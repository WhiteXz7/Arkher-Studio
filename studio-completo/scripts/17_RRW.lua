-- =============================================================
-- ARKHER RRW (17_RRW) — pipeline de render hibrido real
-- UI 100% assada (RW7_*); este script LIGA os controles e traduz
-- gesto -> RrwProfile/Fx/Sky/Atmo/Clouds/Lod/Vfx/Stats (R14b).
-- Render = Lighting real + pos-efeitos reais + ceu/clima reais +
-- LOD por troca de tiers + VFX reais. Sem painel falso.
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "17: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "17: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "17: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)

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
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  return (type(r) == "table" and r.result) or r, nil
end
local say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
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
local function rayView(x, y)
  local c = workspace.CurrentCamera
  if not c then return nil end
  local ok, ray = pcall(function() return c:ScreenPointToRay(x, y) end)
  if not ok or not ray then return nil end
  local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 5000) end)
  if not ok2 or not hit or not hit.Instance then return nil end
  return hit
end

-- ============ estado ============
local S = { open = false, place = false, preset = "Tocha",
  selFx = "BloomEffect", inten = 1, profile = "-",
  clock = 12, cycling = false, speed = 0.1,
  atmo = 0.3, cloud = 0.5, tiers = {}, fxOn = {} }
local RW7_ALL = { "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status", "VP3_Rail", "VP3_Cam", "VP3_Trans",
  "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert",
  "MD4_Top", "MD4_IO", "MD4_Status", "AN5_Rail", "AN5_Rig", "AN5_Pose",
  "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status",
  "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local FX_BTN = { Bloom = "BloomEffect", Blur = "BlurEffect", Color = "ColorCorrectionEffect",
  DOF = "DepthOfFieldEffect", Rays = "SunRaysEffect", Grade = "ColorGradingEffect" }
local FX_MAIN = { BloomEffect = "Intensity", BlurEffect = "Size",
  ColorCorrectionEffect = "Brightness", DepthOfFieldEffect = "FarIntensity",
  SunRaysEffect = "Intensity", ColorGradingEffect = nil }
local PROFILES = { "Realista", "Showcase", "Horror", "Mobile", "Estudio" }

local function clockFmt(h)
  h = h or 0
  local hh = math.floor(h)
  local mm = math.floor((h - hh) * 60 + 0.5)
  if mm >= 60 then hh, mm = hh + 1, 0 end
  return string.format("%02d:%02d", hh % 24, mm)
end
local function refreshFxInfo()
  local names = {}
  for cls in pairs(S.fxOn) do names[#names + 1] = cls:gsub("Effect", "") end
  table.sort(names)
  setText("RW7_F_Info", (#names > 0) and ("on: " .. table.concat(names, ",")) or "fx: none")
end
local function refreshStats()
  local r, err = api("RrwStats", {})
  if err then return end
  setText("RW7_StatL", string.format("%s · %.0f fps · %d parts · %d fx · lod %d · %s",
    S.profile, r.fps or 0, r.parts or 0, r.effects or 0, r.lodGroups or 0, clockFmt(r.clockTime)))
end
local function refreshFx()
  local r, err = api("RrwFx", { op = "list" })
  if err then return end
  S.fxOn = {}
  for _, it in ipairs(r.items or {}) do
    if it.enabled then S.fxOn[it.class] = true end
  end
  refreshFxInfo()
end
local function refreshSky()
  local r, err = api("RrwSky", {})
  if err then return end
  S.cycling = (r.mode == "cycle")
  S.speed = r.speed or S.speed
  S.clock = r.clockTime or S.clock
  setText("RW7_S_TV", clockFmt(S.clock))
  setText("RW7_S_Cycle", S.cycling and "CYCLE ON" or "CYCLE OFF")
  setText("RW7_S_SV", string.format("%g", S.speed))
end
local function setOpen(v)
  S.open = v
  for _, n in ipairs(RW7_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  for _, n in ipairs(OTHER_EDS) do setVisible(n, false) end
  setVisible("M_VP", false)
  setVisible("M_MD", false)
  setVisible("M_AN", false)
  setVisible("M_UI", false)
  setVisible("M_DO", false)
  setVisible("M_WO", false)
  if v then
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherDo15", "ArkherWorld" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    refreshFx()
    refreshSky()
    refreshStats()
    if platform() == "Mobile" then setVisible("M_RW", true) end
    say("RRW open (" .. platform() .. ").")
  else
    S.place = false
    setVisible("M_RW", false)
    say("RRW closed.")
  end
end
local statT = 0
RunService.Heartbeat:Connect(function(dt)
  if not S.open then return end
  statT = statT + (dt or 0)
  if statT >= 1 then
    statT = 0
    refreshStats()
  end
end)

-- ============ rail ============
local BTN_BG, ACC_BG = nil, nil
pcall(function()
  local b = find("RW7_T_Place")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("RW7_P_Realista")
  if g then ACC_BG = g.BackgroundColor3 end
end)
on("RW7_T_Place", function()
  S.place = not S.place
  local o = find("RW7_T_Place")
  if o then pcall(function()
    o.BackgroundColor3 = (S.place and ACC_BG or BTN_BG) or o.BackgroundColor3
  end) end
  say(S.place and ("Place ON: click a part (" .. S.preset .. ").") or "Place OFF.")
end)
on("RW7_Close", function() setOpen(false) end)

-- ============ profiles ============
for _, p in ipairs(PROFILES) do
  local pp = p
  on("RW7_P_" .. pp, function()
    local r, err = api("RrwProfile", { preset = pp })
    if err then say("Profile: " .. tostring(err), true) return end
    S.profile = pp
    local via = {}
    if r.via then
      if r.via.style then via[#via + 1] = "style" end
      if r.via.tech then via[#via + 1] = "tech" end
    end
    setText("RW7_P_Info", string.format("%s · %s\nvia %s", pp, r.style or "-", table.concat(via, "+")))
    refreshStats()
    refreshSky()
    say(r.msg or "Profile applied.")
  end)
end

-- ============ fx ============
for btn, cls in pairs(FX_BTN) do
  local b2, c2 = btn, cls
  on("RW7_F_" .. b2, function()
    S.selFx = c2
    if S.fxOn[c2] then
      local r, err = api("RrwFx", { op = "remove", class = c2 })
      if err then say("FX: " .. tostring(err), true) return end
      S.fxOn[c2] = nil
      say(c2 .. " off.")
    else
      local props = {}
      local main = FX_MAIN[c2]
      if main then props[main] = S.inten end
      local r, err = api("RrwFx", { op = "add", class = c2, props = props })
      if err then say("FX: " .. tostring(err), true) return end
      S.fxOn[c2] = true
      say(c2 .. " on.")
    end
    refreshFxInfo()
  end)
end
on("RW7_I_M", function()
  S.inten = math.max(S.inten - 0.5, 0)
  setText("RW7_IV", string.format("%g", S.inten))
  local main = FX_MAIN[S.selFx]
  if not main then say("Grade: on/off only.", true) return end
  local r, err = api("RrwFx", { op = "set", class = S.selFx, props = { [main] = S.inten } })
  if err then say("FX: " .. tostring(err), true) return end
  S.fxOn[S.selFx] = true
  refreshFxInfo()
end)
on("RW7_I_P", function()
  S.inten = math.min(S.inten + 0.5, 10)
  setText("RW7_IV", string.format("%g", S.inten))
  local main = FX_MAIN[S.selFx]
  if not main then say("Grade: on/off only.", true) return end
  local r, err = api("RrwFx", { op = "set", class = S.selFx, props = { [main] = S.inten } })
  if err then say("FX: " .. tostring(err), true) return end
  S.fxOn[S.selFx] = true
  refreshFxInfo()
end)

-- ============ sky ============
on("RW7_S_TM", function()
  local r, err = api("RrwSky", { mode = "static", clockTime = (S.clock - 1) % 24 })
  if err then say("Sky: " .. tostring(err), true) return end
  S.clock = r.clockTime
  S.cycling = false
  setText("RW7_S_TV", clockFmt(S.clock))
  setText("RW7_S_Cycle", "CYCLE OFF")
end)
on("RW7_S_TP", function()
  local r, err = api("RrwSky", { mode = "static", clockTime = (S.clock + 1) % 24 })
  if err then say("Sky: " .. tostring(err), true) return end
  S.clock = r.clockTime
  S.cycling = false
  setText("RW7_S_TV", clockFmt(S.clock))
  setText("RW7_S_Cycle", "CYCLE OFF")
end)
on("RW7_S_Cycle", function()
  local r, err = api("RrwSky", { mode = S.cycling and "off" or "cycle" })
  if err then say("Sky: " .. tostring(err), true) return end
  S.cycling = (r.mode == "cycle")
  setText("RW7_S_Cycle", S.cycling and "CYCLE ON" or "CYCLE OFF")
  say(S.cycling and "Day cycle on." or "Day cycle off.")
end)
on("RW7_S_SM", function()
  local ns = math.max(S.speed - 0.05, 0.01)
  local r, err = api("RrwSky", { mode = S.cycling and "cycle" or "static", speed = ns })
  if err then say("Sky: " .. tostring(err), true) return end
  S.speed = r.speed
  setText("RW7_S_SV", string.format("%g", S.speed))
end)
on("RW7_S_SP", function()
  local ns = math.min(S.speed + 0.05, 6)
  local r, err = api("RrwSky", { mode = S.cycling and "cycle" or "static", speed = ns })
  if err then say("Sky: " .. tostring(err), true) return end
  S.speed = r.speed
  setText("RW7_S_SV", string.format("%g", S.speed))
end)

-- ============ atmo + clouds + vfx ============
on("RW7_A_M", function()
  local nv = math.max(S.atmo - 0.1, 0)
  local r, err = api("RrwAtmo", { density = nv })
  if err then say("Atmo: " .. tostring(err), true) return end
  S.atmo = r.density
  setText("RW7_AV", string.format("%g", S.atmo))
end)
on("RW7_A_P", function()
  local nv = math.min(S.atmo + 0.1, 1)
  local r, err = api("RrwAtmo", { density = nv })
  if err then say("Atmo: " .. tostring(err), true) return end
  S.atmo = r.density
  setText("RW7_AV", string.format("%g", S.atmo))
end)
on("RW7_C_M", function()
  local nv = math.max(S.cloud - 0.1, 0)
  local r, err = api("RrwClouds", { cover = nv })
  if err then say("Clouds: " .. tostring(err), true) return end
  S.cloud = r.cover
  setText("RW7_CV", string.format("%g", S.cloud))
end)
on("RW7_C_P", function()
  local nv = math.min(S.cloud + 0.1, 1)
  local r, err = api("RrwClouds", { cover = nv })
  if err then say("Clouds: " .. tostring(err), true) return end
  S.cloud = r.cover
  setText("RW7_CV", string.format("%g", S.cloud))
end)
for _, v in ipairs({ "Torch", "Smoke", "Magic", "Glow" }) do
  local vv = v
  on("RW7_V_" .. vv, function()
    S.preset = (vv == "Torch" and "Tocha") or (vv == "Smoke" and "Fumaca")
      or (vv == "Magic" and "Magia") or "Brilho"
    if not S.place then
      S.place = true
      local o = find("RW7_T_Place")
      if o then pcall(function() o.BackgroundColor3 = ACC_BG or o.BackgroundColor3 end) end
    end
    say("Preset " .. S.preset .. ": click a part to place.")
  end)
end

-- ============ LOD ============
on("RW7_L_Add", function()
  local inst = nil
  pcall(function()
    local sv = rt:FindFirstChild("SelectedInstance")
    if sv then inst = sv.Value end
  end)
  if not inst then say("LOD: select a Model first.", true) return end
  local isM = false
  pcall(function() isM = inst:IsA("Model") end)
  if not isM then say("LOD: select a Model.", true) return end
  local r, err = api("Identify", { object = inst })
  if err or not (r and r.id) then say("LOD: " .. tostring(err or "identify failed"), true) return end
  if #S.tiers >= 5 then say("LOD: max 5 tiers.", true) return end
  S.tiers[#S.tiers + 1] = { id = r.id, dist = 150 * (#S.tiers + 1) }
  local ds = {}
  for _, t in ipairs(S.tiers) do ds[#ds + 1] = tostring(t.dist) end
  setText("RW7_L_Info", string.format("tiers %d (%s)", #S.tiers, table.concat(ds, "/")))
  say("Tier " .. #S.tiers .. " staged (" .. inst.Name .. ").")
end)
on("RW7_L_Reg", function()
  local nm = ""
  pcall(function() nm = find("RW7_L_Name").Text or "" end)
  if nm == "" then say("LOD: name the group.", true) return end
  if #S.tiers < 2 then say("LOD: stage 2+ tiers.", true) return end
  local r, err = api("RrwLod", { op = "register", name = nm, tiers = S.tiers })
  if err then say("LOD: " .. tostring(err), true) return end
  S.tiers = {}
  setText("RW7_L_Info", "tiers: registered " .. nm)
  say("LOD " .. nm .. " live.")
end)
on("RW7_L_Del", function()
  local nm = ""
  pcall(function() nm = find("RW7_L_Name").Text or "" end)
  if nm == "" then say("LOD: name the group.", true) return end
  local r, err = api("RrwLod", { op = "remove", name = nm })
  if err then say("LOD: " .. tostring(err), true) return end
  say("LOD " .. nm .. " removed (tiers restored).")
end)

-- ============ clique: place VFX ============
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or typing() then return end
  if not S.place then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseButton1 and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p or overUI(p.X, p.Y) then return end
  local hit = rayView(p.X, p.Y)
  if not hit then return end
  local isP = false
  pcall(function() isP = hit.Instance:IsA("BasePart") end)
  if not isP then say("Place: click a part.", true) return end
  local r, err = api("Identify", { object = hit.Instance })
  if err or not (r and r.id) then say("Place: " .. tostring(err or "identify failed"), true) return end
  local r2, err2 = api("RrwVfx", { preset = S.preset, parentId = r.id })
  if err2 then say("Place: " .. tostring(err2), true) return end
  say(r2.msg or "VFX placed.")
end)

-- ============ mobile strip ============
on("M_RW_Prof", function()
  local i = 1
  for n, p in ipairs(PROFILES) do if p == S.profile then i = n break end end
  local np = PROFILES[(i % #PROFILES) + 1]
  local r, err = api("RrwProfile", { preset = np })
  if err then say("Profile: " .. tostring(err), true) return end
  S.profile = np
  setText("RW7_P_Info", np)
  say(r.msg or "Profile applied.")
end)
on("M_RW_FX", function()
  if S.fxOn.BloomEffect then
    local r, err = api("RrwFx", { op = "remove", class = "BloomEffect" })
    if err then say("FX: " .. tostring(err), true) return end
    S.fxOn.BloomEffect = nil
    say("Bloom off.")
  else
    local r, err = api("RrwFx", { op = "add", class = "BloomEffect", props = { Intensity = 1 } })
    if err then say("FX: " .. tostring(err), true) return end
    S.fxOn.BloomEffect = true
    say("Bloom on.")
  end
  refreshFxInfo()
end)
on("M_RW_Sky", function()
  local r, err = api("RrwSky", { mode = S.cycling and "off" or "cycle" })
  if err then say("Sky: " .. tostring(err), true) return end
  S.cycling = (r.mode == "cycle")
  setText("RW7_S_Cycle", S.cycling and "CYCLE ON" or "CYCLE OFF")
  say(S.cycling and "Day cycle on." or "Day cycle off.")
end)

-- ============ boot ============
refreshFxInfo()
rawset(_G, "ArkherRRW", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
