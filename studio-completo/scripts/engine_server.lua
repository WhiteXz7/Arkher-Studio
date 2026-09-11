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

local ORDER = { "DM", "ATX", "AWX", "ASXN", "AAX", "AUX", "AEX", "APX", "RPX", "RIGX", "MSHX" }
for _, nm in ipairs(ORDER) do
	local ok, err = pcall(function() require(engines[nm]) end)
	if not ok then warn("[ArkherX] motor " .. nm .. " falhou: " .. tostring(err)) end
end

local net = ReplicatedStorage:WaitForChild("ArkherNet", 30)
local cmdE = net:WaitForChild("ArkherXCmd")
local queryF = net:WaitForChild("ArkherXQ")

-- ---------- comandos (server -> mundo real) ----------
local CMD = {}

function CMD.stats()
	return {
		atx = ArkherTerrainX ~= nil, awx = ArkherWaterX ~= nil, asxn = ArkherSceneX ~= nil,
		aax = ArkherAnimX ~= nil, aux = ArkherAudioX ~= nil, aex = ArkherAtmosX ~= nil,
		apx = ArkherParticlesX ~= nil, rpx = ArkherRopeX ~= nil,
		rigx = ArkherRigX ~= nil, meshx = ArkherMeshX ~= nil,
		chains = ArkherRigX and (function() local n = 0 for _ in pairs(ArkherRigX.S.chains) do n = n + 1 end return n end)() or 0,
		meshops = ArkherMeshX and ArkherMeshX.S.stats.ops or 0,
		bodies = ArkherWaterX and #ArkherWaterX.bodies or 0,
		ropes = ArkherRopeX and (#ArkherRopeX._ropes + #ArkherRopeX._cloths) or 0,
		weather = ArkherAtmosX and ArkherAtmosX.S.state or "—",
		clock = ArkherAtmosX and ArkherAtmosX.S.clock or 0,
		sceneReg = ArkherSceneX and #ArkherSceneX._hash.map and "ok" or "ok",
	}
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

queryF.OnServerInvoke = function(payload)
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
RunService.Heartbeat:Connect(function(dt)
	if ArkherAtmosX then pcall(function() ArkherAtmosX.pump(dt) end) end
	if ArkherAnimX then pcall(function() ArkherAnimX.pump(dt) end) end -- inclui RPX (mesmo pulso)
	if ArkherAudioX then pcall(function() ArkherAudioX.pump(dt) end) end
	if ArkherRigX then pcall(function() ArkherRigX.pump(dt) end) end
	acc = acc + dt
	if acc > 0.25 then
		acc = 0
		local w = _G.ArkherWorld
		if w and ArkherSceneX and ArkherSceneX.applyLOD then
			pcall(function() ArkherSceneX.applyLOD(0, 0) end)
		end
	end
end)

print("[ArkherX] EngineServer pronto — 9 motores no vault + ponte ArkherNet ativa")
