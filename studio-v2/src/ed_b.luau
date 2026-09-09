--[[ ARKHER V2 — EDITORES CRIATIVOS ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ SCRIPT EDITOR ============
ARKHER_REG.ScriptEditor = function()
	local g, root = K.window("ArkherScriptEditor", "Script Editor", 140, 60, 700, 460)
	local tabs = { "ServerMain.lua", "ArkherCore.lua", "D_O15.lua" }
	local tx = 8
	for i, tn in ipairs(tabs) do
		local tb = K.btn(root, "T" .. i, tx, 30, 120, 22, i == 1 and T.bg2 or T.bg4, 4)
		K.txt(tb, tn, 8, 0, 96, 22, 10, i == 1 and T.txt or T.txt3)
		local xx = K.btn(tb, "x", 102, 3, 14, 14, tb.BackgroundColor3, 3)
		ICON.close(xx)
		tx = tx + 124
	end
	local gutter = K.f(root, "Gut", 8, 56, 34, 330, T.bg4)
	K.corner(gutter, 4)
	local code = Instance.new("TextBox")
	code.Name = "Code"
	code.Parent = root
	code.Position = UDim2.new(0, 46, 0, 56)
	code.Size = UDim2.new(0, 646, 0, 330)
	code.BackgroundColor3 = T.bg0
	code.BorderSizePixel = 0
	code.TextColor3 = C("#9FE8C0")
	code.TextSize = 12
	code.Font = ARKHER.MONO
	code.MultiLine = true
	code.TextEditable = true
	code.TextXAlignment = Enum.TextXAlignment.Left
	code.TextYAlignment = Enum.TextYAlignment.Top
	code.Text = "-- ARKHER V2\nlocal UES = require(game.ReplicatedStorage.UES)\n\nlocal function tick(dt)\n\tUES.JobSystem.schedule(dt)\nend\n\nreturn { tick = tick }"
	K.corner(code, 4)
	local lines = K.txt(gutter, "1\n2\n3\n4\n5\n6\n7\n8\n9", 6, 4, 24, 320, 11, T.txt4, ARKHER.MONO)
	lines.TextYAlignment = Enum.TextYAlignment.Top
	code:GetPropertyChangedSignal("Text"):Connect(function()
		local n = 1
		for _ in string.gmatch(code.Text, "\n") do n = n + 1 end
		local s = {}
		for i = 1, n do table.insert(s, tostring(i)) end
		lines.Text = table.concat(s, "\n")
	end)
	local term = K.f(root, "Term", 8, 392, 684, 36, T.bg0)
	K.corner(term, 4)
	local tout = K.txt(term, "arkher:~ ", 8, 0, 560, 36, 11, T.green, ARKHER.MONO)
	local runB = K.btn(root, "Run", 610, 30, 60, 22, T.green, 4)
	K.txtS(runB, "RUN", 11, T.bg0, ARKHER.FONTB)
	runB.MouseButton1Click:Connect(function()
		local fn, cerr = loadstring(code.Text)
		local ok, rerr = fn and pcall(fn) or false, cerr
		if not ok then
			tout.Text = "arkher:~ " .. tostring(rerr)
		else
			tout.Text = "arkher:~ executed ok"
		end
	end)
	return g
end

-- ============ CONSOLE / OUTPUT ============
ARKHER_REG.Console = function()
	local g, root = K.window("ArkherConsole", "Console / Output", 200, 120, 640, 380)
	local cats = { "UTS", "UES", "AI", "WORLD", "RENDER", "PHYSICS", "AUDIO", "STORAGE", "NETWORK", "TOOLS" }
	local active = { UTS = true, UES = true, AI = true, WORLD = true, RENDER = true, PHYSICS = true, AUDIO = true, STORAGE = true, NETWORK = true, TOOLS = true }
	local cx = 8
	local chips = {}
	for _, cn in ipairs(cats) do
		local ch = K.btn(root, "C_" .. cn, cx, 30, 14 + #cn * 6, 18, T.sel, 9)
		K.txtS(ch, cn, 9, T.txt, ARKHER.FONTB)
		chips[cn] = ch
		ch.MouseButton1Click:Connect(function()
			active[cn] = not active[cn]
			ch.BackgroundColor3 = active[cn] and T.sel or T.bg4
		end)
		cx = cx + 18 + #cn * 6
	end
	local exp = K.btn(root, "Exp", 560, 30, 70, 18, T.hover, 4)
	K.txtS(exp, "EXPORT", 9, T.txt2)
	exp.MouseButton1Click:Connect(function() K.notify("CONSOLE", "Log exportado (snapshot em memória)", "SUCCESS") end)
	local area = K.f(root, "Area", 8, 54, 624, 290, T.bg0)
	K.corner(area, 4)
	area.ClipsDescendants = true
	local yl = 4
	local function log(cat, sev, msg)
		if not active[cat] then return end
		local col = sev == "ERR" and C("#E05252") or sev == "WARN" and T.orange or sev == "OK" and T.green or T.txt3
		local r = K.txt(area, "[" .. cat .. "] " .. msg, 6, yl, 610, 14, 10, col, ARKHER.MONO)
		yl = yl + 15
	end
	log("UES", "OK", "Job System online (12 workers)")
	log("UES", "INFO", "Entity System registered 4.096 entities")
	log("AI", "INFO", "Singularity orchestration ready")
	log("RENDER", "WARN", "D-O15 deferred 214 abstract items")
	log("PHYSICS", "INFO", "Collision matrix rebuilt")
	log("STORAGE", "OK", "Integrity checksum verified")
	log("NETWORK", "INFO", "Replication graph stable")
	local inl = K.input(root, 8, 350, 560, 24, "> command")
	local send = K.btn(root, "S", 574, 350, 58, 24, T.sel, 4)
	K.txtS(send, "RUN", 10, T.txt)
	send.MouseButton1Click:Connect(function()
		log("TOOLS", "INFO", "> " .. inl.Text)
		inl.Text = ""
	end)
	return g
end

-- ============ DEBUGGER ============
ARKHER_REG.Debugger = function()
	local g, root = K.window("ArkherDebugger", "Debugger", 260, 90, 660, 420)
	local tb = { { "cont", ICON.play }, { "step", ICON.chevD }, { "stop", ICON.pause } }
	local bx = 8
	for _, b in ipairs(tb) do
		local bb = K.btn(root, "DB" .. bx, bx, 30, 30, 24, T.hover, 4)
		b[2](bb, 16, 7, 4)
		K.hover(bb, T.hover, T.sel)
		bx = bx + 34
	end
	local stack = K.f(root, "Stack", 8, 60, 200, 250, T.bg4)
	K.corner(stack, 4)
	K.txt(stack, "CALL STACK", 8, 4, 120, 16, 10, T.txt4, ARKHER.FONTB)
	local fr = { "UES.tick @ JobSystem:118", "D_O15.materialize :42", "Entity.spawn :201", "main :12" }
	local fy = 24
	for _, f in ipairs(fr) do
		local r = K.btn(stack, "F", 2, fy, 196, 18, T.bg4, 3)
		K.txt(r, f, 8, 0, 186, 18, 10, T.txt2, ARKHER.MONO)
		K.hover(r, T.bg4, T.hover)
		fy = fy + 19
	end
	local bp = K.f(root, "BP", 216, 60, 210, 250, T.bg4)
	K.corner(bp, 4)
	K.txt(bp, "BREAKPOINTS", 8, 4, 140, 16, 10, T.txt4, ARKHER.FONTB)
	local bps = { { "JobSystem:118", true }, { "D_O15:42", true }, { "Entity:201", false } }
	local by = 24
	for _, b in ipairs(bps) do
		K.checkRow(bp, b[1], b[2], by)
		by = by + 20
	end
	local watch = K.f(root, "W", 434, 60, 218, 250, T.bg4)
	K.corner(watch, 4)
	K.txt(watch, "WATCH", 8, 4, 120, 16, 10, T.txt4, ARKHER.FONTB)
	K.row(watch, "dt", "0.0166", 26)
	K.row(watch, "pressure", "0.32", 46)
	K.row(watch, "entities", "4096", 66)
	K.row(watch, "state", "ACTIVE", 86)
	local ai = K.btn(root, "AIT", 8, 318, 644, 66, T.bg0, 4)
	K.txt(ai, "AI TRACE: interpreted -> planned -> executed -> verified (last run: PASS)", 10, 6, 620, 16, 10, T.accent2, ARKHER.MONO)
	K.txt(ai, "tool calls: 14 | errors: 0 | corrections: 1", 10, 26, 620, 16, 10, T.txt3, ARKHER.MONO)
	return g
end

-- ============ PROFILER / PERFORMANCE ============
ARKHER_REG.Profiler = function()
	local g, root = K.window("ArkherProfiler", "Profiler / Performance", 220, 100, 620, 400)
	local bars = {}
	local names = { "SIMULATION", "RENDER", "PHYSICS", "AUDIO", "STREAMING", "MEMORY" }
	local y = 40
	for _, n in ipairs(names) do
		K.txt(root, n, 10, y + 2, 90, 14, 10, T.txt3)
		local track = K.f(root, "T_" .. n, 110, y + 4, 380, 10, T.bg4)
		K.corner(track, 3)
		local fill = K.f(track, "F", 0, 0, 120, 10, T.accent2)
		K.corner(fill, 3)
		local val = K.txt(root, "0.0ms", 500, y, 60, 16, 10, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Right)
		bars[n] = { fill = fill, val = val }
		y = y + 22
	end
	local graph = K.f(root, "G", 10, y + 10, 600, 130, T.bg0)
	K.corner(graph, 4)
	graph.ClipsDescendants = true
	local cols = {}
	for i = 0, 59 do
		cols[i] = K.f(graph, "c" .. i, i * 10, 0, 8, 40, T.green)
		cols[i].AnchorPoint = Vector2.new(0, 1)
		cols[i].Position = UDim2.new(0, i * 10, 1, 0)
	end
	coroutine.wrap(function()
		while wait(0.25) do
			for n, b in pairs(bars) do
				local v = math.random(8, 92)
				b.fill.Size = UDim2.new(0, math.floor(380 * v / 100), 0, 10)
				b.val.Text = string.format("%.1fms", v / 6)
			end
			for i = 0, 58 do
				cols[i].Size = UDim2.new(0, 8, 0, cols[i + 1] and cols[i + 1].Size.Y.Offset or 40)
			end
			cols[59].Size = UDim2.new(0, 8, 0, math.random(10, 120))
		end
	end)()
	return g
end

-- ============ TIMELINE / SEQUENCER ============
ARKHER_REG.Timeline = function()
	local g, root = K.window("ArkherTimeline", "Timeline / Sequencer", 180, 140, 720, 360)
	local tr = { "Camera.Cut", "Lighting.Ambient", "NPC.Walk", "Audio.Theme", "VFX.Fog" }
	local tx = { ICON.camera, ICON.bulb, ICON.playersI, ICON.chat, ICON.gem }
	local ruler = K.f(root, "Ruler", 140, 32, 572, 20, T.bg4)
	for i = 0, 28 do
		K.f(ruler, "t" .. i, i * 20, i % 5 == 0 and 8 or 12, 1, i % 5 == 0 and 12 or 8, T.txt4)
		if i % 5 == 0 then K.txt(ruler, tostring(i), i * 20 + 2, 0, 18, 10, 8, T.txt4) end
	end
	local playhead = K.f(root, "PH", 140 + 80, 32, 2, 260, T.orange)
	local y = 56
	for i, tn in ipairs(tr) do
		K.txt(root, tn, 8, y + 4, 120, 18, 10, T.txt2)
		local lane = K.f(root, "L" .. i, 140, y, 572, 26, T.bg4)
		K.corner(lane, 3)
		local kf = { 20, 120, 260, 420 }
		for _, kx in ipairs(kf) do
			local d = K.f(lane, "K", kx, 7, 10, 10, T.orange)
			d.Rotation = 45
			K.corner(d, 2)
		end
		if i == 1 then
			local clip = K.f(lane, "Clip", 60, 4, 200, 18, T.sel)
			K.corner(clip, 3)
			K.txt(clip, "Shot_A", 6, 0, 120, 18, 9, T.txt)
		end
		y = y + 30
	end
	local transport = { { ICON.pause, "pause" }, { ICON.play, "play" }, { ICON.rotate, "loop" } }
	local px2 = 8
	for _, tb in ipairs(transport) do
		local b = K.btn(root, "TR", px2, 30, 26, 22, T.hover, 4)
		tb[1](b, 14, 6, 4)
		K.hover(b, T.hover, T.sel)
		if tb[2] == "play" then
			b.MouseButton1Click:Connect(function()
				coroutine.wrap(function()
					for xx = 0, 560, 4 do
						playhead.Position = UDim2.new(0, 140 + xx, 0, 32)
						wait(0.03)
					end
				end)()
			end)
		end
		px2 = px2 + 30
	end
	return g
end

-- ============ MATERIAL EDITOR ============
ARKHER_REG.MaterialEditor = function()
	local g, root = K.window("ArkherMaterialEditor", "Material Editor", 240, 80, 620, 400)
	local prev
	local mats = { "Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Slate", "Concrete", "Marble", "Granite", "Brick", "Pebble", "Sand", "Fabric", "Rock", "Glacier", "Snow", "Sandstone", "Mud", "Basalt", "CrackedLava", "Foil", "Glass", "Asphalt", "LeafyGrass", "Salt", "Limestone" }
	local cols = { C("#A3A8B5"), C("#C7CDD8"), C("#37F5C8"), C("#8E9AAD"), C("#8F5F2C"), C("#5E6E86"), C("#8A8F98"), C("#D8D3CC"), C("#B58F77"), C("#B0492F"), C("#9C8B77"), C("#D8C08A"), C("#7A5C48"), C("#6E6A63"), C("#A8D8E8"), C("#F2F6FB"), C("#C8A877"), C("#6B4E38"), C("#3E4247"), C("#E86A3C"), C("#D8DDE6"), C("#BFE8F2"), C("#3E4245"), C("#4CAF50"), C("#F5F2E8"), C("#D8CDB5") }
	local x, y = 8, 36
	for i, m in ipairs(mats) do
		local sw = K.btn(root, "M" .. i, x, y, 34, 34, cols[i], 4)
		K.stroke(sw, T.line2, 1)
		sw.MouseButton1Click:Connect(function()
			prev.BackgroundColor3 = cols[i]
			K.notify("MATERIAL", m .. " selecionado", "INFO")
		end)
		x = x + 38
		if x > 380 then x = 8 y = y + 38 end
	end
	prev = K.f(root, "Prev", 420, 40, 160, 160, C("#8E9AAD"))
	K.corner(prev, 80)
	K.grad(prev, C("#FFFFFF"), C("#20242C"), 135)
	local py = 210
	for _, s in ipairs({ { "Roughness", 0.4 }, { "Metalness", 0.6 }, { "Sheen", 0.2 }, { "Emission", 0.1 } }) do
		K.sliderRow(root, s[1], s[2], py)
		py = py + 22
	end
	return g
end

-- ============ TERRAIN EDITOR ============
ARKHER_REG.TerrainEditor = function()
	local g, root = K.window("ArkherTerrainEditor", "ARKHER Terrain Editor", 200, 90, 640, 420)
	local tools = { "Raise", "Lower", "Smooth", "Flatten", "Paint", "Erase", "Sculpt", "Water" }
	local y = 40
	for i, tn in ipairs(tools) do
		local b = K.btn(root, "TT" .. tn, 8, y, 90, 24, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, tn, 11, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		b.MouseButton1Click:Connect(function() K.notify("TERRAIN", "Brush: " .. tn, "INFO") end)
		y = y + 28
	end
	K.sliderRow(root, "Size", 0.5, y + 6)
	K.sliderRow(root, "Strength", 0.7, y + 28)
	local pal = { C("#3ECF7A"), C("#8F5F2C"), C("#D8C08A"), C("#6E6A63"), C("#A8D8E8"), C("#F2F6FB") }
	local pxx = 8
	for i, pc in ipairs(pal) do
		local sw = K.btn(root, "TP" .. i, pxx, y + 56, 22, 22, pc, 3)
		K.stroke(sw, T.line2, 1)
		pxx = pxx + 26
	end
	local hm = K.f(root, "HM", 130, 40, 496, 360, T.bg0)
	K.corner(hm, 4)
	hm.ClipsDescendants = true
	for ry = 0, 14 do
		for cx = 0, 23 do
			local hgt = math.abs(math.sin(cx * 0.7) * math.cos(ry * 0.5))
			local col = hgt > 0.66 and C("#3ECF7A") or hgt > 0.33 and C("#8F5F2C") or C("#2A6BC0")
			local cell = K.f(hm, "c", cx * 20 + 4, ry * 24 + 4, 19, 23, col)
			K.corner(cell, 2)
			cell.BackgroundTransparency = 0.15 + (1 - hgt) * 0.5
		end
	end
	return g
end

-- ============ ANIMATION EDITOR ============
ARKHER_REG.AnimationEditor = function()
	local g, root = K.window("ArkherAnimationEditor", "ARKHER Animation Editor", 190, 110, 700, 380)
	local parts = { "HumanoidRootPart", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }
	local y = 60
	for i, p in ipairs(parts) do
		K.txt(root, p, 8, y + 3, 130, 18, 10, T.txt2)
		local lane = K.f(root, "AL" .. i, 150, y, 540, 24, T.bg4)
		K.corner(lane, 3)
		for _, kx in ipairs({ 30 + i * 40, 180 + i * 20, 380 }) do
			local d = K.f(lane, "K", kx, 7, 10, 10, T.accent2)
			d.Rotation = 45
			K.corner(d, 2)
		end
		y = y + 28
	end
	local ruler = K.f(root, "R", 150, 36, 540, 18, T.bg4)
	for i = 0, 27 do K.f(ruler, "t" .. i, i * 20, i % 5 == 0 and 6 or 10, 1, i % 5 == 0 and 12 or 8, T.txt4) end
	local eb = K.btn(root, "Ease", 8, 36, 130, 20, T.bg4, 4)
	K.txtS(eb, "Easing: Quad Out", 10, T.txt2)
	eb.MouseButton1Click:Connect(function() K.notify("ANIMATION", "Ciclo de easing alternado", "INFO") end)
	return g
end

-- ============ PARTICLE EDITOR ============
ARKHER_REG.ParticleEditor = function()
	local g, root = K.window("ArkherParticleEditor", "ARKHER VFX / Particle Editor", 250, 70, 600, 420)
	local py = 40
	for _, s in ipairs({ { "Rate", 0.6 }, { "Lifetime", 0.4 }, { "Speed", 0.5 }, { "Spread", 0.3 }, { "Size", 0.45 }, { "Gravity", 0.7 }, { "Turbulence", 0.2 } }) do
		K.sliderRow(root, s[1], s[2], py)
		py = py + 22
	end
	local prev = K.f(root, "Prev", 240, 36, 350, 370, T.bg0)
	K.corner(prev, 4)
	prev.ClipsDescendants = true
	local emit = K.f(prev, "E", 170, 330, 12, 8, T.orange)
	K.corner(emit, 2)
	local pool = {}
	for i = 1, 40 do
		pool[i] = K.f(prev, "p" .. i, 170 + math.random(-6, 6), 320, 4, 4, i % 2 == 0 and T.orange or T.yellow)
		K.corner(pool[i], 2)
	end
	coroutine.wrap(function()
		while wait(0.05) do
			for i = 1, 40 do
				local p = pool[i]
				local yy = p.Position.Y.Offset - 6
				local xx = p.Position.X.Offset + math.random(-4, 4)
				if yy < 10 then xx = 170 + math.random(-6, 6) yy = 320 end
				p.Position = UDim2.new(0, xx, 0, yy)
				p.BackgroundTransparency = yy / 340
			end
		end
	end)()
	return g
end

-- ============ VFX EDITOR ============
ARKHER_REG.VFXEditor = function()
	local g, root = K.window("ArkherVFXEditor", "ARKHER VFX Editor", 280, 100, 560, 380)
	local layers = { "Bloom", "Glow", "Fog", "ColorGrade", "Scanlines", "ChromaticAberr" }
	local y = 40
	for i, l in ipairs(layers) do
		K.toggle(root, 10, y, i <= 2, l)
		y = y + 22
	end
	local gy = y + 8
	for _, s in ipairs({ { "Intensity", 0.55 }, { "Threshold", 0.35 }, { "Saturation", 0.6 }, { "Contrast", 0.5 } }) do
		K.sliderRow(root, s[1], s[2], gy)
		gy = gy + 22
	end
	local grade = K.f(root, "Grade", 240, 40, 300, 120, T.bg0)
	K.corner(grade, 4)
	K.grad(grade, T.purple, T.accent2, 0)
	local curve = K.f(root, "Curve", 240, 170, 300, 120, T.bg0)
	K.corner(curve, 4)
	for i = 0, 20 do
		local h = 60 + math.sin(i * 0.5) * 40
		K.f(curve, "c" .. i, i * 14, 120 - h, 3, h, T.accent2)
	end
	return g
end
