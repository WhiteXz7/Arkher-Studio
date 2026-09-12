-- =============================================================
-- Arkher_09_Topbar (GUIX) — FIAÇÃO da barra X.
-- A barra é REAL (Canvas/ArkherXDeck/ArkherXBar no .rbxl, com os 6
-- botões + ícones desenhados em Frames); o popup de formas também é
-- REAL (ServerEditorPopups/ArkherShapesPopup). Aqui mora SÓ o sistema:
--   PART ▸ (7 formas, spawn server na frente da câmera),
--   BASEPLATE (garante chão), UNION / NEGATE (CSG real),
--   TOOLBOX (deck-first, cai no dock do 10 se o deck não subiu),
--   ✦ X (abre a central de editores do 05).
-- =============================================================

local Players = game:GetService("Players")
local client = Players.LocalPlayer

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 09_Topbar precisa estar dentro de ArkherStudioUI") return end
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

-- ---------- GUI real: XBar + popup de formas ----------
local canvas = uiRoot:WaitForChild("Canvas", 25)
local host = canvas:WaitForChild("ArkherXDeck", 25)
local bar = host:WaitForChild("ArkherXBar", 25)
local popups = host:WaitForChild("ServerEditorPopups", 25)
local shapesPopup = popups:WaitForChild("ArkherShapesPopup", 25)
local uiscale = canvas:FindFirstChild("ResponsiveScale")

local SHAPES = {
	{ "Block", "Block (4×2×4)" }, { "Ball", "Ball (esfera)" },
	{ "Cylinder", "Cylinder (roda)" }, { "CylinderVertical", "Cylinder vertical (pilar)" },
	{ "Wedge", "Wedge (rampa)" }, { "CornerWedge", "CornerWedge (canto)" },
	{ "Truss", "Truss (treliça)" },
}
local function closeShapes()
	shapesPopup.Visible = false
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
local function spawnShape(shapeId, shapeLabel)
	closeShapes()
	task.spawn(function()
		local x2, y2, z2 = camSpawnPos()
		local res, err = apiResult("QuickPart", { shape = shapeId, x = x2, y = y2, z = z2 })
		if res and res.msg then W("Message", { text = res.msg })
		elseif err then W("Message", { text = "Spawn falhou: " .. tostring(err), bad = true })
		else W("Message", { text = shapeId .. " criado na frente da câmera." }) end
	end)
end
-- fia as 7 linhas REAIS (uma vez; o popup só mostra/esconde)
for _, spec in ipairs(SHAPES) do
	local row = shapesPopup:FindFirstChild("ShapeRow_" .. spec[1])
	if row then
		row.MouseEnter:Connect(function() row.BackgroundColor3 = m.selected end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = m.panel end)
		onTap(row, function() spawnShape(spec[1], spec[2]) end)
	end
end
local function openShapes(hostBtn)
	local scale = (uiscale and uiscale.Scale) or 1
	if scale <= 0 then scale = 1 end
	local ap, asz = hostBtn.AbsolutePosition, hostBtn.AbsoluteSize
	shapesPopup.Position = UDim2.fromOffset(ap.X / scale, (ap.Y + asz.Y) / scale + 4)
	shapesPopup.Visible = true
end
do
	local UIS = game:GetService("UserInputService")
	UIS.InputBegan:Connect(function(inp, gp)
		if gp or not shapesPopup.Visible then return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = Vector2.new(inp.Position.X, inp.Position.Y)
			local fp, fs = shapesPopup.AbsolutePosition, shapesPopup.AbsoluteSize
			if fp.X > 0 and not (mp.X >= fp.X and mp.Y >= fp.Y and mp.X <= fp.X + fs.X and mp.Y <= fp.Y + fs.Y) then
				closeShapes()
			end
		end
	end)
end

-- ---------- fia os 6 botões REAIS ----------
local btnPart = bar:WaitForChild("ArkherX_Part", 10)
local btnBase = bar:WaitForChild("ArkherX_Base", 10)
local btnUnion = bar:WaitForChild("ArkherX_Union", 10)
local btnNegate = bar:WaitForChild("ArkherX_Negate", 10)
local btnToolbox = bar:WaitForChild("ArkherX_Toolbox", 10)
local btnLauncher = bar:WaitForChild("ArkherX_Launcher", 10)

onTap(btnPart, function() openShapes(btnPart) end)
onTap(btnBase, function()
	task.spawn(function()
		local res, err = apiResult("EnsureBase", {})
		if res and res.msg then W("Message", { text = res.msg })
		elseif err then W("Message", { text = "Baseplate falhou: " .. tostring(err), bad = true }) end
	end)
end)
onTap(btnUnion, function()
	task.spawn(function()
		local res, err = apiResult("CsgDo", { op = "union" })
		if res and res.msg then W("Message", { text = res.msg })
		elseif res and res.error then W("Message", { text = tostring(res.error), bad = true })
		elseif err then W("Message", { text = tostring(err), bad = true }) end
	end)
end)
onTap(btnNegate, function()
	task.spawn(function()
		local res, err = apiResult("CsgDo", { op = "negate" })
		if res and res.msg then W("Message", { text = res.msg })
		elseif res and res.error then W("Message", { text = tostring(res.error), bad = true })
		elseif err then W("Message", { text = tostring(err), bad = true }) end
	end)
end)
onTap(btnToolbox, function() -- deck-first; cai no dock do 10 se o deck não subiu
	local d = rawget(_G, "ArkherDeck")
	if d and d.open then d.open("toolbox") return end
	local dd = rawget(_G, "ArkherStudioDock")
	if dd and dd.toggle then dd.toggle("toolbox") return end
	W("Message", { text = "UI X ainda carregando…", bad = true })
end)
onTap(btnLauncher, function()
	local s = rawget(_G, "ArkherStudioX")
	if s and s.open then s.open() return end
	local lw = host:FindFirstChild("Deck_launcher")
	if lw then lw.Visible = true end
end)

W("Message", { text = "XBar: 6 botões reais (Part ▸ / Baseplate / Union / Negate / Toolbox / ✦ X) + popup de 7 formas." })
print("[ArkherX] 09_Topbar: XBar real fiada — zero overlay, zero Instance.new de GUI")
