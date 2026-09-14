-- arkher/shell/bottom.lua — Output + Console + Problems + status wiring.
local BO = {}
local function E() return _G.ARKHER end
function BO.build(dock, status)
  local body = dock:FindFirstChild("Body")
  local th = E().shell.theme()
  -- tab row
  local row = Instance.new("Frame")
  row.Size = UDim2.new(1, 0, 0, 24) row.Position = UDim2.new(0, 0, 0, 22) row.BackgroundColor3 = th.bg row.BorderSizePixel = 0 row.Parent = dock
  body.Position = UDim2.new(0, 0, 0, 46) body.Size = UDim2.new(1, 0, 1, -46)
  BO.body = body
  BO.mode = "Output"
  for i, m in ipairs({ "Output", "Console", "Problems" }) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 90, 1, 0) b.Position = UDim2.new(0, (i - 1) * 94, 0, 0)
    b.Font = Enum.Font.GothamBold b.TextSize = 12 b.Text = m
    b.BackgroundColor3 = th.btn b.TextColor3 = th.text b.BorderSizePixel = 0 b.Parent = row
    b.MouseButton1Click:Connect(function() BO.mode = m BO.render() end)
  end
  -- console input
  local ci = Instance.new("TextBox")
  ci.Name = "ConsoleIn" ci.Size = UDim2.new(1, -8, 0, 24) ci.Position = UDim2.new(0, 4, 1, -26)
  ci.Font = Enum.Font.Code ci.TextSize = 13 ci.PlaceholderText = "Lua >"
  ci.BackgroundColor3 = th.input ci.TextColor3 = th.text ci.BorderSizePixel = 0 ci.Parent = dock
  ci.FocusLost:Connect(function(enter)
    if enter and ci.Text ~= "" then
      E().out.log("> " .. ci.Text)
      E().systems.script.runCode(ci.Text)
      ci.Text = ""
    end
  end)
  E().out.sub(function() BO.render() end)
  BO.render()
end
function BO.render()
  local body = BO.body
  if not body then return end
  for _, ch in ipairs(body:GetChildren()) do if not ch:IsA("UIListLayout") then ch:Destroy() end end
  local th = E().shell.theme()
  local lines = E().out.lines
  if BO.mode == "Problems" then lines = E().out.problems end
  local f = E().out.filter
  local n = 0
  for i = math.max(1, #lines - 120), #lines do
    local e = lines[i]
    if e.kind ~= "clear" and e.kind ~= "filter" then
      if f == "all" or (f == "error" and e.kind == "error") or (f == "warn" and (e.kind == "warn" or e.kind == "error")) then
        n = n + 1
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 16) l.LayoutOrder = n l.Font = Enum.Font.Code l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left l.BackgroundTransparency = 1
        l.TextColor3 = e.kind == "error" and th.err or (e.kind == "warn" and th.warn or th.text)
        l.Text = "[" .. e.kind .. "] " .. e.msg:sub(1, 220) l.Parent = body
      end
    end
  end
  body.CanvasPosition = Vector2.new(0, 1e6)
end
E().bottom = BO
return BO
