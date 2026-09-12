-- CIVI X (CIVIX) — ASSENTAMENTOS PROCEDURAIS (cat. M 6701-7300 dos TXT):
-- vila / cidade / metropole REAIS: malha viaria + lotes + edificios
-- fabricados pelo FABX + praça + iluminacao + arvores — deterministico por
-- seed (mesmo DNA = mesma cidade), cada peca registrada no RRW.

local DM = rawget(_G, "ArkherDM")

local V3 = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles

local CIVIX = {}
local S = { made = 0, sets = {} }

local ROAD = Color3.fromRGB(46, 48, 54)

local function fab(kind, seed, pos, extra)
	local FAB = rawget(_G, "ArkherFabricX")
	if not FAB then return nil end
	local spec = { kind = kind, seed = seed }
	if extra then for k, v in pairs(extra) do spec[k] = v end end
	local res = FAB.fabricate(spec, { pos = pos })
	return res
end

local function road(name, cf, size, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = ROAD
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	local RX = rawget(_G, "ArkherRealityX")
	if RX then RX.register(p, { kind = "part", matter = "rock", importance = 0.6, meta = { road = true, baseTransparency = 0 } }) end
	return p
end

-- ============ VILA (praca circular + casas ao redor) ============
local function village(rng, cx, cz, parent)
	local n = 6 + math.floor(rng() * 5)
	fab("fonte", 1, V3(cx, 0, cz))
	for i = 1, n do
		local a = i / n * math.pi * 2
		local r = 16 + rng() * 6
		local px, pz = cx + math.cos(a) * r, cz + math.sin(a) * r
		fab("casa", 10 + i, V3(px, 0, pz))
		if i % 2 == 0 then fab("lampada", 30 + i, V3(px * 0.8 + cx * 0.2, 0, pz * 0.8 + cz * 0.2)) end
	end
	fab("cerca", 40, V3(cx, 0, cz + 20), { size = 14 })
	for i = 1, 4 do
		fab("arvore", 50 + i, V3(cx + rng(-24, 24), 0, cz + rng(-24, 24)))
	end
	road("EstradaVila", CF(cx, 0.12, cz - 30), V3(6, 0.24, 44), parent)
	return n + 8
end

-- ============ CIDADE (rua principal + comercio + praca) ============
local function town(rng, cx, cz, parent)
	local total = 0
	road("RuaPrincipal", CF(cx, 0.12, cz), V3(72, 0.24, 7), parent)
	road("RuaTravessa", CF(cx, 0.12, cz), V3(7, 0.24, 56), parent)
	total = total + 2
	for i = -3, 3 do
		if i ~= 0 then
			fab("casa", 100 + i * 2, V3(cx + i * 11, 0, cz - 9.5))
			fab("casa", 101 + i * 2, V3(cx + i * 11, 0, cz + 9.5))
			if (i % 2) == 0 then fab("lampada", 130 + i, V3(cx + i * 11, 0, cz - 4.6)) end
			total = total + 2 + ((i % 2) == 0 and 1 or 0)
		end
	end
	for j = -2, 2 do
		if j ~= 0 then
			fab("casa", 140 + j * 3, V3(cx - 9.5, 0, cz + j * 11))
			fab("casa", 141 + j * 3, V3(cx + 9.5, 0, cz + j * 11))
			total = total + 2
		end
	end
	fab("estatua", 150, V3(cx, 0.3, cz - 18))
	fab("fonte", 151, V3(cx, 0, cz + 18))
	total = total + 2
	return total
end

-- ============ METROPOLE (quadras + predios de alturas variadas) ============
local function city(rng, cx, cz, parent)
	local total = 0
	local bw, gap = 26, 8
	for gx = -2, 2 do
		road("AvX" .. gx, CF(cx + gx * (bw + gap), 0.12, cz), V3(6, 0.24, 5 * (bw + gap)), parent)
		total = total + 1
	end
	for gz = -2, 2 do
		road(("AvZ"):format(gz), CF(cx, 0.12, cz + gz * (bw + gap)), V3(5 * (bw + gap), 0.24, 6), parent)
		total = total + 1
	end
	for gx = -1, 1 do
		for gz = -1, 1 do
			local px = cx + gx * (bw + gap) + (bw / 2 + gap / 2)
			local pz = cz + gz * (bw + gap) + (bw / 2 + gap / 2)
			local seed = 200 + (gx + 2) * 7 + (gz + 2) * 13
			if rng() < 0.22 and not (gx == 0 and gz == 0) then
				fab("janela", seed, V3(px, 0, pz)) -- lote vazio em obra
				fab("cerca", seed + 1, V3(px, 0, pz), { size = 20 })
				total = total + 2
			elseif gx == 0 and gz == 0 then
				fab("fonte", seed, V3(px, 0, pz))
				for i = 1, 4 do fab("arvore", seed + i, V3(px + rng(-10, 10), 0, pz + rng(-10, 10))) end
				total = total + 5
			else
				fab("predio", seed, V3(px - 6, 0, pz - 6))
				fab("predio", seed + 1, V3(px + 6, 0, pz + 6))
				fab("lampada", seed + 2, V3(px, 0, pz))
				total = total + 3
			end
		end
	end
	return total
end

function CIVIX.fabricate(opts)
	opts = opts or {}
	local kind = tostring(opts.kind or "vila"):lower()
	local seed = tonumber(opts.seed) or 7
	local rng = DM and DM.rng(seed) or math.random
	local cx, cz = tonumber(opts.x) or 0, tonumber(opts.z) or -90
	local model = Instance.new("Model")
	model.Name = "CIV_" .. kind .. "_" .. seed
	model.Parent = workspace
	local pieces = 0
	if kind == "vila" or kind == "village" then pieces = village(rng, cx, cz, model)
	elseif kind == "metropole" or kind == "metropolis" or kind == "capital" then pieces = city(rng, cx, cz, model)
	else pieces = town(rng, cx, cz, model) end
	S.made = S.made + 1
	S.sets[#S.sets + 1] = model
	return { kind = kind, seed = seed, pieces = pieces, model = model }
end

function CIVIX.stats()
	return { settlements = S.made }
end

_G.ArkherCiviX = CIVIX
return CIVIX
