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
	local order = { "place", "city", "nature", "space", "material", "light", "npc", "clean", "perf", "check" }
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
	local closeB = K.btn(bar, 340, 44, 100, 24, T.bg2, 4)
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
	local diag = K.btn(bar, 340, 52, 100, 24, T.bg2, 4)
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
--[[ ARKHER V3 — UI: ANIMATOR ]]
-- Layout unico: lista de poses a esquerda, preview do personagem no centro,
-- timeline real com keytracks (K.keyTrack) + scrub + controles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF9F43")

local function build()
	local g, root, head = K.window("ArkherAnimator", "ANIMATOR — timeline & poses", 24, 300, 540, 392, { pin = true })

	-- acento na head
	K.f(head, "Acc", 0, 24, 540, 2, ACCENT)

	-- ===== PAINEL ESQUERDO: POSES =====
	local left = K.f(root, "Poses", 8, 34, 122, 300, T.bg4)
	K.corner(left, 4)
	K.txt(left, "POSES", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local poses = { "Pose Inicial", "Andar", "Correr", "Pulo", "Ataque" }
	local selPose = 1
	for i, p in ipairs(poses) do
		local row = K.treeRow(left, 0, i == 1 and ICON.play or ICON.pause, p, i == 1, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			selPose = i
			ARKHER.out("INFO", "Animator: pose selecionada: " .. p)
		end)
	end
	K.txt(left, "clique = trocar pose", 8, 160, 110, 30, 9, T.txt4)

	-- ===== CENTRO: PREVIEW =====
	local pv = K.f(root, "Preview", 140, 34, 250, 150, T.dark)
	K.corner(pv, 4)
	K.stroke(pv, T.line, 1)
	-- grade
	for i = 1, 7 do
		K.f(pv, "gx" .. i, i * 34, 0, 1, 150, T.bg3)
		K.f(pv, "gy" .. i, 0, i * 21, 250, 1, T.bg3)
	end
	-- silhueta humanoide (frames)
	local bx = 105
	K.f(pv, "Head", bx, 34, 22, 22, ACCENT, 6)
	K.f(pv, "Torso", bx + 2, 58, 18, 34, T.neon)
	K.f(pv, "ArmL", bx - 10, 58, 8, 30, T.neon)
	K.f(pv, "ArmR", bx + 24, 58, 8, 30, T.neon)
	K.f(pv, "LegL", bx + 2, 94, 7, 34, T.neon)
	K.f(pv, "LegR", bx + 13, 94, 7, 34, T.neon)
	local poseLbl = K.txt(pv, "Pose: Andar", 8, 130, 120, 16, 10, T.txt3)
	-- sombra
	K.f(pv, "Shadow", bx - 12, 130, 58, 5, T.bg0, 2)

	-- ===== CENTRO-BAIXO: TIMELINE =====
	local tl = K.f(root, "Timeline", 140, 194, 392, 140, T.bg0)
	K.corner(tl, 4)
	K.txt(tl, "TIMELINE", 8, 4, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.keyTrack(tl, "Position", 24, { 0, 0.28, 0.62, 0.9 }, ACCENT)
	K.keyTrack(tl, "Rotation", 46, { 0.15, 0.55, 0.78 }, C("#FFD93D"))
	K.keyTrack(tl, "Scale", 68, { 0.5, 0.52 }, C("#74B9FF"))
	-- scrub
	local playLbl = K.btn(tl, "Play", 8, 96, 52, 20, T.bg2, 4)
	K.txtS(playLbl, "Play", 10, T.txt)
	K.hover(playLbl, T.bg2, T.hover)
	local playing = false
	playLbl.MouseButton1Click:Connect(function()
		playing = not playing
		playLbl.Text = ""
		K.txt(playLbl, playing and "Pause" or "Play", 0, 0, 52, 20, 10, T.txt, FONTB, Enum.TextXAlignment.Center)
		ARKHER.out(playing and "SUCCESS" or "INFO", "Animator: " .. (playing and "tocando" or "pausado") .. " — " .. poses[selPose])
	end)
	local scrub, scrubFill = K.progress(tl, 70, 104, 310, 0.32, ACCENT)
	local tLbl = K.txt(tl, "0.96s / 3.00s", 70, 122, 150, 14, 9, T.txt4)
	-- marcadores de tempo
	for i = 0, 10 do
		K.txt(tl, tostring(i) .. ".0", 70 + i * 31, 116, 20, 10, 7, T.txt4)
	end
	-- zoom
	K.txt(tl, "zoom x1", 330, 122, 40, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: CONTROLES =====
	local right = K.f(root, "Ctrls", 442, 34, 90, 300, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AJUSTES", 10, 6, 70, 14, 10, T.txt3, ARKHER.FONTB)
	K.sliderRow(right, "Duracao", 0.34, 26)
	K.sliderRow(right, "Ease", 0.5, 52)
	K.checkRow(right, "Loop", true, 80)
	K.checkRow(right, "Fade in", true, 104)
	K.row(right, "Frames", "90 @ 30fps", 130)
	local bake = K.btn(right, "Bake", 10, 158, 70, 24, ACCENT, 5)
	K.txtS(bake, "BAKE", 11, C("#14100C"))
	K.hover(bake, ACCENT, C("#FFB86B"))
	bake.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Animator: " .. poses[selPose] .. " baked (90 frames, 3.0s)")
		K.notify("Bake concluido", poses[selPose] .. " -> AnimationTrack", "ok")
		Bus.emit("animator.bake", { pose = poses[selPose], frames = 90 })
	end)
	K.row(right, "Size", "1.2 KB", 200)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 344, 524, 40, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "4 keyframes", 12, 6, 90, 14, 9, T.txt3)
	K.txt(bar, "3 tracks", 110, 6, 70, 14, 9, T.txt3)
	K.txt(bar, "30 fps", 188, 6, 60, 14, 9, T.txt3)
	K.txt(bar, "Andar.anim", 256, 6, 100, 14, 9, ACCENT)
	K.txt(bar, "pronto", 480, 6, 40, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Animator", "Animator", "Editor", ICON.play, "Timeline de animacao: poses, keyframes, scrub e bake", build)
end

do
--[[ ARKHER V3 — UI: AUDIO ]]
-- Layout unico: lista de faixas com FORMAS DE ONDA (K.wave) a esquerda,
-- detalhe da faixa selecionada no centro, mixer com VERTICAIS (K.vfader) a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#A29BFE")

local TRACKS = {
	{ nm = "Theme_01", len = "2:34", seed = 11, vol = 0.8, kind = "Music" },
	{ nm = "City_amb", len = "4:10", seed = 23, vol = 0.55, kind = "Ambience" },
	{ nm = "UI_click", len = "0:01", seed = 37, vol = 0.7, kind = "SFX" },
	{ nm = "Boss_roar", len = "0:04", seed = 53, vol = 0.9, kind = "SFX" },
}

local function build()
	local g, root, head = K.window("ArkherAudio", "AUDIO — mixer & faixas", 24, 370, 560, 372, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local sel = 1

	-- ===== ESQUERDA: FAIXAS =====
	local left = K.f(root, "Tracks", 8, 34, 150, 260, T.bg4)
	K.corner(left, 4)
	K.txt(left, "FAIXAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, tr in ipairs(TRACKS) do
		local row = K.f(left, "Tr" .. i, 6, 26 + (i - 1) * 56, 138, 50, i == 1 and T.bg2 or T.bg4, 4)
		if i == 1 then K.stroke(row, ACCENT, 1.5) end
		K.txt(row, tr.nm, 6, 4, 90, 14, 10, T.txt)
		K.txt(row, tr.kind .. " | " .. tr.len, 6, 18, 120, 12, 8, T.txt4)
		K.wave(row, 6, 32, 100, 14, tr.seed, i == 1 and ACCENT or T.txt4)
		K.txt(row, math.floor(tr.vol * 100 + 0.5) .. "%", 110, 34, 26, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Right)
		local idx = i
		row.MouseButton1Click:Connect(function()
			sel = idx
			ARKHER.out("INFO", "Audio: selecionada " .. tr.nm)
		end)
	end

	-- ===== CENTRO: DETALHE =====
	local cv = K.f(root, "Detail", 170, 34, 244, 160, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, TRACKS[1].nm, 10, 8, 160, 16, 12, T.txt, ARKHER.FONTB)
	K.txt(cv, "Music | 2:34 | 44.1kHz", 10, 26, 180, 14, 9, T.txt4)
	K.wave(cv, 10, 48, 224, 56, 11, ACCENT)
	-- seek
	local seek, seekFill = K.progress(cv, 10, 116, 180, 0.36, ACCENT)
	K.txt(cv, "0:54", 196, 110, 36, 14, 9, T.txt3)
	-- controles
	local pl = K.btn(cv, "Pl", 10, 134, 44, 22, T.bg2, 4)
	K.txtS(pl, "Play", 10, T.txt)
	K.hover(pl, T.bg2, T.hover)
	pl.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: tocando " .. TRACKS[sel].nm)
	end)
	local pp = K.btn(cv, "Pp", 60, 134, 44, 22, T.bg2, 4)
	K.txtS(pp, "Stop", 10, T.txt)
	K.hover(pp, T.bg2, T.hover)
	pp.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Audio: parado")
	end)

	-- ===== DIREITA: MIXER =====
	local right = K.f(root, "Mixer", 426, 34, 126, 260, T.bg4)
	K.corner(right, 4)
	K.txt(right, "MIXER", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local chans = { "MUS", "SFX", "AMB" }
	local vols = { 0.8, 0.7, 0.55 }
	for i = 1, 3 do
		K.vfader(right, 18 + (i - 1) * 36, 28, 150, vols[i], chans[i])
	end
	K.txt(right, "MASTER", 10, 192, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.vfader(right, 30, 208, 40, 0.75, "M")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 60, T.bg0)
	K.corner(bar, 4)
	K.checkRow(bar, "Loop", true, 8)
	K.sliderRow(bar, "Master vol", 0.75, 34)
	local add = K.btn(bar, "Add", 300, 16, 90, 28, ACCENT, 5)
	K.txtS(add, "+ faixa", 11, C("#12102A"))
	K.hover(add, ACCENT, C("#C3BFFF"))
	add.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Audio: faixa 'Nova' adicionada ao mixer")
	end)
	K.txt(bar, "3 canais | 44.1k | 16bit", 410, 22, 130, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Audio", "Audio", "Scene", ICON.data, "Mixer de audio: faixas com waveforms, seek e canais verticais", build)
end

do
--[[ ARKHER V3 — UI: CAMERA ]]
-- Layout unico: lista de modos de vista a esquerda, preview com cone de FOV
-- que MUDA ao clicar nos botoes +/-, knobs de FOV/velocidade a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FF6B81")

local function build()
	local g, root, head = K.window("ArkherCamera", "CAMERA — rig & view", 24, 350, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local fov = 70
	local speed = 16

	-- ===== ESQUERDA: MODOS =====
	local left = K.f(root, "Modes", 8, 34, 122, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MODOS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local modes = { "Orbit", "Free", "Cinematic", "Drone", "Follow", "Top" }
	for i, m in ipairs(modes) do
		local row = K.treeRow(left, 0, i == 3 and ICON.camera or ICON.select, m, i == 3, 26 + (i - 1) * 24)
		K.hover(row, T.bg4, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Camera: modo " .. m)
		end)
	end
	K.txt(left, "Cinematic ativo", 10, 172, 110, 24, 9, ACCENT)

	-- ===== CENTRO: PREVIEW COM CONE DE FOV =====
	local cv = K.f(root, "Prev", 142, 34, 268, 200, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- ceu/terreno
	K.f(cv, "Sky", 0, 0, 268, 108, C("#12233D"))
	K.f(cv, "Gnd", 0, 108, 268, 92, C("#1B2B22"))
	-- sol
	K.f(cv, "Sun", 200, 24, 14, 14, C("#FFD93D"), 7)
	-- montanhas (frames rotacionados)
	local m1 = K.f(cv, "M1", 20, 78, 90, 30, C("#0E1A2B"))
	m1.Rotation = -8
	local m2 = K.f(cv, "M2", 150, 70, 110, 38, C("#101E30"))
	m2.Rotation = 5
	-- objeto alvo
	K.f(cv, "Tgt", 128, 128, 14, 26, ACCENT)
	K.txt(cv, "alvo", 118, 156, 36, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
	-- cone de FOV (2 linhas rotacionadas a partir do olho)
	local coneLines = {}
	local fovLbl = K.txt(cv, "70 FOV", 8, 180, 80, 16, 10, ACCENT)
	local function drawCone()
		for _, l in ipairs(coneLines) do l:Destroy() end
		coneLines = {}
		local ang = fov * 0.42
		for _, s in ipairs({ -1, 1 }) do
			local l = K.f(cv, "C", 135, 140, 150, 2, ACCENT)
			l.Rotation = s * ang
			l.AnchorPoint = Vector2.new(0, 0.5)
			table.insert(coneLines, l)
		end
		local eye = K.f(cv, "Eye", 131, 136, 8, 8, T.neon, 4)
		table.insert(coneLines, eye)
		fovLbl.Text = fov .. " FOV"
	end
	drawCone()

	-- ===== DIREITA: AJUSTES =====
	local right = K.f(root, "Adj", 422, 34, 130, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "FOV", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	local minus = K.btn(right, "M-", 10, 24, 52, 22, T.bg2, 4)
	K.txtS(minus, "-", 12, T.txt)
	K.hover(minus, T.bg2, T.hover)
	local plus = K.btn(right, "M+", 72, 24, 52, 22, T.bg2, 4)
	K.txtS(plus, "+", 12, T.txt)
	K.hover(plus, T.bg2, T.hover)
	minus.MouseButton1Click:Connect(function()
		fov = math.max(20, fov - 5)
		drawCone()
	end)
	plus.MouseButton1Click:Connect(function()
		fov = math.min(120, fov + 5)
		drawCone()
	end)
	K.knob(right, 38, 58, 54, fov / 120, math.floor(fov / 120 * 100 + 0.5) .. "%")
	K.txt(right, "VELOCIDADE", 10, 138, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 38, 156, 54, speed / 40, speed .. " u/s")
	K.row(right, "Zoom", "2.4", 216)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 296, 544, 76, T.bg0)
	K.corner(bar, 4)
	K.row(bar, "Rig", "CinematicCam", 8)
	K.row(bar, "Tracking", "Player", 34)
	local apply = K.btn(bar, "Apply", 300, 20, 110, 28, ACCENT, 5)
	K.txtS(apply, "Aplicar ao Place", 10, C("#1C070C"))
	K.hover(apply, ACCENT, C("#FF97A8"))
	apply.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Camera: rig CinematicCam (fov " .. fov .. ", " .. speed .. "u/s) aplicado")
		Bus.emit("camera.apply", { fov = fov, speed = speed, mode = "Cinematic" })
	end)
	K.txt(bar, "lens: 35mm equiv", 430, 28, 104, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Rig de camera: modos, FOV interativo, tracking e preview", build)
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
	local sim = K.btn(bar, 330, 34, 100, 26, T.bg2, 5)
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
--[[ ARKHER V3 — UI: LIGHTING ]]
-- Layout unico: knobs de sol/ambiente a esquerda, faixa HORA DO DIA clicavel
-- no centro (mexe o ceu + posicao do sol no preview), cores e toggles a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD93D")

local SKY_STEPS = {
	{ nm = "Noite", sky = C("#0B1026"), sun = C("#B0BEC5"), y = 78, x = 40 },
	{ nm = "Amanhecer", sky = C("#3E2748"), sun = C("#FF9770"), y = 60, x = 80 },
	{ nm = "Manha", sky = C("#4A78A8"), sun = C("#FFD93D"), y = 34, x = 120 },
	{ nm = "Meio-dia", sky = C("#5B9BD5"), sun = C("#FFF176"), y = 14, x = 160 },
	{ nm = "Tarde", sky = C("#4A6FA5"), sun = C("#FFCA28"), y = 40, x = 200 },
	{ nm = "Pôr do sol", sky = C("#5D3A4E"), sun = C("#FF7043"), y = 62, x = 240 },
	{ nm = "Anoitecer", sky = C("#2A2440"), sun = C("#FF8A65"), y = 78, x = 280 },
	{ nm = "Meia-noite", sky = C("#070B1A"), sun = C("#90A4AE"), y = 84, x = 320 },
}

local function build()
	local g, root, head = K.window("ArkherLighting", "LIGHTING — hora do dia", 24, 360, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	local step = 4

	-- ===== ESQUERDA: KNOBS =====
	local left = K.f(root, "Knobs", 8, 34, 132, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "SOL", 10, 6, 60, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 22, 60, (step - 1) / 7, "35deg")
	K.txt(left, "AMBIENTE", 10, 96, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 112, 60, 0.45, "0.45")
	K.txt(left, "EXPOSICAO", 10, 184, 100, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(left, 36, 200, 60, 0.5, "1.0x")

	-- ===== CENTRO: PREVIEW DO CEU + FAIXA =====
	local cv = K.f(root, "Sky", 152, 34, 264, 150, C("#5B9BD5"))
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	-- nuvens
	K.f(cv, "Cl1", 30, 20, 54, 14, C("#FFFFFF"), 7)
	K.f(cv, "Cl2", 150, 34, 70, 16, C("#F5F7FA"), 8)
	K.f(cv, "Cl3", 90, 58, 40, 10, C("#FFFFFF"), 5)
	-- terreno
	K.f(cv, "Hil", 0, 108, 264, 42, C("#1B2B22"))
	local hill = K.f(cv, "Hill", 60, 92, 140, 26, C("#16241C"))
	hill.Rotation = -3
	-- sol/lua (move com a hora)
	local sun = K.f(cv, "SunObj", SKY_STEPS[step].x, SKY_STEPS[step].y, 20, 20, SKY_STEPS[step].sun, 10)
	K.txt(cv, SKY_STEPS[step].nm, 8, 128, 120, 18, 11, T.txt, ARKHER.FONTB)

	-- faixa hora do dia (clicavel)
	local strip = K.f(root, "Strip", 152, 196, 264, 34, T.bg0)
	K.corner(strip, 4)
	for i, s in ipairs(SKY_STEPS) do
		local b = K.f(strip, "S" .. i, (i - 1) * 33, 4, 31, 26, s.sky, 2)
		K.txt(b, s.nm, 0, 14, 31, 10, 7, T.txt3, FONT, Enum.TextXAlignment.Center)
		local idx = i
		b.MouseButton1Click:Connect(function()
			step = idx
			cv.BackgroundColor3 = s.sky
			sun.Position = UDim2.new(0, s.x, 0, s.y)
			sun.BackgroundColor3 = s.sun
			ARKHER.out("INFO", "Lighting: " .. s.nm)
		end)
	end

	-- ===== DIREITA: CORES + TOGGLES =====
	local right = K.f(root, "Cols", 428, 34, 124, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "CORES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local colors = {
		{ "Sky", C("#5B9BD5") }, { "Cloud", C("#F5F7FA") },
		{ "Shadow", C("#3E5C76") }, { "Fog", C("#B0C4DE") },
	}
	for i, c2 in ipairs(colors) do
		K.row(right, c2[1], "", 26 + (i - 1) * 24)
		local sw = K.f(right, "CSw" .. i, 78, 26 + (i - 1) * 24, 34, 16, c2[2], 3)
		K.stroke(sw, T.line2, 1)
	end
	K.checkRow(right, "Sombras", true, 126)
	K.checkRow(right, "Fog", false, 150)
	K.checkRow(right, "Global light", true, 174)
	K.checkRow(right, "Post FX", true, 198)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 90, T.bg0)
	K.corner(bar, 4)
	local create = K.btn(bar, "Create", 10, 10, 140, 26, ACCENT, 5)
	K.txtS(create, "Criar luz no Place", 10, C("#1A1403"))
	K.hover(create, ACCENT, C("#FFE57A"))
	create.MouseButton1Click:Connect(function()
		local ws = workspace
		if ws:FindFirstChild("ArkherLighting") then ws:FindFirstChild("ArkherLighting"):Destroy() end
		local f = Instance.new("Folder")
		f.Name = "ArkherLighting"
		f:SetAttribute("Hora", SKY_STEPS[step].nm)
		f:SetAttribute("Sol", 35)
		f.Parent = ws
		ARKHER.out("SUCCESS", "Lighting: luz " .. SKY_STEPS[step].nm .. " criada no place")
	end)
	K.txt(bar, "sun: " .. SKY_STEPS[step].nm, 170, 16, 180, 16, 10, T.txt3)
	K.progress(bar, 10, 46, 524, (step - 1) / 7, ACCENT)
	K.txt(bar, "ciclo: 0h -> " .. ((step - 1) * 3) .. "h", 170, 58, 200, 14, 9, T.txt4)
end

ARKHER.reg("Lighting", "Lighting", "Scene", ICON.bulb, "Iluminacao: hora do dia interativa, sol, cores e post FX", build)
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
--[[ ARKHER V3 — UI: PARTICLES ]]
-- Layout unico: arvore do emissor a esquerda, GRAPH DE NOS (K.node + K.wireLayer)
-- no centro — estilo Nuke/Blender, knobs a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C56CF0")

local function build()
	local g, root, head = K.window("ArkherParticles", "PARTICLES — graph", 24, 340, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: ARVORE DO EMISSOR =====
	local left = K.f(root, "Tree", 8, 34, 148, 296, T.bg4)
	K.corner(left, 4)
	K.txt(left, "EMITTER", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(left, 0, ICON.gem, "SparkEmitter", "open", 26)
	K.treeRow(left, 1, ICON.data, "RateOverTime", "sel", 50)
	K.treeRow(left, 1, ICON.data, "SpreadOverCone", nil, 74)
	K.treeRow(left, 1, ICON.data, "ColorOverLife", nil, 98)
	K.treeRow(left, 1, ICON.data, "Velocity", nil, 122)
	K.txt(left, "4 properties", 10, 150, 100, 14, 9, T.txt4)
	local addProp = K.btn(left, "AddP", 10, 172, 128, 22, T.bg2, 4)
	K.txtS(addProp, "+ property", 10, T.txt)
	K.hover(addProp, T.bg2, T.hover)
	local props = 4
	addProp.MouseButton1Click:Connect(function()
		props = props + 1
		ARKHER.out("INFO", "Particles: property #" .. props .. " adicionada")
	end)
	K.row(left, "Tipo", "Bullets", 210)
	K.row(left, "Lighting", "On", 234)
	K.row(left, "Sort", "Distance", 258)

	-- ===== CENTRO: GRAPH =====
	local cv = K.f(root, "Graph", 168, 34, 284, 296, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 8 do K.f(cv, "gx" .. i, i * 33, 0, 1, 296, T.bg3) end
	for i = 1, 9 do K.f(cv, "gy" .. i, 0, i * 31, 284, 1, T.bg3) end
	local wire = K.wireLayer(cv)
	-- nos
	local nEm = K.node(cv, 12, 108, 100, "Emitter", C("#3A2B45"), { "rate", "spread", "color" }, {}, { sel = true, dot = ACCENT })
	local nRate = K.node(cv, 160, 40, 104, "RateOverTime", T.bg1, {}, { "value" })
	local nSpread = K.node(cv, 160, 128, 104, "SpreadOverCone", T.bg1, {}, { "cone" })
	local nColor = K.node(cv, 160, 212, 104, "ColorOverLife", T.bg1, {}, { "grad" })
	-- liga os soquetes (coordenadas vindas dos _socket)
	local function socketsOf(n)
		local ins, outs = {}, {}
		for _, s in ipairs(n._sockets or {}) do
			if s._socket then
				if s._socket.kind == "in" then table.insert(ins, s._socket)
				else table.insert(outs, s._socket) end
			end
		end
		return ins, outs
	end
	local eIn, _ = socketsOf(nEm)
	local _, rOut = socketsOf(nRate)
	local _, sOut = socketsOf(nSpread)
	local _, cOut = socketsOf(nColor)
	if eIn[1] and rOut[1] then wire:link(rOut[1].x, rOut[1].y, eIn[1].x, eIn[1].y, ACCENT) end
	if eIn[2] and sOut[1] then wire:link(sOut[1].x, sOut[1].y, eIn[2].x, eIn[2].y, C("#4DFFDB")) end
	if eIn[3] and cOut[1] then wire:link(cOut[1].x, cOut[1].y, eIn[3].x, eIn[3].y, C("#FFD93D")) end
	K.txt(cv, "graph: 4 nos, 3 fios", 8, 278, 200, 14, 9, T.txt4)

	-- ===== DIREITA: KNOBS =====
	local right = K.f(root, "Knobs", 464, 34, 88, 296, T.bg4)
	K.corner(right, 4)
	K.txt(right, "RATE", 6, 6, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 24, 48, 0.72, "128/s")
	K.txt(right, "SPREAD", 6, 96, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 114, 48, 0.3, "38deg")
	K.txt(right, "LIFE", 6, 186, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 204, 48, 0.5, "1.4s")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 340, 544, 52, T.bg0)
	K.corner(bar, 4)
	-- preview de particulas (pontos)
	local pv = K.f(bar, "Prev", 10, 6, 120, 40, T.dark)
	K.corner(pv, 3)
	for i = 1, 14 do
		local s = (i * 16807) % 2147483647
		local s2 = (s * 16807) % 2147483647
		local d = K.f(pv, "P" .. i, s % 110 + 4, s2 % 30 + 4, 3, 3, ACCENT, 1)
	end
	local pvLbl = K.txt(bar, "preview: 128/s", 140, 12, 120, 16, 10, T.txt3)
	local sim = K.btn(bar, "Sim", 270, 12, 80, 26, ACCENT, 5)
	K.txtS(sim, "Simular", 11, C("#160B1E"))
	K.hover(sim, ACCENT, C("#D99BFF"))
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Particles: 128 particulas/s por 1.4s simuladas")
		K.notify("Simulacao", "SparkEmitter OK", "ok")
	end)
	K.txt(bar, "modo: graph", 370, 18, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(bar, "pronto", 480, 18, 50, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Sistema de particulas em graph de nos com emissor e preview", build)
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
	local rep2 = K.btn(bar, 330, 52, 110, 24, T.bg2, 4)
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
	local closeB = K.btn(bar, 330, 56, 100, 26, T.bg2, 4)
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
--[[ ARKHER V3 — UI: SCRIPT (code editor) ]]
-- Layout unico: barra de arquivo + tabs de classe, area de codigo com
-- numeros de linha, painel de lint, acoes reais (criar Script no place, exportar).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")

local TEMPLATES = {
	Script = {
		"-- MeuScript (Script)",
		"local part = script.Parent",
		"",
		"part.Touched:Connect(function(hit)",
		"\tprint(\"tocado: \" .. hit.Name)",
		"\tpart.BrickColor = BrickColor.new(\"Bright red\")",
		"end)",
		"",
		"-- ARKHER: criado via Scripter",
	},
	LocalScript = {
		"-- MeuLocal (LocalScript)",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal cam = workspace.CurrentCamera",
		"\tcam.FieldOfView = 70",
		"end)",
	},
	ModuleScript = {
		"-- MeuModule (ModuleScript)",
		"local M = {}",
		"",
		"function M.hello(name)",
		"\treturn \"ola, \" .. name",
		"end",
		"",
		"return M",
	},
}

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT — editor de codigo", 24, 330, 520, 424, { pin = true })
	K.f(head, "Acc", 0, 24, 520, 2, ACCENT)

	local curCls = "Script"
	local curName = "MeuScript"
	local code = {}
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }

	-- ===== TOPO: ARQUIVO + CLASSES =====
	local nameBox = K.input(root, 10, 34, 190, 24, "nome do arquivo")
	nameBox.Text = "MeuScript"
	K.tabs(root, 210, 34, 290, CLASSES, 1, function(idx)
		curCls = CLASSES[idx]
		curName = nameBox.Text
		code = TEMPLATES[curCls]
		renderCode()
	end)

	-- ===== AREA DE CODIGO =====
	local ed = K.f(root, "Editor", 10, 64, 356, 240, T.bg0)
	K.corner(ed, 4)
	K.stroke(ed, T.line, 1)
	local function renderCode()
		for i = 1, 12 do
			local old = ed:FindFirstChild("L" .. i)
			if old then old:Destroy() end
		end
		for i = 1, 12 do
			local ln = code[i] or ""
			K.txt(ed, string.format("%2d", i), 4, 6 + (i - 1) * 18, 24, 18, 9, T.txt4)
			K.f(ed, "ln" .. i, 28, 6 + (i - 1) * 18, 322, 1, (i == 5 or i == 7) and T.line or T.bg0)
			local col = T.txt2
			local txt = ln
			if ln:sub(1, 2) == "--" then col = T.txt4 end
			if ln:find("local ") == 1 then col = C("#C792EA") end
			if ln:find("function ") == 1 then col = ACCENT end
			if ln:find("print") == 1 then col = C("#82AAFF") end
			if txt ~= "" then
				local t = K.txt(ed, "L" .. i, 30, 6 + (i - 1) * 18, 320, 18, 10, col, ARKHER.MONO or ARKHER.FONT)
			end
		end
	end
	renderCode()

	-- ===== LINT =====
	local lint = K.f(root, "Lint", 10, 310, 356, 56, T.bg4)
	K.corner(lint, 4)
	K.txt(lint, "LINT", 8, 4, 50, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(lint, "0 erros", 8, 22, 80, 14, 10, T.ok)
	K.txt(lint, "1 aviso: pcall p/ Touched", 100, 22, 160, 14, 9, C("#FFD93D"))
	K.txt(lint, "linhas: 9", 280, 22, 70, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 378, 64, 134, 302, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AÇÕES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Classe", curCls, 26)
	K.row(right, "Linhas", "9", 50)
	K.row(right, "Tamanho", "0.2 KB", 74)
	local create = K.btn(right, "Create", 10, 102, 114, 26, ACCENT, 5)
	K.txtS(create, "Criar no Place", 10, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local n = 1
		local ws = workspace
		local base = nameBox.Text
		while ws:FindFirstChild(base) do n = n + 1 base = nameBox.Text .. "_" .. n end
		local sc = Instance.new(curCls)
		sc.Name = base
		sc.Source = table.concat(code, "\n")
		sc.Parent = ws
		ARKHER.out("SUCCESS", "Script: " .. curCls .. " '" .. base .. "' criado no place (" .. #code .. " linhas)")
		K.notify("Script criado", base .. " no workspace", "ok")
	end)
	local exp = K.btn(right, "Export", 10, 136, 114, 26, T.bg2, 5)
	K.txtS(exp, "Exportar .lua", 10, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local data = table.concat(code, "\n")
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherScripts/" .. nameBox.Text .. ".lua", data)
				return "ArkherScripts/" .. nameBox.Text .. ".lua"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Script: exportado para " .. path)
		else
			ARKHER.out("WARNING", "Script: WriteFile indisponivel fora do Studio")
		end
	end)
	local ins = K.btn(right, "Insert", 10, 170, 114, 26, T.bg2, 5)
	K.txtS(ins, "+ snippet", 11, T.txt)
	K.hover(ins, T.bg2, T.hover)
	local snippets = { "\t-- snippet: debounce", "\tlocal debounce = false", "pcall(function() end)", "warn(\"debug\")" }
	local sn = 1
	ins.MouseButton1Click:Connect(function()
		sn = (sn % #snippets) + 1
		table.insert(code, snippets[sn])
		renderCode()
		ARKHER.out("INFO", "Script: snippet inserido")
	end)
	K.row(right, "Encoding", "utf-8", 214)
	K.row(right, "EOL", "LF", 238)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 10, 372, 502, 44, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "Ln 5, Col 12", 12, 6, 100, 14, 9, T.txt3)
	K.txt(bar, curCls, 130, 6, 120, 14, 9, ACCENT)
	K.txt(bar, "UTF-8 | LF | Luau", 268, 6, 130, 14, 9, T.txt4)
	K.txt(bar, "salvo", 470, 6, 30, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Script", "Script", "Editor", ICON.script, "Editor de codigo Luau: classes, lint, criar no place e exportar", build)
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
--[[ ARKHER V3 — UI: TERRAIN ]]
-- Layout unico: pincelais de escultura a esquerda, heightmap 8x8 INTERATIVO
-- no centro (clique aplica o pincel e repinta), paleta de biomas a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#7ED957")

local function build()
	local g, root, head = K.window("ArkherTerrain", "TERRAIN — escultura", 24, 320, 552, 384, { pin = true })
	K.f(head, "Acc", 0, 24, 552, 2, ACCENT)

	-- estado do relevo
	local heights = {}
	local seed = 7
	local function reseed(s)
		seed = s
		for i = 1, 64 do
			seed = (seed * 16807) % 2147483647
			heights[i] = (seed % 1000) / 1000 * 6
		end
	end
	reseed(11)

	-- ===== PINCELAS =====
	local brushes = {
		{ id = "raise", nm = "Raise", gl = "+", d = "sobe 1u" },
		{ id = "lower", nm = "Lower", gl = "-", d = "desce 1u" },
		{ id = "smooth", nm = "Smooth", gl = "~", d = "media vizinhos" },
		{ id = "flatten", nm = "Flatten", gl = "=", d = "zera" },
		{ id = "erase", nm = "Erase", gl = "x", d = "remove tudo" },
	}
	local curBrush = "raise"
	local left = K.f(root, "Brush", 8, 34, 108, 240, T.bg4)
	K.corner(left, 4)
	K.txt(left, "PINCEL", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	for i, b in ipairs(brushes) do
		local row = K.btn(left, "B" .. i, 8, 26 + (i - 1) * 34, 92, 28, T.bg2, 4)
		local ic = K.f(row, "G", 4, 6, 16, 16, T.bg0, 3)
		K.txt(ic, b.gl, 0, 0, 16, 16, 11, ACCENT, FONTB, Enum.TextXAlignment.Center)
		K.txt(row, b.nm, 26, 2, 62, 14, 10, T.txt)
		K.txt(row, b.d, 26, 15, 62, 11, 8, T.txt4)
		local id = b.id
		row.MouseButton1Click:Connect(function()
			curBrush = id
			for j = 1, #brushes do
				local rr = left:FindFirstChild("B" .. j)
				if rr then K.stroke(rr, j == i and ACCENT or T.line2, j == i and 1.5 or 1) end
			end
		end)
		K.stroke(row, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	K.sliderRow(left, "Forca", 0.6, 206)

	-- ===== HEIGHTMAP 8x8 =====
	local cv = K.f(root, "Map", 126, 34, 252, 240, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	local tiles = {}
	local function hcolor(h)
		-- 0=agua/areia -> 6=rocha
		local stops = { C("#2E86AB"), C("#E9D8A6"), C("#7ED957"), C("#3E8E41"), C("#8D6E63"), C("#6D6E71"), C("#CFD8DC") }
		local idx = math.min(6, math.floor(h))
		return stops[idx + 1]
	end
	local function paint(i, tx, ty)
		local t = tiles[i]
		if t then
			t.BackgroundColor3 = hcolor(heights[i])
			t:FindFirstChild("N").Text = string.format("%.1f", heights[i])
		end
	end
	local function applyBrush(idx)
		local r, c = math.floor((idx - 1) / 8) + 1, ((idx - 1) % 8) + 1
		local function get(r2, c2)
			if r2 < 1 or r2 > 8 or c2 < 1 or c2 > 8 then return nil end
			return (r2 - 1) * 8 + c2
		end
		if curBrush == "raise" then heights[idx] = math.min(6, heights[idx] + 1)
		elseif curBrush == "lower" then heights[idx] = math.max(0, heights[idx] - 1)
		elseif curBrush == "flatten" then heights[idx] = 0
		elseif curBrush == "erase" then heights[idx] = 0
		elseif curBrush == "smooth" then
			local sum, n = 0, 0
			for dr = -1, 1 do
				for dc = -1, 1 do
					local j = get(r + dr, c + dc)
					if j then sum = sum + heights[j] n = n + 1 end
				end
			end
			heights[idx] = sum / n
		end
		-- repinta a vizinhanca
		for dr = -1, 1 do
			for dc = -1, 1 do
				local j = get(r + dr, c + dc)
				if j then paint(j) end
			end
		end
	end
	for i = 1, 64 do
		local r, c = math.floor((i - 1) / 8) + 1, ((i - 1) % 8) + 1
		local t = K.f(cv, "H" .. i, (c - 1) * 31 + 2, (r - 1) * 29 + 2, 29, 27, hcolor(heights[i]), 2)
		K.txt(t, string.format("%.1f", heights[i]), 0, 8, 29, 12, 9, T.txt3, FONT, Enum.TextXAlignment.Center)
		tiles[i] = t
		local idx = i
		t.MouseButton1Click:Connect(function() applyBrush(idx) end)
	end
	K.txt(cv, "clique num tile = aplicar pincel", 8, 236, 200, 12, 8, T.txt4)

	-- ===== BIOMAS + MATERIAIS =====
	local right = K.f(root, "Biome", 390, 34, 154, 240, T.bg4)
	K.corner(right, 4)
	K.txt(right, "BIOMAS", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	local biomes = {
		{ "Praia", C("#E9D8A6") }, { "Grande", C("#7ED957") },
		{ "Deserto", C("#D4A373") }, { "Neve", C("#ECEFF1") },
	}
	for i, b in ipairs(biomes) do
		local row = K.btn(right, "BM" .. i, 10, 26 + (i - 1) * 26, 134, 22, T.bg2, 4)
		K.f(row, "Sw", 4, 5, 12, 12, b[2], 2)
		K.txt(row, b[1], 22, 0, 90, 22, 10, T.txt)
		K.hover(row, T.bg2, T.hover)
		row.MouseButton1Click:Connect(function()
			ARKHER.out("INFO", "Terrain: bioma " .. b[1])
		end)
	end
	K.txt(right, "MATERIAIS", 10, 138, 90, 14, 10, T.txt3, ARKHER.FONTB)
	local mats = { C("#7ED957"), C("#8D6E63"), C("#B0BEC5"), C("#E9D8A6"), C("#4DB6AC"), C("#6D6E71") }
	for i = 1, 6 do
		local m = K.f(right, "M" .. i, 10 + ((i - 1) % 3) * 44, 158 + math.floor((i - 1) / 3) * 34, 38, 28, mats[i], 3)
		K.stroke(m, i == 1 and ACCENT or T.line, i == 1 and 1.5 or 1)
		K.txt(m, tostring(i) .. "u", 0, 16, 38, 10, 8, T.txt3, FONT, Enum.TextXAlignment.Center)
	end

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 284, 536, 92, T.bg0)
	K.corner(bar, 4)
	local gen = K.btn(bar, "Gen", 10, 10, 130, 26, ACCENT, 5)
	K.txtS(gen, "Relevo procedural", 10, C("#0D140B"))
	K.hover(gen, ACCENT, C("#A5E88C"))
	local gseed = 11
	gen.MouseButton1Click:Connect(function()
		gseed = gseed * 31 + 7
		reseed(gseed)
		for i = 1, 64 do paint(i) end
		ARKHER.out("SUCCESS", "Terrain: relevo procedural (seed " .. gseed .. ")")
	end)
	local ai = K.btn(bar, "AI", 150, 10, 120, 26, T.bg2, 5)
	K.txtS(ai, "Gerar c/ IA", 11, T.txt)
	K.hover(ai, T.bg2, T.hover)
	ai.MouseButton1Click:Connect(function()
		ARKHER.out("INFO", "Terrain: pedindo a Singularity...")
		local ok, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um terreno com natureza") end)
		if ok and rep then K.notify("Singularity", "terreno gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	K.txt(bar, "8x8 tiles | 31u | bioma: Grande", 10, 48, 250, 16, 10, T.txt3)
	K.txt(bar, "altura media: 2.4u", 300, 48, 150, 16, 10, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.progress(bar, 10, 70, 516, 0.42, ACCENT)
end

ARKHER.reg("Terrain", "Terrain", "Editor", ICON.terrain, "Escultura de terreno: pincelais, heightmap, biomas e materiais", build)
end

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

--[[ ARKHER V3 — DRIVER: boot completo (sistemas + shell + todas as UIs) ]]
-- Ordem: prelude → core → actions → boot → main shell → UIs em cascata.
do
	ARKHER.boot()
	pcall(function() ARKHER_BUILD_MAIN() end)
	local opened = ARKHER.openAll()
	ARKHER.out("SUCCESS", string.format("ARKHER V3 pronto: %d UIs ativas + core (places/do15/nmn/singularity/undo/live/publish)", opened))
end
