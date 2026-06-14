local eps = {
  "https://httpbin.org/html",
}

wifi.setmode(wifi.STATION)
wifi.sta.config({ ssid = "C&G", pwd = "", auto = true })

local function test_next(idx)
  if idx > #eps then
    print("ALL DONE")
    return
  end
  local url = eps[idx]
  print("Testing stream: " .. url)
  collectgarbage(); collectgarbage()
  print("Heap before: " .. node.heap())
  local total = 0
  http.get_stream(url, nil, function(code, data)
    if data then total = total + #data end
    if code then 
      print("Got chunk code: " .. tostring(code) .. " len: " .. tostring(data and #data or 0) .. " total: " .. total)
    else
      print("Stream Done")
      test_next(idx + 1)
    end
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
