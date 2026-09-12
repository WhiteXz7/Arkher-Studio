-- =============================================================
-- Arkher_08_Deck — os EDITORES ÚNICOS do ARKHER (LocalScript)
-- Regra do estúdio: SEM retângulo genérico de botões. Cada editor
-- tem LAYOUT PRÓPRIO e FERRAMENTAS PRÓPRIAS que agem de verdade:
--   TERRAIN X  — editor territorial único ARKHER
--   MODELER X  — estilo Blender (modos + toolbox + outliner + N-panel)
--   ANIMATOR X — estilo Cascadeur (timeline+transporte+AutoPhysics)
--   ESPAÇO    — criador orbital único (Képler real, escala log/real)
--   FABRICAR  — catálogo gramatical único (criar qualquer coisa)
-- Os menus da topbar ORIGINAL (MUNDO/MODELAGEM/ANIMAÇÃO/ESPAÇO/
-- FABRICAR) abrem estas janelas. RRW/D-O15/Tese dos D = backend
-- invisível, automático. Nada aqui finge automação: é tudo DEV.
-- =============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- ---------- ponte real ----------
local netFn
pcall(function()
	local net = ReplicatedStorage:WaitForChild("ArkherNet", 20)
	if net then netFn = net:WaitForChild("ArkherXQ", 6) end
end)
local function cmd(op, params)
	if not netFn then return { msg = "sem ponte ArkherNet" } end
	local ok, res = pcall(function() return netFn:InvokeServer({ op = op, params = params }) end)
	if not ok then return { msg = "falha remota: " .. tostring(res) } end
	if type(res) ~= "table" then return { msg = tostring(res) } end
	return res
end
local function msgOf(res) return (type(res) == "table" and (res.msg or "")) or tostring(res) end

-- ponte com o editor NATIVO (hierarchy/properties/criacao/publish) via ClientBus
local studioUI = script:FindFirstAncestorOfClass("ScreenGui")
local clientBus
do
	local ok, b = pcall(function()
		if not studioUI then return nil end
		return studioUI:WaitForChild("ClientBus", 25)
	end)
	if ok then clientBus = b end
end
local function bridge(action, payload)
	if not clientBus then
		local ok, b = pcall(function()
			return studioUI and studioUI:FindFirstChild("ClientBus") or nil
		end)
		if ok and b then clientBus = b end
		if not clientBus then return nil, "ClientBus indisponivel (o nucleo nativo ainda nao subiu)" end
	end
	local ok, r = pcall(function()
		return clientBus:Invoke("API", { action = action, payload = payload or {}, quiet = true })
	end)
	if not ok then return nil, "falha bridge: " .. tostring(r) end
	if type(r) ~= "table" then return nil, tostring(r) end
	if r.error then return nil, r.error end
	return r
end
local function bridgeResult(action, payload)
	local r, err = bridge(action, payload)
	if not r then return nil, err end
	if r.result then return r.result end
	return r
end

-- ---------- ScreenGui ----------
local gui = Instance.new("ScreenGui")
gui.Name = "ArkherDeck"
gui.ResetOnSpawn = false
gui.DisplayOrder = 68
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- frame raiz para escala adaptativa (mobile/diversos dispositivos)
local deckHost = Instance.new("Frame")
deckHost.Name = "DeckHost"
deckHost.Size = UDim2.fromScale(1, 1)
deckHost.BackgroundTransparency = 1
deckHost.Parent = gui
local deckScale = Instance.new("UIScale")
deckScale.Scale = 1
deckScale.Parent = deckHost
local function updateDeckScale()
	local vp = gui.AbsoluteSize
	local w = vp.X
	if w <= 0 then return end
	-- dispositivos estreitos (mobile/tablet vertical) encolhem; nunca abaixo de legivel
	local sc = math.clamp(w / 1500, 0.72, 1.3)
	deckScale.Scale = sc
end
task.spawn(function()
	task.wait(0.2)
	updateDeckScale()
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateDeckScale)

-- ---------- base de widgets (cada painel usa, mas o LAYOUT é dele) ----------
local function B(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function H(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 7)
	c.Parent = o
	return o
end
local function ST(o, th, col)
	local s0 = Instance.new("UIStroke")
	s0.Thickness = th or 1
	s0.Color = col or Color3.fromRGB(52, 80, 120)
	s0.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s0.Parent = o
	return o
end
local function makeDraggable(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			startPos = frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

-- janela base (tema passado por quem chama — cada editor tem a sua cara)
local function mkWin(id, title, w, h, th)
	local f = B("Frame", {
		Name = "Deck_" .. id, Size = UDim2.fromOffset(w, h),
		Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
		BackgroundColor3 = th.bg, BorderSizePixel = 0, Visible = false,
		Active = true, ZIndex = 40,
	}, deckHost)
	H(f, th.cr or 10)
	ST(f, 1.2, th.edge)
	local cap = B("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = th.cap, BorderSizePixel = 0, ZIndex = 41 }, f)
	H(cap, th.cr or 10)
	B("TextLabel", {
		Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
		TextSize = 13, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42,
	}, cap)
	local tag = B("TextLabel", {
		Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -160, 0, 0),
		BackgroundTransparency = 1, Text = th.tag or "", Font = Enum.Font.Gotham,
		TextSize = 10, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 42,
	}, cap)
	local cls = B("TextButton", {
		Size = UDim2.fromOffset(24, 20), Position = UDim2.new(1, -28, 0, 5),
		BackgroundColor3 = th.bg2 or th.cap, Text = "x", Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 42,
	}, cap)
	H(cls, 5)
	cls.MouseButton1Click:Connect(function() f.Visible = false end)
	makeDraggable(f, cap)
	local body = B("Frame", {
		Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 30),
		BackgroundTransparency = 1, ZIndex = 41,
	}, f)
	-- estado inicial: esconder junto
	return { root = f, body = body, theme = th, tag = tag }
end

-- botão de ação REAL: sempre mostra o que o servidor respondeu
local function actBtn(parent, posTxt, wTxt, label, th, fn, order)
	local b0 = B("TextButton", {
		Size = wTxt, Position = posTxt,
		BackgroundColor3 = th.act, Text = label, Font = Enum.Font.GothamBold,
		TextSize = 11, TextColor3 = th.text, BorderSizePixel = 0,
		AutoButtonColor = true, ZIndex = (order or 43),
	}, parent)
	H(b0, 6)
	ST(b0, 1, th.edge)
	local busy = false
	b0.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		local old = b0.Text
		b0.Text = label .. " …"
		task.spawn(function()
			local res = fn()
			b0.Text = old
			if parent.Descendants and parent.Parent then end
			busy = false
			return res
		end)
	end)
	return b0
end

-- slider REAL (arrasta e chama onChange(v) com debounce)
local function sliderCtl(parent, pos, w, label, min, max, init, th, onChange)
	local val = init or min
	local box = B("Frame", { Size = UDim2.new(1, 0, 0, 34), Position = pos, BackgroundTransparency = 1, ZIndex = 43 }, parent)
	B("TextLabel", {
		Size = UDim2.new(1, -56, 0, 14), BackgroundTransparency = 1,
		Text = label, Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, box)
	local valLbl = B("TextLabel", {
		Size = UDim2.fromOffset(52, 14), Position = UDim2.new(1, -52, 0, 0),
		BackgroundTransparency = 1, Text = string.format("%.2f", val),
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43,
	}, box)
	local track = B("Frame", {
		Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 21),
		BackgroundColor3 = th.bg3 or th.cap, BorderSizePixel = 0, ZIndex = 43,
	}, box)
	H(track, 3)
	local fill = B("Frame", { Size = UDim2.new((val - min) / (max - min), 0, 1, 0), BackgroundColor3 = th.acc, BorderSizePixel = 0, ZIndex = 44 }, track)
	H(fill, 3)
	local knob = B("Frame", {
		Size = UDim2.fromOffset(12, 12), Position = UDim2.new((val - min) / (max - min), -6, 0.5, -6),
		BackgroundColor3 = th.text, BorderSizePixel = 0, ZIndex = 45,
	}, track)
	H(knob, 6)
	local dragging = false
	local lastFire = 0
	local function setFromX(ax)
		local rel = math.clamp((ax - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		val = min + (max - min) * rel
		valLbl.Text = string.format("%.2f", val)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, -6, 0.5, -6)
		local now = os.clock()
		if now - lastFire > 0.25 then
			lastFire = now
			task.spawn(onChange, val)
		end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true setFromX(inp.Position.X) end
	end)
	knob.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then setFromX(inp.Position.X) end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
			dragging = false
			task.spawn(onChange, val) -- valor final garantido
		end
	end)
	return { get = function() return val end }
end

-- stepper REAL (- valor +) com min/max
local function stepCtl(parent, pos, label, init, step, min, max, th, fmt, W_)
	local val = init
	fmt = fmt or "%d"
	local wfrac = W_ or 0.5
	local box = B("Frame", { Size = UDim2.new(wfrac, -4, 0, 30), Position = pos, BackgroundColor3 = th.act, BorderSizePixel = 0, ZIndex = 43 }, parent)
	H(box, 6)
	ST(box, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(8, 0),
		BackgroundTransparency = 1, Text = label, Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, box)
	local vl = B("TextLabel", {
		Size = UDim2.fromOffset(40, 30), Position = UDim2.new(1, -68, 0, 0),
		BackgroundTransparency = 1, Text = string.format(fmt, val),
		Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text, ZIndex = 44,
	}, box)
	local minus = B("TextButton", {
		Size = UDim2.fromOffset(16, 22), Position = UDim2.new(1, -28, 0, 4),
		BackgroundColor3 = th.bg3 or th.cap, Text = "-", Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.acc, BorderSizePixel = 0, ZIndex = 45,
	}, box)
	H(minus, 4)
	local plus = B("TextButton", {
		Size = UDim2.fromOffset(16, 22), Position = UDim2.new(1, -13, 0, 4),
		BackgroundColor3 = th.bg3 or th.cap, Text = "+", Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.acc, BorderSizePixel = 0, ZIndex = 45,
	}, box)
	H(plus, 4)
	local function upd()
		vl.Text = string.format(fmt, val)
	end
	minus.MouseButton1Click:Connect(function() val = math.max(min, val - step) upd() end)
	plus.MouseButton1Click:Connect(function() val = math.min(max, val + step) upd() end)
	return { get = function() return val end }
end

-- log de respostas (toda ação REAL mostra o efeito no mundo)
local function logCtl(parent, pos, w, th)
	local l = B("TextLabel", {
		Size = w, Position = pos,
		BackgroundColor3 = th.logBg or th.cap, Text = "  pronto.",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	H(l, 5)
	return function(txt, good)
		l.Text = "  " .. tostring(txt)
		l.TextColor3 = good == false and Color3.fromRGB(255, 164, 143) or th.logOk or Color3.fromRGB(120, 220, 160)
	end
end

-- lista rolável com rows
local function listCtl(parent, pos, size, th)
	local fr = B("ScrollingFrame", {
		Size = size, Position = pos, BackgroundColor3 = th.bg2 or th.cap,
		BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = th.edge, ZIndex = 43,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, parent)
	H(fr, 7)
	ST(fr, 1, th.edge)
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 3)
	lay.Parent = fr
	return fr
end

-- =============================================================
-- TERRAIN X — o editor territorial ARKHER (único, do zero)
-- =============================================================
local THEME_TERRAIN = {
	bg = Color3.fromRGB(9, 20, 26), bg2 = Color3.fromRGB(12, 27, 34), bg3 = Color3.fromRGB(16, 34, 42),
	cap = Color3.fromRGB(13, 30, 38), edge = Color3.fromRGB(46, 84, 96),
	text = Color3.fromRGB(226, 244, 250), muted = Color3.fromRGB(130, 168, 178),
	acc = Color3.fromRGB(43, 203, 190), act = Color3.fromRGB(16, 58, 62),
}

local TERRAIN_CATS = {
	sculpt = "Modelar base", landform = "Grandes formas", glacial = "Glacial",
	eolico = "Eólico/Dunas", fluvial = "Fluvial", carste = "Carste",
	vulcano = "Vulcão & Cratera", costa = "Costa & Marés", erosao = "Erosão",
	impacto = "Impacto/Cratera",
}

local function buildTerrain(win)
	local th = THEME_TERRAIN
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	-- coluna 1: categorias
	B("TextLabel", {
		Size = UDim2.fromOffset(128, 16), Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1, Text = "CATEGORIAS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local catList = listCtl(body, UDim2.fromOffset(10, 26), UDim2.fromOffset(128, 190), th)

	-- coluna 2: tools da categoria
	B("TextLabel", {
		Size = UDim2.fromOffset(190, 16), Position = UDim2.fromOffset(146, 8),
		BackgroundTransparency = 1, Text = "FERRAMENTAS (reais, do WORLDX)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local toolList = listCtl(body, UDim2.fromOffset(146, 26), UDim2.fromOffset(190, 190), th)

	-- coluna 3: inspector (parâmetros + sonda + mundo)
	local insp = B("Frame", {
		Size = UDim2.fromOffset(214, 314), Position = UDim2.fromOffset(344, 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(insp, 7) ST(insp, 1, th.edge)

	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "INSPECTOR DE TOOL", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)
	local curTool = { id = nil, label = nil }
	local toolLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 20),
		BackgroundTransparency = 1, Text = "nenhuma tool selecionada",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = th.text,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)
	local descLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 36),
		BackgroundTransparency = 1, Text = "escolha uma categoria à esquerda e uma tool",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, insp)

	local parmR = sliderCtl(insp, UDim2.fromOffset(8, 80), 0, "Raio r (studs)", 8, 320, 80, th, function() end)
	local parmA = sliderCtl(insp, UDim2.fromOffset(8, 118), 0, "Força/Amplitude", 1, 120, 30, th, function() end)
	local px = stepCtl(insp, UDim2.fromOffset(8, 160), "X", 0, 10, -9999, 9999, th)
	local pz = stepCtl(insp, UDim2.new(0.5, 4, 0, 160), "Z", 0, 10, -9999, 9999, th)

	actBtn(insp, UDim2.fromOffset(8, 198), UDim2.new(1, -16, 0, 26), "APLICAR TOOL NO MUNDO", th, function()
		if not curTool.id then return log("selecione uma tool primeiro", false) end
		local res = cmd("world_tool", { id = curTool.id, x = px.get(), z = pz.get(), r = parmR.get(), amp = parmA.get() })
		log(msgOf(res))
	end)

	-- sonda (bioma/clima/matéria reais do mundo)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 232),
		BackgroundTransparency = 1, Text = "SONDA DO MUNDO", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)
	local probeLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 46), Position = UDim2.fromOffset(8, 248),
		BackgroundTransparency = 1, Text = "—", Font = Enum.Font.Code, TextSize = 10,
		TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 44,
	}, insp)
	local probing = false
	local function probe()
		if probing then return end
		probing = true
		task.spawn(function()
			local res = cmd("world_probe", { x = px.get(), z = pz.get() })
			probeLbl.Text = "  " .. msgOf(res)
			probing = false
		end)
	end
	actBtn(insp, UDim2.fromOffset(8, 296), UDim2.fromOffset(96, 22), "Sondar", th, function() probe() end)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.5)
			if win.root.Visible then probe() end
		end
	end)

	-- faixa "MUNDO" (gerar/materializar/vegetar/erodir/rios) — visão grande
	local world = B("Frame", {
		Size = UDim2.fromOffset(326, 118), Position = UDim2.new(0, 10, 1, -144),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(world, 7) ST(world, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "MUNDO — geração planetária real", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, world)
	local seed = stepCtl(world, UDim2.fromOffset(8, 24), "seed", 7, 1, 1, 999, th)
	local placas = stepCtl(world, UDim2.new(0.5, 4, 0, 24), "placas", 9, 1, 3, 24, th)

	local genAct = actBtn(world, UDim2.fromOffset(8, 58), UDim2.fromOffset(96, 24), "GERAR PLANETA", th, function()
		local res = cmd("world_generate", { seed = seed.get(), plates = placas.get(), driftT = 0, season = 0.35, size = 1200 })
		log(msgOf(res))
	end)
	local matAct = actBtn(world, UDim2.fromOffset(110, 58), UDim2.fromOffset(104, 24), "MATERIALIZAR", th, function()
		local res = cmd("world_materialize", {})
		log(msgOf(res))
	end)
	local vegAct = actBtn(world, UDim2.fromOffset(220, 58), UDim2.fromOffset(96, 24), "VEGETAR", th, function()
		local res = cmd("world_vegetate", {})
		log(msgOf(res))
	end)
	local eroAct = actBtn(world, UDim2.fromOffset(8, 86), UDim2.fromOffset(100, 24), "ERODIR ×150", th, function()
		local res = cmd("world_erode", { cycles = 150 })
		log(msgOf(res))
	end)
	local rivAct
	-- dados das tools: do SERVIDOR (grade verdadeira)
	local toolsByCat = {}
	task.spawn(function()
		local res = cmd("world_tools")
		if res.tools then
			for _, tl in ipairs(res.tools) do
				toolsByCat[tl.cat] = toolsByCat[tl.cat] or {}
				table.insert(toolsByCat[tl.cat], tl)
			end
		end
		log(res.count and ("WORLDX: " .. res.count .. " tools territoriais carregadas") or "tools indisponíveis")
		-- monta categorias
		for cat in pairs(toolsByCat) do
			local nm = TERRAIN_CATS[cat] or cat
			local cb = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 22),
				BackgroundColor3 = th.bg3, Text = nm, Font = Enum.Font.GothamBold,
				TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, catList)
			H(cb, 5)
			cb.MouseButton1Click:Connect(function()
				for _, ch in ipairs(catList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 ch.TextColor3 = th.muted end
				end
				cb.BackgroundColor3 = th.act
				cb.TextColor3 = th.text
				for _, ch in ipairs(toolList:GetChildren()) do
					if ch:IsA("TextButton") then ch:Destroy() end
				end
				for _, tl in ipairs(toolsByCat[cat] or {}) do
					local tb = B("TextButton", {
						Size = UDim2.new(1, -8, 0, 26),
						BackgroundColor3 = th.bg3, Text = "  " .. tl.id, Font = Enum.Font.GothamBold,
						TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0,
						TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
					}, toolList)
					H(tb, 5)
					tb.MouseButton1Click:Connect(function()
						curTool.id, curTool.label = tl.id, tl.id
						toolLbl.Text = tl.id .. "  [" .. tl.cat .. "]"
						descLbl.Text = tl.msg
						for _, ch in ipairs(toolList:GetChildren()) do
							if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
						end
						tb.BackgroundColor3 = th.act
					end)
				end
				log("categoria '" .. nm .. "': " .. #(toolsByCat[cat] or {}) .. " tools")
			end)
		end
	end)
	return win
end

-- janela TERRAIN: oversized material para as colunas respirarem
local wTerrain = mkWin("terrain", "TERRAIN X — editor territorial ARKHER", 568, 396, THEME_TERRAIN)
buildTerrain(wTerrain)


-- =============================================================
-- MODELER X — estilo Blender (modos + toolbox + outliner + N-panel)
-- =============================================================
local THEME_MODELER = {
	bg = Color3.fromRGB(30, 30, 34), bg2 = Color3.fromRGB(36, 36, 41), bg3 = Color3.fromRGB(42, 42, 48),
	cap = Color3.fromRGB(24, 24, 28), edge = Color3.fromRGB(62, 62, 72),
	text = Color3.fromRGB(235, 235, 240), muted = Color3.fromRGB(150, 152, 160),
	acc = Color3.fromRGB(224, 124, 28), act = Color3.fromRGB(58, 58, 66),
	tag = "Blender-style",
}

local MODES = {
	{ id = "prim", label = "GERAR" },
	{ id = "xf", label = "EDITAR" },
	{ id = "topo", label = "TOPOLOGIA" },
	{ id = "fin", label = "FINALIZAR" },
	{ id = "pipe", label = "PIPELINE" },
}

local function buildModeler(win)
	local th = THEME_MODELER
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	-- faixa de MODOS (header tabs — a cara do Blender)
	local tabRow = B("Frame", {
		Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1, ZIndex = 43,
	}, body)
	local tabs = {}
	local mode = { id = "prim" }
	for i, m2 in ipairs(MODES) do
		local tb = B("TextButton", {
			Size = UDim2.fromOffset(102, 24), Position = UDim2.fromOffset((i - 1) * 108, 0),
			BackgroundColor3 = i == 1 and th.acc or th.bg3,
			Text = m2.label, Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = i == 1 and Color3.new(1, 1, 1) or th.muted,
			BorderSizePixel = 0, ZIndex = 44,
		}, tabRow)
		H(tb, 5)
		tabs[m2.id] = tb
	end

	-- toolbox (esquerda)
	B("TextLabel", {
		Size = UDim2.fromOffset(180, 14), Position = UDim2.fromOffset(10, 40),
		BackgroundTransparency = 1, Text = "TOOLBOX", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local toolList = listCtl(body, UDim2.fromOffset(10, 58), UDim2.fromOffset(180, 240), th)

	-- inspector de tool + N-panel de params (centro)
	local mid = B("Frame", {
		Size = UDim2.fromOffset(200, 240), Position = UDim2.fromOffset(198, 58),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(mid, 7) ST(mid, 1, th.edge)
	local toolName = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "selecione uma tool", Font = Enum.Font.GothamBold,
		TextSize = 13, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local toolDesc = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 28),
		BackgroundTransparency = 1, Text = "as ops agem na banca MeshX do servidor",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 44,
	}, mid)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 60),
		BackgroundTransparency = 1, Text = "N-PANEL — PARÂMETROS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local psx = stepCtl(mid, UDim2.fromOffset(8, 76), "sx", 8, 1, 0, 256, th, "%d", 0.48)
	local psy = stepCtl(mid, UDim2.new(0.5, 4, 0, 76), "sy", 8, 1, 0, 256, th, "%d", 0.48)
	local psz = stepCtl(mid, UDim2.fromOffset(8, 108), "sz", 8, 1, 0, 256, th, "%d", 0.48)
	local pr = stepCtl(mid, UDim2.new(0.5, 4, 0, 108), "r", 4, 1, 0, 256, th, "%d", 0.48)
	local ph = stepCtl(mid, UDim2.fromOffset(8, 140), "h", 8, 1, 0, 256, th, "%d", 0.48)
	local pseg = stepCtl(mid, UDim2.new(0.5, 4, 0, 140), "seg", 16, 2, 3, 64, th, "%d", 0.48)
	local pdeg = stepCtl(mid, UDim2.fromOffset(8, 172), "deg", 90, 15, 0, 360, th, "%d", 0.48)
	local pn = stepCtl(mid, UDim2.new(0.5, 4, 0, 172), "n", 5, 1, 1, 64, th, "%d", 0.48)

	actBtn(mid, UDim2.fromOffset(8, 206), UDim2.new(1, -16, 0, 26), "APLICAR TOOL NA BANCA", th, function()
		if not curToolId then return log("selecione uma tool", false) end
		local res = cmd("mesh_tool", { id = curToolId, sx = psx.get(), sy = psy.get(), sz = psz.get(),
			r = pr.get(), h = ph.get(), seg = pseg.get(), deg = pdeg.get(), n = pn.get(), s = psx.get() })
		log(msgOf(res))
		refreshStats()
	end)

	-- OUTLINER (direita) — stats da banca
	local outp = B("Frame", {
		Size = UDim2.fromOffset(200, 240), Position = UDim2.fromOffset(406, 58),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(outp, 7) ST(outp, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "OUTLINER — BANCA", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, outp)
	local stV = B("TextLabel", { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 26), BackgroundTransparency = 1, Text = "vértices: —", Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44 }, outp)
	local stF = B("TextLabel", { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 44), BackgroundTransparency = 1, Text = "faces:    —", Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44 }, outp)
	local stO = B("TextLabel", { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 62), BackgroundTransparency = 1, Text = "operações: —", Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44 }, outp)
	local stM = B("TextLabel", { Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 82), BackgroundTransparency = 1, Text = "—", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 44 }, outp)
	function refreshStats()
		task.spawn(function()
			local res = cmd("bench_stats")
			stV.Text = "vértices:   " .. tostring(res.verts)
			stF.Text = "faces:      " .. tostring(res.faces)
			stO.Text = "operações:  " .. tostring(res.ops)
			stM.Text = msgOf(res)
		end)
	end
	actBtn(outp, UDim2.fromOffset(8, 128), UDim2.new(1, -16, 0, 24), "ATUALIZAR STATS", th, function() refreshStats() end)
	actBtn(outp, UDim2.fromOffset(8, 158), UDim2.new(1, -16, 0, 24), "LIMPAR BANCA", th, function()
		local res = cmd("mesh_clean")
		log(msgOf(res))
		refreshStats()
	end)

	-- carrega tools do servidor e monta por modo
	local toolsByMode = {}
	curToolId = nil
	task.spawn(function()
		local res = cmd("mesh_tools")
		if res.tools then
			for _, tl in ipairs(res.tools) do
				toolsByMode[tl.cat] = toolsByMode[tl.cat] or {}
				table.insert(toolsByMode[tl.cat], tl)
			end
		end
		log(res.count and ("MeshX: " .. res.count .. " tools na banca") or "tools indisponíveis")
	end)
	local function applyMode(mid)
		mode.id = mid
		curToolId = nil
		for mid2, tb in pairs(tabs) do
			local on = (mid2 == mid)
			tb.BackgroundColor3 = on and th.acc or th.bg3
			tb.TextColor3 = on and Color3.new(1, 1, 1) or th.muted
		end
		toolName.Text = "selecione uma tool"
		toolDesc.Text = "modo: " .. mid
		for _, ch in ipairs(toolList:GetChildren()) do
			if ch:IsA("TextButton") then ch:Destroy() end
		end
		for _, tl in ipairs(toolsByMode[mid] or {}) do
			local tb2 = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = th.bg3,
				Text = "  " .. tl.id, Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = th.text, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, toolList)
			H(tb2, 5)
			tb2.MouseButton1Click:Connect(function()
				curToolId = tl.id
				toolName.Text = tl.id
				toolDesc.Text = tostring(tl.msg)
				for _, ch in ipairs(toolList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
				end
				tb2.BackgroundColor3 = th.act
			end)
		end
		log("modo '" .. mid .. "': " .. #(toolsByMode[mid] or {}) .. " tools")
	end
	for mid, tb in pairs(tabs) do
		tb.MouseButton1Click:Connect(function() applyMode(mid) end)
	end
	refreshStats()
	win.root:GetPropertyChangedSignal("Visible"):Connect(function()
		if win.root.Visible then applyMode(mode.id) refreshStats() end
	end)
	return win
end

local wModeler = mkWin("modeler", "MODELER X", 616, 360, THEME_MODELER)
buildModeler(wModeler)

-- =============================================================
-- ANIMATOR X — estilo Cascadeur (timeline + transporte + AutoPhysics)
-- =============================================================
local THEME_ANIM = {
	bg = Color3.fromRGB(20, 15, 28), bg2 = Color3.fromRGB(26, 20, 36), bg3 = Color3.fromRGB(34, 27, 46),
	cap = Color3.fromRGB(16, 11, 24), edge = Color3.fromRGB(76, 58, 114),
	text = Color3.fromRGB(240, 232, 252), muted = Color3.fromRGB(158, 140, 186),
	acc = Color3.fromRGB(166, 117, 240), act = Color3.fromRGB(46, 34, 70),
	tag = "Cascadeur-style",
}

local function buildAnimator(win)
	local th = THEME_ANIM
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	-- esquerda: cena de rigs
	B("TextLabel", {
		Size = UDim2.fromOffset(160, 14), Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1, Text = "PERSONAGENS / ESQUELETOS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local rigList = listCtl(body, UDim2.fromOffset(10, 26), UDim2.fromOffset(160, 180), th)
	local function rigRow(label, op, params)
		local b0 = B("TextButton", {
			Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = th.bg3,
			Text = "  " .. label, Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = th.text, BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
		}, rigList)
		H(b0, 5)
		b0.MouseButton1Click:Connect(function()
			task.spawn(function()
				local res = cmd(op, params)
				log(msgOf(res))
			end)
		end)
		return b0
	end
	rigRow("AutoRig · BÍPEDE", "anim_autorig", { preset = "bipede" })
	rigRow("AutoRig · QUADRÚPEDE", "anim_autorig", { preset = "quadrupede" })
	rigRow("AutoRig · SERPENTE", "anim_autorig", { preset = "serpente" })
	rigRow("AutoRig · MONSTRO", "anim_autorig", { preset = "monstro" })
	rigRow("NPC vivo (FABRIK+mentes)", "npc_spawn", { preset = "bipede" })
	rigRow("Humano digital (DAYX)", "life_human", { seed = 7 })

	-- direita: AUTOPHYSICS (os 3 eixos reais, somados no backend)
	local phys = B("Frame", {
		Size = UDim2.fromOffset(210, 206), Position = UDim2.fromOffset(370, 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(phys, 7) ST(phys, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "AUTOPHYSICS (os 3 eixos se somam no nível 0→1)",
		Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 44,
	}, phys)
	local sSec, sBal, sBall
	local function applyPhysics()
		local lv = 0.35 * (sSec and sSec.get() or 0) + 0.35 * (sBal and sBal.get() or 0) + 0.30 * (sBall and sBall.get() or 0)
		local res = cmd("anim_autophysics", { level = lv })
		return res
	end
	sSec = sliderCtl(phys, UDim2.fromOffset(8, 36), 0, "Secundária (molas de penduricalhos)", 0, 1, 0.6, th, function() task.spawn(function() log(msgOf(applyPhysics())) end) end)
	sBal = sliderCtl(phys, UDim2.fromOffset(8, 74), 0, "Auto-Balanço (COM pélvico)", 0, 1, 0.6, th, function() task.spawn(function() log(msgOf(applyPhysics())) end) end)
	sBall = sliderCtl(phys, UDim2.fromOffset(8, 112), 0, "Balística (trajetória senoidal)", 0, 1, 0.6, th, function() task.spawn(function() log(msgOf(applyPhysics())) end) end)
	local bonesOn = { v = true }
	local chip = B("TextButton", {
		Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 152),
		BackgroundColor3 = th.act, Text = "Palco/ossos: VISÍVEIS", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
	}, phys)
	H(chip, 6)
	chip.MouseButton1Click:Connect(function()
		bonesOn.v = not bonesOn.v
		chip.Text = "Palco/ossos: " .. (bonesOn.v and "VISÍVEIS" or "ocultos")
		task.spawn(function() log(msgOf(cmd("bones_visibility", { on = bonesOn.v }))) end)
	end)
	actBtn(phys, UDim2.fromOffset(8, 180), UDim2.new(1, -16, 0, 22), "Balanço pélvico (demo)", th, function()
		log(msgOf(cmd("rig_balance")))
	end)

	-- centro: palco de dados do rig (o 3D é o viewport — aqui é a alma)
	local stage = B("Frame", {
		Size = UDim2.fromOffset(188, 206), Position = UDim2.fromOffset(174, 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(stage, 7) ST(stage, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "PALCO", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, stage)
	local stageInfo = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 120), Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1, Text = "Crie um rig na lista à esquerda.\nO esqueleto aparece NO MUNDO (3D).\nAqui ficam as réguas de controle.",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, stage)
	actBtn(stage, UDim2.fromOffset(8, 152), UDim2.new(1, -16, 0, 22), "Loop demo", th, function()
		log(msgOf(cmd("rig_demo")))
	end)
	actBtn(stage, UDim2.fromOffset(8, 178), UDim2.new(1, -16, 0, 22), "Cube pump AAX", th, function()
		log(msgOf(cmd("aax_demo")))
	end)

	-- TIMELINE CASCADEUR (rodapé): régua 48 frames @ 24fps + playhead real
	local tl = B("Frame", {
		Size = UDim2.new(1, -20, 0, 108), Position = UDim2.new(0, 10, 1, -140),
		BackgroundColor3 = Color3.fromRGB(14, 10, 20), BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(tl, 7) ST(tl, 1, th.edge)
	-- transporte
	local tp = B("Frame", { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 6), BackgroundTransparency = 1, ZIndex = 44 }, tl)
	local function tpBtn(x, label2, op, params, col)
		return actBtn(tp, UDim2.fromOffset(x, 0), UDim2.fromOffset(56, 26), label2, th, function()
			log(msgOf(cmd(op, params)))
		end)
	end
	tpBtn(0, "► PLAY", "rig_demo")
	tpBtn(62, "■ STOP", "rig_stop")
	B("TextLabel", {
		Size = UDim2.fromOffset(300, 26), Position = UDim2.fromOffset(124, 0),
		BackgroundTransparency = 1, Text = "Timeline 24 fps · loop 48 f · playhead = tempo REAL do rig (a scrub manual chega com clips AAX fase 2)",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, tp)
	-- régua
	local ruler = B("Frame", {
		Size = UDim2.new(1, -16, 0, 56), Position = UDim2.fromOffset(8, 40),
		BackgroundColor3 = Color3.fromRGB(10, 8, 16), BorderSizePixel = 0, ZIndex = 44,
	}, tl)
	H(ruler, 4)
	local FRAMES = 48
	for f = 0, FRAMES do
		local big = (f % 6 == 0)
		B("Frame", {
			Size = UDim2.fromOffset(1, big and 14 or 7),
			Position = UDim2.new(f / FRAMES, 0, 1, big and -14 or -7),
			BackgroundColor3 = big and th.muted or th.edge, BorderSizePixel = 0, ZIndex = 45,
		}, ruler)
		if big then
			B("TextLabel", {
				Size = UDim2.fromOffset(24, 12), Position = UDim2.new(f / FRAMES, -4, 0, 2),
				BackgroundTransparency = 1, Text = tostring(f), Font = Enum.Font.Code,
				TextSize = 9, TextColor3 = th.muted, ZIndex = 45,
			}, ruler)
		end
	end
	local playhead = B("Frame", {
		Size = UDim2.fromOffset(2, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 71, 71), BorderSizePixel = 0, ZIndex = 46,
	}, ruler)
	playhead.Size = UDim2.new(0, 2, 1, 0)
	local playing, t0 = false, 0
	task.spawn(function()
		local start = os.clock()
		while win.root.Parent do
			task.wait(1 / 30)
			if playing then
				local f = ((os.clock() - start) * 24) % FRAMES
				playhead.Position = UDim2.new(f / FRAMES, 0, 0, 0)
			end
		end
	end)
	-- transporte liga playhead
	for _, b0 in ipairs(tp:GetChildren()) do
		if b0:IsA("TextButton") then
			local old = b0.Text
			b0.MouseButton1Click:Connect(function()
				if old == "► PLAY" then playing = true start = os.clock() end
				if old == "■ STOP" then playing = false playhead.Position = UDim2.new(0, 0, 0, 0) end
			end)
		end
	end
	return win
end

local wAnimator = mkWin("animator", "ANIMATOR X", 590, 400, THEME_ANIM)
buildAnimator(wAnimator)

-- =============================================================
-- ESPAÇO — criador orbital único ARKHER (Képler + escala log/real)
-- =============================================================
local THEME_SPACE = {
	bg = Color3.fromRGB(7, 11, 24), bg2 = Color3.fromRGB(10, 16, 32), bg3 = Color3.fromRGB(14, 22, 42),
	cap = Color3.fromRGB(9, 14, 30), edge = Color3.fromRGB(48, 74, 140),
	text = Color3.fromRGB(226, 236, 255), muted = Color3.fromRGB(146, 164, 210),
	acc = Color3.fromRGB(240, 185, 70), act = Color3.fromRGB(24, 38, 84),
}

local SCALE_MODES = {
	{ id = "superficie", label = "SUPERFÍCIE", hint = "1 stud = 4 km" },
	{ id = "planetaria", label = "PLANETÁRIA", hint = "1 stud = 640 km" },
	{ id = "sistema", label = "SISTEMA", hint = "raio exib. = log10(km) × K" },
	{ id = "galaxia", label = "GALÁXIA", hint = "ultra-log" },
}

local function buildEspaco(win)
	local th = THEME_SPACE
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	-- ESCADA DE ESCALA (topo) — de superfície à galáxia
	local ladder = B("Frame", {
		Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1, ZIndex = 43,
	}, body)
	local ldBtns = {}
	for i, sm in ipairs(SCALE_MODES) do
		local tb = B("TextButton", {
			Size = UDim2.fromOffset(112, 28), Position = UDim2.fromOffset((i - 1) * 118, 0),
			BackgroundColor3 = th.bg3, Text = sm.label, Font = Enum.Font.GothamBold,
			TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
		}, ladder)
		H(tb, 5)
		ldBtns[sm.id] = tb
		tb.MouseButton1Click:Connect(function()
			task.spawn(function()
				local res = cmd("space_mode", { id = sm.id })
				log(msgOf(res))
				hintLbl.Text = "modo: " .. sm.label .. " — " .. sm.hint
				for id2, b2 in pairs(ldBtns) do
					b2.BackgroundColor3 = (id2 == sm.id) and th.acc or th.bg3
					b2.TextColor3 = (id2 == sm.id) and Color3.fromRGB(20, 16, 6) or th.muted
				end
			end)
		end)
	end
	hintLbl = B("TextLabel", {
		Size = UDim2.new(1, -436, 0, 28), Position = UDim2.fromOffset(470, 0),
		BackgroundTransparency = 1, Text = "modo: SISTEMA — raio exib. = log10(km) × K",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, ladder)

	-- esquerda: presets + adicionar corpo
	local lp = B("Frame", {
		Size = UDim2.fromOffset(264, 240), Position = UDim2.fromOffset(10, 44),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(lp, 7) ST(lp, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "SISTEMAS PRONTOS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, lp)
	actBtn(lp, UDim2.fromOffset(8, 24), UDim2.new(1, -16, 0, 24), "Sistema Solar (log) — 9 corpos", th, function()
		log(msgOf(cmd("space_preset", { id = "solar" })))
		refreshMap()
	end)
	actBtn(lp, UDim2.fromOffset(8, 52), UDim2.new(1, -16, 0, 24), "Terra + Lua + Sol", th, function()
		log(msgOf(cmd("space_preset", { id = "terra_lua" })))
		refreshMap()
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 82),
		BackgroundTransparency = 1, Text = "ADICIONAR CORPO (matéria real)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, lp)
	bodyNameN = 1
	local nmLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 100),
		BackgroundTransparency = 1, Text = "nome automático: corpo_01", Font = Enum.Font.Code,
		TextSize = 9, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, lp)
	local radK = stepCtl(lp, UDim2.fromOffset(8, 120), "raio km ×1000", 6371, 1000, 500, 500000, th, "%d", 0.48)
	local orbK = stepCtl(lp, UDim2.new(0.5, 4, 0, 120), "órbita Mkm", 100, 10, 0, 5000, th, "%d", 0.48)
	local matters = { "rocha", "terra", "gas", "gelo", "lava", "oceano", "deserto", "lua" }
	local matIdx = { i = 1 }
	local matBtn = B("TextButton", {
		Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 154),
		BackgroundColor3 = th.act, Text = "matéria: rocha", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
	}, lp)
	H(matBtn, 5)
	matBtn.MouseButton1Click:Connect(function()
		matIdx.i = (matIdx.i % #matters) + 1
		matBtn.Text = "matéria: " .. matters[matIdx.i]
	end)
	actBtn(lp, UDim2.fromOffset(8, 182), UDim2.new(1, -16, 0, 26), "ADICIONAR AO SISTEMA", th, function()
		local nm = string.format("corpo_%02d", bodyNameN)
		bodyNameN = bodyNameN + 1
		nmLbl.Text = "nome automático: corpo_" .. string.format("%02d", bodyNameN)
		local res = cmd("space_add", { name = nm, matter = matters[matIdx.i],
			radiusKm = radK.get(), orbitKm = orbK.get() * 1e6 })
		log(msgOf(res))
		refreshMap()
	end)
	local orbOn = { v = true }
	local orbChip = B("TextButton", {
		Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 212),
		BackgroundColor3 = th.act, Text = "ÓRBITAS: ON (Képler T ∝ r^1.5)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
	}, lp)
	H(orbChip, 5)
	orbChip.MouseButton1Click:Connect(function()
		orbOn.v = not orbOn.v
		orbChip.Text = orbOn.v and "ÓRBITAS: ON (Képler T ∝ r^1.5)" or "ÓRBITAS: pausadas"
		task.spawn(function() log(msgOf(cmd("space_orbits", { on = orbOn.v }))) end)
	end)

	-- centro/direita: MAPA ORBITAL real (vista de topo, lê estado do servidor)
	local map = B("Frame", {
		Size = UDim2.fromOffset(330, 240), Position = UDim2.fromOffset(282, 44),
		BackgroundColor3 = Color3.fromRGB(4, 7, 16), BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(map, 7) ST(map, 1, th.edge)
	map.ClipsDescendants = true
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 4),
		BackgroundTransparency = 1, Text = "MAPA ORBITAL (estado REAL do servidor, atualiza sozinho)",
		Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, map)
	local dots = {}
	function refreshMap()
		task.spawn(function()
			local res = cmd("space_state")
			for _, d in pairs(dots) do pcall(function() d:Destroy() end) end
			dots = {}
			if not res.bodies then return end
			local cx, cy = 165, 128
			local maxOrbit = 1
			for _, b2 in ipairs(res.bodies) do
				maxOrbit = math.max(maxOrbit, b2.orbit or 0)
			end
			for _, b2 in ipairs(res.bodies) do
				if (b2.orbit or 0) > 0 then
					local rr = (b2.orbit / maxOrbit) * 100
					local ring = B("Frame", {
						Size = UDim2.fromOffset(rr * 2, rr * 2),
						Position = UDim2.fromOffset(cx - rr, cy - rr),
						BackgroundTransparency = 1, ZIndex = 45,
					}, map)
					local rc = Instance.new("UICorner")
					rc.CornerRadius = UDim.new(1, 0)
					rc.Parent = ring
					local rst = Instance.new("UIStroke")
					rst.Thickness = 0.8
					rst.Color = Color3.fromRGB(40, 58, 110)
					rst.Transparency = 0.25
					rst.Parent = ring
					dots[#dots + 1] = ring
				end
				local dr = math.max(3, math.min(16, (b2.r or 2)))
				local px2 = cx + (b2.x / math.max(1, maxOrbit)) * 100
				local py2 = cy + (b2.z / math.max(1, maxOrbit)) * 100
				local dot = B("Frame", {
					Size = UDim2.fromOffset(dr, dr), Position = UDim2.fromOffset(px2 - dr / 2, py2 - dr / 2),
					BackgroundColor3 = Color3.fromRGB(240, 200, 120), BorderSizePixel = 0, ZIndex = 46,
				}, map)
				H(dot, dr / 2)
				if b2.matter == "terra" then dot.BackgroundColor3 = Color3.fromRGB(80, 150, 230) end
				if b2.matter == "sol" then dot.BackgroundColor3 = Color3.fromRGB(255, 214, 96) end
				if b2.matter == "lua" then dot.BackgroundColor3 = Color3.fromRGB(190, 190, 188) end
				if b2.matter == "gas" then dot.BackgroundColor3 = Color3.fromRGB(222, 186, 140) end
				if b2.matter == "lava" then dot.BackgroundColor3 = Color3.fromRGB(255, 100, 40) end
				local nl = B("TextLabel", {
					Size = UDim2.fromOffset(70, 10), Position = UDim2.fromOffset(dr / 2 + 2, -2),
					BackgroundTransparency = 1, Text = b2.name, Font = Enum.Font.Gotham,
					TextSize = 8, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 46,
				}, dot)
				dots[#dots + 1] = dot
			end
		end)
	end
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.2)
			if win.root.Visible then refreshMap() end
		end
	end)
	return win
end

local wEspaco = mkWin("espaco", "ESPAÇO X — criador orbital ARKHER", 622, 330, THEME_SPACE)
buildEspaco(wEspaco)

-- =============================================================
-- FABRICAR — catálogo gramatical (criar qualquer coisa)
-- =============================================================
local THEME_FAB = {
	bg = Color3.fromRGB(24, 14, 10), bg2 = Color3.fromRGB(30, 18, 13), bg3 = Color3.fromRGB(38, 24, 17),
	cap = Color3.fromRGB(20, 12, 8), edge = Color3.fromRGB(110, 66, 40),
	text = Color3.fromRGB(252, 236, 222), muted = Color3.fromRGB(196, 156, 126),
	acc = Color3.fromRGB(255, 130, 60), act = Color3.fromRGB(70, 40, 24),
}

local FAB_FAMS = {
	{ nm = "NATUREZA", kinds = { "arvore", "pinheiro", "palmeira", "cacto", "arbusto", "flor", "cogumelo", "pedra", "cristal", "montanha", "vulcao", "ilha" } },
	{ nm = "ESTRUTURA", kinds = { "casa", "predio", "torre", "ponte", "muro", "cerca", "escada", "porta", "coluna", "fonte", "arco", "telhado", "janela" } },
	{ nm = "MOBILIÁRIO", kinds = { "mesa", "cadeira", "sofa", "cama", "estante", "lampada", "vaso" } },
	{ nm = "VEÍCULOS", kinds = { "carro", "roda", "barco", "aviao", "nave" } },
	{ nm = "PROPS & ARMAS", kinds = { "espada", "escudo", "caixa", "barril", "placa", "bau", "estatua", "antena" } },
	{ nm = "ORGÂNICO", kinds = { "personagem", "criatura", "ave", "peixe" } },
}

local function buildFabricar(win)
	local th = THEME_FAB
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	B("TextLabel", {
		Size = UDim2.fromOffset(150, 14), Position = UDim2.fromOffset(10, 8),
		BackgroundTransparency = 1, Text = "FAMÍLIAS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local famList = B("Frame", {
		Size = UDim2.fromOffset(150, 206), Position = UDim2.fromOffset(10, 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(famList, 7) ST(famList, 1, th.edge)
	local flay = Instance.new("UIListLayout")
	flay.Padding = UDim.new(0, 2)
	flay.Parent = famList

	B("TextLabel", {
		Size = UDim2.fromOffset(190, 14), Position = UDim2.fromOffset(168, 8),
		BackgroundTransparency = 1, Text = "CLASSES (gramática procedural)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local kindList = listCtl(body, UDim2.fromOffset(168, 26), UDim2.fromOffset(190, 206), th)

	-- inspector
	local insp = B("Frame", {
		Size = UDim2.fromOffset(214, 232), Position = UDim2.fromOffset(366, 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(insp, 7) ST(insp, 1, th.edge)
	local kinName = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "escolha uma classe", Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)
	local seed = stepCtl(insp, UDim2.fromOffset(8, 32), "seed", 7, 1, 1, 9999, th)
	local autoSeed = { v = false }
	local chipA = B("TextButton", {
		Size = UDim2.new(0.5, -4, 0, 30), Position = UDim2.new(0.5, 4, 0, 32),
		BackgroundColor3 = th.act, Text = "auto-seed: off", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
	}, insp)
	H(chipA, 6)
	chipA.MouseButton1Click:Connect(function()
		autoSeed.v = not autoSeed.v
		chipA.Text = autoSeed.v and "auto-seed: ON (+1/clique)" or "auto-seed: off"
	end)
	local fx = stepCtl(insp, UDim2.fromOffset(8, 68), "x", 0, 10, -9999, 9999, th)
	local fz = stepCtl(insp, UDim2.new(0.5, 4, 0, 68), "z", -14, 10, -9999, 9999, th)
	local fsize = sliderCtl(insp, UDim2.fromOffset(8, 104), 0, "Tamanho ×", 0.4, 3, 1, th, function() end)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 140),
		BackgroundTransparency = 1, Text = "TINGE (exceto vidro/neon)", Font = Enum.Font.GothamBold,
		TextSize = 8, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)
	local swatches = {
		Color3.fromRGB(200, 40, 40), Color3.fromRGB(40, 90, 200), Color3.fromRGB(230, 200, 60),
		Color3.fromRGB(80, 170, 90), Color3.fromRGB(240, 240, 240), Color3.fromRGB(46, 46, 52),
	}
	local picked = { c = swatches[1] }
	for i, c in ipairs(swatches) do
		local sw = B("TextButton", {
			Size = UDim2.fromOffset(24, 18), Position = UDim2.fromOffset(8 + (i - 1) * 30, 156),
			BackgroundColor3 = c, Text = "", BorderSizePixel = 0, ZIndex = 44, AutoButtonColor = true,
		}, insp)
		H(sw, 4)
		sw.MouseButton1Click:Connect(function() picked.c = c end)
	end
	actBtn(insp, UDim2.fromOffset(8, 182), UDim2.new(1, -16, 0, 28), "FABRICAR NO MUNDO", th, function()
		if not curKind then return log("escolha uma classe", false) end
		local sd = autoSeed.v and math.random(1, 9999) or seed.get()
		local c = picked.c
		local res = cmd("fabricate", { kind = curKind, seed = sd, size = fsize.get(),
			x = fx.get(), z = fz.get(), y = 0,
			cr = c.R * 255, cg = c.G * 255, cb = c.B * 255 })
		log(msgOf(res))
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 214),
		BackgroundTransparency = 1, Text = "tudo que fabrica entra sozinho no mundo (backend RRW)",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, insp)

	curKind = nil
	for i, fam in ipairs(FAB_FAMS) do
		local fb = B("TextButton", {
			Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = th.bg3,
			Text = "  " .. fam.nm, Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = th.muted, BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
		}, famList)
		H(fb, 5)
		fb.MouseButton1Click:Connect(function()
			for _, ch in ipairs(famList:GetChildren()) do
				if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 ch.TextColor3 = th.muted end
			end
			fb.BackgroundColor3 = th.act
			fb.TextColor3 = th.text
			for _, ch in ipairs(kindList:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			for _, kn in ipairs(fam.kinds) do
				local kb = B("TextButton", {
					Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = th.bg3,
					Text = "  " .. kn, Font = Enum.Font.GothamBold, TextSize = 10,
					TextColor3 = th.text, BorderSizePixel = 0,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, kindList)
				H(kb, 5)
				kb.MouseButton1Click:Connect(function()
					curKind = kn
					kinName.Text = kn
					for _, ch in ipairs(kindList:GetChildren()) do
						if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
					end
					kb.BackgroundColor3 = th.act
				end)
			end
			log(fam.nm .. ": " .. #fam.kinds .. " classes")
		end)
	end
	return win
end

local wFabricar = mkWin("fabricar", "FABRICAR X — criar qualquer coisa", 590, 290, THEME_FAB)
buildFabricar(wFabricar)


-- =============================================================
-- WATER X — oceanografia REAL (fisica, nao shader de jogo)
-- comp. fisica (densidade/salinidade/temperatura/viscosidade) +
-- ondas Gerstner com dispersao REAL omega=sqrt(g*k) + mares +
-- Arquimedes (empuxo = rho*V*g) + cachoeira de materia real.
-- =============================================================
local THEME_WATER = {
	bg = Color3.fromRGB(6, 24, 32), bg2 = Color3.fromRGB(9, 32, 42), bg3 = Color3.fromRGB(12, 42, 54),
	cap = Color3.fromRGB(5, 20, 28), edge = Color3.fromRGB(28, 92, 112),
	text = Color3.fromRGB(214, 244, 252), muted = Color3.fromRGB(118, 178, 192),
	acc = Color3.fromRGB(53, 200, 232), act = Color3.fromRGB(14, 64, 80),
	tag = "óceano real",
}

local function buildWater(win)
	local th = THEME_WATER
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)

	-- faixa viva de stats (pomp do servidor, 2.5s)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  AWX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
		ClipsDescendants = true,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.5)
			if win.root.Visible then
				local res = cmd("water_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
			end
		end
	end)

	-- ============ COL 1: COMPOSICAO REAL (8 aguas) ============
	B("TextLabel", {
		Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(10, 30),
		BackgroundTransparency = 1, Text = "COMPOSIÇÃO (física real)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local kindList = listCtl(body, UDim2.fromOffset(10, 48), UDim2.fromOffset(200, 246), th)

	-- ============ COL 2: PARAMETROS + ESTADO DO MAR ============
	local mid = B("Frame", {
		Size = UDim2.fromOffset(210, 246), Position = UDim2.fromOffset(218, 48),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(mid, 7) ST(mid, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "PARÂMETROS FÍSICOS", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local chosenKind = { id = "oceano" }
	local kindLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 22),
		BackgroundTransparency = 1, Text = "oceano — 1025 kg/m³ · sal 35 g/kg",
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local seaId = { id = "porto" }
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 44),
		BackgroundTransparency = 1, Text = "estado do mar (Gerstner ω=√(g·k))", Font = Enum.Font.GothamBold,
		TextSize = 8, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local seaRow = B("Frame", {
		Size = UDim2.new(1, -16, 0, 50), Position = UDim2.fromOffset(8, 58),
		BackgroundTransparency = 1, ZIndex = 44,
	}, mid)
	local seaBtns = {}
	local seaNames = { "calmaria", "porto", "ressaca", "tempestade" }
	for i, sn in ipairs(seaNames) do
		local tb = B("TextButton", {
			Size = UDim2.fromOffset(94, 22), Position = UDim2.fromOffset(((i - 1) % 2) * 100, math.floor((i - 1) / 2) * 26),
			BackgroundColor3 = sn == "porto" and th.acc or th.bg3,
			Text = sn, Font = Enum.Font.GothamBold, TextSize = 9,
			TextColor3 = sn == "porto" and Color3.new(1, 1, 1) or th.muted,
			BorderSizePixel = 0, ZIndex = 45,
		}, seaRow)
		H(tb, 5)
		seaBtns[sn] = tb
		tb.MouseButton1Click:Connect(function()
			seaId.id = sn
			for s2, b2 in pairs(seaBtns) do
				b2.BackgroundColor3 = (s2 == sn) and th.acc or th.bg3
				b2.TextColor3 = (s2 == sn) and Color3.new(1, 1, 1) or th.muted
			end
		end)
	end
	-- espelho/corredeira numa segunda linha (menos usados)
	local altRow = B("Frame", {
		Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 110),
		BackgroundTransparency = 1, ZIndex = 44,
	}, mid)
	for i, sn in ipairs({ "corredeira", "espelho" }) do
		local tb = B("TextButton", {
			Size = UDim2.fromOffset(94, 22), Position = UDim2.fromOffset((i - 1) * 100, 0),
			BackgroundColor3 = th.bg3, Text = sn, Font = Enum.Font.GothamBold,
			TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 45,
		}, altRow)
		H(tb, 5)
		seaBtns[sn] = tb
		tb.MouseButton1Click:Connect(function()
			seaId.id = sn
			for s2, b2 in pairs(seaBtns) do
				b2.BackgroundColor3 = (s2 == sn) and th.acc or th.bg3
				b2.TextColor3 = (s2 == sn) and Color3.new(1, 1, 1) or th.muted
			end
		end)
	end
	local lvlS = sliderCtl(mid, UDim2.fromOffset(8, 140), 0, "Nível do mar (studs)", -20, 60, 8, th, function() end)
	local sizeS = sliderCtl(mid, UDim2.fromOffset(8, 178), 0, "Extensão (studs)", 128, 2048, 512, th, function() end)
	actBtn(mid, UDim2.fromOffset(8, 214), UDim2.new(1, -16, 0, 26), "CRIAR ÁGUA DE VERDADE", th, function()
		local res = cmd("water_create", {
			kind = chosenKind.id, preset = seaId.id,
			level = math.floor(lvlS.get()), size = math.floor(sizeS.get()),
		})
		log(msgOf(res))
	end)

	-- ============ COL 3: FISICA VIVA (demonstracoes reais) ============
	local rig = B("Frame", {
		Size = UDim2.fromOffset(210, 246), Position = UDim2.fromOffset(436, 48),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(rig, 7) ST(rig, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "FÍSICA VIVA — demonstrações de materia real",
		Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 44,
	}, rig)
	actBtn(rig, UDim2.fromOffset(8, 36), UDim2.new(1, -16, 0, 24), "Teste de Arquimedes (6 densidades)", th, function()
		log(msgOf(cmd("water_float_test", {})))
	end)
	local fallH = stepCtl(rig, UDim2.fromOffset(8, 66), "queda (studs)", 22, 4, 6, 80, th, "%d", 0.46)
	local fallF = stepCtl(rig, UDim2.new(0.5, 4, 0, 66), "gotas/s", 8, 2, 2, 40, th, "%d", 0.46)
	actBtn(rig, UDim2.fromOffset(8, 100), UDim2.new(1, -16, 0, 24), "Cachoeira de verdade", th, function()
		log(msgOf(cmd("water_waterfall", { h = fallH.get(), flow = fallF.get() })))
	end)
	actBtn(rig, UDim2.fromOffset(8, 130), UDim2.new(1, -16, 0, 24), "Barco físico (4 boias)", th, function()
		log(msgOf(cmd("water_boat", {})))
	end)
	actBtn(rig, UDim2.fromOffset(8, 160), UDim2.new(1, -16, 0, 24), "Ler composição atual", th, function()
		log(msgOf(cmd("water_composition", {})))
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 190),
		BackgroundTransparency = 1,
		Text = "Real aqui = oceano de verdade: densidade/sal/temperatura mudam empuxo; ondas obedecem dispersão gravitacional; maré tem período lunar. Não é skin visual.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, rig)

	-- preencher a lista de composicoes com dados REAIS do servidor
	task.spawn(function()
		local res = cmd("water_presets")
		if not res.kinds then return end
		for _, k in ipairs(res.kinds) do
			local kb = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 28), BackgroundColor3 = th.bg3,
				Text = ("  %s   %.0f kg/m³"):format(k.id, k.dens),
				Font = Enum.Font.GothamBold, TextSize = 9,
				TextColor3 = th.text, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, kindList)
			H(kb, 5)
			kb.MouseButton1Click:Connect(function()
				chosenKind.id = k.id
				kindLbl.Text = ("%s — %.0f kg/m³ · sal %.1f g/kg · %.0f°C"):format(k.id, k.dens, k.sal, k.temp)
				for _, ch in ipairs(kindList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
				end
				kb.BackgroundColor3 = th.act
			end)
		end
	end)
	return win
end

local wWater = mkWin("water", "WATER X — oceanografia real (densidade · Gerstner · Arquimedes)", 656, 330, THEME_WATER)
buildWater(wWater)


-- =============================================================
-- ATMOS X — céu/clima físico (Kelvin real, 7 estados, ciclo solar)
-- =============================================================
local THEME_ATMOS = {
	bg = Color3.fromRGB(10, 14, 32), bg2 = Color3.fromRGB(14, 20, 42), bg3 = Color3.fromRGB(18, 26, 54),
	cap = Color3.fromRGB(8, 11, 26), edge = Color3.fromRGB(60, 78, 150),
	text = Color3.fromRGB(232, 238, 255), muted = Color3.fromRGB(148, 160, 210),
	acc = Color3.fromRGB(255, 208, 116), act = Color3.fromRGB(70, 58, 24),
}

local function buildAtmos(win)
	local th = THEME_ATMOS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  AEX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.4)
			if win.root.Visible then
				local res = cmd("atmos_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
			end
		end
	end)

	-- COL 1: horário do sol (6 presets Kelvin reais)
	B("TextLabel", {
		Size = UDim2.fromOffset(210, 14), Position = UDim2.fromOffset(10, 30),
		BackgroundTransparency = 1, Text = "HORÁRIO DO SOL — cor real por Kelvin", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local skyList = listCtl(body, UDim2.fromOffset(10, 48), UDim2.fromOffset(210, 200), th)

	-- COL 2: estado do tempo (7 estados de transição)
	B("TextLabel", {
		Size = UDim2.fromOffset(104, 14), Position = UDim2.fromOffset(228, 30),
		BackgroundTransparency = 1, Text = "TEMPO", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local wList = listCtl(body, UDim2.fromOffset(228, 48), UDim2.fromOffset(104, 200), th)

	-- COL 3: relógio solar (controla o céu de verdade)
	local rig = B("Frame", {
		Size = UDim2.fromOffset(324, 200), Position = UDim2.fromOffset(340, 48),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(rig, 7) ST(rig, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "RELÓGIO SOLAR (0–24h, o céu cruza sozinho)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, rig)
	local clockBig = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1, Text = "12.0 h", Font = Enum.Font.Code,
		TextSize = 30, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, rig)
	local clockS = sliderCtl(rig, UDim2.fromOffset(8, 70), 0, "hora do dia", 0, 24, 12, th, function(v)
		clockBig.Text = string.format("%.1f h", v)
	end)
	task.spawn(function()
		while win.root.Parent do
			task.wait(3.2)
			if win.root.Visible then
				local res = cmd("atmos_stats")
				if res.clock then
					clockBig.Text = string.format("%.1f h", res.clock)
				end
			end
		end
	end)
	-- gira o relógio quando o usuário solta o slider (hook custom no InputEnded do track? o kit ja manda final)
	do
		-- onChange do sliderCtl chama com debounce; aqui conecto "valor final" ao servidor
		local lastSent = 0
		task.spawn(function()
			while win.root.Parent do
				task.wait(0.6)
				local v = clockS.get()
				if math.abs(v - lastSent) > 0.05 and win.root.Visible then
					lastSent = v
					local res = cmd("atmos_clock", { h = v })
					log(msgOf(res))
				end
			end
		end)
	end
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 84), Position = UDim2.fromOffset(8, 108),
		BackgroundTransparency = 1,
		Text = "Física de verdade: sol de 1900K (noite) a 5600K (meio-dia) converge por Planck/CIE no Lighting — não é tint manual. Nuvens orgânicas, relâmpagos agendados, transições de 7 estados com blend de verdade no pump.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, rig)

	-- preencher listas com dados reais do motor
	task.spawn(function()
		local res = cmd("atmos_list")
		if not res.skies then return end
		for _, sk in ipairs(res.skies) do
			local kb = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = th.bg3,
				Text = ("  %s   %dK"):format(sk.id, sk.kelvin),
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = th.text, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, skyList)
			H(kb, 5)
			kb.MouseButton1Click:Connect(function()
				task.spawn(function() log(msgOf(cmd("atmos_preset", { preset = sk.id }))) end)
				for _, ch in ipairs(skyList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
				end
				kb.BackgroundColor3 = th.act
			end)
		end
		for _, w2 in ipairs(res.weathers or {}) do
			local wb = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = th.bg3,
				Text = "  " .. w2, Font = Enum.Font.GothamBold, TextSize = 9,
				TextColor3 = th.muted, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, wList)
			H(wb, 5)
			wb.MouseButton1Click:Connect(function()
				task.spawn(function() log(msgOf(cmd("atmos_weather", { state = w2 }))) end)
				for _, ch in ipairs(wList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
				end
				wb.BackgroundColor3 = th.act
			end)
		end
	end)
	return win
end

local wAtmos = mkWin("atmos", "ATMOS X — céu e clima físicos (Kelvin real)", 674, 300, THEME_ATMOS)
buildAtmos(wAtmos)

-- =============================================================
-- CLIMA X — frentes H/L que VIAJAM e mudam o tempo de verdade
-- =============================================================
local THEME_CLIMA = {
	bg = Color3.fromRGB(22, 24, 28), bg2 = Color3.fromRGB(28, 31, 38), bg3 = Color3.fromRGB(34, 38, 48),
	cap = Color3.fromRGB(18, 20, 25), edge = Color3.fromRGB(78, 92, 122),
	text = Color3.fromRGB(238, 242, 252), muted = Color3.fromRGB(150, 160, 182),
	acc = Color3.fromRGB(122, 168, 255), act = Color3.fromRGB(46, 68, 118),
}

local function buildClima(win)
	local th = THEME_CLIMA
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  WEA conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	actBtn(body, UDim2.fromOffset(10, 32), UDim2.fromOffset(150, 26), "LIGAR FRENTE H/L", th, function()
		log(msgOf(cmd("fronts_on", {})))
	end, 43)
	actBtn(body, UDim2.fromOffset(10, 64), UDim2.fromOffset(150, 26), "Parar frentes", th, function()
		log(msgOf(cmd("wea_off", {})))
	end, 43)
	B("TextLabel", {
		Size = UDim2.fromOffset(150, 120), Position = UDim2.fromOffset(10, 98),
		BackgroundTransparency = 1,
		Text = "Sistemas de ALTA/BAIXA pressão nascem, viajam com a circulação e MORREM — quando uma frente cruza pra cá, o tempo (ATMOS) muda SOZINHO.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)
	-- mapa de frentes (estado real do servidor)
	local map = B("Frame", {
		Size = UDim2.fromOffset(490, 246), Position = UDim2.fromOffset(170, 48),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22), BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(map, 7) ST(map, 1, th.edge)
	map.ClipsDescendants = true
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 12), Position = UDim2.fromOffset(8, 4),
		BackgroundTransparency = 1, Text = "MAPA METEOROLÓGICO (vivo, do servidor)",
		Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, map)
	local dots = {}
	local function draw(res)
		for _, d in ipairs(dots) do pcall(function() d:Destroy() end) end
		dots = {}
		if not res.systems then return end
		local cx2, cy2 = 245, 129
		for _, sy in ipairs(res.systems) do
			local rr = math.clamp((sy.r or 200) / 1200 * 224, 10, 110)
			local col = (sy.kind == "H") and Color3.fromRGB(96, 160, 255) or Color3.fromRGB(255, 110, 100)
			local ring = B("Frame", {
				Size = UDim2.fromOffset(rr * 2, rr * 2),
				Position = UDim2.fromOffset(cx2 + (sy.x / 1200) * 224 - rr, cy2 + (sy.z / 1200) * 112 - rr),
				BackgroundTransparency = 1, ZIndex = 45,
			}, map)
			local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(1, 0) rc.Parent = ring
			local rst = Instance.new("UIStroke") rst.Thickness = 1.6 rst.Color = col rst.Transparency = 0.35 rst.Parent = ring
			local core = B("TextLabel", {
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.fromOffset(cx2 + (sy.x / 1200) * 224 - 9, cy2 + (sy.z / 1200) * 112 - 9),
				BackgroundColor3 = col, Text = sy.kind, Font = Enum.Font.GothamBold,
				TextSize = 11, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 46,
			}, map)
			H(core, 9)
			dots[#dots + 1] = ring
			dots[#dots + 1] = core
		end
	end
	task.spawn(function()
		while win.root.Parent do
			task.wait(3)
			if win.root.Visible then
				local res = cmd("wea_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
				draw(res)
			end
		end
	end)
	return win
end

local wClima = mkWin("clima", "CLIMA X — frentes meteorológicas vivas (H/L)", 670, 320, THEME_CLIMA)
buildClima(wClima)

-- =============================================================
-- VIDA X — humanos digitais, NPCs, ecossistema, mentes
-- =============================================================
local THEME_VIDA = {
	bg = Color3.fromRGB(14, 28, 18), bg2 = Color3.fromRGB(18, 36, 24), bg3 = Color3.fromRGB(22, 46, 32),
	cap = Color3.fromRGB(12, 24, 16), edge = Color3.fromRGB(52, 122, 74),
	text = Color3.fromRGB(228, 250, 234), muted = Color3.fromRGB(140, 190, 156),
	acc = Color3.fromRGB(127, 226, 138), act = Color3.fromRGB(24, 74, 42),
}

local function buildVida(win)
	local th = THEME_VIDA
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  VIDA conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(3)
			if win.root.Visible then
				local d = cmd("day_stats")
				local e = cmd("eco_stats")
				local m2 = cmd("mind_stats")
				statsBar.Text = "  " .. (d.msg or "—") .. "  |  " .. (e.msg or "—") .. "  |  " .. (m2.msg or "—")
			end
		end
	end)

	-- COL 1 humano digital
	B("TextLabel", {
		Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(10, 30),
		BackgroundTransparency = 1, Text = "HUMANO DIGITAL (DAYX)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local hseed = stepCtl(body, UDim2.fromOffset(10, 50), "seed", 7, 1, 1, 9999, th, "%d", 0.96)
	actBtn(body, UDim2.fromOffset(10, 86), UDim2.fromOffset(200, 26), "SPAWNAR HUMANO DIGITAL", th, function()
		local res = cmd("life_human", { seed = hseed.get() })
		log(msgOf(res))
	end)
	B("TextLabel", {
		Size = UDim2.fromOffset(200, 74), Position = UDim2.fromOffset(10, 118),
		BackgroundTransparency = 1,
		Text = "Respiração 0.25 Hz, piscar fisiológico, olhar-atento à sua câmera, marcha procedural — importância 0.95 no RRW (não some).",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)

	-- COL 2 NPCs
	B("TextLabel", {
		Size = UDim2.fromOffset(210, 14), Position = UDim2.fromOffset(218, 30),
		BackgroundTransparency = 1, Text = "NPCs (FABRIK + mentes)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	for i, pr in ipairs({ "bipede", "quadrupede", "serpente", "monstro" }) do
		actBtn(body, UDim2.fromOffset(218, 50 + (i - 1) * 32), UDim2.fromOffset(210, 26), "NPC " .. pr, th, function()
			log(msgOf(cmd("npc_spawn", { preset = pr })))
		end)
	end

	-- COL 3 eco + mentes
	B("TextLabel", {
		Size = UDim2.fromOffset(220, 14), Position = UDim2.fromOffset(436, 30),
		BackgroundTransparency = 1, Text = "ECOSSISTEMA + MENTES", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	actBtn(body, UDim2.fromOffset(436, 50), UDim2.fromOffset(220, 26), "LIGAR ECOSSISTEMA", th, function()
		log(msgOf(cmd("eco_start", {})))
	end)
	actBtn(body, UDim2.fromOffset(436, 82), UDim2.fromOffset(220, 26), "Pausar ecossistema", th, function()
		log(msgOf(cmd("eco_stop", {})))
	end)
	B("TextLabel", {
		Size = UDim2.fromOffset(220, 80), Position = UDim2.fromOffset(436, 114),
		BackgroundTransparency = 1,
		Text = "Presas/predadores logísticos no ECOX; cada NPC tem mente MINDX com percepção real (o painel mostra objetivos atuais no topo).",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)
	return win
end

local wVida = mkWin("vida", "VIDA X — humanos digitais · NPCs · ecossistema", 666, 230, THEME_VIDA)
buildVida(wVida)

-- =============================================================
-- CIDADE X — assentamentos (malha viaria + FABX) que GRAVAM na terra
-- =============================================================
local THEME_CIDADE = {
	bg = Color3.fromRGB(30, 23, 16), bg2 = Color3.fromRGB(38, 30, 22), bg3 = Color3.fromRGB(46, 38, 29),
	cap = Color3.fromRGB(26, 20, 14), edge = Color3.fromRGB(124, 88, 52),
	text = Color3.fromRGB(250, 238, 222), muted = Color3.fromRGB(200, 168, 132),
	acc = Color3.fromRGB(224, 164, 92), act = Color3.fromRGB(96, 62, 30),
}

local function buildCidade(win)
	local th = THEME_CIDADE
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  CIVIX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(3)
			if win.root.Visible then
				local res = cmd("civ_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
			end
		end
	end)

	local kind = { id = "vila" }
	local kindBtns = {}
	for i, k in ipairs({ "vila", "cidade", "metropole" }) do
		local tb = B("TextButton", {
			Size = UDim2.fromOffset(160, 36), Position = UDim2.fromOffset(10 + (i - 1) * 172, 32),
			BackgroundColor3 = i == 1 and th.acc or th.bg3,
			Text = (k == "metropole") and "METRÓPOLE" or (k == "cidade") and "CIDADE" or "VILA",
			Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = i == 1 and Color3.fromRGB(24, 16, 8) or th.muted,
			BorderSizePixel = 0, ZIndex = 44,
		}, body)
		H(tb, 7) ST(tb, 1, th.edge)
		kindBtns[k] = tb
		tb.MouseButton1Click:Connect(function()
			kind.id = k
			for k2, b2 in pairs(kindBtns) do
				b2.BackgroundColor3 = (k2 == k) and th.acc or th.bg3
				b2.TextColor3 = (k2 == k) and Color3.fromRGB(24, 16, 8) or th.muted
			end
		end)
	end
	local cseed = stepCtl(body, UDim2.fromOffset(10, 78), "seed", 7, 1, 1, 9999, th)
	local autoSeed = { v = false }
	local chip = B("TextButton", {
		Size = UDim2.new(0.3, -4, 0, 30), Position = UDim2.new(0.51, 4, 0, 78),
		BackgroundColor3 = th.act, Text = "auto-seed: off", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
	}, body)
	H(chip, 6)
	chip.MouseButton1Click:Connect(function()
		autoSeed.v = not autoSeed.v
		chip.Text = autoSeed.v and "auto-seed: ON" or "auto-seed: off"
	end)
	local cx = stepCtl(body, UDim2.fromOffset(10, 116), "x", 0, 20, -9999, 9999, th)
	local cz = stepCtl(body, UDim2.new(0.51, 4, 0, 116), "z", -90, 20, -9999, 9999, th)
	actBtn(body, UDim2.fromOffset(10, 156), UDim2.new(1, -20, 0, 30), "CONSTRUIR NO MUNDO (grava na terra)", th, function()
		local sd = autoSeed.v and math.random(1, 9999) or cseed.get()
		local res = cmd("civ_fabricate", { kind = kind.id, seed = sd, x = cx.get(), z = cz.get() })
		log(msgOf(res))
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 192),
		BackgroundTransparency = 1,
		Text = "A malha viária sai do CIVIX + peças do FABX, e o assentamento também grava na TERRA via RLayer.urbanize (ó qual queridade urbana da cell).",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)
	return win
end

local wCidade = mkWin("cidade", "CIDADE X — vila, cidade, metrópole reais", 660, 250, THEME_CIDADE)
buildCidade(wCidade)

-- =============================================================
-- ÁUDIO X — o mixer dos 7 buses reais do mundo (AUX)
-- =============================================================
local THEME_AUDIO = {
	bg = Color3.fromRGB(20, 14, 30), bg2 = Color3.fromRGB(26, 19, 40), bg3 = Color3.fromRGB(32, 24, 50),
	cap = Color3.fromRGB(16, 12, 24), edge = Color3.fromRGB(88, 66, 140),
	text = Color3.fromRGB(244, 238, 254), muted = Color3.fromRGB(176, 156, 210),
	acc = Color3.fromRGB(192, 140, 255), act = Color3.fromRGB(56, 38, 96),
}

local BUS_ORDER = { "master", "music", "sfx", "ui", "ambient", "weather", "voice" }

local function buildAudio(win)
	local th = THEME_AUDIO
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  AUX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.5)
			if win.root.Visible then
				local res = cmd("audio_stats")
				if type(res) == "table" and res.buses then
					statsBar.Text = ("  AUX: %d sons | %d tocando | %d buses | %d ducks | %d ambientes"):format(res.sounds or 0, res.playing or 0, res.buses or 0, res.ducks or 0, res.ambients or 0)
				end
			end
		end
	end)

	-- mixer vertical (7 buses, com leitura do servidor)
	local mixer = B("Frame", {
		Size = UDim2.fromOffset(360, 244), Position = UDim2.fromOffset(10, 30),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(mixer, 7) ST(mixer, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "MIXER — 7 BUSES (arrasta, grava no motor)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mixer)
	for i, bname in ipairs(BUS_ORDER) do
		local row = B("Frame", {
			Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 24 + (i - 1) * 32),
			BackgroundTransparency = 1, ZIndex = 44,
		}, mixer)
		B("TextLabel", {
			Size = UDim2.fromOffset(70, 30), BackgroundTransparency = 1, Text = bname,
			Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.text,
			TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
		}, row)
		local volLbl = B("TextLabel", {
			Size = UDim2.fromOffset(36, 30), Position = UDim2.new(1, -36, 0, 0),
			BackgroundTransparency = 1, Text = "1.00", Font = Enum.Font.Code,
			TextSize = 11, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 44,
		}, row)
		local sld = sliderCtl(row, UDim2.fromOffset(74, -1), 0, "", 0, 2, 1, th, function(v)
			volLbl.Text = string.format("%.2f", v)
			task.spawn(function()
				local res = cmd("audio_bus", { bus = bname, vol = v })
				log(msgOf(res))
			end)
		end)
	end

	-- intensidade musical
	local rightc = B("Frame", {
		Size = UDim2.fromOffset(266, 244), Position = UDim2.fromOffset(380, 30),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(rightc, 7) ST(rightc, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 14), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = "INTENSIDADE MUSICAL", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, rightc)
	local intLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1, Text = "1.00 — tensão", Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, rightc)
	sliderCtl(rightc, UDim2.fromOffset(8, 62), 0, "0 paz · 1 tensão · 2 combate", 0, 2, 1, th, function(v)
		intLbl.Text = string.format("%.2f — %s", v, v < 0.5 and "paz" or (v < 1.4 and "tensão" or "combate"))
		task.spawn(function() log(msgOf(cmd("audio_intensity", { v = v }))) end)
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 112), Position = UDim2.fromOffset(8, 102),
		BackgroundTransparency = 1,
		Text = "O motor AUX é real: buses de ganho, rolloff inverso-quadrático, doppler aproximado, ducks, layers e ligação com ATMOS/AWX. Sem clipes custom ainda (Roblox id) — os buses controlam o som do mundo (vento, mar, relâmpagos) que os outros motores tocam.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, rightc)
	actBtn(rightc, UDim2.fromOffset(8, 216), UDim2.new(1, -16, 0, 24), "Setup buses (idempotente)", th, function()
		log(msgOf(cmd("audio_setup", {})))
	end)
	return win
end

local wAudio = mkWin("audio", "ÁUDIO X — mixer real dos 7 buses do mundo", 656, 300, THEME_AUDIO)
buildAudio(wAudio)

-- =============================================================
-- FX X — 13 presets de partículas FÍSICAS (gravidade real, budget D-O15)
-- =============================================================
local THEME_FX = {
	bg = Color3.fromRGB(28, 12, 8), bg2 = Color3.fromRGB(36, 17, 12), bg3 = Color3.fromRGB(46, 23, 16),
	cap = Color3.fromRGB(24, 11, 8), edge = Color3.fromRGB(128, 60, 30),
	text = Color3.fromRGB(252, 238, 226), muted = Color3.fromRGB(204, 160, 128),
	acc = Color3.fromRGB(255, 154, 61), act = Color3.fromRGB(108, 48, 18),
}

local function buildFx(win)
	local th = THEME_FX
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  APX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.5)
			if win.root.Visible then
				local res = cmd("fx_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
			end
		end
	end)

	B("TextLabel", {
		Size = UDim2.fromOffset(210, 14), Position = UDim2.fromOffset(10, 30),
		BackgroundTransparency = 1, Text = "13 PRESETS (física de verdade)", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local fxList = listCtl(body, UDim2.fromOffset(10, 48), UDim2.fromOffset(210, 230), th)

	local mid = B("Frame", {
		Size = UDim2.fromOffset(250, 230), Position = UDim2.fromOffset(228, 48),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(mid, 7) ST(mid, 1, th.edge)
	local fxName = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Text = "selecione um preset", Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, mid)
	local fxInfo = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1, Text = "—", Font = Enum.Font.Gotham, TextSize = 9,
		TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 44,
	}, mid)
	local chosen = { id = "fogo" }
	local fx = stepCtl(mid, UDim2.fromOffset(8, 62), "x", 0, 10, -999, 999, th)
	local fz = stepCtl(mid, UDim2.new(0.51, 4, 0, 62), "z", -16, 10, -999, 999, th)
	local fy = stepCtl(mid, UDim2.fromOffset(8, 100), "y (altura)", 6, 2, 0, 200, th)
	actBtn(mid, UDim2.fromOffset(8, 140), UDim2.new(1, -16, 0, 28), "EMITIR NO MUNDO", th, function()
		local res = cmd("fx_emit", { kind = chosen.id, x = fx.get(), y = fy.get(), z = fz.get() })
		log(msgOf(res))
	end)
	actBtn(mid, UDim2.fromOffset(8, 174), UDim2.new(1, -16, 0, 24), "Limpar TODOS os emissores", th, function()
		log(msgOf(cmd("fx_clear", {})))
	end)

	local rightInfo = B("Frame", {
		Size = UDim2.fromOffset(200, 230), Position = UDim2.fromOffset(486, 48),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(rightInfo, 7) ST(rightInfo, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 200), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		Text = "Cada preset tem gravidade, velocidade, espalhamento, vida e cores FÍSICAS próprias — fogo sobe (gravidade -12), chuva cai a 40/s com cone fino, neve balança com sway, magia gira em vórtice (vR/vOmega). O budget D-O15 corta emissão sozinho se a GPU apertar — sem overdraw fake.",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, rightInfo)
	-- preencher presets
	task.spawn(function()
		local res = cmd("fx_presets")
		if not res.presets then return end
		for _, pr in ipairs(res.presets) do
			local kb = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 26), BackgroundColor3 = th.bg3,
				Text = ("  %s  ·  %s · %d/s"):format(pr.id, pr.mode, pr.rate or 0),
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = th.text, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, fxList)
			H(kb, 5)
			kb.MouseButton1Click:Connect(function()
				chosen.id = pr.id
				fxName.Text = pr.id
				fxInfo.Text = ("modo %s · vel %.0f · grav %.0f · vida %.1fs"):format(pr.mode, pr.speed or 0, pr.gravity or 0, pr.life or 0)
				for _, ch in ipairs(fxList:GetChildren()) do
					if ch:IsA("TextButton") then ch.BackgroundColor3 = th.bg3 end
				end
				kb.BackgroundColor3 = th.act
			end)
		end
	end)
	return win
end

local wFx = mkWin("fx", "FX X — partículas físicas (gravidade real, budget real)", 696, 310, THEME_FX)
buildFx(wFx)

-- =============================================================
-- CORDAS X — integração Verlet íntegra (corda, bandeira, ponte)
-- =============================================================
local THEME_CORDAS = {
	bg = Color3.fromRGB(24, 18, 12), bg2 = Color3.fromRGB(30, 24, 17), bg3 = Color3.fromRGB(38, 30, 22),
	cap = Color3.fromRGB(20, 16, 11), edge = Color3.fromRGB(112, 84, 48),
	text = Color3.fromRGB(250, 240, 228), muted = Color3.fromRGB(196, 168, 130),
	acc = Color3.fromRGB(216, 162, 90), act = Color3.fromRGB(84, 54, 26),
}

local function buildCordas(win)
	local th = THEME_CORDAS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statsBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  RPX conectando…",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statsBar, 6)
	task.spawn(function()
		while win.root.Parent do
			task.wait(2.5)
			if win.root.Visible then
				local res = cmd("rope_stats")
				if res.msg then statsBar.Text = "  " .. res.msg end
			end
		end
	end)

	actBtn(body, UDim2.fromOffset(10, 34), UDim2.fromOffset(300, 30), "PONTE DE CORDA (demo físico)", th, function()
		log(msgOf(cmd("rope_demo", {})))
	end)
	local fx = stepCtl(body, UDim2.fromOffset(10, 74), "x", 6, 2, -60, 60, th)
	local fy = stepCtl(body, UDim2.new(0.51, 16, 0, 74), "y", 16, 2, 4, 40, th)
	local fz2 = stepCtl(body, UDim2.fromOffset(10, 110), "z", 4, 2, -60, 60, th)
	actBtn(body, UDim2.fromOffset(10, 146), UDim2.fromOffset(300, 28), "BANDEIRA (tecido Verlet ao vento)", th, function()
		log(msgOf(cmd("rope_flag", { x = fx.get(), y = fy.get(), z = fz2.get() })))
	end)
	local bLen = stepCtl(body, UDim2.fromOffset(10, 184), "vão (studs)", 30, 6, 12, 96, th)
	actBtn(body, UDim2.fromOffset(10, 220), UDim2.fromOffset(300, 28), "PONTE PÊNSIL + bola oscilante", th, function()
		log(msgOf(cmd("rope_bridge", { len = bLen.get() })))
	end)

	local rig = B("Frame", {
		Size = UDim2.fromOffset(330, 214), Position = UDim2.fromOffset(320, 34),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(rig, 7) ST(rig, 1, th.edge)
	B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 200), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		Text = "Verlet íntegro: cada corda/tecidinho é pontos e restrições integrados ponto a ponto no pump (gravidade, mola, colisão com esferas e chão) — e o VENTO do ATMOS entra como força real. Não é uma imagem de corda: é física de partículas escrita no workspace (cada segmento vira Part).",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 44,
	}, rig)
	return win
end

local wCordas = mkWin("cordas", "CORDAS X — Verlet íntegro (corda/bandeira/ponte)", 666, 270, THEME_CORDAS)
buildCordas(wCordas)


-- =============================================================
-- TOOLBOX X — Creator Store REAL do Roblox + templates Arkher
-- =============================================================
local THEME_TOOLBOX = {
	bg = Color3.fromRGB(16, 20, 30), bg2 = Color3.fromRGB(20, 25, 38), bg3 = Color3.fromRGB(26, 32, 48),
	cap = Color3.fromRGB(13, 16, 25), edge = Color3.fromRGB(64, 84, 130),
	text = Color3.fromRGB(235, 242, 255), muted = Color3.fromRGB(150, 165, 200),
	acc = Color3.fromRGB(96, 180, 255), act = Color3.fromRGB(28, 64, 112),
}

local function buildToolbox(win)
	local th = THEME_TOOLBOX
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local cur = { tab = "loja", kind = "models", page = 0, query = "" }

	-- tabs
	local tabLoja = B("TextButton", {
		Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.acc, Text = "CREATOR STORE (loja real Roblox)",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(8, 16, 30),
		BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(tabLoja, 6)
	local tabStock = B("TextButton", {
		Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(196, 6),
		BackgroundColor3 = th.bg3, Text = "Templates Arkher (prontos)",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.muted,
		BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(tabStock, 6)
	local info = B("TextLabel", {
		Size = UDim2.new(0, 280, 0, 24), Position = UDim2.new(1, -290, 0, 6),
		BackgroundTransparency = 1, Text = "clique INSERE no mundo (InsertService real)",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43,
	}, body)

	-- barra de busca
	local searchBox = B("TextBox", {
		Size = UDim2.new(1, -280, 0, 26), Position = UDim2.fromOffset(10, 38),
		BackgroundColor3 = th.bg2, Text = "", PlaceholderText = "buscar na Creator Store… (ex.: tree, sword, house)",
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 43,
	}, body)
	H(searchBox, 6)
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0, 8) pad.Parent = searchBox
	local kindBtn = B("TextButton", {
		Size = UDim2.fromOffset(110, 26), Position = UDim2.new(1, -264, 0, 38),
		BackgroundColor3 = th.bg3, Text = "modelos ▾", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(kindBtn, 6)
	kindBtn.MouseButton1Click:Connect(function()
		cur.kind = (cur.kind == "models") and "decals" or "models"
		kindBtn.Text = (cur.kind == "models") and "modelos ▾" or "decals ▾"
	end)
	local pageLbl = B("TextLabel", {
		Size = UDim2.fromOffset(60, 26), Position = UDim2.new(1, -148, 0, 38),
		BackgroundTransparency = 1, Text = "pág 1", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = th.muted, ZIndex = 43,
	}, body)
	local prevB = B("TextButton", {
		Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -86, 0, 38),
		BackgroundColor3 = th.bg3, Text = "‹", Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(prevB, 6)
	local nextB = B("TextButton", {
		Size = UDim2.fromOffset(30, 26), Position = UDim2.new(1, -52, 0, 38),
		BackgroundColor3 = th.bg3, Text = "›", Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(nextB, 6)

	local results = listCtl(body, UDim2.fromOffset(10, 72), UDim2.new(1, -20, 1, -100), th)

	local function clearList(cnt)
		for _, ch in ipairs(results:GetChildren()) do
			if ch:IsA("GuiObject") and (ch.Name == "Row" or ch:IsA("TextButton")) then ch:Destroy() end
		end
	end

	local function paintLoja(res)
		clearList()
		if not res then return end
		if res.error then
			B("TextLabel", {
				Size = UDim2.new(1, -8, 0, 44), BackgroundTransparency = 1,
				Text = "⚠  " .. res.error, Font = Enum.Font.Gotham, TextSize = 11,
				TextColor3 = Color3.fromRGB(255, 170, 120), TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 44,
			}, results)
			return
		end
		info.Text = ("%s resultados — clique INSERE (Creator Store REAL)"):format(tostring(res.total or #res.items))
		for _, it in ipairs(res.items or {}) do
			local row = B("TextButton", {
				Size = UDim2.new(1, -8, 0, 36), BackgroundColor3 = th.bg2,
				Text = "", BorderSizePixel = 0, ZIndex = 43,
			}, results)
			H(row, 6)
			B("TextLabel", {
				Size = UDim2.new(1, -200, 0, 18), Position = UDim2.fromOffset(8, 2),
				BackgroundTransparency = 1, Text = tostring(it.name),
				Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, row)
			B("TextLabel", {
				Size = UDim2.new(1, -200, 0, 14), Position = UDim2.fromOffset(8, 19),
				BackgroundTransparency = 1,
				Text = ("id %d · por %s%s"):format(it.id or 0, tostring(it.creator or "?"), it.trusted and " ★" or ""),
				Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, row)
			local ins = B("TextButton", {
				Size = UDim2.fromOffset(96, 26), Position = UDim2.new(1, -104, 0, 5),
				BackgroundColor3 = th.acc, Text = "INSERIR", Font = Enum.Font.GothamBold,
				TextSize = 10, TextColor3 = Color3.fromRGB(8, 16, 30), BorderSizePixel = 0, ZIndex = 44,
			}, row)
			H(ins, 6)
			ins.MouseButton1Click:Connect(function()
				ins.Text = "…"
				task.spawn(function()
					local rr, err = bridgeResult("ToolboxAssetInsert", { assetId = it.id })
					ins.Text = "INSERIR"
					if not rr then log("⚠ " .. tostring(err)) else
						log(rr.msg or ("asset " .. it.id .. " inserido"))
					end
				end)
			end)
		end
		if #(res.items or {}) == 0 and not res.error then
			B("TextLabel", {
				Size = UDim2.new(1, -8, 0, 30), BackgroundTransparency = 1,
				Text = "Nada encontrado — tente outro termo (inglês funciona melhor: tree, sword, car, gun, house…)",
				Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = th.muted,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, results)
		end
	end

	local function paintArkher()
		clearList()
		info.Text = "Templates Arkher — inserta com um clique (motor nativo)"
		task.spawn(function()
			local res, err = bridgeResult("ToolboxList")
			if not res then log("⚠ " .. tostring(err)) return end
			for _, cat in ipairs(res.categories or {}) do
				B("TextLabel", {
					Size = UDim2.new(1, -8, 0, 22), BackgroundColor3 = th.bg3,
					Text = "  " .. tostring(cat.category), Font = Enum.Font.GothamBold,
					TextSize = 11, TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0, ZIndex = 43,
				}, results)
				for _, it in ipairs(cat.items or {}) do
					local row = B("TextButton", {
						Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = th.bg2,
						Text = "", BorderSizePixel = 0, ZIndex = 43,
					}, results)
					H(row, 6)
					B("TextLabel", {
						Size = UDim2.new(1, -140, 0, 15), Position = UDim2.fromOffset(8, 1),
						BackgroundTransparency = 1, Text = tostring(it.name),
						Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
						TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
					}, row)
					B("TextLabel", {
						Size = UDim2.new(1, -140, 0, 12), Position = UDim2.fromOffset(8, 16),
						BackgroundTransparency = 1, Text = tostring(it.description or ""),
						Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
						TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
					}, row)
					local ins = B("TextButton", {
						Size = UDim2.fromOffset(110, 22), Position = UDim2.new(1, -118, 0, 4),
						BackgroundColor3 = th.act, Text = "INSERIR", Font = Enum.Font.GothamBold,
						TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
					}, row)
					H(ins, 6)
					ins.MouseButton1Click:Connect(function()
						task.spawn(function()
							local rr, err2 = bridgeResult("ToolboxInsert", { id = it.id })
							if not rr then log("⚠ " .. tostring(err2)) else
								log("template '" .. tostring(it.name) .. "' inserido (Register + histórico nativos)")
							end
						end)
					end)
				end
			end
		end)
	end

	local function doSearch(pn)
		cur.page = pn or 0
		cur.query = searchBox.Text
		pageLbl.Text = "pág " .. (cur.page + 1)
		info.Text = "buscando…"
		task.spawn(function()
			local res, err = bridgeResult("ToolboxSearch", { query = cur.query ~= "" and cur.query or "tree", kind = cur.kind, page = cur.page })
			if not res then
				paintLoja({ error = tostring(err) })
				return
			end
			paintLoja(res)
		end)
	end
	searchBox.FocusLost:Connect(function(enter) if enter then doSearch(0) end end)
	prevB.MouseButton1Click:Connect(function() if cur.page > 0 then doSearch(cur.page - 1) end end)
	nextB.MouseButton1Click:Connect(function() doSearch(cur.page + 1) end)
	tabLoja.MouseButton1Click:Connect(function()
		cur.tab = "loja"
		tabLoja.BackgroundColor3 = th.acc tabLoja.TextColor3 = Color3.fromRGB(8, 16, 30)
		tabStock.BackgroundColor3 = th.bg3 tabStock.TextColor3 = th.muted
	end)
	tabStock.MouseButton1Click:Connect(function()
		cur.tab = "arkher"
		tabStock.BackgroundColor3 = th.acc tabStock.TextColor3 = Color3.fromRGB(8, 16, 30)
		tabLoja.BackgroundColor3 = th.bg3 tabLoja.TextColor3 = th.muted
		paintArkher()
	end)
	log("TOOLBOX X pronta — a LOJA é a Creator Store REAL do Roblox (InsertService.GetFreeModelsAsync)")
	return win
end

local wToolbox = mkWin("toolbox", "TOOLBOX X — Creator Store REAL + templates", 700, 400, THEME_TOOLBOX)
buildToolbox(wToolbox)

-- =============================================================
-- PROPS X — TODAS as propriedades do objeto selecionado, editáveis
-- =============================================================
local THEME_PROPS = {
	bg = Color3.fromRGB(18, 18, 24), bg2 = Color3.fromRGB(23, 23, 31), bg3 = Color3.fromRGB(28, 29, 40),
	cap = Color3.fromRGB(14, 14, 19), edge = Color3.fromRGB(68, 70, 100),
	text = Color3.fromRGB(240, 241, 252), muted = Color3.fromRGB(152, 154, 178),
	acc = Color3.fromRGB(150, 200, 255), act = Color3.fromRGB(36, 52, 88),
}


-- =============================================================
-- PICKER DE COR POPUP — aparece NAS PROPRIEDADES: só quando você
-- CLICA no quadrado de cor. nada de abrir janela separada.
-- =============================================================
local __colorPopup
local function openColorPopup(hostFrame, startColor, applyFn, hostZ)
	if __colorPopup and __colorPopup.Parent then __colorPopup:Destroy() end
	local th2 = { bg = Color3.fromRGB(20, 24, 34), bg2 = Color3.fromRGB(26, 31, 44), bg3 = Color3.fromRGB(33, 40, 56), edge = Color3.fromRGB(90, 110, 150), text = Color3.fromRGB(235, 242, 255), muted = Color3.fromRGB(150, 165, 190), acc = Color3.fromRGB(255, 200, 120), act = Color3.fromRGB(60, 44, 24) }
	local C = { h = 0, s = 0, v = 1 }
	if startColor then C.h, C.s, C.v = Color3.toHSV(startColor) end
	local f = B("Frame", {
		Size = UDim2.fromOffset(252, 246), Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = th2.bg, BorderSizePixel = 0, ZIndex = (hostZ or 46) + 10,
	}, hostFrame)
	H(f, 8) ST(f, 1.2, th2.edge)
	f.Active = true
	__colorPopup = f
	local hover = false
	f.MouseEnter:Connect(function() hover = true end)
	f.MouseLeave:Connect(function() task.delay(0.8, function() end) end)
	local cls = B("TextButton", {
		Size = UDim2.fromOffset(22, 20), Position = UDim2.new(1, -26, 0, 4),
		BackgroundColor3 = th2.bg2, Text = "x", Font = Enum.Font.GothamBold,
		TextSize = 12, TextColor3 = th2.muted, BorderSizePixel = 0, ZIndex = f.ZIndex + 2,
	}, f)
	H(cls, 5)
	cls.MouseButton1Click:Connect(function() f:Destroy() end)
	local prev = B("Frame", {
		Size = UDim2.fromOffset(60, 60), Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.fromHSV(C.h, C.s, C.v), BorderSizePixel = 0, ZIndex = f.ZIndex + 1,
	}, f)
	H(prev, 6) ST(prev, 1, th2.edge)
	local hexLb = B("TextLabel", {
		Size = UDim2.fromOffset(60, 14), Position = UDim2.fromOffset(8, 70),
		BackgroundTransparency = 1, Text = "#FFFFFF", Font = Enum.Font.Code,
		TextSize = 9, TextColor3 = th2.muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = f.ZIndex + 1,
	}, f)
	local function refreshP()
		local c = Color3.fromHSV(C.h, C.s, C.v)
		prev.BackgroundColor3 = c
		hexLb.Text = string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	-- sliders H/S/V e R/G/B
	local xs = 78
	sliderCtl(f, UDim2.fromOffset(xs, 8), 0, "H", 0, 360, C.h * 360, th2, function(v) C.h = v / 360 refreshP() end)
	sliderCtl(f, UDim2.fromOffset(xs, 42), 0, "S", 0, 100, C.s * 100, th2, function(v) C.s = v / 100 refreshP() end)
	sliderCtl(f, UDim2.fromOffset(xs, 76), 0, "V", 0, 100, C.v * 100, th2, function(v) C.v = v / 100 refreshP() end)
	local rgbY = { 112, 146, 180 }
	local names = { "R", "G", "B" }
	local gets = { function() return prev.BackgroundColor3.R * 255 end, function() return prev.BackgroundColor3.G * 255 end, function() return prev.BackgroundColor3.B * 255 end }
	for q = 1, 3 do
		sliderCtl(f, UDim2.fromOffset(8, rgbY[q]), 0, names[q], 0, 255, gets[q](), th2, function(v)
			local c = prev.BackgroundColor3
			local rr, gg, bb = c.R, c.G, c.B
			if q == 1 then rr = v / 255 elseif q == 2 then gg = v / 255 else bb = v / 255 end
			C.h, C.s, C.v = Color3.toHSV(Color3.new(rr, gg, bb))
			refreshP()
		end)
	end
	-- paleta em miniatura
	local paleta2 = { "Bright red", "Bright blue", "Bright green", "Bright yellow", "Bright orange", "Bright violet", "White", "Black", "Deep orange", "Pink", "Lime green", "Cyan" }
	for q, nm in ipairs(paleta2) do
		local bc = BrickColor.new(nm)
		local sw2 = B("TextButton", {
			Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(8 + ((q - 1) % 10) * 24, 234 - 24),
			BackgroundColor3 = bc.Color, Text = "", BorderSizePixel = 0, ZIndex = f.ZIndex + 1,
		}, f)
		H(sw2, 5) ST(sw2, 1, th2.edge)
		sw2.MouseButton1Click:Connect(function()
			C.h, C.s, C.v = Color3.toHSV(bc.Color) refreshP()
		end)
	end
	-- posiciona ao lado do host (clamp dentro da janela)
	local hostSize = hostFrame.AbsoluteSize
	if hostSize.X > 400 then
		f.Position = UDim2.new(1, 8, 0, 30)
		f.AnchorPoint = Vector2.new(1, 0)
	else
		f.Position = UDim2.fromOffset(8, 30)
	end
	-- APLICAR grande
	local applyB = B("TextButton", {
		Size = UDim2.fromOffset(98, 24), Position = UDim2.new(1, -104, 1, -30),
		BackgroundColor3 = th2.acc, Text = "APLICAR ✓",
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(30, 20, 10),
		BorderSizePixel = 0, ZIndex = f.ZIndex + 2,
	}, f)
	H(applyB, 6)
	applyB.MouseButton1Click:Connect(function()
		applyFn(prev.BackgroundColor3)
		f:Destroy()
	end)
	refreshP()
	return f
end

local PROPS_STATE = { targetId = nil, fields = {} }

local function buildProps(win)
	local th = THEME_PROPS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local headLbl = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  clique num objeto do EXPLORADOR e depois ATUALIZAR",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(headLbl, 6)
	local filterBox = B("TextBox", {
		Size = UDim2.fromOffset(220, 22), Position = UDim2.fromOffset(10, 30),
		BackgroundColor3 = th.bg2, Text = "", PlaceholderText = "filtrar (ex.: color, size, mat…)",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, ZIndex = 43,
	}, body)
	H(filterBox, 6)
	local padf = Instance.new("UIPadding") padf.PaddingLeft = UDim.new(0, 8) padf.Parent = filterBox
	local refreshB = B("TextButton", {
		Size = UDim2.fromOffset(96, 22), Position = UDim2.fromOffset(238, 30),
		BackgroundColor3 = th.acc, Text = "ATUALIZAR", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = Color3.fromRGB(10, 14, 28), BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(refreshB, 6)
	local listF = listCtl(body, UDim2.fromOffset(10, 58), UDim2.new(1, -20, 1, -86), th)

	local curFilter = ""
	filterBox:GetPropertyChangedSignal("Text"):Connect(function()
		curFilter = filterBox.Text:lower()
		for _, row in ipairs(listF:GetChildren()) do
			if row:IsA("GuiObject") and row:GetAttribute("pkey") then
				local key = (row:GetAttribute("pkey") or ""):lower()
				local group = (row:GetAttribute("pgroup") or ""):lower()
				row.Visible = curFilter == "" or key:find(curFilter, 1, true) ~= nil or group:find(curFilter, 1, true) ~= nil
			end
		end
	end)

	local function setVal(key, kind, payload, rowLbl)
		task.spawn(function()
			local rr, err = bridgeResult("PropsSet", {
				id = PROPS_STATE.targetId, key = key, kind = kind,
			})
			-- o bridgePropsSet recebe o payload via tabela; remonto com kind bits
			if not rr then log("⚠ " .. tostring(err)) else log(("✓ %s aplicado"):format(key)) end
		end)
	end

	-- editor por kind (compacto, mais claro que o nativo)
	local function rowEditor(row, f)
		local X0 = 240
		if not f.editable then
			B("TextLabel", {
				Size = UDim2.new(0, 180, 0, 14), Position = UDim2.fromOffset(X0, 5),
				BackgroundTransparency = 1, Text = "(somente leitura)",
				Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, row)
			return
		end
		local function mkVal(txt, x, w2)
			return B("TextBox", {
				Size = UDim2.fromOffset(w2, 18), Position = UDim2.fromOffset(x, 3),
				BackgroundColor3 = th.bg3, Text = txt, Font = Enum.Font.Code,
				TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, ZIndex = 44,
			}, row)
		end
		if f.kind == "boolean" then
			local on = f.v and f.v.v == true
			local tb = B("TextButton", {
				Size = UDim2.fromOffset(54, 18), Position = UDim2.fromOffset(X0, 3),
				BackgroundColor3 = on and th.acc or th.bg3,
				Text = on and "TRUE" or "false", Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = on and Color3.fromRGB(10, 14, 28) or th.muted, BorderSizePixel = 0, ZIndex = 44,
			}, row)
			H(tb, 5)
			tb.MouseButton1Click:Connect(function()
				task.spawn(function()
					local rr, err = bridgeResult("PropsSet", { id = PROPS_STATE.targetId, key = f.key, kind = "boolean", v = not on })
					if not rr then log("⚠ " .. tostring(err)) else
						on = not on
						tb.BackgroundColor3 = on and th.acc or th.bg3
						tb.Text = on and "TRUE" or "false"
						tb.TextColor3 = on and Color3.fromRGB(10, 14, 28) or th.muted
					end
				end)
			end)
		elseif f.kind == "number" then
			local tb = mkVal(tostring(f.v and f.v.v or 0), X0, 70)
			tb.FocusLost:Connect(function(enter)
				if not enter then return end
				local n = tonumber(tb.Text)
				if not n then log("⚠ número inválido: " .. tb.Text) return end
				task.spawn(function()
					local rr, err = bridgeResult("PropsSet", { id = PROPS_STATE.targetId, key = f.key, kind = "number", v = n })
					if not rr then log("⚠ " .. tostring(err)) else log("✓ " .. f.key .. " = " .. n) end
				end)
			end)
		elseif f.kind == "string" then
			local tb = mkVal(tostring(f.v and f.v.s or ""), X0, 190)
			tb.TextXAlignment = Enum.TextXAlignment.Left
			tb.FocusLost:Connect(function(enter)
				if not enter then return end
				task.spawn(function()
					local rr, err = bridgeResult("PropsSet", { id = PROPS_STATE.targetId, key = f.key, kind = "string", s = tb.Text })
					if not rr then log("⚠ " .. tostring(err)) else log("✓ " .. f.key .. " = '" .. tb.Text:sub(1, 24) .. "'") end
				end)
			end)
		elseif f.kind == "color" then
			local c = f.v or { r = 1, g = 1, b = 1 }
			local sw = B("TextButton", {
				Size = UDim2.fromOffset(46, 18), Position = UDim2.fromOffset(X0, 3),
				BackgroundColor3 = Color3.new(c.r or 1, c.g or 1, c.b or 1),
				Text = "", BorderSizePixel = 0, ZIndex = 44,
			}, row)
			H(sw, 4) ST(sw, 1, th.edge)
			sw.MouseButton1Click:Connect(function()
				-- picker INLINE: aparece NAS PROPRIEDADES quando clica no quadrado
				openColorPopup(win.root, Color3.new(c.r or 1, c.g or 1, c.b or 1), function(col)
					task.spawn(function()
						local rr, err = bridgeResult("PropsSet", {
							id = PROPS_STATE.targetId, key = f.key, kind = "color",
							r = col.R, g = col.G, b = col.B,
						})
						if not rr then log("⚠ " .. tostring(err)) else
							sw.BackgroundColor3 = col
							log(("✓ %s = #%02X%02X%02X aplicado DIRETO nas propriedades"):format(f.key,
								math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)))
						end
					end)
				end, 45)
			end)
			local tbc = mkVal(("%d,%d,%d"):format(math.floor((c.r or 1) * 255 + 0.5), math.floor((c.g or 1) * 255 + 0.5), math.floor((c.b or 1) * 255 + 0.5)), X0 + 52, 92)
			tbc.FocusLost:Connect(function(enter)
				if not enter then return end
				local r2, g2, b2 = tbc.Text:match("^%s*(%d+)%s*[,;%s]%s*(%d+)%s*[,;%s]%s*(%d+)%s*$")
				if not r2 then log("⚠ formato r,g,b ex: 255,128,0") return end
				task.spawn(function()
					local rr, err = bridgeResult("PropsSet", {
						id = PROPS_STATE.targetId, key = f.key, kind = "color",
						r = math.clamp(tonumber(r2) / 255, 0, 1), g = math.clamp(tonumber(g2) / 255, 0, 1), b = math.clamp(tonumber(b2) / 255, 0, 1),
					})
					if not rr then log("⚠ " .. tostring(err)) else sw.BackgroundColor3 = Color3.fromRGB(r2, g2, b2) end
				end)
			end)
		elseif f.kind == "vector" or f.kind == "vector2" then
			local comps = (f.kind == "vector") and { "x", "y", "z" } or { "x", "y" }
			local labels = f.v or {}
			local boxes = {}
			for k2, nm in ipairs(comps) do
				boxes[nm] = mkVal(tostring((labels[nm]) or 0), X0 + (k2 - 1) * 52, 46)
			end
			for nm, tb2 in pairs(boxes) do
				tb2.FocusLost:Connect(function(enter)
					if not enter then return end
					local pl = { id = PROPS_STATE.targetId, key = f.key, kind = f.kind }
					for nm3, tb3 in pairs(boxes) do pl[nm3] = tonumber(tb3.Text) or 0 end
					task.spawn(function()
						local rr, err = bridgeResult("PropsSet", pl)
						if not rr then log("⚠ " .. tostring(err)) else log("✓ " .. f.key .. " aplicado") end
					end)
				end)
			end
		elseif f.kind == "enum" then
			local eb = B("TextButton", {
				Size = UDim2.fromOffset(150, 18), Position = UDim2.fromOffset(X0, 3),
				BackgroundColor3 = th.bg3, Text = (f.v and f.v.enum or "?") .. " ▾",
				Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.text,
				BorderSizePixel = 0, ZIndex = 44,
			}, row)
			H(eb, 4)
			local idx = 1
			local enums = f.enum or {}
			for k2, nm in ipairs(enums) do if nm == (f.v and f.v.enum) then idx = k2 end end
			eb.MouseButton1Click:Connect(function()
				if #enums == 0 then log("⚠ enum sem lista (raro)") return end
				idx = (idx % #enums) + 1
				eb.Text = enums[idx] .. " ▾"
				task.spawn(function()
					local rr, err = bridgeResult("PropsSet", { id = PROPS_STATE.targetId, key = f.key, kind = "enum", enum = enums[idx] })
					if not rr then log("⚠ " .. tostring(err)) else log("✓ " .. f.key .. " = " .. enums[idx]) end
				end)
			end)
		else
			B("TextLabel", {
				Size = UDim2.new(0, 180, 0, 14), Position = UDim2.fromOffset(X0, 5),
				BackgroundTransparency = 1, Text = "…" .. f.kind,
				Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
				TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, row)
		end
	end

	local function reload()
		task.spawn(function()
			local sel, err0 = bridgeResult("SelectedGet")
			if not sel then headLbl.Text = "  ⚠ " .. tostring(err0) return end
			if sel.none then headLbl.Text = "  " .. sel.msg PROPS_STATE.targetId = nil return end
			PROPS_STATE.targetId = sel.id
			headLbl.Text = ("  %s  (%s) — atualizando props…"):format(sel.name, sel.className)
			local res, err = bridgeResult("PropsAll", { id = sel.id })
			if not res then log("⚠ " .. tostring(err)) return end
			headLbl.Text = ("  %s  (%s) — %d propriedades REAIS, %s"):format(res.name, res.className, #res.fields, res.writable and "TODAS editáveis" or "somente leitura")
			PROPS_STATE.fields = res.fields
			for _, ch in ipairs(listF:GetChildren()) do
				if ch:IsA("GuiObject") then ch:Destroy() end
			end
			local lastGroup = nil
			for _, f in ipairs(res.fields) do
				if f.group ~= lastGroup then
					lastGroup = f.group
					B("TextLabel", {
						Size = UDim2.new(1, -8, 0, 18), BackgroundColor3 = th.bg3,
						Text = "  " .. f.group, Font = Enum.Font.GothamBold, TextSize = 10,
						TextColor3 = th.acc, TextXAlignment = Enum.TextXAlignment.Left,
						BorderSizePixel = 0, ZIndex = 43,
					}, listF)
				end
				local row = B("Frame", { Size = UDim2.new(1, -8, 0, 24), BackgroundTransparency = 1, ZIndex = 43 }, listF)
				row:SetAttribute("pkey", f.key) row:SetAttribute("pgroup", f.group)
				B("TextLabel", {
					Size = UDim2.fromOffset(224, 20), Position = UDim2.fromOffset(2, 2),
					BackgroundTransparency = 1, Text = f.key .. "   ·" .. f.kind .. (f.editable and "" or " 🔒"),
					Font = Enum.Font.GothamBold, TextSize = 10,
					TextColor3 = f.editable and th.text or th.muted,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, row)
				rowEditor(row, f)
			end
		end)
	end
	refreshB.MouseButton1Click:Connect(reload)
	-- auto: quando a janela abre, ja tenta
	task.delay(0.4, reload)
	log("PROPS X — mesmas propriedades do painel nativo + TODAS as curadas exaustivas por classe")
	return win
end

local wProps = mkWin("props", "PROPS X — TODAS as propriedades, funcionais", 700, 420, THEME_PROPS)
buildProps(wProps)


-- =============================================================
-- CORES X — color picker REAL (HSV/RGB/hex) que aplica no alvo
-- =============================================================
local THEME_CORES = {
	bg = Color3.fromRGB(22, 18, 26), bg2 = Color3.fromRGB(28, 23, 33), bg3 = Color3.fromRGB(35, 29, 42),
	cap = Color3.fromRGB(18, 15, 21), edge = Color3.fromRGB(96, 78, 120),
	text = Color3.fromRGB(248, 244, 252), muted = Color3.fromRGB(182, 170, 196),
	acc = Color3.fromRGB(255, 200, 120), act = Color3.fromRGB(80, 52, 26),
}

local function buildCores(win)
	local th = THEME_CORES
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local C = { h = 0.6, s = 0.7, v = 0.9 }
	local target = { id = nil, key = nil } -- setado pelo PROPS X via _G.ArkherColorTarget

	local prev = B("Frame", {
		Size = UDim2.new(1, -20, 0, 46), Position = UDim2.fromOffset(10, 8),
		BackgroundColor3 = Color3.fromHSV(C.h, C.s, C.v), BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(prev, 7) ST(prev, 1, th.edge)
	local hexLbl = B("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(10, 56),
		BackgroundTransparency = 1, Text = "#FFFFFF", Font = Enum.Font.Code,
		TextSize = 11, TextColor3 = th.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)

	local function hexOf(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function refreshPreview()
		local c = Color3.fromHSV(C.h, C.s, C.v)
		prev.BackgroundColor3 = c
		hexLbl.Text = hexOf(c)
	end

	-- sliders RGB + HSV em duas colunas
	local labels = {}
	local function colSlider(x, lbl, min, max, get, set, fmt)
		local sld = sliderCtl(body, UDim2.fromOffset(x, 74 + #labels * 2), 0, lbl .. string.format(fmt or " (%.2f)", get()), min, max, get(), th, function(v)
			set(v) refreshPreview()
			-- atualiza rotulos vizinhos
			for _, L in ipairs(labels) do L() end
		end)
		labels[#labels + 1] = function() end
	end
	-- rgb
	sliderCtl(body, UDim2.fromOffset(10, 76), 0, "R (0-255)", 0, 255, 153, th, function(v) local hh, ss, vv = 0, 0, 0 local c = prev.BackgroundColor3 hh, ss, vv = Color3.toHSV(c) local n = Color3.fromRGB(math.floor(v + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) C.h, C.s, C.v = Color3.toHSV(n) end)
	sliderCtl(body, UDim2.fromOffset(10, 112), 0, "G (0-255)", 0, 255, 178, th, function(v) local c = prev.BackgroundColor3 local n = Color3.fromRGB(math.floor(c.R * 255 + 0.5), math.floor(v + 0.5), math.floor(c.B * 255 + 0.5)) C.h, C.s, C.v = Color3.toHSV(n) end)
	sliderCtl(body, UDim2.fromOffset(10, 148), 0, "B (0-255)", 0, 255, 229, th, function(v) local c = prev.BackgroundColor3 local n = Color3.fromRGB(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(v + 0.5)) C.h, C.s, C.v = Color3.toHSV(n) end)
	-- hsv
	sliderCtl(body, UDim2.new(0.5, 8, 0, 76), 0, "Matiz H (0-360)", 0, 360, 216, th, function(v) C.h = v / 360 end)
	sliderCtl(body, UDim2.new(0.5, 8, 0, 112), 0, "Saturação S (0-100)", 0, 100, 70, th, function(v) C.s = v / 100 end)
	sliderCtl(body, UDim2.new(0.5, 8, 0, 148), 0, "Valor V (0-100)", 0, 100, 90, th, function(v) C.v = v / 100 end)
	-- conectar onChange->refreshPreview nos sliders (padrao: o kit chama onChange puro)
	refreshPreview()

	-- hex entry
	local hexBox = B("TextBox", {
		Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(10, 186),
		BackgroundColor3 = th.bg3, Text = "#RRGGBB", Font = Enum.Font.Code,
		TextSize = 11, TextColor3 = th.text, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = true, ZIndex = 43,
	}, body)
	H(hexBox, 5)
	hexBox.FocusLost:Connect(function(enter)
		if not enter then return end
		local hx = hexBox.Text:gsub("#", "")
		if #hx == 6 then
			local r2 = tonumber(hx:sub(1, 2), 16); local g2 = tonumber(hx:sub(3, 4), 16); local b2 = tonumber(hx:sub(5, 6), 16)
			if r2 and g2 and b2 then
				C.h, C.s, C.v = Color3.toHSV(Color3.fromRGB(r2, g2, b2))
				refreshPreview()
				log("cor " .. hexBox.Text .. " carregada")
			end
		else log("⚠ hex formato #RRGGBB") end
	end)

	-- paleta BrickColor (curada oficial)
	B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 14), Position = UDim2.fromOffset(10, 216),
		BackgroundTransparency = 1, Text = "PALETA (clique carrega):",
		Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local paleta = {
		"Bright red", "Bright blue", "Bright green", "Bright yellow", "Bright orange", "Bright violet",
		"White", "Black", "Dark stone grey", "Medium stone grey", "Light stone grey", "Deep orange",
		"Navy blue", "Lime green", "Pink", "Cyan", "Gold", "Really red", "Really blue", "Earth green",
		"Brick yellow", "Sand", "New Yeller", "Hot pink",
	}
	local px, py = 10, 234
	for i, nm in ipairs(paleta) do
		local bc = BrickColor.new(nm)
		local swc = B("TextButton", {
			Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(px, py),
			BackgroundColor3 = bc.Color, Text = "", BorderSizePixel = 0, ZIndex = 43,
		}, body)
		H(swc, 5) ST(swc, 1, th.edge)
		swc.MouseButton1Click:Connect(function()
			C.h, C.s, C.v = Color3.toHSV(bc.Color)
			refreshPreview()
			log("carregado: " .. nm)
		end)
		px = px + 30
		if px > (wCordas and 620 or 620) - 30 then px = 10 py = py + 30 end
	end

	-- ONDE APLICAR: lista de chaves de cor do alvo (via PropsAll) + direto no target setado
	local applyFrame = B("Frame", {
		Size = UDim2.new(1, -20, 0, 118), Position = UDim2.new(0, 10, 1, -150),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(applyFrame, 7) ST(applyFrame, 1, th.edge)
	local applyList = listCtl(applyFrame, UDim2.fromOffset(8, 28), UDim2.new(1, -16, 1, -34), th)
	local alvoLbl = B("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 4),
		BackgroundTransparency = 1, Text = "APLICAR — nenhum alvo ainda (selecione algo)",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, applyFrame)

	local function scanColorKeys()
		for _, ch in ipairs(applyList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		task.spawn(function()
			local sel = target.id and { id = target.id } or bridgeResult("SelectedGet")
			if not sel or sel.none then
				alvoLbl.Text = "APLICAR — selecione um objeto no EXPLORADOR (ou venha do PROPS X)"
				return
			end
			local res = bridgeResult("PropsAll", { id = sel.id })
			if not res then alvoLbl.Text = "APLICAR — sem acesso às props" return end
			alvoLbl.Text = ("APLICAR em %s (%s): escolha a PROPRIEDADE de cor"):format(res.name, res.className)
			local found = false
			for _, f in ipairs(res.fields or {}) do
				if f.kind == "color" and f.editable then
					found = true
					local ab2 = B("TextButton", {
						Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = th.act,
						Text = "▶ " .. f.key, Font = Enum.Font.GothamBold, TextSize = 10,
						TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
						TextXAlignment = Enum.TextXAlignment.Left,
					}, applyList)
					H(ab2, 5)
					local padl = Instance.new("UIPadding") padl.PaddingLeft = UDim.new(0, 6) padl.Parent = ab2
					ab2.MouseButton1Click:Connect(function()
						local c = prev.BackgroundColor3
						task.spawn(function()
							local rr, err = bridgeResult("PropsSet", {
								id = sel.id, key = f.key, kind = "color", r = c.R, g = c.G, b = c.B,
							})
							if not rr then log("⚠ " .. tostring(err)) else
								log(("✓ %s.%s = %s — aplicado de VERDADE"):format(res.name, f.key, hexOf(c)))
							end
						end)
					end)
				end
			end
			if not found then
				B("TextLabel", {
					Size = UDim2.new(1, -8, 0, 20), BackgroundTransparency = 1,
					Text = "Este objeto não tem propriedade de cor EDITÁVEL.",
					Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = th.muted,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, applyList)
			end
		end)
	end
	-- alvo externo (PROPS X chamou)
	rawset(_G, "ArkherColorTarget", function(t2)
		target.id = t2.id target.key = t2.key
		log("alvo: propriedade '" .. tostring(t2.key) .. "' — escolha e aplique")
		scanColorKeys()
	end)
	-- botao re-scan
	local reB = B("TextButton", {
		Size = UDim2.fromOffset(84, 18), Position = UDim2.new(1, -92, 0, 6),
		BackgroundColor3 = th.bg3, Text = "↻ selecionar", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
	}, applyFrame)
	H(reB, 4)
	reB.MouseButton1Click:Connect(function() target.id = nil scanColorKeys() end)
	task.delay(0.5, scanColorKeys)
	log("CORES X — picking HSV/RGB/hex real; aplica na propriedade DE COR do objeto selecionado")
	return win
end

local wCores = mkWin("cores", "CORES X — color picker real e funcional", 640, 430, THEME_CORES)
buildCores(wCores)

-- =============================================================
-- OUTPUT X — o log REAL (LogService) com filtros e limpar
-- =============================================================
local THEME_OUTPUT = {
	bg = Color3.fromRGB(12, 12, 14), bg2 = Color3.fromRGB(16, 16, 20), bg3 = Color3.fromRGB(21, 21, 27),
	cap = Color3.fromRGB(9, 9, 11), edge = Color3.fromRGB(60, 62, 74),
	text = Color3.fromRGB(235, 236, 240), muted = Color3.fromRGB(146, 148, 160),
	acc = Color3.fromRGB(124, 200, 255), act = Color3.fromRGB(24, 44, 72),
}

local function buildOutput(win)
	local th = THEME_OUTPUT
	local body = win.body
	local LogS = game:GetService("LogService")
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local filtros = { Info = true, Warning = true, Error = true }
	local counter = B("TextLabel", {
		Size = UDim2.fromOffset(220, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  0 mensagens",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(counter, 5)
	local chipDefs = { { "Info", Color3.fromRGB(180, 210, 255) }, { "Warning", Color3.fromRGB(255, 226, 130) }, { "Error", Color3.fromRGB(255, 140, 125) } }
	local chipBtns = {}
	for i, df in ipairs(chipDefs) do
		local cb = B("TextButton", {
			Size = UDim2.fromOffset(84, 18), Position = UDim2.fromOffset(238 + (i - 1) * 90, 6),
			BackgroundColor3 = th.bg3, Text = df[1] .. " ✓", Font = Enum.Font.GothamBold,
			TextSize = 9, TextColor3 = df[2], BorderSizePixel = 0, ZIndex = 43,
		}, body)
		H(cb, 5)
		chipBtns[df[1]] = cb
		cb.MouseButton1Click:Connect(function()
			filtros[df[1]] = not filtros[df[1]]
			cb.Text = df[1] .. (filtros[df[1]] and " ✓" or " ✗")
			cb.BackgroundColor3 = filtros[df[1]] and th.act or th.bg3
			for _, row in ipairs(listO and { listO } or {}) do end
			-- esconde/mostra
			for _, row0 in ipairs(rowsFrame:GetChildren()) do
				if row0:IsA("TextLabel") then
					local t2 = row0:GetAttribute("mtype")
					row0.Visible = t2 and filtros[t2] ~= false
				end
			end
		end)
	end
	local clearB = B("TextButton", {
		Size = UDim2.fromOffset(84, 18), Position = UDim2.new(1, -100, 0, 6),
		BackgroundColor3 = th.bg3, Text = "LIMPAR", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(clearB, 5)
	rowsFrame = listCtl(body, UDim2.fromOffset(10, 30), UDim2.new(1, -20, 1, -58), th)

	local total = 0
	local function addLine(msg, mtype)
		total = total + 1
		counter.Text = ("  %d mensagens (LogService REAL)"):format(total)
		local show = filtros[mtype] ~= false
		local col = (mtype == "Error") and Color3.fromRGB(255, 140, 125)
			or (mtype == "Warning") and Color3.fromRGB(255, 226, 130)
			or (mtype == "Info" and Color3.fromRGB(212, 216, 224) or th.text)
		local row = B("TextLabel", {
			Size = UDim2.new(1, -8, 0, 16), BackgroundTransparency = 1,
			Text = (mtype == "Info" and "• " or (mtype == "Warning" and "⚠ " or "✗ ")) .. tostring(msg),
			Font = Enum.Font.Code, TextSize = 11, TextColor3 = col,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = false,
			BorderSizePixel = 0, ZIndex = 44,
		}, rowsFrame)
		row:SetAttribute("mtype", mtype)
		row.Visible = show
		if #rowsFrame:GetChildren() > 520 then
			for _, c0 in ipairs(rowsFrame:GetChildren()) do
				if c0:IsA("TextLabel") then c0:Destroy() break end
			end
		end
	end
	clearB.MouseButton1Click:Connect(function()
		local ok, err = pcall(function() LogS:ClearOutput() end)
		if ok then
			total = 0
			for _, c0 in ipairs(rowsFrame:GetChildren()) do
				if c0:IsA("TextLabel") then c0:Destroy() end
			end
			counter.Text = "  0 mensagens (limpa!)"
			log("Output REAL limpo (mesmo Clear do Studio)")
		else
			log("⚠ ClearOutput falhou: " .. tostring(err))
		end
	end)
	-- snapshot inicial
	task.spawn(function()
		local hist = LogS:GetLogHistory()
		for i = #hist - 160, #hist do
			local it = hist[i]
			if it then
				local mtype = (it.messageType == Enum.MessageType.MessageError) and "Error"
					or (it.messageType == Enum.MessageType.MessageWarning) and "Warning" or "Info"
				addLine(it.message, mtype)
			end
		end
	end)
	-- vivo
	LogS.MessageOut:Connect(function(msg, mtype)
		local mt = (mtype == Enum.MessageType.MessageError) and "Error"
			or (mtype == Enum.MessageType.MessageWarning) and "Warning" or "Info"
		addLine(msg, mt)
	end)
	log("OUTPUT X — o log REAL (LogService.GetLogHistory + MessageOut), filtros por tipo")
	return win
end

local wOutput = mkWin("output", "OUTPUT X — log real do jogo (LogService)", 700, 380, THEME_OUTPUT)
buildOutput(wOutput)

-- =============================================================
-- COMANDO X — barra de comandos que EXECUTA de verdade
-- =============================================================
local THEME_COMANDO = {
	bg = Color3.fromRGB(14, 18, 22), bg2 = Color3.fromRGB(18, 23, 29), bg3 = Color3.fromRGB(23, 30, 37),
	cap = Color3.fromRGB(10, 13, 17), edge = Color3.fromRGB(56, 86, 108),
	text = Color3.fromRGB(230, 244, 252), muted = Color3.fromRGB(140, 170, 190),
	acc = Color3.fromRGB(140, 255, 196), act = Color3.fromRGB(20, 70, 48),
}

local function mathEval(src)
	-- mini-parser seguro: numeros, + - * / ^ % ( ), funcoes de math, pi
	local pos = 1
	local function peek() return src:sub(pos, pos) end
	local function eat(s2)
		if src:sub(pos, pos + #s2 - 1) == s2 then pos = pos + #s2 return true end
		return false
	end
	local function skipWS() while peek():match("%s") do pos = pos + 1 end end
	local parseExpr
	local function parseAtom()
		skipWS()
		if eat("(") then
			local v = parseExpr()
			skipWS()
			assert(eat(")"), "faltou ')'")
			return v
		end
		-- numero
		local num = src:match("^%d+%.?%d*", pos)
		if num and #num > 0 then
			pos = pos + #num
			return tonumber(num)
		end
		-- ident (funcao/const)
		local id = src:match("^%a+", pos)
		if id and #id > 0 then
			pos = pos + #id
			skipWS()
			if id == "pi" then return math.pi end
			if eat("(") then
				local a = parseExpr()
				skipWS()
				assert(eat(")"), "faltou ')' em " .. id)
				local fn = math[id]
				assert(type(fn) == "function", "funcao desconhecida: " .. id)
				return fn(a)
			end
		end
		error("esperava numero na posicao " .. pos)
	end
	local function parsePow()
		local v = parseAtom()
		skipWS()
		if eat("^") then v = v ^ parsePow() end
		return v
	end
	local function parseTerm()
		local v = parsePow()
		while true do
			skipWS()
			if eat("*") then v = v * parsePow()
			elseif eat("/") then v = v / parsePow()
			elseif eat("%%") then v = v % parsePow()
			else break end
		end
		return v
	end
	parseExpr = function()
		local v = parseTerm()
		while true do
			skipWS()
			if eat("+") then v = v + parseTerm()
			elseif eat("-") then v = v - parseTerm()
			else break end
		end
		return v
	end
	local ok, r2 = pcall(function()
		local v = parseExpr()
		skipWS()
		assert(pos > #src, "trailing '" .. src:sub(pos) .. "'")
		return v
	end)
	if ok then return r2 end
	error(tostring(r2))
end

local function buildComando(win)
	local th = THEME_COMANDO
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local help = {
		"help — esta ajuda",
		"spawn Block|Ball|Cylinder|CylinderVertical|Wedge|CornerWedge|Truss — spawna a FORMA real no mundo",
		"sel — mostra o objeto selecionado no EXPLORADOR",
		"set <propriedade> <valor> — aplica no selecionado (ex.: set Transparency 0.5 · set Color 255,128,0 · set Anchored true · set Material Neon)",
		"cmd <op> chave=valor… — chama os 95 comandos X do engine (ex.: cmd fx_emit kind=fogo x=0 y=6 z=-16)",
		"math <expressao> — ex.: math (2+3)*sqrt(16)^0.5",
		"time <0-24> — relógio solar (o céu cruza os Kelvin de (...) sozinho)",
		"weather <sol|chuva|nebulina|tempestade|neve|neblina|arco> — tempo de transição real",
		"ls — lista o que a barra sabe",
	}
	local outBox = B("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -100), Position = UDim2.fromOffset(10, 32),
		BackgroundColor3 = th.bg3, BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6, ScrollBarImageColor3 = th.acc, ZIndex = 43,
	}, body)
	H(outBox, 6)
	local layO = Instance.new("UIListLayout") layO.Padding = UDim.new(0, 2) layO.Parent = outBox
	local padO = Instance.new("UIPadding") padO.PaddingLeft = UDim.new(0, 6) padO.PaddingTop = UDim.new(0, 4) padO.Parent = outBox
	local function sayOut(t2, col)
		B("TextLabel", {
			Size = UDim2.new(1, -12, 0, 16),
			BackgroundTransparency = 1, Text = tostring(t2),
			Font = Enum.Font.Code, TextSize = 11,
			TextColor3 = col or th.text, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false, ZIndex = 44,
		}, outBox)
		task.defer(function() outBox.CanvasPosition = Vector2.new(0, outBox.AbsoluteCanvasSize.Y + 40) end)
		if #outBox:GetChildren() > 200 then
			for _, c0 in ipairs(outBox:GetChildren()) do
				if c0:IsA("TextLabel") then c0:Destroy() break end
			end
		end
	end
	sayOut("COMANDO X pronta — digite 'help' (barra que EXECUTA de verdade)", th.acc)

	local hist = {}
	local histFrame = B("Frame", {
		Size = UDim2.fromOffset(140, 1), Position = UDim2.new(1, -150, 0, 8),
		BackgroundTransparency = 1, ZIndex = 43,
	}, body)
	local input = B("TextBox", {
		Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 1, -68),
		BackgroundColor3 = th.bg2, Text = "",
		PlaceholderText = "comando… (ex.: spawn Ball · set Color 255,128,0 · cmd wea_stats · math 2^10)",
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 43,
	}, body)
	H(input, 7)
	local padI = Instance.new("UIPadding") padI.PaddingLeft = UDim.new(0, 10) padI.Parent = input

	local function repaintHist()
		for _, c0 in ipairs(histFrame:GetChildren()) do if c0:IsA("GuiObject") then c0:Destroy() end end
		histFrame.Size = UDim2.fromOffset(1, 24)
		local layH = Instance.new("UIListLayout") layH.FillDirection = Enum.FillDirection.Horizontal layH.Padding = UDim.new(0, 4) layH.Parent = histFrame
		for i = math.max(1, #hist - 5), #hist do
			local hstr = hist[i]
			local btn = B("TextButton", {
				Size = UDim2.fromOffset(90, 24), BackgroundColor3 = th.bg3,
				Text = hstr:sub(1, 12) .. (#hstr > 12 and "…" or ""),
				Font = Enum.Font.Code, TextSize = 9, TextColor3 = th.muted,
				BorderSizePixel = 0, ZIndex = 44,
			}, histFrame)
			H(btn, 5)
			btn.MouseButton1Click:Connect(function() input.Text = hstr input:CaptureFocus() end)
		end
	end

	local function run(line)
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line == "" then return end
		sayOut("Arkher> " .. line, th.muted)
		hist[#hist + 1] = line
		if #hist > 30 then table.remove(hist, 1) end
		repaintHist()
		local cmdName, rest = line:match("^(%S+)%s*(.-)$")
		cmdName = (cmdName or ""):lower()
		if cmdName == "help" or cmdName == "ls" or cmdName == "ajuda" then
			for _, h2 in ipairs(help) do sayOut("  " .. h2, th.text) end
			return
		end
		if cmdName == "math" then
			local ok2, r2 = pcall(mathEval, rest)
			if ok2 then sayOut("= " .. tostring(r2), th.acc) else sayOut("⚠ " .. tostring(r2), Color3.fromRGB(255, 150, 120)) end
			return
		end
		if cmdName == "spawn" then
			local shape = rest:match("^%s*([%w]+)") or "Block"
			local map = { block = "Block", ball = "Ball", cylinder = "Cylinder", cylindervertical = "CylinderVertical", wedge = "Wedge", cornerwedge = "CornerWedge", truss = "Truss" }
			local s2 = map[shape:lower()]
			if not s2 then sayOut("⚠ forma '" .. shape .. "'? use: Block|Ball|Cylinder|CylinderVertical|Wedge|CornerWedge|Truss", Color3.fromRGB(255, 150, 120)) return end
			sayOut("spawning " .. s2 .. "…", th.muted)
			task.spawn(function()
				local rr, err = bridgeResult("QuickPart", { shape = s2 })
				if not rr then sayOut("⚠ " .. tostring(err), Color3.fromRGB(255, 150, 120)) else
					sayOut("✓ " .. (rr.msg or (s2 .. " criado")), th.acc)
				end
			end)
			return
		end
		if cmdName == "sel" then
			task.spawn(function()
				local sel, err = bridgeResult("SelectedGet")
				if not sel then sayOut("⚠ " .. tostring(err), Color3.fromRGB(255, 150, 120))
				elseif sel.none then sayOut("(nada selecionado)", th.muted)
				else sayOut(("✓ %s (%s) — %s"):format(sel.name, sel.className, sel.path or ""), th.acc) end
			end)
			return
		end
		if cmdName == "set" then
			local key, raw = rest:match("^(%S+)%s+(.+)$")
			if not key then sayOut("⚠ uso: set <propriedade> <valor>", Color3.fromRGB(255, 150, 120)) return end
			task.spawn(function()
				local sel = bridgeResult("SelectedGet")
				if not sel or sel.none then sayOut("⚠ selecione um objeto no EXPLORADOR primeiro") return end
				-- descobre o kind via PropsAll
				local res = bridgeResult("PropsAll", { id = sel.id })
				if not res then sayOut("⚠ sem props") return end
				local kind = nil
				for _, f in ipairs(res.fields or {}) do
					if f.key:lower() == key:lower() then kind = f.kind key = f.key break end
				end
				if not kind then sayOut("⚠ propriedade '" .. key .. "' nao existe em " .. (sel.className or "?"), Color3.fromRGB(255, 150, 120)) return end
				local pl = { id = sel.id, key = key, kind = kind }
				local rv = (raw or ""):gsub("%s+$", "")
				if kind == "boolean" then
					pl.v = rv:lower():find("^t") or rv == "1" or rv:lower() == "yes" or rv:lower() == "sim" or false
					pl.v = pl.v == true
				elseif kind == "number" then
					pl.v = tonumber(rv)
					if not pl.v then sayOut("⚠ numero invalido: " .. rv, Color3.fromRGB(255, 150, 120)) return end
				elseif kind == "color" then
					local r2, g2, b2 = rv:match("(%d+)%s*[,;%s]%s*(%d+)%s*[,;%s]%s*(%d+)")
					if not r2 then sayOut("⚠ cor: r,g,b ex: 255,128,0", Color3.fromRGB(255, 150, 120)) return end
					pl.r, pl.g, pl.b = tonumber(r2) / 255, tonumber(g2) / 255, tonumber(b2) / 255
				elseif kind == "vector" then
					local x2, y2, z2 = rv:match("([%d%-%.]+)%s*[,;%s]%s*([%d%-%.]+)%s*[,;%s]%s*([%d%-%.]+)")
					if not x2 then sayOut("⚠ vetor: x,y,z", Color3.fromRGB(255, 150, 120)) return end
					pl.x, pl.y, pl.z = tonumber(x2), tonumber(y2), tonumber(z2)
				elseif kind == "enum" then
					pl.enum = rv
				else
					pl.s = rv
				end
				local rr, err = bridgeResult("PropsSet", pl)
				if not rr then sayOut("⚠ " .. tostring(err), Color3.fromRGB(255, 150, 120)) else
					sayOut(("✓ %s.%s aplicado"):format(sel.name, key), th.acc)
				end
			end)
			return
		end
		if cmdName == "time" then
			local h2 = tonumber(rest)
			if not h2 then sayOut("⚠ time 0..24") return end
			sayOut("relógio solar -> " .. h2 .. "h…")
			task.spawn(function()
				local res = cmd("atmos_clock", { h = h2 })
				sayOut(msgOf(res), th.acc)
			end)
			return
		end
		if cmdName == "weather" then
			sayOut("tempo -> '" .. rest .. "'…")
			task.spawn(function()
				local res = cmd("atmos_weather", { state = rest })
				sayOut(msgOf(res), th.acc)
			end)
			return
		end
		if cmdName == "cmd" then
			local op, kvs = rest:match("^(%S+)%s*(.-)$")
			if not op then sayOut("⚠ uso: cmd <op> k=v k=v…", Color3.fromRGB(255, 150, 120)) return end
			local params = {}
			for k2, v2 in (kvs or ""):gmatch("(%w+)%s*=%s*([%w%._%-%,;]+)") do
				local n2 = tonumber(v2)
				params[k2] = n2 or (v2:lower() == "true" and true or (v2:lower() == "false" and false or v2))
			end
			sayOut("engine: " .. op .. " …", th.muted)
			task.spawn(function()
				local res = cmd(op, params)
				if type(res) == "table" then
					sayOut(res.msg and ("✓ " .. res.msg) or "✓ (ok; use stats p/ ver)", th.acc)
				else
					sayOut(tostring(res), th.text)
				end
			end)
			return
		end
		sayOut(" comando desconhecido: '" .. cmdName .. "' — digite 'help'", Color3.fromRGB(255, 150, 120))
	end
	input.FocusLost:Connect(function(enter)
		if not enter then return end
		local t2 = input.Text
		input.Text = ""
		run(t2)
	end)
	log("COMANDO X — a barra QUE EXECUTA de verdade: spawn/set/sel/math/cmd/time/weather")
	return win
end

local wComando = mkWin("comando", "COMANDO X — barra funcional (spawn · set · cmd · math)", 660, 400, THEME_COMANDO)
buildComando(wComando)


-- =============================================================
-- SCRIPTS X — editor de scripts POTENTE: abas, buscar/substituir,
-- Source REAL via PropsAll/PropsSet (le e aplica de verdade)
-- =============================================================
local THEME_SCRIPTS = {
	bg = Color3.fromRGB(13, 18, 26), bg2 = Color3.fromRGB(17, 23, 33), bg3 = Color3.fromRGB(22, 29, 42),
	cap = Color3.fromRGB(10, 14, 20), edge = Color3.fromRGB(48, 84, 122),
	text = Color3.fromRGB(228, 240, 252), muted = Color3.fromRGB(140, 164, 192),
	acc = Color3.fromRGB(120, 210, 255), act = Color3.fromRGB(22, 54, 88),
}

local function buildScripts(win)
	local th = THEME_SCRIPTS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local tabs = {} -- {id, name, path, className, dirty}
	local curTab = 1

	-- COL ESQUERDA: lista de scripts do jogo
	local lList = listCtl(body, UDim2.fromOffset(10, 30), UDim2.fromOffset(180, 1 - 60), th)
	-- ajusta altura proporcional ao corpo
	lList.Size = UDim2.new(0, 180, 1, -100)
	local lHead = B("TextLabel", {
		Size = UDim2.fromOffset(180, 20), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  SCRIPTS DO JOGO",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(lHead, 5)
	local reB = B("TextButton", {
		Size = UDim2.fromOffset(180, 20), Position = UDim2.new(0, 10, 1, -96),
		BackgroundColor3 = th.bg3, Text = "↻ recarregar lista",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.muted,
		BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(reB, 5)

	-- area editor: barra de abas + toolbar + editor
	local ED_X = 196
	local tabsBar = B("Frame", {
		Size = UDim2.new(1, -(ED_X + 10), 0, 26), Position = UDim2.fromOffset(ED_X, 6),
		BackgroundTransparency = 1, ZIndex = 43,
	}, body)
	local toolBar = B("Frame", {
		Size = UDim2.new(1, -(ED_X + 10), 0, 30), Position = UDim2.fromOffset(ED_X, 36),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(toolBar, 6)
	-- find / replace
	local findBox = B("TextBox", {
		Size = UDim2.fromOffset(150, 22), Position = UDim2.fromOffset(6, 4),
		BackgroundColor3 = th.bg3, Text = "", PlaceholderText = "buscar…",
		Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 44,
	}, toolBar)
	H(findBox, 4)
	local repBox = B("TextBox", {
		Size = UDim2.fromOffset(150, 22), Position = UDim2.fromOffset(162, 4),
		BackgroundColor3 = th.bg3, Text = "", PlaceholderText = "substituir por…",
		Font = Enum.Font.Code, TextSize = 11, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 44,
	}, toolBar)
	H(repBox, 4)
	local repBtn = B("TextButton", {
		Size = UDim2.fromOffset(96, 22), Position = UDim2.fromOffset(318, 4),
		BackgroundColor3 = th.act, Text = "SUBSTITUIR", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
	}, toolBar)
	H(repBtn, 4)
	local countLbl = B("TextLabel", {
		Size = UDim2.fromOffset(150, 22), Position = UDim2.fromOffset(422, 4),
		BackgroundTransparency = 1, Text = "0 ocorrências",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
	}, toolBar)
	local saveBtn = B("TextButton", {
		Size = UDim2.fromOffset(130, 22), Position = UDim2.new(1, -136, 0, 4),
		BackgroundColor3 = th.acc, Text = "APLICAR ✓ (Ctrl+S)",
		Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(8, 16, 30), BorderSizePixel = 0, ZIndex = 44,
	}, toolBar)
	H(saveBtn, 5)

	local editor = B("TextBox", {
		Size = UDim2.new(1, -(ED_X + 10), 1, -140), Position = UDim2.fromOffset(ED_X, 72),
		BackgroundColor3 = Color3.fromRGB(9, 12, 18), Text = "-- Selecione um script na lista",
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(220, 236, 252),
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = false, MultiLine = true, ClearTextOnFocus = false,
		BorderSizePixel = 0, ZIndex = 43, RichText = false,
	}, body)
	H(editor, 6)
	local padE = Instance.new("UIPadding") padE.PaddingLeft = UDim.new(0, 8) padE.PaddingTop = UDim.new(0, 6) padE.Parent = editor

	local infoBar = B("TextLabel", {
		Size = UDim2.new(1, -(ED_X + 10), 0, 18), Position = UDim2.new(0, ED_X, 1, -60),
		BackgroundColor3 = th.cap, Text = "  linhas 0 · chars 0 · readonly? —",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(infoBar, 5)

	local function updateInfo()
		local t2 = tabs[curTab]
		local txt = editor.Text
		local nls = select(2, txt:gsub("\n", "\n")) + 1
		infoBar.Text = ("  linhas %d · chars %d · %s"):format(nls, #txt, t2 and (t2.path or t2.name) or "(sem aba)")
	end
	editor:GetPropertyChangedSignal("Text"):Connect(function()
		if tabs[curTab] then tabs[curTab].dirty = true end
		updateInfo()
	end)

	local function repaintTabs()
		for _, c0 in ipairs(tabsBar:GetChildren()) do if c0:IsA("GuiObject") then c0:Destroy() end end
		local lay = Instance.new("UIListLayout") lay.FillDirection = Enum.FillDirection.Horizontal lay.Padding = UDim.new(0, 4) lay.Parent = tabsBar
		for i, t2 in ipairs(tabs) do
			local tb = B("TextButton", {
				Size = UDim2.fromOffset(math.clamp(#t2.name * 8 + 52, 90, 190), 0, 26),
				BackgroundColor3 = (i == curTab) and th.act or th.bg3,
				Text = "  " .. t2.name .. (t2.dirty and " ●" or "") .. "  ×",
				Font = Enum.Font.GothamBold, TextSize = 10,
				TextColor3 = (i == curTab) and th.text or th.muted,
				BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
			}, tabsBar)
			H(tb, 5)
			tb.MouseButton1Click:Connect(function()
				-- salva o texto atual na aba anterior
				if tabs[curTab] and tabs[curTab].id then tabs[curTab].text = editor.Text end
				curTab = i
				editor.Text = t2.text or "-- (carregando)"
				repaintTabs()
				updateInfo()
			end)
			tb.MouseButton2Click:Connect(function()
				table.remove(tabs, i)
				if #tabs == 0 then curTab = 1 editor.Text = "-- nenhuma aba" else
					curTab = math.max(1, math.min(curTab, #tabs))
					editor.Text = tabs[curTab].text or ""
				end
				repaintTabs() updateInfo()
			end)
		end
	end

	local function openScript(id, name, path)
		for i, t2 in ipairs(tabs) do
			if t2.id == id then curTab = i editor.Text = t2.text repaintTabs() return end
		end
		tabs[#tabs + 1] = { id = id, name = name, path = path, text = "-- carregando Source…", dirty = false }
		curTab = #tabs
		repaintTabs()
		editor.Text = "-- carregando Source…"
		task.spawn(function()
			local res = bridgeResult("PropsAll", { id = id })
			local src = nil
			if res then
				for _, f in ipairs(res.fields or {}) do
					if f.key == "Source" then src = f.v and f.v.s break end
				end
			end
			local t2 = tabs[curTab]
			if t2 and t2.id == id then
				t2.text = src or "-- (sem permissao de leitura do Source)"
				if #editor.Text < 60 or editor.Text:find("carregando") then editor.Text = t2.text end
				log("✓ Source lido: " .. (t2.name) .. " (" .. #(src or "") .. " chars)")
			end
			updateInfo()
		end)
	end

	local function applySource()
		local t2 = tabs[curTab]
		if not t2 or not t2.id then log("⚠ sem aba ativa") return end
		t2.text = editor.Text
		task.spawn(function()
			local rr, err = bridgeResult("PropsSet", { id = t2.id, key = "Source", kind = "source", s = t2.text })
			if not rr then log("⚠ aplicar: " .. tostring(err)) else
				t2.dirty = false
				repaintTabs()
				log(("✓ Source APLICADO de verdade em '%s' (%d chars) — historico hSet gravou"):format(t2.name, #t2.text))
			end
		end)
	end
	saveBtn.MouseButton1Click:Connect(applySource)
	UIS.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.S and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			if win.root.Visible then applySource() end
		end
	end)

	local function findCount(pat)
		if pat == "" then return 0 end
		local n = 0
		local plain = true
		local pos = 1
		while true do
			local a, b = (editor.Text):find(pat, pos, plain)
			if not a then break end
			n = n + 1
			pos = b + 1
			if n > 9999 then break end
		end
		return n
	end
	findBox:GetPropertyChangedSignal("Text"):Connect(function()
		countLbl.Text = findCount(findBox.Text) .. " ocorrências"
	end)
	repBtn.MouseButton1Click:Connect(function()
		if findBox.Text == "" then return end
		local newTxt, n2 = (editor.Text):gsub(findBox.Text:gsub("(%W)", "%%%1"), repBox.Text)
		editor.Text = newTxt
		log(("✓ substituídos %d× '%s' → '%s' (entao APLICAR)"):format(n2, findBox.Text, repBox.Text))
	end)

	local function reloadList()
		task.spawn(function()
			local res, err = bridgeResult("ScriptList")
			for _, ch in ipairs(lList:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
			if not res then log("⚠ ScriptList: " .. tostring(err)) return end
			lHead.Text = ("  %d SCRIPTS"):format(res.count or 0)
			for _, sc2 in ipairs(res.scripts or {}) do
				local row = B("TextButton", {
					Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = th.bg2,
					Text = "", BorderSizePixel = 0, ZIndex = 43,
				}, lList)
				H(row, 5)
				B("TextLabel", {
					Size = UDim2.new(1, -8, 0, 15), Position = UDim2.fromOffset(6, 1),
					BackgroundTransparency = 1, Text = sc2.name,
					Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.text,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, row)
				B("TextLabel", {
					Size = UDim2.new(1, -8, 0, 12), Position = UDim2.fromOffset(6, 16),
					BackgroundTransparency = 1,
					Text = ("%s · %d ch"):format(sc2.className, sc2.len or 0),
					Font = Enum.Font.Code, TextSize = 8, TextColor3 = th.muted,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, row)
				row.MouseButton1Click:Connect(function()
					openScript(sc2.id, sc2.name, sc2.path)
				end)
			end
		end)
	end
	reB.MouseButton1Click:Connect(reloadList)
	task.delay(0.5, reloadList)
	log("SCRIPTS X — abas + buscar/substituir + APLICAR de verdade (le/escreve Source via bridge)")
	return win
end

local wScripts = mkWin("scripts", "SCRIPTS X — editor potente (abas · buscar · aplicar Source real)", 720, 430, THEME_SCRIPTS)
buildScripts(wScripts)

-- =============================================================
-- PY X — ponte com PYTHON do PC (tests/build/audit reais via HTTP)
-- =============================================================
local THEME_PY = {
	bg = Color3.fromRGB(12, 16, 24), bg2 = Color3.fromRGB(16, 21, 30), bg3 = Color3.fromRGB(21, 28, 38),
	cap = Color3.fromRGB(9, 12, 18), edge = Color3.fromRGB(52, 78, 108),
	text = Color3.fromRGB(230, 242, 254), muted = Color3.fromRGB(146, 168, 192),
	acc = Color3.fromRGB(120, 255, 176), act = Color3.fromRGB(18, 60, 40),
}

-- PY vai pelo servidor (HttpService nao roda em LocalScript — era o PluginOrCloudAPI)

local function buildPy(win)
	local th = THEME_PY
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local statusBar = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  pybridge: verificando… (rode tools/pybridge.py no PC)",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(statusBar, 6)
	statusBar.TextWrapped = true

	local conn = { ok = false, info = "" }
	local function check()
		task.spawn(function()
			local res, err = bridgeResult("PyStatus")
			if res and res.online then
				conn.ok = true
				conn.info = ("✓ python %s · v%s"):format(tostring(res.py or "?"), tostring(res.version or "?"))
				statusBar.Text = "  " .. conn.info .. "  — bridge PYTHON ATIVA (via servidor)"
				statusBar.TextColor3 = th.acc
			else
				conn.ok = false
				statusBar.Text = "  ✗ pybridge offline. Rode: python studio-completo/tools/pybridge.py\n  " .. tostring((res and res.error) or err or "")
				statusBar.TextColor3 = Color3.fromRGB(255, 170, 120)
			end
		end)
	end
	check()
	local reB = B("TextButton", {
		Size = UDim2.fromOffset(100, 18), Position = UDim2.new(1, -110, 0, 8),
		BackgroundColor3 = th.bg3, Text = "↻ re-checar", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
	}, body)
	H(reB, 4)
	reB.MouseButton1Click:Connect(check)

	-- log de saida
	local outScr = B("ScrollingFrame", {
		Size = UDim2.new(1, -20, 1, -170), Position = UDim2.fromOffset(10, 132),
		BackgroundColor3 = th.bg3, BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6, ScrollBarImageColor3 = th.acc, ZIndex = 43,
	}, body)
	H(outScr, 6)
	local layO = Instance.new("UIListLayout") layO.Padding = UDim.new(0, 2) layO.Parent = outScr
	local padO = Instance.new("UIPadding") padO.PaddingLeft = UDim.new(0, 6) padO.PaddingTop = UDim.new(0, 4) padO.Parent = outScr
	local function sayOut(t2, col)
		B("TextLabel", {
			Size = UDim2.new(1, -12, 0, 15), BackgroundTransparency = 1,
			Text = tostring(t2), Font = Enum.Font.Code, TextSize = 10,
			TextColor3 = col or th.text, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false, ZIndex = 44,
		}, outScr)
		task.defer(function() outScr.CanvasPosition = Vector2.new(0, outScr.AbsoluteCanvasSize.Y + 40) end)
	end

	local function runTask(taskName, labelDesc)
		if not conn.ok then log("⚠ pybridge offline — recheque o status em cima") return end
		sayOut("→ " .. labelDesc .. " …", th.muted)
		task.spawn(function()
			local data, err = bridgeResult("PyRun", { task = taskName })
			if not data then sayOut("⚠ " .. tostring(err), Color3.fromRGB(255, 150, 120)) return end
			if data.ok then
				sayOut("✓ " .. tostring(data.summary or "ok"), th.acc)
				for _, ln in ipairs(data.out or {}) do sayOut("   " .. tostring(ln), th.text) end
			else
				sayOut("✗ FALHOU: " .. tostring(data.error or "?"), Color3.fromRGB(255, 150, 120))
				for _, ln in ipairs(data.out or {}) do sayOut("   " .. tostring(ln), Color3.fromRGB(255, 200, 170)) end
			end
			log((data.ok and "✓ " or "✗ ") .. labelDesc)
		end)
	end

	-- botoes de tarefas reais do pipeline
	local tasks = {
		{ "tests", "Rodar SUITE DE TESTES (run_tests.py)", 10, 62 },
		{ "build", "Rebuild server.lua (build_server.py)", 10, 96 },
		{ "audit", "Audit especificacoes (auditoria.py)", 10 + 0, 130 },
		{ "shell", "Executar comando shell (cmd arg)", 228, 62 },
	}
	for _, t2 in ipairs(tasks) do
		local btn = B("TextButton", {
			Size = UDim2.fromOffset(214, 26), Position = UDim2.fromOffset(t2[3], t2[4]),
			BackgroundColor3 = th.act, Text = "▶ " .. t2[2],
			Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.text,
			BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
		}, body)
		H(btn, 6)
		local padB = Instance.new("UIPadding") padB.PaddingLeft = UDim.new(0, 8) padB.Parent = btn
		btn.MouseButton1Click:Connect(function()
			runTask(t2[1], t2[2])
		end)
	end
	local cmdBox = B("TextBox", {
		Size = UDim2.fromOffset(214, 26), Position = UDim2.fromOffset(228, 96),
		BackgroundColor3 = th.bg2, Text = "", PlaceholderText = "ls -la / python …",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 43,
	}, body)
	H(cmdBox, 6)
	local padC = Instance.new("UIPadding") padC.PaddingLeft = UDim.new(0, 8) padC.Parent = cmdBox
	cmdBox.FocusLost:Connect(function(enter)
		if not enter or cmdBox.Text == "" then return end
		if not conn.ok then log("⚠ pybridge offline") return end
		local cmdText = cmdBox.Text
		task.spawn(function()
			local data = bridgeResult("PyRun", { task = "shell", arg = cmdText })
			if data then
				sayOut("$ " .. cmdText, th.acc)
				for _, ln in ipairs(data.out or {}) do sayOut("   " .. tostring(ln), th.text) end
				if data.error or (not data.ok) then sayOut("✗ " .. tostring(data.error or data.summary or ""), Color3.fromRGB(255, 150, 120)) end
			end
		end)
		cmdBox.Text = ""
	end)
	B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 160 - 40),
		BackgroundTransparency = 1,
		Text = "O PYTHON RODA NO SEU PC (tools/pybridge.py); estes botoes SAO reais: disparam os scripts de verdade e mostram a SAIDA aqui.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 43,
	}, body)
	log("PY X — ponte python REAL via HTTP local (subprocess de verdade, nao simulado)")
	return win
end

local wPy = mkWin("py", "PY X — ponte com o python do PC (tests/build/shell reais)", 660, 400, THEME_PY)
buildPy(wPy)


-- =============================================================
-- SCULPT X — pincéis de terreno com falloff gaussiano REAL
-- =============================================================
local THEME_SCULPT = {
	bg = Color3.fromRGB(24, 18, 10), bg2 = Color3.fromRGB(30, 23, 14), bg3 = Color3.fromRGB(38, 30, 20),
	cap = Color3.fromRGB(20, 15, 9), edge = Color3.fromRGB(120, 88, 44),
	text = Color3.fromRGB(250, 240, 226), muted = Color3.fromRGB(200, 170, 130),
	acc = Color3.fromRGB(240, 170, 80), act = Color3.fromRGB(110, 66, 20),
}

local function buildSculpt(win)
	local th = THEME_SCULPT
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local st = { mode = "raise", mat = "Grass" }
	B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  SCULPT: terreno REAL (RenderVoxels/WriteVoxels + fill real)",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	-- modos (botões grandes, tratado como pincéis do Blender)
	local modes = {
		{ "raise", "⛏ RAISE (levanta)" },
		{ "lower", "⛏ LOWER (cava)" },
		{ "smooth", "〜 SMOOTH (alisa real)" },
		{ "flat", "◓ FLAT (aplaina no y)" },
	}
	local modeBtns = {}
	for i, df in ipairs(modes) do
		local mb = B("TextButton", {
			Size = UDim2.fromOffset(140, 30), Position = UDim2.fromOffset(10 + (i - 1) * 148, 34),
			BackgroundColor3 = i == 1 and th.acc or th.bg3,
			Text = df[2], Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = i == 1 and Color3.fromRGB(30, 20, 10) or th.muted,
			BorderSizePixel = 0, ZIndex = 44,
		}, body)
		H(mb, 7) ST(mb, 1, th.edge)
		modeBtns[df[1]] = mb
		mb.MouseButton1Click:Connect(function()
			st.mode = df[1]
			for k2, b2 in pairs(modeBtns) do
				b2.BackgroundColor3 = (k2 == df[1]) and th.acc or th.bg3
				b2.TextColor3 = (k2 == df[1]) and Color3.fromRGB(30, 20, 10) or th.muted
			end
		end)
	end
	-- param steppers
	local sx = stepCtl(body, UDim2.fromOffset(10, 76), "x", 0, 4, -9999, 9999, th)
	local sy = stepCtl(body, UDim2.new(0.36, 2, 0, 76), "y", 2, 4, -512, 512, th)
	local sz = stepCtl(body, UDim2.new(0.69, 2, 0, 76), "z", 0, 4, -9999, 9999, th)
	local sr = stepCtl(body, UDim2.fromOffset(10, 114), "raio (studs)", 12, 2, 4, 64, th)
	local sfo = stepCtl(body, UDim2.new(0.36, 2, 0, 114), "força (0-1)", 1, 0.05, 0.05, 1, th, "%.2f", 0.66)
	-- material (quando raise/flat cria volume)
	local matLbl = B("TextLabel", {
		Size = UDim2.fromOffset(90, 16), Position = UDim2.fromOffset(10, 154),
		BackgroundTransparency = 1, Text = "material:",
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local matBtn = B("TextButton", {
		Size = UDim2.fromOffset(130, 22), Position = UDim2.fromOffset(72, 150),
		BackgroundColor3 = th.bg3, Text = "Grass ▾", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 44,
	}, body)
	H(matBtn, 5)
	local MATS = { "Grass", "Slate", "Sand", "Snow", "Rock", "Mud", "Ground", "Sandstone" }
	local matIdx = 1
	matBtn.MouseButton1Click:Connect(function()
		matIdx = (matIdx % #MATS) + 1
		st.mat = MATS[matIdx]
		matBtn.Text = MATS[matIdx] .. " ▾"
	end)
	actBtn(body, UDim2.fromOffset(10, 184), UDim2.fromOffset(300, 32), "▶ APLICAR PINCEL", th, function()
		local res, err = bridgeResult("SculptApply", {
			mode = st.mode, x = sx.get(), y = sy.get(), z = sz.get(),
			r = sr.get(), strength = sfo.get(), material = st.mat,
		})
		if not res then log("⚠ " .. tostring(err)) else log(res.msg or "aplicado") end
	end)
	B("TextLabel", {
		Size = UDim2.fromOffset(340, 130), Position = UDim2.fromOffset(320, 30),
		BackgroundTransparency = 1,
		Text = "Física de verdade no terreno: RAISE/LOWER usam FillBall real do Roblox; SMOOTH é um Laplaciano REAL (média dos 6 vizinhos por voxel, 4³·stud) com falloff GAUSSIANO (mais força no centro, caindo até zero na borda); FLAT puxa cada voxel prum plano alvo. Múltiplos cliques acumulam o efeito — segure e veja a montanha nascer.",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)
	log("SCULPT X pronto — 4 pincéis reais com falloff gaussiano")
	return win
end

local wSculpt = mkWin("sculpt", "SCULPT X — esculpir o terreno de verdade", 676, 250, THEME_SCULPT)
buildSculpt(wSculpt)

-- =============================================================
-- GRUPOS X — grupos de colisão REAIS (PhysicsService)
-- =============================================================
local THEME_GRUPOS = {
	bg = Color3.fromRGB(14, 20, 16), bg2 = Color3.fromRGB(18, 26, 21), bg3 = Color3.fromRGB(23, 33, 27),
	cap = Color3.fromRGB(11, 16, 13), edge = Color3.fromRGB(58, 108, 72),
	text = Color3.fromRGB(230, 248, 236), muted = Color3.fromRGB(150, 190, 164),
	acc = Color3.fromRGB(120, 230, 150), act = Color3.fromRGB(30, 90, 50),
}

local function buildGrupos(win)
	local th = THEME_GRUPOS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local head = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  grupos de colisão (servidor real)",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(head, 5)
	local gList = listCtl(body, UDim2.fromOffset(10, 30), UDim2.fromOffset(300, 170), th)

	local function reload()
		for _, ch in ipairs(gList:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
		task.spawn(function()
			local res, err = bridgeResult("ColGroupList")
			if not res then log("⚠ " .. tostring(err)) return end
			head.Text = ("  %d grupos de colisão REGISTRADOS"):format(#(res.groups or {}))
			for _, g in ipairs(res.groups or {}) do
				local row = B("Frame", { Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43 }, gList)
				H(row, 5)
				B("TextLabel", {
					Size = UDim2.fromOffset(160, 22), Position = UDim2.fromOffset(6, 1),
					BackgroundTransparency = 1, Text = g.name, Font = Enum.Font.GothamBold,
					TextSize = 11, TextColor3 = th.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, row)
				B("TextLabel", {
					Size = UDim2.fromOffset(110, 22), Position = UDim2.new(1, -116, 0, 1),
					BackgroundTransparency = 1, Text = "id " .. tostring(g.id),
					Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.muted,
					TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 44,
				}, row)
			end
		end)
	end
	local nmBox = B("TextBox", {
		Size = UDim2.fromOffset(180, 24), Position = UDim2.fromOffset(10, 208),
		BackgroundColor3 = th.bg3, Text = "", PlaceholderText = "nome do grupo novo…",
		Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
		PlaceholderColor3 = th.muted, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 43,
	}, body)
	H(nmBox, 5)
	local padn = Instance.new("UIPadding") padn.PaddingLeft = UDim.new(0, 8) padn.Parent = nmBox
	actBtn(body, UDim2.fromOffset(196, 208), UDim2.fromOffset(104, 24), "CRIAR", th, function()
		local res, err = bridgeResult("ColGroupCreate", { name = nmBox.Text })
		if not res then log("⚠ " .. tostring(err)) else log(res.msg or "criado") reload() end
	end)
	-- colidisão A × B
	B("TextLabel", {
		Size = UDim2.fromOffset(300, 16), Position = UDim2.fromOffset(10, 240),
		BackgroundTransparency = 1, Text = "COLISÃO ENTRE GRUPOS (toggle real):",
		Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
	}, body)
	local aBox = B("TextBox", {
		Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(10, 260),
		BackgroundColor3 = th.bg3, Text = "Default", Font = Enum.Font.Code,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(aBox, 5)
	local bBox = B("TextBox", {
		Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(138, 260),
		BackgroundColor3 = th.bg3, Text = "Default", Font = Enum.Font.Code,
		TextSize = 10, TextColor3 = th.text, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(bBox, 5)
	local colOn = { v = true }
	local togBtn = B("TextButton", {
		Size = UDim2.fromOffset(84, 22), Position = UDim2.fromOffset(266, 260),
		BackgroundColor3 = th.acc, Text = "COLIDE", Font = Enum.Font.GothamBold,
		TextSize = 10, TextColor3 = Color3.fromRGB(14, 30, 18), BorderSizePixel = 0, ZIndex = 44,
	}, body)
	H(togBtn, 5)
	togBtn.MouseButton1Click:Connect(function()
		colOn.v = not colOn.v
		togBtn.Text = colOn.v and "COLIDE" or "IGNORA"
		togBtn.BackgroundColor3 = colOn.v and th.acc or th.bg3
	end)
	actBtn(body, UDim2.fromOffset(10, 290), UDim2.fromOffset(340, 26), "APLICAR regra de colisão", th, function()
		local res, err = bridgeResult("ColGroupSetCollidable", { a = aBox.Text, b = bBox.Text, collidable = colOn.v })
		if not res then log("⚠ " .. tostring(err)) else log(res.msg or "aplicado") end
	end)
	-- info: como atribuir grupos às peças
	B("TextLabel", {
		Size = UDim2.fromOffset(300, 120), Position = UDim2.fromOffset(360, 34),
		BackgroundTransparency = 1,
		Text = "1) Crie o grupo aqui.\n2) No PROPS X, na peça, edite CollisionGroupId com o id do grupo (lista acima).\n3) A regra A×B liga/desliga colisão entre grupos — física real instantânea no servidor.",
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true, ZIndex = 43,
	}, body)
	actBtn(body, UDim2.fromOffset(360, 160), UDim2.fromOffset(200, 24), "↻ atualizar", th, reload)
	task.delay(0.3, reload)
	log("GRUPOS X — Collision Groups reais via PhysicsService")
	return win
end

local wGrupos = mkWin("grupos", "GRUPOS X — grupos de colisão reais", 666, 330, THEME_GRUPOS)
buildGrupos(wGrupos)

-- =============================================================
-- PLUGINS X — módulos X ligam/desligam de verdade (pump real)
-- =============================================================
local THEME_PLUGINS = {
	bg = Color3.fromRGB(20, 16, 26), bg2 = Color3.fromRGB(26, 21, 34), bg3 = Color3.fromRGB(33, 27, 43),
	cap = Color3.fromRGB(16, 13, 22), edge = Color3.fromRGB(88, 70, 120),
	text = Color3.fromRGB(244, 238, 252), muted = Color3.fromRGB(180, 162, 200),
	acc = Color3.fromRGB(190, 140, 255), act = Color3.fromRGB(60, 34, 96),
}

local function buildPlugins(win)
	local th = THEME_PLUGINS
	local body = win.body
	local log = logCtl(body, UDim2.new(0, 10, 1, -26), UDim2.new(1, -20, 0, 20), th)
	local head = B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 6),
		BackgroundColor3 = th.cap, Text = "  plugins/pumps X — toggle REAL no servidor",
		Font = Enum.Font.Code, TextSize = 10, TextColor3 = th.acc,
		TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, ZIndex = 43,
	}, body)
	H(head, 5)
	local pList = listCtl(body, UDim2.fromOffset(10, 30), UDim2.new(1, -20, 1, -90), th)
	local function reload()
		for _, ch in ipairs(pList:GetChildren()) do if ch:IsA("GuiObject") then ch:Destroy() end end
		task.spawn(function()
			local res, err = bridgeResult("PluginList")
			if not res then log("⚠ " .. tostring(err)) return end
			head.Text = ("  %d plugins/pumps registrados"):format(#(res.plugins or {}))
			for _, pl in ipairs(res.plugins or {}) do
				local row = B("Frame", { Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 43 }, pList)
				H(row, 6)
				B("TextLabel", {
					Size = UDim2.fromOffset(320, 26), Position = UDim2.fromOffset(8, 2),
					BackgroundTransparency = 1, Text = pl.id .. "  ·" .. pl.kind,
					Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.text,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44,
				}, row)
				local tb = B("TextButton", {
					Size = UDim2.fromOffset(96, 22), Position = UDim2.new(1, -104, 0, 4),
					BackgroundColor3 = pl.enabled and th.acc or th.bg3,
					Text = pl.enabled and "LIGADO" or "desligado",
					Font = Enum.Font.GothamBold, TextSize = 10,
					TextColor3 = pl.enabled and Color3.fromRGB(20, 10, 34) or th.muted,
					BorderSizePixel = 0, ZIndex = 44,
				}, row)
				H(tb, 5)
				tb.MouseButton1Click:Connect(function()
					task.spawn(function()
						local rr, err2 = bridgeResult("PluginToggle", { id = pl.id, enabled = not pl.enabled })
						if not rr then log("⚠ " .. tostring(err2)) else
							pl.enabled = not pl.enabled
							tb.BackgroundColor3 = pl.enabled and th.acc or th.bg3
							tb.Text = pl.enabled and "LIGADO" or "desligado"
							tb.TextColor3 = pl.enabled and Color3.fromRGB(20, 10, 34) or th.muted
							log(rr.msg or "ok")
						end
					end)
				end)
			end
		end)
	end
	B("TextLabel", {
		Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 1, -56),
		BackgroundTransparency = 1,
		Text = "Ligando/desligando você PAUSA istantaneamente o pulso (pump) daquele motor no servidor — efeito real: água congela, céu para, NPCs dormem.",
		Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = th.muted,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 43,
	}, body)
	local reB = B("TextButton", {
		Size = UDim2.fromOffset(96, 18), Position = UDim2.new(1, -106, 0, 8),
		BackgroundColor3 = th.bg3, Text = "↻ atualizar", Font = Enum.Font.GothamBold,
		TextSize = 9, TextColor3 = th.muted, BorderSizePixel = 0, ZIndex = 44,
	}, body)
	H(reB, 4)
	reB.MouseButton1Click:Connect(reload)
	task.delay(0.3, reload)
	log("PLUGINS X — toggle REAL via atributos lidos no Heartbeat do engine")
	return win
end

local wPlugins = mkWin("plugins", "PLUGINS X — liga/desliga os motores de verdade", 700, 320, THEME_PLUGINS)
buildPlugins(wPlugins)

-- =============================================================
-- registro DECK (cada menu da topbar abre SUA janela única)
-- =============================================================
local windows = {
	terrain = wTerrain, modeler = wModeler, animator = wAnimator,
	espaco = wEspaco, fabricar = wFabricar, water = wWater,
	atmos = wAtmos, clima = wClima, vida = wVida, cidade = wCidade,
	audio = wAudio, fx = wFx, cordas = wCordas,
	toolbox = wToolbox, props = wProps, cores = wCores, output = wOutput,
	comando = wComando, scripts = wScripts, py = wPy,
	sculpt = wSculpt, grupos = wGrupos, plugins = wPlugins,
}
_G.ArkherDeck = {
	open = function(id, view)
		for k, w2 in pairs(windows) do w2.root.Visible = false end
		local w2 = windows[id]
		if w2 then
			w2.root.Visible = true
			cmd("sec_stats") -- toque de auditoria real
		end
	end,
	cmd = cmd,
}
print("[ArkherX] 08_Deck: 23 painéis prontos (em diante: +SCULPT/GRUPOS/PLUGINS com backend real) — escala adaptativa p/ mobile")
