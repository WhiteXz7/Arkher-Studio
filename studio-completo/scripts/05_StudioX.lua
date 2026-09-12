-- =============================================================
-- Arkher_05_StudioX — FIAÇÃO da central de editores (LocalScript)
-- A GUI é REAL (Canvas/ArkherXDeck/Deck_launcher no .rbxl); aqui mora
-- SÓ o sistema: abrir/fechar, drag, e as 25 linhas que abrem editores.
-- =============================================================

local UIS = game:GetService("UserInputService")

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 05_StudioX precisa estar dentro de ArkherStudioUI") return end
local rt = uiRoot:WaitForChild("ArkherServerClientRuntime", 20)
if not rt then warn("[ArkherX] 05: núcleo não achado.") return end
local bus = rt:WaitForChild("ClientBus", 20)
local ready = rt:WaitForChild("CoreReady", 20)
if not bus or not ready then warn("[ArkherX] 05: núcleo incompleto.") return end
local t0 = os.clock()
while not ready.Value and rt.Parent and os.clock() - t0 < 20 do task.wait(0.04) end
if not ready.Value then warn("[ArkherX] 05: núcleo não subiu a tempo.") return end
if not bus:Invoke("ClaimPart", { name = "05_StudioX", script = script }) then return end

local canvas = uiRoot:WaitForChild("Canvas", 25)
local host = canvas:WaitForChild("ArkherXDeck", 25)
local launcher = host:WaitForChild("Deck_launcher", 25)
local body = launcher:WaitForChild("Body")
local list = body:WaitForChild("List")
local cap = launcher:WaitForChild("Cap")
local closeB = cap:WaitForChild("Close")

-- arrastar pela capa
do
	local dragging, dragStart, startPos
	cap.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			startPos = launcher.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			launcher.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end
closeB.MouseButton1Click:Connect(function() launcher.Visible = false end)
pcall(function() closeB.Activated:Connect(function() launcher.Visible = false end) end)

local function hideDeckWindows()
	for _, ch in ipairs(host:GetChildren()) do
		if ch:IsA("Frame") and ch.Name ~= "ArkherXBar" and ch.Name ~= "ServerEditorPopups" then
			ch.Visible = false
		end
	end
end

local function openDeck(id)
	if id == "rig" or id == "mesh" then
		hideDeckWindows()
		local w = host:FindFirstChild("Deck_" .. id)
		if w then w.Visible = true end
		return
	end
	local d = rawget(_G, "ArkherDeck")
	if d and d.open then
		launcher.Visible = false
		d.open(id)
	else
		bus:Invoke("Message", { text = "UI X ainda carregando…", bad = true })
	end
end

local IDS = {
	"terrain", "modeler", "animator", "espaco", "fabricar", "water",
	"atmos", "clima", "vida", "cidade", "audio", "fx", "cordas",
	"toolbox", "props", "cores", "output", "comando", "scripts", "py",
	"sculpt", "grupos", "plugins", "rig", "mesh",
}
local wired = 0
for _, id in ipairs(IDS) do
	local row = list:FindFirstChild("Launch_" .. id)
	if row then
		wired = wired + 1
		local hover = row.BackgroundColor3
		row.MouseEnter:Connect(function() row.BackgroundColor3 = Color3.fromRGB(17, 76, 139) end)
		row.MouseLeave:Connect(function() row.BackgroundColor3 = hover end)
		local function go() openDeck(id) end
		row.MouseButton1Click:Connect(go)
		pcall(function() row.Activated:Connect(go) end)
	end
end

rawset(_G, "ArkherStudioX", {
	root = launcher,
	open = function() launcher.Visible = true end,
})
print(("[ArkherX] 05_StudioX pronto — central real com %d/25 linhas fiadas"):format(wired))
