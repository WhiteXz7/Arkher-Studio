--[[ ARKHER V3 — UI: TERRAIN ]]
-- Layout unico: pincelais de escultura a esquerda, heightmap 8x8 INTERATIVO
-- no centro (clique aplica o pincel e repinta), paleta de biomas a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN — escultura", 24, 320, 552, 384, { pin = true })
	K.f(head, "Acc", 0, 24, 552, 2, ACCENT)

	-- estado do relevo
	local heights = {}
	local seed = 7
	local function reseed(s)
		seed = s
		for i = 1, 64 do
			seed = (seed * 16807) % 2147483647
			heights[i] = (seed % 1000) / 1000 * 6
		end
	end
	reseed(11)

	-- ===== PINCELAS =====
	local brushes = {
		{ id = "raise", nm = "Raise", gl = "+", d = "sobe 1u" },
		{ id = "lower", nm = "Lower", gl = "-", d = "desce 1u" },
		{ id = "smooth", nm = "Smooth", gl = "~", d = "media vizinhos" },
		{ id = "flatten", nm = "Flatten", gl = "=", d = "zera" },
		{ id = "erase", nm = "Erase", gl = "x", d = "remove tudo" },
	}
	local curBrush = "raise"
	local left = K.f(root, "Brush", 8, 34, 108, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "PINCEL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, b in ipairs(brushes) do
		local row = K.btn(left, "B" .. i, 8, 26 + (i - 1) * 34, 92, 28, T.bg2, 4)
		local ic = K.f(row, "G", 4, 6, 16, 16, T.bg0, 3)
		K.txt(ic, b.gl, 0, 0, 16, 16, 11, ACCENT, FONTB, Enum.TextXAlignment.Center)
		K.txt(row, b.nm, 26, 2, 62, 14, 10, T.txt)
		K.txt(row, b.d, 26, 15, 62, 11, 8, T.txt4)
		local id = b.id
		row.MouseButton1Click:Connect(function()
			curBrush = id
			for j = 1, #brushes do
				local rr = left:FindFirstChild("B" .. j)
				if rr then K.stroke(rr, j == i and ACCENT or T.line2, j == i and 1.5 or 1) end
			end
		end)
		K.stroke(row, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	K.sliderRow(left, "Forca", 0.6, 206)

	-- ===== HEIGHTMAP 8x8 =====
	local cv = K.f(root, "Map", 126, 34, 252, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	local tiles = {}
	local function hcolor(h)
		-- 0=agua/areia -> 6=rocha
		local stops = { C("#2E86AB"), C("#E9D8A6"), C("#7ED957"), C("#3E8E41"), C("#8D6E63"), C("#6D6E71"), C("#CFD8DC") }
		local idx = math.min(6, math.floor(h))
		return stops[idx + 1]
	end
	local function paint(i, tx, ty)
		local t = tiles[i]
		if t then
			t.BackgroundColor3 = hcolor(heights[i])
			t:FindFirstChild("N").Text = string.format("%.1f", heights[i])
		end
	end
	local function applyBrush(idx)
		local r, c = math.floor((idx - 1) / 8) + 1, ((idx - 1) % 8) + 1
		local function get(r2, c2)
			if r2 < 1 or r2 > 8 or c2 < 1 or c2 > 8 then return nil end
			return (r2 - 1) * 8 + c2
		end
		if curBrush == "raise" then heights[idx] = math.min(6, heights[idx] + 1)
		elseif curBrush == "lower" then heights[idx] = math.max(0, heights[idx] - 1)
		elseif curBrush == "flatten" then heights[idx] = 0
		elseif curBrush == "erase" then heights[idx] = 0
		elseif curBrush == "smooth" then
			local sum, n = 0, 0
			for dr = -1, 1 do
				for dc = -1, 1 do
					local j = get(r + dr, c + dc)
					if j then sum = sum + heights[j] n = n + 1 end
				end
			end
			heights[idx] = sum / n
		end
		-- repinta a vizinhanca
		for dr = -1, 1 do
			for dc = -1, 1 do
				local j = get(r + dr, c + dc)
				if j then paint(j) end
			end
		end
	end
	for i = 1, 64 do
		local r, c = math.floor((i - 1) / 8) + 1, ((i - 1) % 8) + 1
		local t = K.f(cv, "H" .. i, (c - 1) * 31 + 2, (r - 1) * 29 + 2, 29, 27, hcolor(heights[i]), 2)
		K.txt(t, string.format("%.1f", heights[i]), 0, 8, 29, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
		tiles[i] = t
		local idx = i
		t.MouseButton1Click:Connect(function() applyBrush(idx) end)
	end
	K.txt(cv, "clique num tile = aplicar pincel", 8, 236, 200, 12, 8, T.txt4)

	-- ===== BIOMAS + MATERIAIS =====
	local right = K.f(root, "Biome", 390, 34, 154, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "BIOMAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local biomes = {
		{ "Praia", C("#E9D8A6") }, { "Grande", C("#7ED957") },
		{ "Deserto", C("#D4A373") }, { "Neve", C("#ECEFF1") },
	}
	for i, b in ipairs(biomes) do
		local row = K.btn(right, "BM" .. i, 10, 26 + (i - 1) * 26, 134, 22, T.bg2, 4)
		K.f(row, "Sw", 4, 5, 12, 12, b[2], 2)
		K.txt(row, b[1], 22, 0, 90, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Terrain: bioma " .. b[1])
		end)
	end
	K.txt(right, "MATERIAIS", 10, 138, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local mats = { C("#7ED957"), C("#8D6E63"), C("#B0BEC5"), C("#E9D8A6"), C("#4DB6AC"), C("#6D6E71") }
	for i = 1, 6 do
		local m = K.f(right, "M" .. i, 10 + ((i - 1) % 3) * 44, 158 + math.floor((i - 1) / 3) * 34, 38, 28, mats[i], 3)
		K.stroke(m, i == 1 and ACCENT or T.line, i == 1 and 1.5 or 1)
		K.txt(m, tostring(i) .. "u", 0, 16, 38, 10, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 536, 92, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Relevo procedural", 10, C("#0D140B"))
	K.hover(gen, ACCENT, C("#A5E88C"))
	local gseed = 11
	gen.MouseButton1Click:Connect(function()
		gseed = gseed * 31 + 7
		reseed(gseed)
		for i = 1, 64 do paint(i) end
		ARKHER.out("SUCCESS", "Terrain: relevo procedural (seed " .. gseed .. ")")
	end)
	local ai = K.btn(bar, "AI", 150, 10, 120, 26, T.bg2, 5)
	K.txtS(ai, "Gerar c/ IA", 11, T.txt)
	K.hover(ai, T.bg2, T.hover)
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Terrain: pedindo a Singularity...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno com natureza") end)
		if ok and rep then K.notify("Singularity", "terreno gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	K.txt(bar, "8x8 tiles | 31u | bioma: Grande", 10, 48, 250, 16, 10, T.txt3)
	K.txt(bar, "altura media: 2.4u", 300, 48, 150, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.progress(bar, 10, 70, 516, 0.42, ACCENT)
end

ARKHER.reg("Terrain", "Terrain", "Editor", ICON.terrain, "Escultura de terreno: pincelais, heightmap, biomas e materiais", build)
