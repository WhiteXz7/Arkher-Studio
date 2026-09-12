-- =============================================================
-- Arkher_10_Studio (ROUND 12) — as três peças que o usuário pediu
-- funcionando na UI REAL:
--
--  1) PROPERTIES NA DOCK ORIGINAL (não numa janela nova!):
--     toma conta da PropertiesDock — lista TODAS as propriedades
--     do objeto (CLASSDB server-side + leitura real por pcall),
--     com editors por tipo: checkbox, número, texto, Vector3,
--     dropdown de ENUM real e COLOR PICKER de verdade (gradientes
--     HSV, hue bar, RGB/hex, abre clicando no quadradinho de cor).
--
--  2) O "+" DA HIERARCHY: clicar no + ao lado dos services abre o
--     painel INSERIR OBJETO com o catálogo GIGANTE (ClassList do
--     servidor, 120+ classes com busca e grupo) e insere de
--     verdade via CreateAny (Instance.new real, pcall por classe).
--
--  3) TOOLBOX estilo Roblox Studio: barra de busca, botões
--     Modelos/Decals, grade de cards com THUMBNAIL REAL
--     (rbxthumb), nome/criador, página anterior/próxima, clique =
--     insere no mundo NA FRENTE DA CÂMERA (ToolboxAssetInsert).
--
-- Expõe _G.ArkherStudioDock {toggle(id)} — o botão Toolbox do
-- ribbon (09) alterna a dock da toolbox.
-- =============================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local client = Players.LocalPlayer

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 10_Studio precisa estar dentro de ArkherStudioUI") return end
local i = uiRoot:WaitForChild("ArkherServerClientRuntime", 20)
if not i then warn("[ArkherX] 10: núcleo não achado.") return end
local j = i:WaitForChild("ClientBus", 20)
local k = i:WaitForChild("CoreReady", 20)
if not j or not k then warn("[ArkherX] 10: núcleo incompleto.") return end
local t0 = os.clock()
while not k.Value and i.Parent and os.clock() - t0 < 20 do task.wait(0.04) end
if not k.Value then warn("[ArkherX] 10: núcleo não subiu a tempo.") return end
if not j:Invoke("ClaimPart", { name = "10_Studio", script = script }) then return end

local canvas = uiRoot:FindFirstChild("Canvas")
local popups = canvas and canvas:FindFirstChild("ServerEditorPopups")
local uiscale = canvas and canvas:FindFirstChild("ResponsiveScale")
local dockP = canvas and canvas:FindFirstChild("PropertiesDock")
local dockH = canvas and canvas:FindFirstChild("HierarchyDock")
local host = canvas and canvas:FindFirstChild("ArkherXDeck")

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
local function say(txt, bad)
	W("Message", { text = txt, bad = bad })
end
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
		if not ok then warn("[ArkherX] 10: " .. tostring(err)) end
	end
	pcall(function() btn.Activated:Connect(function(...) fire("A", ...) end) end)
	pcall(function() btn.MouseButton1Click:Connect(function(...) fire("M", ...) end) end)
	btn.Active = true
	btn.Selectable = true
end
local function guiScale()
	local s = (uiscale and uiscale.Scale) or 1
	if s <= 0 then s = 1 end
	return s
end

-- ---------- tema (dark, direto, estilo Studio) ----------
local th = {
	bg = Color3.fromRGB(24, 27, 34), bg2 = Color3.fromRGB(31, 35, 45), panel = Color3.fromRGB(37, 42, 56),
	row = Color3.fromRGB(32, 37, 50), rowAlt = Color3.fromRGB(28, 32, 43), head = Color3.fromRGB(20, 23, 30),
	border = Color3.fromRGB(70, 82, 105), text = Color3.fromRGB(232, 238, 248), muted = Color3.fromRGB(150, 162, 183),
	acc = Color3.fromRGB(54, 145, 240), acc2 = Color3.fromRGB(40, 205, 220), good = Color3.fromRGB(90, 190, 110),
	bad = Color3.fromRGB(240, 110, 95), gold = Color3.fromRGB(235, 185, 80),
}

local function mk(class, parent, props)
	local o = Instance.new(class)
	for p, v in pairs(props or {}) do o[p] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) mk("UICorner", o, { CornerRadius = UDim.new(0, r or 6) }) end
local function stroke(o, c, t2) mk("UIStroke", o, { Color = c or th.border, Thickness = t2 or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end

-- =============================================================
-- PARTE 1 — PROPERTIES NA DOCK ORIGINAL
-- =============================================================
local propsState = { objId = nil, fields = nil, filter = "", list = nil, scroll = nil, colorTarget = nil, enumTarget = nil }

local function selectedId()
	local a2 = i:FindFirstChild("SelectedId")
	if a2 and a2.Value ~= "" then return a2.Value end
	return nil
end

-- ---------- COLOR PICKER (HSV real com gradientes) ----------
local colorWin
local function closeColorWin() if colorWin and colorWin.Parent then colorWin:Destroy() end colorWin = nil propsState.colorTarget = nil end

local function openColorPicker(anchorBtn, field, applyProp)
	if not popups then return end
	closeColorWin()
	local scale = guiScale()
	local ap = anchorBtn.AbsolutePosition
	local cur = field.value or { r = 1, g = 1, b = 1 }
	local H, S, V = Color3.new(cur.r, cur.g, cur.b):ToHSV()
	local fw = 260
	local f = mk("Frame", nil, {
		Name = "ArkherColorPicker", Size = UDim2.fromOffset(fw, 300),
		Position = UDim2.fromOffset(math.clamp(ap.X / scale - 40, 2, 1568 - fw), ap.Y / scale + 26),
		BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 70, Active = true,
	})
	corner(f, 10) stroke(f, th.acc, 1.5)
	mk("TextLabel", f, { Text = "  COR — " .. field.name, Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(4, 4),
		BackgroundTransparency = 1, TextColor3 = th.acc2, Font = Enum.Font.GothamBold, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 71 })

	-- SV box (hue fixo; sat horizontal; val vertical)
	local sv = mk("TextButton", f, { Size = UDim2.fromOffset(170, 150), Position = UDim2.fromOffset(10, 30),
		BackgroundColor3 = Color3.fromHSV(H, 1, 1), Text = "", BorderSizePixel = 0, ZIndex = 71, AutoButtonColor = false })
	corner(sv, 6) stroke(sv, th.border, 1)
	local satL = mk("Frame", sv, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 72 })
	corner(satL, 6)
	mk("UIGradient", satL, { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
	local valL = mk("Frame", sv, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 73 })
	corner(valL, 6)
	mk("UIGradient", valL, { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) })
	local svDot = mk("Frame", sv, { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 74, BorderSizePixel = 0 })
	mk("UICorner", svDot, { CornerRadius = UDim.new(1, 0) }) stroke(svDot, Color3.new(0, 0, 0), 1.4)

	-- Hue bar
	local hue = mk("TextButton", f, { Size = UDim2.fromOffset(16, 150), Position = UDim2.fromOffset(188, 30),
		BackgroundColor3 = Color3.new(1, 1, 1), Text = "", BorderSizePixel = 0, ZIndex = 71, AutoButtonColor = false })
	corner(hue, 4) stroke(hue, th.border, 1)
	local keys = {}
	for q = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(q / 6, Color3.fromHSV(q / 6, 1, 1)) end
	mk("UIGradient", hue, { Rotation = 90, Color = ColorSequence.new(keys) })
	local hueDot = mk("Frame", hue, { Size = UDim2.new(1, 4, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 74, BorderSizePixel = 0 })
	stroke(hueDot, Color3.new(0, 0, 0), 1.2)

	-- preview + inputs
	local prev = mk("Frame", f, { Size = UDim2.fromOffset(56, 30), Position = UDim2.fromOffset(212, 30),
		BackgroundColor3 = Color3.fromHSV(H, S, V), BorderSizePixel = 0, ZIndex = 71 })
	corner(prev, 6) stroke(prev, th.border, 1)

	local function lab(t2, x, y) return mk("TextLabel", f, { Text = t2, Size = UDim2.fromOffset(24, 16),
		Position = UDim2.fromOffset(x, y), BackgroundTransparency = 1, TextColor3 = th.muted,
		Font = Enum.Font.Gotham, TextSize = 10, ZIndex = 71 }) end
	local function inp(x, y, w2, t2)
		local b2 = mk("TextBox", f, { Size = UDim2.fromOffset(w2, 18), Position = UDim2.fromOffset(x, y),
			BackgroundColor3 = th.panel, Text = t2, TextColor3 = th.text, Font = Enum.Font.Gotham,
			TextSize = 11, BorderSizePixel = 0, ZIndex = 71, ClearTextOnFocus = false })
		corner(b2, 4) stroke(b2, th.border, 1)
		return b2
	end
	lab("R", 12, 188) local ri = inp(30, 186, 44, tostring(math.floor(cur.r * 255 + 0.5)))
	lab("G", 80, 188) local gi = inp(98, 186, 44, tostring(math.floor(cur.g * 255 + 0.5)))
	lab("B", 148, 188) local bi = inp(166, 186, 44, tostring(math.floor(cur.b * 255 + 0.5)))
	lab("#", 12, 212) local hex = inp(30, 210, 110, string.format("%02X%02X%02X", cur.r * 255, cur.g * 255, cur.b * 255))
	lab("H", 12, 236) local hi = inp(30, 234, 44, tostring(math.floor(H * 360 + 0.5)))
	lab("S", 80, 236) local si = inp(98, 234, 34, tostring(math.floor(S * 100 + 0.5)))
	lab("V", 148, 236) local vi = inp(166, 234, 34, tostring(math.floor(V * 100 + 0.5)))

	local fireApply
	local function refreshFromHSV(apply)
		local c3 = Color3.fromHSV(H, S, V)
		sv.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
		prev.BackgroundColor3 = c3
		svDot.Position = UDim2.new(S, 0, 1 - V, 0)
		hueDot.Position = UDim2.new(0.5, 0, H, 0)
		ri.Text = tostring(math.floor(c3.R * 255 + 0.5))
		gi.Text = tostring(math.floor(c3.G * 255 + 0.5))
		bi.Text = tostring(math.floor(c3.B * 255 + 0.5))
		hex.Text = string.format("%02X%02X%02X", c3.R * 255, c3.G * 255, c3.B * 255)
		hi.Text = tostring(math.floor(H * 360 + 0.5))
		si.Text = tostring(math.floor(S * 100 + 0.5))
		vi.Text = tostring(math.floor(V * 100 + 0.5))
		if apply then fireApply(c3) end
	end
	local applyTick = 0
	function fireApply(c3)
		local now = os.clock()
		applyTick = now
		task.delay(0.18, function()
			if applyTick == now then applyProp({ r = c3.R, g = c3.G, b = c3.B }) end
		end)
	end

	local dragging = nil
	local function trackInput(obj, cb)
		obj.InputBegan:Connect(function(inp2)
			if inp2.UserInputType == Enum.UserInputType.MouseButton1 or inp2.UserInputType == Enum.UserInputType.Touch then
				dragging = cb
				cb(inp2)
			end
		end)
	end
	UIS.InputChanged:Connect(function(inp2)
		if dragging and (inp2.UserInputType == Enum.UserInputType.MouseMovement or inp2.UserInputType == Enum.UserInputType.Touch) then
			dragging(inp2)
		end
	end)
	UIS.InputEnded:Connect(function(inp2)
		if inp2.UserInputType == Enum.UserInputType.MouseButton1 or inp2.UserInputType == Enum.UserInputType.Touch then dragging = nil end
	end)
	trackInput(sv, function(inp2)
		local p2, s2 = sv.AbsolutePosition, sv.AbsoluteSize
		S = math.clamp((inp2.Position.X - p2.X) / math.max(s2.X, 1), 0, 1)
		V = math.clamp(1 - (inp2.Position.Y - p2.Y) / math.max(s2.Y, 1), 0, 1)
		refreshFromHSV(true)
	end)
	trackInput(hue, function(inp2)
		local p2, s2 = hue.AbsolutePosition, hue.AbsoluteSize
		H = math.clamp((inp2.Position.Y - p2.Y) / math.max(s2.Y, 1), 0, 1)
		refreshFromHSV(true)
	end)
	local function commitRGB()
		local r2 = math.clamp((tonumber(ri.Text) or 0) / 255, 0, 1)
		local g3 = math.clamp((tonumber(gi.Text) or 0) / 255, 0, 1)
		local b3 = math.clamp((tonumber(bi.Text) or 0) / 255, 0, 1)
		H, S, V = Color3.new(r2, g3, b3):ToHSV()
		refreshFromHSV(true)
	end
	for _, b2 in ipairs({ ri, gi, bi }) do b2.FocusLost:Connect(function(enter) if enter then commitRGB() end end) end
	hex.FocusLost:Connect(function(enter)
		if not enter then return end
		local t2 = hex.Text:gsub("#", ""):upper()
		if #t2 == 6 then
			local r2 = tonumber(t2:sub(1, 2), 16) / 255
			local g3 = tonumber(t2:sub(3, 4), 16) / 255
			local b3 = tonumber(t2:sub(5, 6), 16) / 255
			if r2 and g3 and b3 then
				H, S, V = Color3.new(r2, g3, b3):ToHSV()
				refreshFromHSV(true)
			end
		end
	end)
	local function commitHSV()
		H = math.clamp((tonumber(hi.Text) or 0) / 360, 0, 1)
		S = math.clamp((tonumber(si.Text) or 0) / 100, 0, 1)
		V = math.clamp((tonumber(vi.Text) or 0) / 100, 0, 1)
		refreshFromHSV(true)
	end
	for _, b2 in ipairs({ hi, si, vi }) do b2.FocusLost:Connect(function(enter) if enter then commitHSV() end end) end

	local okB = mk("TextButton", f, { Size = UDim2.fromOffset(96, 24), Position = UDim2.new(1, -106, 1, -32),
		BackgroundColor3 = th.acc, Text = "FECHAR", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 11, BorderSizePixel = 0, ZIndex = 71, AutoButtonColor = true })
	corner(okB, 6)
	onTap(okB, closeColorWin)

	refreshFromHSV(false)
	colorWin = f
	pcall(function() f.Parent = popups end)
	if not f.Parent then f.Parent = uiRoot end
end

-- ---------- render das ROWS de propriedade ----------
local propRows = {}

local function commitField(field, payloadVal)
	local id2 = propsState.objId
	if not id2 then return end
	task.spawn(function()
		local res, err = apiResult("SetAny", { id = id2, name = field.name, kind = field.rawKind, value = payloadVal })
		if res and res.error then say(res.error, true)
		elseif err then say(tostring(err), true)
		elseif res and res.ok then
			say(field.name .. " = " .. tostring(res.now))
		end
	end)
end

local function rowBase(parent, y2, h2)
	local row = mk("Frame", parent, { Size = UDim2.new(1, -8, 0, h2), Position = UDim2.fromOffset(4, y2),
		BackgroundColor3 = ((y2 / h2) % 2 < 1) and th.row or th.rowAlt, BorderSizePixel = 0 })
	return row
end

local function renderProps()
	local list = propsState.list
	if not list or not list.Parent then return end
	for _, r in ipairs(list:GetChildren()) do if r:IsA("GuiObject") then r:Destroy() end end
	local fields = propsState.fields or {}
	local filter = string.lower(propsState.filter or "")
	local y2 = 0
	local lastGroup = nil
	local count = 0
	for _, field in ipairs(fields) do
		local labelText = field.name
		if filter == "" or string.lower(labelText):find(filter, 1, true) or string.lower(field.group or ""):find(filter, 1, true) then
			count = count + 1
			if field.group ~= lastGroup then
				lastGroup = field.group
				local gh = mk("Frame", list, { Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(4, y2),
					BackgroundColor3 = th.head, BorderSizePixel = 0 })
				mk("TextLabel", gh, { Text = "  " .. string.upper(field.group or "Geral"), Size = UDim2.new(1, -8, 1, 0),
					BackgroundTransparency = 1, TextColor3 = th.acc2, Font = Enum.Font.GothamBold, TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left })
				y2 = y2 + 18
			end
			local kind, ro = field.rawKind, field.ro
			local rowH = 24
			local row = rowBase(list, y2, rowH)
			y2 = y2 + rowH
			mk("TextLabel", row, { Text = labelText, Size = UDim2.new(0.42, -4, 1, 0), Position = UDim2.fromOffset(6, 0),
				BackgroundTransparency = 1, TextColor3 = ro and th.muted or th.text, Font = Enum.Font.Gotham,
				TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
			local x0 = 0.44
			if kind == "b" and not ro then
				local chk = mk("TextButton", row, { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = field.value and th.acc or th.panel, Text = field.value and "✓" or "",
					TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0,
					AutoButtonColor = true })
				corner(chk, 4) stroke(chk, th.border, 1)
				onTap(chk, function()
					field.value = not field.value
					chk.BackgroundColor3 = field.value and th.acc or th.panel
					chk.Text = field.value and "✓" or ""
					commitField(field, field.value)
				end)
			elseif kind == "n" and not ro then
				local nb = mk("TextBox", row, { Size = UDim2.new(0.52, -6, 0, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = th.panel, Text = tostring(field.value), TextColor3 = th.text,
					Font = Enum.Font.Gotham, TextSize = 11, BorderSizePixel = 0, ClearTextOnFocus = false })
				corner(nb, 4) stroke(nb, th.border, 1)
				nb.FocusLost:Connect(function(enter)
					if not enter then return end
					local nv = tonumber(nb.Text)
					if nv and nv ~= field.value then field.value = nv commitField(field, nv) end
				end)
			elseif kind == "v" or kind == "v2" then
				local comps = kind == "v" and { "x", "y", "z" } or { "x", "y" }
				local saved = field.value or {}
				for ci, cn in ipairs(comps) do
					local cb = mk("TextBox", row, { Size = UDim2.new(0.17, -4, 0, 18), Position = UDim2.new(x0 + (ci - 1) * 0.175, 0, 0.5, -9),
						BackgroundColor3 = th.panel, Text = string.format("%.2f", saved[cn] or 0), TextColor3 = th.text,
						Font = Enum.Font.Gotham, TextSize = 10, BorderSizePixel = 0, ClearTextOnFocus = false })
					corner(cb, 4) stroke(cb, th.border, 1)
					cb.FocusLost:Connect(function(enter)
						if not enter or ro then return end
						local nv = tonumber(cb.Text)
						if nv then saved[cn] = nv commitField(field, { x = saved.x, y = saved.y, z = saved.z }) end
					end)
				end
			elseif kind == "c" then
				local cur = field.value or { r = 1, g = 1, b = 1 }
				local sw = mk("TextButton", row, { Size = UDim2.fromOffset(30, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = Color3.new(cur.r, cur.g, cur.b), Text = "", BorderSizePixel = 0, AutoButtonColor = true })
				corner(sw, 4) stroke(sw, th.border, 1)
				onTap(sw, function()
					if ro then return end
					openColorPicker(sw, field, function(cT)
						sw.BackgroundColor3 = Color3.new(cT.r, cT.g, cT.b)
						field.value = cT
						commitField(field, cT)
					end)
				end)
			elseif kind == "br" then
				local bc = BrickColor.new(tostring(field.value or "White"))
				local sw = mk("Frame", row, { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = bc.Color, BorderSizePixel = 0 })
				corner(sw, 4) stroke(sw, th.border, 1)
				local tb = mk("TextBox", row, { Size = UDim2.new(0.36, -4, 0, 18), Position = UDim2.new(x0, 22, 0.5, -9),
					BackgroundColor3 = th.panel, Text = tostring(field.value or "White"), TextColor3 = th.text,
					Font = Enum.Font.Gotham, TextSize = 10, BorderSizePixel = 0, ClearTextOnFocus = false })
				corner(tb, 4) stroke(tb, th.border, 1)
				tb.FocusLost:Connect(function(enter)
					if not enter or ro then return end
					local okB2, nbv = pcall(function() return BrickColor.new(tb.Text) end)
					if okB2 and nbv then field.value = nbv.Name sw.BackgroundColor3 = nbv.Color commitField(field, nbv.Name)
					else say("BrickColor desconhecido: " .. tb.Text, true) end
				end)
			elseif field.enum then
				local okE, items = pcall(function() return Enum[field.enum]:GetEnumItems() end)
				local names = {}
				if okE then for _, it in ipairs(items) do names[#names + 1] = it.Name end end
				local db = mk("TextButton", row, { Size = UDim2.new(0.52, -6, 0, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = th.panel, Text = "  " .. tostring(field.value) .. "  ▾", TextColor3 = th.text,
					Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
					BorderSizePixel = 0, AutoButtonColor = true })
				corner(db, 4) stroke(db, th.border, 1)
				onTap(db, function()
					if ro or #names == 0 then return end
					-- dropdown simples: popup com scroll
					if propsState.enumTarget and propsState.enumTarget.Parent then propsState.enumTarget:Destroy() propsState.enumTarget = nil return end
					local scale = guiScale()
					local ap2 = db.AbsolutePosition
					local hMax = math.min(#names * 20, 220)
					local ddp = mk("Frame", nil, { Size = UDim2.fromOffset(db.AbsoluteSize.X / scale, hMax + 6),
						Position = UDim2.fromOffset(ap2.X / scale, ap2.Y / scale + 20),
						BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 70, Active = true })
					corner(ddp, 6) stroke(ddp, th.acc, 1)
					local scr = mk("ScrollingFrame", ddp, { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4),
						BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, #names * 20),
						ZIndex = 71 })
					for qi, nm in ipairs(names) do
						local op = mk("TextButton", scr, { Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(0, (qi - 1) * 20),
							BackgroundColor3 = (nm == field.value) and th.acc or th.bg2, Text = "  " .. nm,
							TextColor3 = th.text, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
							BorderSizePixel = 0, ZIndex = 72, AutoButtonColor = true })
						onTap(op, function()
							ddp:Destroy() propsState.enumTarget = nil
							if nm ~= field.value then
								db.Text = "  " .. nm .. "  ▾"
								field.value = nm
								commitField(field, nm)
							end
						end)
					end
					propsState.enumTarget = ddp
					pcall(function() ddp.Parent = popups end)
					if not ddp.Parent then ddp.Parent = uiRoot end
				end)
			else
				-- string/asset/seq/cf/o/ro → caixa de texto (ro cinza não editável)
				local tb = mk("TextBox", row, { Size = UDim2.new(0.52, -6, 0, 18), Position = UDim2.new(x0, 0, 0.5, -9),
					BackgroundColor3 = th.panel, Text = tostring(field.value), TextColor3 = ro and th.muted or th.text,
					Font = Enum.Font.Gotham, TextSize = 10, BorderSizePixel = 0, ClearTextOnFocus = false,
					TextEditable = not ro })
				corner(tb, 4) stroke(tb, th.border, 1)
				tb.FocusLost:Connect(function(enter)
					if not enter or ro then return end
					if tb.Text ~= tostring(field.value) then
						local kind2 = field.rawKind
						if kind2 == "s" or kind2 == "i" then
							field.value = tb.Text
							commitField(field, tb.Text)
						elseif kind2 == "u2" then
							local a, b2, c2, d2 = tb.Text:match("%{?%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*;?%s*[%{%s]*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
							if a then commitField(field, { sx = tonumber(a), ox = tonumber(b2), sy = tonumber(c2), oy = tonumber(d2) }) end
						elseif kind2 == "u" then
							local a, b2 = tb.Text:match("%{?%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
							if a then commitField(field, { s = tonumber(a), o = tonumber(b2) }) end
						end
					end
				end)
			end
		end
	end
	if propsState.scroll then propsState.scroll.CanvasSize = UDim2.fromOffset(0, y2 + 8) end
	propsState.visibleCount = count
	if propsState.countLbl then propsState.countLbl.Text = tostring(count) .. " props" end
end

local function refreshProps(force)
	local id2 = selectedId()
	if not id2 then
		propsState.objId = nil
		propsState.fields = {}
		if propsState.titleLbl then propsState.titleLbl.Text = "PROPERTIES — nada selecionado" end
		renderProps()
		return
	end
	if id2 == propsState.objId and propsState.fields and not force then return end
	propsState.objId = id2
	task.spawn(function()
		local res, err = apiResult("PropsAll", { id = id2 })
		if not res then
			if propsState.titleLbl then propsState.titleLbl.Text = "PROPERTIES — erro: " .. tostring(err) end
			return
		end
		-- normaliza kinds crus
		for _, f2 in ipairs(res.fields or {}) do
			if f2.enum then
				f2.rawKind = "e:" .. f2.enum
			else
				f2.rawKind = f2.kind
			end
		end
		propsState.fields = res.fields or {}
		if propsState.titleLbl then
			propsState.titleLbl.Text = (res.name or "?") .. "  ·  " .. (res.className or "?")
		end
		renderProps()
	end)
end

local function takeOverPropertiesDock()
	if not dockP then warn("[ArkherX] 10: PropertiesDock não achada.") return end
	-- marca e esconde o conteúdo original (menos Header); o 01 pode re-desenhar,
	-- então também vigiamos ChildAdded e re-escondemos.
	local function hideOriginal()
		for _, c in ipairs(dockP:GetChildren()) do
			if c:IsA("GuiObject") and c.Name ~= "Header" and not c:GetAttribute("ArkherProps") then
				c.Visible = false
			end
		end
	end
	hideOriginal()
	dockP.ChildAdded:Connect(function(c)
		if c:GetAttribute("ArkherProps") then return end
		task.defer(function()
			if c:IsA("GuiObject") and c.Name ~= "Header" then c.Visible = false end
		end)
	end)
	local overlay = mk("Frame", dockP, {
		Name = "ArkherPropsOverlay", BackgroundColor3 = th.bg, BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), ZIndex = 6, ClipsDescendants = true,
	})
	overlay:SetAttribute("ArkherProps", true)
	-- barra de topo: nome/classe + busca + refresh
	local top = mk("Frame", overlay, { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 7 })
	propsState.titleLbl = mk("TextLabel", top, { Text = "PROPERTIES — nada selecionado", Size = UDim2.new(1, -70, 0, 22),
		Position = UDim2.fromOffset(8, 2), BackgroundTransparency = 1, TextColor3 = th.text, Font = Enum.Font.GothamBold,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, TextTruncate = Enum.TextTruncate.AtEnd })
	propsState.countLbl = mk("TextLabel", top, { Text = "0 props", Size = UDim2.fromOffset(56, 16),
		Position = UDim2.new(1, -64, 0, 4), BackgroundTransparency = 1, TextColor3 = th.muted, Font = Enum.Font.Gotham,
		TextSize = 10, ZIndex = 8 })
	local search = mk("TextBox", top, { Size = UDim2.new(1, -64, 0, 22), Position = UDim2.fromOffset(8, 26),
		BackgroundColor3 = th.panel, Text = "", PlaceholderText = "🔍 filtrar propriedades…", PlaceholderColor3 = th.muted,
		TextColor3 = th.text, Font = Enum.Font.Gotham, TextSize = 11, BorderSizePixel = 0, ZIndex = 8,
		ClearTextOnFocus = false })
	corner(search, 5) stroke(search, th.border, 1)
	search:GetPropertyChangedSignal("Text"):Connect(function()
		propsState.filter = search.Text
		renderProps()
	end)
	local refB = mk("TextButton", top, { Size = UDim2.fromOffset(48, 22), Position = UDim2.new(1, -56, 0, 26),
		BackgroundColor3 = th.panel, Text = "↻", TextColor3 = th.acc2, Font = Enum.Font.GothamBold, TextSize = 14,
		BorderSizePixel = 0, ZIndex = 8, AutoButtonColor = true })
	corner(refB, 5) stroke(refB, th.border, 1)
	onTap(refB, function() refreshProps(true) end)
	local scr = mk("ScrollingFrame", overlay, { Size = UDim2.new(1, 0, 1, -54), Position = UDim2.fromOffset(0, 52),
		BackgroundTransparency = 1, ScrollBarThickness = 5, ZIndex = 7, CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never })
	propsState.scroll = scr
	local lst = mk("Frame", scr, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 7 })
	propsState.list = lst
	-- seleção muda → refaz
	local a2 = i:FindFirstChild("SelectedId")
	if a2 then a2:GetPropertyChangedSignal("Value"):Connect(function() refreshProps(false) end) end
	task.spawn(function()
		while task.wait(1.5) do
			local id2 = selectedId()
			if id2 ~= propsState.objId then refreshProps(false) end
		end
	end)
	refreshProps(true)
	say("PROPERTIES na dock original: TODAS as props do objeto + color picker (clique no quadradinho de cor).")
end

-- =============================================================
-- PARTE 2 — PAINEL INSERIR OBJETO (o "+" de +1k objetos)
-- =============================================================
local insertWin, insertItems, insertTarget, insertSearchT
local INSERT_TARGETS = { "Selecionado", "Workspace", "Lighting", "StarterGui", "StarterPack", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "SoundService" }
local function resolveInsertParent(payload)
	local target = payload.target
	if target == "Selecionado" then return nil end -- servidor usa seleção
	local ok, svc = pcall(function() return game:GetService(target) end)
	return nil -- ids não trafegam services; servidor decide por nome
end

local function buildInsertPanel(hostBtn)
	if insertWin and insertWin.Parent then insertWin:Destroy() insertWin = nil return end
	if not popups then say("Sem popups canvas.", true) return end
	local scale = guiScale()
	local ap = hostBtn and hostBtn.AbsolutePosition or Vector2.new(200, 120)
	local fw, fh = 420, 480
	local fx = math.clamp(ap.X / scale + 24, 4, 1568 - fw)
	local fy = math.clamp(ap.Y / scale + 24, 4, 882 - fh)
	local f = mk("Frame", nil, { Size = UDim2.fromOffset(fw, fh), Position = UDim2.fromOffset(fx, fy),
		BackgroundColor3 = th.bg, BorderSizePixel = 0, ZIndex = 66, Active = true, Name = "ArkherInsertPanel" })
	corner(f, 10) stroke(f, th.acc, 1.5)
	-- title + drag
	local tb = mk("Frame", f, { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = th.head, BorderSizePixel = 0, ZIndex = 67, Active = true })
	corner(tb, 10)
	mk("TextLabel", tb, { Text = "  ➕  INSERIR OBJETO  —  catálogo completo", Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1, TextColor3 = th.text, Font = Enum.Font.GothamBold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 68 })
	local closeB = mk("TextButton", tb, { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -28, 0.5, -13),
		BackgroundColor3 = th.panel, Text = "✕", TextColor3 = th.text, Font = Enum.Font.GothamBold, TextSize = 12,
		BorderSizePixel = 0, ZIndex = 68, AutoButtonColor = true })
	corner(closeB, 6)
	onTap(closeB, function() f:Destroy() insertWin = nil end)
	-- drag
	do
		local dragOn, dragStart, frameStart
		tb.InputBegan:Connect(function(inp2)
			if inp2.UserInputType == Enum.UserInputType.MouseButton1 then
				dragOn = true dragStart = inp2.Position frameStart = f.Position
			end
		end)
		UIS.InputChanged:Connect(function(inp2)
			if dragOn and inp2.UserInputType == Enum.UserInputType.MouseMovement then
				local d2 = (inp2.Position - dragStart) / scale
				f.Position = UDim2.fromOffset(frameStart.X.Offset + d2.X, frameStart.Y.Offset + d2.Y)
			end
		end)
		UIS.InputEnded:Connect(function(inp2)
			if inp2.UserInputType == Enum.UserInputType.MouseButton1 then dragOn = false end
		end)
	end
	-- busca
	local search = mk("TextBox", f, { Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 34),
		BackgroundColor3 = th.panel, Text = "", PlaceholderText = "🔍 buscar classe (part, light, weld, remote…)",
		PlaceholderColor3 = th.muted, TextColor3 = th.text, Font = Enum.Font.Gotham, TextSize = 12,
		BorderSizePixel = 0, ZIndex = 67, ClearTextOnFocus = false })
	corner(search, 6) stroke(search, th.border, 1)
	insertSearchT = search
	-- alvo
	mk("TextLabel", f, { Text = "Inserir em:", Size = UDim2.fromOffset(58, 20), Position = UDim2.fromOffset(8, 64),
		BackgroundTransparency = 1, TextColor3 = th.muted, Font = Enum.Font.Gotham, TextSize = 10, ZIndex = 67 })
	insertTarget = "Selecionado"
	local targetLbl = mk("TextButton", f, { Size = UDim2.fromOffset(150, 20), Position = UDim2.fromOffset(70, 64),
		BackgroundColor3 = th.panel, Text = "  " .. insertTarget .. "  ▾", TextColor3 = th.acc2,
		Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0, ZIndex = 67, AutoButtonColor = true })
	corner(targetLbl, 5) stroke(targetLbl, th.border, 1)
	local targetDd
	onTap(targetLbl, function()
		if targetDd and targetDd.Parent then targetDd:Destroy() targetDd = nil return end
		targetDd = mk("Frame", f, { Size = UDim2.fromOffset(150, #INSERT_TARGETS * 20 + 8),
			Position = UDim2.fromOffset(70, 86), BackgroundColor3 = th.bg2, BorderSizePixel = 0, ZIndex = 75, Active = true })
		corner(targetDd, 6) stroke(targetDd, th.acc, 1)
		for qi, nm in ipairs(INSERT_TARGETS) do
			local op = mk("TextButton", targetDd, { Size = UDim2.new(1, -8, 0, 20), Position = UDim2.fromOffset(4, 4 + (qi - 1) * 20),
				BackgroundColor3 = (nm == insertTarget) and th.acc or th.bg2, Text = "  " .. nm, TextColor3 = th.text,
				Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
				BorderSizePixel = 0, ZIndex = 76, AutoButtonColor = true })
			onTap(op, function()
				insertTarget = nm
				targetLbl.Text = "  " .. nm .. "  ▾"
				targetDd:Destroy() targetDd = nil
			end)
		end
	end)
	-- lista
	local scr = mk("ScrollingFrame", f, { Size = UDim2.new(1, -16, 1, -154), Position = UDim2.fromOffset(8, 90),
		BackgroundColor3 = th.bg2, ScrollBarThickness = 5, ZIndex = 67, CanvasSize = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y })
	corner(scr, 6) stroke(scr, th.border, 1)
	local lst = mk("Frame", scr, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 68 })
	-- rodapé
	local hint = mk("TextLabel", f, { Text = "Clique 2x insere • alvo = seleção atual (ou Workspace)",
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, fh - 60), BackgroundTransparency = 1,
		TextColor3 = th.muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 67 })
	local countLbl = mk("TextLabel", f, { Text = "…", Size = UDim2.fromOffset(180, 16), Position = UDim2.fromOffset(8, fh - 42),
		BackgroundTransparency = 1, TextColor3 = th.acc2, Font = Enum.Font.GothamBold, TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 67 })
	local insB = mk("TextButton", f, { Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, fh - 36),
		BackgroundColor3 = th.acc, Text = "INSERIR CLASSE SELECIONADA", TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0, ZIndex = 67, AutoButtonColor = true })
	corner(insB, 7)

	local picked = nil
	local pickedRow = nil
	local function doInsert(cls)
		if not cls then say("Escolha uma classe primeiro.", true) return end
		task.spawn(function()
			local par
			if insertTarget ~= "Selecionado" then
				par = { target = insertTarget }
			else
				local sid = selectedId()
				if sid then par = { parentId = sid } end
			end
			local payload = { class = cls }
			if par and par.parentId then payload.parentId = par.parentId end
			if insertTarget ~= "Selecionado" then payload.parentName = insertTarget end
			local res, err = apiResult("CreateAny", payload)
			if res and res.error then say(res.error, true)
			elseif err then say(tostring(err), true)
			elseif res and res.msg then say(res.msg) end
		end)
	end
	local function renderList(items)
		for _, c in ipairs(lst:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local q2 = string.lower(search.Text or "")
		local y2, count = 0, 0
		local lastCat = nil
		for _, it in ipairs(items) do
			if q2 == "" or string.lower(it.class):find(q2, 1, true)
				or string.lower(it.desc or ""):find(q2, 1, true)
				or string.lower(it.alias or ""):find(q2, 1, true)
				or string.lower(it.cat or ""):find(q2, 1, true) then
				count = count + 1
				if it.cat ~= lastCat then
					lastCat = it.cat
					local gh = mk("Frame", lst, { Size = UDim2.new(1, -8, 0, 16), Position = UDim2.fromOffset(4, y2),
						BackgroundColor3 = th.head, BorderSizePixel = 0 })
					mk("TextLabel", gh, { Text = "  " .. string.upper(it.cat or "?"), Size = UDim2.new(1, -6, 1, 0),
						BackgroundTransparency = 1, TextColor3 = th.gold, Font = Enum.Font.GothamBold, TextSize = 9,
						TextXAlignment = Enum.TextXAlignment.Left })
					y2 = y2 + 16
				end
				local row = mk("TextButton", lst, { Size = UDim2.new(1, -8, 0, 24), Position = UDim2.fromOffset(4, y2),
					BackgroundColor3 = (count % 2 == 0) and th.row or th.rowAlt, Text = "", BorderSizePixel = 0,
					AutoButtonColor = true, ZIndex = 69 })
				y2 = y2 + 24
				mk("TextLabel", row, { Text = "  " .. it.class, Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1,
					TextColor3 = th.acc2, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 70 })
				mk("TextLabel", row, { Text = it.desc or "", Size = UDim2.new(0.58, -6, 1, 0), Position = UDim2.new(0.4, 6, 0, 0),
					BackgroundTransparency = 1, TextColor3 = th.muted, Font = Enum.Font.Gotham, TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 70, TextTruncate = Enum.TextTruncate.AtEnd })
				local cls = it.class
				local lastClick = 0
				onTap(row, function()
					if pickedRow and pickedRow.Parent then pickedRow.BackgroundColor3 = th.row end
					picked = cls pickedRow = row
					row.BackgroundColor3 = th.acc
					local now = os.clock()
					if now - lastClick < 0.45 then doInsert(cls) end
					lastClick = now
				end)
			end
		end
		if count == 0 then
			mk("TextLabel", lst, { Text = "  nada encontrado p/ '" .. (search.Text or "") .. "'", Size = UDim2.new(1, -8, 0, 22),
				Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, TextColor3 = th.muted,
				Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left })
			y2 = 24
		end
		scr.CanvasSize = UDim2.fromOffset(0, y2 + 8)
		countLbl.Text = tostring(count) .. "/" .. tostring(#items) .. " classes"
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		if insertItems then renderList(insertItems) end
	end)
	onTap(insB, function() doInsert(picked) end)

	insertWin = f
	f.Parent = popups
	-- carrega catálogo real do servidor
	task.spawn(function()
		local res, err = apiResult("ClassList", {})
		if not res then say("ClassList falhou: " .. tostring(err), true) return end
		insertItems = res.items or {}
		renderList(insertItems)
		say("Catálogo INSERIR: " .. tostring(#insertItems) .. " classes (todas testáveis via CreateAny real).")
	end)
end

-- wire nos "+" da Hierarchy (per-row plus ao lado dos services)
local function wireHierarchyPlus()
	if not dockH then return end
	local tree = dockH:FindFirstChild("Tree", true)
	if not tree then tree = dockH end
	local function tryAttach(b)
		if b:GetAttribute("ArkWiredPlus") then return end
		if b:IsA("GuiButton") and (b.Text == "+" or b.Text == "−") then
			b:SetAttribute("ArkWiredPlus", true)
			local function onPlus()
				-- espera o picker NATIVO (se houver); senão abre o nosso
				local seen = {}
				if popups then
					for _, d in ipairs(popups:GetDescendants()) do
						if d:IsA("GuiObject") and d.Visible then seen[d] = true end
					end
				end
				task.delay(0.14, function()
					if popups then
						for _, d in ipairs(popups:GetDescendants()) do
							if d:IsA("GuiObject") and d.Visible and not seen[d] then
								return -- picker nativo abriu, não duplica
							end
						end
					end
					buildInsertPanel(b)
				end)
			end
			pcall(function() b.Activated:Connect(onPlus) end)
			pcall(function() b.MouseButton1Click:Connect(onPlus) end)
		end
	end
	for _, d in ipairs(tree:GetDescendants()) do tryAttach(d) end
	tree.DescendantAdded:Connect(function(d) tryAttach(d) end)
end

-- =============================================================
-- PARTE 3 — TOOLBOX DOCK estilo Roblox Studio
-- =============================================================
local toolboxWin
local tbState = { kind = "models", page = 0, query = "", items = {}, total = 0, busy = false }

local function closeToolbox() if toolboxWin and toolboxWin.Parent then toolboxWin:Destroy() end toolboxWin = nil end
local function camForward(dist)
	local cam = workspace.CurrentCamera
	if cam then
		local cf = cam.CFrame
		local p = cf.Position + cf.LookVector * (dist or 18)
		return math.floor(p.X + 0.5), math.max(math.floor(p.Y + 0.5), 3), math.floor(p.Z + 0.5)
	end
	return 0, 4, -16
end

local function buildToolbox()
	if toolboxWin and toolboxWin.Parent then closeToolbox() return end
	if not popups then return end
	local scale = guiScale()
	local fw, fh = 560, 520
	local f = mk("Frame", nil, { Size = UDim2.fromOffset(fw, fh), Position = UDim2.fromOffset(760, 120),
		BackgroundColor3 = th.bg, BorderSizePixel = 0, ZIndex = 64, Active = true, Name = "ArkherToolboxDock" })
	corner(f, 10) stroke(f, th.border, 1.2)
	-- title + drag
	local tb = mk("Frame", f, { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = th.head, BorderSizePixel = 0, ZIndex = 65, Active = true })
	corner(tb, 10)
	mk("TextLabel", tb, { Text = "  🧰  TOOLBOX  —  Creator Store (thumbs reais)", Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1, TextColor3 = th.text, Font = Enum.Font.GothamBold, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 66 })
	local closeB = mk("TextButton", tb, { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -30, 0.5, -14),
		BackgroundColor3 = th.panel, Text = "✕", TextColor3 = th.text, Font = Enum.Font.GothamBold, TextSize = 13,
		BorderSizePixel = 0, ZIndex = 66, AutoButtonColor = true })
	corner(closeB, 6)
	onTap(closeB, closeToolbox)
	do
		local dragOn, dragStart, frameStart
		tb.InputBegan:Connect(function(inp2)
			if inp2.UserInputType == Enum.UserInputType.MouseButton1 then
				dragOn = true dragStart = inp2.Position frameStart = f.Position
			end
		end)
		UIS.InputChanged:Connect(function(inp2)
			if dragOn and inp2.UserInputType == Enum.UserInputType.MouseMovement then
				local d2 = (inp2.Position - dragStart) / scale
				f.Position = UDim2.fromOffset(frameStart.X.Offset + d2.X, frameStart.Y.Offset + d2.Y)
			end
		end)
		UIS.InputEnded:Connect(function(inp2)
			if inp2.UserInputType == Enum.UserInputType.MouseButton1 then dragOn = false end
		end)
	end
	-- busca + categoria
	local search = mk("TextBox", f, { Size = UDim2.new(1, -130, 0, 28), Position = UDim2.fromOffset(10, 42),
		BackgroundColor3 = th.panel, Text = "", PlaceholderText = "🔍 buscar na loja (casa, árvore, carro, arma…)",
		PlaceholderColor3 = th.muted, TextColor3 = th.text, Font = Enum.Font.Gotham, TextSize = 12,
		BorderSizePixel = 0, ZIndex = 65, ClearTextOnFocus = false })
	corner(search, 6) stroke(search, th.border, 1)
	local goB = mk("TextButton", f, { Size = UDim2.fromOffset(108, 28), Position = UDim2.new(1, -118, 0, 42),
		BackgroundColor3 = th.acc, Text = "BUSCAR", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 12, BorderSizePixel = 0, ZIndex = 65, AutoButtonColor = true })
	corner(goB, 6)
	local kindModels = mk("TextButton", f, { Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(10, 76),
		BackgroundColor3 = th.acc, Text = "MODELOS", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
		TextSize = 10, BorderSizePixel = 0, ZIndex = 65, AutoButtonColor = true })
	corner(kindModels, 5)
	local kindDecals = mk("TextButton", f, { Size = UDim2.fromOffset(120, 22), Position = UDim2.fromOffset(136, 76),
		BackgroundColor3 = th.panel, Text = "DECALS/IMAGENS", TextColor3 = th.muted, Font = Enum.Font.GothamBold,
		TextSize = 10, BorderSizePixel = 0, ZIndex = 65, AutoButtonColor = true })
	corner(kindDecals, 5) stroke(kindDecals, th.border, 1)
	local status = mk("TextLabel", f, { Text = "Digite e BUSCAR — resultados reais da Creator Store.",
		Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 102), BackgroundTransparency = 1,
		TextColor3 = th.muted, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 65 })
	-- grade
	local scr = mk("ScrollingFrame", f, { Size = UDim2.new(1, -20, 1, -166), Position = UDim2.fromOffset(10, 122),
		BackgroundColor3 = th.bg2, ScrollBarThickness = 5, ZIndex = 65, CanvasSize = UDim2.fromOffset(0, 0),
		BorderSizePixel = 0, ScrollingDirection = Enum.ScrollingDirection.Y })
	corner(scr, 6) stroke(scr, th.border, 1)
	local grid = mk("UIGridLayout", scr, { CellSize = UDim2.fromOffset(126, 152), CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left })
	mk("UIPadding", scr, { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 8) })
	-- páginas
	local prevB = mk("TextButton", f, { Size = UDim2.fromOffset(110, 24), Position = UDim2.fromOffset(10, fh - 40),
		BackgroundColor3 = th.panel, Text = "◀ anterior", TextColor3 = th.text, Font = Enum.Font.GothamBold,
		TextSize = 11, BorderSizePixel = 0, ZIndex = 65, AutoButtonColor = true })
	corner(prevB, 5) stroke(prevB, th.border, 1)
	local pageLbl = mk("TextLabel", f, { Text = "pág 0", Size = UDim2.fromOffset(60, 24), Position = UDim2.fromOffset(124, fh - 40),
		BackgroundTransparency = 1, TextColor3 = th.muted, Font = Enum.Font.GothamBold, TextSize = 11, ZIndex = 65 })
	local nextB = mk("TextButton", f, { Size = UDim2.fromOffset(110, 24), Position = UDim2.fromOffset(188, fh - 40),
		BackgroundColor3 = th.panel, Text = "próxima ▶", TextColor3 = th.text, Font = Enum.Font.GothamBold,
		TextSize = 11, BorderSizePixel = 0, ZIndex = 65, AutoButtonColor = true })
	corner(nextB, 5) stroke(nextB, th.border, 1)

	local function setKind(kd)
		tbState.kind = kd
		local onM = kd == "models"
		kindModels.BackgroundColor3 = onM and th.acc or th.panel
		kindModels.TextColor3 = onM and Color3.new(1, 1, 1) or th.muted
		kindDecals.BackgroundColor3 = onM and th.panel or th.acc
		kindDecals.TextColor3 = onM and th.muted or Color3.new(1, 1, 1)
	end
	local function doInsert(it)
		task.spawn(function()
			local x2, y2, z2 = camForward(18)
			local res, err = apiResult("ToolboxAssetInsert", { assetId = it.id, x = x2, y = y2, z = z2 })
			if res and res.error then say(res.error, true)
			elseif err then say("Insert falhou: " .. tostring(err), true)
			elseif res and res.msg then say(res.msg) end
		end)
	end
	local function renderItems()
		for _, c in ipairs(scr:GetChildren()) do
			if c:IsA("GuiObject") and c ~= grid then c:Destroy() end
		end
		for qi, it in ipairs(tbState.items) do
			local card = mk("TextButton", scr, { BackgroundColor3 = th.panel, Text = "", BorderSizePixel = 0,
				AutoButtonColor = true, ZIndex = 66, LayoutOrder = qi })
			corner(card, 8) stroke(card, th.border, 1)
			local img = mk("ImageLabel", card, { Size = UDim2.new(1, -12, 0, 102), Position = UDim2.fromOffset(6, 6),
				BackgroundColor3 = th.rowAlt, BorderSizePixel = 0, ZIndex = 67,
				Image = ("rbxthumb://type=Asset&id=" .. tostring(it.id) .. "&w=420&h=420"),
				ScaleType = Enum.ScaleType.Fit })
			corner(img, 6)
			if it.trusted then
				mk("TextLabel", card, { Text = "★", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -20, 0, 8),
					BackgroundTransparency = 1, Text = "★", TextColor3 = th.gold, Font = Enum.Font.GothamBold,
					TextSize = 12, ZIndex = 68 })
			end
			mk("TextLabel", card, { Text = it.name or "?", Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 108),
				BackgroundTransparency = 1, TextColor3 = th.text, Font = Enum.Font.GothamBold, TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 67 })
			mk("TextLabel", card, { Text = "por " .. tostring(it.creator or "?"), Size = UDim2.new(1, -12, 0, 14),
				Position = UDim2.fromOffset(6, 132), BackgroundTransparency = 1, TextColor3 = th.muted,
				Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 67 })
			local item = it
			onTap(card, function() doInsert(item) end)
		end
		pageLbl.Text = "pág " .. tostring(tbState.page)
	end
	local function doSearch(resetPage)
		if tbState.busy then return end
		tbState.busy = true
		if resetPage then tbState.page = 0 end
		tbState.query = search.Text
		status.Text = "Buscando '" .. tbState.query .. "' (" .. tbState.kind .. ")…"
		task.spawn(function()
			local res, err = apiResult("ToolboxSearch", { query = tbState.query, kind = tbState.kind, page = tbState.page })
			tbState.busy = false
			if not res then
				status.Text = "Falhou: " .. tostring(err or "?")
				say("ToolboxSearch falhou: " .. tostring(err or "?"), true)
				return
			end
			if res.error then
				status.Text = tostring(res.error)
				say(res.error, true)
				return
			end
			tbState.items = res.items or {}
			tbState.total = res.total or 0
			status.Text = tostring(#tbState.items) .. " resultados (total ~" .. tostring(tbState.total) .. ") — clique num card pra inserir na frente da câmera."
			renderItems()
		end)
	end
	onTap(goB, function() doSearch(true) end)
	onTap(prevB, function() if tbState.page > 0 then tbState.page = tbState.page - 1 doSearch(false) end end)
	onTap(nextB, function() tbState.page = tbState.page + 1 doSearch(false) end)
	onTap(kindModels, function() setKind("models") doSearch(true) end)
	onTap(kindDecals, function() setKind("decals") doSearch(true) end)
	search.FocusLost:Connect(function(enter) if enter and #search.Text > 1 then doSearch(true) end end)

	toolboxWin = f
	pcall(function() f.Parent = popups end)
	if not f.Parent then f.Parent = uiRoot end
	setKind("models")
	if #search.Text > 1 then doSearch(true) end
end

-- ---------- /_G.ArkherStudioDock ----------
rawset(_G, "ArkherStudioDock", {
	toggle = function(id2)
		if id2 == "toolbox" then buildToolbox()
		elseif id2 == "insert" then buildInsertPanel(nil)
		end
	end,
})

-- ---------- boot ----------
takeOverPropertiesDock()
wireHierarchyPlus()

-- PARTE 4 — V2_ArkherToolbox (janela ASSADA): busca REAL + insert REAL
do
	local tbW = host and host:FindFirstChild("V2_ArkherToolbox")
	if tbW then
		local MPS = game:GetService("MarketplaceService")
		local plr = game:GetService("Players").LocalPlayer
		local searchFrame = tbW:FindFirstChild("Search")
		local searchBox = searchFrame and searchFrame:FindFirstChild("SearchBox")
		local rows = {}
		for _, ch in ipairs(tbW:GetChildren()) do
			if ch:IsA("Frame") and ch.Name == "AS" then rows[#rows + 1] = ch end
		end
		local tb = { kind = "models", items = {}, note = false, paid = false }
		local function rowParts(row)
			local lbl, ins, pv, thumb, ikon
			for _, ch in ipairs(row:GetChildren()) do
				if ch:IsA("TextLabel") then lbl = ch
				elseif ch:IsA("TextButton") and ch.Name == "INS" then ins = ch
				elseif ch:IsA("Frame") and ch.Name == "PV" then pv = ch end
			end
			if pv then
				thumb = pv:FindFirstChild("Thumb")
				ikon = pv:FindFirstChild("I")
			end
			return lbl, ins, thumb, ikon
		end
		local function paint()
			for i, row in ipairs(rows) do
				local lbl, _, thumb, ikon = rowParts(row)
				local it = tb.items[i]
				pcall(function()
					if lbl then local t = it and tostring(it.name):sub(1, 22) or "--" if it and tonumber(it.price or 0) and tonumber(it.price) > 0 then t = t .. " [R$" .. tostring(it.price) .. "]" end lbl.Text = t end
					if thumb then thumb.Image = it and ("rbxthumb://type=Asset&id=" .. tostring(it.id) .. "&w=150&h=150") or "" end
					if ikon then ikon.Visible = (it == nil) end
				end)
			end
		end
		local buyHooked = false
		local function buyPaid(it)
			local aid = tonumber(it.id or 0) or 0
			if aid <= 0 then say("Item pago sem id valido.", true) return end
			if not buyHooked then buyHooked = true
				pcall(function() MPS.PromptPurchaseFinished:Connect(function(p, assetId, ok)
					if ok and p == plr then say("Compra finalizada (asset " .. tostring(assetId) .. ").") end
				end) end)
			end
			pcall(function() MPS:PromptPurchase(plr, aid) end)
			say("Abrindo compra de " .. tostring(it.name):sub(1, 28) .. " [R$" .. tostring(it.price or "?") .. "]...")
		end
		local function insertAt(i)
			local it = tb.items[i]
			if not it then say("Busque algo primeiro (ENTER na busca).", true) return end
			local cf = nil
			pcall(function() cf = workspace.CurrentCamera and workspace.CurrentCamera.CFrame end)
			local px, py, pz = 0, 4, -14
			if cf then
				local pp = cf.Position + cf.LookVector * 14
				px, py, pz = pp.X, pp.Y, pp.Z
			end
			if tb.paid then buyPaid(it) return end
			local _, err = apiResult("ToolboxAssetInsert", { assetId = it.id, x = px, y = py, z = pz })
			if err then say("Inserir: " .. tostring(err), true)
			else say("BAG " .. tostring(it.name):sub(1, 30) .. " (de " .. tostring(it.creator or "?"):sub(1, 20) .. ") inserido.") end
		end
		for i, row in ipairs(rows) do
			local _, ins = rowParts(row)
			if ins then onTap(ins, function() insertAt(i) end) end
		end
		local catKind = { TC_3D = "models", TC_Images = "decals", TC_Textures = "decals" }
		local function doPaidSearch(q)
			local res, err = apiResult("ToolboxPaidSearch", { query = q })
			if err then say("Loja paga: " .. tostring(err), true) return end
			tb.items = (res and res.items) or {}
			tb.paid = true
			paint()
			say("$ " .. #tb.items .. " pagos p/ " .. q:sub(1, 24) .. ". INS = comprar.")
		end
		local function doSearch()
			local q = searchBox and searchBox.Text or ""
			if #q < 2 then say("Digite 2+ letras e ENTER ($ = loja paga).", true) return end
			if q:sub(1, 1) == "$" then local rest = q:sub(2):match("^%s*(.-)%s*$") if rest:match("^%d+$") then buyPaid({ id = rest, name = "item #" .. rest, price = "?" }) else doPaidSearch(rest) end return end
			local res, err = apiResult("ToolboxSearch", { query = q, kind = tb.kind, page = 0 })
			if err then say("Toolbox: " .. tostring(err), true) return end
			tb.items = (res and res.items) or {}
			tb.paid = false
			paint()
			say("BAG " .. #tb.items .. ' resultados reais para "' .. q:sub(1, 24) .. '".')
		end
		if searchBox then
			pcall(function()
				searchBox.FocusLost:Connect(function(enter)
					if enter then doSearch() end
				end)
			end)
		end
		for _, ch in ipairs(tbW:GetChildren()) do
			if ch:IsA("TextButton") and ch.Name:sub(1, 3) == "TC_" then
				onTap(ch, function()
					tb.kind = catKind[ch.Name] or "models"
					if not catKind[ch.Name] and not tb.note then
						tb.note = true
						say("Categoria " .. ch.Name:sub(4) .. ": busca nativa cobre Modelos/Decals -- mostrando Modelos.")
					end
					if searchBox and #searchBox.Text >= 2 then doSearch()
					else say("Categoria: " .. tb.kind .. ". Digite a busca + ENTER.") end
				end)
			end
		end
	end
end


-- PARTE 5 — V2_ArkherScriptEditor (janela ASSADA): abas + Run REAL (command-bar local)
do
	local seW = host and host:FindFirstChild("V2_ArkherScriptEditor")
	if seW then
		local codeBox = seW:FindFirstChild("Code")
		local gutF = seW:FindFirstChild("Gut")
		local gutLbl = gutF and gutF:FindFirstChildOfClass("TextLabel")
		local termF = seW:FindFirstChild("Term")
		local termLbl = termF and termF:FindFirstChildOfClass("TextLabel")
		local runB = seW:FindFirstChild("Run")
		local tabs = {}
		for _, ch in ipairs(seW:GetChildren()) do
			if ch:IsA("TextButton") and ch.Name:match("^T[123]$") then tabs[ch.Name] = ch end
		end
		local order = { "T1", "T2", "T3" }
		local buffers = {
			{ name = "ServerMain.lua", code = (codeBox and codeBox.Text) or "-- novo script" },
			{ name = "ArkherCore.lua", code = "-- ArkherCore.lua\nprint(\"ArkherCore ok\")\n" },
			{ name = "D_O15.lua", code = "-- D_O15.lua\nprint(\"D-O15 ok\")\n" },
		}
		local cur = 1
		local SEL_BG = Color3.fromRGB(26, 42, 74)
		local UNS_BG = Color3.fromRGB(7, 13, 25)
		local function paintGut()
			if not gutLbl or not codeBox then return end
			local n = 1
			for _ in codeBox.Text:gmatch("\n") do n = n + 1 end
			n = math.min(n, 200)
			local lines = {}
			for i = 1, n do lines[i] = tostring(i) end
			pcall(function() gutLbl.Text = table.concat(lines, "\n") end)
		end
		local function paintTabs()
			for idx, tn in ipairs(order) do
				local bb = tabs[tn]
				if bb then pcall(function()
					bb.BackgroundColor3 = (idx == cur) and SEL_BG or UNS_BG
					bb.BackgroundTransparency = (idx == cur) and 0 or 1
				end) end
			end
		end
		local function term(msg, isErr)
			if termLbl then pcall(function()
				termLbl.Text = "arkher:~ " .. tostring(msg):sub(1, 220)
				termLbl.TextColor3 = isErr and Color3.fromRGB(255, 150, 140) or Color3.fromRGB(120, 220, 150)
			end) end
		end
		local function selectTab(idx)
			if codeBox then buffers[cur].code = codeBox.Text end
			cur = idx
			if codeBox then codeBox.Text = buffers[cur].code end
			paintGut()
			paintTabs()
		end
		for idx, tn in ipairs(order) do
			local bb = tabs[tn]
			if bb then
				onTap(bb, function() selectTab(idx) end)
				local x = bb:FindFirstChild("x")
				if x and x:IsA("TextButton") then
					onTap(x, function()
						buffers[idx].code = ""
						if idx == cur and codeBox then codeBox.Text = "" end
						paintGut()
						say(buffers[idx].name .. " limpo.")
					end)
				end
			end
		end
		if codeBox then
			pcall(function()
				codeBox:GetPropertyChangedSignal("Text"):Connect(paintGut)
			end)
		end
		if runB then
			onTap(runB, function()
				if not codeBox then return end
				buffers[cur].code = codeBox.Text
				if _G.ArkherSEBridge and _G.ArkherSEBridge(codeBox.Text, buffers[cur].name, term) then return end
				local fn, lerr = loadstring(codeBox.Text, "=" .. buffers[cur].name)
				if not fn then term("ERRO sintaxe: " .. tostring(lerr), true) return end
				local out = {}
				local oldPrint = print
				print = function(...)
					local parts = {}
					for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
					out[#out + 1] = table.concat(parts, "  ")
				end
				local ok, rerr = pcall(fn)
				print = oldPrint
				if not ok then term("ERRO: " .. tostring(rerr), true)
				elseif #out > 0 then term(table.concat(out, " | "))
				else term("OK (sem saida) -- " .. buffers[cur].name) end
			end)
		end
		paintGut()
		paintTabs()
	end
end

print("[ArkherX] 10_Studio: Properties NA DOCK ORIGINAL (todas as props + color picker) · INSERIR OBJETO (+ da Hierarchy) · TOOLBOX estilo Studio com thumbs reais")

-- PARTE 6A — ScriptEditor: LANG (LU/PY/C+/C#) + exec via PyBridge + autocomplete CLASSDB
do
	local seW = host and host:FindFirstChild("V2_ArkherScriptEditor")
	if seW then
		local codeBox = seW:FindFirstChild("Code")
		local langB = seW:FindFirstChild("LangPy")
		local sugBox = seW:FindFirstChild("Suggest")
		local LANGS = { "LU", "PY", "C+", "C#" }
		local TOBR = { LU = "lua", PY = "py", ["C+"] = "cpp", ["C#"] = "csharp" }
		local li = 1
		local function paintLang()
			if langB then local l = langB:FindFirstChild("Lbl") if l then l.Text = LANGS[li] end end
		end
		if langB then onTap(langB, function()
			li = li % #LANGS + 1
			paintLang()
			say("ScriptEditor: " .. LANGS[li] .. (LANGS[li] == "LU" and " (exec local)" or " (exec PyBridge)") .. ".")
		end) end
		paintLang()
		_G.ArkherSEBridge = function(code, name, termFn)
			local lg = LANGS[li]
			if lg == "LU" then return false end
			if termFn then termFn("bridge " .. lg .. ": executando...", false) end
			local res, err = apiResult("PyRun", { task = "exec", lang = TOBR[lg], code = code })
			if err then if termFn then termFn("BRIDGE ERRO: " .. tostring(err), true) end return true end
			local out = res and (res.out or res.summary) or ""
			local e2 = res and res.error or ""
			if termFn then
				if e2 ~= "" then termFn("ERRO: " .. tostring(e2) .. (out ~= "" and (" | " .. tostring(out):sub(1, 120)) or ""), true)
				else termFn((out ~= "" and tostring(out):sub(1, 220) or "OK (sem saida)") .. " -- " .. tostring(name)) end
			end
			return true
		end
		local sugs = {}
		if sugBox then for i = 0, 7 do sugs[i] = sugBox:FindFirstChild("Sug" .. i) end end
		local classes, classT, shown, lock = {}, 0, {}, false
		local function hideSug() if sugBox then sugBox.Visible = false end end
		local function refreshSug()
			if lock then return end
			if not sugBox or not codeBox then return end
			if #classes == 0 and (os.clock() - classT) > 5 then
				classT = os.clock()
				local res = apiResult("ClassList", {})
				if res and res.items then for _, it in ipairs(res.items) do classes[#classes + 1] = it.class end end
			end
			if #classes == 0 then hideSug() return end
			local pos = codeBox.CursorPosition or 1
			local pre = (codeBox.Text or ""):sub(1, math.max(0, pos - 1))
			local word = pre:match("[%w_]+$") or ""
			if #word < 2 then hideSug() return end
			local lw = word:lower()
			table.clear(shown)
			for _, c in ipairs(classes) do
				if type(c) == "string" and c:lower():find(lw, 1, true) == 1 then shown[#shown + 1] = c end
				if #shown >= 8 then break end
			end
			if #shown == 0 then hideSug() return end
			for i = 0, 7 do local b = sugs[i] if b then b.Text = (i < #shown) and ("  " .. shown[i + 1]) or "" b.Visible = i < #shown end end
			sugBox.Visible = true
		end
		for i = 0, 7 do local b = sugs[i] if b then onTap(b, function()
			local pick = shown[i + 1]
			if not pick or not codeBox then hideSug() return end
			local pos = codeBox.CursorPosition or 1
			local txt = codeBox.Text or ""
			local pre = txt:sub(1, math.max(0, pos - 1)):gsub("[%w_]+$", "")
			lock = true
			codeBox.Text = pre .. pick .. txt:sub(pos)
				codeBox.CursorPosition = #pre + #pick + 1
			lock = false
			hideSug()
			pcall(function() codeBox:CaptureFocus() end)
		end) end end
		if codeBox then pcall(function()
			codeBox:GetPropertyChangedSignal("Text"):Connect(refreshSug)
			codeBox:GetPropertyChangedSignal("CursorPosition"):Connect(refreshSug)
		end) end
	end
end

