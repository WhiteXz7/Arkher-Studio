-- Teste do ARKHER Input System (11_Input): deteccao, layouts, 4 controllers + server.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
	if cond then pass = pass + 1 print("  OK  " .. msg)
	else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local shell = Instance.new("Frame"); shell.Name = "ArkherShell2"; shell.Parent = canvas
local desktop = Instance.new("Frame"); desktop.Name = "DesktopRoot"; desktop.Visible = true; desktop.Parent = shell
local mroot = Instance.new("Frame"); mroot.Name = "MobileRoot"; mroot.Visible = false; mroot.Parent = shell
local croot = Instance.new("Frame"); croot.Name = "ConsoleRoot"; croot.Visible = false; croot.Parent = shell
local vroot = Instance.new("Frame"); vroot.Name = "VRoot"; vroot.Visible = false; vroot.Parent = shell
local function W(parent, cls, name)
	local o = Instance.new(cls); o.Name = name
	if cls == "TextLabel" or cls == "TextButton" then o.Text = name end
	o.Parent = parent
	return o
end
-- desktop extras
for _, n in ipairs({ "R2_Anchor", "R2_Snap", "R2_Group", "F2_LogLine" }) do W(desktop, "TextButton", n) end
-- mobile
for _, n in ipairs({ "M_MenuBtn", "M_Undo", "M_Redo", "M_Save", "M_Play", "M_Stop",
	"M_T_Select", "M_T_Move", "M_T_Rotate", "M_T_Scale", "M_T_Camera", "M_T_Insert", "M_T_Snap", "M_T_Props",
	"M_DrawerClose", "M_PropsClose", "M_PropsOpen",
	"M_B_Confirm", "M_B_Cancel", "M_B_Undo", "M_B_Prec", "M_B_Snap", "M_B_Axis", "M_B_Space",
	"M_N_XMinus", "M_N_XPlus", "M_N_YMinus", "M_N_YPlus", "M_N_ZMinus", "M_N_ZPlus",
	"M_N_Rot", "M_N_Size", "M_N_Axis", "M_N_Apply", "M_N_Cancel", "M_N_Reset", "M_N_Close" }) do
	W(mroot, "TextButton", n)
end
for _, n in ipairs({ "Select", "Build", "Terrain", "Model", "Paint", "Light", "FX", "Sound", "UI",
	"Animate", "Physics", "Game", "Cloud" }) do W(mroot, "TextButton", "M_Cat_" .. n) end
for _, n in ipairs({ "M_Mode", "M_Sel", "M_N_XVal", "M_N_YVal", "M_N_ZVal", "M_N_Mode" }) do
	local l = W(mroot, "TextLabel", n); l.Text = "0"
end
for _, n in ipairs({ "M_Drawer", "M_PropsP", "M_Numeric" }) do
	local f = W(mroot, "Frame", n); f.Visible = false
end
-- console
for _, n in ipairs({ "C_Menu", "C_Props", "C_R_0", "C_R_1", "C_R_2", "C_R_3", "C_R_4", "C_R_5",
	"C_N_XMinus", "C_N_XPlus", "C_N_YMinus", "C_N_YPlus", "C_N_ZMinus", "C_N_ZPlus",
	"C_N_Mode", "C_N_Apply", "C_N_Cancel", "C_PropsOpen" }) do W(croot, "TextButton", n) end
for _, n in ipairs({ "C_Tool", "C_Mode", "C_R_Title", "C_N_XVal", "C_N_YVal", "C_N_ZVal" }) do
	local l = W(croot, "TextLabel", n); l.Text = "0"
end
for _, n in ipairs({ "C_Radial", "C_Panel", "C_Numeric" }) do
	local f = W(croot, "Frame", n); f.Visible = false
end
W(croot, "TextLabel", "C_Cursor")
-- vr
for _, n in ipairs({ "V_T_Select", "V_T_Move", "V_T_Rotate", "V_T_Scale", "V_T_Camera", "V_T_Insert",
	"V_Confirm", "V_Cancel", "V_Prec", "V_Snap", "V_Teleport" }) do W(vroot, "TextButton", n) end
W(vroot, "TextLabel", "V_Status"); W(vroot, "TextLabel", "V_Sel")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
local selInst = Instance.new("ObjectValue"); selInst.Name = "SelectedInstance"; selInst.Parent = runtime
local selIdVal = Instance.new("StringValue"); selIdVal.Name = "SelectedId"; selIdVal.Value = ""; selIdVal.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_11_Input"; script.Parent = gui

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function serverInvoke(action, payload) return rawget(request, "__props").OnServerInvoke(tp, action, payload or {}) end
local wsId = nil
do
	local st = serverInvoke("Snapshot", {})
	if st and st.nodes then
		for _, n in ipairs(st.nodes) do if n.class == "Workspace" then wsId = n.id end end
	end
end
assert(wsId ~= nil, "fixture sem Workspace")

local spy, menuSpy, messages = {}, {}, {}
local cstate = { selectedId = nil, space = "Local" }
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		spy[#spy + 1] = { cmd = payload.action, p = payload.payload }
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "State" then
		if selIdVal.Value ~= "" then cstate.selectedId = selIdVal.Value end
		return cstate
	end
	if action == "SetMode" or action == "SetSpace" then spy[#spy + 1] = { cmd = action, p = payload } return true end
	if action == "Message" then messages[#messages + 1] = { text = payload.text, bad = payload.bad } return true end
	return true
end
menusBus.OnInvoke = function(action, payload)
	menuSpy[#menuSpy + 1] = { cmd = action, p = payload or {} }
	return true
end

local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local ws = game:GetService("Workspace")
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 30, 60); cam.FieldOfView = 70
cam.Focus = CFrame.new(0, 0, 0)
ws.CurrentCamera = cam

local src11 = io.open("studio-completo/scripts/11_Input.lua"):read("*a")
assert(pcall(assert(loadstring(src11, "[11]"))), "11 nao carregou")
local IN = _G.ArkherInput
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end
local function lastSpy() return spy[#spy] end
local function mkSel(nm, x)
	local c = serverInvoke("Create", { parentId = wsId, class = "Part", name = nm })
	local id = c.node.id
	if x then serverInvoke("SetAny", { id = id, name = "Position", kind = "v", value = { x = x, y = 0, z = 0 } }) end
	serverInvoke("Select", { id = id })
	local inst = ws:FindFirstChild(nm, true)
	selInst.Value = inst; selIdVal.Value = id; cstate.selectedId = id
	return id, inst
end

print("\n== Input: boot PC ==")
check(IN ~= nil, "11 expoe _G.ArkherInput")
check(IN.platform() == "PC", "detect default = PC")
check(desktop.Visible and not mroot.Visible and not croot.Visible and not vroot.Visible, "so Desktop visivel")

print("\n== Input: PC teclado/mouse ==")
local n0 = #spy
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.One, UserInputType = Enum.UserInputType.Keyboard }, false)
check(lastSpy().cmd == "SetMode" and lastSpy().p.key == "Select", "tecla 1 = Select")
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.Three, UserInputType = Enum.UserInputType.Keyboard }, false)
check(lastSpy().cmd == "SetMode" and lastSpy().p.key == "Rotate", "tecla 3 = Rotate")
local idP, instP = mkSel("PCeca", 5)
local cx0 = cam.CFrame.Position.X
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.F, UserInputType = Enum.UserInputType.Keyboard }, false)
check(cam.CFrame.Position.X == 15, "F enquadra (5+10=15)")
UIS.IsKeyDown = function(self, k) return k == Enum.KeyCode.LeftControl end
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.D, UserInputType = Enum.UserInputType.Keyboard }, false)
check(lastSpy().cmd == "Duplicate", "Ctrl+D roteia Duplicate")
local dup = ws:FindFirstChild("PCeca1", true) or ws:FindFirstChild("PCeca0", true)
check(lastSpy().p.id == idP, "Duplicate mira a peca selecionada")
UIS.IsKeyDown = function(self, k) return false end
local cz0 = cam.CFrame.Position.Z
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseWheel, Position = { X = 0, Y = 0, Z = 1 } })
check(cam.CFrame.Position.Z ~= cz0, "wheel dolly move camera")
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton2, KeyCode = Enum.KeyCode.Unknown }, false)
local co0 = cam.CFrame.Position.X
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Delta = { X = 40, Y = 0 } })
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton2 })
check(true, "RMB+move orbita sem erro")
UIS.GetFocusedTextBox = function(self) return {} end
local nT = #spy
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.One, UserInputType = Enum.UserInputType.Keyboard }, false)
check(#spy == nT, "digitando: teclas ignoradas")
UIS.GetFocusedTextBox = function(self) return nil end

print("\n== Input: Mobile ==")
UIS.TouchEnabled = true; UIS.KeyboardEnabled = false; UIS.GamepadEnabled = false
check(IN.redetect() == "Mobile", "touch sem teclado = Mobile")
check(mroot.Visible and not desktop.Visible, "MobileRoot visivel, Desktop oculta")
click("M_T_Move")
check(lastSpy().cmd == "SetMode" and lastSpy().p.key == "Move", "M_T_Move = modo Move")
check(find("M_Mode").Text == "MODE: MOVE", "indicador MODE: MOVE")
check(find("M_Numeric").Visible, "modo Move abre painel numerico")
click("M_N_XPlus"); click("M_N_XPlus")
check(find("M_N_XVal").Text == "7.00", "stepper X: 5 -> 7.00")
click("M_B_Axis")
check(find("M_B_Axis").Text == "AXIS: Y", "M_B_Axis cicla p/ Y")
click("M_B_Space")
check(lastSpy().cmd == "SetSpace", "M_B_Space roteia SetSpace")
click("M_Cat_Terrain")
check(menuSpy[#menuSpy].cmd == "Menu" and menuSpy[#menuSpy].p.name == "Terrain", "M_Cat_Terrain abre menu Terrain")
click("M_T_Insert")
check(find("M_Drawer").Visible, "M_T_Insert abre drawer")
click("M_DrawerClose")
local cf0 = cam.CFrame.Position.X
UIS.TouchTapInWorld:Fire({ X = 1, Y = 2 }, false)
UIS.TouchTapInWorld:Fire({ X = 1, Y = 2 }, false)
check(cam.CFrame.Position.X ~= cf0, "tap duplo enquadra")
click("M_B_Confirm")
local pv = serverInvoke("Select", { id = idP })
local px = nil
for _, f in ipairs(pv.properties.fields) do if f.key == "Position" then px = f.value.X end end
check(px == 7, "M_B_Confirm aplica X=7 no server (full-stack)")

print("\n== Input: Console ==")
UIS.TouchEnabled = false; UIS.KeyboardEnabled = false; UIS.GamepadEnabled = true
check(IN.redetect() == "Console", "so gamepad = Console")
check(croot.Visible and not mroot.Visible, "ConsoleRoot visivel")
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonR1 }, false)
check(find("C_Tool").Text == "TOOL: MOVE", "R1 cicla ferramenta")
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonL1 }, false)
check(find("C_Tool").Text == "TOOL: SELECT", "L1 volta p/ Select")
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonY }, false)
check(find("C_Radial").Visible and find("C_R_0").Text == "Frame", "Y abre radial (Frame/Props/...)")
local idC = mkSel("ConPeca", 9)
click("C_R_2")
check(lastSpy().cmd == "Duplicate", "radial Duplicate roteia")
GuiService.SelectedObject = nil
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.DPadUp }, false)
check(GuiService.SelectedObject and GuiService.SelectedObject.Name == "C_Props", "DPad navega foco")
cam.ScreenPointToRay = function(self, x, y) return { Origin = Vector3.new(0, 0, 0), Direction = Vector3.new(0, 0, -1) } end
local idT = mkSel("AlvoCursor", 3)
local instT = ws:FindFirstChild("AlvoCursor", true)
ws.Raycast = function(self, o, d) return { Instance = instT, Position = Vector3.new(0, 0, 0) } end
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonB }, false)
selIdVal.Value = ""; cstate.selectedId = nil
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonA }, false)
check(selIdVal.Value == idT, "A no cursor vazio = raycast seleciona (full-stack)")
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.Thumbstick1, Position = { X = 0, Y = -1 } })
local st0 = cam.CFrame.Position.Z
RunService.Heartbeat:Fire(0.016)
check(cam.CFrame.Position.Z ~= st0, "stick esquerdo move camera")

print("\n== Input: VR ==")
VRService.VREnabled = true
check(IN.redetect() == "VR", "VREnabled = VR")
check(vroot.Visible and not croot.Visible, "VRoot visivel")
VRService.GetUserCFrame = function(self, uf) return CFrame.new(0, 1, 0) end
local idV = mkSel("AlvoVR", 4)
local instV = ws:FindFirstChild("AlvoVR", true)
ws.Raycast = function(self, o, d) return { Instance = instV, Position = Vector3.new(0, 0, 0) } end
selIdVal.Value = ""; cstate.selectedId = nil
UIS.InputBegan:Fire({ KeyCode = Enum.KeyCode.ButtonR1 }, false)
check(selIdVal.Value == idV, "gatilho VR = raycast seleciona (full-stack)")
local pv0 = nil
do local s = serverInvoke("Select", { id = idV })
	for _, f in ipairs(s.properties.fields) do if f.key == "Position" then pv0 = f.value.X end end end
do local t0 = os.clock() while os.clock() - t0 < 0.15 do end end
RunService.Heartbeat:Fire(0.05)
local pv1 = nil
do local s = serverInvoke("Select", { id = idV })
	for _, f in ipairs(s.properties.fields) do if f.key == "Position" then pv1 = f.value.X end end end
check(lastSpy().cmd == "SetAny" and lastSpy().p.name == "Position", "grab VR arrasta p/ server (throttled)")
UIS.InputEnded:Fire({ KeyCode = Enum.KeyCode.ButtonR1 })
click("V_Snap")
check(lastSpy().cmd == "SetAny", "V_Snap roteia snap")

print("\n== Input: override + desktop extras ==")
check(IN.setPlatform("PC") == "PC" and desktop.Visible, "override manual p/ PC")
VRService.VREnabled = false; UIS.GamepadEnabled = false
check(IN.redetect() == "PC", "redetect volta p/ PC")
local idA = mkSel("Ancora", 1)
click("R2_Anchor")
local pa = serverInvoke("Select", { id = idA })
local av = nil
for _, f in ipairs(pa.properties.fields) do if f.key == "Anchored" then av = f.value end end
check(av == true, "R2_Anchor liga Anchored (full-stack)")
click("R2_Group")
check(lastSpy().cmd == "Group", "R2_Group roteia Group")

print(string.format("RESULTADO: %d passaram, %d falharam", pass, fail))
if fail > 0 then os.exit(1) else os.exit(0) end
