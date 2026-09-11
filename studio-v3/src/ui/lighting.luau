-- =============================================================
-- LIGHTING STUDIO X — UI sobre o ATMOS X (AEX custom)
-- Ciclo dia/noite com Kelvin PLANCKIAN REAL (kelvinRGB), 6 presets de
-- céu com física (kelvin/haze/fog do próprio motor), WEATHER MACHINE
-- com 7 estados e transição suave, raio de demonstração, links AWX/AUX.
-- Tudo REAL: mexer = alterar Lighting/Atmosphere/ColorCorrection. ☀️🌩️
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#8BCCFF"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#8BCCFF"))
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
	if not ArkherAtmosX then ARKHER.note("Kit E nao carregado (ATMOS X ausente)") return end
	local AEX = ArkherAtmosX
	AEX.setup({})

	local W, H = 680, 500
	local g, root = K.window("LightingStudio", "LIGHTING STUDIO X — ceu custom (ATMOS X custom)", 240, 130, W, H, { pin = true })

	local running, cycle = true, false

	-- ============ ESQUERDA: SKY + CICLO ============
	local bodyH = H - 34 - 40
	local left = K.f(root, "L", 6, 34, 240, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "PRESETS DE CEU (fisica do motor)", 8, 4, 220, 14, 9, T.txt3)
	local presets = { "madrugada", "amanhecer", "meiodia", "tarde", "entardecer", "noite" }
	for i, pn in ipairs(presets) do
		local y = 20 + (i - 1) * 30
		local b = K.btn(left, pn, 8, y, 224, 26, T.bg4, 6)
		K.txt(b, pn .. "  (" .. math.floor((AEX.SKY_PRESETS[pn].kelvin or 5000) / 100) / 10 .. "k Kelvin)", 10, 6, 200, 14, 9, T.txt)
		b.MouseButton1Click:Connect(function()
			AEX.setPreset(pn)
			repaintKelvin()
		end)
	end
	K.txt(left, "CICLO DIA-NOITE", 8, 208, 220, 14, 9, T.txt3)
	local spdS = mkSlider(left, 8, 224, 200, "vel ciclo (h/s)", 0, 0.5, 0.0045, function(v) return string.format("%.4f", v) end, function(v) AEX.S.cycleSpeed = v end)
	local cycB = K.btn(left, "CICLO AR 24H", 8, 268, 110, 22, T.bg4, 5)
	local cycOn = false
	cycB.MouseButton1Click:Connect(function()
		cycOn = not cycOn
		spdS.set(0.7)
	end)
	local ckTxt = K.txt(left, "clock: —", 8, 296, 224, 14, 9, T.txt2)
	K.txt(left, "aplicado SEMPRE ao Lighting real", 8, 312, 224, 12, 8, T.txt3)

	-- ============ CENTRO: KELVIN + TEMPO ============
	local center = K.f(root, "C", 254, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "TEMPERATURA DE COR DO SOL", 8, 4, 236, 14, 9, T.txt3)
	K.txt(center, "Intensidade/tonalidade vêm da escala", 8, 18, 236, 12, 8, T.txt3)
	K.txt(center, "Planckian REAL (kelvinRGB do AEX)", 8, 30, 236, 12, 8, T.txt3)
	local kelvinS = mkSlider(center, 8, 48, 226, "Kelvin", 1000, 12000, 5600, function(v) return string.format("%.0f K", v) end, function(v) repaintKelvin() end)
	local swatch = K.f(center, "Sw", 8, 92, 226, 76, C("#FFFFFF"))
	K.corner(swatch, 6)
	K.stroke(swatch, T.line2, 1)
	local rgbTxt = K.txt(center, "r/g/b: —", 12, 100, 220, 14, 9, C("#0B1220"))
	local terraR = K.f(center, "bandR", 42, 176, 40, 40, C("#FF3B30"))
	K.corner(terraR, 20)
	local terraG = K.f(center, "bandG", 92, 176, 40, 40, C("#D8FFB0"))
	K.corner(terraG, 20)
	local terraB = K.f(center, "bandB", 142, 176, 40, 40, C("#BFE7FF"))
	K.corner(terraB, 20)
	local terraLblR = K.txt(center, "R", 54, 218, 16, 12, 8, T.txt2)
	local terraLblG = K.txt(center, "G", 104, 218, 16, 12, 8, T.txt2)
	local terraLblB = K.txt(center, "B", 154, 218, 16, 12, 8, T.txt2)
	K.txt(center, "faixa fisica (1k..12k K)", 42, 234, 150, 12, 8, T.txt3)
	function repaintKelvin()
		local k = kelvinS.get()
		local col = AEX.kelvinRGB(k)
		swatch.BackgroundColor3 = col
		local rr = col.R or 0
		local gg = col.G or 0
		local bb = col.B or 0
		local ri = math.floor((type(rr) == "number" and rr <= 1) and rr * 255 or rr)
		-- Color3 pode vir 0..1 ou 0..255 conforme origem
		local function to255(v) return v > 1 and math.floor(v + 0.5) or math.floor(v * 255 + 0.5) end
		local R255, G255, B255 = to255(rr), to255(gg), to255(bb)
		rgbTxt.Text = string.format("R%d  G%d  B%d  (%d K real)", R255, G255, B255, k)
		rgbTxt.TextColor3 = (R255 + G255 + B255) > 380 and C("#0B1220") or C("#E6EBF5")
		terraR.BackgroundColor3 = Color3.fromRGB(255, math.max(20, math.floor(120 - (k - 1000) / 11000 * 60)), 30)
		terraG.BackgroundColor3 = Color3.fromRGB(200 + math.floor((k - 5600) / 6000 * 55), 255, 176)
		terraB.BackgroundColor3 = Color3.fromRGB(148, 209, 255)
		-- aplica kelvin custom no preset atual
		local pr = AEX.SKY_PRESETS[AEX.S.preset]
		if pr then pr.kelvin = k end
	end
	K.txt(center, "TEMPO (hora solar gerando o dia)", 8, 258, 236, 14, 9, T.txt3)
	local clockS = mkSlider(center, 8, 274, 226, "hora (0..24)", 0, 24, 12, function(v) return string.format("%.2fh", v) end, function(v) AEX.setClock(v) AEX.apply({}) ckTxt.Text = string.format("clock: %.2f (ClockTime real)", v) end)
	local clockBarBk = K.f(center, "Cbk", 8, 330, 226, 20, C("#101827"))
	K.corner(clockBarBk, 5)
	local sunDot = K.f(clockBarBk, "Sun", 6, 6, 8, 8, C("#FFE08A"))
	K.corner(sunDot, 4)
	local duskBar = K.f(clockBarBk, "DuskA", 6 + (18 / 24) * 214, 6, 8, 8, C("#FF8C3B"))
	K.corner(duskBar, 4)
	local nightBar = K.f(clockBarBk, "Night", 6, 6, 4, 8, C("#5B6EA8"))
	K.corner(nightBar, 2)
	-- desenha o espectro do dia: 48 pontinhos no fundo
	for i = 0, 24 do
		local kk = 1800 + (i / 24) * (5600 - 1800)
		local c = AEX.kelvinRGB(kk)
		local dot = K.f(clockBarBk, "d" .. i, 4 + i * 9, 13, 3, 3, c)
	end

	-- ============ DIREITA: WEATHER MACHINE ============
	local right = K.f(root, "R", 512, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "WEATHER MACHINE (multiplicadores fisicos)", 8, 4, 222, 14, 9, T.txt3)
	local weathers = { "limpo", "nuvem", "chuva", "tempestade", "neblina", "neve", "aurora" }
	local wBtns = {}
	for i, wn in ipairs(weathers) do
		local wx = (i % 2 == 1) and 8 or 120
		local wy = 20 + math.floor((i - 1) / 2) * 30
		local wv = AEX.WEATHER[wn]
		local tint = wv.rain > 0 and C("#24486B") or (wv.haze > 7 and C("#3A3A42") or C("#2E5E46"))
		local b = K.btn(right, "W_" .. wn, wx, wy, 106, 26, tint, 6)
		K.txt(b, wn, 8, 6, 96, 14, 9, T.txt)
		wBtns[wn] = b
		b.MouseButton1Click:Connect(function()
			AEX.setWeather(wn, transS.get())
		end)
	end
	K.txt(right, "TRANSICAO", 8, 142, 222, 14, 9, T.txt3)
	local transS = mkSlider(right, 8, 158, 222, "vel. transicao", 0.05, 2.0, 0.35, function(v) return string.format("%.2f/s", v) end)
	local demoB = K.btn(right, "DEMO: tempestade agora", 8, 202, 130, 24, C("#7A2E2E"), 6)
	demoB.MouseButton1Click:Connect(function()
		AEX.setWeather("tempestade", 2.0)
		-- + boost das ondas reais já acontece via link AWX no pump
	end)
	local cleanB = K.btn(right, "limpar", 144, 202, 86, 24, T.bg4, 6)
	cleanB.MouseButton1Click:Connect(function() AEX.setWeather("limpo", 1.2) end)
	K.txt(right, "ESTADO DO MOTOR (pump)", 8, 238, 222, 14, 9, T.txt3)
	local fogTxt = K.txt(right, "nevoa: —", 8, 254, 222, 14, 9, T.txt2)
	local hazeTxt = K.txt(right, "haze: —", 8, 268, 222, 14, 9, T.txt2)
	local boostTxt = K.txt(right, "waveBoost: —", 8, 282, 222, 14, 9, T.txt2)
	local ltTest = K.btn(right, "flash relampago (teste)", 8, 306, 140, 24, C("#5A3B8C"), 6)
	ltTest.MouseButton1Click:Connect(function()
		if ArkherAtmosX and ArkherAtmosX.S._cc then
			ArkherAtmosX.S._cc.Brightness = 0.22
		end
	end)
	K.txt(right, "LINKS FISICOS", 8, 338, 222, 14, 9, T.txt3)
	K.txt(right, "tempestade → ondas AWX ×2.2", 8, 352, 222, 12, 8, T.txt3)
	K.txt(right, "vento → volume weather AUX", 8, 366, 222, 12, 8, T.txt3)
	K.txt(right, "nevoa/neve → FogEnd/Haze reais", 8, 380, 222, 12, 8, T.txt3)

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Lighting Studio X atasao ATMOS X (ceu custom Kelvin + weather machine)")

	-- ============ HEARTBEAT (pump real do motor) ============
	if not ArkherAtmosX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherAtmosX.UI_CONN = RS.Heartbeat:Connect(function(dt)
					local okin = pcall(function()
						local clockNow, w = AEX.pump(dt or 1 / 60)
						ckTxt.Text = string.format("clock: %.2f (ClockTime real; ciclo %s)", clockNow, cycOn and "ON" or "manual")
						fogTxt.Text = string.format("FogEnd: %.0f  (cloud %.2f, rain %.2f)", w.fogEnd, w.cloud, w.rain)
						hazeTxt.Text = string.format("Haze: %.2f  Stars: %s", w.haze, tostring(w.stars))
						boostTxt.Text = string.format("waveBoost: %.2fx  volBoost +%.2f", w.waveBoost, w.volBoost)
						sunDot.Position = UDim2.new(0, 4 + (clockNow / 24) * 214, 0, 6)
					end)
					if not okin then ArkherAtmosX.UI_CONN:Disconnect() ArkherAtmosX.UI_CONN = nil end
				end)
			end)
		end
	end
	repaintKelvin()
end

ARKHER.reg("Lighting", "Lighting", "Scene", ICON.bulb, "Iluminacao custom: ciclo dia/noite Kelvin real + weather machine (ATMOS X)", build)
