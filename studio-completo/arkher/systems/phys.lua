-- arkher/systems/phys.lua — constraints/forces/audit (all real instances).
local PH = { frozen = nil }
local function E() return _G.ARKHER end
local function parts(list) local o = {} for _, v in ipairs(list or {}) do if v and v.Parent and v:IsA("BasePart") then o[#o + 1] = v end end return o end
function PH.attachment(into)
  local parent = (into and into.Parent) and into or workspace
  local host = parent:IsA("BasePart") and parent or nil
  if not host then E().toast("Select a part first.") return end
  local a = Instance.new("Attachment") a.Parent = host
  E().undo.created(a) E().undo.commit("attachment") E().sel.set({ a })
end
local function ensureAtt(p, name)
  local a = p:FindFirstChild(name)
  if not a then a = Instance.new("Attachment") a.Name = name a.Parent = p end
  return a
end
function PH.constraint(kind, list, a)
  a = a or {}
  local p = parts(list)
  if #p < 2 then E().toast("Select 2 parts.") return end
  local map = { Weld = "WeldConstraint", Hinge = "HingeConstraint", Rope = "RopeConstraint", Rod = "RodConstraint", Spring = "SpringConstraint", Prismatic = "PrismaticConstraint", BallSocket = "BallSocketConstraint" }
  local cls = map[kind] or "WeldConstraint"
  local c = Instance.new(cls)
  if cls == "WeldConstraint" then c.Part0, c.Part1 = p[1], p[2]
  else
    c.Attachment0 = ensureAtt(p[1], "ARKHER_A0") c.Attachment1 = ensureAtt(p[2], "ARKHER_A1")
    if cls == "HingeConstraint" and a.motor then c.ActuatorType = Enum.ActuatorType.Motor c.AngularVelocity = a.speed or 10 end
    if cls == "PrismaticConstraint" and a.motor then c.ActuatorType = Enum.ActuatorType.Motor c.Velocity = a.speed or 10 end
    if cls == "RopeConstraint" then c.Length = (p[1].Position - p[2].Position).Magnitude end
    if c.Parent == nil then end
  end
  c.Parent = p[1]
  E().undo.created(c) E().undo.commit("constraint " .. kind) E().sel.set({ c })
end
function PH.align(list)
  local p = parts(list)
  if #p < 2 then E().toast("Select mover + target.") return end
  local ap = Instance.new("AlignPosition") ap.Attachment0 = ensureAtt(p[1], "ARKHER_A0") ap.Attachment1 = ensureAtt(p[2], "ARKHER_A1") ap.RigidityEnabled = true ap.Parent = p[1]
  local ao = Instance.new("AlignOrientation") ao.Attachment0 = ap.Attachment0 ao.Attachment1 = ap.Attachment1 ao.RigidityEnabled = true ao.Parent = p[1]
  E().undo.created(ap) E().undo.created(ao) E().undo.commit("align") E().sel.set({ ap })
end
function PH.explode()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local e = Instance.new("Explosion") e.Position = c e.BlastRadius = 12 e.BlastPressure = 500000 e.Parent = workspace
  E().out.log("Explosion at " .. tostring(c))
end
function PH.audit()
  local un, mass, joints = 0, 0, 0
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and not d.Anchored then un = un + 1 mass = mass + d:GetMass() end
    if d:IsA("Constraint") then joints = joints + 1 end
  end
  E().out.log(string.format("Physics: %d unanchored (%.0f mass), %d constraints.", un, mass, joints))
  if un > 500 then E().out.warn("Over 500 simulated parts: perf risk.") end
end
function PH.freezeAll(on)
  if on then
    PH.frozen = {}
    for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") and not d.Anchored then PH.frozen[#PH.frozen + 1] = d d.Anchored = true end end
    E().toast("Froze " .. #PH.frozen .. " parts.")
  else
    local n = 0
    for _, d in ipairs(PH.frozen or {}) do if d and d.Parent then d.Anchored = false n = n + 1 end end
    PH.frozen = nil
    E().toast("Unfroze " .. n .. " parts.")
  end
  E().undo.commit("freeze")
end
E().systems.phys = PH
return PH
