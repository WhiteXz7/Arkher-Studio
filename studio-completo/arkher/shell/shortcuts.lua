-- arkher/shell/shortcuts.lua — key bindings auto-built from registry key fields.
local SC = { map = {} }
local function E() return _G.ARKHER end
local function parseKey(s)
  -- "Ctrl+Shift+Z" -> {ctrl=true,shift=true,code=Z}
  local parts = {}
  for p in string.gmatch(s, "[^+]+") do parts[#parts + 1] = p end
  local b = { ctrl = false, shift = false, alt = false, code = nil }
  for _, p in ipairs(parts) do
    local l = p:lower()
    if l == "ctrl" then b.ctrl = true elseif l == "shift" then b.shift = true elseif l == "alt" then b.alt = true
    elseif l == "del" then b.code = "Delete" elseif l == "esc" then b.code = "Escape"
    elseif l == "num1" then b.code = "One"
    elseif p == "=" then b.code = "Equals" elseif p == "-" then b.code = "Minus"
    elseif #p == 1 then b.code = p:upper()
    else b.code = p end
  end
  return b
end
local function canonical(s)
  local b = parseKey(s)
  return (b.ctrl and "Ctrl+" or "") .. (b.shift and "Shift+" or "") .. (b.code or "")
end
function SC.build()
  SC.map = {}
  for _, t in ipairs(E().registry.tabs) do
    for _, c in ipairs(t.commands) do
      if c.key and c.key ~= "" then local k = canonical(c.key) if not SC.map[k] then SC.map[k] = c.id end end
    end
  end
  SC.map["Ctrl+K"] = SC.map["Ctrl+K"] or "view_cmdpalette"
  local UIS = game:GetService("UserInputService")
  UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
    -- don't steal typing keys (except Esc/Ctrl combos)
    local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
    local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
    local kc = inp.KeyCode.Name
    local combo = (ctrl and "Ctrl+" or "") .. (shift and "Shift+" or "") .. kc
    -- normalize single letters F-keys etc.
    local id = SC.map[combo] or SC.map[kc]
    if kc == "Escape" then
      E().sel.set({})
      E().shell.layout("reset")
      return
    end
    if id then
      E().cmd.run(id)
    end
  end)
  E().out.log("Shortcuts: " .. (function() local n = 0 for _, _ in pairs(SC.map) do n = n + 1 end return n end)() .. " bindings.")
end
E().shortcuts = SC
return SC
