-- REALITY X (RRX) — o orquestrador RRW do ARKHER:
-- REALIDADE -> CONHECIMENTO -> TESE_DOS_D -> REPRESENTACAO -> D_O15 -> RRW
-- -> MATERIALIZACAO -> EXPERIENCIA, aplicado AUTOMATICAMENTE em tudo.
-- Toda coisa do mundo e uma "realidade" com materia+importancia; o daemon
-- decide o D operacional por entidade e materializa (16k, parallax, luz,
-- fisica, LOD) — nenhum menu, nenhum preset: adaptacao continua da realidade.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local WX = rawget(_G, "ArkherWorldX")

local V3 = Vector3.new
local RX = {}
local S = {
	entities = {},  -- ref -> {obj, matter, importance, d, dTarget, kind}
	world = nil,
	running = false,
	clock = 11.0,   -- hora do dia do mundo
	dayScale = 60,  -- 1 dia = dom segundos reais
	tier = "doze",
	learnRounds = 0,
	stats = { adapted = 0, materialized = 0, parallaxAtivo = 0 },
}
RX.S = S

-- ============ registrar realidade ============
-- kind: "terrain" | "veg" | "water" | "rope" | "part" | "mesh" | "sky"
function RX.register(obj, opts)
	opts = opts or {}
	local ent = {
		obj = obj,
		kind = opts.kind or "part",
		matter = opts.matter or "rock",
		importance = math.clamp(opts.importance or 0.5, 0, 1),
		d = 1.0,
		dT = 1.0,
		meta = opts.meta or {},
		lastAdapt = 0,
	}
	S.entities[obj] = ent
	return ent
end

function RX.unregister(obj)
	S.entities[obj] = nil
end

-- ============ D-alvo por contexto (Tese dos D: obj+ctx+recursos) ============
local cameraPos = V3(0, 30, 0)
function RX.setCamera(v) cameraPos = v end

local function targetD(ent)
	local obj = ent.obj
	local pos
	if obj and obj.Parent then
		local ok, vv = pcall(function() return obj:IsA("Model") and obj:GetPivot().Position or obj.Position end)
		pos = ok and vv or nil
	end
	local dist = pos and (pos - cameraPos).Magnitude or 500
	local budget = (TX.TIERS[S.tier] or TX.TIERS.doze).pixelBudget
	return TX.chooseD(ent.importance, dist, budget), dist
end

-- hysteresis D (sec. 82) + D preditivo (sec. 83/84): sobe cedo, desce tarde
local function stepD(ent, dt)
	local dT = select(1, targetD(ent))
	ent.dT = dT
	local rate = (dT > ent.d) and 6 or 1.4 -- subir eh prioridade; descer suave
	ent.d = ent.d + (dT - ent.d) * math.min(1, rate * dt)
	-- snap proximo ao alvo p/ nao oscilar (estabilidade)
	if math.abs(ent.d - dT) < 0.035 then ent.d = dT end
	return ent.d
end

-- ============ MATERIALIZACAO por entidade (RRW em acao) ============
local function materialize(ent)
	local obj = ent.obj
	if not obj or not obj.Parent then return false end
	if ent.kind == "terrain" or ent.kind == "veg" or ent.kind == "part" or ent.kind == "mesh" then
		-- cor/material de MATERIA REAL (micro-relieve 16K pelo mundo quando perto)
		if ent.d > 0.65 and ent.meta and ent.meta.mat16k then
			pcall(function()
				if obj:IsA("BasePart") then
					obj.Color = ent.meta.mat16k(obj.Position.X, obj.Position.Z)
					obj.Material = Enum.Material.SmoothPlastic
				end
			end)
		end
		-- parallax TRUE: cascas ligam/desligam por D (D-O15, nao preset)
		local shells = ent.meta and ent.meta.shells
		if shells then
			local want = ent.d > 0.55
			for i, sh in ipairs(shells) do
				local lim = (i - 1) / math.max(1, #shells - 1)
				pcall(function() sh.Visible = want and (ent.d > 0.55 + lim * 0.35) end)
			end
			S.stats.parallaxAtivo = want and 1 or 0
		end
		-- NIC/LOD distante nao destruido (regra de nao-destruicao, sec. 80):
		-- representacao abstraida (transparencia alta em vez de Destroy).
		local tr = ent.meta and ent.meta.baseTransparency or 0
		if ent.d < 0.12 then
			pcall(function() obj.Transparency = math.min(0.85, 0.25 + (0.12 - ent.d) * 5) end)
		else
			pcall(function() obj.Transparency = tr end)
		end
	end
	return true
end

-- ============ automatico: pump global ============
local acc, lightAcc = 0, 0
function RX.pump(dt)
	-- relogio do mundo (tempo real acelerado)
	S.clock = (S.clock + dt * 24 / S.dayScale) % 24
	acc = acc + dt
	lightAcc = lightAcc + dt
	-- adapta entidades em fatiamento (D-O15: nao gasta CPU desnecessario)
	if acc >= 0.1 then
		local dtb = acc; acc = 0
		-- camera: workspace.CurrentCamera (client e server-safe fallback)
		local cam = workspace.CurrentCamera
		if cam then cameraPos = cam.CFrame.Position end
		local n = 0
		for obj, ent in pairs(S.entities) do
			n = n + 1
			if (n + S.learnRounds) % 3 == 0 then -- 1/3 por tick (~30Hz -> 10Hz efetivo)
				stepD(ent, dtb * 3)
				if materialize(ent) then S.stats.adapted = S.stats.adapted + 1 end
			end
		end
	end
	-- luz ambiental a cada ciclo curto (simulacao fisica do ceu)
	if WX and lightAcc > 1.5 and S.world then
		lightAcc = 0
		pcall(function()
			local w = S.world
			w.seasonClock = S.clock
			WX.ambientLight(w, S.clock)
		end)
	end
end

-- ============ criar mundo-planeta (RRW end-to-end) ============
function RX.createWorld(opts)
	opts = opts or {}
	local w = WX.new({
		seed = opts.seed or 7, size = opts.size or 1200, cell = opts.cell or 8,
		season = opts.season or 0.35, scale = opts.scale, plates = opts.plates,
		driftT = opts.driftT or 0,
	})
	S.world = w
	S.clock = opts.clock or 11.5
	S.dayScale = opts.dayScale or 60
	if opts.tier then RX.setTier(opts.tier) end
	return w
end

-- ============ materializar mundo (16K por celula + parallax orla) ============
-- construcao em CHUNKS de celulas com cor real por celula (render16k).
function RX.materializeWorld(w, opts)
	opts = opts or {}
	local size = opts.size or math.min(w.size, opts.maxSize or w.size)
	local cell = opts.cell or math.max(4, (w.tier or TX.TIERS.doze).detailCell * 2)
	local half = size / 2
	local parent = opts.parent or workspace:FindFirstChild("ArkherX_World") or Instance.new("Model")
	parent.Name = "ArkherX_World"
	parent.Parent = workspace
	local tier = w.tier or TX.TIERS.premium
	local count, made = 0, 0
	-- pass 1: base (celulas grandes - representacao macro, D baixo)
	for gx = -half, half - cell, cell * 2 do
		for gz = -half, half - cell, cell * 2 do
			local cx, cz = gx + cell, gz + cell
			local h = WX.height(w, cx, cz)
			if h > -40 then
				local p = Instance.new("Part")
				p.Anchored = true
				p.CanCollide = true
				local bi, cl = WX.biomeAt(w, cx, cz)
				local mat = WX.materialAt(w, cx, cz, cl, bi)
				local r16 = WX.render16k(w, cx, cz, mat)
				p.Color = r16.color
				p.Material = Enum.Material.SmoothPlastic
				p.Size = V3(cell * 2, math.max(1.4, h + 46), cell * 2)
				p.Position = V3(cx, (h - 46) / 2, cz)
				p.TopSurface = Enum.SurfaceType.Smooth
				p.Name = "WX_" .. mat
				p.Parent = parent
				made = made + 1
				RX.register(p, { kind = "terrain", matter = mat,
					importance = 0.5 + math.min(0.5, math.max(0, h) / 400),
					meta = { baseTransparency = 0, mat16k = function(px, pz)
						local b2, c2 = WX.biomeAt(w, px, pz)
						local m2 = WX.materialAt(w, px, pz, c2, b2)
						return WX.render16k(w, px, pz, m2).color
					end } })
			end
			count = count + 1
			if made >= (opts.budget or 900) then break end
		end
		if made >= (opts.budget or 900) then break end
	end
	-- pass 2: PARALLAX GEOMETRICO na orla das celulas significativas (D alto)
	local parTarget = math.min(opts.parallaxCount or 24, made)
	local shellsMade = 0
	for obj, ent in pairs(S.entities) do
		if shellsMade >= parTarget then break end
		if ent.kind == "terrain" and obj:IsA("BasePart") then
			local shells = WX.parallaxSeed(parent, obj, ent.matter, nil, (w.tier or TX.TIERS.premium).parallaxLayers)
			ent.meta.shells = shells
			shellsMade = shellsMade + 1
		end
	end
	-- stats
	S.stats.materialized = made
	return { cells = made, parallax = shellsMade, budget = opts.budget or 900 }
end

-- ============ tier global (hardware adaptation REAL) ============
function RX.setTier(id)
	S.tier = id
	TX.setTier(id)
	if S.world then S.world.tier = TX.TIERS[id] end
	return TX.activeTier
end

-- ============ auto-vegetacao + aprendizado (rosa dos ventos global) ============
function RX.autoVegetate(w, opts)
	opts = opts or {}
	local res = WX.vegetate(w, opts)
	S.stats.learnedVeg = res.placed
	-- aprendizado: guarda densidade real atingida p/ futuras rodadas
	local l = w.learn or {}
	l.vegPlaced = res.placed
	TX.memPut("wldx", "learn_" .. w.seed, l)
	return res
end

function RX.statsReport()
	local entN = 0
	for _ in pairs(S.entities) do entN = entN + 1 end
	local l = S.world and (S.world.learn or { runs = 0 })
	return {
		chain = TX.CHAIN, tier = S.tier, clock = string.format("%.1fh", S.clock),
		entities = entN, materialized = S.stats.materialized,
		parallaxActive = S.stats.parallaxAtivo, veg = S.stats.learnedVeg or 0,
		erodeRuns = (l and l.runs) or 0,
	}
end

function RX.start()
	S.running = true
	return "RRX rodando (RRW automatico)"
end

_G.ArkherRealityX = RX
return RX
