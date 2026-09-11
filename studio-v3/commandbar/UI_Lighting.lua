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
--[[ ARKHER V3 — UI: LIGHTING ]]
-- Layout unico: knobs de sol/ambiente a esquerda, faixa HORA DO DIA clicavel
-- no centro (mexe o ceu + posicao do sol no preview), cores e toggles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD93D")

local SKY_STEPS = {
	{ nm = "Noite", sky = C("#0B1026"), sun = C("#B0BEC5"), y = 78, x = 40 },
	{ nm = "Amanhecer", sky = C("#3E2748"), sun = C("#FF9770"), y = 60, x = 80 },
	{ nm = "Manha", sky = C("#4A78A8"), sun = C("#FFD93D"), y = 34, x = 120 },
	{ nm = "Meio-dia", sky = C("#5B9BD5"), sun = C("#FFF176"), y = 14, x = 160 },
	{ nm = "Tarde", sky = C("#4A6FA5"), sun = C("#FFCA28"), y = 40, x = 200 },
	{ nm = "Pôr do sol", sky = C("#5D3A4E"), sun = C("#FF7043"), y = 62, x = 240 },
	{ nm = "Anoitecer", sky = C("#2A2440"), sun = C("#FF8A65"), y = 78, x = 280 },
	{ nm = "Meia-noite", sky = C("#070B1A"), sun = C("#90A4AE"), y = 84, x = 320 },
}

local function build()
	local g, root, head = K.window("ArkherLighting", "LIGHTING — hora do dia", 24, 360, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local step = 4

	-- ===== ESQUERDA: KNOBS =====
	local left = K.f(root, "Knobs", 8, 34, 132, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SOL", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 22, 60, (step - 1) / 7, "35deg")
	K.txt(left, "AMBIENTE", 10, 96, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 112, 60, 0.45, "0.45")
	K.txt(left, "EXPOSICAO", 10, 184, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 200, 60, 0.5, "1.0x")

	-- ===== CENTRO: PREVIEW DO CEU + FAIXA =====
	local cv = K.f(root, "Sky", 152, 34, 264, 150, C("#5B9BD5"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- nuvens
	K.f(cv, "Cl1", 30, 20, 54, 14, C("#FFFFFF"), 7)
	K.f(cv, "Cl2", 150, 34, 70, 16, C("#F5F7FA"), 8)
	K.f(cv, "Cl3", 90, 58, 40, 10, C("#FFFFFF"), 5)
	-- terreno
	K.f(cv, "Hil", 0, 108, 264, 42, C("#1B2B22"))
	local hill = K.f(cv, "Hill", 60, 92, 140, 26, C("#16241C"))
	hill.Rotation = -3
	-- sol/lua (move com a hora)
	local sun = K.f(cv, "SunObj", SKY_STEPS[step].x, SKY_STEPS[step].y, 20, 20, SKY_STEPS[step].sun, 10)
	K.txt(cv, SKY_STEPS[step].nm, 8, 128, 120, 18, 11, T.txt, ARKHER.FONTB)

	-- faixa hora do dia (clicavel)
	local strip = K.f(root, "Strip", 152, 196, 264, 34, T.bg0)
	K.corner(strip, 4)
	for i, s in ipairs(SKY_STEPS) do
		local b = K.f(strip, "S" .. i, (i - 1) * 33, 4, 31, 26, s.sky, 2)
		K.txt(b, s.nm, 0, 14, 31, 10, 7, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		b.MouseButton1Click:Connect(function()
			step = idx
			cv.BackgroundColor3 = s.sky
			sun.Position = UDim2.new(0, s.x, 0, s.y)
			sun.BackgroundColor3 = s.sun
			ARKHER.out("INFO", "Lighting: " .. s.nm)
		end)
	end

	-- ===== DIREITA: CORES + TOGGLES =====
	local right = K.f(root, "Cols", 428, 34, 124, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "CORES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local colors = {
		{ "Sky", C("#5B9BD5") }, { "Cloud", C("#F5F7FA") },
		{ "Shadow", C("#3E5C76") }, { "Fog", C("#B0C4DE") },
	}
	for i, c2 in ipairs(colors) do
		K.row(right, c2[1], "", 26 + (i - 1) * 24)
		local sw = K.f(right, "CSw" .. i, 78, 26 + (i - 1) * 24, 34, 16, c2[2], 3)
		K.stroke(sw, T.line2, 1)
	end
	K.checkRow(right, "Sombras", true, 126)
	K.checkRow(right, "Fog", false, 150)
	K.checkRow(right, "Global light", true, 174)
	K.checkRow(right, "Post FX", true, 198)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 90, T.bg0)
	K.corner(bar, 4)
	local create = K.btn(bar, "Create", 10, 10, 140, 26, ACCENT, 5)
	K.txtS(create, "Criar luz no Place", 10, C("#1A1403"))
	K.hover(create, ACCENT, C("#FFE57A"))
	create.MouseButton1Click:Connect(function()
		local ws = workspace
		if ws:FindFirstChild("ArkherLighting") then ws:FindFirstChild("ArkherLighting"):Destroy() end
		local f = Instance.new("Folder")
		f.Name = "ArkherLighting"
		f:SetAttribute("Hora", SKY_STEPS[step].nm)
		f:SetAttribute("Sol", 35)
		f.Parent = ws
		ARKHER.out("SUCCESS", "Lighting: luz " .. SKY_STEPS[step].nm .. " criada no place")
	end)
	K.txt(bar, "sun: " .. SKY_STEPS[step].nm, 170, 16, 180, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 524, (step - 1) / 7, ACCENT)
	K.txt(bar, "ciclo: 0h -> " .. ((step - 1) * 3) .. "h", 170, 58, 200, 14, 9, T.txt4)
end

ARKHER.reg("Lighting", "Lighting", "Scene", ICON.bulb, "Iluminacao: hora do dia interativa, sol, cores e post FX", build)
end

ARKHER.open("Lighting")
