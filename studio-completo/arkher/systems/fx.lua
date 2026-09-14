-- arkher/systems/fx.lua — particles/beams/screen fx (real instances + overlays).
local FX = {}
local function E() return _G.ARKHER end
local function hostPart(first)
  if first and first.Parent and first:IsA("BasePart") then return first end
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local p = Instance.new("Part") p.Name = "FXHost" p.Anchored = true p.CanCollide = false p.Transparency = 1 p.Size = Vector3.new(1, 1, 1) p.Position = c p.Parent = workspace
  return p
end
function FX.emit(kind, first)
  local host = hostPart(first)
  local cls = ({ particles = "ParticleEmitter", fire = "Fire", smoke = "Smoke", sparkles = "Sparkles" })[kind] or "ParticleEmitter"
  local e = Instance.new(cls)
  if cls == "ParticleEmitter" then e.Rate = 20 e.Lifetime = NumberRange.new(1, 2) e.Speed = NumberRange.new(5, 10) e.Size = NumberSequence.new(1) end
  e.Parent = host
  E().undo.created(e) E().undo.commit("fx " .. kind) E().sel.set({ e })
end
function FX.burst(list)
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("ParticleEmitter") then o:Emit(50) end end
end
function FX.toggle(list)
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("ParticleEmitter") then o.Enabled = not o.Enabled end end
  E().undo.commit("fx toggle")
end
function FX.forcefield(first)
  local m = first and first:FindFirstAncestorWhichIsA("Model")
  local target = m or (first and first.Parent)
  if not target then E().toast("Select a character or model.") return end
  local f = Instance.new("ForceField") f.Visible = true f.Parent = target
  E().undo.created(f) E().undo.commit("forcefield")
end
function FX.beam(list, a)
  local p = {}
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") then p[#p + 1] = o end end
  if #p < 2 then E().toast("Select 2 parts.") return end
  local function att(x) local t = Instance.new("Attachment") t.Parent = x return t end
  local b = Instance.new("Beam") b.Attachment0 = att(p[1]) b.Attachment1 = att(p[2])
  b.Width0, b.Width1 = 0.5, 0.5 b.FaceCamera = true b.Parent = p[1]
  E().undo.created(b) E().undo.commit("beam") E().sel.set({ b })
end
function FX.trail(first)
  local p = first and first.Parent and first:IsA("BasePart") and first or nil
  if not p then E().toast("Select a part.") return end
  local function att(dy) local t = Instance.new("Attachment") t.Position = Vector3.new(0, dy, 0) t.Parent = p return t end
  local t = Instance.new("Trail") t.Attachment0 = att(1) t.Attachment1 = att(-1) t.Parent = p
  E().undo.created(t) E().undo.commit("trail") E().sel.set({ t })
end
function FX.lightning(a)
  a = a or {}
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local top = c + Vector3.new(math.random(-20, 20), 120, math.random(-20, 20))
  local m = Instance.new("Model") m.Name = "Lightning"
  local prev = top
  for i = 1, 8 do
    local nxt = top:Lerp(c, i / 8) + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
    local seg = Instance.new("Part") seg.Anchored = true seg.CanCollide = false seg.Material = Enum.Material.Neon
    seg.Color = Color3.fromRGB(150, 200, 255) seg.Size = Vector3.new(0.6, 0.6, (prev - nxt).Magnitude)
    seg.CFrame = CFrame.new((prev + nxt) / 2, nxt) seg.Parent = m
    prev = nxt
  end
  m.Parent = workspace E().undo.created(m) E().undo.commit("lightning") E().sel.set({ m })
end
function FX.shake() if E().shell and E().shell.shake then E().shell.shake() else E().toast("Shake needs engine UI.") end end
function FX.flash() if E().shell and E().shell.flash then E().shell.flash() else E().toast("Flash needs engine UI.") end end
function FX.slowmo()
  local cur = tonumber(E().store.get("sim_speed")) or 1
  E().store.set("sim_speed", cur == 1 and 0.25 or 1)
  E().toast("Sim speed = " .. tostring(E().store.get("sim_speed")))
end
function FX.hitstop()
  E().store.set("sim_speed", 0)
  E().toast("Hitstop!")
  coroutine.wrap(function() wait(0.12) E().store.set("sim_speed", 1) end)()
end
function FX.all(on)
  local n = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("ParticleEmitter") then d.Enabled = on n = n + 1 end end
  E().toast(n .. " emitters " .. (on and "on" or "off") .. ".")
end
function FX.audit()
  local n, rate = 0, 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("ParticleEmitter") and d.Enabled then n = n + 1 rate = rate + d.Rate end end
  E().out.log(string.format("FX: %d active emitters, %d particles/sec.", n, rate))
end
function FX.savePreset(first, name)
  if first and first:IsA("ParticleEmitter") then
    E().out.log("FXPRESET " .. (name or first.Name) .. " rate=" .. first.Rate)
    E().toast("Preset -> Output.")
  else E().toast("Select an emitter.") end
end
function FX.clear() for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("ParticleEmitter") then d:Clear() end end E().toast("Particles cleared.") end
function FX.sparkleburst()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local p = Instance.new("Part") p.Anchored = true p.CanCollide = false p.Transparency = 1 p.Size = Vector3.new(1, 1, 1)
  p.Position = hit and hit.Position or cam.Focus.Position p.Parent = workspace
  local e = Instance.new("ParticleEmitter") e.Rate = 0 e.Speed = NumberRange.new(8, 14) e.Lifetime = NumberRange.new(0.5, 1) e.Size = NumberSequence.new(1.5) e.Parent = p
  e:Emit(40)
  game:GetService("Debris"):AddItem(p, 3)
end
function FX.tick(dt) end
E().systems.fx = FX
return FX
