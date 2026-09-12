-- SPACE X (SPX) — criacao de ESPACO de verdade (RRW alem do planeta):
-- corpos celestes com MATERIA real + orbitas keplerianas (p proporcional a
-- r^1.5 — 3a lei de Kepler REAL, nao animacao fake). Escala logaritmica:
-- o sistema solar nao cabe em studs na proporcao 1:1, entao o editor usa
-- escalas declaradas (log) — o dev escolhe exibicao log OU a Terra em
-- escala real via WORLDX (superficie/planetaria). Corpos entram no RRX.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local CF = CFrame.new

local SPX = {}
local S = {
	bodies = {}, orbits = true, t = 0,
	mode = "sistema",     -- superficie | planetaria | sistema | galaxia
	logK = 34,            -- escala logaritmica: raioExib = log10(rKm) * K
	orbitK = 60,
	keplerK = 14,         -- p = keplerK * orbitR^1.5 (em "dias" — o dev ajusta)
}

-- matéria colorida por tipo de corpo (mesma familia TX.MATTER)
local MATS = {
	sol = Color3.fromRGB(255, 214, 96), estrela = Color3.fromRGB(255, 214, 96),
	rocha = Color3.fromRGB(150, 120, 100), terra = Color3.fromRGB(60, 130, 220),
	oceano = Color3.fromRGB(50, 110, 200), deserto = Color3.fromRGB(214, 180, 110),
	gelo = Color3.fromRGB(200, 226, 240), gas = Color3.fromRGB(222, 186, 140),
	lava = Color3.fromRGB(255, 91, 26), lua = Color3.fromRGB(180, 178, 172),
}

SPX.S = S

SPX.MODES = {
	superficie = { studToKm = 0.004, note = "1 stud = 4 km (voo/superficie)" },
	planetaria = { studToKm = 0.64, note = "1 stud = 640 km (planeta inteiro)" },
	sistema    = { studToKm = "log", note = "log10(r_KM) * logK studs (sistema solar legivel)" },
	galaxia    = { studToKm = "ultra-log", note = "estrelas aglomeradas em mapa log" },
}

local function radiusDisplay(rKm)
	if S.mode == "galaxia" then return math.max(2, math.log10(math.max(10, rKm)) * 8) end
	if S.mode == "sistema" then return math.max(1.4, math.log10(math.max(10, rKm)) * S.logK) end
	-- escala linear (so para corpos pequenos na superficie/planetaria)
	local sk = SPX.MODES[S.mode].studToKm
	return math.max(1.4, (rKm / (type(sk) == "number" and sk or 1)))
end

local function orbitDisplay(oKm)
	if S.mode == "galaxia" then return math.max(8, math.log10(math.max(100, oKm)) * S.orbitK * 0.5) end
	if S.mode == "sistema" then return math.max(10, math.log10(math.max(100, oKm)) * S.orbitK) end
	local sk = SPX.MODES[S.mode].studToKm
	return math.min(30000, oKm / (type(sk) == "number" and sk or 1))
end

-- ============ adicionar corpo ============
function SPX.add(body)
	-- body: {name, matter, radiusKm, orbitKm, periodDays, parent ("sun"/nil), hue?}
	local b = {
		name = body.name or "corpo",
		matter = body.matter or "rocha",
		radiusKm = body.radiusKm or 6371,
		orbitKm = body.orbitKm or 0,
		periodDays = body.periodDays or 365,
		angle = (body.angleDeg or 0) / 57.2958,
		parent = body.parent,
	}
	S.bodies[#S.bodies + 1] = b
	SPX.materialize(b)
	return b
end

function SPX.materialize(b)
	local model = workspace:FindFirstChild("SPACE_" .. b.name) or Instance.new("Model")
	model.Name = "SPACE_" .. b.name
	model.Parent = workspace
	local r = radiusDisplay(b.radiusKm)
	local bb = Instance.new("Part")
	bb.Name = "corpo"
	bb.Shape = Enum.PartType.Ball
	bb.Size = V3(r * 2, r * 2, r * 2)
	bb.Anchored = true
	bb.CanCollide = false
	bb.Color = MATS[b.matter] or MATS.rocha
	bb.Material = (b.matter == "sol" or b.matter == "estrela") and Enum.Material.Neon or Enum.Material.SmoothPlastic
	bb.CFrame = CF(0, 400, 0)
	bb.Parent = model
	b.core = bb
	b.displayR = r
	b.displayOrbit = b.orbitKm > 0 and orbitDisplay(b.orbitKm) or 0
	b.periodSec = b.periodDays > 0 and (b.periodDays ^ 1.0) * 1 or 0
	-- periodo real em "segundos de simulacao": p = keplerK * orbitDisplay^1.5
	b.orbPeriod = b.displayOrbit > 0 and (S.keplerK * (b.displayOrbit / S.orbitK) ^ 1.5 * 10) or 0
	if RX then
		RX.register(bb, { kind = "part", matter = "rock", importance = 0.8,
			parent = model, meta = { spaceBody = b.name, baseTransparency = 0 } })
	end
	return model
end

-- ============ presets ============
function SPX.preset(id)
	-- limpa? nao: ACUMULA (regra de construcao do ARKHER)
	if id == "solar" then
		SPX.add({ name = "Sol", matter = "sol", radiusKm = 695700 })
		SPX.add({ name = "Mercurio", matter = "rocha", radiusKm = 2440, orbitKm = 57.9e6 })
		SPX.add({ name = "Venus", matter = "deserto", radiusKm = 6052, orbitKm = 108e6 })
		SPX.add({ name = "Terra", matter = "terra", radiusKm = 6371, orbitKm = 149.6e6 })
		SPX.add({ name = "Marte", matter = "lava", radiusKm = 3390, orbitKm = 228e6 })
		SPX.add({ name = "Jupiter", matter = "gas", radiusKm = 69911, orbitKm = 778e6 })
		SPX.add({ name = "Saturno", matter = "gas", radiusKm = 58232, orbitKm = 1433e6 })
		SPX.add({ name = "Urano", matter = "gelo", radiusKm = 25362, orbitKm = 2870e6 })
		SPX.add({ name = "Netuno", matter = "oceano", radiusKm = 24622, orbitKm = 4495e6 })
		return 9
	elseif id == "terra_lua" then
		SPX.add({ name = "Sol", matter = "sol", radiusKm = 695700 })
		SPX.add({ name = "Terra", matter = "terra", radiusKm = 6371, orbitKm = 300 })
		SPX.add({ name = "Lua", matter = "lua", radiusKm = 1737, orbitKm = 460 })
		return 3
	end
	return 0
end

-- ============ pump de orbitas (kepleriana circular: angulo avanca 2pi/T) ============
function SPX.step(dt)
	if not S.orbits then return end
	S.t = S.t + dt
	for _, b in ipairs(S.bodies) do
		if b.core and b.core.Parent and b.orbPeriod and b.orbPeriod > 0 then
			b.angle = b.angle + (math.pi * 2 / b.orbPeriod) * dt
			local cx, cz = 0, 0
			if b.parent then
				local pb = SPX.find(b.parent)
				if pb and pb.core then cx, cz = pb.core.Position.X, pb.core.Position.Z end
			end
			b.core.CFrame = CF(cx + math.cos(b.angle) * b.displayOrbit, 400,
				cz + math.sin(b.angle) * b.displayOrbit)
		end
	end
end

function SPX.find(name2)
	for _, b in ipairs(S.bodies) do if b.name == name2 then return b end end
end

function SPX.setMode(id)
	if SPX.MODES[id] then S.mode = id end
	return S.mode
end

function SPX.state()
	local out = {}
	for _, b in ipairs(S.bodies) do
		local p = b.core and b.core.Position or V3(0, 400, 0)
		out[#out + 1] = { name = b.name, x = p.X, z = p.Z, r = b.displayR or 2,
			orbit = b.displayOrbit or 0, matter = b.matter }
	end
	return out
end

function SPX.stats()
	return { bodies = #S.bodies, orbits = S.orbits, mode = S.mode,
		modeNote = SPX.MODES[S.mode].note }
end

do
	if RX and RX.hook then RX.hook("spacex", function(dt) SPX.step(dt) end) end
end

_G.ArkherSpaceX = SPX
return SPX
