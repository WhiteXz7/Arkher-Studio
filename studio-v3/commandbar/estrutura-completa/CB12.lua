--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA (12/13)
  ArkherStudio_ALL chunk 3/3
  Cria: ReplicatedStorage.ArkherV3.ALL.ALL_P3 (ModuleScript, 83,607 chars)
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]
local rs = game:GetService("ReplicatedStorage")
local arkherv3 = rs:FindFirstChild("ArkherV3")
if not arkherv3 then arkherv3 = Instance.new("Folder") arkherv3.Name = "ArkherV3" arkherv3.Parent = rs end
local all = arkherv3:FindFirstChild("ALL")
if not all then all = Instance.new("Folder") all.Name = "ALL" all.Parent = arkherv3 end
local S_CHUNK = [=====[return[====[		{ x = 204, w = 28, h = 66 },
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

do
--[[ ARKHER V3 — UI: PARTICLES ]]
-- Layout unico: arvore do emissor a esquerda, GRAPH DE NOS (K.node + K.wireLayer)
-- no centro — estilo Nuke/Blender, knobs a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C56CF0")

local function build()
	local g, root, head = K.window("ArkherParticles", "PARTICLES — graph", 24, 340, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: ARVORE DO EMISSOR =====
	local left = K.f(root, "Tree", 8, 34, 148, 296, T.bg4)
	K.corner(left, 4)
	K.txt(left, "EMITTER", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(left, 0, ICON.gem, "SparkEmitter", "open", 26)
	K.treeRow(left, 1, ICON.data, "RateOverTime", "sel", 50)
	K.treeRow(left, 1, ICON.data, "SpreadOverCone", nil, 74)
	K.treeRow(left, 1, ICON.data, "ColorOverLife", nil, 98)
	K.treeRow(left, 1, ICON.data, "Velocity", nil, 122)
	K.txt(left, "4 properties", 10, 150, 100, 14, 9, T.txt4)
	local addProp = K.btn(left, "AddP", 10, 172, 128, 22, T.bg2, 4)
	K.txtS(addProp, "+ property", 10, T.txt)
	K.hover(addProp, T.bg2, T.hover)
	local props = 4
	addProp.MouseButton1Click:Connect(function()
		props = props + 1
		ARKHER.out("INFO", "Particles: property #" .. props .. " adicionada")
	end)
	K.row(left, "Tipo", "Bullets", 210)
	K.row(left, "Lighting", "On", 234)
	K.row(left, "Sort", "Distance", 258)

	-- ===== CENTRO: GRAPH =====
	local cv = K.f(root, "Graph", 168, 34, 284, 296, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 8 do K.f(cv, "gx" .. i, i * 33, 0, 1, 296, T.bg3) end
	for i = 1, 9 do K.f(cv, "gy" .. i, 0, i * 31, 284, 1, T.bg3) end
	local wire = K.wireLayer(cv)
	-- nos
	local nEm = K.node(cv, 12, 108, 100, "Emitter", C("#3A2B45"), { "rate", "spread", "color" }, {}, { sel = true, dot = ACCENT })
	local nRate = K.node(cv, 160, 40, 104, "RateOverTime", T.bg1, {}, { "value" })
	local nSpread = K.node(cv, 160, 128, 104, "SpreadOverCone", T.bg1, {}, { "cone" })
	local nColor = K.node(cv, 160, 212, 104, "ColorOverLife", T.bg1, {}, { "grad" })
	-- liga os soquetes (coordenadas vindas dos _socket)
	local function socketsOf(n)
		local ins, outs = {}, {}
		for _, s in ipairs(n._sockets or {}) do
			if s._socket then
				if s._socket.kind == "in" then table.insert(ins, s._socket)
				else table.insert(outs, s._socket) end
			end
		end
		return ins, outs
	end
	local eIn, _ = socketsOf(nEm)
	local _, rOut = socketsOf(nRate)
	local _, sOut = socketsOf(nSpread)
	local _, cOut = socketsOf(nColor)
	if eIn[1] and rOut[1] then wire:link(rOut[1].x, rOut[1].y, eIn[1].x, eIn[1].y, ACCENT) end
	if eIn[2] and sOut[1] then wire:link(sOut[1].x, sOut[1].y, eIn[2].x, eIn[2].y, C("#4DFFDB")) end
	if eIn[3] and cOut[1] then wire:link(cOut[1].x, cOut[1].y, eIn[3].x, eIn[3].y, C("#FFD93D")) end
	K.txt(cv, "graph: 4 nos, 3 fios", 8, 278, 200, 14, 9, T.txt4)

	-- ===== DIREITA: KNOBS =====
	local right = K.f(root, "Knobs", 464, 34, 88, 296, T.bg4)
	K.corner(right, 4)
	K.txt(right, "RATE", 6, 6, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 24, 48, 0.72, "128/s")
	K.txt(right, "SPREAD", 6, 96, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 114, 48, 0.3, "38deg")
	K.txt(right, "LIFE", 6, 186, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 204, 48, 0.5, "1.4s")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 340, 544, 52, T.bg0)
	K.corner(bar, 4)
	-- preview de particulas (pontos)
	local pv = K.f(bar, "Prev", 10, 6, 120, 40, T.dark)
	K.corner(pv, 3)
	for i = 1, 14 do
		local s = (i * 16807) % 2147483647
		local s2 = (s * 16807) % 2147483647
		local d = K.f(pv, "P" .. i, s % 110 + 4, s2 % 30 + 4, 3, 3, ACCENT, 1)
	end
	local pvLbl = K.txt(bar, "preview: 128/s", 140, 12, 120, 16, 10, T.txt3)
	local sim = K.btn(bar, "Sim", 270, 12, 80, 26, ACCENT, 5)
	K.txtS(sim, "Simular", 11, C("#160B1E"))
	K.hover(sim, ACCENT, C("#D99BFF"))
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Particles: 128 particulas/s por 1.4s simuladas")
		K.notify("Simulacao", "SparkEmitter OK", "ok")
	end)
	K.txt(bar, "modo: graph", 370, 18, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(bar, "pronto", 480, 18, 50, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Sistema de particulas em graph de nos com emissor e preview", build)
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
	local rep2 = K.btn(bar, 330, 52, 110, 24, T.bg2, 4)
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
	local closeB = K.btn(bar, 330, 56, 100, 26, T.bg2, 4)
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
--[[ ARKHER V3 — UI: SCRIPT (code editor) ]]
-- Layout unico: barra de arquivo + tabs de classe, area de codigo com
-- numeros de linha, painel de lint, acoes reais (criar Script no place, exportar).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")

local TEMPLATES = {
	Script = {
		"-- MeuScript (Script)",
		"local part = script.Parent",
		"",
		"part.Touched:Connect(function(hit)",
		"\tprint(\"tocado: \" .. hit.Name)",
		"\tpart.BrickColor = BrickColor.new(\"Bright red\")",
		"end)",
		"",
		"-- ARKHER: criado via Scripter",
	},
	LocalScript = {
		"-- MeuLocal (LocalScript)",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal cam = workspace.CurrentCamera",
		"\tcam.FieldOfView = 70",
		"end)",
	},
	ModuleScript = {
		"-- MeuModule (ModuleScript)",
		"local M = {}",
		"",
		"function M.hello(name)",
		"\treturn \"ola, \" .. name",
		"end",
		"",
		"return M",
	},
}

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT — editor de codigo", 24, 330, 520, 424, { pin = true })
	K.f(head, "Acc", 0, 24, 520, 2, ACCENT)

	local curCls = "Script"
	local curName = "MeuScript"
	local code = {}
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }

	-- ===== TOPO: ARQUIVO + CLASSES =====
	local nameBox = K.input(root, 10, 34, 190, 24, "nome do arquivo")
	nameBox.Text = "MeuScript"
	K.tabs(root, 210, 34, 290, CLASSES, 1, function(idx)
		curCls = CLASSES[idx]
		curName = nameBox.Text
		code = TEMPLATES[curCls]
		renderCode()
	end)

	-- ===== AREA DE CODIGO =====
	local ed = K.f(root, "Editor", 10, 64, 356, 240, T.bg0)
	K.corner(ed, 4)
	K.stroke(ed, T.line, 1)
	local function renderCode()
		for i = 1, 12 do
			local old = ed:FindFirstChild("L" .. i)
			if old then old:Destroy() end
		end
		for i = 1, 12 do
			local ln = code[i] or ""
			K.txt(ed, string.format("%2d", i), 4, 6 + (i - 1) * 18, 24, 18, 9, T.txt4)
			K.f(ed, "ln" .. i, 28, 6 + (i - 1) * 18, 322, 1, (i == 5 or i == 7) and T.line or T.bg0)
			local col = T.txt2
			local txt = ln
			if ln:sub(1, 2) == "--" then col = T.txt4 end
			if ln:find("local ") == 1 then col = C("#C792EA") end
			if ln:find("function ") == 1 then col = ACCENT end
			if ln:find("print") == 1 then col = C("#82AAFF") end
			if txt ~= "" then
				local t = K.txt(ed, "L" .. i, 30, 6 + (i - 1) * 18, 320, 18, 10, col, ARKHER.MONO or ARKHER.FONT)
			end
		end
	end
	renderCode()

	-- ===== LINT =====
	local lint = K.f(root, "Lint", 10, 310, 356, 56, T.bg4)
	K.corner(lint, 4)
	K.txt(lint, "LINT", 8, 4, 50, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(lint, "0 erros", 8, 22, 80, 14, 10, T.ok)
	K.txt(lint, "1 aviso: pcall p/ Touched", 100, 22, 160, 14, 9, C("#FFD93D"))
	K.txt(lint, "linhas: 9", 280, 22, 70, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 378, 64, 134, 302, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AÇÕES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Classe", curCls, 26)
	K.row(right, "Linhas", "9", 50)
	K.row(right, "Tamanho", "0.2 KB", 74)
	local create = K.btn(right, "Create", 10, 102, 114, 26, ACCENT, 5)
	K.txtS(create, "Criar no Place", 10, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local n = 1
		local ws = workspace
		local base = nameBox.Text
		while ws:FindFirstChild(base) do n = n + 1 base = nameBox.Text .. "_" .. n end
		local sc = Instance.new(curCls)
		sc.Name = base
		sc.Source = table.concat(code, "\n")
		sc.Parent = ws
		ARKHER.out("SUCCESS", "Script: " .. curCls .. " '" .. base .. "' criado no place (" .. #code .. " linhas)")
		K.notify("Script criado", base .. " no workspace", "ok")
	end)
	local exp = K.btn(right, "Export", 10, 136, 114, 26, T.bg2, 5)
	K.txtS(exp, "Exportar .lua", 10, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local data = table.concat(code, "\n")
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherScripts/" .. nameBox.Text .. ".lua", data)
				return "ArkherScripts/" .. nameBox.Text .. ".lua"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Script: exportado para " .. path)
		else
			ARKHER.out("WARNING", "Script: WriteFile indisponivel fora do Studio")
		end
	end)
	local ins = K.btn(right, "Insert", 10, 170, 114, 26, T.bg2, 5)
	K.txtS(ins, "+ snippet", 11, T.txt)
	K.hover(ins, T.bg2, T.hover)
	local snippets = { "\t-- snippet: debounce", "\tlocal debounce = false", "pcall(function() end)", "warn(\"debug\")" }
	local sn = 1
	ins.MouseButton1Click:Connect(function()
		sn = (sn % #snippets) + 1
		table.insert(code, snippets[sn])
		renderCode()
		ARKHER.out("INFO", "Script: snippet inserido")
	end)
	K.row(right, "Encoding", "utf-8", 214)
	K.row(right, "EOL", "LF", 238)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 10, 372, 502, 44, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "Ln 5, Col 12", 12, 6, 100, 14, 9, T.txt3)
	K.txt(bar, curCls, 130, 6, 120, 14, 9, ACCENT)
	K.txt(bar, "UTF-8 | LF | Luau", 268, 6, 130, 14, 9, T.txt4)
	K.txt(bar, "salvo", 470, 6, 30, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Script", "Script", "Editor", ICON.script, "Editor de codigo Luau: classes, lint, criar no place e exportar", build)
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
--[[ ARKHER V3 — UI: TERRAIN ]]
-- Layout unico: pincelais de escultura a esquerda, heightmap 8x8 INTERATIVO
-- no centro (clique aplica o pincel e repinta), paleta de biomas a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN — escultura", 24, 320, 552, 384, { pin = true })
	K.f(head, "Acc", 0, 24, 552, 2, ACCENT)

	-- estado do relevo
	local heights = {}
	local seed = 7
	local function reseed(s)
		seed = s
		for i = 1, 64 do
			seed = (seed * 16807) % 2147483647
			heights[i] = (seed % 1000) / 1000 * 6
		end
	end
	reseed(11)

	-- ===== PINCELAS =====
	local brushes = {
		{ id = "raise", nm = "Raise", gl = "+", d = "sobe 1u" },
		{ id = "lower", nm = "Lower", gl = "-", d = "desce 1u" },
		{ id = "smooth", nm = "Smooth", gl = "~", d = "media vizinhos" },
		{ id = "flatten", nm = "Flatten", gl = "=", d = "zera" },
		{ id = "erase", nm = "Erase", gl = "x", d = "remove tudo" },
	}
	local curBrush = "raise"
	local left = K.f(root, "Brush", 8, 34, 108, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "PINCEL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, b in ipairs(brushes) do
		local row = K.btn(left, "B" .. i, 8, 26 + (i - 1) * 34, 92, 28, T.bg2, 4)
		local ic = K.f(row, "G", 4, 6, 16, 16, T.bg0, 3)
		K.txt(ic, b.gl, 0, 0, 16, 16, 11, ACCENT, FONTB, Enum.TextXAlignment.Center)
		K.txt(row, b.nm, 26, 2, 62, 14, 10, T.txt)
		K.txt(row, b.d, 26, 15, 62, 11, 8, T.txt4)
		local id = b.id
		row.MouseButton1Click:Connect(function()
			curBrush = id
			for j = 1, #brushes do
				local rr = left:FindFirstChild("B" .. j)
				if rr then K.stroke(rr, j == i and ACCENT or T.line2, j == i and 1.5 or 1) end
			end
		end)
		K.stroke(row, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	K.sliderRow(left, "Forca", 0.6, 206)

	-- ===== HEIGHTMAP 8x8 =====
	local cv = K.f(root, "Map", 126, 34, 252, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	local tiles = {}
	local function hcolor(h)
		-- 0=agua/areia -> 6=rocha
		local stops = { C("#2E86AB"), C("#E9D8A6"), C("#7ED957"), C("#3E8E41"), C("#8D6E63"), C("#6D6E71"), C("#CFD8DC") }
		local idx = math.min(6, math.floor(h))
		return stops[idx + 1]
	end
	local function paint(i, tx, ty)
		local t = tiles[i]
		if t then
			t.BackgroundColor3 = hcolor(heights[i])
			t:FindFirstChild("N").Text = string.format("%.1f", heights[i])
		end
	end
	local function applyBrush(idx)
		local r, c = math.floor((idx - 1) / 8) + 1, ((idx - 1) % 8) + 1
		local function get(r2, c2)
			if r2 < 1 or r2 > 8 or c2 < 1 or c2 > 8 then return nil end
			return (r2 - 1) * 8 + c2
		end
		if curBrush == "raise" then heights[idx] = math.min(6, heights[idx] + 1)
		elseif curBrush == "lower" then heights[idx] = math.max(0, heights[idx] - 1)
		elseif curBrush == "flatten" then heights[idx] = 0
		elseif curBrush == "erase" then heights[idx] = 0
		elseif curBrush == "smooth" then
			local sum, n = 0, 0
			for dr = -1, 1 do
				for dc = -1, 1 do
					local j = get(r + dr, c + dc)
					if j then sum = sum + heights[j] n = n + 1 end
				end
			end
			heights[idx] = sum / n
		end
		-- repinta a vizinhanca
		for dr = -1, 1 do
			for dc = -1, 1 do
				local j = get(r + dr, c + dc)
				if j then paint(j) end
			end
		end
	end
	for i = 1, 64 do
		local r, c = math.floor((i - 1) / 8) + 1, ((i - 1) % 8) + 1
		local t = K.f(cv, "H" .. i, (c - 1) * 31 + 2, (r - 1) * 29 + 2, 29, 27, hcolor(heights[i]), 2)
		K.txt(t, string.format("%.1f", heights[i]), 0, 8, 29, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
		tiles[i] = t
		local idx = i
		t.MouseButton1Click:Connect(function() applyBrush(idx) end)
	end
	K.txt(cv, "clique num tile = aplicar pincel", 8, 236, 200, 12, 8, T.txt4)

	-- ===== BIOMAS + MATERIAIS =====
	local right = K.f(root, "Biome", 390, 34, 154, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "BIOMAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local biomes = {
		{ "Praia", C("#E9D8A6") }, { "Grande", C("#7ED957") },
		{ "Deserto", C("#D4A373") }, { "Neve", C("#ECEFF1") },
	}
	for i, b in ipairs(biomes) do
		local row = K.btn(right, "BM" .. i, 10, 26 + (i - 1) * 26, 134, 22, T.bg2, 4)
		K.f(row, "Sw", 4, 5, 12, 12, b[2], 2)
		K.txt(row, b[1], 22, 0, 90, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Terrain: bioma " .. b[1])
		end)
	end
	K.txt(right, "MATERIAIS", 10, 138, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local mats = { C("#7ED957"), C("#8D6E63"), C("#B0BEC5"), C("#E9D8A6"), C("#4DB6AC"), C("#6D6E71") }
	for i = 1, 6 do
		local m = K.f(right, "M" .. i, 10 + ((i - 1) % 3) * 44, 158 + math.floor((i - 1) / 3) * 34, 38, 28, mats[i], 3)
		K.stroke(m, i == 1 and ACCENT or T.line, i == 1 and 1.5 or 1)
		K.txt(m, tostring(i) .. "u", 0, 16, 38, 10, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 536, 92, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Relevo procedural", 10, C("#0D140B"))
	K.hover(gen, ACCENT, C("#A5E88C"))
	local gseed = 11
	gen.MouseButton1Click:Connect(function()
		gseed = gseed * 31 + 7
		reseed(gseed)
		for i = 1, 64 do paint(i) end
		ARKHER.out("SUCCESS", "Terrain: relevo procedural (seed " .. gseed .. ")")
	end)
	local ai = K.btn(bar, "AI", 150, 10, 120, 26, T.bg2, 5)
	K.txtS(ai, "Gerar c/ IA", 11, T.txt)
	K.hover(ai, T.bg2, T.hover)
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Terrain: pedindo a Singularity...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno com natureza") end)
		if ok and rep then K.notify("Singularity", "terreno gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	K.txt(bar, "8x8 tiles | 31u | bioma: Grande", 10, 48, 250, 16, 10, T.txt3)
	K.txt(bar, "altura media: 2.4u", 300, 48, 150, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.progress(bar, 10, 70, 516, 0.42, ACCENT)
end

ARKHER.reg("Terrain", "Terrain", "Editor", ICON.terrain, "Escultura de terreno: pincelais, heightmap, biomas e materiais", build)
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

--[[ ARKHER V3 — DRIVER: boot completo (sistemas + shell + todas as UIs) ]]
-- Ordem: prelude → core → actions → boot → main shell → UIs em cascata.
do
	ARKHER.boot()
	pcall(function() ARKHER_BUILD_MAIN() end)
	local opened = ARKHER.openAll()
	ARKHER.out("SUCCESS", string.format("ARKHER V3 pronto: %d UIs ativas + core (places/do15/nmn/singularity/undo/live/publish)", opened))
end
]====]
]=====]
local t = all:FindFirstChild("ALL_P3")
if not t then t = Instance.new("ModuleScript") t.Name = "ALL_P3" t.Parent = all end
t.Source = S_CHUNK
print("[ARKHER V3] (12/13) ALL_P3 instalado em ReplicatedStorage.ArkherV3.ALL (83,607 chars)")
