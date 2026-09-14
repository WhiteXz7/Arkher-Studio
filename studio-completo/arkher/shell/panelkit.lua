-- arkher/shell/panelkit.lua — declarative panel controls (responsive + a11y labels).
local K = {}
local function E() return _G.ARKHER end
local function theme() return E().shell.theme() end
function K.row(parent, h)
  local f = Instance.new("Frame")
  f.BackgroundTransparency = 1 f.Size = UDim2.new(1, 0, 0, h or 30)
  f.LayoutOrder = #parent:GetChildren() + 1 f.Parent = parent
  return f
end
function K.label(parent, text, small)
  local r = K.row(parent, small and 20 or 24)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, 0, 1, 0)
  t.Font = Enum.Font.Gotham t.TextSize = small and 11 or 13
  t.TextColor3 = theme().text t.Text = tostring(text) t.TextXAlignment = Enum.TextXAlignment.Left
  t.TextWrapped = true t.Parent = r
  return t
end
function K.sep(parent) local r = K.row(parent, 8) local f = Instance.new("Frame") f.BackgroundColor3 = theme().border f.BorderSizePixel = 0 f.Size = UDim2.new(1, 0, 0, 1) f.Position = UDim2.new(0, 0, 0, 4) f.Parent = r end
function K.button(parent, label, fn)
  local r = K.row(parent, 32)
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1, 0, 1, 0) b.Font = Enum.Font.GothamBold b.TextSize = 13
  b.Text = "  " .. tostring(label) b.TextXAlignment = Enum.TextXAlignment.Left
  b.BackgroundColor3 = theme().btn b.TextColor3 = theme().text b.BorderSizePixel = 0
  b.AutoButtonColor = true b.Parent = r
  local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
  b.MouseButton1Click:Connect(function() local ok, err = pcall(fn) if not ok then E().out.err(tostring(err)) end end)
  return b
end
function K.toggle(parent, label, get, set)
  local r = K.row(parent, 30)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, -56, 1, 0) t.Font = Enum.Font.Gotham t.TextSize = 13
  t.TextColor3 = theme().text t.Text = tostring(label) t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = r
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, 48, 0, 22) b.Position = UDim2.new(1, -48, 0, 4)
  b.Font = Enum.Font.GothamBold b.TextSize = 12 b.BorderSizePixel = 0 b.AutoButtonColor = true b.Parent = r
  local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
  local function paint() local v = get() b.Text = v and "ON" or "OFF" b.BackgroundColor3 = v and theme().accent or theme().btn b.TextColor3 = Color3.fromRGB(255, 255, 255) end
  paint()
  b.MouseButton1Click:Connect(function() set(not get()) paint() end)
  return b
end
function K.slider(parent, label, min, max, step, get, set)
  local r = K.row(parent, 46)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, 0, 0, 18) t.Font = Enum.Font.Gotham t.TextSize = 12
  t.TextColor3 = theme().text t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = r
  local bar = Instance.new("TextButton")
  bar.Size = UDim2.new(1, 0, 0, 20) bar.Position = UDim2.new(0, 0, 0, 22)
  bar.BackgroundColor3 = theme().btn bar.Text = "" bar.BorderSizePixel = 0 bar.AutoButtonColor = false bar.Parent = r
  local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = bar
  local fill = Instance.new("Frame") fill.BackgroundColor3 = theme().accent fill.BorderSizePixel = 0 fill.Parent = bar
  local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 4) fc.Parent = fill
  local function paint()
    local v = math.clamp(get() or min, min, max)
    t.Text = label .. ": " .. string.format("%.2f", v)
    fill.Size = UDim2.new((v - min) / math.max(0.001, (max - min)), 0, 1, 0)
  end
  paint()
  local drag = false
  local function apply(x)
    local ax = bar.AbsolutePosition.X local aw = math.max(1, bar.AbsoluteSize.X)
    local a = math.clamp((x - ax) / aw, 0, 1)
    local v = min + a * (max - min)
    if step and step > 0 then v = math.floor(v / step + 0.5) * step end
    set(v) paint()
  end
  bar.MouseButton1Down:Connect(function(x) drag = true apply(x) end)
  game:GetService("UserInputService").InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
  game:GetService("UserInputService").InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then apply(i.Position.X) end end)
  return bar
end
function K.text(parent, label, get, set, numeric)
  local r = K.row(parent, 46)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, 0, 0, 18) t.Font = Enum.Font.Gotham t.TextSize = 12
  t.TextColor3 = theme().text t.Text = tostring(label) t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = r
  local b = Instance.new("TextBox")
  b.Size = UDim2.new(1, 0, 0, 24) b.Position = UDim2.new(0, 0, 0, 20)
  b.Font = Enum.Font.Code b.TextSize = 13 b.Text = tostring(get() or "")
  b.BackgroundColor3 = theme().input b.TextColor3 = theme().text b.BorderSizePixel = 0 b.ClearTextOnFocus = false b.Parent = r
  local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
  b.FocusLost:Connect(function(enter) if enter then local v = b.Text if numeric then v = tonumber(v) or get() end set(v) end end)
  return b
end
function K.dropdown(parent, label, options, get, set)
  local r = K.row(parent, 46)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, 0, 0, 18) t.Font = Enum.Font.Gotham t.TextSize = 12
  t.TextColor3 = theme().text t.Text = tostring(label) t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = r
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(1, 0, 0, 24) b.Position = UDim2.new(0, 0, 0, 20)
  b.Font = Enum.Font.Gotham b.TextSize = 13 b.BackgroundColor3 = theme().btn b.TextColor3 = theme().text
  b.TextXAlignment = Enum.TextXAlignment.Left b.BorderSizePixel = 0 b.AutoButtonColor = true b.Parent = r
  local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = b
  local open = nil
  local function paint() b.Text = "  " .. tostring(get()) .. "  ▾" end
  paint()
  b.MouseButton1Click:Connect(function()
    if open then open:Destroy() open = nil return end
    open = Instance.new("Frame")
    open.Size = UDim2.new(0, b.AbsoluteSize.X, 0, math.min(#options, 8) * 24)
    open.Position = UDim2.fromOffset(b.AbsolutePosition.X, b.AbsolutePosition.Y + 26)
    open.BackgroundColor3 = theme().panel open.BorderSizePixel = 1 open.BorderColor3 = theme().border
    open.ZIndex = 100 open.Parent = E().shell.root()
    for i, op in ipairs(options) do
      local ob = Instance.new("TextButton")
      ob.Size = UDim2.new(1, 0, 0, 24) ob.Position = UDim2.new(0, 0, 0, (i - 1) * 24)
      ob.Font = Enum.Font.Gotham ob.TextSize = 12 ob.Text = "  " .. tostring(op) ob.TextXAlignment = Enum.TextXAlignment.Left
      ob.BackgroundColor3 = theme().panel ob.TextColor3 = theme().text ob.BorderSizePixel = 0 ob.ZIndex = 101 ob.Parent = open
      ob.MouseButton1Click:Connect(function() set(op) paint() open:Destroy() open = nil end)
    end
  end)
  return b
end
function K.color(parent, label, get, set)
  local r = K.row(parent, 30)
  local t = Instance.new("TextLabel")
  t.BackgroundTransparency = 1 t.Size = UDim2.new(1, -56, 1, 0) t.Font = Enum.Font.Gotham t.TextSize = 13
  t.TextColor3 = theme().text t.Text = tostring(label) t.TextXAlignment = Enum.TextXAlignment.Left t.Parent = r
  local b = Instance.new("TextButton")
  b.Size = UDim2.new(0, 48, 0, 22) b.Position = UDim2.new(1, -48, 0, 4)
  b.Text = "" b.BorderSizePixel = 1 b.BorderColor3 = theme().border b.AutoButtonColor = false b.Parent = r
  local presets = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 170, 0), Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 0, 255), Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 30, 30), Color3.fromRGB(150, 150, 150) }
  local function paint() b.BackgroundColor3 = get() or Color3.new(1, 1, 1) end
  paint()
  b.MouseButton1Click:Connect(function()
    local cur = get() or presets[1]
    local idx = 1
    for i, p in ipairs(presets) do if math.abs(p.R - cur.R) < 0.01 and math.abs(p.G - cur.G) < 0.01 and math.abs(p.B - cur.B) < 0.01 then idx = i break end end
    set(presets[(idx % #presets) + 1]) paint()
  end)
  return b
end
function K.cmd(parent, id)
  local c = E().registry.byId[id]
  if not c then return K.label(parent, "?", true) end
  return K.button(parent, (c.label or id) .. "  —  " .. (c.tip or ""), function() E().cmd.run(id) end)
end
function K.storeToggle(parent, label, key)
  return K.toggle(parent, label, function() return E().store.get(key) end, function(v) E().store.set(key, v) end)
end
function K.storeSlider(parent, label, key, min, max, step)
  return K.slider(parent, label, min, max, step, function() return tonumber(E().store.get(key)) or min end, function(v) E().store.set(key, v) end)
end
function K.storeText(parent, label, key, numeric)
  return K.text(parent, label, function() return E().store.get(key) end, function(v) E().store.set(key, v) end, numeric)
end
E().kit = K
return K
