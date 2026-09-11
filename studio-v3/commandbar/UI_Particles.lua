--[[ ARKHER V4 — LocalScript. Requer os kits (ReplicatedStorage.ArkherV3.ArkherKit_B/C/D/E). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	for _, kn in ipairs({ "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E" }) do
		local m = folder and folder:FindFirstChild(kn)
		if not m then m = script:FindFirstChild(kn) end
		if not m then m = script.Parent and script.Parent:FindFirstChild(kn) end
		if not m then
			error("[ARKHER] " .. kn .. " nao encontrado: rode os installers A+B+C+D+E primeiro.")
		end
		require(m)
	end
end
_arkherKit()
ARKHER.boot()

do
-- =============================================================
-- PARTICLES STUDIO X — UI sobre o PARTICLES X (APX custom)
-- 12 presets REAIS (fisica process-own: foguete ballistico, fogo com
-- up-draft, splash d'agua, vortex magico, ring shockwave, chuva/neve
-- com area, folhas com sway...), EDITOR de spec ao vivo, suppressor
-- D-O15 (budget com pressure real), links AWX/AEX. Mexer = emitir
-- ParticleEmitter REAL parametrizado pela nossa fisica. ✨🔥❄️
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#FFB84D"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#FFB84D"))
	K.corner(fill, 3)
	local function rs()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setI(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		rs()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then setI(i) end end)
	track.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then setI(i) end end)
	rs()
	return { get = function() return val end, set = function(v) val = v rs() if onSet then onSet(v) end end }
end

local function build()
	if not ArkherParticlesX then ARKHER.note("Kit E nao carregado (PARTICLES X ausente)") return end
	local APX = ArkherParticlesX

	local W, H = 700, 500
	local g, root = K.window("ParticlesStudio", "PARTICLES STUDIO X — emissores custom (APX custom)", 270, 140, W, H, { pin = true })

	local bodyH = H - 34 - 40
	local logLine, repaintActive

	-- ============ ESQUERDA: 12 PRESETS ============
	local left = K.f(root, "L", 6, 34, 244, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "PRESETS FISICOS (clique = emitir REAL)", 8, 4, 230, 14, 9, T.txt3)
	local cols = {
		foguete = "#C9413C", fogo = "#E0641E", fumaca = "#5A5A62", faiscas = "#E3B22E",
		agua = "#3E7FBF", magia = "#7B4BD9", gilman = "#82D4FF", chuva = "#4A6E8C",
		neve = "#D8E4F0", folhas = "#6E8C2E", poeira = "#A89670", bolhas = "#62B8D9", trilha = "#3E8CD9",
	}
	local order = { "foguete", "fogo", "fumaca", "faiscas", "agua", "magia", "gilman", "chuva", "neve", "folhas", "poeira", "bolhas" }
	for i, nm in ipairs(order) do
		local px = 8 + ((i - 1) % 2) * 114
		local py = 20 + math.floor((i - 1) / 2) * 40
		local col = C(cols[nm] or "#555")
		local b = K.btn(left, "P_" .. nm, px, py, 106, 34, T.bg4, 6)
		local sw = K.f(b, "Sw", 4, 4, 26, 26, col)
		K.corner(sw, 5)
		K.txt(b, nm, 36, 10, 68, 14, 9, T.txt)
		b.MouseButton1Click:Connect(function()
			APX.emit(nil, nm)
			logLine("emit: " .. nm)
		end)
	end
	K.txt(left, "continuous: cone/vortex/trail", 8, 262, 230, 12, 8, T.txt3)
	K.txt(left, "one-shot: burst/ring (1 toque)", 8, 274, 230, 12, 8, T.txt3)
	local clearB = K.btn(left, "LIMPAR TODOS", 8, 292, 228, 24, C("#7A2E2E"), 6)
	clearB.MouseButton1Click:Connect(function()
		APX.clear()
		repaintActive()
		logLine("clear all")
	end)

	-- ============ CENTRO: EDITOR DE SPEC ============
	local center = K.f(root, "C", 258, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "SPEC EDITOR (override do preset)", 8, 4, 236, 14, 9, T.txt3)
	local baseSel = "fogo"
	local baseLbl = K.txt(center, "base: fogo", 8, 20, 150, 14, 9, C("#FFB84D"))
	local function mkBaseBtn(nm, x)
		local b = K.btn(center, "SB_" .. nm, x, 36, 74, 18, T.bg4, 4)
		K.txt(b, nm, 8, 3, 60, 12, 8, T.txt2)
		b.MouseButton1Click:Connect(function() baseSel = nm baseLbl.Text = "base: " .. nm end)
	end
	mkBaseBtn("fogo", 60) mkBaseBtn("agua", 138)
	local lifeS = mkSlider(center, 8, 58, 226, "life", 0.2, 8, 1.4, function(v) return string.format("%.1f s", v) end)
	local speedS = mkSlider(center, 8, 100, 226, "speed", 0, 40, 8, function(v) return string.format("%.0f m/s", v) end)
	local gravS = mkSlider(center, 8, 142, 226, "gravity(− sobe)", -30, 60, 12, function(v) return string.format("%.0f", v) end)
	local spreadS = mkSlider(center, 8, 184, 226, "spread", 0, 2.0, 0.4, function(v) return string.format("%.2f", v) end)
	local rateS = mkSlider(center, 8, 226, 226, "rate (emit cont.)", 0, 400, 80, function(v) return string.format("%.0f/s", v) end)
	local sizeS = mkSlider(center, 8, 268, 226, "size", 0.05, 6, 0.8, function(v) return string.format("%.2f", v) end)
	local vortexS = mkSlider(center, 8, 310, 226, "vOmega (vortex)", 0, 20, 9, function(v) return string.format("%.1f", v) end)
	K.txt(center, "MODO", 8, 356, 236, 14, 9, T.txt3)
	local modeSel = "cone"
	local modes = { "cone", "burst", "ring", "vortex", "trail" }
	for i, m in ipairs(modes) do
		local mx = 8 + ((i - 1) % 3) * 78
		local my = 372 + math.floor((i - 1) / 3) * 24
		local b = K.btn(center, "M_" .. m, mx, my, 74, 20, T.bg4, 4)
		K.txt(b, m, 8, 4, 60, 12, 8, T.txt2)
		b.MouseButton1Click:Connect(function() modeSel = m end)
	end
	local emitBtn = K.btn(center, "EMITIR CUSTOM", 8, 424, 228, 26, C("#2E8C46"), 6)
	emitBtn.MouseButton1Click:Connect(function()
		APX.emit(nil, baseSel, {
			mode = modeSel,
			life = lifeS.get(),
			speed = speedS.get(),
			gravity = gravS.get(),
			spread = spreadS.get(),
			rate = rateS.get(),
			size0 = sizeS.get(),
			size1 = sizeS.get() * 0.5,
			vOmega = vortexS.get(),
		})
		logLine("emit custom (" .. baseSel .. "/" .. modeSel .. ")")
	end)

	-- ============ DIREITA: BUDGET + ACTIVE + LINKS ============
	local right = K.f(root, "R", 516, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "BUDGET D-O15 (pressure real)", 8, 4, 222, 14, 9, T.txt3)
	local presBar = K.f(right, "PB", 8, 20, 222, 10, C("#101827"))
	K.corner(presBar, 5)
	local presFill = K.f(presBar, "F", 0, 2, 4, 6, C("#7A2E2E"))
	K.corner(presFill, 3)
	local budgetTxt = K.txt(right, "pressure: —  scale: —", 8, 36, 222, 14, 9, T.txt2)
	K.txt(right, "EMISSORES ATIVOS", 8, 60, 222, 14, 9, T.txt3)
	local actList = K.txt(right, "(nenhum)", 8, 76, 222, 76, 9, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Left)
	repaintActive = function()
		local lines2 = {}
		for k, e in pairs(APX._emitters) do
			lines2[#lines2 + 1] = "- " .. k .. " [rate " .. tostring(e.pe.Rate) .. "]"
		end
		if #lines2 == 0 then lines2[1] = "(nenhum)" end
		table.sort(lines2)
		actList.Text = table.concat(lines2, "\n")
	end
	K.txt(right, "LINKS FISICOS REAIS", 8, 166, 222, 14, 9, T.txt3)
	local splashB = K.btn(right, "SPLASH p/ primeiro corpo AWX", 8, 182, 222, 22, C("#2E4E7A"), 5)
	splashB.MouseButton1Click:Connect(function()
		if ArkherWaterX and #ArkherWaterX.bodies > 0 then
			local b = ArkherWaterX.bodies[1]
			local anchor = Instance.new("Part")
			anchor.Size = Vector3.new(0.2, 0.2, 0.2)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.Position = Vector3.new(0, b.seaLevel + 0.3, 0)
			anchor.Parent = workspace
			APX.emit(anchor, "agua", { burst = 40, mode = "burst", life = 0.8 })
			ArkherWaterX.splash(b, 0, b.seaLevel + 0.2, 0, 2)
			logLine("splash: agua burst + AWX splash reel")
		else
			logLine("sem corpo AWX; criando ocean oceano...")
			if ArkherWaterX then ArkherWaterX.create("ocean") end
		end
	end)
	local stormB = K.btn(right, "chuva + setWeather(tempestade)", 8, 210, 222, 22, C("#3A3A42"), 5)
	stormB.MouseButton1Click:Connect(function()
		if ArkherAtmosX then ArkherAtmosX.setWeather("tempestade", 1.2) end
		APX.emit(nil, "chuva", { rate = 240, speed = 40 })
		logLine("chuva emit + AEX tempestade")
	end)
	local snowB = K.btn(right, "neve suave", 8, 238, 222, 22, C("#4A5A6E"), 5)
	snowB.MouseButton1Click:Connect(function()
		if ArkherAtmosX then ArkherAtmosX.setWeather("neve", 1.0) end
		APX.emit(nil, "neve", { rate = 60 })
		logLine("neve emit")
	end)
	K.txt(right, "LOG", 8, 276, 222, 14, 9, T.txt3)
	local logTxt = K.txt(right, "", 8, 292, 222, 110, 9, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Left)
	local lines = {}
	logLine = function(s)
		lines[#lines + 1] = s
		if #lines > 7 then table.remove(lines, 1) end
		logTxt.Text = table.concat(lines, "\n")
	end
	logLine("APX Studio pronto")

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Particles Studio X atasao PARTICLES X (12 presets fisicos + budget D-O15)")

	-- ============ HEARTBEAT budget ============
	if not ArkherParticlesX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherParticlesX.UI_CONN = RS.Heartbeat:Connect(function()
					local okin = pcall(function()
						if ArkherDO15 and ArkherDO15.pressure then
							local p = ArkherDO15.pressure()
							presFill.Size = UDim2.new(0, math.floor(p * 222), 0, 6)
							budgetTxt.Text = string.format("pressure: %.0f%%  scale: %.0f%%", p * 100, APX.budgetScale() * 100)
						end
					end)
					if not okin then ArkherParticlesX.UI_CONN:Disconnect() ArkherParticlesX.UI_CONN = nil end
				end)
			end)
		end
	end
	repaintActive()
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Particulas custom: 12 presets fisicos + spec editor + budget D-O15 (PARTICLES X)", build)
end

ARKHER.open("Particles")
