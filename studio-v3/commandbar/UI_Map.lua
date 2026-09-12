--[[ ARKHER V4 — LocalScript. Requer os kits (ReplicatedStorage.ArkherV3.ArkherKit_B/C/D/E). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	for _, kn in ipairs({ "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E" }) do
		local m = folder and folder:FindFirstChild(kn)
		if not m then m = script:FindFirstChild(kn) end
		if not m then m = script.Parent and script.Parent:FindFirstChild(kn) end
		if not m then
			error("[ARKHER] " .. kn .. " nao encontrado: rode os installers A+B+C+D+E primeiro.")
		end
		require(m)
	end
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER V3 — UI: MAP ]]
-- Layout unico: minimapa grande no centro com POIs (ICON.pin) clicaveis,
-- lista de pontos de interesse a esquerda, legenda a direita, exportacao real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#55EFC4")

local POIS = {
	{ nm = "Spawn Point", x = 60, y = 180, c = ACCENT, kind = "spawn" },
	{ nm = "Municipio", x = 150, y = 90, c = C("#FFD93D"), kind = "build" },
	{ nm = "Porto", x = 30, y = 60, c = C("#74B9FF"), kind = "water" },
	{ nm = "Base Militar", x = 250, y = 200, c = C("#FF6B81"), kind = "military" },
}

local function build()
	local g, root, head = K.window("ArkherMap", "MAP — pontos de interesse", 24, 400, 572, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	local selPoi = 1

	-- ===== ESQUERDA: LISTA DE POIs =====
	local left = K.f(root, "Pois", 8, 34, 128, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POIs", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local poiBtns = {}
	for i, p in ipairs(POIS) do
		local row = K.btn(left, "P" .. i, 8, 26 + (i - 1) * 34, 112, 30, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		local ic = K.f(row, "Ic", 4, 5, 20, 20)
		ICON.pin(ic)
		K.txt(row, p.nm, 28, 0, 80, 30, 10, T.txt)
		K.hover(row, T.bg4, T.hover)
		poiBtns[i] = row
		local idx = i
		row.MouseButton1Click:Connect(function()
			selPoi = idx
			for j, b in ipairs(poiBtns) do
				K.stroke(b, j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			detNm.Text = POIS[idx].nm
			detKd.Text = POIS[idx].kind
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	K.txt(left, "4 POIs mapeados", 10, 172, 110, 30, 9, T.txt4)
	local addP = K.btn(left, "AddP", 8, 200, 112, 22, T.bg2, 4)
	K.txtS(addP, "+ POI", 10, T.txt)
	K.hover(addP, T.bg2, T.hover)
	addP.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Map: novo POI em modo de colocacao")
	end)

	-- ===== CENTRO: MINIMAPA =====
	local cv = K.f(root, "Map", 148, 34, 292, 256, C("#16281F"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- agua
	local water = K.f(cv, "Water", 0, 0, 70, 110, C("#1B3A5C"), 0)
	K.grad(water, C("#1B3A5C"), C("#122A44"))
	-- estradas
	K.f(cv, "R1", 0, 130, 292, 10, C("#3A3F47"))
	K.f(cv, "R2", 140, 0, 10, 256, C("#3A3F47"))
	K.f(cv, "R3", 60, 200, 232, 8, C("#33383F"))
	-- quarteiroes
	K.f(cv, "B1", 90, 60, 40, 56, C("#24382C"))
	K.f(cv, "B2", 170, 40, 52, 60, C("#26392D"))
	K.f(cv, "B3", 200, 160, 60, 70, C("#22352A"))
	K.f(cv, "B4", 90, 170, 36, 60, C("#24382C"))
	-- pinos
	local pins = {}
	for i, p in ipairs(POIS) do
		local pin = K.f(cv, "Pin" .. i, p.x - 8, p.y - 16, 16, 16, T.bg0)
		ICON.pin(pin)
		if i == 1 then
			local ring = K.f(cv, "Ring" .. i, p.x - 13, p.y - 21, 26, 26, T.bg0)
			ring.BackgroundTransparency = 1
			K.corner(ring, 13)
			K.stroke(ring, ACCENT, 2)
			pins[i] = ring
		end
		K.txt(cv, "L" .. i, p.x - 30, p.y + 4, 60, 12, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		pin.MouseButton1Click:Connect(function()
			selPoi = idx
			detNm.Text = POIS[idx].nm
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	-- norte
	local north = K.f(cv, "North", 258, 8, 24, 24, T.bg0, 12)
	K.stroke(north, ACCENT, 1.5)
	K.txt(north, "N", 0, 4, 24, 16, 10, ACCENT, FONTB, Enum.TextXAlignment.Center)

	-- ===== DIREITA: LEGENDA + DETALHE =====
	local right = K.f(root, "Leg", 452, 34, 112, 256, T.bg4)
	K.corner(right, 4)
	K.txt(right, "LEGENDA", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local legend = {
		{ "Agua", C("#1B3A5C") }, { "Estrada", C("#3A3F47") },
		{ "Predio", C("#26392D") }, { "Spawn", ACCENT },
	}
	for i, l in ipairs(legend) do
		K.f(right, "L" .. i, 10, 28 + (i - 1) * 22, 12, 12, l[2], 2)
		K.txt(right, l[1], 28, 26 + (i - 1) * 22, 70, 14, 9, T.txt2)
	end
	K.txt(right, "DETALHE", 10, 128, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local detNm = K.txt(right, "Spawn Point", 10, 146, 94, 16, 10, ACCENT, ARKHER.FONTB)
	local detKd = K.txt(right, "spawn", 10, 164, 94, 14, 9, T.txt4)
	K.row(right, "Escala", "1:500", 190)
	K.row(right, "Resolucao", "512px", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 298, 556, 94, T.bg0)
	K.corner(bar, 4)
	local exp = K.btn(bar, "Exp", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(exp, "Exportar mapa", 10, C("#04180F"))
	K.hover(exp, ACCENT, C("#9DF5D8"))
	exp.MouseButton1Click:Connect(function()
		local lines = { "-- MAPA ARKHER", string.format("gerado em %s", tostring(tick() and math.floor(tick() * 100))) }
		for i, p in ipairs(POIS) do
			table.insert(lines, string.format("%d. %s (%s) @ (%d, %d)", i, p.nm, p.kind, p.x, p.y))
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherMaps/mapa_pois.txt", table.concat(lines, "\n"))
				return "ArkherMaps/mapa_pois.txt"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Map: exportado para " .. path)
			K.notify("Mapa exportado", path, "ok")
		else
			ARKHER.out("WARNING", "Map: WriteFile indisponivel fora do Studio")
		end
	end)
	K.txt(bar, "128x128u | 4 POIs | escala 1:500", 160, 16, 240, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 536, 0.8, ACCENT)
	K.txt(bar, "mapeado: 80%", 160, 58, 120, 14, 9, T.txt4)
end

ARKHER.reg("Map", "Map", "Scene", ICON.globe, "Mapa: minimapa com POIs interativos, legenda e exportacao", build)
end

ARKHER.open("Map")
