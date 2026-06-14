local eps = {
  "https://httpbin.org/ip",
  "https://google.com/",
  "https://www.howsmyssl.com/a/check",
  "https://api.ipify.org/",
  "https://postman-echo.com/get",
  "https://example.com/"
}

wifi.setmode(wifi.STATION)
wifi.sta.config({ ssid = "C&G", pwd = "", auto = true })

local function test_next(idx)
  if idx > #eps then
    print("ALL DONE")
    return
  end
  local url = eps[idx]
  print("Testing: " .. url)
  collectgarbage(); collectgarbage()
  print("Heap before: " .. node.heap())
  http.get(url, nil, function(code, data)
    print("Result for " .. url .. ": " .. tostring(code) .. " len: " .. tostring(data and #data or 0))
    test_next(idx + 1)
  end)
end

local t = tmr.create()
t:alarm(1000, tmr.ALARM_AUTO, function()
  if wifi.sta.getip() then
    t:unregister()
    print("Got IP: " .. wifi.sta.getip())
    test_next(1)
  end
end)
