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
--[[ ARKHER V3 — UI: SAVEOPEN ]]
-- Layout unico: acao GRANDE de salvar no topo, nome do place, lista de
-- recentes com abrir, autosave a direita — o fluxo rapido de File.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFA502")

local function build()
	local g, root, head = K.window("ArkherSaveOpen", "FILE — salvar & abrir", 24, 490, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: SALVAR =====
	local nameBox = K.input(root, 8, 34, 240, 28, "nome do place")
	nameBox.Text = ARKHER.STATE.placeName or "Untitled"
	local save = K.btn(root, "Save", 260, 32, 150, 32, ACCENT, 6)
	local saveIc = K.f(save, "Ic", 8, 6, 20, 20)
	ICON.save(saveIc)
	K.txt(save, "SALVAR", 34, 0, 100, 32, 12, C("#241300"), ARKHER.FONTB)
	K.hover(save, ACCENT, C("#FFC14D"))
	save.MouseButton1Click:Connect(function()
		ARKHER.STATE.placeName = nameBox.Text
		ArkherPlaces.save(nameBox.Text)
		K.notify("Place salvo", nameBox.Text, "ok")
		refreshRecent()
	end)
	local savedLbl = K.txt(root, "nunca", 420, 42, 130, 16, 10, T.txt3, FONT, Enum.TextXAlignment.Right)

	-- ===== CENTRO: RECENTES =====
	local rec = K.f(root, "Recent", 8, 74, 380, 190, T.bg0)
	K.corner(rec, 4)
	K.stroke(rec, T.line, 1)
	K.txt(rec, "RECENTES", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	local rows = K.f(rec, "Rows", 0, 26, 380, 160)
	local function refreshRecent()
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		local list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(rows, "(vazio — salve o place atual)", 12, 6, 340, 20, 9, T.txt4)
			return
		end
		for i, p in ipairs(list) do
			if i > 5 then break end
			local y = (i - 1) * 32
			local row = K.f(rows, "R" .. i, 8, y, 364, 28, T.bg2, 4)
			ICON.folder(row, 14)
			K.txt(row, tostring(p.name), 26, 2, 180, 16, 10, T.txt)
			K.txt(row, "#" .. tostring(p.id) .. " | " .. string.format("%.1fK", (p.bytes or 0) / 1024), 26, 15, 180, 12, 8, T.txt4)
			local ob = K.btn(row, "O" .. i, 280, 3, 56, 22, ACCENT, 4)
			K.txtS(ob, "abrir", 9, C("#241300"))
			K.hover(ob, ACCENT, C("#FFC14D"))
			local pid = p.id
			ob.MouseButton1Click:Connect(function()
				ArkherPlaces.open(pid)
				nameBox.Text = ARKHER.STATE.placeName
			end)
		end
	end
	refreshRecent()

	-- ===== DIREITA: AUTOSAVE =====
	local right = K.f(root, "Auto", 400, 74, 152, 190, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AUTOSAVE", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.checkRow(right, "Ativo", true, 26)
	K.sliderRow(right, "Intervalo", 0.33, 52)
	K.row(right, "", "a cada 10 min", 78)
	K.checkRow(right, "Snapshot de seguranca", true, 106)
	K.row(right, "Ultimo", "agora", 134)
	K.row(right, "Proximo", "9 min", 158)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 272, 544, 100, T.bg0)
	K.corner(bar, 4)
	local list = ArkherPlaces.list()
	local total = 0
	for _, p in ipairs(list) do total = total + (p.bytes or 0) end
	K.row(bar, "Places salvos", tostring(#list), 8)
	K.row(bar, "Total em disco", string.format("%.1f KB", total / 1024), 34)
	K.progress(bar, 220, 14, 300, math.min(1, total / (1024 * 1024)), ACCENT)
	K.row(bar, "Formato", ".arkher.lua (JSON)", 60)
	local closeB = K.btn(bar, "Close", 330, 56, 100, 26, T.bg2, 4)
	K.txtS(closeB, "fechar place", 9, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		ArkherPlaces.close()
		nameBox.Text = "Untitled"
	end)
	K.txt(bar, "novos places: City | Nature | Space | Baseplate | Empty", 450, 62, 100, 40, 8, T.txt4)
end

ARKHER.reg("SaveOpen", "Save & Open", "System", ICON.save, "Fluxo rapido de File: salvar, recentes, autosave", build)
end

ARKHER.open("SaveOpen")
