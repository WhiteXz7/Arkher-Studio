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
