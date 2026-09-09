--[[ ARKHER V3 — LIVE: Inspector (Properties) e Hierarchy ligados ao Estado REAL ]]
-- O Inspector lê a Selection real do Roblox e edita propriedades de verdade.
-- A Hierarchy espelha o DataModel real (workspace + services) com filtro.
local Players = game:GetService("Players")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

local LIVE = {}
ArkherLive = LIVE
ARKHER_LIVE = LIVE

-- ---------- widgets de inspector ----------
local function vec3box(parent, label, vec, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local vals = { vec.X, vec.Y, vec.Z }
	local boxes = {}
	for i = 1, 3 do
		local b = K.input(parent, 118 + (i - 1) * 42, y, 40, 18, "")
		b.Text = tostring(math.floor((vals[i] or 0) * 100) / 100)
		b.TextXAlignment = Enum.TextXAlignment.Center
		b.ClearTextOnFocus = true
		b.FocusLost:Connect(function()
			local n = tonumber(b.Text)
			if n then
				vals[i] = n
				if onChange then onChange(vals[1], vals[2], vals[3]) end
			else
				b.Text = tostring(vals[i])
			end
		end)
		boxes[i] = b
	end
	return boxes
end

local function numbox(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(math.floor(val * 1000) / 1000)
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		local n = tonumber(b.Text)
		if n then
			if min and n < min then n = min end
			if max and n > max then n = max end
			b.Text = tostring(n)
			if onChange then onChange(n) end
		else
			b.Text = tostring(val)
		end
	end)
	return b
end

local function slider(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	min = min or 0
	max = max or 1
	K.txt(parent, label, 22, y, 84, 18, 11, T.txt3)
	local track = K.btn(parent, "Sl_" .. label, 110, y + 6, 96, 6, T.bg4, 3)
	local fill = K.f(track, "Fill", 0, 0, 0, 6, T.accent)
	K.corner(fill, 3)
	local knob = K.f(track, "Knob", 0, -3, 12, 12, T.accent2, 6)
	local label2 = K.txt(parent, "", 210, y, 40, 18, 11, T.txt, FONT, Enum.TextXAlignment.Left)
	local v = math.min(max, math.max(min, val or min))
	local function paint()
		local frac = (v - min) / (max - min)
		fill.Size = UDim2.new(0, math.floor(96 * frac), 0, 6)
		knob.Position = UDim2.new(0, math.floor(96 * frac) - 6, 0, -3)
		label2.Text = string.format("%.2f", v)
	end
	paint()
	local dragging = false
	local function setFromX(xabs)
		local rel = (xabs - track.AbsolutePosition.X) / track.AbsoluteSize.X
		v = math.min(max, math.max(min, min + rel * (max - min)))
		paint()
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if onChange then onChange(v) end
		end
	end)
	return track
end

local function colorbox(parent, label, col, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local sw = K.btn(parent, "Clr_" .. label, 128, y, 96, 18, col, 3)
	K.stroke(sw, T.line2, 1)
	local pal = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(227, 52, 47),
		Color3.fromRGB(255, 152, 0), Color3.fromRGB(255, 230, 0), Color3.fromRGB(102, 187, 106),
		Color3.fromRGB(41, 121, 255), Color3.fromRGB(104, 58, 183), Color3.fromRGB(255, 112, 179),
	}
	local open = false
	sw.MouseButton1Click:Connect(function()
		open = not open
		local dd = sw:FindFirstChild("Pal")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "Pal", 128, y + 20, 96, 58, T.bg2)
			p.Name = "Pal"
			K.stroke(p, T.line2, 1)
			for i, c in ipairs(pal) do
				local cb = K.btn(p, "c" .. i, 4 + ((i - 1) % 4) * 23, 4 + math.floor((i - 1) / 4) * 18, 18, 14, c, 2)
				cb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					sw.BackgroundColor3 = c
					if onChange then onChange(c) end
				end)
			end
			K.f(p, "x", 0, 0, 1, 1, T.bg2)
		end
	end)
	return sw
end

local MATERIALS = {
	"Neon", "SmoothPlastic", "Plastic", "Metal", "Wood", "WoodPlanks", "Concrete",
	"Glass", "Grass", "Slate", "Brick", "CorrodedMetal", "Foil", "Ice", "Marble",
	"MossyRock", "Sand", "Snow", "Fabric", "LeafyGrass",
}
local function materialRow(parent, label, matName, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.btn(parent, "Mat_" .. label, 128, y, 96, 18, T.bg4, 3)
	K.stroke(b, T.line2, 1)
	K.txtS(b, matName or "?", 10, T.txt)
	local open = false
	b.MouseButton1Click:Connect(function()
		open = not open
		local dd = b:FindFirstChild("MList")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "MList", 128, y + 20, 100, 130, T.bg2)
			p.Name = "MList"
			K.stroke(p, T.line2, 1)
			for i, m in ipairs(MATERIALS) do
				local mb = K.btn(p, m, 3, 3 + (i - 1) * 18, 94, 16, T.bg2, 2)
				K.txtS(mb, m, 10, m == matName and T.neon or T.txt2)
				K.hover(mb, T.bg2, T.hover)
				mb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					b:ClearAllChildren()
					K.txtS(b, m, 10, T.txt)
					if onChange then onChange(m) end
				end)
			end
		end
	end)
	return b
end

local function check(parent, label, on, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 128, 18, 11, T.txt3)
	local box = K.btn(parent, "Chk_" .. label, 156, y + 2, 14, 14, T.bg4, 3)
	K.stroke(box, on and T.check or T.line2, 1)
	local inner = K.f(box, "On", 2, 2, 10, 10, T.check)
	K.corner(inner, 2)
	inner.Visible = on
	box.MouseButton1Click:Connect(function()
		on = not on
		inner.Visible = on
		K.stroke(box, on and T.check or T.line2, 1)
		if onChange then onChange(on) end
	end)
	return box
end

local function textRow(parent, label, val, y, onChange, mono)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(val or "")
	b.Font = mono and ARKHER.MONO or FONT
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		if onChange then onChange(b.Text) end
	end)
	return b
end

-- ---------- INSPECTOR ----------
local BASEPART_PROPS = {
	"Position", "CFrame", "Size", "Color", "Material", "Transparency",
	"Anchored", "CanCollide", "CastShadow", "BrickColor",
}
local GUI_PROPS = { "BackgroundColor3", "BackgroundTransparency", "Size", "Position", "Text", "TextColor3", "TextSize" }

function LIVE.currentSelection()
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and type(sel) == "table" and #sel > 0 then return sel[1] end
	return nil
end

function LIVE.rebuildInspector(container)
	local T, K = ARKHER.T, ARKHER.K
	container:ClearAllChildren()
	local inst = LIVE.currentSelection()
	local head = K.f(container, "Head", 1, 0, 10, 26, T.bg3)
	head.Size = UDim2.new(1, -2, 0, 26)
	if not inst then
		K.txt(head, "Nada selecionado", 24, 0, 200, 26, 11, T.txt4)
		return
	end
	local ic = K.f(head, "Ic", 10, 4, 18, 18)
	local iconFn = LIVE.iconFor(inst)
	if iconFn then iconFn(ic, 18) end
	K.txt(head, inst.Name, 32, 0, 120, 26, 12, T.txt, ARKHER.FONTB)
	K.txt(head, inst.ClassName, 0, 0, 150, 26, 9, T.txt4)
	-- linha de classe à direita
	local clsLbl = K.txt(head, inst.ClassName, 0, 0, 110, 26, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	clsLbl.Position = UDim2.new(1, -110, 0, 0)

	local body = K.f(container, "Body", 1, 26, 10, 10, T.bg3)
	body.Size = UDim2.new(1, -2, 1, -26)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Parent = body
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	local inner = K.f(scroll, "Inner", 0, 0, 10, 0, T.bg3)
	inner.Size = UDim2.new(1, -8, 0, 0)
	local y = 4

	local function push(dy)
		y = y + dy
		inner.Size = UDim2.new(1, -8, 0, y)
		scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		return y
	end

	if inst:IsA("BasePart") then
		local sec, sbody = K.section(inner, "Core Properties", true, 0)
		local sy = 0
		local function row(dy)
			sy = sy + dy
			return sy
		end
		local pos = inst.Position or Vector3.new(0, 0, 0)
		local p1 = vec3box(sbody, "Position", pos, 4, function(x, y2, z)
			pcall(function() inst.Position = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local size = inst.Size or Vector3.new(1, 1, 1)
		vec3box(sbody, "Size", size, sy + 2, function(x, y2, z)
			pcall(function() inst.Size = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local col = inst.Color or Color3.new(1, 1, 1)
		colorbox(sbody, "Color", col, sy + 2, function(c)
			pcall(function() inst.Color = c end)
		end)
		sy = row(24)
		local matName = "SmoothPlastic"
		pcall(function() matName = inst.Material.Name end)
		materialRow(sbody, "Material", matName, sy + 2, function(m)
			pcall(function()
				local okm, me = pcall(function() return Enum.Material[m] end)
				if okm and me then inst.Material = me end
			end)
		end)
		sy = row(24)
		local tr = inst.Transparency or 0
		slider(sbody, "Transparency", tr, sy + 2, function(v)
			pcall(function() inst.Transparency = v end)
		end)
		sy = row(26)
		check(sbody, "Anchored", inst.Anchored ~= false, sy + 2, function(v)
			pcall(function() inst.Anchored = v end)
		end)
		sy = row(22)
		check(sbody, "CanCollide", inst.CanCollide ~= false, sy + 2, function(v)
			pcall(function() inst.CanCollide = v end)
		end)
		sy = row(22)
		check(sbody, "CastShadow", inst.CastShadow ~= false, sy + 2, function(v)
			pcall(function() inst.CastShadow = v end)
		end)
		sy = row(24)
		local bh = sy + 6
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Body" then ch.Size = UDim2.new(1, 0, 0, bh) end
		end
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Head" then end
		end
		push(bh + 10)

		local sec2 = K.section(inner, "Physics", true, y + 2)
		local b2 = sec2:FindFirstChild("Body")
		local sy2 = 0
		check(b2, "CanTouch", true, 4, function() end)
		sy2 = sy2 + 22
		check(b2, "CustomPhysicalProperties", false, sy2 + 2, function() end)
		sy2 = sy2 + 22
		b2.Size = UDim2.new(1, 0, 0, sy2 + 10)
		for _, ch in ipairs(sec2:GetChildren()) do
			if ch.Name ~= "Head" and ch.Name ~= "Body" then ch.Position = UDim2.new(0, 0, 0, 0) end
		end
		push(sy2 + 34)

		local sec3, b3 = K.section(inner, "Scripting", false, y + 2)
		check(b3, "Archivable", true, 4, function() end)
		b3.Size = UDim2.new(1, 0, 0, 26)
		push(20 + 26)
	elseif inst:IsA("GuiObject") then
		local sec = K.section(inner, "Layout", true, 0)
		local b = sec:FindFirstChild("Body")
		local sy = 0
		if inst.Size then
			numbox(b, "Size.X", 0, 4, function() end)
			sy = sy + 24
		end
		local col = inst.BackgroundColor3 or Color3.new(0, 0, 0)
		colorbox(b, "BackgroundColor3", col, sy + 2, function(c)
			pcall(function() inst.BackgroundColor3 = c end)
		end)
		sy = sy + 24
		local tr = inst.BackgroundTransparency or 0
		slider(b, "BackgroundTransp.", tr, sy + 2, function(v)
			pcall(function() inst.BackgroundTransparency = v end)
		end)
		sy = sy + 26
		if inst.Text ~= nil then
			textRow(b, "Text", inst.Text, sy + 2, function(t)
				pcall(function() inst.Text = t end)
			end, true)
			sy = sy + 24
			local tc = inst.TextColor3 or Color3.new(1, 1, 1)
			colorbox(b, "TextColor3", tc, sy + 2, function(c)
				pcall(function() inst.TextColor3 = c end)
			end)
			sy = sy + 24
		end
		b.Size = UDim2.new(1, 0, 0, sy + 8)
		push(sy + 28)
	elseif inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
		local sec = K.section(inner, "Code", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "Fonte do script (abrindo no Script Editor):", 22, 4, 200, 16, 10, T.txt3)
		local src = inst.Source or ""
		local preview = K.txt(b, string.sub(src, 1, 300), 22, 22, 190, 60, 9, T.txt2, ARKHER.MONO)
		preview.TextXAlignment = Enum.TextXAlignment.Left
		preview.TextYAlignment = Enum.TextYAlignment.Top
		preview.TextWrapped = true
		local ob = K.btn(b, "OpenInEditor", 22, 88, 120, 20, T.sec, 4)
		K.txtS(ob, "Abrir no Script Editor", 10, T.txt)
		K.hover(ob, T.sec, T.hover)
		ob.MouseButton1Click:Connect(function()
			ARKHER.STATE.scriptOpen = inst
			ARKHER.open("ScriptEditor")
			ARKHER.out("INFO", "Script aberto: " .. inst:GetFullName())
		end)
		b.Size = UDim2.new(1, 0, 0, 120)
		push(140)
	else
		local sec = K.section(inner, "Identity", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "FullName", 22, 4, 80, 16, 10, T.txt3)
		K.txt(b, inst:GetFullName(), 100, 4, 130, 16, 9, T.txt2, ARKHER.MONO)
		b.Size = UDim2.new(1, 0, 0, 26)
		push(40)
	end
end

-- ---------- ICONS POR CLASSE (hierarchy) ----------
local CLASS_ICON = {
	Baseplate = "plate", Part = "cubeW", Terrain = "terrain", Camera = "camera",
	Workspace = "ws", SpawnLocation = "plate", Model = "model",
	Script = "script", LocalScript = "script", ModuleScript = "script",
	Folder = "folder", Lighting = "bulb", Players = "playersI",
	MaterialService = "gem", ReplicatedFirst = "repfirst",
	ReplicatedStorage = "boxG", ServerScriptService = "cubeT", ServerStorage = "cubeT",
	StarterGui = "folderP", StarterPack = "folderP", StarterPlayer = "folderP",
	TextChatService = "chat", PointLight = "bulb", SpotLight = "bulb",
	ParticleEmitter = "particle", Sound = "music", MeshPart = "model",
}
function LIVE.iconFor(inst)
	local n = CLASS_ICON[inst.ClassName] or CLASS_ICON[inst.Name]
	if n and ICON[n] then return ICON[n] end
	if inst:IsA("BasePart") then return ICON.cubeW end
	if inst:IsA("GuiObject") then return ICON.imageI end
	if inst:IsA("Model") then return ICON.model end
	return ICON.folder
end

-- ---------- HIERARCHY ----------
local SERVICE_ROWS = {
	"Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage",
	"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
	"TextChatService", "SoundService", "RunService", "Workspace",
}

function LIVE.matchFilter(inst, filter)
	if not filter or filter == "" then return true end
	local f = filter:lower()
	local nameOk = inst.Name:lower():find(f, 1, true) ~= nil
	local clsOk = inst.ClassName:lower():find(f, 1, true) ~= nil
	return nameOk or clsOk
end

local function hierarchyNode(parent, inst, depth, y, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	local kids = inst:GetChildren()
	local hasKids = #kids > 0
	local visible = LIVE.matchFilter(inst, filter) or (hasKids and false)
	-- mantém visivel se qualquer descendant casar
	if not visible and hasKids then
		local any = false
		for _, ch in ipairs(kids) do
			if LIVE.matchFilter(ch, filter) then any = true break end
		end
		visible = any
	end
	if not visible then return y end
	local row = K.treeRow(parent, depth, LIVE.iconFor(inst), inst.Name, hasKids and (state.open[inst.Name] and depth < 99 and "open" or "closed") or nil, y)
	if inst == LIVE.currentSelection() then
		row.BackgroundColor3 = T.sel
	end
	row.MouseButton1Click:Connect(function()
		local ok = pcall(function() Selection:Set({ inst }) end)
		if not ok then
			pcall(function() Selection:Set({ inst }) end)
		end
		Bus.emit("hierarchy.picked", inst)
		ARKHER.out("INFO", "Selecionado: " .. inst:GetFullName())
	end)
	y = y + 20
	if hasKids then
		local isOpen = state.open[inst.Name] ~= false and depth <= 2
		state.open[inst.Name] = isOpen
		-- chevron clicavel
		local chev = row:FindFirstChild("Chev")
		if chev then
			local cb = K.btn(row, "ChevBtn", 6 + depth * 16, 2, 14, 16, T.bg3, 2)
			cb.BackgroundColor3 = T.bg3
			if isOpen then ICON.chevD(chev, 8) else ICON.chevR(chev, 8) end
			cb.MouseButton1Click:Connect(function()
				state.open[inst.Name] = not state.open[inst.Name]
				ARKHER_LIVE.rebuildHierarchy(state.container, state.filter or "", state)
			end)
		end
		if isOpen then
			for _, ch in ipairs(kids) do
				y = hierarchyNode(parent, ch, depth + 1, y, filter, state)
			end
		end
	end
	return y
end

function LIVE.rebuildHierarchy(container, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	state = state or { open = {}, filter = filter }
	state.filter = filter or ""
	if state.container ~= container then state.container = container end
	container:ClearAllChildren()
	local ws = workspace
	local y = 4
	-- raiz: Workspace
	local rootRow = K.treeRow(container, 0, ICON.ws, "Workspace", "open", y)
	rootRow.BackgroundColor3 = T.bg3
	K.stroke(rootRow, T.line, 1)
	y = y + 20
	for _, ch in ipairs(ws:GetChildren()) do
		y = hierarchyNode(container, ch, 1, y, state.filter, state)
	end
	-- services (niveis de primeira classe)
	y = y + 6
	local svcLbl = K.txt(container, "— services —", 8, y, 150, 14, 9, T.txt4)
	y = y + 16
	for _, svcName in ipairs(SERVICE_ROWS) do
		if svcName ~= "Workspace" then
			local svc = game:FindFirstChild(svcName)
			if svc and LIVE.matchFilter(svc, state.filter) then
				local r = K.treeRow(container, 0, LIVE.iconFor(svc) or ICON.server, svcName .. "+", "closed", y)
				r.BackgroundColor3 = T.bg3
				r.MouseButton1Click:Connect(function()
					pcall(function() Selection:Set({ svc }) end)
					ARKHER.out("INFO", "Serviço selecionado: " .. svcName)
				end)
				y = y + 20
			end
		end
	end
	-- auto-abre workspace
	if state.open["Workspace"] == nil then state.open["Workspace"] = true end
end

-- ---------- WIRING (SelectionChanged + Changed do seleto) ----------
function LIVE.start()
	ARKHER.out("INFO", "ArkherLive: ligando SelectionChanged/Changed")
	local function onSel()
		Bus.emit("inspector.refresh")
		Bus.emit("hierarchy.refresh")
	end
	pcall(function()
		Selection.SelectionChanged:Connect(onSel)
	end)
	-- Changed do objeto selecionado (throttled por frame)
	local dirty = false
	pcall(function()
		RunService.Heartbeat:Connect(function()
			if dirty then
				dirty = false
				Bus.emit("inspector.refresh")
			end
		end)
	end)
	local function watch(inst)
		if not inst then return end
		pcall(function()
			inst:GetPropertyChangedSignal("*"):Connect(function()
				dirty = true
			end)
		end)
	end
	pcall(function()
		Selection.SelectionChanged:Connect(function()
			local sel = LIVE.currentSelection()
			watch(sel)
		end)
	end)
end
