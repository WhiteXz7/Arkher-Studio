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
--[[ ARKHER V3 — UI: ABOUT ]]
-- Layout unico: emblem + versao ao centro, lista REAL dos sistemas ativos
-- a esquerda, contadores vivos a direita (UIs, comandos, places, mentes).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#576574")

local function build()
	local g, root, head = K.window("ArkherAbout", "ABOUT — ARKHER V3", 24, 520, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: SISTEMAS =====
	local left = K.f(root, "Sys", 8, 34, 168, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SISTEMAS ATIVOS", 10, 6, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local systems = {
		{ "Places (cloud local)", ArkherPlaces ~= nil },
		{ "Undo/Redo (50)", ArkherUNDO ~= nil },
		{ "Live (inspector)", ArkherLive ~= nil },
		{ "D-O15 (perf)", ArkherDO15 ~= nil },
		{ "Singularity (IA)", ARKHER_SINGULARITY ~= nil },
		{ "NMN (mentes)", ArkherNMN ~= nil },
		{ "Publish (sem Open API)", ArkherPublish ~= nil },
		{ "Actions (ARKHER.cmd)", ARKHER.ACTIONS ~= nil },
	}
	for i, s in ipairs(systems) do
		K.treeRow(left, 0, s[2] and ICON.check or ICON.close, s[1], s[2] and "ok" or nil, 26 + (i - 1) * 27)
	end

	-- ===== CENTRO: EMBLEM + VERSAO =====
	local cv = K.f(root, "Brand", 188, 34, 204, 170, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line2, 1)
	local emb = K.f(cv, "Emblem", 82, 20, 40, 40)
	ICON.emblem(emb, 40)
	K.txt(cv, "ARKHER STUDIO", 0, 68, 204, 20, 16, T.txt, ARKHER.FONTB, Enum.TextXAlignment.Center)
	K.txt(cv, "v" .. tostring(ARKHER._version or "3.0.0"), 0, 90, 204, 14, 10, T.neon, FONT, Enum.TextXAlignment.Center)
	K.txt(cv, "UES COMPLETA MAS NO ROBLOX", 0, 112, 204, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	K.grad(cv, T.dark, C("#101828"), 90)
	local tags = K.f(cv, "Tags", 0, 134, 204, 30, T.bg0)
	K.txt(tags, "criar places | publicar facil | IA local", 0, 0, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(tags, "sem Open API | sem cloud obrigatoria", 0, 16, 204, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Center)

	-- ===== DIREITA: CONTADORES VIVOS =====
	local right = K.f(root, "Count", 404, 34, 148, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AGORA", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local uiCount = #ARKHER.listUIs()
	local cmdCount = 0
	for _ in pairs(ARKHER.ACTIONS or {}) do cmdCount = cmdCount + 1 end
	local placesCount = #ArkherPlaces.list()
	local nmnCount = ArkherNMN and ArkherNMN.count() or 0
	local counters = {
		{ "UIs registradas", tostring(uiCount) },
		{ "Comandos (ARKHER.cmd)", tostring(cmdCount) },
		{ "Places salvos", tostring(placesCount) },
		{ "Mentes NMN", tostring(nmnCount) },
		{ "Nivel D-O15", tostring((ArkherDO15 and ArkherDO15.state and ArkherDO15.state.level) or "?") },
		{ "Place atual", ARKHER.STATE.placeName or "?" },
	}
	for i, c2 in ipairs(counters) do
		K.txt(right, c2[1], 10, 28 + (i - 1) * 34, 130, 14, 9, T.txt3)
		K.txt(right, c2[2], 10, 44 + (i - 1) * 34, 130, 16, 11, T.txt, ARKHER.FONTB)
		if i < #counters then K.f(right, "sep" .. i, 10, 62 + (i - 1) * 34, 128, 1, T.line) end
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "feito no Roblox Studio, para o Roblox Studio", 12, 8, 320, 16, 10, T.txt3)
	K.txt(bar, "batch 0: core + shell | batch 1: UIs unicas | batch 2: integracao", 12, 28, 420, 14, 9, T.txt4)
	K.txt(bar, "2026", 500, 8, 40, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	local closeB = K.btn(bar, 340, 44, 100, 24, T.bg2, 4)
	K.txtS(closeB, "fechar", 10, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		root.Visible = false
	end)
end

ARKHER.reg("About", "About", "System", ICON.info, "Sobre o ARKHER V3: sistemas ativos e contadores em tempo real", build)
end

ARKHER.open("About")
