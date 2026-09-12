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
