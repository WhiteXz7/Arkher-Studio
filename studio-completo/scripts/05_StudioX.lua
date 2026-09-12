-- =============================================================
-- Arkher_05_StudioX — CONTROLADOR DA SHELL (TabStrip + Ribbon).
-- A shell é REAL (Canvas/ArkherXDeck/ArkherTop no .rbxl: 11 abas,
-- 11 páginas, 84 botões com ícones em Frames). Aqui mora SÓ o sistema:
--   aba ▸ troca de página; botão ▸ abre janela / popup / ação server.
-- ZERO criação de GUI (nenhum Instance.new de GuiObject).
-- Espelha a tabela TABS de tools/build_shell.py (fonte única).
-- =============================================================

local UIS = game:GetService("UserInputService")

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 05 precisa estar dentro de ArkherStudioUI") return end
local canvas = uiRoot:WaitForChild("Canvas", 20)
if not canvas then warn("[ArkherX] 05: Canvas não achado.") return end
local host = canvas:WaitForChild("ArkherXDeck", 25)
if not host then warn("[ArkherX] 05: ArkherXDeck não achado.") return end

-- barramentos (núcleo 01 sobe antes; tolera testes sem menus)
local clientBus, menusBus
do
	local rt = uiRoot:FindFirstChild("ArkherServerClientRuntime")
	local f = rt and rt:FindFirstChild("ClientBus") or nil
	clientBus = f or uiRoot:FindFirstChild("ClientBus")
	menusBus = rt and rt:FindFirstChild("MenusBus") or nil
end

local top = host:WaitForChild("ArkherTop", 20)
if not top then warn("[ArkherX] 05: ArkherTop não achado.") return end
local strip = top:WaitForChild("TabStrip", 10)
local ribbon = top:WaitForChild("Ribbon", 10)
local toast = host:WaitForChild("ArkherMsg", 10)
local toastLbl = toast and toast:WaitForChild("MsgLbl", 5) or nil
local popupsBox = host:WaitForChild("ServerEditorPopups", 10)

-- ---------- toast ----------
local toastTok = 0
local function say(text)
	if not toast or not toastLbl then return end
	toastTok = toastTok + 1
	local mine = toastTok
	toastLbl.Text = tostring(text)
	toast.Visible = true
	task.delay(4, function()
		if mine == toastTok and toast then toast.Visible = false end
	end)
end

-- ---------- chamadas ----------
local function busApi(action, payload)
	if not clientBus then return nil, "sem ClientBus" end
	local ok, r = pcall(function()
		return clientBus:Invoke("API", { action = action, payload = payload or {}, quiet = true })
	end)
	if not ok then return nil, tostring(r) end
	if type(r) == "table" and r.result then return r.result end
	return nil, (type(r) == "table" and r.error) or "sem resposta"
end
local function menusDo(cmd)
	if not menusBus then return nil, "menus indisponíveis" end
	local ok, r = pcall(function() return menusBus:Invoke(cmd) end)
	if not ok then return nil, tostring(r) end
	return r or true
end

-- ---------- janelas ----------
local topZ = 100
local wired = {}
local function dragify(root, handle)
	if not root or not handle then return end
	local dragging, dragStart, startPos
	pcall(function()
		handle.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = inp.Position
				startPos = root.Position
			end
		end)
	end)
	pcall(function()
		UIS.InputChanged:Connect(function(inp)
			if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
				local d = inp.Position - dragStart
				root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end)
	pcall(function()
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end)
end
local function wireWindow(root)
	if not root or wired[root] then return end
	wired[root] = true
	-- deck: fecha/arrasta pelo próprio 08; v2: liga Head/Close aqui
	if root.Name:sub(1, 3) ~= "V2_" then return end
	local head = root:FindFirstChild("Head")
	if head then
		dragify(root, head)
		local cls = head:FindFirstChild("Close")
		if cls and cls:IsA("GuiButton") then
			pcall(function()
				cls.MouseButton1Click:Connect(function() root.Visible = false end)
			end)
			pcall(function()
				cls.Activated:Connect(function() root.Visible = false end)
			end)
		end
	end
end
local function openWindow(name)
	local w = host:FindFirstChild(name)
	if not w then say("Janela não achada: " .. name) return end
	-- deck-first: o 08 centraliza/traz junto
	if name:sub(1, 5) == "Deck_" and name ~= "Deck_rig" and name ~= "Deck_mesh" then
		local d = rawget(_G, "ArkherDeck")
		if d and d.open then
			local ok = pcall(d.open, name:sub(6), nil)
			if ok then wireWindow(w) return end
		end
	end
	w.Visible = true
	topZ = topZ + 1
	pcall(function() w.ZIndex = topZ end)
	wireWindow(w)
end
local function toggleWindow(name)
	local w = host:FindFirstChild(name)
	if not w then say("Janela não achada: " .. name) return end
	w.Visible = not w.Visible
	if w.Visible then
		topZ = topZ + 1
		pcall(function() w.ZIndex = topZ end)
		wireWindow(w)
	end
end

-- ---------- ações (espelho de build_shell.TABS) ----------
-- { kind, arg, payload? } kind: open/toggle/popup/menus/bus
local ACTIONS = {
	HOME_Play = { "menus", "RunToggle" },
	HOME_Pause = { "menus", "RunPause" },
	HOME_Plugins = { "open", "V2_ArkherPluginManager" },
	HOME_Save = { "menus", "Save" },
	HOME_Open = { "menus", "File" },
	HOME_Cloud = { "menus", "OpenCloud" },
	HOME_Undo = { "bus", "Undo", {} },
	HOME_Redo = { "bus", "Redo", {} },
	HOME_Palette = { "open", "V2_ArkherPalette" },
	HOME_Search = { "open", "V2_ArkherSearch" },
	HOME_Toolbox = { "open", "V2_ArkherToolbox" },
	HOME_Settings = { "open", "V2_ArkherSettings" },
	HOME_Status = { "toggle", "V2_ArkherStatusBar" },
	HOME_Account = { "open", "V2_ArkherLogin" },
	HOME_Places = { "open", "V2_ArkherSaveOpen" },
	HOME_History = { "open", "V2_ArkherUndoRedo" },
	BUILD_Part = { "popup", "ArkherShapesPopup" },
	BUILD_Model = { "bus", "CreateAny", { class = "Model" } },
	BUILD_Folder = { "bus", "CreateAny", { class = "Folder" } },
	BUILD_Script = { "bus", "CreateAny", { class = "Script" } },
	BUILD_Text = { "menus", "Insert" },
	BUILD_Material = { "open", "V2_ArkherMaterialEditor" },
	BUILD_Mesh = { "open", "Deck_mesh" },
	BUILD_Modeler = { "open", "Deck_modeler" },
	BUILD_Fabricar = { "open", "Deck_fabricar" },
	BUILD_Insert = { "menus", "Insert" },
	BUILD_Base = { "bus", "EnsureBase", {} },
	BUILD_Union = { "bus", "CsgDo", { op = "union" } },
	BUILD_Negate = { "bus", "CsgDo", { op = "negate" } },
	TERRAIN_Terrain = { "open", "V2_ArkherTerrainEditor" },
	TERRAIN_TerrainX = { "open", "Deck_terrain" },
	TERRAIN_Sculpt = { "open", "Deck_sculpt" },
	TERRAIN_Water = { "open", "Deck_water" },
	TERRAIN_Atmos = { "open", "Deck_atmos" },
	TERRAIN_Clima = { "open", "Deck_clima" },
	ANIMATE_Animator = { "open", "V2_ArkherAnimationEditor" },
	ANIMATE_AnimX = { "open", "Deck_animator" },
	ANIMATE_Timeline = { "open", "V2_ArkherTimeline" },
	ANIMATE_Rig = { "open", "Deck_rig" },
	FX_Particles = { "open", "V2_ArkherParticleEditor" },
	FX_VFX = { "open", "V2_ArkherVFXEditor" },
	FX_FXLab = { "open", "Deck_fx" },
	FX_Cordas = { "open", "Deck_cordas" },
	AUDIO_Audio = { "open", "V2_ArkherAudioEditor" },
	AUDIO_AudioX = { "open", "Deck_audio" },
	WORLD_World = { "open", "V2_ArkherWorldEditor" },
	WORLD_Space = { "open", "Deck_espaco" },
	WORLD_Vida = { "open", "Deck_vida" },
	WORLD_City = { "open", "Deck_cidade" },
	WORLD_Physics = { "open", "V2_ArkherPhysicsEditor" },
	WORLD_Navigate = { "open", "V2_ArkherNavigationEditor" },
	SCRIPT_Scripts = { "open", "V2_ArkherScriptEditor" },
	SCRIPT_Console = { "open", "V2_ArkherConsole" },
	SCRIPT_Debug = { "open", "V2_ArkherDebugger" },
	SCRIPT_Profiler = { "open", "V2_ArkherProfiler" },
	SCRIPT_Terminal = { "open", "Deck_comando" },
	SCRIPT_ScriptsX = { "open", "Deck_scripts" },
	SCRIPT_Output = { "open", "Deck_output" },
	SCRIPT_Py = { "open", "Deck_py" },
	DATA_Data = { "open", "V2_ArkherDataManager" },
	DATA_Lang = { "open", "V2_ArkherLocalization" },
	DATA_Packages = { "open", "V2_ArkherPackageManager" },
	DATA_Versions = { "open", "V2_ArkherVersionControl" },
	DATA_Props = { "open", "Deck_props" },
	DATA_Colors = { "open", "Deck_cores" },
	AI_Singularity = { "open", "V2_ArkherAIEditor" },
	AI_UTS = { "open", "V2_ArkherUTSAI" },
	AI_Graph = { "open", "V2_ArkherGraphEditor" },
	AI_Nodes = { "open", "V2_ArkherNodeEditor" },
	AI_Visual = { "open", "V2_ArkherVisualScripting" },
	AI_Shader = { "open", "V2_ArkherShaderEditor" },
	AI_Docs = { "open", "V2_ArkherDocs" },
	VIEW_UIEdit = { "open", "V2_ArkherUIEditor" },
	VIEW_Layouts = { "open", "V2_ArkherLayouts" },
	VIEW_Alerts = { "open", "V2_ArkherNotifications" },
	VIEW_Collab = { "open", "V2_ArkherCollaboration" },
	VIEW_Project = { "open", "V2_ArkherProjectSettings" },
	VIEW_Build = { "open", "V2_ArkherBuildSettings" },
	VIEW_Plugins = { "open", "V2_ArkherPluginManager" },
	VIEW_Groups = { "open", "Deck_grupos" },
	VIEW_PluginsX = { "open", "Deck_plugins" },
	VIEW_ToolX = { "open", "Deck_toolbox" },
	VIEW_Play = { "menus", "RunToggle" },
	VIEW_Pause = { "menus", "RunPause" },
}

local function runAction(key)
	local a = ACTIONS[key]
	if not a then say("Ação não mapeada: " .. key) return end
	if a[1] == "open" then
		openWindow(a[2])
	elseif a[1] == "toggle" then
		toggleWindow(a[2])
	elseif a[1] == "popup" then
		local p = popupsBox and popupsBox:FindFirstChild(a[2])
		if p then p.Visible = true else say("Popup não achado: " .. a[2]) end
	elseif a[1] == "menus" then
		local _, err = menusDo(a[2])
		if err then say(tostring(err)) end
	elseif a[1] == "bus" then
		local res, err = busApi(a[2], a[3])
		if err then
			say(tostring(err))
		elseif type(res) == "table" and res.msg then
			say(res.msg)
		elseif type(res) == "table" and res.id then
			say("Criado: " .. tostring(res.id))
		else
			say(a[2] .. " ok")
		end
	end
end

-- ---------- fiação ----------
local function onTap(btn, fn)
	local lastT = -1
	local function fire(...)
		local now = os.clock()
		if now - lastT < 0.12 then return end
		lastT = now
		local ok, err = pcall(fn, ...)
		if not ok then warn("[ArkherX] 05 clique: " .. tostring(err)) end
	end
	pcall(function() btn.MouseButton1Click:Connect(fire) end)
	pcall(function() btn.Activated:Connect(fire) end)
end

local TAB_BG_ON = Color3.fromRGB(26, 42, 74)
local TAB_BG_OFF = Color3.fromRGB(7, 13, 25)
local TAB_TX_ON = Color3.fromRGB(230, 235, 245)
local TAB_TX_OFF = Color3.fromRGB(199, 210, 232)
local tabs, pages = {}, {}
if strip and ribbon then
	for _, ch in ipairs(strip:GetChildren()) do
		if ch:IsA("GuiButton") and ch.Name:sub(1, 4) == "Tab_" then
			tabs[ch.Name:sub(5)] = ch
		end
	end
	for _, ch in ipairs(ribbon:GetChildren()) do
		if ch.Name:sub(1, 5) == "Page_" then pages[ch.Name:sub(6)] = ch end
	end
	local function selectTab(name)
		for tn, tb in pairs(tabs) do
			local on = (tn == name)
			pcall(function()
				tb.BackgroundColor3 = on and TAB_BG_ON or TAB_BG_OFF
				tb.BackgroundTransparency = on and 0 or 1
				tb.TextColor3 = on and TAB_TX_ON or TAB_TX_OFF
				local pill = tb:FindFirstChild("ActivePill")
				if pill then pill.Visible = on end
			end)
		end
		for pn, pg in pairs(pages) do
			pcall(function() pg.Visible = (pn == name) end)
		end
	end
	for tn, tb in pairs(tabs) do
		onTap(tb, function() selectTab(tn) end)
	end
	for _, pg in pairs(pages) do
		for _, ch in ipairs(pg:GetChildren()) do
			if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then
				local key = ch.Name:sub(11)
				onTap(ch, function() runAction(key) end)
			end
		end
	end
	_G.ArkherShell = { select = selectTab, run = runAction, say = say }
	print("[ArkherX] 05_Shell: abas + ribbon ligados.")
else
	warn("[ArkherX] 05: TabStrip/Ribbon ausentes.")
end

-- Diagnostico de visibilidade (1 tiro, 1s apos boot): prova no log ONDE a shell esta.
task.delay(1, function()
	local function fld(fn)
		local ok, v = pcall(fn)
		if ok and v ~= nil then return tostring(v) end
		return "?"
	end
	local parts = {
		"pos=" .. fld(function() local p = top.AbsolutePosition return p.X .. "," .. p.Y end),
		"size=" .. fld(function() local z = top.AbsoluteSize return z.X .. "x" .. z.Y end),
		"vis=" .. fld(function() return top.Visible end),
		"topZ=" .. fld(function() return top.ZIndex end),
		"hostZ=" .. fld(function() return host.ZIndex end),
		"deckScale=" .. fld(function() return host:FindFirstChildOfClass("UIScale").Scale end),
		"viewport=" .. fld(function() local z = uiRoot.AbsoluteSize return z.X .. "x" .. z.Y end),
		"pagesVis=" .. fld(function()
			local n = 0
			for _, pg in ipairs(ribbon:GetChildren()) do
				if pg.Name:sub(1, 5) == "Page_" and pg.Visible then n = n + 1 end
			end
			return n
		end),
	}
	print("[ArkherX] 05_DIAG topbar " .. table.concat(parts, " "))
end)
