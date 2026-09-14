-- Teste GUIX: bake completa (fixture) + adoção 08 + fiação 05/06/07/09 zero-novas.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
  if cond then pass = pass + 1 print("  OK  " .. msg)
  else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local waits, stops = 0, 0
task.wait = function(t)
  waits = waits + 1
  if waits > 500 then error("__REC_STOP__", 0) end
  return nil
end
local _warn = warn
warn = function(m) if tostring(m):find("__REC_STOP__") then stops = stops + 1 else _warn(m) end end

-- ---------- ambiente ----------
local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local scale = Instance.new("UIScale"); scale.Name = "ResponsiveScale"; scale.Parent = canvas
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local NOSEL = { none = true, msg = "Nada selecionado — clique num objeto no EXPLORADOR." }
local messages, apiCalls, menusCalls, setModes = {}, {}, {}, {}
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
clientBus.OnInvoke = function(action, payload)
  if action == "ClaimPart" then return true end
  if action == "Message" then messages[#messages + 1] = tostring(payload.text) return true end
  if action == "SetMode" then setModes[#setModes + 1] = payload.key return true end
  if action == "API" then
    apiCalls[#apiCalls + 1] = payload.action
    if payload.action == "SelectedGet" or payload.action == "PropsAll" then
      return { result = NOSEL }
    end
    return { result = { msg = "ok (" .. tostring(payload.action) .. ")" } }
  end
  return true
end
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
menusBus.OnInvoke = function(action) menusCalls[#menusCalls + 1] = action return true end
local ready = Instance.new("BoolValue"); ready.Name = "CoreReady"; ready.Value = true; ready.Parent = runtime
local mready = Instance.new("BoolValue"); mready.Name = "MenusReady"; mready.Value = true; mready.Parent = runtime
local selIdv = Instance.new("StringValue"); selIdv.Name = "SelectedId"; selIdv.Value = ""; selIdv.Parent = runtime
local directBus = Instance.new("BindableFunction"); directBus.Name = "ClientBus"; directBus.Parent = gui
directBus.OnInvoke = clientBus.OnInvoke
local rs = game:GetService("ReplicatedStorage")
local net = Instance.new("Folder"); net.Name = "ArkherNet"; net.Parent = rs
local netFn = Instance.new("RemoteFunction"); netFn.Name = "ArkherXQ"; netFn.Parent = net
local netCalls = {}
netFn.InvokeServer = function(self, arg)
  netCalls[#netCalls + 1] = arg.op
  if arg.op == "bench_stats" then return { verts = 0, faces = 0, ops = 0, msg = "banca vazia" } end
  if arg.op == "mesh_tools" or arg.op == "world_tools" then return { tools = {}, count = 0 } end
  return { msg = arg.op .. " ok (teste)" }
end
local ls = game:GetService("LogService")
ls.GetLogHistory = function(self) return {} end
ls.ClearOutput = function(self) end

local function loadClient(path, nm)
  local src = io.open(path):read("*a")
  local fn, err = loadstring(src, "[" .. nm .. "]")
  assert(fn, "sintaxe " .. nm .. ": " .. tostring(err))
  script = Instance.new("LocalScript"); script.Name = nm; script.Parent = gui
  local ok, run = pcall(fn)
  check(ok, nm .. " executou" .. (ok and "" or (" err=" .. tostring(run))))
  script.Parent = nil
  return ok
end

local function census()
  local c = {}
  local function walk(o)
    for _, ch in ipairs(o:GetChildren()) do
      local cls = ch.ClassName
      c[cls] = (c[cls] or 0) + 1
      walk(ch)
    end
  end
  walk(canvas)
  return c
end
local function same(a, b)
  for k, v in pairs(a) do if b[k] ~= v then return false, k .. ":" .. v .. "!=" .. tostring(b[k]) end end
  for k, v in pairs(b) do if a[k] ~= v then return false, k .. ":" .. tostring(a[k]) .. "!=" .. v end end
  return true
end
local function total(c) local t = 0 for _, v in pairs(c) do t = t + v end return t end

print("\n== 08 create-path (canvas vazio) ==")
check(loadClient("studio-completo/scripts/08_RealityX.lua", "Arkher_08_RealityX"), "08 #1 ok")
local host = canvas:FindFirstChild("ArkherXDeck")
check(host ~= nil, "host ArkherXDeck criado (fallback)")
local wins = 0
if host then for _, ch in ipairs(host:GetChildren()) do if ch.Name:sub(1, 5) == "Deck_" then wins = wins + 1 end end end
check(wins == 23, "23 janelas Deck_* (" .. wins .. ")")
check(rawget(_G, "ArkherDeck") ~= nil, "_G.ArkherDeck exposto")

print("\n== fixture: shell + 40 v2 + popups + rig/mesh ==")
dofile("studio-completo/tools/baked_fixture.lua")
for _, t in ipairs(FIXTURE_TREES) do
  if t.name == "ArkherShell2" then buildFixtureTree(t, canvas) else buildFixtureTree(t, host) end
end
local nDeck, nV2 = 0, 0
for _, ch in ipairs(host:GetChildren()) do
  if ch.Name:sub(1, 5) == "Deck_" then nDeck = nDeck + 1 end
  if ch.Name:sub(1, 3) == "V2_" then nV2 = nV2 + 1 end
end
check(nDeck == 25, "25 Deck_* (23 + rig + mesh), achado " .. nDeck)
check(nV2 == 40, "40 V2_* assadas, achado " .. nV2)
check(host:FindFirstChild("ArkherXBar") == nil, "XBar antiga REMOVIDA")
check(host:FindFirstChild("Deck_launcher") == nil, "launcher antigo REMOVIDO")
local top = host:FindFirstChild("ArkherTop")
check(top ~= nil, "ArkherTop assado")
local strip = top and top:FindFirstChild("TabStrip")
local ribbon = top and top:FindFirstChild("Ribbon")
local nTabs, nPages, nBtns = 0, 0, 0
if strip then for _, ch in ipairs(strip:GetChildren()) do
  if ch:IsA("GuiButton") and ch.Name:sub(1, 4) == "Tab_" then nTabs = nTabs + 1 end
end end
if ribbon then for _, pg in ipairs(ribbon:GetChildren()) do
  if pg.Name:sub(1, 5) == "Page_" then
    nPages = nPages + 1
    for _, ch in ipairs(pg:GetChildren()) do
      if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then nBtns = nBtns + 1 end
    end
  end
end end
check(nTabs == 9, "9 abas Tab_* (" .. nTabs .. ")")
check(nPages == 9, "9 paginas Page_* (" .. nPages .. ")")
check(nBtns == 42, "42 botoes RibbonBtn_* (" .. nBtns .. ")")
local nM2 = 0
if top then for _, d in ipairs(top:GetDescendants()) do
  if d:IsA("GuiButton") and d.Name:match("^M2_")
     and d.Name ~= "M2_Bell" and d.Name ~= "M2_User" then nM2 = nM2 + 1 end
end end
check(nM2 == 18, "18 menus M2_* na topbar unica (" .. nM2 .. ")")
local S1 = census()
print("   census bake total=" .. total(S1))

print("\n== 08 adopt-path (recarrega sobre a bake pronta) ==")
check(loadClient("studio-completo/scripts/08_RealityX.lua", "Arkher_08_RealityX"), "08 #2 ok")
local S2 = census()
local ok2, diff2 = same(S1, S2)
check(ok2, "2o load NAO duplica nada" .. (ok2 and (" (" .. total(S2) .. " inst)") or (" diff=" .. diff2)))

print("\n== 05 shell2 (fios reais, 1 linha de dados) ==")
check(loadClient("studio-completo/scripts/05_StudioX.lua", "Arkher_05_StudioX"), "05 ok")
local mates = 0
for _, d in ipairs(canvas:GetDescendants()) do if d.Name == "Mate" then mates = mates + 1 end end
check(mates == 1, "05 cria 1 linha Mate (dados do time)")
check(rawget(_G, "ArkherUnread") == 0, "_G.ArkherUnread zerado")
local shell2 = canvas:FindFirstChild("ArkherShell2")
check(shell2 ~= nil, "ArkherShell2 na fixture")
local bGen = shell2 and shell2:FindFirstChild("T2_Generate", true)
if bGen then
  local n0 = #apiCalls
  bGen.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "TerrainFill", "T2_Generate chama bus TerrainFill")
end
local bSP = shell2 and shell2:FindFirstChild("T2_SizePlus", true)
if bSP then
  bSP.MouseButton1Click:Fire()
  check(shell2:FindFirstChild("T2_SizeVal", true).Text == "20", "stepper Size 16->20")
end
local bCrate = shell2 and shell2:FindFirstChild("FR2_A_Crate", true)
if bCrate then
  local n0 = #apiCalls
  bCrate.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "QuickPart", "FR2_A_Crate chama bus QuickPart")
end
local bExp = shell2 and shell2:FindFirstChild("FR2_Export", true)
if bExp then
  local n0 = #apiCalls
  bExp.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "Export", "FR2_Export chama bus Export")
end
local bRec = shell2 and shell2:FindFirstChild("TL2_Rec", true)
if bRec then
  local m0 = #messages
  bRec.MouseButton1Click:Fire()
  check(messages[m0 + 1] and messages[m0 + 1]:find("select an object") ~= nil, "TL2_Rec sem selecao: erro honesto")
end
local bDay = shell2 and shell2:FindFirstChild("SM2_Day", true)
if bDay then
  local n0 = #apiCalls
  bDay.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "SvcSet", "SM2_Day chama bus SvcSet")
end
-- popup de formas: assado mas ORFAO no set antigo (sem gatilho no ribbon)
local shapes = host:FindFirstChild("ServerEditorPopups"):FindFirstChild("ArkherShapesPopup")
check(shapes ~= nil, "popup de formas assado (orfo no set antigo)")
local S3 = census()

print("\n== 06/07 fiacao (zero novas) ==")
check(loadClient("studio-completo/scripts/06_RigX.lua", "Arkher_06_RigX"), "06 ok")
check(loadClient("studio-completo/scripts/07_MeshX.lua", "Arkher_07_MeshX"), "07 ok")
local S4 = census()
local ok4, diff4 = same(S3, S4)
check(ok4, "06/07 criam ZERO instancias" .. (ok4 and "" or (" diff=" .. diff4)))
local rigBody = host:FindFirstChild("Deck_rig"):FindFirstChild("Body")
local demo = rigBody:FindFirstChild("RigBtn_Demo")
if demo then
  demo.MouseButton1Click:Fire()
  check(netCalls[#netCalls] == "rig_demo", "RigBtn_Demo chama rig_demo")
  check(rigBody:FindFirstChild("RigStatus").Text:sub(1, 4) == "✓ ", "status ok (" .. rigBody:FindFirstChild("RigStatus").Text .. ")")
end
local meshBody = host:FindFirstChild("Deck_mesh"):FindFirstChild("Body")
local house = meshBody:FindFirstChild("MeshBtn_House")
if house then
  house.MouseButton1Click:Fire()
  check(netCalls[#netCalls] == "mesh_house", "MeshBtn_House chama mesh_house")
end

print("\n== 09 fiacao (zero novas) ==")
check(loadClient("studio-completo/scripts/09_Topbar.lua", "Arkher_09_Topbar"), "09 ok")
local S5 = census()
local ok5, diff5 = same(S4, S5)
check(ok5, "09 cria ZERO instancias" .. (ok5 and "" or (" diff=" .. diff5)))
local mnu = top:FindFirstChild("M2_Terrain", true)
if mnu then
  local m0 = #menusCalls
  mnu.MouseButton1Click:Fire()
  check(menusCalls[m0 + 1] == "Menu", "M2_Terrain abre dropdown (bus Menu)")
end
local mfile = top:FindFirstChild("M2_File", true)
if mfile then
  local m0 = #menusCalls
  mfile.MouseButton1Click:Fire()
  check(menusCalls[m0 + 1] == "Menu", "M2_File abre dropdown (bus Menu)")
end
local rp = top:FindFirstChild("RibbonBtn_RUN_Play", true)
if rp then
  local m0 = #menusCalls
  rp.MouseButton1Click:Fire()
  check(menusCalls[m0 + 1] == "RunToggle", "RUN_Play chama menus RunToggle")
end
local ru = top:FindFirstChild("RibbonBtn_EDIT_Undo", true)
if ru then
  local n0 = #apiCalls
  ru.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "Undo", "EDIT_Undo chama bus Undo")
end
local rs2 = top:FindFirstChild("RibbonBtn_TRANSFORM_Select", true)
if rs2 then
  rs2.MouseButton1Click:Fire()
  check(setModes[#setModes] == "Select", "TRANSFORM_Select -> SetMode Select")
end
local lg = top:FindFirstChild("RibbonBtn_TRANSFORM_LocalGlobal", true)
if lg then
  local m0 = #messages
  lg.MouseButton1Click:Fire()
  check(messages[m0 + 1] == "Space toggled (Local/Global).", "LocalGlobal alterna espaco")
end
local lk = top:FindFirstChild("RibbonBtn_TRANSFORM_Lock", true)
if lk then
  local m0 = #messages
  lk.MouseButton1Click:Fire()
  check(messages[m0 + 1] == "Lock: select an object first.", "Lock sem selecao: erro honesto")
end
local tabE = top:FindFirstChild("Tab_EDIT", true)
if tabE then
  tabE.MouseButton1Click:Fire()
  local pF = top:FindFirstChild("Page_FILE", true)
  local pE = top:FindFirstChild("Page_EDIT", true)
  check(pF and not pF.Visible and pE and pE.Visible, "Tab_EDIT troca pagina (FILE some, EDIT aparece)")
end

print("\n================================")
print("ADOPT: " .. pass .. " passaram, " .. fail .. " falharam (loops mortos: " .. stops .. ")")
if fail > 0 then os.exit(1) end
