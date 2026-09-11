-- Teste de integracao do cliente (03_Menus) + server, no mesmo runtime.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
  if cond then pass = pass + 1 print("  OK  " .. msg)
  else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local starterGui = game:GetService("StarterGui")
-- ScreenGui + Canvas (estrutura minima que o 03_Menus espera)
local gui = Instance.new("ScreenGui")
gui.Name = "ArkherStudioUI"
gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local scale = Instance.new("Frame"); scale.Name = "ResponsiveScale"; scale.Parent = canvas
scale.Scale = 1
local popups = Instance.new("Frame"); popups.Name = "ServerEditorPopups"; popups.Parent = canvas
for _, nm in ipairs({ "HierarchyDock", "PropertiesDock", "TitleBar", "MenuBar", "Footer", "Viewport", "Ribbon" }) do
  local f = Instance.new("Frame"); f.Name = nm; f.Parent = canvas
end
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local coreReady = Instance.new("BoolValue"); coreReady.Name = "CoreReady"; coreReady.Value = true; coreReady.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
local menusReady = Instance.new("BoolValue"); menusReady.Name = "MenusReady"; menusReady.Parent = runtime

-- script = o Menus (parentado no ScreenGui)
script = Instance.new("LocalScript"); script.Name = "Arkher_03_Menus"; script.Parent = gui

-- ---- carrega o server (cria a bridge) ----
local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local bridge = RS:FindFirstChild("ArkherStudioBridge")
assert(bridge, "bridge nao criada")
local request = bridge:FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")

-- estado do cliente (selectedId) mantido pelo teste
local cstate = { selectedId = nil, workspaceId = nil, node = nil }
local messages = {}
clientBus.OnInvoke = function(action, payload)
  payload = payload or {}
  if action == "ClaimPart" then return true end
  if action == "API" then
    local r = rawget(request, "__props").OnServerInvoke(tp, payload.action, payload.payload)
    if r and r.error then return { error = r.error } end
    return { result = r }
  end
  if action == "State" then return cstate end
  if action == "Message" then messages[#messages + 1] = { text = payload.text, bad = payload.bad } return true end
  if action == "Info" then messages[#messages + 1] = { info = payload.title } return true end
  if action == "Diagnostic" then return true end
  if action == "Created" then return true end
  if action == "MenuChanged" then return true end
  if action == "Icon" then return true end
  if action == "Done" or action == "Wip" or action == "Tooltip" then return true end
  if action == "FinishDrag" or action == "DragState" or action == "Preview" or action == "Properties" then return true end
  return true
end

-- ---- carrega o 03_Menus ----
local msrc = io.open("studio-completo/scripts/03_Menus.lua"):read("*a")
local mfn, merr = loadstring(msrc, "[menus]")
assert(mfn, "sintaxe menus: " .. tostring(merr))
local mok, mrun = pcall(mfn)
check(mok, "03_Menus executou" .. (mok and "" or (" err=" .. tostring(mrun))))
check(menusReady.Value == true, "MenusReady=true apos iniciar")

local function snap() return rawget(request, "__props").OnServerInvoke(tp, "Snapshot", {}) end
local function findId(s, name) for _, n in ipairs(s.nodes) do if n.name == name then return n.id end end end
local function exists(s, name) return findId(s, name) ~= nil end

print("\n== Build dos menus (MenusBus 'Menu') ==")
local function menuItems(name)
  menusBus:Invoke("Menu", { name = name })
  local f = popups:FindFirstChild(name .. "Menu")
  if not f then return nil, nil end
  local items = 0
  for _, c in ipairs(f:GetChildren()) do if c:IsA("TextButton") then items = items + 1 end end
  return f, items
end
local fEdit, nEdit = menuItems("Edit")
check(fEdit ~= nil, "Menu Edit criado")
check(nEdit == 8, "Menu Edit tem 8 itens (=" .. tostring(nEdit) .. ")")
local fFile, nFile = menuItems("File")
check(fFile ~= nil, "Menu File criado")
check(nFile >= 9, "Menu File tem itens (=" .. tostring(nFile) .. ")")
local fRun, nRun = menuItems("Run")
check(fRun ~= nil and nRun == 3, "Menu Run tem 3 itens (Play/Pause/Stop)")
menusBus:Invoke("CloseAll")
check(popups:FindFirstChild("RunMenu") == nil, "CloseAll fecha o menu")

print("\n== Acao: criar part (server) + Edit > Excluir via menu ==")
local s0 = snap()
local wsId = findId(s0, "Workspace")
cstate.workspaceId = wsId
local c = rawget(request, "__props").OnServerInvoke(tp, "Create", { parentId = wsId, class = "Part", name = "PartViaMenu" })
check(c and c.ok == true, "Create PartViaMenu (id=" .. (c and c.node and c.node.id) .. ")")
cstate.selectedId = c.node.id
-- abre o menu Edit e dispara o item 'Excluir'
menusBus:Invoke("Menu", { name = "Edit" })
local editMenu = popups:FindFirstChild("EditMenu")
local delBtn
for _, b in ipairs(editMenu:GetChildren()) do
  if b:IsA("TextButton") and b:FindFirstChild("Lbl") and b:FindFirstChild("Lbl").Text:find("Excluir") then delBtn = b end
end
check(delBtn ~= nil, "botao 'Excluir' encontrado no menu Edit")
if delBtn then
  delBtn.Activated:Fire()
  local s1 = snap()
  check(not exists(s1, "PartViaMenu"), "apos Excluir: PartViaMenu removida")
  check(#messages > 0, "feedback de status emitido")
end

print("\n== Acao: Edit > Desfazer restaura a part ==")
menusBus:Invoke("Menu", { name = "Edit" })
local editMenu2 = popups:FindFirstChild("EditMenu")
local undoBtn
for _, b in ipairs(editMenu2:GetChildren()) do
  if b:IsA("TextButton") and b:FindFirstChild("Lbl") and b:FindFirstChild("Lbl").Text:find("Desfazer") then undoBtn = b end
end
if undoBtn then
  undoBtn.Activated:Fire()
  local s2 = snap()
  check(exists(s2, "PartViaMenu"), "apos Desfazer: PartViaMenu restaurada")
end

print("\n== Acao: View > Hierarchy alterna o painel ==")
local hd = canvas:FindFirstChild("HierarchyDock")
hd.Visible = true
menusBus:Invoke("Menu", { name = "View" })
local viewMenu = popups:FindFirstChild("ViewMenu")
local hierBtn
for _, b in ipairs(viewMenu:GetChildren()) do
  if b:IsA("TextButton") and b:FindFirstChild("Lbl") and b:FindFirstChild("Lbl").Text:find("Hierarchy") then hierBtn = b end
end
if hierBtn then
  hierBtn.Activated:Fire()
  check(hd.Visible == false, "View > Hierarchy ocultou o painel")
  hierBtn.Activated:Fire()
  check(hd.Visible == true, "View > Hierarchy (de novo) exibiu o painel")
end

print("\n== Run > Play/Stop (atributo ArkherRunning) ==")
menusBus:Invoke("RunToggle")
check(runtime:GetAttribute("ArkherRunning") == true, "RunToggle -> Play (ArkherRunning=true)")
menusBus:Invoke("RunToggle")
check(runtime:GetAttribute("ArkherRunning") == false, "RunToggle -> Stop (ArkherRunning=false)")

print("\n== Game > Configurações abre dialog ==")
menusBus:Invoke("Menu", { name = "Game" })
local gameMenu = popups:FindFirstChild("GameMenu")
local setBtn
for _, b in ipairs(gameMenu:GetChildren()) do
  if b:IsA("TextButton") and b:FindFirstChild("Lbl") and b:FindFirstChild("Lbl").Text:find("Configurações do jogo") then setBtn = b end
end
if setBtn then
  setBtn.Activated:Fire()
  check(popups:FindFirstChild("ArkherSettingsDialog") ~= nil, "Game > Configurações abriu o dialog de settings")
end

print("\n================================")
print(string.format("CLIENTE: %d passaram, %d falharam", pass, fail))
if fail > 0 then os.exit(1) else os.exit(0) end
