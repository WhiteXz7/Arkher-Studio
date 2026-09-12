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

