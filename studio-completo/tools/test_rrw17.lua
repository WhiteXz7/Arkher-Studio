-- Testa R14b RRW: server Rrw* (perfil/FX/ceu/clima/LOD/VFX/stats) + client 17_RRW.
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
for _, n in ipairs({ "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "M_RW" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail", "AN5_Rail", "UI6_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "RW7_T_Place", "RW7_Close", "RW7_P_Realista", "RW7_P_Showcase",
	"RW7_P_Horror", "RW7_P_Mobile", "RW7_P_Estudio", "RW7_F_Bloom", "RW7_F_Blur",
	"RW7_F_Color", "RW7_F_DOF", "RW7_F_Rays", "RW7_F_Grade", "RW7_I_M", "RW7_I_P",
	"RW7_S_TM", "RW7_S_TP", "RW7_S_Cycle", "RW7_S_SM", "RW7_S_SP", "RW7_A_M",
	"RW7_A_P", "RW7_C_M", "RW7_C_P", "RW7_V_Torch", "RW7_V_Smoke", "RW7_V_Magic",
	"RW7_V_Glow", "RW7_L_Add", "RW7_L_Reg", "RW7_L_Del", "M_RW_Prof", "M_RW_FX",
	"M_RW_Sky" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "RW7_P_Info", "RW7_F_Info", "RW7_IV", "RW7_S_TV", "RW7_S_SV",
	"RW7_AV", "RW7_CV", "RW7_L_Info", "RW7_StatL", "M_RW_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "RW7_L_Name")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_17_RRW"; script.Parent = gui

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
local L = game:GetService("Lighting")

print("\n== RW17-S1: RrwProfile ==")
local pR = serverInvoke("RrwProfile", { preset = "Realista" })
check(pR.style == "Realistic" and L.ClockTime == 14, "Realista: style + 14h")
check(L.Brightness == 2 and L.Ambient.R == 70 / 255, "Realista: brightness/ambient reais")
check(pR.via and (pR.via.style or pR.via.tech), "via honesto (style/tech)")
local pH = serverInvoke("RrwProfile", { preset = "Horror" })
check(L.ClockTime == 0 and L.FogEnd == 80, "Horror: 0h + fog 80")
local pM = serverInvoke("RrwProfile", { preset = "Mobile" })
check(pM.style == "Soft" and L.GlobalShadows == false, "Mobile: Soft sem sombras")
check(serverInvoke("RrwProfile", { preset = "X" }).error ~= nil, "preset invalido falha")
serverInvoke("Undo", {})
check(L.ClockTime == 0 and L.Brightness == 1, "Undo restaura perfil anterior")
serverInvoke("Redo", {})
check(L.ClockTime == 14, "Redo reaplica")

print("\n== RW17-S2: RrwFx ==")
local fB = serverInvoke("RrwFx", { op = "add", class = "BloomEffect", props = { Intensity = 2 } })
check(fB.created and L:FindFirstChildOfClass("BloomEffect").Intensity == 2, "add Bloom i=2")
local fS = serverInvoke("RrwFx", { op = "set", class = "BloomEffect", props = { Intensity = 3 } })
check(fS.created == false and L:FindFirstChildOfClass("BloomEffect").Intensity == 3, "set atualiza")
serverInvoke("RrwFx", { op = "set", class = "BloomEffect", props = { Intensity = 99 } })
check(L:FindFirstChildOfClass("BloomEffect").Intensity == 10, "clamp guardrail (10)")
local fL = serverInvoke("RrwFx", { op = "list" })
check(#fL.items == 1 and fL.items[1].class == "BloomEffect", "list mostra Bloom")
serverInvoke("RrwFx", { op = "add", class = "ColorCorrectionEffect",
	props = { Brightness = 0.1 }, })
check(L:FindFirstChildOfClass("ColorCorrectionEffect").Brightness == 0.1, "add ColorCorrection")
serverInvoke("RrwFx", { op = "set", class = "ColorCorrectionEffect",
	props = { TintColor = { 1, 0.5, 0.5 } } })
local tc = L:FindFirstChildOfClass("ColorCorrectionEffect").TintColor
check(tc.R == 1 and tc.G == 0.5, "TintColor aplica")
local fG = serverInvoke("RrwFx", { op = "add", class = "ColorGradingEffect" })
check(fG.created, "Grade adiciona (on/off)")
local fR = serverInvoke("RrwFx", { op = "remove", class = "BloomEffect" })
check(fR.removed and L:FindFirstChildOfClass("BloomEffect") == nil, "remove Bloom")
check(serverInvoke("RrwFx", { op = "remove", class = "BloomEffect" }).error ~= nil,
	"remove inexistente falha")
check(serverInvoke("RrwFx", { op = "add", class = "XEffect" }).error ~= nil, "classe fx invalida falha")

print("\n== RW17-S3: RrwSky ==")
local s0 = serverInvoke("RrwSky", {})
check(s0.mode == "off", "estado inicial off (leitura pura)")
local sS = serverInvoke("RrwSky", { mode = "static", clockTime = 18 })
check(sS.clockTime == 18 and L.ClockTime == 18, "static 18h")
local sC = serverInvoke("RrwSky", { mode = "cycle", speed = 0.1 })
check(sC.mode == "cycle", "cycle liga")
game:GetService("RunService").Heartbeat:Fire(10)
check(math.abs(L.ClockTime - 19) < 1e-6, "ciclo avanca (10s*0.1=+1h)")
local sR = serverInvoke("RrwSky", {})
check(math.abs(sR.clockTime - 19) < 1e-6, "leitura nao altera")
serverInvoke("RrwSky", { mode = "off" })
game:GetService("RunService").Heartbeat:Fire(10)
check(math.abs(L.ClockTime - 19) < 1e-6, "off congela")
check(serverInvoke("RrwSky", { mode = "X" }).error ~= nil, "mode invalido falha")

print("\n== RW17-S4: Atmo/Clouds ==")
local a1 = serverInvoke("RrwAtmo", { density = 0.7 })
check(a1.density == 0.7 and L:FindFirstChildOfClass("Atmosphere") ~= nil, "atmo cria+set")
serverInvoke("RrwAtmo", { density = 99 })
check(L:FindFirstChildOfClass("Atmosphere").Density == 1, "atmo clamp 1")
serverInvoke("RrwAtmo", { color = { 0.9, 0.8, 0.7 } })
check(math.abs(L:FindFirstChildOfClass("Atmosphere").Color.R - 0.9) < 1e-9, "atmo cor")
local c1 = serverInvoke("RrwClouds", { cover = 0.2 })
check(c1.cover == 0.2 and L:FindFirstChildOfClass("Clouds") ~= nil, "clouds cria+set")
serverInvoke("RrwClouds", { cover = -5 })
check(L:FindFirstChildOfClass("Clouds").Cover == 0, "clouds clamp 0")

print("\n== RW17-S5: LOD (troca real por distancia) ==")
local function mkModel(nm, x)
	local m = Instance.new("Model"); m.Name = nm
	local p = Instance.new("Part"); p.Name = "P"
	p.Size = Vector3.new(4, 4, 4); p.Anchored = true
	p.CFrame = CFrame.new(x, 0, 0)
	p.Parent = m
	m.Parent = ws
	return m
end
local modA, modB = mkModel("LodHi", 0), mkModel("LodLo", 0)
local idA = serverInvoke("Identify", { object = modA }).id
local idB = serverInvoke("Identify", { object = modB }).id
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 0, 0)
ws.CurrentCamera = cam
local lod = serverInvoke("RrwLod", { op = "register", name = "G1",
	tiers = { { id = idA, dist = 150 }, { id = idB, dist = 300 } } })
check(lod.registered and modB.Parent.Name == "ArkherLOD", "register: tier2 vai p/ stash")
check(modA.Parent == ws, "tier1 ativo no workspace")
cam.CFrame = CFrame.new(1000, 0, 0)
game:GetService("RunService").Heartbeat:Fire(0.1)
check(modA.Parent.Name == "ArkherLOD" and modB.Parent == ws, "longe: troca p/ tier2 (histerese)")
local ll = serverInvoke("RrwLod", { op = "list" })
check(ll.groups[1].active == 2 and ll.groups[1].dist > 900, "list: active=2 + dist real")
cam.CFrame = CFrame.new(140, 0, 0)
game:GetService("RunService").Heartbeat:Fire(0.1)
check(modB.Parent == ws, "zona morta: sem flicker (140 dentro de 135..165)")
cam.CFrame = CFrame.new(0, 0, 0)
game:GetService("RunService").Heartbeat:Fire(0.1)
check(modA.Parent == ws and modB.Parent.Name == "ArkherLOD", "perto: volta p/ tier1")
local lrm = serverInvoke("RrwLod", { op = "remove", name = "G1" })
check(lrm.removed and modA.Parent == ws and modB.Parent == ws, "remove restaura tiers")
check(serverInvoke("RrwLod", { op = "register", name = "G2",
	tiers = { { id = idA, dist = 300 }, { id = idB, dist = 150 } } }).error ~= nil,
	"dists nao-crescentes falham")
check(serverInvoke("RrwLod", { op = "remove", name = "ZZZ" }).error ~= nil, "remove inexistente falha")

print("\n== RW17-S6: Vfx ==")
local vT = serverInvoke("RrwVfx", { preset = "Tocha" })
check(vT.spawned == 2, "Tocha: Fire+Light")
local vf = nil
for _, d in ipairs(ws:GetDescendants()) do if d.Name == "ArkherFire" then vf = d break end end
check(vf and vf:IsA("Fire"), "Fire real no workspace")
local vM = serverInvoke("RrwVfx", { preset = "Magia" })
check(vM.spawned == 2, "Magia: emitter+light")
check(serverInvoke("RrwVfx", { preset = "X" }).error ~= nil, "preset invalido falha")
local vPart = Instance.new("Part"); vPart.Name = "VPart"; vPart.Parent = ws
local vPartId = serverInvoke("Identify", { object = vPart }).id
serverInvoke("RrwVfx", { preset = "Fumaca", parentId = vPartId })
check(vPart:FindFirstChild("ArkherSmoke") ~= nil, "parent custom respeitado")

print("\n== RW17-S7: Stats ==")
game:GetService("RunService").Heartbeat:Fire(0.016)
local st = serverInvoke("RrwStats", {})
check(type(st.fps) == "number" and st.fps >= 0 and st.fps <= 1000, "fps numerico real")
check(st.parts >= 3, "conta parts")
check(st.effects == 2, "conta efeitos (Color+Grade)")
check(st.lodGroups == 0, "lod groups zerado")
check(st.style == "Soft", "style readback (Mobile vigente)")

-- ============ CLIENT ============
local UIS = game:GetService("UserInputService")
cam.ScreenPointToRay = function(self, x, y)
	return { Origin = Vector3.new(0, 30, 60), Direction = Vector3.new(0, -1, 0) }
end
local hitInst = nil
ws.Raycast = function(self, o, d)
	if not hitInst then return nil end
	return { Instance = hitInst, Position = Vector3.new(0, 0, 0) }
end
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src17 = io.open("studio-completo/scripts/17_RRW.lua"):read("*a")
assert(pcall(assert(loadstring(src17, "[17]"))), "17 nao carregou")
local RRW = _G.ArkherRRW
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== RW17-C1: boot/open/close ==")
check(RRW ~= nil and RRW.isOpen() == false, "17 expoe _G.ArkherRRW fechado")
check(find("RW7_Rail").Visible == false and find("M_RW").Visible == false, "RW7+M_RW ocultos")
find("TE3_Rail").Visible = true; find("AN5_Rail").Visible = true; find("UI6_Rail").Visible = true
RRW.open()
check(RRW.isOpen() and find("RW7_LOD").Visible, "open mostra RW7")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("UI6_Rail").Visible == false, "open exclui editores")
check(find("RW7_StatL").Text:find("fps") ~= nil, "open carrega stats reais")
RRW.close()
check(find("RW7_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
RRW.open()

print("\n== RW17-C2: profile ==")
click("RW7_P_Horror")
check(find("RW7_P_Info").Text:find("Horror") ~= nil and L.ClockTime == 0, "Horror via UI (server)")
check(lastMsg():find("Horror") ~= nil, "Horror loga")
click("RW7_P_Realista")
check(L.ClockTime == 14, "Realista volta")

print("\n== RW17-C3: fx ==")
click("RW7_F_Bloom")
check(find("RW7_F_Info").Text:find("Bloom") ~= nil, "Bloom on (info)")
check(L:FindFirstChildOfClass("BloomEffect") ~= nil, "Bloom real no Lighting")
click("RW7_I_P")
check(find("RW7_IV").Text == "1.5", "inten 1.5")
check(L:FindFirstChildOfClass("BloomEffect").Intensity == 1.5, "inten no server")
click("RW7_F_Bloom")
check(L:FindFirstChildOfClass("BloomEffect") == nil, "Bloom off remove")
click("RW7_F_Grade")
check(RRW.state().selFx == "ColorGradingEffect", "Grade seleciona")
click("RW7_I_P")
check(lastMsg():find("on/off only") ~= nil, "Grade sem prop numerica (honesto)")

print("\n== RW17-C4: sky ==")
click("RW7_S_TP")
check(find("RW7_S_TV").Text == "15:00" and L.ClockTime == 15, "+1h (15:00)")
click("RW7_S_TM")
check(find("RW7_S_TV").Text == "14:00", "-1h volta")
click("RW7_S_Cycle")
check(find("RW7_S_Cycle").Text == "CYCLE ON", "cycle ON")
click("RW7_S_SP")
check(find("RW7_S_SV").Text == "0.15", "speed 0.15")
game:GetService("RunService").Heartbeat:Fire(1.2)
check(find("RW7_StatL").Text:find("fps") ~= nil, "stats auto-refresh (1s)")
click("RW7_S_Cycle")
check(find("RW7_S_Cycle").Text == "CYCLE OFF", "cycle OFF")

print("\n== RW17-C5: atmo + place VFX ==")
click("RW7_A_P")
check(find("RW7_AV").Text == "0.4", "atmo 0.4")
click("RW7_C_M")
check(find("RW7_CV").Text == "0.4", "cloud 0.4")
click("RW7_V_Torch")
check(RRW.state().place == true, "Torch arma Place")
hitInst = vPart
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
local placed = vPart:FindFirstChild("ArkherFire")
check(placed ~= nil, "click poe Fire na part")
hitInst = modA
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
check(lastMsg():find("click a part") ~= nil, "click em Model avisa")

print("\n== RW17-C6: LOD via UI ==")
local sv = Instance.new("ObjectValue"); sv.Name = "SelectedInstance"; sv.Parent = runtime
sv.Value = modA
click("RW7_L_Add")
check(find("RW7_L_Info").Text:find("tiers 1") ~= nil, "tier1 staged")
sv.Value = modB
click("RW7_L_Add")
check(find("RW7_L_Info").Text:find("tiers 2") ~= nil, "tier2 staged (150/300 auto)")
find("RW7_L_Name").Text = "GC"
click("RW7_L_Reg")
check(serverInvoke("RrwLod", { op = "list" }).groups[1].name == "GC", "register via UI (server)")
check(lastMsg():find("live") ~= nil, "register loga")
click("RW7_L_Del")
check(#serverInvoke("RrwLod", { op = "list" }).groups == 0, "remove via UI")
find("RW7_L_Name").Text = ""
click("RW7_L_Reg")
check(lastMsg():find("name the group") ~= nil, "sem nome avisa")

print("\n== RW17-C7: mobile ==")
plat = "Mobile"
RRW.close()
RRW.open()
check(find("M_RW").Visible == true, "Mobile: strip visivel")
click("M_RW_Prof")
check(find("RW7_P_Info").Text == "Showcase", "M_RW_Prof cicla (Realista->Showcase)")
click("M_RW_FX")
check(L:FindFirstChildOfClass("BloomEffect") ~= nil, "M_RW_FX liga Bloom")
click("M_RW_FX")
check(L:FindFirstChildOfClass("BloomEffect") == nil, "M_RW_FX desliga")
click("M_RW_Sky")
check(find("RW7_S_Cycle").Text == "CYCLE ON", "M_RW_Sky liga ciclo")
click("M_RW_Sky")
check(find("RW7_S_Cycle").Text == "CYCLE OFF", "M_RW_Sky desliga")
RRW.close()
check(find("M_RW").Visible == false, "close esconde M_RW")
plat = "PC"

print("\nRRW17: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
