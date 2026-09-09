--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER V3 — UI: CAMERA ]]
-- Layout unico: lista de modos de vista a esquerda, preview com cone de FOV
-- que MUDA ao clicar nos botoes +/-, knobs de FOV/velocidade a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6B81")

local function build()
	local g, root, head = K.window("ArkherCamera", "CAMERA — rig & view", 24, 350, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local fov = 70
	local speed = 16

	-- ===== ESQUERDA: MODOS =====
	local left = K.f(root, "Modes", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MODOS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local modes = { "Orbit", "Free", "Cinematic", "Drone", "Follow", "Top" }
	for i, m in ipairs(modes) do
		local row = K.treeRow(left, 0, i == 3 and ICON.camera or ICON.select, m, i == 3, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Camera: modo " .. m)
		end)
	end
	K.txt(left, "Cinematic ativo", 10, 172, 110, 24, 9, ACCENT)

	-- ===== CENTRO: PREVIEW COM CONE DE FOV =====
	local cv = K.f(root, "Prev", 142, 34, 268, 200, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- ceu/terreno
	K.f(cv, "Sky", 0, 0, 268, 108, C("#12233D"))
	K.f(cv, "Gnd", 0, 108, 268, 92, C("#1B2B22"))
	-- sol
	K.f(cv, "Sun", 200, 24, 14, 14, C("#FFD93D"), 7)
	-- montanhas (frames rotacionados)
	local m1 = K.f(cv, "M1", 20, 78, 90, 30, C("#0E1A2B"))
	m1.Rotation = -8
	local m2 = K.f(cv, "M2", 150, 70, 110, 38, C("#101E30"))
	m2.Rotation = 5
	-- objeto alvo
	K.f(cv, "Tgt", 128, 128, 14, 26, ACCENT)
	K.txt(cv, "alvo", 118, 156, 36, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	-- cone de FOV (2 linhas rotacionadas a partir do olho)
	local coneLines = {}
	local fovLbl = K.txt(cv, "70 FOV", 8, 180, 80, 16, 10, ACCENT)
	local function drawCone()
		for _, l in ipairs(coneLines) do l:Destroy() end
		coneLines = {}
		local ang = fov * 0.42
		for _, s in ipairs({ -1, 1 }) do
			local l = K.f(cv, "C", 135, 140, 150, 2, ACCENT)
			l.Rotation = s * ang
			l.AnchorPoint = Vector2.new(0, 0.5)
			table.insert(coneLines, l)
		end
		local eye = K.f(cv, "Eye", 131, 136, 8, 8, T.neon, 4)
		table.insert(coneLines, eye)
		fovLbl.Text = fov .. " FOV"
	end
	drawCone()

	-- ===== DIREITA: AJUSTES =====
	local right = K.f(root, "Adj", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "FOV", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	local minus = K.btn(right, "M-", 10, 24, 52, 22, T.bg2, 4)
	K.txtS(minus, "-", 12, T.txt)
	K.hover(minus, T.bg2, T.hover)
	local plus = K.btn(right, "M+", 72, 24, 52, 22, T.bg2, 4)
	K.txtS(plus, "+", 12, T.txt)
	K.hover(plus, T.bg2, T.hover)
	minus.MouseButton1Click:Connect(function()
		fov = math.max(20, fov - 5)
		drawCone()
	end)
	plus.MouseButton1Click:Connect(function()
		fov = math.min(120, fov + 5)
		drawCone()
	end)
	K.knob(right, 38, 58, 54, fov / 120, math.floor(fov / 120 * 100 + 0.5) .. "%")
	K.txt(right, "VELOCIDADE", 10, 138, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 38, 156, 54, speed / 40, speed .. " u/s")
	K.row(right, "Zoom", "2.4", 216)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 76, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Rig", "CinematicCam", 8)
	K.row(bar, "Tracking", "Player", 34)
	local apply = K.btn(bar, "Apply", 300, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar ao Place", 10, C("#1C070C"))
	K.hover(apply, ACCENT, C("#FF97A8"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Camera: rig CinematicCam (fov " .. fov .. ", " .. speed .. "u/s) aplicado")
		Bus.emit("camera.apply", { fov = fov, speed = speed, mode = "Cinematic" })
	end)
	K.txt(bar, "lens: 35mm equiv", 430, 28, 104, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Rig de camera: modos, FOV interativo, tracking e preview", build)
end

do
--[[ ARKHER V3 — UI: LIGHTING ]]
-- Layout unico: knobs de sol/ambiente a esquerda, faixa HORA DO DIA clicavel
-- no centro (mexe o ceu + posicao do sol no preview), cores e toggles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD93D")

local SKY_STEPS = {
	{ nm = "Noite", sky = C("#0B1026"), sun = C("#B0BEC5"), y = 78, x = 40 },
	{ nm = "Amanhecer", sky = C("#3E2748"), sun = C("#FF9770"), y = 60, x = 80 },
	{ nm = "Manha", sky = C("#4A78A8"), sun = C("#FFD93D"), y = 34, x = 120 },
	{ nm = "Meio-dia", sky = C("#5B9BD5"), sun = C("#FFF176"), y = 14, x = 160 },
	{ nm = "Tarde", sky = C("#4A6FA5"), sun = C("#FFCA28"), y = 40, x = 200 },
	{ nm = "Pôr do sol", sky = C("#5D3A4E"), sun = C("#FF7043"), y = 62, x = 240 },
	{ nm = "Anoitecer", sky = C("#2A2440"), sun = C("#FF8A65"), y = 78, x = 280 },
	{ nm = "Meia-noite", sky = C("#070B1A"), sun = C("#90A4AE"), y = 84, x = 320 },
}

local function build()
	local g, root, head = K.window("ArkherLighting", "LIGHTING — hora do dia", 24, 360, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local step = 4

	-- ===== ESQUERDA: KNOBS =====
	local left = K.f(root, "Knobs", 8, 34, 132, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SOL", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 22, 60, (step - 1) / 7, "35deg")
	K.txt(left, "AMBIENTE", 10, 96, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 112, 60, 0.45, "0.45")
	K.txt(left, "EXPOSICAO", 10, 184, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 200, 60, 0.5, "1.0x")

	-- ===== CENTRO: PREVIEW DO CEU + FAIXA =====
	local cv = K.f(root, "Sky", 152, 34, 264, 150, C("#5B9BD5"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- nuvens
	K.f(cv, "Cl1", 30, 20, 54, 14, C("#FFFFFF"), 7)
	K.f(cv, "Cl2", 150, 34, 70, 16, C("#F5F7FA"), 8)
	K.f(cv, "Cl3", 90, 58, 40, 10, C("#FFFFFF"), 5)
	-- terreno
	K.f(cv, "Hil", 0, 108, 264, 42, C("#1B2B22"))
	local hill = K.f(cv, "Hill", 60, 92, 140, 26, C("#16241C"))
	hill.Rotation = -3
	-- sol/lua (move com a hora)
	local sun = K.f(cv, "SunObj", SKY_STEPS[step].x, SKY_STEPS[step].y, 20, 20, SKY_STEPS[step].sun, 10)
	K.txt(cv, SKY_STEPS[step].nm, 8, 128, 120, 18, 11, T.txt, ARKHER.FONTB)

	-- faixa hora do dia (clicavel)
	local strip = K.f(root, "Strip", 152, 196, 264, 34, T.bg0)
	K.corner(strip, 4)
	for i, s in ipairs(SKY_STEPS) do
		local b = K.f(strip, "S" .. i, (i - 1) * 33, 4, 31, 26, s.sky, 2)
		K.txt(b, s.nm, 0, 14, 31, 10, 7, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		b.MouseButton1Click:Connect(function()
			step = idx
			cv.BackgroundColor3 = s.sky
			sun.Position = UDim2.new(0, s.x, 0, s.y)
			sun.BackgroundColor3 = s.sun
			ARKHER.out("INFO", "Lighting: " .. s.nm)
		end)
	end

	-- ===== DIREITA: CORES + TOGGLES =====
	local right = K.f(root, "Cols", 428, 34, 124, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "CORES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local colors = {
		{ "Sky", C("#5B9BD5") }, { "Cloud", C("#F5F7FA") },
		{ "Shadow", C("#3E5C76") }, { "Fog", C("#B0C4DE") },
	}
	for i, c2 in ipairs(colors) do
		K.row(right, c2[1], "", 26 + (i - 1) * 24)
		local sw = K.f(right, "CSw" .. i, 78, 26 + (i - 1) * 24, 34, 16, c2[2], 3)
		K.stroke(sw, T.line2, 1)
	end
	K.checkRow(right, "Sombras", true, 126)
	K.checkRow(right, "Fog", false, 150)
	K.checkRow(right, "Global light", true, 174)
	K.checkRow(right, "Post FX", true, 198)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 90, T.bg0)
	K.corner(bar, 4)
	local create = K.btn(bar, "Create", 10, 10, 140, 26, ACCENT, 5)
	K.txtS(create, "Criar luz no Place", 10, C("#1A1403"))
	K.hover(create, ACCENT, C("#FFE57A"))
	create.MouseButton1Click:Connect(function()
		local ws = workspace
		if ws:FindFirstChild("ArkherLighting") then ws:FindFirstChild("ArkherLighting"):Destroy() end
		local f = Instance.new("Folder")
		f.Name = "ArkherLighting"
		f:SetAttribute("Hora", SKY_STEPS[step].nm)
		f:SetAttribute("Sol", 35)
		f.Parent = ws
		ARKHER.out("SUCCESS", "Lighting: luz " .. SKY_STEPS[step].nm .. " criada no place")
	end)
	K.txt(bar, "sun: " .. SKY_STEPS[step].nm, 170, 16, 180, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 524, (step - 1) / 7, ACCENT)
	K.txt(bar, "ciclo: 0h -> " .. ((step - 1) * 3) .. "h", 170, 58, 200, 14, 9, T.txt4)
end

ARKHER.reg("Lighting", "Lighting", "Scene", ICON.bulb, "Iluminacao: hora do dia interativa, sol, cores e post FX", build)
end

do
--[[ ARKHER V3 — UI: AUDIO ]]
-- Layout unico: lista de faixas com FORMAS DE ONDA (K.wave) a esquerda,
-- detalhe da faixa selecionada no centro, mixer com VERTICAIS (K.vfader) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#A29BFE")

local TRACKS = {
	{ nm = "Theme_01", len = "2:34", seed = 11, vol = 0.8, kind = "Music" },
	{ nm = "City_amb", len = "4:10", seed = 23, vol = 0.55, kind = "Ambience" },
	{ nm = "UI_click", len = "0:01", seed = 37, vol = 0.7, kind = "SFX" },
	{ nm = "Boss_roar", len = "0:04", seed = 53, vol = 0.9, kind = "SFX" },
}

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO — mixer & faixas", 24, 370, 560, 372, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local sel = 1

	-- ===== ESQUERDA: FAIXAS =====
	local left = K.f(root, "Tracks", 8, 34, 150, 260, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FAIXAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, tr in ipairs(TRACKS) do
		local row = K.f(left, "Tr" .. i, 6, 26 + (i - 1) * 56, 138, 50, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, tr.nm, 6, 4, 90, 14, 10, T.txt)
		K.txt(row, tr.kind .. " | " .. tr.len, 6, 18, 120, 12, 8, T.txt4)
		K.wave(row, 6, 32, 100, 14, tr.seed, i == 1 and ACCENT or T.txt4)
		K.txt(row, math.floor(tr.vol * 100 + 0.5) .. "%", 110, 34, 26, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
		local idx = i
		row.MouseButton1Click:Connect(function()
			sel = idx
			ARKHER.out("INFO", "Audio: selecionada " .. tr.nm)
		end)
	end

	-- ===== CENTRO: DETALHE =====
	local cv = K.f(root, "Detail", 170, 34, 244, 160, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, TRACKS[1].nm, 10, 8, 160, 16, 12, T.txt, ARKHER.FONTB)
	K.txt(cv, "Music | 2:34 | 44.1kHz", 10, 26, 180, 14, 9, T.txt4)
	K.wave(cv, 10, 48, 224, 56, 11, ACCENT)
	-- seek
	local seek, seekFill = K.progress(cv, 10, 116, 180, 0.36, ACCENT)
	K.txt(cv, "0:54", 196, 110, 36, 14, 9, T.txt3)
	-- controles
	local pl = K.btn(cv, "Pl", 10, 134, 44, 22, T.bg2, 4)
	K.txtS(pl, "Play", 10, T.txt)
	K.hover(pl, T.bg2, T.hover)
	pl.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: tocando " .. TRACKS[sel].nm)
	end)
	local pp = K.btn(cv, "Pp", 60, 134, 44, 22, T.bg2, 4)
	K.txtS(pp, "Stop", 10, T.txt)
	K.hover(pp, T.bg2, T.hover)
	pp.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: parado")
	end)

	-- ===== DIREITA: MIXER =====
	local right = K.f(root, "Mixer", 426, 34, 126, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MIXER", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local chans = { "MUS", "SFX", "AMB" }
	local vols = { 0.8, 0.7, 0.55 }
	for i = 1, 3 do
		K.vfader(right, 18 + (i - 1) * 36, 28, 150, vols[i], chans[i])
	end
	K.txt(right, "MASTER", 10, 192, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.vfader(right, 30, 208, 40, 0.75, "M")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 60, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Loop", true, 8)
	K.sliderRow(bar, "Master vol", 0.75, 34)
	local add = K.btn(bar, "Add", 300, 16, 90, 28, ACCENT, 5)
	K.txtS(add, "+ faixa", 11, C("#12102A"))
	K.hover(add, ACCENT, C("#C3BFFF"))
	add.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Audio: faixa 'Nova' adicionada ao mixer")
	end)
	K.txt(bar, "3 canais | 44.1k | 16bit", 410, 22, 130, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Audio", "Audio", "Scene", ICON.data, "Mixer de audio: faixas com waveforms, seek e canais verticais", build)
end

do
--[[ ARKHER V3 — UI: PHYSICS ]]
-- Layout unico: parametros globais a esquerda, GRID DE COLISAO interativo
-- (clique liga/desliga collider) no centro, lista de joints a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FD9644")

local function build()
	local g, root, head = K.window("ArkherPhysics", "PHYSICS — colliders & joints", 24, 380, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local colliders = {}
	for i = 1, 144 do
		local s = (i * 16807) % 2147483647
		colliders[i] = (s % 5) < 2
	end
	local onCount = 0
	for _, v in ipairs(colliders) do if v then onCount = onCount + 1 end end

	-- ===== ESQUERDA: PARAMETROS =====
	local left = K.f(root, "Params", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MUNDO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(left, "Gravidade", 0.7, 26)
	K.row(left, "", "196.2 m/s2", 52)
	K.sliderRow(left, "Time scale", 1.0, 80)
	K.row(left, "", "x1.0", 106)
	K.sliderRow(left, "Frequencia", 0.5, 134)
	K.row(left, "", "60 Hz", 160)
	K.checkRow(left, "Sleep mode", true, 190)
	K.checkRow(left, "CCD", false, 214)

	-- ===== CENTRO: GRID DE COLISAO =====
	local cv = K.f(root, "Grid", 150, 34, 264, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "colisao (clique = liga/desliga)", 8, 230, 240, 14, 9, T.txt4)
	local dots = {}
	for i = 1, 144 do
		local r, c = math.floor((i - 1) / 12) + 1, ((i - 1) % 12) + 1
		local d = K.f(cv, "D" .. i, (c - 1) * 21 + 8, (r - 1) * 18 + 10, 9, 9, colliders[i] and ACCENT or T.bg3, 4)
		dots[i] = d
		local idx = i
		d.MouseButton1Click:Connect(function()
			colliders[idx] = not colliders[idx]
			d.BackgroundColor3 = colliders[idx] and ACCENT or T.bg3
			if colliders[idx] then onCount = onCount + 1 else onCount = onCount - 1 end
			cntLbl.Text = onCount .. " colliders ativos"
		end)
	end
	local cntLbl = K.txt(cv, onCount .. " colliders ativos", 8, 216, 180, 14, 10, ACCENT)

	-- ===== DIREITA: JOINTS =====
	local right = K.f(root, "Joints", 426, 34, 126, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "JOINTS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(right, 0, ICON.ws, "Weld_Constraint", "ok", 26)
	K.treeRow(right, 1, nil, "Part1 <-> Part2", nil, 50)
	K.treeRow(right, 0, ICON.ws, "Motor6D", "ok", 74)
	K.treeRow(right, 1, nil, "Leg (hip)", nil, 98)
	K.treeRow(right, 0, ICON.ws, "SpringWire", nil, 122)
	local addJ = K.btn(right, "AddJ", 10, 150, 106, 22, T.bg2, 4)
	K.txtS(addJ, "+ joint", 10, T.txt)
	K.hover(addJ, T.bg2, T.hover)
	local joints = 3
	addJ.MouseButton1Click:Connect(function()
		joints = joints + 1
		ARKHER.out("INFO", "Physics: joint #" .. joints .. " criado")
	end)
	K.row(right, "Solver", "2 iter", 190)
	K.row(right, "Mass total", "412 kg", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Centro de massa", "(0, 3.2, 0)", 8)
	K.row(bar, "Velocidade media", "0.4 u/s", 34)
	local apply = K.btn(bar, "Apply", 320, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar fisico", 10, C("#241102"))
	K.hover(apply, ACCENT, C("#FFB87A"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Physics: " .. onCount .. " colliders + " .. joints .. " joints aplicados")
		Bus.emit("physics.apply", { colliders = onCount, joints = joints })
	end)
	K.txt(bar, "solver: v2", 450, 28, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Physics", "Physics", "Scene", ICON.ws, "Fisica: grid de colisao interativo, joints e parametros do mundo", build)
end

do
--[[ ARKHER V3 — UI: UIDESIGNER ]]
-- Layout unico: paleta de widgets a esquerda, CANVAS com grade no centro
-- (widgets posicionados, clique seleciona), inspector de estilo a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")

local function build()
	local g, root, head = K.window("ArkherUIDesigner", "UI DESIGNER — canvas", 24, 390, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: PALETA =====
	local left = K.f(root, "Pal", 8, 34, 120, 268, T.bg4)
	K.corner(left, 4)
	K.txt(left, "WIDGETS", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local palette = {
		{ nm = "Button", ic = ICON.transform },
		{ nm = "Label", ic = ICON.textA },
		{ nm = "Frame", ic = ICON.plate },
		{ nm = "TextBox", ic = ICON.script },
		{ nm = "Image", ic = ICON.gem },
		{ nm = "Toggle", ic = ICON.check },
	}
	for i, p in ipairs(palette) do
		local row = K.btn(left, "P" .. i, 8, 26 + (i - 1) * 26, 104, 22, T.bg2, 4)
		local ic = K.f(row, "Ic", 4, 3, 16, 16)
		p.ic(ic, 14)
		K.txt(row, p.nm, 24, 0, 76, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "UIDesigner: widget " .. p.nm .. " na paleta")
		end)
	end
	K.txt(left, "6 widgets", 10, 196, 90, 14, 9, T.txt4)
	K.row(left, "Zoom", "100%", 216)
	K.row(left, "Snap", "8px", 240)

	-- ===== CENTRO: CANVAS COM GRADE =====
	local cv = K.f(root, "Canvas", 140, 34, 272, 268, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 13 do K.f(cv, "gx" .. i, i * 20, 0, 1, 268, T.bg3) end
	for i = 1, 13 do K.f(cv, "gy" .. i, 0, i * 20, 272, 1, T.bg3) end
	-- widgets ja colocados
	local widgets = {
		{ x = 20, y = 30, w = 120, h = 32, nm = "Btn_Primary", c = ACCENT },
		{ x = 160, y = 30, w = 92, h = 32, nm = "Label_Titulo", c = T.sec },
		{ x = 20, y = 84, w = 232, h = 72, nm = "Frame_Card", c = T.bg2 },
		{ x = 20, y = 172, w = 140, h = 28, nm = "Txt_Input", c = T.bg4 },
	}
	local selW = 3
	local wFrames = {}
	for i, w2 in ipairs(widgets) do
		local f = K.f(cv, "W" .. i, w2.x, w2.y, w2.w, w2.h, w2.c, 4)
		K.stroke(f, i == selW and ACCENT or T.line, i == selW and 2 or 1)
		K.txt(f, w2.nm, 6, 4, w2.w - 12, 14, 9, w2.c == ACCENT and C("#10202A") or T.txt2)
		wFrames[i] = f
		local idx = i
		f.MouseButton1Click:Connect(function()
			selW = idx
			for j, fr in ipairs(wFrames) do
				K.stroke(fr, j == idx and ACCENT or T.line, j == idx and 2 or 1)
			end
			nameLbl.Text = widgets[idx].nm
		end)
	end
	local nameLbl = K.txt(cv, "Frame_Card", 200, 244, 66, 14, 9, ACCENT, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: INSPECTOR =====
	local right = K.f(root, "Insp", 424, 34, 128, 268, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ESTILO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Pos", "20, 84", 26)
	K.row(right, "Size", "232 x 72", 50)
	K.sliderRow(right, "Opacidade", 1.0, 76)
	K.sliderRow(right, "Rounded", 0.4, 102)
	K.knob(right, 40, 124, 48, 0.4, "r: 8px")
	K.checkRow(right, "Stroke", true, 186)
	K.checkRow(right, "Drop shadow", false, 210)
	K.checkRow(right, "Auto resize", true, 234)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 312, 544, 72, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Gerar GUI no Place", 10, C("#041820"))
	K.hover(gen, ACCENT, C("#7DEBFF"))
	gen.MouseButton1Click:Connect(function()
		local ws = workspace
		local gui = Instance.new("ScreenGui")
		gui.Name = "ArkherGeneratedUI"
		gui.Parent = ws
		for _, w2 in ipairs(widgets) do
			local isBtn = w2.nm:sub(1, 4) == "Btn_"
			local inst = Instance.new(isBtn and "TextButton" or (w2.nm:sub(1, 4) == "Txt_" and "TextBox" or "Frame"))
			inst.Name = w2.nm
			inst.Parent = gui
			inst:SetAttribute("ARKHER", "designed")
		end
		ARKHER.out("SUCCESS", "UIDesigner: GUI gerada no place (" .. #widgets .. " widgets)")
		K.notify("GUI gerada", "ArkherGeneratedUI no workspace", "ok")
	end)
	K.txt(bar, "4 widgets no canvas", 160, 16, 150, 16, 10, T.txt3)
	K.txt(bar, "AutoLayout: ON", 330, 16, 110, 16, 9, T.txt4)
	K.txt(bar, "960x540", 470, 16, 70, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("UIDesigner", "UI Designer", "Editor", ICON.plate, "Designer de UI: paleta, canvas com grade e inspector de estilo", build)
end

do
--[[ ARKHER V3 — UI: MAP ]]
-- Layout unico: minimapa grande no centro com POIs (ICON.pin) clicaveis,
-- lista de pontos de interesse a esquerda, legenda a direita, exportacao real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#55EFC4")

local POIS = {
	{ nm = "Spawn Point", x = 60, y = 180, c = ACCENT, kind = "spawn" },
	{ nm = "Municipio", x = 150, y = 90, c = C("#FFD93D"), kind = "build" },
	{ nm = "Porto", x = 30, y = 60, c = C("#74B9FF"), kind = "water" },
	{ nm = "Base Militar", x = 250, y = 200, c = C("#FF6B81"), kind = "military" },
}

local function build()
	local g, root, head = K.window("ArkherMap", "MAP — pontos de interesse", 24, 400, 572, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	local selPoi = 1

	-- ===== ESQUERDA: LISTA DE POIs =====
	local left = K.f(root, "Pois", 8, 34, 128, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POIs", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local poiBtns = {}
	for i, p in ipairs(POIS) do
		local row = K.btn(left, "P" .. i, 8, 26 + (i - 1) * 34, 112, 30, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		local ic = K.f(row, "Ic", 4, 5, 20, 20)
		ICON.pin(ic)
		K.txt(row, p.nm, 28, 0, 80, 30, 10, T.txt)
		K.hover(row, T.bg4, T.hover)
		poiBtns[i] = row
		local idx = i
		row.MouseButton1Click:Connect(function()
			selPoi = idx
			for j, b in ipairs(poiBtns) do
				K.stroke(b, j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			detNm.Text = POIS[idx].nm
			detKd.Text = POIS[idx].kind
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	K.txt(left, "4 POIs mapeados", 10, 172, 110, 30, 9, T.txt4)
	local addP = K.btn(left, "AddP", 8, 200, 112, 22, T.bg2, 4)
	K.txtS(addP, "+ POI", 10, T.txt)
	K.hover(addP, T.bg2, T.hover)
	addP.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Map: novo POI em modo de colocacao")
	end)

	-- ===== CENTRO: MINIMAPA =====
	local cv = K.f(root, "Map", 148, 34, 292, 256, C("#16281F"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- agua
	local water = K.f(cv, "Water", 0, 0, 70, 110, C("#1B3A5C"), 0)
	K.grad(water, C("#1B3A5C"), C("#122A44"))
	-- estradas
	K.f(cv, "R1", 0, 130, 292, 10, C("#3A3F47"))
	K.f(cv, "R2", 140, 0, 10, 256, C("#3A3F47"))
	K.f(cv, "R3", 60, 200, 232, 8, C("#33383F"))
	-- quarteiroes
	K.f(cv, "B1", 90, 60, 40, 56, C("#24382C"))
	K.f(cv, "B2", 170, 40, 52, 60, C("#26392D"))
	K.f(cv, "B3", 200, 160, 60, 70, C("#22352A"))
	K.f(cv, "B4", 90, 170, 36, 60, C("#24382C"))
	-- pinos
	local pins = {}
	for i, p in ipairs(POIS) do
		local pin = K.f(cv, "Pin" .. i, p.x - 8, p.y - 16, 16, 16, T.bg0)
		ICON.pin(pin)
		if i == 1 then
			local ring = K.f(cv, "Ring" .. i, p.x - 13, p.y - 21, 26, 26, T.bg0)
			ring.BackgroundTransparency = 1
			K.corner(ring, 13)
			K.stroke(ring, ACCENT, 2)
			pins[i] = ring
		end
		K.txt(cv, "L" .. i, p.x - 30, p.y + 4, 60, 12, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		pin.MouseButton1Click:Connect(function()
			selPoi = idx
			detNm.Text = POIS[idx].nm
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	-- norte
	local north = K.f(cv, "North", 258, 8, 24, 24, T.bg0, 12)
	K.stroke(north, ACCENT, 1.5)
	K.txt(north, "N", 0, 4, 24, 16, 10, ACCENT, FONTB, Enum.TextXAlignment.Center)

	-- ===== DIREITA: LEGENDA + DETALHE =====
	local right = K.f(root, "Leg", 452, 34, 112, 256, T.bg4)
	K.corner(right, 4)
	K.txt(right, "LEGENDA", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local legend = {
		{ "Agua", C("#1B3A5C") }, { "Estrada", C("#3A3F47") },
		{ "Predio", C("#26392D") }, { "Spawn", ACCENT },
	}
	for i, l in ipairs(legend) do
		K.f(right, "L" .. i, 10, 28 + (i - 1) * 22, 12, 12, l[2], 2)
		K.txt(right, l[1], 28, 26 + (i - 1) * 22, 70, 14, 9, T.txt2)
	end
	K.txt(right, "DETALHE", 10, 128, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local detNm = K.txt(right, "Spawn Point", 10, 146, 94, 16, 10, ACCENT, ARKHER.FONTB)
	local detKd = K.txt(right, "spawn", 10, 164, 94, 14, 9, T.txt4)
	K.row(right, "Escala", "1:500", 190)
	K.row(right, "Resolucao", "512px", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 298, 556, 94, T.bg0)
	K.corner(bar, 4)
	local exp = K.btn(bar, "Exp", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(exp, "Exportar mapa", 10, C("#04180F"))
	K.hover(exp, ACCENT, C("#9DF5D8"))
	exp.MouseButton1Click:Connect(function()
		local lines = { "-- MAPA ARKHER", string.format("gerado em %s", tostring(tick() and math.floor(tick() * 100))) }
		for i, p in ipairs(POIS) do
			table.insert(lines, string.format("%d. %s (%s) @ (%d, %d)", i, p.nm, p.kind, p.x, p.y))
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherMaps/mapa_pois.txt", table.concat(lines, "\n"))
				return "ArkherMaps/mapa_pois.txt"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Map: exportado para " .. path)
			K.notify("Mapa exportado", path, "ok")
		else
			ARKHER.out("WARNING", "Map: WriteFile indisponivel fora do Studio")
		end
	end)
	K.txt(bar, "128x128u | 4 POIs | escala 1:500", 160, 16, 240, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 536, 0.8, ACCENT)
	K.txt(bar, "mapeado: 80%", 160, 58, 120, 14, 9, T.txt4)
end

ARKHER.reg("Map", "Map", "Scene", ICON.globe, "Mapa: minimapa com POIs interativos, legenda e exportacao", build)
end

local opened = ARKHER.openAll()
ARKHER.out("SUCCESS", "ARKHER V3 — bundle Scene: " .. opened .. " UIs abertas")
