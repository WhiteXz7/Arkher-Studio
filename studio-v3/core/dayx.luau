-- DAY X (DAYX) — HUMANO DIGITAL (cat. J 4901-5300 dos TXT):
-- nao e um avatar de catalogo: e um humano PROCEDURl com respiracao,
-- piscar, olhar-para-a-camera (atencao), deambular e balanco de bracos/pernas
-- por caminhada procedural. Vive no RRW como entidade de importancia ALTA
-- (D-O15 sobe o D dele antes de qualquer objeto inerte — regra da Tese dos D).

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")

local V3 = Vector3.new
local CF = CFrame.new

local DAYX = {}
local S = { humans = {}, t = 0 }

local SKIN = Color3.fromRGB(224, 182, 144)
local SKILL = Color3.fromRGB(206, 160, 120)

local function part(name, size, cf, color, shape, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = Enum.PartType.Ball end
	p.Parent = parent
	return p
end

function DAYX.spawn(opts)
	opts = opts or {}
	local seed = opts.seed or 7
	local rng = DM and DM.rng(seed) or math.random
	local pos = opts.pos or V3(0, 6, 0)
	local shirt = opts.shirt or Color3.fromRGB(40 + rng(140), 60 + rng(120), 140 + rng(90))
	local pants = Color3.fromRGB(44 + rng(30), 48 + rng(26), 66 + rng(30))

	local m = Instance.new("Model")
	m.Name = "DAYX_" .. (opts.name or ("humano_" .. seed))
	local rootCF = CF(pos)

	local torso = part("Torso", V3(2, 2.4, 1.1), rootCF * CF(0, 2.9, 0), shirt, nil, m)
	local head = part("Cabeca", V3(1.25, 1.25, 1.25), rootCF * CF(0, 4.85, 0), SKIN, true, m)
	local eyeL = part("OlhoL", V3(0.26, 0.26, 0.2), head.CFrame * CF(-0.3, 0.12, -0.58), Color3.fromRGB(250, 250, 250), true, m)
	local eyeR = part("OlhoR", V3(0.26, 0.26, 0.2), head.CFrame * CF(0.3, 0.12, -0.58), Color3.fromRGB(250, 250, 250), true, m)
	local pupL = part("PupL", V3(0.12, 0.12, 0.1), eyeL.CFrame * CF(0, 0, -0.09), Color3.fromRGB(30, 40, 60), true, m)
	local pupR = part("PupR", V3(0.12, 0.12, 0.1), eyeR.CFrame * CF(0, 0, -0.09), Color3.fromRGB(30, 40, 60), true, m)
	local mouth = part("Boca", V3(0.5, 0.1, 0.12), head.CFrame * CF(0, -0.3, -0.6), Color3.fromRGB(120, 50, 50), nil, m)
	local armL = part("BracoL", V3(0.62, 2.1, 0.7), rootCF * CF(-1.35, 2.9, 0), shirt, nil, m)
	local armR = part("BracoR", V3(0.62, 2.1, 0.7), rootCF * CF(1.35, 2.9, 0), shirt, nil, m)
	local legL = part("PernaL", V3(0.85, 2.1, 0.95), rootCF * CF(-0.5, 0.85, 0), pants, nil, m)
	local legR = part("PernaR", V3(0.85, 2.1, 0.95), rootCF * CF(0.5, 0.85, 0), pants, nil, m)
	m.PrimaryPart = torso
	m.Parent = workspace

	local h = {
		m = m, torso = torso, head = head, eyeL = eyeL, eyeR = eyeR,
		pupL = pupL, pupR = pupR, mouth = mouth,
		armL = armL, armR = armR, legL = legL, legR = legR,
		root = pos, target = pos + V3(rng(-14, 14), 0, rng(-14, 14)),
		blinkT = rng(1, 4), blink = 0, breathe = rng(0, 6),
		wanderT = rng(3, 8), walking = 0, phase = rng(0, 10),
		name = opts.name or ("humano_" .. seed),
	}
	S.humans[#S.humans + 1] = h

	-- RRW: importancia altissima — humanos digitais NUNCA caem pra "fundo"
	local RX = rawget(_G, "ArkherRealityX")
	if RX then
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				RX.register(d, { kind = "part", matter = "soil", importance = 0.95,
					parent = m, meta = { human = true, baseTransparency = 0 } })
			end
		end
	end
	return h
end

-- pump procedural: respiracao, piscar, olhar, andar, balancar
function DAYX.step(dt)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or V3(0, 10, 20)
	for _, h in ipairs(S.humans) do
		if not (h.m and h.m.Parent) then
			-- nada a fazer (objeto removido fora do motor)
		else
			h.breathe = h.breathe + dt
			-- respiracao: tronco sobe/desce 2cm a 0.25Hz (fisiologia real em repouso)
			local br = math.sin(h.breathe * math.pi * 2 * 0.25) * 0.02
			h.torso.Size = V3(2 * (1 + br), 2.4, 1.1 * (1 + br * 2))
			-- piscar: a cada 2-6s por 0.14s (fisiologia)
			h.blinkT = h.blinkT - dt
			if h.blinkT <= 0 then h.blinkT = math.max(1.2, (DM and DM.rng((h.breathe * 1000) % 997)() or 3)) + 1.4 h.blink = 0.14 end
			if h.blink > 0 then
				h.blink = h.blink - dt
				h.eyeL.Size, h.eyeR.Size = V3(0.26, 0.05, 0.2), V3(0.26, 0.05, 0.2)
			else
				h.eyeL.Size, h.eyeR.Size = V3(0.26, 0.26, 0.2), V3(0.26, 0.26, 0.2)
			end
			-- olhar-para-a-camera (atencao) quando perto
			local headPos = h.head.Position
			if (headPos - camPos).Magnitude < 60 then
				local look = CFrame.lookAt(headPos, V3(camPos.X, headPos.Y, camPos.Z))
				h.head.CFrame = look
				h.eyeL.CFrame = look * CF(-0.3, 0.12, -0.58)
				h.eyeR.CFrame = look * CF(0.3, 0.12, -0.58)
				h.pupL.CFrame = h.eyeL.CFrame * CF(0, 0, -0.09)
				h.pupR.CFrame = h.eyeR.CFrame * CF(0, 0, -0.09)
				h.mouth.CFrame = look * CF(0, -0.3, -0.6)
			end
			-- deambular com caminhada procedural
			h.wanderT = h.wanderT - dt
			if h.wanderT <= 0 and not h.mind then
				h.wanderT = 4 + (math.sin(h.phase * 7.3) + 1) * 3.5
				local rng = DM and DM.rng((h.phase * 100) % 99991 + 11)
				h.target = h.root + V3(rng(-18, 18), 0, rng(-18, 18))
			end
			local cur = h.m:GetPivot().Position
			local to = h.target - V3(cur.X, h.root.Y, cur.Z)
			local dist = V3(to.X, 0, to.Z).Magnitude
			if dist > 1.2 then
				h.walking = math.min(1, h.walking + dt * 4)
				local dir = V3(to.X, 0, to.Z).Unit
				local step = dir * math.min(dist, 2.2 * dt) * h.walking
				h.m:PivotTo((h.m:GetPivot() + step) * (CFrame.lookAt(V3(), dir) - V3()))
			else
				h.walking = math.max(0, h.walking - dt * 5)
			end
			-- balanco pendular de pernas/bracos quando andando (fisica de marcha)
			h.phase = h.phase + dt * (6 + 4 * h.walking)
			local sw = math.sin(h.phase * 2.4) * 0.5 * h.walking
			local base = h.m:GetPivot()
			local ab = base.Position
			h.legL.CFrame = base * CF(-0.5, 0.85, 0) * CFrame.Angles(sw, 0, 0)
			h.legR.CFrame = base * CF(0.5, 0.85, 0) * CFrame.Angles(-sw, 0, 0)
			h.armL.CFrame = base * CF(-1.35, 2.9, 0) * CFrame.Angles(-sw * 0.8, 0, 0)
			h.armR.CFrame = base * CF(1.35, 2.9, 0) * CFrame.Angles(sw * 0.8, 0, 0)
		end
	end
end

function DAYX.stats()
	return { humans = #S.humans }
end

-- entra no pulso universal do RRX (automatico)
do
	local RX = rawget(_G, "ArkherRealityX")
	if RX and RX.hook then RX.hook("dayx", function(dt) DAYX.step(dt) end) end
end

_G.ArkherDayX = DAYX
return DAYX
