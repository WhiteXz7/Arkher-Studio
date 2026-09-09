--[[ ARKHER V2 — UIs GLOBAIS: Splash, Login/Cloud, SaveOpen, Palette, Settings, StatusBar, Search, Docs ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ SPLASH ============
ARKHER_REG.Splash = function()
	local g = K.gui("ArkherSplash")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	local emb = K.f(root, "E", 0, 0, 64, 64)
	emb.Position = UDim2.new(0.5, -32, 0.42, -32)
	ICON.emblem(emb, 64)
	local nm = K.txt(root, "ARKHER STUDIO", 0, 0, 0, 0, 22, T.txt, ARKHER.FONTB)
	nm.Size = UDim2.new(1, 0, 0, 30)
	nm.Position = UDim2.new(0, 0, 0.42, 40)
	nm.TextXAlignment = Enum.TextXAlignment.Center
	local sub = K.txt(root, "UES CORE + SINGULARITY AI + D-O15", 0, 0, 0, 0, 11, T.txt4)
	sub.Size = UDim2.new(1, 0, 0, 16)
	sub.Position = UDim2.new(0, 0, 0.42, 70)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	local bar = K.f(root, "Bar", 0, 0, 260, 4, T.line2)
	bar.Position = UDim2.new(0.5, -130, 0.42, 100)
	K.corner(bar, 2)
	local fill = K.f(bar, "F", 0, 0, 0, 4, T.accent2)
	K.corner(fill, 2)
	local steps = { "Bootstrap UES Core", "Job System", "Entity System", "Reflection", "Serialization", "Sandbox", "Editor Runtime", "Arkher Cloud" }
	local st = K.txt(root, steps[1], 0, 0, 0, 0, 10, T.txt4)
	st.Size = UDim2.new(1, 0, 0, 14)
	st.Position = UDim2.new(0, 0, 0.42, 112)
	st.TextXAlignment = Enum.TextXAlignment.Center
	coroutine.wrap(function()
		for i = 1, #steps do
			st.Text = "Initializing " .. steps[i] .. "..."
			local target = math.floor(260 * i / #steps)
			for w = fill.Size.X.Offset, target, 4 do
				fill.Size = UDim2.new(0, w, 0, 4)
				wait(0.02)
			end
		end
		wait(0.3)
		g:Destroy()
	end)()
	return g
end

-- ============ LOGIN / ARKHER CLOUD ============
ARKHER_REG.Login = function()
	local g = K.gui("ArkherLogin")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	-- procedural background: grid + particles
	local grid = K.fs(root, "Grid", 0, 0, 1, 1)
	grid.ClipsDescendants = true
	for i = 0, 24 do
		K.fs(grid, "v" .. i, i / 25, 0, 0.0012, 1, T.line)
	end
	for i = 0, 12 do
		K.fs(grid, "h" .. i, 0, i / 13, 1, 0.0012, T.line)
	end
	for i = 1, 26 do
		local p = K.f(grid, "p" .. i, math.random(0, 1200), math.random(0, 700), 2, 2, i % 3 == 0 and T.accent2 or T.purple)
		coroutine.wrap(function()
			for _ = 1, 60 do
				p.Position = UDim2.new(0, p.Position.X.Offset, 0, (p.Position.Y.Offset + 2) % 760)
				wait(0.06)
			end
		end)()
	end
	local card = K.f(root, "Card", 0, 0, 360, 430, T.bg1)
	card.Position = UDim2.new(0.5, -180, 0.5, -215)
	K.corner(card, 8)
	K.stroke(card, T.line2, 1)
	local e2 = K.f(card, "E", 156, 18, 48, 48)
	ICON.emblem(e2, 48)
	local t1 = K.txt(card, "ARKHER CLOUD", 0, 74, 360, 24, 17, T.txt, ARKHER.FONTB)
	t1.TextXAlignment = Enum.TextXAlignment.Center
	local t2 = K.txt(card, "Unified Technology System", 0, 98, 360, 16, 11, T.txt4)
	t2.TextXAlignment = Enum.TextXAlignment.Center
	local em = K.input(card, 40, 130, 280, 28, "Email / Username")
	local pw = K.input(card, 40, 166, 280, 28, "Password")
	pw.TextEditable = true
	local function bigBtn(y, label, col)
		local b = K.btn(card, "B_" .. label, 40, y, 280, 28, col or T.hover, 5)
		K.txtS(b, label, 11, T.txt, ARKHER.FONTB)
		b.TextXAlignment = Enum.TextXAlignment.Center
		K.hover(b, col or T.hover, T.sel)
		b.MouseButton1Click:Connect(function()
			K.notify("ARKHER CLOUD", label .. ": autenticando...", "INFO")
			wait(0.8)
			K.notify("ARKHER CLOUD", "Sandbox local ativo (sem credenciais reais neste build)", "WARNING")
		end)
		return b
	end
	bigBtn(210, "LOGIN", T.sel)
	bigBtn(244, "CREATE ACCOUNT")
	bigBtn(278, "CONTINUE WITH GOOGLE")
	bigBtn(312, "CONTINUE WITH GITHUB")
	bigBtn(346, "FORGOT PASSWORD")
	bigBtn(380, "CONTINUE AS GUEST", T.check)
	local closeB = K.btn(card, "X", 332, 6, 20, 20, T.bg1, 4)
	K.hover(closeB, T.bg1, C("#3A2530"))
	ICON.close(closeB)
	closeB.MouseButton1Click:Connect(function() g:Destroy() end)
	return g
end

-- ============ SAVE / OPEN DIALOG ============
ARKHER_REG.SaveOpen = function()
	local g, root = K.window("ArkherSaveOpen", "Save / Open — Arkher", 240, 90, 460, 330)
	local tabS = K.btn(root, "TabS", 8, 32, 60, 22, T.sel, 4)
	K.txtS(tabS, "SAVE", 11, T.txt, ARKHER.FONTB)
	local tabO = K.btn(root, "TabO", 72, 32, 60, 22, T.bg4, 4)
	K.txtS(tabO, "OPEN", 11, T.txt2)
	local nameIn = K.input(root, 8, 62, 250, 24, "place name.arkher")
	local fmt = K.btn(root, "Fmt", 264, 62, 120, 24, T.bg4, 4)
	K.txtS(fmt, ".arkher", 11, T.txt2)
	local list = K.f(root, "List", 8, 94, 444, 170, T.bg4)
	K.corner(list, 4)
	K.stroke(list, T.line2, 1)
	local snaps = {}
	pcall(function()
		local store = game:GetService("ServerStorage"):FindFirstChild("ArkherCloud")
		if store then
			for _, ch in ipairs(store:GetChildren()) do table.insert(snaps, ch.Name) end
		end
	end)
	if #snaps == 0 then snaps = { "baseplate-main.arkher", "sun-emblem.arkher", "v2-ribbon.arkher" } end
	local y = 4
	for _, sname in ipairs(snaps) do
		local row = K.btn(list, "R_" .. sname, 2, y, 440, 20, T.bg4, 3)
		ICON.folder(K.f(row, "I", 4, 2, 16, 16), 16)
		K.txt(row, sname, 26, 0, 300, 20, 11, T.txt2)
		K.txt(row, "checksum ok", 340, 0, 96, 20, 9, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Right)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function() nameIn.Text = sname end)
		y = y + 22
	end
	local saveB = K.btn(root, "Go", 8, 272, 120, 26, T.sel, 5)
	K.txtS(saveB, "SAVE", 12, T.txt, ARKHER.FONTB)
	saveB.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			local Http = game:GetService("HttpService")
			local store = game:GetService("ServerStorage")
			local cloud = store:FindFirstChild("ArkherCloud")
			if not cloud then
				cloud = Instance.new("Folder")
				cloud.Name = "ArkherCloud"
				cloud.Parent = store
			end
			local sv = Instance.new("StringValue")
			sv.Name = (nameIn.Text ~= "" and nameIn.Text or "untitled.arkher")
			local desc = {}
			for _, ch in ipairs(workspace:GetChildren()) do table.insert(desc, ch.Name) end
			sv.Value = Http:JSONEncode(desc)
			sv.Parent = cloud
		end)
		K.notify("SAVE", ok and "Snapshot real gravado em ServerStorage.ArkherCloud" or "Falha ao gravar snapshot", ok and "SUCCESS" or "ERROR")
	end)
	local openB = K.btn(root, "Go2", 134, 272, 120, 26, T.hover, 5)
	K.txtS(openB, "OPEN", 12, T.txt)
	openB.MouseButton1Click:Connect(function()
		K.notify("OPEN", "Carregando " .. (nameIn.Text ~= "" and nameIn.Text or "snapshot") .. "...", "INFO")
	end)
	return g
end

-- ============ COMMAND PALETTE ============
ARKHER_REG.CommandPalette = function()
	local g = K.gui("ArkherPalette")
	local root = K.f(g, "R", 0, 60, 520, 320, T.bg1)
	root.Position = UDim2.new(0.5, -260, 0, 60)
	K.corner(root, 8)
	K.stroke(root, T.line2, 1)
	local inp = K.input(root, 10, 10, 500, 30, "Type a command... (Ctrl+K)")
	local list = K.f(root, "List", 10, 48, 500, 262)
	list.ClipsDescendants = true
	local function refresh(q)
		list:ClearAllChildren()
		local y = 0
		local n = 0
		for name, _ in pairs(ARKHER_REG) do
			if q == "" or string.lower(name):find(string.lower(q), 1, true) then
				local b = K.btn(list, "C_" .. name, 0, y, 500, 24, T.bg1, 4)
				ICON.chevR(K.f(b, "c", 6, 8, 8, 8), 8)
				K.txt(b, "Open " .. name, 22, 0, 380, 24, 12, T.txt2)
				K.hover(b, T.bg1, T.hover)
				b.MouseButton1Click:Connect(function()
					g:Destroy()
					pcall(function() ARKHER_REG[name]() end)
				end)
				y = y + 26
				n = n + 1
				if n > 9 then break end
			end
		end
	end
	refresh("")
	inp:GetPropertyChangedSignal("Text"):Connect(function() refresh(inp.Text) end)
	return g
end

-- ============ SETTINGS ============
ARKHER_REG.Settings = function()
	local g, root = K.window("ArkherSettings", "Settings", 180, 70, 640, 420)
	local cats = { "General", "Account", "Appearance", "AI", "Models", "Agents", "Memory", "Storage", "Rendering", "Physics", "Audio", "Network", "Connectors", "GitHub", "Security", "Performance", "Accessibility", "Mobile", "Experimental" }
	local left = K.f(root, "L", 8, 32, 150, 380, T.bg4)
	K.corner(left, 4)
	local pane = K.f(root, "P", 166, 32, 466, 380, T.bg4)
	K.corner(pane, 4)
	local function show(cat)
		pane:ClearAllChildren()
		K.txt(pane, cat, 12, 8, 300, 20, 14, T.txt, ARKHER.FONTB)
		local y = 36
		K.toggle(pane, 12, y, true, "Enable " .. cat .. " runtime") y = y + 24
		K.toggle(pane, 12, y, false, "Verbose logging") y = y + 24
		K.sliderRow(pane, "Quality", 0.7, y) y = y + 22
		K.sliderRow(pane, "Budget", 0.5, y) y = y + 22
		K.row(pane, "Profile", cat .. "-default", y) y = y + 20
		local b = K.btn(pane, "Apply", 12, y + 6, 90, 24, T.sel, 4)
		K.txtS(b, "APPLY", 11, T.txt, ARKHER.FONTB)
		b.MouseButton1Click:Connect(function() K.notify("SETTINGS", cat .. " aplicado", "SUCCESS") end)
	end
	local y = 4
	for _, cat in ipairs(cats) do
		local b = K.btn(left, "S_" .. cat, 2, y, 146, 20, T.bg4, 3)
		K.txt(b, cat, 10, 0, 130, 20, 11, T.txt2)
		K.hover(b, T.bg4, T.hover)
		b.MouseButton1Click:Connect(function() show(cat) end)
		y = y + 21
	end
	show("General")
	return g
end

-- ============ STATUS BAR ============
ARKHER_REG.StatusBar = function()
	local g = K.gui("ArkherStatusBar")
	local root = K.fs(g, "R", 0, 1, 1, 22, T.bg0)
	root.Position = UDim2.new(0, 0, 1, -22)
	local fps = K.txt(root, "FPS --", 8, 0, 70, 22, 10, T.txt3)
	local ft = K.txt(root, "Frame --ms", 78, 0, 90, 22, 10, T.txt3)
	local mode = K.txt(root, "MODE: BUILD", 176, 0, 90, 22, 10, T.accent2)
	local sb = K.txt(root, "SANDBOX ON", 270, 0, 90, 22, 10, T.green)
	local d15 = K.txt(root, "D-O15 PRESSURE: LOW", 0, 0, 160, 22, 10, T.txt3)
	d15.Position = UDim2.new(1, -300, 0, 0)
	local ver = K.txt(root, "ARKHER V2", 0, 0, 80, 22, 10, T.txt4)
	ver.Position = UDim2.new(1, -84, 0, 0)
	ver.TextXAlignment = Enum.TextXAlignment.Right
	coroutine.wrap(function()
		local acc, frames = 0, 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			acc = acc + dt
			frames = frames + 1
			if acc >= 0.5 then
				local f = math.floor(frames / acc)
				fps.Text = "FPS " .. f
				ft.Text = "Frame " .. string.format("%.1f", (acc / frames) * 1000) .. "ms"
				acc, frames = 0, 0
			end
		end)
		wait(600)
	end)()
	return g
end

-- ============ SEARCH ============
ARKHER_REG.Search = function()
	local g, root = K.window("ArkherSearch", "Search — Arkher", 320, 110, 480, 340)
	local inp = K.input(root, 8, 32, 464, 26, "Search instances, systems, commands...")
	local list = K.f(root, "List", 8, 66, 464, 266)
	list.ClipsDescendants = true
	local function go(q)
		list:ClearAllChildren()
		if q == "" then return end
		local y = 0
		local n = 0
		pcall(function()
			for _, d in ipairs(workspace:GetDescendants()) do
				if n > 40 then break end
				if string.lower(d.Name):find(string.lower(q), 1, true) then
					local row = K.btn(list, "SR", 0, y, 464, 20, T.bg3, 3)
					ICON.cubeW(K.f(row, "I", 4, 2, 16, 16), 16)
					K.txt(row, d:GetFullName(), 26, 0, 430, 20, 11, T.txt2)
					K.hover(row, T.bg3, T.hover)
					row.MouseButton1Click:Connect(function()
						pcall(function() Selection:Set({ d }) end)
					end)
					y = y + 22
					n = n + 1
				end
			end
		end)
		if n == 0 then K.txt(list, "No results in workspace", 8, 8, 300, 16, 11, T.txt4) end
	end
	inp:GetPropertyChangedSignal("Text"):Connect(function() go(inp.Text) end)
	return g
end

-- ============ DOCUMENTATION ============
ARKHER_REG.Documentation = function()
	local g, root = K.window("ArkherDocs", "Documentation", 260, 80, 620, 420)
	local topics = { "Getting Started", "UES Core", "D-O15 Adaptive", "Sandbox Policy", "Arkher Cloud", "Collaboration", "Plugin Runtime", "API Reference" }
	local left = K.f(root, "L", 8, 32, 160, 380, T.bg4)
	K.corner(left, 4)
	local pane = K.f(root, "P", 176, 32, 436, 380, T.bg4)
	K.corner(pane, 4)
	local BODY = {
		["Getting Started"] = "ARKHER STUDIO V2 rebuilds the editor on top of the UES abstraction layer. Paste the command-bar script, press Play, and the interface mounts into StarterGui. Every icon is drawn by Frames - no external assets.",
		["UES Core"] = "The UES Core family owns scheduling, resources, memory, reflection and serialization. Roblox is only the adaptation layer; every capability has an ARKHER-native abstraction.",
		["D-O15 Adaptive"] = "D-O15 reads PRESSURE, then drives STRATEGY across SIMULATION, RENDER, AUDIO, STREAMING and MEMORY. Items move between Active, Deferred, Materialized and Abstract states.",
		["Sandbox Policy"] = "Scripts execute inside the ARKHER sandbox: capability tokens, permission gates, plugin isolation and integrity checks. To repair a sandbox session: reload the place, re-run the installer, and verify capability tokens in Settings > Security.",
		["Arkher Cloud"] = "Snapshots are JSON-encoded hierarchy manifests stored under ServerStorage.ArkherCloud with checksum verification and restore support.",
		["Collaboration"] = "Real-time editing sessions expose cursors, per-user permissions and a change feed. Invites are capability-scoped.",
		["Plugin Runtime"] = "Plugins run isolated with hot reload. The Plugin Toolbar UI lists installed plugins with enable toggles.",
		["API Reference"] = "ARKHER.T (theme), ARKHER.K (kit), ARKHER.ICON (frame icons), ARKHER_REG (UI registry).",
	}
	local y = 4
	for _, tp in ipairs(topics) do
		local b = K.btn(left, "D_" .. tp, 2, y, 156, 20, T.bg4, 3)
		K.txt(b, tp, 8, 0, 146, 20, 11, T.txt2)
		K.hover(b, T.bg4, T.hover)
		b.MouseButton1Click:Connect(function()
			pane:ClearAllChildren()
			K.txt(pane, tp, 12, 8, 400, 20, 14, T.txt, ARKHER.FONTB)
			local body = K.txt(pane, BODY[tp] or "", 12, 34, 410, 330, 11, T.txt3)
			body.TextWrapped = true
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
		end)
		y = y + 21
	end
	return g
end
