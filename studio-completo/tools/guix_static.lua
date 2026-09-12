-- GuixStatic — construtores da GUI X ESTÁTICA (executados SÓ na gravação).
-- Tudo aqui vira instância REAL dentro do Canvas no .rbxl final.
-- A fiação (cliques/remotos) mora nos LocalScripts 05/06/07/09 — aqui é só forma.
-- Convenção de nomes: estável, espelhada nos scripts de fiação.

local GuixStatic = {}

local M = {
  bg = Color3.fromRGB(7, 16, 32), panel = Color3.fromRGB(9, 23, 44),
  section = Color3.fromRGB(20, 42, 75), border = Color3.fromRGB(52, 80, 120),
  text = Color3.fromRGB(228, 240, 255), muted = Color3.fromRGB(146, 170, 202),
  blue = Color3.fromRGB(35, 139, 230), selected = Color3.fromRGB(17, 76, 139),
  cyan = Color3.fromRGB(43, 203, 243), purple = Color3.fromRGB(166, 117, 240),
  gold = Color3.fromRGB(240, 185, 70), acc = Color3.fromRGB(43, 203, 243),
}

local function B(cls, props, parent)
  local o = Instance.new(cls)
  for k, v in pairs(props) do o[k] = v end
  o.Parent = parent
  return o
end
local function H(o, r)
  local c = Instance.new("UICorner")
  c.CornerRadius = UDim.new(0, r or 7)
  c.Parent = o
  return o
end
local function ST(o, th, col)
  local s0 = Instance.new("UIStroke")
  s0.Thickness = th or 1
  s0.Color = col or M.border
  s0.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  s0.Parent = o
  return o
end

-- réplica fiel da chrome mkWin do 08 (sombra + capa + grip + título + tag + X + corpo)
local function mkShell(id, title, tag, w, h, parent, acc)
  acc = acc or M.cyan
  local f = B("Frame", {
    Name = "Deck_" .. id, Size = UDim2.fromOffset(w, h),
    Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2),
    BackgroundColor3 = M.bg, BorderSizePixel = 0, Visible = false,
    Active = true, ZIndex = 40,
  }, parent)
  H(f, 10)
  ST(f, 1.2, M.border)
  local shw = B("Frame", {
    Name = "Shadow", Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(6, 8),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.84,
    BorderSizePixel = 0, ZIndex = 38, Active = false,
  }, f)
  H(shw, 14)
  local cap = B("Frame", { Name = "Cap", Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = M.panel, BorderSizePixel = 0, ZIndex = 41 }, f)
  H(cap, 10)
  B("Frame", { Name = "CapFill", Size = UDim2.new(1, 0, 0, 15), Position = UDim2.fromOffset(0, 15),
    BackgroundColor3 = M.panel, BorderSizePixel = 0, ZIndex = 41 }, cap)
  B("Frame", { Name = "Hairline", Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 29),
    BackgroundColor3 = M.border, BorderSizePixel = 0, ZIndex = 42 }, cap)
  local grip = B("Frame", { Name = "Grip", Size = UDim2.fromOffset(3, 14), Position = UDim2.fromOffset(9, 8),
    BackgroundColor3 = acc, BorderSizePixel = 0, ZIndex = 43 }, cap)
  H(grip, 2)
  B("TextLabel", {
    Name = "Title", Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(18, 0),
    BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
    TextSize = 13, TextColor3 = M.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42,
  }, cap)
  B("TextLabel", {
    Name = "Tag", Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -160, 0, 0),
    BackgroundTransparency = 1, Text = tag or "", Font = Enum.Font.Gotham,
    TextSize = 10, TextColor3 = M.muted, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 42,
  }, cap)
  local cls = B("TextButton", {
    Name = "Close", Size = UDim2.fromOffset(22, 20), Position = UDim2.new(1, -27, 0, 5),
    BackgroundColor3 = M.panel, Text = "✕", Font = Enum.Font.GothamBold,
    TextSize = 11, TextColor3 = M.muted, BorderSizePixel = 0, ZIndex = 43,
  }, cap)
  H(cls, 5)
  local body = B("Frame", {
    Name = "Body", Size = UDim2.new(1, 0, 1, -30), Position = UDim2.fromOffset(0, 30),
    BackgroundTransparency = 1, ZIndex = 41,
  }, f)
  return { root = f, body = body, close = cls }
end

local function subtitle(parent, text, y)
  return B("TextLabel", {
    Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, y or 6),
    BackgroundTransparency = 1, Text = text,
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = M.muted,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
  }, parent)
end

local function actionBtn(parent, name, label, y, h)
  local b0 = B("TextButton", {
    Name = name, Size = UDim2.new(1, -16, 0, h or 30), Position = UDim2.fromOffset(8, y),
    BackgroundColor3 = M.selected, Text = label, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = M.text, BorderSizePixel = 0, AutoButtonColor = true, ZIndex = 43,
  }, parent)
  H(b0, 8)
  ST(b0, 1, M.border)
  return b0
end

local function statusLbl(parent, name, w, h)
  local s0 = B("TextLabel", {
    Name = name, Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 1, -42),
    BackgroundColor3 = M.panel, BorderSizePixel = 0, Text = "aguardando…",
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = M.muted,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43,
  }, parent)
  H(s0, 8)
  return s0
end

-- ============ ícones 28px (mesma arte do 09, escala 1.75, tudo Frame) ============
local function drawXIcon(kind, g2)
  local S = 1.75
  local function P(v) return math.floor(v * S + 0.5) end
  local function box(x, y, w2, h2, color, round, transp)
    local f = B("Frame", {
      Size = UDim2.fromOffset(math.max(P(w2), 1), math.max(P(h2), 1)),
      Position = UDim2.fromOffset(P(x), P(y)),
      BackgroundColor3 = color, BackgroundTransparency = transp or 0,
      BorderSizePixel = 0, ZIndex = 32,
    }, g2)
    if round then H(f, math.max(math.floor(round * S + 0.5), 1)) end
    return f
  end
  local function line(x1, y1, x2, y2, color, thick)
    local dx, dy = (x2 - x1), (y2 - y1)
    local th = math.max(P(thick or 2), 1)
    local len = math.sqrt(dx * dx + dy * dy) * S
    local f = B("Frame", {
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromOffset(P((x1 + x2) / 2), P((y1 + y2) / 2)),
      Size = UDim2.fromOffset(math.floor(len + th + 0.5), th),
      Rotation = math.deg(math.atan2(dy, dx)),
      BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 32,
    }, g2)
    H(f, math.floor(th / 2 + 0.5))
    return f
  end
  if kind == "PART" then
    box(3, 3, 10, 10, M.blue, 3)
    box(5, 5, 6, 3, Color3.fromRGB(90, 170, 255), 2)
  elseif kind == "BASEPLATE" then
    box(1, 9, 14, 6, Color3.fromRGB(100, 104, 118), 2)
    box(1, 7, 14, 3, Color3.fromRGB(125, 130, 146), 2)
    box(5, 1, 5, 5, M.cyan, 3)
  elseif kind == "UNION" then
    box(1, 3, 10, 10, Color3.fromRGB(43, 203, 243), 7, 0.55)
    box(6, 3, 10, 10, Color3.fromRGB(240, 185, 70), 7, 0.55)
  elseif kind == "NEGATE" then
    box(1, 3, 10, 10, Color3.fromRGB(43, 203, 243), 7, 0.55)
    box(7, 4, 8, 8, Color3.fromRGB(255, 143, 117), 6, 0.15)
  elseif kind == "TOOLBOX" then
    box(1, 5, 14, 10, Color3.fromRGB(190, 140, 60), 3)
    box(5, 2, 6, 3, Color3.fromRGB(150, 108, 44), 3)
    box(1, 8, 14, 2, Color3.fromRGB(150, 108, 44), 1)
  elseif kind == "XFAB" then
    line(3, 8, 8, 3, M.gold, 2)
    line(8, 3, 13, 8, M.gold, 2)
    line(13, 8, 8, 13, M.gold, 2)
    line(8, 13, 3, 8, M.gold, 2)
    box(6, 6, 4, 4, M.cyan, 2)
  end
end

-- ============ XBar: barra vertical de ações (6 botões) ============
function GuixStatic.buildXBar(outRoot)
  local bar = B("Frame", {
    Name = "ArkherXBar", Size = UDim2.fromOffset(72, 400), Position = UDim2.fromOffset(346, 196),
    BackgroundColor3 = M.bg, BorderSizePixel = 0, ZIndex = 30, Active = true,
  }, outRoot)
  H(bar, 10)
  ST(bar, 1.2, M.border)
  local defs = {
    { "ArkherX_Part", "Part ▸", "PART" },
    { "ArkherX_Base", "Baseplate", "BASEPLATE" },
    { "ArkherX_Union", "Union", "UNION" },
    { "ArkherX_Negate", "Negate", "NEGATE" },
    { "ArkherX_Toolbox", "Toolbox", "TOOLBOX" },
    { "ArkherX_Launcher", "✦ X", "XFAB" },
  }
  for i, d in ipairs(defs) do
    local b0 = B("TextButton", {
      Name = d[1], Size = UDim2.fromOffset(62, 58), Position = UDim2.fromOffset(5, 8 + (i - 1) * 64),
      BackgroundColor3 = M.panel, Text = "", BorderSizePixel = 0, ZIndex = 31,
      AutoButtonColor = true, Active = true, Selectable = true,
    }, bar)
    H(b0, 8)
    ST(b0, 1, M.border)
    local ic = B("Frame", {
      Name = "Icon", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0.5, -14, 0, 3),
      BackgroundTransparency = 1, ZIndex = 32,
    }, b0)
    drawXIcon(d[3], ic)
    B("TextLabel", {
      Name = "Caption", Size = UDim2.new(1, -4, 0, 16), Position = UDim2.new(0, 2, 1, -19),
      BackgroundTransparency = 1, Text = d[2], Font = Enum.Font.GothamBold,
      TextSize = 8, TextColor3 = M.text, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 32,
    }, b0)
  end
  return bar
end

-- ============ Shapes popup (7 formas) ============
GuixStatic.SHAPES = {
  { "Block", "Block (4×2×4)", "ShapeRow_Block" },
  { "Ball", "Ball (esfera)", "ShapeRow_Ball" },
  { "Cylinder", "Cylinder (roda)", "ShapeRow_Cylinder" },
  { "CylinderVertical", "Cylinder vertical (pilar)", "ShapeRow_CylinderVertical" },
  { "Wedge", "Wedge (rampa)", "ShapeRow_Wedge" },
  { "CornerWedge", "CornerWedge (canto)", "ShapeRow_CornerWedge" },
  { "Truss", "Truss (treliça)", "ShapeRow_Truss" },
}

function GuixStatic.buildPopups(outRoot)
  local pop = B("Frame", {
    Name = "ServerEditorPopups", Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1, ZIndex = 50,
  }, outRoot)
  local f = B("Frame", {
    Name = "ArkherShapesPopup", Size = UDim2.fromOffset(230, 208), Position = UDim2.fromOffset(420, 200),
    BackgroundColor3 = M.panel, BorderSizePixel = 0, ZIndex = 60, Active = true, Visible = false,
  }, pop)
  H(f, 8)
  ST(f, 1.5, M.border)
  for i, spec in ipairs(GuixStatic.SHAPES) do
    local row = B("TextButton", {
      Name = spec[3], Size = UDim2.new(1, -12, 0, 24), Position = UDim2.fromOffset(6, 6 + (i - 1) * 28),
      BackgroundColor3 = M.panel, Text = "   " .. spec[2], Font = Enum.Font.GothamBold,
      TextSize = 12, TextColor3 = M.text, BorderSizePixel = 0, ZIndex = 61,
    }, f)
    H(row, 6)
  end
  return pop
end

-- ============ Launcher: central com os 25 editores ============
GuixStatic.LAUNCHER = {
  { "terrain", "TERRAIN X — editor territorial", "TE", Color3.fromRGB(120, 200, 120) },
  { "modeler", "MODELER X — estilo Blender", "MO", Color3.fromRGB(43, 203, 243) },
  { "animator", "ANIMATOR X — estilo Cascadeur", "AN", Color3.fromRGB(166, 117, 240) },
  { "espaco", "ESPAÇO X — criador orbital", "ES", Color3.fromRGB(90, 140, 255) },
  { "fabricar", "FABRICAR X — criar qualquer coisa", "FA", Color3.fromRGB(240, 185, 70) },
  { "water", "WATER X — oceanografia real", "WA", Color3.fromRGB(60, 170, 255) },
  { "atmos", "ATMOS X — céu e clima físicos", "AT", Color3.fromRGB(140, 200, 255) },
  { "clima", "CLIMA X — frentes H/L vivas", "CL", Color3.fromRGB(150, 220, 230) },
  { "vida", "VIDA X — NPCs e ecossistema", "VI", Color3.fromRGB(140, 230, 160) },
  { "cidade", "CIDADE X — vilas e metrópoles", "CI", Color3.fromRGB(230, 200, 140) },
  { "audio", "ÁUDIO X — mixer dos 7 buses", "AU", Color3.fromRGB(230, 150, 220) },
  { "fx", "FX X — partículas físicas", "FX", Color3.fromRGB(255, 170, 120) },
  { "cordas", "CORDAS X — Verlet íntegro", "CO", Color3.fromRGB(200, 180, 140) },
  { "toolbox", "TOOLBOX X — Creator Store", "TB", Color3.fromRGB(190, 140, 60) },
  { "props", "PROPS X — todas as propriedades", "PR", Color3.fromRGB(160, 180, 220) },
  { "cores", "CORES X — color picker real", "CR", Color3.fromRGB(255, 130, 180) },
  { "output", "OUTPUT X — log real do jogo", "OU", Color3.fromRGB(180, 210, 255) },
  { "comando", "COMANDO X — barra funcional", "CM", Color3.fromRGB(140, 255, 200) },
  { "scripts", "SCRIPTS X — editor com abas", "SC", Color3.fromRGB(170, 200, 255) },
  { "py", "PY X — ponte com o python", "PY", Color3.fromRGB(120, 220, 160) },
  { "sculpt", "SCULPT X — esculpir terreno", "SL", Color3.fromRGB(210, 170, 120) },
  { "grupos", "GRUPOS X — colisão real", "GR", Color3.fromRGB(200, 200, 160) },
  { "plugins", "PLUGINS X — motores on/off", "PL", Color3.fromRGB(190, 170, 255) },
  { "rig", "RIG X — Cascadeur++ FABRIK", "RG", Color3.fromRGB(255, 210, 120) },
  { "mesh", "MESH X — Blender++ boolean", "ME", Color3.fromRGB(120, 230, 230) },
}

function GuixStatic.buildLauncher(outRoot)
  local win = mkShell("launcher", "✦ ARKHER X — CENTRAL DE EDITORES", "25 editores · clique abre", 440, 520, outRoot, M.gold)
  subtitle(win.body, "Todos os editores X em GUI real — sem overlay, sem gambiarra.", 6)
  local list = B("ScrollingFrame", {
    Name = "List", Size = UDim2.new(1, -16, 1, -52), Position = UDim2.fromOffset(8, 28),
    BackgroundColor3 = M.bg, BorderSizePixel = 0, ZIndex = 43,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 6, ScrollBarImageColor3 = M.gold,
  }, win.body)
  H(list, 7)
  ST(list, 1, M.border)
  local lay = Instance.new("UIListLayout")
  lay.Padding = UDim.new(0, 4)
  lay.Parent = list
  local pad = Instance.new("UIPadding")
  pad.PaddingLeft = UDim.new(0, 6)
  pad.PaddingTop = UDim.new(0, 6)
  pad.PaddingRight = UDim.new(0, 6)
  pad.Parent = list
  for _, e in ipairs(GuixStatic.LAUNCHER) do
    local row = B("TextButton", {
      Name = "Launch_" .. e[1], Size = UDim2.new(1, -12, 0, 30),
      BackgroundColor3 = M.panel, Text = "", BorderSizePixel = 0,
      AutoButtonColor = true, ZIndex = 44,
    }, list)
    H(row, 7)
    ST(row, 1, M.border)
    local badge = B("Frame", {
      Name = "Badge", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(6, 3),
      BackgroundColor3 = e[4], BorderSizePixel = 0, ZIndex = 45,
    }, row)
    H(badge, 6)
    B("TextLabel", {
      Name = "Code", Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(6, 3),
      BackgroundTransparency = 1, Text = e[3], Font = Enum.Font.GothamBold,
      TextSize = 9, TextColor3 = Color3.fromRGB(7, 16, 32),
      TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 46,
    }, row)
    B("TextLabel", {
      Name = "Title", Size = UDim2.new(1, -62, 1, 0), Position = UDim2.fromOffset(36, 0),
      BackgroundTransparency = 1, Text = e[2], Font = Enum.Font.Gotham,
      TextSize = 11, TextColor3 = M.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 45,
    }, row)
    B("TextLabel", {
      Name = "Arrow", Size = UDim2.fromOffset(20, 30), Position = UDim2.new(1, -24, 0, 0),
      BackgroundTransparency = 1, Text = "›", Font = Enum.Font.GothamBold,
      TextSize = 16, TextColor3 = M.muted, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 45,
    }, row)
  end
  return win
end

-- ============ RIG X / MESH X (painéis únicos, textos originais do 06/07) ============
function GuixStatic.buildRig(outRoot)
  local win = mkShell("rig", "RIG X — Cascadeur++ (FABRIK+fisica)", "IK ao vivo", 340, 300, outRoot, M.gold)
  subtitle(win.body, "Alem do Cascadeur: IK ao vivo COM fisica do jogo", 6)
  actionBtn(win.body, "RigBtn_Demo", "Cadeia FABRIK demo (4 ossos + pole)", 30)
  actionBtn(win.body, "RigBtn_Balance", "Relatorio de equilibrio (COM → suporte)", 64)
  actionBtn(win.body, "RigBtn_Stop", "PARAR rig", 98)
  statusLbl(win.body, "RigStatus")
  return win
end

function GuixStatic.buildMesh(outRoot)
  local win = mkShell("mesh", "MESH X — Blender++ procedural", "boolean real", 340, 380, outRoot, M.cyan)
  subtitle(win.body, "Boolean convexo REAL — sem CSG service", 6)
  actionBtn(win.body, "MeshBtn_House", "CASA (janelas/porta = subtract real)", 30)
  actionBtn(win.body, "MeshBtn_Gear", "ENGRENAGEM (dentada por extrudes)", 64)
  actionBtn(win.body, "MeshBtn_Crystal", "CRISTAL (icosa + subdivide)", 98)
  actionBtn(win.body, "MeshBtn_Mesa", "MESA procedural (displace + smooth)", 132)
  actionBtn(win.body, "MeshBtn_Clean", "LIMPAR ultimo mesh", 176)
  statusLbl(win.body, "MeshStatus")
  return win
end

return GuixStatic
