-- Lightweight on-device HTTPS proof for the `http` module.
--
-- Kept deliberately tiny: a TLS handshake with the 16 KB mbedtls IN buffer peaks
-- at ~37.5 KB of heap, and a clean boot provides ~40 KB, so the script itself
-- must stay resident in only ~1-2 KB or it starves the handshake (this is why
-- the heavier NTest serial-transfer harness, ~4 KB resident, can't run these
-- fetches in-place). Run it via run-https-proof.expect, which transfers it to
-- SPIFFS and dofile()s it after a reboot so the heap is at its peak.
--
-- Targets span the record-size spectrum: httpbin (small, buffered + streamed),
-- raw.githubusercontent.com and a CloudFront host with a ~102 KB body (large
-- records -- proves the 16 KB IN buffer receives >8 KB application-data
-- records), and clients5.google.com (largest cert chain, 4868 B).

if type(file) == "table" and file.exists and file.exists("e2e_wifi.lua") then
  pcall(dofile, "e2e_wifi.lua")
end

-- {url, buffered?, label}; nil 2nd field = streamed. Spans the record-size
-- spectrum: small responses (httpbin/google), a ~5 KB body (github-raw), and a
-- ~102 KB CloudFront body whose large (16 KB) application-data records exercise
-- the full 16 KB IN buffer -- all must pass (see user_mbedtls.h: 16 KB IN +
-- KEEP_PEER_CERTIFICATE off).
local urls = {
  { "https://httpbin.org/ip", true, "httpbin-buffered" },
  { "https://httpbin.org/html", false, "httpbin-streamed" },
  { "https://raw.githubusercontent.com/nodemcu/nodemcu-firmware/master/README.md", false, "github-raw" },
  { "https://clients5.google.com/pagead/drt/dn/", false, "google" },
  { "https://dziadalnfpolx.cloudfront.net/", false, "cloudfront-102k" },
}
local fails = 0

local function nxt(i)
  if i > #urls then
    print("PROOF: 1.." .. (i - 1))
    print(fails == 0 and "PROOF: ALL OK" or ("PROOF: " .. fails .. " FAILURES"))
    return
  end
  collectgarbage(); collectgarbage()
  local u = urls[i]
  local done = function(code, total)
    local ok = code == 200 and total > 0
    if not ok then fails = fails + 1 end
    print(("PROOF: %s %d %s code=%s bytes=%d"):format(
      ok and "ok" or "not ok", i, u[3], tostring(code), total))
    nxt(i + 1)
  end
  if u[2] then
    http.get(u[1], nil, function(code, data) done(code, data and #data or 0) end)
  else
    local total = 0
    http.get_stream(u[1], nil, function(code, chunk, _h, fin)
      if chunk then total = total + #chunk end
      if fin then done(code, total) end
    end)
  end
end

-- Wait for an IP (the board auto-reconnects from saved creds; injected creds are
-- a fallback), then settle ~4 s so lwIP transients free and the heap is at peak.
local function start()
  local cfg = rawget(_G, "TEST_WIFI_SSID")
  if not wifi.sta.getip() and cfg then
    wifi.setmode(wifi.STATION)
    wifi.sta.config({ ssid = cfg, pwd = rawget(_G, "TEST_WIFI_PASSWD") or "", auto = true })
    wifi.sta.connect()
  end
  local t = tmr.create()
  t:alarm(500, tmr.ALARM_AUTO, function()
    if wifi.sta.getip() then
      t:unregister()
      local s = tmr.create()
      s:alarm(3000, tmr.ALARM_SINGLE, function() collectgarbage(); collectgarbage(); nxt(1) end)
    end
  end)
end

start()
