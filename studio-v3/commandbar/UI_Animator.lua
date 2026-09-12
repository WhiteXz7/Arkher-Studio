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

ARKHER.open("Animator")
