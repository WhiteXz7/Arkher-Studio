-- PHYS X (PHYSX) — FISICA AVANCADA (cat. H 3701-4300 dos TXT):
-- campo de VENTO GLOBAL com rajadas (ruido 1D real) empurrando corpos soltos,
-- mais ONDA DE CHOQUE (shockwave) com decaimento esferico. Tudo integrado ao
-- pulso do RRX e ao orcamento D-O15 (amostragem, nunca frame-rate killer).

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local PHYSX = {}
local S = {
	wind = { on = false, deg = 20, speed = 7 },
	t = 0, idx = 0, cache = {}, cacheT = 0,
	shocks = {}, -- {x,z,r,f,t,age}
}

local function dirVec()
	local a = math.rad(S.wind.deg)
	return V3(math.cos(a), 0, math.sin(a))
end

function PHYSX.setWind(on, deg, speed)
	S.wind.on = on and true or false
	if deg then S.wind.deg = deg end
	if speed then S.wind.speed = speed end
	return S.wind
end

function PHYSX.shockwave(x, z, radius, force)
	S.shocks[#S.shocks + 1] = { x = x or 0, z = z or 0, r = radius or 40, f = force or 60, age = 0 }
	return #S.shocks
end

-- colecao de corpos soltos (atualiza a cada 1.5s — barato)
local function bodies()
	if S.t - S.cacheT > 1.5 then
		S.cacheT = S.t
		S.cache = {}
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("BasePart") and not d.Anchored and not d:IsDescendantOf(game:GetService("Players")) then
				S.cache[#S.cache + 1] = d
			end
		end
	end
	return S.cache
end

function PHYSX.step(dt)
	S.t = S.t + dt
	if S.wind.on then
		local list = bodies()
		local n = #list
		if n > 0 then
			-- rajada: ruido 1D (vento real nao e constante)
			local gust = 0.65 + 0.7 * ((DM and DM.vnoise1(S.t * 0.6, 11)) or math.sin(S.t))
			local dv = dirVec() * (S.wind.speed / 10) * gust
			-- budget D-O15: fatia de corpos por tick
			local slice = math.min(n, 40)
			for i = 1, slice do
				S.idx = (S.idx % n) + 1
				local p = list[S.idx]
				if p.Parent and p.AssemblyMass then
					pcall(function()
						p.AssemblyLinearVelocity = p.AssemblyLinearVelocity + dv * dt * (10 / math.max(1, p.AssemblyMass ^ 0.5))
					end)
				end
			end
		end
	end
	-- ondas de choque (decaimento esferico)
	for i = #S.shocks, 1, -1 do
		local sh = S.shocks[i]
		sh.age = sh.age + dt
		local front = sh.r * math.min(1, sh.age / 0.6) -- frente expande 0.6s
		for _, p in ipairs(bodies()) do
			if p.Parent then
				local dx, dz = p.Position.X - sh.x, p.Position.Z - sh.z
				local d = (dx * dx + dz * dz) ^ 0.5
				if d < front and d > 0.1 then
					local fall = 1 - d / sh.r
					pcall(function()
						p.AssemblyLinearVelocity = p.AssemblyLinearVelocity + V3(dx / d, 0.6, dz / d) * sh.f * fall
					end)
				end
			end
		end
		if sh.age > 0.6 then table.remove(S.shocks, i) end
	end
end

function PHYSX.stats()
	return { wind = S.wind, bodies = #S.cache, shocks = #S.shocks }
end

do
	if RX and RX.hook then RX.hook("physx", function(dt) PHYSX.step(dt) end) end
end

_G.ArkherPhysX = PHYSX
return PHYSX
