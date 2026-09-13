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
  local yaw = CFrame.Angles(0, -dx * Bindings.lookSpeed * Bindings.invertX, 0)
  local pitch = CFrame.Angles(-dy * Bindings.lookSpeed * Bindings.invertY, 0, 0)
  c.CFrame = CFrame.new(cf.Position) * yaw * (CFrame.new(cf.Position):Inverse() * cf) * pitch
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
  local id = selId()
  if not id then say("Delete: select an object first.", true) return end
  local _, err = api("Delete", { id = id })
  if err then say("Delete: " .. err, true) else say("Deleted.") end
end
function Actions.duplicate()
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
local function setPlatform(p)
  if not Roots[p] then say("Unknown platform: " .. tostring(p), true) return Platform end
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
  local function ctrl()
    local a, b = pcall(function() return UIS:IsKeyDown(Enum.KeyCode.LeftControl) end)
    local c, d = pcall(function() return UIS:IsKeyDown(Enum.KeyCode.RightControl) end)
    return (a and b) or (c and d)
  end
  if input.UserInputType == Enum.UserInputType.MouseButton2 then PC.rmb = true return end
  if input.UserInputType == Enum.UserInputType.MouseButton3 then PC.mmb = true return end
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
  end
end
function PC.onInputEnded(input)
  if input.UserInputType == Enum.UserInputType.MouseButton2 then PC.rmb = false end
  if input.UserInputType == Enum.UserInputType.MouseButton3 then PC.mmb = false end
end
function PC.onInputChanged(input)
  if Platform ~= "PC" then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseWheel then
    Cam.dolly(input.Position.Z > 0 and 1 or -1)
  elseif uit == Enum.UserInputType.MouseMovement then
    local d = input.Delta
    if PC.rmb then Cam.orbit(d.X, d.Y)
    elseif PC.mmb then Cam.pan(d.X, d.Y) end
  end
end
Controllers.PC = PC

-- =============================================================
-- Mobile controller: touch-first, modos, painel numerico
-- =============================================================
local Mobile = { mode = "Select", axis = "X", lastTap = 0 }
local MOBILE_MENUS = { Select = nil, Build = "Models", Terrain = "Terrain", Model = "Models",
  Paint = "Models", Light = "Lighting", FX = "FX", Sound = "Audio", UI = "UI",
  Animate = "Animation", Physics = "Physics", Game = "Gameplay", Cloud = "Tools" }
local Num = { mode = "POS", val = { X = 0, Y = 0, Z = 0 } }
local numShow, numStep, numApply -- forward (setMode usa)
function Mobile.setMode(m)
  Mobile.mode = m
  setText("M_Mode", "MODE: " .. string.upper(m))
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
numApply = function(prefix, panel)
  local id = selId()
  if not id then say("Transform: select an object first.", true) return end
  local v = Num.val
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
  setText("C_Tool", "TOOL: " .. string.upper(t))
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
  setVisible("C_Radial", show)
  if show then
    local items = RADIALS[Console.tool] or RADIALS.Select
    for i = 0, 5 do setText("C_R_" .. i, items[i + 1] or "···") end
    setText("C_R_Title", "RADIAL · " .. string.upper(Console.tool))
    local first = find("C_R_0")
    if first then pcall(function() GuiService.SelectedObject = first end) end
  end
end
function Console.radialPick(i)
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
function Console.focusStep(dir)
  local names = { "C_Menu", "C_Props", "C_R_0", "C_R_1", "C_R_2", "C_R_3", "C_R_4", "C_R_5" }
  local cur = nil
  pcall(function() cur = GuiService.SelectedObject end)
  local idx = 0
  for i, nm in ipairs(names) do
    if cur and cur.Name == nm then idx = i break end
  end
  idx = ((idx + dir) % #names) + 1
  local target = find(names[idx])
  if target then pcall(function() GuiService.SelectedObject = target end) end
end
function Console.enter()
  Console.setTool("Select")
  setText("C_Mode", "MODE: EDITOR")
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
  setText("V_Status", "right hand: ray · left hand: panel")
  setText("V_Sel", "Selection: —")
end
Controllers.VR = VR

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

-- ============ Roteamento global de input ============
local ThumbL, ThumbR = { X = 0, Y = 0 }, { X = 0, Y = 0 }
UIS.InputBegan:Connect(function(input, gpe)
  if gpe then return end
  if Platform == "PC" then PC.onInputBegan(input, gpe) return end
  if Platform == "Console" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonA then Console.confirm()
    elseif kc == Enum.KeyCode.ButtonB then Console.cancel()
    elseif kc == Enum.KeyCode.ButtonX then Actions.snap()
    elseif kc == Enum.KeyCode.ButtonY then Console.radial(not Console.radialOpen)
    elseif kc == Enum.KeyCode.ButtonR1 then Console.cycle(1)
    elseif kc == Enum.KeyCode.ButtonL1 then Console.cycle(-1)
    elseif kc == Enum.KeyCode.ButtonR2 or kc == Enum.KeyCode.ButtonL2 then Console.orbit = true
    elseif kc == Enum.KeyCode.ButtonStart then menu("Tools", find("C_Menu"))
    elseif kc == Enum.KeyCode.ButtonSelect then Actions.propsMenu(find("C_Props"))
    elseif kc == Enum.KeyCode.DPadUp or kc == Enum.KeyCode.DPadRight then Console.focusStep(1)
    elseif kc == Enum.KeyCode.DPadDown or kc == Enum.KeyCode.DPadLeft then Console.focusStep(-1)
    end
    return
  end
  if Platform == "VR" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonR2
      or kc == Enum.KeyCode.ButtonL1 or kc == Enum.KeyCode.ButtonL2 then
      VR.raySelect() VR.grabBegin()
    elseif kc == Enum.KeyCode.ButtonA then say("Confirmed.")
    elseif kc == Enum.KeyCode.ButtonB then Console.cancel() say("Cancelled.")
    elseif kc == Enum.KeyCode.ButtonX then Actions.snap()
    elseif kc == Enum.KeyCode.ButtonY then Precise.on = not Precise.on
      say("Precision " .. (Precise.on and "ON." or "OFF."))
    end
    return
  end
end)
UIS.InputEnded:Connect(function(input)
  if Platform == "PC" then PC.onInputEnded(input) return end
  if Platform == "Console" then
    if input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.ButtonL2 then
      Console.orbit = false
    end
    return
  end
  if Platform == "VR" then
    local kc = input.KeyCode
    if kc == Enum.KeyCode.ButtonR1 or kc == Enum.KeyCode.ButtonR2
      or kc == Enum.KeyCode.ButtonL1 or kc == Enum.KeyCode.ButtonL2 then
      VR.grabEnd()
    end
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
      if z > 0.5 and not VR.grabbing then VR.raySelect() VR.grabBegin()
      elseif z <= 0.15 and VR.grabbing then VR.grabEnd() end
    end
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
      Actions.propsMenu(find("M_T_Props"))
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
    if Platform == "Mobile" then Mobile.refreshSel()
    elseif Platform == "VR" then
      local o = selObj()
      setText("V_Sel", "Selection: " .. (o and o.Name or "—"))
    end
  end
end)

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
})
setPlatform(detectPlatform())
