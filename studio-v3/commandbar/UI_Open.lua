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
--[[ ARKHER V3 — UI: OPEN ]]
-- Layout unico: busca + arvore de pastas a esquerda, GRID de thumbnails
-- (K.thumb) no centro, painel de detalhes a direita — o browser completo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#70A1FF")

local function build()
	local g, root, head = K.window("ArkherOpen", "OPEN — browser de places", 24, 510, 572, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	-- ===== ESQUERDA: PASTAS =====
	local left = K.f(root, "Tree", 8, 34, 118, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "LOCAL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local folders = {
		{ nm = "Places", n = true },
		{ nm = "Maps" },
		{ nm = "Console" },
		{ nm = "Exports" },
	}
	for i, f in ipairs(folders) do
		local row = K.treeRow(left, 0, ICON.folder, f.nm, f.n, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Open: pasta " .. f.nm)
		end)
	end
	K.txt(left, "ServerStorage/\nArkherCloud/", 10, 140, 100, 30, 8, T.txt4)
	local newB = K.btn(left, "NewB", 10, 200, 98, 22, T.bg2, 4)
	K.txtS(newB, "+ novo", 9, T.txt)
	K.hover(newB, T.bg2, T.hover)
	newB.MouseButton1Click:Connect(function()
		ArkherPlaces.new("Empty")
	end)

	-- ===== TOPO: BUSCA =====
	K.search(root, 138, 34, 240, 24, "buscar place...")
	local sortB = K.btn(root, "Sort", 386, 34, 90, 24, T.bg4, 4)
	K.txtS(sortB, "ordem: size", 9, T.txt3)
	K.hover(sortB, T.bg4, T.hover)

	-- ===== CENTRO: GRID DE THUMBS =====
	local grid = K.f(root, "Grid", 138, 66, 240, 218, T.bg0)
	K.corner(grid, 4)
	K.stroke(grid, T.line, 1)
	local cards = K.f(grid, "Cards", 0, 0, 240, 218)
	local selCard = nil
	local function renderGrid()
		for _, ch in ipairs(cards:GetChildren()) do ch:Destroy() end
		local list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(cards, "(nada para abrir\nsalve um place primeiro)", 80, 90, 160, 40, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
			return
		end
		for i, p in ipairs(list) do
			if i > 4 then break end
			local r, c = math.floor((i - 1) / 2) + 1, ((i - 1) % 2) + 1
			local th = K.thumb(cards, 8 + (c - 1) * 118, 8 + (r - 1) * 106, 108, 96,
				tostring(p.name), C("#243447"), C("#18222E"))
			K.txt(th, "#" .. tostring(p.id), 4, 6, 60, 14, 9, T.neon)
			K.txt(th, string.format("%.1fK", (p.bytes or 0) / 1024), 66, 6, 38, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
			local pid = p.id
			th.MouseButton1Click:Connect(function()
				selCard = th
				detId.Text = "#" .. tostring(pid)
				detName.Text = tostring(p.name)
				detBytes.Text = string.format("%.1f KB", (p.bytes or 0) / 1024)
			end)
		end
	end
	renderGrid()

	-- ===== DIREITA: DETALHES =====
	local right = K.f(root, "Det", 390, 34, 174, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "DETALHES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local detName = K.txt(right, "—", 10, 28, 154, 18, 12, T.txt, ARKHER.FONTB)
	local detId = K.txt(right, "id: —", 10, 50, 154, 14, 10, T.neon)
	local detBytes = K.txt(right, "0 KB", 10, 68, 154, 14, 10, T.txt3)
	K.row(right, "Criado", "sessao atual", 96)
	K.row(right, "Modificado", "agora", 120)
	K.row(right, "Integridade", "100%", 144)
	local openB = K.btn(right, "OpenB", 10, 172, 154, 30, ACCENT, 5)
	K.txtS(openB, "ABRIR PLACE", 11, C("#0A1424"))
	K.hover(openB, ACCENT, C("#A6C2FF"))
	openB.MouseButton1Click:Connect(function()
		local id = tonumber(string.match(detId.Text, "%d+"))
		if id then
			ArkherPlaces.open(id)
			K.notify("Place aberto", detName.Text, "ok")
		else
			ARKHER.out("WARNING", "Open: selecione um place no grid")
		end
	end)
	local back = K.btn(right, "Back", 10, 210, 154, 22, T.bg2, 4)
	K.txtS(back, "voltar ao editor", 9, T.txt)
	K.hover(back, T.bg2, T.hover)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 556, 88, T.bg0)
	K.corner(bar, 4)
	local list = ArkherPlaces.list()
	K.row(bar, "Places", tostring(#list), 8)
	K.row(bar, "Pasta atual", "ArkherCloud/Places", 34)
	K.txt(bar, "clique na thumb para ver detalhes | duplo fluxo: abrir ou exportar", 200, 16, 340, 14, 9, T.txt4)
	K.progress(bar, 200, 46, 300, 0.6, ACCENT)
	K.txt(bar, "186 MB livres", 510, 52, 46, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Open", "Open", "System", ICON.open, "Browser de places: busca, grid de thumbs, detalhes e abrir", build)
end

ARKHER.open("Open")
