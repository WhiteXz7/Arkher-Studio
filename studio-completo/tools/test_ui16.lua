-- Testa R14a UI Editor: server Ui* (scope/CRUD/JSON/publish) + client 16_UI.
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
local function W(parent, cls, name, vis)
	local o = Instance.new(cls); o.Name = name
	if cls == "TextLabel" or cls == "TextButton" then o.Text = name end
	if cls == "TextButton" then o.BackgroundColor3 = Color3.new(0.1, 0.16, 0.28) end
	if vis ~= nil then o.Visible = vis end
	o.Parent = parent
	return o
end
for _, n in ipairs({ "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status", "M_UI" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail", "AN5_Rail" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "UI6_T_Select", "UI6_T_Move", "UI6_Close", "UI6_N_Frame", "UI6_N_Label",
	"UI6_N_Button", "UI6_N_Box", "UI6_N_Image", "UI6_N_Scroll", "UI6_N_Corner", "UI6_N_Stroke",
	"UI6_X_M", "UI6_X_P", "UI6_Y_M", "UI6_Y_P", "UI6_W_M", "UI6_W_P", "UI6_H_M", "UI6_H_P",
	"UI6_T_Apply", "UI6_Dup", "UI6_Del", "UI6_T_Prev", "UI6_T_Next", "UI6_Pub",
	"UI6_IO_Import", "UI6_IO_Export", "M_UI_New", "M_UI_Dup", "M_UI_Del" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "UI6_Info", "UI6_XV", "UI6_YV", "UI6_WV", "UI6_HV",
	"UI6_T_Name", "UI6_T_Hint", "UI6_IO_Stat", "UI6_StatL", "M_UI_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "UI6_Text")
W(shell, "TextBox", "UI6_IO_Text")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_16_UI"; script.Parent = gui

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function serverInvoke(action, payload)
	local r = rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
	if r and r.error and r.error:find("frequ") then
		local t0 = os.clock()
		while os.clock() - t0 < 2.5 do end
		r = rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
	end
	return r
end
local messages, setModes = {}, {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "Message" then messages[#messages + 1] = payload return true end
	if action == "SetMode" then setModes[#setModes + 1] = payload.key return true end
	return true
end
local function lastMsg() return messages[#messages] and messages[#messages].text or "" end

local ws = game:GetService("Workspace")
local Http = game:GetService("HttpService")
local pg = nil

print("\n== UI16-S1: UiRoot/UiNew ==")
local rRoot = serverInvoke("UiRoot", {})
check(rRoot.node and rRoot.node.name == "ArkherUI", "UiRoot cria ArkherUI")
local rRoot2 = serverInvoke("UiRoot", {})
check(rRoot2.node.id == rRoot.node.id, "UiRoot idempotente")
pg = tp:FindFirstChild("PlayerGui")
local rootId = rRoot.node.id
local rFr = serverInvoke("UiNew", { class = "Frame", name = "Painel" })
check(rFr.node and rFr.node.name == "Painel", "UiNew Frame")
local frId = rFr.node.id
local frInst = pg:FindFirstChild("ArkherUI"):FindFirstChild("Painel")
check(frInst and frInst.Size.X.Offset == 200 and frInst.Position.X.Offset == 80,
	"Frame defaults (200x50 @80,80)")
local rLb = serverInvoke("UiNew", { class = "TextLabel", name = "Titulo", parentId = frId })
check(rLb.node.id ~= nil, "UiNew aninhado (Label no Frame)")
local lbId = rLb.node.id
check(serverInvoke("UiNew", { class = "Part" }).error ~= nil, "classe 3D rejeitada")
check(serverInvoke("UiNew", { class = "ScreenGui" }).error ~= nil, "ScreenGui avulsa rejeitada")
local wsPart = Instance.new("Part"); wsPart.Name = "WS"; wsPart.Parent = ws
local wsPartId = serverInvoke("Identify", { object = wsPart }).id
check(serverInvoke("UiNew", { class = "Frame", parentId = wsPartId }).error ~= nil,
	"pai fora do escopo rejeitado")

print("\n== UI16-S2: Move/Size/Text ==")
local mv = serverInvoke("UiMove", { id = frId, dx = 10, dy = -5 })
check(mv.x == 90 and mv.y == 75, "UiMove soma offsets")
local mvC = serverInvoke("UiMove", { id = frId, dx = 99999, dy = 0 })
check(mvC.x == 90 + 5000, "UiMove clampado em +-5000")
serverInvoke("UiMove", { id = frId, dx = -5000, dy = 0 })
local sz = serverInvoke("UiSize", { id = frId, dw = 20, dh = 20 })
check(sz.w == 220 and sz.h == 70, "UiSize cresce")
local szM = serverInvoke("UiSize", { id = frId, dw = -9999, dh = -9999 })
check(szM.w == 1 and szM.h == 1, "UiSize minimo 1px")
serverInvoke("UiSize", { id = frId, dw = 219, dh = 69 })
local tx = serverInvoke("UiText", { id = lbId, text = "Ola" })
check(tx.text == "Ola", "UiText escreve")
check(serverInvoke("UiText", { id = frId, text = "x" }).error ~= nil, "UiText em Frame falha")
local rCo = serverInvoke("UiNew", { class = "UICorner", parentId = frId })
check(serverInvoke("UiMove", { id = rCo.node.id, dx = 1, dy = 1 }).error ~= nil,
	"UiMove em UICorner falha (nao-GuiObject)")

print("\n== UI16-S3: Delete/Dup + undo ==")
local dp = serverInvoke("UiDup", { id = frId })
check(dp.node.name == "PainelCopy", "UiDup copia (nome Copy)")
local trDup = serverInvoke("UiTree", {})
local copyKids = 0
for _, t in ipairs(trDup.items) do if t.depth == 1 then copyKids = copyKids + 1 end end
check(copyKids == 4, "Dup preserva filhos (2+2 depth1)")
local dl = serverInvoke("UiDelete", { id = frId })
check(dl.deleted, "UiDelete remove")
check(#serverInvoke("UiTree", {}).items == 3, "tree apos delete (Copy+2 kids)")
serverInvoke("Undo", {})
check(#serverInvoke("UiTree", {}).items == 6, "Undo restaura subarvore")
serverInvoke("Redo", {})
check(#serverInvoke("UiTree", {}).items == 3, "Redo refaz delete")
serverInvoke("Undo", {})
check(#serverInvoke("UiTree", {}).items == 6, "Undo2 apos Redo")
check(serverInvoke("UiDelete", { id = rootId }).error ~= nil, "raiz ArkherUI protegida")

print("\n== UI16-S4: Tree/Export/Import/Publish ==")
local tr = serverInvoke("UiTree", {})
check(#tr.items == 6 and tr.total == 6, "UiTree lista 6")
local frItem = nil
for _, t in ipairs(tr.items) do if t.name == "Painel" and t.depth == 0 then frItem = t break end end
check(frItem and frItem.x == 90 and frItem.w == 220, "UiTree traz rect (x=90 w=220)")
local ex = serverInvoke("UiExport", { id = frItem.id })
check(ex.nodes == 3, "UiExport conta 3 nos")
local dEx = Http:JSONDecode(ex.json)
check(dEx.v == 1 and dEx.ui.class == "Frame" and #dEx.ui.kids == 2, "export JSON: Frame+2 kids")
local rt = serverInvoke("UiImport", { json = ex.json })
check(rt.nodes == 3 and rt.node.id ~= frItem.id, "round-trip: mesmos nos, novo id")
local tr2 = serverInvoke("UiTree", {})
check(#tr2.items == 9, "import soma 3 nos (9 total)")
check(serverInvoke("UiImport", { json = "{ops" }).error ~= nil, "JSON invalido falha")
check(serverInvoke("UiImport", { json = '{"ui":{"class":"Part"}}' }).error ~= nil,
	"classe 3D no import falha")
local pb = serverInvoke("UiPublish", { id = rootId })
check(pb.node.name == "ArkherUI", "UiPublish clona p/ StarterGui")
check(game:GetService("StarterGui"):FindFirstChild("ArkherUI") ~= nil, "StarterGui tem copia")
check(serverInvoke("UiPublish", { id = frItem.id }).error ~= nil, "publish nao-ScreenGui falha")

print("\n== UI16-S5: escopo/seguranca ==")
check(serverInvoke("UiMove", { id = wsPartId, dx = 1, dy = 1 }).error ~= nil, "UiMove fora do escopo falha")
check(serverInvoke("UiDelete", { id = wsPartId }).error ~= nil, "UiDelete fora do escopo falha")
check(serverInvoke("UiExport", { id = wsPartId }).error ~= nil, "UiExport fora do escopo falha")

-- ============ CLIENT ============
local UIS = game:GetService("UserInputService")
local lp = game:GetService("Players").LocalPlayer
local lpg = lp:FindFirstChild("PlayerGui")
local pickList = {}
lpg.GetGuiObjectsAtPosition = function(self, x, y) return pickList end
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src16 = io.open("studio-completo/scripts/16_UI.lua"):read("*a")
assert(pcall(assert(loadstring(src16, "[16]"))), "16 nao carregou")
local UI = _G.ArkherUI
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== UI16-C1: boot/open/close ==")
check(UI ~= nil and UI.isOpen() == false, "16 expoe _G.ArkherUI fechado")
check(find("UI6_Rail").Visible == false and find("M_UI").Visible == false, "UI6+M_UI ocultos no boot")
find("TE3_Rail").Visible = true; find("VP3_Rail").Visible = true
find("MD4_Rail").Visible = true; find("AN5_Rail").Visible = true
UI.open()
check(UI.isOpen() and find("UI6_Rail").Visible and find("UI6_IO").Visible, "open mostra UI6")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("AN5_Rail").Visible == false, "open exclui editores")
check(UI.state().rootId ~= nil, "open garante UiRoot")
check(lastMsg():find("UI Editor open") ~= nil, "open loga")
UI.close()
check(find("UI6_Rail").Visible == false and find("T2_Panel").Visible, "close restaura desktop")
UI.open()

print("\n== UI16-C2: new + tree ==")
click("UI6_N_Frame")
check(UI.state().selClass == "Frame" and find("UI6_Info").Text:find("Frame") ~= nil, "N_Frame cria+adota")
click("UI6_N_Label")
check(UI.state().selClass == "TextLabel", "N_Label aninhado no Frame")
local nTree = #UI.state().tree
click("UI6_T_Next")
check(find("UI6_T_Name").Text ~= "- -", "T_Next navega")
click("UI6_T_Prev")
check(UI.state().selId ~= nil, "T_Prev volta")

print("\n== UI16-C3: nudge/size/text ==")
for i = 1, 3 do if UI.state().selClass ~= "Frame" then click("UI6_T_Prev") end end
click("UI6_X_P")
check(find("UI6_XV").Text == "85", "X_P +5 (80->85)")
click("UI6_Y_M")
check(find("UI6_YV").Text == "75", "Y_M -5")
click("UI6_W_P")
check(find("UI6_WV").Text == "210", "W_P +10")
click("UI6_H_M")
check(find("UI6_HV").Text == "40", "H_M -10")
click("UI6_T_Next")
find("UI6_Text").Text = "Oi"
click("UI6_T_Apply")
check(lastMsg():find("Text set") ~= nil, "texto aplica no Label")
for i = 1, 3 do if UI.state().selClass ~= "Frame" then click("UI6_T_Next") end end
find("UI6_Text").Text = "x"
click("UI6_T_Apply")
check(lastMsg():find("so em texto") ~= nil, "texto em Frame avisa erro")
check(lastMsg():find("table:") == nil, "erro de servidor mostra TEXTO (regressao api)")

print("\n== UI16-C4: click select + drag ==")
local ark = tp:FindFirstChild("PlayerGui"):FindFirstChild("ArkherUI")
local lbl = nil
for _, d in ipairs(ark:GetDescendants()) do
	if d:IsA("TextLabel") then lbl = d break end
end
check(lbl ~= nil, "label existe p/ pick")
pickList = { lbl }
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 100, Y = 100 } }, false)
check(UI.state().selClass == "TextLabel", "click Select adota label")
click("UI6_T_Move")
local x0 = lbl.Position.X.Offset
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 100, Y = 100 } }, false)
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement,
	Position = { X = 130, Y = 110 } })
check(lbl.Position.X.Offset == x0 + 30, "drag move +30px (server)")
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
check(lastMsg():find("Dropped") ~= nil, "drop loga")
pickList = { { Name = "UI6_T_Select", Parent = { Name = "UI6_Rail",
	Parent = { Name = "ArkherShell2" } } } }
local selAntes = UI.state().selId
click("UI6_T_Select")
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 10, Y = 10 } }, false)
check(UI.state().selId == selAntes, "clique no painel nao seleciona (overUI)")
pickList = {}

print("\n== UI16-C5: dup/del/pub/IO ==")
click("UI6_Dup")
check(find("UI6_Info").Text:find("Copy") ~= nil, "Dup via UI")
click("UI6_Del")
check(UI.state().selId == nil and lastMsg():find("Deleted") ~= nil, "Del via UI")
click("UI6_Pub")
check(lastMsg():find("StarterGui") ~= nil, "Publish via UI")
click("UI6_N_Frame")
click("UI6_IO_Export")
check(find("UI6_IO_Text").Text:find('"class":"Frame"') ~= nil, "Export preenche JSON")
check(find("UI6_IO_Stat").Text:find("ui 1 nodes") ~= nil, "Export stat 1 no")
click("UI6_Del")
click("UI6_IO_Import")
check(UI.state().selClass == "Frame", "Import recria Frame")
find("UI6_IO_Text").Text = ""
click("UI6_IO_Import")
check(lastMsg():find("paste UI") ~= nil, "Import vazio avisa")

print("\n== UI16-C6: mobile ==")
plat = "Mobile"
UI.close()
UI.open()
check(find("M_UI").Visible == true, "Mobile: strip visivel")
click("M_UI_New")
check(UI.state().selClass == "Frame", "M_UI_New cria")
click("M_UI_Dup")
check(find("UI6_Info").Text:find("Copy") ~= nil, "M_UI_Dup duplica")
click("M_UI_Del")
check(UI.state().selId == nil, "M_UI_Del apaga")
UI.close()
check(find("M_UI").Visible == false, "close esconde M_UI")
plat = "PC"

print("\nUI16: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
