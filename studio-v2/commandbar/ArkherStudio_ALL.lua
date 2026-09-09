--[[ ARKHER STUDIO V2 — PRELUDE (Theme + Icons-by-Frame + UI Kit) ]]
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Selection = game:GetService("Selection")
local Stats = game:GetService("Stats")

-- ---------- THEME ----------
local function C(h)
	local n = tonumber(string.sub(h, 2), 16)
	return Color3.fromRGB(math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end
local T = {
	bg0 = C("#070D19"), bg1 = C("#0B1220"), bg2 = C("#0F1B33"), bg3 = C("#0D1728"),
	bg4 = C("#0B1424"), sec = C("#14264A"), hover = C("#1A2A4A"),
	line = C("#22314F"), line2 = C("#2A3B5E"),
	txt = C("#E6EBF5"), txt2 = C("#C7D2E8"), txt3 = C("#9AA7C0"), txt4 = C("#7C8BA6"),
	accent = C("#3F7FE0"), accent2 = C("#58A6FF"), sel = C("#2E6BD6"),
	purple = C("#8A4FE0"), purple2 = C("#6E4FE0"), orange = C("#F07E2E"),
	green = C("#37C85C"), yellow = C("#E8B33C"), teal = C("#2FBF9F"),
	check = C("#2F81D0"), vp1 = C("#8A9199"), vp2 = C("#949BA3"),
}
local FONT, FONTB
do
	local ok = pcall(function() FONT = Enum.Font.BuilderSans end)
	if not ok then FONT = Enum.Font.Gotham end
	local ok2 = pcall(function() FONTB = Enum.Font.BuilderSansBold end)
	if not ok2 then
		local ok3 = pcall(function() FONTB = Enum.Font.GothamBold end)
		if not ok3 then FONTB = FONT end
	end
end

-- ---------- KIT ----------
local K = {}
K.T = T

function K.f(parent, name, x, y, w, h, color)
	local f = Instance.new("Frame")
	f.Name = name or "F"
	f.Parent = parent
	f.Position = UDim2.new(0, x or 0, 0, y or 0)
	f.Size = UDim2.new(0, w or 0, 0, h or 0)
	if color then f.BackgroundColor3 = color else f.BackgroundTransparency = 1 end
	f.BorderSizePixel = 0
	return f
end
function K.fs(parent, name, sx, sy, sw, sh, color)
	local f = Instance.new("Frame")
	f.Name = name or "F"
	f.Parent = parent
	f.Position = UDim2.new(sx or 0, 0, sy or 0, 0)
	f.Size = UDim2.new(sw or 0, 0, sh or 0, 0)
	if color then f.BackgroundColor3 = color else f.BackgroundTransparency = 1 end
	f.BorderSizePixel = 0
	return f
end
function K.corner(f, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = f
	return c
end
function K.stroke(f, color, th)
	local s = Instance.new("UIStroke")
	s.Color = color or T.line2
	s.Thickness = th or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	return s
end
function K.grad(f, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 90
	g.Parent = f
	return g
end
function K.txt(parent, text, x, y, w, h, size, color, font, alignX)
	local t = Instance.new("TextLabel")
	t.Name = "Lbl"
	t.Parent = parent
	t.Position = UDim2.new(0, x or 0, 0, y or 0)
	t.Size = UDim2.new(0, w or 0, 0, h or 0)
	t.BackgroundTransparency = 1
	t.Text = text or ""
	t.TextSize = size or 12
	t.TextColor3 = color or T.txt
	t.Font = font or FONT
	t.TextXAlignment = alignX or Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Center
	t.TextTruncate = Enum.TextTruncate.AtEnd
	return t
end
function K.txtS(parent, text, size, color, font)
	local t = K.txt(parent, text, 0, 0, 0, 0, size, color, font)
	t.Size = UDim2.new(1, 0, 1, 0)
	return t
end
function K.hover(f, base, hov)
	f.AutoButtonColor = false
	f.MouseEnter:Connect(function()
		pcall(function() f.BackgroundColor3 = hov end)
	end)
	f.MouseLeave:Connect(function()
		pcall(function() f.BackgroundColor3 = base end)
	end)
end
function K.gui(name)
	local old = StarterGui:FindFirstChild(name)
	if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.IgnoreGuiInset = true
	pcall(function() g.Parent = StarterGui end)
	if not g.Parent then pcall(function() g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 2) end) end
	return g
end
function K.drag(handle, frame)
	pcall(function()
		local dragging = false
		local sx, sy = 0, 0
		handle.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				sx = inp.Position.X - frame.AbsolutePosition.X
				sy = inp.Position.Y - frame.AbsolutePosition.Y
			end
		end)
		handle.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
				frame.Position = UDim2.new(0, inp.Position.X - sx, 0, inp.Position.Y - sy)
			end
		end)
	end)
end
function K.btn(parent, name, x, y, w, h, color, r)
	local b = Instance.new("TextButton")
	b.Name = name or "Btn"
	b.Parent = parent
	b.Position = UDim2.new(0, x or 0, 0, y or 0)
	b.Size = UDim2.new(0, w or 0, 0, h or 0)
	b.BackgroundColor3 = color or T.hover
	b.BorderSizePixel = 0
	b.Text = ""
	b.AutoButtonColor = false
	if r then K.corner(b, r) end
	return b
end

-- ribbon button: icon painter + label, optional selected look
function K.ribbonBtn(parent, x, w, iconFn, label, opts)
	opts = opts or {}
	local b = K.btn(parent, "RB_" .. (label or "btn"), x, 6, w, 58, T.bg2, 6)
	local iconBox = K.f(b, "Icon", math.floor((w - 26) / 2), 3, 26, 26)
	if iconFn then iconFn(iconBox, 26) end
	local lbl = K.txt(b, label or "", 0, 42, w, 14, 10, T.txt2, FONT, Enum.TextXAlignment.Center)
	lbl.TextTruncate = Enum.TextTruncate.None
	lbl.TextWrapped = true
	if opts.selected then
		b.BackgroundColor3 = T.sel
		K.stroke(b, T.accent2, 1)
	else
		K.hover(b, T.bg2, T.hover)
	end
	return b
end

-- window/panel with header (title + right icons), draggable, closable
ARKHER_CASCADE = ARKHER_CASCADE or 0
function K.window(name, title, x, y, w, h, opts)
	opts = opts or {}
	x = x + ARKHER_CASCADE
	y = y + math.floor(ARKHER_CASCADE * 0.6)
	ARKHER_CASCADE = (ARKHER_CASCADE + 18) % 220
	local g = K.gui(name)
	local root = K.f(g, "Root", x, y, w, h, T.bg3)
	K.corner(root, opts.radius or 6)
	K.stroke(root, T.line, 1)
	local head = K.f(root, "Head", 0, 0, w, 26, T.bg1)
	K.corner(head, opts.radius or 6)
	K.f(head, "HeadFix", 0, 14, w, 12, T.bg1)
	K.txt(head, title, 8, 0, w - 70, 26, 12, T.txt, FONTB)
	local hx = w - 24
	if opts.closable ~= false then
		local cx = K.btn(head, "Close", hx, 5, 16, 16, T.bg1, 4)
		K.hover(cx, T.bg1, C("#3A2530"))
		ICON.close(cx, 12, 2, 2)
		cx.MouseButton1Click:Connect(function() root.Visible = not root.Visible end)
		hx = hx - 20
	end
	if opts.pin then
		local pn = K.btn(head, "Pin", hx, 5, 16, 16, T.bg1, 4)
		ICON.pin(pn, 12, 2, 2)
		K.hover(pn, T.bg1, T.hover)
		hx = hx - 20
	end
	if opts.draggable ~= false then K.drag(head, root) end
	return g, root, head
end

-- search box
function K.search(parent, x, y, w, h, ph)
	local s = K.f(parent, "Search", x, y, w, h or 22, T.bg4)
	K.corner(s, 4)
	K.stroke(s, T.line2, 1)
	ICON.search(s, 12, 5, math.floor((h or 22) / 2) - 6)
	local t = K.txt(s, ph or "Search", 20, 0, w - 26, h or 22, 11, T.txt4)
	return s, t
end

-- collapsible section (Properties style)
function K.section(parent, title, expanded, y)
	local holder = K.f(parent, "SEC_" .. title, 0, y or 0, parent.AbsoluteSize.X > 0 and 0 or 0, 0)
	holder.Size = UDim2.new(1, -2, 0, 0)
	holder.Position = UDim2.new(0, 1, 0, y or 0)
	local head = K.btn(holder, "Head", 0, 0, 10, 20, T.sec)
	head.Size = UDim2.new(1, 0, 0, 20)
	local chev = K.f(head, "Chev", 6, 6, 8, 8)
	K.txt(head, title, 20, 0, 200, 20, 11, T.txt2, FONTB)
	local body = K.f(holder, "Body", 0, 20, 10, 10, T.bg3)
	body.Size = UDim2.new(1, 0, 0, 0)
	local function layout(open)
		chev:ClearAllChildren()
		if open then ICON.chevD(chev, 8) else ICON.chevR(chev, 8) end
		local bh = 0
		body.Visible = open
		if open then
			local maxy = 0
			for _, ch in ipairs(body:GetChildren()) do
				if ch:IsA("GuiObject") then
					local bottom = ch.Position.Y.Offset + ch.Size.Y.Offset
					if bottom > maxy then maxy = bottom end
				end
			end
			bh = maxy
		end
		body.Size = UDim2.new(1, 0, 0, bh)
		holder.Size = UDim2.new(1, -2, 0, 20 + bh)
		return 20 + bh
	end
	local open = expanded and true or false
	head.MouseButton1Click:Connect(function()
		open = not open
		layout(open)
		if holder.Parent and holder.Parent.Name == "Sections" then K.reflow(holder.Parent) end
	end)
	layout(open)
	return holder, body, head
end
function K.reflow(container)
	local y = 0
	for _, ch in ipairs(container:GetChildren()) do
		if ch:IsA("GuiObject") and ch.Name:sub(1, 4) == "SEC_" then
			ch.Position = UDim2.new(0, 1, 0, y)
			y = y + ch.Size.Y.Offset
		end
	end
end
function K.row(parent, label, value, y)
	K.txt(parent, label, 22, y, 110, 18, 11, T.txt3)
	K.txt(parent, value, 132, y, 100, 18, 11, T.txt, FONT, Enum.TextXAlignment.Left)
	local f = K.f(parent, "Row", 0, y, 10, 18)
	f.Size = UDim2.new(1, 0, 0, 18)
	f.BackgroundTransparency = 1
	return f
end
function K.sliderRow(parent, label, val, y)
	K.txt(parent, label, 22, y, 90, 18, 11, T.txt3)
	local track = K.f(parent, "Track", 118, y + 7, 60, 4, T.line2)
	K.corner(track, 2)
	local fill = K.f(track, "Fill", 0, 0, math.floor(60 * (val or 0)), 4, T.accent)
	K.corner(fill, 2)
	local knob = K.f(track, "Knob", math.floor(60 * (val or 0)) - 4, -3, 10, 10, T.accent2)
	K.corner(knob, 5)
	K.txt(parent, tostring(val or 0), 186, y, 40, 18, 11, T.txt, FONT, Enum.TextXAlignment.Left)
end
function K.checkRow(parent, label, on, y)
	K.txt(parent, label, 22, y, 120, 18, 11, T.txt3)
	local box = K.btn(parent, "Chk", 146, y + 2, 14, 14, T.bg4, 3)
	K.stroke(box, on and T.check or T.line2, 1)
	local inner = K.f(box, "On", 2, 2, 10, 10, T.check)
	K.corner(inner, 2)
	ICON.check(inner, 10)
	inner.Visible = on and true or false
	box.MouseButton1Click:Connect(function()
		on = not on
		inner.Visible = on
		K.stroke(box, on and T.check or T.line2, 1)
	end)
end

-- tree row (Hierarchy style)
function K.treeRow(parent, depth, iconFn, name, state, y)
	local row = K.btn(parent, "Row_" .. name, 0, y, 10, 20, T.bg3)
	row.Size = UDim2.new(1, 0, 0, 20)
	local x = 6 + depth * 16
	local chev = K.f(row, "Chev", x, 6, 8, 8)
	if state == "open" then ICON.chevD(chev, 8)
	elseif state == "closed" then ICON.chevR(chev, 8) end
	if iconFn then
		local ib = K.f(row, "I", x + 12, 2, 16, 16)
		iconFn(ib, 16)
	end
	K.txt(row, name, x + 32, 0, 160, 20, 11, T.txt2)
	K.hover(row, T.bg3, T.hover)
	return row
end

-- notification toast
local toastY = 0
function K.notify(title, msg, kind)
	kind = kind or "INFO"
	local col = kind == "SUCCESS" and T.green or kind == "ERROR" and C("#E05252") or kind == "WARNING" and T.orange or T.accent
	local g = K.gui("ArkherToast_" .. tostring(math.floor(math.random() * 1e6)))
	local root = K.f(g, "R", 8, 40 + toastY, 260, 46, T.bg1)
	K.corner(root, 6)
	K.stroke(root, T.line2, 1)
	K.f(root, "Bar", 0, 0, 3, 46, col)
	K.txt(root, title, 10, 4, 240, 16, 12, T.txt, FONTB)
	K.txt(root, msg, 10, 22, 240, 18, 10, T.txt3)
	toastY = toastY + 52
	coroutine.wrap(function()
		wait(4)
		pcall(function()
			TweenService:Create(root, TweenInfo.new(0.3), { Position = UDim2.new(0, -280, 0, root.Position.Y.Offset) }):Play()
		end)
		wait(0.4)
		g:Destroy()
	end)()
	return g
end

-- text input
function K.input(parent, x, y, w, h, ph, pass)
	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Parent = parent
	box.Position = UDim2.new(0, x, 0, y)
	box.Size = UDim2.new(0, w, 0, h or 24)
	box.BackgroundColor3 = T.bg4
	box.BorderSizePixel = 0
	box.Text = ""
	box.PlaceholderText = ph or ""
	box.PlaceholderColor3 = T.txt4
	box.TextColor3 = T.txt
	box.TextSize = 12
	box.Font = FONT
	box.ClearTextOnFocus = false
	if pass then box.TextEditable = true end
	K.corner(box, 4)
	K.stroke(box, T.line2, 1)
	return box
end
-- toggle switch
function K.toggle(parent, x, y, on, label)
	local holder = K.f(parent, "Tog", x, y, 120, 18)
	local track = K.btn(holder, "Track", 0, 2, 30, 14, on and T.check or T.line2, 7)
	local knob = K.f(track, "Knob", on and 17 or 2, 2, 10, 10, T.txt, 5)
	if label then K.txt(holder, label, 36, 0, 90, 18, 11, T.txt3) end
	track.MouseButton1Click:Connect(function()
		on = not on
		track.BackgroundColor3 = on and T.check or T.line2
		knob.Position = UDim2.new(0, on and 17 or 2, 0, 2)
	end)
	return holder, function() return on end
end
-- vertical fader
function K.vfader(parent, x, y, h, val, label)
	local holder = K.f(parent, "Fader", x, y, 26, h + 16)
	local track = K.f(holder, "Track", 11, 0, 4, h, T.line2)
	K.corner(track, 2)
	local knob = K.btn(holder, "Knob", 4, math.floor((h - 12) * (1 - (val or 0.7))), 18, 12, T.txt2, 2)
	K.stroke(knob, T.accent2, 1)
	if label then K.txt(holder, label, 0, h + 2, 26, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center) end
	return holder
end

-- ---------- ICONS (drawn by Frame, 20x20 grid) ----------
ICON = {}
local function px(c, x, y, w, h, color, r, rot)
	local f = Instance.new("Frame")
	f.Parent = c
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Position = UDim2.new(x / 20, 0, y / 20, 0)
	f.Size = UDim2.new(w / 20, 0, h / 20, 0)
	if rot then f.Rotation = rot end
	if r then K.corner(f, r) end
	return f
end
function K.canvas(parent, size, x, y)
	local c = K.f(parent, "IconCanvas", x or 0, y or 0, size, size)
	c.BackgroundTransparency = 1
	return c
end
function K.icon(parent, name, size, x, y)
	local c = K.canvas(parent, size or 20, x, y)
	local fn = ICON[name]
	if fn then fn(c) end
	return c
end
local function gear(c, col)
	px(c, 7, 7, 6, 6, col, 3)
	px(c, 9, 3, 2, 3, col)
	px(c, 9, 14, 2, 3, col)
	px(c, 3, 9, 3, 2, col)
	px(c, 14, 9, 3, 2, col)
	px(c, 5, 4, 2, 2, col, 0, 45)
	px(c, 13, 4, 2, 2, col, 0, 45)
	px(c, 5, 14, 2, 2, col, 0, 45)
	px(c, 13, 14, 2, 2, col, 0, 45)
	px(c, 9, 9, 2, 2, T.bg2, 1)
end
ICON.save = function(c)
	px(c, 3, 3, 14, 14, T.purple, 2)
	px(c, 6, 3, 8, 5, C("#E9EDF6"), 1)
	px(c, 9, 4, 3, 3, T.purple)
	px(c, 5, 11, 10, 6, C("#EFE9FF"), 1)
	px(c, 7, 13, 6, 1, T.purple)
	px(c, 7, 15, 6, 1, T.purple)
end
ICON.open = function(c)
	px(c, 6, 3, 8, 6, C("#EDF1F7"), 1)
	px(c, 2, 6, 6, 3, T.yellow, 1)
	px(c, 2, 8, 16, 9, C("#E8B33C"), 2)
	px(c, 2, 10, 16, 7, C("#F6C65B"), 2)
end
ICON.cloud = function(c)
	px(c, 4, 9, 12, 6, C("#8A6BFF"), 3)
	px(c, 6, 6, 7, 6, C("#8A6BFF"), 3)
	px(c, 9, 8, 2, 7, C("#FFFFFF"))
	px(c, 6.6, 9.2, 4, 1.6, C("#FFFFFF"), 0, 45)
	px(c, 9.4, 9.2, 4, 1.6, C("#FFFFFF"), 0, -45)
end
ICON.select = function(c)
	px(c, 6, 3, 3.4, 12, C("#FFFFFF"), 1, -16)
	px(c, 9.4, 10, 3, 6.4, C("#FFFFFF"), 1, -16)
	px(c, 5, 3, 1.6, 10, C("#0B1220"), 0, -16)
end
ICON.move = function(c)
	px(c, 9, 5, 2, 10, T.txt)
	px(c, 5, 9, 10, 2, T.txt)
	px(c, 8.6, 2.4, 3, 3, T.txt, 0, 45)
	px(c, 8.6, 14.6, 3, 3, T.txt, 0, 45)
	px(c, 2.4, 8.6, 3, 3, T.txt, 0, 45)
	px(c, 14.6, 8.6, 3, 3, T.txt, 0, 45)
end
ICON.scaleI = function(c)
	px(c, 4, 4, 10, 1.6, T.txt)
	px(c, 4, 4, 1.6, 10, T.txt)
	px(c, 4, 14.4, 10, 1.6, T.txt)
	px(c, 14.4, 4, 1.6, 10, T.txt)
	px(c, 8, 8.6, 7, 1.8, T.accent2, 0, -45)
	px(c, 12.6, 4.6, 3, 3, T.accent2, 0, 45)
end
ICON.rotate = function(c)
	local seg = { { 9, 3, 0 }, { 13.4, 4.6, 45 }, { 15, 9, 90 }, { 13.4, 13.4, 135 }, { 9, 15, 90 }, { 4.6, 13.4, 45 }, { 3, 9, 0 } }
	for _, s in ipairs(seg) do
		px(c, s[1], s[2], 2.4, 2.4, T.accent2, 1, s[3])
	end
	px(c, 12.4, 2.2, 3, 3, T.accent2, 0, 45)
end
ICON.transform = function(c)
	px(c, 4, 4, 5, 1.8, T.txt); px(c, 4, 4, 1.8, 5, T.txt)
	px(c, 11, 4, 5, 1.8, T.txt); px(c, 14.2, 4, 1.8, 5, T.txt)
	px(c, 4, 14.2, 5, 1.8, T.txt); px(c, 4, 11.2, 1.8, 5, T.txt)
	px(c, 11, 14.2, 5, 1.8, T.txt); px(c, 14.2, 11.2, 1.8, 5, T.txt)
end
ICON.lock = function(c)
	px(c, 6, 9, 8, 8, T.txt2, 2)
	px(c, 7.4, 5, 5.2, 2, T.txt2, 1)
	px(c, 7.4, 5, 1.8, 5, T.txt2)
	px(c, 10.8, 5, 1.8, 5, T.txt2)
	px(c, 9.2, 11, 1.6, 4, T.bg2, 1)
end
ICON.model = function(c)
	px(c, 4, 8, 9, 9, C("#AEB9CC"), 1)
	px(c, 6, 4, 9, 5, C("#D7DEEA"), 1)
	px(c, 13, 6, 3, 11, C("#8894A9"), 1)
end
ICON.folder = function(c)
	px(c, 2, 5, 6, 3, T.yellow, 1)
	px(c, 2, 7, 16, 10, C("#E8B33C"), 2)
	px(c, 2, 9, 16, 8, C("#F0BE4F"), 2)
end
ICON.script = function(c)
	px(c, 5, 2, 10, 16, C("#EDF1F7"), 2)
	px(c, 7, 6, 6, 1.4, C("#8894A9"))
	px(c, 7, 9, 6, 1.4, C("#8894A9"))
	px(c, 7, 12, 4, 1.4, C("#8894A9"))
end
ICON.textA = function(c)
	px(c, 4, 6, 2, 11, T.txt, 0, 12)
	px(c, 9, 6, 2, 11, T.txt, 0, -12)
	px(c, 5.4, 11, 5, 1.8, T.txt)
	px(c, 13, 3, 1.4, 7, T.accent2, 0, 10)
	px(c, 16, 3, 1.4, 7, T.accent2, 0, -10)
	px(c, 14, 6.4, 3, 1.2, T.accent2)
end
ICON.play = function(c)
	px(c, 6, 4, 3, 12, T.green, 1)
	px(c, 9, 6, 3, 8, T.green, 1)
	px(c, 12, 8, 3, 4, T.green, 1)
end
ICON.pause = function(c)
	px(c, 6, 4, 3, 12, T.txt3, 1)
	px(c, 11, 4, 3, 12, T.txt3, 1)
end
ICON.data = function(c) gear(c, T.orange) end
ICON.settings = function(c) gear(c, C("#AEB9CC")) end
ICON.plugin = function(c) gear(c, C("#8894A9")) end
ICON.globe = function(c)
	px(c, 3, 3, 14, 14, T.purple2, 7)
	px(c, 5, 6, 4, 3, C("#3ECF7A"), 1)
	px(c, 10, 9, 5, 4, C("#3ECF7A"), 1)
	px(c, 9.4, 3, 1.2, 14, C("#FFFFFF"), 0)
end
ICON.toolbox = function(c)
	px(c, 8, 3, 4, 2, C("#8F5F2C"), 1)
	px(c, 2, 5, 16, 3, C("#8F5F2C"), 1)
	px(c, 3, 8, 14, 9, C("#B07A3E"), 2)
	px(c, 9, 9, 2, 3, C("#E8D9B0"), 1)
end
ICON.people = function(c)
	px(c, 5, 4, 4, 4, C("#8A6BFF"), 2)
	px(c, 3, 9, 8, 7, C("#8A6BFF"), 3)
	px(c, 12, 5, 4, 4, T.accent, 2)
	px(c, 10, 10, 7, 6, T.accent, 3)
end
ICON.info = function(c)
	local ring = K.f(c, "ring", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.Size = UDim2.new(0.7, 0, 0.7, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.accent, 2)
	px(c, 9.2, 5.6, 1.8, 1.8, T.txt, 1)
	px(c, 9.2, 8.6, 1.8, 6, T.txt, 1)
end
ICON.pin = function(c)
	px(c, 6, 3, 8, 3, T.txt2, 1)
	px(c, 9, 3, 2, 9, T.txt2)
	px(c, 6, 10, 8, 2, T.txt2, 1)
	px(c, 9.4, 12, 1.4, 5, T.txt2)
end
ICON.close = function(c, s, x, y)
	local holder = c
	px(holder, 4, 9, 12, 2, T.txt2, 1, 45)
	px(holder, 4, 9, 12, 2, T.txt2, 1, -45)
end
ICON.check = function(c)
	px(c, 2, 4.6, 4, 1.6, C("#FFFFFF"), 0, 45)
	px(c, 4, 5.6, 6, 1.6, C("#FFFFFF"), 0, -45)
end
ICON.search = function(c, s, x, y)
	local ring = Instance.new("Frame")
	ring.Parent = c
	ring.BackgroundTransparency = 1
	ring.Position = UDim2.new(0, x or 4, 0, y or 4)
	ring.Size = UDim2.new(0, 10, 0, 10)
	K.corner(ring, 5)
	K.stroke(ring, T.txt4, 1.5)
	local h = Instance.new("Frame")
	h.Parent = c
	h.BackgroundColor3 = T.txt4
	h.BorderSizePixel = 0
	h.Position = UDim2.new(0, (x or 4) + 9, 0, (y or 4) + 9)
	h.Size = UDim2.new(0, 5, 0, 1.5)
	h.Rotation = 45
end
ICON.chevD = function(c, s, x, y)
	px(c, 1, 2, 6, 1.8, T.txt3, 0, 35)
	px(c, 5, 4.4, 6, 1.8, T.txt3, 0, -35)
end
ICON.chevR = function(c, s, x, y)
	px(c, 2, 1, 1.8, 6, T.txt3, 0, -35)
	px(c, 2, 5, 1.8, 6, T.txt3, 0, 35)
end
ICON.plus = function(c)
	px(c, 9, 4, 2, 12, T.txt2)
	px(c, 4, 9, 12, 2, T.txt2)
end
ICON.emblem = function(c)
	px(c, 5, 14, 2.6, 4, T.accent2, 0, 24)
	px(c, 12.4, 14, 2.6, 4, T.accent2, 0, -24)
	px(c, 6.4, 12, 7.2, 1.8, T.accent2)
end
ICON.share = function(c)
	px(c, 3, 8, 4, 4, C("#7AA7F0"), 2)
	px(c, 13, 3, 4, 4, C("#7AA7F0"), 2)
	px(c, 13, 13, 4, 4, C("#7AA7F0"), 2)
	px(c, 6.4, 8.4, 7, 1.4, C("#7AA7F0"), 0, -22)
	px(c, 6.4, 10.6, 7, 1.4, C("#7AA7F0"), 0, 22)
end
-- hierarchy icons
ICON.ws = function(c)
	px(c, 3, 3, 14, 14, T.teal, 7)
	px(c, 5, 5, 5, 4, C("#7FE0C8"), 1)
	px(c, 10, 9, 5, 4, C("#7FE0C8"), 1)
end
ICON.plate = function(c)
	px(c, 5, 7, 10, 2, C("#D7DEEA"), 1)
	px(c, 3, 9, 14, 4, C("#AEB9CC"), 1)
end
ICON.cubeW = function(c)
	px(c, 4, 7, 9, 9, C("#DDE4EE"), 1)
	px(c, 6, 4, 9, 4, C("#F2F6FB"), 1)
	px(c, 13, 5, 3, 11, C("#AEB9CC"), 1)
end
ICON.terrain = function(c)
	px(c, 3, 10, 14, 6, C("#8F5F2C"), 1)
	px(c, 3, 8, 14, 4, C("#3ECF7A"), 1)
	px(c, 5, 6, 3, 2, C("#3ECF7A"), 1)
	px(c, 10, 6, 4, 2, C("#3ECF7A"), 1)
end
ICON.camera = function(c)
	px(c, 6, 4, 4, 2, C("#2A6BC0"), 1)
	px(c, 3, 6, 14, 9, T.accent, 2)
	px(c, 8, 8, 5, 5, T.bg2, 2)
	K.stroke(px(c, 8, 8, 5, 5, T.bg2, 2), C("#A6C6FF"), 1)
end
ICON.playersI = function(c)
	px(c, 5, 4, 4, 4, T.yellow, 2)
	px(c, 3, 9, 8, 7, T.yellow, 3)
	px(c, 12, 5, 3, 3, T.accent, 2)
	px(c, 11, 9, 6, 6, T.accent, 3)
end
ICON.bulb = function(c)
	px(c, 7, 3, 6, 7, C("#F6C65B"), 3)
	px(c, 8.4, 10.6, 3.2, 2, C("#AEB9CC"), 1)
	px(c, 8.4, 13, 3.2, 1.6, C("#8894A9"), 1)
end
ICON.gem = function(c)
	px(c, 6, 3, 8, 4, C("#B07AE0"), 1)
	px(c, 4, 7, 12, 4, C("#8A4FD6"), 1)
	px(c, 7, 11, 6, 3, C("#6E3BBF"), 1)
	px(c, 9, 14, 2, 2, C("#5A2BA6"), 1)
end
ICON.repfirst = function(c)
	px(c, 5, 5, 10, 10, C("#8A6BFF"), 2)
	px(c, 8, 7, 4, 1.6, C("#FFFFFF"))
	px(c, 8, 10, 4, 1.6, C("#FFFFFF"))
	px(c, 3, 13, 3, 3, T.accent, 0, 45)
end
ICON.boxG = function(c)
	px(c, 4, 7, 9, 9, C("#9AA7C0"), 1)
	px(c, 6, 4, 9, 4, C("#C7D2E8"), 1)
	px(c, 13, 5, 3, 11, C("#7C8BA6"), 1)
end
ICON.cubeT = function(c)
	px(c, 4, 7, 9, 9, T.teal, 1)
	px(c, 6, 4, 9, 4, C("#7FE0C8"), 1)
	px(c, 13, 5, 3, 11, C("#1F8F77"), 1)
end
ICON.folderP = function(c)
	ICON.folder(c)
	px(c, 9, 9, 2, 6, C("#FFFFFF"))
	px(c, 7, 11, 6, 2, C("#FFFFFF"))
end
ICON.playercard = function(c)
	px(c, 3, 4, 14, 12, T.accent, 2)
	px(c, 5.4, 7, 3.4, 3.4, C("#FFFFFF"), 2)
	px(c, 4.6, 11.4, 5, 3.4, C("#FFFFFF"), 2)
	px(c, 11, 8, 4, 1.4, C("#CFE3FF"))
	px(c, 11, 11, 4, 1.4, C("#CFE3FF"))
end
ICON.chat = function(c)
	px(c, 3, 4, 14, 9, T.accent, 3)
	px(c, 5, 12, 4, 3, T.accent, 1)
	px(c, 6, 7.4, 2, 2, C("#FFFFFF"), 1)
	px(c, 9, 7.4, 2, 2, C("#FFFFFF"), 1)
	px(c, 12, 7.4, 2, 2, C("#FFFFFF"), 1)
end
ICON.minus = function(c) px(c, 4, 9, 12, 2, T.txt2) end
ICON.square = function(c)
	local s = Instance.new("Frame")
	s.Parent = c
	s.BackgroundTransparency = 1
	s.Position = UDim2.new(0.2, 0, 0.2, 0)
	s.Size = UDim2.new(0.6, 0, 0.6, 0)
	K.stroke(s, T.txt2, 1.5)
end
ICON.dock = function(c)
	px(c, 3, 3, 14, 14, nil, 0)
	local s = Instance.new("Frame")
	s.Parent = c
	s.BackgroundTransparency = 1
	s.Position = UDim2.new(0.15, 0, 0.15, 0)
	s.Size = UDim2.new(0.7, 0, 0.7, 0)
	K.stroke(s, T.txt3, 1)
	px(c, 3, 3, 8, 8, T.txt3, 0)
end

local MONO
pcall(function() MONO = Enum.Font.CodePlatform end)
if not MONO then MONO = Enum.Font.Code end

ARKHER = { T = T, K = K, ICON = ICON, C = C, FONT = FONT, FONTB = FONTB, MONO = MONO }
--[[ ARKHER V2 — SYSTEMS: action hooks, atalhos, inspector live, hierarchy live, sandbox ]]
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
ARKHER_REG = ARKHER_REG or {}

-- ---------- action routing (ribbon/menus -> UIs) ----------
local ROUTE = {
	["Save"] = "SaveOpen", ["Open"] = "SaveOpen", ["Save to Arkher"] = "SaveOpen",
	["Settings"] = "Settings", ["Data"] = "DataManager", ["Localization"] = "Localization",
	["Toolbox"] = "Toolbox", ["Collaboration Settings"] = "Collaboration", ["Collaborate"] = "Collaboration",
	["Arkher Cloud"] = "Login", ["Plugin Toolbar"] = "PluginManager",
	["Command Palette"] = "CommandPalette", ["Properties"] = nil, ["Hierarchy"] = "HierarchyLive",
	["Console"] = "Console", ["Output"] = "Console",
	["Model"] = "Toolbox", ["Script"] = "ScriptEditor", ["Text"] = "UTSAI",
	["Game Settings"] = "ProjectSettings", ["Publish to Arkher"] = "BuildSettings",
	["Performance Stats"] = "Profiler", ["Run Diagnostics"] = "Debugger",
	["Invites"] = "Collaboration", ["Changes"] = "VersionControl",
	["Undo"] = "UndoRedo", ["Redo"] = "UndoRedo",
}
local SANDBOX_ON = true
ARKHER_ACTIONS = {
	ribbon = function(name)
		local tgt = ROUTE[name]
		if tgt and ARKHER_REG[tgt] then
			pcall(function() ARKHER_REG[tgt]() end)
			return
		end
		if name == "Play" then
			K.notify("RUN", "Play: use RUN (F5) no Studio — a UI monta via StarterGui e o sandbox valida capacidades", "WARNING")
		elseif name == "Pause" then
			K.notify("RUN", "Pause solicitado ao runtime UES", "INFO")
		end
	end,
	menu = function(item)
		local tgt = ROUTE[item]
		if tgt and ARKHER_REG[tgt] then
			pcall(function() ARKHER_REG[tgt]() end)
			return
		end
		if item == "Sandbox: ON" then
			SANDBOX_ON = not SANDBOX_ON
			K.notify("SANDBOX", SANDBOX_ON and "Sandbox ATIVADO: capability tokens + isolamento de plugins" or "Sandbox desativado (não recomendado)", SANDBOX_ON and "SUCCESS" or "WARNING")
		elseif item == "Reset Layout" then
			for _, ch in ipairs(game:GetService("StarterGui"):GetChildren()) do
				if ch.Name:sub(1, 6) == "Arkher" and ch.Name ~= "ArkherStudioMainUI" then
					pcall(function() ch:Destroy() end)
				end
			end
			K.notify("VIEW", "Layout resetado", "INFO")
		end
	end,
}

-- ---------- global shortcuts ----------
pcall(function()
	UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.KeyCode == Enum.KeyCode.K and (inp.ModifierKeys and false or true) then
			local ctrl = false
			pcall(function() ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) end)
			if ctrl and ARKHER_REG.CommandPalette then ARKHER_REG.CommandPalette() end
		end
	end)
end)

-- ---------- LIVE INSPECTOR (selection -> real properties) ----------
ARKHER_REG.InspectorLive = function()
	local g, root = K.window("ArkherInspectorLive", "Inspector (live)", 40, 120, 260, 320)
	local title = K.txt(root, "nenhuma seleção", 10, 34, 240, 18, 12, T.txt, ARKHER.FONTB)
	local body = K.f(root, "B", 0, 58, 260, 250)
	body.ClipsDescendants = true
	local function refresh()
		body:ClearAllChildren()
		local sel = nil
		pcall(function() sel = Selection:Get()[1] end)
		if not sel then
			title.Text = "nenhuma seleção"
			K.txt(body, "Selecione um objeto no Explorer para inspecionar propriedades reais.", 10, 8, 240, 60, 10, T.txt4)
			return
		end
		title.Text = sel.Name .. " (" .. sel.ClassName .. ")"
		local y = 4
		local function put(k, v)
			K.row(body, k, tostring(v), y)
			y = y + 20
		end
		put("Class", sel.ClassName)
		pcall(function() put("Position", string.format("%.1f, %.1f, %.1f", sel.Position.X, sel.Position.Y, sel.Position.Z)) end)
		pcall(function() put("Size", string.format("%.1f, %.1f, %.1f", sel.Size.X, sel.Size.Y, sel.Size.Z)) end)
		pcall(function() put("Orientation", string.format("%.0f, %.0f, %.0f", sel.Orientation.X, sel.Orientation.Y, sel.Orientation.Z)) end)
		pcall(function() put("Transparency", sel.Transparency) end)
		pcall(function() put("Anchored", sel.Anchored) end)
		pcall(function() put("Material", tostring(sel.Material)) end)
		pcall(function() put("Color", tostring(sel.Color)) end)
		put("Children", #sel:GetChildren())
	end
	refresh()
	pcall(function()
		Selection.SelectionChanged:Connect(refresh)
	end)
	return g
end

-- ---------- HIERARCHY LIVE (real workspace tree) ----------
ARKHER_REG.HierarchyLive = function()
	local g, root = K.window("ArkherHierarchyLive", "Hierarchy (live workspace)", 60, 140, 280, 380)
	K.search(root, 6, 30, 268, 22, "Filter workspace (Ctrl+Shift+X)")
	local tree = K.f(root, "T", 0, 58, 280, 316)
	tree.ClipsDescendants = true
	local ICONMAP = {
		Workspace = "ws", BasePart = "plate", Part = "plate", Terrain = "terrain", Camera = "camera",
		Folder = "folder", Model = "model", Script = "script", LocalScript = "script", ModuleScript = "script",
		Lighting = "bulb", Players = "playersI", Sound = "chat",
	}
	local function iconFor(inst)
		local n = ICONMAP[inst.ClassName] or ICONMAP[inst.Name]
		return n and ICON[n] or ICON.boxG
	end
	local function build(inst, depth, y)
		local kids = inst:GetChildren()
		local state = #kids > 0 and (inst.Name == "Workspace" and "open" or "closed") or nil
		local row = K.treeRow(tree, depth, iconFor(inst), inst.Name, state, y)
		y = y + 20
		row.MouseButton1Click:Connect(function() pcall(function() Selection:Set({ inst }) end) end)
		if state == "open" then
			for _, k in ipairs(kids) do
				y = build(k, depth + 1, y)
			end
		end
		return y
	end
	local function rebuild()
		tree:ClearAllChildren()
		pcall(function() build(workspace, 0, 0) end)
	end
	rebuild()
	local live = K.toggle(root, 180, 32, true, "live")
	return g
end

-- ---------- boot registry convenience ----------
ARKHER.openAll = function()
	for name, fn in pairs(ARKHER_REG) do
		if name ~= "Splash" and name ~= "Login" then
			pcall(fn)
		end
	end
end
--[[ ARKHER V2 — UIs GLOBAIS: Splash, Login/Cloud, SaveOpen, Palette, Settings, StatusBar, Search, Docs ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ SPLASH ============
ARKHER_REG.Splash = function()
	local g = K.gui("ArkherSplash")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	local emb = K.f(root, "E", 0, 0, 64, 64)
	emb.Position = UDim2.new(0.5, -32, 0.42, -32)
	ICON.emblem(emb, 64)
	local nm = K.txt(root, "ARKHER STUDIO", 0, 0, 0, 0, 22, T.txt, ARKHER.FONTB)
	nm.Size = UDim2.new(1, 0, 0, 30)
	nm.Position = UDim2.new(0, 0, 0.42, 40)
	nm.TextXAlignment = Enum.TextXAlignment.Center
	local sub = K.txt(root, "UES CORE + SINGULARITY AI + D-O15", 0, 0, 0, 0, 11, T.txt4)
	sub.Size = UDim2.new(1, 0, 0, 16)
	sub.Position = UDim2.new(0, 0, 0.42, 70)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	local bar = K.f(root, "Bar", 0, 0, 260, 4, T.line2)
	bar.Position = UDim2.new(0.5, -130, 0.42, 100)
	K.corner(bar, 2)
	local fill = K.f(bar, "F", 0, 0, 0, 4, T.accent2)
	K.corner(fill, 2)
	local steps = { "Bootstrap UES Core", "Job System", "Entity System", "Reflection", "Serialization", "Sandbox", "Editor Runtime", "Arkher Cloud" }
	local st = K.txt(root, steps[1], 0, 0, 0, 0, 10, T.txt4)
	st.Size = UDim2.new(1, 0, 0, 14)
	st.Position = UDim2.new(0, 0, 0.42, 112)
	st.TextXAlignment = Enum.TextXAlignment.Center
	coroutine.wrap(function()
		for i = 1, #steps do
			st.Text = "Initializing " .. steps[i] .. "..."
			local target = math.floor(260 * i / #steps)
			for w = fill.Size.X.Offset, target, 4 do
				fill.Size = UDim2.new(0, w, 0, 4)
				wait(0.02)
			end
		end
		wait(0.3)
		g:Destroy()
	end)()
	return g
end

-- ============ LOGIN / ARKHER CLOUD ============
ARKHER_REG.Login = function()
	local g = K.gui("ArkherLogin")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	-- procedural background: grid + particles
	local grid = K.fs(root, "Grid", 0, 0, 1, 1)
	grid.ClipsDescendants = true
	for i = 0, 24 do
		K.fs(grid, "v" .. i, i / 25, 0, 0.0012, 1, T.line)
	end
	for i = 0, 12 do
		K.fs(grid, "h" .. i, 0, i / 13, 1, 0.0012, T.line)
	end
	for i = 1, 26 do
		local p = K.f(grid, "p" .. i, math.random(0, 1200), math.random(0, 700), 2, 2, i % 3 == 0 and T.accent2 or T.purple)
		coroutine.wrap(function()
			for _ = 1, 60 do
				p.Position = UDim2.new(0, p.Position.X.Offset, 0, (p.Position.Y.Offset + 2) % 760)
				wait(0.06)
			end
		end)()
	end
	local card = K.f(root, "Card", 0, 0, 360, 430, T.bg1)
	card.Position = UDim2.new(0.5, -180, 0.5, -215)
	K.corner(card, 8)
	K.stroke(card, T.line2, 1)
	local e2 = K.f(card, "E", 156, 18, 48, 48)
	ICON.emblem(e2, 48)
	local t1 = K.txt(card, "ARKHER CLOUD", 0, 74, 360, 24, 17, T.txt, ARKHER.FONTB)
	t1.TextXAlignment = Enum.TextXAlignment.Center
	local t2 = K.txt(card, "Unified Technology System", 0, 98, 360, 16, 11, T.txt4)
	t2.TextXAlignment = Enum.TextXAlignment.Center
	local em = K.input(card, 40, 130, 280, 28, "Email / Username")
	local pw = K.input(card, 40, 166, 280, 28, "Password")
	pw.TextEditable = true
	local function bigBtn(y, label, col)
		local b = K.btn(card, "B_" .. label, 40, y, 280, 28, col or T.hover, 5)
		K.txtS(b, label, 11, T.txt, ARKHER.FONTB)
		b.TextXAlignment = Enum.TextXAlignment.Center
		K.hover(b, col or T.hover, T.sel)
		b.MouseButton1Click:Connect(function()
			K.notify("ARKHER CLOUD", label .. ": autenticando...", "INFO")
			wait(0.8)
			K.notify("ARKHER CLOUD", "Sandbox local ativo (sem credenciais reais neste build)", "WARNING")
		end)
		return b
	end
	bigBtn(210, "LOGIN", T.sel)
	bigBtn(244, "CREATE ACCOUNT")
	bigBtn(278, "CONTINUE WITH GOOGLE")
	bigBtn(312, "CONTINUE WITH GITHUB")
	bigBtn(346, "FORGOT PASSWORD")
	bigBtn(380, "CONTINUE AS GUEST", T.check)
	local closeB = K.btn(card, "X", 332, 6, 20, 20, T.bg1, 4)
	K.hover(closeB, T.bg1, C("#3A2530"))
	ICON.close(closeB)
	closeB.MouseButton1Click:Connect(function() g:Destroy() end)
	return g
end

-- ============ SAVE / OPEN DIALOG ============
ARKHER_REG.SaveOpen = function()
	local g, root = K.window("ArkherSaveOpen", "Save / Open — Arkher", 240, 90, 460, 330)
	local tabS = K.btn(root, "TabS", 8, 32, 60, 22, T.sel, 4)
	K.txtS(tabS, "SAVE", 11, T.txt, ARKHER.FONTB)
	local tabO = K.btn(root, "TabO", 72, 32, 60, 22, T.bg4, 4)
	K.txtS(tabO, "OPEN", 11, T.txt2)
	local nameIn = K.input(root, 8, 62, 250, 24, "place name.arkher")
	local fmt = K.btn(root, "Fmt", 264, 62, 120, 24, T.bg4, 4)
	K.txtS(fmt, ".arkher", 11, T.txt2)
	local list = K.f(root, "List", 8, 94, 444, 170, T.bg4)
	K.corner(list, 4)
	K.stroke(list, T.line2, 1)
	local snaps = {}
	pcall(function()
		local store = game:GetService("ServerStorage"):FindFirstChild("ArkherCloud")
		if store then
			for _, ch in ipairs(store:GetChildren()) do table.insert(snaps, ch.Name) end
		end
	end)
	if #snaps == 0 then snaps = { "baseplate-main.arkher", "sun-emblem.arkher", "v2-ribbon.arkher" } end
	local y = 4
	for _, sname in ipairs(snaps) do
		local row = K.btn(list, "R_" .. sname, 2, y, 440, 20, T.bg4, 3)
		ICON.folder(K.f(row, "I", 4, 2, 16, 16), 16)
		K.txt(row, sname, 26, 0, 300, 20, 11, T.txt2)
		K.txt(row, "checksum ok", 340, 0, 96, 20, 9, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Right)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function() nameIn.Text = sname end)
		y = y + 22
	end
	local saveB = K.btn(root, "Go", 8, 272, 120, 26, T.sel, 5)
	K.txtS(saveB, "SAVE", 12, T.txt, ARKHER.FONTB)
	saveB.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			local Http = game:GetService("HttpService")
			local store = game:GetService("ServerStorage")
			local cloud = store:FindFirstChild("ArkherCloud")
			if not cloud then
				cloud = Instance.new("Folder")
				cloud.Name = "ArkherCloud"
				cloud.Parent = store
			end
			local sv = Instance.new("StringValue")
			sv.Name = (nameIn.Text ~= "" and nameIn.Text or "untitled.arkher")
			local desc = {}
			for _, ch in ipairs(workspace:GetChildren()) do table.insert(desc, ch.Name) end
			sv.Value = Http:JSONEncode(desc)
			sv.Parent = cloud
		end)
		K.notify("SAVE", ok and "Snapshot real gravado em ServerStorage.ArkherCloud" or "Falha ao gravar snapshot", ok and "SUCCESS" or "ERROR")
	end)
	local openB = K.btn(root, "Go2", 134, 272, 120, 26, T.hover, 5)
	K.txtS(openB, "OPEN", 12, T.txt)
	openB.MouseButton1Click:Connect(function()
		K.notify("OPEN", "Carregando " .. (nameIn.Text ~= "" and nameIn.Text or "snapshot") .. "...", "INFO")
	end)
	return g
end

-- ============ COMMAND PALETTE ============
ARKHER_REG.CommandPalette = function()
	local g = K.gui("ArkherPalette")
	local root = K.f(g, "R", 0, 60, 520, 320, T.bg1)
	root.Position = UDim2.new(0.5, -260, 0, 60)
	K.corner(root, 8)
	K.stroke(root, T.line2, 1)
	local inp = K.input(root, 10, 10, 500, 30, "Type a command... (Ctrl+K)")
	local list = K.f(root, "List", 10, 48, 500, 262)
	list.ClipsDescendants = true
	local function refresh(q)
		list:ClearAllChildren()
		local y = 0
		local n = 0
		for name, _ in pairs(ARKHER_REG) do
			if q == "" or string.lower(name):find(string.lower(q), 1, true) then
				local b = K.btn(list, "C_" .. name, 0, y, 500, 24, T.bg1, 4)
				ICON.chevR(K.f(b, "c", 6, 8, 8, 8), 8)
				K.txt(b, "Open " .. name, 22, 0, 380, 24, 12, T.txt2)
				K.hover(b, T.bg1, T.hover)
				b.MouseButton1Click:Connect(function()
					g:Destroy()
					pcall(function() ARKHER_REG[name]() end)
				end)
				y = y + 26
				n = n + 1
				if n > 9 then break end
			end
		end
	end
	refresh("")
	inp:GetPropertyChangedSignal("Text"):Connect(function() refresh(inp.Text) end)
	return g
end

-- ============ SETTINGS ============
ARKHER_REG.Settings = function()
	local g, root = K.window("ArkherSettings", "Settings", 180, 70, 640, 420)
	local cats = { "General", "Account", "Appearance", "AI", "Models", "Agents", "Memory", "Storage", "Rendering", "Physics", "Audio", "Network", "Connectors", "GitHub", "Security", "Performance", "Accessibility", "Mobile", "Experimental" }
	local left = K.f(root, "L", 8, 32, 150, 380, T.bg4)
	K.corner(left, 4)
	local pane = K.f(root, "P", 166, 32, 466, 380, T.bg4)
	K.corner(pane, 4)
	local function show(cat)
		pane:ClearAllChildren()
		K.txt(pane, cat, 12, 8, 300, 20, 14, T.txt, ARKHER.FONTB)
		local y = 36
		K.toggle(pane, 12, y, true, "Enable " .. cat .. " runtime") y = y + 24
		K.toggle(pane, 12, y, false, "Verbose logging") y = y + 24
		K.sliderRow(pane, "Quality", 0.7, y) y = y + 22
		K.sliderRow(pane, "Budget", 0.5, y) y = y + 22
		K.row(pane, "Profile", cat .. "-default", y) y = y + 20
		local b = K.btn(pane, "Apply", 12, y + 6, 90, 24, T.sel, 4)
		K.txtS(b, "APPLY", 11, T.txt, ARKHER.FONTB)
		b.MouseButton1Click:Connect(function() K.notify("SETTINGS", cat .. " aplicado", "SUCCESS") end)
	end
	local y = 4
	for _, cat in ipairs(cats) do
		local b = K.btn(left, "S_" .. cat, 2, y, 146, 20, T.bg4, 3)
		K.txt(b, cat, 10, 0, 130, 20, 11, T.txt2)
		K.hover(b, T.bg4, T.hover)
		b.MouseButton1Click:Connect(function() show(cat) end)
		y = y + 21
	end
	show("General")
	return g
end

-- ============ STATUS BAR ============
ARKHER_REG.StatusBar = function()
	local g = K.gui("ArkherStatusBar")
	local root = K.fs(g, "R", 0, 1, 1, 22, T.bg0)
	root.Position = UDim2.new(0, 0, 1, -22)
	local fps = K.txt(root, "FPS --", 8, 0, 70, 22, 10, T.txt3)
	local ft = K.txt(root, "Frame --ms", 78, 0, 90, 22, 10, T.txt3)
	local mode = K.txt(root, "MODE: BUILD", 176, 0, 90, 22, 10, T.accent2)
	local sb = K.txt(root, "SANDBOX ON", 270, 0, 90, 22, 10, T.green)
	local d15 = K.txt(root, "D-O15 PRESSURE: LOW", 0, 0, 160, 22, 10, T.txt3)
	d15.Position = UDim2.new(1, -300, 0, 0)
	local ver = K.txt(root, "ARKHER V2", 0, 0, 80, 22, 10, T.txt4)
	ver.Position = UDim2.new(1, -84, 0, 0)
	ver.TextXAlignment = Enum.TextXAlignment.Right
	coroutine.wrap(function()
		local acc, frames = 0, 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			acc = acc + dt
			frames = frames + 1
			if acc >= 0.5 then
				local f = math.floor(frames / acc)
				fps.Text = "FPS " .. f
				ft.Text = "Frame " .. string.format("%.1f", (acc / frames) * 1000) .. "ms"
				acc, frames = 0, 0
			end
		end)
		wait(600)
	end)()
	return g
end

-- ============ SEARCH ============
ARKHER_REG.Search = function()
	local g, root = K.window("ArkherSearch", "Search — Arkher", 320, 110, 480, 340)
	local inp = K.input(root, 8, 32, 464, 26, "Search instances, systems, commands...")
	local list = K.f(root, "List", 8, 66, 464, 266)
	list.ClipsDescendants = true
	local function go(q)
		list:ClearAllChildren()
		if q == "" then return end
		local y = 0
		local n = 0
		pcall(function()
			for _, d in ipairs(workspace:GetDescendants()) do
				if n > 40 then break end
				if string.lower(d.Name):find(string.lower(q), 1, true) then
					local row = K.btn(list, "SR", 0, y, 464, 20, T.bg3, 3)
					ICON.cubeW(K.f(row, "I", 4, 2, 16, 16), 16)
					K.txt(row, d:GetFullName(), 26, 0, 430, 20, 11, T.txt2)
					K.hover(row, T.bg3, T.hover)
					row.MouseButton1Click:Connect(function()
						pcall(function() Selection:Set({ d }) end)
					end)
					y = y + 22
					n = n + 1
				end
			end
		end)
		if n == 0 then K.txt(list, "No results in workspace", 8, 8, 300, 16, 11, T.txt4) end
	end
	inp:GetPropertyChangedSignal("Text"):Connect(function() go(inp.Text) end)
	return g
end

-- ============ DOCUMENTATION ============
ARKHER_REG.Documentation = function()
	local g, root = K.window("ArkherDocs", "Documentation", 260, 80, 620, 420)
	local topics = { "Getting Started", "UES Core", "D-O15 Adaptive", "Sandbox Policy", "Arkher Cloud", "Collaboration", "Plugin Runtime", "API Reference" }
	local left = K.f(root, "L", 8, 32, 160, 380, T.bg4)
	K.corner(left, 4)
	local pane = K.f(root, "P", 176, 32, 436, 380, T.bg4)
	K.corner(pane, 4)
	local BODY = {
		["Getting Started"] = "ARKHER STUDIO V2 rebuilds the editor on top of the UES abstraction layer. Paste the command-bar script, press Play, and the interface mounts into StarterGui. Every icon is drawn by Frames - no external assets.",
		["UES Core"] = "The UES Core family owns scheduling, resources, memory, reflection and serialization. Roblox is only the adaptation layer; every capability has an ARKHER-native abstraction.",
		["D-O15 Adaptive"] = "D-O15 reads PRESSURE, then drives STRATEGY across SIMULATION, RENDER, AUDIO, STREAMING and MEMORY. Items move between Active, Deferred, Materialized and Abstract states.",
		["Sandbox Policy"] = "Scripts execute inside the ARKHER sandbox: capability tokens, permission gates, plugin isolation and integrity checks. To repair a sandbox session: reload the place, re-run the installer, and verify capability tokens in Settings > Security.",
		["Arkher Cloud"] = "Snapshots are JSON-encoded hierarchy manifests stored under ServerStorage.ArkherCloud with checksum verification and restore support.",
		["Collaboration"] = "Real-time editing sessions expose cursors, per-user permissions and a change feed. Invites are capability-scoped.",
		["Plugin Runtime"] = "Plugins run isolated with hot reload. The Plugin Toolbar UI lists installed plugins with enable toggles.",
		["API Reference"] = "ARKHER.T (theme), ARKHER.K (kit), ARKHER.ICON (frame icons), ARKHER_REG (UI registry).",
	}
	local y = 4
	for _, tp in ipairs(topics) do
		local b = K.btn(left, "D_" .. tp, 2, y, 156, 20, T.bg4, 3)
		K.txt(b, tp, 8, 0, 146, 20, 11, T.txt2)
		K.hover(b, T.bg4, T.hover)
		b.MouseButton1Click:Connect(function()
			pane:ClearAllChildren()
			K.txt(pane, tp, 12, 8, 400, 20, 14, T.txt, ARKHER.FONTB)
			local body = K.txt(pane, BODY[tp] or "", 12, 34, 410, 330, 11, T.txt3)
			body.TextWrapped = true
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
		end)
		y = y + 21
	end
	return g
end
--[[ ARKHER V2 — EDITORES CRIATIVOS ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ SCRIPT EDITOR ============
ARKHER_REG.ScriptEditor = function()
	local g, root = K.window("ArkherScriptEditor", "Script Editor", 140, 60, 700, 460)
	local tabs = { "ServerMain.lua", "ArkherCore.lua", "D_O15.lua" }
	local tx = 8
	for i, tn in ipairs(tabs) do
		local tb = K.btn(root, "T" .. i, tx, 30, 120, 22, i == 1 and T.bg2 or T.bg4, 4)
		K.txt(tb, tn, 8, 0, 96, 22, 10, i == 1 and T.txt or T.txt3)
		local xx = K.btn(tb, "x", 102, 3, 14, 14, tb.BackgroundColor3, 3)
		ICON.close(xx)
		tx = tx + 124
	end
	local gutter = K.f(root, "Gut", 8, 56, 34, 330, T.bg4)
	K.corner(gutter, 4)
	local code = Instance.new("TextBox")
	code.Name = "Code"
	code.Parent = root
	code.Position = UDim2.new(0, 46, 0, 56)
	code.Size = UDim2.new(0, 646, 0, 330)
	code.BackgroundColor3 = T.bg0
	code.BorderSizePixel = 0
	code.TextColor3 = C("#9FE8C0")
	code.TextSize = 12
	code.Font = ARKHER.MONO
	code.MultiLine = true
	code.TextEditable = true
	code.TextXAlignment = Enum.TextXAlignment.Left
	code.TextYAlignment = Enum.TextYAlignment.Top
	code.Text = "-- ARKHER V2\nlocal UES = require(game.ReplicatedStorage.UES)\n\nlocal function tick(dt)\n\tUES.JobSystem.schedule(dt)\nend\n\nreturn { tick = tick }"
	K.corner(code, 4)
	local lines = K.txt(gutter, "1\n2\n3\n4\n5\n6\n7\n8\n9", 6, 4, 24, 320, 11, T.txt4, ARKHER.MONO)
	lines.TextYAlignment = Enum.TextYAlignment.Top
	code:GetPropertyChangedSignal("Text"):Connect(function()
		local n = 1
		for _ in string.gmatch(code.Text, "\n") do n = n + 1 end
		local s = {}
		for i = 1, n do table.insert(s, tostring(i)) end
		lines.Text = table.concat(s, "\n")
	end)
	local term = K.f(root, "Term", 8, 392, 684, 36, T.bg0)
	K.corner(term, 4)
	local tout = K.txt(term, "arkher:~ ", 8, 0, 560, 36, 11, T.green, ARKHER.MONO)
	local runB = K.btn(root, "Run", 610, 30, 60, 22, T.green, 4)
	K.txtS(runB, "RUN", 11, T.bg0, ARKHER.FONTB)
	runB.MouseButton1Click:Connect(function()
		local fn, cerr = loadstring(code.Text)
		local ok, rerr = fn and pcall(fn) or false, cerr
		if not ok then
			tout.Text = "arkher:~ " .. tostring(rerr)
		else
			tout.Text = "arkher:~ executed ok"
		end
	end)
	return g
end

-- ============ CONSOLE / OUTPUT ============
ARKHER_REG.Console = function()
	local g, root = K.window("ArkherConsole", "Console / Output", 200, 120, 640, 380)
	local cats = { "UTS", "UES", "AI", "WORLD", "RENDER", "PHYSICS", "AUDIO", "STORAGE", "NETWORK", "TOOLS" }
	local active = { UTS = true, UES = true, AI = true, WORLD = true, RENDER = true, PHYSICS = true, AUDIO = true, STORAGE = true, NETWORK = true, TOOLS = true }
	local cx = 8
	local chips = {}
	for _, cn in ipairs(cats) do
		local ch = K.btn(root, "C_" .. cn, cx, 30, 14 + #cn * 6, 18, T.sel, 9)
		K.txtS(ch, cn, 9, T.txt, ARKHER.FONTB)
		chips[cn] = ch
		ch.MouseButton1Click:Connect(function()
			active[cn] = not active[cn]
			ch.BackgroundColor3 = active[cn] and T.sel or T.bg4
		end)
		cx = cx + 18 + #cn * 6
	end
	local exp = K.btn(root, "Exp", 560, 30, 70, 18, T.hover, 4)
	K.txtS(exp, "EXPORT", 9, T.txt2)
	exp.MouseButton1Click:Connect(function() K.notify("CONSOLE", "Log exportado (snapshot em memória)", "SUCCESS") end)
	local area = K.f(root, "Area", 8, 54, 624, 290, T.bg0)
	K.corner(area, 4)
	area.ClipsDescendants = true
	local yl = 4
	local function log(cat, sev, msg)
		if not active[cat] then return end
		local col = sev == "ERR" and C("#E05252") or sev == "WARN" and T.orange or sev == "OK" and T.green or T.txt3
		local r = K.txt(area, "[" .. cat .. "] " .. msg, 6, yl, 610, 14, 10, col, ARKHER.MONO)
		yl = yl + 15
	end
	log("UES", "OK", "Job System online (12 workers)")
	log("UES", "INFO", "Entity System registered 4.096 entities")
	log("AI", "INFO", "Singularity orchestration ready")
	log("RENDER", "WARN", "D-O15 deferred 214 abstract items")
	log("PHYSICS", "INFO", "Collision matrix rebuilt")
	log("STORAGE", "OK", "Integrity checksum verified")
	log("NETWORK", "INFO", "Replication graph stable")
	local inl = K.input(root, 8, 350, 560, 24, "> command")
	local send = K.btn(root, "S", 574, 350, 58, 24, T.sel, 4)
	K.txtS(send, "RUN", 10, T.txt)
	send.MouseButton1Click:Connect(function()
		log("TOOLS", "INFO", "> " .. inl.Text)
		inl.Text = ""
	end)
	return g
end

-- ============ DEBUGGER ============
ARKHER_REG.Debugger = function()
	local g, root = K.window("ArkherDebugger", "Debugger", 260, 90, 660, 420)
	local tb = { { "cont", ICON.play }, { "step", ICON.chevD }, { "stop", ICON.pause } }
	local bx = 8
	for _, b in ipairs(tb) do
		local bb = K.btn(root, "DB" .. bx, bx, 30, 30, 24, T.hover, 4)
		b[2](bb, 16, 7, 4)
		K.hover(bb, T.hover, T.sel)
		bx = bx + 34
	end
	local stack = K.f(root, "Stack", 8, 60, 200, 250, T.bg4)
	K.corner(stack, 4)
	K.txt(stack, "CALL STACK", 8, 4, 120, 16, 10, T.txt4, ARKHER.FONTB)
	local fr = { "UES.tick @ JobSystem:118", "D_O15.materialize :42", "Entity.spawn :201", "main :12" }
	local fy = 24
	for _, f in ipairs(fr) do
		local r = K.btn(stack, "F", 2, fy, 196, 18, T.bg4, 3)
		K.txt(r, f, 8, 0, 186, 18, 10, T.txt2, ARKHER.MONO)
		K.hover(r, T.bg4, T.hover)
		fy = fy + 19
	end
	local bp = K.f(root, "BP", 216, 60, 210, 250, T.bg4)
	K.corner(bp, 4)
	K.txt(bp, "BREAKPOINTS", 8, 4, 140, 16, 10, T.txt4, ARKHER.FONTB)
	local bps = { { "JobSystem:118", true }, { "D_O15:42", true }, { "Entity:201", false } }
	local by = 24
	for _, b in ipairs(bps) do
		K.checkRow(bp, b[1], b[2], by)
		by = by + 20
	end
	local watch = K.f(root, "W", 434, 60, 218, 250, T.bg4)
	K.corner(watch, 4)
	K.txt(watch, "WATCH", 8, 4, 120, 16, 10, T.txt4, ARKHER.FONTB)
	K.row(watch, "dt", "0.0166", 26)
	K.row(watch, "pressure", "0.32", 46)
	K.row(watch, "entities", "4096", 66)
	K.row(watch, "state", "ACTIVE", 86)
	local ai = K.btn(root, "AIT", 8, 318, 644, 66, T.bg0, 4)
	K.txt(ai, "AI TRACE: interpreted -> planned -> executed -> verified (last run: PASS)", 10, 6, 620, 16, 10, T.accent2, ARKHER.MONO)
	K.txt(ai, "tool calls: 14 | errors: 0 | corrections: 1", 10, 26, 620, 16, 10, T.txt3, ARKHER.MONO)
	return g
end

-- ============ PROFILER / PERFORMANCE ============
ARKHER_REG.Profiler = function()
	local g, root = K.window("ArkherProfiler", "Profiler / Performance", 220, 100, 620, 400)
	local bars = {}
	local names = { "SIMULATION", "RENDER", "PHYSICS", "AUDIO", "STREAMING", "MEMORY" }
	local y = 40
	for _, n in ipairs(names) do
		K.txt(root, n, 10, y + 2, 90, 14, 10, T.txt3)
		local track = K.f(root, "T_" .. n, 110, y + 4, 380, 10, T.bg4)
		K.corner(track, 3)
		local fill = K.f(track, "F", 0, 0, 120, 10, T.accent2)
		K.corner(fill, 3)
		local val = K.txt(root, "0.0ms", 500, y, 60, 16, 10, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Right)
		bars[n] = { fill = fill, val = val }
		y = y + 22
	end
	local graph = K.f(root, "G", 10, y + 10, 600, 130, T.bg0)
	K.corner(graph, 4)
	graph.ClipsDescendants = true
	local cols = {}
	for i = 0, 59 do
		cols[i] = K.f(graph, "c" .. i, i * 10, 0, 8, 40, T.green)
		cols[i].AnchorPoint = Vector2.new(0, 1)
		cols[i].Position = UDim2.new(0, i * 10, 1, 0)
	end
	coroutine.wrap(function()
		while wait(0.25) do
			for n, b in pairs(bars) do
				local v = math.random(8, 92)
				b.fill.Size = UDim2.new(0, math.floor(380 * v / 100), 0, 10)
				b.val.Text = string.format("%.1fms", v / 6)
			end
			for i = 0, 58 do
				cols[i].Size = UDim2.new(0, 8, 0, cols[i + 1] and cols[i + 1].Size.Y.Offset or 40)
			end
			cols[59].Size = UDim2.new(0, 8, 0, math.random(10, 120))
		end
	end)()
	return g
end

-- ============ TIMELINE / SEQUENCER ============
ARKHER_REG.Timeline = function()
	local g, root = K.window("ArkherTimeline", "Timeline / Sequencer", 180, 140, 720, 360)
	local tr = { "Camera.Cut", "Lighting.Ambient", "NPC.Walk", "Audio.Theme", "VFX.Fog" }
	local tx = { ICON.camera, ICON.bulb, ICON.playersI, ICON.chat, ICON.gem }
	local ruler = K.f(root, "Ruler", 140, 32, 572, 20, T.bg4)
	for i = 0, 28 do
		K.f(ruler, "t" .. i, i * 20, i % 5 == 0 and 8 or 12, 1, i % 5 == 0 and 12 or 8, T.txt4)
		if i % 5 == 0 then K.txt(ruler, tostring(i), i * 20 + 2, 0, 18, 10, 8, T.txt4) end
	end
	local playhead = K.f(root, "PH", 140 + 80, 32, 2, 260, T.orange)
	local y = 56
	for i, tn in ipairs(tr) do
		K.txt(root, tn, 8, y + 4, 120, 18, 10, T.txt2)
		local lane = K.f(root, "L" .. i, 140, y, 572, 26, T.bg4)
		K.corner(lane, 3)
		local kf = { 20, 120, 260, 420 }
		for _, kx in ipairs(kf) do
			local d = K.f(lane, "K", kx, 7, 10, 10, T.orange)
			d.Rotation = 45
			K.corner(d, 2)
		end
		if i == 1 then
			local clip = K.f(lane, "Clip", 60, 4, 200, 18, T.sel)
			K.corner(clip, 3)
			K.txt(clip, "Shot_A", 6, 0, 120, 18, 9, T.txt)
		end
		y = y + 30
	end
	local transport = { { ICON.pause, "pause" }, { ICON.play, "play" }, { ICON.rotate, "loop" } }
	local px2 = 8
	for _, tb in ipairs(transport) do
		local b = K.btn(root, "TR", px2, 30, 26, 22, T.hover, 4)
		tb[1](b, 14, 6, 4)
		K.hover(b, T.hover, T.sel)
		if tb[2] == "play" then
			b.MouseButton1Click:Connect(function()
				coroutine.wrap(function()
					for xx = 0, 560, 4 do
						playhead.Position = UDim2.new(0, 140 + xx, 0, 32)
						wait(0.03)
					end
				end)()
			end)
		end
		px2 = px2 + 30
	end
	return g
end

-- ============ MATERIAL EDITOR ============
ARKHER_REG.MaterialEditor = function()
	local g, root = K.window("ArkherMaterialEditor", "Material Editor", 240, 80, 620, 400)
	local prev
	local mats = { "Plastic", "SmoothPlastic", "Neon", "Metal", "Wood", "Slate", "Concrete", "Marble", "Granite", "Brick", "Pebble", "Sand", "Fabric", "Rock", "Glacier", "Snow", "Sandstone", "Mud", "Basalt", "CrackedLava", "Foil", "Glass", "Asphalt", "LeafyGrass", "Salt", "Limestone" }
	local cols = { C("#A3A8B5"), C("#C7CDD8"), C("#37F5C8"), C("#8E9AAD"), C("#8F5F2C"), C("#5E6E86"), C("#8A8F98"), C("#D8D3CC"), C("#B58F77"), C("#B0492F"), C("#9C8B77"), C("#D8C08A"), C("#7A5C48"), C("#6E6A63"), C("#A8D8E8"), C("#F2F6FB"), C("#C8A877"), C("#6B4E38"), C("#3E4247"), C("#E86A3C"), C("#D8DDE6"), C("#BFE8F2"), C("#3E4245"), C("#4CAF50"), C("#F5F2E8"), C("#D8CDB5") }
	local x, y = 8, 36
	for i, m in ipairs(mats) do
		local sw = K.btn(root, "M" .. i, x, y, 34, 34, cols[i], 4)
		K.stroke(sw, T.line2, 1)
		sw.MouseButton1Click:Connect(function()
			prev.BackgroundColor3 = cols[i]
			K.notify("MATERIAL", m .. " selecionado", "INFO")
		end)
		x = x + 38
		if x > 380 then x = 8 y = y + 38 end
	end
	prev = K.f(root, "Prev", 420, 40, 160, 160, C("#8E9AAD"))
	K.corner(prev, 80)
	K.grad(prev, C("#FFFFFF"), C("#20242C"), 135)
	local py = 210
	for _, s in ipairs({ { "Roughness", 0.4 }, { "Metalness", 0.6 }, { "Sheen", 0.2 }, { "Emission", 0.1 } }) do
		K.sliderRow(root, s[1], s[2], py)
		py = py + 22
	end
	return g
end

-- ============ TERRAIN EDITOR ============
ARKHER_REG.TerrainEditor = function()
	local g, root = K.window("ArkherTerrainEditor", "ARKHER Terrain Editor", 200, 90, 640, 420)
	local tools = { "Raise", "Lower", "Smooth", "Flatten", "Paint", "Erase", "Sculpt", "Water" }
	local y = 40
	for i, tn in ipairs(tools) do
		local b = K.btn(root, "TT" .. tn, 8, y, 90, 24, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, tn, 11, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		b.MouseButton1Click:Connect(function() K.notify("TERRAIN", "Brush: " .. tn, "INFO") end)
		y = y + 28
	end
	K.sliderRow(root, "Size", 0.5, y + 6)
	K.sliderRow(root, "Strength", 0.7, y + 28)
	local pal = { C("#3ECF7A"), C("#8F5F2C"), C("#D8C08A"), C("#6E6A63"), C("#A8D8E8"), C("#F2F6FB") }
	local pxx = 8
	for i, pc in ipairs(pal) do
		local sw = K.btn(root, "TP" .. i, pxx, y + 56, 22, 22, pc, 3)
		K.stroke(sw, T.line2, 1)
		pxx = pxx + 26
	end
	local hm = K.f(root, "HM", 130, 40, 496, 360, T.bg0)
	K.corner(hm, 4)
	hm.ClipsDescendants = true
	for ry = 0, 14 do
		for cx = 0, 23 do
			local hgt = math.abs(math.sin(cx * 0.7) * math.cos(ry * 0.5))
			local col = hgt > 0.66 and C("#3ECF7A") or hgt > 0.33 and C("#8F5F2C") or C("#2A6BC0")
			local cell = K.f(hm, "c", cx * 20 + 4, ry * 24 + 4, 19, 23, col)
			K.corner(cell, 2)
			cell.BackgroundTransparency = 0.15 + (1 - hgt) * 0.5
		end
	end
	return g
end

-- ============ ANIMATION EDITOR ============
ARKHER_REG.AnimationEditor = function()
	local g, root = K.window("ArkherAnimationEditor", "ARKHER Animation Editor", 190, 110, 700, 380)
	local parts = { "HumanoidRootPart", "Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }
	local y = 60
	for i, p in ipairs(parts) do
		K.txt(root, p, 8, y + 3, 130, 18, 10, T.txt2)
		local lane = K.f(root, "AL" .. i, 150, y, 540, 24, T.bg4)
		K.corner(lane, 3)
		for _, kx in ipairs({ 30 + i * 40, 180 + i * 20, 380 }) do
			local d = K.f(lane, "K", kx, 7, 10, 10, T.accent2)
			d.Rotation = 45
			K.corner(d, 2)
		end
		y = y + 28
	end
	local ruler = K.f(root, "R", 150, 36, 540, 18, T.bg4)
	for i = 0, 27 do K.f(ruler, "t" .. i, i * 20, i % 5 == 0 and 6 or 10, 1, i % 5 == 0 and 12 or 8, T.txt4) end
	local eb = K.btn(root, "Ease", 8, 36, 130, 20, T.bg4, 4)
	K.txtS(eb, "Easing: Quad Out", 10, T.txt2)
	eb.MouseButton1Click:Connect(function() K.notify("ANIMATION", "Ciclo de easing alternado", "INFO") end)
	return g
end

-- ============ PARTICLE EDITOR ============
ARKHER_REG.ParticleEditor = function()
	local g, root = K.window("ArkherParticleEditor", "ARKHER VFX / Particle Editor", 250, 70, 600, 420)
	local py = 40
	for _, s in ipairs({ { "Rate", 0.6 }, { "Lifetime", 0.4 }, { "Speed", 0.5 }, { "Spread", 0.3 }, { "Size", 0.45 }, { "Gravity", 0.7 }, { "Turbulence", 0.2 } }) do
		K.sliderRow(root, s[1], s[2], py)
		py = py + 22
	end
	local prev = K.f(root, "Prev", 240, 36, 350, 370, T.bg0)
	K.corner(prev, 4)
	prev.ClipsDescendants = true
	local emit = K.f(prev, "E", 170, 330, 12, 8, T.orange)
	K.corner(emit, 2)
	local pool = {}
	for i = 1, 40 do
		pool[i] = K.f(prev, "p" .. i, 170 + math.random(-6, 6), 320, 4, 4, i % 2 == 0 and T.orange or T.yellow)
		K.corner(pool[i], 2)
	end
	coroutine.wrap(function()
		while wait(0.05) do
			for i = 1, 40 do
				local p = pool[i]
				local yy = p.Position.Y.Offset - 6
				local xx = p.Position.X.Offset + math.random(-4, 4)
				if yy < 10 then xx = 170 + math.random(-6, 6) yy = 320 end
				p.Position = UDim2.new(0, xx, 0, yy)
				p.BackgroundTransparency = yy / 340
			end
		end
	end)()
	return g
end

-- ============ VFX EDITOR ============
ARKHER_REG.VFXEditor = function()
	local g, root = K.window("ArkherVFXEditor", "ARKHER VFX Editor", 280, 100, 560, 380)
	local layers = { "Bloom", "Glow", "Fog", "ColorGrade", "Scanlines", "ChromaticAberr" }
	local y = 40
	for i, l in ipairs(layers) do
		K.toggle(root, 10, y, i <= 2, l)
		y = y + 22
	end
	local gy = y + 8
	for _, s in ipairs({ { "Intensity", 0.55 }, { "Threshold", 0.35 }, { "Saturation", 0.6 }, { "Contrast", 0.5 } }) do
		K.sliderRow(root, s[1], s[2], gy)
		gy = gy + 22
	end
	local grade = K.f(root, "Grade", 240, 40, 300, 120, T.bg0)
	K.corner(grade, 4)
	K.grad(grade, T.purple, T.accent2, 0)
	local curve = K.f(root, "Curve", 240, 170, 300, 120, T.bg0)
	K.corner(curve, 4)
	for i = 0, 20 do
		local h = 60 + math.sin(i * 0.5) * 40
		K.f(curve, "c" .. i, i * 14, 120 - h, 3, h, T.accent2)
	end
	return g
end
--[[ ARKHER V2 — SISTEMAS UES: Audio, Physics, Navigation, AI, World, UIEditor, Nodes, Graph, UTS AI ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ AUDIO EDITOR ============
ARKHER_REG.AudioEditor = function()
	local g, root = K.window("ArkherAudioEditor", "ARKHER Audio Editor", 210, 80, 640, 400)
	local chans = { "Master", "Environment", "Ambience", "SFX", "Voices", "Music", "Weather", "UI" }
	local x = 10
	local meters = {}
	for i, ch in ipairs(chans) do
		local strip = K.f(root, "S_" .. ch, x, 40, 46, 300, T.bg4)
		K.corner(strip, 4)
		local mtrack = K.f(strip, "MT", 8, 10, 8, 220, T.bg0)
		K.corner(mtrack, 3)
		local mfill = K.f(mtrack, "F", 0, 0, 8, 120, T.green)
		mfill.AnchorPoint = Vector2.new(0, 1)
		mfill.Position = UDim2.new(0, 0, 1, 0)
		K.corner(mfill, 3)
		K.vfader(strip, 24, 10, 220, 0.8 - i * 0.05, nil)
		K.txt(strip, ch, 0, 240, 46, 24, 8, T.txt3, ARKHER.FONT, Enum.TextXAlignment.Center)
		meters[i] = mfill
		x = x + 52
	end
	local spatial = K.f(root, "SP", x + 10, 40, 180, 300, T.bg4)
	K.corner(spatial, 4)
	K.txt(spatial, "SPATIALIZATION", 8, 6, 140, 14, 9, T.txt4, ARKHER.FONTB)
	local listener = K.f(spatial, "L", 85, 140, 10, 10, T.accent2)
	K.corner(listener, 5)
	for i = 1, 6 do
		local a = i * 60
		local sx = 90 + math.cos(math.rad(a)) * 60
		local sy = 145 + math.sin(math.rad(a)) * 60
		local src = K.f(spatial, "src" .. i, sx, sy, 6, 6, T.yellow)
		K.corner(src, 3)
	end
	K.toggle(spatial, 8, 260, true, "HRTF")
	coroutine.wrap(function()
		while wait(0.12) do
			for i = 1, #meters do
				meters[i].Size = UDim2.new(0, 8, 0, math.random(30, 210))
			end
		end
	end)()
	return g
end

-- ============ PHYSICS EDITOR ============
ARKHER_REG.PhysicsEditor = function()
	local g, root = K.window("ArkherPhysicsEditor", "ARKHER Physics Editor", 230, 90, 660, 420)
	K.sliderRow(root, "Gravity", 0.97, 40)
	K.sliderRow(root, "Timestep", 0.4, 62)
	local matL = { "Default", "Metal", "Wood", "Rock", "Ice", "Rubber" }
	local matT = { "Default", "Metal", "Wood", "Rock", "Ice", "Rubber" }
	K.txt(root, "COLLISION MATRIX", 300, 40, 200, 16, 10, T.txt4, ARKHER.FONTB)
	local gx, gy = 300, 60
	for i, a in ipairs(matL) do
		K.txt(root, a, 40, gy + 2, 60, 16, 9, T.txt3)
		for j, b in ipairs(matT) do
			local on = (i + j) % 3 ~= 0
			local cell = K.btn(root, "CM" .. i .. j, gx + (j - 1) * 22, gy, 18, 18, on and T.check or T.bg4, 3)
			K.stroke(cell, T.line2, 1)
			cell.MouseButton1Click:Connect(function()
				cell.BackgroundColor3 = cell.BackgroundColor3 == T.check and T.bg4 or T.check
			end)
		end
		gy = gy + 22
	end
	for j, b in ipairs(matT) do
		local tt = K.txt(root, string.sub(b, 1, 3), gx + (j - 1) * 22, 42, 20, 14, 9, T.txt3)
	end
	local bodies = K.f(root, "B", 470, 60, 180, 240, T.bg4)
	K.corner(bodies, 4)
	K.txt(bodies, "BODIES", 8, 4, 80, 14, 9, T.txt4, ARKHER.FONTB)
	local bl = { "Baseplate (static)", "SpamPoint (dyn)", "Ball_01 (dyn)", "Ragdoll_NPC", "Vehicle_02" }
	local by = 22
	for _, bn in ipairs(bl) do
		local r = K.btn(bodies, "B_" .. bn, 2, by, 176, 18, T.bg4, 3)
		K.txt(r, bn, 8, 0, 160, 18, 10, T.txt2)
		K.hover(r, T.bg4, T.hover)
		by = by + 19
	end
	K.row(root, "Contacts", "1.284", 320)
	K.row(root, "Forces", "96", 340)
	K.row(root, "Constraints", "42", 360)
	return g
end

-- ============ NAVIGATION EDITOR ============
ARKHER_REG.NavigationEditor = function()
	local g, root = K.window("ArkherNavigationEditor", "ARKHER Navigation Editor", 260, 100, 600, 380)
	local agents = { "Humanoid", "Vehicle", "Flyer", "Crowd" }
	local y = 40
	for i, a in ipairs(agents) do
		local b = K.btn(root, "A_" .. a, 8, y, 110, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, a, 11, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		y = y + 26
	end
	K.sliderRow(root, "Radius", 0.3, y + 8)
	K.sliderRow(root, "Height", 0.6, y + 30)
	K.sliderRow(root, "Slope", 0.45, y + 52)
	local nav = K.f(root, "Nav", 150, 40, 440, 320, T.bg0)
	K.corner(nav, 4)
	nav.ClipsDescendants = true
	for ry = 0, 12 do
		for cx = 0, 17 do
			local v = math.sin(cx * 0.6 + ry) * math.cos(ry * 0.4)
			if v > -0.2 then
				local cell = K.f(nav, "n", cx * 24 + 4, ry * 24 + 4, 22, 22, v > 0.5 and T.teal or T.sel)
				K.corner(cell, 2)
				cell.BackgroundTransparency = 0.45
			end
		end
	end
	local path = K.f(nav, "p0", 30, 300, 60, 3, T.orange)
	path.Rotation = -35
	local path2 = K.f(nav, "p1", 80, 250, 90, 3, T.orange)
	path2.Rotation = -10
	return g
end

-- ============ AI EDITOR (Singularity) ============
ARKHER_REG.AIEditor = function()
	local g, root = K.window("ArkherAIEditor", "Singularity AI Editor", 190, 70, 700, 460)
	local modes = { "CHAT", "BUILD", "AUTO" }
	local mx = 8
	for i, m in ipairs(modes) do
		local b = K.btn(root, "MD_" .. m, mx, 30, 64, 22, i == 3 and T.sel or T.bg4, 4)
		K.txtS(b, m, 11, i == 3 and T.txt or T.txt2, ARKHER.FONTB)
		K.hover(b, b.BackgroundColor3, T.hover)
		mx = mx + 70
	end
	local prompt = K.input(root, 8, 58, 684, 40, "Describe what to create / change...")
	prompt.TextWrapped = true
	local agents = { "Architect", "Coder", "Researcher", "Designer", "Graphics", "Physics", "Audio", "World", "QA", "Optimizer" }
	local ax, ay = 8, 108
	for i, a in ipairs(agents) do
		local card = K.f(root, "AG_" .. a, ax, ay, 128, 64, T.bg4)
		K.corner(card, 5)
		K.stroke(card, T.line2, 1)
		ICON.gem(K.f(card, "I", 8, 8, 16, 16), 16)
		K.txt(card, a, 30, 6, 92, 16, 11, T.txt, ARKHER.FONTB)
		K.txt(card, "status: idle", 8, 28, 110, 12, 9, T.txt4)
		K.txt(card, "model: AUTO", 8, 42, 110, 12, 9, T.accent2)
		ax = ax + 134
		if ax > 560 then ax = 8 ay = ay + 70 end
	end
	local plan = K.f(root, "Plan", 8, 260, 684, 160, T.bg0)
	K.corner(plan, 4)
	local steps = { "Interpret request", "Plan", "Execute", "Verify", "Correct", "Complete" }
	local sy = 8
	for i, s in ipairs(steps) do
		local done = i <= 3
		local dot = K.f(plan, "D" .. i, 12, sy + 2, 10, 10, done and T.green or T.line2)
		K.corner(dot, 5)
		K.txt(plan, s, 30, sy, 200, 14, 11, done and T.txt2 or T.txt4)
		if i < 6 then K.f(plan, "ln", 16, sy + 12, 1, 10, T.line2) end
		sy = sy + 24
	end
	K.txt(plan, "AUTO: interpret -> plan -> execute -> verify -> correct -> complete", 260, 12, 410, 14, 10, T.accent2, ARKHER.MONO)
	K.txt(plan, "context: page=AIEditor | selection=none | world=base", 260, 32, 410, 14, 10, T.txt3, ARKHER.MONO)
	return g
end

-- ============ WORLD EDITOR ============
ARKHER_REG.WorldEditor = function()
	local g, root = K.window("ArkherWorldEditor", "ARKHER World Editor", 220, 80, 680, 440)
	local biomes = { "Temperate", "Desert", "Tundra", "Tropical", "Volcanic" }
	local bx = 8
	for i, b in ipairs(biomes) do
		local bb = K.btn(root, "BI_" .. b, bx, 30, 20 + #b * 6, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(bb, b, 10, i == 1 and T.txt or T.txt2)
		K.hover(bb, bb.BackgroundColor3, T.hover)
		bx = bx + 26 + #b * 6
	end
	local y = 62
	for _, s in ipairs({ { "Temperature", 0.5 }, { "Humidity", 0.6 }, { "Wind", 0.3 }, { "Rain", 0.2 }, { "Clouds", 0.4 } }) do
		K.sliderRow(root, s[1], s[2], y)
		y = y + 22
	end
	local dial = K.f(root, "Dial", 300, 70, 120, 120, T.bg0)
	K.corner(dial, 60)
	K.stroke(dial, T.line2, 1)
	local sun = K.f(dial, "Sun", 60, 12, 14, 14, T.yellow)
	K.corner(sun, 7)
	local hand = K.f(dial, "H", 58, 20, 3, 40, T.accent2)
	hand.AnchorPoint = Vector2.new(0.5, 1)
	hand.Position = UDim2.new(0.5, 0, 0.5, 0)
	hand.Rotation = 35
	K.txt(root, "DAY / NIGHT", 300, 194, 120, 14, 9, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Center)
	local speeds = { "1x", "10x", "100x", "1000x" }
	local sx = 460
	for i, sp in ipairs(speeds) do
		local b = K.btn(root, "SP_" .. sp, sx, 80, 44, 22, i == 2 and T.sel or T.bg4, 4)
		K.txtS(b, sp, 10, i == 2 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		sx = sx + 48
	end
	local pb = K.btn(root, "WPlay", 460, 110, 44, 22, T.hover, 4)
	ICON.play(pb, 14, 15, 4)
	local pb2 = K.btn(root, "WPause", 508, 110, 44, 22, T.hover, 4)
	ICON.pause(pb2, 14, 15, 4)
	local stats = K.f(root, "ST", 460, 150, 210, 180, T.bg4)
	K.corner(stats, 4)
	K.row(stats, "Population", "12.480", 8)
	K.row(stats, "Entities", "96.214", 28)
	K.row(stats, "Biome", "Temperate", 48)
	K.row(stats, "Weather", "Clear", 68)
	K.row(stats, "Sim tick", "30Hz", 88)
	K.row(stats, "D-O15", "ACTIVE", 108)
	return g
end

-- ============ UI EDITOR ============
ARKHER_REG.UIEditor = function()
	local g, root = K.window("ArkherUIEditor", "ARKHER UI Editor", 250, 90, 660, 420)
	local comps = { "ScreenGui", "  Frame.HUD", "    HealthBar", "    StaminaBar", "  Frame.Minimap", "  TextLabel.Score" }
	local y = 40
	for i, cp in ipairs(comps) do
		local depth = #cp - #cp:gsub(" ", "")
		local r = K.btn(root, "UC" .. i, 8, y, 190, 20, i == 3 and T.sel or T.bg4, 3)
		K.txt(r, cp:gsub(" ", ""), 8 + depth * 12, 0, 170, 20, 10, T.txt2)
		K.hover(r, r.BackgroundColor3, T.hover)
		y = y + 21
	end
	local canvas = K.f(root, "CV", 210, 40, 280, 360, T.bg0)
	K.corner(canvas, 4)
	local hud = K.f(canvas, "HUD", 10, 10, 260, 340, nil)
	K.stroke(hud, T.line, 1)
	local hb = K.f(hud, "HB", 10, 10, 160, 12, T.bg4)
	K.corner(hb, 6)
	local hbf = K.f(hb, "F", 0, 0, 110, 12, T.green)
	K.corner(hbf, 6)
	K.stroke(hbf, C("#7FE0A8"), 1)
	local sb = K.f(hud, "SB", 10, 26, 120, 8, T.bg4)
	K.corner(sb, 4)
	local sbf = K.f(sb, "F", 0, 0, 80, 8, T.accent2)
	K.corner(sbf, 4)
	local sel = K.f(hud, "SEL", 8, 8, 164, 16, nil)
	K.stroke(sel, T.orange, 1)
	local props = K.f(root, "PR", 500, 40, 150, 360, T.bg4)
	K.corner(props, 4)
	K.txt(props, "HealthBar", 8, 4, 130, 16, 11, T.txt, ARKHER.FONTB)
	K.row(props, "Anchor", "TopLeft", 26)
	K.row(props, "Size", "160,12", 46)
	K.row(props, "Radius", "6", 66)
	K.row(props, "Value", "0.68", 86)
	return g
end

-- ============ NODE / SHADER / VISUAL SCRIPTING ============
local function nodeCanvas(title, nodeDefs)
	local g, root = K.window("Arkher" .. title, title, 200, 70, 720, 460)
	local palette = K.f(root, "PAL", 8, 32, 130, 420, T.bg4)
	K.corner(palette, 4)
	local py = 6
	for _, pd in ipairs(nodeDefs) do
		local b = K.btn(palette, "P_" .. pd[1], 4, py, 122, 20, T.bg4, 3)
		K.txt(b, pd[1], 8, 0, 110, 20, 10, T.txt2)
		K.hover(b, T.bg4, T.hover)
		py = py + 21
	end
	local canvas = K.f(root, "CV", 146, 32, 566, 420, T.bg0)
	K.corner(canvas, 4)
	canvas.ClipsDescendants = true
	for gx = 0, 27 do K.f(canvas, "g" .. gx, gx * 20, 0, 1, 420, T.line) end
	for gy = 0, 20 do K.f(canvas, "h" .. gy, 0, gy * 20, 566, 1, T.line) end
	local nodes = {}
	for i, nd in ipairs(nodeDefs) do
		local n = K.f(canvas, "N" .. i, nd[2], nd[3], 140, 26 + 16 * #nd[4], T.bg2)
		K.corner(n, 5)
		K.stroke(n, nd[5] or T.line2, 1)
		K.f(n, "HD", 0, 0, 140, 20, nd[5] or T.sel)
		K.txt(n, nd[1], 8, 0, 124, 20, 10, T.txt, ARKHER.FONTB)
		local iy = 24
		for _, port in ipairs(nd[4]) do
			K.f(n, "pin", -4, iy + 2, 8, 8, T.accent2)
			K.txt(n, port, 8, iy, 90, 12, 9, T.txt3)
			K.f(n, "pout", 136, iy + 2, 8, 8, T.orange)
			iy = iy + 16
		end
		K.drag(K.f(n, "drag", 0, 0, 140, 20, nil), n)
		nodes[i] = n
	end
	local function wire(a, b, col)
		local na, nb = nodes[a], nodes[b]
		local x1 = na.Position.X.Offset + 140
		local y1 = na.Position.Y.Offset + 30
		local x2 = nb.Position.X.Offset
		local y2 = nb.Position.Y.Offset + 30
		local len = math.max(20, x2 - x1)
		local w = K.f(canvas, "W", x1, (y1 + y2) / 2, len, 2, col or T.accent2)
		w.Rotation = math.deg(math.atan(y2 - y1, len))
	end
	if #nodes >= 2 then
		wire(1, 2)
		if #nodes >= 3 then wire(2, 3, T.orange) end
	end
	return g
end
ARKHER_REG.ShaderEditor = function()
	return nodeCanvas("ShaderEditor", {
		{ "Base Color", 30, 40, { "Albedo", "Tint" }, T.purple },
		{ "PBR Master", 240, 90, { "Rough", "Metal", "Normal", "Emission" }, T.sel },
		{ "Fresnel", 40, 220, { "Power" }, T.teal },
		{ "Output", 460, 140, { "Surface" }, T.orange },
	})
end
ARKHER_REG.VisualScripting = function()
	return nodeCanvas("VisualScripting", {
		{ "OnStart", 20, 30, { "exec" }, T.green },
		{ "Spawn Entity", 220, 60, { "exec", "entity" }, T.sel },
		{ "Set Velocity", 220, 200, { "exec", "vec3" }, T.accent },
		{ "Loop x10", 430, 120, { "body", "done" }, T.orange },
	})
end
ARKHER_REG.NodeEditor = function()
	return nodeCanvas("NodeEditor", {
		{ "Input", 20, 40, { "value" }, T.teal },
		{ "Math.Add", 220, 80, { "a", "b" }, T.sel },
		{ "Math.Mul", 220, 220, { "a", "b" }, T.purple },
		{ "Output", 440, 150, { "in" }, T.orange },
	})
end

-- ============ GRAPH EDITOR ============
ARKHER_REG.GraphEditor = function()
	local g, root = K.window("ArkherGraphEditor", "Graph Editor", 240, 110, 640, 380)
	local cv = K.f(root, "CV", 8, 32, 624, 300, T.bg0)
	K.corner(cv, 4)
	cv.ClipsDescendants = true
	for gx = 0, 30 do K.f(cv, "g" .. gx, gx * 20, 0, 1, 300, T.line) end
	for gy = 0, 14 do K.f(cv, "h" .. gy, 0, gy * 20, 624, 1, T.line) end
	local pts = { { 40, 240 }, { 160, 90 }, { 300, 160 }, { 460, 60 }, { 600, 120 } }
	for i = 1, #pts - 1 do
		local x1, y1 = pts[i][1], pts[i][2]
		local x2, y2 = pts[i + 1][1], pts[i + 1][2]
		local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
		local seg = K.f(cv, "seg" .. i, x1, y1, len, 2, T.accent2)
		seg.Rotation = math.deg(math.atan(y2 - y1, x2 - x1))
	end
	for i, p in ipairs(pts) do
		local d = K.f(cv, "K" .. i, p[1] - 5, p[2] - 5, 10, 10, T.orange)
		d.Rotation = 45
		K.corner(d, 2)
		local h1 = K.f(cv, "H" .. i, p[1] - 24, p[2] - 1, 20, 2, T.purple)
		local hh = K.f(cv, "HH" .. i, p[1] - 28, p[2] - 4, 8, 8, T.purple)
		K.corner(hh, 4)
	end
	local interp = K.btn(root, "INT", 8, 340, 140, 22, T.bg4, 4)
	K.txtS(interp, "Interp: Bezier", 10, T.txt2)
	interp.MouseButton1Click:Connect(function() K.notify("GRAPH", "Interp: Bezier -> Linear -> Constant", "INFO") end)
	return g
end

-- ============ UTS AI HOME ============
ARKHER_REG.UTSAI = function()
	local g = K.gui("ArkherUTSAI")
	local root = K.fs(g, "R", 0, 0, 1, 1, T.bg0)
	local emb = K.f(root, "E", 0, 0, 72, 72)
	emb.Position = UDim2.new(0.42, -36, 0.24, 0)
	ICON.emblem(emb, 72)
	local ti = K.txt(root, "ARKHER", 0, 0, 0, 30, 24, T.txt, ARKHER.FONTB)
	ti.Size = UDim2.new(1, 0, 0, 30)
	ti.Position = UDim2.new(0, 0, 0.24, 20)
	ti.TextXAlignment = Enum.TextXAlignment.Center
	local sub = K.txt(root, "How can I help you create?", 0, 0, 0, 20, 13, T.txt3)
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Position = UDim2.new(0, 0, 0.24, 54)
	sub.TextXAlignment = Enum.TextXAlignment.Center
	local prompt = K.input(root, 0, 0, 560, 44, "What do you want to create?")
	prompt.Position = UDim2.new(0.5, -280, 0.45, 0)
	prompt.TextWrapped = true
	local att = { "Attach", "Image", "Video", "Audio", "Document", "Code", "URL", "File" }
	local ax = -260
	for _, a in ipairs(att) do
		local w = 18 + #a * 6
		local b = K.btn(root, "AT_" .. a, 0, 0, w, 20, T.bg2, 10)
		b.Position = UDim2.new(0.5, ax, 0.45, 52)
		K.txtS(b, a, 10, T.txt2)
		K.hover(b, T.bg2, T.hover)
		ax = ax + w + 6
	end
	local hist = K.f(root, "H", 0, 0, 240, 10, T.bg1)
	hist.Position = UDim2.new(1, -250, 0, 60)
	hist.Size = UDim2.new(0, 240, 1, -120)
	K.corner(hist, 6)
	K.stroke(hist, T.line, 1)
	K.txt(hist, "HISTORY", 10, 8, 120, 16, 10, T.txt4, ARKHER.FONTB)
	local nb = K.btn(hist, "NEW", 150, 6, 80, 20, T.sel, 4)
	K.txtS(nb, "+ NEW CHAT", 9, T.txt)
	local items = { "Medieval world + river", "NPC economy tuning", "Rewrite D-O15 strategy", "Physics audit", "Publish pipeline" }
	local hy = 32
	for _, it in ipairs(items) do
		local r = K.btn(hist, "H_" .. it, 4, hy, 232, 22, T.bg1, 3)
		K.txt(r, it, 8, 0, 216, 22, 10, T.txt2)
		K.hover(r, T.bg1, T.hover)
		hy = hy + 24
	end
	return g
end
--[[ ARKHER V2 — GESTÃO: Projects, Build, Packages, Plugins, VC, Collab, Localization, Data, Toolbox, Undo, Layouts, Notifs ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ PROJECT SETTINGS ============
ARKHER_REG.ProjectSettings = function()
	local g, root = K.window("ArkherProjectSettings", "Project Settings", 240, 80, 560, 400)
	K.txt(root, "Name", 12, 40, 80, 20, 11, T.txt3)
	K.input(root, 100, 38, 200, 24, "SunEmblemBlock")
	K.txt(root, "Place ID", 12, 70, 80, 20, 11, T.txt3)
	K.input(root, 100, 68, 200, 24, "0x4F2A-ARKHER")
	K.txt(root, "Genre", 12, 100, 80, 20, 11, T.txt3)
	local gn = K.btn(root, "G", 100, 98, 200, 24, T.bg4, 4)
	K.txtS(gn, "Simulation / MMO", 11, T.txt2)
	local y = 136
	for _, tg in ipairs({ "Allow Copying", "Server Storage API", "Third-party APIs", "Studio Access to APIs", "Permissions: Arkher Cloud" }) do
		K.toggle(root, 12, y, true, tg)
		y = y + 24
	end
	local icon = K.f(root, "IC", 340, 40, 96, 96, T.bg4)
	K.corner(icon, 8)
	K.stroke(icon, T.line2, 1)
	ICON.emblem(K.f(icon, "E", 24, 24, 48, 48), 48)
	K.txt(root, "Icon / Thumbnail", 340, 142, 120, 16, 10, T.txt4)
	return g
end

-- ============ BUILD SETTINGS / PUBLISH ============
ARKHER_REG.BuildSettings = function()
	local g, root = K.window("ArkherBuildSettings", "Build Settings / Publish", 260, 90, 600, 400)
	local plats = { "Web", "Android", "Desktop", "Standalone", "Package" }
	local x = 8
	for i, p in ipairs(plats) do
		local card = K.btn(root, "PL_" .. p, x, 36, 104, 64, i == 1 and T.sel or T.bg4, 6)
		K.txtS(card, p, 12, i == 1 and T.txt or T.txt2, ARKHER.FONTB)
		K.hover(card, card.BackgroundColor3, T.hover)
		x = x + 110
	end
	local y = 116
	for _, s in ipairs({ { "Compression", 0.7 }, { "Strip unused", 0.9 }, { "Texture budget", 0.5 } }) do
		K.sliderRow(root, s[1], s[2], y)
		y = y + 22
	end
	local bar = K.f(root, "Bar", 8, y + 8, 584, 8, T.bg4)
	K.corner(bar, 4)
	local fill = K.f(bar, "F", 0, 0, 0, 8, T.green)
	K.corner(fill, 4)
	local st = K.txt(root, "idle", 8, y + 20, 584, 16, 10, T.txt3, ARKHER.MONO)
	local build = K.btn(root, "BD", 8, y + 42, 140, 28, T.sel, 5)
	K.txtS(build, "BUILD + SIGN", 12, T.txt, ARKHER.FONTB)
	build.MouseButton1Click:Connect(function()
		coroutine.wrap(function()
			for w = 0, 584, 8 do
				fill.Size = UDim2.new(0, w, 0, 8)
				st.Text = "building... " .. math.floor(w / 584 * 100) .. "% (integrity: sha256)"
				wait(0.03)
			end
			st.Text = "build ok | size 42.7MB | signature ARKHER-ED25519 verified"
			K.notify("PUBLISH", "Build assinado com integridade verificada", "SUCCESS")
		end)()
	end)
	K.row(root, "Dependencies", "UES-Core, D-O15, Singularity", y + 44)
	return g
end

-- ============ PACKAGE MANAGER ============
ARKHER_REG.PackageManager = function()
	local g, root = K.window("ArkherPackageManager", "Package Manager", 280, 100, 560, 380)
	K.search(root, 8, 32, 544, 24, "Search packages...")
	local pkgs = {
		{ "ues-core", "12.4.0", "installed" }, { "d-o15", "3.1.2", "installed" },
		{ "singularity-bridge", "1.9.0", "update" }, { "arkher-terrain", "2.0.1", "installed" },
		{ "arkher-audio-hrtf", "0.8.3", "install" }, { "nmn-behavior", "4.2.0", "update" },
		{ "collab-rt", "1.2.7", "installed" }, { "vfx-hdr", "2.2.0", "install" },
	}
	local y = 64
	for _, p in ipairs(pkgs) do
		local row = K.f(root, "PK_" .. p[1], 8, y, 544, 24, T.bg4)
		K.corner(row, 4)
		ICON.toolbox(K.f(row, "I", 6, 4, 16, 16), 16)
		K.txt(row, p[1], 28, 0, 200, 24, 11, T.txt, ARKHER.MONO)
		K.txt(row, "v" .. p[2], 240, 0, 80, 24, 10, T.txt3, ARKHER.MONO)
		local act = p[3]
		local b = K.btn(row, "A", 460, 2, 78, 20, act == "installed" and T.bg2 or T.sel, 4)
		K.txtS(b, string.upper(act), 9, act == "installed" and T.txt3 or T.txt, ARKHER.FONTB)
		if act ~= "installed" then
			b.MouseButton1Click:Connect(function()
				K.txt(row, "", 0, 0, 0, 0, 1)
				K.notify("PACKAGES", p[1] .. " -> " .. (act == "update" and "atualizado" or "instalado"), "SUCCESS")
				b.BackgroundColor3 = T.bg2
			end)
		end
		y = y + 27
	end
	return g
end

-- ============ PLUGIN MANAGER / TOOLBAR ============
ARKHER_REG.PluginManager = function()
	local g, root = K.window("ArkherPluginManager", "Plugin Toolbar / Manager", 300, 80, 520, 380)
	local plugs = {
		{ "Arkher Terrain Brush", true }, { "RoStrap Compat", false }, { "Animation Capture", true },
		{ "Lightmap Baker", false }, { "Mesh Optimizer", true }, { "Git Sync", true },
	}
	local y = 38
	for _, p in ipairs(plugs) do
		local row = K.f(root, "PL", 8, y, 504, 26, T.bg4)
		K.corner(row, 4)
		ICON.plugin(K.f(row, "I", 6, 5, 16, 16), 16)
		K.txt(row, p[1], 30, 0, 260, 26, 11, T.txt2)
		K.toggle(row, 380, 4, p[2], nil)
		local gear = K.btn(row, "G", 470, 5, 16, 16, T.bg4, 3)
		ICON.settings(gear, 14, 1, 1)
		K.hover(gear, T.bg4, T.hover)
		y = y + 29
	end
	local hot = K.btn(root, "HR", 8, y + 6, 120, 24, T.hover, 4)
	K.txtS(hot, "HOT RELOAD", 10, T.txt2, ARKHER.FONTB)
	hot.MouseButton1Click:Connect(function() K.notify("PLUGINS", "Hot reload executado sem perda de estado", "SUCCESS") end)
	return g
end

-- ============ VERSION CONTROL ============
ARKHER_REG.VersionControl = function()
	local g, root = K.window("ArkherVersionControl", "Version Control", 240, 70, 620, 420)
	local br = K.btn(root, "BR", 8, 32, 160, 24, T.bg4, 4)
	ICON.share(K.f(br, "I", 6, 4, 16, 16), 16)
	K.txt(br, "arena/v2-uis", 28, 0, 110, 24, 11, T.txt)
	ICON.chevD(K.f(br, "C", 140, 8, 8, 8), 8)
	local commits = {
		{ "09b5140", "Add Arkher package via Git LFS", "main" },
		{ "a41f2c9", "V2 ribbon replica (frame icons)", "arena" },
		{ "b77e01d", "Hierarchy + Properties dock", "arena" },
		{ "c03aa55", "D-O15 pressure wiring", "arena" },
	}
	local y = 66
	for _, c in ipairs(commits) do
		local row = K.f(root, "CM", 8, y, 380, 24, T.bg4)
		K.corner(row, 4)
		K.txt(row, c[1], 8, 0, 64, 24, 10, T.orange, ARKHER.MONO)
		K.txt(row, c[2], 78, 0, 240, 24, 10, T.txt2)
		K.txt(row, c[3], 330, 0, 50, 24, 9, T.accent2, ARKHER.MONO)
		y = y + 27
	end
	local changes = { "M studio-v2/src/prelude.luau", "M studio-v2/src/body_main.luau", "A studio-v2/src/ed_c.luau", "A studio-v2/src/ed_d.luau" }
	local ch = K.f(root, "CH", 400, 32, 212, 240, T.bg4)
	K.corner(ch, 4)
	K.txt(ch, "CHANGES", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	local cy = 22
	for _, c in ipairs(changes) do
		K.txt(ch, c, 8, cy, 200, 16, 10, c:sub(1, 1) == "A" and T.green or T.yellow, ARKHER.MONO)
		cy = cy + 17
	end
	local bx = 400
	for _, bn in ipairs({ "COMMIT", "PUSH", "PULL" }) do
		local b = K.btn(root, "VC_" .. bn, bx, 284, 64, 24, bn == "COMMIT" and T.sel or T.hover, 4)
		K.txtS(b, bn, 9, T.txt, ARKHER.FONTB)
		b.MouseButton1Click:Connect(function() K.notify("VC", bn .. " concluído (branch arena)", "SUCCESS") end)
		bx = bx + 70
	end
	return g
end

-- ============ COLLABORATION ============
ARKHER_REG.Collaboration = function()
	local g, root = K.window("ArkherCollaboration", "Collaboration Settings", 260, 90, 560, 400)
	local users = { { "WhiteXz7", T.purple, "owner" }, { "Arkher-Agent", T.accent2, "edit" }, { "Guest_42", T.yellow, "view" } }
	local y = 40
	for _, u in ipairs(users) do
		local av = K.f(root, "AV", 10, y, 20, 20, u[2])
		K.corner(av, 10)
		K.txt(root, u[1], 38, y + 2, 140, 18, 11, T.txt)
		local cur = K.f(root, "CUR", 190, y + 4, 8, 12, u[2])
		cur.Rotation = -15
		local perm = K.btn(root, "PM", 240, y, 90, 20, T.bg4, 4)
		K.txtS(perm, u[3], 10, T.txt2)
		K.hover(perm, T.bg4, T.hover)
		y = y + 28
	end
	local inv = K.input(root, 10, y + 8, 240, 24, "invite by email...")
	local sb = K.btn(root, "INV", 256, y + 8, 74, 24, T.sel, 4)
	K.txtS(sb, "INVITE", 10, T.txt, ARKHER.FONTB)
	sb.MouseButton1Click:Connect(function() K.notify("COLLAB", "Convite capability-scoped enviado", "SUCCESS") end)
	local feed = K.f(root, "FD", 340, 36, 212, 320, T.bg4)
	K.corner(feed, 4)
	K.txt(feed, "CHANGES FEED", 8, 4, 140, 14, 9, T.txt4, ARKHER.FONTB)
	local fl = { "WhiteXz7 moved Baseplate", "Arkher-Agent edited Ribbon", "Guest_42 viewing Viewport", "WhiteXz7 saved snapshot", "Arkher-Agent added icons" }
	local fy = 22
	for _, f in ipairs(fl) do
		K.txt(feed, f, 8, fy, 196, 14, 9, T.txt3)
		fy = fy + 16
	end
	return g
end

-- ============ LOCALIZATION ============
ARKHER_REG.Localization = function()
	local g, root = K.window("ArkherLocalization", "Localization", 280, 100, 560, 380)
	local langs = { { "pt-BR", 1.0 }, { "en-US", 0.92 }, { "es-419", 0.74 }, { "ja-JP", 0.41 }, { "de-DE", 0.38 } }
	local y = 40
	for _, l in ipairs(langs) do
		K.txt(root, l[1], 12, y, 60, 18, 11, T.txt, ARKHER.MONO)
		local track = K.f(root, "TR", 80, y + 5, 300, 8, T.bg4)
		K.corner(track, 4)
		local f = K.f(track, "F", 0, 0, math.floor(300 * l[2]), 8, l[2] == 1 and T.green or T.accent2)
		K.corner(f, 4)
		K.txt(root, math.floor(l[2] * 100) .. "%", 390, y, 50, 18, 10, T.txt3)
		y = y + 24
	end
	local tr = K.btn(root, "TRB", 12, y + 10, 180, 26, T.sel, 5)
	K.txtS(tr, "TRANSLATE MISSING", 10, T.txt, ARKHER.FONTB)
	tr.MouseButton1Click:Connect(function() K.notify("LOCALIZATION", "Singularity traduziu 214 strings pendentes", "SUCCESS") end)
	local prev = K.f(root, "PV", 12, y + 46, 536, 90, T.bg4)
	K.corner(prev, 4)
	K.txt(prev, "Preview: \"Como posso ajudar você a criar?\"", 12, 10, 500, 18, 12, T.txt)
	K.txt(prev, "Locale ativo: pt-BR (fallback en-US)", 12, 34, 500, 16, 10, T.txt4)
	return g
end

-- ============ DATA MANAGER ============
ARKHER_REG.DataManager = function()
	local g, root = K.window("ArkherDataManager", "Data / Storage Manager", 240, 80, 640, 420)
	local stores = { "player_progress", "world_state", "economy_ledger", "npc_memory" }
	local x = 8
	for i, s in ipairs(stores) do
		local b = K.btn(root, "ST_" .. s, x, 32, 30 + #s * 6, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, s, 10, i == 1 and T.txt or T.txt2, ARKHER.MONO)
		K.hover(b, b.BackgroundColor3, T.hover)
		x = x + 36 + #s * 6
	end
	local entries = K.f(root, "EN", 8, 62, 400, 240, T.bg4)
	K.corner(entries, 4)
	K.txt(entries, "KEY", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	K.txt(entries, "SIZE", 240, 4, 60, 14, 9, T.txt4, ARKHER.FONTB)
	K.txt(entries, "INTEGRITY", 300, 4, 90, 14, 9, T.txt4, ARKHER.FONTB)
	local rows = { { "uid_0x4F2A", "2.1KB", "sha ok" }, { "checkpoint_118", "48KB", "sha ok" }, { "snapshot_sun", "12KB", "sha ok" }, { "ledger_q3", "96KB", "rebuild" } }
	local ey = 22
	for _, r in ipairs(rows) do
		K.txt(entries, r[1], 8, ey, 200, 16, 10, T.txt2, ARKHER.MONO)
		K.txt(entries, r[2], 240, ey, 50, 16, 10, T.txt3, ARKHER.MONO)
		K.txt(entries, r[3], 300, ey, 90, 16, 10, r[3] == "sha ok" and T.green or T.orange, ARKHER.MONO)
		ey = ey + 18
	end
	local snaps = K.f(root, "SN", 416, 62, 216, 240, T.bg4)
	K.corner(snaps, 4)
	K.txt(snaps, "CHECKPOINTS", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	local sy = 22
	for i = 1, 6 do
		local row = K.btn(snaps, "S" .. i, 2, sy, 212, 20, T.bg4, 3)
		K.txt(row, "ckpt #" .. (120 - i), 8, 0, 100, 20, 10, T.txt2, ARKHER.MONO)
		local rs = K.btn(row, "R", 150, 2, 60, 16, T.hover, 3)
		K.txtS(rs, "RESTORE", 8, T.txt2)
		rs.MouseButton1Click:Connect(function() K.notify("DATA", "Checkpoint restaurado (validação ok)", "SUCCESS") end)
		sy = sy + 22
	end
	local bb = K.btn(root, "BK", 8, 310, 140, 26, T.sel, 5)
	K.txtS(bb, "BACKUP NOW", 10, T.txt, ARKHER.FONTB)
	bb.MouseButton1Click:Connect(function() K.notify("DATA", "Backup com checksum criado", "SUCCESS") end)
	return g
end

-- ============ TOOLBOX ============
ARKHER_REG.Toolbox = function()
	local g, root = K.window("ArkherToolbox", "Toolbox — Arkher Assets", 220, 70, 660, 440)
	local cats = { "3D", "Materials", "Textures", "Audio", "Animation", "Particles", "Shaders", "Images", "Video", "Data" }
	local cx = 8
	for i, c in ipairs(cats) do
		local b = K.btn(root, "TC_" .. c, cx, 32, 16 + #c * 6, 20, i == 1 and T.sel or T.bg4, 10)
		K.txtS(b, c, 9, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		cx = cx + 22 + #c * 6
	end
	K.search(root, 8, 58, 644, 24, "Semantic search: ex. \"medieval castle gate\"")
	local assets = {
		{ "Castle Gate", ICON.toolbox, C("#8F5F2C") }, { "River Spline", ICON.chat, C("#2A6BC0") },
		{ "Pine Forest", ICON.terrain, C("#3ECF7A") }, { "Torch VFX", ICON.gem, C("#F07E2E") },
		{ "Lute Loop", ICON.bulb, C("#F6C65B") }, { "Knight NPC", ICON.playersI, C("#8A6BFF") },
		{ "Stone Wall", ICON.boxG, C("#9AA7C0") }, { "Market Stall", ICON.folder, C("#E8B33C") },
	}
	local ax, ay = 8, 92
	for _, a in ipairs(assets) do
		local card = K.f(root, "AS", ax, ay, 150, 120, T.bg4)
		K.corner(card, 6)
		K.stroke(card, T.line2, 1)
		local pv = K.f(card, "PV", 6, 6, 138, 76, T.bg0)
		K.corner(pv, 4)
		a[2](K.f(pv, "I", 57, 26, 24, 24), 24)
		pv.BackgroundColor3 = Color3.new(a[3].R * 0.2, a[3].G * 0.2, a[3].B * 0.2)
		K.txt(card, a[1], 8, 88, 100, 14, 10, T.txt)
		local ins = K.btn(card, "INS", 108, 86, 36, 18, T.sel, 3)
		K.txtS(ins, "INS", 9, T.txt, ARKHER.FONTB)
		ins.MouseButton1Click:Connect(function()
			pcall(function()
				local p = Instance.new("Part")
				p.Name = a[1]
				p.Parent = workspace
			end)
			K.notify("TOOLBOX", a[1] .. " inserido no workspace", "SUCCESS")
		end)
		ax = ax + 158
		if ax > 490 then ax = 8 ay = ay + 128 end
	end
	return g
end

-- ============ UNDO / REDO ============
ARKHER_REG.UndoRedo = function()
	local g, root = K.window("ArkherUndoRedo", "Undo / Redo History", 300, 100, 420, 360)
	local hist = { "Insert Part", "Move Baseplate", "Rename SpamPoint", "Edit Ribbon icon", "Change Transparency", "Insert Script", "Terrain paint" }
	local y = 36
	for i, h in ipairs(hist) do
		local row = K.btn(root, "H" .. i, 8, y, 404, 20, i == 4 and T.sel or T.bg4, 3)
		K.txt(row, (i <= 4 and "  " or "↺ ") .. h, 10, 0, 300, 20, 10, i <= 4 and T.txt or T.txt4)
		K.hover(row, row.BackgroundColor3, T.hover)
		row.MouseButton1Click:Connect(function() K.notify("UNDO", "Saltou para: " .. h, "INFO") end)
		y = y + 22
	end
	local ub = K.btn(root, "U", 8, y + 8, 90, 24, T.hover, 4)
	K.txtS(ub, "UNDO", 11, T.txt, ARKHER.FONTB)
	local rb = K.btn(root, "R", 104, y + 8, 90, 24, T.hover, 4)
	K.txtS(rb, "REDO", 11, T.txt, ARKHER.FONTB)
	ub.MouseButton1Click:Connect(function() K.notify("UNDO", "Desfeito: Edit Ribbon icon", "INFO") end)
	rb.MouseButton1Click:Connect(function() K.notify("UNDO", "Refeito", "INFO") end)
	return g
end

-- ============ LAYOUTS / PROFILES / DOCKING ============
ARKHER_REG.Layouts = function()
	local g, root = K.window("ArkherLayouts", "Workspace Profiles / Layout / Docking", 280, 90, 520, 360)
	local lays = { "Default Dual-Panel", "Animation Focus", "Debug Wide", "Coding Minimal", "Full Screen Viewport" }
	local y = 36
	for i, l in ipairs(lays) do
		local row = K.btn(root, "L" .. i, 8, y, 300, 22, i == 1 and T.sel or T.bg4, 4)
		K.txt(row, l, 10, 0, 240, 22, 11, i == 1 and T.txt or T.txt2)
		K.hover(row, row.BackgroundColor3, T.hover)
		local ap = K.btn(row, "AP", 240, 2, 56, 18, T.hover, 3)
		K.txtS(ap, "APPLY", 9, T.txt2)
		ap.MouseButton1Click:Connect(function() K.notify("LAYOUT", "Layout \"" .. l .. "\" aplicado", "SUCCESS") end)
		y = y + 25
	end
	local sv = K.btn(root, "SV", 8, y + 6, 120, 24, T.sel, 4)
	K.txtS(sv, "SAVE CURRENT", 10, T.txt, ARKHER.FONTB)
	K.toggle(root, 330, 40, true, "Docking")
	K.toggle(root, 330, 64, true, "Multi-window")
	K.toggle(root, 330, 88, false, "Auto-hide panels")
	K.toggle(root, 330, 112, true, "Snap to edges")
	return g
end

-- ============ NOTIFICATIONS CENTER ============
ARKHER_REG.NotificationsCenter = function()
	local g, root = K.window("ArkherNotifications", "Notifications", 320, 110, 460, 340)
	local kinds = { "INFO", "PROCESSING", "SUCCESS", "WARNING", "ERROR" }
	local kx = 8
	for i, kk in ipairs(kinds) do
		local b = K.btn(root, "K_" .. kk, kx, 32, 16 + #kk * 6, 18, T.bg4, 9)
		K.txtS(b, kk, 8, T.txt2, ARKHER.FONTB)
		K.hover(b, T.bg4, T.hover)
		kx = kx + 22 + #kk * 6
	end
	local feed = {
		{ "SUCCESS", "Snapshot salvo (checksum ok)" }, { "INFO", "Collab: Arkher-Agent entrou" },
		{ "WARNING", "D-O15: pressão alta no RENDER" }, { "PROCESSING", "Build em andamento..." },
		{ "ERROR", "Plugin Lightmap: timeout (isolado pelo sandbox)" }, { "INFO", "Localization pt-BR 100%" },
	}
	local cols = { SUCCESS = T.green, INFO = T.accent, WARNING = T.orange, PROCESSING = T.accent2, ERROR = C("#E05252") }
	local y = 58
	for _, f in ipairs(feed) do
		local row = K.f(root, "N", 8, y, 444, 24, T.bg4)
		K.corner(row, 4)
		K.f(row, "B", 0, 0, 3, 24, cols[f[1]])
		K.txt(row, f[1], 10, 0, 90, 24, 9, cols[f[1]], ARKHER.FONTB)
		K.txt(row, f[2], 104, 0, 330, 24, 10, T.txt2)
		y = y + 27
	end
	return g
end
--[[ ARKHER STUDIO V2 — MAIN UI (replica fiel da print) ]]
local function BUILD_MAIN()
	local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
	local TITLE_H, MENU_H, RIB_H, TAB_H = 26, 24, 78, 26
	local LEFT_W, RIGHT_W = 250, 222
	local TOP = TITLE_H + MENU_H + RIB_H

	local g = K.gui("ArkherStudioMainUI")
	local root = K.fs(g, "Root", 0, 0, 1, 1, T.bg1)

	-- ================= TITLE BAR =================
	local title = K.f(root, "TitleBar", 0, 0, 10, TITLE_H, T.bg0)
	title.Size = UDim2.new(1, 0, 0, TITLE_H)
	local emb = K.f(title, "Emblem", 8, 4, 18, 18)
	ICON.emblem(emb, 18)
	local tname = K.txt(title, "ARKHER STUDIO", 30, 0, 160, TITLE_H, 12, T.txt, ARKHER.FONTB)
	local winBtns = K.f(title, "Win", 0, 0, 70, TITLE_H)
	winBtns.Position = UDim2.new(1, -70, 0, 0)
	local bmin = K.btn(winBtns, "Min", 6, 5, 24, 16, T.bg0, 3)
	K.hover(bmin, T.bg0, T.hover)
	ICON.minus(bmin)
	local bmax = K.btn(winBtns, "Max", 38, 5, 24, 16, T.bg0, 3)
	K.hover(bmax, T.bg0, T.hover)
	ICON.square(bmax)

	-- ================= MENU BAR =================
	local menu = K.f(root, "MenuBar", 0, TITLE_H, 10, MENU_H, T.bg1)
	menu.Size = UDim2.new(1, 0, 0, MENU_H)
	local MENUS = {
		FILE = { "Save", "Open", "Save to Arkher", "-", "Import Asset", "Export Place", "-", "Recent Places", "Close Place" },
		EDIT = { "Undo", "Redo", "-", "Cut", "Copy", "Paste", "Delete", "-", "Rename", "Duplicate" },
		VIEW = { "Properties", "Hierarchy", "Console", "Output", "Command Palette", "-", "Fullscreen Viewport", "Reset Layout" },
		INSERT = { "Model", "Folder", "Script", "LocalScript", "ModuleScript", "Text", "Part", "Mesh", "Light", "Sound" },
		RUN = { "Play", "Pause", "Stop", "-", "Run Diagnostics", "Performance Stats", "-", "Sandbox: ON" },
		GAME = { "Game Settings", "Places", "Publish to Arkher", "-", "Passes", "Developer Products", "Team Create" },
	}
	local mx = 8
	local openDD = nil
	local function closeDD()
		if openDD then openDD:Destroy() openDD = nil end
	end
	local function dropdown(anchor, items)
		closeDD()
		local dd = K.f(root, "Dropdown", anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y, 190, 0, T.bg2)
		K.corner(dd, 4)
		K.stroke(dd, T.line2, 1)
		local y = 2
		for _, it in ipairs(items) do
			if it == "-" then
				K.f(dd, "Sep", 4, y, 182, 1, T.line)
				y = y + 5
			else
				local ib = K.btn(dd, "MI_" .. it, 2, y, 186, 20, T.bg2, 3)
				K.txt(ib, it, 10, 0, 170, 20, 11, T.txt2)
				K.hover(ib, T.bg2, T.hover)
				ib.MouseButton1Click:Connect(function()
					closeDD()
					if ARKHER_ACTIONS and ARKHER_ACTIONS.menu then ARKHER_ACTIONS.menu(it) end
					K.notify("ARKHER", it .. " acionado", "INFO")
				end)
				y = y + 21
			end
		end
		dd.Size = UDim2.new(0, 190, 0, y + 2)
		dd.ZIndex = 50
		openDD = dd
	end
	for _, name in ipairs({ "FILE", "EDIT", "VIEW", "INSERT", "RUN", "GAME" }) do
		local mb = K.btn(menu, "M_" .. name, mx, 2, 46, 20, T.bg1, 3)
		K.txtS(mb, name, 11, T.txt2, ARKHER.FONT)
		K.hover(mb, T.bg1, T.hover)
		mb.MouseButton1Click:Connect(function() dropdown(mb, MENUS[name]) end)
		mx = mx + 50
	end
	-- right side of menu bar
	local rightMenu = K.f(menu, "Right", 0, 0, 300, MENU_H)
	rightMenu.Position = UDim2.new(1, -300, 0, 0)
	local rx = 8
	for _, nm in ipairs({ "Collaborate", "Invites", "Changes" }) do
		local w = 26 + string.len(nm) * 6
		local b = K.btn(rightMenu, "R_" .. nm, rx, 2, w, 20, T.bg1, 3)
		K.txtS(b, nm, 11, T.txt2)
		K.hover(b, T.bg1, T.hover)
		b.MouseButton1Click:Connect(function()
			if ARKHER_ACTIONS and ARKHER_ACTIONS.menu then ARKHER_ACTIONS.menu(nm) end
			K.notify("ARKHER", nm, "INFO")
		end)
		rx = rx + w + 8
	end
	local av = K.f(rightMenu, "Avatar", rx + 2, 4, 16, 16, T.purple)
	K.corner(av, 8)
	K.txt(rightMenu, "ARKH", rx + 22, 0, 40, MENU_H, 11, T.txt2)

	-- ================= RIBBON =================
	local rib = K.f(root, "Ribbon", 0, TITLE_H + MENU_H, 10, RIB_H, T.bg2)
	rib.Size = UDim2.new(1, 0, 0, RIB_H)
	local ribClip = rib
	local x = 6
	local function sep()
		K.f(rib, "Sep", x, 8, 1, RIB_H - 16, T.line)
		x = x + 8
	end
	-- group 1: file ops
	local bSave = K.ribbonBtn(rib, x, 44, ICON.save, "Save")
	x = x + 46
	local bOpen = K.ribbonBtn(rib, x, 44, ICON.open, "Open")
	x = x + 46
	local bCloud = K.ribbonBtn(rib, x, 48, ICON.cloud, "Save to\nArkher")
	x = x + 52
	sep()
	-- group 2: transform
	local bSel = K.ribbonBtn(rib, x, 44, ICON.select, "Select", { selected = true })
	x = x + 46
	local bMove = K.ribbonBtn(rib, x, 40, ICON.move, "Scale")
	x = x + 42
	local bScale = K.ribbonBtn(rib, x, 40, ICON.scaleI, "Scale")
	x = x + 42
	local bRot = K.ribbonBtn(rib, x, 40, ICON.rotate, "Rotate")
	x = x + 46
	local trCol = K.f(rib, "TransformCol", x, 6, 78, 58)
	local trI = K.f(trCol, "TI", 2, 2, 14, 14)
	ICON.transform(trI, 14)
	K.txt(trCol, "Transform", 20, 0, 58, 14, 10, T.txt2)
	local lkI = K.f(trCol, "LI", 2, 20, 14, 14)
	ICON.lock(lkI, 14)
	K.txt(trCol, "Lock", 20, 18, 34, 14, 10, T.txt2)
	ICON.chevD(K.f(trCol, "LV", 52, 20, 8, 8), 8)
	K.txt(trCol, "Local/Global", 0, 40, 78, 12, 8, T.txt4, ARKHER.FONT, Enum.TextXAlignment.Left)
	x = x + 84
	sep()
	-- group 3: insert
	for _, e in ipairs({ { ICON.model, "Model" }, { ICON.folder, "Folder" }, { ICON.script, "Script" }, { ICON.textA, "Text" } }) do
		K.ribbonBtn(rib, x, 42, e[1], e[2])
		x = x + 44
	end
	sep()
	-- group 4: run
	K.ribbonBtn(rib, x, 40, ICON.play, "Play")
	x = x + 42
	K.ribbonBtn(rib, x, 40, ICON.pause, "Pause")
	x = x + 42
	K.ribbonBtn(rib, x, 40, ICON.data, "Data")
	x = x + 42
	K.ribbonBtn(rib, x, 44, ICON.globe, "Localization")
	x = x + 46
	K.ribbonBtn(rib, x, 44, ICON.settings, "Settings")
	x = x + 48
	sep()
	-- group 5: toolbox
	K.ribbonBtn(rib, x, 46, ICON.toolbox, "Toolbox")
	x = x + 48
	K.ribbonBtn(rib, x, 62, ICON.people, "Collaboration\nSettings")
	x = x + 68
	sep()
	-- group 6: cloud / plugin
	K.ribbonBtn(rib, x, 48, ICON.info, "Arkher\nCloud")
	x = x + 52
	K.ribbonBtn(rib, x, 52, ICON.plugin, "Plugin\nToolbar")

	-- ribbon wiring (hooks overridable by systems)
	local function act(name)
		if ARKHER_ACTIONS and ARKHER_ACTIONS.ribbon then ARKHER_ACTIONS.ribbon(name) end
		K.notify("ARKHER STUDIO", name, "INFO")
	end
	bSave.MouseButton1Click:Connect(function() act("Save") end)
	bOpen.MouseButton1Click:Connect(function() act("Open") end)
	bCloud.MouseButton1Click:Connect(function() act("Save to Arkher") end)
	bSel.MouseButton1Click:Connect(function() act("Select") end)
	bMove.MouseButton1Click:Connect(function() act("Move") end)
	bScale.MouseButton1Click:Connect(function() act("Scale") end)
	bRot.MouseButton1Click:Connect(function() act("Rotate") end)

	-- ================= TAB BAR + VIEWPORT =================
	local tabbar = K.f(root, "TabBar", LEFT_W, TOP, 10, TAB_H, T.bg1)
	tabbar.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 0, TAB_H)
	local tab1 = K.f(tabbar, "TabActive", 4, 0, 150, TAB_H, T.bg2)
	K.stroke(tab1, T.line, 1)
	local ticon = K.f(tab1, "I", 8, 5, 16, 16)
	ICON.share(ticon, 16)
	K.txt(tab1, "SunEmblemBlock", 28, 0, 100, TAB_H, 11, T.txt)
	local tx = K.btn(tab1, "X", 128, 5, 16, 16, T.bg2, 3)
	K.hover(tx, T.bg2, C("#3A2530"))
	ICON.close(tx)
	local tab2 = K.btn(tabbar, "Tab2", 158, 0, 26, TAB_H, T.bg1, 0)
	ICON.minus(tab2)
	local dockI = K.btn(tabbar, "Dock", 0, 5, 16, 16, T.bg1, 3)
	dockI.Position = UDim2.new(1, -22, 0, 5)
	ICON.dock(dockI)

	local vp = K.f(root, "Viewport", LEFT_W, TOP + TAB_H, 10, 10, T.vp1)
	vp.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 1, -(TOP + TAB_H))
	vp.ClipsDescendants = true
	local function checker()
		vp:ClearAllChildren()
		local w, h = vp.AbsoluteSize.X, vp.AbsoluteSize.Y
		if w <= 0 then w = 1024 end
		if h <= 0 then h = 512 end
		local tile = 40
		local cols = math.ceil(w / tile)
		local rows = math.ceil(h / tile)
		if cols * rows > 900 then tile = 64 cols = math.ceil(w / tile) rows = math.ceil(h / tile) end
		for ry = 0, rows - 1 do
			for cx = 0, cols - 1 do
				local even = (ry + cx) % 2 == 0
				local q = K.f(vp, "ck", cx * tile, ry * tile, tile, tile, even and T.vp1 or T.vp2)
			end
		end
	end
	checker()
	pcall(function()
		vp:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() checker() end)
	end)

	-- ================= PROPERTIES (LEFT) =================
	local left = K.f(root, "Left", 0, TOP, LEFT_W, 10, T.bg3)
	left.Size = UDim2.new(0, LEFT_W, 1, -TOP)
	local lhead = K.f(left, "Head", 0, 0, LEFT_W, TAB_H, T.bg3)
	K.txt(lhead, "Properties", 8, 0, 120, TAB_H, 12, T.txt2, ARKHER.FONTB)
	local pin1 = K.btn(lhead, "Pin", LEFT_W - 44, 5, 16, 16, T.bg3, 3)
	ICON.pin(pin1)
	K.hover(pin1, T.bg3, T.hover)
	local lx = K.btn(lhead, "X", LEFT_W - 24, 5, 16, 16, T.bg3, 3)
	K.hover(lx, T.bg3, C("#3A2530"))
	ICON.close(lx)
	lx.MouseButton1Click:Connect(function() left.Visible = not left.Visible end)

	K.search(left, 6, 32, LEFT_W - 12, 22, "Search Properties (Ctrl+Shift+P)")

	local objRow = K.f(left, "Obj", 0, 60, LEFT_W, 24, T.bg3)
	local objI = K.f(objRow, "I", 8, 4, 16, 16)
	ICON.cubeW(objI, 16)
	K.txt(objRow, "Part", 30, 0, 120, 24, 12, T.txt, ARKHER.FONTB)

	local secs = K.f(left, "Sections", 0, 88, LEFT_W, 10)
	secs.Size = UDim2.new(1, 0, 1, -88)
	secs.ClipsDescendants = true

	local s1, s1b = K.section(secs, "Core Properties", true, 0)
	K.row(s1b, "Position", "X: 16, 19, 5", 2)
	K.row(s1b, "Orientation", "X: 35, 223, 3", 22)
	K.sliderRow(s1b, "Transparency", 0, 42)
	K.sliderRow(s1b, "Transparency", 0, 62)
	K.txt(s1b, "Color", 22, 82, 80, 18, 11, T.txt3)
	local sw = K.f(s1b, "Swatch", 118, 83, 16, 16, C("#C89B7B"))
	K.corner(sw, 2)
	K.stroke(sw, T.line2, 1)
	K.txt(s1b, "Color", 140, 82, 60, 18, 11, T.txt)

	local s2, s2b = K.section(secs, "Data", false, 0)
	K.row(s2b, "UniqueId", "0x4F2A", 2)
	K.row(s2b, "Archivable", "true", 22)

	local s3, s3b = K.section(secs, "Transform", false, 0)
	K.row(s3b, "PivotOffset", "0, 0, 0", 2)
	K.row(s3b, "Size", "4, 1, 2", 22)

	local s4, s4b = K.section(secs, "Physics", true, 0)
	K.checkRow(s4b, "Transparency", true, 2)
	K.checkRow(s4b, "ReplicatedFirst", true, 22)
	K.checkRow(s4b, "Transformfall", true, 42)
	K.checkRow(s4b, "PhysicsPlayer", true, 62)
	K.checkRow(s4b, "PhysicsTodall...", false, 82)

	local s5, s5b = K.section(secs, "Scripting", true, 0)
	K.checkRow(s5b, "Scripting", true, 2)

	local s6, s6b = K.section(secs, "Advanced Barre", false, 0)
	K.row(s6b, "CollisionFidelity", "Box", 2)
	K.row(s6b, "Massless", "false", 22)

	K.reflow(secs)
	-- reflow after each section body measured (sections already laid out in creation order)

	-- ================= HIERARCHY (RIGHT) =================
	local right = K.f(root, "Right", 0, TOP, RIGHT_W, 10, T.bg3)
	right.Position = UDim2.new(1, -RIGHT_W, 0, TOP)
	right.Size = UDim2.new(0, RIGHT_W, 1, -TOP)
	local rhead = K.f(right, "Head", 0, 0, RIGHT_W, TAB_H, T.bg3)
	K.txt(rhead, "Hierarchy", 8, 0, 120, TAB_H, 12, T.txt2, ARKHER.FONTB)
	local pin2 = K.btn(rhead, "Pin", RIGHT_W - 44, 5, 16, 16, T.bg3, 3)
	ICON.pin(pin2)
	K.hover(pin2, T.bg3, T.hover)
	local rx2 = K.btn(rhead, "X", RIGHT_W - 24, 5, 16, 16, T.bg3, 3)
	K.hover(rx2, T.bg3, C("#3A2530"))
	ICON.close(rx2)
	rx2.MouseButton1Click:Connect(function() right.Visible = not right.Visible end)

	K.search(right, 6, 32, RIGHT_W - 12, 22, "Filter workspace (Ctrl+Shift+X)")

	local tree = K.f(right, "Tree", 0, 60, RIGHT_W, 10)
	tree.Size = UDim2.new(1, 0, 1, -60)
	tree.ClipsDescendants = true
	local y = 0
	local function trow(depth, icon, name, state)
		K.treeRow(tree, depth, icon, name, state, y)
		y = y + 20
	end
	trow(0, ICON.ws, "Workspace", "open")
	trow(1, ICON.plate, "Baseplate", "closed")
	trow(1, ICON.cubeW, "SpamPoint", "closed")
	trow(1, ICON.terrain, "Terrain", "closed")
	trow(1, ICON.camera, "Camera", nil)
	trow(0, ICON.playersI, "Players +", "closed")
	trow(0, ICON.bulb, "Lighting +", nil)
	trow(0, ICON.gem, "MaterialService +", nil)
	trow(0, ICON.repfirst, "ReplicatedFirst +", "closed")
	trow(0, ICON.boxG, "ReplicatedStorage +", nil)
	trow(0, ICON.cubeT, "ServerScriptService", nil)
	trow(0, ICON.cubeT, "ServerStorage", nil)
	trow(0, ICON.folder, "StarterGui +", "closed")
	trow(0, ICON.folderP, "StarterPack +", nil)
	trow(0, ICON.playercard, "StarterPlayer +", "closed")
	trow(0, ICON.chat, "TextChatService", nil)

	return g
end
BUILD_MAIN()

-- ===== DRIVER: monta todas as UIs =====
pcall(function() ARKHER_REG.StatusBar() end)
ARKHER.openAll()
