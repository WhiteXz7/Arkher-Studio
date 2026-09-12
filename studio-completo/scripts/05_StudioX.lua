-- =============================================================
-- Arkher_05_StudioX — CONTROLADOR DA SHELL (TabStrip + Ribbon).
-- A shell é REAL (Canvas/ArkherXDeck/ArkherTop no .rbxl: 11 abas,
-- 11 páginas, 89 botões com ícones em Frames). Aqui mora SÓ o sistema:
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
	if not toast or not toastLbl then
		pcall(function()
			toast = host and host:FindFirstChild("ArkherMsg", true) or toast
			toastLbl = toast and toast:FindFirstChild("MsgLbl", true) or toastLbl
		end)
	end
	print("[ArkherX] SAY " .. tostring(text))
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
	if name:sub(1, 3) == "V2_" then
		pcall(function()
			w.AnchorPoint = Vector2.new(0.5, 0.5)
			w.Position = UDim2.new(0.5, 0, 0.46, 0)
		end)
	end
	wireWindow(w)
	print("[ArkherX] ArkherOPEN " .. name .. " vis=" .. tostring(w.Visible))
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
	-- FILE (antiga FileTools)
	FILE_Save = { "menus", "Save" },
	FILE_Open = { "menus", "File" },
	FILE_SaveToArkher = { "bus", "CloudQuick" },
	-- INSERT (antiga InsertTools)
	INSERT_Model = { "bus", "CreateAny", { class = "Model" } },
	INSERT_Folder = { "bus", "CreateAny", { class = "Folder" } },
	INSERT_Script = { "bus", "CreateAny", { class = "Script" } },
	INSERT_Text = { "bus", "CreateAny", { class = "TextLabel" } },
	-- RUN (antiga RunTools)
	RUN_Play = { "menus", "RunToggle" },
	RUN_Pause = { "menus", "RunPause" },
	-- TRANSFORM (antiga TransformTools; modos do nucleo 01)
	TRANSFORM_Select = { "core", "Select" },
	TRANSFORM_MoveScale = { "core", "MoveScale" },
	TRANSFORM_Rotate = { "core", "Rotate" },
	TRANSFORM_Scale = { "core", "Scale" },
	TRANSFORM_Transform = { "core", "Transform" },
	TRANSFORM_Lock = { "core", "Lock" },
	TRANSFORM_LocalGlobal = { "core", "LocalGlobal" },
	-- SETTINGS (antiga SettingsTools; paineis 03)
	SETTINGS_Data = { "menus", "OpenData" },
	SETTINGS_Localization = { "menus", "OpenLocalization" },
	SETTINGS_Settings = { "menus", "OpenProjectSettings" },
	-- PLUGINS (antiga PluginTools)
	PLUGINS_ArkherCloud = { "menus", "OpenCloud" },
	PLUGINS_PluginToolbar = { "menus", "OpenPlugins" },
	-- TEAM (antiga CollaborationTools)
	TEAM_CollaborationSettings = { "menus", "OpenCollaboration" },
	TEAM_Toolbox = { "menus", "OpenToolbox" },
}

local lastQuick = 0
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
		if a[2] == "CloudQuick" then
			local nowQ = os.time()
			if nowQ - lastQuick < 5 then say("Aguarde " .. math.ceil(5 - (nowQ - lastQuick)) .. "s (publicando...).") return end
			lastQuick = nowQ
			say("Publicando + criando place...")
		end
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
	elseif a[1] == "core" then
		if not clientBus then say("sem ClientBus") return end
		local ok, r = pcall(function() return clientBus:Invoke(a[2], a[3] or {}) end)
		if not ok then say(tostring(r)) end
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
	-- icones ORIGINAIS (02 pinta via IconsBus; assados ficam de fallback)
	pcall(function()
		local rt = uiRoot:FindFirstChild("ArkherServerClientRuntime")
		local ib = rt and rt:FindFirstChild("IconsBus") or nil
		if ib then
			local ir = rt:FindFirstChild("IconsReady")
			local t0, tries = os.clock(), 0
			while tries < 30 and (not ir or not ir.Value) and os.clock() - t0 < 3 do
				tries = tries + 1
				task.wait(0.1)
			end
			if ir and ir.Value then
				local kinds = { FILE_Save = "Save", FILE_Open = "Open", FILE_SaveToArkher = "Cloud",
					INSERT_Folder = "Folder", INSERT_Model = "Model", INSERT_Script = "Script", INSERT_Text = "Text",
					RUN_Play = "Play", RUN_Pause = "Pause", TRANSFORM_Select = "Select",
					TRANSFORM_MoveScale = "Move", TRANSFORM_Rotate = "Rotate", TRANSFORM_Scale = "Scale",
					TRANSFORM_Transform = "Scale", TRANSFORM_Lock = "Lock", TRANSFORM_LocalGlobal = "Move",
					SETTINGS_Data = "Data", SETTINGS_Localization = "Localization", SETTINGS_Settings = "Settings",
					PLUGINS_ArkherCloud = "Info", PLUGINS_PluginToolbar = "Plugin",
					TEAM_CollaborationSettings = "Collaboration", TEAM_Toolbox = "Tool" }
				local n = 0
				for _, pg in pairs(pages) do
					for _, ch in ipairs(pg:GetChildren()) do
						if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then
							local k = kinds[ch.Name:sub(11)]
							local ic = ch:FindFirstChild("Icon")
							if k and ic then
								local ok = pcall(function() ib:Invoke("Draw", { object = ic, kind = k, size = 40 }) end)
								if ok then n = n + 1 end
							end
						end
					end
				end
				print("[ArkherX] 05 icones originais: " .. n .. "/23 pintados.")
			else
				print("[ArkherX] 05 icones: 02 indisponivel, usando assados.")
			end
		end
	end)

	_G.ArkherShell = { select = selectTab, run = runAction, say = say }
	-- auto-cura de boot: garante topbar visivel e UMA pagina (HOME)
	pcall(function() top.Visible = true end)
	selectTab("FILE")
	print("[ArkherX] 05_Shell: abas + ribbon ligados.")
	print("[ArkherX] 05 build 2026-09-12/OLD-BUTTONS (7 abas x 23 botoes antigos, UIL horizontal, icones 02).")
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
		"canvasScale=" .. fld(function() local c = canvas and canvas:FindFirstChild("ResponsiveScale") return c and c.Scale end),
		"deckSize=" .. fld(function() local z = host.AbsoluteSize return z.X .. "x" .. z.Y end),
		"fileBtns=" .. fld(function()
			local pg = ribbon and ribbon:FindFirstChild("Page_FILE")
			local v, t = 0, 0
			if pg then for _, ch in ipairs(pg:GetChildren()) do
				if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then
					t = t + 1
					if ch.Visible then v = v + 1 end
				end
			end end
			return v .. "/" .. t
		end),
		"saveOpen=" .. fld(function()
			local w0 = host and host:FindFirstChild("V2_ArkherSaveOpen")
			if not w0 then return "nil" end
			local p = w0.AbsolutePosition
			return tostring(w0.Visible) .. "@" .. math.floor(p.X) .. "," .. math.floor(p.Y)
		end),
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

-- ==== FASE 3 — V2_ArkherSaveOpen (janela ASSADA): cloud + place + publish REAIS ====
do
	local sv = host and host:FindFirstChild("V2_ArkherSaveOpen")
	if sv then
		local HS = game:GetService("HttpService")
		local input = sv:FindFirstChild("Input")
		if input and not input:IsA("TextBox") then input = input:FindFirstChildOfClass("TextBox", true) end
		local go = sv:FindFirstChild("Go")
		local go2 = sv:FindFirstChild("Go2")
		local newP = sv:FindFirstChild("NewPlace")
		local saveA = sv:FindFirstChild("SaveAcct")
		local pub = sv:FindFirstChild("Publish")
		local tabS = sv:FindFirstChild("TabS")
		local tabO = sv:FindFirstChild("TabO")
		local rows = {}
		do local listF = sv:FindFirstChild("List")
			if listF then for _, ch in ipairs(listF:GetChildren()) do
				if ch:IsA("GuiButton") and ch.Name:sub(1, 2) == "R_" then rows[#rows + 1] = ch end
			end end
			table.sort(rows, function(a, b) return a.Name < b.Name end) end
		local projects, sel, mode = {}, 1, "save"
		local SEL_BG = Color3.fromRGB(26, 42, 74)
		local UNS_BG = Color3.fromRGB(7, 13, 25)
		local function dump(res)
			local ok, j = pcall(function() return HS:JSONEncode(res) end)
			if ok and type(j) == "string" then return j:sub(1, 160) end
			return tostring(res)
		end
		local function rowText(row)
			if not row then return nil end
			local first = nil
			for _, d in ipairs(row:GetDescendants()) do
				if d:IsA("TextLabel") then
					if not first then first = d else pcall(function() d.Text = "" end) end
				end
			end
			if first then return first end
			if row:IsA("TextButton") or row:IsA("TextLabel") then return row end
			return nil
		end
		local function rowBtn(row)
			if not row then return nil end
			if row:IsA("GuiButton") then return row end
			return row:FindFirstChildOfClass("GuiButton", true)
		end
		local function paint()
			for i, row in ipairs(rows) do
				local p = projects[i]
				local t = rowText(row)
				if t then pcall(function()
					t.Text = p and (tostring(p.name):sub(1, 24) .. "  [" .. tostring(p.nodes or 0) .. " obj]  " .. tostring(p.savedAt or "")):sub(1, 44) or ("-- slot " .. i .. " --")
				end) end
				if row then pcall(function()
					row.BackgroundColor3 = (i == sel) and SEL_BG or UNS_BG
					row.BackgroundTransparency = (i == sel) and 0 or 0.55
				end) end
			end
			for _, tp in ipairs({ tabS, tabO }) do if tp then pcall(function()
				local on = (tp == tabS and mode == "save") or (tp == tabO and mode == "open")
				tp.BackgroundColor3 = on and SEL_BG or UNS_BG
				tp.BackgroundTransparency = on and 0 or 0.55
			end) end end
		end
		local function refresh()
			if not sv.Visible then return end
			local res, err = busApi("CloudList", {})
			if err then say("Cloud: " .. tostring(err), true) return end
			projects = (res and res.projects) or {}
			if sel > math.max(1, #projects) then sel = 1 end
			paint()
		end
		local function curName(def)
			local t = input and input.Text or ""
			t = t:match("^%s*(.-)%s*$")
			if #t < 3 then return def end
			return t
		end
		for i, row in ipairs(rows) do local b = rowBtn(row) if b then pcall(function()
			local function pick() if _G.ArkherSvConta and _G.ArkherSvConta.on then _G.ArkherSvConta.sel = i if _G.ArkherSvContaPaint then _G.ArkherSvContaPaint() end else sel = i paint() end end
			b.MouseButton1Click:Connect(pick)
			b.Activated:Connect(pick)
		end) end end
		local function tap(n, fn) if n and n:IsA("GuiButton") then pcall(function()
			n.MouseButton1Click:Connect(fn) n.Activated:Connect(fn)
		end) end end
		tap(tabS, function() mode = "save" paint() refresh() say("Modo SALVAR (Go = salva na cloud).") end)
		tap(tabO, function() mode = "open" paint() refresh() say("Modo ABRIR (Go2 = abre o slot selecionado).") end)
		tap(go, function()
			local res, err = busApi("CloudSave", { name = curName("") })
			if err then say("Salvar: " .. tostring(err), true)
			else local pr = res and res.project or {} say("Salvo na cloud: " .. tostring(pr.name or "?") .. " (" .. tostring(pr.nodes or 0) .. " obj).") refresh() end
		end)
		tap(go2, function()
			if _G.ArkherSvConta and _G.ArkherSvConta.on then
				local c = _G.ArkherSvConta.places[_G.ArkherSvConta.sel]
				if not c then say("Nada selecionado na conta.", true) return end
				say("Indo p/ " .. tostring(c.name) .. "...")
				local _, e = busApi("TeleportTo", { placeId = c.id })
				if e then say("Abrir: " .. tostring(e), true) end return
			end
			refresh()
			local p = projects[sel]
			if not p then say("Nada no slot " .. sel .. " (salve primeiro).", true) return end
			say("Abrindo " .. tostring(p.name) .. " (viewport atual sera substituida)...")
			local _, err = busApi("CloudOpen", { id = p.id })
			if err then say("Abrir: " .. tostring(err), true) else say("Projeto aberto: " .. tostring(p.name) .. ".") end
		end)
		tap(newP, function()
			local nm = curName("Place " .. os.date("%d/%m %H:%M"))
			say("Criando place " .. nm .. "...")
			local res, err = busApi("PlaceCreate", { name = nm })
			if err then say("PlaceCreate: " .. tostring(err), true)
			else _G.ArkherLastPlace = res and res.placeId or nil
				say("Place criada: " .. dump(res) .. " — ABRIR teleporta p/ la.") end
		end)
		tap(saveA, function()
			local res, err = busApi("SavePlace", {})
			if err then say("SavePlace: " .. tostring(err), true) else say("Place salva na conta: " .. dump(res)) end
		end)
		tap(pub, function()
			say("1-CLIQUE: snapshot na cloud...")
			local snap, e1 = busApi("CloudSave", { name = "Auto " .. os.date("%d/%m %H:%M") })
			if e1 then say("1-CLIQUE: cloud falhou: " .. tostring(e1), true) return end
			local pr = snap and snap.project or {}
			say("1-CLIQUE: cloud ok (" .. tostring(pr.nodes or 0) .. " obj). Salvando place...")
			local _, e2 = busApi("SavePlace", {})
			local pid = 0 pcall(function() pid = game.PlaceId or 0 end)
			if e2 then say("1-CLIQUE: cloud OK; SavePlace recusou (ative o API nas settings da place): " .. tostring(e2), true)
			else say("PUBLICADO 1-CLIQUE: cloud + place. roblox.com/games/" .. tostring(pid)) end
			refresh()
		end)
		if input and input:IsA("TextBox") then pcall(function()
			input.FocusLost:Connect(function(enter) if enter and go then pcall(function() go:Activate() end) end end)
		end) end
		pcall(function()
			sv:GetPropertyChangedSignal("Visible"):Connect(function() if sv.Visible then refresh() end end)
		end)
		paint()
	end
end

-- ==== FASE 4 — SaveOpen: ABRIR + EXPORT + CONTA (conta real) ====
do
	local sv = host and host:FindFirstChild("V2_ArkherSaveOpen")
	if sv then
		_G.ArkherSvConta = _G.ArkherSvConta or { on = false, places = {}, sel = 1 }
		local st = _G.ArkherSvConta
		local input = sv:FindFirstChild("Input")
		if input and not input:IsA("TextBox") then input = input:FindFirstChildOfClass("TextBox", true) end
		local abrir = sv:FindFirstChild("Abrir")
		local export = sv:FindFirstChild("Export")
		local conta = sv:FindFirstChild("Conta")
		local rows = {}
		do local listF = sv:FindFirstChild("List")
			if listF then for _, ch in ipairs(listF:GetChildren()) do
				if ch:IsA("GuiButton") and ch.Name:sub(1, 2) == "R_" then rows[#rows + 1] = ch end
			end end
			table.sort(rows, function(a, b) return a.Name < b.Name end) end
		local SEL_BG = Color3.fromRGB(26, 42, 74)
		local UNS_BG = Color3.fromRGB(7, 13, 25)
		local function rtext(row)
			if not row then return nil end
			local first = nil
			for _, d in ipairs(row:GetDescendants()) do
				if d:IsA("TextLabel") then
					if not first then first = d else pcall(function() d.Text = "" end) end
				end
			end
			if first then return first end
			if row:IsA("TextButton") or row:IsA("TextLabel") then return row end
			return nil
		end
		_G.ArkherSvContaPaint = function()
			for i, row in ipairs(rows) do
				local c = st.places[i]
				local t = rtext(row)
				if t then pcall(function()
					t.Text = c and ("@ " .. tostring(c.name):sub(1, 30) .. "  [id " .. tostring(c.id) .. "]"):sub(1, 44) or ("-- conta slot " .. i .. " --")
				end) end
				if row then pcall(function()
					row.BackgroundColor3 = (i == st.sel) and SEL_BG or UNS_BG
					row.BackgroundTransparency = (i == st.sel) and 0 or 0.55
				end) end
			end
		end
		local function paintCloudBack()
			local res, err = busApi("CloudList", {})
			local projects = (res and not err) and (res.projects or {}) or {}
			for i, row in ipairs(rows) do
				local p = projects[i]
				local t = rtext(row)
				if t then pcall(function()
					t.Text = p and (tostring(p.name):sub(1, 24) .. "  [" .. tostring(p.nodes or 0) .. " obj]"):sub(1, 44) or ("-- slot " .. i .. " --")
				end) end
			end
		end
		local function tap(n, fn) if n and n:IsA("GuiButton") then pcall(function()
			n.MouseButton1Click:Connect(fn) n.Activated:Connect(fn)
		end) end end
		tap(conta, function()
			st.on = not st.on
			if not st.on then paintCloudBack() say("Modo CLOUD (snapshots).") return end
			say("Listando places reais da conta...")
			local res, err = busApi("AccountPlaces", {})
			if err then st.on = false say("Conta: " .. tostring(err), true) return end
			st.places = (res and res.places) or {}
			st.sel = 1
			_G.ArkherSvContaPaint()
			say("CONTA: " .. #st.places .. " places reais. Go2/ABRIR teleporta.")
		end)
		tap(abrir, function()
			local target, nm = nil, nil
			if st.on then local c = st.places[st.sel] if c then target, nm = c.id, c.name end
			else target = _G.ArkherLastPlace end
			if not target then say(st.on and "Nada selecionado na conta." or "Crie uma place (NEW PLACE) ou entre na CONTA primeiro.", true) return end
			say("Abrindo " .. tostring(nm or ("place " .. tostring(target))) .. "...")
			local _, err = busApi("TeleportTo", { placeId = target })
			if err then say("ABRIR: " .. tostring(err), true) end
		end)
		tap(export, function()
			local t = input and input.Text or ""
			t = t:match("^%s*(.-)%s*$")
			local nm = (#t >= 3) and t or ("Arkher " .. os.date("%d/%m %H:%M"))
			say("EXPORT: gerando .rbxlx de " .. nm .. "...")
			local res, err = busApi("PublishReal", { name = nm })
			if err then say("EXPORT: " .. tostring(err), true) return end
			if res and res.published then say("PUBLICADO NA CONTA: versao " .. tostring(res.version) .. " (" .. tostring((res.stats or {}).parts or 0) .. " parts).")
			elseif res and res.url then say("RBXLX pronto: " .. tostring(res.url) .. " (" .. tostring((res.stats or {}).parts or 0) .. " parts, " .. tostring((res.stats or {}).bytes or 0) .. " bytes). Baixe e publique pelo Studio.")
			else say("EXPORT: " .. tostring(res and res.file or "?")) end
		end)
	end
end

