-- arkher/shell/sel.lua — selection (Studio Selection service when available + fallback).
local SEL = { list = {}, boxes = {}, hl = nil, changed = {} }
local function studioSel()
  local ok, s = pcall(game.GetService, game, "Selection")
  return ok and s or nil
end
function SEL.get() local out = {} for _, o in ipairs(SEL.list) do if o and o.Parent then out[#out + 1] = o end end return out end
function SEL.set(t)
  SEL.list = {}
  for _, o in ipairs(t or {}) do if o and o.Parent then SEL.list[#SEL.list + 1] = o end end
  local ss = studioSel()
  if ss then pcall(function() ss:Set(SEL.list) end) end
  SEL.refresh()
  for _, f in ipairs(SEL.changed) do pcall(f, SEL.list) end
  if _G.ARKHER.props then _G.ARKHER.props.show(SEL.list[1]) end
end
function SEL.add(o) local t = SEL.get() t[#t + 1] = o SEL.set(t) end
function SEL.onChange(f) SEL.changed[#SEL.changed + 1] = f end
function SEL.clearBoxes() for _, b in ipairs(SEL.boxes) do pcall(function() b:Destroy() end) end SEL.boxes = {} if SEL.hl then pcall(function() SEL.hl:Destroy() end) SEL.hl = nil end end
function SEL.refresh()
  SEL.clearBoxes()
  local list = SEL.get()
  if #list == 0 then return end
  local ok, _ = pcall(function() return Instance.new("Highlight") end)
  if ok and _G.ARKHER.store.get("perfmode") == false then
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.85 hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(0, 170, 255)
    local f = list[1]
    if #list == 1 and (f:IsA("BasePart") or f:IsA("Model")) then hl.Adornee = f hl.Parent = f
    else local m = Instance.new("Model") m.Name = "ARKHER_selhl" for _, o in ipairs(list) do if o:IsA("BasePart") and o.Parent then local w = o:Clone() w.Anchored = true w.CanCollide = false w.Transparency = 1 w.Parent = m end end m.Parent = workspace hl.Adornee = m hl.Parent = m end
    SEL.hl = hl
  else
    for _, o in ipairs(list) do
      if o:IsA("BasePart") then local b = Instance.new("SelectionBox") b.Adornee = o b.Color3 = Color3.fromRGB(0, 170, 255) b.Parent = o SEL.boxes[#SEL.boxes + 1] = b
      elseif o:IsA("Model") then local cf, sz = o:GetBoundingBox() local b = Instance.new("SelectionBox") b.Adornee = o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart") if b.Adornee then b.Color3 = Color3.fromRGB(0, 170, 255) b.Parent = b.Adornee SEL.boxes[#SEL.boxes + 1] = b end end
    end
  end
end
_G.ARKHER.sel = SEL
return SEL
