-- FABRIC X (FABX) — o FABRICATOR universal do ARKHER:
-- "criar LITERALMENTE QUALQUER COISA" = gramatica procedural (cat. M 6701-7300)
-- sobre as primitivas reais: cada classe vira um Model composto de parts com
-- MATERIA VERDADEIRA (TX.MATTER — nao PBR de imagem) e entra no RRW
-- automaticamente (registro no RRX na hora da criacao).
-- Fabricate aceita PT ou EN ("arvore"/"tree") e uma semente: mesma seed,
-- sempre o mesmo objeto (deterministico, como manda a Tese dos D).

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local FABX = {}
local S = { fabricated = 0, byKind = {} }

-- ============ helpers de construcao ============
local function add(list, cf, size, color, mat, shape)
	list[#list + 1] = { cf = cf, size = size, color = color, mat = mat, shape = shape }
end

local function mc(name) -- cor de MATERIA real
	local m = TX and TX.MATTER[name]
	if m then return m.colA else return Color3.fromRGB(150, 150, 150) end
end
local function mcB(name)
	local m = TX and TX.MATTER[name]
	if m then return m.colB else return Color3.fromRGB(90, 90, 90) end
end

local WOOD  = Color3.fromRGB(120, 84, 52)
local WOOD2 = Color3.fromRGB(88, 60, 38)
local LEAF  = Color3.fromRGB(72, 128, 54)
local LEAF2 = Color3.fromRGB(52, 100, 40)
local METAL = Color3.fromRGB(150, 158, 170)
local GLASS = Color3.fromRGB(150, 200, 235)
local STONE = Color3.fromRGB(126, 122, 116)
local SKIN  = Color3.fromRGB(220, 178, 140)

-- parte genérica: pilar/corpo/etc
local function box(list, x, y, z, sx, sy, sz, color, shape)
	add(list, CF(x, y, z), V3(sx, sy, sz), color, nil, shape)
end

-- ============ GENERADORES (cada um: rng pre-semeado -> lista de specs) ============
-- rng = DM.rng(seed): fn().next? usamos rng():Number em [0,1) se DM; senão math.random
local function R(rng, a, b)
	if rng then
		local v = rng()
		return a + (b - a) * (v % 1)
	end
	return a + (b - a) * math.random()
end

local GEN = {}
local FAM = {} -- classe -> familia (p/ UI/debug)

-- ---- NATUREZA ----
local function genTree(rng, o, trunkH, leafSpread, leafCol, trunkCol, mode)
	local L = {}
	local h = R(rng, trunkH * 0.8, trunkH * 1.25)
	local th = R(rng, 0.5, 0.9) * (o.thick or 1)
	box(L, 0, h / 2, 0, th, h, th, trunkCol)
	local n = 3 + math.floor(R(rng, 0, 3.9))
	for i = 1, n do
		local a = R(rng, 0, math.pi * 2)
		local ry = h * R(rng, 0.55, 1.05)
		local rr = leafSpread * R(rng, 0.65, 1.15)
		add(L, CF(math.cos(a) * rr * 0.5, ry, math.sin(a) * rr * 0.5),
			V3(rr, rr * (mode == "pine" and 1.5 or 0.9), rr), (i % 2 == 0 and leafCol or LEAF2), nil, "Ball")
	end
	if mode == "palm" then
		for i = 1, 6 do
			local a = i / 6 * math.pi * 2
			add(L, CF(math.cos(a) * leafSpread * 0.8, h + 0.3, math.sin(a) * leafSpread * 0.8)
				* ANG(0, -a, math.rad(28)), V3(leafSpread * 1.6, 0.3, 0.8), LEAF, nil)
		end
	end
	return L
end

GEN.arvore    = function(rng, o) return genTree(rng, o, 7, 4.4, LEAF, WOOD) end
GEN.pinheiro  = function(rng, o) return genTree(rng, o, 9, 3.4, Color3.fromRGB(46, 96, 58), WOOD2, "pine") end
GEN.palmeira  = function(rng, o) return genTree(rng, o, 8, 2.4, LEAF, Color3.fromRGB(140, 110, 70), "palm") end
GEN.cacto     = function(rng, o)
	local L = {} local h = R(rng, 4, 7)
	box(L, 0, h / 2, 0, 1.2, h, 1.2, Color3.fromRGB(66, 132, 66))
	box(L, 1.1, h * 0.62, 0, 0.8, h * 0.3, 0.8, Color3.fromRGB(66, 132, 66))
	box(L, 1.6, h * 0.72, 0, 0.8, 1.2, 0.8, Color3.fromRGB(66, 132, 66))
	box(L, -1.1, h * 0.45, 0, 0.8, h * 0.26, 0.8, Color3.fromRGB(66, 132, 66))
	box(L, -1.6, h * 0.55, 0, 0.8, 1.2, 0.8, Color3.fromRGB(66, 132, 66))
	return L
end
GEN.arbusto   = function(rng, o)
	local L = {}
	for i = 1, 4 do
		local a = R(rng, 0, math.pi * 2)
		add(L, CF(math.cos(a) * 0.8, R(rng, 0.4, 1.2), math.sin(a) * 0.8), V3(1.6, 1.4, 1.6), LEAF2, nil, "Ball")
	end
	return L
end
GEN.flor      = function(rng, o)
	local pet = { Color3.fromRGB(230, 90, 120), Color3.fromRGB(240, 200, 80), Color3.fromRGB(150, 110, 230) }
	local c = pet[1 + math.floor(R(rng, 0, 2.9))]
	local L = {}
	box(L, 0, 0.8, 0, 0.16, 1.6, 0.16, LEAF)
	add(L, CF(0, 1.75, 0), V3(0.9, 0.5, 0.9), c, nil, "Ball")
	for i = 1, 5 do
		local a = i / 5 * math.pi * 2
		add(L, CF(math.cos(a) * 0.65, 1.7, math.sin(a) * 0.65) * ANG(0, -a, 0), V3(0.7, 0.14, 0.5), c, nil)
	end
	return L
end
GEN.cogumelo  = function(rng, o)
	local L = {}
	box(L, 0, 0.7, 0, 0.7, 1.4, 0.7, Color3.fromRGB(235, 228, 214))
	add(L, CF(0, 1.5, 0), V3(2.2, 0.9, 2.2), Color3.fromRGB(196, 56, 48), nil, "Ball")
	return L
end
GEN.pedra     = function(rng, o)
	local L = {}
	local n = 2 + math.floor(R(rng, 0, 3))
	for i = 1, n do
		local s = R(rng, 1.2, 3.6) * (o.size or 1)
		add(L, CF(R(rng, -1.4, 1.4), s / 2.3, R(rng, -1.4, 1.4)), V3(s, s * 0.8, s), (i % 2 == 0 and mc("rock") or mcB("rock")), "rock", "Ball")
	end
	return L
end
GEN.cristal   = function(rng, o)
	local L = {}
	local n = 2 + math.floor(R(rng, 0, 3))
	for i = 1, n do
		local h = R(rng, 2, 5.4)
		add(L, CF(R(rng, -1, 1), h / 2, R(rng, -1, 1)) * ANG(math.rad(R(rng, -14, 14)), 0, math.rad(R(rng, -14, 14))),
			V3(0.9, h, 0.9), Color3.fromRGB(130, 190, 255), "ice")
	end
	return L
end
GEN.montanha  = function(rng, o)
	local L = {}
	local w = (o.size or 60)
	box(L, 0, w * 0.16, 0, w, w * 0.32, w, mc("rock"), "rock")
	box(L, 0, w * 0.4, 0, w * 0.66, w * 0.24, w * 0.66, mcB("rock"), "rock")
	box(L, 0, w * 0.56, 0, w * 0.34, w * 0.14, w * 0.34, mc("snow"), "snow")
	return L
end
GEN.vulcao    = function(rng, o)
	local L = {}
	local w = (o.size or 50)
	box(L, 0, w * 0.14, 0, w, w * 0.28, w, mc("rock"), "rock")
	box(L, 0, w * 0.34, 0, w * 0.5, w * 0.16, w * 0.5, mcB("rock"), "rock")
	box(L, 0, w * 0.44, 0, w * 0.18, w * 0.05, w * 0.18, mc("lava"), "lava")
	return L
end

-- ---- ESTRUTURA ----
GEN.casa = function(rng, o)
	local L = {}
	local w, d, h = R(rng, 10, 16), R(rng, 8, 12), R(rng, 5.5, 8)
	local wall = (o.color or Color3.fromRGB(214, 190, 150))
	box(L, 0, h / 2, 0, w, h, d, wall)
	add(L, CF(0, h + h * 0.16, 0), V3(w * 1.14, h * 0.36, d * 1.14), WOOD2, nil, "Wedge")
	box(L, 0, h * 0.32, d / 2 + 0.06, 1.8, h * 0.62, 0.3, WOOD)
	for _, sx in ipairs({ -1, 1 }) do
		box(L, sx * w * 0.3, h * 0.55, d / 2 + 0.06, 1.6, 1.6, 0.26, GLASS)
	end
	return L
end
GEN.predio = function(rng, o)
	local L = {}
	local w, d = R(rng, 14, 22), R(rng, 14, 22)
	local floors = 3 + math.floor(R(rng, 0, 8.9))
	local fh = 3.2
	local face = { Color3.fromRGB(170, 176, 186), Color3.fromRGB(150, 140, 128), Color3.fromRGB(120, 132, 150) }
	local c = face[1 + math.floor(R(rng, 0, 2.9))]
	box(L, 0, floors * fh / 2, 0, w, floors * fh, d, c)
	for f = 0, floors - 1 do
		for i = -2, 2 do
			box(L, i * w / 5, (f + 0.55) * fh, d / 2 + 0.05, w / 8, fh * 0.44, 0.2, GLASS)
			box(L, i * w / 5, (f + 0.55) * fh, -d / 2 - 0.05, w / 8, fh * 0.44, 0.2, GLASS)
		end
	end
	return L
end
GEN.torre = function(rng, o)
	local L = {}
	local h = R(rng, 18, 34)
	box(L, 0, h / 2, 0, 6, h, 6, STONE, "rock")
	add(L, CF(0, h + 2, 0), V3(7.6, 4, 7.6), WOOD2, nil, "Wedge")
	for i = 1, 3 do box(L, 0, h * (0.25 + i * 0.2), 3.1, 1, 2, 0.2, GLASS) end
	return L
end
GEN.ponte = function(rng, o)
	local L = {}
	local sp = (o.size or 30)
	box(L, 0, 6, 0, sp, 1.2, 5, STONE, "rock")
	for _, sx in ipairs({ -1, 1 }) do
		box(L, sx * sp * 0.36, 3, 0, 2.4, 6, 5.6, STONE, "rock")
		box(L, 0, 7, sx * 2.6, sp, 1, 0.5, WOOD)
	end
	for i = -3, 3 do
		local x = i / 3 * (sp * 0.28)
		box(L, x, 2.4, 0, 1, 4.4, 4.2, STONE, "rock")
	end
	return L
end
GEN.muro = function(rng, o)
	local L = {}
	local ln = (o.size or 20)
	box(L, 0, 2, 0, ln, 4, 1.2, STONE, "rock")
	for i = -2, 2 do box(L, i * ln / 5, 4.4, 0, 1.6, 0.9, 1.5, mcB("rock"), "rock") end
	return L
end
GEN.cerca = function(rng, o)
	local L = {}
	local ln = (o.size or 16)
	for i = 0, math.floor(ln / 2.4) do box(L, i * 2.4 - ln / 2, 1.2, 0, 0.3, 2.4, 0.3, WOOD2) end
	box(L, 0, 1.7, 0, ln, 0.24, 0.2, WOOD)
	box(L, 0, 0.9, 0, ln, 0.24, 0.2, WOOD)
	return L
end
GEN.escada = function(rng, o)
	local L = {}
	local n = (o.size or 8)
	for i = 0, n - 1 do box(L, 0, i * 0.5 + 0.25, i * 1.2, 3, 0.5, 1.2, STONE) end
	return L
end
GEN.porta = function(rng, o)
	local L = {}
	box(L, -1.6, 2.4, 0, 0.6, 4.8, 0.8, WOOD2)
	box(L, 1.6, 2.4, 0, 0.6, 4.8, 0.8, WOOD2)
	box(L, 0, 4.8, 0, 3.8, 0.6, 0.8, WOOD2)
	box(L, 0, 2.3, 0, 2.6, 4.4, 0.3, WOOD)
	return L
end
GEN.coluna = function(rng, o)
	local L = {}
	local h = R(rng, 6, 10)
	box(L, 0, h / 2, 0, 1.4, h, 1.4, Color3.fromRGB(228, 224, 216), nil, "Cylinder")
	box(L, 0, 0.35, 0, 2.2, 0.7, 2.2, Color3.fromRGB(216, 212, 204))
	box(L, 0, h + 0.35, 0, 2.4, 0.7, 2.4, Color3.fromRGB(216, 212, 204))
	return L
end
GEN.fonte = function(rng, o)
	local L = {}
	add(L, CF(0, 0.6, 0), V3(7, 1.2, 7), STONE, "rock", "Cylinder")
	add(L, CF(0, 0.8, 0), V3(6, 0.5, 6), Color3.fromRGB(90, 160, 220), nil, "Cylinder")
	box(L, 0, 2.2, 0, 1, 3, 1, STONE)
	add(L, CF(0, 3.8, 0), V3(2.6, 0.5, 2.6), Color3.fromRGB(120, 190, 240), nil, "Cylinder")
	return L
end

-- ---- MOBILIARIO ----
GEN.mesa = function(rng, o)
	local L = {}
	box(L, 0, 2.6, 0, 5, 0.4, 3, WOOD)
	for _, sx in ipairs({ -2.2, 2.2 }) do for _, sz in ipairs({ -1.2, 1.2 }) do box(L, sx, 1.2, sz, 0.4, 2.4, 0.4, WOOD2) end end
	return L
end
GEN.cadeira = function(rng, o)
	local L = {}
	box(L, 0, 1.6, 0, 2, 0.3, 2, WOOD)
	for _, sx in ipairs({ -0.8, 0.8 }) do for _, sz in ipairs({ -0.8, 0.8 }) do box(L, sx * (sz > 0 and 1 or 0.8), 0.75, sz, 0.26, 1.5, 0.26, WOOD2) end end
	box(L, 0, 2.9, -0.9, 2, 2.4, 0.3, WOOD)
	return L
end
GEN.sofa = function(rng, o)
	local c = o.color or Color3.fromRGB(140, 60, 70)
	local L = {}
	box(L, 0, 1, 0, 5, 1.4, 2.2, c)
	box(L, 0, 2.2, -0.9, 5, 1.6, 0.5, c)
	box(L, -2.4, 1.8, 0, 0.6, 1.8, 2.2, c)
	box(L, 2.4, 1.8, 0, 0.6, 1.8, 2.2, c)
	return L
end
GEN.cama = function(rng, o)
	local L = {}
	box(L, 0, 0.9, 0, 4.4, 0.8, 6.6, WOOD2)
	box(L, 0, 1.5, 0, 4.2, 0.5, 6.2, Color3.fromRGB(238, 236, 230))
	box(L, 0, 1.9, -2.4, 4, 0.7, 1.3, Color3.fromRGB(250, 248, 244))
	box(L, 0, 2, -3.2, 4.4, 3, 0.4, WOOD)
	return L
end
GEN.estante = function(rng, o)
	local L = {}
	box(L, 0, 3, 0, 4, 6, 0.8, WOOD2)
	local liv = { Color3.fromRGB(190, 70, 60), Color3.fromRGB(70, 120, 190), Color3.fromRGB(90, 170, 90), Color3.fromRGB(220, 180, 60) }
	for f = 0, 2 do
		for i = 0, 4 do
			box(L, -1.5 + i * 0.75, 1.2 + f * 2, 0.2, 0.5, 1.2, 0.5, liv[(i + f) % 4 + 1])
		end
	end
	return L
end
GEN.lampada = function(rng, o)
	local L = {}
	box(L, 0, 2.6, 0, 0.3, 5.2, 0.3, METAL)
	add(L, CF(0, 5.4, 0), V3(1.6, 1.4, 1.6), Color3.fromRGB(255, 236, 170), nil, "Ball")
	box(L, 0, 0.15, 0, 1.6, 0.3, 1.6, METAL)
	return L
end
GEN.vaso = function(rng, o)
	local L = {}
	add(L, CF(0, 0.8, 0), V3(1.4, 1.6, 1.4), Color3.fromRGB(176, 96, 60), nil, "Cylinder")
	box(L, 0, 2.1, 0, 0.3, 1.4, 0.3, LEAF2)
	add(L, CF(0, 2.9, 0), V3(1.3, 1, 1.3), LEAF, nil, "Ball")
	return L
end

-- ---- VEICULOS ----
GEN.carro = function(rng, o)
	local c = o.color or ({ Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 90, 200), Color3.fromRGB(230, 200, 60), Color3.fromRGB(46, 46, 52) })[1 + math.floor(R(rng, 0, 3.9))]
	local L = {}
	box(L, 0, 1.1, 0, 7, 1.4, 3, c)
	box(L, -0.4, 2.2, 0, 3.6, 1.2, 2.7, c)
	box(L, -0.4, 2.2, 0, 3.7, 1, 2.71, GLASS)
	for _, sx in ipairs({ -2.3, 2.3 }) do
		for _, sz in ipairs({ -1.6, 1.6 }) do
			add(L, CF(sx, 0.6, sz), V3(1.2, 1.2, 0.6), Color3.fromRGB(30, 30, 34), nil, "Cylinder")
		end
	end
	return L
end
GEN.roda = function(rng, o)
	local L = {}
	add(L, CF(0, 1.4, 0), V3(2.8, 2.8, 0.7), Color3.fromRGB(28, 28, 32), nil, "Cylinder")
	add(L, CF(0, 1.4, 0), V3(1.2, 1.2, 0.78), METAL, nil, "Cylinder")
	return L
end
GEN.barco = function(rng, o)
	local L = {}
	add(L, CF(0, 1.2, 0), V3(9, 2.4, 3.6), WOOD, nil)
	box(L, 0, 2.7, 0, 5, 0.8, 2.6, Color3.fromRGB(238, 238, 238))
	box(L, 0, 5, 0, 0.3, 7, 0.3, WOOD2)
	add(L, CF(0.8, 5.6, 0) * ANG(0, 0, math.rad(-16)), V3(4, 5, 0.12), Color3.fromRGB(240, 240, 236))
	return L
end
GEN.aviao = function(rng, o)
	local c = o.color or Color3.fromRGB(230, 232, 236)
	local L = {}
	add(L, CF(0, 2, 0), V3(11, 2.4, 2.4), c, nil, "Cylinder")
	add(L, CF(0, 2, 0), V3(3, 0.4, 12), c)
	add(L, CF(4.4, 2.6, 0) * ANG(0, 0, math.rad(35)), V3(2.4, 2.4, 2.4), c, nil, "Cylinder")
	box(L, 5.4, 3.6, 0, 1.2, 3, 0.3, c)
	box(L, 5.4, 2.6, 0, 1, 0.3, 4, c)
	return L
end
GEN.nave = function(rng, o)
	local L = {}
	add(L, CF(0, 2.4, 0), V3(8, 2, 8), METAL, nil, "Cylinder")
	add(L, CF(0, 1.2, 0), V3(11, 1.2, 11), Color3.fromRGB(120, 126, 138), nil, "Cylinder")
	add(L, CF(0, 3.4, 0), V3(3.4, 1.6, 3.4), GLASS, nil, "Ball")
	for i = 1, 4 do
		local a = i / 4 * math.pi * 2
		box(L, math.cos(a) * 5.6, 0.6, math.sin(a) * 5.6, 0.6, 1.2, 0.6, METAL)
	end
	return L
end

-- ---- PROPS / ARMAS ----
GEN.espada = function(rng, o)
	local L = {}
	box(L, 0, 3.4, 0, 0.5, 5.2, 0.16, Color3.fromRGB(208, 214, 222))
	box(L, 0, 0.9, 0, 1.7, 0.34, 0.34, METAL)
	box(L, 0, 0.35, 0, 0.4, 0.9, 0.4, WOOD2)
	add(L, CF(0, 6.05, 0), V3(0.4, 0.3, 0.14), Color3.fromRGB(208, 214, 222), nil, "Wedge")
	return L
end
GEN.escudo = function(rng, o)
	local L = {}
	add(L, CF(0, 2, 0), V3(2.6, 3.4, 0.3), Color3.fromRGB(120, 60, 40), nil, "Cylinder")
	add(L, CF(0, 2, 0.2), V3(1, 1, 0.2), METAL, nil, "Ball")
	return L
end
GEN.caixa = function(rng, o)
	local L = {}
	local s = R(rng, 1.6, 3.4)
	box(L, 0, s / 2, 0, s, s, s, WOOD)
	box(L, 0, s / 2, s / 2 + 0.02, s * 0.7, s * 0.16, 0.06, WOOD2)
	return L
end
GEN.barril = function(rng, o)
	local L = {}
	add(L, CF(0, 1.4, 0), V3(2.2, 2.8, 2.2), WOOD, nil, "Cylinder")
	add(L, CF(0, 2, 0), V3(2.3, 0.2, 2.3), METAL, nil, "Cylinder")
	add(L, CF(0, 0.8, 0), V3(2.3, 0.2, 2.3), METAL, nil, "Cylinder")
	return L
end
GEN.placa = function(rng, o)
	local L = {}
	box(L, 0, 2, 0, 0.3, 4, 0.3, WOOD2)
	box(L, 0, 4.3, 0, 3.4, 1.6, 0.25, WOOD)
	return L
end
GEN.bau = function(rng, o)
	local L = {}
	box(L, 0, 0.9, 0, 2.8, 1.8, 1.7, WOOD)
	add(L, CF(0, 1.9, 0), V3(2.8, 0.7, 1.7), WOOD2, nil, "Cylinder")
	box(L, 0, 1.2, 0.88, 0.5, 0.6, 0.06, Color3.fromRGB(230, 190, 60))
	return L
end
GEN.estatua = function(rng, o)
	local L = {}
	box(L, 0, 0.6, 0, 3, 1.2, 3, STONE, "rock")
	box(L, 0, 3.2, 0, 1.6, 4, 1.1, STONE, "rock")
	add(L, CF(0, 5.8, 0), V3(1, 1, 1), STONE, "rock", "Ball")
	box(L, -1.1, 4, 0, 0.5, 2.4, 0.6, STONE, "rock")
	box(L, 1.1, 4, 0, 0.5, 2.4, 0.6, STONE, "rock")
	return L
end

-- ---- ORGANICO ----
GEN.personagem = function(rng, o)
	local roupa = o.color or ({ Color3.fromRGB(60, 100, 200), Color3.fromRGB(200, 80, 60), Color3.fromRGB(80, 170, 90) })[1 + math.floor(R(rng, 0, 2.9))]
	local L = {}
	box(L, -0.45, 1, 0, 0.8, 2, 0.9, Color3.fromRGB(52, 58, 74))
	box(L, 0.45, 1, 0, 0.8, 2, 0.9, Color3.fromRGB(52, 58, 74))
	box(L, 0, 3, 0, 2, 2.2, 1.1, roupa)
	box(L, -1.35, 3, 0, 0.6, 2, 0.7, roupa)
	box(L, 1.35, 3, 0, 0.6, 2, 0.7, roupa)
	add(L, CF(0, 4.9, 0), V3(1.2, 1.2, 1.2), SKIN, nil, "Ball")
	return L
end
GEN.criatura = function(rng, o)
	local c = o.color or ({ Color3.fromRGB(120, 190, 90), Color3.fromRGB(150, 90, 190), Color3.fromRGB(90, 160, 190) })[1 + math.floor(R(rng, 0, 2.9))]
	local L = {}
	local n = 3 + math.floor(R(rng, 0, 3.9))
	add(L, CF(0, 1.6, 0), V3(2.6, 1.8, 3.4), c, nil, "Ball")
	add(L, CF(0, 2.2, 2.1), V3(1.6, 1.3, 1.5), c, nil, "Ball")
	for i = 1, n do
		local a = i / n * math.pi * 2
		box(L, math.cos(a) * 1.5, 0.7, math.sin(a) * 1.5, 0.5, 1.4, 0.5, c)
	end
	add(L, CF(-0.4, 2.5, 2.8), V3(0.4, 0.4, 0.2), Color3.fromRGB(250, 250, 250), nil, "Ball")
	add(L, CF(0.4, 2.5, 2.8), V3(0.4, 0.4, 0.2), Color3.fromRGB(250, 250, 250), nil, "Ball")
	return L
end
GEN.ave = function(rng, o)
	local L = {}
	add(L, CF(0, 1.2, 0), V3(1, 1, 1.6), Color3.fromRGB(80, 110, 180), nil, "Ball")
	add(L, CF(0, 1.6, 0.9), V3(0.55, 0.55, 0.55), Color3.fromRGB(80, 110, 180), nil, "Ball")
	box(L, 0, 1.55, 1.35, 0.3, 0.18, 0.5, Color3.fromRGB(240, 180, 60))
	add(L, CF(-0.8, 1.3, -0.1) * ANG(0, 0, math.rad(18)), V3(1.6, 0.14, 0.9), Color3.fromRGB(64, 92, 150))
	add(L, CF(0.8, 1.3, -0.1) * ANG(0, 0, math.rad(-18)), V3(1.6, 0.14, 0.9), Color3.fromRGB(64, 92, 150))
	box(L, 0, 0.5, 0.25, 0.12, 1, 0.12, Color3.fromRGB(200, 160, 60))
	return L
end
GEN.peixe = function(rng, o)
	local c = o.color or Color3.fromRGB(240, 130, 60)
	local L = {}
	add(L, CF(0, 1, 0), V3(1.1, 1.4, 2.4), c, nil, "Ball")
	add(L, CF(0, 1, -1.4) * ANG(0, 0, math.rad(45)), V3(0.2, 1.2, 0.9), c)
	add(L, CF(-0.45, 1.35, 0.9), V3(0.24, 0.24, 0.12), Color3.fromRGB(250, 250, 250), nil, "Ball")
	add(L, CF(0.45, 1.35, 0.9), V3(0.24, 0.24, 0.12), Color3.fromRGB(250, 250, 250), nil, "Ball")
	return L
end

-- ---- EXOTICOS da realidade (ARKHER originals) ----
GEN.antena = function(rng, o)
	local L = {}
	local h = R(rng, 10, 18)
	box(L, 0, h / 2, 0, 0.7, h, 0.7, METAL)
	add(L, CF(1.4, h * 0.85, 0) * ANG(0, 0, math.rad(20)), V3(2.6, 2.6, 0.4), Color3.fromRGB(220, 224, 230), nil, "Cylinder")
	box(L, 0, h + 0.5, 0, 0.2, 1, 0.2, Color3.fromRGB(255, 60, 60))
	return L
end
GEN.arco = function(rng, o)
	local L = {}
	box(L, -3, 4, 0, 2, 8, 2, STONE, "rock")
	box(L, 3, 4, 0, 2, 8, 2, STONE, "rock")
	box(L, 0, 8.6, 0, 10, 1.8, 2, STONE, "rock")
	return L
end
GEN.telhado = function(rng, o)
	local L = {}
	add(L, CF(0, 1.2, 0), V3(12, 2.6, 9), WOOD2, nil, "Wedge")
	return L
end
GEN.janela = function(rng, o)
	local L = {}
	box(L, 0, 2, 0, 3, 4, 0.4, WOOD2)
	box(L, 0, 2, 0.1, 2.4, 3.4, 0.2, GLASS)
	box(L, 0, 2, 0.25, 0.2, 3.4, 0.1, WOOD)
	return L
end
GEN.ilha = function(rng, o)
	local L = GEN.montanha(rng, { size = (o.size or 36) })
	for i = 1, 3 do
		local rng2 = DM and DM.rng((o.seed or 1) * 31 + i) or nil
		local T = genTree(rng2, o, 6, 2.2, LEAF, Color3.fromRGB(140, 110, 70), "palm")
		local ox = R(rng, -8, 8)
		local oz = R(rng, -8, 8)
		for _, t2 in ipairs(T) do
			add(L, CF(ox, 36 * 0.62, oz) * t2.cf, t2.size, t2.color, t2.mat, t2.shape)
		end
	end
	return L
end

-- ============ sinonimos PT/EN + catalogo ============
local SYN = {
	tree = "arvore", pine = "pinheiro", palm = "palmeira", cactus = "cacto",
	bush = "arbusto", flower = "flor", mushroom = "cogumelo", rock = "pedra",
	stone = "pedra", crystal = "cristal", mountain = "montanha", volcano = "vulcao",
	house = "casa", building = "predio", tower = "torre", bridge = "ponte",
	wall = "muro", fence = "cerca", stairs = "escada", door = "porta",
	column = "coluna", fountain = "fonte", table = "mesa", chair = "cadeira",
	couch = "sofa", bed = "cama", shelf = "estante", lamp = "lampada",
	pot = "vaso", car = "carro", wheel = "roda", boat = "barco", ship = "barco",
	plane = "aviao", airplane = "aviao", ufo = "nave", sword = "espada",
	shield = "escudo", box = "caixa", crate = "caixa", barrel = "barril",
	sign = "placa", chest = "bau", statue = "estatua", character = "personagem",
	person = "personagem", human = "personagem", creature = "criatura",
	bird = "ave", fish = "peixe", antenna = "antena", arch = "arco",
	roof = "telhado", window = "janela", island = "ilha",
}

function FABX.list()
	local out = {}
	for k in pairs(GEN) do out[#out + 1] = k end
	table.sort(out)
	return out
end

-- ============ fabricate: O PEDIDO UNIVERSAL ============
-- spec: string ("arvore"/"tree") ou {kind=..., seed=..., size=..., color=...}
function FABX.fabricate(spec, opts)
	opts = opts or {}
	local kind = type(spec) == "string" and spec or (spec.kind or spec[1] or "arvore")
	kind = tostring(kind):lower():gsub("^%s*(.-)%s*$", "%1"):gsub("ç", "c"):gsub("ã", "a"):gsub("é", "e"):gsub("í", "i"):gsub("ú", "u")
	kind = SYN[kind] or kind
	local gen = GEN[kind]
	if not gen then
		return nil, ("classe desconhecida '%s' — classes: %s"):format(kind, table.concat(FABX.list(), ", "))
	end
	local seed = (type(spec) == "table" and spec.seed) or opts.seed or 1
	local rng = DM and DM.rng(seed) or nil
	local o = (type(spec) == "table" and spec) or {}
	o.seed = seed
	for k, v in pairs(opts) do o[k] = o[k] or v end
	local parts = gen(rng, o)

	local model = Instance.new("Model")
	model.Name = "FAB_" .. kind .. "_" .. tostring(seed)
	local mainMat = "soil"
	for i, pt in ipairs(parts) do
		local p
		local shape = pt.shape
		if shape == "Ball" or shape == "Cylinder" or shape == "Wedge" then
			p = Instance.new("Part")
			p.Shape = shape == "Ball" and Enum.PartType.Ball or p.Shape
			if shape == "Cylinder" then p.Shape = Enum.PartType.Cylinder end
			if shape == "Wedge" then p = Instance.new("WedgePart") end
		else
			p = Instance.new("Part")
		end
		p.Name = "p" .. i
		p.Size = pt.size
		p.CFrame = pt.cf
		p.Color = pt.color
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		if pt.mat then mainMat = pt.mat end
	end
	local pv = opts.pos or V3(0, 0, 0)
	model:PivotTo(CF(pv))
	model.Parent = workspace
	S.fabricated = S.fabricated + 1
	S.byKind[kind] = (S.byKind[kind] or 0) + 1

	-- RRW AUTOMATICO: a coisa criada JA entra na realidade (sem toque manual)
	local RX2 = rawget(_G, "ArkherRealityX")
	if RX2 and RX2.register then
		local imp = (kind == "personagem" or kind == "criatura") and 0.85 or 0.6
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				RX2.register(d, { kind = "part", matter = mainMat, importance = imp,
					parent = model, meta = { fabKind = kind, seed = seed } })
			end
		end
	end
	return { model = model, kind = kind, seed = seed, parts = #parts }
end

function FABX.stats()
	return { fabricated = S.fabricated, kinds = #FABX.list(), byKind = S.byKind }
end

_G.ArkherFabricX = FABX
return FABX
