-- arkher/systems/perf.lua — real perf stats (Stats service) + snapshots.
local PF = { base = nil, rec = false, series = {}, frames = {}, last = 0 }
local function E() return _G.ARKHER end
function PF.stats()
  local S = game:GetService("Stats")
  local o = {}
  pcall(function() o.fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait()) end)
  pcall(function() o.contacts = S.ContactsCount end)
  pcall(function() o.instances = S.InstanceCount end)
  pcall(function() o.physics = S.PhysicsStepTime end)
  pcall(function() o.drawcalls = S.SceneDrawcallCount end)
  pcall(function() o.tris = S.SceneTriangleCount end)
  pcall(function() o.mem = S:GetTotalMemoryUsageMb() end)
  pcall(function() o.send = S.DataSendKbps end)
  pcall(function() o.recv = S.DataReceiveKbps end)
  return o
end
function PF.quick()
  local s = PF.stats()
  local msg = string.format("inst=%s phys=%sms draw=%s tri=%s mem=%sMB", tostring(s.instances or "?"), tostring(s.physics and string.format("%.2f", s.physics) or "?"), tostring(s.drawcalls or "?"), tostring(s.tris or "?"), tostring(s.mem and math.floor(s.mem) or "?"))
  E().out.log(msg)
  if E().shell and E().shell.status then E().shell.status(msg) end
end
function PF.fps()
  local t0 = os.clock() local n = 0
  local c; c = game:GetService("RunService").RenderStepped:Connect(function() n = n + 1 if os.clock() - t0 >= 1 then c:Disconnect() E().out.log("FPS: " .. n) E().toast("FPS: " .. n) end end)
end
function PF.gc()
  local before = gcinfo()
  collectgarbage("collect")
  local after = gcinfo()
  E().out.log(string.format("GC: %.1fKB -> %.1fKB", before, after))
end
function PF.snapshot()
  local s = PF.stats() s.t = os.time()
  E().out.log("SNAP " .. game:GetService("HttpService"):JSONEncode(s))
  E().toast("Snapshot -> Output.")
  return s
end
function PF.baseline() PF.base = PF.stats() E().toast("Baseline saved.") end
function PF.export() PF.snapshot() end
function PF.audit()
  local parts = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") then parts = parts + 1 end end
  local s = PF.stats()
  E().out.log(string.format("Perf audit: %d parts, mem=%sMB, draw=%s.", parts, tostring(s.mem and math.floor(s.mem) or "?"), tostring(s.drawcalls or "?")))
  if parts > 20000 then E().out.warn("Over 20k parts: streaming recommended.") end
end
function PF.record(on)
  PF.rec = on
  if on then PF.series = {} E().toast("Recording perf...") else E().out.log("Perf recording: " .. #PF.series .. " samples.") end
end
function PF.merge(a)
  a = a or {}
  local parts = {}
  for _, o in ipairs(E().sel.get()) do if o and o.Parent and o:IsA("BasePart") then parts[#parts + 1] = o end end
  if #parts < 2 then E().toast("Select 2+ static parts.") return end
  for _, o in ipairs(parts) do o.Anchored = true end
  local m = Instance.new("Model") m.Name = "StaticMerged"
  for _, o in ipairs(parts) do o.Parent = m end
  m.Parent = workspace
  E().undo.created(m) E().undo.commit("merge static")
  E().toast(#parts .. " parts merged (anchored group).")
end
E().systems.perf = PF
return PF
