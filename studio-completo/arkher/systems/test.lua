-- arkher/systems/test.lua — self-tests, bots, audits.
local TS = { bots = {} }
local function E() return _G.ARKHER end
function TS.local_()
  local pass, fail = 0, 0
  local function check(name, fn) local ok = pcall(fn) if ok then pass = pass + 1 else fail = fail + 1 E().out.err("FAIL " .. name) end end
  check("workspace", function() assert(workspace ~= nil) end)
  check("terrain", function() assert(workspace.Terrain ~= nil) end)
  check("lighting", function() assert(game:GetService("Lighting") ~= nil) end)
  check("registry", function() assert(E().registry.tabs and #E().registry.tabs == 30) end)
  check("commands", function() local n = 0 for _, t in ipairs(E().registry.tabs) do n = n + #t.commands end assert(n == 1200) end)
  check("actions", function() for _, t in ipairs(E().registry.tabs) do for _, c in ipairs(t.commands) do assert(E().ACTIONS[c.act], c.id) end end end)
  E().out.log(string.format("Self-test: %d pass, %d fail.", pass, fail))
  E().toast(string.format("Self-test: %d/%d", pass, pass + fail))
end
function TS.bots(a)
  a = a or {}
  local n = math.min(20, a.count or 4)
  for i = 1, n do
    E().systems.char.new({ rig = "R15" })
    local m = E().sel.get()[1]
    if m then m.Name = "Bot" .. i TS.bots[#TS.bots + 1] = m end
  end
  E().toast(n .. " bots spawned.")
end
function TS.all() TS.local_() E().systems.project.validate() E().systems.perf.audit() end
function TS.selected(list)
  E().out.log("Selected-scope checks on " .. #(list or {}) .. " objects.")
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") and not o.Anchored then E().out.warn("Unanchored: " .. o:GetFullName()) end end
end
function TS.audit()
  local parts, scripts, sounds = 0, 0, 0
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") then parts = parts + 1 elseif d:IsA("LuaSourceContainer") then scripts = scripts + 1 elseif d:IsA("Sound") then sounds = sounds + 1 end
  end
  E().out.log(string.format("Place: %d parts, %d scripts, %d sounds.", parts, scripts, sounds))
end
E().systems.test = TS
return TS
