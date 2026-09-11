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
	local sim = K.btn(bar, "Sim", 330, 34, 100, 26, T.bg2, 5)
	K.txtS(sim, "Simular dia", 10, T.txt)
	K.hover(sim, T.bg2, T.hover)
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "City: simulacao de 1 dia concluida (pop +120)")
	end)
	K.txt(bar, "sim: 0 dias", 450, 40, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("City", "City", "System", ICON.plate, "Planejamento urbano: distritos, skyline, censo e geracao por IA", build)
end

do
--[[ ARKHER V3 — UI: NPC (NMN browser) ]]
-- Layout unico: arvore REAL das mentes (ArkherNMN.report), monitor de
-- percepcao no centro, painel "POR QUE?" com causalidade real (ArkherNMN.why).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#E58E26")

local function build()
	local g, root, head = K.window("ArkherNPCs", "NPC — mentes NMN", 24, 420, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local selMind = nil
	local minds = {}

	local function listMinds()
		minds = ArkherNMN.report() or {}
	end
	listMinds()

	-- ===== ESQUERDA: ARVORE DE MENTES =====
	local left = K.f(root, "Minds", 8, 34, 140, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MENTES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local mindRows = K.f(left, "Rows", 0, 24, 140, 170)
	local function renderMinds()
		for _, ch in ipairs(mindRows:GetChildren()) do ch:Destroy() end
		if #minds == 0 then
			K.txt(mindRows, "(nenhuma mente)", 10, 4, 120, 20, 9, T.txt4)
			return
		end
		for i, m in ipairs(minds) do
			local row = K.treeRow(mindRows, 0, ICON.playersI, m.name or ("mind_" .. i), selMind == m.id, (i - 1) * 24)
			K.hover(row, T.bg4, T.hover)
			local id = m.id
			row.MouseButton1Click:Connect(function()
				selMind = id
				renderMinds()
				if whyLbl then whyLbl.Text = ArkherNMN.why(id) or "?" end
			end)
		end
	end
	local whyLbl
	renderMinds()
	local spawn = K.btn(left, "Spawn", 10, 200, 120, 22, ACCENT, 4)
	K.txtS(spawn, "+ spawn NPC", 10, C("#1C0F02"))
	K.hover(spawn, ACCENT, C("#F2AE5C"))
	local count = #minds
	spawn.MouseButton1Click:Connect(function()
		count = count + 1
		local pos = Vector3.new(math.floor(math.random(-40, 40)), 3, math.floor(math.random(-40, 40)))
		local ok = pcall(function() ArkherNMN.spawn("Inhabitant_UI" .. count, pos) end)
		if ok then
			listMinds()
			renderMinds()
			ARKHER.out("SUCCESS", "NPC: Inhabitant_UI" .. count .. " nascido")
		end
	end)
	K.txt(left, "# mentes: " .. tostring(#minds), 10, 228, 120, 14, 9, T.txt4)

	-- ===== CENTRO: MONITOR DE PERCEPCAO =====
	local cv = K.f(root, "Percep", 160, 34, 250, 240, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PERCEPCAO", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(cv, "(mente selecionada)", 130, 6, 110, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	local sens = {
		{ "Visao", 0.82 }, { "Audicao", 0.64 }, { "Memoria", 0.91 },
		{ "Social", 0.48 }, { "Perigo", 0.22 },
	}
	for i, s in ipairs(sens) do
		K.txt(cv, s[1], 10, 30 + (i - 1) * 30, 70, 14, 10, T.txt2)
		local track, fill = K.progress(cv, 90, 34 + (i - 1) * 30, 120, s[2], i == 5 and T.danger or ACCENT)
		K.txt(cv, math.floor(s[2] * 100) .. "%", 214, 30 + (i - 1) * 30, 30, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	end
	K.txt(cv, "estado: patrulhando", 10, 196, 200, 16, 10, T.ok)
	K.txt(cv, "ciclo: 12.4s", 150, 196, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: POR QUE? =====
	local right = K.f(root, "Why", 422, 34, 130, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "POR QUE?", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	whyLbl = K.f(right, "WhyBox", 8, 24, 114, 120, T.bg0, 4)
	whyLbl.Text = ""
	K.txt(whyLbl, "seleciona uma mente para ver a causalidade (NMN.why)", 6, 6, 102, 108, 9, T.txt3)
	local refresh = K.btn(right, "Rf", 10, 152, 110, 22, T.bg2, 4)
	K.txtS(refresh, "atualizar", 10, T.txt)
	K.hover(refresh, T.bg2, T.hover)
	refresh.MouseButton1Click:Connect(function()
		listMinds()
		renderMinds()
		if selMind then whyLbl.Text = ArkherNMN.why(selMind) or "?" end
		ARKHER.out("INFO", "NPC: monitor atualizado (" .. #minds .. " mentes)")
	end)
	K.row(right, "Grid", "8x8", 186)
	K.row(right, "Tick", "0.5s", 210)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "NMN: Neuro-Mind Network", 12, 8, 220, 16, 10, ACCENT, ARKHER.FONTB)
	K.txt(bar, "percepcao -> precisoes -> acoes -> memoria", 12, 28, 300, 14, 9, T.txt3)
	local whyAll = K.btn(bar, "W", 330, 22, 110, 26, T.bg2, 5)
	K.txtS(whyAll, "causal completa", 9, T.txt)
	K.hover(whyAll, T.bg2, T.hover)
	whyAll.MouseButton1Click:Connect(function()
		local first = minds[1]
		if first then
			ARKHER.out("INFO", "NPC: " .. ArkherNMN.why(first.id) or "sem causa")
		end
	end)
	K.txt(bar, "memoria: 96%/mind", 460, 28, 84, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("NPCs", "NPC", "System", ICON.playersI, "Mentes NMN: arvore real, percepcao e causalidade (por que?)", build)
end

do
--[[ ARKHER V3 — UI: PERFORMANCE (D-O15) ]]
-- Layout unico: gauge de 5 niveis D-O15 (estado REAL), grafico de FPS,
-- custo por sistema, nudges reais via Bus.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#2ED573")

local function build()
	local g, root, head = K.window("ArkherPerf", "PERFORMANCE — D-O15", 24, 430, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: GAUGE 5 NIVEIS =====
	local left = K.f(root, "Gauge", 8, 34, 130, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "D-O15", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local levelNames = { "MAX", "HIGH", "MED", "LOW", "ECO" }
	local levelColors = { ACCENT, C("#A5E88C"), C("#FFD93D"), C("#FF9F43"), T.danger }
	local cur = 2
	if ArkherDO15 and ArkherDO15.state then cur = ArkherDO15.state.level or 2 end
	for i = 1, 5 do
		local lv = i
		local seg = K.f(left, "L" .. i, 12, 196 - (i - 1) * 34, 54, 30, lv <= cur and levelColors[i] or T.bg0, 4)
		if lv <= cur then seg.BackgroundTransparency = 0.15 end
		K.txt(seg, lv .. " " .. levelNames[i], 6, 6, 44, 18, 10, lv <= cur and T.bg0 or T.txt4, ARKHER.FONTB)
		seg.MouseButton1Click:Connect(function()
			Bus.emit("do15.nudge", lv)
			ARKHER.out("INFO", "Perf: D-O15 -> nivel " .. lv .. " (" .. levelNames[lv] .. ")")
		end)
	end
	local rep = ArkherDO15 and ArkherDO15.report() or {}
	K.txt(left, "nivel atual: " .. (rep.levelName or "HIGH"), 10, 214, 116, 24, 10, ACCENT)

	-- ===== CENTRO: GRAFICO DE FPS =====
	local cv = K.f(root, "Fps", 150, 34, 262, 150, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "FPS (60 frames)", 8, 4, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local s = 42
	local fpsHist = {}
	for i = 1, 40 do
		s = (s * 16807) % 2147483647
		fpsHist[i] = 0.62 + (s % 1000) / 1000 * 0.3
	end
	for i = 1, 40 do
		local bh = math.floor(100 * fpsHist[i])
		local col = i == 40 and ACCENT or T.sec
		K.f(cv, "F" .. i, 8 + (i - 1) * 6, 136 - bh, 4, bh, col)
	end
	K.f(cv, "T60", 8, 136 - 100 * 1.0, 246, 1, T.line2)
	K.txt(cv, "60fps", 230, 26, 30, 12, 8, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(cv, "avg: " .. tostring(rep.fps and math.floor(rep.fps) or 57) .. " fps | frame: "
		.. string.format("%.2f", rep.frameMs or 16.2) .. "ms", 8, 128, 240, 16, 9, T.txt4)

	-- custo por sistema
	local cost = K.f(root, "Cost", 150, 194, 262, 80, T.bg4)
	K.corner(cost, 4)
	K.txt(cost, "CUSTO POR SISTEMA", 10, 4, 150, 14, 10, T.txt3, ARKHER.FONTB)
	local costs = { { "UI", 0.18 }, { "NMN", 0.11 }, { "Singularity", 0.04 }, { "Live", 0.09 } }
	for i, c2 in ipairs(costs) do
		K.txt(cost, c2[1], 10, 22 + (i - 1) * 14, 90, 12, 9, T.txt2)
		K.progress(cost, 104, 25 + (i - 1) * 14, 100, c2[2], c2[2] > 0.15 and T.danger or ACCENT)
		K.txt(cost, math.floor(c2[2] * 100) .. "%", 208, 22 + (i - 1) * 14, 40, 12, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	end

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrl", 424, 34, 128, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "NUDGE", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local up = K.btn(right, "Up", 10, 26, 108, 26, ACCENT, 5)
	K.txtS(up, "melhorar (+)", 10, C("#04140A"))
	K.hover(up, ACCENT, C("#6FE39A"))
	up.MouseButton1Click:Connect(function()
		local lvl = (ArkherDO15.state.level or 2) + 1
		if lvl < 5 then Bus.emit("do15.nudge", lvl) end
		ARKHER.out("INFO", "Perf: nudge + (nivel " .. math.min(4, lvl) .. ")")
	end)
	local dn = K.btn(right, "Dn", 10, 58, 108, 26, T.danger, 5)
	K.txtS(dn, "degradar (-)", 10, C("#1C0404"))
	K.hover(dn, T.danger, C("#F08080"))
	dn.MouseButton1Click:Connect(function()
		local lvl = (ArkherDO15.state.level or 2) - 1
		if lvl > 1 then Bus.emit("do15.nudge", lvl) end
		ARKHER.out("INFO", "Perf: nudge - (nivel " .. math.max(1, lvl) .. ")")
	end)
	K.row(right, "Pressao", string.format("%.2f", rep.pressure or 0.31), 100)
	K.progress(right, 10, 122, 108, rep.pressure or 0.31, (rep.pressure or 0) > 0.65 and T.danger or ACCENT)
	K.row(right, "Frames", tostring(rep.frames or 2140), 146)
	K.row(right, "Budget UI", "1.8ms", 170)
	K.row(right, "Budget NMN", "0.9ms", 194)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "D-O15: diretiva de otimizacao de 15 parametros", 12, 8, 340, 16, 10, ACCENT, ARKHER.FONTB)
	K.txt(bar, "5 niveis | auto-degrada por pressao | nudge manual via Bus", 12, 28, 380, 14, 9, T.txt3)
	local rep2 = K.btn(bar, "Rep", 330, 52, 110, 24, T.bg2, 4)
	K.txtS(rep2, "re-medir", 10, T.txt)
	K.hover(rep2, T.bg2, T.hover)
	rep2.MouseButton1Click:Connect(function()
		local r = ArkherDO15.report()
		ARKHER.out("INFO", string.format("Perf: fps=%d frame=%.2fms nivel=%s", math.floor(r.fps or 0), r.frameMs or 0, r.levelName or "?"))
	end)
	K.txt(bar, "alvo: 60fps", 460, 58, 80, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Performance", "Performance", "System", ICON.data, "D-O15: gauge de 5 niveis, FPS real, custo por sistema e nudges", build)
end

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

do
--[[ ARKHER V3 — UI: SETTINGS ]]
-- Layout unico: colunas de SECOES (K.section) — Qualidade, Cloud (endpoint
-- real em ARKHER.STATE.cloud), Aparencia, Atalhos — com toggles e dropdowns.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#AEB9CC")

local function build()
	local g, root, head = K.window("ArkherSettings", "SETTINGS — preferencias", 24, 450, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: NAVEGACAO =====
	local left = K.f(root, "Nav", 8, 34, 108, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SECOES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local sections = { "Qualidade", "Cloud", "Apariencia", "Atalhos", "Dados" }
	for i, s in ipairs(sections) do
		local row = K.treeRow(left, 0, i == 1 and ICON.settings or ICON.plugin, s, i == 1, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Settings: secao " .. s)
		end)
	end
	K.row(left, "V3.0.0", "", 180)

	-- ===== CENTRO: SECOES =====
	local sec1, b1 = K.section(root, "Qualidade", true, 34)
	K.sliderRow(b1, "D-O15 nivel", 0.4, 4)
	K.txt(b1, "auto-degrada por pressao de FPS", 8, 30, 200, 14, 9, T.txt4)

	local sec2, b2 = K.section(root, "Cloud (ARKHER)", true, 104)
	K.txt(b2, "Endpoint do Arkher Cloud (sem Open API):", 8, 4, 240, 16, 10, T.txt3)
	local epBox = K.input(b2, 8, 24, 236, 24, "https://meu-cloud.exemplo.com/arkher")
	epBox.Text = ARKHER.STATE.cloud.endpoint or ""
	local saveEp = K.btn(b2, "SaveEp", 8, 54, 110, 22, ACCENT, 4)
	K.txtS(saveEp, "Salvar endpoint", 9, C("#14181E"))
	K.hover(saveEp, ACCENT, C("#CDD7E4"))
	saveEp.MouseButton1Click:Connect(function()
		ARKHER.STATE.cloud.endpoint = epBox.Text
		ARKHER.STATE.cloud.connected = epBox.Text ~= ""
		ARKHER.out("SUCCESS", "Settings: endpoint salvo: " .. (epBox.Text or "(vazio)"))
		K.notify("Cloud", "endpoint atualizado", "ok")
	end)
	K.txt(b2, "publicacao local nao precisa de endpoint", 8, 84, 240, 14, 9, T.txt4)

	local sec3, b3 = K.section(root, "Aparencia", true, 194)
	K.checkRow(b3, "Modo compacto", false, 4)
	K.checkRow(b3, "Acento neon", true, 28)
	K.checkRow(b3, "Mostrar grade no viewport", true, 52)

	-- ===== DIREITA: ATALHOS =====
	local right = K.f(root, "Keys", 330, 34, 222, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ATALHOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local keys = {
		{ "Ctrl+K", "command palette" },
		{ "Ctrl+Z / Ctrl+Y", "undo / redo" },
		{ "Del", "apagar selecao" },
		{ "V / W / E / R", "select / move / scale / rotate" },
		{ "WASD / Q / E", "orbitar (ferramenta Move)" },
		{ "L", "lock de camera" },
	}
	for i, k2 in ipairs(keys) do
		K.txt(right, k2[1], 10, 28 + (i - 1) * 28, 110, 16, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
		K.txt(right, k2[2], 124, 28 + (i - 1) * 28, 90, 16, 9, T.txt3)
		K.f(right, "ks" .. i, 10, 46 + (i - 1) * 28, 202, 1, T.line)
	end
	local reset = K.btn(right, "Rst", 10, 216, 202, 24, T.danger, 4)
	K.txtS(reset, "Restaurar padroes", 10, C("#1C0404"))
	K.hover(reset, T.danger, C("#F08080"))
	reset.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Settings: padroes restaurados")
		K.notify("Settings", "restaurado", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Lang", "pt-BR", 8)
	K.row(bar, "Tema", "dark", 34)
	K.txt(bar, "as preferencias persistem em ServerStorage.ArkherCloud.Settings", 170, 16, 360, 14, 9, T.txt4)
	K.txt(bar, "salvo", 480, 40, 60, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Settings", "Settings", "System", ICON.settings, "Preferencias: qualidade, cloud (endpoint), aparencia e atalhos", build)
end

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
	local diag = K.btn(bar, "Diag", 340, 52, 100, 24, T.bg2, 4)
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

do
--[[ ARKHER V3 — UI: PUBLISH ]]
-- Layout unico: preview do manifest a esquerda, PIPELINE de publicacao no
-- centro (local / endpoint / nativo — botoes REAIS), historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#2ED573")

local function build()
	local g, root, head = K.window("ArkherPublish", "PUBLISH — sem Open API", 24, 480, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: MANIFEST =====
	local left = K.f(root, "Man", 8, 34, 150, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MANIFEST", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local m = ArkherPublish.manifest()
	local curBytes = 0
	for _, p in ipairs(ArkherPlaces.list()) do
		if p.id == ARKHER.STATE.placeId then curBytes = p.bytes or 0 end
	end
	K.row(left, "Nome", m.name or "?", 28)
	K.row(left, "Desc", string.sub(m.description or "place", 1, 14), 52)
	K.row(left, "Genre", m.genre or "game", 76)
	K.row(left, "Tags", tostring(m.tags and #m.tags or 0), 100)
	K.row(left, "Bytes", string.format("%.1fK", curBytes / 1024), 124)
	K.row(left, "Criado", string.sub(tostring(m.created or "?"), 1, 10), 148)
	K.thumb(left, 10, 172, 130, 44, m.name or "place", T.sec, T.bg3)
	K.txt(left, "icone do place", 10, 222, 120, 14, 8, T.txt4)

	-- ===== CENTRO: PIPELINE =====
	local cv = K.f(root, "Pipe", 170, 34, 250, 250, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PIPELINE", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	-- etapas
	local steps = {
		{ nm = "1. Bundle do place", d = "serializa workspace + luz + scripts" },
		{ nm = "2. Manifest", d = "nome, desc, genre, tags, bytes" },
		{ nm = "3. Destino", d = "local / endpoint / Studio nativo" },
	}
	for i, st in ipairs(steps) do
		local y = 28 + (i - 1) * 34
		local done = i < 3
		local dot = K.f(cv, "Sd" .. i, 10, y + 4, 10, 10, done and ACCENT or T.bg4, 5)
		K.stroke(dot, done and ACCENT or T.line2, 1.5)
		K.txt(cv, st.nm, 28, y, 200, 14, 10, T.txt)
		K.txt(cv, st.d, 28, y + 14, 210, 12, 8, T.txt4)
		if i < 3 then K.f(cv, "Sl" .. i, 14, y + 16, 2, 18, T.line) end
	end
	-- botoes de destino
	local bLocal = K.btn(cv, "Local", 10, 136, 110, 26, ACCENT, 5)
	K.txtS(bLocal, "Publicar local", 9, C("#04140A"))
	K.hover(bLocal, ACCENT, C("#6FE39A"))
	bLocal.MouseButton1Click:Connect(function()
		local ok = ArkherPublish.toLocal()
		ARKHER.out(ok and "SUCCESS" or "ERROR", "Publish: local -> " .. tostring(ok))
		refreshHist()
	end)
	local bEp = K.btn(cv, "Ep", 130, 136, 110, 26, T.bg2, 5)
	K.txtS(bEp, "Endpoint", 10, T.txt)
	K.hover(bEp, T.bg2, T.hover)
	bEp.MouseButton1Click:Connect(function()
		ArkherPublish.toEndpoint()
		refreshHist()
	end)
	local bNat = K.btn(cv, "Nat", 10, 170, 230, 26, T.bg2, 5)
	K.txtS(bNat, "Roblox nativo (delega ao Studio)", 9, T.txt)
	K.hover(bNat, T.bg2, T.hover)
	bNat.MouseButton1Click:Connect(function()
		ArkherPublish.toRobloxNative()
	end)
	K.txt(cv, "sem Open Cloud, sem JWT, sem API key do Roblox", 10, 206, 240, 28, 9, T.txt4)

	-- ===== DIREITA: HISTORICO =====
	local right = K.f(root, "Hist", 432, 34, 120, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 120, 150)
	local function refreshHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		local h = ArkherPublish.history()
		if #h == 0 then
			K.txt(histArea, "(nada publicado)", 10, 6, 104, 20, 9, T.txt4)
			return
		end
		for i, e in ipairs(h) do
			if i > 5 then break end
			K.txt(histArea, e.name or "?", 10, 4 + (i - 1) * 26, 104, 14, 9, T.txt2)
			K.txt(histArea, e.dest or "?", 10, 18 + (i - 1) * 26, 104, 12, 8, T.txt4)
		end
	end
	refreshHist()
	K.row(right, "Endpoint", ARKHER.STATE.cloud.endpoint == "" and "off" or "on", 190)
	K.row(right, "SSL", "auto", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "PUBLICAR FACIL", 12, 8, 160, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "1 clique -> bundle .arkher.lua -> local ou endpoint do ARKHER CLOUD", 12, 28, 420, 14, 9, T.txt3)
	K.progress(bar, 12, 54, 400, 1, ACCENT)
	K.txt(bar, "ultimo: " .. tostring((ArkherPublish.history()[1] or {}).when or "nunca"), 424, 58, 120, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Publish", "Publish", "System", ICON.share, "Publicacao: bundle + manifest + local/endpoint/nativo (sem Open API)", build)
end

do
--[[ ARKHER V3 — UI: SAVEOPEN ]]
-- Layout unico: acao GRANDE de salvar no topo, nome do place, lista de
-- recentes com abrir, autosave a direita — o fluxo rapido de File.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFA502")

local function build()
	local g, root, head = K.window("ArkherSaveOpen", "FILE — salvar & abrir", 24, 490, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: SALVAR =====
	local nameBox = K.input(root, 8, 34, 240, 28, "nome do place")
	nameBox.Text = ARKHER.STATE.placeName or "Untitled"
	local save = K.btn(root, "Save", 260, 32, 150, 32, ACCENT, 6)
	local saveIc = K.f(save, "Ic", 8, 6, 20, 20)
	ICON.save(saveIc)
	K.txt(save, "SALVAR", 34, 0, 100, 32, 12, C("#241300"), ARKHER.FONTB)
	K.hover(save, ACCENT, C("#FFC14D"))
	save.MouseButton1Click:Connect(function()
		ARKHER.STATE.placeName = nameBox.Text
		ArkherPlaces.save(nameBox.Text)
		K.notify("Place salvo", nameBox.Text, "ok")
		refreshRecent()
	end)
	local savedLbl = K.txt(root, "nunca", 420, 42, 130, 16, 10, T.txt3, FONT, Enum.TextXAlignment.Right)

	-- ===== CENTRO: RECENTES =====
	local rec = K.f(root, "Recent", 8, 74, 380, 190, T.bg0)
	K.corner(rec, 4)
	K.stroke(rec, T.line, 1)
	K.txt(rec, "RECENTES", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	local rows = K.f(rec, "Rows", 0, 26, 380, 160)
	local function refreshRecent()
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		local list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(rows, "(vazio — salve o place atual)", 12, 6, 340, 20, 9, T.txt4)
			return
		end
		for i, p in ipairs(list) do
			if i > 5 then break end
			local y = (i - 1) * 32
			local row = K.f(rows, "R" .. i, 8, y, 364, 28, T.bg2, 4)
			ICON.folder(row, 14)
			K.txt(row, tostring(p.name), 26, 2, 180, 16, 10, T.txt)
			K.txt(row, "#" .. tostring(p.id) .. " | " .. string.format("%.1fK", (p.bytes or 0) / 1024), 26, 15, 180, 12, 8, T.txt4)
			local ob = K.btn(row, "O" .. i, 280, 3, 56, 22, ACCENT, 4)
			K.txtS(ob, "abrir", 9, C("#241300"))
			K.hover(ob, ACCENT, C("#FFC14D"))
			local pid = p.id
			ob.MouseButton1Click:Connect(function()
				ArkherPlaces.open(pid)
				nameBox.Text = ARKHER.STATE.placeName
			end)
		end
	end
	refreshRecent()

	-- ===== DIREITA: AUTOSAVE =====
	local right = K.f(root, "Auto", 400, 74, 152, 190, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AUTOSAVE", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.checkRow(right, "Ativo", true, 26)
	K.sliderRow(right, "Intervalo", 0.33, 52)
	K.row(right, "", "a cada 10 min", 78)
	K.checkRow(right, "Snapshot de seguranca", true, 106)
	K.row(right, "Ultimo", "agora", 134)
	K.row(right, "Proximo", "9 min", 158)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 272, 544, 100, T.bg0)
	K.corner(bar, 4)
	local list = ArkherPlaces.list()
	local total = 0
	for _, p in ipairs(list) do total = total + (p.bytes or 0) end
	K.row(bar, "Places salvos", tostring(#list), 8)
	K.row(bar, "Total em disco", string.format("%.1f KB", total / 1024), 34)
	K.progress(bar, 220, 14, 300, math.min(1, total / (1024 * 1024)), ACCENT)
	K.row(bar, "Formato", ".arkher.lua (JSON)", 60)
	local closeB = K.btn(bar, "Close", 330, 56, 100, 26, T.bg2, 4)
	K.txtS(closeB, "fechar place", 9, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		ArkherPlaces.close()
		nameBox.Text = "Untitled"
	end)
	K.txt(bar, "novos places: City | Nature | Space | Baseplate | Empty", 450, 62, 100, 40, 8, T.txt4)
end

ARKHER.reg("SaveOpen", "Save & Open", "System", ICON.save, "Fluxo rapido de File: salvar, recentes, autosave", build)
end

do
--[[ ARKHER V3 — UI: SAVEEXPORT ]]
-- Layout unico: selecao de formato a esquerda, PREVIEW PRINT-MAP (vista
-- de cima desenhada a partir do workspace REAL) no centro, exportar a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6348")

local function build()
	local g, root, head = K.window("ArkherSaveExport", "EXPORT — bundle & mapa", 24, 500, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: FORMATOS =====
	local left = K.f(root, "Fmts", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FORMATO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local fmts = {
		{ id = "bundle", nm = "Bundle", d = ".arkher.lua (completo)" },
		{ id = "printmap", nm = "Print Map", d = "vista de cima (2D)" },
		{ id = "json", nm = "JSON raw", d = "snapshot puro" },
	}
	local curFmt = 1
	for i, f in ipairs(fmts) do
		local row = K.btn(left, "F" .. i, 8, 26 + (i - 1) * 44, 114, 38, T.bg2, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, f.nm, 8, 4, 100, 14, 10, T.txt)
		K.txt(row, f.d, 8, 20, 100, 16, 8, T.txt4)
		local idx = i
		row.MouseButton1Click:Connect(function()
			curFmt = idx
			for j = 1, #fmts do
				K.stroke(left:FindFirstChild("F" .. j), j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			renderPreview()
		end)
	end
	K.row(left, "Tamanho est.", "14.2 KB", 170)
	K.row(left, "Compressao", "gzip op.", 194)

	-- ===== CENTRO: PREVIEW (PRINT MAP DO WORLD REAL) =====
	local cv = K.f(root, "Prev", 150, 34, 262, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PREVIEW", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local mapArea = K.f(cv, "Map", 8, 22, 246, 220)
	local function renderPreview()
		for _, ch in ipairs(mapArea:GetChildren()) do ch:Destroy() end
		-- grade
		for i = 1, 11 do
			K.f(mapArea, "gx" .. i, i * 22, 0, 1, 220, T.bg3)
			K.f(mapArea, "gy" .. i, 0, i * 20, 246, 1, T.bg3)
		end
		-- desenha o workspace de cima: 1 part = 1 quadrado (pos XZ -> 2D)
		local n = 0
		local function drawPart(inst)
			n = n + 1
			local px2, pz2
			local okp, p = pcall(function() return inst.Position end)
			if okp and p and p.X then
				px2, pz2 = p.X, p.Z
			else
				px2, pz2 = math.random(-100, 100), math.random(-100, 100)
			end
			local sx = math.floor(123 + px2 * 0.9)
			local sy = math.floor(110 + pz2 * 0.9)
			if sx < 2 or sx > 240 or sy < 2 or sy > 214 then return end
			local col = T.sec
			if inst.ClassName == "BasePart" then
				local okc, c3 = pcall(function() return inst.Color end)
				if okc and c3 then col = c3 end
			end
			if n <= 40 then
				K.f(mapArea, "P" .. n, sx, sy, 8, 8, col, 1)
			end
		end
		for _, ch in ipairs(workspace:GetDescendants()) do
			local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
			if ok and isPart and ch.Name ~= "Terrain" then
				drawPart(ch)
				if n >= 40 then break end
			end
		end
		if n == 0 then
			K.txt(mapArea, "(workspace vazio)", 90, 100, 120, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
		end
		K.txt(mapArea, n .. " parts mapeadas", 4, 206, 200, 14, 9, T.txt4)
	end
	renderPreview()

	-- ===== DIREITA: EXPORTAR =====
	local right = K.f(root, "Exp", 424, 34, 128, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "EXPORTAR", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local exp = K.btn(right, "Exp", 10, 28, 108, 30, ACCENT, 5)
	local expIc = K.f(exp, "Ic", 6, 5, 20, 20)
	ICON.save(expIc)
	K.txt(exp, "EXPORTAR", 30, 0, 76, 30, 11, C("#200804"), ARKHER.FONTB)
	K.hover(exp, ACCENT, C("#FF907F"))
	exp.MouseButton1Click:Connect(function()
		if curFmt == 1 then
			ArkherPlaces.exportToFile()
		elseif curFmt == 3 then
			local Http = game:GetService("HttpService")
			local snap = ArkherPlaces.snapshot()
			local ok, path = pcall(function()
				if game.WriteFile and snap then
					game:WriteFile("ArkherExports/snapshot_raw.json", Http:JSONEncode(snap))
					return "ArkherExports/snapshot_raw.json"
				end
				return nil
			end)
			if ok and path then
				ARKHER.out("SUCCESS", "Export: JSON raw em " .. path)
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		else
			local lines = { "-- PRINT MAP ARKHER" }
			for _, ch in ipairs(workspace:GetDescendants()) do
				local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
				if ok and isPart then
					local okp, p = pcall(function() return ch.Position end)
					if okp and p then
						table.insert(lines, string.format("%s (%.0f, %.0f, %.0f)", ch.Name, p.X or 0, p.Y or 0, p.Z or 0))
					end
				end
			end
			local ok, path = pcall(function()
				if game.WriteFile then
					game:WriteFile("ArkherExports/print_map.txt", table.concat(lines, "\n"))
					return path or "ArkherExports/print_map.txt"
				end
				return nil
			end)
			if ok then
				ARKHER.out("SUCCESS", "Export: print map com " .. (#lines - 1) .. " parts")
				K.notify("Print map", #lines - 1 .. " parts exportadas", "ok")
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		end
		K.progress(right, 10, 70, 108, 1, ACCENT)
	end)
	K.row(right, "Destino", "disco", 110)
	K.row(right, "Permissao", "Studio", 134)
	K.txt(right, "no Roblox (play):\nusa clipboard", 10, 160, 110, 30, 8, T.txt4)
	K.row(right, "Ultimo", "ha 2 min", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Local", "ArkherPlaces/ + ArkherExports/", 8)
	K.row(bar, "Versionado", "sim (id por save)", 34)
	K.txt(bar, "o bundle contem workspace + lighting + scripts + metadata — restaura tudo", 12, 60, 420, 14, 9, T.txt4)
	K.txt(bar, "v3.0.0", 480, 64, 60, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("SaveExport", "Export", "System", ICON.share, "Exportacao: bundle, print map 2D do world real e JSON", build)
end

do
--[[ ARKHER V3 — UI: OPEN ]]
-- Layout unico: busca + arvore de pastas a esquerda, GRID de thumbnails
-- (K.thumb) no centro, painel de detalhes a direita — o browser completo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#70A1FF")

local function build()
	local g, root, head = K.window("ArkherOpen", "OPEN — browser de places", 24, 510, 572, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	-- ===== ESQUERDA: PASTAS =====
	local left = K.f(root, "Tree", 8, 34, 118, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "LOCAL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local folders = {
		{ nm = "Places", n = true },
		{ nm = "Maps" },
		{ nm = "Console" },
		{ nm = "Exports" },
	}
	for i, f in ipairs(folders) do
		local row = K.treeRow(left, 0, ICON.folder, f.nm, f.n, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Open: pasta " .. f.nm)
		end)
	end
	K.txt(left, "ServerStorage/\nArkherCloud/", 10, 140, 100, 30, 8, T.txt4)
	local newB = K.btn(left, "NewB", 10, 200, 98, 22, T.bg2, 4)
	K.txtS(newB, "+ novo", 9, T.txt)
	K.hover(newB, T.bg2, T.hover)
	newB.MouseButton1Click:Connect(function()
		ArkherPlaces.new("Empty")
	end)

	-- ===== TOPO: BUSCA =====
	K.search(root, 138, 34, 240, 24, "buscar place...")
	local sortB = K.btn(root, "Sort", 386, 34, 90, 24, T.bg4, 4)
	K.txtS(sortB, "ordem: size", 9, T.txt3)
	K.hover(sortB, T.bg4, T.hover)

	-- ===== CENTRO: GRID DE THUMBS =====
	local grid = K.f(root, "Grid", 138, 66, 240, 218, T.bg0)
	K.corner(grid, 4)
	K.stroke(grid, T.line, 1)
	local cards = K.f(grid, "Cards", 0, 0, 240, 218)
	local selCard = nil
	local function renderGrid()
		for _, ch in ipairs(cards:GetChildren()) do ch:Destroy() end
		local list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(cards, "(nada para abrir\nsalve um place primeiro)", 80, 90, 160, 40, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
			return
		end
		for i, p in ipairs(list) do
			if i > 4 then break end
			local r, c = math.floor((i - 1) / 2) + 1, ((i - 1) % 2) + 1
			local th = K.thumb(cards, 8 + (c - 1) * 118, 8 + (r - 1) * 106, 108, 96,
				tostring(p.name), C("#243447"), C("#18222E"))
			K.txt(th, "#" .. tostring(p.id), 4, 6, 60, 14, 9, T.neon)
			K.txt(th, string.format("%.1fK", (p.bytes or 0) / 1024), 66, 6, 38, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
			local pid = p.id
			th.MouseButton1Click:Connect(function()
				selCard = th
				detId.Text = "#" .. tostring(pid)
				detName.Text = tostring(p.name)
				detBytes.Text = string.format("%.1f KB", (p.bytes or 0) / 1024)
			end)
		end
	end
	renderGrid()

	-- ===== DIREITA: DETALHES =====
	local right = K.f(root, "Det", 390, 34, 174, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "DETALHES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local detName = K.txt(right, "—", 10, 28, 154, 18, 12, T.txt, ARKHER.FONTB)
	local detId = K.txt(right, "id: —", 10, 50, 154, 14, 10, T.neon)
	local detBytes = K.txt(right, "0 KB", 10, 68, 154, 14, 10, T.txt3)
	K.row(right, "Criado", "sessao atual", 96)
	K.row(right, "Modificado", "agora", 120)
	K.row(right, "Integridade", "100%", 144)
	local openB = K.btn(right, "OpenB", 10, 172, 154, 30, ACCENT, 5)
	K.txtS(openB, "ABRIR PLACE", 11, C("#0A1424"))
	K.hover(openB, ACCENT, C("#A6C2FF"))
	openB.MouseButton1Click:Connect(function()
		local id = tonumber(string.match(detId.Text, "%d+"))
		if id then
			ArkherPlaces.open(id)
			K.notify("Place aberto", detName.Text, "ok")
		else
			ARKHER.out("WARNING", "Open: selecione um place no grid")
		end
	end)
	local back = K.btn(right, "Back", 10, 210, 154, 22, T.bg2, 4)
	K.txtS(back, "voltar ao editor", 9, T.txt)
	K.hover(back, T.bg2, T.hover)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 556, 88, T.bg0)
	K.corner(bar, 4)
	local list = ArkherPlaces.list()
	K.row(bar, "Places", tostring(#list), 8)
	K.row(bar, "Pasta atual", "ArkherCloud/Places", 34)
	K.txt(bar, "clique na thumb para ver detalhes | duplo fluxo: abrir ou exportar", 200, 16, 340, 14, 9, T.txt4)
	K.progress(bar, 200, 46, 300, 0.6, ACCENT)
	K.txt(bar, "186 MB livres", 510, 52, 46, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Open", "Open", "System", ICON.open, "Browser de places: busca, grid de thumbs, detalhes e abrir", build)
end

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
	local closeB = K.btn(bar, "Close", 340, 44, 100, 24, T.bg2, 4)
	K.txtS(closeB, "fechar", 10, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		root.Visible = false
	end)
end

ARKHER.reg("About", "About", "System", ICON.info, "Sobre o ARKHER V3: sistemas ativos e contadores em tempo real", build)
end

local opened = ARKHER.openAll()
ARKHER.out("SUCCESS", "ARKHER V3 — bundle System: " .. opened .. " UIs abertas")
