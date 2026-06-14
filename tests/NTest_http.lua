-- NTest suite for the `http` module: validates the http.get / http.get_stream
-- API split and, when TLS is available, exercises HTTPS fetches.
--
-- WiFi credentials come from TEST_WIFI_SSID / TEST_WIFI_PASSWD globals
-- (injected by tests/run-e2e-http.sh).

if type(file) == "table" and file.exists and file.exists("e2e_wifi.lua") then
  pcall(dofile, "e2e_wifi.lua")
end

local cfg_ssid   = rawget(_G, "TEST_WIFI_SSID")
local cfg_passwd = rawget(_G, "TEST_WIFI_PASSWD")

local have_http = (type(http) == "table") or (type(http) == "ROtable")
local have_tls  = (type(tls)  == "table") or (type(tls)  == "ROtable")

-- Global (not local): part2 is loaded as a separate dofile() chunk and reads
-- these results as a global, so they must cross the chunk boundary via _G.
HTTPS_RESULTS = { buffered = false, streamed = false, buffered_bytes = 0, streamed_bytes = 0 }

-- Before loading NTest (which consumes ~15KB of RAM), we manually run the HTTPS tests.
-- This ensures mbedTLS has the maximum possible free heap (~39KB) to survive the TLS handshake.
if have_http and have_tls then
  local function ensure_wifi_manual(cb)
    -- The board re-associates from its saved credentials on boot, so just poll
    -- for an IP -- no wifi.sta.config()+connect(), which costs ~3 KB of heap that
    -- does NOT come back before the TLS handshake. (If a board ever ships without
    -- saved creds, apply cfg_ssid once here; omitted to keep this closure small,
    -- since every byte resident during the handshake matters.) The heartbeat
    -- keeps the runner alive while we poll.
    if wifi.sta.getip() then cb(); return end
    local t = tmr.create()
    t:alarm(500, tmr.ALARM_AUTO, function()
      if wifi.sta.getip() then t:unregister(); cb() end
    end)
  end

  local function run_https_tests(done_cb)
    -- These HTTPS fetches happen BEFORE NTest loads and emit no TAP output until
    -- part2 runs. Each TLS handshake is several seconds of serial silence, which
    -- would trip tap-driver.expect's 10s "getting started" timeout. A heartbeat
    -- print every 2s keeps the driver's catch-all resetting that timer. The body
    -- prints a CONSTANT string (no "..node.heap()" concat) so an interned literal
    -- allocates no heap and never competes with mbedtls for the trough.
    local hb = tmr.create()
    hb:alarm(2000, tmr.ALARM_AUTO, function()
      print("# https heartbeat")
    end)
    local finish = function()
      hb:unregister()
      done_cb()
    end

    -- Buffered HTTPS (Test 1), runs after the streamed fetch. No diagnostic
    -- prints here: this closure is resident DURING the handshake, so every string
    -- constant and runtime concat it carries is heap stolen from the ~1 KB-tight
    -- trough. The heartbeat above is the only output the driver needs.
    local run_buffered = function()
      collectgarbage(); collectgarbage()
      http.get("https://httpbin.org/ip", nil, function(code, data)
        if code > 0 then
          HTTPS_RESULTS.buffered = true
          HTTPS_RESULTS.buffered_bytes = data and #data or 0
        end
        finish()
      end)
    end

    -- Streamed HTTPS (Test 2), runs first.
    -- Callback contract is cb(status, chunk, headers, done): `status` is ALWAYS
    -- an integer (never nil); the terminal call is flagged by the 4th arg
    -- `done == true` (httpclient.c emits it on every path, incl. errors).
    -- Detecting "done" via `not status` never fires and would hang the whole
    -- suite (part2 never loads -> "time out getting started").
    local run_streamed = function()
      collectgarbage(); collectgarbage()
      local stream_total = 0
      http.get_stream("https://httpbin.org/html", nil, function(scode, sdata, _hdrs, sdone)
        if sdata then stream_total = stream_total + #sdata end
        if scode and scode > 0 then
          HTTPS_RESULTS.streamed = true
          HTTPS_RESULTS.streamed_bytes = stream_total
        end
        if sdone then
          run_buffered()
        end
      end)
    end

    ensure_wifi_manual(function()
      -- Brief settle: right after boot the WiFi/lwIP stack is still allocating
      -- DHCP/ARP transients, so free heap climbs for a couple of seconds. The
      -- heartbeat keeps tap-driver.expect alive during the wait.
      local settle = tmr.create()
      settle:alarm(2000, tmr.ALARM_SINGLE, function()
        collectgarbage(); collectgarbage()
        run_streamed()
      end)
    end)
  end

  -- We must block the execution of the rest of the script until the async HTTPS tests finish.
  -- NodeMCU has no sync sleep, so we just return from the main chunk and let the async callback load NTest!
  local old_run_https = run_https_tests
  run_https_tests = nil
  old_run_https(function()
    -- Reclaim everything the part1 HTTPS work left behind before NTest (~15 KB)
    -- and the plain-HTTP network tests load on top: a couple of GC passes plus a
    -- short delay lets the SDK tear down the last TLS connection's buffers, so
    -- part2 starts from the highest possible heap.
    collectgarbage(); collectgarbage()
    local t = tmr.create()
    t:alarm(750, tmr.ALARM_SINGLE, function()
      collectgarbage(); collectgarbage()
      dofile("NTest_http_part2.lc")
    end)
  end)
  return
end

-- If no TLS, just load part2 immediately
dofile("NTest_http_part2.lc")
