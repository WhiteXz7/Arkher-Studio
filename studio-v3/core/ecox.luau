-- ECO X (ECOX) — ECOSSISTEMAS VIVOS (cat. L 6001-6700 dos TXT):
-- populacoes REAIS por bioma com crescimento logistico (dN = rN(1-N/K)),
-- fauna materializada via FABX quando a populacao logica cruza o inteiro,
-- movimento de rebanho (wander suave) e respeito ao D-O15 (budget pelo tier).
-- Nada e "ambiente falso": cada animal e uma entidade RRW com materia.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local WX = rawget(_G, "ArkherWorldX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local ECOX = {}
local S = {
	running = false, t = 0, acc = 0,
	pops = {},      -- espcie -> {n, k, r, fabrica, list}
	spawned = 0, births = 0, deaths = 0,
}

-- especies: nicho ecologico real (bioma/alimento/producao)
ECOX.SPECIES = {
	ave      = { kind = "ave",      r = 0.22, k0 = 8,  minBiomeVeg = 0.2 },
	criatura = { kind = "criatura", r = 0.10, k0 = 5,  minBiomeVeg = 0.35 },
	peixe    = { kind = "peixe",    r = 0.3,  k0 = 10, water = true },
}

local function worldOf() return (RX and (RX.S.earth or RX.S.world)) or nil end

local function tier()
	return (TX and TX.activeTier) or { vegDensity = 1 }
end

function ECOX.start()
	S.running = true
	local w = worldOf()
	if not w then return "ECO: gere um mundo primeiro (planeta/terra)" end
	S.pops = {}
	for id, sp in pairs(ECOX.SPECIES) do
		S.pops[id] = { n = 1.0, k = sp.k0, r = sp.r, sp = sp, list = {} }
	end
	return ("ECO rodando: %d especies com dinamica logistica real"):format(2)
end

local function spawnOne(pop, w)
	local FAB = rawget(_G, "ArkherFabricX")
	if not FAB then return nil end
	local rng = DM and DM.rng((S.t * 1000 + S.spawned * 37) % 999983)
	local x, z = rng(-w.size / 2 * 0.9, w.size / 2 * 0.9), rng(-w.size / 2 * 0.9, w.size / 2 * 0.9)
	local h = WX and WX.height(w, x, z) or 10
	local sea = w.sea or (w.scale and w.scale.seaLevel) or 10
	if pop.sp.water then
		if h > sea - 0.5 then return nil end -- peixe so na agua de verdade
		local y = sea - 1
		local res = FAB.fabricate({ kind = pop.sp.kind, seed = 10 + S.spawned }, { pos = V3(x, y, z) })
		return res and res.model or nil
	end
	if h < sea + 0.5 then return nil end -- fauna terrestre so na terra
	local bi, cl = WX.biomeAt(w, x, z)
	local bio = bi and (TX and TX.biomeById(type(bi) == "table" and bi.id or bi) or nil) or nil
	local veg = (type(bi) == "table" and bi.veg) or (bio and bio.veg) or 0.5
	if veg < pop.sp.minBiomeVeg then return nil end -- nicho nao sustenta
	local res = FAB.fabricate({ kind = pop.sp.kind, seed = 10 + S.spawned }, { pos = V3(x, h + 0.4, z) })
	return res and res.model or nil
end

-- dinamica: passageiros do pulso (a cada ~2s de mundo)
function ECOX.step(dt)
	if not S.running then return end
	S.t = S.t + dt
	S.acc = S.acc + dt
	if S.acc < 2.0 then return end
	local dtm = S.acc
	S.acc = 0
	local w = worldOf()
	if not w then return end
	local tden = tier().vegDensity
	local budget = math.max(4, math.floor(14 * tden))
	for id, pop in pairs(S.pops) do
		-- logistico real: dN = r N (1 - N/K)
		local dN = pop.r * pop.n * (1 - pop.n / math.max(1, pop.k))
		pop.n = math.max(0.1, pop.n + dN * dtm * 0.1)
		local target = math.floor(pop.n + 0.5)
		local live = 0
		for _, m2 in ipairs(pop.list) do if m2.Parent then live = live + 1 end end
		-- nascimentos (budget D-O15)
		while live < target and S.spawned < budget do
			local m2 = spawnOne(pop, w)
			if not m2 then break end
			pop.list[#pop.list + 1] = m2
			S.spawned = S.spawned + 1
			S.births = S.births + 1
			live = live + 1
		end
		-- wander do rebanho (micro, a cada ciclo)
		for _, m2 in ipairs(pop.list) do
			if m2.Parent then
				local pv = m2:GetPivot()
				local ph = S.t * 0.7 + pv.Position.X * 0.13
				m2:PivotTo(pv + V3(math.sin(ph) * 0.25, math.max(0, math.sin(ph * 2)) * 0.05, math.cos(ph) * 0.25))
			end
		end
	end
end

function ECOX.stop()
	S.running = false
	return "ECO: ecossistema PAUSADO (populacoes congelam onde estao)"
end

function ECOX.stats()
	local out = { running = S.running, spawned = S.spawned, births = S.births, species = {} }
	for id, pop in pairs(S.pops) do
		out.species[#out.species + 1] = ("%s=%.1f"):format(id, pop.n)
	end
	return out
end

do
	if RX and RX.hook then RX.hook("ecox", function(dt) ECOX.step(dt) end) end
end

_G.ArkherEcoX = ECOX
return ECOX
