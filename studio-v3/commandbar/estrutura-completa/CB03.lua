--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA (3/13)
  Launchers 1/2 — MainUI + Bundle_Editors
  Cria: StarterPlayerScripts.Arkher.{ArkherMainUI, ArkherBundle_Editors} (LocalScripts ativos)
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]
local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local arkher = spps:FindFirstChild("Arkher")
if not arkher then arkher = Instance.new("Folder") arkher.Name = "Arkher" arkher.Parent = spps end
local S_MAIN = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()

do
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
end

do
--[[ ARKHER V3 — UI: COMMAND PALETTE (Ctrl+K) ]]
-- Layout unico: barra flutuante centralizada de BUSCA, lista viva que filtra
-- UIs + TODOS os comandos do ARKHER conforme digita. Sem janela comum.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD400")

local function build()
	local g, root, head = K.window("ArkherCommandPalette", "COMMAND PALETTE", 40, 140, 480, 318, {})
	K.f(head, "Acc", 0, 24, 480, 2, ACCENT)

	local box = K.input(root, 10, 34, 460, 28, "digite: publish, animator, save, insert.part...")
	local area = K.f(root, "Results", 10, 70, 460, 212, T.bg0)
	K.corner(area, 4)
	K.stroke(area, T.line, 1)
	local rows = K.f(area, "Rows", 0, 4, 460, 204)

	local firstRun = nil
	local function render(filter)
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		firstRun = nil
		local f = (filter or ""):lower()
		local y = 0
		local n = 0
		for _, name in ipairs(ARKHER.listUIs()) do
			local cat = ARKHER.CATALOG[name]
			local title = (cat and cat.title) or name
			if f == "" or title:lower():find(f, 1, true) or name:lower():find(f, 1, true) then
				local row = K.btn(rows, "R" .. n, 4, y, 452, 24, T.bg2, 3)
				K.txt(row, title, 10, 0, 320, 24, 11, T.txt)
				K.txt(row, (cat and cat.cat) or "ui", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local nm = name
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd("ui.open", nm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd("ui.open", nm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n > 0 then
			K.f(rows, "Sep", 8, y + 6, 444, 1, T.line)
			y = y + 12
		end
		for cmd in pairs(ARKHER.ACTIONS or {}) do
			if n >= 26 then break end
			if f == "" or cmd:find(f, 1, true) then
				local row = K.btn(rows, "C" .. n, 4, y, 452, 24, T.bg4, 3)
				K.txt(row, cmd, 10, 0, 320, 24, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
				K.txt(row, "comando", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local cm = cmd
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd(cm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd(cm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n == 0 then
			K.txt(rows, "(nada encontrado para \"" .. tostring(filter) .. "\")", 10, 10, 300, 20, 10, T.txt4)
		end
	end
	render("")

	local function refresh()
		render(box.Text or "")
	end
	local okc, sig = pcall(function() return box:GetPropertyChangedSignal("Text") end)
	if okc and sig then sig:Connect(refresh) end
	local okf, fl = pcall(function() return box.FocusLost end)
	if okf and fl then
		fl:Connect(function(commit)
			if commit and firstRun then
				local ok, err = pcall(firstRun)
				if not ok then ARKHER.out("ERROR", "Palette: " .. tostring(err)) end
			end
			root.Visible = false
		end)
	end
	K.txt(root, "# UIs: " .. tostring(#ARKHER.listUIs()) .. "  |  # comandos: " .. (function()
		local c = 0
		for _ in pairs(ARKHER.ACTIONS or {}) do c = c + 1 end
		return c
	end)(), 10, 290, 300, 16, 9, T.txt4)
	K.txt(root, "Enter = 1o resultado | Esc = fecha", 300, 290, 170, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	-- paleta nasce oculta: abre com Ctrl+K / VIEW > Command Palette
	root.Visible = false
end

ARKHER.reg("CommandPalette", "Command Palette", "System", ICON.search, "Ctrl+K: busca viva de UIs e todos os comandos do ARKHER", build)
end

local ok, err = pcall(function() ARKHER_BUILD_MAIN() end)
if not ok then ARKHER.out("ERROR", "MainUI falhou: " .. tostring(err)) end
]====]
local S_ED = [====[--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER V3 — UI: ANIMATOR ]]
-- Layout unico: lista de poses a esquerda, preview do personagem no centro,
-- timeline real com keytracks (K.keyTrack) + scrub + controles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF9F43")

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR — timeline & poses", 24, 300, 540, 392, { pin = true })

	-- acento na head
	K.f(head, "Acc", 0, 24, 540, 2, ACCENT)

	-- ===== PAINEL ESQUERDO: POSES =====
	local left = K.f(root, "Poses", 8, 34, 122, 300, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POSES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local poses = { "Pose Inicial", "Andar", "Correr", "Pulo", "Ataque" }
	local selPose = 1
	for i, p in ipairs(poses) do
		local row = K.treeRow(left, 0, i == 1 and ICON.play or ICON.pause, p, i == 1, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			selPose = i
			ARKHER.out("INFO", "Animator: pose selecionada: " .. p)
		end)
	end
	K.txt(left, "clique = trocar pose", 8, 160, 110, 30, 9, T.txt4)

	-- ===== CENTRO: PREVIEW =====
	local pv = K.f(root, "Preview", 140, 34, 250, 150, T.dark)
	K.corner(pv, 4)
	K.stroke(pv, T.line, 1)
	-- grade
	for i = 1, 7 do
		K.f(pv, "gx" .. i, i * 34, 0, 1, 150, T.bg3)
		K.f(pv, "gy" .. i, 0, i * 21, 250, 1, T.bg3)
	end
	-- silhueta humanoide (frames)
	local bx = 105
	K.f(pv, "Head", bx, 34, 22, 22, ACCENT, 6)
	K.f(pv, "Torso", bx + 2, 58, 18, 34, T.neon)
	K.f(pv, "ArmL", bx - 10, 58, 8, 30, T.neon)
	K.f(pv, "ArmR", bx + 24, 58, 8, 30, T.neon)
	K.f(pv, "LegL", bx + 2, 94, 7, 34, T.neon)
	K.f(pv, "LegR", bx + 13, 94, 7, 34, T.neon)
	local poseLbl = K.txt(pv, "Pose: Andar", 8, 130, 120, 16, 10, T.txt3)
	-- sombra
	K.f(pv, "Shadow", bx - 12, 130, 58, 5, T.bg0, 2)

	-- ===== CENTRO-BAIXO: TIMELINE =====
	local tl = K.f(root, "Timeline", 140, 194, 392, 140, T.bg0)
	K.corner(tl, 4)
	K.txt(tl, "TIMELINE", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.keyTrack(tl, "Position", 24, { 0, 0.28, 0.62, 0.9 }, ACCENT)
	K.keyTrack(tl, "Rotation", 46, { 0.15, 0.55, 0.78 }, C("#FFD93D"))
	K.keyTrack(tl, "Scale", 68, { 0.5, 0.52 }, C("#74B9FF"))
	-- scrub
	local playLbl = K.btn(tl, "Play", 8, 96, 52, 20, T.bg2, 4)
	K.txtS(playLbl, "Play", 10, T.txt)
	K.hover(playLbl, T.bg2, T.hover)
	local playing = false
	playLbl.MouseButton1Click:Connect(function()
		playing = not playing
		playLbl.Text = ""
		K.txt(playLbl, playing and "Pause" or "Play", 0, 0, 52, 20, 10, T.txt, FONTB, Enum.TextXAlignment.Center)
		ARKHER.out(playing and "SUCCESS" or "INFO", "Animator: " .. (playing and "tocando" or "pausado") .. " — " .. poses[selPose])
	end)
	local scrub, scrubFill = K.progress(tl, 70, 104, 310, 0.32, ACCENT)
	local tLbl = K.txt(tl, "0.96s / 3.00s", 70, 122, 150, 14, 9, T.txt4)
	-- marcadores de tempo
	for i = 0, 10 do
		K.txt(tl, tostring(i) .. ".0", 70 + i * 31, 116, 20, 10, 7, T.txt4)
	end
	-- zoom
	K.txt(tl, "zoom x1", 330, 122, 40, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrls", 442, 34, 90, 300, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AJUSTES", 10, 6, 70, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(right, "Duracao", 0.34, 26)
	K.sliderRow(right, "Ease", 0.5, 52)
	K.checkRow(right, "Loop", true, 80)
	K.checkRow(right, "Fade in", true, 104)
	K.row(right, "Frames", "90 @ 30fps", 130)
	local bake = K.btn(right, "Bake", 10, 158, 70, 24, ACCENT, 5)
	K.txtS(bake, "BAKE", 11, C("#14100C"))
	K.hover(bake, ACCENT, C("#FFB86B"))
	bake.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Animator: " .. poses[selPose] .. " baked (90 frames, 3.0s)")
		K.notify("Bake concluido", poses[selPose] .. " -> AnimationTrack", "ok")
		Bus.emit("animator.bake", { pose = poses[selPose], frames = 90 })
	end)
	K.row(right, "Size", "1.2 KB", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 344, 524, 40, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "4 keyframes", 12, 6, 90, 14, 9, T.txt3)
	K.txt(bar, "3 tracks", 110, 6, 70, 14, 9, T.txt3)
	K.txt(bar, "30 fps", 188, 6, 60, 14, 9, T.txt3)
	K.txt(bar, "Andar.anim", 256, 6, 100, 14, 9, ACCENT)
	K.txt(bar, "pronto", 480, 6, 40, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Animator", "Animator", "Editor", ICON.play, "Timeline de animacao: poses, keyframes, scrub e bake", build)
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
--[[ ARKHER V3 — UI: TERRAIN ]]
-- Layout unico: pincelais de escultura a esquerda, heightmap 8x8 INTERATIVO
-- no centro (clique aplica o pincel e repinta), paleta de biomas a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN — escultura", 24, 320, 552, 384, { pin = true })
	K.f(head, "Acc", 0, 24, 552, 2, ACCENT)

	-- estado do relevo
	local heights = {}
	local seed = 7
	local function reseed(s)
		seed = s
		for i = 1, 64 do
			seed = (seed * 16807) % 2147483647
			heights[i] = (seed % 1000) / 1000 * 6
		end
	end
	reseed(11)

	-- ===== PINCELAS =====
	local brushes = {
		{ id = "raise", nm = "Raise", gl = "+", d = "sobe 1u" },
		{ id = "lower", nm = "Lower", gl = "-", d = "desce 1u" },
		{ id = "smooth", nm = "Smooth", gl = "~", d = "media vizinhos" },
		{ id = "flatten", nm = "Flatten", gl = "=", d = "zera" },
		{ id = "erase", nm = "Erase", gl = "x", d = "remove tudo" },
	}
	local curBrush = "raise"
	local left = K.f(root, "Brush", 8, 34, 108, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "PINCEL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, b in ipairs(brushes) do
		local row = K.btn(left, "B" .. i, 8, 26 + (i - 1) * 34, 92, 28, T.bg2, 4)
		local ic = K.f(row, "G", 4, 6, 16, 16, T.bg0, 3)
		K.txt(ic, b.gl, 0, 0, 16, 16, 11, ACCENT, FONTB, Enum.TextXAlignment.Center)
		K.txt(row, b.nm, 26, 2, 62, 14, 10, T.txt)
		K.txt(row, b.d, 26, 15, 62, 11, 8, T.txt4)
		local id = b.id
		row.MouseButton1Click:Connect(function()
			curBrush = id
			for j = 1, #brushes do
				local rr = left:FindFirstChild("B" .. j)
				if rr then K.stroke(rr, j == i and ACCENT or T.line2, j == i and 1.5 or 1) end
			end
		end)
		K.stroke(row, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	K.sliderRow(left, "Forca", 0.6, 206)

	-- ===== HEIGHTMAP 8x8 =====
	local cv = K.f(root, "Map", 126, 34, 252, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	local tiles = {}
	local function hcolor(h)
		-- 0=agua/areia -> 6=rocha
		local stops = { C("#2E86AB"), C("#E9D8A6"), C("#7ED957"), C("#3E8E41"), C("#8D6E63"), C("#6D6E71"), C("#CFD8DC") }
		local idx = math.min(6, math.floor(h))
		return stops[idx + 1]
	end
	local function paint(i, tx, ty)
		local t = tiles[i]
		if t then
			t.BackgroundColor3 = hcolor(heights[i])
			t:FindFirstChild("N").Text = string.format("%.1f", heights[i])
		end
	end
	local function applyBrush(idx)
		local r, c = math.floor((idx - 1) / 8) + 1, ((idx - 1) % 8) + 1
		local function get(r2, c2)
			if r2 < 1 or r2 > 8 or c2 < 1 or c2 > 8 then return nil end
			return (r2 - 1) * 8 + c2
		end
		if curBrush == "raise" then heights[idx] = math.min(6, heights[idx] + 1)
		elseif curBrush == "lower" then heights[idx] = math.max(0, heights[idx] - 1)
		elseif curBrush == "flatten" then heights[idx] = 0
		elseif curBrush == "erase" then heights[idx] = 0
		elseif curBrush == "smooth" then
			local sum, n = 0, 0
			for dr = -1, 1 do
				for dc = -1, 1 do
					local j = get(r + dr, c + dc)
					if j then sum = sum + heights[j] n = n + 1 end
				end
			end
			heights[idx] = sum / n
		end
		-- repinta a vizinhanca
		for dr = -1, 1 do
			for dc = -1, 1 do
				local j = get(r + dr, c + dc)
				if j then paint(j) end
			end
		end
	end
	for i = 1, 64 do
		local r, c = math.floor((i - 1) / 8) + 1, ((i - 1) % 8) + 1
		local t = K.f(cv, "H" .. i, (c - 1) * 31 + 2, (r - 1) * 29 + 2, 29, 27, hcolor(heights[i]), 2)
		K.txt(t, string.format("%.1f", heights[i]), 0, 8, 29, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
		tiles[i] = t
		local idx = i
		t.MouseButton1Click:Connect(function() applyBrush(idx) end)
	end
	K.txt(cv, "clique num tile = aplicar pincel", 8, 236, 200, 12, 8, T.txt4)

	-- ===== BIOMAS + MATERIAIS =====
	local right = K.f(root, "Biome", 390, 34, 154, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "BIOMAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local biomes = {
		{ "Praia", C("#E9D8A6") }, { "Grande", C("#7ED957") },
		{ "Deserto", C("#D4A373") }, { "Neve", C("#ECEFF1") },
	}
	for i, b in ipairs(biomes) do
		local row = K.btn(right, "BM" .. i, 10, 26 + (i - 1) * 26, 134, 22, T.bg2, 4)
		K.f(row, "Sw", 4, 5, 12, 12, b[2], 2)
		K.txt(row, b[1], 22, 0, 90, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Terrain: bioma " .. b[1])
		end)
	end
	K.txt(right, "MATERIAIS", 10, 138, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local mats = { C("#7ED957"), C("#8D6E63"), C("#B0BEC5"), C("#E9D8A6"), C("#4DB6AC"), C("#6D6E71") }
	for i = 1, 6 do
		local m = K.f(right, "M" .. i, 10 + ((i - 1) % 3) * 44, 158 + math.floor((i - 1) / 3) * 34, 38, 28, mats[i], 3)
		K.stroke(m, i == 1 and ACCENT or T.line, i == 1 and 1.5 or 1)
		K.txt(m, tostring(i) .. "u", 0, 16, 38, 10, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 536, 92, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Relevo procedural", 10, C("#0D140B"))
	K.hover(gen, ACCENT, C("#A5E88C"))
	local gseed = 11
	gen.MouseButton1Click:Connect(function()
		gseed = gseed * 31 + 7
		reseed(gseed)
		for i = 1, 64 do paint(i) end
		ARKHER.out("SUCCESS", "Terrain: relevo procedural (seed " .. gseed .. ")")
	end)
	local ai = K.btn(bar, "AI", 150, 10, 120, 26, T.bg2, 5)
	K.txtS(ai, "Gerar c/ IA", 11, T.txt)
	K.hover(ai, T.bg2, T.hover)
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Terrain: pedindo a Singularity...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno com natureza") end)
		if ok and rep then K.notify("Singularity", "terreno gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	K.txt(bar, "8x8 tiles | 31u | bioma: Grande", 10, 48, 250, 16, 10, T.txt3)
	K.txt(bar, "altura media: 2.4u", 300, 48, 150, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.progress(bar, 10, 70, 516, 0.42, ACCENT)
end

ARKHER.reg("Terrain", "Terrain", "Editor", ICON.terrain, "Escultura de terreno: pincelais, heightmap, biomas e materiais", build)
end

do
--[[ ARKHER V3 — UI: SCRIPT (code editor) ]]
-- Layout unico: barra de arquivo + tabs de classe, area de codigo com
-- numeros de linha, painel de lint, acoes reais (criar Script no place, exportar).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")

local TEMPLATES = {
	Script = {
		"-- MeuScript (Script)",
		"local part = script.Parent",
		"",
		"part.Touched:Connect(function(hit)",
		"\tprint(\"tocado: \" .. hit.Name)",
		"\tpart.BrickColor = BrickColor.new(\"Bright red\")",
		"end)",
		"",
		"-- ARKHER: criado via Scripter",
	},
	LocalScript = {
		"-- MeuLocal (LocalScript)",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal cam = workspace.CurrentCamera",
		"\tcam.FieldOfView = 70",
		"end)",
	},
	ModuleScript = {
		"-- MeuModule (ModuleScript)",
		"local M = {}",
		"",
		"function M.hello(name)",
		"\treturn \"ola, \" .. name",
		"end",
		"",
		"return M",
	},
}

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT — editor de codigo", 24, 330, 520, 424, { pin = true })
	K.f(head, "Acc", 0, 24, 520, 2, ACCENT)

	local curCls = "Script"
	local curName = "MeuScript"
	local code = {}
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }

	-- ===== TOPO: ARQUIVO + CLASSES =====
	local nameBox = K.input(root, 10, 34, 190, 24, "nome do arquivo")
	nameBox.Text = "MeuScript"
	K.tabs(root, 210, 34, 290, CLASSES, 1, function(idx)
		curCls = CLASSES[idx]
		curName = nameBox.Text
		code = TEMPLATES[curCls]
		renderCode()
	end)

	-- ===== AREA DE CODIGO =====
	local ed = K.f(root, "Editor", 10, 64, 356, 240, T.bg0)
	K.corner(ed, 4)
	K.stroke(ed, T.line, 1)
	local function renderCode()
		for i = 1, 12 do
			local old = ed:FindFirstChild("L" .. i)
			if old then old:Destroy() end
		end
		for i = 1, 12 do
			local ln = code[i] or ""
			K.txt(ed, string.format("%2d", i), 4, 6 + (i - 1) * 18, 24, 18, 9, T.txt4)
			K.f(ed, "ln" .. i, 28, 6 + (i - 1) * 18, 322, 1, (i == 5 or i == 7) and T.line or T.bg0)
			local col = T.txt2
			local txt = ln
			if ln:sub(1, 2) == "--" then col = T.txt4 end
			if ln:find("local ") == 1 then col = C("#C792EA") end
			if ln:find("function ") == 1 then col = ACCENT end
			if ln:find("print") == 1 then col = C("#82AAFF") end
			if txt ~= "" then
				local t = K.txt(ed, "L" .. i, 30, 6 + (i - 1) * 18, 320, 18, 10, col, ARKHER.MONO or ARKHER.FONT)
			end
		end
	end
	renderCode()

	-- ===== LINT =====
	local lint = K.f(root, "Lint", 10, 310, 356, 56, T.bg4)
	K.corner(lint, 4)
	K.txt(lint, "LINT", 8, 4, 50, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(lint, "0 erros", 8, 22, 80, 14, 10, T.ok)
	K.txt(lint, "1 aviso: pcall p/ Touched", 100, 22, 160, 14, 9, C("#FFD93D"))
	K.txt(lint, "linhas: 9", 280, 22, 70, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 378, 64, 134, 302, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AÇÕES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Classe", curCls, 26)
	K.row(right, "Linhas", "9", 50)
	K.row(right, "Tamanho", "0.2 KB", 74)
	local create = K.btn(right, "Create", 10, 102, 114, 26, ACCENT, 5)
	K.txtS(create, "Criar no Place", 10, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local n = 1
		local ws = workspace
		local base = nameBox.Text
		while ws:FindFirstChild(base) do n = n + 1 base = nameBox.Text .. "_" .. n end
		local sc = Instance.new(curCls)
		sc.Name = base
		sc.Source = table.concat(code, "\n")
		sc.Parent = ws
		ARKHER.out("SUCCESS", "Script: " .. curCls .. " '" .. base .. "' criado no place (" .. #code .. " linhas)")
		K.notify("Script criado", base .. " no workspace", "ok")
	end)
	local exp = K.btn(right, "Export", 10, 136, 114, 26, T.bg2, 5)
	K.txtS(exp, "Exportar .lua", 10, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local data = table.concat(code, "\n")
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherScripts/" .. nameBox.Text .. ".lua", data)
				return "ArkherScripts/" .. nameBox.Text .. ".lua"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Script: exportado para " .. path)
		else
			ARKHER.out("WARNING", "Script: WriteFile indisponivel fora do Studio")
		end
	end)
	local ins = K.btn(right, "Insert", 10, 170, 114, 26, T.bg2, 5)
	K.txtS(ins, "+ snippet", 11, T.txt)
	K.hover(ins, T.bg2, T.hover)
	local snippets = { "\t-- snippet: debounce", "\tlocal debounce = false", "pcall(function() end)", "warn(\"debug\")" }
	local sn = 1
	ins.MouseButton1Click:Connect(function()
		sn = (sn % #snippets) + 1
		table.insert(code, snippets[sn])
		renderCode()
		ARKHER.out("INFO", "Script: snippet inserido")
	end)
	K.row(right, "Encoding", "utf-8", 214)
	K.row(right, "EOL", "LF", 238)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 10, 372, 502, 44, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "Ln 5, Col 12", 12, 6, 100, 14, 9, T.txt3)
	K.txt(bar, curCls, 130, 6, 120, 14, 9, ACCENT)
	K.txt(bar, "UTF-8 | LF | Luau", 268, 6, 130, 14, 9, T.txt4)
	K.txt(bar, "salvo", 470, 6, 30, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Script", "Script", "Editor", ICON.script, "Editor de codigo Luau: classes, lint, criar no place e exportar", build)
end

do
--[[ ARKHER V3 — UI: PARTICLES ]]
-- Layout unico: arvore do emissor a esquerda, GRAPH DE NOS (K.node + K.wireLayer)
-- no centro — estilo Nuke/Blender, knobs a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C56CF0")

local function build()
	local g, root, head = K.window("ArkherParticles", "PARTICLES — graph", 24, 340, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: ARVORE DO EMISSOR =====
	local left = K.f(root, "Tree", 8, 34, 148, 296, T.bg4)
	K.corner(left, 4)
	K.txt(left, "EMITTER", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(left, 0, ICON.gem, "SparkEmitter", "open", 26)
	K.treeRow(left, 1, ICON.data, "RateOverTime", "sel", 50)
	K.treeRow(left, 1, ICON.data, "SpreadOverCone", nil, 74)
	K.treeRow(left, 1, ICON.data, "ColorOverLife", nil, 98)
	K.treeRow(left, 1, ICON.data, "Velocity", nil, 122)
	K.txt(left, "4 properties", 10, 150, 100, 14, 9, T.txt4)
	local addProp = K.btn(left, "AddP", 10, 172, 128, 22, T.bg2, 4)
	K.txtS(addProp, "+ property", 10, T.txt)
	K.hover(addProp, T.bg2, T.hover)
	local props = 4
	addProp.MouseButton1Click:Connect(function()
		props = props + 1
		ARKHER.out("INFO", "Particles: property #" .. props .. " adicionada")
	end)
	K.row(left, "Tipo", "Bullets", 210)
	K.row(left, "Lighting", "On", 234)
	K.row(left, "Sort", "Distance", 258)

	-- ===== CENTRO: GRAPH =====
	local cv = K.f(root, "Graph", 168, 34, 284, 296, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 8 do K.f(cv, "gx" .. i, i * 33, 0, 1, 296, T.bg3) end
	for i = 1, 9 do K.f(cv, "gy" .. i, 0, i * 31, 284, 1, T.bg3) end
	local wire = K.wireLayer(cv)
	-- nos
	local nEm = K.node(cv, 12, 108, 100, "Emitter", C("#3A2B45"), { "rate", "spread", "color" }, {}, { sel = true, dot = ACCENT })
	local nRate = K.node(cv, 160, 40, 104, "RateOverTime", T.bg1, {}, { "value" })
	local nSpread = K.node(cv, 160, 128, 104, "SpreadOverCone", T.bg1, {}, { "cone" })
	local nColor = K.node(cv, 160, 212, 104, "ColorOverLife", T.bg1, {}, { "grad" })
	-- liga os soquetes (coordenadas vindas dos _socket)
	local function socketsOf(n)
		local ins, outs = {}, {}
		for _, s in ipairs(n._sockets or {}) do
			if s._socket then
				if s._socket.kind == "in" then table.insert(ins, s._socket)
				else table.insert(outs, s._socket) end
			end
		end
		return ins, outs
	end
	local eIn, _ = socketsOf(nEm)
	local _, rOut = socketsOf(nRate)
	local _, sOut = socketsOf(nSpread)
	local _, cOut = socketsOf(nColor)
	if eIn[1] and rOut[1] then wire:link(rOut[1].x, rOut[1].y, eIn[1].x, eIn[1].y, ACCENT) end
	if eIn[2] and sOut[1] then wire:link(sOut[1].x, sOut[1].y, eIn[2].x, eIn[2].y, C("#4DFFDB")) end
	if eIn[3] and cOut[1] then wire:link(cOut[1].x, cOut[1].y, eIn[3].x, eIn[3].y, C("#FFD93D")) end
	K.txt(cv, "graph: 4 nos, 3 fios", 8, 278, 200, 14, 9, T.txt4)

	-- ===== DIREITA: KNOBS =====
	local right = K.f(root, "Knobs", 464, 34, 88, 296, T.bg4)
	K.corner(right, 4)
	K.txt(right, "RATE", 6, 6, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 24, 48, 0.72, "128/s")
	K.txt(right, "SPREAD", 6, 96, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 114, 48, 0.3, "38deg")
	K.txt(right, "LIFE", 6, 186, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 204, 48, 0.5, "1.4s")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 340, 544, 52, T.bg0)
	K.corner(bar, 4)
	-- preview de particulas (pontos)
	local pv = K.f(bar, "Prev", 10, 6, 120, 40, T.dark)
	K.corner(pv, 3)
	for i = 1, 14 do
		local s = (i * 16807) % 2147483647
		local s2 = (s * 16807) % 2147483647
		local d = K.f(pv, "P" .. i, s % 110 + 4, s2 % 30 + 4, 3, 3, ACCENT, 1)
	end
	local pvLbl = K.txt(bar, "preview: 128/s", 140, 12, 120, 16, 10, T.txt3)
	local sim = K.btn(bar, "Sim", 270, 12, 80, 26, ACCENT, 5)
	K.txtS(sim, "Simular", 11, C("#160B1E"))
	K.hover(sim, ACCENT, C("#D99BFF"))
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Particles: 128 particulas/s por 1.4s simuladas")
		K.notify("Simulacao", "SparkEmitter OK", "ok")
	end)
	K.txt(bar, "modo: graph", 370, 18, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(bar, "pronto", 480, 18, 50, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Sistema de particulas em graph de nos com emissor e preview", build)
end

local opened = ARKHER.openAll()
ARKHER.out("SUCCESS", "ARKHER V3 — bundle Editors: " .. opened .. " UIs abertas")
]====]
local t = arkher:FindFirstChild("ArkherMainUI")
if not t then t = Instance.new("LocalScript") t.Name = "ArkherMainUI" t.Parent = arkher end
t.Source = S_MAIN
local t = arkher:FindFirstChild("ArkherBundle_Editors")
if not t then t = Instance.new("LocalScript") t.Name = "ArkherBundle_Editors" t.Parent = arkher end
t.Source = S_ED
print("[ARKHER V3] (3/13) MainUI + Bundle_Editors instalados em StarterPlayerScripts.Arkher")
