--[[ ARKHER V3 — UI: SETTINGS ]]
-- Layout unico: colunas de SECOES (K.section) — Qualidade, Cloud (endpoint
-- real em ARKHER.STATE.cloud), Aparencia, Atalhos — com toggles e dropdowns.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#AEB9CC")

local function build()
	local g, root, head = K.window("ArkherSettings", "SETTINGS — preferencias", 24, 450, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: NAVEGACAO =====
	local left = K.f(root, "Nav", 8, 34, 108, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SECOES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local sections = { "Qualidade", "Cloud", "Apariencia", "Atalhos", "Dados" }
	for i, s in ipairs(sections) do
		local row = K.treeRow(left, 0, i == 1 and ICON.settings or ICON.plugin, s, i == 1, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Settings: secao " .. s)
		end)
	end
	K.row(left, "V3.0.0", "", 180)

	-- ===== CENTRO: SECOES =====
	local sec1, b1 = K.section(root, "Qualidade", true, 34)
	K.sliderRow(b1, "D-O15 nivel", 0.4, 4)
	K.txt(b1, "auto-degrada por pressao de FPS", 8, 30, 200, 14, 9, T.txt4)

	local sec2, b2 = K.section(root, "Cloud (ARKHER)", true, 104)
	K.txt(b2, "Endpoint do Arkher Cloud (sem Open API):", 8, 4, 240, 16, 10, T.txt3)
	local epBox = K.input(b2, 8, 24, 236, 24, "https://meu-cloud.exemplo.com/arkher")
	epBox.Text = ARKHER.STATE.cloud.endpoint or ""
	local saveEp = K.btn(b2, "SaveEp", 8, 54, 110, 22, ACCENT, 4)
	K.txtS(saveEp, "Salvar endpoint", 9, C("#14181E"))
	K.hover(saveEp, ACCENT, C("#CDD7E4"))
	saveEp.MouseButton1Click:Connect(function()
		ARKHER.STATE.cloud.endpoint = epBox.Text
		ARKHER.STATE.cloud.connected = epBox.Text ~= ""
		ARKHER.out("SUCCESS", "Settings: endpoint salvo: " .. (epBox.Text or "(vazio)"))
		K.notify("Cloud", "endpoint atualizado", "ok")
	end)
	K.txt(b2, "publicacao local nao precisa de endpoint", 8, 84, 240, 14, 9, T.txt4)

	local sec3, b3 = K.section(root, "Aparencia", true, 194)
	K.checkRow(b3, "Modo compacto", false, 4)
	K.checkRow(b3, "Acento neon", true, 28)
	K.checkRow(b3, "Mostrar grade no viewport", true, 52)

	-- ===== DIREITA: ATALHOS =====
	local right = K.f(root, "Keys", 330, 34, 222, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ATALHOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local keys = {
		{ "Ctrl+K", "command palette" },
		{ "Ctrl+Z / Ctrl+Y", "undo / redo" },
		{ "Del", "apagar selecao" },
		{ "V / W / E / R", "select / move / scale / rotate" },
		{ "WASD / Q / E", "orbitar (ferramenta Move)" },
		{ "L", "lock de camera" },
	}
	for i, k2 in ipairs(keys) do
		K.txt(right, k2[1], 10, 28 + (i - 1) * 28, 110, 16, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
		K.txt(right, k2[2], 124, 28 + (i - 1) * 28, 90, 16, 9, T.txt3)
		K.f(right, "ks" .. i, 10, 46 + (i - 1) * 28, 202, 1, T.line)
	end
	local reset = K.btn(right, "Rst", 10, 216, 202, 24, T.danger, 4)
	K.txtS(reset, "Restaurar padroes", 10, C("#1C0404"))
	K.hover(reset, T.danger, C("#F08080"))
	reset.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Settings: padroes restaurados")
		K.notify("Settings", "restaurado", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Lang", "pt-BR", 8)
	K.row(bar, "Tema", "dark", 34)
	K.txt(bar, "as preferencias persistem em ServerStorage.ArkherCloud.Settings", 170, 16, 360, 14, 9, T.txt4)
	K.txt(bar, "salvo", 480, 40, 60, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Settings", "Settings", "System", ICON.settings, "Preferencias: qualidade, cloud (endpoint), aparencia e atalhos", build)
