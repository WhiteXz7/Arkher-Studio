-- =============================================================
-- Arkher_09_Topbar — A TOPBAR DE VERDADE: ABAS estilo Roblox.
--
-- Estrutura: uma faixa de ABAS (HOME/MUNDO/NATUREZA/CRIAÇÃO/
-- ESTÚDIO/CONSTRUIR/DEV) logo ACIMA do Ribbon original. Cada aba
-- tem sua PÁGINA de botões GRANDES com ÍCONE DESENHADO EM CIMA +
-- label embaixo — mesmo estilo dos botões originais. Aba HOME =
-- Ribbon INTACTO do estúdio (nada do original é destruído nem
-- movido: só deslocado 26px para baixo, junto com os docks, para a
-- faixa de abas respirar). Ícones: IconX procedural 32x32 (mesh de
-- linhas/formas), desenhados na hora, SEM depender de asset upload.
-- Ação padrão: deckOpen(viewId) — cada botão abre a UI única dele
-- (a diretriz "clicou na topbar -> ativou o sistema dela").
-- =============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local client = Players.LocalPlayer
local playerGui = client:WaitForChild("PlayerGui")

-- espera o núcleo da UI (mesmo contrato do 03)
local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 09_Topbar precisa estar dentro de ArkherStudioUI") return end
-- o núcleo mora dentro de ArkherServerClientRuntime (mesmo contrato do 03/02/04)
local i = uiRoot:WaitForChild("ArkherServerClientRuntime", 20)
if not i then warn("[ArkherX] 09: núcleo (01_Nucleo) não achado.") return end
local j = i:WaitForChild("ClientBus", 20)
local k = i:WaitForChild("CoreReady", 20)
if not j or not k then warn("[ArkherX] 09: núcleo incompleto.") return end
local t0 = os.clock()
while not k.Value and i.Parent and os.clock() - t0 < 20 do task.wait(0.04) end
if not k.Value then warn("[ArkherX] 09: núcleo não subiu a tempo.") return end
if not j:Invoke("ClaimPart", { name = "09_Topbar", script = script }) then return end

local function W(action, payload)
	local ok, r = pcall(function() return j:Invoke(action, payload or {}) end)
	if not ok then return { error = tostring(r) } end
	if type(r) == "table" then return r end
	return { result = r }
end
local function apiResult(action, payload)
	local r = W("API", { action = action, payload = payload or {}, quiet = true })
	if r and r.result then return r.result end
	return nil, r and r.error
end
local function deckOpen(v)
	local d = rawget(_G, "ArkherDeck")
	if d and d.open then return d.open(v, nil) end
	W("Message", { text = "Deck X ainda carregando…", bad = true })
end

-- ---------- Canvas/Ribbon descobertos por medida (não por nome decorado) ----------
local canvas = i:FindFirstChild("Canvas") or i
local ribbon = canvas:FindFirstChild("Ribbon")
local menuBar = canvas:FindFirstChild("MenuBar")

-- ---------- paleta (mesma do estúdio) ----------
local m = {
	bg = Color3.fromRGB(7, 16, 32), panel = Color3.fromRGB(9, 23, 44), section = Color3.fromRGB(20, 42, 75),
	border = Color3.fromRGB(52, 80, 120), text = Color3.fromRGB(228, 240, 255), muted = Color3.fromRGB(146, 170, 202),
	blue = Color3.fromRGB(35, 139, 230), selected = Color3.fromRGB(17, 76, 139), cyan = Color3.fromRGB(43, 203, 243),
	purple = Color3.fromRGB(166, 117, 240), gold = Color3.fromRGB(240, 185, 70), error = Color3.fromRGB(255, 164, 143),
	ribbonBg = Color3.fromRGB(10, 22, 42),
}

-- =============================================================
-- IconX — desenhador de ícones 32x32 (procedural, rico em cor)
-- =============================================================
local function drawIcon(kind, parent, size)
	size = size or 28
	local g2 = Instance.new("Frame")
	g2.Name = "Icon_" .. kind
	g2.Size = UDim2.fromOffset(size, size)
	g2.BackgroundTransparency = 1
	g2.BorderSizePixel = 0
	g2.Parent = parent
	local ag = size / 32
	local function box(x, y, w2, h2, color, round, transp)
		local f = Instance.new("Frame")
		f.Position = UDim2.fromOffset(x * ag, y * ag)
		f.Size = UDim2.fromOffset(math.max(w2 * ag, 1), math.max(h2 * ag, 1))
		f.BackgroundColor3 = color
		f.BackgroundTransparency = transp or 0
		f.BorderSizePixel = 0
		f.ZIndex = (parent and parent.ZIndex or 44) + 1
		if round then
			local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, round * ag) c.Parent = f
		end
		f.Parent = g2
		return f
	end
	local function line(x1, y1, x2, y2, color, thick)
		local dx, dy = (x2 - x1) * ag, (y2 - y1) * ag
		local th = math.max((thick or 2.2) * ag, 1)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset((x1 + x2) / 2 * ag, (y1 + y2) / 2 * ag)
		f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + th, th)
		f.Rotation = math.deg(math.atan2(dy, dx))
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.ZIndex = (parent and parent.ZIndex or 44) + 1
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = f
		f.Parent = g2
		return f
	end
	local function circ(x, y, r, color, thick, transp)
		local f = box(x - r, y - r, 2 * r, 2 * r, color, r, transp)
		if thick then
			local st = Instance.new("UIStroke") st.Thickness = math.max(thick * ag, 1) st.Color = color
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = f
			f.BackgroundTransparency = 1
		end
		return f
	end
	local function arc(cx, cy, r, a1, a2, color, thick)
		local last
		for A = 0, 24 do
			local a = math.rad(a1 + (a2 - a1) * A / 24)
			local p2 = { cx + r * math.cos(a), cy + r * math.sin(a) }
			if last then line(last[1], last[2], p2[1], p2[2], color, thick or 2.2) end
			last = p2
		end
	end
	local function poly(pts, color, thick)
		for q = 1, #pts - 1 do line(pts[q][1], pts[q][2], pts[q + 1][1], pts[q + 1][2], color, thick or 2.4) end
	end

	local P = m
	if kind == "HOME" then
		line(6, 17, 16, 7, P.cyan, 3) line(16, 7, 26, 17, P.cyan, 3)
		box(9, 16, 14, 11, P.section, 2) box(14, 21, 4, 6, P.cyan, 1)
	elseif kind == "TERRAIN" then
		line(2, 25, 12, 10, Color3.fromRGB(154, 208, 104), 3)
		line(12, 10, 18, 19, Color3.fromRGB(154, 208, 104), 3)
		line(18, 19, 23, 14, Color3.fromRGB(190, 160, 110), 3)
		line(23, 14, 30, 25, Color3.fromRGB(190, 160, 110), 3)
		circ(24, 7, 3.2, P.gold)
		line(2, 28, 30, 28, Color3.fromRGB(120, 96, 66), 2)
	elseif kind == "WATER" then
		for q = 0, 2 do
			arc(8 + q * 8, 13, 4, 180, 360, Color3.fromRGB(64, 150, 255), 2.4)
			arc(8 + q * 8, 22, 4, 180, 360, Color3.fromRGB(40, 110, 220), 2.4)
		end
	elseif kind == "MODELER" then
		line(16, 4, 28, 11, m.cyan, 2.2) line(28, 11, 28, 23, m.cyan, 2.2)
		line(28, 23, 16, 30, m.cyan, 2.2) line(16, 30, 4, 23, m.cyan, 2.2)
		line(4, 23, 4, 11, m.cyan, 2.2) line(4, 11, 16, 4, m.cyan, 2.2)
		line(4, 11, 16, 18, m.blue, 2) line(28, 11, 16, 18, m.blue, 2) line(16, 18, 16, 30, m.blue, 2)
	elseif kind == "ANIMATOR" then
		circ(11, 7, 3, P.text) line(11, 10, 11, 20, P.text, 2.6) line(11, 14, 4, 18, P.text, 2.2)
		line(11, 14, 18, 18, P.text, 2.2) line(11, 20, 6, 29, P.text, 2.2) line(11, 20, 16, 29, P.text, 2.2)
		arc(21, 9, 6, -40, 140, P.gold, 2) line(25, 3.6, 27, 8, P.gold, 2)
	elseif kind == "SPACE" then
		circ(16, 16, 8, Color3.fromRGB(90, 140, 255), nil, 0.85)
		arc(16, 16, 13, 150, 390, Color3.fromRGB(220, 200, 120), 2)
		circ(26, 6, 1.6, P.gold) circ(5, 25, 1.3, P.text) circ(28, 24, 1.1, P.text)
	elseif kind == "FABRICAR" then
		box(5, 12, 22, 16, P.section, 2)
		line(5, 18, 27, 18, P.muted, 1.6)
		box(13, 6, 6, 6, Color3.fromRGB(190, 130, 70), 1)
		line(21, 8, 25, 4, P.gold, 2.4) line(7, 8, 11, 4, P.gold, 2.4)
		line(12, 23, 20, 23, P.cyan, 1.8)
	elseif kind == "ATMOS" then
		circ(12, 12, 5, P.gold)
		for A = 0, 7 do
			local a = math.rad(A * 45)
			line(12 + 8 * math.cos(a), 12 + 8 * math.sin(a), 12 + 11 * math.cos(a), 12 + 11 * math.sin(a), P.gold, 2)
		end
		box(8, 22, 18, 5, Color3.fromRGB(180, 190, 210), 3) box(14, 19, 12, 5, Color3.fromRGB(160, 170, 195), 3)
	elseif kind == "CLIMA" then
		arc(11, 13, 6, 45, 315, Color3.fromRGB(96, 160, 255), 2.6) circ(16, 6, 2.4, Color3.fromRGB(96, 160, 255))
		arc(22, 22, 6, -135, 135, Color3.fromRGB(255, 110, 100), 2.6) circ(16, 24, 2.4, Color3.fromRGB(255, 110, 100))
		line(20, 9, 17, 15, Color3.fromRGB(96, 160, 255), 2) line(12, 23, 15, 17, Color3.fromRGB(255, 110, 100), 2)
	elseif kind == "VIDA" then
		circ(16, 12, 4, Color3.fromRGB(255, 120, 140))
		circ(10, 9, 3, Color3.fromRGB(130, 230, 150)) circ(10, 15, 3, Color3.fromRGB(130, 230, 150))
		circ(22, 9, 3, Color3.fromRGB(130, 230, 150)) circ(22, 15, 3, Color3.fromRGB(130, 230, 150))
		line(16, 16, 16, 28, Color3.fromRGB(255, 120, 140), 2.4) line(16, 28, 10, 30, P.text, 2) line(16, 28, 22, 30, P.text, 2)
	elseif kind == "CIDADE" then
		box(4, 14, 8, 15, P.section) box(5.5, 16.5, 5, 3, P.cyan) box(5.5, 22, 5, 3, P.cyan)
		box(13, 7, 9, 22, m.blue) box(14.5, 10, 6, 4, P.text) box(14.5, 17, 6, 4, P.text) box(14.5, 24, 6, 4, P.text)
		box(23, 12, 6, 17, P.gold) box(24.5, 14.5, 3, 3, P.text) box(24.5, 20, 3, 3, P.text)
		line(2, 29, 30, 29, P.muted, 1.8)
	elseif kind == "AUDIO" then
		box(4, 12, 7, 9, P.cyan, 1) line(11, 12, 17, 6, P.cyan, 2.6) line(17, 6, 17, 27, P.cyan, 2.6) line(17, 27, 11, 21, P.cyan, 2.6)
		arc(17, 16.5, 7, -55, 55, P.text, 2) arc(17, 16.5, 11, -50, 50, P.muted, 2)
	elseif kind == "FX" then
		line(16, 4, 16, 24, P.gold, 2.6) line(8, 10, 24, 24, P.gold, 2.2) line(24, 10, 8, 24, P.gold, 2.2)
		circ(16, 18, 4.5, Color3.fromRGB(255, 120, 60)) circ(16, 18, 2, Color3.fromRGB(255, 220, 130))
		circ(27, 26, 1.6, Color3.fromRGB(255, 154, 61)) circ(5, 26, 1.6, Color3.fromRGB(255, 154, 61))
	elseif kind == "CORDAS" then
		local last
		for q = 0, 20 do
			local x2 = 3 + q * 1.3
			local y2 = 12 + math.sin(q / 20 * math.pi) * 8
			if last then line(last[1], last[2], x2, y2, Color3.fromRGB(216, 162, 90), 2.4) end
			last = { x2, y2 }
		end
		circ(3, 12, 2, P.text) circ(29, 12, 2, P.text)
		line(16, 20, 16, 28, P.cyan, 2) circ(16, 29, 1.6, P.cyan)
	elseif kind == "PART" then
		box(6, 8, 20, 20, m.blue, 3) box(9, 11, 14, 5, Color3.fromRGB(90, 170, 255), 2)
		line(6, 24, 26, 30, m.cyan, 2)
	elseif kind == "TOOLBOX" then
		box(4, 10, 24, 18, Color3.fromRGB(190, 140, 60), 3)
		box(11, 6, 10, 5, Color3.fromRGB(150, 108, 44), 3)
		box(4, 16, 24, 3, Color3.fromRGB(150, 108, 44), 1)
		circ(13, 17.5, 3.4, P.gold, 1.6)
		line(21.5, 21, 25.5, 25, P.text, 2) line(25.5, 21, 21.5, 25, P.text, 2)
	elseif kind == "PROPS" then
		for q = 0, 2 do
			local y2 = 9 + q * 7
			line(5, y2, 27, y2, P.muted, 2)
			circ(9 + (q % 2) * 12 + q * 2, y2, 3, P.cyan, 1.8)
		end
	elseif kind == "CORES" then
		for A = 0, 11 do
			local a = math.rad(A * 30)
			circ(16 + 10 * math.cos(a), 16 + 10 * math.sin(a), 2.6, Color3.fromHSV(A / 12, 0.9, 1))
		end
		circ(16, 16, 4.4, Color3.fromRGB(255, 255, 255), 1.6)
	elseif kind == "OUTPUT" then
		box(4, 6, 24, 20, P.section, 3)
		line(8, 11, 14, 15, P.cyan, 2.6) line(14, 15, 8, 19, P.cyan, 2.6)
		line(16, 20, 25, 20, P.text, 2)
	elseif kind == "COMANDO" then
		box(4, 7, 24, 18, Color3.fromRGB(16, 26, 38), 3)
		line(8, 12, 13, 15, P.gold, 2.2) line(13, 15, 8, 18, P.gold, 2.2)
		line(15, 18, 24, 18, P.text, 1.8)
		line(8, 9, 24, 9, P.muted, 1.4)
	elseif kind == "SCRIPTS" then
		box(8, 3, 17, 26, P.cyan, 2, 1)
		line(11, 9, 22, 9, P.cyan, 2) line(11, 14, 19, 14, P.cyan, 2) line(11, 19, 22, 19, P.cyan, 2) line(11, 24, 17, 24, P.cyan, 2)
		box(4, 8, 4, 16, m.purple, 2)
	elseif kind == "PY" then
		line(9, 6, 20, 6, m.blue, 3) line(20, 6, 20, 14, m.blue, 3) line(20, 14, 12, 14, m.blue, 3)
		line(12, 14, 12, 22, P.gold, 3) line(12, 22, 23, 22, P.gold, 3) line(23, 22, 23, 30, P.gold, 3)
		circ(11.5, 8.5, 1.3, P.text) circ(20.5, 24.5, 1.3, P.text)
	elseif kind == "SCULPT" then
		line(3, 26, 11, 14, Color3.fromRGB(240, 170, 80), 3)
		line(11, 14, 16, 21, Color3.fromRGB(240, 170, 80), 3)
		line(16, 21, 22, 15, Color3.fromRGB(240, 170, 80), 3)
		line(22, 15, 29, 26, Color3.fromRGB(240, 170, 80), 3)
		circ(24, 9, 4, P.section, 1.6)
		line(24, 13, 24, 17, P.muted, 2)
	elseif kind == "PLUGINS" then
		box(5, 7, 14, 14, P.cyan, 3)
		box(17, 17, 11, 11, m.purple, 3)
		circ(12, 7, 3, P.cyan) circ(17, 17, 3, m.purple)
		line(15, 15, 19, 19, P.text, 2)
	elseif kind == "GRUPOS" then
		box(4, 6, 17, 17, P.cyan, 3, 0.25)
		box(11, 12, 17, 17, P.gold, 3, 0.35)
		circ(16, 14.5, 4, P.text, 1.6)
	elseif kind == "UNION" then
		circ(12, 16, 9, P.cyan, 2.4) circ(20, 16, 9, P.gold, 2.4)
		arc(16, 16, 9, -40, 40, P.text, 2) arc(16, 16, 9, 140, 220, P.text, 2)
	elseif kind == "NEGATE" then
		circ(14, 16, 10, P.cyan, 2.4)
		circ(24, 16, 7, P.error, 2.4)
		circ(25.5, 16, 5.6, m.ribbonBg)
	elseif kind == "PUBLISH" then
		line(16, 26, 16, 6, P.cyan, 3) line(10, 12, 16, 6, P.cyan, 3) line(16, 6, 22, 12, P.cyan, 3)
		box(6, 28, 20, 3, P.section, 1)
	else
		circ(16, 16, 10, P.muted, 2)
	end
	return g2
end

-- =============================================================
-- Estrutura de ABAS + páginas (botões com ícone em cima)
-- =============================================================
-- { icon, label, action = {kind="deck", view} | {kind="part"} | {kind="api", action, payload} }
local TABS = {
	{ name = "HOME", original = true, tip = "O ribbon ORIGINAL do estúdio (FileTools, gizmos etc) — intacto" },
	{ name = "MUNDO", items = {
		{ "TERRAIN", "Terrain", { kind = "deck", view = "terrain" } },
		{ "SCULPT", "Sculpt", { kind = "deck", view = "sculpt" } },
		{ "WATER", "Água X", { kind = "deck", view = "water" } },
		{ "SPACE", "Espaço", { kind = "deck", view = "espaco" } },
		{ "ATMOS", "Atmosfera", { kind = "deck", view = "atmos" } },
		{ "CLIMA", "Clima", { kind = "deck", view = "clima" } },
		{ "CIDADE", "Cidade", { kind = "deck", view = "cidade" } },
	} },
	{ name = "NATUREZA", items = {
		{ "VIDA", "Vida", { kind = "deck", view = "vida" } },
		{ "CORDAS", "Cordas", { kind = "deck", view = "cordas" } },
		{ "FX", "Partículas", { kind = "deck", view = "fx" } },
		{ "AUDIO", "Áudio", { kind = "deck", view = "audio" } },
	} },
	{ name = "CRIAÇÃO", items = {
		{ "MODELER", "Modeler", { kind = "deck", view = "modeler" } },
		{ "FABRICAR", "Fabricar", { kind = "deck", view = "fabricar" } },
		{ "ANIMATOR", "Animator", { kind = "deck", view = "animator" } },
	} },
	{ name = "CONSTRUIR", items = {
		{ "PART", "Part ▸", { kind = "part" } },
		{ "UNION", "Union", { kind = "api", action = "CsgDo", payload = { op = "union" } } },
		{ "NEGATE", "Negate", { kind = "api", action = "CsgDo", payload = { op = "negate" } } },
		{ "TOOLBOX", "Toolbox", { kind = "deck", view = "toolbox" } },
	} },
	{ name = "ESTÚDIO", items = {
		{ "PROPS", "Propriedades", { kind = "deck", view = "props" } },
		{ "CORES", "Cores", { kind = "deck", view = "cores" } },
		{ "OUTPUT", "Output", { kind = "deck", view = "output" } },
		{ "COMANDO", "Comando", { kind = "deck", view = "comando" } },
	} },
	{ name = "DEV", items = {
		{ "SCRIPTS", "Scripts", { kind = "deck", view = "scripts" } },
		{ "PY", "Python", { kind = "deck", view = "py" } },
		{ "PLUGINS", "Plugins", { kind = "deck", view = "plugins" } },
		{ "GRUPOS", "Colisões", { kind = "deck", view = "grupos" } },
	} },
}

-- medidas
local ribbonRect = { x = 0, y = 78, w = 1366, h = 96 }
local function measureRibbon()
	if ribbon then
		local ok, ap, asz, cp = pcall(function()
			return ribbon.AbsolutePosition, ribbon.AbsoluteSize, canvas.AbsolutePosition
		end)
		if ok and asz and asz.Y > 10 then
			ribbonRect = { x = ap.X - cp.X, y = ap.Y - cp.Y, w = asz.X, h = asz.Y }
		end
	end
	return ribbonRect
end

-- 1) empurra o ribbon original + docks 26px para baixo (UMA VEZ só)
local pushedDone = false
local function pushOriginal()
	if pushedDone then return end
	if not ribbon then return end
	local ok = pcall(function()
		local m0 = measureRibbon()
		ribbon.Position = ribbon.Position + UDim2.fromOffset(0, 26)
		for _, nm in ipairs({ "HierarchyDock", "PropertiesDock" }) do
			local d2 = canvas:FindFirstChild(nm)
			if d2 then
				d2.Position = d2.Position + UDim2.fromOffset(0, 26)
				d2.Size = d2.Size - UDim2.fromOffset(0, 26)
			end
		end
	end)
	if ok then pushedDone = true end
	-- re-medir depois do deslocamento
	task.defer(measureRibbon)
end

-- 2) tab strip
local tabStrip = Instance.new("Frame")
tabStrip.Name = "ArkherTabStrip"
tabStrip.BackgroundColor3 = m.bg
tabStrip.BackgroundTransparency = 0.05
tabStrip.BorderSizePixel = 0
tabStrip.ZIndex = 55
local tpad = Instance.new("UIPadding") tpad.PaddingLeft = UDim.new(0, 6) tpad.PaddingTop = UDim.new(0, 2) tpad.Parent = tabStrip
local tlay = Instance.new("UIListLayout")
tlay.FillDirection = Enum.FillDirection.Horizontal
tlay.Padding = UDim.new(0, 4)
tlay.VerticalAlignment = Enum.VerticalAlignment.Center
tlay.SortOrder = Enum.SortOrder.LayoutOrder
tlay.Parent = tabStrip

-- 3) faixa de páginas (cobre o ribbon quando aba ≠ HOME)
local pagesHost = Instance.new("Frame")
pagesHost.Name = "ArkherTabPages"
pagesHost.BackgroundColor3 = m.ribbonBg
pagesHost.BackgroundTransparency = 0.02
pagesHost.BorderSizePixel = 0
pagesHost.Visible = false
pagesHost.ZIndex = 54
local pstroke = Instance.new("UIStroke") pstroke.Thickness = 1 pstroke.Color = m.border pstroke.Parent = pagesHost

local function layoutTopbar()
	local m0 = measureRibbon()
	if ribbon then
		tabStrip.Position = UDim2.fromOffset(m0.x, m0.y - 26)
		tabStrip.Size = UDim2.new(0, m0.w, 0, 26)
		pagesHost.Position = UDim2.fromOffset(m0.x, m0.y)
		pagesHost.Size = UDim2.new(0, m0.w, 0, m0.h)
	else
		-- sem ribbon achada: vai no topo
		tabStrip.Position = UDim2.fromOffset(8, 64)
		tabStrip.Size = UDim2.new(1, -16, 0, 26)
		pagesHost.Position = UDim2.fromOffset(8, 92)
		pagesHost.Size = UDim2.new(1, -16, 0, 96)
	end
end
tabStrip.Parent = canvas
pagesHost.Parent = canvas

-- popup de shapes do PART
local shapesPopup
local function closeShapes()
	if shapesPopup and shapesPopup.Parent then shapesPopup:Destroy() end
	shapesPopup = nil
end
local SHAPES = {
	{ "Block", "Block (4×2×4)" }, { "Ball", "Ball (esfera)" },
	{ "Cylinder", "Cylinder (roda)" }, { "CylinderVertical", "Cylinder vertical (pilar)" },
	{ "Wedge", "Wedge (rampa)" }, { "CornerWedge", "CornerWedge (canto)" },
	{ "Truss", "Truss (treliça)" },
}
local function openShapes(hostBtn)
	closeShapes()
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(230, #SHAPES * 28 + 12)
	f.BackgroundColor3 = m.panel
	f.BorderSizePixel = 0
	f.ZIndex = 70
	f.Active = true
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = f
	local st = Instance.new("UIStroke") st.Thickness = 1.5 st.Color = m.border st.Parent = f
	local ap = hostBtn.AbsolutePosition
	local cp = canvas.AbsolutePosition
	f.Position = UDim2.fromOffset(ap.X - cp.X, hostBtn.AbsolutePosition.Y - cp.Y + hostBtn.AbsoluteSize.Y + 4)
	for q, spec in ipairs(SHAPES) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -12, 0, 24)
		row.Position = UDim2.fromOffset(6, 6 + (q - 1) * 28)
		row.BackgroundColor3 = m.panel
		row.Text = "   " .. spec[2]
		row.Font = Enum.Font.GothamBold
		row.TextSize = 12
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = m.text
		row.ZIndex = 71
		row.BorderSizePixel = 0
		local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 6) rc.Parent = row
		row.MouseEnter:Connect(function() row.BackgroundColor3 = m.selected end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = m.panel end)
		row.Activated:Connect(function()
			closeShapes()
			task.spawn(function()
				local res = apiResult("QuickPart", { shape = spec[1] })
				if res and res.msg then W("Message", { text = res.msg }) else W("Message", { text = spec[1] .. " criado." }) end
			end)
		end)
		row.Parent = f
	end
	shapesPopup = f
	f.Parent = canvas
	UIS.InputBegan:Connect(function(inp, gp)
		if gp or not f.Parent then return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = Vector2.new(inp.Position.X, inp.Position.Y)
			local fp, fs = f.AbsolutePosition, f.AbsoluteSize
			if not (mp.X >= fp.X and mp.Y >= fp.Y and mp.X <= fp.X + fs.X and mp.Y <= fp.Y + fs.Y) then
				closeShapes()
			end
		end
	end)
end

-- abas e páginas
local curTab = 1
local tabBtns = {}
local pageFrames = {}

local function activateTab(idx)
	curTab = idx
	for q, b in ipairs(tabBtns) do
		b.BackgroundColor3 = (q == idx) and m.selected or m.panel
		b.TextColor3 = (q == idx) and m.cyan or m.muted
	end
	local tab = TABS[idx]
	for q, pf in ipairs(pageFrames) do
		pf.Visible = (q == idx) and not tab.original
	end
	pagesHost.Visible = not tab.original
	rawset(_G, "ArkherTopTab", tab.name)
	closeShapes()
end

for idx, tab in ipairs(TABS) do
	local tb = Instance.new("TextButton")
	tb.Name = "Tab_" .. tab.name
	tb.Size = UDim2.fromOffset(tab.method and 10 or math.max(64, #tab.name * 10 + 24), 0, 22)
	tb.AutoButtonColor = true
	tb.BackgroundColor3 = m.panel
	tb.Text = tab.name
	tb.Font = Enum.Font.GothamBold
	tb.TextSize = 13
	tb.TextColor3 = m.muted
	tb.ZIndex = 56
	tb.BorderSizePixel = 0
	tb.LayoutOrder = idx
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 7) c.Parent = tb
	tb.Activated:Connect(function() activateTab(idx) end)
	if tab.tip then
		tb.MouseEnter:Connect(function() end)
	end
	tb.Parent = tabStrip
	tabBtns[idx] = tb

	-- página (página HOME não é criada: ribbon original aparece)
	if not tab.original then
		local pf = Instance.new("Frame")
		pf.Name = "Page_" .. tab.name
		pf.Size = UDim2.fromScale(1, 1)
		pf.BackgroundTransparency = 1
		pf.Visible = false
		pf.ZIndex = 57
		local grid = Instance.new("UIGridLayout")
		grid.FillDirection = Enum.FillDirection.Horizontal
		grid.CellPadding = UDim2.new(0, 6, 0, 4)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
		grid.Parent = pf
		local gpad = Instance.new("UIPadding")
		gpad.PaddingLeft = UDim.new(0, 8) gpad.PaddingTop = UDim.new(0, 6)
		gpad.Parent = pf
		-- responsivo: recalcula largura de célula pelo espaço útil
		local function layoutPage()
			local avail = math.max(tabStrip.AbsoluteSize.X, 600)
			local hR = ribbonRect.h > 20 and ribbonRect.h or 96
			local cellH = math.max(hR - 16, 58)
			local cellW = 78
			local cols = math.max(1, math.floor((avail - 16) / (cellW + 6)))
			if cols > #tab.items then cols = #tab.items end
			-- se sobrar espaço: células mais largas e confortáveis
			local extra = avail - 16 - cols * (cellW + 6)
			if extra > 0 and cols > 0 then cellW = cellW + math.min(extra / cols, 40) end
			grid.CellSize = UDim2.new(0, cellW, 0, cellH)
		end
		layoutPage()
		tabStrip:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutPage)
		pf:SetAttribute("layoutPage", true)
		task.spawn(function() task.wait(0.4) layoutPage() end)

		for q2, it in ipairs(tab.items) do
			local iconKind, label2, act = it[1], it[2], it[3]
			local btn = Instance.new("TextButton")
			btn.Name = "TopBtn_" .. iconKind
			btn.BackgroundColor3 = m.panel
			btn.BackgroundTransparency = 0.12
			btn.Text = ""
			btn.AutoButtonColor = true
			btn.BorderSizePixel = 0
			btn.ZIndex = 58
			btn.LayoutOrder = q2
			local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = btn
			btn.MouseEnter:Connect(function() btn.BackgroundColor3 = m.selected end)
			btn.MouseLeave:Connect(function() btn.BackgroundColor3 = m.panel end)
			-- ícone EM CIMA, label EMBAIXO (estilo ribbon)
			local ic = drawIcon(iconKind, btn, 30)
			ic.AnchorPoint = Vector2.new(0.5, 0)
			ic.Position = UDim2.new(0.5, 0, 0, 5)
			ic.ZIndex = 59
			local lb = Instance.new("TextLabel")
			lb.Name = "Label"
			lb.AnchorPoint = Vector2.new(0.5, 1)
			lb.Position = UDim2.new(0.5, 0, 1, -3)
			lb.Size = UDim2.new(1, -4, 0, 18)
			lb.BackgroundTransparency = 1
			lb.Text = label2
			lb.Font = Enum.Font.GothamBold
			lb.TextSize = 11
			lb.TextColor3 = m.text
			lb.TextXAlignment = Enum.TextXAlignment.Center
			lb.ZIndex = 59
			lb.Parent = btn
			btn.Activated:Connect(function()
				if act.kind == "deck" then
					deckOpen(act.view)
				elseif act.kind == "part" then
					openShapes(btn)
				elseif act.kind == "api" then
					task.spawn(function()
						local res = apiResult(act.action, act.payload or {})
						if res and res.msg then W("Message", { text = res.msg }) end
					end)
				end
			end)
			btn.Parent = pf
		end
		pf.Parent = pagesHost
		pageFrames[idx] = pf
	end
end

-- posicionamento final + listeners responsivos
pushOriginal()
layoutTopbar()
task.delay(0.5, layoutTopbar)
if ribbon then
	ribbon:GetPropertyChangedSignal("AbsolutePosition"):Connect(layoutTopbar)
	ribbon:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTopbar)
end
pcall(function()
	canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutTopbar)
end)
activateTab(1) -- HOME: ribbon original visivel
tabStrip.Active = true
W("Message", { text = "Topbar com ABAS pronta: HOME = ribbon original; MUNDO/NATUREZA/CRIAÇÃO/CONSTRUIR/ESTÚDIO/DEV = sistemas Arkher com ícones desenhados. Clique num botão para ATIVAR o sistema dele." })
print("[ArkherX] 09_Topbar: 7 abas (HOME original + 6 páginas com ícones IconX) — PART com submenu de formas, ribbon original intacto")
