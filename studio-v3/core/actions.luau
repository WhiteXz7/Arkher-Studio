--[[ ARKHER V3 — ACTIONS: registro central de comandos ]]
-- Menus, toolbar, atalhos, command palette e a IA usam o MESMO registro:
-- ARKHER.cmd("comando", arg). Nenhum botão da UI é decorativo.
local UserInputService = game:GetService("UserInputService")
local Selection = game:GetService("Selection")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")
local HttpService = game:GetService("HttpService")

local A = {}
ArkherActions = A
ARKHER.ACTIONS = A -- mesmo objeto: ARKHER.cmd() despacha p/ A

local function sel()
	local ok, s = pcall(function() return Selection:Get() end)
	if ok and s and #s > 0 then return s[1] end
	return nil
end

-- ================= PLACE / FILE =================
A["place.new"] = function(template)
	ArkherPlaces.new(template)
	ARKHER.out("SUCCESS", "Place novo: " .. ARKHER.STATE.placeName)
end
A["place.open"] = function(id)
	if id then
		ArkherPlaces.open(id)
	else
		ARKHER.open("SaveOpen")
	end
end
A["place.save"] = function()
	ArkherPlaces.save()
end
A["place.close"] = function()
	ArkherPlaces.close()
end
A["place.export"] = function()
	ArkherPlaces.exportToFile()
	ArkherPlaces.copyBundle()
end
A["file.save"] = A["place.save"]
A["file.savecloud"] = function()
	ArkherPublish.toLocal()
end
A["file.open"] = function()
	ARKHER.open("SaveOpen")
end
A["file.import"] = function()
	ARKHER.out("INFO", "Import: copie um bundle .arkher.lua e cole no editor (FILE > Copy Bundle usa a area de transferencia).")
	ARKHER.open("SaveOpen")
end
A["file.export"] = A["place.export"]

-- ================= PUBLISH (sem Open Cloud API) =================
A["publish.local"] = function()
	ArkherPublish.toLocal()
end
A["publish.cloud"] = function()
	if ArkherPublish.toEndpoint() then return end
	ARKHER.out("INFO", "Sem endpoint? O local cloud guardou o bundle. Configure em Settings > Cloud.")
	ArkherPublish.toLocal()
end
A["publish.native"] = function()
	ArkherPublish.toRobloxNative()
end
A["game.publish"] = A["publish.local"]
A["game.places"] = function()
	ARKHER.open("SaveOpen")
end
A["game.settings"] = function()
	ARKHER.open("Settings")
end
A["game.passes"] = function()
	ARKHER.open("PackageManager")
end
A["game.products"] = function()
	ARKHER.out("INFO", "Developer Products: use o Package Manager para registrar passes/produtos no manifest do place.")
	ARKHER.open("PackageManager")
end

-- ================= UNDO (todo editavel passa por aqui antes de mudar) =================
A["undo.push"] = function(label)
	pcall(function() ArkherUNDO.push(label) end)
end

-- ================= EDIT =================
A["edit.undo"] = function() ArkherUNDO.undo() end
A["edit.redo"] = function() ArkherUNDO.redo() end
A["edit.delete"] = function()
	local s = sel()
	if s then
		ARKHER.cmd("undo.push", "Delete " .. s.Name)
		local ok = pcall(function() s:Destroy() end)
		ARKHER.out(ok and "SUCCESS" or "WARNING", "Removido: " .. (ok and s.Name or "sem acesso (servico)"))
	end
end
A["edit.duplicate"] = function()
	local s = sel()
	if not s then return end
	ARKHER.cmd("undo.push", "Duplicate " .. s.Name)
	local clone
	local ok = pcall(function() clone = s:Clone() end)
	if ok and clone then
		clone.Name = s.Name .. " Copy"
		if s:IsA("BasePart") then
			clone.Position = s.Position + Vector3.new(2, 0, 2)
		end
		pcall(function() clone.Parent = s.Parent end)
		pcall(function() Selection:Set({ clone }) end)
		ARKHER.out("SUCCESS", "Duplicado: " .. clone.Name)
	end
end
A["edit.rename"] = function()
	local s = sel()
	if not s then return end
	ARKHER.open("SaveOpen")
	ARKHER.out("INFO", "Renomear: use o panel SaveOpen/Manager ou digite no Explorer do Studio: " .. s.Name)
end
A["edit.copy"] = function()
	local s = sel()
	if s then ARKHER.STATE.clipboard = s end
end
A["edit.paste"] = function()
	local c = ARKHER.STATE.clipboard
	if not c or not c.Parent then
		ARKHER.out("WARNING", "Clipboard vazio")
		return
	end
	ARKHER.cmd("undo.push", "Paste " .. c.Name)
	local clone
	local ok = pcall(function() clone = c:Clone() end)
	if ok and clone then
		clone.Name = c.Name .. " Copy"
		pcall(function() clone.Parent = workspace end)
		ARKHER.out("SUCCESS", "Colado: " .. clone.Name)
	end
end
A["edit.cut"] = function()
	ARKHER.cmd("edit.copy")
	ARKHER.cmd("edit.delete")
end

-- ================= INSERT (cria instancias REAIS) =================
local function insertAt(cls, name, opts)
	ARKHER.cmd("undo.push", "Insert " .. name)
	local inst
	local ok = pcall(function() inst = Instance.new(cls) end)
	if not ok or not inst then
		ARKHER.out("ERROR", "Insert: classe indisponivel " .. cls)
		return
	end
	inst.Name = name or cls
	local pos = workspace:FindFirstChild("Camera")
	local at = (opts and opts.pos) or Vector3.new(0, 3, 0)
	if opts and opts.apply then opts.apply(inst) end
	if inst:IsA("BasePart") then
		inst.Anchored = true
		inst.Position = at
	end
	pcall(function() inst.Parent = workspace end)
	pcall(function() Selection:Set({ inst }) end)
	ARKHER.out("SUCCESS", "Inserido: " .. inst.Name .. " (" .. cls .. ")")
	return inst
end
A["insert.part"] = function()
	insertAt("Part", "Part")
end
A["insert.sphere"] = function()
	insertAt("Part", "Sphere", { apply = function(p) p.Shape = Enum.PartType.Ball p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.cylinder"] = function()
	insertAt("Part", "Cylinder", { apply = function(p) p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(4, 8, 4) end })
end
A["insert.wedge"] = function()
	insertAt("Part", "Wedge", { apply = function(p) p.Shape = Enum.PartType.Wedge p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.blockmesh"] = function()
	insertAt("Part", "BlockMesh", { apply = function(p) p.Shape = Enum.PartType.Block end })
end
A["insert.folder"] = function()
	local inst = insertAt("Folder", "Folder")
	return inst
end
A["insert.model"] = function()
	local m = insertAt("Model", "Model")
	local p = Instance.new("Part")
	p.Name = "Part"
	p.Anchored = true
	p.Size = Vector3.new(4, 4, 4)
	p.Parent = m
	return m
end
A["insert.script"] = function()
	insertAt("Script", "ServerScript", { apply = function(s) s.Source = "-- ServerScript\nprint(\"ARKHER: script criado\")\n" end })
end
A["insert.localscript"] = function()
	insertAt("LocalScript", "ClientScript", { apply = function(s) s.Source = "-- ClientScript\n" end })
end
A["insert.modulescript"] = function()
	insertAt("ModuleScript", "Module", { apply = function(s) s.Source = "return {}\n" end })
end
A["insert.text"] = function()
	local bb = insertAt("Part", "TextPart", { apply = function(p)
		p.Size = Vector3.new(8, 4, 1)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.Parent = p
		local lb = Instance.new("TextLabel")
		lb.Name = "Text"
		lb.Size = UDim2.new(1, 0, 1, 0)
		lb.BackgroundTransparency = 1
		lb.Text = "ARKHER"
		lb.TextScaled = true
		lb.TextColor3 = Color3.new(1, 1, 1)
		lb.Parent = sg
	end })
	return bb
end
A["insert.light"] = function()
	local m = insertAt("Model", "Light")
	local p = Instance.new("Part")
	p.Name = "LightPart"
	p.Anchored = true
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Parent = m
	local pl = Instance.new("PointLight")
	pl.Brightness = 2
	pl.Range = 20
	pl.Color = Color3.new(1, 1, 1)
	pl.Parent = p
	return m
end
A["insert.sound"] = function()
	local m = insertAt("Model", "Sound")
	local p = Instance.new("Part")
	p.Name = "SoundPart"
	p.Anchored = true
	p.Size = Vector3.new(1, 1, 1)
	p.Transparency = 1
	p.CanCollide = false
	p.Parent = m
	local s = Instance.new("Sound")
	s.Name = "Sound"
	s.Loops = false
	s.Parent = p
	return m
end

-- ================= TOOL / TRANSFORM =================
local TOOLS = { Select = "select", Move = "move", Rotate = "rotate", Scale = "scale" }
A["tool"] = function(t)
	ARKHER.STATE.tool = t
	ARKHER.out("INFO", "Ferramenta: " .. t)
	Bus.emit("tool.changed", t)
end
A["transform.lock"] = function()
	ARKHER.STATE.locked = not ARKHER.STATE.locked
	ARKHER.out("INFO", "Lock: " .. (ARKHER.STATE.locked and "ON" or "OFF"))
	Bus.emit("tool.locked", ARKHER.STATE.locked)
end
A["transform.mode"] = function()
	ARKHER.STATE.spaceMode = ARKHER.STATE.spaceMode == "Local" and "Global" or "Local"
	ARKHER.out("INFO", "Espaco de transform: " .. ARKHER.STATE.spaceMode)
end

-- move real do selecionado (arraste com as setas / WASD quando ferramenta Move)
local function nudge(dx, dy, dz)
	local s = sel()
	if not s or not s:IsA("BasePart") then return end
	if ARKHER.STATE.locked then
		ARKHER.out("WARNING", "Objeto travado (Lock ON)")
		return
	end
	local ok = pcall(function() s.Position = s.Position + Vector3.new(dx, dy, dz) end)
	if ok and ARKHER_STATE then end
end
A["move.x+" ] = function() nudge(1, 0, 0) end
A["move.x-"] = function() nudge(-1, 0, 0) end
A["move.y+"] = function() nudge(0, 1, 0) end
A["move.y-"] = function() nudge(0, -1, 0) end
A["move.z+"] = function() nudge(0, 0, 1) end
A["move.z-"] = function() nudge(0, 0, -1) end

-- ================= RUN =================
A["run.play"] = function()
	ARKHER.STATE.playing = true
	ARKHER.out("SUCCESS", "RUN: modo Play (simulacao ARKHER)")
	Bus.emit("run.play")
end
A["run.pause"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: pausado")
	Bus.emit("run.pause")
end
A["run.stop"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: parado")
	Bus.emit("run.stop")
end
A["run.diagnostics"] = function()
	ARKHER_SINGULARITY.run("diagnostico completo do place")
end
A["run.perf"] = function()
	ARKHER.open("Profiler")
end
A["sandbox.toggle"] = function()
	ARKHER.STATE.sandbox = not ARKHER.STATE.sandbox
	ARKHER.out("INFO", "Sandbox: " .. (ARKHER.STATE.sandbox and "ON (plugins isolados)" or "OFF"))
	Bus.emit("sandbox.changed", ARKHER.STATE.sandbox)
end

-- ================= VIEW (abrir UIs) =================
A["view.properties"] = function() Bus.emit("view.toggle", "Properties") end
A["view.hierarchy"] = function() Bus.emit("view.toggle", "Hierarchy") end
A["view.console"] = function() ARKHER.open("Console") end
A["view.output"] = function() ARKHER.open("Console") end
A["view.palette"] = function()
	ARKHER.open("CommandPalette") -- registra/cria (na oculta)
	local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
	local g = fg and fg:FindFirstChild("ArkherStudioCommandPalette")
	if g then g.Visible = true end
end
A["ui.open"] = function(name)
	local ok = ARKHER.open(name)
	if ok then
		ARKHER.out("INFO", "UI aberta: " .. tostring(name))
	else
		ARKHER.out("WARNING", "UI nao abriu: " .. tostring(name))
	end
	return ok
end
A["view.reset"] = function()
	ARKHER.out("INFO", "Layout resetado")
	Bus.emit("view.reset")
end

-- ================= AI / SINGULARITY =================
A["ai.run"] = function(goal)
	ARKHER_SINGULARITY.run(goal)
end
A["ai.mode"] = function(mode)
	ARKHER.STATE.ai.mode = mode
	ARKHER.out("INFO", "IA modo: " .. mode)
	Bus.emit("ai.mode", mode)
end
A["ai.open"] = function()
	ARKHER.open("AIEditor")
end
A["utsai.open"] = function()
	ARKHER.open("UTSAI")
end

-- ================= CLOUD =================
A["cloud.status"] = function()
	local c = ARKHER.STATE.cloud
	ARKHER.out("INFO", "Cloud: " .. (c.endpoint and ("endpoint " .. c.endpoint) or "so local (ServerStorage)") .. " | " .. #c.places .. " places salvos")
	Bus.emit("cloud.status", c)
end
A["cloud.connect"] = function()
	ARKHER.open("Settings")
end
A["cloud.disconnect"] = function()
	ARKHER.STATE.cloud.endpoint = ""
	ARKHER.STATE.cloud.connected = false
	ARKHER.out("INFO", "Cloud: desconectado (modo local)")
	Bus.emit("cloud.status", ARKHER.STATE.cloud)
end

-- ================= GENERIC: ui.<nome> =================
function A.registerUICommands()
	for name in pairs(ARKHER.CATALOG) do
		ARKHER.on("ui." .. name, function()
			ARKHER.open(name)
		end)
		ARKHER.on(name, function()
			ARKHER.open(name)
		end)
	end
	-- atalhos de menu comuns
	ARKHER.on("menu.file.save", A["file.save"])
end

-- ================= SHORTCUTS =================
function A.startShortcuts()
	local CTRL = {
		[Enum.KeyCode.K] = function() ARKHER.open("CommandPalette") end,
		[Enum.KeyCode.Z] = function() ArkherUNDO.undo() end,
		[Enum.KeyCode.Y] = function() ArkherUNDO.redo() end,
		[Enum.KeyCode.D] = function() ARKHER.cmd("edit.duplicate") end,
		[Enum.KeyCode.C] = function() ARKHER.cmd("edit.copy") end,
		[Enum.KeyCode.X] = function() ARKHER.cmd("edit.cut") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("edit.paste") end,
	}
	local PLAIN = {
		[Enum.KeyCode.Delete] = function() ARKHER.cmd("edit.delete") end,
		[Enum.KeyCode.L] = function() ARKHER.cmd("transform.lock") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("tool", "Select") end,
		[Enum.KeyCode.W] = function() ARKHER.cmd("tool", "Move") end,
		[Enum.KeyCode.E] = function() ARKHER.cmd("tool", "Rotate") end,
		[Enum.KeyCode.R] = function() ARKHER.cmd("tool", "Scale") end,
	}
	local NUDGE = {
		[Enum.KeyCode.W] = "move.z-", [Enum.KeyCode.S] = "move.z+",
		[Enum.KeyCode.A] = "move.x-", [Enum.KeyCode.D] = "move.x+",
		[Enum.KeyCode.Q] = "move.y-", [Enum.KeyCode.E] = "move.y+",
	}
	local function onKey(inp, gp)
		if gp then return end
		local isCtrl = pcall(function() return UserInputService:IsKeyDown(Enum.LeftControl) end)
			and UserInputService:IsKeyDown(Enum.LeftControl)
		local code = inp.KeyCode
		if isCtrl and CTRL[code] then
			pcall(CTRL[code])
			return
		end
		if not isCtrl and PLAIN[code] then
			pcall(PLAIN[code])
		end
		-- nudge com WASD quando ferramenta Move (W/E disputam com tool; nudge tem prioridade em Move)
		if ARKHER.STATE.tool == "Move" and not isCtrl and NUDGE[code] then
			ARKHER.cmd(NUDGE[code])
		end
	end
	pcall(function()
		UserInputService.InputBegan:Connect(onKey)
	end)
	ARKHER.out("INFO", "Atalhos: Ctrl+K palette | Ctrl+Z/Y undo/redo | Del apagar | Ctrl+C/X/V/D | V/W/E/R ferramentas | L lock | WASD/Q/E move (ferramenta Move)")
end
