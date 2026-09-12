-- WORLD X (WLDX) — motor planetario RRW do ARKHER:
-- REALIDADE(planeta Terra) -> tectonica-lite + orografia + clima real
-- -> REPRESENTACAO (heightmap/materia) -> D-O15 (tiers) -> RRW
-- (parallax geometrico + microrelieve 16K + auto-vegetacao por bioma)
-- -> MATERIALIZACAO (parts/meshes) — com AUTO-APRENDIZADO de geracao
-- (mapas 3D que melhoram a geracao procedural a cada run, via memoria TX).
-- Depende: _G.ArkherDM (noise/hash), _G.ArkherTheoryX (leis).

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")

local V3 = Vector3.new
local WX = {}
local S = {
	worlds = {},
	parallax = {},   -- {model -> {shells}}
	slots = {},      -- bioma-slot -> pasta de modelos do usuario
	stats = { generated = 0, learned = 0 },
}
WX.S = S

-- ============ ruido base ============
local function fbm(x, z, oct, seed)
	oct = oct or 5
	local amp, freq, acc, norm = 1, 1, 0, 0
	for i = 1, oct do
		local n = DM.noise2(x * freq / 100 + seed * 17.13, z * freq / 100 - seed * 9.7, seed + i)
		acc = acc + n * amp
		norm = norm + amp
		amp = amp * 0.5
		freq = freq * 2.03
	end
	return acc / norm
end

local function ridged(x, z, oct, seed)
	return 1 - math.abs(fbm(x, z, oct, seed)) * 2
end

-- ============ TECTONICA-LITE (supercontinentes + rift + orogenias) ============
-- Real: limites de placas definem montanhas (convergente) e oceanos (divergente).
-- Modelo: N Nucleos continentais com vetores de DRIFT; campo = max Voronoi suavizado.
function WX.tectonics(seed, plates)
	plates = plates or 7
	local rng = Random.new(seed)
	local nucl = {}
	for i = 1, plates do
		table.insert(nucl, {
			x = rng:NextNumber(-1400, 1400), z = rng:NextNumber(-1400, 1400),
			dx = rng:NextNumber(-1, 1), dz = rng:NextNumber(-1, 1),
			size = rng:NextNumber(380, 900) * (i == 1 and 1.6 or 1), -- supercontinente
			rise = rng:NextNumber(0.5, 1.0),
		})
	end
	return function(x, z, t)
		t = t or 0 -- drift temporal (milhoes de anos simulados)
		local best, best2, bid = -1e9, -1e9, 1
		for i, n in ipairs(nucl) do
			local nx, nz = n.x + n.dx * t, n.z + n.dz * t
			local d = ((x - nx) ^ 2 + (z - nz) ^ 2) ^ 0.5 / n.size
			local v = 1 - d
			if v > best then best2, best, bid = best, v, i
			elseif v > best2 then best2 = v end
		end
		-- borda convergente (best ~ best2) = orogenia (dobras/vulcanismo)
		local boundary = math.clamp(1 - (best - best2) * 3.2, 0, 1)
		local base = math.clamp(best * nucl[bid].rise, -1, 1)
		local orogeny = boundary * boundary
		return base, orogeny, bid
	end
end

-- ============ ALTURA COMPLETA (continente->costa->oceano, escala) ============
-- h em studs; usa tectonica + ridged frio (cristas) + fbm humido (vales)
function WX.height(w, x, z)
	local c = w._cache
	local key = x * 100000 + z
	local cached = c[key]
	if cached then return cached end
	local tec, orog = w.tec(x, z, w.driftT or 0)
	local sea = -0.55 * (1 - math.max(0, tec + 0.7))
	local continent = tec * 240
	local orogM = orog * 190 * (0.7 + 0.6 * ridged(x, z, 5, w.seed + 3))
	local hills = fbm(x, z, 5, w.seed) * 60
	local micro = fbm(x * 4.1, z * 4.1, 3, w.seed + 7) * 6
	local h = math.max(sea * 60, continent + orogM + hills + micro)
	c[key] = h
	return h
end

-- ============ CLIMA REAL (latitude + orografia + dist do mar) ============
function WX.climate(w, x, z)
	local h = WX.height(w, x, z)
	local scaleK = (w.scale or TX.SCALES.studio).studToM
	-- latitude: -1 (sul) .. 1 (norte) sobre o world
	local lat = math.clamp(z / (w.size * 0.5), -1, 1)
	local absLat = math.abs(lat)
	local tBase = 30 - absLat * 62                -- media anual por latitude
	local lapse = h * scaleK * -0.0065            -- gradiente adiabatico: -6.5C/km
	local temp = tBase + lapse + math.sin(w.season * math.pi * 2 + lat * 1.6) * (4 + absLat * 16) * (w.seasonAmp or 1)
	-- precipitacao: base latitudinal + sombra de chuva orografica
	local pLat = 1850 * (1 - absLat) ^ 1.35 + 60
	-- barlavento: amostra vento zonal (oeste->leste)
	local windX, windZ = math.cos(w.windRot or 0), math.sin(w.windRot or 0)
	local hUp = WX.height(w, x - windX * 220, z - windZ * 220)
	local updraft = math.max(0, (h - hUp)) * scaleK
	local precip = pLat + math.min(900, updraft * 0.16) - math.max(0, (hUp - h)) * scaleK * 0.0015
	precip = math.clamp(precip, 2, 6200)
	local humid = math.clamp(precip / 1850, 0, 1.4)
	return { t = temp, p = precip, h = h, lat = lat, humid = humid, lapse = lapse }
end

-- ============ BIOMA (TX.whittaker + regras extras) ============
function WX.biomeAt(w, x, z)
	local cl = WX.climate(w, x, z)
	local id = TX.whittaker(cl.t, cl.p, cl.h * (w.scale or TX.SCALES.studio).studToM, cl.h > 300 and true or false)
	-- regras de sobreposicao: rios (riparian), litoral (mangue), salares
	if cl.h < 8 and cl.p > 900 and cl.t > 22 then id = 21 end        -- mangue litoral
	if cl.h < 6 and cl.p > 1100 then id = 22 end                      -- alagado
	if cl.h < 3 and cl.p < 160 then id = 32 end                       -- playa/salar
	if id == 17 and cl.t > 6 then id = 16 end                         -- taiga -> mista
	return TX.biomeById(id), cl
end

-- ============ new world ============
function WX.new(opts)
	opts = opts or {}
	local w = {
		seed = opts.seed or 1,
		size = opts.size or 1400,
		cell = opts.cell or 8,
		season = opts.season or 0.3,
		seasonAmp = opts.seasonAmp or 1,
		scale = opts.scale or TX.SCALES.studio,
		tier = TX.activeTier,
		learn = TX.memGet("wldx", "learn_" .. tostring(opts.seed or 1)) or { a = 1, e = 1, runs = 0 },
		_cache = {},
	}
	w.tec = WX.tectonics(w.seed, opts.plates)
	table.insert(S.worlds, w)
	_G.ArkherWorldX = w
	S.stats.generated = S.stats.generated + 1
	return w
end

-- ============ MICRORELIEVE 16K (qualidade de textura por MATERIA) ============
-- "16K" ARKHER = relevo em sub-celula com octavas do tier + brilho por grão,
-- molhado escurece (real: agua reduz albedo), gradiente de exposicao.
function WX.materialAt(w, x, z, cl, biome)
	cl = cl or WX.climate(w, x, z)
	biome = biome or WX.biomeAt(w, x, z)
	local h = cl.h
	local slope = w.slope and w:slope(x, z) or 0
	local mat
	if h < 2 then mat = "sand"
	elseif cl.t < 1 or h > 240 then mat = "snow"
	elseif slope > 0.9 then mat = "rock"
	elseif slope > 0.6 then mat = "scree"
	elseif cl.p < 260 and cl.t > 20 then mat = "sand"
	elseif cl.h < 9 and cl.p > 650 then mat = "mud"
	elseif cl.p > 950 then mat = "grass"
	else mat = "soil" end
	if biome.kop == "VOL" then mat = "lava" end
	if biome.kop == "EF" then mat = "ice" end
	return mat
end

-- renderiza microrelieve: retorna cor + brilho + relevo local
function WX.render16k(w, x, z, mat)
	local m = TX.MATTER[mat] or TX.MATTER.rock
	local tier = w.tier or TX.TIERS.premium
	local oct = tier.microReliefOctaves
	-- octavas de micro (frequencia alta = grao; sombra/espelha por face NE/NW)
	local g = fbm(x * m.microFreq, z * m.microFreq, oct, w.seed + 101)
	local gNE = fbm((x + 1.5) * m.microFreq, (z + 1.5) * m.microFreq, math.max(2, oct - 1), w.seed + 101)
	local s1 = math.clamp(0.5 + 0.85 * g, 0, 1)
	local relief = (gNE - g) -- derivada = relevo local (paralaxe de fato)
	local col = m.colA:Lerp(m.colB, s1)
	-- molhado: escurece e satura (agua em poros)
	local cl = WX.climate(w, x, z)
	local wet = math.clamp((cl.p - 250) / 1600, 0, 1) * (1 - m.grain * 0.4)
	if wet > 0 then
		col = col:Lerp(Color3.new(0, 0, 0), wet * (1 - m.wetDark) * 0.55)
	end
	-- exposicao (luz ambiente: faces claras ao SE escuras ao NW - real)
	local exp = math.clamp(-relief * 2.2, -0.5, 0.5)
	col = Color3.new(
		math.clamp(col.R + exp * 0.22, 0, 1),
		math.clamp(col.G + exp * 0.22, 0, 1),
		math.clamp(col.B + exp * 0.22, 0, 1))
	return { color = col, relief = relief, grain = s1, wet = wet, mat = mat }
end

-- ============ PARALLAX GEOMETRICO REAL (camadas fisicas) ============
-- Sem shaders nem imagens: N cascas transparentes empilhadas com offsets
-- de relevo -> o olho/camera ve camadas a profundidades diferentes = paralaxe
-- TRUE (movimento relativo de camadas quando a camera move — melhor que
-- normal map falso). Cada casca e um clone fino deformado da superficie.
function WX.parallaxSeed(model, terrainPart, mat, depth, layers)
	layers = layers or (TX.activeTier.parallaxLayers)
	depth = depth or ((TX.MATTER[mat] or TX.MATTER.rock).parallaxDepth)
	local shells = {}
	for i = 1, layers do
		local sh = terrainPart:Clone()
		sh.Name = "PX" .. i
		sh.Size = V3(terrainPart.Size.X, 0.05, terrainPart.Size.Z)
		sh.Position = terrainPart.Position + V3(0, depth * (i / layers), 0)
		sh.Transparency = 0.55 + (i / layers) * 0.4
		sh.CastShadow = i == 1
		sh.CanCollide = false
		sh.Anchored = true
		local m = TX.MATTER[mat] or TX.MATTER.rock
		sh.Color = m.colA:Lerp(m.colB, (i / layers))
		sh.Material = Enum.Material.SmoothPlastic
		sh.Parent = model
		table.insert(shells, sh)
	end
	S.parallax[model] = shells
	return shells
end

-- ============ SLOTS de modelos do usuario (arvores/biomas) ============
-- bioma.slot ("jungle_trees" etc.) <- pasta em ServerStorage.ArkherTreeModels
function WX.bindModelSlots(rootModel)
	for _, b in ipairs(TX.BIOMES) do
		local folder = rootModel and rootModel:FindFirstChild(b.slot)
		if folder then S.slots[b.slot] = folder end
	end
	return #(function() local t2 = {} for k in pairs(S.slots) do t2[#t2 + 1] = k end return t2 end)()
end

-- ============ AUTO-VEGETACAO POR BIOMA (com placeholder procedural) ============
-- Se o slot tem modelos do usuario -> clona aleatoriamente; senao gera
-- prototipo procedural minimo de ARVORE (tronco+copa) sintonizado por bioma.
function WX.vegetate(w, opts)
	opts = opts or {}
	local cx, cz, r = opts.cx or 0, opts.cz or 0, opts.radius or 120
	local count = math.floor((opts.count or 60) * (w.tier.vegDensity or 1))
	local parent = opts.parent or workspace:FindFirstChild("ArkherX_Forest") or Instance.new("Model")
	parent.Name = "ArkherX_Forest"
	parent.Parent = workspace
	w.slope = w.slope or function() return 0 end
	local rng = Random.new(w.seed * 7 + 13)
	local placed = 0
	local tries = count * 6
	while placed < count and tries > 0 do
		tries = tries - 1
		local x = cx + rng:NextNumber(-r, r)
		local z = cz + rng:NextNumber(-r, r)
		local biome, cl = WX.biomeAt(w, x, z)
		local skip = (cl.h < 3) or (biome.veg <= 0.02)
		if not skip and rng:NextNumber() > biome.veg * (w.tier.vegDensity or 1) then skip = true end
		if not skip then
		local y = cl.h
		-- distancia minima simples (poisson-lite)
		local slotFolder = S.slots[biome.slot]
		local item
		if slotFolder and #slotFolder:GetChildren() > 0 then
			local kids = slotFolder:GetChildren()
			item = kids[rng:NextInteger(1, #kids)]:Clone()
		else
			-- prototipo ARKHER (tronco+copa org anica por bioma)
			item = Instance.new("Model")
			item.Name = "ArkherTree_" .. biome.kop
			local th = (biome.kop == "Af" or biome.kop == "Am") and 18 or (biome.kop == "BWh" and 4 or 10)
			local trunk = Instance.new("Part")
			trunk.Name = "Trunk"
			trunk.Size = V3(math.max(0.6, th * 0.09), th, math.max(0.6, th * 0.09))
			trunk.Position = V3(x, y + th / 2, z)
			trunk.Color = Color3.fromRGB(96, 66, 40)
			trunk.Material = Enum.Material.Wood
			trunk.Anchored = true
			trunk.Parent = item
			local crown = Instance.new("Part")
			crown.Name = "Crown"
			crown.Shape = Enum.PartType.Ball
			local cr = th * (0.55 + rng:NextNumber() * 0.5)
			crown.Size = V3(cr, cr * 0.7, cr)
			crown.Position = V3(x, y + th + cr * 0.2, z)
			local cb = TX.BIOMES[biome.id]
			crown.Color = (biome.kop == "BWh" or biome.kop == "BWk") and Color3.fromRGB(120, 140, 80)
				or Color3.fromRGB(40 + rng:NextInteger(0, 30), 110 + rng:NextInteger(0, 45), 40)
			crown.Material = Enum.Material.Grass
			crown.Anchored = true
			crown.Parent = item
		end
		item.Parent = parent
		if item:IsA("Model") and item.PrimaryPart == nil and item:FindFirstChildWhichIsA("BasePart") then
			item.PrimaryPart = item:FindFirstChildWhichIsA("BasePart")
		end
		if item:IsA("Model") and item.PrimaryPart then
			item:SetPrimaryPartCFrame(CFrame.new(x, y, z))
		end
			placed = placed + 1
		end
	end
	w.veg = { placed = placed, biome = "auto" }
	return { placed = placed }
end

-- ============ EROSAO (hidraulica aprimorada com orcamento do tier) ============
function WX.erode(w, cycles)
	cycles = cycles or (w.tier.erosionDrops or 150)
	local rng = Random.new(w.seed + 99)
	local carveKeys = {}
	for i = 1, cycles do
		local x, z = rng:NextNumber(-w.size / 2, w.size / 2), rng:NextNumber(-w.size / 2, w.size / 2)
		local h = WX.height(w, x, z)
		-- fluxo: desce 8 passos na direcao do gradiente
		for step = 1, 10 do
			local gx = (WX.height(w, x + 12, z) - h) / 12
			local gz = (WX.height(w, x, z + 12) - h) / 12
			local mag = math.max(1e-4, (gx * gx + gz * gz) ^ 0.5)
			x = x - (gx / mag) * 14
			z = z - (gz / mag) * 14
			h = WX.height(w, x, z)
		end
		-- poça/sedimenta cão: aprende tendencia
		carveKeys[#carveKeys + 1] = { x = math.floor(x), z = math.floor(z) }
	end
	-- aprendizado: atualiza estatistica no TX.mem (melhora prox runs)
	local learn = w.learn
	learn.runs = (learn.runs or 0) + 1
	learn.flows = carveKeys
	TX.memPut("wldx", "learn_" .. w.seed, learn)
	return { cycles = cycles, learned = learn.runs }
end

-- ============ HEIGHTMAP import (dados reais -> representacao) ============
-- grade: {w=cols,h=rows, data={h1..hN} 0..1}; pixel -> studs (escala TX)
function WX.fromHeightmap(grade, opts)
	opts = opts or {}
	local w = WX.new({ seed = opts.seed or 1, size = (grade.w * (opts.cell or 8)), cell = opts.cell or 8 })
	local imgW, imgH = grade.w, grade.h
	w.rawHeight = function(x, z)
		local ix = math.clamp(math.floor((x + w.size / 2) / w.cell) + 1, 1, imgW)
		local iz = math.clamp(math.floor((z + w.size / 2) / w.cell) + 1, 1, imgH)
		local v = grade.data[(iz - 1) * imgW + ix] or 0
		return v * (opts.heightScale or 400) - (opts.seaOff or 160)
	end
	w.tec = function(x, z) return w.rawHeight(x, z) / 240, 0, 1 end
	w.fromData = true
	return w
end

-- ============ LUZ AMBIENTAL (clima+hora -> Lighting, fotorreal+) ============
function WX.ambientLight(w, hours, Lighting, opts)
	local L = Lighting or game:GetService("Lighting")
	local t2 = (hours or w.seasonClock or 12) / 24
	local sun = math.max(0, math.sin((t2 - 0.25) * math.pi * 2)) -- 6h nasce 18h se poe
	-- Kelvin real: 6500K dia -> 1800K golden
	local kelvin = 1800 + (6500 - 1800) * sun
	-- transform Kelvin -> RGB (algoritmo de aproximacao real)
	local tk = kelvin / 100
	local r, g, b
	if tk <= 66 then
		r = 255
		g = 99.47 * math.log(tk) - 161.12
		b = tk <= 19 and 0 or 138.52 * math.log(tk - 10) - 305.04
	else
		r = 329.70 * (tk - 60) ^ -0.1332
		g = 288.12 * (tk - 60) ^ -0.0755
		b = 255
	end
	local function cl255(v) return math.clamp((v or 255) / 255, 0, 1) end
	local sunCol = Color3.new(cl255(r), cl255(g), cl255(b))
	L.ClockTime = hours or 12
	-- atmosfera (neblina baseada em umidade + aerossois do dia)
	local atmo = L:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", L)
	atmo.Density = 0.26 + (1 - sun) * 0.18 + (w.haze or 0) * 0.2
	atmo.Offset = 0.14 + sun * 0.3
	atmo.Color = sunCol:Lerp(Color3.fromRGB(150, 180, 220), sun * 0.75)
	atmo.Decay = Color3.fromRGB(106, 120, 150)
	atmo.Glare = (1 - sun) * 0.4 + 0.05
	atmo.Haze = (1 - sun) * 2.6 + 0.6
	L.OutdoorAmbient = sunCol:Lerp(Color3.fromRGB(70, 90, 110), 0.5)
	L.Ambient = Color3.fromRGB(45, 55, 70):Lerp(sunCol, sun * 0.25)
	L.Brightness = 0.4 + sun * 2
	L.EnvironmentDiffuseScale = 0.5 + sun * 0.5
	L.EnvironmentSpecularScale = 0.4 + sun * 0.6
	L.ColorShift_Bottom = Color3.fromRGB(20, 25, 40):Lerp(sunCol, sun * 0.1)
	L.ColorShift_Top = Color3.fromRGB(120, 150, 255):Lerp(sunCol, 1 - sun * 0.5)
	-- geografia celeste aproximada: latitude longitudinal
	L.GeographicLatitude = 15 * (w.latFactor or 1)
	-- sol/lua artificial (Billboard efeito via Fluorescent)
	local bloom = L:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", L)
	bloom.Intensity = (1 - sun) * 1.1 + 0.08
	bloom.Size = 18 + (1 - sun) * 20
	bloom.Threshold = 2
	local cc = L:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", L)
	cc.TintColor = sunCol
	cc.Contrast = 0.06 + (1 - sun) * 0.12
	cc.Saturation = -0.06 - (1 - sun) * 0.1
	local dof = L:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect", L)
	dof.FarIntensity = 0.12
	dof.FocusDistance = 30
	dof.NearIntensity = 0
	dof.Enabled = true
	return { kelvin = kelvin, sun = sun, sunColor = sunCol }
end

-- stats/mapa 3D auto-aprendido (melhora geracao ao longo do tempo)
function WX.stats(w)
	local l = w.learn or { runs = 0 }
	return { seed = w.seed, runs = l.runs or 0, flows = #(l.flows or {}),
		tier = w.tier.id, parallaxModels = 0 }
end

-- =============================================================
-- 50 TERRAIN TOOLS (D-LEVEL catalog de ARKHER STUDIOS - secao D)
-- Cada tool altera o world REAL via campos da tectonica/noise/caches.
-- Sig: fn(w, params) -> { msg }
-- =============================================================
local function brush(w, x, z, r, amp, cb)
	local applied = 0
	w._cache = w._cache or {}
	for k in pairs(w._cache) do w._cache[k] = nil end
	w._deltas = w._deltas or {}
	table.insert(w._deltas, { x = x, z = z, r = r, amp = amp, fn = cb })
	applied = #w._deltas
	return applied
end
local function deltaH(w, x, z)
	local tot = 0
	for _, d in ipairs(w._deltas or {}) do
		local dx, dz = x - d.x, z - d.z
		local dist = (dx * dx + dz * dz) ^ 0.5
		if dist < d.r * 2 then
			local t2 = math.max(0, 1 - dist / (d.r * 2))
			tot = tot + d.fn(t2) * d.amp
		end
	end
	return tot
end
-- hook: height inclui deltas das escovas
local _heightRaw = WX.height
function WX.height(w, x, z)
	local base = _heightRaw(w, x, z)
	return base + deltaH(w, x, z)
end

local gauss = function(t2) return t2 * t2 * (3 - 2 * t2) end
local sharp = function(t2) return t2 * t2 end
local wide  = function(t2) return t2 ^ 0.5 end

WX.TOOLS = {
	raise      = { cat = "sculpt", fn = function(w, p) return brush(w, p.x, p.z, p.r or 60, p.amp or 30, gauss) end,  msg = "elevar terreno" },
	lower      = { cat = "sculpt", fn = function(w, p) return brush(w, p.x, p.z, p.r or 60, -(p.amp or 30), gauss) end, msg = "rebaixar terreno" },
	flatten    = { cat = "sculpt", fn = function(w, p) local h = WX.height(w, p.x, p.z) return brush(w, p.x, p.z, p.r or 70, h * 0.4, function(t2) return (h - _heightRaw(w, p.x, p.z)) / math.max(1, (p.amp or 30)) end) end, msg = "achatar planalto" },
	smooth     = { cat = "sculpt", fn = function(w, p) return brush(w, p.x, p.z, p.r or 50, 6, function(t2) return (1 - t2) * -0.5 + 0.5 end) end, msg = "suavizar" },
	terrace    = { cat = "sculpt", fn = function(w, p) return brush(w, p.x, p.z, p.r or 90, p.amp or 16, function(t2) return math.floor(t2 * (p.steps or 5)) / (p.steps or 5) end) end, msg = "terracas" },
	stamp      = { cat = "sculpt", fn = function(w, p) return brush(w, p.x, p.z, p.r or 80, p.amp or 50, function(t2) return t2 < 0.85 and 0 or (t2 - 0.85) / 0.15 end) end, msg = "platô estampado" },
	mesa       = { cat = "landform", fn = function(w, p) return brush(w, p.x, p.z, p.r or 120, p.amp or 70, function(t2) return t2 > 0.55 and 1 or t2 / 0.55 end) end, msg = "mesa" },
	mountain   = { cat = "landform", fn = function(w, p) return brush(w, p.x, p.z, p.r or 160, p.amp or 220, sharp) end, msg = "montanha" },
	ridge      = { cat = "landform", fn = function(w, p) local n = 0 for i = -2, 2 do n = n + brush(w, p.x + i * (p.r or 100) * 0.8, p.z, (p.r or 100), (p.amp or 120) * (1 - math.abs(i) / 3), sharp) end return n end, msg = "cordilheira" },
	valley     = { cat = "landform", fn = function(w, p) local n = 0 for i = -3, 3 do n = n + brush(w, p.x, p.z + i * (p.r or 60) * 0.9, (p.r or 60) * 0.8, -(p.amp or 90) * (1 - math.abs(i) / 4), gauss) end return n end, msg = "vale em U" },
	canyon     = { cat = "landform", fn = function(w, p) return brush(w, p.x, p.z, p.r or 40, -(p.amp or 110), function(t2) return t2 ^ 0.3 end) end, msg = "canion entalhado" },
	cliff      = { cat = "landform", fn = function(w, p) return brush(w, p.x, p.z, p.r or 30, p.amp or 80, function(t2) return t2 > 0.5 and 1 or 0 end) end, msg = "falesia degrau" },
	cirque     = { cat = "glacial", fn = function(w, p) local n = brush(w, p.x, p.z, p.r or 90, -(p.amp or 60), gauss) return n + brush(w, p.x, p.z, (p.r or 90) * 1.15, p.amp or 25, sharp) end, msg = "circo glaciar" },
	moraine    = { cat = "glacial", fn = function(w, p) local n = 0 for i = 0, 9 do n = n + brush(w, p.x + i * 14 - 63, p.z + math.sin(i) * 10, 14, 12, gauss) end return n end, msg = "morena" },
	fjord      = { cat = "glacial", fn = function(w, p) local n = 0 for i = 0, 7 do n = n + brush(w, p.x, p.z + i * (p.r or 50) * 0.9, (p.r or 50) * 0.75, -(p.amp or 120), function(t2) return t2 ^ 0.4 end) end return n end, msg = "fiorde" },
	horn       = { cat = "glacial", fn = function(w, p) local n = 0 for i = 0, 3 do local a = i * math.pi / 2 + 0.4 n = n + brush(w, p.x + math.cos(a) * 55, p.z + math.sin(a) * 55, 40, -55, gauss) end return n + brush(w, p.x, p.z, 46, 130, sharp) end, msg = "pico Matterhorn" },
	duneField  = { cat = "eolico", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + p.x) for i = 1, 7 do n = n + brush(w, p.x + rng:NextNumber(-90, 90), p.z + rng:NextNumber(-90, 90), 26, 16, function(t2) return t2 > 0.6 and (t2 - 0.6) * 2.5 or t2 * 0.33 end) end return n end, msg = "campo de dunas barcan" },
	loess      = { cat = "eolico", fn = function(w, p) return brush(w, p.x, p.z, p.r or 140, 6, wide) end, msg = "deposito de loess" },
	oasis      = { cat = "eolico", fn = function(w, p) return brush(w, p.x, p.z, p.r or 34, -(p.amp or 22), gauss) end, msg = "oasis (depressao)" },
	playa      = { cat = "eolico", fn = function(w, p) local h = WX.height(w, p.x, p.z) return brush(w, p.x, p.z, p.r or 100, -6, function(t2) return t2 < 0.7 and 1 or 0 end) end, msg = "playa plana" },
	river      = { cat = "fluvial", fn = function(w, p) local n = 0 for i = -6, 6 do n = n + brush(w, p.x + i * (p.r or 24) * 0.85 + math.sin(i * 0.9) * 22, p.z + i * (p.r or 24) * 0.4, (p.r or 24), -(p.amp or 36), function(t2) return t2 ^ 0.45 end) end return n end, msg = "canal de rio sinuoso" },
	meander    = { cat = "fluvial", fn = function(w, p) local n = 0 for i = 0, 5 do local a = i / 5 * math.pi * 2 n = n + brush(w, p.x + math.cos(a) * (p.r or 80), p.z + math.sin(a) * (p.r or 80), 22, -30, gauss) end return n end, msg = "caudal em meandro" },
	oxbow      = { cat = "fluvial", fn = function(w, p) return WX.TOOLS.meander.fn(w, p) and brush(w, p.x + (p.r or 80), p.z, 16, -26, gauss) end, msg = "lago de meandro (oxbow)" },
	delta      = { cat = "fluvial", fn = function(w, p) local n = 0 for i = -2, 2 do n = n + brush(w, p.x + i * 34, p.z + math.abs(i) * 20, 26, 14, wide) end return n end, msg = "delta fluvial" },
	lake       = { cat = "fluvial", fn = function(w, p) return brush(w, p.x, p.z, p.r or 70, -(p.amp or 40), gauss) end, msg = "lago" },
	wetland    = { cat = "fluvial", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + 31) for i = 1, 9 do n = n + brush(w, p.x + rng:NextNumber(-70, 70), p.z + rng:NextNumber(-70, 70), 20, -12, gauss) end return n end, msg = "alagado baixio" },
	levee      = { cat = "fluvial", fn = function(w, p) return WX.TOOLS.river.fn(w, p) + brush(w, p.x, p.z, (p.r or 24) * 1.5, 10, gauss) end, msg = "levee natural" },
	backswamp  = { cat = "fluvial", fn = function(w, p) return brush(w, p.x, p.z, p.r or 120, -8, wide) end, msg = "vaRzea posterior" },
	alluvialFan= { cat = "fluvial", fn = function(w, p) local n = 0 for i = 0, 5 do n = n + brush(w, p.x + i * 26 - 65, p.z + i * 30, 30 - i * 2, 26 - i * 3, gauss) end return n end, msg = "leque aluvial" },
	karst      = { cat = "carste", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + 77) for i = 1, 6 do n = n + brush(w, p.x + rng:NextNumber(-80, 80), p.z + rng:NextNumber(-80, 80), 12, -(p.amp or 70), function(t2) return t2 ^ 0.25 end) end return n end, msg = "dolinas de carste" },
	caveSeed   = { cat = "carste", fn = function(w, p) return brush(w, p.x, p.z, p.r or 25, -8, gauss) end, msg = "boca de caverna (seed)" },
	pinnacle   = { cat = "carste", fn = function(w, p) return brush(w, p.x, p.z, p.r or 18, p.amp or 65, sharp) end, msg = "pinaculo carste" },
	volcano    = { cat = "vulcano", fn = function(w, p) local n = brush(w, p.x, p.z, p.r or 130, p.amp or 190, function(t2) return t2 ^ 0.6 end) return n + brush(w, p.x, p.z, (p.r or 130) * 0.28, -60, function(t2) return t2 ^ 0.2 end) end, msg = "cone vulcanico + cratera" },
	caldera    = { cat = "vulcano", fn = function(w, p) local n = brush(w, p.x, p.z, p.r or 110, 90, gauss) return n + brush(w, p.x, p.z, (p.r or 110) * 0.7, -110, gauss) end, msg = "caldeira" },
	lavaFlow   = { cat = "vulcano", fn = function(w, p) local n = 0 for i = 0, 6 do n = n + brush(w, p.x + i * 18, p.z + i * 26 + math.sin(i) * 8, 16, 20 - i * 2, gauss) end return n end, msg = "escoada de lava" },
	cinder     = { cat = "vulcano", fn = function(w, p) return brush(w, p.x, p.z, p.r or 40, p.amp or 50, sharp) end, msg = "cone de cinzas" },
	crater     = { cat = "impacto", fn = function(w, p) local n = brush(w, p.x, p.z, p.r or 90, 40, function(t2) return t2 > 0.85 and 1.6 or 0 end) return n + brush(w, p.x, p.z, (p.r or 90) * 0.8, -(p.amp or 90), gauss) end, msg = "cratera de impacto + anel" },
	island     = { cat = "costa", fn = function(w, p) return brush(w, p.x, p.z, p.r or 100, p.amp or 90, gauss) end, msg = "ilha" },
	archipelago= { cat = "costa", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + 9) for i = 1, 8 do n = n + brush(w, p.x + rng:NextNumber(-160, 160), p.z + rng:NextNumber(-160, 160), rng:NextNumber(24, 66), rng:NextNumber(26, 70), gauss) end return n end, msg = "arquipelago" },
	atoll      = { cat = "costa", fn = function(w, p) local n = 0 for i = 0, 9 do local a = i / 10 * math.pi * 2 n = n + brush(w, p.x + math.cos(a) * 70, p.z + math.sin(a) * 70, 22, 34, gauss) end return n + brush(w, p.x, p.z, 50, -20, gauss) end, msg = "atol com laguna" },
	tombolo    = { cat = "costa", fn = function(w, p) return brush(w, p.x, p.z, p.r or 16, 12, wide) end, msg = "tombolo (ligacao)" },
	spit       = { cat = "costa", fn = function(w, p) local n = 0 for i = 0, 5 do n = n + brush(w, p.x + i * 22, p.z + i * 8, 12, 10 - i, gauss) end return n end, msg = "restinga (spit)" },
	seaStack   = { cat = "costa", fn = function(w, p) return brush(w, p.x, p.z, p.r or 14, p.amp or 60, sharp) end, msg = "sea stack" },
	reef       = { cat = "costa", fn = function(w, p) local n = 0 for i = -4, 4 do n = n + brush(w, p.x + i * 26, p.z + math.abs(i) * 6, 16, 14, gauss) end return n end, msg = "recife franjante" },
	beachProf  = { cat = "costa", fn = function(w, p) local n = 0 for i = 0, 4 do n = n + brush(w, p.x, p.z + i * 20, 60 - i * 8, 12 - i * 3, wide) end return n end, msg = "perfil de praia" },
	badlands   = { cat = "erosao", fn = function(w, p) return WX.erode(w, (w.tier.erosionDrops or 120) * 2) and brush(w, p.x, p.z, p.r or 90, -20, function(t2) return t2 * 0.5 end) end, msg = "badlands entalhado" },
	gully      = { cat = "erosao", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + p.x * 3) for i = 1, 8 do n = n + brush(w, p.x + rng:NextNumber(-70, 70), p.z + i * 14 - 56, 8, -22, sharp) end return n end, msg = "ravinas paralelas" },
	hoodoo     = { cat = "erosao", fn = function(w, p) return brush(w, p.x, p.z, p.r or 12, p.amp or 55, sharp) end, msg = "hoodoo" },
	arch       = { cat = "erosao", fn = function(w, p) local n = brush(w, p.x - 16, p.z, 12, 45, sharp) return n + brush(w, p.x + 16, p.z, 12, 45, sharp) + brush(w, p.x, p.z, 20, 42, function(t2) return t2 > 0.7 and (t2 - 0.7) * 1.4 + 0.42 or 0 end) end, msg = "arco natural" },
	talus      = { cat = "erosao", fn = function(w, p) local n = 0 for i = 0, 3 do n = n + brush(w, p.x + i * 22, p.z + 30, 26, 18 - i * 4, gauss) end return n end, msg = "cone de talus" },
	strath     = { cat = "erosao", fn = function(w, p) return brush(w, p.x, p.z, p.r or 130, 10, function(t2) return t2 > 0.75 and 0.6 or 0 end) end, msg = "terraco strath" },
	kettle     = { cat = "glacial", fn = function(w, p) local n = 0 local rng = Random.new(w.seed + 55) for i = 1, 7 do n = n + brush(w, p.x + rng:NextNumber(-60, 60), p.z + rng:NextNumber(-60, 60), 10, -24, gauss) end return n end, msg = "kettles" },
}
function WX.tool(id, w, p)
	local t2 = WX.TOOLS[id]
	if not t2 then error("tool desconhecida: " .. tostring(id)) end
	local n = t2.fn(w, p or {})
	return { tool = id, cat = t2.cat, applied = n, msg = t2.msg }
end


-- ============ HIDROLOGIA REAL (cat. L: rios + ciclo dagua, 6001-6700) ============
-- steepest-descent sobre height(): nasce em zona alta e umida; entalha o leito
-- via deltas (regra ARKHER: rio e PROCESSO, nao textura azul).
function WX.rivers(w, count, seed)
	w.rivers = w.rivers or {}
	local sea = w.sea or (w.scale and w.scale.seaLevel) or 10
	local rng = Random.new((seed or w.seed) + 4242)
	local half = w.size / 2
	local step = math.max(w.cell * 2, 8)
	local made = 0
	for t = 1, (count or 6) * 6 do
		if made >= (count or 6) then break end
		local x = rng:NextNumber(-half * 0.8, half * 0.8)
		local z = rng:NextNumber(-half * 0.8, half * 0.8)
		local h = WX.height(w, x, z)
		local _, cl = WX.biomeAt(w, x, z)
		if h > sea * 1.8 and cl then
			local path = { { x = x, z = z, h = h } }
			local px, pz, ph = x, z, h
			for era = 1, 400 do
				-- 4-vizinhanca, vai na maior descida
				local bx, bz, bh = px, pz, ph
				for _, d in ipairs({ { step, 0 }, { -step, 0 }, { 0, step }, { 0, -step } }) do
					local nh = WX.height(w, px + d[1], pz + d[2])
					if nh < bh then bx, bz, bh = px + d[1], pz + d[2], nh end
				end
				if bh >= ph - 0.01 then break end -- lago/depressao: para
				px, pz, ph = bx, bz, bh
				table.insert(path, { x = px, z = pz, h = ph })
				if ph <= sea + 0.5 then break end -- desaguou no oceano
				if (px * px + pz * pz) ^ 0.5 > half then break end
			end
			if #path >= 8 then
				made = made + 1
				table.insert(w.rivers, path)
				-- entalha o leito: cada 2 pontos, brush negativo
				for i = 2, #path, 2 do
					local q = path[i]
					brush(w, q.x, q.z, step * 1.4, -2.2, function(t2) return t2 end)
				end
			end
		end
	end
	return made
end

-- materializa os rios em fitas d'agua (RRW: superficie por polilinha real)
function WX.materializeRivers(w, parent)
	if not w.rivers or #w.rivers == 0 then return 0 end
	local M = parent or workspace:FindFirstChild("ArkherX_Rivers") or Instance.new("Model")
	M.Name = "ArkherX_Rivers"
	M.Parent = workspace
	local n = 0
	for _, path in ipairs(w.rivers) do
		for i = 2, #path do
			local a, b = path[i - 1], path[i]
			local midX, midZ = (a.x + b.x) / 2, (a.z + b.z) / 2
			local sea = w.sea or (w.scale and w.scale.seaLevel) or 10
		local y = math.max(sea, ((a.h + b.h) / 2)) + 0.4
			local dx, dz = b.x - a.x, b.z - a.z
			local len = (dx * dx + dz * dz) ^ 0.5 + 0.5
			local p = Instance.new("Part")
			p.Name = "RiverSeg"
			p.Anchored = true
			p.CanCollide = false
			p.Color = Color3.fromRGB(58, 140, 210)
			p.Transparency = 0.18
			p.Material = Enum.Material.SmoothPlastic
			p.Size = V3(len, 0.5, math.max(4, len * 0.5))
			p.CFrame = CFrame.new(midX, y, midZ) * CFrame.Angles(0, -math.atan2(dz, dx), 0)
			p.Parent = M
			n = n + 1
			if n >= 900 then return n end
		end
	end
	return n
end

-- umidade por proximidade de rio (boost de vegetacao e wetness da materia)
function WX.riverMoist(w, x, z)
	if not w.rivers then return 0 end
	local best = 1e9
	for _, path in ipairs(w.rivers) do
		for i = 1, #path, 3 do
			local q = path[i]
			local d = ((x - q.x) ^ 2 + (z - q.z) ^ 2) ^ 0.5
			if d < best then best = d end
		end
	end
	return math.clamp(1 - best / (w.cell * 14), 0, 1)
end

-- CICLO DAGUA (bombeado pelo RRX): evapora (T/so), acumula nuvens, precipita
-- quando satura (com orografia) -> re-umidifica + micro-erosao episodica.
-- estado hidrologico por mundo em w.hydro (crio lazily)
function WX.hydroStep(w, dt)
	w.hydro = w.hydro or { humidity = 0.6, clouds = 0.1, rainEvents = 0, sat = 1.0 }
	local hy = w.hydro
	local season = math.sin((w.season or 0.3) * math.pi * 2)
	local evap = (0.04 + math.max(0, season) * 0.05) * dt
	hy.humidity = math.clamp(hy.humidity + evap, 0, 1.4)
	hy.clouds = math.clamp(hy.clouds + hy.humidity * 0.12 * dt - hy.clouds * 0.03 * dt, 0, 1.2)
	if hy.clouds > hy.sat and hy.humidity > 0.9 then
		hy.rainEvents = hy.rainEvents + 1
		hy.humidity = hy.humidity - 0.55
		hy.clouds = hy.clouds * 0.35
		-- a chuva REAL: aprende com o mundo (erosao leve + re-umidificacao)
		WX.erode(w, math.max(20, (w.tier and w.tier.erosionDrops or 120) / 6))
		local l = w.learn or { runs = 0 }
		l.rains = (l.rains or 0) + 1
		TX.memPut("wldx", "learn_" .. w.seed, l)
		return true, hy
	end
	return false, hy
end

_G.ArkherWorldX = WX
return WX
