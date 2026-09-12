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

local function label(name, parent, text, pos, size, fontSize, color, wrap, ...)
  local t = Instance.new("TextLabel")
  t.Name = name
  -- aceita DUAS formas legadas sem quebrar chamadores:
  --   A) pos/size = UDim2, fontSize, color, wrap
  --   B) numerica: x, y, w, h[, fontSize], color[, wrap] -> fromOffset
  if typeof(pos) == "UDim2" then
    t.Position = pos
    t.Size = (typeof(size) == "UDim2") and size or UDim2.new()
    t.TextColor3 = color or m.text
    t.TextSize = fontSize or 17
    if wrap then t.TextWrapped = true t.TextYAlignment = Enum.TextYAlignment.Top end
    if not wrap then t.TextYAlignment = Enum.TextYAlignment.Center end
  else
    local x = type(pos) == "number" and pos or 0
    local y = type(size) == "number" and size or 0
    local w = type(fontSize) == "number" and fontSize or 0
    local h = type(color) == "number" and color or 18
    local fs, col, wp = 17, m.text, false
    if typeof(wrap) == "Color3" then
      col = wrap
      if (...) == true then wp = true end
    elseif type(wrap) == "number" then
      fs = wrap
      local v1, v2 = ...
      if typeof(v1) == "Color3" then col = v1 end
      if v2 == true then wp = true end
    elseif typeof(color) == "Color3" and wrap == nil then
      col = color
      h = 20
    end
    t.Position = UDim2.fromOffset(x, y)
    t.Size = UDim2.fromOffset(w, h)
    t.TextColor3 = col
    t.TextSize = fs
    if wp then t.TextWrapped = true t.TextYAlignment = Enum.TextYAlignment.Top end
    if not wp then t.TextYAlignment = Enum.TextYAlignment.Center end
  end
  t.BackgroundTransparency = 1
  t.Text = text
  t.Font = Enum.Font.SourceSans
  t.TextXAlignment = Enum.TextXAlignment.Left
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
local openPublishDialog, openCloudPanel, openDataPanel, openToolboxPanel
local openCollaborationPanel, openLocalizationPanel, openProjectSettingsPanel, openPluginsPanel
local openProfilePanel, doCloudSave
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
  openPublishDialog()
end
actions.SaveCloud = function()
  openCloudPanel()
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
  openPublishDialog()
end
actions.GameProperties = function()
  local st = state()
  if st.workspaceId then
    W("API", { action = "Select", payload = { id = st.workspaceId } })
    say("Propriedades do Workspace abertas no painel Properties.")
  end
end

-- ---- TOPOS ----
actions.PlacesProfile = function() openPlacesPanel() end
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
    { icon = "Save", label = "Publicar no Roblox…", act = "Publish", tip = "Publica o jogo atual no seu PERFIL (página estilo jogo do Roblox)" },
    { icon = "Folder", label = "Places do meu perfil…", act = "PlacesProfile", tip = "Lista jogos/places do perfil + cria PLACES NOVAS de verdade (CreatePlaceAsync)" },
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
  local cs = rawget(_G, "__arkherCloseSub")
  if cs then pcall(cs) end
  n.menu = nil
end

local subFrame

local function closeSubMenu()
  if subFrame and subFrame.Parent then subFrame:Destroy() end
  subFrame = nil
end
rawset(_G, "__arkherCloseSub", closeSubMenu)

local function buildSubMenu(items2, hostRow, hostMenu)
  closeSubMenu()
  if not items2 or #items2 == 0 then return end
  local rowH = 30
  local count = 0
  for _, it in ipairs(items2) do count = count + (it.sep and 9 or rowH) end
  local menuH = count + 12
  local aw2 = 220
  local rp = hostRow.AbsolutePosition
  local rs = hostRow.AbsoluteSize
  local mp = hostMenu.AbsolutePosition
  local scale = math.max(h.Scale, 0.01)
  local ax = (mp.X + hostMenu.AbsoluteSize.X + 2) / scale
  local ay = rp.Y / scale - 4
  local f = frame("Sub", ad, UDim2.fromOffset(math.clamp(ax, 0, 1568 - aw2), math.clamp(ay, 0, 882 - menuH)), UDim2.fromOffset(aw2, menuH), m.panel, 0)
  f.ZIndex = 34
  f.Active = true
  corner(f, 8)
  stroke(f, m.border, 1.5)
  subFrame = f
  local y2 = 6
  for _, it in ipairs(items2) do
    if it.sep then
      frame("Sep", f, UDim2.fromOffset(10, y2 + 4), UDim2.new(1, -20, 0, 1), m.border, 0.4)
      y2 = y2 + 9
    else
      local row = button("Sub_" .. (it.act or it.label), f, UDim2.fromOffset(4, y2), UDim2.new(1, -8, 0, rowH - 4), "", m.panel)
      row.TextXAlignment = Enum.TextXAlignment.Left
      row.ZIndex = 35
      row.MouseEnter:Connect(function() row.BackgroundColor3 = m.selected end)
      row.MouseLeave:Connect(function() row.BackgroundColor3 = m.panel end)
      if it.icon then icon(row, it.icon, 6, 5, 20) end
      label("Lbl", row, it.label, it.icon and 34 or 12, 0, aw2 - 40, 15, m.text)
      if it.tip then
        row.MouseEnter:Connect(function()
          local tipLbl = hostMenu:FindFirstChild("TipBar")
          if tipLbl then tipLbl.Text = "ⓘ  " .. it.tip end
        end)
      end
      row.Activated:Connect(function()
        closeMenu()
        if actions[it.act] then pcall(actions[it.act]) end
      end)
      y2 = y2 + rowH
    end
  end
  return f
end

local function buildMenu(name, buttonRef)
  closeMenu()
  closeSubMenu()
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
  local hasTips = false
  for _, it in ipairs(items) do
    count = count + (it.sep and 9 or (it.head and 18 or rowH))
    if it.tip then hasTips = true end
  end
  local menuH = count + 14 + (hasTips and 22 or 0)
  local f = frame(name .. "Menu", ad, UDim2.fromOffset(math.clamp(ax, 0, 1568 - aw), math.clamp(ay, 0, 882 - menuH)), UDim2.fromOffset(aw, menuH), m.panel, 0)
  f.ZIndex = 30
  f.Active = true
  corner(f, 8)
  stroke(f, m.border, 1)
  openMenuFrame = f
  n.menu = name
  -- barra de DICA no rodape: diz O QUE cada item faz (resposta ao "nao da pra saber o que colocar")
  if hasTips then
    local tipBar = label("TipBar", f, "ⓘ  Passe o mouse: aqui aparece a explicacao do item", 10, menuH - 20, aw - 20, 12, m.cyan)
    tipBar.Font = Enum.Font.GothamBold
    tipBar.TextSize = 11
  end
  local y = 8
  for _, it in ipairs(items) do
    if it.sep then
      local ln = frame("Sep", f, UDim2.fromOffset(10, y + 4), UDim2.new(1, -20, 0, 1), m.border, 0.4)
      y = y + 9
    elseif it.head then
      label("Head", f, it.head:upper(), 12, y, aw - 24, 11, m.cyan).Font = Enum.Font.GothamBold
      y = y + 18
    else
      local row = button("Item_" .. it.act, f, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, rowH - 4), "", m.panel)
      row.TextXAlignment = Enum.TextXAlignment.Left
      row.Text = ""
      row.ZIndex = 31
      local hover = false
      row.MouseEnter:Connect(function()
        hover = true
        row.BackgroundColor3 = m.selected
        if it.tip then
          local tipLbl = f:FindFirstChild("TipBar")
          if tipLbl then tipLbl.Text = "ⓘ  " .. it.tip end
        end
        if it.sub then buildSubMenu(it.sub, row, f) end
      end)
      row.MouseLeave:Connect(function()
        hover = false
        row.BackgroundColor3 = m.panel
        task.delay(0.25, function()
          if subFrame and subFrame.Parent then
            local mp = Vector2.new(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
            local sp, ss = subFrame.AbsolutePosition, subFrame.AbsoluteSize
            local overSub = mp.X >= sp.X - 4 and mp.Y >= sp.Y - 4 and mp.X <= sp.X + ss.X + 4 and mp.Y <= sp.Y + ss.Y + 4
            local rp2, rs2 = row.AbsolutePosition, row.AbsoluteSize
            local overRow = mp.X >= rp2.X and mp.Y >= rp2.Y and mp.X <= rp2.X + rs2.X and mp.Y <= rp2.Y + rs2.Y
            if not overSub and not overRow then closeSubMenu() end
          end
        end)
      end)
      if it.icon then icon(row, it.icon, 8, 6, 22) end
      local arrow = it.sub and "▸" or ""
      label("Lbl", row, it.label, it.icon and 40 or 14, 0, aw - (it.icon and 60 or 30) - 80, 16, m.text)
      if it.sub and not it.key then it.key = arrow end
      if it.key then label("Key", row, it.key, 0, 0, 70, 14, m.muted).Position = UDim2.new(1, -8, 0, 4) end
      row.Activated:Connect(function()
        if it.sub then buildSubMenu(it.sub, row, f) return end
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

-- ============ PAINÉIS DE SISTEMAS (custom: cloud/publish/data/i18n/toolbox/collab/plugins) ============
local currentPanel
local function closeCurrentPanel()
  if currentPanel and currentPanel.Parent then currentPanel:Destroy() end
  currentPanel = nil
end
local function modalDialog(title, w, h)
  closeCurrentPanel()
  local d = frame("ArkherPanel", ad, UDim2.fromOffset(0, 0), UDim2.fromOffset(w or 640, h or 540), m.panel, 0)
  d.AnchorPoint = Vector2.new(0.5, 0.5)
  d.Position = UDim2.fromScale(0.5, 0.5)
  d.ZIndex = 40
  d.Active = true
  corner(d, 10)
  stroke(d, m.border, 1.5)
  label("Title", d, title, 20, 12, 400, 22, 22, m.text)
  local close = button("Close", d, UDim2.new(1, -40, 0, 12), UDim2.fromOffset(30, 30), "×", m.muted)
  close.TextSize = 26
  close.Activated:Connect(function() closeCurrentPanel() end)
  currentPanel = d
  local body = frame("Body", d, UDim2.fromOffset(20, 52), UDim2.new(1, -40, 1, -68), m.section, 0.55)
  corner(body, 8)
  body.ZIndex = 41
  return d, body
end
local function rowLabel(parent, text, x, y, w, size, color)
  return label("L" .. y, parent, text, UDim2.fromOffset(x, y), UDim2.fromOffset(w or 200, 20), size or 16, color or m.muted)
end
local function input(parent, name, x, y, w, placeholder)
  local t = Instance.new("TextBox")
  t.Name = name
  t.Position = UDim2.fromOffset(x, y)
  t.Size = UDim2.fromOffset(w, 34)
  t.BackgroundColor3 = m.bg
  t.TextColor3 = m.text
  t.PlaceholderColor3 = m.muted
  t.PlaceholderText = placeholder or ""
  t.Font = Enum.Font.SourceSans
  t.TextSize = 16
  t.ClearTextOnFocus = false
  t.ZIndex = 42
  t.Parent = parent
  corner(t, 6)
  stroke(t, m.border, 1)
  return t
end
local function actionBtn(parent, x, y, w, h, text, color)
  local b = button("B" .. y, parent, UDim2.fromOffset(x, y), UDim2.fromOffset(w or 120, h or 34), text, color or m.blue)
  b.TextSize = 16
  b.ZIndex = 42
  corner(b, 6)
  b.MouseEnter:Connect(function() b.BackgroundColor3 = m.selected end)
  b.MouseLeave:Connect(function() b.BackgroundColor3 = color or m.blue end)
  return b
end
local function scrollList(parent, x, y, w, h)
  local s = Instance.new("ScrollingFrame")
  s.Name = "List"
  s.Position = UDim2.fromOffset(x, y)
  s.Size = UDim2.fromOffset(w, h)
  s.BackgroundTransparency = 1
  s.BorderSizePixel = 0
  s.ScrollBarThickness = 8
  s.ScrollBarImageColor3 = m.blue
  s.AutomaticCanvasSize = Enum.AutomaticSize.Y
  s.CanvasSize = UDim2.new(0, 0, 0, 0)
  s.ZIndex = 42
  s.Parent = parent
  local ll = Instance.new("UIListLayout")
  ll.Padding = UDim.new(0, 6)
  ll.SortOrder = Enum.SortOrder.LayoutOrder
  ll.Parent = s
  return s
end
local function card(parent, order, h)
  local c = frame("Item_" .. order, parent, UDim2.fromOffset(0, 0), UDim2.new(1, -10, 0, h or 64), m.panel, 0)
  c.LayoutOrder = order
  c.ZIndex = 43
  corner(c, 8)
  stroke(c, m.border, 1)
  return c
end

-- ---------- PUBLICAR (perfil do dev) ----------
openPublishDialog = function()
  local d, body = modalDialog("Publicar no perfil do dev", 660, 600)
  rowLabel(body, "Título do jogo", 0, 10, 200, 15)
  local title = input(body, "Title", 0, 32, 420, "Ex: Meu Jogo Insano")
  rowLabel(body, "Descrição", 0, 80, 200, 15)
  local desc = input(body, "Desc", 0, 102, 620, "Conte sobre o seu jogo…")
  rowLabel(body, "Gênero", 0, 150, 200, 15)
  local genre = input(body, "Genre", 0, 172, 240, "Aventura")
  rowLabel(body, "Visibilidade", 260, 150, 200, 15)
  local vis = "Public"
  local visBtn = actionBtn(body, 260, 172, 150, 34, "Public", m.purple)
  visBtn.Activated:Connect(function() vis = vis == "Public" and "Unlisted" or (vis == "Unlisted" and "Private" or "Public") visBtn.Text = vis end)
  local pubBtn = actionBtn(body, 430, 172, 190, 34, "Publicar no Roblox  →", m.gold)
  pubBtn.Activated:Connect(function()
    local r, err = api("Publish", { title = title.Text, description = desc.Text, genre = genre.Text, visibility = vis })
    if err then say("Publicar: " .. err, true) return end
    local g = r.result and r.result.game
    say("Publicado! Seu jogo está no perfil de @" .. g.publishedBy)
    for _, c in ipairs(body:GetChildren()) do if c.Name == "GameCard" then c:Destroy() end end
    local cardW = 620
    local gc = frame("GameCard", body, UDim2.fromOffset(0, 224), UDim2.new(1, -12, 0, 300), m.bg, 0)
    gc.ZIndex = 42
    corner(gc, 10)
    stroke(gc, m.gold, 2)
    local thumb = frame("Thumb", gc, UDim2.fromOffset(20, 20), UDim2.fromOffset(300, 150), Color3.fromRGB(28, 58, 108), 0)
    corner(thumb, 8)
    stroke(thumb, m.blue, 1)
    local tt = label("ThumbTxt", thumb, g.title, 0, 0, 280, 40, 26, m.text)
    tt.Position = UDim2.new(0.5, 0, 0.5, 0)
    tt.AnchorPoint = Vector2.new(0.5, 0.5)
    tt.TextXAlignment = Enum.TextXAlignment.Center
    tt.TextWrapped = true
    local play = button("PlayBtn", gc, UDim2.fromOffset(20, 182), UDim2.fromOffset(300, 44), "JOGAR", m.blue)
    play.TextSize = 20
    play.ZIndex = 43
    corner(play, 8)
    play.Activated:Connect(function() say("Abrindo " .. g.url .. " (publicação local simulada).", false) end)
    local meta = "Perfil: @" .. g.publishedBy .. "\nURL: " .. g.url .. "\nVersão " .. g.version .. " · " .. g.visibility .. "\nVisitas: " .. tostring(g.visits) .. "  ·  Favoritos: " .. tostring(g.favorites) .. "\nGênero: " .. (g.genre or "—") .. "  ·  " .. tostring(g.workspaceNodes or 0) .. " objetos"
    label("Meta", gc, meta, 340, 24, 270, 130, 15, m.text, true)
    local profBtn = actionBtn(gc, 340, 170, 150, 34, "Meu perfil", m.purple)
    profBtn.Activated:Connect(function() openProfilePanel() end)
  end)
  local hint = label("Hint", body, "Publicar cria uma página de jogo no seu perfil de dev (caminho custom — sem depender da Open API Cloud).", 0, 224, 620, 24, 14, m.muted, true)
end

-- ---------- PERFIL DO DEV (meus jogos) ----------
openProfilePanel = function()
  local r, err = api("ProfileList")
  if err then say(err, true) return end
  local games = (r.result and r.result.games) or {}
  local d, body = modalDialog("Meu perfil de dev", 660, 560)
  local st = api("CloudStatus")
  local sr = (st and st.result) or {}
  label("Own", body, "@" .. (sr.owner or "dev") .. "  ·  " .. tostring(#games) .. " jogo(s) publicado(s) no perfil", 0, 8, 600, 22, 15, m.cyan, true)
  local list = scrollList(body, 0, 40, 620, 440)
  if #games == 0 then
    label("Empty", list, "(nenhum jogo publicado ainda — use File > Salvar & Publicar)", UDim2.fromOffset(10, 10), UDim2.fromOffset(600, 30), 15, m.muted)
    return
  end
  for idx, g in ipairs(games) do
    local c = card(list, idx, 96)
    local thumb = frame("Thumb", c, UDim2.fromOffset(12, 12), UDim2.fromOffset(120, 72), Color3.fromRGB(28, 58, 108), 0)
    corner(thumb, 6)
    label("T", c, g.title, 144, 12, 340, 24, 18, m.text)
    label("U", c, g.url, 144, 40, 380, 16, 12, m.muted, true)
    label("M", c, "v" .. g.version .. " · " .. g.visibility .. " · " .. g.genre .. " · " .. tostring(g.visits) .. " visitas", 144, 62, 400, 16, 13, m.muted)
    local del = button("Del", c, UDim2.new(1, -70, 0, 12), UDim2.fromOffset(58, 28), "Excluir", m.error)
    del.TextSize = 13
    del.ZIndex = 44
    del.Activated:Connect(function()
      local rr, ee = api("ProfileDelete", { id = g.id })
      if ee then say(ee, true) else say("Jogo removido do perfil.") end
      openProfilePanel()
    end)
  end
end

-- ---------- ARKHER CLOUD (projetos) ----------
doCloudSave = function(name)
  local r, err = api("CloudSave", { name = name })
  if err then say("Cloud: " .. err, true) else say("Projeto salvo na Arkher Cloud (" .. tostring(r.result and r.result.project and r.result.project.nodes) .. " objetos).") end
end
openCloudPanel = function()
  local st, se = api("CloudStatus")
  local r, err = api("CloudList")
  if err then say(err, true) return end
  local sr = (st and st.result) or {}
  local projects = (r.result and r.result.projects) or {}
  local d, body = modalDialog("Arkher Cloud", 660, 560)
  label("Acc", body, "Conta @" .. (sr.owner or "dev") .. "  ·  " .. (sr.plan or "Creator") .. "  ·  região " .. (sr.region or "—") .. "\nRegistros persistem no seu place (caminho custom, sem Cloud API real).", 0, 8, 620, 40, 14, m.cyan, true)
  rowLabel(body, "Salvar cópia do projeto na cloud", 0, 54, 300, 15)
  local cname = input(body, "CName", 0, 76, 420, "Nome da cópia")
  local saveBtn = actionBtn(body, 430, 76, 190, 34, "Salvar na Cloud", m.blue)
  saveBtn.Activated:Connect(function() doCloudSave(cname.Text) openCloudPanel() end)
  local list = scrollList(body, 0, 126, 620, 356)
  if #projects == 0 then
    label("Empty", list, "(nenhuma cópia na cloud ainda)", UDim2.fromOffset(10, 10), UDim2.fromOffset(500, 24), 14, m.muted)
    return
  end
  for idx, p in ipairs(projects) do
    local c = card(list, idx, 62)
    label("N", c, p.name, 16, 10, 340, 22, 17, m.text)
    label("I", c, tostring(p.nodes) .. " objetos · " .. tostring(p.size) .. " bytes · v" .. tostring(p.versions) .. " · " .. p.savedAt, 16, 36, 400, 16, 12, m.muted)
    local openB = actionBtn(c, 420, 14, 90, 32, "Abrir", m.blue)
    openB.Activated:Connect(function()
      local rr, ee = api("CloudOpen", { id = p.id })
      if ee then say(ee, true) else say("Projeto '" .. p.name .. "' aberto na cloud.") end
      closeCurrentPanel()
    end)
    local delB = button("Del", c, UDim2.new(1, -84, 0, 14), UDim2.fromOffset(70, 32), "Excluir", m.error)
    delB.TextSize = 13
    delB.ZIndex = 44
    delB.Activated:Connect(function()
      local rr, ee = api("CloudDelete", { id = p.id })
      if ee then say(ee, true) else say("Cópia excluída.") end
      openCloudPanel()
    end)
  end
end

-- ---------- DADOS (custom DataStore) ----------
openDataPanel = function()
  local r, err = api("DataList")
  if err then say(err, true) return end
  local entries = (r.result and r.result.entries) or {}
  local d, body = modalDialog("Gerenciador de Dados", 640, 540)
  rowLabel(body, "Chave", 0, 8, 100, 15)
  local kIn = input(body, "Key", 0, 30, 220, "Ex: Coins")
  rowLabel(body, "Valor", 236, 8, 100, 15)
  local vIn = input(body, "Value", 236, 30, 240, "Valor")
  rowLabel(body, "Tipo", 492, 8, 60, 15)
  local typ = "string"
  local typeBtn = actionBtn(body, 492, 30, 60, 34, typ, m.purple)
  typeBtn.Activated:Connect(function() typ = typ == "string" and "number" or (typ == "number" and "boolean" or "string") typeBtn.Text = typ end)
  local addBtn = actionBtn(body, 0, 74, 796, 34, "Adicionar dado", m.blue)
  addBtn.Activated:Connect(function()
    local val = vIn.Text
    if typ == "number" then val = tonumber(val) end
    if typ == "boolean" then val = val == "true" or val == "1" end
    local rr, ee = api("DataSet", { key = kIn.Text, value = val, type = typ })
    if ee then say("Dados: " .. ee, true) else say("Dado '" .. kIn.Text .. "' salvo.") end
    openDataPanel()
  end)
  local list = scrollList(body, 0, 122, 620, 360)
  if #entries == 0 then
    label("Empty", list, "(nenhum dado salvo — adicione acima)", UDim2.fromOffset(10, 10), UDim2.fromOffset(500, 24), 14, m.muted)
    return
  end
  for idx, e in ipairs(entries) do
    local c = card(list, idx, 54)
    label("K", c, e.key, 16, 10, 200, 22, 17, m.cyan)
    label("T", c, "[" .. e.type .. "]", 220, 12, 90, 20, 13, m.purple)
    label("V", c, tostring(e.value), 320, 12, 220, 22, 16, m.text)
    local del = button("Del", c, UDim2.new(1, -84, 0, 12), UDim2.fromOffset(70, 30), "Excluir", m.error)
    del.TextSize = 13
    del.ZIndex = 44
    del.Activated:Connect(function()
      local rr, ee = api("DataDelete", { key = e.key })
      if ee then say(ee, true) else say("Dado '" .. e.key .. "' excluído.") end
      openDataPanel()
    end)
  end
end

-- ---------- TOOLBOX (biblioteca de templates) ----------
openToolboxPanel = function()
  local r, err = api("ToolboxList")
  if err then say(err, true) return end
  local cats = (r.result and r.result.categories) or {}
  local d, body = modalDialog("Toolbox — Biblioteca", 660, 560)
  label("Hint", body, "Clique num template para inserir no lugar selecionado (ou no Workspace). Tudo é desfazível.", 0, 8, 620, 20, 14, m.muted, true)
  local list = scrollList(body, 0, 34, 620, 470)
  local order = 0
  for _, cat in ipairs(cats) do
    order = order + 1
    local hdr = card(list, order, 34)
    label("H", hdr, cat.category, 16, 6, 400, 22, 16, m.gold)
    for _, it in ipairs(cat.items) do
      order = order + 1
      local c = card(list, order, 58)
      local icon = frame("Icon", c, UDim2.fromOffset(12, 14), UDim2.fromOffset(30, 30), m.blue, 0)
      corner(icon, 6)
      label("N", c, it.name, 56, 8, 260, 22, 16, m.text)
      label("D", c, it.description, 56, 32, 320, 18, 12, m.muted)
      local ins = actionBtn(c, 420, 12, 120, 32, "Inserir", m.blue)
      ins.Activated:Connect(function()
        local st = state()
        local rr, ee = api("ToolboxInsert", { id = it.id, parentId = st.selectedId or st.workspaceId })
        if ee then say("Toolbox: " .. ee, true) else say("Template '" .. it.name .. "' inserido (" .. tostring(rr.count) .. " objetos).") end
        closeCurrentPanel()
      end)
    end
  end
end

-- ---------- COLABORAÇÃO (equipe + convites) ----------
openCollaborationPanel = function()
  -- PAINEL COLABORAÇÃO — redesenhado (3 colunas limpas, sem sobreposição):
  --   [EQUIPE] [CONVITES] [COMO FUNCIONA + NOVO]
  local t, te = api("TeamInfo")
  local inv, ie = api("InviteList")
  local d, body = modalDialog("Colaboração", 700, 540)
  local members = (t and t.result and t.result.members) or {}
  local invites = (inv and inv.result and inv.result.invites) or {}

  local function colFrame(x, wCol, title, accent)
    local f2 = frame("Col", body, UDim2.fromOffset(x, 8), UDim2.fromOffset(wCol, 500), m.panel, 0)
    f2.ZIndex = 42
    corner(f2, 10)
    stroke(f2, accent or m.border, 1.2)
    local hd = frame("Hd", f2, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 30), accent or m.section, 0.25)
    hd.ZIndex = 43
    corner(hd, 10)
    local t2 = label("T", hd, "  " .. title, 8, 5, wCol - 16, 20, 15, m.text)
    t2.Font = Enum.Font.GothamBold
    return f2
  end

  -- COL 1: EQUIPE (membros reais do place, com online + papel)
  local c1 = colFrame(0, 336, "EQUIPE — " .. #members .. " membro(s)", m.cyan)
  local tlist = scrollList(c1, 8, 38, 320, 380)
  if #members == 0 then
    label("E0", tlist, "(só você por enquanto)", UDim2.fromOffset(10, 8), UDim2.fromOffset(300, 20), 13, m.muted)
  end
  for idx, mbr in ipairs(members) do
    local c = card(tlist, idx, 46)
    local dot = frame("Dot", c, UDim2.fromOffset(10, 10), UDim2.fromOffset(10, 10), mbr.online and m.cyan or m.muted, 0)
    corner(dot, 5)
    label("N", c, mbr.name, 30, 4, 210, 18, 15, m.text)
    label("R", c, mbr.role, 30, 24, 210, 16, 12, m.purple)
    if mbr.role ~= "Owner" then
      local del = button("Del", c, UDim2.new(1, -70, 0, 10), UDim2.fromOffset(64, 24), "Remover", m.error)
      del.TextSize = 11
      del.ZIndex = 46
      del.Activated:Connect(function()
        local rr, ee = api("TeamRemove", { name = mbr.name })
        if ee then say(ee, true) else say("Membro removido.") end
        openCollaborationPanel()
      end)
    end
  end
  local onlineTxt = "custom: persiste no place (ServerStorage), nao usa API externa"
  label("Foot", c1, onlineTxt, 10, 424, 316, 13, m.muted)

  -- COL 2: CONVITES (pendentes + aceitar)
  local c2 = colFrame(344, 336 - 8, "CONVITES — " .. #invites, m.gold)
  local ilist = scrollList(c2, 8, 38, 312, 300)
  if #invites == 0 then
    label("E1", ilist, "(nenhum convite gerado)", UDim2.fromOffset(10, 8), UDim2.fromOffset(290, 20), 13, m.muted)
  end
  for idx, iv in ipairs(invites) do
    local c = card(ilist, idx, 56)
    label("C", c, iv.code, 10, 6, 200, 18, 14, m.gold)
    label("E", c, (iv.email or "") .. " · " .. (iv.status or "pendente"), 10, 26, 250, 16, 11, m.muted)
    label("R", c, iv.role, 10, 42, 120, 12, 10, m.purple)
    if iv.status == "pending" then
      local acc = button("Acc", c, UDim2.new(1, -86, 0, 8), UDim2.fromOffset(78, 20), "Aceitar", m.blue)
      acc.TextSize = 11
      acc.ZIndex = 46
      acc.Activated:Connect(function()
        local rr, ee = api("InviteAccept", { code = iv.code })
        if ee then say(ee, true) else say("Convite aceito: @?" .. " entrou na equipe.") end
        openCollaborationPanel()
      end)
    end
  end
  rowLabel(c2, "Novo convite", 10, 348, 150, 13)
  local ieIn = input(c2, "IEmail", 10, 368, 200, "email@dev.com")
  local iRole = "Editor"
  local iRoleBtn = actionBtn(c2, 218, 368, 110, 30, "papel: " .. iRole, m.purple)
  iRoleBtn.TextSize = 11
  iRoleBtn.Activated:Connect(function()
    iRole = (iRole == "Editor") and "Viewer" or "Editor"
    iRoleBtn.Text = "papel: " .. iRole
  end)
  local icBtn = actionBtn(c2, 218, 404, 110, 30, "Gerar convite", m.gold)
  icBtn.TextSize = 11
  icBtn.Activated:Connect(function()
    local rr, ee = api("InviteCreate", { email = ieIn.Text, role = iRole })
    if ee then say(ee, true) else say("Convite criado para " .. ieIn.Text) end
    openCollaborationPanel()
  end)
  label("Foot2", c2, "código do convite = link pra entrar na equipe", 10, 440, 300, 13, m.muted)

  -- adicionar membro direto (em cima de EQUIPE)
  rowLabel(c1, "Adicionar membro (email + papel)", 10, 348, 220, 13)
  local eIn2 = input(c1, "Email", 10, 368, 200, "email@dev.com")
  local role2 = "Editor"
  local roleBtn2 = actionBtn(c1, 218, 368, 110, 30, "papel: " .. role2, m.purple)
  roleBtn2.TextSize = 11
  roleBtn2.Activated:Connect(function()
    role2 = (role2 == "Editor") and "Viewer" or "Editor"
    roleBtn2.Text = "papel: " .. role2
  end)
  local addM2 = actionBtn(c1, 218, 404, 110, 30, "Adicionar", m.blue)
  addM2.TextSize = 11
  addM2.Activated:Connect(function()
    local rr, ee = api("TeamAdd", { name = eIn2.Text, role = role2 })
    if ee then say(ee, true) else say("Membro '" .. eIn2.Text .. "' adicionado.") end
    openCollaborationPanel()
  end)
end

-- ---------- PLACES DO PERFIL (criar places novas de verdade) ----------
local function openPlacesPanel()
  local pl, pe = api("ProfileList")
  local d, body = modalDialog("Places do meu perfil", 680, 520)
  local games = (pl and pl.result and pl.result.games) or {}
  label("T", body, "JOGOS/PLACES PUBLICADOS — " .. #games, 0, 8, 400, 18, 14, m.cyan, true)
  local glist = scrollList(body, 0, 34, 660, 300)
  if #games == 0 then
    label("E", glist, "(nenhum jogo publicado ainda — use Game > Publicar)", UDim2.fromOffset(10, 8), UDim2.fromOffset(600, 20), 13, m.muted)
  end
  for idx, g in ipairs(games) do
    local c = card(glist, idx, 54)
    label("N", c, g.name or ("place " .. tostring(g.id)), 12, 6, 300, 20, 15, m.text)
    label("D", c, (g.url or ("roblox.com/games/" .. tostring(g.placeId or g.id))) .. " · v" .. tostring(g.version or 1) .. " · " .. tostring(g.visits or 0) .. " visitas", 12, 28, 460, 18, 12, m.muted)
    label("V", c, (g.visibility or "public"), 480, 6, 120, 18, 11, g.visibility == "private" and m.muted or m.cyan)
    local del = button("Del", c, UDim2.new(1, -70, 0, 12), UDim2.fromOffset(62, 24), "Excluir", m.error)
    del.TextSize = 11
    del.ZIndex = 46
    del.Activated:Connect(function()
      local rr, ee = api("ProfileDelete", { id = g.id })
      if ee then say(ee, true) else say("Jogo removido do perfil.") end
      openPlacesPanel()
    end)
  end
  -- NOVA PLACE NO PERFIL (AssetService.CreatePlaceAsync — REAL)
  label("T2", body, "CRIAR PLACE NOVA NO PERFIL (AssetService.CreatePlaceAsync — cria de VERDADE)", 0, 348, 660, 16, 13, m.gold, true)
  local nmIn = input(body, "Nm", 0, 372, 220, "Minha place nova")
  local tpIn = input(body, "Tp", 228, 372, 150, "templateId (vazio = baseplate)")
  label("TpL", body, "template opcional", 228, 396, 200, 12, 10, m.muted)
  local dsIn = input(body, "Ds", 386, 372, 274, "descrição da place")
  local cre = actionBtn(body, 0, 420, 200, 34, "CRIAR NO PERFIL", m.gold)
  cre.Activated:Connect(function()
    local tpl = tonumber(tpIn.Text)
    local rr, ee2 = api("PlaceCreate", { name = nmIn.Text, template = tpl, description = dsIn.Text })
    if ee2 then say("Criar place: " .. ee2, true)
    elseif rr and rr.result and rr.result.error then say(rr.result.error, true)
    elseif rr and rr.result then
      say(rr.result.msg or "Place criada!")
      openPlacesPanel()
    end
  end)
  label("Hint", body, "Só funciona em jogo ONLINE publicado com permissão de criar places ativa. Se recusar, o texto explica exatamente o porquê.", 0, 462, 660, 30, 11, m.muted)
end
-- ---------- LOCALIZAÇÃO (i18n) ----------
openLocalizationPanel = function()
  local loc, le = api("Locales")
  local s, se = api("LocStrings")
  local lr = (loc and loc.result) or {}
  local sr = (s and s.result) or {}
  local d, body = modalDialog("Localização / Tradução", 680, 560)
  rowLabel(body, "Idioma ativo", 0, 8, 140, 14)
  local order = 0
  local bx = 0
  for _, l in ipairs(lr.available or {}) do
    order = order + 1
    local active = (l.code == lr.current)
    local b = actionBtn(body, bx, 30, 96, 32, l.name, active and m.cyan or m.blue)
    b.TextSize = 13
    b.Activated:Connect(function()
      local rr, ee = api("SetLocale", { code = l.code })
      if ee then say(ee, true) else say("Idioma: " .. l.name) end
      openLocalizationPanel()
    end)
    bx = bx + 104
  end
  local strings = sr.strings or {}
  local list = scrollList(body, 0, 78, 640, 300)
  for idx, st in ipairs(strings) do
    local c = card(list, idx, 52)
    label("K", c, st.key, 12, 8, 150, 20, 14, m.cyan)
    label("V", c, st.value, 170, 8, 260, 20, 15, m.text)
    label("R", c, "[" .. (lr.current or "pt-BR") .. "] " .. (st.resolved or st.value), 170, 30, 400, 18, 12, m.gold)
  end
  rowLabel(body, "Nova tradução (chave + valor + en/es)", 0, 392, 300, 14)
  local kIn = input(body, "K", 0, 414, 150, "chave")
  local vIn = input(body, "V", 158, 414, 180, "valor pt-BR")
  local enIn = input(body, "E", 346, 414, 140, "en")
  local esIn = input(body, "E2", 494, 414, 100, "es")
  local addS = actionBtn(body, 494, 456, 140, 34, "Adicionar", m.blue)
  addS.Activated:Connect(function()
    local rr, ee = api("SetLocString", { key = kIn.Text, value = vIn.Text, translations = { en = enIn.Text, es = esIn.Text } })
    if ee then say(ee, true) else say("Tradução '" .. kIn.Text .. "' salva.") end
    openLocalizationPanel()
  end)
end

-- ---------- CONFIGURAÇÕES DO PROJETO (completas) ----------
openProjectSettingsPanel = function()
  local pi = api("ProjectInfo")
  local info = (pi and pi.result and pi.result.info) or {}
  local d, body = modalDialog("Configurações do Projeto", 660, 560)
  rowLabel(body, "Nome do jogo", 0, 10, 160, 15)
  local nameIn = input(body, "Name", 0, 32, 300, (info.GameName or ""))
  rowLabel(body, "Gênero", 320, 10, 120, 15)
  local genreIn = input(body, "Genre", 320, 32, 180, (info.Genre or ""))
  rowLabel(body, "Visibilidade", 520, 10, 120, 15)
  local vis = info.Visibility or "Public"
  local visBtn = actionBtn(body, 520, 32, 100, 34, vis, m.purple)
  visBtn.Activated:Connect(function() vis = vis == "Public" and "Unlisted" or (vis == "Unlisted" and "Private" or "Public") visBtn.Text = vis end)
  rowLabel(body, "Máx. de jogadores", 0, 80, 200, 15)
  local maxIn = input(body, "Max", 0, 102, 120, tostring(info.MaxPlayers or 50))
  rowLabel(body, "Descrição", 0, 150, 160, 15)
  local descIn = input(body, "Desc", 0, 172, 620, (info.Description or ""))
  -- mundo (workspace/lighting) via Set
  local wsId = state().workspaceId
  local gravity = 196.2
  local rr = api("Select", { id = wsId })
  if rr and rr.properties and rr.properties.fields then
    for _, f in ipairs(rr.properties.fields) do if f.key == "Gravity" then gravity = f.value end end
  end
  rowLabel(body, "Gravidade (Workspace)", 0, 224, 220, 15)
  local gIn = input(body, "Grav", 0, 246, 120, tostring(gravity))
  local saveBtn = actionBtn(body, 0, 292, 300, 36, "Salvar configurações", m.blue)
  saveBtn.Activated:Connect(function()
    local r1, e1 = api("SetProjectInfo", { GameName = nameIn.Text, Description = descIn.Text, Genre = genreIn.Text, Visibility = vis, MaxPlayers = maxIn.Text })
    if e1 then say(e1, true) return end
    local gv = tonumber(gIn.Text)
    if gv then local r2, e2 = api("Set", { id = wsId, key = "Gravity", value = math.clamp(gv, 0, 10000) })
      if e2 then say(e2, true) end
    end
    say("Configurações do projeto salvas.")
    closeCurrentPanel()
  end)
  label("Hint", body, "Os dados do projeto persistem no place (caminho custom). Gravidade aplica na hora e é desfazível.", 320, 224, 300, 60, 13, m.muted, true)
end

-- ---------- PLUGINS (PluginToolbar) ----------
openPluginsPanel = function()
  local d, body = modalDialog("Central de Plugins", 620, 520)
  label("Hint", body, "Sistemas integrados do Arkher Studio (todos operacionais e persistidos no place).", 0, 8, 560, 20, 14, m.muted, true)
  local plugins = {
    { name = "Arkher Cloud", desc = "Cópias de projeto na nuvem (custom).", icon = m.blue, act = function() openCloudPanel() end },
    { name = "Publicar no perfil do dev", desc = "Página de jogo estilo Roblox.", icon = m.gold, act = function() openPublishDialog() end },
    { name = "Gerenciador de Dados", desc = "DataStore custom (chave/valor).", icon = m.cyan, act = function() openDataPanel() end },
    { name = "Toolbox", desc = "Biblioteca de templates prontos.", icon = m.purple, act = function() openToolboxPanel() end },
    { name = "Localização", desc = "Tradução em 6 idiomas.", icon = m.green or m.blue, act = function() openLocalizationPanel() end },
    { name = "Colaboração", desc = "Equipe + convites.", icon = m.blue, act = function() openCollaborationPanel() end },
  }
  local list = scrollList(body, 0, 34, 580, 440)
  for idx, p in ipairs(plugins) do
    local c = card(list, idx, 60)
    local ic = frame("Icon", c, UDim2.fromOffset(12, 15), UDim2.fromOffset(30, 30), p.icon, 0)
    corner(ic, 6)
    label("N", c, p.name, 56, 8, 320, 22, 16, m.text)
    label("D", c, p.desc, 56, 32, 340, 18, 12, m.muted)
    local openB = actionBtn(c, 440, 14, 100, 32, "Abrir", m.blue)
    openB.Activated:Connect(p.act)
  end
end

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
  elseif action == "OpenData" then
    openDataPanel()
    return true
  elseif action == "OpenToolbox" then
    openToolboxPanel()
    return true
  elseif action == "OpenCloud" then
    openCloudPanel()
    return true
  elseif action == "OpenCollaboration" then
    openCollaborationPanel()
    return true
  elseif action == "OpenLocalization" then
    openLocalizationPanel()
    return true
  elseif action == "OpenProjectSettings" then
    openProjectSettingsPanel()
    return true
  elseif action == "OpenPlugins" then
    openPluginsPanel()
    return true
  elseif action == "OpenPublish" then
    openPublishDialog()
    return true
  elseif action == "MUNDO" then
    buildMenu("MUNDO", payload and payload.button)
    return true
  elseif action == "MODELAGEM" then
    buildMenu("MODELAGEM", payload and payload.button)
    return true
  elseif action == "ANIMACAO" then
    buildMenu("ANIMACAO", payload and payload.button)
    return true
  elseif action == "ESPACO" then
    buildMenu("ESPACO", payload and payload.button)
    return true
  elseif action == "FABRICAR" then
    buildMenu("FABRICAR", payload and payload.button)
    return true
  elseif action == "AGUA" then
    buildMenu("AGUA", payload and payload.button)
    return true
  elseif action == "ATMOS" then
    buildMenu("ATMOS", payload and payload.button)
    return true
  elseif action == "CLIMA" then
    buildMenu("CLIMA", payload and payload.button)
    return true
  elseif action == "VIDA" then
    buildMenu("VIDA", payload and payload.button)
    return true
  elseif action == "CIDADE" then
    buildMenu("CIDADE", payload and payload.button)
    return true
  elseif action == "AUDIO" then
    buildMenu("AUDIO", payload and payload.button)
    return true
  elseif action == "FX" then
    buildMenu("FX", payload and payload.button)
    return true
  elseif action == "CORDAS" then
    buildMenu("CORDAS", payload and payload.button)
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


-- =============================================================
-- MENUS X (ADITIVO) — os editores unicos do ARKHER na topbar
-- original. Cada menu abre uma UI DEDICADA (TERRAIN / MODELER
-- Blender / ANIMATOR Cascadeur / ESPAÇO / FABRICAR). RRW/D-O15/
-- Tese dos D ficam no backend invisível; aqui é 100% DEV.
-- =============================================================

MENUS.MUNDO = {
  { icon = "Part", label = "Editor TERRAIN X (abrir)", act = "XOpenTerrain" },
  { sep = true },
  { icon = "plus", label = "Gerar planeta (sócio tectônico)…", act = "XOpenTerrainGen" },
  { icon = "Data", label = "Sonda do mundo (bioma/clima/matéria)", act = "XOpenTerrainProbe" },
}
MENUS.MODELAGEM = {
  { icon = "Model", label = "Modeler X (abrir, estilo Blender)", act = "XOpenModeler" },
  { sep = true },
  { icon = "plus", label = "Nova primitiva na banca…", act = "XOpenModelerPrim" },
}
MENUS.ANIMACAO = {
  { icon = "Play", label = "Animator X (abrir, estilo Cascadeur)", act = "XOpenAnimator" },
  { sep = true },
  { icon = "Players", label = "AutoRig (esqueletos)…", act = "XOpenAnimatorRig" },
  { icon = "Settings", label = "AutoPhysics 0→1…", act = "XOpenAnimatorPhys" },
}
MENUS.ESPACO = {
  { icon = "expand", label = "Editor de ESPAÇO (abrir)", act = "XOpenEspaco" },
  { sep = true },
  { icon = "plus", label = "Preset: Sistema Solar (log)", act = "XEspacoSolar" },
  { icon = "plus", label = "Preset: Terra + Lua + Sol", act = "XEspacoTerraLua" },
}
MENUS.FABRICAR = {
  { icon = "plus", label = "Fabricator X (abrir catálogo)", act = "XOpenFabricar" },
  { sep = true },
  { icon = "Folder", label = "Listar classes da gramática", act = "XFabricarList" },
}

MENUS.AGUA = {
  { icon = "Part", label = "Editor WATER X (abrir)", act = "XOpenWater" },
  { sep = true },
  { icon = "plus", label = "Criar Oceano (água de VERDADE)", act = "XAguaOceano" },
  { icon = "Players", label = "Teste de Arquimedes (6 densidades reais)", act = "XAguaFlutua" },
}

MENUS.ATMOS = {
  { icon = "plus", label = "ATMOS X (abrir céu/clima)", act = "XOpenAtmos" },
  { sep = true },
  { icon = "Settings", label = "Horário do sol (Kelvin real)…", act = "XAtmosCeu" },
  { icon = "Data", label = "Estado do tempo…", act = "XAtmosTempo" },
}
MENUS.CLIMA = {
  { icon = "plus", label = "CLIMA X — frentes (abrir)", act = "XOpenClima" },
  { sep = true },
  { icon = "Play", label = "Ligar frentes H/L (vivas)", act = "XClimaOn" },
  { icon = "Flag", label = "Parar frentes", act = "XClimaOff" },
}
MENUS.VIDA = {
  { icon = "plus", label = "VIDA X (abrir)", act = "XOpenVida" },
  { sep = true },
  { icon = "Players", label = "Humano digital (DAYX)…", act = "XVidaHumano" },
  { icon = "Players", label = "NPC bípede (FABRIK+mente)", act = "XVidaNpc" },
  { icon = "Data", label = "Ligar ecossistema…", act = "XVidaEco" },
}
MENUS.CIDADE = {
  { icon = "plus", label = "CIDADE X (abrir)", act = "XOpenCidade" },
  { sep = true },
  { icon = "Folder", label = "Construir VILA (seed)", act = "XCidadeVila" },
  { icon = "Model", label = "Construir METRÓPOLE (seed)", act = "XCidadeMetro" },
}
MENUS.AUDIO = {
  { icon = "plus", label = "ÁUDIO X — mixer (abrir)", act = "XOpenAudio" },
  { sep = true },
  { icon = "Settings", label = "Buses do mundo (7)…", act = "XAudioMixer" },
  { icon = "Data", label = "Intensidade musical…", act = "XAudioInt" },
}
MENUS.FX = {
  { icon = "plus", label = "FX X — partículas (abrir)", act = "XOpenFx" },
  { sep = true },
  { icon = "plus", label = "Fogo (emitir)", act = "XFxFogo" },
  { icon = "plus", label = "Chuva (emitir)", act = "XFxChuva" },
}
MENUS.PART = {
  { head = "formas basicas" },
  { icon = "Part", label = "Spawnar ▸", key = "▸", tip = "Escolha a FORMA real (Shape do engine, nao visual), nasce em (0,3,-16) e vira selecao", sub = {
    { icon = "Part", label = "Block (4×2×4)", act = "XSpawnBlock", tip = "Part com Shape=Block — a peca clasica do Roblox" },
    { icon = "Part", label = "Ball (esfera)", act = "XSpawnBall", tip = "Shape=Ball: esfera perfeita para bolas, planetinhas, roda" },
    { icon = "Part", label = "Cylinder (cilindro p/ roda)", act = "XSpawnCyl", tip = "Shape=Cylinder: cilindro de lado (Ideal rodas/eixos)" },
    { icon = "Part", label = "CylinderVertical (em pe)", act = "XSpawnCylV", tip = "Shape=CylinderVertical: cilindro em pe (colunas/pilares)" },
  } },
  { head = "formas especiais (classe propria)" },
  { icon = "Part", label = "Wedge (rampa)", act = "XSpawnWedge", tip = "WedgePart: rampa/helder o classico — sempre 1/2 do bloco" },
  { icon = "Part", label = "CornerWedge (rampa de canto)", act = "XSpawnCorner", tip = "CornerWedgePart: rampa de 45 graus nos cantos" },
  { icon = "Part", label = "Truss (estrutura escalavel)", act = "XSpawnTruss", tip = "TrussPart: escada trelica tipo andaime" },
  { sep = true },
  { icon = "plus", label = "Inserir outra classe…", act = "InsertFull", tip = "Abre o INSERIR completo (hierarchy picker) com TODAS as classes" },
}
MENUS.TOOLBX = {
  { icon = "Folder", label = "TOOLBOX X (abrir loja real)", act = "XOpenToolbox", tip = "Busca na Creator Store REAL do Roblox + templates Arkher; clique INSERE no mundo" },
  { sep = true },
  { icon = "plus", label = "Buscar modelos…", act = "XOpenToolbox", tip = "Modelos gratuitos publicados pela comunidade Roblox" },
  { icon = "Data", label = "Templates Arkher", act = "XToolboxArkher", tip = "Plataforma/Muralha/Ponte/Luzes/Moeda etc — inserta e automatiza pros motores X" },
}
MENUS.PROPS = {
  { icon = "Settings", label = "PROPS X — TODAS (abrir)", act = "XOpenProps", tip = "TODAS as propriedades do objeto selecionado — string/numero/bool/vetor/cor/enum TODAS editaveis" },
  { sep = true },
  { icon = "Players", label = "Ver seleção atual", act = "XPropsTarget", tip = "Mostra o que o PROPS esta editando agora" },
}
MENUS.CORES = {
  { icon = "Settings", label = "CORES X (abrir picker)", act = "XOpenCores", tip = "Color picker REAL (HSV/RGB/hex) que aplica de VERDADE na propriedade de cor do selecionado" },
}
MENUS.OUTPUT = {
  { icon = "Data", label = "OUTPUT X (abrir log)", act = "XOpenOutput", tip = "O log REAL do Output (LogService) — todos os prints/warns/erros com filtros" },
  { sep = true },
  { icon = "Flag", label = "Limpar Output", act = "XOutputClear", tip = "Limpa a janela Output oficial (mesmo botao do Roblox Studio)" },
}
MENUS.COMANDO = {
  { icon = "Flag", label = "COMANDO X (abrir barra)", act = "XOpenComando", tip = "Barra de comandos QUE EXECUTA DE VERDADE — spawn/set/cmd/math/help da Arkher" },
  { sep = true },
  { icon = "Data", label = "Ajuda de comandos", act = "XComandoHelp", tip = "Lista tudo que a barra sabe fazer" },
}

MENUS.SCRIPTSX = {
  { icon = "Script", label = "SCRIPTS X (abrir editor)", act = "XOpenScripts", tip = "Editor POTENTE: abas por script, buscar/substituir, Source LIDO e APLICADO de verdade" },
  { sep = true },
  { icon = "plus", label = "Novo Script em ServerScriptService", act = "InsertScript", tip = "Cria um Script novo (via inserir nativo)" },
}
MENUS.PYTHONX = {
  { icon = "Data", label = "PY X (abrir ponte)", act = "XOpenPy", tip = "Conecta no python/pybridge.py do seu PC — roda TESTES/BUILD/AUDITORIA/SHELL de verdade e mostra a saída" },
}

MENUS.CORDAS = {
  { icon = "plus", label = "CORDAS X — Verlet (abrir)", act = "XOpenCordas" },
  { sep = true },
  { icon = "plus", label = "Ponte de corda (demo físico)", act = "XCordaDemo" },
  { icon = "Flag", label = "Ponte pênsil…", act = "XCordaPonte" },
}

local function deckOpen(id, view)
  local d = rawget(_G, "ArkherDeck")
  if d and d.open then return d.open(id, view) end
  say("Deck X ainda carregando… tente de novo em 2s.", true)
end
local function deckCmd(op, params)
  local d = rawget(_G, "ArkherDeck")
  if d and d.cmd then return d.cmd(op, params) end
  say("Deck X indisponível p/ backend.", true)
end

actions.XOpenTerrain      = function() deckOpen("terrain", "ferramentas") end
actions.XOpenTerrainGen   = function() deckOpen("terrain", "gerar") end
actions.XOpenTerrainProbe = function() deckOpen("terrain", "sonda") end
actions.XOpenModeler      = function() deckOpen("modeler", "gerar") end
actions.XOpenModelerPrim  = function() deckOpen("modeler", "gerar") end
actions.XOpenAnimator     = function() deckOpen("animator", "palco") end
actions.XOpenAnimatorRig  = function() deckOpen("animator", "rigs") end
actions.XOpenAnimatorPhys = function() deckOpen("animator", "physics") end
actions.XOpenEspaco       = function() deckOpen("espaco", "sistema") end
actions.XOpenFabricar     = function() deckOpen("fabricar", "catalogo") end
actions.XEspacoSolar      = function() deckCmd("space_preset", { id = "solar" }) deckOpen("espaco", "sistema") end
actions.XEspacoTerraLua   = function() deckCmd("space_preset", { id = "terra_lua" }) deckOpen("espaco", "sistema") end
actions.XFabricarList     = function() deckOpen("fabricar", "catalogo") end
actions.XOpenWater        = function() deckOpen("water", "corpos") end
actions.XAguaOceano       = function() deckCmd("water_create", { kind = "oceano", preset = "porto", level = 8, size = 512 }) deckOpen("water", "corpos") end
actions.XAguaFlutua       = function() deckCmd("water_float_test", {}) deckOpen("water", "fisica") end
actions.XOpenAtmos        = function() deckOpen("atmos", "ceu") end
actions.XAtmosCeu         = function() deckOpen("atmos", "ceu") end
actions.XAtmosTempo       = function() deckOpen("atmos", "tempo") end
actions.XOpenClima        = function() deckOpen("clima", "frentes") end
actions.XClimaOn          = function() deckCmd("fronts_on", {}) deckOpen("clima", "mapa") end
actions.XClimaOff         = function() deckCmd("wea_off", {}) end
actions.XOpenVida         = function() deckOpen("vida", "seres") end
actions.XVidaHumano       = function() deckCmd("life_human", { seed = 7 }) deckOpen("vida", "humano") end
actions.XVidaNpc          = function() deckCmd("npc_spawn", { preset = "bipede" }) deckOpen("vida", "npc") end
actions.XVidaEco          = function() deckCmd("eco_start", {}) deckOpen("vida", "eco") end
actions.XOpenCidade       = function() deckOpen("cidade", "construir") end
actions.XCidadeVila       = function() deckCmd("civ_fabricate", { kind = "vila", seed = 7 }) deckOpen("cidade", "log") end
actions.XCidadeMetro      = function() deckCmd("civ_fabricate", { kind = "metropole", seed = 11 }) deckOpen("cidade", "log") end
actions.XOpenAudio        = function() deckOpen("audio", "mixer") end
actions.XAudioMixer       = function() deckOpen("audio", "mixer") end
actions.XAudioInt         = function() deckOpen("audio", "intensidade") end
actions.XOpenFx           = function() deckOpen("fx", "presets") end
actions.XFxFogo           = function() deckCmd("fx_emit", { kind = "fogo" }) deckOpen("fx", "log") end
actions.XFxChuva          = function() deckCmd("fx_emit", { kind = "chuva" }) deckOpen("fx", "log") end
actions.XOpenCordas       = function() deckOpen("cordas", "demos") end
local function spawnShape(shape)
  local r, err = api("QuickPart", { shape = shape })
  if err then say("Spawn " .. shape .. ": " .. err, true)
  else say(r.result and r.result.msg or (shape .. " criado.")) end
end
actions.XSpawnBlock       = function() spawnShape("Block") end
actions.XSpawnBall        = function() spawnShape("Ball") end
actions.XSpawnCyl         = function() spawnShape("Cylinder") end
actions.XSpawnCylV        = function() spawnShape("CylinderVertical") end
actions.XSpawnWedge       = function() spawnShape("Wedge") end
actions.XSpawnCorner      = function() spawnShape("CornerWedge") end
actions.XSpawnTruss       = function() spawnShape("Truss") end
actions.XOpenToolbox      = function() deckOpen("toolbox", "loja") end
actions.XToolboxArkher    = function() deckOpen("toolbox", "arkher") end
actions.XOpenProps        = function() deckOpen("props", nil) end
actions.XPropsTarget      = function() deckOpen("props", nil) end
actions.XOpenCores        = function() deckOpen("cores", nil) end
actions.XOpenOutput       = function() deckOpen("output", nil) end
actions.XOutputClear      = function() deckOpen("output", nil) say("Abra OUTPUT X e clique em LIMPAR (botão real, LogService.ClearOutput).") end
actions.XOpenComando      = function() deckOpen("comando", nil) end
actions.XComandoHelp      = function() deckOpen("comando", "ajuda") end
actions.XOpenScripts      = function() deckOpen("scripts", nil) end
actions.XOpenPy           = function() deckOpen("py", nil) end
actions.XCordaDemo        = function() deckCmd("rope_demo", {}) deckOpen("cordas", "demos") end
actions.XCordaPonte       = function() deckOpen("cordas", "ponte") end

-- ---- botoes na MenuRow da topbar ORIGINAL (clona estilo do irmao) ----
do
  local weekdayALvo = { "MUNDO", "AGUA", "MODELAGEM", "ANIMACAO", "ESPACO", "FABRICAR" }
  local function findBtn(nm)
    for _, c in ipairs(g:GetDescendants()) do
      if c:IsA("GuiButton") and c.Name == nm then return c end
    end
    return nil
  end
  local ref = findBtn("View") or findBtn("Game") or findBtn("Insert")
  if ref and ref.Parent then
    local row = ref.Parent
    local byName = {}
    for _, c in ipairs(row:GetChildren()) do
      if c:IsA("GuiButton") then byName[c.Name] = true end
    end
    for i, nm in ipairs(weekdayALvo) do
      if not byName[nm] then
        local b0 = ref:Clone()
        b0.Name = nm
        b0.Text = (nm == "ANIMACAO") and "ANIMAÇÃO" or (nm == "FABRICAR" and "FABRICAR" or nm)
        b0.Parent = row
        pcall(function() b0.LayoutOrder = 100 + i end) -- DEPOIS do GAME
        b0.Activated:Connect(function()
          W(nm, { button = b0 })
        end)
      end
    end
    print("[ArkherX] Menus X na topbar original: MUNDO / ÁGUA / MODELAGEM / ANIMAÇÃO / ESPAÇO / FABRICAR")
  else
    warn("[ArkherX] MenuRow não achada — menus X vivem só via MenusBus")
  end
end


-- =============================================================
-- X-TIER REMOVIDO: os 19+2 mini-botões "View" clonados foram a
-- abordagem errada — o usuário mostrou que a TOPBAR é a faixa de
-- ÍCONES original (Ribbon) e pediu ABAS. Quem faz isso agora e o
-- 09_Topbar (abas estilo Roblox: aba -> pagina de botoes com icones
-- DESENHADOS). Este stub fica apenas para marcar a decisao.
-- =============================================================
print("[ArkherX] X-tier desativado: topbar com ABAS agora e do 09_Topbar (aba HOME = ribbon original)")
