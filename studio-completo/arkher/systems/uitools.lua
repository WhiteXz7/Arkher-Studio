-- arkher/systems/uitools.lua — GuiObject ops (align/distribute/modal/preview/a11y).
local G = {}
local function E() return _G.ARKHER end
local function guis(list) local o = {} for _, v in ipairs(list or {}) do if v and v.Parent and v:IsA("GuiObject") then o[#o + 1] = v end end return o end
function G.align(list)
  local g = guis(list) if #g < 2 then E().toast("Select 2+ GuiObjects.") return end
  local y = g[1].Position.Y
  for i = 2, #g do g[i].Position = UDim2.new(g[i].Position.X.Scale, g[i].Position.X.Offset, y.Scale, y.Offset) end
  E().undo.commit("gui align")
end
function G.distribute(list)
  local g = guis(list) if #g < 3 then E().toast("Select 3+ GuiObjects.") return end
  table.sort(g, function(a, b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
  local x0 = g[1].Position.X.Offset local x1 = g[#g].Position.X.Offset
  for i = 2, #g - 1 do local x = x0 + (x1 - x0) * ((i - 1) / (#g - 1)) g[i].Position = UDim2.new(g[i].Position.X.Scale, math.floor(x), g[i].Position.Y.Scale, g[i].Position.Y.Offset) end
  E().undo.commit("gui distribute")
end
function G.showhide(list) local g = guis(list) for _, o in ipairs(g) do o.Visible = not o.Visible end E().undo.commit("gui visible") end
function G.modal(o)
  if o and o:IsA("GuiObject") then local sg = o:FindFirstAncestorWhichIsA("ScreenGui") or o:FindFirstAncestorWhichIsA("GuiBase") end
  local sg = o and o:FindFirstAncestorWhichIsA("ScreenGui")
  if sg then sg.DisplayOrder = 999 E().toast(sg.Name .. " set modal-focus (top order).") else E().toast("Select a GuiObject inside a ScreenGui.") end
end
function G.preview(o)
  local sg = o and (o:IsA("ScreenGui") and o or o:FindFirstAncestorWhichIsA("ScreenGui"))
  if not sg then E().toast("Select a ScreenGui.") return end
  local pg = game:GetService("Players").LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
  if pg then local c = sg:Clone() c.Name = "ARKHER_preview" c.Parent = pg E().toast("Previewing (delete ARKHER_preview to close).") end
end
function G.a11y(o)
  local sg = o and (o:IsA("ScreenGui") and o or o:FindFirstAncestorWhichIsA("ScreenGui"))
  if not sg then E().toast("Select a ScreenGui.") return end
  local small, total = 0, 0
  for _, d in ipairs(sg:GetDescendants()) do
    if d:IsA("GuiButton") then total = total + 1 if d.AbsoluteSize.X < 44 or d.AbsoluteSize.Y < 44 then small = small + 1 end end
  end
  E().out.log(string.format("A11y: %d buttons, %d below 44px touch target.", total, small))
end
function G.export(o)
  local sg = o and (o:IsA("ScreenGui") and o or o:FindFirstAncestorWhichIsA("ScreenGui"))
  if not sg then E().toast("Select a ScreenGui.") return end
  local function ser(x) local t = { c = x.ClassName, n = x.Name, ch = {} } pcall(function() t.pos = { x.Position.X.Scale, x.Position.X.Offset, x.Position.Y.Scale, x.Position.Y.Offset } t.size = { x.Size.X.Scale, x.Size.X.Offset, x.Size.Y.Scale, x.Size.Y.Offset } end) for _, ch in ipairs(x:GetChildren()) do t.ch[#t.ch + 1] = ser(ch) end return t end
  E().out.log("GUI " .. game:GetService("HttpService"):JSONEncode(ser(sg)))
end
function G.import(a) E().panel.open("ui_import", a) end
E().systems.uitools = G
return G
