--[[ ARKHER V4 — KIT C (ModuleScript) — DMATH + TERRAIN X (custom) + WATER X (custom) ]]
-- Motores proprios RRW: nao usam Terrain nem agua do Roblox. Requer o Kit A.
-- Instala em: ReplicatedStorage.ArkherV3.ArkherKit_C
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro.")
	end
	require(a)
end
_arkherLoadKitA()

do
--[[ ARKHER — D-MATH: camada matematica de campos (fundamento RRW) ]]
-- "Qual D e necessario para representar o problema?" — aqui ficam as
-- representacoes continuas discretizadas: ruido deterministico, campos
-- escalares, curvas e classificadores fisicos (Whittaker). Tudo DETERMINISTICO
-- por semente: a mesma realidade, a mesma materializacao, em qualquer D-O15.
-- Sem bitwise ops (compatibilidade total Lua 5.1 / Luau / shim de testes).
ArkherDM = ArkherDM or {}
local M = ArkherDM

local floor, ceil = math.floor, math.ceil
local abs, sqrt, exp = math.abs, math.sqrt, math.exp
local sin, cos, pi = math.sin, math.cos, math.pi

-- =============== PRIMITIVAS ===============
function M.clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
function M.lerp(a, b, t) return a + (b - a) * t end
function M.smoothstep(t) t = M.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
function M.smootherstep(t) t = M.clamp(t, 0, 1) return t * t * t * (t * (t * 6 - 15) + 10) end
function M.remap(v, a, b, c, d) return c + (d - c) * ((v - a) / ((b - a) ~= 0 and (b - a) or 1)) end
function M.gauss(d, r) if r <= 0 then return 0 end local q = d / r return exp(-q * q * 4.5) end
function M.falloff(d, r, kind)
	local t = M.clamp(1 - d / (r > 0 and r or 1), 0, 1)
	if kind == "linear" then return t
	elseif kind == "gaussian" then return M.gauss(d, r)
	elseif kind == "cosine" then return 0.5 + 0.5 * cos(pi * M.clamp(d / (r > 0 and r or 1), 0, 1))
	elseif kind == "sharp" then return t >= 0.5 and 1 or 0
	else return t * t * (3 - 2 * t) end -- "smooth"
end

-- =============== RNG / HASH DETERMINISTICO ===============
-- hash de 2 inteiros -> [0,1) usando mistura multiplicativa (Park-Miller bits)
local i2556 = 2147483647
local function mix(n)
	n = n % i2556
	n = (n * 16807) % i2556
	n = (n * 48271 + 11) % i2556
	n = (n * 69621) % i2556
	return n / i2556
end
function M.hash2(x, y, seed)
	seed = seed or 0
	local n = (floor(x) * 374761393 + floor(y) * 668265263 + floor(seed) * 974634211) % 2000000011
	return mix(abs(n))
end
function M.hash3(x, y, z, seed)
	seed = seed or 0
	local n = (floor(x) * 374761393 + floor(y) * 668265263 + floor(z) * 2246822519 % 999999937 + floor(seed) * 3266489917 % 999999937) % 2000000011
	return mix(abs(n))
end
-- rng com estado (streams independentes por semente)
function M.rng(seed)
	local s = (floor(seed or 1) % i2556); if s <= 0 then s = 1 end
	return function(a, b)
		s = (s * 16807) % i2556
		local u = s / i2556
		if a and b then return a + (b - a) * u end
		if a then return u * a end
		return u
	end
end

-- =============== RUIDO ===============
-- value noise 2D
function M.vnoise2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local xf, yf = x - xi, y - yi
	local u, v = M.smootherstep(xf), M.smootherstep(yf)
	local a = M.hash2(xi, yi, seed)
	local b = M.hash2(xi + 1, yi, seed)
	local c = M.hash2(xi, yi + 1, seed)
	local d = M.hash2(xi + 1, yi + 1, seed)
	return M.lerp(M.lerp(a, b, u), M.lerp(c, d, u), v)
end
-- gradient (Perlin) noise 2D — 8 gradientes por hash
local GRAD = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.7071, 0.7071 }, { -0.7071, 0.7071 }, { 0.7071, -0.7071 }, { -0.7071, -0.7071 } }
function M.gnoise2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local xf, yf = x - xi, y - yi
	local function dot(ix, iy, dx, dy)
		local g = GRAD[floor(M.hash2(ix, iy, seed) * 8) + 1]
		return g[1] * dx + g[2] * dy
	end
	local u, v = M.smootherstep(xf), M.smootherstep(yf)
	local n00 = dot(xi, yi, xf, yf)
	local n10 = dot(xi + 1, yi, xf - 1, yf)
	local n01 = dot(xi, yi + 1, xf, yf - 1)
	local n11 = dot(xi + 1, yi + 1, xf - 1, yf - 1)
	-- escala p/ [-1,1]
	return M.lerp(M.lerp(n00, n10, u), M.lerp(n01, n11, u), v) * 1.4142
end
-- 1D (ondas / audio / vento)
function M.vnoise1(x, seed)
	local xi = floor(x); local xf = x - xi; local u = M.smootherstep(xf)
	return M.lerp(M.hash2(xi, 17, seed), M.hash2(xi + 1, 17, seed), u)
end
-- fBm generico (func = "g"|"v"|"ridged"|"billow")
function M.fbm2(x, y, opts)
	opts = opts or {}
	local oct, lac, gain = opts.octaves or 5, opts.lacunarity or 2, opts.gain or 0.5
	local seed, fn = opts.seed or 0, opts.fn or "g"
	local amp, freq, sum, norm = 1, opts.frequency or 1, 0, 0
	for i = 1, oct do
		local v
		if i > 1 then freq = freq * lac; amp = amp * gain end
		if fn == "v" then v = M.vnoise2(x * freq, y * freq, seed + i * 131) * 2 - 1
		elseif fn == "ridged" then v = 1 - abs(M.gnoise2(x * freq, y * freq, seed + i * 131))
		elseif fn == "billow" then v = abs(M.gnoise2(x * freq, y * freq, seed + i * 131)) * 2 - 1
		else v = M.gnoise2(x * freq, y * freq, seed + i * 131) end
		sum = sum + v * amp
		norm = norm + amp
	end
	return sum / norm -- ~[-1,1]
end
-- domain warp: distorce o dominio antes de amostrar (costas organicas, montanhas reais)
function M.warp2(x, y, opts)
	opts = opts or {}
	local str, seed = opts.strength or 4, opts.seed or 0
	local wx = M.gnoise2(x * 0.5 + 31.4, y * 0.5 + 71.7, seed) * str
	local wy = M.gnoise2(x * 0.5 + 89.2, y * 0.5 + 13.9, seed) * str
	return x + wx, y + wy
end
-- Worley / celular (F1 e F2-F1) — crateras, escamas, celulas, espuma
function M.worley2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local f1, f2 = 1e9, 1e9
	for oy = -1, 1 do
		for ox = -1, 1 do
			local cx, cy = xi + ox, yi + oy
			local px = cx + M.hash2(cx, cy, seed or 0)
			local py = cy + M.hash2(cx, cy, (seed or 0) + 77)
			local dx, dy = px - x, py - y
			local d = sqrt(dx * dx + dy * dy)
			if d < f1 then f2 = f1; f1 = d elseif d < f2 then f2 = d end
		end
	end
	return f1, f2 - f1
end

-- =============== CURVAS / GRADE ===============
function M.catmullRom(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end
-- amostragem bilinear de grade heights (1-based, (h-1)*w+1)
function M.bilinear(grid, w, h, gx, gy)
	gx = M.clamp(gx, 1, w - 0.001); gy = M.clamp(gy, 1, h - 0.001)
	local x0, y0 = floor(gx), floor(gy)
	local fx, fy = gx - x0, gy - y0
	local i = (y0 - 1) * w + x0
	local a, b, c, d = grid[i], grid[i + 1], grid[i + w], grid[i + w + 1]
	return M.lerp(M.lerp(a, b, fx), M.lerp(c, d, fx), fy)
end
-- gradiente numerico de grade (para erosao / normais)
function M.gradient(grid, w, h, gx, gy, spacing)
	spacing = spacing or 1
	local gxL, gxR = M.bilinear(grid, w, h, gx - 1, gy), M.bilinear(grid, w, h, gx + 1, gy)
	local gyU, gyD = M.bilinear(grid, w, h, gx, gy - 1), M.bilinear(grid, w, h, gx, gy + 1)
	return (gxL - gxR) / (2 * spacing), (gyU - gyD) / (2 * spacing)
end

-- =============== FISICA AMBIENTAL ===============
-- Classificador de Whittaker (temperatura C x precipitacao cm/ano) -> bioma
-- Tese dos D: mesma realidade (clima) -> representacao semantica (bioma).
M.BIOMES = {
	"tundra", "taiga", "esteppe_fria", "pradaria", "deserto_frio",
	"savana", "deserto_quente", "chaparral", "floresta_temperada",
	"pantano", "floresta_tropical", "floresta_equatorial", "alpino", "gelo",
}
function M.whittaker(tempC, precipCm)
	if tempC <= -12 then return "gelo" end
	if tempC < 0 then
		if precipCm < 40 then return "tundra" else return "taiga" end
	end
	if tempC < 8 then
		if precipCm < 30 then return "esteppe_fria"
		elseif precipCm < 80 then return "pradaria"
		else return "taiga" end
	end
	if tempC < 17 then
		if precipCm < 25 then return "deserto_frio"
		elseif precipCm < 55 then return "chaparral"
		elseif precipCm < 130 then return "floresta_temperada"
		else return "pantano" end
	end
	if tempC < 26 then
		if precipCm < 20 then return "deserto_quente"
		elseif precipCm < 70 then return "savana"
		else return "floresta_tropical" end
	end
	if precipCm < 30 then return "deserto_quente"
	elseif precipCm < 120 then return "floresta_tropical"
	else return "floresta_equatorial" end
end
-- orvalho/efeito orografico simples: sombra de chuva a sotavento
function M.rainShadow(here, windwardAlt)
	local drop = windwardAlt - here
	if drop > 0 then return M.clamp(1 - drop / 400, 0.25, 1) end
	return 1
end
-- barometrica: pressao aproximada por altitude (m)
function M.pressureAt(altM) return 101325 * exp(-altM / 8434) end
-- ponto de orvalho approx (Magnus)
function M.dewPoint(tempC, rh)
	local a, b = 17.27, 237.7
	local alpha = ((a * tempC) / (b + tempC)) + math.log(M.clamp(rh, 0.01, 1))
	return (b * alpha) / (a - alpha)
end

M._version = "1.0.0"
end

do
--[[ ARKHER TERRAIN X (ATX) — motor de terreno CUSTOM (nao usa Terrain do Roblox) ]]
-- RRW: realidade (geologia, clima, hidrologia) -> representacao (campos por
-- chunk) -> D-O15 (LOD adaptativo) -> materializacao (parts no workspace).
-- Tudo deterministico por semente: o mesmo mundo renasce igual em qualquer D.
--
-- Capacidades:
--  * mundo infinito em chunks (geracao procedural sob demanda)
--  * geofisica: continentes, montanhas ridged, domain warp, crateras, mesetas
--  * erosao REAL: hidraulica (droplet) + termica (talus) + deposicao
--  * hidrologia: rede de rios por acumulacao de fluxo (D8), lagos por
--    preenchimento de depressoes, praias por nivel do mar
--  * clima: temperatura (latitude+altitude), precipitacao (fbm+sombra de
--    chuva), biomas pelo diagrama de Whittaker (14 biomas)
--  * 24 MATERIAIS COM PROPRIEDADES FISICAS (RRW "materia", nao albedo+normal):
--    densidade, dureza, porosidade, coesao, cor, termica, umidade alvo
--  * escultura: 10 operacoes de pincel x 5 falloffs (gauss/suave/coseno/linear/seco)
--  * materializacao adaptativa: chunks de parts, LOD por distancia/orcamento
--  * persistencia: export/import JSON compacto (run-length), undo-friendly
--  * consultas: heightAt/normalAt/materialAt/biomeAt/waterDepthAt + raycast plano
ArkherTerrainX = ArkherTerrainX or {}
local ATX = ArkherTerrainX
local DM = ArkherDM
local floor, ceil, abs = math.floor, math.ceil, math.abs
local sqrt, clamp = math.sqrt, DM.clamp
local lerp = DM.lerp

local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end

-- ================= MATERIAIS (RRW materia) =================
-- props fisicas: dens(kg/L-ish), dureza(Mohs-ish), porosidade, coesao,
-- termica (inercia), cor radiometria simplificada {r,g,b}, solubilidade
ATX.MATERIALS = {
	{ id = "rocha", nm = "Rocha", dens = 2.65, dureza = 6, poros = 0.02, coesao = 0.9, termica = 0.8, cor = { 122, 118, 113 } },
	{ id = "basalto", nm = "Basalto", dens = 2.9, dureza = 6.5, poros = 0.03, coesao = 0.95, termica = 0.85, cor = { 74, 74, 78 } },
	{ id = "granito", nm = "Granito", dens = 2.65, dureza = 6.8, poros = 0.015, coesao = 0.95, termica = 0.75, cor = { 158, 146, 138 } },
	{ id = "cascalho", nm = "Cascalho", dens = 1.8, dureza = 3, poros = 0.35, coesao = 0.2, termica = 0.5, cor = { 139, 131, 120 } },
	{ id = "areia", nm = "Areia", dens = 1.6, dureza = 2, poros = 0.4, coesao = 0.1, termica = 0.45, cor = { 219, 200, 152 } },
	{ id = "areia_des", nm = "Areia do Deserto", dens = 1.55, dureza = 2, poros = 0.42, coesao = 0.08, termica = 0.4, cor = { 226, 191, 122 } },
	{ id = "terra", nm = "Terra", dens = 1.5, dureza = 2.5, poros = 0.35, coesao = 0.45, termica = 0.55, cor = { 122, 92, 62 } },
	{ id = "argila", nm = "Argila", dens = 1.9, dureza = 2, poros = 0.45, coesao = 0.7, termica = 0.6, cor = { 168, 122, 96 } },
	{ id = "grama", nm = "Grama", dens = 1.35, dureza = 1.5, poros = 0.5, coesao = 0.5, termica = 0.5, cor = { 96, 168, 74 } },
	{ id = "prado", nm = "Prado", dens = 1.35, dureza = 1.5, poros = 0.52, coesao = 0.5, termica = 0.5, cor = { 124, 186, 84 } },
	{ id = "floresta", nm = "Solo de Floresta", dens = 1.3, dureza = 1.5, poros = 0.55, coesao = 0.55, termica = 0.55, cor = { 74, 128, 58 } },
	{ id = "lama", nm = "Lama", dens = 1.4, dureza = 1, poros = 0.6, coesao = 0.3, termica = 0.5, cor = { 104, 84, 60 } },
	{ id = "neve", nm = "Neve", dens = 0.35, dureza = 1, poros = 0.7, coesao = 0.15, termica = 0.2, cor = { 238, 242, 248 } },
	{ id = "gelo", nm = "Gelo", dens = 0.92, dureza = 1.5, poros = 0.0, coesao = 0.8, termica = 0.15, cor = { 188, 218, 235 } },
	{ id = "cinza", nm = "Cinza Vulcanica", dens = 1.1, dureza = 1, poros = 0.6, coesao = 0.12, termica = 0.5, cor = { 96, 94, 90 } },
	{ id = "lava", nm = "Lava Resfriada", dens = 2.8, dureza = 5.5, poros = 0.05, coesao = 0.9, termica = 0.9, cor = { 58, 48, 46 } },
	{ id = "sal", nm = "Salina", dens = 2.16, dureza = 2.5, poros = 0.05, coesao = 0.4, termica = 0.5, cor = { 236, 232, 218 } },
	{ id = "coral", nm = "Coral", dens = 1.9, dureza = 3, poros = 0.5, coesao = 0.3, termica = 0.5, cor = { 232, 138, 118 } },
	{ id = "rocha_prof", nm = "Rocha Profunda", dens = 3.0, dureza = 7, poros = 0.01, coesao = 1, termica = 0.9, cor = { 54, 54, 58 } },
	{ id = "turfa", nm = "Turfa", dens = 0.9, dureza = 1, poros = 0.8, coesao = 0.2, termica = 0.4, cor = { 82, 68, 44 } },
	{ id = "arenito", nm = "Arenito", dens = 2.3, dureza = 5, poros = 0.15, coesao = 0.7, termica = 0.65, cor = { 202, 158, 104 } },
	{ id = "calcario", nm = "Calcario", dens = 2.5, dureza = 4, poros = 0.12, coesao = 0.75, termica = 0.7, cor = { 214, 208, 188 } },
	{ id = "obsidiana", nm = "Obsidiana", dens = 2.4, dureza = 5.5, poros = 0, coesao = 0.95, termica = 0.8, cor = { 36, 34, 40 } },
	{ id = "enxofre", nm = "Enxofre", dens = 2.07, dureza = 2, poros = 0.1, coesao = 0.3, termica = 0.35, cor = { 220, 196, 66 } },
}
ATX.MAT_INDEX = {}
for i, m in ipairs(ATX.MATERIALS) do m.index = i; ATX.MAT_INDEX[m.id] = i end

-- mapa bioma -> material de superficie
ATX.BIOME_MAT = {
	tundra = "cascalho", taiga = "floresta", esteppe_fria = "grama", pradaria = "prado",
	deserto_frio = "cascalho", savana = "areia", deserto_quente = "areia_des",
	chaparral = "grama", floresta_temperada = "floresta", pantano = "lama",
	floresta_tropical = "floresta", floresta_equatorial = "turfa",
	alpino = "rocha", gelo = "gelo",
}

ATX.PRESETS = {
	continentes = { label = "Continentes", cont = 1.0, mont = 1.0, hill = 0.45, det = 0.35, sea = 0, warp = 5, caves = 0 },
	ilhas = { label = "Arquipelago", cont = 0.8, mont = 0.5, hill = 0.3, det = 0.4, sea = -4, warp = 9, islands = true },
	montanhas = { label = "Cordilheira", cont = 1.1, mont = 1.9, hill = 0.5, det = 0.5, sea = -10, warp = 6, caves = 1 },
	canyon = { label = "Canyon", cont = 0.9, mont = 0.4, hill = 0.2, det = 0.4, sea = -14, warp = 3, terrace = 7, caves = 0.8 },
	dunas = { label = "Dunas", cont = 0.6, mont = 0.05, hill = 0.9, det = 0.6, sea = -9, warp = 2, dunes = true, tempB = 14, humidB = -40 },
	meseta = { label = "Mesetas", cont = 1.0, mont = 0.8, hill = 0.3, det = 0.3, sea = -12, warp = 4, terrace = 11 },
	vulcao = { label = "Vulcao", cont = 0.8, mont = 1.4, hill = 0.3, det = 0.4, sea = -8, warp = 4, volcano = true, caves = 0.9 },
	polar = { label = "Polar", cont = 0.9, mont = 0.9, hill = 0.4, det = 0.3, sea = -3, warp = 4, tempB = -34, humidB = -10 },
	pantanal = { label = "Pantanal", cont = 0.7, mont = 0.08, hill = 0.2, det = 0.5, sea = -1.5, warp = 2, tempB = 12, humidB = 55, lakes = true },
	taiga = { label = "Taiga", cont = 1.0, mont = 0.7, hill = 0.6, det = 0.4, sea = -6, warp = 7, tempB = -14, humidB = 20 },
}

local World = {}
World.__index = World

-- world:worldToCell(studs) -> cell coords (frac)
local function studs2cell(self, x, z) return x / self.cell + 0.5, z / self.cell + 0.5 end

function ATX.new(opts)
	opts = opts or {}
	local w = setmetatable({}, World)
	w.seed = floor(opts.seed or 1337)
	w.cell = opts.cell or 8 -- studs por celula
	w.chunkCells = opts.chunkCells or 16 -- celulas por lado do chunk
	w.preset = opts.preset or "continentes"
	w.params = {}
	local p = ATX.PRESETS[w.preset] or ATX.PRESETS.continentes
	for k, v in pairs(p) do w.params[k] = v end
	-- o preset define o nivel do mar quando nao passado explicitamente
	w.seaLevel = opts.seaLevel or w.params.sea or 0
	if opts.params then for k, v in pairs(opts.params) do w.params[k] = v end end
	w.chunks = {}
	w.rivers = {} -- lista de celulas fluviais {cx,cz,acc}
	w.lakes = {} -- mapa "cx,cz" -> depth
	w.scultCount = 0
	w.materialized = nil -- Model no workspace
	w.partsCount = 0
	w.stats = { gen = 0, cells = 0, erosions = 0, droplets = 0 }
	return w
end

-- ================= GERACAO (campos fisicos) =================
function World:baseElevation(wx, wz, P)
	P = P or self.params
	-- domain warp organico
	local qx, qz = DM.warp2(wx / 40, wz / 40, { strength = (P.warp or 4) / 40, seed = self.seed })
	qx, qz = qx * 40, qz * 40
	local cont = DM.fbm2(qx / 96, qz / 96, { octaves = 5, seed = self.seed, fn = "g" })
	cont = cont * 0.5 + 0.5
	local mask = DM.smoothstep((cont - 0.52) / 0.2)
	if P.islands then mask = DM.smoothstep((cont - 0.56) / 0.3) end
	local ridge = DM.fbm2(qx / 44, qz / 44, { octaves = 6, seed = self.seed + 11, fn = "ridged" })
	ridge = ridge * ridge * mask
	local detail = DM.fbm2(qx / 14, qz / 14, { octaves = 4, seed = self.seed + 23 }) * (P.det or 0.35) * 6
	local hills = DM.fbm2(qx / 30, qz / 30, { octaves = 4, seed = self.seed + 37 }) * (P.hill or 0.4) * 8
	local e = (cont - 0.45) * (P.cont or 1) * 46 + ridge * (P.mont or 1) * 34 + hills + detail - 6
	if P.dunes then
		local wv = math.abs(DM.gnoise2((qx + qz * 0.6) / 18, qz / 40, self.seed + 55))
		e = -4 + wv * 16 + detail * 0.5
	end
	if P.volcano then
		local d = sqrt(qx * qx + qz * qz) / 140
		local cone = clamp(1 - d, 0, 1)
		e = e + cone * 62 - (DM.smoothstep(clamp(1 - d * 6, 0, 1)) * 18) -- cratera no topo
	end
	if P.terrace then
		local t = P.terrace
		local f = floor(e / t + 0.5) * t
		e = lerp(e, f, 0.72) + (e - f) * 0.28
	end
	return e
end

function World:climate(wx, wz, elev)
	local P = self.params
	-- temperatura: base quente, -latitude (z longe do equador), -altitude
	local lat = abs(wz * self.cell) / 36 -- graus-ish
	local temp = 27 - lat * 0.55 - math.max(0, elev) * 0.55 + (P.tempB or 0)
	temp = temp + DM.gnoise2(wx / 60, wz / 60, self.seed + 91) * 3
	-- precipitacao: fbm + boost orografico (chuva de barlavento)
	local base = 60 + DM.fbm2(wx / 70 + 9.1, wz / 70 - 3.7, { octaves = 4, seed = self.seed + 77 }) * 55
	base = base + clamp(elev, 0, 60) * 1.1 + (P.humidB or 0)
	return temp, clamp(base, 2, 400)
end

function World:pickMaterial(wx, wz, h, tempC, precip)
	local sea = self.seaLevel
	if h < sea then
		local d = sea - h
		if d < 2.2 then
			local coral = DM.hash2(wx, wz, self.seed + 501)
			if coral > 0.86 and tempC > 18 then return ATX.MAT_INDEX.coral end
			return ATX.MAT_INDEX.areia
		elseif d < 14 then return ATX.MAT_INDEX.cascalho
		else return ATX.MAT_INDEX.rocha_prof end
	end
	if h < sea + 1.6 then return ATX.MAT_INDEX.areia end -- praia
	local biome = DM.whittaker(tempC, precip)
	local mid = ATX.MAT_INDEX[ATX.BIOME_MAT[biome]] or ATX.MAT_INDEX.grama
	-- altitude forca rocha/neve
	if h > 52 or tempC < -2 then
		if tempC < -2 then return ATX.MAT_INDEX.neve end
		if h > 64 then return DM.hash2(wx, wz, self.seed + 502) > 0.4 and ATX.MAT_INDEX.neve or ATX.MAT_INDEX.rocha end
		return ATX.MAT_INDEX.rocha
	end
	-- textura: variacao local (patches), ex: pedregulho em encosta
	local patch = DM.vnoise2(wx / 8, wz / 8, self.seed + 503)
	if patch > 0.78 then return ATX.MAT_INDEX.cascalho end
	return mid
end

function World:genChunk(cx, cz)
	local key = cx .. "," .. cz
	if self.chunks[key] then return self.chunks[key] end
	local n = self.chunkCells
	local h = {}
	local gn = n + 1
	for j = 1, gn do
		for i = 1, gn do
			local wx = cx * n + i - 1
			local wz = cz * n + j - 1
			h[(j - 1) * gn + i] = self:baseElevation(wx, wz)
		end
	end
	local mat, wet, biome = {}, {}, {}
	for j = 1, n do
		for i = 1, n do
			local wx = cx * n + i - 0.5
			local wz = cz * n + j - 0.5
			local e = (h[(j - 1) * gn + i] + h[(j - 1) * gn + i + 1] + h[j * gn + i] + h[j * gn + i + 1]) / 4
			local tC, pr = self:climate(wx, wz, e)
			mat[(j - 1) * n + i] = self:pickMaterial(wx, wz, e, tC, pr)
			wet[(j - 1) * n + i] = pr / 400
			biome[(j - 1) * n + i] = DM.whittaker(tC, pr)
		end
	end
	local ch = { cx = cx, cz = cz, h = h, mat = mat, wet = wet, biome = biome, dirty = true, sculpted = false }
	self.chunks[key] = ch
	self.stats.gen = self.stats.gen + 1
	self.stats.cells = self.stats.cells + n * n
	return ch
end

function World:chunkKeyOf(gx, gz)
	local n = self.chunkCells
	local cx = floor((gx - 1) / n)
	local cz = floor((gz - 1) / n)
	return cx, cz, cx .. "," .. cz
end

-- ================= CONSULTAS (RRW: leitura da realidade) =================
function World:heightAtCell(gx, gz) -- celulas, amostragem bilinear auto-gen
	local cx, cz, key = self:chunkKeyOf(floor(gx) + 1, floor(gz) + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = gx - cx * n
	local lz = gz - cz * n
	return DM.bilinear(ch.h, n + 1, n + 1, clamp(lx + 1, 1, n + 1), clamp(lz + 1, 1, n + 1))
end
function World:heightAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	return self:heightAtCell(gx, gz)
end
function World:normalAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local e = 0.25
	local hl = self:heightAtCell(gx - e, gz)
	local hr = self:heightAtCell(gx + e, gz)
	local hu = self:heightAtCell(gx, gz - e)
	local hd = self:heightAtCell(gx, gz + e)
	local sx = (hl - hr) / (2 * e * self.cell)
	local sz = (hu - hd) / (2 * e * self.cell)
	local nx, ny, nz = sx, 1, sz
	local m = sqrt(nx * nx + ny * ny + nz * nz)
	return nx / m, ny / m, nz / m
end
-- bioma Whittaker real da CELULA exata (x em studs)
function World:biomeAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local igx, igz = floor(gx), floor(gz)
	local cx, cz = self:chunkKeyOf(igx + 1, igz + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = clamp(igx + 1 - cx * n, 1, n)
	local lz = clamp(igz + 1 - cz * n, 1, n)
	return ch.biome[(lz - 1) * n + lx] or "padrao"
end
function World:materialAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local cx, cz = self:chunkKeyOf(floor(gx) + 1, floor(gz) + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = clamp(floor(gx - cx * n) + 1, 1, n)
	local lz = clamp(floor(gz - cz * n) + 1, 1, n)
	return ch.mat[(lz - 1) * n + lx], ch.biome[(lz - 1) * n + lx]
end
function World:waterDepthAt(xStuds, zStuds)
	local h = self:heightAt(xStuds, zStuds)
	local d = self.seaLevel - h
	local keyLake = nil
	if d <= 0 then -- lagos acima do nivel do mar
		local gx, gz = studs2cell(self, xStuds, zStuds)
		local lk = self.lakes[floor(gx) .. "," .. floor(gz)]
		if lk then d = lk end
	end
	return math.max(d, 0)
end

-- ================= ESCULTURA =================
ATX.BRUSH_OPS = { "raise", "lower", "smooth", "flatten", "set", "noise", "crater", "terrace", "paint", "wet" }
function World:sculpt(xStuds, zStuds, o)
	o = o or {}
	local op = o.op or "raise"
	local rad = math.max((o.radius or 24) / self.cell, 0.5)
	local strength = o.strength or 0.5
	local fall = o.falloff or "smooth"
	local amt = o.amount or 6
	local cgX, cgZ = studs2cell(self, xStuds, zStuds)
	local target = o.target
	if not target and op == "flatten" then target = self:heightAtCell(cgX, cgZ) end
	local x0, x1 = floor(cgX - rad) + 1, ceil(cgX + rad)
	local z0, z1 = floor(cgZ - rad) + 1, ceil(cgZ + rad)
	local changed, meanSum, meanN = 0, 0, 0
	local rn = DM.rng(self.seed + self.scultCount * 77 + 1)
	for gz = z0, z1 do
		for gx = x0, x1 do
			local d = sqrt((gx - cgX) ^ 2 + (gz - cgZ) ^ 2)
			local w = DM.falloff(d, rad, fall)
			if w > 0.001 then
				local cx, cz = self:chunkKeyOf(gx, gz)
				local ch = self:genChunk(cx, cz)
				local n = self.chunkCells
				local lx, lz = gx - cx * n, gz - cz * n
				local hi = (lz - 1) * (n + 1) + lx
				ch.sculpted = true
				local v = ch.h[hi] or 0
				if op == "raise" then ch.h[hi] = v + amt * strength * w
				elseif op == "lower" then ch.h[hi] = v - amt * strength * w
				elseif op == "set" then ch.h[hi] = lerp(v, target or amt, clamp(strength * w * 2, 0, 1))
				elseif op == "flatten" then ch.h[hi] = lerp(v, target, clamp(strength * w * 1.6, 0, 1))
				elseif op == "crater" then
					local rim = DM.gauss(d - rad * 0.72, rad * 0.3)
					ch.h[hi] = v - amt * 1.6 * strength * DM.gauss(d, rad * 0.72) + amt * rim * strength
				elseif op == "terrace" then
					local t = amt
					ch.h[hi] = lerp(v, floor(v / t + 0.5) * t, clamp(strength * w, 0, 1))
				elseif op == "noise" then
					ch.h[hi] = v + DM.gnoise2(gx * 0.35, gz * 0.35, self.seed + 700 + self.scultCount) * amt * strength * w
				elseif op == "paint" and o.mat then
					local mi = type(o.mat) == "number" and o.mat or ATX.MAT_INDEX[o.mat]
					if mi and lx <= n and lz <= n then ch.mat[(lz - 1) * n + lx] = mi end
				elseif op == "wet" then
					if lx <= n and lz <= n then ch.wet[(lz - 1) * n + lx] = clamp((ch.wet[(lz - 1) * n + lx] or 0) + strength * w, 0, 1) end
				elseif op == "smooth" then
					meanSum = meanSum + 1 -- coletado numa 2a passada abaixo
				end
				if w > 0.5 then changed = changed + 1 end
			end
		end
	end
	if op == "smooth" then
		local copy = {}
		for gz = z0, z1 do
			for gx = x0, x1 do copy[gx .. "," .. gz] = self:heightAtCell(gx, gz) end
		end
		for gz = z0, z1 do
			for gx = x0, x1 do
				local d = sqrt((gx - cgX) ^ 2 + (gz - cgZ) ^ 2)
				local w = DM.falloff(d, rad, fall)
				if w > 0.001 then
					local acc, cnt = 0, 0
					for dz = -1, 1 do
						for dx = -1, 1 do
							local k = (gx + dx) .. "," .. (gz + dz)
							local sample = copy[k] or self:heightAtCell(gx + dx, gz + dz)
							acc = acc + sample; cnt = cnt + 1
						end
					end
					local cx, cz = self:chunkKeyOf(gx, gz)
					local ch = self:genChunk(cx, cz)
					local n = self.chunkCells
					local lx, lz = gx - cx * n, gz - cz * n
					ch.h[(lz - 1) * (n + 1) + lx] = lerp(ch.h[(lz - 1) * (n + 1) + lx], acc / cnt, clamp(strength * w, 0, 1))
					ch.sculpted = true
				end
			end
		end
	end
	self.scultCount = self.scultCount + 1
	for k2, ch in pairs(self.chunks) do
		if ch.sculpted then ch.dirty = true end
	end
	return changed
end

-- ================= EROSAO (geologia real) =================
-- Hidraulica (droplet): inercia + capacidade de sedimentos + evaporacao
function World:erodeHydraulic(gx0, gz0, gw, gh, iters, opts)
	opts = opts or {}
	iters = iters or 5000
	-- amostra grade local numa tabela temporaria (inclui borda de 2)
	local gw2, gh2 = gw + 4, gh + 4
	local grid = {}
	for j = 1, gh2 do
		for i = 1, gw2 do grid[(j - 1) * gw2 + i] = self:heightAtCell(gx0 + i - 3, gz0 + j - 3) end
	end
	local inertia = opts.inertia or 0.06
	local capFactor = opts.capacity or 5
	local erodeF, depositF = opts.erode or 0.35, opts.deposit or 0.35
	local evap = opts.evap or 0.015
	local maxLife = 40
	local grav = 4
	local rn = DM.rng(self.seed + 9000 + self.stats.erosions * 13)
	for drop = 1, iters do
		local px, pz = 1 + rn() * (gw2 - 2), 1 + rn() * (gh2 - 2)
		local dx, dz = 0, 0
		local speed, water, sed = 0, 1, 0
		for life = 1, maxLife do
			local ix, iy = floor(px), floor(pz)
			if ix < 2 or iy < 2 or ix > gw2 - 2 or iy > gh2 - 2 then break end
			local fx, fy = px - ix, pz - iy
			local gx, gz = DM.gradient(grid, gw2, gh2, px, pz, 1)
			dx = dx * inertia - gx * (1 - inertia)
			dz = dz * inertia - gz * (1 - inertia)
			local len = sqrt(dx * dx + dz * dz)
			if len < 1e-6 then dx = rn() - 0.5; dz = rn() - 0.5; len = sqrt(dx * dx + dz * dz) end
			dx, dz = dx / len, dz / len
			local nxp, nzp = px + dx, pz + dz
			local hOld = DM.bilinear(grid, gw2, gh2, px, pz)
			local hNew = DM.bilinear(grid, gw2, gh2, nxp, nzp)
			local dh = hNew - hOld
			local cap = math.max(-dh, 0.01) * speed * water * capFactor
			if dh > 0 or sed > cap then -- deposita
				local amount = (dh > 0) and math.min(dh, sed) or (sed - cap) * depositF
				sed = sed - amount
				local i00 = (iy - 1) * gw2 + ix
				grid[i00] = grid[i00] + amount * (1 - fx) * (1 - fy)
				grid[i00 + 1] = grid[i00 + 1] + amount * fx * (1 - fy)
				grid[i00 + gw2] = grid[i00 + gw2] + amount * (1 - fx) * fy
				grid[i00 + gw2 + 1] = grid[i00 + gw2 + 1] + amount * fx * fy
			else -- erode
				local amount = math.min((cap - sed) * erodeF, -dh * 0 + math.max(-dh, 0) + (cap - sed) * 0.4)
				sed = sed + amount
				local i00 = (iy - 1) * gw2 + ix
				grid[i00] = grid[i00] - amount * (1 - fx) * (1 - fy)
				grid[i00 + 1] = grid[i00 + 1] - amount * fx * (1 - fy)
				grid[i00 + gw2] = grid[i00 + gw2] - amount * (1 - fx) * fy
				grid[i00 + gw2 + 1] = grid[i00 + gw2 + 1] - amount * fx * fy
			end
			speed = sqrt(math.max(speed * speed + dh * grav, 0))
			water = water * (1 - evap)
			px, pz = nxp, nzp
		end
		self.stats.droplets = self.stats.droplets + 1
	end
	-- escreve de volta (so o interior, celulas fora do mar tambem)
	local total, cnt, mx = 0, 0, 0
	for j = 3, gh2 - 2 do
		for i = 3, gw2 - 2 do
			local gx, gz = gx0 + i - 3, gz0 + j - 3
			local cx, cz = self:chunkKeyOf(gx, gz)
			local ch = self:genChunk(cx, cz)
			local n = self.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			local idx = (lz - 1) * (n + 1) + lx
			local newH = grid[(j - 1) * gw2 + i]
			local d = abs(newH - (ch.h[idx] or 0))
			if d > mx then mx = d end
			total = total + d; cnt = cnt + 1
			ch.h[idx] = newH
			ch.dirty = true; ch.sculpted = true
			if lx <= n and lz <= n then
				-- vales erodidos: mais umidade e solo exposto
				local mi = (lz - 1) * n + lx
				ch.wet[mi] = clamp((ch.wet[mi] or 0) + 0.05, 0, 1)
			end
		end
	end
	self.stats.erosions = self.stats.erosions + 1
	return { iterations = iters, meanDelta = cnt > 0 and total / cnt or 0, maxDelta = mx }
end
-- Termica (talus): material escorrega quando talude > angulo limite
function World:erodeThermal(gx0, gz0, gw, gh, passes, talus)
	talus = talus or 0.9 -- talude maximo (dh por celula)
	passes = passes or 8
	local moved = 0
	for p = 1, passes do
		for gz = gz0, gz0 + gh - 1 do
			for gx = gx0, gx0 + gw - 1 do
				local h0 = self:heightAtCell(gx, gz)
				local lowest, lowH = nil, h0
				for dz = -1, 1 do
					for dx = -1, 1 do
						if not (dx == 0 and dz == 0) then
							local hn = self:heightAtCell(gx + dx, gz + dz)
							if hn < lowH then lowH = hn; lowest = { dx, dz } end
						end
					end
				end
				if lowest and (h0 - lowH) > talus then
					local cx, cz = self:chunkKeyOf(gx, gz)
					local ch = self:genChunk(cx, cz)
					local n = self.chunkCells
					local lx, lz = gx - cx * n, gz - cz * n
					local excess = (h0 - lowH - talus) * 0.35
					ch.h[(lz - 1) * (n + 1) + lx] = h0 - excess
					local cx2, cz2 = self:chunkKeyOf(gx + lowest[1], gz + lowest[2])
					local ch2 = self:genChunk(cx2, cz2)
					local lx2, lz2 = gx + lowest[1] - cx2 * n, gz + lowest[2] - cz2 * n
					ch2.h[(lz2 - 1) * (n + 1) + lx2] = ch2.h[(lz2 - 1) * (n + 1) + lx2] + excess
					ch.dirty, ch2.dirty = true, true
					ch.sculpted, ch2.sculpted = true, true
					moved = moved + excess
				end
			end
		end
	end
	return { passes = passes, moved = moved }
end

-- ================= HIDROLOGIA =================
-- D8 flow accumulation -> rios; retorna celulas com acumulacao > minAcc
function World:carveRivers(gx0, gz0, gw, gh, minAcc)
	minAcc = minAcc or 28
	-- grade + borda
	local grid = {}
	local gw2, gh2 = gw + 2, gh + 2
	for j = 1, gh2 do
		for i = 1, gw2 do grid[(j - 1) * gw2 + i] = self:heightAtCell(gx0 + i - 2, gz0 + j - 2) end
	end
	-- direcao de fluxo (maior descida)
	local flow = {}
	for j = 2, gh2 - 1 do
		for i = 2, gw2 - 1 do
			local idx = (j - 1) * gw2 + i
			local h0 = grid[idx]
			local best, bestDrop = 0, self.seaLevel - h0 -- se abaixo do mar, despeja no mar
			for o = 1, 8 do
				local oi = i + (o == 1 and -1 or o == 2 and 0 or o == 3 and 1 or o == 4 and -1 or o == 5 and 1 or o == 6 and -1 or o == 7 and 0 or 1)
				local oj = j + (o <= 3 and -1 or o <= 5 and 0 or 1)
				local hn = grid[(oj - 1) * gw2 + oi]
				local drop = (h0 - hn) / ((oi ~= i and oj ~= j) and 1.4142 or 1)
				if drop > bestDrop then bestDrop = drop; best = o end
			end
			flow[idx] = best
		end
	end
	-- acumulacao por processamento em ordem de altura (maior -> menor)
	local order = {}
	for j = 2, gh2 - 1 do for i = 2, gw2 - 1 do order[#order + 1] = (j - 1) * gw2 + i end end
	table.sort(order, function(a, b) return grid[a] > grid[b] end)
	local acc = {}
	for _, idx in ipairs(order) do
		acc[idx] = (acc[idx] or 1)
		local f = flow[idx]
		if f and f > 0 then
			local i = ((idx - 1) % gw2) + 1
			local j = floor((idx - 1) / gw2) + 1
			local oi = i + (f == 1 and -1 or f == 2 and 0 or f == 3 and 1 or f == 4 and -1 or f == 5 and 1 or f == 6 and -1 or f == 7 and 0 or 1)
			local oj = j + (f <= 3 and -1 or f <= 5 and 0 or 1)
			local nidx = (oj - 1) * gw2 + oi
			acc[nidx] = (acc[nidx] or 1) + acc[idx]
		end
	end
	-- rios = acumulacao alta; escava leito em V suave e marca
	local riverCells = 0
	local maxAcc = 0
	for _, idx in ipairs(order) do if (acc[idx] or 0) > maxAcc then maxAcc = acc[idx] end end
	for _, idx in ipairs(order) do
		local a = acc[idx] or 1
		if a >= minAcc then
			local i = ((idx - 1) % gw2) + 1
			local j = floor((idx - 1) / gw2) + 1
			local gx, gz = gx0 + i - 2, gz0 + j - 2
			local cx, cz = self:chunkKeyOf(gx, gz)
			local ch = self:genChunk(cx, cz)
			local n = self.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			local hidx = (lz - 1) * (n + 1) + lx
			local depth = clamp(math.log(a) * 0.5, 0.4, 3.2)
			ch.h[hidx] = math.min(ch.h[hidx], ch.h[hidx] - depth * 0 + 0) -- mantem; escava abaixo:
			ch.h[hidx] = ch.h[hidx] - depth * 0.55
			ch.dirty = true; ch.sculpted = true
			if lx <= n and lz <= n then
				local mi = (lz - 1) * n + lx
				ch.wet[mi] = 1
				if ch.h[hidx] > self.seaLevel - 1 then ch.mat[mi] = ATX.MAT_INDEX.lama end
			end
			self.rivers[#self.rivers + 1] = { gx = gx, gz = gz, acc = a }
			riverCells = riverCells + 1
		end
	end
	return { cells = riverCells, maxAcc = maxAcc }
end
-- Lagos: preenchimento de depressoes (Planchon-Darboux simplificado)
function World:fillLakes(gw0, gz0, gw, gh)
	local grid, spill = {}, {}
	local gw2, gh2 = gw + 2, gh + 2
	local BIG = 1e9
	for j = 1, gh2 do
		for i = 1, gw2 do
			local h = self:heightAtCell(gw0 + i - 2, gz0 + j - 2)
			grid[(j - 1) * gw2 + i] = h
			local border = (i == 1 or j == 1 or i == gw2 or j == gh2)
			spill[(j - 1) * gw2 + i] = border and h or BIG
		end
	end
	for it = 1, 40 do
		local changed = false
		for j = 2, gh2 - 1 do
			for i = 2, gw2 - 1 do
				local idx = (j - 1) * gw2 + i
				local h = grid[idx]
				local s = spill[idx]
				if s > h then
					local minN = BIG
					local n1 = spill[idx - 1]; if n1 < minN then minN = n1 end
					local n2 = spill[idx + 1]; if n2 < minN then minN = n2 end
					local n3 = spill[idx - gw2]; if n3 < minN then minN = n3 end
					local n4 = spill[idx + gw2]; if n4 < minN then minN = n4 end
					local ns = math.max(h, minN)
					if ns < s - 1e-6 then spill[idx] = ns; changed = true end
				end
			end
		end
		if not changed then break end
	end
	local lakes = 0
	for j = 2, gh2 - 1 do
		for i = 2, gw2 - 1 do
			local idx = (j - 1) * gw2 + i
			local depth = spill[idx] - grid[idx]
			if depth > 0.7 and spill[idx] < BIG / 2 then
				local gx, gz = gw0 + i - 2, gz0 + j - 2
				self.lakes[gx .. "," .. gz] = depth
				local cx, cz = self:chunkKeyOf(gx, gz)
				local ch = self:genChunk(cx, cz)
				local n = self.chunkCells
				local lx, lz = gx - cx * n, gz - cz * n
				if lx <= n and lz <= n then
					local mi = (lz - 1) * n + lx
					ch.mat[mi] = ATX.MAT_INDEX.lama
					ch.wet[mi] = 1
					ch.dirty = true
				end
				lakes = lakes + 1
			end
		end
	end
	return { cells = lakes }
end

-- ================= MATERIALIZACAO (RRW -> dispositivo) =================
local function matColor(m, shade, hgt, sea)
	local c = m.cor
	local f = clamp(0.82 + shade * 0.18 + (hgt / 90) * 0.1, 0.5, 1.15)
	local r = clamp(floor(c[1] * f + 0.5), 0, 255)
	local g = clamp(floor(c[2] * f + 0.5), 0, 255)
	local b = clamp(floor(c[3] * f + 0.5), 0, 255)
	return Color3.fromRGB(r, g, b)
end

local function newPart(className, name, size, pos, color, parent)
	local p = Instance.new(className)
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	pcall(function() p.Material = Enum.Material.SmoothPlastic end)
	p.Color = color
	p.Parent = parent
	return p
end

function ATX._lodStep(defaultStep)
	local ok, lv = pcall(function() return ArkherDO15.state.level end)
	if not ok then return defaultStep or 2 end
	return ({ 1, 2, 3, 4 })[lv or 2] or (defaultStep or 2)
end

-- caverna: campo worley+gnoise — colunas altas ganham GAP interno real
-- (o voxel-shaped deixa de ser um pilar solido: vira base/caixao+tecto)
function World:caveSpanAt(wx, wz, baseY, colHeight)
	local cv = self.params.caves or 0
	if cv <= 0 or colHeight < 18 then return nil end
	local g1 = DM.gnoise2(wx * 0.021, wz * 0.021, self.seed + 913)
	local g2 = DM.gnoise2(wx * 0.068, wz * 0.068, self.seed + 914)
	local score = g1 * 0.62 + g2 * 0.38
	if score < 0.42 * cv then return nil end
	local frac = 0.28 + 0.34 * DM.hash2(wx, wz, self.seed + 915)
	local thick = 4 + 4 * DM.hash2(wx, wz, self.seed + 916)
	local mid = baseY + colHeight * frac
	local y0, y1 = mid - thick / 2, mid + thick / 2
	if y1 > baseY + colHeight - 3 then return nil end -- preserva a crosta
	if y0 < baseY + 3 then return nil end -- preserva a base
	return { y0 = y0, y1 = y1 }
end

function World:materializeChunk(ch, opts)
	opts = opts or {}
	if not self.materialized then self:materializeRoot() end
	local root = self.materialized
	local cname = "Chunk_" .. ch.cx .. "_" .. ch.cz
	local old = root:FindFirstChild(cname)
	if old then self.partsCount = self.partsCount - #old:GetChildren(); old:Destroy() end
	local model = Instance.new("Model")
	model.Name = cname
	model:SetAttribute("cx", ch.cx)
	model:SetAttribute("cz", ch.cz)
	model.Parent = root
	local n = self.chunkCells
	local step = opts.step or ATX._lodStep(2)
	if step < 1 then step = 1 end
	local cs = self.cell * step
	local baseY = opts.baseY or -40
	local count = 0
	for j0 = 1, n, step do
		for i0 = 1, n, step do
			-- media das alturas no bloco
			local acc, cnt = 0, 0
			for dj = 0, step do
				for di = 0, step do
					local hi = (j0 + dj - 1) * (n + 1) + (i0 + di)
					if hi <= #ch.h then acc = acc + (ch.h[hi] or 0); cnt = cnt + 1 end
				end
			end
			local hgt = cnt > 0 and acc / cnt or 0
			local wx = (ch.cx * n + i0 - 1 + (step - 1) / 2) * self.cell
			local wz = (ch.cz * n + j0 - 1 + (step - 1) / 2) * self.cell
			-- material dominante
			local mi = ch.mat[(clamp(j0, 1, n) - 1) * n + clamp(i0, 1, n)] or 1
			local m = ATX.MATERIALS[mi] or ATX.MATERIALS[1]
			local hL = (ch.h[(clamp(j0, 1, n + 1) - 1) * (n + 1) + clamp(i0 - 1, 1, n + 1)] or hgt)
			local hR = (ch.h[(clamp(j0, 1, n + 1) - 1) * (n + 1) + clamp(i0 + 1, 1, n + 1)] or hgt)
			local slope = abs(hL - hR) / (2 * self.cell)
			local col = matColor(m, -slope, hgt, self.seaLevel)
			local colHeight = math.max(hgt - baseY, 1)
			local gap = self:caveSpanAt(wx, wz, baseY, colHeight)
			if gap then
				-- coluna dividida: base rochosa + crosta (encontrado em mountain/canyon/vulcao)
				local rock = { 104, 96, 88 }
				local lowerH = gap.y0 - baseY
				local upperH = (baseY + colHeight) - gap.y1
				if lowerH > 0.5 then
					local p1 = newPart("Part", "CaveBase", Vector3.new(cs, lowerH, cs), Vector3.new(wx, baseY + lowerH / 2, wz), rock, model)
					p1:SetAttribute("mat", m.id)
					p1:SetAttribute("cave", "base")
					count = count + 1
				end
				if upperH > 0.5 then
					local p2 = newPart("Part", "CaveTop", Vector3.new(cs, upperH, cs), Vector3.new(wx, gap.y1 + upperH / 2, wz), col, model)
					p2:SetAttribute("mat", m.id)
					p2:SetAttribute("cave", "top")
					count = count + 1
				end
			else
				local p = newPart("Part", "C", Vector3.new(cs, colHeight, cs), Vector3.new(wx, baseY + colHeight / 2, wz), col, model)
				p:SetAttribute("mat", m.id)
				count = count + 1
			end
		end
	end
	self.partsCount = self.partsCount + count
	ch.dirty = false
	return model, count
end

function World:materializeRoot()
	local ws = workspace
	local old = ws:FindFirstChild("ATX_World")
	if old then old:Destroy() end
	local root = Instance.new("Model")
	root.Name = "ATX_World"
	root:SetAttribute("engine", "ArkherTerrainX")
	root:SetAttribute("seed", self.seed)
	root:SetAttribute("cell", self.cell)
	root:SetAttribute("preset", self.preset)
	root:SetAttribute("seaLevel", self.seaLevel)
	root.Parent = ws
	self.materialized = root
	return root
end

function ATX.clearWorld(world)
	if world and world.materialized then world.materialized:Destroy() world.materialized = nil world.partsCount = 0 end
end

function World:materializeRegion(x0Studs, z0Studs, wStuds, hStuds, opts)
	opts = opts or {}
	local n = self.chunkCells
	local cx0 = floor((x0Studs / self.cell) / n)
	local cx1 = floor(((x0Studs + wStuds) / self.cell) / n)
	local cz0 = floor((z0Studs / self.cell) / n)
	local cz1 = floor(((z0Studs + hStuds) / self.cell) / n)
	local built, parts = 0, 0
	for cz = cz0, cz1 do
		for cx = cx0, cx1 do
			local ch = self:genChunk(cx, cz)
			local _, cnt = self:materializeChunk(ch, opts)
			built = built + 1; parts = parts + cnt
		end
	end
	return { chunks = built, parts = parts }
end
-- LOD adaptativo por distancia do foco (D-O15 "materializacao adequada")
function World:updateLOD(focusX, focusZ)
	if not self.materialized then return { updated = 0 } end
	local updated = 0
	for key, ch in pairs(self.chunks) do
		local n = self.chunkCells
		local ccx = (ch.cx + 0.5) * n * self.cell
		local ccz = (ch.cz + 0.5) * n * self.cell
		local d = sqrt((ccx - focusX) ^ 2 + (ccz - focusZ) ^ 2)
		local want = d < 260 and 1 or d < 560 and 2 or 4
		local model = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
		local cur = model and model:GetAttribute("step") or nil
		if model and cur ~= want then
			self:materializeChunk(ch, { step = want })
			model = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
			if model then model:GetAttribute("step") end
			updated = updated + 1
		elseif model then
			model:SetAttribute("step", want)
		elseif not model then
			self:materializeChunk(ch, { step = want })
			local m2 = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
			if m2 then m2:SetAttribute("step", want) end
			updated = updated + 1
		end
	end
	return { updated = updated }
end

-- ================= STATS / SERIALIZACAO =================
function World:biomeCounts()
	local out = {}
	for _, ch in pairs(self.chunks) do
		for _, b in ipairs(ch.biome) do out[b] = (out[b] or 0) + 1 end
	end
	return out
end
function World:matCounts()
	local out = {}
	for _, ch in pairs(self.chunks) do
		for _, mi in ipairs(ch.mat) do
			local m = ATX.MATERIALS[mi]
			if m then out[m.id] = (out[m.id] or 0) + 1 end
		end
	end
	return out
end
function World:worldStats()
	local islands = 0
	return {
		seed = self.seed, preset = self.preset, chunks = self.stats.gen, cells = self.stats.cells,
		droplets = self.stats.droplets, erosions = self.stats.erosions,
		parts = self.partsCount, rivers = #self.rivers, lakes = (function() local c = 0 for _ in pairs(self.lakes) do c = c + 1 end return c end)(),
		sculpts = self.scultCount,
	}
end

function World:serialize()
	local chunks = {}
	for key, ch in pairs(self.chunks) do
		if ch.sculpted then
			local n = self.chunkCells
			local hs = {}
			for i = 1, (n + 1) * (n + 1) do hs[i] = floor((ch.h[i] or 0) * 10 + 0.5) end
			local ms = {}
			for i = 1, n * n do ms[i] = ch.mat[i] or 1 end
			chunks[#chunks + 1] = { cx = ch.cx, cz = ch.cz, h = table.concat(hs, ","), m = table.concat(ms, ",") }
		end
	end
	local data = {
		engine = "ATX", version = 1, seed = self.seed, cell = self.cell,
		chunkCells = self.chunkCells, seaLevel = self.seaLevel, preset = self.preset,
		params = self.params, lakes = self.lakes, chunks = chunks,
	}
	if HttpService then return HttpService:JSONEncode(data) end
	return "ATX:" .. tostring(self.seed)
end

function ATX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "ATX" then return nil, "bundle ATX invalido" end
	local w = ATX.new({ seed = data.seed, cell = data.cell, chunkCells = data.chunkCells, seaLevel = data.seaLevel, preset = data.preset })
	if type(data.params) == "table" then for k, v in pairs(data.params) do w.params[k] = v end end
	local restored = 0
	for _, c in ipairs(data.chunks or {}) do
		local ch = w:genChunk(c.cx, c.cz)
		local n = w.chunkCells
		local i = 0
		for tok in string.gmatch(c.h or "", "([^,]+)") do
			i = i + 1
			if i <= (n + 1) * (n + 1) then ch.h[i] = tonumber(tok) / 10 end
		end
		i = 0
		for tok in string.gmatch(c.m or "", "([^,]+)") do
			i = i + 1
			if i <= n * n then ch.mat[i] = tonumber(tok) end
		end
		ch.sculpted = true; ch.dirty = true
		restored = restored + 1
	end
	if type(data.lakes) == "table" then for k, v in pairs(data.lakes) do w.lakes[k] = v end end
	w.restored = restored
	return w
end

function World:exportFile(path)
	local str = self:serialize()
	path = path or ("ArkherTerrainX/world_" .. tostring(self.seed) .. ".atx.json")
	local ok = pcall(function()
		if game.WriteFile then game:WriteFile(path, str) end
	end)
	return str, path, ok
end

ATX._version = "1.0.0"
end

do
--[[ ARKHER WATER X (AWX) — motor de agua CUSTOM (nao usa a agua do Roblox) ]]
-- Alem do "shader de agua" da industria: corpos d'agua sao COMPOSICOES FISICAS
-- (densidade, salinidade, temperatura, viscosidade) + ondas de Gerstner com
-- dispersao gravitacional REAL (omega = sqrt(g*k)) + mares lunares + correntes
-- + flutuabilidade arquimediana de caixas + natacao + ambiente subaquatico.
-- RRW: realidade -> representacao (campo de ondas+termos fisicos) -> D-O15
-- (LOD de simulacao/materializacao) -> materializacao (tiles animados).
ArkherWaterX = ArkherWaterX or {}
local AWX = ArkherWaterX
local DM = ArkherDM
local floor, abs, sqrt = math.floor, math.abs, math.sqrt
local sin, cos, pi = math.sin, math.cos, math.pi
local clamp, lerp = DM.clamp, DM.lerp
local function atan2Safe(y, x) if x == 0 then return 0 end return math.atan(y / x) end
local function sign(x) if x > 0 then return 1 elseif x < 0 then return -1 end return 0 end
local G = 19.62 -- "gravidade Roblox-ish" p/ dispersao

local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end
local RunService
do local ok, s = pcall(function() return game:GetService("RunService") end) if ok then RunService = s end end

-- ================= TIPOS DE AGUA (materia real) =================
AWX.WATERS = {
	oceano = { nm = "Oceano", dens = 1025, sal = 35, temp = 18, visc = 1.0, cor = { 14, 68, 112 }, absorb = 0.65 },
	mar_calmo = { nm = "Mar Calmo", dens = 1025, sal = 32, temp = 22, visc = 0.9, cor = { 24, 112, 168 }, absorb = 0.45 },
	lago = { nm = "Lago", dens = 1000, sal = 0.2, temp = 16, visc = 0.85, cor = { 34, 96, 122 }, absorb = 0.35 },
	rio = { nm = "Rio", dens = 1000, sal = 0.1, temp = 14, visc = 0.8, cor = { 52, 110, 128 }, absorb = 0.3 },
	cachoeira = { nm = "Cachoeira", dens = 1000, sal = 0.1, temp = 12, visc = 0.75, cor = { 160, 196, 214 }, absorb = 0.15 },
	pantano = { nm = "Pantano", dens = 1005, sal = 4, temp = 24, visc = 1.6, cor = { 66, 84, 54 }, absorb = 0.85 },
	glacial = { nm = "Glacial", dens = 1000, sal = 0, temp = 2, visc = 1.1, cor = { 120, 178, 204 }, absorb = 0.25 },
	terma = { nm = "Terma", dens = 985, sal = 8, temp = 38, visc = 0.7, cor = { 96, 178, 186 }, absorb = 0.3 },
}
AWX.PRESETS = {
	calmaria = { waves = { { amp = 0.18, len = 28, dir = 20, speed = 1, steep = 0.2 }, { amp = 0.1, len = 11, dir = 75, speed = 1.2, steep = 0.1 } }, tide = 0.15 },
	porto = { waves = { { amp = 0.4, len = 34, dir = 0, speed = 1, steep = 0.3 }, { amp = 0.22, len = 13, dir = 40, speed = 1.1, steep = 0.2 }, { amp = 0.09, len = 6, dir = 110, speed = 1.4, steep = 0.1 } }, tide = 0.5 },
	ressaca = { waves = { { amp = 1.2, len = 58, dir = 12, speed = 1.05, steep = 0.5 }, { amp = 0.6, len = 21, dir = 48, speed = 1.2, steep = 0.35 }, { amp = 0.25, len = 9, dir = 100, speed = 1.6, steep = 0.2 } }, tide = 0.8 },
	tempestade = { waves = { { amp = 2.6, len = 88, dir = 8, speed = 1.25, steep = 0.75 }, { amp = 1.4, len = 31, dir = 55, speed = 1.4, steep = 0.55 }, { amp = 0.7, len = 13, dir = 130, speed = 1.7, steep = 0.4 }, { amp = 0.3, len = 6, dir = 200, speed = 2, steep = 0.3 } }, tide = 1.2 },
	corredeira = { waves = { { amp = 0.5, len = 9, dir = 0, speed = 1.9, steep = 0.55 }, { amp = 0.3, len = 5, dir = 30, speed = 2.3, steep = 0.45 } }, tide = 0 },
	espelho = { waves = { { amp = 0.05, len = 40, dir = 0, speed = 0.6, steep = 0.05 } }, tide = 0.05 },
}

local Body = {}
Body.__index = Body

AWX.bodies = {} -- registro vivo (alimenta links AEX/APX/UI)
function AWX.create(kind, opts)
	opts = opts or {}
	local props = AWX.WATERS[kind] and (function()
		local p = {}
		for k, v in pairs(AWX.WATERS[kind]) do p[k] = v end
		return p
	end)() or { nm = kind or "custom", dens = 1000, sal = 5, temp = 18, visc = 1, cor = { 30, 90, 140 }, absorb = 0.4 }
	local b = setmetatable({}, Body)
	b.kind = kind or "lago"
	b.props = props
	if opts.props then for k, v in pairs(opts.props) do b.props[k] = v end end
	b.level = opts.level or 0
	b.center = opts.center or { x = 0, z = 0 }
	b.size = opts.size or { x = 512, z = 512 } -- retangulo (ou raio em .radius)
	b.radius = opts.radius
	b.waves = opts.waves or (AWX.PRESETS.calmaria.waves)
	b.tideAmp = opts.tideAmp or (AWX.PRESETS.calmaria.tide or 0)
	b.tidePeriod = opts.tidePeriod or 360 -- s (ciclo lunar curto)
	b.flow = opts.flow -- fn(x,z,t) -> vx,vz (correnteza)
	b.foaminess = opts.foaminess or 0.4
	b.ripple = opts.ripple ~= false -- micro-ondulacao por ruido
	b.t0 = opts.t0 or 0
	b.tiles = nil
	b.tileParts = 0
	b.floaters = {}
	b.splashes = 0
	b.underwater = nil
	AWX.bodies[#AWX.bodies + 1] = b
	return b
end
function AWX.preset(name, opts)
	opts = opts or {}
	local p = AWX.PRESETS[name] or AWX.PRESETS.calmaria
	local waves = {}
	for i, w in ipairs(p.waves) do
		waves[i] = { amp = w.amp, len = w.len, dir = w.dir, speed = w.speed, steep = w.steep }
	end
	opts.waves = waves
	opts.tideAmp = p.tide
	return AWX.create(opts.kind or "oceano", opts)
end

-- ================= CAMPO DE ONDAS =================
-- mare lunar: componente diurna + semi-diurna simplificadas
function Body:tideAt(t)
	local p = (t or 0) / self.tidePeriod
	return self.tideAmp * (sin(2 * pi * p) * 0.7 + sin(4 * pi * p + 1.3) * 0.3)
end
-- Gerstner: altura em (x,z,t). dir em graus; omega = sqrt(g*k) * speedMul
function Body:heightAt(x, z, t)
	t = (t or 0) + self.t0
	local y = self.level + self:tideAt(t)
	for _, w in ipairs(self.waves) do
		local rad = w.dir * pi / 180
		local k = 2 * pi / w.len
		local omega = sqrt(G * k) * (w.speed or 1)
		local phase = (x * cos(rad) + z * sin(rad)) * k - omega * t
		y = y + w.amp * sin(phase)
	end
	if self.ripple then
		y = y + (DM.vnoise2(x * 0.22 + t * 0.35, z * 0.22, 777) - 0.5) * 0.14
	end
	return y
end
function Body:normalAt(x, z, t)
	local e = 0.9
	local hL, hR = self:heightAt(x - e, z, t), self:heightAt(x + e, z, t)
	local hU, hD = self:heightAt(x, z - e, t), self:heightAt(x, z + e, t)
	local nx, ny, nz = (hL - hR) / (2 * e), 1, (hU - hD) / (2 * e)
	local m = sqrt(nx * nx + ny * ny + nz * nz)
	return nx / m, ny / m, nz / m
end
-- energia da crista (por/espuma): segunda derivada negativa
function Body:crestAt(x, z, t)
	local h = self:heightAt(x, z, t)
	local hx = self:heightAt(x + 1.4, z, t) + self:heightAt(x - 1.4, z, t)
	local hz = self:heightAt(x, z + 1.4, t) + self:heightAt(x, z - 1.4, t)
	return clamp(((hx + hz) / 4 - h) * 0.9 + 0.2, 0, 1)
end
function Body:flowAt(x, z, t)
	if self.flow then return self.flow(x, z, t) end
	-- corrente gerada pelas proprias ondas (Stokes drift simplificado)
	local vx, vz = 0, 0
	for _, w in ipairs(self.waves) do
		local rad = w.dir * pi / 180
		local k = 2 * pi / w.len
		local omega = sqrt(G * k)
		local s = w.steep or 0.2
		vx = vx + cos(rad) * s * omega * w.amp * 0.12
		vz = vz + sin(rad) * s * omega * w.amp * 0.12
	end
	return vx, vz
end
function Body:inside(x, z)
	if self.radius then
		local dx, dz = x - self.center.x, z - self.center.z
		return dx * dx + dz * dz <= self.radius * self.radius
	end
	return abs(x - self.center.x) <= self.size.x / 2 and abs(z - self.center.z) <= self.size.z / 2
end
function Body:depthAt(x, z, t, floorFn)
	local bed = floorFn and floorFn(x, z) or (self.level - 12)
	return math.max(self:heightAt(x, z, t) - bed, 0)
end
-- amortecimento submerso (arraste viscoso quadratico + linear)
function Body:dragFactor(depthRatio, speed)
	local mu = self.props.visc or 1
	return mu * (1.15 * depthRatio) + mu * 0.02 * speed * speed
end

-- ================= FLUTUABILIDADE (Arquimedes de caixas) =================
function AWX.float(body, part, opts)
	opts = opts or {}
	local f = {
		part = part, body = body,
		density = opts.density or 600, -- kg/m3 do objeto
		damp = opts.damp or 0.85,
		vy = part and part.Position and 0 or 0,
		tilt = 0, spin = 0,
		mass = opts.mass,
		alive = true,
		lastSplash = 0,
	}
	if part and part.Size and not f.mass then
		f.mass = part.Size.X * part.Size.Y * part.Size.Z * f.density
	else
		f.mass = f.mass or 100
	end
	body.floaters[#body.floaters + 1] = f
	return f
end
-- integra 1 passo: retorna nova posicao Y e velocidade vertical
function AWX.stepFloater(f, dt, t)
	local b = f.body
	local p = f.part
	if not (p and p.Position and p.Size) then return nil end
	local h = b:heightAt(p.Position.X, p.Position.Z, t)
	local bottom = p.Position.Y - p.Size.Y / 2
	local subRatio = clamp((h - bottom) / p.Size.Y, 0, 1)
	-- forca: empuxo ~ rho_agua/rho_obj * submerso - gravidade, com arrasto
	local disp = (b.props.dens / f.density) * subRatio
	local acc = (disp - 1) * G * 0.6
	local drag = b:dragFactor(subRatio, abs(f.vy))
	-- arraste viscoso FISICO: linear (Stokes) + quadratico (forma), nunca
	-- zera a velocidade num passo so (leapfrog estavel)
	f.vy = f.vy + acc * dt
	local decel = drag * 0.9 * f.vy + sign(f.vy) * drag * 0.05 * f.vy * f.vy
	f.vy = f.vy - clamp(decel * dt, -abs(f.vy), abs(f.vy))
	f.vy = f.vy * (f.damp or 0.85)
	-- giro de "adiracao a crista": inclina com a normal da onda
	local nx, ny, nz = b:normalAt(p.Position.X, p.Position.Z, t)
	f.tilt = lerp(f.tilt or 0, nx * subRatio, clamp(dt * 4, 0, 1))
	-- correnteza desloca devagar
	local fx, fz = b:flowAt(p.Position.X, p.Position.Z, t)
	local newY = p.Position.Y + f.vy * dt
	if p.CFrame then
		local cf = CFrame.new(p.Position.X + fx * dt * 0.5, newY, p.Position.Z + fz * dt * 0.5)
		pcall(function() p.CFrame = cf end)
	end
	-- splash quando entra na agua com velocidade
	if subRatio > 0.05 and abs(f.vy) > 3 and (t - (f.lastSplash or 0)) > 0.5 then
		AWX.splash(b, p.Position.X, h, p.Position.Z, clamp(abs(f.vy) * 0.2, 0.5, 3))
		f.lastSplash = t
	end
	return newY, f.vy
end
function AWX.step(body, dt, t)
	local n = 0
	for _, f in ipairs(body.floaters) do
		if f.alive then AWX.stepFloater(f, dt, t or 0); n = n + 1 end
	end
	return n
end
-- natacao: imersao e forca de boiamento p/ personagem
function AWX.swim(body, rootPos, height, t)
	local h = body:heightAt(rootPos.X, rootPos.Z, t)
	local head = rootPos.Y + (height or 5) / 2
	local subHead = h - head
	return {
		immersion = clamp((h - (rootPos.Y - (height or 5) / 2)) / (height or 5), 0, 1),
		underwaterHead = subHead > 0,
		surfaceY = h,
		buoyAccel = (h - rootPos.Y) * 2.2,
	}
end

-- ================= AMBIENTE SUBAQUATICO / ATMOSFERA =================
function AWX.applyUnderwater(body, on)
	local lighting
	local ok, l = pcall(function() return game:GetService("Lighting") end)
	if not ok then return false end
	lighting = l
	if on then
		body.underwater = {
			fogEnd = lighting.FogEnd, fogColor = lighting.FogColor, fogStart = lighting.FogStart,
		}
		local c = body.props.cor
		lighting.FogColor = Color3.fromRGB(floor(c[1] * 0.5), floor(c[2] * 0.7), floor(c[3] * 0.9))
		lighting.FogStart = 0
		lighting.FogEnd = 60 / (body.props.absorb + 0.05)
		local cc = lighting:FindFirstChild("AWX_UnderwaterCC")
		if not cc then
			cc = Instance.new("ColorCorrection") -- existe no Roblox real; shim aceita classe livre
			cc.Name = "AWX_UnderwaterCC"
			cc.Parent = lighting
		end
		pcall(function()
			cc.TintColor = Color3.fromRGB(floor(120 + c[1] * 0.3), floor(140 + c[2] * 0.28), floor(150 + c[3] * 0.3))
			cc.Saturation = -0.08
		end)
	else
		if body.underwater then
			pcall(function()
				lighting.FogEnd = body.underwater.fogEnd or 100000
				lighting.FogColor = body.underwater.fogColor
				lighting.FogStart = body.underwater.fogStart or 0
			end)
			local cc = lighting:FindFirstChild("AWX_UnderwaterCC")
			if cc then cc:Destroy() end
			body.underwater = nil
		end
	end
	return true
end

-- ================= MATERIALIZACAO (tiles animados + espuma + caustica) =================
local function makeTile(body, x, z, size, t, foam)
	local p = Instance.new("Part")
	p.Name = foam and "Foam" or "W"
	p.Size = Vector3.new(size, foam and 0.12 or 0.35, size)
	p.CFrame = CFrame.new(x, body:heightAt(x, z, t) + (foam and 0.25 or 0), z)
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = foam and 0.25 or 0.32
	local c = body.props.cor
	if foam then p.Color = Color3.fromRGB(235, 244, 248)
	else p.Color = Color3.fromRGB(c[1], c[2], c[3]) end
	pcall(function() p.Material = Enum.Material.SmoothPlastic end)
	p:SetAttribute("kind", foam and "foam" or "water")
	return p
end

function AWX.materialize(body, opts)
	opts = opts or {}
	local ws = workspace
	local step = opts.tile or 16
	if ArkherDO15 then
		local lv = ArkherDO15.state.level
		step = ({ 12, 16, 24, 32 })[lv or 2] or step
	end
	local sx = body.radius and body.radius * 2 or body.size.x
	local sz = body.radius and body.radius * 2 or body.size.z
	sx = clamp(sx, step, opts.maxSpan or 512)
	sz = clamp(sz, step, opts.maxSpan or 512)
	local old = ws:FindFirstChild("AWX_Water")
	if old then old:Destroy() end
	local model = Instance.new("Model")
	model.Name = "AWX_Water"
	model:SetAttribute("kind", body.kind)
	model:SetAttribute("level", body.level)
	model:SetAttribute("tile", step)
	model.Parent = ws
	local t = 0
	local count = 0
	for z = -sz / 2 + step / 2, sz / 2 - step / 2 + 0.01, step do
		for x = -sx / 2 + step / 2, sx / 2 - step / 2 + 0.01, step do
			local wx, wz = x + body.center.x, z + body.center.z
			if body:inside(wx, wz) then
				local tile = makeTile(body, wx, wz, step, t, false)
				tile.Parent = model
				count = count + 1
				-- espuma em crista
				if DM.hash2(wx, wz, 4242) * 0.5 + body:crestAt(wx, wz, 0) * body.foaminess > 0.85 then
					local foam = makeTile(body, wx + step * 0.2, wz, step * 0.3, t, true)
					foam.Parent = model
					count = count + 1
				end
			end
		end
	end
	body.tiles = model
	body.tileParts = count
	return model, count
end
-- anima 1 quadro (barato): desloca tiles pela funcao de onda real
function AWX.animate(body, t)
	if not body.tiles then return 0 end
	local moved = 0
	for _, tile in ipairs(body.tiles:GetChildren()) do
		if tile:IsA("BasePart") and tile:GetAttribute("kind") == "water" then
			local x, z = tile.Position.X, tile.Position.Z
			local y = body:heightAt(x, z, t)
			tile.CFrame = CFrame.new(x, y, z)
			local c = body:crestAt(x, z, t)
			tile.Transparency = 0.32 - c * 0.12
			moved = moved + 1
		end
	end
	return moved
end
-- causticas: luz dançante no fundo (shimmer) — simulated via neon tiles
function AWX.caustics(body, floorY, opts)
	opts = opts or {}
	if not body.tiles then return 0 end
	local model = body.tiles
	local step = opts.tile or 24
	local sx = clamp(body.radius and body.radius * 2 or body.size.x, step, 256)
	local sz = clamp(body.radius and body.radius * 2 or body.size.z, step, 256)
	local count = 0
	for z = -sz / 2 + step / 2, sz / 2 - step / 2 + 0.01, step do
		for x = -sx / 2 + step / 2, sx / 2 - step / 2 + 0.01, step do
			local wx, wz = x + body.center.x, z + body.center.z
			if body:inside(wx, wz) and DM.hash2(wx, wz, 9191) > 0.55 then
				local p = Instance.new("Part")
				p.Name = "Caustic"
				p.Size = Vector3.new(step * 0.4, 0.1, step * 0.4)
				p.CFrame = CFrame.new(wx, floorY + 0.3, wz)
				p.Anchored = true
				p.CanCollide = false
				p.Transparency = 0.4
				p.Color = Color3.fromRGB(210, 236, 244)
				pcall(function() p.Material = Enum.Material.Neon end)
				p:SetAttribute("kind", "caustic")
				p:SetAttribute("phase", DM.hash2(wx, wz, 3333) * 6.28)
				p.Parent = model
				count = count + 1
			end
		end
	end
	return count
end

-- ================= SPLASH / gotas =================
function AWX.splash(body, x, y, z, intensity)
	intensity = intensity or 1
	if not body.tiles and not workspace then return nil end
	local holder = body.tiles or workspace
	local src = Instance.new("Part")
	src.Name = "SplashSrc"
	src.Size = Vector3.new(0.4, 0.4, 0.4)
	src.CFrame = CFrame.new(x, y, z)
	src.Anchored = true
	src.CanCollide = false
	src.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Splash"
	pcall(function()
		pe.Rate = 0
		pe.Speed = NumberRange.new(6 * intensity, 14 * intensity)
		pe.Lifetime = NumberRange.new(0.3, 0.8)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(Color3.fromRGB(225, 240, 248))
		pe.Acceleration = Vector3.new(0, -G * 0.5, 0)
	end)
	pe.Parent = src
	src.Parent = holder
	pcall(function() pe.Enabled = false; pe:Emit(floor(16 * intensity)) end)
	body.splashes = (body.splashes or 0) + 1
	return src
end

-- ================= CHUVA / EVAPORACAO (ciclo hidrologico) =================
-- orvalho proximo da agua + evaporacao por temperatura -> umidade do ATX
function AWX.hydrologyTick(body, world, gx0, gz0, gw, gh)
	if not (world and world.chunkKeyOf) then return { adjusted = 0 } end
	local adj = 0
	local evap = clamp((body.props.temp - 5) / 40, 0, 1) * 0.02
	for gz = gz0, gz0 + gh - 1 do
		for gx = gx0, gx0 + gw - 1 do
			local cx, cz = world:chunkKeyOf(gx, gz)
			local ch = world:genChunk(cx, cz)
			local n = world.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			if lx >= 1 and lx <= n and lz >= 1 and lz <= n then
				local mi = (lz - 1) * n + lx
				local nearWater = ch.mat[mi] == (ATX and ATX.MAT_INDEX.lama or 0) or (ch.wet[mi] or 0) > 0.6
				if nearWater then
					ch.wet[mi] = clamp((ch.wet[mi] or 0) + 0.01 - evap * 0.3, 0, 1)
					adj = adj + 1
				end
			end
		end
	end
	return { adjusted = adj, evaporation = evap }
end

-- ================= SERIALIZACAO =================
function Body:serialize()
	local data = {
		engine = "AWX", version = 1, kind = self.kind, props = self.props,
		level = self.level, center = self.center, size = self.size, radius = self.radius,
		waves = self.waves, tideAmp = self.tideAmp, tidePeriod = self.tidePeriod,
		foaminess = self.foaminess, ripple = self.ripple,
	}
	if HttpService then return HttpService:JSONEncode(data) end
	return "AWX:" .. tostring(self.kind)
end
function AWX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "AWX" then return nil, "bundle AWX invalido" end
	local waves = {}
	for i, w in ipairs(data.waves or {}) do
		waves[i] = { amp = w.amp, len = w.len, dir = w.dir, speed = w.speed, steep = w.steep }
	end
	local b = AWX.create(data.kind, {
		level = data.level, center = data.center, size = data.size, radius = data.radius,
		waves = waves, tideAmp = data.tideAmp, tidePeriod = data.tidePeriod,
		foaminess = data.foaminess, ripple = data.ripple,
	})
	for k, v in pairs(data.props or {}) do b.props[k] = v end
	return b
end

function Body:stats()
	return {
		kind = self.kind, waves = #self.waves, tideAmp = self.tideAmp,
		tiles = self.tileParts or 0, floaters = #self.floaters,
		splashes = self.splashes or 0, density = self.props.dens, salinity = self.props.sal,
		temp = self.props.temp,
	}
end

-- ================= CACHOEIRA (droplets fisicos) =================
-- gotas saem do topo com velocidade/jitter, caem por gravidade real e viram
-- splash + espuma quando cruzam a superficie do corpo de destino
function AWX.waterfall(body, cfg)
	cfg = cfg or {}
	local wf = {
		body = body,
		sourceX = cfg.sourceX or 0, sourceY = cfg.sourceY or 24, sourceZ = cfg.sourceZ or 0,
		flow = cfg.flow or 6, -- gotas por segundo
		jetV = cfg.jetV or (8 + (cfg.speed or 1) * 6), -- velocidade de jato
		width = cfg.width or 2,
		intensity = cfg.intensity or 1.4,
		drops = {}, acc = 0, alive = true, rng = cfg.seed or 11,
	}
	if not body.tiles then AWX.materialize(body, { maxSpan = 200 }) end
	function wf:emitDrop()
		local d = Instance.new("Part")
		d.Name = "FallDrop"
		d.Size = Vector3.new(0.45, 0.9, 0.45)
		local jx = (DM.hash2(self.rng, 1, 7) - 0.5) * self.width
		d.CFrame = CFrame.new(self.sourceX + jx, self.sourceY, self.sourceZ)
		d.Anchored = true
		d.CanCollide = false
		d.Transparency = 0.2
		local c = body.props.cor
		d.Color = Color3.fromRGB(math.min(c[1] + 130, 235), math.min(c[2] + 120, 240), math.min(c[3] + 60, 245))
		pcall(function() d.Material = Enum.Material.SmoothPlastic end)
		d.Parent = body.tiles or workspace
		self.drops[#self.drops + 1] = { inst = d, vx = (DM.hash2(self.rng, 2, 3) - 0.5) * 1.4, vy = -self.jetV, vz = self.jetV * (0.4 + DM.hash2(self.rng, 4, 9) * 0.4) }
		self.rng = self.rng + 1
	end
	AWX._falls = AWX._falls or {}
	AWX._falls[#AWX._falls + 1] = wf
	return wf
end
function AWX.stepWaterfall(wf, dt, t)
	if not wf.alive then return 0 end
	wf.acc = wf.acc + dt * wf.flow
	while wf.acc >= 1 do wf.acc = wf.acc - 1 wf:emitDrop() end
	local landed = 0
	for i = #wf.drops, 1, -1 do
		local d = wf.drops[i]
		d.vy = d.vy - G * dt -- gravidade real
		local p = d.inst
		local nx = p.Position.X + d.vx * dt
		local ny = p.Position.Y + d.vy * dt
		local nz = p.Position.Z + d.vz * dt
		local surface = wf.body:heightAt(nx, nz, t)
		if ny <= surface + 0.2 then
			AWX.splash(wf.body, nx, surface, nz, clamp(abs(d.vy) * 0.12, 0.5, 3) * (wf.intensity or 1))
			pcall(function() p:Destroy() end)
			table.remove(wf.drops, i)
			landed = landed + 1
		else
			p.CFrame = CFrame.new(nx, ny, nz)
		end
	end
	return landed
end
function AWX.stepFalls(dt, t)
	local n = 0
	for _, wf in ipairs(AWX._falls or {}) do n = n + AWX.stepWaterfall(wf, dt, t) end
	return n
end

-- ================= BARCO (casco com flutuabilidade de 4 pontos) =================
-- Amostra a superficie em 4 cantos do casco transformados pelo heading →
-- empuxo por amostra (nao so centro), pitch/roll pelos deltas, motor,
-- leme e arrasto hidrodinamico pela viscosidade do corpo.
function AWX.boat(body, part, opts)
	opts = opts or {}
	local bt = {
		body = body, part = part,
		speed = 0, heading = opts.heading or 0, -- rad
		motor = opts.motor or 0, -- -1..1 (empurro do motor)
		helm = opts.helm or 0, -- -1..1 (leme)
		mass = opts.mass or 800, -- kg
		vy = 0, pitch = 0, roll = 0,
		halfL = (part and part.Size.Z or 8) / 2, halfW = (part and part.Size.X or 4) / 2,
		hullH = part and part.Size.Y or 3,
		power = opts.power or 22, turnRate = opts.turnRate or 0.55,
		alive = true,
	}
	AWX._boats = AWX._boats or {}
	AWX._boats[#AWX._boats + 1] = bt
	return bt
end
function AWX.stepBoat(bt, dt, t)
	if not (bt.alive and bt.part) then return nil end
	local p = bt.part
	local fx, fz = -sin(bt.heading), cos(bt.heading) -- frente (z+ frente em roblox usa -z; usamos convencao propria)
	local rx, rz = cos(bt.heading), sin(bt.heading) -- lateral
	-- 4 amostras: proa, popa, boreste, bombordo
	local cx, cz = p.Position.X, p.Position.Z
	local hF = bt.body:heightAt(cx + fx * bt.halfL, cz + fz * bt.halfL, t)
	local hB = bt.body:heightAt(cx - fx * bt.halfL, cz - fz * bt.halfL, t)
	local hR = bt.body:heightAt(cx + rx * bt.halfW, cz + rz * bt.halfW, t)
	local hL = bt.body:heightAt(cx - rx * bt.halfW, cz - rz * bt.halfW, t)
	local avg = (hF + hB + hR + hL) / 4
	local bottomY = p.Position.Y - bt.hullH / 2
	local sub = clamp((avg - bottomY) / bt.hullH, 0, 1)
	-- ARQUIMEDES de casco: fracao submersa de equilibrio = dens_casco/dens_agua
	local fullVol = math.max((bt.halfL * 2) * (bt.halfW * 2) * bt.hullH, 0.01)
	local hullDens = bt.mass / fullVol -- kg/m3 efetivo do casco
	local targetSub = clamp(hullDens / (bt.body.props.dens or 1000), 0.02, 0.98)
	-- mola submersa p/ o equilibrio + amortecimento vertical (agua amortece)
	local accY = clamp((sub - targetSub) * G * 1.4 - bt.vy * 3.5, -24, 24)
	bt.vy = clamp(bt.vy + accY * dt, -8, 8)
	bt.pitch = lerp(bt.pitch or 0, atan2Safe(hB - hF, math.max(bt.halfL * 2, 0.01)) * 0.7, clamp(dt * 4, 0, 1))
	bt.roll = lerp(bt.roll or 0, atan2Safe(hL - hR, math.max(bt.halfW * 2, 0.01)) * 0.7, clamp(dt * 4, 0, 1))
	-- motor + arrasto hidrodinamico (viscosidade + arrasto quadratico)
	local thrust = bt.motor * bt.power
	local visc = bt.body.props.visc or 1
	local drag = visc * (0.6 * bt.speed + 0.18 * bt.speed * abs(bt.speed))
	local accS = thrust - drag
	bt.speed = clamp(bt.speed + accS * dt, -8, 14)
	bt.heading = bt.heading + bt.helm * bt.turnRate * clamp(abs(bt.speed) / 6 + 0.25, 0, 1) * dt
	-- integra
	local nx = cx + fx * bt.speed * dt
	local nz = cz + fz * bt.speed * dt
	local ny = p.Position.Y + bt.vy * dt
	local cf = CFrame.new(nx, ny, nz) * CFrame.Angles(bt.pitch, bt.heading, bt.roll)
	pcall(function() p.CFrame = cf end)
	return { speed = bt.speed, heading = bt.heading, submerged = sub, pitch = bt.pitch, roll = bt.roll }
end
function AWX.stepBoats(dt, t)
	for _, bt in ipairs(AWX._boats or {}) do AWX.stepBoat(bt, dt, t) end
end

AWX._version = "1.0.0"
end

