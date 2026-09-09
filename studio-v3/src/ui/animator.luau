--[[ ARKHER V3 — UI: ANIMATOR ]]
-- Layout unico: lista de poses a esquerda, preview do personagem no centro,
-- timeline real com keytracks (K.keyTrack) + scrub + controles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF9F43")

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR — timeline & poses", 24, 300, 540, 392, { pin = true })

	-- acento na head
	K.f(head, "Acc", 0, 24, 540, 2, ACCENT)

	-- ===== PAINEL ESQUERDO: POSES =====
	local left = K.f(root, "Poses", 8, 34, 122, 300, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POSES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local poses = { "Pose Inicial", "Andar", "Correr", "Pulo", "Ataque" }
	local selPose = 1
	for i, p in ipairs(poses) do
		local row = K.treeRow(left, 0, i == 1 and ICON.play or ICON.pause, p, i == 1, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			selPose = i
			ARKHER.out("INFO", "Animator: pose selecionada: " .. p)
		end)
	end
	K.txt(left, "clique = trocar pose", 8, 160, 110, 30, 9, T.txt4)

	-- ===== CENTRO: PREVIEW =====
	local pv = K.f(root, "Preview", 140, 34, 250, 150, T.dark)
	K.corner(pv, 4)
	K.stroke(pv, T.line, 1)
	-- grade
	for i = 1, 7 do
		K.f(pv, "gx" .. i, i * 34, 0, 1, 150, T.bg3)
		K.f(pv, "gy" .. i, 0, i * 21, 250, 1, T.bg3)
	end
	-- silhueta humanoide (frames)
	local bx = 105
	K.f(pv, "Head", bx, 34, 22, 22, ACCENT, 6)
	K.f(pv, "Torso", bx + 2, 58, 18, 34, T.neon)
	K.f(pv, "ArmL", bx - 10, 58, 8, 30, T.neon)
	K.f(pv, "ArmR", bx + 24, 58, 8, 30, T.neon)
	K.f(pv, "LegL", bx + 2, 94, 7, 34, T.neon)
	K.f(pv, "LegR", bx + 13, 94, 7, 34, T.neon)
	local poseLbl = K.txt(pv, "Pose: Andar", 8, 130, 120, 16, 10, T.txt3)
	-- sombra
	K.f(pv, "Shadow", bx - 12, 130, 58, 5, T.bg0, 2)

	-- ===== CENTRO-BAIXO: TIMELINE =====
	local tl = K.f(root, "Timeline", 140, 194, 392, 140, T.bg0)
	K.corner(tl, 4)
	K.txt(tl, "TIMELINE", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.keyTrack(tl, "Position", 24, { 0, 0.28, 0.62, 0.9 }, ACCENT)
	K.keyTrack(tl, "Rotation", 46, { 0.15, 0.55, 0.78 }, C("#FFD93D"))
	K.keyTrack(tl, "Scale", 68, { 0.5, 0.52 }, C("#74B9FF"))
	-- scrub
	local playLbl = K.btn(tl, "Play", 8, 96, 52, 20, T.bg2, 4)
	K.txtS(playLbl, "Play", 10, T.txt)
	K.hover(playLbl, T.bg2, T.hover)
	local playing = false
	playLbl.MouseButton1Click:Connect(function()
		playing = not playing
		playLbl.Text = ""
		K.txt(playLbl, playing and "Pause" or "Play", 0, 0, 52, 20, 10, T.txt, FONTB, Enum.TextXAlignment.Center)
		ARKHER.out(playing and "SUCCESS" or "INFO", "Animator: " .. (playing and "tocando" or "pausado") .. " — " .. poses[selPose])
	end)
	local scrub, scrubFill = K.progress(tl, 70, 104, 310, 0.32, ACCENT)
	local tLbl = K.txt(tl, "0.96s / 3.00s", 70, 122, 150, 14, 9, T.txt4)
	-- marcadores de tempo
	for i = 0, 10 do
		K.txt(tl, tostring(i) .. ".0", 70 + i * 31, 116, 20, 10, 7, T.txt4)
	end
	-- zoom
	K.txt(tl, "zoom x1", 330, 122, 40, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrls", 442, 34, 90, 300, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AJUSTES", 10, 6, 70, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(right, "Duracao", 0.34, 26)
	K.sliderRow(right, "Ease", 0.5, 52)
	K.checkRow(right, "Loop", true, 80)
	K.checkRow(right, "Fade in", true, 104)
	K.row(right, "Frames", "90 @ 30fps", 130)
	local bake = K.btn(right, "Bake", 10, 158, 70, 24, ACCENT, 5)
	K.txtS(bake, "BAKE", 11, C("#14100C"))
	K.hover(bake, ACCENT, C("#FFB86B"))
	bake.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Animator: " .. poses[selPose] .. " baked (90 frames, 3.0s)")
		K.notify("Bake concluido", poses[selPose] .. " -> AnimationTrack", "ok")
		Bus.emit("animator.bake", { pose = poses[selPose], frames = 90 })
	end)
	K.row(right, "Size", "1.2 KB", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 344, 524, 40, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "4 keyframes", 12, 6, 90, 14, 9, T.txt3)
	K.txt(bar, "3 tracks", 110, 6, 70, 14, 9, T.txt3)
	K.txt(bar, "30 fps", 188, 6, 60, 14, 9, T.txt3)
	K.txt(bar, "Andar.anim", 256, 6, 100, 14, 9, ACCENT)
	K.txt(bar, "pronto", 480, 6, 40, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Animator", "Animator", "Editor", ICON.play, "Timeline de animacao: poses, keyframes, scrub e bake", build)
