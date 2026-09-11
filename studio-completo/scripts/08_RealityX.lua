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

-- ---------- ScreenGui ----------
local gui = Instance.new("ScreenGui")
gui.Name = "ArkherDeck"
gui.ResetOnSpawn = false
gui.DisplayOrder = 68
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

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
	}, gui)
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
-- registro DECK (cada menu da topbar abre SUA janela única)
-- =============================================================
local windows = {
	terrain = wTerrain, modeler = wModeler, animator = wAnimator,
	espaco = wEspaco, fabricar = wFabricar, water = wWater,
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
print("[ArkherX] 08_Deck: 6 editores únicos prontos (TERRAIN/WATER/MODELER/ANIMATOR/ESPAÇO/FABRICAR) — abrem pela topbar original")
