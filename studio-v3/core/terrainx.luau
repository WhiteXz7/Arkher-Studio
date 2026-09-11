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
_G.ArkherTerrainX = _G.ArkherTerrainX or {}
local ATX = _G.ArkherTerrainX
local DM = rawget(_G, "ArkherDM")
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
	local ok, lv = pcall(function() return (rawget(_G, "ArkherDO15") or {}).state.level end)
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
return ATX
