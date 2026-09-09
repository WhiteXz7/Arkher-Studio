--[[ ARKHER V3 — UI: AUDIO ]]
-- Layout unico: lista de faixas com FORMAS DE ONDA (K.wave) a esquerda,
-- detalhe da faixa selecionada no centro, mixer com VERTICAIS (K.vfader) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#A29BFE")

local TRACKS = {
	{ nm = "Theme_01", len = "2:34", seed = 11, vol = 0.8, kind = "Music" },
	{ nm = "City_amb", len = "4:10", seed = 23, vol = 0.55, kind = "Ambience" },
	{ nm = "UI_click", len = "0:01", seed = 37, vol = 0.7, kind = "SFX" },
	{ nm = "Boss_roar", len = "0:04", seed = 53, vol = 0.9, kind = "SFX" },
}

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO — mixer & faixas", 24, 370, 560, 372, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local sel = 1

	-- ===== ESQUERDA: FAIXAS =====
	local left = K.f(root, "Tracks", 8, 34, 150, 260, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FAIXAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, tr in ipairs(TRACKS) do
		local row = K.f(left, "Tr" .. i, 6, 26 + (i - 1) * 56, 138, 50, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, tr.nm, 6, 4, 90, 14, 10, T.txt)
		K.txt(row, tr.kind .. " | " .. tr.len, 6, 18, 120, 12, 8, T.txt4)
		K.wave(row, 6, 32, 100, 14, tr.seed, i == 1 and ACCENT or T.txt4)
		K.txt(row, math.floor(tr.vol * 100 + 0.5) .. "%", 110, 34, 26, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
		local idx = i
		row.MouseButton1Click:Connect(function()
			sel = idx
			ARKHER.out("INFO", "Audio: selecionada " .. tr.nm)
		end)
	end

	-- ===== CENTRO: DETALHE =====
	local cv = K.f(root, "Detail", 170, 34, 244, 160, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, TRACKS[1].nm, 10, 8, 160, 16, 12, T.txt, ARKHER.FONTB)
	K.txt(cv, "Music | 2:34 | 44.1kHz", 10, 26, 180, 14, 9, T.txt4)
	K.wave(cv, 10, 48, 224, 56, 11, ACCENT)
	-- seek
	local seek, seekFill = K.progress(cv, 10, 116, 180, 0.36, ACCENT)
	K.txt(cv, "0:54", 196, 110, 36, 14, 9, T.txt3)
	-- controles
	local pl = K.btn(cv, "Pl", 10, 134, 44, 22, T.bg2, 4)
	K.txtS(pl, "Play", 10, T.txt)
	K.hover(pl, T.bg2, T.hover)
	pl.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: tocando " .. TRACKS[sel].nm)
	end)
	local pp = K.btn(cv, "Pp", 60, 134, 44, 22, T.bg2, 4)
	K.txtS(pp, "Stop", 10, T.txt)
	K.hover(pp, T.bg2, T.hover)
	pp.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: parado")
	end)

	-- ===== DIREITA: MIXER =====
	local right = K.f(root, "Mixer", 426, 34, 126, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MIXER", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local chans = { "MUS", "SFX", "AMB" }
	local vols = { 0.8, 0.7, 0.55 }
	for i = 1, 3 do
		K.vfader(right, 18 + (i - 1) * 36, 28, 150, vols[i], chans[i])
	end
	K.txt(right, "MASTER", 10, 192, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.vfader(right, 30, 208, 40, 0.75, "M")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 60, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Loop", true, 8)
	K.sliderRow(bar, "Master vol", 0.75, 34)
	local add = K.btn(bar, "Add", 300, 16, 90, 28, ACCENT, 5)
	K.txtS(add, "+ faixa", 11, C("#12102A"))
	K.hover(add, ACCENT, C("#C3BFFF"))
	add.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Audio: faixa 'Nova' adicionada ao mixer")
	end)
	K.txt(bar, "3 canais | 44.1k | 16bit", 410, 22, 130, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Audio", "Audio", "Scene", ICON.data, "Mixer de audio: faixas com waveforms, seek e canais verticais", build)
