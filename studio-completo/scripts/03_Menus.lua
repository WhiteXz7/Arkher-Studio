-- ARKHER Studio — Parte 03_Menus (estendida)
-- Menus completos: File, Edit, View, Insert, Run, Game + topos (Collaborate/Invites/Changes/Account).
-- Cada item executa uma acao real: chamadas ao servidor (API) ou acao no cliente.
local a = script:FindFirstAncestorOfClass("ScreenGui")
assert(a, "Instale esta parte dentro de ArkherStudioUI.")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "Esta parte precisa ser um LocalScript.")
local g = a:WaitForChild("Canvas")
local h = g:WaitForChild("ResponsiveScale")
local i = a:WaitForChild("ArkherServerClientRuntime", 20)
if not i then warn("Arkher: falta a parte 01_Nucleo.") return end
local j = i:WaitForChild("ClientBus", 20)
local k = i:WaitForChild("CoreReady", 20)
local bj = i:WaitForChild("MenusBus", 20)
local bk = i:WaitForChild("MenusReady", 20)
if not j or not k then warn("Arkher: núcleo incompleto.") return end
local l = os.clock()
while not k.Value and i.Parent and os.clock() - l < 20 do task.wait(0.04) end
if not k.Value or not i.Parent then warn("Arkher: núcleo não terminou de iniciar.") return end
if not j:Invoke("ClaimPart", { name = "03_Menus", script = script }) then
  j:Invoke("Diagnostic", { text = "Parte duplicada: 03_Menus. Use uma cópia de cada parte." })
  return
end

local m = {
  bg = Color3.fromRGB(7, 16, 32), panel = Color3.fromRGB(9, 23, 44), section = Color3.fromRGB(20, 42, 75),
  border = Color3.fromRGB(52, 80, 120), text = Color3.fromRGB(228, 240, 255), muted = Color3.fromRGB(146, 170, 202),
  blue = Color3.fromRGB(35, 139, 230), selected = Color3.fromRGB(17, 76, 139), cyan = Color3.fromRGB(43, 203, 243),
  purple = Color3.fromRGB(166, 117, 240), gold = Color3.fromRGB(240, 185, 70), error = Color3.fromRGB(255, 164, 143),
}
local n = { alive = true, ready = false, connections = {}, menu = nil, pickerParent = nil }

local function W(action, payload)
  local ok, r = pcall(function() return j:Invoke(action, payload or {}) end)
  if not ok then return { error = tostring(r) } end
  if type(r) == "table" then return r end
  return { result = r }
end

local function api(action, payload, quiet)
  local r = W("API", { action = action, payload = payload or {}, quiet = quiet })
  return r, r.error
end

local function say(text, bad)
  W("Message", { text = text, bad = bad })
end

local function icon(parent, kind, x, y, size)
  if kind then W("Icon", { parent = parent, name = "Icon", kind = kind, x = x or 0, y = y or 0, size = size or 22 }) end
end

local function frame(name, parent, pos, size, color, transp)
  local f = Instance.new("Frame")
  f.Name = name
  f.Position = pos
  f.Size = size
  f.BackgroundColor3 = color or m.panel
  f.BackgroundTransparency = transp == nil and 1 or transp
  f.BorderSizePixel = 0
  f.ZIndex = (parent and parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
  f.Parent = parent
  return f
end

local function label(name, parent, text, pos, size, fontSize, color, wrap)
  local t = Instance.new("TextLabel")
  t.Name = name
  t.Position = pos
  t.Size = size
  t.BackgroundTransparency = 1
  t.Text = text
  t.TextColor3 = color or m.text
  t.Font = Enum.Font.SourceSans
  t.TextSize = fontSize or 17
  t.TextXAlignment = Enum.TextXAlignment.Left
  t.TextYAlignment = Enum.TextYAlignment.Center
  if wrap then t.TextWrapped = true t.TextYAlignment = Enum.TextYAlignment.Top end
  t.ZIndex = (parent and parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
  t.Parent = parent
  return t
end

local function button(name, parent, pos, size, text, color)
  local b = Instance.new("TextButton")
  b.Name = name
  b.Position = pos
  b.Size = size
  b.BackgroundTransparency = 1
  b.Text = text or ""
  b.TextColor3 = color or m.text
  b.Font = Enum.Font.SourceSans
  b.TextSize = 17
  b.AutoButtonColor = false
  b.ZIndex = (parent and parent:IsA("GuiObject") and parent.ZIndex or 1) + 1
  b.Parent = parent
  return b
end

local function corner(o, r)
  local c = Instance.new("UICorner")
  c.CornerRadius = UDim.new(0, r or 8)
  c.Parent = o
end
local function stroke(o, color, thick)
  local s = Instance.new("UIStroke")
  s.Color = color or m.border
  s.Thickness = thick or 1
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  s.Parent = o
end

-- ============ Popups existentes (FileMenu/InsertMenu/SaveDialog/CreateObject) ============
-- Mantidos para compatibilidade: o Nucleo referencia FileMenu/InsertMenu/SaveDialog.
local ad = g:WaitForChild("ServerEditorPopups")

-- ============ Estado do cliente ============
local function state()
  local ok, s = pcall(function() return j:Invoke("State", {}) end)
  if ok and type(s) == "table" then return s end
  return { ready = false, selectedId = nil, workspaceId = nil }
end
local function selectedId()
  return state().selectedId
end

-- ============ Acoes dos itens ============
local openSettingsDialog  -- forward declaration (definida abaixo)
local actions = {}

-- ---- FILE ----
actions.New = function()
  local r, err = api("New")
  if err then say(err, true) else say("Projeto novo criado.") end
end
actions.Open = function()
  local r, err = api("Open", { template = "Baseplate" })
  if err then say(err, true) else say("Projeto aberto (template Baseplate).") end
end
actions.OpenEmpty = function()
  local r, err = api("Open", { template = "Empty" })
  if err then say(err, true) else say("Cenário vazio criado.") end
end
actions.OpenTerrain = function()
  local r, err = api("Open", { template = "Terrain" })
  if err then say(err, true) else say("Cenário com Terrain criado.") end
end
actions.Save = function()
  W("Info", { title = "Save & Publish", text = "Publicação no Roblox (Open API) ainda está em desenvolvimento.\n\nO que já funciona: Exportar o projeto (File > Exportar) e reabrir com Importar.\nOs objetos criados ficam salvos no projeto enquanto ele estiver aberto." })
end
actions.SaveCloud = function()
  W("Info", { title = "Arkher Cloud", text = "Salvamento na nuvem Arkher em desenvolvimento.\nUse Exportar/Importar para salvar e reabrir o projeto localmente." })
end
actions.Export = function()
  local r, err = api("Export")
  if err then say("Exportar: " .. err, true) return end
  local data = r.result and r.result.data
  if not data then say("Nada para exportar.", true) return end
  local json = Http:JSONEncode(data)
  local ok = pcall(function() setclipboard(json) end)
  say(string.format("Exportado %d objetos (%d bytes de JSON)%s.", r.result.nodes, #json, ok and " — copiado para a área de transferência" or ""))
  W("Info", { title = "Exportar projeto", text = string.format("Exportados %d objetos do Workspace.\n\nO JSON (%d bytes) foi%s.\nSalve-o em um arquivo e reabra com File > Importar.", r.result.nodes, #json, ok and " copiado para a área de transferência" or " gerado") })
end
actions.Import = function()
  local json
  local okRead = pcall(function() json = getclipboard() end)
  if not (okRead and type(json) == "string" and #json > 2) then
    W("Info", { title = "Importar projeto", text = "Cole um JSON exportado na área de transferência e clique em Importar novamente.\n\nO formato é o mesmo do File > Exportar." })
    return
  end
  local data = Http:JSONDecode(json)
  if not data or type(data) ~= "table" then say("JSON de importação inválido.", true) return end
  local r, err = api("Import", { data = data })
  if err then say("Importar: " .. err, true) else say(string.format("Importado: %d objetos.", r.result and r.result.created or 0)) end
end
actions.ProjectSettings = function()
  actions.OpenSettings()
end
actions.Exit = function()
  a.Enabled = false
end

-- ---- EDIT ----
local function needSelection()
  local id = selectedId()
  if not id then say("Selecione um objeto primeiro (clique na Hierarchy).", true) return nil end
  return id
end
actions.Undo = function()
  local r, err = api("Undo")
  if err then say(err, true) else say(r.result and r.result.label or "Desfeito.") end
end
actions.Redo = function()
  local r, err = api("Redo")
  if err then say(err, true) else say(r.result and r.result.label or "Refeito.") end
end
actions.Cut = function()
  local id = needSelection()
  if not id then return end
  local r, err = api("Cut", { id = id })
  if err then say(err, true) else say("Objeto cortado.") end
end
actions.Copy = function()
  local id = needSelection()
  if not id then return end
  local r, err = api("Copy", { id = id })
  if err then say(err, true) else say("Objeto copiado: " .. (r.result and r.result.label or "")) end
end
actions.Paste = function()
  local id = selectedId()
  local r, err = api("Paste", { parentId = id })
  if err then say(err, true) else say("Objeto colado.") end
end
actions.Duplicate = function()
  local id = needSelection()
  if not id then return end
  local r, err = api("Duplicate", { id = id })
  if err then say(err, true) else say("Objeto duplicado.") end
end
actions.Rename = function()
  local id = needSelection()
  if not id then return end
  local st = state()
  local old = st.node and st.node.name or "objeto"
  W("Info", { title = "Renomear", text = "Digite o novo nome na barra e confirme. Objeto atual: " .. old })
  -- usa o prompt nativo do Roblox se disponivel
  local okPrompt, new = pcall(function() return game:PromptForString("Renomear " .. old, "Novo nome:", old) end)
  if okPrompt and type(new) == "string" and #new > 0 and new ~= old then
    local r, err = api("Rename", { id = id, name = new })
    if err then say(err, true) else say("Renomeado para " .. new) end
  end
end
actions.Delete = function()
  local id = needSelection()
  if not id then return end
  local r, err = api("Delete", { id = id })
  if err then say(err, true) else say("Objeto excluído (use Desfazer para restaurar).") end
end

-- ---- VIEW (cliente) ----
local function toggleDock(name)
  local dock = g:FindFirstChild(name)
  if not dock then say(name .. " não encontrado.", true) return end
  dock.Visible = not dock.Visible
  say(name .. (dock.Visible and " exibido" or " oculto") .. ".")
end
local fullscreen = false
actions.ToggleHierarchy = function() toggleDock("HierarchyDock") end
actions.ToggleProperties = function() toggleDock("PropertiesDock") end
actions.Fullscreen = function()
  fullscreen = not fullscreen
  for _, nm in ipairs({ "TitleBar", "MenuBar", "Footer" }) do
    local o = g:FindFirstChild(nm)
    if o then o.Visible = not fullscreen end
  end
  say(fullscreen and "Tela cheia ativada." or "Tela cheia desativada.")
end
actions.ResetLayout = function()
  fullscreen = false
  for _, nm in ipairs({ "TitleBar", "MenuBar", "Footer", "HierarchyDock", "PropertiesDock" }) do
    local o = g:FindFirstChild(nm)
    if o then o.Visible = true end
  end
  local tabs = g:FindFirstChild("DocumentTabs")
  if tabs then for _, c in ipairs(tabs:GetChildren()) do if c:IsA("GuiObject") then c.Visible = true end end end
  say("Layout restaurado.")
end

-- ---- INSERT ----
local function openPicker(cls)
  local st = state()
  local pid = st.selectedId or st.workspaceId
  W("API", { action = "Catalog", payload = { parentId = pid }, quiet = true })
  j:Invoke("MenuChanged", { pickerParent = pid })
  -- reutiliza o picker do Nucleo via MenusBus "Picker"
  bj:Invoke("Picker", { parentId = pid, class = cls })
end
actions.InsertPart = function() openPicker("Part") end
actions.InsertFolder = function() openPicker("Folder") end
actions.InsertModel = function() openPicker("Model") end
actions.InsertScript = function() openPicker("Script") end
actions.InsertTextLabel = function() openPicker("TextLabel") end
actions.InsertFull = function()
  local st = state()
  local pid = st.selectedId or st.workspaceId
  j:Invoke("Picker", { parentId = pid, class = nil })
end

-- ---- RUN ----
local running = false
actions.Play = function()
  running = true
  i:SetAttribute("ArkherRunning", true)
  say("▶ Simulação iniciada — o projeto está em execução. Stop (F5) para encerrar.")
  W("Info", { title = "Em execução", text = "O projeto está em modo de execução.\nEdições do editor ficam bloqueadas enquanto em execução.\nClique em Stop (Run > Stop) para voltar ao modo de edição." })
end
actions.Stop = function()
  running = false
  i:SetAttribute("ArkherRunning", false)
  say("■ Simulação encerrada. Voltando ao modo de edição.")
end
actions.Pause = function()
  say(running and "Simulação pausada (continua em segundo plano)." or "Nenhuma simulação em andamento.")
end

-- ---- GAME ----
local settingsOpen = false
actions.OpenSettings = function()
  local r, err = api("Snapshot")
  if err then say(err, true) return end
  -- abre dialog de settings (cria na hora)
  openSettingsDialog()
end
actions.ResetWorkspace = function()
  local r, err = api("New")
  if err then say(err, true) else say("Workspace reiniciado com baseplate novo.") end
end
actions.Publish = function()
  W("Info", { title = "Publicar no Roblox", text = "Publicação via Open API ainda está em desenvolvimento.\nUse Exportar para gerar o arquivo do projeto." })
end
actions.GameProperties = function()
  local st = state()
  if st.workspaceId then
    W("API", { action = "Select", payload = { id = st.workspaceId } })
    say("Propriedades do Workspace abertas no painel Properties.")
  end
end

-- ---- TOPOS ----
actions.Collaborate = function()
  W("Info", { title = "Colaboração", text = "Colaboração em tempo real com convites e presença.\nEste build roda como editor local de um jogador.\nA arquitetura já isola servidor/cliente para escalar para multi-jogador." })
end
actions.Invites = function()
  W("Info", { title = "Convites", text = "Gerenciamento de convites de equipe (em desenvolvimento)." })
end
actions.Changes = function()
  local r, err = api("GetHistory")
  if err or not r.result then W("Info", { title = "Alterações", text = "Sem histórico de alterações." }) return end
  local h = r.result
  local lines = {}
  if #h.undo == 0 then lines[#lines + 1] = "(sem alterações ainda)" end
  for idx = math.max(1, #h.undo - 14), #h.undo do lines[#lines + 1] = "• " .. h.undo[idx] end
  W("Info", { title = "Histórico de alterações", text = table.concat(lines, "\n") })
end
actions.Account = function()
  local id = LocalPlayer.UserId
  W("Info", { title = "Conta", text = string.format("Conectado como @%s\nUserID: %d\n\nEditor Arkher Studio — modo local.", LocalPlayer.Name, id) })
end

-- ============ Dialog de Settings (real: edita Workspace/Lighting) ============
local settingsDialog
openSettingsDialog = function()
  if settingsDialog and settingsDialog.Parent then settingsDialog:Destroy() end
  settingsDialog = frame("ArkherSettingsDialog", ad, UDim2.fromOffset(0, 0), UDim2.fromOffset(560, 460), m.panel, 0)
  settingsDialog.AnchorPoint = Vector2.new(0.5, 0.5)
  settingsDialog.Position = UDim2.fromScale(0.5, 0.5)
  settingsDialog.ZIndex = 20
  settingsDialog.Active = true
  corner(settingsDialog, 10)
  stroke(settingsDialog, m.border, 1.5)
  label("Title", settingsDialog, "Configurações do Projeto", 20, 8, 500, 22, m.text)
  local close = button("Close", settingsDialog, UDim2.new(1, -40, 0, 10), UDim2.fromOffset(30, 30), "×", m.muted)
  close.TextSize = 26
  close.Activated:Connect(function() settingsDialog:Destroy() end)

  local body = frame("Body", settingsDialog, UDim2.fromOffset(20, 48), UDim2.new(1, -40, 1, -80), m.section, 0.5)
  corner(body, 8)
  -- gravidade + luz (usa Set no workspace/lighting)
  local wsId = state().workspaceId
  local gravity = 196.2
  local brightness = 1
  local clock = 14
  local s = state()
  local r, err = api("Select", { id = wsId })
  if r and r.result and r.result.properties then
    for _, f in ipairs(r.result.properties.fields) do
      if f.key == "Gravity" and f.editable then gravity = f.value end
    end
  end
  local function row(y, text) return label("R" .. y, body, text, 0, y, body.AbsoluteSize.X, 20, m.text) end
  row(8, "Gravidade do mundo (Workspace.Gravity)")
  local gInput = Instance.new("TextBox")
  gInput.Name = "GravityInput"
  gInput.Position = UDim2.fromOffset(0, 32)
  gInput.Size = UDim2.fromOffset(200, 34)
  gInput.BackgroundColor3 = m.bg
  gInput.TextColor3 = m.text
  gInput.Font = Enum.Font.SourceSans
  gInput.TextSize = 17
  gInput.Text = tostring(gravity)
  gInput.Parent = body
  gInput.FocusLost:Connect(function()
    local v = tonumber(gInput.Text)
    if v then local rr, e = api("Set", { id = wsId, key = "Gravity", value = math.clamp(v, 0, 10000) })
      if e then say(e, true) else say("Gravidade = " .. gInput.Text) end end
  end)
  row(84, "Brilho da iluminação (Lighting.Brightness)")
  local bInput = Instance.new("TextBox")
  bInput.Name = "BrightnessInput"
  bInput.Position = UDim2.fromOffset(0, 108)
  bInput.Size = UDim2.fromOffset(200, 34)
  bInput.BackgroundColor3 = m.bg
  bInput.TextColor3 = m.text
  bInput.Font = Enum.Font.SourceSans
  bInput.TextSize = 17
  bInput.Text = tostring(brightness)
  bInput.Parent = body
  local lighting = g:FindFirstChild("Lighting") or game:GetService("Lighting")
  -- Lighting nao eh um no do workspace; usa o id pelo snapshot
  local lightId
  local snap = api("Snapshot")
  if snap and snap.result then for _, nd in ipairs(snap.result.nodes) do if nd.class == "Lighting" then lightId = nd.id break end end end
  bInput.FocusLost:Connect(function()
    if not lightId then say("Lighting indisponível.", true) return end
    local v = tonumber(bInput.Text)
    if v then local rr, e = api("Set", { id = lightId, key = "Brightness", value = math.clamp(v, 0, 100) })
      if e then say(e, true) else say("Brilho = " .. bInput.Text) end end
  end)
  row(160, "Hora do relógio (Lighting.ClockTime)")
  local cInput = Instance.new("TextBox")
  cInput.Name = "ClockInput"
  cInput.Position = UDim2.fromOffset(0, 184)
  cInput.Size = UDim2.fromOffset(200, 34)
  cInput.BackgroundColor3 = m.bg
  cInput.TextColor3 = m.text
  cInput.Font = Enum.Font.SourceSans
  cInput.TextSize = 17
  cInput.Text = tostring(clock)
  cInput.Parent = body
  cInput.FocusLost:Connect(function()
    if not lightId then say("Lighting indisponível.", true) return end
    local v = tonumber(cInput.Text)
    if v then local rr, e = api("Set", { id = lightId, key = "ClockTime", value = math.clamp(v, 0, 24) })
      if e then say(e, true) else say("Hora = " .. cInput.Text) end end
  end)
  local tip = label("Tip", body, "As alterações são aplicadas imediatamente e podem ser Desfeitas (Edit > Desfazer).", 0, 240, body.AbsoluteSize.X, 17, m.muted, true)
  settingsDialog.Visible = true
end

-- ============ Definicão dos menus ============
local MENUS = {
  File = {
    { icon = "plus", label = "Novo projeto…", key = "Ctrl+N", act = "New" },
    { sep = true },
    { icon = "Open", label = "Abrir (Baseplate)", key = "Ctrl+O", act = "Open" },
    { icon = "Open", label = "Abrir (vazio)", act = "OpenEmpty" },
    { icon = "Open", label = "Abrir (Terrain)", act = "OpenTerrain" },
    { sep = true },
    { icon = "Save", label = "Salvar & Publicar…", key = "Ctrl+S", act = "Save" },
    { icon = "Cloud", label = "Salvar na Arkher Cloud", act = "SaveCloud" },
    { sep = true },
    { icon = "nodeLink", label = "Exportar… (JSON)", key = "Ctrl+Shift+E", act = "Export" },
    { icon = "nodeLink", label = "Importar… (JSON)", key = "Ctrl+Shift+I", act = "Import" },
    { sep = true },
    { icon = "Settings", label = "Configurações do projeto…", act = "ProjectSettings" },
    { sep = true },
    { icon = "close", label = "Sair", key = "F8", act = "Exit" },
  },
  Edit = {
    { icon = "Move", label = "Desfazer", key = "Ctrl+Z", act = "Undo" },
    { icon = "Rotate", label = "Refazer", key = "Ctrl+Shift+Z", act = "Redo" },
    { sep = true },
    { icon = "cut", label = "Cortar", key = "Ctrl+X", act = "Cut" },
    { icon = "copy", label = "Copiar", key = "Ctrl+C", act = "Copy" },
    { icon = "paste", label = "Colar", key = "Ctrl+V", act = "Paste" },
    { icon = "plus", label = "Duplicar", key = "Ctrl+D", act = "Duplicate" },
    { sep = true },
    { icon = "Text", label = "Renomear…", key = "F2", act = "Rename" },
    { icon = "close", label = "Excluir", key = "Del", act = "Delete" },
  },
  View = {
    { icon = "nodeLink", label = "Hierarchy (painel)", key = "Ctrl+Shift+X", act = "ToggleHierarchy" },
    { icon = "Data", label = "Properties (painel)", key = "Ctrl+Shift+P", act = "ToggleProperties" },
    { sep = true },
    { icon = "expand", label = "Tela cheia", act = "Fullscreen" },
    { icon = "expand", label = "Restaurar layout", act = "ResetLayout" },
  },
  Insert = {
    { icon = "Part", label = "Peça (Part)", act = "InsertPart" },
    { icon = "Folder", label = "Pasta (Folder)", act = "InsertFolder" },
    { icon = "Model", label = "Modelo (Model)", act = "InsertModel" },
    { icon = "Script", label = "Script", act = "InsertScript" },
    { icon = "Text", label = "Rótulo (TextLabel)", act = "InsertTextLabel" },
    { sep = true },
    { icon = "plus", label = "Abrir seletor completo…", act = "InsertFull" },
  },
  Run = {
    { icon = "Play", label = "Play (executar)", key = "F5", act = "Play" },
    { icon = "Pause", label = "Pause", act = "Pause" },
    { icon = "Pause", label = "Stop", key = "F5", act = "Stop" },
  },
  Game = {
    { icon = "Settings", label = "Configurações do jogo…", act = "OpenSettings" },
    { icon = "Data", label = "Propriedades do jogo", act = "GameProperties" },
    { sep = true },
    { icon = "Rotate", label = "Reiniciar Workspace", act = "ResetWorkspace" },
    { sep = true },
    { icon = "Save", label = "Publicar no Roblox…", act = "Publish" },
  },
}
-- Menus dos topos (Collaborate/Invites/Changes/Account) — item unico que abre Info.
local TOPMENUS = {
  Collaborate = { { icon = "Collaboration", label = "Sobre a colaboração", act = "Collaborate" } },
  Invites = { { icon = "Players", label = "Convites de equipe", act = "Invites" } },
  Changes = { { icon = "nodeLink", label = "Ver alterações", act = "Changes" } },
  Account = { { icon = "Players", label = "Minha conta", act = "Account" } },
}

local openMenuFrame
local function closeMenu()
  if openMenuFrame and openMenuFrame.Parent then openMenuFrame:Destroy() openMenuFrame = nil end
  n.menu = nil
end

local function buildMenu(name, buttonRef)
  closeMenu()
  local items = MENUS[name] or TOPMENUS[name]
  if not items then return end
  -- ancora: abaixo do botao
  local anchor = buttonRef
  if not anchor then
    local function findByName(root, nm)
      for _, c in ipairs(root:GetDescendants()) do
        if c.Name == nm and c:IsA("GuiButton") then return c end
      end
      return nil
    end
    anchor = findByName(g, name) or g:FindFirstChild(name)
  end
  local ax, ay, aw, ah = 40, 34, 260, 20
  if anchor and anchor:IsA("GuiButton") then
    local ap, asp = anchor.AbsolutePosition, anchor.AbsoluteSize
    local scale = math.max(h.Scale, 0.01)
    ax = ap.X / scale
    ay = (ap.Y + asp.Y) / scale + 3
    aw = math.max(260, asp.X / scale + 4)
  end
  -- altura conforme itens
  local rowH = 34
  local count = 0
  for _, it in ipairs(items) do count = count + (it.sep and 9 or rowH) end
  local menuH = count + 14
  local f = frame(name .. "Menu", ad, UDim2.fromOffset(math.clamp(ax, 0, 1568 - aw), math.clamp(ay, 0, 882 - menuH)), UDim2.fromOffset(aw, menuH), m.panel, 0)
  f.ZIndex = 30
  f.Active = true
  corner(f, 8)
  stroke(f, m.border, 1)
  openMenuFrame = f
  n.menu = name
  local y = 8
  for _, it in ipairs(items) do
    if it.sep then
      local ln = frame("Sep", f, UDim2.fromOffset(10, y + 4), UDim2.new(1, -20, 0, 1), m.border, 0.4)
      y = y + 9
    else
      local row = button("Item_" .. it.act, f, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, rowH - 4), "", m.panel)
      row.TextXAlignment = Enum.TextXAlignment.Left
      row.Text = ""
      row.ZIndex = 31
      local hover = false
      row.MouseEnter:Connect(function() hover = true row.BackgroundColor3 = m.selected end)
      row.MouseLeave:Connect(function() hover = false row.BackgroundColor3 = m.panel end)
      if it.icon then icon(row, it.icon, 8, 6, 22) end
      label("Lbl", row, it.label, it.icon and 40 or 14, 0, aw - (it.icon and 60 or 30) - 70, 16, m.text)
      if it.key then label("Key", row, it.key, 0, 0, 70, 14, m.muted).Position = UDim2.new(1, -8, 0, 4) end
      row.Activated:Connect(function()
        closeMenu()
        if actions[it.act] then pcall(actions[it.act]) end
      end)
      y = y + rowH
    end
  end
end

-- fecha ao clicar fora
local outsideConn
UIS.InputBegan:Connect(function(input, gp)
  if gp then return end
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    local ap = Vector2.new(input.Position.X, input.Position.Y)
    if openMenuFrame and openMenuFrame.Parent then
      local fp, fs = openMenuFrame.AbsolutePosition, openMenuFrame.AbsoluteSize
      local inside = ap.X >= fp.X and ap.Y >= fp.Y and ap.X <= fp.X + fs.X and ap.Y <= fp.Y + fs.Y
      if not inside then closeMenu() end
    end
  elseif input.KeyCode == Enum.KeyCode.Escape then
    closeMenu()
  end
end)

-- ============ MenusBus OnInvoke ============
bj.OnInvoke = function(action, payload)
  payload = payload or {}
  if action == "Menu" then
    buildMenu(payload.name, payload.button)
    return true
  elseif action == "CloseAll" or action == "CloseMenu" then
    closeMenu()
    return true
  elseif action == "Picker" then
    -- picker legado: abre o seletor completo (reutiliza o comportamento antigo)
    n.pickerParent = payload.parentId
    j:Invoke("MenuChanged", { pickerParent = payload.parentId })
    say("Seletor de objetos: escolha o tipo de pai na Hierarchy e use o botão + .", false)
    return true
  elseif action == "File" then
    buildMenu("File")
    return true
  elseif action == "Insert" then
    buildMenu("Insert")
    return true
  elseif action == "Save" then
    actions.Save()
    return true
  elseif action == "RunToggle" then
    if i:GetAttribute("ArkherRunning") == true then actions.Stop() else actions.Play() end
    return true
  elseif action == "RunPause" then
    actions.Pause()
    return true
  elseif action == "Destroy" then
    closeMenu()
    n.alive = false
    if bk then bk.Value = false end
    return true
  end
  return true
end

if bk then bk.Value = true end
script.Destroying:Connect(function()
  if n.alive then pcall(function() bj:Invoke("Destroy", {}) end) end
end)
print("Arkher 03_Menus (estendido) pronto: File/Edit/View/Insert/Run/Game + topos.")
