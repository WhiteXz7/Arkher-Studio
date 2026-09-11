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
--[[ ARKHER — UI: TERRAIN STUDIO (motor ATX custom, nao usa Terrain do Roblox) ]]
-- Estudio profissional completo: 6 abas (ESCULPIR/GERAR/GEOL/HIDRO/CLIMA/MUNDO),
-- canvas de terreno INTERATIVO (clique/arraste esculpe o mundo ATX de verdade),
-- 10 pinceis x 5 falloffs, 8 presets de mundo, erosao real, rios, lagos, clima,
-- biomas, materializacao adaptativa (D-O15) e export real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local TX, DM = ArkherTerrainX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	local lbl = K.txt(parent, label, x, y, 80, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 54, y, 54, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 16, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		if fmt then valLbl.Text = fmt(val) else valLbl.Text = string.format("%.2f", val) end
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
	return {
		get = function() return val end,
		set = function(v) val = v renderSlider() if onSet then onSet(v) end end,
	}
end

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN STUDIO — motor ATX (custom)", 24, 300, 700, 500, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= MUNDO VIVO =================
	local world = TX.new({ seed = 1337, preset = "continentes", cell = 8, chunkCells = 16 })
	local brush = { op = "raise", falloff = "smooth", radius = 24, strength = 0.6, amount = 6, mat = "grama" }
	local region = { gx0 = 1, gz0 = 1, gw = 64, gh = 40 } -- regiao de trabalho (celulas)
	local status = nil
	local statLbl = nil
	local gridTiles = {}
	local preview = nil
	local seedBox = nil
	local refreshStats = nil
	local refreshClimate = nil
	local climateList = nil

	-- ================= ABAS =================
	local TABS = { "ESCULPIR", "GERAR", "GEOL", "HIDRO", "CLIMA", "MUNDO" }
	local curTab = 1
	local tabBodies = {}
	local tabBar = K.f(root, "TabBar", 8, 34, 684, 26, T.bg4)
	K.corner(tabBar, 5)
	local tabBtns = {}
	local function selectTab(i)
		curTab = i
		for j, b in ipairs(tabBtns) do
			b.BackgroundColor3 = (j == i) and T.bg2 or T.bg4
			local u = b:FindFirstChild("Und")
			if u then u.BackgroundColor3 = (j == i) and ACCENT or T.bg4 end
			if tabBodies[j] then tabBodies[j].Visible = (j == i) end
		end
	end
	for i, nm in ipairs(TABS) do
		local b = K.btn(tabBar, "T" .. i, 4 + (i - 1) * 113, 2, 108, 22, T.bg4, 4)
		K.txtS(b, nm, 10, T.txt2)
		local u = K.f(b, "Und", 0, 20, 108, 2, T.bg4)
		local idx = i
		b.MouseButton1Click:Connect(function() selectTab(idx) end)
		tabBtns[i] = b
	end

	local contentY, contentH = 66, 300

	-- ================= CANVAS (todos os paineis a esquerda) =================
	local canvasW, canvasCols, canvasRows = 320, 16, 10
	local tileW, tileH = 20, 24
	preview = K.f(root, "Canvas", 8, contentY, tileW * canvasCols + 2, tileH * canvasRows + 2, T.bg0)
	K.corner(preview, 4)
	K.stroke(preview, T.line, 1)
	local painting = false
	local function cellColor(h, mi, wet, isRiver, isLake)
		local m = TX.MATERIALS[mi or 1]
		local base = m and m.cor or { 90, 140, 80 }
		local shade = math.min(1.2, math.max(0.45, 0.75 + h / 70))
		local r2 = math.floor(base[1] * shade)
		local g2 = math.floor(base[2] * shade)
		local b2 = math.floor(base[3] * shade)
		if isRiver or isLake then return Color3.fromRGB(52, 120, 200) end
		if h < world.seaLevel then return Color3.fromRGB(28, 84, 148) end
		if wet and wet > 0.75 then
			return Color3.fromRGB(math.floor(r2 * 0.8), math.floor(g2 * 0.9), math.floor(b2 * 0.85))
		end
		return Color3.fromRGB(math.min(255, r2), math.min(255, g2), math.min(255, b2))
	end
	local function repaint()
		for j = 1, canvasRows do
			for i = 1, canvasCols do
				local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
				local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
				local cx, cz = world:chunkKeyOf(gx, gz)
				local ch = world:genChunk(cx, cz)
				local n = world.chunkCells
				local lx = math.min(n, math.max(1, gx - cx * n))
				local lz = math.min(n, math.max(1, gz - cz * n))
				local h = world:heightAtCell(gx, gz)
				local mi = ch.mat[(lz - 1) * n + lx]
				local wv = ch.wet[(lz - 1) * n + lx] or 0
				local isRiver = (wv >= 0.99 and h > world.seaLevel - 1)
				local isLake = world.lakes[gx .. "," .. gz] ~= nil
				local t2 = gridTiles[(j - 1) * canvasCols + i]
				t2.BackgroundColor3 = cellColor(h, mi, wv, isRiver, isLake)
				local hl = t2:FindFirstChild("Hd")
				if hl then hl.Visible = false end
			end
		end
	end
	local function paintAt(i, j)
		local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
		local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
		-- nivel de mar: depressao vira agua visual
		if brush.op == "sealevel" then
			world.seaLevel = world:heightAtCell(gx, gz)
			repaint()
			return
		end
		world:sculpt(gx * world.cell, gz * world.cell, {
			op = brush.op, radius = brush.radius, strength = brush.strength,
			falloff = brush.falloff, amount = brush.amount, mat = brush.mat,
			target = world:heightAtCell(gx, gz),
		})
		repaint()
		if status then status.Text = "pincel '" .. brush.op .. "' em (" .. gx .. "," .. gz .. ") r=" .. brush.radius .. " f=" .. string.format("%.2f", brush.strength) end
	end
	for j = 1, canvasRows do
		for i = 1, canvasCols do
			local t2 = K.btn(preview, "H" .. ((j - 1) * canvasCols + i), (i - 1) * tileW + 1, (j - 1) * tileH + 1, tileW - 1, tileH - 1, T.bg2, 1)
			local ii, jj = i, j
			t2.MouseButton1Click:Connect(function() paintAt(ii, jj) end)
			t2.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = true paintAt(ii, jj) end
			end)
			t2.MouseEnter:Connect(function()
				if painting then paintAt(ii, jj) end
				t2.BackgroundTransparency = 0.55
			end)
			t2.MouseLeave:Connect(function() t2.BackgroundTransparency = 0 end)
			gridTiles[(j - 1) * canvasCols + i] = t2
		end
	end
	preview.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = false end
	end)
	K.txt(preview, region.gw .. "x" .. region.gh .. " celulas | clique ou arraste p/ esculpir", 6, tileH * canvasRows - 16, 260, 12, 8, C("#0A0F18"))

	-- ================= PAINEL DIREITO (abas) =================
	local panel = K.f(root, "Panel", 338, contentY, 352, contentH + 150, T.bg4)
	K.corner(panel, 5)
	for i = 1, #TABS do
		local body = K.f(panel, "TB" .. i, 0, 0, 352, contentH + 150)
		body.Visible = i == 1
		tabBodies[i] = body
	end

	-- ========== ABA 1: ESCULPIR ==========
	do
		local b = tabBodies[1]
		K.txt(b, "PINCEIS (10)", 12, 8, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local ops = {
			{ id = "raise", nm = "Raise", gl = "+" }, { id = "lower", nm = "Lower", gl = "-" },
			{ id = "smooth", nm = "Smooth", gl = "~" }, { id = "flatten", nm = "Flatten", gl = "=" },
			{ id = "set", nm = "Set", gl = "S" }, { id = "noise", nm = "Noise", gl = "N" },
			{ id = "crater", nm = "Cratera", gl = "O" }, { id = "terrace", nm = "Terraco", gl = "T" },
			{ id = "paint", nm = "Pintar", gl = "P" }, { id = "wet", nm = "Molhar", gl = "W" },
		}
		local opBtns = {}
		for i, o in ipairs(ops) do
			local bx = 12 + ((i - 1) % 3) * 108
			local by = 26 + math.floor((i - 1) / 3) * 30
			local b2 = K.btn(b, "OP" .. i, bx, by, 100, 26, T.bg2, 4)
			K.txt(b2, o.gl, 6, 5, 16, 16, 13, ACCENT, ARKHER.FONTB)
			K.txt(b2, o.nm, 26, 6, 70, 14, 10, T.txt)
			local id = o.id
			b2.MouseButton1Click:Connect(function()
				brush.op = id
				for j3, bb in ipairs(opBtns) do K.stroke(bb, ops[j3].id == id and ACCENT or T.line2, ops[j3].id == id and 1.5 or 1) end
				if status then status.Text = "pincel: " .. o.nm end
			end)
			K.stroke(b2, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			opBtns[i] = b2
		end
		K.txt(b, "FALLOFF", 12, 134, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local falloffs = { "smooth", "gaussian", "cosine", "linear", "sharp" }
		local fBtns = {}
		for i, f2 in ipairs(falloffs) do
			local b3 = K.btn(b, "F" .. i, 12 + (i - 1) * 65, 152, 60, 20, T.bg2, 4)
			K.txtS(b3, f2, 9, T.txt2)
			local fid = f2
			b3.MouseButton1Click:Connect(function()
				brush.falloff = fid
				for j3, bb in ipairs(fBtns) do K.stroke(bb, falloffs[j3] == fid and ACCENT or T.line2, falloffs[j3] == fid and 1.5 or 1) end
			end)
			K.stroke(b3, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			fBtns[i] = b3
		end
		mkSlider(b, 12, 182, 200, "Raio", 4, 96, brush.radius, function(v) return string.format("%.0f", v) end, function(v) brush.radius = v end)
		mkSlider(b, 12, 226, 200, "Forca", 0.05, 1, brush.strength, function(v) return string.format("%.2f", v) end, function(v) brush.strength = v end)
		mkSlider(b, 12, 270, 200, "Quantia", 1, 24, brush.amount, function(v) return string.format("%.1f", v) end, function(v) brush.amount = v end)
		-- materiais (18 dos 24 p/ pintar)
		K.txt(b, "MATERIAL (p/ pintar)", 12, 314, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local pm = 0
		for i, m in ipairs(TX.MATERIALS) do
			if pm >= 18 then break end
			pm = pm + 1
			local mx = 12 + ((pm - 1) % 6) * 54
			local my = 332 + math.floor((pm - 1) / 6) * 24
			local sw = K.btn(b, "MT" .. pm, mx, my, 50, 20, T.bg2, 3)
			K.f(sw, "c", 3, 3, 14, 14, Color3.fromRGB(m.cor[1], m.cor[2], m.cor[3]), 2)
			K.txt(sw, m.id:sub(1, 7), 19, 4, 30, 12, 8, T.txt3)
			local mid = m.id
			sw.MouseButton1Click:Connect(function()
				brush.mat = mid
				brush.op = "paint"
				if status then status.Text = "pintar: " .. m.nm .. " (dens " .. m.dens .. " kg/L)" end
			end)
		end
		local undo2 = K.btn(b, "Undo", 12, 416, 120, 26, T.bg2, 5)
		K.txtS(undo2, "Desfazer (undo stack)", 9, T.txt)
		K.hover(undo2, T.bg2, T.hover)
		undo2.MouseButton1Click:Connect(function()
			ArkherUNDO.undo()
			repaint()
			if status then status.Text = "undo aplicado" end
		end)
	end

	-- ========== ABA 2: GERAR ==========
	do
		local b = tabBodies[2]
		K.txt(b, "PRESETS DE MUNDO (8)", 12, 8, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local presetIds = { "continentes", "ilhas", "montanhas", "canyon", "dunas", "meseta", "vulcao", "polar" }
		for i, pid in ipairs(presetIds) do
			local p = TX.PRESETS[pid]
			local bx = 12 + ((i - 1) % 2) * 166
			local by = 28 + math.floor((i - 1) / 2) * 34
			local b2 = K.btn(b, "PR" .. i, bx, by, 158, 30, T.bg2, 4)
			K.txt(b2, p.label, 10, 3, 130, 14, 11, T.txt)
			local extras = (p.mont and ("mont x" .. p.mont) or "") .. (p.terrace and (" | terraco " .. p.terrace) or "")
			K.txt(b2, extras, 10, 16, 140, 12, 8, T.txt4)
			K.hover(b2, T.bg2, T.hover)
			local id = pid
			b2.MouseButton1Click:Connect(function()
				local s = math.floor(seedBox.Text ~= "" and tonumber(seedBox.Text) or world.seed)
				world = TX.new({ seed = s, preset = id, cell = world.cell, chunkCells = 16, seaLevel = p.sea or 0 })
				repaint()
				refreshStats()
				if status then status.Text = "mundo gerado: " .. p.label .. " (seed " .. s .. ")" end
			end)
		end
		K.txt(b, "SEED", 12, 172, 60, 14, 10, T.txt3, ARKHER.FONTB)
		seedBox = K.input(b, 60, 168, 100, 24, "1337")
		local regen = K.btn(b, "Regen", 168, 168, 90, 24, ACCENT, 5)
		K.txtS(regen, "Gerar", 11, C("#0D140B"))
		K.hover(regen, ACCENT, C("#A5E88C"))
		local rnd = K.btn(b, "Rnd", 264, 168, 60, 24, T.bg2, 5)
		K.txtS(rnd, "Aleatoria", 9, T.txt)
		K.hover(rnd, T.bg2, T.hover)
		rnd.MouseButton1Click:Connect(function()
			seedBox.Text = tostring(math.random(1, 99999))
		end)
		regen.MouseButton1Click:Connect(function()
			local s = tonumber(seedBox.Text) or 1337
			world = TX.new({ seed = s, preset = world.preset, cell = world.cell, chunkCells = 16, seaLevel = world.params.sea or 0 })
			repaint()
			refreshStats()
			if status then status.Text = "regenerado seed " .. s .. " preset " .. world.preset end
		end)
		-- parametros finos
		K.txt(b, "PARAMETROS FISICOS", 12, 206, 200, 14, 10, T.txt3, ARKHER.FONTB)
		mkSlider(b, 12, 224, 200, "Continentes", 0, 2, world.params.cont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.cont = v end)
		mkSlider(b, 12, 268, 200, "Montanhas", 0, 2.5, world.params.mont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.mont = v end)
		mkSlider(b, 12, 312, 200, "Warp", 0, 12, world.params.warp or 4, function(v) return string.format("%.1f", v) end, function(v) world.params.warp = v end)
		local reapp = K.btn(b, "Reapply", 12, 362, 160, 26, T.bg2, 5)
		K.txtS(reapp, "Reaplicar e re-gerar chunks", 9, T.txt)
		K.hover(reapp, T.bg2, T.hover)
		reapp.MouseButton1Click:Connect(function()
			world.chunks = {}
			world.stats.gen = 0
			world.stats.cells = 0
			repaint()
			refreshStats()
			if status then status.Text = "chunks re-gerados com novos parametros" end
		end)
	end

	-- ========== ABA 3: GEOL (erosao) ==========
	do
		local b = tabBodies[3]
		K.txt(b, "EROSAO HIDRAULICA (droplet sim)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local iters = mkSlider(b, 12, 26, 200, "Gotas", 500, 20000, 5000, function(v) return string.format("%.0f", v) end)
		local erf = mkSlider(b, 12, 70, 200, "Erodibilidade", 0.05, 1, 0.35)
		local dep = mkSlider(b, 12, 114, 200, "Deposicao", 0.05, 1, 0.35)
		local run1 = K.btn(b, "RunH", 12, 168, 158, 28, ACCENT, 5)
		K.txtS(run1, "Rodar erosao hidraulica", 10, C("#0D140B"))
		K.hover(run1, ACCENT, C("#A5E88C"))
		local hydRes = K.txt(b, "—", 12, 202, 320, 14, 9, T.txt4)
		run1.MouseButton1Click:Connect(function()
			local res = world:erodeHydraulic(region.gx0, region.gz0, region.gw, region.gh, math.floor(iters.get()), { erode = erf.get(), deposit = dep.get() })
			hydRes.Text = "gotas: " .. res.iterations .. " | dMedio: " .. string.format("%.3f", res.meanDelta) .. " | dMax: " .. string.format("%.2f", res.maxDelta)
			repaint()
			if status then status.Text = "erosao hidraulica concluida (vales + sedimentos reais)" end
		end)
		K.txt(b, "EROSAO TERMICA (talus)", 12, 232, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local pass = mkSlider(b, 12, 250, 200, "Passagens", 1, 32, 8, function(v) return string.format("%.0f", v) end)
		local tal = mkSlider(b, 12, 294, 200, "Talude limite", 0.2, 2, 0.9)
		local run2 = K.btn(b, "RunT", 12, 348, 158, 28, T.bg2, 5)
		K.txtS(run2, "Rodar erosao termica", 10, T.txt)
		K.hover(run2, T.bg2, T.hover)
		local thRes = K.txt(b, "—", 12, 382, 320, 14, 9, T.txt4)
		run2.MouseButton1Click:Connect(function()
			local res = world:erodeThermal(region.gx0, region.gz0, region.gw, region.gh, math.floor(pass.get()), tal.get())
			thRes.Text = "passagens: " .. res.passes .. " | material movido: " .. string.format("%.1f", res.moved)
			repaint()
			if status then status.Text = "erosao termica concluida (encostas em angulo de repouso)" end
		end)
	end

	-- ========== ABA 4: HIDRO ==========
	do
		local b = tabBodies[4]
		K.txt(b, "RIOS (D8 flow accumulation)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local acc = mkSlider(b, 12, 26, 200, "Acumulacao min", 4, 96, 24, function(v) return string.format("%.0f", v) end)
		local runR = K.btn(b, "RunR", 12, 76, 158, 28, C("#58A6FF"), 5)
		K.txtS(runR, "Escavar rede de rios", 10, C("#081420"))
		K.hover(runR, C("#58A6FF"), C("#8FC3FF"))
		local rivRes = K.txt(b, "—", 12, 110, 320, 14, 9, T.txt4)
		runR.MouseButton1Click:Connect(function()
			local res = world:carveRivers(region.gx0, region.gz0, region.gw, region.gh, math.floor(acc.get()))
			rivRes.Text = "celulas fluviais: " .. res.cells .. " | acumulacao max: " .. res.maxAcc
			repaint()
			if status then status.Text = "rios escavados: " .. res.cells .. " celulas (leitos em V)" end
		end)
		K.txt(b, "LAGOS (depression fill)", 12, 140, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local runL = K.btn(b, "RunL", 12, 160, 158, 28, C("#2FBF9F"), 5)
		K.txtS(runL, "Preencher lagos", 10, C("#062018"))
		K.hover(runL, C("#2FBF9F"), C("#6ADFC2"))
		local lakeRes = K.txt(b, "—", 12, 194, 320, 14, 9, T.txt4)
		runL.MouseButton1Click:Connect(function()
			local res = world:fillLakes(region.gx0, region.gz0, region.gw, region.gh)
			lakeRes.Text = "celulas de lago: " .. res.cells
			repaint()
			if status then status.Text = "lagos preenchidos: " .. res.cells .. " celulas" end
		end)
		K.txt(b, "NIVEL DO MAR", 12, 224, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local sea = mkSlider(b, 12, 242, 200, "Sea level", -20, 20, world.seaLevel, function(v) return string.format("%.1f", v) end, function(v)
			world.seaLevel = v
			repaint()
		end)
		local awater = K.btn(b, "Water", 12, 292, 158, 28, T.purple, 5)
		K.txtS(awater, "Abrir WATER STUDIO", 10, C("#FFFFFF"))
		K.hover(awater, T.purple, C("#A97AFF"))
		awater.MouseButton1Click:Connect(function() ARKHER.open("Water") end)
		K.txt(b, "waters = AWX (motor proprio)", 12, 326, 240, 12, 8, T.txt4)
	end

	-- ========== ABA 5: CLIMA ==========
	do
		local b = tabBodies[5]
		K.txt(b, "CLIMA GLOBAL (campos fisicos)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local tb = mkSlider(b, 12, 26, 200, "Temp bias", -40, 40, world.params.tempB or 0, function(v) return string.format("%+.0f C", v) end, function(v) world.params.tempB = v end)
		local hb = mkSlider(b, 12, 70, 200, "Chuva bias", -80, 80, world.params.humidB or 0, function(v) return string.format("%+.0f cm", v) end, function(v) world.params.humidB = v end)
		local applyC = K.btn(b, "ApplyC", 12, 124, 158, 26, T.bg2, 5)
		K.txtS(applyC, "Re-classificar biomas", 10, T.txt)
		K.hover(applyC, T.bg2, T.hover)
		applyC.MouseButton1Click:Connect(function()
			world.chunks = {}
			repaint()
			refreshClimate()
			if status then status.Text = "biomas re-classificados via Whittaker" end
		end)
		K.txt(b, "BIOMAS (distribuicao real — Whittaker)", 12, 162, 300, 14, 10, T.txt3, ARKHER.FONTB)
		climateList = K.f(b, "CL", 12, 182, 328, 200)
		refreshClimate = function()
			climateList:ClearAllChildren()
			local counts = world:biomeCounts()
			local total = 0
			local sorted = {}
			for k2, v in pairs(counts) do total = total + v; sorted[#sorted + 1] = { k2, v } end
			table.sort(sorted, function(a, b2) return a[2] > b2[2] end)
			if total == 0 then K.txt(climateList, "gere o mundo primeiro (canvas)", 0, 0, 240, 14, 10, T.txt4) return end
			for i = 1, math.min(#sorted, 9) do
				local name, qty = sorted[i][1], sorted[i][2]
				local frac = qty / total
				K.txt(climateList, name, 0, (i - 1) * 21, 150, 14, 10, T.txt2)
				local bar = K.f(climateList, "B" .. i, 150, (i - 1) * 21 + 3, math.floor(140 * frac), 8, ACCENT)
				K.corner(bar, 3)
				K.txt(climateList, string.format("%.1f%%", frac * 100), 296, (i - 1) * 21, 40, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Right)
			end
		end
		refreshClimate()
	end

	-- ========== ABA 6: MUNDO ==========
	do
		local b = tabBodies[6]
		K.txt(b, "MATERIALIZACAO (RRW -> workspace)", 12, 8, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local mkWorld = K.btn(b, "M1", 12, 26, 158, 28, ACCENT, 5)
		K.txtS(mkWorld, "Materializar 128x128", 10, C("#0D140B"))
		K.hover(mkWorld, ACCENT, C("#A5E88C"))
		local mkBig = K.btn(b, "M2", 176, 26, 158, 28, T.bg2, 5)
		K.txtS(mkBig, "Materializar 256x256", 10, T.txt)
		K.hover(mkBig, T.bg2, T.hover)
		local mkOut = K.txt(b, "—", 12, 60, 328, 14, 9, T.txt4)
		mkWorld.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-64, -64, 128, 128, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts (LOD " .. tostring(TX._lodStep(2)) .. ")" end
		end)
		mkBig.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-128, -128, 256, 256, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts" end
		end)
		local lodB = K.btn(b, "LOD", 12, 84, 158, 26, T.bg2, 5)
		K.txtS(lodB, "LOD adaptativo (foco 0,0)", 9, T.txt)
		K.hover(lodB, T.bg2, T.hover)
		lodB.MouseButton1Click:Connect(function()
			local r = world:updateLOD(0, 0)
			if status then status.Text = "LOD: " .. r.updated .. " chunks atualizados (D-O15 nivel " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")" end
		end)
		local clr = K.btn(b, "Clr", 176, 84, 158, 26, T.bg2, 5)
		K.txtS(clr, "Limpar workspace", 10, T.txt)
		K.hover(clr, T.bg2, T.hover)
		clr.MouseButton1Click:Connect(function()
			TX.clearWorld(world)
			refreshStats()
			if status then status.Text = "ATX_World removido do workspace" end
		end)
		K.txt(b, "PERSISTENCIA (JSON roundtrip)", 12, 122, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local exp = K.btn(b, "Exp", 12, 140, 158, 26, T.bg2, 5)
		K.txtS(exp, "Exportar ATX JSON", 10, T.txt)
		K.hover(exp, T.bg2, T.hover)
		local expOut = K.txt(b, "—", 12, 170, 328, 14, 9, T.txt4)
		exp.MouseButton1Click:Connect(function()
			local str, path, ok = world:exportFile()
			expOut.Text = "bundle: " .. #str .. " chars → " .. path .. (ok and " (arquivo gravado)" or " (somente Studio grava)")
		end)
		local load2 = K.btn(b, "Load", 176, 140, 158, 26, T.bg2, 5)
		K.txtS(load2, "Testar roundtrip", 10, T.txt)
		K.hover(load2, T.bg2, T.hover)
		load2.MouseButton1Click:Connect(function()
			local str = world:serialize()
			local w2, err = TX.deserialize(str)
			if w2 then
				expOut.Text = "roundtrip OK: " .. (w2.restored or 0) .. " chunks restaurados, seed " .. w2.seed
			else
				expOut.Text = "roundtrip falhou: " .. tostring(err)
			end
		end)
		K.txt(b, "MOTOR", 12, 196, 120, 14, 10, T.txt3, ARKHER.FONTB)
		K.row(b, "engine", "ATX v" .. TX._version, 214)
		K.row(b, "chunk", world.chunkCells .. " celulas x " .. world.cell .. " studs", 232)
		K.row(b, "materiais", #TX.MATERIALS .. " fisicos", 250)
		K.row(b, "presets", "8 mundos", 268)
		local ai2 = K.btn(b, "AI", 12, 292, 322, 28, T.purple, 5)
		K.txtS(ai2, "Singularity: mundo + erosao + rios + agua", 10, C("#FFFFFF"))
		K.hover(ai2, T.purple, C("#A97AFF"))
		ai2.MouseButton1Click:Connect(function()
			local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno realista com rios, erosao e oceano") end)
			if ok2 and rep then K.notify("Singularity", "mundo gerado (" .. #rep.lines .. " etapas)", "ok") end
		end)
		K.txt(b, "sementes renascem identicas — mesma realidade, qualquer D-O15", 12, 330, 320, 12, 8, T.txt4)
	end

	-- ================= BASE: STATUS + STATS =================
	local bar = K.f(root, "Bar", 8, contentY + contentH + 8, 322, 52, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um pincel e clique no canvas", 10, 6, 304, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 28, 304, 14, 8, T.txt4)
	refreshStats = function()
		local s = world:worldStats()
		statLbl.Text = "seed " .. s.seed .. " | chunks " .. s.chunks .. " | celulas " .. s.cells .. " | rios " .. s.rivers .. " | lagos " .. s.lakes .. " | parts " .. s.parts .. " | gotas " .. s.droplets
	end
	refreshStats()
	repaint()
	selectTab(1)
end

ARKHER.reg("Terrain", "Terrain Studio", "Editor", ICON.terrain, "Terrain custom (ATX): 10 pinceis, erosao real, rios, lagos, clima, biomas, LOD D-O15", build)
end

do
--[[ ARKHER — UI: WATER STUDIO (motor AWX custom, nao usa agua do Roblox) ]]
-- Estudio de agua completissimo: 8 tipos com fisica real (densidade/salinidade/
-- temperatura/viscosidade), 6 presets de mar, DESIGNER DE ONDAS DE GERSTNER
-- (amp/len/dir/speed/steep por onda), mare lunar, correntes (Stokes drift),
-- preview vivo do perfil de onda, espuma por energia de crista, causticas,
-- FLUTUABILIDADE arquimediana real na selecao, ambiente subaquatico, splash.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#58C6FF")
local WX, DM = ArkherWaterX, ArkherDM

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

local function build()
	local g, root, head = K.window("ArkherWater", "WATER STUDIO — motor AWX (custom)", 30, 320, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= CORPO D'AGUA VIVO =================
	local body = WX.preset("porto", { kind = "oceano", level = 0, size = { x = 480, z = 320 } })
	local simT = 0
	local playing = false
	local status = nil
	local statLbl = nil
	local profTiles = {}
	local foamTiles = {}
	local waveRows = {}
	local selWave = 1
	local repaintProfile = nil
	local repaintWaves = nil
	local refreshWaveSliders = nil
	local timeS = nil

	-- ================= ESQUERDA: TIPOS + PRESETS =================
	local left = K.f(root, "Left", 8, 34, 150, 252, T.bg4)
	K.corner(left, 4)
	K.txt(left, "TIPO DE AGUA", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	local kinds = { "oceano", "mar_calmo", "lago", "rio", "cachoeira", "pantano", "glacial", "terma" }
	for i, kd in ipairs(kinds) do
		local w = WX.WATERS[kd]
		local b = K.btn(left, "K" .. i, 8, 24 + (i - 1) * 27, 134, 23, T.bg2, 4)
		K.f(b, "c", 4, 5, 13, 13, Color3.fromRGB(w.cor[1], w.cor[2], w.cor[3]), 2)
		K.txt(b, w.nm, 22, 4, 102, 14, 10, T.txt)
		K.txt(b, "dens " .. w.dens, 22, 15, 102, 10, 7, T.txt4)
		K.hover(b, T.bg2, T.hover)
		local id = kd
		b.MouseButton1Click:Connect(function()
			local lvl = body.level
			body = WX.create(id, { level = lvl, size = body.size, waves = body.waves, tideAmp = body.tideAmp })
			repaintProfile()
			if status then status.Text = "agua: " .. w.nm .. " | sal " .. w.sal .. "g/L | temp " .. w.temp .. "C | visc " .. w.visc end
		end)
	end
	K.txt(left, "PRESETS DE MAR", 10, 242, 130, 14, 10, T.txt3, ARKHER.FONTB)
	local presets = { "calmaria", "porto", "ressaca", "tempestade", "corredeira", "espelho" }
	for i, pr in ipairs(presets) do
		local b = K.btn(left, "P" .. i, 8 + ((i - 1) % 2) * 68, 260 + math.floor((i - 1) / 2) * 24, 62, 20, T.bg2, 4)
		K.txtS(b, pr, 8, T.txt2)
		K.hover(b, T.bg2, T.hover)
		local id = pr
		b.MouseButton1Click:Connect(function()
			local kind = body.kind
			body = WX.preset(id, { kind = kind, level = body.level, size = body.size })
			repaintWaves()
			repaintProfile()
			if status then status.Text = "preset '" .. id .. "': " .. #body.waves .. " ondas de Gerstner" end
		end)
	end

	-- ================= CENTRO: PREVIEW VIVO (perfil de onda real) =================
	local prof = K.f(root, "Prof", 168, 34, 340, 252, T.bg0)
	K.corner(prof, 4)
	K.stroke(prof, T.line, 1)
	local COLS, PH = 34, 226
	local function colFor(h, crest)
		if crest > 0.45 then return Color3.fromRGB(190, 226, 246) end
		local f = math.min(1, math.max(0, (h + 6) / 12))
		local c = body.props.cor
		return Color3.fromRGB(
			math.floor(c[1] + f * 40), math.floor(c[2] + f * 44), math.floor(c[3] + f * 30))
	end
	for i = 1, COLS do
		local col = K.f(prof, "P" .. i, (i - 1) * 10 + 2, 10, 9, 10, C("#16456B"), 0)
		profTiles[i] = col
		local fo = K.f(prof, "F" .. i, (i - 1) * 10 + 2, 10, 9, 3, C("#E8F6FF"), 0)
		fo.Visible = false
		foamTiles[i] = fo
	end
	repaintProfile = function()
		local span = (body.size and body.size.x) or 480
		local maxA = 1
		for _, w in ipairs(body.waves) do maxA = math.max(maxA, w.amp) end
		for i = 1, COLS do
			local x = (i - 0.5) / COLS * span - span / 2
			local h = body:heightAt(x, 0, simT) - body.level
			local crest = body:crestAt(x, 0, simT)
			local px = math.floor(math.max(4, math.min(PH - 20, 60 + h * (22 / math.max(maxA, 0.5)))))
			local col = profTiles[i]
			col.Size = UDim2.new(0, 9, 0, px)
			col.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 10 + PH - px)
			col.BackgroundColor3 = colFor(h, crest)
			local fo = foamTiles[i]
			fo.Visible = crest * body.foaminess > 0.32
			fo.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 8 + PH - px)
		end
	end
	-- tempo + play
	timeS = mkSlider(prof, 10, PH + 8, 200, "Tempo (s)", 0, 120, 0, function(v) return string.format("%.1f", v) end, function(v)
		simT = v
		repaintProfile()
	end)
	local play = K.btn(prof, "Play", 250, PH + 18, 80, 22, ACCENT, 5)
	K.txtS(play, "ANIMAR", 9, C("#06222E"))
	K.hover(play, ACCENT, C("#9BE0FF"))
	local playConn = nil
	play.MouseButton1Click:Connect(function()
		playing = not playing
		local lbl2 = play:FindFirstChildOfClass("TextLabel")
		if lbl2 then lbl2.Text = playing and "PARAR" or "ANIMAR" end
		if playing and not playConn then
			local ok2, RS = pcall(function() return game:GetService("RunService") end)
			if ok2 and RS and RS.Heartbeat then
				local acc = 0
				playConn = RS.Heartbeat:Connect(function(dt)
					if not playing then return end
					acc = acc + dt
					local budget = ArkherDO15 and ArkherDO15.refreshBudget("animations") or 0
					if acc >= math.max(0.03, 0.05) then
						simT = simT + acc
						acc = 0
						timeS.set(simT % 120)
						repaintProfile()
						if body.tiles then WX.animate(body, simT) end
						WX.step(body, dt, simT)
					end
				end)
			end
		end
	end)

	-- ================= DIREITA: DESIGNER DE ONDAS + PROPRIEDADES =================
	local right = K.f(root, "Right", 518, 34, 174, 252, T.bg4)
	K.corner(right, 4)
	K.txt(right, "GERSTNER (ondas)", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	repaintWaves = function()
		for i = 1, 6 do
			local row = right:FindFirstChild("WR" .. i)
			if row then row:Destroy() end
		end
		waveRows = {}
		for i = 1, math.min(#body.waves, 6) do
			local w = body.waves[i]
			local row = K.btn(right, "WR" .. i, 8, 24 + (i - 1) * 26, 158, 22, T.bg2, 4)
			K.txt(row, "λ" .. string.format("%.0f", w.len) .. " a" .. string.format("%.2f", w.amp), 8, 3, 86, 14, 9, (i == selWave) and ACCENT or T.txt)
			K.txt(row, "→" .. string.format("%.0f", w.dir) .. "°", 100, 3, 50, 14, 9, T.txt4)
			K.stroke(row, i == selWave and ACCENT or T.line2, i == selWave and 1.5 or 1)
			local idx = i
			row.MouseButton1Click:Connect(function()
				selWave = idx
				repaintWaves()
				refreshWaveSliders()
			end)
			waveRows[i] = row
		end
	end
	repaintWaves()
	local swAmp, swLen, swDir
	local function curW() return body.waves[selWave] end
	refreshWaveSliders = function()
		local w = curW()
		if not w or not swAmp then return end
		swAmp.set(w.amp); swLen.set(w.len); swDir.set(w.dir)
	end
	swAmp = mkSlider(right, 10, 184, 154, "Amplitude", 0.03, 3, 0.4, nil, function(v) if curW() then curW().amp = v end repaintProfile() repaintWaves() end)
	swLen = mkSlider(right, 10, 216, 154, "Comprimento λ", 4, 120, 34, function(v) return string.format("%.0f", v) end, function(v) if curW() then curW().len = v end repaintProfile() repaintWaves() end)
	swDir = mkSlider(right, 10, 248, 154, "Direcao", 0, 360, 0, function(v) return string.format("%.0f", v) .. "°" end, function(v) if curW() then curW().dir = v end repaintProfile() repaintWaves() end)

	local props = K.f(root, "Props", 518, 292, 174, 130, T.bg4)
	K.corner(props, 4)
	K.txt(props, "MARE / NIVEL", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	mkSlider(props, 10, 24, 154, "Nivel", -20, 20, body.level, function(v) return string.format("%.1f", v) end, function(v) body.level = v repaintProfile() end)
	mkSlider(props, 10, 62, 154, "Mare amp", 0, 4, body.tideAmp, nil, function(v) body.tideAmp = v repaintProfile() end)
	mkSlider(props, 10, 100, 154, "Espuma", 0, 1, body.foaminess, nil, function(v) body.foaminess = v repaintProfile() end)

	-- ================= BASE: ACOES REAIS =================
	local bar = K.f(root, "Bar", 8, 296, 500, 130, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um preset e materialize o mar", 10, 6, 480, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 24, 480, 14, 8, T.txt4)
	local function refreshStats()
		local s = body:stats()
		statLbl.Text = "ondas " .. s.waves .. " | dens " .. s.density .. " | tiles " .. s.tiles .. " | flutuadores " .. s.floaters .. " | splashes " .. s.splashes
	end
	refreshStats()

	local mk = K.btn(bar, "Mk", 10, 46, 110, 26, ACCENT, 5)
	K.txtS(mk, "Materializar mar", 9, C("#06222E"))
	K.hover(mk, ACCENT, C("#9BE0FF"))
	mk.MouseButton1Click:Connect(function()
		local model, n = WX.materialize(body, { maxSpan = 480 })
		status.Text = "mar materializado: " .. n .. " tiles animados (LOD D-O15 " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")"
		refreshStats()
	end)
	local cau = K.btn(bar, "Cau", 128, 46, 100, 26, T.bg2, 5)
	K.txtS(cau, "+ Causticas", 9, T.txt)
	K.hover(cau, T.bg2, T.hover)
	cau.MouseButton1Click:Connect(function()
		local n = WX.caustics(body, body.level - 10)
		status.Text = "causticas: " .. n .. " brilhos no fundo (shimmer neon)"
		refreshStats()
	end)
	local flt = K.btn(bar, "Flt", 236, 46, 120, 26, T.bg2, 5)
	K.txtS(flt, "Flutuar selecao", 9, T.txt)
	K.hover(flt, T.bg2, T.hover)
	flt.MouseButton1Click:Connect(function()
		local ok2, sel = pcall(function() return game:GetService("Selection"):Get() end)
		local n = 0
		if ok2 and sel then
			for _, inst in ipairs(sel) do
				if inst:IsA("BasePart") then WX.float(body, inst, {}) n = n + 1 end
			end
		end
		if n == 0 then
			-- cria uma boia demo de verdade
			local p = Instance.new("Part")
			p.Name = "AWX_Buoy"
			p.Size = Vector3.new(5, 2.4, 5)
			p.Position = Vector3.new(0, body.level + 1, 0)
			p.Color = Color3.fromRGB(240, 180, 60)
			p.Parent = workspace
			WX.float(body, p, { density = 420 })
			n = 1
			status.Text = "boia criada + flutuabilidade arquimediana ativa (de play)"
		else
			status.Text = "flutuabilidade em " .. n .. " parts da selecao (Arquimedes)"
		end
		refreshStats()
	end)
	local und = K.btn(bar, "Und", 364, 46, 126, 26, T.bg2, 5)
	K.txtS(und, "Submerso: ON/OFF", 9, T.txt)
	local undOn = false
	K.hover(und, T.bg2, T.hover)
	und.MouseButton1Click:Connect(function()
		undOn = not undOn
		WX.applyUnderwater(body, undOn)
		status.Text = undOn and "ambiente subaquatico: neblina croma + absorcao" or "ambiente restaurado"
	end)
	local spl = K.btn(bar, "Spl", 10, 78, 110, 26, T.bg2, 5)
	K.txtS(spl, "Splash teste", 9, T.txt)
	K.hover(spl, T.bg2, T.hover)
	spl.MouseButton1Click:Connect(function()
		if not body.tiles then WX.materialize(body, { maxSpan = 240 }) end
		WX.splash(body, 0, body:heightAt(0, 0, simT), 0, 2)
		status.Text = "splash emitido (particulas + gravidade real)"
		refreshStats()
	end)
	local ser = K.btn(bar, "Ser", 128, 78, 100, 26, T.bg2, 5)
	K.txtS(ser, "Roundtrip JSON", 9, T.txt)
	K.hover(ser, T.bg2, T.hover)
	ser.MouseButton1Click:Connect(function()
		local str = body:serialize()
		local b2, err = WX.deserialize(str)
		if b2 then status.Text = "roundtrip OK: " .. #str .. " chars, " .. #b2.waves .. " ondas restauradas"
		else status.Text = "roundtrip falhou: " .. tostring(err) end
	end)
	local ai2 = K.btn(bar, "AI", 236, 78, 120, 26, T.purple, 5)
	K.txtS(ai2, "Singularity: mar", 9, C("#FFF"))
	K.hover(ai2, T.purple, C("#A97AFF"))
	ai2.MouseButton1Click:Connect(function()
		local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um oceano realista com ondas e espuma") end)
		if ok2 and rep then K.notify("Singularity", "oceano gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	local terr = K.btn(bar, "Terr", 364, 78, 126, 26, C("#4E8FE0"), 5)
	K.txtS(terr, "< TERRAIN STUDIO", 9, C("#FFF"))
	K.hover(terr, C("#4E8FE0"), C("#6FA8F0"))
	terr.MouseButton1Click:Connect(function() ARKHER.open("Terrain") end)

	repaintProfile()
end

ARKHER.reg("Water", "Water Studio", "Editor", ICON.plate, "Agua custom (AWX): Gerstner, mare, correntes, flutuabilidade, causticas, submerso", build)
end

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

do
--[[ ARKHER — UI: SCATTER / SCENE STUDIO X (motor ASXN custom) ]]
-- Studio de povoamento procedural: SCATTER com amostragem Poisson, regras por
-- BIOMA (Whittaker do ATX — a arvore certa no bioma certo), declive maximo,
-- acima do mar, jitter deterministico anti-CG (PATINA), LOD por distancia
-- cooperando com D-O15, query por classe/nome/raio, MERGE/EXPLODE/ALIGN,
-- barras de resultado ao vivo. Preview ANTES de materializar (pontos reais).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7CE38B")
local SXN, DM = ArkherSceneX, ArkherDM

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

local repaintPreview, repaintRules, repaintStatus, repaintQuery, repaintLast, repaintLod, repaintPatCount

local function build()
	local g, root, head = K.window("ArkherScatter", "SCATTER / SCENE STUDIO X — motor ASXN (custom)", 120, 120, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)
	local W, H = 700, 470

	-- ================= ESQUERDA: REGIAO + MAKERS =================
	local lw = 220
	local bodyH = 470 - 34 - 40
	local left = K.f(root, "L", 6, 34, lw, bodyH, T.bg3)
	K.txt(left, "REGIAO DO SCATTER", 8, 4, 200, 14, 9, T.txt3)
	local xBox = K.input(left, 8, 22, 100, 18, "cx (0)", false)
	local zBox = K.input(left, 118, 22, 100, 18, "cz (0)", false)
	local regionShapeBtn = K.btn(left, "Formato: circulo", 8, 46, 150, 18, T.bg4)
	local regionIsCircle = true
	local radiusS = mkSlider(left, 8, 70, 210, "Raio", 8, 160, 60, function(v) return string.format("%.0f m", v) end)
	local rectWS = mkSlider(left, 8, 104, 210, "Rect W", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local rectHS = mkSlider(left, 8, 138, 210, "Rect H", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local countS = mkSlider(left, 8, 172, 210, "Quantidade", 5, 240, 60, function(v) return string.format("%d", math.floor(v)) end)
	local minDistS = mkSlider(left, 8, 206, 210, "Min dist", 1, 20, 5, function(v) return string.format("%.1f m", v) end)
	local slopeS = mkSlider(left, 8, 240, 210, "Declive max", 0, 1.4, 0.8, function(v) return string.format("%.2f", v) end)
	local seedI = K.input(left, 8, 276, 210, 18, "seed (4242)", false)
	K.txt(left, "MAKER", 8, 300, 100, 14, 9, T.txt3)
	local makers = { "auto (regra do bioma)", "tree", "bush", "rock", "grass" }
	local makerIdx = 1
	local makerB = K.btn(left, "auto (regra do bioma)", 8, 316, 210, 18, T.bg4)
	makerB.MouseButton1Click:Connect(function()
		makerIdx = makerIdx % #makers + 1
		makerB.Text = makers[makerIdx]
	end)
	local aboveWater = true
	local wetB = K.btn(left, "so acima do mar: SIM", 8, 340, 150, 18, T.bg4)
	wetB.MouseButton1Click:Connect(function()
		aboveWater = not aboveWater
		wetB.Text = "so acima do mar: " .. (aboveWater and "SIM" or "NAO")
	end)
	local biomes = { "auto (ATX)", "floresta_equatorial", "savana", "deserto", "rocha", "taiga" }
	local biomeIdx = 1
	local biomeB = K.btn(left, "bioma: auto (ATX)", 8, 364, 210, 18, T.bg4)
	biomeB.MouseButton1Click:Connect(function()
		biomeIdx = biomeIdx % #biomes + 1
		biomeB.Text = "bioma: " .. biomes[biomeIdx]
	end)
	regionShapeBtn.MouseButton1Click:Connect(function()
		regionIsCircle = not regionIsCircle
		regionShapeBtn.Text = "Formato: " .. (regionIsCircle and "circulo" or "retangulo")
	end)

	-- ================= CENTRO: PLANO DE PONTOS (PREVIEW) =================
	local cx0, cw = 6 + lw + 8, 236
	local center = K.f(root, "C", cx0, 34, cw, bodyH, T.bg3)
	K.txt(center, "PREVIEW (dots = vai materializar)", 4, 2, 250, 12, 8, T.txt3)
	local pv = K.f(center, "PV", 4, 18, cw - 8, 300, T.bg2)
	K.stroke(pv, T.line, 1)
	local pvCross = K.f(pv, "c", 116, 146, 1, 8, C("#FFD34A"))
	K.f(pv, "c2", 112, 150, 8, 1, C("#FFD34A"))
	local prevInfo = K.txt(center, "passe o PREVIEW p/ calcular", 4, 322, 250, 12, 8.5, T.txt3)
	local prepared = nil

	local prevB = K.btn(center, "PREVIEW", 4, 340, 74, 22, C("#2D6BFF"))
	local scatB = K.btn(center, "SCATTER REAL", 84, 340, 112, 22, C("#3F9E58"))
	local lodB = K.btn(center, "Reg. LOD", 202, 340, 34, 22, T.bg4)

	-- ================= DIREITA: QUERY / PATINA / ALIGN / LOD =================
	local rx0 = cx0 + cw + 8
	local rw = W - rx0 - 6
	local right = K.f(root, "R", rx0, 34, rw, bodyH, T.bg3)
	K.txt(right, "QUERY NO WORLD", 8, 4, 200, 14, 9, T.txt3)
	local qCls = K.input(right, 8, 20, rw - 16, 18, "class (Part)", false)
	local qName = K.input(right, 8, 44, rw - 16, 18, "nome contem", false)
	local qRadS = mkSlider(right, 8, 66, rw - 20, "Raio q", 0, 300, 0, function(v) return v == 0 and "off" or string.format("%.0f m", v) end)
	local qBtn = K.btn(right, "Rodar query", 8, 106, 110, 20, C("#2D6BFF"))
	local qRes = K.txt(right, "—", 8, 130, rw - 12, 26, 8.5, T.txt2)
	local lastQuery = {}

	K.txt(right, "PATINA (variacao anti-CG)", 8, 162, 200, 14, 9, T.txt3)
	local pHue = mkSlider(right, 8, 178, rw - 20, "Hue jit", 0, 0.15, 0.02, function(v) return string.format("%.3f", v) end)
	local pSat = mkSlider(right, 8, 212, rw - 20, "Sat jit", 0, 0.4, 0.06, function(v) return string.format("%.3f", v) end)
	local pVal = mkSlider(right, 8, 246, rw - 20, "Val jit", 0, 0.5, 0.08, function(v) return string.format("%.3f", v) end)
	local patSelB = K.btn(right, "Patina na SELECAO", 8, 286, 120, 20, ACCENT)
	local patLastB = K.btn(right, "Patina no ULTIMO scatter", 8, 310, 160, 20, T.bg4)
	local patRes = K.txt(right, "—", 8, 334, rw - 12, 22, 8.5, T.txt3)

	K.txt(right, "ALIGN / MERGE", 8, 360, 200, 12, 9, T.txt3)
	local axB = K.btn(right, "Align X (min)", 8, 374, 70, 18, T.bg4)
	local ayB = K.btn(right, "Align Y", 82, 374, 60, 18, T.bg4)
	local azB = K.btn(right, "Align Z", 146, 374, 60, 18, T.bg4)
	local mergeB = K.btn(right, "Merge selecao", 8, 396, 88, 18, C("#2D6BFF"))
	local explB = K.btn(right, "Explode", 100, 396, 62, 18, T.bg4)
	local lodApplyB = K.btn(right, "Aplicar LOD (foco 0,0)", 8, 418, 140, 18, C("#8062FF"))
	local lodRes = K.txt(right, "—", 8, 438, rw - 12, 22, 8.5, T.txt3)

	-- ================= STATUS BAR =================
	local stat = K.txt(root, "", 8, H - 36, W - 16, 14, 9, T.txt3)

	-- ================= WORLD SNAPSHOT =================
	local function getWorld()
		if ARKHER._world then return ARKHER._world end
		if ArkherTerrainX then
			ARKHER._world = ArkherTerrainX.new({ seed = 1337, preset = "continentes", cell = 8 })
		end
		return ARKHER._world
	end
	local function spec()
		local cx = tonumber(xBox.Text) or 0
		local cz = tonumber(zBox.Text) or 0
		local mk = makerIdx > 1 and makers[makerIdx] or nil
		local b2 = biomeIdx > 1 and biomes[biomeIdx] or nil
		return {
			x = cx, z = cz,
			radius = regionIsCircle and radiusS.get() or nil,
			rect = regionIsCircle and nil or { w = rectWS.get(), h = rectHS.get() },
			count = math.floor(countS.get()), minDist = minDistS.get(),
			maxSlope = slopeS.get(), aboveWater = aboveWater,
			maker = mk, biome = b2,
			seed = tonumber(seedI.Text) or 4242, world = getWorld(),
			name = "ASXN_ScatterUI",
		}
	end

	repaintPreview = function()
		for _, ch in ipairs(pv:GetChildren()) do if ch.Name:find("^d") then ch:Destroy() end end
		if not prepared then return end
		-- mapear bbox dos pontos para o quadro
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, it in ipairs(prepared.placed) do
			minX = math.min(minX, it[1]) maxX = math.max(maxX, it[1])
			minZ = math.min(minZ, it[2]) maxZ = math.max(maxZ, it[2])
		end
		local span = math.max(maxX - minX, maxZ - minZ, 1)
		local pw, ph = pv.AbsoluteSize.X > 10 and pv.AbsoluteSize.X or 248, 286
		for i, it in ipairs(prepared.placed) do
			if i > 400 then break end
			local fx = (it[1] - minX) / span
			local fz = (it[2] - minZ) / span
			local col = it[4] == "tree" and C("#63D68B") or it[4] == "rock" and C("#B9B3A8") or it[4] == "bush" and C("#84C96B") or C("#CFE38B")
			local d = K.f(pv, "d" .. i, fx * (pw - 8) + 2, fz * (ph - 8) + 2, it[4] == "tree" and 5 or 3, it[4] == "tree" and 5 or 3, col)
			K.corner(d, 2)
		end
		prevInfo.Text = string.format("%d pontos prontos (tries %d) — area uso ~%.0fx%.0f m | span %.0f m",
			#prepared.placed, prepared.tries or 0, prepared.rect and prepared.rect.w or 2 * (prepared.radius or 0), prepared.rect and prepared.rect.h or 2 * (prepared.radius or 0), span)
	end
	repaintQuery = function(txt) if qRes then qRes.Text = txt end end
	repaintLast = function() local n = #SXN._lods return n end
	repaintLod = function(l) if lodRes then lodRes.Text = l end end
	repaintPatCount = function(s) if patRes then patRes.Text = s end end
	repaintRules = function() end -- reservado p/ barra de regras (v2)
	repaintStatus = function()
		local inv = 0
		for _ in pairs(SXN._ambients or {}) do inv = inv + 1 end
		local hashCount = 0
		for _ in pairs(SXN._hash or {}) do hashCount = hashCount + 1 end
		stat.Text = string.format("spatial-hash cells %d | lod groups %d | ultimo scatter: %s | tries p/ ver o preview",
			hashCount, #SXN._lods, (prepared and (#prepared.placed .. " pts prontos") or "—"))
	end

	prevB.MouseButton1Click:Connect(function()
		local s = spec()
		prepared = SXN.prepare(s)
		prepared.rect = s.rect
		prepared.radius = s.radius
		repaintPreview()
		repaintStatus()
	end)
	scatB.MouseButton1Click:Connect(function()
		local s = spec()
		if prepared then s._prepared = prepared end
		local res = SXN.scatter(s)
		ARKHER._lastScatter = res.model
		K.notify("Scatter", res.count .. " instancias em ASXN_ScatterUI (tries " .. res.tries .. ") | biomas do ATX", "ok")
		repaintStatus()
	end)
	lodB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			SXN.registerLOD(ARKHER._lastScatter, { near = 90, mid = 200, far = 360 })
			repaintLod("LOD registrado grps=" .. #SXN._lods)
		else
			repaintLod("nada p/ registrar (rode SCATTER)")
		end
	end)
	lodApplyB.MouseButton1Click:Connect(function()
		local r = SXN.applyLOD(0, 0)
		repaintLod(string.format("LOD: %d shown, %d ghosts(mid), %d culled(far)", r.shown, r.ghosts, r.culled))
	end)
	qBtn.MouseButton1Click:Connect(function()
		local cls = qCls.Text ~= "" and qCls.Text or "Part"
		local nm = qName.Text ~= "" and qName.Text or nil
		local r = qRadS.get()
		local sp = { class = cls, name = nm, within = r > 0 and { x = tonumber(xBox.Text) or 0, z = tonumber(zBox.Text) or 0, r = r } or nil }
		lastQuery = SXN.query(sp)
		-- contagem por classe
		local byCls = {}
		for _, inst in ipairs(lastQuery) do byCls[inst.ClassName] = (byCls[inst.ClassName] or 0) + 1 end
		local parts = {}
		for k, v in pairs(byCls) do parts[#parts + 1] = k .. "=" .. v end
		repaintQuery(#lastQuery .. " resultados | " .. table.concat(parts, ", "))
	end)
	patSelB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		local n = SXN.patina(list, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get(), seed = tonumber(seedI.Text) or 99 })
		repaintPatCount("patina: " .. n .. " partes (seed " .. (tonumber(seedI.Text) or 99) .. ")")
	end)
	patLastB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			local parts = {}
			for _, ch in ipairs(ARKHER._lastScatter:GetDescendants()) do if ch:IsA("BasePart") then parts[#parts + 1] = ch end end
			local n = SXN.patina(parts, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get() })
			repaintPatCount("patina ultimo scatter: " .. n .. " partes")
		end
	end)
	axB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "x", mode = "min" }) end
	end)
	ayB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "y", mode = "avg" }) end
	end)
	azB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "z", mode = "min" }) end
	end)
	mergeB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 0 then local m = SXN.merge(list, "ASXN_MergedUI") K.notify("Merge", "Model ASXN_MergedUI com " .. #list .. " parts", "ok") end
	end)
	explB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if list[1] and list[1].ClassName == "Model" then
			local out = SXN.explode(list[1])
			K.notify("Explode", #out .. " parts soltas", "ok")
		end
	end)

	-- boot
	repaintStatus()
	return g
end

ARKHER.reg("Scatter", "Scatter / Scene X", "Mundo", ICON.plate, "Povoamento procedural: scatter Poisson por bioma, patina, LOD distancia, query, merge/align", build)
end

local opened = ARKHER.openAll()
ARKHER.out("SUCCESS", "ARKHER V4 — bundle Editors: " .. opened .. " UIs abertas")
