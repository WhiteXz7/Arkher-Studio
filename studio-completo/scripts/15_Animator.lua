-- =============================================================
-- ARKHER Animator (15_Animator) — keyframes reais em KeyframeSequence
-- UI 100% assada (AN5_*); este script LIGA os controles e traduz
-- gesto -> AnimRig/New/Keys/KeyAdd/KeyDel/PoseSet/JointSet/Play/Stop/
-- Scrub/IK/Export/Import (R13). Preview = Motor6D.Transform (canal real).
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "15: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "15: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "15: runtime missing (01_Nucleo must boot first).")
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
local S = { open = false, tool = "Select",
  seqId = nil, seqName = "-", rigId = nil, rigName = "-",
  joints = {}, jointIdx = 0, keys = {}, keyIdx = 0,
  time = 0, length = 0, playing = false, loop = false, speed = 1,
  easeS = "Linear", easeD = "InOut", weight = 1,
  pend = { x = 0, y = 0, z = 0 } }
local AN5_ALL = { "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status", "VP3_Rail", "VP3_Cam", "VP3_Trans",
  "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert",
  "MD4_Top", "MD4_IO", "MD4_Status", "UI6_Rail", "UI6_New", "UI6_Props",
  "UI6_Tree", "UI6_IO", "UI6_Status", "RW7_Rail", "RW7_Prof", "RW7_FX",
  "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status",
  "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status",
  "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status",
  "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local EASES = { "Linear", "Constant", "Elastic", "CubicV2", "Bounce", "Cubic" }
local EASE_SHORT = { Linear = "LIN", Constant = "CON", Elastic = "ELA",
  CubicV2 = "CV2", Bounce = "BNC", Cubic = "CUB" }
local EASED = { "InOut", "In", "Out" }
local EASED_SHORT = { InOut = "INOUT", In = "IN", Out = "OUT" }

local function curJoint()
  if S.jointIdx >= 1 and S.jointIdx <= #S.joints then return S.joints[S.jointIdx] end
  return nil
end
local function curKey()
  if S.keyIdx >= 1 and S.keyIdx <= #S.keys then return S.keys[S.keyIdx] end
  return nil
end
local function sffmt(t)
  t = math.max(t or 0, 0)
  local fr = math.floor(t * 30 + 0.5)
  return string.format("%d:%02d", math.floor(fr / 30), fr % 30)
end
local function refreshStatus()
  setText("AN5_StatL", string.format("%s · %s · %d keys · %s · %s",
    S.seqName, S.rigName, #S.keys, sffmt(S.time), string.upper(S.tool)))
end
local function showTime()
  setText("AN5_TLabel", sffmt(S.time))
  refreshStatus()
end
local marker = nil
local function setOpen(v)
  S.open = v
  for _, n in ipairs(AN5_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  for _, n in ipairs(OTHER_EDS) do setVisible(n, false) end
  setVisible("M_VP", false)
  setVisible("M_MD", false)
  setVisible("M_UI", false)
  setVisible("M_RW", false)
  setVisible("M_DO", false)
  setVisible("M_WO", false)
  setVisible("M_HO", false)
  setVisible("M_SC", false)
  setVisible("M_PL", false)
  if v then
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherHome", "ArkherScript", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    if platform() == "Mobile" then setVisible("M_AN", true) end
    say("Animator open (" .. platform() .. ").")
  else
    if S.playing then
      S.playing = false
      pcall(function() api("AnimStop", {}) end)
    end
    setVisible("M_AN", false)
    say("Animator closed.")
  end
end

-- ============ sequencia / rig ============
local function showJoint()
  local j = curJoint()
  setText("AN5_J_Name", j or "joint -")
  setText("AN5_R_XV", string.format("%d", S.pend.x))
  setText("AN5_R_YV", string.format("%d", S.pend.y))
  setText("AN5_R_ZV", string.format("%d", S.pend.z))
  refreshStatus()
end
local function showKey()
  local k = curKey()
  if k then
    setText("AN5_K_Name", string.format("%s %s", k.name or "key", sffmt(k.time)))
  else
    setText("AN5_K_Name", "key -")
  end
  refreshStatus()
end
local function loadKeys(silent)
  if not S.seqId then return false end
  local r, err = api("AnimKeys", { id = S.seqId })
  if err then
    if not silent then say("Keys: " .. tostring(err), true) end
    return false
  end
  S.keys = r.keys or {}
  S.length = r.length or 0
  if S.keyIdx < 1 or S.keyIdx > #S.keys then S.keyIdx = (#S.keys > 0) and 1 or 0 end
  setText("AN5_Info", string.format("%s\n%s\n%d joints %d keys %s",
    S.seqName, S.rigName, #S.joints, #S.keys, sffmt(S.length)))
  showKey()
  return true
end
local function adoptRig(id, name)
  local r, err = api("AnimRig", { id = id })
  if err then say("Rig: " .. tostring(err), true) return false end
  S.rigId = id
  S.rigName = name or (r.node and r.node.name) or id
  S.joints = r.joints or {}
  S.jointIdx = (#S.joints > 0) and 1 or 0
  S.pend = { x = 0, y = 0, z = 0 }
  say(r.msg or "Rig adopted.")
  showJoint()
  loadKeys(true)
  return true
end
local function adoptSeq(id, name)
  S.seqId = id
  S.seqName = name or id
  S.keyIdx = 1
  S.time = 0
  loadKeys()
  showTime()
end
local function scrubTo(t, silent)
  if not S.rigId then return false end
  S.time = math.max(t, 0)
  local r, err = api("AnimScrub", { id = S.seqId, rigId = S.rigId, time = S.time })
  if err then
    if not silent then say("Scrub: " .. tostring(err), true) end
    return false
  end
  S.time = r.time or S.time
  if r.length then S.length = r.length end
  showTime()
  return true
end

-- ============ ferramentas ============
local BTN_BG, ACC_BG = nil, nil
pcall(function()
  local b = find("AN5_T_Select")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("AN5_New")
  if g then ACC_BG = g.BackgroundColor3 end
end)
local function setTool(t)
  S.tool = t
  for _, k in ipairs({ "Select", "Pose" }) do
    local o = find("AN5_T_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == t and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  if t == "Select" then
    local ok, err = pcall(function() clientBus:Invoke("SetMode", { key = t }) end)
    if not ok then say("SetMode: " .. tostring(err), true) end
  else
    say("Pose: click a rig part to pick its joint.")
  end
  refreshStatus()
end
for _, k in ipairs({ "Select", "Pose" }) do
  local key = k
  on("AN5_T_" .. key, function() setTool(key) end)
end
on("AN5_Close", function() setOpen(false) end)

-- ============ rig / seq ============
on("AN5_New", function()
  local arg = { name = "Animacao" }
  if S.rigId then arg.rigId = S.rigId end
  local r, err = api("AnimNew", arg)
  if err then say("New: " .. tostring(err), true) return end
  adoptSeq(r.node.id, r.node.name)
  say(r.msg or "Sequence created.")
end)
on("AN5_Adopt", function()
  local inst = nil
  pcall(function()
    local sv = rt:FindFirstChild("SelectedInstance")
    if sv then inst = sv.Value end
  end)
  if not inst then say("Adopt: select a Model/Sequence first.", true) return end
  local isSeq, isModel = false, false
  pcall(function() isSeq = inst:IsA("KeyframeSequence") end)
  pcall(function() isModel = inst:IsA("Model") end)
  if not (isSeq or isModel) then say("Adopt: select a Model or KeyframeSequence.", true) return end
  local r, err = api("Identify", { object = inst })
  if err or not (r and r.id) then say("Adopt: " .. tostring(err or "identify failed"), true) return end
  if isSeq then adoptSeq(r.id, inst.Name) else adoptRig(r.id, inst.Name) end
end)
on("AN5_J_Prev", function()
  if #S.joints == 0 then return end
  S.jointIdx = ((S.jointIdx - 2) % #S.joints) + 1
  S.pend = { x = 0, y = 0, z = 0 }
  showJoint()
end)
on("AN5_J_Next", function()
  if #S.joints == 0 then return end
  S.jointIdx = (S.jointIdx % #S.joints) + 1
  S.pend = { x = 0, y = 0, z = 0 }
  showJoint()
end)

-- ============ pose ao vivo ============
for _, ax in ipairs({ "X", "Y", "Z" }) do
  local a = ax
  on("AN5_R_" .. a .. "M", function()
    S.pend[a:lower()] = S.pend[a:lower()] - 15
    showJoint()
  end)
  on("AN5_R_" .. a .. "P", function()
    S.pend[a:lower()] = S.pend[a:lower()] + 15
    showJoint()
  end)
end
on("AN5_R_Apply", function()
  local j = curJoint()
  if not j or not S.rigId then say("Pose: pick a joint first.", true) return end
  local r, err = api("AnimJointSet", { rigId = S.rigId, part = j,
    rot = { x = S.pend.x, y = S.pend.y, z = S.pend.z } })
  if err then say("Pose: " .. tostring(err), true) return end
  say("Joint posed (" .. j .. ").")
end)
on("AN5_R_Reset", function()
  local j = curJoint()
  if not j or not S.rigId then say("Pose: pick a joint first.", true) return end
  S.pend = { x = 0, y = 0, z = 0 }
  local r, err = api("AnimJointSet", { rigId = S.rigId, part = j,
    rot = { x = 0, y = 0, z = 0 } })
  if err then say("Pose: " .. tostring(err), true) return end
  showJoint()
  say("Joint reset (" .. j .. ").")
end)

-- ============ timeline ============
on("AN5_Play", function()
  if not S.seqId or not S.rigId then say("Play: need sequence + rig.", true) return end
  local r, err = api("AnimPlay", { id = S.seqId, rigId = S.rigId,
    loop = S.loop, speed = S.speed, from = S.time })
  if err then say("Play: " .. tostring(err), true) return end
  S.playing = true
  if r.length then S.length = r.length end
  setText("AN5_Play", "PAUSE")
  say(r.msg or "Playing.")
end)
on("AN5_Stop", function()
  local r, err = api("AnimStop", {})
  if err then say("Stop: " .. tostring(err), true) return end
  S.playing = false
  S.time = 0
  setText("AN5_Play", "PLAY")
  showTime()
  say(r.msg or "Stopped.")
end)
on("AN5_F_M", function()
  S.playing = false
  setText("AN5_Play", "PLAY")
  scrubTo(S.time - 1 / 30)
end)
on("AN5_F_P", function()
  S.playing = false
  setText("AN5_Play", "PLAY")
  scrubTo(S.time + 1 / 30)
end)
on("AN5_Loop", function()
  S.loop = not S.loop
  setText("AN5_Loop", S.loop and "LOOP ON" or "LOOP OFF")
  refreshStatus()
end)
on("AN5_S_M", function()
  S.speed = math.max(S.speed - 0.5, 0.5)
  setText("AN5_SV", string.format("%gx", S.speed))
end)
on("AN5_S_P", function()
  S.speed = math.min(S.speed + 0.5, 4)
  setText("AN5_SV", string.format("%gx", S.speed))
end)
RunService.Heartbeat:Connect(function(dt)
  if not (S.open and S.playing) then return end
  S.time = S.time + dt * S.speed
  if S.length > 0 and S.time >= S.length then
    if S.loop then S.time = S.time % S.length
    else
      S.time = S.length
      S.playing = false
      setText("AN5_Play", "PLAY")
    end
  end
  setText("AN5_TLabel", sffmt(S.time))
end)

-- ============ keys ============
on("AN5_K_Prev", function()
  if #S.keys == 0 then return end
  S.keyIdx = ((S.keyIdx - 2) % #S.keys) + 1
  local k = curKey()
  showKey()
  if k then scrubTo(k.time, true) end
end)
on("AN5_K_Next", function()
  if #S.keys == 0 then return end
  S.keyIdx = (S.keyIdx % #S.keys) + 1
  local k = curKey()
  showKey()
  if k then scrubTo(k.time, true) end
end)
on("AN5_K_Add", function()
  if not S.seqId then say("Key: create a sequence first.", true) return end
  local arg = { id = S.seqId, time = S.time }
  if S.rigId then arg.rigId = S.rigId end
  local r, err = api("AnimKeyAdd", arg)
  if err then say("Key: " .. tostring(err), true) return end
  say(string.format("Key @ %s (%d poses).", sffmt(S.time), r.poses or 0))
  loadKeys()
end)
on("AN5_K_Del", function()
  local k = curKey()
  if not k then say("Key: none selected.", true) return end
  local r, err = api("AnimKeyDel", { id = S.seqId, time = k.time })
  if err then say("Key: " .. tostring(err), true) return end
  say("Key deleted.")
  loadKeys()
end)
local function pushEase()
  local k, j = curKey(), curJoint()
  if not k or not j then
    setText("AN5_E_S", EASE_SHORT[S.easeS])
    setText("AN5_E_D", EASED_SHORT[S.easeD])
    setText("AN5_WV", string.format("%g", S.weight))
    return
  end
  local r, err = api("AnimPoseSet", { id = S.seqId, time = k.time, part = j,
    weight = S.weight, easingStyle = S.easeS, easingDir = S.easeD })
  if err then say("Ease: " .. tostring(err), true) return end
  setText("AN5_E_S", EASE_SHORT[S.easeS])
  setText("AN5_E_D", EASED_SHORT[S.easeD])
  setText("AN5_WV", string.format("%g", S.weight))
  say(string.format("Ease %s/%s w=%g (%s).", S.easeS, S.easeD, S.weight, j))
end
on("AN5_E_S", function()
  local i = 1
  for n, e in ipairs(EASES) do if e == S.easeS then i = n break end end
  S.easeS = EASES[(i % #EASES) + 1]
  pushEase()
end)
on("AN5_E_D", function()
  local i = 1
  for n, e in ipairs(EASED) do if e == S.easeD then i = n break end end
  S.easeD = EASED[(i % #EASED) + 1]
  pushEase()
end)
on("AN5_W_M", function()
  S.weight = math.max(S.weight - 0.5, 0)
  pushEase()
end)
on("AN5_W_P", function()
  S.weight = math.min(S.weight + 0.5, 10)
  pushEase()
end)

-- ============ IO ============
on("AN5_IO_Export", function()
  if not S.seqId then say("Export: no sequence.", true) return end
  local r, err = api("AnimExport", { id = S.seqId })
  if err then say("Export: " .. tostring(err), true) return end
  local box = find("AN5_IO_Text")
  if box then pcall(function() box.Text = r.json end) end
  print("[ArkherAnimator] ANIM export:\n" .. r.json)
  setText("AN5_IO_Stat", string.format("anim %d keys", r.keys or 0))
  say("ANIM exported (textbox + Output).")
end)
on("AN5_IO_Import", function()
  local txt = ""
  pcall(function() txt = find("AN5_IO_Text").Text or "" end)
  if txt == "" then say("Import: paste ANIM first.", true) return end
  local r, err = api("AnimImport", { json = txt })
  if err then say("Import: " .. tostring(err), true) return end
  adoptSeq(r.node.id, r.node.name)
  setText("AN5_IO_Stat", string.format("anim %d keys", r.keys or 0))
  say(r.msg or "ANIM imported.")
end)

-- ============ clique: select rig / pick joint ============
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or typing() then return end
  if S.tool ~= "Select" and S.tool ~= "Pose" then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseButton1 and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p or overUI(p.X, p.Y) then return end
  local hit = rayView(p.X, p.Y)
  if not hit then return end
  if S.tool == "Select" then
    local model = nil
    pcall(function()
      local o = hit.Instance
      while o do
        if o:IsA("Model") then model = o break end
        o = o.Parent
      end
    end)
    if not model then say("Select: that's not a rig.", true) return end
    local r, err = api("Identify", { object = model })
    if err or not (r and r.id) then say("Select: " .. tostring(err or "identify failed"), true) return end
    adoptRig(r.id, model.Name)
  else
    if not S.rigId or #S.joints == 0 then say("Pose: adopt a rig first.", true) return end
    local nm = nil
    pcall(function() nm = hit.Instance and hit.Instance.Name or nil end)
    local idx = nil
    for i, j in ipairs(S.joints) do if j == nm then idx = i break end end
    if not idx then say("Pose: that's not a joint of this rig.", true) return end
    S.jointIdx = idx
    S.pend = { x = 0, y = 0, z = 0 }
    showJoint()
    say("Joint: " .. nm .. ".")
  end
end)

-- ============ mobile strip ============
on("M_AN_New", function()
  local arg = { name = "Animacao" }
  if S.rigId then arg.rigId = S.rigId end
  local r, err = api("AnimNew", arg)
  if err then say("New: " .. tostring(err), true) return end
  adoptSeq(r.node.id, r.node.name)
  say(r.msg or "Sequence created.")
end)
on("M_AN_Play", function()
  if not S.seqId or not S.rigId then say("Play: need sequence + rig.", true) return end
  if S.playing then
    local r, err = api("AnimStop", {})
    if err then say("Stop: " .. tostring(err), true) return end
    S.playing = false
    S.time = 0
    showTime()
    say("Stopped.")
    return
  end
  local r, err = api("AnimPlay", { id = S.seqId, rigId = S.rigId, loop = S.loop, speed = 1, from = 0 })
  if err then say("Play: " .. tostring(err), true) return end
  S.playing = true
  say(r.msg or "Playing.")
end)
on("M_AN_Key", function()
  if not S.seqId then say("Key: need sequence.", true) return end
  local arg = { id = S.seqId, time = S.time }
  if S.rigId then arg.rigId = S.rigId end
  local r, err = api("AnimKeyAdd", arg)
  if err then say("Key: " .. tostring(err), true) return end
  say("Key added.")
  loadKeys()
end)

-- ============ boot ============
setTool("Select")
setText("AN5_E_S", "LIN")
setText("AN5_E_D", "INOUT")
setText("AN5_WV", "1")
setText("AN5_SV", "1x")
setText("AN5_Loop", "LOOP OFF")
showTime()
rawset(_G, "ArkherAnimator", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
