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
--[[ ARKHER V3 — UI: CAMERA ]]
-- Layout unico: lista de modos de vista a esquerda, preview com cone de FOV
-- que MUDA ao clicar nos botoes +/-, knobs de FOV/velocidade a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6B81")

local function build()
	local g, root, head = K.window("ArkherCamera", "CAMERA — rig & view", 24, 350, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local fov = 70
	local speed = 16

	-- ===== ESQUERDA: MODOS =====
	local left = K.f(root, "Modes", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MODOS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local modes = { "Orbit", "Free", "Cinematic", "Drone", "Follow", "Top" }
	for i, m in ipairs(modes) do
		local row = K.treeRow(left, 0, i == 3 and ICON.camera or ICON.select, m, i == 3, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Camera: modo " .. m)
		end)
	end
	K.txt(left, "Cinematic ativo", 10, 172, 110, 24, 9, ACCENT)

	-- ===== CENTRO: PREVIEW COM CONE DE FOV =====
	local cv = K.f(root, "Prev", 142, 34, 268, 200, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- ceu/terreno
	K.f(cv, "Sky", 0, 0, 268, 108, C("#12233D"))
	K.f(cv, "Gnd", 0, 108, 268, 92, C("#1B2B22"))
	-- sol
	K.f(cv, "Sun", 200, 24, 14, 14, C("#FFD93D"), 7)
	-- montanhas (frames rotacionados)
	local m1 = K.f(cv, "M1", 20, 78, 90, 30, C("#0E1A2B"))
	m1.Rotation = -8
	local m2 = K.f(cv, "M2", 150, 70, 110, 38, C("#101E30"))
	m2.Rotation = 5
	-- objeto alvo
	K.f(cv, "Tgt", 128, 128, 14, 26, ACCENT)
	K.txt(cv, "alvo", 118, 156, 36, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	-- cone de FOV (2 linhas rotacionadas a partir do olho)
	local coneLines = {}
	local fovLbl = K.txt(cv, "70 FOV", 8, 180, 80, 16, 10, ACCENT)
	local function drawCone()
		for _, l in ipairs(coneLines) do l:Destroy() end
		coneLines = {}
		local ang = fov * 0.42
		for _, s in ipairs({ -1, 1 }) do
			local l = K.f(cv, "C", 135, 140, 150, 2, ACCENT)
			l.Rotation = s * ang
			l.AnchorPoint = Vector2.new(0, 0.5)
			table.insert(coneLines, l)
		end
		local eye = K.f(cv, "Eye", 131, 136, 8, 8, T.neon, 4)
		table.insert(coneLines, eye)
		fovLbl.Text = fov .. " FOV"
	end
	drawCone()

	-- ===== DIREITA: AJUSTES =====
	local right = K.f(root, "Adj", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "FOV", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	local minus = K.btn(right, "M-", 10, 24, 52, 22, T.bg2, 4)
	K.txtS(minus, "-", 12, T.txt)
	K.hover(minus, T.bg2, T.hover)
	local plus = K.btn(right, "M+", 72, 24, 52, 22, T.bg2, 4)
	K.txtS(plus, "+", 12, T.txt)
	K.hover(plus, T.bg2, T.hover)
	minus.MouseButton1Click:Connect(function()
		fov = math.max(20, fov - 5)
		drawCone()
	end)
	plus.MouseButton1Click:Connect(function()
		fov = math.min(120, fov + 5)
		drawCone()
	end)
	K.knob(right, 38, 58, 54, fov / 120, math.floor(fov / 120 * 100 + 0.5) .. "%")
	K.txt(right, "VELOCIDADE", 10, 138, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 38, 156, 54, speed / 40, speed .. " u/s")
	K.row(right, "Zoom", "2.4", 216)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 76, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Rig", "CinematicCam", 8)
	K.row(bar, "Tracking", "Player", 34)
	local apply = K.btn(bar, "Apply", 300, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar ao Place", 10, C("#1C070C"))
	K.hover(apply, ACCENT, C("#FF97A8"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Camera: rig CinematicCam (fov " .. fov .. ", " .. speed .. "u/s) aplicado")
		Bus.emit("camera.apply", { fov = fov, speed = speed, mode = "Cinematic" })
	end)
	K.txt(bar, "lens: 35mm equiv", 430, 28, 104, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Rig de camera: modos, FOV interativo, tracking e preview", build)
end

ARKHER.open("Camera")
