-- =============================================================
-- ARKHER Viewport Editor (13_Viewport) — camera, frame, medida, multi
-- UI 100% assada (VP3_*); este script LIGA os controles e traduz
-- gesto -> ViewportFrame/ViewportRig/TransformMany (server R11).
-- Ferramentas Select/Move/Rotate/Scale = SetMode REAL no nucleo 01.
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "13: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "13: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "13: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ============ helpers ============
local function find(name)
  return shell:FindFirstChild(name, true)
end
local function setText(name, text)
  local o = find(name)
  if o then pcall(function() o.Text = text end) end
end
local function setVisible(name, v)
  local o = find(name)
  if o then pcall(function() o.Visible = v end) end
end
local function on(name, fn)
  local o = find(name)
  if not o then return nil end
  local ev = o.Activated or o.MouseButton1Click
  if ev then pcall(function() ev:Connect(fn) end) return o end
  return nil
end
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  return (type(r) == "table" and r.result) or r, nil
end
local say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
end
local function cam()
  return workspace.CurrentCamera
end
local function typing()
  local ok, box = pcall(function() return UIS:GetFocusedTextBox() end)
  return ok and box ~= nil
end
local function platform()
  local inp = _G.ArkherInput
  if inp and inp.platform then
    local ok, p = pcall(inp.platform)
    if ok and p then return p end
  end
  return "PC"
end
local function overUI(x, y)
  local hit = false
  pcall(function()
    local pg = player:WaitForChild("PlayerGui")
    local list = pg:GetGuiObjectsAtPosition(x, y)
    local o = list and list[1] or nil
    local depth = 0
    while o and depth < 10 do
      if o.Name == "ArkherShell2" then hit = true break end
      o = o.Parent
      depth = depth + 1
    end
  end)
  return hit
end
local function rayView(x, y)
  local c = cam()
  if not c then return nil end
  local ok, ray = pcall(function() return c:ScreenPointToRay(x, y) end)
  if not ok or not ray then return nil end
  local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 5000) end)
  if not ok2 or not hit or not hit.Instance then return nil end
  return hit
end

-- ============ estado ============
local S = { open = false, tool = "Select", fov = 70,
  tmMode = "move", tm = { x = 0, y = 0, z = 0 },
  snap = true, step = 1, arm = nil, pA = nil, pB = nil,
  orbit = false, orbitA = 0, count = 0 }
local VP3_ALL = { "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status" }
local TE3_ALL = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status" }
local MD4_ALL = { "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status" }
local AN5_ALL = { "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status" }
local UI6_ALL = { "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status" }
local RW7_ALL = { "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status" }
local DO8_ALL = { "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status" }
local WO9_ALL = { "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status" }
local HO10_ALL = { "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status" }
local SC11_ALL = { "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status" }
local PL12_ALL = { "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }

local function refreshStatus()
  local st = string.format("%s · fov %d · snap %s/%s · multi %d",
    string.upper(S.tool), S.fov, S.snap and "ON" or "OFF", tostring(S.step), S.count)
  setText("VP3_StatL", st)
end
local function setOpen(v)
  S.open = v
  for _, n in ipairs(VP3_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  for _, n in ipairs(TE3_ALL) do setVisible(n, false) end
  for _, n in ipairs(MD4_ALL) do setVisible(n, false) end
  for _, n in ipairs(AN5_ALL) do setVisible(n, false) end
  for _, n in ipairs(UI6_ALL) do setVisible(n, false) end
  for _, n in ipairs(RW7_ALL) do setVisible(n, false) end
    for _, n in ipairs(DO8_ALL) do setVisible(n, false) end
    for _, n in ipairs(WO9_ALL) do setVisible(n, false) end
    for _, n in ipairs(HO10_ALL) do setVisible(n, false) end
    for _, n in ipairs(SC11_ALL) do setVisible(n, false) end
    for _, n in ipairs(PL12_ALL) do setVisible(n, false) end
  setVisible("M_MD", false)
  setVisible("M_AN", false)
  setVisible("M_UI", false)
  setVisible("M_RW", false)
    setVisible("M_DO", false)
    setVisible("M_WO", false)
    setVisible("M_HO", false)
    setVisible("M_SC", false)
    setVisible("M_PL", false)
  if v then
    for _, ed in ipairs({ "ArkherTerrain", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherHome", "ArkherScript", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    if platform() == "Mobile" then setVisible("M_VP", true) end
    refreshCount()
    say("Viewport Editor open (" .. platform() .. ").")
  else
    setVisible("M_VP", false)
    S.orbit = false
    setText("VP3_CamOrbit", "ORBIT: OFF")
    say("Viewport Editor closed.")
  end
end
function refreshCount()
  local r = api("ViewportFrame", {})
  if r and r.count then
    S.count = r.count
    setText("VP3_TM_Count", tostring(r.count) .. " selected")
    refreshStatus()
  end
end

-- ============ ferramentas (SetMode real no 01) ============
local BTN_BG, ACC_BG = nil, nil
pcall(function()
  local b = find("VP3_T_Select")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("VP3_Frame")
  if g then ACC_BG = g.BackgroundColor3 end
end)
local function setTool(t)
  S.tool = t
  for _, k in ipairs({ "Select", "Move", "Rotate", "Scale", "Measure" }) do
    local o = find("VP3_T_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == t and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  if t ~= "Measure" then
    local ok, err = pcall(function() clientBus:Invoke("SetMode", { key = t }) end)
    if not ok then say("SetMode: " .. tostring(err), true) end
  else
    say("Measure: SET A, click point 1, SET B, click point 2.")
  end
  refreshStatus()
end
for _, k in ipairs({ "Select", "Move", "Rotate", "Scale", "Measure" }) do
  local key = k
  on("VP3_T_" .. key, function() setTool(key) end)
end
on("VP3_Close", function() setOpen(false) end)

-- ============ camera ============
local function camTarget()
  local c = cam()
  if not c then return nil end
  local vs = nil
  pcall(function() vs = c.ViewportSize end)
  local cx, cy = 784, 441
  if vs then cx, cy = vs.X / 2, vs.Y / 2 end
  local hit = rayView(cx, cy)
  if hit then return hit.Position end
  local f = nil
  pcall(function() f = c.Focus.Position end)
  return f or Vector3.new(0, 0, 0)
end
local function camDist(t)
  local c = cam()
  if not c or not t then return 40 end
  local d = 40
  pcall(function() d = (c.CFrame.Position - t).Magnitude end)
  return math.clamp(d, 4, 2000)
end
local function applyLook(pos, t)
  local c = cam()
  if not c then return false end
  local ok = pcall(function() c.CFrame = CFrame.lookAt(pos, t) end)
  return ok
end
local function preset(dir)
  local t = camTarget()
  if not t then say("Camera: no camera.", true) return end
  local d = camDist(t)
  local pos = t + dir * d
  if applyLook(pos, t) then
    setText("VP3_CamV", string.format("(%.0f,%.0f,%.0f)", pos.X, pos.Y, pos.Z))
    say("Camera preset applied.")
  else
    say("Camera preset failed.", true)
  end
end
on("VP3_CamFront", function() preset(Vector3.new(0, 0.15, 1)) end)
on("VP3_CamTop", function() preset(Vector3.new(0, 1, 0.01)) end)
on("VP3_CamSide", function() preset(Vector3.new(1, 0.15, 0)) end)
on("VP3_CamIso", function() preset(Vector3.new(1, 0.7, 1).Unit) end)
on("VP3_CamOrbit", function()
  S.orbit = not S.orbit
  local t = camTarget()
  if S.orbit and t then
    local c = cam()
    if c then pcall(function()
      local off = c.CFrame.Position - t
      S.orbitA = math.atan2(off.X, off.Z)
    end) end
  end
  setText("VP3_CamOrbit", S.orbit and "ORBIT: ON" or "ORBIT: OFF")
end)
local function setFov(f)
  S.fov = math.clamp(math.floor(f), 1, 120)
  local c = cam()
  if c then pcall(function() c.FieldOfView = S.fov end) end
  setText("VP3_FovV", tostring(S.fov))
  refreshStatus()
end
on("VP3_FovM", function() setFov(S.fov - 5) end)
on("VP3_FovP", function() setFov(S.fov + 5) end)
on("VP3_Frame", function()
  local r, err = api("ViewportFrame", {})
  if err then say("Frame: " .. tostring(err), true) return end
  local t = Vector3.new(r.center.x, r.center.y, r.center.z)
  local pos = Vector3.new(r.pos.x, r.pos.y, r.pos.z)
  if applyLook(pos, t) then
    S.count = r.count or S.count
    setText("VP3_TM_Count", tostring(S.count) .. " selected")
    setText("VP3_CamV", string.format("(%.0f,%.0f,%.0f)", pos.X, pos.Y, pos.Z))
    say(r.msg or "Framed.")
    refreshStatus()
  else
    say("Frame: camera failed.", true)
  end
end)
on("VP3_RigSave", function()
  local c = cam()
  if not c then say("Rig: no camera.", true) return end
  local p, t = nil, camTarget()
  pcall(function() p = c.CFrame.Position end)
  if not (p and t) then say("Rig: unreadable camera.", true) return end
  local r, err = api("ViewportRig", { op = "set",
    pos = { x = p.X, y = p.Y, z = p.Z },
    target = { x = t.X, y = t.Y, z = t.Z }, fov = S.fov, mode = S.tool })
  if err then say("Rig: " .. tostring(err), true) else say("Rig saved.") end
end)
on("VP3_RigLoad", function()
  local r, err = api("ViewportRig", { op = "get" })
  if err or not (r and r.rig and r.rig.pos) then
    say("Rig: nothing saved yet.", true) return
  end
  local g = r.rig
  local pos = Vector3.new(g.pos.x, g.pos.y, g.pos.z)
  local t = g.target and Vector3.new(g.target.x, g.target.y, g.target.z) or pos
  if applyLook(pos, t) then
    if g.fov then setFov(g.fov) end
    say("Rig loaded.")
  else
    say("Rig: camera failed.", true)
  end
end)

-- ============ multi-transform ============
local function tmStep()
  if S.tmMode == "rot" then return S.snap and 15 or 5 end
  if S.tmMode == "scale" then return 0.1 end
  return S.snap and S.step or 0.5
end
local function tmShow()
  local f = (S.tmMode == "scale") and "%.2f" or "%.2f"
  setText("VP3_TM_XV", string.format(f, S.tm.x))
  setText("VP3_TM_YV", string.format(f, S.tm.y))
  setText("VP3_TM_ZV", string.format(f, S.tm.z))
end
local function tmMode(m)
  S.tmMode = m
  for _, k in ipairs({ "Move", "Rot", "Scale" }) do
    local o = find("VP3_TM_" .. k)
    if o then pcall(function()
      local active = (k:lower() == m) or (m == "move" and k == "Move")
      o.BackgroundColor3 = (active and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  if m == "scale" then S.tm = { x = 1, y = 1, z = 1 }
  else S.tm = { x = 0, y = 0, z = 0 } end
  tmShow()
end
on("VP3_TM_Move", function() tmMode("move") end)
on("VP3_TM_Rot", function() tmMode("rot") end)
on("VP3_TM_Scale", function() tmMode("scale") end)
for _, ax in ipairs({ "X", "Y", "Z" }) do
  local a = ax
  on("VP3_TM_" .. a .. "M", function()
    local k = a:lower()
    S.tm[k] = S.tm[k] - tmStep()
    tmShow()
  end)
  on("VP3_TM_" .. a .. "P", function()
    local k = a:lower()
    S.tm[k] = S.tm[k] + tmStep()
    tmShow()
  end)
end
on("VP3_TM_Reset", function()
  if S.tmMode == "scale" then S.tm = { x = 1, y = 1, z = 1 }
  else S.tm = { x = 0, y = 0, z = 0 } end
  tmShow()
end)
on("VP3_TM_Apply", function()
  local d = { x = S.tm.x, y = S.tm.y, z = S.tm.z }
  if S.snap and S.tmMode == "move" then
    d.x = math.floor(d.x / S.step + 0.5) * S.step
    d.y = math.floor(d.y / S.step + 0.5) * S.step
    d.z = math.floor(d.z / S.step + 0.5) * S.step
  end
  local r, err = api("TransformMany", { mode = S.tmMode, delta = d })
  if err then say("Multi: " .. tostring(err), true)
  else
    say(r.msg or "Applied.")
    refreshCount()
  end
end)

-- ============ snap ============
on("VP3_G_Snap", function()
  S.snap = not S.snap
  setText("VP3_G_Snap", S.snap and "SNAP: ON" or "SNAP: OFF")
  refreshStatus()
end)
local STEPS = { 0.25, 0.5, 1, 2, 4 }
local stepIdx = 3
on("VP3_G_StepM", function()
  stepIdx = math.max(stepIdx - 1, 1)
  S.step = STEPS[stepIdx]
  setText("VP3_G_StepV", tostring(S.step))
  refreshStatus()
end)
on("VP3_G_StepP", function()
  stepIdx = math.min(stepIdx + 1, #STEPS)
  S.step = STEPS[stepIdx]
  setText("VP3_G_StepV", tostring(S.step))
  refreshStatus()
end)

-- ============ measure ============
local measureLine = nil
local function clearMeasure()
  S.pA, S.pB, S.arm = nil, nil, nil
  setText("VP3_M_Val", "dist -")
  if measureLine then pcall(function() measureLine:Destroy() end) end
  measureLine = nil
end
local function drawMeasure()
  if measureLine then pcall(function() measureLine:Destroy() end) end
  measureLine = nil
  if not (S.pA and S.pB) then return end
  local dist = 0
  pcall(function() dist = (S.pB - S.pA).Magnitude end)
  setText("VP3_M_Val", string.format("%.2f studs", dist))
  local ok, p = pcall(Instance.new, "Part")
  if not ok or not p then return end
  pcall(function()
    p.Name = "ArkherMeasure"
    p.Anchored = true p.CanCollide = false p.CanQuery = false
    p.Color = Color3.fromRGB(240, 185, 70)
    p.Transparency = 0.25
    local mid = (S.pA + S.pB) / 2
    p.Size = Vector3.new(0.3, 0.3, math.max(dist, 0.5))
    p.CFrame = CFrame.lookAt(mid, S.pB)
    p.Parent = workspace
  end)
  measureLine = p
end
on("VP3_M_D1", function()
  S.arm = "A"
  say("Measure: click point A in the viewport.")
end)
on("VP3_M_D2", function()
  S.arm = "B"
  say("Measure: click point B in the viewport.")
end)
on("VP3_M_Clear", function() clearMeasure() say("Measure cleared.") end)
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or not S.arm or typing() then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseButton1 and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p or overUI(p.X, p.Y) then return end
  local hit = rayView(p.X, p.Y)
  if not hit then say("Measure: aim at something solid.", true) return end
  if S.arm == "A" then
    S.pA = hit.Position
    say("Point A set.")
  else
    S.pB = hit.Position
    say("Point B set.")
  end
  S.arm = nil
  drawMeasure()
end)

-- ============ mobile strip ============
on("M_VP_Frame", function()
  local r, err = api("ViewportFrame", {})
  if err then say("Frame: " .. tostring(err), true) return end
  local t = Vector3.new(r.center.x, r.center.y, r.center.z)
  local pos = Vector3.new(r.pos.x, r.pos.y, r.pos.z)
  if applyLook(pos, t) then say(r.msg or "Framed.") else say("Frame failed.", true) end
end)
on("M_VP_Meas", function()
  S.arm = S.pA and "B" or "A"
  say("Measure: tap point " .. S.arm .. ".")
end)

-- ============ orbit + cam readout ============
local tickAcc = 0
RunService.Heartbeat:Connect(function(dt)
  if not S.open then return end
  if S.orbit then
    local t = camTarget()
    local c = cam()
    if t and c then
      S.orbitA = S.orbitA + (dt or 0.016) * 0.5
      local d = camDist(t)
      local pos = t + Vector3.new(math.sin(S.orbitA) * d, d * 0.35, math.cos(S.orbitA) * d)
      pcall(function() c.CFrame = CFrame.lookAt(pos, t) end)
    end
  end
  tickAcc = tickAcc + (dt or 0.016)
  if tickAcc > 2 then
    tickAcc = 0
    refreshCount()
  end
end)

-- ============ boot ============
setTool("Select")
tmMode("move")
refreshStatus()
rawset(_G, "ArkherViewport", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
