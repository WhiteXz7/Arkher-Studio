--[[ ARKHER ANIMATOR X (AAX) — motor de animacao CUSTOM (nao usa Animation/KeyFrame do Roblox) ]]
-- Timelines multi-track com easing REAL (35 funcoes fisicas), splines de
-- Catmull-Rom, integrador de mola amortecida REAL (oscilador harmonico
-- amortecido — mesma fisica do D-O15), loop/ping-pong, markers, time-warp,
-- blend de clips, deformers procedurais (bend/twist/wave/taper) para
-- assemblies de parts (rig sem keyframe manual), serialize/export JSON.
-- RRW: REALIDADE (leis de movimento) -> REPRESENTACAO (curvas+springs) ->
-- MATERIALIZACAO (CFrame/Size/Color/atributos reais escritos a cada passo).
_G.ArkherAnimX = _G.ArkherAnimX or {}
local AAX = _G.ArkherAnimX
local DM = rawget(_G, "ArkherDM")
local abs, floor, sin, cos, pi, sqrt, exp = math.abs, math.floor, math.sin, math.cos, math.pi, math.sqrt, math.exp
local clamp, lerp = DM.clamp, DM.lerp
local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end

-- ================= EASINGS (37 reais) =================
local function bounceOut(t)
	if t < 1 / 2.75 then return 7.5625 * t * t
	elseif t < 2 / 2.75 then t = t - 1.5 / 2.75 return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then t = t - 2.25 / 2.75 return 7.5625 * t * t + 0.9375
	else t = t - 2.625 / 2.75 return 7.5625 * t * t + 0.984375 end
end
local function elasticIn(t)
	if t == 0 or t == 1 then return t end
	return -(2 ^ (10 * (t - 1))) * sin((t - 1.075) * (2 * pi) / 0.3)
end
local function elasticOut(t)
	if t == 0 or t == 1 then return t end
	return 2 ^ (-10 * t) * sin((t - 0.075) * (2 * pi) / 0.3) + 1
end
local S = 1.70158
AAX.EASE = {
	linear = function(t) return t end,
	smoothstep = function(t) return t * t * (3 - 2 * t) end,
	smootherstep = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end,
	easeIn_quad = function(t) return t * t end,
	easeOut_quad = function(t) return 1 - (1 - t) * (1 - t) end,
	easeInOut_quad = function(t) return t < 0.5 and 2 * t * t or 1 - 2 * (1 - t) ^ 2 end,
	easeIn_cubic = function(t) return t ^ 3 end,
	easeOut_cubic = function(t) return 1 - (1 - t) ^ 3 end,
	easeInOut_cubic = function(t) return t < 0.5 and 4 * t ^ 3 or 1 - 4 * (1 - t) ^ 3 end,
	easeIn_quart = function(t) return t ^ 4 end,
	easeOut_quart = function(t) return 1 - (1 - t) ^ 4 end,
	easeInOut_quart = function(t) return t < 0.5 and 8 * t ^ 4 or 1 - 8 * (1 - t) ^ 4 end,
	easeIn_quint = function(t) return t ^ 5 end,
	easeOut_quint = function(t) return 1 - (1 - t) ^ 5 end,
	easeInOut_quint = function(t) return t < 0.5 and 16 * t ^ 5 or 1 - 16 * (1 - t) ^ 5 end,
	easeIn_sine = function(t) return 1 - cos(t * pi / 2) end,
	easeOut_sine = function(t) return sin(t * pi / 2) end,
	easeInOut_sine = function(t) return (1 - cos(pi * t)) / 2 end,
	easeIn_expo = function(t) return t == 0 and 0 or 2 ^ (10 * (t - 1)) end,
	easeOut_expo = function(t) return t == 1 and 1 or 1 - 2 ^ (-10 * t) end,
	easeInOut_expo = function(t)
		if t == 0 or t == 1 then return t end
		return t < 0.5 and 2 ^ (20 * t - 11) or 1 - 2 ^ (-20 * t + 11) / 1 * 1
	end,
	easeIn_circ = function(t) return 1 - sqrt(1 - t * t) end,
	easeOut_circ = function(t) return sqrt(1 - (t - 1) ^ 2) end,
	easeInOut_circ = function(t)
		return t < 0.5 and (1 - sqrt(1 - 4 * t * t)) / 2 or (sqrt(1 - (2 * t - 2) ^ 2) + 1) / 2
	end,
	easeIn_back = function(t) return (S + 1) * t ^ 3 - S * t * t end,
	easeOut_back = function(t) local u = t - 1 return 1 + (S + 1) * u ^ 3 + S * u * u end,
	easeInOut_back = function(t)
		local s2 = S * 1.525
		return t < 0.5 and (t * t * ((s2 + 1) * 2 * t - s2)) / 2
			or ((2 * t - 2) ^ 2 * ((s2 + 1) * (2 * t - 2) + s2) + 2) / 2
	end,
	easeIn_elastic = elasticIn,
	easeOut_elastic = elasticOut,
	easeInOut_elastic = function(t)
		if t == 0 or t == 1 then return t end
		if t < 0.5 then return -(2 ^ (20 * t - 11) * sin((20 * t - 11.125) * (2 * pi) / 4.5)) / 2 end
		return 2 ^ (-20 * t + 11) * sin((20 * t - 11.125) * (2 * pi) / 4.5) / 2 + 1
	end,
	easeIn_bounce = function(t) return 1 - bounceOut(1 - t) end,
	easeOut_bounce = bounceOut,
	easeInOut_bounce = function(t)
		return t < 0.5 and (1 - bounceOut(1 - 2 * t)) / 2 or (1 + bounceOut(2 * t - 1)) / 2
	end,
	easeOut_spring = function(t) return 1 - exp(-6.5 * t) * cos(12 * t) end, -- mola real aprox (overshoot)
	easeOut_pop = function(t) -- overshoot curto usado em UI
		local c1 = 3.2
		return 1 + (c1 + 1) * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end,
}
AAX.EASE_NAMES = (function()
	local t = {}
	for k in pairs(AAX.EASE) do t[#t + 1] = k end
	table.sort(t)
	return t
end)()

-- ================= INTERPOLADORES =================
function AAX.mix(a, b, al) return a + (b - a) * al end
function AAX.mixVec(a, b, al) -- {x,y,z}
	return { x = a.x + (b.x - a.x) * al, y = a.y + (b.y - a.y) * al, z = a.z + (b.z - a.z) * al }
end
function AAX.mixColor(a, b, al) -- {r,g,b}
	return { r = floor(a.r + (b.r - a.r) * al), g = floor(a.g + (b.g - a.g) * al), b = floor(a.b + (b.b - a.b) * al) }
end
function AAX.kindOf(v)
	if type(v) == "number" then return "num" end
	if type(v) == "table" then
		if v.r ~= nil then return "color" end
		if v.x ~= nil then
			if v.rx ~= nil or v.rr ~= nil then return "cframe" end
			return "vec"
		end
	end
	return "num"
end
function AAX.mixAny(a, b, al)
	local k = AAX.kindOf(a)
	if k == "color" then return AAX.mixColor(a, b, al) end
	if k == "vec" then return AAX.mixVec(a, b, al) end
	if k == "cframe" then
		local p = AAX.mixVec(a, b, al)
		return { x = p.x, y = p.y, z = p.z,
			rx = (a.rx or 0) + ((b.rx or 0) - (a.rx or 0)) * al,
			ry = (a.ry or 0) + ((b.ry or 0) - (a.ry or 0)) * al,
			rz = (a.rz or 0) + ((b.rz or 0) - (a.rz or 0)) * al }
	end
	return a + (b - a) * al
end

-- ================= CATMULL-ROM (curva suave universal) =================
function AAX.catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end
-- AAX.curve(points, closed?) -> fn(t in [0,1]) : interpolador suave de pontos 1D
function AAX.curve(points, closed)
	local n = #points
	if n < 2 then return function() return points[1] or 0 end end
	return function(t)
		t = clamp(t, 0, 1)
		local seg = clamp(floor(t * (n - 1)), 0, n - 2)
		local lt = t * (n - 1) - seg
		local i = seg + 1 -- 1-based center
		local p0 = points[clamp(i - 1, 1, n)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[clamp(i + 2, 1, n)]
		return AAX.catmull(p0, p1, p2, p3, lt)
	end
end

-- ================= SPRING (oscilador harmonico amortecido REAL) =================
-- m*x'' = -k*(x - target) - c*x'  → semi-implicit Euler (estavel p/ dt variavel)
function AAX.spring(opts)
	opts = opts or {}
	local s = {
		k = opts.stiffness or 120, c = opts.damping or 14, m = opts.mass or 1,
		target = opts.target or 0, pos = opts.pos or 0, vel = opts.vel or 0,
	}
	function s:set(v) self.target = v return self end
	function s:snap(v) self.pos = v self.vel = 0 self.target = v return self end
	function s:update(dt)
		dt = clamp(dt or 0.016, 0.0001, 0.1)
		local acc = (-self.k * (self.pos - self.target) - self.c * self.vel) / self.m
		self.vel = self.vel + acc * dt
		self.pos = self.pos + self.vel * dt
		return self.pos, self.vel
	end
	function s:settled() return abs(self.vel) < 0.01 and abs(self.pos - self.target) < 0.01 end
	return s
end

-- ================= KEYFRAMES / TRACKS =================
local function sortKeys(keys) table.sort(keys, function(a, b) return a.t < b.t end) return keys end
function AAX.key(t, v, ease, params) return { t = t, v = v, ease = ease or "easeInOut_sine", params = params } end

local Track = {}
Track.__index = Track
function Track.new(prop, keys)
	local tr = setmetatable({ prop = prop, keys = sortKeys(keys or {}), mode = "key" }, Track)
	return tr
end
function Track:addKey(k) self.keys[#self.keys + 1] = AAX.key(k.t, k.v, k.ease, k.params) sortKeys(self.keys) return self end
function Track:removeAt(idx) table.remove(self.keys, idx) return self end
function Track:duration() return self.keys[#self.keys] and self.keys[#self.keys].t or 0 end
function Track:sample(t)
	local ks = self.keys
	if #ks == 0 then return nil end
	if t <= ks[1].t then return ks[1].v end
	if t >= ks[#ks].t then return ks[#ks].v end
	-- binaria simples
	local i = 1
	while i < #ks and ks[i + 1].t < t do i = i + 1 end
	local k1, k2 = ks[i], ks[i + 1]
	local span = k2.t - k1.t
	if span <= 0 then return k2.v end
	local al = (t - k1.t) / span
	if k1.ease and k1.ease ~= "linear" then
		local ez = AAX.EASE[k1.ease]
		if ez then al = ez(al) end
	end
	-- waypoint extra (curvatura): k1.params.ctrl = deslocamento no eixo do valor
	if k1.params and k1.params.ctrl then
		local cp = k1.params.ctrl
		local om = 1 - al
		local a1 = AAX.mixAny(k1.v, cp, al * al / (al * al + om * om + 1e-9))
		return AAX.mixAny(a1, k2.v, al)
	end
	return AAX.mixAny(k1.v, k2.v, al)
end

-- ================= CLIP =================
local Clip = {}
Clip.__index = Clip
function AAX.clip(name, opts)
	opts = opts or {}
	local c = setmetatable({
		name = name or "clip", tracks = {}, loop = opts.loop or "loop",
		speed = opts.speed or 1, markers = opts.markers or {}, binds = {},
		timeWarp = opts.timeWarp, playing = false, time = 0, dir = 1,
		onMarker = opts.onMarker, onEnd = opts.onEnd,
	}, Clip)
	return c
end
function Clip:addTrack(prop, keys)
	local tr = Track.new(prop, keys)
	self.tracks[#self.tracks + 1] = tr
	return tr
end
function Clip:track(prop)
	for _, tr in ipairs(self.tracks) do if tr.prop == prop then return tr end end
	return self:addTrack(prop, {})
end
function Clip:duration()
	local d = 0
	for _, tr in ipairs(self.tracks) do d = math.max(d, tr:duration()) end
	return d
end
function Clip:marker(t, id) self.markers[#self.markers + 1] = { t = t, id = id } table.sort(self.markers, function(a, b) return a.t < b.t end) return self end
-- warp: fn(tRaw)->tCurva (aceita AAX.curve)
function Clip:warpT(t) return self.timeWarp and self.timeWarp(t) or t end
function Clip:sample(t)
	t = self:warpT(t)
	local out = {}
	for _, tr in ipairs(self.tracks) do
		local v = tr:sample(t)
		if v ~= nil then out[tr.prop] = v end
	end
	return out
end
-- bindings reais: escreve em instancias (parts, gui, etc; pcall por seguranca)
function Clip:bind(inst, propMap)
	propMap = propMap or {}
	self.binds[#self.binds + 1] = { inst = inst, map = propMap }
	return self
end
function Clip:apply(t, sample)
	sample = sample or self:sample(t)
	for _, b in ipairs(self.binds) do
		local inst = b.inst
		local map = b.map
		if inst then
			for prop, v in pairs(sample) do
				local target = map[prop] or prop
				pcall(function()
					if target == "Position" and type(v) == "table" then
						inst.CFrame = CFrame.new(v.x, v.y, v.z)
					elseif target == "CFrame" and type(v) == "table" then
						inst.CFrame = CFrame.new(v.x, v.y, v.z) * CFrame.Angles(v.rx or 0, v.ry or 0, v.rz or 0)
					elseif target == "Size" and type(v) == "table" then
						inst.Size = Vector3.new(v.x, v.y, v.z)
					elseif target == "Color" and type(v) == "table" then
						inst.Color = Color3.fromRGB(clamp(v.r, 0, 255), clamp(v.g, 0, 255), clamp(v.b, 0, 255))
					elseif target == "Transparency" then
						inst.Transparency = clamp(v, 0, 1)
					elseif target:sub(1, 5) == "attr:" then
						inst:SetAttribute(target:sub(6), v)
					else
						pcall(function() inst[target] = v end)
					end
				end)
			end
		end
	end
end
function Clip:play(opts)
	opts = opts or {}
	self.time = opts.from or 0
	self.dir = 1
	self.playing = true
	AAX._register(self)
	-- aplica frame inicial
	self:apply(self.time)
	return self
end
function Clip:stop()
	self.playing = false
	return self
end
function Clip:pump(dt)
	if not self.playing then return false end
	local d = self:duration()
	if d <= 0 then self.playing = false return false end
	local prev = self.time
	self.time = self.time + dt * (self.speed or 1) * self.dir
	-- markers
	for _, mk in ipairs(self.markers) do
		local hit = (self.dir > 0 and prev < mk.t and self.time >= mk.t)
			or (self.dir < 0 and prev > mk.t and self.time <= mk.t)
		if hit and self.onMarker then self.onMarker(mk.id, mk.t) end
	end
	-- loops
	if self.time >= d then
		if self.loop == "pingpong" then
			self.dir = -self.dir self.time = d
		elseif self.loop == "loop" then
			self.time = self.time % d
		else
			self.time = d self.playing = false
			if self.onEnd then self.onEnd(self) end
		end
	elseif self.time <= 0 and self.dir < 0 then
		if self.loop == "pingpong" then
			self.dir = -self.dir self.time = 0
		elseif self.loop == "loop" then
			self.time = d
		else
			self.time = 0 self.playing = false
			if self.onEnd then self.onEnd(self) end
		end
	end
	local sm = self:sample(self.time)
	self:apply(self.time, sm)
	return true, sm
end
-- blend REAL de dois clips (pose a pose)
function AAX.blend(clipA, clipB, w, tA, tB)
	local aS = clipA:sample(tA or 0)
	local bS = clipB:sample(tB or 0)
	local out = {}
	local seen = {}
	for prop in pairs(aS) do
		if bS[prop] ~= nil and AAX.kindOf(aS[prop]) == AAX.kindOf(bS[prop]) then
			out[prop] = AAX.mixAny(aS[prop], bS[prop], clamp(w, 0, 1))
		else
			out[prop] = aS[prop]
		end
		seen[prop] = true
	end
	for prop in pairs(bS) do if not seen[prop] then out[prop] = bS[prop] end end
	return out
end
function Clip:serialize()
	local data = { engine = "AAX", name = self.name, loop = self.loop, speed = self.speed, markers = self.markers, tracks = {} }
	for _, tr in ipairs(self.tracks) do
		local ks = {}
		for _, k in ipairs(tr.keys) do ks[#ks + 1] = { t = k.t, v = k.v, ease = k.ease } end
		data.tracks[#data.tracks + 1] = { prop = tr.prop, keys = ks }
	end
	if HttpService then return HttpService:JSONEncode(data) end
	return "AAX:" .. self.name
end
function AAX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "AAX" then return nil, "clip invalido" end
	local c = AAX.clip(data.name, { loop = data.loop, speed = data.speed })
	for _, mk in ipairs(data.markers or {}) do c:marker(mk.t, mk.id) end
	for _, td in ipairs(data.tracks or {}) do
		c:addTrack(td.prop, {} )
		local tr = c:track(td.prop)
		for _, k in ipairs(td.keys or {}) do tr:addKey({ t = k.t, v = k.v, ease = k.ease }) end
	end
	return c
end

-- ================= DRIVER GLOBAL (1 pump p/ todos os clips vivos) =================
AAX._clips = {}
function AAX._register(c)
	for _, x in ipairs(AAX._clips) do if x == c then return end end
	AAX._clips[#AAX._clips + 1] = c
end
function AAX.pump(dt)
	local live = 0
	for i = #AAX._clips, 1, -1 do
		local c = AAX._clips[i]
		if c.playing then
			c:pump(dt)
			if c.playing then live = live + 1 else table.remove(AAX._clips, i) end
		else
			table.remove(AAX._clips, i)
		end
	end
	-- Rope X (se carregado): fisica de corda/tecido bombeada no mesmo pulso
	if rawget(_G, "ArkherRopeX") then pcall(function() rawget(_G, "ArkherRopeX").pump(dt) end) end
	return live
end
function AAX.stopAll()
	for _, c in ipairs(AAX._clips) do c:stop() end
	AAX._clips = {}
end

-- ================= ASSEMBLIES + DEFORMERS (rig sem rig) =================
-- "rig procedura": conjunto de parts com base CFrame; deformer desloca cada
-- part pelo seu offset usando f(x,y,z,t) — e assim damos vizinho vida real
-- sem keyframe manual (ondulacao de bandeira, verga de arco, vento em grama).
function AAX.assemble(parts)
	local asm = { parts = {}, bounds = { min = { x = 1e9, y = 1e9, z = 1e9 }, max = { x = -1e9, y = -1e9, z = -1e9 } } }
	for i, p in ipairs(parts) do
		local cf
		local ok, v = pcall(function() return p.CFrame end)
		cf = ok and v or nil
		local pos = cf and { x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z } or { x = 0, y = 0, z = 0 }
		asm.parts[i] = { inst = p, base = pos }
		for _, k in pairs({ "x", "y", "z" }) do
			if pos[k] < asm.bounds.min[k] then asm.bounds.min[k] = pos[k] end
			if pos[k] > asm.bounds.max[k] then asm.bounds.max[k] = pos[k] end
		end
	end
	return asm
end
AAX.DEFORMERS = {
	bend = function(angle, axis)
		axis = axis or "x"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local a = angle * norm * norm
			local ca, sa = cos(a), sin(a)
			local u = base[axis] - asm.bounds.min[axis]
			local v = base.y - asm.bounds.min.y
			local ny = v * ca - u * sa
			local nu = v * sa + u * ca
			local dx, dy = 0, ny - v
			if axis == "x" then dx = nu - u else _ = 0 end
			local out = { x = base.x + (axis == "x" and dx or 0), y = base.y + dy, z = base.z + (axis == "z" and dx or 0) }
			return out, { rx = 0, ry = axis == "z" and -a or 0, rz = axis == "x" and a or 0 }
		end
	end,
	twist = function(turns, axis)
		axis = axis or "y"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local a = turns * 2 * pi * norm
			local ca, sa = cos(a), sin(a)
			local dx, dz = base.x, base.z
			if axis == "y" then
				dx, dz = base.x * ca - base.z * sa, base.x * sa + base.z * ca
			end
			return { x = dx, y = base.y, z = dz }, { rx = 0, ry = axis == "y" and a or 0, rz = 0 }
		end
	end,
	wave = function(amp, len, speed)
		return function(asm, i, base, t)
			local ph = (base.x / math.max(len, 0.1)) * 2 * pi - t * (speed or 2)
			local elev = sin(ph) * amp
			return { x = base.x, y = base.y + elev, z = base.z }, { rx = 0, ry = 0, rz = cos(ph) * amp * 0.35 }
		end
	end,
	taper = function(amount, axis)
		axis = axis or "y"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local s = 1 - amount * norm
			local cx = (asm.bounds.min.x + asm.bounds.max.x) / 2
			local cz = (asm.bounds.min.z + asm.bounds.max.z) / 2
			return { x = cx + (base.x - cx) * s, y = base.y, z = cz + (base.z - cz) * s }, { rx = 0, ry = 0, rz = 0 }
		end
	end,
	breathe = function(amount, speed)
		return function(asm, i, base, t)
			local s = 1 + sin(t * (speed or 2)) * (amount or 0.06)
			local cx = (asm.bounds.min.x + asm.bounds.max.x) / 2
			local cz = (asm.bounds.min.z + asm.bounds.max.z) / 2
			return { x = cx + (base.x - cx) * s, y = base.y + (base.y - asm.bounds.min.y) * (s - 1), z = cz + (base.z - cz) * s }, { rx = 0, ry = 0, rz = 0 }
		end
	end,
}
-- deformer vivo: aplica fn cada pump
function AAX.deform(asm, deformFn, opts)
	opts = opts or {}
	local d = { asm = asm, fn = deformFn, time = opts.time or 0, playing = true }
	function d:pump(dt)
		if not self.playing then return 0 end
		self.time = self.time + dt
		local n = 0
		for i, slot in ipairs(self.asm.parts) do
			local pos, rot = self.fn(self.asm, i, slot.base, self.time)
			pcall(function()
				slot.inst.CFrame = CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(rot.rx or 0, rot.ry or 0, rot.rz or 0)
			end)
			n = n + 1
		end
		return n
	end
	AAX._deformers = AAX._deformers or {}
	AAX._deformers[#AAX._deformers + 1] = d
	return d
end
function AAX.pumpDeformers(dt)
	local n = 0
	for _, d in ipairs(AAX._deformers or {}) do n = n + d:pump(dt) end
	return n
end

AAX._version = "1.0.0"
return AAX
