--[[ ARKHER — D-MATH: camada matematica de campos (fundamento RRW) ]]
-- "Qual D e necessario para representar o problema?" — aqui ficam as
-- representacoes continuas discretizadas: ruido deterministico, campos
-- escalares, curvas e classificadores fisicos (Whittaker). Tudo DETERMINISTICO
-- por semente: a mesma realidade, a mesma materializacao, em qualquer D-O15.
-- Sem bitwise ops (compatibilidade total Lua 5.1 / Luau / shim de testes).
_G.ArkherDM = _G.ArkherDM or {}
local M = _G.ArkherDM

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
return M
