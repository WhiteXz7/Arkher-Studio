--[[ ARKHER V3 — MAIN UI: o shell do editor (fiel a Recording_20260908_174341.jpg) ]]
-- Titlebar + 6 menus reais + toolbar com acoes reais + Properties live + Hierarchy live
-- + viewport NATIVO do Roblox (sem frame fake) + status bar com dados reais.
local Players = game:GetService("Players")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local function BUILD_MAIN()
	local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
	local TITLE_H, MENU_H, RIB_H, STATUS_H = 26, 24, 78, 24
	local LEFT_W, RIGHT_W = 250, 222
	local TOP = TITLE_H + MENU_H + RIB_H

	local g = K.gui("ArkherStudioMainUI")
	local root = K.f(g, "Root", 0, 0, 10, 10, T.bg1)
	root.Size = UDim2.new(1, 0, 1, 0)

	-- ================= TITLE BAR =================
	local title = K.f(root, "TitleBar", 0, 0, 10, TITLE_H, T.bg0)
	title.Size = UDim2.new(1, 0, 0, TITLE_H)
	local emb = K.f(title, "Emblem", 8, 4, 18, 18)
	ICON.emblem(emb, 18)
	K.txt(title, "ARKHER STUDIO", 30, 0, 180, TITLE_H, 12, T.txt, ARKHER.FONTB)
	local placeLbl = K.txt(title, ARKHER.STATE.placeName, 140, 0, 300, TITLE_H, 10, T.txt4)
	local win = K.f(title, "Win", 0, 0, 80, TITLE_H)
	win.Position = UDim2.new(1, -80, 0, 0)
	local bmin = K.btn(win, "Min", 6, 5, 24, 16, T.bg0, 3)
	K.hover(bmin, T.bg0, T.hover)
	ICON.minus(bmin)
	bmin.MouseButton1Click:Connect(function()
		local vp = root:FindFirstChild("ViewportArea")
		if vp then vp.Visible = not vp.Visible end
	end)
	local bmax = K.btn(win, "Max", 38, 5, 24, 16, T.bg0, 3)
	K.hover(bmax, T.bg0, T.hover)
	ICON.square(bmax)
	local bclose = K.btn(win, "Close", 70, 5, 24, 16, T.bg0, 3)
	K.hover(bclose, T.bg0, C("#3A2530"))
	ICON.close(bclose)
	bclose.MouseButton1Click:Connect(function()
		K.notify("ARKHER", "Feche pelo Studio (o shell ARKHER persiste entre places)", "INFO")
	end)

	-- ================= MENU BAR =================
	local menu = K.f(root, "MenuBar", 0, TITLE_H, 10, MENU_H, T.bg1)
	menu.Size = UDim2.new(1, 0, 0, MENU_H)
	local function recentList()
		local items = {}
		local places = ArkherPlaces and ArkherPlaces.list() or {}
		if #places == 0 then items[#items + 1] = "(vazio)" else
			for i, p in ipairs(places) do
				if i > 6 then break end
				items[#items + 1] = { label = (p.name or "?") .. "  [" .. tostring(p.id) .. "]", cmd = "place.open", tpl = p.id }
			end
		end
		return items
	end
	local MENUS = {
		FILE = {
			{ label = "New Place", items = {
				{ label = "Baseplate", cmd = "place.new", tpl = "Baseplate" },
				{ label = "City", cmd = "place.new", tpl = "City" },
				{ label = "Nature", cmd = "place.new", tpl = "Nature" },
				{ label = "Space", cmd = "place.new", tpl = "Space" },
				{ label = "Empty", cmd = "place.new", tpl = "Empty" },
			} },
			{ label = "Save", cmd = "file.save" },
			{ label = "Open...", cmd = "file.open" },
			{ label = "Save to Arkher Cloud", cmd = "file.savecloud" },
			"-",
			{ label = "Import Bundle...", cmd = "file.import" },
			{ label = "Export Place...", cmd = "file.export" },
			"-",
			{ label = "Recent Places", recent = true },
			{ label = "Close Place", cmd = "place.close" },
		},
		EDIT = {
			{ label = "Undo", cmd = "edit.undo", ks = "Ctrl+Z" },
			{ label = "Redo", cmd = "edit.redo", ks = "Ctrl+Y" },
			"-",
			{ label = "Cut", cmd = "edit.cut", ks = "Ctrl+X" },
			{ label = "Copy", cmd = "edit.copy", ks = "Ctrl+C" },
			{ label = "Paste", cmd = "edit.paste", ks = "Ctrl+V" },
			"-",
			{ label = "Delete", cmd = "edit.delete", ks = "Del" },
			{ label = "Duplicate", cmd = "edit.duplicate", ks = "Ctrl+D" },
			{ label = "Rename...", cmd = "edit.rename" },
		},
		VIEW = {
		{ label = "Properties", cmd = "view.properties" },
		{ label = "Hierarchy", cmd = "view.hierarchy" },
		{ label = "Console", cmd = "view.console" },
		{ label = "Command Palette", cmd = "view.palette", ks = "Ctrl+K" },
		{ label = "Painéis", panels = true },
		"-",
			{ label = "Fullscreen Viewport", cmd = "view.fullscreen" },
			{ label = "Reset Layout", cmd = "view.reset" },
			{ label = "Sandbox: ON", cmd = "sandbox.toggle" },
		},
		INSERT = {
			{ label = "Part", cmd = "insert.part" },
			{ label = "Sphere", cmd = "insert.sphere" },
			{ label = "Cylinder", cmd = "insert.cylinder" },
			{ label = "Wedge", cmd = "insert.wedge" },
			"-",
			{ label = "Model", cmd = "insert.model" },
			{ label = "Folder", cmd = "insert.folder" },
			"-",
			{ label = "Script", cmd = "insert.script" },
			{ label = "LocalScript", cmd = "insert.localscript" },
			{ label = "ModuleScript", cmd = "insert.modulescript" },
			"-",
			{ label = "Text", cmd = "insert.text" },
			{ label = "Light", cmd = "insert.light" },
			{ label = "Sound", cmd = "insert.sound" },
		},
		RUN = {
			{ label = "Play", cmd = "run.play" },
			{ label = "Pause", cmd = "run.pause" },
			{ label = "Stop", cmd = "run.stop" },
			"-",
			{ label = "Run Diagnostics", cmd = "run.diagnostics" },
			{ label = "Performance Stats", cmd = "run.perf" },
			"-",
			{ label = "Sandbox: ON", cmd = "sandbox.toggle" },
		},
		GAME = {
			{ label = "Game Settings", cmd = "game.settings" },
			{ label = "Places", cmd = "game.places" },
			"-",
			{ label = "Publish to Arkher", cmd = "publish.local" },
			{ label = "Publish to Roblox", cmd = "publish.native" },
			"-",
			{ label = "Passes", cmd = "game.passes" },
			{ label = "Developer Products", cmd = "game.products" },
		},
	}
	local mx = 8
	for _, name in ipairs({ "FILE", "EDIT", "VIEW", "INSERT", "RUN", "GAME" }) do
		local mb = K.btn(menu, "M_" .. name, mx, 2, 46, 20, T.bg1, 3)
		K.txtS(mb, name, 11, T.txt2)
		K.hover(mb, T.bg1, T.hover)
		mb.MouseButton1Click:Connect(function()
			local items = MENUS[name]
			-- recent + paineis dinamicos
			local final = {}
			for _, it in ipairs(items) do
				if type(it) == "table" and it.recent then
					final[#final + 1] = { label = "Recent Places", items = recentList() }
				elseif type(it) == "table" and it.panels then
					local pl = {}
					for _, nm in ipairs(ARKHER.listUIs()) do
						local cat = ARKHER.CATALOG[nm]
						pl[#pl + 1] = { label = (cat and cat.title) or nm, cmd = "ui.open", tpl = nm }
					end
					table.sort(pl, function(a, b) return a.label < b.label end)
					final[#final + 1] = { label = "Painéis (" .. #pl .. ")", items = pl }
				else
					final[#final + 1] = it
				end
			end
			K.dropdown(menu, mb, final)
		end)
		mx = mx + 50
	end
	local rightMenu = K.f(menu, "Right", 0, 0, 300, MENU_H)
	rightMenu.Position = UDim2.new(1, -300, 0, 0)
	local rx = 8
	for _, nm in ipairs({ "Collaborate", "Invites", "Changes" }) do
		local w = 26 + #nm * 6
		local b = K.btn(rightMenu, "RM_" .. nm, rx, 2, w, 20, T.bg1, 3)
		K.txtS(b, nm, 11, T.txt3)
		K.hover(b, T.bg1, T.hover)
		b.MouseButton1Click:Connect(function()
			if nm == "Collaborate" then ARKHER.open("Collaboration")
			elseif nm == "Invites" then ARKHER.open("Collaboration")
			else ARKHER.open("VersionControl") end
		end)
		rx = rx + w + 4
	end
	local chip = K.btn(rightMenu, "User", rx, 2, 44, 20, T.sec, 10)
	K.txtS(chip, "ARKH", 9, T.txt, ARKHER.FONTB)
	K.hover(chip, T.sec, T.hover)
	chip.MouseButton1Click:Connect(function() ARKHER.open("Login") end)

	-- ================= TOOLBAR (RIBBON) =================
	local rib = K.f(root, "Ribbon", 0, TOP - RIB_H, 10, RIB_H, T.bg2)
	rib.Size = UDim2.new(1, 0, 0, RIB_H)
	local groups = {
		{ { "Save", "save", "file.save" }, { "Open", "open", "file.open" }, { "Save to Arkher", "cloud", "file.savecloud" } },
		{ { "Select", "select", "tool:Select" }, { "Move", "move", "tool:Move" }, { "Scale", "scaleI", "tool:Scale" }, { "Rotate", "rotate", "tool:Rotate" }, { "Transform", "transform", "transform.lock" } },
		{ { "Model", "model", "insert.model" }, { "Folder", "folder", "insert.folder" }, { "Script", "script", "insert.script" }, { "Text", "textA", "insert.text" } },
		{ { "Play", "play", "run.play" }, { "Pause", "pause", "run.pause" }, { "Data", "data", "ui.DataManager" }, { "Localization", "globe", "ui.Localization" }, { "Settings", "settings", "game.settings" } },
		{ { "Toolbox", "toolbox", "ui.Toolbox" }, { "Collaboration Settings", "people", "ui.Collaboration" } },
		{ { "Arkher Cloud", "info", "cloud.status" }, { "Plugin Toolbar", "plugin", "ui.PluginManager" } },
	}
	local gx = 8
	for _, grp in ipairs(groups) do
		if gx > 8 then
			K.f(rib, "Sep", gx, 14, 1, 50, T.line)
			gx = gx + 8
		end
		for _, item in ipairs(grp) do
			local label, icon, cmd = item[1], item[2], item[3]
			local w = math.max(56, #label * 5 + 22)
			local b = K.ribbonBtn(rib, gx, w, ICON[icon], label, {})
			if cmd:sub(1, 5) == "tool:" then
				local toolName = cmd:sub(6)
				b._tool = toolName
				b.MouseButton1Click:Connect(function() ARKHER.cmd("tool", toolName) end)
			elseif cmd == "transform.lock" then
				b.MouseButton1Click:Connect(function()
					K.dropdown(rib, b, {
						{ label = "Lock", cmd = "transform.lock" },
						{ label = "Local/Global", cmd = "transform.mode" },
					})
				end)
			else
				b.MouseButton1Click:Connect(function() ARKHER.cmd(cmd) end)
			end
			gx = gx + w + 3
		end
	end

	-- ================= LEFT: PROPERTIES (live) =================
	local left = K.f(root, "Left", 0, TOP, LEFT_W, 10, T.bg3)
	left.Size = UDim2.new(0, LEFT_W, 1, -TOP - STATUS_H)
	K.f(left, "HeadLine", 0, 0, LEFT_W, 26, T.bg1)
	K.txt(left, "Properties", 10, 0, 150, 26, 12, T.txt, ARKHER.FONTB)
	local pinL = K.btn(left, "PinL", LEFT_W - 52, 5, 18, 16, T.bg1, 3)
	ICON.pin(pinL, 12, 2, 2)
	K.hover(pinL, T.bg1, T.hover)
	local closeL = K.btn(left, "CloseL", LEFT_W - 30, 5, 18, 16, T.bg1, 3)
	ICON.close(closeL)
	K.hover(closeL, T.bg1, C("#3A2530"))
	closeL.MouseButton1Click:Connect(function()
		left.Visible = not left.Visible
		Bus.emit("view.toggle", "Properties")
	end)
	local propSearch = K.search(left, 8, 30, LEFT_W - 16, 22, "Search Properties (Ctrl+Shift+P)")
	local propBox = K.input(left, 10, 32, LEFT_W - 30, 18, "")
	propBox.Name = "PropFilter"
	propBox.Text = ""
	propBox.PlaceholderText = "Search Properties (Ctrl+Shift+P)"
	propBox.TextSize = 10
	propBox.BackgroundColor3 = T.bg4
	propBox.ClearTextOnFocus = true
	local propContainer = K.f(left, "PropContainer", 0, 58, LEFT_W, 10, T.bg3)
	propContainer.Size = UDim2.new(0, LEFT_W, 1, -58)

	local function filterProps()
		local f = (propBox.Text or ""):lower()
		for _, sec in ipairs(propContainer:GetChildren()) do
			if sec.Name:sub(1, 4) == "SEC_" then
				local label = sec.Name:sub(5):lower()
				sec.Visible = f == "" or label:find(f, 1, true) ~= nil
			end
		end
	end
	propBox.FocusLost:Connect(function()
		filterProps()
		Bus.emit("inspector.refresh")
	end)

	local function rebuildInspector()
		if not left.Visible then return end
		ARKHER_LIVE.rebuildInspector(propContainer)
		filterProps()
	end
	Bus.on("inspector.refresh", rebuildInspector)
	Bus.on("hierarchy.picked", function() rebuildInspector() end)

	-- ================= CENTER: VIEWPORT (nativo, sem frame fake) =================
	local vp = K.f(root, "ViewportArea", 0, TOP, 10, 10, T.bg0)
	vp.Position = UDim2.new(0, LEFT_W, 0, TOP)
	vp.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 1, -TOP - STATUS_H)
	vp.BackgroundTransparency = 1
	local tabStrip = K.f(vp, "TabStrip", 0, 0, 300, 24, T.bg1)
	local tab = K.btn(tabStrip, "Tab_VP", 2, 2, 150, 20, T.bg2, 3)
	local tabIc = K.f(tab, "Ic", 6, 3, 14, 14)
	ICON.camera(tabIc, 14)
	local tabName = K.txt(tab, "Viewport", 24, 0, 96, 20, 10, T.txt)
	local tabX = K.btn(tab, "X", 132, 4, 12, 12, T.bg2, 3)
	ICON.close(tabX)
	local tabMin = K.btn(tabStrip, "Tab_Min", 156, 2, 24, 20, T.bg1, 3)
	ICON.minus(tabMin)
	tabX.MouseButton1Click:Connect(function() vp.Visible = not vp.Visible end)
	tabMin.MouseButton1Click:Connect(function() vp.Visible = not vp.Visible end)
	-- HUD de camera (dados REAIS do viewport nativo)
	local hud = K.f(vp, "CamHud", 8, 30, 220, 18, T.bg1)
	K.stroke(hud, T.line, 1)
	hud.BackgroundTransparency = 0.25
	local hudTxt = K.txt(hud, "Cam (0, 0, 0)", 8, 0, 204, 18, 10, T.txt2, ARKHER.MONO)
	local chips = K.f(vp, "Chips", 8, 52, 260, 22, T.bg1)
	chips.BackgroundTransparency = 0.25
	K.stroke(chips, T.line, 1)
	local chipNames = { "Grid", "Axes", "Focus", "Fit" }
	local cx = 4
	for _, cn in ipairs(chipNames) do
		local cw = 12 + #cn * 6
		local cb = K.btn(chips, "C_" .. cn, cx, 2, cw, 18, T.bg2, 4)
		K.txtS(cb, cn, 9, T.txt2)
		K.hover(cb, T.bg2, T.hover)
		cb.MouseButton1Click:Connect(function()
			if cn == "Focus" then
				local s = ARKHER_LIVE.currentSelection()
				if s and s:IsA("BasePart") then
					local cam = workspace:FindFirstChild("Camera") or workspace:FindFirstChildOfClass("Camera")
					if cam then pcall(function() cam.CFrame = CFrame.lookAt(s.Position + Vector3.new(10, 8, 10), s.Position) end) end
					ARKHER.out("INFO", "F: camera focada em " .. s.Name)
				end
			elseif cn == "Fit" then
				ARKHER.out("INFO", "Fit: enquadre todo o place (use F no Studio ou a camera do ARKHER)")
			else
				ARKHER.out("INFO", "View option: " .. cn .. " (viewport nativo do Roblox)")
			end
		end)
		cx = cx + cw + 3
	end

	-- ================= RIGHT: HIERARCHY (live) =================
	local right = K.f(root, "Right", 0, TOP, RIGHT_W, 10, T.bg3)
	right.Position = UDim2.new(1, -RIGHT_W, 0, TOP)
	right.Size = UDim2.new(0, RIGHT_W, 1, -TOP - STATUS_H)
	K.f(right, "HeadLine", 0, 0, RIGHT_W, 26, T.bg1)
	K.txt(right, "Hierarchy", 10, 0, 120, 26, 12, T.txt, ARKHER.FONTB)
	local pinR = K.btn(right, "PinR", RIGHT_W - 52, 5, 18, 16, T.bg1, 3)
	ICON.pin(pinR, 12, 2, 2)
	K.hover(pinR, T.bg1, T.hover)
	local closeR = K.btn(right, "CloseR", RIGHT_W - 30, 5, 18, 16, T.bg1, 3)
	ICON.close(closeR)
	K.hover(closeR, T.bg1, C("#3A2530"))
	closeR.MouseButton1Click:Connect(function()
		right.Visible = not right.Visible
		Bus.emit("view.toggle", "Hierarchy")
	end)
	local hBox = K.input(right, 10, 32, RIGHT_W - 22, 18, "")
	hBox.Text = ""
	hBox.PlaceholderText = "Filter workspace (Ctrl+Shift+X)"
	hBox.TextSize = 10
	hBox.BackgroundColor3 = T.bg4
	hBox.ClearTextOnFocus = true
	local hIc = K.f(right, "HSearchIc", RIGHT_W - 34, 34, 14, 14)
	ICON.search(hIc, 12, 1, 1)
	local hState = { open = { Workspace = true } }
	local hContainer = K.f(right, "HContainer", 0, 56, RIGHT_W, 10, T.bg3)
	hContainer.Size = UDim2.new(0, RIGHT_W, 1, -56)
	hContainer.BackgroundTransparency = 1
	local function rebuildHierarchy()
		if not right.Visible then return end
		ARKHER_LIVE.rebuildHierarchy(hContainer, hBox.Text or "", hState)
	end
	Bus.on("hierarchy.refresh", rebuildHierarchy)
	hBox.FocusLost:Connect(rebuildHierarchy)
	Bus.on("hierarchy.filter", function() rebuildHierarchy() end)

	-- ================= STATUS BAR =================
	local status = K.f(root, "StatusBar", 0, 0, 10, STATUS_H, T.bg0)
	status.Size = UDim2.new(1, 0, 0, STATUS_H)
	status.Position = UDim2.new(0, 0, 1, -STATUS_H)
	local sPlace = K.txt(status, ARKHER.STATE.placeName, 10, 0, 220, STATUS_H, 10, T.txt2)
	local sSel = K.txt(status, "Nada selecionado", 240, 0, 300, STATUS_H, 10, T.txt3)
	local sRight = K.f(status, "Right", 0, 0, 420, STATUS_H)
	sRight.Position = UDim2.new(1, -420, 0, 0)
	local sFps = K.txt(sRight, "FPS --", 0, 0, 60, STATUS_H, 10, T.txt3, ARKHER.MONO)
	local sFrame = K.txt(sRight, "ms --", 62, 0, 54, STATUS_H, 10, T.txt3, ARKHER.MONO)
	local sDo15 = K.txt(sRight, "D-O15 HIGH", 118, 0, 84, STATUS_H, 10, T.neon, ARKHER.MONO)
	local sTool = K.txt(sRight, "Select", 204, 0, 60, STATUS_H, 10, T.txt2)
	local sCloud = K.txt(sRight, "cloud: local", 266, 0, 90, STATUS_H, 10, T.txt3)
	local sVer = K.txt(sRight, "ARKHER V3", 360, 0, 60, STATUS_H, 9, T.txt4, ARKHER.FONTB)

	-- ================= WIRING REAL =================
	local lastFps = 0
	pcall(function()
		RunService.Heartbeat:Connect(function()
			local cam = workspace:FindFirstChild("Camera")
			if cam then
				local pos = cam.CFrame.Position
				hudTxt.Text = string.format("Cam (%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
			end
		end)
	end)
	Bus.on("do15.level", function(lvl, fps, ms)
		sFps.Text = "FPS " .. string.format("%.0f", fps or 0)
		sFrame.Text = string.format("%.1f ms", ms or 0)
		local names = { "MAX", "HIGH", "BAL", "ECO" }
		sDo15.Text = "D-O15 " .. (names[lvl] or "?")
		sDo15.TextColor3 = lvl == 1 and T.green or lvl == 2 and T.neon or lvl == 3 and T.yellow or T.danger
	end)
	Bus.on("tool.changed", function(tool)
		sTool.Text = tostring(tool)
		for _, ch in ipairs(rib:GetChildren()) do
			if ch._tool then
				ch.BackgroundColor3 = ch._tool == tool and T.sel or T.bg2
				local st = ch:FindFirstChildOfClass("UIStroke")
				if st then st.Visible = ch._tool == tool end
			end
		end
	end)
	Bus.on("tool.locked", function(on)
		ARKHER.out("INFO", "Lock: " .. (on and "ON" or "OFF"))
	end)
	local function refreshPlaceLabel()
		sPlace.Text = ARKHER.STATE.placeName
		tabName.Text = "Viewport"
	end
	Bus.on("place.saved", function(meta)
		refreshPlaceLabel()
		rebuildHierarchy()
		sCloud.Text = "cloud: " .. #ARKHER.STATE.cloud.places .. " places"
	end)
	Bus.on("place.new", function()
		refreshPlaceLabel()
		rebuildHierarchy()
	end)
	Bus.on("place.opened", function()
		refreshPlaceLabel()
		rebuildHierarchy()
	end)
	Bus.on("cloud.status", function(c)
		sCloud.Text = c.endpoint and "cloud: online" or "cloud: local"
	end)
	Bus.on("inspector.refresh", function()
		local s = ARKHER_LIVE.currentSelection()
		sSel.Text = s and (s.Name .. "  (" .. s.ClassName .. ")") or "Nada selecionado"
	end)
	Bus.on("view.toggle", function(which)
		if which == "Properties" then K.notify("ARKHER", "Properties: " .. (left.Visible and "aberto" or "fechado"), "INFO") end
		if which == "Hierarchy" then K.notify("ARKHER", "Hierarchy: " .. (right.Visible and "aberto" or "fechado"), "INFO") end
	end)
	ARKHER.on("view.fullscreen", function()
		left.Visible = false
		right.Visible = false
		Bus.emit("view.reset")
	end)
	Bus.on("view.reset", function()
		left.Visible = true
		right.Visible = true
	end)

	-- estado inicial
	rebuildInspector()
	rebuildHierarchy()
	sTool.Text = ARKHER.STATE.tool or "Select"
	ARKHER.out("SUCCESS", "ARKHER V3 shell montado — menus/toolbar/properties/hierarchy/status bar ativos")
	return g
end

ARKHER_BUILD_MAIN = BUILD_MAIN
