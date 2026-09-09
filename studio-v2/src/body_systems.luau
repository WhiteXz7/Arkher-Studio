--[[ ARKHER V2 — SYSTEMS: action hooks, atalhos, inspector live, hierarchy live, sandbox ]]
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
ARKHER_REG = ARKHER_REG or {}

-- ---------- action routing (ribbon/menus -> UIs) ----------
local ROUTE = {
	["Save"] = "SaveOpen", ["Open"] = "SaveOpen", ["Save to Arkher"] = "SaveOpen",
	["Settings"] = "Settings", ["Data"] = "DataManager", ["Localization"] = "Localization",
	["Toolbox"] = "Toolbox", ["Collaboration Settings"] = "Collaboration", ["Collaborate"] = "Collaboration",
	["Arkher Cloud"] = "Login", ["Plugin Toolbar"] = "PluginManager",
	["Command Palette"] = "CommandPalette", ["Properties"] = nil, ["Hierarchy"] = "HierarchyLive",
	["Console"] = "Console", ["Output"] = "Console",
	["Model"] = "Toolbox", ["Script"] = "ScriptEditor", ["Text"] = "UTSAI",
	["Game Settings"] = "ProjectSettings", ["Publish to Arkher"] = "BuildSettings",
	["Performance Stats"] = "Profiler", ["Run Diagnostics"] = "Debugger",
	["Invites"] = "Collaboration", ["Changes"] = "VersionControl",
	["Undo"] = "UndoRedo", ["Redo"] = "UndoRedo",
}
local SANDBOX_ON = true
ARKHER_ACTIONS = {
	ribbon = function(name)
		local tgt = ROUTE[name]
		if tgt and ARKHER_REG[tgt] then
			pcall(function() ARKHER_REG[tgt]() end)
			return
		end
		if name == "Play" then
			K.notify("RUN", "Play: use RUN (F5) no Studio — a UI monta via StarterGui e o sandbox valida capacidades", "WARNING")
		elseif name == "Pause" then
			K.notify("RUN", "Pause solicitado ao runtime UES", "INFO")
		end
	end,
	menu = function(item)
		local tgt = ROUTE[item]
		if tgt and ARKHER_REG[tgt] then
			pcall(function() ARKHER_REG[tgt]() end)
			return
		end
		if item == "Sandbox: ON" then
			SANDBOX_ON = not SANDBOX_ON
			K.notify("SANDBOX", SANDBOX_ON and "Sandbox ATIVADO: capability tokens + isolamento de plugins" or "Sandbox desativado (não recomendado)", SANDBOX_ON and "SUCCESS" or "WARNING")
		elseif item == "Reset Layout" then
			for _, ch in ipairs(game:GetService("StarterGui"):GetChildren()) do
				if ch.Name:sub(1, 6) == "Arkher" and ch.Name ~= "ArkherStudioMainUI" then
					pcall(function() ch:Destroy() end)
				end
			end
			K.notify("VIEW", "Layout resetado", "INFO")
		end
	end,
}

-- ---------- global shortcuts ----------
pcall(function()
	UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.KeyCode == Enum.KeyCode.K and (inp.ModifierKeys and false or true) then
			local ctrl = false
			pcall(function() ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) end)
			if ctrl and ARKHER_REG.CommandPalette then ARKHER_REG.CommandPalette() end
		end
	end)
end)

-- ---------- LIVE INSPECTOR (selection -> real properties) ----------
ARKHER_REG.InspectorLive = function()
	local g, root = K.window("ArkherInspectorLive", "Inspector (live)", 40, 120, 260, 320)
	local title = K.txt(root, "nenhuma seleção", 10, 34, 240, 18, 12, T.txt, ARKHER.FONTB)
	local body = K.f(root, "B", 0, 58, 260, 250)
	body.ClipsDescendants = true
	local function refresh()
		body:ClearAllChildren()
		local sel = nil
		pcall(function() sel = Selection:Get()[1] end)
		if not sel then
			title.Text = "nenhuma seleção"
			K.txt(body, "Selecione um objeto no Explorer para inspecionar propriedades reais.", 10, 8, 240, 60, 10, T.txt4)
			return
		end
		title.Text = sel.Name .. " (" .. sel.ClassName .. ")"
		local y = 4
		local function put(k, v)
			K.row(body, k, tostring(v), y)
			y = y + 20
		end
		put("Class", sel.ClassName)
		pcall(function() put("Position", string.format("%.1f, %.1f, %.1f", sel.Position.X, sel.Position.Y, sel.Position.Z)) end)
		pcall(function() put("Size", string.format("%.1f, %.1f, %.1f", sel.Size.X, sel.Size.Y, sel.Size.Z)) end)
		pcall(function() put("Orientation", string.format("%.0f, %.0f, %.0f", sel.Orientation.X, sel.Orientation.Y, sel.Orientation.Z)) end)
		pcall(function() put("Transparency", sel.Transparency) end)
		pcall(function() put("Anchored", sel.Anchored) end)
		pcall(function() put("Material", tostring(sel.Material)) end)
		pcall(function() put("Color", tostring(sel.Color)) end)
		put("Children", #sel:GetChildren())
	end
	refresh()
	pcall(function()
		Selection.SelectionChanged:Connect(refresh)
	end)
	return g
end

-- ---------- HIERARCHY LIVE (real workspace tree) ----------
ARKHER_REG.HierarchyLive = function()
	local g, root = K.window("ArkherHierarchyLive", "Hierarchy (live workspace)", 60, 140, 280, 380)
	K.search(root, 6, 30, 268, 22, "Filter workspace (Ctrl+Shift+X)")
	local tree = K.f(root, "T", 0, 58, 280, 316)
	tree.ClipsDescendants = true
	local ICONMAP = {
		Workspace = "ws", BasePart = "plate", Part = "plate", Terrain = "terrain", Camera = "camera",
		Folder = "folder", Model = "model", Script = "script", LocalScript = "script", ModuleScript = "script",
		Lighting = "bulb", Players = "playersI", Sound = "chat",
	}
	local function iconFor(inst)
		local n = ICONMAP[inst.ClassName] or ICONMAP[inst.Name]
		return n and ICON[n] or ICON.boxG
	end
	local function build(inst, depth, y)
		local kids = inst:GetChildren()
		local state = #kids > 0 and (inst.Name == "Workspace" and "open" or "closed") or nil
		local row = K.treeRow(tree, depth, iconFor(inst), inst.Name, state, y)
		y = y + 20
		row.MouseButton1Click:Connect(function() pcall(function() Selection:Set({ inst }) end) end)
		if state == "open" then
			for _, k in ipairs(kids) do
				y = build(k, depth + 1, y)
			end
		end
		return y
	end
	local function rebuild()
		tree:ClearAllChildren()
		pcall(function() build(workspace, 0, 0) end)
	end
	rebuild()
	local live = K.toggle(root, 180, 32, true, "live")
	return g
end

-- ---------- boot registry convenience ----------
ARKHER.openAll = function()
	for name, fn in pairs(ARKHER_REG) do
		if name ~= "Splash" and name ~= "Login" then
			pcall(fn)
		end
	end
end
