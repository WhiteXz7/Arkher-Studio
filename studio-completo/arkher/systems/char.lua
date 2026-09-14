-- arkher/systems/char.lua — character rigs (manual R6/R15 builder + Humanoid APIs).
local CH = {}
local function E() return _G.ARKHER end
local LIMBS_R15 = {
  { n = "Head", s = Vector3.new(2, 1, 1), c = Vector3.new(0, 5, 0) },
  { n = "UpperTorso", s = Vector3.new(2, 2, 1), c = Vector3.new(0, 4, 0) },
  { n = "LowerTorso", s = Vector3.new(2, 2, 1), c = Vector3.new(0, 2, 0) },
  { n = "LeftUpperArm", s = Vector3.new(1, 2, 1), c = Vector3.new(-1.5, 4, 0) },
  { n = "RightUpperArm", s = Vector3.new(1, 2, 1), c = Vector3.new(1.5, 4, 0) },
  { n = "LeftLowerArm", s = Vector3.new(1, 2, 1), c = Vector3.new(-1.5, 2, 0) },
  { n = "RightLowerArm", s = Vector3.new(1, 2, 1), c = Vector3.new(1.5, 2, 0) },
  { n = "LeftHand", s = Vector3.new(1, 1, 1), c = Vector3.new(-1.5, 0.5, 0) },
  { n = "RightHand", s = Vector3.new(1, 1, 1), c = Vector3.new(1.5, 0.5, 0) },
  { n = "LeftUpperLeg", s = Vector3.new(1, 2, 1), c = Vector3.new(-0.5, 0, 0) },
  { n = "RightUpperLeg", s = Vector3.new(1, 2, 1), c = Vector3.new(0.5, 0, 0) },
  { n = "LeftLowerLeg", s = Vector3.new(1, 2, 1), c = Vector3.new(-0.5, -2, 0) },
  { n = "RightLowerLeg", s = Vector3.new(1, 2, 1), c = Vector3.new(0.5, -2, 0) },
  { n = "LeftFoot", s = Vector3.new(1, 1, 2), c = Vector3.new(-0.5, -3.2, 0.35) },
  { n = "RightFoot", s = Vector3.new(1, 1, 2), c = Vector3.new(0.5, -3.2, 0.35) },
}
local LIMBS_R6 = {
  { n = "Head", s = Vector3.new(2, 1, 1), c = Vector3.new(0, 4, 0) },
  { n = "Torso", s = Vector3.new(2, 2, 1), c = Vector3.new(0, 2.5, 0) },
  { n = "Left Arm", s = Vector3.new(1, 2, 1), c = Vector3.new(-1.5, 2.5, 0) },
  { n = "Right Arm", s = Vector3.new(1, 2, 1), c = Vector3.new(1.5, 2.5, 0) },
  { n = "Left Leg", s = Vector3.new(1, 2, 1), c = Vector3.new(-0.5, 0.5, 0) },
  { n = "Right Leg", s = Vector3.new(1, 2, 1), c = Vector3.new(0.5, 0.5, 0) },
}
local function buildRig(rig, at)
  local limbs = rig == "R6" and LIMBS_R6 or LIMBS_R15
  local m = Instance.new("Model") m.Name = rig .. "Char"
  local parts = {}
  for _, l in ipairs(limbs) do
    local p = Instance.new("Part") p.Name = l.n p.Size = l.s
    p.CFrame = (at or CFrame.new(0, 5, 0)) * CFrame.new(l.c)
    p.Anchored = true p.Parent = m parts[l.n] = p
  end
  local h = Instance.new("Humanoid") h.RigType = rig == "R6" and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15 h.Parent = m
  m.PrimaryPart = parts.Head
  -- joints
  local function joint(n, p0, p1, c0, c1)
    if not (parts[p0] and parts[p1]) then return end
    local j = Instance.new("Motor6D") j.Name = n j.Part0 = parts[p0] j.Part1 = parts[p1]
    j.C0 = c0 or CFrame.new() j.C1 = c1 or CFrame.new() j.Parent = parts[p0]
  end
  if rig == "R6" then
    joint("Neck", "Torso", "Head", CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    joint("Left Shoulder", "Torso", "Left Arm", CFrame.new(-1, 1, 0), CFrame.new(0.5, 1, 0))
    joint("Right Shoulder", "Torso", "Right Arm", CFrame.new(1, 1, 0), CFrame.new(-0.5, 1, 0))
    joint("Left Hip", "Torso", "Left Leg", CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    joint("Right Hip", "Torso", "Right Leg", CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
  else
    joint("Neck", "UpperTorso", "Head", CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
    joint("Waist", "LowerTorso", "UpperTorso", CFrame.new(0, 1, 0), CFrame.new(0, -1, 0))
    joint("LeftShoulder", "UpperTorso", "LeftUpperArm", CFrame.new(-1, 1, 0), CFrame.new(0.5, 1, 0))
    joint("RightShoulder", "UpperTorso", "RightUpperArm", CFrame.new(1, 1, 0), CFrame.new(-0.5, 1, 0))
    joint("LeftElbow", "LeftUpperArm", "LeftLowerArm", CFrame.new(0, -1, 0), CFrame.new(0, 1, 0))
    joint("RightElbow", "RightUpperArm", "RightLowerArm", CFrame.new(0, -1, 0), CFrame.new(0, 1, 0))
    joint("LeftWrist", "LeftLowerArm", "LeftHand", CFrame.new(0, -1, 0), CFrame.new(0, 0.5, 0))
    joint("RightWrist", "RightLowerArm", "RightHand", CFrame.new(0, -1, 0), CFrame.new(0, 0.5, 0))
    joint("LeftHip", "LowerTorso", "LeftUpperLeg", CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
    joint("RightHip", "LowerTorso", "RightUpperLeg", CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
    joint("LeftKnee", "LeftUpperLeg", "LeftLowerLeg", CFrame.new(0, -1, 0), CFrame.new(0, 1, 0))
    joint("RightKnee", "RightUpperLeg", "RightLowerLeg", CFrame.new(0, -1, 0), CFrame.new(0, 1, 0))
    joint("LeftAnkle", "LeftLowerLeg", "LeftFoot", CFrame.new(0, -1, 0), CFrame.new(0, 0.1, -0.35))
    joint("RightAnkle", "RightLowerLeg", "RightFoot", CFrame.new(0, -1, 0), CFrame.new(0, 0.1, -0.35))
  end
  m.Parent = workspace
  return m
end
function CH.new(a)
  a = a or {}
  local rig = a.rig or "R15"
  local m = buildRig(rig, E().systems.camera.focusCF())
  E().undo.created(m) E().undo.commit("new char") E().sel.set({ m })
end
function CH.fromNPC(npc) if npc and npc:IsA("Model") and npc:FindFirstChildWhichIsA("Humanoid") then npc.Name = "Character" E().toast("Converted.") else E().toast("Select an NPC model.") end end
function CH.poseReset(m) if m and m:IsA("Model") then for _, d in ipairs(m:GetDescendants()) do if d:IsA("Motor6D") then d.Transform = CFrame.new() end end E().toast("Pose reset.") else E().toast("Select a character.") end end
function CH.savePreset(m) E().panel.open("char_presets", { model = m }) end
function CH.ragdoll(m)
  if not (m and m:IsA("Model")) then E().toast("Select a character.") return end
  for _, d in ipairs(m:GetDescendants()) do
    if d:IsA("Motor6D") then
      local b = Instance.new("BallSocketConstraint") b.Attachment0 = b.Attachment0
      local a0 = Instance.new("Attachment") a0.CFrame = d.C0 a0.Parent = d.Part0
      local a1 = Instance.new("Attachment") a1.CFrame = d.C1 a1.Parent = d.Part1
      b.Attachment0 = a0 b.Attachment1 = a1 b.Parent = d.Part0
      d.Enabled = false
    end
  end
  for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false end end
  E().toast("Ragdoll on (preview).")
end
function CH.respawn(m)
  if not (m and m:IsA("Model")) then E().toast("Select a character.") return end
  local sp = workspace:FindFirstChildWhichIsA("SpawnLocation")
  local cf = sp and (sp.CFrame + Vector3.new(0, 5, 0)) or CFrame.new(0, 10, 0)
  m:PivotTo(cf)
  local h = m:FindFirstChildWhichIsA("Humanoid") if h then h.Health = h.MaxHealth end
end
function CH.kill(m) if m and m:IsA("Model") then local h = m:FindFirstChildWhichIsA("Humanoid") if h then h.Health = 0 end else E().toast("Select a character.") end end
function CH.fullReset(m)
  if not (m and m:IsA("Model")) then E().toast("Select a character.") return end
  CH.poseReset(m)
  local h = m:FindFirstChildWhichIsA("Humanoid")
  if h then h.Health = h.MaxHealth h.WalkSpeed = 16 h.JumpPower = 50 end
end
function CH.ikDrag(part)
  if not (part and part.Parent) then return end
  local m = part:FindFirstAncestorWhichIsA("Model")
  if not m then return end
  local j = nil
  for _, d in ipairs(m:GetDescendants()) do if d:IsA("Motor6D") and d.Part1 == part then j = d break end end
  if not j then E().toast("No joint drives this limb.") return end
  local UIS = game:GetService("UserInputService")
  local x0 = UIS:GetMouseLocation().X
  local c; c = UIS.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
      local deg = (UIS:GetMouseLocation().X - x0) / 2
      j.Transform = CFrame.Angles(0, 0, math.rad(deg))
    end
  end)
  local c2; c2 = UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then c:Disconnect() c2:Disconnect() E().undo.commit("ik") end
  end)
end
function CH.export(m)
  if not (m and m:IsA("Model")) then E().toast("Select a character.") return end
  local h = m:FindFirstChildWhichIsA("Humanoid")
  E().out.log("CHAR " .. game:GetService("HttpService"):JSONEncode({ rig = h and h.RigType.Name or "?", parts = #m:GetDescendants() }))
end
function CH.import(a) E().panel.open("char_import", a) end
E().systems.char = CH
return CH
