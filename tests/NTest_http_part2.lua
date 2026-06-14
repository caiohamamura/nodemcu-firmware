-- Obtain the NTest factory via the driver-provided global `ntshim` when present
-- (tap-driver.expect defines it; it wires up the "TAP: " output handler the
-- runner parses). part1 reaches us through dofile(), not the loadfile(...)(ntshim)
-- vararg, so we read ntshim from _G rather than as an argument. Fall back to a
-- plain NTest instance when run standalone (no driver).
local N = (rawget(_G, "ntshim") or function(name) return (require "NTest")(name) end)("http")

local cfg_ssid   = rawget(_G, "TEST_WIFI_SSID")
local cfg_passwd = rawget(_G, "TEST_WIFI_PASSWD")

local have_http = (type(http) == "table") or (type(http) == "ROtable")
local have_tls  = (type(tls)  == "table") or (type(tls)  == "ROtable")

--------------------------------------------------------------------------------
-- Unit tests: API contract, no network required.
--------------------------------------------------------------------------------

if have_http then
  N.test('api surface', function()
    ok(eq(type(http.get),        "function"), "http.get is a function")
    ok(eq(type(http.get_stream), "function"), "http.get_stream is a function")
    ok(eq(type(http.post),       "function"), "http.post is a function")
    ok(eq(type(http.post_stream),"function"), "http.post_stream is a function")
    ok(eq(type(http.put),        "function"), "http.put is a function")
    ok(eq(type(http.delete),     "function"), "http.delete is a function")
    ok(eq(type(http.request),    "function"), "http.request is a function")
  end)

  N.test('rejects missing url', function()
    fail(function() http.get() end, "string expected", "get() with no url errors")
    fail(function() http.request(nil, "GET", nil, "", function() end) end,
         "string expected", "request() with nil url errors")
  end)

  N.test('rejects missing method', function()
    fail(function() http.request("https://example.com/") end,
         "string expected", "request() with no method errors")
  end)

  N.test('accepts well-formed call and returns nil', function()
    local r = http.get("http://0.0.0.0/", nil, function() end)
    ok(eq(r, nil), "http.get returns nil")
  end)
else
  N.test('http module absent', function()
    ok(true, "firmware built without the http module; skipping http tests")
  end)
end

--------------------------------------------------------------------------------
-- WiFi + network helpers
--------------------------------------------------------------------------------

local function station_has_ip()
  return (type(wifi) == "table" or type(wifi) == "ROtable")
     and wifi.sta and wifi.sta.getip and (wifi.sta.getip() ~= nil)
end

local function ensure_wifi(getCB, waitCB)
  if station_has_ip() then return true end
  if not (cfg_ssid and wifi and wifi.setmode and wifi.sta) then return false end
  wifi.setmode(wifi.STATION)
  wifi.sta.config({ ssid = cfg_ssid, pwd = cfg_passwd or "", auto = true })
  wifi.sta.connect()
  local tries, t = 0, tmr.create()
  t:alarm(500, tmr.ALARM_AUTO, getCB("wifipoll"))
  while tries < 30 do
    waitCB(); tries = tries + 1
    if station_has_ip() then t:unregister(); return true end
  end
  t:unregister()
  return false
end

local function gwait(getCB, waitCB, ms)
  local guard = tmr.create()
  guard:alarm(ms or 20000, tmr.ALARM_SINGLE, getCB("timeout_guard"))
  local r = {waitCB()}
  guard:unregister()
  return r[1] == "timeout_guard", unpack(r)
end

local function fetch(url, getCB, waitCB)
  local max_retries = 2
  for try = 1, max_retries do
    collectgarbage(); collectgarbage()
    http.get(url, nil, getCB("http"))
    local to, _, code, chunk = gwait(getCB, waitCB)
    if not to and code ~= -1 then return code, type(chunk) == "string" and #chunk or 0 end
    if try < max_retries then
      local t = tmr.create()
      t:alarm(1000, tmr.ALARM_SINGLE, getCB("delay"))
      waitCB()
    end
  end
  return -1, 0
end

local function fetch_stream(url, getCB, waitCB)
  local max_retries = 2
  for try = 1, max_retries do
    collectgarbage(); collectgarbage()
    http.get_stream(url, nil, getCB("http"))
    local status, total = nil, 0
    repeat
      local to, _, code, chunk, _, done = gwait(getCB, waitCB)
      if to or (status == nil and code == -1) then status = -1; break end
      status = status or code
      if type(chunk) == "string" then total = total + #chunk end
    until done
    if status ~= -1 then return status, total end
    if try < max_retries then
      local t = tmr.create()
      t:alarm(1000, tmr.ALARM_SINGLE, getCB("delay"))
      waitCB()
    end
  end
  return -1, 0
end

--------------------------------------------------------------------------------
-- Network tests: HTTPS (TLS + SNI) results injected from part1
--------------------------------------------------------------------------------
if have_http and have_tls then
  N.test('GET streamed (https)', function()
    ok(HTTPS_RESULTS.streamed, "streamed HTTPS ok")
    ok(HTTPS_RESULTS.streamed_bytes > 0, "received " .. tostring(HTTPS_RESULTS.streamed_bytes) .. " streamed body bytes")
  end)

  N.test('GET buffered (https)', function()
    ok(HTTPS_RESULTS.buffered, "buffered HTTPS ok")
    ok(HTTPS_RESULTS.buffered_bytes > 0, "non-empty body (" .. tostring(HTTPS_RESULTS.buffered_bytes) .. " bytes)")
  end)
elseif have_http then
  N.test('tls module absent', function()
    ok(true, "firmware lacks the tls module; skipping HTTPS fetches")
  end)
end

--------------------------------------------------------------------------------
-- Network tests: plain HTTP (no TLS overhead)
--------------------------------------------------------------------------------
if have_http then
  N.testco('GET streamed (http)', function(getCB, waitCB)
    ok(ensure_wifi(getCB, waitCB), "station has an IP address")
    local code, total = fetch_stream("http://httpbin.org/html", getCB, waitCB)
    ok(code and code > 0, "streamed HTTP ok (got " .. tostring(code) .. ")")
    ok(total > 0, "non-empty streamed body (" .. tostring(total) .. " bytes)")
  end)

  N.testco('GET buffered (http)', function(getCB, waitCB)
    ok(ensure_wifi(getCB, waitCB), "station has an IP address")
    local code, total = fetch("http://httpbin.org/ip", getCB, waitCB)
    ok(code and code > 0, "buffered HTTP ok (got " .. tostring(code) .. ")")
    ok(total > 0, "non-empty body (" .. tostring(total) .. " bytes)")
  end)
end

-- NTest runs each test synchronously as it is registered above (coroutine
-- tests via testco drain their own callback queue), and emits the terminal
-- "TAP: POST 1..N" plan through the output handler. Nothing else to kick off.
