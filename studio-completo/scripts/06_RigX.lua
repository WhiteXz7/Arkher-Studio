-- Arkher_06_RigX — FIAÇÃO do editor de esqueleto (Cascadeur++)
-- A GUI é REAL (Canvas/ArkherXDeck/Deck_rig no .rbxl); aqui mora SÓ o
-- sistema: drag, fechar, e os 3 botões que falam com o servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local uiRoot = script:FindFirstAncestorOfClass("ScreenGui")
if not uiRoot then warn("[ArkherX] 06_RigX precisa estar dentro de ArkherStudioUI") return end
local canvas = uiRoot:WaitForChild("Canvas", 25)
local host = canvas:WaitForChild("ArkherXDeck", 25)
local win = host:WaitForChild("Deck_rig", 25)
local body = win:WaitForChild("Body")
local cap = win:WaitForChild("Cap")
local closeB = cap:WaitForChild("Close")
local status = body:WaitForChild("RigStatus")

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

do
	local dragging, dragStart, startPos
	cap.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			startPos = win.Position
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end
closeB.MouseButton1Click:Connect(function() win.Visible = false end)
pcall(function() closeB.Activated:Connect(function() win.Visible = false end) end)

local OKC = Color3.fromRGB(120, 220, 160)
local BADC = Color3.fromRGB(255, 164, 143)
local RUNC = Color3.fromRGB(43, 203, 243)
local function wire(btnName, label, fn)
	local b0 = body:FindFirstChild(btnName)
	if not b0 then warn("[ArkherX] 06: sem " .. btnName) return end
	local busy = false
	local function go()
		if busy then return end
		busy = true
		status.Text = "→ " .. label .. "…"
		status.TextColor3 = RUNC
		task.spawn(function()
			local ok, res = pcall(fn)
			if ok then status.Text = "✓ " .. tostring(res) status.TextColor3 = OKC
			else status.Text = "✗ " .. tostring(res) status.TextColor3 = BADC end
			busy = false
		end)
	end
	b0.MouseButton1Click:Connect(go)
	pcall(function() b0.Activated:Connect(go) end)
end

wire("RigBtn_Demo", "Cadeia FABRIK demo", function() return remote("rig_demo", {}) end)
wire("RigBtn_Balance", "Relatorio de equilibrio", function() return remote("rig_balance", {}) end)
wire("RigBtn_Stop", "PARAR rig", function() return remote("rig_stop", {}) end)

rawset(_G, "ArkherRigX", { root = win, open = function() win.Visible = true end })
print("[ArkherX] 06_RigX pronto (Cascadeur++ FABRIK+balance real)")
