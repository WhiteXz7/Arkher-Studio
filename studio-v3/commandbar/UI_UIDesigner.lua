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
--[[ ARKHER V3 — UI: UIDESIGNER ]]
-- Layout unico: paleta de widgets a esquerda, CANVAS com grade no centro
-- (widgets posicionados, clique seleciona), inspector de estilo a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")

local function build()
	local g, root, head = K.window("ArkherUIDesigner", "UI DESIGNER — canvas", 24, 390, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: PALETA =====
	local left = K.f(root, "Pal", 8, 34, 120, 268, T.bg4)
	K.corner(left, 4)
	K.txt(left, "WIDGETS", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local palette = {
		{ nm = "Button", ic = ICON.transform },
		{ nm = "Label", ic = ICON.textA },
		{ nm = "Frame", ic = ICON.plate },
		{ nm = "TextBox", ic = ICON.script },
		{ nm = "Image", ic = ICON.gem },
		{ nm = "Toggle", ic = ICON.check },
	}
	for i, p in ipairs(palette) do
		local row = K.btn(left, "P" .. i, 8, 26 + (i - 1) * 26, 104, 22, T.bg2, 4)
		local ic = K.f(row, "Ic", 4, 3, 16, 16)
		p.ic(ic, 14)
		K.txt(row, p.nm, 24, 0, 76, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "UIDesigner: widget " .. p.nm .. " na paleta")
		end)
	end
	K.txt(left, "6 widgets", 10, 196, 90, 14, 9, T.txt4)
	K.row(left, "Zoom", "100%", 216)
	K.row(left, "Snap", "8px", 240)

	-- ===== CENTRO: CANVAS COM GRADE =====
	local cv = K.f(root, "Canvas", 140, 34, 272, 268, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 13 do K.f(cv, "gx" .. i, i * 20, 0, 1, 268, T.bg3) end
	for i = 1, 13 do K.f(cv, "gy" .. i, 0, i * 20, 272, 1, T.bg3) end
	-- widgets ja colocados
	local widgets = {
		{ x = 20, y = 30, w = 120, h = 32, nm = "Btn_Primary", c = ACCENT },
		{ x = 160, y = 30, w = 92, h = 32, nm = "Label_Titulo", c = T.sec },
		{ x = 20, y = 84, w = 232, h = 72, nm = "Frame_Card", c = T.bg2 },
		{ x = 20, y = 172, w = 140, h = 28, nm = "Txt_Input", c = T.bg4 },
	}
	local selW = 3
	local wFrames = {}
	for i, w2 in ipairs(widgets) do
		local f = K.f(cv, "W" .. i, w2.x, w2.y, w2.w, w2.h, w2.c, 4)
		K.stroke(f, i == selW and ACCENT or T.line, i == selW and 2 or 1)
		K.txt(f, w2.nm, 6, 4, w2.w - 12, 14, 9, w2.c == ACCENT and C("#10202A") or T.txt2)
		wFrames[i] = f
		local idx = i
		f.MouseButton1Click:Connect(function()
			selW = idx
			for j, fr in ipairs(wFrames) do
				K.stroke(fr, j == idx and ACCENT or T.line, j == idx and 2 or 1)
			end
			nameLbl.Text = widgets[idx].nm
		end)
	end
	local nameLbl = K.txt(cv, "Frame_Card", 200, 244, 66, 14, 9, ACCENT, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: INSPECTOR =====
	local right = K.f(root, "Insp", 424, 34, 128, 268, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ESTILO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Pos", "20, 84", 26)
	K.row(right, "Size", "232 x 72", 50)
	K.sliderRow(right, "Opacidade", 1.0, 76)
	K.sliderRow(right, "Rounded", 0.4, 102)
	K.knob(right, 40, 124, 48, 0.4, "r: 8px")
	K.checkRow(right, "Stroke", true, 186)
	K.checkRow(right, "Drop shadow", false, 210)
	K.checkRow(right, "Auto resize", true, 234)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 312, 544, 72, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Gerar GUI no Place", 10, C("#041820"))
	K.hover(gen, ACCENT, C("#7DEBFF"))
	gen.MouseButton1Click:Connect(function()
		local ws = workspace
		local gui = Instance.new("ScreenGui")
		gui.Name = "ArkherGeneratedUI"
		gui.Parent = ws
		for _, w2 in ipairs(widgets) do
			local isBtn = w2.nm:sub(1, 4) == "Btn_"
			local inst = Instance.new(isBtn and "TextButton" or (w2.nm:sub(1, 4) == "Txt_" and "TextBox" or "Frame"))
			inst.Name = w2.nm
			inst.Parent = gui
			inst:SetAttribute("ARKHER", "designed")
		end
		ARKHER.out("SUCCESS", "UIDesigner: GUI gerada no place (" .. #widgets .. " widgets)")
		K.notify("GUI gerada", "ArkherGeneratedUI no workspace", "ok")
	end)
	K.txt(bar, "4 widgets no canvas", 160, 16, 150, 16, 10, T.txt3)
	K.txt(bar, "AutoLayout: ON", 330, 16, 110, 16, 9, T.txt4)
	K.txt(bar, "960x540", 470, 16, 70, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("UIDesigner", "UI Designer", "Editor", ICON.plate, "Designer de UI: paleta, canvas com grade e inspector de estilo", build)
end

ARKHER.open("UIDesigner")
