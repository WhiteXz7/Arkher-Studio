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
ARKHER_REG.AudioEditor()
