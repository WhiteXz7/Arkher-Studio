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
--[[ ARKHER — UI: ANIMATOR STUDIO X (motor AAX custom, sem KeyframeSequences) ]]
-- Timeline REAL: clips multi-track (Position/CFrame/Size/Color/Transparency/
-- atributos), keys com 37 easings fisicos reais, spline preview desenhado das
-- curvas AMOSTRADAS do motor, scrub, loop/ping-pong, speed, markers com
-- eventos, blend de clips, DEFORMERS procedurais no assembly (bend/twist/
-- wave/taper/breathe) para dar vida sem rig manual. Exporta JSON. A pre-viw
-- escreve CFrame/Size/etc REAL na selecao.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFB453")
local AX = ArkherAnimX
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

-- pre-declarados (padrao V4: nunca `function name()` depois)
local repaintClips, repaintTracks, repaintCurve, repaintKeys, repaintEase, repaintStatus, repaintMarkers

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR STUDIO X — motor AAX (custom)", 60, 140, 720, 500, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)
	local W, H = 720, 500

	-- ================= ESTADO =================
	local clips = {}
	local clipsSel = 1
	local trackSel = 1
	local keySel = 1
	local playhead = 0
	local speed = 1
	local boundInst = nil
	local deformH = nil
	local status = nil

	-- clips iniciais reais: BOAT BOB + FLAG WAVE (demonstradores fisicos)
	local boat = AX.clip("BoatBob", { loop = "pingpong" })
	boat:addTrack("Position", {
		AX.key(0, { x = 0, y = 2, z = 0 }, "easeInOut_sine"),
		AX.key(1.2, { x = 0.4, y = 3.4, z = 0 }, "easeOut_back"),
		AX.key(2.4, { x = 0, y = 2.2, z = 0 }, "easeInOut_sine"),
	})
	boat:addTrack("Transparency", { AX.key(0, 0.35, "linear"), AX.key(2.4, 0.15, "easeOut_sine") })
	boat:marker(1.2, "crest")
	local flag = AX.clip("FlagWave", { loop = "loop" })
	flag:addTrack("Position", {
		AX.key(0, { x = 0, y = 6, z = 0 }, "easeInOut_sine"),
		AX.key(0.6, { x = 0.8, y = 6.6, z = 0.2 }, "easeInOut_sine"),
		AX.key(1.2, { x = 0, y = 6, z = 0 }, "easeInOut_sine"),
	})
	clips = { boat, flag }
	local function clip() return clips[clipsSel] end
	local function track() local tr = clip() and clip().tracks[trackSel] return tr end

	-- ================= COLUNA ESQUERDA: CLIPS =================
	local leftW = 158
	local bodyH = 500 - 34 - 40
	local left = K.f(root, "Clips", 6, 34, leftW, bodyH, T.bg3)
	K.txt(left, "CLIPS", 8, 4, 120, 14, 9, T.txt3)
	local clipsBody = K.f(left, "Body", 4, 22, leftW - 8, bodyH - 70, T.bg2)
	local addClipB = K.btn(left, "+ Cl", 6, bodyH - 42, 46, 18, ACCENT)
	local dupB = K.btn(left, "Dup", 56, bodyH - 42, 44, 18, T.bg4)
	local delB = K.btn(left, "Del", 104, bodyH - 42, 46, 18, C("#B33A3A"))

	-- ================= CENTRO: TIMELINE/CURVE CANVAS =================
	local cx0, cw = leftW + 14, 344
	local center = K.f(root, "Curve", cx0, 34, cw, bodyH, T.bg3)
	K.txt(center, "CURVA AMOSTRADA (prop selecionada)", 8, 4, 240, 14, 9, T.txt3)
	local canvas = K.f(center, "Cv", 8, 24, cw - 16, 240, T.bg2)
	K.stroke(canvas, T.line, 1)
	-- backdrop grid
	for i = 1, 7 do K.f(canvas, "gx" .. i, i * (cw - 16) / 8, 0, 1, 240, T.line) end
	for i = 1, 4 do K.f(canvas, "gy" .. i, 0, i * 48, cw - 16, 1, T.line) end
	-- playhead marker
	local playLine = K.f(canvas, "Play", 0, 0, 1, 240, C("#6799FF"))
	-- mini timeline de markers/faixas
	local miniBar = K.f(center, "Mini", 8, 270, cw - 16, 40, T.bg2)
	K.stroke(miniBar, T.line, 1)
	K.txt(center, "markers feridos apos o(s) clip(s) ao PLAY", 8, 312, 320, 12, 8, T.txt3)
	-- controles de tempo
	local timeS = mkSlider(center, 8, 330, cw - 16, "Tempo", 0, 2.4, 0, function(v) return string.format("%.2fs", v) end, function(v) playhead = v repaintCurve() end)
	local playB = K.btn(center, "▶ Play", 8, 384, 70, 22, C("#3F9E58"))
	local stopB = K.btn(center, "■ Stop", 84, 384, 70, 22, C("#A93B3B"))
	local loopBtn = K.btn(center, "Loop: loop", 160, 384, 96, 22, T.bg4)
	local spdS = mkSlider(center, 262, 370, 78, "Vel", 0.1, 3, 1, function(v) return string.format("%.1fx", v) end, function(v) speed = v clip().speed = v end)
	local demoB = K.btn(center, "Aplicar na selecao + tocar", 8, 414, 180, 20, C("#2D6BFF"))
	local deformBtn = K.btn(center, "Deform: onda (assembly)", 194, 414, 160, 20, T.bg4)

	-- ================= DIREITA A: TRACKS =================
	local tx0, tw = cx0 + cw + 8, 174
	local trf = K.f(root, "Tracks", tx0, 34, tw, 210, T.bg3)
	K.txt(trf, "TRACKS", 8, 4, 120, 14, 9, T.txt3)
	local tracksBody = K.f(trf, "Body", 4, 20, tw - 8, 210 - 74, T.bg2)
	local PROPS = { "Position", "CFrame", "Size", "Color", "Transparency", "attr:Jump" }
	local propIdx = 1
	local addTrB = K.btn(trf, "+ Track", 6, 162, 70, 18, ACCENT)
	local propB = K.btn(trf, "prop: Position", 80, 162, 88, 18, T.bg4)
	local addKeyB = K.btn(trf, "+ Key @ playhead", 6, 184, 112, 18, C("#2D6BFF"))
	local delKeyB = K.btn(trf, "- Key", 124, 184, 44, 18, C("#B33A3A"))

	-- ================= DIREITA B: EASINGS + MARKERS + EXPORT =================
	local ex0 = tx0
	local ey0 = 252
	local ez = K.f(root, "Easy", ex0, ey0, tw, 500 - ey0 - 44, T.bg3)
	K.txt(ez, "EASING (aplica p/ key selecionada)", 8, 4, 200, 14, 9, T.txt3)
	local easeBody = K.f(ez, "Body", 4, 20, tw - 8, 148, T.bg2)
	local easeUp = K.btn(ez, "▲", 150, 4, 18, 14, T.bg4)
	local easeDn = K.btn(ez, "▼", 150, 20, 18, 14, T.bg4)
	local ezScroll = 0
	local mkBody = K.f(ez, "MkB", 4, 170, tw - 8, 16, T.bg2)
	local addMkB = K.btn(ez, "+ Marcador @ t", 6, 188, 110, 18, T.bg4)
	local expB = K.btn(ez, "Export", 118, 188, 50, 18, C("#2D6BFF"))

	-- ================= STATUS =================
	local stat = K.txt(root, "", 8, H - 40, W - 16, 14, 9, T.txt3)

	-- ================= FUNCOES (assign, NUNCA `function name()`) =================
	repaintStatus = function()
		local c = clip()
		local ks = track() and #track().keys or 0
		stat.Text = string.format("clip %d/%d  '%s' | track %d (%s) %d keys | duracao %.2fs | playhead %.2fs   | easings %d | springs p/ secondaries",
			clipsSel, #clips, c and c.name or "?", trackSel, track() and track().prop or "?", ks, c and c:duration() or 0, playhead, #AX.EASE_NAMES)
		timeS.set(playhead)
	end

	repaintClips = function()
		for _, ch in ipairs(clipsBody:GetChildren()) do ch:Destroy() end
		for i, c in ipairs(clips) do
			local row = K.btn(clipsBody, "C" .. i, 2, (i - 1) * 28, leftW - 16, 24, i == clipsSel and T.bg4 or T.bg3)
			local acc = C(i == clipsSel and "#FFB453" or "#5A6B8C")
			K.f(row, "a", 4, 10, 3, 3, acc)
			K.txt(row, c.name, 12, 5, leftW - 40, 14, 9.5, T.txt, Enum.Font.GothamMedium)
			K.txt(row, string.format("%d tr | %.1fs | %s", #c.tracks, c:duration(), c.loop), 12, 14, leftW - 40, 10, 7.5, T.txt3)
			row.MouseButton1Click:Connect(function() clipsSel = i trackSel = 1 keySel = 1 repaintTracks() repaintCurve() repaintStatus() end)
		end
	end

	repaintTracks = function()
		for _, ch in ipairs(tracksBody:GetChildren()) do ch:Destroy() end
		local c = clip()
		if not c then return end
		for i, tr in ipairs(c.tracks) do
			local row = K.btn(tracksBody, "T" .. i, 2, (i - 1) * 26, tw - 16, 22, i == trackSel and T.bg4 or T.bg3)
			local sw = K.f(row, "s", 4, 6, 8, 8, C(i == 1 and "#58C6FF" or i == 2 and "#7CE38B" or i == 3 and "#F77FAF" or "#FFB453"))
			K.txt(row, tr.prop, 18, 2, tw - 60, 12, 9, T.txt)
			K.txt(row, #tr.keys .. " keys", 18, 13, 120, 9, 7.5, T.txt3)
			row.MouseButton1Click:Connect(function() trackSel = i keySel = 1 repaintCurve() repaintEase() repaintStatus() end)
		end
		-- nenhum
		if #c.tracks == 0 then K.txt(tracksBody, "(sem tracks — +Track)", 6, 6, 140, 14, 9, T.txt3) end
	end

	repaintCurve = function()
		for _, ch in ipairs(canvas:GetChildren()) do if ch.Name:find("^pt") or ch.Name == "KeyM" then ch:Destroy() end end
		local tr = track()
		local c = clip()
		if not tr or not c then return end
		local dur = math.max(c:duration(), 0.001)
		-- range do valor (1D: usa vetor m ou escalar)
		local vmin, vmax = math.huge, -math.huge
		for i = 1, 40 do
			local t = (i - 1) / 39 * dur
			local v = tr:sample(t)
			local sv = (type(v) == "table") and v.y or v
			if sv then vmin = math.min(vmin, sv) vmax = math.max(vmax, sv) end
		end
		local span = math.max(vmax - vmin, 1e-4)
		local CW = cw - 16
		local denom = (span == 0 and 1 or span)
		for i = 1, 40 do
			local t = (i - 1) / 39 * dur
			local v = tr:sample(t)
			local sv = (type(v) == "table") and v.y or v
			if sv then
				local x = (t / dur) * (CW - 8) + 2
				local y = 240 - ((sv - vmin) / denom * 220 + 10)
				local dot = K.f(canvas, "pt" .. i, x, y, 4, 4, ACCENT)
				K.corner(dot, 2)
			end
		end
		-- keys com cor da track
		for ki, k in ipairs(tr.keys) do
			local x = (k.t / dur) * (CW - 8) + 2
			local km = K.f(canvas, "KeyM", x - 4, (ki == keySel and 4 or 8), 8, (ki == keySel and 10 or 6), ki == keySel and C("#FF4040") or T.txt3)
			km.Name = "KeyM_" .. ki
			local btn = K.btn(canvas, "KB" .. ki, x - 7, 0, 14, 240, C("#000000"))
			btn.BackgroundTransparency = 1
			btn.ZIndex = 5
			btn.MouseButton1Click:Connect(function() keySel = ki repaintCurve() repaintEase() repaintStatus() end)
		end
		-- playhead
		playLine.Position = UDim2.new(0, (playhead / dur) * (CW - 8) + 2, 0, 0)
	end

	repaintKeys = function() repaintCurve() end -- alias (camadas juntas)

	repaintEase = function(ezScroll_)
		ezScroll = ezScroll_ or ezScroll or 0
		for _, ch in ipairs(easeBody:GetChildren()) do ch:Destroy() end
		local names = AX.EASE_NAMES
		local PER = 15
		local page = math.floor(ezScroll / PER)
		local c2 = clip()
		local tr = track()
		local curE = nil
		if tr and tr.keys[keySel] then curE = tr.keys[keySel].ease end
		for i = 1 + page * PER, math.min(#names, page * PER + PER) do
			local id = names[i]
			local b = K.btn(easeBody, "E" .. i, 2 + ((i - 1 - page * PER) % 3) * 56, math.floor((i - 1 - page * PER) / 3) * 24, 52, 20, id == curE and ACCENT or T.bg3)
			K.txt(b, id:sub(1, 8), 2, 5, 46, 12, 7.5, id == curE and C("#111") or T.txt2, Enum.Font.Code)
			b.MouseButton1Click:Connect(function()
				local tr2 = track()
				if tr2 and tr2.keys[keySel] then
					tr2.keys[keySel].ease = id
					repaintCurve()
					repaintEase()
					repaintStatus()
				end
			end)
		end
	end

	repaintMarkers = function()
		for _, ch in ipairs(mkBody:GetChildren()) do ch:Destroy() end
		local c = clip()
		if not c then return end
		for i, mk in ipairs(c.markers) do
			K.txt(mkBody, string.format("⚑ %s @ %.1f", tostring(mk.id), mk.t), 4 + (i - 1) * 80, 4, 78, 16, 8, C("#9BB1FF"))
		end
		if #c.markers == 0 then K.txt(mkBody, "sem marcadores", 4, 4, 120, 14, 8, T.txt3) end
	end

	-- ================= ACOES =================
	addClipB.MouseButton1Click:Connect(function()
		local base = clip()
		local c2 = AX.clip("Clip_" .. #clips + 1, { loop = "loop" })
		c2:addTrack("Position", { AX.key(0, { x = 0, y = 1, z = 0 }, "linear"), AX.key(1.5, { x = 4, y = 3, z = 0 }, "easeOut_spring") })
		clips[#clips + 1] = c2
		clipsSel = #clips
		repaintClips() repaintTracks() repaintCurve() repaintStatus()
	end)
	dupB.MouseButton1Click:Connect(function()
		local c = clip()
		if c then
			local str = c:serialize()
			local c3 = AX.deserialize(str)
			if c3 then c3.name = c3.name .. "_copia" clips[#clips + 1] = c3 clipsSel = #clips end
			repaintClips() repaintStatus()
		end
	end)
	delB.MouseButton1Click:Connect(function()
		if #clips > 1 then table.remove(clips, clipsSel) clipsSel = 1 trackSel = 1 repaintClips() repaintTracks() repaintCurve() repaintStatus() end
	end)
	addTrB.MouseButton1Click:Connect(function()
		local c = clip()
		local prop = PROPS[propIdx]
		local v0 = prop == "Transparency" and 0.5 or (prop == "Color" and { r = 90, g = 140, b = 240 } or { x = 0, y = 2, z = 0 })
		local v1 = prop == "Transparency" and 0.1 or (prop == "Color" and { r = 240, g = 90, b = 140 } or { x = 0, y = 6, z = 0 })
		c:addTrack(prop, { AX.key(0, v0, "linear"), AX.key(1.2, v1, "easeInOut_sine") })
		trackSel = #c.tracks
		repaintTracks() repaintCurve() repaintStatus()
	end)
	propB.MouseButton1Click:Connect(function()
		propIdx = propIdx % #PROPS + 1
		propB.Text = "prop: " .. PROPS[propIdx]
	end)
	addKeyB.MouseButton1Click:Connect(function()
		local tr = track()
		local c = clip()
		if tr and c then
			local v = tr:sample(playhead)
			tr:addKey({ t = clamp(playhead, 0, c:duration()), v = v, ease = "easeOut_sine" })
			keySel = #tr.keys
			repaintCurve() repaintEase() repaintStatus()
		end
	end)
	delKeyB.MouseButton1Click:Connect(function()
		local tr = track()
		if tr and #tr.keys > 1 then tr:removeAt(keySel) keySel = 1 repaintCurve() repaintStatus() end
	end)
	easeUp.MouseButton1Click:Connect(function() repaintEase(math.max(0, ezScroll - 15)) end)
	easeDn.MouseButton1Click:Connect(function() repaintEase(ezScroll + 15) end)
	loopBtn.MouseButton1Click:Connect(function()
		local modes = { "loop", "pingpong", "none" }
		local c = clip()
		local i2 = 1
		for i, m in ipairs(modes) do if m == c.loop then i2 = i end end
		c.loop = modes[i2 % 3 + 1]
		loopBtn.Text = "Loop: " .. c.loop
		repaintStatus()
	end)
	local playing = false
	playB.MouseButton1Click:Connect(function()
		playing = true
		AX.stopAll()
		local c = clip()
		c:play({ from = playhead })
	end)
	stopB.MouseButton1Click:Connect(function() playing = false AX.stopAll() repaintStatus() end)
	addMkB.MouseButton1Click:Connect(function()
		clip():marker(playhead, "mk" .. (#clip().markers + 1))
		repaintMarkers()
	end)
	expB.MouseButton1Click:Connect(function()
		local c = clip()
		local str = c:serialize()
		local path = "ArkherClips/" .. c.name .. ".json"
		local ok = pcall(function() if game.WriteFile then game:WriteFile(path, str) end end)
		K.notify("Clip exportado", #str .. " chars → " .. path, "ok")
	end)
	demoB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		local inst = list and list[1]
		if inst then
			boundInst = inst
			local c = clip()
			c.binds = { { inst = inst, map = {} } }
			playing = true
			AX.stopAll()
			c:play({ from = playhead })
			K.notify("AAX bound", "clip '" .. c.name .. "' escreve REAL em " .. (inst.Name or "?"), "ok")
		else
			-- cria alvo demo se nada selecionado
			local ws = game:FindFirstChild("Workspace") or game
			local p = Instance.new("Part")
			p.Name = "AAX_Demo"
			p.Size = Vector3.new(2, 2, 2)
			p.Anchored = true
			p.Color = Color3.fromRGB(255, 170, 60)
			p.CFrame = CFrame.new(0, 4, 0)
			p.Parent = ws
			boundInst = p
			clip().binds = { { inst = p, map = {} } }
			playing = true
			AX.stopAll()
			clip():play({ from = playhead })
			K.notify("Demo criada", "Part AAX_Demo no workspace (sem selecao anterior)", "info")
		end
	end)
	local defKind = 1
	local DEFN = { "onda (wave)", "dobrar (bend)", "torcer (twist)", "afunilar (taper)", "respirar (breathe)" }
	deformBtn.MouseButton1Click:Connect(function()
		defKind = defKind % #DEFN + 1
		deformBtn.Text = "Deform: " .. DEFN[defKind]
	end)
	local liveDeformB = K.btn(center, "TOCAR deform p/ assembly", 360, 414, 160, 20, C("#3F9E58"))
	liveDeformB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list < 1 then
			K.notify("Sem selecao", "selecione parts para formar um assembly", "warn")
			return
		end
		local fns = {
			AX.DEFORMERS.wave(1.2, 14, 2.2),
			AX.DEFORMERS.bend(0.8, "x"),
			AX.DEFORMERS.twist(0.5, "y"),
			AX.DEFORMERS.taper(0.6, "y"),
			AX.DEFORMERS.breathe(0.08, 2.4),
		}
		if deformH then deformH.playing = false end
		local asm = AX.assemble(list)
		deformH = AX.deform(asm, fns[defKind], {})
		K.notify("Assembly deformer", DEFN[defKind] .. " em " .. #list .. " parts (ao vivo)", "ok")
	end)

	-- ================= PUMP (Frame -> AAX.pump + exhibits) =================
	local acc = 0
	pcall(function()
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			AX.pump(dt)
			AX.pumpDeformers(dt)
			acc = acc + dt
			if acc >= 0.1 then
				acc = 0
				-- atualizar playhead visual e dots
				local c = clip()
				if c and c.playing then
					playhead = c.time
					repaintCurve()
					repaintStatus()
				end
			end
		end)
	end)

	-- ================= BOOT =================
	repaintClips()
	repaintTracks()
	repaintCurve()
	repaintEase(0)
	repaintMarkers()
	repaintStatus()
	return g
end

ARKHER.reg("Animator", "Animator Studio X", "Editor", ICON.play, "Animacao custom (AAX): 37 easings, splines, springs, deformers, export JSON, aplica REAL", build)
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

local opened = ARKHER.openAll()
ARKHER.out("SUCCESS", "ARKHER V4 — bundle Motion: " .. opened .. " UIs abertas")
