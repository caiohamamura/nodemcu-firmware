wifi.setmode(wifi.STATION)
wifi.sta.config({ ssid = "C&G", pwd = "", auto = true })
local function test()
  print("Heap before: " .. node.heap())
  http.get("https://ecc256.badssl.com/", nil, function(code, data)
    print("ECC Result: " .. tostring(code) .. " len: " .. tostring(data and #data or 0))
  end)
end
local t = tmr.create()
t:alarm(1000, tmr.ALARM_AUTO, function()
  if wifi.sta.getip() then t:unregister(); test() end
end)
