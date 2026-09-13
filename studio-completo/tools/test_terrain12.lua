-- Testa o client do Terrain Editor (12_Terrain): wiring assado + strokes + paineis.
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
-- paineis TE3 (ocultos) + desktop (visiveis)
for _, n in ipairs({ "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
	"TE3_Gen", "TE3_Water", "TE3_Status", "M_TE" }) do W(shell, "Frame", n, false) end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for i = 0, 7 do W(shell, "Frame", "TE3_LRow" .. i, false) end
-- toolbar
for _, k in ipairs({ "draw", "sculpt", "raise", "lower", "flatten", "smooth", "erode",
	"crater", "paint", "replace", "water", "drain" }) do W(shell, "TextButton", "TE3_T_" .. k) end
W(shell, "TextButton", "TE3_Close")
-- sliders
for _, p in ipairs({ "TE3_Size", "TE3_Str", "TE3_Fal", "TE3_Har", "TE3_Noi", "TE3_GHei",
	"TE3_GWat", "TE3_WTra", "TE3_WRef", "TE3_WWav", "TE3_WSpd", "TE3_Grass" }) do
	W(shell, "TextButton", p .. "_Track"); W(shell, "TextButton", p .. "_Knob"); W(shell, "TextLabel", p .. "_Val")
end
-- brush misc
for _, n in ipairs({ "TE3_Sym_None", "TE3_Sym_X", "TE3_Sym_Z", "TE3_Sym_XZ",
	"TE3_PlaneSet", "TE3_Src" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "TE3_PlaneVal")
-- materiais
for _, m in ipairs({ "Grass", "LeafyGrass", "Ground", "Mud", "Sand", "Sandstone",
	"Rock", "Slate", "Basalt", "Limestone", "Pavement", "Concrete", "Brick",
	"Cobblestone", "Asphalt", "Salt", "Snow", "Ice", "Glacier", "CrackedLava", "WoodPlanks" }) do
	W(shell, "TextButton", "TE3_M_" .. m)
end
W(shell, "TextLabel", "TE3_MatName")
-- layers
for i = 0, 7 do
	W(shell, "TextButton", "TE3_LName" .. i); W(shell, "TextLabel", "TE3_LOps" .. i)
	W(shell, "TextButton", "TE3_LShow" .. i); W(shell, "TextButton", "TE3_LClear" .. i)
	W(shell, "TextButton", "TE3_LDel" .. i)
end
W(shell, "TextBox", "TE3_LName")
for _, n in ipairs({ "TE3_LSizeS", "TE3_LSizeM", "TE3_LSizeL", "TE3_LAdd" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "TE3_LHint")
-- history
W(shell, "TextButton", "TE3_Undo"); W(shell, "TextButton", "TE3_Redo"); W(shell, "TextLabel", "TE3_Depth")
for i = 0, 5 do W(shell, "TextLabel", "TE3_H" .. i) end
-- gen
for _, n in ipairs({ "TE3_GSeedM", "TE3_GSeedP", "TE3_GSizeS", "TE3_GSizeM", "TE3_GSizeL",
	"TE3_GBio", "TE3_GEroM", "TE3_GEroP", "TE3_Gen", "TE3_Keep", "TE3_Discard" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "TE3_GSeedV"); W(shell, "TextLabel", "TE3_GEroV"); W(shell, "TextLabel", "TE3_GStat")
-- water
for _, n in ipairs({ "TE3_WC1", "TE3_WC2", "TE3_WC3", "TE3_Decor", "TE3_Rain",
	"TE3_FloodM", "TE3_FloodP", "TE3_Flood", "TE3_Hydro" }) do W(shell, "TextButton", n) end
W(shell, "TextLabel", "TE3_FloodV"); W(shell, "TextLabel", "TE3_HydroV")
-- status + mobile
W(shell, "TextLabel", "TE3_StatL")
for _, n in ipairs({ "M_TE_Prev", "M_TE_Next", "M_TE_SizeM", "M_TE_SizeP", "M_TE_Mat" }) do
	W(shell, "TextButton", n)
end
W(shell, "TextLabel", "M_TE_Tool"); W(shell, "TextLabel", "M_TE_SizeV"); W(shell, "TextLabel", "M_TE_Hint")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_12_Terrain"; script.Parent = gui

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function serverInvoke(action, payload)
	return rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
end
local messages = {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "Message" then messages[#messages + 1] = payload return true end
	return true
end

local ws = game:GetService("Workspace")
local ter = Instance.new("Terrain"); ter.Name = "Terrain"; ter.Parent = ws
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 30, 60)
ws.CurrentCamera = cam
cam.ScreenPointToRay = function(self, x, y)
	return { Origin = Vector3.new(0, 30, 60), Direction = Vector3.new(0, -1, 0) }
end
local hitPos = Vector3.new(0, 20, 0)
ws.Raycast = function(self, o, d) return { Instance = ter, Position = hitPos } end

local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src12 = io.open("studio-completo/scripts/12_Terrain.lua"):read("*a")
assert(pcall(assert(loadstring(src12, "[12]"))), "12 nao carregou")
local TE = _G.ArkherTerrain
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== TE12: boot + open/close ==")
check(TE ~= nil and TE.isOpen() == false, "12 expoe _G.ArkherTerrain fechado")
check(find("TE3_Rail").Visible == false, "paineis TE3 ocultos no boot")
TE.open()
check(TE.isOpen() and find("TE3_Rail").Visible and find("T2_Panel").Visible == false, "open mostra TE3 e esconde desktop")
TE.close()
check(find("TE3_Rail").Visible == false and find("T2_Panel").Visible, "close restaura desktop")
TE.open()

print("\n== TE12: toolbar + sliders + materiais ==")
click("TE3_T_raise")
check(TE.state().tool == "raise" and find("M_TE_Tool").Text == "RAISE", "raise selecionado (estado+mobile)")
check(TE.xToValue(0, 100, 25, 1, 64, true) == 17, "xToValue mapeia 25% -> 17")
check(TE.xToValue(0, 100, -50, 1, 64, true) == 1 and TE.xToValue(0, 100, 500, 1, 64, true) == 64, "xToValue clamp nas bordas")
click("TE3_Size_Track")
check(TE.state().size == 11 and find("TE3_Size_Val").Text == "11", "slider size anda (fallback click = mesmo set)")
local gc = ter:GetMaterialColor(Enum.Material.Grass)
local gb = find("TE3_M_Grass").BackgroundColor3
check(gb.R == gc.R and gb.G == gc.G and gb.B == gc.B, "swatch Grass = cor REAL do Terrain")
click("TE3_M_Rock")
check(TE.state().material == "Rock" and find("TE3_MatName").Text == "Rock", "swatch Rock seleciona")
click("TE3_Sym_X")
check(TE.state().symmetry == "x", "simetria X")

print("\n== TE12: stroke mouse -> server ==")
check(ter:CountCells() == 0, "terreno comeca vazio")
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
local cB = ter:CountCells()
check(cB > 0, "M1 begin pinta (" .. cB .. " celulas)")
check(find("TE3_PlaneVal").Text == "Y: 20", "plano capturado do hit (Y: 20)")
hitPos = Vector3.new(40, 20, 0)
UIS.InputChanged:Fire({ UserInputType = Enum.UserInputType.MouseMovement, Position = { X = 500, Y = 300 } })
local cM = ter:CountCells()
check(cM > cB, "drag continua o stroke (" .. cM .. ")")
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
check(find("TE3_Depth").Text == "1/0", "stroke fechado = 1 entrada de undo")
check(find("TE3_H0").Text:find("raise") ~= nil, "historico local registra stroke")
local giz = ws:FindFirstChild("ArkherBrushOuter")
check(giz ~= nil and giz.CanQuery == false, "gizmo existe e nao bloqueia raycast")
RunService.Heartbeat:Fire(2.5)
check(find("TE3_StatL").Text:find("RAISE") ~= nil, "status mostra ferramenta")

print("\n== TE12: guards honestos ==")
local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
pg.GetGuiObjectsAtPosition = function(self, x, y)
	return { { Name = "TE3_T_draw", Parent = { Name = "TE3_Rail", Parent = { Name = "ArkherShell2" } } } }
end
local cG = ter:CountCells()
hitPos = Vector3.new(200, 20, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = { X = 10, Y = 10 } }, false)
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
check(ter:CountCells() == cG, "clique no painel NAO pinta (overUI)")
pg.GetGuiObjectsAtPosition = nil
UIS.GetFocusedTextBox = function(self) return {} end
hitPos = Vector3.new(220, 20, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.MouseButton1 })
check(ter:CountCells() == cG, "digitando NAO pinta")
UIS.GetFocusedTextBox = function(self) return nil end

print("\n== TE12: undo/redo/layers via UI ==")
click("TE3_Undo")
check(ter:CountCells() == 0, "botao UNDO desfaz stroke")
click("TE3_Redo")
check(ter:CountCells() > 0, "botao REDO refaz")
find("TE3_LName").Text = "L1"
click("TE3_LAdd")
check(find("TE3_LRow0").Visible and find("TE3_LName0").Text == "L1", "ADD cria camada L1")
click("TE3_LShow0")
check(find("TE3_LShow0").Text == "Show", "Hide vira Show")
click("TE3_LClear0")
check(find("TE3_LOps0").Text == "0", "Clear zera ops")
click("TE3_LDel0")
check(find("TE3_LRow0").Visible == false, "Del remove camada")

print("\n== TE12: gen + agua + mobile ==")
local cPre = ter:CountCells()
click("TE3_Gen")
local cGen = ter:CountCells()
check(cGen > cPre + 1000 and find("TE3_GStat").Text:find("seed=7") ~= nil, "GENERATE aplica preview (" .. cGen .. ")")
click("TE3_Discard")
check(ter:CountCells() == cPre, "UNDO descarta preview")
click("TE3_WC2")
local wc = ter.WaterColor
check(math.floor(wc.R * 255 + 0.5) == 20 and math.floor(wc.B * 255 + 0.5) == 140, "preset BLUE chega no Terrain")
click("TE3_Rain")
check(find("TE3_Rain").Text == "RAIN: ON" and ws:FindFirstChild("ArkherRainRig") ~= nil, "RAIN liga emissor")
click("TE3_Rain")
check(find("TE3_Rain").Text == "RAIN: OFF", "RAIN desliga")
click("TE3_Flood")
click("TE3_Hydro")
check(find("TE3_HydroV").Text:find("Agua:") ~= nil, "SCAN mostra diagnostico (" .. find("TE3_HydroV").Text:sub(1, 40) .. ")")
click("TE3_WTra_Track")
check(math.abs(ter.WaterTransparency - TE.state().wTra) < 1e-9, "slider agua aplica no release (full-stack)")
TE.close()
plat = "Mobile"
TE.open()
check(find("M_TE").Visible, "mobile abre strip M_TE")
click("M_TE_Next")
check(TE.state().tool == "lower", "strip cicla ferramenta (raise->lower)")
local sz0 = TE.state().size
click("M_TE_SizeP")
check(TE.state().size == sz0 + 2, "strip size +2")
click("M_TE_Mat")
check(TE.state().material == "Slate", "strip cicla material (Rock->Slate)")
TE.setTool("draw")
local cTouch0 = ter:CountCells()
hitPos = Vector3.new(300, 20, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.Touch, KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
UIS.InputEnded:Fire({ UserInputType = Enum.UserInputType.Touch })
check(ter:CountCells() > cTouch0, "toque pinta no mobile")

print("TERRAIN12: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
