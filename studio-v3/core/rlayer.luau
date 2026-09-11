-- RLAYER (RLX) — REALITY LAYER (tech ARKHER original, cat. Z 13301-15000):
-- a realidade nao e UM terreno: sao CINCO CAMADAS vivas sobrepostas —
--   GEO (rocha/solo/alvo) · HYDRO (umidade/água) · ATMO (nuvem/neblina local)
--   BIO (vida por célula) · URB (carga humana: cidades/estradas)
-- Cada camada evolui sozinha (advecção do vento, logística, deposição) e
-- COMPOEM juntas a cor/micromatéria de cada célula do mundo. Camadas se
-- alimentam (ATMO umida -> HYDRO, HYDRO -> BIO, URB come BIO) — REALIDADE.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local WX = rawget(_G, "ArkherWorldX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local RL = {}
local S = {
	world = nil, cell = 16, t = 0, acc = 0,
	layers = { GEO = {}, HYDRO = {}, ATMO = {}, BIO = {}, URB = {} },
	composed = 0, tintApplied = 0,
}

RL.LAYERS = { "GEO", "HYDRO", "ATMO", "BIO", "URB" }

local function key(x, z)
	return math.floor(x / S.cell + 0.5) .. ":" .. math.floor(z / S.cell + 0.5)
end

-- ============ constrói as camadas sobre o mundo ============
function RL.build(w)
	S.world = w
	S.cell = math.max(8, (w.cell or 8) * 2)
	local half = w.size / 2
	local sea = w.sea or (w.scale and w.scale.seaLevel) or 10
	local step = S.cell * 3 -- amostragem; interpolação no compor
	for x = -half, half, step do
		for z = -half, half, step do
			local k = key(x, z)
			local h = WX.height(w, x, z)
			local bi, cl = WX.biomeAt(w, x, z)
			local geo = math.clamp((h + 60) / 400, 0, 1)
			local wet = h < sea and 1 or math.clamp(0.5 - (h - sea) / 120, 0, 1)
			local veg = (type(bi) == "table" and bi.veg) or 0.4
			S.layers.GEO[k] = geo
			S.layers.HYDRO[k] = math.clamp((cl and cl.P or 600) / 2000 + wet * 0.4, 0, 1)
			S.layers.ATMO[k] = 0.2 + (cl and cl.cloud or 0) * 0.5
			S.layers.BIO[k] = veg * math.clamp(S.layers.HYDRO[k], 0.15, 1)
			S.layers.URB[k] = 0
		end
	end
	S.composed = 0
	local n = 0
	for _ in pairs(S.layers.GEO) do n = n + 1 end
	return n
end

-- URB: registra carga humana (CIVIX chama ao fabricar assentamentos)
function RL.urbanize(cx, cz, radius, weight)
	if not S.world then return end
	S.urbSpots = S.urbSpots or {}
	S.urbSpots[#S.urbSpots + 1] = { x = cx, z = cz, r = radius or 40, w = weight or 0.6 }
end

-- ============ evolução das camadas (pulso vivo) ============
function RL.step(dt)
	if not S.world then return end
	S.t = S.t + dt
	S.acc = S.acc + dt
	if S.acc < 2.5 then return end
	local dtm = S.acc
	S.acc = 0
	local w = S.world
	-- ATMO advecta com o vento (WEAX se estiver rodando), difunde e descarrega em HYDRO
	local WXW = rawget(_G, "ArkherWeaX")
	local wind = WXW and WXW.S and WXW.S.wind or Vector2.new(2, 1)
	local rng = DM and DM.rng((S.t * 7) % 99991)
	local moves = 0
	for k, atm in pairs(S.layers.ATMO) do
		if moves > 40 then break end
		moves = moves + 1
		-- difusão leve: vizinho aleatório ganha parte
		if atm > 0.35 then
			local rain = (atm - 0.35) * 0.18 * dtm
			S.layers.ATMO[k] = math.max(0.1, atm - rain)
			S.layers.HYDRO[k] = math.clamp((S.layers.HYDRO[k] or 0.5) + rain * 0.7, 0, 1)
		end
		if rng() < 0.08 then
			S.layers.ATMO[k] = math.clamp(atm + (rng() - 0.45) * 0.12 * dtm, 0.05, 1)
		end
	end
	-- HYDRO evapora condensando em ATMO; BIO cresce/com HYDRO (logístico curto)
	for k, hy in pairs(S.layers.HYDRO) do
		local evap = hy * 0.02 * dtm
		S.layers.HYDRO[k] = math.clamp(hy - evap * 0.5, 0, 1)
		S.layers.ATMO[k] = math.clamp((S.layers.ATMO[k] or 0.2) + evap, 0, 1)
		local bio = S.layers.BIO[k] or 0.2
		local grow = 0.05 * bio * (1 - bio) * (hy > 0.25 and 1 or -0.6)
		S.layers.BIO[k] = math.clamp(bio + grow * dtm, 0, 1)
	end
	-- URB: spots decaem devagar (cidade persiste)
	S.urbT = (S.urbT or 0) + dtm
end

-- ============ COMPOSIÇÃO: a cor que a realidade manda ============
-- retorna camadas efetivas num ponto (urbano distorce bio, hidro escurece)
function RL.composeAt(x, z)
	if not S.world then return nil end
	local k = key(x, z)
	local geo = S.layers.GEO[k] or 0.5
	local hyw = S.layers.HYDRO[k] or 0.4
	local atm = S.layers.ATMO[k] or 0.2
	local bio = S.layers.BIO[k] or 0.3
	local urb = 0
	if S.urbSpots then
		for _, sp in ipairs(S.urbSpots) do
			local d = ((x - sp.x) ^ 2 + (z - sp.z) ^ 2) ^ 0.5
			if d < sp.r then urb = math.max(urb, sp.w * (1 - d / sp.r)) end
		end
	end
	return { geo = geo, wet = hyw, cloud = atm, bio = bio * (1 - urb * 0.8), urb = urb }
end

-- tint aplicado pelo RRX.materialize: wet escurece, bio esverdeia, urb acinzenta
function RL.tintFor(x, z, col, ent)
	local c = RL.composeAt(x, z)
	if not c then return col end
	local r, g, b = col.R, col.G, col.B
	local wetF = 1 - c.wet * 0.28
	r, g, b = r * wetF, g * wetF, b * (wetF + c.wet * 0.06)
	g = math.min(1, g + c.bio * 0.10)
	r = r * (1 - c.bio * 0.06)
	if c.urb > 0 then
		local m = (r + g + b) / 3
		r = r + (m - r) * c.urb * 0.6
		g = g + (m - g) * c.urb * 0.6
		b = b + (m - b) * c.urb * 0.6
	end
	if c.cloud > 0.7 then
		local d = (c.cloud - 0.7) * 0.12
		r, g, b = r * (1 - d), g * (1 - d), b * (1 - d)
	end
	S.tintApplied = S.tintApplied + 1
	return Color3.new(math.clamp(r, 0, 1), math.clamp(g, 0, 1), math.clamp(b, 0, 1))
end

function RL.stats()
	local n = 0
	for _ in pairs(S.layers.GEO) do n = n + 1 end
	return { world = S.world ~= nil, cells = n, urbSpots = S.urbSpots and #S.urbSpots or 0,
		tintApplied = S.tintApplied, layers = RL.LAYERS }
end

do
	if RX and RX.hook then RX.hook("rlayer", function(dt) RL.step(dt) end) end
end

_G.ArkherRLayer = RL
return RL
