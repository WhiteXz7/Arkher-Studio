--[[ ARKHER UI KIT X (AXI) — engine de UI de jogos (CUSTOM, widgets reais) ]]
-- 42 fabricas de widgets de HUD/menus, 6 temas completos, ferramentas de
-- alinhamento/ancoragem/distribuicao, export REAL (ScreenGui no StarterGui +
-- modul e codigo-fonte reproduzivel) e import de volta do StarterGui.
ArkherUIKitX = ArkherUIKitX or {}
local X = ArkherUIKitX
local floor = math.floor

-- ================= TEMAS =================
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
X.THEMES = {
	arkher = {
		nm = "Arkher Dark", bg = rgb(7, 13, 25), panel = rgb(15, 27, 51), card = rgb(11, 20, 36),
		txt = rgb(230, 235, 245), txt2 = rgb(154, 167, 192), accent = rgb(63, 127, 224),
		good = rgb(55, 200, 92), warn = rgb(232, 179, 60), bad = rgb(224, 82, 82), line = rgb(42, 59, 94),
	},
	neon = {
		nm = "Neon Night", bg = rgb(8, 8, 18), panel = rgb(18, 16, 38), card = rgb(12, 12, 28),
		txt = rgb(240, 240, 255), txt2 = rgb(150, 148, 190), accent = rgb(150, 80, 255),
		good = rgb(80, 255, 160), warn = rgb(255, 210, 80), bad = rgb(255, 80, 130), line = rgb(60, 50, 110),
	},
	light = {
		nm = "Light Paper", bg = rgb(246, 247, 250), panel = rgb(255, 255, 255), card = rgb(238, 240, 244),
		txt = rgb(24, 28, 40), txt2 = rgb(90, 98, 118), accent = rgb(46, 110, 220),
		good = rgb(30, 160, 80), warn = rgb(210, 150, 30), bad = rgb(210, 60, 60), line = rgb(210, 216, 226),
	},
	forest = {
		nm = "Forest", bg = rgb(10, 22, 14), panel = rgb(18, 40, 24), card = rgb(14, 30, 18),
		txt = rgb(228, 240, 228), txt2 = rgb(140, 170, 146), accent = rgb(70, 180, 96),
		good = rgb(110, 220, 130), warn = rgb(230, 190, 70), bad = rgb(220, 90, 70), line = rgb(40, 78, 52),
	},
	sunset = {
		nm = "Sunset", bg = rgb(28, 12, 22), panel = rgb(48, 20, 38), card = rgb(38, 16, 30),
		txt = rgb(248, 236, 240), txt2 = rgb(190, 150, 170), accent = rgb(240, 110, 80),
		good = rgb(120, 200, 110), warn = rgb(250, 190, 90), bad = rgb(230, 80, 100), line = rgb(88, 40, 70),
	},
	glass = {
		nm = "Mono Glass", bg = rgb(12, 14, 18), panel = rgb(26, 30, 38), card = rgb(20, 24, 30),
		txt = rgb(235, 240, 246), txt2 = rgb(150, 158, 172), accent = rgb(96, 165, 250),
		good = rgb(74, 222, 128), warn = rgb(250, 204, 21), bad = rgb(248, 113, 113), line = rgb(52, 60, 74),
	},
}
X.theme = X.THEMES.arkher
function X.setTheme(id) X.theme = X.THEMES[id] or X.THEMES.arkher return X.theme end

-- helpers de construcao
local function mk(class, parent, name)
	local inst = Instance.new(class)
	if name then inst.Name = name end
	if parent then inst.Parent = parent end
	return inst
end
local function corner(inst, r) local c = mk("UICorner", inst) c.CornerRadius = UDim.new(0, r or 6) return c end
local function stroke(inst, col, th) local s = mk("UIStroke", inst) s.Color = col or X.theme.line s.Thickness = th or 1 return s end
local function label(parent, text, x, y, w, h, size, color, align)
	local t = mk("TextLabel", parent, "Text")
	t.Position = UDim2.fromOffset(x or 0, y or 0)
	t.Size = UDim2.fromOffset(w or 60, h or 16)
	t.BackgroundTransparency = 1
	t.Text = tostring(text or "")
	t.TextColor3 = color or X.theme.txt
	t.TextSize = size or 12
	t.Font = Enum.Font.Gotham
	t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.TextTruncate = Enum.TextTruncate.AtEnd
	return t
end
local function baseFrame(id, meta)
	local f = mk("Frame", nil, id)
	f.BackgroundColor3 = X.theme.panel
	f.BorderSizePixel = 0
	f:SetAttribute("ARKHER_WIDGET", id)
	if meta then
		f.Position = UDim2.fromOffset(meta.x or 0, meta.y or 0)
		if meta.w and meta.h then f.Size = UDim2.fromOffset(meta.w, meta.h) end
	end
	return f
end

-- ================= FABRICAS (42 widgets) =================
X.WIDGETS = {}
local function W(id, cat, nm, size, fn) X.WIDGETS[id] = { id = id, cat = cat, nm = nm, w = size[1], h = size[2], fn = fn } end

-- ---- BASE ----
W("frame", "Base", "Frame", { 220, 140 }, function(o, t)
	local f = baseFrame("frame", o); f.Size = UDim2.fromOffset(o.w or 220, o.h or 140); corner(f, o.r or 6); stroke(f)
	return f
end)
W("label", "Base", "Label", { 160, 22 }, function(o, t)
	local t2 = label(nil, o.text or "Texto", 0, 0, o.w or 160, o.h or 22, o.size or 13)
	t2.Name = "label"; t2:SetAttribute("ARKHER_WIDGET", "label")
	t2.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	return t2
end)
W("button", "Base", "Botao", { 140, 34 }, function(o, t)
	local b = mk("TextButton", nil, "button")
	b.Size = UDim2.fromOffset(o.w or 140, o.h or 34)
	b.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	b.BackgroundColor3 = o.color or X.theme.accent
	b.TextColor3 = X.theme.bg
	b.Text = o.text or "Botao"
	b.TextSize = 13
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	corner(b, o.r or 6)
	b:SetAttribute("ARKHER_WIDGET", "button")
	return b
end)
W("textbox", "Base", "Campo de Texto", { 200, 30 }, function(o, t)
	local box = mk("TextBox", nil, "textbox")
	box.Size = UDim2.fromOffset(o.w or 200, o.h or 30)
	box.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	box.BackgroundColor3 = X.theme.card
	box.TextColor3 = X.theme.txt
	box.PlaceholderText = o.placeholder or "Digite..."
	box.PlaceholderColor3 = X.theme.txt2
	box.Text = o.text or ""
	box.TextSize = 12
	corner(box, 5); stroke(box)
	box:SetAttribute("ARKHER_WIDGET", "textbox")
	return box
end)
W("card", "Base", "Card", { 240, 90 }, function(o, t)
	local f = baseFrame("card", o); f.Size = UDim2.fromOffset(o.w or 240, o.h or 90); corner(f, 8); stroke(f)
	label(f, o.title or "Titulo", 12, 8, 200, 18, 13, X.theme.txt)
	label(f, o.sub or "descricao curta aqui", 12, 30, 210, 14, 11, X.theme.txt2)
	return f
end)
W("divider", "Base", "Divisor", { 200, 2 }, function(o, t)
	local f = baseFrame("divider", o); f.Size = UDim2.fromOffset(o.w or 200, 2); f.BackgroundColor3 = X.theme.line
	return f
end)
W("badge", "Base", "Badge", { 64, 22 }, function(o, t)
	local f = baseFrame("badge", o); f.Size = UDim2.fromOffset(o.w or 64, o.h or 22); corner(f, 11)
	f.BackgroundColor3 = o.color or X.theme.accent
	label(f, o.text or "NOVO", 0, 3, o.w or 64, 16, 10, X.theme.bg, Enum.TextXAlignment.Center)
	return f
end)
W("scroll", "Base", "Lista Scroll", { 220, 160 }, function(o, t)
	local f = mk("ScrollingFrame", nil, "scroll")
	f.Size = UDim2.fromOffset(o.w or 220, o.h or 160)
	f.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	f.BackgroundColor3 = X.theme.card
	f.BorderSizePixel = 0
	f.CanvasSize = UDim2.fromOffset(0, (o.h or 160) * 2)
	corner(f, 6); stroke(f)
	f:SetAttribute("ARKHER_WIDGET", "scroll")
	for i = 1, o.items or 6 do
		local row = mk("Frame", f, "Item" .. i)
		row.Size = UDim2.new(1, -16, 0, 30)
		row.Position = UDim2.fromOffset(8, 8 + (i - 1) * 36)
		row.BackgroundColor3 = X.theme.panel
		corner(row, 5)
		label(row, "Item " .. i, 10, 6, 130, 18, 12)
	end
	return f
end)
W("image", "Base", "Imagem", { 96, 96 }, function(o, t)
	local img = mk("ImageLabel", nil, "image")
	img.Size = UDim2.fromOffset(o.w or 96, o.h or 96)
	img.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	img.BackgroundColor3 = X.theme.card
	img.Image = o.image or ""
	img:SetAttribute("ARKHER_WIDGET", "image")
	corner(img, 8); stroke(img)
	return img
end)

-- ---- INPUT ----
W("toggle", "Input", "Toggle", { 60, 28 }, function(o, t)
	local f = baseFrame("toggle", o); f.Size = UDim2.fromOffset(60, 28); f.BackgroundColor3 = X.theme.card; corner(f, 14); stroke(f)
	local knob = mk("Frame", f, "Knob")
	knob.Size = UDim2.fromOffset(22, 22); knob.Position = UDim2.fromOffset(o.on and 34 or 4, 3)
	knob.BackgroundColor3 = o.on and X.theme.good or X.theme.txt2; corner(knob, 11)
	return f
end)
W("slider", "Input", "Slider", { 220, 30 }, function(o, t)
	local f = baseFrame("slider", o); f.Size = UDim2.fromOffset(o.w or 220, 30); f.BackgroundTransparency = 1
	local track = mk("Frame", f, "Track")
	track.Size = UDim2.fromOffset(o.w or 220, 6); track.Position = UDim2.fromOffset(0, 12)
	track.BackgroundColor3 = X.theme.line; corner(track, 3)
	local fill = mk("Frame", track, "Fill")
	fill.Size = UDim2.fromOffset(floor((o.w or 220) * (o.value or 0.5)), 6)
	fill.BackgroundColor3 = X.theme.accent; corner(fill, 3)
	local knob = mk("Frame", f, "Knob")
	knob.Size = UDim2.fromOffset(16, 16); knob.Position = UDim2.fromOffset(floor((o.w or 220) * (o.value or 0.5)) - 8, 7)
	knob.BackgroundColor3 = X.theme.txt; corner(knob, 8)
	return f
end)
W("checkbox", "Input", "Checkbox", { 130, 24 }, function(o, t)
	local f = baseFrame("checkbox", o); f.BackgroundTransparency = 1; f.Size = UDim2.fromOffset(o.w or 130, 24)
	local b = mk("Frame", f, "Box")
	b.Size = UDim2.fromOffset(20, 20); b.Position = UDim2.fromOffset(0, 2)
	b.BackgroundColor3 = o.on and X.theme.good or X.theme.card; corner(b, 4); stroke(b)
	if o.on then label(b, "OK", 0, 1, 20, 16, 11, X.theme.bg, Enum.TextXAlignment.Center) end
	label(f, o.text or "Opcao", 28, 3, (o.w or 130) - 28, 16, 12)
	return f
end)
W("dropdown", "Input", "Dropdown", { 200, 30 }, function(o, t)
	local f = baseFrame("dropdown", o); f.Size = UDim2.fromOffset(o.w or 200, o.h or 30); corner(f, 6); stroke(f)
	label(f, o.text or "Selecionar...", 10, 7, (o.w or 200) - 40, 16, 12, X.theme.txt2)
	label(f, "v", (o.w or 200) - 22, 7, 16, 16, 12, X.theme.txt, Enum.TextXAlignment.Center)
	return f
end)
W("keychip", "Input", "Tecla", { 40, 26 }, function(o, t)
	local f = baseFrame("keychip", o); f.Size = UDim2.fromOffset(o.w or 40, 26); corner(f, 5); stroke(f)
	label(f, o.text or "E", 0, 4, o.w or 40, 16, 12, X.theme.txt, Enum.TextXAlignment.Center)
	return f
end)

-- ---- DISPLAY ----
W("progressbar", "Display", "Barra de Progresso", { 240, 22 }, function(o, t)
	local f = baseFrame("progressbar", o); f.Size = UDim2.fromOffset(o.w or 240, 22); corner(f, 8); stroke(f)
	local fill = mk("Frame", f, "Fill")
	fill.Size = UDim2.fromOffset(floor((o.w or 240) * (o.value or 0.65)), 22)
	fill.BackgroundColor3 = o.color or X.theme.accent; corner(fill, 8)
	label(f, o.text or (floor((o.value or 0.65) * 100) .. "%"), 8, 3, 120, 16, 11, X.theme.bg)
	return f
end)
W("ringprogress", "Display", "Anel de Progresso", { 64, 64 }, function(o, t)
	local f = baseFrame("ringprogress", o); f.Size = UDim2.fromOffset(64, 64); f.BackgroundTransparency = 1
	local outer = mk("Frame", f, "Out"); outer.Size = UDim2.fromOffset(64, 64); outer.BackgroundColor3 = X.theme.card; corner(outer, 32); stroke(outer, X.theme.accent, 3)
	local inner = mk("Frame", outer, "In"); inner.Size = UDim2.fromOffset(46, 46); inner.Position = UDim2.fromOffset(9, 9); inner.BackgroundColor3 = X.theme.bg; corner(inner, 23)
	label(inner, floor((o.value or 0.7) * 100) .. "%", 0, 14, 46, 18, 13, X.theme.txt, Enum.TextXAlignment.Center)
	return f
end)
W("tooltip", "Display", "Tooltip", { 180, 44 }, function(o, t)
	local f = baseFrame("tooltip", o); f.Size = UDim2.fromOffset(o.w or 180, 44); f.BackgroundColor3 = X.theme.bg; corner(f, 6); stroke(f, X.theme.accent)
	label(f, o.title or "Dica", 10, 5, 160, 14, 11, X.theme.accent)
	label(f, o.text or "Informacao do item aqui", 10, 21, 160, 14, 10, X.theme.txt2)
	return f
end)
W("toast", "Display", "Toast", { 260, 40 }, function(o, t)
	local f = baseFrame("toast", o); f.Size = UDim2.fromOffset(260, 40); corner(f, 7); stroke(f)
	local bar = mk("Frame", f, "Bar"); bar.Size = UDim2.fromOffset(3, 40); bar.BackgroundColor3 = o.color or X.theme.good
	label(f, o.title or "Conquista!", 12, 5, 200, 15, 12, X.theme.txt)
	label(f, o.text or "voce desbloqueou algo", 12, 21, 200, 13, 10, X.theme.txt2)
	return f
end)
W("modal", "Display", "Modal", { 300, 160 }, function(o, t)
	local f = baseFrame("modal", o); f.Size = UDim2.fromOffset(o.w or 300, o.h or 160); corner(f, 10); stroke(f)
	label(f, o.title or "Confirmar", 0, 14, o.w or 300, 20, 15, X.theme.txt, Enum.TextXAlignment.Center)
	label(f, o.text or "Deseja continuar?", 0, 44, o.w or 300, 16, 12, X.theme.txt2, Enum.TextXAlignment.Center)
	local wb = o.w or 300
	local yes = X.WIDGETS.button.fn({ x = wb / 2 - 106, y = 96, w = 96, h = 30, text = "Sim", color = X.theme.good }, t); yes.Parent = f
	local no = X.WIDGETS.button.fn({ x = wb / 2 + 10, y = 96, w = 96, h = 30, text = "Nao", color = X.theme.card }, t); no.Parent = f
	return f
end)
W("loadingbar", "Display", "Loading", { 280, 30 }, function(o, t)
	local f = baseFrame("loadingbar", o); f.Size = UDim2.fromOffset(280, 30); f.BackgroundTransparency = 1
	local track = mk("Frame", f, "T"); track.Size = UDim2.fromOffset(280, 10); track.Position = UDim2.fromOffset(0, 4); track.BackgroundColor3 = X.theme.line; corner(track, 5)
	local stripes = o.stripes or 8
	for i = 1, stripes do
		local s = mk("Frame", track, "S" .. i)
		s.Size = UDim2.fromOffset(floor(272 / stripes) - 4, 6)
		s.Position = UDim2.fromOffset(3 + (i - 1) * floor(272 / stripes), 2)
		s.BackgroundColor3 = i <= floor(stripes * (o.value or 0.6)) and X.theme.accent or X.theme.panel
		corner(s, 3)
	end
	label(f, o.text or "Carregando mundo...", 0, 17, 200, 12, 10, X.theme.txt2)
	return f
end)
W("statblock", "Display", "Bloco Stat", { 120, 54 }, function(o, t)
	local f = baseFrame("statblock", o); f.Size = UDim2.fromOffset(120, 54); corner(f, 7); stroke(f)
	label(f, o.title or "KILLS", 10, 6, 100, 12, 10, X.theme.txt2)
	label(f, o.text or "128", 10, 22, 100, 24, 20, o.color or X.theme.accent)
	return f
end)

-- ---- HUD DE JOGO ----
W("health", "HUD", "Barra de Vida", { 220, 26 }, function(o, t)
	local f = baseFrame("health", o); f.Size = UDim2.fromOffset(o.w or 220, 26); corner(f, 9); stroke(f)
	local fill = mk("Frame", f, "Fill")
	fill.Size = UDim2.fromOffset(floor((o.w or 220) * (o.value or 0.85)), 26)
	fill.BackgroundColor3 = X.theme.good; corner(fill, 9)
	label(f, o.text or "85 HP", 10, 5, 90, 16, 12, X.theme.bg)
	local heart = label(f, "+", (o.w or 220) - 24, 3, 18, 18, 16, X.theme.bg, Enum.TextXAlignment.Center)
	return f
end)
W("stamina", "HUD", "Barra de Stamina", { 220, 14 }, function(o, t)
	local f = baseFrame("stamina", o); f.Size = UDim2.fromOffset(o.w or 220, 14); corner(f, 7); stroke(f)
	local fill = mk("Frame", f, "F")
	fill.Size = UDim2.fromOffset(floor((o.w or 220) * (o.value or 0.6)), 14)
	fill.BackgroundColor3 = X.theme.warn; corner(fill, 7)
	return f
end)
W("xpbar", "HUD", "Barra de XP", { 320, 20 }, function(o, t)
	local f = baseFrame("xpbar", o); f.Size = UDim2.fromOffset(o.w or 320, 20); corner(f, 8); stroke(f)
	local fill = mk("Frame", f, "F")
	fill.Size = UDim2.fromOffset(floor((o.w or 320) * (o.value or 0.42)), 20)
	fill.BackgroundColor3 = o.color or X.theme.accent; corner(fill, 8)
	label(f, "XP " .. floor((o.value or 0.42) * (o.max or 1000)) .. "/" .. (o.max or 1000), 0, 2, o.w or 320, 16, 11, X.theme.txt, Enum.TextXAlignment.Center)
	return f
end)
W("levelbadge", "HUD", "Selo de Nivel", { 44, 44 }, function(o, t)
	local f = baseFrame("levelbadge", o); f.Size = UDim2.fromOffset(44, 44); corner(f, 22); stroke(f, X.theme.warn, 2)
	f.BackgroundColor3 = X.theme.card
	label(f, o.text or "12", 4, 12, 36, 20, 16, X.theme.warn, Enum.TextXAlignment.Center)
	return f
end)
W("hotbar", "HUD", "Hotbar", { 348, 62 }, function(o, t)
	local slots = o.slots or 5
	local f = baseFrame("hotbar", o); f.Size = UDim2.fromOffset(slots * 62 + 8, 62); f.BackgroundTransparency = 1
	for i = 1, slots do
		local s = mk("Frame", f, "Slot" .. i)
		s.Size = UDim2.fromOffset(54, 54); s.Position = UDim2.fromOffset(4 + (i - 1) * 62, 4)
		s.BackgroundColor3 = X.theme.card; corner(s, 7); stroke(s, i == (o.selected or 1) and X.theme.accent or X.theme.line, i == (o.selected or 1) and 2 or 1)
		label(s, tostring(i), 3, 2, 14, 12, 9, X.theme.txt2)
	end
	return f
end)
W("inventory", "HUD", "Inventario", { 300, 220 }, function(o, t)
	local cols, rows = o.cols or 5, o.rows or 4
	local f = baseFrame("inventory", o); f.Size = UDim2.fromOffset(cols * 56 + 20, rows * 56 + 44); corner(f, 8); stroke(f)
	label(f, o.title or "INVENTARIO", 12, 8, 180, 16, 11, X.theme.txt2)
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local s = mk("Frame", f, "S" .. r .. "_" .. c)
			s.Size = UDim2.fromOffset(48, 48); s.Position = UDim2.fromOffset(10 + c * 56, 34 + r * 56)
			s.BackgroundColor3 = X.theme.card; corner(s, 6); stroke(s)
			if (r * cols + c) < (o.items or 7) then
				local chip = mk("Frame", s, "I"); chip.Size = UDim2.fromOffset(30, 30); chip.Position = UDim2.fromOffset(9, 9)
				chip.BackgroundColor3 = ({ X.theme.accent, X.theme.good, X.theme.warn, X.theme.bad })[(r * cols + c) % 4 + 1]; corner(chip, 5)
			end
		end
	end
	return f
end)
W("coins", "HUD", "Contador de Moedas", { 130, 32 }, function(o, t)
	local f = baseFrame("coins", o); f.Size = UDim2.fromOffset(130, 32); corner(f, 16); stroke(f)
	local c = mk("Frame", f, "C"); c.Size = UDim2.fromOffset(18, 18); c.Position = UDim2.fromOffset(8, 7); c.BackgroundColor3 = X.theme.warn; corner(c, 9)
	label(f, o.text or "12.4K", 32, 7, 88, 18, 13, X.theme.txt)
	return f
end)
W("gems", "HUD", "Contador de Gemas", { 130, 32 }, function(o, t)
	local f = baseFrame("gems", o); f.Size = UDim2.fromOffset(130, 32); corner(f, 16); stroke(f)
	local d = mk("Frame", f, "D"); d.Size = UDim2.fromOffset(16, 16); d.Position = UDim2.fromOffset(9, 8); d.BackgroundColor3 = X.theme.accent; d.Rotation = 45
	label(f, o.text or "3.2K", 34, 7, 86, 18, 13, X.theme.txt)
	return f
end)
W("timer", "HUD", "Timer", { 110, 34 }, function(o, t)
	local f = baseFrame("timer", o); f.Size = UDim2.fromOffset(110, 34); corner(f, 8); stroke(f, X.theme.warn)
	label(f, o.text or "04:59", 0, 8, 110, 20, 16, X.theme.warn, Enum.TextXAlignment.Center)
	return f
end)
W("crosshair", "HUD", "Mira", { 28, 28 }, function(o, t)
	local f = baseFrame("crosshair", o); f.Size = UDim2.fromOffset(28, 28); f.BackgroundTransparency = 1
	local c = X.theme.txt
	local h1 = mk("Frame", f, "h1"); h1.Size = UDim2.fromOffset(2, 8); h1.Position = UDim2.fromOffset(13, 0); h1.BackgroundColor3 = c
	local h2 = mk("Frame", f, "h2"); h2.Size = UDim2.fromOffset(2, 8); h2.Position = UDim2.fromOffset(13, 20); h2.BackgroundColor3 = c
	local v1 = mk("Frame", f, "v1"); v1.Size = UDim2.fromOffset(8, 2); v1.Position = UDim2.fromOffset(0, 13); v1.BackgroundColor3 = c
	local v2 = mk("Frame", f, "v2"); v2.Size = UDim2.fromOffset(8, 2); v2.Position = UDim2.fromOffset(20, 13); v2.BackgroundColor3 = c
	return f
end)
W("minimap", "HUD", "Minimapa", { 150, 150 }, function(o, t)
	local f = baseFrame("minimap", o); f.Size = UDim2.fromOffset(150, 150); corner(f, 10); stroke(f)
	for i = 1, 6 do
		local dot = mk("Frame", f, "P" .. i)
		dot.Size = UDim2.fromOffset(6, 6); dot.Position = UDim2.fromOffset((i * 37) % 132 + 6, (i * 53) % 132 + 6)
		dot.BackgroundColor3 = ({ X.theme.good, X.theme.bad, X.theme.warn })[i % 3 + 1]; corner(dot, 3)
	end
	local me = mk("Frame", f, "Me"); me.Size = UDim2.fromOffset(10, 10); me.Position = UDim2.fromOffset(70, 70); me.BackgroundColor3 = X.theme.accent; corner(me, 5)
	return f
end)
W("bossbar", "HUD", "Barra de Boss", { 420, 34 }, function(o, t)
	local f = baseFrame("bossbar", o); f.Size = UDim2.fromOffset(o.w or 420, 34); f.BackgroundTransparency = 1
	label(f, o.name or "ARKHER, O ANCIAO", 0, 0, o.w or 420, 14, 11, X.theme.bad, Enum.TextXAlignment.Center)
	local bg = mk("Frame", f, "BG"); bg.Size = UDim2.fromOffset(o.w or 420, 14); bg.Position = UDim2.fromOffset(0, 18); bg.BackgroundColor3 = X.theme.card; corner(bg, 7); stroke(bg, X.theme.bad, 1)
	local fill = mk("Frame", bg, "F"); fill.Size = UDim2.fromOffset(floor((o.w or 420) * (o.value or 0.7)), 14); fill.BackgroundColor3 = X.theme.bad; corner(fill, 7)
	return f
end)
W("compass", "HUD", "Bussola", { 280, 26 }, function(o, t)
	local f = baseFrame("compass", o); f.Size = UDim2.fromOffset(280, 26); f.BackgroundColor3 = X.theme.card; corner(f, 8); stroke(f)
	local pts = { "N", "NE", "E", "SE", "S", "SO", "O", "NO" }
	for i, p in ipairs(pts) do
		label(f, p, floor(-140 + i * 35 - 18) + 140, 5, 30, 16, 10, i == 1 and X.theme.warn or X.theme.txt2, Enum.TextXAlignment.Center)
	end
	return f
end)
W("damage", "HUD", "Numero de Dano", { 70, 26 }, function(o, t)
	local f = baseFrame("damage", o); f.BackgroundTransparency = 1; f.Size = UDim2.fromOffset(70, 26)
	local l = label(f, o.text or "-128", 0, 2, 70, 22, 17, o.color or X.theme.bad, Enum.TextXAlignment.Center)
	pcall(function()
		l.TextStrokeTransparency = 0.4
	end)
	return f
end)
W("feed", "HUD", "Kill Feed", { 260, 110 }, function(o, t)
	local f = baseFrame("feed", o); f.Size = UDim2.fromOffset(260, (o.items or 4) * 26 + 8); f.BackgroundTransparency = 1
	local samples = o.samples or { "ARKHER x1 eliminou SK", "HEADSHOT! +250", "SNB entrou no servidor", "UES dominou o mapa" }
	for i = 1, o.items or 4 do
		local row = mk("Frame", f, "E" .. i)
		row.Size = UDim2.fromOffset(260, 22); row.Position = UDim2.fromOffset(0, 4 + (i - 1) * 26)
		row.BackgroundColor3 = X.theme.card; corner(row, 4)
		row.BackgroundTransparency = 0.25
		label(row, samples[((i - 1) % #samples) + 1], 8, 4, 246, 14, 10, X.theme.txt)
	end
	return f
end)
W("oxygen", "HUD", "Oxigenio", { 180, 16 }, function(o, t)
	local f = baseFrame("oxygen", o); f.Size = UDim2.fromOffset(180, 16); corner(f, 8); stroke(f)
	local fill = mk("Frame", f, "F"); fill.Size = UDim2.fromOffset(floor(180 * (o.value or 0.4)), 16); fill.BackgroundColor3 = rgb(80, 160, 220); corner(fill, 8)
	label(f, "O2", 6, 1, 30, 14, 10, X.theme.bg)
	return f
end)
W("powergauge", "HUD", "Medidor de Poder", { 60, 160 }, function(o, t)
	local f = baseFrame("powergauge", o); f.Size = UDim2.fromOffset(60, 160); corner(f, 10); stroke(f)
	local segs = 10
	for i = 1, segs do
		local s = mk("Frame", f, "S" .. i)
		s.Size = UDim2.fromOffset(44, 11); s.Position = UDim2.fromOffset(8, 150 - i * 14)
		s.BackgroundColor3 = i <= floor(segs * (o.value or 0.6)) and X.theme.accent or X.theme.card
		corner(s, 3)
	end
	return f
end)

-- ---- MENUS / SISTEMA ----
W("menubutton", "Menu", "Botao de Menu", { 220, 44 }, function(o, t)
	local b = mk("TextButton", nil, "menubutton")
	b.Size = UDim2.fromOffset(o.w or 220, 44); b.Position = UDim2.fromOffset(o.x or 0, o.y or 0)
	b.BackgroundColor3 = X.theme.panel; b.Text = ""; corner(b, 8); stroke(b)
	label(b, o.text or "JOGAR", 18, 8, (o.w or 220) - 36, 18, 13, X.theme.txt)
	label(b, o.sub or "modo historia", 18, 25, (o.w or 220) - 36, 12, 9, X.theme.txt2)
	b:SetAttribute("ARKHER_WIDGET", "menubutton")
	return b
end)
W("title", "Menu", "Titulo", { 340, 58 }, function(o, t)
	local f = baseFrame("title", o); f.BackgroundTransparency = 1; f.Size = UDim2.fromOffset(340, 58)
	label(f, o.text or "ARKHER", 0, 0, 340, 34, 30, X.theme.accent, Enum.TextXAlignment.Center)
	label(f, o.sub or "U M A   R E A L I D A D E   N O V A", 0, 38, 340, 14, 10, X.theme.txt2, Enum.TextXAlignment.Center)
	return f
end)
W("tabview", "Menu", "Abas", { 320, 200 }, function(o, t)
	local f = baseFrame("tabview", o); f.Size = UDim2.fromOffset(o.w or 320, o.h or 200); corner(f, 8); stroke(f)
	local tabs = o.tabs or { "Geral", "Itens", "Stats" }
	for i, tb in ipairs(tabs) do
		local w = floor(((o.w or 320) - 16) / #tabs)
		local tab = mk("Frame", f, "Tab" .. i)
		tab.Size = UDim2.fromOffset(w - 4, 26); tab.Position = UDim2.fromOffset(8 + (i - 1) * w, 6)
		tab.BackgroundColor3 = i == 1 and X.theme.accent or X.theme.card; corner(tab, 5)
		label(tab, tb, 0, 5, w - 4, 14, 11, i == 1 and X.theme.bg or X.theme.txt2, Enum.TextXAlignment.Center)
	end
	local body = mk("Frame", f, "Body"); body.Size = UDim2.fromOffset((o.w or 320) - 16, (o.h or 200) - 44); body.Position = UDim2.fromOffset(8, 38)
	body.BackgroundColor3 = X.theme.card; corner(body, 6)
	label(body, "conteudo da aba 1", 10, 10, 180, 14, 11, X.theme.txt2)
	return f
end)
W("questtracker", "Menu", "Rastreador de Quest", { 260, 96 }, function(o, t)
	local f = baseFrame("questtracker", o); f.Size = UDim2.fromOffset(260, 96); corner(f, 8); stroke(f, X.theme.warn)
	label(f, "QUEST ATIVA", 12, 7, 160, 12, 10, X.theme.warn)
	label(f, o.title or "A Jornada dos D", 12, 22, 200, 16, 13, X.theme.txt)
	local rows = o.objectives or { { "Coletar 5 fragmentos", true }, { "Achar o portal", false }, { "Derrotar o eco", false } }
	for i, r2 in ipairs(rows) do
		label(f, (r2[2] and "[x] " or "[ ] ") .. r2[1], 12, 42 + (i - 1) * 16, 236, 14, 10, r2[2] and X.theme.good or X.theme.txt2)
	end
	return f
end)
W("dialogue", "Menu", "Caixa de Dialogo", { 420, 110 }, function(o, t)
	local f = baseFrame("dialogue", o); f.Size = UDim2.fromOffset(420, 110); corner(f, 9); stroke(f)
	local nameTag = mk("Frame", f, "Tag"); nameTag.Size = UDim2.fromOffset(110, 20); nameTag.Position = UDim2.fromOffset(12, -10); nameTag.BackgroundColor3 = X.theme.accent; corner(nameTag, 5)
	label(nameTag, o.name or "ARKHER", 0, 3, 110, 14, 11, X.theme.bg, Enum.TextXAlignment.Center)
	label(f, o.text or "A realidade nao se copia. Ela se representa — e depois se materializa.", 16, 22, 388, 44, 12, X.theme.txt)
	label(f, "E >", 380, 88, 30, 12, 10, X.theme.txt2)
	return f
end)
W("leaderboard", "Menu", "Placar", { 280, 170 }, function(o, t)
	local f = baseFrame("leaderboard", o); f.Size = UDim2.fromOffset(280, 24 + (o.rows or 5) * 28 + 8); corner(f, 8); stroke(f)
	label(f, "PLACAR", 12, 7, 120, 14, 11, X.theme.txt2)
	local names = o.names or { "ARKHER", "SNB", "UES", "Voz", "Eco" }
	for i = 1, o.rows or 5 do
		local row = mk("Frame", f, "R" .. i)
		row.Size = UDim2.fromOffset(262, 24); row.Position = UDim2.fromOffset(9, 26 + (i - 1) * 28)
		row.BackgroundColor3 = i == 1 and X.theme.card or X.theme.panel; corner(row, 5)
		label(row, "#" .. i, 8, 4, 26, 14, 11, i == 1 and X.theme.warn or X.theme.txt2)
		label(row, names[((i - 1) % #names) + 1], 40, 4, 120, 14, 11, X.theme.txt)
		label(row, tostring((6 - i) * 1320), 180, 4, 74, 14, 11, X.theme.accent, Enum.TextXAlignment.Right)
	end
	return f
end)
W("playerrow", "Menu", "Linha de Jogador", { 260, 34 }, function(o, t)
	local f = baseFrame("playerrow", o); f.Size = UDim2.fromOffset(260, 34); corner(f, 7); stroke(f)
	local av = mk("Frame", f, "Av"); av.Size = UDim2.fromOffset(24, 24); av.Position = UDim2.fromOffset(6, 5); av.BackgroundColor3 = X.theme.accent; corner(av, 12)
	label(av, (o.initials or "A"), 0, 5, 24, 14, 11, X.theme.bg, Enum.TextXAlignment.Center)
	label(f, o.name or "WhiteXz7", 40, 9, 120, 16, 12, X.theme.txt)
	label(f, o.ping or "42ms", 190, 9, 58, 16, 11, X.theme.good, Enum.TextXAlignment.Right)
	return f
end)
W("podium", "Menu", "Podio", { 240, 120 }, function(o, t)
	local f = baseFrame("podium", o); f.Size = UDim2.fromOffset(240, 120); f.BackgroundTransparency = 1
	local cols = { { 90, 60, X.theme.warn }, { 10, 84, X.theme.txt2 }, { 170, 44, rgb(190, 120, 60) } }
	for i, c in ipairs(cols) do
		local post = mk("Frame", f, "P" .. i)
		post.Size = UDim2.fromOffset(60, c[2]); post.Position = UDim2.fromOffset(c[1], 116 - c[2])
		post.BackgroundColor3 = X.theme.card; corner(post, 5); stroke(post, c[3], 2)
		label(post, "#" .. (i == 1 and 1 or i == 2 and 2 or 3), 0, 8, 60, 16, 14, c[3], Enum.TextXAlignment.Center)
	end
	return f
end)
W("countdown", "Menu", "Contagem Regressiva", { 140, 60 }, function(o, t)
	local f = baseFrame("countdown", o); f.BackgroundTransparency = 1; f.Size = UDim2.fromOffset(140, 60)
	local l = label(f, o.text or "3", 0, 0, 140, 52, 44, X.theme.bad, Enum.TextXAlignment.Center)
	return f
end)
W("banner", "Menu", "Banner", { 420, 60 }, function(o, t)
	local f = baseFrame("banner", o); f.Size = UDim2.fromOffset(420, 60); corner(f, 8); f.BackgroundColor3 = o.color or X.theme.accent
	label(f, o.text or "EVENTO: A CHEGADA DOS D", 0, 10, 420, 22, 17, X.theme.bg, Enum.TextXAlignment.Center)
	label(f, o.sub or "ate domingo as 18h", 0, 34, 420, 14, 11, X.theme.bg, Enum.TextXAlignment.Center)
	return f
end)
W("notification", "Menu", "Notificacao", { 290, 56 }, function(o, t)
	local f = baseFrame("notification", o); f.Size = UDim2.fromOffset(290, 56); corner(f, 8); stroke(f)
	local dot = mk("Frame", f, "Dot"); dot.Size = UDim2.fromOffset(8, 8); dot.Position = UDim2.fromOffset(12, 12); dot.BackgroundColor3 = o.color or X.theme.accent; corner(dot, 4)
	label(f, o.title or "Atualizacao do mundo", 28, 8, 230, 16, 12, X.theme.txt)
	label(f, o.text or "o terreno foi regenerado com seed 42", 28, 27, 240, 14, 10, X.theme.txt2)
	return f
end)
W("carousel", "Menu", "Carrossel", { 340, 90 }, function(o, t)
	local f = baseFrame("carousel", o); f.Size = UDim2.fromOffset(340, 90); f.BackgroundTransparency = 1
	for i = 1, 3 do
		local card2 = mk("Frame", f, "C" .. i)
		local w = i == 2 and 160 or 96
		card2.Size = UDim2.fromOffset(w, 84)
		card2.Position = UDim2.fromOffset(i == 1 and 0 or i == 2 and 90 - 0 or 340 - 96, 3)
		if i == 2 then card2.Position = UDim2.fromOffset(90, 3) end
		card2.BackgroundColor3 = i == 2 and X.theme.panel or X.theme.card
		corner(card2, 8); stroke(card2, i == 2 and X.theme.accent or X.theme.line)
		if i == 2 then label(card2, o.text or "MAPA 07", 0, 34, 160, 18, 13, X.theme.txt, Enum.TextXAlignment.Center) end
	end
	return f
end)

-- lista categorizada (para paletas de UI)
function X.catalog()
	local cats = {}
	for id, w in pairs(X.WIDGETS) do
		cats[w.cat] = cats[w.cat] or {}
		table.insert(cats[w.cat], { id = id, nm = w.nm, w = w.w, h = w.h })
	end
	for _, list in pairs(cats) do table.sort(list, function(a, b) return a.nm < b.nm end) end
	return cats
end

function X.create(id, opts)
	opts = opts or {}
	local def = X.WIDGETS[id]
	if not def then return nil, "widget desconhecido: " .. tostring(id) end
	local root = def.fn(opts, X.theme)
	return { root = root, kind = id, meta = { x = opts.x or 0, y = opts.y or 0, w = def.w, h = def.h, opts = opts } }
end

-- ================= LAYOUT / ALINHAMENTO =================
-- descritores: {root, kind, meta{x,y,w,h}} — retorna quantos moveu
function X.alignLeft(items) local n = 0 local minX = math.huge for _, it in ipairs(items) do if it.meta.x < minX then minX = it.meta.x end end for _, it in ipairs(items) do it.meta.x = minX n = n + 1 end return n end
function X.alignRight(items) local maxR = 0 for _, it in ipairs(items) do if it.meta.x + it.meta.w > maxR then maxR = it.meta.x + it.meta.w end end for _, it in ipairs(items) do it.meta.x = maxR - it.meta.w end return #items end
function X.alignHCenter(items) local cx = (items[1] and (items[1].meta.x + items[1].meta.w / 2)) or 0 for _, it in ipairs(items) do cx = math.max(cx, it.meta.x + it.meta.w / 2) end for _, it in ipairs(items) do it.meta.x = floor(cx - it.meta.w / 2) end return #items end
function X.alignTop(items) local minY = math.huge for _, it in ipairs(items) do if it.meta.y < minY then minY = it.meta.y end end for _, it in ipairs(items) do it.meta.y = minY end return #items end
function X.alignBottom(items) local maxB = 0 for _, it in ipairs(items) do if it.meta.y + it.meta.h > maxB then maxB = it.meta.y + it.meta.h end end for _, it in ipairs(items) do it.meta.y = maxB - it.meta.h end return #items end
function X.distributeH(items)
	if #items < 3 then return 0 end
	table.sort(items, function(a, b) return a.meta.x < b.meta.x end)
	local first, last = items[1], items[#items]
	local totalW = (last.meta.x + last.meta.w) - first.meta.x
	local content = 0 for _, it in ipairs(items) do content = content + it.meta.w end
	local gap = (totalW - content) / (#items - 1)
	local x = first.meta.x
	for _, it in ipairs(items) do it.meta.x = floor(x) x = x + it.meta.w + gap end
	return #items
end
function X.distributeV(items)
	if #items < 3 then return 0 end
	table.sort(items, function(a, b) return a.meta.y < b.meta.y end)
	local first, last = items[1], items[#items]
	local totalH = (last.meta.y + last.meta.h) - first.meta.y
	local content = 0 for _, it in ipairs(items) do content = content + it.meta.h end
	local gap = (totalH - content) / (#items - 1)
	local y = first.meta.y
	for _, it in ipairs(items) do it.meta.y = floor(y) y = y + it.meta.h + gap end
	return #items
end
X.ANCHORS = {
	centro = { 0.5, 0.5 }, sup_esq = { 0, 0 }, sup_centro = { 0.5, 0 }, sup_dir = { 1, 0 },
	meio_esq = { 0, 0.5 }, meio_dir = { 1, 0.5 }, inf_esq = { 0, 1 }, inf_centro = { 0.5, 1 }, inf_dir = { 1, 1 },
}
function X.anchorPreset(item, preset, guiW, guiH)
	local a = X.ANCHORS[preset]
	if not a then return false end
	item.meta.x = floor((guiW or 960) * a[1] - item.meta.w * a[1])
	item.meta.y = floor((guiH or 540) * a[2] - item.meta.h * a[2])
	return true
end

-- ================= BUILD REAL (ScreenGui) =================
function X.build(items, guiName, opts)
	opts = opts or {}
	local parent = opts.parent
	if not parent then
		local ok, sg = pcall(function() return game:GetService("StarterGui") end)
		parent = ok and sg or workspace
	end
	local old = parent:FindFirstChild(guiName)
	if old then old:Destroy() end
	local gui = mk("ScreenGui", nil, guiName or "ArkherHUD")
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("ARKHER_UIKIT", "1")
	local count = 0
	for i, it in ipairs(items) do
		local inst = it.root
		if inst and not inst:GetAttribute("ARKHER_WIDGET") then inst:SetAttribute("ARKHER_WIDGET", it.kind) end
		if inst then
			inst.Position = UDim2.fromOffset(it.meta.x, it.meta.y)
			inst.Name = (it.kind or "w") .. "_" .. i
			inst:SetAttribute("wkind", it.kind)
			inst.Parent = gui
			count = count + 1
		end
	end
	gui.Parent = parent
	return gui, count
end

-- aplica posicoes do meta nas raizes (apos mover/align no canvas)
function X.sync(items)
	for _, it in ipairs(items) do
		if it.root then it.root.Position = UDim2.fromOffset(it.meta.x, it.meta.y) end
	end
end

-- ================= EXPORT CODIGO-FONTE =================
function X.exportModule(items, moduleName)
	local L = {}
	L[#L + 1] = "-- " .. (moduleName or "ArkherUIExport") .. " — UI gerada pelo ARKHER UI Kit X"
	L[#L + 1] = "local function b(name, w, h, x, y, col)"
	L[#L + 1] = "\tlocal f = Instance.new(\"Frame\")"
	L[#L + 1] = "\tf.Name = name"
	L[#L + 1] = "\tf.Size = UDim2.fromOffset(w, h)"
	L[#L + 1] = "\tf.Position = UDim2.fromOffset(x, y)"
	L[#L + 1] = "\tf.BackgroundColor3 = Color3.fromRGB(" .. floor(X.theme.panel.R * 255) .. "," .. floor(X.theme.panel.G * 255) .. "," .. floor(X.theme.panel.B * 255) .. ")"
	L[#L + 1] = "\tf.BorderSizePixel = 0"
	L[#L + 1] = "\tlocal c = Instance.new(\"UICorner\") c.CornerRadius = UDim.new(0, 6) c.Parent = f"
	L[#L + 1] = "\tf:SetAttribute(\"ARKHER_WIDGET\", name)"
	L[#L + 1] = "\treturn f"
	L[#L + 1] = "end"
	L[#L + 1] = "local M = {}"
	L[#L + 1] = "function M.build(parent)"
	L[#L + 1] = "\tlocal gui = Instance.new(\"ScreenGui\")"
	L[#L + 1] = "\tgui.Name = \"" .. (moduleName or "ArkherUIExport") .. "\""
	L[#L + 1] = "\tgui.ResetOnSpawn = false"
	for i, it in ipairs(items) do
		L[#L + 1] = "\tlocal w" .. i .. " = b(\"" .. (it.kind or "widget") .. "\", " .. it.meta.w .. ", " .. it.meta.h .. ", " .. it.meta.x .. ", " .. it.meta.y .. ")"
		L[#L + 1] = "\tw" .. i .. ":SetAttribute(\"wkind\", \"" .. (it.kind or "?") .. "\")"
	end
	for i = 1, #items do
		L[#L + 1] = "\tw" .. i .. ".Parent = gui"
	end
	L[#L + 1] = "\tgui.Parent = parent"
	L[#L + 1] = "\treturn gui"
	L[#L + 1] = "end"
	L[#L + 1] = "return M"
	return table.concat(L, "\n")
end
function X.exportController(items, controllerName)
	local L = {}
	L[#L + 1] = "-- " .. (controllerName or "ArkherUIController") .. " — conecta eventos da UI"
	L[#L + 1] = "local M = {}"
	L[#L + 1] = "function M.bind(gui)"
	for i, it in ipairs(items) do
		local kind = it.kind or ""
		if kind == "button" or kind == "menubutton" then
			L[#L + 1] = "\tlocal b" .. i .. " = gui:FindFirstChildOfClass(\"TextButton\")"
			L[#L + 1] = "\tif b" .. i .. " then b" .. i .. ".Activated:Connect(function() print(\"[" .. kind .. "_" .. i .. "] clicado\") end) end"
		end
	end
	L[#L + 1] = "end"
	L[#L + 1] = "return M"
	return table.concat(L, "\n")
end
-- ================= IMPORT =================
function X.importGui(gui)
	local items = {}
	for _, ch in ipairs(gui:GetChildren()) do
		local kind = ch:GetAttribute("wkind") or ch:GetAttribute("ARKHER_WIDGET") or ch.ClassName
		local x, y = 0, 0
		local w, h = 60, 30
		pcall(function()
			x = floor(ch.Position.X.Offset + 0.5); y = floor(ch.Position.Y.Offset + 0.5)
			w = floor(ch.Size.X.Offset + 0.5); h = floor(ch.Size.Y.Offset + 0.5)
		end)
		items[#items + 1] = { root = ch, kind = tostring(kind), meta = { x = x, y = y, w = w, h = h } }
	end
	return items
end

X._version = "1.0.0"
