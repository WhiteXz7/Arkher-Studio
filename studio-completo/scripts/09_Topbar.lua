-- =============================================================
-- Arkher_09_Topbar (GUIX) — GUARDIÃO DOS POPUPS.
-- Os popups são REAIS (Canvas/ArkherXDeck/ServerEditorPopups no .rbxl).
-- Aqui mora SÓ o sistema: 7 linhas de formas (spawn server QuickPart
-- na frente da câmera), hover, fechar clicando fora. ZERO Instance.new.
-- A shell (05) mostra os popups; o 09 fia o conteúdo deles.
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
local function say(text, bad)
	local sh = rawget(_G, "ArkherShell")
	if sh and sh.say and not bad then sh.say(text) return end
	W("Message", { text = text, bad = bad })
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
		if not ok then warn("[ArkherX] 09 clique: " .. tostring(err)) end
	end
	pcall(function() btn.Activated:Connect(function(...) fire("A", ...) end) end)
	pcall(function() btn.MouseButton1Click:Connect(function(...) fire("M", ...) end) end)
	btn.Active = true
	btn.Selectable = true
	btn.Visible = true
end

local m = {
	panel = Color3.fromRGB(9, 23, 44), selected = Color3.fromRGB(17, 76, 139),
}

-- ---------- popup de formas REAL ----------
local canvas = uiRoot:WaitForChild("Canvas", 25)
local host = canvas:WaitForChild("ArkherXDeck", 25)
local popups = host:WaitForChild("ServerEditorPopups", 25)
local shapesPopup = popups:WaitForChild("ArkherShapesPopup", 25)

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
		if res and res.msg then say(res.msg)
		elseif err then say("Spawn falhou: " .. tostring(err), true)
		else say(shapeId .. " criado na frente da câmera.") end
	end)
end
for _, spec in ipairs(SHAPES) do
	local row = shapesPopup:FindFirstChild("ShapeRow_" .. spec[1])
	if row then
		row.MouseEnter:Connect(function() row.BackgroundColor3 = m.selected end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = m.panel end)
		onTap(row, function() spawnShape(spec[1], spec[2]) end)
	end
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

_G.ArkherPopups = { shapes = function() shapesPopup.Visible = true end, say = say }
print("[ArkherX] 09_Popups: 7 formas reais fiadas — zero Instance.new de GUI")
