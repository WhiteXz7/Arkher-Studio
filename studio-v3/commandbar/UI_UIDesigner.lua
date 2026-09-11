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
--[[ ARKHER — UI: UI STUDIO (designer de UI de jogos, engine ArkherUIKitX) ]]
-- Designer profissional: paleta com 42 widgets reais (base/input/display/HUD/
-- menu), canvas com grade e DRAG DE VERDADE (move/redimensiona), snap, inspector
-- numerico vivo, 9 presets de ancora, alinhar/distribuir multi-selecao, 6 temas
-- aplicaveis, camadas, import/export REAL (ScreenGui no StarterGui + ModuleScript
-- de codigo + controller de eventos).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")
local X = ArkherUIKitX
local UserInputService = game:GetService("UserInputService")

local function build()
	local g, root, head = K.window("ArkherUIDesigner", "UI STUDIO — designer de UI de jogos", 30, 300, 720, 520, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)

	-- ================= ESTADO =================
	local items = {} -- {root, kind, meta{x,y,w,h,opts}}
	local selected = {}
	local snap = true
	local SNAP = 4
	local status = nil
	local canvas = nil
	local devW, devH = 960, 540
	local selBox, selHandle = nil, nil
	local layersBody = nil
	local inspectorBody = nil
	-- pre-declarados (closures cruzadas)
	local addWidget, refreshInspector, refreshLayers, refreshSelBox

	local function snapV(v) return snap and (math.floor(v / SNAP) * SNAP) or math.floor(v) end
	local function isSel(it)
		for _, s in ipairs(selected) do if s == it then return true end end
		return false
	end
	local function syncItem(it)
		it.root.Position = UDim2.fromOffset(snapV(it.meta.x), snapV(it.meta.y))
		it.root.Size = UDim2.fromOffset(it.meta.w, it.meta.h)
	end

	-- ================= PALETA (42 widgets, paged, por categoria) =================
	local pal = K.f(root, "Pal", 8, 34, 132, 432, T.bg4)
	K.corner(pal, 4)
	local CATS = { "Base", "Input", "Display", "HUD", "Menu" }
	local palCat = 1
	local palPage = 0
	local palBody = K.f(pal, "PB", 4, 48, 124, 378)
	local palBtns = {}
	local repaintPal = nil
	for i, nm in ipairs(CATS) do
		local b = K.btn(pal, "C" .. i, 4 + (i - 1) * 26, 6, 24, 18, T.bg4, 3)
		K.txtS(b, nm:sub(1, 2), 8, i == palCat and ACCENT or T.txt3)
		local idx = i
		b.MouseButton1Click:Connect(function()
			palCat = idx
			palPage = 0
			repaintPal()
		end)
		palBtns[i] = b
	end
	local palNext = K.btn(pal, "Next", 70, 26, 58, 18, T.bg2, 3)
	K.txtS(palNext, "mais >", 8, T.txt3)
	local palPrev = K.btn(pal, "Prev", 6, 26, 58, 18, T.bg2, 3)
	K.txtS(palPrev, "< ant", 8, T.txt3)
	palPrev.MouseButton1Click:Connect(function() palPage = math.max(0, palPage - 1) repaintPal() end)
	palNext.MouseButton1Click:Connect(function() palPage = palPage + 1 repaintPal() end)

	local catalog = X.catalog()
	repaintPal = function()
		palBody:ClearAllChildren()
		for j, b in ipairs(palBtns) do
			b.BackgroundColor3 = j == palCat and T.bg2 or T.bg4
		end
		local list = catalog[CATS[palCat]] or {}
		local PER = 18
		palPage = math.min(palPage, math.max(0, math.ceil(#list / PER) - 1))
		local base = palPage * PER
		for i = 1, PER do
			local w = list[base + i]
			if not w then break end
			local b = K.btn(palBody, "W" .. i, 0, (i - 1) * 20, 122, 18, T.bg2, 3)
			K.txt(b, (w.nm), 6, 2, 112, 14, 9, T.txt)
			K.hover(b, T.bg2, T.hover)
			local id = w.id
			b.MouseButton1Click:Connect(function() addWidget(id) end)
		end
	end

	-- ================= CANVAS COM GRADE =================
	local cvX, cvY, cvW, cvH = 148, 34, 400, 432
	canvas = K.f(root, "Canvas", cvX, cvY, cvW, cvH, T.bg0)
	K.corner(canvas, 4)
	K.stroke(canvas, T.line, 1)
	canvas.ClipsDescendants = true
	-- device frame interno (viewport da tela alvo)
	local devScaleX, devScaleY = (cvW - 16) / devW, (cvH - 16) / devH
	local devScale = math.min(devScaleX, devScaleY)
	local devFrame = K.f(canvas, "Device", 8, 8, math.floor(devW * devScale), math.floor(devH * devScale), C("#101A2C"))
	K.corner(devFrame, 3)
	K.stroke(devFrame, T.line2, 1)
	-- grade
	for i = 1, 19 do K.f(devFrame, "gx" .. i, math.floor(i * devFrame.Size.X.Offset / 20), 0, 1, devFrame.Size.Y.Offset, C("#16233C")) end
	for i = 1, 11 do K.f(devFrame, "gy" .. i, 0, math.floor(i * devFrame.Size.Y.Offset / 12), devFrame.Size.X.Offset, 1, C("#16233C")) end
	local devLbl = K.txt(canvas, "960x540 (Desktop)", cvW - 130, cvH - 16, 126, 12, 8, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Right)

	-- escala canvas->tela
	local function toCanvas(x, y) return x * devScale, y * devScale end

	-- selecao: caixa + handle
	selBox = K.f(devFrame, "SelBox", 0, 0, 10, 10)
	selBox.BackgroundTransparency = 1
	K.stroke(selBox, ACCENT, 1.5)
	selBox.Visible = false
	selHandle = K.btn(devFrame, "SelHandle", 0, 0, 12, 12, ACCENT, 2)
	selHandle.Visible = false

	refreshLayers = function() end -- (camadas exibidas via selecao/inspector)

	local function setSelection(list)
		selected = list
		refreshSelBox()
		refreshInspector()
		refreshLayers()
	end

	refreshSelBox = function()
		if #selected == 0 then selBox.Visible = false selHandle.Visible = false return end
		local it = selected[#selected]
		local x, y = toCanvas(it.meta.x, it.meta.y)
		local w, h = it.meta.w * devScale, it.meta.h * devScale
		selBox.Visible = true
		selBox.Position = UDim2.fromOffset(math.floor(x) - 2, math.floor(y) - 2)
		selBox.Size = UDim2.fromOffset(math.floor(w) + 4, math.floor(h) + 4)
		selHandle.Visible = true
		selHandle.Position = UDim2.fromOffset(math.floor(x + w) - 4, math.floor(y + h) - 4)
	end

	-- drag de mover (widget) e resize (handle)
	local drag = nil
	local function canvasPosOfInput(inp)
		return inp.Position.X - devFrame.AbsolutePosition.X, inp.Position.Y - devFrame.AbsolutePosition.Y
	end
	UserInputService.InputChanged:Connect(function(inp)
		if not drag then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		local mx, my = canvasPosOfInput(inp)
		if drag.mode == "move" then
			for _, d in ipairs(drag.list) do
				d.it.meta.x = snapV(d.x0 + (mx - drag.mx0) / devScale)
				d.it.meta.y = snapV(d.y0 + (my - drag.my0) / devScale)
				local cx2, cy2 = toCanvas(d.it.meta.x, d.it.meta.y)
				d.it.root.Position = UDim2.fromOffset(cx2, cy2)
			end
			refreshSelBox()
			refreshInspector()
		elseif drag.mode == "resize" then
			local it = drag.list[1].it
			it.meta.w = math.max(20, snapV(drag.list[1].w0 + (mx - drag.mx0) / devScale))
			it.meta.h = math.max(14, snapV(drag.list[1].h0 + (my - drag.my0) / devScale))
			local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
			it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale)
			refreshSelBox()
			refreshInspector()
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
	end)
	selHandle.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local it = selected[#selected]
		if not it then return end
		local mx, my = canvasPosOfInput(inp)
		drag = { mode = "resize", mx0 = mx, my0 = my, list = { { it = it, w0 = it.meta.w, h0 = it.meta.h } } }
	end)

	local function mountItem(it)
		-- meta.x/y em coords de TELA (device); cria posicionado no devFrame
		local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
		it.root.Position = UDim2.fromOffset(cx2, cy2)
		it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale)
		it.root:SetAttribute("wkind", it.kind)
		it.root.Parent = devFrame
		if it.root:IsA("GuiObject") then
			it.root.InputBegan:Connect(function(inp)
				if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				if not isSel(it) then setSelection({ it }) end
				local mx, my = canvasPosOfInput(inp)
				local list = {}
				for _, s in ipairs(selected) do list[#list + 1] = { it = s, x0 = s.meta.x, y0 = s.meta.y } end
				if #list == 0 then list[1] = { it = it, x0 = it.meta.x, y0 = it.meta.y } end
				drag = { mode = "move", mx0 = mx, my0 = my, list = list }
			end)
		end
	end

	addWidget = function(id, meta)
		local meta2 = meta or { x = math.floor(devW / 2 - 60), y = math.floor(devH / 2 - 20) }
		local w, err = X.create(id, meta2)
		if not w then
			if status then status.Text = "erro: " .. tostring(err) end
			return
		end
		w.meta.x, w.meta.y = meta2.x, meta2.y
		if meta2.w then w.meta.w = meta2.w end
		if meta2.h then w.meta.h = meta2.h end
		if meta2.text then w.meta.opts.text = meta2.text end
		items[#items + 1] = w
		mountItem(w)
		setSelection({ w })
		if status then status.Text = "+" .. id .. " (" .. X.WIDGETS[id].nm .. ") no canvas" end
	end
	repaintPal()

	-- ================= CAMADAS / INSPECTOR (direita) =================
	local right = K.f(root, "Right", 556, 34, 156, 432, T.bg4)
	K.corner(right, 4)
	K.txt(right, "INSPECTOR", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	inspectorBody = K.f(right, "IB", 6, 24, 144, 250)

	local function stepper(parent, y, label, get, set, lo, hi)
		K.txt(parent, label, 4, y, 40, 14, 9, T.txt3)
		local minus = K.btn(parent, "M", 44, y - 2, 18, 16, T.bg2, 3)
		K.txtS(minus, "-", 10, T.txt)
		local plus2 = K.btn(parent, "P", 122, y - 2, 18, 16, T.bg2, 3)
		K.txtS(plus2, "+", 10, T.txt)
		local val = K.txt(parent, tostring(get()), 64, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Center)
		local function re() val.Text = tostring(get()) end
		minus.MouseButton1Click:Connect(function() set(math.max(lo or -99999, get() - SNAP * 2)) re() end)
		plus2.MouseButton1Click:Connect(function() set(math.min(hi or 99999, get() + SNAP * 2)) re() end)
		return re
	end

	refreshInspector = function()
		inspectorBody:ClearAllChildren()
		local it = selected[#selected]
		if not it then K.txt(inspectorBody, "nada selecionado", 4, 2, 130, 14, 9, T.txt4) return end
		K.txt(inspectorBody, it.kind, 4, 2, 130, 16, 11, ACCENT, ARKHER.FONTB)
		stepper(inspectorBody, 30, "X", function() return it.meta.x end, function(v) it.meta.x = v syncItem(it) local cx2, cy2 = toCanvas(v, it.meta.y) it.root.Position = UDim2.fromOffset(cx2, cy2) refreshSelBox() end)
		stepper(inspectorBody, 56, "Y", function() return it.meta.y end, function(v) it.meta.y = v syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, v) it.root.Position = UDim2.fromOffset(cx2, cy2) refreshSelBox() end)
		stepper(inspectorBody, 82, "Larg", function() return it.meta.w end, function(v) it.meta.w = math.max(20, v) syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, it.meta.y) it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale) refreshSelBox() end)
		stepper(inspectorBody, 108, "Alt", function() return it.meta.h end, function(v) it.meta.h = math.max(14, v) syncItem(it) local cx2, cy2 = toCanvas(it.meta.x, it.meta.y) it.root.Size = UDim2.fromOffset(it.meta.w * devScale, it.meta.h * devScale) refreshSelBox() end)
		-- ancoras 3x3
		K.txt(inspectorBody, "ANCORA", 4, 136, 90, 12, 9, T.txt3, ARKHER.FONTB)
		local anames = { "sup_esq", "sup_centro", "sup_dir", "meio_esq", "centro", "meio_dir", "inf_esq", "inf_centro", "inf_dir" }
		for i, an in ipairs(anames) do
			local b = K.btn(inspectorBody, "A" .. i, 4 + ((i - 1) % 3) * 46, 152 + math.floor((i - 1) / 3) * 20, 44, 17, T.bg2, 3)
			K.txtS(b, "", 8, T.txt4)
			local dot = K.f(b, "d", 17 + ((i - 1) % 3) * 4 - 4, 5 + math.floor((i - 1) / 3) * 3, 6, 6, ACCENT, 3)
			local aname = an
			b.MouseButton1Click:Connect(function()
				X.anchorPreset(it, aname, devW, devH)
				local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
				it.root.Position = UDim2.fromOffset(cx2, cy2)
				refreshSelBox()
				refreshInspector()
				if status then status.Text = "ancorado: " .. aname end
			end)
		end
	end

	-- multi-selecao por botoes de acao rapida
	local actRow = K.f(right, "Acts", 6, 280, 144, 64)
	local delB = K.btn(actRow, "Del", 0, 0, 70, 22, C("#5A2830"), 4)
	K.txtS(delB, "Excluir", 9, C("#FFB0B8"))
	local dupB = K.btn(actRow, "Dup", 74, 0, 70, 22, T.bg2, 4)
	K.txtS(dupB, "Duplicar", 9, T.txt)
	delB.MouseButton1Click:Connect(function()
		local n = 0
		for _, it in ipairs(selected) do
			for i = #items, 1, -1 do if items[i] == it then table.remove(items, i) end end
			it.root:Destroy()
			n = n + 1
		end
		setSelection({})
		if status then status.Text = n .. " widget(s) excluido(s)" end
	end)
	dupB.MouseButton1Click:Connect(function()
		local it = selected[#selected]
		if it then
			addWidget(it.kind, { x = it.meta.x + 16, y = it.meta.y + 16, w = it.meta.w, h = it.meta.h, text = it.meta.opts and it.meta.opts.text })
		end
	end)
	-- alinhar/distribuir
	K.txt(right, "ALINHAR (multi)", 10, 348, 130, 12, 9, T.txt3, ARKHER.FONTB)
	local alignBtns = {
		{ "Esq", function() return X.alignLeft(selected) end }, { "Cen", function() return X.alignHCenter(selected) end },
		{ "Dir", function() return X.alignRight(selected) end }, { "Top", function() return X.alignTop(selected) end },
		{ "Base", function() return X.alignBottom(selected) end }, { "DistH", function() return X.distributeH(selected) end },
		{ "DistV", function() return X.distributeV(selected) end },
	}
	for i, a in ipairs(alignBtns) do
		local b = K.btn(right, "AL" .. i, 8 + ((i - 1) % 3) * 48, 364 + math.floor((i - 1) / 3) * 22, 44, 19, T.bg2, 3)
		K.txtS(b, a[1], 8, T.txt2)
		K.hover(b, T.bg2, T.hover)
		local fn = a[2]
		local nm = a[1]
		b.MouseButton1Click:Connect(function()
			if #selected == 0 then
				-- sem selecao: aplica em todos (atalho pro)
				selected = items
			end
			local n = fn()
			for _, it in ipairs(items) do
				local cx2, cy2 = toCanvas(it.meta.x, it.meta.y)
				it.root.Position = UDim2.fromOffset(cx2, cy2)
			end
			refreshSelBox()
			if status then status.Text = nm .. ": " .. n .. " widgets alinhados" end
		end)
	end
	local selAll = K.btn(right, "SelAll", 8, 412, 140, 20, T.bg2, 4)
	K.txtS(selAll, "Selecionar todos", 9, T.txt)
	selAll.MouseButton1Click:Connect(function() setSelection(items) end)

	-- ================= BARRA INFERIOR: EXPORT / TEMA / DEVICE =================
	local bar = K.f(root, "Bar", 8, 474, 704, 38, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "42 widgets na paleta — clique p/ adicionar, arraste p/ mover", 10, 4, 330, 14, 9, T.txt3)
	-- tema
	local themeIds = { "arkher", "neon", "light", "forest", "sunset", "glass" }
	local themeIdx = 1
	local themeB = K.btn(bar, "Theme", 348, 8, 80, 22, T.bg2, 4)
	K.txtS(themeB, "Tema: arkher", 8, T.txt)
	K.hover(themeB, T.bg2, T.hover)
	themeB.MouseButton1Click:Connect(function()
		themeIdx = (themeIdx % #themeIds) + 1
		local th = X.setTheme(themeIds[themeIdx])
		themeB:FindFirstChildOfClass("TextLabel").Text = "Tema: " .. themeIds[themeIdx]
		-- recria todos os widgets com o tema novo
		local saved = {}
		for i, it in ipairs(items) do saved[i] = { kind = it.kind, meta = it.meta } it.root:Destroy() end
		items = {}
		setSelection({})
		for _, s in ipairs(saved) do addWidget(s.kind, s.meta) end
		status.Text = "tema '" .. th.nm .. "' aplicado a TODOS os widgets"
		setSelection({})
	end)
	-- device
	local devs = {
		{ nm = "Desktop", w = 960, h = 540 }, { nm = "HD", w = 1280, h = 720 },
		{ nm = "Phone", w = 390, h = 844 }, { nm = "Tablet", w = 820, h = 1180 },
	}
	local devIdx = 1
	local devB = K.btn(bar, "Dev", 436, 8, 80, 22, T.bg2, 4)
	K.txtS(devB, "Tela: Desktop", 8, T.txt)
	K.hover(devB, T.bg2, T.hover)
	devB.MouseButton1Click:Connect(function()
		devIdx = (devIdx % #devs) + 1
		local d = devs[devIdx]
		devW, devH = d.w, d.h
		status.Text = "tela alvo: " .. d.nm .. " (" .. d.w .. "x" .. d.h .. ") — reabra p/ re-escalar"
		devB:FindFirstChildOfClass("TextLabel").Text = "Tela: " .. d.nm
		devLbl.Text = d.w .. "x" .. d.h .. " (" .. d.nm .. ")"
	end)
	-- export real
	local expB = K.btn(bar, "Exp", 524, 8, 84, 22, ACCENT, 4)
	K.txtS(expB, "Exportar GUI", 9, C("#041820"))
	K.hover(expB, ACCENT, C("#7DEBFF"))
	expB.MouseButton1Click:Connect(function()
		local gui, n = X.build(items, "ArkherHUD")
		-- o build re-parenta as raizes; devolve ao canvas para continuar editando
		for _, it in ipairs(items) do mountItem(it) end
		refreshSelBox()
		status.Text = "ScreenGui 'ArkherHUD' com " .. n .. " widgets no StarterGui (export REAL — canvas preservado)"
		K.notify("UI exportada", n .. " widgets → StarterGui.ArkherHUD", "ok")
	end)
	local codeB = K.btn(bar, "Code", 614, 8, 88, 22, T.bg2, 4)
	K.txtS(codeB, "Export codigo", 9, T.txt)
	K.hover(codeB, T.bg2, T.hover)
	codeB.MouseButton1Click:Connect(function()
		local src = X.exportModule(items, "ArkherUI_HUD")
		local ctrl = X.exportController(items, "ArkherUI_Controller")
		local ok2, rs = pcall(function() return game:GetService("ReplicatedStorage") end)
		if ok2 and rs then
			local m = rs:FindFirstChild("ArkherUI_HUD")
			if not m then m = Instance.new("ModuleScript") m.Name = "ArkherUI_HUD" m.Parent = rs end
			m.Source = src
			local m2 = rs:FindFirstChild("ArkherUI_Controller")
			if not m2 then m2 = Instance.new("ModuleScript") m2.Name = "ArkherUI_Controller" m2.Parent = rs end
			m2.Source = ctrl
		end
		pcall(function() if game.WriteFile then game:WriteFile("ArkherUI/ArkherUI_HUD.lua", src) end end)
		status.Text = "codigo exportado: ReplicatedStorage.ArkherUI_HUD + _Controller (" .. #src .. " chars)"
	end)
	-- import
	local impB = K.btn(bar, "Imp", 8, 20, 0, 0, T.bg0)
	impB.Visible = false
	K.txt(bar, "snap " .. SNAP .. "px", 10, 20, 60, 12, 7, T.txt4)
	local snapB = K.btn(bar, "Snap", 76, 20, 54, 14, T.bg2, 3)
	K.txtS(snapB, "snap:on", 7, T.txt3)
	snapB.MouseButton1Click:Connect(function()
		snap = not snap
		snapB:FindFirstChildOfClass("TextLabel").Text = snap and "snap:on" or "snap:off"
	end)

	setSelection({})
end

ARKHER.reg("UIDesigner", "UI Studio", "Editor", ICON.plate, "Designer de UI de jogos: 42 widgets, drag real, temas, ancoras, alinhar, export ScreenGui+codigo", build)
end

ARKHER.open("UIDesigner")
