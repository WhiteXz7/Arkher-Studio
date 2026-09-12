--[[ ARKHER — UI: SCATTER / SCENE STUDIO X (motor ASXN custom) ]]
-- Studio de povoamento procedural: SCATTER com amostragem Poisson, regras por
-- BIOMA (Whittaker do ATX — a arvore certa no bioma certo), declive maximo,
-- acima do mar, jitter deterministico anti-CG (PATINA), LOD por distancia
-- cooperando com D-O15, query por classe/nome/raio, MERGE/EXPLODE/ALIGN,
-- barras de resultado ao vivo. Preview ANTES de materializar (pontos reais).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7CE38B")
local SXN, DM = ArkherSceneX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local repaintPreview, repaintRules, repaintStatus, repaintQuery, repaintLast, repaintLod, repaintPatCount

local function build()
	local g, root, head = K.window("ArkherScatter", "SCATTER / SCENE STUDIO X — motor ASXN (custom)", 120, 120, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)
	local W, H = 700, 470

	-- ================= ESQUERDA: REGIAO + MAKERS =================
	local lw = 220
	local bodyH = 470 - 34 - 40
	local left = K.f(root, "L", 6, 34, lw, bodyH, T.bg3)
	K.txt(left, "REGIAO DO SCATTER", 8, 4, 200, 14, 9, T.txt3)
	local xBox = K.input(left, 8, 22, 100, 18, "cx (0)", false)
	local zBox = K.input(left, 118, 22, 100, 18, "cz (0)", false)
	local regionShapeBtn = K.btn(left, "Formato: circulo", 8, 46, 150, 18, T.bg4)
	local regionIsCircle = true
	local radiusS = mkSlider(left, 8, 70, 210, "Raio", 8, 160, 60, function(v) return string.format("%.0f m", v) end)
	local rectWS = mkSlider(left, 8, 104, 210, "Rect W", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local rectHS = mkSlider(left, 8, 138, 210, "Rect H", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local countS = mkSlider(left, 8, 172, 210, "Quantidade", 5, 240, 60, function(v) return string.format("%d", math.floor(v)) end)
	local minDistS = mkSlider(left, 8, 206, 210, "Min dist", 1, 20, 5, function(v) return string.format("%.1f m", v) end)
	local slopeS = mkSlider(left, 8, 240, 210, "Declive max", 0, 1.4, 0.8, function(v) return string.format("%.2f", v) end)
	local seedI = K.input(left, 8, 276, 210, 18, "seed (4242)", false)
	K.txt(left, "MAKER", 8, 300, 100, 14, 9, T.txt3)
	local makers = { "auto (regra do bioma)", "tree", "bush", "rock", "grass" }
	local makerIdx = 1
	local makerB = K.btn(left, "auto (regra do bioma)", 8, 316, 210, 18, T.bg4)
	makerB.MouseButton1Click:Connect(function()
		makerIdx = makerIdx % #makers + 1
		makerB.Text = makers[makerIdx]
	end)
	local aboveWater = true
	local wetB = K.btn(left, "so acima do mar: SIM", 8, 340, 150, 18, T.bg4)
	wetB.MouseButton1Click:Connect(function()
		aboveWater = not aboveWater
		wetB.Text = "so acima do mar: " .. (aboveWater and "SIM" or "NAO")
	end)
	local biomes = { "auto (ATX)", "floresta_equatorial", "savana", "deserto", "rocha", "taiga" }
	local biomeIdx = 1
	local biomeB = K.btn(left, "bioma: auto (ATX)", 8, 364, 210, 18, T.bg4)
	biomeB.MouseButton1Click:Connect(function()
		biomeIdx = biomeIdx % #biomes + 1
		biomeB.Text = "bioma: " .. biomes[biomeIdx]
	end)
	regionShapeBtn.MouseButton1Click:Connect(function()
		regionIsCircle = not regionIsCircle
		regionShapeBtn.Text = "Formato: " .. (regionIsCircle and "circulo" or "retangulo")
	end)

	-- ================= CENTRO: PLANO DE PONTOS (PREVIEW) =================
	local cx0, cw = 6 + lw + 8, 236
	local center = K.f(root, "C", cx0, 34, cw, bodyH, T.bg3)
	K.txt(center, "PREVIEW (dots = vai materializar)", 4, 2, 250, 12, 8, T.txt3)
	local pv = K.f(center, "PV", 4, 18, cw - 8, 300, T.bg2)
	K.stroke(pv, T.line, 1)
	local pvCross = K.f(pv, "c", 116, 146, 1, 8, C("#FFD34A"))
	K.f(pv, "c2", 112, 150, 8, 1, C("#FFD34A"))
	local prevInfo = K.txt(center, "passe o PREVIEW p/ calcular", 4, 322, 250, 12, 8.5, T.txt3)
	local prepared = nil

	local prevB = K.btn(center, "PREVIEW", 4, 340, 74, 22, C("#2D6BFF"))
	local scatB = K.btn(center, "SCATTER REAL", 84, 340, 112, 22, C("#3F9E58"))
	local lodB = K.btn(center, "Reg. LOD", 202, 340, 34, 22, T.bg4)

	-- ================= DIREITA: QUERY / PATINA / ALIGN / LOD =================
	local rx0 = cx0 + cw + 8
	local rw = W - rx0 - 6
	local right = K.f(root, "R", rx0, 34, rw, bodyH, T.bg3)
	K.txt(right, "QUERY NO WORLD", 8, 4, 200, 14, 9, T.txt3)
	local qCls = K.input(right, 8, 20, rw - 16, 18, "class (Part)", false)
	local qName = K.input(right, 8, 44, rw - 16, 18, "nome contem", false)
	local qRadS = mkSlider(right, 8, 66, rw - 20, "Raio q", 0, 300, 0, function(v) return v == 0 and "off" or string.format("%.0f m", v) end)
	local qBtn = K.btn(right, "Rodar query", 8, 106, 110, 20, C("#2D6BFF"))
	local qRes = K.txt(right, "—", 8, 130, rw - 12, 26, 8.5, T.txt2)
	local lastQuery = {}

	K.txt(right, "PATINA (variacao anti-CG)", 8, 162, 200, 14, 9, T.txt3)
	local pHue = mkSlider(right, 8, 178, rw - 20, "Hue jit", 0, 0.15, 0.02, function(v) return string.format("%.3f", v) end)
	local pSat = mkSlider(right, 8, 212, rw - 20, "Sat jit", 0, 0.4, 0.06, function(v) return string.format("%.3f", v) end)
	local pVal = mkSlider(right, 8, 246, rw - 20, "Val jit", 0, 0.5, 0.08, function(v) return string.format("%.3f", v) end)
	local patSelB = K.btn(right, "Patina na SELECAO", 8, 286, 120, 20, ACCENT)
	local patLastB = K.btn(right, "Patina no ULTIMO scatter", 8, 310, 160, 20, T.bg4)
	local patRes = K.txt(right, "—", 8, 334, rw - 12, 22, 8.5, T.txt3)

	K.txt(right, "ALIGN / MERGE", 8, 360, 200, 12, 9, T.txt3)
	local axB = K.btn(right, "Align X (min)", 8, 374, 70, 18, T.bg4)
	local ayB = K.btn(right, "Align Y", 82, 374, 60, 18, T.bg4)
	local azB = K.btn(right, "Align Z", 146, 374, 60, 18, T.bg4)
	local mergeB = K.btn(right, "Merge selecao", 8, 396, 88, 18, C("#2D6BFF"))
	local explB = K.btn(right, "Explode", 100, 396, 62, 18, T.bg4)
	local lodApplyB = K.btn(right, "Aplicar LOD (foco 0,0)", 8, 418, 140, 18, C("#8062FF"))
	local lodRes = K.txt(right, "—", 8, 438, rw - 12, 22, 8.5, T.txt3)

	-- ================= STATUS BAR =================
	local stat = K.txt(root, "", 8, H - 36, W - 16, 14, 9, T.txt3)

	-- ================= WORLD SNAPSHOT =================
	local function getWorld()
		if ARKHER._world then return ARKHER._world end
		if ArkherTerrainX then
			ARKHER._world = ArkherTerrainX.new({ seed = 1337, preset = "continentes", cell = 8 })
		end
		return ARKHER._world
	end
	local function spec()
		local cx = tonumber(xBox.Text) or 0
		local cz = tonumber(zBox.Text) or 0
		local mk = makerIdx > 1 and makers[makerIdx] or nil
		local b2 = biomeIdx > 1 and biomes[biomeIdx] or nil
		return {
			x = cx, z = cz,
			radius = regionIsCircle and radiusS.get() or nil,
			rect = regionIsCircle and nil or { w = rectWS.get(), h = rectHS.get() },
			count = math.floor(countS.get()), minDist = minDistS.get(),
			maxSlope = slopeS.get(), aboveWater = aboveWater,
			maker = mk, biome = b2,
			seed = tonumber(seedI.Text) or 4242, world = getWorld(),
			name = "ASXN_ScatterUI",
		}
	end

	repaintPreview = function()
		for _, ch in ipairs(pv:GetChildren()) do if ch.Name:find("^d") then ch:Destroy() end end
		if not prepared then return end
		-- mapear bbox dos pontos para o quadro
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, it in ipairs(prepared.placed) do
			minX = math.min(minX, it[1]) maxX = math.max(maxX, it[1])
			minZ = math.min(minZ, it[2]) maxZ = math.max(maxZ, it[2])
		end
		local span = math.max(maxX - minX, maxZ - minZ, 1)
		local pw, ph = pv.AbsoluteSize.X > 10 and pv.AbsoluteSize.X or 248, 286
		for i, it in ipairs(prepared.placed) do
			if i > 400 then break end
			local fx = (it[1] - minX) / span
			local fz = (it[2] - minZ) / span
			local col = it[4] == "tree" and C("#63D68B") or it[4] == "rock" and C("#B9B3A8") or it[4] == "bush" and C("#84C96B") or C("#CFE38B")
			local d = K.f(pv, "d" .. i, fx * (pw - 8) + 2, fz * (ph - 8) + 2, it[4] == "tree" and 5 or 3, it[4] == "tree" and 5 or 3, col)
			K.corner(d, 2)
		end
		prevInfo.Text = string.format("%d pontos prontos (tries %d) — area uso ~%.0fx%.0f m | span %.0f m",
			#prepared.placed, prepared.tries or 0, prepared.rect and prepared.rect.w or 2 * (prepared.radius or 0), prepared.rect and prepared.rect.h or 2 * (prepared.radius or 0), span)
	end
	repaintQuery = function(txt) if qRes then qRes.Text = txt end end
	repaintLast = function() local n = #SXN._lods return n end
	repaintLod = function(l) if lodRes then lodRes.Text = l end end
	repaintPatCount = function(s) if patRes then patRes.Text = s end end
	repaintRules = function() end -- reservado p/ barra de regras (v2)
	repaintStatus = function()
		local inv = 0
		for _ in pairs(SXN._ambients or {}) do inv = inv + 1 end
		local hashCount = 0
		for _ in pairs(SXN._hash or {}) do hashCount = hashCount + 1 end
		stat.Text = string.format("spatial-hash cells %d | lod groups %d | ultimo scatter: %s | tries p/ ver o preview",
			hashCount, #SXN._lods, (prepared and (#prepared.placed .. " pts prontos") or "—"))
	end

	prevB.MouseButton1Click:Connect(function()
		local s = spec()
		prepared = SXN.prepare(s)
		prepared.rect = s.rect
		prepared.radius = s.radius
		repaintPreview()
		repaintStatus()
	end)
	scatB.MouseButton1Click:Connect(function()
		local s = spec()
		if prepared then s._prepared = prepared end
		local res = SXN.scatter(s)
		ARKHER._lastScatter = res.model
		K.notify("Scatter", res.count .. " instancias em ASXN_ScatterUI (tries " .. res.tries .. ") | biomas do ATX", "ok")
		repaintStatus()
	end)
	lodB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			SXN.registerLOD(ARKHER._lastScatter, { near = 90, mid = 200, far = 360 })
			repaintLod("LOD registrado grps=" .. #SXN._lods)
		else
			repaintLod("nada p/ registrar (rode SCATTER)")
		end
	end)
	lodApplyB.MouseButton1Click:Connect(function()
		local r = SXN.applyLOD(0, 0)
		repaintLod(string.format("LOD: %d shown, %d ghosts(mid), %d culled(far)", r.shown, r.ghosts, r.culled))
	end)
	qBtn.MouseButton1Click:Connect(function()
		local cls = qCls.Text ~= "" and qCls.Text or "Part"
		local nm = qName.Text ~= "" and qName.Text or nil
		local r = qRadS.get()
		local sp = { class = cls, name = nm, within = r > 0 and { x = tonumber(xBox.Text) or 0, z = tonumber(zBox.Text) or 0, r = r } or nil }
		lastQuery = SXN.query(sp)
		-- contagem por classe
		local byCls = {}
		for _, inst in ipairs(lastQuery) do byCls[inst.ClassName] = (byCls[inst.ClassName] or 0) + 1 end
		local parts = {}
		for k, v in pairs(byCls) do parts[#parts + 1] = k .. "=" .. v end
		repaintQuery(#lastQuery .. " resultados | " .. table.concat(parts, ", "))
	end)
	patSelB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		local n = SXN.patina(list, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get(), seed = tonumber(seedI.Text) or 99 })
		repaintPatCount("patina: " .. n .. " partes (seed " .. (tonumber(seedI.Text) or 99) .. ")")
	end)
	patLastB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			local parts = {}
			for _, ch in ipairs(ARKHER._lastScatter:GetDescendants()) do if ch:IsA("BasePart") then parts[#parts + 1] = ch end end
			local n = SXN.patina(parts, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get() })
			repaintPatCount("patina ultimo scatter: " .. n .. " partes")
		end
	end)
	axB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "x", mode = "min" }) end
	end)
	ayB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "y", mode = "avg" }) end
	end)
	azB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "z", mode = "min" }) end
	end)
	mergeB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 0 then local m = SXN.merge(list, "ASXN_MergedUI") K.notify("Merge", "Model ASXN_MergedUI com " .. #list .. " parts", "ok") end
	end)
	explB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if list[1] and list[1].ClassName == "Model" then
			local out = SXN.explode(list[1])
			K.notify("Explode", #out .. " parts soltas", "ok")
		end
	end)

	-- boot
	repaintStatus()
	return g
end

ARKHER.reg("Scatter", "Scatter / Scene X", "Mundo", ICON.plate, "Povoamento procedural: scatter Poisson por bioma, patina, LOD distancia, query, merge/align", build)
