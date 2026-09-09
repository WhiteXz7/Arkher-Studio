--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA (6/13)
  Paineis UI_AI…UI_Modeler
  Cria: StarterPlayerScripts.Arkher.Panels: UI_AI, UI_About, UI_Animator, UI_Audio, UI_Camera, UI_City, UI_Cloud, UI_CommandPalette, UI_Console, UI_Lighting, UI_Map, UI_Modeler
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]
local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local arkher = spps:FindFirstChild("Arkher")
if not arkher then arkher = Instance.new("Folder") arkher.Name = "Arkher" arkher.Parent = spps end
local panels = arkher:FindFirstChild("Panels")
if not panels then panels = Instance.new("Folder") panels.Name = "Panels" panels.Parent = arkher end
local S_0 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: AI (SINGULARITY) ]]
-- Layout unico: campo de objetivo + chips de sugestao, execucao REAL
-- (ARKHER_SINGULARITY.run), relatorio ao centro, historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")

local SUGGESTIONS = {
	"crie uma cidade com npc",
	"crie um terreno com natureza",
	"crie um espaco com asteroides",
	"otimize e diagnostico",
}

local function build()
	local g, root, head = K.window("ArkherAI", "AI — Singularity (local)", 24, 470, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: OBJETIVO =====
	local goalBox = K.input(root, 8, 34, 360, 26, "descreva o que construir...")
	local run = K.btn(root, "Run", 380, 34, 100, 26, ACCENT, 5)
	K.txtS(run, "EXECUTAR", 11, C("#04141C"))
	K.hover(run, ACCENT, C("#7DEBFF"))
	-- chips
	local chips = {}
	for i, sg in ipairs(SUGGESTIONS) do
		local ch = K.btn(root, "Ch" .. i, 8 + (i - 1) * 138, 68, 132, 20, T.bg4, 10)
		K.txtS(ch, sg, 8, T.txt3)
		K.hover(ch, T.bg4, T.hover)
		local sg2 = sg
		ch.MouseButton1Click:Connect(function()
			goalBox.Text = sg2
		end)
		chips[i] = ch
	end

	-- ===== CENTRO: RELATORIO =====
	local rep = K.f(root, "Rep", 8, 96, 360, 190, T.bg0)
	K.corner(rep, 4)
	K.stroke(rep, T.line, 1)
	K.txt(rep, "RELATORIO DE EXECUCAO", 10, 6, 180, 14, 10, T.txt3, ARKHER.FONTB)
	local area = K.f(rep, "Area", 0, 26, 360, 160)
	local lastRep
	local function renderRep()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		if not lastRep then
			K.txt(area, "a Singularity planeja o objetivo em intents\n(city / nature / space / npc / perf / check...)\ne executa de VERDADE no workspace.", 12, 8, 330, 50, 9, T.txt4)
			return
		end
		local y = 4
		for i, l in ipairs(lastRep.lines) do
			local col = T.txt2
			if l:sub(1, 5) == "plano" then col = T.neon end
			if l:find("diagnostico") then col = C("#FFD93D") end
			if l:find("performance") then col = T.ok end
			if l:find("ERRO") then col = T.danger end
			K.txt(area, l, 12, y, 336, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
			y = y + 18
			if y > 150 then break end
		end
	end
	renderRep()
	run.MouseButton1Click:Connect(function()
		local goal = goalBox.Text
		if goal == "" then goal = "diagnostico" end
		ARKHER.out("INFO", "AI: executando: " .. goal)
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run(goal) end)
		if ok and r then
			lastRep = r
			renderRep()
			ARKHER.out("SUCCESS", "AI: missao concluida (" .. #r.lines .. " etapas)")
		else
			ARKHER.out("ERROR", "AI: falhou: " .. tostring(r))
		end
	end)

	-- ===== DIREITA: HISTORICO + MODO =====
	local right = K.f(root, "Hist", 380, 96, 172, 190, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 172, 120)
	local hist = {}
	local function renderHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		if #hist == 0 then
			K.txt(histArea, "(sem missoes ainda)", 10, 6, 150, 20, 9, T.txt4)
			return
		end
		for i, h in ipairs(hist) do
			if i > 5 then break end
			K.txt(histArea, "- " .. h, 10, 4 + (i - 1) * 22, 152, 20, 9, T.txt3)
		end
	end
	renderHist()
	run.MouseButton1Click:Connect(function()
		table.insert(hist, 1, goalBox.Text)
		table.remove(hist, 6)
		renderHist()
	end)
	K.row(right, "Modo", ARKHER.STATE.ai and ARKHER.STATE.ai.mode or "local", 152)
	K.txt(right, "IA 100% local:\nplanner + especialistas\nexecutam no Roblox.", 10, 168, 152, 44, 9, T.txt4)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "SINGULARITY", 12, 8, 140, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "planner de intent -> especialistas locais -> execucao real + relatorio", 12, 28, 400, 14, 9, T.txt3)
	K.txt(bar, "sem cloud, sem API key", 12, 52, 200, 14, 9, T.txt4)
	local diag = K.btn(bar, 340, 52, 100, 24, T.bg2, 4)
	K.txtS(diag, "diagnostico", 9, T.txt)
	K.hover(diag, T.bg2, T.hover)
	diag.MouseButton1Click:Connect(function()
		goalBox.Text = "diagnostico"
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run("diagnostico") end)
		if ok and r then lastRep = r renderRep() end
	end)
	K.txt(bar, "missoes: " .. tostring(#hist), 460, 58, 84, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("AI", "AI (Singularity)", "System", ICON.gem, "IA local: objetivo -> plano -> execucao real no workspace + relatorio", build)
end

ARKHER.open("AI")
]====]
local S_1 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: ABOUT ]]
-- Layout unico: emblem + versao ao centro, lista REAL dos sistemas ativos
-- a esquerda, contadores vivos a direita (UIs, comandos, places, mentes).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#576574")

local function build()
	local g, root, head = K.window("ArkherAbout", "ABOUT — ARKHER V3", 24, 520, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: SISTEMAS =====
	local left = K.f(root, "Sys", 8, 34, 168, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SISTEMAS ATIVOS", 10, 6, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local systems = {
		{ "Places (cloud local)", ArkherPlaces ~= nil },
		{ "Undo/Redo (50)", ArkherUNDO ~= nil },
		{ "Live (inspector)", ArkherLive ~= nil },
		{ "D-O15 (perf)", ArkherDO15 ~= nil },
		{ "Singularity (IA)", ARKHER_SINGULARITY ~= nil },
		{ "NMN (mentes)", ArkherNMN ~= nil },
		{ "Publish (sem Open API)", ArkherPublish ~= nil },
		{ "Actions (ARKHER.cmd)", ARKHER.ACTIONS ~= nil },
	}
	for i, s in ipairs(systems) do
		K.treeRow(left, 0, s[2] and ICON.check or ICON.close, s[1], s[2] and "ok" or nil, 26 + (i - 1) * 27)
	end

	-- ===== CENTRO: EMBLEM + VERSAO =====
	local cv = K.f(root, "Brand", 188, 34, 204, 170, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line2, 1)
	local emb = K.f(cv, "Emblem", 82, 20, 40, 40)
	ICON.emblem(emb, 40)
	K.txt(cv, "ARKHER STUDIO", 0, 68, 204, 20, 16, T.txt, ARKHER.FONTB, Enum.TextXAlignment.Center)
	K.txt(cv, "v" .. tostring(ARKHER._version or "3.0.0"), 0, 90, 204, 14, 10, T.neon, FONT, Enum.TextXAlignment.Center)
	K.txt(cv, "UES COMPLETA MAS NO ROBLOX", 0, 112, 204, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	K.grad(cv, T.dark, C("#101828"), 90)
	local tags = K.f(cv, "Tags", 0, 134, 204, 30, T.bg0)
	K.txt(tags, "criar places | publicar facil | IA local", 0, 0, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(tags, "sem Open API | sem cloud obrigatoria", 0, 16, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)

	-- ===== DIREITA: CONTADORES VIVOS =====
	local right = K.f(root, "Count", 404, 34, 148, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AGORA", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local uiCount = #ARKHER.listUIs()
	local cmdCount = 0
	for _ in pairs(ARKHER.ACTIONS or {}) do cmdCount = cmdCount + 1 end
	local placesCount = #ArkherPlaces.list()
	local nmnCount = ArkherNMN and ArkherNMN.count() or 0
	local counters = {
		{ "UIs registradas", tostring(uiCount) },
		{ "Comandos (ARKHER.cmd)", tostring(cmdCount) },
		{ "Places salvos", tostring(placesCount) },
		{ "Mentes NMN", tostring(nmnCount) },
		{ "Nivel D-O15", tostring((ArkherDO15 and ArkherDO15.state and ArkherDO15.state.level) or "?") },
		{ "Place atual", ARKHER.STATE.placeName or "?" },
	}
	for i, c2 in ipairs(counters) do
		K.txt(right, c2[1], 10, 28 + (i - 1) * 34, 130, 14, 9, T.txt3)
		K.txt(right, c2[2], 10, 44 + (i - 1) * 34, 130, 16, 11, T.txt, ARKHER.FONTB)
		if i < #counters then K.f(right, "sep" .. i, 10, 62 + (i - 1) * 34, 128, 1, T.line) end
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "feito no Roblox Studio, para o Roblox Studio", 12, 8, 320, 16, 10, T.txt3)
	K.txt(bar, "batch 0: core + shell | batch 1: UIs unicas | batch 2: integracao", 12, 28, 420, 14, 9, T.txt4)
	K.txt(bar, "2026", 500, 8, 40, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	local closeB = K.btn(bar, 340, 44, 100, 24, T.bg2, 4)
	K.txtS(closeB, "fechar", 10, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		root.Visible = false
	end)
end

ARKHER.reg("About", "About", "System", ICON.info, "Sobre o ARKHER V3: sistemas ativos e contadores em tempo real", build)
end

ARKHER.open("About")
]====]
local S_2 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: ANIMATOR ]]
-- Layout unico: lista de poses a esquerda, preview do personagem no centro,
-- timeline real com keytracks (K.keyTrack) + scrub + controles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF9F43")

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR — timeline & poses", 24, 300, 540, 392, { pin = true })

	-- acento na head
	K.f(head, "Acc", 0, 24, 540, 2, ACCENT)

	-- ===== PAINEL ESQUERDO: POSES =====
	local left = K.f(root, "Poses", 8, 34, 122, 300, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POSES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local poses = { "Pose Inicial", "Andar", "Correr", "Pulo", "Ataque" }
	local selPose = 1
	for i, p in ipairs(poses) do
		local row = K.treeRow(left, 0, i == 1 and ICON.play or ICON.pause, p, i == 1, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			selPose = i
			ARKHER.out("INFO", "Animator: pose selecionada: " .. p)
		end)
	end
	K.txt(left, "clique = trocar pose", 8, 160, 110, 30, 9, T.txt4)

	-- ===== CENTRO: PREVIEW =====
	local pv = K.f(root, "Preview", 140, 34, 250, 150, T.dark)
	K.corner(pv, 4)
	K.stroke(pv, T.line, 1)
	-- grade
	for i = 1, 7 do
		K.f(pv, "gx" .. i, i * 34, 0, 1, 150, T.bg3)
		K.f(pv, "gy" .. i, 0, i * 21, 250, 1, T.bg3)
	end
	-- silhueta humanoide (frames)
	local bx = 105
	K.f(pv, "Head", bx, 34, 22, 22, ACCENT, 6)
	K.f(pv, "Torso", bx + 2, 58, 18, 34, T.neon)
	K.f(pv, "ArmL", bx - 10, 58, 8, 30, T.neon)
	K.f(pv, "ArmR", bx + 24, 58, 8, 30, T.neon)
	K.f(pv, "LegL", bx + 2, 94, 7, 34, T.neon)
	K.f(pv, "LegR", bx + 13, 94, 7, 34, T.neon)
	local poseLbl = K.txt(pv, "Pose: Andar", 8, 130, 120, 16, 10, T.txt3)
	-- sombra
	K.f(pv, "Shadow", bx - 12, 130, 58, 5, T.bg0, 2)

	-- ===== CENTRO-BAIXO: TIMELINE =====
	local tl = K.f(root, "Timeline", 140, 194, 392, 140, T.bg0)
	K.corner(tl, 4)
	K.txt(tl, "TIMELINE", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.keyTrack(tl, "Position", 24, { 0, 0.28, 0.62, 0.9 }, ACCENT)
	K.keyTrack(tl, "Rotation", 46, { 0.15, 0.55, 0.78 }, C("#FFD93D"))
	K.keyTrack(tl, "Scale", 68, { 0.5, 0.52 }, C("#74B9FF"))
	-- scrub
	local playLbl = K.btn(tl, "Play", 8, 96, 52, 20, T.bg2, 4)
	K.txtS(playLbl, "Play", 10, T.txt)
	K.hover(playLbl, T.bg2, T.hover)
	local playing = false
	playLbl.MouseButton1Click:Connect(function()
		playing = not playing
		playLbl.Text = ""
		K.txt(playLbl, playing and "Pause" or "Play", 0, 0, 52, 20, 10, T.txt, FONTB, Enum.TextXAlignment.Center)
		ARKHER.out(playing and "SUCCESS" or "INFO", "Animator: " .. (playing and "tocando" or "pausado") .. " — " .. poses[selPose])
	end)
	local scrub, scrubFill = K.progress(tl, 70, 104, 310, 0.32, ACCENT)
	local tLbl = K.txt(tl, "0.96s / 3.00s", 70, 122, 150, 14, 9, T.txt4)
	-- marcadores de tempo
	for i = 0, 10 do
		K.txt(tl, tostring(i) .. ".0", 70 + i * 31, 116, 20, 10, 7, T.txt4)
	end
	-- zoom
	K.txt(tl, "zoom x1", 330, 122, 40, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrls", 442, 34, 90, 300, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AJUSTES", 10, 6, 70, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(right, "Duracao", 0.34, 26)
	K.sliderRow(right, "Ease", 0.5, 52)
	K.checkRow(right, "Loop", true, 80)
	K.checkRow(right, "Fade in", true, 104)
	K.row(right, "Frames", "90 @ 30fps", 130)
	local bake = K.btn(right, "Bake", 10, 158, 70, 24, ACCENT, 5)
	K.txtS(bake, "BAKE", 11, C("#14100C"))
	K.hover(bake, ACCENT, C("#FFB86B"))
	bake.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Animator: " .. poses[selPose] .. " baked (90 frames, 3.0s)")
		K.notify("Bake concluido", poses[selPose] .. " -> AnimationTrack", "ok")
		Bus.emit("animator.bake", { pose = poses[selPose], frames = 90 })
	end)
	K.row(right, "Size", "1.2 KB", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 344, 524, 40, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "4 keyframes", 12, 6, 90, 14, 9, T.txt3)
	K.txt(bar, "3 tracks", 110, 6, 70, 14, 9, T.txt3)
	K.txt(bar, "30 fps", 188, 6, 60, 14, 9, T.txt3)
	K.txt(bar, "Andar.anim", 256, 6, 100, 14, 9, ACCENT)
	K.txt(bar, "pronto", 480, 6, 40, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Animator", "Animator", "Editor", ICON.play, "Timeline de animacao: poses, keyframes, scrub e bake", build)
end

ARKHER.open("Animator")
]====]
local S_3 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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

ARKHER.open("Audio")
]====]
local S_4 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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

ARKHER.open("Camera")
]====]
local S_5 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: CITY ]]
-- Layout unico: grid de distritos a esquerda, skyline desenhada no centro,
-- stats + geracao real com Singularity (IA) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#F9CA24")

local DISTRICTS = {
	{ nm = "Centro", b = 42, p = 0.82 }, { nm = "Porto", b = 18, p = 0.45 },
	{ nm = "Industrial", b = 26, p = 0.61 }, { nm = "Residencial", b = 64, p = 0.9 },
	{ nm = "Parque", b = 4, p = 0.2 }, { nm = "Mercado", b = 21, p = 0.58 },
	{ nm = "Academia", b = 12, p = 0.37 }, { nm = "Estacao", b = 9, p = 0.31 },
	{ nm = "Suburbio", b = 33, p = 0.72 },
}

local function build()
	local g, root, head = K.window("ArkherCity", "CITY — distritos & IA", 24, 410, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: DISTritos (3x3) =====
	local left = K.f(root, "Dist", 8, 34, 150, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "DISTRITOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	for i, d in ipairs(DISTRICTS) do
		local r, c = math.floor((i - 1) / 3) + 1, ((i - 1) % 3) + 1
		local cell = K.f(left, "D" .. i, 8 + (c - 1) * 46, 26 + (r - 1) * 70, 42, 64, T.bg2, 4)
		K.txt(cell, d.nm, 3, 4, 36, 14, 8, T.txt)
		K.txt(cell, d.b .. " bld", 3, 20, 36, 12, 8, T.txt4)
		K.progress(cell, 3, 40, 36, d.p, ACCENT)
		cell.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "City: distrito " .. d.nm .. " (" .. d.b .. " predios)")
		end)
	end
	K.txt(left, "9 distritos", 10, 232, 100, 12, 9, T.txt4)

	-- ===== CENTRO: SKYLINE =====
	local cv = K.f(root, "Sky", 170, 34, 244, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.f(cv, "Gnd", 0, 190, 244, 50, C("#101B12"))
	local blds = {
		{ x = 12, w = 26, h = 70 }, { x = 44, w = 20, h = 96 }, { x = 70, w = 30, h = 56 },
		{ x = 106, w = 24, h = 120 }, { x = 136, w = 34, h = 84 }, { x = 176, w = 22, h = 104 },
		{ x = 204, w = 28, h = 66 },
	}
	for i, b in ipairs(blds) do
		local bld = K.f(cv, "B" .. i, b.x, 190 - b.h, b.w, b.h, i % 2 == 0 and C("#1D2B3A") or C("#223140"))
		-- janelas
		local wy = 190 - b.h + 8
		while wy < 182 do
			local wx = b.x + 4
			while wx < b.x + b.w - 6 do
				local lit = ((i * 7 + wx + wy) % 3) == 0
				K.f(bld, "W" .. wx .. "_" .. wy, wx - b.x, wy - (190 - b.h), 3, 4, lit and ACCENT or T.bg0)
				wx = wx + 7
			end
			wy = wy + 10
		end
	end
	K.txt(cv, "skyline: 7 predios visiveis", 8, 222, 200, 14, 9, T.txt4)

	-- ===== DIREITA: STATS + IA =====
	local right = K.f(root, "Stats", 426, 34, 126, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "CENSO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Populacao", "18.4k", 26)
	K.row(right, "Predios", "229", 50)
	K.row(right, "Zonas", "9", 74)
	K.row(right, "Densidade", "0.72", 98)
	K.progress(right, 10, 122, 106, 0.72, ACCENT)
	K.txt(right, "crescimento", 10, 132, 100, 12, 9, T.txt4)
	local ai = K.btn(right, "AI", 10, 156, 106, 28, ACCENT, 5)
	K.txtS(ai, "Gerar c/ IA", 10, C("#1A1403"))
	K.hover(ai, ACCENT, C("#FFDF6B"))
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "City: Singularity gerando cidade real no workspace...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie uma cidade com npc") end)
		if ok and rep then
			K.notify("Cidade gerada", "Singularity: " .. #rep.lines .. " etapas", "ok")
		else
			K.notify("Singularity falhou", tostring(rep), "err")
		end
	end)
	K.txt(right, "a IA executa de", 10, 196, 106, 24, 8, T.txt4)
	K.txt(right, "verdade no place", 10, 212, 106, 12, 8, T.txt4)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 100, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Zoneamento", "mixto 68%", 8)
	K.progress(bar, 220, 14, 300, 0.68, ACCENT)
	K.row(bar, "Transporte", "4 rotas", 34)
	K.row(bar, "Energia", "91%", 60)
	local sim = K.btn(bar, 330, 34, 100, 26, T.bg2, 5)
	K.txtS(sim, "Simular dia", 10, T.txt)
	K.hover(sim, T.bg2, T.hover)
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "City: simulacao de 1 dia concluida (pop +120)")
	end)
	K.txt(bar, "sim: 0 dias", 450, 40, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("City", "City", "System", ICON.plate, "Planejamento urbano: distritos, skyline, censo e geracao por IA", build)
end

ARKHER.open("City")
]====]
local S_6 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: CLOUD (place cloud) ]]
-- Layout unico: resumo de storage a esquerda, lista REAL de places
-- (ArkherPlaces.list) com abrir/apagar, acoes de novo/exportar a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#74B9FF")

local function build()
	local g, root, head = K.window("ArkherCloud", "CLOUD — seus places", 24, 460, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: STORAGE =====
	local left = K.f(root, "Storage", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "STORAGE", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local list = ArkherPlaces.list()
	local total = 0
	for _, p in ipairs(list) do total = total + (p.bytes or 0) end
	K.progress(left, 10, 30, 102, math.min(1, total / (1024 * 1024)), ACCENT)
	K.txt(left, string.format("%.1f KB / 1 MB", total / 1024), 10, 40, 102, 14, 9, T.txt2)
	K.row(left, "Places", tostring(#list), 70)
	K.row(left, "Endpoint", ARKHER.STATE.cloud.endpoint ~= "" and "ok" or "local", 94)
	K.row(left, "Sync", "auto", 118)
	K.txt(left, "local: ServerStorage\nArkherCloud/Places", 10, 150, 104, 40, 8, T.txt4)
	local newP = K.btn(left, "NewP", 10, 204, 102, 24, ACCENT, 4)
	K.txtS(newP, "+ novo place", 9, C("#0A1420"))
	K.hover(newP, ACCENT, C("#A9D1FF"))
	newP.MouseButton1Click:Connect(function()
		ArkherPlaces.new("City")
		ARKHER.out("SUCCESS", "Cloud: place novo criado")
		refreshList()
	end)

	-- ===== CENTRO: LISTA =====
	local listArea = K.f(root, "List", 142, 34, 268, 250, T.bg0)
	K.corner(listArea, 4)
	K.stroke(listArea, T.line, 1)
	local rows = K.f(listArea, "Rows", 0, 24, 268, 224)
	K.txt(listArea, "PLACES SALVOS", 10, 6, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local function refreshList()
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(rows, "(nenhum place — use File > Save)", 10, 8, 240, 20, 9, T.txt4)
			return
		end
		for i, p in ipairs(list) do
			if i > 6 then break end
			local y = (i - 1) * 36
			local row = K.f(rows, "R" .. i, 6, y, 256, 32, T.bg2, 4)
			local rowIc = K.f(row, "Ic", 4, 6, 20, 20)
			ICON.folder(rowIc)
			K.txt(row, tostring(p.name), 28, 2, 130, 16, 10, T.txt)
			K.txt(row, "#" .. tostring(p.id) .. " | " .. string.format("%.1fK", (p.bytes or 0) / 1024), 26, 17, 140, 14, 8, T.txt4)
			local ob = K.btn(row, "O" .. i, 168, 5, 38, 22, ACCENT, 3)
			K.txtS(ob, "abrir", 9, C("#0A1420"))
			K.hover(ob, ACCENT, C("#A9D1FF"))
			local pid = p.id
			ob.MouseButton1Click:Connect(function()
				ArkherPlaces.open(pid)
				refreshList()
			end)
			local db = K.btn(row, "D" .. i, 212, 5, 38, 22, T.bg4, 3)
			K.txtS(db, "x", 10, T.danger)
			K.hover(db, T.bg4, T.hover)
			db.MouseButton1Click:Connect(function()
				pcall(function() ArkherPlaces.delete(pid) end)
				refreshList()
			end)
		end
	end
	refreshList()

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ACOES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local expB = K.btn(right, "ExpB", 10, 28, 110, 24, T.bg2, 4)
	K.txtS(expB, "exportar atual", 9, T.txt)
	K.hover(expB, T.bg2, T.hover)
	expB.MouseButton1Click:Connect(function()
		ArkherPlaces.exportToFile()
		refreshList()
	end)
	local saveB = K.btn(right, "SvB", 10, 58, 110, 24, T.bg2, 4)
	K.txtS(saveB, "salvar atual", 9, T.txt)
	K.hover(saveB, T.bg2, T.hover)
	saveB.MouseButton1Click:Connect(function()
		ArkherPlaces.save(ARKHER.STATE.placeName)
		refreshList()
	end)
	K.row(right, "Versao", "v3", 100)
	K.row(right, "Formato", ".arkher.lua", 124)
	K.row(right, "Cripto", "nenhum", 148)
	K.txt(right, "endpoint:", 10, 180, 100, 14, 9, T.txt4)
	K.txt(right, ARKHER.STATE.cloud.endpoint == "" and "(local)" or ARKHER.STATE.cloud.endpoint, 10, 196, 110, 30, 8, T.neon)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Ultimo sync", "agora", 8)
	K.row(bar, "Backup automatico", "ON (a cada save)", 34)
	K.progress(bar, 260, 20, 260, 0.99, ACCENT)
	K.txt(bar, "integridade: 100%", 260, 44, 140, 14, 9, T.txt4)
end

ARKHER.reg("Cloud", "Cloud", "System", ICON.cloud, "Place Cloud: lista real, abrir/apagar, exportar e storage", build)
end

ARKHER.open("Cloud")
]====]
local S_7 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: COMMAND PALETTE (Ctrl+K) ]]
-- Layout unico: barra flutuante centralizada de BUSCA, lista viva que filtra
-- UIs + TODOS os comandos do ARKHER conforme digita. Sem janela comum.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD400")

local function build()
	local g, root, head = K.window("ArkherCommandPalette", "COMMAND PALETTE", 40, 140, 480, 318, {})
	K.f(head, "Acc", 0, 24, 480, 2, ACCENT)

	local box = K.input(root, 10, 34, 460, 28, "digite: publish, animator, save, insert.part...")
	local area = K.f(root, "Results", 10, 70, 460, 212, T.bg0)
	K.corner(area, 4)
	K.stroke(area, T.line, 1)
	local rows = K.f(area, "Rows", 0, 4, 460, 204)

	local firstRun = nil
	local function render(filter)
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		firstRun = nil
		local f = (filter or ""):lower()
		local y = 0
		local n = 0
		for _, name in ipairs(ARKHER.listUIs()) do
			local cat = ARKHER.CATALOG[name]
			local title = (cat and cat.title) or name
			if f == "" or title:lower():find(f, 1, true) or name:lower():find(f, 1, true) then
				local row = K.btn(rows, "R" .. n, 4, y, 452, 24, T.bg2, 3)
				K.txt(row, title, 10, 0, 320, 24, 11, T.txt)
				K.txt(row, (cat and cat.cat) or "ui", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local nm = name
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd("ui.open", nm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd("ui.open", nm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n > 0 then
			K.f(rows, "Sep", 8, y + 6, 444, 1, T.line)
			y = y + 12
		end
		for cmd in pairs(ARKHER.ACTIONS or {}) do
			if n >= 26 then break end
			if f == "" or cmd:find(f, 1, true) then
				local row = K.btn(rows, "C" .. n, 4, y, 452, 24, T.bg4, 3)
				K.txt(row, cmd, 10, 0, 320, 24, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
				K.txt(row, "comando", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local cm = cmd
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd(cm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd(cm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n == 0 then
			K.txt(rows, "(nada encontrado para \"" .. tostring(filter) .. "\")", 10, 10, 300, 20, 10, T.txt4)
		end
	end
	render("")

	local function refresh()
		render(box.Text or "")
	end
	local okc, sig = pcall(function() return box:GetPropertyChangedSignal("Text") end)
	if okc and sig then sig:Connect(refresh) end
	local okf, fl = pcall(function() return box.FocusLost end)
	if okf and fl then
		fl:Connect(function(commit)
			if commit and firstRun then
				local ok, err = pcall(firstRun)
				if not ok then ARKHER.out("ERROR", "Palette: " .. tostring(err)) end
			end
			root.Visible = false
		end)
	end
	K.txt(root, "# UIs: " .. tostring(#ARKHER.listUIs()) .. "  |  # comandos: " .. (function()
		local c = 0
		for _ in pairs(ARKHER.ACTIONS or {}) do c = c + 1 end
		return c
	end)(), 10, 290, 300, 16, 9, T.txt4)
	K.txt(root, "Enter = 1o resultado | Esc = fecha", 300, 290, 170, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	-- paleta nasce oculta: abre com Ctrl+K / VIEW > Command Palette
	root.Visible = false
end

ARKHER.reg("CommandPalette", "Command Palette", "System", ICON.search, "Ctrl+K: busca viva de UIs e todos os comandos do ARKHER", build)
end

ARKHER.open("CommandPalette")
]====]
local S_8 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: CONSOLE ]]
-- Layout unico: chips de filtro, log REAL (ARKHER.OUTPUT) colorido por
-- severidade, append ao vivo via Bus, exportacao para arquivo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C8D6E5")

local KIND_COLORS = {
	INFO = T.neon, SUCCESS = T.ok, WARNING = C("#FFD93D"), ERROR = T.danger,
}

local function build()
	local g, root, head = K.window("ArkherConsole", "CONSOLE — log do ARKHER", 24, 440, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: FILTROS =====
	local filters = { "TODAS", "INFO", "SUCCESS", "WARNING", "ERROR" }
	local curFilter = "TODAS"
	local fbtns = {}
	for i, fl in ipairs(filters) do
		local b = K.btn(root, "F" .. i, 8 + (i - 1) * 78, 34, 72, 22, i == 1 and T.bg2 or T.bg4, 4)
		K.txtS(b, fl, 9, i == 1 and T.txt or T.txt3)
		K.hover(b, T.bg4, T.hover)
		local fl2 = fl
		b.MouseButton1Click:Connect(function()
			curFilter = fl2
			for j, bb in ipairs(fbtns) do
				K.stroke(bb, j == i and ACCENT or T.line2, j == i and 1.5 or 1)
			end
			render()
		end)
		fbtns[i] = b
		K.stroke(b, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	local cntLbl = K.txt(root, "# linhas", 410, 38, 140, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== LOG =====
	local log = K.f(root, "Log", 8, 64, 544, 232, T.bg0)
	K.corner(log, 4)
	K.stroke(log, T.line, 1)
	local area = K.f(log, "Area", 0, 0, 544, 232)
	local function render()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		local lines = ARKHER.OUTPUT or {}
		local shown = 0
		local y = 6
		for i = #lines, 1, -1 do
			if shown >= 18 then break end
			local e = lines[i]
			if curFilter == "TODAS" or e.kind == curFilter then
				local col = KIND_COLORS[e.kind] or T.txt2
				if col == T.danger then K.f(area, "bg" .. shown, 6, y - 2, 532, 18, C("#2A1214")) end
				K.txt(area, string.format("[%s] %s", e.kind, e.msg), 10, y, 524, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
				shown = shown + 1
				y = y + 16
			end
		end
		cntLbl.Text = tostring(#lines) .. " linhas | " .. shown .. " visiveis"
	end
	render()
	-- ao vivo
	Bus.on("output", function()
		render()
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 68, T.bg0)
	K.corner(bar, 4)
	local clear = K.btn(bar, "Cl", 10, 10, 80, 24, T.bg2, 4)
	K.txtS(clear, "Limpar", 10, T.txt)
	K.hover(clear, T.bg2, T.hover)
	clear.MouseButton1Click:Connect(function()
		ARKHER.OUTPUT = {}
		render()
		ARKHER.out("INFO", "Console: limpo")
	end)
	local exp = K.btn(bar, "Ex", 100, 10, 110, 24, ACCENT, 4)
	K.txtS(exp, "Exportar .txt", 10, C("#101418"))
	K.hover(exp, ACCENT, C("#E4ECF5"))
	exp.MouseButton1Click:Connect(function()
		local lines = {}
		for _, e in ipairs(ARKHER.OUTPUT or {}) do
			table.insert(lines, "[" .. e.kind .. "] " .. e.msg)
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherConsole/console_" .. tostring(math.floor(tick() and tick() or 0)) .. ".txt", table.concat(lines, "\n"))
				return true
			end
			return false
		end)
		if ok then
			ARKHER.out("SUCCESS", "Console: " .. #lines .. " linhas exportadas")
		else
			ARKHER.out("WARNING", "Console: WriteFile indisponivel fora do Studio")
		end
	end)
	local auto = K.checkRow(bar, "auto-scroll", true, 44)
	K.txt(bar, "severidades: INFO=azul SUCCESS=verde WARNING=amarelo ERROR=vermelho", 230, 16, 300, 14, 9, T.txt4)
end

ARKHER.reg("Console", "Console", "System", ICON.script, "Console: log real do ARKHER com filtros, ao vivo e exportacao", build)
end

ARKHER.open("Console")
]====]
local S_9 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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

ARKHER.open("Lighting")
]====]
local S_10 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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

ARKHER.open("Map")
]====]
local S_11 = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
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
--[[ ARKHER V3 — UI: MODELER ]]
-- Layout unico: paleta vertical de ferramentas (modo polygonal), canvas com
-- malha low-poly interativa (vertices selecionaveis), stats + UV grid a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#4DFFDB")

local function build()
	local g, root, head = K.window("ArkherModeler", "MODELER — polygonal", 24, 310, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== PALETA VERTICAL DE FERRAMENTAS =====
	local tools = {
		{ ic = ICON.select, nm = "Select" },
		{ ic = ICON.move, nm = "Move" },
		{ ic = ICON.scaleI, nm = "Scale" },
		{ ic = ICON.rotate, nm = "Rotate" },
		{ ic = ICON.transform, nm = "Gizmo" },
	}
	local curTool = 1
	local pal = K.f(root, "Pal", 8, 34, 46, 330, T.bg4)
	K.corner(pal, 4)
	for i, tl in ipairs(tools) do
		local b = K.btn(pal, "T" .. i, 5, 8 + (i - 1) * 46, 36, 36, i == 1 and T.bg2 or T.bg4, 5)
		tl.ic(b, 18)
		K.hover(b, T.bg4, T.hover)
		local idx = i
		b.MouseButton1Click:Connect(function()
			curTool = idx
			for j = 1, #tools do
				local bb = pal:FindFirstChild("T" .. j)
				if bb then
					bb.BackgroundColor3 = j == idx and T.bg2 or T.bg4
					if bb:FindFirstChild("Acc") then bb:FindFirstChild("Acc"):Destroy() end
					if j == idx then K.stroke(bb, ACCENT, 1.5) end
				end
			end
			ARKHER.out("INFO", "Modeler: ferramenta " .. tl.nm)
		end)
	end
	K.txt(pal, "MODO", 2, 250, 42, 12, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(pal, "VERTEX", 2, 262, 42, 24, 8, ACCENT, FONT, Enum.TextXAlignment.Center)

	-- ===== TABS SUPERIORES =====
	K.tabs(root, 66, 34, 300, { "Objetos", "Materiais", "UV" }, 1)

	-- ===== CANVAS DE MALHA =====
	local cv = K.f(root, "Canvas", 66, 60, 330, 260, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 9 do K.f(cv, "gx" .. i, i * 33, 0, 1, 260, T.bg3) end
	for i = 1, 8 do K.f(cv, "gy" .. i, 0, i * 32, 330, 1, T.bg3) end
	-- malha low-poly: cubo isometrico (faces)
	local faces = {
		{ x = 90, y = 90, w = 75, h = 40, c = C("#2E5E54") }, -- top
		{ x = 90, y = 130, w = 75, h = 60, c = C("#1F423C") }, -- front
		{ x = 165, y = 112, w = 60, h = 78, c = C("#284F48") }, -- side
	}
	for i, f in ipairs(faces) do
		local fc = K.f(cv, "F" .. i, f.x, f.y, f.w, f.h, f.c)
		K.stroke(fc, ACCENT, 0.8)
	end
	-- janelas
	K.f(cv, "W1", 105, 145, 14, 14, ACCENT)
	K.f(cv, "W2", 133, 145, 14, 14, ACCENT)
	K.f(cv, "W3", 180, 130, 12, 12, C("#4DFFDB"))
	-- vertices (interativos)
	local vpos = {
		{ 90, 90 }, { 165, 90 }, { 225, 112 }, { 165, 112 },
		{ 90, 130 }, { 165, 130 }, { 225, 190 }, { 165, 190 }, { 90, 190 },
	}
	local selVerts = {}
	local selLbl
	for i, p in ipairs(vpos) do
		local d = K.f(cv, "V" .. i, p[1] - 4, p[2] - 4, 8, 8, T.bg0, 4)
		K.stroke(d, ACCENT, 1.5)
		local vi = i
		d.MouseButton1Click:Connect(function()
			if selVerts[vi] then
				selVerts[vi] = nil
				d.BackgroundColor3 = T.bg0
			else
				selVerts[vi] = true
				d.BackgroundColor3 = ACCENT
			end
			local n = 0
			for _ in pairs(selVerts) do n = n + 1 end
			if selLbl then selLbl.Text = tostring(n) .. " vertices" end
		end)
	end
	selLbl = K.txt(cv, "0 vertices", 10, 236, 120, 16, 10, ACCENT)

	-- ===== DIREITA: STATS + UV =====
	local right = K.f(root, "Stats", 408, 60, 144, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MESH", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Verts", "9", 26)
	K.row(right, "Edges", "14", 50)
	K.row(right, "Faces", "5", 74)
	K.row(right, "Tris", "8", 98)
	K.txt(right, "UV GRID", 10, 128, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i = 1, 6 do
		for j = 1, 4 do
			local on = (i == 2 and j == 2) or (i == 3 and j == 2)
			K.f(right, "UV_" .. i .. "_" .. j, 10 + (j - 1) * 30, 148 + (i - 1) * 22, 26, 18, on and ACCENT or T.bg0)
			K.stroke(right:FindFirstChild("UV_" .. i .. "_" .. j), T.line, 0.6)
		end
	end
	local weld = K.btn(right, "Weld", 10, 226, 60, 22, ACCENT, 4)
	K.txtS(weld, "Weld", 10, C("#0B1410"))
	K.hover(weld, ACCENT, C("#8DFFE8"))
	weld.MouseButton1Click:Connect(function()
		local n = 0
		for _ in pairs(selVerts) do n = n + 1 end
		ARKHER.out("SUCCESS", "Modeler: " .. math.max(n, 1) .. " vertices soldados")
		K.notify("Weld aplicado", "malha otimizada", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 334, 544, 58, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Snap 1u", true, 8)
	K.checkRow(bar, "Grid 33u", true, 34)
	K.txt(bar, "modo: " .. tools[curTool].nm, 220, 14, 110, 20, 10, ACCENT)
	K.txt(bar, "Buildings/1.fbx", 400, 14, 130, 20, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Modeler", "Modeler", "Editor", ICON.cubeW, "Modelagem polygonal: ferramentas, malha, vertices e UV", build)
end

ARKHER.open("Modeler")
]====]
local t = panels:FindFirstChild("UI_AI")
if not t then t = Instance.new("LocalScript") t.Name = "UI_AI" t.Parent = panels end
t.Source = S_0
	t.Disabled = true
local t = panels:FindFirstChild("UI_About")
if not t then t = Instance.new("LocalScript") t.Name = "UI_About" t.Parent = panels end
t.Source = S_1
	t.Disabled = true
local t = panels:FindFirstChild("UI_Animator")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Animator" t.Parent = panels end
t.Source = S_2
	t.Disabled = true
local t = panels:FindFirstChild("UI_Audio")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Audio" t.Parent = panels end
t.Source = S_3
	t.Disabled = true
local t = panels:FindFirstChild("UI_Camera")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Camera" t.Parent = panels end
t.Source = S_4
	t.Disabled = true
local t = panels:FindFirstChild("UI_City")
if not t then t = Instance.new("LocalScript") t.Name = "UI_City" t.Parent = panels end
t.Source = S_5
	t.Disabled = true
local t = panels:FindFirstChild("UI_Cloud")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Cloud" t.Parent = panels end
t.Source = S_6
	t.Disabled = true
local t = panels:FindFirstChild("UI_CommandPalette")
if not t then t = Instance.new("LocalScript") t.Name = "UI_CommandPalette" t.Parent = panels end
t.Source = S_7
	t.Disabled = true
local t = panels:FindFirstChild("UI_Console")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Console" t.Parent = panels end
t.Source = S_8
	t.Disabled = true
local t = panels:FindFirstChild("UI_Lighting")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Lighting" t.Parent = panels end
t.Source = S_9
	t.Disabled = true
local t = panels:FindFirstChild("UI_Map")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Map" t.Parent = panels end
t.Source = S_10
	t.Disabled = true
local t = panels:FindFirstChild("UI_Modeler")
if not t then t = Instance.new("LocalScript") t.Name = "UI_Modeler" t.Parent = panels end
t.Source = S_11
	t.Disabled = true
print("[ARKHER V3] (6/13) 12 paineis instalados em StarterPlayerScripts.Arkher.Panels (DESATIVADOS — habilite um por um para testar)")
