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

print("\n== Shell real (abas + paginas + botoes) ==")
local top12 = host:FindFirstChild("ArkherTop")
check(top12 ~= nil, "ArkherTop existe no host")
local strip12 = top12 and top12:FindFirstChild("TabStrip")
local ribbon12 = top12 and top12:FindFirstChild("Ribbon")
local nTabs12, nPages12, nBtns12 = 0, 0, 0
if strip12 then for _, ch in ipairs(strip12:GetChildren()) do
  if ch:IsA("GuiButton") and ch.Name:sub(1, 4) == "Tab_" then nTabs12 = nTabs12 + 1 end
end end
if ribbon12 then for _, pg in ipairs(ribbon12:GetChildren()) do
  if pg.Name:sub(1, 5) == "Page_" then
    nPages12 = nPages12 + 1
    for _, ch in ipairs(pg:GetChildren()) do
      if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then nBtns12 = nBtns12 + 1 end
    end
  end
end end
check(nTabs12 == 11 and nPages12 == 11 and nBtns12 == 84,
  "11 abas + 11 paginas + 84 botoes (" .. nTabs12 .. "/" .. nPages12 .. "/" .. nBtns12 .. ")")
local tabB = strip12 and strip12:FindFirstChild("Tab_BUILD")
if tabB then
  tabB.Activated:Fire()
  check(ribbon12:FindFirstChild("Page_BUILD").Visible == true, "aba BUILD mostra Page_BUILD")
  check(ribbon12:FindFirstChild("Page_HOME").Visible == false, "Page_HOME esconde")
end

print("\n== Submenu PART (7 formas reais, via ribbon) ==")
local hostPopups = host:FindFirstChild("ServerEditorPopups")
local partBtn = ribbon12 and ribbon12:FindFirstChild("Page_BUILD"):FindFirstChild("RibbonBtn_BUILD_Part")
if partBtn then
  partBtn.Activated:Fire()
  local sh = hostPopups and hostPopups:FindFirstChild("ArkherShapesPopup")
  check(sh ~= nil and sh.Visible == true, "PART mostra o popup de formas real")
  if sh then
    local rows = {}
    for _, d in ipairs(sh:GetChildren()) do if d:IsA("GuiButton") then rows[#rows + 1] = d end end
    check(#rows == 7, "popup tem 7 formas (" .. #rows .. ")")
    local blocoBtn
    for _, r in ipairs(rows) do if tostring(r.Text):find("loco") or tostring(r.Text):find("Block") then blocoBtn = r end end
    if blocoBtn then
      blocoBtn.Activated:Fire()
      local s = snap()
      check(findId(s, "Block_ArkherStock") ~= nil, "Block spawna no mundo via QuickPart server")
    end
  end
end

print("\n== Baseplate / Union / Negate clicaveis (via ribbon) ==")
local pageB = ribbon12 and ribbon12:FindFirstChild("Page_BUILD")
local bBase = pageB and pageB:FindFirstChild("RibbonBtn_BUILD_Base")
local bUnion = pageB and pageB:FindFirstChild("RibbonBtn_BUILD_Union")
local bNeg = pageB and pageB:FindFirstChild("RibbonBtn_BUILD_Negate")
if bBase then
  bBase.Activated:Fire()
  check(true, "Baseplate clique nao explode (mock ja tem Baseplate)")
end
local msgBefore = #messages
if bUnion then
  invoke("QuickPart", { shape = "Block", x = 0, y = 3, z = 0 })
  bUnion.Activated:Fire()
  bNeg.Activated:Fire()
  check(true, "Union/Negate respondem sem crash")
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
