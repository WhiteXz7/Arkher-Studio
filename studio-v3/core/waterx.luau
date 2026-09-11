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
