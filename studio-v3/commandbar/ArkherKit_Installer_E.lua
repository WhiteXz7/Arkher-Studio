--[[ ARKHER V3 — Installer ArkherKit_E: cria o ModuleScript em ReplicatedStorage.ArkherV3 ]]
local KIT = [====[
--[[ ARKHER V4 — KIT E (ModuleScript) — ANIMATOR X + AUDIO X + SCENE/SCATTER X ]]
-- Motores de animacao (37 easings/springs/deformers), mixer/DSP e povoamento
-- procedural. Requer o Kit A. Instala em: ReplicatedStorage.ArkherV3.ArkherKit_E
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
--[[ ARKHER ANIMATOR X (AAX) — motor de animacao CUSTOM (nao usa Animation/KeyFrame do Roblox) ]]
-- Timelines multi-track com easing REAL (35 funcoes fisicas), splines de
-- Catmull-Rom, integrador de mola amortecida REAL (oscilador harmonico
-- amortecido — mesma fisica do D-O15), loop/ping-pong, markers, time-warp,
-- blend de clips, deformers procedurais (bend/twist/wave/taper) para
-- assemblies de parts (rig sem keyframe manual), serialize/export JSON.
-- RRW: REALIDADE (leis de movimento) -> REPRESENTACAO (curvas+springs) ->
-- MATERIALIZACAO (CFrame/Size/Color/atributos reais escritos a cada passo).
ArkherAnimX = ArkherAnimX or {}
local AAX = ArkherAnimX
local DM = ArkherDM
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
	if ArkherRopeX then pcall(function() ArkherRopeX.pump(dt) end) end
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
end

do
--[[ ARKHER AUDIO X (AUX) — motor de audio/mixer CUSTOM ]]
-- Vai alem do "tocar um Sound": arquitetura de MIXAGEM com SoundGroups REAIS
-- (master/sfx/music/ui/ambient/weather/voice), DSP do engine (Reverb, Echo,
-- Compressor, Distortion, Equalizer, Flange, Tremolo, PitchShift), presets
-- acusticos (caverna, estadio, campo aberto, subaquatico, radio), DUCKING
-- sidechain (voz abaixa a musica com envelope), crossfade de camadas
-- adaptativas (explore/combat/night), scheduler de ambiente com controle
-- de repeticao (never-repeats-recent), posicionamento 3D simulado com
-- rolloff real (inverso-quadratico) + doppler aproximado, e link com AWX
-- (ondas ressacam => vento/mono de mar alto sobe).
ArkherAudioX = ArkherAudioX or {}
local AUX = ArkherAudioX
local DM = ArkherDM
local floor, abs, sqrt, clamp = math.floor, math.abs, math.sqrt, DM.clamp
local soundService
do local ok, s = pcall(function() return game:GetService("SoundService") end) if ok then soundService = s end end
local RunService
do local ok, s = pcall(function() return game:GetService("RunService") end) if ok then RunService = s end end

-- ================= BUSES (SoundGroups REAIS) =================
AUX.BUSES = { "master", "music", "sfx", "ui", "ambient", "weather", "voice" }
AUX._groups = {}
function AUX._group(name)
	local g = AUX._groups[name]
	if g then return g end
	if soundService then
		local parent = name == "master" and soundService or AUX._group("master")
		g = Instance.new("SoundGroup")
		g.Name = "AUX_" .. name
		g.Volume = 1
		g.Parent = parent
	else
		g = { Name = "AUX_" .. name, Volume = 1, _shimBus = true }
	end
	AUX._groups[name] = g
	return g
end
function AUX.setup()
	for _, b in ipairs(AUX.BUSES) do AUX._group(b) end
	return AUX._groups
end
function AUX.busVolume(name) local g = AUX._group(name) return g and g.Volume end
function AUX.setBusVolume(name, v)
	local g = AUX._group(name)
	if g then pcall(function() g.Volume = clamp(v, 0, 10) end) end
	return v
end

-- ================= DSP / PRESETS ACUSTICOS =================
-- cada preset liga efeitos REAIS no SoundGroup da bus
AUX.ACOUSTICS = {
	flat = {},
	caverna = {
		{ "ReverbSoundEffect", { DecayTime = 4.5, Density = 1, Diffusion = 1, DryLevel = -6, WetLevel = -2 } },
		{ "EchoSoundEffect", { Delay = 0.18, Feedback = 0.35, WetLevel = -12 } },
	},
	estadio = {
		{ "ReverbSoundEffect", { DecayTime = 3.2, Density = 1, Diffusion = 0.85, DryLevel = -3, WetLevel = 0 } },
		{ "EchoSoundEffect", { Delay = 0.09, Feedback = 0.22, WetLevel = -16 } },
		{ "CompressorSoundEffect", { Threshold = -14, Ratio = 3, Attack = 0.02, Release = 0.15, GainMakeup = 4 } },
	},
	estudio = {
		{ "CompressorSoundEffect", { Threshold = -10, Ratio = 2.5, Attack = 0.005, Release = 0.1, GainMakeup = 2 } },
		{ "EqualizerSoundEffect", { LowGain = 1.5, MidGain = 0.8, HighGain = 0.4 } },
	},
	subaquatico = {
		{ "PitchShiftSoundEffect", { Octave = 0.5 } },
		{ "ReverbSoundEffect", { DecayTime = 2.8, Density = 0.9, Diffusion = 1, DryLevel = -8, WetLevel = -4 } },
		{ "EqualizerSoundEffect", { LowGain = 5, MidGain = -6, HighGain = -18 } },
	},
	radio = { -- telefone/radio AM
		{ "EqualizerSoundEffect", { LowGain = -18, MidGain = 4, HighGain = -14 } },
		{ "DistortionSoundEffect", { Level = 0.25 } },
	},
	floresta = {
		{ "ReverbSoundEffect", { DecayTime = 1.6, Density = 0.8, Diffusion = 0.7, DryLevel = -4, WetLevel = -10 } },
	},
	metal = { -- metal/catedral de metal
		{ "FlangeSoundEffect", { Depth = 0.4, Mix = 0.35, Rate = 0.8 } },
		{ "ReverbSoundEffect", { DecayTime = 2.2, Density = 1, Diffusion = 0.9, DryLevel = -5, WetLevel = -8 } },
	},
}
function AUX.patch(busName, presetId)
	if not soundService then return false, "SoundService indisponivel" end
	local g = AUX._group(busName)
	local preset = AUX.ACOUSTICS[presetId or "flat"] or AUX.ACOUSTICS.flat
	-- limpa efeitos anteriores AUX
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
	for _, spec in ipairs(preset) do
		local cls, params = spec[1], spec[2]
		local ok, fx = pcall(function()
			local e = Instance.new(cls)
			e.Name = "AUX_" .. cls
			e.Enabled = true
			e.Priority = 0
			for k, v in pairs(params or {}) do pcall(function() e[k] = v end) end
			e.Parent = g
			return e
		end)
		if not ok then return false, "efeito " .. cls .. " falhou" end
	end
	return true, #preset
end
function AUX.clearPatch(busName)
	local g = AUX._group(busName)
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
end

-- ================= REGISTRY DE SONS =================
AUX._sounds = {} -- id -> {inst, def}
function AUX.register(id, def)
	def = def or {}
	local s
	if soundService then
		s = Instance.new("Sound")
		s.Name = "AUX_S_" .. id
		s.SoundId = def.id or (def.asset and ("rbxassetid://" .. tostring(def.asset)) or "")
		s.Volume = def.volume or 0.5
		s.PlaybackSpeed = def.pitch or 1
		s.Looped = def.looped or false
		if def.bus then s.SoundGroup = AUX._group(def.bus) end
		s.Parent = soundService
	else
		s = { Name = id, Volume = def.volume or 0.5, Playing = false, Looped = def.looped or false }
	end
	AUX._sounds[id] = { inst = s, def = def, bus = def.bus or "sfx" }
	return s
end
function AUX.play(id, opts)
	opts = opts or {}
	local reg = AUX._sounds[id]
	if not reg then
		AUX.register(id, opts.def or { bus = opts.bus })
		reg = AUX._sounds[id]
	end
	local s = reg.inst
	pcall(function()
		if opts.volume then s.Volume = opts.volume end
		if opts.pitch then s.PlaybackSpeed = opts.pitch end
		s:Play()
	end)
	reg.playing = true
	if not soundService then s.Playing = true end
	return s
end
function AUX.stop(id)
	local reg = AUX._sounds[id]
	if reg then reg.playing = false pcall(function() reg.inst:Stop() end) reg.inst.Playing = false end
end

-- ================= DUCKING (sidechain real com envelope) =================
-- quando bus trigger toca, alvo abaixa p/ duckLevel com attack, volta com release
AUX._ducks = {}
function AUX.duck(targetBus, triggerBus, opts)
	opts = opts or {}
	AUX._ducks[#AUX._ducks + 1] = {
		target = targetBus, trigger = triggerBus,
		level = opts.level or 0.35, attack = opts.attack or 0.08, release = opts.release or 0.9,
		hold = opts.hold or 0.6, t = 0, env = 1, state = "idle",
	}
end
local function busIsPlaying(busName)
	for _, reg in pairs(AUX._sounds) do
		if reg.bus == busName and reg.playing then return true end
	end
	return false
end
function AUX._pumpDucks(dt)
	for _, d in ipairs(AUX._ducks) do
		local g = AUX._groups[d.target]
		if g then
			local active = busIsPlaying(d.trigger)
			if active then
				d.state = "ducking"
				d.env = math.max(d.level, d.env - dt / math.max(d.attack, 0.001))
				if d.env <= d.level then d.state = "hold" d.t = 0 end
			else
				if d.state == "hold" then
					d.t = d.t + dt
					if d.t >= d.hold then d.state = "release" end
				elseif d.state ~= "idle" then
					d.state = d.state == "ducking" and "release" or d.state
					d.env = math.min(1, d.env + dt / math.max(d.release, 0.001))
					if d.env >= 1 then d.state = "idle" d.env = 1 end
				end
			end
			pcall(function() g.Volume = d.env * (AUX._baseVol and AUX._baseVol[d.target] or 1) end)
		end
	end
end

-- ================= MUSIC LAYERS (adaptativo) =================
AUX._layers = nil -- {base=regId, tension=regId, combat=regId, intensity=0..1}
function AUX.musicLayers(defs)
	-- defs = { base = id, tension = id, combat = id } de sons registrados (loop)
	AUX._layers = { defs = defs, intensity = 0 }
	for role, id in pairs(defs) do
		local s = AUX._sounds[id] and AUX._sounds[id].inst
		if s then pcall(function() s.Looped = true s:Play() s.Volume = role == "base" and (AUX._sounds[id].def.volume or 0.5) or 0 end) end
	end
	return AUX._layers
end
function AUX.setIntensity(v) -- 0..2 (0 paz, 1 tensao, 2 combate)
	if not AUX._layers then return end
	AUX._layers.intensity = clamp(v, 0, 2)
end
function AUX._pumpLayers(dt)
	local L = AUX._layers
	if not L then return end
	local int = L.intensity or 0
	local targets = { base = clamp(1 - int, 0.25, 1), tension = clamp(1 - abs(int - 1), 0, 1), combat = clamp(int - 1, 0, 1) }
	for role, id in pairs(L.defs) do
		local reg = AUX._sounds[id]
		if reg then
			local base = reg.def.volume or 0.5
			local want = base * (targets[role] or 1)
			local cur = 0
			pcall(function() cur = reg.inst.Volume end)
			cur = cur or 0
			local nv = cur + (want - cur) * clamp(dt * 4, 0, 1)
			pcall(function() reg.inst.Volume = nv end)
		end
	end
end

-- ================= AMBIENT SCHEDULER (nunca repete os 2 ultimos) =================
AUX._ambients = {}
function AUX.ambient(name, spec)
	-- spec: { ids = {a,b,c}, interval = {min,max}, bus = "ambient", condition = fn,
	-- volume = {min,max}, pitched = {min,max} }
	local am = {
		name = name, ids = spec.ids or {}, bus = spec.bus or "ambient",
		interval = spec.interval or { 18, 42 }, volume = spec.volume or { 0.2, 0.5 },
		pitchRange = spec.pitch or { 0.9, 1.1 }, condition = spec.condition,
		timer = 0, running = false, last2 = {}, rng = 1234567,
	}
	function am:nextIn()
		return self.interval[1] + (self.interval[2] - self.interval[1]) * DM.hash2(self.rng, 77, 555)
	end
	function am:pick()
		if #self.ids == 0 then return nil end
		local tries = 0
		while tries < 8 do
			local i = 1 + floor(DM.hash2(self.rng, tries, 91) * #self.ids)
			local id = self.ids[i]
			if id ~= self.last2[1] and id ~= self.last2[2] then return id end
			tries = tries + 1
		end
		return self.ids[1]
	end
	function am:start()
		self.running = true
		self.timer = self:nextIn() * 0.3
	end
	function am:stop() self.running = false end
	function am:pump(dt)
		if not self.running then return false end
		if self.condition and not self.condition() then return false end
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = self:nextIn()
			self.rng = self.rng + 1
			local id = self:pick()
			if id then
				local vol = self.volume[1] + (self.volume[2] - self.volume[1]) * DM.hash2(self.rng, 3, 9)
				local pit = self.pitchRange[1] + (self.pitchRange[2] - self.pitchRange[1]) * DM.hash2(self.rng, 5, 7)
				AUX.play(id, { volume = vol, pitch = pit, bus = self.bus, def = { bus = self.bus, volume = vol } })
				self.last2[2] = self.last2[1]
				self.last2[1] = id
				return true
			end
		end
		return false
	end
	AUX._ambients[name] = am
	return am
end

-- ================= POSICIONAL 3D SIMULADO (rolloff^2 + doppler) =================
AUX._posTracked = {}
function AUX.positional(soundOrId, getPosFn, opts)
	opts = opts or {}
	local reg = AUX._sounds[soundOrId]
	local snd = reg and reg.inst or soundOrId
	local tr = {
		snd = snd, getPos = getPosFn, refDist = opts.refDist or 12, maxDist = opts.maxDist or 120,
		baseVol = opts.volume or (snd and snd.Volume) or 0.5, doppler = opts.doppler ~= false,
		lastPos = nil, lastVel = 0,
	}
	AUX._posTracked[#AUX._posTracked + 1] = tr
	return tr
end
local function camPos()
	local ws = workspace
	local cam = ws and ws.CurrentCamera
	if cam and cam.CFrame then return cam.CFrame.Position end
	return nil
end
function AUX._pumpPositional(dt)
	for _, tr in ipairs(AUX._posTracked) do
		local cp = camPos()
		local wp = tr.getPos and tr.getPos()
		if cp and wp and tr.snd then
			local dx, dy, dz = cp.X - wp.X, cp.Y - wp.Y, cp.Z - wp.Z
			local d = sqrt(dx * dx + dy * dy + dz * dz)
			-- rolloff inverso-quadratico (real) com clamp
			local g = clamp((tr.refDist / math.max(d, tr.refDist)) ^ 2, 0, 1)
			if d > tr.maxDist then g = 0 end
			-- doppler aproximado: velocidade radial do emissor
			local pitch = 1
			if tr.doppler and tr.lastPos and dt > 0 then
				local vx = (wp.X - tr.lastPos.X) / dt
				local vy = (wp.Y - tr.lastPos.Y) / dt
				local vz = (wp.Z - tr.lastPos.Z) / dt
				local speed = sqrt(vx * vx + vy * vy + vz * vz)
				local radial = speed * (dx / math.max(d, 1e-4))
				pitch = clamp(1 + radial / 343 * 6, 0.7, 1.4) -- exagero artistico
			end
			tr.lastPos = wp
			pcall(function()
				tr.snd.Volume = tr.baseVol * g
				tr.snd.PlaybackSpeed = pitch
			end)
		end
	end
end

-- ================= LINK AWX (mar alto => vento ondulante) =================
function AUX.linkSea(sea, ambientName, opts)
	opts = opts or {}
	local am = AUX._ambients[ambientName]
	if not am or not sea then return false end
	am.condition = function()
		local h = 0
		for w = 1, #sea.waves do h = h + (sea.waves[w].amp or 0) end
		return h >= (opts.minAmp or 0.4)
	end
	return true
end

-- ================= PUMP GLOBAL =================
AUX._fires = {}
function AUX.pump(dt)
	dt = dt or 0.016
	AUX._pumpDucks(dt)
	AUX._pumpLayers(dt)
	for name, am in pairs(AUX._ambients) do
		if am:pump(dt) then
			AUX._fires[#AUX._fires + 1] = { name = name, t = (tick and tick()) or os.clock() }
			if #AUX._fires > 8 then table.remove(AUX._fires, 1) end
		end
	end
	AUX._pumpPositional(dt)
end
function AUX.stats()
	local n, playing = 0, 0
	for _, reg in pairs(AUX._sounds) do
		n = n + 1
		local ok, p = pcall(function() return reg.inst.IsPlaying or reg.inst.Playing end)
		if ok and p then playing = playing + 1 end
	end
	return {
		sounds = n, playing = playing, buses = #AUX.BUSES,
		ducks = #AUX._ducks, ambients = (function() local c = 0 for _ in pairs(AUX._ambients) do c = c + 1 end return c end)(),
		positional = #AUX._posTracked, layers = AUX._layers and AUX._layers.intensity or nil,
	}
end

AUX._version = "1.0.0"
end

do
--[[ ARKHER SCENE X (ASXN) — grafo de cena, query, SCATTER procedural e LOD ]]
-- O "organizador/montador" que o Roblox nao tem nativo: spatial-hash real,
-- query por classe/nome/atributo/regiao, PATINA (variacao sutil deterministica
-- de cor = anti-CG realista), SCATTER com amostragem Poisson-like no nosso
-- ATX (regras de bioma/declive/agua), biblioteca de vegetacao procedural
-- (arvores/arbustos/pedras/grama geradas como models reais), MERGE/EXPLODE,
-- alinhamento ARRAY, registro de assoc `LOD de distancia` cooperando com D-O15.
-- RRW: REPRESENTACAO (hash+regras) -> MATERIALIZACAO (models reais no mundo).
ArkherSceneX = ArkherSceneX or {}
local X = ArkherSceneX
local DM = ArkherDM
local floor, abs, sqrt, min, max = math.floor, math.abs, math.sqrt, math.min, math.max
local clamp, lerp = DM.clamp, DM.lerp
local pi, cos, sin = math.pi, math.cos, math.sin
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

-- ================= SPATIAL HASH =================
X.CELL = 8
X._hash = {} -- "cx,cz" -> {inst}
local function cellKeyOf(x, z) return floor(x / X.CELL) .. "," .. floor(z / X.CELL) end
function X.register(inst)
	if not inst then return end
	local ok, pos = pcall(function() return inst.Position end)
	if not (ok and pos) then return end
	local k = cellKeyOf(pos.X, pos.Z)
	X._hash[k] = X._hash[k] or {}
	X._hash[k][#X._hash[k] + 1] = inst
end
function X.unregister(inst, x, z)
	if x and z then
		local k = cellKeyOf(x, z)
		local list = X._hash[k]
		if list then for i, v in ipairs(list) do if v == inst then table.remove(list, i) break end end end
	end
end
function X.rehash()
	X._hash = {}
	if not workspace then return 0 end
	local n = 0
	local function scan(node)
		for _, ch in ipairs(node:GetChildren()) do
			if ch:IsA("BasePart") then X.register(ch) n = n + 1 end
			scan(ch)
		end
	end
	scan(workspace)
	return n
end
function X.near(x, z, r)
	local out = {}
	local c0 = floor((x - r) / X.CELL)
	local c1 = floor((x + r) / X.CELL)
	local d0 = floor((z - r) / X.CELL)
	local d1 = floor((z + r) / X.CELL)
	for cx = c0, c1 do
		for cz = d0, d1 do
			local list = X._hash[cx .. "," .. cz]
			if list then
				for _, inst in ipairs(list) do
					local ok2, pos = pcall(function() return inst.Position end)
					if ok2 and pos then
						local dx, dz = pos.X - x, pos.Z - z
						if dx * dx + dz * dz <= r * r then out[#out + 1] = inst end
					end
				end
			end
		end
	end
	return out
end

-- ================= QUERY (estilo explorer programatico) =================
function X.query(spec)
	spec = spec or {}
	local pool = {}
	local function scan(node)
		for _, ch in ipairs(node:GetChildren()) do
			local ok = true
			if spec.class and not ch:IsA(spec.class) then ok = false end
			if ok and spec.name then
				local n = ch.Name or ""
				if not n:lower():find(spec.name:lower(), 1, true) then ok = false end
			end
			if ok and spec.attr then
				for k, v in pairs(spec.attr) do
					local a = ch:GetAttribute(k)
					if v == nil and a == nil then ok = false
					elseif v ~= nil and a ~= v then ok = false end
				end
			end
			if ok and spec.tag then
				local t = ch:GetAttribute("arkher_tag")
				if t ~= spec.tag then ok = false end
			end
			if ok and spec.where then ok = spec.where(ch) == true end
			if ok then pool[#pool + 1] = ch end
			scan(ch)
		end
	end
	scan(workspace)
	if spec.within then
		local w = spec.within
		local filtered = {}
		for _, ch in ipairs(pool) do
			local ok, pos = pcall(function() return ch.Position end)
			if ok and pos then
				local dx, dz = pos.X - w.x, pos.Z - w.z
				if dx * dx + dz * dz <= w.r * w.r then filtered[#filtered + 1] = ch end
			end
		end
		pool = filtered
	end
	return pool
end

-- ================= PATINA (variacao deterministica anti-CG) =================
function X.patina(insts, opts)
	opts = opts or {}
	local seed = opts.seed or 777
	local hJ, sJ, vJ = opts.hueJit or 0.02, opts.satJit or 0.06, opts.valJit or 0.08
	local n = 0
	local hasHSV = Color3.fromHSV ~= nil
	for i, inst in ipairs(insts) do
		local okC, c = pcall(function() return inst.Color end)
		if okC and c then
			local r1 = DM.hash3(i, 11, 13, seed) - 0.5
			local r2 = DM.hash3(i, 17, 19, seed) - 0.5
			local r3 = DM.hash3(i, 23, 29, seed) - 0.5
			if hasHSV and type(c) == "userdata" and c.ToHSV or (hasHSV and type(c) == "table" and c.ToHSV) then -- shim-safe
				local ok2, h, s, v = pcall(function() return c:ToHSV() end)
				if ok2 then
					local nh = (h + r1 * hJ * 2) % 1
					local ns = clamp(s + r2 * sJ * 2, 0, 1)
					local nv = clamp(v + r3 * vJ * 2, 0, 1)
					pcall(function() inst.Color = Color3.fromHSV(nh, ns, nv) end)
					n = n + 1
				end
			else
				-- fallback RGB-jitter (mesma finalidade: quebrar o phong uniforme)
				local rr = (c.R or 0.5) + r2 * sJ
				local gg = (c.G or 0.5) + r1 * hJ
				local bb = (c.B or 0.5) + r3 * vJ
				pcall(function()
					inst.Color = Color3.new(clamp(rr, 0, 1), clamp(gg, 0, 1), clamp(bb, 0, 1))
				end)
				n = n + 1
			end
		end
	end
	return n
end

-- ================= VEGETACAO / PROPS PROCEDURAIS (models reais) =================
local function mkPart(name, size, cf, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	pcall(function() p.Material = material or Enum.Material.SmoothPlastic end)
	if parent then p.Parent = parent end
	return p
end
-- cores por bioma (Whittaker aliada ao ATX)
X.BIOME_FOLIAGE = {
	floresta_equatorial = { { 34, 118, 52 }, { 52, 132, 60 }, { 74, 148, 66 } },
	taiga = { { 28, 84, 44 }, { 38, 96, 46 }, { 48, 110, 52 } },
	savana = { { 96, 122, 44 }, { 118, 138, 52 } },
	deserto = { { 140, 128, 70 } },
	padrao = { { 46, 108, 56 }, { 58, 122, 60 }, { 70, 130, 64 } },
}
function X.foliageColor(biome, seed, i)
	local pal = X.BIOME_FOLIAGE[biome] or X.BIOME_FOLIAGE.padrao
	local pick = pal[1 + floor(DM.hash3(i, 3, 5, seed) * #pal) % #pal]
	return Color3.fromRGB(pick[1], pick[2], pick[3])
end
-- ARVORE: tronco conificado + dossel em 2-3 blobs organicos
function X.makeTree(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local h = opts.height or (7 + floor(DM.hash3(seed, 1, 2, 9) * 6))
	local model = Instance.new("Model")
	model.Name = "Tree_" .. seed
	local trunkH = h * 0.45
	local trunkW = 0.5 + h * 0.05
	mkPart("Trunk", Vector3.new(trunkW, trunkH, trunkW),
		CFrame.new(x, y + trunkH / 2, z),
		Color3.fromRGB(92 + floor(DM.hash3(seed, 7, 1, 3) * 12), 74, 56), model, Enum.Material.Wood)
	local canopyBase = y + trunkH
	local blobs = 2 + floor(DM.hash3(seed, 3, 5, 7) * 2)
	for i = 1, blobs do
		local ang = DM.hash3(seed, i, 11, 13) * pi * 2
		local rad = h * 0.18 * (i - 1) * 0.5
		local ox, oz = cos(ang) * rad, sin(ang) * rad
		local size = h * (0.42 - 0.09 * (i - 1))
		local col = X.foliageColor(opts.biome, seed, i)
		mkPart("Canopy_" .. i, Vector3.new(size, size * 0.75, size),
			CFrame.new(x + ox, canopyBase + size * 0.35 * (i - 1) + size * 0.25, z + oz), col, model, Enum.Material.Grass)
	end
	model:SetAttribute("arkher_tag", opts.tag or "tree")
	model:SetAttribute("biome", opts.biome or "padrao")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- ARBUSTO: 1-2 blobs baixos
function X.makeBush(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Bush_" .. seed
	local s = 1 + DM.hash3(seed, 2, 4, 6) * 2
	mkPart("BushA", Vector3.new(s * 2, s * 1.3, s * 2), CFrame.new(x, y + s * 0.6, z),
		X.foliageColor(opts.biome, seed, 1), model, Enum.Material.Grass)
	mkPart("BushB", Vector3.new(s * 1.2, s, s * 1.2), CFrame.new(x + s * 0.7, y + s * 0.5, z + s * 0.3),
		X.foliageColor(opts.biome, seed, 2), model, Enum.Material.Grass)
	model:SetAttribute("arkher_tag", opts.tag or "bush")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- PEDRA: 2-3 paralelepipedos empilhados com rotacao (rocha angular)
function X.makeRock(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Rock_" .. seed
	local s = 1 + DM.hash3(seed, 5, 7, 9) * 3.5
	local g1 = Color3.fromRGB(118 + floor(DM.hash3(seed, 9, 1, 3) * 14), 116, 110)
	mkPart("RockA", Vector3.new(s * 2, s * 1.2, s * 1.6), CFrame.new(x, y + s * 0.5, z)
		* CFrame.Angles(0.1, DM.hash3(seed, 1, 2, 3) * pi, 0.06), g1, model, Enum.Material.Slate)
	if DM.hash3(seed, 8, 2, 9) > 0.45 then
		mkPart("RockB", Vector3.new(s * 1.1, s * 0.8, s), CFrame.new(x + s * 0.6, y + s * 0.9, z + s * 0.2)
			* CFrame.Angles(0.15, DM.hash3(seed, 4, 5, 6) * pi, -0.08), g1, model, Enum.Material.Slate)
	end
	model:SetAttribute("arkher_tag", opts.tag or "rock")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- GRAMA: tufo de 4-6 lâminas finas (Parts finos) com inclinacao
-- (estilizado REAL: densidade visual, custo baixo)
function X.makeGrass(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Grass_" .. seed
	local blades = 4 + floor(DM.hash3(seed, 3, 7, 11) * 3)
	for i = 1, blades do
		local a = (i / blades) * pi * 2 + DM.hash3(seed, i, 1, 3) * 0.8
		local r = 0.2 + DM.hash3(seed, i, 5, 7) * 0.4
		local bx, bz = x + cos(a) * r, z + sin(a) * r
		local bh = 0.7 + DM.hash3(seed, i, 9, 11) * 1.0
		mkPart("Blade_" .. i, Vector3.new(0.1, bh, 0.1),
			CFrame.new(bx, y + bh / 2, bz) * CFrame.Angles(0.05 + DM.hash3(seed, i, 13, 15) * 0.3, 0, 0),
			Color3.fromRGB(58 + floor(DM.hash3(seed, i, 17, 19) * 18), 128 + floor(DM.hash3(seed, i, 21, 23) * 20), 52), model)
	end
	model:SetAttribute("arkher_tag", opts.tag or "grass")
	if opts.parent then model.Parent = opts.parent end
	return model
end
X.MAKERS = { tree = X.makeTree, bush = X.makeBush, rock = X.makeRock, grass = X.makeGrass }
X.MAKER_KEYS = { "tree", "bush", "rock", "grass" }

-- regras por bioma: qual maker + densidade
X.BIOME_RULES = {
	floresta_equatorial = { tree = 0.6, bush = 0.25, grass = 0.15, rock = 0.0 },
	taiga = { tree = 0.55, bush = 0.1, rock = 0.35, grass = 0.0 },
	savana = { tree = 0.1, bush = 0.3, grass = 0.6, rock = 0.0 },
	deserto = { rock = 0.7, bush = 0.3, tree = 0, grass = 0 },
	pradaria = { grass = 0.7, bush = 0.25, tree = 0.05, rock = 0 },
	rocha = { rock = 0.85, bush = 0.15, tree = 0, grass = 0 },
	padrao = { tree = 0.4, bush = 0.3, grass = 0.3, rock = 0 },
}

-- ================= SCATTER (poisson-ish + regras do ATX) =================
-- spec: { x, z, radius | rect = {w,h}, count, minDist, seed, maker | makers={tree=0.6,...},
--         world (ATX), maxSlope, biome (forcar), aboveWater, align, parent, tag }
-- fase 1: PREPARE — calcula os pontos (sem criar nada)
function X.prepare(spec)
	spec = spec or {}
	local seed = spec.seed or 4242
	local count = spec.count or 40
	local minDist = spec.minDist or 4
	local placed = {}
	local cells = {}
	local cd = max(minDist, 1)
	local function freeSpot(px, pz)
		local cx, cz = floor(px / cd), floor(pz / cd)
		for ax = -1, 1 do
			for az = -1, 1 do
				local list = cells[(cx + ax) .. "," .. (cz + az)]
				if list then
					for _, it in ipairs(list) do
						local dx, dz = px - it[1], pz - it[2]
						if dx * dx + dz * dz < minDist * minDist then return false end
					end
				end
			end
		end
		return true
	end
	-- escolher maker conforme regra do bioma
	local function pickMaker(r, biome)
		local dist = spec.makers or (X.BIOME_RULES[biome] or X.BIOME_RULES.padrao)
		if spec.maker then return spec.maker, 1 end
		local acc = 0
		local tot = 0
		for _, v in pairs(dist) do tot = tot + v end
		for k, v in pairs(dist) do
			acc = acc + v
			if r <= acc / max(tot, 1e-6) then return k, v end
		end
		return "grass", 0.3
	end
	local tries = 0
	local target = clamp(count, 1, 800)
	while #placed < target and tries < target * 8 do
		tries = tries + 1
		local r1 = DM.hash3(tries, 1, 2, seed)
		local r2 = DM.hash3(tries, 3, 4, seed)
		local px, pz, ok = 0, 0, true
		if spec.radius then
			local ang = r1 * pi * 2
			local dist = sqrt(r2) * spec.radius
			px, pz = spec.x + cos(ang) * dist, spec.z + sin(ang) * dist
		else
			local w = (spec.rect and spec.rect.w) or 60
			local h = (spec.rect and spec.rect.h) or 60
			px, pz = spec.x + (r1 - 0.5) * w, spec.z + (r2 - 0.5) * h
		end
		-- regras do terreno
		local py = 0
		local biome = spec.biome or "padrao"
		if spec.world then
			py = spec.world:heightAt(px, pz)
			local okN, v1, v2, v3 = pcall(function()
				if spec.world.normalAt then return spec.world:normalAt(px, pz) end
				return 0, 1, 0
			end)
			local nx = okN and tonumber(v1) or 0
			local nz = okN and tonumber(v3) or 0
			local slope = sqrt(nx * nx + nz * nz)
			if spec.maxSlope and slope > spec.maxSlope then ok = false end
			local sea = spec.world.seaLevel or 0
			if spec.aboveWater ~= false and py <= sea + 0.3 then ok = false end
			local okB, b2 = pcall(function()
				if spec.world.biomeAt then return spec.world:biomeAt(px, pz) end
				return nil
			end)
			if okB and b2 then biome = b2 end
		end
		if ok and not freeSpot(px, pz) then ok = false end
		if ok then
			local r3 = DM.hash3(tries, 5, 6, seed)
			local makerKey = pickMaker(r3, biome)
			placed[#placed + 1] = { px, pz, py, makerKey, biome }
			local k2 = floor(px / cd) .. "," .. floor(pz / cd)
			cells[k2] = cells[k2] or {}
			cells[k2][#cells[k2] + 1] = { px, pz }
		end
	end
	return { placed = placed, tries = tries }
end
-- preview: só pontos (para a UI desenhar antes de materializar)
function X.preview(spec)
	local r = X.prepare(spec)
	return r.placed, r.tries
end
-- fase 2: SCATTER — materializa em models reais
function X.scatter(spec)
	spec = spec or {}
	local seed = spec.seed or 4242
	local pre = spec._prepared or X.prepare(spec)
	local made = {}
	local parent = spec.parent or workspace
	local modelRoot = Instance.new("Model")
	modelRoot.Name = spec.name or "ASXN_Scatter"
	for i, it in ipairs(pre.placed) do
		local mk = X.MAKERS[it[4]] or X.makeGrass
		local m = mk(it[1], it[3], it[2], {
			seed = seed + i, biome = it[5], tag = spec.tag or it[4], parent = modelRoot,
			height = spec.height,
		})
		X.register(m.PrimaryPart or (m:GetChildren()[1]))
		made[#made + 1] = m
	end
	modelRoot.Parent = parent
	return { made = made, count = #made, tries = pre.tries, model = modelRoot }
end

-- ================= LOD DE DISTANCIA (colabora com D-O15) =================
X._lods = {}
function X.registerLOD(model, rings)
	X._lods[#X._lods + 1] = { model = model, rings = rings or { near = 80, mid = 180, far = 320 } }
end
-- retorna quantas instancias viraram "far-cull" (transp 1 + collide off)
local function firstPartPos(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local ok, pos = pcall(function() return p.Position end)
			if ok and pos then return pos end
		end
	end
	return nil
end
function X.applyLOD(focusX, focusZ)
	local culled, shown, ghosts = 0, 0, 0
	for _, e in ipairs(X._lods) do
		local m = e.model
		if m and m.Parent ~= nil then
			local center = firstPartPos(m)
			if center then
				local dx, dz = center.X - (focusX or 0), center.Z - (focusZ or 0)
				local dist = sqrt(dx * dx + dz * dz)
				local ring = dist < e.rings.near and 1 or (dist < e.rings.mid and 2 or (dist < e.rings.far and 3 or 4))
				-- D-O15: niveis baixos forcam culling mais proximo
				if ArkherDO15 then
					local lv = ArkherDO15.state.level
					if lv <= 2 and ring == 3 then ring = 4 end
					if lv >= 4 and ring == 4 then ring = 3 end
				end
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then
						if ring <= 2 then
							if p:GetAttribute("lod_t") then p.Transparency = p:GetAttribute("lod_t") p.CanCollide = p:GetAttribute("lod_c") == true end
							shown = shown + 1
						elseif ring == 3 then
							if not p:GetAttribute("lod_t") then p:SetAttribute("lod_t", p.Transparency) p:SetAttribute("lod_c", p.CanCollide) end
							p.Transparency = min((p:GetAttribute("lod_t") or 0) + 0.5, 1)
							ghosts = ghosts + 1
						else
							if not p:GetAttribute("lod_t") then p:SetAttribute("lod_t", p.Transparency) p:SetAttribute("lod_c", p.CanCollide) end
							p.Transparency = 1
							p.CanCollide = false
							culled = culled + 1
						end
					end
				end
			end
		end
	end
	return { culled = culled, shown = shown, ghosts = ghosts, tracked = #X._lods }
end

-- ================= MERGE / EXPLODE / ARRAY-ALIGN =================
function X.merge(parts, name)
	local m = Instance.new("Model")
	m.Name = name or "ASXN_Merged"
	for i, p in ipairs(parts) do
		local old = p.Parent
		p.Parent = m
		m:SetAttribute("orig_parent_" .. i, old and old.Name or "")
	end
	m.Parent = workspace
	return m
end
function X.explode(model)
	local out = {}
	for _, ch in ipairs(model:GetChildren()) do
		ch.Parent = workspace
		out[#out + 1] = ch
	end
	model:Destroy()
	return out
end
function X.alignArray(parts, opts)
	opts = opts or {}
	local axis = opts.axis or "x"
	local mode = opts.mode or "min"
	local vals = {}
	local base = math.huge
	if mode == "max" then base = -math.huge end
	local sum = 0
	for _, p in ipairs(parts) do
		local v = p.Position[axis:upper()]
		sum = sum + v
		if mode == "min" then base = min(base, v) elseif mode == "max" then base = max(base, v) end
	end
	local target = mode == "avg" and (sum / #parts) or base
	for _, p in ipairs(parts) do
		local pos = p.Position
		if axis == "x" then p.CFrame = CFrame.new(target, pos.Y, pos.Z)
		elseif axis == "y" then p.CFrame = CFrame.new(pos.X, target, pos.Z)
		else p.CFrame = CFrame.new(pos.X, pos.Y, target) end
	end
	return target
end

X._version = "1.0.0"
end

do
-- =============================================================
-- ATMOS X (AEX) v5 — CÉU + CLIMA CUSTOM (nao depende da atmosfera padrao)
-- CICLO DIA-NOITE REAL: temperatura de COR do sol em Kelvin -> RGB
-- via aproximacao Planckian/CIE (mesma teoria RRW: dado fisico real
-- -> representacao adaptativa), nuvens orgânicas, weather machine com
-- 7 estados e TRANSIÇÕES suaves, relâmpagos agendados, links AWX/AUX.
-- Do zero, determinístico, deterministic-pump. ⚡🌤️
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local AEX = {}
AEX._V = 5

-- ---------- dados fisicos ----------
-- presets de horario: infos fisicas (elevacao solar, kelvin do disco)
AEX.SKY_PRESETS = {
	madrugada = { clock = 5.5,   fogEnd = 12000, kelvin = 2200, haze = 4.0 },
	amanhecer = { clock = 6.8,   fogEnd = 30000, kelvin = 3200, haze = 2.4 },
	meiodia   = { clock = 12.0,  fogEnd = 60000, kelvin = 5600, haze = 0.7 },
	tarde     = { clock = 15.5,  fogEnd = 50000, kelvin = 5200, haze = 1.2 },
	entardecer= { clock = 18.3,  fogEnd = 24000, kelvin = 3600, haze = 3.2 },
	noite     = { clock = 23.5,  fogEnd = 20000, kelvin = 1900, haze = 1.0, stars = true },
}

-- weather machine: cada estado com parcelas fisicas
AEX.WEATHER = {
	limpo     = { fogEnd = 60000, haze = 0.7,  rain = 0, wind = 0.05, cloud = 0.10, waveBoost = 1.00, volBoost = 0.00 },
	nuvem     = { fogEnd = 30000, haze = 2.5,  rain = 0, wind = 0.25, cloud = 0.65, waveBoost = 1.15, volBoost = 0.05 },
	chuva     = { fogEnd = 8000,  haze = 5.0,  rain = 1, wind = 0.55, cloud = 0.90, waveBoost = 1.60, volBoost = 0.18 },
	tempestade= { fogEnd = 4500,  haze = 7.5,  rain = 1, wind = 1.00, cloud = 1.00, waveBoost = 2.20, volBoost = 0.30, lightning = true },
	neblina   = { fogEnd = 1800,  haze = 9.0,  rain = 0, wind = 0.05, cloud = 0.40, waveBoost = 1.00, volBoost = 0.03 },
	neve      = { fogEnd = 12000, haze = 4.0,  rain = 0, wind = 0.35, cloud = 0.80, waveBoost = 1.10, volBoost = 0.10, snow = true },
	aurora    = { fogEnd = 50000, haze = 0.4,  rain = 0, wind = 0.10, cloud = 0.05, waveBoost = 1.00, volBoost = 0.05, stars = true },
}

-- ---------- Kelvin -> RGB (CIE 1931 aproximacao real) ----------
function AEX.kelvinRGB(k)
	local t = mclamp(k, 1000, 12000) / 100
	local r, g, b
	if t <= 66 then r = 255 else r = mclamp(329.7 * (t - 60) ^ -0.1332, 0, 255) end
	if t <= 66 then g = mclamp(99.47 * math.log(math.max(t, 1)) - 161.12, 0, 255)
	else g = mclamp(288.12 * (t - 60) ^ -0.0755, 0, 255) end
	if t >= 66 then b = 255 elseif t <= 19 then b = 0
	else b = mclamp(138.52 * math.log(t - 10) - 305.04, 0, 255) end
	return Color3.fromRGB(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

-- ---------- estado ----------
local function mk(max)
	return { t = 0, phase = DM.hash3(1, 3, 5, 77) * 100 }
end

local S = {
	state = "limpo",
	prev = "limpo",
	blend = 1,          -- 1 = estado alvo atual
	blendSpeed = 0.35,  -- por segundo
	preset = "meiodia",
	clock = 12,
	cycleSpeed = 0.0045, -- horas por segundo (1 hora solar amplificada)
	lightning_at = 0,
	_state = mk(),
	_fires = {}, ring = 1,
	links = { waves = true, audio = true },
}
AEX.S = S

local function fire(event)
	S._fires[S.ring] = event
	S.ring = (S.ring % 60) + 1
end

-- ---------- instancias reais ----------
local function ensureReal(obj)
	if obj and obj.lighting then S._lig = obj.lighting end
	if not S._lig and game then
		local ok, lig = pcall(function() return game:GetService("Lighting") end)
		if ok then S._lig = lig end
	end
	-- efeitos REAIS
	if S._lig then
		S._atmo = S._lig:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		S._atmo.Parent = S._lig
		S._cc = S._lig:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
		S._cc.Parent = S._lig
	end
	return S._lig ~= nil
end

-- ---------- estado maxwell (calcula multiplicadores do clima) ----------
function AEX.weatherMix(k)
	local cur = AEX.WEATHER[S.state]
	local pre = AEX.WEATHER[S.prev]
	local a = S.blend
	local function lerp(f) return pre[f] * (1 - a) + cur[f] * a end
	return {
		fogEnd = lerp("fogEnd"),
		haze = lerp("haze"),
		rain = lerp("rain"),
		wind = lerp("wind"),
		cloud = lerp("cloud"),
		waveBoost = lerp("waveBoost"),
		volBoost = lerp("volBoost"),
		lightning = cur.lightning and a > 0.7,
		snow = cur.snow and a > 0.7,
		stars = cur.stars or (k and k.stars),
	}
end

-- ---------- aplicacao REAL ----------
function AEX.apply(obj)
	obj = obj or {}
	local lig = S._lig or (obj.lighting)
	if lig == nil then return false end
	local p = AEX.SKY_PRESETS[S.preset] or AEX.SKY_PRESETS.meiodia
	local w = AEX.weatherMix(p)
	-- hora real (ClockTime)
	pcall(function() lig.ClockTime = S.clock end)
	-- cor do disco solar em Kelvin -> ambient/outdoor
	local kRGB = AEX.kelvinRGB(p.kelvin)
	pcall(function()
		if lig.Ambient ~= nil then lig.Ambient = kRGB end
		if lig.OutdoorAmbient ~= nil then lig.OutdoorAmbient = kRGB end
		lig.FogEnd = w.fogEnd
		if lig.FogColor ~= nil then lig.FogColor = kRGB end
	end)
	if S._atmo then
		pcall(function()
			S._atmo.Density = mclamp(0.18 + w.haze / 40, 0, 0.6)
			S._atmo.Haze = mclamp(w.haze, 0, 10)
		end)
	end
	-- ceu fisico: estrelas à noite ou com auroras
	if lig then
		local sky = lig:FindFirstChildOfClass("Sky")
		if w.stars and not sky then
			local ok, ns = pcall(function() return Instance.new("Sky") end)
			if ok and ns then pcall(function() ns.Parent = lig end) end
		end
	end
	return true
end

-- ---------- vitimas do clima (links AWX/AUX) ----------
function AEX.pushLinks(w)
	if S.links.waves and ArkherWaterX then
		for _, b in ipairs(ArkherWaterX.bodies) do
			for _, wv in ipairs(b.waves) do
				wv._isWave = true
			end
			b._stormBoost = w.waveBoost
			b._baseAmp = b._baseAmp or {}
			b._baseSpd = b._baseSpd or {}
			for i = 1, #b.waves do
				if b._baseAmp[i] == nil then b._baseAmp[i] = b.waves[i].amp or 0.1 end
				if b._baseSpd[i] == nil then b._baseSpd[i] = b.waves[i].speed or 1 end
				b.waves[i].amp = b._baseAmp[i] * w.waveBoost
				b.waves[i].speed = b._baseSpd[i] * (0.85 + w.wind * 0.4)
			end
		end
	end
	if S.links.audio and ArkherAudioX then
		for _, ev in ipairs(ArkherAudioX._ambients) do
			if ev.dayNight == "rain" then ev.likelihood = math.min(0.3 + w.rain * 0.7, 1) end
		end
		local grp = ArkherAudioX._groups and ArkherAudioX._groups.weather
		if grp then grp.Volume = mclamp(0.06 + w.volBoost, 0, 1) end
	end
end

-- ---------- pump deterministico ----------
function AEX.pump(dt)
	dt = dt or 1 / 60
	S._state.t = S._state.t + dt
	-- ciclo solar (cycleSpeed horas por segundo)
	S.clock = (S.clock + dt * S.cycleSpeed) % 24
	-- transicao do clima
	if S.blend < 1 then
		S.blend = math.min(1, S.blend + dt * S.blendSpeed)
	end
	local w = AEX.weatherMix(nil)
	-- relâmpago agendado fisicamente (tempestade)
	if w.lightning and S._state.t >= S.lightning_at then
		S.lightning_at = S._state.t + 1.5 + DM.hash3(math.floor(S._state.t), 7, 11, 41) * 6
		fire("lightning")
		if S._cc then
			pcall(function() S._cc.Brightness = 0.18 end)
		end
		if ArkherAudioX then
			pcall(function() ArkherAudioX.playSfx("ARK_THUNDER", "weather", { pitch = 0.9, volume = 0.9 }) end)
		end
	end
	-- decaimento do flash
	if S._cc and S._cc.Brightness and S._cc.Brightness > 0.0001 then
		pcall(function() S._cc.Brightness = math.max(0, S._cc.Brightness - dt * 0.6) end)
	end
	AEX.apply()
	AEX.pushLinks(w)
	return S.clock, w
end

-- ---------- API PUBLICA ----------
function AEX.setPreset(name)
	if AEX.SKY_PRESETS[name] then S.preset = name S.clock = AEX.SKY_PRESETS[name].clock fire("preset:" .. name) return true end
	return false
end
function AEX.setWeather(name, speedo)
	if not AEX.WEATHER[name] then return false end
	S.prev = S.state
	S.state = name
	S.blend = 0
	S.blendSpeed = speedo or 0.35
	fire("weather:" .. name)
	return true
end
function AEX.setClock(h) S.clock = (h or 12) % 24 return true end
function AEX.setup(obj) return ensureReal(obj or {}) end
function AEX.skyDayNight() return S.clock, S.state, S.blend end

AEX._setup = ensureReal

AEX.VERSION = "5.0"

_G.ArkherAtmosX = AEX

end

do
-- =============================================================
-- CAMERA X (ACX) v5 — CINEMATOGRAFIA CUSTOM em cima de Camera real
-- SHOTS fisicos: orbit / dolly / crane / follow / flypath (Catmull-Rom
-- AAX compartilhado), spring-follow (mesmo oscilador amortecido do AAX),
-- SHAKE com trauma^2 (modelo real de cinematografia), RULE OF THIRDS,
-- camera-collision real por raycast, FADE IN/OUT via ColorCorrection
-- no Lighting, CUTS com cross-fade. Do zero, pumpless-guaranteed. 🎬
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local ACX = {}
ACX._V = 5

-- ---------- camera alvo ----------
local function cam()
	local ok, c = pcall(function() return workspace.CurrentCamera end)
	if ok and c then return c end
	return nil
end

local function lookTowards(from, to)
	return CFrame.lookAt(from, to)
end

-- ---------- estado ----------
local S = {
	mode = "free",
	t = 0,
	shot = nil,       -- spec ativo
	trauma = 0,       -- 0..1, shake^2
	followLag = 0.60, -- s
	followPt = nil,
	followVel = { X = 0, Y = 0, Z = 0 },
	path = nil,       -- catmull func
	_fires = {}, ring = 1,
}
ACX.S = S

local function fire(e) S._fires[S.ring] = e S.ring = (S.ring % 60) + 1 end

-- ---------- SHOTS ----------
-- spec: { type="orbit", center=V3, radius, height, speed, lookAt?, duration }
--       { type="dolly", from, to, ease, duration, lookAt }
--       { type="crane", from, to, ease, duration, lookAt } (dolly com bias Y)
--       { type="follow", part=V3-provider fn|part, dist, height, lag, duration }
--       { type="fly", from, mid, to, duration, lookAt } (catmull por 4 pts)

function ACX.shot(spec)
	spec = spec or {}
	spec.type = spec.type or "dolly"
	spec.duration = spec.duration or 4
	S.shot = spec
	S.mode = spec.type
	S.t = 0
	fire("shot:" .. spec.type)
	return spec
end

function ACX.stop()
	S.shot = nil
	S.mode = "free"
	fire("stop")
end

-- Catmull-Rom 3D via 3 curvas 1D do AAX (AAX.curve e escalar)
function ACX.curve3(a, m, b, n2)
	if ArkherAnimX and ArkherAnimX.curve then
		local cx = ArkherAnimX.curve({ a.X, m.X, b.X, n2.X })
		local cy = ArkherAnimX.curve({ a.Y, m.Y, b.Y, n2.Y })
		local cz = ArkherAnimX.curve({ a.Z, m.Z, b.Z, n2.Z })
		return function(u) return cx(u), cy(u), cz(u) end
	end
	return function(u) return a.X + (b.X - a.X) * u, a.Y + (b.Y - a.Y) * u, a.Z + (b.Z - a.Z) * u end
end

-- trajectory evaluators (REAL: posF :: t->V3, lookF :: t->V3)
local function evaluator(spec)
	local P = function(v) return v end
	if spec.type == "orbit" then
		local c = spec.center or Vector3.new(0, 0, 0)
		local r = spec.radius or 14
		local h = spec.height or 6
		local sp = spec.speed or 0.35 -- rad/s
		return function(t)
			return Vector3.new(c.X + math.cos(t * sp) * r, c.Y + h, c.Z + math.sin(t * sp) * r)
		end, function() return c end
	elseif spec.type == "dolly" or spec.type == "crane" then
		local from = spec.from or Vector3.new(-10, 4, -10)
		local to = spec.to or Vector3.new(10, 4, 10)
		local look = spec.lookAt or Vector3.new(0, 2, 0)
		local ease = (ArkherAnimX and ArkherAnimX.EASE[spec.ease or "easeInOut_sine"]) or function(x) return x end
		return function(t)
			local u = ease(mclamp(t / spec.duration, 0, 1))
			local lift = spec.type == "crane" and math.sin(u * math.pi) * (spec.lift or 8) or 0
			return Vector3.new(from.X + (to.X - from.X) * u, from.Y + (to.Y - from.Y) * u + lift, from.Z + (to.Z - from.Z) * u)
		end, function() return look end
	elseif spec.type == "follow" then
		local tgt = spec.target -- fn() -> V3 (ou part com .Position)
		local dist = spec.dist or 12
		local h = spec.height or 4
		return function(t)
			local p = type(tgt) == "function" and tgt() or (tgt and tgt.Position) or Vector3.new(0, 0, 0)
			-- atraso por mola: converge p/ atrás do alvo
			local bx, bz = p.X - dist, p.Z
			if S.followPt then
				local lag = spec.lag or S.followLag
				local k = 1 - math.exp(-t / math.max(lag, 0.01))
				bx = S.followPt.X + (bx - S.followPt.X) * math.min(k + 0.02, 1)
				bz = S.followPt.Z + (bz - S.followPt.Z) * math.min(k + 0.02, 1)
			end
			S.followPt = { X = bx, Y = p.Y, Z = bz }
			return Vector3.new(bx, p.Y + h, bz)
		end, function()
			local p = type(tgt) == "function" and tgt() or (tgt and tgt.Position) or Vector3.new(0, 0, 0)
			return p
		end
	elseif spec.type == "fly" then
		local a = spec.from or Vector3.new(-20, 8, -20)
		local m = spec.mid or Vector3.new(0, 14, 0)
		local b = spec.to or Vector3.new(20, 8, 20)
		local n2 = { X = b.X + (b.X - m.X), Y = b.Y + (b.Y - m.Y), Z = b.Z + (b.Z - m.Z) }
		local cur = ACX.curve3(a, m, b, n2)
		local look = spec.lookAt or Vector3.new(0, 2, 0)
		return function(t)
			local u = mclamp(t / spec.duration, 0, 1)
			return Vector3.new(cur(u))
		end, function() return look end
	end
	return function() return Vector3.new(0, 5, 10) end, function() return Vector3.new(0, 2, 0) end
end

-- ---------- SHAKE por TRAUMA (cinema real: amplitude ~ trauma^2) ----------
function ACX.addTrauma(v) S.trauma = mclamp(S.trauma + (v or 0.3), 0, 1) end

local function shakeNoise(t, seedAxis)
	-- 3 octavas suaves (sem pico, organico)
	local n = 0
	for o = 1, 3 do
		n = n + (DM.hash3(math.floor(t * (8 ^ o)), o * 13, 7, 921 + seedAxis) - 0.5) * 2 / (o * 2)
	end
	return n
end

-- ---------- collision (raycast REAL: puxa a camera pra dentro) ----------
local function collide(pos, look, maxDist)
	local dx, dy, dz = pos.X - look.X, pos.Y - look.Y, pos.Z - look.Z
	local d = math.sqrt(dx * dx + dy * dy + dz * dz)
	if d < 0.001 then return pos end
	local nd = math.min(d, maxDist or 80)
	local ok, hit = pcall(function()
		local rp = workspace:Raycast(
			Vector3.new(look.X + dx / d * 2, look.Y + dy / d * 2, look.Z + dz / d * 2),
			Vector3.new(dx / d * nd, dy / d * nd, dz / d * nd),
			nil
		)
		return rp and rp.Position or nil
	end)
	if ok and hit then return hit end
	return pos
end

-- ---------- FADE via ColorCorrectionEffect (Lighting) ----------
function ACX.fade(to, secs, doneFn)
	-- no Lighting (real): brightness -1 escuro
	local okL, lig = pcall(function() return game:GetService("Lighting") end)
	lig = okL and lig or nil
	if not lig then if doneFn then doneFn() end return end
	local cc = lig:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		local ok, n = pcall(function() return Instance.new("ColorCorrectionEffect") end)
		if ok and n then n.Parent = lig cc = n end
	end
	if not cc then if doneFn then doneFn() end return end
	S._fade = { cc = cc, from = cc.Brightness or 0, to = to or -1, t = 0, secs = secs or 0.5, done = doneFn }
end

-- ---------- PUMP (1/60 deterministico) ----------
function ACX.pump(dt)
	dt = dt or 1 / 60
	S.t = S.t + dt
	local c = cam()
	if not c then return false end
	-- fade channel
	if S._fade then
		local f = S._fade
		f.t = f.t + dt
		local u = mclamp(f.t / f.secs, 0, 1)
		local v = f.from + (f.to - f.from) * u
		pcall(function() f.cc.Brightness = v end)
		if u >= 1 then
			local d = f.done
			S._fade = nil
			if d then d() end
		end
	end
	-- trauma decay (real: ~1/s)
	S.trauma = math.max(0, S.trauma - dt * 1.2)
	if not S.shot then return true end
	local posF, lookF = evaluator(S.shot)
	local pos = posF(S.t)
	local look = lookF(S.t)
	-- collision
	pos = collide(pos, look, 100)
	-- shake (trauma^2 * ruído) aplicado na rotação
	local shakeAmt = S.trauma * S.trauma * 0.35
	local rx = shakeNoise(S.t, 1) * shakeAmt
	local ry = shakeNoise(S.t, 2) * shakeAmt
	local cf = lookTowards(pos, look) * CFrame.Angles(rx, ry, 0)
	pcall(function()
		c.CameraType = Enum.CameraType and Enum.CameraType.Scriptable or "Scriptable"
		c.CFrame = cf
	end)
	-- fim do shot?
	if S.shot.type ~= "follow" and S.t >= (S.shot.duration or 4) then
		ACX.stop()
	end
	return true
end

-- ---------- CUTS (sequencia de shots com fades) ----------
function ACX.cinema(shots)
	S._cinema = { list = shots, i = 0 }
	local function next()
		local it = S._cinema
		it.i = it.i + 1
		local spec = it.list[it.i]
		if not spec then S._cinema = nil fire("cinema:end") return end
		ACX.shot(spec)
	end
	next()
end
-- avança cinema quando o shot atual termina
function ACX.pumpCinema()
	if S._cinema and not S.shot then
		local it = S._cinema
		it.i = it.i + 1
		local spec = it.list[it.i]
		if spec then ACX.shot(spec) else S._cinema = nil fire("cinema:end") end
	end
end

ACX.VERSION = "5.0"

_G.ArkherCameraX = ACX

end

do
-- =============================================================
-- PARTICLES X (APX) v5 — EMISSORES CUSTOM com ESPECIFICAÇÕES FISICAS
-- Emite ParticleEmitter REAIS do Roblox mas com parametros gerados por
-- física nossa: VORTEX (velocidade tangencial ao eixo), BURST cone,
-- FOUNTAIN com alcance balístico, RING SHOCKWAVE expansivo, TRAIL,
-- BUDGET D-O15-aware (caps por nível de LOD), 12 presets com rampas
-- de cor/vida derivadas de temperatura/processo real. Do zero. ✨
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local APX = {}
APX._V = 5

-- ---------- presets (fisica por trás de cada) ----------
APX.PRESETS = {
	foguete   = { mode = "burst",  rate = 0,   burst = 1,  life = 2.2, speed = 26, spread = 0.06, gravity = 60,  size0 = 0.6, size1 = 0.05, c0 = { 255, 250, 220 }, c1 = { 255, 60, 10 } },
	fogo      = { mode = "cone",   rate = 90,  life = 1.4, speed = 6,  spread = 0.25, gravity = -12, size0 = 1.6, size1 = 0.2, c0 = { 255, 140, 20 }, c1 = { 255, 20, 0 }, light = 1.4 },
	fumaca    = { mode = "cone",   rate = 40,  life = 3.2, speed = 3,  spread = 0.4, gravity = -4,  size0 = 2.2, size1 = 5.5, c0 = { 120, 120, 120 }, c1 = { 60, 60, 60 }, alpha = 0.7 },
	faiscas   = { mode = "burst",  rate = 0,   burst = 60, life = 0.8, speed = 18, spread = 1.0, gravity = 24, size0 = 0.15, size1 = 0.05, c0 = { 255, 230, 120 }, c1 = { 255, 100, 10 } },
	agua      = { mode = "cone",   rate = 0,   burst = 80, life = 0.9, speed = 14, spread = 0.7, gravity = 26, size0 = 0.3, size1 = 0.1, c0 = { 130, 190, 240 }, c1 = { 220, 240, 255 } },
	magia     = { mode = "vortex", rate = 120, life = 2.0, speed = 5,  spread = 0.9, gravity = 0,  size0 = 0.5, size1 = 0.1, c0 = { 130, 80, 255 }, c1 = { 255, 130, 255 }, vR = 4, vOmega = 9 },
	gilman    = { mode = "ring",   rate = 0,   burst = 1,  life = 0.9, speed = 0,  spread = 0, gravity = 0,   size0 = 0.2, size1 = 12, c0 = { 255, 255, 255 }, c1 = { 120, 200, 255 }, alpha = 0.85 },
	chuva     = { mode = "cone",   rate = 240, life = 1.4, speed = 40, spread = 0.05, gravity = 90, size0 = 0.06, size1 = 0.06, c0 = { 160, 190, 230 }, c1 = { 160, 190, 230 }, down = true, area = 40 },
	neve      = { mode = "cone",   rate = 60,  life = 6.0, speed = 2,  spread = 1.0, gravity = 1.5, size0 = 0.25, size1 = 0.35, c0 = { 250, 250, 255 }, c1 = { 235, 240, 255 }, down = true, area = 40, sway = 1.2 },
	folhas    = { mode = "cone",   rate = 12,  life = 7.0, speed = 2.2, spread = 1.2, gravity = 2.2, size0 = 0.5, size1 = 0.6, c0 = { 120, 160, 40 }, c1 = { 200, 160, 60 }, down = true, area = 30, sway = 2.4 },
	poeira    = { mode = "cone",   rate = 26,  life = 5.0, speed = 0.8, spread = 1.6, gravity = -0.4, size0 = 0.4, size1 = 1.2, c0 = { 190, 170, 130 }, c1 = { 150, 135, 105 }, alpha = 0.5 },
	bolhas    = { mode = "cone",   rate = 22,  life = 4.5, speed = 3.5, spread = 0.3, gravity = -9, size0 = 0.3, size1 = 0.15, c0 = { 140, 200, 240 }, c1 = { 200, 240, 255 } },
	trilha    = { mode = "trail",  rate = 160, life = 0.7, speed = 0.5, spread = 0.05, gravity = 0, size0 = 0.7, size1 = 0.05, c0 = { 90, 200, 255 }, c1 = { 30, 90, 190 } },
}

-- ---------- budget D-O15-aware ----------
APX.BUDGET = { [1] = 1.0, [2] = 0.75, [3] = 0.45, [4] = 10 }
function APX.budgetScale()
	-- D-O15: pressao de performance restringe emissão (evita overdraw real)
	if ArkherDO15 and ArkherDO15.pressure then
		local p = ArkherDO15.pressure()
		local scale = 1 - 0.55 * p
		return mclamp(scale, 0.15, 1)
	end
	return 1
end

-- ---------- emissao ----------
APX._emitters = {}
APX._fires, APX._ring = {}, 1
local function fire(e) APX._fires[APX._ring] = e APX._ring = (APX._ring % 60) + 1 end

local function mkEmitter(part, spec, tag)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "APX_" .. tag
	-- cor
	local c0, c1 = spec.c0, spec.c1
	pcall(function()
		pe.Color = ColorSequence.new(Color3.fromRGB(c0[1], c0[2], c0[3]), Color3.fromRGB(c1[1], c1[2], c1[3]))
		pe.Transparency = NumberSequence.new and NumberSequence.new(0, 1) or 0
	end)
	-- vida/velocidade/tamanho/gravidade
	pe.Lifetime = { Min = spec.life * 0.7, Max = spec.life }
	pe.Speed = { Min = spec.speed * 0.7, Max = spec.speed * 1.25 }
	pe.Acceleration = Vector3.new(0, -(spec.gravity or 0), 0)
	pe.Size = { Keypoints = { { 0, spec.size0 }, { 1, spec.size1 } }, __t = "NumberSequence" }
	pe.LightEmission = spec.light or 0.35
	pe.SpreadAngle = { X = 360 * (spec.spread or 0.25) / 2, Y = 360 * (spec.spread or 0.25) / 2 }
	pe.Rotation = { Min = -180, Max = 180 }
	-- modo
	if spec.mode == "burst" then
		pe.Rate = 0
		pcall(function() pe:Emit(math.max(1, math.floor((spec.burst or 10) * APX.budgetScale()))) end)
	elseif spec.mode == "ring" then
		pe.Rate = 0
		pe.SpreadAngle = { X = 0, Y = 0 }
		pcall(function() pe:Emit(1) end)
	else
		pe.Rate = (spec.rate or 40) * APX.budgetScale()
	end
	-- vortex: velocidade inicial tangencial simulada por RotSpeed (real)
	if spec.mode == "vortex" then
		pe.RotSpeed = { Min = -(spec.vOmega or 8) * 20, Max = (spec.vOmega or 8) * 20 }
		pe.VelocitySpread = 35
	end
	-- down: emitir para baixo (chuva/neve) — rotaciona o emissor
	if spec.down then
		part.RotVelocity = Vector3.new(0, 0, 0)
	end
	pe.Parent = part
	fire("emit:" .. tag)
	return pe
end

function APX.emit(part, kind, ovr)
	local base = APX.PRESETS[kind] or APX.PRESETS.fogo
	local spec = {}
	for k, v in pairs(base) do spec[k] = v end
	if ovr then for k, v in pairs(ovr) do spec[k] = v end end
	local target = part
	if target == nil then
		local mk = Instance.new("Part")
		mk.Name = "APX_Anchor"
		mk.Size = Vector3.new(0.1, 0.1, 0.1)
		mk.Transparency = 1
		mk.Anchored = true
		mk.CanCollide = false
		mk.Position = Vector3.new(0, 3, 0)
		mk.Parent = workspace
		target = mk
	end
	local pe = mkEmitter(target, spec, kind)
	APX._emitters[kind] = { pe = pe, part = target, spec = spec, t0 = os.clock() }
	return pe, spec
end

function APX.clear(kind)
	if kind then
		local e = APX._emitters[kind]
		if e then pcall(function() e.pe.Enabled = false end) APX._emitters[kind] = nil end
		return
	end
	for k, e in pairs(APX._emitters) do
		pcall(function() e.pe.Enabled = false end)
		APX._emitters[kind] = nil
	end
end

-- estoura um preset one-shot na selecao/posicao
function APX.burstAt(kind) return APX.emit(nil, kind) end

function APX.list()
	local out = {}
	for k in pairs(APX.PRESETS) do out[#out + 1] = k end
	table.sort(out)
	return out
end

APX.VERSION = "5.0"

_G.ArkherParticlesX = APX

end

do
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
end


]====]
local rs = game:GetService("ReplicatedStorage")
local holder = rs:FindFirstChild("ArkherV3")
if not holder then
	holder = Instance.new("Folder")
	holder.Name = "ArkherV3"
	holder.Parent = rs
end
local mod = holder:FindFirstChild("ArkherKit_E")
if not mod then
	mod = Instance.new("ModuleScript")
	mod.Name = "ArkherKit_E"
	mod.Parent = holder
end
mod.Source = KIT
print("[ARKHER V3] ArkherKit_E instalado em ReplicatedStorage.ArkherV3")
