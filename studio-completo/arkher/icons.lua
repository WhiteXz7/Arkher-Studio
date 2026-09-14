-- arkher/icons.lua — sistema central de icones vetoriais (0 emoji, 0 unicode-art).
-- Fonte: ICONS (gerado de iconspec.json pelo build). Render = Frames nativos
-- com posicao/tamanho em escala + Rotation; estados via recoloracao.
-- Uso: Icons.render(parent, "terrain", 28, {x=0,y=0}) -> host Frame.
--      Icons.setState(host, "active"|"inactive"|"hover"|"pressed"|"disabled")
local Icons = {}
local U = require("arkher.util")

local function c3(rgb) return Color3.new(rgb[1], rgb[2], rgb[3]) end

-- paleta de estados: multiplica a cor-base de cada pixel.
local STATE_TINT = {
  active = { 1.0, 1.0, 1.0 },
  inactive = { 0.55, 0.6, 0.7 },
  hover = { 1.15, 1.2, 1.3 },
  pressed = { 0.8, 0.85, 0.95 },
  disabled = { 0.35, 0.38, 0.45 },
}
local function tint(col, m)
  return Color3.new(math.min(col.R * m[1], 1), math.min(col.G * m[2], 1), math.min(col.B * m[3], 1))
end

function Icons.names()
  return U.keys(ICONS)
end

function Icons.exists(name)
  if type(name) ~= "string" then return false end
  return ICONS[name] ~= nil or ICONS[name:lower()] ~= nil
end

-- desenha o icone `name` dentro de `parent` (host size x size, pos x,y).
function Icons.render(parent, name, size, x, y)
  size = size or 24
  local def = ICONS[name] or (type(name) == "string" and ICONS[name:lower()] or nil)
  if not def then
    -- fallback honesto: quadrado vazado = icone ausente (nunca quebra o build).
    local miss = Instance.new("Frame")
    miss.Name = "IconMiss"
    miss.Size = UDim2.fromOffset(size, size)
    miss.Position = UDim2.fromOffset(x or 0, y or 0)
    miss.BackgroundTransparency = 1
    miss.BorderSizePixel = 0
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(240, 80, 80)
    st.Thickness = 2
    st.Parent = miss
    miss.Parent = parent
    return miss
  end
  local host = Instance.new("Frame")
  host.Name = "Icon"
  host.Size = UDim2.fromOffset(size, size)
  host.Position = UDim2.fromOffset(x or 0, y or 0)
  host.BackgroundTransparency = 1
  host.BorderSizePixel = 0
  local base = {}
  for i, px in ipairs(def) do
    local f = Instance.new("Frame")
    f.Name = "p" .. i
    f.BorderSizePixel = 0
    f.Position = UDim2.new(px[1], 0, px[2], 0)
    f.Size = UDim2.new(px[3], 0, px[4], 0)
    local col = c3(px[5])
    f.BackgroundColor3 = col
    if px[6] and px[6] ~= 0 then f.Rotation = px[6] end
    f.Parent = host
    base[#base + 1] = col
  end
  host:SetAttribute("IconName", name)
  host:SetAttribute("IconState", "active")
  -- guarda cores-base p/ recolorir sem Perder referencia.
  local store = Instance.new("StringValue")
  store.Name = "BaseColors"
  local enc = {}
  for _, col in ipairs(base) do enc[#enc + 1] = string.format("%.4f,%.4f,%.4f", col.R, col.G, col.B) end
  store.Value = table.concat(enc, ";")
  store.Parent = host
  return host
end

function Icons.setState(host, state)
  local m = STATE_TINT[state or "active"] or STATE_TINT.active
  local store = host and host:FindFirstChild("BaseColors")
  if not store then return end
  local i = 0
  for _, part in ipairs(U.split(store.Value, ";")) do
    i = i + 1
    local f = host:FindFirstChild("p" .. i)
    if f then
      local rgb = U.split(part, ",")
      local col = Color3.new(tonumber(rgb[1]) or 1, tonumber(rgb[2]) or 1, tonumber(rgb[3]) or 1)
      pcall(function() f.BackgroundColor3 = tint(col, m) end)
    end
  end
  pcall(function() host:SetAttribute("IconState", state) end)
end

return Icons
