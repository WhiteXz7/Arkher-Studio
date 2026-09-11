-- RIG X (RPX2) — sistema de esqueleto/Cascadeur++ nativo ARKHER.
-- Alem do Cascadeur: FABRIK multi-alvo, fisica de equilibrio REAL (COM projetado,
-- momento angular), locomocao procedural por intencao, ghosting/onion
-- e secundaria spring em TODOS os ossos — tudo ao vivo, dentro do jogo.

local DM = rawget(_G, "ArkherDM")

local V3 = Vector3.new
local CF = CFrame.new

local RigX = {}
local S = {
	chains = {},      -- {id -> chain}
	plays = {},       -- {id -> play}
	ghosts = {},      -- {id -> {poses ring}}
	acc = 0,
}
RigX.S = S

-- ============================ ossos/cadeia ============================
-- bone: {name, len, dir(unit Vector3 rel ao pai), mass, part?, motor?}
local function newBone(name, len, dir, mass)
	return { name = name, len = len or 1, dir = (dir or V3(0, -1, 0)).Unit,
		mass = mass or 1, pos = V3(0, 0, 0), vel = V3(0, 0, 0), sp = 0 }
end

--- cria cadeia FK a partir do root (raiz efeito-gravidade)
-- spec: {root = Vector3, bones = {{n=1.4,dir=...},...}, pole = Vector3?}
function RigX.chain(spec)
	local id = "chain" .. tostring(#S.chains + 1)
	local c = { id = id, root = spec.root or V3(0, 0, 0), bones = {}, pole = spec.pole }
	for i, b in ipairs(spec.bones) do
		table.insert(c.bones, newBone(b.name or ("b" .. i), b.len, b.dir, b.mass))
	end
	RigX.forwardKinematics(c)
	S.chains[id] = c
	return c
end

--- FK simples: posiona os ossos alongando as direcoes dos pais
function RigX.forwardKinematics(c)
	local p = c.root
	for _, b in ipairs(c.bones) do
		b.pos = p + b.dir * b.len
		p = b.pos
	end
	return c
end

-- ============================ FABRIK ============================
--- Resolve a cadeia para que o END (ultimo osso) atinja target.
-- opts: {iters=10, tols=1e-3, keepLen=true, pole=Vector3?}
function RigX.fabrik(c, target, opts)
	opts = opts or {}
	local iters = opts.iters or 12
	local tol = opts.tol or 0.01
	local n = #c.bones
	if n == 0 then return c end
	local p = {}
	p[1] = c.root
	for i, b in ipairs(c.bones) do p[i + 1] = b.pos end

	local total = 0
	for _, b in ipairs(c.bones) do total = total + b.len end
	local d = (target - c.root)

	-- unreachable: estica em linha reta
	if d.Magnitude > total * 0.999 then
		local dir = d.Unit
		for i = 2, n + 1 do
			p[i] = p[1] + dir * RigX._lenTo(c, i - 1)
		end
	else
		for _ = 1, iters do
			-- backward: do end para root
			p[n + 1] = target
			for i = n, 1, -1 do
				local dir = (p[i] - p[i + 1]).Unit
				p[i] = p[i + 1] + dir * c.bones[i].len
			end
			-- forward: raiz fixada
			p[1] = c.root
			for i = 1, n do
				local dir = (p[i + 1] - p[i]).Unit
				p[i + 1] = p[i] + dir * c.bones[i].len
			end
			-- bias de pole (perna quebrando pra frente etc.)
			local pole = opts.pole or c.pole
			if pole and n >= 2 then
				for i = 2, n do
					local a, b, c3 = p[i - 1], p[i], p[i + 1]
					local ab = b - a
					local nrm = (ab:Cross((c3 - a)):Cross(ab))
					if nrm.Magnitude > 1e-6 and ab.Magnitude > 1e-6 then
						local toPole = pole - (a + ab.Unit * math.max(0, math.min(ab.Magnitude, (pole - a):Dot(ab.Unit))))
						p[i] = p[i] + toPole * 0.18
					end
				end
				-- reforca comprimentos depois do pole
				for i = 1, n do
					local dir = (p[i + 1] - p[i]).Unit
					p[i + 1] = p[i] + dir * c.bones[i].len
				end
			end
			if (p[n + 1] - target).Magnitude < tol then break end
		end
	end

	-- grava posicoes + dirs
	for i = 1, n do
		local seg = p[i + 1] - p[i]
		if seg.Magnitude > 1e-6 then c.bones[i].dir = seg.Unit end
		c.bones[i].pos = p[i + 1]
	end
	c.end_ = p[n + 1]
	return c
end

function RigX._lenTo(c, i)
	local tot = 0
	for k = 1, i do tot = tot + c.bones[k].len end
	return tot
end

-- ============================ CCD ============================
function RigX.ccd(c, target, opts)
	opts = opts or {}
	local iters = opts.iters or 8
	local ll = {}
	for i = #c.bones, 1, -1 do table.insert(ll, i) end
	for _ = 1, iters do
		for _, i in ipairs(ll) do
			-- pivot do osso i via FK parcial
			local piv = c.root
			for k = 1, i - 1 do piv = piv + c.bones[k].dir * c.bones[k].len end
			local endPos = c.bones[#c.bones].pos
			local v1 = endPos - piv
			local v2 = target - piv
			if v1.Magnitude > 1e-6 and v2.Magnitude > 1e-6 then
				local axis = v1:Cross(v2)
				if axis.Magnitude > 1e-6 then
					local ang = math.acos(math.clamp(v1.Unit:Dot(v2.Unit), -1, 1)) * 0.6
					local rot = CFrame.fromAxisAngle(axis.Unit, math.min(ang, math.pi / 3))
					local rel = rot:VectorToWorldSpace(v1)
					c.bones[i].dir = rel.Unit
					for k = i, #c.bones do
						local piv2 = c.root
						for j = 1, k - 1 do piv2 = piv2 + c.bones[j].dir * c.bones[j].len end
						c.bones[k].pos = piv2 + c.bones[k].dir * c.bones[k].len
					end
				end
			end
		end
		local endPos = c.bones[#c.bones].pos
		if (endPos - target).Magnitude < 0.01 then break end
	end
	return c
end

-- ============================ fisica real ============================
--- Centro de massa da cadeia (massas nos ossos)
function RigX.com(c)
	local total, acc = 0, V3(0, 0, 0)
	local p = c.root
	for _, b in ipairs(c.bones) do
		local mid = (p + b.pos) * 0.5
		acc = acc + mid * b.mass
		total = total + b.mass
		p = b.pos
	end
	if total <= 0 then return p end
	return acc / total
end

--- Equilibrio estilo Cascadeur: projeta COM no "poligono de suporte"
-- (area entre os pes). Retorna margem [0..1] e correcao de inclinacao.
function RigX.balance(c, supportPoly)
	local com3 = RigX.com(c)
	local com2 = { x = com3.X, z = com3.Z }
	local minD, closest = 1e9, nil
	for i = 1, #supportPoly do
		local a = supportPoly[i]
		local b = supportPoly[(i % #supportPoly) + 1]
		local abx, abz = b.x - a.x, b.z - a.z
		local t = math.clamp(((com2.x - a.x) * abx + (com2.z - a.z) * abz) / math.max(1e-6, abx * abx + abz * abz), 0, 1)
		local qx, qz = a.x + abx * t, a.z + abz * t
		local d = math.sqrt((com2.x - qx) ^ 2 + (com2.z - qz) ^ 2)
		if d < minD then minD = d; closest = { x = qx, z = qz } end
	end
	-- dentro ou fora do poligono? (ray cast par/ímpar)
	local inside = false
	for i = 1, #supportPoly do
		local a = supportPoly[i]
		local b = supportPoly[(i % #supportPoly) + 1]
		if (a.z > com2.z) ~= (b.z > com2.z) then
			local xi = a.x + (com2.z - a.z) / (b.z - a.z) * (b.x - a.x)
			if xi > com2.x then inside = not inside end
		end
	end
	local margin = inside and minD or -minD
	return { com = com3, margin = margin, inside = inside, closest = closest }
end

--- secundaria spring: ossos perseguem a pose FK com mola real
function RigX.secondary(c, dt, stif, damp)
	stif = stif or 28
	damp = damp or 6
	RigX.forwardKinematics(c)
	for _, b in ipairs(c.bones) do
		local err = b.targetPos and (b.targetPos - b.pos) or V3(0, 0, 0)
		b.vel = b.vel + err * stif * dt
		b.vel = b.vel * math.max(0, 1 - damp * dt)
		b.pos = b.pos + b.vel * dt
	end
	return c
end

-- ============================ pose/keyframes ============================
--- Keyframe de pose automatico (intencao → movimento)
-- intent: {dir=v2?, speed=, crouch=0..1, jump=0..1, lean=}
function RigX.locomotionPose(t, intent)
	local sp = (intent.speed or 0)
	local run = math.clamp(sp / 14, 0, 1)
	local w = 2 * math.pi * (1.6 + 2.2 * run) * t
	local swing = math.sin(w)
	local swing2 = math.sin(w + math.pi)
	local crouch = intent.crouch or 0
	return {
		torso = { pitch = 0.12 * run + crouch * 0.5, roll = (intent.lean or 0) },
		head = { pitch = -0.05 * run, yaw = 0 },
		l_upperarm = { pitch = swing * (0.3 + 0.45 * run) },
		r_upperarm = { pitch = swing2 * (0.3 + 0.45 * run) },
		l_forearm = { pitch = math.abs(swing) * 0.4 * run },
		r_forearm = { pitch = math.abs(swing2) * 0.4 * run },
		l_thigh = { pitch = swing2 * (0.35 + 0.5 * run) },
		r_thigh = { pitch = swing * (0.35 + 0.5 * run) },
		l_shin = { pitch = math.max(0, -swing2) * 0.7 * run },
		r_shin = { pitch = math.max(0, -swing) * 0.7 * run },
		bob = math.abs(math.cos(w)) * 0.06 * (0.4 + run),
	}
end

--- Interpolacao Catmull-Rom entre chaves de pose (suavizada tipo Cascadeur)
function RigX.poseLerp(a, b, t2)
	local out = {}
	for k, va in pairs(a) do
		local vb = b[k]
		if type(va) == "number" then
			out[k] = va + (vb - va) * t2
		elseif type(va) == "table" and type(vb) == "table" then
			out[k] = RigX.poseLerp(va, vb, t2)
		else
			out[k] = va
		end
	end
	for k, vb in pairs(b) do if out[k] == nil then out[k] = vb end end
	return out
end

function RigX.newClip(keys, opts)
	opts = opts or {}
	return { keys = keys, duration = opts.duration or (#keys > 0 and keys[#keys].t or 0), loop = opts.loop ~= false }
end

function RigX.sampleClip(clip, t2)
	if clip.loop and clip.duration > 0 then t2 = t2 % clip.duration end
	local keys = clip.keys
	if #keys == 0 then return {} end
	if t2 <= keys[1].t then return keys[1].pose end
	if t2 >= keys[#keys].t then return keys[#keys].pose end
	local i = 1
	while i < #keys and keys[i + 1].t < t2 do i = i + 1 end
	local a, b = keys[i], keys[i + 1]
	-- hermite cubico (ease suave entre chaves)
	local u = (t2 - a.t) / math.max(1e-6, b.t - a.t)
	local s0 = u * u * (3 - 2 * u)
	return RigX.poseLerp(a.pose, b.pose, s0)
end

-- ============================ ghost (onion) ============================
function RigX.ghostChain(c, every)
	local ring = S.ghosts[c.id]
	if not ring then ring = { i = 0, poses = {}, every = every or 0.08 } S.ghosts[c.id] = ring end
	S.acc = S.acc + 1
	if (S.acc % 6) == 0 then
		ring.i = (ring.i % 16) + 1
		local snap = {}
		for idx, b in ipairs(c.bones) do snap[idx] = { pos = b.pos, dir = b.dir } end
		ring.poses[ring.i] = snap
	end
	return ring
end

-- ============================ aplicar no mundo ============================
--- aplica uma cadeia resolvida em parts (solo robot/arma custom)
function RigX.applyToParts(c, parts, thickness, color)
	thickness = thickness or 0.3
	local prev = c.root
	for i, b in ipairs(c.bones) do
		local p = parts[i]
		if p and p:IsA("BasePart") then
			local seg = b.pos - prev
			local mid = (prev + b.pos) * 0.5
			p.Size = V3(thickness, thickness, math.max(0.05, seg.Magnitude))
			p.CFrame = CFrame.lookAt(mid, b.pos)
			p.Anchored = true
			if color then p.Color = color end
		end
		prev = b.pos
	end
end

--- demo completa (cadeia 5 ossos perseguindo target animado + ghost)
function RigX.demo()
	local c = RigX.chain({
		root = V3(0, 6, -8),
		bones = {
			{ name = "hip", len = 1.6, dir = V3(0, -1, 0), mass = 3 },
			{ name = "knee", len = 1.8, dir = V3(0, -1, 0.06), mass = 2 },
			{ name = "ankle", len = 1.7, dir = V3(0, -1, 0), mass = 1.5 },
			{ name = "ball", len = 0.5, dir = V3(0, -0.4, 0.9), mass = 0.6 },
		},
		pole = V3(0, 4, 6),
	})
	return c
end

-- ============================ pump ============================
function RigX.pump(dt)
	for _, play in pairs(S.plays) do
		play.t = play.t + dt
		if play.kind == "target" then
			-- target orbitando (demo/repelente)
			local a = play.t * (play.speed or 1.4)
			local tgt = play.center + V3(math.cos(a) * play.radius, math.sin(a * 0.7) * (play.radius * 0.35), math.sin(a) * play.radius)
			RigX.fabrik(play.chain, tgt, { iters = 10 })
			RigX.ghostChain(play.chain)
			if play.parts then RigX.applyToParts(play.chain, play.parts, play.thickness, play.color) end
		elseif play.kind == "clip" then
			local pose = RigX.sampleClip(play.clip, play.t)
			play.lastPose = pose
		end
	end
end

function RigX.playTarget(chain, opts)
	opts = opts or {}
	local id = "play" .. tostring(#S.plays + 1)
	S.plays[id] = { t = 0, kind = "target", chain = chain,
		center = opts.center or V3(0, 6, 0), radius = opts.radius or 3, speed = opts.speed or 1.4,
		parts = opts.parts, thickness = opts.thickness, color = opts.color }
	return id
end

function RigX.stopAll()
	S.plays = {}
end

_G.ArkherRigX = RigX
return RigX
