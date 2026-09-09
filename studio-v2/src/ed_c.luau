--[[ ARKHER V2 — SISTEMAS UES: Audio, Physics, Navigation, AI, World, UIEditor, Nodes, Graph, UTS AI ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ AUDIO EDITOR ============
ARKHER_REG.AudioEditor = function()
	local g, root = K.window("ArkherAudioEditor", "ARKHER Audio Editor", 210, 80, 640, 400)
	local chans = { "Master", "Environment", "Ambience", "SFX", "Voices", "Music", "Weather", "UI" }
	local x = 10
	local meters = {}
	for i, ch in ipairs(chans) do
		local strip = K.f(root, "S_" .. ch, x, 40, 46, 300, T.bg4)
		K.corner(strip, 4)
		local mtrack = K.f(strip, "MT", 8, 10, 8, 220, T.bg0)
		K.corner(mtrack, 3)
		local mfill = K.f(mtrack, "F", 0, 0, 8, 120, T.green)
		mfill.AnchorPoint = Vector2.new(0, 1)
		mfill.Position = UDim2.new(0, 0, 1, 0)
		K.corner(mfill, 3)
		K.vfader(strip, 24, 10, 220, 0.8 - i * 0.05, nil)
		K.txt(strip, ch, 0, 240, 46, 24, 8, T.txt3, ARKHER.FONT, Enum.TextXAlignment.Center)
		meters[i] = mfill
		x = x + 52
	end
	local spatial = K.f(root, "SP", x + 10, 40, 180, 300, T.bg4)
	K.corner(spatial, 4)
	K.txt(spatial, "SPATIALIZATION", 8, 6, 140, 14, 9, T.txt4, ARKHER.FONTB)
	local listener = K.f(spatial, "L", 85, 140, 10, 10, T.accent2)
	K.corner(listener, 5)
	for i = 1, 6 do
		local a = i * 60
		local sx = 90 + math.cos(math.rad(a)) * 60
		local sy = 145 + math.sin(math.rad(a)) * 60
		local src = K.f(spatial, "src" .. i, sx, sy, 6, 6, T.yellow)
		K.corner(src, 3)
	end
	K.toggle(spatial, 8, 260, true, "HRTF")
	coroutine.wrap(function()
		while wait(0.12) do
			for i = 1, #meters do
				meters[i].Size = UDim2.new(0, 8, 0, math.random(30, 210))
			end
		end
	end)()
	return g
end

-- ============ PHYSICS EDITOR ============
ARKHER_REG.PhysicsEditor = function()
	local g, root = K.window("ArkherPhysicsEditor", "ARKHER Physics Editor", 230, 90, 660, 420)
	K.sliderRow(root, "Gravity", 0.97, 40)
	K.sliderRow(root, "Timestep", 0.4, 62)
	local matL = { "Default", "Metal", "Wood", "Rock", "Ice", "Rubber" }
	local matT = { "Default", "Metal", "Wood", "Rock", "Ice", "Rubber" }
	K.txt(root, "COLLISION MATRIX", 300, 40, 200, 16, 10, T.txt4, ARKHER.FONTB)
	local gx, gy = 300, 60
	for i, a in ipairs(matL) do
		K.txt(root, a, 40, gy + 2, 60, 16, 9, T.txt3)
		for j, b in ipairs(matT) do
			local on = (i + j) % 3 ~= 0
			local cell = K.btn(root, "CM" .. i .. j, gx + (j - 1) * 22, gy, 18, 18, on and T.check or T.bg4, 3)
			K.stroke(cell, T.line2, 1)
			cell.MouseButton1Click:Connect(function()
				cell.BackgroundColor3 = cell.BackgroundColor3 == T.check and T.bg4 or T.check
			end)
		end
		gy = gy + 22
	end
	for j, b in ipairs(matT) do
		local tt = K.txt(root, string.sub(b, 1, 3), gx + (j - 1) * 22, 42, 20, 14, 9, T.txt3)
	end
	local bodies = K.f(root, "B", 470, 60, 180, 240, T.bg4)
	K.corner(bodies, 4)
	K.txt(bodies, "BODIES", 8, 4, 80, 14, 9, T.txt4, ARKHER.FONTB)
	local bl = { "Baseplate (static)", "SpamPoint (dyn)", "Ball_01 (dyn)", "Ragdoll_NPC", "Vehicle_02" }
	local by = 22
	for _, bn in ipairs(bl) do
		local r = K.btn(bodies, "B_" .. bn, 2, by, 176, 18, T.bg4, 3)
		K.txt(r, bn, 8, 0, 160, 18, 10, T.txt2)
		K.hover(r, T.bg4, T.hover)
		by = by + 19
	end
	K.row(root, "Contacts", "1.284", 320)
	K.row(root, "Forces", "96", 340)
	K.row(root, "Constraints", "42", 360)
	return g
end

-- ============ NAVIGATION EDITOR ============
ARKHER_REG.NavigationEditor = function()
	local g, root = K.window("ArkherNavigationEditor", "ARKHER Navigation Editor", 260, 100, 600, 380)
	local agents = { "Humanoid", "Vehicle", "Flyer", "Crowd" }
	local y = 40
	for i, a in ipairs(agents) do
		local b = K.btn(root, "A_" .. a, 8, y, 110, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, a, 11, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		y = y + 26
	end
	K.sliderRow(root, "Radius", 0.3, y + 8)
	K.sliderRow(root, "Height", 0.6, y + 30)
	K.sliderRow(root, "Slope", 0.45, y + 52)
	local nav = K.f(root, "Nav", 150, 40, 440, 320, T.bg0)
	K.corner(nav, 4)
	nav.ClipsDescendants = true
	for ry = 0, 12 do
		for cx = 0, 17 do
			local v = math.sin(cx * 0.6 + ry) * math.cos(ry * 0.4)
			if v > -0.2 then
				local cell = K.f(nav, "n", cx * 24 + 4, ry * 24 + 4, 22, 22, v > 0.5 and T.teal or T.sel)
				K.corner(cell, 2)
				cell.BackgroundTransparency = 0.45
			end
		end
	end
	local path = K.f(nav, "p0", 30, 300, 60, 3, T.orange)
	path.Rotation = -35
	local path2 = K.f(nav, "p1", 80, 250, 90, 3, T.orange)
	path2.Rotation = -10
	return g
end

-- ============ AI EDITOR (Singularity) ============
ARKHER_REG.AIEditor = function()
	local g, root = K.window("ArkherAIEditor", "Singularity AI Editor", 190, 70, 700, 460)
	local modes = { "CHAT", "BUILD", "AUTO" }
	local mx = 8
	for i, m in ipairs(modes) do
		local b = K.btn(root, "MD_" .. m, mx, 30, 64, 22, i == 3 and T.sel or T.bg4, 4)
		K.txtS(b, m, 11, i == 3 and T.txt or T.txt2, ARKHER.FONTB)
		K.hover(b, b.BackgroundColor3, T.hover)
		mx = mx + 70
	end
	local prompt = K.input(root, 8, 58, 684, 40, "Describe what to create / change...")
	prompt.TextWrapped = true
	local agents = { "Architect", "Coder", "Researcher", "Designer", "Graphics", "Physics", "Audio", "World", "QA", "Optimizer" }
	local ax, ay = 8, 108
	for i, a in ipairs(agents) do
		local card = K.f(root, "AG_" .. a, ax, ay, 128, 64, T.bg4)
		K.corner(card, 5)
		K.stroke(card, T.line2, 1)
		ICON.gem(K.f(card, "I", 8, 8, 16, 16), 16)
		K.txt(card, a, 30, 6, 92, 16, 11, T.txt, ARKHER.FONTB)
		K.txt(card, "status: idle", 8, 28, 110, 12, 9, T.txt4)
		K.txt(card, "model: AUTO", 8, 42, 110, 12, 9, T.accent2)
		ax = ax + 134
		if ax > 560 then ax = 8 ay = ay + 70 end
	end
	local plan = K.f(root, "Plan", 8, 260, 684, 160, T.bg0)
	K.corner(plan, 4)
	local steps = { "Interpret request", "Plan", "Execute", "Verify", "Correct", "Complete" }
	local sy = 8
	for i, s in ipairs(steps) do
		local done = i <= 3
		local dot = K.f(plan, "D" .. i, 12, sy + 2, 10, 10, done and T.green or T.line2)
		K.corner(dot, 5)
		K.txt(plan, s, 30, sy, 200, 14, 11, done and T.txt2 or T.txt4)
		if i < 6 then K.f(plan, "ln", 16, sy + 12, 1, 10, T.line2) end
		sy = sy + 24
	end
	K.txt(plan, "AUTO: interpret -> plan -> execute -> verify -> correct -> complete", 260, 12, 410, 14, 10, T.accent2, ARKHER.MONO)
	K.txt(plan, "context: page=AIEditor | selection=none | world=base", 260, 32, 410, 14, 10, T.txt3, ARKHER.MONO)
	return g
end

-- ============ WORLD EDITOR ============
ARKHER_REG.WorldEditor = function()
	local g, root = K.window("ArkherWorldEditor", "ARKHER World Editor", 220, 80, 680, 440)
	local biomes = { "Temperate", "Desert", "Tundra", "Tropical", "Volcanic" }
	local bx = 8
	for i, b in ipairs(biomes) do
		local bb = K.btn(root, "BI_" .. b, bx, 30, 20 + #b * 6, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(bb, b, 10, i == 1 and T.txt or T.txt2)
		K.hover(bb, bb.BackgroundColor3, T.hover)
		bx = bx + 26 + #b * 6
	end
	local y = 62
	for _, s in ipairs({ { "Temperature", 0.5 }, { "Humidity", 0.6 }, { "Wind", 0.3 }, { "Rain", 0.2 }, { "Clouds", 0.4 } }) do
		K.sliderRow(root, s[1], s[2], y)
		y = y + 22
	end
	local dial = K.f(root, "Dial", 300, 70, 120, 120, T.bg0)
	K.corner(dial, 60)
	K.stroke(dial, T.line2, 1)
	local sun = K.f(dial, "Sun", 60, 12, 14, 14, T.yellow)
	K.corner(sun, 7)
	local hand = K.f(dial, "H", 58, 20, 3, 40, T.accent2)
	hand.AnchorPoint = Vector2.new(0.5, 1)
	hand.Position = UDim2.new(0.5, 0, 0.5, 0)
	hand.Rotation = 35
	K.txt(root, "DAY / NIGHT", 300, 194, 120, 14, 9, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Center)
	local speeds = { "1x", "10x", "100x", "1000x" }
	local sx = 460
	for i, sp in ipairs(speeds) do
		local b = K.btn(root, "SP_" .. sp, sx, 80, 44, 22, i == 2 and T.sel or T.bg4, 4)
		K.txtS(b, sp, 10, i == 2 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		sx = sx + 48
	end
	local pb = K.btn(root, "WPlay", 460, 110, 44, 22, T.hover, 4)
	ICON.play(pb, 14, 15, 4)
	local pb2 = K.btn(root, "WPause", 508, 110, 44, 22, T.hover, 4)
	ICON.pause(pb2, 14, 15, 4)
	local stats = K.f(root, "ST", 460, 150, 210, 180, T.bg4)
	K.corner(stats, 4)
	K.row(stats, "Population", "12.480", 8)
	K.row(stats, "Entities", "96.214", 28)
	K.row(stats, "Biome", "Temperate", 48)
	K.row(stats, "Weather", "Clear", 68)
	K.row(stats, "Sim tick", "30Hz", 88)
	K.row(stats, "D-O15", "ACTIVE", 108)
	return g
end

-- ============ UI EDITOR ============
ARKHER_REG.UIEditor = function()
	local g, root = K.window("ArkherUIEditor", "ARKHER UI Editor", 250, 90, 660, 420)
	local comps = { "ScreenGui", "  Frame.HUD", "    HealthBar", "    StaminaBar", "  Frame.Minimap", "  TextLabel.Score" }
	local y = 40
	for i, cp in ipairs(comps) do
		local depth = #cp - #cp:gsub(" ", "")
		local r = K.btn(root, "UC" .. i, 8, y, 190, 20, i == 3 and T.sel or T.bg4, 3)
		K.txt(r, cp:gsub(" ", ""), 8 + depth * 12, 0, 170, 20, 10, T.txt2)
		K.hover(r, r.BackgroundColor3, T.hover)
		y = y + 21
	end
	local canvas = K.f(root, "CV", 210, 40, 280, 360, T.bg0)
	K.corner(canvas, 4)
	local hud = K.f(canvas, "HUD", 10, 10, 260, 340, nil)
	K.stroke(hud, T.line, 1)
	local hb = K.f(hud, "HB", 10, 10, 160, 12, T.bg4)
	K.corner(hb, 6)
	local hbf = K.f(hb, "F", 0, 0, 110, 12, T.green)
	K.corner(hbf, 6)
	K.stroke(hbf, C("#7FE0A8"), 1)
	local sb = K.f(hud, "SB", 10, 26, 120, 8, T.bg4)
	K.corner(sb, 4)
	local sbf = K.f(sb, "F", 0, 0, 80, 8, T.accent2)
	K.corner(sbf, 4)
	local sel = K.f(hud, "SEL", 8, 8, 164, 16, nil)
	K.stroke(sel, T.orange, 1)
	local props = K.f(root, "PR", 500, 40, 150, 360, T.bg4)
	K.corner(props, 4)
	K.txt(props, "HealthBar", 8, 4, 130, 16, 11, T.txt, ARKHER.FONTB)
	K.row(props, "Anchor", "TopLeft", 26)
	K.row(props, "Size", "160,12", 46)
	K.row(props, "Radius", "6", 66)
	K.row(props, "Value", "0.68", 86)
	return g
end

-- ============ NODE / SHADER / VISUAL SCRIPTING ============
local function nodeCanvas(title, nodeDefs)
	local g, root = K.window("Arkher" .. title, title, 200, 70, 720, 460)
	local palette = K.f(root, "PAL", 8, 32, 130, 420, T.bg4)
	K.corner(palette, 4)
	local py = 6
	for _, pd in ipairs(nodeDefs) do
		local b = K.btn(palette, "P_" .. pd[1], 4, py, 122, 20, T.bg4, 3)
		K.txt(b, pd[1], 8, 0, 110, 20, 10, T.txt2)
		K.hover(b, T.bg4, T.hover)
		py = py + 21
	end
	local canvas = K.f(root, "CV", 146, 32, 566, 420, T.bg0)
	K.corner(canvas, 4)
	canvas.ClipsDescendants = true
	for gx = 0, 27 do K.f(canvas, "g" .. gx, gx * 20, 0, 1, 420, T.line) end
	for gy = 0, 20 do K.f(canvas, "h" .. gy, 0, gy * 20, 566, 1, T.line) end
	local nodes = {}
	for i, nd in ipairs(nodeDefs) do
		local n = K.f(canvas, "N" .. i, nd[2], nd[3], 140, 26 + 16 * #nd[4], T.bg2)
		K.corner(n, 5)
		K.stroke(n, nd[5] or T.line2, 1)
		K.f(n, "HD", 0, 0, 140, 20, nd[5] or T.sel)
		K.txt(n, nd[1], 8, 0, 124, 20, 10, T.txt, ARKHER.FONTB)
		local iy = 24
		for _, port in ipairs(nd[4]) do
			K.f(n, "pin", -4, iy + 2, 8, 8, T.accent2)
			K.txt(n, port, 8, iy, 90, 12, 9, T.txt3)
			K.f(n, "pout", 136, iy + 2, 8, 8, T.orange)
			iy = iy + 16
		end
		K.drag(K.f(n, "drag", 0, 0, 140, 20, nil), n)
		nodes[i] = n
	end
	local function wire(a, b, col)
		local na, nb = nodes[a], nodes[b]
		local x1 = na.Position.X.Offset + 140
		local y1 = na.Position.Y.Offset + 30
		local x2 = nb.Position.X.Offset
		local y2 = nb.Position.Y.Offset + 30
		local len = math.max(20, x2 - x1)
		local w = K.f(canvas, "W", x1, (y1 + y2) / 2, len, 2, col or T.accent2)
		w.Rotation = math.deg(math.atan(y2 - y1, len))
	end
	if #nodes >= 2 then
		wire(1, 2)
		if #nodes >= 3 then wire(2, 3, T.orange) end
	end
	return g
end
ARKHER_REG.ShaderEditor = function()
	return nodeCanvas("ShaderEditor", {
		{ "Base Color", 30, 40, { "Albedo", "Tint" }, T.purple },
		{ "PBR Master", 240, 90, { "Rough", "Metal", "Normal", "Emission" }, T.sel },
		{ "Fresnel", 40, 220, { "Power" }, T.teal },
		{ "Output", 460, 140, { "Surface" }, T.orange },
	})
end
ARKHER_REG.VisualScripting = function()
	return nodeCanvas("VisualScripting", {
		{ "OnStart", 20, 30, { "exec" }, T.green },
		{ "Spawn Entity", 220, 60, { "exec", "entity" }, T.sel },
		{ "Set Velocity", 220, 200, { "exec", "vec3" }, T.accent },
		{ "Loop x10", 430, 120, { "body", "done" }, T.orange },
	})
end
ARKHER_REG.NodeEditor = function()
	return nodeCanvas("NodeEditor", {
		{ "Input", 20, 40, { "value" }, T.teal },
		{ "Math.Add", 220, 80, { "a", "b" }, T.sel },
		{ "Math.Mul", 220, 220, { "a", "b" }, T.purple },
		{ "Output", 440, 150, { "in" }, T.orange },
	})
end

-- ============ GRAPH EDITOR ============
ARKHER_REG.GraphEditor = function()
	local g, root = K.window("ArkherGraphEditor", "Graph Editor", 240, 110, 640, 380)
	local cv = K.f(root, "CV", 8, 32, 624, 300, T.bg0)
	K.corner(cv, 4)
	cv.ClipsDescendants = true
	for gx = 0, 30 do K.f(cv, "g" .. gx, gx * 20, 0, 1, 300, T.line) end
	for gy = 0, 14 do K.f(cv, "h" .. gy, 0, gy * 20, 624, 1, T.line) end
	local pts = { { 40, 240 }, { 160, 90 }, { 300, 160 }, { 460, 60 }, { 600, 120 } }
	for i = 1, #pts - 1 do
		local x1, y1 = pts[i][1], pts[i][2]
		local x2, y2 = pts[i + 1][1], pts[i + 1][2]
		local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
		local seg = K.f(cv, "seg" .. i, x1, y1, len, 2, T.accent2)
		seg.Rotation = math.deg(math.atan(y2 - y1, x2 - x1))
	end
	for i, p in ipairs(pts) do
		local d = K.f(cv, "K" .. i, p[1] - 5, p[2] - 5, 10, 10, T.orange)
		d.Rotation = 45
		K.corner(d, 2)
		local h1 = K.f(cv, "H" .. i, p[1] - 24, p[2] - 1, 20, 2, T.purple)
		local hh = K.f(cv, "HH" .. i, p[1] - 28, p[2] - 4, 8, 8, T.purple)
		K.corner(hh, 4)
	end
	local interp = K.btn(root, "INT", 8, 340, 140, 22, T.bg4, 4)
	K.txtS(interp, "Interp: Bezier", 10, T.txt2)
	interp.MouseButton1Click:Connect(function() K.notify("GRAPH", "Interp: Bezier -> Linear -> Constant", "INFO") end)
	return g
end

-- ============ UTS AI HOME ============
ARKHER_REG.UTSAI = function()
	local g = K.gui("ArkherUTSAI")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	local emb = K.f(root, "E", 0, 0, 72, 72)
	emb.Position = UDim2.new(0.42, -36, 0.24, 0)
	ICON.emblem(emb, 72)
	local ti = K.txt(root, "ARKHER", 0, 0, 0, 30, 24, T.txt, ARKHER.FONTB)
	ti.Size = UDim2.new(1, 0, 0, 30)
	ti.Position = UDim2.new(0, 0, 0.24, 20)
	ti.TextXAlignment = Enum.TextXAlignment.Center
	local sub = K.txt(root, "How can I help you create?", 0, 0, 0, 20, 13, T.txt3)
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Position = UDim2.new(0, 0, 0.24, 54)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	local prompt = K.input(root, 0, 0, 560, 44, "What do you want to create?")
	prompt.Position = UDim2.new(0.5, -280, 0.45, 0)
	prompt.TextWrapped = true
	local att = { "Attach", "Image", "Video", "Audio", "Document", "Code", "URL", "File" }
	local ax = -260
	for _, a in ipairs(att) do
		local w = 18 + #a * 6
		local b = K.btn(root, "AT_" .. a, 0, 0, w, 20, T.bg2, 10)
		b.Position = UDim2.new(0.5, ax, 0.45, 52)
		K.txtS(b, a, 10, T.txt2)
		K.hover(b, T.bg2, T.hover)
		ax = ax + w + 6
	end
	local hist = K.f(root, "H", 0, 0, 240, 10, T.bg1)
	hist.Position = UDim2.new(1, -250, 0, 60)
	hist.Size = UDim2.new(0, 240, 1, -120)
	K.corner(hist, 6)
	K.stroke(hist, T.line, 1)
	K.txt(hist, "HISTORY", 10, 8, 120, 16, 10, T.txt4, ARKHER.FONTB)
	local nb = K.btn(hist, "NEW", 150, 6, 80, 20, T.sel, 4)
	K.txtS(nb, "+ NEW CHAT", 9, T.txt)
	local items = { "Medieval world + river", "NPC economy tuning", "Rewrite D-O15 strategy", "Physics audit", "Publish pipeline" }
	local hy = 32
	for _, it in ipairs(items) do
		local r = K.btn(hist, "H_" .. it, 4, hy, 232, 22, T.bg1, 3)
		K.txt(r, it, 8, 0, 216, 22, 10, T.txt2)
		K.hover(r, T.bg1, T.hover)
		hy = hy + 24
	end
	return g
end
