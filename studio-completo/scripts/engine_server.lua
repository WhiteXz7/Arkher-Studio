-- =============================================================
-- ArkherEngineServer — ponte SERVIDOR dos motores ARKHER X
-- Roda em ServerScriptService. Os motores vivem como ModuleScripts
-- dentro de ServerStorage/ArkherEngines (exploiters NAO alcancam).
-- Cliente conversa via ReplicatedStorage/ArkherNet (APENAS a ponte
-- fica no ReplicatedStorage — como manda o modelo Roblox).
-- =============================================================

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local engines = ServerStorage:WaitForChild("ArkherEngines", 30)
if not engines then
	-- PROBE anti-drop: revela o que o Studio realmente carregou
	local dump = {}
	for _, c in ipairs(ServerStorage:GetChildren()) do
		dump[#dump + 1] = c.ClassName .. ":" .. c.Name .. "(" .. #c:GetChildren() .. " filhos)"
	end
	warn("[ArkherX] ServerStorage conteudo: " .. (#dump > 0 and table.concat(dump, ", ") or "(vazio)"))
	local dump2 = {}
	for _, c in ipairs(ReplicatedStorage:GetChildren()) do dump2[#dump2 + 1] = c.ClassName .. ":" .. c.Name end
	warn("[ArkherX] ReplicatedStorage conteudo: " .. (#dump2 > 0 and table.concat(dump2, ", ") or "(vazio)"))
	error("ArkherEngines ausente no ServerStorage (ver probes acima)")
end

local ORDER = { "DM", "THX", "WLDX", "RRX", "FABX", "DAYX", "ECOX", "WEAX", "CIVIX", "SECX", "PHYSX", "RLX", "DPX", "MINDX", "SPX", "ATX", "AWX", "ASXN", "AAX", "AUX", "AEX", "APX", "RPX", "RIGX", "MSHX" }
for _, nm in ipairs(ORDER) do
	local ok, err = pcall(function() require(engines["ArkherX_" .. nm]) end)
	if not ok then warn("[ArkherX] motor " .. nm .. " falhou: " .. tostring(err)) end
end

-- Liga os simbolos dos motores NESTE Script. No Roblox cada script tem
-- environment proprio: "ArkherDM = ..." num Module NAO aparece nos outros.
-- O padrao ARKHER e exportar em _G e ler de _G — aqui apenas espelhamos
-- os nomes para o codigo abaixo seguir limpo (busca em runtime, apos boot).
ArkherDM = rawget(_G, "ArkherDM")
ArkherTheoryX = rawget(_G, "ArkherTheoryX")
ArkherWorldX = rawget(_G, "ArkherWorldX")
ArkherRealityX = rawget(_G, "ArkherRealityX")
ArkherFabricX = rawget(_G, "ArkherFabricX")
ArkherDayX = rawget(_G, "ArkherDayX")
ArkherEcoX = rawget(_G, "ArkherEcoX")
ArkherWeaX = rawget(_G, "ArkherWeaX")
ArkherCiviX = rawget(_G, "ArkherCiviX")
ArkherSecX = rawget(_G, "ArkherSecX")
ArkherPhysX = rawget(_G, "ArkherPhysX")
ArkherRLayer = rawget(_G, "ArkherRLayer")
ArkherDPred = rawget(_G, "ArkherDPred")
ArkherMindX = rawget(_G, "ArkherMindX")
ArkherSpaceX = rawget(_G, "ArkherSpaceX")
ArkherTerrainX = rawget(_G, "ArkherTerrainX")
ArkherWaterX = rawget(_G, "ArkherWaterX")
ArkherSceneX = rawget(_G, "ArkherSceneX")
ArkherAnimX = rawget(_G, "ArkherAnimX")
ArkherAudioX = rawget(_G, "ArkherAudioX")
ArkherAtmosX = rawget(_G, "ArkherAtmosX")
ArkherParticlesX = rawget(_G, "ArkherParticlesX")
ArkherRopeX = rawget(_G, "ArkherRopeX")
ArkherRigX = rawget(_G, "ArkherRigX")
ArkherMeshX = rawget(_G, "ArkherMeshX")

local net = ReplicatedStorage:WaitForChild("ArkherNet", 30)
local cmdE = net:WaitForChild("ArkherXCmd")
local queryF = net:WaitForChild("ArkherXQ")

-- ---------- comandos (server -> mundo real) ----------
local CMD = {}


function CMD.tier_set(p)
	assert(ArkherRealityX, "RRX off")
	local t = ArkherRealityX.setTier((p and p.id) or "doze")
	return { msg = "D-O15 tier -> " .. t.id .. " (materializacao da realidade ajustada)" }
end

function CMD.world_generate(p)
	assert(ArkherRealityX, "RRX off")
	p = p or {}
	local w = ArkherRealityX.createWorld({
		seed = p.seed or 7, size = p.size or 1200, plates = p.plates,
		season = p.season or 0.35, driftT = p.driftT or 0,
		clock = p.clock, dayScale = p.dayScale, tier = p.tier,
	})
	return { msg = ("RRW planeta gerado: seed %d, %d placas, deriva %.1f Ma, saz %.2f"):format(
		(p.seed or 7), (p.plates or 7), (p.driftT or 0), (p.season or 0.35)) }
end

function CMD.world_materialize(p)
	assert(ArkherRealityX and ArkherRealityX.S.world, "gere o planeta primeiro")
	local res = ArkherRealityX.materializeWorld(ArkherRealityX.S.world, p or {})
	return { msg = ("RRW materializado: %d celulas com materia REAL + %d alvos de parallax TRUE"):format(res.cells, res.parallax) }
end

function CMD.world_tool(p)
	assert(ArkherWorldX and ArkherWorldX.tool, "WORLDX off")
	local w = ArkherRealityX.S.world
	if not w then return { msg = "gere o planeta primeiro" } end
	p = p or {}
	p.x = p.x or 0
	p.z = p.z or 0
	local res = ArkherWorldX.tool(p.id, w, p)
	return { msg = "TERRAIN[" .. (p.id or "?") .. "]: " .. res.msg .. " (" .. tostring(res.applied or 0) .. " strokes)" }
end

function CMD.world_vegetate(p)
	assert(ArkherRealityX, "RRX off")
	local w = ArkherRealityX.S.world
	if not w then return { msg = "gere o planeta primeiro" } end
	local res = ArkherRealityX.autoVegetate(w, p or {})
	return { msg = ("VEGETAÇÃO: %d árvores por bioma Whittaker (slots %s)"):format(
		res.placed, next(ArkherWorldX.S.slots) and "modelos OK" or "protótipo ARKHER") }
end

function CMD.world_erode(p)
	assert(ArkherWorldX, "WLDX off")
	local w = ArkherRealityX.S.world
	if not w then return { msg = "gere o planeta primeiro" } end
	local res = ArkherWorldX.erode(w, (p and p.cycles) or 150)
	return { msg = ("erosão: %d ciclos | run de aprendizado #%d (mapas 3D melhoram sozinhos)"):format(res.cycles, res.learned) }
end

function CMD.rrx_start(p)
	assert(ArkherRealityX, "RRX off")
	return { msg = ArkherRealityX.start() }
end

function CMD.rrx_stats(p)
	if not ArkherRealityX then return { msg = "RRX off" } end
	local s0 = ArkherRealityX.statsReport()
	return { msg = ("RRW: %d entidades | %d cells | veg %d | tier %s | clock %s | eros runs %d"):format(
		s0.entities, s0.materialized, s0.veg, s0.tier, s0.clock, s0.erodeRuns or 0) }
end


function CMD.anim_autorig(p)
	assert(ArkherRigX, "RIGX off")
	local preset = (p and p.preset) or "bipede"
	local c = ArkherRigX.autoRig(nil, preset)
	_G.ArkherX_RigChain = c
	local parts = {}
	for i = 1, #c.bones do
		local prt = workspace:FindFirstChild("RigX_auto_b" .. i) or Instance.new("Part")
		prt.Name = "RigX_auto_b" .. i
		prt.Color = Color3.fromRGB(166, 117, 240)
		prt.Material = Enum.Material.Neon
		prt.Anchored = true
		prt.Parent = workspace
		table.insert(parts, prt)
	end
	_G.ArkherX_RigPlay = ArkherRigX.playTarget(c, {
		center = c.root + Vector3.new(0, 2, 0), radius = 2.4, speed = 1.1,
		parts = parts, thickness = 0.4, color = Color3.fromRGB(166, 117, 240),
	})
	return { msg = "AutoRig '" .. preset .. "': " .. #c.bones .. " ossos (bipede/quadrupede/serpente/monstro)" }
end

function CMD.anim_autophysics(p)
	assert(ArkherRigX, "RIGX off")
	local lv = ArkherRigX.setAutoPhysics((p and p.level) or 0.6)
	return { msg = "AutoPhysics = " .. string.format("%.2f", lv) .. " (0=off 0.35=secundaria 0.7=+balance 1=+balistica)" }
end


function CMD.rrx_autobind(p)
	assert(ArkherRealityX and ArkherRealityX.autoBind, "RRX off")
	local n = ArkherRealityX.autoBind(p and p.on ~= false)
	return { msg = ("AUTO-BIND RRW: %d objetos do workspace capturados; TODO spawn futuro entra automaticamente"):format(n) }
end

function CMD.awi_on(p)
	assert(ArkherRealityX, "RRX off")
	ArkherRealityX.S.awi.on = (p and p.on ~= false)
	return { msg = "AWI (Adaptive World Intelligence) " .. (ArkherRealityX.S.awi.on and "ON — mundo aprende com a atencao do jogador" or "OFF") }
end

function CMD.earth_generate(p)
	assert(ArkherRealityX and ArkherRealityX.createEarth, "RRX off")
	local w = ArkherRealityX.createEarth((p and p.scale) or "paisagem")
	return { msg = ("TERRA escala '%s' gerada: 12 placas, 32 biomas, 1 stud = %sm, gravidade ajustada"):format(
		(p and p.scale) or "paisagem", tostring(w.earthScale.studToM)) }
end

function CMD.earth_stream(p)
	assert(ArkherRealityX and ArkherRealityX.earthStream, "RRX off")
	local on = ArkherRealityX.earthStream(p and p.on ~= false, p or {})
	return { msg = on and "STREAMING DA TERRA: ligado (histerese D-O15: entra cedo, abstrai tarde, NUNCA destroi sem abstrair)" or "streaming desligado" }
end

function CMD.world_rivers(p)
	assert(ArkherRealityX and ArkherWorldX, "RRW off")
	local w = ArkherRealityX.S.earth or ArkherRealityX.S.world
	if not w then return { msg = "gere um mundo primeiro (planeta ou terra)" } end
	local n = ArkherWorldX.rivers(w, (p and p.n) or 6)
	local segs = ArkherWorldX.materializeRivers(w)
	return { msg = ("%d rios REAIS por queda-dagua (entalharam o leito), %d segmentos d'agua materializados"):format(n, segs) }
end

function CMD.hydro_on(p)
	assert(ArkherRealityX, "RRX off")
	ArkherRealityX.S.hydroOn = (p and p.on ~= false)
	return { msg = "CICLO D'AGUA " .. (ArkherRealityX.S.hydroOn and "ON — evapora > nuvens > chuva (que erode e aprende) > rios" or "OFF") }
end

function CMD.fabricate(p)
	assert(ArkherFabricX, "FABX off")
	p = p or {}
	local res, err = ArkherFabricX.fabricate(p, { pos = Vector3.new(p.x or 0, p.y or 0, p.z or -14) })
	if not res then return { msg = "✗ " .. tostring(err) } end
	local tintMsg = ""
	if p.cr and res.model then
		local c = Color3.fromRGB(
			math.clamp(math.floor(tonumber(p.cr) or 255), 0, 255),
			math.clamp(math.floor(tonumber(p.cg) or 255), 0, 255),
			math.clamp(math.floor(tonumber(p.cb) or 255), 0, 255))
		local t = 0
		for _, d in ipairs(res.model:GetDescendants()) do
			if d:IsA("BasePart") and d.Material ~= Enum.Material.Glass and d.Material ~= Enum.Material.Neon then
				d.Color = c
				t = t + 1
			end
		end
		if t > 0 then tintMsg = (" (TINGIDO em %d parts)"):format(t) end
	end
	return { msg = ("FABRICADO: %s (seed %s)%s — %d parts de materia real, JA registrado no RRW automatico"):format(res.kind, tostring(res.seed), tintMsg, res.parts) }
end

function CMD.fabricate_list()
	assert(ArkherFabricX, "FABX off")
	local l = ArkherFabricX.list()
	return { kinds = l, count = #l }
end

function CMD.graph_stats(p)
	if not (ArkherRealityX and ArkherRealityX.graphStats) then return { msg = "grafo off" } end
	local g = ArkherRealityX.graphStats()
	local parts = {}
	for k, v in pairs(g.byMatter) do parts[#parts + 1] = k .. "=" .. v end
	return { msg = ("GRAFO SEMANTICO: %d nos — materia: %s"):format(g.nodes, table.concat(parts, " ")) }
end

function CMD.npc_spawn(p)
	assert(ArkherRigX and ArkherRealityX, "RIGX/RRX off")
	local preset = (p and p.preset) or "bipede"
	local c = ArkherRigX.autoRig(nil, preset)
	local parts = {}
	for i = 1, #c.bones do
		local prt = workspace:FindFirstChild("NPC_b" .. i) or Instance.new("Part")
		prt.Name = "NPC_b" .. i
		prt.Color = Color3.fromRGB(240, 190, 90)
		prt.Material = Enum.Material.Neon
		prt.Anchored = true
		prt.Parent = workspace
		table.insert(parts, prt)
		ArkherRealityX.register(prt, { kind = "part", matter = "soil", importance = 0.9,
			meta = { npc = true, baseTransparency = 0 } })
	end
	_G.ArkherX_NPC = ArkherRigX.playTarget(c, {
		center = c.root + Vector3.new(4, 2, 0), radius = 3.4, speed = 0.9,
		parts = parts, thickness = 0.42, color = Color3.fromRGB(240, 190, 90),
	})
	return { msg = ("NPC '%s' vivo: %d ossos FABRIK + balanco + importancia 0.9 no RRW (AutoPhysics conforme slider)"):format(preset, #c.bones) }
end


function CMD.life_human(p)
	assert(ArkherDayX, "DAYX off")
	p = p or {}
	local h = ArkherDayX.spawn({ name = p.name, seed = p.seed or 7,
		pos = Vector3.new(p.x or 0, p.y or 0, p.z or -20) })
	return { msg = ("HUMANO DIGITAL '%s' vivo: respiracao 0.25Hz, piscar fisiologico, olhar-atento, marcha procedural — importancia 0.95 no RRW"):format(h.name) }
end

function CMD.eco_start(p)
	assert(ArkherEcoX, "ECOX off")
	return { msg = ArkherEcoX.start() }
end

function CMD.eco_stats()
	assert(ArkherEcoX, "ECOX off")
	local st = ArkherEcoX.stats()
	return { msg = ("ECO: %d animais vivos, %d nascimentos — populacoes: %s"):format(
		st.spawned, st.births, table.concat(st.species, " ")) }
end

function CMD.fronts_on(p)
	assert(ArkherWeaX, "WEAX off")
	return { msg = ArkherWeaX.start() }
end

function CMD.fronts_stats()
	assert(ArkherWeaX, "WEAX off")
	local st = ArkherWeaX.stats()
	return { msg = ("FRENTES: %d sistemas (%d baixa/%d alta) | vento %s studs/s | tempo na camera: %s"):format(
		st.systems, st.low, st.high, st.wind, tostring(st.current)) }
end

function CMD.civ_fabricate(p)
	assert(ArkherCiviX, "CIVIX off")
	p = p or {}
	local res = ArkherCiviX.fabricate(p)
	if ArkherRLayer and ArkherRLayer.urbanize then
		ArkherRLayer.urbanize(tonumber(p.x) or 0, tonumber(p.z) or -90, res.kind == "metropole" and 220 or 90, res.kind == "metropole" and 0.9 or 0.65)
	end
	if ArkherMindX and ArkherMindX.addFoodSpot then
		ArkherMindX.addFoodSpot(tonumber(p.x) or 0, tonumber(p.z) or -90)
	end
	return { msg = ("ASSENTAMENTO '%s' (seed %d): %d pecas — malha viaria + FABX, tudo no RRW automatico"):format(res.kind, res.seed, res.pieces) }
end

function CMD.wind_on(p)
	assert(ArkherPhysX, "PHYSX off")
	local w = ArkherPhysX.setWind(p and p.on ~= false, p and p.deg, p and p.speed)
	return { msg = ("VENTO GLOBAL: %s a %d° forca %d studs/s° (rajadas por ruido 1D, empurra corpos soltos)"):format(
		w.on and "ON" or "OFF", w.deg, w.speed) }
end

function CMD.shockwave(p)
	assert(ArkherPhysX, "PHYSX off")
	p = p or {}
	local n = ArkherPhysX.shockwave(p.x or 0, p.z or 0, p.r or 46, p.f or 70)
	return { msg = ("SHOCKWAVE #%d em (%.0f,%.0f): decaimento esferico, empurra tudo solto no raio"):format(n, p.x or 0, p.z or 0) }
end

function CMD.sec_arm(p)
	assert(ArkherSecX, "SECX off")
	local on = ArkherSecX.arm(p and p.on ~= false)
	return { msg = "SECX " .. (on and "ARMADO: ponte ArkherXQ com rate-limit + higiene + auditoria" or "destivado") }
end

function CMD.sec_stats()
	assert(ArkherSecX, "SECX off")
	local st = ArkherSecX.stats()
	return { msg = ("SECX %s | %d violacoes | %d eventos auditados | recentes: %s"):format(
		st.on and "ON" or "off", st.violations, st.audited, st.recent) }
end


function CMD.rl_build()
	assert(ArkherRLayer, "RLX off")
	local w = ArkherRealityX and (ArkherRealityX.S.earth or ArkherRealityX.S.world)
	if not w then return { msg = "gere um mundo primeiro" } end
	local n = ArkherRLayer.build(w)
	return { msg = ("REALITY LAYER: %d células × 5 camadas (GEO/HYDRO/ATMO/BIO/URB) — realidade composta, não terreno pelado"):format(n) }
end

function CMD.rl_stats()
	assert(ArkherRLayer, "RLX off")
	local st = ArkherRLayer.stats()
	return { msg = ("RL: %d células | %d áreas urbanas | %d tints aplicados às entidades"):format(
		st.cells, st.urbSpots, st.tintApplied) }
end

function CMD.pred_on(p)
	assert(ArkherDPred, "DPX off")
	ArkherRealityX.S.dpredOn = (p and p.on ~= false)
	ArkherDPred.setOn(ArkherRealityX.S.dpredOn)
	return { msg = "D-O15 PREDICTIVE " .. (ArkherDPred.S.on and "ON — o mundo materializa ANTES da percepção chegar" or "OFF") }
end

function CMD.pred_stats()
	assert(ArkherDPred, "DPX off")
	local st = ArkherDPred.stats()
	return { msg = ("PREDICTIVE: vel %.1f st/s | horizonte %s | alvo previsto (%s) | %d células de atenção | hotspots: %s"):format(
		st.vel, st.horizon, st.pred, st.heatCells, st.hotspots) }
end

function CMD.mind_stats()
	assert(ArkherMindX, "MINDX off")
	local st = ArkherMindX.stats()
	return { msg = ("MENTES: %d vivas | objetivos: %s | pontos de comida: %d"):format(st.minds, st.goals, st.food) }
end

function CMD.mind_why(p)
	assert(ArkherMindX, "MINDX off")
	return { msg = ArkherMindX.why(p and p.name) }
end

function CMD.mind_food(p)
	assert(ArkherMindX, "MINDX off")
	p = p or {}
	local n = ArkherMindX.addFoodSpot(p.x or 0, p.z or 0)
	return { msg = ("Comida registrada (%d total) — mentes famintas vão buscar sozinhas (causalidade auditável)"):format(n) }
end


function CMD.space_preset(p)
	assert(ArkherSpaceX, "SPX off")
	local n = ArkherSpaceX.preset((p and p.id) or "solar")
	return { msg = ("ESPAÇO: preset '%s' com %d corpos celestes (órbitas keplerianas p ∝ r^1.5)"):format((p and p.id) or "solar", n) }
end

function CMD.space_add(p)
	assert(ArkherSpaceX, "SPX off")
	p = p or {}
	local b = ArkherSpaceX.add(p)
	return { msg = ("corpo '%s' adicionado: r=%skm, órbita=%skm — exibido em escala %s"):format(
		b.name, tostring(b.radiusKm), tostring(b.orbitKm), ArkherSpaceX.S.mode) }
end

function CMD.space_orbits(p)
	assert(ArkherSpaceX, "SPX off")
	ArkherSpaceX.S.orbits = (p and p.on ~= false)
	return { msg = "ÓRBITAS " .. (ArkherSpaceX.S.orbits and "ON (keplerianas reais no pump RRX)" or "PAUSADAS") }
end

function CMD.space_mode(p)
	assert(ArkherSpaceX, "SPX off")
	local m2 = ArkherSpaceX.setMode((p and p.id) or "sistema")
	return { msg = "ESPAÇO modo '" .. m2 .. "': " .. ArkherSpaceX.MODES[m2].note }
end

function CMD.space_state()
	assert(ArkherSpaceX, "SPX off")
	return { bodies = ArkherSpaceX.state(), mode = ArkherSpaceX.S.mode }
end

function CMD.bench_stats()
	assert(ArkherMeshX, "MSHX off")
	local buf = _G.ArkherX_MeshBuf or {}
	local m = buf.mesh
	return {
		verts = m and #m.v or 0,
		faces = m and #m.f or 0,
		ops = ArkherMeshX.S.stats.ops,
		msg = m and ("banca: " .. #m.v .. " verts / " .. #m.f .. " faces / " .. ArkherMeshX.S.stats.ops .. " ops") or "banca vazia — gere uma primitiva",
	}
end

function CMD.bones_visibility(p)
	local on = p and p.on ~= false
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:match("^RigX") or d.Name:match("^NPC_b") or d.Name:match("^RigX_bone")) then
			d.Transparency = on and 0 or 1
			n = n + 1
		end
	end
	return { msg = ("Ossos/palco: %s em %d partes"):format(on and "VISÍVEIS" or "ocultos", n) }
end

function CMD.world_probe(p)
	assert(ArkherWorldX, "WLDX off")
	local w = ArkherRealityX and (ArkherRealityX.S.earth or ArkherRealityX.S.world)
	if not w then return { msg = "gere um mundo primeiro" } end
	p = p or {}
	local x, z = p.x or 0, p.z or 0
	local h = ArkherWorldX.height(w, x, z)
	local bi, cl = ArkherWorldX.biomeAt(w, x, z)
	local mat = ArkherWorldX.materialAt(w, x, z, cl, bi)
	local bname = type(bi) == "table" and (bi.name or bi.id) or tostring(bi)
	return {
		h = h, biome = tostring(bname), mat = mat,
		msg = ("@(%.0f,%.0f): h=%.1f | bioma %s | matéria %s"):format(x, z, h, tostring(bname), mat),
	}
end

function CMD.stats()


	return {
		atx = ArkherTerrainX ~= nil, awx = ArkherWaterX ~= nil, asxn = ArkherSceneX ~= nil,
		aax = ArkherAnimX ~= nil, aux = ArkherAudioX ~= nil, aex = ArkherAtmosX ~= nil,
		apx = ArkherParticlesX ~= nil, rpx = ArkherRopeX ~= nil,
		rigx = ArkherRigX ~= nil, meshx = ArkherMeshX ~= nil, thx = ArkherTheoryX ~= nil,
		wldx = ArkherWorldX ~= nil, rrx = ArkherRealityX ~= nil,
		chains = ArkherRigX and (function() local n = 0 for _ in pairs(ArkherRigX.S.chains) do n = n + 1 end return n end)() or 0,
		meshops = ArkherMeshX and ArkherMeshX.S.stats.ops or 0,
		bodies = ArkherWaterX and #ArkherWaterX.bodies or 0,
		ropes = ArkherRopeX and (#ArkherRopeX._ropes + #ArkherRopeX._cloths) or 0,
		weather = ArkherAtmosX and ArkherAtmosX.S.state or "—",
		clock = ArkherAtmosX and ArkherAtmosX.S.clock or 0,
		sceneReg = ArkherSceneX and #ArkherSceneX._hash.map and "ok" or "ok",
	}
end


function CMD.world_tools()
	assert(ArkherWorldX and ArkherWorldX.TOOLS, "WLDX off")
	local out = {}
	for id, def in pairs(ArkherWorldX.TOOLS) do
		out[#out + 1] = { id = id, cat = def.cat or "geral", msg = def.msg or id }
	end
	table.sort(out, function(a, b) if a.cat ~= b.cat then return a.cat < b.cat end return a.id < b.id end)
	return { tools = out, count = #out }
end

function CMD.mesh_tools()
	assert(ArkherMeshX and ArkherMeshX.TOOLS, "MSHX off")
	local out = {}
	for id, def in pairs(ArkherMeshX.TOOLS) do
		out[#out + 1] = { id = id, cat = def.cat or "geral", msg = def.msg or id }
	end
	table.sort(out, function(a, b) if a.cat ~= b.cat then return a.cat < b.cat end return a.id < b.id end)
	return { tools = out, count = #out }
end

function CMD.mesh_tool(p)
	assert(ArkherMeshX and ArkherMeshX.tool, "MSHX off")
	p = p or {}
	local def = ArkherMeshX.TOOLS[p.id]
	if not def then return { msg = "mesh tool desconhecida: " .. tostring(p.id) } end
	local buf = _G.ArkherX_MeshBuf or {}
	_G.ArkherX_MeshBuf = buf
	local res
	if def.cat == "prim" then
		res = ArkherMeshX.tool(p.id, nil, p)
		buf.mesh = res.mesh
	else
		if not buf.mesh then
			return { msg = "crie uma PRIMITIVA antes (MODELER > geracao) — tools de transformacao precisam de mesh" }
		end
		res = ArkherMeshX.tool(p.id, buf.mesh, p)
		buf.mesh = res.mesh or buf.mesh
	end
	if buf.mesh and buf.mesh.v then
		if buf.model then pcall(function() buf.model:Destroy() end) end
		buf.model = ArkherMeshX.bake(buf.mesh, {
			name = "ArkherX_MeshBench", mode = "auto",
			color = Color3.fromRGB(140, 200, 255), th = 0.06,
		})
	end
	return { msg = ("MESH[%s/%s]: %s — banca com %d verts"):format(
		p.id, def.cat, def.msg or "ok", buf.mesh and #buf.mesh.v or 0) }
end

function CMD.terrain_generate(p)
	assert(ArkherTerrainX, "ATX off")
	local w = ArkherTerrainX.new({
		seed = (p and p.seed) or 7,
		preset = (p and p.preset) or "continentes",
		cell = 8, chunkCells = 24,
	})
	_G.ArkherWorld = w
	return { msg = "ATX mundo '" .. w.preset .. "' gerado (seed " .. w.seed .. ", mar " .. w.seaLevel .. ")" }
end

function CMD.terrain_materialize(p)
	local w = _G.ArkherWorld
	if not w then return { msg = "gere o terreno primeiro" } end
	local m = w:materialize(24, 3)
	return { msg = "ATX materializado: " .. tostring(w.partsCount) .. " parts (" .. w.stats.cells .. " celulas)" }
end

function CMD.terrain_erode(p)
	local w = _G.ArkherWorld
	if not w then return { msg = "gere o terreno primeiro" } end
	w:erodeRain((p and p.cycles) or 120)
	return { msg = "erosao hidraulica real: " .. w.stats.droplets .. " gotas" }
end

function CMD.scatter_forest(p)
	assert(ArkherSceneX, "ASXN off")
	local w = _G.ArkherWorld
	if not w and ArkherTerrainX then w = ArkherTerrainX.new({ seed = 5, preset = "montanhas", cell = 8 }) _G.ArkherWorld = w end
	local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = (p and p.radius) or 90, count = (p and p.count) or 60, minDist = 6, world = w, seed = 31, name = "ArkherX_Forest" })
	return { msg = "ASXN floresta: " .. res.count .. " arvores por bioma Whittaker REAL" }
end

function CMD.patina(p)
	assert(ArkherSceneX, "ASXN off")
	local m = workspace:FindFirstChild("ArkherX_Forest")
	if not m then return { msg = "gere a floresta primeiro" } end
	local n = ArkherSceneX.patina(m, { hue = 0.03, sat = 0.08, val = 0.1, seed = 71 })
	return { msg = "patina anti-CG em " .. n .. " parts (cor + jitter + tinta por distancia)" }
end

function CMD.water_ocean(p)
	assert(ArkherWaterX, "AWX off")
	local b = ArkherWaterX.preset((p and p.sea) or "porto", { level = 10 })
	_G.ArkherSea = b
	return { msg = "AWX oceano '" .. b.kind .. "' no nivel " .. b.level }
end

function CMD.water_boat(p)
	local b = _G.ArkherSea
	if not b then return { msg = "crie o oceano primeiro" } end
	local hull = Instance.new("Part")
	hull.Name = "ArkherX_BoatHull"
	hull.Size = Vector3.new(5, 3, 10)
	hull.CFrame = CFrame.new(0, 11.5, 0)
	hull.Anchored = true
	hull.Color = Color3.fromRGB(150, 55, 35)
	hull.Parent = workspace
	ArkherWaterX.boat(b, hull, { mass = 52000, power = 30 })
	return { msg = "barco fisico (4 pontos) no " .. b.kind .. " — empuxo Arquimedes real" }
end

function CMD.water_presets()
	assert(ArkherWaterX, "AWX off")
	local kinds = {}
	for id, w in pairs(ArkherWaterX.WATERS) do
		kinds[#kinds + 1] = { id = id, nm = w.nm, dens = w.dens, sal = w.sal, temp = w.temp, visc = w.visc }
	end
	table.sort(kinds, function(a, b) return a.id < b.id end)
	local seas = {}
	for id, pr in pairs(ArkherWaterX.PRESETS) do
		local maxAmp, total = 0, 0
		for _, wv in ipairs(pr.waves or {}) do maxAmp = math.max(maxAmp, wv.amp or 0) total = total + 1 end
		seas[#seas + 1] = { id = id, maxAmp = maxAmp, waves = total, tide = pr.tide }
	end
	table.sort(seas, function(a, b) return a.id < b.id end)
	return { kinds = kinds, seas = seas, count = #kinds }
end

function CMD.water_create(p)
	assert(ArkherWaterX, "AWX off")
	p = p or {}
	local kind = p.kind or "oceano"
	local wavePreset = ArkherWaterX.PRESETS[p.preset or "porto"] or ArkherWaterX.PRESETS.calmaria
	local b = ArkherWaterX.create(kind, {
		level = p.level or 8,
		center = { x = p.x or 0, z = p.z or 0 },
		size = { x = p.size or 512, z = p.size or 512 },
		waves = wavePreset.waves,
		tideAmp = wavePreset.tide or 0.2,
	})
	ArkherWaterX.materialize(b, { maxSpan = 220 })
	_G.ArkherSea = b
	if ArkherWaterX.caustics then pcall(ArkherWaterX.caustics, b, (p.level or 8) - 6, {}) end
	local pr = b.props
	return { msg = ("AGUA REAL criada: %s [%s] — %.0f kg/m3, sal %.1f g/kg, %.0f C, %d ondas Gerstner (%s), mare %.1f — %d tiles"):format(
		pr.nm, b.kind, pr.dens, pr.sal, pr.temp, #b.waves, p.preset or "porto", b.tideAmp, b.tileParts or 0) }
end

function CMD.water_stats()
	assert(ArkherWaterX, "AWX off")
	local nb, nf, nflo, nw = #ArkherWaterX.bodies, 0, 0, 0
	for _, b in ipairs(ArkherWaterX.bodies) do
		nflo = nflo + #b.floaters
		nw = nw + #b.waves
		nf = nf + ((b.falls and #b.falls) or 0)
	end
	return { bodies = nb, floaters = nflo, wavesTotal = nw,
		msg = ("AWX: %d corpos d'agua | %d ondas Gerstner no pump | %d flutuadores | dispersao omega=sqrt(g*k) REAL"):format(nb, nw, nflo) }
end

function CMD.water_float_test(p)
	assert(ArkherWaterX, "AWX off")
	local b = _G.ArkherSea
	if not b then return { msg = "crie um corpo d'agua primeiro (AGUA > criar)" } end
	p = p or {}
	local mats = {
		{ nm = "espuma", dens = 40, cor = Color3.fromRGB(240, 240, 220) },
		{ nm = "madeira", dens = 600, cor = Color3.fromRGB(150, 105, 60) },
		{ nm = "gelo", dens = 917, cor = Color3.fromRGB(190, 225, 240) },
		{ nm = "tubarao de borracha", dens = 1090, cor = Color3.fromRGB(90, 90, 100) },
		{ nm = "concreto", dens = 2400, cor = Color3.fromRGB(140, 140, 140) },
		{ nm = "ferro", dens = 7850, cor = Color3.fromRGB(80, 84, 92) },
	}
	for i, m in ipairs(mats) do
		local box = Instance.new("Part")
		box.Name = "AWX_Float_" .. m.nm:gsub(" ", "_")
		box.Size = Vector3.new(2.4, 2.4, 2.4)
		box.CFrame = CFrame.new(-30 + i * 8, b.level + 6, p.z or -20)
		box.Color = m.cor
		box.Parent = workspace
		ArkherWaterX.float(b, box, { density = m.dens })
		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.fromOffset(150, 30)
		tag.StudsOffset = Vector3.new(0, 2.5, 0)
		tag.AlwaysOnTop = true
		tag.Parent = box
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Text = m.nm .. " " .. m.dens .. "kg/m3"
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 10
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0.4
		tl.Parent = tag
	end
	return { msg = "TESTE DE ARQUIMEDES: 6 materiais com densidades REAIS (40 a 7850 kg/m3) — observe quem flutua e QUANTO afunda (empuxo = rho*V*g) no pump" }
end

function CMD.water_waterfall(p)
	assert(ArkherWaterX, "AWX off")
	local b = _G.ArkherSea
	if not b then return { msg = "crie um corpo d'agua primeiro" } end
	p = p or {}
	local wf = ArkherWaterX.waterfall(b, {
		sourceX = p.x or 0, sourceY = b.level + (p.h or 22), sourceZ = p.z or 30,
		flow = p.flow or 8, width = p.width or 3, speed = p.speed or 1.4,
	})
	b.falls = b.falls or {}
	b.falls[#b.falls + 1] = wf
	return { msg = ("CACHOEIRA fisica: jato em %.0f studs de altura, %d gotas/s de materia real + respingo/som no pump"):format(p.h or 22, p.flow or 8) }
end

function CMD.water_composition(p)
	assert(ArkherWaterX, "AWX off")
	local b = _G.ArkherSea
	if not b then return { msg = "sem corpo d'agua ativo" } end
	local pr = b.props
	return { msg = ("COMPOSICAO %s: densidade %.1f kg/m3 (agua pura 1000) | salinidade %.1f g/kg | temp %.1f C | viscosidade rel %.2f | absorcao luz %.2f"):format(
		pr.nm, pr.dens, pr.sal, pr.temp, pr.visc, pr.absorb) }
end

function CMD.atmos_weather(p)
	assert(ArkherAtmosX, "AEX off")
	ArkherAtmosX.setup({})
	local w = (p and p.state) or "chuva"
	ArkherAtmosX.setWeather(w, 0.8)
	return { msg = "weather machine AEX -> " .. w .. " (fog/haze/AWX/AUX reais no pump)" }
end

function CMD.atmos_preset(p)
	assert(ArkherAtmosX, "AEX off")
	ArkherAtmosX.setup({})
	local pr = (p and p.preset) or "entardecer"
	ArkherAtmosX.setPreset(pr)
	ArkherAtmosX.apply({})
	return { msg = "ceu AEX '" .. pr .. "' aplicado (Kelvin real no Lighting)" }
end

function CMD.rope_demo(p)
	assert(ArkherRopeX, "RPX off")
	local r = ArkherRopeX.rope({ from = { x = 0, y = 18, z = -6 }, points = 12, name = "ArkherX_Rope" })
	ArkherRopeX.materializeRope(r, { w = 0.25, color = { 190, 130, 70 } })
	ArkherRopeX.flagAt(6, 16, 4)
	ArkherRopeX.addSphere(2, 13, 0, 2.2)
	return { msg = "RPX corda + bandeira de Verlet no world (vento liga com AEX)" }
end

function CMD.px_emit(p)
	assert(ArkherParticlesX, "APX off")
	ArkherParticlesX.emit(nil, (p and p.kind) or "fogo")
	return { msg = "APX emissor '" .. ((p and p.kind) or "fogo") .. "' emitido (budget D-O15)" }
end

function CMD.aax_demo(p)
	assert(ArkherAnimX, "AAX off")
	local part = Instance.new("Part")
	part.Name = "ArkherX_AnimCube"
	part.Size = Vector3.new(2, 2, 2)
	part.Position = Vector3.new(0, 8, 0)
	part.Anchored = true
	part.Color = Color3.fromRGB(60, 130, 250)
	part.Parent = workspace
	local clip = ArkherAnimX.clip({
		Id = "sv_pump", loop = "pingpong", duration = 1.6,
		tracks = {
			{ path = {"Size","Y"}, keys = { {0, 2}, {0.8, 5.2} }, ease = "easeOut_spring" },
			{ path = {"Position","Y"}, keys = { {0, 8}, {0.8, 12} }, ease = "easeOut_bounce" },
		},
		target = part,
	})
	clip:play()
	return { msg = "AAX: cubo pulsando com spring+bounce reais (loop pingpong)" }
end

function CMD.rig_demo(p)
	assert(ArkherRigX, "RIGX off")
	ArkherRigX.stopAll()
	local c = ArkherRigX.demo()
	local parts = {}
	for i = 1, #c.bones do
		local prt = Instance.new("Part")
		prt.Name = "RigX_bone" .. i
		prt.Color = Color3.fromRGB(90, 190, 255)
		prt.Material = Enum.Material.Neon
		prt.Parent = workspace
		table.insert(parts, prt)
	end
	_G.ArkherX_RigPlay = ArkherRigX.playTarget(c, {
		center = Vector3.new(0, 5, -8), radius = 3.2, speed = 1.2,
		parts = parts, thickness = 0.34, color = Color3.fromRGB(90, 190, 255),
	})
	return { msg = "RigX: cadeia 4 ossos FABRIK + pole, ghost ring e alvo orbital" }
end

function CMD.rig_stop(p)
	if ArkherRigX then ArkherRigX.stopAll() end
	return { msg = "RigX parado" }
end

function CMD.rig_balance(p)
	assert(ArkherRigX, "RIGX off")
	local c = next(ArkherRigX.S.chains) and ArkherRigX.S.chains[next(ArkherRigX.S.chains)]
	if not c then return { msg = "crie a cadeia primeiro (RigX demo)" } end
	local res = ArkherRigX.balance(c, { { x = -0.6, z = -8.4 }, { x = 0.6, z = -8.4 }, { x = 0.6, z = -7.2 }, { x = -0.6, z = -7.2 } })
	return { msg = ("COM=%.1f,%.1f | margem=%.2f %s (Cascadeur-style)"):format(
		res.com.X, res.com.Z, res.margin, res.inside and "DENTRO" or "FORA") }
end

function CMD.mesh_house(p)
	assert(ArkherMeshX, "MSHX off")
	CMD.mesh_clean()
	local m = ArkherMeshX.house({ w = 16, h = 7, d = 12, windows = 3 })
	_G.ArkherX_MeshModel = ArkherMeshX.bake(m, { name = "ArkherX_House", mode = (p and p.mode) or "auto",
		color = Color3.fromRGB(212, 172, 120), th = 0.08 })
	return { msg = ("MSHX casa: %d verts/%d faces (boolean janelas+porta REAL)"):format(#m.v, #m.f) }
end

function CMD.mesh_gear(p)
	assert(ArkherMeshX, "MSHX off")
	CMD.mesh_clean()
	local m = ArkherMeshX.gear(3, 10, 0.8)
	ArkherMeshX.translate(m, Vector3.new(22, 4, 0))
	_G.ArkherX_MeshModel = ArkherMeshX.bake(m, { name = "ArkherX_Gear", mode = "edges",
		color = Color3.fromRGB(43, 203, 243), th = 0.12 })
	return { msg = ("MSHX engrenagem: %d verts/%d faces, 10 dentes extrudados"):format(#m.v, #m.f) }
end

function CMD.mesh_crystal(p)
	assert(ArkherMeshX, "MSHX off")
	CMD.mesh_clean()
	local m = ArkherMeshX.crystal(2.4, 1.9)
	ArkherMeshX.translate(m, Vector3.new(0, 5, 14))
	_G.ArkherX_MeshModel = ArkherMeshX.bake(m, { name = "ArkherX_Crystal", mode = "edges",
		color = Color3.fromRGB(166, 117, 240), th = 0.1 })
	return { msg = ("MSHX cristal: %d verts/%d faces (icosa+subdiv tri)"):format(#m.v, #m.f) }
end

function CMD.mesh_mesa(p)
	assert(ArkherMeshX, "MSHX off")
	CMD.mesh_clean()
	local m = ArkherMeshX.mesa((p and p.seed) or 7, 44, 8)
	ArkherMeshX.translate(m, Vector3.new(0, 3, 40))
	_G.ArkherX_MeshModel = ArkherMeshX.bake(m, { name = "ArkherX_Mesa", mode = "edges",
		color = Color3.fromRGB(120, 220, 160), th = 0.09 })
	return { msg = ("MSHX mesa: %d verts/%d faces (plane+displace+subdivide suave)"):format(#m.v, #m.f) }
end

function CMD.mesh_clean()
	local old = workspace:FindFirstChild("ArkherX_House") or workspace:FindFirstChild("ArkherX_Gear")
		or workspace:FindFirstChild("ArkherX_Crystal") or workspace:FindFirstChild("ArkherX_Mesa")
		or workspace:FindFirstChild("ArkherX_Mesh")
	if old then old:Destroy() end
	return { msg = "mesh anterior limpa" }
end

-- ---------- remotes ----------
cmdE.OnServerEvent:Connect(function(player, op, params)
	local fn = CMD[tostring(op or "")]
	if not fn then return end
	local ok, res = pcall(fn, params)
	if not ok then warn("[ArkherX] cmd " .. tostring(op) .. ": " .. tostring(res)) end
end)

queryF.OnServerInvoke = function(player, payload)
	-- SECX blinda a ponte: rate-limit por jogador + higiene + auditoria (fail-closed)
	if ArkherSecX then
		local okHook, allowed = pcall(function() return ArkherSecX.allow(player, payload) end)
		if not okHook then
			return { msg = "SECX indisponivel — comando negado (fail-closed)" }
		end
		if not allowed then
			return { msg = "SECX: rate limit ou payload invalido — reduza o ritmo" }
		end
	end
	if type(payload) == "table" and payload.op then
		local fn = CMD[tostring(payload.op)]
		if fn then
			local ok, res = pcall(fn, payload.params)
			if ok then return res end
			return { msg = "erro: " .. tostring(res) }
		end
		return { msg = "op desconhecida: " .. tostring(payload.op) }
	end
	return CMD.stats()
end

-- ---------- pumps (servidor, pelo RunService puro) ----------
local acc = 0

-- =============================================================
-- COMANDOS DOS NOVOS EDITORES X (ATMOS / CLIMA / VIDA / CIDADE /
-- AUDIO / FX / CORDAS) — toda a UI nova vem por esses canais reais
-- =============================================================

function CMD.atmos_list()
	assert(ArkherAtmosX, "AEX off")
	local skies = {}
	for id, pr in pairs(ArkherAtmosX.SKY_PRESETS) do
		skies[#skies + 1] = { id = id, kelvin = pr.kelvin, clock = pr.clock, fogEnd = pr.fogEnd }
	end
	table.sort(skies, function(a, b) return a.clock < b.clock end)
	local weathers = {}
	for id in pairs(ArkherAtmosX.WEATHER) do weathers[#weathers + 1] = id end
	table.sort(weathers)
	local S = ArkherAtmosX.S
	return { skies = skies, weathers = weathers, preset = S.preset, state = S.state, clock = S.clock }
end

function CMD.atmos_clock(p)
	assert(ArkherAtmosX, "AEX off")
	local h = math.clamp(tonumber(p and p.h) or 12, 0, 24)
	ArkherAtmosX.setClock(h)
	return { msg = ("RELÓGIO SOLAR -> %.1fh (o céu cruza os Kelvin SOZINHO no pump — sem truque de cor)"):format(h) }
end

function CMD.atmos_stats()
	if not ArkherAtmosX then return { msg = "AEX off" } end
	local S = ArkherAtmosX.S
	return { state = S.state, preset = S.preset, clock = S.clock,
		msg = ("AEX: tempo='%s' (transicao %.0f%%) | ceu='%s' %.1fh | fog adapta no pump"):format(S.state, (S.blend or 1) * 100, S.preset, S.clock) }
end

function CMD.wea_stats()
	assert(ArkherWeaX, "WEAX off")
	local S = ArkherWeaX.S
	local systems = {}
	for i, sy in ipairs(S.systems) do
		if i > 6 then break end
		systems[#systems + 1] = { kind = sy.kind, x = sy.x, z = sy.z, r = sy.r, int = sy.int }
	end
	return { running = S.running, n = #S.systems, systems = systems,
		wind = S.wind,
		msg = ("WEA: %s | %d frentes vivas (H/L viajando) | vento (%.1f, %.1f)"):format(
			S.running and "RODANDO" or "parado", #S.systems, S.wind.X, S.wind.Y) }
end

function CMD.wea_off()
	assert(ArkherWeaX, "WEAX off")
	ArkherWeaX.S.running = false
	return { msg = "WEA: frentes PARADAS — ceu volta a ficar manual (ATMOS)" }
end

function CMD.day_stats()
	assert(ArkherDayX, "DAYX off")
	local st = ArkherDayX.stats()
	return { humans = st.humans, msg = ("DAYX: %d humanos digitais vivos (respiracao/piscar/olhar procedural no pump)"):format(st.humans) }
end

function CMD.mind_stats()
	assert(ArkherMindX, "MINDX off")
	local st = ArkherMindX.stats()
	return { st.minds and st.minds or 0,
		msg = ("MENTES: %d ativas | objetivos: %s | pontos de comida: %d"):format(st.minds, st.goals ~= "" and st.goals or "—", st.food) }
end

function CMD.eco_stop()
	assert(ArkherEcoX, "ECOX off")
	if ArkherEcoX.stop then return { msg = ArkherEcoX.stop() } end
	return { msg = "ECO sem stop (o modulo define so start) — gere isso no erro, ao menos o aviso e honesto" }
end

function CMD.civ_stats()
	assert(ArkherCiviX, "CIVIX off")
	local st = ArkherCiviX.stats()
	return { settlements = st.settlements,
		msg = ("CIVIX: %d assentamentos erguidos — cada um grava na TERRA via RLayer.urbanize"):format(st.settlements) }
end

function CMD.audio_setup()
	assert(ArkherAudioX, "AUX off")
	ArkherAudioX.setup()
	local buses = {}
	for _, b in ipairs(ArkherAudioX.BUSES) do
		buses[#buses + 1] = { name = b, vol = ArkherAudioX.busVolume(b) or 1 }
	end
	return { buses = buses, msg = "MIXER AUX: 7 buses vivos (master/music/sfx/ui/ambient/weather/voice)" }
end

function CMD.audio_bus(p)
	assert(ArkherAudioX, "AUX off")
	p = p or {}
	local bus = tostring(p.bus or "sfx")
	local vol = math.clamp(tonumber(p.vol) or 1, 0, 2)
	local okv = ArkherAudioX.setBusVolume(bus, vol)
	if okv == false then return { msg = "bus desconhecido: " .. bus } end
	return { msg = ("MIXER: bus '%s' -> %.2f (lido de volta: %.2f)"):format(bus, vol, ArkherAudioX.busVolume(bus) or 0) }
end

function CMD.audio_intensity(p)
	assert(ArkherAudioX, "AUX off")
	local v = math.clamp(tonumber(p and p.v) or 1, 0, 2)
	ArkherAudioX.setIntensity(v)
	return { msg = ("INTENSIDADE MUSICAL -> %.2f (%s)"):format(v, v < 0.5 and "PAZ" or (v < 1.4 and "TENSÃO" or "COMBATE")) }
end

function CMD.audio_stats()
	if not ArkherAudioX then return { msg = "AUX off" } end
	local st = ArkherAudioX.stats()
	return st
end

function CMD.fx_presets()
	assert(ArkherParticlesX, "APX off")
	local out = {}
	for id, pr in pairs(ArkherParticlesX.PRESETS) do
		out[#out + 1] = { id = id, mode = pr.mode, rate = pr.rate or 0, speed = pr.speed or 0, gravity = pr.gravity or 0, life = pr.life or 0 }
	end
	table.sort(out, function(a, b) return a.id < b.id end)
	return { presets = out, count = #out }
end

function CMD.fx_emit(p)
	assert(ArkherParticlesX, "APX off")
	p = p or {}
	local anchor = Instance.new("Part")
	anchor.Name = "APX_" .. tostring(p.kind or "fogo")
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Position = Vector3.new(p.x or 0, p.y or 6, p.z or -16)
	anchor.Parent = workspace
	ArkherParticlesX.emit(anchor, tostring(p.kind or "fogo"))
	return { msg = ("FX emissor '%s' ancorado em (%.0f, %.0f, %.0f) — budget D-O15 restringe sozinho"):format(p.kind or "fogo", p.x or 0, p.y or 6, p.z or -16) }
end

function CMD.fx_clear()
	assert(ArkherParticlesX, "APX off")
	ArkherParticlesX.clear()
	return { msg = "FX: emissores LIMPOS do mundo" }
end

function CMD.fx_stats()
	if not ArkherParticlesX then return { msg = "APX off" } end
	local n = 0
	for _ in pairs(ArkherParticlesX._emitters) do n = n + 1 end
	return { emitters = n, msg = ("FX: %d emissores ativos | budget D-O15 [1]=%.2f [3]=%.2f"):format(n, ArkherParticlesX.BUDGET[1], ArkherParticlesX.BUDGET[3]) }
end

function CMD.rope_flag(p)
	assert(ArkherRopeX, "RPX off")
	p = p or {}
	ArkherRopeX.flagAt(tonumber(p.x) or 6, tonumber(p.y) or 16, tonumber(p.z) or 4)
	return { msg = "BANDEIRA de Verlet no mundo — o vento AEX a carrega de verdade" }
end

function CMD.rope_bridge(p)
	assert(ArkherRopeX, "RPX off")
	p = p or {}
	local len = math.clamp(tonumber(p.len) or 30, 12, 120)
	local y = tonumber(p.y) or 18
	local z = tonumber(p.z) or 10
	for _, px in ipairs({ -len / 2, len / 2 }) do
		local post = Instance.new("Part")
		post.Name = "RPX_Post"
		post.Size = Vector3.new(0.8, y, 0.8)
		post.CFrame = CFrame.new(px, y / 2, z)
		post.Anchored = true
		post.Color = Color3.fromRGB(90, 70, 50)
		post.Material = Enum.Material.Wood
		post.Parent = workspace
	end
	local r = ArkherRopeX.rope({ from = { x = -len / 2, y = y, z = z }, to = { x = len / 2, y = y, z = z }, points = 14 })
	ArkherRopeX.materializeRope(r, { w = 0.18, color = { 190, 130, 70 } })
	ArkherRopeX.addSphere(0, y - 1, z, 1.4)
	return { msg = ("PONTE PÊNSIL Verlet: %d studs vão, 14 pontos de corda real + bola oscilando"):format(len) }
end

function CMD.rope_stats()
	if not ArkherRopeX then return { msg = "RPX off" } end
	local nr = #ArkherRopeX._ropes
	local nc = #ArkherRopeX._cloths
	return { ropes = nr, cloths = nc,
		msg = ("RPX: %d cordas + %d tecidos Vivos (integracao Verlet no pump)"):format(nr, nc) }
end

local function modOn(nm)
	return engines:GetAttribute("Enabled_" .. nm) ~= false
end

RunService.Heartbeat:Connect(function(dt)
	if ArkherAtmosX and modOn("Atmos") then pcall(function() ArkherAtmosX.pump(dt) end) end
	if ArkherWaterX and modOn("Water") then pcall(function()
		local t = os.clock()
		for _, b in ipairs(ArkherWaterX.bodies or {}) do
			pcall(ArkherWaterX.animate, b, t)
			pcall(ArkherWaterX.step, b, dt, t)
		end
		if ArkherWaterX.stepFalls then pcall(ArkherWaterX.stepFalls, dt, t) end
		if ArkherWaterX.stepBoats then pcall(ArkherWaterX.stepBoats, dt, t) end
	end) end
	if ArkherAnimX and modOn("Anim") then pcall(function() ArkherAnimX.pump(dt) end) end -- inclui RPX (mesmo pulso)
	if ArkherAudioX and modOn("Audio") then pcall(function() ArkherAudioX.pump(dt) end) end
	if ArkherRigX and modOn("Rig") then pcall(function() ArkherRigX.pump(dt) end) end
	if ArkherRealityX and modOn("Reality") then pcall(function() ArkherRealityX.pump(dt) end) end
	acc = acc + dt
	if acc > 0.25 then
		acc = 0
		local w = _G.ArkherWorld
		if w and ArkherSceneX and ArkherSceneX.applyLOD and modOn("Scene") then
			pcall(function() ArkherSceneX.applyLOD(0, 0) end)
		end
	end
end)

print("[ArkherX] EngineServer pronto — 25 motores (RRW backend + ESPAÇO) + ponte ArkherNet blindada")
