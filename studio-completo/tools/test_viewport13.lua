-- Testa R11: server (Remap/TransformMany/ViewportFrame/Rig) + client 13_Viewport.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
	if cond then pass = pass + 1 print("  OK  " .. msg)
	else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function invoke(action, payload)
	return rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
end

print("\n== VP11 server: remap/rig/frame/transform-many ==")
local rs = invoke("RemapSet", { bindings = { Select = "B", Frame = "G" } })
check(rs and rs.saved and rs.slots == 2 and rs.store == false, "RemapSet salva (memoria; sem DataStore no mock)")
local rg = invoke("RemapGet", {})
check(rg and rg.bindings and rg.bindings.Select == "B" and rg.source == "memory", "RemapGet devolve (memory)")
local rb = invoke("RemapSet", { bindings = { Nope = "B" } })
check(rb and rb.error ~= nil, "RemapSet rejeita slot invalido")
local rc = invoke("RemapSet", { bindings = { Select = "B!" } })
check(rc and rc.error ~= nil, "RemapSet rejeita KeyCode invalido")
local snap = invoke("Snapshot")
local wsId
for _, n in ipairs(snap.nodes) do if n.class == "Workspace" then wsId = n.id end end
local c1 = invoke("Create", { parentId = wsId, class = "Part", name = "VP1" })
local c2 = invoke("Create", { parentId = wsId, class = "Part", name = "VP2" })
local id1, id2 = c1.node.id, c2.node.id
check(id1 ~= nil and id2 ~= nil, "2 pecas criadas")
local fr0 = invoke("ViewportFrame", {})
check(fr0 and fr0.error ~= nil, "Frame sem selecao = erro honesto")
invoke("SelectMany", { ids = { id1, id2 } })
local fr = invoke("ViewportFrame", {})
check(fr and fr.count == 2 and math.abs(fr.center.y - 5) < 0.01 and fr.dist > 6, "Frame: centro/dist de 2 pecas")
local rig0 = invoke("ViewportRig", { op = "get" })
check(rig0 and rig0.rig == nil, "Rig vazio no boot")
local rig1 = invoke("ViewportRig", { op = "set", pos = { x = 1, y = 2, z = 3 }, fov = 90 })
check(rig1 and rig1.saved and rig1.rig.pos.x == 1 and rig1.rig.fov == 90, "Rig salva")
local tm = invoke("TransformMany", { mode = "move", delta = { x = 4, y = 0, z = 0 }, ids = { id1, id2 } })
check(tm and tm.transformed == 2, "TransformMany move x2 pecas (1 undo)")
local ws = game:GetService("Workspace")
local p1 = ws:FindFirstChild("VP1")
check(math.abs(p1.Position.X - 4) < 1e-6, "P1 em x=4")
invoke("Undo", {})
check(math.abs(p1.Position.X - 0) < 1e-6, "Undo volta x=0")
invoke("Redo", {})
check(math.abs(p1.Position.X - 4) < 1e-6, "Redo volta x=4")
invoke("TransformMany", { mode = "rot", delta = { x = 0, y = 90, z = 0 }, ids = { id1 } })
local _, _, _, _, _, r02 = p1.CFrame:GetComponents()
check(math.abs(r02 - 1) < 1e-6, "rot 90 yaw (r02=1)")
invoke("Undo", {})
local _, _, _, _, _, r02b = p1.CFrame:GetComponents()
check(math.abs(r02b) < 1e-6, "Undo desfaz rot")
invoke("TransformMany", { mode = "scale", delta = { x = 2, y = 2, z = 2 }, ids = { id1 } })
check(math.abs(p1.Size.X - 8) < 1e-6, "scale 2x (Size 8)")
invoke("Undo", {})
check(math.abs(p1.Size.X - 4) < 1e-6, "Undo desfaz scale")
local tb = invoke("TransformMany", { mode = "shear", delta = {} })
check(tb and tb.error ~= nil, "TransformMany rejeita mode invalido")

print("\n== VP13 client: camera/frame/multi/measure ==")
local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local shell = Instance.new("Frame"); shell.Name = "ArkherShell2"; shell.Parent = canvas
local function W(parent, cls, name, vis, text)
	local o = Instance.new(cls); o.Name = name
	if cls == "TextLabel" or cls == "TextButton" then o.Text = text or name end
	if cls == "TextButton" then o.BackgroundColor3 = Color3.new(0.1, 0.16, 0.28) end
	if vis ~= nil then o.Visible = vis end
	o.Parent = parent
	return o
end
for _, n in ipairs({ "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "M_VP" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, k in ipairs({ "Select", "Move", "Rotate", "Scale", "Measure" }) do W(shell, "TextButton", "VP3_T_" .. k) end
W(shell, "TextButton", "VP3_Close")
for _, n in ipairs({ "VP3_CamFront", "VP3_CamTop", "VP3_CamSide", "VP3_CamIso", "VP3_CamOrbit",
	"VP3_FovM", "VP3_FovP", "VP3_Frame", "VP3_RigSave", "VP3_RigLoad" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "VP3_FovV", nil, "70"); W(shell, "TextLabel", "VP3_CamV", nil, "cam -")
for _, n in ipairs({ "VP3_TM_Move", "VP3_TM_Rot", "VP3_TM_Scale",
	"VP3_TM_XM", "VP3_TM_XP", "VP3_TM_YM", "VP3_TM_YP", "VP3_TM_ZM", "VP3_TM_ZP",
	"VP3_TM_Apply", "VP3_TM_Reset" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "VP3_TM_XV", nil, "0"); W(shell, "TextLabel", "VP3_TM_YV", nil, "0")
W(shell, "TextLabel", "VP3_TM_ZV", nil, "0"); W(shell, "TextLabel", "VP3_TM_Count", nil, "0 selected")
for _, n in ipairs({ "VP3_M_D1", "VP3_M_D2", "VP3_M_Clear" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "VP3_M_Val", nil, "dist -")
W(shell, "TextButton", "VP3_G_Snap", nil, "SNAP: ON")
W(shell, "TextButton", "VP3_G_StepM"); W(shell, "TextButton", "VP3_G_StepP")
W(shell, "TextLabel", "VP3_G_StepV", nil, "1")
W(shell, "TextLabel", "VP3_StatL", nil, "viewport")
W(shell, "TextButton", "M_VP_Frame"); W(shell, "TextButton", "M_VP_Meas")
W(shell, "TextLabel", "M_VP_Hint")
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_13_Viewport"; script.Parent = gui
local cmds, messages = {}, {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		local r = invoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "Message" then messages[#messages + 1] = payload return true end
	cmds[#cmds + 1] = { action, payload }
	return true
end
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 30, 60); cam.FieldOfView = 70
ws.CurrentCamera = cam
cam.ScreenPointToRay = function(self, x, y)
	return { Origin = Vector3.new(0, 30, 60), Direction = Vector3.new(0, -0.4, -1) }
end
local hitPos, hitInst = Vector3.new(0, 5, 0), nil
ws.Raycast = function(self, o, d) return { Instance = hitInst, Position = hitPos } end
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local teClosed = 0
_G.ArkherTerrain = { isOpen = function() return true end, close = function() teClosed = teClosed + 1 end }
local src13 = io.open("studio-completo/scripts/13_Viewport.lua"):read("*a")
assert(pcall(assert(loadstring(src13, "[13]"))), "13 nao carregou")
local VP = _G.ArkherViewport
hitInst = p1
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

check(VP ~= nil and VP.isOpen() == false, "13 expoe _G.ArkherViewport fechado")
check(find("VP3_Rail").Visible == false, "paineis VP3 ocultos no boot")
VP.open()
check(VP.isOpen() and find("VP3_Rail").Visible and find("T2_Panel").Visible == false, "open mostra VP3 e esconde desktop")
check(teClosed == 1, "open fecha o Terrain (exclusao mutua)")
VP.close()
check(find("VP3_Rail").Visible == false and find("T2_Panel").Visible, "close restaura desktop")
VP.open()
_G.ArkherTerrain.isOpen = function() return false end
click("VP3_T_Move")
check(VP.state().tool == "Move" and cmds[#cmds][1] == "SetMode" and cmds[#cmds][2].key == "Move", "tool Move = SetMode REAL no nucleo")
click("VP3_FovP")
check(cam.FieldOfView == 75 and find("VP3_FovV").Text == "75", "FOV +5 aplica na camera")
click("VP3_FovM")
check(cam.FieldOfView == 70, "FOV -5 volta")
local iso0 = cam.CFrame.Position
click("VP3_CamIso")
check(find("VP3_CamV").Text ~= "cam -" and (cam.CFrame.Position - iso0).Magnitude > 1, "preset ISO move a camera p/ o alvo")
click("VP3_Frame")
check(find("VP3_TM_Count").Text == "2 selected", "FRAME enquadra set (count=2)")
click("VP3_TM_XP")
check(find("VP3_TM_XV").Text == "1.00", "stepper X +step")
click("VP3_TM_Apply")
check(math.abs(p1.Position.X - 5) < 1e-6, "APPLY move 2 pecas (+1)")
click("VP3_TM_Reset")
check(find("VP3_TM_XV").Text == "0.00", "RESET zera delta")
click("VP3_G_Snap")
check(find("VP3_G_Snap").Text == "SNAP: OFF", "snap alterna")
click("VP3_G_StepP")
check(find("VP3_G_StepV").Text == "2", "step 1->2")
click("VP3_M_D1")
hitPos = Vector3.new(0, 5, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
click("VP3_M_D2")
hitPos = Vector3.new(3, 5, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = { X = 500, Y = 300 } }, false)
check(find("VP3_M_Val").Text == "3.00 studs", "medida A-B = 3 studs")
check(ws:FindFirstChild("ArkherMeasure") ~= nil, "linha 3D desenhada")
click("VP3_M_Clear")
check(find("VP3_M_Val").Text == "dist -" and ws:FindFirstChild("ArkherMeasure") == nil, "CLEAR remove medida")
click("VP3_CamOrbit")
local orb0 = cam.CFrame.Position
RunService.Heartbeat:Fire(0.5)
check(find("VP3_CamOrbit").Text == "ORBIT: ON" and (cam.CFrame.Position - orb0).Magnitude > 0.1, "ORBIT gira a camera")
click("VP3_RigSave")
cam.CFrame = CFrame.new(0, 100, 100)
click("VP3_RigLoad")
check((cam.CFrame.Position - orb0).Magnitude > 0.1 and cam.CFrame.Position.Y < 100, "RIG salva/carrega pose")
VP.close()
plat = "Mobile"
VP.open()
check(find("M_VP").Visible, "mobile abre strip M_VP")
click("M_VP_Frame")
check(find("VP3_CamV").Text ~= "cam -", "strip FRAME enquadra")
click("M_VP_Meas")
check(VP.state().arm == "A", "strip MEASURE arma ponto A")

print("VIEWPORT13: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
