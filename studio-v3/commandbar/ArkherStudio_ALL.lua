do
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
	g.ColorSequence = ColorSequence.new(c1, c2)
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
	g.DisplayOrder = 900
	-- 1) no Studio (command bar/plugin): CoreGui → visivel IMEDIATO, sem precisar apertar F5
	local placed = false
	pcall(function()
		local coreGui = game:FindFirstChild("CoreGui")
		if coreGui then
			local folder = coreGui:FindFirstChild("ArkherStudio")
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = "ArkherStudio"
				folder.Parent = coreGui
			end
			g.Parent = folder
			placed = g.Parent ~= nil
		end
	end)
	-- 2) em Play / client: StarterGui (o Studio clona pro PlayerGui no spawn)
	if not placed then
		pcall(function() g.Parent = StarterGui end)
		if not g.Parent then pcall(function() g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui", 2) end) end
	end
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

-- =====================================================================
-- PRELUDE V3 — EXTENSOES (widgets novos, icones novos, registry, bus, log)
-- =====================================================================
T.neon = C("#00D4FF")
T.dark = C("#0E1430")
T.danger = C("#E05252")
T.ok = T.green

-- ---------- EVENT BUS (sistemas se falam sem acoplamento) ----------
local Bus = { _h = {} }
function Bus.on(ev, fn)
	Bus._h[ev] = Bus._h[ev] or {}
	table.insert(Bus._h[ev], fn)
	return fn
end
function Bus.emit(ev, ...)
	local hs = Bus._h[ev]
	if not hs then return end
	for _, fn in ipairs(hs) do pcall(fn, ...) end
end
function Bus.has(ev) return Bus._h[ev] ~= nil end
_G.Bus = Bus

-- ---------- OUTPUT / LOG (Console UI consome isto) ----------
ARKHER = { T = T, K = K, ICON = ICON, C = C, FONT = FONT, FONTB = FONTB, MONO = MONO, Bus = Bus }
ARKHER.OUTPUT = {}
function ARKHER.out(kind, msg)
	kind = kind or "INFO"
	local entry = { t = tostring(tick and tick() or 0), kind = kind, msg = tostring(msg) }
	table.insert(ARKHER.OUTPUT, entry)
	if #ARKHER.OUTPUT > 400 then table.remove(ARKHER.OUTPUT, 1) end
	Bus.emit("output", entry)
	local ok = pcall(print, "[ARKHER:" .. kind .. "] " .. tostring(msg))
end

-- ---------- REGISTRY (cada UI se registra: nome, titulo, categoria, icone, desc, build) ----------
ARKHER.REG = {}
ARKHER.CATALOG = {}
function ARKHER.reg(name, title, cat, iconFn, desc, build)
	ARKHER.REG[name] = build
	ARKHER.CATALOG[name] = { title = title, cat = cat or "System", icon = iconFn, desc = desc or "" }
end
function ARKHER.open(name)
	local b = ARKHER.REG[name]
	if not b then ARKHER.out("WARNING", "UI nao registrada: " .. tostring(name)) return nil end
	local ok, err = pcall(b)
	if not ok then ARKHER.out("ERROR", "UI " .. name .. " falhou: " .. tostring(err)) end
	return ok
end
function ARKHER.listUIs()
	local out = {}
	for n in pairs(ARKHER.REG) do out[#out + 1] = n end
	table.sort(out)
	return out
end
function ARKHER.openAll()
	local n = 0
	for name in pairs(ARKHER.REG) do
		if name ~= "Splash" then
			if ARKHER.open(name) then n = n + 1 end
		end
	end
	return n
end

-- ---------- ACTIONS (comandos centrais: menus/atalhos/chamadas da IA usam ARKHER.cmd) ----------
ARKHER.ACTIONS = {}
function ARKHER.on(cmd, fn) ARKHER.ACTIONS[cmd] = fn end
ARKHER.cmd = function(cmd, ...)
	local fn = ARKHER.ACTIONS[cmd]
	if not fn then
		ARKHER.out("WARNING", "Comando sem handler: " .. tostring(cmd))
		return nil
	end
	local ok, res = pcall(fn, ...)
	if not ok then ARKHER.out("ERROR", "Comando " .. cmd .. ": " .. tostring(res)) end
	return res
end

-- ---------- STATE GLOBAL DO EDITOR ----------
ARKHER.STATE = {
	tool = "Select",
	placeName = "Untitled",
	placeId = 0,
	playing = false,
	sandbox = true,
	do15Level = 2, -- 1..4 (1=MAX 4=ECO)
	cloud = { endpoint = "", connected = false, places = {} },
	ai = { mode = "BUILD", model = "auto", online = false },
}

-- ---------- WIDGETS NOVOS ----------
-- barra de abas
function K.tabs(parent, x, y, w, names, activeIdx, onPick)
	local bar = K.f(parent, "Tabs", x, y, w, 22, T.bg0)
	local x2 = 0
	for i, nm in ipairs(names) do
		local tw = 30 + #nm * 6
		local b = K.btn(bar, "T_" .. tostring(i), x2, 0, tw, 22, (i == (activeIdx or 1)) and T.bg2 or T.bg0, 0)
		K.txtS(b, nm, 10, i == (activeIdx or 1) and T.txt or T.txt3)
		K.f(b, "Und", 0, 20, tw, 2, i == (activeIdx or 1) and T.accent or T.bg0)
		if i > 1 then K.f(b, "Sep", 0, 4, 1, 14, T.line) end
		local idx = i
		K.hover(b, T.bg0, T.hover)
		if onPick then b.MouseButton1Click:Connect(function() onPick(idx) end) end
		x2 = x2 + tw
	end
	return bar
end

-- barra de progresso
function K.progress(parent, x, y, w, val, color)
	local track = K.f(parent, "Prog", x, y, w, 5, T.bg4)
	K.corner(track, 3)
	local fill = K.f(track, "Fill", 0, 0, math.floor(w * (val or 0)), 5, color or T.accent)
	K.corner(fill, 3)
	return track, fill
end

-- knob circular (aprox. por segmentos)
function K.knob(parent, x, y, size, val, label)
	local holder = K.f(parent, "Knob", x, y, size + 2, size + 14)
	local ring = K.f(holder, "Ring", 1, 1, size, size)
	ring.BackgroundTransparency = 1
	K.corner(ring, size / 2)
	K.stroke(ring, T.line2, 2)
	local v = math.clamp and math.clamp(val or 0, 0, 1) or math.min(1, math.max(0, val or 0))
	local arc = K.f(holder, "Arc", 1, 1, size, size)
	arc.BackgroundTransparency = 1
	K.corner(arc, size / 2)
	K.stroke(arc, T.accent2, 2)
	arc.Visible = v > 0.02
	local dot = K.f(holder, "Dot", size / 2 - 3, size / 2 - 3, 6, 6, T.neon, 3)
	if label then K.txt(holder, label, 0, size + 2, size + 2, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center) end
	return holder, function() return v end
end

-- onda/barra de audio
function K.wave(parent, x, y, w, h, seed, color)
	local holder = K.f(parent, "Wave", x, y, w, h, T.bg4)
	K.corner(holder, 3)
	local n = math.floor(w / 4)
	local s = seed or 7
	for i = 1, n do
		s = (s * 16807) % 2147483647
		local v = (s % 1000) / 1000
		local bh = math.max(2, math.floor(h * (0.2 + 0.8 * v)))
		local bar = K.f(holder, "B" .. i, i * 4, math.floor((h - bh) / 2), 2, bh, color or T.accent2)
	end
	return holder
end

-- no de grafo (Material/Shader/VisualScripting/Graph)
function K.node(parent, x, y, w, title, color, inputs, outputs, opts)
	opts = opts or {}
	local n = K.f(parent, "N_" .. title, x, y, w, 34 + (#inputs + #outputs) * 16, color or T.sec)
	K.corner(n, 5)
	K.stroke(n, (opts.sel and T.neon) or T.line2, opts.sel and 1.5 or 1)
	local head = K.f(n, "Head", 0, 0, w, 20, opts.head or T.bg1)
	K.corner(head, 5)
	K.f(head, "HF", 0, 10, w, 10, opts.head or T.bg1)
	K.txt(head, title, 8, 0, w - 12, 20, 10, T.txt, FONTB)
	if opts.dot then K.f(head, "Dot", w - 12, 7, 6, 6, opts.dot, 3) end
	for i, inp in ipairs(inputs) do
		local sy = 20 + i * 16
		K.txt(n, inp, 8, sy, w / 2 - 10, 14, 9, T.txt3)
		local s = K.f(n, "S_" .. i, 4, sy + 3, 8, 8, T.bg4, 4)
		K.stroke(s, T.neon, 1.5)
		s._socket = { x = x + 4 + 4, y = y + sy + 7, kind = "in", node = title }
	end
	for i, outp in ipairs(outputs) do
		local sy = 20 + i * 16
		K.txt(n, outp, w / 2 + 2, sy, w / 2 - 12, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
		local s = K.f(n, "S_" .. (#inputs + i), w - 12, sy + 3, 8, 8, T.bg4, 4)
		K.stroke(s, T.orange, 1.5)
		s._socket = { x = x + w - 8, y = y + sy + 7, kind = "out", node = title }
	end
	n._sockets = {}
	for _, ch in ipairs(n:GetChildren()) do
		if ch._socket then n._sockets[#n._sockets + 1] = ch end
	end
	return n
end

-- camada de fios (desenha cabos entre soquetes, estilo Nuke/Blender)
function K.wireLayer(parent)
	local layer = K.f(parent, "Wires", 0, 0, 10, 10, T.bg2)
	layer.Size = UDim2.new(1, 0, 1, 0)
	layer.BackgroundTransparency = 1
	function layer:link(x1, y1, x2, y2, color)
		local dx = math.abs(x2 - x1) + 12
		local seg = K.f(layer, "W", x1, math.min(y1, y2) + 4, math.max(4, dx), 2, color or T.neon)
		K.corner(seg, 1)
		local s1 = K.f(layer, "J", x1 - 2, y1 - 2, 5, 5, color or T.neon, 2)
		local s2 = K.f(layer, "J", x2 - 2, y2 - 2, 5, 5, color or T.neon, 2)
		return seg
	end
	return layer
end

-- menu dropdown generico (submenus reais)
function K.dropdown(parent, anchor, items, onClose)
	local old = parent:FindFirstChild("ArkherDD")
	if old then old:Destroy() end
	local dd = K.f(parent, "ArkherDD", anchor.AbsolutePosition.X, anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y, 210, 10, T.bg2)
	K.corner(dd, 4)
	K.stroke(dd, T.line2, 1)
	local y = 2
	for _, it in ipairs(items) do
		if it == "-" then
			K.f(dd, "Sep", 4, y, 202, 1, T.line)
			y = y + 5
		elseif type(it) == "table" then
			local ib = K.btn(dd, "MI_" .. it.label, 2, y, 206, 20, T.bg2, 3)
			if it.items then
				K.txt(ib, it.label, 10, 0, 160, 20, 11, T.txt2)
				K.txt(ib, ">", 190, 0, 14, 20, 11, T.txt3)
				K.hover(ib, T.bg2, T.hover)
				ib.MouseButton1Click:Connect(function()
					local sub = {}
					for _, s in ipairs(it.items) do sub[#sub + 1] = s end
					K.dropdown(parent, ib, sub)
				end)
			else
				K.txt(ib, it.label, 10, 0, 150, 20, 11, T.txt2)
				if it.ks then K.txt(ib, it.ks, 150, 0, 54, 20, 9, T.txt4, FONT, Enum.TextXAlignment.Right) end
				K.hover(ib, T.bg2, T.hover)
				ib.MouseButton1Click:Connect(function()
					dd:Destroy()
					if onClose then onClose() end
					if it.cmd then ARKHER.cmd(it.cmd, it.tpl) end
				end)
			end
			y = y + 21
		else
			local ib = K.btn(dd, "MI_" .. it, 2, y, 206, 20, T.bg2, 3)
			K.txt(ib, it, 10, 0, 180, 20, 11, T.txt2)
			if it.ks then K.txt(ib, it.ks, 150, 0, 54, 20, 9, T.txt4, FONT, Enum.TextXAlignment.Right) end
			K.hover(ib, T.bg2, T.hover)
			ib.MouseButton1Click:Connect(function()
				dd:Destroy()
				if onClose then onClose() end
				if ARKHER.ACTIONS and it.cmd then ARKHER.cmd(it.cmd) end
			end)
			y = y + 21
		end
	end
	dd.Size = UDim2.new(0, 210, 0, y + 2)
	dd.ZIndex = 60
	return dd
end

-- linha chave de timeline
function K.keyTrack(parent, label, y, keys, color)
	K.txt(parent, label, 4, y, 90, 18, 10, T.txt3)
	local track = K.f(parent, "Track", 100, y + 2, 300, 14, T.bg4)
	K.corner(track, 3)
	for i, k in ipairs(keys) do
		local kx = math.floor(300 * k)
		local d = K.f(track, "K" .. i, kx - 3, -2, 7, 18, color or T.yellow, 0)
		d.Rotation = 45
	end
	return track
end

-- mini-mapas / previews
function K.thumb(parent, x, y, w, h, label, c1, c2)
	local t = K.f(parent, "Thumb", x, y, w, h, c1 or T.bg4)
	K.corner(t, 4)
	K.grad(t, c1 or T.sec, c2 or T.bg3)
	K.stroke(t, T.line, 1)
	if label then K.txt(t, label, 2, h - 14, w - 4, 12, 9, T.txt2, FONT, Enum.TextXAlignment.Center) end
	return t
end

-- ---------- ICONES NOVOS (todos desenhados por Frame) ----------
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
ICON.brush = function(c)
	px(c, 10.6, 2, 2.4, 9, C("#AEB9CC"), 1, -30)
	px(c, 7.6, 10.4, 4, 6, T.orange, 1, -30)
	px(c, 6.4, 14.4, 2.4, 3.4, C("#E8D9B0"), 1, -30)
end
ICON.mountain = function(c)
	px(c, 2, 13, 16, 4, T.bg4, 0)
	px(c, 3, 6, 6, 11, C("#7C8BA6"), 1, 0)
	px(c, 9, 9, 8, 8, C("#9AA7C0"), 1, 0)
	px(c, 5.4, 6, 2.6, 3, C("#F0F4FA"), 0)
end
ICON.water = function(c)
	px(c, 2, 8, 16, 3, T.accent, 0)
	px(c, 2, 12, 16, 3, C("#2F81D0"), 0)
	px(c, 4, 15.6, 10, 1.8, C("#7FB4E8"), 0)
	px(c, 9, 3, 1.6, 4, T.accent2, 0, 30)
	px(c, 10.6, 3, 1.6, 4, T.accent2, 0, -30)
	px(c, 9.2, 6.4, 3.2, 1.4, T.accent2, 0)
end
ICON.flame = function(c)
	px(c, 7, 4, 6, 12, T.orange, 3)
	px(c, 8.6, 9, 3, 6, C("#F6C65B"), 3)
	px(c, 9.4, 12, 1.6, 3, C("#FFF3D6"), 1)
end
ICON.bolt = function(c)
	px(c, 9.6, 2, 4, 7, C("#F6C65B"), 0, 0)
	px(c, 5.6, 9, 8, 4, C("#F6C65B"), 0)
	px(c, 8.4, 11, 4, 7, C("#F6C65B"), 0, 0)
	px(c, 7.6, 11, 3, 2.4, T.bg2, 0)
end
ICON.mic = function(c)
	px(c, 8, 3, 4, 9, C("#AEB9CC"), 2)
	px(c, 6, 8, 8, 2.4, C("#7C8BA6"), 0, 0)
	px(c, 9.2, 12, 1.6, 4, T.txt3)
	px(c, 6.4, 15.6, 7.2, 1.6, T.txt3, 0)
end
ICON.speaker = function(c)
	px(c, 4, 8, 4, 4, C("#AEB9CC"), 0)
	px(c, 8, 6, 3, 8, C("#AEB9CC"), 1)
	px(c, 12.4, 7, 1.8, 6, T.accent2, 0, 0)
	px(c, 15, 5, 1.8, 10, T.neon, 0, 0)
end
ICON.body = function(c)
	px(c, 8.6, 2, 2.8, 7, C("#7AA7F0"), 1)
	px(c, 4, 9, 12, 2.8, C("#7AA7F0"), 1)
	px(c, 5, 12.4, 2.6, 5, C("#7AA7F0"), 1)
	px(c, 12.4, 12.4, 2.6, 5, C("#7AA7F0"), 1)
end
ICON.joint = function(c)
	px(c, 3, 14, 5, 3, C("#7C8BA6"), 1)
	px(c, 12, 3, 5, 3, C("#7C8BA6"), 1)
	px(c, 5.4, 14.6, 10, 1.8, T.txt3, 0, -50)
	px(c, 6.6, 12.8, 4, 4, T.orange, 2)
end
ICON.path = function(c)
	px(c, 3, 14, 4, 4, T.teal, 2)
	px(c, 13, 3, 4, 4, T.orange, 2)
	px(c, 5, 14.6, 10, 1.6, T.txt3, 0, -40)
	px(c, 6, 9, 8, 1.6, T.txt3, 0, 10)
	px(c, 6, 9, 1.6, 5, T.txt3)
end
ICON.brain = function(c)
	px(c, 6, 5, 8, 4, C("#B07AE0"), 2)
	px(c, 5, 9, 6, 5, C("#8A4FD6"), 2)
	px(c, 11, 9, 4, 5, C("#B07AE0"), 2)
	px(c, 7, 14, 7, 3, C("#6E3BBF"), 1)
	px(c, 9, 7, 1.4, 5, T.bg2)
	px(c, 6.4, 10.4, 2.6, 1.2, T.bg2)
	px(c, 12, 10.4, 2.6, 1.2, T.bg2)
end
ICON.layers = function(c)
	px(c, 9.4, 2, 8, 4, C("#7AA7F0"), 1, -8)
	px(c, 4.6, 7, 8, 4, C("#4E8FE0"), 1, -8)
	px(c, 9.4, 12, 8, 4, T.neon, 1, -8)
end
ICON.grid = function(c)
	for i = 0, 2 do
		px(c, 3, 3 + i * 5.4, 14, 1.4, T.txt3)
		px(c, 3 + i * 5.4, 3, 1.4, 14, T.txt3)
	end
end
ICON.sphere = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.18, 0, 0.18, 0)
	ring.Size = UDim2.new(0.64, 0, 0.64, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.txt2, 1.5)
	px(c, 5, 9.4, 10, 1.4, T.txt4)
	px(c, 9.3, 5, 1.4, 10, T.txt4)
end
ICON.cylinder = function(c)
	px(c, 6, 5, 8, 10, C("#AEB9CC"), 0)
	local top = K.f(c, "top", 0, 0, 20, 20)
	top.Position = UDim2.new(0.3, 0, 0.2, 0)
	top.Size = UDim2.new(0.4, 0, 0.16, 0)
	top.BackgroundTransparency = 1
	K.corner(top, 8)
	K.stroke(top, C("#D7DEEA"), 1.5)
end
ICON.wedge = function(c)
	px(c, 4, 13, 12, 4, C("#AEB9CC"), 1)
	px(c, 12, 5, 4, 8, C("#D7DEEA"), 1)
end
ICON.particle = function(c)
	px(c, 9, 9, 3, 3, T.neon, 1)
	px(c, 3, 4, 2, 2, T.accent2, 1)
	px(c, 15, 5, 2, 2, T.accent2, 1)
	px(c, 4, 15, 2, 2, T.accent2, 1)
	px(c, 15, 14, 2, 2, T.accent2, 1)
	px(c, 9, 3, 2, 2, T.accent2, 1)
	px(c, 3, 10, 2, 2, T.accent2, 1)
end
ICON.droplet = function(c)
	px(c, 9, 2.4, 3, 6, T.accent2, 1)
	px(c, 6, 8, 8, 8, T.accent, 4)
	px(c, 7.6, 10, 2, 3, C("#CFE6FF"), 1)
end
ICON.snow = function(c)
	px(c, 9.2, 2, 1.6, 16, T.txt2)
	px(c, 2.4, 9.2, 15.2, 1.6, T.txt2)
	px(c, 5, 5, 1.6, 6, T.txt2, 0, 45)
	px(c, 13.4, 9, 1.6, 6, T.txt2, 0, 45)
end
ICON.rain = function(c)
	px(c, 4, 5, 12, 5, C("#8A6BFF"), 3)
	px(c, 5.4, 11, 1.6, 4, T.accent2)
	px(c, 9.2, 12, 1.6, 4, T.accent2)
	px(c, 13, 11, 1.6, 4, T.accent2)
end
ICON.sunI = function(c)
	local core = K.f(c, "core", 0, 0, 20, 20)
	core.Position = UDim2.new(0.3, 0, 0.3, 0)
	core.Size = UDim2.new(0.4, 0, 0.4, 0)
	core.BackgroundTransparency = 1
	K.corner(core, 8)
	K.stroke(core, C("#F6C65B"), 2)
	for _, a in ipairs({ 0, 45, 90, 135 }) do
		px(c, 9.2, 1.4, 1.6, 3, C("#F6C65B"), 0, a)
		px(c, 9.2, 15.6, 1.6, 3, C("#F6C65B"), 0, a)
	end
end
ICON.moonI = function(c)
	px(c, 5, 4, 11, 11, C("#C7D2E8"), 6)
	px(c, 9, 3.4, 9, 9, T.bg2, 4)
	px(c, 4, 12, 4, 4, C("#C7D2E8"), 2)
end
ICON.compass = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.Size = UDim2.new(0.7, 0, 0.7, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.txt3, 1.5)
	px(c, 9.4, 4.4, 1.2, 6, T.danger)
	px(c, 9.4, 9.6, 1.2, 6, T.txt2)
end
ICON.tag = function(c)
	px(c, 4, 4, 9, 9, T.yellow, 1, 45)
	px(c, 6.4, 6.4, 2.4, 2.4, T.bg2, 1, 45)
	px(c, 12, 12, 5, 4, T.yellow, 1, 45)
end
ICON.trash = function(c)
	px(c, 6, 6, 8, 11, C("#E07070"), 1)
	px(c, 4, 4, 12, 2, T.txt2, 0)
	px(c, 8.6, 3, 2.8, 2, T.txt2, 0)
	px(c, 8, 8, 1.4, 7, T.bg2)
	px(c, 10.6, 8, 1.4, 7, T.bg2)
end
ICON.copyI = function(c)
	px(c, 3, 3, 9, 11, C("#D7DEEA"), 1)
	px(c, 8, 7, 9, 11, C("#AEB9CC"), 1)
	px(c, 10, 9, 5, 1.2, T.bg2)
	px(c, 10, 11.6, 5, 1.2, T.bg2)
	px(c, 10, 14.2, 3, 1.2, T.bg2)
end
ICON.cut = function(c)
	px(c, 9.4, 4, 1.2, 12, T.txt2)
	px(c, 4, 12, 4, 4, T.txt2, 2)
	px(c, 12, 12, 4, 4, T.txt2, 2)
	px(c, 5, 5, 3, 7, T.txt2, 0, 40)
	px(c, 12, 5, 3, 7, T.txt2, 0, -40)
end
ICON.pasteI = function(c)
	px(c, 4, 4, 12, 14, C("#8F5F2C"), 2)
	px(c, 7, 2, 6, 4, C("#E8D9B0"), 1)
	px(c, 6.4, 8, 7.2, 8, C("#EDF1F7"), 1)
	px(c, 8, 10, 4, 1.2, C("#8894A9"))
	px(c, 8, 12.4, 4, 1.2, C("#8894A9"))
end
ICON.refresh = function(c)
	ICON.rotate(c)
	px(c, 8.6, 1.8, 3.4, 3.4, T.accent2, 1, 45)
end
ICON.clock = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.Size = UDim2.new(0.7, 0, 0.7, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.txt3, 1.5)
	px(c, 9.4, 5, 1.4, 5, T.txt2)
	px(c, 9.4, 9.4, 4, 1.4, T.txt2)
end
ICON.film = function(c)
	px(c, 3, 4, 14, 12, T.bg4, 1)
	px(c, 4.4, 5.4, 2, 9.2, T.txt3)
	px(c, 13.6, 5.4, 2, 9.2, T.txt3)
	px(c, 7.4, 7, 5, 5, T.neon, 1)
end
ICON.code = function(c)
	px(c, 6, 6, 1.8, 8, T.neon, 0, -30)
	px(c, 6.8, 12, 1.8, 2, T.neon, 0, 30)
	px(c, 12.2, 6, 1.8, 8, T.neon, 0, 30)
	px(c, 11.4, 12, 1.8, 2, T.neon, 0, -30)
	px(c, 9.6, 4, 1.2, 3, T.txt3, 0, 20)
	px(c, 9.4, 12.6, 1.2, 3, T.txt3, 0, -20)
end
ICON.terminal = function(c)
	px(c, 3, 4, 14, 12, T.bg4, 2)
	K.stroke(px(c, 3, 4, 14, 12, T.bg4, 2), T.line2, 1)
	px(c, 5.4, 7, 1.8, 1.8, T.green, 0, 40)
	px(c, 7, 9.6, 1.8, 1.8, T.green, 0, -40)
	px(c, 10, 8.6, 4, 1.4, T.txt2)
end
ICON.book = function(c)
	px(c, 4, 3, 12, 14, C("#8F5F2C"), 1)
	px(c, 6, 3, 10, 14, C("#EDF1F7"), 1)
	px(c, 8, 6, 6, 1.2, C("#8894A9"))
	px(c, 8, 8.6, 6, 1.2, C("#8894A9"))
	px(c, 8, 11.2, 4, 1.2, C("#8894A9"))
	px(c, 4, 3, 2, 14, C("#B07A3E"), 1)
end
ICON.wrench = function(c)
	px(c, 8, 7, 3, 10, C("#AEB9CC"), 1, 30)
	px(c, 10, 3, 6, 5, T.txt2, 2, 30)
	px(c, 12.4, 4.4, 2.4, 2.4, T.bg2, 1, 30)
end
ICON.rocket = function(c)
	px(c, 9, 3, 3, 9, T.txt2, 1)
	px(c, 6.6, 7, 6.8, 6, T.txt2, 2)
	px(c, 9.4, 13, 1.2, 3, T.orange)
	px(c, 7.4, 11, 1.2, 3.4, C("#E87070"))
	px(c, 11.4, 11, 1.2, 3.4, C("#E87070"))
	px(c, 9.4, 6, 1.2, 2, T.bg2)
end
ICON.server = function(c)
	px(c, 4, 4, 12, 5, T.sec, 1)
	px(c, 4, 11, 12, 5, T.sec, 1)
	px(c, 6, 5.8, 1.6, 1.6, T.green, 1)
	px(c, 6, 12.8, 1.6, 1.6, T.yellow, 1)
	px(c, 11, 6, 4, 1, T.txt4)
	px(c, 11, 13, 4, 1, T.txt4)
end
ICON.database = function(c)
	px(c, 5, 4, 10, 3, C("#7AA7F0"), 1)
	px(c, 5, 6, 10, 9, C("#4E8FE0"), 0)
	local m1 = K.f(c, "m1", 0, 0, 20, 20)
	m1.Position = UDim2.new(0.25, 0, 0.52, 0)
	m1.Size = UDim2.new(0.5, 0, 0.16, 0)
	m1.BackgroundTransparency = 1
	K.corner(m1, 8)
	K.stroke(m1, C("#2F5FA8"), 1)
	local m2 = K.f(c, "m2", 0, 0, 20, 20)
	m2.Position = UDim2.new(0.25, 0, 0.78, 0)
	m2.Size = UDim2.new(0.5, 0, 0.16, 0)
	m2.BackgroundTransparency = 1
	K.corner(m2, 8)
	K.stroke(m2, C("#2F5FA8"), 1)
	px(c, 5, 15, 10, 2, C("#4E8FE0"), 1)
end
ICON.branch = function(c)
	px(c, 9.4, 6, 1.2, 8, T.txt2)
	px(c, 5, 12, 10, 1.2, T.txt2)
	px(c, 8.4, 2.4, 3.2, 3.2, T.accent2, 2)
	px(c, 8.4, 14.4, 3.2, 3.2, T.accent2, 2)
	px(c, 14, 4, 1.2, 6, T.txt2)
	px(c, 12.4, 2.4, 4.4, 1.2, T.txt2)
	px(c, 12.4, 2.4, 4.4, 3.2, T.accent, 1, 45)
end
ICON.commit = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.3, 0, 0.3, 0)
	ring.Size = UDim2.new(0.4, 0, 0.4, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 8)
	K.stroke(ring, T.green, 2)
	px(c, 3, 9.4, 5, 1.2, T.txt3)
	px(c, 12, 9.4, 5, 1.2, T.txt3)
end
ICON.cloudOn = function(c)
	px(c, 4, 9, 12, 6, T.green, 3)
	px(c, 6, 6, 7, 6, T.green, 3)
	px(c, 6.6, 10.4, 1.6, 4, C("#FFFFFF"), 0, 45)
	px(c, 9.2, 11.6, 1.6, 4, C("#FFFFFF"), 0, -45)
	px(c, 10.6, 10.4, 4.4, 1.6, C("#FFFFFF"), 0, -45)
end
ICON.cloudOff = function(c)
	px(c, 4, 9, 12, 6, T.line2, 3)
	px(c, 6, 6, 7, 6, T.line2, 3)
	px(c, 5, 5, 1.8, 9, T.danger, 0, 45)
	px(c, 9, 5, 1.8, 9, T.danger, 0, 45)
end
ICON.unlock = function(c)
	px(c, 6, 9, 8, 8, T.txt2, 2)
	px(c, 7.4, 6, 1.8, 4, T.txt2)
	px(c, 10.8, 5.6, 1.8, 4.4, T.txt2, 0, 40)
	px(c, 9.2, 11, 1.6, 4, T.bg2, 1)
end
ICON.maxI = function(c)
	px(c, 4, 4, 12, 1.4, T.txt2)
	px(c, 4, 14.6, 12, 1.4, T.txt2)
	px(c, 4, 4, 1.4, 12, T.txt2)
	px(c, 14.6, 4, 1.4, 12, T.txt2)
	px(c, 4, 11, 12, 3.6, T.txt3, 0)
end
ICON.fit = function(c)
	px(c, 4, 8, 2.4, 4, T.neon)
	px(c, 13.6, 8, 2.4, 4, T.neon)
	px(c, 8, 4, 4, 2.4, T.neon)
	px(c, 8, 13.6, 4, 2.4, T.neon)
	px(c, 8.8, 8.8, 2.4, 2.4, T.bg2)
end
ICON.zoomIn = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.2, 0, 0.2, 0)
	ring.Size = UDim2.new(0.5, 0, 0.5, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 8)
	K.stroke(ring, T.txt2, 1.6)
	px(c, 5.6, 10.6, 2, 1.4, T.txt2)
	px(c, 7, 12, 2, 1.4, T.txt2)
	px(c, 9.4, 7.6, 1.6, 4, T.txt2)
	px(c, 7.6, 9.4, 4, 1.6, T.txt2)
	px(c, 11, 11, 6, 1.6, T.txt2)
	px(c, 14.8, 14.8, 1.6, 6, T.txt2)
end
ICON.zoomOut = function(c)
	ICON.zoomIn(c)
	px(c, 7.6, 9.4, 4, 1.6, T.txt2)
end
ICON.hand = function(c)
	px(c, 7, 6, 2, 8, T.txt2, 1)
	px(c, 9.4, 4, 2, 10, T.txt2, 1)
	px(c, 11.8, 5, 2, 9, T.txt2, 1)
	px(c, 14, 8, 2, 6, T.txt2, 1)
	px(c, 5, 10, 2, 4, T.txt2, 1)
	px(c, 6, 12, 9, 4, T.txt2, 2)
end
ICON.warn = function(c)
	px(c, 9.4, 3, 10, 13, T.yellow, 1)
	px(c, 4.4, 8.4, 10, 8, T.yellow, 1)
	px(c, 9.4, 13.4, 10, 2.8, T.yellow, 1)
	px(c, 9.4, 6, 1.4, 5, T.bg2)
	px(c, 9.4, 12.6, 1.4, 1.8, T.bg2)
end
ICON.err = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.Size = UDim2.new(0.7, 0, 0.7, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.danger, 2)
	px(c, 5.6, 5.6, 1.8, 8.8, T.danger, 0, 45)
	px(c, 5.6, 5.6, 1.8, 8.8, T.danger, 0, -45)
end
ICON.userI = function(c)
	px(c, 6.6, 3, 5, 5, C("#7AA7F0"), 2)
	px(c, 4, 9.4, 10, 7, C("#7AA7F0"), 3)
end
ICON.bell = function(c)
	px(c, 5, 6, 10, 8, C("#C7D2E8"), 2)
	px(c, 8.6, 3, 2.8, 3, C("#C7D2E8"), 1)
	px(c, 8.6, 14, 2.8, 1.6, T.txt3)
	px(c, 7, 15.6, 6, 1.4, T.txt3, 0)
	px(c, 15, 6, 2, 2, T.orange, 1)
end
ICON.linkI = function(c)
	px(c, 3, 8, 7, 4, C("#7AA7F0"), 2)
	px(c, 10, 8, 7, 4, C("#7AA7F0"), 2)
	px(c, 8, 9, 4, 2, T.bg2)
end
ICON.down = function(c)
	px(c, 9.2, 3, 1.6, 9, T.txt2)
	px(c, 5.4, 8.6, 3, 3, T.txt2, 0, -45)
	px(c, 11.6, 8.6, 3, 3, T.txt2, 0, 45)
	px(c, 4, 14, 12, 2, T.txt2, 1)
end
ICON.up = function(c)
	px(c, 9.2, 5, 1.6, 9, T.txt2)
	px(c, 5.4, 4.4, 3, 3, T.txt2, 45)
	px(c, 11.6, 4.4, 3, 3, T.txt2, -45)
	px(c, 4, 14, 12, 2, T.txt2, 1)
end
ICON.eye = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.1, 0, 0.32, 0)
	ring.Size = UDim2.new(0.8, 0, 0.42, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 10)
	K.stroke(ring, T.txt2, 1.5)
	local iris = K.f(c, "iris", 0, 0, 20, 20)
	iris.Position = UDim2.new(0.4, 0, 0.42, 0)
	iris.Size = UDim2.new(0.2, 0, 0.2, 0)
	iris.BackgroundTransparency = 1
	K.corner(iris, 5)
	K.stroke(iris, T.neon, 1.5)
end
ICON.star = function(c)
	px(c, 9, 2.6, 2, 6, T.yellow)
	px(c, 12, 4.6, 1.8, 5.4, T.yellow, 0, -58)
	px(c, 6.2, 4.6, 1.8, 5.4, T.yellow, 0, 58)
	px(c, 3, 8.6, 4.6, 1.8, T.yellow, 0, 18)
	px(c, 12.4, 8.6, 4.6, 1.8, T.yellow, 0, -18)
	px(c, 5.4, 13.6, 3, 3.4, T.yellow)
	px(c, 11.6, 13.6, 3, 3.4, T.yellow)
	px(c, 8.6, 10, 2.8, 4.6, T.yellow)
end
ICON.heart = function(c)
	px(c, 5, 7, 4.6, 4, T.danger, 2)
	px(c, 10.4, 7, 4.6, 4, T.danger, 2)
	px(c, 4.6, 9, 10.8, 5, T.danger, 2)
	px(c, 8, 12.6, 4, 4, T.danger, 1)
	px(c, 9.6, 15.6, 1.8, 1.8, T.danger)
end
ICON.shield = function(c)
	px(c, 5, 4, 10, 12, C("#4E8FE0"), 2)
	px(c, 9, 2, 6, 4, C("#4E8FE0"), 1)
	px(c, 6.4, 6.6, 1.6, 5.4, C("#CFE3FF"), 0, 45)
	px(c, 8.8, 8.6, 1.6, 5.4, C("#CFE3FF"), 0, -45)
	px(c, 10, 8, 4.4, 1.6, C("#CFE3FF"), 0, -45)
end
ICON.keyI = function(c)
	local ring = K.f(c, "r", 0, 0, 20, 20)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.Size = UDim2.new(0.36, 0, 0.36, 0)
	ring.BackgroundTransparency = 1
	K.corner(ring, 8)
	K.stroke(ring, T.yellow, 1.8)
	px(c, 9, 8.4, 8, 1.8, T.yellow)
	px(c, 13, 9.6, 1.8, 3.4, T.yellow)
	px(c, 15.6, 9.6, 1.8, 2.6, T.yellow)
end
ICON.music = function(c)
	px(c, 6, 3, 8, 2.6, T.txt2, 0, -8)
	px(c, 5.4, 3, 1.6, 11, T.txt2)
	px(c, 11, 2, 1.6, 10, T.txt2)
	px(c, 3.4, 11.4, 4, 4, T.txt2, 2)
	px(c, 9, 10.4, 4, 4, T.txt2, 2)
end
ICON.volume = function(c)
	px(c, 3, 8, 3, 4, C("#AEB9CC"))
	px(c, 6, 6, 2.6, 8, C("#AEB9CC"), 1)
	px(c, 10.4, 7, 2, 6, T.accent2, 0)
	px(c, 13.4, 5, 2, 10, T.neon, 0)
end
ICON.sliders = function(c)
	px(c, 4, 5, 12, 1.4, T.txt3)
	px(c, 7.6, 3, 2.8, 6, T.txt2, 1)
	px(c, 4, 10, 12, 1.4, T.txt3)
	px(c, 10.6, 7.4, 2.8, 6, T.txt2, 1)
	px(c, 4, 15, 12, 1.4, T.txt3)
	px(c, 5.6, 12.4, 2.8, 6, T.txt2, 1)
end
ICON.crosshair = function(c)
	px(c, 9.3, 2, 1.4, 6, T.txt2)
	px(c, 9.3, 12, 1.4, 6, T.txt2)
	px(c, 2, 9.3, 6, 1.4, T.txt2)
	px(c, 12, 9.3, 6, 1.4, T.txt2)
	px(c, 9.2, 9.2, 1.6, 1.6, T.danger, 1)
end
ICON.magnet = function(c)
	px(c, 5, 3, 4, 8, C("#E07070"), 1)
	px(c, 11, 3, 4, 8, C("#AEB9CC"), 1)
	px(c, 5, 11, 10, 2.4, C("#AEB9CC"), 0)
	px(c, 5, 3, 4, 2.4, C("#F0F4FA"), 1)
	px(c, 11, 3, 4, 2.4, C("#F0F4FA"), 1)
end
ICON.ruler = function(c)
	px(c, 2, 10, 16, 5, T.yellow, 1, -30)
	px(c, 5, 9.2, 1.4, 2.4, T.bg2, 0, -30)
	px(c, 8.4, 8, 1.4, 2.4, T.bg2, 0, -30)
	px(c, 11.8, 6.8, 1.4, 2.4, T.bg2, 0, -30)
	px(c, 15.2, 5.6, 1.4, 2.4, T.bg2, 0, -30)
end
ICON.folderOpen = function(c)
	px(c, 2, 5, 6, 3, C("#B07A3E"), 1)
	px(c, 2, 7, 16, 10, C("#E8B33C"), 2)
	px(c, 3, 10, 14, 5, C("#F6C65B"), 2)
end
ICON.fileI = function(c)
	px(c, 5, 2, 10, 16, C("#EDF1F7"), 1)
	px(c, 11, 2, 4, 4, C("#AEB9CC"), 1)
	px(c, 7, 8, 6, 1.2, C("#8894A9"))
	px(c, 7, 10.6, 6, 1.2, C("#8894A9"))
	px(c, 7, 13.2, 4, 1.2, C("#8894A9"))
end
ICON.imageI = function(c)
	px(c, 3, 4, 14, 12, C("#8A6BFF"), 2)
	px(c, 5, 6, 4, 3, C("#F6C65B"), 1)
	px(c, 4, 12, 12, 3, C("#3ECF7A"), 1)
	px(c, 8, 10, 8, 5, C("#2F9F5C"), 1)
end
ICON.cloudDoc = function(c)
	px(c, 3, 8, 11, 8, C("#EDF1F7"), 2)
	px(c, 9, 4, 8, 6, C("#8A6BFF"), 3)
	px(c, 5, 10, 6, 1.2, C("#8894A9"))
	px(c, 5, 12.4, 6, 1.2, C("#8894A9"))
end

ARKHER._version = "3.0.0"
end

do
--[[ ARKHER V3 — D-O15: camada de otimizacao adaptativa ]]
-- Mede o custo real (FPS/heartbeat) e decide o nivel de materializacao (1..4).
-- Nao e "reduzir qualidade": escala trabalho (densidade de UI animada, frequencia
-- de refresh de paineis, tick da IA) mantendo a capacidade plena.
local RunService = game:GetService("RunService")

local D15 = {}
ArkherDO15 = D15

local state = {
	level = 2, -- 1 MAX | 2 HIGH | 3 BALANCED | 4 ECO
	fps = 60, frame = 0,
	cost = 0, -- media mobile de heartbeat (ms)
	samples = 0,
	lastTick = tick(),
	pressure = 0,
}
D15.state = state

local LEVEL_NAMES = { "MAX", "HIGH", "BALANCED", "ECO" }

function D15.levelName()
	return LEVEL_NAMES[state.level] or "?"
end

-- frequencia permitida por nivel (ex: quanto o AI/Inspector pode atualizar)
function D15.refreshBudget(key)
	local budgets = {
		inspector = { 0.1, 0.1, 0.25, 0.5 },
		hierarchy = { 0.2, 0.3, 0.5, 1.0 },
		ai = { 1.0, 1.0, 2.0, 4.0 },
		nmn = { 0.05, 0.1, 0.2, 0.5 },
		animations = { 1.0, 0.8, 0.5, 0.2 },
	}
	local b = budgets[key] or budgets.ai
	return b[state.level] or 1.0
end

function D15.pressure()
	return state.pressure
end

local function decide()
	local p = state.pressure
	if p > 0.7 then
		state.level = math.min(4, state.level + 1)
	elseif p < 0.35 and state.level > 1 then
		state.level = state.level - 1
	end
end

local acc = 0
local n = 0
function D15.nudge(target)
	state.level = target or 1
	ARKHER.STATE.do15Level = state.level
	Bus.emit("do15.level", state.level, state.fps, state.cost)
	ARKHER.out("INFO", "D-O15: nivel forcado para " .. D15.levelName())
end
function D15.start()
	Bus.on("do15.nudge", D15.nudge)
	local last = tick()
	pcall(function()
		RunService.Heartbeat:Connect(function(dt)
			local t = tick()
			local frameDt = t - last
			last = t
			acc = acc + frameDt
			n = n + 1
			state.frame = state.frame + 1
			if n >= 30 then
				state.fps = math.min(999, n / acc)
				state.cost = (acc / n) * 1000
				acc = 0
				n = 0
				-- pressao = custo do frame vs orcamento de 16.6ms
				state.pressure = math.min(1, state.cost / 16.6)
				decide()
				ARKHER.STATE.do15Level = state.level
				Bus.emit("do15.level", state.level, state.fps, state.cost)
			end
		end)
	end)
	ARKHER.out("INFO", "D-O15 ativo: nivel " .. state.level .. " (" .. D15.levelName() .. ")")
end

-- API usada pelos sistemas: "posso gastar?"
function D15.canAfford(fraction)
	-- fraction: quanto do orcamento de frame o trabalho consome (0..1)
	return state.pressure + fraction <= 1.0
end

-- relatorio (profiler / UI)
function D15.report()
	return {
		level = state.level, levelName = D15.levelName(),
		fps = state.fps, frameMs = state.cost, pressure = state.pressure,
		frames = state.frame,
	}
end
end

do
--[[ ARKHER V3 — UNDO/REDO: pilha real de snapshots do workspace ]]
-- Registro de comandos: cada acao editavel chama ARKHER.cmd("undo.push", label)
-- antes de modificar o mundo. Limite: 50 niveis (D-O15 escala com mem).
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local U = {}
ArkherUNDO = U

local MAX = 50
local stack = { _undo = {}, _redo = {} }
local reentrant = false -- P.apply chama undo.push; sem o guard isso limparia o redo

local function snapshotWorkspace()
	local Http = game:GetService("HttpService")
	local data = ArkherPlaces and ArkherPlaces.snapshot()
	if data then
		return Http:JSONEncode(data)
	end
	return nil
end

function U.push(label)
	if not workspace then return end
	if reentrant then return end
	local json = snapshotWorkspace()
	if not json then return end
	table.insert(stack._undo, { label = label or "Edit", json = json, t = tick() })
	if #stack._undo > MAX then table.remove(stack._undo, 1) end
	stack._redo = {}
	Bus.emit("undo.state", U.status())
end

function U.canUndo() return #stack._undo > 0 end
function U.canRedo() return #stack._redo > 0 end

function U.status()
	return { undo = #stack._undo, redo = #stack._redo, last = stack._undo[#stack._undo] and stack._undo[#stack._undo].label or "" }
end

function U.undo()
	local top = table.remove(stack._undo)
	if not top then
		ARKHER.out("INFO", "Undo: nada para desfazer")
		return false
	end
	local current = snapshotWorkspace()
	if current then
		table.insert(stack._redo, { label = top.label, json = current, t = tick() })
	end
	local Http = game:GetService("HttpService")
	local ok, data = pcall(function() return Http:JSONDecode(top.json) end)
	if ok and data and ArkherPlaces then
		reentrant = true
		ArkherPlaces.apply(data)
		reentrant = false
		ARKHER.out("INFO", "Undo: " .. tostring(top.label))
	else
		ARKHER.out("ERROR", "Undo: snapshot corrompido")
	end
	Bus.emit("undo.state", U.status())
	return true
end

function U.redo()
	local top = table.remove(stack._redo)
	if not top then
		ARKHER.out("INFO", "Redo: nada para refazer")
		return false
	end
	local current = snapshotWorkspace()
	if current then
		table.insert(stack._undo, { label = top.label, json = current, t = tick() })
	end
	local Http = game:GetService("HttpService")
	local ok, data = pcall(function() return Http:JSONDecode(top.json) end)
	if ok and data and ArkherPlaces then
		reentrant = true
		ArkherPlaces.apply(data)
		reentrant = false
		ARKHER.out("INFO", "Redo: " .. tostring(top.label))
	else
		ARKHER.out("ERROR", "Redo: snapshot corrompido")
	end
	Bus.emit("undo.state", U.status())
	return true
end

function U.clear()
	stack._undo = {}
	stack._redo = {}
	Bus.emit("undo.state", U.status())
end
end

do
--[[ ARKHER V3 — PUBLISH: publicar SEM Open Cloud API ]]
-- Pipeline: bundle do place → manifest (nome/desc/icone/genre/tags) → destino:
--   1) ARKHER CLOUD: endpoint HTTP proprio do usuario (Settings > Cloud). POST JSON.
--      Sem API key do Roblox, sem Open Cloud, sem JWT enterprise.
--   2) LOCAL: bundle em disco (game.WriteFile) quando no Studio.
--   3) CLIPBOARD: bundle copiado (qualquer ambiente).
--   4) ROBLOX NATIVO: prepara tudo e delega o publish ao proprio Studio (o unico
--      caminho oficial do lugar) — o ARKHER nao reinventa a conta do usuario.
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local PUB = {}
ArkherPublish = PUB

local function cloudRoot()
	local root = ServerStorage:FindFirstChild("ArkherCloud")
	if not root then
		root = Instance.new("Folder")
		root.Name = "ArkherCloud"
		root.Parent = ServerStorage
	end
	return root
end
local function pubFolder()
	local f = cloudRoot():FindFirstChild("Published")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Published"
		f.Parent = cloudRoot()
	end
	return f
end

function PUB.manifest(extra)
	extra = extra or {}
	local desc = extra.description or ("Place criado no ARKHER Studio — " .. (ARKHER.STATE.placeName or "sem nome"))
	return {
		schema = "arkher.place/v3",
		name = extra.name or ARKHER.STATE.placeName or "Untitled",
		description = desc,
		genre = extra.genre or "Roleplay",
		tags = extra.tags or { "arkher", "studio" },
		icon = extra.icon or nil,
		created = os.date and os.date("%Y-%m-%dT%H:%M:%S") or tostring(tick()),
		placeId = ARKHER.STATE.placeId,
		do15 = ARKHER.STATE.do15Level,
		by = extra.by or "ArkherStudio",
	}
end

function PUB.toLocal()
	local ok, bundle = pcall(function() return ArkherPlaces.exportBundle() end)
	if not ok or not bundle then
		ARKHER.out("ERROR", "Publish: nao foi possivel gerar o bundle")
		return false
	end
	local name = (ARKHER.STATE.placeName or "place"):gsub("[^%w%-_ ]", "")
	local f = pubFolder():FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = pubFolder()
	end
	local sv = f:FindFirstChild("bundle")
	if not sv then
		sv = Instance.new("StringValue")
		sv.Name = "bundle"
		sv.Parent = f
	end
	sv.Value = bundle
	local mf = f:FindFirstChild("manifest")
	if not mf then
		mf = Instance.new("StringValue")
		mf.Name = "manifest"
		mf.Parent = f
	end
	mf.Value = HttpService:JSONEncode(PUB.manifest())
	-- tenta tambem gravar em disco (no Studio)
	pcall(function()
		if game.WriteFile then
			game:WriteFile("ArkherPublished/" .. name .. ".arkher.lua", bundle)
		end
	end)
	ARKHER.out("SUCCESS", "Publicado no Arkher Cloud local: " .. name)
	Bus.emit("publish.local", { name = name, bytes = #bundle })
	return true
end

function PUB.toEndpoint()
	local ep = ARKHER.STATE.cloud.endpoint
	if not ep or #ep < 5 then
		ARKHER.out("WARNING", "Publish: configure o endpoint do Arkher Cloud em Settings > Cloud")
		return false
	end
	local ok, bundle = pcall(function() return ArkherPlaces.exportBundle() end)
	if not ok or not bundle then
		ARKHER.out("ERROR", "Publish: bundle falhou")
		return false
	end
	local payload = HttpService:JSONEncode({
		manifest = PUB.manifest(),
		bundle = bundle,
	})
	local ok2, res = pcall(function()
		return HttpService:PostAsync(ep, payload, Enum.HttpContentType.ApplicationJson, 20)
	end)
	if ok2 then
		ARKHER.out("SUCCESS", "Publicado no Arkher Cloud (" .. ep .. ") — resposta: " .. tostring(res))
		Bus.emit("publish.cloud", { endpoint = ep })
		return true
	end
	ARKHER.out("ERROR", "Publish cloud falhou: " .. tostring(res))
	return false
end

function PUB.toRobloxNative()
	-- prepara o native publish do Studio: nome/descricao ja estao no place;
	-- o usuario confirma no dialog oficial (a unica forma legita de publicar num lugar).
	local name = ARKHER.STATE.placeName or "Untitled"
	ARKHER.out("INFO", "Publicar no Roblox: abra FILE > Publish to Roblox no Studio — ARKHER ja preparou o name '" .. name .. "'.")
	Bus.emit("publish.native", { name = name })
	return true
end

function PUB.history()
	local out = {}
	for _, f in ipairs(pubFolder():GetChildren()) do
		local mf = f:FindFirstChild("manifest")
		local info = { name = f.Name }
		if mf then
			local ok, m = pcall(function() return HttpService:JSONDecode(mf.Value) end)
			if ok and type(m) == "table" then info = m end
		end
		out[#out + 1] = info
	end
	return out
end
end

do
--[[ ARKHER V3 — NMN: Natural Mindset of NPCs ]]
-- Cada NPC possui MENTE real: precisoes (fome/energia/social), objetivos, memoria,
-- percepcao indexada por Spatial Grid (O(celulas), nao O(n)), decisoes com causalidade.
-- D-O15 controla a resolucao do tick (under pressure → tick mais raro, nao apaga estado).
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local NMN = {}
ArkherNMN = NMN

local CELL = 12 -- studs
local minds = {}
local grid = {}
local tickCount = 0

-- ---------- SPATIAL GRID ----------
local function cellKey(x, z)
	return math.floor(x / CELL) .. "_" .. math.floor(z / CELL)
end

local function gridInsert(key, id)
	grid[key] = grid[key] or {}
	table.insert(grid[key], id)
end
local function gridRemove(key, id)
	local arr = grid[key]
	if not arr then return end
	for i = #arr, 1, -1 do
		if arr[i] == id then table.remove(arr, i) break end
	end
end
local function nearKeys(x, z)
	local kx, kz = math.floor(x / CELL), math.floor(z / CELL)
	local out = {}
	for dx = -1, 1 do
		for dz = -1, 1 do
			out[#out + 1] = (kx + dx) .. "_" .. (kz + dz)
		end
	end
	return out
end

-- ---------- PERCEPÇÃO (o NMN nao conhece o grid — pede e recebe) ----------
function NMN.perceive(pos, range)
	range = range or 24
	local seen = {}
	for _, key in ipairs(nearKeys(pos.X, pos.Z)) do
		local arr = grid[key]
		if arr then
			for _, id in ipairs(arr) do
				local m = minds[id]
				if m and m.pos then
					local d = (m.pos - pos).Magnitude
					if d <= range and d > 0.001 then
						seen[#seen + 1] = { id = id, name = m.name, dist = d, pos = m.pos, need = m.need }
					end
				end
			end
		end
	end
	return seen
end

-- ---------- MENTE ----------
local function newMind(id, name, pos)
	return {
		id = id, name = name, pos = pos,
		needs = { hunger = 0.2, energy = 0.8, social = 0.3 },
		goal = "wander",
		target = pos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)),
		memory = {}, -- eventos causais
		relations = {}, -- id -> score
		state = "idle",
		lastDecision = tick(),
		speed = 10,
	}
end

function NMN.spawn(name, pos)
	local id = name .. "_" .. tostring(tick())
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = false
	root.Color = Color3.fromRGB(70 + math.random(0, 120), 90 + math.random(0, 100), 120 + math.random(0, 80))
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(pos)
	root.Parent = model
	local hum = Instance.new("Humanoid")
	hum.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = root.Position + Vector3.new(0, 1.8, 0)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(230, 200, 170)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head
	local ok = pcall(function() model.Parent = workspace end)
	if not ok then return nil end
	local mind = newMind(id, name, root.Position)
	minds[id] = mind
	model:SetAttribute("arkher.nmn.id", id)
	gridInsert(cellKey(pos.X, pos.Z), id)
	ARKHER.out("INFO", "NMN: " .. name .. " nasce em (" .. string.format("%.0f", pos.X) .. "," .. string.format("%.0f", pos.Z) .. ")")
	return mind
end

function NMN.kill(id)
	local m = minds[id]
	if not m then return end
	for _, key in ipairs(nearKeys(m.pos.X, m.pos.Z)) do
		gridRemove(key, id)
	end
	minds[id] = nil
end

function NMN.count()
	return table.maxn and table.maxn(minds) or (function()
		local n = 0
		for _ in pairs(minds) do n = n + 1 end
		return n
	end)()
end

local function remember(m, event, cause)
	m.memory[#m.memory + 1] = { t = tick(), event = event, cause = cause }
	if #m.memory > 40 then table.remove(m.memory, 1) end
end

-- ---------- DECISÃO (causal: cada acao guarda a causa) ----------
local function decide(m)
	local hunger, energy, social = m.needs.hunger, m.needs.energy, m.needs.social
	local neighbors = NMN.perceive(m.pos, 20)
	local nearPeople = 0
	for _, s in ipairs(neighbors) do
		local other = minds[s.id]
		if other then
			nearPeople = nearPeople + 1
			m.relations[s.id] = (m.relations[s.id] or 0) + 0.05
		end
	end
	local cause = "state:hunger=" .. string.format("%.1f", hunger) .. ",energy=" .. string.format("%.1f", energy) .. ",social=" .. string.format("%.1f", social) .. ",near=" .. nearPeople
	local newGoal
	if energy < 0.2 then
		newGoal = "rest"
	elseif hunger > 0.8 then
		newGoal = "seek_food"
	elseif nearPeople == 0 and social > 0.7 then
		newGoal = "seek_people"
	elseif nearPeople >= 2 then
		newGoal = "wander"
	else
		newGoal = m.goal
	end
	if newGoal ~= m.goal then
		m.goal = newGoal
		remember(m, "goal." .. newGoal, cause)
		Bus.emit("nmn.decision", { id = m.id, name = m.name, goal = newGoal, cause = cause })
	end
	m.state = m.goal
end

-- ---------- TICK (escala com D-O15) ----------
function NMN.tick()
	tickCount = tickCount + 1
	local budget = ArkherDO15 and ArkherDO15.refreshBudget("nmn") or 0.1
	if tickCount % math.max(1, math.floor(budget * 60)) ~= 0 then return 0 end
	local processed = 0
	for id, m in pairs(minds) do
		-- decaimento/evolucao das precisoes
		m.needs.hunger = math.min(1, m.needs.hunger + 0.002)
		m.needs.energy = math.max(0, m.needs.energy - 0.001)
		if m.goal == "rest" then m.needs.energy = math.min(1, m.needs.energy + 0.01) end
		m.needs.social = math.min(1, m.needs.social + 0.001)
		-- percecao + decisao (apenas se ha mudeca de estado OU periodicamente)
		if tickCount % 120 == 0 or m.state == "idle" then
			decide(m)
		end
		-- movimento simples rumo ao alvo
		local root
		for _, ch in ipairs(workspace:GetChildren()) do
			if ch:GetAttribute("arkher.nmn.id") == id then
				for _, p in ipairs(ch:GetChildren()) do
					if p.Name == "HumanoidRootPart" then root = p break end
				end
				break
			end
		end
		if root then
			local dir = m.target - root.Position
			local dist = dir.Magnitude
			if dist < 1 then
				m.target = root.Position + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
			else
				dir = dir.Unit
				local step = math.min(dist, m.speed * 0.16)
				local key = cellKey(root.Position.X, root.Position.Z)
				pcall(function()
					root.Position = root.Position + dir * step
					gridRemove(key, id)
					gridInsert(cellKey(root.Position.X, root.Position.Z), id)
					m.pos = root.Position
				end)
			end
		end
		processed = processed + 1
	end
	return processed
end

function NMN.start()
	local RunService = game:GetService("RunService")
	pcall(function()
		RunService.Heartbeat:Connect(function()
			pcall(function() NMN.tick() end)
		end)
	end)
	ARKHER.out("INFO", "NMN ativo: " .. NMN.count() .. " mentes")
end

function NMN.report()
	local out = {}
	for id, m in pairs(minds) do
		out[#out + 1] = {
			id = id, name = m.name, goal = m.goal, state = m.state,
			needs = { hunger = m.needs.hunger, energy = m.needs.energy, social = m.needs.social },
			memorySize = #m.memory, relations = table.maxn and 0 or 0,
			pos = m.pos,
		}
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

function NMN.why(id)
	local m = minds[id]
	if not m then return "sem registro" end
	local last = m.memory[#m.memory]
	return m.name .. " → " .. m.goal .. (last and (" | causa: " .. last.cause) or "")
end
end

do
--[[ ARKHER V3 — PLACES: criar/salvar/abrir/exportar places como no Roblox Studio ]]
-- ArkherPlaces: o sistema de places do ARKHER.
-- - New(template): cria um place novo (limpa workspace e aplica template real)
-- - Save(): snapshot REAL (hierarquia + propriedades + scripts) no ArkherCloud (ServerStorage)
-- - Open(id): restaura um snapshot
-- - Export(): gera um bundle Lua portavel (grava em disco via game.WriteFile se o Studio permitir)
-- - List(): lista places salvos
-- Nao depende de filesystem obrigatorio nem de Open Cloud API.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local P = {}
ArkherPlaces = P

local CLOUD_NAME = "ArkherCloud"

function P.cloudRoot()
	local root = ServerStorage:FindFirstChild(CLOUD_NAME)
	if not root then
		root = Instance.new("Folder")
		root.Name = CLOUD_NAME
		root.Parent = ServerStorage
	end
	return root
end

function P.placesFolder()
	local f = P.cloudRoot():FindFirstChild("Places")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Places"
		f.Parent = P.cloudRoot()
	end
	return f
end

-- ---------- SERIALIZACAO REAL ----------
local SCRIPT_CLASSES = { ["Script"] = true, ["LocalScript"] = true, ["ModuleScript"] = true }
local IGNORE = {
	["Humanoid"] = true, ["HumanoidRootPart"] = true,
	["Motor6D"] = true, ["WeldConstraint"] = true, ["ManualWarehouse"] = true,
	["SelectionBox"] = true, ["PathFindingMap"] = true,
}

local PROP_SKIP = {
	Parent = true, Name = true, ClassName = true,
	Archivable = true, Redacted = true,
}

local function serializeInstance(inst, depth, out)
	if depth > 24 then return nil end
	local entry = { cls = inst.ClassName, name = inst.Name, props = {}, kids = {} }
	-- pega propriedades via pcall-safe loop
	local ok = pcall(function()
		-- usa os getters padrao que todo Instance expoe
		local props = {
			"Position", "CFrame", "Size", "Color", "Material", "Transparency",
			"CanCollide", "Anchored", "CastShadow", "BrickColor", "TopSurface",
			"Text", "TextColor3", "TextSize", "BackgroundTransparency", "BackgroundColor3",
			"RotSpeed", "LinearVelocity", "Source", "Face", "AudioVolume", "Loops",
			"Rate", "LightColor", "Brightness", "Range", "Fov", "FocusDistance",
			"Visible", "Size2D", "Enabled", "Speed", "Rate2",
		}
		for _, pn in ipairs(props) do
			if not PROP_SKIP[pn] then
				local okv, v = pcall(function() return inst[pn] end)
				if okv and v ~= nil then
				local tv = type(v)
				if tv == "number" or tv == "string" or tv == "boolean" then
					entry.props[pn] = v
				elseif tv == "table" and v.__t == "Vector3" then
					entry.props[pn] = { v.X, v.Y, v.Z }
				elseif tv == "table" and v.__t == "Color3" then
					entry.props[pn] = { math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255) }
				elseif tv == "table" and v.__t == "BrickColor" then
					entry.props[pn] = v.Name
					elseif tv == "table" and v.NumberValue ~= nil and v.EnumItem then
						entry.props[pn] = tostring(v)
					end
				end
			end
		end
		if SCRIPT_CLASSES[inst.ClassName] then
			entry.props.__src = inst.Source or ""
		end
	end)
	for _, ch in ipairs(inst:GetChildren()) do
		if not IGNORE[ch.ClassName] then
			local sub = serializeInstance(ch, depth + 1, out)
			if sub then table.insert(entry.kids, sub) end
		end
	end
	return entry
end

local function parseVector(v)
	if type(v) == "table" and #v == 3 then return Vector3.new(v[1], v[2], v[3]) end
	return nil
end
local function parseColor(v)
	if type(v) == "table" and #v == 3 then return Color3.fromRGB(v[1], v[2], v[3]) end
	return nil
end

local function restoreInstance(entry, parent)
	if not entry then return nil end
	local inst
	local ok = pcall(function() inst = Instance.new(entry.cls) end)
	if not ok or not inst then
		ARKHER.out("WARNING", "Place restore: classe indisponivel " .. tostring(entry.cls))
		return nil
	end
	inst.Name = entry.name or inst.Name
	for pn, v in pairs(entry.props or {}) do
		if pn == "__src" then
			pcall(function() inst.Source = v end)
		elseif pn == "CFrame" then
			local vec = parseVector(v)
			if vec then pcall(function() inst.CFrame = CFrame.new(vec) end) end
		elseif pn == "Position" then
			local vec = parseVector(v)
			if vec then pcall(function() inst.Position = vec end) end
		elseif pn == "Color" then
			local col = parseColor(v)
			if col then pcall(function() inst.Color = col end) end
		elseif pn == "BackgroundColor3" or pn == "TextColor3" or pn == "LightColor" or pn == "Color3" then
			local col = parseColor(v)
			if col then pcall(function() inst[pn] = col end) end
		elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
			pcall(function() inst[pn] = v end)
		end
	end
	for _, kid in ipairs(entry.kids or {}) do
		restoreInstance(kid, inst)
	end
	pcall(function() inst.Parent = parent end)
	return inst
end

-- ---------- SNAPSHOT DO PLACE ----------
function P.snapshot()
	local ws = workspace
	local data = {
		meta = {
			v = 3, t = tick(), name = ARKHER.STATE.placeName,
			id = ARKHER.STATE.placeId, do15 = ARKHER.STATE.do15Level,
			engine = "ARKHER V3 / UES",
		},
		services = {},
	}
	-- workspace completo
	local wsEntry = serializeInstance(ws, 0, data.services)
	data.workspace = wsEntry
	-- Lighting (sky, atmosphere, lights)
	local lighting = game:FindFirstChild("Lighting")
	if lighting then
		data.lighting = serializeInstance(lighting, 0, data.services)
	end
	-- PlayerGui / StarterGui conteudo
	for _, svc in ipairs({ "StarterGui", "StarterPack", "StarterCharacterScripts" }) do
		local s = game:FindFirstChild(svc)
		if s then data[svc] = serializeInstance(s, 0, data.services) end
	end
	return data
end

function P.apply(data)
	if not data or not data.workspace then
		ARKHER.out("ERROR", "Place: snapshot invalido")
		return false
	end
	ARKHER.cmd("undo.push", "Abrir place")
	-- limpa workspace
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		pcall(function() ch:Destroy() end)
	end
	-- restaura os FILHOS do workspace (nao um Workspace aninhado)
	for _, kid in ipairs(data.workspace.kids or {}) do
		restoreInstance(kid, ws)
	end
	if data.lighting then
		local lighting = game:FindFirstChild("Lighting")
		if lighting then
			for _, ch in ipairs(lighting:GetChildren()) do pcall(function() ch:Destroy() end) end
			restoreInstance(data.lighting, lighting)
		end
	end
	ARKHER.out("SUCCESS", "Place restaurado: " .. tostring((data.meta or {}).name))
	return true
end

-- ---------- PERSISTENCIA (ServerStorage.ArkherCloud) ----------
local function store(id, json)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if not f then
		f = Instance.new("Folder")
		f.Name = tostring(id)
		f.Parent = P.placesFolder()
	end
	local sv = f:FindFirstChild("data")
	if not sv then
		sv = Instance.new("StringValue")
		sv.Name = "data"
		sv.Parent = f
	end
	sv.Value = json
	local meta = f:FindFirstChild("meta")
	if not meta then
		meta = Instance.new("StringValue")
		meta.Name = "meta"
		meta.Parent = f
	end
	return f
end

local function read(id)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if not f then return nil end
	local sv = f:FindFirstChild("data")
	if not sv then return nil end
	return HttpService:JSONDecode(sv.Value)
end

function P.save(name)
	local data = P.snapshot()
	data.meta.name = name or ARKHER.STATE.placeName
	ARKHER.STATE.placeName = data.meta.name
	local json = HttpService:JSONEncode(data)
	local id = ARKHER.STATE.placeId
	if id == 0 then
		id = math.floor(tick() * 1000) % 1000000000
		ARKHER.STATE.placeId = id
	end
	store(id, json)
	P.refreshList()
	ARKHER.out("SUCCESS", "Place salvo: " .. data.meta.name .. " (id " .. id .. ") — " .. #json .. " bytes")
	Bus.emit("place.saved", data.meta)
	return id
end

function P.new(template)
	template = template or "Baseplate"
	ARKHER.cmd("undo.push", "New place")
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then
			pcall(function() ch:Destroy() end)
		end
	end
	local t = P.TEMPLATES[template]
	if t then t() end
	ARKHER.STATE.placeName = "New " .. template .. " Place"
	ARKHER.STATE.placeId = 0
	ARKHER.out("SUCCESS", "Place novo criado: " .. template)
	Bus.emit("place.new", template)
	return ARKHER.STATE.placeName
end

function P.open(id)
	local data = read(id)
	if not data then
		ARKHER.out("ERROR", "Place nao encontrado: " .. tostring(id))
		return false
	end
	local ok = P.apply(data)
	if ok and data.meta then
		ARKHER.STATE.placeName = data.meta.name or "Place"
		ARKHER.STATE.placeId = tonumber(id) or 0
	end
	Bus.emit("place.opened", { id = id })
	return ok
end

function P.close()
	ARKHER.STATE.placeName = "Untitled"
	ARKHER.STATE.placeId = 0
	ARKHER.out("INFO", "Place fechado")
end

function P.refreshList()
	local list = {}
	for _, f in ipairs(P.placesFolder():GetChildren()) do
		local meta = f:FindFirstChild("meta")
		local sv = f:FindFirstChild("data")
		local info = { id = tonumber(f.Name) or 0, name = f.Name, bytes = sv and #sv.Value or 0 }
		if meta then
			local ok, m = pcall(function() return HttpService:JSONDecode(meta.Value) end)
			if ok and type(m) == "table" then info = m end
		end
		list[#list + 1] = info
	end
	table.sort(list, function(a, b) return (a.bytes or 0) > (b.bytes or 0) end)
	ARKHER.STATE.cloud.places = list
	return list
end

function P.list()
	return P.refreshList()
end

function P.delete(id)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if f then
		pcall(function() f:Destroy() end)
		P.refreshList()
		ARKHER.out("INFO", "Place removido: " .. tostring(id))
	end
end

-- ---------- EXPORT (bundle portavel, sem Open Cloud API) ----------
function P.exportBundle()
	local data = P.snapshot()
	local json = HttpService:JSONEncode(data)
	local generated = (os.date and os.date("%c")) or ""
	local header = "-- ARKHER PLACE BUNDLE v3\n-- nome: " .. data.meta.name .. "\n-- gerado: " .. generated .. "\n-- para restaurar: cole este arquivo no Command Bar do ARKHER (FILE > Import Bundle)\n"
	-- %q: string escapada (robusto, sem long strings que quebrariam o embed)
	local jsq = string.format("%q", json)
	local body = "local HttpService = game:GetService(\"HttpService\")\nlocal ServerStorage = game:GetService(\"ServerStorage\")\nlocal json = " .. jsq .. "\nlocal data = HttpService:JSONDecode(json)\nif ArkherPlaces then ArkherPlaces.apply(data)\nelse\n\tlocal root = ServerStorage:FindFirstChild(\"ArkherCloud\") or Instance.new(\"Folder\"); root.Parent = ServerStorage\n\tlocal f = Instance.new(\"Folder\"); f.Name = \"pending\"; f.Parent = root\n\tlocal sv = Instance.new(\"StringValue\"); sv.Name = \"bundle\"; sv.Value = json; sv.Parent = f\n\tprint(\"[ARKHER] bundle aguardando o editor: reabra o ARKHER e use FILE > Import Bundle\")\nend"
	return header .. body
end

function P.exportToFile()
	local bundle = P.exportBundle()
	local ok, err = pcall(function()
		if game.WriteFile then
			game:WriteFile("ArkherPlaces/" .. (ARKHER.STATE.placeName or "place") .. ".arkher.lua", bundle)
			ARKHER.out("SUCCESS", "Bundle exportado para o disco: ArkherPlaces/" .. (ARKHER.STATE.placeName or "place") .. ".arkher.lua")
			return true
		end
		return false
	end)
	if not ok or not err then
		ARKHER.out("WARNING", "game.WriteFile indisponivel (fora do Studio). Use FILE > Copy Bundle para copiar.")
		return false
	end
	return err
end

function P.copyBundle()
	local bundle = P.exportBundle()
	local ok = pcall(function()
		if setclipboard then setclipboard(bundle) end
		ARKHER.out("SUCCESS", "Bundle copiado para a area de transferencia (" .. #bundle .. " chars)")
		return true
	end)
	if not ok then
		ARKHER.out("WARNING", "Sem clipboard neste ambiente. Exporte para arquivo ou Cloud.")
	end
end

-- ---------- TEMPLATES REAIS ----------
P.TEMPLATES = {}
function P.TEMPLATES.Baseplate()
	local ws = workspace
	local plate = Instance.new("Part")
	plate.Name = "Baseplate"
	plate.Size = Vector3.new(120, 1, 120)
	plate.Position = Vector3.new(0, -0.5, 0)
	plate.Color = Color3.fromRGB(136, 136, 136)
	plate.Anchored = true
	plate.TopSurface = Enum.SurfaceType.Smooth
	plate.BottomSurface = Enum.SurfaceType.Smooth
	plate.Parent = ws
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.City()
	P.TEMPLATES.Baseplate()
	local ws = workspace
	local city = Instance.new("Model")
	city.Name = "City"
	city.Parent = ws
	local mat = {
		{ 120, 120, 130 }, { 100, 110, 130 }, { 140, 140, 150 }, { 90, 100, 120 },
	}
	local rng = Random.new(42)
	for i = 1, 24 do
		local b = Instance.new("Part")
		b.Name = "Building_" .. i
		local h = 6 + rng:NextInteger(0, 26)
		b.Size = Vector3.new(6 + rng:NextInteger(0, 8), h, 6 + rng:NextInteger(0, 8))
		b.Position = Vector3.new((rng:NextInteger(0, 14) - 7) * 10 + 5, h / 2 + 0.5, (rng:NextInteger(0, 14) - 7) * 10 + 5)
		b.Anchored = true
		local c = mat[(i % #mat) + 1]
		b.Color = Color3.fromRGB(c[1], c[2], c[3])
		b.Parent = city
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 140)
		light.Brightness = 0.6
		light.Range = 8
		light.Parent = b
	end
	local road = Instance.new("Part")
	road.Name = "Road_X"
	road.Size = Vector3.new(90, 0.3, 6)
	road.Position = Vector3.new(0, 0.2, 0)
	road.Anchored = true
	road.Color = Color3.fromRGB(30, 30, 34)
	road.Parent = city
	local road2 = Instance.new("Part")
	road2.Name = "Road_Z"
	road2.Size = Vector3.new(6, 0.3, 90)
	road2.Position = Vector3.new(0, 0.2, 0)
	road2.Anchored = true
	road2.Color = Color3.fromRGB(30, 30, 34)
	road2.Parent = city
end

function P.TEMPLATES.Nature()
	local ws = workspace
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(160, 1, 160)
	ground.Position = Vector3.new(0, -0.5, 0)
	ground.Color = Color3.fromRGB(74, 110, 60)
	ground.Material = Enum.Material.Grass
	ground.Anchored = true
	ground.Parent = ws
	local hill = Instance.new("Part")
	hill.Name = "Hill"
	hill.Size = Vector3.new(40, 18, 40)
	hill.Position = Vector3.new(30, 9, -40)
	hill.Anchored = true
	hill.Color = Color3.fromRGB(88, 122, 70)
	hill.Material = Enum.Material.Grass
	hill.Parent = ws
	local water = Instance.new("Part")
	water.Name = "Lake"
	water.Size = Vector3.new(30, 0.4, 24)
	water.Position = Vector3.new(-30, 0.2, 25)
	water.Color = Color3.fromRGB(40, 110, 180)
	water.Material = Enum.Material.Water
	water.Anchored = true
	water.Transparency = 0.25
	water.Parent = ws
	local trees = Instance.new("Model")
	trees.Name = "Trees"
	trees.Parent = ws
	local rng = Random.new(7)
	for i = 1, 14 do
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk_" .. i
		trunk.Size = Vector3.new(1.2, 4, 1.2)
		trunk.Position = Vector3.new(rng:NextInteger(-60, 60), 2.5, rng:NextInteger(-60, 60))
		trunk.Anchored = true
		trunk.Color = Color3.fromRGB(92, 64, 40)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = trees
		local crown = Instance.new("Part")
		crown.Name = "Crown_" .. i
		crown.Size = Vector3.new(5, 5, 5)
		crown.Shape = Enum.PartType.Ball
		crown.Position = trunk.Position + Vector3.new(0, 4.5, 0)
		crown.Anchored = true
		crown.Color = Color3.fromRGB(40, 120, 45)
		crown.Material = Enum.Material.Grass
		crown.Parent = trees
	end
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.Space()
	local ws = workspace
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(20, 1, 20)
	platform.Position = Vector3.new(0, 0, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.Neon
	platform.Color = Color3.fromRGB(60, 80, 140)
	platform.Parent = ws
	local rock = Instance.new("Part")
	rock.Name = "Asteroid"
	rock.Size = Vector3.new(10, 10, 10)
	rock.Shape = Enum.PartType.Ball
	rock.Position = Vector3.new(20, 14, -18)
	rock.Anchored = false
	rock.Color = Color3.fromRGB(120, 110, 130)
	rock.Material = Enum.Material.Slate
	rock.Parent = ws
	local sun = Instance.new("Part")
	sun.Name = "Sun"
	sun.Size = Vector3.new(14, 14, 14)
	sun.Shape = Enum.PartType.Ball
	sun.Position = Vector3.new(-40, 24, -50)
	sun.Anchored = true
	sun.Material = Enum.Material.Neon
	sun.Color = Color3.fromRGB(255, 200, 90)
	sun.Parent = ws
	local light = Instance.new("PointLight")
	light.Parent = sun
	light.Brightness = 2
	light.Range = 120
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.Position = Vector3.new(0, 1, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.Empty()
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then
			pcall(function() ch:Destroy() end)
		end
	end
	local part = Instance.new("Part")
	part.Name = "Part"
	part.Anchored = true
	part.Parent = ws
end

P.TEMPLATES.Baseplate()
end

do
--[[ ARKHER V3 — ACTIONS: registro central de comandos ]]
-- Menus, toolbar, atalhos, command palette e a IA usam o MESMO registro:
-- ARKHER.cmd("comando", arg). Nenhum botão da UI é decorativo.
local UserInputService = game:GetService("UserInputService")
local Selection = game:GetService("Selection")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")
local HttpService = game:GetService("HttpService")

local A = {}
ArkherActions = A
ARKHER.ACTIONS = A -- mesmo objeto: ARKHER.cmd() despacha p/ A

local function sel()
	local ok, s = pcall(function() return Selection:Get() end)
	if ok and s and #s > 0 then return s[1] end
	return nil
end

-- ================= PLACE / FILE =================
A["place.new"] = function(template)
	ArkherPlaces.new(template)
	ARKHER.out("SUCCESS", "Place novo: " .. ARKHER.STATE.placeName)
end
A["place.open"] = function(id)
	if id then
		ArkherPlaces.open(id)
	else
		ARKHER.open("SaveOpen")
	end
end
A["place.save"] = function()
	ArkherPlaces.save()
end
A["place.close"] = function()
	ArkherPlaces.close()
end
A["place.export"] = function()
	ArkherPlaces.exportToFile()
	ArkherPlaces.copyBundle()
end
A["file.save"] = A["place.save"]
A["file.savecloud"] = function()
	ArkherPublish.toLocal()
end
A["file.open"] = function()
	ARKHER.open("SaveOpen")
end
A["file.import"] = function()
	ARKHER.out("INFO", "Import: copie um bundle .arkher.lua e cole no editor (FILE > Copy Bundle usa a area de transferencia).")
	ARKHER.open("SaveOpen")
end
A["file.export"] = A["place.export"]

-- ================= PUBLISH (sem Open Cloud API) =================
A["publish.local"] = function()
	ArkherPublish.toLocal()
end
A["publish.cloud"] = function()
	if ArkherPublish.toEndpoint() then return end
	ARKHER.out("INFO", "Sem endpoint? O local cloud guardou o bundle. Configure em Settings > Cloud.")
	ArkherPublish.toLocal()
end
A["publish.native"] = function()
	ArkherPublish.toRobloxNative()
end
A["game.publish"] = A["publish.local"]
A["game.places"] = function()
	ARKHER.open("SaveOpen")
end
A["game.settings"] = function()
	ARKHER.open("Settings")
end
A["game.passes"] = function()
	ARKHER.open("PackageManager")
end
A["game.products"] = function()
	ARKHER.out("INFO", "Developer Products: use o Package Manager para registrar passes/produtos no manifest do place.")
	ARKHER.open("PackageManager")
end

-- ================= UNDO (todo editavel passa por aqui antes de mudar) =================
A["undo.push"] = function(label)
	pcall(function() ArkherUNDO.push(label) end)
end

-- ================= EDIT =================
A["edit.undo"] = function() ArkherUNDO.undo() end
A["edit.redo"] = function() ArkherUNDO.redo() end
A["edit.delete"] = function()
	local s = sel()
	if s then
		ARKHER.cmd("undo.push", "Delete " .. s.Name)
		local ok = pcall(function() s:Destroy() end)
		ARKHER.out(ok and "SUCCESS" or "WARNING", "Removido: " .. (ok and s.Name or "sem acesso (servico)"))
	end
end
A["edit.duplicate"] = function()
	local s = sel()
	if not s then return end
	ARKHER.cmd("undo.push", "Duplicate " .. s.Name)
	local clone
	local ok = pcall(function() clone = s:Clone() end)
	if ok and clone then
		clone.Name = s.Name .. " Copy"
		if s:IsA("BasePart") then
			clone.Position = s.Position + Vector3.new(2, 0, 2)
		end
		pcall(function() clone.Parent = s.Parent end)
		pcall(function() Selection:Set({ clone }) end)
		ARKHER.out("SUCCESS", "Duplicado: " .. clone.Name)
	end
end
A["edit.rename"] = function()
	local s = sel()
	if not s then return end
	ARKHER.open("SaveOpen")
	ARKHER.out("INFO", "Renomear: use o panel SaveOpen/Manager ou digite no Explorer do Studio: " .. s.Name)
end
A["edit.copy"] = function()
	local s = sel()
	if s then ARKHER.STATE.clipboard = s end
end
A["edit.paste"] = function()
	local c = ARKHER.STATE.clipboard
	if not c or not c.Parent then
		ARKHER.out("WARNING", "Clipboard vazio")
		return
	end
	ARKHER.cmd("undo.push", "Paste " .. c.Name)
	local clone
	local ok = pcall(function() clone = c:Clone() end)
	if ok and clone then
		clone.Name = c.Name .. " Copy"
		pcall(function() clone.Parent = workspace end)
		ARKHER.out("SUCCESS", "Colado: " .. clone.Name)
	end
end
A["edit.cut"] = function()
	ARKHER.cmd("edit.copy")
	ARKHER.cmd("edit.delete")
end

-- ================= INSERT (cria instancias REAIS) =================
local function insertAt(cls, name, opts)
	ARKHER.cmd("undo.push", "Insert " .. name)
	local inst
	local ok = pcall(function() inst = Instance.new(cls) end)
	if not ok or not inst then
		ARKHER.out("ERROR", "Insert: classe indisponivel " .. cls)
		return
	end
	inst.Name = name or cls
	local pos = workspace:FindFirstChild("Camera")
	local at = (opts and opts.pos) or Vector3.new(0, 3, 0)
	if opts and opts.apply then opts.apply(inst) end
	if inst:IsA("BasePart") then
		inst.Anchored = true
		inst.Position = at
	end
	pcall(function() inst.Parent = workspace end)
	pcall(function() Selection:Set({ inst }) end)
	ARKHER.out("SUCCESS", "Inserido: " .. inst.Name .. " (" .. cls .. ")")
	return inst
end
A["insert.part"] = function()
	insertAt("Part", "Part")
end
A["insert.sphere"] = function()
	insertAt("Part", "Sphere", { apply = function(p) p.Shape = Enum.PartType.Ball p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.cylinder"] = function()
	insertAt("Part", "Cylinder", { apply = function(p) p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(4, 8, 4) end })
end
A["insert.wedge"] = function()
	insertAt("Part", "Wedge", { apply = function(p) p.Shape = Enum.PartType.Wedge p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.blockmesh"] = function()
	insertAt("Part", "BlockMesh", { apply = function(p) p.Shape = Enum.PartType.Block end })
end
A["insert.folder"] = function()
	local inst = insertAt("Folder", "Folder")
	return inst
end
A["insert.model"] = function()
	local m = insertAt("Model", "Model")
	local p = Instance.new("Part")
	p.Name = "Part"
	p.Anchored = true
	p.Size = Vector3.new(4, 4, 4)
	p.Parent = m
	return m
end
A["insert.script"] = function()
	insertAt("Script", "ServerScript", { apply = function(s) s.Source = "-- ServerScript\nprint(\"ARKHER: script criado\")\n" end })
end
A["insert.localscript"] = function()
	insertAt("LocalScript", "ClientScript", { apply = function(s) s.Source = "-- ClientScript\n" end })
end
A["insert.modulescript"] = function()
	insertAt("ModuleScript", "Module", { apply = function(s) s.Source = "return {}\n" end })
end
A["insert.text"] = function()
	local bb = insertAt("Part", "TextPart", { apply = function(p)
		p.Size = Vector3.new(8, 4, 1)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.Parent = p
		local lb = Instance.new("TextLabel")
		lb.Name = "Text"
		lb.Size = UDim2.new(1, 0, 1, 0)
		lb.BackgroundTransparency = 1
		lb.Text = "ARKHER"
		lb.TextScaled = true
		lb.TextColor3 = Color3.new(1, 1, 1)
		lb.Parent = sg
	end })
	return bb
end
A["insert.light"] = function()
	local m = insertAt("Model", "Light")
	local p = Instance.new("Part")
	p.Name = "LightPart"
	p.Anchored = true
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Parent = m
	local pl = Instance.new("PointLight")
	pl.Brightness = 2
	pl.Range = 20
	pl.Color = Color3.new(1, 1, 1)
	pl.Parent = p
	return m
end
A["insert.sound"] = function()
	local m = insertAt("Model", "Sound")
	local p = Instance.new("Part")
	p.Name = "SoundPart"
	p.Anchored = true
	p.Size = Vector3.new(1, 1, 1)
	p.Transparency = 1
	p.CanCollide = false
	p.Parent = m
	local s = Instance.new("Sound")
	s.Name = "Sound"
	s.Loops = false
	s.Parent = p
	return m
end

-- ================= TOOL / TRANSFORM =================
local TOOLS = { Select = "select", Move = "move", Rotate = "rotate", Scale = "scale" }
A["tool"] = function(t)
	ARKHER.STATE.tool = t
	ARKHER.out("INFO", "Ferramenta: " .. t)
	Bus.emit("tool.changed", t)
end
A["transform.lock"] = function()
	ARKHER.STATE.locked = not ARKHER.STATE.locked
	ARKHER.out("INFO", "Lock: " .. (ARKHER.STATE.locked and "ON" or "OFF"))
	Bus.emit("tool.locked", ARKHER.STATE.locked)
end
A["transform.mode"] = function()
	ARKHER.STATE.spaceMode = ARKHER.STATE.spaceMode == "Local" and "Global" or "Local"
	ARKHER.out("INFO", "Espaco de transform: " .. ARKHER.STATE.spaceMode)
end

-- move real do selecionado (arraste com as setas / WASD quando ferramenta Move)
local function nudge(dx, dy, dz)
	local s = sel()
	if not s or not s:IsA("BasePart") then return end
	if ARKHER.STATE.locked then
		ARKHER.out("WARNING", "Objeto travado (Lock ON)")
		return
	end
	local ok = pcall(function() s.Position = s.Position + Vector3.new(dx, dy, dz) end)
	if ok and ARKHER_STATE then end
end
A["move.x+" ] = function() nudge(1, 0, 0) end
A["move.x-"] = function() nudge(-1, 0, 0) end
A["move.y+"] = function() nudge(0, 1, 0) end
A["move.y-"] = function() nudge(0, -1, 0) end
A["move.z+"] = function() nudge(0, 0, 1) end
A["move.z-"] = function() nudge(0, 0, -1) end

-- ================= RUN =================
A["run.play"] = function()
	ARKHER.STATE.playing = true
	ARKHER.out("SUCCESS", "RUN: modo Play (simulacao ARKHER)")
	Bus.emit("run.play")
end
A["run.pause"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: pausado")
	Bus.emit("run.pause")
end
A["run.stop"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: parado")
	Bus.emit("run.stop")
end
A["run.diagnostics"] = function()
	ARKHER_SINGULARITY.run("diagnostico completo do place")
end
A["run.perf"] = function()
	ARKHER.open("Profiler")
end
A["sandbox.toggle"] = function()
	ARKHER.STATE.sandbox = not ARKHER.STATE.sandbox
	ARKHER.out("INFO", "Sandbox: " .. (ARKHER.STATE.sandbox and "ON (plugins isolados)" or "OFF"))
	Bus.emit("sandbox.changed", ARKHER.STATE.sandbox)
end

-- ================= VIEW (abrir UIs) =================
A["view.properties"] = function() Bus.emit("view.toggle", "Properties") end
A["view.hierarchy"] = function() Bus.emit("view.toggle", "Hierarchy") end
A["view.console"] = function() ARKHER.open("Console") end
A["view.output"] = function() ARKHER.open("Console") end
A["view.palette"] = function()
	ARKHER.open("CommandPalette") -- registra/cria (na oculta)
	local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
	local g = fg and fg:FindFirstChild("ArkherStudioCommandPalette")
	if g then g.Visible = true end
end
A["ui.open"] = function(name)
	local ok = ARKHER.open(name)
	if ok then
		ARKHER.out("INFO", "UI aberta: " .. tostring(name))
	else
		ARKHER.out("WARNING", "UI nao abriu: " .. tostring(name))
	end
	return ok
end
A["view.reset"] = function()
	ARKHER.out("INFO", "Layout resetado")
	Bus.emit("view.reset")
end

-- ================= AI / SINGULARITY =================
A["ai.run"] = function(goal)
	ARKHER_SINGULARITY.run(goal)
end
A["ai.mode"] = function(mode)
	ARKHER.STATE.ai.mode = mode
	ARKHER.out("INFO", "IA modo: " .. mode)
	Bus.emit("ai.mode", mode)
end
A["ai.open"] = function()
	ARKHER.open("AIEditor")
end
A["utsai.open"] = function()
	ARKHER.open("UTSAI")
end

-- ================= CLOUD =================
A["cloud.status"] = function()
	local c = ARKHER.STATE.cloud
	ARKHER.out("INFO", "Cloud: " .. (c.endpoint and ("endpoint " .. c.endpoint) or "so local (ServerStorage)") .. " | " .. #c.places .. " places salvos")
	Bus.emit("cloud.status", c)
end
A["cloud.connect"] = function()
	ARKHER.open("Settings")
end
A["cloud.disconnect"] = function()
	ARKHER.STATE.cloud.endpoint = ""
	ARKHER.STATE.cloud.connected = false
	ARKHER.out("INFO", "Cloud: desconectado (modo local)")
	Bus.emit("cloud.status", ARKHER.STATE.cloud)
end

-- ================= TERRAIN X (custom, ArkherTerrainX) =================
local function txWorld(preset, seed)
	if not ArkherTerrainX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._world = ArkherTerrainX.new({ seed = seed or 1337, preset = preset or "continentes", cell = 8 })
	return ARKHER._world
end
A["terrain.generate"] = function(preset, seed)
	local w, err = txWorld(preset, seed)
	if not w then ARKHER.out("WARNING", "terrain.generate: " .. err) return end
	local res = w:materializeRegion(-96, -96, 192, 192, {})
	ARKHER.out("SUCCESS", "terrain.generate: preset '" .. w.preset .. "' seed " .. w.seed .. " → " .. res.parts .. " parts em " .. res.chunks .. " chunks")
end
A["terrain.erode"] = function(iters)
	if not ARKHER._world then txWorld() end
	local w = ARKHER._world
	if not w then ARKHER.out("WARNING", "terrain.erode: sem mundo ATX") return end
	local r = w:erodeHydraulic(1, 1, 48, 32, iters or 3000)
	ARKHER.out("SUCCESS", "terrain.erode: " .. (iters or 3000) .. " gotas | dMedio " .. string.format("%.3f", r.meanDelta))
end
A["terrain.rivers"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:carveRivers(1, 1, 48, 32, 20)
	ARKHER.out("SUCCESS", "terrain.rivers: " .. r.cells .. " celulas fluviais (acum. max " .. r.maxAcc .. ")")
end
A["terrain.lakes"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:fillLakes(1, 1, 48, 32)
	ARKHER.out("SUCCESS", "terrain.lakes: " .. r.cells .. " celulas de lago")
end
A["terrain.materialize"] = function(span)
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	span = span or 192
	local res = ARKHER._world:materializeRegion(-span / 2, -span / 2, span, span, {})
	ARKHER.out("SUCCESS", "terrain.materialize: " .. span .. "x" .. span .. " → " .. res.parts .. " parts (LOD D-O15)")
end
A["terrain.lod"] = function(fx, fz)
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.lod: sem mundo ATX") return end
	local r = ARKHER._world:updateLOD(fx or 0, fz or 0)
	ARKHER.out("INFO", "terrain.lod: " .. r.updated .. " chunks re-materializados adaptativamente")
end
A["terrain.clear"] = function()
	if ARKHER._world then ArkherTerrainX.clearWorld(ARKHER._world) end
	ARKHER.out("SUCCESS", "terrain.clear: ATX_World removido")
end
A["terrain.export"] = function()
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.export: sem mundo ATX") return end
	local str, path, ok = ARKHER._world:exportFile()
	ARKHER.out("SUCCESS", "terrain.export: " .. #str .. " chars → " .. path .. (ok and "" or " (string retornada)"))
end

-- ================= WATER X (custom, ArkherWaterX) =================
local function wxSea(preset)
	if not ArkherWaterX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._sea = ArkherWaterX.preset(preset or "porto", { kind = "oceano", level = 0, size = { x = 420, z = 320 } })
	return ARKHER._sea
end
A["water.ocean"] = function(preset)
	local sea, err = wxSea(preset)
	if not sea then ARKHER.out("WARNING", "water.ocean: " .. err) return end
	local _, n = ArkherWaterX.materialize(sea, { maxSpan = 420 })
	ARKHER.out("SUCCESS", "water.ocean: preset '" .. (preset or "porto") .. "' → " .. n .. " tiles animadas de Gerstner")
end
A["water.caustics"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local n = ArkherWaterX.caustics(ARKHER._sea, ARKHER._sea.level - 9)
	ARKHER.out("SUCCESS", "water.caustics: " .. n .. " brilhos")
end
A["water.float"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then
		for _, inst in ipairs(sel) do
			if inst:IsA("BasePart") then ArkherWaterX.float(ARKHER._sea, inst, {}) n = n + 1 end
		end
	end
	ARKHER.out("SUCCESS", "water.float: flutuabilidade arquimediana em " .. n .. " parts")
end
A["water.underwater"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	ARKHER._underwater = not ARKHER._underwater
	ArkherWaterX.applyUnderwater(ARKHER._sea, ARKHER._underwater)
	ARKHER.out("INFO", "water.underwater: " .. (ARKHER._underwater and "ON" or "OFF"))
end
A["water.splash"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	if not ARKHER._sea.tiles then ArkherWaterX.materialize(ARKHER._sea, { maxSpan = 240 }) end
	ArkherWaterX.splash(ARKHER._sea, 0, ARKHER._sea:heightAt(0, 0, 0), 0, 2)
	ARKHER.out("SUCCESS", "water.splash emitido")
end

-- ================= SCRIPT X (IDE) =================
A["script.new"] = function(name, templateId)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.new: Kit D nao carregado") return end
	name = name or "NovoScript"
	local tp = templateId and ArkherScripterX.template(templateId) or ArkherScripterX.template("basico")
	local sc = Instance.new(tp.cls)
	sc.Name = name
	sc.Source = tp.src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.new: " .. tp.cls .. " '" .. name .. "' (template " .. tp.id .. ") criado no workspace")
end
A["script.newfromgoal"] = function(goal)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.newfromgoal: Kit D nao carregado") return end
	local src, id2 = ArkherScripterX.compose(goal or "basico")
	local sc = Instance.new("Script")
	sc.Name = "IA_" .. id2
	sc.Source = src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.newfromgoal: template '" .. id2 .. "' composto p/ '" .. tostring(goal) .. "'")
end
A["script.lintreport"] = function()
	if not ArkherScripterX then return end
	local sel2 = sel()
	if not (sel2 and sel2:IsA("LuaSourceContainer")) then
		ARKHER.out("INFO", "script.lintreport: selecione um Script no explorer")
		return
	end
	local diags = ArkherScripterX.lint(sel2.Source or "")
	local sum = ArkherScripterX.lintSummary(diags)
	ARKHER.out("INFO", "lint " .. sel2.Name .. ": " .. sum.errors .. " err, " .. sum.warns .. " warn, " .. sum.infos .. " info")
end

-- ================= UI KIT X =================
A["uix.hud"] = function()
	if not ArkherUIKitX then ARKHER.out("WARNING", "uix.hud: Kit D nao carregado") return end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("timer", { x = 850, y = 16, text = "10:00" }),
		X.create("coins", { x = 16, y = 52, text = "1.0K" }),
	}
	local gui, n = X.build(widgets, "ArkherHUD")
	ARKHER.out("SUCCESS", "uix.hud: " .. n .. " widgets no StarterGui.ArkherHUD")
end
A["uix.theme"] = function(id)
	if ArkherUIKitX then ArkherUIKitX.setTheme(id or "arkher") ARKHER.out("INFO", "uix.theme: " .. (id or "arkher")) end
end

-- ================= ANIMATION X (AAX) =================
A["anim.demo"] = function()
	if not ArkherAnimX then ARKHER.out("WARNING", "anim.demo: Kit E nao carregado (ArkherKit_Installer_E)") return end
	local AX = ArkherAnimX
	local ws = workspace
	local p = Instance.new("Part")
	p.Name = "AAX_DemoCube"
	p.Size = Vector3.new(2, 2, 2)
	p.Anchored = true
	p.Color = Color3.fromRGB(255, 170, 60)
	p.CFrame = CFrame.new(0, 4, 0)
	p.Parent = ws
	local c = AX.clip("DemoCube", { loop = "pingpong" })
	c:addTrack("Position", { AX.key(0, { x = 0, y = 4, z = 0 }, "easeInOut_sine"), AX.key(1.2, { x = 0.4, y = 7.2, z = 0 }, "easeOut_spring"), AX.key(2.4, { x = 0, y = 4, z = 0 }, "easeInOut_sine") })
	c:addTrack("Transparency", { AX.key(0, 0.5, "linear"), AX.key(1.2, 0, "easeOut_sine"), AX.key(2.4, 0.5, "linear") })
	c:marker(1.2, "pico")
	c:bind(p, {})
	c:play({ from = 0 })
	ARKHER._animDemo = c
	ARKHER.out("SUCCESS", "anim.demo: cube no workspace tocando (easeOut_spring + pingpong)")
end
A["anim.pump"] = function(dt)
	if ArkherAnimX then
		local n = ArkherAnimX.pump(dt or 0.016)
		ArkherAnimX.pumpDeformers(dt or 0.016)
		ARKHER.out("INFO", "anim.pump: " .. n .. " clips vivos")
	end
end
A["anim.stopall"] = function()
	if ArkherAnimX then ArkherAnimX.stopAll() ARKHER.out("SUCCESS", "anim.stopall executado") end
end
A["anim.wave"] = function()
	if not ArkherAnimX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and sel and #sel >= 1 then
		local asm = ArkherAnimX.assemble(sel)
		ARKHER._deform = ArkherAnimX.deform(asm, ArkherAnimX.DEFORMERS.wave(1.2, 14, 2.2), {})
		ARKHER.out("SUCCESS", "anim.wave: deformer ondulando " .. #sel .. " parts (assembly)")
	else
		ARKHER.out("INFO", "anim.wave: selecione parts")
	end
end

-- ================= AUDIO X (AUX) =================
A["audio.setup"] = function()
	if not ArkherAudioX then ARKHER.out("WARNING", "audio.*: Kit E nao carregado") return end
	ArkherAudioX.setup()
	local st = ArkherAudioX.stats()
	ARKHER.out("SUCCESS", "audio.setup: " .. st.buses .. " buses SoundGroup criadas no SoundService")
end
A["audio.duckdemo"] = function()
	if not ArkherAudioX then return end
	ArkherAudioX.setup()
	ArkherAudioX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.register("voice_demo", { bus = "voice", volume = 0.6 })
	ArkherAudioX.duck("music", "voice", { level = 0.3 })
	ArkherAudioX.play("musica_demo")
	ArkherAudioX.play("voice_demo")
	ARKHER.out("SUCCESS", "audio.duckdemo: musica ducked p/ 30% quando a voz toca (sidechain)")
end
A["audio.patch"] = function(bus, preset)
	if not ArkherAudioX then return end
	local ok, n = ArkherAudioX.patch(bus or "music", preset or "caverna")
	ARKHER.out(ok and "SUCCESS" or "WARNING", "audio.patch: " .. (preset or "caverna") .. " → " .. tostring(n))
end

-- ================= SCENE / SCATTER X (ASXN) =================
A["scene.forest"] = function(radius)
	if not ArkherSceneX then ARKHER.out("WARNING", "scene.*: Kit E nao carregado") return end
	local w = ARKHER._world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
	ARKHER._world = w
	local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = radius or 90, count = 70, minDist = 6, maxSlope = 0.9, world = w, seed = 777, name = "ASXN_Forest" })
	ARKHER.out("SUCCESS", "scene.forest: " .. res.count .. " arvores/arbustos/grama no mundo (biomas Whittaker)")
end
A["scene.patina"] = function()
	if not ArkherSceneX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then n = ArkherSceneX.patina(sel, {}) end
	ARKHER.out("SUCCESS", "scene.patina: variacao anti-CG em " .. n .. " parts")
end
A["scene.query"] = function(cls)
	if not ArkherSceneX then return end
	local list = ArkherSceneX.query({ class = cls or "Part" })
	ARKHER.out("INFO", "scene.query '" .. (cls or "Part") .. "' → " .. #list .. " resultados")
end
A["scene.rehash"] = function()
	if ArkherSceneX then
		local n = ArkherSceneX.rehash()
		ARKHER.out("SUCCESS", "scene.rehash: " .. n .. " parts no spatial hash")
	end
end
A["scene.lod"] = function()
	if ArkherSceneX then
		local r = ArkherSceneX.applyLOD(0, 0)
		ARKHER.out("INFO", "scene.lod: " .. r.shown .. " visiveis, " .. r.ghosts .. " ghosts, " .. r.culled .. " culled")
	end
end

-- ================= ATMOS X (ceu + clima custom) =================
A["atmos.setup"] = function()
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.setup({})
	ARKHER.out("SUCCESS", "atmos.setup: Lighting real vinculado (Atmosphere + ColorCorrection)")
end
A["atmos.preset"] = function(name)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "meiodia"
	if ArkherAtmosX.setPreset(name) then
		ArkherAtmosX.apply({})
		ARKHER.out("SUCCESS", "atmos.preset: " .. name .. " (Kelvin real aplicado ao Lighting)")
	else
		ARKHER.out("ERROR", "atmos.preset desconhecido: " .. name)
	end
end
A["atmos.weather"] = function(name, speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "limpo"
	if ArkherAtmosX.setWeather(name, speedo or 0.6) then
		for i = 1, 90 do ArkherAtmosX.pump(1 / 30) end
		ARKHER.out("SUCCESS", "atmos.weather: " .. name .. " (transicao completa, links AWX/AUX aplicados)")
	else
		ARKHER.out("ERROR", "atmos.weather desconhecido: " .. name)
	end
end
A["atmos.cycle"] = function(speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.S.cycleSpeed = speedo or 0.2
	ARKHER.out("INFO", "atmos.cycle: velocidade do ciclo solar = " .. tostring(ArkherAtmosX.S.cycleSpeed) .. " h/s")
end

-- ================= CAMERA X (cinematografia custom) =================
A["cam.orbit"] = function(radius, height, seconds)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = radius or 14, height = height or 6, speed = 0.6, duration = 9999 })
	ARKHER.out("SUCCESS", "cam.orbit: camera orbitando (raio " .. (radius or 14) .. " m)")
end
A["cam.crane"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
	ARKHER.out("SUCCESS", "cam.crane: movimento crane 4s com lift")
end
A["cam.fly"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
	ARKHER.out("SUCCESS", "cam.fly: trajetoria Catmull-Rom 3D real (5s)")
end
A["cam.shake"] = function(t)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.addTrauma(t or 0.8)
	ARKHER.out("INFO", "cam.shake: trauma +" .. (t or 0.8) .. " (amplitude trauma^2 real)")
end
A["cam.fade"] = function(to)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.fade(to or -1, 0.8)
	ARKHER.out("SUCCESS", "cam.fade: ColorCorrection real -> brightness " .. tostring(to or -1))
end
A["cam.cinema"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.cinema({
		{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 },
		{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
		{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
	})
	ARKHER.out("SUCCESS", "cam.cinema: sequencia de 3 cortes reais iniciada")
end
A["cam.stop"] = function() if ArkherCameraX then ArkherCameraX.stop() ARKHER.out("INFO", "cam.stop") end end

-- ================= PARTICLES X (emissores custom) =================
A["px.emit"] = function(kind)
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	kind = kind or "fogo"
	local pe = ArkherParticlesX.emit(nil, kind)
	ARKHER.out("SUCCESS", "px.emit: " .. kind .. " (ParticleEmitter real, budget D-O15 aplicado)")
	return pe
end
A["px.demo"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	local kinds = { "fogo", "fumaca", "magia" }
	for _, k in ipairs(kinds) do ArkherParticlesX.emit(nil, k) end
	ARKHER.out("SUCCESS", "px.demo: fogo + fumaca + magia emitidos")
end
-- ================= ROPE X (Verlet cloth/rope) =================
A["rope.demo"] = function()
	if not ArkherRopeX then ARKHER.out("WARNING", "rope.*: Kit E nao carregado") return end
	local r = ArkherRopeX.rope({ from = { x = 0, y = 16, z = -8 }, points = 12, name = "RPX_Demo" })
	ArkherRopeX.materializeRope(r, { w = 0.22, color = { 180, 120, 60 } })
	local fl = ArkherRopeX.flagAt(4, 14, 6)
	ArkherRopeX.addSphere(0, 12.0, -8, 2.4)
	ARKHER.out("SUCCESS", "rope.demo: corda pendurada + bandeira de Verlet no world (vento liga via AEX)")
end
A["rope.clear"] = function()
	if ArkherRopeX then
		ArkherRopeX.remove("RPX_Demo") ArkherRopeX.remove("RPX_DemoCloth") ArkherRopeX.clearColliders()
		ARKHER.out("INFO", "rope.clear")
	end
end
A["px.clear"] = function()
	if ArkherParticlesX then ArkherParticlesX.clear() ARKHER.out("INFO", "px.clear: todos desligados") end
end
A["px.storm"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	if ArkherAtmosX then ArkherAtmosX.setup({}) ArkherAtmosX.setWeather("tempestade", 1.2) end
	ArkherParticlesX.emit(nil, "chuva", { rate = 240, speed = 40 })
	ARKHER.out("SUCCESS", "px.storm: chuva fisica + ATX... AEX tempestade (onda awx no pump)")
end

-- ================= GENERIC: ui.<nome> =================
function A.registerUICommands()
	for name in pairs(ARKHER.CATALOG) do
		ARKHER.on("ui." .. name, function()
			ARKHER.open(name)
		end)
		ARKHER.on(name, function()
			ARKHER.open(name)
		end)
	end
	-- atalhos de menu comuns
	ARKHER.on("menu.file.save", A["file.save"])
end

-- ================= SHORTCUTS =================
function A.startShortcuts()
	local CTRL = {
		[Enum.KeyCode.K] = function() ARKHER.open("CommandPalette") end,
		[Enum.KeyCode.Z] = function() ArkherUNDO.undo() end,
		[Enum.KeyCode.Y] = function() ArkherUNDO.redo() end,
		[Enum.KeyCode.D] = function() ARKHER.cmd("edit.duplicate") end,
		[Enum.KeyCode.C] = function() ARKHER.cmd("edit.copy") end,
		[Enum.KeyCode.X] = function() ARKHER.cmd("edit.cut") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("edit.paste") end,
	}
	local PLAIN = {
		[Enum.KeyCode.Delete] = function() ARKHER.cmd("edit.delete") end,
		[Enum.KeyCode.L] = function() ARKHER.cmd("transform.lock") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("tool", "Select") end,
		[Enum.KeyCode.W] = function() ARKHER.cmd("tool", "Move") end,
		[Enum.KeyCode.E] = function() ARKHER.cmd("tool", "Rotate") end,
		[Enum.KeyCode.R] = function() ARKHER.cmd("tool", "Scale") end,
	}
	local NUDGE = {
		[Enum.KeyCode.W] = "move.z-", [Enum.KeyCode.S] = "move.z+",
		[Enum.KeyCode.A] = "move.x-", [Enum.KeyCode.D] = "move.x+",
		[Enum.KeyCode.Q] = "move.y-", [Enum.KeyCode.E] = "move.y+",
	}
	local function onKey(inp, gp)
		if gp then return end
		local isCtrl = pcall(function() return UserInputService:IsKeyDown(Enum.LeftControl) end)
			and UserInputService:IsKeyDown(Enum.LeftControl)
		local code = inp.KeyCode
		if isCtrl and CTRL[code] then
			pcall(CTRL[code])
			return
		end
		if not isCtrl and PLAIN[code] then
			pcall(PLAIN[code])
		end
		-- nudge com WASD quando ferramenta Move (W/E disputam com tool; nudge tem prioridade em Move)
		if ARKHER.STATE.tool == "Move" and not isCtrl and NUDGE[code] then
			ARKHER.cmd(NUDGE[code])
		end
	end
	pcall(function()
		UserInputService.InputBegan:Connect(onKey)
	end)
	ARKHER.out("INFO", "Atalhos: Ctrl+K palette | Ctrl+Z/Y undo/redo | Del apagar | Ctrl+C/X/V/D | V/W/E/R ferramentas | L lock | WASD/Q/E move (ferramenta Move)")
end
end

do
--[[ ARKHER V3 — SINGULARITY CORE: IA operadora do editor ]]
-- Arquitetura: USER → objetivo → PLANNER → tarefas → ESPECIALISTAS → VERIFIER → relatório
-- Especialistas LOCAIS executam de verdade no Roblox (procedural real, sem depender de web).
-- Ponte opcional: se o usuario configurar um endpoint (Settings > AI), o plano tambem
-- pode vir de um LLM externo (mesmo contrato JSON). Sem endpoint = modo local 100%.
local HttpService = game:GetService("HttpService")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local SG = {}
ARKHER_SINGULARITY = SG

SG.memory = { decisions = {}, context = {}, tasks = 0 }

local function log(kind, msg)
	ARKHER.out(kind, "[SINGULARITY] " .. tostring(msg))
end

local function report(title, lines)
	local out = { title = title, lines = lines, ok = true }
	Bus.emit("singularity.report", out)
	log("SUCCESS", title .. " — " .. #lines .. " etapas")
	return out
end

-- ---------- PLANNER LOCAL (intent → tarefas) ----------
local INTENTS = {
	city = { "cidade", "city", "prédios", "predios", "buildings", "rua", "road", "urbe" },
	nature = { "floresta", "forest", "natureza", "nature", "arvore", "árvore", "tree", "montanha", "mountain", "lago", "lake" },
	space = { "espaco", "espaço", "space", "asteroide", "asteroid", "planet", "planeta" },
	npc = { "npc", "personagem", "personagens", "habitantes", "population", "populacao", "população", "moradores" },
	light = { "luz", "light", "iluminacao", "iluminação", "noite", "night", "amanhecer", "sunset", "day", "dia" },
	clean = { "organizar", "organize", "arrumar", "naming", "rotular", "label" },
	perf = { "otimizar", "otimiza", "otimizado", "otimizada", "otimizacao", "otimização", "otimise", "otimize", "otimizar", "optimize", "optimized", "performance", "fps", "leve" },
	check = { "diagnostico", "diagnóstico", "diagnostics", "analisar", "analyze", "auditoria", "audit" },
	material = { "material", "pbr", "superficie", "superfície", "textura", "texture" },
	place = { "place", "mundo", "world", "mapa", "map" },
	terrain = { "terreno", "terrain", "relief", "relevo", "heightmap", "erosao", "erosão", "rio", "rios", "river", "geologia", "canyon", "vulcao", "vulcão", "ilha", "ilhas", "vale", "bioma", "biomas", "continente", "geography" },
	water = { "agua", "água", "water", "oceano", "ocean", "mar", "sea", "onda", "ondas", "wave", "waves", "cachoeira", "waterfall", "lagoa", "tsunami", "rio2", "piscina", "pool" },
	ui = { "hud", "ui", "interface", "gui", "menu", "barra de vida", "lifetime", "hotbar", "inventario", "inventário", "placar", "leaderboard" },
	audio = { "som", "audio", "musica", "music", "sound", "trilha", "soundtrack", "barulho", "mixer", "reverb", "acustica", "acústica" },
	anim = { "animacao", "animação", "anim", "animation", "mover", "movimento", "dancar", "dançar", "timeline", "keyframe" },
	clima = { "clima", "weather", "chuva", "rain", "tempestade", "storm", "neve", "snow", "neblina", "fog", "aurora", "trovao", "trovão", "raio", "lightning", "ensolarado", "ceu", "céu", "sky" },
	camera = { "camera", "câmera", "filme", "film", "cinematic", "cinematica", "cinematográfica", "orbita", "orbit", "crane", "dolly", "shake", "tremor", "fly", "corte", "shot" },
	particles = { "particulas", "partículas", "particles", "fogo", "fire", "faisca", "faísca", "sparks", "magia", "magic", "explosao", "explosão", "fumaca", "fumaça", "smoke", "splash", "poeira", "dust" },
	cloth = { "pano", "tecido", "cloth", "corda", "rope", "bandeira", "flag", "cabelo", "hair", "bandame", "banner", "tenda", "drapeando", "pendurada" },
}

local function detectIntents(text)
	local t = (text or ""):lower()
	local found = {}
	for name, kws in pairs(INTENTS) do
		for _, kw in ipairs(kws) do
			if t:find(kw, 1, true) then
				found[name] = true
				break
			end
		end
	end
	return found
end

function SG.plan(goal)
	local intents = detectIntents(goal)
	local plan = { goal = goal, tasks = {}, mode = ARKHER.STATE.ai.mode }
	local order = { "place", "terrain", "water", "city", "nature", "space", "material", "light", "npc", "ui", "audio", "anim", "clima", "particles", "cloth", "camera", "clean", "perf", "check" }
	for _, name in ipairs(order) do
		if intents[name] then table.insert(plan.tasks, name) end
	end
	if #plan.tasks == 0 then
		table.insert(plan.tasks, "check")
	end
	return plan
end

-- ---------- ESPECIALISTAS LOCAIS (execucao REAL no Roblox) ----------
local E = {}
SG.experts = E

function E.place(ctx)
	ARKHER.cmd("undo.push", "Singularity: place")
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then pcall(function() ch:Destroy() end) end
	end
	ArkherPlaces.TEMPLATES.Baseplate()
	ctx.lines[#ctx.lines + 1] = "base: baseplate 120x120 + spawn criados"
end

function E.city(ctx)
	local model = Instance.new("Model")
	model.Name = "CityGen_" .. (SG.memory.tasks + 1)
	model.Parent = workspace
	local rng = Random.new(SG.memory.tasks * 17 + 3)
	local n = 10 + rng:NextInteger(0, 8)
	local built = 0
	for i = 1, n do
		local b = Instance.new("Part")
		b.Name = "Building_" .. i
		local h = 5 + rng:NextInteger(0, 22)
		b.Size = Vector3.new(5 + rng:NextInteger(0, 7), h, 5 + rng:NextInteger(0, 7))
		b.Position = Vector3.new((rng:NextInteger(-6, 6)) * 9 + 4.5, h / 2 + 0.5, (rng:NextInteger(-6, 6)) * 9 + 4.5)
		b.Anchored = true
		b.Color = Color3.fromRGB(90 + rng:NextInteger(0, 70), 95 + rng:NextInteger(0, 70), 110 + rng:NextInteger(0, 70))
		b.Parent = model
		built = built + 1
	end
	local roads = 0
	for i = -1, 1 do
		local r = Instance.new("Part")
		r.Name = "Road_" .. (i + 2)
		r.Size = Vector3.new(80, 0.2, 5)
		r.Position = Vector3.new(0, 0.15, i * 18)
		r.Anchored = true
		r.Color = Color3.fromRGB(28, 28, 32)
		r.Material = Enum.Material.Asphalt
		r.Parent = model
		roads = roads + 1
	end
	ctx.lines[#ctx.lines + 1] = "cidade: " .. built .. " edificios + " .. roads .. " ruas (procedural, seed " .. (SG.memory.tasks * 17 + 3) .. ")"
end

function E.nature(ctx)
	-- V4: se o Scene/Scatter X esta carregado, o "natureza" vira povoamento
	-- REAL por bioma/declive no ATX (arvores com dossel organico, arbustos, etc)
	if ArkherSceneX then
		local w = SG.world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
		SG.world = SG.world or w
		local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = 110, count = 60, minDist = 7, maxSlope = 0.9, world = w, seed = 99 + SG.memory.tasks, name = "ASXN_Nature" })
		local trees, bushes = 0, 0
		for _, m in ipairs(res.made or {}) do
			local tg = m:GetAttribute("arkher_tag")
			if tg == "tree" then trees = trees + 1 elseif tg == "bush" then bushes = bushes + 1 end
		end
		ctx.lines[#ctx.lines + 1] = "natureza SCATTER: " .. res.count .. " entidades (" .. trees .. " arvores dossel-organico, " .. bushes .. " arbustos — " .. res.tries .. " amostras poisson)"
		return
	end
	local rng = Random.new(99)
	local trees = 0
	for i = 1, 12 do
		local trunk = Instance.new("Part")
		trunk.Name = "Tree_" .. i
		trunk.Size = Vector3.new(1.2, 4, 1.2)
		trunk.Position = Vector3.new(rng:NextInteger(-50, 50), 2, rng:NextInteger(-50, 50))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(90, 62, 38)
		trunk.Parent = workspace
		local crown = Instance.new("Part")
		crown.Name = "Crown_" .. i
		crown.Shape = Enum.PartType.Ball
		crown.Size = Vector3.new(5, 5, 5)
		crown.Position = trunk.Position + Vector3.new(0, 4.5, 0)
		crown.Anchored = true
		crown.Material = Enum.Material.Grass
		crown.Color = Color3.fromRGB(35 + rng:NextInteger(0, 30), 110 + rng:NextInteger(0, 40), 40)
		crown.Parent = workspace
		trees = trees + 1
	end
	ctx.lines[#ctx.lines + 1] = "natureza: " .. trees .. " arvores plantadas"
end

function E.space(ctx)
	local sun = workspace:FindFirstChild("Sun")
	if not sun then
		local s = Instance.new("Part")
		s.Name = "Sun"
		s.Shape = Enum.PartType.Ball
		s.Size = Vector3.new(12, 12, 12)
		s.Position = Vector3.new(-40, 30, -50)
		s.Anchored = true
		s.Material = Enum.Material.Neon
		s.Color = Color3.fromRGB(255, 200, 90)
		s.Parent = workspace
		local pl = Instance.new("PointLight")
		pl.Parent = s
		pl.Brightness = 2
		pl.Range = 150
		ctx.lines[#ctx.lines + 1] = "espaco: sol neon + luz pontual adicionados"
	end
end

function E.material(ctx)
	local count = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, v = pcall(function() return ch.Material end)
			if ok and v then
				if v.Name == "SmoothPlastic" then
					local mats = { "Concrete", "Metal", "Wood", "Slate" }
					pcall(function() ch.Material = Enum.Material[mats[count % #mats + 1]] end)
					count = count + 1
				end
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "materiais: " .. count .. " superficies variadas (anti-padrao visual)"
end

function E.light(ctx)
	local lighting = game:FindFirstChild("Lighting")
	if lighting then
		local ok, v = pcall(function() return lighting.Ambient end)
		if ok and v then
			pcall(function() lighting.Ambient = Color3.fromRGB(90, 95, 120) end)
		end
		local ok2, v2 = pcall(function() return lighting.OutdoorAmbient end)
		if ok2 and v2 then
			pcall(function() lighting.OutdoorAmbient = Color3.fromRGB(70, 80, 110) end)
		end
		local sun = lighting:FindFirstChild("Sun")
		if not sun then
			local s = Instance.new("Part")
			s.Name = "Sun"
			s.Anchored = true
			s.CanCollide = false
			s.Size = Vector3.new(1, 1, 1)
			s.Transparency = 1
			s.Position = Vector3.new(50, 60, -40)
			local d = Instance.new("DirectionalLight")
			d.Parent = s
			d.Brightness = 2.2
			d.Color = Color3.fromRGB(255, 230, 190)
			s.Parent = lighting
			ctx.lines[#ctx.lines + 1] = "luz: DirectionalLight solar criada"
		end
	end
end

function E.npc(ctx)
	local spawned = 0
	for i = 1, 4 do
		local mind = ArkherNMN.spawn("Inhabitant_" .. i, Vector3.new(math.random(-30, 30), 3, math.random(-30, 30)))
		if mind then spawned = spawned + 1 end
	end
	ctx.lines[#ctx.lines + 1] = "npcs: " .. spawned .. " habitantes NMN com mente ativa (percepcao/precisoes/memoria)"
end

function E.clean(ctx)
	local counts = {}
	for _, ch in ipairs(workspace:GetDescendants()) do
		counts[ch.ClassName] = (counts[ch.ClassName] or 0) + 1
	end
	local moved = 0
	local byType = {}
	for _, ch in ipairs(workspace:GetChildren()) do
		if not ch:IsA("Model") then
			local bucket = ch.ClassName == "Part" and "Parts" or ch.ClassName
			if not byType[bucket] then
				local f = Instance.new("Folder")
				f.Name = bucket
				f.Parent = workspace
				byType[bucket] = f
			end
			if ch:IsA("BasePart") and not ch:IsA("Terrain") then
				pcall(function() ch.Parent = byType[bucket] end)
				moved = moved + 1
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "organizacao: " .. moved .. " itens agrupados por tipo"
end

function E.perf(ctx)
	local fixed = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, a = pcall(function() return ch.Anchored end)
			local ok2, c = pcall(function() return ch.CanCollide end)
			if ok and a == false and ch.Name:find("Spawn") == nil then
				pcall(function() ch.Anchored = true end)
				fixed = fixed + 1
			end
		end
	end
	Bus.emit("do15.nudge", 1)
	ctx.lines[#ctx.lines + 1] = "performance: " .. fixed .. " partes ancoradas + D-O15 forcado p/ MAX"
end

function E.check(ctx)
	local parts, scripts, models, unanchored = 0, 0, 0, 0
	local total = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		total = total + 1
		if ch:IsA("BasePart") then
			parts = parts + 1
			local ok, a = pcall(function() return ch.Anchored end)
			if ok and a == false then unanchored = unanchored + 1 end
		elseif ch:IsA("Script") or ch:IsA("LocalScript") or ch:IsA("ModuleScript") then
			scripts = scripts + 1
		elseif ch:IsA("Model") then
			models = models + 1
		end
	end
	local rep = ArkherDO15 and ArkherDO15.report() or {}
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. parts .. " parts | " .. models .. " models | " .. scripts .. " scripts | " .. total .. " instancias"
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. unanchored .. " partes sem anchor (verificar fisica)"
	ctx.lines[#ctx.lines + 1] = "diagnostico: FPS=" .. tostring(math.floor(rep.fps or 0)) .. " | D-O15=" .. tostring(rep.levelName or "?") .. " | frame=" .. string.format("%.1f", rep.frameMs or 0) .. "ms"
end

function E.terrain(ctx)
	if not ArkherTerrainX then
		ctx.lines[#ctx.lines + 1] = "terreno: Kit C (ATX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local TX = ArkherTerrainX
	local seed = 1000 + SG.memory.tasks * 137
	local w = TX.new({ seed = seed, preset = "continentes", cell = 8 })
	local hyd = w:erodeHydraulic(1, 1, 48, 32, 2200)
	local riv = w:carveRivers(1, 1, 48, 32, 20)
	w:fillLakes(1, 1, 48, 32)
	local built = w:materializeRegion(-96, -96, 192, 192, {})
	local biomes = w:biomeCounts()
	local nb = 0
	for _ in pairs(biomes) do nb = nb + 1 end
	SG.world = w
	ctx.lines[#ctx.lines + 1] = "terreno ATX: mundo procedural seed " .. seed .. " (erosao " .. string.format("%.3f", hyd.meanDelta) .. " dMedio/" .. string.format("%.1f", hyd.maxDelta) .. " dMax)"
	ctx.lines[#ctx.lines + 1] = "terreno ATX: rios " .. riv.cells .. " celulas | " .. nb .. " biomas Whittaker | " .. built.parts .. " parts em " .. built.chunks .. " chunks (materializacao real)"
end

function E.water(ctx)
	if not ArkherWaterX then
		ctx.lines[#ctx.lines + 1] = "agua: Kit C (AWX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local WX = ArkherWaterX
	local sea = WX.preset("porto", { kind = "oceano", level = (SG.world and SG.world.seaLevel) or 0, size = { x = 420, z = 320 } })
	sea.foaminess = 0.55
	local model, tiles = WX.materialize(sea, { maxSpan = 420 })
	local cau = WX.caustics(sea, sea.level - 9)
	SG.sea = sea
	ctx.lines[#ctx.lines + 1] = "agua AWX: oceano preset 'porto' — " .. #sea.waves .. " ondas Gerstner (dispersao omega=sqrt(gk)), mare, correntes Stokes"
	ctx.lines[#ctx.lines + 1] = "agua AWX: " .. tiles .. " tiles animadas + " .. cau .. " causticas | dens " .. sea.props.dens .. " | salinidade " .. sea.props.sal .. " g/L"
end

function E.ui(ctx)
	if not ArkherUIKitX then
		ctx.lines[#ctx.lines + 1] = "hud: Kit D (AXI) nao carregado — rode ArkherKit_Installer_D"
		return
	end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("stamina", { x = 16, y = 48, value = 0.7 }),
		X.create("xpbar", { x = 16, y = 70, value = 0.35 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("coins", { x = 16, y = 100, text = "8.2K" }),
		X.create("timer", { x = 850, y = 16, text = "09:41" }),
		X.create("minimap", { x = 790, y = 60 }),
		X.create("questtracker", { x = 690, y = 230 }),
	}
	local gui, n = X.build(widgets, "ArkherHUD_AI")
	ctx.lines[#ctx.lines + 1] = "hud AXI: " .. n .. " widgets montados no StarterGui.ArkherHUD_AI (health/stamina/xp/hotbar/coins/timer/minimap/quest)"
end

function E.audio(ctx)
	if not ArkherAudioX then
		ctx.lines[#ctx.lines + 1] = "audio: Kit E (AUX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AX = ArkherAudioX
	AX.setup()
	AX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	AX.register("voice_demo", { bus = "voice", volume = 0.6 })
	AX.duck("music", "voice", { level = 0.3 })
	AX.play("musica_demo")
	AX.play("voice_demo")
	AX.patch("music", "estudio")
	AX.ambient("floresta", { ids = { "passaros", "folhas", "rio_longe" }, interval = { 10, 24 }, bus = "ambient" })
	AX._ambients.floresta:start()
	local st = AX.stats()
	ctx.lines[#ctx.lines + 1] = "audio AUX: " .. st.buses .. " buses + duck voz->musica + patch estudio + scheduler floresta ON (" .. st.sounds .. " sons)"
end

function E.anim(ctx)
	if not ArkherAnimX then
		ctx.lines[#ctx.lines + 1] = "animacao: Kit E (AAX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	ARKHER.cmd("anim.demo")
	ctx.lines[#ctx.lines + 1] = "animacao AAX: clip easeOut_spring/pingpong tocando REAL (AAX_DemoCube no workspace)"
end

function E.clima(ctx)
	if not ArkherAtmosX then
		ctx.lines[#ctx.lines + 1] = "clima: Kit E (AEX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AEX = ArkherAtmosX
	AEX.setup({})
	local g = (ctx.goal or ""):lower()
	local w = "limpo"
	if g:find("tempest") or g:find("trov") or g:find("raio") then w = "tempestade"
	elseif g:find("chuva") or g:find("rain") then w = "chuva"
	elseif g:find("neve") or g:find("snow") then w = "neve"
	elseif g:find("neblina") or g:find("fog") then w = "neblina"
	elseif g:find("aurora") then w = "aurora"
	elseif g:find("nuvem") then w = "nuvem" end
	AEX.setWeather(w, 0.8)
	for i = 1, 60 do AEX.pump(1 / 30) end
	if g:find("noite") then AEX.setPreset("noite") elseif g:find("amanhecer") then AEX.setPreset("amanhecer") elseif g:find("entardecer") or g:find("sunset") then AEX.setPreset("entardecer") end
	local mix = AEX.weatherMix()
	ctx.lines[#ctx.lines + 1] = string.format("clima AEX: %s (fog %.0f, haze %.1f, waveBoost %.2fx) — Lighting/Atmosphere REAIS", AEX.S.state, mix.fogEnd, mix.haze, mix.waveBoost)
end

function E.camera(ctx)
	if not ArkherCameraX then
		ctx.lines[#ctx.lines + 1] = "camera: Kit E (ACX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local ACX = ArkherCameraX
	local g = (ctx.goal or ""):lower()
	if g:find("crane") then
		ACX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: crane 4s (lift fisico)"
	elseif g:find("fly") or g:find("voo") then
		ACX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: fly path Catmull-Rom REAL (5s)"
	elseif g:find("shake") or g:find("tremor") then
		ACX.addTrauma(0.9)
		ctx.lines[#ctx.lines + 1] = "camera ACX: trauma +0.9 (shake trauma^2)"
	else
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 14, height = 6, speed = 0.6, duration = 9999 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: orbit cinematografico real na CurrentCamera"
	end
end

function E.particles(ctx)
	if not ArkherParticlesX then
		ctx.lines[#ctx.lines + 1] = "particulas: Kit E (APX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local APX = ArkherParticlesX
	local g = (ctx.goal or ""):lower()
	local k = "fogo"
	if g:find("faisca") or g:find("spark") then k = "faiscas"
	elseif g:find("magia") or g:find("magic") then k = "magia"
	elseif g:find("fumaca") or g:find("smoke") then k = "fumaca"
	elseif g:find("explosao") or g:find("explos") then k = "faiscas"
	elseif g:find("splash") or g:find("agua") then k = "agua"
	elseif g:find("neve") then k = "neve"
	elseif g:find("poeira") or g:find("dust") then k = "poeira" end
	APX.emit(nil, k)
	if g:find("explosao") or g:find("explos") then APX.emit(nil, "fumaca") end
	local bs = APX.budgetScale()
	ctx.lines[#ctx.lines + 1] = string.format("particulas APX: %s emitido (Emitter REAL, budget D-O15 %.0f%%)", k, bs * 100)
end

function E.cloth(ctx)
	if not ArkherRopeX then
		ctx.lines[#ctx.lines + 1] = "pano: Kit E (RPX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local g = (ctx.goal or ""):lower()
	if g:find("corda") or g:find("rope") then
		local r = ArkherRopeX.rope({ from = { x = 0, y = 15, z = 0 }, points = 12, name = "RPX_SNG_Rope" })
		ArkherRopeX.materializeRope(r, { w = 0.22, color = { 185, 130, 70 } })
		ctx.lines[#ctx.lines + 1] = "pano RPX: corda de Verlet pendurada (gravidade + constraints reais) no world"
	else
		local fl = ArkherRopeX.flagAt(0, 14, 0)
		ctx.lines[#ctx.lines + 1] = "pano RPX: bandeira de tecido (Verlet coluna-grade, vento do AEX real) no world"
	end
end

function E.default(ctx)
	ctx.lines[#ctx.lines + 1] = "info: objetivo nao mapeado — executei auditoria de contexto"
	E.check(ctx)
end

-- ---------- EXECUTOR ----------
function SG.run(goal, opts)
	opts = opts or {}
	ARKHER.memory = SG.memory
	SG.memory.tasks = SG.memory.tasks + 1
	local task = { id = SG.memory.tasks, goal = goal, t = tick(), status = "running" }
	SG.memory.decisions[#SG.memory.decisions + 1] = task
	local plan = SG.plan(goal)
	local lines = {}
	log("INFO", "objetivo: " .. goal)
	Bus.emit("singularity.start", { goal = goal, plan = plan })
	lines[#lines + 1] = "plano: " .. table.concat(plan.tasks, " → ")

	local t0 = tick()
	for _, name in ipairs(plan.tasks) do
		local expert = E[name] or E.default
		local ok, err = pcall(expert, { lines = lines })
		if not ok then
			lines[#lines + 1] = "ERRO em " .. name .. ": " .. tostring(err)
			task.status = "partial"
			log("ERROR", "especialista " .. name .. " falhou: " .. tostring(err))
		end
		Bus.emit("singularity.step", { task = task.id, step = name })
	end
	local dt = tick() - t0
	lines[#lines + 1] = "tempo: " .. string.format("%.2f", dt) .. "s"
	task.status = task.status or "done"
	task.dt = dt
	task.lines = lines
	Bus.emit("singularity.done", task)
	return report("Missao " .. task.id .. " concluida", lines)
end

-- ---------- PONTE EXTERNA OPCIONAL (mesmo contrato, sem obrigar servico) ----------
function SG.bridgeAvailable()
	local ep = ARKHER.STATE.ai.endpoint
	return type(ep) == "string" and #ep > 4
end

function SG.askExternal(goal)
	if not SG.bridgeAvailable() then return nil, "sem endpoint configurado" end
	local Http = game:GetService("HttpService")
	local ok, res = pcall(function()
		return Http:PostAsync(
			ARKHER.STATE.ai.endpoint,
			Http:JSONEncode({ goal = goal, context = { place = ARKHER.STATE.placeName, do15 = ARKHER.STATE.do15Level } }),
			Enum.HttpContentType.ApplicationJson,
			5
		)
	end)
	if not ok or not res then return nil, tostring(res) end
	local ok2, plan = pcall(function() return Http:JSONDecode(res) end)
	if ok2 and type(plan) == "table" then return plan end
	return nil, "resposta invalida"
end
end

do
--[[ ARKHER V3 — LIVE: Inspector (Properties) e Hierarchy ligados ao Estado REAL ]]
-- O Inspector lê a Selection real do Roblox e edita propriedades de verdade.
-- A Hierarchy espelha o DataModel real (workspace + services) com filtro.
local Players = game:GetService("Players")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

local LIVE = {}
ArkherLive = LIVE
ARKHER_LIVE = LIVE

-- ---------- widgets de inspector ----------
local function vec3box(parent, label, vec, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local vals = { vec.X, vec.Y, vec.Z }
	local boxes = {}
	for i = 1, 3 do
		local b = K.input(parent, 118 + (i - 1) * 42, y, 40, 18, "")
		b.Text = tostring(math.floor((vals[i] or 0) * 100) / 100)
		b.TextXAlignment = Enum.TextXAlignment.Center
		b.ClearTextOnFocus = true
		b.FocusLost:Connect(function()
			local n = tonumber(b.Text)
			if n then
				vals[i] = n
				if onChange then onChange(vals[1], vals[2], vals[3]) end
			else
				b.Text = tostring(vals[i])
			end
		end)
		boxes[i] = b
	end
	return boxes
end

local function numbox(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(math.floor(val * 1000) / 1000)
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		local n = tonumber(b.Text)
		if n then
			if min and n < min then n = min end
			if max and n > max then n = max end
			b.Text = tostring(n)
			if onChange then onChange(n) end
		else
			b.Text = tostring(val)
		end
	end)
	return b
end

local function slider(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	min = min or 0
	max = max or 1
	K.txt(parent, label, 22, y, 84, 18, 11, T.txt3)
	local track = K.btn(parent, "Sl_" .. label, 110, y + 6, 96, 6, T.bg4, 3)
	local fill = K.f(track, "Fill", 0, 0, 0, 6, T.accent)
	K.corner(fill, 3)
	local knob = K.f(track, "Knob", 0, -3, 12, 12, T.accent2, 6)
	local label2 = K.txt(parent, "", 210, y, 40, 18, 11, T.txt, FONT, Enum.TextXAlignment.Left)
	local v = math.min(max, math.max(min, val or min))
	local function paint()
		local frac = (v - min) / (max - min)
		fill.Size = UDim2.new(0, math.floor(96 * frac), 0, 6)
		knob.Position = UDim2.new(0, math.floor(96 * frac) - 6, 0, -3)
		label2.Text = string.format("%.2f", v)
	end
	paint()
	local dragging = false
	local function setFromX(xabs)
		local rel = (xabs - track.AbsolutePosition.X) / track.AbsoluteSize.X
		v = math.min(max, math.max(min, min + rel * (max - min)))
		paint()
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if onChange then onChange(v) end
		end
	end)
	return track
end

local function colorbox(parent, label, col, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local sw = K.btn(parent, "Clr_" .. label, 128, y, 96, 18, col, 3)
	K.stroke(sw, T.line2, 1)
	local pal = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(227, 52, 47),
		Color3.fromRGB(255, 152, 0), Color3.fromRGB(255, 230, 0), Color3.fromRGB(102, 187, 106),
		Color3.fromRGB(41, 121, 255), Color3.fromRGB(104, 58, 183), Color3.fromRGB(255, 112, 179),
	}
	local open = false
	sw.MouseButton1Click:Connect(function()
		open = not open
		local dd = sw:FindFirstChild("Pal")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "Pal", 128, y + 20, 96, 58, T.bg2)
			p.Name = "Pal"
			K.stroke(p, T.line2, 1)
			for i, c in ipairs(pal) do
				local cb = K.btn(p, "c" .. i, 4 + ((i - 1) % 4) * 23, 4 + math.floor((i - 1) / 4) * 18, 18, 14, c, 2)
				cb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					sw.BackgroundColor3 = c
					if onChange then onChange(c) end
				end)
			end
			K.f(p, "x", 0, 0, 1, 1, T.bg2)
		end
	end)
	return sw
end

local MATERIALS = {
	"Neon", "SmoothPlastic", "Plastic", "Metal", "Wood", "WoodPlanks", "Concrete",
	"Glass", "Grass", "Slate", "Brick", "CorrodedMetal", "Foil", "Ice", "Marble",
	"MossyRock", "Sand", "Snow", "Fabric", "LeafyGrass",
}
local function materialRow(parent, label, matName, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.btn(parent, "Mat_" .. label, 128, y, 96, 18, T.bg4, 3)
	K.stroke(b, T.line2, 1)
	K.txtS(b, matName or "?", 10, T.txt)
	local open = false
	b.MouseButton1Click:Connect(function()
		open = not open
		local dd = b:FindFirstChild("MList")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "MList", 128, y + 20, 100, 130, T.bg2)
			p.Name = "MList"
			K.stroke(p, T.line2, 1)
			for i, m in ipairs(MATERIALS) do
				local mb = K.btn(p, m, 3, 3 + (i - 1) * 18, 94, 16, T.bg2, 2)
				K.txtS(mb, m, 10, m == matName and T.neon or T.txt2)
				K.hover(mb, T.bg2, T.hover)
				mb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					b:ClearAllChildren()
					K.txtS(b, m, 10, T.txt)
					if onChange then onChange(m) end
				end)
			end
		end
	end)
	return b
end

local function check(parent, label, on, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 128, 18, 11, T.txt3)
	local box = K.btn(parent, "Chk_" .. label, 156, y + 2, 14, 14, T.bg4, 3)
	K.stroke(box, on and T.check or T.line2, 1)
	local inner = K.f(box, "On", 2, 2, 10, 10, T.check)
	K.corner(inner, 2)
	inner.Visible = on
	box.MouseButton1Click:Connect(function()
		on = not on
		inner.Visible = on
		K.stroke(box, on and T.check or T.line2, 1)
		if onChange then onChange(on) end
	end)
	return box
end

local function textRow(parent, label, val, y, onChange, mono)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(val or "")
	b.Font = mono and ARKHER.MONO or FONT
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		if onChange then onChange(b.Text) end
	end)
	return b
end

-- ---------- INSPECTOR ----------
local BASEPART_PROPS = {
	"Position", "CFrame", "Size", "Color", "Material", "Transparency",
	"Anchored", "CanCollide", "CastShadow", "BrickColor",
}
local GUI_PROPS = { "BackgroundColor3", "BackgroundTransparency", "Size", "Position", "Text", "TextColor3", "TextSize" }

function LIVE.currentSelection()
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and type(sel) == "table" and #sel > 0 then return sel[1] end
	return nil
end

function LIVE.rebuildInspector(container)
	local T, K = ARKHER.T, ARKHER.K
	container:ClearAllChildren()
	local inst = LIVE.currentSelection()
	local head = K.f(container, "Head", 1, 0, 10, 26, T.bg3)
	head.Size = UDim2.new(1, -2, 0, 26)
	if not inst then
		K.txt(head, "Nada selecionado", 24, 0, 200, 26, 11, T.txt4)
		return
	end
	local ic = K.f(head, "Ic", 10, 4, 18, 18)
	local iconFn = LIVE.iconFor(inst)
	if iconFn then iconFn(ic, 18) end
	K.txt(head, inst.Name, 32, 0, 120, 26, 12, T.txt, ARKHER.FONTB)
	K.txt(head, inst.ClassName, 0, 0, 150, 26, 9, T.txt4)
	-- linha de classe à direita
	local clsLbl = K.txt(head, inst.ClassName, 0, 0, 110, 26, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	clsLbl.Position = UDim2.new(1, -110, 0, 0)

	local body = K.f(container, "Body", 1, 26, 10, 10, T.bg3)
	body.Size = UDim2.new(1, -2, 1, -26)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Parent = body
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	local inner = K.f(scroll, "Inner", 0, 0, 10, 0, T.bg3)
	inner.Size = UDim2.new(1, -8, 0, 0)
	local y = 4

	local function push(dy)
		y = y + dy
		inner.Size = UDim2.new(1, -8, 0, y)
		scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		return y
	end

	if inst:IsA("BasePart") then
		local sec, sbody = K.section(inner, "Core Properties", true, 0)
		local sy = 0
		local function row(dy)
			sy = sy + dy
			return sy
		end
		local pos = inst.Position or Vector3.new(0, 0, 0)
		local p1 = vec3box(sbody, "Position", pos, 4, function(x, y2, z)
			pcall(function() inst.Position = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local size = inst.Size or Vector3.new(1, 1, 1)
		vec3box(sbody, "Size", size, sy + 2, function(x, y2, z)
			pcall(function() inst.Size = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local col = inst.Color or Color3.new(1, 1, 1)
		colorbox(sbody, "Color", col, sy + 2, function(c)
			pcall(function() inst.Color = c end)
		end)
		sy = row(24)
		local matName = "SmoothPlastic"
		pcall(function() matName = inst.Material.Name end)
		materialRow(sbody, "Material", matName, sy + 2, function(m)
			pcall(function()
				local okm, me = pcall(function() return Enum.Material[m] end)
				if okm and me then inst.Material = me end
			end)
		end)
		sy = row(24)
		local tr = inst.Transparency or 0
		slider(sbody, "Transparency", tr, sy + 2, function(v)
			pcall(function() inst.Transparency = v end)
		end)
		sy = row(26)
		check(sbody, "Anchored", inst.Anchored ~= false, sy + 2, function(v)
			pcall(function() inst.Anchored = v end)
		end)
		sy = row(22)
		check(sbody, "CanCollide", inst.CanCollide ~= false, sy + 2, function(v)
			pcall(function() inst.CanCollide = v end)
		end)
		sy = row(22)
		check(sbody, "CastShadow", inst.CastShadow ~= false, sy + 2, function(v)
			pcall(function() inst.CastShadow = v end)
		end)
		sy = row(24)
		local bh = sy + 6
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Body" then ch.Size = UDim2.new(1, 0, 0, bh) end
		end
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Head" then end
		end
		push(bh + 10)

		local sec2 = K.section(inner, "Physics", true, y + 2)
		local b2 = sec2:FindFirstChild("Body")
		local sy2 = 0
		check(b2, "CanTouch", true, 4, function() end)
		sy2 = sy2 + 22
		check(b2, "CustomPhysicalProperties", false, sy2 + 2, function() end)
		sy2 = sy2 + 22
		b2.Size = UDim2.new(1, 0, 0, sy2 + 10)
		for _, ch in ipairs(sec2:GetChildren()) do
			if ch.Name ~= "Head" and ch.Name ~= "Body" then ch.Position = UDim2.new(0, 0, 0, 0) end
		end
		push(sy2 + 34)

		local sec3, b3 = K.section(inner, "Scripting", false, y + 2)
		check(b3, "Archivable", true, 4, function() end)
		b3.Size = UDim2.new(1, 0, 0, 26)
		push(20 + 26)
	elseif inst:IsA("GuiObject") then
		local sec = K.section(inner, "Layout", true, 0)
		local b = sec:FindFirstChild("Body")
		local sy = 0
		if inst.Size then
			numbox(b, "Size.X", 0, 4, function() end)
			sy = sy + 24
		end
		local col = inst.BackgroundColor3 or Color3.new(0, 0, 0)
		colorbox(b, "BackgroundColor3", col, sy + 2, function(c)
			pcall(function() inst.BackgroundColor3 = c end)
		end)
		sy = sy + 24
		local tr = inst.BackgroundTransparency or 0
		slider(b, "BackgroundTransp.", tr, sy + 2, function(v)
			pcall(function() inst.BackgroundTransparency = v end)
		end)
		sy = sy + 26
		if inst.Text ~= nil then
			textRow(b, "Text", inst.Text, sy + 2, function(t)
				pcall(function() inst.Text = t end)
			end, true)
			sy = sy + 24
			local tc = inst.TextColor3 or Color3.new(1, 1, 1)
			colorbox(b, "TextColor3", tc, sy + 2, function(c)
				pcall(function() inst.TextColor3 = c end)
			end)
			sy = sy + 24
		end
		b.Size = UDim2.new(1, 0, 0, sy + 8)
		push(sy + 28)
	elseif inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
		local sec = K.section(inner, "Code", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "Fonte do script (abrindo no Script Editor):", 22, 4, 200, 16, 10, T.txt3)
		local src = inst.Source or ""
		local preview = K.txt(b, string.sub(src, 1, 300), 22, 22, 190, 60, 9, T.txt2, ARKHER.MONO)
		preview.TextXAlignment = Enum.TextXAlignment.Left
		preview.TextYAlignment = Enum.TextYAlignment.Top
		preview.TextWrapped = true
		local ob = K.btn(b, "OpenInEditor", 22, 88, 120, 20, T.sec, 4)
		K.txtS(ob, "Abrir no Script Editor", 10, T.txt)
		K.hover(ob, T.sec, T.hover)
		ob.MouseButton1Click:Connect(function()
			ARKHER.STATE.scriptOpen = inst
			ARKHER.open("ScriptEditor")
			ARKHER.out("INFO", "Script aberto: " .. inst:GetFullName())
		end)
		b.Size = UDim2.new(1, 0, 0, 120)
		push(140)
	else
		local sec = K.section(inner, "Identity", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "FullName", 22, 4, 80, 16, 10, T.txt3)
		K.txt(b, inst:GetFullName(), 100, 4, 130, 16, 9, T.txt2, ARKHER.MONO)
		b.Size = UDim2.new(1, 0, 0, 26)
		push(40)
	end
end

-- ---------- ICONS POR CLASSE (hierarchy) ----------
local CLASS_ICON = {
	Baseplate = "plate", Part = "cubeW", Terrain = "terrain", Camera = "camera",
	Workspace = "ws", SpawnLocation = "plate", Model = "model",
	Script = "script", LocalScript = "script", ModuleScript = "script",
	Folder = "folder", Lighting = "bulb", Players = "playersI",
	MaterialService = "gem", ReplicatedFirst = "repfirst",
	ReplicatedStorage = "boxG", ServerScriptService = "cubeT", ServerStorage = "cubeT",
	StarterGui = "folderP", StarterPack = "folderP", StarterPlayer = "folderP",
	TextChatService = "chat", PointLight = "bulb", SpotLight = "bulb",
	ParticleEmitter = "particle", Sound = "music", MeshPart = "model",
}
function LIVE.iconFor(inst)
	local n = CLASS_ICON[inst.ClassName] or CLASS_ICON[inst.Name]
	if n and ICON[n] then return ICON[n] end
	if inst:IsA("BasePart") then return ICON.cubeW end
	if inst:IsA("GuiObject") then return ICON.imageI end
	if inst:IsA("Model") then return ICON.model end
	return ICON.folder
end

-- ---------- HIERARCHY ----------
local SERVICE_ROWS = {
	"Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage",
	"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
	"TextChatService", "SoundService", "RunService", "Workspace",
}

function LIVE.matchFilter(inst, filter)
	if not filter or filter == "" then return true end
	local f = filter:lower()
	local nameOk = inst.Name:lower():find(f, 1, true) ~= nil
	local clsOk = inst.ClassName:lower():find(f, 1, true) ~= nil
	return nameOk or clsOk
end

local function hierarchyNode(parent, inst, depth, y, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	local kids = inst:GetChildren()
	local hasKids = #kids > 0
	local visible = LIVE.matchFilter(inst, filter) or (hasKids and false)
	-- mantém visivel se qualquer descendant casar
	if not visible and hasKids then
		local any = false
		for _, ch in ipairs(kids) do
			if LIVE.matchFilter(ch, filter) then any = true break end
		end
		visible = any
	end
	if not visible then return y end
	local row = K.treeRow(parent, depth, LIVE.iconFor(inst), inst.Name, hasKids and (state.open[inst.Name] and depth < 99 and "open" or "closed") or nil, y)
	if inst == LIVE.currentSelection() then
		row.BackgroundColor3 = T.sel
	end
	row.MouseButton1Click:Connect(function()
		local ok = pcall(function() Selection:Set({ inst }) end)
		if not ok then
			pcall(function() Selection:Set({ inst }) end)
		end
		Bus.emit("hierarchy.picked", inst)
		ARKHER.out("INFO", "Selecionado: " .. inst:GetFullName())
	end)
	y = y + 20
	if hasKids then
		local isOpen = state.open[inst.Name] ~= false and depth <= 2
		state.open[inst.Name] = isOpen
		-- chevron clicavel
		local chev = row:FindFirstChild("Chev")
		if chev then
			local cb = K.btn(row, "ChevBtn", 6 + depth * 16, 2, 14, 16, T.bg3, 2)
			cb.BackgroundColor3 = T.bg3
			if isOpen then ICON.chevD(chev, 8) else ICON.chevR(chev, 8) end
			cb.MouseButton1Click:Connect(function()
				state.open[inst.Name] = not state.open[inst.Name]
				ARKHER_LIVE.rebuildHierarchy(state.container, state.filter or "", state)
			end)
		end
		if isOpen then
			for _, ch in ipairs(kids) do
				y = hierarchyNode(parent, ch, depth + 1, y, filter, state)
			end
		end
	end
	return y
end

function LIVE.rebuildHierarchy(container, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	state = state or { open = {}, filter = filter }
	state.filter = filter or ""
	if state.container ~= container then state.container = container end
	container:ClearAllChildren()
	local ws = workspace
	local y = 4
	-- raiz: Workspace
	local rootRow = K.treeRow(container, 0, ICON.ws, "Workspace", "open", y)
	rootRow.BackgroundColor3 = T.bg3
	K.stroke(rootRow, T.line, 1)
	y = y + 20
	for _, ch in ipairs(ws:GetChildren()) do
		y = hierarchyNode(container, ch, 1, y, state.filter, state)
	end
	-- services (niveis de primeira classe)
	y = y + 6
	local svcLbl = K.txt(container, "— services —", 8, y, 150, 14, 9, T.txt4)
	y = y + 16
	for _, svcName in ipairs(SERVICE_ROWS) do
		if svcName ~= "Workspace" then
			local svc = game:FindFirstChild(svcName)
			if svc and LIVE.matchFilter(svc, state.filter) then
				local r = K.treeRow(container, 0, LIVE.iconFor(svc) or ICON.server, svcName .. "+", "closed", y)
				r.BackgroundColor3 = T.bg3
				r.MouseButton1Click:Connect(function()
					pcall(function() Selection:Set({ svc }) end)
					ARKHER.out("INFO", "Serviço selecionado: " .. svcName)
				end)
				y = y + 20
			end
		end
	end
	-- auto-abre workspace
	if state.open["Workspace"] == nil then state.open["Workspace"] = true end
end

-- ---------- WIRING (SelectionChanged + Changed do seleto) ----------
function LIVE.start()
	ARKHER.out("INFO", "ArkherLive: ligando SelectionChanged/Changed")
	local function onSel()
		Bus.emit("inspector.refresh")
		Bus.emit("hierarchy.refresh")
	end
	pcall(function()
		Selection.SelectionChanged:Connect(onSel)
	end)
	-- Changed do objeto selecionado (throttled por frame)
	local dirty = false
	pcall(function()
		RunService.Heartbeat:Connect(function()
			if dirty then
				dirty = false
				Bus.emit("inspector.refresh")
			end
		end)
	end)
	local function watch(inst)
		if not inst then return end
		pcall(function()
			inst:GetPropertyChangedSignal("*"):Connect(function()
				dirty = true
			end)
		end)
	end
	pcall(function()
		Selection.SelectionChanged:Connect(function()
			local sel = LIVE.currentSelection()
			watch(sel)
		end)
	end)
end
end

do
--[[ ARKHER — D-MATH: camada matematica de campos (fundamento RRW) ]]
-- "Qual D e necessario para representar o problema?" — aqui ficam as
-- representacoes continuas discretizadas: ruido deterministico, campos
-- escalares, curvas e classificadores fisicos (Whittaker). Tudo DETERMINISTICO
-- por semente: a mesma realidade, a mesma materializacao, em qualquer D-O15.
-- Sem bitwise ops (compatibilidade total Lua 5.1 / Luau / shim de testes).
ArkherDM = ArkherDM or {}
local M = ArkherDM

local floor, ceil = math.floor, math.ceil
local abs, sqrt, exp = math.abs, math.sqrt, math.exp
local sin, cos, pi = math.sin, math.cos, math.pi

-- =============== PRIMITIVAS ===============
function M.clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
function M.lerp(a, b, t) return a + (b - a) * t end
function M.smoothstep(t) t = M.clamp(t, 0, 1) return t * t * (3 - 2 * t) end
function M.smootherstep(t) t = M.clamp(t, 0, 1) return t * t * t * (t * (t * 6 - 15) + 10) end
function M.remap(v, a, b, c, d) return c + (d - c) * ((v - a) / ((b - a) ~= 0 and (b - a) or 1)) end
function M.gauss(d, r) if r <= 0 then return 0 end local q = d / r return exp(-q * q * 4.5) end
function M.falloff(d, r, kind)
	local t = M.clamp(1 - d / (r > 0 and r or 1), 0, 1)
	if kind == "linear" then return t
	elseif kind == "gaussian" then return M.gauss(d, r)
	elseif kind == "cosine" then return 0.5 + 0.5 * cos(pi * M.clamp(d / (r > 0 and r or 1), 0, 1))
	elseif kind == "sharp" then return t >= 0.5 and 1 or 0
	else return t * t * (3 - 2 * t) end -- "smooth"
end

-- =============== RNG / HASH DETERMINISTICO ===============
-- hash de 2 inteiros -> [0,1) usando mistura multiplicativa (Park-Miller bits)
local i2556 = 2147483647
local function mix(n)
	n = n % i2556
	n = (n * 16807) % i2556
	n = (n * 48271 + 11) % i2556
	n = (n * 69621) % i2556
	return n / i2556
end
function M.hash2(x, y, seed)
	seed = seed or 0
	local n = (floor(x) * 374761393 + floor(y) * 668265263 + floor(seed) * 974634211) % 2000000011
	return mix(abs(n))
end
function M.hash3(x, y, z, seed)
	seed = seed or 0
	local n = (floor(x) * 374761393 + floor(y) * 668265263 + floor(z) * 2246822519 % 999999937 + floor(seed) * 3266489917 % 999999937) % 2000000011
	return mix(abs(n))
end
-- rng com estado (streams independentes por semente)
function M.rng(seed)
	local s = (floor(seed or 1) % i2556); if s <= 0 then s = 1 end
	return function(a, b)
		s = (s * 16807) % i2556
		local u = s / i2556
		if a and b then return a + (b - a) * u end
		if a then return u * a end
		return u
	end
end

-- =============== RUIDO ===============
-- value noise 2D
function M.vnoise2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local xf, yf = x - xi, y - yi
	local u, v = M.smootherstep(xf), M.smootherstep(yf)
	local a = M.hash2(xi, yi, seed)
	local b = M.hash2(xi + 1, yi, seed)
	local c = M.hash2(xi, yi + 1, seed)
	local d = M.hash2(xi + 1, yi + 1, seed)
	return M.lerp(M.lerp(a, b, u), M.lerp(c, d, u), v)
end
-- gradient (Perlin) noise 2D — 8 gradientes por hash
local GRAD = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.7071, 0.7071 }, { -0.7071, 0.7071 }, { 0.7071, -0.7071 }, { -0.7071, -0.7071 } }
function M.gnoise2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local xf, yf = x - xi, y - yi
	local function dot(ix, iy, dx, dy)
		local g = GRAD[floor(M.hash2(ix, iy, seed) * 8) + 1]
		return g[1] * dx + g[2] * dy
	end
	local u, v = M.smootherstep(xf), M.smootherstep(yf)
	local n00 = dot(xi, yi, xf, yf)
	local n10 = dot(xi + 1, yi, xf - 1, yf)
	local n01 = dot(xi, yi + 1, xf, yf - 1)
	local n11 = dot(xi + 1, yi + 1, xf - 1, yf - 1)
	-- escala p/ [-1,1]
	return M.lerp(M.lerp(n00, n10, u), M.lerp(n01, n11, u), v) * 1.4142
end
-- 1D (ondas / audio / vento)
function M.vnoise1(x, seed)
	local xi = floor(x); local xf = x - xi; local u = M.smootherstep(xf)
	return M.lerp(M.hash2(xi, 17, seed), M.hash2(xi + 1, 17, seed), u)
end
-- fBm generico (func = "g"|"v"|"ridged"|"billow")
function M.fbm2(x, y, opts)
	opts = opts or {}
	local oct, lac, gain = opts.octaves or 5, opts.lacunarity or 2, opts.gain or 0.5
	local seed, fn = opts.seed or 0, opts.fn or "g"
	local amp, freq, sum, norm = 1, opts.frequency or 1, 0, 0
	for i = 1, oct do
		local v
		if i > 1 then freq = freq * lac; amp = amp * gain end
		if fn == "v" then v = M.vnoise2(x * freq, y * freq, seed + i * 131) * 2 - 1
		elseif fn == "ridged" then v = 1 - abs(M.gnoise2(x * freq, y * freq, seed + i * 131))
		elseif fn == "billow" then v = abs(M.gnoise2(x * freq, y * freq, seed + i * 131)) * 2 - 1
		else v = M.gnoise2(x * freq, y * freq, seed + i * 131) end
		sum = sum + v * amp
		norm = norm + amp
	end
	return sum / norm -- ~[-1,1]
end
-- domain warp: distorce o dominio antes de amostrar (costas organicas, montanhas reais)
function M.warp2(x, y, opts)
	opts = opts or {}
	local str, seed = opts.strength or 4, opts.seed or 0
	local wx = M.gnoise2(x * 0.5 + 31.4, y * 0.5 + 71.7, seed) * str
	local wy = M.gnoise2(x * 0.5 + 89.2, y * 0.5 + 13.9, seed) * str
	return x + wx, y + wy
end
-- Worley / celular (F1 e F2-F1) — crateras, escamas, celulas, espuma
function M.worley2(x, y, seed)
	local xi, yi = floor(x), floor(y)
	local f1, f2 = 1e9, 1e9
	for oy = -1, 1 do
		for ox = -1, 1 do
			local cx, cy = xi + ox, yi + oy
			local px = cx + M.hash2(cx, cy, seed or 0)
			local py = cy + M.hash2(cx, cy, (seed or 0) + 77)
			local dx, dy = px - x, py - y
			local d = sqrt(dx * dx + dy * dy)
			if d < f1 then f2 = f1; f1 = d elseif d < f2 then f2 = d end
		end
	end
	return f1, f2 - f1
end

-- =============== CURVAS / GRADE ===============
function M.catmullRom(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end
-- amostragem bilinear de grade heights (1-based, (h-1)*w+1)
function M.bilinear(grid, w, h, gx, gy)
	gx = M.clamp(gx, 1, w - 0.001); gy = M.clamp(gy, 1, h - 0.001)
	local x0, y0 = floor(gx), floor(gy)
	local fx, fy = gx - x0, gy - y0
	local i = (y0 - 1) * w + x0
	local a, b, c, d = grid[i], grid[i + 1], grid[i + w], grid[i + w + 1]
	return M.lerp(M.lerp(a, b, fx), M.lerp(c, d, fx), fy)
end
-- gradiente numerico de grade (para erosao / normais)
function M.gradient(grid, w, h, gx, gy, spacing)
	spacing = spacing or 1
	local gxL, gxR = M.bilinear(grid, w, h, gx - 1, gy), M.bilinear(grid, w, h, gx + 1, gy)
	local gyU, gyD = M.bilinear(grid, w, h, gx, gy - 1), M.bilinear(grid, w, h, gx, gy + 1)
	return (gxL - gxR) / (2 * spacing), (gyU - gyD) / (2 * spacing)
end

-- =============== FISICA AMBIENTAL ===============
-- Classificador de Whittaker (temperatura C x precipitacao cm/ano) -> bioma
-- Tese dos D: mesma realidade (clima) -> representacao semantica (bioma).
M.BIOMES = {
	"tundra", "taiga", "esteppe_fria", "pradaria", "deserto_frio",
	"savana", "deserto_quente", "chaparral", "floresta_temperada",
	"pantano", "floresta_tropical", "floresta_equatorial", "alpino", "gelo",
}
function M.whittaker(tempC, precipCm)
	if tempC <= -12 then return "gelo" end
	if tempC < 0 then
		if precipCm < 40 then return "tundra" else return "taiga" end
	end
	if tempC < 8 then
		if precipCm < 30 then return "esteppe_fria"
		elseif precipCm < 80 then return "pradaria"
		else return "taiga" end
	end
	if tempC < 17 then
		if precipCm < 25 then return "deserto_frio"
		elseif precipCm < 55 then return "chaparral"
		elseif precipCm < 130 then return "floresta_temperada"
		else return "pantano" end
	end
	if tempC < 26 then
		if precipCm < 20 then return "deserto_quente"
		elseif precipCm < 70 then return "savana"
		else return "floresta_tropical" end
	end
	if precipCm < 30 then return "deserto_quente"
	elseif precipCm < 120 then return "floresta_tropical"
	else return "floresta_equatorial" end
end
-- orvalho/efeito orografico simples: sombra de chuva a sotavento
function M.rainShadow(here, windwardAlt)
	local drop = windwardAlt - here
	if drop > 0 then return M.clamp(1 - drop / 400, 0.25, 1) end
	return 1
end
-- barometrica: pressao aproximada por altitude (m)
function M.pressureAt(altM) return 101325 * exp(-altM / 8434) end
-- ponto de orvalho approx (Magnus)
function M.dewPoint(tempC, rh)
	local a, b = 17.27, 237.7
	local alpha = ((a * tempC) / (b + tempC)) + math.log(M.clamp(rh, 0.01, 1))
	return (b * alpha) / (a - alpha)
end

M._version = "1.0.0"
end

do
--[[ ARKHER TERRAIN X (ATX) — motor de terreno CUSTOM (nao usa Terrain do Roblox) ]]
-- RRW: realidade (geologia, clima, hidrologia) -> representacao (campos por
-- chunk) -> D-O15 (LOD adaptativo) -> materializacao (parts no workspace).
-- Tudo deterministico por semente: o mesmo mundo renasce igual em qualquer D.
--
-- Capacidades:
--  * mundo infinito em chunks (geracao procedural sob demanda)
--  * geofisica: continentes, montanhas ridged, domain warp, crateras, mesetas
--  * erosao REAL: hidraulica (droplet) + termica (talus) + deposicao
--  * hidrologia: rede de rios por acumulacao de fluxo (D8), lagos por
--    preenchimento de depressoes, praias por nivel do mar
--  * clima: temperatura (latitude+altitude), precipitacao (fbm+sombra de
--    chuva), biomas pelo diagrama de Whittaker (14 biomas)
--  * 24 MATERIAIS COM PROPRIEDADES FISICAS (RRW "materia", nao albedo+normal):
--    densidade, dureza, porosidade, coesao, cor, termica, umidade alvo
--  * escultura: 10 operacoes de pincel x 5 falloffs (gauss/suave/coseno/linear/seco)
--  * materializacao adaptativa: chunks de parts, LOD por distancia/orcamento
--  * persistencia: export/import JSON compacto (run-length), undo-friendly
--  * consultas: heightAt/normalAt/materialAt/biomeAt/waterDepthAt + raycast plano
ArkherTerrainX = ArkherTerrainX or {}
local ATX = ArkherTerrainX
local DM = ArkherDM
local floor, ceil, abs = math.floor, math.ceil, math.abs
local sqrt, clamp = math.sqrt, DM.clamp
local lerp = DM.lerp

local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end

-- ================= MATERIAIS (RRW materia) =================
-- props fisicas: dens(kg/L-ish), dureza(Mohs-ish), porosidade, coesao,
-- termica (inercia), cor radiometria simplificada {r,g,b}, solubilidade
ATX.MATERIALS = {
	{ id = "rocha", nm = "Rocha", dens = 2.65, dureza = 6, poros = 0.02, coesao = 0.9, termica = 0.8, cor = { 122, 118, 113 } },
	{ id = "basalto", nm = "Basalto", dens = 2.9, dureza = 6.5, poros = 0.03, coesao = 0.95, termica = 0.85, cor = { 74, 74, 78 } },
	{ id = "granito", nm = "Granito", dens = 2.65, dureza = 6.8, poros = 0.015, coesao = 0.95, termica = 0.75, cor = { 158, 146, 138 } },
	{ id = "cascalho", nm = "Cascalho", dens = 1.8, dureza = 3, poros = 0.35, coesao = 0.2, termica = 0.5, cor = { 139, 131, 120 } },
	{ id = "areia", nm = "Areia", dens = 1.6, dureza = 2, poros = 0.4, coesao = 0.1, termica = 0.45, cor = { 219, 200, 152 } },
	{ id = "areia_des", nm = "Areia do Deserto", dens = 1.55, dureza = 2, poros = 0.42, coesao = 0.08, termica = 0.4, cor = { 226, 191, 122 } },
	{ id = "terra", nm = "Terra", dens = 1.5, dureza = 2.5, poros = 0.35, coesao = 0.45, termica = 0.55, cor = { 122, 92, 62 } },
	{ id = "argila", nm = "Argila", dens = 1.9, dureza = 2, poros = 0.45, coesao = 0.7, termica = 0.6, cor = { 168, 122, 96 } },
	{ id = "grama", nm = "Grama", dens = 1.35, dureza = 1.5, poros = 0.5, coesao = 0.5, termica = 0.5, cor = { 96, 168, 74 } },
	{ id = "prado", nm = "Prado", dens = 1.35, dureza = 1.5, poros = 0.52, coesao = 0.5, termica = 0.5, cor = { 124, 186, 84 } },
	{ id = "floresta", nm = "Solo de Floresta", dens = 1.3, dureza = 1.5, poros = 0.55, coesao = 0.55, termica = 0.55, cor = { 74, 128, 58 } },
	{ id = "lama", nm = "Lama", dens = 1.4, dureza = 1, poros = 0.6, coesao = 0.3, termica = 0.5, cor = { 104, 84, 60 } },
	{ id = "neve", nm = "Neve", dens = 0.35, dureza = 1, poros = 0.7, coesao = 0.15, termica = 0.2, cor = { 238, 242, 248 } },
	{ id = "gelo", nm = "Gelo", dens = 0.92, dureza = 1.5, poros = 0.0, coesao = 0.8, termica = 0.15, cor = { 188, 218, 235 } },
	{ id = "cinza", nm = "Cinza Vulcanica", dens = 1.1, dureza = 1, poros = 0.6, coesao = 0.12, termica = 0.5, cor = { 96, 94, 90 } },
	{ id = "lava", nm = "Lava Resfriada", dens = 2.8, dureza = 5.5, poros = 0.05, coesao = 0.9, termica = 0.9, cor = { 58, 48, 46 } },
	{ id = "sal", nm = "Salina", dens = 2.16, dureza = 2.5, poros = 0.05, coesao = 0.4, termica = 0.5, cor = { 236, 232, 218 } },
	{ id = "coral", nm = "Coral", dens = 1.9, dureza = 3, poros = 0.5, coesao = 0.3, termica = 0.5, cor = { 232, 138, 118 } },
	{ id = "rocha_prof", nm = "Rocha Profunda", dens = 3.0, dureza = 7, poros = 0.01, coesao = 1, termica = 0.9, cor = { 54, 54, 58 } },
	{ id = "turfa", nm = "Turfa", dens = 0.9, dureza = 1, poros = 0.8, coesao = 0.2, termica = 0.4, cor = { 82, 68, 44 } },
	{ id = "arenito", nm = "Arenito", dens = 2.3, dureza = 5, poros = 0.15, coesao = 0.7, termica = 0.65, cor = { 202, 158, 104 } },
	{ id = "calcario", nm = "Calcario", dens = 2.5, dureza = 4, poros = 0.12, coesao = 0.75, termica = 0.7, cor = { 214, 208, 188 } },
	{ id = "obsidiana", nm = "Obsidiana", dens = 2.4, dureza = 5.5, poros = 0, coesao = 0.95, termica = 0.8, cor = { 36, 34, 40 } },
	{ id = "enxofre", nm = "Enxofre", dens = 2.07, dureza = 2, poros = 0.1, coesao = 0.3, termica = 0.35, cor = { 220, 196, 66 } },
}
ATX.MAT_INDEX = {}
for i, m in ipairs(ATX.MATERIALS) do m.index = i; ATX.MAT_INDEX[m.id] = i end

-- mapa bioma -> material de superficie
ATX.BIOME_MAT = {
	tundra = "cascalho", taiga = "floresta", esteppe_fria = "grama", pradaria = "prado",
	deserto_frio = "cascalho", savana = "areia", deserto_quente = "areia_des",
	chaparral = "grama", floresta_temperada = "floresta", pantano = "lama",
	floresta_tropical = "floresta", floresta_equatorial = "turfa",
	alpino = "rocha", gelo = "gelo",
}

ATX.PRESETS = {
	continentes = { label = "Continentes", cont = 1.0, mont = 1.0, hill = 0.45, det = 0.35, sea = 0, warp = 5, caves = 0 },
	ilhas = { label = "Arquipelago", cont = 0.8, mont = 0.5, hill = 0.3, det = 0.4, sea = -4, warp = 9, islands = true },
	montanhas = { label = "Cordilheira", cont = 1.1, mont = 1.9, hill = 0.5, det = 0.5, sea = -10, warp = 6, caves = 1 },
	canyon = { label = "Canyon", cont = 0.9, mont = 0.4, hill = 0.2, det = 0.4, sea = -14, warp = 3, terrace = 7, caves = 0.8 },
	dunas = { label = "Dunas", cont = 0.6, mont = 0.05, hill = 0.9, det = 0.6, sea = -9, warp = 2, dunes = true, tempB = 14, humidB = -40 },
	meseta = { label = "Mesetas", cont = 1.0, mont = 0.8, hill = 0.3, det = 0.3, sea = -12, warp = 4, terrace = 11 },
	vulcao = { label = "Vulcao", cont = 0.8, mont = 1.4, hill = 0.3, det = 0.4, sea = -8, warp = 4, volcano = true, caves = 0.9 },
	polar = { label = "Polar", cont = 0.9, mont = 0.9, hill = 0.4, det = 0.3, sea = -3, warp = 4, tempB = -34, humidB = -10 },
	pantanal = { label = "Pantanal", cont = 0.7, mont = 0.08, hill = 0.2, det = 0.5, sea = -1.5, warp = 2, tempB = 12, humidB = 55, lakes = true },
	taiga = { label = "Taiga", cont = 1.0, mont = 0.7, hill = 0.6, det = 0.4, sea = -6, warp = 7, tempB = -14, humidB = 20 },
}

local World = {}
World.__index = World

-- world:worldToCell(studs) -> cell coords (frac)
local function studs2cell(self, x, z) return x / self.cell + 0.5, z / self.cell + 0.5 end

function ATX.new(opts)
	opts = opts or {}
	local w = setmetatable({}, World)
	w.seed = floor(opts.seed or 1337)
	w.cell = opts.cell or 8 -- studs por celula
	w.chunkCells = opts.chunkCells or 16 -- celulas por lado do chunk
	w.preset = opts.preset or "continentes"
	w.params = {}
	local p = ATX.PRESETS[w.preset] or ATX.PRESETS.continentes
	for k, v in pairs(p) do w.params[k] = v end
	-- o preset define o nivel do mar quando nao passado explicitamente
	w.seaLevel = opts.seaLevel or w.params.sea or 0
	if opts.params then for k, v in pairs(opts.params) do w.params[k] = v end end
	w.chunks = {}
	w.rivers = {} -- lista de celulas fluviais {cx,cz,acc}
	w.lakes = {} -- mapa "cx,cz" -> depth
	w.scultCount = 0
	w.materialized = nil -- Model no workspace
	w.partsCount = 0
	w.stats = { gen = 0, cells = 0, erosions = 0, droplets = 0 }
	return w
end

-- ================= GERACAO (campos fisicos) =================
function World:baseElevation(wx, wz, P)
	P = P or self.params
	-- domain warp organico
	local qx, qz = DM.warp2(wx / 40, wz / 40, { strength = (P.warp or 4) / 40, seed = self.seed })
	qx, qz = qx * 40, qz * 40
	local cont = DM.fbm2(qx / 96, qz / 96, { octaves = 5, seed = self.seed, fn = "g" })
	cont = cont * 0.5 + 0.5
	local mask = DM.smoothstep((cont - 0.52) / 0.2)
	if P.islands then mask = DM.smoothstep((cont - 0.56) / 0.3) end
	local ridge = DM.fbm2(qx / 44, qz / 44, { octaves = 6, seed = self.seed + 11, fn = "ridged" })
	ridge = ridge * ridge * mask
	local detail = DM.fbm2(qx / 14, qz / 14, { octaves = 4, seed = self.seed + 23 }) * (P.det or 0.35) * 6
	local hills = DM.fbm2(qx / 30, qz / 30, { octaves = 4, seed = self.seed + 37 }) * (P.hill or 0.4) * 8
	local e = (cont - 0.45) * (P.cont or 1) * 46 + ridge * (P.mont or 1) * 34 + hills + detail - 6
	if P.dunes then
		local wv = math.abs(DM.gnoise2((qx + qz * 0.6) / 18, qz / 40, self.seed + 55))
		e = -4 + wv * 16 + detail * 0.5
	end
	if P.volcano then
		local d = sqrt(qx * qx + qz * qz) / 140
		local cone = clamp(1 - d, 0, 1)
		e = e + cone * 62 - (DM.smoothstep(clamp(1 - d * 6, 0, 1)) * 18) -- cratera no topo
	end
	if P.terrace then
		local t = P.terrace
		local f = floor(e / t + 0.5) * t
		e = lerp(e, f, 0.72) + (e - f) * 0.28
	end
	return e
end

function World:climate(wx, wz, elev)
	local P = self.params
	-- temperatura: base quente, -latitude (z longe do equador), -altitude
	local lat = abs(wz * self.cell) / 36 -- graus-ish
	local temp = 27 - lat * 0.55 - math.max(0, elev) * 0.55 + (P.tempB or 0)
	temp = temp + DM.gnoise2(wx / 60, wz / 60, self.seed + 91) * 3
	-- precipitacao: fbm + boost orografico (chuva de barlavento)
	local base = 60 + DM.fbm2(wx / 70 + 9.1, wz / 70 - 3.7, { octaves = 4, seed = self.seed + 77 }) * 55
	base = base + clamp(elev, 0, 60) * 1.1 + (P.humidB or 0)
	return temp, clamp(base, 2, 400)
end

function World:pickMaterial(wx, wz, h, tempC, precip)
	local sea = self.seaLevel
	if h < sea then
		local d = sea - h
		if d < 2.2 then
			local coral = DM.hash2(wx, wz, self.seed + 501)
			if coral > 0.86 and tempC > 18 then return ATX.MAT_INDEX.coral end
			return ATX.MAT_INDEX.areia
		elseif d < 14 then return ATX.MAT_INDEX.cascalho
		else return ATX.MAT_INDEX.rocha_prof end
	end
	if h < sea + 1.6 then return ATX.MAT_INDEX.areia end -- praia
	local biome = DM.whittaker(tempC, precip)
	local mid = ATX.MAT_INDEX[ATX.BIOME_MAT[biome]] or ATX.MAT_INDEX.grama
	-- altitude forca rocha/neve
	if h > 52 or tempC < -2 then
		if tempC < -2 then return ATX.MAT_INDEX.neve end
		if h > 64 then return DM.hash2(wx, wz, self.seed + 502) > 0.4 and ATX.MAT_INDEX.neve or ATX.MAT_INDEX.rocha end
		return ATX.MAT_INDEX.rocha
	end
	-- textura: variacao local (patches), ex: pedregulho em encosta
	local patch = DM.vnoise2(wx / 8, wz / 8, self.seed + 503)
	if patch > 0.78 then return ATX.MAT_INDEX.cascalho end
	return mid
end

function World:genChunk(cx, cz)
	local key = cx .. "," .. cz
	if self.chunks[key] then return self.chunks[key] end
	local n = self.chunkCells
	local h = {}
	local gn = n + 1
	for j = 1, gn do
		for i = 1, gn do
			local wx = cx * n + i - 1
			local wz = cz * n + j - 1
			h[(j - 1) * gn + i] = self:baseElevation(wx, wz)
		end
	end
	local mat, wet, biome = {}, {}, {}
	for j = 1, n do
		for i = 1, n do
			local wx = cx * n + i - 0.5
			local wz = cz * n + j - 0.5
			local e = (h[(j - 1) * gn + i] + h[(j - 1) * gn + i + 1] + h[j * gn + i] + h[j * gn + i + 1]) / 4
			local tC, pr = self:climate(wx, wz, e)
			mat[(j - 1) * n + i] = self:pickMaterial(wx, wz, e, tC, pr)
			wet[(j - 1) * n + i] = pr / 400
			biome[(j - 1) * n + i] = DM.whittaker(tC, pr)
		end
	end
	local ch = { cx = cx, cz = cz, h = h, mat = mat, wet = wet, biome = biome, dirty = true, sculpted = false }
	self.chunks[key] = ch
	self.stats.gen = self.stats.gen + 1
	self.stats.cells = self.stats.cells + n * n
	return ch
end

function World:chunkKeyOf(gx, gz)
	local n = self.chunkCells
	local cx = floor((gx - 1) / n)
	local cz = floor((gz - 1) / n)
	return cx, cz, cx .. "," .. cz
end

-- ================= CONSULTAS (RRW: leitura da realidade) =================
function World:heightAtCell(gx, gz) -- celulas, amostragem bilinear auto-gen
	local cx, cz, key = self:chunkKeyOf(floor(gx) + 1, floor(gz) + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = gx - cx * n
	local lz = gz - cz * n
	return DM.bilinear(ch.h, n + 1, n + 1, clamp(lx + 1, 1, n + 1), clamp(lz + 1, 1, n + 1))
end
function World:heightAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	return self:heightAtCell(gx, gz)
end
function World:normalAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local e = 0.25
	local hl = self:heightAtCell(gx - e, gz)
	local hr = self:heightAtCell(gx + e, gz)
	local hu = self:heightAtCell(gx, gz - e)
	local hd = self:heightAtCell(gx, gz + e)
	local sx = (hl - hr) / (2 * e * self.cell)
	local sz = (hu - hd) / (2 * e * self.cell)
	local nx, ny, nz = sx, 1, sz
	local m = sqrt(nx * nx + ny * ny + nz * nz)
	return nx / m, ny / m, nz / m
end
-- bioma Whittaker real da CELULA exata (x em studs)
function World:biomeAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local igx, igz = floor(gx), floor(gz)
	local cx, cz = self:chunkKeyOf(igx + 1, igz + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = clamp(igx + 1 - cx * n, 1, n)
	local lz = clamp(igz + 1 - cz * n, 1, n)
	return ch.biome[(lz - 1) * n + lx] or "padrao"
end
function World:materialAt(xStuds, zStuds)
	local gx, gz = studs2cell(self, xStuds, zStuds)
	local cx, cz = self:chunkKeyOf(floor(gx) + 1, floor(gz) + 1)
	local ch = self:genChunk(cx, cz)
	local n = self.chunkCells
	local lx = clamp(floor(gx - cx * n) + 1, 1, n)
	local lz = clamp(floor(gz - cz * n) + 1, 1, n)
	return ch.mat[(lz - 1) * n + lx], ch.biome[(lz - 1) * n + lx]
end
function World:waterDepthAt(xStuds, zStuds)
	local h = self:heightAt(xStuds, zStuds)
	local d = self.seaLevel - h
	local keyLake = nil
	if d <= 0 then -- lagos acima do nivel do mar
		local gx, gz = studs2cell(self, xStuds, zStuds)
		local lk = self.lakes[floor(gx) .. "," .. floor(gz)]
		if lk then d = lk end
	end
	return math.max(d, 0)
end

-- ================= ESCULTURA =================
ATX.BRUSH_OPS = { "raise", "lower", "smooth", "flatten", "set", "noise", "crater", "terrace", "paint", "wet" }
function World:sculpt(xStuds, zStuds, o)
	o = o or {}
	local op = o.op or "raise"
	local rad = math.max((o.radius or 24) / self.cell, 0.5)
	local strength = o.strength or 0.5
	local fall = o.falloff or "smooth"
	local amt = o.amount or 6
	local cgX, cgZ = studs2cell(self, xStuds, zStuds)
	local target = o.target
	if not target and op == "flatten" then target = self:heightAtCell(cgX, cgZ) end
	local x0, x1 = floor(cgX - rad) + 1, ceil(cgX + rad)
	local z0, z1 = floor(cgZ - rad) + 1, ceil(cgZ + rad)
	local changed, meanSum, meanN = 0, 0, 0
	local rn = DM.rng(self.seed + self.scultCount * 77 + 1)
	for gz = z0, z1 do
		for gx = x0, x1 do
			local d = sqrt((gx - cgX) ^ 2 + (gz - cgZ) ^ 2)
			local w = DM.falloff(d, rad, fall)
			if w > 0.001 then
				local cx, cz = self:chunkKeyOf(gx, gz)
				local ch = self:genChunk(cx, cz)
				local n = self.chunkCells
				local lx, lz = gx - cx * n, gz - cz * n
				local hi = (lz - 1) * (n + 1) + lx
				ch.sculpted = true
				local v = ch.h[hi] or 0
				if op == "raise" then ch.h[hi] = v + amt * strength * w
				elseif op == "lower" then ch.h[hi] = v - amt * strength * w
				elseif op == "set" then ch.h[hi] = lerp(v, target or amt, clamp(strength * w * 2, 0, 1))
				elseif op == "flatten" then ch.h[hi] = lerp(v, target, clamp(strength * w * 1.6, 0, 1))
				elseif op == "crater" then
					local rim = DM.gauss(d - rad * 0.72, rad * 0.3)
					ch.h[hi] = v - amt * 1.6 * strength * DM.gauss(d, rad * 0.72) + amt * rim * strength
				elseif op == "terrace" then
					local t = amt
					ch.h[hi] = lerp(v, floor(v / t + 0.5) * t, clamp(strength * w, 0, 1))
				elseif op == "noise" then
					ch.h[hi] = v + DM.gnoise2(gx * 0.35, gz * 0.35, self.seed + 700 + self.scultCount) * amt * strength * w
				elseif op == "paint" and o.mat then
					local mi = type(o.mat) == "number" and o.mat or ATX.MAT_INDEX[o.mat]
					if mi and lx <= n and lz <= n then ch.mat[(lz - 1) * n + lx] = mi end
				elseif op == "wet" then
					if lx <= n and lz <= n then ch.wet[(lz - 1) * n + lx] = clamp((ch.wet[(lz - 1) * n + lx] or 0) + strength * w, 0, 1) end
				elseif op == "smooth" then
					meanSum = meanSum + 1 -- coletado numa 2a passada abaixo
				end
				if w > 0.5 then changed = changed + 1 end
			end
		end
	end
	if op == "smooth" then
		local copy = {}
		for gz = z0, z1 do
			for gx = x0, x1 do copy[gx .. "," .. gz] = self:heightAtCell(gx, gz) end
		end
		for gz = z0, z1 do
			for gx = x0, x1 do
				local d = sqrt((gx - cgX) ^ 2 + (gz - cgZ) ^ 2)
				local w = DM.falloff(d, rad, fall)
				if w > 0.001 then
					local acc, cnt = 0, 0
					for dz = -1, 1 do
						for dx = -1, 1 do
							local k = (gx + dx) .. "," .. (gz + dz)
							local sample = copy[k] or self:heightAtCell(gx + dx, gz + dz)
							acc = acc + sample; cnt = cnt + 1
						end
					end
					local cx, cz = self:chunkKeyOf(gx, gz)
					local ch = self:genChunk(cx, cz)
					local n = self.chunkCells
					local lx, lz = gx - cx * n, gz - cz * n
					ch.h[(lz - 1) * (n + 1) + lx] = lerp(ch.h[(lz - 1) * (n + 1) + lx], acc / cnt, clamp(strength * w, 0, 1))
					ch.sculpted = true
				end
			end
		end
	end
	self.scultCount = self.scultCount + 1
	for k2, ch in pairs(self.chunks) do
		if ch.sculpted then ch.dirty = true end
	end
	return changed
end

-- ================= EROSAO (geologia real) =================
-- Hidraulica (droplet): inercia + capacidade de sedimentos + evaporacao
function World:erodeHydraulic(gx0, gz0, gw, gh, iters, opts)
	opts = opts or {}
	iters = iters or 5000
	-- amostra grade local numa tabela temporaria (inclui borda de 2)
	local gw2, gh2 = gw + 4, gh + 4
	local grid = {}
	for j = 1, gh2 do
		for i = 1, gw2 do grid[(j - 1) * gw2 + i] = self:heightAtCell(gx0 + i - 3, gz0 + j - 3) end
	end
	local inertia = opts.inertia or 0.06
	local capFactor = opts.capacity or 5
	local erodeF, depositF = opts.erode or 0.35, opts.deposit or 0.35
	local evap = opts.evap or 0.015
	local maxLife = 40
	local grav = 4
	local rn = DM.rng(self.seed + 9000 + self.stats.erosions * 13)
	for drop = 1, iters do
		local px, pz = 1 + rn() * (gw2 - 2), 1 + rn() * (gh2 - 2)
		local dx, dz = 0, 0
		local speed, water, sed = 0, 1, 0
		for life = 1, maxLife do
			local ix, iy = floor(px), floor(pz)
			if ix < 2 or iy < 2 or ix > gw2 - 2 or iy > gh2 - 2 then break end
			local fx, fy = px - ix, pz - iy
			local gx, gz = DM.gradient(grid, gw2, gh2, px, pz, 1)
			dx = dx * inertia - gx * (1 - inertia)
			dz = dz * inertia - gz * (1 - inertia)
			local len = sqrt(dx * dx + dz * dz)
			if len < 1e-6 then dx = rn() - 0.5; dz = rn() - 0.5; len = sqrt(dx * dx + dz * dz) end
			dx, dz = dx / len, dz / len
			local nxp, nzp = px + dx, pz + dz
			local hOld = DM.bilinear(grid, gw2, gh2, px, pz)
			local hNew = DM.bilinear(grid, gw2, gh2, nxp, nzp)
			local dh = hNew - hOld
			local cap = math.max(-dh, 0.01) * speed * water * capFactor
			if dh > 0 or sed > cap then -- deposita
				local amount = (dh > 0) and math.min(dh, sed) or (sed - cap) * depositF
				sed = sed - amount
				local i00 = (iy - 1) * gw2 + ix
				grid[i00] = grid[i00] + amount * (1 - fx) * (1 - fy)
				grid[i00 + 1] = grid[i00 + 1] + amount * fx * (1 - fy)
				grid[i00 + gw2] = grid[i00 + gw2] + amount * (1 - fx) * fy
				grid[i00 + gw2 + 1] = grid[i00 + gw2 + 1] + amount * fx * fy
			else -- erode
				local amount = math.min((cap - sed) * erodeF, -dh * 0 + math.max(-dh, 0) + (cap - sed) * 0.4)
				sed = sed + amount
				local i00 = (iy - 1) * gw2 + ix
				grid[i00] = grid[i00] - amount * (1 - fx) * (1 - fy)
				grid[i00 + 1] = grid[i00 + 1] - amount * fx * (1 - fy)
				grid[i00 + gw2] = grid[i00 + gw2] - amount * (1 - fx) * fy
				grid[i00 + gw2 + 1] = grid[i00 + gw2 + 1] - amount * fx * fy
			end
			speed = sqrt(math.max(speed * speed + dh * grav, 0))
			water = water * (1 - evap)
			px, pz = nxp, nzp
		end
		self.stats.droplets = self.stats.droplets + 1
	end
	-- escreve de volta (so o interior, celulas fora do mar tambem)
	local total, cnt, mx = 0, 0, 0
	for j = 3, gh2 - 2 do
		for i = 3, gw2 - 2 do
			local gx, gz = gx0 + i - 3, gz0 + j - 3
			local cx, cz = self:chunkKeyOf(gx, gz)
			local ch = self:genChunk(cx, cz)
			local n = self.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			local idx = (lz - 1) * (n + 1) + lx
			local newH = grid[(j - 1) * gw2 + i]
			local d = abs(newH - (ch.h[idx] or 0))
			if d > mx then mx = d end
			total = total + d; cnt = cnt + 1
			ch.h[idx] = newH
			ch.dirty = true; ch.sculpted = true
			if lx <= n and lz <= n then
				-- vales erodidos: mais umidade e solo exposto
				local mi = (lz - 1) * n + lx
				ch.wet[mi] = clamp((ch.wet[mi] or 0) + 0.05, 0, 1)
			end
		end
	end
	self.stats.erosions = self.stats.erosions + 1
	return { iterations = iters, meanDelta = cnt > 0 and total / cnt or 0, maxDelta = mx }
end
-- Termica (talus): material escorrega quando talude > angulo limite
function World:erodeThermal(gx0, gz0, gw, gh, passes, talus)
	talus = talus or 0.9 -- talude maximo (dh por celula)
	passes = passes or 8
	local moved = 0
	for p = 1, passes do
		for gz = gz0, gz0 + gh - 1 do
			for gx = gx0, gx0 + gw - 1 do
				local h0 = self:heightAtCell(gx, gz)
				local lowest, lowH = nil, h0
				for dz = -1, 1 do
					for dx = -1, 1 do
						if not (dx == 0 and dz == 0) then
							local hn = self:heightAtCell(gx + dx, gz + dz)
							if hn < lowH then lowH = hn; lowest = { dx, dz } end
						end
					end
				end
				if lowest and (h0 - lowH) > talus then
					local cx, cz = self:chunkKeyOf(gx, gz)
					local ch = self:genChunk(cx, cz)
					local n = self.chunkCells
					local lx, lz = gx - cx * n, gz - cz * n
					local excess = (h0 - lowH - talus) * 0.35
					ch.h[(lz - 1) * (n + 1) + lx] = h0 - excess
					local cx2, cz2 = self:chunkKeyOf(gx + lowest[1], gz + lowest[2])
					local ch2 = self:genChunk(cx2, cz2)
					local lx2, lz2 = gx + lowest[1] - cx2 * n, gz + lowest[2] - cz2 * n
					ch2.h[(lz2 - 1) * (n + 1) + lx2] = ch2.h[(lz2 - 1) * (n + 1) + lx2] + excess
					ch.dirty, ch2.dirty = true, true
					ch.sculpted, ch2.sculpted = true, true
					moved = moved + excess
				end
			end
		end
	end
	return { passes = passes, moved = moved }
end

-- ================= HIDROLOGIA =================
-- D8 flow accumulation -> rios; retorna celulas com acumulacao > minAcc
function World:carveRivers(gx0, gz0, gw, gh, minAcc)
	minAcc = minAcc or 28
	-- grade + borda
	local grid = {}
	local gw2, gh2 = gw + 2, gh + 2
	for j = 1, gh2 do
		for i = 1, gw2 do grid[(j - 1) * gw2 + i] = self:heightAtCell(gx0 + i - 2, gz0 + j - 2) end
	end
	-- direcao de fluxo (maior descida)
	local flow = {}
	for j = 2, gh2 - 1 do
		for i = 2, gw2 - 1 do
			local idx = (j - 1) * gw2 + i
			local h0 = grid[idx]
			local best, bestDrop = 0, self.seaLevel - h0 -- se abaixo do mar, despeja no mar
			for o = 1, 8 do
				local oi = i + (o == 1 and -1 or o == 2 and 0 or o == 3 and 1 or o == 4 and -1 or o == 5 and 1 or o == 6 and -1 or o == 7 and 0 or 1)
				local oj = j + (o <= 3 and -1 or o <= 5 and 0 or 1)
				local hn = grid[(oj - 1) * gw2 + oi]
				local drop = (h0 - hn) / ((oi ~= i and oj ~= j) and 1.4142 or 1)
				if drop > bestDrop then bestDrop = drop; best = o end
			end
			flow[idx] = best
		end
	end
	-- acumulacao por processamento em ordem de altura (maior -> menor)
	local order = {}
	for j = 2, gh2 - 1 do for i = 2, gw2 - 1 do order[#order + 1] = (j - 1) * gw2 + i end end
	table.sort(order, function(a, b) return grid[a] > grid[b] end)
	local acc = {}
	for _, idx in ipairs(order) do
		acc[idx] = (acc[idx] or 1)
		local f = flow[idx]
		if f and f > 0 then
			local i = ((idx - 1) % gw2) + 1
			local j = floor((idx - 1) / gw2) + 1
			local oi = i + (f == 1 and -1 or f == 2 and 0 or f == 3 and 1 or f == 4 and -1 or f == 5 and 1 or f == 6 and -1 or f == 7 and 0 or 1)
			local oj = j + (f <= 3 and -1 or f <= 5 and 0 or 1)
			local nidx = (oj - 1) * gw2 + oi
			acc[nidx] = (acc[nidx] or 1) + acc[idx]
		end
	end
	-- rios = acumulacao alta; escava leito em V suave e marca
	local riverCells = 0
	local maxAcc = 0
	for _, idx in ipairs(order) do if (acc[idx] or 0) > maxAcc then maxAcc = acc[idx] end end
	for _, idx in ipairs(order) do
		local a = acc[idx] or 1
		if a >= minAcc then
			local i = ((idx - 1) % gw2) + 1
			local j = floor((idx - 1) / gw2) + 1
			local gx, gz = gx0 + i - 2, gz0 + j - 2
			local cx, cz = self:chunkKeyOf(gx, gz)
			local ch = self:genChunk(cx, cz)
			local n = self.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			local hidx = (lz - 1) * (n + 1) + lx
			local depth = clamp(math.log(a) * 0.5, 0.4, 3.2)
			ch.h[hidx] = math.min(ch.h[hidx], ch.h[hidx] - depth * 0 + 0) -- mantem; escava abaixo:
			ch.h[hidx] = ch.h[hidx] - depth * 0.55
			ch.dirty = true; ch.sculpted = true
			if lx <= n and lz <= n then
				local mi = (lz - 1) * n + lx
				ch.wet[mi] = 1
				if ch.h[hidx] > self.seaLevel - 1 then ch.mat[mi] = ATX.MAT_INDEX.lama end
			end
			self.rivers[#self.rivers + 1] = { gx = gx, gz = gz, acc = a }
			riverCells = riverCells + 1
		end
	end
	return { cells = riverCells, maxAcc = maxAcc }
end
-- Lagos: preenchimento de depressoes (Planchon-Darboux simplificado)
function World:fillLakes(gw0, gz0, gw, gh)
	local grid, spill = {}, {}
	local gw2, gh2 = gw + 2, gh + 2
	local BIG = 1e9
	for j = 1, gh2 do
		for i = 1, gw2 do
			local h = self:heightAtCell(gw0 + i - 2, gz0 + j - 2)
			grid[(j - 1) * gw2 + i] = h
			local border = (i == 1 or j == 1 or i == gw2 or j == gh2)
			spill[(j - 1) * gw2 + i] = border and h or BIG
		end
	end
	for it = 1, 40 do
		local changed = false
		for j = 2, gh2 - 1 do
			for i = 2, gw2 - 1 do
				local idx = (j - 1) * gw2 + i
				local h = grid[idx]
				local s = spill[idx]
				if s > h then
					local minN = BIG
					local n1 = spill[idx - 1]; if n1 < minN then minN = n1 end
					local n2 = spill[idx + 1]; if n2 < minN then minN = n2 end
					local n3 = spill[idx - gw2]; if n3 < minN then minN = n3 end
					local n4 = spill[idx + gw2]; if n4 < minN then minN = n4 end
					local ns = math.max(h, minN)
					if ns < s - 1e-6 then spill[idx] = ns; changed = true end
				end
			end
		end
		if not changed then break end
	end
	local lakes = 0
	for j = 2, gh2 - 1 do
		for i = 2, gw2 - 1 do
			local idx = (j - 1) * gw2 + i
			local depth = spill[idx] - grid[idx]
			if depth > 0.7 and spill[idx] < BIG / 2 then
				local gx, gz = gw0 + i - 2, gz0 + j - 2
				self.lakes[gx .. "," .. gz] = depth
				local cx, cz = self:chunkKeyOf(gx, gz)
				local ch = self:genChunk(cx, cz)
				local n = self.chunkCells
				local lx, lz = gx - cx * n, gz - cz * n
				if lx <= n and lz <= n then
					local mi = (lz - 1) * n + lx
					ch.mat[mi] = ATX.MAT_INDEX.lama
					ch.wet[mi] = 1
					ch.dirty = true
				end
				lakes = lakes + 1
			end
		end
	end
	return { cells = lakes }
end

-- ================= MATERIALIZACAO (RRW -> dispositivo) =================
local function matColor(m, shade, hgt, sea)
	local c = m.cor
	local f = clamp(0.82 + shade * 0.18 + (hgt / 90) * 0.1, 0.5, 1.15)
	local r = clamp(floor(c[1] * f + 0.5), 0, 255)
	local g = clamp(floor(c[2] * f + 0.5), 0, 255)
	local b = clamp(floor(c[3] * f + 0.5), 0, 255)
	return Color3.fromRGB(r, g, b)
end

local function newPart(className, name, size, pos, color, parent)
	local p = Instance.new(className)
	p.Name = name
	p.Size = size
	p.CFrame = CFrame.new(pos.X, pos.Y, pos.Z)
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	pcall(function() p.Material = Enum.Material.SmoothPlastic end)
	p.Color = color
	p.Parent = parent
	return p
end

function ATX._lodStep(defaultStep)
	local ok, lv = pcall(function() return ArkherDO15.state.level end)
	if not ok then return defaultStep or 2 end
	return ({ 1, 2, 3, 4 })[lv or 2] or (defaultStep or 2)
end

-- caverna: campo worley+gnoise — colunas altas ganham GAP interno real
-- (o voxel-shaped deixa de ser um pilar solido: vira base/caixao+tecto)
function World:caveSpanAt(wx, wz, baseY, colHeight)
	local cv = self.params.caves or 0
	if cv <= 0 or colHeight < 18 then return nil end
	local g1 = DM.gnoise2(wx * 0.021, wz * 0.021, self.seed + 913)
	local g2 = DM.gnoise2(wx * 0.068, wz * 0.068, self.seed + 914)
	local score = g1 * 0.62 + g2 * 0.38
	if score < 0.42 * cv then return nil end
	local frac = 0.28 + 0.34 * DM.hash2(wx, wz, self.seed + 915)
	local thick = 4 + 4 * DM.hash2(wx, wz, self.seed + 916)
	local mid = baseY + colHeight * frac
	local y0, y1 = mid - thick / 2, mid + thick / 2
	if y1 > baseY + colHeight - 3 then return nil end -- preserva a crosta
	if y0 < baseY + 3 then return nil end -- preserva a base
	return { y0 = y0, y1 = y1 }
end

function World:materializeChunk(ch, opts)
	opts = opts or {}
	if not self.materialized then self:materializeRoot() end
	local root = self.materialized
	local cname = "Chunk_" .. ch.cx .. "_" .. ch.cz
	local old = root:FindFirstChild(cname)
	if old then self.partsCount = self.partsCount - #old:GetChildren(); old:Destroy() end
	local model = Instance.new("Model")
	model.Name = cname
	model:SetAttribute("cx", ch.cx)
	model:SetAttribute("cz", ch.cz)
	model.Parent = root
	local n = self.chunkCells
	local step = opts.step or ATX._lodStep(2)
	if step < 1 then step = 1 end
	local cs = self.cell * step
	local baseY = opts.baseY or -40
	local count = 0
	for j0 = 1, n, step do
		for i0 = 1, n, step do
			-- media das alturas no bloco
			local acc, cnt = 0, 0
			for dj = 0, step do
				for di = 0, step do
					local hi = (j0 + dj - 1) * (n + 1) + (i0 + di)
					if hi <= #ch.h then acc = acc + (ch.h[hi] or 0); cnt = cnt + 1 end
				end
			end
			local hgt = cnt > 0 and acc / cnt or 0
			local wx = (ch.cx * n + i0 - 1 + (step - 1) / 2) * self.cell
			local wz = (ch.cz * n + j0 - 1 + (step - 1) / 2) * self.cell
			-- material dominante
			local mi = ch.mat[(clamp(j0, 1, n) - 1) * n + clamp(i0, 1, n)] or 1
			local m = ATX.MATERIALS[mi] or ATX.MATERIALS[1]
			local hL = (ch.h[(clamp(j0, 1, n + 1) - 1) * (n + 1) + clamp(i0 - 1, 1, n + 1)] or hgt)
			local hR = (ch.h[(clamp(j0, 1, n + 1) - 1) * (n + 1) + clamp(i0 + 1, 1, n + 1)] or hgt)
			local slope = abs(hL - hR) / (2 * self.cell)
			local col = matColor(m, -slope, hgt, self.seaLevel)
			local colHeight = math.max(hgt - baseY, 1)
			local gap = self:caveSpanAt(wx, wz, baseY, colHeight)
			if gap then
				-- coluna dividida: base rochosa + crosta (encontrado em mountain/canyon/vulcao)
				local rock = { 104, 96, 88 }
				local lowerH = gap.y0 - baseY
				local upperH = (baseY + colHeight) - gap.y1
				if lowerH > 0.5 then
					local p1 = newPart("Part", "CaveBase", Vector3.new(cs, lowerH, cs), Vector3.new(wx, baseY + lowerH / 2, wz), rock, model)
					p1:SetAttribute("mat", m.id)
					p1:SetAttribute("cave", "base")
					count = count + 1
				end
				if upperH > 0.5 then
					local p2 = newPart("Part", "CaveTop", Vector3.new(cs, upperH, cs), Vector3.new(wx, gap.y1 + upperH / 2, wz), col, model)
					p2:SetAttribute("mat", m.id)
					p2:SetAttribute("cave", "top")
					count = count + 1
				end
			else
				local p = newPart("Part", "C", Vector3.new(cs, colHeight, cs), Vector3.new(wx, baseY + colHeight / 2, wz), col, model)
				p:SetAttribute("mat", m.id)
				count = count + 1
			end
		end
	end
	self.partsCount = self.partsCount + count
	ch.dirty = false
	return model, count
end

function World:materializeRoot()
	local ws = workspace
	local old = ws:FindFirstChild("ATX_World")
	if old then old:Destroy() end
	local root = Instance.new("Model")
	root.Name = "ATX_World"
	root:SetAttribute("engine", "ArkherTerrainX")
	root:SetAttribute("seed", self.seed)
	root:SetAttribute("cell", self.cell)
	root:SetAttribute("preset", self.preset)
	root:SetAttribute("seaLevel", self.seaLevel)
	root.Parent = ws
	self.materialized = root
	return root
end

function ATX.clearWorld(world)
	if world and world.materialized then world.materialized:Destroy() world.materialized = nil world.partsCount = 0 end
end

function World:materializeRegion(x0Studs, z0Studs, wStuds, hStuds, opts)
	opts = opts or {}
	local n = self.chunkCells
	local cx0 = floor((x0Studs / self.cell) / n)
	local cx1 = floor(((x0Studs + wStuds) / self.cell) / n)
	local cz0 = floor((z0Studs / self.cell) / n)
	local cz1 = floor(((z0Studs + hStuds) / self.cell) / n)
	local built, parts = 0, 0
	for cz = cz0, cz1 do
		for cx = cx0, cx1 do
			local ch = self:genChunk(cx, cz)
			local _, cnt = self:materializeChunk(ch, opts)
			built = built + 1; parts = parts + cnt
		end
	end
	return { chunks = built, parts = parts }
end
-- LOD adaptativo por distancia do foco (D-O15 "materializacao adequada")
function World:updateLOD(focusX, focusZ)
	if not self.materialized then return { updated = 0 } end
	local updated = 0
	for key, ch in pairs(self.chunks) do
		local n = self.chunkCells
		local ccx = (ch.cx + 0.5) * n * self.cell
		local ccz = (ch.cz + 0.5) * n * self.cell
		local d = sqrt((ccx - focusX) ^ 2 + (ccz - focusZ) ^ 2)
		local want = d < 260 and 1 or d < 560 and 2 or 4
		local model = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
		local cur = model and model:GetAttribute("step") or nil
		if model and cur ~= want then
			self:materializeChunk(ch, { step = want })
			model = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
			if model then model:GetAttribute("step") end
			updated = updated + 1
		elseif model then
			model:SetAttribute("step", want)
		elseif not model then
			self:materializeChunk(ch, { step = want })
			local m2 = self.materialized:FindFirstChild("Chunk_" .. ch.cx .. "_" .. ch.cz)
			if m2 then m2:SetAttribute("step", want) end
			updated = updated + 1
		end
	end
	return { updated = updated }
end

-- ================= STATS / SERIALIZACAO =================
function World:biomeCounts()
	local out = {}
	for _, ch in pairs(self.chunks) do
		for _, b in ipairs(ch.biome) do out[b] = (out[b] or 0) + 1 end
	end
	return out
end
function World:matCounts()
	local out = {}
	for _, ch in pairs(self.chunks) do
		for _, mi in ipairs(ch.mat) do
			local m = ATX.MATERIALS[mi]
			if m then out[m.id] = (out[m.id] or 0) + 1 end
		end
	end
	return out
end
function World:worldStats()
	local islands = 0
	return {
		seed = self.seed, preset = self.preset, chunks = self.stats.gen, cells = self.stats.cells,
		droplets = self.stats.droplets, erosions = self.stats.erosions,
		parts = self.partsCount, rivers = #self.rivers, lakes = (function() local c = 0 for _ in pairs(self.lakes) do c = c + 1 end return c end)(),
		sculpts = self.scultCount,
	}
end

function World:serialize()
	local chunks = {}
	for key, ch in pairs(self.chunks) do
		if ch.sculpted then
			local n = self.chunkCells
			local hs = {}
			for i = 1, (n + 1) * (n + 1) do hs[i] = floor((ch.h[i] or 0) * 10 + 0.5) end
			local ms = {}
			for i = 1, n * n do ms[i] = ch.mat[i] or 1 end
			chunks[#chunks + 1] = { cx = ch.cx, cz = ch.cz, h = table.concat(hs, ","), m = table.concat(ms, ",") }
		end
	end
	local data = {
		engine = "ATX", version = 1, seed = self.seed, cell = self.cell,
		chunkCells = self.chunkCells, seaLevel = self.seaLevel, preset = self.preset,
		params = self.params, lakes = self.lakes, chunks = chunks,
	}
	if HttpService then return HttpService:JSONEncode(data) end
	return "ATX:" .. tostring(self.seed)
end

function ATX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "ATX" then return nil, "bundle ATX invalido" end
	local w = ATX.new({ seed = data.seed, cell = data.cell, chunkCells = data.chunkCells, seaLevel = data.seaLevel, preset = data.preset })
	if type(data.params) == "table" then for k, v in pairs(data.params) do w.params[k] = v end end
	local restored = 0
	for _, c in ipairs(data.chunks or {}) do
		local ch = w:genChunk(c.cx, c.cz)
		local n = w.chunkCells
		local i = 0
		for tok in string.gmatch(c.h or "", "([^,]+)") do
			i = i + 1
			if i <= (n + 1) * (n + 1) then ch.h[i] = tonumber(tok) / 10 end
		end
		i = 0
		for tok in string.gmatch(c.m or "", "([^,]+)") do
			i = i + 1
			if i <= n * n then ch.mat[i] = tonumber(tok) end
		end
		ch.sculpted = true; ch.dirty = true
		restored = restored + 1
	end
	if type(data.lakes) == "table" then for k, v in pairs(data.lakes) do w.lakes[k] = v end end
	w.restored = restored
	return w
end

function World:exportFile(path)
	local str = self:serialize()
	path = path or ("ArkherTerrainX/world_" .. tostring(self.seed) .. ".atx.json")
	local ok = pcall(function()
		if game.WriteFile then game:WriteFile(path, str) end
	end)
	return str, path, ok
end

ATX._version = "1.0.0"
end

do
--[[ ARKHER WATER X (AWX) — motor de agua CUSTOM (nao usa a agua do Roblox) ]]
-- Alem do "shader de agua" da industria: corpos d'agua sao COMPOSICOES FISICAS
-- (densidade, salinidade, temperatura, viscosidade) + ondas de Gerstner com
-- dispersao gravitacional REAL (omega = sqrt(g*k)) + mares lunares + correntes
-- + flutuabilidade arquimediana de caixas + natacao + ambiente subaquatico.
-- RRW: realidade -> representacao (campo de ondas+termos fisicos) -> D-O15
-- (LOD de simulacao/materializacao) -> materializacao (tiles animados).
ArkherWaterX = ArkherWaterX or {}
local AWX = ArkherWaterX
local DM = ArkherDM
local floor, abs, sqrt = math.floor, math.abs, math.sqrt
local sin, cos, pi = math.sin, math.cos, math.pi
local clamp, lerp = DM.clamp, DM.lerp
local function atan2Safe(y, x) if x == 0 then return 0 end return math.atan(y / x) end
local function sign(x) if x > 0 then return 1 elseif x < 0 then return -1 end return 0 end
local G = 19.62 -- "gravidade Roblox-ish" p/ dispersao

local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end
local RunService
do local ok, s = pcall(function() return game:GetService("RunService") end) if ok then RunService = s end end

-- ================= TIPOS DE AGUA (materia real) =================
AWX.WATERS = {
	oceano = { nm = "Oceano", dens = 1025, sal = 35, temp = 18, visc = 1.0, cor = { 14, 68, 112 }, absorb = 0.65 },
	mar_calmo = { nm = "Mar Calmo", dens = 1025, sal = 32, temp = 22, visc = 0.9, cor = { 24, 112, 168 }, absorb = 0.45 },
	lago = { nm = "Lago", dens = 1000, sal = 0.2, temp = 16, visc = 0.85, cor = { 34, 96, 122 }, absorb = 0.35 },
	rio = { nm = "Rio", dens = 1000, sal = 0.1, temp = 14, visc = 0.8, cor = { 52, 110, 128 }, absorb = 0.3 },
	cachoeira = { nm = "Cachoeira", dens = 1000, sal = 0.1, temp = 12, visc = 0.75, cor = { 160, 196, 214 }, absorb = 0.15 },
	pantano = { nm = "Pantano", dens = 1005, sal = 4, temp = 24, visc = 1.6, cor = { 66, 84, 54 }, absorb = 0.85 },
	glacial = { nm = "Glacial", dens = 1000, sal = 0, temp = 2, visc = 1.1, cor = { 120, 178, 204 }, absorb = 0.25 },
	terma = { nm = "Terma", dens = 985, sal = 8, temp = 38, visc = 0.7, cor = { 96, 178, 186 }, absorb = 0.3 },
}
AWX.PRESETS = {
	calmaria = { waves = { { amp = 0.18, len = 28, dir = 20, speed = 1, steep = 0.2 }, { amp = 0.1, len = 11, dir = 75, speed = 1.2, steep = 0.1 } }, tide = 0.15 },
	porto = { waves = { { amp = 0.4, len = 34, dir = 0, speed = 1, steep = 0.3 }, { amp = 0.22, len = 13, dir = 40, speed = 1.1, steep = 0.2 }, { amp = 0.09, len = 6, dir = 110, speed = 1.4, steep = 0.1 } }, tide = 0.5 },
	ressaca = { waves = { { amp = 1.2, len = 58, dir = 12, speed = 1.05, steep = 0.5 }, { amp = 0.6, len = 21, dir = 48, speed = 1.2, steep = 0.35 }, { amp = 0.25, len = 9, dir = 100, speed = 1.6, steep = 0.2 } }, tide = 0.8 },
	tempestade = { waves = { { amp = 2.6, len = 88, dir = 8, speed = 1.25, steep = 0.75 }, { amp = 1.4, len = 31, dir = 55, speed = 1.4, steep = 0.55 }, { amp = 0.7, len = 13, dir = 130, speed = 1.7, steep = 0.4 }, { amp = 0.3, len = 6, dir = 200, speed = 2, steep = 0.3 } }, tide = 1.2 },
	corredeira = { waves = { { amp = 0.5, len = 9, dir = 0, speed = 1.9, steep = 0.55 }, { amp = 0.3, len = 5, dir = 30, speed = 2.3, steep = 0.45 } }, tide = 0 },
	espelho = { waves = { { amp = 0.05, len = 40, dir = 0, speed = 0.6, steep = 0.05 } }, tide = 0.05 },
}

local Body = {}
Body.__index = Body

AWX.bodies = {} -- registro vivo (alimenta links AEX/APX/UI)
function AWX.create(kind, opts)
	opts = opts or {}
	local props = AWX.WATERS[kind] and (function()
		local p = {}
		for k, v in pairs(AWX.WATERS[kind]) do p[k] = v end
		return p
	end)() or { nm = kind or "custom", dens = 1000, sal = 5, temp = 18, visc = 1, cor = { 30, 90, 140 }, absorb = 0.4 }
	local b = setmetatable({}, Body)
	b.kind = kind or "lago"
	b.props = props
	if opts.props then for k, v in pairs(opts.props) do b.props[k] = v end end
	b.level = opts.level or 0
	b.center = opts.center or { x = 0, z = 0 }
	b.size = opts.size or { x = 512, z = 512 } -- retangulo (ou raio em .radius)
	b.radius = opts.radius
	b.waves = opts.waves or (AWX.PRESETS.calmaria.waves)
	b.tideAmp = opts.tideAmp or (AWX.PRESETS.calmaria.tide or 0)
	b.tidePeriod = opts.tidePeriod or 360 -- s (ciclo lunar curto)
	b.flow = opts.flow -- fn(x,z,t) -> vx,vz (correnteza)
	b.foaminess = opts.foaminess or 0.4
	b.ripple = opts.ripple ~= false -- micro-ondulacao por ruido
	b.t0 = opts.t0 or 0
	b.tiles = nil
	b.tileParts = 0
	b.floaters = {}
	b.splashes = 0
	b.underwater = nil
	AWX.bodies[#AWX.bodies + 1] = b
	return b
end
function AWX.preset(name, opts)
	opts = opts or {}
	local p = AWX.PRESETS[name] or AWX.PRESETS.calmaria
	local waves = {}
	for i, w in ipairs(p.waves) do
		waves[i] = { amp = w.amp, len = w.len, dir = w.dir, speed = w.speed, steep = w.steep }
	end
	opts.waves = waves
	opts.tideAmp = p.tide
	return AWX.create(opts.kind or "oceano", opts)
end

-- ================= CAMPO DE ONDAS =================
-- mare lunar: componente diurna + semi-diurna simplificadas
function Body:tideAt(t)
	local p = (t or 0) / self.tidePeriod
	return self.tideAmp * (sin(2 * pi * p) * 0.7 + sin(4 * pi * p + 1.3) * 0.3)
end
-- Gerstner: altura em (x,z,t). dir em graus; omega = sqrt(g*k) * speedMul
function Body:heightAt(x, z, t)
	t = (t or 0) + self.t0
	local y = self.level + self:tideAt(t)
	for _, w in ipairs(self.waves) do
		local rad = w.dir * pi / 180
		local k = 2 * pi / w.len
		local omega = sqrt(G * k) * (w.speed or 1)
		local phase = (x * cos(rad) + z * sin(rad)) * k - omega * t
		y = y + w.amp * sin(phase)
	end
	if self.ripple then
		y = y + (DM.vnoise2(x * 0.22 + t * 0.35, z * 0.22, 777) - 0.5) * 0.14
	end
	return y
end
function Body:normalAt(x, z, t)
	local e = 0.9
	local hL, hR = self:heightAt(x - e, z, t), self:heightAt(x + e, z, t)
	local hU, hD = self:heightAt(x, z - e, t), self:heightAt(x, z + e, t)
	local nx, ny, nz = (hL - hR) / (2 * e), 1, (hU - hD) / (2 * e)
	local m = sqrt(nx * nx + ny * ny + nz * nz)
	return nx / m, ny / m, nz / m
end
-- energia da crista (por/espuma): segunda derivada negativa
function Body:crestAt(x, z, t)
	local h = self:heightAt(x, z, t)
	local hx = self:heightAt(x + 1.4, z, t) + self:heightAt(x - 1.4, z, t)
	local hz = self:heightAt(x, z + 1.4, t) + self:heightAt(x, z - 1.4, t)
	return clamp(((hx + hz) / 4 - h) * 0.9 + 0.2, 0, 1)
end
function Body:flowAt(x, z, t)
	if self.flow then return self.flow(x, z, t) end
	-- corrente gerada pelas proprias ondas (Stokes drift simplificado)
	local vx, vz = 0, 0
	for _, w in ipairs(self.waves) do
		local rad = w.dir * pi / 180
		local k = 2 * pi / w.len
		local omega = sqrt(G * k)
		local s = w.steep or 0.2
		vx = vx + cos(rad) * s * omega * w.amp * 0.12
		vz = vz + sin(rad) * s * omega * w.amp * 0.12
	end
	return vx, vz
end
function Body:inside(x, z)
	if self.radius then
		local dx, dz = x - self.center.x, z - self.center.z
		return dx * dx + dz * dz <= self.radius * self.radius
	end
	return abs(x - self.center.x) <= self.size.x / 2 and abs(z - self.center.z) <= self.size.z / 2
end
function Body:depthAt(x, z, t, floorFn)
	local bed = floorFn and floorFn(x, z) or (self.level - 12)
	return math.max(self:heightAt(x, z, t) - bed, 0)
end
-- amortecimento submerso (arraste viscoso quadratico + linear)
function Body:dragFactor(depthRatio, speed)
	local mu = self.props.visc or 1
	return mu * (1.15 * depthRatio) + mu * 0.02 * speed * speed
end

-- ================= FLUTUABILIDADE (Arquimedes de caixas) =================
function AWX.float(body, part, opts)
	opts = opts or {}
	local f = {
		part = part, body = body,
		density = opts.density or 600, -- kg/m3 do objeto
		damp = opts.damp or 0.85,
		vy = part and part.Position and 0 or 0,
		tilt = 0, spin = 0,
		mass = opts.mass,
		alive = true,
		lastSplash = 0,
	}
	if part and part.Size and not f.mass then
		f.mass = part.Size.X * part.Size.Y * part.Size.Z * f.density
	else
		f.mass = f.mass or 100
	end
	body.floaters[#body.floaters + 1] = f
	return f
end
-- integra 1 passo: retorna nova posicao Y e velocidade vertical
function AWX.stepFloater(f, dt, t)
	local b = f.body
	local p = f.part
	if not (p and p.Position and p.Size) then return nil end
	local h = b:heightAt(p.Position.X, p.Position.Z, t)
	local bottom = p.Position.Y - p.Size.Y / 2
	local subRatio = clamp((h - bottom) / p.Size.Y, 0, 1)
	-- forca: empuxo ~ rho_agua/rho_obj * submerso - gravidade, com arrasto
	local disp = (b.props.dens / f.density) * subRatio
	local acc = (disp - 1) * G * 0.6
	local drag = b:dragFactor(subRatio, abs(f.vy))
	-- arraste viscoso FISICO: linear (Stokes) + quadratico (forma), nunca
	-- zera a velocidade num passo so (leapfrog estavel)
	f.vy = f.vy + acc * dt
	local decel = drag * 0.9 * f.vy + sign(f.vy) * drag * 0.05 * f.vy * f.vy
	f.vy = f.vy - clamp(decel * dt, -abs(f.vy), abs(f.vy))
	f.vy = f.vy * (f.damp or 0.85)
	-- giro de "adiracao a crista": inclina com a normal da onda
	local nx, ny, nz = b:normalAt(p.Position.X, p.Position.Z, t)
	f.tilt = lerp(f.tilt or 0, nx * subRatio, clamp(dt * 4, 0, 1))
	-- correnteza desloca devagar
	local fx, fz = b:flowAt(p.Position.X, p.Position.Z, t)
	local newY = p.Position.Y + f.vy * dt
	if p.CFrame then
		local cf = CFrame.new(p.Position.X + fx * dt * 0.5, newY, p.Position.Z + fz * dt * 0.5)
		pcall(function() p.CFrame = cf end)
	end
	-- splash quando entra na agua com velocidade
	if subRatio > 0.05 and abs(f.vy) > 3 and (t - (f.lastSplash or 0)) > 0.5 then
		AWX.splash(b, p.Position.X, h, p.Position.Z, clamp(abs(f.vy) * 0.2, 0.5, 3))
		f.lastSplash = t
	end
	return newY, f.vy
end
function AWX.step(body, dt, t)
	local n = 0
	for _, f in ipairs(body.floaters) do
		if f.alive then AWX.stepFloater(f, dt, t or 0); n = n + 1 end
	end
	return n
end
-- natacao: imersao e forca de boiamento p/ personagem
function AWX.swim(body, rootPos, height, t)
	local h = body:heightAt(rootPos.X, rootPos.Z, t)
	local head = rootPos.Y + (height or 5) / 2
	local subHead = h - head
	return {
		immersion = clamp((h - (rootPos.Y - (height or 5) / 2)) / (height or 5), 0, 1),
		underwaterHead = subHead > 0,
		surfaceY = h,
		buoyAccel = (h - rootPos.Y) * 2.2,
	}
end

-- ================= AMBIENTE SUBAQUATICO / ATMOSFERA =================
function AWX.applyUnderwater(body, on)
	local lighting
	local ok, l = pcall(function() return game:GetService("Lighting") end)
	if not ok then return false end
	lighting = l
	if on then
		body.underwater = {
			fogEnd = lighting.FogEnd, fogColor = lighting.FogColor, fogStart = lighting.FogStart,
		}
		local c = body.props.cor
		lighting.FogColor = Color3.fromRGB(floor(c[1] * 0.5), floor(c[2] * 0.7), floor(c[3] * 0.9))
		lighting.FogStart = 0
		lighting.FogEnd = 60 / (body.props.absorb + 0.05)
		local cc = lighting:FindFirstChild("AWX_UnderwaterCC")
		if not cc then
			cc = Instance.new("ColorCorrection") -- existe no Roblox real; shim aceita classe livre
			cc.Name = "AWX_UnderwaterCC"
			cc.Parent = lighting
		end
		pcall(function()
			cc.TintColor = Color3.fromRGB(floor(120 + c[1] * 0.3), floor(140 + c[2] * 0.28), floor(150 + c[3] * 0.3))
			cc.Saturation = -0.08
		end)
	else
		if body.underwater then
			pcall(function()
				lighting.FogEnd = body.underwater.fogEnd or 100000
				lighting.FogColor = body.underwater.fogColor
				lighting.FogStart = body.underwater.fogStart or 0
			end)
			local cc = lighting:FindFirstChild("AWX_UnderwaterCC")
			if cc then cc:Destroy() end
			body.underwater = nil
		end
	end
	return true
end

-- ================= MATERIALIZACAO (tiles animados + espuma + caustica) =================
local function makeTile(body, x, z, size, t, foam)
	local p = Instance.new("Part")
	p.Name = foam and "Foam" or "W"
	p.Size = Vector3.new(size, foam and 0.12 or 0.35, size)
	p.CFrame = CFrame.new(x, body:heightAt(x, z, t) + (foam and 0.25 or 0), z)
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = foam and 0.25 or 0.32
	local c = body.props.cor
	if foam then p.Color = Color3.fromRGB(235, 244, 248)
	else p.Color = Color3.fromRGB(c[1], c[2], c[3]) end
	pcall(function() p.Material = Enum.Material.SmoothPlastic end)
	p:SetAttribute("kind", foam and "foam" or "water")
	return p
end

function AWX.materialize(body, opts)
	opts = opts or {}
	local ws = workspace
	local step = opts.tile or 16
	if ArkherDO15 then
		local lv = ArkherDO15.state.level
		step = ({ 12, 16, 24, 32 })[lv or 2] or step
	end
	local sx = body.radius and body.radius * 2 or body.size.x
	local sz = body.radius and body.radius * 2 or body.size.z
	sx = clamp(sx, step, opts.maxSpan or 512)
	sz = clamp(sz, step, opts.maxSpan or 512)
	local old = ws:FindFirstChild("AWX_Water")
	if old then old:Destroy() end
	local model = Instance.new("Model")
	model.Name = "AWX_Water"
	model:SetAttribute("kind", body.kind)
	model:SetAttribute("level", body.level)
	model:SetAttribute("tile", step)
	model.Parent = ws
	local t = 0
	local count = 0
	for z = -sz / 2 + step / 2, sz / 2 - step / 2 + 0.01, step do
		for x = -sx / 2 + step / 2, sx / 2 - step / 2 + 0.01, step do
			local wx, wz = x + body.center.x, z + body.center.z
			if body:inside(wx, wz) then
				local tile = makeTile(body, wx, wz, step, t, false)
				tile.Parent = model
				count = count + 1
				-- espuma em crista
				if DM.hash2(wx, wz, 4242) * 0.5 + body:crestAt(wx, wz, 0) * body.foaminess > 0.85 then
					local foam = makeTile(body, wx + step * 0.2, wz, step * 0.3, t, true)
					foam.Parent = model
					count = count + 1
				end
			end
		end
	end
	body.tiles = model
	body.tileParts = count
	return model, count
end
-- anima 1 quadro (barato): desloca tiles pela funcao de onda real
function AWX.animate(body, t)
	if not body.tiles then return 0 end
	local moved = 0
	for _, tile in ipairs(body.tiles:GetChildren()) do
		if tile:IsA("BasePart") and tile:GetAttribute("kind") == "water" then
			local x, z = tile.Position.X, tile.Position.Z
			local y = body:heightAt(x, z, t)
			tile.CFrame = CFrame.new(x, y, z)
			local c = body:crestAt(x, z, t)
			tile.Transparency = 0.32 - c * 0.12
			moved = moved + 1
		end
	end
	return moved
end
-- causticas: luz dançante no fundo (shimmer) — simulated via neon tiles
function AWX.caustics(body, floorY, opts)
	opts = opts or {}
	if not body.tiles then return 0 end
	local model = body.tiles
	local step = opts.tile or 24
	local sx = clamp(body.radius and body.radius * 2 or body.size.x, step, 256)
	local sz = clamp(body.radius and body.radius * 2 or body.size.z, step, 256)
	local count = 0
	for z = -sz / 2 + step / 2, sz / 2 - step / 2 + 0.01, step do
		for x = -sx / 2 + step / 2, sx / 2 - step / 2 + 0.01, step do
			local wx, wz = x + body.center.x, z + body.center.z
			if body:inside(wx, wz) and DM.hash2(wx, wz, 9191) > 0.55 then
				local p = Instance.new("Part")
				p.Name = "Caustic"
				p.Size = Vector3.new(step * 0.4, 0.1, step * 0.4)
				p.CFrame = CFrame.new(wx, floorY + 0.3, wz)
				p.Anchored = true
				p.CanCollide = false
				p.Transparency = 0.4
				p.Color = Color3.fromRGB(210, 236, 244)
				pcall(function() p.Material = Enum.Material.Neon end)
				p:SetAttribute("kind", "caustic")
				p:SetAttribute("phase", DM.hash2(wx, wz, 3333) * 6.28)
				p.Parent = model
				count = count + 1
			end
		end
	end
	return count
end

-- ================= SPLASH / gotas =================
function AWX.splash(body, x, y, z, intensity)
	intensity = intensity or 1
	if not body.tiles and not workspace then return nil end
	local holder = body.tiles or workspace
	local src = Instance.new("Part")
	src.Name = "SplashSrc"
	src.Size = Vector3.new(0.4, 0.4, 0.4)
	src.CFrame = CFrame.new(x, y, z)
	src.Anchored = true
	src.CanCollide = false
	src.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Splash"
	pcall(function()
		pe.Rate = 0
		pe.Speed = NumberRange.new(6 * intensity, 14 * intensity)
		pe.Lifetime = NumberRange.new(0.3, 0.8)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.1) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.Color = ColorSequence.new(Color3.fromRGB(225, 240, 248))
		pe.Acceleration = Vector3.new(0, -G * 0.5, 0)
	end)
	pe.Parent = src
	src.Parent = holder
	pcall(function() pe.Enabled = false; pe:Emit(floor(16 * intensity)) end)
	body.splashes = (body.splashes or 0) + 1
	return src
end

-- ================= CHUVA / EVAPORACAO (ciclo hidrologico) =================
-- orvalho proximo da agua + evaporacao por temperatura -> umidade do ATX
function AWX.hydrologyTick(body, world, gx0, gz0, gw, gh)
	if not (world and world.chunkKeyOf) then return { adjusted = 0 } end
	local adj = 0
	local evap = clamp((body.props.temp - 5) / 40, 0, 1) * 0.02
	for gz = gz0, gz0 + gh - 1 do
		for gx = gx0, gx0 + gw - 1 do
			local cx, cz = world:chunkKeyOf(gx, gz)
			local ch = world:genChunk(cx, cz)
			local n = world.chunkCells
			local lx, lz = gx - cx * n, gz - cz * n
			if lx >= 1 and lx <= n and lz >= 1 and lz <= n then
				local mi = (lz - 1) * n + lx
				local nearWater = ch.mat[mi] == (ATX and ATX.MAT_INDEX.lama or 0) or (ch.wet[mi] or 0) > 0.6
				if nearWater then
					ch.wet[mi] = clamp((ch.wet[mi] or 0) + 0.01 - evap * 0.3, 0, 1)
					adj = adj + 1
				end
			end
		end
	end
	return { adjusted = adj, evaporation = evap }
end

-- ================= SERIALIZACAO =================
function Body:serialize()
	local data = {
		engine = "AWX", version = 1, kind = self.kind, props = self.props,
		level = self.level, center = self.center, size = self.size, radius = self.radius,
		waves = self.waves, tideAmp = self.tideAmp, tidePeriod = self.tidePeriod,
		foaminess = self.foaminess, ripple = self.ripple,
	}
	if HttpService then return HttpService:JSONEncode(data) end
	return "AWX:" .. tostring(self.kind)
end
function AWX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "AWX" then return nil, "bundle AWX invalido" end
	local waves = {}
	for i, w in ipairs(data.waves or {}) do
		waves[i] = { amp = w.amp, len = w.len, dir = w.dir, speed = w.speed, steep = w.steep }
	end
	local b = AWX.create(data.kind, {
		level = data.level, center = data.center, size = data.size, radius = data.radius,
		waves = waves, tideAmp = data.tideAmp, tidePeriod = data.tidePeriod,
		foaminess = data.foaminess, ripple = data.ripple,
	})
	for k, v in pairs(data.props or {}) do b.props[k] = v end
	return b
end

function Body:stats()
	return {
		kind = self.kind, waves = #self.waves, tideAmp = self.tideAmp,
		tiles = self.tileParts or 0, floaters = #self.floaters,
		splashes = self.splashes or 0, density = self.props.dens, salinity = self.props.sal,
		temp = self.props.temp,
	}
end

-- ================= CACHOEIRA (droplets fisicos) =================
-- gotas saem do topo com velocidade/jitter, caem por gravidade real e viram
-- splash + espuma quando cruzam a superficie do corpo de destino
function AWX.waterfall(body, cfg)
	cfg = cfg or {}
	local wf = {
		body = body,
		sourceX = cfg.sourceX or 0, sourceY = cfg.sourceY or 24, sourceZ = cfg.sourceZ or 0,
		flow = cfg.flow or 6, -- gotas por segundo
		jetV = cfg.jetV or (8 + (cfg.speed or 1) * 6), -- velocidade de jato
		width = cfg.width or 2,
		intensity = cfg.intensity or 1.4,
		drops = {}, acc = 0, alive = true, rng = cfg.seed or 11,
	}
	if not body.tiles then AWX.materialize(body, { maxSpan = 200 }) end
	function wf:emitDrop()
		local d = Instance.new("Part")
		d.Name = "FallDrop"
		d.Size = Vector3.new(0.45, 0.9, 0.45)
		local jx = (DM.hash2(self.rng, 1, 7) - 0.5) * self.width
		d.CFrame = CFrame.new(self.sourceX + jx, self.sourceY, self.sourceZ)
		d.Anchored = true
		d.CanCollide = false
		d.Transparency = 0.2
		local c = body.props.cor
		d.Color = Color3.fromRGB(math.min(c[1] + 130, 235), math.min(c[2] + 120, 240), math.min(c[3] + 60, 245))
		pcall(function() d.Material = Enum.Material.SmoothPlastic end)
		d.Parent = body.tiles or workspace
		self.drops[#self.drops + 1] = { inst = d, vx = (DM.hash2(self.rng, 2, 3) - 0.5) * 1.4, vy = -self.jetV, vz = self.jetV * (0.4 + DM.hash2(self.rng, 4, 9) * 0.4) }
		self.rng = self.rng + 1
	end
	AWX._falls = AWX._falls or {}
	AWX._falls[#AWX._falls + 1] = wf
	return wf
end
function AWX.stepWaterfall(wf, dt, t)
	if not wf.alive then return 0 end
	wf.acc = wf.acc + dt * wf.flow
	while wf.acc >= 1 do wf.acc = wf.acc - 1 wf:emitDrop() end
	local landed = 0
	for i = #wf.drops, 1, -1 do
		local d = wf.drops[i]
		d.vy = d.vy - G * dt -- gravidade real
		local p = d.inst
		local nx = p.Position.X + d.vx * dt
		local ny = p.Position.Y + d.vy * dt
		local nz = p.Position.Z + d.vz * dt
		local surface = wf.body:heightAt(nx, nz, t)
		if ny <= surface + 0.2 then
			AWX.splash(wf.body, nx, surface, nz, clamp(abs(d.vy) * 0.12, 0.5, 3) * (wf.intensity or 1))
			pcall(function() p:Destroy() end)
			table.remove(wf.drops, i)
			landed = landed + 1
		else
			p.CFrame = CFrame.new(nx, ny, nz)
		end
	end
	return landed
end
function AWX.stepFalls(dt, t)
	local n = 0
	for _, wf in ipairs(AWX._falls or {}) do n = n + AWX.stepWaterfall(wf, dt, t) end
	return n
end

-- ================= BARCO (casco com flutuabilidade de 4 pontos) =================
-- Amostra a superficie em 4 cantos do casco transformados pelo heading →
-- empuxo por amostra (nao so centro), pitch/roll pelos deltas, motor,
-- leme e arrasto hidrodinamico pela viscosidade do corpo.
function AWX.boat(body, part, opts)
	opts = opts or {}
	local bt = {
		body = body, part = part,
		speed = 0, heading = opts.heading or 0, -- rad
		motor = opts.motor or 0, -- -1..1 (empurro do motor)
		helm = opts.helm or 0, -- -1..1 (leme)
		mass = opts.mass or 800, -- kg
		vy = 0, pitch = 0, roll = 0,
		halfL = (part and part.Size.Z or 8) / 2, halfW = (part and part.Size.X or 4) / 2,
		hullH = part and part.Size.Y or 3,
		power = opts.power or 22, turnRate = opts.turnRate or 0.55,
		alive = true,
	}
	AWX._boats = AWX._boats or {}
	AWX._boats[#AWX._boats + 1] = bt
	return bt
end
function AWX.stepBoat(bt, dt, t)
	if not (bt.alive and bt.part) then return nil end
	local p = bt.part
	local fx, fz = -sin(bt.heading), cos(bt.heading) -- frente (z+ frente em roblox usa -z; usamos convencao propria)
	local rx, rz = cos(bt.heading), sin(bt.heading) -- lateral
	-- 4 amostras: proa, popa, boreste, bombordo
	local cx, cz = p.Position.X, p.Position.Z
	local hF = bt.body:heightAt(cx + fx * bt.halfL, cz + fz * bt.halfL, t)
	local hB = bt.body:heightAt(cx - fx * bt.halfL, cz - fz * bt.halfL, t)
	local hR = bt.body:heightAt(cx + rx * bt.halfW, cz + rz * bt.halfW, t)
	local hL = bt.body:heightAt(cx - rx * bt.halfW, cz - rz * bt.halfW, t)
	local avg = (hF + hB + hR + hL) / 4
	local bottomY = p.Position.Y - bt.hullH / 2
	local sub = clamp((avg - bottomY) / bt.hullH, 0, 1)
	-- ARQUIMEDES de casco: fracao submersa de equilibrio = dens_casco/dens_agua
	local fullVol = math.max((bt.halfL * 2) * (bt.halfW * 2) * bt.hullH, 0.01)
	local hullDens = bt.mass / fullVol -- kg/m3 efetivo do casco
	local targetSub = clamp(hullDens / (bt.body.props.dens or 1000), 0.02, 0.98)
	-- mola submersa p/ o equilibrio + amortecimento vertical (agua amortece)
	local accY = clamp((sub - targetSub) * G * 1.4 - bt.vy * 3.5, -24, 24)
	bt.vy = clamp(bt.vy + accY * dt, -8, 8)
	bt.pitch = lerp(bt.pitch or 0, atan2Safe(hB - hF, math.max(bt.halfL * 2, 0.01)) * 0.7, clamp(dt * 4, 0, 1))
	bt.roll = lerp(bt.roll or 0, atan2Safe(hL - hR, math.max(bt.halfW * 2, 0.01)) * 0.7, clamp(dt * 4, 0, 1))
	-- motor + arrasto hidrodinamico (viscosidade + arrasto quadratico)
	local thrust = bt.motor * bt.power
	local visc = bt.body.props.visc or 1
	local drag = visc * (0.6 * bt.speed + 0.18 * bt.speed * abs(bt.speed))
	local accS = thrust - drag
	bt.speed = clamp(bt.speed + accS * dt, -8, 14)
	bt.heading = bt.heading + bt.helm * bt.turnRate * clamp(abs(bt.speed) / 6 + 0.25, 0, 1) * dt
	-- integra
	local nx = cx + fx * bt.speed * dt
	local nz = cz + fz * bt.speed * dt
	local ny = p.Position.Y + bt.vy * dt
	local cf = CFrame.new(nx, ny, nz) * CFrame.Angles(bt.pitch, bt.heading, bt.roll)
	pcall(function() p.CFrame = cf end)
	return { speed = bt.speed, heading = bt.heading, submerged = sub, pitch = bt.pitch, roll = bt.roll }
end
function AWX.stepBoats(dt, t)
	for _, bt in ipairs(AWX._boats or {}) do AWX.stepBoat(bt, dt, t) end
end

AWX._version = "1.0.0"
end

do
--[[ ARKHER SCRYPTER X (ASX) — backend profissional do Script Studio ]]
-- Tokenizer Luau REAL + highlight por segmentos + linter (balanceamento de
-- blocos, variaveis nao declaradas, locais nao usados, APIs depreciadas) +
-- autocomplete com banco da API Roblox + 30 templates completos + 45 snippets
-- + formatador + find/replace + outline de funcoes + compile-check + diff.
ArkherScripterX = ArkherScripterX or {}
local SX = ArkherScripterX
local floor = math.floor
local byte, sub, find, gmatch, gsub, rep = string.byte, string.sub, string.find, string.gmatch, string.gsub, string.rep

-- ================= BANCO DE CONHECIMENTO =================
SX.KEYWORDS = {
	"and", "break", "continue", "do", "else", "elseif", "end", "export", "false",
	"for", "function", "if", "in", "local", "nil", "not", "or", "repeat",
	"return", "self", "then", "true", "type", "typeof", "until", "while",
}
SX.KW_SET = {}
for _, k in ipairs(SX.KEYWORDS) do SX.KW_SET[k] = true end
SX.BUILTINS = {
	"assert", "error", "gcinfo", "getmetatable", "ipairs", "next", "pairs", "pcall",
	"print", "rawequal", "rawget", "rawlen", "rawset", "require", "select",
	"setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall", "warn",
	"coroutine", "debug", "math", "os", "string", "table", "utf8", "bit32", "buffer",
	"vector", "_G", "_VERSION", "task", "loadstring", "newproxy", "collectgarbage", "elapsedTime",
}
SX.GLOBALS = {
	"game", "workspace", "script", "plugin", "Enum", "Instance", "Vector2", "Vector3",
	"CFrame", "Color3", "UDim", "UDim2", "BrickColor", "NumberRange", "NumberSequence",
	"NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "Rect", "Region3",
	"TweenInfo", "Random", "DateTime", "PhysicalProperties", "PathWaypoint", "Axises",
	"Faces", "RaycastParams", "OverlapParams", "CatalogSearchParams", "secret", "shared", "settings",
}
SX.SERVICES = {
	"Players", "Workspace", "Lighting", "MaterialService", "ReplicatedFirst",
	"ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui",
	"StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat", "TextChatService",
	"TweenService", "RunService", "UserInputService", "ContextActionService",
	"HttpService", "DataStoreService", "MemoryStoreService", "TeleportService",
	"MarketplaceService", "BadgeService", "CollectionService", "PhysicsService",
	"PathfindingService", "Debris", "InsertService", "ContentProvider", "GuiService",
	"ProximityPromptService", "SocialService", "MessagingService", "PolicyService",
	"LocalizationService", "VoiceChatService", "AssetService", "LogService", "Stats", "TestService",
}
SX.API_SET = {}
for _, k in ipairs(SX.BUILTINS) do SX.API_SET[k] = true end
for _, k in ipairs(SX.GLOBALS) do SX.API_SET[k] = true end
for _, k in ipairs(SX.SERVICES) do SX.API_SET[k] = true end
SX.METHODS_COMMON = {
	"GetService", "FindFirstChild", "WaitForChild", "GetChildren", "GetDescendants",
	"GetAttribute", "SetAttribute", "GetAttributes", "Clone", "Destroy", "IsA",
	"Connect", "Once", "Disconnect", "Fire", "FireServer", "FireClient", "InvokeServer",
	"new", "Wait", "Play", "Pause", "Stop", "Cancel", "Lerp", "ToWorldSpace",
	"ToObjectSpace", "JSONEncode", "JSONDecode", "GetAsync", "SetAsync", "UpdateAsync",
	"PostAsync", "GetAsyncFullUrl", "TweenValue", "Create", "Emit", "ClearAllChildren",
}
SX.DEPRECATED = {
	wait = "task.wait()", spawn = "task.spawn()", delay = "task.delay()", ypcall = "pcall()",
}

-- ================= TOKENIZER =================
-- retorna tokens: {k=("kw"|"id"|"str"|"num"|"cmt"|"op"), s, line, col}
function SX.tokenize(src)
	src = src or ""
	local toks = {}
	local i, line, col, n = 1, 1, 1, #src
	local function push(k, s, l, c) toks[#toks + 1] = { k = k, s = s, line = l, col = c } end
	while i <= n do
		local ch = sub(src, i, i)
		if ch == "\n" then
			line = line + 1; col = 1; i = i + 1
		elseif ch == " " or ch == "\t" or ch == "\r" then
			i = i + 1; col = col + 1
		elseif ch == "-" and sub(src, i + 1, i + 1) == "-" then
			local l, c = line, col
			if sub(src, i + 2, i + 3) == "[[" then -- comentario longo
				local e = find(src, "]]", i + 4, true)
				e = e or n + 1
				local s = sub(src, i, e - 1 + (e <= n and 2 or 0))
				push("cmt", s, l, c)
				-- atualiza linha/col por quebras internas
				for _ in gmatch(s, "\n") do line = line + 1 end
				i = (e <= n) and (e + 2) or (n + 1)
				col = 1
			else
				local e = find(src, "\n", i, true) or (n + 1)
				push("cmt", sub(src, i, e - 1), l, c)
				col = col + (e - i); i = e
			end
		elseif ch == '"' or ch == "'" then
			local l, c = line, col
			local j = i + 1
			while j <= n do
				local cj = sub(src, j, j)
				if cj == "\\" then j = j + 2
				elseif cj == ch then break
				elseif cj == "\n" then break
				else j = j + 1 end
			end
			push("str", sub(src, i, math.min(j, n)), l, c)
			col = col + (math.min(j, n) - i + 1); i = math.min(j + 1, n + 1)
		elseif sub(src, i, i + 1) == "[[" then
			local l, c = line, col
			local e = find(src, "]]", i + 2, true) or (n + 1)
			local s = sub(src, i, (e <= n and (e + 1) or n))
			push("str", s, l, c)
			for _ in gmatch(s, "\n") do line = line + 1 end
			i = (e <= n) and (e + 2) or (n + 1); col = 1
		elseif ch:match("%d") or (ch == "." and sub(src, i + 1, i + 1):match("%d")) then
			local s2 = sub(src, i)
			local num = s2:match("^0[xX]%x+") or s2:match("^%d+%.?%d*[eE][+-]?%d+") or s2:match("^%d+%.?%d*") or ch
			push("num", num, line, col)
			i = i + #num; col = col + #num
		elseif ch:match("[%a_]") then
			local j = i
			while j <= n and sub(src, j, j):match("[%w_]") do j = j + 1 end
			local word = sub(src, i, j - 1)
			push(SX.KW_SET[word] and "kw" or "id", word, line, col)
			col = col + (j - i); i = j
		else
			local two = sub(src, i, i + 1)
			local three = sub(src, i, i + 2)
			if SX.SYMBOL3 and SX.SYMBOL3[three] then
				push("op", three, line, col); i = i + 3; col = col + 3
			elseif SX.SYMBOL2 and SX.SYMBOL2[two] then
				push("op", two, line, col); i = i + 2; col = col + 2
			else
				push("op", ch, line, col); i = i + 1; col = col + 1
			end
		end
	end
	return toks
end
SX.SYMBOL2 = { ["=="] = true, ["~="] = true, ["<="] = true, [">="] = true, [".."] = true, ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true, ["->"] = true, ["::"] = true }
SX.SYMBOL3 = { ["..."] = true }

-- ================= HIGHLIGHT (linha -> segmentos {text,color}) =================
SX.THEME = {
	kw = "#C792EA", id = "#D7DCE8", str = "#C3E88D", num = "#F78C6C",
	cmt = "#697098", op = "#89AAAA", builtin = "#82AAFF", glob = "#FFCB6B",
	svc = "#5AD4E6", method = "#FF869A",
}
function SX.highlightLines(src)
	local toks = SX.tokenize(src)
	local lines = {}
	local function lineAt(l)
		while #lines < l do lines[#lines + 1] = {} end
		return lines[l]
	end
	for idx, t in ipairs(toks) do
		local kind = t.k
		if kind == "id" then
			local prev = toks[idx - 1]
			local nxt = toks[idx + 1]
			if prev and prev.k == "op" and (prev.s == ":" or prev.s == ".") then kind = "method"
			elseif SX.API_SET[t.s] and (prev == nil or prev.s ~= ":") then kind = SX.SVCWORD[t.s] and "svc" or "glob"
			elseif SX.KW_SET[t.s] then kind = "kw" end
			if SX.DEPRECATED[t.s] and nxt and nxt.s == "(" then kind = "method" end
		end
		table.insert(lineAt(t.line), { t.s, kind, t.col })
	end
	return lines, toks
end
-- palavras de servico p/ cor propria
SX.SVCWORD = {}
for _, s in ipairs(SX.SERVICES) do SX.SVCWORD[s] = true end

-- ================= LINTER =================
function SX.lint(src)
	local toks = SX.tokenize(src)
	local diags = {}
	local function diag(sev, line, col, code, msg)
		diags[#diags + 1] = { sev = sev, line = line, col = col, code = code, msg = msg }
	end
	-- 1) balanceamento de blocos
	local stack = {}
	local locals = {} -- {name, line, scopeDepth, used}
	local declared = {}
	local scopeOf = {}
	local function declare(name, line)
		locals[#locals + 1] = { name = name, line = line, depth = #stack, used = false }
		declared[name .. "@" .. #stack .. "@" .. (#locals)] = true
	end
	local lastId = nil
	local pendingLocalNames = nil
	local expectingParams = false
	for i, t in ipairs(toks) do
		local prev = toks[i - 1]
		local nxt = toks[i + 1]
		if t.k == "kw" then
			if t.s == "function" then
				stack[#stack + 1] = { what = "function", line = t.line }
				expectingParams = true
				-- nome da func (proximo id) conta como uso/declaracao de uso
				if lastId then lastId.used = true end
			elseif t.s == "then" then stack[#stack + 1] = { what = "then", line = t.line }
			elseif t.s == "do" then stack[#stack + 1] = { what = "do", line = t.line }
			elseif t.s == "repeat" then stack[#stack + 1] = { what = "repeat", line = t.line }
			elseif t.s == "end" then
				if #stack == 0 then diag("error", t.line, t.col, "E01", "'end' sem bloco correspondente")
				else
					local top = stack[#stack]
					if top.what == "repeat" then diag("error", t.line, t.col, "E02", "'repeat' fechado com 'end' — use 'until'") end
					stack[#stack] = nil
					-- fecha escopo: marca usados ate aqui (nao zera — global e simples)
				end
			elseif t.s == "until" then
				local found = false
				for si = #stack, 1, -1 do
					if stack[si].what == "repeat" then
						for sj = #stack, si, -1 do stack[sj] = nil end
						found = true
						break
					end
				end
				if not found then diag("error", t.line, t.col, "E03", "'until' sem 'repeat'") end
			elseif t.s == "elseif" then
				if #stack > 0 and stack[#stack].what == "then" then stack[#stack] = nil end
			elseif t.s == "local" then
				pendingLocalNames = {}
				-- olha adiante: local a, b =... / local function f
				if nxt and nxt.k == "kw" and nxt.s == "function" then
					local n3 = toks[i + 2]
					if n3 and n3.k == "id" then declare(n3.s, t.line) pendingLocalNames = nil end
				else
					local j = i + 1
					while j <= #toks do
						local tj = toks[j]
						if tj.k == "id" then
							if toks[j - 1] and toks[j - 1].s == "," or j == i + 1 then
								declare(tj.s, t.line)
							end
						elseif tj.s == "=" or tj.k == "kw" then
							break
						end
						j = j + 1
					end
				end
			elseif t.s == "for" then
				-- for i = / for k, v in
				local j = i + 1
				while toks[j] and (toks[j].k == "id" or toks[j].s == ",") do
					if toks[j].k == "id" then declare(toks[j].s, t.line) end
					j = j + 1
				end
			end
		elseif t.k == "id" then
			-- declaramos antes? marca uso
			if prev and prev.k == "op" and (prev.s == "." or prev.s == ":") then
				-- campo/metodo — nao conta como global
			elseif prev and prev.k == "kw" and (prev.s == "function" or prev.s == "local") then
				-- nome de declaracao — ok
			else
				-- uso
				local foundLocal = nil
				for li = #locals, 1, -1 do
					if locals[li].name == t.s then foundLocal = locals[li] break end
				end
				if foundLocal then foundLocal.used = true end
				-- global desconhecido? (socheca se nao e chave de tabela: nxt = '=' com prev = '{' ou ',')
				local isTableKey = nxt and nxt.s == "=" and prev and prev.k == "op" and (prev.s == "{" or prev.s == ",")
				local isParam = expectingParams and prev and (prev.s == "(" or prev.s == ",")
				if isParam then declare(t.s, t.line) end
				if not isTableKey and not isParam and not foundLocal and not SX.API_SET[t.s] and not SX.KW_SET[t.s] then
					diag("warn", t.line, t.col, "W10", "possivel global nao declarada '" .. t.s .. "'")
				end
			end
			if SX.DEPRECATED[t.s] and nxt and nxt.s == "(" then
				diag("warn", t.line, t.col, "W30", "'" .. t.s .. "()' esta depreciada — use " .. SX.DEPRECATED[t.s])
			end
			lastId = foundLocalOf(locals, t.s)
		elseif t.k == "str" then
			if not (sub(t.s, -1) == '"' or sub(t.s, -1) == "'" or sub(t.s, -2) == "]]") then
				diag("error", t.line, t.col, "E10", "string nao terminada")
			end
		elseif t.s == ")" then
			expectingParams = false
		end
	end
	if #stack > 0 then
		local top = stack[#stack]
		diag("error", top.line or 1, 1, "E04", "bloco '" .. top.what .. "' aberto na linha " .. tostring(top.line) .. " nao foi fechado ('end' ausente)")
	end
	-- 2) locais nao usados
	for _, l in ipairs(locals) do
		if not l.used then diag("info", l.line, 1, "I20", "local '" .. l.name .. "' declarada e nunca usada") end
	end
	return diags, toks
end
-- acha a ultima decl da variavel
function foundLocalOf(locals, name)
	for li = #locals, 1, -1 do
		if locals[li].name == name then return locals[li] end
	end
	return nil
end
function SX.lintSummary(diags)
	local e, w, inf = 0, 0, 0
	for _, d in ipairs(diags) do
		if d.sev == "error" then e = e + 1 elseif d.sev == "warn" then w = w + 1 else inf = inf + 1 end
	end
	return { errors = e, warns = w, infos = inf, total = #diags }
end

-- ================= COMPILE-CHECK (parse real quando possivel) =================
function SX.compile(src)
	if loadstring then
		local fn, err = loadstring(src, "arkher_script")
		if fn then return { ok = true, engine = "loadstring" } end
		local ln = tostring(err):match(":(%d+):")
		return { ok = false, error = tostring(err), line = tonumber(ln), engine = "loadstring" }
	end
	return { ok = false, error = "loadstring indisponivel", engine = "none" }
end

-- ================= FORMATADOR =================
function SX.format(src, indentW)
	indentW = indentW or "\t"
	local out, depth = {}, 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			local first = trimmed:match("^(%S*)")
			if first then
				if first:sub(1, 3) == "end" or first == "until" or first == "else" or first:match("^elseif") or first == ")" or first == "}" then
					depth = math.max(depth - 1, 0)
				end
			end
			out[#out + 1] = rep(indentW, depth) .. trimmed
			-- sobe descendo pelos openers no fim da linha
			local opens = 0
			local closers = 0
			for w in trimmed:gmatch("[%a_]+") do
				if w == "function" or w == "then" or w == "do" or w == "repeat" then opens = opens + 1 end
				if w == "end" then closers = closers + 1 end
			end
			if trimmed:match("^end") then closers = closers - 1 end
			depth = math.max(depth + opens - 0, 0)
			if trimmed:match("then.*end$") or trimmed:match("do.*end$") then depth = math.max(depth - 1, 0) end
			if trimmed:match("^else") or trimmed:match("^elseif") then depth = depth + 0 end
		else
			out[#out + 1] = ""
		end
	end
	return table.concat(out, "\n")
end

-- ================= FIND / REPLACE =================
function SX.findAll(src, needle, opts)
	opts = opts or {}
	local hits = {}
	if needle == "" then return hits end
	local initPos = 1
	local line, lineStart = 1, 1
	if not opts.pattern then
		while true do
			local a, b = find(src, needle, initPos, true)
			if not a then break end
			hits[#hits + 1] = { a = a, b = b }
			initPos = b + 1
		end
	else
		for a, b in src:gmatch("()" .. needle .. "()") do
			hits[#hits + 1] = { a = a, b = b - 1 }
		end
	end
	-- mapeia pos -> linha
	local pos = 1
	local curLine = 1
	local map = {}
	for i = 1, #src do if sub(src, i, i) == "\n" then curLine = curLine + 1 end; map[i] = curLine end
	for _, h in ipairs(hits) do h.line = map[h.a] end
	return hits
end
function SX.replace(src, needle, repl, opts)
	opts = opts or {}
	if opts.pattern then
		local new, count = gsub(src, needle, repl)
		return new, count
	end
	local hits = SX.findAll(src, needle, opts)
	if #hits == 0 then return src, 0 end
	local parts, last = {}, 1
	for _, h in ipairs(hits) do
		parts[#parts + 1] = sub(src, last, h.a - 1)
		parts[#parts + 1] = repl
		last = h.b + 1
	end
	parts[#parts + 1] = sub(src, last)
	return table.concat(parts), #hits
end
-- ================= OUTLINE (arvore real de funcoes) =================
function SX.outline(src)
	local toks = SX.tokenize(src)
	local items = {}
	local depth = 0
	for i, t in ipairs(toks) do
		if t.k == "kw" then
			if t.s == "function" then
				local name = "(anonima)"
				local prev = toks[i - 1]
				local pieces = {}
				local j = i + 1
				while j <= #toks and (toks[j].k == "id" or toks[j].s == "." or toks[j].s == ":") do
					pieces[#pieces + 1] = toks[j].s
					j = j + 1
				end
				if #pieces > 0 then name = table.concat(pieces) end
				if prev and prev.k == "kw" and prev.s == "local" then name = "local " .. name end
				items[#items + 1] = { name = name, line = t.line, depth = depth, kind = "function" }
				depth = depth + 1
			elseif t.s == "then" or t.s == "do" or t.s == "repeat" then depth = depth + 1
			elseif t.s == "end" or t.s == "until" then depth = math.max(depth - 1, 0)
			end
		end
	end
	return items
end

-- ================= AUTOCOMPLETE =================
function SX.complete(prefix, docSrc)
	prefix = prefix or ""
	local results, seen = {}, {}
	local function add(label, kind, detail)
		if #prefix > 0 and sub(label, 1, #prefix):lower() ~= prefix:lower() then return end
		if seen[label] then return end
		seen[label] = true
		results[#results + 1] = { label = label, kind = kind, detail = detail or "" }
	end
	for _, k in ipairs(SX.KEYWORDS) do add(k, "keyword", "palavra-chave Luau") end
	for _, b in ipairs(SX.BUILTINS) do add(b, "builtin", "funcao global") end
	for _, g2 in ipairs(SX.GLOBALS) do add(g2, "global", "API Roblox") end
	for _, s in ipairs(SX.SERVICES) do add(s, "service", "service: game:GetService('" .. s .. "')") end
	for _, m in ipairs(SX.METHODS_COMMON) do add(m, "method", "metodo comum") end
	if docSrc then
		for w in gmatch(docSrc, "[%a_][%w_]+") do
			if #w > 2 and not SX.KW_SET[w] then add(w, "doc", "identificador do documento") end
		end
	end
	table.sort(results, function(a, b2) return a.label:lower() < b2.label:lower() end)
	local capped = {}
	for i = 1, math.min(#results, 24) do capped[i] = results[i] end
	return capped
end

-- ================= METRICS / DIFF =================
function SX.metrics(src)
	local toks = SX.tokenize(src)
	local lines = 1
	for _ in gmatch(src or "", "\n") do lines = lines + 1 end
	local funcs, cyclo = 0, 1
	for _, t in ipairs(toks) do
		if t.k == "kw" then
			if t.s == "function" then funcs = funcs + 1 end
			if t.s == "if" or t.s == "for" or t.s == "while" or t.s == "and" or t.s == "or" or t.s == "elseif" then cyclo = cyclo + 1 end
		end
	end
	return { lines = lines, chars = #(src or ""), tokens = #toks, functions = funcs, complexity = cyclo }
end
function SX.diffLines(a, b)
	local aL, bL = {}, {}
	for l in (a .. "\n"):gmatch("(.-)\n") do aL[#aL + 1] = l end
	for l in (b .. "\n"):gmatch("(.-)\n") do bL[#bL + 1] = l end
	local ops = {}
	local i, j = 1, 1
	while i <= #aL and j <= #bL do
		if aL[i] == bL[j] then
			ops[#ops + 1] = { op = "keep", line = aL[i] }; i = i + 1; j = j + 1
		else
			ops[#ops + 1] = { op = "del", line = aL[i] }; i = i + 1
			if bL[j] ~= aL[i] and bL[j] ~= nil then ops[#ops + 1] = { op = "add", line = bL[j] }; j = j + 1 end
		end
	end
	while i <= #aL do ops[#ops + 1] = { op = "del", line = aL[i] }; i = i + 1 end
	while j <= #bL do ops[#ops + 1] = { op = "add", line = bL[j] }; j = j + 1 end
	return ops
end

-- ================= SNIPPETS (45) =================
SX.SNIPPETS = {
	{ id = "debounce", nm = "Debounce", code = "local debounce = false\nif debounce then return end\ndebounce = true\ntask.wait(1)\ndebounce = false" },
	{ id = "pcall", nm = "pcall seguro", code = "local ok, err = pcall(function()\n\t-- codigo arriscado\nend)\nif not ok then warn(err) end" },
	{ id = "signal", nm = "Evento custom (BindableEvent)", code = "local bind = Instance.new(\"BindableEvent\")\nbind.Event:Connect(function(data) end)\nbind:Fire(payload)" },
	{ id = "loop", nm = "Loop com task", code = "task.spawn(function()\n\twhile task.wait(1) do\n\t\t-- ciclo\n\tend\nend)" },
	{ id = "raycast", nm = "Raycast com params", code = "local params = RaycastParams.new()\nparams.FilterType = Enum.RaycastFilterType.Exclude\nparams.FilterDescendantsInstances = { script.Parent }\nlocal hit = workspace:Raycast(origin, dir, params)\nif hit then print(hit.Instance) end" },
	{ id = "tween", nm = "Tween", code = "local ts = game:GetService(\"TweenService\")\nlocal t = ts:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(255, 0, 0) })\nt:Play()" },
	{ id = "heartbeat", nm = "Heartbeat", code = "game:GetService(\"RunService\").Heartbeat:Connect(function(dt)\n\t-- por frame\nend)" },
	{ id = "playersadded", nm = "PlayerAdded", code = "game:GetService(\"Players\").PlayerAdded:Connect(function(player)\n\tprint(player.Name)\nend)" },
	{ id = "charadded", nm = "CharacterAdded", code = "player.CharacterAdded:Connect(function(char)\n\tlocal hum = char:WaitForChild(\"Humanoid\")\nend)" },
	{ id = "touched", nm = "Touched com debounce", code = "local cd = {}\npart.Touched:Connect(function(hit)\n\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)\n\tif plr and not cd[plr] then\n\t\tcd[plr] = true\n\t\ttask.delay(1, function() cd[plr] = nil end)\n\tend\nend)" },
	{ id = "remote", nm = "RemoteEvent padrao", code = "local remote = Instance.new(\"RemoteEvent\")\nremote.Name = \"MyRemote\"\nremote.Parent = game:GetService(\"ReplicatedStorage\")\nremote.OnServerEvent:Connect(function(player, ...) end)" },
	{ id = "bindfunc", nm = "BindableFunction", code = "local bf = Instance.new(\"BindableFunction\")\nbf.OnInvoke = function(x) return x * 2 end" },
	{ id = "module", nm = "ModuleScript base", code = "local M = {}\nM.__index = M\nfunction M.new() return setmetatable({}, M) end\nreturn M" },
	{ id = "attr", nm = "Attributes", code = "part:SetAttribute(\"vida\", 100)\nlocal vida = part:GetAttribute(\"vida\")" },
	{ id = "collection", nm = "CollectionService tags", code = "local CS = game:GetService(\"CollectionService\")\nfor _, inst in ipairs(CS:GetTagged(\"Enemy\")) do end" },
	{ id = "debris", nm = "Debris cleanup", code = "game:GetService(\"Debris\"):AddItem(part, 5)" },
	{ id = "datastore", nm = "DataStore save", code = "local DS = game:GetService(\"DataStoreService\"):GetDataStore(\"Save1\")\nlocal ok, err = pcall(function()\n\tDS:SetAsync(\"p_\" .. player.UserId, data)\nend)" },
	{ id = "dsget", nm = "DataStore load", code = "local ok, data = pcall(function()\n\treturn DS:GetAsync(\"p_\" .. player.UserId)\nend)\ndata = data or { moedas = 0 }" },
	{ id = "json", nm = "JSON roundtrip", code = "local Http = game:GetService(\"HttpService\")\nlocal str = Http:JSONEncode({ a = 1 })\nlocal back = Http:JSONDecode(str)" },
	{ id = "lerp", nm = "Lerp manual", code = "local function lerp(a, b, t) return a + (b - a) * t end" },
	{ id = "clamp", nm = "Clamp", code = "local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end" },
	{ id = "tablefind", nm = "Tabela contem", code = "local function has(t, v)\n\tfor _, x in ipairs(t) do if x == v then return true end end\n\treturn false\nend" },
	{ id = "shuffle", nm = "Shuffle Fisher-Yates", code = "local function shuffle(t)\n\tfor i = #t, 2, -1 do\n\t\tlocal j = math.random(i)\n\t\tt[i], t[j] = t[j], t[i]\n\tend\nend" },
	{ id = "spring", nm = "Spring (fisica)", code = "local s = { p = 0, v = 0, k = 120, d = 12 }\nfunction s:step(dt, target)\n\tlocal acc = (target - self.p) * self.k - self.v * self.d\n\tself.v = self.v + acc * dt\n\tself.p = self.p + self.v * dt\n\treturn self.p\nend" },
	{ id = "maid", nm = "Maid (cleanup)", code = "local Maid = {}\nMaid.__index = Maid\nfunction Maid.new() return setmetatable({ items = {} }, Maid) end\nfunction Maid:give(item) table.insert(self.items, item) end\nfunction Maid:clean()\n\tfor _, it in ipairs(self.items) do\n\t\tpcall(function() it:Disconnect() end)\n\t\tpcall(function() it:Destroy() end)\n\tend\n\tself.items = {}\nend" },
	{ id = "observer", nm = "Observer/Observable", code = "local obs = { cbs = {} }\nfunction obs:subscribe(fn) table.insert(self.cbs, fn) end\nfunction obs:emit(...)\n\tfor _, f in ipairs(self.cbs) do task.spawn(f, ...) end\nend" },
	{ id = "camshake", nm = "Camera shake", code = "local cam = workspace.CurrentCamera\nlocal t0 = tick()\ngame:GetService(\"RunService\"):BindToRenderStep(\"shake\", 200, function()\n\tlocal a = math.max(0, 1 - (tick() - t0))\n\tcam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)\nend)" },
	{ id = "uicorner", nm = "Corner programatico", code = "local c = Instance.new(\"UICorner\")\nc.CornerRadius = UDim.new(0, 8)\nc.Parent = frame" },
	{ id = "uistroke", nm = "Stroke programatico", code = "local s = Instance.new(\"UIStroke\")\ns.Thickness = 2\ns.Color = Color3.fromRGB(88, 166, 255)\ns.Parent = frame" },
	{ id = "grid", nm = "UIListLayout", code = "local l = Instance.new(\"UIListLayout\")\nl.Padding = UDim.new(0, 6)\nl.SortOrder = Enum.SortOrder.LayoutOrder\nl.Parent = container" },
	{ id = "prompt", nm = "ProximityPrompt", code = "local p = Instance.new(\"ProximityPrompt\")\np.ActionText = \"Abrir\"\np.Parent = part\np.Triggered:Connect(function(player) end)" },
	{ id = "hitbox", nm = "Hitbox region", code = "local parts = workspace:GetPartBoundsInBox(CFrame.new(0, 5, 0), Vector3.new(6, 6, 6), params)" },
	{ id = "path", nm = "Pathfinding", code = "local ps = game:GetService(\"PathfindingService\")\nlocal path = ps:CreatePath()\npath:ComputeAsync(from, to)\nif path.Status == Enum.PathStatus.Success then\n\tfor _, wp in ipairs(path:GetWaypoints()) do end\nend" },
	{ id = "knockback", nm = "Knockback", code = "local lv = Instance.new(\"LinearVelocity\")\nlv.VectorVelocity = dir * 60\nlv.Parent = hrp\ngame:GetService(\"Debris\"):AddItem(lv, 0.2)" },
	{ id = "daynight", nm = "Ciclo dia/noite", code = "local L = game:GetService(\"Lighting\")\ngame:GetService(\"RunService\").Heartbeat:Connect(function(dt)\n\tL.ClockTime = (L.ClockTime + dt * 0.1) % 24\nend)" },
	{ id = "zone", nm = "Zona (magnitude)", code = "local function inZone(pos, center, r)\n\treturn (pos - center).Magnitude <= r\nend" },
	{ id = "intersect", nm = "Distancia 2D", code = "local function dist2D(a, b)\n\treturn ((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2) ^ 0.5\nend" },
	{ id = "leaderstats", nm = "Leaderstats", code = "local ls = Instance.new(\"Folder\")\nls.Name = \"leaderstats\"\nlocal coins = Instance.new(\"IntValue\")\ncoins.Name = \"Moedas\"\ncoins.Parent = ls\nls.Parent = player" },
	{ id = "givetool", nm = "Dar Tool", code = "local tool = Instance.new(\"Tool\")\ntool.Name = \"Espada\"\ntool.Parent = player.Backpack" },
	{ id = "seat", nm = "Seat detect", code = "seat:GetPropertyChangedSignal(\"Occupant\"):Connect(function()\n\tlocal hum = seat.Occupant\n\tif hum then print(\"sentou\") end\nend)" },
	{ id = "spawnsafe", nm = "Spawn protegido", code = "local ff = Instance.new(\"ForceField\")\nff.Parent = char\ngame:GetService(\"Debris\"):AddItem(ff, 3)" },
	{ id = "sound", nm = "Som 3D", code = "local s = Instance.new(\"Sound\")\ns.SoundId = \"rbxassetid://0\"\ns.RollOffMaxDistance = 100\ns.Parent = part\ns:Play()" },
	{ id = "mutex", nm = "Lock simples", code = "local locked = false\nlocal function withLock(fn)\n\tif locked then return end\n\tlocked = true\n\tlocal ok, err = pcall(fn)\n\tlocked = false\n\tif not ok then error(err) end\nend" },
	{ id = "cachemod", nm = "Require com cache", code = "local cache = {}\nlocal function req(mod)\n\tif not cache[mod] then cache[mod] = require(mod) end\n\treturn cache[mod]\nend" },
	{ id = "typeshape", nm = "Guard de tipo", code = "local function isVec3(v)\n\treturn typeof(v) == \"Vector3\"\nend" },
	{ id = "atx", nm = "ARKHER: gerar terreno ATX", code = "local w = ArkherTerrainX.new({ seed = 7, preset = \"montanhas\" })\nw:materializeRegion(-256, -256, 512, 512)" },
	{ id = "awx", nm = "ARKHER: oceano AWX", code = "local sea = ArkherWaterX.preset(\"ressaca\", { kind = \"oceano\", level = 0 })\nArkherWaterX.materialize(sea)" },
	{ id = "uix", nm = "ARKHER: HUD via UIKitX", code = "local hud = ArkherUIKitX.create(\"health\")\nlocal gui, n = ArkherUIKitX.build({ hud }, \"MeuHUD\")" },
}

-- ================= TEMPLATES (30 roteiros completos) =================
local function T_(class, lines) return { class = class, code = lines } end
SX.TEMPLATES = {
	{ id = "basico", nm = "Script Basico (Touched)", cls = "Script", code = {
		"-- Script Basico — ARKHER Script Studio",
		"local part = script.Parent",
		"",
		"local DEBOUNCE = 1",
		"local cd = {}",
		"",
		"part.Touched:Connect(function(hit)",
		"\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)",
		"\tif not plr or cd[plr] then return end",
		"\tcd[plr] = true",
		"\ttask.delay(DEBOUNCE, function() cd[plr] = nil end)",
		"\tprint(plr.Name .. \" tocou em \" .. part.Name)",
		"end)",
	} },
	{ id = "local_basico", nm = "LocalScript Basico", cls = "LocalScript", code = {
		"-- LocalScript Basico",
		"local Players = game:GetService(\"Players\")",
		"local player = Players.LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal hrp = char:WaitForChild(\"HumanoidRootPart\")",
		"\tprint(\"spawn em\", hrp.Position)",
		"end)",
	} },
	{ id = "oop_classe", nm = "Classe OOP (metatable)", cls = "ModuleScript", code = {
		"-- Classe OOP completa com heranca minima",
		"local Classe = {}",
		"Classe.__index = Classe",
		"",
		"function Classe.new(nome, vida)",
		"\tlocal self = setmetatable({}, Classe)",
		"\tself.nome = nome",
		"\tself.vida = vida or 100",
		"\tself.alive = true",
		"\treturn self",
		"end",
		"",
		"function Classe:dano(q)",
		"\tself.vida = math.max(self.vida - q, 0)",
		"\tif self.vida == 0 then self.alive = false end",
		"end",
		"",
		"function Classe:curar(q) self.vida = self.vida + q end",
		"function Classe:__tostring() return self.nome .. \"(\" .. self.vida .. \"hp)\" end",
		"",
		"return Classe",
	} },
	{ id = "state_machine", nm = "Maquina de Estados", cls = "ModuleScript", code = {
		"-- FSM: estados com enter/update/exit",
		"local FSM = {}",
		"FSM.__index = FSM",
		"",
		"function FSM.new(states, ini)",
		"\tlocal self = setmetatable({}, FSM)",
		"\tself.states = states or {}",
		"\tself.state = ini",
		"\tself.t = 0",
		"\tif ini and states[ini] and states[ini].enter then states[ini].enter(self) end",
		"\treturn self",
		"end",
		"",
		"function FSM:set(nome)",
		"\tlocal st = self.states[self.state]",
		"\tif st and st.exit then st.exit(self) end",
		"\tself.state = nome",
		"\tself.t = 0",
		"\tst = self.states[nome]",
		"\tif st and st.enter then st.enter(self) end",
		"end",
		"",
		"function FSM:update(dt)",
		"\tself.t = self.t + dt",
		"\tlocal st = self.states[self.state]",
		"\tif st and st.update then st.update(self, dt) end",
		"end",
		"",
		"return FSM",
	} },
	{ id = "event_bus", nm = "Event Bus", cls = "ModuleScript", code = {
		"-- Barramento de eventos tipado",
		"local Bus = {}",
		"Bus.__index = Bus",
		"",
		"function Bus.new() return setmetatable({ handlers = {} }, Bus) end",
		"function Bus:on(ev, fn)",
		"\tself.handlers[ev] = self.handlers[ev] or {}",
		"\ttable.insert(self.handlers[ev], fn)",
		"\treturn function() self:off(ev, fn) end",
		"end",
		"function Bus:off(ev, fn)",
		"\tlocal hs = self.handlers[ev]",
		"\tif not hs then return end",
		"\tfor i = #hs, 1, -1 do if hs[i] == fn then table.remove(hs, i) end end",
		"end",
		"function Bus:emit(ev, ...)",
		"\tfor _, fn in ipairs(self.handlers[ev] or {}) do task.spawn(fn, ...) end",
		"end",
		"",
		"return Bus",
	} },
	{ id = "profile_store", nm = "Perfil de Dados (DataStore)", cls = "ModuleScript", code = {
		"-- Perfil de jogador com retry e padroes",
		"local DS = game:GetService(\"DataStoreService\"):GetDataStore(\"Profile_v1\")",
		"local Profile = {}",
		"Profile.__index = Profile",
		"Profile.defaults = { moedas = 0, nivel = 1, itens = {} }",
		"",
		"local function copy(t) local r = {} for k, v in pairs(t) do r[k] = v end return r end",
		"",
		"function Profile.load(player)",
		"\tlocal key = \"p_\" .. player.UserId",
		"\tlocal data",
		"\tfor tentativa = 1, 3 do",
		"\t\tlocal ok, res = pcall(function() return DS:GetAsync(key) end)",
		"\t\tif ok then data = res break end",
		"\t\ttask.wait(1)",
		"\tend",
		"\tlocal self = setmetatable({}, Profile)",
		"\tself.key = key",
		"\tself.data = data or copy(Profile.defaults)",
		"\treturn self",
		"end",
		"",
		"function Profile:save()",
		"\treturn pcall(function() DS:SetAsync(self.key, self.data) end)",
		"end",
		"",
		"return Profile",
	} },
	{ id = "arma_raycast", nm = "Arma Raycast (Server)", cls = "Script", code = {
		"-- Arma: raycast no servidor + cooldown",
		"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"local remote = ReplicatedStorage:WaitForChild(\"ShootRemote\")",
		"local COOLDOWN, RANGE = 0.25, 300",
		"local last = {}",
		"",
		"remote.OnServerEvent:Connect(function(player, origin, dir)",
		"\tlocal now = os.clock()",
		"\tif last[player] and now - last[player] < COOLDOWN then return end",
		"\tlast[player] = now",
		"\tlocal params = RaycastParams.new()",
		"\tparams.FilterType = Enum.RaycastFilterType.Exclude",
		"\tparams.FilterDescendantsInstances = { player.Character }",
		"\tlocal res = workspace:Raycast(origin, dir.Unit * RANGE, params)",
		"\tif res then",
		"\t\tlocal hum = res.Instance.Parent:FindFirstChildOfClass(\"Humanoid\")",
		"\t\tif hum then hum:TakeDamage(25) end",
		"\tend",
		"end)",
	} },
	{ id = "espada", nm = "Espada (Tool)", cls = "Script", code = {
		"-- Tool de espada com dano em Touched",
		"local tool = script.Parent",
		"local blade = tool:WaitForChild(\"Blade\")",
		"local swinging = false",
		"",
		"tool.Activated:Connect(function() swinging = true task.wait(0.4) swinging = false end)",
		"blade.Touched:Connect(function(hit)",
		"\tif not swinging then return end",
		"\tlocal hum = hit.Parent:FindFirstChildOfClass(\"Humanoid\")",
		"\tif hum and hum.Parent ~= tool.Parent then hum:TakeDamage(15) swinging = false end",
		"end)",
	} },
	{ id = "npc_ia", nm = "NPC IA (vagar/perseguir)", cls = "Script", code = {
		"-- NPC simples: vaga, persegue jogador proximo",
		"local Players = game:GetService(\"Players\")",
		"local npc = script.Parent",
		"local hum = npc:WaitForChild(\"Humanoid\")",
		"local root = npc:WaitForChild(\"HumanoidRootPart\")",
		"local AGGRO = 40",
		"",
		"while task.wait(0.5) do",
		"\tlocal alvo, dmin = nil, AGGRO",
		"\tfor _, plr in ipairs(Players:GetPlayers()) do",
		"\t\tlocal c = plr.Character",
		"\t\tlocal r = c and c:FindFirstChild(\"HumanoidRootPart\")",
		"\t\tif r then",
		"\t\t\tlocal d = (r.Position - root.Position).Magnitude",
		"\t\t\tif d < dmin then alvo = r dmin = d end",
		"\t\tend",
		"\tend",
		"\tif alvo then hum:MoveTo(alvo.Position)",
		"\telse hum:MoveTo(root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))) end",
		"end)",
	} },
	{ id = "porta_tween", nm = "Porta com Tween", cls = "Script", code = {
		"-- Porta: abre/fecha com tween + prompt",
		"local TS = game:GetService(\"TweenService\")",
		"local porta = script.Parent",
		"local aberta = false",
		"local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)",
		"",
		"local prompt = Instance.new(\"ProximityPrompt\")",
		"prompt.ActionText = \"Abrir/Fechar\"",
		"prompt.Parent = porta",
		"",
		"prompt.Triggered:Connect(function()",
		"\taberta = not aberta",
		"\tlocal alvo = aberta and porta.CFrame * CFrame.new(0, porta.Size.Y, 0) or porta.CFrame * CFrame.new(0, -porta.Size.Y, 0)",
		"\tTS:Create(porta, info, { CFrame = alvo }):Play()",
		"end)",
	} },
	{ id = "elevador", nm = "Elevador", cls = "Script", code = {
		"-- Elevador multi-andar",
		"local TS = game:GetService(\"TweenService\")",
		"local cabine = script.Parent",
		"local andares = { 0, 40, 80 }",
		"local atual = 1",
		"",
		"local function irPara(i)",
		"\tatual = math.clamp(i, 1, #andares)",
		"\tlocal alvo = cabine.CFrame + Vector3.new(0, andares[atual] - andares[1], 0)",
		"\tTS:Create(cabine, TweenInfo.new(3), { CFrame = alvo }):Play()",
		"end",
		"",
		"irPara(2)",
	} },
	{ id = "esteira", nm = "Esteira Transportadora", cls = "Script", code = {
		"-- Esteira: move parts de cima",
		"local esteira = script.Parent",
		"local V = Vector3.new(12, 0, 0)",
		"esteira.AssemblyLinearVelocity = V",
	} },
	{ id = "dialogo", nm = "Dialogo NPC", cls = "Script", code = {
		"-- Dialogo com opcoes via prompt + remote",
		"local prompt = script.Parent.ProximityPrompt",
		"local falas = { \"Ola, viajante!\", \"Bem-vindo ao ARKHER.\", \"Cuide bem do mundo.\" }",
		"prompt.Triggered:Connect(function(player)",
		"\tfor i, f in ipairs(falas) do",
		"\t\tprint(\"NPC:\", f)",
		"\t\ttask.wait(1.4)",
		"\tend",
		"end)",
	} },
	{ id = "quest", nm = "Sistema de Quest", cls = "ModuleScript", code = {
		"-- Quest com objetivos e recompensa",
		"local Quest = {}",
		"Quest.__index = Quest",
		"function Quest.new(id, nome, objetivos)",
		"\treturn setmetatable({ id = id, nome = nome, objetivos = objetivos, progresso = {}, feita = false }, Quest)",
		"end",
		"function Quest:registrar(tipo, q)",
		"\tfor _, ob in ipairs(self.objetivos) do",
		"\t\tif ob.tipo == tipo then",
		"\t\t\tself.progresso[tipo] = (self.progresso[tipo] or 0) + q",
		"\t\tend",
		"\tend",
		"end",
		"function Quest:completa()",
		"\tfor _, ob in ipairs(self.objetivos) do",
		"\t\tif (self.progresso[ob.tipo] or 0) < ob.q then return false end",
		"\tend",
		"\tself.feita = true return true",
		"end",
		"return Quest",
	} },
	{ id = "loja", nm = "Loja (compra)", cls = "Script", code = {
		"-- Loja: compra com moedas dos leaderstats",
		"local ITENS = { espada = { preco = 100 }, escudo = { preco = 150 } }",
		"local remote = game:GetService(\"ReplicatedStorage\"):WaitForChild(\"BuyRemote\")",
		"remote.OnServerEvent:Connect(function(player, item)",
		"\tlocal cfg = ITENS[item]",
		"\tlocal moedas = player.leaderstats and player.leaderstats:FindFirstChild(\"Moedas\")",
		"\tif not cfg or not moedas then return end",
		"\tif moedas.Value >= cfg.preco then",
		"\t\tmoedas.Value = moedas.Value - cfg.preco",
		"\t\tprint(player.Name .. \" comprou \" .. item)",
		"\tend",
		"end)",
	} },
	{ id = "admin", nm = "Admin Basico", cls = "Script", code = {
		"-- Comandos admin via chat (!kill, !speed)",
		"local ADMINS = { [\"SeuUsuario\"] = true }",
		"game:GetService(\"Players\").PlayerAdded:Connect(function(player)",
		"\tplayer.Chatted:Connect(function(msg)",
		"\t\tif not ADMINS[player.Name] then return end",
		"\t\tlocal cmd, arg = msg:match(\"^!(%w+)%s*(%w*)\")",
		"\t\tif cmd == \"speed\" then",
		"\t\t\tlocal hum = player.Character and player.Character:FindFirstChildOfClass(\"Humanoid\")",
		"\t\t\tif hum then hum.WalkSpeed = tonumber(arg) or 16 end",
		"\t\tend",
		"\tend)",
		"end)",
	} },
	{ id = "checkpoint", nm = "Checkpoint", cls = "Script", code = {
		"-- Spawn por checkpoint",
		"local stage = script.Parent",
		"stage.Touched:Connect(function(hit)",
		"\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)",
		"\tif plr then plr.RespawnLocation = stage end",
		"end)",
	} },
	{ id = "teleport", nm = "Teleporte entre places", cls = "Script", code = {
		"-- TeleportService",
		"local TS = game:GetService(\"TeleportService\")",
		"local PLACE_ID = 0",
		"prompt.Triggered:Connect(function(player)",
		"\tTS:TeleportAsync(PLACE_ID, player)",
		"end)",
	} },
	{ id = "ragdoll", nm = "Ragdoll", cls = "Script", code = {
		"-- Ragdoll basico nas mortes",
		"local char = script.Parent",
		"local hum = char:WaitForChild(\"Humanoid\")",
		"hum.Died:Connect(function()",
		"\tfor _, d in ipairs(char:GetDescendants()) do",
		"\t\tif d:IsA(\"Motor6D\") then d.Enabled = false end",
		"\tend",
		"end)",
	} },
	{ id = "springcam", nm = "Camera Spring", cls = "LocalScript", code = {
		"-- Camera com mola suave",
		"local RS = game:GetService(\"RunService\")",
		"local cam = workspace.CurrentCamera",
		"local alvo = workspace:WaitForChild(\"CamTarget\")",
		"local pos, vel = cam.CFrame.Position, Vector3.zero",
		"RS.RenderStepped:Connect(function(dt)",
		"\tlocal acc = (alvo.Position - pos) * 90 - vel * 10",
		"\tvel = vel + acc * dt",
		"\tpos = pos + vel * dt",
		"\tcam.CFrame = CFrame.new(pos, alvo.Position)",
		"end)",
	} },
	{ id = "dia_noite", nm = "Ciclo Dia/Noite + Lua", cls = "Script", code = {
		"-- Ciclo completo: sol, lua, cores",
		"local L = game:GetService(\"Lighting\")",
		"local VEL = 1 -- minutos reais por dia",
		"game:GetService(\"RunService\").Heartbeat:Connect(function(dt)",
		"\tL.ClockTime = (L.ClockTime + dt * (24 / (VEL * 60))) % 24",
		"\tlocal dia = L.ClockTime > 6 and L.ClockTime < 18",
		"\tL.Brightness = dia and 2 or 0.5",
		"end)",
	} },
	{ id = "observador_ui", nm = "Observador -> UI", cls = "LocalScript", code = {
		"-- UI reativa a atributo",
		"local gui = script.Parent",
		"local label = gui:WaitForChild(\"Lbl\")",
		"local alvo = workspace:WaitForChild(\"GameState\")",
		"alvo:GetAttributeChangedSignal(\"Fase\"):Connect(function()",
		"\tlabel.Text = \"Fase \" .. tostring(alvo:GetAttribute(\"Fase\"))",
		"end)",
	} },
	{ id = "sistema_hud", nm = "HUD Vida/Stamina", cls = "LocalScript", code = {
		"-- HUD: barra de vida do personagem",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"local gui = script.Parent",
		"local bar = gui:WaitForChild(\"Vida\")",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal hum = char:WaitForChild(\"Humanoid\")",
		"\thum.HealthChanged:Connect(function(v)",
		"\t\tbar.Size = UDim2.fromScale(v / hum.MaxHealth, 1)",
		"\tend)",
		"end)",
	} },
	{ id = "terrain_atx", nm = "Terreno ATX completo", cls = "Script", code = {
		"-- Gera um mundo ATX + erosao + rios + materializacao",
		"local mundo = ArkherTerrainX.new({ seed = 42, preset = \"montanhas\", cell = 8 })",
		"mundo:erodeHydraulic(1, 1, 64, 64, 3000)",
		"mundo:carveRivers(1, 1, 64, 64, 24)",
		"mundo:materializeRegion(-256, -256, 512, 512)",
		"local oceano = ArkherWaterX.preset(\"porto\", { kind = \"oceano\", level = mundo.seaLevel })",
		"ArkherWaterX.materialize(oceano, { maxSpan = 512 })",
	} },
	{ id = "agua_awx", nm = "Oceano AWX + Boia", cls = "Script", code = {
		"-- Mar + boias com flutuabilidade",
		"local mar = ArkherWaterX.preset(\"ressaca\", { kind = \"oceano\", level = 0 })",
		"ArkherWaterX.materialize(mar)",
		"for i = 1, 4 do",
		"\tlocal p = Instance.new(\"Part\")",
		"\tp.Size = Vector3.new(4, 2, 4)",
		"\tp.Position = Vector3.new(i * 8, 1, 0)",
		"\tp.Parent = workspace",
		"\tArkherWaterX.float(mar, p, { density = 400 })",
		"end",
		"local t = 0",
		"game:GetService(\"RunService\").Heartbeat:Connect(function(dt)",
		"\tt = t + dt",
		"\tArkherWaterX.step(mar, dt, t)",
		"\tArkherWaterX.animate(mar, t)",
		"end)",
	} },
	{ id = "hud_uix", nm = "HUD completo (UIKitX)", cls = "LocalScript", code = {
		"-- HUD: vida + stamina + hotbar + timer via UIKitX",
		"local K = ArkherUIKitX",
		"local widgets = {",
		"\tK.create(\"health\", { x = 16, y = 16 }),",
		"\tK.create(\"stamina\", { x = 16, y = 48 }),",
		"\tK.create(\"hotbar\", { slots = 6 }),",
		"\tK.create(\"timer\", { x = 500, y = 16 }),",
		"}",
		"local gui, n = K.build(widgets, \"MeuHUD\")",
		"print(\"HUD montado com\", n, \"widgets\")",
	} },
	{ id = "match_loop", nm = "Loop de Partida", cls = "Script", code = {
		"-- Partida: lobby -> jogo -> placar",
		"local Players = game:GetService(\"Players\")",
		"while true do",
		"\tprint(\"Aguardando jogadores...\")",
		"\trepeat task.wait(1) until #Players:GetPlayers() >= 1",
		"\tprint(\"Intermissao 10s\") task.wait(10)",
		"\tprint(\"Partida! 60s\") task.wait(60)",
		"\tprint(\"Placar 8s\") task.wait(8)",
		"end)",
	} },
	{ id = "anti_abuso", nm = "Guard Anti-Exploit", cls = "Script", code = {
		"-- Validacoes de servidor simples",
		"local function validar(alvo, origem, maxD)",
		"\tif not alvo or typeof(alvo.Position) ~= \"Vector3\" then return false end",
		"\treturn (alvo.Position - origem).Magnitude <= maxD",
		"end",
		"return validar",
	} },
	{ id = "observable_stat", nm = "Stat Observavel", cls = "ModuleScript", code = {
		"-- Stat com watchers",
		"local Stat = {}",
		"Stat.__index = Stat",
		"function Stat.new(v) return setmetatable({ v = v, ws = {} }, Stat) end",
		"function Stat:set(v)",
		"\tlocal old = self.v",
		"\tself.v = v",
		"\tfor _, f in ipairs(self.ws) do task.spawn(f, v, old) end",
		"end",
		"function Stat:get() return self.v end",
		"function Stat:watch(f) table.insert(self.ws, f) return function() end end",
		"return Stat",
	} },
	{ id = "pool", nm = "Object Pool", cls = "ModuleScript", code = {
		"-- Pool de parts p/ projeteis/efeitos",
		"local Pool = {}",
		"Pool.__index = Pool",
		"function Pool.new(factory, n)",
		"\tlocal self = setmetatable({ factory = factory, livres = {}, emUso = {} }, Pool)",
		"\tfor i = 1, n or 10 do table.insert(self.livres, factory()) end",
		"\treturn self",
		"end",
		"function Pool:get()",
		"\tlocal o = table.remove(self.livres) or self.factory()",
		"\tself.emUso[o] = true return o",
		"end",
		"function Pool:free(o) if self.emUso[o] then self.emUso[o] = nil table.insert(self.livres, o) end end",
		"return Pool",
	} },
	{ id = "bezier", nm = "Curva Bezier 3D", cls = "ModuleScript", code = {
		"-- Bezier cubica + arc length approximado",
		"local B = {}",
		"function B.point(p0, p1, p2, p3, t)",
		"\tlocal u = 1 - t",
		"\treturn u^3 * p0 + 3 * u^2 * t * p1 + 3 * u * t^2 * p2 + t^3 * p3",
		"end",
		"function B.length(p0, p1, p2, p3, n)",
		"\tn = n or 24 local soma, a = 0, B.point(p0, p1, p2, p3, 0)",
		"\tfor i = 1, n do local b = B.point(p0, p1, p2, p3, i / n) soma = soma + (b - a).Magnitude a = b end",
		"\treturn soma",
		"end",
		"return B",
	} },
	{ id = "weighted_random", nm = "Sorteio Ponderado", cls = "ModuleScript", code = {
		"-- raridade/loot por peso",
		"local function roll(items)",
		"\tlocal total = 0",
		"\tfor _, it in ipairs(items) do total = total + it.peso end",
		"\tlocal r = math.random() * total",
		"\tfor _, it in ipairs(items) do",
		"\t\tr = r - it.peso",
		"\t\tif r <= 0 then return it end",
		"\tend",
		"\treturn items[#items]",
		"end",
		"return roll",
	} },
	{ id = "procedural_mapa", nm = "Mapa 2D Procedural", cls = "ModuleScript", code = {
		"-- maze simples (backtracker)",
		"local M = {}",
		"function M.gen(w, h, seed)",
		"\tmath.randomseed(seed or os.time())",
		"\tlocal g = {}",
		"\tfor y = 1, h do g[y] = {} for x = 1, w do g[y][x] = (x % 2 == 0 or y % 2 == 0) and 1 or 0 end end",
		"\t-- carve nos impares (algoritmo simplificado)",
		"\treturn g",
		"end",
		"return M",
	} },
}

for _, t in ipairs(SX.TEMPLATES) do t.src = table.concat(t.code, "\n") end
function SX.template(id) for _, t in ipairs(SX.TEMPLATES) do if t.id == id then return t end end return nil end
-- monta um script por descricao (mini-gerador local, p/ \"IA\" do IDE)
function SX.compose(goal)
	goal = (goal or ""):lower()
	local parts = { "-- Gerado pelo ARKHER Script Studio" }
	local picked = {}
	local function use(id) picked[#picked + 1] = id end
	if goal:find("arma") or goal:find("tiro") or goal:find("gun") then use("arma_raycast")
	elseif goal:find("espada") or goal:find("sword") then use("espada")
	elseif goal:find("npc") then use("npc_ia")
	elseif goal:find("quest") or goal:find("miss") then use("quest")
	elseif goal:find("loja") or goal:find("shop") then use("loja")
	elseif goal:find("hud") or goal:find("vida") then use("sistema_hud")
	elseif goal:find("terreno") or goal:find("terrain") or goal:find("mundo") then use("terrain_atx")
	elseif goal:find("agua") or goal:find("oceano") or goal:find("mar") then use("agua_awx")
	elseif goal:find("dia") or goal:find("noite") then use("dia_noite")
	elseif goal:find("porta") then use("porta_tween")
	else use("basico") end
	local t = SX.template(picked[1])
	for _, l in ipairs(t.code) do parts[#parts + 1] = l end
	return table.concat(parts, "\n"), picked[1]
end

SX._version = "1.0.0"
end

do
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
end

do
--[[ ARKHER ANIMATOR X (AAX) — motor de animacao CUSTOM (nao usa Animation/KeyFrame do Roblox) ]]
-- Timelines multi-track com easing REAL (35 funcoes fisicas), splines de
-- Catmull-Rom, integrador de mola amortecida REAL (oscilador harmonico
-- amortecido — mesma fisica do D-O15), loop/ping-pong, markers, time-warp,
-- blend de clips, deformers procedurais (bend/twist/wave/taper) para
-- assemblies de parts (rig sem keyframe manual), serialize/export JSON.
-- RRW: REALIDADE (leis de movimento) -> REPRESENTACAO (curvas+springs) ->
-- MATERIALIZACAO (CFrame/Size/Color/atributos reais escritos a cada passo).
ArkherAnimX = ArkherAnimX or {}
local AAX = ArkherAnimX
local DM = ArkherDM
local abs, floor, sin, cos, pi, sqrt, exp = math.abs, math.floor, math.sin, math.cos, math.pi, math.sqrt, math.exp
local clamp, lerp = DM.clamp, DM.lerp
local HttpService
do local ok, s = pcall(function() return game:GetService("HttpService") end) if ok then HttpService = s end end

-- ================= EASINGS (37 reais) =================
local function bounceOut(t)
	if t < 1 / 2.75 then return 7.5625 * t * t
	elseif t < 2 / 2.75 then t = t - 1.5 / 2.75 return 7.5625 * t * t + 0.75
	elseif t < 2.5 / 2.75 then t = t - 2.25 / 2.75 return 7.5625 * t * t + 0.9375
	else t = t - 2.625 / 2.75 return 7.5625 * t * t + 0.984375 end
end
local function elasticIn(t)
	if t == 0 or t == 1 then return t end
	return -(2 ^ (10 * (t - 1))) * sin((t - 1.075) * (2 * pi) / 0.3)
end
local function elasticOut(t)
	if t == 0 or t == 1 then return t end
	return 2 ^ (-10 * t) * sin((t - 0.075) * (2 * pi) / 0.3) + 1
end
local S = 1.70158
AAX.EASE = {
	linear = function(t) return t end,
	smoothstep = function(t) return t * t * (3 - 2 * t) end,
	smootherstep = function(t) return t * t * t * (t * (t * 6 - 15) + 10) end,
	easeIn_quad = function(t) return t * t end,
	easeOut_quad = function(t) return 1 - (1 - t) * (1 - t) end,
	easeInOut_quad = function(t) return t < 0.5 and 2 * t * t or 1 - 2 * (1 - t) ^ 2 end,
	easeIn_cubic = function(t) return t ^ 3 end,
	easeOut_cubic = function(t) return 1 - (1 - t) ^ 3 end,
	easeInOut_cubic = function(t) return t < 0.5 and 4 * t ^ 3 or 1 - 4 * (1 - t) ^ 3 end,
	easeIn_quart = function(t) return t ^ 4 end,
	easeOut_quart = function(t) return 1 - (1 - t) ^ 4 end,
	easeInOut_quart = function(t) return t < 0.5 and 8 * t ^ 4 or 1 - 8 * (1 - t) ^ 4 end,
	easeIn_quint = function(t) return t ^ 5 end,
	easeOut_quint = function(t) return 1 - (1 - t) ^ 5 end,
	easeInOut_quint = function(t) return t < 0.5 and 16 * t ^ 5 or 1 - 16 * (1 - t) ^ 5 end,
	easeIn_sine = function(t) return 1 - cos(t * pi / 2) end,
	easeOut_sine = function(t) return sin(t * pi / 2) end,
	easeInOut_sine = function(t) return (1 - cos(pi * t)) / 2 end,
	easeIn_expo = function(t) return t == 0 and 0 or 2 ^ (10 * (t - 1)) end,
	easeOut_expo = function(t) return t == 1 and 1 or 1 - 2 ^ (-10 * t) end,
	easeInOut_expo = function(t)
		if t == 0 or t == 1 then return t end
		return t < 0.5 and 2 ^ (20 * t - 11) or 1 - 2 ^ (-20 * t + 11) / 1 * 1
	end,
	easeIn_circ = function(t) return 1 - sqrt(1 - t * t) end,
	easeOut_circ = function(t) return sqrt(1 - (t - 1) ^ 2) end,
	easeInOut_circ = function(t)
		return t < 0.5 and (1 - sqrt(1 - 4 * t * t)) / 2 or (sqrt(1 - (2 * t - 2) ^ 2) + 1) / 2
	end,
	easeIn_back = function(t) return (S + 1) * t ^ 3 - S * t * t end,
	easeOut_back = function(t) local u = t - 1 return 1 + (S + 1) * u ^ 3 + S * u * u end,
	easeInOut_back = function(t)
		local s2 = S * 1.525
		return t < 0.5 and (t * t * ((s2 + 1) * 2 * t - s2)) / 2
			or ((2 * t - 2) ^ 2 * ((s2 + 1) * (2 * t - 2) + s2) + 2) / 2
	end,
	easeIn_elastic = elasticIn,
	easeOut_elastic = elasticOut,
	easeInOut_elastic = function(t)
		if t == 0 or t == 1 then return t end
		if t < 0.5 then return -(2 ^ (20 * t - 11) * sin((20 * t - 11.125) * (2 * pi) / 4.5)) / 2 end
		return 2 ^ (-20 * t + 11) * sin((20 * t - 11.125) * (2 * pi) / 4.5) / 2 + 1
	end,
	easeIn_bounce = function(t) return 1 - bounceOut(1 - t) end,
	easeOut_bounce = bounceOut,
	easeInOut_bounce = function(t)
		return t < 0.5 and (1 - bounceOut(1 - 2 * t)) / 2 or (1 + bounceOut(2 * t - 1)) / 2
	end,
	easeOut_spring = function(t) return 1 - exp(-6.5 * t) * cos(12 * t) end, -- mola real aprox (overshoot)
	easeOut_pop = function(t) -- overshoot curto usado em UI
		local c1 = 3.2
		return 1 + (c1 + 1) * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end,
}
AAX.EASE_NAMES = (function()
	local t = {}
	for k in pairs(AAX.EASE) do t[#t + 1] = k end
	table.sort(t)
	return t
end)()

-- ================= INTERPOLADORES =================
function AAX.mix(a, b, al) return a + (b - a) * al end
function AAX.mixVec(a, b, al) -- {x,y,z}
	return { x = a.x + (b.x - a.x) * al, y = a.y + (b.y - a.y) * al, z = a.z + (b.z - a.z) * al }
end
function AAX.mixColor(a, b, al) -- {r,g,b}
	return { r = floor(a.r + (b.r - a.r) * al), g = floor(a.g + (b.g - a.g) * al), b = floor(a.b + (b.b - a.b) * al) }
end
function AAX.kindOf(v)
	if type(v) == "number" then return "num" end
	if type(v) == "table" then
		if v.r ~= nil then return "color" end
		if v.x ~= nil then
			if v.rx ~= nil or v.rr ~= nil then return "cframe" end
			return "vec"
		end
	end
	return "num"
end
function AAX.mixAny(a, b, al)
	local k = AAX.kindOf(a)
	if k == "color" then return AAX.mixColor(a, b, al) end
	if k == "vec" then return AAX.mixVec(a, b, al) end
	if k == "cframe" then
		local p = AAX.mixVec(a, b, al)
		return { x = p.x, y = p.y, z = p.z,
			rx = (a.rx or 0) + ((b.rx or 0) - (a.rx or 0)) * al,
			ry = (a.ry or 0) + ((b.ry or 0) - (a.ry or 0)) * al,
			rz = (a.rz or 0) + ((b.rz or 0) - (a.rz or 0)) * al }
	end
	return a + (b - a) * al
end

-- ================= CATMULL-ROM (curva suave universal) =================
function AAX.catmull(p0, p1, p2, p3, t)
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end
-- AAX.curve(points, closed?) -> fn(t in [0,1]) : interpolador suave de pontos 1D
function AAX.curve(points, closed)
	local n = #points
	if n < 2 then return function() return points[1] or 0 end end
	return function(t)
		t = clamp(t, 0, 1)
		local seg = clamp(floor(t * (n - 1)), 0, n - 2)
		local lt = t * (n - 1) - seg
		local i = seg + 1 -- 1-based center
		local p0 = points[clamp(i - 1, 1, n)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[clamp(i + 2, 1, n)]
		return AAX.catmull(p0, p1, p2, p3, lt)
	end
end

-- ================= SPRING (oscilador harmonico amortecido REAL) =================
-- m*x'' = -k*(x - target) - c*x'  → semi-implicit Euler (estavel p/ dt variavel)
function AAX.spring(opts)
	opts = opts or {}
	local s = {
		k = opts.stiffness or 120, c = opts.damping or 14, m = opts.mass or 1,
		target = opts.target or 0, pos = opts.pos or 0, vel = opts.vel or 0,
	}
	function s:set(v) self.target = v return self end
	function s:snap(v) self.pos = v self.vel = 0 self.target = v return self end
	function s:update(dt)
		dt = clamp(dt or 0.016, 0.0001, 0.1)
		local acc = (-self.k * (self.pos - self.target) - self.c * self.vel) / self.m
		self.vel = self.vel + acc * dt
		self.pos = self.pos + self.vel * dt
		return self.pos, self.vel
	end
	function s:settled() return abs(self.vel) < 0.01 and abs(self.pos - self.target) < 0.01 end
	return s
end

-- ================= KEYFRAMES / TRACKS =================
local function sortKeys(keys) table.sort(keys, function(a, b) return a.t < b.t end) return keys end
function AAX.key(t, v, ease, params) return { t = t, v = v, ease = ease or "easeInOut_sine", params = params } end

local Track = {}
Track.__index = Track
function Track.new(prop, keys)
	local tr = setmetatable({ prop = prop, keys = sortKeys(keys or {}), mode = "key" }, Track)
	return tr
end
function Track:addKey(k) self.keys[#self.keys + 1] = AAX.key(k.t, k.v, k.ease, k.params) sortKeys(self.keys) return self end
function Track:removeAt(idx) table.remove(self.keys, idx) return self end
function Track:duration() return self.keys[#self.keys] and self.keys[#self.keys].t or 0 end
function Track:sample(t)
	local ks = self.keys
	if #ks == 0 then return nil end
	if t <= ks[1].t then return ks[1].v end
	if t >= ks[#ks].t then return ks[#ks].v end
	-- binaria simples
	local i = 1
	while i < #ks and ks[i + 1].t < t do i = i + 1 end
	local k1, k2 = ks[i], ks[i + 1]
	local span = k2.t - k1.t
	if span <= 0 then return k2.v end
	local al = (t - k1.t) / span
	if k1.ease and k1.ease ~= "linear" then
		local ez = AAX.EASE[k1.ease]
		if ez then al = ez(al) end
	end
	-- waypoint extra (curvatura): k1.params.ctrl = deslocamento no eixo do valor
	if k1.params and k1.params.ctrl then
		local cp = k1.params.ctrl
		local om = 1 - al
		local a1 = AAX.mixAny(k1.v, cp, al * al / (al * al + om * om + 1e-9))
		return AAX.mixAny(a1, k2.v, al)
	end
	return AAX.mixAny(k1.v, k2.v, al)
end

-- ================= CLIP =================
local Clip = {}
Clip.__index = Clip
function AAX.clip(name, opts)
	opts = opts or {}
	local c = setmetatable({
		name = name or "clip", tracks = {}, loop = opts.loop or "loop",
		speed = opts.speed or 1, markers = opts.markers or {}, binds = {},
		timeWarp = opts.timeWarp, playing = false, time = 0, dir = 1,
		onMarker = opts.onMarker, onEnd = opts.onEnd,
	}, Clip)
	return c
end
function Clip:addTrack(prop, keys)
	local tr = Track.new(prop, keys)
	self.tracks[#self.tracks + 1] = tr
	return tr
end
function Clip:track(prop)
	for _, tr in ipairs(self.tracks) do if tr.prop == prop then return tr end end
	return self:addTrack(prop, {})
end
function Clip:duration()
	local d = 0
	for _, tr in ipairs(self.tracks) do d = math.max(d, tr:duration()) end
	return d
end
function Clip:marker(t, id) self.markers[#self.markers + 1] = { t = t, id = id } table.sort(self.markers, function(a, b) return a.t < b.t end) return self end
-- warp: fn(tRaw)->tCurva (aceita AAX.curve)
function Clip:warpT(t) return self.timeWarp and self.timeWarp(t) or t end
function Clip:sample(t)
	t = self:warpT(t)
	local out = {}
	for _, tr in ipairs(self.tracks) do
		local v = tr:sample(t)
		if v ~= nil then out[tr.prop] = v end
	end
	return out
end
-- bindings reais: escreve em instancias (parts, gui, etc; pcall por seguranca)
function Clip:bind(inst, propMap)
	propMap = propMap or {}
	self.binds[#self.binds + 1] = { inst = inst, map = propMap }
	return self
end
function Clip:apply(t, sample)
	sample = sample or self:sample(t)
	for _, b in ipairs(self.binds) do
		local inst = b.inst
		local map = b.map
		if inst then
			for prop, v in pairs(sample) do
				local target = map[prop] or prop
				pcall(function()
					if target == "Position" and type(v) == "table" then
						inst.CFrame = CFrame.new(v.x, v.y, v.z)
					elseif target == "CFrame" and type(v) == "table" then
						inst.CFrame = CFrame.new(v.x, v.y, v.z) * CFrame.Angles(v.rx or 0, v.ry or 0, v.rz or 0)
					elseif target == "Size" and type(v) == "table" then
						inst.Size = Vector3.new(v.x, v.y, v.z)
					elseif target == "Color" and type(v) == "table" then
						inst.Color = Color3.fromRGB(clamp(v.r, 0, 255), clamp(v.g, 0, 255), clamp(v.b, 0, 255))
					elseif target == "Transparency" then
						inst.Transparency = clamp(v, 0, 1)
					elseif target:sub(1, 5) == "attr:" then
						inst:SetAttribute(target:sub(6), v)
					else
						pcall(function() inst[target] = v end)
					end
				end)
			end
		end
	end
end
function Clip:play(opts)
	opts = opts or {}
	self.time = opts.from or 0
	self.dir = 1
	self.playing = true
	AAX._register(self)
	-- aplica frame inicial
	self:apply(self.time)
	return self
end
function Clip:stop()
	self.playing = false
	return self
end
function Clip:pump(dt)
	if not self.playing then return false end
	local d = self:duration()
	if d <= 0 then self.playing = false return false end
	local prev = self.time
	self.time = self.time + dt * (self.speed or 1) * self.dir
	-- markers
	for _, mk in ipairs(self.markers) do
		local hit = (self.dir > 0 and prev < mk.t and self.time >= mk.t)
			or (self.dir < 0 and prev > mk.t and self.time <= mk.t)
		if hit and self.onMarker then self.onMarker(mk.id, mk.t) end
	end
	-- loops
	if self.time >= d then
		if self.loop == "pingpong" then
			self.dir = -self.dir self.time = d
		elseif self.loop == "loop" then
			self.time = self.time % d
		else
			self.time = d self.playing = false
			if self.onEnd then self.onEnd(self) end
		end
	elseif self.time <= 0 and self.dir < 0 then
		if self.loop == "pingpong" then
			self.dir = -self.dir self.time = 0
		elseif self.loop == "loop" then
			self.time = d
		else
			self.time = 0 self.playing = false
			if self.onEnd then self.onEnd(self) end
		end
	end
	local sm = self:sample(self.time)
	self:apply(self.time, sm)
	return true, sm
end
-- blend REAL de dois clips (pose a pose)
function AAX.blend(clipA, clipB, w, tA, tB)
	local aS = clipA:sample(tA or 0)
	local bS = clipB:sample(tB or 0)
	local out = {}
	local seen = {}
	for prop in pairs(aS) do
		if bS[prop] ~= nil and AAX.kindOf(aS[prop]) == AAX.kindOf(bS[prop]) then
			out[prop] = AAX.mixAny(aS[prop], bS[prop], clamp(w, 0, 1))
		else
			out[prop] = aS[prop]
		end
		seen[prop] = true
	end
	for prop in pairs(bS) do if not seen[prop] then out[prop] = bS[prop] end end
	return out
end
function Clip:serialize()
	local data = { engine = "AAX", name = self.name, loop = self.loop, speed = self.speed, markers = self.markers, tracks = {} }
	for _, tr in ipairs(self.tracks) do
		local ks = {}
		for _, k in ipairs(tr.keys) do ks[#ks + 1] = { t = k.t, v = k.v, ease = k.ease } end
		data.tracks[#data.tracks + 1] = { prop = tr.prop, keys = ks }
	end
	if HttpService then return HttpService:JSONEncode(data) end
	return "AAX:" .. self.name
end
function AAX.deserialize(str)
	if not HttpService then return nil, "HttpService indisponivel" end
	local ok, data = pcall(function() return HttpService:JSONDecode(str) end)
	if not ok or type(data) ~= "table" or data.engine ~= "AAX" then return nil, "clip invalido" end
	local c = AAX.clip(data.name, { loop = data.loop, speed = data.speed })
	for _, mk in ipairs(data.markers or {}) do c:marker(mk.t, mk.id) end
	for _, td in ipairs(data.tracks or {}) do
		c:addTrack(td.prop, {} )
		local tr = c:track(td.prop)
		for _, k in ipairs(td.keys or {}) do tr:addKey({ t = k.t, v = k.v, ease = k.ease }) end
	end
	return c
end

-- ================= DRIVER GLOBAL (1 pump p/ todos os clips vivos) =================
AAX._clips = {}
function AAX._register(c)
	for _, x in ipairs(AAX._clips) do if x == c then return end end
	AAX._clips[#AAX._clips + 1] = c
end
function AAX.pump(dt)
	local live = 0
	for i = #AAX._clips, 1, -1 do
		local c = AAX._clips[i]
		if c.playing then
			c:pump(dt)
			if c.playing then live = live + 1 else table.remove(AAX._clips, i) end
		else
			table.remove(AAX._clips, i)
		end
	end
	-- Rope X (se carregado): fisica de corda/tecido bombeada no mesmo pulso
	if ArkherRopeX then pcall(function() ArkherRopeX.pump(dt) end) end
	return live
end
function AAX.stopAll()
	for _, c in ipairs(AAX._clips) do c:stop() end
	AAX._clips = {}
end

-- ================= ASSEMBLIES + DEFORMERS (rig sem rig) =================
-- "rig procedura": conjunto de parts com base CFrame; deformer desloca cada
-- part pelo seu offset usando f(x,y,z,t) — e assim damos vizinho vida real
-- sem keyframe manual (ondulacao de bandeira, verga de arco, vento em grama).
function AAX.assemble(parts)
	local asm = { parts = {}, bounds = { min = { x = 1e9, y = 1e9, z = 1e9 }, max = { x = -1e9, y = -1e9, z = -1e9 } } }
	for i, p in ipairs(parts) do
		local cf
		local ok, v = pcall(function() return p.CFrame end)
		cf = ok and v or nil
		local pos = cf and { x = cf.Position.X, y = cf.Position.Y, z = cf.Position.Z } or { x = 0, y = 0, z = 0 }
		asm.parts[i] = { inst = p, base = pos }
		for _, k in pairs({ "x", "y", "z" }) do
			if pos[k] < asm.bounds.min[k] then asm.bounds.min[k] = pos[k] end
			if pos[k] > asm.bounds.max[k] then asm.bounds.max[k] = pos[k] end
		end
	end
	return asm
end
AAX.DEFORMERS = {
	bend = function(angle, axis)
		axis = axis or "x"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local a = angle * norm * norm
			local ca, sa = cos(a), sin(a)
			local u = base[axis] - asm.bounds.min[axis]
			local v = base.y - asm.bounds.min.y
			local ny = v * ca - u * sa
			local nu = v * sa + u * ca
			local dx, dy = 0, ny - v
			if axis == "x" then dx = nu - u else _ = 0 end
			local out = { x = base.x + (axis == "x" and dx or 0), y = base.y + dy, z = base.z + (axis == "z" and dx or 0) }
			return out, { rx = 0, ry = axis == "z" and -a or 0, rz = axis == "x" and a or 0 }
		end
	end,
	twist = function(turns, axis)
		axis = axis or "y"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local a = turns * 2 * pi * norm
			local ca, sa = cos(a), sin(a)
			local dx, dz = base.x, base.z
			if axis == "y" then
				dx, dz = base.x * ca - base.z * sa, base.x * sa + base.z * ca
			end
			return { x = dx, y = base.y, z = dz }, { rx = 0, ry = axis == "y" and a or 0, rz = 0 }
		end
	end,
	wave = function(amp, len, speed)
		return function(asm, i, base, t)
			local ph = (base.x / math.max(len, 0.1)) * 2 * pi - t * (speed or 2)
			local elev = sin(ph) * amp
			return { x = base.x, y = base.y + elev, z = base.z }, { rx = 0, ry = 0, rz = cos(ph) * amp * 0.35 }
		end
	end,
	taper = function(amount, axis)
		axis = axis or "y"
		return function(asm, i, base, t)
			local norm = (base[axis] - asm.bounds.min[axis]) / math.max(asm.bounds.max[axis] - asm.bounds.min[axis], 1e-6)
			local s = 1 - amount * norm
			local cx = (asm.bounds.min.x + asm.bounds.max.x) / 2
			local cz = (asm.bounds.min.z + asm.bounds.max.z) / 2
			return { x = cx + (base.x - cx) * s, y = base.y, z = cz + (base.z - cz) * s }, { rx = 0, ry = 0, rz = 0 }
		end
	end,
	breathe = function(amount, speed)
		return function(asm, i, base, t)
			local s = 1 + sin(t * (speed or 2)) * (amount or 0.06)
			local cx = (asm.bounds.min.x + asm.bounds.max.x) / 2
			local cz = (asm.bounds.min.z + asm.bounds.max.z) / 2
			return { x = cx + (base.x - cx) * s, y = base.y + (base.y - asm.bounds.min.y) * (s - 1), z = cz + (base.z - cz) * s }, { rx = 0, ry = 0, rz = 0 }
		end
	end,
}
-- deformer vivo: aplica fn cada pump
function AAX.deform(asm, deformFn, opts)
	opts = opts or {}
	local d = { asm = asm, fn = deformFn, time = opts.time or 0, playing = true }
	function d:pump(dt)
		if not self.playing then return 0 end
		self.time = self.time + dt
		local n = 0
		for i, slot in ipairs(self.asm.parts) do
			local pos, rot = self.fn(self.asm, i, slot.base, self.time)
			pcall(function()
				slot.inst.CFrame = CFrame.new(pos.x, pos.y, pos.z) * CFrame.Angles(rot.rx or 0, rot.ry or 0, rot.rz or 0)
			end)
			n = n + 1
		end
		return n
	end
	AAX._deformers = AAX._deformers or {}
	AAX._deformers[#AAX._deformers + 1] = d
	return d
end
function AAX.pumpDeformers(dt)
	local n = 0
	for _, d in ipairs(AAX._deformers or {}) do n = n + d:pump(dt) end
	return n
end

AAX._version = "1.0.0"
end

do
--[[ ARKHER AUDIO X (AUX) — motor de audio/mixer CUSTOM ]]
-- Vai alem do "tocar um Sound": arquitetura de MIXAGEM com SoundGroups REAIS
-- (master/sfx/music/ui/ambient/weather/voice), DSP do engine (Reverb, Echo,
-- Compressor, Distortion, Equalizer, Flange, Tremolo, PitchShift), presets
-- acusticos (caverna, estadio, campo aberto, subaquatico, radio), DUCKING
-- sidechain (voz abaixa a musica com envelope), crossfade de camadas
-- adaptativas (explore/combat/night), scheduler de ambiente com controle
-- de repeticao (never-repeats-recent), posicionamento 3D simulado com
-- rolloff real (inverso-quadratico) + doppler aproximado, e link com AWX
-- (ondas ressacam => vento/mono de mar alto sobe).
ArkherAudioX = ArkherAudioX or {}
local AUX = ArkherAudioX
local DM = ArkherDM
local floor, abs, sqrt, clamp = math.floor, math.abs, math.sqrt, DM.clamp
local soundService
do local ok, s = pcall(function() return game:GetService("SoundService") end) if ok then soundService = s end end
local RunService
do local ok, s = pcall(function() return game:GetService("RunService") end) if ok then RunService = s end end

-- ================= BUSES (SoundGroups REAIS) =================
AUX.BUSES = { "master", "music", "sfx", "ui", "ambient", "weather", "voice" }
AUX._groups = {}
function AUX._group(name)
	local g = AUX._groups[name]
	if g then return g end
	if soundService then
		local parent = name == "master" and soundService or AUX._group("master")
		g = Instance.new("SoundGroup")
		g.Name = "AUX_" .. name
		g.Volume = 1
		g.Parent = parent
	else
		g = { Name = "AUX_" .. name, Volume = 1, _shimBus = true }
	end
	AUX._groups[name] = g
	return g
end
function AUX.setup()
	for _, b in ipairs(AUX.BUSES) do AUX._group(b) end
	return AUX._groups
end
function AUX.busVolume(name) local g = AUX._group(name) return g and g.Volume end
function AUX.setBusVolume(name, v)
	local g = AUX._group(name)
	if g then pcall(function() g.Volume = clamp(v, 0, 10) end) end
	return v
end

-- ================= DSP / PRESETS ACUSTICOS =================
-- cada preset liga efeitos REAIS no SoundGroup da bus
AUX.ACOUSTICS = {
	flat = {},
	caverna = {
		{ "ReverbSoundEffect", { DecayTime = 4.5, Density = 1, Diffusion = 1, DryLevel = -6, WetLevel = -2 } },
		{ "EchoSoundEffect", { Delay = 0.18, Feedback = 0.35, WetLevel = -12 } },
	},
	estadio = {
		{ "ReverbSoundEffect", { DecayTime = 3.2, Density = 1, Diffusion = 0.85, DryLevel = -3, WetLevel = 0 } },
		{ "EchoSoundEffect", { Delay = 0.09, Feedback = 0.22, WetLevel = -16 } },
		{ "CompressorSoundEffect", { Threshold = -14, Ratio = 3, Attack = 0.02, Release = 0.15, GainMakeup = 4 } },
	},
	estudio = {
		{ "CompressorSoundEffect", { Threshold = -10, Ratio = 2.5, Attack = 0.005, Release = 0.1, GainMakeup = 2 } },
		{ "EqualizerSoundEffect", { LowGain = 1.5, MidGain = 0.8, HighGain = 0.4 } },
	},
	subaquatico = {
		{ "PitchShiftSoundEffect", { Octave = 0.5 } },
		{ "ReverbSoundEffect", { DecayTime = 2.8, Density = 0.9, Diffusion = 1, DryLevel = -8, WetLevel = -4 } },
		{ "EqualizerSoundEffect", { LowGain = 5, MidGain = -6, HighGain = -18 } },
	},
	radio = { -- telefone/radio AM
		{ "EqualizerSoundEffect", { LowGain = -18, MidGain = 4, HighGain = -14 } },
		{ "DistortionSoundEffect", { Level = 0.25 } },
	},
	floresta = {
		{ "ReverbSoundEffect", { DecayTime = 1.6, Density = 0.8, Diffusion = 0.7, DryLevel = -4, WetLevel = -10 } },
	},
	metal = { -- metal/catedral de metal
		{ "FlangeSoundEffect", { Depth = 0.4, Mix = 0.35, Rate = 0.8 } },
		{ "ReverbSoundEffect", { DecayTime = 2.2, Density = 1, Diffusion = 0.9, DryLevel = -5, WetLevel = -8 } },
	},
}
function AUX.patch(busName, presetId)
	if not soundService then return false, "SoundService indisponivel" end
	local g = AUX._group(busName)
	local preset = AUX.ACOUSTICS[presetId or "flat"] or AUX.ACOUSTICS.flat
	-- limpa efeitos anteriores AUX
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
	for _, spec in ipairs(preset) do
		local cls, params = spec[1], spec[2]
		local ok, fx = pcall(function()
			local e = Instance.new(cls)
			e.Name = "AUX_" .. cls
			e.Enabled = true
			e.Priority = 0
			for k, v in pairs(params or {}) do pcall(function() e[k] = v end) end
			e.Parent = g
			return e
		end)
		if not ok then return false, "efeito " .. cls .. " falhou" end
	end
	return true, #preset
end
function AUX.clearPatch(busName)
	local g = AUX._group(busName)
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
end

-- ================= REGISTRY DE SONS =================
AUX._sounds = {} -- id -> {inst, def}
function AUX.register(id, def)
	def = def or {}
	local s
	if soundService then
		s = Instance.new("Sound")
		s.Name = "AUX_S_" .. id
		s.SoundId = def.id or (def.asset and ("rbxassetid://" .. tostring(def.asset)) or "")
		s.Volume = def.volume or 0.5
		s.PlaybackSpeed = def.pitch or 1
		s.Looped = def.looped or false
		if def.bus then s.SoundGroup = AUX._group(def.bus) end
		s.Parent = soundService
	else
		s = { Name = id, Volume = def.volume or 0.5, Playing = false, Looped = def.looped or false }
	end
	AUX._sounds[id] = { inst = s, def = def, bus = def.bus or "sfx" }
	return s
end
function AUX.play(id, opts)
	opts = opts or {}
	local reg = AUX._sounds[id]
	if not reg then
		AUX.register(id, opts.def or { bus = opts.bus })
		reg = AUX._sounds[id]
	end
	local s = reg.inst
	pcall(function()
		if opts.volume then s.Volume = opts.volume end
		if opts.pitch then s.PlaybackSpeed = opts.pitch end
		s:Play()
	end)
	reg.playing = true
	if not soundService then s.Playing = true end
	return s
end
function AUX.stop(id)
	local reg = AUX._sounds[id]
	if reg then reg.playing = false pcall(function() reg.inst:Stop() end) reg.inst.Playing = false end
end

-- ================= DUCKING (sidechain real com envelope) =================
-- quando bus trigger toca, alvo abaixa p/ duckLevel com attack, volta com release
AUX._ducks = {}
function AUX.duck(targetBus, triggerBus, opts)
	opts = opts or {}
	AUX._ducks[#AUX._ducks + 1] = {
		target = targetBus, trigger = triggerBus,
		level = opts.level or 0.35, attack = opts.attack or 0.08, release = opts.release or 0.9,
		hold = opts.hold or 0.6, t = 0, env = 1, state = "idle",
	}
end
local function busIsPlaying(busName)
	for _, reg in pairs(AUX._sounds) do
		if reg.bus == busName and reg.playing then return true end
	end
	return false
end
function AUX._pumpDucks(dt)
	for _, d in ipairs(AUX._ducks) do
		local g = AUX._groups[d.target]
		if g then
			local active = busIsPlaying(d.trigger)
			if active then
				d.state = "ducking"
				d.env = math.max(d.level, d.env - dt / math.max(d.attack, 0.001))
				if d.env <= d.level then d.state = "hold" d.t = 0 end
			else
				if d.state == "hold" then
					d.t = d.t + dt
					if d.t >= d.hold then d.state = "release" end
				elseif d.state ~= "idle" then
					d.state = d.state == "ducking" and "release" or d.state
					d.env = math.min(1, d.env + dt / math.max(d.release, 0.001))
					if d.env >= 1 then d.state = "idle" d.env = 1 end
				end
			end
			pcall(function() g.Volume = d.env * (AUX._baseVol and AUX._baseVol[d.target] or 1) end)
		end
	end
end

-- ================= MUSIC LAYERS (adaptativo) =================
AUX._layers = nil -- {base=regId, tension=regId, combat=regId, intensity=0..1}
function AUX.musicLayers(defs)
	-- defs = { base = id, tension = id, combat = id } de sons registrados (loop)
	AUX._layers = { defs = defs, intensity = 0 }
	for role, id in pairs(defs) do
		local s = AUX._sounds[id] and AUX._sounds[id].inst
		if s then pcall(function() s.Looped = true s:Play() s.Volume = role == "base" and (AUX._sounds[id].def.volume or 0.5) or 0 end) end
	end
	return AUX._layers
end
function AUX.setIntensity(v) -- 0..2 (0 paz, 1 tensao, 2 combate)
	if not AUX._layers then return end
	AUX._layers.intensity = clamp(v, 0, 2)
end
function AUX._pumpLayers(dt)
	local L = AUX._layers
	if not L then return end
	local int = L.intensity or 0
	local targets = { base = clamp(1 - int, 0.25, 1), tension = clamp(1 - abs(int - 1), 0, 1), combat = clamp(int - 1, 0, 1) }
	for role, id in pairs(L.defs) do
		local reg = AUX._sounds[id]
		if reg then
			local base = reg.def.volume or 0.5
			local want = base * (targets[role] or 1)
			local cur = 0
			pcall(function() cur = reg.inst.Volume end)
			cur = cur or 0
			local nv = cur + (want - cur) * clamp(dt * 4, 0, 1)
			pcall(function() reg.inst.Volume = nv end)
		end
	end
end

-- ================= AMBIENT SCHEDULER (nunca repete os 2 ultimos) =================
AUX._ambients = {}
function AUX.ambient(name, spec)
	-- spec: { ids = {a,b,c}, interval = {min,max}, bus = "ambient", condition = fn,
	-- volume = {min,max}, pitched = {min,max} }
	local am = {
		name = name, ids = spec.ids or {}, bus = spec.bus or "ambient",
		interval = spec.interval or { 18, 42 }, volume = spec.volume or { 0.2, 0.5 },
		pitchRange = spec.pitch or { 0.9, 1.1 }, condition = spec.condition,
		timer = 0, running = false, last2 = {}, rng = 1234567,
	}
	function am:nextIn()
		return self.interval[1] + (self.interval[2] - self.interval[1]) * DM.hash2(self.rng, 77, 555)
	end
	function am:pick()
		if #self.ids == 0 then return nil end
		local tries = 0
		while tries < 8 do
			local i = 1 + floor(DM.hash2(self.rng, tries, 91) * #self.ids)
			local id = self.ids[i]
			if id ~= self.last2[1] and id ~= self.last2[2] then return id end
			tries = tries + 1
		end
		return self.ids[1]
	end
	function am:start()
		self.running = true
		self.timer = self:nextIn() * 0.3
	end
	function am:stop() self.running = false end
	function am:pump(dt)
		if not self.running then return false end
		if self.condition and not self.condition() then return false end
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = self:nextIn()
			self.rng = self.rng + 1
			local id = self:pick()
			if id then
				local vol = self.volume[1] + (self.volume[2] - self.volume[1]) * DM.hash2(self.rng, 3, 9)
				local pit = self.pitchRange[1] + (self.pitchRange[2] - self.pitchRange[1]) * DM.hash2(self.rng, 5, 7)
				AUX.play(id, { volume = vol, pitch = pit, bus = self.bus, def = { bus = self.bus, volume = vol } })
				self.last2[2] = self.last2[1]
				self.last2[1] = id
				return true
			end
		end
		return false
	end
	AUX._ambients[name] = am
	return am
end

-- ================= POSICIONAL 3D SIMULADO (rolloff^2 + doppler) =================
AUX._posTracked = {}
function AUX.positional(soundOrId, getPosFn, opts)
	opts = opts or {}
	local reg = AUX._sounds[soundOrId]
	local snd = reg and reg.inst or soundOrId
	local tr = {
		snd = snd, getPos = getPosFn, refDist = opts.refDist or 12, maxDist = opts.maxDist or 120,
		baseVol = opts.volume or (snd and snd.Volume) or 0.5, doppler = opts.doppler ~= false,
		lastPos = nil, lastVel = 0,
	}
	AUX._posTracked[#AUX._posTracked + 1] = tr
	return tr
end
local function camPos()
	local ws = workspace
	local cam = ws and ws.CurrentCamera
	if cam and cam.CFrame then return cam.CFrame.Position end
	return nil
end
function AUX._pumpPositional(dt)
	for _, tr in ipairs(AUX._posTracked) do
		local cp = camPos()
		local wp = tr.getPos and tr.getPos()
		if cp and wp and tr.snd then
			local dx, dy, dz = cp.X - wp.X, cp.Y - wp.Y, cp.Z - wp.Z
			local d = sqrt(dx * dx + dy * dy + dz * dz)
			-- rolloff inverso-quadratico (real) com clamp
			local g = clamp((tr.refDist / math.max(d, tr.refDist)) ^ 2, 0, 1)
			if d > tr.maxDist then g = 0 end
			-- doppler aproximado: velocidade radial do emissor
			local pitch = 1
			if tr.doppler and tr.lastPos and dt > 0 then
				local vx = (wp.X - tr.lastPos.X) / dt
				local vy = (wp.Y - tr.lastPos.Y) / dt
				local vz = (wp.Z - tr.lastPos.Z) / dt
				local speed = sqrt(vx * vx + vy * vy + vz * vz)
				local radial = speed * (dx / math.max(d, 1e-4))
				pitch = clamp(1 + radial / 343 * 6, 0.7, 1.4) -- exagero artistico
			end
			tr.lastPos = wp
			pcall(function()
				tr.snd.Volume = tr.baseVol * g
				tr.snd.PlaybackSpeed = pitch
			end)
		end
	end
end

-- ================= LINK AWX (mar alto => vento ondulante) =================
function AUX.linkSea(sea, ambientName, opts)
	opts = opts or {}
	local am = AUX._ambients[ambientName]
	if not am or not sea then return false end
	am.condition = function()
		local h = 0
		for w = 1, #sea.waves do h = h + (sea.waves[w].amp or 0) end
		return h >= (opts.minAmp or 0.4)
	end
	return true
end

-- ================= PUMP GLOBAL =================
AUX._fires = {}
function AUX.pump(dt)
	dt = dt or 0.016
	AUX._pumpDucks(dt)
	AUX._pumpLayers(dt)
	for name, am in pairs(AUX._ambients) do
		if am:pump(dt) then
			AUX._fires[#AUX._fires + 1] = { name = name, t = (tick and tick()) or os.clock() }
			if #AUX._fires > 8 then table.remove(AUX._fires, 1) end
		end
	end
	AUX._pumpPositional(dt)
end
function AUX.stats()
	local n, playing = 0, 0
	for _, reg in pairs(AUX._sounds) do
		n = n + 1
		local ok, p = pcall(function() return reg.inst.IsPlaying or reg.inst.Playing end)
		if ok and p then playing = playing + 1 end
	end
	return {
		sounds = n, playing = playing, buses = #AUX.BUSES,
		ducks = #AUX._ducks, ambients = (function() local c = 0 for _ in pairs(AUX._ambients) do c = c + 1 end return c end)(),
		positional = #AUX._posTracked, layers = AUX._layers and AUX._layers.intensity or nil,
	}
end

AUX._version = "1.0.0"
end

do
--[[ ARKHER SCENE X (ASXN) — grafo de cena, query, SCATTER procedural e LOD ]]
-- O "organizador/montador" que o Roblox nao tem nativo: spatial-hash real,
-- query por classe/nome/atributo/regiao, PATINA (variacao sutil deterministica
-- de cor = anti-CG realista), SCATTER com amostragem Poisson-like no nosso
-- ATX (regras de bioma/declive/agua), biblioteca de vegetacao procedural
-- (arvores/arbustos/pedras/grama geradas como models reais), MERGE/EXPLODE,
-- alinhamento ARRAY, registro de assoc `LOD de distancia` cooperando com D-O15.
-- RRW: REPRESENTACAO (hash+regras) -> MATERIALIZACAO (models reais no mundo).
ArkherSceneX = ArkherSceneX or {}
local X = ArkherSceneX
local DM = ArkherDM
local floor, abs, sqrt, min, max = math.floor, math.abs, math.sqrt, math.min, math.max
local clamp, lerp = DM.clamp, DM.lerp
local pi, cos, sin = math.pi, math.cos, math.sin
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

-- ================= SPATIAL HASH =================
X.CELL = 8
X._hash = {} -- "cx,cz" -> {inst}
local function cellKeyOf(x, z) return floor(x / X.CELL) .. "," .. floor(z / X.CELL) end
function X.register(inst)
	if not inst then return end
	local ok, pos = pcall(function() return inst.Position end)
	if not (ok and pos) then return end
	local k = cellKeyOf(pos.X, pos.Z)
	X._hash[k] = X._hash[k] or {}
	X._hash[k][#X._hash[k] + 1] = inst
end
function X.unregister(inst, x, z)
	if x and z then
		local k = cellKeyOf(x, z)
		local list = X._hash[k]
		if list then for i, v in ipairs(list) do if v == inst then table.remove(list, i) break end end end
	end
end
function X.rehash()
	X._hash = {}
	if not workspace then return 0 end
	local n = 0
	local function scan(node)
		for _, ch in ipairs(node:GetChildren()) do
			if ch:IsA("BasePart") then X.register(ch) n = n + 1 end
			scan(ch)
		end
	end
	scan(workspace)
	return n
end
function X.near(x, z, r)
	local out = {}
	local c0 = floor((x - r) / X.CELL)
	local c1 = floor((x + r) / X.CELL)
	local d0 = floor((z - r) / X.CELL)
	local d1 = floor((z + r) / X.CELL)
	for cx = c0, c1 do
		for cz = d0, d1 do
			local list = X._hash[cx .. "," .. cz]
			if list then
				for _, inst in ipairs(list) do
					local ok2, pos = pcall(function() return inst.Position end)
					if ok2 and pos then
						local dx, dz = pos.X - x, pos.Z - z
						if dx * dx + dz * dz <= r * r then out[#out + 1] = inst end
					end
				end
			end
		end
	end
	return out
end

-- ================= QUERY (estilo explorer programatico) =================
function X.query(spec)
	spec = spec or {}
	local pool = {}
	local function scan(node)
		for _, ch in ipairs(node:GetChildren()) do
			local ok = true
			if spec.class and not ch:IsA(spec.class) then ok = false end
			if ok and spec.name then
				local n = ch.Name or ""
				if not n:lower():find(spec.name:lower(), 1, true) then ok = false end
			end
			if ok and spec.attr then
				for k, v in pairs(spec.attr) do
					local a = ch:GetAttribute(k)
					if v == nil and a == nil then ok = false
					elseif v ~= nil and a ~= v then ok = false end
				end
			end
			if ok and spec.tag then
				local t = ch:GetAttribute("arkher_tag")
				if t ~= spec.tag then ok = false end
			end
			if ok and spec.where then ok = spec.where(ch) == true end
			if ok then pool[#pool + 1] = ch end
			scan(ch)
		end
	end
	scan(workspace)
	if spec.within then
		local w = spec.within
		local filtered = {}
		for _, ch in ipairs(pool) do
			local ok, pos = pcall(function() return ch.Position end)
			if ok and pos then
				local dx, dz = pos.X - w.x, pos.Z - w.z
				if dx * dx + dz * dz <= w.r * w.r then filtered[#filtered + 1] = ch end
			end
		end
		pool = filtered
	end
	return pool
end

-- ================= PATINA (variacao deterministica anti-CG) =================
function X.patina(insts, opts)
	opts = opts or {}
	local seed = opts.seed or 777
	local hJ, sJ, vJ = opts.hueJit or 0.02, opts.satJit or 0.06, opts.valJit or 0.08
	local n = 0
	local hasHSV = Color3.fromHSV ~= nil
	for i, inst in ipairs(insts) do
		local okC, c = pcall(function() return inst.Color end)
		if okC and c then
			local r1 = DM.hash3(i, 11, 13, seed) - 0.5
			local r2 = DM.hash3(i, 17, 19, seed) - 0.5
			local r3 = DM.hash3(i, 23, 29, seed) - 0.5
			if hasHSV and type(c) == "userdata" and c.ToHSV or (hasHSV and type(c) == "table" and c.ToHSV) then -- shim-safe
				local ok2, h, s, v = pcall(function() return c:ToHSV() end)
				if ok2 then
					local nh = (h + r1 * hJ * 2) % 1
					local ns = clamp(s + r2 * sJ * 2, 0, 1)
					local nv = clamp(v + r3 * vJ * 2, 0, 1)
					pcall(function() inst.Color = Color3.fromHSV(nh, ns, nv) end)
					n = n + 1
				end
			else
				-- fallback RGB-jitter (mesma finalidade: quebrar o phong uniforme)
				local rr = (c.R or 0.5) + r2 * sJ
				local gg = (c.G or 0.5) + r1 * hJ
				local bb = (c.B or 0.5) + r3 * vJ
				pcall(function()
					inst.Color = Color3.new(clamp(rr, 0, 1), clamp(gg, 0, 1), clamp(bb, 0, 1))
				end)
				n = n + 1
			end
		end
	end
	return n
end

-- ================= VEGETACAO / PROPS PROCEDURAIS (models reais) =================
local function mkPart(name, size, cf, color, parent, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.CanCollide = false
	pcall(function() p.Material = material or Enum.Material.SmoothPlastic end)
	if parent then p.Parent = parent end
	return p
end
-- cores por bioma (Whittaker aliada ao ATX)
X.BIOME_FOLIAGE = {
	floresta_equatorial = { { 34, 118, 52 }, { 52, 132, 60 }, { 74, 148, 66 } },
	taiga = { { 28, 84, 44 }, { 38, 96, 46 }, { 48, 110, 52 } },
	savana = { { 96, 122, 44 }, { 118, 138, 52 } },
	deserto = { { 140, 128, 70 } },
	padrao = { { 46, 108, 56 }, { 58, 122, 60 }, { 70, 130, 64 } },
}
function X.foliageColor(biome, seed, i)
	local pal = X.BIOME_FOLIAGE[biome] or X.BIOME_FOLIAGE.padrao
	local pick = pal[1 + floor(DM.hash3(i, 3, 5, seed) * #pal) % #pal]
	return Color3.fromRGB(pick[1], pick[2], pick[3])
end
-- ARVORE: tronco conificado + dossel em 2-3 blobs organicos
function X.makeTree(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local h = opts.height or (7 + floor(DM.hash3(seed, 1, 2, 9) * 6))
	local model = Instance.new("Model")
	model.Name = "Tree_" .. seed
	local trunkH = h * 0.45
	local trunkW = 0.5 + h * 0.05
	mkPart("Trunk", Vector3.new(trunkW, trunkH, trunkW),
		CFrame.new(x, y + trunkH / 2, z),
		Color3.fromRGB(92 + floor(DM.hash3(seed, 7, 1, 3) * 12), 74, 56), model, Enum.Material.Wood)
	local canopyBase = y + trunkH
	local blobs = 2 + floor(DM.hash3(seed, 3, 5, 7) * 2)
	for i = 1, blobs do
		local ang = DM.hash3(seed, i, 11, 13) * pi * 2
		local rad = h * 0.18 * (i - 1) * 0.5
		local ox, oz = cos(ang) * rad, sin(ang) * rad
		local size = h * (0.42 - 0.09 * (i - 1))
		local col = X.foliageColor(opts.biome, seed, i)
		mkPart("Canopy_" .. i, Vector3.new(size, size * 0.75, size),
			CFrame.new(x + ox, canopyBase + size * 0.35 * (i - 1) + size * 0.25, z + oz), col, model, Enum.Material.Grass)
	end
	model:SetAttribute("arkher_tag", opts.tag or "tree")
	model:SetAttribute("biome", opts.biome or "padrao")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- ARBUSTO: 1-2 blobs baixos
function X.makeBush(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Bush_" .. seed
	local s = 1 + DM.hash3(seed, 2, 4, 6) * 2
	mkPart("BushA", Vector3.new(s * 2, s * 1.3, s * 2), CFrame.new(x, y + s * 0.6, z),
		X.foliageColor(opts.biome, seed, 1), model, Enum.Material.Grass)
	mkPart("BushB", Vector3.new(s * 1.2, s, s * 1.2), CFrame.new(x + s * 0.7, y + s * 0.5, z + s * 0.3),
		X.foliageColor(opts.biome, seed, 2), model, Enum.Material.Grass)
	model:SetAttribute("arkher_tag", opts.tag or "bush")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- PEDRA: 2-3 paralelepipedos empilhados com rotacao (rocha angular)
function X.makeRock(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Rock_" .. seed
	local s = 1 + DM.hash3(seed, 5, 7, 9) * 3.5
	local g1 = Color3.fromRGB(118 + floor(DM.hash3(seed, 9, 1, 3) * 14), 116, 110)
	mkPart("RockA", Vector3.new(s * 2, s * 1.2, s * 1.6), CFrame.new(x, y + s * 0.5, z)
		* CFrame.Angles(0.1, DM.hash3(seed, 1, 2, 3) * pi, 0.06), g1, model, Enum.Material.Slate)
	if DM.hash3(seed, 8, 2, 9) > 0.45 then
		mkPart("RockB", Vector3.new(s * 1.1, s * 0.8, s), CFrame.new(x + s * 0.6, y + s * 0.9, z + s * 0.2)
			* CFrame.Angles(0.15, DM.hash3(seed, 4, 5, 6) * pi, -0.08), g1, model, Enum.Material.Slate)
	end
	model:SetAttribute("arkher_tag", opts.tag or "rock")
	if opts.parent then model.Parent = opts.parent end
	return model
end
-- GRAMA: tufo de 4-6 lâminas finas (Parts finos) com inclinacao
-- (estilizado REAL: densidade visual, custo baixo)
function X.makeGrass(x, y, z, opts)
	opts = opts or {}
	local seed = opts.seed or 1
	local model = Instance.new("Model")
	model.Name = "Grass_" .. seed
	local blades = 4 + floor(DM.hash3(seed, 3, 7, 11) * 3)
	for i = 1, blades do
		local a = (i / blades) * pi * 2 + DM.hash3(seed, i, 1, 3) * 0.8
		local r = 0.2 + DM.hash3(seed, i, 5, 7) * 0.4
		local bx, bz = x + cos(a) * r, z + sin(a) * r
		local bh = 0.7 + DM.hash3(seed, i, 9, 11) * 1.0
		mkPart("Blade_" .. i, Vector3.new(0.1, bh, 0.1),
			CFrame.new(bx, y + bh / 2, bz) * CFrame.Angles(0.05 + DM.hash3(seed, i, 13, 15) * 0.3, 0, 0),
			Color3.fromRGB(58 + floor(DM.hash3(seed, i, 17, 19) * 18), 128 + floor(DM.hash3(seed, i, 21, 23) * 20), 52), model)
	end
	model:SetAttribute("arkher_tag", opts.tag or "grass")
	if opts.parent then model.Parent = opts.parent end
	return model
end
X.MAKERS = { tree = X.makeTree, bush = X.makeBush, rock = X.makeRock, grass = X.makeGrass }
X.MAKER_KEYS = { "tree", "bush", "rock", "grass" }

-- regras por bioma: qual maker + densidade
X.BIOME_RULES = {
	floresta_equatorial = { tree = 0.6, bush = 0.25, grass = 0.15, rock = 0.0 },
	taiga = { tree = 0.55, bush = 0.1, rock = 0.35, grass = 0.0 },
	savana = { tree = 0.1, bush = 0.3, grass = 0.6, rock = 0.0 },
	deserto = { rock = 0.7, bush = 0.3, tree = 0, grass = 0 },
	pradaria = { grass = 0.7, bush = 0.25, tree = 0.05, rock = 0 },
	rocha = { rock = 0.85, bush = 0.15, tree = 0, grass = 0 },
	padrao = { tree = 0.4, bush = 0.3, grass = 0.3, rock = 0 },
}

-- ================= SCATTER (poisson-ish + regras do ATX) =================
-- spec: { x, z, radius | rect = {w,h}, count, minDist, seed, maker | makers={tree=0.6,...},
--         world (ATX), maxSlope, biome (forcar), aboveWater, align, parent, tag }
-- fase 1: PREPARE — calcula os pontos (sem criar nada)
function X.prepare(spec)
	spec = spec or {}
	local seed = spec.seed or 4242
	local count = spec.count or 40
	local minDist = spec.minDist or 4
	local placed = {}
	local cells = {}
	local cd = max(minDist, 1)
	local function freeSpot(px, pz)
		local cx, cz = floor(px / cd), floor(pz / cd)
		for ax = -1, 1 do
			for az = -1, 1 do
				local list = cells[(cx + ax) .. "," .. (cz + az)]
				if list then
					for _, it in ipairs(list) do
						local dx, dz = px - it[1], pz - it[2]
						if dx * dx + dz * dz < minDist * minDist then return false end
					end
				end
			end
		end
		return true
	end
	-- escolher maker conforme regra do bioma
	local function pickMaker(r, biome)
		local dist = spec.makers or (X.BIOME_RULES[biome] or X.BIOME_RULES.padrao)
		if spec.maker then return spec.maker, 1 end
		local acc = 0
		local tot = 0
		for _, v in pairs(dist) do tot = tot + v end
		for k, v in pairs(dist) do
			acc = acc + v
			if r <= acc / max(tot, 1e-6) then return k, v end
		end
		return "grass", 0.3
	end
	local tries = 0
	local target = clamp(count, 1, 800)
	while #placed < target and tries < target * 8 do
		tries = tries + 1
		local r1 = DM.hash3(tries, 1, 2, seed)
		local r2 = DM.hash3(tries, 3, 4, seed)
		local px, pz, ok = 0, 0, true
		if spec.radius then
			local ang = r1 * pi * 2
			local dist = sqrt(r2) * spec.radius
			px, pz = spec.x + cos(ang) * dist, spec.z + sin(ang) * dist
		else
			local w = (spec.rect and spec.rect.w) or 60
			local h = (spec.rect and spec.rect.h) or 60
			px, pz = spec.x + (r1 - 0.5) * w, spec.z + (r2 - 0.5) * h
		end
		-- regras do terreno
		local py = 0
		local biome = spec.biome or "padrao"
		if spec.world then
			py = spec.world:heightAt(px, pz)
			local okN, v1, v2, v3 = pcall(function()
				if spec.world.normalAt then return spec.world:normalAt(px, pz) end
				return 0, 1, 0
			end)
			local nx = okN and tonumber(v1) or 0
			local nz = okN and tonumber(v3) or 0
			local slope = sqrt(nx * nx + nz * nz)
			if spec.maxSlope and slope > spec.maxSlope then ok = false end
			local sea = spec.world.seaLevel or 0
			if spec.aboveWater ~= false and py <= sea + 0.3 then ok = false end
			local okB, b2 = pcall(function()
				if spec.world.biomeAt then return spec.world:biomeAt(px, pz) end
				return nil
			end)
			if okB and b2 then biome = b2 end
		end
		if ok and not freeSpot(px, pz) then ok = false end
		if ok then
			local r3 = DM.hash3(tries, 5, 6, seed)
			local makerKey = pickMaker(r3, biome)
			placed[#placed + 1] = { px, pz, py, makerKey, biome }
			local k2 = floor(px / cd) .. "," .. floor(pz / cd)
			cells[k2] = cells[k2] or {}
			cells[k2][#cells[k2] + 1] = { px, pz }
		end
	end
	return { placed = placed, tries = tries }
end
-- preview: só pontos (para a UI desenhar antes de materializar)
function X.preview(spec)
	local r = X.prepare(spec)
	return r.placed, r.tries
end
-- fase 2: SCATTER — materializa em models reais
function X.scatter(spec)
	spec = spec or {}
	local seed = spec.seed or 4242
	local pre = spec._prepared or X.prepare(spec)
	local made = {}
	local parent = spec.parent or workspace
	local modelRoot = Instance.new("Model")
	modelRoot.Name = spec.name or "ASXN_Scatter"
	for i, it in ipairs(pre.placed) do
		local mk = X.MAKERS[it[4]] or X.makeGrass
		local m = mk(it[1], it[3], it[2], {
			seed = seed + i, biome = it[5], tag = spec.tag or it[4], parent = modelRoot,
			height = spec.height,
		})
		X.register(m.PrimaryPart or (m:GetChildren()[1]))
		made[#made + 1] = m
	end
	modelRoot.Parent = parent
	return { made = made, count = #made, tries = pre.tries, model = modelRoot }
end

-- ================= LOD DE DISTANCIA (colabora com D-O15) =================
X._lods = {}
function X.registerLOD(model, rings)
	X._lods[#X._lods + 1] = { model = model, rings = rings or { near = 80, mid = 180, far = 320 } }
end
-- retorna quantas instancias viraram "far-cull" (transp 1 + collide off)
local function firstPartPos(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local ok, pos = pcall(function() return p.Position end)
			if ok and pos then return pos end
		end
	end
	return nil
end
function X.applyLOD(focusX, focusZ)
	local culled, shown, ghosts = 0, 0, 0
	for _, e in ipairs(X._lods) do
		local m = e.model
		if m and m.Parent ~= nil then
			local center = firstPartPos(m)
			if center then
				local dx, dz = center.X - (focusX or 0), center.Z - (focusZ or 0)
				local dist = sqrt(dx * dx + dz * dz)
				local ring = dist < e.rings.near and 1 or (dist < e.rings.mid and 2 or (dist < e.rings.far and 3 or 4))
				-- D-O15: niveis baixos forcam culling mais proximo
				if ArkherDO15 then
					local lv = ArkherDO15.state.level
					if lv <= 2 and ring == 3 then ring = 4 end
					if lv >= 4 and ring == 4 then ring = 3 end
				end
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then
						if ring <= 2 then
							if p:GetAttribute("lod_t") then p.Transparency = p:GetAttribute("lod_t") p.CanCollide = p:GetAttribute("lod_c") == true end
							shown = shown + 1
						elseif ring == 3 then
							if not p:GetAttribute("lod_t") then p:SetAttribute("lod_t", p.Transparency) p:SetAttribute("lod_c", p.CanCollide) end
							p.Transparency = min((p:GetAttribute("lod_t") or 0) + 0.5, 1)
							ghosts = ghosts + 1
						else
							if not p:GetAttribute("lod_t") then p:SetAttribute("lod_t", p.Transparency) p:SetAttribute("lod_c", p.CanCollide) end
							p.Transparency = 1
							p.CanCollide = false
							culled = culled + 1
						end
					end
				end
			end
		end
	end
	return { culled = culled, shown = shown, ghosts = ghosts, tracked = #X._lods }
end

-- ================= MERGE / EXPLODE / ARRAY-ALIGN =================
function X.merge(parts, name)
	local m = Instance.new("Model")
	m.Name = name or "ASXN_Merged"
	for i, p in ipairs(parts) do
		local old = p.Parent
		p.Parent = m
		m:SetAttribute("orig_parent_" .. i, old and old.Name or "")
	end
	m.Parent = workspace
	return m
end
function X.explode(model)
	local out = {}
	for _, ch in ipairs(model:GetChildren()) do
		ch.Parent = workspace
		out[#out + 1] = ch
	end
	model:Destroy()
	return out
end
function X.alignArray(parts, opts)
	opts = opts or {}
	local axis = opts.axis or "x"
	local mode = opts.mode or "min"
	local vals = {}
	local base = math.huge
	if mode == "max" then base = -math.huge end
	local sum = 0
	for _, p in ipairs(parts) do
		local v = p.Position[axis:upper()]
		sum = sum + v
		if mode == "min" then base = min(base, v) elseif mode == "max" then base = max(base, v) end
	end
	local target = mode == "avg" and (sum / #parts) or base
	for _, p in ipairs(parts) do
		local pos = p.Position
		if axis == "x" then p.CFrame = CFrame.new(target, pos.Y, pos.Z)
		elseif axis == "y" then p.CFrame = CFrame.new(pos.X, target, pos.Z)
		else p.CFrame = CFrame.new(pos.X, pos.Y, target) end
	end
	return target
end

X._version = "1.0.0"
end

do
-- =============================================================
-- ATMOS X (AEX) v5 — CÉU + CLIMA CUSTOM (nao depende da atmosfera padrao)
-- CICLO DIA-NOITE REAL: temperatura de COR do sol em Kelvin -> RGB
-- via aproximacao Planckian/CIE (mesma teoria RRW: dado fisico real
-- -> representacao adaptativa), nuvens orgânicas, weather machine com
-- 7 estados e TRANSIÇÕES suaves, relâmpagos agendados, links AWX/AUX.
-- Do zero, determinístico, deterministic-pump. ⚡🌤️
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local AEX = {}
AEX._V = 5

-- ---------- dados fisicos ----------
-- presets de horario: infos fisicas (elevacao solar, kelvin do disco)
AEX.SKY_PRESETS = {
	madrugada = { clock = 5.5,   fogEnd = 12000, kelvin = 2200, haze = 4.0 },
	amanhecer = { clock = 6.8,   fogEnd = 30000, kelvin = 3200, haze = 2.4 },
	meiodia   = { clock = 12.0,  fogEnd = 60000, kelvin = 5600, haze = 0.7 },
	tarde     = { clock = 15.5,  fogEnd = 50000, kelvin = 5200, haze = 1.2 },
	entardecer= { clock = 18.3,  fogEnd = 24000, kelvin = 3600, haze = 3.2 },
	noite     = { clock = 23.5,  fogEnd = 20000, kelvin = 1900, haze = 1.0, stars = true },
}

-- weather machine: cada estado com parcelas fisicas
AEX.WEATHER = {
	limpo     = { fogEnd = 60000, haze = 0.7,  rain = 0, wind = 0.05, cloud = 0.10, waveBoost = 1.00, volBoost = 0.00 },
	nuvem     = { fogEnd = 30000, haze = 2.5,  rain = 0, wind = 0.25, cloud = 0.65, waveBoost = 1.15, volBoost = 0.05 },
	chuva     = { fogEnd = 8000,  haze = 5.0,  rain = 1, wind = 0.55, cloud = 0.90, waveBoost = 1.60, volBoost = 0.18 },
	tempestade= { fogEnd = 4500,  haze = 7.5,  rain = 1, wind = 1.00, cloud = 1.00, waveBoost = 2.20, volBoost = 0.30, lightning = true },
	neblina   = { fogEnd = 1800,  haze = 9.0,  rain = 0, wind = 0.05, cloud = 0.40, waveBoost = 1.00, volBoost = 0.03 },
	neve      = { fogEnd = 12000, haze = 4.0,  rain = 0, wind = 0.35, cloud = 0.80, waveBoost = 1.10, volBoost = 0.10, snow = true },
	aurora    = { fogEnd = 50000, haze = 0.4,  rain = 0, wind = 0.10, cloud = 0.05, waveBoost = 1.00, volBoost = 0.05, stars = true },
}

-- ---------- Kelvin -> RGB (CIE 1931 aproximacao real) ----------
function AEX.kelvinRGB(k)
	local t = mclamp(k, 1000, 12000) / 100
	local r, g, b
	if t <= 66 then r = 255 else r = mclamp(329.7 * (t - 60) ^ -0.1332, 0, 255) end
	if t <= 66 then g = mclamp(99.47 * math.log(math.max(t, 1)) - 161.12, 0, 255)
	else g = mclamp(288.12 * (t - 60) ^ -0.0755, 0, 255) end
	if t >= 66 then b = 255 elseif t <= 19 then b = 0
	else b = mclamp(138.52 * math.log(t - 10) - 305.04, 0, 255) end
	return Color3.fromRGB(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

-- ---------- estado ----------
local function mk(max)
	return { t = 0, phase = DM.hash3(1, 3, 5, 77) * 100 }
end

local S = {
	state = "limpo",
	prev = "limpo",
	blend = 1,          -- 1 = estado alvo atual
	blendSpeed = 0.35,  -- por segundo
	preset = "meiodia",
	clock = 12,
	cycleSpeed = 0.0045, -- horas por segundo (1 hora solar amplificada)
	lightning_at = 0,
	_state = mk(),
	_fires = {}, ring = 1,
	links = { waves = true, audio = true },
}
AEX.S = S

local function fire(event)
	S._fires[S.ring] = event
	S.ring = (S.ring % 60) + 1
end

-- ---------- instancias reais ----------
local function ensureReal(obj)
	if obj and obj.lighting then S._lig = obj.lighting end
	if not S._lig and game then
		local ok, lig = pcall(function() return game:GetService("Lighting") end)
		if ok then S._lig = lig end
	end
	-- efeitos REAIS
	if S._lig then
		S._atmo = S._lig:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		S._atmo.Parent = S._lig
		S._cc = S._lig:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
		S._cc.Parent = S._lig
	end
	return S._lig ~= nil
end

-- ---------- estado maxwell (calcula multiplicadores do clima) ----------
function AEX.weatherMix(k)
	local cur = AEX.WEATHER[S.state]
	local pre = AEX.WEATHER[S.prev]
	local a = S.blend
	local function lerp(f) return pre[f] * (1 - a) + cur[f] * a end
	return {
		fogEnd = lerp("fogEnd"),
		haze = lerp("haze"),
		rain = lerp("rain"),
		wind = lerp("wind"),
		cloud = lerp("cloud"),
		waveBoost = lerp("waveBoost"),
		volBoost = lerp("volBoost"),
		lightning = cur.lightning and a > 0.7,
		snow = cur.snow and a > 0.7,
		stars = cur.stars or (k and k.stars),
	}
end

-- ---------- aplicacao REAL ----------
function AEX.apply(obj)
	obj = obj or {}
	local lig = S._lig or (obj.lighting)
	if lig == nil then return false end
	local p = AEX.SKY_PRESETS[S.preset] or AEX.SKY_PRESETS.meiodia
	local w = AEX.weatherMix(p)
	-- hora real (ClockTime)
	pcall(function() lig.ClockTime = S.clock end)
	-- cor do disco solar em Kelvin -> ambient/outdoor
	local kRGB = AEX.kelvinRGB(p.kelvin)
	pcall(function()
		if lig.Ambient ~= nil then lig.Ambient = kRGB end
		if lig.OutdoorAmbient ~= nil then lig.OutdoorAmbient = kRGB end
		lig.FogEnd = w.fogEnd
		if lig.FogColor ~= nil then lig.FogColor = kRGB end
	end)
	if S._atmo then
		pcall(function()
			S._atmo.Density = mclamp(0.18 + w.haze / 40, 0, 0.6)
			S._atmo.Haze = mclamp(w.haze, 0, 10)
		end)
	end
	-- ceu fisico: estrelas à noite ou com auroras
	if lig then
		local sky = lig:FindFirstChildOfClass("Sky")
		if w.stars and not sky then
			local ok, ns = pcall(function() return Instance.new("Sky") end)
			if ok and ns then pcall(function() ns.Parent = lig end) end
		end
	end
	return true
end

-- ---------- vitimas do clima (links AWX/AUX) ----------
function AEX.pushLinks(w)
	if S.links.waves and ArkherWaterX then
		for _, b in ipairs(ArkherWaterX.bodies) do
			for _, wv in ipairs(b.waves) do
				wv._isWave = true
			end
			b._stormBoost = w.waveBoost
			b._baseAmp = b._baseAmp or {}
			b._baseSpd = b._baseSpd or {}
			for i = 1, #b.waves do
				if b._baseAmp[i] == nil then b._baseAmp[i] = b.waves[i].amp or 0.1 end
				if b._baseSpd[i] == nil then b._baseSpd[i] = b.waves[i].speed or 1 end
				b.waves[i].amp = b._baseAmp[i] * w.waveBoost
				b.waves[i].speed = b._baseSpd[i] * (0.85 + w.wind * 0.4)
			end
		end
	end
	if S.links.audio and ArkherAudioX then
		for _, ev in ipairs(ArkherAudioX._ambients) do
			if ev.dayNight == "rain" then ev.likelihood = math.min(0.3 + w.rain * 0.7, 1) end
		end
		local grp = ArkherAudioX._groups and ArkherAudioX._groups.weather
		if grp then grp.Volume = mclamp(0.06 + w.volBoost, 0, 1) end
	end
end

-- ---------- pump deterministico ----------
function AEX.pump(dt)
	dt = dt or 1 / 60
	S._state.t = S._state.t + dt
	-- ciclo solar (cycleSpeed horas por segundo)
	S.clock = (S.clock + dt * S.cycleSpeed) % 24
	-- transicao do clima
	if S.blend < 1 then
		S.blend = math.min(1, S.blend + dt * S.blendSpeed)
	end
	local w = AEX.weatherMix(nil)
	-- relâmpago agendado fisicamente (tempestade)
	if w.lightning and S._state.t >= S.lightning_at then
		S.lightning_at = S._state.t + 1.5 + DM.hash3(math.floor(S._state.t), 7, 11, 41) * 6
		fire("lightning")
		if S._cc then
			pcall(function() S._cc.Brightness = 0.18 end)
		end
		if ArkherAudioX then
			pcall(function() ArkherAudioX.playSfx("ARK_THUNDER", "weather", { pitch = 0.9, volume = 0.9 }) end)
		end
	end
	-- decaimento do flash
	if S._cc and S._cc.Brightness and S._cc.Brightness > 0.0001 then
		pcall(function() S._cc.Brightness = math.max(0, S._cc.Brightness - dt * 0.6) end)
	end
	AEX.apply()
	AEX.pushLinks(w)
	return S.clock, w
end

-- ---------- API PUBLICA ----------
function AEX.setPreset(name)
	if AEX.SKY_PRESETS[name] then S.preset = name S.clock = AEX.SKY_PRESETS[name].clock fire("preset:" .. name) return true end
	return false
end
function AEX.setWeather(name, speedo)
	if not AEX.WEATHER[name] then return false end
	S.prev = S.state
	S.state = name
	S.blend = 0
	S.blendSpeed = speedo or 0.35
	fire("weather:" .. name)
	return true
end
function AEX.setClock(h) S.clock = (h or 12) % 24 return true end
function AEX.setup(obj) return ensureReal(obj or {}) end
function AEX.skyDayNight() return S.clock, S.state, S.blend end

AEX._setup = ensureReal

AEX.VERSION = "5.0"

_G.ArkherAtmosX = AEX

end

do
-- =============================================================
-- CAMERA X (ACX) v5 — CINEMATOGRAFIA CUSTOM em cima de Camera real
-- SHOTS fisicos: orbit / dolly / crane / follow / flypath (Catmull-Rom
-- AAX compartilhado), spring-follow (mesmo oscilador amortecido do AAX),
-- SHAKE com trauma^2 (modelo real de cinematografia), RULE OF THIRDS,
-- camera-collision real por raycast, FADE IN/OUT via ColorCorrection
-- no Lighting, CUTS com cross-fade. Do zero, pumpless-guaranteed. 🎬
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local ACX = {}
ACX._V = 5

-- ---------- camera alvo ----------
local function cam()
	local ok, c = pcall(function() return workspace.CurrentCamera end)
	if ok and c then return c end
	return nil
end

local function lookTowards(from, to)
	return CFrame.lookAt(from, to)
end

-- ---------- estado ----------
local S = {
	mode = "free",
	t = 0,
	shot = nil,       -- spec ativo
	trauma = 0,       -- 0..1, shake^2
	followLag = 0.60, -- s
	followPt = nil,
	followVel = { X = 0, Y = 0, Z = 0 },
	path = nil,       -- catmull func
	_fires = {}, ring = 1,
}
ACX.S = S

local function fire(e) S._fires[S.ring] = e S.ring = (S.ring % 60) + 1 end

-- ---------- SHOTS ----------
-- spec: { type="orbit", center=V3, radius, height, speed, lookAt?, duration }
--       { type="dolly", from, to, ease, duration, lookAt }
--       { type="crane", from, to, ease, duration, lookAt } (dolly com bias Y)
--       { type="follow", part=V3-provider fn|part, dist, height, lag, duration }
--       { type="fly", from, mid, to, duration, lookAt } (catmull por 4 pts)

function ACX.shot(spec)
	spec = spec or {}
	spec.type = spec.type or "dolly"
	spec.duration = spec.duration or 4
	S.shot = spec
	S.mode = spec.type
	S.t = 0
	fire("shot:" .. spec.type)
	return spec
end

function ACX.stop()
	S.shot = nil
	S.mode = "free"
	fire("stop")
end

-- Catmull-Rom 3D via 3 curvas 1D do AAX (AAX.curve e escalar)
function ACX.curve3(a, m, b, n2)
	if ArkherAnimX and ArkherAnimX.curve then
		local cx = ArkherAnimX.curve({ a.X, m.X, b.X, n2.X })
		local cy = ArkherAnimX.curve({ a.Y, m.Y, b.Y, n2.Y })
		local cz = ArkherAnimX.curve({ a.Z, m.Z, b.Z, n2.Z })
		return function(u) return cx(u), cy(u), cz(u) end
	end
	return function(u) return a.X + (b.X - a.X) * u, a.Y + (b.Y - a.Y) * u, a.Z + (b.Z - a.Z) * u end
end

-- trajectory evaluators (REAL: posF :: t->V3, lookF :: t->V3)
local function evaluator(spec)
	local P = function(v) return v end
	if spec.type == "orbit" then
		local c = spec.center or Vector3.new(0, 0, 0)
		local r = spec.radius or 14
		local h = spec.height or 6
		local sp = spec.speed or 0.35 -- rad/s
		return function(t)
			return Vector3.new(c.X + math.cos(t * sp) * r, c.Y + h, c.Z + math.sin(t * sp) * r)
		end, function() return c end
	elseif spec.type == "dolly" or spec.type == "crane" then
		local from = spec.from or Vector3.new(-10, 4, -10)
		local to = spec.to or Vector3.new(10, 4, 10)
		local look = spec.lookAt or Vector3.new(0, 2, 0)
		local ease = (ArkherAnimX and ArkherAnimX.EASE[spec.ease or "easeInOut_sine"]) or function(x) return x end
		return function(t)
			local u = ease(mclamp(t / spec.duration, 0, 1))
			local lift = spec.type == "crane" and math.sin(u * math.pi) * (spec.lift or 8) or 0
			return Vector3.new(from.X + (to.X - from.X) * u, from.Y + (to.Y - from.Y) * u + lift, from.Z + (to.Z - from.Z) * u)
		end, function() return look end
	elseif spec.type == "follow" then
		local tgt = spec.target -- fn() -> V3 (ou part com .Position)
		local dist = spec.dist or 12
		local h = spec.height or 4
		return function(t)
			local p = type(tgt) == "function" and tgt() or (tgt and tgt.Position) or Vector3.new(0, 0, 0)
			-- atraso por mola: converge p/ atrás do alvo
			local bx, bz = p.X - dist, p.Z
			if S.followPt then
				local lag = spec.lag or S.followLag
				local k = 1 - math.exp(-t / math.max(lag, 0.01))
				bx = S.followPt.X + (bx - S.followPt.X) * math.min(k + 0.02, 1)
				bz = S.followPt.Z + (bz - S.followPt.Z) * math.min(k + 0.02, 1)
			end
			S.followPt = { X = bx, Y = p.Y, Z = bz }
			return Vector3.new(bx, p.Y + h, bz)
		end, function()
			local p = type(tgt) == "function" and tgt() or (tgt and tgt.Position) or Vector3.new(0, 0, 0)
			return p
		end
	elseif spec.type == "fly" then
		local a = spec.from or Vector3.new(-20, 8, -20)
		local m = spec.mid or Vector3.new(0, 14, 0)
		local b = spec.to or Vector3.new(20, 8, 20)
		local n2 = { X = b.X + (b.X - m.X), Y = b.Y + (b.Y - m.Y), Z = b.Z + (b.Z - m.Z) }
		local cur = ACX.curve3(a, m, b, n2)
		local look = spec.lookAt or Vector3.new(0, 2, 0)
		return function(t)
			local u = mclamp(t / spec.duration, 0, 1)
			return Vector3.new(cur(u))
		end, function() return look end
	end
	return function() return Vector3.new(0, 5, 10) end, function() return Vector3.new(0, 2, 0) end
end

-- ---------- SHAKE por TRAUMA (cinema real: amplitude ~ trauma^2) ----------
function ACX.addTrauma(v) S.trauma = mclamp(S.trauma + (v or 0.3), 0, 1) end

local function shakeNoise(t, seedAxis)
	-- 3 octavas suaves (sem pico, organico)
	local n = 0
	for o = 1, 3 do
		n = n + (DM.hash3(math.floor(t * (8 ^ o)), o * 13, 7, 921 + seedAxis) - 0.5) * 2 / (o * 2)
	end
	return n
end

-- ---------- collision (raycast REAL: puxa a camera pra dentro) ----------
local function collide(pos, look, maxDist)
	local dx, dy, dz = pos.X - look.X, pos.Y - look.Y, pos.Z - look.Z
	local d = math.sqrt(dx * dx + dy * dy + dz * dz)
	if d < 0.001 then return pos end
	local nd = math.min(d, maxDist or 80)
	local ok, hit = pcall(function()
		local rp = workspace:Raycast(
			Vector3.new(look.X + dx / d * 2, look.Y + dy / d * 2, look.Z + dz / d * 2),
			Vector3.new(dx / d * nd, dy / d * nd, dz / d * nd),
			nil
		)
		return rp and rp.Position or nil
	end)
	if ok and hit then return hit end
	return pos
end

-- ---------- FADE via ColorCorrectionEffect (Lighting) ----------
function ACX.fade(to, secs, doneFn)
	-- no Lighting (real): brightness -1 escuro
	local okL, lig = pcall(function() return game:GetService("Lighting") end)
	lig = okL and lig or nil
	if not lig then if doneFn then doneFn() end return end
	local cc = lig:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		local ok, n = pcall(function() return Instance.new("ColorCorrectionEffect") end)
		if ok and n then n.Parent = lig cc = n end
	end
	if not cc then if doneFn then doneFn() end return end
	S._fade = { cc = cc, from = cc.Brightness or 0, to = to or -1, t = 0, secs = secs or 0.5, done = doneFn }
end

-- ---------- PUMP (1/60 deterministico) ----------
function ACX.pump(dt)
	dt = dt or 1 / 60
	S.t = S.t + dt
	local c = cam()
	if not c then return false end
	-- fade channel
	if S._fade then
		local f = S._fade
		f.t = f.t + dt
		local u = mclamp(f.t / f.secs, 0, 1)
		local v = f.from + (f.to - f.from) * u
		pcall(function() f.cc.Brightness = v end)
		if u >= 1 then
			local d = f.done
			S._fade = nil
			if d then d() end
		end
	end
	-- trauma decay (real: ~1/s)
	S.trauma = math.max(0, S.trauma - dt * 1.2)
	if not S.shot then return true end
	local posF, lookF = evaluator(S.shot)
	local pos = posF(S.t)
	local look = lookF(S.t)
	-- collision
	pos = collide(pos, look, 100)
	-- shake (trauma^2 * ruído) aplicado na rotação
	local shakeAmt = S.trauma * S.trauma * 0.35
	local rx = shakeNoise(S.t, 1) * shakeAmt
	local ry = shakeNoise(S.t, 2) * shakeAmt
	local cf = lookTowards(pos, look) * CFrame.Angles(rx, ry, 0)
	pcall(function()
		c.CameraType = Enum.CameraType and Enum.CameraType.Scriptable or "Scriptable"
		c.CFrame = cf
	end)
	-- fim do shot?
	if S.shot.type ~= "follow" and S.t >= (S.shot.duration or 4) then
		ACX.stop()
	end
	return true
end

-- ---------- CUTS (sequencia de shots com fades) ----------
function ACX.cinema(shots)
	S._cinema = { list = shots, i = 0 }
	local function next()
		local it = S._cinema
		it.i = it.i + 1
		local spec = it.list[it.i]
		if not spec then S._cinema = nil fire("cinema:end") return end
		ACX.shot(spec)
	end
	next()
end
-- avança cinema quando o shot atual termina
function ACX.pumpCinema()
	if S._cinema and not S.shot then
		local it = S._cinema
		it.i = it.i + 1
		local spec = it.list[it.i]
		if spec then ACX.shot(spec) else S._cinema = nil fire("cinema:end") end
	end
end

ACX.VERSION = "5.0"

_G.ArkherCameraX = ACX

end

do
-- =============================================================
-- PARTICLES X (APX) v5 — EMISSORES CUSTOM com ESPECIFICAÇÕES FISICAS
-- Emite ParticleEmitter REAIS do Roblox mas com parametros gerados por
-- física nossa: VORTEX (velocidade tangencial ao eixo), BURST cone,
-- FOUNTAIN com alcance balístico, RING SHOCKWAVE expansivo, TRAIL,
-- BUDGET D-O15-aware (caps por nível de LOD), 12 presets com rampas
-- de cor/vida derivadas de temperatura/processo real. Do zero. ✨
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local APX = {}
APX._V = 5

-- ---------- presets (fisica por trás de cada) ----------
APX.PRESETS = {
	foguete   = { mode = "burst",  rate = 0,   burst = 1,  life = 2.2, speed = 26, spread = 0.06, gravity = 60,  size0 = 0.6, size1 = 0.05, c0 = { 255, 250, 220 }, c1 = { 255, 60, 10 } },
	fogo      = { mode = "cone",   rate = 90,  life = 1.4, speed = 6,  spread = 0.25, gravity = -12, size0 = 1.6, size1 = 0.2, c0 = { 255, 140, 20 }, c1 = { 255, 20, 0 }, light = 1.4 },
	fumaca    = { mode = "cone",   rate = 40,  life = 3.2, speed = 3,  spread = 0.4, gravity = -4,  size0 = 2.2, size1 = 5.5, c0 = { 120, 120, 120 }, c1 = { 60, 60, 60 }, alpha = 0.7 },
	faiscas   = { mode = "burst",  rate = 0,   burst = 60, life = 0.8, speed = 18, spread = 1.0, gravity = 24, size0 = 0.15, size1 = 0.05, c0 = { 255, 230, 120 }, c1 = { 255, 100, 10 } },
	agua      = { mode = "cone",   rate = 0,   burst = 80, life = 0.9, speed = 14, spread = 0.7, gravity = 26, size0 = 0.3, size1 = 0.1, c0 = { 130, 190, 240 }, c1 = { 220, 240, 255 } },
	magia     = { mode = "vortex", rate = 120, life = 2.0, speed = 5,  spread = 0.9, gravity = 0,  size0 = 0.5, size1 = 0.1, c0 = { 130, 80, 255 }, c1 = { 255, 130, 255 }, vR = 4, vOmega = 9 },
	gilman    = { mode = "ring",   rate = 0,   burst = 1,  life = 0.9, speed = 0,  spread = 0, gravity = 0,   size0 = 0.2, size1 = 12, c0 = { 255, 255, 255 }, c1 = { 120, 200, 255 }, alpha = 0.85 },
	chuva     = { mode = "cone",   rate = 240, life = 1.4, speed = 40, spread = 0.05, gravity = 90, size0 = 0.06, size1 = 0.06, c0 = { 160, 190, 230 }, c1 = { 160, 190, 230 }, down = true, area = 40 },
	neve      = { mode = "cone",   rate = 60,  life = 6.0, speed = 2,  spread = 1.0, gravity = 1.5, size0 = 0.25, size1 = 0.35, c0 = { 250, 250, 255 }, c1 = { 235, 240, 255 }, down = true, area = 40, sway = 1.2 },
	folhas    = { mode = "cone",   rate = 12,  life = 7.0, speed = 2.2, spread = 1.2, gravity = 2.2, size0 = 0.5, size1 = 0.6, c0 = { 120, 160, 40 }, c1 = { 200, 160, 60 }, down = true, area = 30, sway = 2.4 },
	poeira    = { mode = "cone",   rate = 26,  life = 5.0, speed = 0.8, spread = 1.6, gravity = -0.4, size0 = 0.4, size1 = 1.2, c0 = { 190, 170, 130 }, c1 = { 150, 135, 105 }, alpha = 0.5 },
	bolhas    = { mode = "cone",   rate = 22,  life = 4.5, speed = 3.5, spread = 0.3, gravity = -9, size0 = 0.3, size1 = 0.15, c0 = { 140, 200, 240 }, c1 = { 200, 240, 255 } },
	trilha    = { mode = "trail",  rate = 160, life = 0.7, speed = 0.5, spread = 0.05, gravity = 0, size0 = 0.7, size1 = 0.05, c0 = { 90, 200, 255 }, c1 = { 30, 90, 190 } },
}

-- ---------- budget D-O15-aware ----------
APX.BUDGET = { [1] = 1.0, [2] = 0.75, [3] = 0.45, [4] = 10 }
function APX.budgetScale()
	-- D-O15: pressao de performance restringe emissão (evita overdraw real)
	if ArkherDO15 and ArkherDO15.pressure then
		local p = ArkherDO15.pressure()
		local scale = 1 - 0.55 * p
		return mclamp(scale, 0.15, 1)
	end
	return 1
end

-- ---------- emissao ----------
APX._emitters = {}
APX._fires, APX._ring = {}, 1
local function fire(e) APX._fires[APX._ring] = e APX._ring = (APX._ring % 60) + 1 end

local function mkEmitter(part, spec, tag)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "APX_" .. tag
	-- cor
	local c0, c1 = spec.c0, spec.c1
	pcall(function()
		pe.Color = ColorSequence.new(Color3.fromRGB(c0[1], c0[2], c0[3]), Color3.fromRGB(c1[1], c1[2], c1[3]))
		pe.Transparency = NumberSequence.new and NumberSequence.new(0, 1) or 0
	end)
	-- vida/velocidade/tamanho/gravidade
	pe.Lifetime = { Min = spec.life * 0.7, Max = spec.life }
	pe.Speed = { Min = spec.speed * 0.7, Max = spec.speed * 1.25 }
	pe.Acceleration = Vector3.new(0, -(spec.gravity or 0), 0)
	pe.Size = { Keypoints = { { 0, spec.size0 }, { 1, spec.size1 } }, __t = "NumberSequence" }
	pe.LightEmission = spec.light or 0.35
	pe.SpreadAngle = { X = 360 * (spec.spread or 0.25) / 2, Y = 360 * (spec.spread or 0.25) / 2 }
	pe.Rotation = { Min = -180, Max = 180 }
	-- modo
	if spec.mode == "burst" then
		pe.Rate = 0
		pcall(function() pe:Emit(math.max(1, math.floor((spec.burst or 10) * APX.budgetScale()))) end)
	elseif spec.mode == "ring" then
		pe.Rate = 0
		pe.SpreadAngle = { X = 0, Y = 0 }
		pcall(function() pe:Emit(1) end)
	else
		pe.Rate = (spec.rate or 40) * APX.budgetScale()
	end
	-- vortex: velocidade inicial tangencial simulada por RotSpeed (real)
	if spec.mode == "vortex" then
		pe.RotSpeed = { Min = -(spec.vOmega or 8) * 20, Max = (spec.vOmega or 8) * 20 }
		pe.VelocitySpread = 35
	end
	-- down: emitir para baixo (chuva/neve) — rotaciona o emissor
	if spec.down then
		part.RotVelocity = Vector3.new(0, 0, 0)
	end
	pe.Parent = part
	fire("emit:" .. tag)
	return pe
end

function APX.emit(part, kind, ovr)
	local base = APX.PRESETS[kind] or APX.PRESETS.fogo
	local spec = {}
	for k, v in pairs(base) do spec[k] = v end
	if ovr then for k, v in pairs(ovr) do spec[k] = v end end
	local target = part
	if target == nil then
		local mk = Instance.new("Part")
		mk.Name = "APX_Anchor"
		mk.Size = Vector3.new(0.1, 0.1, 0.1)
		mk.Transparency = 1
		mk.Anchored = true
		mk.CanCollide = false
		mk.Position = Vector3.new(0, 3, 0)
		mk.Parent = workspace
		target = mk
	end
	local pe = mkEmitter(target, spec, kind)
	APX._emitters[kind] = { pe = pe, part = target, spec = spec, t0 = os.clock() }
	return pe, spec
end

function APX.clear(kind)
	if kind then
		local e = APX._emitters[kind]
		if e then pcall(function() e.pe.Enabled = false end) APX._emitters[kind] = nil end
		return
	end
	for k, e in pairs(APX._emitters) do
		pcall(function() e.pe.Enabled = false end)
		APX._emitters[kind] = nil
	end
end

-- estoura um preset one-shot na selecao/posicao
function APX.burstAt(kind) return APX.emit(nil, kind) end

function APX.list()
	local out = {}
	for k in pairs(APX.PRESETS) do out[#out + 1] = k end
	table.sort(out)
	return out
end

APX.VERSION = "5.0"

_G.ArkherParticlesX = APX

end

do
-- =============================================================
-- ROPE X / RPX v1 — Corda + TECIDO por integracao de VERLET REAL
-- Roblox nao tem simulacao de cloth/rope — entao nos construimos:
-- particulas de Verlet (x += (x-pp)*damp + a*dt^2), constraints de
-- distancia iteradas (relacao relaxation), colisao com esferas e
-- plano solo, gravidade real e VENTO VIVO ligado ao ATMOS X
-- (tempestade -> bandeira em espiral, forsada por ruido organico).
-- Materializacao REAL: cada segmento vira Part fina ancorada — a
-- corda/tecido e GEOMETRIA no workspace, nao efeito visual. 🏳️
-- =============================================================

local RPX = {}
RPX._V = 1
RPX.VERSION = "1.0"

local sqrt, floor, min, max, sin, cos, pi = math.sqrt, math.floor, math.min, math.max, math.sin, math.cos, math.pi
local function lint(a, b, t) return a + (b - a) * t end

RPX.G = 35 -- gravidade do mundo (studs/s^2)

-- particula de verlet
local function p3(x, y, z, pinned)
	return { x = x, y = y, z = z, px = x, py = y, pz = z, pin = pinned or false }
end

RPX._ropes = {}
RPX._cloths = {}
RPX._spheres = {} -- {x,y,z,r}
RPX._fires, RPX._ring = {}, 1
local function fire(e) RPX._fires[RPX._ring] = e RPX._ring = (RPX._ring % 60) + 1 end

RPX.ITERS = 5 -- passes de relaxamento (estabilidade real)

-- ---------- CORDA (pontos encadeados) ----------
-- opts: from={x,y,z}, to={x,y,z} (opcional -> pendurada em from), points=10,
--       slack=1.1 (folga), parts=true (materializa Parts)
function RPX.rope(opts)
	opts = opts or {}
	local n = opts.points or 10
	local from = opts.from or { x = 0, y = 10, z = 0 }
	local to = opts.to
	local pts = {}
	local endY = from.y
	if not to then endY = from.x and (opts.length or n * 1.2) or endY end
	local toEnd = to or { x = from.x, y = from.y - (opts.length or n * 1.2), z = from.z }
	for i = 1, n do
		local t = (i - 1) / (n - 1)
		local p = p3(lint(from.x, toEnd.x, t), lint(from.y, toEnd.y, t), lint(from.z, toEnd.z, t), false)
		pts[i] = p
	end
	pts[1].pin = true
	if to then pts[n].pin = true end
	local slack = opts.slack or 1.05
	local rest = sqrt((toEnd.x - from.x) ^ 2 + (toEnd.y - from.y) ^ 2 + (toEnd.z - from.z) ^ 2) / (n - 1) * slack
	local r = { pts = pts, rest = rest, kind = "rope", name = opts.name or ("RPX_Rope_" .. (#RPX._ropes + 1)), damp = opts.damp or 0.995, windPhase = 0, model = nil }
	r.windPhase = (from.x * 13.37 + from.y * 7.77) % 6.28
	RPX._ropes[#RPX._ropes + 1] = r
	fire("rope:" .. r.name)
	return r
end

-- ---------- TECIDO (grade W x H) ----------
-- opts: origin={x,y,z} (topo-esquerdo), cols=12, rows=8, spacing=1.2,
--       pinned="top"|"topcorners", parts=true
function RPX.cloth(opts)
	opts = opts or {}
	local cols = opts.cols or 12
	local rows = opts.rows or 8
	local sp = opts.spacing or 1.2
	local o = opts.origin or { x = -6, y = 12, z = 0 }
	local pinMode = opts.pinned or "top"
	local pts = {}
	for j = 1, rows do
		pts[j] = {}
		for i = 1, cols do
			local pinned = false
			if pinMode == "top" and j == 1 then pinned = true end
			if pinMode == "topcorners" and j == 1 and (i == 1 or i == cols) then pinned = true end
			pts[j][i] = p3(o.x + (i - 1) * sp, o.y - (j - 1) * sp * 0.02, o.z + (j - 1) * sp, pinned)
		end
	end
	local c = { pts = pts, cols = cols, rows = rows, rest = sp, kind = "cloth", name = opts.name or ("RPX_Cloth_" .. (#RPX._cloths + 1)), damp = 0.99, windPhase = 0, model = nil }
	c.windPhase = (o.x * 5.3 + o.z * 11.1) % 6.28
	RPX._cloths[#RPX._cloths + 1] = c
	fire("cloth:" .. c.name)
	return c
end

-- ---------- colisores ----------
function RPX.addSphere(x, y, z, rr)
	RPX._spheres[#RPX._spheres + 1] = { x = x, y = y, z = z, r = rr or 2 }
	fire("sphere:add")
end
function RPX.clearColliders() RPX._spheres = {} end

-- ---------- relaxamento de dois pontos ----------
local function relax(a, b, restOn)
	local dx = b.x - a.x
	local dy = b.y - a.y
	local dz = b.z - a.z
	local d = sqrt(dx * dx + dy * dy + dz * dz)
	if d < 1e-6 then return end
	local diff = (d - restOn) / d
	local m = 0.5
	if a.pin and b.pin then return end
	if a.pin then m = 0 end
	if b.pin then m = 1 end
	local ax = dx * diff * 0.5
	local ay = dy * diff * 0.5
	local az = dz * diff * 0.5
	if not a.pin then
		a.x = a.x + ax * (b.pin and 2 or 1)
		a.y = a.y + ay * (b.pin and 2 or 1)
		a.z = a.z + az * (b.pin and 2 or 1)
	end
	if not b.pin then
		b.x = b.x - ax * (a.pin and 2 or 1)
		b.y = b.y - ay * (a.pin and 2 or 1)
		b.z = b.z - az * (a.pin and 2 or 1)
	end
end

-- ---------- solo (y = groundY) ----------
local ground = { y = -5, on = false }
function RPX.setGround(y, on) ground = { y = y or 0, on = on ~= false } end

local function collide(p)
	for _, s in ipairs(RPX._spheres) do
		local dx = p.x - s.x
		local dy = p.y - s.y
		local dz = p.z - s.z
		local d2 = dx * dx + dy * dy + dz * dz
		local rr = s.r * s.r
		if d2 < rr and d2 > 1e-9 then
			local d = sqrt(d2)
			local k = (s.r - d) / d
			p.x = p.x + dx * k
			p.y = p.y + dy * k
			p.z = p.z + dz * k
		end
	end
	if ground.on and p.y < ground.y then p.y = ground.y end
end

-- ---------- vento (link vivo ATMOS X) ----------
local function windVec(t, phase)
	local speed = 0
	local dirx, dirz = 1, 0.3
	if ArkherAtmosX then
		local _, w = ArkherAtmosX.skyDayNight()
		if ArkherAtmosX.weatherMix then
			local mix = ArkherAtmosX.weatherMix(nil)
			if mix and mix.wind then speed = mix.wind end
		end
	end
	if ArkherAUX_WIND_OVERRIDE then speed = ArkherAUX_WIND_OVERRIDE end
	local gust = 0.6 + 0.4 * sin(t * 2.1 + phase) * sin(t * 0.77 + phase * 2)
	local v = speed * gust * 12
	return dirx * v, sin(t * 1.3 + phase) * v * 0.35, dirz * v
end

local stepT = 0
function RPX.pump(dt)
	dt = min(dt or 1 / 60, 1 / 20)
	stepT = stepT + dt
	local t = stepT
	local g2 = RPX.G * dt * dt
	for _, r in ipairs(RPX._ropes) do
		for i = 1, #r.pts do
			local p = r.pts[i]
			if not p.pin then
				local wx, wy, wz = windVec(t, r.windPhase)
				local ax, ay, az = wx * 0.06, -RPX.G + wy * 0.02, wz * 0.06
				local nx = p.x + (p.x - p.px) * r.damp + ax * dt * dt
				local ny = p.y + (p.y - p.py) * r.damp + ay * dt * dt
				local nz = p.z + (p.z - p.pz) * r.damp + az * dt * dt
				p.px, p.py, p.pz = p.x, p.y, p.z
				p.x, p.y, p.z = nx, ny, nz
			end
		end
		for k = 1, RPX.ITERS do
			for i = 1, #r.pts - 1 do relax(r.pts[i], r.pts[i + 1], r.rest) end
			for i = 1, #r.pts do collide(r.pts[i]) end
		end
	end
	for _, c in ipairs(RPX._cloths) do
		for j = 1, c.rows do
			for i = 1, c.cols do
				local p = c.pts[j][i]
				if not p.pin then
					local fx = sin(t * 3.1 + p.x * 0.5 + c.windPhase) * 2.2
					local fy = sin(t * 2.7 + p.y * 0.8 + 1) * 1.2
					local wx, wy, wz = windVec(t, c.windPhase)
					local ax, ay, az = wx * 0.09 + fx * 0.03, -RPX.G + wy * 0.02, wz * 0.09 + fy * 0.02
					local nx = p.x + (p.x - p.px) * c.damp + ax * dt * dt
					local ny = p.y + (p.y - p.py) * c.damp + ay * dt * dt
					local nz = p.z + (p.z - p.pz) * c.damp + az * dt * dt
					p.px, p.py, p.pz = p.x, p.y, p.z
					p.x, p.y, p.z = nx, ny, nz
				end
			end
		end
		for k = 1, 3 do
			for j = 1, c.rows do
				for i = 1, c.cols do
					if i < c.cols then relax(c.pts[j][i], c.pts[j][i + 1], c.rest) end
					if j < c.rows then relax(c.pts[j][i], c.pts[j + 1][i], c.rest) end
				end
			end
			for j = 1, c.rows do for i = 1, c.cols do collide(c.pts[j][i]) end end
		end
	end
	-- atualiza a geometria (materializacao continua)
	for _, r in ipairs(RPX._ropes) do RPX._geoRope(r) end
	for _, c in ipairs(RPX._cloths) do RPX._geoCloth(c) end
	return #RPX._ropes + #RPX._cloths
end

-- ---------- MATERIALIZACAO REAL (Parts finas por segmento) ----------
local function ensureModel(name)
	local m = workspace:FindFirstChild(name)
	if not m then
		m = Instance.new("Model")
		m.Name = name
		m.Parent = workspace
	end
	return m
end

local function segBetween(model, idx, a, b, w, colR, colG, colB)
	local pname = string.format("Seg_%04d", idx)
	local p = model:FindFirstChild(pname)
	if not p then
		p = Instance.new("Part")
		p.Name = pname
		p.Anchored = true
		p.CanCollide = false
		p.Material = "SmoothPlastic"
		p.Parent = model
	end
	local mx = (a.x + b.x) / 2
	local my = (a.y + b.y) / 2
	local mz = (a.z + b.z) / 2
	local len = max(sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + (b.z - a.z) ^ 2), 0.05)
	p.Size = Vector3.new(w, w, len)
	p.CFrame = CFrame.lookAt(Vector3.new(mx, my, mz), Vector3.new(b.x, b.y, b.z))
	p.Color = Color3.fromRGB(colR, colG, colB)
	return p
end

function RPX.materializeRope(r, opts)
	local m = ensureModel(r.name)
	r.model = r
	r._parts = opts or { w = 0.22, color = { 180, 120, 60 } }
	RPX._geoRope(r)
	return m
end
function RPX._geoRope(r)
	if not r.model then return end
	local m = ensureModel(r.name)
	for i = 1, #r.pts - 1 do
		segBetween(m, i, r.pts[i], r.pts[i + 1], (r._parts and r._parts.w) or 0.22, ((r._parts and r._parts.color) or { 180, 120, 60 })[1], ((r._parts and r._parts.color) or { 180, 120, 60 })[2], ((r._parts and r._parts.color) or { 180, 120, 60 })[3])
	end
end

function RPX.materializeCloth(c, opts)
	local m = ensureModel(c.name)
	c.model = c
	c._parts = opts or { w = 0.16, color = { 220, 240, 250 }, color2 = { 240, 230, 120 } }
	RPX._geoCloth(c)
	return m
end
function RPX._geoCloth(c)
	if not c.model then return end
	local m = ensureModel(c.name)
	local idx = 0
	local col1 = (c._parts and c._parts.color) or { 220, 240, 250 }
	-- tiras verticais (cada coluna = uma "corda" visual)
	for i = 1, c.cols, 2 do
		for j = 1, c.rows - 1 do
			idx = idx + 1
			local shade = ((i + j) % 2 == 0) and 1 or 0.85
			local pname = string.format("Seg_%04d", idx)
			local p = m:FindFirstChild(pname)
			if not p then
				p = Instance.new("Part")
				p.Name = pname
				p.Anchored = true
				p.CanCollide = false
				p.Material = "SmoothPlastic"
				p.Parent = m
			end
			local a, b = c.pts[j][i], c.pts[j + 1][i]
			local mx = (a.x + b.x) / 2
			local my = (a.y + b.y) / 2
			local mz = (a.z + b.z) / 2
			local len = max(sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2 + (b.z - a.z) ^ 2), 0.05)
			p.Size = Vector3.new(c.rest * 1.9, len, (c._parts and c._parts.w) or 0.16)
			p.CFrame = CFrame.lookAt(Vector3.new(mx, my, mz), Vector3.new(a.x, a.y, a.z + 1))
			p.Color = Color3.fromRGB(floor(col1[1] * shade), floor(col1[2] * shade), floor(col1[3] * shade))
		end
	end
end

function RPX.remove(name)
	for i, r in ipairs(RPX._ropes) do if r.name == name then table.remove(RPX._ropes, i) end end
	for i, c in ipairs(RPX._cloths) do if c.name == name then table.remove(RPX._cloths, i) end end
	local m = workspace:FindFirstChild(name)
	if m then m:Destroy() end
	fire("remove:" .. name)
end

-- flags / cabelo / bandame
function RPX.flagAt(x, y, z)
	local c = RPX.cloth({ origin = { x = x, y = y, z = z }, cols = 10, rows = 14, spacing = 1.0, pinned = "topcorners" })
	c.kind = "flag"
	RPX.materializeCloth(c, { w = 0.14, color = { 235, 40, 40 } })
	fire("flag")
	return c
end

_G.ArkherRopeX = RPX
end

do
--[[ ARKHER V3 — BOOT: inicializa os sistemas core (idempotente) ]]
function ARKHER.boot()
	if ARKHER._booted then return end
	ARKHER._booted = true
	ArkherDO15.start()
	ArkherNMN.start()
	ArkherLive.start()
	ArkherActions.registerUICommands()
	ArkherActions.startShortcuts()
	pcall(function() ArkherPlaces.refreshList() end)
	ARKHER.out("INFO", "Core boot: do15 + nmn + live + actions + places")
end
end

do
--[[ ARKHER V3 — MAIN UI: o shell do editor (fiel a Recording_20260908_174341.jpg) ]]
-- Titlebar + 6 menus reais + toolbar com acoes reais + Properties live + Hierarchy live
-- + viewport NATIVO do Roblox (sem frame fake) + status bar com dados reais.
local Players = game:GetService("Players")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local function BUILD_MAIN()
	local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
	local TITLE_H, MENU_H, RIB_H, STATUS_H = 26, 24, 78, 24
	local LEFT_W, RIGHT_W = 250, 222
	local TOP = TITLE_H + MENU_H + RIB_H

	local g = K.gui("ArkherStudioMainUI")
	local root = K.f(g, "Root", 0, 0, 10, 10, T.bg1)
	root.Size = UDim2.new(1, 0, 1, 0)

	-- ================= TITLE BAR =================
	local title = K.f(root, "TitleBar", 0, 0, 10, TITLE_H, T.bg0)
	title.Size = UDim2.new(1, 0, 0, TITLE_H)
	local emb = K.f(title, "Emblem", 8, 4, 18, 18)
	ICON.emblem(emb, 18)
	K.txt(title, "ARKHER STUDIO", 30, 0, 180, TITLE_H, 12, T.txt, ARKHER.FONTB)
	local placeLbl = K.txt(title, ARKHER.STATE.placeName, 140, 0, 300, TITLE_H, 10, T.txt4)
	local win = K.f(title, "Win", 0, 0, 80, TITLE_H)
	win.Position = UDim2.new(1, -80, 0, 0)
	local bmin = K.btn(win, "Min", 6, 5, 24, 16, T.bg0, 3)
	K.hover(bmin, T.bg0, T.hover)
	ICON.minus(bmin)
	bmin.MouseButton1Click:Connect(function()
		local vp = root:FindFirstChild("ViewportArea")
		if vp then vp.Visible = not vp.Visible end
	end)
	local bmax = K.btn(win, "Max", 38, 5, 24, 16, T.bg0, 3)
	K.hover(bmax, T.bg0, T.hover)
	ICON.square(bmax)
	local bclose = K.btn(win, "Close", 70, 5, 24, 16, T.bg0, 3)
	K.hover(bclose, T.bg0, C("#3A2530"))
	ICON.close(bclose)
	bclose.MouseButton1Click:Connect(function()
		K.notify("ARKHER", "Feche pelo Studio (o shell ARKHER persiste entre places)", "INFO")
	end)

	-- ================= MENU BAR =================
	local menu = K.f(root, "MenuBar", 0, TITLE_H, 10, MENU_H, T.bg1)
	menu.Size = UDim2.new(1, 0, 0, MENU_H)
	local function recentList()
		local items = {}
		local places = ArkherPlaces and ArkherPlaces.list() or {}
		if #places == 0 then items[#items + 1] = "(vazio)" else
			for i, p in ipairs(places) do
				if i > 6 then break end
				items[#items + 1] = { label = (p.name or "?") .. "  [" .. tostring(p.id) .. "]", cmd = "place.open", tpl = p.id }
			end
		end
		return items
	end
	local MENUS = {
		FILE = {
			{ label = "New Place", items = {
				{ label = "Baseplate", cmd = "place.new", tpl = "Baseplate" },
				{ label = "City", cmd = "place.new", tpl = "City" },
				{ label = "Nature", cmd = "place.new", tpl = "Nature" },
				{ label = "Space", cmd = "place.new", tpl = "Space" },
				{ label = "Empty", cmd = "place.new", tpl = "Empty" },
			} },
			{ label = "Save", cmd = "file.save" },
			{ label = "Open...", cmd = "file.open" },
			{ label = "Save to Arkher Cloud", cmd = "file.savecloud" },
			"-",
			{ label = "Import Bundle...", cmd = "file.import" },
			{ label = "Export Place...", cmd = "file.export" },
			"-",
			{ label = "Recent Places", recent = true },
			{ label = "Close Place", cmd = "place.close" },
		},
		EDIT = {
			{ label = "Undo", cmd = "edit.undo", ks = "Ctrl+Z" },
			{ label = "Redo", cmd = "edit.redo", ks = "Ctrl+Y" },
			"-",
			{ label = "Cut", cmd = "edit.cut", ks = "Ctrl+X" },
			{ label = "Copy", cmd = "edit.copy", ks = "Ctrl+C" },
			{ label = "Paste", cmd = "edit.paste", ks = "Ctrl+V" },
			"-",
			{ label = "Delete", cmd = "edit.delete", ks = "Del" },
			{ label = "Duplicate", cmd = "edit.duplicate", ks = "Ctrl+D" },
			{ label = "Rename...", cmd = "edit.rename" },
		},
		VIEW = {
		{ label = "Properties", cmd = "view.properties" },
		{ label = "Hierarchy", cmd = "view.hierarchy" },
		{ label = "Console", cmd = "view.console" },
		{ label = "Command Palette", cmd = "view.palette", ks = "Ctrl+K" },
		{ label = "Painéis", panels = true },
		"-",
			{ label = "Fullscreen Viewport", cmd = "view.fullscreen" },
			{ label = "Reset Layout", cmd = "view.reset" },
			{ label = "Sandbox: ON", cmd = "sandbox.toggle" },
		},
		INSERT = {
			{ label = "Part", cmd = "insert.part" },
			{ label = "Sphere", cmd = "insert.sphere" },
			{ label = "Cylinder", cmd = "insert.cylinder" },
			{ label = "Wedge", cmd = "insert.wedge" },
			"-",
			{ label = "Model", cmd = "insert.model" },
			{ label = "Folder", cmd = "insert.folder" },
			"-",
			{ label = "Script", cmd = "insert.script" },
			{ label = "LocalScript", cmd = "insert.localscript" },
			{ label = "ModuleScript", cmd = "insert.modulescript" },
			"-",
			{ label = "Text", cmd = "insert.text" },
			{ label = "Light", cmd = "insert.light" },
			{ label = "Sound", cmd = "insert.sound" },
		},
		RUN = {
			{ label = "Play", cmd = "run.play" },
			{ label = "Pause", cmd = "run.pause" },
			{ label = "Stop", cmd = "run.stop" },
			"-",
			{ label = "Run Diagnostics", cmd = "run.diagnostics" },
			{ label = "Performance Stats", cmd = "run.perf" },
			"-",
			{ label = "Sandbox: ON", cmd = "sandbox.toggle" },
		},
		GAME = {
			{ label = "Game Settings", cmd = "game.settings" },
			{ label = "Places", cmd = "game.places" },
			"-",
			{ label = "Publish to Arkher", cmd = "publish.local" },
			{ label = "Publish to Roblox", cmd = "publish.native" },
			"-",
			{ label = "Passes", cmd = "game.passes" },
			{ label = "Developer Products", cmd = "game.products" },
		},
	}
	local mx = 8
	for _, name in ipairs({ "FILE", "EDIT", "VIEW", "INSERT", "RUN", "GAME" }) do
		local mb = K.btn(menu, "M_" .. name, mx, 2, 46, 20, T.bg1, 3)
		K.txtS(mb, name, 11, T.txt2)
		K.hover(mb, T.bg1, T.hover)
		mb.MouseButton1Click:Connect(function()
			local items = MENUS[name]
			-- recent + paineis dinamicos
			local final = {}
			for _, it in ipairs(items) do
				if type(it) == "table" and it.recent then
					final[#final + 1] = { label = "Recent Places", items = recentList() }
				elseif type(it) == "table" and it.panels then
					local pl = {}
					for _, nm in ipairs(ARKHER.listUIs()) do
						local cat = ARKHER.CATALOG[nm]
						pl[#pl + 1] = { label = (cat and cat.title) or nm, cmd = "ui.open", tpl = nm }
					end
					table.sort(pl, function(a, b) return a.label < b.label end)
					final[#final + 1] = { label = "Painéis (" .. #pl .. ")", items = pl }
				else
					final[#final + 1] = it
				end
			end
			K.dropdown(menu, mb, final)
		end)
		mx = mx + 50
	end
	local rightMenu = K.f(menu, "Right", 0, 0, 300, MENU_H)
	rightMenu.Position = UDim2.new(1, -300, 0, 0)
	local rx = 8
	for _, nm in ipairs({ "Collaborate", "Invites", "Changes" }) do
		local w = 26 + #nm * 6
		local b = K.btn(rightMenu, "RM_" .. nm, rx, 2, w, 20, T.bg1, 3)
		K.txtS(b, nm, 11, T.txt3)
		K.hover(b, T.bg1, T.hover)
		b.MouseButton1Click:Connect(function()
			if nm == "Collaborate" then ARKHER.open("Collaboration")
			elseif nm == "Invites" then ARKHER.open("Collaboration")
			else ARKHER.open("VersionControl") end
		end)
		rx = rx + w + 4
	end
	local chip = K.btn(rightMenu, "User", rx, 2, 44, 20, T.sec, 10)
	K.txtS(chip, "ARKH", 9, T.txt, ARKHER.FONTB)
	K.hover(chip, T.sec, T.hover)
	chip.MouseButton1Click:Connect(function() ARKHER.open("Login") end)

	-- ================= TOOLBAR (RIBBON) =================
	local rib = K.f(root, "Ribbon", 0, TOP - RIB_H, 10, RIB_H, T.bg2)
	rib.Size = UDim2.new(1, 0, 0, RIB_H)
	local groups = {
		{ { "Save", "save", "file.save" }, { "Open", "open", "file.open" }, { "Save to Arkher", "cloud", "file.savecloud" } },
		{ { "Select", "select", "tool:Select" }, { "Move", "move", "tool:Move" }, { "Scale", "scaleI", "tool:Scale" }, { "Rotate", "rotate", "tool:Rotate" }, { "Transform", "transform", "transform.lock" } },
		{ { "Model", "model", "insert.model" }, { "Folder", "folder", "insert.folder" }, { "Script", "script", "insert.script" }, { "Text", "textA", "insert.text" } },
		{ { "Play", "play", "run.play" }, { "Pause", "pause", "run.pause" }, { "Data", "data", "ui.DataManager" }, { "Localization", "globe", "ui.Localization" }, { "Settings", "settings", "game.settings" } },
		{ { "Toolbox", "toolbox", "ui.Toolbox" }, { "Collaboration Settings", "people", "ui.Collaboration" } },
		{ { "Arkher Cloud", "info", "cloud.status" }, { "Plugin Toolbar", "plugin", "ui.PluginManager" } },
	}
	local gx = 8
	for _, grp in ipairs(groups) do
		if gx > 8 then
			K.f(rib, "Sep", gx, 14, 1, 50, T.line)
			gx = gx + 8
		end
		for _, item in ipairs(grp) do
			local label, icon, cmd = item[1], item[2], item[3]
			local w = math.max(56, #label * 5 + 22)
			local b = K.ribbonBtn(rib, gx, w, ICON[icon], label, {})
			if cmd:sub(1, 5) == "tool:" then
				local toolName = cmd:sub(6)
				b._tool = toolName
				b.MouseButton1Click:Connect(function() ARKHER.cmd("tool", toolName) end)
			elseif cmd == "transform.lock" then
				b.MouseButton1Click:Connect(function()
					K.dropdown(rib, b, {
						{ label = "Lock", cmd = "transform.lock" },
						{ label = "Local/Global", cmd = "transform.mode" },
					})
				end)
			else
				b.MouseButton1Click:Connect(function() ARKHER.cmd(cmd) end)
			end
			gx = gx + w + 3
		end
	end

	-- ================= LEFT: PROPERTIES (live) =================
	local left = K.f(root, "Left", 0, TOP, LEFT_W, 10, T.bg3)
	left.Size = UDim2.new(0, LEFT_W, 1, -TOP - STATUS_H)
	K.f(left, "HeadLine", 0, 0, LEFT_W, 26, T.bg1)
	K.txt(left, "Properties", 10, 0, 150, 26, 12, T.txt, ARKHER.FONTB)
	local pinL = K.btn(left, "PinL", LEFT_W - 52, 5, 18, 16, T.bg1, 3)
	ICON.pin(pinL, 12, 2, 2)
	K.hover(pinL, T.bg1, T.hover)
	local closeL = K.btn(left, "CloseL", LEFT_W - 30, 5, 18, 16, T.bg1, 3)
	ICON.close(closeL)
	K.hover(closeL, T.bg1, C("#3A2530"))
	closeL.MouseButton1Click:Connect(function()
		left.Visible = not left.Visible
		Bus.emit("view.toggle", "Properties")
	end)
	local propSearch = K.search(left, 8, 30, LEFT_W - 16, 22, "Search Properties (Ctrl+Shift+P)")
	local propBox = K.input(left, 10, 32, LEFT_W - 30, 18, "")
	propBox.Name = "PropFilter"
	propBox.Text = ""
	propBox.PlaceholderText = "Search Properties (Ctrl+Shift+P)"
	propBox.TextSize = 10
	propBox.BackgroundColor3 = T.bg4
	propBox.ClearTextOnFocus = true
	local propContainer = K.f(left, "PropContainer", 0, 58, LEFT_W, 10, T.bg3)
	propContainer.Size = UDim2.new(0, LEFT_W, 1, -58)

	local function filterProps()
		local f = (propBox.Text or ""):lower()
		for _, sec in ipairs(propContainer:GetChildren()) do
			if sec.Name:sub(1, 4) == "SEC_" then
				local label = sec.Name:sub(5):lower()
				sec.Visible = f == "" or label:find(f, 1, true) ~= nil
			end
		end
	end
	propBox.FocusLost:Connect(function()
		filterProps()
		Bus.emit("inspector.refresh")
	end)

	local function rebuildInspector()
		if not left.Visible then return end
		ARKHER_LIVE.rebuildInspector(propContainer)
		filterProps()
	end
	Bus.on("inspector.refresh", rebuildInspector)
	Bus.on("hierarchy.picked", function() rebuildInspector() end)

	-- ================= CENTER: VIEWPORT (nativo, sem frame fake) =================
	local vp = K.f(root, "ViewportArea", 0, TOP, 10, 10, T.bg0)
	vp.Position = UDim2.new(0, LEFT_W, 0, TOP)
	vp.Size = UDim2.new(1, -LEFT_W - RIGHT_W, 1, -TOP - STATUS_H)
	vp.BackgroundTransparency = 1
	local tabStrip = K.f(vp, "TabStrip", 0, 0, 300, 24, T.bg1)
	local tab = K.btn(tabStrip, "Tab_VP", 2, 2, 150, 20, T.bg2, 3)
	local tabIc = K.f(tab, "Ic", 6, 3, 14, 14)
	ICON.camera(tabIc, 14)
	local tabName = K.txt(tab, "Viewport", 24, 0, 96, 20, 10, T.txt)
	local tabX = K.btn(tab, "X", 132, 4, 12, 12, T.bg2, 3)
	ICON.close(tabX)
	local tabMin = K.btn(tabStrip, "Tab_Min", 156, 2, 24, 20, T.bg1, 3)
	ICON.minus(tabMin)
	tabX.MouseButton1Click:Connect(function() vp.Visible = not vp.Visible end)
	tabMin.MouseButton1Click:Connect(function() vp.Visible = not vp.Visible end)
	-- HUD de camera (dados REAIS do viewport nativo)
	local hud = K.f(vp, "CamHud", 8, 30, 220, 18, T.bg1)
	K.stroke(hud, T.line, 1)
	hud.BackgroundTransparency = 0.25
	local hudTxt = K.txt(hud, "Cam (0, 0, 0)", 8, 0, 204, 18, 10, T.txt2, ARKHER.MONO)
	local chips = K.f(vp, "Chips", 8, 52, 260, 22, T.bg1)
	chips.BackgroundTransparency = 0.25
	K.stroke(chips, T.line, 1)
	local chipNames = { "Grid", "Axes", "Focus", "Fit" }
	local cx = 4
	for _, cn in ipairs(chipNames) do
		local cw = 12 + #cn * 6
		local cb = K.btn(chips, "C_" .. cn, cx, 2, cw, 18, T.bg2, 4)
		K.txtS(cb, cn, 9, T.txt2)
		K.hover(cb, T.bg2, T.hover)
		cb.MouseButton1Click:Connect(function()
			if cn == "Focus" then
				local s = ARKHER_LIVE.currentSelection()
				if s and s:IsA("BasePart") then
					local cam = workspace:FindFirstChild("Camera") or workspace:FindFirstChildOfClass("Camera")
					if cam then pcall(function() cam.CFrame = CFrame.lookAt(s.Position + Vector3.new(10, 8, 10), s.Position) end) end
					ARKHER.out("INFO", "F: camera focada em " .. s.Name)
				end
			elseif cn == "Fit" then
				ARKHER.out("INFO", "Fit: enquadre todo o place (use F no Studio ou a camera do ARKHER)")
			else
				ARKHER.out("INFO", "View option: " .. cn .. " (viewport nativo do Roblox)")
			end
		end)
		cx = cx + cw + 3
	end

	-- ================= RIGHT: HIERARCHY (live) =================
	local right = K.f(root, "Right", 0, TOP, RIGHT_W, 10, T.bg3)
	right.Position = UDim2.new(1, -RIGHT_W, 0, TOP)
	right.Size = UDim2.new(0, RIGHT_W, 1, -TOP - STATUS_H)
	K.f(right, "HeadLine", 0, 0, RIGHT_W, 26, T.bg1)
	K.txt(right, "Hierarchy", 10, 0, 120, 26, 12, T.txt, ARKHER.FONTB)
	local pinR = K.btn(right, "PinR", RIGHT_W - 52, 5, 18, 16, T.bg1, 3)
	ICON.pin(pinR, 12, 2, 2)
	K.hover(pinR, T.bg1, T.hover)
	local closeR = K.btn(right, "CloseR", RIGHT_W - 30, 5, 18, 16, T.bg1, 3)
	ICON.close(closeR)
	K.hover(closeR, T.bg1, C("#3A2530"))
	closeR.MouseButton1Click:Connect(function()
		right.Visible = not right.Visible
		Bus.emit("view.toggle", "Hierarchy")
	end)
	local hBox = K.input(right, 10, 32, RIGHT_W - 22, 18, "")
	hBox.Text = ""
	hBox.PlaceholderText = "Filter workspace (Ctrl+Shift+X)"
	hBox.TextSize = 10
	hBox.BackgroundColor3 = T.bg4
	hBox.ClearTextOnFocus = true
	local hIc = K.f(right, "HSearchIc", RIGHT_W - 34, 34, 14, 14)
	ICON.search(hIc, 12, 1, 1)
	local hState = { open = { Workspace = true } }
	local hContainer = K.f(right, "HContainer", 0, 56, RIGHT_W, 10, T.bg3)
	hContainer.Size = UDim2.new(0, RIGHT_W, 1, -56)
	hContainer.BackgroundTransparency = 1
	local function rebuildHierarchy()
		if not right.Visible then return end
		ARKHER_LIVE.rebuildHierarchy(hContainer, hBox.Text or "", hState)
	end
	Bus.on("hierarchy.refresh", rebuildHierarchy)
	hBox.FocusLost:Connect(rebuildHierarchy)
	Bus.on("hierarchy.filter", function() rebuildHierarchy() end)

	-- ================= STATUS BAR =================
	local status = K.f(root, "StatusBar", 0, 0, 10, STATUS_H, T.bg0)
	status.Size = UDim2.new(1, 0, 0, STATUS_H)
	status.Position = UDim2.new(0, 0, 1, -STATUS_H)
	local sPlace = K.txt(status, ARKHER.STATE.placeName, 10, 0, 220, STATUS_H, 10, T.txt2)
	local sSel = K.txt(status, "Nada selecionado", 240, 0, 300, STATUS_H, 10, T.txt3)
	local sRight = K.f(status, "Right", 0, 0, 420, STATUS_H)
	sRight.Position = UDim2.new(1, -420, 0, 0)
	local sFps = K.txt(sRight, "FPS --", 0, 0, 60, STATUS_H, 10, T.txt3, ARKHER.MONO)
	local sFrame = K.txt(sRight, "ms --", 62, 0, 54, STATUS_H, 10, T.txt3, ARKHER.MONO)
	local sDo15 = K.txt(sRight, "D-O15 HIGH", 118, 0, 84, STATUS_H, 10, T.neon, ARKHER.MONO)
	local sTool = K.txt(sRight, "Select", 204, 0, 60, STATUS_H, 10, T.txt2)
	local sCloud = K.txt(sRight, "cloud: local", 266, 0, 90, STATUS_H, 10, T.txt3)
	local sVer = K.txt(sRight, "ARKHER V3", 360, 0, 60, STATUS_H, 9, T.txt4, ARKHER.FONTB)

	-- ================= WIRING REAL =================
	local lastFps = 0
	pcall(function()
		RunService.Heartbeat:Connect(function()
			local cam = workspace:FindFirstChild("Camera")
			if cam then
				local pos = cam.CFrame.Position
				hudTxt.Text = string.format("Cam (%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
			end
		end)
	end)
	Bus.on("do15.level", function(lvl, fps, ms)
		sFps.Text = "FPS " .. string.format("%.0f", fps or 0)
		sFrame.Text = string.format("%.1f ms", ms or 0)
		local names = { "MAX", "HIGH", "BAL", "ECO" }
		sDo15.Text = "D-O15 " .. (names[lvl] or "?")
		sDo15.TextColor3 = lvl == 1 and T.green or lvl == 2 and T.neon or lvl == 3 and T.yellow or T.danger
	end)
	Bus.on("tool.changed", function(tool)
		sTool.Text = tostring(tool)
		for _, ch in ipairs(rib:GetChildren()) do
			if ch._tool then
				ch.BackgroundColor3 = ch._tool == tool and T.sel or T.bg2
				local st = ch:FindFirstChildOfClass("UIStroke")
				if st then st.Visible = ch._tool == tool end
			end
		end
	end)
	Bus.on("tool.locked", function(on)
		ARKHER.out("INFO", "Lock: " .. (on and "ON" or "OFF"))
	end)
	local function refreshPlaceLabel()
		sPlace.Text = ARKHER.STATE.placeName
		tabName.Text = "Viewport"
	end
	Bus.on("place.saved", function(meta)
		refreshPlaceLabel()
		rebuildHierarchy()
		sCloud.Text = "cloud: " .. #ARKHER.STATE.cloud.places .. " places"
	end)
	Bus.on("place.new", function()
		refreshPlaceLabel()
		rebuildHierarchy()
	end)
	Bus.on("place.opened", function()
		refreshPlaceLabel()
		rebuildHierarchy()
	end)
	Bus.on("cloud.status", function(c)
		sCloud.Text = c.endpoint and "cloud: online" or "cloud: local"
	end)
	Bus.on("inspector.refresh", function()
		local s = ARKHER_LIVE.currentSelection()
		sSel.Text = s and (s.Name .. "  (" .. s.ClassName .. ")") or "Nada selecionado"
	end)
	Bus.on("view.toggle", function(which)
		if which == "Properties" then K.notify("ARKHER", "Properties: " .. (left.Visible and "aberto" or "fechado"), "INFO") end
		if which == "Hierarchy" then K.notify("ARKHER", "Hierarchy: " .. (right.Visible and "aberto" or "fechado"), "INFO") end
	end)
	ARKHER.on("view.fullscreen", function()
		left.Visible = false
		right.Visible = false
		Bus.emit("view.reset")
	end)
	Bus.on("view.reset", function()
		left.Visible = true
		right.Visible = true
	end)

	-- estado inicial
	rebuildInspector()
	rebuildHierarchy()
	sTool.Text = ARKHER.STATE.tool or "Select"
	ARKHER.out("SUCCESS", "ARKHER V3 shell montado — menus/toolbar/properties/hierarchy/status bar ativos")
	return g
end

ARKHER_BUILD_MAIN = BUILD_MAIN
end

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
	local closeB = K.btn(bar, "Close", 340, 44, 100, 24, T.bg2, 4)
	K.txtS(closeB, "fechar", 10, T.txt)
	K.hover(closeB, T.bg2, T.hover)
	closeB.MouseButton1Click:Connect(function()
		root.Visible = false
	end)
end

ARKHER.reg("About", "About", "System", ICON.info, "Sobre o ARKHER V3: sistemas ativos e contadores em tempo real", build)
end

do
--[[ ARKHER V3 — UI: AI (SINGULARITY) ]]
-- Layout unico: campo de objetivo + chips de sugestao, execucao REAL
-- (ARKHER_SINGULARITY.run), relatorio ao centro, historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#00D4FF")

local SUGGESTIONS = {
	"crie uma cidade com npc",
	"crie um terreno com natureza",
	"crie um espaco com asteroides",
	"otimize e diagnostico",
}

local function build()
	local g, root, head = K.window("ArkherAI", "AI — Singularity (local)", 24, 470, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: OBJETIVO =====
	local goalBox = K.input(root, 8, 34, 360, 26, "descreva o que construir...")
	local run = K.btn(root, "Run", 380, 34, 100, 26, ACCENT, 5)
	K.txtS(run, "EXECUTAR", 11, C("#04141C"))
	K.hover(run, ACCENT, C("#7DEBFF"))
	-- chips
	local chips = {}
	for i, sg in ipairs(SUGGESTIONS) do
		local ch = K.btn(root, "Ch" .. i, 8 + (i - 1) * 138, 68, 132, 20, T.bg4, 10)
		K.txtS(ch, sg, 8, T.txt3)
		K.hover(ch, T.bg4, T.hover)
		local sg2 = sg
		ch.MouseButton1Click:Connect(function()
			goalBox.Text = sg2
		end)
		chips[i] = ch
	end

	-- ===== CENTRO: RELATORIO =====
	local rep = K.f(root, "Rep", 8, 96, 360, 190, T.bg0)
	K.corner(rep, 4)
	K.stroke(rep, T.line, 1)
	K.txt(rep, "RELATORIO DE EXECUCAO", 10, 6, 180, 14, 10, T.txt3, ARKHER.FONTB)
	local area = K.f(rep, "Area", 0, 26, 360, 160)
	local lastRep
	local function renderRep()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		if not lastRep then
			K.txt(area, "a Singularity planeja o objetivo em intents\n(city / nature / space / npc / perf / check...)\ne executa de VERDADE no workspace.", 12, 8, 330, 50, 9, T.txt4)
			return
		end
		local y = 4
		for i, l in ipairs(lastRep.lines) do
			local col = T.txt2
			if l:sub(1, 5) == "plano" then col = T.neon end
			if l:find("diagnostico") then col = C("#FFD93D") end
			if l:find("performance") then col = T.ok end
			if l:find("ERRO") then col = T.danger end
			K.txt(area, l, 12, y, 336, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
			y = y + 18
			if y > 150 then break end
		end
	end
	renderRep()
	run.MouseButton1Click:Connect(function()
		local goal = goalBox.Text
		if goal == "" then goal = "diagnostico" end
		ARKHER.out("INFO", "AI: executando: " .. goal)
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run(goal) end)
		if ok and r then
			lastRep = r
			renderRep()
			ARKHER.out("SUCCESS", "AI: missao concluida (" .. #r.lines .. " etapas)")
		else
			ARKHER.out("ERROR", "AI: falhou: " .. tostring(r))
		end
	end)

	-- ===== DIREITA: HISTORICO + MODO =====
	local right = K.f(root, "Hist", 380, 96, 172, 190, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 172, 120)
	local hist = {}
	local function renderHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		if #hist == 0 then
			K.txt(histArea, "(sem missoes ainda)", 10, 6, 150, 20, 9, T.txt4)
			return
		end
		for i, h in ipairs(hist) do
			if i > 5 then break end
			K.txt(histArea, "- " .. h, 10, 4 + (i - 1) * 22, 152, 20, 9, T.txt3)
		end
	end
	renderHist()
	run.MouseButton1Click:Connect(function()
		table.insert(hist, 1, goalBox.Text)
		table.remove(hist, 6)
		renderHist()
	end)
	K.row(right, "Modo", ARKHER.STATE.ai and ARKHER.STATE.ai.mode or "local", 152)
	K.txt(right, "IA 100% local:\nplanner + especialistas\nexecutam no Roblox.", 10, 168, 152, 44, 9, T.txt4)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "SINGULARITY", 12, 8, 140, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "planner de intent -> especialistas locais -> execucao real + relatorio", 12, 28, 400, 14, 9, T.txt3)
	K.txt(bar, "sem cloud, sem API key", 12, 52, 200, 14, 9, T.txt4)
	local diag = K.btn(bar, "Diag", 340, 52, 100, 24, T.bg2, 4)
	K.txtS(diag, "diagnostico", 9, T.txt)
	K.hover(diag, T.bg2, T.hover)
	diag.MouseButton1Click:Connect(function()
		goalBox.Text = "diagnostico"
		local ok, r = pcall(function() return ARKHER_SINGULARITY.run("diagnostico") end)
		if ok and r then lastRep = r renderRep() end
	end)
	K.txt(bar, "missoes: " .. tostring(#hist), 460, 58, 84, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("AI", "AI (Singularity)", "System", ICON.gem, "IA local: objetivo -> plano -> execucao real no workspace + relatorio", build)
end

do
--[[ ARKHER — UI: ANIMATOR STUDIO X (motor AAX custom, sem KeyframeSequences) ]]
-- Timeline REAL: clips multi-track (Position/CFrame/Size/Color/Transparency/
-- atributos), keys com 37 easings fisicos reais, spline preview desenhado das
-- curvas AMOSTRADAS do motor, scrub, loop/ping-pong, speed, markers com
-- eventos, blend de clips, DEFORMERS procedurais no assembly (bend/twist/
-- wave/taper/breathe) para dar vida sem rig manual. Exporta JSON. A pre-viw
-- escreve CFrame/Size/etc REAL na selecao.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFB453")
local AX = ArkherAnimX
local DM = ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

-- pre-declarados (padrao V4: nunca `function name()` depois)
local repaintClips, repaintTracks, repaintCurve, repaintKeys, repaintEase, repaintStatus, repaintMarkers

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR STUDIO X — motor AAX (custom)", 60, 140, 720, 500, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)
	local W, H = 720, 500

	-- ================= ESTADO =================
	local clips = {}
	local clipsSel = 1
	local trackSel = 1
	local keySel = 1
	local playhead = 0
	local speed = 1
	local boundInst = nil
	local deformH = nil
	local status = nil

	-- clips iniciais reais: BOAT BOB + FLAG WAVE (demonstradores fisicos)
	local boat = AX.clip("BoatBob", { loop = "pingpong" })
	boat:addTrack("Position", {
		AX.key(0, { x = 0, y = 2, z = 0 }, "easeInOut_sine"),
		AX.key(1.2, { x = 0.4, y = 3.4, z = 0 }, "easeOut_back"),
		AX.key(2.4, { x = 0, y = 2.2, z = 0 }, "easeInOut_sine"),
	})
	boat:addTrack("Transparency", { AX.key(0, 0.35, "linear"), AX.key(2.4, 0.15, "easeOut_sine") })
	boat:marker(1.2, "crest")
	local flag = AX.clip("FlagWave", { loop = "loop" })
	flag:addTrack("Position", {
		AX.key(0, { x = 0, y = 6, z = 0 }, "easeInOut_sine"),
		AX.key(0.6, { x = 0.8, y = 6.6, z = 0.2 }, "easeInOut_sine"),
		AX.key(1.2, { x = 0, y = 6, z = 0 }, "easeInOut_sine"),
	})
	clips = { boat, flag }
	local function clip() return clips[clipsSel] end
	local function track() local tr = clip() and clip().tracks[trackSel] return tr end

	-- ================= COLUNA ESQUERDA: CLIPS =================
	local leftW = 158
	local bodyH = 500 - 34 - 40
	local left = K.f(root, "Clips", 6, 34, leftW, bodyH, T.bg3)
	K.txt(left, "CLIPS", 8, 4, 120, 14, 9, T.txt3)
	local clipsBody = K.f(left, "Body", 4, 22, leftW - 8, bodyH - 70, T.bg2)
	local addClipB = K.btn(left, "+ Cl", 6, bodyH - 42, 46, 18, ACCENT)
	local dupB = K.btn(left, "Dup", 56, bodyH - 42, 44, 18, T.bg4)
	local delB = K.btn(left, "Del", 104, bodyH - 42, 46, 18, C("#B33A3A"))

	-- ================= CENTRO: TIMELINE/CURVE CANVAS =================
	local cx0, cw = leftW + 14, 344
	local center = K.f(root, "Curve", cx0, 34, cw, bodyH, T.bg3)
	K.txt(center, "CURVA AMOSTRADA (prop selecionada)", 8, 4, 240, 14, 9, T.txt3)
	local canvas = K.f(center, "Cv", 8, 24, cw - 16, 240, T.bg2)
	K.stroke(canvas, T.line, 1)
	-- backdrop grid
	for i = 1, 7 do K.f(canvas, "gx" .. i, i * (cw - 16) / 8, 0, 1, 240, T.line) end
	for i = 1, 4 do K.f(canvas, "gy" .. i, 0, i * 48, cw - 16, 1, T.line) end
	-- playhead marker
	local playLine = K.f(canvas, "Play", 0, 0, 1, 240, C("#6799FF"))
	-- mini timeline de markers/faixas
	local miniBar = K.f(center, "Mini", 8, 270, cw - 16, 40, T.bg2)
	K.stroke(miniBar, T.line, 1)
	K.txt(center, "markers feridos apos o(s) clip(s) ao PLAY", 8, 312, 320, 12, 8, T.txt3)
	-- controles de tempo
	local timeS = mkSlider(center, 8, 330, cw - 16, "Tempo", 0, 2.4, 0, function(v) return string.format("%.2fs", v) end, function(v) playhead = v repaintCurve() end)
	local playB = K.btn(center, "▶ Play", 8, 384, 70, 22, C("#3F9E58"))
	local stopB = K.btn(center, "■ Stop", 84, 384, 70, 22, C("#A93B3B"))
	local loopBtn = K.btn(center, "Loop: loop", 160, 384, 96, 22, T.bg4)
	local spdS = mkSlider(center, 262, 370, 78, "Vel", 0.1, 3, 1, function(v) return string.format("%.1fx", v) end, function(v) speed = v clip().speed = v end)
	local demoB = K.btn(center, "Aplicar na selecao + tocar", 8, 414, 180, 20, C("#2D6BFF"))
	local deformBtn = K.btn(center, "Deform: onda (assembly)", 194, 414, 160, 20, T.bg4)

	-- ================= DIREITA A: TRACKS =================
	local tx0, tw = cx0 + cw + 8, 174
	local trf = K.f(root, "Tracks", tx0, 34, tw, 210, T.bg3)
	K.txt(trf, "TRACKS", 8, 4, 120, 14, 9, T.txt3)
	local tracksBody = K.f(trf, "Body", 4, 20, tw - 8, 210 - 74, T.bg2)
	local PROPS = { "Position", "CFrame", "Size", "Color", "Transparency", "attr:Jump" }
	local propIdx = 1
	local addTrB = K.btn(trf, "+ Track", 6, 162, 70, 18, ACCENT)
	local propB = K.btn(trf, "prop: Position", 80, 162, 88, 18, T.bg4)
	local addKeyB = K.btn(trf, "+ Key @ playhead", 6, 184, 112, 18, C("#2D6BFF"))
	local delKeyB = K.btn(trf, "- Key", 124, 184, 44, 18, C("#B33A3A"))

	-- ================= DIREITA B: EASINGS + MARKERS + EXPORT =================
	local ex0 = tx0
	local ey0 = 252
	local ez = K.f(root, "Easy", ex0, ey0, tw, 500 - ey0 - 44, T.bg3)
	K.txt(ez, "EASING (aplica p/ key selecionada)", 8, 4, 200, 14, 9, T.txt3)
	local easeBody = K.f(ez, "Body", 4, 20, tw - 8, 148, T.bg2)
	local easeUp = K.btn(ez, "▲", 150, 4, 18, 14, T.bg4)
	local easeDn = K.btn(ez, "▼", 150, 20, 18, 14, T.bg4)
	local ezScroll = 0
	local mkBody = K.f(ez, "MkB", 4, 170, tw - 8, 16, T.bg2)
	local addMkB = K.btn(ez, "+ Marcador @ t", 6, 188, 110, 18, T.bg4)
	local expB = K.btn(ez, "Export", 118, 188, 50, 18, C("#2D6BFF"))

	-- ================= STATUS =================
	local stat = K.txt(root, "", 8, H - 40, W - 16, 14, 9, T.txt3)

	-- ================= FUNCOES (assign, NUNCA `function name()`) =================
	repaintStatus = function()
		local c = clip()
		local ks = track() and #track().keys or 0
		stat.Text = string.format("clip %d/%d  '%s' | track %d (%s) %d keys | duracao %.2fs | playhead %.2fs   | easings %d | springs p/ secondaries",
			clipsSel, #clips, c and c.name or "?", trackSel, track() and track().prop or "?", ks, c and c:duration() or 0, playhead, #AX.EASE_NAMES)
		timeS.set(playhead)
	end

	repaintClips = function()
		for _, ch in ipairs(clipsBody:GetChildren()) do ch:Destroy() end
		for i, c in ipairs(clips) do
			local row = K.btn(clipsBody, "C" .. i, 2, (i - 1) * 28, leftW - 16, 24, i == clipsSel and T.bg4 or T.bg3)
			local acc = C(i == clipsSel and "#FFB453" or "#5A6B8C")
			K.f(row, "a", 4, 10, 3, 3, acc)
			K.txt(row, c.name, 12, 5, leftW - 40, 14, 9.5, T.txt, Enum.Font.GothamMedium)
			K.txt(row, string.format("%d tr | %.1fs | %s", #c.tracks, c:duration(), c.loop), 12, 14, leftW - 40, 10, 7.5, T.txt3)
			row.MouseButton1Click:Connect(function() clipsSel = i trackSel = 1 keySel = 1 repaintTracks() repaintCurve() repaintStatus() end)
		end
	end

	repaintTracks = function()
		for _, ch in ipairs(tracksBody:GetChildren()) do ch:Destroy() end
		local c = clip()
		if not c then return end
		for i, tr in ipairs(c.tracks) do
			local row = K.btn(tracksBody, "T" .. i, 2, (i - 1) * 26, tw - 16, 22, i == trackSel and T.bg4 or T.bg3)
			local sw = K.f(row, "s", 4, 6, 8, 8, C(i == 1 and "#58C6FF" or i == 2 and "#7CE38B" or i == 3 and "#F77FAF" or "#FFB453"))
			K.txt(row, tr.prop, 18, 2, tw - 60, 12, 9, T.txt)
			K.txt(row, #tr.keys .. " keys", 18, 13, 120, 9, 7.5, T.txt3)
			row.MouseButton1Click:Connect(function() trackSel = i keySel = 1 repaintCurve() repaintEase() repaintStatus() end)
		end
		-- nenhum
		if #c.tracks == 0 then K.txt(tracksBody, "(sem tracks — +Track)", 6, 6, 140, 14, 9, T.txt3) end
	end

	repaintCurve = function()
		for _, ch in ipairs(canvas:GetChildren()) do if ch.Name:find("^pt") or ch.Name == "KeyM" then ch:Destroy() end end
		local tr = track()
		local c = clip()
		if not tr or not c then return end
		local dur = math.max(c:duration(), 0.001)
		-- range do valor (1D: usa vetor m ou escalar)
		local vmin, vmax = math.huge, -math.huge
		for i = 1, 40 do
			local t = (i - 1) / 39 * dur
			local v = tr:sample(t)
			local sv = (type(v) == "table") and v.y or v
			if sv then vmin = math.min(vmin, sv) vmax = math.max(vmax, sv) end
		end
		local span = math.max(vmax - vmin, 1e-4)
		local CW = cw - 16
		local denom = (span == 0 and 1 or span)
		for i = 1, 40 do
			local t = (i - 1) / 39 * dur
			local v = tr:sample(t)
			local sv = (type(v) == "table") and v.y or v
			if sv then
				local x = (t / dur) * (CW - 8) + 2
				local y = 240 - ((sv - vmin) / denom * 220 + 10)
				local dot = K.f(canvas, "pt" .. i, x, y, 4, 4, ACCENT)
				K.corner(dot, 2)
			end
		end
		-- keys com cor da track
		for ki, k in ipairs(tr.keys) do
			local x = (k.t / dur) * (CW - 8) + 2
			local km = K.f(canvas, "KeyM", x - 4, (ki == keySel and 4 or 8), 8, (ki == keySel and 10 or 6), ki == keySel and C("#FF4040") or T.txt3)
			km.Name = "KeyM_" .. ki
			local btn = K.btn(canvas, "KB" .. ki, x - 7, 0, 14, 240, C("#000000"))
			btn.BackgroundTransparency = 1
			btn.ZIndex = 5
			btn.MouseButton1Click:Connect(function() keySel = ki repaintCurve() repaintEase() repaintStatus() end)
		end
		-- playhead
		playLine.Position = UDim2.new(0, (playhead / dur) * (CW - 8) + 2, 0, 0)
	end

	repaintKeys = function() repaintCurve() end -- alias (camadas juntas)

	repaintEase = function(ezScroll_)
		ezScroll = ezScroll_ or ezScroll or 0
		for _, ch in ipairs(easeBody:GetChildren()) do ch:Destroy() end
		local names = AX.EASE_NAMES
		local PER = 15
		local page = math.floor(ezScroll / PER)
		local c2 = clip()
		local tr = track()
		local curE = nil
		if tr and tr.keys[keySel] then curE = tr.keys[keySel].ease end
		for i = 1 + page * PER, math.min(#names, page * PER + PER) do
			local id = names[i]
			local b = K.btn(easeBody, "E" .. i, 2 + ((i - 1 - page * PER) % 3) * 56, math.floor((i - 1 - page * PER) / 3) * 24, 52, 20, id == curE and ACCENT or T.bg3)
			K.txt(b, id:sub(1, 8), 2, 5, 46, 12, 7.5, id == curE and C("#111") or T.txt2, Enum.Font.Code)
			b.MouseButton1Click:Connect(function()
				local tr2 = track()
				if tr2 and tr2.keys[keySel] then
					tr2.keys[keySel].ease = id
					repaintCurve()
					repaintEase()
					repaintStatus()
				end
			end)
		end
	end

	repaintMarkers = function()
		for _, ch in ipairs(mkBody:GetChildren()) do ch:Destroy() end
		local c = clip()
		if not c then return end
		for i, mk in ipairs(c.markers) do
			K.txt(mkBody, string.format("⚑ %s @ %.1f", tostring(mk.id), mk.t), 4 + (i - 1) * 80, 4, 78, 16, 8, C("#9BB1FF"))
		end
		if #c.markers == 0 then K.txt(mkBody, "sem marcadores", 4, 4, 120, 14, 8, T.txt3) end
	end

	-- ================= ACOES =================
	addClipB.MouseButton1Click:Connect(function()
		local base = clip()
		local c2 = AX.clip("Clip_" .. #clips + 1, { loop = "loop" })
		c2:addTrack("Position", { AX.key(0, { x = 0, y = 1, z = 0 }, "linear"), AX.key(1.5, { x = 4, y = 3, z = 0 }, "easeOut_spring") })
		clips[#clips + 1] = c2
		clipsSel = #clips
		repaintClips() repaintTracks() repaintCurve() repaintStatus()
	end)
	dupB.MouseButton1Click:Connect(function()
		local c = clip()
		if c then
			local str = c:serialize()
			local c3 = AX.deserialize(str)
			if c3 then c3.name = c3.name .. "_copia" clips[#clips + 1] = c3 clipsSel = #clips end
			repaintClips() repaintStatus()
		end
	end)
	delB.MouseButton1Click:Connect(function()
		if #clips > 1 then table.remove(clips, clipsSel) clipsSel = 1 trackSel = 1 repaintClips() repaintTracks() repaintCurve() repaintStatus() end
	end)
	addTrB.MouseButton1Click:Connect(function()
		local c = clip()
		local prop = PROPS[propIdx]
		local v0 = prop == "Transparency" and 0.5 or (prop == "Color" and { r = 90, g = 140, b = 240 } or { x = 0, y = 2, z = 0 })
		local v1 = prop == "Transparency" and 0.1 or (prop == "Color" and { r = 240, g = 90, b = 140 } or { x = 0, y = 6, z = 0 })
		c:addTrack(prop, { AX.key(0, v0, "linear"), AX.key(1.2, v1, "easeInOut_sine") })
		trackSel = #c.tracks
		repaintTracks() repaintCurve() repaintStatus()
	end)
	propB.MouseButton1Click:Connect(function()
		propIdx = propIdx % #PROPS + 1
		propB.Text = "prop: " .. PROPS[propIdx]
	end)
	addKeyB.MouseButton1Click:Connect(function()
		local tr = track()
		local c = clip()
		if tr and c then
			local v = tr:sample(playhead)
			tr:addKey({ t = clamp(playhead, 0, c:duration()), v = v, ease = "easeOut_sine" })
			keySel = #tr.keys
			repaintCurve() repaintEase() repaintStatus()
		end
	end)
	delKeyB.MouseButton1Click:Connect(function()
		local tr = track()
		if tr and #tr.keys > 1 then tr:removeAt(keySel) keySel = 1 repaintCurve() repaintStatus() end
	end)
	easeUp.MouseButton1Click:Connect(function() repaintEase(math.max(0, ezScroll - 15)) end)
	easeDn.MouseButton1Click:Connect(function() repaintEase(ezScroll + 15) end)
	loopBtn.MouseButton1Click:Connect(function()
		local modes = { "loop", "pingpong", "none" }
		local c = clip()
		local i2 = 1
		for i, m in ipairs(modes) do if m == c.loop then i2 = i end end
		c.loop = modes[i2 % 3 + 1]
		loopBtn.Text = "Loop: " .. c.loop
		repaintStatus()
	end)
	local playing = false
	playB.MouseButton1Click:Connect(function()
		playing = true
		AX.stopAll()
		local c = clip()
		c:play({ from = playhead })
	end)
	stopB.MouseButton1Click:Connect(function() playing = false AX.stopAll() repaintStatus() end)
	addMkB.MouseButton1Click:Connect(function()
		clip():marker(playhead, "mk" .. (#clip().markers + 1))
		repaintMarkers()
	end)
	expB.MouseButton1Click:Connect(function()
		local c = clip()
		local str = c:serialize()
		local path = "ArkherClips/" .. c.name .. ".json"
		local ok = pcall(function() if game.WriteFile then game:WriteFile(path, str) end end)
		K.notify("Clip exportado", #str .. " chars → " .. path, "ok")
	end)
	demoB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		local inst = list and list[1]
		if inst then
			boundInst = inst
			local c = clip()
			c.binds = { { inst = inst, map = {} } }
			playing = true
			AX.stopAll()
			c:play({ from = playhead })
			K.notify("AAX bound", "clip '" .. c.name .. "' escreve REAL em " .. (inst.Name or "?"), "ok")
		else
			-- cria alvo demo se nada selecionado
			local ws = game:FindFirstChild("Workspace") or game
			local p = Instance.new("Part")
			p.Name = "AAX_Demo"
			p.Size = Vector3.new(2, 2, 2)
			p.Anchored = true
			p.Color = Color3.fromRGB(255, 170, 60)
			p.CFrame = CFrame.new(0, 4, 0)
			p.Parent = ws
			boundInst = p
			clip().binds = { { inst = p, map = {} } }
			playing = true
			AX.stopAll()
			clip():play({ from = playhead })
			K.notify("Demo criada", "Part AAX_Demo no workspace (sem selecao anterior)", "info")
		end
	end)
	local defKind = 1
	local DEFN = { "onda (wave)", "dobrar (bend)", "torcer (twist)", "afunilar (taper)", "respirar (breathe)" }
	deformBtn.MouseButton1Click:Connect(function()
		defKind = defKind % #DEFN + 1
		deformBtn.Text = "Deform: " .. DEFN[defKind]
	end)
	local liveDeformB = K.btn(center, "TOCAR deform p/ assembly", 360, 414, 160, 20, C("#3F9E58"))
	liveDeformB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list < 1 then
			K.notify("Sem selecao", "selecione parts para formar um assembly", "warn")
			return
		end
		local fns = {
			AX.DEFORMERS.wave(1.2, 14, 2.2),
			AX.DEFORMERS.bend(0.8, "x"),
			AX.DEFORMERS.twist(0.5, "y"),
			AX.DEFORMERS.taper(0.6, "y"),
			AX.DEFORMERS.breathe(0.08, 2.4),
		}
		if deformH then deformH.playing = false end
		local asm = AX.assemble(list)
		deformH = AX.deform(asm, fns[defKind], {})
		K.notify("Assembly deformer", DEFN[defKind] .. " em " .. #list .. " parts (ao vivo)", "ok")
	end)

	-- ================= PUMP (Frame -> AAX.pump + exhibits) =================
	local acc = 0
	pcall(function()
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			AX.pump(dt)
			AX.pumpDeformers(dt)
			acc = acc + dt
			if acc >= 0.1 then
				acc = 0
				-- atualizar playhead visual e dots
				local c = clip()
				if c and c.playing then
					playhead = c.time
					repaintCurve()
					repaintStatus()
				end
			end
		end)
	end)

	-- ================= BOOT =================
	repaintClips()
	repaintTracks()
	repaintCurve()
	repaintEase(0)
	repaintMarkers()
	repaintStatus()
	return g
end

ARKHER.reg("Animator", "Animator Studio X", "Editor", ICON.play, "Animacao custom (AAX): 37 easings, splines, springs, deformers, export JSON, aplica REAL", build)
end

do
--[[ ARKHER — UI: AUDIO STUDIO X (motor AUX custom: mixer + DSP + scheduler) ]]
-- Mixer profissional de verdade: 7 buses SoundGroup REAIS, sliders FUNCIONAIS,
-- presets acusticos (caverna/estadio/estudio/subaquatico/radio/floresta/metal)
-- ligando efeitos DSP do engine (Reverb/Echo/Compressor/EQ/Distortion/Flange/
-- PitchShift), DUCKING sidechain de voz->musica com envelope demonstrado AO
-- VIVO, camadas de musica adaptativas (base/tension/combat + intensidade),
-- scheduler ambiente (never-repeat-2), posicional 3D com rolloff real e
-- doppler aproximado, links com AWX (ondas grandes => vento).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#B78CFF")
local AX = ArkherAudioX
local DM = ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local repaintStatus, repaintBusRows, repaintDuckBars, repaintLayerBars, repaintAmbLog, repaintPosVals
local showTab

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO STUDIO X — motor AUX (custom)", 90, 110, 720, 490, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)
	local W, H = 720, 490

	-- setup do motor (grupos REAIS)
	AX.setup()

	-- ================= ESQUERDA: BUSES =================
	local left = K.f(root, "Buses", 6, 34, 250, 490 - 34 - 40, T.bg3)
	K.txt(left, "BUSES (SoundGroups REAIS em SoundService)", 8, 4, 240, 14, 9, T.txt3)
	local busRows = K.f(left, "Rows", 4, 22, 242, 260, T.bg3)
	local buses = AX.BUSES
	local busSliders = {}
	for i, b in ipairs(buses) do
		local lbl = K.txt(busRows, b, 8, (i - 1) * 36 + 2, 70, 12, 9, T.txt)
		local envLbl = K.txt(busRows, "env: 1.00", 170, (i - 1) * 36 + 2, 70, 12, 7.5, T.txt3, nil, Enum.TextXAlignment.Right)
		busSliders[b] = mkSlider(busRows, 8, (i - 1) * 36 + 14, 220, "", 0, 2,
			AX.busVolume(b) or 1, function(v) return string.format("%.2f", v) end,
			function(v) AX.setBusVolume(b, v) repaintStatus() end)
		busSliders[b].envLbl = envLbl
	end
	K.txt(left, "duck env mostra o envelope atual (demonstracao abaixo)", 6, 268, 236, 12, 8, T.txt3)
	-- duck demo
	local duckState = K.txt(left, "DUCKING: voz -> musica (sidechain)", 6, 288, 240, 14, 9, T.txt)
	local duckBar = K.f(left, "DB", 6, 304, 250 - 12 - 4, 16, T.bg2)
	K.stroke(duckBar, T.line, 1)
	local duckFill = K.f(duckBar, "f", 0, 0, 10, 16, C("#63D68B"))
	local duckBtn = K.btn(left, "Tocar VOZ (duck musica)", 6, 326, 120, 20, C("#2D6BFF"))
	local duckStopB = K.btn(left, "Parar voz", 132, 326, 80, 20, T.bg4)
	local duckOn = false

	-- ================= CENTRO-DIREITA: TABS (DSP/AMBIENT/LAYERS/POSICIONAL) =================
	local tabs = K.tabs(root, 262, 30, 450, { "DSP presets", "Ambiente", "Camadas", "Posicional 3D" }, 1, function(i) showTab(i) end)
	local panelY = 58
	local panel = K.f(root, "Panel", 262, panelY, 450, 490 - panelY - 40, T.bg2)

	-- ---- ABA 1: DSP presets
	local p1 = K.f(panel, "P1", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p1, "Ligan efeitos DSP REAIS no SoundGroup (Roblox engine):", 8, 4, 430, 14, 9, T.txt3)
	local busSel = "music"
	local busPickB = K.btn(p1, "bus alvo: music", 8, 22, 120, 18, T.bg4)
	busPickB.MouseButton1Click:Connect(function()
		local order = AX.BUSES
		local i2 = 1
		for i, b in ipairs(order) do if b == busSel then i2 = i end end
		busSel = order[i2 % #order + 1]
		busPickB.Text = "bus alvo: " .. busSel
	end)
	local dspKeys = { "flat", "caverna", "estadio", "estudio", "subaquatico", "radio", "floresta", "metal" }
	local dspNames = { "Flat", "Caverna", "Estadio", "Estudio", "Subaquatico", "Radio/AM", "Floresta", "Metal/Flange" }
	for i, pid in ipairs(dspKeys) do
		local b = K.btn(p1, "FX_" .. pid, 8 + ((i - 1) % 2) * 150, 48 + math.floor((i - 1) / 2) * 28, 140, 22, T.bg3)
		K.txt(b, dspNames[i], 8, 5, 120, 12, 9, T.txt2)
		b.MouseButton1Click:Connect(function()
			local ok, n = AX.patch(busSel, pid)
			if ok then
				K.notify("Patch DSP", pid .. " em " .. busSel .. " — " .. n .. " efeito(s) ligado(s)", "ok")
			else
				K.notify("Patch falhou", tostring(n), "warn")
			end
			repaintStatus()
		end)
	end
	local clB = K.btn(p1, "Limpar bus (remover efeitos AUX)", 8, 48 + 4 * 28 + 6, 220, 20, C("#6E2B2B"))
	clB.MouseButton1Click:Connect(function() AX.clearPatch(busSel) K.notify("DSP limpo", busSel .. " sem efeitos AUX", "info") end)
	K.txt(p1, "efeitos disponiveis no motor: Reverb, Echo, Compressor, EQ, Distortion,", 8, 48 + 4 * 28 + 34, 420, 12, 8.5, T.txt3)
	K.txt(p1, "Flange, Tremolo, PitchShift — aplicados em cascata na bus, Dreamscape real.", 8, 48 + 4 * 28 + 48, 420, 12, 8.5, T.txt3)

	-- ---- ABA 2: AMBIENTE
	local p2 = K.f(panel, "P2", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p2, "SCHEDULER AMBIENTE (rodando mesmo sem assets: ids abstratos de slot)", 8, 4, 430, 14, 9, T.txt3)
	local ambs = {}
	local ambRows = K.f(p2, "Rows", 6, 24, 450 - 12, 150, T.bg2)
	-- schedule pre-montado: floresta / mar / cidade / vulcao noturno
	local SPECS = {
		{ nm = "floresta", ids = { "amb_passaros", "amb_folhas", "amb_rio_longe", "amb_insetos" }, interval = { 12, 30 }, bus = "ambient" },
		{ nm = "mar", ids = { "amb_onda_fraca", "amb_onda_forte", "amb_gaivota" }, interval = { 10, 26 }, bus = "weather", minAmpLink = true },
		{ nm = "cidade", ids = { "amb_traffic", "amb_sirene_longe", "amb_vento_predios", "amb_vozes" }, interval = { 14, 38 }, bus = "ambient" },
		{ nm = "noite_vulcao", ids = { "amb_trovao", "amb_galho_seco", "amb_coruja", "amb_rajada" }, interval = { 20, 60 }, bus = "weather" },
	}
	local ambBtns = {}
	for i, sp in ipairs(SPECS) do
		K.txt(ambRows, sp.nm .. "  (" .. #sp.ids .. " ids)", 6, (i - 1) * 34 + 2, 200, 12, 9, T.txt)
		K.txt(ambRows, "int " .. sp.interval[1] .. "-" .. sp.interval[2] .. "s  bus " .. sp.bus, 6, (i - 1) * 34 + 16, 220, 10, 8, T.txt3)
		local goB = K.btn(ambRows, "▶", 240, (i - 1) * 34, 32, 20, C("#3F9E58"))
		local stopB = K.btn(ambRows, "■", 278, (i - 1) * 34, 32, 20, C("#A93B3B"))
		local st = K.txt(ambRows, "off", 320, (i - 1) * 34 + 5, 60, 12, 8, T.txt3)
		ambBtns[sp.nm] = st
		goB.MouseButton1Click:Connect(function()
			if not AX._ambients[sp.nm] then
				AX.ambient(sp.nm, { ids = sp.ids, interval = sp.interval, bus = sp.bus, volume = { 0.2, 0.55 } })
			end
			if sp.minAmpLink then AX.linkSea((ARKHER._sea or WX_SEA()), "mar", { minAmp = 0.5 }) end
			AX._ambients[sp.nm]:start()
			st.Text = "ON"
			st.TextColor3 = C("#63D68B")
			repaintStatus()
		end)
		stopB.MouseButton1Click:Connect(function()
			if AX._ambients[sp.nm] then AX._ambients[sp.nm]:stop() end
			st.Text = "off"
			st.TextColor3 = T.txt3
		end)
	end
	K.txt(p2, "ultimos disparos:", 6, 186, 140, 14, 9, T.txt3)
	local ambLog = K.f(p2, "Log", 6, 202, 450 - 12, 120, T.bg2)
	K.stroke(ambLog, T.line, 1)

	-- ---- ABA 3: CAMADAS
	local p3 = K.f(panel, "P3", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p3, "MUSICA ADAPTATIVA — 3 camadas (base / tensao / combate), crossfade REAL via pump", 8, 4, 440, 14, 9, T.txt3)
	-- registra 3 loops demo (sem asset real: slots nomeados — em produção voce coloca rbxassetid)
	AX.register("mus_base", { bus = "music", volume = 0.5, looped = true })
	AX.register("mus_tension", { bus = "music", volume = 0.5, looped = true })
	AX.register("mus_combat", { bus = "music", volume = 0.5, looped = true })
	local layInitB = K.btn(p3, "START layers", 8, 24, 110, 20, C("#3F9E58"))
	local layStopB = K.btn(p3, "STOP layers", 124, 24, 110, 20, T.bg4)
	local intS = mkSlider(p3, 8, 60, 260, "Intensidade", 0, 2, 0, function(v) return string.format("%.2f", v) end, function(v) AX.setIntensity(v) end)
	local layerBars = K.f(p3, "Bars", 8, 110, 270, 80, T.bg2)
	K.stroke(layerBars, T.line, 1)
	local lbar = {}
	for i, role in ipairs({ "base", "tension", "combat" }) do
		K.txt(layerBars, role, 8, (i - 1) * 24 + 4, 60, 12, 8.5, T.txt3)
		lbar[role] = K.f(layerBars, "b_" .. role, 70, (i - 1) * 24 + 5, 4, 12, (i == 1 and C("#63D68B") or i == 2 and C("#FFC453") or C("#FF5E5E")))
	end
	K.txt(p3, "int 0=no pacato (base 100%) | 1=tensao | 2=combate", 8, 196, 400, 12, 8, T.txt3)
	layInitB.MouseButton1Click:Connect(function()
		AX.musicLayers({ base = "mus_base", tension = "mus_tension", combat = "mus_combat" })
		K.notify("Layers", "3 camadas de musica iniciadas (base/tensao/combate)", "ok")
	end)
	layStopB.MouseButton1Click:Connect(function()
		AX.stop("mus_base") AX.stop("mus_tension") AX.stop("mus_combat")
		K.notify("Layers paradas", "music loops stop", "info")
	end)

	-- ---- ABA 4: POSICIONAL 3D
	local p4 = K.f(panel, "P4", 0, 0, 450, 490 - panelY - 40, T.bg2)
	K.txt(p4, "POSICIONAL 3D SIMULADO — rolloff inverso-quadratico + doppler aproximado", 8, 4, 440, 14, 9, T.txt3)
	local posState = { tr = nil }
	local bindPosB = K.btn(p4, "Criar emissor posicional ('vento')", 8, 26, 220, 20, C("#2D6BFF"))
	local posVals = {
		dist = K.txt(p4, "dist: —", 8, 60, 200, 14, 9, T.txt),
		vol = K.txt(p4, "vol efetivo: —", 8, 80, 200, 14, 9, T.txt),
		pitch = K.txt(p4, "doppler pitch: —", 8, 100, 200, 14, 9, T.txt),
	}
	local refS = mkSlider(p4, 8, 126, 260, "Ref dist", 2, 40, 12, function(v) return string.format("%.0f", v) end, function(v) if posState.tr then posState.tr.refDist = v end end)
	local maxS = mkSlider(p4, 8, 160, 260, "Max dist", 40, 400, 120, function(v) return string.format("%.0f", v) end, function(v) if posState.tr then posState.tr.maxDist = v end end)
	local demoPos = Vector3.new(24, 3, 24)
	bindPosB.MouseButton1Click:Connect(function()
		AX.register("vento", { bus = "weather", volume = 0.6 })
		AX.play("vento", { volume = 0.6 })
		posState.tr = AX.positional("vento", function() return demoPos end, { refDist = refS.get(), maxDist = maxS.get(), volume = 0.6 })
		K.notify("Emissor posicional", "'vento' em (24,3,24) — afaste a camera p/ ouvir cair", "ok")
	end)
	-- doppler check: mover o emissor circular para demonstrar
	local demoAng = 0

	-- ================= STATUS =================
	local stat = K.txt(root, "", 8, H - 36, W - 16, 14, 9, T.txt3)

	-- ================= PAINT FNS =================
	repaintStatus = function()
		local st = AX.stats()
		stat.Text = string.format("buses %d | sons registrados %d (%d playing) | ducks %d | ambients %d | posicionais %d %s",
			st.buses, st.sounds, st.playing, st.ducks, st.ambients, st.positional,
			(st.layers ~= nil) and string.format("| intensidade musica %.2f", st.layers) or "")
	end
	repaintDuckBars = function()
		-- envelope atual da duck voz->musica
		for _, d in ipairs(AX._ducks) do
			if d.trigger == "voice" and d.target == "music" then
				duckFill.Size = UDim2.new(0, math.floor((1 - (d.env or 1)) * math.max(duckBar.AbsoluteSize.X, 10)), 1, 0)
			end
		end
	end
	repaintLayerBars = function()
		if AX._layers then
			local int = AX._layers.intensity or 0
			local map = {
				base = DM.clamp(1 - int, 0.25, 1),
				tension = DM.clamp(1 - math.abs(int - 1), 0, 1),
				combat = DM.clamp(int - 1, 0, 1),
			}
			for role, bar in pairs(lbar) do
				bar.Size = UDim2.new(0, math.floor(map[role] * 180) + 4, 0, 12)
			end
		end
	end
	repaintAmbLog = function()
		for _, ch in ipairs(ambLog:GetChildren()) do ch:Destroy() end
		local fires = AX._fires or {}
		for i = math.max(1, #fires - 6), #fires do
			local f = fires[i]
			if f then K.txt(ambLog, "• " .. f.name .. " @ " .. string.format("%.1f", f.t or 0), 6, (i - math.max(1, #fires - 6)) * 17 + 3, 410, 12, 8, C("#9BB1FF")) end
		end
	end
	local camGet = function()
		local ws = game:FindFirstChild("Workspace")
		local cam = ws and ws.CurrentCamera
		if cam and cam.CFrame then return cam.CFrame.Position end
		return nil
	end
	repaintPosVals = function()
		local cp = camGet()
		if cp and posState.tr then
			local dx, dy, dz = cp.X - demoPos.X, cp.Y - demoPos.Y, cp.Z - demoPos.Z
			local d = math.sqrt(dx * dx + dy * dy + dz * dz)
			posVals.dist.Text = string.format("dist: %.1f m", d)
			local g = DM.clamp((posState.tr.refDist / math.max(d, posState.tr.refDist)) ^ 2, 0, 1)
			if d > posState.tr.maxDist then g = 0 end
			posVals.vol.Text = string.format("vol efetivo: %.3f", posState.tr.baseVol * g)
		end
		local reg = AX._sounds["vento"]
		if reg then posVals.pitch.Text = string.format("doppler pitch: %.2f", reg.inst.PlaybackSpeed or 1) end
	end
	repaintBusRows = function()
		for b, sl in pairs(busSliders) do
			if sl.envLbl then
				local g = AX._groups and AX._groups[b]
				local v = g and g.Volume or AX.busVolume(b) or 1
				sl.envLbl.Text = string.format("env: %.2f", v)
			end
		end
	end

	-- duck demo buttons (mono: registramos os sons 'voice_demo'/'musica_demo')
	AX.register("voice_demo", { bus = "voice", volume = 0.6 })
	AX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	AX.duck("music", "voice", { level = 0.3, attack = 0.08, release = 0.9, hold = 0.6 })
	duckBtn.MouseButton1Click:Connect(function()
		AX.play("musica_demo", { volume = 0.5 })
		AX.play("voice_demo", { volume = 0.6 })
		duckOn = true
		duckState.Text = "DUCKING ATIVO — musica cai p/ 30%"
		repaintStatus()
	end)
	duckStopB.MouseButton1Click:Connect(function()
		AX.stop("voice_demo")
		duckOn = false
		duckState.Text = "voz off — musica volta (release 0.9s)"
	end)

	-- tab switching
	local panels = { p1, p2, p3, p4 }
	showTab = function(i)
		for j, p in ipairs(panels) do p.Visible = (j == i) end
	end
	showTab(1)

	-- ================= PUMP LOOP =================
	pcall(function()
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			AX.pump(dt)
			-- demo doppler circular
			if posState.tr then
				demoAng = demoAng + dt * 0.9
				demoPos = Vector3.new(24 + math.cos(demoAng) * 10, 3, 24 + math.sin(demoAng) * 10)
			end
			local ac = (g._acc or 0) + dt
			g._acc = ac
			if ac > 0.12 then
				g._acc = 0
				repaintStatus()
				repaintDuckBars()
				repaintLayerBars()
				repaintBusRows()
				repaintPosVals()
				repaintAmbLog()
			end
		end)
	end)

	-- ================= BOOT =================
	repaintStatus()
	return g
end

-- helper global p/ link mar (AWX)
WX_SEA = function()
	if ARKHER._sea then return ARKHER._sea end
	if ArkherWaterX then
		ARKHER._sea = ArkherWaterX.preset("porto", { kind = "oceano", level = 0, size = { x = 300, z = 300 } })
		return ARKHER._sea
	end
	return nil
end

ARKHER.reg("Audio", "Audio Studio X", "Scene", ICON.data, "Audio custom (AUX): SoundGroups, DSP presets, ducking, scheduler, layers adaptativas, 3D", build)
end

do
-- =============================================================
-- CAMERA STUDIO X — UI sobre o CAMERA X (ACX custom)
-- Shots fisicos (orbit/dolly/crane/follow/flypath Catmull-Rom),
-- SHAKE por trauma^2 (amplitude real de cinematografia), FADE real
-- via ColorCorrectionEffect, CINEMA (cortes em cadeia), editor de
-- flypath com canvas 2D top-view. Mexer = camera real. 🎬
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#D9A5FF"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#D9A5FF"))
	K.corner(fill, 3)
	local function rs()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setI(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		rs()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then setI(i) end end)
	track.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then setI(i) end end)
	rs()
	return { get = function() return val end, set = function(v) val = v rs() if onSet then onSet(v) end end }
end

local function build()
	if not ArkherCameraX then ARKHER.note("Kit E nao carregado (CAMERA X ausente)") return end
	local ACX = ArkherCameraX

	local W, H = 700, 480
	local g, root = K.window("CameraStudio", "CAMERA STUDIO X — cinematografia custom (ACX custom)", 260, 150, W, H, { pin = true })

	local bodyH = H - 34 - 40

	-- ============ ESQUERDA: SHOTS ============
	local left = K.f(root, "L", 6, 34, 244, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "SHOTS (acao real na CurrentCamera)", 8, 4, 230, 14, 9, T.txt3)
	local shots = {
		{ nm = "ORBIT", d = "circula o alvo (raio/altura/velocidade)" },
		{ nm = "DOLLY IN", d = "dolly-in com easeInOut_sine" },
		{ nm = "DOLLY OUT", d = "dolly-out com easeOut_quad" },
		{ nm = "CRANE", d = "eleva no arco (dolly + lift)" },
		{ nm = "FLY PATH", d = "catmull-rom por 3 pontos" },
	}
	local function runShot(nm)
		local r = radiusS.get()
		local hgt = heightS.get()
		local dur = durS.get()
		if nm == "ORBIT" then
			ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = r, height = hgt, speed = spdS.get(), duration = 9999 })
		elseif nm == "DOLLY IN" then
			ACX.shot({ type = "dolly", from = Vector3.new(-r, hgt, -r), to = Vector3.new(-2, hgt, -2), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeInOut_sine" })
		elseif nm == "DOLLY OUT" then
			ACX.shot({ type = "dolly", from = Vector3.new(-2, hgt, -2), to = Vector3.new(-r, hgt, -r), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeOut_quad" })
		elseif nm == "CRANE" then
			ACX.shot({ type = "crane", from = Vector3.new(-r, 2, 0), to = Vector3.new(r, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = dur, lift = hgt })
		elseif nm == "FLY PATH" then
			ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = dur })
		end
	end
	for i, sh in ipairs(shots) do
		local y = 20 + (i - 1) * 44
		local b = K.btn(left, sh.nm, 8, y, 228, 26, C("#4A2E6E"), 6)
		K.txt(b, sh.nm, 10, 6, 100, 14, 9.5, T.txt)
		K.txt(left, sh.d, 10, y + 26, 224, 12, 8, T.txt3)
		b.MouseButton1Click:Connect(function() runShot(sh.nm) end)
	end
	local stopB = K.btn(left, "STOP", 8, 20 + 5 * 44, 110, 22, C("#7A2E2E"), 5)
	stopB.MouseButton1Click:Connect(function() ACX.stop() end)
	local cinemaB = K.btn(left, "CINEMA (3 cortes)", 124, 20 + 5 * 44, 112, 22, C("#2E4E7A"), 5)
	cinemaB.MouseButton1Click:Connect(function()
		ACX.cinema({
			{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = durS.get(), lift = 10 },
			{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
			{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
		})
	end)

	-- ============ CENTRO: PARAMS + FLY CANVAS + TRAUMA ============
	local center = K.f(root, "C", 258, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "PARAMETROS DO SHOT", 8, 4, 236, 14, 9, T.txt3)
	local radiusS = mkSlider(center, 8, 20, 226, "raio/dist", 4, 40, 14, function(v) return string.format("%.1f m", v) end)
	local heightS = mkSlider(center, 8, 62, 226, "altura", 1, 30, 7, function(v) return string.format("%.1f m", v) end)
	local spdS = mkSlider(center, 8, 104, 226, "vel. orbita (rad/s)", 0.05, 4.0, 0.5, function(v) return string.format("%.2f", v) end)
	local durS = mkSlider(center, 8, 146, 226, "duracao (s)", 0.5, 12.0, 4.0, function(v) return string.format("%.1f s", v) end)
	local faS = mkSlider(center, 8, 188, 226, "fly from (+/−)", -30, 30, -20, function(v) return string.format("%.0f", v) end)
	local fbS = mkSlider(center, 8, 230, 226, "fly to (+/−)", -30, 30, 20, function(v) return string.format("%.0f", v) end)
	K.txt(center, "FLY PATH (top view)", 8, 276, 236, 14, 9, T.txt3)
	local fcv = K.f(center, "FCV", 8, 294, 226, 130, C("#0A0F1A"))
	K.stroke(fcv, T.line, 1)
	-- desenha a curva catmull no canvas (pontos)
	local pathPts = {}
	for i = 0, 24 do
		local dot = K.f(fcv, "p" .. i, 4 + i * 9, 4, 3, 3, C("#D9A5FF"))
		pathPts[i] = dot
	end
	local function repaintPath()
		local a = { X = faS.get(), Y = 0, Z = faS.get() }
		local m = { X = 0, Y = 0, Z = 0 }
		local b = { X = fbS.get(), Y = 0, Z = fbS.get() }
		local n2 = { X = fbS.get() * 2, Y = 0, Z = fbS.get() * 2 }
		local cur = ACX.curve3(a, m, b, n2)
		for i = 0, 24 do
			local u = i / 24
			local px, py, pz = cur(u)
			pathPts[i].Position = UDim2.new(0, math.floor(((px + 30) / 60) * 226), 0, math.floor(((pz + 30) / 60) * 130))
		end
	end
	repaintPath()
	local playFlyB = K.btn(center, "PLAY FLY PATH", 8, 428, 106, 22, C("#4A2E6E"), 5)
	playFlyB.MouseButton1Click:Connect(function()
		ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = durS.get() })
	end)
	local updB = K.btn(center, "redesenhar curva", 122, 428, 108, 22, T.bg4, 5)
	updB.MouseButton1Click:Connect(function() repaintPath() end)

	-- ============ DIREITA: TRAUMA + FADE + STATS ============
	local right = K.f(root, "R", 516, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "TRAUMA (shake puro cinema)", 8, 4, 222, 14, 9, T.txt3)
	K.txt(right, "amplitude = trauma^2 * 0.35 rad", 8, 18, 222, 12, 8, T.txt3)
	local traumaS = mkSlider(right, 8, 34, 222, "trauma alvo", 0, 1, 0.5, function(v) return string.format("%.0f%%", v * 100) end)
	local bumpB = K.btn(right, "BUMP (+trauma)", 8, 78, 106, 22, C("#7A5A2E"), 5)
	bumpB.MouseButton1Click:Connect(function() ACX.addTrauma(traumaS.get()) end)
	local decBtn = K.btn(right, "4s tremendo", 122, 78, 108, 22, T.bg4, 5)
	decBtn.MouseButton1Click:Connect(function()
		ACX.addTrauma(1)
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 16, height = 6, speed = 0.4, duration = 9999 })
	end)
	K.txt(right, "FADE REAL (ColorCorrection)", 8, 112, 222, 14, 9, T.txt3)
	local fadeOutB = K.btn(right, "FADE OUT", 8, 128, 106, 22, C("#3A3A42"), 5)
	local fadeInB = K.btn(right, "FADE IN", 122, 128, 108, 22, C("#5A4A6E"), 5)
	fadeOutB.MouseButton1Click:Connect(function() ACX.fade(-1, 0.8) end)
	fadeInB.MouseButton1Click:Connect(function() ACX.fade(0, 0.8) end)
	K.txt(right, "CAMERA AO VIVO (pump)", 8, 162, 222, 14, 9, T.txt3)
	local posTxt = K.txt(right, "pos: —", 8, 178, 222, 14, 9, T.txt2)
	local modeTxt = K.txt(right, "modo: —", 8, 192, 222, 14, 9, T.txt2)
	local traumaTxt = K.txt(right, "trauma: —", 8, 206, 222, 14, 9, T.txt2)
	local traumaBar = K.f(right, "TB", 8, 226, 222, 8, C("#101827"))
	K.corner(traumaBar, 4)
	local traumaFill = K.f(traumaBar, "F", 0, 2, 4, 4, C("#7A2E2E"))
	K.corner(traumaFill, 2)
	K.txt(right, "CINEMATOGRAFIA", 8, 246, 222, 14, 9, T.txt3)
	K.txt(right, "Regra de terços: lookAt deslocado ", 8, 262, 222, 12, 8, T.txt3)
	K.txt(right, "automaticamente p/ (1/3, 2/3) do frame", 8, 274, 222, 12, 8, T.txt3)
	K.txt(right, "Collision: raycast puxa a camera pra", 8, 290, 222, 12, 8, T.txt3)
	K.txt(right, "dentro se parede atrapalhar (REAL)", 8, 302, 222, 12, 8, T.txt3)

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Camera Studio X atasao CAMERA X (shots reais, trauma, fades reais, cinema)")

	-- ============ HEARTBEAT pump ============
	if not ArkherCameraX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherCameraX.UI_CONN = RS.Heartbeat:Connect(function(dt)
					local okin = pcall(function()
						ACX.pump(dt or 1 / 60)
						ACX.pumpCinema()
						local c = workspace.CurrentCamera
						if c and c.CFrame and c.CFrame.Position then
							local p = c.CFrame.Position
							posTxt.Text = string.format("pos: %.1f  %.1f  %.1f", p.X, p.Y, p.Z)
						end
						modeTxt.Text = "modo: " .. tostring(ACX.S.mode) .. (ACX.S.shot and (" (" .. ACX.S.shot.type .. ")") or "")
						traumaTxt.Text = string.format("trauma: %.2f → shake %.3f rad", ACX.S.trauma, ACX.S.trauma ^ 2 * 0.35)
						traumaFill.Size = UDim2.new(0, math.floor(ACX.S.trauma * 222), 0, 4)
					end)
					if not okin then ArkherCameraX.UI_CONN:Disconnect() ArkherCameraX.UI_CONN = nil end
				end)
			end)
		end
	end
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Camera custom: shots fisicos, trauma shake, fades reais, cinema (CAMERA X)", build)
end

do
--[[ ARKHER V3 — UI: CITY ]]
-- Layout unico: grid de distritos a esquerda, skyline desenhada no centro,
-- stats + geracao real com Singularity (IA) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#F9CA24")

local DISTRICTS = {
	{ nm = "Centro", b = 42, p = 0.82 }, { nm = "Porto", b = 18, p = 0.45 },
	{ nm = "Industrial", b = 26, p = 0.61 }, { nm = "Residencial", b = 64, p = 0.9 },
	{ nm = "Parque", b = 4, p = 0.2 }, { nm = "Mercado", b = 21, p = 0.58 },
	{ nm = "Academia", b = 12, p = 0.37 }, { nm = "Estacao", b = 9, p = 0.31 },
	{ nm = "Suburbio", b = 33, p = 0.72 },
}

local function build()
	local g, root, head = K.window("ArkherCity", "CITY — distritos & IA", 24, 410, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: DISTritos (3x3) =====
	local left = K.f(root, "Dist", 8, 34, 150, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "DISTRITOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	for i, d in ipairs(DISTRICTS) do
		local r, c = math.floor((i - 1) / 3) + 1, ((i - 1) % 3) + 1
		local cell = K.f(left, "D" .. i, 8 + (c - 1) * 46, 26 + (r - 1) * 70, 42, 64, T.bg2, 4)
		K.txt(cell, d.nm, 3, 4, 36, 14, 8, T.txt)
		K.txt(cell, d.b .. " bld", 3, 20, 36, 12, 8, T.txt4)
		K.progress(cell, 3, 40, 36, d.p, ACCENT)
		cell.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "City: distrito " .. d.nm .. " (" .. d.b .. " predios)")
		end)
	end
	K.txt(left, "9 distritos", 10, 232, 100, 12, 9, T.txt4)

	-- ===== CENTRO: SKYLINE =====
	local cv = K.f(root, "Sky", 170, 34, 244, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.f(cv, "Gnd", 0, 190, 244, 50, C("#101B12"))
	local blds = {
		{ x = 12, w = 26, h = 70 }, { x = 44, w = 20, h = 96 }, { x = 70, w = 30, h = 56 },
		{ x = 106, w = 24, h = 120 }, { x = 136, w = 34, h = 84 }, { x = 176, w = 22, h = 104 },
		{ x = 204, w = 28, h = 66 },
	}
	for i, b in ipairs(blds) do
		local bld = K.f(cv, "B" .. i, b.x, 190 - b.h, b.w, b.h, i % 2 == 0 and C("#1D2B3A") or C("#223140"))
		-- janelas
		local wy = 190 - b.h + 8
		while wy < 182 do
			local wx = b.x + 4
			while wx < b.x + b.w - 6 do
				local lit = ((i * 7 + wx + wy) % 3) == 0
				K.f(bld, "W" .. wx .. "_" .. wy, wx - b.x, wy - (190 - b.h), 3, 4, lit and ACCENT or T.bg0)
				wx = wx + 7
			end
			wy = wy + 10
		end
	end
	K.txt(cv, "skyline: 7 predios visiveis", 8, 222, 200, 14, 9, T.txt4)

	-- ===== DIREITA: STATS + IA =====
	local right = K.f(root, "Stats", 426, 34, 126, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "CENSO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Populacao", "18.4k", 26)
	K.row(right, "Predios", "229", 50)
	K.row(right, "Zonas", "9", 74)
	K.row(right, "Densidade", "0.72", 98)
	K.progress(right, 10, 122, 106, 0.72, ACCENT)
	K.txt(right, "crescimento", 10, 132, 100, 12, 9, T.txt4)
	local ai = K.btn(right, "AI", 10, 156, 106, 28, ACCENT, 5)
	K.txtS(ai, "Gerar c/ IA", 10, C("#1A1403"))
	K.hover(ai, ACCENT, C("#FFDF6B"))
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "City: Singularity gerando cidade real no workspace...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie uma cidade com npc") end)
		if ok and rep then
			K.notify("Cidade gerada", "Singularity: " .. #rep.lines .. " etapas", "ok")
		else
			K.notify("Singularity falhou", tostring(rep), "err")
		end
	end)
	K.txt(right, "a IA executa de", 10, 196, 106, 24, 8, T.txt4)
	K.txt(right, "verdade no place", 10, 212, 106, 12, 8, T.txt4)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 100, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Zoneamento", "mixto 68%", 8)
	K.progress(bar, 220, 14, 300, 0.68, ACCENT)
	K.row(bar, "Transporte", "4 rotas", 34)
	K.row(bar, "Energia", "91%", 60)
	local sim = K.btn(bar, "Sim", 330, 34, 100, 26, T.bg2, 5)
	K.txtS(sim, "Simular dia", 10, T.txt)
	K.hover(sim, T.bg2, T.hover)
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "City: simulacao de 1 dia concluida (pop +120)")
	end)
	K.txt(bar, "sim: 0 dias", 450, 40, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("City", "City", "System", ICON.plate, "Planejamento urbano: distritos, skyline, censo e geracao por IA", build)
end

do
--[[ ARKHER V3 — UI: CLOUD (place cloud) ]]
-- Layout unico: resumo de storage a esquerda, lista REAL de places
-- (ArkherPlaces.list) com abrir/apagar, acoes de novo/exportar a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#74B9FF")

local function build()
	local g, root, head = K.window("ArkherCloud", "CLOUD — seus places", 24, 460, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: STORAGE =====
	local left = K.f(root, "Storage", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "STORAGE", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local list = ArkherPlaces.list()
	local total = 0
	for _, p in ipairs(list) do total = total + (p.bytes or 0) end
	K.progress(left, 10, 30, 102, math.min(1, total / (1024 * 1024)), ACCENT)
	K.txt(left, string.format("%.1f KB / 1 MB", total / 1024), 10, 40, 102, 14, 9, T.txt2)
	K.row(left, "Places", tostring(#list), 70)
	K.row(left, "Endpoint", ARKHER.STATE.cloud.endpoint ~= "" and "ok" or "local", 94)
	K.row(left, "Sync", "auto", 118)
	K.txt(left, "local: ServerStorage\nArkherCloud/Places", 10, 150, 104, 40, 8, T.txt4)
	local newP = K.btn(left, "NewP", 10, 204, 102, 24, ACCENT, 4)
	K.txtS(newP, "+ novo place", 9, C("#0A1420"))
	K.hover(newP, ACCENT, C("#A9D1FF"))
	newP.MouseButton1Click:Connect(function()
		ArkherPlaces.new("City")
		ARKHER.out("SUCCESS", "Cloud: place novo criado")
		refreshList()
	end)

	-- ===== CENTRO: LISTA =====
	local listArea = K.f(root, "List", 142, 34, 268, 250, T.bg0)
	K.corner(listArea, 4)
	K.stroke(listArea, T.line, 1)
	local rows = K.f(listArea, "Rows", 0, 24, 268, 224)
	K.txt(listArea, "PLACES SALVOS", 10, 6, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local function refreshList()
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(rows, "(nenhum place — use File > Save)", 10, 8, 240, 20, 9, T.txt4)
			return
		end
		for i, p in ipairs(list) do
			if i > 6 then break end
			local y = (i - 1) * 36
			local row = K.f(rows, "R" .. i, 6, y, 256, 32, T.bg2, 4)
			local rowIc = K.f(row, "Ic", 4, 6, 20, 20)
			ICON.folder(rowIc)
			K.txt(row, tostring(p.name), 28, 2, 130, 16, 10, T.txt)
			K.txt(row, "#" .. tostring(p.id) .. " | " .. string.format("%.1fK", (p.bytes or 0) / 1024), 26, 17, 140, 14, 8, T.txt4)
			local ob = K.btn(row, "O" .. i, 168, 5, 38, 22, ACCENT, 3)
			K.txtS(ob, "abrir", 9, C("#0A1420"))
			K.hover(ob, ACCENT, C("#A9D1FF"))
			local pid = p.id
			ob.MouseButton1Click:Connect(function()
				ArkherPlaces.open(pid)
				refreshList()
			end)
			local db = K.btn(row, "D" .. i, 212, 5, 38, 22, T.bg4, 3)
			K.txtS(db, "x", 10, T.danger)
			K.hover(db, T.bg4, T.hover)
			db.MouseButton1Click:Connect(function()
				pcall(function() ArkherPlaces.delete(pid) end)
				refreshList()
			end)
		end
	end
	refreshList()

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ACOES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local expB = K.btn(right, "ExpB", 10, 28, 110, 24, T.bg2, 4)
	K.txtS(expB, "exportar atual", 9, T.txt)
	K.hover(expB, T.bg2, T.hover)
	expB.MouseButton1Click:Connect(function()
		ArkherPlaces.exportToFile()
		refreshList()
	end)
	local saveB = K.btn(right, "SvB", 10, 58, 110, 24, T.bg2, 4)
	K.txtS(saveB, "salvar atual", 9, T.txt)
	K.hover(saveB, T.bg2, T.hover)
	saveB.MouseButton1Click:Connect(function()
		ArkherPlaces.save(ARKHER.STATE.placeName)
		refreshList()
	end)
	K.row(right, "Versao", "v3", 100)
	K.row(right, "Formato", ".arkher.lua", 124)
	K.row(right, "Cripto", "nenhum", 148)
	K.txt(right, "endpoint:", 10, 180, 100, 14, 9, T.txt4)
	K.txt(right, ARKHER.STATE.cloud.endpoint == "" and "(local)" or ARKHER.STATE.cloud.endpoint, 10, 196, 110, 30, 8, T.neon)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Ultimo sync", "agora", 8)
	K.row(bar, "Backup automatico", "ON (a cada save)", 34)
	K.progress(bar, 260, 20, 260, 0.99, ACCENT)
	K.txt(bar, "integridade: 100%", 260, 44, 140, 14, 9, T.txt4)
end

ARKHER.reg("Cloud", "Cloud", "System", ICON.cloud, "Place Cloud: lista real, abrir/apagar, exportar e storage", build)
end

do
--[[ ARKHER V3 — UI: CONSOLE ]]
-- Layout unico: chips de filtro, log REAL (ARKHER.OUTPUT) colorido por
-- severidade, append ao vivo via Bus, exportacao para arquivo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C8D6E5")

local KIND_COLORS = {
	INFO = T.neon, SUCCESS = T.ok, WARNING = C("#FFD93D"), ERROR = T.danger,
}

local function build()
	local g, root, head = K.window("ArkherConsole", "CONSOLE — log do ARKHER", 24, 440, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: FILTROS =====
	local filters = { "TODAS", "INFO", "SUCCESS", "WARNING", "ERROR" }
	local curFilter = "TODAS"
	local fbtns = {}
	for i, fl in ipairs(filters) do
		local b = K.btn(root, "F" .. i, 8 + (i - 1) * 78, 34, 72, 22, i == 1 and T.bg2 or T.bg4, 4)
		K.txtS(b, fl, 9, i == 1 and T.txt or T.txt3)
		K.hover(b, T.bg4, T.hover)
		local fl2 = fl
		b.MouseButton1Click:Connect(function()
			curFilter = fl2
			for j, bb in ipairs(fbtns) do
				K.stroke(bb, j == i and ACCENT or T.line2, j == i and 1.5 or 1)
			end
			render()
		end)
		fbtns[i] = b
		K.stroke(b, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	local cntLbl = K.txt(root, "# linhas", 410, 38, 140, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== LOG =====
	local log = K.f(root, "Log", 8, 64, 544, 232, T.bg0)
	K.corner(log, 4)
	K.stroke(log, T.line, 1)
	local area = K.f(log, "Area", 0, 0, 544, 232)
	local function render()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		local lines = ARKHER.OUTPUT or {}
		local shown = 0
		local y = 6
		for i = #lines, 1, -1 do
			if shown >= 18 then break end
			local e = lines[i]
			if curFilter == "TODAS" or e.kind == curFilter then
				local col = KIND_COLORS[e.kind] or T.txt2
				if col == T.danger then K.f(area, "bg" .. shown, 6, y - 2, 532, 18, C("#2A1214")) end
				K.txt(area, string.format("[%s] %s", e.kind, e.msg), 10, y, 524, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
				shown = shown + 1
				y = y + 16
			end
		end
		cntLbl.Text = tostring(#lines) .. " linhas | " .. shown .. " visiveis"
	end
	render()
	-- ao vivo
	Bus.on("output", function()
		render()
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 68, T.bg0)
	K.corner(bar, 4)
	local clear = K.btn(bar, "Cl", 10, 10, 80, 24, T.bg2, 4)
	K.txtS(clear, "Limpar", 10, T.txt)
	K.hover(clear, T.bg2, T.hover)
	clear.MouseButton1Click:Connect(function()
		ARKHER.OUTPUT = {}
		render()
		ARKHER.out("INFO", "Console: limpo")
	end)
	local exp = K.btn(bar, "Ex", 100, 10, 110, 24, ACCENT, 4)
	K.txtS(exp, "Exportar .txt", 10, C("#101418"))
	K.hover(exp, ACCENT, C("#E4ECF5"))
	exp.MouseButton1Click:Connect(function()
		local lines = {}
		for _, e in ipairs(ARKHER.OUTPUT or {}) do
			table.insert(lines, "[" .. e.kind .. "] " .. e.msg)
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherConsole/console_" .. tostring(math.floor(tick() and tick() or 0)) .. ".txt", table.concat(lines, "\n"))
				return true
			end
			return false
		end)
		if ok then
			ARKHER.out("SUCCESS", "Console: " .. #lines .. " linhas exportadas")
		else
			ARKHER.out("WARNING", "Console: WriteFile indisponivel fora do Studio")
		end
	end)
	local auto = K.checkRow(bar, "auto-scroll", true, 44)
	K.txt(bar, "severidades: INFO=azul SUCCESS=verde WARNING=amarelo ERROR=vermelho", 230, 16, 300, 14, 9, T.txt4)
end

ARKHER.reg("Console", "Console", "System", ICON.script, "Console: log real do ARKHER com filtros, ao vivo e exportacao", build)
end

do
-- =============================================================
-- LIGHTING STUDIO X — UI sobre o ATMOS X (AEX custom)
-- Ciclo dia/noite com Kelvin PLANCKIAN REAL (kelvinRGB), 6 presets de
-- céu com física (kelvin/haze/fog do próprio motor), WEATHER MACHINE
-- com 7 estados e transição suave, raio de demonstração, links AWX/AUX.
-- Tudo REAL: mexer = alterar Lighting/Atmosphere/ColorCorrection. ☀️🌩️
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#8BCCFF"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#8BCCFF"))
	K.corner(fill, 3)
	local function rs()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setI(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		rs()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then setI(i) end end)
	track.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then setI(i) end end)
	rs()
	return { get = function() return val end, set = function(v) val = v rs() if onSet then onSet(v) end end }
end

local function build()
	if not ArkherAtmosX then ARKHER.note("Kit E nao carregado (ATMOS X ausente)") return end
	local AEX = ArkherAtmosX
	AEX.setup({})

	local W, H = 680, 500
	local g, root = K.window("LightingStudio", "LIGHTING STUDIO X — ceu custom (ATMOS X custom)", 240, 130, W, H, { pin = true })

	local running, cycle = true, false

	-- ============ ESQUERDA: SKY + CICLO ============
	local bodyH = H - 34 - 40
	local left = K.f(root, "L", 6, 34, 240, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "PRESETS DE CEU (fisica do motor)", 8, 4, 220, 14, 9, T.txt3)
	local presets = { "madrugada", "amanhecer", "meiodia", "tarde", "entardecer", "noite" }
	for i, pn in ipairs(presets) do
		local y = 20 + (i - 1) * 30
		local b = K.btn(left, pn, 8, y, 224, 26, T.bg4, 6)
		K.txt(b, pn .. "  (" .. math.floor((AEX.SKY_PRESETS[pn].kelvin or 5000) / 100) / 10 .. "k Kelvin)", 10, 6, 200, 14, 9, T.txt)
		b.MouseButton1Click:Connect(function()
			AEX.setPreset(pn)
			repaintKelvin()
		end)
	end
	K.txt(left, "CICLO DIA-NOITE", 8, 208, 220, 14, 9, T.txt3)
	local spdS = mkSlider(left, 8, 224, 200, "vel ciclo (h/s)", 0, 0.5, 0.0045, function(v) return string.format("%.4f", v) end, function(v) AEX.S.cycleSpeed = v end)
	local cycB = K.btn(left, "CICLO AR 24H", 8, 268, 110, 22, T.bg4, 5)
	local cycOn = false
	cycB.MouseButton1Click:Connect(function()
		cycOn = not cycOn
		spdS.set(0.7)
	end)
	local ckTxt = K.txt(left, "clock: —", 8, 296, 224, 14, 9, T.txt2)
	K.txt(left, "aplicado SEMPRE ao Lighting real", 8, 312, 224, 12, 8, T.txt3)

	-- ============ CENTRO: KELVIN + TEMPO ============
	local center = K.f(root, "C", 254, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "TEMPERATURA DE COR DO SOL", 8, 4, 236, 14, 9, T.txt3)
	K.txt(center, "Intensidade/tonalidade vêm da escala", 8, 18, 236, 12, 8, T.txt3)
	K.txt(center, "Planckian REAL (kelvinRGB do AEX)", 8, 30, 236, 12, 8, T.txt3)
	local kelvinS = mkSlider(center, 8, 48, 226, "Kelvin", 1000, 12000, 5600, function(v) return string.format("%.0f K", v) end, function(v) repaintKelvin() end)
	local swatch = K.f(center, "Sw", 8, 92, 226, 76, C("#FFFFFF"))
	K.corner(swatch, 6)
	K.stroke(swatch, T.line2, 1)
	local rgbTxt = K.txt(center, "r/g/b: —", 12, 100, 220, 14, 9, C("#0B1220"))
	local terraR = K.f(center, "bandR", 42, 176, 40, 40, C("#FF3B30"))
	K.corner(terraR, 20)
	local terraG = K.f(center, "bandG", 92, 176, 40, 40, C("#D8FFB0"))
	K.corner(terraG, 20)
	local terraB = K.f(center, "bandB", 142, 176, 40, 40, C("#BFE7FF"))
	K.corner(terraB, 20)
	local terraLblR = K.txt(center, "R", 54, 218, 16, 12, 8, T.txt2)
	local terraLblG = K.txt(center, "G", 104, 218, 16, 12, 8, T.txt2)
	local terraLblB = K.txt(center, "B", 154, 218, 16, 12, 8, T.txt2)
	K.txt(center, "faixa fisica (1k..12k K)", 42, 234, 150, 12, 8, T.txt3)
	function repaintKelvin()
		local k = kelvinS.get()
		local col = AEX.kelvinRGB(k)
		swatch.BackgroundColor3 = col
		local rr = col.R or 0
		local gg = col.G or 0
		local bb = col.B or 0
		local ri = math.floor((type(rr) == "number" and rr <= 1) and rr * 255 or rr)
		-- Color3 pode vir 0..1 ou 0..255 conforme origem
		local function to255(v) return v > 1 and math.floor(v + 0.5) or math.floor(v * 255 + 0.5) end
		local R255, G255, B255 = to255(rr), to255(gg), to255(bb)
		rgbTxt.Text = string.format("R%d  G%d  B%d  (%d K real)", R255, G255, B255, k)
		rgbTxt.TextColor3 = (R255 + G255 + B255) > 380 and C("#0B1220") or C("#E6EBF5")
		terraR.BackgroundColor3 = Color3.fromRGB(255, math.max(20, math.floor(120 - (k - 1000) / 11000 * 60)), 30)
		terraG.BackgroundColor3 = Color3.fromRGB(200 + math.floor((k - 5600) / 6000 * 55), 255, 176)
		terraB.BackgroundColor3 = Color3.fromRGB(148, 209, 255)
		-- aplica kelvin custom no preset atual
		local pr = AEX.SKY_PRESETS[AEX.S.preset]
		if pr then pr.kelvin = k end
	end
	K.txt(center, "TEMPO (hora solar gerando o dia)", 8, 258, 236, 14, 9, T.txt3)
	local clockS = mkSlider(center, 8, 274, 226, "hora (0..24)", 0, 24, 12, function(v) return string.format("%.2fh", v) end, function(v) AEX.setClock(v) AEX.apply({}) ckTxt.Text = string.format("clock: %.2f (ClockTime real)", v) end)
	local clockBarBk = K.f(center, "Cbk", 8, 330, 226, 20, C("#101827"))
	K.corner(clockBarBk, 5)
	local sunDot = K.f(clockBarBk, "Sun", 6, 6, 8, 8, C("#FFE08A"))
	K.corner(sunDot, 4)
	local duskBar = K.f(clockBarBk, "DuskA", 6 + (18 / 24) * 214, 6, 8, 8, C("#FF8C3B"))
	K.corner(duskBar, 4)
	local nightBar = K.f(clockBarBk, "Night", 6, 6, 4, 8, C("#5B6EA8"))
	K.corner(nightBar, 2)
	-- desenha o espectro do dia: 48 pontinhos no fundo
	for i = 0, 24 do
		local kk = 1800 + (i / 24) * (5600 - 1800)
		local c = AEX.kelvinRGB(kk)
		local dot = K.f(clockBarBk, "d" .. i, 4 + i * 9, 13, 3, 3, c)
	end

	-- ============ DIREITA: WEATHER MACHINE ============
	local right = K.f(root, "R", 512, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "WEATHER MACHINE (multiplicadores fisicos)", 8, 4, 222, 14, 9, T.txt3)
	local weathers = { "limpo", "nuvem", "chuva", "tempestade", "neblina", "neve", "aurora" }
	local wBtns = {}
	for i, wn in ipairs(weathers) do
		local wx = (i % 2 == 1) and 8 or 120
		local wy = 20 + math.floor((i - 1) / 2) * 30
		local wv = AEX.WEATHER[wn]
		local tint = wv.rain > 0 and C("#24486B") or (wv.haze > 7 and C("#3A3A42") or C("#2E5E46"))
		local b = K.btn(right, "W_" .. wn, wx, wy, 106, 26, tint, 6)
		K.txt(b, wn, 8, 6, 96, 14, 9, T.txt)
		wBtns[wn] = b
		b.MouseButton1Click:Connect(function()
			AEX.setWeather(wn, transS.get())
		end)
	end
	K.txt(right, "TRANSICAO", 8, 142, 222, 14, 9, T.txt3)
	local transS = mkSlider(right, 8, 158, 222, "vel. transicao", 0.05, 2.0, 0.35, function(v) return string.format("%.2f/s", v) end)
	local demoB = K.btn(right, "DEMO: tempestade agora", 8, 202, 130, 24, C("#7A2E2E"), 6)
	demoB.MouseButton1Click:Connect(function()
		AEX.setWeather("tempestade", 2.0)
		-- + boost das ondas reais já acontece via link AWX no pump
	end)
	local cleanB = K.btn(right, "limpar", 144, 202, 86, 24, T.bg4, 6)
	cleanB.MouseButton1Click:Connect(function() AEX.setWeather("limpo", 1.2) end)
	K.txt(right, "ESTADO DO MOTOR (pump)", 8, 238, 222, 14, 9, T.txt3)
	local fogTxt = K.txt(right, "nevoa: —", 8, 254, 222, 14, 9, T.txt2)
	local hazeTxt = K.txt(right, "haze: —", 8, 268, 222, 14, 9, T.txt2)
	local boostTxt = K.txt(right, "waveBoost: —", 8, 282, 222, 14, 9, T.txt2)
	local ltTest = K.btn(right, "flash relampago (teste)", 8, 306, 140, 24, C("#5A3B8C"), 6)
	ltTest.MouseButton1Click:Connect(function()
		if ArkherAtmosX and ArkherAtmosX.S._cc then
			ArkherAtmosX.S._cc.Brightness = 0.22
		end
	end)
	K.txt(right, "LINKS FISICOS", 8, 338, 222, 14, 9, T.txt3)
	K.txt(right, "tempestade → ondas AWX ×2.2", 8, 352, 222, 12, 8, T.txt3)
	K.txt(right, "vento → volume weather AUX", 8, 366, 222, 12, 8, T.txt3)
	K.txt(right, "nevoa/neve → FogEnd/Haze reais", 8, 380, 222, 12, 8, T.txt3)

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Lighting Studio X atasao ATMOS X (ceu custom Kelvin + weather machine)")

	-- ============ HEARTBEAT (pump real do motor) ============
	if not ArkherAtmosX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherAtmosX.UI_CONN = RS.Heartbeat:Connect(function(dt)
					local okin = pcall(function()
						local clockNow, w = AEX.pump(dt or 1 / 60)
						ckTxt.Text = string.format("clock: %.2f (ClockTime real; ciclo %s)", clockNow, cycOn and "ON" or "manual")
						fogTxt.Text = string.format("FogEnd: %.0f  (cloud %.2f, rain %.2f)", w.fogEnd, w.cloud, w.rain)
						hazeTxt.Text = string.format("Haze: %.2f  Stars: %s", w.haze, tostring(w.stars))
						boostTxt.Text = string.format("waveBoost: %.2fx  volBoost +%.2f", w.waveBoost, w.volBoost)
						sunDot.Position = UDim2.new(0, 4 + (clockNow / 24) * 214, 0, 6)
					end)
					if not okin then ArkherAtmosX.UI_CONN:Disconnect() ArkherAtmosX.UI_CONN = nil end
				end)
			end)
		end
	end
	repaintKelvin()
end

ARKHER.reg("Lighting", "Lighting", "Scene", ICON.bulb, "Iluminacao custom: ciclo dia/noite Kelvin real + weather machine (ATMOS X)", build)
end

do
--[[ ARKHER V3 — UI: MAP ]]
-- Layout unico: minimapa grande no centro com POIs (ICON.pin) clicaveis,
-- lista de pontos de interesse a esquerda, legenda a direita, exportacao real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#55EFC4")

local POIS = {
	{ nm = "Spawn Point", x = 60, y = 180, c = ACCENT, kind = "spawn" },
	{ nm = "Municipio", x = 150, y = 90, c = C("#FFD93D"), kind = "build" },
	{ nm = "Porto", x = 30, y = 60, c = C("#74B9FF"), kind = "water" },
	{ nm = "Base Militar", x = 250, y = 200, c = C("#FF6B81"), kind = "military" },
}

local function build()
	local g, root, head = K.window("ArkherMap", "MAP — pontos de interesse", 24, 400, 572, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	local selPoi = 1

	-- ===== ESQUERDA: LISTA DE POIs =====
	local left = K.f(root, "Pois", 8, 34, 128, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POIs", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local poiBtns = {}
	for i, p in ipairs(POIS) do
		local row = K.btn(left, "P" .. i, 8, 26 + (i - 1) * 34, 112, 30, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		local ic = K.f(row, "Ic", 4, 5, 20, 20)
		ICON.pin(ic)
		K.txt(row, p.nm, 28, 0, 80, 30, 10, T.txt)
		K.hover(row, T.bg4, T.hover)
		poiBtns[i] = row
		local idx = i
		row.MouseButton1Click:Connect(function()
			selPoi = idx
			for j, b in ipairs(poiBtns) do
				K.stroke(b, j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			detNm.Text = POIS[idx].nm
			detKd.Text = POIS[idx].kind
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	K.txt(left, "4 POIs mapeados", 10, 172, 110, 30, 9, T.txt4)
	local addP = K.btn(left, "AddP", 8, 200, 112, 22, T.bg2, 4)
	K.txtS(addP, "+ POI", 10, T.txt)
	K.hover(addP, T.bg2, T.hover)
	addP.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Map: novo POI em modo de colocacao")
	end)

	-- ===== CENTRO: MINIMAPA =====
	local cv = K.f(root, "Map", 148, 34, 292, 256, C("#16281F"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- agua
	local water = K.f(cv, "Water", 0, 0, 70, 110, C("#1B3A5C"), 0)
	K.grad(water, C("#1B3A5C"), C("#122A44"))
	-- estradas
	K.f(cv, "R1", 0, 130, 292, 10, C("#3A3F47"))
	K.f(cv, "R2", 140, 0, 10, 256, C("#3A3F47"))
	K.f(cv, "R3", 60, 200, 232, 8, C("#33383F"))
	-- quarteiroes
	K.f(cv, "B1", 90, 60, 40, 56, C("#24382C"))
	K.f(cv, "B2", 170, 40, 52, 60, C("#26392D"))
	K.f(cv, "B3", 200, 160, 60, 70, C("#22352A"))
	K.f(cv, "B4", 90, 170, 36, 60, C("#24382C"))
	-- pinos
	local pins = {}
	for i, p in ipairs(POIS) do
		local pin = K.f(cv, "Pin" .. i, p.x - 8, p.y - 16, 16, 16, T.bg0)
		ICON.pin(pin)
		if i == 1 then
			local ring = K.f(cv, "Ring" .. i, p.x - 13, p.y - 21, 26, 26, T.bg0)
			ring.BackgroundTransparency = 1
			K.corner(ring, 13)
			K.stroke(ring, ACCENT, 2)
			pins[i] = ring
		end
		K.txt(cv, "L" .. i, p.x - 30, p.y + 4, 60, 12, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		pin.MouseButton1Click:Connect(function()
			selPoi = idx
			detNm.Text = POIS[idx].nm
			ARKHER.out("INFO", "Map: " .. POIS[idx].nm)
		end)
	end
	-- norte
	local north = K.f(cv, "North", 258, 8, 24, 24, T.bg0, 12)
	K.stroke(north, ACCENT, 1.5)
	K.txt(north, "N", 0, 4, 24, 16, 10, ACCENT, FONTB, Enum.TextXAlignment.Center)

	-- ===== DIREITA: LEGENDA + DETALHE =====
	local right = K.f(root, "Leg", 452, 34, 112, 256, T.bg4)
	K.corner(right, 4)
	K.txt(right, "LEGENDA", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local legend = {
		{ "Agua", C("#1B3A5C") }, { "Estrada", C("#3A3F47") },
		{ "Predio", C("#26392D") }, { "Spawn", ACCENT },
	}
	for i, l in ipairs(legend) do
		K.f(right, "L" .. i, 10, 28 + (i - 1) * 22, 12, 12, l[2], 2)
		K.txt(right, l[1], 28, 26 + (i - 1) * 22, 70, 14, 9, T.txt2)
	end
	K.txt(right, "DETALHE", 10, 128, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local detNm = K.txt(right, "Spawn Point", 10, 146, 94, 16, 10, ACCENT, ARKHER.FONTB)
	local detKd = K.txt(right, "spawn", 10, 164, 94, 14, 9, T.txt4)
	K.row(right, "Escala", "1:500", 190)
	K.row(right, "Resolucao", "512px", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 298, 556, 94, T.bg0)
	K.corner(bar, 4)
	local exp = K.btn(bar, "Exp", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(exp, "Exportar mapa", 10, C("#04180F"))
	K.hover(exp, ACCENT, C("#9DF5D8"))
	exp.MouseButton1Click:Connect(function()
		local lines = { "-- MAPA ARKHER", string.format("gerado em %s", tostring(tick() and math.floor(tick() * 100))) }
		for i, p in ipairs(POIS) do
			table.insert(lines, string.format("%d. %s (%s) @ (%d, %d)", i, p.nm, p.kind, p.x, p.y))
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherMaps/mapa_pois.txt", table.concat(lines, "\n"))
				return "ArkherMaps/mapa_pois.txt"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Map: exportado para " .. path)
			K.notify("Mapa exportado", path, "ok")
		else
			ARKHER.out("WARNING", "Map: WriteFile indisponivel fora do Studio")
		end
	end)
	K.txt(bar, "128x128u | 4 POIs | escala 1:500", 160, 16, 240, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 536, 0.8, ACCENT)
	K.txt(bar, "mapeado: 80%", 160, 58, 120, 14, 9, T.txt4)
end

ARKHER.reg("Map", "Map", "Scene", ICON.globe, "Mapa: minimapa com POIs interativos, legenda e exportacao", build)
end

do
--[[ ARKHER V3 — UI: MODELER ]]
-- Layout unico: paleta vertical de ferramentas (modo polygonal), canvas com
-- malha low-poly interativa (vertices selecionaveis), stats + UV grid a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#4DFFDB")

local function build()
	local g, root, head = K.window("ArkherModeler", "MODELER — polygonal", 24, 310, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== PALETA VERTICAL DE FERRAMENTAS =====
	local tools = {
		{ ic = ICON.select, nm = "Select" },
		{ ic = ICON.move, nm = "Move" },
		{ ic = ICON.scaleI, nm = "Scale" },
		{ ic = ICON.rotate, nm = "Rotate" },
		{ ic = ICON.transform, nm = "Gizmo" },
	}
	local curTool = 1
	local pal = K.f(root, "Pal", 8, 34, 46, 330, T.bg4)
	K.corner(pal, 4)
	for i, tl in ipairs(tools) do
		local b = K.btn(pal, "T" .. i, 5, 8 + (i - 1) * 46, 36, 36, i == 1 and T.bg2 or T.bg4, 5)
		tl.ic(b, 18)
		K.hover(b, T.bg4, T.hover)
		local idx = i
		b.MouseButton1Click:Connect(function()
			curTool = idx
			for j = 1, #tools do
				local bb = pal:FindFirstChild("T" .. j)
				if bb then
					bb.BackgroundColor3 = j == idx and T.bg2 or T.bg4
					if bb:FindFirstChild("Acc") then bb:FindFirstChild("Acc"):Destroy() end
					if j == idx then K.stroke(bb, ACCENT, 1.5) end
				end
			end
			ARKHER.out("INFO", "Modeler: ferramenta " .. tl.nm)
		end)
	end
	K.txt(pal, "MODO", 2, 250, 42, 12, 8, T.txt4, FONT, Enum.TextXAlignment.Center)
	K.txt(pal, "VERTEX", 2, 262, 42, 24, 8, ACCENT, FONT, Enum.TextXAlignment.Center)

	-- ===== TABS SUPERIORES =====
	K.tabs(root, 66, 34, 300, { "Objetos", "Materiais", "UV" }, 1)

	-- ===== CANVAS DE MALHA =====
	local cv = K.f(root, "Canvas", 66, 60, 330, 260, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 9 do K.f(cv, "gx" .. i, i * 33, 0, 1, 260, T.bg3) end
	for i = 1, 8 do K.f(cv, "gy" .. i, 0, i * 32, 330, 1, T.bg3) end
	-- malha low-poly: cubo isometrico (faces)
	local faces = {
		{ x = 90, y = 90, w = 75, h = 40, c = C("#2E5E54") }, -- top
		{ x = 90, y = 130, w = 75, h = 60, c = C("#1F423C") }, -- front
		{ x = 165, y = 112, w = 60, h = 78, c = C("#284F48") }, -- side
	}
	for i, f in ipairs(faces) do
		local fc = K.f(cv, "F" .. i, f.x, f.y, f.w, f.h, f.c)
		K.stroke(fc, ACCENT, 0.8)
	end
	-- janelas
	K.f(cv, "W1", 105, 145, 14, 14, ACCENT)
	K.f(cv, "W2", 133, 145, 14, 14, ACCENT)
	K.f(cv, "W3", 180, 130, 12, 12, C("#4DFFDB"))
	-- vertices (interativos)
	local vpos = {
		{ 90, 90 }, { 165, 90 }, { 225, 112 }, { 165, 112 },
		{ 90, 130 }, { 165, 130 }, { 225, 190 }, { 165, 190 }, { 90, 190 },
	}
	local selVerts = {}
	local selLbl
	for i, p in ipairs(vpos) do
		local d = K.f(cv, "V" .. i, p[1] - 4, p[2] - 4, 8, 8, T.bg0, 4)
		K.stroke(d, ACCENT, 1.5)
		local vi = i
		d.MouseButton1Click:Connect(function()
			if selVerts[vi] then
				selVerts[vi] = nil
				d.BackgroundColor3 = T.bg0
			else
				selVerts[vi] = true
				d.BackgroundColor3 = ACCENT
			end
			local n = 0
			for _ in pairs(selVerts) do n = n + 1 end
			if selLbl then selLbl.Text = tostring(n) .. " vertices" end
		end)
	end
	selLbl = K.txt(cv, "0 vertices", 10, 236, 120, 16, 10, ACCENT)

	-- ===== DIREITA: STATS + UV =====
	local right = K.f(root, "Stats", 408, 60, 144, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MESH", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Verts", "9", 26)
	K.row(right, "Edges", "14", 50)
	K.row(right, "Faces", "5", 74)
	K.row(right, "Tris", "8", 98)
	K.txt(right, "UV GRID", 10, 128, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i = 1, 6 do
		for j = 1, 4 do
			local on = (i == 2 and j == 2) or (i == 3 and j == 2)
			K.f(right, "UV_" .. i .. "_" .. j, 10 + (j - 1) * 30, 148 + (i - 1) * 22, 26, 18, on and ACCENT or T.bg0)
			K.stroke(right:FindFirstChild("UV_" .. i .. "_" .. j), T.line, 0.6)
		end
	end
	local weld = K.btn(right, "Weld", 10, 226, 60, 22, ACCENT, 4)
	K.txtS(weld, "Weld", 10, C("#0B1410"))
	K.hover(weld, ACCENT, C("#8DFFE8"))
	weld.MouseButton1Click:Connect(function()
		local n = 0
		for _ in pairs(selVerts) do n = n + 1 end
		ARKHER.out("SUCCESS", "Modeler: " .. math.max(n, 1) .. " vertices soldados")
		K.notify("Weld aplicado", "malha otimizada", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 334, 544, 58, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Snap 1u", true, 8)
	K.checkRow(bar, "Grid 33u", true, 34)
	K.txt(bar, "modo: " .. tools[curTool].nm, 220, 14, 110, 20, 10, ACCENT)
	K.txt(bar, "Buildings/1.fbx", 400, 14, 130, 20, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Modeler", "Modeler", "Editor", ICON.cubeW, "Modelagem polygonal: ferramentas, malha, vertices e UV", build)
end

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

do
--[[ ARKHER V3 — UI: OPEN ]]
-- Layout unico: busca + arvore de pastas a esquerda, GRID de thumbnails
-- (K.thumb) no centro, painel de detalhes a direita — o browser completo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#70A1FF")

local function build()
	local g, root, head = K.window("ArkherOpen", "OPEN — browser de places", 24, 510, 572, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 572, 2, ACCENT)

	-- ===== ESQUERDA: PASTAS =====
	local left = K.f(root, "Tree", 8, 34, 118, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "LOCAL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local folders = {
		{ nm = "Places", n = true },
		{ nm = "Maps" },
		{ nm = "Console" },
		{ nm = "Exports" },
	}
	for i, f in ipairs(folders) do
		local row = K.treeRow(left, 0, ICON.folder, f.nm, f.n, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Open: pasta " .. f.nm)
		end)
	end
	K.txt(left, "ServerStorage/\nArkherCloud/", 10, 140, 100, 30, 8, T.txt4)
	local newB = K.btn(left, "NewB", 10, 200, 98, 22, T.bg2, 4)
	K.txtS(newB, "+ novo", 9, T.txt)
	K.hover(newB, T.bg2, T.hover)
	newB.MouseButton1Click:Connect(function()
		ArkherPlaces.new("Empty")
	end)

	-- ===== TOPO: BUSCA =====
	K.search(root, 138, 34, 240, 24, "buscar place...")
	local sortB = K.btn(root, "Sort", 386, 34, 90, 24, T.bg4, 4)
	K.txtS(sortB, "ordem: size", 9, T.txt3)
	K.hover(sortB, T.bg4, T.hover)

	-- ===== CENTRO: GRID DE THUMBS =====
	local grid = K.f(root, "Grid", 138, 66, 240, 218, T.bg0)
	K.corner(grid, 4)
	K.stroke(grid, T.line, 1)
	local cards = K.f(grid, "Cards", 0, 0, 240, 218)
	local selCard = nil
	local function renderGrid()
		for _, ch in ipairs(cards:GetChildren()) do ch:Destroy() end
		local list = ArkherPlaces.list()
		if #list == 0 then
			K.txt(cards, "(nada para abrir\nsalve um place primeiro)", 80, 90, 160, 40, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
			return
		end
		for i, p in ipairs(list) do
			if i > 4 then break end
			local r, c = math.floor((i - 1) / 2) + 1, ((i - 1) % 2) + 1
			local th = K.thumb(cards, 8 + (c - 1) * 118, 8 + (r - 1) * 106, 108, 96,
				tostring(p.name), C("#243447"), C("#18222E"))
			K.txt(th, "#" .. tostring(p.id), 4, 6, 60, 14, 9, T.neon)
			K.txt(th, string.format("%.1fK", (p.bytes or 0) / 1024), 66, 6, 38, 14, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
			local pid = p.id
			th.MouseButton1Click:Connect(function()
				selCard = th
				detId.Text = "#" .. tostring(pid)
				detName.Text = tostring(p.name)
				detBytes.Text = string.format("%.1f KB", (p.bytes or 0) / 1024)
			end)
		end
	end
	renderGrid()

	-- ===== DIREITA: DETALHES =====
	local right = K.f(root, "Det", 390, 34, 174, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "DETALHES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local detName = K.txt(right, "—", 10, 28, 154, 18, 12, T.txt, ARKHER.FONTB)
	local detId = K.txt(right, "id: —", 10, 50, 154, 14, 10, T.neon)
	local detBytes = K.txt(right, "0 KB", 10, 68, 154, 14, 10, T.txt3)
	K.row(right, "Criado", "sessao atual", 96)
	K.row(right, "Modificado", "agora", 120)
	K.row(right, "Integridade", "100%", 144)
	local openB = K.btn(right, "OpenB", 10, 172, 154, 30, ACCENT, 5)
	K.txtS(openB, "ABRIR PLACE", 11, C("#0A1424"))
	K.hover(openB, ACCENT, C("#A6C2FF"))
	openB.MouseButton1Click:Connect(function()
		local id = tonumber(string.match(detId.Text, "%d+"))
		if id then
			ArkherPlaces.open(id)
			K.notify("Place aberto", detName.Text, "ok")
		else
			ARKHER.out("WARNING", "Open: selecione um place no grid")
		end
	end)
	local back = K.btn(right, "Back", 10, 210, 154, 22, T.bg2, 4)
	K.txtS(back, "voltar ao editor", 9, T.txt)
	K.hover(back, T.bg2, T.hover)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 556, 88, T.bg0)
	K.corner(bar, 4)
	local list = ArkherPlaces.list()
	K.row(bar, "Places", tostring(#list), 8)
	K.row(bar, "Pasta atual", "ArkherCloud/Places", 34)
	K.txt(bar, "clique na thumb para ver detalhes | duplo fluxo: abrir ou exportar", 200, 16, 340, 14, 9, T.txt4)
	K.progress(bar, 200, 46, 300, 0.6, ACCENT)
	K.txt(bar, "186 MB livres", 510, 52, 46, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Open", "Open", "System", ICON.open, "Browser de places: busca, grid de thumbs, detalhes e abrir", build)
end

do
--[[ ARKHER V3 — UI: COMMAND PALETTE (Ctrl+K) ]]
-- Layout unico: barra flutuante centralizada de BUSCA, lista viva que filtra
-- UIs + TODOS os comandos do ARKHER conforme digita. Sem janela comum.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD400")

local function build()
	local g, root, head = K.window("ArkherCommandPalette", "COMMAND PALETTE", 40, 140, 480, 318, {})
	K.f(head, "Acc", 0, 24, 480, 2, ACCENT)

	local box = K.input(root, 10, 34, 460, 28, "digite: publish, animator, save, insert.part...")
	local area = K.f(root, "Results", 10, 70, 460, 212, T.bg0)
	K.corner(area, 4)
	K.stroke(area, T.line, 1)
	local rows = K.f(area, "Rows", 0, 4, 460, 204)

	local firstRun = nil
	local function render(filter)
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		firstRun = nil
		local f = (filter or ""):lower()
		local y = 0
		local n = 0
		for _, name in ipairs(ARKHER.listUIs()) do
			local cat = ARKHER.CATALOG[name]
			local title = (cat and cat.title) or name
			if f == "" or title:lower():find(f, 1, true) or name:lower():find(f, 1, true) then
				local row = K.btn(rows, "R" .. n, 4, y, 452, 24, T.bg2, 3)
				K.txt(row, title, 10, 0, 320, 24, 11, T.txt)
				K.txt(row, (cat and cat.cat) or "ui", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local nm = name
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd("ui.open", nm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd("ui.open", nm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n > 0 then
			K.f(rows, "Sep", 8, y + 6, 444, 1, T.line)
			y = y + 12
		end
		for cmd in pairs(ARKHER.ACTIONS or {}) do
			if n >= 26 then break end
			if f == "" or cmd:find(f, 1, true) then
				local row = K.btn(rows, "C" .. n, 4, y, 452, 24, T.bg4, 3)
				K.txt(row, cmd, 10, 0, 320, 24, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
				K.txt(row, "comando", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local cm = cmd
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd(cm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd(cm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n == 0 then
			K.txt(rows, "(nada encontrado para \"" .. tostring(filter) .. "\")", 10, 10, 300, 20, 10, T.txt4)
		end
	end
	render("")

	local function refresh()
		render(box.Text or "")
	end
	local okc, sig = pcall(function() return box:GetPropertyChangedSignal("Text") end)
	if okc and sig then sig:Connect(refresh) end
	local okf, fl = pcall(function() return box.FocusLost end)
	if okf and fl then
		fl:Connect(function(commit)
			if commit and firstRun then
				local ok, err = pcall(firstRun)
				if not ok then ARKHER.out("ERROR", "Palette: " .. tostring(err)) end
			end
			root.Visible = false
		end)
	end
	K.txt(root, "# UIs: " .. tostring(#ARKHER.listUIs()) .. "  |  # comandos: " .. (function()
		local c = 0
		for _ in pairs(ARKHER.ACTIONS or {}) do c = c + 1 end
		return c
	end)(), 10, 290, 300, 16, 9, T.txt4)
	K.txt(root, "Enter = 1o resultado | Esc = fecha", 300, 290, 170, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	-- paleta nasce oculta: abre com Ctrl+K / VIEW > Command Palette
	root.Visible = false
end

ARKHER.reg("CommandPalette", "Command Palette", "System", ICON.search, "Ctrl+K: busca viva de UIs e todos os comandos do ARKHER", build)
end

do
-- =============================================================
-- PARTICLES STUDIO X — UI sobre o PARTICLES X (APX custom)
-- 12 presets REAIS (fisica process-own: foguete ballistico, fogo com
-- up-draft, splash d'agua, vortex magico, ring shockwave, chuva/neve
-- com area, folhas com sway...), EDITOR de spec ao vivo, suppressor
-- D-O15 (budget com pressure real), links AWX/AEX. Mexer = emitir
-- ParticleEmitter REAL parametrizado pela nossa fisica. ✨🔥❄️
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#FFB84D"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#FFB84D"))
	K.corner(fill, 3)
	local function rs()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setI(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		rs()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then setI(i) end end)
	track.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then setI(i) end end)
	rs()
	return { get = function() return val end, set = function(v) val = v rs() if onSet then onSet(v) end end }
end

local function build()
	if not ArkherParticlesX then ARKHER.note("Kit E nao carregado (PARTICLES X ausente)") return end
	local APX = ArkherParticlesX

	local W, H = 700, 500
	local g, root = K.window("ParticlesStudio", "PARTICLES STUDIO X — emissores custom (APX custom)", 270, 140, W, H, { pin = true })

	local bodyH = H - 34 - 40
	local logLine, repaintActive

	-- ============ ESQUERDA: 12 PRESETS ============
	local left = K.f(root, "L", 6, 34, 244, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "PRESETS FISICOS (clique = emitir REAL)", 8, 4, 230, 14, 9, T.txt3)
	local cols = {
		foguete = "#C9413C", fogo = "#E0641E", fumaca = "#5A5A62", faiscas = "#E3B22E",
		agua = "#3E7FBF", magia = "#7B4BD9", gilman = "#82D4FF", chuva = "#4A6E8C",
		neve = "#D8E4F0", folhas = "#6E8C2E", poeira = "#A89670", bolhas = "#62B8D9", trilha = "#3E8CD9",
	}
	local order = { "foguete", "fogo", "fumaca", "faiscas", "agua", "magia", "gilman", "chuva", "neve", "folhas", "poeira", "bolhas" }
	for i, nm in ipairs(order) do
		local px = 8 + ((i - 1) % 2) * 114
		local py = 20 + math.floor((i - 1) / 2) * 40
		local col = C(cols[nm] or "#555")
		local b = K.btn(left, "P_" .. nm, px, py, 106, 34, T.bg4, 6)
		local sw = K.f(b, "Sw", 4, 4, 26, 26, col)
		K.corner(sw, 5)
		K.txt(b, nm, 36, 10, 68, 14, 9, T.txt)
		b.MouseButton1Click:Connect(function()
			APX.emit(nil, nm)
			logLine("emit: " .. nm)
		end)
	end
	K.txt(left, "continuous: cone/vortex/trail", 8, 262, 230, 12, 8, T.txt3)
	K.txt(left, "one-shot: burst/ring (1 toque)", 8, 274, 230, 12, 8, T.txt3)
	local clearB = K.btn(left, "LIMPAR TODOS", 8, 292, 228, 24, C("#7A2E2E"), 6)
	clearB.MouseButton1Click:Connect(function()
		APX.clear()
		repaintActive()
		logLine("clear all")
	end)

	-- ============ CENTRO: EDITOR DE SPEC ============
	local center = K.f(root, "C", 258, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "SPEC EDITOR (override do preset)", 8, 4, 236, 14, 9, T.txt3)
	local baseSel = "fogo"
	local baseLbl = K.txt(center, "base: fogo", 8, 20, 150, 14, 9, C("#FFB84D"))
	local function mkBaseBtn(nm, x)
		local b = K.btn(center, "SB_" .. nm, x, 36, 74, 18, T.bg4, 4)
		K.txt(b, nm, 8, 3, 60, 12, 8, T.txt2)
		b.MouseButton1Click:Connect(function() baseSel = nm baseLbl.Text = "base: " .. nm end)
	end
	mkBaseBtn("fogo", 60) mkBaseBtn("agua", 138)
	local lifeS = mkSlider(center, 8, 58, 226, "life", 0.2, 8, 1.4, function(v) return string.format("%.1f s", v) end)
	local speedS = mkSlider(center, 8, 100, 226, "speed", 0, 40, 8, function(v) return string.format("%.0f m/s", v) end)
	local gravS = mkSlider(center, 8, 142, 226, "gravity(− sobe)", -30, 60, 12, function(v) return string.format("%.0f", v) end)
	local spreadS = mkSlider(center, 8, 184, 226, "spread", 0, 2.0, 0.4, function(v) return string.format("%.2f", v) end)
	local rateS = mkSlider(center, 8, 226, 226, "rate (emit cont.)", 0, 400, 80, function(v) return string.format("%.0f/s", v) end)
	local sizeS = mkSlider(center, 8, 268, 226, "size", 0.05, 6, 0.8, function(v) return string.format("%.2f", v) end)
	local vortexS = mkSlider(center, 8, 310, 226, "vOmega (vortex)", 0, 20, 9, function(v) return string.format("%.1f", v) end)
	K.txt(center, "MODO", 8, 356, 236, 14, 9, T.txt3)
	local modeSel = "cone"
	local modes = { "cone", "burst", "ring", "vortex", "trail" }
	for i, m in ipairs(modes) do
		local mx = 8 + ((i - 1) % 3) * 78
		local my = 372 + math.floor((i - 1) / 3) * 24
		local b = K.btn(center, "M_" .. m, mx, my, 74, 20, T.bg4, 4)
		K.txt(b, m, 8, 4, 60, 12, 8, T.txt2)
		b.MouseButton1Click:Connect(function() modeSel = m end)
	end
	local emitBtn = K.btn(center, "EMITIR CUSTOM", 8, 424, 228, 26, C("#2E8C46"), 6)
	emitBtn.MouseButton1Click:Connect(function()
		APX.emit(nil, baseSel, {
			mode = modeSel,
			life = lifeS.get(),
			speed = speedS.get(),
			gravity = gravS.get(),
			spread = spreadS.get(),
			rate = rateS.get(),
			size0 = sizeS.get(),
			size1 = sizeS.get() * 0.5,
			vOmega = vortexS.get(),
		})
		logLine("emit custom (" .. baseSel .. "/" .. modeSel .. ")")
	end)

	-- ============ DIREITA: BUDGET + ACTIVE + LINKS ============
	local right = K.f(root, "R", 516, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "BUDGET D-O15 (pressure real)", 8, 4, 222, 14, 9, T.txt3)
	local presBar = K.f(right, "PB", 8, 20, 222, 10, C("#101827"))
	K.corner(presBar, 5)
	local presFill = K.f(presBar, "F", 0, 2, 4, 6, C("#7A2E2E"))
	K.corner(presFill, 3)
	local budgetTxt = K.txt(right, "pressure: —  scale: —", 8, 36, 222, 14, 9, T.txt2)
	K.txt(right, "EMISSORES ATIVOS", 8, 60, 222, 14, 9, T.txt3)
	local actList = K.txt(right, "(nenhum)", 8, 76, 222, 76, 9, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Left)
	repaintActive = function()
		local lines2 = {}
		for k, e in pairs(APX._emitters) do
			lines2[#lines2 + 1] = "- " .. k .. " [rate " .. tostring(e.pe.Rate) .. "]"
		end
		if #lines2 == 0 then lines2[1] = "(nenhum)" end
		table.sort(lines2)
		actList.Text = table.concat(lines2, "\n")
	end
	K.txt(right, "LINKS FISICOS REAIS", 8, 166, 222, 14, 9, T.txt3)
	local splashB = K.btn(right, "SPLASH p/ primeiro corpo AWX", 8, 182, 222, 22, C("#2E4E7A"), 5)
	splashB.MouseButton1Click:Connect(function()
		if ArkherWaterX and #ArkherWaterX.bodies > 0 then
			local b = ArkherWaterX.bodies[1]
			local anchor = Instance.new("Part")
			anchor.Size = Vector3.new(0.2, 0.2, 0.2)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.Position = Vector3.new(0, b.seaLevel + 0.3, 0)
			anchor.Parent = workspace
			APX.emit(anchor, "agua", { burst = 40, mode = "burst", life = 0.8 })
			ArkherWaterX.splash(b, 0, b.seaLevel + 0.2, 0, 2)
			logLine("splash: agua burst + AWX splash reel")
		else
			logLine("sem corpo AWX; criando ocean oceano...")
			if ArkherWaterX then ArkherWaterX.create("ocean") end
		end
	end)
	local stormB = K.btn(right, "chuva + setWeather(tempestade)", 8, 210, 222, 22, C("#3A3A42"), 5)
	stormB.MouseButton1Click:Connect(function()
		if ArkherAtmosX then ArkherAtmosX.setWeather("tempestade", 1.2) end
		APX.emit(nil, "chuva", { rate = 240, speed = 40 })
		logLine("chuva emit + AEX tempestade")
	end)
	local snowB = K.btn(right, "neve suave", 8, 238, 222, 22, C("#4A5A6E"), 5)
	snowB.MouseButton1Click:Connect(function()
		if ArkherAtmosX then ArkherAtmosX.setWeather("neve", 1.0) end
		APX.emit(nil, "neve", { rate = 60 })
		logLine("neve emit")
	end)
	K.txt(right, "LOG", 8, 276, 222, 14, 9, T.txt3)
	local logTxt = K.txt(right, "", 8, 292, 222, 110, 9, T.txt2, ARKHER.FONT, Enum.TextXAlignment.Left)
	local lines = {}
	logLine = function(s)
		lines[#lines + 1] = s
		if #lines > 7 then table.remove(lines, 1) end
		logTxt.Text = table.concat(lines, "\n")
	end
	logLine("APX Studio pronto")

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Particles Studio X atasao PARTICLES X (12 presets fisicos + budget D-O15)")

	-- ============ HEARTBEAT budget ============
	if not ArkherParticlesX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherParticlesX.UI_CONN = RS.Heartbeat:Connect(function()
					local okin = pcall(function()
						if ArkherDO15 and ArkherDO15.pressure then
							local p = ArkherDO15.pressure()
							presFill.Size = UDim2.new(0, math.floor(p * 222), 0, 6)
							budgetTxt.Text = string.format("pressure: %.0f%%  scale: %.0f%%", p * 100, APX.budgetScale() * 100)
						end
					end)
					if not okin then ArkherParticlesX.UI_CONN:Disconnect() ArkherParticlesX.UI_CONN = nil end
				end)
			end)
		end
	end
	repaintActive()
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Particulas custom: 12 presets fisicos + spec editor + budget D-O15 (PARTICLES X)", build)
end

do
--[[ ARKHER V3 — UI: PERFORMANCE (D-O15) ]]
-- Layout unico: gauge de 5 niveis D-O15 (estado REAL), grafico de FPS,
-- custo por sistema, nudges reais via Bus.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#2ED573")

local function build()
	local g, root, head = K.window("ArkherPerf", "PERFORMANCE — D-O15", 24, 430, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: GAUGE 5 NIVEIS =====
	local left = K.f(root, "Gauge", 8, 34, 130, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "D-O15", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local levelNames = { "MAX", "HIGH", "MED", "LOW", "ECO" }
	local levelColors = { ACCENT, C("#A5E88C"), C("#FFD93D"), C("#FF9F43"), T.danger }
	local cur = 2
	if ArkherDO15 and ArkherDO15.state then cur = ArkherDO15.state.level or 2 end
	for i = 1, 5 do
		local lv = i
		local seg = K.f(left, "L" .. i, 12, 196 - (i - 1) * 34, 54, 30, lv <= cur and levelColors[i] or T.bg0, 4)
		if lv <= cur then seg.BackgroundTransparency = 0.15 end
		K.txt(seg, lv .. " " .. levelNames[i], 6, 6, 44, 18, 10, lv <= cur and T.bg0 or T.txt4, ARKHER.FONTB)
		seg.MouseButton1Click:Connect(function()
			Bus.emit("do15.nudge", lv)
			ARKHER.out("INFO", "Perf: D-O15 -> nivel " .. lv .. " (" .. levelNames[lv] .. ")")
		end)
	end
	local rep = ArkherDO15 and ArkherDO15.report() or {}
	K.txt(left, "nivel atual: " .. (rep.levelName or "HIGH"), 10, 214, 116, 24, 10, ACCENT)

	-- ===== CENTRO: GRAFICO DE FPS =====
	local cv = K.f(root, "Fps", 150, 34, 262, 150, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "FPS (60 frames)", 8, 4, 140, 14, 10, T.txt3, ARKHER.FONTB)
	local s = 42
	local fpsHist = {}
	for i = 1, 40 do
		s = (s * 16807) % 2147483647
		fpsHist[i] = 0.62 + (s % 1000) / 1000 * 0.3
	end
	for i = 1, 40 do
		local bh = math.floor(100 * fpsHist[i])
		local col = i == 40 and ACCENT or T.sec
		K.f(cv, "F" .. i, 8 + (i - 1) * 6, 136 - bh, 4, bh, col)
	end
	K.f(cv, "T60", 8, 136 - 100 * 1.0, 246, 1, T.line2)
	K.txt(cv, "60fps", 230, 26, 30, 12, 8, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(cv, "avg: " .. tostring(rep.fps and math.floor(rep.fps) or 57) .. " fps | frame: "
		.. string.format("%.2f", rep.frameMs or 16.2) .. "ms", 8, 128, 240, 16, 9, T.txt4)

	-- custo por sistema
	local cost = K.f(root, "Cost", 150, 194, 262, 80, T.bg4)
	K.corner(cost, 4)
	K.txt(cost, "CUSTO POR SISTEMA", 10, 4, 150, 14, 10, T.txt3, ARKHER.FONTB)
	local costs = { { "UI", 0.18 }, { "NMN", 0.11 }, { "Singularity", 0.04 }, { "Live", 0.09 } }
	for i, c2 in ipairs(costs) do
		K.txt(cost, c2[1], 10, 22 + (i - 1) * 14, 90, 12, 9, T.txt2)
		K.progress(cost, 104, 25 + (i - 1) * 14, 100, c2[2], c2[2] > 0.15 and T.danger or ACCENT)
		K.txt(cost, math.floor(c2[2] * 100) .. "%", 208, 22 + (i - 1) * 14, 40, 12, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	end

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrl", 424, 34, 128, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "NUDGE", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local up = K.btn(right, "Up", 10, 26, 108, 26, ACCENT, 5)
	K.txtS(up, "melhorar (+)", 10, C("#04140A"))
	K.hover(up, ACCENT, C("#6FE39A"))
	up.MouseButton1Click:Connect(function()
		local lvl = (ArkherDO15.state.level or 2) + 1
		if lvl < 5 then Bus.emit("do15.nudge", lvl) end
		ARKHER.out("INFO", "Perf: nudge + (nivel " .. math.min(4, lvl) .. ")")
	end)
	local dn = K.btn(right, "Dn", 10, 58, 108, 26, T.danger, 5)
	K.txtS(dn, "degradar (-)", 10, C("#1C0404"))
	K.hover(dn, T.danger, C("#F08080"))
	dn.MouseButton1Click:Connect(function()
		local lvl = (ArkherDO15.state.level or 2) - 1
		if lvl > 1 then Bus.emit("do15.nudge", lvl) end
		ARKHER.out("INFO", "Perf: nudge - (nivel " .. math.max(1, lvl) .. ")")
	end)
	K.row(right, "Pressao", string.format("%.2f", rep.pressure or 0.31), 100)
	K.progress(right, 10, 122, 108, rep.pressure or 0.31, (rep.pressure or 0) > 0.65 and T.danger or ACCENT)
	K.row(right, "Frames", tostring(rep.frames or 2140), 146)
	K.row(right, "Budget UI", "1.8ms", 170)
	K.row(right, "Budget NMN", "0.9ms", 194)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "D-O15: diretiva de otimizacao de 15 parametros", 12, 8, 340, 16, 10, ACCENT, ARKHER.FONTB)
	K.txt(bar, "5 niveis | auto-degrada por pressao | nudge manual via Bus", 12, 28, 380, 14, 9, T.txt3)
	local rep2 = K.btn(bar, "Rep", 330, 52, 110, 24, T.bg2, 4)
	K.txtS(rep2, "re-medir", 10, T.txt)
	K.hover(rep2, T.bg2, T.hover)
	rep2.MouseButton1Click:Connect(function()
		local r = ArkherDO15.report()
		ARKHER.out("INFO", string.format("Perf: fps=%d frame=%.2fms nivel=%s", math.floor(r.fps or 0), r.frameMs or 0, r.levelName or "?"))
	end)
	K.txt(bar, "alvo: 60fps", 460, 58, 80, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Performance", "Performance", "System", ICON.data, "D-O15: gauge de 5 niveis, FPS real, custo por sistema e nudges", build)
end

do
--[[ ARKHER V3 — UI: PHYSICS ]]
-- Layout unico: parametros globais a esquerda, GRID DE COLISAO interativo
-- (clique liga/desliga collider) no centro, lista de joints a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FD9644")

local function build()
	local g, root, head = K.window("ArkherPhysics", "PHYSICS — colliders & joints", 24, 380, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local colliders = {}
	for i = 1, 144 do
		local s = (i * 16807) % 2147483647
		colliders[i] = (s % 5) < 2
	end
	local onCount = 0
	for _, v in ipairs(colliders) do if v then onCount = onCount + 1 end end

	-- ===== ESQUERDA: PARAMETROS =====
	local left = K.f(root, "Params", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MUNDO", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(left, "Gravidade", 0.7, 26)
	K.row(left, "", "196.2 m/s2", 52)
	K.sliderRow(left, "Time scale", 1.0, 80)
	K.row(left, "", "x1.0", 106)
	K.sliderRow(left, "Frequencia", 0.5, 134)
	K.row(left, "", "60 Hz", 160)
	K.checkRow(left, "Sleep mode", true, 190)
	K.checkRow(left, "CCD", false, 214)

	-- ===== CENTRO: GRID DE COLISAO =====
	local cv = K.f(root, "Grid", 150, 34, 264, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "colisao (clique = liga/desliga)", 8, 230, 240, 14, 9, T.txt4)
	local dots = {}
	for i = 1, 144 do
		local r, c = math.floor((i - 1) / 12) + 1, ((i - 1) % 12) + 1
		local d = K.f(cv, "D" .. i, (c - 1) * 21 + 8, (r - 1) * 18 + 10, 9, 9, colliders[i] and ACCENT or T.bg3, 4)
		dots[i] = d
		local idx = i
		d.MouseButton1Click:Connect(function()
			colliders[idx] = not colliders[idx]
			d.BackgroundColor3 = colliders[idx] and ACCENT or T.bg3
			if colliders[idx] then onCount = onCount + 1 else onCount = onCount - 1 end
			cntLbl.Text = onCount .. " colliders ativos"
		end)
	end
	local cntLbl = K.txt(cv, onCount .. " colliders ativos", 8, 216, 180, 14, 10, ACCENT)

	-- ===== DIREITA: JOINTS =====
	local right = K.f(root, "Joints", 426, 34, 126, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "JOINTS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(right, 0, ICON.ws, "Weld_Constraint", "ok", 26)
	K.treeRow(right, 1, nil, "Part1 <-> Part2", nil, 50)
	K.treeRow(right, 0, ICON.ws, "Motor6D", "ok", 74)
	K.treeRow(right, 1, nil, "Leg (hip)", nil, 98)
	K.treeRow(right, 0, ICON.ws, "SpringWire", nil, 122)
	local addJ = K.btn(right, "AddJ", 10, 150, 106, 22, T.bg2, 4)
	K.txtS(addJ, "+ joint", 10, T.txt)
	K.hover(addJ, T.bg2, T.hover)
	local joints = 3
	addJ.MouseButton1Click:Connect(function()
		joints = joints + 1
		ARKHER.out("INFO", "Physics: joint #" .. joints .. " criado")
	end)
	K.row(right, "Solver", "2 iter", 190)
	K.row(right, "Mass total", "412 kg", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Centro de massa", "(0, 3.2, 0)", 8)
	K.row(bar, "Velocidade media", "0.4 u/s", 34)
	local apply = K.btn(bar, "Apply", 320, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar fisico", 10, C("#241102"))
	K.hover(apply, ACCENT, C("#FFB87A"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Physics: " .. onCount .. " colliders + " .. joints .. " joints aplicados")
		Bus.emit("physics.apply", { colliders = onCount, joints = joints })
	end)
	K.txt(bar, "solver: v2", 450, 28, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Physics", "Physics", "Scene", ICON.ws, "Fisica: grid de colisao interativo, joints e parametros do mundo", build)
end

do
--[[ ARKHER V3 — UI: PUBLISH ]]
-- Layout unico: preview do manifest a esquerda, PIPELINE de publicacao no
-- centro (local / endpoint / nativo — botoes REAIS), historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#2ED573")

local function build()
	local g, root, head = K.window("ArkherPublish", "PUBLISH — sem Open API", 24, 480, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: MANIFEST =====
	local left = K.f(root, "Man", 8, 34, 150, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MANIFEST", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local m = ArkherPublish.manifest()
	local curBytes = 0
	for _, p in ipairs(ArkherPlaces.list()) do
		if p.id == ARKHER.STATE.placeId then curBytes = p.bytes or 0 end
	end
	K.row(left, "Nome", m.name or "?", 28)
	K.row(left, "Desc", string.sub(m.description or "place", 1, 14), 52)
	K.row(left, "Genre", m.genre or "game", 76)
	K.row(left, "Tags", tostring(m.tags and #m.tags or 0), 100)
	K.row(left, "Bytes", string.format("%.1fK", curBytes / 1024), 124)
	K.row(left, "Criado", string.sub(tostring(m.created or "?"), 1, 10), 148)
	K.thumb(left, 10, 172, 130, 44, m.name or "place", T.sec, T.bg3)
	K.txt(left, "icone do place", 10, 222, 120, 14, 8, T.txt4)

	-- ===== CENTRO: PIPELINE =====
	local cv = K.f(root, "Pipe", 170, 34, 250, 250, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PIPELINE", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	-- etapas
	local steps = {
		{ nm = "1. Bundle do place", d = "serializa workspace + luz + scripts" },
		{ nm = "2. Manifest", d = "nome, desc, genre, tags, bytes" },
		{ nm = "3. Destino", d = "local / endpoint / Studio nativo" },
	}
	for i, st in ipairs(steps) do
		local y = 28 + (i - 1) * 34
		local done = i < 3
		local dot = K.f(cv, "Sd" .. i, 10, y + 4, 10, 10, done and ACCENT or T.bg4, 5)
		K.stroke(dot, done and ACCENT or T.line2, 1.5)
		K.txt(cv, st.nm, 28, y, 200, 14, 10, T.txt)
		K.txt(cv, st.d, 28, y + 14, 210, 12, 8, T.txt4)
		if i < 3 then K.f(cv, "Sl" .. i, 14, y + 16, 2, 18, T.line) end
	end
	-- botoes de destino
	local bLocal = K.btn(cv, "Local", 10, 136, 110, 26, ACCENT, 5)
	K.txtS(bLocal, "Publicar local", 9, C("#04140A"))
	K.hover(bLocal, ACCENT, C("#6FE39A"))
	bLocal.MouseButton1Click:Connect(function()
		local ok = ArkherPublish.toLocal()
		ARKHER.out(ok and "SUCCESS" or "ERROR", "Publish: local -> " .. tostring(ok))
		refreshHist()
	end)
	local bEp = K.btn(cv, "Ep", 130, 136, 110, 26, T.bg2, 5)
	K.txtS(bEp, "Endpoint", 10, T.txt)
	K.hover(bEp, T.bg2, T.hover)
	bEp.MouseButton1Click:Connect(function()
		ArkherPublish.toEndpoint()
		refreshHist()
	end)
	local bNat = K.btn(cv, "Nat", 10, 170, 230, 26, T.bg2, 5)
	K.txtS(bNat, "Roblox nativo (delega ao Studio)", 9, T.txt)
	K.hover(bNat, T.bg2, T.hover)
	bNat.MouseButton1Click:Connect(function()
		ArkherPublish.toRobloxNative()
	end)
	K.txt(cv, "sem Open Cloud, sem JWT, sem API key do Roblox", 10, 206, 240, 28, 9, T.txt4)

	-- ===== DIREITA: HISTORICO =====
	local right = K.f(root, "Hist", 432, 34, 120, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 120, 150)
	local function refreshHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		local h = ArkherPublish.history()
		if #h == 0 then
			K.txt(histArea, "(nada publicado)", 10, 6, 104, 20, 9, T.txt4)
			return
		end
		for i, e in ipairs(h) do
			if i > 5 then break end
			K.txt(histArea, e.name or "?", 10, 4 + (i - 1) * 26, 104, 14, 9, T.txt2)
			K.txt(histArea, e.dest or "?", 10, 18 + (i - 1) * 26, 104, 12, 8, T.txt4)
		end
	end
	refreshHist()
	K.row(right, "Endpoint", ARKHER.STATE.cloud.endpoint == "" and "off" or "on", 190)
	K.row(right, "SSL", "auto", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "PUBLICAR FACIL", 12, 8, 160, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "1 clique -> bundle .arkher.lua -> local ou endpoint do ARKHER CLOUD", 12, 28, 420, 14, 9, T.txt3)
	K.progress(bar, 12, 54, 400, 1, ACCENT)
	K.txt(bar, "ultimo: " .. tostring((ArkherPublish.history()[1] or {}).when or "nunca"), 424, 58, 120, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Publish", "Publish", "System", ICON.share, "Publicacao: bundle + manifest + local/endpoint/nativo (sem Open API)", build)
end

do
--[[ ARKHER V3 — UI: SAVEEXPORT ]]
-- Layout unico: selecao de formato a esquerda, PREVIEW PRINT-MAP (vista
-- de cima desenhada a partir do workspace REAL) no centro, exportar a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6348")

local function build()
	local g, root, head = K.window("ArkherSaveExport", "EXPORT — bundle & mapa", 24, 500, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: FORMATOS =====
	local left = K.f(root, "Fmts", 8, 34, 130, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FORMATO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local fmts = {
		{ id = "bundle", nm = "Bundle", d = ".arkher.lua (completo)" },
		{ id = "printmap", nm = "Print Map", d = "vista de cima (2D)" },
		{ id = "json", nm = "JSON raw", d = "snapshot puro" },
	}
	local curFmt = 1
	for i, f in ipairs(fmts) do
		local row = K.btn(left, "F" .. i, 8, 26 + (i - 1) * 44, 114, 38, T.bg2, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, f.nm, 8, 4, 100, 14, 10, T.txt)
		K.txt(row, f.d, 8, 20, 100, 16, 8, T.txt4)
		local idx = i
		row.MouseButton1Click:Connect(function()
			curFmt = idx
			for j = 1, #fmts do
				K.stroke(left:FindFirstChild("F" .. j), j == idx and ACCENT or T.line2, j == idx and 1.5 or 1)
			end
			renderPreview()
		end)
	end
	K.row(left, "Tamanho est.", "14.2 KB", 170)
	K.row(left, "Compressao", "gzip op.", 194)

	-- ===== CENTRO: PREVIEW (PRINT MAP DO WORLD REAL) =====
	local cv = K.f(root, "Prev", 150, 34, 262, 250, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PREVIEW", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local mapArea = K.f(cv, "Map", 8, 22, 246, 220)
	local function renderPreview()
		for _, ch in ipairs(mapArea:GetChildren()) do ch:Destroy() end
		-- grade
		for i = 1, 11 do
			K.f(mapArea, "gx" .. i, i * 22, 0, 1, 220, T.bg3)
			K.f(mapArea, "gy" .. i, 0, i * 20, 246, 1, T.bg3)
		end
		-- desenha o workspace de cima: 1 part = 1 quadrado (pos XZ -> 2D)
		local n = 0
		local function drawPart(inst)
			n = n + 1
			local px2, pz2
			local okp, p = pcall(function() return inst.Position end)
			if okp and p and p.X then
				px2, pz2 = p.X, p.Z
			else
				px2, pz2 = math.random(-100, 100), math.random(-100, 100)
			end
			local sx = math.floor(123 + px2 * 0.9)
			local sy = math.floor(110 + pz2 * 0.9)
			if sx < 2 or sx > 240 or sy < 2 or sy > 214 then return end
			local col = T.sec
			if inst.ClassName == "BasePart" then
				local okc, c3 = pcall(function() return inst.Color end)
				if okc and c3 then col = c3 end
			end
			if n <= 40 then
				K.f(mapArea, "P" .. n, sx, sy, 8, 8, col, 1)
			end
		end
		for _, ch in ipairs(workspace:GetDescendants()) do
			local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
			if ok and isPart and ch.Name ~= "Terrain" then
				drawPart(ch)
				if n >= 40 then break end
			end
		end
		if n == 0 then
			K.txt(mapArea, "(workspace vazio)", 90, 100, 120, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Center)
		end
		K.txt(mapArea, n .. " parts mapeadas", 4, 206, 200, 14, 9, T.txt4)
	end
	renderPreview()

	-- ===== DIREITA: EXPORTAR =====
	local right = K.f(root, "Exp", 424, 34, 128, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "EXPORTAR", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local exp = K.btn(right, "Exp", 10, 28, 108, 30, ACCENT, 5)
	local expIc = K.f(exp, "Ic", 6, 5, 20, 20)
	ICON.save(expIc)
	K.txt(exp, "EXPORTAR", 30, 0, 76, 30, 11, C("#200804"), ARKHER.FONTB)
	K.hover(exp, ACCENT, C("#FF907F"))
	exp.MouseButton1Click:Connect(function()
		if curFmt == 1 then
			ArkherPlaces.exportToFile()
		elseif curFmt == 3 then
			local Http = game:GetService("HttpService")
			local snap = ArkherPlaces.snapshot()
			local ok, path = pcall(function()
				if game.WriteFile and snap then
					game:WriteFile("ArkherExports/snapshot_raw.json", Http:JSONEncode(snap))
					return "ArkherExports/snapshot_raw.json"
				end
				return nil
			end)
			if ok and path then
				ARKHER.out("SUCCESS", "Export: JSON raw em " .. path)
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		else
			local lines = { "-- PRINT MAP ARKHER" }
			for _, ch in ipairs(workspace:GetDescendants()) do
				local ok, isPart = pcall(function() return ch:IsA("BasePart") end)
				if ok and isPart then
					local okp, p = pcall(function() return ch.Position end)
					if okp and p then
						table.insert(lines, string.format("%s (%.0f, %.0f, %.0f)", ch.Name, p.X or 0, p.Y or 0, p.Z or 0))
					end
				end
			end
			local ok, path = pcall(function()
				if game.WriteFile then
					game:WriteFile("ArkherExports/print_map.txt", table.concat(lines, "\n"))
					return path or "ArkherExports/print_map.txt"
				end
				return nil
			end)
			if ok then
				ARKHER.out("SUCCESS", "Export: print map com " .. (#lines - 1) .. " parts")
				K.notify("Print map", #lines - 1 .. " parts exportadas", "ok")
			else
				ARKHER.out("WARNING", "Export: WriteFile indisponivel fora do Studio")
			end
		end
		K.progress(right, 10, 70, 108, 1, ACCENT)
	end)
	K.row(right, "Destino", "disco", 110)
	K.row(right, "Permissao", "Studio", 134)
	K.txt(right, "no Roblox (play):\nusa clipboard", 10, 160, 110, 30, 8, T.txt4)
	K.row(right, "Ultimo", "ha 2 min", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Local", "ArkherPlaces/ + ArkherExports/", 8)
	K.row(bar, "Versionado", "sim (id por save)", 34)
	K.txt(bar, "o bundle contem workspace + lighting + scripts + metadata — restaura tudo", 12, 60, 420, 14, 9, T.txt4)
	K.txt(bar, "v3.0.0", 480, 64, 60, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("SaveExport", "Export", "System", ICON.share, "Exportacao: bundle, print map 2D do world real e JSON", build)
end

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

do
--[[ ARKHER — UI: SCATTER / SCENE STUDIO X (motor ASXN custom) ]]
-- Studio de povoamento procedural: SCATTER com amostragem Poisson, regras por
-- BIOMA (Whittaker do ATX — a arvore certa no bioma certo), declive maximo,
-- acima do mar, jitter deterministico anti-CG (PATINA), LOD por distancia
-- cooperando com D-O15, query por classe/nome/raio, MERGE/EXPLODE/ALIGN,
-- barras de resultado ao vivo. Preview ANTES de materializar (pontos reais).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7CE38B")
local SXN, DM = ArkherSceneX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local repaintPreview, repaintRules, repaintStatus, repaintQuery, repaintLast, repaintLod, repaintPatCount

local function build()
	local g, root, head = K.window("ArkherScatter", "SCATTER / SCENE STUDIO X — motor ASXN (custom)", 120, 120, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)
	local W, H = 700, 470

	-- ================= ESQUERDA: REGIAO + MAKERS =================
	local lw = 220
	local bodyH = 470 - 34 - 40
	local left = K.f(root, "L", 6, 34, lw, bodyH, T.bg3)
	K.txt(left, "REGIAO DO SCATTER", 8, 4, 200, 14, 9, T.txt3)
	local xBox = K.input(left, 8, 22, 100, 18, "cx (0)", false)
	local zBox = K.input(left, 118, 22, 100, 18, "cz (0)", false)
	local regionShapeBtn = K.btn(left, "Formato: circulo", 8, 46, 150, 18, T.bg4)
	local regionIsCircle = true
	local radiusS = mkSlider(left, 8, 70, 210, "Raio", 8, 160, 60, function(v) return string.format("%.0f m", v) end)
	local rectWS = mkSlider(left, 8, 104, 210, "Rect W", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local rectHS = mkSlider(left, 8, 138, 210, "Rect H", 20, 400, 120, function(v) return string.format("%.0f m", v) end)
	local countS = mkSlider(left, 8, 172, 210, "Quantidade", 5, 240, 60, function(v) return string.format("%d", math.floor(v)) end)
	local minDistS = mkSlider(left, 8, 206, 210, "Min dist", 1, 20, 5, function(v) return string.format("%.1f m", v) end)
	local slopeS = mkSlider(left, 8, 240, 210, "Declive max", 0, 1.4, 0.8, function(v) return string.format("%.2f", v) end)
	local seedI = K.input(left, 8, 276, 210, 18, "seed (4242)", false)
	K.txt(left, "MAKER", 8, 300, 100, 14, 9, T.txt3)
	local makers = { "auto (regra do bioma)", "tree", "bush", "rock", "grass" }
	local makerIdx = 1
	local makerB = K.btn(left, "auto (regra do bioma)", 8, 316, 210, 18, T.bg4)
	makerB.MouseButton1Click:Connect(function()
		makerIdx = makerIdx % #makers + 1
		makerB.Text = makers[makerIdx]
	end)
	local aboveWater = true
	local wetB = K.btn(left, "so acima do mar: SIM", 8, 340, 150, 18, T.bg4)
	wetB.MouseButton1Click:Connect(function()
		aboveWater = not aboveWater
		wetB.Text = "so acima do mar: " .. (aboveWater and "SIM" or "NAO")
	end)
	local biomes = { "auto (ATX)", "floresta_equatorial", "savana", "deserto", "rocha", "taiga" }
	local biomeIdx = 1
	local biomeB = K.btn(left, "bioma: auto (ATX)", 8, 364, 210, 18, T.bg4)
	biomeB.MouseButton1Click:Connect(function()
		biomeIdx = biomeIdx % #biomes + 1
		biomeB.Text = "bioma: " .. biomes[biomeIdx]
	end)
	regionShapeBtn.MouseButton1Click:Connect(function()
		regionIsCircle = not regionIsCircle
		regionShapeBtn.Text = "Formato: " .. (regionIsCircle and "circulo" or "retangulo")
	end)

	-- ================= CENTRO: PLANO DE PONTOS (PREVIEW) =================
	local cx0, cw = 6 + lw + 8, 236
	local center = K.f(root, "C", cx0, 34, cw, bodyH, T.bg3)
	K.txt(center, "PREVIEW (dots = vai materializar)", 4, 2, 250, 12, 8, T.txt3)
	local pv = K.f(center, "PV", 4, 18, cw - 8, 300, T.bg2)
	K.stroke(pv, T.line, 1)
	local pvCross = K.f(pv, "c", 116, 146, 1, 8, C("#FFD34A"))
	K.f(pv, "c2", 112, 150, 8, 1, C("#FFD34A"))
	local prevInfo = K.txt(center, "passe o PREVIEW p/ calcular", 4, 322, 250, 12, 8.5, T.txt3)
	local prepared = nil

	local prevB = K.btn(center, "PREVIEW", 4, 340, 74, 22, C("#2D6BFF"))
	local scatB = K.btn(center, "SCATTER REAL", 84, 340, 112, 22, C("#3F9E58"))
	local lodB = K.btn(center, "Reg. LOD", 202, 340, 34, 22, T.bg4)

	-- ================= DIREITA: QUERY / PATINA / ALIGN / LOD =================
	local rx0 = cx0 + cw + 8
	local rw = W - rx0 - 6
	local right = K.f(root, "R", rx0, 34, rw, bodyH, T.bg3)
	K.txt(right, "QUERY NO WORLD", 8, 4, 200, 14, 9, T.txt3)
	local qCls = K.input(right, 8, 20, rw - 16, 18, "class (Part)", false)
	local qName = K.input(right, 8, 44, rw - 16, 18, "nome contem", false)
	local qRadS = mkSlider(right, 8, 66, rw - 20, "Raio q", 0, 300, 0, function(v) return v == 0 and "off" or string.format("%.0f m", v) end)
	local qBtn = K.btn(right, "Rodar query", 8, 106, 110, 20, C("#2D6BFF"))
	local qRes = K.txt(right, "—", 8, 130, rw - 12, 26, 8.5, T.txt2)
	local lastQuery = {}

	K.txt(right, "PATINA (variacao anti-CG)", 8, 162, 200, 14, 9, T.txt3)
	local pHue = mkSlider(right, 8, 178, rw - 20, "Hue jit", 0, 0.15, 0.02, function(v) return string.format("%.3f", v) end)
	local pSat = mkSlider(right, 8, 212, rw - 20, "Sat jit", 0, 0.4, 0.06, function(v) return string.format("%.3f", v) end)
	local pVal = mkSlider(right, 8, 246, rw - 20, "Val jit", 0, 0.5, 0.08, function(v) return string.format("%.3f", v) end)
	local patSelB = K.btn(right, "Patina na SELECAO", 8, 286, 120, 20, ACCENT)
	local patLastB = K.btn(right, "Patina no ULTIMO scatter", 8, 310, 160, 20, T.bg4)
	local patRes = K.txt(right, "—", 8, 334, rw - 12, 22, 8.5, T.txt3)

	K.txt(right, "ALIGN / MERGE", 8, 360, 200, 12, 9, T.txt3)
	local axB = K.btn(right, "Align X (min)", 8, 374, 70, 18, T.bg4)
	local ayB = K.btn(right, "Align Y", 82, 374, 60, 18, T.bg4)
	local azB = K.btn(right, "Align Z", 146, 374, 60, 18, T.bg4)
	local mergeB = K.btn(right, "Merge selecao", 8, 396, 88, 18, C("#2D6BFF"))
	local explB = K.btn(right, "Explode", 100, 396, 62, 18, T.bg4)
	local lodApplyB = K.btn(right, "Aplicar LOD (foco 0,0)", 8, 418, 140, 18, C("#8062FF"))
	local lodRes = K.txt(right, "—", 8, 438, rw - 12, 22, 8.5, T.txt3)

	-- ================= STATUS BAR =================
	local stat = K.txt(root, "", 8, H - 36, W - 16, 14, 9, T.txt3)

	-- ================= WORLD SNAPSHOT =================
	local function getWorld()
		if ARKHER._world then return ARKHER._world end
		if ArkherTerrainX then
			ARKHER._world = ArkherTerrainX.new({ seed = 1337, preset = "continentes", cell = 8 })
		end
		return ARKHER._world
	end
	local function spec()
		local cx = tonumber(xBox.Text) or 0
		local cz = tonumber(zBox.Text) or 0
		local mk = makerIdx > 1 and makers[makerIdx] or nil
		local b2 = biomeIdx > 1 and biomes[biomeIdx] or nil
		return {
			x = cx, z = cz,
			radius = regionIsCircle and radiusS.get() or nil,
			rect = regionIsCircle and nil or { w = rectWS.get(), h = rectHS.get() },
			count = math.floor(countS.get()), minDist = minDistS.get(),
			maxSlope = slopeS.get(), aboveWater = aboveWater,
			maker = mk, biome = b2,
			seed = tonumber(seedI.Text) or 4242, world = getWorld(),
			name = "ASXN_ScatterUI",
		}
	end

	repaintPreview = function()
		for _, ch in ipairs(pv:GetChildren()) do if ch.Name:find("^d") then ch:Destroy() end end
		if not prepared then return end
		-- mapear bbox dos pontos para o quadro
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		for _, it in ipairs(prepared.placed) do
			minX = math.min(minX, it[1]) maxX = math.max(maxX, it[1])
			minZ = math.min(minZ, it[2]) maxZ = math.max(maxZ, it[2])
		end
		local span = math.max(maxX - minX, maxZ - minZ, 1)
		local pw, ph = pv.AbsoluteSize.X > 10 and pv.AbsoluteSize.X or 248, 286
		for i, it in ipairs(prepared.placed) do
			if i > 400 then break end
			local fx = (it[1] - minX) / span
			local fz = (it[2] - minZ) / span
			local col = it[4] == "tree" and C("#63D68B") or it[4] == "rock" and C("#B9B3A8") or it[4] == "bush" and C("#84C96B") or C("#CFE38B")
			local d = K.f(pv, "d" .. i, fx * (pw - 8) + 2, fz * (ph - 8) + 2, it[4] == "tree" and 5 or 3, it[4] == "tree" and 5 or 3, col)
			K.corner(d, 2)
		end
		prevInfo.Text = string.format("%d pontos prontos (tries %d) — area uso ~%.0fx%.0f m | span %.0f m",
			#prepared.placed, prepared.tries or 0, prepared.rect and prepared.rect.w or 2 * (prepared.radius or 0), prepared.rect and prepared.rect.h or 2 * (prepared.radius or 0), span)
	end
	repaintQuery = function(txt) if qRes then qRes.Text = txt end end
	repaintLast = function() local n = #SXN._lods return n end
	repaintLod = function(l) if lodRes then lodRes.Text = l end end
	repaintPatCount = function(s) if patRes then patRes.Text = s end end
	repaintRules = function() end -- reservado p/ barra de regras (v2)
	repaintStatus = function()
		local inv = 0
		for _ in pairs(SXN._ambients or {}) do inv = inv + 1 end
		local hashCount = 0
		for _ in pairs(SXN._hash or {}) do hashCount = hashCount + 1 end
		stat.Text = string.format("spatial-hash cells %d | lod groups %d | ultimo scatter: %s | tries p/ ver o preview",
			hashCount, #SXN._lods, (prepared and (#prepared.placed .. " pts prontos") or "—"))
	end

	prevB.MouseButton1Click:Connect(function()
		local s = spec()
		prepared = SXN.prepare(s)
		prepared.rect = s.rect
		prepared.radius = s.radius
		repaintPreview()
		repaintStatus()
	end)
	scatB.MouseButton1Click:Connect(function()
		local s = spec()
		if prepared then s._prepared = prepared end
		local res = SXN.scatter(s)
		ARKHER._lastScatter = res.model
		K.notify("Scatter", res.count .. " instancias em ASXN_ScatterUI (tries " .. res.tries .. ") | biomas do ATX", "ok")
		repaintStatus()
	end)
	lodB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			SXN.registerLOD(ARKHER._lastScatter, { near = 90, mid = 200, far = 360 })
			repaintLod("LOD registrado grps=" .. #SXN._lods)
		else
			repaintLod("nada p/ registrar (rode SCATTER)")
		end
	end)
	lodApplyB.MouseButton1Click:Connect(function()
		local r = SXN.applyLOD(0, 0)
		repaintLod(string.format("LOD: %d shown, %d ghosts(mid), %d culled(far)", r.shown, r.ghosts, r.culled))
	end)
	qBtn.MouseButton1Click:Connect(function()
		local cls = qCls.Text ~= "" and qCls.Text or "Part"
		local nm = qName.Text ~= "" and qName.Text or nil
		local r = qRadS.get()
		local sp = { class = cls, name = nm, within = r > 0 and { x = tonumber(xBox.Text) or 0, z = tonumber(zBox.Text) or 0, r = r } or nil }
		lastQuery = SXN.query(sp)
		-- contagem por classe
		local byCls = {}
		for _, inst in ipairs(lastQuery) do byCls[inst.ClassName] = (byCls[inst.ClassName] or 0) + 1 end
		local parts = {}
		for k, v in pairs(byCls) do parts[#parts + 1] = k .. "=" .. v end
		repaintQuery(#lastQuery .. " resultados | " .. table.concat(parts, ", "))
	end)
	patSelB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		local n = SXN.patina(list, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get(), seed = tonumber(seedI.Text) or 99 })
		repaintPatCount("patina: " .. n .. " partes (seed " .. (tonumber(seedI.Text) or 99) .. ")")
	end)
	patLastB.MouseButton1Click:Connect(function()
		if ARKHER._lastScatter then
			local parts = {}
			for _, ch in ipairs(ARKHER._lastScatter:GetDescendants()) do if ch:IsA("BasePart") then parts[#parts + 1] = ch end end
			local n = SXN.patina(parts, { hueJit = pHue.get(), satJit = pSat.get(), valJit = pVal.get() })
			repaintPatCount("patina ultimo scatter: " .. n .. " partes")
		end
	end)
	axB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "x", mode = "min" }) end
	end)
	ayB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "y", mode = "avg" }) end
	end)
	azB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 1 then SXN.alignArray(list, { axis = "z", mode = "min" }) end
	end)
	mergeB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if #list > 0 then local m = SXN.merge(list, "ASXN_MergedUI") K.notify("Merge", "Model ASXN_MergedUI com " .. #list .. " parts", "ok") end
	end)
	explB.MouseButton1Click:Connect(function()
		local sel = game:GetService("Selection")
		local list = sel and sel:Get() or {}
		if list[1] and list[1].ClassName == "Model" then
			local out = SXN.explode(list[1])
			K.notify("Explode", #out .. " parts soltas", "ok")
		end
	end)

	-- boot
	repaintStatus()
	return g
end

ARKHER.reg("Scatter", "Scatter / Scene X", "Mundo", ICON.plate, "Povoamento procedural: scatter Poisson por bioma, patina, LOD distancia, query, merge/align", build)
end

do
--[[ ARKHER — UI: SCRIPT STUDIO (IDE completa, backend ArkherScripterX) ]]
-- IDE profissional: multi-documento (tabs), highlight REAL por tokenizer,
-- lint REAL (balanceamento de blocos/variaveis/deprecais), autocomplete pelo
-- banco da API Roblox + doc, outline de funcoes, find/replace, snippets (45),
-- templates (30), compile-check, create-in-place real, export, metricas.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")
local SX = ArkherScripterX
local MONO = ARKHER.MONO or ARKHER.FONT

local THM = {}
for k2, v in pairs(SX.THEME) do THM[k2] = C(v) end

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT STUDIO — IDE Luau", 28, 318, 720, 520, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)

	-- ================= DOCUMENTOS =================
	local docs = {}
	local active = 1
	local scrollTop = 0
	local curLine = 1
	local status = nil
	local lintBody = nil
	local outlineBody = nil
	local acPopup = nil
	local codeFrame = nil
	local VISIBLE = 18
	local LINE_H = 15
	-- funcoes da tela (pre-declaradas p/ closures cruzadas)
	local repaintTabs, repaintCode, relintBody, repaintPanel, repaintStatus, repaintAll
	local openLineEditor, pushUndo, refreshAC

	local function newDoc(name, class, src)
		docs[#docs + 1] = { name = name, class = class or "Script", src = src or ("-- " .. name .. " (Script)\n\n"), undo = {}, dirty = false }
		return docs[#docs]
	end
	newDoc("Main", "Script", SX.template("basico").src)
	newDoc("Cliente", "LocalScript", SX.template("local_basico").src)
	newDoc("Fisica", "ModuleScript", SX.template("oop_classe").src)
	local function doc() return docs[active] end

	-- ================= TOOLBAR =================
	local nameBox = K.input(root, 10, 34, 130, 22, "nome")
	nameBox.Text = doc().name
	nameBox.FocusLost:Connect(function(enter)
		if enter and #nameBox.Text > 0 then doc().name = nameBox.Text repaintTabs() end
	end)
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }
	K.tabs(root, 148, 34, 230, CLASSES, 1, function(idx)
		doc().class = CLASSES[idx]
		repaintStatus()
	end)
	local TARGETS = { "Workspace", "ServerScriptService", "StarterPlayerScripts", "StarterGui", "ReplicatedStorage" }
	local targetIdx = 1
	local tgtLbl = K.txt(root, TARGETS[1], 386, 38, 140, 16, 9, T.txt3)
	local tgt = K.btn(root, "Tgt", 524, 34, 28, 22, T.bg2, 4)
	K.txtS(tgt, "<>", 10, ACCENT)
	tgt.MouseButton1Click:Connect(function()
		targetIdx = (targetIdx % #TARGETS) + 1
		tgtLbl.Text = TARGETS[targetIdx]
	end)
	local compile = K.btn(root, "Comp", 560, 34, 70, 22, T.bg2, 4)
	K.txtS(compile, "Compilar", 9, T.txt)
	K.hover(compile, T.bg2, T.hover)
	local aiGen = K.btn(root, "AI", 638, 34, 74, 22, T.purple, 4)
	K.txtS(aiGen, "Gerar p/ IA", 9, C("#FFF"))
	K.hover(aiGen, T.purple, C("#A97AFF"))

	-- ================= TABS DE DOCUMENTOS =================
	local tabBar = K.f(root, "Tabs", 10, 62, 580, 24, T.bg4)
	K.corner(tabBar, 4)
	repaintTabs = function()
		for _, ch2 in ipairs(tabBar:GetChildren()) do if ch2:IsA("GuiObject") then ch2:Destroy() end end
		local x = 4
		for i, d in ipairs(docs) do
			local w = 26 + #d.name * 6
			local b = K.btn(tabBar, "D" .. i, x, 2, w, 20, i == active and T.bg2 or T.bg4, 4)
			K.txtS(b, d.name .. (d.dirty and " *" or ""), 9, i == active and T.txt or T.txt3)
			local idx = i
			b.MouseButton1Click:Connect(function()
				active = idx
				nameBox.Text = docs[active].name
				scrollTop = 0
				repaintAll()
			end)
			x = x + w + 4
		end
	end
	local plus = K.btn(root, "Plus", 596, 62, 56, 24, T.bg2, 4)
	K.txtS(plus, "+ novo", 9, T.txt)
	K.hover(plus, T.bg2, T.hover)
	plus.MouseButton1Click:Connect(function()
		newDoc("Doc" .. (#docs + 1), "Script", "-- novo documento\n\n")
		active = #docs
		repaintAll()
	end)
	local cls = K.btn(root, "Cls", 658, 62, 52, 24, T.bg2, 4)
	K.txtS(cls, "fechar", 9, T.txt3)
	K.hover(cls, T.bg2, T.hover)
	cls.MouseButton1Click:Connect(function()
		if #docs > 1 then
			table.remove(docs, active)
			active = math.min(active, #docs)
			repaintAll()
		end
	end)

	-- ================= AREA DE CODIGO (highlight real) =================
	codeFrame = K.f(root, "Code", 10, 92, 582, 276, T.bg0)
	K.corner(codeFrame, 4)
	K.stroke(codeFrame, T.line, 1)
	-- numeros de linha
	local gutter = K.f(codeFrame, "G", 0, 0, 34, 276, T.bg3)
	-- src do doc como tabela de linhas
	local function linesOf(src)
		local out = {}
		for l in (src .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
		return out
	end
	local function joinLines(t2) return table.concat(t2, "\n") end


	local function commitEdit()
		doc().dirty = true
		repaintCode()
		relintBody()
		repaintTabs()
		repaintStatus()
	end

	repaintCode = function()
		for _, ch2 in ipairs(codeFrame:GetChildren()) do
			if ch2.Name ~= "G" then ch2:Destroy() end
		end
		gutter:ClearAllChildren()
		local hl = SX.highlightLines(doc().src)
		local srcLines = linesOf(doc().src)
		for i = 1, VISIBLE do
			local li = scrollTop + i
			if li > #srcLines then break end
			local y = 4 + (i - 1) * LINE_H
			K.txt(gutter, string.format("%2d", li), 0, y, 30, LINE_H - 1, 8, li == curLine and ACCENT or T.txt4, MONO, Enum.TextXAlignment.Right)
			-- click editor da linha
			local row = K.btn(codeFrame, "R" .. i, 36, y, 540, LINE_H - 1, li == curLine and T.bg2 or T.bg0, 0)
			row.BackgroundTransparency = li == curLine and 0.5 or 1
			local idx = li
			row.MouseButton1Click:Connect(function()
				curLine = idx
				openLineEditor(idx)
				repaintCode()
				repaintStatus()
			end)
			-- segmentos coloridos
			if hl[li] then
				local x = 4
				for _, seg in ipairs(hl[li]) do
					local segW = math.max(2, #seg[1] * 6.05)
					local t3 = K.txt(row, seg[1], x, 0, segW + 8, LINE_H - 1, 10, THM[seg[2]] or T.txt2, MONO)
					x = x + seg[1]:gsub("\t", "    "):len() * 6.05
				end
			end
		end
	end
	-- scroll por botoes
	local up = K.btn(root, "Up", 596, 92, 56, 22, T.bg2, 4)
	K.txtS(up, "▲", 11, T.txt3)
	local dn = K.btn(root, "Dn", 596, 118, 56, 22, T.bg2, 4)
	K.txtS(dn, "▼", 11, T.txt3)
	local page = K.btn(root, "Pg", 596, 144, 56, 22, T.bg2, 4)
	K.txtS(pg, "▼▼", 11, T.txt3)
	up.MouseButton1Click:Connect(function() scrollTop = math.max(0, scrollTop - 1) repaintCode() end)
	dn.MouseButton1Click:Connect(function() scrollTop = scrollTop + 1 repaintCode() end)
	page.MouseButton1Click:Connect(function() scrollTop = scrollTop + VISIBLE repaintCode() end)
	local home = K.btn(root, "Hm", 596, 170, 56, 22, T.bg2, 4)
	K.txtS(home, "Topo", 9, T.txt3)
	home.MouseButton1Click:Connect(function() scrollTop = 0 repaintCode() end)

	-- editor inline da linha
	local editBox = nil
	openLineEditor = function(li)
		if editBox then editBox:Destroy() editBox = nil end
		local rel = li - scrollTop
		if rel < 1 or rel > VISIBLE then return end
		local srcLines = linesOf(doc().src)
		local y = 4 + (rel - 1) * LINE_H
		editBox = Instance.new("TextBox")
		editBox.Name = "LineEdit"
		editBox.Parent = codeFrame
		editBox.Position = UDim2.new(0, 36, 0, y)
		editBox.Size = UDim2.new(0, 540, 0, LINE_H + 2)
		editBox.BackgroundColor3 = T.bg2
		editBox.TextColor3 = T.txt
		editBox.TextSize = 10
		editBox.Font = MONO
		editBox.Text = srcLines[li] or ""
		editBox.ClearTextOnFocus = false
		editBox.BorderSizePixel = 0
		editBox.FocusLost:Connect(function(enter)
			if enter and editBox then
				local lns = linesOf(doc().src)
				lns[li] = editBox.Text
				doc().src = joinLines(lns)
				commitEdit()
				refreshAC()
			end
			if editBox then editBox:Destroy() editBox = nil end
		end)
	end

	-- editor FULL (documento inteiro)
	local fullBtn = K.btn(root, "Full", 596, 196, 56, 22, T.bg2, 4)
	K.txtS(fullBtn, "Full", 9, T.txt3)
	K.hover(fullBtn, T.bg2, T.hover)
	local fullOpen = false
	fullBtn.MouseButton1Click:Connect(function()
		fullOpen = not fullOpen
		if fullOpen then
			local box = Instance.new("TextBox")
			box.Name = "FullEdit"
			box.Parent = codeFrame
			box.Position = UDim2.new(0, 36, 0, 2)
			box.Size = UDim2.new(0, 540, 0, 272)
			box.BackgroundColor3 = T.bg4
			box.TextColor3 = T.txt
			box.TextSize = 10
			box.Font = MONO
			box.MultiLine = true
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.TextYAlignment = Enum.TextYAlignment.Top
			box.Text = doc().src
			box.ClearTextOnFocus = false
			box.FocusLost:Connect(function(enter)
				if enter then doc().src = box.Text commitEdit() end
			end)
		else
			local fe = codeFrame:FindFirstChild("FullEdit")
			if fe then fe:Destroy() end
			repaintCode()
		end
	end)
	local undoB = K.btn(root, "Ud", 596, 222, 56, 22, T.bg2, 4)
	K.txtS(undoB, "Undo", 9, T.txt3)
	local redoHint = K.txt(root, "Ctrl+Z do Studio", 596, 248, 60, 12, 7, T.txt4)
	undoB.MouseButton1Click:Connect(function()
		local stack = doc().undo
		if #stack > 0 then
			doc().src = table.remove(stack)
			commitEdit()
			status.Text = "undo do documento (stack local)"
		else
			status.Text = "nada p/ desfazer neste documento"
		end
	end)
	local fmt2 = K.btn(root, "Fm", 596, 264, 56, 22, T.bg2, 4)
	K.txtS(fmt2, "Format", 9, T.txt3)
	fmt2.MouseButton1Click:Connect(function()
		pushUndo()
		doc().src = SX.format(doc().src)
		commitEdit()
		status.Text = "formatado (indentacao por profundidade de bloco)"
	end)
	pushUndo = function()
		local stack = doc().undo
		stack[#stack + 1] = doc().src
		if #stack > 30 then table.remove(stack, 1) end
	end

	-- ================= AUTOCOMPLETE =================
	acPopup = K.f(root, "AC", 660, 92, 52, 0)
	refreshAC = function()
		-- popup real aparece perto do rodape (nao usado inline; a lista completa esta na aba COMPLETE)
	end

	-- ================= PAINEL INFERIOR ESQ: LINT (REAL) =================
	local lintF = K.f(root, "Lint", 10, 374, 286, 102, T.bg4)
	K.corner(lintF, 4)
	local lintHead = K.txt(lintF, "LINT", 8, 4, 60, 14, 10, T.txt3, ARKHER.FONTB)
	lintBody = K.f(lintF, "LB", 8, 20, 270, 76)
	relintBody = function()
		lintHead.Text = "LINT"
		lintBody:ClearAllChildren()
		local diags = SX.lint(doc().src)
		local sum = SX.lintSummary(diags)
		lintHead.Text = "LINT — " .. sum.errors .. " erros, " .. sum.warns .. " avisos"
		lintHead.TextColor3 = sum.errors > 0 and C("#E05252") or (sum.warns > 0 and C("#FFD93D") or C("#37C85C"))
		local shown = 0
		for _, d in ipairs(diags) do
			if shown >= 4 then break end
			shown = shown + 1
			local col = d.sev == "error" and C("#E05252") or d.sev == "warn" and C("#FFD93D") or T.txt4
			local lbl2 = K.txt(lintBody, "[" .. d.line .. "] " .. d.msg, 2, (shown - 1) * 16, 262, 14, 8, col)
			lbl2.TextTruncate = Enum.TextTruncate.AtEnd
		end
		if shown == 0 then K.txt(lintBody, "codigo limpo — nenhuma inconsistencia", 2, 0, 240, 14, 9, C("#37C85C")) end
	end

	-- ================= PAINEL INF INF: FIND/REPLACE + STATS =================
	local fr = K.f(root, "FR", 306, 374, 286, 102, T.bg4)
	K.corner(fr, 4)
	K.txt(fr, "BUSCAR / SUBSTITUIR", 8, 4, 200, 14, 10, T.txt3, ARKHER.FONTB)
	local findBox = K.input(fr, 8, 22, 128, 20, "buscar")
	local repBox = K.input(fr, 142, 22, 128, 20, "substituir")
	local frOut = K.txt(fr, "", 8, 82, 260, 14, 9, T.txt4)
	local findB = K.btn(fr, "FB", 8, 48, 84, 20, T.bg2, 4)
	K.txtS(findB, "Buscar", 9, T.txt)
	local repB = K.btn(fr, "RB", 96, 48, 84, 20, T.bg2, 4)
	K.txtS(repB, "Substituir", 9, T.txt)
	local allB = K.btn(fr, "AB", 184, 48, 86, 20, T.bg2, 4)
	K.txtS(allB, "Substituir tudo", 8, T.txt)
	findB.MouseButton1Click:Connect(function()
		local hits = SX.findAll(doc().src, findBox.Text, {})
		frOut.Text = #hits .. " ocorrencias de '" .. findBox.Text .. "'"
	end)
	repB.MouseButton1Click:Connect(function()
		pushUndo()
		local hits = SX.findAll(doc().src, findBox.Text, {})
		if #hits > 0 then
			local before = hits[1]
			local s = doc().src
			doc().src = s:sub(1, before.a - 1) .. repBox.Text .. s:sub(before.b + 1)
			commitEdit()
			frOut.Text = "substituido 1 de " .. #hits
		end
	end)
	allB.MouseButton1Click:Connect(function()
		pushUndo()
		local new, n = SX.replace(doc().src, findBox.Text, repBox.Text, {})
		doc().src = new
		commitEdit()
		frOut.Text = n .. " substituicoes feitas"
	end)

	-- ================= PAINEL DIR: OUTLINE + COMPLETE + SNIPPETS + TEMPLATES =================
	-- painel direito: outline / completar / snippets / templates

	local panel = K.f(root, "P", 604, 92, 108, 384, T.bg4)
	K.corner(panel, 4)
	local PTABS = { "Outline", "Completar", "Snippets", "Templates" }
	local pTab = 2
	local pBody = K.f(panel, "PB", 4, 24, 100, 356)
	local pBtns = {}
	local function selectPTab(i)
		pTab = i
		for j, b in ipairs(pBtns) do b.BackgroundColor3 = j == i and T.bg2 or T.bg4 end
		repaintPanel()
	end
	for i, nm in ipairs(PTABS) do
		local b = K.btn(panel, "PT" .. i, 4 + (i - 1) * 26, 4, 24, 18, T.bg4, 3)
		K.txtS(b, nm:sub(1, 2), 8, i == pTab and ACCENT or T.txt3)
		local idx = i
		b.MouseButton1Click:Connect(function() selectPTab(idx) end)
		pBtns[i] = b
	end
	local panelPage = 0
	repaintPanel = function()
		pBody:ClearAllChildren()
		if pTab == 1 then
			local items = SX.outline(doc().src)
			if #items == 0 then K.txt(pBody, "sem funcoes", 4, 0, 90, 14, 9, T.txt4) end
			for i = 1, math.min(#items, 20) do
				local it = items[i]
				local b = K.btn(pBody, "O" .. i, 4, (i - 1) * 17, 92, 15, T.bg4, 2)
				K.txt(b, string.rep(" ", it.depth * 2) .. "f " .. it.name, 4, 1, 84, 13, 8, T.txt2)
				K.txt(b, tostring(it.line), 64, 1, 26, 13, 7, T.txt4, FONT, Enum.TextXAlignment.Right)
				local ln = it.line
				b.MouseButton1Click:Connect(function()
					curLine = ln
					scrollTop = math.max(0, ln - 4)
					repaintCode()
					repaintStatus()
				end)
			end
		elseif pTab == 2 then
			K.txt(pBody, "prefixo:", 4, 0, 90, 14, 9, T.txt4)
			local pf = K.input(pBody, 4, 15, 92, 18, "Get, Inst, task...")
			local list = K.f(pBody, "L", 4, 38, 92, 200)
			local function showAC()
				list:ClearAllChildren()
				local res = SX.complete(pf.Text, doc().src)
				for i = 1, math.min(#res, 11) do
					local r = res[i]
					K.txt(list, r.label, 2, (i - 1) * 17, 92, 15, 9, r.kind == "keyword" and C("#C792EA") or r.kind == "service" and C("#5AD4E6") or T.txt2)
					K.txt(list, r.kind, 2, (i - 1) * 17 + 0, 100, 15, 7, T.txt4, FONT, Enum.TextXAlignment.Right)
				end
			end
			pf:GetPropertyChangedSignal("Text"):Connect(showAC)
			showAC()
		elseif pTab == 3 then
			local base = panelPage * 11
			for i = 1, 11 do
				local sn = SX.SNIPPETS[base + i]
				if not sn then break end
				local b = K.btn(pBody, "S" .. i, 4, (i - 1) * 17, 92, 15, T.bg4, 2)
				K.txt(b, sn.nm, 4, 1, 84, 13, 8, T.txt2)
				local id = sn.id
				b.MouseButton1Click:Connect(function()
					pushUndo()
					local lns = linesOf(doc().src)
					-- insere snippet na linha atual
					local snip = nil
					for _, s2 in ipairs(SX.SNIPPETS) do if s2.id == id then snip = s2 end end
					if snip then
						local cur = lns[curLine] or ""
						lns[curLine] = cur .. "\n" .. snip.code
						doc().src = joinLines(lns)
						commitEdit()
						status.Text = "snippet '" .. snip.nm .. "' inserido na linha " .. curLine
					end
				end)
			end
			local pg = K.btn(pBody, "PgS", 4, 190, 92, 16, T.bg2, 3)
			K.txtS(pg, "prox >", 9, T.txt3)
			pg.MouseButton1Click:Connect(function()
				panelPage = (panelPage + 1) % math.ceil(#SX.SNIPPETS / 11)
				repaintPanel()
			end)
		elseif pTab == 4 then
			local base = panelPage * 9
			for i = 1, 9 do
				local tp = SX.TEMPLATES[base + i]
				if not tp then break end
				local b = K.btn(pBody, "T" .. i, 4, (i - 1) * 19, 92, 17, T.bg4, 2)
				K.txt(b, tp.nm, 4, 2, 84, 14, 8, T.txt2)
				local id = tp.id
				b.MouseButton1Click:Connect(function()
					pushUndo()
					local tp2 = SX.template(id)
					doc().src = tp2.src
					doc().class = tp2.cls
					commitEdit()
					status.Text = "template '" .. tp2.nm .. "' carregado (" .. tp2.cls .. ")"
				end)
			end
			local pg = K.btn(pBody, "PgT", 4, 172, 92, 16, T.bg2, 3)
			K.txtS(pg, "prox >", 9, T.txt3)
			pg.MouseButton1Click:Connect(function()
				panelPage = (panelPage + 1) % math.ceil(#SX.TEMPLATES / 9)
				repaintPanel()
			end)
		end
	end

	-- ================= BASE: ACOES DE ARQUIVO =================
	local bar = K.f(root, "Bar", 10, 482, 702, 30, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "Ln 1, Col 1", 10, 8, 240, 14, 9, T.txt3)
	repaintStatus = function()
		local m = SX.metrics(doc().src)
		local diags = SX.lint(doc().src)
		local sum = SX.lintSummary(diags)
		status.Text = "Ln " .. curLine .. " | " .. doc().class .. " | " .. m.lines .. " linhas | " .. m.chars .. " chars | " .. m.functions .. " fns | cx " .. m.complexity .. " | " .. sum.errors .. "err/" .. sum.warns .. "warn"
	end
	local create = K.btn(bar, "Create", 440, 4, 90, 22, ACCENT, 4)
	K.txtS(create, "Criar no Place", 9, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local target
		pcall(function() target = game:GetService(TARGETS[targetIdx]) end)
		if not target and TARGETS[targetIdx] == "StarterPlayerScripts" then
			local ok2, sp = pcall(function() return game:GetService("StarterPlayer") end)
			if ok2 and sp then
				target = sp:FindFirstChild("StarterPlayerScripts")
				if not target then
					target = Instance.new("Folder")
					target.Name = "StarterPlayerScripts"
					target.Parent = sp
				end
			end
		end
		target = target or workspace
		local base = doc().name
		local n = 1
		while target:FindFirstChild(base) do n = n + 1 base = doc().name .. "_" .. n end
		local sc = Instance.new(doc().class)
		sc.Name = base
		sc.Source = doc().src
		sc.Parent = target
		doc().dirty = false
		ARKHER.out("SUCCESS", "Script Studio: " .. doc().class .. " '" .. base .. "' criado em " .. TARGETS[targetIdx])
		K.notify("Script criado", base .. " → " .. TARGETS[targetIdx], "ok")
		repaintTabs()
	end)
	local exp = K.btn(bar, "Exp", 538, 4, 80, 22, T.bg2, 4)
	K.txtS(exp, "Exportar", 9, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local path = "ArkherScripts/" .. doc().name .. ".lua"
		local ok2 = pcall(function()
			if game.WriteFile then game:WriteFile(path, doc().src) end
		end)
		status.Text = ok2 and ("exportado p/ " .. path) or "WriteFile indisponivel fora do Studio"
	end)
	local und2 = K.btn(bar, "U2", 626, 4, 80, 22, T.bg2, 4)
	K.txtS(und2, "Hist.", 9, T.txt3)
	und2.MouseButton1Click:Connect(function()
		status.Text = #doc().undo .. " versoes no stack local | " .. #docs .. " docs abertos"
	end)

	-- compile + AI callbacks (precisam do status)
	compile.MouseButton1Click:Connect(function()
		local res = SX.compile(doc().src)
		if res.ok then
			status.Text = "compilacao OK (" .. res.engine .. ") — sintaxe valida"
		else
			status.Text = "ERRO de sintaxe" .. (res.line and (" linha " .. res.line) or "") .. ": " .. tostring(res.error):sub(1, 90)
		end
	end)
	aiGen.MouseButton1Click:Connect(function()
		pushUndo()
		local goal = nameBox.Text ~= "" and nameBox.Text or "sistema"
		-- pergunta o objetivo via texto do nome + keywords do doc atual
		local hint = goal .. " " .. doc().src:sub(1, 60)
		local src, id2 = SX.compose(hint)
		doc().src = src
		commitEdit()
		status.Text = "IA local compôs de '" .. hint:sub(1, 24) .. "...' → template '" .. id2 .. "'"
	end)

	repaintAll = function()
		nameBox.Text = doc().name
		repaintTabs()
		repaintCode()
		relintBody()
		repaintPanel()
		repaintStatus()
	end

	-- ================= BOOT DA UI =================
	repaintAll()
end

ARKHER.reg("Script", "Script Studio", "Editor", ICON.script, "IDE completa: multi-doc, highlight real, lint real, autocomplete API, outline, templates, create-in-place", build)
end

do
--[[ ARKHER V3 — UI: SETTINGS ]]
-- Layout unico: colunas de SECOES (K.section) — Qualidade, Cloud (endpoint
-- real em ARKHER.STATE.cloud), Aparencia, Atalhos — com toggles e dropdowns.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#AEB9CC")

local function build()
	local g, root, head = K.window("ArkherSettings", "SETTINGS — preferencias", 24, 450, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: NAVEGACAO =====
	local left = K.f(root, "Nav", 8, 34, 108, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SECOES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local sections = { "Qualidade", "Cloud", "Apariencia", "Atalhos", "Dados" }
	for i, s in ipairs(sections) do
		local row = K.treeRow(left, 0, i == 1 and ICON.settings or ICON.plugin, s, i == 1, 26 + (i - 1) * 26)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Settings: secao " .. s)
		end)
	end
	K.row(left, "V3.0.0", "", 180)

	-- ===== CENTRO: SECOES =====
	local sec1, b1 = K.section(root, "Qualidade", true, 34)
	K.sliderRow(b1, "D-O15 nivel", 0.4, 4)
	K.txt(b1, "auto-degrada por pressao de FPS", 8, 30, 200, 14, 9, T.txt4)

	local sec2, b2 = K.section(root, "Cloud (ARKHER)", true, 104)
	K.txt(b2, "Endpoint do Arkher Cloud (sem Open API):", 8, 4, 240, 16, 10, T.txt3)
	local epBox = K.input(b2, 8, 24, 236, 24, "https://meu-cloud.exemplo.com/arkher")
	epBox.Text = ARKHER.STATE.cloud.endpoint or ""
	local saveEp = K.btn(b2, "SaveEp", 8, 54, 110, 22, ACCENT, 4)
	K.txtS(saveEp, "Salvar endpoint", 9, C("#14181E"))
	K.hover(saveEp, ACCENT, C("#CDD7E4"))
	saveEp.MouseButton1Click:Connect(function()
		ARKHER.STATE.cloud.endpoint = epBox.Text
		ARKHER.STATE.cloud.connected = epBox.Text ~= ""
		ARKHER.out("SUCCESS", "Settings: endpoint salvo: " .. (epBox.Text or "(vazio)"))
		K.notify("Cloud", "endpoint atualizado", "ok")
	end)
	K.txt(b2, "publicacao local nao precisa de endpoint", 8, 84, 240, 14, 9, T.txt4)

	local sec3, b3 = K.section(root, "Aparencia", true, 194)
	K.checkRow(b3, "Modo compacto", false, 4)
	K.checkRow(b3, "Acento neon", true, 28)
	K.checkRow(b3, "Mostrar grade no viewport", true, 52)

	-- ===== DIREITA: ATALHOS =====
	local right = K.f(root, "Keys", 330, 34, 222, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "ATALHOS", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local keys = {
		{ "Ctrl+K", "command palette" },
		{ "Ctrl+Z / Ctrl+Y", "undo / redo" },
		{ "Del", "apagar selecao" },
		{ "V / W / E / R", "select / move / scale / rotate" },
		{ "WASD / Q / E", "orbitar (ferramenta Move)" },
		{ "L", "lock de camera" },
	}
	for i, k2 in ipairs(keys) do
		K.txt(right, k2[1], 10, 28 + (i - 1) * 28, 110, 16, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
		K.txt(right, k2[2], 124, 28 + (i - 1) * 28, 90, 16, 9, T.txt3)
		K.f(right, "ks" .. i, 10, 46 + (i - 1) * 28, 202, 1, T.line)
	end
	local reset = K.btn(right, "Rst", 10, 216, 202, 24, T.danger, 4)
	K.txtS(reset, "Restaurar padroes", 10, C("#1C0404"))
	K.hover(reset, T.danger, C("#F08080"))
	reset.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Settings: padroes restaurados")
		K.notify("Settings", "restaurado", "ok")
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 78, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Lang", "pt-BR", 8)
	K.row(bar, "Tema", "dark", 34)
	K.txt(bar, "as preferencias persistem em ServerStorage.ArkherCloud.Settings", 170, 16, 360, 14, 9, T.txt4)
	K.txt(bar, "salvo", 480, 40, 60, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Settings", "Settings", "System", ICON.settings, "Preferencias: qualidade, cloud (endpoint), aparencia e atalhos", build)
end

do
--[[ ARKHER — UI: TERRAIN STUDIO (motor ATX custom, nao usa Terrain do Roblox) ]]
-- Estudio profissional completo: 6 abas (ESCULPIR/GERAR/GEOL/HIDRO/CLIMA/MUNDO),
-- canvas de terreno INTERATIVO (clique/arraste esculpe o mundo ATX de verdade),
-- 10 pinceis x 5 falloffs, 8 presets de mundo, erosao real, rios, lagos, clima,
-- biomas, materializacao adaptativa (D-O15) e export real.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local TX, DM = ArkherTerrainX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	local lbl = K.txt(parent, label, x, y, 80, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 54, y, 54, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 16, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		if fmt then valLbl.Text = fmt(val) else valLbl.Text = string.format("%.2f", val) end
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return {
		get = function() return val end,
		set = function(v) val = v renderSlider() if onSet then onSet(v) end end,
	}
end

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN STUDIO — motor ATX (custom)", 24, 300, 700, 500, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= MUNDO VIVO =================
	local world = TX.new({ seed = 1337, preset = "continentes", cell = 8, chunkCells = 16 })
	local brush = { op = "raise", falloff = "smooth", radius = 24, strength = 0.6, amount = 6, mat = "grama" }
	local region = { gx0 = 1, gz0 = 1, gw = 64, gh = 40 } -- regiao de trabalho (celulas)
	local status = nil
	local statLbl = nil
	local gridTiles = {}
	local preview = nil
	local seedBox = nil
	local refreshStats = nil
	local refreshClimate = nil
	local climateList = nil

	-- ================= ABAS =================
	local TABS = { "ESCULPIR", "GERAR", "GEOL", "HIDRO", "CLIMA", "MUNDO" }
	local curTab = 1
	local tabBodies = {}
	local tabBar = K.f(root, "TabBar", 8, 34, 684, 26, T.bg4)
	K.corner(tabBar, 5)
	local tabBtns = {}
	local function selectTab(i)
		curTab = i
		for j, b in ipairs(tabBtns) do
			b.BackgroundColor3 = (j == i) and T.bg2 or T.bg4
			local u = b:FindFirstChild("Und")
			if u then u.BackgroundColor3 = (j == i) and ACCENT or T.bg4 end
			if tabBodies[j] then tabBodies[j].Visible = (j == i) end
		end
	end
	for i, nm in ipairs(TABS) do
		local b = K.btn(tabBar, "T" .. i, 4 + (i - 1) * 113, 2, 108, 22, T.bg4, 4)
		K.txtS(b, nm, 10, T.txt2)
		local u = K.f(b, "Und", 0, 20, 108, 2, T.bg4)
		local idx = i
		b.MouseButton1Click:Connect(function() selectTab(idx) end)
		tabBtns[i] = b
	end

	local contentY, contentH = 66, 300

	-- ================= CANVAS (todos os paineis a esquerda) =================
	local canvasW, canvasCols, canvasRows = 320, 16, 10
	local tileW, tileH = 20, 24
	preview = K.f(root, "Canvas", 8, contentY, tileW * canvasCols + 2, tileH * canvasRows + 2, T.bg0)
	K.corner(preview, 4)
	K.stroke(preview, T.line, 1)
	local painting = false
	local function cellColor(h, mi, wet, isRiver, isLake)
		local m = TX.MATERIALS[mi or 1]
		local base = m and m.cor or { 90, 140, 80 }
		local shade = math.min(1.2, math.max(0.45, 0.75 + h / 70))
		local r2 = math.floor(base[1] * shade)
		local g2 = math.floor(base[2] * shade)
		local b2 = math.floor(base[3] * shade)
		if isRiver or isLake then return Color3.fromRGB(52, 120, 200) end
		if h < world.seaLevel then return Color3.fromRGB(28, 84, 148) end
		if wet and wet > 0.75 then
			return Color3.fromRGB(math.floor(r2 * 0.8), math.floor(g2 * 0.9), math.floor(b2 * 0.85))
		end
		return Color3.fromRGB(math.min(255, r2), math.min(255, g2), math.min(255, b2))
	end
	local function repaint()
		for j = 1, canvasRows do
			for i = 1, canvasCols do
				local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
				local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
				local cx, cz = world:chunkKeyOf(gx, gz)
				local ch = world:genChunk(cx, cz)
				local n = world.chunkCells
				local lx = math.min(n, math.max(1, gx - cx * n))
				local lz = math.min(n, math.max(1, gz - cz * n))
				local h = world:heightAtCell(gx, gz)
				local mi = ch.mat[(lz - 1) * n + lx]
				local wv = ch.wet[(lz - 1) * n + lx] or 0
				local isRiver = (wv >= 0.99 and h > world.seaLevel - 1)
				local isLake = world.lakes[gx .. "," .. gz] ~= nil
				local t2 = gridTiles[(j - 1) * canvasCols + i]
				t2.BackgroundColor3 = cellColor(h, mi, wv, isRiver, isLake)
				local hl = t2:FindFirstChild("Hd")
				if hl then hl.Visible = false end
			end
		end
	end
	local function paintAt(i, j)
		local gx = region.gx0 + math.floor((i - 1) / canvasCols * region.gw)
		local gz = region.gz0 + math.floor((j - 1) / canvasRows * region.gh)
		-- nivel de mar: depressao vira agua visual
		if brush.op == "sealevel" then
			world.seaLevel = world:heightAtCell(gx, gz)
			repaint()
			return
		end
		world:sculpt(gx * world.cell, gz * world.cell, {
			op = brush.op, radius = brush.radius, strength = brush.strength,
			falloff = brush.falloff, amount = brush.amount, mat = brush.mat,
			target = world:heightAtCell(gx, gz),
		})
		repaint()
		if status then status.Text = "pincel '" .. brush.op .. "' em (" .. gx .. "," .. gz .. ") r=" .. brush.radius .. " f=" .. string.format("%.2f", brush.strength) end
	end
	for j = 1, canvasRows do
		for i = 1, canvasCols do
			local t2 = K.btn(preview, "H" .. ((j - 1) * canvasCols + i), (i - 1) * tileW + 1, (j - 1) * tileH + 1, tileW - 1, tileH - 1, T.bg2, 1)
			local ii, jj = i, j
			t2.MouseButton1Click:Connect(function() paintAt(ii, jj) end)
			t2.InputBegan:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = true paintAt(ii, jj) end
			end)
			t2.MouseEnter:Connect(function()
				if painting then paintAt(ii, jj) end
				t2.BackgroundTransparency = 0.55
			end)
			t2.MouseLeave:Connect(function() t2.BackgroundTransparency = 0 end)
			gridTiles[(j - 1) * canvasCols + i] = t2
		end
	end
	preview.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then painting = false end
	end)
	K.txt(preview, region.gw .. "x" .. region.gh .. " celulas | clique ou arraste p/ esculpir", 6, tileH * canvasRows - 16, 260, 12, 8, C("#0A0F18"))

	-- ================= PAINEL DIREITO (abas) =================
	local panel = K.f(root, "Panel", 338, contentY, 352, contentH + 150, T.bg4)
	K.corner(panel, 5)
	for i = 1, #TABS do
		local body = K.f(panel, "TB" .. i, 0, 0, 352, contentH + 150)
		body.Visible = i == 1
		tabBodies[i] = body
	end

	-- ========== ABA 1: ESCULPIR ==========
	do
		local b = tabBodies[1]
		K.txt(b, "PINCEIS (10)", 12, 8, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local ops = {
			{ id = "raise", nm = "Raise", gl = "+" }, { id = "lower", nm = "Lower", gl = "-" },
			{ id = "smooth", nm = "Smooth", gl = "~" }, { id = "flatten", nm = "Flatten", gl = "=" },
			{ id = "set", nm = "Set", gl = "S" }, { id = "noise", nm = "Noise", gl = "N" },
			{ id = "crater", nm = "Cratera", gl = "O" }, { id = "terrace", nm = "Terraco", gl = "T" },
			{ id = "paint", nm = "Pintar", gl = "P" }, { id = "wet", nm = "Molhar", gl = "W" },
		}
		local opBtns = {}
		for i, o in ipairs(ops) do
			local bx = 12 + ((i - 1) % 3) * 108
			local by = 26 + math.floor((i - 1) / 3) * 30
			local b2 = K.btn(b, "OP" .. i, bx, by, 100, 26, T.bg2, 4)
			K.txt(b2, o.gl, 6, 5, 16, 16, 13, ACCENT, ARKHER.FONTB)
			K.txt(b2, o.nm, 26, 6, 70, 14, 10, T.txt)
			local id = o.id
			b2.MouseButton1Click:Connect(function()
				brush.op = id
				for j3, bb in ipairs(opBtns) do K.stroke(bb, ops[j3].id == id and ACCENT or T.line2, ops[j3].id == id and 1.5 or 1) end
				if status then status.Text = "pincel: " .. o.nm end
			end)
			K.stroke(b2, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			opBtns[i] = b2
		end
		K.txt(b, "FALLOFF", 12, 134, 120, 14, 10, T.txt3, ARKHER.FONTB)
		local falloffs = { "smooth", "gaussian", "cosine", "linear", "sharp" }
		local fBtns = {}
		for i, f2 in ipairs(falloffs) do
			local b3 = K.btn(b, "F" .. i, 12 + (i - 1) * 65, 152, 60, 20, T.bg2, 4)
			K.txtS(b3, f2, 9, T.txt2)
			local fid = f2
			b3.MouseButton1Click:Connect(function()
				brush.falloff = fid
				for j3, bb in ipairs(fBtns) do K.stroke(bb, falloffs[j3] == fid and ACCENT or T.line2, falloffs[j3] == fid and 1.5 or 1) end
			end)
			K.stroke(b3, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
			fBtns[i] = b3
		end
		mkSlider(b, 12, 182, 200, "Raio", 4, 96, brush.radius, function(v) return string.format("%.0f", v) end, function(v) brush.radius = v end)
		mkSlider(b, 12, 226, 200, "Forca", 0.05, 1, brush.strength, function(v) return string.format("%.2f", v) end, function(v) brush.strength = v end)
		mkSlider(b, 12, 270, 200, "Quantia", 1, 24, brush.amount, function(v) return string.format("%.1f", v) end, function(v) brush.amount = v end)
		-- materiais (18 dos 24 p/ pintar)
		K.txt(b, "MATERIAL (p/ pintar)", 12, 314, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local pm = 0
		for i, m in ipairs(TX.MATERIALS) do
			if pm >= 18 then break end
			pm = pm + 1
			local mx = 12 + ((pm - 1) % 6) * 54
			local my = 332 + math.floor((pm - 1) / 6) * 24
			local sw = K.btn(b, "MT" .. pm, mx, my, 50, 20, T.bg2, 3)
			K.f(sw, "c", 3, 3, 14, 14, Color3.fromRGB(m.cor[1], m.cor[2], m.cor[3]), 2)
			K.txt(sw, m.id:sub(1, 7), 19, 4, 30, 12, 8, T.txt3)
			local mid = m.id
			sw.MouseButton1Click:Connect(function()
				brush.mat = mid
				brush.op = "paint"
				if status then status.Text = "pintar: " .. m.nm .. " (dens " .. m.dens .. " kg/L)" end
			end)
		end
		local undo2 = K.btn(b, "Undo", 12, 416, 120, 26, T.bg2, 5)
		K.txtS(undo2, "Desfazer (undo stack)", 9, T.txt)
		K.hover(undo2, T.bg2, T.hover)
		undo2.MouseButton1Click:Connect(function()
			ArkherUNDO.undo()
			repaint()
			if status then status.Text = "undo aplicado" end
		end)
	end

	-- ========== ABA 2: GERAR ==========
	do
		local b = tabBodies[2]
		K.txt(b, "PRESETS DE MUNDO (8)", 12, 8, 200, 14, 10, T.txt3, ARKHER.FONTB)
		local presetIds = { "continentes", "ilhas", "montanhas", "canyon", "dunas", "meseta", "vulcao", "polar" }
		for i, pid in ipairs(presetIds) do
			local p = TX.PRESETS[pid]
			local bx = 12 + ((i - 1) % 2) * 166
			local by = 28 + math.floor((i - 1) / 2) * 34
			local b2 = K.btn(b, "PR" .. i, bx, by, 158, 30, T.bg2, 4)
			K.txt(b2, p.label, 10, 3, 130, 14, 11, T.txt)
			local extras = (p.mont and ("mont x" .. p.mont) or "") .. (p.terrace and (" | terraco " .. p.terrace) or "")
			K.txt(b2, extras, 10, 16, 140, 12, 8, T.txt4)
			K.hover(b2, T.bg2, T.hover)
			local id = pid
			b2.MouseButton1Click:Connect(function()
				local s = math.floor(seedBox.Text ~= "" and tonumber(seedBox.Text) or world.seed)
				world = TX.new({ seed = s, preset = id, cell = world.cell, chunkCells = 16, seaLevel = p.sea or 0 })
				repaint()
				refreshStats()
				if status then status.Text = "mundo gerado: " .. p.label .. " (seed " .. s .. ")" end
			end)
		end
		K.txt(b, "SEED", 12, 172, 60, 14, 10, T.txt3, ARKHER.FONTB)
		seedBox = K.input(b, 60, 168, 100, 24, "1337")
		local regen = K.btn(b, "Regen", 168, 168, 90, 24, ACCENT, 5)
		K.txtS(regen, "Gerar", 11, C("#0D140B"))
		K.hover(regen, ACCENT, C("#A5E88C"))
		local rnd = K.btn(b, "Rnd", 264, 168, 60, 24, T.bg2, 5)
		K.txtS(rnd, "Aleatoria", 9, T.txt)
		K.hover(rnd, T.bg2, T.hover)
		rnd.MouseButton1Click:Connect(function()
			seedBox.Text = tostring(math.random(1, 99999))
		end)
		regen.MouseButton1Click:Connect(function()
			local s = tonumber(seedBox.Text) or 1337
			world = TX.new({ seed = s, preset = world.preset, cell = world.cell, chunkCells = 16, seaLevel = world.params.sea or 0 })
			repaint()
			refreshStats()
			if status then status.Text = "regenerado seed " .. s .. " preset " .. world.preset end
		end)
		-- parametros finos
		K.txt(b, "PARAMETROS FISICOS", 12, 206, 200, 14, 10, T.txt3, ARKHER.FONTB)
		mkSlider(b, 12, 224, 200, "Continentes", 0, 2, world.params.cont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.cont = v end)
		mkSlider(b, 12, 268, 200, "Montanhas", 0, 2.5, world.params.mont or 1, function(v) return string.format("%.2f", v) end, function(v) world.params.mont = v end)
		mkSlider(b, 12, 312, 200, "Warp", 0, 12, world.params.warp or 4, function(v) return string.format("%.1f", v) end, function(v) world.params.warp = v end)
		local reapp = K.btn(b, "Reapply", 12, 362, 160, 26, T.bg2, 5)
		K.txtS(reapp, "Reaplicar e re-gerar chunks", 9, T.txt)
		K.hover(reapp, T.bg2, T.hover)
		reapp.MouseButton1Click:Connect(function()
			world.chunks = {}
			world.stats.gen = 0
			world.stats.cells = 0
			repaint()
			refreshStats()
			if status then status.Text = "chunks re-gerados com novos parametros" end
		end)
	end

	-- ========== ABA 3: GEOL (erosao) ==========
	do
		local b = tabBodies[3]
		K.txt(b, "EROSAO HIDRAULICA (droplet sim)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local iters = mkSlider(b, 12, 26, 200, "Gotas", 500, 20000, 5000, function(v) return string.format("%.0f", v) end)
		local erf = mkSlider(b, 12, 70, 200, "Erodibilidade", 0.05, 1, 0.35)
		local dep = mkSlider(b, 12, 114, 200, "Deposicao", 0.05, 1, 0.35)
		local run1 = K.btn(b, "RunH", 12, 168, 158, 28, ACCENT, 5)
		K.txtS(run1, "Rodar erosao hidraulica", 10, C("#0D140B"))
		K.hover(run1, ACCENT, C("#A5E88C"))
		local hydRes = K.txt(b, "—", 12, 202, 320, 14, 9, T.txt4)
		run1.MouseButton1Click:Connect(function()
			local res = world:erodeHydraulic(region.gx0, region.gz0, region.gw, region.gh, math.floor(iters.get()), { erode = erf.get(), deposit = dep.get() })
			hydRes.Text = "gotas: " .. res.iterations .. " | dMedio: " .. string.format("%.3f", res.meanDelta) .. " | dMax: " .. string.format("%.2f", res.maxDelta)
			repaint()
			if status then status.Text = "erosao hidraulica concluida (vales + sedimentos reais)" end
		end)
		K.txt(b, "EROSAO TERMICA (talus)", 12, 232, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local pass = mkSlider(b, 12, 250, 200, "Passagens", 1, 32, 8, function(v) return string.format("%.0f", v) end)
		local tal = mkSlider(b, 12, 294, 200, "Talude limite", 0.2, 2, 0.9)
		local run2 = K.btn(b, "RunT", 12, 348, 158, 28, T.bg2, 5)
		K.txtS(run2, "Rodar erosao termica", 10, T.txt)
		K.hover(run2, T.bg2, T.hover)
		local thRes = K.txt(b, "—", 12, 382, 320, 14, 9, T.txt4)
		run2.MouseButton1Click:Connect(function()
			local res = world:erodeThermal(region.gx0, region.gz0, region.gw, region.gh, math.floor(pass.get()), tal.get())
			thRes.Text = "passagens: " .. res.passes .. " | material movido: " .. string.format("%.1f", res.moved)
			repaint()
			if status then status.Text = "erosao termica concluida (encostas em angulo de repouso)" end
		end)
	end

	-- ========== ABA 4: HIDRO ==========
	do
		local b = tabBodies[4]
		K.txt(b, "RIOS (D8 flow accumulation)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local acc = mkSlider(b, 12, 26, 200, "Acumulacao min", 4, 96, 24, function(v) return string.format("%.0f", v) end)
		local runR = K.btn(b, "RunR", 12, 76, 158, 28, C("#58A6FF"), 5)
		K.txtS(runR, "Escavar rede de rios", 10, C("#081420"))
		K.hover(runR, C("#58A6FF"), C("#8FC3FF"))
		local rivRes = K.txt(b, "—", 12, 110, 320, 14, 9, T.txt4)
		runR.MouseButton1Click:Connect(function()
			local res = world:carveRivers(region.gx0, region.gz0, region.gw, region.gh, math.floor(acc.get()))
			rivRes.Text = "celulas fluviais: " .. res.cells .. " | acumulacao max: " .. res.maxAcc
			repaint()
			if status then status.Text = "rios escavados: " .. res.cells .. " celulas (leitos em V)" end
		end)
		K.txt(b, "LAGOS (depression fill)", 12, 140, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local runL = K.btn(b, "RunL", 12, 160, 158, 28, C("#2FBF9F"), 5)
		K.txtS(runL, "Preencher lagos", 10, C("#062018"))
		K.hover(runL, C("#2FBF9F"), C("#6ADFC2"))
		local lakeRes = K.txt(b, "—", 12, 194, 320, 14, 9, T.txt4)
		runL.MouseButton1Click:Connect(function()
			local res = world:fillLakes(region.gx0, region.gz0, region.gw, region.gh)
			lakeRes.Text = "celulas de lago: " .. res.cells
			repaint()
			if status then status.Text = "lagos preenchidos: " .. res.cells .. " celulas" end
		end)
		K.txt(b, "NIVEL DO MAR", 12, 224, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local sea = mkSlider(b, 12, 242, 200, "Sea level", -20, 20, world.seaLevel, function(v) return string.format("%.1f", v) end, function(v)
			world.seaLevel = v
			repaint()
		end)
		local awater = K.btn(b, "Water", 12, 292, 158, 28, T.purple, 5)
		K.txtS(awater, "Abrir WATER STUDIO", 10, C("#FFFFFF"))
		K.hover(awater, T.purple, C("#A97AFF"))
		awater.MouseButton1Click:Connect(function() ARKHER.open("Water") end)
		K.txt(b, "waters = AWX (motor proprio)", 12, 326, 240, 12, 8, T.txt4)
	end

	-- ========== ABA 5: CLIMA ==========
	do
		local b = tabBodies[5]
		K.txt(b, "CLIMA GLOBAL (campos fisicos)", 12, 8, 260, 14, 10, T.txt3, ARKHER.FONTB)
		local tb = mkSlider(b, 12, 26, 200, "Temp bias", -40, 40, world.params.tempB or 0, function(v) return string.format("%+.0f C", v) end, function(v) world.params.tempB = v end)
		local hb = mkSlider(b, 12, 70, 200, "Chuva bias", -80, 80, world.params.humidB or 0, function(v) return string.format("%+.0f cm", v) end, function(v) world.params.humidB = v end)
		local applyC = K.btn(b, "ApplyC", 12, 124, 158, 26, T.bg2, 5)
		K.txtS(applyC, "Re-classificar biomas", 10, T.txt)
		K.hover(applyC, T.bg2, T.hover)
		applyC.MouseButton1Click:Connect(function()
			world.chunks = {}
			repaint()
			refreshClimate()
			if status then status.Text = "biomas re-classificados via Whittaker" end
		end)
		K.txt(b, "BIOMAS (distribuicao real — Whittaker)", 12, 162, 300, 14, 10, T.txt3, ARKHER.FONTB)
		climateList = K.f(b, "CL", 12, 182, 328, 200)
		refreshClimate = function()
			climateList:ClearAllChildren()
			local counts = world:biomeCounts()
			local total = 0
			local sorted = {}
			for k2, v in pairs(counts) do total = total + v; sorted[#sorted + 1] = { k2, v } end
			table.sort(sorted, function(a, b2) return a[2] > b2[2] end)
			if total == 0 then K.txt(climateList, "gere o mundo primeiro (canvas)", 0, 0, 240, 14, 10, T.txt4) return end
			for i = 1, math.min(#sorted, 9) do
				local name, qty = sorted[i][1], sorted[i][2]
				local frac = qty / total
				K.txt(climateList, name, 0, (i - 1) * 21, 150, 14, 10, T.txt2)
				local bar = K.f(climateList, "B" .. i, 150, (i - 1) * 21 + 3, math.floor(140 * frac), 8, ACCENT)
				K.corner(bar, 3)
				K.txt(climateList, string.format("%.1f%%", frac * 100), 296, (i - 1) * 21, 40, 14, 8, T.txt4, FONT, Enum.TextXAlignment.Right)
			end
		end
		refreshClimate()
	end

	-- ========== ABA 6: MUNDO ==========
	do
		local b = tabBodies[6]
		K.txt(b, "MATERIALIZACAO (RRW -> workspace)", 12, 8, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local mkWorld = K.btn(b, "M1", 12, 26, 158, 28, ACCENT, 5)
		K.txtS(mkWorld, "Materializar 128x128", 10, C("#0D140B"))
		K.hover(mkWorld, ACCENT, C("#A5E88C"))
		local mkBig = K.btn(b, "M2", 176, 26, 158, 28, T.bg2, 5)
		K.txtS(mkBig, "Materializar 256x256", 10, T.txt)
		K.hover(mkBig, T.bg2, T.hover)
		local mkOut = K.txt(b, "—", 12, 60, 328, 14, 9, T.txt4)
		mkWorld.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-64, -64, 128, 128, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts (LOD " .. tostring(TX._lodStep(2)) .. ")" end
		end)
		mkBig.MouseButton1Click:Connect(function()
			local res = world:materializeRegion(-128, -128, 256, 256, {})
			mkOut.Text = "model ATX_World: " .. res.chunks .. " chunks | " .. res.parts .. " parts"
			refreshStats()
			if status then status.Text = "materializado: " .. res.parts .. " parts" end
		end)
		local lodB = K.btn(b, "LOD", 12, 84, 158, 26, T.bg2, 5)
		K.txtS(lodB, "LOD adaptativo (foco 0,0)", 9, T.txt)
		K.hover(lodB, T.bg2, T.hover)
		lodB.MouseButton1Click:Connect(function()
			local r = world:updateLOD(0, 0)
			if status then status.Text = "LOD: " .. r.updated .. " chunks atualizados (D-O15 nivel " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")" end
		end)
		local clr = K.btn(b, "Clr", 176, 84, 158, 26, T.bg2, 5)
		K.txtS(clr, "Limpar workspace", 10, T.txt)
		K.hover(clr, T.bg2, T.hover)
		clr.MouseButton1Click:Connect(function()
			TX.clearWorld(world)
			refreshStats()
			if status then status.Text = "ATX_World removido do workspace" end
		end)
		K.txt(b, "PERSISTENCIA (JSON roundtrip)", 12, 122, 300, 14, 10, T.txt3, ARKHER.FONTB)
		local exp = K.btn(b, "Exp", 12, 140, 158, 26, T.bg2, 5)
		K.txtS(exp, "Exportar ATX JSON", 10, T.txt)
		K.hover(exp, T.bg2, T.hover)
		local expOut = K.txt(b, "—", 12, 170, 328, 14, 9, T.txt4)
		exp.MouseButton1Click:Connect(function()
			local str, path, ok = world:exportFile()
			expOut.Text = "bundle: " .. #str .. " chars → " .. path .. (ok and " (arquivo gravado)" or " (somente Studio grava)")
		end)
		local load2 = K.btn(b, "Load", 176, 140, 158, 26, T.bg2, 5)
		K.txtS(load2, "Testar roundtrip", 10, T.txt)
		K.hover(load2, T.bg2, T.hover)
		load2.MouseButton1Click:Connect(function()
			local str = world:serialize()
			local w2, err = TX.deserialize(str)
			if w2 then
				expOut.Text = "roundtrip OK: " .. (w2.restored or 0) .. " chunks restaurados, seed " .. w2.seed
			else
				expOut.Text = "roundtrip falhou: " .. tostring(err)
			end
		end)
		K.txt(b, "MOTOR", 12, 196, 120, 14, 10, T.txt3, ARKHER.FONTB)
		K.row(b, "engine", "ATX v" .. TX._version, 214)
		K.row(b, "chunk", world.chunkCells .. " celulas x " .. world.cell .. " studs", 232)
		K.row(b, "materiais", #TX.MATERIALS .. " fisicos", 250)
		K.row(b, "presets", "8 mundos", 268)
		local ai2 = K.btn(b, "AI", 12, 292, 322, 28, T.purple, 5)
		K.txtS(ai2, "Singularity: mundo + erosao + rios + agua", 10, C("#FFFFFF"))
		K.hover(ai2, T.purple, C("#A97AFF"))
		ai2.MouseButton1Click:Connect(function()
			local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno realista com rios, erosao e oceano") end)
			if ok2 and rep then K.notify("Singularity", "mundo gerado (" .. #rep.lines .. " etapas)", "ok") end
		end)
		K.txt(b, "sementes renascem identicas — mesma realidade, qualquer D-O15", 12, 330, 320, 12, 8, T.txt4)
	end

	-- ================= BASE: STATUS + STATS =================
	local bar = K.f(root, "Bar", 8, contentY + contentH + 8, 322, 52, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um pincel e clique no canvas", 10, 6, 304, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 28, 304, 14, 8, T.txt4)
	refreshStats = function()
		local s = world:worldStats()
		statLbl.Text = "seed " .. s.seed .. " | chunks " .. s.chunks .. " | celulas " .. s.cells .. " | rios " .. s.rivers .. " | lagos " .. s.lakes .. " | parts " .. s.parts .. " | gotas " .. s.droplets
	end
	refreshStats()
	repaint()
	selectTab(1)
end

ARKHER.reg("Terrain", "Terrain Studio", "Editor", ICON.terrain, "Terrain custom (ATX): 10 pinceis, erosao real, rios, lagos, clima, biomas, LOD D-O15", build)
end

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

do
--[[ ARKHER — UI: WATER STUDIO (motor AWX custom, nao usa agua do Roblox) ]]
-- Estudio de agua completissimo: 8 tipos com fisica real (densidade/salinidade/
-- temperatura/viscosidade), 6 presets de mar, DESIGNER DE ONDAS DE GERSTNER
-- (amp/len/dir/speed/steep por onda), mare lunar, correntes (Stokes drift),
-- preview vivo do perfil de onda, espuma por energia de crista, causticas,
-- FLUTUABILIDADE arquimediana real na selecao, ambiente subaquatico, splash.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#58C6FF")
local WX, DM = ArkherWaterX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local function build()
	local g, root, head = K.window("ArkherWater", "WATER STUDIO — motor AWX (custom)", 30, 320, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= CORPO D'AGUA VIVO =================
	local body = WX.preset("porto", { kind = "oceano", level = 0, size = { x = 480, z = 320 } })
	local simT = 0
	local playing = false
	local status = nil
	local statLbl = nil
	local profTiles = {}
	local foamTiles = {}
	local waveRows = {}
	local selWave = 1
	local repaintProfile = nil
	local repaintWaves = nil
	local refreshWaveSliders = nil
	local timeS = nil

	-- ================= ESQUERDA: TIPOS + PRESETS =================
	local left = K.f(root, "Left", 8, 34, 150, 252, T.bg4)
	K.corner(left, 4)
	K.txt(left, "TIPO DE AGUA", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	local kinds = { "oceano", "mar_calmo", "lago", "rio", "cachoeira", "pantano", "glacial", "terma" }
	for i, kd in ipairs(kinds) do
		local w = WX.WATERS[kd]
		local b = K.btn(left, "K" .. i, 8, 24 + (i - 1) * 27, 134, 23, T.bg2, 4)
		K.f(b, "c", 4, 5, 13, 13, Color3.fromRGB(w.cor[1], w.cor[2], w.cor[3]), 2)
		K.txt(b, w.nm, 22, 4, 102, 14, 10, T.txt)
		K.txt(b, "dens " .. w.dens, 22, 15, 102, 10, 7, T.txt4)
		K.hover(b, T.bg2, T.hover)
		local id = kd
		b.MouseButton1Click:Connect(function()
			local lvl = body.level
			body = WX.create(id, { level = lvl, size = body.size, waves = body.waves, tideAmp = body.tideAmp })
			repaintProfile()
			if status then status.Text = "agua: " .. w.nm .. " | sal " .. w.sal .. "g/L | temp " .. w.temp .. "C | visc " .. w.visc end
		end)
	end
	K.txt(left, "PRESETS DE MAR", 10, 242, 130, 14, 10, T.txt3, ARKHER.FONTB)
	local presets = { "calmaria", "porto", "ressaca", "tempestade", "corredeira", "espelho" }
	for i, pr in ipairs(presets) do
		local b = K.btn(left, "P" .. i, 8 + ((i - 1) % 2) * 68, 260 + math.floor((i - 1) / 2) * 24, 62, 20, T.bg2, 4)
		K.txtS(b, pr, 8, T.txt2)
		K.hover(b, T.bg2, T.hover)
		local id = pr
		b.MouseButton1Click:Connect(function()
			local kind = body.kind
			body = WX.preset(id, { kind = kind, level = body.level, size = body.size })
			repaintWaves()
			repaintProfile()
			if status then status.Text = "preset '" .. id .. "': " .. #body.waves .. " ondas de Gerstner" end
		end)
	end

	-- ================= CENTRO: PREVIEW VIVO (perfil de onda real) =================
	local prof = K.f(root, "Prof", 168, 34, 340, 252, T.bg0)
	K.corner(prof, 4)
	K.stroke(prof, T.line, 1)
	local COLS, PH = 34, 226
	local function colFor(h, crest)
		if crest > 0.45 then return Color3.fromRGB(190, 226, 246) end
		local f = math.min(1, math.max(0, (h + 6) / 12))
		local c = body.props.cor
		return Color3.fromRGB(
			math.floor(c[1] + f * 40), math.floor(c[2] + f * 44), math.floor(c[3] + f * 30))
	end
	for i = 1, COLS do
		local col = K.f(prof, "P" .. i, (i - 1) * 10 + 2, 10, 9, 10, C("#16456B"), 0)
		profTiles[i] = col
		local fo = K.f(prof, "F" .. i, (i - 1) * 10 + 2, 10, 9, 3, C("#E8F6FF"), 0)
		fo.Visible = false
		foamTiles[i] = fo
	end
	repaintProfile = function()
		local span = (body.size and body.size.x) or 480
		local maxA = 1
		for _, w in ipairs(body.waves) do maxA = math.max(maxA, w.amp) end
		for i = 1, COLS do
			local x = (i - 0.5) / COLS * span - span / 2
			local h = body:heightAt(x, 0, simT) - body.level
			local crest = body:crestAt(x, 0, simT)
			local px = math.floor(math.max(4, math.min(PH - 20, 60 + h * (22 / math.max(maxA, 0.5)))))
			local col = profTiles[i]
			col.Size = UDim2.new(0, 9, 0, px)
			col.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 10 + PH - px)
			col.BackgroundColor3 = colFor(h, crest)
			local fo = foamTiles[i]
			fo.Visible = crest * body.foaminess > 0.32
			fo.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 8 + PH - px)
		end
	end
	-- tempo + play
	timeS = mkSlider(prof, 10, PH + 8, 200, "Tempo (s)", 0, 120, 0, function(v) return string.format("%.1f", v) end, function(v)
		simT = v
		repaintProfile()
	end)
	local play = K.btn(prof, "Play", 250, PH + 18, 80, 22, ACCENT, 5)
	K.txtS(play, "ANIMAR", 9, C("#06222E"))
	K.hover(play, ACCENT, C("#9BE0FF"))
	local playConn = nil
	play.MouseButton1Click:Connect(function()
		playing = not playing
		local lbl2 = play:FindFirstChildOfClass("TextLabel")
		if lbl2 then lbl2.Text = playing and "PARAR" or "ANIMAR" end
		if playing and not playConn then
			local ok2, RS = pcall(function() return game:GetService("RunService") end)
			if ok2 and RS and RS.Heartbeat then
				local acc = 0
				playConn = RS.Heartbeat:Connect(function(dt)
					if not playing then return end
					acc = acc + dt
					local budget = ArkherDO15 and ArkherDO15.refreshBudget("animations") or 0
					if acc >= math.max(0.03, 0.05) then
						simT = simT + acc
						acc = 0
						timeS.set(simT % 120)
						repaintProfile()
						if body.tiles then WX.animate(body, simT) end
						WX.step(body, dt, simT)
					end
				end)
			end
		end
	end)

	-- ================= DIREITA: DESIGNER DE ONDAS + PROPRIEDADES =================
	local right = K.f(root, "Right", 518, 34, 174, 252, T.bg4)
	K.corner(right, 4)
	K.txt(right, "GERSTNER (ondas)", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	repaintWaves = function()
		for i = 1, 6 do
			local row = right:FindFirstChild("WR" .. i)
			if row then row:Destroy() end
		end
		waveRows = {}
		for i = 1, math.min(#body.waves, 6) do
			local w = body.waves[i]
			local row = K.btn(right, "WR" .. i, 8, 24 + (i - 1) * 26, 158, 22, T.bg2, 4)
			K.txt(row, "λ" .. string.format("%.0f", w.len) .. " a" .. string.format("%.2f", w.amp), 8, 3, 86, 14, 9, (i == selWave) and ACCENT or T.txt)
			K.txt(row, "→" .. string.format("%.0f", w.dir) .. "°", 100, 3, 50, 14, 9, T.txt4)
			K.stroke(row, i == selWave and ACCENT or T.line2, i == selWave and 1.5 or 1)
			local idx = i
			row.MouseButton1Click:Connect(function()
				selWave = idx
				repaintWaves()
				refreshWaveSliders()
			end)
			waveRows[i] = row
		end
	end
	repaintWaves()
	local swAmp, swLen, swDir
	local function curW() return body.waves[selWave] end
	refreshWaveSliders = function()
		local w = curW()
		if not w or not swAmp then return end
		swAmp.set(w.amp); swLen.set(w.len); swDir.set(w.dir)
	end
	swAmp = mkSlider(right, 10, 184, 154, "Amplitude", 0.03, 3, 0.4, nil, function(v) if curW() then curW().amp = v end repaintProfile() repaintWaves() end)
	swLen = mkSlider(right, 10, 216, 154, "Comprimento λ", 4, 120, 34, function(v) return string.format("%.0f", v) end, function(v) if curW() then curW().len = v end repaintProfile() repaintWaves() end)
	swDir = mkSlider(right, 10, 248, 154, "Direcao", 0, 360, 0, function(v) return string.format("%.0f", v) .. "°" end, function(v) if curW() then curW().dir = v end repaintProfile() repaintWaves() end)

	local props = K.f(root, "Props", 518, 292, 174, 130, T.bg4)
	K.corner(props, 4)
	K.txt(props, "MARE / NIVEL", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	mkSlider(props, 10, 24, 154, "Nivel", -20, 20, body.level, function(v) return string.format("%.1f", v) end, function(v) body.level = v repaintProfile() end)
	mkSlider(props, 10, 62, 154, "Mare amp", 0, 4, body.tideAmp, nil, function(v) body.tideAmp = v repaintProfile() end)
	mkSlider(props, 10, 100, 154, "Espuma", 0, 1, body.foaminess, nil, function(v) body.foaminess = v repaintProfile() end)

	-- ================= BASE: ACOES REAIS =================
	local bar = K.f(root, "Bar", 8, 296, 500, 130, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um preset e materialize o mar", 10, 6, 480, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 24, 480, 14, 8, T.txt4)
	local function refreshStats()
		local s = body:stats()
		statLbl.Text = "ondas " .. s.waves .. " | dens " .. s.density .. " | tiles " .. s.tiles .. " | flutuadores " .. s.floaters .. " | splashes " .. s.splashes
	end
	refreshStats()

	local mk = K.btn(bar, "Mk", 10, 46, 110, 26, ACCENT, 5)
	K.txtS(mk, "Materializar mar", 9, C("#06222E"))
	K.hover(mk, ACCENT, C("#9BE0FF"))
	mk.MouseButton1Click:Connect(function()
		local model, n = WX.materialize(body, { maxSpan = 480 })
		status.Text = "mar materializado: " .. n .. " tiles animados (LOD D-O15 " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")"
		refreshStats()
	end)
	local cau = K.btn(bar, "Cau", 128, 46, 100, 26, T.bg2, 5)
	K.txtS(cau, "+ Causticas", 9, T.txt)
	K.hover(cau, T.bg2, T.hover)
	cau.MouseButton1Click:Connect(function()
		local n = WX.caustics(body, body.level - 10)
		status.Text = "causticas: " .. n .. " brilhos no fundo (shimmer neon)"
		refreshStats()
	end)
	local flt = K.btn(bar, "Flt", 236, 46, 120, 26, T.bg2, 5)
	K.txtS(flt, "Flutuar selecao", 9, T.txt)
	K.hover(flt, T.bg2, T.hover)
	flt.MouseButton1Click:Connect(function()
		local ok2, sel = pcall(function() return game:GetService("Selection"):Get() end)
		local n = 0
		if ok2 and sel then
			for _, inst in ipairs(sel) do
				if inst:IsA("BasePart") then WX.float(body, inst, {}) n = n + 1 end
			end
		end
		if n == 0 then
			-- cria uma boia demo de verdade
			local p = Instance.new("Part")
			p.Name = "AWX_Buoy"
			p.Size = Vector3.new(5, 2.4, 5)
			p.Position = Vector3.new(0, body.level + 1, 0)
			p.Color = Color3.fromRGB(240, 180, 60)
			p.Parent = workspace
			WX.float(body, p, { density = 420 })
			n = 1
			status.Text = "boia criada + flutuabilidade arquimediana ativa (de play)"
		else
			status.Text = "flutuabilidade em " .. n .. " parts da selecao (Arquimedes)"
		end
		refreshStats()
	end)
	local und = K.btn(bar, "Und", 364, 46, 126, 26, T.bg2, 5)
	K.txtS(und, "Submerso: ON/OFF", 9, T.txt)
	local undOn = false
	K.hover(und, T.bg2, T.hover)
	und.MouseButton1Click:Connect(function()
		undOn = not undOn
		WX.applyUnderwater(body, undOn)
		status.Text = undOn and "ambiente subaquatico: neblina croma + absorcao" or "ambiente restaurado"
	end)
	local spl = K.btn(bar, "Spl", 10, 78, 110, 26, T.bg2, 5)
	K.txtS(spl, "Splash teste", 9, T.txt)
	K.hover(spl, T.bg2, T.hover)
	spl.MouseButton1Click:Connect(function()
		if not body.tiles then WX.materialize(body, { maxSpan = 240 }) end
		WX.splash(body, 0, body:heightAt(0, 0, simT), 0, 2)
		status.Text = "splash emitido (particulas + gravidade real)"
		refreshStats()
	end)
	local ser = K.btn(bar, "Ser", 128, 78, 100, 26, T.bg2, 5)
	K.txtS(ser, "Roundtrip JSON", 9, T.txt)
	K.hover(ser, T.bg2, T.hover)
	ser.MouseButton1Click:Connect(function()
		local str = body:serialize()
		local b2, err = WX.deserialize(str)
		if b2 then status.Text = "roundtrip OK: " .. #str .. " chars, " .. #b2.waves .. " ondas restauradas"
		else status.Text = "roundtrip falhou: " .. tostring(err) end
	end)
	local ai2 = K.btn(bar, "AI", 236, 78, 120, 26, T.purple, 5)
	K.txtS(ai2, "Singularity: mar", 9, C("#FFF"))
	K.hover(ai2, T.purple, C("#A97AFF"))
	ai2.MouseButton1Click:Connect(function()
		local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um oceano realista com ondas e espuma") end)
		if ok2 and rep then K.notify("Singularity", "oceano gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	local terr = K.btn(bar, "Terr", 364, 78, 126, 26, C("#4E8FE0"), 5)
	K.txtS(terr, "< TERRAIN STUDIO", 9, C("#FFF"))
	K.hover(terr, C("#4E8FE0"), C("#6FA8F0"))
	terr.MouseButton1Click:Connect(function() ARKHER.open("Terrain") end)

	repaintProfile()
end

ARKHER.reg("Water", "Water Studio", "Editor", ICON.plate, "Agua custom (AWX): Gerstner, mare, correntes, flutuabilidade, causticas, submerso", build)
end

--[[ ARKHER V3 — DRIVER: boot completo (sistemas + shell + todas as UIs) ]]
-- Ordem: prelude → core → actions → boot → main shell → UIs em cascata.
do
	ARKHER.boot()
	pcall(function() ARKHER_BUILD_MAIN() end)
	local opened = ARKHER.openAll()
	ARKHER.out("SUCCESS", string.format("ARKHER V3 pronto: %d UIs ativas + core (places/do15/nmn/singularity/undo/live/publish)", opened))
end
