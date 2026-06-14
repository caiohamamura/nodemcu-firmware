local eps = {
  "https://cloudflare-dns.com/dns-query",
  "https://api.github.com/",
  "https://tls-v1-2.badssl.com:1012/"
}
wifi.setmode(wifi.STATION)
wifi.sta.config({ ssid = "C&G", pwd = "", auto = true })
local function test_next(idx)
  if idx > #eps then print("ALL DONE"); return end
  local url = eps[idx]
  print("Testing: " .. url)
  -- emulate low heap of NTest
  local filler = {}
  for i=1, 300 do filler[i] = tostring(i) .. "123456789012345678901234567890" end
  collectgarbage(); collectgarbage()
  print("Heap before: " .. node.heap())
  local total = 0
  http.get_stream(url, nil, function(code, chunk, _h, fin)
    if chunk then total = total + #chunk end
    if fin then
      print("Result for " .. url .. ": " .. tostring(code) .. " (finished, total len: " .. tostring(total) .. ")")
      filler = nil
      test_next(idx + 1)
    end
  end)
end
local t = tmr.create()
t:alarm(1000, tmr.ALARM_AUTO, function()
  if wifi.sta.getip() then t:unregister(); test_next(1) end
end)
