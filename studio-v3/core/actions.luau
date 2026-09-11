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

-- ================= TERRAIN X (custom, ArkherTerrainX) =================
local function txWorld(preset, seed)
	if not ArkherTerrainX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._world = ArkherTerrainX.new({ seed = seed or 1337, preset = preset or "continentes", cell = 8 })
	return ARKHER._world
end
A["terrain.generate"] = function(preset, seed)
	local w, err = txWorld(preset, seed)
	if not w then ARKHER.out("WARNING", "terrain.generate: " .. err) return end
	local res = w:materializeRegion(-96, -96, 192, 192, {})
	ARKHER.out("SUCCESS", "terrain.generate: preset '" .. w.preset .. "' seed " .. w.seed .. " → " .. res.parts .. " parts em " .. res.chunks .. " chunks")
end
A["terrain.erode"] = function(iters)
	if not ARKHER._world then txWorld() end
	local w = ARKHER._world
	if not w then ARKHER.out("WARNING", "terrain.erode: sem mundo ATX") return end
	local r = w:erodeHydraulic(1, 1, 48, 32, iters or 3000)
	ARKHER.out("SUCCESS", "terrain.erode: " .. (iters or 3000) .. " gotas | dMedio " .. string.format("%.3f", r.meanDelta))
end
A["terrain.rivers"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:carveRivers(1, 1, 48, 32, 20)
	ARKHER.out("SUCCESS", "terrain.rivers: " .. r.cells .. " celulas fluviais (acum. max " .. r.maxAcc .. ")")
end
A["terrain.lakes"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:fillLakes(1, 1, 48, 32)
	ARKHER.out("SUCCESS", "terrain.lakes: " .. r.cells .. " celulas de lago")
end
A["terrain.materialize"] = function(span)
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	span = span or 192
	local res = ARKHER._world:materializeRegion(-span / 2, -span / 2, span, span, {})
	ARKHER.out("SUCCESS", "terrain.materialize: " .. span .. "x" .. span .. " → " .. res.parts .. " parts (LOD D-O15)")
end
A["terrain.lod"] = function(fx, fz)
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.lod: sem mundo ATX") return end
	local r = ARKHER._world:updateLOD(fx or 0, fz or 0)
	ARKHER.out("INFO", "terrain.lod: " .. r.updated .. " chunks re-materializados adaptativamente")
end
A["terrain.clear"] = function()
	if ARKHER._world then ArkherTerrainX.clearWorld(ARKHER._world) end
	ARKHER.out("SUCCESS", "terrain.clear: ATX_World removido")
end
A["terrain.export"] = function()
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.export: sem mundo ATX") return end
	local str, path, ok = ARKHER._world:exportFile()
	ARKHER.out("SUCCESS", "terrain.export: " .. #str .. " chars → " .. path .. (ok and "" or " (string retornada)"))
end

-- ================= WATER X (custom, ArkherWaterX) =================
local function wxSea(preset)
	if not ArkherWaterX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._sea = ArkherWaterX.preset(preset or "porto", { kind = "oceano", level = 0, size = { x = 420, z = 320 } })
	return ARKHER._sea
end
A["water.ocean"] = function(preset)
	local sea, err = wxSea(preset)
	if not sea then ARKHER.out("WARNING", "water.ocean: " .. err) return end
	local _, n = ArkherWaterX.materialize(sea, { maxSpan = 420 })
	ARKHER.out("SUCCESS", "water.ocean: preset '" .. (preset or "porto") .. "' → " .. n .. " tiles animadas de Gerstner")
end
A["water.caustics"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local n = ArkherWaterX.caustics(ARKHER._sea, ARKHER._sea.level - 9)
	ARKHER.out("SUCCESS", "water.caustics: " .. n .. " brilhos")
end
A["water.float"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then
		for _, inst in ipairs(sel) do
			if inst:IsA("BasePart") then ArkherWaterX.float(ARKHER._sea, inst, {}) n = n + 1 end
		end
	end
	ARKHER.out("SUCCESS", "water.float: flutuabilidade arquimediana em " .. n .. " parts")
end
A["water.underwater"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	ARKHER._underwater = not ARKHER._underwater
	ArkherWaterX.applyUnderwater(ARKHER._sea, ARKHER._underwater)
	ARKHER.out("INFO", "water.underwater: " .. (ARKHER._underwater and "ON" or "OFF"))
end
A["water.splash"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	if not ARKHER._sea.tiles then ArkherWaterX.materialize(ARKHER._sea, { maxSpan = 240 }) end
	ArkherWaterX.splash(ARKHER._sea, 0, ARKHER._sea:heightAt(0, 0, 0), 0, 2)
	ARKHER.out("SUCCESS", "water.splash emitido")
end

-- ================= SCRIPT X (IDE) =================
A["script.new"] = function(name, templateId)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.new: Kit D nao carregado") return end
	name = name or "NovoScript"
	local tp = templateId and ArkherScripterX.template(templateId) or ArkherScripterX.template("basico")
	local sc = Instance.new(tp.cls)
	sc.Name = name
	sc.Source = tp.src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.new: " .. tp.cls .. " '" .. name .. "' (template " .. tp.id .. ") criado no workspace")
end
A["script.newfromgoal"] = function(goal)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.newfromgoal: Kit D nao carregado") return end
	local src, id2 = ArkherScripterX.compose(goal or "basico")
	local sc = Instance.new("Script")
	sc.Name = "IA_" .. id2
	sc.Source = src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.newfromgoal: template '" .. id2 .. "' composto p/ '" .. tostring(goal) .. "'")
end
A["script.lintreport"] = function()
	if not ArkherScripterX then return end
	local sel2 = sel()
	if not (sel2 and sel2:IsA("LuaSourceContainer")) then
		ARKHER.out("INFO", "script.lintreport: selecione um Script no explorer")
		return
	end
	local diags = ArkherScripterX.lint(sel2.Source or "")
	local sum = ArkherScripterX.lintSummary(diags)
	ARKHER.out("INFO", "lint " .. sel2.Name .. ": " .. sum.errors .. " err, " .. sum.warns .. " warn, " .. sum.infos .. " info")
end

-- ================= UI KIT X =================
A["uix.hud"] = function()
	if not ArkherUIKitX then ARKHER.out("WARNING", "uix.hud: Kit D nao carregado") return end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("timer", { x = 850, y = 16, text = "10:00" }),
		X.create("coins", { x = 16, y = 52, text = "1.0K" }),
	}
	local gui, n = X.build(widgets, "ArkherHUD")
	ARKHER.out("SUCCESS", "uix.hud: " .. n .. " widgets no StarterGui.ArkherHUD")
end
A["uix.theme"] = function(id)
	if ArkherUIKitX then ArkherUIKitX.setTheme(id or "arkher") ARKHER.out("INFO", "uix.theme: " .. (id or "arkher")) end
end

-- ================= ANIMATION X (AAX) =================
A["anim.demo"] = function()
	if not ArkherAnimX then ARKHER.out("WARNING", "anim.demo: Kit E nao carregado (ArkherKit_Installer_E)") return end
	local AX = ArkherAnimX
	local ws = workspace
	local p = Instance.new("Part")
	p.Name = "AAX_DemoCube"
	p.Size = Vector3.new(2, 2, 2)
	p.Anchored = true
	p.Color = Color3.fromRGB(255, 170, 60)
	p.CFrame = CFrame.new(0, 4, 0)
	p.Parent = ws
	local c = AX.clip("DemoCube", { loop = "pingpong" })
	c:addTrack("Position", { AX.key(0, { x = 0, y = 4, z = 0 }, "easeInOut_sine"), AX.key(1.2, { x = 0.4, y = 7.2, z = 0 }, "easeOut_spring"), AX.key(2.4, { x = 0, y = 4, z = 0 }, "easeInOut_sine") })
	c:addTrack("Transparency", { AX.key(0, 0.5, "linear"), AX.key(1.2, 0, "easeOut_sine"), AX.key(2.4, 0.5, "linear") })
	c:marker(1.2, "pico")
	c:bind(p, {})
	c:play({ from = 0 })
	ARKHER._animDemo = c
	ARKHER.out("SUCCESS", "anim.demo: cube no workspace tocando (easeOut_spring + pingpong)")
end
A["anim.pump"] = function(dt)
	if ArkherAnimX then
		local n = ArkherAnimX.pump(dt or 0.016)
		ArkherAnimX.pumpDeformers(dt or 0.016)
		ARKHER.out("INFO", "anim.pump: " .. n .. " clips vivos")
	end
end
A["anim.stopall"] = function()
	if ArkherAnimX then ArkherAnimX.stopAll() ARKHER.out("SUCCESS", "anim.stopall executado") end
end
A["anim.wave"] = function()
	if not ArkherAnimX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and sel and #sel >= 1 then
		local asm = ArkherAnimX.assemble(sel)
		ARKHER._deform = ArkherAnimX.deform(asm, ArkherAnimX.DEFORMERS.wave(1.2, 14, 2.2), {})
		ARKHER.out("SUCCESS", "anim.wave: deformer ondulando " .. #sel .. " parts (assembly)")
	else
		ARKHER.out("INFO", "anim.wave: selecione parts")
	end
end

-- ================= AUDIO X (AUX) =================
A["audio.setup"] = function()
	if not ArkherAudioX then ARKHER.out("WARNING", "audio.*: Kit E nao carregado") return end
	ArkherAudioX.setup()
	local st = ArkherAudioX.stats()
	ARKHER.out("SUCCESS", "audio.setup: " .. st.buses .. " buses SoundGroup criadas no SoundService")
end
A["audio.duckdemo"] = function()
	if not ArkherAudioX then return end
	ArkherAudioX.setup()
	ArkherAudioX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.register("voice_demo", { bus = "voice", volume = 0.6 })
	ArkherAudioX.duck("music", "voice", { level = 0.3 })
	ArkherAudioX.play("musica_demo")
	ArkherAudioX.play("voice_demo")
	ARKHER.out("SUCCESS", "audio.duckdemo: musica ducked p/ 30% quando a voz toca (sidechain)")
end
A["audio.patch"] = function(bus, preset)
	if not ArkherAudioX then return end
	local ok, n = ArkherAudioX.patch(bus or "music", preset or "caverna")
	ARKHER.out(ok and "SUCCESS" or "WARNING", "audio.patch: " .. (preset or "caverna") .. " → " .. tostring(n))
end

-- ================= SCENE / SCATTER X (ASXN) =================
A["scene.forest"] = function(radius)
	if not ArkherSceneX then ARKHER.out("WARNING", "scene.*: Kit E nao carregado") return end
	local w = ARKHER._world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
	ARKHER._world = w
	local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = radius or 90, count = 70, minDist = 6, maxSlope = 0.9, world = w, seed = 777, name = "ASXN_Forest" })
	ARKHER.out("SUCCESS", "scene.forest: " .. res.count .. " arvores/arbustos/grama no mundo (biomas Whittaker)")
end
A["scene.patina"] = function()
	if not ArkherSceneX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then n = ArkherSceneX.patina(sel, {}) end
	ARKHER.out("SUCCESS", "scene.patina: variacao anti-CG em " .. n .. " parts")
end
A["scene.query"] = function(cls)
	if not ArkherSceneX then return end
	local list = ArkherSceneX.query({ class = cls or "Part" })
	ARKHER.out("INFO", "scene.query '" .. (cls or "Part") .. "' → " .. #list .. " resultados")
end
A["scene.rehash"] = function()
	if ArkherSceneX then
		local n = ArkherSceneX.rehash()
		ARKHER.out("SUCCESS", "scene.rehash: " .. n .. " parts no spatial hash")
	end
end
A["scene.lod"] = function()
	if ArkherSceneX then
		local r = ArkherSceneX.applyLOD(0, 0)
		ARKHER.out("INFO", "scene.lod: " .. r.shown .. " visiveis, " .. r.ghosts .. " ghosts, " .. r.culled .. " culled")
	end
end

-- ================= ATMOS X (ceu + clima custom) =================
A["atmos.setup"] = function()
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.setup({})
	ARKHER.out("SUCCESS", "atmos.setup: Lighting real vinculado (Atmosphere + ColorCorrection)")
end
A["atmos.preset"] = function(name)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "meiodia"
	if ArkherAtmosX.setPreset(name) then
		ArkherAtmosX.apply({})
		ARKHER.out("SUCCESS", "atmos.preset: " .. name .. " (Kelvin real aplicado ao Lighting)")
	else
		ARKHER.out("ERROR", "atmos.preset desconhecido: " .. name)
	end
end
A["atmos.weather"] = function(name, speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "limpo"
	if ArkherAtmosX.setWeather(name, speedo or 0.6) then
		for i = 1, 90 do ArkherAtmosX.pump(1 / 30) end
		ARKHER.out("SUCCESS", "atmos.weather: " .. name .. " (transicao completa, links AWX/AUX aplicados)")
	else
		ARKHER.out("ERROR", "atmos.weather desconhecido: " .. name)
	end
end
A["atmos.cycle"] = function(speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.S.cycleSpeed = speedo or 0.2
	ARKHER.out("INFO", "atmos.cycle: velocidade do ciclo solar = " .. tostring(ArkherAtmosX.S.cycleSpeed) .. " h/s")
end

-- ================= CAMERA X (cinematografia custom) =================
A["cam.orbit"] = function(radius, height, seconds)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = radius or 14, height = height or 6, speed = 0.6, duration = 9999 })
	ARKHER.out("SUCCESS", "cam.orbit: camera orbitando (raio " .. (radius or 14) .. " m)")
end
A["cam.crane"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
	ARKHER.out("SUCCESS", "cam.crane: movimento crane 4s com lift")
end
A["cam.fly"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
	ARKHER.out("SUCCESS", "cam.fly: trajetoria Catmull-Rom 3D real (5s)")
end
A["cam.shake"] = function(t)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.addTrauma(t or 0.8)
	ARKHER.out("INFO", "cam.shake: trauma +" .. (t or 0.8) .. " (amplitude trauma^2 real)")
end
A["cam.fade"] = function(to)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.fade(to or -1, 0.8)
	ARKHER.out("SUCCESS", "cam.fade: ColorCorrection real -> brightness " .. tostring(to or -1))
end
A["cam.cinema"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.cinema({
		{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 },
		{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
		{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
	})
	ARKHER.out("SUCCESS", "cam.cinema: sequencia de 3 cortes reais iniciada")
end
A["cam.stop"] = function() if ArkherCameraX then ArkherCameraX.stop() ARKHER.out("INFO", "cam.stop") end end

-- ================= PARTICLES X (emissores custom) =================
A["px.emit"] = function(kind)
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	kind = kind or "fogo"
	local pe = ArkherParticlesX.emit(nil, kind)
	ARKHER.out("SUCCESS", "px.emit: " .. kind .. " (ParticleEmitter real, budget D-O15 aplicado)")
	return pe
end
A["px.demo"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	local kinds = { "fogo", "fumaca", "magia" }
	for _, k in ipairs(kinds) do ArkherParticlesX.emit(nil, k) end
	ARKHER.out("SUCCESS", "px.demo: fogo + fumaca + magia emitidos")
end
A["px.clear"] = function()
	if ArkherParticlesX then ArkherParticlesX.clear() ARKHER.out("INFO", "px.clear: todos desligados") end
end
A["px.storm"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	if ArkherAtmosX then ArkherAtmosX.setup({}) ArkherAtmosX.setWeather("tempestade", 1.2) end
	ArkherParticlesX.emit(nil, "chuva", { rate = 240, speed = 40 })
	ARKHER.out("SUCCESS", "px.storm: chuva fisica + ATX... AEX tempestade (onda awx no pump)")
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
