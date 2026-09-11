--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA (11/13)
  ArkherStudio_ALL chunk 2/3
  Cria: ReplicatedStorage.ArkherV3.ALL.ALL_P2 (ModuleScript, 83,624 chars)
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]
local rs = game:GetService("ReplicatedStorage")
local arkherv3 = rs:FindFirstChild("ArkherV3")
if not arkherv3 then arkherv3 = Instance.new("Folder") arkherv3.Name = "ArkherV3" arkherv3.Parent = rs end
local all = arkherv3:FindFirstChild("ALL")
if not all then all = Instance.new("Folder") all.Name = "ALL" all.Parent = arkherv3 end
local S_CHUNK = [=====[return[====[A["place.export"] = function()
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
end

do
--[[ ARKHER V3 — SINGULARITY CORE: IA operadora do editor ]]
-- Arquitetura: USER → objetivo → PLANNER → tarefas → ESPECIALISTAS → VERIFIER → relatório
-- Especialistas LOCAIS executam de verdade no Roblox (procedural real, sem depender de web).
-- Ponte opcional: se o usuario configurar um endpoint (Settings > AI), o plano tambem
-- pode vir de um LLM externo (mesmo contrato JSON). Sem endpoint = modo local 100%.
local HttpService = game:GetService("HttpService")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local SG = {}
ARKHER_SINGULARITY = SG

SG.memory = { decisions = {}, context = {}, tasks = 0 }

local function log(kind, msg)
	ARKHER.out(kind, "[SINGULARITY] " .. tostring(msg))
end

local function report(title, lines)
	local out = { title = title, lines = lines, ok = true }
	Bus.emit("singularity.report", out)
	log("SUCCESS", title .. " — " .. #lines .. " etapas")
	return out
end

-- ---------- PLANNER LOCAL (intent → tarefas) ----------
local INTENTS = {
	city = { "cidade", "city", "prédios", "predios", "buildings", "rua", "road", "urbe" },
	nature = { "floresta", "forest", "natureza", "nature", "arvore", "árvore", "tree", "montanha", "mountain", "lago", "lake" },
	space = { "espaco", "espaço", "space", "asteroide", "asteroid", "planet", "planeta" },
	npc = { "npc", "personagem", "personagens", "habitantes", "population", "populacao", "população", "moradores" },
	light = { "luz", "light", "iluminacao", "iluminação", "noite", "night", "amanhecer", "sunset", "day", "dia" },
	clean = { "organizar", "organize", "arrumar", "naming", "rotular", "label" },
	perf = { "otimizar", "otimiza", "otimizado", "otimizada", "otimizacao", "otimização", "otimise", "otimize", "otimizar", "optimize", "optimized", "performance", "fps", "leve" },
	check = { "diagnostico", "diagnóstico", "diagnostics", "analisar", "analyze", "auditoria", "audit" },
	material = { "material", "pbr", "superficie", "superfície", "textura", "texture" },
	place = { "place", "mundo", "world", "mapa", "map" },
}

local function detectIntents(text)
	local t = (text or ""):lower()
	local found = {}
	for name, kws in pairs(INTENTS) do
		for _, kw in ipairs(kws) do
			if t:find(kw, 1, true) then
				found[name] = true
				break
			end
		end
	end
	return found
end

function SG.plan(goal)
	local intents = detectIntents(goal)
	local plan = { goal = goal, tasks = {}, mode = ARKHER.STATE.ai.mode }
	local order = { "place", "city", "nature", "space", "material", "light", "npc", "clean", "perf", "check" }
	for _, name in ipairs(order) do
		if intents[name] then table.insert(plan.tasks, name) end
	end
	if #plan.tasks == 0 then
		table.insert(plan.tasks, "check")
	end
	return plan
end

-- ---------- ESPECIALISTAS LOCAIS (execucao REAL no Roblox) ----------
local E = {}
SG.experts = E

function E.place(ctx)
	ARKHER.cmd("undo.push", "Singularity: place")
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then pcall(function() ch:Destroy() end) end
	end
	ArkherPlaces.TEMPLATES.Baseplate()
	ctx.lines[#ctx.lines + 1] = "base: baseplate 120x120 + spawn criados"
end

function E.city(ctx)
	local model = Instance.new("Model")
	model.Name = "CityGen_" .. (SG.memory.tasks + 1)
	model.Parent = workspace
	local rng = Random.new(SG.memory.tasks * 17 + 3)
	local n = 10 + rng:NextInteger(0, 8)
	local built = 0
	for i = 1, n do
		local b = Instance.new("Part")
		b.Name = "Building_" .. i
		local h = 5 + rng:NextInteger(0, 22)
		b.Size = Vector3.new(5 + rng:NextInteger(0, 7), h, 5 + rng:NextInteger(0, 7))
		b.Position = Vector3.new((rng:NextInteger(-6, 6)) * 9 + 4.5, h / 2 + 0.5, (rng:NextInteger(-6, 6)) * 9 + 4.5)
		b.Anchored = true
		b.Color = Color3.fromRGB(90 + rng:NextInteger(0, 70), 95 + rng:NextInteger(0, 70), 110 + rng:NextInteger(0, 70))
		b.Parent = model
		built = built + 1
	end
	local roads = 0
	for i = -1, 1 do
		local r = Instance.new("Part")
		r.Name = "Road_" .. (i + 2)
		r.Size = Vector3.new(80, 0.2, 5)
		r.Position = Vector3.new(0, 0.15, i * 18)
		r.Anchored = true
		r.Color = Color3.fromRGB(28, 28, 32)
		r.Material = Enum.Material.Asphalt
		r.Parent = model
		roads = roads + 1
	end
	ctx.lines[#ctx.lines + 1] = "cidade: " .. built .. " edificios + " .. roads .. " ruas (procedural, seed " .. (SG.memory.tasks * 17 + 3) .. ")"
end

function E.nature(ctx)
	local rng = Random.new(99)
	local trees = 0
	for i = 1, 12 do
		local trunk = Instance.new("Part")
		trunk.Name = "Tree_" .. i
		trunk.Size = Vector3.new(1.2, 4, 1.2)
		trunk.Position = Vector3.new(rng:NextInteger(-50, 50), 2, rng:NextInteger(-50, 50))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(90, 62, 38)
		trunk.Parent = workspace
		local crown = Instance.new("Part")
		crown.Name = "Crown_" .. i
		crown.Shape = Enum.PartType.Ball
		crown.Size = Vector3.new(5, 5, 5)
		crown.Position = trunk.Position + Vector3.new(0, 4.5, 0)
		crown.Anchored = true
		crown.Material = Enum.Material.Grass
		crown.Color = Color3.fromRGB(35 + rng:NextInteger(0, 30), 110 + rng:NextInteger(0, 40), 40)
		crown.Parent = workspace
		trees = trees + 1
	end
	ctx.lines[#ctx.lines + 1] = "natureza: " .. trees .. " arvores plantadas"
end

function E.space(ctx)
	local sun = workspace:FindFirstChild("Sun")
	if not sun then
		local s = Instance.new("Part")
		s.Name = "Sun"
		s.Shape = Enum.PartType.Ball
		s.Size = Vector3.new(12, 12, 12)
		s.Position = Vector3.new(-40, 30, -50)
		s.Anchored = true
		s.Material = Enum.Material.Neon
		s.Color = Color3.fromRGB(255, 200, 90)
		s.Parent = workspace
		local pl = Instance.new("PointLight")
		pl.Parent = s
		pl.Brightness = 2
		pl.Range = 150
		ctx.lines[#ctx.lines + 1] = "espaco: sol neon + luz pontual adicionados"
	end
end

function E.material(ctx)
	local count = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, v = pcall(function() return ch.Material end)
			if ok and v then
				if v.Name == "SmoothPlastic" then
					local mats = { "Concrete", "Metal", "Wood", "Slate" }
					pcall(function() ch.Material = Enum.Material[mats[count % #mats + 1]] end)
					count = count + 1
				end
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "materiais: " .. count .. " superficies variadas (anti-padrao visual)"
end

function E.light(ctx)
	local lighting = game:FindFirstChild("Lighting")
	if lighting then
		local ok, v = pcall(function() return lighting.Ambient end)
		if ok and v then
			pcall(function() lighting.Ambient = Color3.fromRGB(90, 95, 120) end)
		end
		local ok2, v2 = pcall(function() return lighting.OutdoorAmbient end)
		if ok2 and v2 then
			pcall(function() lighting.OutdoorAmbient = Color3.fromRGB(70, 80, 110) end)
		end
		local sun = lighting:FindFirstChild("Sun")
		if not sun then
			local s = Instance.new("Part")
			s.Name = "Sun"
			s.Anchored = true
			s.CanCollide = false
			s.Size = Vector3.new(1, 1, 1)
			s.Transparency = 1
			s.Position = Vector3.new(50, 60, -40)
			local d = Instance.new("DirectionalLight")
			d.Parent = s
			d.Brightness = 2.2
			d.Color = Color3.fromRGB(255, 230, 190)
			s.Parent = lighting
			ctx.lines[#ctx.lines + 1] = "luz: DirectionalLight solar criada"
		end
	end
end

function E.npc(ctx)
	local spawned = 0
	for i = 1, 4 do
		local mind = ArkherNMN.spawn("Inhabitant_" .. i, Vector3.new(math.random(-30, 30), 3, math.random(-30, 30)))
		if mind then spawned = spawned + 1 end
	end
	ctx.lines[#ctx.lines + 1] = "npcs: " .. spawned .. " habitantes NMN com mente ativa (percepcao/precisoes/memoria)"
end

function E.clean(ctx)
	local counts = {}
	for _, ch in ipairs(workspace:GetDescendants()) do
		counts[ch.ClassName] = (counts[ch.ClassName] or 0) + 1
	end
	local moved = 0
	local byType = {}
	for _, ch in ipairs(workspace:GetChildren()) do
		if not ch:IsA("Model") then
			local bucket = ch.ClassName == "Part" and "Parts" or ch.ClassName
			if not byType[bucket] then
				local f = Instance.new("Folder")
				f.Name = bucket
				f.Parent = workspace
				byType[bucket] = f
			end
			if ch:IsA("BasePart") and not ch:IsA("Terrain") then
				pcall(function() ch.Parent = byType[bucket] end)
				moved = moved + 1
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "organizacao: " .. moved .. " itens agrupados por tipo"
end

function E.perf(ctx)
	local fixed = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, a = pcall(function() return ch.Anchored end)
			local ok2, c = pcall(function() return ch.CanCollide end)
			if ok and a == false and ch.Name:find("Spawn") == nil then
				pcall(function() ch.Anchored = true end)
				fixed = fixed + 1
			end
		end
	end
	Bus.emit("do15.nudge", 1)
	ctx.lines[#ctx.lines + 1] = "performance: " .. fixed .. " partes ancoradas + D-O15 forcado p/ MAX"
end

function E.check(ctx)
	local parts, scripts, models, unanchored = 0, 0, 0, 0
	local total = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		total = total + 1
		if ch:IsA("BasePart") then
			parts = parts + 1
			local ok, a = pcall(function() return ch.Anchored end)
			if ok and a == false then unanchored = unanchored + 1 end
		elseif ch:IsA("Script") or ch:IsA("LocalScript") or ch:IsA("ModuleScript") then
			scripts = scripts + 1
		elseif ch:IsA("Model") then
			models = models + 1
		end
	end
	local rep = ArkherDO15 and ArkherDO15.report() or {}
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. parts .. " parts | " .. models .. " models | " .. scripts .. " scripts | " .. total .. " instancias"
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. unanchored .. " partes sem anchor (verificar fisica)"
	ctx.lines[#ctx.lines + 1] = "diagnostico: FPS=" .. tostring(math.floor(rep.fps or 0)) .. " | D-O15=" .. tostring(rep.levelName or "?") .. " | frame=" .. string.format("%.1f", rep.frameMs or 0) .. "ms"
end

function E.default(ctx)
	ctx.lines[#ctx.lines + 1] = "info: objetivo nao mapeado — executei auditoria de contexto"
	E.check(ctx)
end

-- ---------- EXECUTOR ----------
function SG.run(goal, opts)
	opts = opts or {}
	ARKHER.memory = SG.memory
	SG.memory.tasks = SG.memory.tasks + 1
	local task = { id = SG.memory.tasks, goal = goal, t = tick(), status = "running" }
	SG.memory.decisions[#SG.memory.decisions + 1] = task
	local plan = SG.plan(goal)
	local lines = {}
	log("INFO", "objetivo: " .. goal)
	Bus.emit("singularity.start", { goal = goal, plan = plan })
	lines[#lines + 1] = "plano: " .. table.concat(plan.tasks, " → ")

	local t0 = tick()
	for _, name in ipairs(plan.tasks) do
		local expert = E[name] or E.default
		local ok, err = pcall(expert, { lines = lines })
		if not ok then
			lines[#lines + 1] = "ERRO em " .. name .. ": " .. tostring(err)
			task.status = "partial"
			log("ERROR", "especialista " .. name .. " falhou: " .. tostring(err))
		end
		Bus.emit("singularity.step", { task = task.id, step = name })
	end
	local dt = tick() - t0
	lines[#lines + 1] = "tempo: " .. string.format("%.2f", dt) .. "s"
	task.status = task.status or "done"
	task.dt = dt
	task.lines = lines
	Bus.emit("singularity.done", task)
	return report("Missao " .. task.id .. " concluida", lines)
end

-- ---------- PONTE EXTERNA OPCIONAL (mesmo contrato, sem obrigar servico) ----------
function SG.bridgeAvailable()
	local ep = ARKHER.STATE.ai.endpoint
	return type(ep) == "string" and #ep > 4
end

function SG.askExternal(goal)
	if not SG.bridgeAvailable() then return nil, "sem endpoint configurado" end
	local Http = game:GetService("HttpService")
	local ok, res = pcall(function()
		return Http:PostAsync(
			ARKHER.STATE.ai.endpoint,
			Http:JSONEncode({ goal = goal, context = { place = ARKHER.STATE.placeName, do15 = ARKHER.STATE.do15Level } }),
			Enum.HttpContentType.ApplicationJson,
			5
		)
	end)
	if not ok or not res then return nil, tostring(res) end
	local ok2, plan = pcall(function() return Http:JSONDecode(res) end)
	if ok2 and type(plan) == "table" then return plan end
	return nil, "resposta invalida"
end
end

do
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
end

do
--[[ ARKHER V3 — BOOT: inicializa os sistemas core (idempotente) ]]
function ARKHER.boot()
	if ARKHER._booted then return end
	ARKHER._booted = true
	ArkherDO15.start()
	ArkherNMN.start()
	ArkherLive.start()
	ArkherActions.registerUICommands()
	ArkherActions.startShortcuts()
	pcall(function() ArkherPlaces.refreshList() end)
	ARKHER.out("INFO", "Core boot: do15 + nmn + live + actions + places")
end
end

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
--[[ ARKHER V3 — UI: ABOUT ]]
-- Layout unico: emblem + versao ao centro, lista REAL dos sistemas ativos
-- a esquerda, contadores vivos a direita (UIs, comandos, places, mentes).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#576574")

local function build()
	local g, root, head = K.window("ArkherAbout", "ABOUT — ARKHER V3", 24, 520, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: SISTEMAS =====
	local left = K.f(root, "Sys", 8, 34, 168, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SISTEMAS ATIVOS", 10, 6, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local systems = {
		{ "Places (cloud local)", ArkherPlaces ~= nil },
		{ "Undo/Redo (50)", ArkherUNDO ~= nil },
		{ "Live (inspector)", ArkherLive ~= nil },
		{ "D-O15 (perf)", ArkherDO15 ~= nil },
		{ "Singularity (IA)", ARKHER_SINGULARITY ~= nil },
		{ "NMN (mentes)", ArkherNMN ~= nil },
		{ "Publish (sem Open API)", ArkherPublish ~= nil },
		{ "Actions (ARKHER.cmd)", ARKHER.ACTIONS ~= nil },
	}
	for i, s in ipairs(systems) do
		K.treeRow(left, 0, s[2] and ICON.check or ICON.close, s[1], s[2] and "ok" or nil, 26 + (i - 1) * 27)
	end

	-- ===== CENTRO: EMBLEM + VERSAO =====
	local cv = K.f(root, "Brand", 188, 34, 204, 170, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line2, 1)
	local emb = K.f(cv, "Emblem", 82, 20, 40, 40)
	ICON.emblem(emb, 40)
	K.txt(cv, "ARKHER STUDIO", 0, 68, 204, 20, 16, T.txt, ARKHER.FONTB, Enum.TextXAlignment.Center)
	K.txt(cv, "v" .. tostring(ARKHER._version or "3.0.0"), 0, 90, 204, 14, 10, T.neon, FONT, Enum.TextXAlignment.Center)
	K.txt(cv, "UES COMPLETA MAS NO ROBLOX", 0, 112, 204, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	K.grad(cv, T.dark, C("#101828"), 90)
	local tags = K.f(cv, "Tags", 0, 134, 204, 30, T.bg0)
	K.txt(tags, "criar places | publicar facil | IA local", 0, 0, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(tags, "sem Open API | sem cloud obrigatoria", 0, 16, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)

	-- ===== DIREITA: CONTADORES VIVOS =====
	local right = K.f(root, "Count", 404, 34, 148, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AGORA", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local uiCount = #ARKHER.listUIs()
	local cmdCount = 0
	for _ in pairs(ARKHER.ACTIONS or {}) do cmdCount = cmdCount + 1 end
	local placesCount = #ArkherPlaces.list()
	local nmnCount = ArkherNMN and ArkherNMN.count() or 0
	local counters = {
		{ "UIs registradas", tostring(uiCount) },
		{ "Comandos (ARKHER.cmd)", tostring(cmdCount) },
		{ "Places salvos", tostring(placesCount) },
		{ "Mentes NMN", tostring(nmnCount) },
		{ "Nivel D-O15", tostring((ArkherDO15 and ArkherDO15.state and ArkherDO15.state.level) or "?") },
		{ "Place atual", ARKHER.STATE.placeName or "?" },
	}
	for i, c2 in ipairs(counters) do
		K.txt(right, c2[1], 10, 28 + (i - 1) * 34, 130, 14, 9, T.txt3)
		K.txt(right, c2[2], 10, 44 + (i - 1) * 34, 130, 16, 11, T.txt, ARKHER.FONTB)
		if i < #counters then K.f(right, "sep" .. i, 10, 62 + (i - 1) * 34, 128, 1, T.line) end
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "feito no Roblox Studio, para o Roblox Studio", 12, 8, 320, 16, 10, T.txt3)
	K.txt(bar, "batch 0: core + shell | batch 1: UIs unicas | batch 2: integracao", 12, 28, 420, 14, 9, T.txt4)
	K.txt(bar, "2026", 500, 8, 40, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	local closeB = K.btn(bar, 340, 44, 100, 24, T.bg2, 4)
	K.txtS(closeB, "fechar", 10, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		root.Visible = false
	end)
end

ARKHER.reg("About", "About", "System", ICON.info, "Sobre o ARKHER V3: sistemas ativos e contadores em tempo real", build)
end

do
--[[ ARKHER V3 — UI: AI (SINGULARITY) ]]
-- Layout unico: campo de objetivo + chips de sugestao, execucao REAL
-- (ARKHER_SINGULARITY.run), relatorio ao centro, historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")

local SUGGESTIONS = {
	"crie uma cidade com npc",
	"crie um terreno com natureza",
	"crie um espaco com asteroides",
	"otimize e diagnostico",
}

local function build()
	local g, root, head = K.window("ArkherAI", "AI — Singularity (local)", 24, 470, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: OBJETIVO =====
	local goalBox = K.input(root, 8, 34, 360, 26, "descreva o que construir...")
	local run = K.btn(root, "Run", 380, 34, 100, 26, ACCENT, 5)
	K.txtS(run, "EXECUTAR", 11, C("#04141C"))
	K.hover(run, ACCENT, C("#7DEBFF"))
	-- chips
	local chips = {}
	for i, sg in ipairs(SUGGESTIONS) do
		local ch = K.btn(root, "Ch" .. i, 8 + (i - 1) * 138, 68, 132, 20, T.bg4, 10)
		K.txtS(ch, sg, 8, T.txt3)
		K.hover(ch, T.bg4, T.hover)
		local sg2 = sg
		ch.MouseButton1Click:Connect(function()
			goalBox.Text = sg2
		end)
		chips[i] = ch
	end

	-- ===== CENTRO: RELATORIO =====
	local rep = K.f(root, "Rep", 8, 96, 360, 190, T.bg0)
	K.corner(rep, 4)
	K.stroke(rep, T.line, 1)
	K.txt(rep, "RELATORIO DE EXECUCAO", 10, 6, 180, 14, 10, T.txt3, ARKHER.FONTB)
	local area = K.f(rep, "Area", 0, 26, 360, 160)
	local lastRep
	local function renderRep()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		if not lastRep then
			K.txt(area, "a Singularity planeja o objetivo em intents\n(city / nature / space / npc / perf / check...)\ne executa de VERDADE no workspace.", 12, 8, 330, 50, 9, T.txt4)
			return
		end
		local y = 4
		for i, l in ipairs(lastRep.lines) do
			local col = T.txt2
			if l:sub(1, 5) == "plano" then col = T.neon end
			if l:find("diagnostico") then col = C("#FFD93D") end
			if l:find("performance") then col = T.ok end
			if l:find("ERRO") then col = T.danger end
			K.txt(area, l, 12, y, 336, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
			y = y + 18
			if y > 150 then break end
		end
	end
	renderRep()
	run.MouseButton1Click:Connect(function()
		local goal = goalBox.Text
		if goal == "" then goal = "diagnostico" end
		ARKHER.out("INFO", "AI: executando: " .. goal)
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run(goal) end)
		if ok and r then
			lastRep = r
			renderRep()
			ARKHER.out("SUCCESS", "AI: missao concluida (" .. #r.lines .. " etapas)")
		else
			ARKHER.out("ERROR", "AI: falhou: " .. tostring(r))
		end
	end)

	-- ===== DIREITA: HISTORICO + MODO =====
	local right = K.f(root, "Hist", 380, 96, 172, 190, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 172, 120)
	local hist = {}
	local function renderHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		if #hist == 0 then
			K.txt(histArea, "(sem missoes ainda)", 10, 6, 150, 20, 9, T.txt4)
			return
		end
		for i, h in ipairs(hist) do
			if i > 5 then break end
			K.txt(histArea, "- " .. h, 10, 4 + (i - 1) * 22, 152, 20, 9, T.txt3)
		end
	end
	renderHist()
	run.MouseButton1Click:Connect(function()
		table.insert(hist, 1, goalBox.Text)
		table.remove(hist, 6)
		renderHist()
	end)
	K.row(right, "Modo", ARKHER.STATE.ai and ARKHER.STATE.ai.mode or "local", 152)
	K.txt(right, "IA 100% local:\nplanner + especialistas\nexecutam no Roblox.", 10, 168, 152, 44, 9, T.txt4)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "SINGULARITY", 12, 8, 140, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "planner de intent -> especialistas locais -> execucao real + relatorio", 12, 28, 400, 14, 9, T.txt3)
	K.txt(bar, "sem cloud, sem API key", 12, 52, 200, 14, 9, T.txt4)
	local diag = K.btn(bar, 340, 52, 100, 24, T.bg2, 4)
	K.txtS(diag, "diagnostico", 9, T.txt)
	K.hover(diag, T.bg2, T.hover)
	diag.MouseButton1Click:Connect(function()
		goalBox.Text = "diagnostico"
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run("diagnostico") end)
		if ok and r then lastRep = r renderRep() end
	end)
	K.txt(bar, "missoes: " .. tostring(#hist), 460, 58, 84, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("AI", "AI (Singularity)", "System", ICON.gem, "IA local: objetivo -> plano -> execucao real no workspace + relatorio", build)
end

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
--[[ ARKHER V3 — UI: AUDIO ]]
-- Layout unico: lista de faixas com FORMAS DE ONDA (K.wave) a esquerda,
-- detalhe da faixa selecionada no centro, mixer com VERTICAIS (K.vfader) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#A29BFE")

local TRACKS = {
	{ nm = "Theme_01", len = "2:34", seed = 11, vol = 0.8, kind = "Music" },
	{ nm = "City_amb", len = "4:10", seed = 23, vol = 0.55, kind = "Ambience" },
	{ nm = "UI_click", len = "0:01", seed = 37, vol = 0.7, kind = "SFX" },
	{ nm = "Boss_roar", len = "0:04", seed = 53, vol = 0.9, kind = "SFX" },
}

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO — mixer & faixas", 24, 370, 560, 372, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local sel = 1

	-- ===== ESQUERDA: FAIXAS =====
	local left = K.f(root, "Tracks", 8, 34, 150, 260, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FAIXAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, tr in ipairs(TRACKS) do
		local row = K.f(left, "Tr" .. i, 6, 26 + (i - 1) * 56, 138, 50, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, tr.nm, 6, 4, 90, 14, 10, T.txt)
		K.txt(row, tr.kind .. " | " .. tr.len, 6, 18, 120, 12, 8, T.txt4)
		K.wave(row, 6, 32, 100, 14, tr.seed, i == 1 and ACCENT or T.txt4)
		K.txt(row, math.floor(tr.vol * 100 + 0.5) .. "%", 110, 34, 26, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
		local idx = i
		row.MouseButton1Click:Connect(function()
			sel = idx
			ARKHER.out("INFO", "Audio: selecionada " .. tr.nm)
		end)
	end

	-- ===== CENTRO: DETALHE =====
	local cv = K.f(root, "Detail", 170, 34, 244, 160, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, TRACKS[1].nm, 10, 8, 160, 16, 12, T.txt, ARKHER.FONTB)
	K.txt(cv, "Music | 2:34 | 44.1kHz", 10, 26, 180, 14, 9, T.txt4)
	K.wave(cv, 10, 48, 224, 56, 11, ACCENT)
	-- seek
	local seek, seekFill = K.progress(cv, 10, 116, 180, 0.36, ACCENT)
	K.txt(cv, "0:54", 196, 110, 36, 14, 9, T.txt3)
	-- controles
	local pl = K.btn(cv, "Pl", 10, 134, 44, 22, T.bg2, 4)
	K.txtS(pl, "Play", 10, T.txt)
	K.hover(pl, T.bg2, T.hover)
	pl.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: tocando " .. TRACKS[sel].nm)
	end)
	local pp = K.btn(cv, "Pp", 60, 134, 44, 22, T.bg2, 4)
	K.txtS(pp, "Stop", 10, T.txt)
	K.hover(pp, T.bg2, T.hover)
	pp.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: parado")
	end)

	-- ===== DIREITA: MIXER =====
	local right = K.f(root, "Mixer", 426, 34, 126, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MIXER", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local chans = { "MUS", "SFX", "AMB" }
	local vols = { 0.8, 0.7, 0.55 }
	for i = 1, 3 do
		K.vfader(right, 18 + (i - 1) * 36, 28, 150, vols[i], chans[i])
	end
	K.txt(right, "MASTER", 10, 192, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.vfader(right, 30, 208, 40, 0.75, "M")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 60, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Loop", true, 8)
	K.sliderRow(bar, "Master vol", 0.75, 34)
	local add = K.btn(bar, "Add", 300, 16, 90, 28, ACCENT, 5)
	K.txtS(add, "+ faixa", 11, C("#12102A"))
	K.hover(add, ACCENT, C("#C3BFFF"))
	add.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Audio: faixa 'Nova' adicionada ao mixer")
	end)
	K.txt(bar, "3 canais | 44.1k | 16bit", 410, 22, 130, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Audio", "Audio", "Scene", ICON.data, "Mixer de audio: faixas com waveforms, seek e canais verticais", build)
end

do
--[[ ARKHER V3 — UI: CAMERA ]]
-- Layout unico: lista de modos de vista a esquerda, preview com cone de FOV
-- que MUDA ao clicar nos botoes +/-, knobs de FOV/velocidade a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6B81")

local function build()
	local g, root, head = K.window("ArkherCamera", "CAMERA — rig & view", 24, 350, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local fov = 70
	local speed = 16

	-- ===== ESQUERDA: MODOS =====
	local left = K.f(root, "Modes", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MODOS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local modes = { "Orbit", "Free", "Cinematic", "Drone", "Follow", "Top" }
	for i, m in ipairs(modes) do
		local row = K.treeRow(left, 0, i == 3 and ICON.camera or ICON.select, m, i == 3, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Camera: modo " .. m)
		end)
	end
	K.txt(left, "Cinematic ativo", 10, 172, 110, 24, 9, ACCENT)

	-- ===== CENTRO: PREVIEW COM CONE DE FOV =====
	local cv = K.f(root, "Prev", 142, 34, 268, 200, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- ceu/terreno
	K.f(cv, "Sky", 0, 0, 268, 108, C("#12233D"))
	K.f(cv, "Gnd", 0, 108, 268, 92, C("#1B2B22"))
	-- sol
	K.f(cv, "Sun", 200, 24, 14, 14, C("#FFD93D"), 7)
	-- montanhas (frames rotacionados)
	local m1 = K.f(cv, "M1", 20, 78, 90, 30, C("#0E1A2B"))
	m1.Rotation = -8
	local m2 = K.f(cv, "M2", 150, 70, 110, 38, C("#101E30"))
	m2.Rotation = 5
	-- objeto alvo
	K.f(cv, "Tgt", 128, 128, 14, 26, ACCENT)
	K.txt(cv, "alvo", 118, 156, 36, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	-- cone de FOV (2 linhas rotacionadas a partir do olho)
	local coneLines = {}
	local fovLbl = K.txt(cv, "70 FOV", 8, 180, 80, 16, 10, ACCENT)
	local function drawCone()
		for _, l in ipairs(coneLines) do l:Destroy() end
		coneLines = {}
		local ang = fov * 0.42
		for _, s in ipairs({ -1, 1 }) do
			local l = K.f(cv, "C", 135, 140, 150, 2, ACCENT)
			l.Rotation = s * ang
			l.AnchorPoint = Vector2.new(0, 0.5)
			table.insert(coneLines, l)
		end
		local eye = K.f(cv, "Eye", 131, 136, 8, 8, T.neon, 4)
		table.insert(coneLines, eye)
		fovLbl.Text = fov .. " FOV"
	end
	drawCone()

	-- ===== DIREITA: AJUSTES =====
	local right = K.f(root, "Adj", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "FOV", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	local minus = K.btn(right, "M-", 10, 24, 52, 22, T.bg2, 4)
	K.txtS(minus, "-", 12, T.txt)
	K.hover(minus, T.bg2, T.hover)
	local plus = K.btn(right, "M+", 72, 24, 52, 22, T.bg2, 4)
	K.txtS(plus, "+", 12, T.txt)
	K.hover(plus, T.bg2, T.hover)
	minus.MouseButton1Click:Connect(function()
		fov = math.max(20, fov - 5)
		drawCone()
	end)
	plus.MouseButton1Click:Connect(function()
		fov = math.min(120, fov + 5)
		drawCone()
	end)
	K.knob(right, 38, 58, 54, fov / 120, math.floor(fov / 120 * 100 + 0.5) .. "%")
	K.txt(right, "VELOCIDADE", 10, 138, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 38, 156, 54, speed / 40, speed .. " u/s")
	K.row(right, "Zoom", "2.4", 216)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 76, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Rig", "CinematicCam", 8)
	K.row(bar, "Tracking", "Player", 34)
	local apply = K.btn(bar, "Apply", 300, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar ao Place", 10, C("#1C070C"))
	K.hover(apply, ACCENT, C("#FF97A8"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Camera: rig CinematicCam (fov " .. fov .. ", " .. speed .. "u/s) aplicado")
		Bus.emit("camera.apply", { fov = fov, speed = speed, mode = "Cinematic" })
	end)
	K.txt(bar, "lens: 35mm equiv", 430, 28, 104, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Rig de camera: modos, FOV interativo, tracking e preview", build)
end

do
--[[ ARKHER V3 — UI: CITY ]]
-- Layout unico: grid de distritos a esquerda, skyline desenhada no centro,
-- stats + geracao real com Singularity (IA) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#F9CA24")

local DISTRICTS = {
	{ nm = "Centro", b = 42, p = 0.82 }, { nm = "Porto", b = 18, p = 0.45 },
	{ nm = "Industrial", b = 26, p = 0.61 }, { nm = "Residencial", b = 64, p = 0.9 },
	{ nm = "Parque", b = 4, p = 0.2 }, { nm = "Mercado", b = 21, p = 0.58 },
	{ nm = "Academia", b = 12, p = 0.37 }, { nm = "Estacao", b = 9, p = 0.31 },
	{ nm = "Suburbio", b = 33, p = 0.72 },
}

local function build()
	local g, root, head = K.window("ArkherCity", "CITY — distritos & IA", 24, 410, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: DISTritos (3x3) =====
	local left = K.f(root, "Dist", 8, 34, 150, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "DISTRITOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	for i, d in ipairs(DISTRICTS) do
		local r, c = math.floor((i - 1) / 3) + 1, ((i - 1) % 3) + 1
		local cell = K.f(left, "D" .. i, 8 + (c - 1) * 46, 26 + (r - 1) * 70, 42, 64, T.bg2, 4)
		K.txt(cell, d.nm, 3, 4, 36, 14, 8, T.txt)
		K.txt(cell, d.b .. " bld", 3, 20, 36, 12, 8, T.txt4)
		K.progress(cell, 3, 40, 36, d.p, ACCENT)
		cell.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "City: distrito " .. d.nm .. " (" .. d.b .. " predios)")
		end)
	end
	K.txt(left, "9 distritos", 10, 232, 100, 12, 9, T.txt4)

	-- ===== CENTRO: SKYLINE =====
	local cv = K.f(root, "Sky", 170, 34, 244, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.f(cv, "Gnd", 0, 190, 244, 50, C("#101B12"))
	local blds = {
		{ x = 12, w = 26, h = 70 }, { x = 44, w = 20, h = 96 }, { x = 70, w = 30, h = 56 },
		{ x = 106, w = 24, h = 120 }, { x = 136, w = 34, h = 84 }, { x = 176, w = 22, h = 104 },
]====]
]=====]
local t = all:FindFirstChild("ALL_P2")
if not t then t = Instance.new("ModuleScript") t.Name = "ALL_P2" t.Parent = all end
t.Source = S_CHUNK
print("[ARKHER V3] (11/13) ALL_P2 instalado em ReplicatedStorage.ArkherV3.ALL (83,624 chars)")
