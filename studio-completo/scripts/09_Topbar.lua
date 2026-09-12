-- =============================================================
-- Arkher_09_Topbar (ROUND 12) — SEM overlay. Botões X vivem
-- DENTRO do Ribbon ORIGINAL, clonados de um botão real dele
-- (mesmo tamanho/estilo/cor — cara nativa, z-order nativo).
--
-- Por que a versão antiga morreu: ela criava uma faixa própria
-- cobrindo a linha de menus real (Active=true engolia os cliques
-- de ESTÚDIO/MODELAGEM/...) e flutuava fora do lugar. Agora:
--  * ZERO frames novos por cima do canvas.
--  * Botões: PART ▸ (7 formas, spawn server na frente da câmera),
--    BASEPLATE (garante chão), UNION / NEGATE (CSG real) e
--    TOOLBOX (dock estilo Roblox, do 10_Studio).
--  * Os menus da faixa de menus (MUNDO/MODELAGEM/…) são do 03 e
--    voltam a funcionar porque não existe mais overlay.
-- =============================================================

local Players = game:GetService("Players")
local client = Players.LocalPlayer

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 09_RibbonX precisa estar dentro de ArkherStudioUI") return end
local i = uiRoot:WaitForChild("ArkherServerClientRuntime", 20)
if not i then warn("[ArkherX] 09: núcleo não achado.") return end
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
	W("Message", { text = "UI X ainda carregando…", bad = true })
end

-- clique à prova de bala: Activated + MouseButton1Click com dedupe
local function onTap(btn, fn)
	local lastEvt, lastT = nil, -1
	local function fire(src, ...)
		local now = os.clock()
		if lastEvt and lastEvt ~= src and now - lastT < 0.12 then
			lastEvt, lastT = nil, now
			return
		end
		lastEvt, lastT = src, now
		local ok, err = pcall(fn, ...)
		if not ok then warn("[ArkherX] 09 clique: " .. tostring(err)) end
	end
	pcall(function() btn.Activated:Connect(function(...) fire("A", ...) end) end)
	pcall(function() btn.MouseButton1Click:Connect(function(...) fire("M", ...) end) end)
	btn.Active = true
	btn.Selectable = true
	btn.Visible = true
end

local m = {
	bg = Color3.fromRGB(7, 16, 32), panel = Color3.fromRGB(9, 23, 44), section = Color3.fromRGB(20, 42, 75),
	border = Color3.fromRGB(52, 80, 120), text = Color3.fromRGB(228, 240, 255), muted = Color3.fromRGB(146, 170, 202),
	blue = Color3.fromRGB(35, 139, 230), selected = Color3.fromRGB(17, 76, 139), cyan = Color3.fromRGB(43, 203, 243),
	purple = Color3.fromRGB(166, 117, 240), gold = Color3.fromRGB(240, 185, 70), error = Color3.fromRGB(255, 164, 143),
}

-- ---------- localizar Canvas/Ribbon e um BOTÃO-MOLDE nativo ----------
local canvas = uiRoot:FindFirstChild("Canvas")
local ribbon = canvas and canvas:FindFirstChild("Ribbon") or nil
if not ribbon then
	warn("[ArkherX] 09: Ribbon não achada — botões X não injetados.")
	return end
local popups = canvas:FindFirstChild("ServerEditorPopups")
local uiscale = canvas:FindFirstChild("ResponsiveScale")

local function findTemplate()
	for _, d in ipairs(ribbon:GetDescendants()) do
		if d:IsA("GuiButton") and d:FindFirstChild("Icon") and d.Parent and d.Parent:IsA("GuiObject") then
			return d
		end
	end
	-- fallback: qualquer GuiButton do ribbon
	for _, d in ipairs(ribbon:GetDescendants()) do
		if d:IsA("GuiButton") then return d end
	end
	return nil
end
local template = findTemplate()
if not template then
	warn("[ArkherX] 09: nenhum botão-molde no Ribbon.")
	return end

-- ---------- mini-art 16px (mesma linguagem dos ícones do estúdio) ----------
local function drawIcon16(kind, parent, zi)
	local old = parent:FindFirstChild("Icon")
	local pos, size
	if old then pos, size = old.Position, old.Size; old:Destroy() end
	local g2 = Instance.new("Frame")
	g2.Name = "Icon"
	g2.BackgroundTransparency = 1
	if pos then g2.Position = pos else g2.Position = UDim2.new(0.5, -8, 0.5, -8) end
	if size then g2.Size = size else g2.Size = UDim2.fromOffset(16, 16) end
	g2.Parent = parent
	local ZI = zi or (parent.ZIndex + 1)
	local ag = (g2.AbsoluteSize.X > 0 and g2.AbsoluteSize.X or 16) / 16
	ag = math.max(ag, 16 / 16)
	local function box(x, y, w2, h2, color, round, transp)
		local f = Instance.new("Frame")
		f.Position = UDim2.fromOffset(x, y)
		f.Size = UDim2.fromOffset(math.max(w2, 1), math.max(h2, 1))
		f.BackgroundColor3 = color
		f.BackgroundTransparency = transp or 0
		f.BorderSizePixel = 0
		f.ZIndex = ZI
		if round then local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, round) c.Parent = f end
		f.Parent = g2
		return f
	end
	local function line(x1, y1, x2, y2, color, thick)
		local dx, dy = (x2 - x1), (y2 - y1)
		local th = math.max(thick or 2, 1)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
		f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + th, th)
		f.Rotation = math.deg(math.atan2(dy, dx))
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.ZIndex = ZI
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.5, 0) c.Parent = f
		f.Parent = g2
		return f
	end
	if kind == "PART" then
		box(3, 3, 10, 10, m.blue, 3)
		box(5, 5, 6, 3, Color3.fromRGB(90, 170, 255), 2)
	elseif kind == "BASEPLATE" then
		box(1, 9, 14, 6, Color3.fromRGB(100, 104, 118), 2)
		box(1, 7, 14, 3, Color3.fromRGB(125, 130, 146), 2)
		box(5, 1, 5, 5, m.cyan, 3)
	elseif kind == "UNION" then
		box(1, 3, 10, 10, Color3.fromRGB(43, 203, 243), 7, 0.55)
		box(6, 3, 10, 10, Color3.fromRGB(240, 185, 70), 7, 0.55)
	elseif kind == "NEGATE" then
		box(1, 3, 10, 10, Color3.fromRGB(43, 203, 243), 7, 0.55)
		box(7, 4, 8, 8, Color3.fromRGB(255, 143, 117), 6, 0.15)
	elseif kind == "TOOLBOX" then
		box(1, 5, 14, 10, Color3.fromRGB(190, 140, 60), 3)
		box(5, 2, 6, 3, Color3.fromRGB(150, 108, 44), 3)
		box(1, 8, 14, 2, Color3.fromRGB(150, 108, 44), 1)
	end
	return g2
end

-- ---------- popup de shapes (anchored no botão; dentro do canvas escalado) ----------
local SHAPES = {
	{ "Block", "Block (4×2×4)" }, { "Ball", "Ball (esfera)" },
	{ "Cylinder", "Cylinder (roda)" }, { "CylinderVertical", "Cylinder vertical (pilar)" },
	{ "Wedge", "Wedge (rampa)" }, { "CornerWedge", "CornerWedge (canto)" },
	{ "Truss", "Truss (treliça)" },
}
local shapesPopup
local function closeShapes()
	if shapesPopup and shapesPopup.Parent then shapesPopup:Destroy() end
	shapesPopup = nil
end
local function camSpawnPos()
	local cam = workspace.CurrentCamera
	if cam then
		local cf = cam.CFrame
		local p = cf.Position + cf.LookVector * 16
		return math.floor(p.X + 0.5), math.max(math.floor(p.Y + 0.5), 3), math.floor(p.Z + 0.5)
	end
	return 0, 3, -16
end
local function openShapes(hostBtn)
	closeShapes()
	if not popups then return end
	local scale = (uiscale and uiscale.Scale) or 1
	if scale <= 0 then scale = 1 end
	local ap, asz = hostBtn.AbsolutePosition, hostBtn.AbsoluteSize
	local f = Instance.new("Frame")
	f.Name = "ArkherShapesPopup"
	f.Size = UDim2.fromOffset(230, #SHAPES * 28 + 12)
	f.Position = UDim2.fromOffset(ap.X / scale, (ap.Y + asz.Y) / scale + 4)
	f.BackgroundColor3 = m.panel
	f.BorderSizePixel = 0
	f.ZIndex = 60
	f.Active = true
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = f
	local st = Instance.new("UIStroke") st.Thickness = 1.5 st.Color = m.border st.Parent = f
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
		row.ZIndex = 61
		row.BorderSizePixel = 0
		local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0, 6) rc.Parent = row
		row.MouseEnter:Connect(function() row.BackgroundColor3 = m.selected end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = m.panel end)
		onTap(row, function()
			closeShapes()
			task.spawn(function()
				local x2, y2, z2 = camSpawnPos()
				local res, err = apiResult("QuickPart", { shape = spec[1], x = x2, y = y2, z = z2 })
				if res and res.msg then W("Message", { text = res.msg })
				elseif err then W("Message", { text = "Spawn falhou: " .. tostring(err), bad = true })
				else W("Message", { text = spec[1] .. " criado na frente da câmera." }) end
			end)
		end)
		row.Parent = f
	end
	local UIS = game:GetService("UserInputService")
	local conn
	conn = UIS.InputBegan:Connect(function(inp, gp)
		if gp or not f.Parent then if conn then conn:Disconnect() end return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = Vector2.new(inp.Position.X, inp.Position.Y)
			local fp, fs = f.AbsolutePosition, f.AbsoluteSize
			if fp.X > 0 and not (mp.X >= fp.X and mp.Y >= fp.Y and mp.X <= fp.X + fs.X and mp.Y <= fp.Y + fs.Y) then
				closeShapes()
				if conn then conn:Disconnect() conn = nil end
			end
		end
	end)
	shapesPopup = f
	f.Parent = popups
end

-- ---------- injeção dos botões X no Ribbon ----------
local injected = {}
local function injectButton(nm, caption, kind, onClick, order)
	if injected[nm] then return end
	local b = template:Clone()
	b.Name = nm
	-- texto: procura um TextLabel de caption no molde; senão usa o próprio Text
	local hadCaption = false
	for _, d in ipairs(b:GetDescendants()) do
		if d:IsA("TextLabel") and d.Name:lower():find("cap") then
			d.Text = caption
			hadCaption = true
		end
	end
	if not hadCaption then
		b.Text = caption
		b.TextSize = math.max(math.min(b.TextSize, 11), 9)
	end
	for _, d in ipairs(b:GetDescendants()) do
		if d:IsA("TextLabel") and d.Name:lower():find("cap") == nil and #d.Text <= 2 then
			d.Text = ""
		end
	end
	pcall(function() b.LayoutOrder = 900 + (order or 0) end)
	b.Visible = true
	drawIcon16(kind, b)
	onTap(b, onClick)
	b.Parent = template.Parent
	-- se o contêiner não tiver layout automático, posiciona depois do último filho
	task.defer(function()
		local row = b.Parent
		if not row then return end
		local auto = false
		for _, c in ipairs(row:GetChildren()) do
			if c:IsA("UIListLayout") or c:IsA("UIGridLayout") or c:IsA("UIPageLayout") or c:IsA("UITableLayout") then
				auto = true
				break
			end
		end
		if not auto then
			local right = -1e9
			for _, c in ipairs(row:GetChildren()) do
				if c:IsA("GuiObject") and c ~= b then
					local rx = c.Position.X.Offset + c.Size.X.Offset
					if rx > right then right = rx end
				end
			end
			if right > -1e9 then
				b.Position = UDim2.new(
					template.Position.X.Scale,
					right + 6,
					template.Position.Y.Scale,
					template.Position.Y.Offset
				)
			end
		end
	end)
	b.Parent = template.Parent
	injected[nm] = b
	return b
end

injectButton("ArkherX_Part", "Part ▸", "PART", function() openShapes(injected.ArkherX_Part) end, 1)
injectButton("ArkherX_Base", "Baseplate", "BASEPLATE", function()
	task.spawn(function()
		local res, err = apiResult("EnsureBase", {})
		if res and res.msg then W("Message", { text = res.msg })
		elseif err then W("Message", { text = "Baseplate falhou: " .. tostring(err), bad = true }) end
	end)
end, 2)
injectButton("ArkherX_Union", "Union", "UNION", function()
	task.spawn(function()
		local res, err = apiResult("CsgDo", { op = "union" })
		if res and res.msg then W("Message", { text = res.msg })
		elseif res and res.error then W("Message", { text = tostring(res.error), bad = true })
		elseif err then W("Message", { text = tostring(err), bad = true }) end
	end)
end, 3)
injectButton("ArkherX_Negate", "Negate", "NEGATE", function()
	task.spawn(function()
		local res, err = apiResult("CsgDo", { op = "negate" })
		if res and res.msg then W("Message", { text = res.msg })
		elseif res and res.error then W("Message", { text = tostring(res.error), bad = true })
		elseif err then W("Message", { text = tostring(err), bad = true }) end
	end)
end, 4)
injectButton("ArkherX_Toolbox", "Toolbox", "TOOLBOX", function()
	local ok = pcall(function()
		local d = rawget(_G, "ArkherStudioDock")
		if d and d.toggle then return d.toggle("toolbox") end
		deckOpen("toolbox")
	end)
	if not ok then deckOpen("toolbox") end
end, 5)

W("Message", { text = "Ribbon X: botões Part ▸ / Baseplate / Union / Negate / Toolbox injetados DENTRO do ribbon original (estilo nativo). Menus da faixa (MUNDO/MODELAGEM/…) clicáveis de novo." })
print("[ArkherX] 09_RibbonX: 5 botões nativos injetados no Ribbon real — zero overlay, menus reais clicáveis")
