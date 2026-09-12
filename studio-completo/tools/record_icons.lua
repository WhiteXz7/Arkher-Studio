-- record_icons.lua — grava os 48 ícones por Frame do v2 (ICON.*) como spec.
-- Produz _G.__ICONS = {icons={NODE...}, warnings={}}.
dofile("studio-completo/tools/mock.lua")

local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local OUT_Icons = Instance.new("Frame"); OUT_Icons.Name = "OUT_Icons"

local src = io.open("studio-completo/v2src/UI_TerrainEditor.lua"):read("*a")
local tailcall = src:match("ARKHER_REG%.[A-Za-z0-9_]+%(%)%s*$")
assert(tailcall, "driver final nao achado")
local driver = [[do
  local _names = {}
  for _n, _f in pairs(ICON) do if type(_f) == "function" then _names[#_names + 1] = _n end end
  table.sort(_names)
  for _, _n in ipairs(_names) do
    local _h = Instance.new("Frame")
    _h.Name = "Icon_" .. _n
    _h.Size = UDim2.new(0, 26, 0, 26)
    _h.BackgroundTransparency = 1
    _h.BorderSizePixel = 0
    _h.Parent = OUT_ICONS_REF
    local _ok, _err = pcall(ICON[_n], _h)
    print(((_ok and "[icon][ok] ") or "[icon][ERR] ") .. _n .. (_ok and "" or (": " .. tostring(_err))))
  end
end]]
src = src:gsub("ARKHER_REG%.[A-Za-z0-9_]+%(%)%s*$", driver)
-- expõe OUT_Icons p/ o driver (global temporária)
_G.OUT_ICONS_REF = OUT_Icons
assert(loadstring(src, "[iconsrc]"))()
_G.OUT_ICONS_REF = nil
print("[icon] fonte ok")

local SKIP = { Parent = true, ClassName = true, AbsoluteSize = true, AbsolutePosition = true,
  AbsoluteRotation = true, CFrame = true }
local WARNINGS = {}
local function encVal(v, path, key)
  local t = type(v)
  if t == "string" or t == "boolean" or t == "number" then return v end
  if t ~= "table" then WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=badtype:" .. t return nil end
  local tag = rawget(v, "__t")
  if tag == "Color3" then return { "C3", v.R, v.G, v.B } end
  if tag == "UDim2" then return { "U2", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } end
  if tag == "UDim" then return { "U1", v.Scale, v.Offset } end
  if tag == "Vector2" then return { "V2", v.X, v.Y } end
  if tag == "Vector3" then WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=Vector3-3D!" return nil end
  local nm = rawget(v, "__name")
  if type(nm) == "string" and nm:sub(1, 5) == "Enum." then return { "EN", nm:sub(6) } end
  WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=badtable:" .. tostring(tag or nm) return nil
end
local function dumpNode(o, path)
  local props = rawget(o, "__props")
  local expl = rawget(o, "__explicit")
  local cls = props.ClassName
  local p = path .. "/" .. tostring(props.Name)
  local pd = {}
  for k in pairs(expl) do
    if not SKIP[k] then
      local e = encVal(props[k], p, k)
      if e ~= nil then pd[k] = e end
    end
  end
  local kd = {}
  for _, ch in ipairs(rawget(o, "__children")) do kd[#kd + 1] = dumpNode(ch, p) end
  return { "NODE", cls, tostring(props.Name), pd, kd }
end

local icons = {}
for _, h in ipairs(OUT_Icons:GetChildren()) do
  icons[#icons + 1] = dumpNode(h, "")
end
_G.__ICONS = { icons = icons, warnings = WARNINGS }
print("[icon] SPEC pronta: icons=" .. #icons .. " warnings=" .. #WARNINGS)
