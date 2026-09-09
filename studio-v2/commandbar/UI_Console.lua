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
ARKHER_REG.Console()
