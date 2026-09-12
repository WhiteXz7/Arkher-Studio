--[[ ARKHER V3 — Installer ArkherKit_A: cria o ModuleScript em ReplicatedStorage.ArkherV3 ]]
local KIT = [====[--[[ ARKHER V3 — KIT A (ModuleScript) — prelude + do15 + undo + publish + nmn ]]
-- Instala em: ReplicatedStorage.ArkherV3.ArkherKit_A

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

]====]
local rs = game:GetService("ReplicatedStorage")
local holder = rs:FindFirstChild("ArkherV3")
if not holder then
	holder = Instance.new("Folder")
	holder.Name = "ArkherV3"
	holder.Parent = rs
end
local mod = holder:FindFirstChild("ArkherKit_A")
if not mod then
	mod = Instance.new("ModuleScript")
	mod.Name = "ArkherKit_A"
	mod.Parent = holder
end
mod.Source = KIT
print("[ARKHER V3] ArkherKit_A instalado em ReplicatedStorage.ArkherV3")
