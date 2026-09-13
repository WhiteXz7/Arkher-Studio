-- Teste de integração ROUND 12: 09_RibbonX + 10_Studio + menus do 03
-- contra o SERVER REAL, no mesmo runtime do mock.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
  if cond then pass = pass + 1 print("  OK  " .. msg)
  else fail = fail + 1 print("  FALHOU  " .. msg) end
end

-- ---------- UI mínima ----------
local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local scale = Instance.new("UIScale"); scale.Name = "ResponsiveScale"; scale.Parent = canvas; scale.Scale = 1
local popups = Instance.new("Frame"); popups.Name = "ServerEditorPopups"; popups.Parent = canvas
for _, nm in ipairs({ "HierarchyDock", "PropertiesDock", "TitleBar", "MenuBar", "Footer", "Viewport", "Ribbon" }) do
  local f = Instance.new("Frame"); f.Name = nm; f.Parent = canvas
end
-- Ribbon com um botão-molde nativo
local ribbon = canvas:FindFirstChild("Ribbon")
local tpl = Instance.new("TextButton"); tpl.Name = "Model"; tpl.Parent = ribbon
tpl.Text = "Model"; tpl.Size = UDim2.fromOffset(64, 56); tpl.Position = UDim2.fromOffset(220, 4)
local tic = Instance.new("Frame"); tic.Name = "Icon"; tic.Parent = tpl
-- host X estático (GUIX real: XBar + popup de formas via guix_static)
local host = Instance.new("Frame"); host.Name = "ArkherXDeck"; host.Parent = canvas
local dscale = Instance.new("UIScale"); dscale.Name = "DeckScale"; dscale.Parent = host
dofile("studio-completo/tools/baked_fixture.lua")
for _, t in ipairs(FIXTURE_TREES) do
  if t.name == "ArkherTop" or t.name == "ArkherMsg" or t.name == "ServerEditorPopups" then
    buildFixtureTree(t, host)
  elseif t.name == "ArkherShell2" then
    buildFixtureTree(t, canvas)
  end
end
-- MenuBar com botão View (molde dos menus X do 03)
local menuBar = canvas:FindFirstChild("MenuBar")
local viewBtn = Instance.new("TextButton"); viewBtn.Name = "View"; viewBtn.Text = "View"; viewBtn.Parent = menuBar
-- runtime
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local coreReady = Instance.new("BoolValue"); coreReady.Name = "CoreReady"; coreReady.Value = true; coreReady.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
local menusReady = Instance.new("BoolValue"); menusReady.Name = "MenusReady"; menusReady.Parent = runtime
local selId = Instance.new("StringValue"); selId.Name = "SelectedId"; selId.Value = ""; selId.Parent = runtime
local selObj = Instance.new("ObjectValue"); selObj.Name = "SelectedInstance"; selObj.Parent = runtime

-- ---------- server real ----------
local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local bridge = RS:FindFirstChild("ArkherStudioBridge")
assert(bridge, "bridge nao criada")
local request = bridge:FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function invoke(action, payload) return rawget(request, "__props").OnServerInvoke(tp, action, payload or {}) end
local function snap() return invoke("Snapshot", {}) end
local function findId(s, name) for _, n in ipairs(s.nodes) do if n.name == name then return n.id end end end

local cstate = { selectedId = nil, node = nil }
local messages = {}
clientBus.OnInvoke = function(action, payload)
  payload = payload or {}
  if action == "ClaimPart" then return true end
  if action == "API" then
    local r = invoke(payload.action, payload.payload)
    if r and r.error then return { error = r.error } end
    return { result = r }
  end
  if action == "State" then return cstate end
  if action == "Message" then messages[#messages + 1] = tostring(payload.text); return true end
  if action == "Icon" then return Instance.new("Frame") end
  return true
end

local function loadClient(path, nm)
  local src = io.open(path):read("*a")
  local fn, err = loadstring(src, "[" .. nm .. "]")
  assert(fn, "sintaxe " .. nm .. ": " .. tostring(err))
  script = Instance.new("LocalScript"); script.Name = nm; script.Parent = gui
  local ok, run = pcall(fn)
  check(ok, nm .. " executou" .. (ok and "" or (" err=" .. tostring(run))))
  return ok
end

print("\n== Clientes ==")
check(loadClient("studio-completo/scripts/03_Menus.lua", "Arkher_03_Menus"), "03 ok")
check(loadClient("studio-completo/scripts/05_StudioX.lua", "Arkher_05_StudioX"), "05 ok")
check(loadClient("studio-completo/scripts/09_Topbar.lua", "Arkher_09_Topbar"), "09 ok")
check(loadClient("studio-completo/scripts/10_Studio.lua", "Arkher_10_Studio"), "10 ok")

print("\n== Menus X no MenuBar (clonados do View) ==")
local modelagemBtn
for _, d in ipairs(menuBar:GetDescendants()) do
  if d:IsA("GuiButton") and d.Name == "MODELAGEM" then modelagemBtn = d end
end
check(modelagemBtn ~= nil, "botão MODELAGEM existe no MenuBar")
if modelagemBtn then
  modelagemBtn.Activated:Fire()
  local mf = popups:FindFirstChild("MODELAGEMMenu")
  check(mf ~= nil, "clicar MODELAGEM abre o dropdown MODELAGEMMenu")
  if mf then
    local rows = 0
    for _, d in ipairs(mf:GetDescendants()) do if d:IsA("GuiButton") then rows = rows + 1 end end
    check(rows >= 2, "dropdown tem itens (" .. rows .. ")")
  end
end

print("\n== Menu LUGARES (salvar/criar places) ==")
local lugBtn
for _, d in ipairs(menuBar:GetDescendants()) do
  if d:IsA("GuiButton") and d.Name == "LUGARES" then lugBtn = d end
end
check(lugBtn ~= nil, "botão LUGARES existe no MenuBar")
if lugBtn then
  lugBtn.Activated:Fire()
  local lm = popups:FindFirstChild("LUGARESMenu")
  check(lm ~= nil, "clicar LUGARES abre o dropdown")
  if lm then
    local saveItem, novaItem, rows2 = nil, nil, 0
    for _, d in ipairs(lm:GetDescendants()) do
      if d:IsA("GuiButton") then
        rows2 = rows2 + 1
        if tostring(d.Name) == "Item_SavePlaceAccount" then saveItem = d end
        if tostring(d.Name) == "Item_PlacesProfile" then novaItem = d end
      end
    end
    check(rows2 >= 4, "LUGARES tem opções salvar/criar/perfil (" .. rows2 .. ")")
    check(saveItem ~= nil and novaItem ~= nil, "itens SALVAR ESTA PLACE + CRIAR PLACE NOVA presentes")
    if saveItem then
      local m0 = #messages
      saveItem.Activated:Fire()
      local got
      for idx = m0 + 1, #messages do got = messages[idx] end
      check(got ~= nil, "clicar SALVAR PLACE devolve feedback (msg/erro honesto)")
      if got then print("   feedback: " .. got) end
    end
  end
end

print("\n== Shell2 real (menus + ribbon + paineis) ==")
local shell12 = canvas:FindFirstChild("ArkherShell2")
check(shell12 ~= nil, "ArkherShell2 no canvas")
local nM2, nR2 = 0, 0
if shell12 then for _, d in ipairs(shell12:GetDescendants()) do
  if d:IsA("GuiButton") then
    if d.Name:match("^M2_") and d.Name ~= "M2_Bell" and d.Name ~= "M2_User" then nM2 = nM2 + 1 end
    if d.Name:match("^R2_") then nR2 = nR2 + 1 end
  end
end end
check(nM2 == 12, "12 menus M2_* (" .. nM2 .. ")")
check(nR2 == 21, "21 botoes R2_* (18+R8 Anchor/Snap/Group: " .. nR2 .. ")")
local panels = { "T2_Panel", "C2_Panel", "S2_Panel", "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local np = 0
if shell12 then for _, pn in ipairs(panels) do if shell12:FindFirstChild(pn, true) then np = np + 1 end end end
check(np == 8, "8 paineis shell2 (" .. np .. ")")

print("\n== Assets criam (via FR2, server real) ==")
local function countClass(s, cls) local n = 0 for _, x in ipairs(s.nodes) do if x.class == cls then n = n + 1 end end return n end
local bCrate = shell12 and shell12:FindFirstChild("FR2_A_Crate", true)
if bCrate then
  local n0 = countClass(snap(), "Part")
  bCrate.Activated:Fire()
  check(countClass(snap(), "Part") >= n0 + 1, "FR2_A_Crate cria Part no mundo")
  check(findId(snap(), "Crate") ~= nil, "Crate registrada")
end
local bTree = shell12 and shell12:FindFirstChild("FR2_A_Tree", true)
if bTree then
  local n0 = countClass(snap(), "Part")
  bTree.Activated:Fire()
  check(countClass(snap(), "Part") == n0 + 2, "FR2_A_Tree cria 2 Parts (trunk+leaves)")
end

print("\n== Terrain/Sim via shell2 (server real) ==")
local ter12 = Instance.new("Terrain"); ter12.Name = "Terrain"; ter12.Parent = workspace
local terCalls12 = {}
METHODS.FillBall = function(self, c, r, m) terCalls12[#terCalls12+1] = { shape = "ball", r = r, mat = m and m.Name } end
local bGen = shell12 and shell12:FindFirstChild("T2_Generate", true)
if bGen then
  bGen.Activated:Fire()
  check(#terCalls12 == 1 and terCalls12[1].mat == "Grass", "T2_Generate -> FillBall Grass (r=" .. tostring(terCalls12[1] and terCalls12[1].r) .. ")")
end
local bDay = shell12 and shell12:FindFirstChild("SM2_Day", true)
if bDay then
  bDay.Activated:Fire()
  check(game:GetService("Lighting").ClockTime == 14, "SM2_Day -> ClockTime 14 DAY (SvcSet real)")
  bDay.Activated:Fire()
  check(game:GetService("Lighting").ClockTime == 0, "SM2_Day toggle -> ClockTime 0 NIGHT")
end

print("\n== Resources via FR2 (server real) ==")
local bSync = shell12 and shell12:FindFirstChild("FR2_Sync", true)
if bSync then
  bSync.Activated:Fire()
  local lab = shell12:FindFirstChild("FR2_StorageLabel", true)
  check(lab and lab.Text:find("project") ~= nil, "FR2_Sync atualiza Cloud label (" .. tostring(lab and lab.Text) .. ")")
end
local bExp2 = shell12 and shell12:FindFirstChild("FR2_Export", true)
if bExp2 then
  local m0 = #messages
  bExp2.Activated:Fire()
  local got
  for idx = m0 + 1, #messages do got = messages[idx] end
  check(got and got:find("Exported") ~= nil, "FR2_Export exporta mundo (msg: " .. tostring(got):sub(1, 50) .. ")")
end

print("\n== Properties na dock original ==")
local ov = canvas:FindFirstChild("ArkherPropsOverlay", true)
check(ov ~= nil, "overlay ArkherPropsOverlay tomou a PropertiesDock")
-- cria uma peça real via server
local s0 = snap()
local wsId
for _, n in ipairs(s0.nodes) do if n.class == "Workspace" then wsId = n.id end end
local cr = invoke("Create", { parentId = wsId, class = "Part", name = "PecaProps" })
local partId = cr and cr.node and cr.node.id or findId(snap(), "PecaProps")
check(partId ~= nil, "peça PecaProps criada via Create")
selId.Value = tostring(partId)
task.wait(0.01)
-- força refresh direto via SelectedId change
pcall(function() rawget(selId, "__events").Value:Fire() end)
local listov = ov and ov:FindFirstChildWhichIsA("ScrollingFrame", true)
local rowCount = 0
if listov then
  for _, d in ipairs(listov:GetDescendants()) do
    if d:IsA("TextLabel") and (d.Text == "Anchored" or d.Text == "Transparency" or d.Text == "Color") then rowCount = rowCount + 1 end
  end
end
check(rowCount >= 2, "PropsAll renderizou campos (Anchored/Transparency/Color achados: " .. rowCount .. ")")
-- SetAny escreve de verdade
local wr = invoke("SetAny", { id = partId, name = "Anchored", kind = "b", value = true })
check(wr and wr.ok == true, "SetAny Anchored=true aplicou")
local pr2 = invoke("PropsAll", { id = partId })
check(pr2 and pr2.fields and #pr2.fields > 15, "PropsAll devolveu " .. tostring(pr2 and pr2.fields and #pr2.fields) .. " propriedades")

print("\n== Timeline grava (server real) ==")
cstate.selectedId = partId
local bRec = shell12 and shell12:FindFirstChild("TL2_Rec", true)
if bRec then
  bRec.Activated:Fire()
  local lane1 = shell12:FindFirstChild("TL2_Lane1", true)
  local keys = 0
  if lane1 then for _, k in ipairs(lane1:GetChildren()) do if k.Name == "Key" then keys = keys + 1 end end end
  check(keys == 1, "TL2_Rec gravou pose + marcador (server AnimKey)")
end

print("\n== Painel INSERIR OBJETO (catálogo gigante) ==")
local g = rawget(_G, "ArkherStudioDock")
check(g ~= nil, "_G.ArkherStudioDock exposto")
if g then
  g.toggle("insert")
  local ip = popups:FindFirstChild("ArkherInsertPanel")
  check(ip ~= nil, "painel INSERIR OBJETO abriu")
  local cls = invoke("ClassList", {})
  check(cls and cls.items and #cls.items >= 100, "ClassList devolveu " .. tostring(cls and #cls.items) .. " classes")
  local ca = invoke("CreateAny", { class = "WeldConstraint" })
  check(ca and ca.id ~= nil, "CreateAny criou WeldConstraint no workspace" .. (ca and ca.error and (" err=" .. ca.error) or ""))
  local bad = invoke("CreateAny", { class = "ClasseFalsa123" })
  check(bad and bad.error ~= nil, "CreateAny com classe falsa devolve erro honesto")
end

print("\n== TOOLBOX dock estilo Studio ==")
if g then
  g.toggle("toolbox")
  local tb2 = popups:FindFirstChild("ArkherToolboxDock")
  check(tb2 ~= nil, "TOOLBOX dock abriu")
  if tb2 then
    local hasGrid = tb2:FindFirstChildWhichIsA("UIGridLayout", true) ~= nil
    check(hasGrid, "toolbox tem grade de cards")
  end
end

print("\n================================")
print("RIBBOX: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
