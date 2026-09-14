-- arkher/shell/explorer.lua — live instance tree (services + search + select).
local EX = { filter = "" }
local function E() return _G.ARKHER end
function EX.build(dock)
  EX.dock = dock
  EX.body = dock:FindFirstChild("Body")
  -- search box
  local th = E().shell.theme()
  local sb = Instance.new("TextBox")
  sb.Name = "Search" sb.Size = UDim2.new(1, -8, 0, 24) sb.Position = UDim2.new(0, 4, 0, 24)
  sb.Font = Enum.Font.Gotham sb.TextSize = 12 sb.PlaceholderText = "Search..."
  sb.BackgroundColor3 = th.input sb.TextColor3 = th.text sb.BorderSizePixel = 0 sb.Parent = dock
  sb:GetPropertyChangedSignal("Text"):Connect(function() EX.filter = sb.Text EX.refresh() end)
  EX.body.Position = UDim2.new(0, 0, 0, 50)
  EX.body.Size = UDim2.new(1, 0, 1, -50)
  EX.refresh()
  E().sel.onChange(function() EX.markSelected() end)
end
local SERVICES = { "Workspace", "Lighting", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams", "Players" }
function EX.refresh()
  if not EX.body then return end
  for _, ch in ipairs(EX.body:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end end
  local th = E().shell.theme()
  local order = 0
  local function row(inst, depth)
    if EX.filter ~= "" and not inst.Name:lower():find(EX.filter:lower(), 1, true) and not inst:IsA("BasePart") then
      -- still show containers
      if inst:IsA("BasePart") then return end
    end
    if EX.filter ~= "" and not inst.Name:lower():find(EX.filter:lower(), 1, true) then
      local any = false
      for _, d in ipairs(inst:GetDescendants()) do if d.Name:lower():find(EX.filter:lower(), 1, true) then any = true break end end
      if not any then return end
    end
    order = order + 1
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 20) b.LayoutOrder = order
    b.Font = Enum.Font.Gotham b.TextSize = 12 b.TextXAlignment = Enum.TextXAlignment.Left
    b.Text = string.rep("  ", math.min(depth, 8)) .. inst.ClassName:sub(1, 1) .. " " .. inst.Name
    b.BackgroundTransparency = 1 b.TextColor3 = th.text b.BorderSizePixel = 0 b.Parent = EX.body
    b.MouseButton1Click:Connect(function()
      E().sel.set({ inst })
      E().props.show(inst)
    end)
    if depth < 4 then
      local kids = inst:GetChildren()
      for i = 1, math.min(#kids, 60) do row(kids[i], depth + 1) end
      if #kids > 60 then order = order + 1 local m = Instance.new("TextLabel") m.Size = UDim2.new(1, 0, 0, 18) m.LayoutOrder = order m.Font = Enum.Font.Gotham m.TextSize = 11 m.TextColor3 = th.dim m.Text = string.rep("  ", depth + 1) .. "... " .. (#kids - 60) .. " more" m.BackgroundTransparency = 1 m.TextXAlignment = Enum.TextXAlignment.Left m.Parent = EX.body end
    end
  end
  for _, s in ipairs(SERVICES) do local ok, svc = pcall(game.GetService, game, s) if ok and svc then row(svc, 0) end end
end
function EX.markSelected() end
E().explorer = EX
return EX
