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
ARKHER_REG.NotificationsCenter()
