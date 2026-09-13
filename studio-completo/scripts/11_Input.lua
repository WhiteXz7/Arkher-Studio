-- =============================================================
-- ARKHER Input System (11_Input) — núcleo + 4 controllers
-- Camada fina de TRADUCAO: gesto/tecla/botao -> Action -> endpoint real
-- (ClientBus / MenusBus / API do servidor). NAO duplica sistemas e NAO
-- cria GUI: os 4 layouts sao assados (Desktop/Mobile/Console/VR Roots).
-- Plataforma detectada UMA vez no boot (sem if-mobile por frame);
-- override manual via _G.ArkherInput.setPlatform("Mobile"|...).
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "11: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "11: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "11: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 20)
local selInst = rt:WaitForChild("SelectedInstance", 20)
local selIdVal = rt:WaitForChild("SelectedId", 20)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ============ Bindings (acessibilidade: tudo editavel aqui) ============
local Bindings = {
  tool = { Select = Enum.KeyCode.One, Move = Enum.KeyCode.Two,
    Rotate = Enum.KeyCode.Three, Scale = Enum.KeyCode.Four, Transform = Enum.KeyCode.Five },
  frame = Enum.KeyCode.F,
  fly = { fwd = Enum.KeyCode.W, back = Enum.KeyCode.S, left = Enum.KeyCode.A,
    right = Enum.KeyCode.D, up = Enum.KeyCode.E, down = Enum.KeyCode.Q },
  fast = Enum.KeyCode.LeftShift, slow = Enum.KeyCode.LeftControl,
  duplicate = Enum.KeyCode.D, undo = Enum.KeyCode.Z, redo = Enum.KeyCode.Y,
  group = Enum.KeyCode.G, snap = Enum.KeyCode.N,
  box = Enum.KeyCode.B, lasso = Enum.KeyCode.L, kids = Enum.KeyCode.K,
  camSpeed = 24, camFast = 3.2, camSlow = 0.22,
  lookSpeed = 0.0042, panSpeed = 0.05, zoomStep = 6,
  invertX = 1, invertY = 1,
  stickSpeed = 620, cursorSpeed = 900,
  doubleTap = 0.35, dragThrottle = 0.1,
}
local Precise = { on = false } -- modo precisao (mobile/console/vr)

-- ============ Helpers ============
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
  if not o then warn("11: baked button missing: " .. name) return nil end
  -- Activated dispara p/ mouse + touch + gamepad (foco); fallback click.
  local ev = o.Activated or o.MouseButton1Click
  if ev then pcall(function() ev:Connect(fn) end) return o end
  warn("11: no click event on " .. name)
  return nil
end
local say -- forward (bus/menu usam)
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  return (type(r) == "table" and r.result) or r, nil
end
local function bus(cmd, arg)
  local ok, err = pcall(function() clientBus:Invoke(cmd, arg or {}) end)
  if not ok then say(cmd .. ": " .. tostring(err), true) end
end
local function menu(name, button)
  local ok, err = pcall(function() menusBus:Invoke("Menu", { name = name, button = button }) end)
  if not ok then say("Menu " .. name .. ": " .. tostring(err), true) end
end
say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
end
local function state()
  local ok, s = pcall(function() return clientBus:Invoke("State", {}) end)
  if ok and type(s) == "table" then return s end
  return {}
end
local function selId()
  -- espelho compartilhado 01<->11 (SelectedId) tem prioridade: 01 escreve
  -- nos cliques; 11 escreve no select via raycast (console/VR).
  if selIdVal and selIdVal.Value and selIdVal.Value ~= "" then return selIdVal.Value end
  return state().selectedId
end
local function setSharedSel(inst, id)
  pcall(function() if selInst then selInst.Value = inst end end)
  pcall(function() if selIdVal then selIdVal.Value = id or "" end end)
end
-- select via instancia (raycast console/VR): server confirma + espelha.
local function selectInstance(inst)
  if not inst then return nil end
  local r, err = api("Select", { inst = inst })
  if err or not (r and r.node and r.node.id) then
    say("Select: " .. tostring(err or "failed"), true) return nil
  end
  setSharedSel(inst, r.node.id)
  say("Selected: " .. inst.Name .. ".")
  return r
end
local function terrainOpen()
  local t = _G.ArkherTerrain
  if t and t.isOpen then
    local ok, v = pcall(t.isOpen)
    if ok then return v == true end
  end
  return false
end
local function selObj()
  if selInst and selInst.Value then return selInst.Value end
  return nil
end
local function cam()
  return workspace.CurrentCamera
end
local function typing()
  local ok, box = pcall(function() return UIS:GetFocusedTextBox() end)
  return ok and box ~= nil
end

-- ============ R9 multi-select (set; 01 continua single) ============
local Multi = { members = {}, ids = {}, boxes = {} }
local Remap = { capturing = nil } -- forward (PC usa; UI define capture)
local UI = { lang = "EN", scale = 1 } -- forward (PC usa scaleBump)
local EDITOR_MENUS = { "Terrain", "Models", "Animate", "UI", "Assets", "Tools" }
local ITEM_PT = { Frame = "Enquadrar", Props = "Props", Duplicate = "Duplicar",
  Delete = "Excluir", Group = "Grupo", Done = "Pronto", ["Axis X"] = "Eixo X",
  ["Axis Y"] = "Eixo Y", ["Axis Z"] = "Eixo Z", Snap = "Encaixe",
  Precision = "Precisão", ["FOV +"] = "FOV +", ["FOV -"] = "FOV -",
  Reset = "Reiniciar", Terrain = "Terreno", Models = "Modelos",
  Animate = "Animar", Assets = "Recursos", Tools = "Ferramentas" }
local function itemT(en)
  if UI.lang == "PT" then return ITEM_PT[en] or en end
  return en
end
local selSetVal = nil
pcall(function() selSetVal = rt:WaitForChild("SelectedSet", 5) end)
if not selSetVal then
  local ok, vv = pcall(Instance.new, "StringValue")
  if ok and vv then
    pcall(function() vv.Name = "SelectedSet" vv.Value = "" vv.Parent = rt end)
    selSetVal = vv
  end
end
local function multiMirror()
  pcall(function() if selSetVal then selSetVal.Value = table.concat(Multi.ids, ",") end end)
end
local function multiClearVisuals()
  for _, b in ipairs(Multi.boxes) do pcall(function() b:Destroy() end) end
  Multi.boxes = {}
end
local function multiSyncVisuals()
  multiClearVisuals()
  for i, o in ipairs(Multi.members) do
    if i > 100 then break end
    local isP = false
    pcall(function() isP = o:IsA("BasePart") end)
    if isP then
      local sbOk, sb = pcall(Instance.new, "SelectionBox")
      if sbOk and sb then
        pcall(function()
          sb.Name = "ArkherSetBox" sb.Adornee = o sb.Color3 = Color3.fromRGB(43, 203, 243)
          sb.LineThickness = 0.08 sb.SurfaceTransparency = 0.9 sb.Parent = o
        end)
        Multi.boxes[#Multi.boxes + 1] = sb
      end
    end
  end
end
local function multiSet(members, ids)
  Multi.members = members or {}
  Multi.ids = ids or {}
  multiMirror() multiSyncVisuals()
end
local function multiClear(localOnly)
  multiSet({}, {})
  if not localOnly then api("SelClear", {}) end
end
local function multiPrune()
  local alive, changed = {}, false
  for _, o in ipairs(Multi.members) do
    local ok = false
    pcall(function() ok = o.Parent ~= nil end)
    if ok then alive[#alive + 1] = o else changed = true end
  end
  if changed then Multi.members = alive multiSyncVisuals() end
end
local function multiCommit(members)
  members = members or {}
  local seen, uniq = {}, {}
  for _, o in ipairs(members) do
    if not seen[o] then seen[o] = true uniq[#uniq + 1] = o end
  end
  members = uniq
  if #members == 0 then multiClear() say("Nothing selected.") return 0 end
  local r, err = api("SelectMany", { insts = members })
  if err then say("Select: " .. tostring(err), true) return 0 end
  multiSet(members, (r and r.ids) or {})
  say("Selected " .. tostring(#members) .. ".")
  return #members
end

-- ============ R9 marquee / box / lasso ============
local Marquee = { active = false, mode = nil, x0 = 0, y0 = 0, prefix = "D_" }
local Lasso = { pts = {} }
local function marqueeShow(prefix, x0, y0, x1, y1)
  local m = find(prefix .. "Marquee")
  if not m then return end
  pcall(function()
    m.Visible = true
    m.Position = UDim2.fromOffset(math.min(x0, x1), math.min(y0, y1))
    m.Size = UDim2.fromOffset(math.max(2, math.abs(x1 - x0)), math.max(2, math.abs(y1 - y0)))
  end)
end
local function marqueeHide(prefix)
  local m = find(prefix .. "Marquee")
  if m then pcall(function() m.Visible = false end) end
end
local function viewportParts()
  local out = {}
  local ok, desc = pcall(function() return workspace:GetDescendants() end)
  if not ok or not desc then return out end
  for _, o in ipairs(desc) do
    local isP = false
    pcall(function() isP = o:IsA("BasePart") and not o:IsA("Terrain") end)
    if isP then out[#out + 1] = o end
  end
  return out
end
local function pickBox(x0, y0, x1, y1)
  local c = cam()
  if not c then return {} end
  local xa, xb = math.min(x0, x1), math.max(x0, x1)
  local ya, yb = math.min(y0, y1), math.max(y0, y1)
  local out = {}
  for _, o in ipairs(viewportParts()) do
    local pos = nil
    pcall(function() pos = o.Position end)
    if pos then
      local ok, v3, vis = pcall(function() return c:WorldToViewportPoint(pos) end)
      if ok and v3 and vis and v3.X >= xa and v3.X <= xb and v3.Y >= ya and v3.Y <= yb then
        out[#out + 1] = o
        if #out >= 200 then break end
      end
    end
  end
  return out
end
local function pip(x, y, poly)
  local inside = false
  local j = #poly
  for i = 1, #poly do
    local xi, yi = poly[i].X, poly[i].Y
    local xj, yj = poly[j].X, poly[j].Y
    if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) + 1e-9) + xi) then
      inside = not inside
    end
    j = i
  end
  return inside
end
local function pickLasso(poly)
  local c = cam()
  if not c or #poly < 3 then return {} end
  local out = {}
  for _, o in ipairs(viewportParts()) do
    local pos = nil
    pcall(function() pos = o.Position end)
    if pos then
      local ok, v3, vis = pcall(function() return c:WorldToViewportPoint(pos) end)
      if ok and v3 and vis and pip(v3.X, v3.Y, poly) then
        out[#out + 1] = o
        if #out >= 200 then break end
      end
    end
  end
  return out
end
local function dragStartEmpty(x, y)
  local c = cam()
  if not c then return true end
  local ok, ray = pcall(function() return c:ScreenPointToRay(x, y) end)
  if not ok or not ray then return true end
  local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 2000) end)
  return not (ok2 and hit and hit.Instance)
end

-- ============ Camera rig (manipulacao direta, padrao 05 Q4) ============
local Cam = {}
function Cam.frame()
  local o = selObj()
  local c = cam()
  if not o or not c then say("Frame: select an object first.", true) return false end
  local ok, p = pcall(function()
    if o:IsA("BasePart") then return o.Position end
    return o:GetPivot().Position
  end)
  if not ok then say("Frame failed.", true) return false end
  c.CFrame = CFrame.new(p + Vector3.new(10, 8, 10), p)
  say("Camera framed on " .. o.Name .. ".")
  return true
end
function Cam.dolly(steps)
  local c = cam()
  if not c then return end
  local cf = c.CFrame
  local d = cf.LookVector * (Bindings.zoomStep * (steps or 1))
  if Precise.on then d = cf.LookVector * (steps or 1) end
  c.CFrame = CFrame.new(cf.Position + d, cf.Position + d + cf.LookVector)
end
function Cam.pan(dx, dy)
  local c = cam()
  if not c then return end
  local cf = c.CFrame
  local dist = 20
  pcall(function() dist = (cf.Position - c.Focus.Position).Magnitude end)
  local s = (dist * 0.002 + 0.02) * (Precise.on and 0.2 or 1)
  local off = (-cf.RightVector * dx + cf.UpVector * dy) * s
  c.CFrame = CFrame.new(cf.Position + off, cf.Position + off + cf.LookVector)
end
function Cam.orbit(dx, dy)
  local c = cam()
  if not c then return end
  local cf = c.CFrame
  local t = nil
  pcall(function() t = c.Focus.Position end)
  if not t then t = cf.Position + cf.LookVector * 20 end
  local off = cf.Position - t
  local yaw = CFrame.Angles(0, -dx * Bindings.lookSpeed * Bindings.invertX, 0)
  local pitch = CFrame.Angles(-dy * Bindings.lookSpeed * Bindings.invertY, 0, 0)
  local np = t + (yaw * pitch * off)
  local ok = pcall(function() c.CFrame = CFrame.lookAt(np, t) end)
  if not ok then c.CFrame = CFrame.new(np.X, np.Y, np.Z) end
end
function Cam.fly(dt)
  local c = cam()
  if not c or typing() then return end
  local f = Bindings.fly
  local mv = Vector3.new(0, 0, 0)
  local okd = function(k) local ok, v = pcall(function() return UIS:IsKeyDown(k) end) return ok and v end
  if okd(f.fwd) then mv = mv + Vector3.new(0, 0, -1) end
  if okd(f.back) then mv = mv + Vector3.new(0, 0, 1) end
  if okd(f.left) then mv = mv + Vector3.new(-1, 0, 0) end
  if okd(f.right) then mv = mv + Vector3.new(1, 0, 0) end
  if okd(f.up) then mv = mv + Vector3.new(0, 1, 0) end
  if okd(f.down) then mv = mv + Vector3.new(0, -1, 0) end
  if mv.Magnitude == 0 then return end
  local sp = Bindings.camSpeed * (Precise.on and Bindings.camSlow or 1)
  if okd(Bindings.fast) then sp = sp * Bindings.camFast end
  if okd(Bindings.slow) then sp = sp * Bindings.camSlow end
  local cf = c.CFrame
  local dir = (cf.RightVector * mv.X + cf.UpVector * mv.Y - cf.LookVector * mv.Z)
  if dir.Magnitude > 0 then dir = dir.Unit end
  c.CFrame = CFrame.new(cf.Position + dir * sp * dt, cf.Position + dir * sp * dt + cf.LookVector)
end

-- ============ Shared Actions (traduzidas p/ endpoints reais) ============
local Actions = {}
function Actions.tool(name)
  bus("SetMode", { key = name })
end
function Actions.space()
  bus("SetSpace", {})
  local s = state()
  local sp = s.space or "Local"
  setText("M_B_Space", "SPACE: " .. string.upper(sp))
  say("Space: " .. sp .. ".")
end
function Actions.undo()
  local r, err = api("Undo", {})
  if err then say("Undo: " .. err, true) else say("Undo done.") end
end
function Actions.redo()
  local r, err = api("Redo", {})
  if err then say("Redo: " .. err, true) else say("Redo done.") end
end
function Actions.delete()
  if #Multi.members > 0 then Actions.deleteMany() return end
  local id = selId()
  if not id then say("Delete: select an object first.", true) return end
  local _, err = api("Delete", { id = id })
  if err then say("Delete: " .. err, true) else say("Deleted.") end
end
function Actions.deleteMany()
  if #Multi.members == 0 then say("Delete: nothing in set.", true) return end
  local r, err = api("DeleteMany", {})
  multiClear(true)
  if err then say("Delete: " .. err, true)
  else say("Deleted " .. tostring(r and r.deleted or "?") .. ".") end
end
function Actions.kids()
  local o = selObj()
  if not o then say("Kids: select an object first.", true) return end
  local out = {}
  local ok, kids = pcall(function() return o:GetChildren() end)
  if ok and kids then
    for _, k in ipairs(kids) do
      local isP = false
      pcall(function() isP = k:IsA("BasePart") end)
      if isP then out[#out + 1] = k end
    end
  end
  if #out == 0 then say("No part children.") return end
  multiCommit(out)
end
function Actions.duplicate()
  if #Multi.members > 0 then
    local r, err = api("DuplicateMany", {})
    multiClear()
    if err then say("Duplicate: " .. err, true)
    else say("Duplicated " .. tostring(r and r.duplicated or "?") .. ".") end
    return
  end
  local id = selId()
  if not id then say("Duplicate: select an object first.", true) return end
  local _, err = api("Duplicate", { id = id })
  if err then say("Duplicate: " .. err, true) else say("Duplicated.") end
end
function Actions.copy()
  local id = selId()
  if not id then say("Copy: select an object first.", true) return end
  local _, err = api("Copy", { id = id })
  if err then say("Copy: " .. err, true) else say("Copied.") end
end
function Actions.paste()
  local _, err = api("Paste", {})
  if err then say("Paste: " .. err, true) else say("Pasted.") end
end
function Actions.cut()
  local id = selId()
  if not id then say("Cut: select an object first.", true) return end
  local _, err = api("Cut", { id = id })
  if err then say("Cut: " .. err, true) else say("Cut.") end
end
function Actions.save()
  pcall(function() menusBus:Invoke("Save", {}) end)
end
function Actions.play()
  pcall(function() menusBus:Invoke("RunToggle", {}) end)
end
function Actions.pause()
  pcall(function() menusBus:Invoke("RunPause", {}) end)
end
function Actions.stop()
  pcall(function() menusBus:Invoke("RunStop", {}) end)
end
function Actions.snap()
  local id = selId()
  local o = selObj()
  if not id or not o then say("Snap: select a Part first.", true) return end
  local ok, p = pcall(function() return o.Position end)
  if not ok or not p then say("Snap: no Position.", true) return end
  local _, err = api("SetAny", { id = id, name = "Position", kind = "v",
    value = { x = math.floor(p.X + 0.5), y = math.floor(p.Y + 0.5), z = math.floor(p.Z + 0.5) } })
  if err then say("Snap: " .. err, true) else say("Snapped to 1-stud grid.") end
end
function Actions.frame()
  Cam.frame()
end
function Actions.group()
  if #Multi.members > 0 then
    local r, err = api("Group", { ids = Multi.ids })
    multiClear()
    if err then say("Group: " .. tostring(err), true)
    else say("Grouped " .. tostring(r and r.grouped or "?") .. " into a Model.") end
    return
  end
  local _, err = api("Group", {})
  if err then say("Group: " .. err, true) else say("Grouped into a Model.") end
end
function Actions.anchor()
  local _, err = api("SetAny", { id = selId(), name = "Anchored", kind = "b", value = true })
  if err then say("Anchor: " .. err, true) else say("Anchor ON.") end
end
function Actions.publish()
  pcall(function() menusBus:Invoke("OpenPublish", {}) end)
end
function Actions.openInsert()
  local d = _G.ArkherStudioDock
  if d and d.toggle then d.toggle("insert") else menu("Models", find("M_T_Insert")) end
end
function Actions.openToolbox()
  local d = _G.ArkherStudioDock
  if d and d.toggle then d.toggle("toolbox") else menu("Tools", find("M_MenuBtn")) end
end
function Actions.propsMenu(btn)
  menu("UI", btn)
end

-- ============ Platform detect + layout switch ============
local Roots = {}
local Platform = "PC"
local function detectPlatform()
  local okVR, vre = pcall(function() return VRService.VREnabled end)
  if okVR and vre then return "VR" end
  local okTF, tf = pcall(function() return GuiService:IsTenFootInterface() end)
  if okTF and tf then return "Console" end
  local touch, kb, pad = false, false, false
  pcall(function() touch = UIS.TouchEnabled and true or false end)
  pcall(function() kb = UIS.KeyboardEnabled and true or false end)
  pcall(function() pad = UIS.GamepadEnabled and true or false end)
  if pad and not touch and not kb then return "Console" end
  if touch and not kb then return "Mobile" end
  return "PC"
end
local Controllers = {}
local resetTransient -- forward: zera estados de gesto ao trocar de plataforma
local function setPlatform(p)
  if not Roots[p] then say("Unknown platform: " .. tostring(p), true) return Platform end
  pcall(function() if resetTransient then resetTransient() end end)
  Platform = p
  for k, root in pairs(Roots) do
    pcall(function() root.Visible = (k == p) end)
  end
  local c = Controllers[p]
  if c and c.enter then pcall(c.enter) end
  say("ARKHER Input: " .. p .. " layout active.")
  return Platform
end

-- =============================================================
-- PC controller: mouse + teclado de precisao, camera livre
-- =============================================================
local PC = { rmb = false, mmb = false }
function PC.enter()
  setText("F2_LogLine", "PC layout: 1-5 tools · F frame · WASD fly · RMB look · wheel zoom")
end
function PC.onInputBegan(input, gpe)
  if Platform ~= "PC" or gpe or typing() then return end
  local kc = input.KeyCode
  if Remap.capturing and kc ~= Enum.KeyCode.Unknown then Remap.capture(kc) return end
  local function ctrl()
    local a, b = pcall(function() return UIS:IsKeyDown(Enum.KeyCode.LeftControl) end)
    local c, d = pcall(function() return UIS:IsKeyDown(Enum.KeyCode.RightControl) end)
    return (a and b) or (c and d)
  end
  if input.UserInputType == Enum.UserInputType.MouseButton2 then PC.rmb = true return end
  if input.UserInputType == Enum.UserInputType.MouseButton3 then PC.mmb = true return end
  if input.UserInputType == Enum.UserInputType.MouseButton1 then PC.mDown(input) return end
  if kc == Bindings.tool.Select then Actions.tool("Select")
  elseif kc == Bindings.tool.Move then Actions.tool("Move")
  elseif kc == Bindings.tool.Rotate then Actions.tool("Rotate")
  elseif kc == Bindings.tool.Scale then Actions.tool("Scale")
  elseif kc == Bindings.tool.Transform then Actions.tool("Move") say("Transform: gizmo handles move/rotate/scale.")
  elseif kc == Bindings.frame then Actions.frame()
  elseif kc == Bindings.snap and not ctrl() then Actions.snap()
  elseif ctrl() and kc == Bindings.duplicate then Actions.duplicate()
  elseif ctrl() and kc == Bindings.undo then Actions.undo()
  elseif ctrl() and kc == Bindings.redo then Actions.redo()
  elseif ctrl() and kc == Bindings.group then Actions.group()
  elseif kc == Bindings.box then PC.armBox()
  elseif kc == Bindings.lasso then PC.armLasso()
  elseif kc == Bindings.kids and not ctrl() then Actions.kids()
  elseif kc == Enum.KeyCode.Delete and ctrl() then Actions.deleteMany()
  elseif kc == Enum.KeyCode.Escape and Marquee.mode then PC.disarm()
  elseif ctrl() and kc == Enum.KeyCode.Equals then UI.scaleBump(1)
  elseif ctrl() and kc == Enum.KeyCode.Minus then UI.scaleBump(-1)
  end
end
function PC.armBox()
  Marquee.mode = "box" Marquee.prefix = "D_" Marquee.active = false
  say("BOX: drag a rectangle (B/Esc cancels).")
end
function PC.armLasso()
  Marquee.mode = "lasso" Marquee.prefix = "D_" Marquee.active = false
  Lasso.pts = {}
  say("LASSO: drag a loop (L/Esc cancels).")
end
function PC.disarm()
  Marquee.mode = nil Marquee.active = false
  marqueeHide("D_")
  say("Marquee cancelled.")
end
function PC.mDown(input)
  if not Marquee.mode then return end
  local p = input.Position
  if not p then return end
  if not dragStartEmpty(p.X, p.Y) then Marquee.mode = nil return end
  Marquee.active = true Marquee.x0 = p.X Marquee.y0 = p.Y
  Lasso.pts = { { X = p.X, Y = p.Y } }
  marqueeShow("D_", p.X, p.Y, p.X + 2, p.Y + 2)
end
function PC.mMove(x, y)
  if not (Marquee.active and Marquee.mode) then return end
  if Marquee.mode == "box" then
    marqueeShow("D_", Marquee.x0, Marquee.y0, x, y)
  else
    Lasso.pts[#Lasso.pts + 1] = { X = x, Y = y }
    local xa, xb, ya, yb = x, x, y, y
    for _, q in ipairs(Lasso.pts) do
      xa = math.min(xa, q.X) xb = math.max(xb, q.X)
      ya = math.min(ya, q.Y) yb = math.max(yb, q.Y)
    end
    marqueeShow("D_", xa, ya, xb, yb)
  end
end
function PC.mUp(input)
  if not (Marquee.active and Marquee.mode) then return end
  local p = input.Position
  Marquee.active = false
  marqueeHide("D_")
  local mode = Marquee.mode
  Marquee.mode = nil
  if not p then return end
  if math.abs(p.X - Marquee.x0) < 6 and math.abs(p.Y - Marquee.y0) < 6 then return end
  if mode == "box" then
    multiCommit(pickBox(Marquee.x0, Marquee.y0, p.X, p.Y))
  else
    Lasso.pts[#Lasso.pts + 1] = { X = p.X, Y = p.Y }
    multiCommit(pickLasso(Lasso.pts))
  end
end
function PC.onInputEnded(input)
  if input.UserInputType == Enum.UserInputType.MouseButton2 then PC.rmb = false end
  if input.UserInputType == Enum.UserInputType.MouseButton3 then PC.mmb = false end
  if input.UserInputType == Enum.UserInputType.MouseButton1 then PC.mUp(input) end
end
function PC.onInputChanged(input)
  if Platform ~= "PC" then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseWheel then
    Cam.dolly(input.Position.Z > 0 and 1 or -1)
  elseif uit == Enum.UserInputType.MouseMovement then
    local d = input.Delta
    if PC.rmb then Cam.orbit(d.X, d.Y)
    elseif PC.mmb then Cam.pan(d.X, d.Y)
    elseif Marquee.active then
      local pp = input.Position
      if pp then PC.mMove(pp.X, pp.Y) end
    end
  end
end
Controllers.PC = PC

-- =============================================================
-- Mobile controller: touch-first, modos, painel numerico
-- =============================================================
local Mobile = { mode = "Select", axis = "X", lastTap = 0 }
local MOBILE_MENUS = { Select = nil, Build = "Models", Terrain = "Terrain", Model = "Models",
  Paint = "Models", Light = "Lighting", FX = "FX", Sound = "Audio", UI = "UI",
  Animate = "Animation", Physics = "Physics", Game = "Gameplay", Cloud = "Tools", Assets = "Assets" }
local Num = { mode = "POS", val = { X = 0, Y = 0, Z = 0 } }
local numShow, numStep, numApply -- forward (setMode usa)
function Mobile.setMode(m)
  Mobile.mode = m
  setText("M_Mode", (UI.lang == "PT" and "MODO: " or "MODE: ") .. string.upper(m))
  if m == "Move" or m == "Rotate" or m == "Scale" then
    Actions.tool(m)
    Num.mode = m == "Move" and "POS" or (m == "Rotate" and "ROT" or "SIZE")
    numShow("M_N_", "M_Numeric")
  elseif m == "Select" then
    Actions.tool(m)
    setVisible("M_Numeric", false)
  else
    setVisible("M_Numeric", false)
  end
end
function Mobile.setAxis(a)
  Mobile.axis = a
  setText("M_B_Axis", "AXIS: " .. a)
  setText("M_N_Axis", "AXIS: " .. a)
end
-- painel numerico compartilhado: prefixo M_N_ (mobile) ou C_N_ (console)
numShow = function(prefix, panel)
  local id = selId()
  local o = selObj()
  if id and o then
    local ok, p = pcall(function()
      if o:IsA("BasePart") then return o.Position end
      return o:GetPivot().Position
    end)
    if ok and p then Num.val = { X = p.X, Y = p.Y, Z = p.Z } end
  end
  for _, ax in ipairs({ "X", "Y", "Z" }) do
    setText(prefix .. ax .. "Val", string.format("%.2f", Num.val[ax] or 0))
  end
  setText(prefix .. "Mode", "MODE: " .. Num.mode)
  setVisible(panel, true)
end
numStep = function(prefix, ax, dir)
  local step = Precise.on and 0.1 or 1
  Num.val[ax] = (Num.val[ax] or 0) + dir * step
  setText(prefix .. ax .. "Val", string.format("%.2f", Num.val[ax]))
end
local function numApplyMany(panel)
  local v = Num.val
  local done, fails = 0, 0
  local dx, dy, dz = 0, 0, 0
  if Num.mode == "POS" then
    local prim = selObj()
    local pp = nil
    if prim then pcall(function() pp = prim.Position end) end
    if not pp then say("Transform: no primary position.", true) return end
    dx, dy, dz = v.X - pp.X, v.Y - pp.Y, v.Z - pp.Z
  end
  for i, o in ipairs(Multi.members) do
    local id = Multi.ids[i]
    local perr = true
    if id then
      if Num.mode == "POS" then
        local mp = nil
        pcall(function() mp = o.Position end)
        if mp then
          local _, e = api("SetAny", { id = id, name = "Position", kind = "v",
            value = { x = mp.X + dx, y = mp.Y + dy, z = mp.Z + dz } })
          perr = e
        end
      elseif Num.mode == "ROT" then
        local _, e = api("Set", { id = id, key = "Orientation", value = Vector3.new(v.X, v.Y, v.Z) })
        perr = e
      else
        local _, e = api("SetAny", { id = id, name = "Size", kind = "v",
          value = { x = math.max(v.X, 0.2), y = math.max(v.Y, 0.2), z = math.max(v.Z, 0.2) } })
        perr = e
      end
    end
    if perr then fails = fails + 1 else done = done + 1 end
  end
  if fails > 0 then say("Transform: " .. done .. " ok, " .. fails .. " failed.", true)
  else say("Transform applied to " .. done .. " (" .. Num.mode .. ").") setVisible(panel, false) end
end
numApply = function(prefix, panel)
  local id = selId()
  if not id then say("Transform: select an object first.", true) return end
  local v = Num.val
  if #Multi.members > 1 then numApplyMany(panel) return end
  local err
  if Num.mode == "POS" then
    _, err = api("SetAny", { id = id, name = "Position", kind = "v", value = { x = v.X, y = v.Y, z = v.Z } })
  elseif Num.mode == "ROT" then
    _, err = api("Set", { id = id, key = "Orientation", value = Vector3.new(v.X, v.Y, v.Z) })
  else
    _, err = api("SetAny", { id = id, name = "Size", kind = "v",
      value = { x = math.max(v.X, 0.2), y = math.max(v.Y, 0.2), z = math.max(v.Z, 0.2) } })
  end
  if err then say("Transform: " .. err, true)
  else say("Transform applied (" .. Num.mode .. ").") setVisible(panel, false) end
end
function Mobile.numShow() numShow("M_N_", "M_Numeric") end
function Mobile.numStep(ax, dir) numStep("M_N_", ax, dir) end
function Mobile.numApply() numApply("M_N_", "M_Numeric") end
function Mobile.enter()
  Mobile.setMode("Select")
  Mobile.setAxis("X")
  setText("M_Sel", "Selection: —")
end
function Mobile.refreshSel()
  local o = selObj()
  setText("M_Sel", "Selection: " .. (o and o.Name or "—"))
end
function Mobile.onTap(pos)
  if Platform ~= "Mobile" then return end
  if pos then
    local c = cam()
    if c then
      local ok, ray = pcall(function() return c:ScreenPointToRay(pos.X, pos.Y) end)
      if ok and ray then
        local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 2000) end)
        local cur = selObj()
        if ok2 and hit and hit.Instance and cur and hit.Instance == cur then
          Mobile.lastTap = 0
          Actions.kids()
          return
        end
      end
    end
  end
  local now = os.clock()
  if now - Mobile.lastTap < Bindings.doubleTap then
    Mobile.lastTap = 0
    Actions.frame()
  else
    Mobile.lastTap = now
  end
end
Controllers.Mobile = Mobile

-- =============================================================
-- Console controller: gamepad, cursor virtual, radial, foco
-- =============================================================
local Console = { tool = "Select", tools = { "Select", "Move", "Rotate", "Scale" },
  radialOpen = false, cursor = { X = 784, Y = 441 }, orbit = false, precision = false }
local RADIALS = {
  Select = { "Frame", "Props", "Duplicate", "Delete", "Group", "Done" },
  Move = { "Axis X", "Axis Y", "Axis Z", "Snap", "Precision", "Done" },
  Rotate = { "Axis X", "Axis Y", "Axis Z", "Snap", "Precision", "Done" },
  Scale = { "Axis X", "Axis Y", "Axis Z", "Snap", "Precision", "Done" },
  Camera = { "Frame", "FOV +", "FOV -", "Reset", "Precision", "Done" },
}
function Console.setTool(t)
  Console.tool = t
  setText("C_Tool", (UI.lang == "PT" and "FERRAMENTA: " or "TOOL: ") .. string.upper(t))
  if t ~= "Camera" then Actions.tool(t) end
end
function Console.cycle(dir)
  local list = Console.tools
  local idx = 1
  for i, t in ipairs(list) do if t == Console.tool then idx = i break end end
  idx = ((idx - 1 + dir) % #list) + 1
  Console.setTool(list[idx])
end
function Console.radial(show)
  Console.radialOpen = show
  if show then Console.radialMode = "tool" end
  setVisible("C_Radial", show)
  if show then
    local items = RADIALS[Console.tool] or RADIALS.Select
    for i = 0, 5 do setText("C_R_" .. i, itemT(items[i + 1]) or "···") end
    setText("C_R_Title", "RADIAL · " .. string.upper(Console.tool))
    local first = find("C_R_0")
    if first then pcall(function() GuiService.SelectedObject = first end) end
  end
end
function Console.radialPick(i)
  if Console.radialMode == "editors" then
    local m = EDITOR_MENUS[i + 1]
    if m then Console.radial(false) menu(m, find("C_R_" .. i)) end
    return
  end
  local items = RADIALS[Console.tool] or RADIALS.Select
  local item = items[i + 1]
  if not item then return end
  if item == "Done" then Console.radial(false)
  elseif item == "Frame" then Actions.frame()
  elseif item == "Props" then Actions.propsMenu(find("C_Props"))
  elseif item == "Duplicate" then Actions.duplicate()
  elseif item == "Delete" then Actions.delete()
  elseif item == "Group" then Actions.group()
  elseif item == "Snap" then Actions.snap()
  elseif item == "Precision" then Console.precision = not Console.precision Precise.on = Console.precision
    say("Precision " .. (Console.precision and "ON." or "OFF."))
  elseif item == "Axis X" or item == "Axis Y" or item == "Axis Z" then
    Console.radial(false)
    numShow("C_N_", "C_Numeric")
    say(item .. ": numeric transform.")
  elseif item == "FOV +" then local c = cam() if c then c.FieldOfView = math.min(c.FieldOfView + 5, 120) end
  elseif item == "FOV -" then local c = cam() if c then c.FieldOfView = math.max(c.FieldOfView - 5, 20) end
  elseif item == "Reset" then local c = cam() if c then c.FieldOfView = 70 c.CFrame = CFrame.new(0, 25, 40) end
  end
end
function Console.moveCursor(dx, dy)
  Console.cursor.X = math.clamp(Console.cursor.X + dx, 0, 1568)
  Console.cursor.Y = math.clamp(Console.cursor.Y + dy, 0, 882)
  if Console.aPress and not Console.aPress.box then
    if math.abs(Console.cursor.X - Console.aPress.x) + math.abs(Console.cursor.Y - Console.aPress.y) > 40 then
      Console.aPress.box = true
    end
  end
  if Console.aPress and Console.aPress.box then
    marqueeShow("C_", Console.aPress.x, Console.aPress.y, Console.cursor.X, Console.cursor.Y)
  end
  if Console.xDown then
    Console.xMoves = (Console.xMoves or 0) + 1
    if Console.xMoves < 3 then return end
    if not Console.xLasso then Console.xLasso = { { X = Console.cursor.X, Y = Console.cursor.Y } } end
    if #Console.xLasso < 128 then
      Console.xLasso[#Console.xLasso + 1] = { X = Console.cursor.X, Y = Console.cursor.Y }
    end
    local f = Console.xLasso[1]
    marqueeShow("C_", f.X, f.Y, Console.cursor.X, Console.cursor.Y)
  end
  local cur = find("C_Cursor")
  if cur then pcall(function()
    cur.Position = UDim2.fromOffset(math.floor(Console.cursor.X), math.floor(Console.cursor.Y))
  end) end
end
function Console.confirm()
  if Console.radialOpen then
    local sel = nil
    pcall(function() sel = GuiService.SelectedObject end)
    if sel then
      local idx = tonumber(tostring(sel.Name):match("C_R_(%d)"))
      if idx then Console.radialPick(idx) return end
    end
    Console.radial(false)
    return
  end
  -- cursor sobre GUI: foca p/ ativacao nativa do ButtonA; senao, raycast 3D.
  local hovered = nil
  pcall(function()
    local pg = player:WaitForChild("PlayerGui")
    local list = pg:GetGuiObjectsAtPosition(Console.cursor.X, Console.cursor.Y)
    hovered = list and list[1] or nil
  end)
  if hovered and hovered:IsA("GuiButton") then
    pcall(function() GuiService.SelectedObject = hovered end)
    say("Focused: " .. hovered.Name .. " (press A to activate).")
    return
  end
  local c = cam()
  if not c then return end
  local ok, ray = pcall(function()
    return c:ScreenPointToRay(Console.cursor.X, Console.cursor.Y)
  end)
  if not ok or not ray then say("Select: ray failed.", true) return end
  local ok2, hit = pcall(function()
    return workspace:Raycast(ray.Origin, ray.Direction * 2000)
  end)
  if ok2 and hit and hit.Instance then
    selectInstance(hit.Instance)
  else
    say("Nothing under cursor.")
  end
end
function Console.cancel()
  if Console.radialOpen then Console.radial(false)
  else pcall(function() menusBus:Invoke("CloseAll", {}) end) end
end
local function isShown(o, top)
  local p, depth = o, 0
  while p and p ~= top and depth < 12 do
    local v = true
    pcall(function() v = p.Visible end)
    if v == false then return false end
    p = p.Parent
    depth = depth + 1
  end
  return true
end
function Console.focusables()
  local list = {}
  for _, nm in ipairs({ "C_Menu", "C_Props", "C_R_0", "C_R_1", "C_R_2", "C_R_3", "C_R_4", "C_R_5" }) do
    local o = find(nm)
    if o and isShown(o, shell) then list[#list + 1] = o end
  end
  local host = shell.Parent and shell.Parent:FindFirstChild("ArkherXDeck")
  if host then
    local ok, desc = pcall(function() return host:GetDescendants() end)
    if ok and desc then
      for _, o in ipairs(desc) do
        if #list >= 300 then break end
        local isB = false
        pcall(function() isB = o:IsA("GuiButton") end)
        if isB and isShown(o, host) then list[#list + 1] = o end
      end
    end
  end
  return list
end
function Console.focusStep(dir)
  local list = Console.focusables()
  if #list == 0 then return end
  local cur = nil
  pcall(function() cur = GuiService.SelectedObject end)
  local idx = 1 -- sem foco = como se estivesse no 1o (1o passo cai no 2o)
  for i, o in ipairs(list) do if cur and o == cur then idx = i break end end
  if dir >= 0 then idx = (idx % #list) + 1
  else idx = ((idx - 2) % #list) + 1 end
  pcall(function() GuiService.SelectedObject = list[idx] end)
end
function Console.enter()
  Console.setTool("Select")
  setText("C_Mode", (UI.lang == "PT" and "MODO: " or "MODE: ") .. "EDITOR")
  Console.radial(false)
end
Controllers.Console = Console

-- =============================================================
-- VR controller: maos, raycast, manipulacao direta
-- trigger/grip: R1/R2 (analogico + digital); A/B confirm/cancel
-- =============================================================
local VR = { grabbing = false, grabOffset = nil, lastDrag = 0, hand = "RightHand" }
function VR.handCF(hand)
  hand = hand or VR.hand
  local ok, cf = pcall(function()
    return VRService:GetUserCFrame(Enum.UserCFrame[hand])
  end)
  if not ok or not cf then return nil end
  local c = cam()
  if not c then return nil end
  return c.CFrame * cf
end
function VR.raySelect()
  local hcf = VR.handCF("RightHand")
  local c = cam()
  if not hcf or not c then say("VR: hand tracking unavailable.", true) return end
  local origin = hcf.Position
  local dir = hcf.LookVector
  local ok, hit = pcall(function() return workspace:Raycast(origin, dir * 2000) end)
  if ok and hit and hit.Instance then
    selectInstance(hit.Instance)
  else
    say("Nothing under ray.")
  end
end
function VR.grabBegin()
  local o = selObj()
  local hcf = VR.handCF("RightHand")
  if not o or not hcf then return end
  local ok, p = pcall(function()
    if o:IsA("BasePart") then return o.Position end
    return o:GetPivot().Position
  end)
  if not ok then return end
  VR.grabbing = true
  VR.grabOffset = p - hcf.Position
  say("Grabbed " .. o.Name .. ".")
end
function VR.grabEnd()
  VR.grabbing = false
  VR.grabOffset = nil
  VR.trigHeld = false
end
function VR.grabStep()
  if not VR.grabbing then return end
  local now = os.clock()
  if now - VR.lastDrag < Bindings.dragThrottle then return end
  VR.lastDrag = now
  local id = selId()
  local hcf = VR.handCF("RightHand")
  if not id or not hcf or not VR.grabOffset then return end
  local p = hcf.Position + VR.grabOffset
  api("SetAny", { id = id, name = "Position", kind = "v", value = { x = p.X, y = p.Y, z = p.Z } })
end
function VR.enter()
  setText("V_Status", UI.lang == "PT" and "mao direita: raio · mao esquerda: painel" or "right hand: ray · left hand: panel")
  setText("V_Sel", "Selection: —")
end
Controllers.VR = VR

-- =============================================================
-- R9 extensoes: touch drag-box, A-drag, radial editores, VR extras,
-- painel espacial, settings/remap/idioma/escala
-- =============================================================
Console.aPress = nil Console.lastX = -10 Console.radialMode = "tool"
VR.lastTrig = -10 VR.xPress = nil
local TouchDrag = nil
local TouchLasso = nil -- {pts={}, moved=false} armada pelo long-press
function Mobile.touchBegin(input)
  TouchLasso = nil
  if terrainOpen() then return end
  if Mobile.mode ~= "Select" then return end
  if input.UserInputType ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p then return end
  if not dragStartEmpty(p.X, p.Y) then return end
  TouchDrag = { x0 = p.X, y0 = p.Y, box = false }
end
function Mobile.touchMove(input)
  if TouchLasso then
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    local pl = input.Position
    if not pl then return end
    local first = TouchLasso.pts[1]
    if math.abs(pl.X - first.X) + math.abs(pl.Y - first.Y) > 24 then TouchLasso.moved = true end
    if TouchLasso.moved then
      if #TouchLasso.pts < 128 then TouchLasso.pts[#TouchLasso.pts + 1] = { X = pl.X, Y = pl.Y } end
      marqueeShow("M_", TouchLasso.x0, TouchLasso.y0, pl.X, pl.Y)
    end
    return
  end
  if not TouchDrag then return end
  if input.UserInputType ~= Enum.UserInputType.Touch
    and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
  local p = input.Position
  if not p then return end
  if not TouchDrag.box and math.abs(p.X - TouchDrag.x0) + math.abs(p.Y - TouchDrag.y0) > 24 then
    TouchDrag.box = true
  end
  if TouchDrag.box then marqueeShow("M_", TouchDrag.x0, TouchDrag.y0, p.X, p.Y) end
end
function Mobile.touchEnd(input)
  if TouchLasso then
    local tl = TouchLasso
    TouchLasso = nil
    marqueeHide("M_")
    if tl.moved and #tl.pts >= 3 then
      multiCommit(pickLasso(tl.pts))
    else
      Actions.propsMenu(find("M_T_Props"))
    end
    return
  end
  if not TouchDrag then return end
  local td = TouchDrag
  TouchDrag = nil
  marqueeHide("M_")
  if not td.box then return end
  local p = input.Position
  if not p then return end
  multiCommit(pickBox(td.x0, td.y0, p.X, p.Y))
end
function Console.pressA()
  Console.aPress = { x = Console.cursor.X, y = Console.cursor.Y, box = false }
end
function Console.releaseA()
  local ap = Console.aPress
  Console.aPress = nil
  marqueeHide("C_")
  if terrainOpen() then return end
  if ap and ap.box then
    multiCommit(pickBox(ap.x, ap.y, Console.cursor.X, Console.cursor.Y))
  else
    Console.confirm()
  end
end
function Console.pressX()
  Console.xDown = os.clock()
  Console.xMoves = 0
  Console.xLasso = nil
end
function Console.releaseX()
  local t0 = Console.xDown
  Console.xDown = nil
  local pts = Console.xLasso
  Console.xLasso = nil
  marqueeHide("C_")
  if pts and #pts >= 3 then
    multiCommit(pickLasso(pts))
    return
  end
  local now = os.clock()
  if now - (Console.lastX or 0) < 0.4 then
    Console.lastX = 0
    Actions.kids()
  else
    Console.lastX = now
    Actions.snap()
  end
end
function Console.editorsRadial()
  if Console.radialOpen and Console.radialMode == "editors" then Console.radial(false) return end
  Console.radialMode = "editors"
  Console.radialOpen = true
  setVisible("C_Radial", true)
  for i = 0, 5 do setText("C_R_" .. i, itemT(EDITOR_MENUS[i + 1])) end
  setText("C_R_Title", "RADIAL · EDITORS")
  local first = find("C_R_0")
  if first then pcall(function() GuiService.SelectedObject = first end) end
end
function VR.pressTrigger()
  local now = os.clock()
  if now - VR.lastTrig < 0.4 then
    VR.lastTrig = 0
    VR.grabEnd()
    Actions.kids()
    VR.trigHeld = true
    return
  end
  VR.lastTrig = now
  VR.trigHeld = true
  if terrainOpen() then return end
  VR.raySelect() VR.grabBegin()
end
function VR.pressXBegin() VR.xPress = os.clock() end
function VR.releaseX()
  local t = VR.xPress
  VR.xPress = nil
  if t and os.clock() - t > 0.6 then Actions.delete() else Actions.snap() end
end

-- ============ R9 VR Spatial: V_Panel ancorado no mundo ============
local Spatial = { on = false, part = nil, sg = nil, home = nil }
function Spatial.toggle()
  if Spatial.on then Spatial.off() else Spatial.on_() end
end
function Spatial.on_()
  local c = cam()
  if not c then say("Spatial: no camera.", true) return end
  local panel = find("V_Panel")
  if not panel then return end
  local ok, part = pcall(Instance.new, "Part")
  if not ok or not part then return end
  pcall(function()
    part.Name = "ArkherVRPanel" part.Size = Vector3.new(28, 25, 1)
    part.Anchored = true part.CanCollide = false part.Transparency = 1
    part.CFrame = c.CFrame * CFrame.new(0, 0, -8)
    part.Parent = workspace
  end)
  local ok2, sg = pcall(Instance.new, "SurfaceGui")
  if not ok2 or not sg then pcall(function() part:Destroy() end) return end
  pcall(function()
    sg.Name = "ArkherVRSurface" sg.PixelsPerStud = 20
    sg.Face = Enum.NormalId.Front sg.Adornee = part sg.Parent = part
  end)
  Spatial.home = panel.Parent
  Spatial.panel = panel
  pcall(function() panel.Position = UDim2.fromOffset(0, 0) panel.Parent = sg end)
  Spatial.on, Spatial.part, Spatial.sg = true, part, sg
  local b = find("V_Spatial")
  if b then pcall(function() b.Text = "Spatial: ON" end) end
  say("VR panel anchored in world.")
end
function Spatial.off()
  local panel = Spatial.panel or find("V_Panel")
  if panel and Spatial.home then pcall(function() panel.Parent = Spatial.home end) end
  if panel then pcall(function() panel.Position = UDim2.fromOffset(524, 220) end) end
  pcall(function() if Spatial.part then Spatial.part:Destroy() end end)
  Spatial.on, Spatial.part, Spatial.sg, Spatial.home, Spatial.panel = false, nil, nil, nil, nil
  local b = find("V_Spatial")
  if b then pcall(function() b.Text = "Spatial: OFF" end) end
  say("VR panel back on screen.")
end

-- ============ R9 settings: remap, idioma, escala ============
local DEFAULT_BINDINGS = nil
local function snapDefaults()
  if DEFAULT_BINDINGS then return end
  DEFAULT_BINDINGS = { Select = Bindings.tool.Select, Move = Bindings.tool.Move,
    Rotate = Bindings.tool.Rotate, Scale = Bindings.tool.Scale, Frame = Bindings.frame,
    Box = Bindings.box, Lasso = Bindings.lasso, Snap = Bindings.snap }
end
local REMAP_SLOTS = {
  { btn = "D_S_B1", label = "Select tool", slot = "Select",
    get = function() return Bindings.tool.Select end,
    set = function(k) Bindings.tool.Select = k end,
    def = function() return DEFAULT_BINDINGS.Select end },
  { btn = "D_S_B2", label = "Move tool", slot = "Move",
    get = function() return Bindings.tool.Move end,
    set = function(k) Bindings.tool.Move = k end,
    def = function() return DEFAULT_BINDINGS.Move end },
  { btn = "D_S_B3", label = "Rotate tool", slot = "Rotate",
    get = function() return Bindings.tool.Rotate end,
    set = function(k) Bindings.tool.Rotate = k end,
    def = function() return DEFAULT_BINDINGS.Rotate end },
  { btn = "D_S_B4", label = "Scale tool", slot = "Scale",
    get = function() return Bindings.tool.Scale end,
    set = function(k) Bindings.tool.Scale = k end,
    def = function() return DEFAULT_BINDINGS.Scale end },
  { btn = "D_S_B5", label = "Frame camera", slot = "Frame",
    get = function() return Bindings.frame end,
    set = function(k) Bindings.frame = k end,
    def = function() return DEFAULT_BINDINGS.Frame end },
  { btn = "D_S_B6", label = "Box select", slot = "Box",
    get = function() return Bindings.box end,
    set = function(k) Bindings.box = k end,
    def = function() return DEFAULT_BINDINGS.Box end },
  { btn = "D_S_B7", label = "Lasso select", slot = "Lasso",
    get = function() return Bindings.lasso end,
    set = function(k) Bindings.lasso = k end,
    def = function() return DEFAULT_BINDINGS.Lasso end },
  { btn = "D_S_B8", label = "Snap to grid", slot = "Snap",
    get = function() return Bindings.snap end,
    set = function(k) Bindings.snap = k end,
    def = function() return DEFAULT_BINDINGS.Snap end },
}
snapDefaults() -- congela defaults no boot, antes de qualquer remap
local function kcName(k)
  local ok, n = pcall(function() return k.Name end)
  return (ok and n) or "..."
end
local function showBindings()
  snapDefaults()
  for _, s in ipairs(REMAP_SLOTS) do setText(s.btn, kcName(s.get())) end
end
function Remap.capture(kc)
  local slot = nil
  for _, s in ipairs(REMAP_SLOTS) do if s.btn == Remap.capturing then slot = s break end end
  Remap.capturing = nil
  if not slot then showBindings() return end
  if kc == Enum.KeyCode.Escape then showBindings() say("Remap cancelled.") return end
  slot.set(kc)
  showBindings()
  Remap.save()
  say(slot.label .. " = " .. kcName(kc) .. ".")
end
function Remap.reset()
  snapDefaults()
  for _, s in ipairs(REMAP_SLOTS) do s.set(s.def()) end
  showBindings()
  Remap.save()
  say("Bindings reset to defaults.")
end
function Remap.save()
  local b = {}
  for _, s in ipairs(REMAP_SLOTS) do
    local k = s.get()
    local ok, n = pcall(function() return k.Name end)
    if ok and n then b[s.slot] = n end
  end
  local _, err = api("RemapSet", { bindings = b })
  if err then say("Remap save: " .. tostring(err), true) end
end
function Remap.load()
  local r, err = api("RemapGet", {})
  if err or not (r and r.bindings) then return false end
  local n = 0
  for _, s in ipairs(REMAP_SLOTS) do
    local name = r.bindings[s.slot]
    if type(name) == "string" then
      local ok, kc = pcall(function() return Enum.KeyCode[name] end)
      if ok and kc then s.set(kc) n = n + 1 end
    end
  end
  showBindings()
  if n > 0 then say("Bindings restored (" .. tostring(r.source or "?") .. ").") end
  return n > 0
end
function UI.refreshScale()
  local sc = find("Shell2Scale")
  if sc then pcall(function() sc.Scale = UI.scale end) end
  setText("D_S_ScaleVal", tostring(math.floor(UI.scale * 100 + 0.5)) .. "%")
end
function UI.scaleBump(d)
  UI.scale = math.clamp((UI.scale or 1) + d * 0.1, 0.7, 1.6)
  UI.refreshScale()
end
function UI.openSettings()
  showBindings()
  UI.refreshScale()
  setText("D_S_Lang", "IDIOMA: " .. UI.lang)
  setVisible("D_Settings", true)
end
local ORIG, ORIGP = {}, {}
local LANG_PT = {
  M2_Assets = "Recursos", M2_Models = "Modelos", M2_Terrain = "Terreno",
  M2_Animation = "Animação", M2_Audio = "Áudio",
  M2_Lighting = "Iluminação", M2_Gameplay = "Jogabilidade",
  M2_Physics = "Física", M2_Tools = "Ferramentas",
  R2_Select = "⌈\nSelecionar", R2_Move = "✋\nMover",
  R2_Scale = "⛶\nEscala", R2_Rotate = "⟳\nGirar",
  R2_Play = "▶\nJogar", R2_Pause = "⏸\nPausar",
  R2_Stop = "⏹\nParar", R2_Undo = "↩\nDesfazer",
  R2_Redo = "↪\nRefazer", R2_Terrain = "⛰\nTerreno",
  R2_Insert = "＋\nInserir", R2_Script = "📜\nScript",
  R2_Animate = "🎬\nAnimar", R2_Save = "💾\nSalvar",
  R2_Publish = "☁\nPublicar", R2_Help = "❓\nAjuda",
  R2_Anchor = "⚓\nAncorar", R2_Snap = "🧲\nEncaixe",
  R2_Group = "🗂\nGrupo",
  T2_Gen = "Gerar", T2_Erode = "Erosão", T2_Craters = "Crateras",
  T2_Flat = "Aplainar", T2_Smooth = "Suavizar", T2_Noise = "Ruído",
  T2_SizeL = "Tamanho", T2_ForceL = "Força",
  C2_Clear = "Limpar", C2_All = "Tudo", C2_Warn = "Avisos", C2_Err = "Erros",
  TL2_Snap = "Encaixe", TL2_Loop = "Repetir",
  SM2_Start = "▶ Iniciar", TM2_Invite = "＋ Convidar",
  FR2_LibTitle = "BIBLIOTECA", FR2_ResTitle = "RECURSOS",
  FR2_QuickTitle = "FERRAMENTAS",
  FR2_A_Tree = "   🌳 Árvore", FR2_A_Crate = "   📦 Caixa",
  FR2_A_Lamp = "   💡 Lâmpada", FR2_A_Car = "   🚗 Carro",
  FR2_A_Coin = "   🪙 Moeda",
  FR2_A_House = "   🏠 Casa", FR2_A_Bridge = "   🌉 Ponte",
  FR2_A_Tower = "   🗼 Torre", FR2_A_Fountain = "   ⛲ Fonte",
  FR2_A_Portal = "   🌀 Portal",
  FR2_Export = "📤 Exportar", FR2_Import = "📥 Importar",
  FR2_Backup = "💾 Cópia", FR2_Sync = "🔄 Sincronizar",
  FR2_K1 = "F5 Jogar · F8 UI", FR2_K2 = "Del Excluir · Esc",
  FR2_K3 = "Ctrl+S Salvar", FR2_K4 = "Ctrl+Z Desfazer",
  F2_Out = "☰ Saída", F2_Err = "⚠ Erros",
  F2_Publish = "☁ Publicar",
  M_Title = "⬢ ARKHER · CELULAR",
  M_T_Select = "⌈\nSELECIONAR", M_T_Move = "✋\nMOVER",
  M_T_Rotate = "⟳\nGIRAR", M_T_Scale = "⛶\nESCALA",
  M_T_Camera = "📷\nCÂMERA", M_T_Insert = "＋\nINSERIR",
  M_T_Snap = "🧲\nENCAIXE",
  M_Cat_Select = "Selecionar", M_Cat_Build = "Construir",
  M_Cat_Terrain = "Terreno", M_Cat_Model = "Modelo", M_Cat_Paint = "Pintar",
  M_Cat_Light = "Luz", M_Cat_Sound = "Som", M_Cat_Animate = "Animar",
  M_Cat_Physics = "Física", M_Cat_Game = "Jogo", M_Cat_Cloud = "Nuvem",
  M_Cat_Assets = "Recursos",
  M_PropsOpen = "ABRIR PROPRIEDADES +",
  M_PropsHint = "propriedades reais vêm do painel do editor",
  M_N_Rot = "GIRAR", M_N_Size = "TAMANHO", M_N_Apply = "✓ APLICAR",
  M_N_Reset = "REINICIAR",
  M_Help = "toque=selecionar · 2×toque=enquadrar · pinça=zoom",
  M_B_Confirm = "✓ CONFIRMAR", M_B_Hint = "ações contextuais aparecem aqui",
  M_B_Prec = "🎯 PRECISÃO", M_B_Snap = "🧲 ENCAIXE",
  C_Props = "⚙ PROPS",
  C_PropsOpen = "ABRIR PROPRIEDADES +",
  C_P_Hint = "propriedades reais vêm do painel do editor",
  C_Leg1 = "A=confirmar · X=encaixe · Y=radial · B=voltar",
  C_Leg2 = "RB/LB=ferramenta · gatilho=órbita · DPad=foco",
  C_N_Apply = "✓ APLICAR",
  V_T_Select = "⌈\nSELECIONAR", V_T_Move = "✋\nMOVER",
  V_T_Rotate = "⟳\nGIRAR", V_T_Scale = "⛶\nESCALA",
  V_T_Camera = "📷\nCÂMERA", V_T_Insert = "＋\nINSERIR",
  V_Confirm = "✓ CONFIRMAR", V_Cancel = "✕ CANCELAR",
  V_Prec = "🎯 PRECISÃO", V_Snap = "🧲 ENCAIXE",
  V_Teleport = "📍 TELEPORTE", V_Editors = "Editores",
  V_Hint = "gatilho=raio+agarrar · 2×=filhos · X=encaixe",
  D_S_B1L = "Ferramenta seleção", D_S_B2L = "Ferramenta mover",
  D_S_B3L = "Ferramenta girar", D_S_B4L = "Ferramenta escala",
  D_S_B5L = "Enquadrar câmera", D_S_B6L = "Seleção caixa",
  D_S_B7L = "Seleção laço", D_S_B8L = "Encaixe na grade",
  D_S_KeyTitle = "Clique e pressione a nova tecla (Esc cancela)",
  D_S_Reset = "RESTAURAR", D_S_LangTitle = "IDIOMA",
  D_S_ScaleTitle = "ESCALA UI",
  D_S_Hint = "remap é só da sessão · escala 70–160%",
}
local LANG_PATH_PT = {
  { "T2_Panel", "Title", "⛰ TERRENO" },
  { "C2_Panel", "Title", "CONSOLE" },
  { "O2_Panel", "Title", "CAMADAS" },
  { "O2_WPanel", "Title", "MUNDO" },
  { "TL2_Panel", "Title", "LINHA DO TEMPO" },
  { "CV2_Panel", "Title", "CURVAS" },
  { "SM2_Panel", "Title", "SIMULAÇÃO" },
  { "D_Settings", "Title", "⚙ CONFIGURAÇÕES" },
  { "M_Drawer", "Title", "FERRAMENTAS" },
  { "M_PropsP", "Title", "PROPRIEDADES" },
  { "M_Numeric", "Title", "TRANSFORMAR" },
  { "C_Panel", "Title", "PAINEL" },
  { "C_Numeric", "Title", "TRANSFORMAR NUMÉRICO" },
  { "FR2_Help", "Title", "TECLAS" },
}
local function setLang(L)
  UI.lang = L
  if L == "PT" then
    for n, pt in pairs(LANG_PT) do
      if ORIG[n] == nil then local o = find(n) ORIG[n] = (o and o.Text) or false end
      setText(n, pt)
    end
    for _, e in ipairs(LANG_PATH_PT) do
      local k = e[1] .. "/" .. e[2]
      local p = find(e[1])
      local o = p and p:FindFirstChild(e[2])
      if ORIGP[k] == nil then ORIGP[k] = (o and o.Text) or false end
      if o then pcall(function() o.Text = e[3] end) end
    end
  else
    for n, tx in pairs(ORIG) do if tx then setText(n, tx) end end
    for k, tx in pairs(ORIGP) do
      if tx then
        local bar = k:find("/")
        local p = find(k:sub(1, bar - 1))
        local o = p and p:FindFirstChild(k:sub(bar + 1))
        if o then pcall(function() o.Text = tx end) end
      end
    end
  end
  setText("D_S_Lang", "IDIOMA: " .. L)
  if Platform == "Mobile" then
    setText("M_Mode", ((L == "PT" and "MODO: " or "MODE: ") .. string.upper(Mobile.mode)))
  end
  if Platform == "Console" then
    setText("C_Tool", ((L == "PT" and "FERRAMENTA: " or "TOOL: ") .. string.upper(Console.tool)))
    setText("C_Mode", (L == "PT" and "MODO: " or "MODE: ") .. "EDITOR")
  end
  if Platform == "VR" then VR.enter() end
  pcall(function()
    local sx = _G.ArkherStudioX
    if sx and sx.refreshTitles then sx.refreshTitles() end
  end)
  say(L == "PT" and "Idioma: Português." or "Language: English.")
end
function UI.toggleLang() setLang(UI.lang == "PT" and "EN" or "PT") end
function UI.setLang(L) setLang(L == "PT" and "PT" or "EN") end

-- ============ Botões assados: wiring por plataforma ============
-- MOBILE
on("M_MenuBtn", function(o) menu("Tools", o) end)
on("M_Undo", Actions.undo)
on("M_Redo", Actions.redo)
on("M_Save", Actions.save)
on("M_Play", Actions.play)
on("M_Stop", Actions.stop)
on("M_T_Select", function() Mobile.setMode("Select") end)
on("M_T_Move", function() Mobile.setMode("Move") end)
on("M_T_Rotate", function() Mobile.setMode("Rotate") end)
on("M_T_Scale", function() Mobile.setMode("Scale") end)
on("M_T_Camera", function() Mobile.setMode("Camera") setVisible("M_Numeric", false) end)
on("M_T_Insert", function(o) setVisible("M_Drawer", not (find("M_Drawer") and find("M_Drawer").Visible)) end)
on("M_T_Snap", Actions.snap)
on("M_T_Props", function(o) Actions.propsMenu(o) end)
on("M_DrawerClose", function() setVisible("M_Drawer", false) end)
on("M_PropsClose", function() setVisible("M_PropsP", false) end)
for cat, mname in pairs(MOBILE_MENUS) do
  if mname then
    on("M_Cat_" .. cat, function(o) setVisible("M_Drawer", false) menu(mname, o) end)
  else
    on("M_Cat_" .. cat, function() setVisible("M_Drawer", false) Mobile.setMode("Select") end)
  end
end
on("M_B_Confirm", function()
  if find("M_Numeric") and find("M_Numeric").Visible then Mobile.numApply()
  else setVisible("M_Drawer", false) setVisible("M_PropsP", false) say("Confirmed.") end
end)
on("M_B_Cancel", function()
  setVisible("M_Numeric", false) setVisible("M_Drawer", false) setVisible("M_PropsP", false)
  say("Cancelled.")
end)
on("M_B_Undo", Actions.undo)
on("M_B_Prec", function()
  Precise.on = not Precise.on
  local b = find("M_B_Prec")
  if b then pcall(function() b.Text = Precise.on and "🎯 PRECISE" or "🎯 PRECISION" end) end
  say("Precision " .. (Precise.on and "ON (0.1 step)." or "OFF (1 step)."))
end)
on("M_B_Snap", Actions.snap)
on("M_B_Axis", function()
  local nx = Mobile.axis == "X" and "Y" or (Mobile.axis == "Y" and "Z" or "X")
  Mobile.setAxis(nx)
end)
on("M_B_Space", Actions.space)
on("M_B_Del", Actions.delete)
for _, ax in ipairs({ "X", "Y", "Z" }) do
  on("M_N_" .. ax .. "Minus", function() Mobile.numStep(ax, -1) end)
  on("M_N_" .. ax .. "Plus", function() Mobile.numStep(ax, 1) end)
end
on("M_N_Rot", function()
  Num.mode = "ROT" setText("M_N_Mode", "MODE: ROT")
  say("Numeric mode: ROTATION (degrees).")
end)
on("M_N_Size", function()
  Num.mode = "SIZE" setText("M_N_Mode", "MODE: SIZE")
  say("Numeric mode: SIZE.")
end)
on("M_N_Axis", function()
  Num.mode = "POS" setText("M_N_Mode", "MODE: POS")
  say("Numeric mode: POSITION.")
end)
on("M_N_Apply", Mobile.numApply)
on("M_N_Cancel", function() setVisible("M_Numeric", false) say("Cancelled.") end)
on("M_N_Reset", function()
  Num.val = { X = 0, Y = 0, Z = 0 }
  for _, ax in ipairs({ "X", "Y", "Z" }) do setText("M_N_" .. ax .. "Val", "0.00") end
end)
on("M_N_Close", function() setVisible("M_Numeric", false) end)

-- CONSOLE
on("C_Menu", function(o) menu("Tools", o) end)
on("C_Props", function(o) Actions.propsMenu(o) end)
for i = 0, 5 do
  local idx = i
  on("C_R_" .. i, function() Console.radialPick(idx) end)
end
for _, ax in ipairs({ "X", "Y", "Z" }) do
  on("C_N_" .. ax .. "Minus", function() numStep("C_N_", ax, -1) end)
  on("C_N_" .. ax .. "Plus", function() numStep("C_N_", ax, 1) end)
end
on("C_N_Mode", function()
  Num.mode = Num.mode == "POS" and "ROT" or (Num.mode == "ROT" and "SIZE" or "POS")
  setText("C_N_Mode", "MODE: " .. Num.mode)
  say("Numeric mode: " .. Num.mode .. ".")
end)
on("C_N_Apply", function() numApply("C_N_", "C_Numeric") end)
on("C_N_Cancel", function() setVisible("C_Numeric", false) say("Cancelled.") end)
on("M_PropsOpen", function(o) setVisible("M_PropsP", false) Actions.propsMenu(o) end)
on("C_PropsOpen", function(o) setVisible("C_Panel", false) Actions.propsMenu(o) end)

-- VR
on("V_T_Select", function() Console.setTool("Select") Actions.tool("Select") end)
on("V_T_Move", function() Actions.tool("Move") end)
on("V_T_Rotate", function() Actions.tool("Rotate") end)
on("V_T_Scale", function() Actions.tool("Scale") end)
on("V_T_Camera", function() say("VR camera: move your head / teleport.") end)
on("V_T_Insert", function(o) Actions.openInsert() end)
on("V_Confirm", function() say("Confirmed.") end)
on("V_Cancel", function() Console.cancel() say("Cancelled.") end)
on("V_Prec", function()
  Precise.on = not Precise.on
  say("Precision " .. (Precise.on and "ON." or "OFF."))
end)
on("V_Snap", Actions.snap)
on("V_Teleport", Actions.frame)
on("V_Editors", function(o) menu("Tools", o) end)
on("V_Spatial", function() Spatial.toggle() end)

-- DESKTOP: R2 extras (Anchor/Snap/Group) via endpoints compartilhados
on("R2_Anchor", function()
  local id = selId()
  if not id then say("Anchor: select an object first.", true) return end
  local pr = api("PropsAll", { id = id })
  local cur = nil
  if pr and pr.fields then for _, f in ipairs(pr.fields) do if f.key == "Anchored" then cur = f.value break end end end
  local _, err = api("SetAny", { id = id, name = "Anchored", kind = "b", value = not cur })
  if err then say("Anchor: " .. err, true) else say("Anchor " .. ((not cur) and "ON." or "OFF.")) end
end)
on("R2_Snap", Actions.snap)
on("R2_Group", Actions.group)

-- DESKTOP: D_Settings (remap + idioma + escala)
for _, s in ipairs(REMAP_SLOTS) do
  local slot = s
  on(slot.btn, function()
    Remap.capturing = slot.btn
    setText(slot.btn, "...")
    say(slot.label .. ": press a key (Esc cancels).")
  end)
end
on("D_S_Reset", Remap.reset)
on("D_S_Lang", function() UI.toggleLang() end)
on("D_S_ScaleMinus", function() UI.scaleBump(-1) end)
on("D_S_ScalePlus", function() UI.scaleBump(1) end)
on("D_S_Close", function() setVisible("D_Settings", false) say("Settings closed.") end)

-- ============ Roteamento global de input ============
local ThumbL, ThumbR = { X = 0, Y = 0 }, { X = 0, Y = 0 }
UIS.InputBegan:Connect(function(input, gpe)
  if gpe then return end
  if Platform == "PC" then PC.onInputBegan(input, gpe) return end
  if Platform == "Console" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonA then Console.pressA()
    elseif kc == Enum.KeyCode.ButtonB then Console.cancel()
    elseif kc == Enum.KeyCode.ButtonX then Console.pressX()
    elseif kc == Enum.KeyCode.ButtonY then Console.radial(not Console.radialOpen)
    elseif kc == Enum.KeyCode.ButtonR1 then Console.cycle(1)
    elseif kc == Enum.KeyCode.ButtonL1 then Console.cycle(-1)
    elseif kc == Enum.KeyCode.ButtonR2 or kc == Enum.KeyCode.ButtonL2 then Console.orbit = true
    elseif kc == Enum.KeyCode.ButtonStart then menu("Tools", find("C_Menu"))
    elseif kc == Enum.KeyCode.ButtonSelect then Console.editorsRadial()
    elseif kc == Enum.KeyCode.DPadUp or kc == Enum.KeyCode.DPadRight then Console.focusStep(1)
    elseif kc == Enum.KeyCode.DPadDown or kc == Enum.KeyCode.DPadLeft then Console.focusStep(-1)
    end
    return
  end
  if Platform == "VR" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonR2
      or kc == Enum.KeyCode.ButtonL1 or kc == Enum.KeyCode.ButtonL2 then
      VR.pressTrigger()
    elseif kc == Enum.KeyCode.ButtonA then say("Confirmed.")
    elseif kc == Enum.KeyCode.ButtonB then Console.cancel() say("Cancelled.")
    elseif kc == Enum.KeyCode.ButtonX then VR.pressXBegin()
    elseif kc == Enum.KeyCode.ButtonY then Precise.on = not Precise.on
      say("Precision " .. (Precise.on and "ON." or "OFF."))
    end
    return
  end
  if Platform == "Mobile" then
    Mobile.touchBegin(input)
    return
  end
end)
UIS.InputEnded:Connect(function(input)
  if Platform == "PC" then PC.onInputEnded(input) return end
  if Platform == "Console" then
    if input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
      Console.orbit = false
    elseif input.KeyCode == Enum.KeyCode.ButtonA then
      Console.releaseA()
    elseif input.KeyCode == Enum.KeyCode.ButtonX then
      Console.releaseX()
    end
    return
  end
  if Platform == "VR" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonR2
      or kc == Enum.KeyCode.ButtonL1 or kc == Enum.KeyCode.ButtonL2 then
      VR.trigHeld = false
      VR.grabEnd()
    elseif kc == Enum.KeyCode.ButtonX then
      VR.releaseX()
    end
  end
  if Platform == "Mobile" then
    Mobile.touchEnd(input)
  end
end)
UIS.InputChanged:Connect(function(input)
  if Platform == "PC" then PC.onInputChanged(input) return end
  if Platform == "Console" then
    local uit = input.UserInputType
    if uit == Enum.UserInputType.Gamepad1 then
      local kc = input.KeyCode
      if kc == Enum.KeyCode.Thumbstick1 then ThumbL = input.Position
      elseif kc == Enum.KeyCode.Thumbstick2 then ThumbR = input.Position end
    end
    return
  end
  if Platform == "VR" then
    -- gatilhos analogicos: comecam como Changed com Position.Z
    local kc = input.KeyCode
    if (kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonR2
      or kc == Enum.KeyCode.ButtonL1 or kc == Enum.KeyCode.ButtonL2) then
      local z = input.Position and input.Position.Z or 0
      if z > 0.5 and not VR.grabbing then VR.pressTrigger()
      elseif z <= 0.15 and VR.grabbing then VR.grabEnd() end
    end
    return
  end
  if Platform == "Mobile" then
    Mobile.touchMove(input)
    return
  end
end)
-- touch (mobile): tap duplo, long-press, pinca, pan de 2 dedos
pcall(function()
  UIS.TouchTapInWorld:Connect(function(pos, processed)
    if not processed then Mobile.onTap(pos) end
  end)
end)
pcall(function()
  UIS.TouchLongPress:Connect(function(pos, state, processed)
    if Platform == "Mobile" and not processed and state == Enum.UserInputState.Begin then
      if terrainOpen() then return end
      TouchDrag = nil
      TouchLasso = { pts = { { X = pos.X, Y = pos.Y } }, moved = false, x0 = pos.X, y0 = pos.Y }
    end
  end)
end)
pcall(function()
  UIS.TouchPinch:Connect(function(touches, scale, velocity, state, rotation, velocity2)
    if Platform ~= "Mobile" then return end
    if state == Enum.UserInputState.Change then
      Cam.dolly(scale > 1 and 1 or -1)
    end
  end)
end)
pcall(function()
  UIS.TouchPan:Connect(function(touches, total, velocity, state, rotation, velocity2)
    if Platform ~= "Mobile" then return end
    if state == Enum.UserInputState.Change and #touches >= 2 then
      Cam.pan(-velocity.X * 0.05, velocity.Y * 0.05)
    end
  end)
end)

-- loop: fly (PC), sticks/cursor (console), grab (VR), labels (mobile/vr)
local selTick = 0
RunService.Heartbeat:Connect(function(dt)
  if Platform == "PC" then
    Cam.fly(dt or 0.016)
  elseif Platform == "Console" then
    local dz = function(v) return math.abs(v) > 0.18 and v or 0 end
    local lx, ly = dz(ThumbL.X or 0), dz(ThumbL.Y or 0)
    local rx, ry = dz(ThumbR.X or 0), dz(ThumbR.Y or 0)
    local c = cam()
    if c and (lx ~= 0 or ly ~= 0) then
      if Console.orbit then Cam.orbit(lx * 14, -ly * 14)
      else
        local cf = c.CFrame
        local dir = cf.RightVector * lx - cf.LookVector * ly
        c.CFrame = CFrame.new(cf.Position + dir * Bindings.stickSpeed * (dt or 0.016) / 60,
          cf.Position + dir * Bindings.stickSpeed * (dt or 0.016) / 60 + cf.LookVector)
      end
    end
    if rx ~= 0 or ry ~= 0 then
      Console.moveCursor(rx * Bindings.cursorSpeed * (dt or 0.016), -ry * Bindings.cursorSpeed * (dt or 0.016))
    end
  elseif Platform == "VR" then
    VR.grabStep()
  end
  selTick = selTick + (dt or 0.016)
  if selTick > 1 then
    selTick = 0
    multiPrune()
    if Platform == "Mobile" then Mobile.refreshSel()
    elseif Platform == "VR" then
      local o = selObj()
      setText("V_Sel", "Selection: " .. (o and o.Name or "—"))
    end
  end
end)

-- R11: trocar de plataforma nunca carrega gesto pela metade (gatilho/A/
-- drag/marquee presos). Estados transientes zerados a cada setPlatform.
resetTransient = function()
  pcall(function() VR.grabEnd() VR.xPress = nil end)
  pcall(function()
    Console.aPress = nil Console.xDown = nil Console.xLasso = nil
    Console.xMoves = 0 Console.orbit = false
  end)
  pcall(function() TouchDrag = nil TouchLasso = nil end)
  pcall(function() PC.rmb = false PC.mmb = false PC.disarm() end)
  pcall(function()
    marqueeHide("D_") marqueeHide("M_") marqueeHide("C_")
  end)
end

-- ============ Boot ============
Roots = {
  PC = shell:WaitForChild("DesktopRoot", 30),
  Mobile = shell:WaitForChild("MobileRoot", 30),
  Console = shell:WaitForChild("ConsoleRoot", 30),
  VR = shell:WaitForChild("VRoot", 30),
}
assert(Roots.PC and Roots.Mobile and Roots.Console and Roots.VR, "11: 4 layout roots missing from bake.")
rawset(_G, "ArkherInput", {
  platform = function() return Platform end,
  setPlatform = setPlatform,
  redetect = function() return setPlatform(detectPlatform()) end,
  actions = Actions,
  bindings = Bindings,
  detect = detectPlatform,
  openSettings = function() return UI.openSettings() end,
  toggleLang = function() return UI.toggleLang() end,
  setLang = function(L) return UI.setLang(L) end,
  lang = function() return UI.lang end,
  multi = Multi,
  reloadBindings = function() return Remap.load() end,
  consoleCursor = function() return { X = Console.cursor.X, Y = Console.cursor.Y } end,
  padPaintHeld = function() return Console.aPress ~= nil end,
  vrPaintHeld = function() return VR.trigHeld == true end,
  vrHandRay = function()
    local hcf = VR.handCF("RightHand")
    if not hcf then return nil end
    local o, d = hcf.Position, hcf.LookVector
    return { ox = o.X, oy = o.Y, oz = o.Z, dx = d.X, dy = d.Y, dz = d.Z }
  end,
})
pcall(function() Remap.load() end)
setPlatform(detectPlatform())
