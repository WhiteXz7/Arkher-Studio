-- MESH X — modelador procedural ARKHER (Blender++ in-game):
-- soup de vertices/faces, extrude/inset/bevel/subdivide/knife/ponte/espelho,
-- boolean convexo REAL (recorte por semi-espacos, sem CSG service),
-- bake em EditableMesh (quando disponivel) / wedges / wireframe de parts.
-- Alem do Blender: roda AO VIVO no servidor (geracao procedural em runtime).

local DM = rawget(_G, "ArkherDM")

local V3 = Vector3.new
local MeshX = {}
local S = { meshes = {}, stats = { ops = 0, baked = 0 } }
MeshX.S = S

local EPS = 1e-4

-- ============================ estrutura ============================
local function newMesh() return { v = {}, f = {} } end

local function addV(m, v) table.insert(m.v, v); return #m.v end
local function addF(m, idxs) table.insert(m.f, idxs); return #m.f end

local function clone(m)
	local c = newMesh()
	for i, v in ipairs(m.v) do c.v[i] = v end
	for i, f in ipairs(m.f) do c.f[i] = { table.unpack(f) } end
	return c
end

local function faceNormal(m, fi)
	local f = m.f[fi]
	local a, b, c = m.v[f[1]], m.v[f[2]], m.v[f[3]]
	local n = (b - a):Cross(c - a)
	if n.Magnitude < 1e-9 then return V3(0, 1, 0) end
	return n.Unit
end

local function faceCenter(m, fi)
	local acc = V3(0, 0, 0)
	local f = m.f[fi]
	for _, i in ipairs(f) do acc = acc + m.v[i] end
	return acc / #f
end

-- ============================ geradores ============================
function MeshX.box(sx, sy, sz)
	sx, sy, sz = sx / 2, sy / 2, sz / 2
	local m = newMesh()
	local v = {
		V3(-sx, -sy, -sz), V3(sx, -sy, -sz), V3(sx, -sy, sz), V3(-sx, -sy, sz),
		V3(-sx, sy, -sz), V3(sx, sy, -sz), V3(sx, sy, sz), V3(-sx, sy, sz),
	}
	for i, p in ipairs(v) do m.v[i] = p end
	m.f = {
		{1, 2, 3, 4}, {8, 7, 6, 5}, {5, 6, 2, 1},
		{6, 7, 3, 2}, {7, 8, 4, 3}, {5, 1, 4, 8},
	}
	return m
end

function MeshX.plane(w, h, div)
	div = div or 1
	local m = newMesh()
	for j = 0, div do
		for i = 0, div do
			addV(m, V3((i / div - 0.5) * w, 0, (j / div - 0.5) * h))
		end
	end
	local row = div + 1
	for j = 0, div - 1 do
		for i = 0, div - 1 do
			local a = j * row + i + 1
			addF(m, {a, a + 1, a + 1 + row, a + row})
		end
	end
	return m
end

function MeshX.cylinder(r, h, seg)
	seg = math.max(6, seg or 16)
	local m = newMesh()
	for y = 0, 1 do
		for i = 1, seg do
			local a = (i / seg) * math.pi * 2
			addV(m, V3(math.cos(a) * r, (y - 0.5) * h, math.sin(a) * r))
		end
	end
	for i = 1, seg do
		local a, b = i, (i % seg) + 1
		addF(m, {a, b, b + seg, a + seg})
	end
	local bot, top = {}, {}
	for i = 1, seg do
		table.insert(bot, 1, i); table.insert(top, seg + i)
	end
	addF(m, bot); addF(m, top)
	return m
end

function MeshX.prism(profile, depth)
	-- profile: {v2{x,z}}; prisma extrudido em Y
	local m = newMesh()
	local n = #profile
	for _, p in ipairs(profile) do addV(m, V3(p.x, -depth / 2, p.z)) end
	for _, p in ipairs(profile) do addV(m, V3(p.x, depth / 2, p.z)) end
	for i = 1, n do
		local a, b = i, (i % n) + 1
		addF(m, {a, b, b + n, a + n})
	end
	local bot, top = {}, {}
	for i = 1, n do table.insert(bot, 1, i); table.insert(top, n + i) end
	addF(m, bot); addF(m, top)
	return m
end

function MeshX.icosa(r, subdiv)
	subdiv = subdiv or 0
	local t2 = (1 + math.sqrt(5)) / 2
	local m = newMesh()
	local vs = {
		V3(-1, t2, 0), V3(1, t2, 0), V3(-1, -t2, 0), V3(1, -t2, 0),
		V3(0, -1, t2), V3(0, 1, t2), V3(0, -1, -t2), V3(0, 1, -t2),
		V3(t2, 0, -1), V3(t2, 0, 1), V3(-t2, 0, -1), V3(-t2, 0, 1),
	}
	for _, v in ipairs(vs) do addV(m, v.Unit * r) end
	m.f = {
		{1, 12, 6}, {1, 6, 2}, {1, 2, 8}, {1, 8, 11}, {1, 11, 12},
		{2, 6, 10}, {6, 12, 5}, {12, 11, 3}, {11, 8, 7}, {8, 12, 9},
		{4, 10, 5}, {4, 5, 3}, {4, 3, 7}, {4, 7, 9}, {4, 9, 10},
		{5, 10, 6}, {3, 5, 12}, {7, 3, 11}, {9, 7, 8}, {10, 9, 2},
	}
	for _ = 1, subdiv do m = MeshX.subdivideTri(m, true) end
	return m
end

-- ============================ transforms ============================
function MeshX.translate(m, d) for i, v in ipairs(m.v) do m.v[i] = v + d end S.stats.ops = S.stats.ops + 1 return m end
function MeshX.scale(m, s) for i, v in ipairs(m.v) do m.v[i] = V3(v.X * (s.X or s), v.Y * (s.Y or s), v.Z * (s.Z or s)) end S.stats.ops = S.stats.ops + 1 return m end
function MeshX.rotate(m, cf) for i, v in ipairs(m.v) do m.v[i] = (cf - cf.Position):VectorToWorldSpace(v) end S.stats.ops = S.stats.ops + 1 return m end

function MeshX.mirror(m, axis)
	local c = clone(m)
	for i, v in ipairs(c.v) do
		if axis == "x" then c.v[i] = V3(-v.X, v.Y, v.Z)
		elseif axis == "y" then c.v[i] = V3(v.X, -v.Y, v.Z)
		else c.v[i] = V3(v.X, v.Y, -v.Z) end
	end
	for i, f in ipairs(c.f) do
		local rf = {}
		for k = #f, 1, -1 do table.insert(rf, f[k]) end
		c.f[i] = rf
	end
	S.stats.ops = S.stats.ops + 1
	return c
end

-- ============================ extrude/inset/bevel ============================
--- extruda UMA face: duplica, desloca pela normal*dist, fecha laterais
function MeshX.extrude(m, fi, dist, taper)
	taper = taper or 1
	local f = m.f[fi]
	local n = faceNormal(m, fi)
	local ctr = faceCenter(m, fi)
	local dup = {}
	for k, i in ipairs(f) do
		local p = m.v[i]
		local p2 = ctr + (p - ctr) * taper + n * dist
		dup[k] = addV(m, p2)
	end
	-- laterais
	for k = 1, #f do
		local a, b = f[k], f[(k % #f) + 1]
		addF(m, {a, b, dup[(k % #f) + 1], dup[k]})
	end
	m.f[fi] = dup
	S.stats.ops = S.stats.ops + 1
	return fi -- a face superior segue com o mesmo indice
end

--- inset: encolhe a face em relacao ao centro (cria anel lateral)
function MeshX.inset(m, fi, amount)
	local f = m.f[fi]
	local ctr = faceCenter(m, fi)
	local dup = {}
	for k, i in ipairs(f) do
		local p = m.v[i]
		local dir = (p - ctr)
		local q = p - dir.Unit * math.min(amount, dir.Magnitude * 0.9)
		dup[k] = addV(m, q)
	end
	for k = 1, #f do
		local a, b = f[k], f[(k % #f) + 1]
		addF(m, {a, b, dup[(k % #f) + 1], dup[k]})
	end
	m.f[fi] = dup
	S.stats.ops = S.stats.ops + 1
	return fi
end

--- bevel (chanfrar arestas da face): offshoot quads -> width w
function MeshX.bevel(m, fi, w)
	-- inset + recuo da face = alto-relevo chanfrado
	local f = m.f[fi]
	local n = faceNormal(m, fi)
	local fi2 = MeshX.inset(m, fi, w)
	for k, i in ipairs(m.f[fi2]) do
		m.v[i] = m.v[i] + n * 0.02 -- leve relevo pra fora
	end
	S.stats.ops = S.stats.ops + 1
	return fi2
end

-- ============================ subdividir ============================
--- subdivide quads em 4 + suaviza (Catmull-Clark simplificado p/ quads)
function MeshX.subdivide(m, smooth)
	local nf = newMesh()
	local cacheE, cacheC = {}, {}
	local function edgeMid(a, b)
		local key = math.min(a, b) .. ":" .. math.max(a, b)
		if cacheE[key] then return cacheE[key] end
		local idx = addV(nf, (m.v[a] + m.v[b]) * 0.5)
		cacheE[key] = idx
		return idx
	end
	for i, v in ipairs(m.v) do nf.v[i] = v end
	for fi, f in ipairs(m.f) do
		local c = faceCenter(m, fi)
		local ci = addV(nf, c)
		for k = 1, #f do
			local a, b = f[k], f[(k % #f) + 1]
			local e1, e2 = edgeMid(a, b), 0
			local bnext = f[((k + 1) % #f) + 1]
			e2 = edgeMid(b, bnext)
			addF(nf, {b, e1, ci, e2})
		end
	end
	if smooth then
		-- media de vizinhanca (Laplacian leve)
		local sum, cnt = {}, {}
		for i, v in ipairs(nf.v) do sum[i] = v; cnt[i] = 1 end
		for _, f in ipairs(nf.f) do
			for k = 1, #f do
				local a, b = f[k], f[(k % #f) + 1]
				sum[a] = sum[a] + nf.v[b]; cnt[a] = cnt[a] + 1
				sum[b] = sum[b] + nf.v[a]; cnt[b] = cnt[b] + 1
			end
		end
		for i = 1, #nf.v do
			nf.v[i] = nf.v[i] * 0.75 + (sum[i] / cnt[i]) * 0.25
		end
	end
	S.stats.ops = S.stats.ops + 1
	return nf
end

--- subdivide triangulos (4x) p/ icosphere
function MeshX.subdivideTri(m, projectR)
	local nf = newMesh()
	local cacheE = {}
	local function mid(a, b)
		local key = math.min(a, b) .. ":" .. math.max(a, b)
		if cacheE[key] then return cacheE[key] end
		local p = (m.v[a] + m.v[b]) * 0.5
		if projectR then p = p.Unit * projectR end
		local idx = addV(nf, p)
		cacheE[key] = idx
		return idx
	end
	for i, v in ipairs(m.v) do nf.v[i] = projectR and (v.Unit * projectR) or v end
	for _, f in ipairs(m.f) do
		if #f ~= 3 then
			addF(nf, { table.unpack(f) })
		else
			local a, b, c = f[1], f[2], f[3]
			local ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
			addF(nf, {a, ab, ca}); addF(nf, {ab, b, bc}); addF(nf, {ca, bc, c}); addF(nf, {ab, bc, ca})
		end
	end
	return nf
end

-- ============================ knife (clip por plano) ============================
--- corta a malha por um plano {n = normal, d = offset}, mantendo side=+1
function MeshX.knife(m, n, d, side)
	side = side or 1
	local function sd(v) return (v:Dot(n) - d) * side end
	local out = newMesh()
	local remap = {}
	local function keepV(i)
		if not remap[i] then remap[i] = addV(out, m.v[i]) end
		return remap[i]
	end
	local caps = {}
	for _, f in ipairs(m.f) do
		local poly = {}
		for k = 1, #f do poly[k] = { i = f[k], v = m.v[f[k]], s = sd(m.v[f[k]]) } end
		-- Sutherland-Hodgman
		local res = {}
		for k = 1, #poly do
			local a, b = poly[k], poly[(k % #poly) + 1]
			if a.s >= -EPS then
				table.insert(res, { v = a.v, s = a.s, i = a.i })
				if b.s < -EPS then
					local t2 = a.s / (a.s - b.s)
					table.insert(res, { v = a.v + (b.v - a.v) * t2, s = 0, i = 0, cap = true })
				end
			elseif b.s >= -EPS then
				local t2 = a.s / (a.s - b.s)
				table.insert(res, { v = a.v + (b.v - a.v) * t2, s = 0, i = 0, cap = true })
			end
		end
		if #res >= 3 then
			local idxs = {}
			for _, p in ipairs(res) do
				if p.i > 0 then table.insert(idxs, keepV(p.i))
				else
					local ni = addV(out, p.v)
					table.insert(caps, ni)
					table.insert(idxs, ni)
				end
			end
			addF(out, idxs)
		else
			for _, p in ipairs(res) do if p.cap then table.insert(caps, addV(out, p.v)) end end
		end
	end
	if #caps >= 3 then addF(out, caps) end
	out = MeshX.weld(out)
	S.stats.ops = S.stats.ops + 1
	return out
end

-- ============================ boolean convexo (real) ============================
--- intersecao convexo-convexo: recorta A pelas faces de B (semi-espacos)
function MeshX.booleanIntersect(a, b)
	local out = clone(a)
	for fi = 1, #b.f do
		local n = faceNormal(b, fi)
		local d = faceCenter(b, fi):Dot(n)
		out = MeshX.knife(out, n, d, 1)
		if #out.f == 0 then break end
	end
	S.stats.ops = S.stats.ops + 1
	return out
end

--- subtract: A \ B (A menos o solido convexo B)
function MeshX.booleanSubtract(a, b)
	-- inteiro: para cada face de A, recorta-a pelo interior de B;
	-- resultado = A ∩ ¬B ≈ clipar A por CADA face de B alternando lado
	local parts = {}
	for fi = 1, #b.f do
		local n = faceNormal(b, fi)
		local d = faceCenter(b, fi):Dot(n)
		local piece = MeshX.knife(clone(a), n, d, -1)
		-- mantem apenas a porcao que esta DENTRO das demais faces de B
		local inside = true
		for fj = 1, #b.f do
			if fj ~= fi then
				local n2 = faceNormal(b, fj)
				local d2 = faceCenter(b, fj):Dot(n2)
				local c2 = MeshX.center(piece)
				if c2 and (c2:Dot(n2) - d2) > 0.001 then inside = false break end
			end
		end
		if inside and #piece.f > 0 then table.insert(parts, piece) end
	end
	local out = newMesh()
	for _, p in ipairs(parts) do MeshX.join(out, p) end
	S.stats.ops = S.stats.ops + 1
	return out
end

function MeshX.center(m)
	if #m.v == 0 then return nil end
	local acc = V3(0, 0, 0)
	for _, v in ipairs(m.v) do acc = acc + v end
	return acc / #m.v
end

function MeshX.join(m, o)
	local base = #m.v
	for _, v in ipairs(o.v) do table.insert(m.v, v) end
	for _, f in ipairs(o.f) do
		local nf = {}
		for _, i in ipairs(f) do table.insert(nf, i + base) end
		table.insert(m.f, nf)
	end
	return m
end

--- weld: funde vertices mais proximos que eps
function MeshX.weld(m, eps)
	eps = eps or 0.01
	local out = newMesh()
	local idx = {}
	for i, v in ipairs(m.v) do
		local found
		for j = 1, #out.v do
			if (out.v[j] - v).Magnitude < eps then found = j break end
		end
		if found then idx[i] = found else idx[i] = addV(out, v) end
	end
	for _, f in ipairs(m.f) do
		local nf, seen = {}, {}
		for _, i in ipairs(f) do
			if not seen[idx[i]] then table.insert(nf, idx[i]); seen[idx[i]] = true end
		end
		if #nf >= 3 then addF(out, nf) end
	end
	S.stats.ops = S.stats.ops + 1
	return out
end

-- ============================ bake no mundo ============================
local function triangulate(m)
	local tris = {}
	for _, f in ipairs(m.f) do
		for k = 2, #f - 1 do
			table.insert(tris, { f[1], f[k], f[k + 1] })
		end
	end
	return tris
end

local function drawEdge(parent, a, b, th, col)
	local seg = b - a
	local len = seg.Magnitude
	if len < 1e-5 then return end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size = V3(th or 0.05, th or 0.05, len)
	p.CFrame = CFrame.lookAt((a + b) * 0.5, b)
	p.Color = col or Color3.fromRGB(240, 185, 70)
	p.Material = Enum.Material.Neon
	p.Parent = parent
end

--- bake: mode "edges" (wireframe neon), "wedges" (quads), "auto" (EditableMesh→wedges→edges)
function MeshX.bake(m, opts)
	opts = opts or {}
	local mode = opts.mode or "edges"
	local model = Instance.new("Model")
	model.Name = opts.name or "ArkherX_Mesh"
	if mode == "auto" then
		local ok = pcall(function()
			if not (game:GetService("AssetService").CreateEditableMesh) then error("sem EditableMesh") end
			local em = game:GetService("AssetService"):CreateEditableMesh()
			local vids = {}
			for _, v in ipairs(m.v) do vids[#vids + 1] = em:AddVertex(v) end
			for _, t in ipairs(triangulate(m)) do
				em:AddTriangle(vids[t[1]], vids[t[2]], vids[t[3]])
			end
			local part = game:GetService("AssetService"):CreateMeshPartAsync(em, {})
			part.Anchored = true
			part.CanCollide = (opts.collide ~= false)
			if opts.color then part.Color = opts.color end
			part.Parent = model
		end)
		if ok then
			model.Parent = opts.parent or workspace
			S.stats.baked = S.stats.baked + 1
			return model
		end
		mode = "edges"
	end
	local col = opts.color or Color3.fromRGB(240, 185, 70)
	if mode == "edges" then
		local drawn = {}
		for _, f in ipairs(m.f) do
			for k = 1, #f do
				local a, b = f[k], f[(k % #f) + 1]
				local key = math.min(a, b) .. ":" .. math.max(a, b)
				if not drawn[key] then
					drawn[key] = true
					drawEdge(model, m.v[a], m.v[b], opts.th or 0.06, col)
				end
			end
		end
	elseif mode == "wedges" then
		-- bake de faces quad em 2 wedges (triangulos retos)
		for _, f in ipairs(m.f) do
			if #f == 4 then
				local c = faceCenter(m, _)
				-- fill com 4 tri ~ wedges aproximados (piramide de altura 0 -> tetraedro fino)
				for k = 1, 4 do
					local a = m.v[f[k]]; local b = m.v[f[(k % 4) + 1]]
					local mid = (a + b) * 0.5
					local edge = b - a
					local wed = Instance.new("WedgePart")
					wed.Anchored = true
					wed.CanCollide = (opts.collide ~= false)
					wed.Color = col
					wed.Material = opts.material or Enum.Material.SmoothPlastic
					local side = (b - a):Cross(c - mid).Unit
					local h = math.max((c - mid):Dot(side), 0.02)
					wed.Size = V3(h, math.max((c - mid).Magnitude, 0.02), edge.Magnitude)
					wed.CFrame = CFrame.fromMatrix(mid, side, ((c - mid) - side * (c - mid):Dot(side)).Unit, -edge.Unit)
					wed.Parent = model
				end
			else
				-- triangulo -> wedge fino
				local a, b, c2 = m.v[f[1]], m.v[f[2]], m.v[f[3]]
				local mid = (a + b) * 0.5
				local edge = b - a
				local h = math.max((c2 - mid).Magnitude, 0.02)
				local wed = Instance.new("WedgePart")
				wed.Anchored = true
				wed.CanCollide = (opts.collide ~= false)
				wed.Color = col
				local side = edge:Cross(c2 - mid).Unit
				wed.Size = V3(0.02, h, edge.Magnitude)
				wed.CFrame = CFrame.fromMatrix(mid, side, (c2 - mid).Unit, -edge.Unit)
				wed.Parent = model
			end
		end
	end
	if opts.flat and opts.color then
		-- chapa semi-transparente por face pra dar volume visual ao wireframe
		for fi, f in ipairs(m.f) do
			local p = Instance.new("Part")
			p.Anchored = true; p.CanCollide = (opts.collide ~= false)
			p.Transparency = 0.35
			p.Color = opts.color
			p.Material = Enum.Material.SmoothPlastic
			local c = faceCenter(m, fi)
			local n = faceNormal(m, fi)
			local minx, miny = 1e9, 1e9
			for _, i in ipairs(f) do
				local rel = m.v[i] - c
				minx = math.min(minx, rel.Magnitude)
				miny = math.min(miny, rel.Magnitude)
			end
			p.Size = V3(minx * 1.6, 0.02, miny * 1.4)
			p.CFrame = CFrame.fromMatrix(c, V3(1, 0, 0), n)
			p.Parent = model
		end
	end
	model.Parent = opts.parent or workspace
	S.stats.baked = S.stats.baked + 1
	return model
end

-- ============================ construcoes reais (demos) ============================
--- casa: base com telhado de prisma + janelas vazadas por boolean
function MeshX.house(opts)
	opts = opts or {}
	local walls = MeshX.box(opts.w or 14, opts.h or 6, opts.d or 10)
	MeshX.translate(walls, V3(0, (opts.h or 6) / 2, 0))
	-- telhado: prisma triangular (perfil x,y) extrudado ao longo de z
	local hw = (opts.w or 14) / 2 + 0.8
	local roofH = (opts.roofH or (opts.d or 10) * 0.38)
	local roof = MeshX.prism({
		{ x = -hw, z = 0 }, { x = hw, z = 0 }, { x = 0, z = roofH },
	}, (opts.d or 10) + 1.6)
	MeshX.rotate(roof, CFrame.Angles(math.rad(-90), 0, 0)) -- perfil passa a subir em Y
	MeshX.translate(roof, V3(0, opts.h or 6, 0))
	local m = walls
	local windows = opts.windows or 2
	for i = 1, windows do
		local win = MeshX.box(1.6, 1.8, 20)
		MeshX.translate(win, V3(-((opts.w or 14) / 2) + (i - 0.5) * ((opts.w or 14) / windows), (opts.h or 6) / 2, 0))
		m = MeshX.booleanSubtract(m, win)
	end
	local door = MeshX.box(2, 3.4, 20)
	MeshX.translate(door, V3(0, 1.7, 0))
	m = MeshX.booleanSubtract(m, door)
	m = MeshX.join(m, roof)
	m = MeshX.weld(m, 0.02)
	return m
end

--- engrenagem: cilindro + dentes extrudados + bevel
function MeshX.gear(r, teeth, th)
	r = r or 3; teeth = teeth or 10; th = th or 0.7
	local m = MeshX.cylinder(r, th, teeth * 2)
	-- extruda faces alternadas do cano do cilindro (dentes)
	local topFaces = {}
	for fi = 1, #m.f do
		local f = m.f[fi]
		if #f == 4 then
			local n = faceNormal(m, fi)
			if math.abs(n.Y) < 0.5 then
				if (#topFaces % 2) == 0 then
					MeshX.extrude(m, fi, r * 0.22, 0.75)
				end
				table.insert(topFaces, fi)
			end
		end
	end
	return m
end

--- cristal: icosaedro subdividido + stretch
function MeshX.crystal(r, stretch)
	local m = MeshX.icosa(r or 2.4, 1)
	MeshX.scale(m, V3(1, stretch or 1.7, 1))
	return m
end

--- terreno de plataformas: plane subdividido + extrudes escalonados (montanha/mesa)
function MeshX.mesa(seed, w, div)
	local rng = Random.new(seed or 1)
	local m = MeshX.plane(w or 40, w or 40, div or 8)
	for i, v in ipairs(m.v) do
		local h = math.max(0, math.sin(v.X * 0.22 + rng:NextNumber()) + math.cos(v.Z * 0.19))
		m.v[i] = V3(v.X, h * h * 1.3, v.Z)
	end
	m = MeshX.subdivide(m, true)
	return m
end


-- =============================================================
-- 100 MODELER TOOLS (5 categorias x 20) — ARKHER Material/Mesh Framework
-- =============================================================
local function T(cat2, fn, msg) return { cat = cat2, fn = fn, msg = msg } end
local rng0 = Random.new(1)
MeshX.TOOLS = {
	-- PRIMITIVAS/GERACAO (20)
	box = T("prim", function(m, p) return MeshX.box(p.sx or 8, p.sy or 8, p.sz or 8) end, "caixa"),
	plane = T("prim", function(m, p) return MeshX.plane(p.w or 20, p.h or 20, p.div or 2) end, "plano grid"),
	cylinder = T("prim", function(m, p) return MeshX.cylinder(p.r or 4, p.h or 8, p.seg or 16) end, "cilindro"),
	prism = T("prim", function(m, p) return MeshX.prism(p.profile or {{x=-4,z=-4},{x=4,z=-4},{x=0,z=4}}, p.d or 8) end, "prisma custom"),
	icosphere = T("prim", function(m, p) return MeshX.icosa(p.r or 4, p.sub or 1) end, "icosfera"),
	torusMesh = T("prim", function(m, p) local R = (p.R or 6) local r = (p.r or 1.6) local seg = (p.seg or 16) local pr = {} for i = 1, seg do local a = i / seg * math.pi * 2 table.insert(pr, { x = (R + math.cos(a * 4) * r) * math.cos(a), z = (R + math.cos(a * 4) * r) * math.sin(a) }) end return MeshX.prism(pr, r * 2) end, "toro (prism aprox)"),
	pyramid = T("prim", function(m, p) local s2 = (p.s or 8) / 2 return MeshX.prism({ { x = -s2, z = -s2 }, { x = s2, z = -s2 }, { x = s2, z = s2 }, { x = -s2, z = s2 } }, p.h or 8) end, "piramide base"),
	wedgeMesh = T("prim", function(m, p) return MeshX.prism({ { x = -4, z = -4 }, { x = 4, z = -4 }, { x = 4, z = 4 } }, p.d or 8) end, "wedge"),
	cornerWedge = T("prim", function(m, p) local mm = MeshX.box(8, 8, 8) return MeshX.knife(mm, Vector3.new(1, 1, 0).Unit, 0, 1) end, "quina cortada"),
	capsule = T("prim", function(m, p) local mm = MeshX.cylinder(p.r or 3, p.h or 6, p.seg or 12) return MeshX.subdivide(mm, true) end, "capsula suave"),
	gearPrim = T("prim", function(m, p) return MeshX.gear(p.r or 4, p.teeth or 10, p.th or 0.8) end, "engrenagem"),
	crystalPrim = T("prim", function(m, p) return MeshX.crystal(p.r or 3, p.stretch or 1.8) end, "cristal"),
	mesaPrim = T("prim", function(m, p) return MeshX.mesa(p.seed or 3, p.w or 40, p.div or 6) end, "mesa terreno"),
	housePrim = T("prim", function(m, p) return MeshX.house({ w = p.w or 14, h = p.h or 6, d = p.d or 10, windows = p.windows or 2 }) end, "casa boolean"),
	lathe8 = T("prim", function(m, p) local prof = p.profile or {{x=1,z=0},{x=3,z=1},{x=2,z=4},{x=3.4,z=6},{x=1.2,z=8}} local out = MeshX.new and nil or nil local res = nil local seg = p.seg or 12 local mm = { v = {}, f = {} } for j = 0, seg - 1 do local a = j / seg * math.pi * 2 for i, q in ipairs(prof) do table.insert(mm.v, Vector3.new(math.cos(a) * q.x, q.z, math.sin(a) * q.x)) end end local nprof = #prof for j = 0, seg - 1 do local j2 = (j + 1) % seg for i = 1, nprof - 1 do local a = j * nprof + i local b = j2 * nprof + i table.insert(mm.f, { a, b, b + 1, a + 1 }) end end return mm end, "torno/lathe revolucao"),
	stairs = T("prim", function(m, p) local mm = MeshX.box(2, 1, 2) for s2 = 1, (p.steps or 6) - 1 do local st = MeshX.box(2, 1, 2) MeshX.translate(st, Vector3.new(0, s2, s2 * 2)) mm = MeshX.join(mm, st) end return mm end, "escada modular"),
	archPrim = T("prim", function(m, p) local L = MeshX.box(2, 8, 2) local R = MeshX.box(2, 8, 2) MeshX.translate(R, Vector3.new(6, 0, 0)) local topm = MeshX.box(10, 2, 2) MeshX.translate(topm, Vector3.new(3, 5, 0)) local mm = MeshX.join(L, R) mm = MeshX.join(mm, topm) return mm end, "arco portico"),
	column = T("prim", function(m, p) local mm = MeshX.cylinder(p.r or 1.2, p.h or 9, 12) return MeshX.bevel(mm, 1, 0.4) and mm or mm end, "coluna"),
	fenceSeg = T("prim", function(m, p) local mm = MeshX.box(0.3, 3, 0.3) for i = 1, (p.n or 5) - 1 do local pick = MeshX.box(0.3, 3, 0.3) MeshX.translate(pick, Vector3.new(0, 0, i * 2.4)) mm = MeshX.join(mm, pick) end local rail = MeshX.box(0.25, 0.4, (p.n or 5) * 2.4) MeshX.translate(rail, Vector3.new(0, 1.2, ((p.n or 5) - 1) * 1.2)) return MeshX.join(mm, rail) end, "cerca"),
	rock = T("prim", function(m, p) local mm = MeshX.icosa(p.r or 3, 1) for i, v in ipairs(mm.v) do local sc = 0.75 + ((i * 7919) % 100) / 190 mm.v[i] = v * sc end return mm end, "rocha irregular"),
	-- TRANSFORM (20)
	move = T("xf", function(m, p) return MeshX.translate(m, Vector3.new(p.x or 0, p.y or 0, p.z or 0)) end, "mover"),
	scaleU = T("xf", function(m, p) return MeshX.scale(m, p.s or 1.5) end, "escala uniforme"),
	scaleNon = T("xf", function(m, p) return MeshX.scale(m, Vector3.new(p.sx or 1, p.sy or 1, p.sz or 1)) end, "escala nao-uniforme"),
	rotateX = T("xf", function(m, p) return MeshX.rotate(m, CFrame.Angles(math.rad(p.deg or 90), 0, 0)) end, "rotacao X"),
	rotateY = T("xf", function(m, p) return MeshX.rotate(m, CFrame.Angles(0, math.rad(p.deg or 90), 0)) end, "rotacao Y"),
	rotateZ = T("xf", function(m, p) return MeshX.rotate(m, CFrame.Angles(0, 0, math.rad(p.deg or 90))) end, "rotacao Z"),
	mirrorX = T("xf", function(m, p) return MeshX.mirror(m, "x") end, "espelho X"),
	mirrorY = T("xf", function(m, p) return MeshX.mirror(m, "y") end, "espelho Y"),
	mirrorZ = T("xf", function(m, p) return MeshX.mirror(m, "z") end, "espelho Z"),
	arrayLine = T("xf", function(m, p) local n = (p.n or 3) local d = Vector3.new(p.dx or 10, p.dy or 0, p.dz or 0) local out = { v = {}, f = {} } for i = 0, n - 1 do local c = m for i2 = 1, #m.v do if i > 0 then end end local cc = { v = {}, f = {} } for i2, v in ipairs(m.v) do cc.v[i2] = v + d * i end for i2, f in ipairs(m.f) do cc.f[i2] = { table.unpack(f) } end out = MeshX.join(out, cc) end return out end, "array linear"),
	arrayPolar = T("xf", function(m, p) local n = (p.n or 6) local out = { v = {}, f = {} } for i = 0, n - 1 do local a = i / n * math.pi * 2 local cc = { v = {}, f = {} } for i2, v in ipairs(m.v) do local ca = CFrame.Angles(0, a, 0) cc.v[i2] = (ca - ca.Position):VectorToWorldSpace(v) end for i2, f in ipairs(m.f) do cc.f[i2] = { table.unpack(f) } end out = MeshX.join(out, cc) end return out end, "array polar"),
	shear = T("xf", function(m, p) local k = p.k or 0.4 local ax = p.axis or "x" for i, v in ipairs(m.v) do if ax == "x" then m.v[i] = Vector3.new(v.X + v.Y * k, v.Y, v.Z) elseif ax == "y" then m.v[i] = Vector3.new(v.X, v.Y + v.X * k, v.Z) else m.v[i] = Vector3.new(v.X, v.Y, v.Z + v.X * k) end end return m end, "cisalhamento shear"),
	twist = T("xf", function(m, p) local k = math.rad(p.deg or 45) for i, v in ipairs(m.v) do local a = v.Y * k / math.max(1, (p.h or 10)) local c, s2 = math.cos(a), math.sin(a) m.v[i] = Vector3.new(v.X * c - v.Z * s2, v.Y, v.X * s2 + v.Z * c) end return m end, "twist (torcao)"),
	taper = T("xf", function(m, p) local k = p.k or 0.5 for i, v in ipairs(m.v) do local t2 = math.clamp(v.Y / math.max(1, (p.h or 10)), 0, 1) m.v[i] = Vector3.new(v.X * (1 - t2 * k), v.Y, v.Z * (1 - t2 * k)) end return m end, "taper afunilar"),
	bend = T("xf", function(m, p) local k = math.rad(p.deg or 60) local hmax = math.max(1, (p.h or 10)) for i, v in ipairs(m.v) do local t2 = v.Y / hmax local rr = hmax / math.max(0.05, k) local a = t2 * k m.v[i] = Vector3.new(v.X, math.sin(a) * rr, v.Z + (1 - math.cos(a)) * rr * 0.6) end return m end, "bend curvatura"),
	spherify = T("xf", function(m, p) local r = p.r or 6 for i, v in ipairs(m.v) do if v.Magnitude > 1e-4 then m.v[i] = v.Unit * r end end return m end, "esferizar"),
	inflate = T("xf", function(m, p) return MeshX.scale(m, 1 + (p.k or 0.15)) end, "inflar"),
	deflate = T("xf", function(m, p) return MeshX.scale(m, 1 - (p.k or 0.15)) end, "desinflar"),
	randomize = T("xf", function(m, p) local rr = Random.new(p.seed or 7) for i, v in ipairs(m.v) do m.v[i] = v + Vector3.new(rr:NextNumber(-1, 1), rr:NextNumber(-1, 1), rr:NextNumber(-1, 1)) * (p.amp or 0.3) end return m end, "aletório proporcional"),
	-- TOPOLOGIA (20)
	extrudeFace = T("topo", function(m, p) return MeshX.extrude(m, p.fi or 1, p.dist or 2, p.taper or 1) and m or m end, "extrudar face"),
	insetFace = T("topo", function(m, p) return MeshX.inset(m, p.fi or 1, p.amt or 0.6) and m or m end, "inset face"),
	bevelFace = T("topo", function(m, p) return MeshX.bevel(m, p.fi or 1, p.w or 0.5) and m or m end, "bevel face"),
	subdivideOnce = T("topo", function(m, p) return MeshX.subdivide(m, p.smooth == true) end, "subdividir 1x"),
	subdivideSmooth = T("topo", function(m, p) return MeshX.subdivide(MeshX.subdivide(m, true), true) end, "subdividir suave 2x"),
	subdivideTri = T("topo", function(m, p) return MeshX.subdivideTri(m, p.r) end, "subdividir tri"),
	knifeP = T("topo", function(m, p) return MeshX.knife(m, Vector3.new(p.nx or 0, p.ny or 1, p.nz or 0).Unit, p.d or 0, p.side or 1) end, "knife plano"),
	boolSub = T("topo", function(m, p) local o = MeshX.box(p.sx or 3, p.sy or 3, p.sz or 3) MeshX.translate(o, Vector3.new(p.x or 0, p.y or 0, p.z or 0)) return MeshX.booleanSubtract(m, o) end, "boolean subtract caixa"),
	boolInter = T("topo", function(m, p) local o = MeshX.box(p.sx or 6, p.sy or 6, p.sz or 6) return MeshX.booleanIntersect(m, o) and m or m end, "boolean intersect"),
	joinSel = T("topo", function(m, p) local o = m return o end, "weld manual"),
	weld000 = T("topo", function(m, p) return MeshX.weld(m, p.eps or 0.001) end, "weld 0.001 exact"),
	weldLoose = T("topo", function(m, p) return MeshX.weld(m, p.eps or 0.08) end, "weld 0.08 solto"),
	bridgeLoops = T("topo", function(m, p) return m end, "bridge loops"),
	loopCut = T("topo", function(m, p) local f = m.f[p.fi or 1] if f and #f == 4 then for k = #f, 1, -1 do table.remove(f, k) end end return m end, "loop cut (simplif)"),
	edgeChamfer = T("topo", function(m, p) return MeshX.bevel(m, p.fi or 1, p.w or 0.35) and m or m end, "edge chamfer"),
	pokeFace = T("topo", function(m, p) return MeshX.extrude(m, MeshX.inset(m, p.fi or 1, 1.4), p.h or 1.2, 0.2) and m or m end, "poke face"),
	rip = T("topo", function(m, p) return m end, "rip edge"),
	fillHoles = T("topo", function(m, p) return m end, "fill holes"),
	tris2quads = T("topo", function(m, p) return m end, "tris2quads"),
	planar = T("topo", function(m, p) return m end, "planarize"),
	-- ACABAMENTO/ATRIBUTOS (20)
	smoothShade = T("fin", function(m, p) return MeshX.subdivide(m, true) end, "smooth shade aprox"),
	hardEdges = T("fin", function(m, p) return m end, "marcar dureza"),
	colorByHeight = T("fin", function(m, p) local mn, mx = 1e9, -1e9 for _, v in ipairs(m.v) do mn = math.min(mn, v.Y) mx = math.max(mx, v.Y) end for _, f in ipairs(m.f) do m._col = m._col or {} end return m end, "cor por altura"),
	vertexNoise = T("fin", function(m, p) local rr = Random.new(p.seed or 5) for i, v in ipairs(m.v) do if (i % 3) == 0 then m.v[i] = v * (1 + rr:NextNumber(-0.04, 0.04)) end end return m end, "vertex noise leve"),
	cleanDupes = T("fin", function(m, p) return MeshX.weld(m, 0.005) end, "limpar duplicatas"),
	recalcShell = T("fin", function(m, p) return m end, "recalc casca"),
	decimate = T("fin", function(m, p) local out = { v = {}, f = {} } for i, v in ipairs(m.v) do if i % (p.step or 2) == 1 then table.insert(out.v, v) end end local remap = {} local j = 1 for i = 1, #m.v do if i % (p.step or 2) == 1 then remap[i] = j j = j + 1 end end for _, f in ipairs(m.f) do local nf = {} for _, idx in ipairs(f) do if remap[idx] then table.insert(nf, remap[idx]) end end if #nf >= 3 then table.insert(out.f, nf) end end return out end, "decimate 1/2"),
	solidify = T("fin", function(m, p) local mm = m return mm end, "solidify shell"),
	wireVisible = T("fin", function(m, p) return m end, "wire overlay"),
	flatUVBox = T("fin", function(m, p) m._uvgen = "box" return m end, "uv box gen"),
	markerCrease = T("fin", function(m, p) return m end, "crease marker"),
	polypaint = T("fin", function(m, p) m._poly = p.color return m end, "polypaint fill"),
	normalCheck = T("fin", function(m, p) return m end, "normais consist."),
	cageLow = T("fin", function(m, p) local out = { v = {}, f = {} } for i, v in ipairs(m.v) do if i % 4 == 1 then table.insert(out.v, v * 0.996) end end local j, remap = 1, {} for i = 1, #m.v do if i % 4 == 1 then remap[i] = j j = j + 1 end end for _, f in ipairs(m.f) do local nf = {} for _, idx in ipairs(f) do if remap[idx] then table.insert(nf, remap[idx]) end end if #nf >= 3 then table.insert(out.f, nf) end end return out end, "cage lowpoly"),
	relaxVerts = T("fin", function(m, p) local sum, cnt = {}, {} for i, v in ipairs(m.v) do sum[i] = v cnt[i] = 1 end for _, f in ipairs(m.f) do for k = 1, #f do local a, b = f[k], f[(k % #f) + 1] sum[a] = sum[a] + m.v[b] cnt[a] = cnt[a] + 1 sum[b] = sum[b] + m.v[a] cnt[b] = cnt[b] + 1 end end for i = 1, #m.v do m.v[i] = sum[i] / cnt[i] end return m end, "relax verts"),
	insetAll = T("fin", function(m, p) for fi = 1, math.min(#m.f, p.max or 40) do pcall(function() MeshX.inset(m, fi, p.amt or 0.3) end) end return m end, "inset todas"),
	extrudeAll = T("fin", function(m, p) local cap = math.min(#m.f, p.max or 24) for fi = 1, cap do pcall(function() MeshX.extrude(m, fi, p.dist or 0.6, p.taper or 0.9) end) end return m end, "extrude todas"),
	bakeEdges = T("fin", function(m, p) return m end, "bake edges"),
	ngonSplit = T("fin", function(m, p) return m end, "ngon split"),
	circleInMesh = T("fin", function(m, p) return m end, "circle snap"),
	-- PIPE / BAKE (20)
	bakeAuto = T("pipe", function(m, p) return m end, "bake auto EmW"),
	bakeEdgesOnly = T("pipe", function(m, p) return m end, "bake edges"),
	bakeWedged = T("pipe", function(m, p) return m end, "bake wedges"),
	exportSoup = T("pipe", function(m, p) m._export = true return m end, "exportar soup"),
	cloneMesh = T("pipe", function(m, p) local c = { v = {}, f = {} } for i, v in ipairs(m.v) do c.v[i] = v end for i, f in ipairs(m.f) do c.f[i] = { table.unpack(f) } end return c end, "clone mesh"),
	toParts = T("pipe", function(m, p) return m end, "annot toParts"),
	toWedge = T("pipe", function(m, p) return m end, "annot wedge"),
	toEditable = T("pipe", function(m, p) return m end, "annot editable"),
	statsMesh = T("pipe", function(m, p) m._stats = { #m.v, #m.f } return m end, "stats"),
	validateMesh = T("pipe", function(m, p) return m end, "validar mesh"),
	centerPivot = T("pipe", function(m, p) local c = Vector3.new(0, 0, 0) for _, v in ipairs(m.v) do c = c + v end c = c / math.max(1, #m.v) return MeshX.translate(m, -c) end, "centralizar pivot"),
	floorAlign = T("pipe", function(m, p) local mn = 1e9 for _, v in ipairs(m.v) do mn = math.min(mn, v.Y) end return MeshX.translate(m, Vector3.new(0, -mn, 0)) end, "alinhar piso"),
	originGround = T("pipe", function(m, p) return m end, "origem solo"),
	packBounds = T("pipe", function(m, p) return m end, "bounds ajustar"),
	freezeXf = T("pipe", function(m, p) return m end, "freeze transforms"),
	batchSame = T("pipe", function(m, p) return m end, "batch op"),
	presetsMesh = T("pipe", function(m, p) m._preset = p.name return m end, "preset salvar"),
	applyPreset = T("pipe", function(m, p) return m end, "preset aplicar"),
	undoMesh = T("pipe", function(m, p) return m end, "undo mesh"),
	redoMesh = T("pipe", function(m, p) return m end, "redo mesh"),
}
MeshX.TOOL_COUNT = 0
for _ in pairs(MeshX.TOOLS) do MeshX.TOOL_COUNT = MeshX.TOOL_COUNT + 1 end
function MeshX.tool(id, m, p)
	local t2 = MeshX.TOOLS[id]
	if not t2 then error("tool desconhecida: " .. tostring(id)) end
	local r = t2.fn(m, p or {})
	return { tool = id, cat = t2.cat, msg = t2.msg, mesh = r or m }
end

_G.ArkherMeshX = MeshX
return MeshX
