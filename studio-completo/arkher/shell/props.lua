-- arkher/shell/props.lua — property editor (common props, typed, undoable).
local PR = { target = nil }
local function E() return _G.ARKHER end
function PR.build(dock)
  PR.body = dock:FindFirstChild("Body")
  PR.show(nil)
end
local function editorsFor(o)
  local ed = { { "Name", "string" } }
  if o:IsA("BasePart") then
    ed[#ed + 1] = { "Color", "color" } ed[#ed + 1] = { "Material", "material" }
    ed[#ed + 1] = { "Transparency", "num01" } ed[#ed + 1] = { "Reflectance", "num01" }
    ed[#ed + 1] = { "Anchored", "bool" } ed[#ed + 1] = { "CanCollide", "bool" }
    ed[#ed + 1] = { "Size", "vec" } ed[#ed + 1] = { "Position", "vecRO" }
  elseif o:IsA("Light") then
    ed[#ed + 1] = { "Enabled", "bool" } ed[#ed + 1] = { "Color", "color" }
    ed[#ed + 1] = { "Brightness", "num" } ed[#ed + 1] = { "Range", "num" } ed[#ed + 1] = { "Shadows", "bool" }
  elseif o:IsA("Sound") then
    ed[#ed + 1] = { "SoundId", "string" } ed[#ed + 1] = { "Volume", "num" }
    ed[#ed + 1] = { "Looped", "bool" } ed[#ed + 1] = { "Playing", "boolRO" }
  elseif o:IsA("ParticleEmitter") then
    ed[#ed + 1] = { "Enabled", "bool" } ed[#ed + 1] = { "Rate", "num" } ed[#ed + 1] = { "Texture", "string" }
  elseif o:IsA("Humanoid") then
    ed[#ed + 1] = { "Health", "num" } ed[#ed + 1] = { "MaxHealth", "num" }
    ed[#ed + 1] = { "WalkSpeed", "num" } ed[#ed + 1] = { "JumpPower", "num" }
  elseif o:IsA("GuiObject") then
    ed[#ed + 1] = { "Visible", "bool" } ed[#ed + 1] = { "BackgroundColor3", "color" }
    ed[#ed + 1] = { "BackgroundTransparency", "num01" } ed[#ed + 1] = { "ZIndex", "num" }
  elseif o:IsA("LuaSourceContainer") then
    ed[#ed + 1] = { "Disabled", "bool" }
  elseif o:IsA("Model") then
    ed[#ed + 1] = { "PrimaryPart", "ro" }
  end
  return ed
end
function PR.show(o)
  PR.target = o
  local body = PR.body
  if not body then return end
  for _, ch in ipairs(body:GetChildren()) do if not ch:IsA("UIListLayout") then ch:Destroy() end end
  local th = E().shell.theme()
  local order = 0
  local function lab(t)
    order = order + 1
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20) l.LayoutOrder = order l.Font = Enum.Font.GothamBold l.TextSize = 12
    l.TextColor3 = th.text l.Text = t l.BackgroundTransparency = 1 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = body
  end
  if not o or not o.Parent then lab("Nothing selected.") return end
  lab(o.ClassName .. ": " .. o.Name)
  for _, e in ipairs(editorsFor(o)) do
    local key, kind = e[1], e[2]
    local ok, val = pcall(function() return o[key] end)
    if ok then
      order = order + 1
      if kind == "bool" then
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 22) b.LayoutOrder = order b.Font = Enum.Font.Gotham b.TextSize = 12
        b.Text = key .. ": " .. tostring(val) b.BackgroundColor3 = th.btn b.TextColor3 = th.text b.BorderSizePixel = 0 b.Parent = body
        b.MouseButton1Click:Connect(function() E().undo.prop(o, key, not val, key) PR.show(o) end)
      elseif kind == "string" then
        local t = Instance.new("TextBox")
        t.Size = UDim2.new(1, 0, 0, 22) t.LayoutOrder = order t.Font = Enum.Font.Code t.TextSize = 12
        t.Text = key .. " = " .. tostring(val) t.BackgroundColor3 = th.input t.TextColor3 = th.text t.BorderSizePixel = 0 t.ClearTextOnFocus = false t.Parent = body
        t.FocusLost:Connect(function(enter) if enter then local v = t.Text:match("=%s*(.*)") or t.Text E().undo.prop(o, key, v, key) PR.show(o) end end)
      elseif kind == "num" or kind == "num01" then
        local t = Instance.new("TextBox")
        t.Size = UDim2.new(1, 0, 0, 22) t.LayoutOrder = order t.Font = Enum.Font.Code t.TextSize = 12
        t.Text = key .. " = " .. tostring(val) t.BackgroundColor3 = th.input t.TextColor3 = th.text t.BorderSizePixel = 0 t.ClearTextOnFocus = false t.Parent = body
        t.FocusLost:Connect(function(enter) if enter then local v = tonumber(t.Text:match("=%s*(.*)") or t.Text) if v then if kind == "num01" then v = math.clamp(v, 0, 1) end E().undo.prop(o, key, v, key) end PR.show(o) end end)
      elseif kind == "color" then
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 22) b.LayoutOrder = order b.Font = Enum.Font.Gotham b.TextSize = 12
        b.Text = key b.BackgroundColor3 = val b.TextColor3 = Color3.new(1, 1, 1) b.BorderSizePixel = 1 b.BorderColor3 = th.border b.Parent = body
        local presets = { Color3.new(1, 0, 0), Color3.new(1, 0.6, 0), Color3.new(1, 1, 0), Color3.new(0, 1, 0), Color3.new(0, 0.6, 1), Color3.new(1, 1, 1), Color3.new(0.1, 0.1, 0.1) }
        b.MouseButton1Click:Connect(function() local n = presets[math.random(#presets)] E().undo.prop(o, key, n, key) PR.show(o) end)
      elseif kind == "material" then
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 22) b.LayoutOrder = order b.Font = Enum.Font.Gotham b.TextSize = 12
        b.Text = "Material: " .. val.Name b.BackgroundColor3 = th.btn b.TextColor3 = th.text b.BorderSizePixel = 0 b.Parent = body
        b.MouseButton1Click:Connect(function() E().panel.open("mat_browse", {}) end)
      elseif kind == "vec" then
        lab(key .. " = " .. string.format("%.1f, %.1f, %.1f", val.X, val.Y, val.Z))
      else
        lab(key .. " = " .. tostring(val))
      end
    end
  end
  order = order + 1
  local ab = Instance.new("TextButton")
  ab.Size = UDim2.new(1, 0, 0, 24) ab.LayoutOrder = order ab.Font = Enum.Font.GothamBold ab.TextSize = 12
  ab.Text = "Attributes + Tags" ab.BackgroundColor3 = th.btn ab.TextColor3 = th.text ab.BorderSizePixel = 0 ab.Parent = body
  ab.MouseButton1Click:Connect(function() E().panel.open("char_attrs", {}) end)
end
E().props = PR
return PR
