--[[ ARKHER SCENE X (ASXN) — grafo de cena, query, SCATTER procedural e LOD ]]
-- O "organizador/montador" que o Roblox nao tem nativo: spatial-hash real,
-- query por classe/nome/atributo/regiao, PATINA (variacao sutil deterministica
-- de cor = anti-CG realista), SCATTER com amostragem Poisson-like no nosso
-- ATX (regras de bioma/declive/agua), biblioteca de vegetacao procedural
-- (arvores/arbustos/pedras/grama geradas como models reais), MERGE/EXPLODE,
-- alinhamento ARRAY, registro de assoc `LOD de distancia` cooperando com D-O15.
-- RRW: REPRESENTACAO (hash+regras) -> MATERIALIZACAO (models reais no mundo).
_G.ArkherSceneX = _G.ArkherSceneX or {}
local X = _G.ArkherSceneX
local DM = rawget(_G, "ArkherDM")
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
				if rawget(_G, "ArkherDO15") then
					local lv = rawget(_G, "ArkherDO15").state.level
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
return X
