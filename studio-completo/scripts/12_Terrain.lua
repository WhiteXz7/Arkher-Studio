-- =============================================================
-- ARKHER Terrain Editor (12_Terrain) — pincel real sobre o Terrain
-- UI 100% assada (TE3_*); este script só LIGA os controles e traduz
-- gesto -> TerrainStroke/Undo/Layers/Gen/Water (server R10).
-- Plataformas R10: PC (mouse) + Mobile (touch) pintam; Console/VR: R11.
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "12: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "12: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "12: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 20)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ============ helpers ============
local function find(name)
  return shell:FindFirstChild(name, true)
end
local function setText(name, text)
  local o = find(name)
  if o then pcall(function() o.Text = text end) end
end
local function setVisible(name, v)
  local o = find(name)
  if o then pcall(function() o.Visible = v end) end
end
local function on(name, fn)
  local o = find(name)
  if not o then return nil end
  local ev = o.Activated or o.MouseButton1Click
  if ev then pcall(function() ev:Connect(fn) end) return o end
  return nil
end
local function onDown(o, fn)
  if not o then return false end
  local ev = nil
  pcall(function() ev = o.MouseButton1Down end)
  if ev then pcall(function() ev:Connect(fn) end) return true end
  return false
end
local function hasDown(o)
  if not o then return false end
  local ev = nil
  pcall(function() ev = o.MouseButton1Down end)
  return ev ~= nil
end
local function onHover(name, enterFn, leaveFn)
  local o = find(name)
  if not o then return end
  pcall(function()
    if o.MouseEnter and enterFn then o.MouseEnter:Connect(enterFn) end
    if o.MouseLeave and leaveFn then o.MouseLeave:Connect(leaveFn) end
  end)
end
local say
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  return (type(r) == "table" and r.result) or r, nil
end
say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
end
local function cam()
  return workspace.CurrentCamera
end
local function typing()
  local ok, box = pcall(function() return UIS:GetFocusedTextBox() end)
  return ok and box ~= nil
end
local function platform()
  local inp = _G.ArkherInput
  if inp and inp.platform then
    local ok, p = pcall(inp.platform)
    if ok and p then return p end
  end
  return "PC"
end

-- ============ estado ============
local TOOLS = { "draw", "sculpt", "raise", "lower", "flatten", "smooth", "erode",
  "crater", "paint", "replace", "water", "drain" }
local TOOL_HINT = {
  draw = "DRAW: add solid with material", sculpt = "SCULPT: carve air",
  raise = "RAISE: grow gradually", lower = "LOWER: shrink gradually",
  flatten = "FLATTEN: level to plane Y", smooth = "SMOOTH: blur neighbors",
  erode = "ERODE: noisy corrosion", crater = "CRATER: dig + rim",
  paint = "PAINT: recolor solid only", replace = "REPLACE: source->material",
  water = "WATER: fill liquid", drain = "DRAIN: remove liquid",
}
local MATS21 = { "Grass", "LeafyGrass", "Ground", "Mud", "Sand", "Sandstone",
  "Rock", "Slate", "Basalt", "Limestone", "Pavement", "Concrete", "Brick",
  "Cobblestone", "Asphalt", "Salt", "Snow", "Ice", "Glacier", "CrackedLava", "WoodPlanks" }
local BIOMES = { "meadow", "desert", "arctic", "volcanic" }
local S = { open = false, tool = "draw", size = 8, strength = 0.5, falloff = 0.5,
  hardness = 0.5, noise = 0, seed = 1, material = "Grass", symmetry = "none",
  planeY = nil, source = "Grass", layer = "", lsize = "M", seedG = 7, gsize = 128,
  height = 48, biome = "meadow", erosion = 1, waterLevel = nil, floodY = 4,
  rain = false, matIdx = 1, srcIdx = 1, bioIdx = 1, toolIdx = 1 }
local TE3_ALL = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local VP3_ALL = { "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status" }
local MD4_ALL = { "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status" }
local HLOG = {}
local lastHit = nil
local lastStats = { cells = 0, undo = 0, redo = 0, layers = 0 }

local function refreshStatus()
  local st = string.format("%s · r%d · %s · layer %s · cells %d · undo %d/%d",
    string.upper(S.tool), S.size, S.material,
    (S.layer ~= "" and S.layer or "-"), lastStats.cells or 0,
    lastStats.undo or 0, lastStats.redo or 0)
  setText("TE3_StatL", st)
end
local function refreshStats()
  local r = api("TerrainStats", {})
  if r then
    lastStats.cells = r.cells or 0
    lastStats.undo = r.undo or 0
    lastStats.redo = r.redo or 0
    lastStats.layers = r.layers or 0
    setText("TE3_Depth", tostring(lastStats.undo) .. "/" .. tostring(lastStats.redo))
    refreshStatus()
  end
end
local function logOp(text)
  table.insert(HLOG, 1, text)
  while #HLOG > 6 do table.remove(HLOG) end
  for i = 1, 6 do setText("TE3_H" .. (i - 1), HLOG[i] or "") end
end

-- ============ open/close ============
local Gizmo = {}
local endStroke -- forward (definida no stroke engine)
local function setOpen(v)
  S.open = v
  for _, n in ipairs(TE3_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  if platform() == "Mobile" then setVisible("M_TE", v) end
  if Gizmo.setVisible then Gizmo.setVisible(v) end
  if v then
    for _, n in ipairs(VP3_ALL) do setVisible(n, false) end
    for _, n in ipairs(MD4_ALL) do setVisible(n, false) end
    setVisible("M_VP", false)
    setVisible("M_MD", false)
    for _, ed in ipairs({ "ArkherViewport", "ArkherModeler" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    refreshStats()
    refreshLayers()
    say("Terrain Editor PRO open (" .. platform() .. ").")
  else
    endStroke(true)
    say("Terrain Editor closed.")
  end
end

-- ============ toolbar + tooltip ============
local BTN_BG = nil
local ACC_BG = nil
pcall(function()
  local b = find("TE3_T_draw")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("TE3_Gen")
  if g then ACC_BG = g.BackgroundColor3 end
end)
local function setTool(t)
  S.tool = t
  for i, k in ipairs(TOOLS) do
    if k == t then S.toolIdx = i break end
  end
  for _, k in ipairs(TOOLS) do
    local o = find("TE3_T_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == t and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  setText("M_TE_Tool", string.upper(t))
  refreshStatus()
end
for _, k in ipairs(TOOLS) do
  local key = k
  on("TE3_T_" .. key, function() setTool(key) end)
  onHover("TE3_T_" .. key,
    function() setText("TE3_StatL", TOOL_HINT[key] or key) end,
    function() refreshStatus() end)
end
on("TE3_Close", function() setOpen(false) end)

-- ============ sliders (arrasto real; funcao pura p/ teste) ============
local function xToValue(trackX, trackW, x, min, max, isInt)
  local f = (x - trackX) / math.max(trackW, 1)
  f = math.clamp(f, 0, 1)
  local v = min + (max - min) * f
  if isInt then v = math.floor(v + 0.5) end
  return v
end
local Drag = { cfg = nil }
local function sliderGeom(prefix)
  local track = find(prefix .. "_Track")
  local knob = find(prefix .. "_Knob")
  local tx, tw, ky, kw = 0, 100, 0, 14
  pcall(function()
    local p = track.Position
    tx = p.X.Offset or p.X or 0
    local s = track.Size
    tw = s.X.Offset or s.X or 100
    ky = knob.Position.Y.Offset or knob.Position.Y or 0
    local ks = knob.Size
    kw = ks.X.Offset or ks.X or 14
  end)
  -- track/knob sao irmaos: knob anda de tx ate tx+tw-kw
  return track, knob, tx, tw, ky, kw
end
local function paintKnob(cfg)
  local _, knob, tx, tw, ky, kw = sliderGeom(cfg.prefix)
  if not knob then return end
  local f = (cfg.get() - cfg.min) / math.max(cfg.max - cfg.min, 1e-9)
  f = math.clamp(f, 0, 1)
  pcall(function()
    knob.Position = UDim2.fromOffset(math.floor(tx + f * (tw - kw)), ky)
  end)
end
local function makeSlider(cfg)
  local track, knob = sliderGeom(cfg.prefix)
  local function apply(x)
    local _, _, tx, tw = sliderGeom(cfg.prefix)
    local v = xToValue(tx, tw, x, cfg.min, cfg.max, cfg.isInt)
    cfg.set(v)
    setText(cfg.prefix .. "_Val", cfg.fmt(v))
    paintKnob(cfg)
  end
  local function beginAt(x)
    if not S.open then return end
    Drag.cfg = cfg
    apply(x)
  end
  if track then onDown(track, function(_, x) beginAt(x or 0) end) end
  if knob then onDown(knob, function(_, x) beginAt(x or 0) end) end
  -- sem MouseButton1Down (mock): Activated da +1 passo (honesto: mesmo set())
  if track and not hasDown(track) then
    on(cfg.prefix .. "_Track", function()
      local step = ((cfg.max - cfg.min) / 20) or 1
      local v = cfg.get() + step
      if v > cfg.max then v = cfg.min end
      if cfg.isInt then v = math.floor(v + 0.5) end
      cfg.set(v)
      setText(cfg.prefix .. "_Val", cfg.fmt(v))
      paintKnob(cfg)
      if cfg.onRelease then cfg.onRelease() end
    end)
  end
  setText(cfg.prefix .. "_Val", cfg.fmt(cfg.get()))
  paintKnob(cfg)
end
UIS.InputChanged:Connect(function(input)
  if not Drag.cfg then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseMovement or uit == Enum.UserInputType.Touch then
    local p = input.Position
    if p then
      local _, _, tx, tw = sliderGeom(Drag.cfg.prefix)
      local v = xToValue(tx, tw, p.X, Drag.cfg.min, Drag.cfg.max, Drag.cfg.isInt)
      Drag.cfg.set(v)
      setText(Drag.cfg.prefix .. "_Val", Drag.cfg.fmt(v))
      paintKnob(Drag.cfg)
    end
  end
end)
UIS.InputEnded:Connect(function(input)
  if not Drag.cfg then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.Touch then
    local cb = Drag.cfg.onRelease
    Drag.cfg = nil
    if cb then cb() end
  end
end)
local function waterApply()
  api("TerrainWaterProps", {
    transparency = S.wTra, reflectance = S.wRef, waveSize = S.wWav, waveSpeed = S.wSpd,
  })
end
S.wTra, S.wRef, S.wWav, S.wSpd, S.grass = 0.3, 1, 0, 10, 0.5
makeSlider({ prefix = "TE3_Size", min = 1, max = 64, isInt = true,
  get = function() return S.size end, set = function(v) S.size = v refreshStatus() end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_Str", min = 0, max = 100, isInt = true,
  get = function() return S.strength * 100 end, set = function(v) S.strength = v / 100 end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_Fal", min = 0, max = 100, isInt = true,
  get = function() return S.falloff * 100 end, set = function(v) S.falloff = v / 100 end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_Har", min = 0, max = 100, isInt = true,
  get = function() return S.hardness * 100 end, set = function(v) S.hardness = v / 100 end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_Noi", min = 0, max = 100, isInt = true,
  get = function() return S.noise * 100 end, set = function(v) S.noise = v / 100 end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_GHei", min = 8, max = 128, isInt = true,
  get = function() return S.height end, set = function(v) S.height = v end,
  fmt = function(v) return tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_GWat", min = -1, max = 64, isInt = true,
  get = function() return S.waterLevel or -1 end,
  set = function(v) S.waterLevel = (v < 0) and nil or v end,
  fmt = function(v) return (v < 0) and "OFF" or tostring(math.floor(v)) end })
makeSlider({ prefix = "TE3_WTra", min = 0, max = 1,
  get = function() return S.wTra end, set = function(v) S.wTra = v end,
  fmt = function(v) return string.format("%.2f", v) end, onRelease = waterApply })
makeSlider({ prefix = "TE3_WRef", min = 0, max = 1,
  get = function() return S.wRef end, set = function(v) S.wRef = v end,
  fmt = function(v) return string.format("%.2f", v) end, onRelease = waterApply })
makeSlider({ prefix = "TE3_WWav", min = 0, max = 1,
  get = function() return S.wWav end, set = function(v) S.wWav = v end,
  fmt = function(v) return string.format("%.2f", v) end, onRelease = waterApply })
makeSlider({ prefix = "TE3_WSpd", min = 0, max = 100, isInt = true,
  get = function() return S.wSpd end, set = function(v) S.wSpd = v end,
  fmt = function(v) return tostring(math.floor(v)) end, onRelease = waterApply })
makeSlider({ prefix = "TE3_Grass", min = 0.1, max = 1,
  get = function() return S.grass end, set = function(v) S.grass = v end,
  fmt = function(v) return string.format("%.2f", v) end,
  onRelease = function() api("TerrainWaterProps", { grass = S.grass }) end })

-- ============ materiais (cores REAIS lidas do Terrain) ============
local function paintSwatches()
  local ter = nil
  pcall(function() ter = workspace:FindFirstChildOfClass("Terrain") end)
  for _, m in ipairs(MATS21) do
    local o = find("TE3_M_" .. m)
    if o then
      pcall(function()
        if ter then o.BackgroundColor3 = ter:GetMaterialColor(Enum.Material[m]) end
      end)
      pcall(function()
        if m == S.material then
          o.BorderSizePixel = 2
          pcall(function() o.BorderColor3 = Color3.fromRGB(255, 255, 255) end)
        else
          o.BorderSizePixel = 0
        end
      end)
    end
  end
  setText("TE3_MatName", S.material)
end
for _, m in ipairs(MATS21) do
  local mat = m
  on("TE3_M_" .. mat, function()
    S.material = mat
    for i, k in ipairs(MATS21) do if k == mat then S.matIdx = i break end end
    paintSwatches()
    refreshStatus()
  end)
  onHover("TE3_M_" .. mat,
    function() setText("TE3_MatName", mat) end,
    function() setText("TE3_MatName", S.material) end)
end
paintSwatches()

-- ============ simetria / plano / source ============
local function paintSym()
  for _, s in ipairs({ "None", "X", "Z", "XZ" }) do
    local o = find("TE3_Sym_" .. s)
    if o then pcall(function()
      local active = (s == "None" and S.symmetry == "none") or ("XZ"):find(s) and S.symmetry == s:lower()
      o.BackgroundColor3 = (active and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
end
for _, s in ipairs({ "None", "X", "Z", "XZ" }) do
  local sym = s
  on("TE3_Sym_" .. sym, function()
    S.symmetry = (sym == "None") and "none" or sym:lower()
    paintSym()
    say("Mirror: " .. sym .. ".")
  end)
end
paintSym()
on("TE3_PlaneSet", function()
  if lastHit then
    S.planeY = math.floor(lastHit.Y)
    setText("TE3_PlaneVal", "Y: " .. tostring(S.planeY))
    say("Plane Y = " .. tostring(S.planeY) .. ".")
  else
    say("Plane: paint once first (auto-captures hit Y).", true)
  end
end)
on("TE3_Src", function()
  S.srcIdx = (S.srcIdx % #MATS21) + 1
  S.source = MATS21[S.srcIdx]
  setText("TE3_Src", S.source)
end)

-- ============ gizmo do pincel (3 discos 3D, nao GUI) ============
do
  local parts = {}
  local function mkDisc(name, color, transp)
    local ok, p = pcall(Instance.new, "Part")
    if not ok or not p then return nil end
    pcall(function()
      p.Name = name p.Shape = Enum.PartType.Cylinder
      p.Size = Vector3.new(1, 1, 1)
      p.Color = color
      p.Transparency = transp
      p.Anchored = true p.CanCollide = false p.CanQuery = false
      p.Parent = workspace
    end)
    return p
  end
  parts.outer = mkDisc("ArkherBrushOuter", Color3.fromRGB(43, 203, 243), 0.7)
  parts.inner = mkDisc("ArkherBrushInner", Color3.fromRGB(43, 203, 243), 0.4)
  parts.dot = mkDisc("ArkherBrushDot", Color3.fromRGB(255, 255, 255), 0.2)
  if parts.dot then pcall(function() parts.dot.Shape = Enum.PartType.Ball end) end
  local shown = false
  function Gizmo.setVisible(v)
    shown = v
    if not v then
      for _, p in pairs(parts) do pcall(function() p.Transparency = 1 end) end
    end
  end
  function Gizmo.update(hitPos)
    if not (shown and hitPos) then return end
    local d = math.max(S.size * 2, 2)
    local core = math.max(d * S.hardness, 1)
    pcall(function()
      parts.outer.Size = Vector3.new(0.4, d, d)
      parts.outer.CFrame = CFrame.new(hitPos.X, hitPos.Y + 0.4, hitPos.Z)
      parts.outer.Transparency = 0.7
      parts.inner.Size = Vector3.new(0.4, core, core)
      parts.inner.CFrame = CFrame.new(hitPos.X, hitPos.Y + 0.5, hitPos.Z)
      parts.inner.Transparency = 0.4
      parts.dot.Size = Vector3.new(1, 1, 1)
      parts.dot.CFrame = CFrame.new(hitPos.X, hitPos.Y + 0.6, hitPos.Z)
      parts.dot.Transparency = 0.2
    end)
  end
end

-- ============ stroke engine (mouse + toque -> dabs) ============
local Stroke = { active = false, lastPos = nil, lastTime = 0 }
local function overUI(x, y)
  local hit = false
  pcall(function()
    local pg = player:WaitForChild("PlayerGui")
    local list = pg:GetGuiObjectsAtPosition(x, y)
    local o = list and list[1] or nil
    local depth = 0
    while o and depth < 10 do
      if o.Name == "ArkherShell2" then hit = true break end
      o = o.Parent
      depth = depth + 1
    end
  end)
  return hit
end
local function rayTerrain(x, y)
  local c = cam()
  if not c then return nil end
  local ok, ray = pcall(function() return c:ScreenPointToRay(x, y) end)
  if not ok or not ray then return nil end
  local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 2000) end)
  if not ok2 or not hit or not hit.Instance then return nil end
  local isT = false
  pcall(function() isT = hit.Instance:IsA("Terrain") end)
  if not isT then return nil end
  return hit
end
local function paintAt(pos, phase)
  local r, err = api("TerrainStroke", {
    tool = S.tool, center = { x = pos.X, y = pos.Y, z = pos.Z },
    radius = S.size, strength = S.strength, material = S.material,
    falloff = S.falloff, hardness = S.hardness, noise = S.noise, seed = S.seed,
    planeY = S.planeY, source = S.source, symmetry = S.symmetry,
    layer = S.layer, stroke = phase, apply = (phase ~= "end"),
  })
  if err then
    say("Brush: " .. tostring(err), true)
    return false
  end
  if phase ~= "end" and r then
    logOp(("%s r%d %s (%d vox)"):format(S.tool, S.size, S.material, r.touched or 0))
  end
  if phase == "end" then refreshStats() end
  return true
end
local function beginAt(pos)
  lastHit = pos
  S.planeY = math.floor(pos.Y)
  setText("TE3_PlaneVal", "Y: " .. tostring(S.planeY))
  Stroke.active = true
  Stroke.lastPos = pos
  Stroke.lastTime = os.clock()
  paintAt(pos, "begin")
end
local function dabAt(pos)
  lastHit = pos
  Gizmo.update(pos)
  local now = os.clock()
  local moved = 0
  pcall(function() moved = (pos - Stroke.lastPos).Magnitude end)
  if moved > math.max(S.size * 0.3, 2) or (now - Stroke.lastTime) > 0.4 then
    Stroke.lastPos = pos
    Stroke.lastTime = now
    paintAt(pos, "dab")
  end
end
local function beginStroke(x, y)
  if not S.open or typing() then return end
  if overUI(x, y) then return end
  local hit = rayTerrain(x, y)
  if not hit then
    say("Aim at the terrain to paint.", true)
    return
  end
  beginAt(hit.Position)
end
local function moveStroke(x, y)
  if not (S.open and Stroke.active) then return end
  local hit = rayTerrain(x, y)
  if not hit then return end
  dabAt(hit.Position)
end
-- R11: Console (cursor virtual + A) e VR (raio da mao + gatilho) pintam
-- pelo mesmo stroke engine; 11 expoe estado, 12 traduz p/ paintAt.
local function padTick()
  local inp = _G.ArkherInput
  if not inp or not S.open or typing() then
    if Stroke.active and S.open then endStroke(false) end
    return
  end
  local held = false
  pcall(function() held = inp.padPaintHeld and inp.padPaintHeld() end)
  if not held then
    if Stroke.active then endStroke(false) end
    return
  end
  local cur = nil
  pcall(function() cur = inp.consoleCursor and inp.consoleCursor() end)
  if not (cur and cur.X and cur.Y) then return end
  if not Stroke.active then beginStroke(cur.X, cur.Y)
  else moveStroke(cur.X, cur.Y) end
end
local function vrTick()
  local inp = _G.ArkherInput
  if not inp or not S.open or typing() then
    if Stroke.active and S.open then endStroke(false) end
    return
  end
  local held = false
  pcall(function() held = inp.vrPaintHeld and inp.vrPaintHeld() end)
  if not held then
    if Stroke.active then endStroke(false) end
    return
  end
  local ray = nil
  pcall(function() ray = inp.vrHandRay and inp.vrHandRay() end)
  if not (ray and ray.ox) then return end
  local ok, hit = pcall(function()
    return workspace:Raycast(Vector3.new(ray.ox, ray.oy, ray.oz),
      Vector3.new(ray.dx, ray.dy, ray.dz) * 2000)
  end)
  if not ok or not hit or not hit.Instance then return end
  local isT = false
  pcall(function() isT = hit.Instance:IsA("Terrain") end)
  if not isT then return end
  if not Stroke.active then beginAt(hit.Position)
  else dabAt(hit.Position) end
end
endStroke = function(silent)
  if not Stroke.active then return end
  Stroke.active = false
  Stroke.lastPos = nil
  paintAt(lastHit or Vector3.new(0, 0, 0), "end")
end
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or typing() then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseButton1 and platform() == "PC" then
    local p = input.Position
    if p then beginStroke(p.X, p.Y) end
  elseif uit == Enum.UserInputType.Touch then
    local p = input.Position
    if p then beginStroke(p.X, p.Y) end
  end
end)
UIS.InputChanged:Connect(function(input)
  if not (S.open and Stroke.active) then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseMovement or uit == Enum.UserInputType.Touch then
    local p = input.Position
    if p then moveStroke(p.X, p.Y) end
  end
end)
UIS.InputEnded:Connect(function(input)
  if not Stroke.active then return end
  local uit = input.UserInputType
  if uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.Touch then
    endStroke(false)
  end
end)

-- ============ layers UI ============
local LayerCache = {}
function refreshLayers()
  local r = api("TerrainLayer", { op = "list" })
  LayerCache = (r and r.layers) or {}
  for i = 0, 7 do
    local L = LayerCache[i + 1]
    setVisible("TE3_LRow" .. i, L ~= nil)
    if L then
      setText("TE3_LName" .. i, L.name)
      setText("TE3_LOps" .. i, tostring(L.ops or 0))
      setText("TE3_LShow" .. i, L.visible and "Hide" or "Show")
      if S.layer == "" then S.layer = L.name end
    end
  end
  setText("TE3_LHint", tostring(#LayerCache) .. "/8 layers" .. (S.layer ~= "" and (" · active: " .. S.layer) or ""))
  refreshStatus()
end
for i = 0, 7 do
  local idx = i
  on("TE3_LShow" .. idx, function()
    local L = LayerCache[idx + 1]
    if not L then return end
    local r, err = api("TerrainLayer", { op = "toggle", name = L.name })
    if err then say("Layer: " .. tostring(err), true) else say(r.msg) end
    refreshLayers()
    refreshStats()
  end)
  on("TE3_LClear" .. idx, function()
    local L = LayerCache[idx + 1]
    if not L then return end
    local r, err = api("TerrainLayer", { op = "clear", name = L.name })
    if err then say("Layer: " .. tostring(err), true) else say(r.msg) end
    refreshLayers()
    refreshStats()
  end)
  on("TE3_LDel" .. idx, function()
    local L = LayerCache[idx + 1]
    if not L then return end
    local r, err = api("TerrainLayer", { op = "remove", name = L.name })
    if err then say("Layer: " .. tostring(err), true)
    else
      if S.layer == L.name then S.layer = "" end
      say(r.msg)
    end
    refreshLayers()
    refreshStats()
  end)
  on("TE3_LName" .. idx, function()
    local L = LayerCache[idx + 1]
    if L then S.layer = L.name refreshLayers() say("Active layer: " .. L.name .. ".") end
  end)
end
for _, s in ipairs({ "S", "M", "L" }) do
  local sz = s
  on("TE3_LSize" .. sz, function()
    S.lsize = sz
    say("Layer size: " .. sz .. ".")
  end)
end
on("TE3_LAdd", function()
  local nm = ""
  pcall(function() nm = find("TE3_LName").Text or "" end)
  if nm == "" then nm = "Layer" .. (#LayerCache + 1) end
  local sz = S.lsize == "S" and 128 or (S.lsize == "L" and 512 or 256)
  local cx, cz = 0, 0
  if lastHit then cx, cz = math.floor(lastHit.X), math.floor(lastHit.Z) end
  local r, err = api("TerrainLayer", { op = "add", name = nm, cx = cx, cz = cz, sx = sz, sz = sz })
  if err then say("Layer: " .. tostring(err), true)
  else
    S.layer = nm
    say(r.msg .. (" (at %d,%d)."):format(cx, cz))
  end
  refreshLayers()
end)

-- ============ history UI ============
on("TE3_Undo", function()
  local r, err = api("TerrainUndo", {})
  if err then say("Undo: " .. tostring(err), true) else say(r.msg) logOp("UNDO") end
  refreshStats()
end)
on("TE3_Redo", function()
  local r, err = api("TerrainRedo", {})
  if err then say("Redo: " .. tostring(err), true) else say(r.msg) logOp("REDO") end
  refreshStats()
end)

-- ============ generate UI ============
on("TE3_GSeedM", function()
  S.seedG = math.max(S.seedG - 1, 1)
  setText("TE3_GSeedV", tostring(S.seedG))
end)
on("TE3_GSeedP", function()
  S.seedG = math.min(S.seedG + 1, 99999)
  setText("TE3_GSeedV", tostring(S.seedG))
end)
for _, s in ipairs({ "S", "M", "L" }) do
  local sz = s
  on("TE3_GSize" .. sz, function()
    S.gsize = sz == "S" and 128 or (sz == "L" and 512 or 256)
    say("Gen size: " .. tostring(S.gsize) .. ".")
  end)
end
on("TE3_GBio", function()
  S.bioIdx = (S.bioIdx % #BIOMES) + 1
  S.biome = BIOMES[S.bioIdx]
  setText("TE3_GBio", S.biome)
end)
on("TE3_GEroM", function()
  S.erosion = math.max(S.erosion - 1, 0)
  setText("TE3_GEroV", tostring(S.erosion))
end)
on("TE3_GEroP", function()
  S.erosion = math.min(S.erosion + 1, 3)
  setText("TE3_GEroV", tostring(S.erosion))
end)
on("TE3_Gen", function()
  local cx, cz = 0, 0
  if lastHit then cx, cz = math.floor(lastHit.X / 4) * 4, math.floor(lastHit.Z / 4) * 4 end
  local r, err = api("TerrainGen", { seed = S.seedG, size = S.gsize, height = S.height,
    cx = cx, cz = cz, biome = S.biome, erosion = S.erosion, waterLevel = S.waterLevel })
  if err then say("Generate: " .. tostring(err), true) return end
  setText("TE3_GStat", r.msg or "")
  logOp("GEN seed" .. S.seedG)
  say("Preview applied at " .. cx .. "," .. cz .. " - KEEP or UNDO.")
  refreshStats()
end)
on("TE3_Keep", function() say("Preview kept.") end)
on("TE3_Discard", function()
  local r, err = api("TerrainUndo", {})
  if err then say("Discard: " .. tostring(err), true) else say("Preview discarded.") end
  refreshStats()
end)

-- ============ water & growth UI ============
on("TE3_WC1", function()
  local r = api("TerrainWaterProps", { color = { r = 13, g = 84, b = 92 } })
  if r then say("Water: teal.") end
end)
on("TE3_WC2", function()
  local r = api("TerrainWaterProps", { color = { r = 20, g = 60, b = 140 } })
  if r then say("Water: blue.") end
end)
on("TE3_WC3", function()
  local r = api("TerrainWaterProps", { color = { r = 30, g = 120, b = 60 } })
  if r then say("Water: green.") end
end)
local decorOn = true
on("TE3_Decor", function()
  decorOn = not decorOn
  api("TerrainWaterProps", { decoration = decorOn })
  setText("TE3_Decor", decorOn and "GRASS: ON" or "GRASS: OFF")
end)
on("TE3_Rain", function()
  S.rain = not S.rain
  local cx, cz = 0, 0
  if lastHit then cx, cz = lastHit.X, lastHit.Z end
  local r, err = api("TerrainRain", { on = S.rain, cx = cx, cz = cz, radius = 64 })
  if err then say("Rain: " .. tostring(err), true) S.rain = not S.rain return end
  setText("TE3_Rain", S.rain and "RAIN: ON" or "RAIN: OFF")
  say(r.msg)
end)
on("TE3_FloodM", function()
  S.floodY = math.max(S.floodY - 4, -64)
  setText("TE3_FloodV", tostring(S.floodY))
end)
on("TE3_FloodP", function()
  S.floodY = math.min(S.floodY + 4, 512)
  setText("TE3_FloodV", tostring(S.floodY))
end)
on("TE3_Flood", function()
  local cx, cz = 0, 0
  if lastHit then cx, cz = math.floor(lastHit.X), math.floor(lastHit.Z) end
  local r, err = api("TerrainFlood", { y = S.floodY, cx = cx, cz = cz, sx = 128, sz = 128 })
  if err then say("Flood: " .. tostring(err), true) else say(r.msg) logOp("FLOOD y" .. S.floodY) end
  refreshStats()
end)
on("TE3_Hydro", function()
  local cx, cz = 0, 0
  if lastHit then cx, cz = math.floor(lastHit.X), math.floor(lastHit.Z) end
  local r, err = api("TerrainHydro", { cx = cx, cz = cz, sx = 128, sz = 128, sy = 64, y0 = -32 })
  if err then say("Hydro: " .. tostring(err), true)
  else setText("TE3_HydroV", r.msg or "") end
end)

-- ============ mobile strip ============
on("M_TE_Prev", function()
  S.toolIdx = ((S.toolIdx - 2) % #TOOLS) + 1
  setTool(TOOLS[S.toolIdx])
end)
on("M_TE_Next", function()
  S.toolIdx = (S.toolIdx % #TOOLS) + 1
  setTool(TOOLS[S.toolIdx])
end)
on("M_TE_SizeM", function()
  S.size = math.max(S.size - 2, 1)
  setText("M_TE_SizeV", tostring(S.size))
  setText("TE3_Size_Val", tostring(S.size))
  paintKnob({ prefix = "TE3_Size", min = 1, max = 64, get = function() return S.size end })
  refreshStatus()
end)
on("M_TE_SizeP", function()
  S.size = math.min(S.size + 2, 64)
  setText("M_TE_SizeV", tostring(S.size))
  setText("TE3_Size_Val", tostring(S.size))
  paintKnob({ prefix = "TE3_Size", min = 1, max = 64, get = function() return S.size end })
  refreshStatus()
end)
on("M_TE_Mat", function()
  S.matIdx = (S.matIdx % #MATS21) + 1
  S.material = MATS21[S.matIdx]
  setText("M_TE_Mat", S.material)
  paintSwatches()
  refreshStatus()
end)

-- ============ gizmo follow + slow tick ============
local tickAcc, statAcc = 0, 0
RunService.Heartbeat:Connect(function(dt)
  if not S.open then return end
  tickAcc = tickAcc + (dt or 0.016)
  if tickAcc > 0.05 then
    tickAcc = 0
    local pf = platform()
    if pf == "Console" then padTick()
    elseif pf == "VR" then vrTick() end
    local ok, mp = pcall(function() return UIS:GetMouseLocation() end)
    if ok and mp and platform() == "PC" and not Stroke.active then
      local hit = rayTerrain(mp.X, mp.Y - 36)
      if hit then Gizmo.update(hit.Position) end
    elseif Stroke.active and lastHit then
      Gizmo.update(lastHit)
    end
  end
  statAcc = statAcc + (dt or 0.016)
  if statAcc > 2 then
    statAcc = 0
    refreshStats()
  end
end)

-- ============ boot ============
setTool("draw")
refreshStatus()
rawset(_G, "ArkherTerrain", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  setTool = setTool,
  setSize = function(v) S.size = math.clamp(math.floor(v), 1, 64) setText("TE3_Size_Val", tostring(S.size)) refreshStatus() end,
  setStrength = function(v) S.strength = math.clamp(v, 0, 1) end,
  setMaterial = function(m) S.material = tostring(m) paintSwatches() refreshStatus() end,
  setSymmetry = function(s) S.symmetry = tostring(s) paintSym() end,
  xToValue = xToValue,
  paintAt = paintAt,
  refreshLayers = refreshLayers,
  refreshStats = refreshStats,
  state = function() return S end,
})
