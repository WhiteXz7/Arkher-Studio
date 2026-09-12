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
	terrain = { "terreno", "terrain", "relief", "relevo", "heightmap", "erosao", "erosão", "rio", "rios", "river", "geologia", "canyon", "vulcao", "vulcão", "ilha", "ilhas", "vale", "bioma", "biomas", "continente", "geography" },
	water = { "agua", "água", "water", "oceano", "ocean", "mar", "sea", "onda", "ondas", "wave", "waves", "cachoeira", "waterfall", "lagoa", "tsunami", "rio2", "piscina", "pool" },
	ui = { "hud", "ui", "interface", "gui", "menu", "barra de vida", "lifetime", "hotbar", "inventario", "inventário", "placar", "leaderboard" },
	audio = { "som", "audio", "musica", "music", "sound", "trilha", "soundtrack", "barulho", "mixer", "reverb", "acustica", "acústica" },
	anim = { "animacao", "animação", "anim", "animation", "mover", "movimento", "dancar", "dançar", "timeline", "keyframe" },
	clima = { "clima", "weather", "chuva", "rain", "tempestade", "storm", "neve", "snow", "neblina", "fog", "aurora", "trovao", "trovão", "raio", "lightning", "ensolarado", "ceu", "céu", "sky" },
	camera = { "camera", "câmera", "filme", "film", "cinematic", "cinematica", "cinematográfica", "orbita", "orbit", "crane", "dolly", "shake", "tremor", "fly", "corte", "shot" },
	particles = { "particulas", "partículas", "particles", "fogo", "fire", "faisca", "faísca", "sparks", "magia", "magic", "explosao", "explosão", "fumaca", "fumaça", "smoke", "splash", "poeira", "dust" },
	cloth = { "pano", "tecido", "cloth", "corda", "rope", "bandeira", "flag", "cabelo", "hair", "bandame", "banner", "tenda", "drapeando", "pendurada" },
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
	local order = { "place", "terrain", "water", "city", "nature", "space", "material", "light", "npc", "ui", "audio", "anim", "clima", "particles", "cloth", "camera", "clean", "perf", "check" }
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
	-- V4: se o Scene/Scatter X esta carregado, o "natureza" vira povoamento
	-- REAL por bioma/declive no ATX (arvores com dossel organico, arbustos, etc)
	if ArkherSceneX then
		local w = SG.world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
		SG.world = SG.world or w
		local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = 110, count = 60, minDist = 7, maxSlope = 0.9, world = w, seed = 99 + SG.memory.tasks, name = "ASXN_Nature" })
		local trees, bushes = 0, 0
		for _, m in ipairs(res.made or {}) do
			local tg = m:GetAttribute("arkher_tag")
			if tg == "tree" then trees = trees + 1 elseif tg == "bush" then bushes = bushes + 1 end
		end
		ctx.lines[#ctx.lines + 1] = "natureza SCATTER: " .. res.count .. " entidades (" .. trees .. " arvores dossel-organico, " .. bushes .. " arbustos — " .. res.tries .. " amostras poisson)"
		return
	end
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

function E.terrain(ctx)
	if not ArkherTerrainX then
		ctx.lines[#ctx.lines + 1] = "terreno: Kit C (ATX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local TX = ArkherTerrainX
	local seed = 1000 + SG.memory.tasks * 137
	local w = TX.new({ seed = seed, preset = "continentes", cell = 8 })
	local hyd = w:erodeHydraulic(1, 1, 48, 32, 2200)
	local riv = w:carveRivers(1, 1, 48, 32, 20)
	w:fillLakes(1, 1, 48, 32)
	local built = w:materializeRegion(-96, -96, 192, 192, {})
	local biomes = w:biomeCounts()
	local nb = 0
	for _ in pairs(biomes) do nb = nb + 1 end
	SG.world = w
	ctx.lines[#ctx.lines + 1] = "terreno ATX: mundo procedural seed " .. seed .. " (erosao " .. string.format("%.3f", hyd.meanDelta) .. " dMedio/" .. string.format("%.1f", hyd.maxDelta) .. " dMax)"
	ctx.lines[#ctx.lines + 1] = "terreno ATX: rios " .. riv.cells .. " celulas | " .. nb .. " biomas Whittaker | " .. built.parts .. " parts em " .. built.chunks .. " chunks (materializacao real)"
end

function E.water(ctx)
	if not ArkherWaterX then
		ctx.lines[#ctx.lines + 1] = "agua: Kit C (AWX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local WX = ArkherWaterX
	local sea = WX.preset("porto", { kind = "oceano", level = (SG.world and SG.world.seaLevel) or 0, size = { x = 420, z = 320 } })
	sea.foaminess = 0.55
	local model, tiles = WX.materialize(sea, { maxSpan = 420 })
	local cau = WX.caustics(sea, sea.level - 9)
	SG.sea = sea
	ctx.lines[#ctx.lines + 1] = "agua AWX: oceano preset 'porto' — " .. #sea.waves .. " ondas Gerstner (dispersao omega=sqrt(gk)), mare, correntes Stokes"
	ctx.lines[#ctx.lines + 1] = "agua AWX: " .. tiles .. " tiles animadas + " .. cau .. " causticas | dens " .. sea.props.dens .. " | salinidade " .. sea.props.sal .. " g/L"
end

function E.ui(ctx)
	if not ArkherUIKitX then
		ctx.lines[#ctx.lines + 1] = "hud: Kit D (AXI) nao carregado — rode ArkherKit_Installer_D"
		return
	end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("stamina", { x = 16, y = 48, value = 0.7 }),
		X.create("xpbar", { x = 16, y = 70, value = 0.35 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("coins", { x = 16, y = 100, text = "8.2K" }),
		X.create("timer", { x = 850, y = 16, text = "09:41" }),
		X.create("minimap", { x = 790, y = 60 }),
		X.create("questtracker", { x = 690, y = 230 }),
	}
	local gui, n = X.build(widgets, "ArkherHUD_AI")
	ctx.lines[#ctx.lines + 1] = "hud AXI: " .. n .. " widgets montados no StarterGui.ArkherHUD_AI (health/stamina/xp/hotbar/coins/timer/minimap/quest)"
end

function E.audio(ctx)
	if not ArkherAudioX then
		ctx.lines[#ctx.lines + 1] = "audio: Kit E (AUX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AX = ArkherAudioX
	AX.setup()
	AX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	AX.register("voice_demo", { bus = "voice", volume = 0.6 })
	AX.duck("music", "voice", { level = 0.3 })
	AX.play("musica_demo")
	AX.play("voice_demo")
	AX.patch("music", "estudio")
	AX.ambient("floresta", { ids = { "passaros", "folhas", "rio_longe" }, interval = { 10, 24 }, bus = "ambient" })
	AX._ambients.floresta:start()
	local st = AX.stats()
	ctx.lines[#ctx.lines + 1] = "audio AUX: " .. st.buses .. " buses + duck voz->musica + patch estudio + scheduler floresta ON (" .. st.sounds .. " sons)"
end

function E.anim(ctx)
	if not ArkherAnimX then
		ctx.lines[#ctx.lines + 1] = "animacao: Kit E (AAX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	ARKHER.cmd("anim.demo")
	ctx.lines[#ctx.lines + 1] = "animacao AAX: clip easeOut_spring/pingpong tocando REAL (AAX_DemoCube no workspace)"
end

function E.clima(ctx)
	if not ArkherAtmosX then
		ctx.lines[#ctx.lines + 1] = "clima: Kit E (AEX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AEX = ArkherAtmosX
	AEX.setup({})
	local g = (ctx.goal or ""):lower()
	local w = "limpo"
	if g:find("tempest") or g:find("trov") or g:find("raio") then w = "tempestade"
	elseif g:find("chuva") or g:find("rain") then w = "chuva"
	elseif g:find("neve") or g:find("snow") then w = "neve"
	elseif g:find("neblina") or g:find("fog") then w = "neblina"
	elseif g:find("aurora") then w = "aurora"
	elseif g:find("nuvem") then w = "nuvem" end
	AEX.setWeather(w, 0.8)
	for i = 1, 60 do AEX.pump(1 / 30) end
	if g:find("noite") then AEX.setPreset("noite") elseif g:find("amanhecer") then AEX.setPreset("amanhecer") elseif g:find("entardecer") or g:find("sunset") then AEX.setPreset("entardecer") end
	local mix = AEX.weatherMix()
	ctx.lines[#ctx.lines + 1] = string.format("clima AEX: %s (fog %.0f, haze %.1f, waveBoost %.2fx) — Lighting/Atmosphere REAIS", AEX.S.state, mix.fogEnd, mix.haze, mix.waveBoost)
end

function E.camera(ctx)
	if not ArkherCameraX then
		ctx.lines[#ctx.lines + 1] = "camera: Kit E (ACX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local ACX = ArkherCameraX
	local g = (ctx.goal or ""):lower()
	if g:find("crane") then
		ACX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: crane 4s (lift fisico)"
	elseif g:find("fly") or g:find("voo") then
		ACX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: fly path Catmull-Rom REAL (5s)"
	elseif g:find("shake") or g:find("tremor") then
		ACX.addTrauma(0.9)
		ctx.lines[#ctx.lines + 1] = "camera ACX: trauma +0.9 (shake trauma^2)"
	else
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 14, height = 6, speed = 0.6, duration = 9999 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: orbit cinematografico real na CurrentCamera"
	end
end

function E.particles(ctx)
	if not ArkherParticlesX then
		ctx.lines[#ctx.lines + 1] = "particulas: Kit E (APX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local APX = ArkherParticlesX
	local g = (ctx.goal or ""):lower()
	local k = "fogo"
	if g:find("faisca") or g:find("spark") then k = "faiscas"
	elseif g:find("magia") or g:find("magic") then k = "magia"
	elseif g:find("fumaca") or g:find("smoke") then k = "fumaca"
	elseif g:find("explosao") or g:find("explos") then k = "faiscas"
	elseif g:find("splash") or g:find("agua") then k = "agua"
	elseif g:find("neve") then k = "neve"
	elseif g:find("poeira") or g:find("dust") then k = "poeira" end
	APX.emit(nil, k)
	if g:find("explosao") or g:find("explos") then APX.emit(nil, "fumaca") end
	local bs = APX.budgetScale()
	ctx.lines[#ctx.lines + 1] = string.format("particulas APX: %s emitido (Emitter REAL, budget D-O15 %.0f%%)", k, bs * 100)
end

function E.cloth(ctx)
	if not ArkherRopeX then
		ctx.lines[#ctx.lines + 1] = "pano: Kit E (RPX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local g = (ctx.goal or ""):lower()
	if g:find("corda") or g:find("rope") then
		local r = ArkherRopeX.rope({ from = { x = 0, y = 15, z = 0 }, points = 12, name = "RPX_SNG_Rope" })
		ArkherRopeX.materializeRope(r, { w = 0.22, color = { 185, 130, 70 } })
		ctx.lines[#ctx.lines + 1] = "pano RPX: corda de Verlet pendurada (gravidade + constraints reais) no world"
	else
		local fl = ArkherRopeX.flagAt(0, 14, 0)
		ctx.lines[#ctx.lines + 1] = "pano RPX: bandeira de tecido (Verlet coluna-grade, vento do AEX real) no world"
	end
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
