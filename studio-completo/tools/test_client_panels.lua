-- Teste de UI dos PAINÉIS DE SISTEMAS (03_Menus) + server, no mesmo runtime.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
	if cond then pass = pass + 1 print("  OK  " .. msg)
	else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
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
script = Instance.new("LocalScript"); script.Name = "Arkher_03_Menus"; script.Parent = gui

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function serverInvoke(action, payload) return rawget(request, "__props").OnServerInvoke(tp, action, payload or {}) end

local cstate = { selectedId = nil, workspaceId = nil }
local messages = {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "ClaimPart" then return true end
	if action == "API" then
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "State" then return cstate end
	if action == "Message" then messages[#messages + 1] = { text = payload.text, bad = payload.bad } return true end
	if action == "Info" then messages[#messages + 1] = { info = payload.title } return true end
	return true
end

local msrc = io.open("studio-completo/scripts/03_Menus.lua"):read("*a")
local mfn, merr = loadstring(msrc, "[menus]")
assert(mfn, "sintaxe menus: " .. tostring(merr))
assert(pcall(mfn), "03_Menus nao executou")

local function snap() return serverInvoke("Snapshot", {}) end
local function findId(s, name) for _, n in ipairs(s.nodes) do if n.name == name then return n.id end end end
local s0 = snap()
cstate.workspaceId = findId(s0, "Workspace")

-- encontra um botao por texto (recursivo)
local function findBtn(root, text)
	for _, c in ipairs(root:GetDescendants()) do
		if c:IsA("TextButton") and c.Text and c.Text:find(text, 1, true) then return c end
	end
	return nil
end
local function hasText(root, text)
	for _, c in ipairs(root:GetDescendants()) do
		if c.Text and c.Text:find(text, 1, true) then return true end
	end
	return false
end
local function findInput(root, name)
	for _, c in ipairs(root:GetDescendants()) do
		if c:IsA("TextBox") and c.Name == name then return c end
	end
	return nil
end

-- ============ DATA ============
print("\n== Painel Dados ==")
menusBus:Invoke("OpenData")
local panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenData: painel criado")
check(panel:FindFirstChild("Body") ~= nil, "OpenData: tem Body")
local kIn = findInput(panel, "Key"); local vIn = findInput(panel, "Value")
kIn.Text = "Coins"; vIn.Text = "500"
local addBtn = findBtn(panel, "Adicionar dado")
check(addBtn ~= nil, "OpenData: botao Adicionar")
addBtn.Activated:Fire()
local dl = serverInvoke("DataList", {})
local found = false
for _, e in ipairs(dl.entries) do if e.key == "Coins" and (e.value == 500 or e.value == "500") then found = true end end
check(found, "OpenData: 'Coins=500' salvo via UI")

-- ============ TOOLBOX ============
print("\n== Painel Toolbox ==")
menusBus:Invoke("OpenToolbox")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenToolbox: painel criado")
check(hasText(panel, "Ponte"), "OpenToolbox: template Ponte listado")
-- clica no primeiro 'Inserir' da Ponte (a Ponte tem 1 botao Inserir no card dela)
local insBtn = findBtn(panel, "Inserir")
check(insBtn ~= nil, "OpenToolbox: botao Inserir")
insBtn.Activated:Fire()
local s1 = snap()
check(findId(s1, "Plataforma") ~= nil or findId(s1, "Muralha") ~= nil or findId(s1, "Ponte") ~= nil, "Toolbox: template inserido no workspace")

-- ============ CLOUD ============
print("\n== Painel Cloud ==")
menusBus:Invoke("OpenCloud")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenCloud: painel criado")
local saveB = findBtn(panel, "Salvar na Cloud")
check(saveB ~= nil, "OpenCloud: botao Salvar")
local cn = findInput(panel, "CName"); if cn then cn.Text = "SaveUI" end
saveB.Activated:Fire()
local cl = serverInvoke("CloudList", {})
check(#cl.projects == 1, "OpenCloud: 1 projeto salvo via UI")

-- ============ PUBLISH ============
print("\n== Painel Publicar ==")
menusBus:Invoke("OpenPublish")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenPublish: painel criado")
local tIn = findInput(panel, "Title")
if tIn then tIn.Text = "Jogo da UI" end
local pubB = findBtn(panel, "Publicar no Roblox")
check(pubB ~= nil, "OpenPublish: botao Publicar")
pubB.Activated:Fire()
local pl = serverInvoke("ProfileList", {})
local pubOk = false
for _, g in ipairs(pl.games) do if g.title == "Jogo da UI" then pubOk = true end end
check(pubOk, "OpenPublish: jogo 'Jogo da UI' no perfil via UI")
-- cartao do jogo aparece
panel = popups:FindFirstChild("ArkherPanel")
check(panel and (function() for _, c in ipairs(panel:GetDescendants()) do if c.Name == "GameCard" then return true end end return false end)(), "OpenPublish: cartao do jogo renderizado")

-- ============ COLABORACAO ============
print("\n== Painel Colaboracao ==")
menusBus:Invoke("OpenCollaboration")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenCollaboration: painel criado")
check(findBtn(panel, "Adicionar") ~= nil, "OpenCollaboration: botao Adicionar membro")
check(findBtn(panel, "Gerar convite") ~= nil, "OpenCollaboration: botao Gerar convite")
local ti = serverInvoke("TeamInfo", {})
check(ti.count == 1 and ti.members[1].role == "Owner", "Colaboracao: 1 owner")

-- ============ LOCALIZACAO ============
print("\n== Painel Localizacao ==")
menusBus:Invoke("OpenLocalization")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenLocalization: painel criado")
local enBtn = findBtn(panel, "English")
check(enBtn ~= nil, "OpenLocalization: seletor English")
enBtn.Activated:Fire()
local loc = serverInvoke("Locales", {})
check(loc.current == "en", "OpenLocalization: idioma trocado para en via UI")

-- ============ PROJECT SETTINGS ============
print("\n== Painel Configuracoes do Projeto ==")
menusBus:Invoke("OpenProjectSettings")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenProjectSettings: painel criado")
local saveSet = findBtn(panel, "Salvar config")
check(saveSet ~= nil, "OpenProjectSettings: botao Salvar")
local pn = findInput(panel, "Name"); if pn then pn.Text = "Projeto UI" end
saveSet.Activated:Fire()
local pi = serverInvoke("ProjectInfo", {})
check(pi.info.GameName == "Projeto UI", "OpenProjectSettings: nome do jogo salvo via UI")

-- ============ PLUGINS ============
print("\n== Painel Plugins ==")
menusBus:Invoke("OpenPlugins")
panel = popups:FindFirstChild("ArkherPanel")
check(panel ~= nil, "OpenPlugins: painel criado")
check(hasText(panel, "Arkher Cloud"), "OpenPlugins: lista sistemas")

print("\n================================")
print(string.format("PAINÉIS: %d passaram, %d falharam", pass, fail))
if fail > 0 then os.exit(1) else os.exit(0) end
