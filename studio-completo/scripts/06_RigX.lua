-- Arkher_06_RigX — parte NOVA: editor de esqueleto/animacao (Cascadeur++)
-- Acopla ao dock do 05_StudioX SEM alterar nada dele. Icones desenhados.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = {
	panel = Color3.fromRGB(7, 16, 32), sect = Color3.fromRGB(9, 23, 44),
	border = Color3.fromRGB(52, 80, 120), text = Color3.fromRGB(228, 240, 255),
	muted = Color3.fromRGB(146, 170, 202), blue = Color3.fromRGB(35, 139, 230),
	sel = Color3.fromRGB(17, 76, 139), cyan = Color3.fromRGB(43, 203, 243),
	gold = Color3.fromRGB(240, 185, 70), err = Color3.fromRGB(255, 164, 143),
	ok = Color3.fromRGB(120, 220, 160), font = Enum.Font.GothamBold, fontm = Enum.Font.Gotham,
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
local function ac(parent, cx, cy, r, col)
	local f = B("Frame", { Size = UDim2.fromOffset(r * 2, r * 2), Position = UDim2.fromOffset(cx - r, cy - r), BackgroundTransparency = 1 }, parent)
	local s0 = Instance.new("UIStroke")
	s0.Thickness = 2; s0.Color = col; s0.Parent = f
	H(f, r)
	return f
end

-- icone: boneco de palitos com osso de ouro (rig)
local function drawRigIcon(canvas, col)
	col = col or t.cyan
	ac(canvas, 14, 7, 3, t.gold)          -- cabeca
	al(canvas, 14, 10, 14, 16, col)       -- coluna
	al(canvas, 14, 12, 7, 15, col)        -- braco esq
	al(canvas, 14, 12, 21, 15, col)       -- braco dir
	al(canvas, 14, 16, 9, 23, col)        -- perna esq
	al(canvas, 14, 16, 19, 23, col)       -- perna dir
	ac(canvas, 21, 15, 2, col)            -- mao (efeito FABRIK)
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

-- acoplamento ao Robox dock criado pelo 05 (additive, sem altera-lo)
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local guiX = pg:WaitForChild("ArkherStudioX", 30)
if not guiX then
	guiX = B("ScreenGui", { Name = "ArkherStudioX", ResetOnSpawn = false, DisplayOrder = 60 }, pg)
end
local dock = guiX:WaitForChild("DockX", 20)

local win = B("Frame", {
	Name = "Px_rig", Size = UDim2.fromOffset(340, 300),
	Position = UDim2.new(0.5, -170, 0.5, -150),
	BackgroundColor3 = t.panel, BorderSizePixel = 0, Visible = false,
}, guiX)
H(win, 12); stroke(win, 1)
local cap = B("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = t.sect, BorderSizePixel = 0 }, win)
H(cap, 12)
local ic = B("Frame", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(5, 4), BackgroundTransparency = 1 }, cap)
drawRigIcon(ic, t.cyan)
B("TextLabel", {
	Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(36, 0), BackgroundTransparency = 1,
	Text = "RIG X — Cascadeur++ (FABRIK+fisica)", Font = t.font, TextSize = 13,
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
	Text = "Alem do Cascadeur: IK ao vivo COM fisica do jogo",
	Font = t.fontm, TextSize = 11, TextColor3 = t.muted, TextXAlignment = Enum.TextXAlignment.Left,
}, body)

mkBtn("Cadeia FABRIK demo (4 ossos + pole)", 24, function() return remote("rig_demo", {}) end)
mkBtn("Relatorio de equilibrio (COM → suporte)", 58, function() return remote("rig_balance", {}) end)
mkBtn("PARAR rig", 92, function() return remote("rig_stop", {}) end)

if dock then
	local b0 = B("TextButton", {
		Size = UDim2.fromOffset(30, 30), BackgroundColor3 = t.sect, Text = "", AutoButtonColor = true,
	}, dock)
	H(b0, 8); stroke(b0, 1, t.border)
	local ic2 = B("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(1, 1), BackgroundTransparency = 1 }, b0)
	drawRigIcon(ic2, t.cyan)
	b0.MouseEnter:Connect(function() b0.BackgroundColor3 = t.sel end)
	b0.MouseLeave:Connect(function() b0.BackgroundColor3 = t.sect end)
	b0.MouseButton1Click:Connect(function()
		for _, w in ipairs(guiX:GetChildren()) do
			if w:IsA("Frame") and string.sub(w.Name, 1, 3) == "Px_" then w.Visible = false end
		end
		win.Visible = true
	end)
end

print("[ArkherX] 06_RigX pronto (Cascadeur++ FABRIK+balance real)")
