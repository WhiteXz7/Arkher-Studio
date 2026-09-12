--[[ ARKHER — UI: TERRAIN STUDIO (motor ATX custom, nao usa Terrain do Roblox) ]]
-- Estudio profissional completo: 6 abas (ESCULPIR/GERAR/GEOL/HIDRO/CLIMA/MUNDO),
-- canvas de terreno INTERATIVO (clique/arraste esculpe o mundo ATX de verdade),
-- 10 pinceis x 5 falloffs, 8 presets de mundo, erosao real, rios, lagos, clima,
-- biomas, materializacao adaptativa (D-O15) e export real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local TX, DM = ArkherTerrainX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	local lbl = K.txt(parent, label, x, y, 80, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 54, y, 54, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 16, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		if fmt then valLbl.Text = fmt(val) else valLbl.Text = string.format("%.2f", val) end
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
	return {
		get = function() return val end,
		set = function(v) val = v renderSlider() if onSet then onSet(v) end end,
	}
end

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN STUDIO — motor ATX (custom)", 24, 300, 700, 500, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= MUNDO VIVO =================
	local world = TX.new({ seed = 1337, preset = "continentes", cell = 8, chunkCells = 16 })
	local brush = { op = "raise", falloff = "smooth", radius = 24, strength = 0.6, amount = 6, mat = "grama" }
	local region = { gx0 = 1, gz0 = 1, gw = 64, gh = 40 } -- regiao de trabalho (celulas)
	local status = nil
	local statLbl = nil
	local gridTiles = {}
	local preview = nil
	local seedBox = nil
	local refreshStats = nil
	local refreshClimate = nil
	local climateList = nil

	-- ================= ABAS =================
	local TABS = { "ESCULPIR", "GERAR", "GEOL", "HIDRO", "CLIMA", "MUNDO" }
	local curTab = 1
	local tabBodies = {}
	local tabBar = K.f(root, "TabBar", 8, 34, 684, 26, T.bg4)
	K.corner(tabBar, 5)
	local tabBtns = {}
	local function selectTab(i)
		curTab = i
		for j, b in ipairs(tabBtns) do
			b.BackgroundColor3 = (j == i) and T.bg2 or T.bg4
			local u = b:FindFirstChild("Und")
			if u then u.BackgroundColor3 = (j == i) and ACCENT or T.bg4 end
			if tabBodies[j] then tabBodies[j].Visible = (j == i) end
		end
	end
	for i, nm in ipairs(TABS) do
		local b = K.btn(tabBar, "T" .. i, 4 + (i - 1) * 113, 2, 108, 22, T.bg4, 4)
		K.txtS(b, nm, 10, T.txt2)
		local u = K.f(b, "Und", 0, 20, 108, 2, T.bg4)
		local idx = i
		b.MouseButton1Click:Connect(function() selectTab(idx) end)
		tabBtns[i] = b
	end

	local contentY, contentH = 66, 300

	-- ================= CANVAS (todos os paineis a esquerda) =================
	local canvasW, canvasCols, canvasRows = 320, 16, 10
	local tileW, tileH = 20, 24
	preview = K.f(root, "Canvas", 8, contentY, tileW * canvasCols + 2, tileH * canvasRows + 2, T.bg0)
	K.corner(preview, 4)
	K.stroke(preview, T.line, 1)
	local painting = false
	local function cellColor(h, mi, wet, isRiver, isLake)
		local m = TX.MATERIALS[mi or 1]
		local base = m and m.cor or { 90, 140, 80 }
		local shade = math.min(1.2, math.max(0.45, 0.75 + h / 70))
		local r2 = math.floor(base[1] * shade)
		local g2 = math.floor(base[2] * shade)
		local b2 = math.floor(base[3] * shade)
		if isRiver or isLake then return Color3.fromRGB(52, 120, 200) end
		if h < world.seaLevel then return Color3.fromRGB(28, 84, 148) end
		if wet and wet > 0.75 then
			return Color3.fromRGB(math.floor(r2 * 0.8), math.floor(g2 * 0.9), math.floor(b2 * 0.85))
		end
		return Color3.fromRGB(math.min(255, r2), math.min(255, g2), math.min(255, b2))
	end
	local function repaint()
		for j = 1, canvasRows do
			for i = 1, canvasCols do
				local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
				local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
				local cx, cz = world:chunkKeyOf(gx, gz)
				local ch = world:genChunk(cx, cz)
				local n = world.chunkCells
				local lx = math.min(n, math.max(1, gx - cx * n))
				local lz = math.min(n, math.max(1, gz - cz * n))
				local h = world:heightAtCell(gx, gz)
				local mi = ch.mat[(lz - 1) * n + lx]
				local wv = ch.wet[(lz - 1) * n + lx] or 0
				local isRiver = (wv >= 0.99 and h > world.seaLevel - 1)
				local isLake = world.lakes[gx .. "," .. gz] ~= nil
				local t2 = gridTiles[(j - 1) * canvasCols + i]
				t2.BackgroundColor3 = cellColor(h, mi, wv, isRiver, isLake)
				local hl = t2:FindFirstChild("Hd")
				if hl then hl.Visible = false end
			end
		end
	end
	local function paintAt(i, j)
		local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
		local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
		-- nivel de mar: depressao vira agua visual
		if brush.op == "sealevel" then
			world.seaLevel = world:heightAtCell(gx, gz)
			repaint()
			return
		end
		world:sculpt(gx * world.cell, gz * world.cell, {
			op = brush.op, radius = brush.radius, strength = brush.strength,
			falloff = brush.falloff, amount = brush.amount, mat = brush.mat,
			target = world:heightAtCell(gx, gz),
		})
		repaint()
		if status then status.Text = "pincel '" .. brush.op .. "' em (" .. gx .. "," .. gz .. ") r=" .. brush.radius .. " f=" .. string.format("%.2f", brush.strength) end
	end
	for j = 1, canvasRows do
		for i = 1, canvasCols do
			local t2 = K.btn(preview, "H" .. ((j - 1) * canvasCols + i), (i - 1) * tileW + 1, (j - 1) * tileH + 1, tileW - 1, tileH - 1, T.bg2, 1)
			local ii, jj = i, j
			t2.MouseButton1Click:Connect(function() paintAt(ii, jj) end)
			t2.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = true paintAt(ii, jj) end
			end)
			t2.MouseEnter:Connect(function()
				if painting then paintAt(ii, jj) end
				t2.BackgroundTransparency = 0.55
			end)
			t2.MouseLeave:Connect(function() t2.BackgroundTransparency = 0 end)
			gridTiles[(j - 1) * canvasCols + i] = t2
		end
	end
	preview.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = false end
	end)
	K.txt(preview, region.gw .. "x" .. region.gh .. " celulas | clique ou arraste p/ esculpir", 6, tileH * canvasRows - 16, 260, 12, 8, C("#0A0F18"))

	-- ================= PAINEL DIREITO (abas) =================
	local panel = K.f(root, "Panel", 338, contentY, 352, contentH + 150, T.bg4)
	K.corner(panel, 5)
	for i = 1, #TABS do
		local body = K.f(panel, "TB" .. i, 0, 0, 352, contentH + 150)
		body.Visible = i == 1
		tabBodies[i] = body
	end

	-- ========== ABA 1: ESCULPIR ==========
	do
		local b = tabBodies[1]
		K.txt(b, "PINCEIS (10)", 12, 8, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local ops = {
			{ id = "raise", nm = "Raise", gl = "+" }, { id = "lower", nm = "Lower", gl = "-" },
			{ id = "smooth", nm = "Smooth", gl = "~" }, { id = "flatten", nm = "Flatten", gl = "=" },
			{ id = "set", nm = "Set", gl = "S" }, { id = "noise", nm = "Noise", gl = "N" },
			{ id = "crater", nm = "Cratera", gl = "O" }, { id = "terrace", nm = "Terraco", gl = "T" },
			{ id = "paint", nm = "Pintar", gl = "P" }, { id = "wet", nm = "Molhar", gl = "W" },
		}
		local opBtns = {}
		for i, o in ipairs(ops) do
			local bx = 12 + ((i - 1) % 3) * 108
			local by = 26 + math.floor((i - 1) / 3) * 30
			local b2 = K.btn(b, "OP" .. i, bx, by, 100, 26, T.bg2, 4)
			K.txt(b2, o.gl, 6, 5, 16, 16, 13, ACCENT, ARKHER.FONTB)
			K.txt(b2, o.nm, 26, 6, 70, 14, 10, T.txt)
			local id = o.id
			b2.MouseButton1Click:Connect(function()
				brush.op = id
				for j3, bb in ipairs(opBtns) do K.stroke(bb, ops[j3].id == id and ACCENT or T.line2, ops[j3].id == id and 1.5 or 1) end
				if status then status.Text = "pincel: " .. o.nm end
			end)
			K.stroke(b2, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			opBtns[i] = b2
		end
		K.txt(b, "FALLOFF", 12, 134, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local falloffs = { "smooth", "gaussian", "cosine", "linear", "sharp" }
		local fBtns = {}
		for i, f2 in ipairs(falloffs) do
			local b3 = K.btn(b, "F" .. i, 12 + (i - 1) * 65, 152, 60, 20, T.bg2, 4)
			K.txtS(b3, f2, 9, T.txt2)
			local fid = f2
			b3.MouseButton1Click:Connect(function()
				brush.falloff = fid
				for j3, bb in ipairs(fBtns) do K.stroke(bb, falloffs[j3] == fid and ACCENT or T.line2, falloffs[j3] == fid and 1.5 or 1) end
			end)
			K.stroke(b3, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			fBtns[i] = b3
		end
		mkSlider(b, 12, 182, 200, "Raio", 4, 96, brush.radius, function(v) return string.format("%.0f", v) end, function(v) brush.radius = v end)
		mkSlider(b, 12, 226, 200, "Forca", 0.05, 1, brush.strength, function(v) return string.format("%.2f", v) end, function(v) brush.strength = v end)
		mkSlider(b, 12, 270, 200, "Quantia", 1, 24, brush.amount, function(v) return string.format("%.1f", v) end, function(v) brush.amount = v end)
		-- materiais (18 dos 24 p/ pintar)
		K.txt(b, "MATERIAL (p/ pintar)", 12, 314, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local pm = 0
		for i, m in ipairs(TX.MATERIALS) do
			if pm >= 18 then break end
			pm = pm + 1
			local mx = 12 + ((pm - 1) % 6) * 54
			local my = 332 + math.floor((pm - 1) / 6) * 24
			local sw = K.btn(b, "MT" .. pm, mx, my, 50, 20, T.bg2, 3)
			K.f(sw, "c", 3, 3, 14, 14, Color3.fromRGB(m.cor[1], m.cor[2], m.cor[3]), 2)
			K.txt(sw, m.id:sub(1, 7), 19, 4, 30, 12, 8, T.txt3)
			local mid = m.id
			sw.MouseButton1Click:Connect(function()
				brush.mat = mid
				brush.op = "paint"
				if status then status.Text = "pintar: " .. m.nm .. " (dens " .. m.dens .. " kg/L)" end
			end)
		end
		local undo2 = K.btn(b, "Undo", 12, 416, 120, 26, T.bg2, 5)
		K.txtS(undo2, "Desfazer (undo stack)", 9, T.txt)
		K.hover(undo2, T.bg2, T.hover)
		undo2.MouseButton1Click:Connect(function()
			ArkherUNDO.undo()
			repaint()
			if status then status.Text = "undo aplicado" end
		end)
	end

	-- ========== ABA 2: GERAR ==========
	do
		local b = tabBodies[2]
		K.txt(b, "PRESETS DE MUNDO (8)", 12, 8, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local presetIds = { "continentes", "ilhas", "montanhas", "canyon", "dunas", "meseta", "vulcao", "polar" }
		for i, pid in ipairs(presetIds) do
			local p = TX.PRESETS[pid]
			local bx = 12 + ((i - 1) % 2) * 166
			local by = 28 + math.floor((i - 1) / 2) * 34
			local b2 = K.btn(b, "PR" .. i, bx, by, 158, 30, T.bg2, 4)
			K.txt(b2, p.label, 10, 3, 130, 14, 11, T.txt)
			local extras = (p.mont and ("mont x" .. p.mont) or "") .. (p.terrace and (" | terraco " .. p.terrace) or "")
			K.txt(b2, extras, 10, 16, 140, 12, 8, T.txt4)
			K.hover(b2, T.bg2, T.hover)
			local id = pid
			b2.MouseButton1Click:Connect(function()
				local s = math.floor(seedBox.Text ~= "" and tonumber(seedBox.Text) or world.seed)
				world = TX.new({ seed = s, preset = id, cell = world.cell, chunkCells = 16, seaLevel = p.sea or 0 })
				repaint()
				refreshStats()
				if status then status.Text = "mundo gerado: " .. p.label .. " (seed " .. s .. ")" end
			end)
		end
		K.txt(b, "SEED", 12, 172, 60, 14, 10, T.txt3, ARKHER.FONTB)
		seedBox = K.input(b, 60, 168, 100, 24, "1337")
		local regen = K.btn(b, "Regen", 168, 168, 90, 24, ACCENT, 5)
		K.txtS(regen, "Gerar", 11, C("#0D140B"))
		K.hover(regen, ACCENT, C("#A5E88C"))
		local rnd = K.btn(b, "Rnd", 264, 168, 60, 24, T.bg2, 5)
		K.txtS(rnd, "Aleatoria", 9, T.txt)
		K.hover(rnd, T.bg2, T.hover)
		rnd.MouseButton1Click:Connect(function()
			seedBox.Text = tostring(math.random(1, 99999))
		end)
		regen.MouseButton1Click:Connect(function()
			local s = tonumber(seedBox.Text) or 1337
			world = TX.new({ seed = s, preset = world.preset, cell = world.cell, chunkCells = 16, seaLevel = world.params.sea or 0 })
			repaint()
			refreshStats()
			if status then status.Text = "regenerado seed " .. s .. " preset " .. world.preset end
		end)
		-- parametros finos
		K.txt(b, "PARAMETROS FISICOS", 12, 206, 200, 14, 10, T.txt3, ARKHER.FONTB)
		mkSlider(b, 12, 224, 200, "Continentes", 0, 2, world.params.cont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.cont = v end)
		mkSlider(b, 12, 268, 200, "Montanhas", 0, 2.5, world.params.mont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.mont = v end)
		mkSlider(b, 12, 312, 200, "Warp", 0, 12, world.params.warp or 4, function(v) return string.format("%.1f", v) end, function(v) world.params.warp = v end)
		local reapp = K.btn(b, "Reapply", 12, 362, 160, 26, T.bg2, 5)
		K.txtS(reapp, "Reaplicar e re-gerar chunks", 9, T.txt)
		K.hover(reapp, T.bg2, T.hover)
		reapp.MouseButton1Click:Connect(function()
			world.chunks = {}
			world.stats.gen = 0
			world.stats.cells = 0
			repaint()
			refreshStats()
			if status then status.Text = "chunks re-gerados com novos parametros" end
		end)
	end

	-- ========== ABA 3: GEOL (erosao) ==========
	do
		local b = tabBodies[3]
		K.txt(b, "EROSAO HIDRAULICA (droplet sim)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local iters = mkSlider(b, 12, 26, 200, "Gotas", 500, 20000, 5000, function(v) return string.format("%.0f", v) end)
		local erf = mkSlider(b, 12, 70, 200, "Erodibilidade", 0.05, 1, 0.35)
		local dep = mkSlider(b, 12, 114, 200, "Deposicao", 0.05, 1, 0.35)
		local run1 = K.btn(b, "RunH", 12, 168, 158, 28, ACCENT, 5)
		K.txtS(run1, "Rodar erosao hidraulica", 10, C("#0D140B"))
		K.hover(run1, ACCENT, C("#A5E88C"))
		local hydRes = K.txt(b, "—", 12, 202, 320, 14, 9, T.txt4)
		run1.MouseButton1Click:Connect(function()
			local res = world:erodeHydraulic(region.gx0, region.gz0, region.gw, region.gh, math.floor(iters.get()), { erode = erf.get(), deposit = dep.get() })
			hydRes.Text = "gotas: " .. res.iterations .. " | dMedio: " .. string.format("%.3f", res.meanDelta) .. " | dMax: " .. string.format("%.2f", res.maxDelta)
			repaint()
			if status then status.Text = "erosao hidraulica concluida (vales + sedimentos reais)" end
		end)
		K.txt(b, "EROSAO TERMICA (talus)", 12, 232, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local pass = mkSlider(b, 12, 250, 200, "Passagens", 1, 32, 8, function(v) return string.format("%.0f", v) end)
		local tal = mkSlider(b, 12, 294, 200, "Talude limite", 0.2, 2, 0.9)
		local run2 = K.btn(b, "RunT", 12, 348, 158, 28, T.bg2, 5)
		K.txtS(run2, "Rodar erosao termica", 10, T.txt)
		K.hover(run2, T.bg2, T.hover)
		local thRes = K.txt(b, "—", 12, 382, 320, 14, 9, T.txt4)
		run2.MouseButton1Click:Connect(function()
			local res = world:erodeThermal(region.gx0, region.gz0, region.gw, region.gh, math.floor(pass.get()), tal.get())
			thRes.Text = "passagens: " .. res.passes .. " | material movido: " .. string.format("%.1f", res.moved)
			repaint()
			if status then status.Text = "erosao termica concluida (encostas em angulo de repouso)" end
		end)
	end

	-- ========== ABA 4: HIDRO ==========
	do
		local b = tabBodies[4]
		K.txt(b, "RIOS (D8 flow accumulation)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local acc = mkSlider(b, 12, 26, 200, "Acumulacao min", 4, 96, 24, function(v) return string.format("%.0f", v) end)
		local runR = K.btn(b, "RunR", 12, 76, 158, 28, C("#58A6FF"), 5)
		K.txtS(runR, "Escavar rede de rios", 10, C("#081420"))
		K.hover(runR, C("#58A6FF"), C("#8FC3FF"))
		local rivRes = K.txt(b, "—", 12, 110, 320, 14, 9, T.txt4)
		runR.MouseButton1Click:Connect(function()
			local res = world:carveRivers(region.gx0, region.gz0, region.gw, region.gh, math.floor(acc.get()))
			rivRes.Text = "celulas fluviais: " .. res.cells .. " | acumulacao max: " .. res.maxAcc
			repaint()
			if status then status.Text = "rios escavados: " .. res.cells .. " celulas (leitos em V)" end
		end)
		K.txt(b, "LAGOS (depression fill)", 12, 140, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local runL = K.btn(b, "RunL", 12, 160, 158, 28, C("#2FBF9F"), 5)
		K.txtS(runL, "Preencher lagos", 10, C("#062018"))
		K.hover(runL, C("#2FBF9F"), C("#6ADFC2"))
		local lakeRes = K.txt(b, "—", 12, 194, 320, 14, 9, T.txt4)
		runL.MouseButton1Click:Connect(function()
			local res = world:fillLakes(region.gx0, region.gz0, region.gw, region.gh)
			lakeRes.Text = "celulas de lago: " .. res.cells
			repaint()
			if status then status.Text = "lagos preenchidos: " .. res.cells .. " celulas" end
		end)
		K.txt(b, "NIVEL DO MAR", 12, 224, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local sea = mkSlider(b, 12, 242, 200, "Sea level", -20, 20, world.seaLevel, function(v) return string.format("%.1f", v) end, function(v)
			world.seaLevel = v
			repaint()
		end)
		local awater = K.btn(b, "Water", 12, 292, 158, 28, T.purple, 5)
		K.txtS(awater, "Abrir WATER STUDIO", 10, C("#FFFFFF"))
		K.hover(awater, T.purple, C("#A97AFF"))
		awater.MouseButton1Click:Connect(function() ARKHER.open("Water") end)
		K.txt(b, "waters = AWX (motor proprio)", 12, 326, 240, 12, 8, T.txt4)
	end

	-- ========== ABA 5: CLIMA ==========
	do
		local b = tabBodies[5]
		K.txt(b, "CLIMA GLOBAL (campos fisicos)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local tb = mkSlider(b, 12, 26, 200, "Temp bias", -40, 40, world.params.tempB or 0, function(v) return string.format("%+.0f C", v) end, function(v) world.params.tempB = v end)
		local hb = mkSlider(b, 12, 70, 200, "Chuva bias", -80, 80, world.params.humidB or 0, function(v) return string.format("%+.0f cm", v) end, function(v) world.params.humidB = v end)
		local applyC = K.btn(b, "ApplyC", 12, 124, 158, 26, T.bg2, 5)
		K.txtS(applyC, "Re-classificar biomas", 10, T.txt)
		K.hover(applyC, T.bg2, T.hover)
		applyC.MouseButton1Click:Connect(function()
			world.chunks = {}
			repaint()
			refreshClimate()
			if status then status.Text = "biomas re-classificados via Whittaker" end
		end)
		K.txt(b, "BIOMAS (distribuicao real — Whittaker)", 12, 162, 300, 14, 10, T.txt3, ARKHER.FONTB)
		climateList = K.f(b, "CL", 12, 182, 328, 200)
		refreshClimate = function()
			climateList:ClearAllChildren()
			local counts = world:biomeCounts()
			local total = 0
			local sorted = {}
			for k2, v in pairs(counts) do total = total + v; sorted[#sorted + 1] = { k2, v } end
			table.sort(sorted, function(a, b2) return a[2] > b2[2] end)
			if total == 0 then K.txt(climateList, "gere o mundo primeiro (canvas)", 0, 0, 240, 14, 10, T.txt4) return end
			for i = 1, math.min(#sorted, 9) do
				local name, qty = sorted[i][1], sorted[i][2]
				local frac = qty / total
				K.txt(climateList, name, 0, (i - 1) * 21, 150, 14, 10, T.txt2)
				local bar = K.f(climateList, "B" .. i, 150, (i - 1) * 21 + 3, math.floor(140 * frac), 8, ACCENT)
				K.corner(bar, 3)
				K.txt(climateList, string.format("%.1f%%", frac * 100), 296, (i - 1) * 21, 40, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Right)
			end
		end
		refreshClimate()
	end

	-- ========== ABA 6: MUNDO ==========
	do
		local b = tabBodies[6]
		K.txt(b, "MATERIALIZACAO (RRW -> workspace)", 12, 8, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local mkWorld = K.btn(b, "M1", 12, 26, 158, 28, ACCENT, 5)
		K.txtS(mkWorld, "Materializar 128x128", 10, C("#0D140B"))
		K.hover(mkWorld, ACCENT, C("#A5E88C"))
		local mkBig = K.btn(b, "M2", 176, 26, 158, 28, T.bg2, 5)
		K.txtS(mkBig, "Materializar 256x256", 10, T.txt)
		K.hover(mkBig, T.bg2, T.hover)
		local mkOut = K.txt(b, "—", 12, 60, 328, 14, 9, T.txt4)
		mkWorld.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-64, -64, 128, 128, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts (LOD " .. tostring(TX._lodStep(2)) .. ")" end
		end)
		mkBig.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-128, -128, 256, 256, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts" end
		end)
		local lodB = K.btn(b, "LOD", 12, 84, 158, 26, T.bg2, 5)
		K.txtS(lodB, "LOD adaptativo (foco 0,0)", 9, T.txt)
		K.hover(lodB, T.bg2, T.hover)
		lodB.MouseButton1Click:Connect(function()
			local r = world:updateLOD(0, 0)
			if status then status.Text = "LOD: " .. r.updated .. " chunks atualizados (D-O15 nivel " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")" end
		end)
		local clr = K.btn(b, "Clr", 176, 84, 158, 26, T.bg2, 5)
		K.txtS(clr, "Limpar workspace", 10, T.txt)
		K.hover(clr, T.bg2, T.hover)
		clr.MouseButton1Click:Connect(function()
			TX.clearWorld(world)
			refreshStats()
			if status then status.Text = "ATX_World removido do workspace" end
		end)
		K.txt(b, "PERSISTENCIA (JSON roundtrip)", 12, 122, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local exp = K.btn(b, "Exp", 12, 140, 158, 26, T.bg2, 5)
		K.txtS(exp, "Exportar ATX JSON", 10, T.txt)
		K.hover(exp, T.bg2, T.hover)
		local expOut = K.txt(b, "—", 12, 170, 328, 14, 9, T.txt4)
		exp.MouseButton1Click:Connect(function()
			local str, path, ok = world:exportFile()
			expOut.Text = "bundle: " .. #str .. " chars → " .. path .. (ok and " (arquivo gravado)" or " (somente Studio grava)")
		end)
		local load2 = K.btn(b, "Load", 176, 140, 158, 26, T.bg2, 5)
		K.txtS(load2, "Testar roundtrip", 10, T.txt)
		K.hover(load2, T.bg2, T.hover)
		load2.MouseButton1Click:Connect(function()
			local str = world:serialize()
			local w2, err = TX.deserialize(str)
			if w2 then
				expOut.Text = "roundtrip OK: " .. (w2.restored or 0) .. " chunks restaurados, seed " .. w2.seed
			else
				expOut.Text = "roundtrip falhou: " .. tostring(err)
			end
		end)
		K.txt(b, "MOTOR", 12, 196, 120, 14, 10, T.txt3, ARKHER.FONTB)
		K.row(b, "engine", "ATX v" .. TX._version, 214)
		K.row(b, "chunk", world.chunkCells .. " celulas x " .. world.cell .. " studs", 232)
		K.row(b, "materiais", #TX.MATERIALS .. " fisicos", 250)
		K.row(b, "presets", "8 mundos", 268)
		local ai2 = K.btn(b, "AI", 12, 292, 322, 28, T.purple, 5)
		K.txtS(ai2, "Singularity: mundo + erosao + rios + agua", 10, C("#FFFFFF"))
		K.hover(ai2, T.purple, C("#A97AFF"))
		ai2.MouseButton1Click:Connect(function()
			local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno realista com rios, erosao e oceano") end)
			if ok2 and rep then K.notify("Singularity", "mundo gerado (" .. #rep.lines .. " etapas)", "ok") end
		end)
		K.txt(b, "sementes renascem identicas — mesma realidade, qualquer D-O15", 12, 330, 320, 12, 8, T.txt4)
	end

	-- ================= BASE: STATUS + STATS =================
	local bar = K.f(root, "Bar", 8, contentY + contentH + 8, 322, 52, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um pincel e clique no canvas", 10, 6, 304, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 28, 304, 14, 8, T.txt4)
	refreshStats = function()
		local s = world:worldStats()
		statLbl.Text = "seed " .. s.seed .. " | chunks " .. s.chunks .. " | celulas " .. s.cells .. " | rios " .. s.rivers .. " | lagos " .. s.lakes .. " | parts " .. s.parts .. " | gotas " .. s.droplets
	end
	refreshStats()
	repaint()
	selectTab(1)
end

ARKHER.reg("Terrain", "Terrain Studio", "Editor", ICON.terrain, "Terrain custom (ATX): 10 pinceis, erosao real, rios, lagos, clima, biomas, LOD D-O15", build)
