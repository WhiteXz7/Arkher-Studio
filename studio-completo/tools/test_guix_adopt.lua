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
local messages, apiCalls, menusCalls = {}, {}, {}
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
clientBus.OnInvoke = function(action, payload)
  if action == "ClaimPart" then return true end
  if action == "Message" then messages[#messages + 1] = tostring(payload.text) return true end
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
for _, t in ipairs(FIXTURE_TREES) do buildFixtureTree(t, host) end
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
check(nTabs == 11, "11 abas (" .. nTabs .. ")")
check(nPages == 11, "11 paginas (" .. nPages .. ")")
check(nBtns == 89, "89 botoes ribbon (" .. nBtns .. ")")
local S1 = census()
print("   census bake total=" .. total(S1))

print("\n== 08 adopt-path (recarrega sobre a bake pronta) ==")
check(loadClient("studio-completo/scripts/08_RealityX.lua", "Arkher_08_RealityX"), "08 #2 ok")
local S2 = census()
local ok2, diff2 = same(S1, S2)
check(ok2, "2o load NAO duplica nada" .. (ok2 and (" (" .. total(S2) .. " inst)") or (" diff=" .. diff2)))

print("\n== 05 shell (zero novas) ==")
check(loadClient("studio-completo/scripts/05_StudioX.lua", "Arkher_05_StudioX"), "05 ok")
local S3 = census()
local ok3, diff3 = same(S2, S3)
check(ok3, "05 cria ZERO instancias" .. (ok3 and "" or (" diff=" .. diff3)))
check(rawget(_G, "ArkherShell") ~= nil, "_G.ArkherShell exposto")
-- troca de aba
local tabT = strip:FindFirstChild("Tab_TERRAIN")
if tabT then
  tabT.MouseButton1Click:Fire()
  check(ribbon:FindFirstChild("Page_TERRAIN").Visible == true, "aba TERRAIN mostra Page_TERRAIN")
  check(ribbon:FindFirstChild("Page_HOME").Visible == false, "Page_HOME esconde")
  check(tabT:FindFirstChild("ActivePill").Visible == true, "pill ativa na aba")
  check(strip:FindFirstChild("Tab_HOME"):FindFirstChild("ActivePill").Visible == false, "pill HOME apaga")
end
-- botao abre v2 + traz p/ frente + fecha pelo X
local bTerr = ribbon:FindFirstChild("Page_TERRAIN"):FindFirstChild("RibbonBtn_TERRAIN_Terrain")
local wTerr = host:FindFirstChild("V2_ArkherTerrainEditor")
if bTerr and wTerr then
  check(wTerr.Visible == false, "v2 comeca fechada")
  bTerr.MouseButton1Click:Fire()
  check(wTerr.Visible == true, "botao abre V2_ArkherTerrainEditor")
  check(wTerr.ZIndex >= 100, "traz p/ frente (Z=" .. tostring(wTerr.ZIndex) .. ")")
  local cls = wTerr:FindFirstChild("Head") and wTerr:FindFirstChild("Head"):FindFirstChild("Close")
  if cls then cls.MouseButton1Click:Fire() check(wTerr.Visible == false, "X da janela fecha") end
end
-- deck-first
local bTX = ribbon:FindFirstChild("Page_TERRAIN"):FindFirstChild("RibbonBtn_TERRAIN_TerrainX")
local wTX = host:FindFirstChild("Deck_terrain")
if bTX and wTX then
  bTX.MouseButton1Click:Fire()
  check(wTX.Visible == true, "botao abre Deck_terrain (deck-first)")
end
-- acao bus
local bUndo = ribbon:FindFirstChild("Page_HOME"):FindFirstChild("RibbonBtn_HOME_Undo")
if bUndo then
  local n0 = #apiCalls
  bUndo.MouseButton1Click:Fire()
  check(apiCalls[n0 + 1] == "Undo", "HOME_Undo chama bus Undo")
  check(host:FindFirstChild("ArkherMsg"):FindFirstChild("MsgLbl").Text == "ok (Undo)", "toast mostra msg (mock esconde na hora: delay sincrono)")
end
-- acao open (Fase 5: Save/Open/Cloud vao p/ a janela ASSADA)
local bSave = ribbon:FindFirstChild("Page_HOME"):FindFirstChild("RibbonBtn_HOME_Save")
local wSave = host:FindFirstChild("V2_ArkherSaveOpen")
if bSave and wSave then
  bSave.MouseButton1Click:Fire()
  check(wSave.Visible == true, "HOME_Save abre V2_ArkherSaveOpen assada")
end
-- popup
local bPart = ribbon:FindFirstChild("Page_BUILD"):FindFirstChild("RibbonBtn_BUILD_Part")
local shapes = host:FindFirstChild("ServerEditorPopups"):FindFirstChild("ArkherShapesPopup")
if bPart and shapes then
  bPart.MouseButton1Click:Fire()
  check(shapes.Visible == true, "BUILD_Part mostra popup de formas")
end
-- toggle statusbar
local bStatus = ribbon:FindFirstChild("Page_HOME"):FindFirstChild("RibbonBtn_HOME_Status")
local wStatus = host:FindFirstChild("V2_ArkherStatusBar")
if bStatus and wStatus then
  check(wStatus.Visible == false, "statusbar comeca escondida")
  bStatus.MouseButton1Click:Fire()
  check(wStatus.Visible == true, "toggle mostra statusbar")
  -- o dedupe 0.12s do 05 (Activated+Click) exige espera real entre 2 cliques
  local _t0 = os.clock()
  while os.clock() - _t0 < 0.15 do end
  bStatus.MouseButton1Click:Fire()
  check(wStatus.Visible == false, "toggle esconde statusbar")
end

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
local brow = shapes:FindFirstChild("ShapeRow_Block")
if brow then
  shapes.Visible = true
  local n0 = #apiCalls
  brow.Activated:Fire()
  check(apiCalls[n0 + 1] == "QuickPart", "ShapeRow_Block chama QuickPart")
  check(shapes.Visible == false, "popup esconde apos spawn")
end

print("\n================================")
print("ADOPT: " .. pass .. " passaram, " .. fail .. " falharam (loops mortos: " .. stops .. ")")
if fail > 0 then os.exit(1) end
