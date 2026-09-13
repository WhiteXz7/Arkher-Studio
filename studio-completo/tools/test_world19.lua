-- Testa R15b World: server World* (info/grav/spawn/save/clean/clear) + 19_World.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
	if cond then pass = pass + 1 print("  OK  " .. msg)
	else fail = fail + 1 print("  FALHOU  " .. msg) end
end

local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local shell = Instance.new("Frame"); shell.Name = "ArkherShell2"; shell.Parent = canvas
local function W(parent, cls, name, vis)
	local o = Instance.new(cls); o.Name = name
	if cls == "TextLabel" or cls == "TextButton" then o.Text = name end
	if cls == "TextButton" then o.BackgroundColor3 = Color3.new(0.1, 0.16, 0.28) end
	if vis ~= nil then o.Visible = vis end
	o.Parent = parent
	return o
end
for _, n in ipairs({ "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status", "M_WO" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail", "AN5_Rail", "UI6_Rail", "RW7_Rail", "DO8_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "WO9_Close", "WO9_I_Refresh", "WO9_G_M", "WO9_G_P", "WO9_G_Set",
	"WO9_G_Reset", "WO9_S_Prev", "WO9_S_Next", "WO9_S_Add", "WO9_S_Toggle", "WO9_S_Del",
	"WO9_V_Save", "WO9_V_Prev", "WO9_V_Next", "WO9_V_Load", "WO9_V_Del",
	"WO9_C_Fallen", "WO9_C_Loose", "WO9_C_Restore", "WO9_C_Clear",
	"M_WO_Save", "M_WO_Spawn", "M_WO_Clean" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "WO9_InfoBig", "WO9_StatL", "WO9_GV", "WO9_G_Info",
	"WO9_S_Info", "WO9_V_Info", "WO9_C_Info", "M_WO_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "WO9_V_Name")
W(shell, "TextBox", "WO9_C_Y")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_19_World"; script.Parent = gui

local ssrc = io.open("studio-completo/scripts/server.lua"):read("*a")
assert(pcall(assert(loadstring(ssrc, "[server]"))), "server nao carregou")
local RS = game:GetService("ReplicatedStorage")
local request = RS:FindFirstChild("ArkherStudioBridge"):FindFirstChild("Request")
local tp = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function serverInvoke(action, payload)
	local r = rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
	if r and r.error and r.error:find("frequ") then
		local t0 = os.clock()
		while os.clock() - t0 < 2.5 do end
		r = rawget(request, "__props").OnServerInvoke(tp, action, payload or {})
	end
	return r
end
local messages = {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "Message" then messages[#messages + 1] = payload return true end
	return true
end
local function lastMsg() return messages[#messages] and messages[#messages].text or "" end

local ws = game:GetService("Workspace")
ws:FindFirstChild("Baseplate").CFrame = CFrame.new(0, -0.5, 0)
ws.Gravity = 196.2
ws.FallenPartsDestroyHeight = -500

print("\n== WO19-S1: WorldInfo ==")
local wi = serverInvoke("WorldInfo", {})
check(wi.parts == 1, "1 part (baseplate)")
check(wi.gravity == 196.2 and wi.killY == -500, "gravity/killY")
check(wi.saves == 0 and wi.trash == 0, "saves/trash zerados")
check(wi.bounds and wi.bounds[2] == -0.5, "bounds reais (base y -0.5)")
check(wi.spawns == 0, "spawns 0")

print("\n== WO19-S2: Gravity + undo ==")
local g1 = serverInvoke("WorldGravity", { g = 50 })
check(g1.g == 50 and ws.Gravity == 50, "set 50 real")
local g2 = serverInvoke("WorldGravity", { g = 99999 })
check(g2.g == 500, "clamp 500")
serverInvoke("Undo", {})
check(ws.Gravity == 50, "Undo volta 50")
serverInvoke("Redo", {})
check(ws.Gravity == 500, "Redo reaplica 500")

print("\n== WO19-S3: Spawn CRUD ==")
check(#serverInvoke("WorldSpawn", { op = "list" }).spawns == 0, "lista vazia")
local s1 = serverInvoke("WorldSpawn", { op = "add", pos = { 10, 40, 10 } })
check(s1.node and s1.node.class == "SpawnLocation", "add retorna node")
local l1 = serverInvoke("WorldSpawn", { op = "list" }).spawns
check(#l1 == 1 and l1[1].pos[1] == 10 and l1[1].neutral == true, "pos + neutral")
local s2 = serverInvoke("WorldSpawn", { op = "add" })
check(s2.node.id ~= nil and type(l1[1].pos[2]) == "number", "add default ok")
local tg = serverInvoke("WorldSpawn", { op = "toggle", id = l1[1].id })
check(tg.enabled == false, "toggle desliga")
local l2 = serverInvoke("WorldSpawn", { op = "list" }).spawns
check(#l2 == 2, "2 spawns")
local rm = serverInvoke("WorldSpawn", { op = "remove", id = l2[2].id })
check(rm.removed and #serverInvoke("WorldSpawn", { op = "list" }).spawns == 1, "remove 1")
serverInvoke("Undo", {})
check(#serverInvoke("WorldSpawn", { op = "list" }).spawns == 2, "Undo restaura spawn")
local bp = ws:FindFirstChild("Baseplate")
local bpId = serverInvoke("Identify", { object = bp }).id
check(serverInvoke("WorldSpawn", { op = "remove", id = bpId }).error ~= nil, "remove nao-spawn falha")

print("\n== WO19-S4: Save/Load ==")
local sa = serverInvoke("WorldSave", { op = "save", name = "A" })
check(sa.saved and sa.items == 3, "save A: 3 top-level")
local sl = serverInvoke("WorldSave", { op = "list" }).saves
check(#sl == 1 and sl[1].name == "A" and sl[1].items == 3, "list mostra A")
check(serverInvoke("WorldSave", { op = "save", name = "A" }).error ~= nil, "dup falha")
check(serverInvoke("WorldSave", { op = "save", name = "??" }).error ~= nil, "nome ruim falha")
local ld = serverInvoke("WorldSave", { op = "load", name = "A" })
check(ld.loaded == 3, "load copia 3")
check(serverInvoke("WorldInfo", {}).parts == 6, "mundo dobra (6 parts)")
local dl = serverInvoke("WorldSave", { op = "delete", name = "A" })
check(dl.deleted and #serverInvoke("WorldSave", { op = "list" }).saves == 0, "delete limpa")
check(serverInvoke("WorldSave", { op = "load", name = "ZZ" }).error ~= nil, "load inexistente falha")

print("\n== WO19-S5: Clean/Restore/Clear ==")
local fp = Instance.new("Part"); fp.Name = "Fell"
fp.Anchored = true
fp.CFrame = CFrame.new(0, -1000, 0)
fp.Parent = ws
local fl = serverInvoke("WorldClean", { op = "fallen", y = -400 })
check(fl.moved == 1 and fp.Parent.Name == "ArkherTrash", "fallen vai p/ trash")
local rs = serverInvoke("WorldClean", { op = "restore" })
check(rs.restored == 1 and fp.Parent == ws, "restore devolve")
local lp = Instance.new("Part"); lp.Name = "Loose"
lp.Anchored = false
lp.CFrame = CFrame.new(0, 50, 0)
lp.Parent = ws
local lo = serverInvoke("WorldClean", { op = "loose" })
check(lo.moved == 1 and lp.Parent.Name == "ArkherTrash", "loose pega 1")
serverInvoke("WorldClean", { op = "restore" })
check(serverInvoke("WorldInfo", {}).trash == 0, "trash zerado")
check(serverInvoke("WorldClear", {}).error ~= nil, "clear sem confirm falha")
local before = serverInvoke("WorldInfo", {}).parts
local cl = serverInvoke("WorldClear", { confirm = true })
check(cl.deleted == before and cl.backup == "autosafe", "clear apaga tudo + autosafe")
check(serverInvoke("WorldInfo", {}).parts == 0, "mundo vazio")
local la = serverInvoke("WorldSave", { op = "load", name = "autosafe" })
check(la.loaded == before, "autosafe restaura tudo")

-- ============ CLIENT ============
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src19 = io.open("studio-completo/scripts/19_World.lua"):read("*a")
assert(pcall(assert(loadstring(src19, "[19]"))), "19 nao carregou")
local WO = _G.ArkherWorld
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== WO19-C1: boot/open/close ==")
check(WO ~= nil and WO.isOpen() == false, "19 expoe _G.ArkherWorld fechado")
check(find("WO9_Rail").Visible == false and find("M_WO").Visible == false, "WO9+M_WO ocultos")
find("TE3_Rail").Visible = true; find("RW7_Rail").Visible = true; find("DO8_Rail").Visible = true
WO.open()
check(WO.isOpen() and find("WO9_Save").Visible, "open mostra WO9")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("DO8_Rail").Visible == false, "open exclui editores")
check(find("WO9_InfoBig").Text:find("parts") ~= nil, "open carrega info")
WO.close()
check(find("WO9_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
WO.open()

print("\n== WO19-C2: info/gravity ==")
click("WO9_I_Refresh")
check(find("WO9_StatL").Text:find("spawns") ~= nil, "refresh mostra spawns")
check(find("WO9_G_Info").Text:find("killY") ~= nil, "grav info killY")
click("WO9_G_M")
check(find("WO9_GV").Text == "490", "stage 490 (500-10)")
click("WO9_G_Set")
check(ws.Gravity == 490, "apply poe 490 no server")
click("WO9_G_Reset")
check(find("WO9_GV").Text == "196.2" and ws.Gravity == 196.2, "reset volta Earth")

print("\n== WO19-C3: spawns UI ==")
local n0 = #serverInvoke("WorldSpawn", { op = "list" }).spawns
click("WO9_S_Add")
check(#serverInvoke("WorldSpawn", { op = "list" }).spawns == n0 + 1, "add +1")
check(find("WO9_S_Info").Text:find("SpawnLocation") ~= nil, "info mostra spawn")
click("WO9_S_Next")
click("WO9_S_Prev")
check(WO.state().spIdx >= 1, "ciclo ok")
local sp0 = WO.state().spawns[WO.state().spIdx].enabled
click("WO9_S_Toggle")
check(WO.state().spawns[WO.state().spIdx].enabled == (not sp0), "toggle inverte")
click("WO9_S_Del")
check(lastMsg():find("click again") ~= nil, "del arma")
click("WO9_S_Del")
check(#serverInvoke("WorldSpawn", { op = "list" }).spawns == n0, "del executa")

print("\n== WO19-C4: saves UI ==")
find("WO9_V_Name").Text = ""
click("WO9_V_Save")
check(lastMsg():find("name it") ~= nil, "sem nome avisa")
find("WO9_V_Name").Text = "B"
click("WO9_V_Save")
local hasB0 = false
for _, s in ipairs(serverInvoke("WorldSave", { op = "list" }).saves) do
	if s.name == "B" then hasB0 = true end
end
check(hasB0, "save B via UI (server)")
click("WO9_V_Next")
check(find("WO9_V_Info").Text:find("B") ~= nil, "navega ate B")
click("WO9_V_Prev")
click("WO9_V_Next")
check(WO.state().svIdx >= 1, "ciclo saves ok")
local pb = serverInvoke("WorldInfo", {}).parts
click("WO9_V_Load")
check(serverInvoke("WorldInfo", {}).parts > pb, "load soma copias")
click("WO9_V_Del")
check(lastMsg():find("click again") ~= nil, "del save arma")
click("WO9_V_Del")
local hasB = false
for _, s in ipairs(serverInvoke("WorldSave", { op = "list" }).saves) do
	if s.name == "B" then hasB = true end
end
check(not hasB, "del save executa")

print("\n== WO19-C5: cleanup UI ==")
local fp2 = Instance.new("Part"); fp2.Name = "Fell2"
fp2.Anchored = true
fp2.CFrame = CFrame.new(0, -999, 0)
fp2.Parent = ws
find("WO9_C_Y").Text = "-400"
click("WO9_C_Fallen")
check(fp2.Parent.Name == "ArkherTrash", "fallen via UI")
click("WO9_C_Restore")
check(fp2.Parent == ws, "restore via UI")
local lp2 = Instance.new("Part"); lp2.Name = "Loose2"
lp2.Anchored = false
lp2.Parent = ws
click("WO9_C_Loose")
check(lp2.Parent.Name == "ArkherTrash", "loose via UI")
click("WO9_C_Restore")
check(lp2.Parent == ws, "restore loose")
click("WO9_C_Clear")
check(lastMsg():find("click again") ~= nil, "clear arma")
click("WO9_C_Clear")
check(lastMsg():find("autosafe") ~= nil, "clear cita backup")
check(serverInvoke("WorldInfo", {}).parts == 0, "clear esvazia")
click("WO9_V_Next")
local svs = serverInvoke("WorldSave", { op = "list" }).saves
local ai = 0
for i, s in ipairs(svs) do if s.name == "autosafe" then ai = i end end
WO.state().svIdx = ai
click("WO9_V_Load")
check(serverInvoke("WorldInfo", {}).parts > 0, "autosafe recarrega")

print("\n== WO19-C6: mobile ==")
plat = "Mobile"
WO.close()
WO.open()
check(find("M_WO").Visible == true, "Mobile: strip visivel")
click("M_WO_Save")
check(lastMsg():find("Quicksaved") ~= nil, "M_WO_Save salva")
click("M_WO_Spawn")
check(lastMsg():find("added") ~= nil, "M_WO_Spawn adiciona")
click("M_WO_Clean")
check(lastMsg():find("Quarantined") ~= nil, "M_WO_Clean limpa")
WO.close()
check(find("M_WO").Visible == false, "close esconde M_WO")
plat = "PC"

print("\nWO19: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
