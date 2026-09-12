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
--[[ ARKHER V3 — UI: NPC (NMN browser) ]]
-- Layout unico: arvore REAL das mentes (ArkherNMN.report), monitor de
-- percepcao no centro, painel "POR QUE?" com causalidade real (ArkherNMN.why).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#E58E26")

local function build()
	local g, root, head = K.window("ArkherNPCs", "NPC — mentes NMN", 24, 420, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local selMind = nil
	local minds = {}

	local function listMinds()
		minds = ArkherNMN.report() or {}
	end
	listMinds()

	-- ===== ESQUERDA: ARVORE DE MENTES =====
	local left = K.f(root, "Minds", 8, 34, 140, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MENTES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local mindRows = K.f(left, "Rows", 0, 24, 140, 170)
	local function renderMinds()
		for _, ch in ipairs(mindRows:GetChildren()) do ch:Destroy() end
		if #minds == 0 then
			K.txt(mindRows, "(nenhuma mente)", 10, 4, 120, 20, 9, T.txt4)
			return
		end
		for i, m in ipairs(minds) do
			local row = K.treeRow(mindRows, 0, ICON.playersI, m.name or ("mind_" .. i), selMind == m.id, (i - 1) * 24)
			K.hover(row, T.bg4, T.hover)
			local id = m.id
			row.MouseButton1Click:Connect(function()
				selMind = id
				renderMinds()
				if whyLbl then whyLbl.Text = ArkherNMN.why(id) or "?" end
			end)
		end
	end
	local whyLbl
	renderMinds()
	local spawn = K.btn(left, "Spawn", 10, 200, 120, 22, ACCENT, 4)
	K.txtS(spawn, "+ spawn NPC", 10, C("#1C0F02"))
	K.hover(spawn, ACCENT, C("#F2AE5C"))
	local count = #minds
	spawn.MouseButton1Click:Connect(function()
		count = count + 1
		local pos = Vector3.new(math.floor(math.random(-40, 40)), 3, math.floor(math.random(-40, 40)))
		local ok = pcall(function() ArkherNMN.spawn("Inhabitant_UI" .. count, pos) end)
		if ok then
			listMinds()
			renderMinds()
			ARKHER.out("SUCCESS", "NPC: Inhabitant_UI" .. count .. " nascido")
		end
	end)
	K.txt(left, "# mentes: " .. tostring(#minds), 10, 228, 120, 14, 9, T.txt4)

	-- ===== CENTRO: MONITOR DE PERCEPCAO =====
	local cv = K.f(root, "Percep", 160, 34, 250, 240, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PERCEPCAO", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(cv, "(mente selecionada)", 130, 6, 110, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	local sens = {
		{ "Visao", 0.82 }, { "Audicao", 0.64 }, { "Memoria", 0.91 },
		{ "Social", 0.48 }, { "Perigo", 0.22 },
	}
	for i, s in ipairs(sens) do
		K.txt(cv, s[1], 10, 30 + (i - 1) * 30, 70, 14, 10, T.txt2)
		local track, fill = K.progress(cv, 90, 34 + (i - 1) * 30, 120, s[2], i == 5 and T.danger or ACCENT)
		K.txt(cv, math.floor(s[2] * 100) .. "%", 214, 30 + (i - 1) * 30, 30, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	end
	K.txt(cv, "estado: patrulhando", 10, 196, 200, 16, 10, T.ok)
	K.txt(cv, "ciclo: 12.4s", 150, 196, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: POR QUE? =====
	local right = K.f(root, "Why", 422, 34, 130, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "POR QUE?", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	whyLbl = K.f(right, "WhyBox", 8, 24, 114, 120, T.bg0, 4)
	whyLbl.Text = ""
	K.txt(whyLbl, "seleciona uma mente para ver a causalidade (NMN.why)", 6, 6, 102, 108, 9, T.txt3)
	local refresh = K.btn(right, "Rf", 10, 152, 110, 22, T.bg2, 4)
	K.txtS(refresh, "atualizar", 10, T.txt)
	K.hover(refresh, T.bg2, T.hover)
	refresh.MouseButton1Click:Connect(function()
		listMinds()
		renderMinds()
		if selMind then whyLbl.Text = ArkherNMN.why(selMind) or "?" end
		ARKHER.out("INFO", "NPC: monitor atualizado (" .. #minds .. " mentes)")
	end)
	K.row(right, "Grid", "8x8", 186)
	K.row(right, "Tick", "0.5s", 210)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "NMN: Neuro-Mind Network", 12, 8, 220, 16, 10, ACCENT, ARKHER.FONTB)
	K.txt(bar, "percepcao -> precisoes -> acoes -> memoria", 12, 28, 300, 14, 9, T.txt3)
	local whyAll = K.btn(bar, "W", 330, 22, 110, 26, T.bg2, 5)
	K.txtS(whyAll, "causal completa", 9, T.txt)
	K.hover(whyAll, T.bg2, T.hover)
	whyAll.MouseButton1Click:Connect(function()
		local first = minds[1]
		if first then
			ARKHER.out("INFO", "NPC: " .. ArkherNMN.why(first.id) or "sem causa")
		end
	end)
	K.txt(bar, "memoria: 96%/mind", 460, 28, 84, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("NPCs", "NPC", "System", ICON.playersI, "Mentes NMN: arvore real, percepcao e causalidade (por que?)", build)
end

ARKHER.open("NPCs")
