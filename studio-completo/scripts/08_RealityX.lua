-- =============================================================
-- Arkher_08_RealityX — TOPBAR DE ABAS do RRW (LocalScript)
-- Diretriz do estudio: NADA na barra lateral direita. Toda a
-- navegacao dos motores novos (THX/WORLDX/REALITYX + MeshX/RigX)
-- mora AQUI, numa faixa de ABAS logo abaixo da topbar original.
-- So ADICIONA UI (parts 01..07 intocadas). Icones texto/quadrado,
-- 100% tema original. Tudo chama o mundo REAL via ArkherNet.
-- =============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = {
	panel = Color3.fromRGB(7, 16, 32),
	sect = Color3.fromRGB(9, 23, 44),
	border = Color3.fromRGB(52, 80, 120),
	text = Color3.fromRGB(228, 240, 255),
	muted = Color3.fromRGB(146, 170, 202),
	blue = Color3.fromRGB(35, 139, 230),
	sel = Color3.fromRGB(17, 76, 139),
	cyan = Color3.fromRGB(43, 203, 243),
	purple = Color3.fromRGB(166, 117, 240),
	gold = Color3.fromRGB(240, 185, 70),
	green = Color3.fromRGB(120, 220, 160),
	err = Color3.fromRGB(255, 164, 143),
	font = Enum.Font.GothamBold,
	fontm = Enum.Font.Gotham,
}

local function B(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function H(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = o
	return o
end

local function stroke(o, th, col)
	local s0 = Instance.new("UIStroke")
	s0.Thickness = th or 1
	s0.Color = col or t.border
	s0.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s0.Parent = o
	return o
end

-- ============ ponte com o mundo real ============
local netFn
pcall(function()
	local net = ReplicatedStorage:WaitForChild("ArkherNet", 20)
	if net then netFn = net:WaitForChild("ArkherXQ", 5) end
end)

local function remote(op, params)
	if not netFn then error("sem ponte ArkherNet") end
	return netFn:InvokeServer({ op = op, params = params })
end

local function remoteMsg(op, params)
	local res = remote(op, params)
	if type(res) == "table" then
		if res.msg then return res.msg end
		return res
	end
	return tostring(res)
end

-- ============ UI raiz ============
local gui = B("ScreenGui", {
	Name = "ArkherRealityXUI", ResetOnSpawn = false,
	DisplayOrder = 70, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- faixa de abas: logo ABAIXO da topbar original (regra: so adicionar)
local strip = B("Frame", {
	Name = "RRW_TabStrip",
	Size = UDim2.new(1, -272, 0, 30),
	Position = UDim2.fromOffset(260, 112),
	BackgroundColor3 = t.panel,
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
}, gui)
H(strip, 8)
stroke(strip, 1)

B("TextLabel", {
	Size = UDim2.fromOffset(66, 30), BackgroundTransparency = 1,
	Text = " RRW", Font = t.font, TextSize = 13, TextColor3 = t.gold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, strip)

local status = B("TextLabel", {
	Name = "Status",
	Size = UDim2.new(1, -820, 1, 0),
	Position = UDim2.new(0, 820, 0, 0),
	BackgroundTransparency = 1,
	Text = "RRW automático: pronto. Passe o mouse numa tool p/ ver o que ela faz.",
	Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
	TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, strip)

local tabHolder = B("Frame", {
	Size = UDim2.fromOffset(740, 30), Position = UDim2.fromOffset(66, 0),
	BackgroundTransparency = 1,
}, strip)
local tabLay = Instance.new("UIListLayout")
tabLay.FillDirection = Enum.FillDirection.Horizontal
tabLay.Padding = UDim.new(0, 4)
tabLay.VerticalAlignment = Enum.VerticalAlignment.Center
tabLay.Parent = tabHolder

-- painel da aba ativa (grade de tools)
local board = B("Frame", {
	Name = "RRW_Board",
	Size = UDim2.new(1, -272, 0, 116),
	Position = UDim2.fromOffset(260, 146),
	BackgroundColor3 = t.panel,
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	Visible = false,
}, gui)
H(board, 10)
stroke(board, 1)

local grid = B("ScrollingFrame", {
	Size = UDim2.new(1, -16, 1, -12),
	Position = UDim2.fromOffset(8, 6),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = t.border,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
}, board)
local glay = Instance.new("UIGridLayout")
glay.CellSize = UDim2.fromOffset(138, 48)
glay.CellPadding = UDim2.fromOffset(6, 6)
glay.FillDirection = Enum.FillDirection.Horizontal
glay.SortOrder = Enum.SortOrder.LayoutOrder
glay.Parent = grid

-- ============ fabrica de botoes de tool ============
local orderN = 0
local busy = false

local function say(txt, col)
	status.Text = txt
	status.TextColor3 = col or t.muted
end

local function toolBtn(label, desc, fn)
	orderN = orderN + 1
	local b0 = B("TextButton", {
		Size = UDim2.fromOffset(138, 48),
		BackgroundColor3 = t.sect,
		Text = label, Font = t.font, TextSize = 10,
		TextColor3 = t.text, TextWrapped = true,
		BorderSizePixel = 0, AutoButtonColor = true,
		LayoutOrder = orderN,
	}, grid)
	H(b0, 8)
	stroke(b0, 1)
	b0.MouseEnter:Connect(function()
		if not busy then say(desc, t.cyan) end
	end)
	b0.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		say("→ " .. label .. "…", t.cyan)
		task.spawn(function()
			local ok, res = pcall(fn)
			if ok then
				say("✓ " .. tostring(res), t.green)
			else
				say("✗ " .. tostring(res), t.err)
			end
			task.delay(0.25, function() busy = false end)
		end)
	end)
	return b0
end

local function section(title, col)
	orderN = orderN + 1
	B("TextLabel", {
		Size = UDim2.fromOffset(138, 48),
		BackgroundTransparency = 1,
		Text = "▮ " .. title, Font = t.font, TextSize = 11,
		TextColor3 = col or t.gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = orderN,
	}, grid)
end

-- ============ conteudo das abas ============
local BUILD = {}

-- ---- RRW · PLANETA (o daemon automatico) ----
function BUILD.planeta()
	section("REALITY ENGINE (RRW)", t.gold)
	toolBtn("🌍 Gerar Planeta", "RRW: tectônica de placas + clima Köppen + 32 biomas Whittaker + matéria 16K — planeta gerado do zero", function()
		return remoteMsg("world_generate", { seed = 7, size = 1200, plates = 9, season = 0.35 })
	end)
	toolBtn("Materializar Mundo", "Converte o planeta em células físicas com cor/micro-relevo 16K por MATÉRIA (não textura) + orla de parallax TRUE", function()
		return remoteMsg("world_materialize", {})
	end)
	toolBtn("Vegetação por Bioma", "Whittaker: cada bioma recebe a vegetação CERTA (slots do usuário ou protótipo tronco+copa ARKHER)", function()
		return remoteMsg("world_vegetate", {})
	end)
	toolBtn("Erosão · Aprender", "Erosão hidráulica; o mapa 3D APRENDE a cada run (memória THX) — fica melhor sozinho", function()
		return remoteMsg("world_erode", { cycles = 150 })
	end)
	toolBtn("Erosão Pesada ×600", "600 ciclos: vales/terraços maduros + aprendizado profundo", function()
		return remoteMsg("world_erode", { cycles = 600 })
	end)
	toolBtn("▶ RRW AUTOMÁTICO", "Liga o daemon RRW: mundo inteiro se materializa/ajusta sozinho por distância, importância e tier — NADA manual", function()
		return remoteMsg("rrx_start", { running = true })
	end)
	toolBtn("Stats RRW", "Entidades, células materializadas, vegetação, relógio do mundo, runs de erosão aprendidas", function()
		return remoteMsg("rrx_stats", {})
	end)
	section("TIER D-O15 (D* = argmax Q−C)", t.purple)
	toolBtn("D12 · DOZE", "Tier máximo: materialização total (octavas 16K, parallax 7 cascas, erosão máxima)", function()
		return remoteMsg("tier_set", { id = "doze" })
	end)
	toolBtn("D9 · PREMIUM", "Tier alto: ótimo balanço qualidade/custo", function()
		return remoteMsg("tier_set", { id = "premium" })
	end)
	toolBtn("D6 · NORMAL", "Tier médio: experiência completa em hardware comum", function()
		return remoteMsg("tier_set", { id = "normal" })
	end)
	toolBtn("D3 · LUAU", "Tier mínimo de complexidade suficiente (Tese dos D)", function()
		return remoteMsg("tier_set", { id = "luau" })
	end)
end

-- ---- TERRAIN · 50 (ferramentas reais do WORLDX) ----
function BUILD.terrain()
	section("MUNDO BASE", t.gold)
	toolBtn("Gerar Plano de Terreno", "TerrainX: oceano/continente com seed fixa (modo clássico RRW)", function()
		return remoteMsg("terrain_generate", { seed = 7, preset = "continentes" })
	end)
	toolBtn("Materializar Terreno", "TerrainX vira blocos reais no workspace", function()
		return remoteMsg("terrain_materialize", {})
	end)
	toolBtn("Erosão Clássica", "Gotas de erosão do TerrainX sobre o plano", function()
		return remoteMsg("terrain_erode", { drops = 800 })
	end)
	-- grade dinamica: as 50 tools reais do WORLDX chegam do servidor
	task.spawn(function()
		local ok, res = pcall(remote, "world_tools")
		if not (ok and type(res) == "table" and res.tools) then
			say("world_tools indisponível: gere com o servidor ARKHER", t.err)
			return
		end
		local lastCat = nil
		for _, tl in ipairs(res.tools) do
			if tl.cat ~= lastCat then
				lastCat = tl.cat
				section(string.upper(tl.cat), t.cyan)
			end
			local id = tl.id
			toolBtn(id, ("WORLDX/%s — %s (aplica em 0,0; o planeta aprende)"):format(tl.cat, tl.msg), function()
				return remoteMsg("world_tool", { id = id })
			end)
		end
	end)
end

-- ---- AGUA ----
function BUILD.agua()
	section("OCEANO · ÁGUA (AWX)", Color3.fromRGB(43, 160, 243))
	toolBtn("Oceano Porto", "Corpo d'água real (rompente/refração/profundidade) no nível 10", function()
		return remoteMsg("water_ocean", { sea = "porto" })
	end)
	toolBtn("Barco Físico", "Casco com 4 pontos de empuxo Arquimedes + motor — interage com ondas do AWX", function()
		return remoteMsg("water_boat", {})
	end)
	toolBtn("Mar no Planeta", "Nível do mar do planeta RRW acompanha as células materializadas", function()
		return remoteMsg("world_materialize", { sea = true })
	end)
end

-- ---- CLIMA · LUZ ----
function BUILD.clima()
	section("CÉU (Kelvin real no Lighting)", t.gold)
	for _, pr in ipairs({ "madrugada", "amanhecer", "meiodia", "tarde", "entardecer", "noite" }) do
		local p2 = pr
		toolBtn("☀ " .. pr, "Preset AEX '" .. pr .. "' — Kelvin/haze/fog físicos aplicados ao Lighting", function()
			return remoteMsg("atmos_preset", { preset = p2 })
		end)
	end
	section("WEATHER MACHINE", t.cyan)
	for _, w in ipairs({ "limpo", "nuvem", "chuva", "tempestade", "neblina", "neve", "aurora" }) do
		local w2 = w
		toolBtn("☁ " .. w, "Weather AEX '" .. w .. "' — chuva/vento/nuvens/ondas/relâmpago acoplados (AWX+AUX+", function()
			return remoteMsg("atmos_weather", { state = w2 })
		end)
	end
end

-- ---- VEGET ----
function BUILD.veget()
	section("VEGETAÇÃO VIVA", Color3.fromRGB(120, 220, 130))
	toolBtn("Auto-Vegetar o Planeta", "Cada célula recebe a árvore do SEU bioma Whittaker (densidade do tier)", function()
		return remoteMsg("world_vegetate", {})
	end)
	toolBtn("Floresta Densa", "SceneX: espalha floresta com densidade alta", function()
		return remoteMsg("scatter_forest", { density = 0.9 })
	end)
	toolBtn("Floresta Média", "SceneX: espalha floresta média", function()
		return remoteMsg("scatter_forest", { density = 0.5 })
	end)
	toolBtn("Pátina Anti-CG", "Envelhece o material: jitter de cor + tinta por distância — adeus cara de CG", function()
		return remoteMsg("patina", {})
	end)
end

-- ---- MODELER · 100 (MeshX tools reais) ----
function BUILD.modeler()
	section("BANCA MESHX (faça prim > transforme > finalize)", t.purple)
	toolBtn("Limpar Banca", "Remove a peça atual da banca MeshX", function()
		return remoteMsg("mesh_clean", {})
	end)
	toolBtn("Casa (boolean)", "Demo casa com portas/janelas booleanas REAIS", function()
		return remoteMsg("mesh_house", {})
	end)
	toolBtn("Engrenagem", "Demo gear paramétrica", function()
		return remoteMsg("mesh_gear", {})
	end)
	toolBtn("Cristal", "Demo cristal", function()
		return remoteMsg("mesh_crystal", {})
	end)
	toolBtn("Mesa Terreno", "Demo mesa/terreno procedural", function()
		return remoteMsg("mesh_mesa", {})
	end)
	task.spawn(function()
		local ok, res = pcall(remote, "mesh_tools")
		if not (ok and type(res) == "table" and res.tools) then
			say("mesh_tools indisponível no servidor", t.err)
			return
		end
		local lastCat = nil
		for _, tl in ipairs(res.tools) do
			if tl.cat ~= lastCat then
				lastCat = tl.cat
				section("MESH·" .. string.upper(tl.cat), t.purple)
			end
			local id = tl.id
			toolBtn(id, ("MeshX/%s — %s (opera na banca; prim cria peça nova)"):format(tl.cat, tl.msg), function()
				return remoteMsg("mesh_tool", { id = id })
			end)
		end
	end)
end

-- ---- ANIMATOR (Cascadeur real na sua plataforma) ----
function BUILD.animator()
	section("AUTORIG (esqueletos reais)", t.purple)
	for _, pr in ipairs({ "bipede", "quadrupede", "serpente", "monstro" }) do
		local p2 = pr
		toolBtn("AutoRig " .. pr, "Esqueleto '" .. pr .. "' pronto com FABRIK + pole + alvo orbital", function()
			return remoteMsg("anim_autorig", { preset = p2 })
		end)
	end
	section("AUTOPHYSICS (0 → 1)", t.gold)
	toolBtn("0 · OFF", "AutoPhysics desligado (rig puro)", function()
		return remoteMsg("anim_autophysics", { level = 0 })
	end)
	toolBtn("0.35 · Secundária", "Molas secundárias (cabelo/cauda/panico de penduricalhos)", function()
		return remoteMsg("anim_autophysics", { level = 0.35 })
	end)
	toolBtn("0.7 · +Balanço", "AutoBalance: centro de massa pélvico se autocorrige", function()
		return remoteMsg("anim_autophysics", { level = 0.7 })
	end)
	toolBtn("1.0 · +Balística", "Trajetória balística senoidal completa (Cascadeur-grade)", function()
		return remoteMsg("anim_autophysics", { level = 1 })
	end)
	section("TIMELINE / DEMOS", t.cyan)
	toolBtn("Rig Demo Orbital", "Cadeia 4 ossos FABRIK perseguindo alvo orbital", function()
		return remoteMsg("rig_demo", {})
	end)
	toolBtn("Balanço Pélvico", "Demo de balance de COM", function()
		return remoteMsg("rig_balance", {})
	end)
	toolBtn("Parar Rigs", "StopAll: congela todos os rigs", function()
		return remoteMsg("rig_stop", {})
	end)
	toolBtn("Cube Pump (AAX)", "Timeline 24fps: spring+bounce em pingpong", function()
		return remoteMsg("aax_demo", {})
	end)
end

-- ---- CENA · FX ----
function BUILD.cena()
	section("FX DE CENA", t.cyan)
	toolBtn("Corda + Bandeira", "RPX Verlet: corda, bandeira e esfera com vento do AEX", function()
		return remoteMsg("rope_demo", {})
	end)
	toolBtn("Fogo", "APX emissor fogo (budget D-O15)", function()
		return remoteMsg("px_emit", { kind = "fogo" })
	end)
	toolBtn("Fumaça", "APX emissor fumaça", function()
		return remoteMsg("px_emit", { kind = "fumaca" })
	end)
	toolBtn("Faíscas", "APX emissor faíscas", function()
		return remoteMsg("px_emit", { kind = "faisca" })
	end)
end

-- ---- STATS ----
function BUILD.stats()
	section("TELEMETRIA ARKHER X", t.green)
	toolBtn("Stats Geral", "14 motores: presença, cadeias, ops de mesh, corpos d'água, clima, relógio", function()
		local res = remote("stats")
		if type(res) == "table" then
			local motores = 0
			for _, k in ipairs({ "thx", "wldx", "rrx", "atx", "awx", "asxn", "aax", "aux", "aex", "apx", "rpx", "rigx", "meshx" }) do
				if res[k] then motores = motores + 1 end
			end
			return ("%d/13 motores ON | ops mesh %s | corpos %s | weather %s"):format(
				motores, tostring(res.meshops), tostring(res.bodies), tostring(res.weather))
		end
		return tostring(res)
	end)
	toolBtn("Stats RRW", "Daemon da realidade: entidades/células/vegetação/tier/relógio", function()
		return remoteMsg("rrx_stats", {})
	end)
end

-- ============ abas ============
local TABS = {
	{ id = "planeta",  title = "RRW · PLANETA", col = t.gold },
	{ id = "terrain",  title = "TERRAIN ·50",   col = t.cyan },
	{ id = "agua",     title = "ÁGUA",          col = Color3.fromRGB(43, 160, 243) },
	{ id = "clima",    title = "CLIMA · LUZ",   col = t.gold },
	{ id = "veget",    title = "VEGET",         col = Color3.fromRGB(120, 220, 130) },
	{ id = "modeler",  title = "MODELER ·100",  col = t.purple },
	{ id = "animator", title = "ANIMATOR",      col = t.purple },
	{ id = "cena",     title = "CENA · FX",     col = t.cyan },
	{ id = "stats",    title = "STATS",         col = t.green },
}

local tabBtns = {}
local activeTab = nil

local function selectTab(id)
	if activeTab == id and board.Visible then
		board.Visible = false
		activeTab = nil
		for _, b2 in pairs(tabBtns) do b2.BackgroundColor3 = t.sect end
		return
	end
	activeTab = id
	orderN = 0
	for _, ch in ipairs(grid:GetChildren()) do
		if ch:IsA("GuiObject") then ch:Destroy() end
	end
	for tid, b2 in pairs(tabBtns) do
		b2.BackgroundColor3 = (tid == id) and t.sel or t.sect
	end
	board.Visible = true
	local build = BUILD[id]
	if build then
		local ok, errb = pcall(build)
		if not ok then say("aba falhou: " .. tostring(errb), t.err) end
	end
end

for _, tb in ipairs(TABS) do
	local b0 = B("TextButton", {
		Size = UDim2.fromOffset(74, 22),
		BackgroundColor3 = t.sect,
		Text = tb.title, Font = t.font, TextSize = 9,
		TextColor3 = tb.col or t.text,
		BorderSizePixel = 0, AutoButtonColor = true,
	}, tabHolder)
	H(b0, 6)
	stroke(b0, 1, t.border)
	b0.MouseButton1Click:Connect(function() selectTab(tb.id) end)
	tabBtns[tb.id] = b0
end

if not netFn then
	say("ArkherNet ausente — rode o servidor ARKHER (ServerScriptService)", t.err)
end

-- abre direto no cockpit RRW
task.defer(function() selectTab("planeta") end)

print("[ArkherX] 08_RealityX: topbar RRW com " .. #TABS .. " abas pronta (barra lateral: REMOVIDA)")
