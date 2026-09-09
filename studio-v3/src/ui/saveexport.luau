--[[ ARKHER V3 — UI: SAVEEXPORT ]]
-- Layout unico: selecao de formato a esquerda, PREVIEW PRINT-MAP (vista
-- de cima desenhada a partir do workspace REAL) no centro, exportar a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6348")

local function build()
	local g, root, head = K.window("ArkherSaveExport", "EXPORT — bundle & mapa", 24, 500, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: FORMATOS =====
	local left = K.f(root, "Fmts", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FORMATO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local fmts = {
		{ id = "bundle", nm = "Bundle", d = ".arkher.lua (completo)" },
		{ id = "printmap", nm = "Print Map", d = "vista de cima (2D)" },
		{ id = "json", nm = "JSON raw", d = "snapshot puro" },
	}
	local curFmt = 1
	for i, f in ipairs(fmts) do
		local row = K.btn(left, "F" .. i, 8, 26 + (i - 1) * 44, 114, 38, T.bg2, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, f.nm, 8, 4, 100, 14, 10, T.txt)
		K.txt(row, f.d, 8, 20, 100, 16, 8, T.txt4)
		local idx = i
		row.MouseButton1Click:Connect(function()
			curFmt = idx
			for j = 1, #fmts do
				K.stroke(left:FindFirstChild("F" .. j), j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			renderPreview()
		end)
	end
	K.row(left, "Tamanho est.", "14.2 KB", 170)
	K.row(left, "Compressao", "gzip op.", 194)

	-- ===== CENTRO: PREVIEW (PRINT MAP DO WORLD REAL) =====
	local cv = K.f(root, "Prev", 150, 34, 262, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PREVIEW", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local mapArea = K.f(cv, "Map", 8, 22, 246, 220)
	local function renderPreview()
		for _, ch in ipairs(mapArea:GetChildren()) do ch:Destroy() end
		-- grade
		for i = 1, 11 do
			K.f(mapArea, "gx" .. i, i * 22, 0, 1, 220, T.bg3)
			K.f(mapArea, "gy" .. i, 0, i * 20, 246, 1, T.bg3)
		end
		-- desenha o workspace de cima: 1 part = 1 quadrado (pos XZ -> 2D)
		local n = 0
		local function drawPart(inst)
			n = n + 1
			local px2, pz2
			local okp, p = pcall(function() return inst.Position end)
			if okp and p and p.X then
				px2, pz2 = p.X, p.Z
			else
				px2, pz2 = math.random(-100, 100), math.random(-100, 100)
			end
			local sx = math.floor(123 + px2 * 0.9)
			local sy = math.floor(110 + pz2 * 0.9)
			if sx < 2 or sx > 240 or sy < 2 or sy > 214 then return end
			local col = T.sec
			if inst.ClassName == "BasePart" then
				local okc, c3 = pcall(function() return inst.Color end)
				if okc and c3 then col = c3 end
			end
			if n <= 40 then
				K.f(mapArea, "P" .. n, sx, sy, 8, 8, col, 1)
			end
		end
		for _, ch in ipairs(workspace:GetDescendants()) do
			local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
			if ok and isPart and ch.Name ~= "Terrain" then
				drawPart(ch)
				if n >= 40 then break end
			end
		end
		if n == 0 then
			K.txt(mapArea, "(workspace vazio)", 90, 100, 120, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
		end
		K.txt(mapArea, n .. " parts mapeadas", 4, 206, 200, 14, 9, T.txt4)
	end
	renderPreview()

	-- ===== DIREITA: EXPORTAR =====
	local right = K.f(root, "Exp", 424, 34, 128, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "EXPORTAR", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local exp = K.btn(right, "Exp", 10, 28, 108, 30, ACCENT, 5)
	local expIc = K.f(exp, "Ic", 6, 5, 20, 20)
	ICON.save(expIc)
	K.txt(exp, "EXPORTAR", 30, 0, 76, 30, 11, C("#200804"), ARKHER.FONTB)
	K.hover(exp, ACCENT, C("#FF907F"))
	exp.MouseButton1Click:Connect(function()
		if curFmt == 1 then
			ArkherPlaces.exportToFile()
		elseif curFmt == 3 then
			local Http = game:GetService("HttpService")
			local snap = ArkherPlaces.snapshot()
			local ok, path = pcall(function()
				if game.WriteFile and snap then
					game:WriteFile("ArkherExports/snapshot_raw.json", Http:JSONEncode(snap))
					return "ArkherExports/snapshot_raw.json"
				end
				return nil
			end)
			if ok and path then
				ARKHER.out("SUCCESS", "Export: JSON raw em " .. path)
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		else
			local lines = { "-- PRINT MAP ARKHER" }
			for _, ch in ipairs(workspace:GetDescendants()) do
				local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
				if ok and isPart then
					local okp, p = pcall(function() return ch.Position end)
					if okp and p then
						table.insert(lines, string.format("%s (%.0f, %.0f, %.0f)", ch.Name, p.X or 0, p.Y or 0, p.Z or 0))
					end
				end
			end
			local ok, path = pcall(function()
				if game.WriteFile then
					game:WriteFile("ArkherExports/print_map.txt", table.concat(lines, "\n"))
					return path or "ArkherExports/print_map.txt"
				end
				return nil
			end)
			if ok then
				ARKHER.out("SUCCESS", "Export: print map com " .. (#lines - 1) .. " parts")
				K.notify("Print map", #lines - 1 .. " parts exportadas", "ok")
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		end
		K.progress(right, 10, 70, 108, 1, ACCENT)
	end)
	K.row(right, "Destino", "disco", 110)
	K.row(right, "Permissao", "Studio", 134)
	K.txt(right, "no Roblox (play):\nusa clipboard", 10, 160, 110, 30, 8, T.txt4)
	K.row(right, "Ultimo", "ha 2 min", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Local", "ArkherPlaces/ + ArkherExports/", 8)
	K.row(bar, "Versionado", "sim (id por save)", 34)
	K.txt(bar, "o bundle contem workspace + lighting + scripts + metadata — restaura tudo", 12, 60, 420, 14, 9, T.txt4)
	K.txt(bar, "v3.0.0", 480, 64, 60, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("SaveExport", "Export", "System", ICON.share, "Exportacao: bundle, print map 2D do world real e JSON", build)
