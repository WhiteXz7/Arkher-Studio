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

_G.ArkherMeshX = MeshX
return MeshX
