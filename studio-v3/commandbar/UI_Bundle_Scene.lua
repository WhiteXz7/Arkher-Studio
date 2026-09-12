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
-- CAMERA STUDIO X — UI sobre o CAMERA X (ACX custom)
-- Shots fisicos (orbit/dolly/crane/follow/flypath Catmull-Rom),
-- SHAKE por trauma^2 (amplitude real de cinematografia), FADE real
-- via ColorCorrectionEffect, CINEMA (cortes em cadeia), editor de
-- flypath com canvas 2D top-view. Mexer = camera real. 🎬
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#D9A5FF"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#D9A5FF"))
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
	if not ArkherCameraX then ARKHER.note("Kit E nao carregado (CAMERA X ausente)") return end
	local ACX = ArkherCameraX

	local W, H = 700, 480
	local g, root = K.window("CameraStudio", "CAMERA STUDIO X — cinematografia custom (ACX custom)", 260, 150, W, H, { pin = true })

	local bodyH = H - 34 - 40

	-- ============ ESQUERDA: SHOTS ============
	local left = K.f(root, "L", 6, 34, 244, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "SHOTS (acao real na CurrentCamera)", 8, 4, 230, 14, 9, T.txt3)
	local shots = {
		{ nm = "ORBIT", d = "circula o alvo (raio/altura/velocidade)" },
		{ nm = "DOLLY IN", d = "dolly-in com easeInOut_sine" },
		{ nm = "DOLLY OUT", d = "dolly-out com easeOut_quad" },
		{ nm = "CRANE", d = "eleva no arco (dolly + lift)" },
		{ nm = "FLY PATH", d = "catmull-rom por 3 pontos" },
	}
	local function runShot(nm)
		local r = radiusS.get()
		local hgt = heightS.get()
		local dur = durS.get()
		if nm == "ORBIT" then
			ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = r, height = hgt, speed = spdS.get(), duration = 9999 })
		elseif nm == "DOLLY IN" then
			ACX.shot({ type = "dolly", from = Vector3.new(-r, hgt, -r), to = Vector3.new(-2, hgt, -2), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeInOut_sine" })
		elseif nm == "DOLLY OUT" then
			ACX.shot({ type = "dolly", from = Vector3.new(-2, hgt, -2), to = Vector3.new(-r, hgt, -r), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeOut_quad" })
		elseif nm == "CRANE" then
			ACX.shot({ type = "crane", from = Vector3.new(-r, 2, 0), to = Vector3.new(r, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = dur, lift = hgt })
		elseif nm == "FLY PATH" then
			ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = dur })
		end
	end
	for i, sh in ipairs(shots) do
		local y = 20 + (i - 1) * 44
		local b = K.btn(left, sh.nm, 8, y, 228, 26, C("#4A2E6E"), 6)
		K.txt(b, sh.nm, 10, 6, 100, 14, 9.5, T.txt)
		K.txt(left, sh.d, 10, y + 26, 224, 12, 8, T.txt3)
		b.MouseButton1Click:Connect(function() runShot(sh.nm) end)
	end
	local stopB = K.btn(left, "STOP", 8, 20 + 5 * 44, 110, 22, C("#7A2E2E"), 5)
	stopB.MouseButton1Click:Connect(function() ACX.stop() end)
	local cinemaB = K.btn(left, "CINEMA (3 cortes)", 124, 20 + 5 * 44, 112, 22, C("#2E4E7A"), 5)
	cinemaB.MouseButton1Click:Connect(function()
		ACX.cinema({
			{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = durS.get(), lift = 10 },
			{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
			{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
		})
	end)

	-- ============ CENTRO: PARAMS + FLY CANVAS + TRAUMA ============
	local center = K.f(root, "C", 258, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "PARAMETROS DO SHOT", 8, 4, 236, 14, 9, T.txt3)
	local radiusS = mkSlider(center, 8, 20, 226, "raio/dist", 4, 40, 14, function(v) return string.format("%.1f m", v) end)
	local heightS = mkSlider(center, 8, 62, 226, "altura", 1, 30, 7, function(v) return string.format("%.1f m", v) end)
	local spdS = mkSlider(center, 8, 104, 226, "vel. orbita (rad/s)", 0.05, 4.0, 0.5, function(v) return string.format("%.2f", v) end)
	local durS = mkSlider(center, 8, 146, 226, "duracao (s)", 0.5, 12.0, 4.0, function(v) return string.format("%.1f s", v) end)
	local faS = mkSlider(center, 8, 188, 226, "fly from (+/−)", -30, 30, -20, function(v) return string.format("%.0f", v) end)
	local fbS = mkSlider(center, 8, 230, 226, "fly to (+/−)", -30, 30, 20, function(v) return string.format("%.0f", v) end)
	K.txt(center, "FLY PATH (top view)", 8, 276, 236, 14, 9, T.txt3)
	local fcv = K.f(center, "FCV", 8, 294, 226, 130, C("#0A0F1A"))
	K.stroke(fcv, T.line, 1)
	-- desenha a curva catmull no canvas (pontos)
	local pathPts = {}
	for i = 0, 24 do
		local dot = K.f(fcv, "p" .. i, 4 + i * 9, 4, 3, 3, C("#D9A5FF"))
		pathPts[i] = dot
	end
	local function repaintPath()
		local a = { X = faS.get(), Y = 0, Z = faS.get() }
		local m = { X = 0, Y = 0, Z = 0 }
		local b = { X = fbS.get(), Y = 0, Z = fbS.get() }
		local n2 = { X = fbS.get() * 2, Y = 0, Z = fbS.get() * 2 }
		local cur = ACX.curve3(a, m, b, n2)
		for i = 0, 24 do
			local u = i / 24
			local px, py, pz = cur(u)
			pathPts[i].Position = UDim2.new(0, math.floor(((px + 30) / 60) * 226), 0, math.floor(((pz + 30) / 60) * 130))
		end
	end
	repaintPath()
	local playFlyB = K.btn(center, "PLAY FLY PATH", 8, 428, 106, 22, C("#4A2E6E"), 5)
	playFlyB.MouseButton1Click:Connect(function()
		ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = durS.get() })
	end)
	local updB = K.btn(center, "redesenhar curva", 122, 428, 108, 22, T.bg4, 5)
	updB.MouseButton1Click:Connect(function() repaintPath() end)

	-- ============ DIREITA: TRAUMA + FADE + STATS ============
	local right = K.f(root, "R", 516, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "TRAUMA (shake puro cinema)", 8, 4, 222, 14, 9, T.txt3)
	K.txt(right, "amplitude = trauma^2 * 0.35 rad", 8, 18, 222, 12, 8, T.txt3)
	local traumaS = mkSlider(right, 8, 34, 222, "trauma alvo", 0, 1, 0.5, function(v) return string.format("%.0f%%", v * 100) end)
	local bumpB = K.btn(right, "BUMP (+trauma)", 8, 78, 106, 22, C("#7A5A2E"), 5)
	bumpB.MouseButton1Click:Connect(function() ACX.addTrauma(traumaS.get()) end)
	local decBtn = K.btn(right, "4s tremendo", 122, 78, 108, 22, T.bg4, 5)
	decBtn.MouseButton1Click:Connect(function()
		ACX.addTrauma(1)
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 16, height = 6, speed = 0.4, duration = 9999 })
	end)
	K.txt(right, "FADE REAL (ColorCorrection)", 8, 112, 222, 14, 9, T.txt3)
	local fadeOutB = K.btn(right, "FADE OUT", 8, 128, 106, 22, C("#3A3A42"), 5)
	local fadeInB = K.btn(right, "FADE IN", 122, 128, 108, 22, C("#5A4A6E"), 5)
	fadeOutB.MouseButton1Click:Connect(function() ACX.fade(-1, 0.8) end)
	fadeInB.MouseButton1Click:Connect(function() ACX.fade(0, 0.8) end)
	K.txt(right, "CAMERA AO VIVO (pump)", 8, 162, 222, 14, 9, T.txt3)
	local posTxt = K.txt(right, "pos: —", 8, 178, 222, 14, 9, T.txt2)
	local modeTxt = K.txt(right, "modo: —", 8, 192, 222, 14, 9, T.txt2)
	local traumaTxt = K.txt(right, "trauma: —", 8, 206, 222, 14, 9, T.txt2)
	local traumaBar = K.f(right, "TB", 8, 226, 222, 8, C("#101827"))
	K.corner(traumaBar, 4)
	local traumaFill = K.f(traumaBar, "F", 0, 2, 4, 4, C("#7A2E2E"))
	K.corner(traumaFill, 2)
	K.txt(right, "CINEMATOGRAFIA", 8, 246, 222, 14, 9, T.txt3)
	K.txt(right, "Regra de terços: lookAt deslocado ", 8, 262, 222, 12, 8, T.txt3)
	K.txt(right, "automaticamente p/ (1/3, 2/3) do frame", 8, 274, 222, 12, 8, T.txt3)
	K.txt(right, "Collision: raycast puxa a camera pra", 8, 290, 222, 12, 8, T.txt3)
	K.txt(right, "dentro se parede atrapalhar (REAL)", 8, 302, 222, 12, 8, T.txt3)

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Camera Studio X atasao CAMERA X (shots reais, trauma, fades reais, cinema)")

	-- ============ HEARTBEAT pump ============
	if not ArkherCameraX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherCameraX.UI_CONN = RS.Heartbeat:Connect(function(dt)
					local okin = pcall(function()
						ACX.pump(dt or 1 / 60)
						ACX.pumpCinema()
						local c = workspace.CurrentCamera
						if c and c.CFrame and c.CFrame.Position then
							local p = c.CFrame.Position
							posTxt.Text = string.format("pos: %.1f  %.1f  %.1f", p.X, p.Y, p.Z)
						end
						modeTxt.Text = "modo: " .. tostring(ACX.S.mode) .. (ACX.S.shot and (" (" .. ACX.S.shot.type .. ")") or "")
						traumaTxt.Text = string.format("trauma: %.2f → shake %.3f rad", ACX.S.trauma, ACX.S.trauma ^ 2 * 0.35)
						traumaFill.Size = UDim2.new(0, math.floor(ACX.S.trauma * 222), 0, 4)
					end)
					if not okin then ArkherCameraX.UI_CONN:Disconnect() ArkherCameraX.UI_CONN = nil end
				end)
			end)
		end
	end
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Camera custom: shots fisicos, trauma shake, fades reais, cinema (CAMERA X)", build)
end

do
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
end

do
--[[ ARKHER — UI: AUDIO STUDIO X (motor AUX custom: mixer + DSP + scheduler) ]]
-- Mixer profissional de verdade: 7 buses SoundGroup REAIS, sliders FUNCIONAIS,
-- presets acusticos (caverna/estadio/estudio/subaquatico/radio/floresta/metal)
-- ligando efeitos DSP do engine (Reverb/Echo/Compressor/EQ/Distortion/Flange/
-- PitchShift), DUCKING sidechain de voz->musica com envelope demonstrado AO
-- VIVO, camadas de musica adaptativas (base/tension/combat + intensidade),
-- scheduler ambiente (never-repeat-2), posicional 3D com rolloff real e
-- doppler aproximado, links com AWX (ondas grandes => vento).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#B78CFF")
local AX = ArkherAudioX
local DM = ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local repaintStatus, repaintBusRows, repaintDuckBars, repaintLayerBars, repaintAmbLog, repaintPosVals
local showTab

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO STUDIO X — motor AUX (custom)", 90, 110, 720, 490, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)
	local W, H = 720, 490

	-- setup do motor (grupos REAIS)
	AX.setup()

	-- ================= ESQUERDA: BUSES =================
	local left = K.f(root, "Buses", 6, 34, 250, 490 - 34 - 40, T.bg3)
	K.txt(left, "BUSES (SoundGroups REAIS em SoundService)", 8, 4, 240, 14, 9, T.txt3)
	local busRows = K.f(left, "Rows", 4, 22, 242, 260, T.bg3)
	local buses = AX.BUSES
	local busSliders = {}
	for i, b in ipairs(buses) do
		local lbl = K.txt(busRows, b, 8, (i - 1) * 36 + 2, 70, 12, 9, T.txt)
		local envLbl = K.txt(busRows, "env: 1.00", 170, (i - 1) * 36 + 2, 70, 12, 7.5, T.txt3, nil, Enum.TextXAlignment.Right)
		busSliders[b] = mkSlider(busRows, 8, (i - 1) * 36 + 14, 220, "", 0, 2,
			AX.busVolume(b) or 1, function(v) return string.format("%.2f", v) end,
			function(v) AX.setBusVolume(b, v) repaintStatus() end)
		busSliders[b].envLbl = envLbl
	end
	K.txt(left, "duck env mostra o envelope atual (demonstracao abaixo)", 6, 268, 236, 12, 8, T.txt3)
	-- duck demo
	local duckState = K.txt(left, "DUCKING: voz -> musica (sidechain)", 6, 288, 240, 14, 9, T.txt)
	local duckBar = K.f(left, "DB", 6, 304, 250 - 12 - 4, 16, T.bg2)
	K.stroke(duckBar, T.line, 1)
	local duckFill = K.f(duckBar, "f", 0, 0, 10, 16, C("#63D68B"))
	local duckBtn = K.btn(left, "Tocar VOZ (duck musica)", 6, 326, 120, 20, C("#2D6BFF"))
	local duckStopB = K.btn(left, "Parar voz", 132, 326, 80, 20, T.bg4)
	local duckOn = false

	-- ================= CENTRO-DIREITA: TABS (DSP/AMBIENT/LAYERS/POSICIONAL) =================
	local tabs = K.tabs(root, 262, 30, 450, { "DSP presets", "Ambiente", "Camadas", "Posicional 3D" }, 1, function(i) showTab(i) end)
	local panelY = 58
	local panel = K.f(root, "Panel", 262, panelY, 450, 490 - panelY - 40, T.bg2)

	-- ---- ABA 1: DSP presets
	local p1 = K.f(panel, "P1", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p1, "Ligan efeitos DSP REAIS no SoundGroup (Roblox engine):", 8, 4, 430, 14, 9, T.txt3)
	local busSel = "music"
	local busPickB = K.btn(p1, "bus alvo: music", 8, 22, 120, 18, T.bg4)
	busPickB.MouseButton1Click:Connect(function()
		local order = AX.BUSES
		local i2 = 1
		for i, b in ipairs(order) do if b == busSel then i2 = i end end
		busSel = order[i2 % #order + 1]
		busPickB.Text = "bus alvo: " .. busSel
	end)
	local dspKeys = { "flat", "caverna", "estadio", "estudio", "subaquatico", "radio", "floresta", "metal" }
	local dspNames = { "Flat", "Caverna", "Estadio", "Estudio", "Subaquatico", "Radio/AM", "Floresta", "Metal/Flange" }
	for i, pid in ipairs(dspKeys) do
		local b = K.btn(p1, "FX_" .. pid, 8 + ((i - 1) % 2) * 150, 48 + math.floor((i - 1) / 2) * 28, 140, 22, T.bg3)
		K.txt(b, dspNames[i], 8, 5, 120, 12, 9, T.txt2)
		b.MouseButton1Click:Connect(function()
			local ok, n = AX.patch(busSel, pid)
			if ok then
				K.notify("Patch DSP", pid .. " em " .. busSel .. " — " .. n .. " efeito(s) ligado(s)", "ok")
			else
				K.notify("Patch falhou", tostring(n), "warn")
			end
			repaintStatus()
		end)
	end
	local clB = K.btn(p1, "Limpar bus (remover efeitos AUX)", 8, 48 + 4 * 28 + 6, 220, 20, C("#6E2B2B"))
	clB.MouseButton1Click:Connect(function() AX.clearPatch(busSel) K.notify("DSP limpo", busSel .. " sem efeitos AUX", "info") end)
	K.txt(p1, "efeitos disponiveis no motor: Reverb, Echo, Compressor, EQ, Distortion,", 8, 48 + 4 * 28 + 34, 420, 12, 8.5, T.txt3)
	K.txt(p1, "Flange, Tremolo, PitchShift — aplicados em cascata na bus, Dreamscape real.", 8, 48 + 4 * 28 + 48, 420, 12, 8.5, T.txt3)

	-- ---- ABA 2: AMBIENTE
	local p2 = K.f(panel, "P2", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p2, "SCHEDULER AMBIENTE (rodando mesmo sem assets: ids abstratos de slot)", 8, 4, 430, 14, 9, T.txt3)
	local ambs = {}
	local ambRows = K.f(p2, "Rows", 6, 24, 450 - 12, 150, T.bg2)
	-- schedule pre-montado: floresta / mar / cidade / vulcao noturno
	local SPECS = {
		{ nm = "floresta", ids = { "amb_passaros", "amb_folhas", "amb_rio_longe", "amb_insetos" }, interval = { 12, 30 }, bus = "ambient" },
		{ nm = "mar", ids = { "amb_onda_fraca", "amb_onda_forte", "amb_gaivota" }, interval = { 10, 26 }, bus = "weather", minAmpLink = true },
		{ nm = "cidade", ids = { "amb_traffic", "amb_sirene_longe", "amb_vento_predios", "amb_vozes" }, interval = { 14, 38 }, bus = "ambient" },
		{ nm = "noite_vulcao", ids = { "amb_trovao", "amb_galho_seco", "amb_coruja", "amb_rajada" }, interval = { 20, 60 }, bus = "weather" },
	}
	local ambBtns = {}
	for i, sp in ipairs(SPECS) do
		K.txt(ambRows, sp.nm .. "  (" .. #sp.ids .. " ids)", 6, (i - 1) * 34 + 2, 200, 12, 9, T.txt)
		K.txt(ambRows, "int " .. sp.interval[1] .. "-" .. sp.interval[2] .. "s  bus " .. sp.bus, 6, (i - 1) * 34 + 16, 220, 10, 8, T.txt3)
		local goB = K.btn(ambRows, "▶", 240, (i - 1) * 34, 32, 20, C("#3F9E58"))
		local stopB = K.btn(ambRows, "■", 278, (i - 1) * 34, 32, 20, C("#A93B3B"))
		local st = K.txt(ambRows, "off", 320, (i - 1) * 34 + 5, 60, 12, 8, T.txt3)
		ambBtns[sp.nm] = st
		goB.MouseButton1Click:Connect(function()
			if not AX._ambients[sp.nm] then
				AX.ambient(sp.nm, { ids = sp.ids, interval = sp.interval, bus = sp.bus, volume = { 0.2, 0.55 } })
			end
			if sp.minAmpLink then AX.linkSea((ARKHER._sea or WX_SEA()), "mar", { minAmp = 0.5 }) end
			AX._ambients[sp.nm]:start()
			st.Text = "ON"
			st.TextColor3 = C("#63D68B")
			repaintStatus()
		end)
		stopB.MouseButton1Click:Connect(function()
			if AX._ambients[sp.nm] then AX._ambients[sp.nm]:stop() end
			st.Text = "off"
			st.TextColor3 = T.txt3
		end)
	end
	K.txt(p2, "ultimos disparos:", 6, 186, 140, 14, 9, T.txt3)
	local ambLog = K.f(p2, "Log", 6, 202, 450 - 12, 120, T.bg2)
	K.stroke(ambLog, T.line, 1)

	-- ---- ABA 3: CAMADAS
	local p3 = K.f(panel, "P3", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p3, "MUSICA ADAPTATIVA — 3 camadas (base / tensao / combate), crossfade REAL via pump", 8, 4, 440, 14, 9, T.txt3)
	-- registra 3 loops demo (sem asset real: slots nomeados — em produção voce coloca rbxassetid)
	AX.register("mus_base", { bus = "music", volume = 0.5, looped = true })
	AX.register("mus_tension", { bus = "music", volume = 0.5, looped = true })
	AX.register("mus_combat", { bus = "music", volume = 0.5, looped = true })
	local layInitB = K.btn(p3, "START layers", 8, 24, 110, 20, C("#3F9E58"))
	local layStopB = K.btn(p3, "STOP layers", 124, 24, 110, 20, T.bg4)
	local intS = mkSlider(p3, 8, 60, 260, "Intensidade", 0, 2, 0, function(v) return string.format("%.2f", v) end, function(v) AX.setIntensity(v) end)
	local layerBars = K.f(p3, "Bars", 8, 110, 270, 80, T.bg2)
	K.stroke(layerBars, T.line, 1)
	local lbar = {}
	for i, role in ipairs({ "base", "tension", "combat" }) do
		K.txt(layerBars, role, 8, (i - 1) * 24 + 4, 60, 12, 8.5, T.txt3)
		lbar[role] = K.f(layerBars, "b_" .. role, 70, (i - 1) * 24 + 5, 4, 12, (i == 1 and C("#63D68B") or i == 2 and C("#FFC453") or C("#FF5E5E")))
	end
	K.txt(p3, "int 0=no pacato (base 100%) | 1=tensao | 2=combate", 8, 196, 400, 12, 8, T.txt3)
	layInitB.MouseButton1Click:Connect(function()
		AX.musicLayers({ base = "mus_base", tension = "mus_tension", combat = "mus_combat" })
		K.notify("Layers", "3 camadas de musica iniciadas (base/tensao/combate)", "ok")
	end)
	layStopB.MouseButton1Click:Connect(function()
		AX.stop("mus_base") AX.stop("mus_tension") AX.stop("mus_combat")
		K.notify("Layers paradas", "music loops stop", "info")
	end)

	-- ---- ABA 4: POSICIONAL 3D
	local p4 = K.f(panel, "P4", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p4, "POSICIONAL 3D SIMULADO — rolloff inverso-quadratico + doppler aproximado", 8, 4, 440, 14, 9, T.txt3)
	local posState = { tr = nil }
	local bindPosB = K.btn(p4, "Criar emissor posicional ('vento')", 8, 26, 220, 20, C("#2D6BFF"))
	local posVals = {
		dist = K.txt(p4, "dist: —", 8, 60, 200, 14, 9, T.txt),
		vol = K.txt(p4, "vol efetivo: —", 8, 80, 200, 14, 9, T.txt),
		pitch = K.txt(p4, "doppler pitch: —", 8, 100, 200, 14, 9, T.txt),
	}
	local refS = mkSlider(p4, 8, 126, 260, "Ref dist", 2, 40, 12, function(v) return string.format("%.0f", v) end, function(v) if posState.tr then posState.tr.refDist = v end end)
	local maxS = mkSlider(p4, 8, 160, 260, "Max dist", 40, 400, 120, function(v) return string.format("%.0f", v) end, function(v) if posState.tr then posState.tr.maxDist = v end end)
	local demoPos = Vector3.new(24, 3, 24)
	bindPosB.MouseButton1Click:Connect(function()
		AX.register("vento", { bus = "weather", volume = 0.6 })
		AX.play("vento", { volume = 0.6 })
		posState.tr = AX.positional("vento", function() return demoPos end, { refDist = refS.get(), maxDist = maxS.get(), volume = 0.6 })
		K.notify("Emissor posicional", "'vento' em (24,3,24) — afaste a camera p/ ouvir cair", "ok")
	end)
	-- doppler check: mover o emissor circular para demonstrar
	local demoAng = 0

	-- ================= STATUS =================
	local stat = K.txt(root, "", 8, H - 36, W - 16, 14, 9, T.txt3)

	-- ================= PAINT FNS =================
	repaintStatus = function()
		local st = AX.stats()
		stat.Text = string.format("buses %d | sons registrados %d (%d playing) | ducks %d | ambients %d | posicionais %d %s",
			st.buses, st.sounds, st.playing, st.ducks, st.ambients, st.positional,
			(st.layers ~= nil) and string.format("| intensidade musica %.2f", st.layers) or "")
	end
	repaintDuckBars = function()
		-- envelope atual da duck voz->musica
		for _, d in ipairs(AX._ducks) do
			if d.trigger == "voice" and d.target == "music" then
				duckFill.Size = UDim2.new(0, math.floor((1 - (d.env or 1)) * math.max(duckBar.AbsoluteSize.X, 10)), 1, 0)
			end
		end
	end
	repaintLayerBars = function()
		if AX._layers then
			local int = AX._layers.intensity or 0
			local map = {
				base = DM.clamp(1 - int, 0.25, 1),
				tension = DM.clamp(1 - math.abs(int - 1), 0, 1),
				combat = DM.clamp(int - 1, 0, 1),
			}
			for role, bar in pairs(lbar) do
				bar.Size = UDim2.new(0, math.floor(map[role] * 180) + 4, 0, 12)
			end
		end
	end
	repaintAmbLog = function()
		for _, ch in ipairs(ambLog:GetChildren()) do ch:Destroy() end
		local fires = AX._fires or {}
		for i = math.max(1, #fires - 6), #fires do
			local f = fires[i]
			if f then K.txt(ambLog, "• " .. f.name .. " @ " .. string.format("%.1f", f.t or 0), 6, (i - math.max(1, #fires - 6)) * 17 + 3, 410, 12, 8, C("#9BB1FF")) end
		end
	end
	local camGet = function()
		local ws = game:FindFirstChild("Workspace")
		local cam = ws and ws.CurrentCamera
		if cam and cam.CFrame then return cam.CFrame.Position end
		return nil
	end
	repaintPosVals = function()
		local cp = camGet()
		if cp and posState.tr then
			local dx, dy, dz = cp.X - demoPos.X, cp.Y - demoPos.Y, cp.Z - demoPos.Z
			local d = math.sqrt(dx * dx + dy * dy + dz * dz)
			posVals.dist.Text = string.format("dist: %.1f m", d)
			local g = DM.clamp((posState.tr.refDist / math.max(d, posState.tr.refDist)) ^ 2, 0, 1)
			if d > posState.tr.maxDist then g = 0 end
			posVals.vol.Text = string.format("vol efetivo: %.3f", posState.tr.baseVol * g)
		end
		local reg = AX._sounds["vento"]
		if reg then posVals.pitch.Text = string.format("doppler pitch: %.2f", reg.inst.PlaybackSpeed or 1) end
	end
	repaintBusRows = function()
		for b, sl in pairs(busSliders) do
			if sl.envLbl then
				local g = AX._groups and AX._groups[b]
				local v = g and g.Volume or AX.busVolume(b) or 1
				sl.envLbl.Text = string.format("env: %.2f", v)
			end
		end
	end

	-- duck demo buttons (mono: registramos os sons 'voice_demo'/'musica_demo')
	AX.register("voice_demo", { bus = "voice", volume = 0.6 })
	AX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	AX.duck("music", "voice", { level = 0.3, attack = 0.08, release = 0.9, hold = 0.6 })
	duckBtn.MouseButton1Click:Connect(function()
		AX.play("musica_demo", { volume = 0.5 })
		AX.play("voice_demo", { volume = 0.6 })
		duckOn = true
		duckState.Text = "DUCKING ATIVO — musica cai p/ 30%"
		repaintStatus()
	end)
	duckStopB.MouseButton1Click:Connect(function()
		AX.stop("voice_demo")
		duckOn = false
		duckState.Text = "voz off — musica volta (release 0.9s)"
	end)

	-- tab switching
	local panels = { p1, p2, p3, p4 }
	showTab = function(i)
		for j, p in ipairs(panels) do p.Visible = (j == i) end
	end
	showTab(1)

	-- ================= PUMP LOOP =================
	pcall(function()
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			AX.pump(dt)
			-- demo doppler circular
			if posState.tr then
				demoAng = demoAng + dt * 0.9
				demoPos = Vector3.new(24 + math.cos(demoAng) * 10, 3, 24 + math.sin(demoAng) * 10)
			end
			local ac = (g._acc or 0) + dt
			g._acc = ac
			if ac > 0.12 then
				g._acc = 0
				repaintStatus()
				repaintDuckBars()
				repaintLayerBars()
				repaintBusRows()
				repaintPosVals()
				repaintAmbLog()
			end
		end)
	end)

	-- ================= BOOT =================
	repaintStatus()
	return g
end

-- helper global p/ link mar (AWX)
WX_SEA = function()
	if ARKHER._sea then return ARKHER._sea end
	if ArkherWaterX then
		ARKHER._sea = ArkherWaterX.preset("porto", { kind = "oceano", level = 0, size = { x = 300, z = 300 } })
		return ARKHER._sea
	end
	return nil
end

ARKHER.reg("Audio", "Audio Studio X", "Scene", ICON.data, "Audio custom (AUX): SoundGroups, DSP presets, ducking, scheduler, layers adaptativas, 3D", build)
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
--[[ ARKHER — UI: UI STUDIO (designer de UI de jogos, engine ArkherUIKitX) ]]
-- Designer profissional: paleta com 42 widgets reais (base/input/display/HUD/
-- menu), canvas com grade e DRAG DE VERDADE (move/redimensiona), snap, inspector
-- numerico vivo, 9 presets de ancora, alinhar/distribuir multi-selecao, 6 temas
-- aplicaveis, camadas, import/export REAL (ScreenGui no StarterGui + ModuleScript
-- de codigo + controller de eventos).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")
local X = ArkherUIKitX
local UserInputService = game:GetService("UserInputService")

local function build()
	local g, root, head = K.window("ArkherUIDesigner", "UI STUDIO — designer de UI de jogos", 30, 300, 720, 520, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)

	-- ================= ESTADO =================
	local items = {} -- {root, kind, meta{x,y,w,h,opts}}
	local selected = {}
	local snap = true
	local SNAP = 4
	local status = nil
	local canvas = nil
	local devW, devH = 960, 540
	local selBox, selHandle = nil, nil
	local layersBody = nil
	local inspectorBody = nil
	-- pre-declarados (closures cruzadas)
	local addWidget, refreshInspector, refreshLayers, refreshSelBox

	local function snapV(v) return snap and (math.floor(v / SNAP) * SNAP) or math.floor(v) end
	local function isSel(it)
		for _, s in ipairs(selected) do if s == it then return true end end
		return false
	end
	local function syncItem(it)
		it.root.Position = UDim2.fromOffset(snapV(it.meta.x), snapV(it.meta.y))
		it.root.Size = UDim2.fromOffset(it.meta.w, it.meta.h)
	end

	-- ================= PALETA (42 widgets, paged, por categoria) =================
	local pal = K.f(root, "Pal", 8, 34, 132, 432, T.bg4)
	K.corner(pal, 4)
	local CATS = { "Base", "Input", "Display", "HUD", "Menu" }
	local palCat = 1
	local palPage = 0
	local palBody = K.f(pal, "PB", 4, 48, 124, 378)
	local palBtns = {}
	local repaintPal = nil
	for i, nm in ipairs(CATS) do
		local b = K.btn(pal, "C" .. i, 4 + (i - 1) * 26, 6, 24, 18, T.bg4, 3)
		K.txtS(b, nm:sub(1, 2), 8, i == palCat and ACCENT or T.txt3)
		local idx = i
		b.MouseButton1Click:Connect(function()
			palCat = idx
			palPage = 0
			repaintPal()
		end)
		palBtns[i] = b
	end
	local palNext = K.btn(pal, "Next", 70, 26, 58, 18, T.bg2, 3)
	K.txtS(palNext, "mais >", 8, T.txt3)
	local palPrev = K.btn(pal, "Prev", 6, 26, 58, 18, T.bg2, 3)
	K.txtS(palPrev, "< ant", 8, T.txt3)
	palPrev.MouseButton1Click:Connect(function() palPage = math.max(0, palPage - 1) repaintPal() end)
	palNext.MouseButton1Click:Connect(function() palPage = palPage + 1 repaintPal() end)

	local catalog = X.catalog()
	repaintPal = function()
		palBody:ClearAllChildren()
		for j, b in ipairs(palBtns) do
			b.BackgroundColor3 = j == palCat and T.bg2 or T.bg4
		end
		local list = catalog[CATS[palCat]] or {}
		local PER = 18
		palPage = math.min(palPage, math.max(0, math.ceil(#list / PER) - 1))
		local base = palPage * PER
		for i = 1, PER do
			local w = list[base + i]
			if not w then break end
			local b = K.btn(palBody, "W" .. i, 0, (i - 1) * 20, 122, 18, T.bg2, 3)
			K.txt(b, (w.nm), 6, 2, 112, 14, 9, T.txt)
			K.hover(b, T.bg2, T.hover)
			local id = w.id
			b.MouseButton1Click:Connect(function() addWidget(id) end)
		end
	end

	-- ================= CANVAS COM GRADE =================
	local cvX, cvY, cvW, cvH = 148, 34, 400, 432
	canvas = K.f(root, "Canvas", cvX, cvY, cvW, cvH, T.bg0)
	K.corner(canvas, 4)
	K.stroke(canvas, T.line, 1)
	canvas.ClipsDescendants = true
	-- device frame interno (viewport da tela alvo)
	local devScaleX, devScaleY = (cvW - 16) / devW, (cvH - 16) / devH
	local devScale = math.min(devScaleX, devScaleY)
	local devFrame = K.f(canvas, "Device", 8, 8, math.floor(devW * devScale), math.floor(devH * devScale), C("#101A2C"))
	K.corner(devFrame, 3)
	K.stroke(devFrame, T.line2, 1)
	-- grade
	for i = 1, 19 do K.f(devFrame, "gx" .. i, math.floor(i * devFrame.Size.X.Offset / 20), 0, 1, devFrame.Size.Y.Offset, C("#16233C")) end
	for i = 1, 11 do K.f(devFrame, "gy" .. i, 0, math.floor(i * devFrame.Size.Y.Offset / 12), devFrame.Size.X.Offset, 1, C("#16233C")) end
	local devLbl = K.txt(canvas, "960x540 (Desktop)", cvW - 130, cvH - 16, 126, 12, 8, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Right)

	-- escala canvas->tela
	local function toCanvas(x, y) return x * devScale, y * devScale end

	-- selecao: caixa + handle
	selBox = K.f(devFrame, "SelBox", 0, 0, 10, 10)
	selBox.BackgroundTransparency = 1
	K.stroke(selBox, ACCENT, 1.5)
	selBox.Visible = false
	selHandle = K.btn(devFrame, "SelHandle", 0, 0, 12, 12, ACCENT, 2)
	selHandle.Visible = false

	refreshLayers = function() end -- (camadas exibidas via selecao/inspector)

	local function setSelection(list)
		selected = list
		refreshSelBox()
		refreshInspector()
		refreshLayers()
	end

	refreshSelBox = function()
		if #selected == 0 then selBox.Visible = false selHandle.Visible = false return end
		local it = selected[#selected]
		local x, y = toCanvas(it.meta.x, it.meta.y)
		local w, h = it.meta.w * devScale, it.meta.h * devScale
		selBox.Visible = true
		selBox.Position = UDim2.fromOffset(math.floor(x) - 2, math.floor(y) - 2)
		selBox.Size = UDim2.fromOffset(math.floor(w) + 4, math.floor(h) + 4)
		selHandle.Visible = true
		selHandle.Position = UDim2.fromOffset(math.floor(x + w) - 4, math.floor(y + h) - 4)
	end

	-- drag de mover (widget) e resize (handle)
	local drag = nil
	local function canvasPosOfInput(inp)
		return inp.Position.X - devFrame.AbsolutePosition.X, inp.Position.Y - devFrame.AbsolutePosition.Y
	end
	UserInputService.InputChanged:Connect(function(inp)
		if not drag then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		local mx, my = canvasPosOfInput(inp)
		if drag.mode == "move" then
			for _, d in ipairs(drag.list) do
				d.it.meta.x = snapV(d.x0 + (mx - drag.mx0) / devScale)
				d.it.meta.y = snapV(d.y0 + (my - drag.my0) / devScale)
				local cx2, cy2 = toCanvas(d.it.meta.x, d.it.meta.y)
				d.it.root.Position = UDim2.fromOffset(cx2, cy2)
			end
			refreshSelBox()
			refreshInspector()
		elseif drag.mode == "resize" then
			local it = drag.list[1].it
			it.meta.w = math.max(20, snapV(drag.list[1].w0 + (mx - drag.mx0) / devScale))
			it.meta.h = math.max(14, snapV(drag.list[1].h0 + (my - drag.my0) / devScale))
			local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
			it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale)
			refreshSelBox()
			refreshInspector()
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
	end)
	selHandle.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local it = selected[#selected]
		if not it then return end
		local mx, my = canvasPosOfInput(inp)
		drag = { mode = "resize", mx0 = mx, my0 = my, list = { { it = it, w0 = it.meta.w, h0 = it.meta.h } } }
	end)

	local function mountItem(it)
		-- meta.x/y em coords de TELA (device); cria posicionado no devFrame
		local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
		it.root.Position = UDim2.fromOffset(cx2, cy2)
		it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale)
		it.root:SetAttribute("wkind", it.kind)
		it.root.Parent = devFrame
		if it.root:IsA("GuiObject") then
			it.root.InputBegan:Connect(function(inp)
				if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not isSel(it) then setSelection({ it }) end
				local mx, my = canvasPosOfInput(inp)
				local list = {}
				for _, s in ipairs(selected) do list[#list + 1] = { it = s, x0 = s.meta.x, y0 = s.meta.y } end
				if #list == 0 then list[1] = { it = it, x0 = it.meta.x, y0 = it.meta.y } end
				drag = { mode = "move", mx0 = mx, my0 = my, list = list }
			end)
		end
	end

	addWidget = function(id, meta)
		local meta2 = meta or { x = math.floor(devW / 2 - 60), y = math.floor(devH / 2 - 20) }
		local w, err = X.create(id, meta2)
		if not w then
			if status then status.Text = "erro: " .. tostring(err) end
			return
		end
		w.meta.x, w.meta.y = meta2.x, meta2.y
		if meta2.w then w.meta.w = meta2.w end
		if meta2.h then w.meta.h = meta2.h end
		if meta2.text then w.meta.opts.text = meta2.text end
		items[#items + 1] = w
		mountItem(w)
		setSelection({ w })
		if status then status.Text = "+" .. id .. " (" .. X.WIDGETS[id].nm .. ") no canvas" end
	end
	repaintPal()

	-- ================= CAMADAS / INSPECTOR (direita) =================
	local right = K.f(root, "Right", 556, 34, 156, 432, T.bg4)
	K.corner(right, 4)
	K.txt(right, "INSPECTOR", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	inspectorBody = K.f(right, "IB", 6, 24, 144, 250)

	local function stepper(parent, y, label, get, set, lo, hi)
		K.txt(parent, label, 4, y, 40, 14, 9, T.txt3)
		local minus = K.btn(parent, "M", 44, y - 2, 18, 16, T.bg2, 3)
		K.txtS(minus, "-", 10, T.txt)
		local plus2 = K.btn(parent, "P", 122, y - 2, 18, 16, T.bg2, 3)
		K.txtS(plus2, "+", 10, T.txt)
		local val = K.txt(parent, tostring(get()), 64, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Center)
		local function re() val.Text = tostring(get()) end
		minus.MouseButton1Click:Connect(function() set(math.max(lo or -99999, get() - SNAP * 2)) re() end)
		plus2.MouseButton1Click:Connect(function() set(math.min(hi or 99999, get() + SNAP * 2)) re() end)
		return re
	end

	refreshInspector = function()
		inspectorBody:ClearAllChildren()
		local it = selected[#selected]
		if not it then K.txt(inspectorBody, "nada selecionado", 4, 2, 130, 14, 9, T.txt4) return end
		K.txt(inspectorBody, it.kind, 4, 2, 130, 16, 11, ACCENT, ARKHER.FONTB)
		stepper(inspectorBody, 30, "X", function() return it.meta.x end, function(v) it.meta.x = v syncItem(it) local cx2, cy2 = toCanvas(v, it.meta.y) it.root.Position = UDim2.fromOffset(cx2, cy2) refreshSelBox() end)
		stepper(inspectorBody, 56, "Y", function() return it.meta.y end, function(v) it.meta.y = v syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, v) it.root.Position = UDim2.fromOffset(cx2, cy2) refreshSelBox() end)
		stepper(inspectorBody, 82, "Larg", function() return it.meta.w end, function(v) it.meta.w = math.max(20, v) syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, it.meta.y) it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale) refreshSelBox() end)
		stepper(inspectorBody, 108, "Alt", function() return it.meta.h end, function(v) it.meta.h = math.max(14, v) syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, it.meta.y) it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale) refreshSelBox() end)
		-- ancoras 3x3
		K.txt(inspectorBody, "ANCORA", 4, 136, 90, 12, 9, T.txt3, ARKHER.FONTB)
		local anames = { "sup_esq", "sup_centro", "sup_dir", "meio_esq", "centro", "meio_dir", "inf_esq", "inf_centro", "inf_dir" }
		for i, an in ipairs(anames) do
			local b = K.btn(inspectorBody, "A" .. i, 4 + ((i - 1) % 3) * 46, 152 + math.floor((i - 1) / 3) * 20, 44, 17, T.bg2, 3)
			K.txtS(b, "", 8, T.txt4)
			local dot = K.f(b, "d", 17 + ((i - 1) % 3) * 4 - 4, 5 + math.floor((i - 1) / 3) * 3, 6, 6, ACCENT, 3)
			local aname = an
			b.MouseButton1Click:Connect(function()
				X.anchorPreset(it, aname, devW, devH)
				local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
				it.root.Position = UDim2.fromOffset(cx2, cy2)
				refreshSelBox()
				refreshInspector()
				if status then status.Text = "ancorado: " .. aname end
			end)
		end
	end

	-- multi-selecao por botoes de acao rapida
	local actRow = K.f(right, "Acts", 6, 280, 144, 64)
	local delB = K.btn(actRow, "Del", 0, 0, 70, 22, C("#5A2830"), 4)
	K.txtS(delB, "Excluir", 9, C("#FFB0B8"))
	local dupB = K.btn(actRow, "Dup", 74, 0, 70, 22, T.bg2, 4)
	K.txtS(dupB, "Duplicar", 9, T.txt)
	delB.MouseButton1Click:Connect(function()
		local n = 0
		for _, it in ipairs(selected) do
			for i = #items, 1, -1 do if items[i] == it then table.remove(items, i) end end
			it.root:Destroy()
			n = n + 1
		end
		setSelection({})
		if status then status.Text = n .. " widget(s) excluido(s)" end
	end)
	dupB.MouseButton1Click:Connect(function()
		local it = selected[#selected]
		if it then
			addWidget(it.kind, { x = it.meta.x + 16, y = it.meta.y + 16, w = it.meta.w, h = it.meta.h, text = it.meta.opts and it.meta.opts.text })
		end
	end)
	-- alinhar/distribuir
	K.txt(right, "ALINHAR (multi)", 10, 348, 130, 12, 9, T.txt3, ARKHER.FONTB)
	local alignBtns = {
		{ "Esq", function() return X.alignLeft(selected) end }, { "Cen", function() return X.alignHCenter(selected) end },
		{ "Dir", function() return X.alignRight(selected) end }, { "Top", function() return X.alignTop(selected) end },
		{ "Base", function() return X.alignBottom(selected) end }, { "DistH", function() return X.distributeH(selected) end },
		{ "DistV", function() return X.distributeV(selected) end },
	}
	for i, a in ipairs(alignBtns) do
		local b = K.btn(right, "AL" .. i, 8 + ((i - 1) % 3) * 48, 364 + math.floor((i - 1) / 3) * 22, 44, 19, T.bg2, 3)
		K.txtS(b, a[1], 8, T.txt2)
		K.hover(b, T.bg2, T.hover)
		local fn = a[2]
		local nm = a[1]
		b.MouseButton1Click:Connect(function()
			if #selected == 0 then
				-- sem selecao: aplica em todos (atalho pro)
				selected = items
			end
			local n = fn()
			for _, it in ipairs(items) do
				local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
				it.root.Position = UDim2.fromOffset(cx2, cy2)
			end
			refreshSelBox()
			if status then status.Text = nm .. ": " .. n .. " widgets alinhados" end
		end)
	end
	local selAll = K.btn(right, "SelAll", 8, 412, 140, 20, T.bg2, 4)
	K.txtS(selAll, "Selecionar todos", 9, T.txt)
	selAll.MouseButton1Click:Connect(function() setSelection(items) end)

	-- ================= BARRA INFERIOR: EXPORT / TEMA / DEVICE =================
	local bar = K.f(root, "Bar", 8, 474, 704, 38, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "42 widgets na paleta — clique p/ adicionar, arraste p/ mover", 10, 4, 330, 14, 9, T.txt3)
	-- tema
	local themeIds = { "arkher", "neon", "light", "forest", "sunset", "glass" }
	local themeIdx = 1
	local themeB = K.btn(bar, "Theme", 348, 8, 80, 22, T.bg2, 4)
	K.txtS(themeB, "Tema: arkher", 8, T.txt)
	K.hover(themeB, T.bg2, T.hover)
	themeB.MouseButton1Click:Connect(function()
		themeIdx = (themeIdx % #themeIds) + 1
		local th = X.setTheme(themeIds[themeIdx])
		themeB:FindFirstChildOfClass("TextLabel").Text = "Tema: " .. themeIds[themeIdx]
		-- recria todos os widgets com o tema novo
		local saved = {}
		for i, it in ipairs(items) do saved[i] = { kind = it.kind, meta = it.meta } it.root:Destroy() end
		items = {}
		setSelection({})
		for _, s in ipairs(saved) do addWidget(s.kind, s.meta) end
		status.Text = "tema '" .. th.nm .. "' aplicado a TODOS os widgets"
		setSelection({})
	end)
	-- device
	local devs = {
		{ nm = "Desktop", w = 960, h = 540 }, { nm = "HD", w = 1280, h = 720 },
		{ nm = "Phone", w = 390, h = 844 }, { nm = "Tablet", w = 820, h = 1180 },
	}
	local devIdx = 1
	local devB = K.btn(bar, "Dev", 436, 8, 80, 22, T.bg2, 4)
	K.txtS(devB, "Tela: Desktop", 8, T.txt)
	K.hover(devB, T.bg2, T.hover)
	devB.MouseButton1Click:Connect(function()
		devIdx = (devIdx % #devs) + 1
		local d = devs[devIdx]
		devW, devH = d.w, d.h
		status.Text = "tela alvo: " .. d.nm .. " (" .. d.w .. "x" .. d.h .. ") — reabra p/ re-escalar"
		devB:FindFirstChildOfClass("TextLabel").Text = "Tela: " .. d.nm
		devLbl.Text = d.w .. "x" .. d.h .. " (" .. d.nm .. ")"
	end)
	-- export real
	local expB = K.btn(bar, "Exp", 524, 8, 84, 22, ACCENT, 4)
	K.txtS(expB, "Exportar GUI", 9, C("#041820"))
	K.hover(expB, ACCENT, C("#7DEBFF"))
	expB.MouseButton1Click:Connect(function()
		local gui, n = X.build(items, "ArkherHUD")
		-- o build re-parenta as raizes; devolve ao canvas para continuar editando
		for _, it in ipairs(items) do mountItem(it) end
		refreshSelBox()
		status.Text = "ScreenGui 'ArkherHUD' com " .. n .. " widgets no StarterGui (export REAL — canvas preservado)"
		K.notify("UI exportada", n .. " widgets → StarterGui.ArkherHUD", "ok")
	end)
	local codeB = K.btn(bar, "Code", 614, 8, 88, 22, T.bg2, 4)
	K.txtS(codeB, "Export codigo", 9, T.txt)
	K.hover(codeB, T.bg2, T.hover)
	codeB.MouseButton1Click:Connect(function()
		local src = X.exportModule(items, "ArkherUI_HUD")
		local ctrl = X.exportController(items, "ArkherUI_Controller")
		local ok2, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
		if ok2 and rs then
			local m = rs:FindFirstChild("ArkherUI_HUD")
			if not m then m = Instance.new("ModuleScript") m.Name = "ArkherUI_HUD" m.Parent = rs end
			m.Source = src
			local m2 = rs:FindFirstChild("ArkherUI_Controller")
			if not m2 then m2 = Instance.new("ModuleScript") m2.Name = "ArkherUI_Controller" m2.Parent = rs end
			m2.Source = ctrl
		end
		pcall(function() if game.WriteFile then game:WriteFile("ArkherUI/ArkherUI_HUD.lua", src) end end)
		status.Text = "codigo exportado: ReplicatedStorage.ArkherUI_HUD + _Controller (" .. #src .. " chars)"
	end)
	-- import
	local impB = K.btn(bar, "Imp", 8, 20, 0, 0, T.bg0)
	impB.Visible = false
	K.txt(bar, "snap " .. SNAP .. "px", 10, 20, 60, 12, 7, T.txt4)
	local snapB = K.btn(bar, "Snap", 76, 20, 54, 14, T.bg2, 3)
	K.txtS(snapB, "snap:on", 7, T.txt3)
	snapB.MouseButton1Click:Connect(function()
		snap = not snap
		snapB:FindFirstChildOfClass("TextLabel").Text = snap and "snap:on" or "snap:off"
	end)

	setSelection({})
end

ARKHER.reg("UIDesigner", "UI Studio", "Editor", ICON.plate, "Designer de UI de jogos: 42 widgets, drag real, temas, ancoras, alinhar, export ScreenGui+codigo", build)
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
ARKHER.out("SUCCESS", "ARKHER V4 — bundle Scene: " .. opened .. " UIs abertas")
