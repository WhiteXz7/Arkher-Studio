-- Testa R16c Places: server PlaceList/TeleportTo/PlaceCreate + 22_Places (lista/teleport/cutscene).
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
for _, n in ipairs({ "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status", "M_PL" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "WO9_Rail", "HO10_Rail", "SC11_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "PL12_L_Refresh", "PL12_L_Prev", "PL12_L_Next", "PL12_L_Go", "PL12_L_GoId",
	"PL12_N_Create", "PL12_C_A", "PL12_C_B", "PL12_C_Play", "PL12_C_Stop",
	"PL12_Close", "M_PL_Go", "M_PL_A", "M_PL_Play" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "PL12_L_Info", "PL12_N_Info", "PL12_C_Info", "PL12_A_Text", "PL12_StatL", "M_PL_Hint" }) do
	W(shell, "TextLabel", n)
end
W(shell, "TextBox", "PL12_L_Id")
W(shell, "TextBox", "PL12_N_Name")
W(shell, "TextBox", "PL12_N_Tpl")
W(shell, "TextBox", "PL12_C_T")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_22_Places"; script.Parent = gui

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
menusBus.OnInvoke = function() return true end
local function lastMsg() return messages[#messages] and messages[#messages].text or "" end
local function sawMsg(pat)
	for _, m in ipairs(messages) do
		if tostring(m.text):find(pat) then return true end
	end
	return false
end

local ws = game:GetService("Workspace")
ws:FindFirstChild("Baseplate").CFrame = CFrame.new(0, -0.5, 0)
local AS = game:GetService("AssetService")
rawget(AS, "__props")._places = {
	{ PlaceId = 111, Name = "Terra Norte" },
	{ PlaceId = 222, Name = "Terra Sul" },
}
local TS0 = game:GetService("TeleportService")
local function teleports() return rawget(TS0, "__props")._teleports end
game.GameId = 999 -- simula jogo publicado (PlaceList client nao passa uid)

print("\n== PL22-S1: PlaceList/TeleportTo/PlaceCreate server ==")
local pl = serverInvoke("PlaceList", { universeId = 999 })
check(pl.places and #pl.places == 2 and pl.places[1].placeId == 111 and pl.universeId == 999, "PlaceList pagina 2 places")
local plNo = serverInvoke("PlaceList", {})
check(plNo.error ~= nil or (plNo.places ~= nil), "PlaceList sem uid: erro honesto ou GameId (" .. tostring(plNo.error or "ok"):sub(1, 40) .. ")")
local t0 = #teleports()
local tr = serverInvoke("TeleportTo", { placeId = 111 })
check(tr.ok and #teleports() == t0 + 1 and teleports()[#teleports()].placeId == 111, "TeleportTo registra teleport")
local tbad = serverInvoke("TeleportTo", { placeId = 0 })
check(tbad.error ~= nil, "TeleportTo id 0 recusa")
local pcr = serverInvoke("PlaceCreate", { name = "PL22 Nova", description = "t" })
check(pcr.placeId ~= nil and pcr.url:find("roblox.com") ~= nil, "PlaceCreate retorna id+url (" .. tostring(pcr.placeId) .. ")")
local pcbad = serverInvoke("PlaceCreate", { name = "ab" })
check(pcbad.error ~= nil, "PlaceCreate nome curto recusa")

-- ============ CLIENT ============
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src22 = io.open("studio-completo/scripts/22_Places.lua"):read("*a")
assert(pcall(assert(loadstring(src22, "[22]"))), "22 nao carregou")
local PL = _G.ArkherPlaces
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== PL22-C1: boot/open/close ==")
check(PL ~= nil and PL.isOpen() == false, "22 expoe _G.ArkherPlaces fechado")
find("TE3_Rail").Visible = true; find("HO10_Rail").Visible = true; find("SC11_Rail").Visible = true
PL.open()
check(PL.isOpen() and find("PL12_List").Visible, "open mostra PL12")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("HO10_Rail").Visible == false and find("SC11_Rail").Visible == false, "open exclui editores")
check(find("PL12_StatL").Text:find("places") ~= nil, "open carrega lista")
PL.close()
check(find("PL12_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
PL.open()

print("\n== PL22-C2: lista + teleport ==")
click("PL12_L_Refresh")
check(#PL.state().places == 2, "refresh lista 2 places")
local i0 = PL.state().idx
click("PL12_L_Next")
check(PL.state().idx ~= i0, "next anda")
click("PL12_L_Prev")
check(PL.state().idx == i0, "prev volta")
local nt0 = #teleports()
click("PL12_L_Go")
check(sawMsg("Teleporting") and #teleports() == nt0 + 1, "GO teleporta p/ selecionada")
find("PL12_L_Id").Text = "abc"
click("PL12_L_GoId")
check(lastMsg():find("bad placeId") ~= nil, "GoId invalido avisa")
find("PL12_L_Id").Text = "222"
click("PL12_L_GoId")
check(#teleports() == nt0 + 2 and teleports()[#teleports()].placeId == 222, "GoId numerico teleporta")

print("\n== PL22-C3: nova place ==")
find("PL12_N_Name").Text = "ab"
click("PL12_N_Create")
check(lastMsg():find("3%+") ~= nil, "nome curto avisa")
find("PL12_N_Name").Text = "PL22 ViaUI"
find("PL12_N_Tpl").Text = ""
click("PL12_N_Create")
check(sawMsg("created") and find("PL12_N_Info").Text:find("id ") ~= nil, "Create cria de verdade")

print("\n== PL22-C4: cutscene real ==")
local cam = Instance.new("Camera")
cam.Name = "TestCam"
local oldType = Enum.CameraType.Custom
cam.CameraType = oldType
local cfa = CFrame.new(0, 10, 0)
local cfb = CFrame.new(50, 20, 50)
cam.CFrame = cfa
ws.CurrentCamera = cam
click("PL12_C_A")
cam.CFrame = cfb
click("PL12_C_B")
check(find("PL12_C_Info").Text:find("A ok") ~= nil, "A+B marcados")
find("PL12_C_T").Text = "1"
cam.CFrame = cfa
click("PL12_C_Play")
check(cam.CFrame == cfb, "Play move camera ate B")
check(cam.CameraType == oldType, "camera restaurada apos cutscene")
check(gui:FindFirstChild("ArkherCutFade") == nil, "fade removido")
check(sawMsg("Cutscene done"), "msg done")
click("PL12_C_Stop")
check(lastMsg():find("stopped") ~= nil, "Stop idle avisa")

print("\n== PL22-C5: mobile ==")
plat = "Mobile"
PL.close(); PL.open()
check(find("M_PL").Visible, "M_PL visivel no mobile")
local nm0 = #teleports()
click("M_PL_Go")
check(#teleports() == nm0 + 1, "M Go teleporta")
cam.CFrame = cfa
click("M_PL_A")
click("M_PL_Play")
check(cam.CFrame == cfb and cam.CameraType == oldType, "M Play executa cutscene")
plat = "PC"
PL.close(); PL.open()

print(("\nPL22: %d ok, %d falhas"):format(pass, fail))
if fail > 0 then os.exit(1) end
