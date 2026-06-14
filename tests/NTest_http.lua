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

local HTTPS_RESULTS = { buffered = false, streamed = false, buffered_bytes = 0, streamed_bytes = 0 }

-- Before loading NTest (which consumes ~15KB of RAM), we manually run the HTTPS tests.
-- This ensures mbedTLS has the maximum possible free heap (~39KB) to survive the TLS handshake.
if have_http and have_tls then
  local function ensure_wifi_manual(cb)
    if wifi.sta.getip() then cb(); return end
    wifi.setmode(wifi.STATION)
    wifi.sta.config({ ssid = cfg_ssid, pwd = cfg_passwd or "", auto = true })
    wifi.sta.connect()
    local t = tmr.create()
    t:alarm(500, tmr.ALARM_AUTO, function()
      if wifi.sta.getip() then t:unregister(); cb() end
    end)
  end

  local function run_https_tests(done_cb)
    ensure_wifi_manual(function()
      collectgarbage(); collectgarbage()
      -- Test 1: Buffered HTTPS
      http.get("https://httpbin.org/ip", nil, function(code, data)
        if code > 0 then
          HTTPS_RESULTS.buffered = true
          HTTPS_RESULTS.buffered_bytes = data and #data or 0
        end
        
        collectgarbage(); collectgarbage()
        -- Test 2: Streamed HTTPS
        local stream_total = 0
        http.get_stream("https://httpbin.org/html", nil, function(scode, sdata)
          if sdata then stream_total = stream_total + #sdata end
          if not scode then
            -- stream done
            done_cb()
          elseif scode > 0 then
            HTTPS_RESULTS.streamed = true
            HTTPS_RESULTS.streamed_bytes = stream_total
          end
        end)
      end)
    end)
  end

  -- We must block the execution of the rest of the script until the async HTTPS tests finish.
  -- NodeMCU has no sync sleep, so we just return from the main chunk and let the async callback load NTest!
  local old_run_https = run_https_tests
  run_https_tests = nil
  old_run_https(function()
    dofile("NTest_http_part2.lc")
  end)
  return
end

-- If no TLS, just load part2 immediately
dofile("NTest_http_part2.lc")
