--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER V3 — UI: MODELER ]]
-- Layout unico: paleta vertical de ferramentas (modo polygonal), canvas com
-- malha low-poly interativa (vertices selecionaveis), stats + UV grid a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#4DFFDB")

local function build()
	local g, root, head = K.window("ArkherModeler", "MODELER — polygonal", 24, 310, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== PALETA VERTICAL DE FERRAMENTAS =====
	local tools = {
		{ ic = ICON.select, nm = "Select" },
		{ ic = ICON.move, nm = "Move" },
		{ ic = ICON.scaleI, nm = "Scale" },
		{ ic = ICON.rotate, nm = "Rotate" },
		{ ic = ICON.transform, nm = "Gizmo" },
	}
	local curTool = 1
	local pal = K.f(root, "Pal", 8, 34, 46, 330, T.bg4)
	K.corner(pal, 4)
	for i, tl in ipairs(tools) do
		local b = K.btn(pal, "T" .. i, 5, 8 + (i - 1) * 46, 36, 36, i == 1 and T.bg2 or T.bg4, 5)
		tl.ic(b, 18)
		K.hover(b, T.bg4, T.hover)
		local idx = i
		b.MouseButton1Click:Connect(function()
			curTool = idx
			for j = 1, #tools do
				local bb = pal:FindFirstChild("T" .. j)
				if bb then
					bb.BackgroundColor3 = j == idx and T.bg2 or T.bg4
					if bb:FindFirstChild("Acc") then bb:FindFirstChild("Acc"):Destroy() end
					if j == idx then K.stroke(bb, ACCENT, 1.5) end
				end
			end
			ARKHER.out("INFO", "Modeler: ferramenta " .. tl.nm)
		end)
	end
	K.txt(pal, "MODO", 2, 250, 42, 12, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(pal, "VERTEX", 2, 262, 42, 24, 8, ACCENT, FONT, Enum.TextXAlignment.Center)

	-- ===== TABS SUPERIORES =====
	K.tabs(root, 66, 34, 300, { "Objetos", "Materiais", "UV" }, 1)

	-- ===== CANVAS DE MALHA =====
	local cv = K.f(root, "Canvas", 66, 60, 330, 260, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 9 do K.f(cv, "gx" .. i, i * 33, 0, 1, 260, T.bg3) end
	for i = 1, 8 do K.f(cv, "gy" .. i, 0, i * 32, 330, 1, T.bg3) end
	-- malha low-poly: cubo isometrico (faces)
	local faces = {
		{ x = 90, y = 90, w = 75, h = 40, c = C("#2E5E54") }, -- top
		{ x = 90, y = 130, w = 75, h = 60, c = C("#1F423C") }, -- front
		{ x = 165, y = 112, w = 60, h = 78, c = C("#284F48") }, -- side
	}
	for i, f in ipairs(faces) do
		local fc = K.f(cv, "F" .. i, f.x, f.y, f.w, f.h, f.c)
		K.stroke(fc, ACCENT, 0.8)
	end
	-- janelas
	K.f(cv, "W1", 105, 145, 14, 14, ACCENT)
	K.f(cv, "W2", 133, 145, 14, 14, ACCENT)
	K.f(cv, "W3", 180, 130, 12, 12, C("#4DFFDB"))
	-- vertices (interativos)
	local vpos = {
		{ 90, 90 }, { 165, 90 }, { 225, 112 }, { 165, 112 },
		{ 90, 130 }, { 165, 130 }, { 225, 190 }, { 165, 190 }, { 90, 190 },
	}
	local selVerts = {}
	local selLbl
	for i, p in ipairs(vpos) do
		local d = K.f(cv, "V" .. i, p[1] - 4, p[2] - 4, 8, 8, T.bg0, 4)
		K.stroke(d, ACCENT, 1.5)
		local vi = i
		d.MouseButton1Click:Connect(function()
			if selVerts[vi] then
				selVerts[vi] = nil
				d.BackgroundColor3 = T.bg0
			else
				selVerts[vi] = true
				d.BackgroundColor3 = ACCENT
			end
			local n = 0
			for _ in pairs(selVerts) do n = n + 1 end
			if selLbl then selLbl.Text = tostring(n) .. " vertices" end
		end)
	end
	selLbl = K.txt(cv, "0 vertices", 10, 236, 120, 16, 10, ACCENT)

	-- ===== DIREITA: STATS + UV =====
	local right = K.f(root, "Stats", 408, 60, 144, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MESH", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Verts", "9", 26)
	K.row(right, "Edges", "14", 50)
	K.row(right, "Faces", "5", 74)
	K.row(right, "Tris", "8", 98)
	K.txt(right, "UV GRID", 10, 128, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i = 1, 6 do
		for j = 1, 4 do
			local on = (i == 2 and j == 2) or (i == 3 and j == 2)
			K.f(right, "UV_" .. i .. "_" .. j, 10 + (j - 1) * 30, 148 + (i - 1) * 22, 26, 18, on and ACCENT or T.bg0)
			K.stroke(right:FindFirstChild("UV_" .. i .. "_" .. j), T.line, 0.6)
		end
	end
	local weld = K.btn(right, "Weld", 10, 226, 60, 22, ACCENT, 4)
	K.txtS(weld, "Weld", 10, C("#0B1410"))
	K.hover(weld, ACCENT, C("#8DFFE8"))
	weld.MouseButton1Click:Connect(function()
		local n = 0
		for _ in pairs(selVerts) do n = n + 1 end
		ARKHER.out("SUCCESS", "Modeler: " .. math.max(n, 1) .. " vertices soldados")
		K.notify("Weld aplicado", "malha otimizada", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 334, 544, 58, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Snap 1u", true, 8)
	K.checkRow(bar, "Grid 33u", true, 34)
	K.txt(bar, "modo: " .. tools[curTool].nm, 220, 14, 110, 20, 10, ACCENT)
	K.txt(bar, "Buildings/1.fbx", 400, 14, 130, 20, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Modeler", "Modeler", "Editor", ICON.cubeW, "Modelagem polygonal: ferramentas, malha, vertices e UV", build)
end

ARKHER.open("Modeler")
