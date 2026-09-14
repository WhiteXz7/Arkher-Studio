-- arkher/systems/npc.lua — NPC spawn + brain tick (Humanoid:MoveTo, waypoints, senses).
local NP = { brains = {}, frozen = false }
local function E() return _G.ARKHER end
local function tag(o, k, v) local t = o:FindFirstChild(k) or Instance.new("StringValue") t.Name = k t.Value = v or "" t.Parent = o end
function NP.new(a)
  a = a or {}
  E().systems.char.new({ rig = "R15" })
  local m = E().sel.get()[1]
  if not (m and m:IsA("Model")) then return end
  m.Name = a.name or "NPC"
  tag(m, "ARKHER_npc", "v1")
  tag(m, "ARKHER_mode", a.mode or "stay")
  local h = m:FindFirstChildWhichIsA("Humanoid")
  if h then h.DisplayName = m.Name end
  for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false end end
  NP.brains[m] = { mode = a.mode or "stay", wp = {}, i = 1, speed = a.speed or 12, home = m:GetPivot() }
  E().toast("NPC spawned.")
end
local PRE = {
  civilian = { mode = "wander", speed = 8 },
  guard = { mode = "patrol", speed = 12 },
  merchant = { mode = "stay", speed = 0 },
  enemy = { mode = "chase", speed = 14 },
}
function NP.preset(name)
  local p = PRE[name] or PRE.civilian
  NP.new({ name = name:upper(), mode = p.mode, speed = p.speed })
end
function NP.mode(m, mode)
  if not (m and m:IsA("Model")) then E().toast("Select an NPC.") return end
  local b = NP.brains[m]
  if not b then NP.brains[m] = { mode = mode, wp = {}, i = 1, speed = 12, home = m:GetPivot() }
  else b.mode = mode end
  tag(m, "ARKHER_mode", mode)
  E().toast("NPC mode: " .. mode)
end
function NP.testTalk(m)
  if not (m and m:IsA("Model")) then E().toast("Select an NPC.") return end
  local d = m:FindFirstChildWhichIsA("Dialog")
  if d then E().toast("Dialog: " .. (d.InitialPrompt or "(no prompt)")) else E().toast("No Dialog; add one via Game > Dialog.") end
end
function NP.bringAll()
  local c = E().systems.camera.focusCF().Position
  local n = 0
  for m, _ in pairs(NP.brains) do if m and m.Parent then m:PivotTo(CFrame.new(c + Vector3.new(n * 4, 5, 0))) n = n + 1 end end
  E().toast(n .. " NPCs brought.")
end
function NP.freeze(f) NP.frozen = f E().toast(f and "NPC AI frozen." or "NPC AI resumed.") end
function NP.resetAll() for m, b in pairs(NP.brains) do if m and m.Parent and b.home then m:PivotTo(b.home) end end end
function NP.tick(dt)
  if NP.frozen then return end
  NP._acc = (NP._acc or 0) + dt
  local tickRate = 1 / math.max(1, tonumber(E().store.get("ai_tick")) or 10)
  if NP._acc < tickRate then return end
  NP._acc = 0
  for m, b in pairs(NP.brains) do
    if m and m.Parent then
      local h = m:FindFirstChildWhichIsA("Humanoid")
      local hrp = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
      if h and hrp and h.Health > 0 then
        h.WalkSpeed = b.speed
        if b.mode == "wander" then
          if (hrp.Position - (b._tgt or hrp.Position)).Magnitude < 4 then b._tgt = hrp.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30)) end
          pcall(function() h:MoveTo(b._tgt) end)
        elseif b.mode == "patrol" and #b.wp > 0 then
          local w = b.wp[b.i]
          if (hrp.Position - w).Magnitude < 5 then b.i = (b.i % #b.wp) + 1 w = b.wp[b.i] end
          pcall(function() h:MoveTo(w) end)
        elseif b.mode == "follow" then
          local pl = game:GetService("Players").LocalPlayer
          local ch = pl and pl.Character
          local tp = ch and ch:FindFirstChild("HumanoidRootPart")
          if tp then pcall(function() h:MoveTo(tp.Position) end) end
        elseif b.mode == "chase" then
          local best, bd = nil, 60
          for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
            local ch = pl.Character local tp = ch and ch:FindFirstChild("HumanoidRootPart")
            if tp then local d = (tp.Position - hrp.Position).Magnitude if d < bd then best, bd = tp, d end end
          end
          if best then pcall(function() h:MoveTo(best.Position) end) end
        end
      end
    end
  end
end
function NP.export(m)
  if not (m and m:IsA("Model")) then E().toast("Select an NPC.") return end
  local b = NP.brains[m] or {}
  E().out.log("NPC " .. game:GetService("HttpService"):JSONEncode({ n = m.Name, mode = b.mode, speed = b.speed }))
end
function NP.import(a) E().panel.open("npc_import", a) end
function NP.audit()
  local n, nomode = 0, 0
  for m, b in pairs(NP.brains) do if m and m.Parent then n = n + 1 if not b.mode then nomode = nomode + 1 end end end
  E().out.log(string.format("NPCs: %d tracked, %d missing mode.", n, nomode))
end
function NP.healthbar()
  NP._hb = not NP._hb
  for m, _ in pairs(NP.brains) do
    if m and m.Parent then local h = m:FindFirstChildWhichIsA("Humanoid")
      if h then h.HealthDisplayType = NP._hb and Enum.HumanoidHealthDisplayType.AlwaysOn or Enum.HumanoidHealthDisplayType.DisplayWhenDamaged end
    end
  end
  E().toast("Healthbars " .. (NP._hb and "on" or "auto") .. ".")
end
E().systems.npc = NP
return NP
