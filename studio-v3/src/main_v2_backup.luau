--[[ ARKHER STUDIO V2 — MAIN UI (replica fiel da print) ]]
local function BUILD_MAIN()
	local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
	local TITLE_H, MENU_H, RIB_H, TAB_H = 26, 24, 78, 26
	local LEFT_W, RIGHT_W = 250, 222
	local TOP = TITLE_H + MENU_H + RIB_H

	local g = K.gui("ArkherStudioMainUI")
	local root = K.fs(g, "Root", 0, 0, 1, 1, T.bg1)

	-- ================= TITLE BAR =================
	local title = K.f(root, "TitleBar", 0, 0, 10, TITLE_H, T.bg0)
	title.Size = UDim2.new(1, 0, 0, TITLE_H)
	local emb = K.f(title, "Emblem", 8, 4, 18, 18)
	ICON.emblem(emb, 18)
	local tname = K.txt(title, "ARKHER STUDIO", 30, 0, 160, TITLE_H, 12, T.txt, ARKHER.FONTB)
	local winBtns = K.f(title, "Win", 0, 0, 70, TITLE_H)
	winBtns.Position = UDim2.new(1, -70, 0, 0)
	local bmin = K.btn(winBtns, "Min", 6, 5, 24, 16, T.bg0, 3)
	K.hover(bmin, T.bg0, T.hover)
	ICON.minus(bmin)
	local bmax = K.btn(winBtns, "Max", 38, 5, 24, 16, T.bg0, 3)
	K.hover(bmax, T.bg0, T.hover)
	ICON.square(bmax)

	-- ================= MENU BAR =================
	local menu = K.f(root, "MenuBar", 0, TITLE_H, 10, MENU_H, T.bg1)
	menu.Size = UDim2.new(1, 0, 0, MENU_H)
	local MENUS = {
		FILE = { "Save", "Open", "Save to Arkher", "-", "Import Asset", "Export Place", "-", "Recent Places", "Close Place" },
		EDIT = { "Undo", "Redo", "-", "Cut", "Copy", "Paste", "Delete", "-", "Rename", "Duplicate" },
		VIEW = { "Properties", "Hierarchy", "Console", "Output", "Command Palette", "-", "Fullscreen Viewport", "Reset Layout" },
		INSERT = { "Model", "Folder", "Script", "LocalScript", "ModuleScript", "Text", "Part", "Mesh", "Light", "Sound" },
		RUN = { "Play", "Pause", "Stop", "-", "Run Diagnostics", "Performance Stats", "-", "Sandbox: ON" },
		GAME = { "Game Settings", "Places", "Publish to Arkher", "-", "Passes", "Developer Products", "Team Create" },
	}
	local mx = 8
	local openDD = nil
	local function closeDD()
		if openDD then openDD:Destroy() openDD = nil end
	end
	local function dropdown(anchor, items)
		closeDD()
		local dd = K.f(root, "Dropdown", anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y, 190, 0, T.bg2)
		K.corner(dd, 4)
		K.stroke(dd, T.line2, 1)
		local y = 2
		for _, it in ipairs(items) do
			if it == "-" then
				K.f(dd, "Sep", 4, y, 182, 1, T.line)
				y = y + 5
			else
				local ib = K.btn(dd, "MI_" .. it, 2, y, 186, 20, T.bg2, 3)
				K.txt(ib, it, 10, 0, 170, 20, 11, T.txt2)
				K.hover(ib, T.bg2, T.hover)
				ib.MouseButton1Click:Connect(function()
					closeDD()
					if ARKHER_ACTIONS and ARKHER_ACTIONS.menu then ARKHER_ACTIONS.menu(it) end
					K.notify("ARKHER", it .. " acionado", "INFO")
				end)
				y = y + 21
			end
		end
		dd.Size = UDim2.new(0, 190, 0, y + 2)
		dd.ZIndex = 50
		openDD = dd
	end
	for _, name in ipairs({ "FILE", "EDIT", "VIEW", "INSERT", "RUN", "GAME" }) do
		local mb = K.btn(menu, "M_" .. name, mx, 2, 46, 20, T.bg1, 3)
		K.txtS(mb, name, 11, T.txt2, ARKHER.FONT)
		K.hover(mb, T.bg1, T.hover)
		mb.MouseButton1Click:Connect(function() dropdown(mb, MENUS[name]) end)
		mx = mx + 50
	end
	-- right side of menu bar
	local rightMenu = K.f(menu, "Right", 0, 0, 300, MENU_H)
	rightMenu.Position = UDim2.new(1, -300, 0, 0)
	local rx = 8
	for _, nm in ipairs({ "Collaborate", "Invites", "Changes" }) do
		local w = 26 + string.len(nm) * 6
		local b = K.btn(rightMenu, "R_" .. nm, rx, 2, w, 20, T.bg1, 3)
		K.txtS(b, nm, 11, T.txt2)
		K.hover(b, T.bg1, T.hover)
		b.MouseButton1Click:Connect(function()
			if ARKHER_ACTIONS and ARKHER_ACTIONS.menu then ARKHER_ACTIONS.menu(nm) end
			K.notify("ARKHER", nm, "INFO")
		end)
		rx = rx + w + 8
	end
	local av = K.f(rightMenu, "Avatar", rx + 2, 4, 16, 16, T.purple)
	K.corner(av, 8)
	K.txt(rightMenu, "ARKH", rx + 22, 0, 40, MENU_H, 11, T.txt2)

	-- ================= RIBBON =================
	local rib = K.f(root, "Ribbon", 0, TITLE_H + MENU_H, 10, RIB_H, T.bg2)
	rib.Size = UDim2.new(1, 0, 0, RIB_H)
	local ribClip = rib
	local x = 6
	local function sep()
		K.f(rib, "Sep", x, 8, 1, RIB_H - 16, T.line)
		x = x + 8
	end
	-- group 1: file ops
	local bSave = K.ribbonBtn(rib, x, 44, ICON.save, "Save")
	x = x + 46
	local bOpen = K.ribbonBtn(rib, x, 44, ICON.open, "Open")
	x = x + 46
	local bCloud = K.ribbonBtn(rib, x, 48, ICON.cloud, "Save to\nArkher")
	x = x + 52
	sep()
	-- group 2: transform
	local bSel = K.ribbonBtn(rib, x, 44, ICON.select, "Select", { selected = true })
	x = x + 46
	local bMove = K.ribbonBtn(rib, x, 40, ICON.move, "Scale")
	x = x + 42
	local bScale = K.ribbonBtn(rib, x, 40, ICON.scaleI, "Scale")
	x = x + 42
	local bRot = K.ribbonBtn(rib, x, 40, ICON.rotate, "Rotate")
	x = x + 46
	local trCol = K.f(rib, "TransformCol", x, 6, 78, 58)
	local trI = K.f(trCol, "TI", 2, 2, 14, 14)
	ICON.transform(trI, 14)
	K.txt(trCol, "Transform", 20, 0, 58, 14, 10, T.txt2)
	local lkI = K.f(trCol, "LI", 2, 20, 14, 14)
	ICON.lock(lkI, 14)
	K.txt(trCol, "Lock", 20, 18, 34, 14, 10, T.txt2)
	ICON.chevD(K.f(trCol, "LV", 52, 20, 8, 8), 8)
	K.txt(trCol, "Local/Global", 0, 40, 78, 12, 8, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Left)
	x = x + 84
	sep()
	-- group 3: insert
	for _, e in ipairs({ { ICON.model, "Model" }, { ICON.folder, "Folder" }, { ICON.script, "Script" }, { ICON.textA, "Text" } }) do
		K.ribbonBtn(rib, x, 42, e[1], e[2])
		x = x + 44
	end
	sep()
	-- group 4: run
	K.ribbonBtn(rib, x, 40, ICON.play, "Play")
	x = x + 42
	K.ribbonBtn(rib, x, 40, ICON.pause, "Pause")
	x = x + 42
	K.ribbonBtn(rib, x, 40, ICON.data, "Data")
	x = x + 42
	K.ribbonBtn(rib, x, 44, ICON.globe, "Localization")
	x = x + 46
	K.ribbonBtn(rib, x, 44, ICON.settings, "Settings")
	x = x + 48
	sep()
	-- group 5: toolbox
	K.ribbonBtn(rib, x, 46, ICON.toolbox, "Toolbox")
	x = x + 48
	K.ribbonBtn(rib, x, 62, ICON.people, "Collaboration\nSettings")
	x = x + 68
	sep()
	-- group 6: cloud / plugin
	K.ribbonBtn(rib, x, 48, ICON.info, "Arkher\nCloud")
	x = x + 52
	K.ribbonBtn(rib, x, 52, ICON.plugin, "Plugin\nToolbar")

	-- ribbon wiring (hooks overridable by systems)
	local function act(name)
		if ARKHER_ACTIONS and ARKHER_ACTIONS.ribbon then ARKHER_ACTIONS.ribbon(name) end
		K.notify("ARKHER STUDIO", name, "INFO")
	end
	bSave.MouseButton1Click:Connect(function() act("Save") end)
	bOpen.MouseButton1Click:Connect(function() act("Open") end)
	bCloud.MouseButton1Click:Connect(function() act("Save to Arkher") end)
	bSel.MouseButton1Click:Connect(function() act("Select") end)
	bMove.MouseButton1Click:Connect(function() act("Move") end)
	bScale.MouseButton1Click:Connect(function() act("Scale") end)
	bRot.MouseButton1Click:Connect(function() act("Rotate") end)

	-- ================= TAB BAR + VIEWPORT =================
	local tabbar = K.f(root, "TabBar", LEFT_W, TOP, 10, TAB_H, T.bg1)
	tabbar.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 0, TAB_H)
	local tab1 = K.f(tabbar, "TabActive", 4, 0, 150, TAB_H, T.bg2)
	K.stroke(tab1, T.line, 1)
	local ticon = K.f(tab1, "I", 8, 5, 16, 16)
	ICON.share(ticon, 16)
	K.txt(tab1, "SunEmblemBlock", 28, 0, 100, TAB_H, 11, T.txt)
	local tx = K.btn(tab1, "X", 128, 5, 16, 16, T.bg2, 3)
	K.hover(tx, T.bg2, C("#3A2530"))
	ICON.close(tx)
	local tab2 = K.btn(tabbar, "Tab2", 158, 0, 26, TAB_H, T.bg1, 0)
	ICON.minus(tab2)
	local dockI = K.btn(tabbar, "Dock", 0, 5, 16, 16, T.bg1, 3)
	dockI.Position = UDim2.new(1, -22, 0, 5)
	ICON.dock(dockI)

	local vp = K.f(root, "Viewport", LEFT_W, TOP + TAB_H, 10, 10, T.vp1)
	vp.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 1, -(TOP + TAB_H))
	vp.ClipsDescendants = true
	local function checker()
		vp:ClearAllChildren()
		local w, h = vp.AbsoluteSize.X, vp.AbsoluteSize.Y
		if w <= 0 then w = 1024 end
		if h <= 0 then h = 512 end
		local tile = 40
		local cols = math.ceil(w / tile)
		local rows = math.ceil(h / tile)
		if cols * rows > 900 then tile = 64 cols = math.ceil(w / tile) rows = math.ceil(h / tile) end
		for ry = 0, rows - 1 do
			for cx = 0, cols - 1 do
				local even = (ry + cx) % 2 == 0
				local q = K.f(vp, "ck", cx * tile, ry * tile, tile, tile, even and T.vp1 or T.vp2)
			end
		end
	end
	checker()
	pcall(function()
		vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() checker() end)
	end)

	-- ================= PROPERTIES (LEFT) =================
	local left = K.f(root, "Left", 0, TOP, LEFT_W, 10, T.bg3)
	left.Size = UDim2.new(0, LEFT_W, 1, -TOP)
	local lhead = K.f(left, "Head", 0, 0, LEFT_W, TAB_H, T.bg3)
	K.txt(lhead, "Properties", 8, 0, 120, TAB_H, 12, T.txt2, ARKHER.FONTB)
	local pin1 = K.btn(lhead, "Pin", LEFT_W - 44, 5, 16, 16, T.bg3, 3)
	ICON.pin(pin1)
	K.hover(pin1, T.bg3, T.hover)
	local lx = K.btn(lhead, "X", LEFT_W - 24, 5, 16, 16, T.bg3, 3)
	K.hover(lx, T.bg3, C("#3A2530"))
	ICON.close(lx)
	lx.MouseButton1Click:Connect(function() left.Visible = not left.Visible end)

	K.search(left, 6, 32, LEFT_W - 12, 22, "Search Properties (Ctrl+Shift+P)")

	local objRow = K.f(left, "Obj", 0, 60, LEFT_W, 24, T.bg3)
	local objI = K.f(objRow, "I", 8, 4, 16, 16)
	ICON.cubeW(objI, 16)
	K.txt(objRow, "Part", 30, 0, 120, 24, 12, T.txt, ARKHER.FONTB)

	local secs = K.f(left, "Sections", 0, 88, LEFT_W, 10)
	secs.Size = UDim2.new(1, 0, 1, -88)
	secs.ClipsDescendants = true

	local s1, s1b = K.section(secs, "Core Properties", true, 0)
	K.row(s1b, "Position", "X: 16, 19, 5", 2)
	K.row(s1b, "Orientation", "X: 35, 223, 3", 22)
	K.sliderRow(s1b, "Transparency", 0, 42)
	K.sliderRow(s1b, "Transparency", 0, 62)
	K.txt(s1b, "Color", 22, 82, 80, 18, 11, T.txt3)
	local sw = K.f(s1b, "Swatch", 118, 83, 16, 16, C("#C89B7B"))
	K.corner(sw, 2)
	K.stroke(sw, T.line2, 1)
	K.txt(s1b, "Color", 140, 82, 60, 18, 11, T.txt)

	local s2, s2b = K.section(secs, "Data", false, 0)
	K.row(s2b, "UniqueId", "0x4F2A", 2)
	K.row(s2b, "Archivable", "true", 22)

	local s3, s3b = K.section(secs, "Transform", false, 0)
	K.row(s3b, "PivotOffset", "0, 0, 0", 2)
	K.row(s3b, "Size", "4, 1, 2", 22)

	local s4, s4b = K.section(secs, "Physics", true, 0)
	K.checkRow(s4b, "Transparency", true, 2)
	K.checkRow(s4b, "ReplicatedFirst", true, 22)
	K.checkRow(s4b, "Transformfall", true, 42)
	K.checkRow(s4b, "PhysicsPlayer", true, 62)
	K.checkRow(s4b, "PhysicsTodall...", false, 82)

	local s5, s5b = K.section(secs, "Scripting", true, 0)
	K.checkRow(s5b, "Scripting", true, 2)

	local s6, s6b = K.section(secs, "Advanced Barre", false, 0)
	K.row(s6b, "CollisionFidelity", "Box", 2)
	K.row(s6b, "Massless", "false", 22)

	K.reflow(secs)
	-- reflow after each section body measured (sections already laid out in creation order)

	-- ================= HIERARCHY (RIGHT) =================
	local right = K.f(root, "Right", 0, TOP, RIGHT_W, 10, T.bg3)
	right.Position = UDim2.new(1, -RIGHT_W, 0, TOP)
	right.Size = UDim2.new(0, RIGHT_W, 1, -TOP)
	local rhead = K.f(right, "Head", 0, 0, RIGHT_W, TAB_H, T.bg3)
	K.txt(rhead, "Hierarchy", 8, 0, 120, TAB_H, 12, T.txt2, ARKHER.FONTB)
	local pin2 = K.btn(rhead, "Pin", RIGHT_W - 44, 5, 16, 16, T.bg3, 3)
	ICON.pin(pin2)
	K.hover(pin2, T.bg3, T.hover)
	local rx2 = K.btn(rhead, "X", RIGHT_W - 24, 5, 16, 16, T.bg3, 3)
	K.hover(rx2, T.bg3, C("#3A2530"))
	ICON.close(rx2)
	rx2.MouseButton1Click:Connect(function() right.Visible = not right.Visible end)

	K.search(right, 6, 32, RIGHT_W - 12, 22, "Filter workspace (Ctrl+Shift+X)")

	local tree = K.f(right, "Tree", 0, 60, RIGHT_W, 10)
	tree.Size = UDim2.new(1, 0, 1, -60)
	tree.ClipsDescendants = true
	local y = 0
	local function trow(depth, icon, name, state)
		K.treeRow(tree, depth, icon, name, state, y)
		y = y + 20
	end
	trow(0, ICON.ws, "Workspace", "open")
	trow(1, ICON.plate, "Baseplate", "closed")
	trow(1, ICON.cubeW, "SpamPoint", "closed")
	trow(1, ICON.terrain, "Terrain", "closed")
	trow(1, ICON.camera, "Camera", nil)
	trow(0, ICON.playersI, "Players +", "closed")
	trow(0, ICON.bulb, "Lighting +", nil)
	trow(0, ICON.gem, "MaterialService +", nil)
	trow(0, ICON.repfirst, "ReplicatedFirst +", "closed")
	trow(0, ICON.boxG, "ReplicatedStorage +", nil)
	trow(0, ICON.cubeT, "ServerScriptService", nil)
	trow(0, ICON.cubeT, "ServerStorage", nil)
	trow(0, ICON.folder, "StarterGui +", "closed")
	trow(0, ICON.folderP, "StarterPack +", nil)
	trow(0, ICON.playercard, "StarterPlayer +", "closed")
	trow(0, ICON.chat, "TextChatService", nil)

	return g
end
BUILD_MAIN()
