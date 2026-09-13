-- Testa R16a Home/Explorer: 20_Home (file via MenusBus, tree Snapshot, props reais).
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
for _, n in ipairs({ "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status", "M_HO" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail", "AN5_Rail", "UI6_Rail", "RW7_Rail", "DO8_Rail", "WO9_Rail", "SC11_Rail", "PL12_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "HO10_F_New", "HO10_F_Open", "HO10_F_Save", "HO10_F_Pub", "HO10_F_Undo",
	"HO10_T_Prev", "HO10_T_Next", "HO10_T_Sel", "HO10_T_Refresh",
	"HO10_P_Rename", "HO10_P_Vis", "HO10_P_Dup", "HO10_P_Del", "HO10_Close",
	"M_HO_Save", "M_HO_Refresh", "M_HO_Del" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "HO10_F_Info", "HO10_T_Info", "HO10_P_Info", "HO10_StatL", "HO10_H_Text", "M_HO_Hint" }) do
	W(shell, "TextLabel", n)
end
W(shell, "TextBox", "HO10_T_Filter")
W(shell, "TextBox", "HO10_P_Name")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_20_Home"; script.Parent = gui

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
local menusCalls = {}
menusBus.OnInvoke = function(action, payload)
	menusCalls[#menusCalls + 1] = action
	return true
end
local function lastMsg() return messages[#messages] and messages[#messages].text or "" end
local function sawMsg(pat)
	for _, m in ipairs(messages) do
		if tostring(m.text):find(pat) then return true end
	end
	return false
end

local ws = game:GetService("Workspace")
ws:FindFirstChild("Baseplate").CFrame = CFrame.new(0, -0.5, 0)

-- ============ CLIENT ============
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src20 = io.open("studio-completo/scripts/20_Home.lua"):read("*a")
assert(pcall(assert(loadstring(src20, "[20]"))), "20 nao carregou")
local HO = _G.ArkherHome
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== HO20-C1: boot/open/close ==")
check(HO ~= nil and HO.isOpen() == false, "20 expoe _G.ArkherHome fechado")
check(find("HO10_Rail").Visible == false and find("M_HO").Visible == false, "HO10+M_HO ocultos")
check(find("HO10_H_Text").Text:find("EXPLORER") ~= nil, "help estatico no boot")
find("TE3_Rail").Visible = true; find("WO9_Rail").Visible = true; find("SC11_Rail").Visible = true
HO.open()
check(HO.isOpen() and find("HO10_Tree").Visible, "open mostra HO10")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("WO9_Rail").Visible == false and find("SC11_Rail").Visible == false, "open exclui editores (incl R16)")
check(find("HO10_StatL").Text:find("nodes") ~= nil, "open carrega tree")
HO.close()
check(find("HO10_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
HO.open()

print("\n== HO20-C2: file via MenusBus ==")
click("HO10_F_New")
check(menusCalls[#menusCalls] == "File", "NEW passa File p/ menus")
click("HO10_F_Open")
check(menusCalls[#menusCalls] == "File", "OPEN passa File p/ menus")
click("HO10_F_Save")
check(menusCalls[#menusCalls] == "Save" and sawMsg("Saved"), "SAVE passa Save p/ menus")
click("HO10_F_Pub")
check(menusCalls[#menusCalls] == "OpenPublish", "PUBLISH abre dialogo")

print("\n== HO20-C3: tree real ==")
find("HO10_T_Filter").Text = ""
click("HO10_T_Refresh")
local st = HO.state()
check(#st.nodes > 5, "tree tem nos (" .. #st.nodes .. ")")
find("HO10_T_Filter").Text = "base"
click("HO10_T_Refresh")
st = HO.state()
local allBase = true
for _, nd in ipairs(st.nodes) do
	if not tostring(nd.name):lower():find("base") then allBase = false end
end
check(#st.nodes >= 1 and allBase, "filtro 'base' restringe")
find("HO10_T_Filter").Text = ""
click("HO10_T_Refresh")
st = HO.state()
local i0 = st.idx
click("HO10_T_Next")
check(HO.state().idx ~= i0 or #HO.state().nodes <= 1, "next anda")
click("HO10_T_Prev")
check(HO.state().idx == i0, "prev volta")
click("HO10_T_Sel")
check(sawMsg("Selected"), "SELECT espelha selecao real")

print("\n== HO20-C4: props reais (dup/rename/vis/del) ==")
find("HO10_T_Filter").Text = "base"
click("HO10_T_Refresh")
st = HO.state()
check(#st.nodes == 1 and st.nodes[1].name == "Baseplate", "filtro isola Baseplate")
click("HO10_T_Sel")
click("HO10_P_Dup")
check(sawMsg("Duplicated") and #HO.state().nodes == 2, "DUP cria copia real")
-- seleciona a copia (ultimo no) e renomeia
st = HO.state()
st.idx = #st.nodes
click("HO10_T_Sel")
find("HO10_P_Name").Text = "HO20_Copia"
click("HO10_P_Rename")
check(sawMsg("Renamed"), "RENAME renomeia de verdade")
local snap = serverInvoke("Snapshot", {})
local gotNew = false
for _, nd in ipairs(snap.nodes) do
	if nd.name == "HO20_Copia" then gotNew = true end
end
check(gotNew, "novo nome aparece no Snapshot")
click("HO10_F_Undo")
check(sawMsg("Undid"), "UNDO desfaz rename")
click("HO10_P_Del")
check(sawMsg("Deleted"), "DEL apaga de verdade")
snap = serverInvoke("Snapshot", {})
local left = 0
for _, nd in ipairs(snap.nodes) do
	if tostring(nd.name):lower():find("base") then left = left + 1 end
end
check(left == 1, "so resta a Baseplate original")

print("\n== HO20-C5: mobile ==")
plat = "Mobile"
HO.close(); HO.open()
check(find("M_HO").Visible, "M_HO visivel no mobile")
click("M_HO_Save")
check(menusCalls[#menusCalls] == "Save", "M save passa Save")
click("M_HO_Refresh")
check(#HO.state().nodes > 0, "M refresh recarrega")
plat = "PC"
HO.close(); HO.open()

print("\n== HO20-C6: honestidade ==")
HO.state().selId = nil
click("HO10_P_Rename")
check(lastMsg():find("select first") ~= nil, "rename sem sel avisa")
click("HO10_P_Vis")
check(lastMsg():find("select first") ~= nil, "vis sem sel avisa")
click("HO10_P_Dup")
check(lastMsg():find("select first") ~= nil, "dup sem sel avisa")

print(("\nHO20: %d ok, %d falhas"):format(pass, fail))
if fail > 0 then os.exit(1) end
