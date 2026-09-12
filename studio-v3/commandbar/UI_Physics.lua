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
--[[ ARKHER V3 — UI: PHYSICS ]]
-- Layout unico: parametros globais a esquerda, GRID DE COLISAO interativo
-- (clique liga/desliga collider) no centro, lista de joints a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FD9644")

local function build()
	local g, root, head = K.window("ArkherPhysics", "PHYSICS — colliders & joints", 24, 380, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local colliders = {}
	for i = 1, 144 do
		local s = (i * 16807) % 2147483647
		colliders[i] = (s % 5) < 2
	end
	local onCount = 0
	for _, v in ipairs(colliders) do if v then onCount = onCount + 1 end end

	-- ===== ESQUERDA: PARAMETROS =====
	local left = K.f(root, "Params", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MUNDO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(left, "Gravidade", 0.7, 26)
	K.row(left, "", "196.2 m/s2", 52)
	K.sliderRow(left, "Time scale", 1.0, 80)
	K.row(left, "", "x1.0", 106)
	K.sliderRow(left, "Frequencia", 0.5, 134)
	K.row(left, "", "60 Hz", 160)
	K.checkRow(left, "Sleep mode", true, 190)
	K.checkRow(left, "CCD", false, 214)

	-- ===== CENTRO: GRID DE COLISAO =====
	local cv = K.f(root, "Grid", 150, 34, 264, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "colisao (clique = liga/desliga)", 8, 230, 240, 14, 9, T.txt4)
	local dots = {}
	for i = 1, 144 do
		local r, c = math.floor((i - 1) / 12) + 1, ((i - 1) % 12) + 1
		local d = K.f(cv, "D" .. i, (c - 1) * 21 + 8, (r - 1) * 18 + 10, 9, 9, colliders[i] and ACCENT or T.bg3, 4)
		dots[i] = d
		local idx = i
		d.MouseButton1Click:Connect(function()
			colliders[idx] = not colliders[idx]
			d.BackgroundColor3 = colliders[idx] and ACCENT or T.bg3
			if colliders[idx] then onCount = onCount + 1 else onCount = onCount - 1 end
			cntLbl.Text = onCount .. " colliders ativos"
		end)
	end
	local cntLbl = K.txt(cv, onCount .. " colliders ativos", 8, 216, 180, 14, 10, ACCENT)

	-- ===== DIREITA: JOINTS =====
	local right = K.f(root, "Joints", 426, 34, 126, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "JOINTS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(right, 0, ICON.ws, "Weld_Constraint", "ok", 26)
	K.treeRow(right, 1, nil, "Part1 <-> Part2", nil, 50)
	K.treeRow(right, 0, ICON.ws, "Motor6D", "ok", 74)
	K.treeRow(right, 1, nil, "Leg (hip)", nil, 98)
	K.treeRow(right, 0, ICON.ws, "SpringWire", nil, 122)
	local addJ = K.btn(right, "AddJ", 10, 150, 106, 22, T.bg2, 4)
	K.txtS(addJ, "+ joint", 10, T.txt)
	K.hover(addJ, T.bg2, T.hover)
	local joints = 3
	addJ.MouseButton1Click:Connect(function()
		joints = joints + 1
		ARKHER.out("INFO", "Physics: joint #" .. joints .. " criado")
	end)
	K.row(right, "Solver", "2 iter", 190)
	K.row(right, "Mass total", "412 kg", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Centro de massa", "(0, 3.2, 0)", 8)
	K.row(bar, "Velocidade media", "0.4 u/s", 34)
	local apply = K.btn(bar, "Apply", 320, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar fisico", 10, C("#241102"))
	K.hover(apply, ACCENT, C("#FFB87A"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Physics: " .. onCount .. " colliders + " .. joints .. " joints aplicados")
		Bus.emit("physics.apply", { colliders = onCount, joints = joints })
	end)
	K.txt(bar, "solver: v2", 450, 28, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Physics", "Physics", "Scene", ICON.ws, "Fisica: grid de colisao interativo, joints e parametros do mundo", build)
end

ARKHER.open("Physics")
