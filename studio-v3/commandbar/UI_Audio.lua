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

ARKHER.open("Audio")
