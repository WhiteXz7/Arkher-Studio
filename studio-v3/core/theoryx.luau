-- THEORY X — codificacao OPERACIONAL das teses ARKHER (TeseDosD.txt,
-- TeseDosDPromptReal.👑, REAL UES, UTS, ARKHER STUDIOS, FASE0):
--   REALIDADE -> CONHECIMENTO -> TESE DOS D -> REPRESENTACAO -> D-O15
--   -> RRW -> MATERIALIZACAO -> EXPERIENCIA
-- Leis: D funcional/fracionario/nao-hierarquico; D* = argmax(Q - C);
-- "nivel minimo de complexidade suficiente"; D-O15 = adaptador universal
-- da realidade (nao LOD barato); hysteresis p/ estabilidade; D preditivo.
-- Este modulo e a FONTE UNICA dos presets/orcamentos que TODO motor usa.

local TX = {}

-- ============ vetor D (sec. 78/79: multivetorial adaptativo) ============
-- Dv visual, Dp fisico, Db comportamental, Ds social, De economico, Dt temporal
function TX.dvec(dv, dp, db, ds, de, dt)
	return { dv = dv or 1, dp = dp or 1, db = db or 1, ds = ds or 1, de = de or 1, dt = dt or 1 }
end

-- ============ tiers D-O15 (hardware adaptation real, sec. 11) ============
-- budget = quanto de "realidade" materializar; NAO e Low/Medium/High bobo.
-- doze = padrao ARKHER premium (padrao ultra). luau = base leve.
TX.TIERS = {
	doze    = { id = "doze",    microReliefOctaves = 6, parallaxLayers = 7,  erosionDrops = 260, detailCell = 1,  vegDensity = 1.0, weatherHz = 4, shadowDetail = 1.0, pixelBudget = 1.0 },
	premium = { id = "premium", microReliefOctaves = 5, parallaxLayers = 5,  erosionDrops = 180, detailCell = 2,  vegDensity = 0.85, weatherHz = 3, shadowDetail = 0.85, pixelBudget = 0.85 },
	normal  = { id = "normal",  microReliefOctaves = 4, parallaxLayers = 3,  erosionDrops = 120, detailCell = 4,  vegDensity = 0.65, weatherHz = 2, shadowDetail = 0.6, pixelBudget = 0.65 },
	luau    = { id = "luau",    microReliefOctaves = 3, parallaxLayers = 2,  erosionDrops = 80,  detailCell = 6,  vegDensity = 0.45, weatherHz = 1, shadowDetail = 0.4, pixelBudget = 0.45 },
}
TX.activeTier = TX.TIERS.doze
function TX.setTier(id) TX.activeTier = assert(TX.TIERS[id], id); return TX.activeTier end

-- D* = argmax(Q - C): escolhe representacao minima suficiente (sec. 97-100)
-- importance 0..1 (percepcao), dist studs, budget livre
function TX.chooseD(importance, dist, budget)
	local imp = math.clamp(importance or 0.5, 0, 1)
	local att = 1 / (1 + math.max(0, dist or 0) / 220)
	local q = imp * (0.35 + 0.65 * att) * (budget or 1)
	-- hysteresis (sec. 82): sobe rapido, desce devagar
	if q > 0.72 then return 1.0
	elseif q > 0.52 then return 0.75
	elseif q > 0.3 then return 0.5
	elseif q > 0.12 then return 0.25
	else return 0.1 end
end

-- ============ RRW: materiais como MATERIA (nao PBR albedo/normal) ============
-- props reais: albedo base, rugosidade, granulacao, umidade, porosidade,
-- dureza, densidade, condutividade termica, cor de grão saturada, espessura
-- de camada de microrelieve (p/ PARALLAX geometrico real).
TX.MATTER = {
	rock     = { microAmp = 0.55, microFreq = 3.1, grain = 0.65, wetDark = 0.55, parallaxDepth = 0.55, colA = Color3.fromRGB(122, 116, 108), colB = Color3.fromRGB(74, 70, 65) },
	sand     = { microAmp = 0.22, microFreq = 6.0, grain = 0.95, wetDark = 0.6,  parallaxDepth = 0.3,  colA = Color3.fromRGB(214, 191, 150), colB = Color3.fromRGB(176, 148, 105) },
	grass    = { microAmp = 0.34, microFreq = 5.2, grain = 0.8,  wetDark = 0.5,  parallaxDepth = 0.34, colA = Color3.fromRGB(94, 148, 70),  colB = Color3.fromRGB(56, 104, 44) },
	soil     = { microAmp = 0.3,  microFreq = 4.4, grain = 0.85, wetDark = 0.62, parallaxDepth = 0.36, colA = Color3.fromRGB(131, 99, 66),  colB = Color3.fromRGB(92, 66, 44) },
	snow     = { microAmp = 0.26, microFreq = 4.8, grain = 0.5,  wetDark = 0.92, parallaxDepth = 0.42, colA = Color3.fromRGB(240, 246, 255), colB = Color3.fromRGB(206, 220, 240) },
	ice      = { microAmp = 0.14, microFreq = 7.5, grain = 0.25, wetDark = 0.95, parallaxDepth = 0.2,  colA = Color3.fromRGB(178, 214, 235), colB = Color3.fromRGB(120, 170, 205) },
	mud      = { microAmp = 0.4,  microFreq = 3.6, grain = 0.9,  wetDark = 0.5,  parallaxDepth = 0.44, colA = Color3.fromRGB(104, 79, 57),  colB = Color3.fromRGB(72, 52, 36) },
	lava     = { microAmp = 0.6,  microFreq = 2.6, grain = 0.7,  wetDark = 1,    parallaxDepth = 0.6,  colA = Color3.fromRGB(255, 91, 26),  colB = Color3.fromRGB(120, 26, 8) },
	scree    = { microAmp = 0.5,  microFreq = 5.6, grain = 0.8,  wetDark = 0.6,  parallaxDepth = 0.5,  colA = Color3.fromRGB(140, 128, 112), colB = Color3.fromRGB(96, 84, 70) },
	coral    = { microAmp = 0.65, microFreq = 3.4, grain = 0.8,  wetDark = 0.85, parallaxDepth = 0.65, colA = Color3.fromRGB(255, 160, 140), colB = Color3.fromRGB(200, 100, 90) },
}

-- ============ BIOMAS (Whittaker full + ESA WorldCover 11 + OpenLandMap 32) ============
-- campos: id, nome, T range(°C), P range(mm/ano), veg(densidade), trees slot
-- Coppen: Af Am Aw BWh BWk BSh BSk Csa Csb Cwa Cwb Cfa Cfb Cfc Dsa Dsb Dsc Dfa Dfb Dfc Dfd ET EF
TX.BIOMES = {
	{ id = 1,  kop = "Af",  name = "Floresta Equatorial",        t = { 22, 30 }, p = { 2000, 4000 }, veg = 1.0,  slot = "jungle_trees" },
	{ id = 2,  kop = "Am",  name = "Moncao Tropical",            t = { 20, 30 }, p = { 1500, 3000 }, veg = 0.95, slot = "monsoon_trees" },
	{ id = 3,  kop = "Aw",  name = "Savana Tropical",            t = { 18, 32 }, p = { 500, 1500 },  veg = 0.55, slot = "savanna_trees" },
	{ id = 4,  kop = "BWh", name = "Deserto Quente",             t = { 22, 45 }, p = { 0, 200 },     veg = 0.04, slot = "desert_shrubs" },
	{ id = 5,  kop = "BWk", name = "Deserto Frio",               t = { -5, 25 }, p = { 0, 250 },    veg = 0.03, slot = "cold_desert_shrubs" },
	{ id = 6,  kop = "BSh", name = "Estepe Quente",              t = { 18, 30 }, p = { 200, 500 },   veg = 0.3,  slot = "steppe_grass" },
	{ id = 7,  kop = "BSk", name = "Estepe Fria",                t = { 0, 20 },  p = { 200, 500 },   veg = 0.28, slot = "grass_steppe" },
	{ id = 8,  kop = "Csa", name = "Mediterraneo Seco",          t = { 10, 28 }, p = { 400, 900 },   veg = 0.5,  slot = "maquis" },
	{ id = 9,  kop = "Csb", name = "Mediterraneo Ameno",         t = { 8, 24 },  p = { 500, 1200 },  veg = 0.6,  slot = "maquis_soft" },
	{ id = 10, kop = "Cwa", name = "Subtropical Umido Seco",     t = { 10, 26 }, p = { 700, 1600 },  veg = 0.7,  slot = "subtropical" },
	{ id = 11, kop = "Cwb", name = "Altitude Tropical",          t = { 5, 20 },  p = { 700, 1500 },  veg = 0.65, slot = "paramo" },
	{ id = 12, kop = "Cfa", name = "Subtropical Umido",          t = { 8, 27 },  p = { 1000, 1800 }, veg = 0.8,  slot = "laurel_forest" },
	{ id = 13, kop = "Cfb", name = "Oceanico Temperado",         t = { 4, 20 },  p = { 800, 1600 },  veg = 0.75, slot = "temperate" },
	{ id = 14, kop = "Cfc", name = "Subpolar Oceanico",          t = { -3, 15 }, p = { 700, 1500 },  veg = 0.5,  slot = "subpolar" },
	{ id = 15, kop = "Dfa", name = "Continental Umido Quente",   t = { -15, 27 }, p = { 600, 1300 }, veg = 0.7,  slot = "mixed_forest" },
	{ id = 16, kop = "Dfb", name = "Continental Ameno",          t = { -25, 22 }, p = { 500, 1000 }, veg = 0.65, slot = "conifer_mixed" },
	{ id = 17, kop = "Dfc", name = "Subartico Taiga",            t = { -35, 18 }, p = { 300, 800 },  veg = 0.55, slot = "taiga" },
	{ id = 18, kop = "Dfd", name = "Subartico Extremo",          t = { -45, 15 }, p = { 250, 600 },  veg = 0.4,  slot = "larch" },
	{ id = 19, kop = "ET",  name = "Tundra",                     t = { -25, 10 }, p = { 150, 500 },  veg = 0.2,  slot = "tundra_moss" },
	{ id = 20, kop = "EF",  name = "Gelo Permanente",            t = { -60, 0 },  p = { 0, 300 },    veg = 0,    slot = "none" },
	{ id = 21, kop = "MAN", name = "Manguezal (ESA 95)",         t = { 20, 32 }, p = { 1000, 4000 }, veg = 0.85, slot = "mangrove" },
	{ id = 22, kop = "WET", name = "Alagado (ESA 90)",           t = { 5, 30 },  p = { 800, 3000 },  veg = 0.7,  slot = "wetland" },
	{ id = 23, kop = "CMP", name = "Campos (ESA 30)",            t = { 10, 26 }, p = { 900, 1800 },  veg = 0.5,  slot = "grass" },
	{ id = 24, kop = "ALP", name = "Alpino/Nival Alto",          t = { -20, 5 }, p = { 400, 2000 },  veg = 0.1,  slot = "alpine" },
	{ id = 25, kop = "KAR", name = "Carste/Dolomita",            t = { 8, 22 },  p = { 600, 1400 },  veg = 0.35, slot = "karst" },
	{ id = 26, kop = "VOL", name = "Vulcanico Ativo",            t = { 10, 60 }, p = { 400, 1600 },  veg = 0.15, slot = "pioneer" },
	{ id = 27, kop = "OAS", name = "Oasis",                      t = { 18, 40 }, p = { 50, 300 },    veg = 0.6,  slot = "palm_oasis" },
	{ id = 28, kop = "RIP", name = "Mata Ciliar/Riparia",        t = { 10, 28 }, p = { 600, 2000 },  veg = 0.9,  slot = "riparian" },
	{ id = 29, kop = "PEA", name = "Turfeira/Bog",               t = { -5, 16 }, p = { 600, 1600 },  veg = 0.5,  slot = "bog" },
	{ id = 30, kop = "ATF", name = "Atol/Recristal Coral",       t = { 24, 32 }, p = { 1200, 3500 }, veg = 0.45, slot = "atoll" },
	{ id = 31, kop = "BDL", name = "Badlands",                   t = { 5, 38 },  p = { 100, 400 },   veg = 0.06, slot = "badlands" },
	{ id = 32, kop = "PLA", name = "Playa/Salar",                t = { -10, 45 }, p = { 0, 150 },    veg = 0.0,  slot = "none" },
}
function TX.biomeById(id) return TX.BIOMES[math.max(1, math.min(#TX.BIOMES, id))] end

-- Whittaker: T x P -> bioma (modelo real de triangulo, refinado p/ 32)
function TX.whittaker(tempC, precipMm, elev, extra)
	local t2 = tempC; local p = precipMm
	if (elev or 0) > 3800 then return 24 end
	if t2 < -2 then
		if p < 150 then return 20 else return 19 end
	end
	if t2 < 1 then
		if p < 260 then return 17 else return 14 end
	end
	if p < 220 then
		if t2 > 18 then return extra and 27 or 4 else return 5 end
	end
	if p < 520 then
		if t2 > 18 then return 6 else return 7 end
	end
	if t2 > 22 then
		if p > 1900 then return 1 elseif p > 1300 then return 2 else return 3 end
	end
	if t2 > 17 then
		if p > 1400 then return 12 elseif p > 900 then return 10 else return 8 end
	end
	if t2 > 10 then
		if p > 1200 then return 12 elseif p > 700 then return 13 else return (extra and 29) or 8 end
	end
	if t2 > 4 then
		if p > 1000 then return 15 else return 16 end
	end
	if p > 600 then return 17 else return 18 end
end

-- ============ escala real RRW (1 stud = K metros) ============
TX.SCALES = {
	studio = { studToM = 0.28, seaLevel = 10, gravity = 196.2 },      -- Roblox: 1 stud = 28cm, g=196.2 st/s2
	paisagem = { studToM = 4, seaLevel = 10 },                         -- 1 stud = 4m (mapas regionais)
	planeta = { studToM = 640, seaLevel = 10 },                        -- 1 stud = 640m (escala planetaria)
}

-- ============ persistencia D-O15 (memory layers da tese complemento 14) ============
TX.MEM = { active = {}, project = {}, history = {} }
function TX.memPut(ns, key, val) TX.MEM.project[ns .. ":" .. key] = val end
function TX.memGet(ns, key) return TX.MEM.project[ns .. ":" .. key] end

-- ============ chain canonica (REAL UES final) ============
TX.CHAIN = { "REALIDADE", "CONHECIMENTO", "TESE_DOS_D", "REPRESENTACAO",
	"D_O15", "RRW", "MATERIALIZACAO", "EXPERIENCIA" }

_G.ArkherTheoryX = TX
return TX
