-- =============================================================
-- Arkher_05_StudioX — PARTE NOVA da GUI ARKHER (LocalScript)
-- Convive com partes 01..04 SEM alterar nada delas.
-- Estilo 100% do tema original (panel 07/16/32, blue 35/139/230...)
-- e icones DESENHADOS em Frames (linhas/retangulos) — sem imagens.
-- Fala com o mundo REAL via ReplicatedStorage/ArkherNet (a ponte;
-- motores vivem seguros em ServerStorage/ArkherEngines).
-- =============================================================

local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local t = {
	panel = Color3.fromRGB(7, 16, 32),
	sect = Color3.fromRGB(9, 23, 44),
	border = Color3.fromRGB(52, 80, 120),
	text = Color3.fromRGB(228, 240, 255),
	muted = Color3.fromRGB(146, 170, 202),
	blue = Color3.fromRGB(35, 139, 230),
	sel = Color3.fromRGB(17, 76, 139),
	cyan = Color3.fromRGB(43, 203, 243),
	purple = Color3.fromRGB(166, 117, 240),
	gold = Color3.fromRGB(240, 185, 70),
	err = Color3.fromRGB(255, 164, 143),
	ok = Color3.fromRGB(120, 220, 160),
	font = Enum.Font.GothamBold,
	fontm = Enum.Font.Gotham,
}

-- helpers (mesma familia funcional do nucleo original)
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
	s0.Thickness = th
	s0.Transparency = 0
	s0.Color = col or t.border
	s0.Parent = o
	return o
end

-- ============ icones DESENHADOS (meus) ============
-- al: linha fina entre dois pontos; ah: bloco retangular; ac: anel
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

local function ah(parent, x, y, w, h, col)
	local f = B("Frame", {
		Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = col, BorderSizePixel = 0,
	}, parent)
	H(f, math.min(4, math.floor(math.min(w, h) / 3)))
	return f
end

local function ac(parent, cx, cy, r, col)
	local f = B("Frame", {
		Size = UDim2.fromOffset(r * 2, r * 2),
		Position = UDim2.fromOffset(cx - r, cy - r),
		BackgroundTransparency = 1,
	}, parent)
	local s0 = Instance.new("UIStroke")
	s0.Thickness = 2
	s0.Color = col
	s0.Parent = f
	H(f, r)
	return f
end

-- desenha o icone do editor num quadrado 28x28
local function drawIcon(canvas, id, col)
	col = col or t.cyan
	if id == "terrain" then
		al(canvas, 2, 24, 10, 10, col)
		al(canvas, 10, 10, 15, 17, col)
		al(canvas, 15, 17, 19, 8, col)
		al(canvas, 19, 8, 26, 24, col)
		ah(canvas, 2, 24, 24, 2, col)
	elseif id == "water" then
		al(canvas, 3, 10, 8, 7, col, 2)
		al(canvas, 8, 7, 14, 10, col, 2)
		al(canvas, 14, 10, 20, 7, col, 2)
		al(canvas, 20, 7, 25, 10, col, 2)
		al(canvas, 3, 17, 8, 14, col, 2)
		al(canvas, 8, 14, 14, 17, col, 2)
		al(canvas, 14, 17, 20, 14, col, 2)
		al(canvas, 20, 14, 25, 17, col, 2)
	elseif id == "scene" then
		al(canvas, 7, 6, 7, 15, col)
		al(canvas, 7, 6, 12, 11, col)
		al(canvas, 7, 6, 2, 11, col)
		ah(canvas, 6, 15, 3, 5, col)
		al(canvas, 18, 10, 18, 18, col)
		al(canvas, 18, 10, 23, 14, col)
		al(canvas, 18, 10, 14, 14, col)
		ah(canvas, 17, 18, 3, 5, col)
	elseif id == "atmos" then
		ac(canvas, 11, 11, 5, col)
		al(canvas, 11, 2, 11, 4, col, 2)
		al(canvas, 11, 18, 11, 20, col, 2)
		al(canvas, 2, 11, 4, 11, col, 2)
		al(canvas, 19, 11, 21, 11, col, 2)
		al(canvas, 18, 18, 26, 18, t.muted, 3)
		al(canvas, 16, 23, 27, 23, t.muted, 3)
	elseif id == "rope" then
		al(canvas, 3, 8, 8, 13, col)
		al(canvas, 8, 13, 13, 9, col)
		al(canvas, 13, 9, 18, 16, col)
		al(canvas, 18, 16, 24, 19, col)
		ac(canvas, 24, 19, 3, t.gold)
	elseif id == "px" then
		ac(canvas, 9, 14, 2, col)
		ac(canvas, 14, 8, 2, col)
		ac(canvas, 19, 14, 2, col)
		ac(canvas, 14, 20, 2, t.gold)
		al(canvas, 14, 8, 12, 4, col, 1)
		al(canvas, 14, 8, 17, 5, col, 1)
	elseif id == "anim" then
		al(canvas, 3, 22, 3, 4, t.muted, 2)
		al(canvas, 3, 22, 25, 22, t.muted, 2)
		al(canvas, 4, 22, 9, 10, col)
		al(canvas, 9, 10, 14, 20, col)
		al(canvas, 14, 20, 19, 6, col)
		al(canvas, 19, 6, 24, 12, col)
	elseif id == "stats" then
		ah(canvas, 4, 14, 4, 8, col)
		ah(canvas, 11, 9, 4, 13, col)
		ah(canvas, 18, 5, 4, 17, col)
		ah(canvas, 3, 23, 20, 2, t.muted)
	elseif id == "audio" then
		ah(canvas, 5, 12, 3, 7, col)
		ah(canvas, 10, 8, 3, 11, col)
		ah(canvas, 15, 4, 3, 15, col)
		ah(canvas, 20, 10, 3, 9, col)
	end
end

-- ============ aguarda o bus do cliente original (sem mexer nele) ============
local function claimBusPart(name)
	local bus = StarterGui:FindFirstChild("ArkherServerClientRuntime")
	bus = bus or (StarterGui:FindFirstChild("ArkherStudioUI") and StarterGui.ArkherStudioUI:WaitForChild("ArkherServerClientRuntime", 10))
	if bus and bus:IsA("BindableFunction") and bus.ClaimPart then
		pcall(function() bus:ClaimPart(name) end)
	end
end

pcall(claimBusPart, "05_StudioX")

-- ============ UI raiz (dock + dock panels) ============
local gui = B("ScreenGui", {
	Name = "ArkherStudioX", ResetOnSpawn = false,
	DisplayOrder = 60, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, Players.LocalPlayer:WaitForChild("PlayerGui"))

-- barra lateral RETIRADA por diretriz: toda a navegacao vai pra TOPBAR (abas).
-- `dock` fica nil; partes 06/07 verificam antes de acoplar.
local dock = nil

local row = B("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, dock)
local tl = B("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
	Text = "X", Font = t.font, TextSize = 15, TextColor3 = t.cyan,
}, row)

-- ============ painel generico ============
local panels = {}

local function makePanel(id, title, build)
	local win = B("Frame", {
		Name = "Px_" .. id, Size = UDim2.fromOffset(340, 330),
		Position = UDim2.new(0.5, -170, 0.5, -165),
		BackgroundColor3 = t.panel, BorderSizePixel = 0, Visible = false,
	}, gui)
	H(win, 12)
	stroke(win, 1)
	local cap = B("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = t.sect, BorderSizePixel = 0 }, win)
	H(cap, 12)
	local ic = B("Frame", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(5, 4), BackgroundTransparency = 1 }, cap)
	drawIcon(ic, id, t.cyan)
	B("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(36, 0),
		BackgroundTransparency = 1, Text = title, Font = t.font, TextSize = 13,
		TextColor3 = t.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, cap)
	local close = B("TextButton", {
		Size = UDim2.fromOffset(26, 22), Position = UDim2.new(1, -30, 0, 5),
		BackgroundColor3 = t.panel, Text = "×", Font = t.font, TextSize = 15,
		TextColor3 = t.muted, BorderSizePixel = 0, AutoButtonColor = true,
	}, cap)
	H(close, 7)
	close.MouseButton1Click:Connect(function() win.Visible = false end)

	local body = B("Frame", {
		Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 38),
		BackgroundTransparency = 1,
	}, win)
	local status = B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, -34),
		BackgroundColor3 = t.sect, BorderSizePixel = 0, Text = "aguardando…",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	}, win)
	H(status, 8)
	local spad = Instance.new("UIPadding")
	spad.PaddingLeft = UDim.new(0, 8)
	spad.PaddingRight = UDim.new(0, 8)
	spad.Parent = status

	local ctx = { root = body, status = status }
	build(ctx)
	panels[id] = win
	return win
end

local function mkBtn(ctx, label, y, fn)
	local b0 = B("TextButton", {
		Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, y),
		BackgroundColor3 = t.sel, Text = label, Font = t.font, TextSize = 12,
		TextColor3 = t.text, BorderSizePixel = 0, AutoButtonColor = true,
	}, ctx.root)
	H(b0, 8)
	stroke(b0, 1)
	local busy = false
	b0.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		ctx.status.Text = "→ " .. label .. "…"
		ctx.status.TextColor3 = t.cyan
		task.spawn(function()
			local ok, res = pcall(fn)
			if ok then
				ctx.status.Text = "✓ " .. tostring(res or "pronto")
				ctx.status.TextColor3 = t.ok
			else
				ctx.status.Text = "✗ " .. tostring(res)
				ctx.status.TextColor3 = t.err
			end
			busy = false
		end)
	end)
	return b0
end

-- ===== remoto (a UNICA coisa no ReplicatedStorage) =====
local netEv, netFn
pcall(function()
	local net = ReplicatedStorage:WaitForChild("ArkherNet", 20)
	if net then
		netEv, netFn = net:WaitForChild("ArkherXCmd", 5), net:WaitForChild("ArkherXQ", 5)
	end
end)
if not netFn then
	local warnl = B("TextLabel", {
		Size = UDim2.fromOffset(320, 20), Position = UDim2.new(0.5, -160, 0, 4),
		BackgroundTransparency = 1, Text = "ArkherNet ausente — rode o servidor ARKHER",
		Font = t.fontm, TextSize = 11, TextColor3 = t.err,
	}, gui)
	task.delay(6, function() warnl:Destroy() end)
end

local function remote(op, params)
	if not netFn then error("sem ponte ArkherNet") end
	local res = netFn:InvokeServer({ op = op, params = params })
	if type(res) == "table" then return res.msg or res end
	return res
end

-- ====================== os 8 editores ======================
makePanel("terrain", "TERRAIN X — mundo do zero", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Oceano/cont. por seed + presets de TeseDosD",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Gerar mundo (preset continentes)", 24, function() return remote("terrain_generate", { seed = 7, preset = "continentes" }) end)
	mkBtn(ctx, "Gerar mundo (preset ilhas)", 58, function() return remote("terrain_generate", { seed = 41, preset = "ilhas" }) end)
	mkBtn(ctx, "Materializar (parts reais + ShoreBlend)", 104, function() return remote("terrain_materialize", {}) end)
	mkBtn(ctx, "Erosao hidraulica (static flow 120 gotas)", 138, function() return remote("terrain_erode", { cycles = 120 }) end)
end)

makePanel("water", "WATER X — oceanos/fisica", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Empuxo de Arquimedes + boat 4 pontos + ripples",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Oceano 'porto' (nivel 10)", 24, function() return remote("water_ocean", { sea = "porto" }) end)
	mkBtn(ctx, "Oceano 'tempestade' (swell 3.2)", 58, function() return remote("water_ocean", { sea = "tempestade" }) end)
	mkBtn(ctx, "Barco fisico no oceano", 104, function() return remote("water_boat", {}) end)
end)

makePanel("scene", "SCENE X — floresta/patina", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Whittaker real: biomas por clima do ATX",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Floresta ASXN (60 arvores densas)", 24, function() return remote("scatter_forest", { radius = 90, count = 60 }) end)
	mkBtn(ctx, "Bosque ASXN (30, mais aberto)", 58, function() return remote("scatter_forest", { radius = 120, count = 30 }) end)
	mkBtn(ctx, "Patina anti-CG nas parts", 104, function() return remote("patina", {}) end)
end)

makePanel("atmos", "ATMOS X — ceu/clima", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Weather machine real + Maui Kelvin",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Preset entardecer (Kelvin 1935 real)", 24, function() return remote("atmos_preset", { preset = "entardecer" }) end)
	mkBtn(ctx, "Preset meio-dia (5522K)", 58, function() return remote("atmos_preset", { preset = "meiodia" }) end)
	mkBtn(ctx, "Clima: CHUVA (maquina de estados)", 104, function() return remote("atmos_weather", { state = "chuva" }) end)
	mkBtn(ctx, "Clima: TEMPESTADE (raios + AWX)", 138, function() return remote("atmos_weather", { state = "tempestade" }) end)
end)

makePanel("rope", "ROPE X — Verlet no mundo", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Na brecha do Roblox: corda real sem Verlet nativo",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Corda + bandeira Verlet (world)", 24, function() return remote("rope_demo", {}) end)
	mkBtn(ctx, "Estregar burst de velocidade", 58, function() return remote("px_emit", { kind = "fumaca" }) end)
end)

makePanel("px", "PARTICLES X — VFX real", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "D-O15: normal/luau/premium/doze",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Emissor FOGO (billboard+attr)", 24, function() return remote("px_emit", { kind = "fogo" }) end)
	mkBtn(ctx, "Emissor FUMAÇA", 58, function() return remote("px_emit", { kind = "fumaca" }) end)
	mkBtn(ctx, "Emissor FAÍSCAS", 104, function() return remote("px_emit", { kind = "faíscas" }) end)
end)

makePanel("anim", "ANIM X — spring/bounce", function(ctx)
	B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
		Text = "Loop pingpong: Size+Position",
		Font = t.fontm, TextSize = 11, TextColor3 = t.muted,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, ctx.root)
	mkBtn(ctx, "Cubo animado (spring bounce)", 24, function() return remote("aax_demo", {}) end)
end)

makePanel("stats", "STATS X — saude do mundo", function(ctx)
	local grid = B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 180), BackgroundColor3 = t.sect, BorderSizePixel = 0,
		Text = "…", Font = t.fontm, TextSize = 12, TextColor3 = t.muted,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, ctx.root)
	H(grid, 8)
	local gp = Instance.new("UIPadding")
	gp.PaddingLeft = UDim.new(0, 10)
	gp.PaddingTop = UDim.new(0, 8)
	gp.Parent = grid
	mkBtn(ctx, "Atualizar agora", 190, function()
		if not netFn then error("sem ponte") end
		local s0 = netFn:InvokeServer({ op = "stats" })
		local line = ("ATX:%s  AWX:%s  ASXN:%s\nAAX:%s  AUX:%s  AEX:%s\nAPX:%s  RPX:%s\nWeather=%s  Bodies=%d  Ropes=%d"):format(
			s0.atx and "ON" or "--", s0.awx and "ON" or "--", s0.asxn and "ON" or "--",
			s0.aax and "ON" or "--", s0.aux and "ON" or "--", s0.aex and "ON" or "--",
			s0.apx and "ON" or "--", s0.rpx and "ON" or "--",
			tostring(s0.weather), s0.bodies or 0, s0.ropes or 0)
		grid.Text = line
		return "stats ATUALIZADOS"
	end)
end)

-- ============ botoes do dock (desativado: topbar assume) ============
local order = { "terrain", "water", "scene", "atmos", "rope", "px", "anim", "stats" }
if dock then for _, id in ipairs(order) do
	local b0 = B("TextButton", {
		Size = UDim2.fromOffset(30, 30), BackgroundColor3 = t.sect,
		BorderSizePixel = 0, Text = "", AutoButtonColor = true,
	}, dock)
	H(b0, 8)
	stroke(b0, 1, t.border)
	local ic = B("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(1, 1), BackgroundTransparency = 1 }, b0)
	drawIcon(ic, id, t.cyan)
	b0.MouseEnter:Connect(function() b0.BackgroundColor3 = t.sel end)
	b0.MouseLeave:Connect(function() b0.BackgroundColor3 = t.sect end)
	b0.MouseButton1Click:Connect(function()
		for _, w in pairs(panels) do w.Visible = false end
		panels[id].Visible = true
	end)
end end

print("[ArkherX] 05_StudioX: paineis prontos (barra lateral removida -> TOPBAR)")
