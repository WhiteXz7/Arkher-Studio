-- Testa R15a D-O15: server Do15* (stats/audit/optimize/preload/relevance/gc) + 18_Do15.
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
for _, n in ipairs({ "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status", "M_DO" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail", "AN5_Rail", "UI6_Rail", "RW7_Rail", "WO9_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "DO8_Scan", "DO8_Close", "DO8_S_Refresh", "DO8_S_Report", "DO8_A_Scan",
	"DO8_O_Touch", "DO8_O_Shadow", "DO8_O_Anchor", "DO8_O_Undo", "DO8_R_Add", "DO8_R_RM",
	"DO8_R_RP", "DO8_R_KLight", "DO8_R_KEmit", "DO8_R_KDecal", "DO8_R_KSnd",
	"DO8_R_Reg", "DO8_R_Del", "DO8_M_GC", "DO8_M_Pre", "M_DO_Scan", "M_DO_Opt", "M_DO_GC" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "DO8_StatBig", "DO8_StatL", "DO8_AuditBig", "DO8_O_Info",
	"DO8_R_RV", "DO8_R_Info", "DO8_M_Info", "M_DO_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "DO8_R_Name")
W(shell, "TextBox", "DO8_M_Ids")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_18_Do15"; script.Parent = gui

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
local function sawMsg(pat)
	for _, m in ipairs(messages) do if m.text and m.text:find(pat) then return true end end
	return false
end

local ws = game:GetService("Workspace")
local Http = game:GetService("HttpService")
local St = game:GetService("Stats")
St.InstanceCount = 500
St.PrimitivesCount = 300
St.SceneTriangleCount = 12000
St.SceneDrawcallCount = 40
rawget(St, "__props")._memMb = 700
ws.StreamingEnabled = true
ws.StreamingTargetRadius = 512
ws.Gravity = 196.2
ws.FallenPartsDestroyHeight = -500

local p1 = Instance.new("Part"); p1.Name = "P1"
p1.Anchored = true; p1.CanTouch = true; p1.CastShadow = true
p1.Material = Enum.Material.Plastic
p1.Parent = ws
local p2 = Instance.new("Part"); p2.Name = "P2"
p2.Anchored = false; p2.CanTouch = false; p2.CastShadow = false
p2.Parent = ws
local p3 = Instance.new("Part"); p3.Name = "P3"
p3.Anchored = true; p3.CanTouch = true; p3.CastShadow = true
p3.Transparency = 0.5
p3.Parent = ws
local cd = Instance.new("ClickDetector"); cd.Parent = p3
local snd = Instance.new("Sound"); snd.Parent = ws

print("\n== DO18-S1: Do15Stats ==")
local st = serverInvoke("Do15Stats", {})
check(type(st.fps) == "number", "fps numerico")
check(st.instances == 500 and st.primitives == 300, "Stats readback")
check(st.memMb == 700, "memoria readback")
check(st.streaming == true and st.targetRadius == 512, "streaming readback")
check(st.gravity == 196.2 and st.killY == -500, "gravity/killY readback")
check(st.parts == 4, "conta 4 parts (base+p1+p2+p3)")

print("\n== DO18-S2: Do15Audit ==")
local au = serverInvoke("Do15Audit", {})
check(au.parts == 4, "audit parts")
check(au.unanchored == 1, "unanchored = p2")
check(au.cantouch == 3, "cantouch 3 (p1+p3+base default)")
check(au.castshadow == 3, "castshadow 3")
check(au.transparent == 1, "transparent = p3")
check(au.sounds == 1, "sounds 1")
local msum = 0
local hasPlastic = false
for _, t in ipairs(au.topMats or {}) do
	msum = msum + t.n
	if t.mat == "Plastic" then hasPlastic = true end
end
check(msum == 4 and hasPlastic, "histograma materiais soma 4 + Plastic")

print("\n== DO18-S3: Do15Optimize + undo ==")
local o1 = serverInvoke("Do15Optimize", { ops = { "notouch" } })
check(o1.changed.notouch == 2 and o1.skipped == 1, "notouch: 2 mudam, 1 skip (ClickDetector)")
check(p1.CanTouch == false and p3.CanTouch == true, "p3 com detector preservado")
serverInvoke("Undo", {})
check(p1.CanTouch == true, "Undo restaura CanTouch")
serverInvoke("Redo", {})
check(p1.CanTouch == false, "Redo reaplica")
local o2 = serverInvoke("Do15Optimize", { ops = { "noshadow" } })
check(o2.changed.noshadow == 2, "noshadow muda 2")
serverInvoke("Undo", {})
check(p1.CastShadow == true, "Undo restaura sombra")
check(serverInvoke("Do15Optimize", { ops = { "anchor" } }).error ~= nil, "anchor sem confirm falha")
local o3 = serverInvoke("Do15Optimize", { ops = { "anchor" }, confirm = true })
check(o3.changed.anchor == 1 and p2.Anchored == true, "anchor confirma+aplica")
serverInvoke("Undo", {})
check(p2.Anchored == false, "Undo restaura anchor")

print("\n== DO18-S4: Preload/GC/Report ==")
local pl = serverInvoke("Do15Preload", { ids = { "rbxassetid://123", "rbxassetid://456" } })
check(pl.loaded == 2 and pl.failed == 0, "preload 2 ok")
check(serverInvoke("Do15Preload", { ids = { "xyz" } }).error ~= nil, "id invalido falha")
local many = {}
for i = 1, 51 do many[i] = "rbxassetid://" .. i end
check(serverInvoke("Do15Preload", { ids = many }).error ~= nil, "51 ids falha (cap 50)")
local gc = serverInvoke("Do15Gc", {})
check(type(gc.beforeKb) == "number" and type(gc.freedKb) == "number", "gc retorna numeros")
local rp = serverInvoke("Do15Report", {})
local dec = Http:JSONDecode(rp.json)
check(dec.v == 1 and dec.stats.parts == 4 and dec.audit.parts == 4, "report JSON stats+audit")

print("\n== DO18-S5: Relevance (distancia real) ==")
local gm = Instance.new("Model"); gm.Name = "RelG"
local gp = Instance.new("Part"); gp.Name = "GP"
gp.CFrame = CFrame.new(0, 0, 0)
gp.Parent = gm
local gl = Instance.new("PointLight"); gl.Enabled = true; gl.Parent = gp
local ge = Instance.new("ParticleEmitter"); ge.Enabled = false; ge.Parent = gp
local gd = Instance.new("Decal"); gd.Parent = gp
gm.Parent = ws
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 0, 0)
ws.CurrentCamera = cam
local gid = serverInvoke("Identify", { object = gm }).id
local rr = serverInvoke("Do15Relevance", { op = "register", name = "R1",
	id = gid, radius = 150, kinds = { "Light", "Emitter" } })
check(rr.registered and rr.items == 2, "register conta Light+Emitter (decal fora)")
cam.CFrame = CFrame.new(1000, 0, 0)
game:GetService("RunService").Heartbeat:Fire(0.1)
check(gl.Enabled == false, "longe: desliga")
local rl = serverInvoke("Do15Relevance", { op = "list" })
check(rl.groups[1].on == false and rl.groups[1].dist > 900, "list: off + dist real")
cam.CFrame = CFrame.new(0, 0, 0)
game:GetService("RunService").Heartbeat:Fire(0.1)
check(gl.Enabled == true and ge.Enabled == false, "perto: restaura estado INICIAL (emitter off)")
local rm = serverInvoke("Do15Relevance", { op = "remove", name = "R1" })
check(rm.removed and #serverInvoke("Do15Relevance", { op = "list" }).groups == 0, "remove limpa")
check(serverInvoke("Do15Relevance", { op = "register", name = "R2",
	id = gid, kinds = { "X" } }).error ~= nil, "kind invalido falha")
serverInvoke("Do15Relevance", { op = "register", name = "Rdup", id = gid })
check(serverInvoke("Do15Relevance", { op = "register", name = "Rdup", id = gid }).error ~= nil,
	"nome duplicado falha")
serverInvoke("Do15Relevance", { op = "remove", name = "Rdup" })

-- ============ CLIENT ============
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src18 = io.open("studio-completo/scripts/18_Do15.lua"):read("*a")
assert(pcall(assert(loadstring(src18, "[18]"))), "18 nao carregou")
local DO = _G.ArkherDo15
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== DO18-C1: boot/open/close ==")
check(DO ~= nil and DO.isOpen() == false, "18 expoe _G.ArkherDo15 fechado")
check(find("DO8_Rail").Visible == false and find("M_DO").Visible == false, "DO8+M_DO ocultos")
find("TE3_Rail").Visible = true; find("UI6_Rail").Visible = true
find("RW7_Rail").Visible = true; find("WO9_Rail").Visible = true
DO.open()
check(DO.isOpen() and find("DO8_Opt").Visible, "open mostra DO8")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("WO9_Rail").Visible == false, "open exclui editores")
check(find("DO8_StatBig").Text:find("fps") ~= nil, "open carrega stats")
DO.close()
check(find("DO8_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
DO.open()

print("\n== DO18-C2: stats/audit UI ==")
click("DO8_S_Refresh")
check(find("DO8_StatL").Text:find("mem 700") ~= nil, "refresh mostra mem 700")
click("DO8_S_Report")
check(lastMsg():find("bytes") ~= nil, "report loga bytes")
click("DO8_A_Scan")
check(find("DO8_AuditBig").Text:find("parts 5") ~= nil, "audit UI mostra 5 parts (+gp)")
check(lastMsg():find("Audit: 5") ~= nil, "audit loga")
click("DO8_Scan")
check(find("DO8_AuditBig").Text:find("unanch 2") ~= nil, "scan via rail (p2+gp)")

print("\n== DO18-C3: optimize UI ==")
click("DO8_O_Touch")
check(find("DO8_O_Info").Text:find("touch 1") ~= nil, "touch pega gp (+1)")
click("DO8_O_Shadow")
check(find("DO8_O_Info").Text:find("shadow 3") ~= nil, "shadow pega p1+bp+gp (3)")
click("DO8_O_Anchor")
check(find("DO8_O_Info").Text:find("click again") ~= nil, "anchor arma confirm")
click("DO8_O_Anchor")
check(find("DO8_O_Info").Text:find("anchor") ~= nil, "anchor executa")
click("DO8_O_Undo")
check(sawMsg("Undid"), "undo via UI")

print("\n== DO18-C4: relevance UI ==")
local sv = Instance.new("ObjectValue"); sv.Name = "SelectedInstance"; sv.Parent = runtime
sv.Value = gm
click("DO8_R_Add")
check(find("DO8_R_Info").Text:find("RelG") ~= nil, "add stages model")
click("DO8_R_RP")
check(find("DO8_R_RV").Text == "200", "radius 200")
click("DO8_R_RM")
check(find("DO8_R_RV").Text == "150", "radius volta 150")
click("DO8_R_KDecal")
check(DO.state().kinds.Decal == true, "kind Decal liga")
click("DO8_R_Reg")
check(lastMsg():find("name the group") ~= nil, "sem nome avisa")
find("DO8_R_Name").Text = "RC"
click("DO8_R_Reg")
check(lastMsg():find("live") ~= nil, "register via UI")
check(find("DO8_R_Info").Text:find("RC") ~= nil, "lista mostra RC")
click("DO8_R_Del")
check(lastMsg():find("removed") ~= nil, "remove via UI")

print("\n== DO18-C5: memory UI ==")
click("DO8_M_GC")
check(find("DO8_M_Info").Text:find("freed") ~= nil, "gc mostra freed")
find("DO8_M_Ids").Text = "rbxassetid://1, rbxassetid://2"
click("DO8_M_Pre")
check(find("DO8_M_Info").Text:find("2 ok") ~= nil, "preload 2 ok")
find("DO8_M_Ids").Text = ""
click("DO8_M_Pre")
check(lastMsg():find("paste ids") ~= nil, "vazio avisa")

print("\n== DO18-C6: mobile ==")
plat = "Mobile"
DO.close()
DO.open()
check(find("M_DO").Visible == true, "Mobile: strip visivel")
click("M_DO_Scan")
check(lastMsg():find("Audit") ~= nil, "M_DO_Scan audita")
click("M_DO_Opt")
check(sawMsg("Optimized"), "M_DO_Opt otimiza")
click("M_DO_GC")
check(lastMsg():find("GC:") ~= nil, "M_DO_GC coleta")
DO.close()
check(find("M_DO").Visible == false, "close esconde M_DO")
plat = "PC"

print("\nDO18: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
