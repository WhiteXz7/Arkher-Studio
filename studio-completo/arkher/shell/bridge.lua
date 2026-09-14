-- arkher/shell/bridge.lua — server bridge (local in Edit mode; latency simulator).
local B = { queue = {}, mode = "local" }
function B.call(name, payload, cb)
  local lat = tonumber(_G.ARKHER.store.get("net_latency")) or 0
  local function exec()
    if B.mode == "local" then
      local sys = _G.ARKHER.systems
      local h = sys.server and sys.server[name]
      local ok, res = true, nil
      if h then ok, res = pcall(h, payload) else ok, res = false, "no handler " .. name end
      if cb then pcall(cb, ok, res) end
      return ok, res
    end
    return false, "remote not connected"
  end
  if lat > 0 then
    B.queue[#B.queue + 1] = { t = os.clock() + lat / 1000, fn = exec }
  else
    return exec()
  end
end
function B.tick()
  local now = os.clock()
  for i = #B.queue, 1, -1 do
    if B.queue[i].t <= now then local q = B.queue[i] table.remove(B.queue, i) pcall(q.fn) end
  end
end
game:GetService("RunService").Heartbeat:Connect(function() B.tick() end)
_G.ARKHER.bridge = B
return B
