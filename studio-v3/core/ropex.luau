-- =============================================================
-- ROPE X / RPX v1 — Corda + TECIDO por integracao de VERLET REAL
-- Roblox nao tem simulacao de cloth/rope — entao nos construimos:
-- particulas de Verlet (x += (x-pp)*damp + a*dt^2), constraints de
-- distancia iteradas (relacao relaxation), colisao com esferas e
-- plano solo, gravidade real e VENTO VIVO ligado ao ATMOS X
-- (tempestade -> bandeira em espiral, forsada por ruido organico).
-- Materializacao REAL: cada segmento vira Part fina ancorada — a
-- corda/tecido e GEOMETRIA no workspace, nao efeito visual. 🏳️
-- =============================================================

local RPX = {}
RPX._V = 1
RPX.VERSION = "1.0"

local sqrt, floor, min, max, sin, cos, pi = math.sqrt, math.floor, math.min, math.max, math.sin, math.cos, math.pi
local function lint(a, b, t) return a + (b - a) * t end

RPX.G = 35 -- gravidade do mundo (studs/s^2)

-- particula de verlet
local function p3(x, y, z, pinned)
	return { x = x, y = y, z = z, px = x, py = y, pz = z, pin = pinned or false }
end

RPX._ropes = {}
RPX._cloths = {}
RPX._spheres = {} -- {x,y,z,r}
RPX._fires, RPX._ring = {}, 1
local function fire(e) RPX._fires[RPX._ring] = e RPX._ring = (RPX._ring % 60) + 1 end

RPX.ITERS = 5 -- passes de relaxamento (estabilidade real)

-- ---------- CORDA (pontos encadeados) ----------
-- opts: from={x,y,z}, to={x,y,z} (opcional -> pendurada em from), points=10,
--       slack=1.1 (folga), parts=true (materializa Parts)
function RPX.rope(opts)
	opts = opts or {}
	local n = opts.points or 10
	local from = opts.from or { x = 0, y = 10, z = 0 }
	local to = opts.to
	local pts = {}
	local endY = from.y
	if not to then endY = from.x and (opts.length or n * 1.2) or endY end
	local toEnd = to or { x = from.x, y = from.y - (opts.length or n * 1.2), z = from.z }
	for i = 1, n do
		local t = (i - 1) / (n - 1)
		local p = p3(lint(from.x, toEnd.x, t), lint(from.y, toEnd.y, t), lint(from.z, toEnd.z, t), false)
		pts[i] = p
	end
	pts[1].pin = true
	if to then pts[n].pin = true end
	local slack = opts.slack or 1.05
	local rest = sqrt((toEnd.x - from.x) ^ 2 + (toEnd.y - from.y) ^ 2 + (toEnd.z - from.z) ^ 2) / (n - 1) * slack
	local r = { pts = pts, rest = rest, kind = "rope", name = opts.name or ("RPX_Rope_" .. (#RPX._ropes + 1)), damp = opts.damp or 0.995, windPhase = 0, model = nil }
	r.windPhase = (from.x * 13.37 + from.y * 7.77) % 6.28
	RPX._ropes[#RPX._ropes + 1] = r
	fire("rope:" .. r.name)
	return r
end

-- ---------- TECIDO (grade W x H) ----------
-- opts: origin={x,y,z} (topo-esquerdo), cols=12, rows=8, spacing=1.2,
--       pinned="top"|"topcorners", parts=true
function RPX.cloth(opts)
	opts = opts or {}
	local cols = opts.cols or 12
	local rows = opts.rows or 8
	local sp = opts.spacing or 1.2
	local o = opts.origin or { x = -6, y = 12, z = 0 }
	local pinMode = opts.pinned or "top"
	local pts = {}
	for j = 1, rows do
		pts[j] = {}
		for i = 1, cols do
			local pinned = false
			if pinMode == "top" and j == 1 then pinned = true end
			if pinMode == "topcorners" and j == 1 and (i == 1 or i == cols) then pinned = true end
			pts[j][i] = p3(o.x + (i - 1) * sp, o.y - (j - 1) * sp * 0.02, o.z + (j - 1) * sp, pinned)
		end
	end
	local c = { pts = pts, cols = cols, rows = rows, rest = sp, kind = "cloth", name = opts.name or ("RPX_Cloth_" .. (#RPX._cloths + 1)), damp = 0.99, windPhase = 0, model = nil }
	c.windPhase = (o.x * 5.3 + o.z * 11.1) % 6.28
	RPX._cloths[#RPX._cloths + 1] = c
	fire("cloth:" .. c.name)
	return c
end

-- ---------- colisores ----------
function RPX.addSphere(x, y, z, rr)
	RPX._spheres[#RPX._spheres + 1] = { x = x, y = y, z = z, r = rr or 2 }
	fire("sphere:add")
end
function RPX.clearColliders() RPX._spheres = {} end

-- ---------- relaxamento de dois pontos ----------
local function relax(a, b, restOn)
	local dx = b.x - a.x
	local dy = b.y - a.y
	local dz = b.z - a.z
	local d = sqrt(dx * dx + dy * dy + dz * dz)
	if d < 1e-6 then return end
	local diff = (d - restOn) / d
	local m = 0.5
	if a.pin and b.pin then return end
	if a.pin then m = 0 end
	if b.pin then m = 1 end
	local ax = dx * diff * 0.5
	local ay = dy * diff * 0.5
	local az = dz * diff * 0.5
	if not a.pin then
		a.x = a.x + ax * (b.pin and 2 or 1)
		a.y = a.y + ay * (b.pin and 2 or 1)
		a.z = a.z + az * (b.pin and 2 or 1)
	end
	if not b.pin then
		b.x = b.x - ax * (a.pin and 2 or 1)
		b.y = b.y - ay * (a.pin and 2 or 1)
		b.z = b.z - az * (a.pin and 2 or 1)
	end
end

-- ---------- solo (y = groundY) ----------
local ground = { y = -5, on = false }
function RPX.setGround(y, on) ground = { y = y or 0, on = on ~= false } end

local function collide(p)
	for _, s in ipairs(RPX._spheres) do
		local dx = p.x - s.x
		local dy = p.y - s.y
		local dz = p.z - s.z
		local d2 = dx * dx + dy * dy + dz * dz
		local rr = s.r * s.r
		if d2 < rr and d2 > 1e-9 then
			local d = sqrt(d2)
			local k = (s.r - d) / d
			p.x = p.x + dx * k
			p.y = p.y + dy * k
			p.z = p.z + dz * k
		end
	end
	if ground.on and p.y < ground.y then p.y = ground.y end
end

-- ---------- vento (link vivo ATMOS X) ----------
local function windVec(t, phase)
	local speed = 0
	local dirx, dirz = 1, 0.3
	if ArkherAtmosX then
		local _, w = ArkherAtmosX.skyDayNight()
		if ArkherAtmosX.weatherMix then
			local mix = ArkherAtmosX.weatherMix(nil)
			if mix and mix.wind then speed = mix.wind end
		end
	end
	if ArkherAUX_WIND_OVERRIDE then speed = ArkherAUX_WIND_OVERRIDE end
	local gust = 0.6 + 0.4 * sin(t * 2.1 + phase) * sin(t * 0.77 + phase * 2)
	local v = speed * gust * 12
	return dirx * v, sin(t * 1.3 + phase) * v * 0.35, dirz * v
end

local stepT = 0
function RPX.pump(dt)
	dt = min(dt or 1 / 60, 1 / 20)
	stepT = stepT + dt
	local t = stepT
	local g2 = RPX.G * dt * dt
	for _, r in ipairs(RPX._ropes) do
		for i = 1, #r.pts do
			local p = r.pts[i]
			if not p.pin then
				local wx, wy, wz = windVec(t, r.windPhase)
				local ax, ay, az = wx * 0.06, -RPX.G + wy * 0.02, wz * 0.06
				local nx = p.x + (p.x - p.px) * r.damp + ax * dt * dt
				local ny = p.y + (p.y - p.py) * r.damp + ay * dt * dt
				local nz = p.z + (p.z - p.pz) * r.damp + az * dt * dt
				p.px, p.py, p.pz = p.x, p.y, p.z
				p.x, p.y, p.z = nx, ny, nz
			end
		end
		for k = 1, RPX.ITERS do
			for i = 1, #r.pts - 1 do relax(r.pts[i], r.pts[i + 1], r.rest) end
			for i = 1, #r.pts do collide(r.pts[i]) end
		end
	end
	for _, c in ipairs(RPX._cloths) do
		for j = 1, c.rows do
			for i = 1, c.cols do
				local p = c.pts[j][i]
				if not p.pin then
					local fx = sin(t * 3.1 + p.x * 0.5 + c.windPhase) * 2.2
					local fy = sin(t * 2.7 + p.y * 0.8 + 1) * 1.2
					local wx, wy, wz = windVec(t, c.windPhase)
					local ax, ay, az = wx * 0.09 + fx * 0.03, -RPX.G + wy * 0.02, wz * 0.09 + fy * 0.02
					local nx = p.x + (p.x - p.px) * c.damp + ax * dt * dt
					local ny = p.y + (p.y - p.py) * c.damp + ay * dt * dt
					local nz = p.z + (p.z - p.pz) * c.damp + az * dt * dt
					p.px, p.py, p.pz = p.x, p.y, p.z
					p.x, p.y, p.z = nx, ny, nz
				end
			end
		end
		for k = 1, 3 do
			for j = 1, c.rows do
				for i = 1, c.cols do
					if i < c.cols then relax(c.pts[j][i], c.pts[j][i + 1], c.rest) end
					if j < c.rows then relax(c.pts[j][i], c.pts[j + 1][i], c.rest) end
				end
			end
			for j = 1, c.rows do for i = 1, c.cols do collide(c.pts[j][i]) end end
		end
	end
	-- atualiza a geometria (materializacao continua)
	for _, r in ipairs(RPX._ropes) do RPX._geoRope(r) end
	for _, c in ipairs(RPX._cloths) do RPX._geoCloth(c) end
	return #RPX._ropes + #RPX._cloths
end

-- ---------- MATERIALIZACAO REAL (Parts finas por segmento) ----------
local function ensureModel(name)
	local m = workspace:FindFirstChild(name)
	if not m then
		m = Instance.new("Model")
		m.Name = name
		m.Parent = workspace
	end
	return m
end

local function segBetween(model, idx, a, b, w, colR, colG, colB)
	local pname = string.format("Seg_%04d", idx)
	local p = model:FindFirstChild(pname)
	if not p then
		p = Instance.new("Part")
		p.Name = pname
		p.Anchored = true
		p.CanCollide = false
		p.Material = "SmoothPlastic"
		p.Parent = model
	end
	local mx = (a.x + b.x) / 2
	local my = (a.y + b.y) / 2
	local mz = (a.z + b.z) / 2
	local len = max(sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + (b.z - a.z) ^ 2), 0.05)
	p.Size = Vector3.new(w, w, len)
	p.CFrame = CFrame.lookAt(Vector3.new(mx, my, mz), Vector3.new(b.x, b.y, b.z))
	p.Color = Color3.fromRGB(colR, colG, colB)
	return p
end

function RPX.materializeRope(r, opts)
	local m = ensureModel(r.name)
	r.model = r
	r._parts = opts or { w = 0.22, color = { 180, 120, 60 } }
	RPX._geoRope(r)
	return m
end
function RPX._geoRope(r)
	if not r.model then return end
	local m = ensureModel(r.name)
	for i = 1, #r.pts - 1 do
		segBetween(m, i, r.pts[i], r.pts[i + 1], (r._parts and r._parts.w) or 0.22, ((r._parts and r._parts.color) or { 180, 120, 60 })[1], ((r._parts and r._parts.color) or { 180, 120, 60 })[2], ((r._parts and r._parts.color) or { 180, 120, 60 })[3])
	end
end

function RPX.materializeCloth(c, opts)
	local m = ensureModel(c.name)
	c.model = c
	c._parts = opts or { w = 0.16, color = { 220, 240, 250 }, color2 = { 240, 230, 120 } }
	RPX._geoCloth(c)
	return m
end
function RPX._geoCloth(c)
	if not c.model then return end
	local m = ensureModel(c.name)
	local idx = 0
	local col1 = (c._parts and c._parts.color) or { 220, 240, 250 }
	-- tiras verticais (cada coluna = uma "corda" visual)
	for i = 1, c.cols, 2 do
		for j = 1, c.rows - 1 do
			idx = idx + 1
			local shade = ((i + j) % 2 == 0) and 1 or 0.85
			local pname = string.format("Seg_%04d", idx)
			local p = m:FindFirstChild(pname)
			if not p then
				p = Instance.new("Part")
				p.Name = pname
				p.Anchored = true
				p.CanCollide = false
				p.Material = "SmoothPlastic"
				p.Parent = m
			end
			local a, b = c.pts[j][i], c.pts[j + 1][i]
			local mx = (a.x + b.x) / 2
			local my = (a.y + b.y) / 2
			local mz = (a.z + b.z) / 2
			local len = max(sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + (b.z - a.z) ^ 2), 0.05)
			p.Size = Vector3.new(c.rest * 1.9, len, (c._parts and c._parts.w) or 0.16)
			p.CFrame = CFrame.lookAt(Vector3.new(mx, my, mz), Vector3.new(a.x, a.y, a.z + 1))
			p.Color = Color3.fromRGB(floor(col1[1] * shade), floor(col1[2] * shade), floor(col1[3] * shade))
		end
	end
end

function RPX.remove(name)
	for i, r in ipairs(RPX._ropes) do if r.name == name then table.remove(RPX._ropes, i) end end
	for i, c in ipairs(RPX._cloths) do if c.name == name then table.remove(RPX._cloths, i) end end
	local m = workspace:FindFirstChild(name)
	if m then m:Destroy() end
	fire("remove:" .. name)
end

-- flags / cabelo / bandame
function RPX.flagAt(x, y, z)
	local c = RPX.cloth({ origin = { x = x, y = y, z = z }, cols = 10, rows = 14, spacing = 1.0, pinned = "topcorners" })
	c.kind = "flag"
	RPX.materializeCloth(c, { w = 0.14, color = { 235, 40, 40 } })
	fire("flag")
	return c
end

_G.ArkherRopeX = RPX
return RPX
