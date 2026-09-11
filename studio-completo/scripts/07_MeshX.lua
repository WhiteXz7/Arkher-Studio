-- Arkher_07_MeshX — parte NOVA: modelador procedural (Blender++ in-game)
-- Acopla ao dock do 05_StudioX SEM alterar nada. Icone = cubo em wireframe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = {
	panel = Color3.fromRGB(7, 16, 32), sect = Color3.fromRGB(9, 23, 44),
	border = Color3.fromRGB(52, 80, 120), text = Color3.fromRGB(228, 240, 255),
	muted = Color3.fromRGB(146, 170, 202), blue = Color3.fromRGB(35, 139, 230),
	sel = Color3.fromRGB(17, 76, 139), cyan = Color3.fromRGB(43, 203, 243),
	gold = Color3.fromRGB(240, 185, 70), err = Color3.fromRGB(255, 164, 143),
	ok = Color3.fromRGB(120, 220, 160), purple = Color3.fromRGB(166, 117, 240),
	font = Enum.Font.GothamBold, fontm = Enum.Font.Gotham,
}

local function B(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function H(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return o
end
local function stroke(o, th, col)
	local s0 = Instance.new("UIStroke")
	s0.Thickness = th; s0.Color = col or t.border; s0.Parent = o
	return o
end
local function al(parent, x1, y1, x2, y2, col, w)
	local dx, dy = x2 - x1, y2 - y1
	local len = math.sqrt(dx * dx + dy * dy)
	local f = B("Frame", {
		Size = UDim2.fromOffset(len, w or 2),
		Position = UDim2.fromOffset((x1 + x2) / 2 - len / 2, (y1 + y2) / 2 - (w or 2) / 2),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = col, BorderSizePixel = 0,
	}, parent)
	H(f, w or 2)
	return f
end

-- icone: cubo em wireframe isometrico (2 quadrados + ligacoes)
local function drawMeshIcon(canvas, col)
	col = col or t.cyan
	-- face de tras
	al(canvas, 8, 5, 20, 5, col)   al(canvas, 20, 5, 20, 17, col)
	al(canvas, 20, 17, 8, 17, col) al(canvas, 8, 17, 8, 5, col)
	-- face da frente
	al(canvas, 4, 9, 16, 9, t.gold)   al(canvas, 16, 9, 16, 21, t.gold)
	al(canvas, 16, 21, 4, 21, t.gold) al(canvas, 4, 21, 4, 9, t.gold)
	-- ligacoes
	al(canvas, 4, 9, 8, 5, col)  al(canvas, 16, 9, 20, 5, col)
	al(canvas, 16, 21, 20, 17, col) al(canvas, 4, 21, 8, 17, col)
end

local netFn
pcall(function()
	local net = ReplicatedStorage:WaitForChild("ArkherNet", 20)
	if net then netFn = net:WaitForChild("ArkherXQ", 5) end
end)
local function remote(op, params)
	if not netFn then error("sem ponte ArkherNet") end
	local res = netFn:InvokeServer({ op = op, params = params })
	if type(res) == "table" then return res.msg or res end
	return res
end

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local guiX = pg:WaitForChild("ArkherStudioX", 30)
if not guiX then
	guiX = B("ScreenGui", { Name = "ArkherStudioX", ResetOnSpawn = false, DisplayOrder = 60 }, pg)
end
local dock = guiX:WaitForChild("DockX", 20)

local win = B("Frame", {
	Name = "Px_mesh", Size = UDim2.fromOffset(340, 380),
	Position = UDim2.new(0.5, -170, 0.5, -190),
	BackgroundColor3 = t.panel, BorderSizePixel = 0, Visible = false,
}, guiX)
H(win, 12); stroke(win, 1)
local cap = B("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = t.sect, BorderSizePixel = 0 }, win)
H(cap, 12)
local ic = B("Frame", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(5, 4), BackgroundTransparency = 1 }, cap)
drawMeshIcon(ic, t.cyan)
B("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1,
	Text = "MESH X — Blender++ procedural", Font = t.font, TextSize = 13,
	TextColor3 = t.text, TextXAlignment = Enum.TextXAlignment.Left,
}, cap)
local close = B("TextButton", {
	Size = UDim2.fromOffset(26, 22), Position = UDim2.new(1, -30, 0, 5), BackgroundColor3 = t.panel,
	Text = "×", Font = t.font, TextSize = 15, TextColor3 = t.muted, AutoButtonColor = true,
}, cap)
H(close, 7)
close.MouseButton1Click:Connect(function() win.Visible = false end)

local body = B("Frame", { Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 38), BackgroundTransparency = 1 }, win)
local status = B("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, -34), BackgroundColor3 = t.sect,
	Text = "aguardando…", Font = t.fontm, TextSize = 11, TextColor3 = t.muted, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
}, win)
H(status, 8)
local spad = Instance.new("UIPadding")
spad.PaddingLeft = UDim.new(0, 8); spad.PaddingRight = UDim.new(0, 8); spad.Parent = status

local function mkBtn(label, y, fn)
	local b0 = B("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, y), BackgroundColor3 = t.sel,
		Text = label, Font = t.font, TextSize = 12, TextColor3 = t.text, AutoButtonColor = true,
	}, body)
	H(b0, 8); stroke(b0, 1)
	local busy = false
	b0.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		status.Text = "→ " .. label .. "…"; status.TextColor3 = t.cyan
		task.spawn(function()
			local ok, res = pcall(fn)
			if ok then status.Text = "✓ " .. tostring(res); status.TextColor3 = t.ok
			else status.Text = "✗ " .. tostring(res); status.TextColor3 = t.err end
			busy = false
		end)
	end)
end

B("TextLabel", {
	Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
	Text = "Boolean convexo REAL — sem CSG service",
	Font = t.fontm, TextSize = 11, TextColor3 = t.muted, TextXAlignment = Enum.TextXAlignment.Left,
}, body)

mkBtn("CASA (janelas/porta = subtract real)", 24, function() return remote("mesh_house", {}) end)
mkBtn("ENGRENAGEM (dentada por extrudes)", 58, function() return remote("mesh_gear", {}) end)
mkBtn("CRISTAL (icosa + subdivide)", 92, function() return remote("mesh_crystal", {}) end)
mkBtn("MESA procedural (displace + smooth)", 126, function() return remote("mesh_mesa", { seed = 7 }) end)
mkBtn("LIMPAR ultimo mesh", 170, function() return remote("mesh_clean", {}) end)

if dock then
	local b0 = B("TextButton", {
		Size = UDim2.fromOffset(30, 30), BackgroundColor3 = t.sect, Text = "", AutoButtonColor = true,
	}, dock)
	H(b0, 8); stroke(b0, 1, t.border)
	local ic2 = B("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(1, 1), BackgroundTransparency = 1 }, b0)
	drawMeshIcon(ic2, t.cyan)
	b0.MouseEnter:Connect(function() b0.BackgroundColor3 = t.sel end)
	b0.MouseLeave:Connect(function() b0.BackgroundColor3 = t.sect end)
	b0.MouseButton1Click:Connect(function()
		for _, w in ipairs(guiX:GetChildren()) do
			if w:IsA("Frame") and string.sub(w.Name, 1, 3) == "Px_" then w.Visible = false end
		end
		win.Visible = true
	end)
end

print("[ArkherX] 07_MeshX pronto (Blender++ boolean/extrude/bevel real)")
