#!/usr/bin/env bash
#
# End-to-end runner for the HTTPS fetch tests (tests/NTest_http.lua) against a
# physical NodeMCU device over its serial link.
#
# Device selection:
#   * If NODEMCU_SERIAL is set, that port is used.
#   * Otherwise the first /dev/ttyUSB*, /dev/ttyACM*, ... is auto-selected by
#     tap-driver.expect / expectnmcu::core::autodetect_serial.
#
# WiFi credentials (needed for the network tests; without them the HTTPS tests
# self-skip on the device):
#   * NODEMCU_WIFI_SSID    - station SSID
#   * NODEMCU_WIFI_PASSWD  - station password (may be empty for open networks)
#
# Optional:
#   * NODEMCU_LFS          - path to an LFS image to flash before running.
#
# The device must already be running a firmware built with the right options
# (the defaults ship TLS off, so a stock build will NOT pass). This script does
# NOT reflash the application firmware (that is destructive and board-specific).
# Required firmware config (uncomment in app/include/user_modules.h /
# app/include/user_config.h before building -- the CI workflow does the first
# three via sed):
#   * LUA_USE_MODULES_HTTP, LUA_USE_MODULES_TLS  -- the modules under test
#   * CLIENT_SSL_ENABLE                          -- HTTPS support
#   * SSL_BUFFER_SIZE 16384                       -- to receive large TLS records
#       (e.g. the CloudFront 102 KB body in the proof); 4096 only handles small-
#       record servers. user_mbedtls.h's KEEP_PEER_CERTIFICATE-off keeps the
#       16 KB handshake within heap.
#   * LUA_USE_MODULES_CRYPTO, LUA_USE_MODULES_ENCODER, LUA_USE_MODULES_FILE
#       -- NOT for TLS itself, but required by the serial file-transfer harness
#       (tap-driver.expect uses encoder.fromBase64 + crypto.fhash + the file API).
#       Without ENCODER/CRYPTO the transfer fails with "attempt to index global
#       'encoder' (a nil value)".
# Also needs a host luac.cross (LUAC_CROSS or ../build_lc/luac.cross) to
# precompile the test Lua to bytecode; otherwise on-device source compile OOMs on
# a TLS build. Build it with: cmake --build build_lc.
#
# Usage:
#   NODEMCU_WIFI_SSID=myssid NODEMCU_WIFI_PASSWD=secret ./tests/run-e2e-http.sh
#   NODEMCU_SERIAL=/dev/ttyUSB2 ./tests/run-e2e-http.sh

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${here}"

# --- dependency check --------------------------------------------------------
missing=()
for cmd in expect socat tclsh; do
  command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
done
if [ "${#missing[@]}" -ne 0 ]; then
  echo "Missing required tools: ${missing[*]}" >&2
  echo "On Debian/Ubuntu: sudo apt install expect socat tcl tcllib tclx8.4" >&2
  exit 1
fi

# --- device selection (report what we'll use; driver does the real pick) -----
if [ -n "${NODEMCU_SERIAL:-}" ]; then
  echo "Using serial device from NODEMCU_SERIAL: ${NODEMCU_SERIAL}"
else
  cand="$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | sort | head -n1 || true)"
  if [ -z "${cand}" ]; then
    echo "No serial device found and NODEMCU_SERIAL is unset." >&2
    echo "Attach a board or set NODEMCU_SERIAL=/dev/ttyUSBx." >&2
    exit 1
  fi
  echo "Auto-selecting serial device: ${cand} (override with NODEMCU_SERIAL)"
fi

# --- assemble files to transfer ----------------------------------------------
# NTest.lua and NTestTapOut.lua must be requirable on the DUT; NTest_http.lua is
# the last argument and is the one actually run by the driver.
workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# NTest and NTestTapOut must be requirable on the DUT. Compiling them to
# bytecode (.lc) before transfer avoids the on-device source compiler, whose
# RAM overhead can exhaust the heap on a TLS-enabled build. We locate a
# matching luac.cross; if none is found we fall back to shipping the .lua
# sources (fine on devices with more free heap, e.g. an LFS-based setup).
luac="${LUAC_CROSS:-}"
if [ -z "${luac}" ]; then
  for c in ./luac.cross ../luac.cross ../bin/luac.cross ../build_lc/luac.cross; do
    [ -x "${c}" ] && { luac="${c}"; break; }
  done
fi

if [ -n "${luac}" ] && [ -x "${luac}" ]; then
  # -s strips debug info (line numbers, local/upvalue names) from the bytecode.
  # That info is dead weight on the device but inflates the RAM footprint of a
  # loaded chunk by several KB -- e.g. part1 (NTest_http.lc) is loaded by the
  # driver while the heap must stay high enough for the TLS handshake. Stripping
  # reclaims that headroom.
  echo "Precompiling NTest deps to stripped bytecode with ${luac}"
  "${luac}" -s -o "${workdir}/NTest.lc"       NTest/NTest.lua
  "${luac}" -s -o "${workdir}/NTestTapOut.lc" utils/NTestTapOut.lua
  xfers=("${workdir}/NTest.lc" "${workdir}/NTestTapOut.lc")
else
  echo "No luac.cross found (set LUAC_CROSS); shipping .lua sources (may OOM on small devices)"
  xfers=("NTest/NTest.lua" "utils/NTestTapOut.lua")
fi

if [ -n "${NODEMCU_WIFI_SSID:-}" ]; then
  # Emit a clean Lua string literal, escaping backslashes and double-quotes.
  # The surrounding quotes are added by the printf format, NOT by sed: sed only
  # escapes the value's contents. (An earlier version added the quotes in sed
  # via s/^/"/;s/$/"/, which silently produced an unquoted, empty value for an
  # empty password -- sed gets zero input lines and emits nothing -- yielding
  # `TEST_WIFI_PASSWD = ` and a chunk-wide "unexpected symbol near '<eof>'"
  # syntax error that left TEST_WIFI_SSID unset too.)
  lua_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
  {
    echo '-- Auto-generated by run-e2e-http.sh; injects station credentials.'
    printf 'TEST_WIFI_SSID = "%s"\n'   "$(lua_escape "${NODEMCU_WIFI_SSID}")"
    printf 'TEST_WIFI_PASSWD = "%s"\n' "$(lua_escape "${NODEMCU_WIFI_PASSWD:-}")"
  } > "${workdir}/e2e_wifi.lua"
  xfers+=("${workdir}/e2e_wifi.lua")
  echo "Injecting WiFi credentials for SSID: ${NODEMCU_WIFI_SSID}"
else
  echo "NODEMCU_WIFI_SSID unset; HTTPS network tests will self-skip on the DUT."
fi

if [ -n "${luac:-}" ] && [ -x "${luac:-}" ]; then
  "${luac}" -s -o "${workdir}/NTest_http.lc" NTest_http.lua
  "${luac}" -s -o "${workdir}/NTest_http_part2.lc" NTest_http_part2.lua
  xfers+=("${workdir}/NTest_http_part2.lc")
  xfers+=("${workdir}/NTest_http.lc")
else
  xfers+=("NTest_http_part2.lua")
  xfers+=("NTest_http.lua")
fi

# --- optional LFS flash ------------------------------------------------------
lfs_args=()
if [ -n "${NODEMCU_LFS:-}" ]; then
  lfs_args=(-lfs "${NODEMCU_LFS}")
fi

# --- run ---------------------------------------------------------------------
serial_args=()
if [ -n "${NODEMCU_SERIAL:-}" ]; then
  serial_args=(-serial "${NODEMCU_SERIAL}")
fi

echo "Running NTest_http.lua on device..."
# Prepend our package dir; keep any caller-provided TCLLIBPATH (e.g. pointing at
# a tcllib install that carries the `cmdline` package).
export TCLLIBPATH="./expectnmcu ${TCLLIBPATH:-}"
exec ./tap-driver.expect \
  "${serial_args[@]}" \
  "${lfs_args[@]}" \
  "${xfers[@]}"
