-- Testa R13 Animator: server Anim* (rig/keys/poses/preview/IK/JSON) + client 15_Animator.
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
for _, n in ipairs({ "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "M_AN" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail", "MD4_Rail" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "AN5_T_Select", "AN5_T_Pose", "AN5_Close", "AN5_New", "AN5_Adopt",
	"AN5_J_Prev", "AN5_J_Next", "AN5_R_XM", "AN5_R_XP", "AN5_R_YM", "AN5_R_YP",
	"AN5_R_ZM", "AN5_R_ZP", "AN5_R_Apply", "AN5_R_Reset", "AN5_Play", "AN5_Stop",
	"AN5_F_M", "AN5_F_P", "AN5_Loop", "AN5_S_M", "AN5_S_P", "AN5_K_Prev",
	"AN5_K_Next", "AN5_K_Add", "AN5_K_Del", "AN5_E_S", "AN5_E_D", "AN5_W_M",
	"AN5_W_P", "AN5_IO_Import", "AN5_IO_Export", "M_AN_New", "M_AN_Play", "M_AN_Key" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "AN5_J_Name", "AN5_Info", "AN5_R_XV", "AN5_R_YV", "AN5_R_ZV",
	"AN5_Pose_Hint", "AN5_TLabel", "AN5_SV", "AN5_K_Name", "AN5_WV",
	"AN5_IO_Stat", "AN5_StatL", "M_AN_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "AN5_IO_Text")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_15_Animator"; script.Parent = gui

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
local messages, setModes = {}, {}
clientBus.OnInvoke = function(action, payload)
	payload = payload or {}
	if action == "API" then
		local r = serverInvoke(payload.action, payload.payload)
		if r and r.error then return { error = r.error } end
		return { result = r }
	end
	if action == "Message" then messages[#messages + 1] = payload return true end
	if action == "SetMode" then setModes[#setModes + 1] = payload.key return true end
	return true
end
local function lastMsg() return messages[#messages] and messages[#messages].text or "" end

local ws = game:GetService("Workspace")
local Http = game:GetService("HttpService")

-- rig fixture: HRP + Torso + Head + RightArm, 3 Motor6D
local rig = Instance.new("Model"); rig.Name = "TestRig"
local function mkPart(nm)
	local p = Instance.new("Part"); p.Name = nm
	p.Size = Vector3.new(2, 2, 1); p.Anchored = true
	p.Parent = rig
	return p
end
local hrp, torso, head, rarm = mkPart("HumanoidRootPart"), mkPart("Torso"), mkPart("Head"), mkPart("RightArm")
local hum = Instance.new("Humanoid"); hum.Name = "Humanoid"; hum.Parent = rig
local function mkMotor(nm, p0, p1)
	local m = Instance.new("Motor6D"); m.Name = nm
	m.Part0 = p0; m.Part1 = p1
	m.C0 = CFrame.new(); m.C1 = CFrame.new(); m.Transform = CFrame.new()
	m.Parent = p1
	return m
end
local mRoot = mkMotor("Root", hrp, torso)
local mNeck = mkMotor("Neck", torso, head)
local mSho = mkMotor("Shoulder", torso, rarm)
rig.Parent = ws
local rigId = serverInvoke("Identify", { object = rig }).id
assert(rigId, "rig nao identificado")

print("\n== AN15-S1: AnimRig ==")
local rRig = serverInvoke("AnimRig", { id = rigId })
check(rRig.joints and #rRig.joints == 3, "rig: 3 juntas")
check(rRig.joints[1] == "Head" and rRig.joints[3] == "Torso", "juntas ordenadas")
check(rRig.parts == 4, "rig: 4 parts")
check(rRig.animatorCreated == true, "Animator auto-criado (flag honesta)")
local rRig2 = serverInvoke("AnimRig", { id = rigId })
check(rRig2.animatorCreated == false, "2o adopt nao duplica Animator")
local norHum = Instance.new("Model"); norHum.Name = "NoHum"; norHum.Parent = ws
local p0 = Instance.new("Part"); p0.Name = "P"; p0.Parent = norHum
local idNoHum = serverInvoke("Identify", { object = norHum }).id
check(serverInvoke("AnimRig", { id = idNoHum }).error ~= nil, "rig sem Humanoid falha")
check(serverInvoke("AnimRig", { id = serverInvoke("Identify", { object = p0 }).id }).error ~= nil,
	"AnimRig em Part falha")

print("\n== AN15-S2: AnimNew/AnimKeys ==")
local rNew = serverInvoke("AnimNew", { name = "SeqA" })
check(rNew.node and rNew.node.name == "SeqA" and rNew.length == 0, "AnimNew vazia (0 keys)")
local seqA = rNew.node.id
local rNewR = serverInvoke("AnimNew", { name = "SeqR", rigId = rigId, priority = "Action2", loop = true })
local seqR = rNewR.node.id
local kR = serverInvoke("AnimKeys", { id = seqR })
check(#kR.keys == 1 and kR.keys[1].name == "K0" and kR.keys[1].poses == 4, "AnimNew+rig captura K0 (4 poses)")
local exR = serverInvoke("AnimExport", { id = seqR })
local dR = Http:JSONDecode(exR.json)
check(dR.priority == "Action2" and dR.loop == true, "priority/loop persistidos")
local kA = serverInvoke("AnimKeys", { id = seqA })
check(#kA.keys == 0 and kA.length == 0, "AnimKeys vazia")

print("\n== AN15-S3: KeyAdd/KeyDel + undo ==")
local ka = serverInvoke("AnimKeyAdd", { id = seqA, time = 1, rigId = rigId })
check(ka.time == 1 and ka.poses == 4, "KeyAdd t=1 captura 4 poses")
check(serverInvoke("AnimKeyAdd", { id = seqA, time = 1 }).error ~= nil, "tempo duplicado rejeitado")
local kaFar = serverInvoke("AnimKeyAdd", { id = seqA, time = 200 })
check(kaFar.time == 120, "tempo clampado em 120s")
local kA2 = serverInvoke("AnimKeys", { id = seqA })
check(#kA2.keys == 2 and kA2.length == 120, "2 keys, length 120")
local kd = serverInvoke("AnimKeyDel", { id = seqA, time = 120 })
check(kd.deleted and serverInvoke("AnimKeys", { id = seqA }).length == 1, "KeyDel remove (len 1)")
serverInvoke("Undo", {})
local kU = serverInvoke("AnimKeys", { id = seqA })
check(#kU.keys == 2, "Undo restaura key")
serverInvoke("Redo", {})
check(#serverInvoke("AnimKeys", { id = seqA }).keys == 1, "Redo refaz delete")
serverInvoke("Undo", {})
check(#serverInvoke("AnimKeys", { id = seqA }).keys == 2, "Undo2 apos Redo (ciclo)")
serverInvoke("Redo", {})
check(serverInvoke("AnimKeyDel", { id = seqA, time = 55 }).error ~= nil, "del tempo inexistente falha")

print("\n== AN15-S4: PoseSet + JointSet ==")
local ps = serverInvoke("AnimPoseSet", { id = seqA, time = 1, part = "Head", rot = { y = 90 }, weight = 2 })
check(ps.ok2, "PoseSet Head rot90")
local ex1 = Http:JSONDecode(serverInvoke("AnimExport", { id = seqA }).json)
local headPose = nil
for _, k in ipairs(ex1.keys) do
	if k.time == 1 then
		for _, p in ipairs(k.poses) do
			if p.path[#p.path] == "Head" then headPose = p end
		end
	end
end
check(headPose and math.abs(headPose.cf[4] - 0) < 1e-6 and math.abs(headPose.cf[6] - 1) < 1e-6
	and headPose.w == 2, "Head rotY90 serializado (r00=0 r02=1, w=2)")
check(headPose and headPose.es == "Linear" and headPose.ed == "InOut", "easing default Linear/InOut")
serverInvoke("AnimPoseSet", { id = seqA, time = 1, part = "Head", easingStyle = "Bounce", easingDir = "In" })
local ex2 = Http:JSONDecode(serverInvoke("AnimExport", { id = seqA }).json)
local hp2 = nil
for _, k in ipairs(ex2.keys) do
	if k.time == 1 then
		for _, p in ipairs(k.poses) do
			if p.path[#p.path] == "Head" then hp2 = p end
		end
	end
end
check(hp2 and hp2.es == "Bounce" and hp2.ed == "In", "easing-only atualiza")
check(hp2 and math.abs(hp2.cf[6] - 1) < 1e-6, "easing-only PRESERVA CFrame (prova)")
check(serverInvoke("AnimPoseSet", { id = seqA, time = 1, part = "Head", easingStyle = "X" }).error ~= nil,
	"easing invalido rejeitado")
local psNew = serverInvoke("AnimPoseSet", { id = seqA, time = 1, part = "Tail" })
check(psNew.created == true, "pose nova p/ part fora do rig (top-level)")
serverInvoke("Undo", {})
local ex3 = Http:JSONDecode(serverInvoke("AnimExport", { id = seqA }).json)
local tailGone = true
for _, k in ipairs(ex3.keys) do
	for _, p in ipairs(k.poses) do if p.path[#p.path] == "Tail" then tailGone = false end end
end
check(tailGone, "Undo remove pose criada")
local js = serverInvoke("AnimJointSet", { rigId = rigId, part = "RightArm", rot = { x = 30 } })
local ox = mSho.Transform:ToOrientation()
check(js.posed and math.abs(math.deg(ox) - 30) < 1e-6, "JointSet escreve Transform (30deg)")
check(serverInvoke("AnimJointSet", { rigId = rigId, part = "Nope", rot = {} }).error ~= nil,
	"JointSet junta inexistente falha")
serverInvoke("AnimJointSet", { rigId = rigId, part = "RightArm", rot = { x = 0 } })

print("\n== AN15-S5: playback (interpolacao provada) ==")
local rP = serverInvoke("AnimNew", { name = "SeqP", rigId = rigId })
local seqP = rP.node.id
serverInvoke("AnimKeyAdd", { id = seqP, time = 1, rigId = rigId })
serverInvoke("AnimPoseSet", { id = seqP, time = 1, part = "Head", rot = { y = 90 } })
local sc = serverInvoke("AnimScrub", { id = seqP, rigId = rigId, time = 0.5 })
local _, hy = mNeck.Transform:ToOrientation()
check(sc.time == 0.5 and math.abs(math.deg(hy) - 45) < 1e-6, "scrub 0.5 = midpoint exato (Head 45deg)")
local sc2 = serverInvoke("AnimScrub", { id = seqP, rigId = rigId, time = 99 })
check(sc2.time == 99 and sc2.applied == 1, "cursor livre p/ edicao; pose clampada no fim")
local pl = serverInvoke("AnimPlay", { id = seqP, rigId = rigId })
check(pl.playing and pl.joints == 3 and pl.trackLoaded == false, "AnimPlay: 3 juntas, sem track")
check(pl.approx == false and pl.msg:find("exato") ~= nil, "preview Linear = exato (flag honesta)")
game:GetService("RunService").Heartbeat:Fire(0.25)
game:GetService("RunService").Heartbeat:Fire(0.25)
local _, hy2 = mNeck.Transform:ToOrientation()
check(math.abs(math.deg(hy2) - 45) < 1, "Heartbeat avanca sessao (2x0.25 -> 45deg)")
serverInvoke("AnimPlay", { id = seqP, rigId = rigId, loop = true })
game:GetService("RunService").Heartbeat:Fire(1.2)
local _, hy3 = mNeck.Transform:ToOrientation()
check(math.abs(math.deg(hy3) - 18) < 1, "loop embrulha (1.2s -> t=0.2 -> 18deg)")
local st = serverInvoke("AnimStop", {})
local _, hy4 = mNeck.Transform:ToOrientation()
check(st.stopped and math.abs(math.deg(hy4)) < 1e-6, "AnimStop volta ao repouso")
local plT = serverInvoke("AnimPlay", { id = seqP, rigId = rigId, animationId = "rbxassetid://123" })
check(plT.trackLoaded == true, "animationId carrega track real (LoadAnimation)")
serverInvoke("AnimStop", {})
serverInvoke("AnimPoseSet", { id = seqP, time = 0, part = "Head", easingStyle = "Elastic" })
local scA = serverInvoke("AnimScrub", { id = seqP, rigId = rigId, time = 0.5 })
check(scA.approx == true, "Elastic -> approx=true (preview linear honesto)")
serverInvoke("AnimPoseSet", { id = seqP, time = 0, part = "Head", easingStyle = "Constant", easingDir = "InOut" })
serverInvoke("AnimScrub", { id = seqP, rigId = rigId, time = 0.4 })
local _, hyC0 = mNeck.Transform:ToOrientation()
serverInvoke("AnimScrub", { id = seqP, rigId = rigId, time = 0.6 })
local _, hyC1 = mNeck.Transform:ToOrientation()
check(math.abs(math.deg(hyC0)) < 1e-6 and math.abs(math.deg(hyC1) - 90) < 1e-6,
	"Constant/InOut: snap (0.4=repouso, 0.6=full)")
serverInvoke("AnimPoseSet", { id = seqP, time = 0, part = "Head", easingStyle = "Linear" })
serverInvoke("AnimStop", {})

print("\n== AN15-S6: IK ==")
local tgt = Instance.new("Part"); tgt.Name = "IKTarget"; tgt.Parent = ws
local tgtId = serverInvoke("Identify", { object = tgt }).id
local ik = serverInvoke("AnimIK", { rigId = rigId, endName = "RightArm", targetId = tgtId })
check(ik.node and ik.node.name == "ArkherIK", "AnimIK cria IKControl")
local ikInst = hum:FindFirstChild("ArkherIK")
check(ikInst and ikInst.Weight == 1 and ikInst.Enabled == true, "IK defaults (w=1, on)")
check(ikInst.ChainRoot and ikInst.ChainRoot.Name == "HumanoidRootPart", "ChainRoot default = HRP")
serverInvoke("AnimIK", { rigId = rigId, endName = "RightArm", targetId = tgtId, weight = 0.5, enabled = false })
check(ikInst.Weight == 0.5 and ikInst.Enabled == false, "IK reconfigura (sem duplicar)")
check(serverInvoke("AnimIK", { rigId = rigId, endName = "Nope", targetId = tgtId }).error ~= nil,
	"IK end inexistente falha")
check(serverInvoke("AnimIK", { rigId = rigId, endName = "Head", targetId = rigId }).error ~= nil,
	"IK target nao-part falha")
check(serverInvoke("AnimIK", { rigId = rigId, endName = "Head", targetId = tgtId, type = "X" }).error ~= nil,
	"IK type invalido falha")

print("\n== AN15-S7: export/import JSON ==")
local exA = Http:JSONDecode(serverInvoke("AnimExport", { id = seqA }).json)
check(exA.v == 1 and #exA.keys == 1, "export: v=1, 1 key")
local hp, hpPath = nil, nil
for _, p in ipairs(exA.keys[1].poses) do
	if p.path[#p.path] == "Head" then hp, hpPath = p, p.path end
end
check(hpPath and #hpPath == 3 and hpPath[1] == "HumanoidRootPart" and hpPath[2] == "Torso",
	"hierarquia preservada (HRP/Torso/Head)")
local rt = serverInvoke("AnimImport", { json = serverInvoke("AnimExport", { id = seqA }).json, name = "SeqRT" })
check(rt.keys == 1 and rt.node.id ~= seqA, "round-trip: mesma key, novo id")
local exRT = Http:JSONDecode(serverInvoke("AnimExport", { id = rt.node.id }).json)
local hpRT = nil
for _, p in ipairs(exRT.keys[1].poses) do
	if p.path[#p.path] == "Head" then hpRT = p end
end
check(hpRT and math.abs(hpRT.cf[6] - 1) < 1e-6 and hpRT.es == "Bounce", "round-trip: cf+easing iguais")
check(#exRT.keys[1].poses == #exA.keys[1].poses, "round-trip: mesma contagem de poses")
check(serverInvoke("AnimImport", { json = "{nao json" }).error ~= nil, "JSON invalido falha")
check(serverInvoke("AnimImport", { json = "" }).error ~= nil, "JSON vazio falha")
check(serverInvoke("AnimImport", { json = '{"keys":[{"time":-5,"poses":[]}]}' }).error ~= nil,
	"key time invalido falha")

-- ============ CLIENT ============
local UIS = game:GetService("UserInputService")
local cam = Instance.new("Camera"); cam.CFrame = CFrame.new(0, 30, 60)
ws.CurrentCamera = cam
cam.ScreenPointToRay = function(self, x, y)
	return { Origin = Vector3.new(0, 30, 60), Direction = Vector3.new(0, -1, 0) }
end
local hitInst, hitPos = nil, Vector3.new(0, 0, 0)
ws.Raycast = function(self, o, d)
	if not hitInst then return nil end
	return { Instance = hitInst, Position = hitPos }
end
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src15 = io.open("studio-completo/scripts/15_Animator.lua"):read("*a")
assert(pcall(assert(loadstring(src15, "[15]"))), "15 nao carregou")
local AN = _G.ArkherAnimator
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== AN15-C1: boot/open/close ==")
check(AN ~= nil and AN.isOpen() == false, "15 expoe _G.ArkherAnimator fechado")
check(find("AN5_Rail").Visible == false and find("M_AN").Visible == false, "AN5+M_AN ocultos no boot")
check(find("AN5_StatL").Text:find("keys") ~= nil, "status boot mostra keys")
find("TE3_Rail").Visible = true; find("VP3_Rail").Visible = true; find("MD4_Rail").Visible = true
AN.open()
check(AN.isOpen() and find("AN5_Rail").Visible and find("AN5_IO").Visible, "open mostra AN5")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("VP3_Rail").Visible == false
	and find("MD4_Rail").Visible == false, "open exclui TE3/VP3/MD4")
check(lastMsg():find("Animator open") ~= nil, "open loga mensagem")
AN.close()
check(find("AN5_Rail").Visible == false and find("T2_Panel").Visible, "close restaura desktop")
AN.open()

print("\n== AN15-C2: new + adopt rig/seq ==")
click("AN5_New")
check(AN.state().seqId ~= nil and #AN.state().keys == 0, "New sem rig: seq vazia (0 keys)")
check(find("AN5_Info").Text:find("Animacao") ~= nil, "Info mostra nome da seq")
hitInst, hitPos = torso, Vector3.new(0, 0, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
check(#AN.state().joints == 3 and AN.state().rigName == "TestRig", "clique Select adota rig (3 juntas)")
check(find("AN5_J_Name").Text == "Head", "J_Name mostra 1a junta")
local sv = Instance.new("ObjectValue"); sv.Name = "SelectedInstance"
sv.Value = game:GetService("ServerStorage"):FindFirstChild("SeqA")
sv.Parent = runtime
click("AN5_Adopt")
check(AN.state().seqName == "SeqA" and #AN.state().keys == 1, "Adopt via SelectedInstance (SeqA, 1 key)")
sv.Value = p0
click("AN5_Adopt")
check(lastMsg():find("Model or KeyframeSequence") ~= nil, "Adopt em Part avisa")
click("AN5_New")
check(AN.state().seqName == "Animacao", "New com rig: seq nova")

print("\n== AN15-C3: pose steppers + pick ==")
click("AN5_R_XP"); click("AN5_R_XP")
check(find("AN5_R_XV").Text == "30", "stepper pend 30deg")
click("AN5_R_Apply")
local oxA = mNeck.Transform:ToOrientation()
check(math.abs(math.deg(oxA) - 30) < 1e-6, "Apply poe Head 30deg no server")
click("AN5_R_Reset")
local oxR = mNeck.Transform:ToOrientation()
check(math.abs(math.deg(oxR)) < 1e-6 and find("AN5_R_XV").Text == "0", "Reset zera (server+label)")
click("AN5_R_XP")
click("AN5_R_Apply")
click("AN5_T_Pose")
hitInst, hitPos = rarm, Vector3.new(0, 0, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
check(find("AN5_J_Name").Text == "RightArm", "Pose click pega junta (RightArm)")
click("AN5_J_Prev")
check(find("AN5_J_Name").Text == "Head", "J_Prev volta p/ Head")

print("\n== AN15-C4: timeline + keys ==")
click("AN5_K_Del")
check(#AN.state().keys == 0, "K_Del remove K0 do New")
click("AN5_K_Add")
check(#AN.state().keys == 1, "K_Add @0 (captura)")
for i = 1, 15 do click("AN5_F_P") end
check(find("AN5_TLabel").Text == "0:15", "15 frames -> 0:15")
click("AN5_K_Add")
check(#AN.state().keys == 2, "K_Add @0.5")
click("AN5_K_Next")
check(AN.state().keyIdx == 2 and find("AN5_TLabel").Text == "0:15", "K_Next pula p/ key (scrub)")
click("AN5_K_Prev")
check(AN.state().keyIdx == 1, "K_Prev volta")
click("AN5_Play")
check(AN.state().playing and find("AN5_Play").Text == "PAUSE", "Play toca")
game:GetService("RunService").Heartbeat:Fire(0.1)
check(find("AN5_TLabel").Text == "0:03", "Heartbeat client avanca label (0.1s)")
click("AN5_Stop")
check(AN.state().playing == false and find("AN5_TLabel").Text == "0:00"
	and find("AN5_Play").Text == "PLAY", "Stop zera")
click("AN5_Loop")
check(find("AN5_Loop").Text == "LOOP ON", "Loop ON")
click("AN5_S_P")
check(find("AN5_SV").Text == "1.5x", "Speed 1.5x")

print("\n== AN15-C5: easing/weight ==")
click("AN5_K_Next")
click("AN5_E_S")
check(find("AN5_E_S").Text == "CON", "E_S cicla p/ Constant")
click("AN5_E_D")
check(find("AN5_E_D").Text == "IN", "E_D cicla p/ In")
click("AN5_W_P")
local exC = Http:JSONDecode(serverInvoke("AnimExport", { id = AN.state().seqId }).json)
local hpC = nil
for _, k in ipairs(exC.keys) do
	if math.abs(k.time - 0.5) < 1e-4 then
		for _, p in ipairs(k.poses) do
			if p.path[#p.path] == "Head" then hpC = p end
		end
	end
end
check(hpC and hpC.es == "Constant" and hpC.ed == "In" and hpC.w == 1.5, "easing/weight no server")
check(hpC and math.abs(hpC.cf[8] - 0.966) < 0.01, "CFrame capturado preservado (rotX15)")

print("\n== AN15-C6: IO ==")
click("AN5_IO_Export")
check(find("AN5_IO_Text").Text:find('"v":1') ~= nil, "Export preenche textbox (JSON v=1)")
check(find("AN5_IO_Stat").Text:find("anim 2 keys") ~= nil, "Export stat 2 keys")
find("AN5_IO_Text").Text = serverInvoke("AnimExport", { id = seqA }).json
click("AN5_IO_Import")
check(#AN.state().keys == 1 and AN.state().seqName == "SeqA", "Import adota SeqA")
find("AN5_IO_Text").Text = ""
click("AN5_IO_Import")
check(lastMsg():find("paste ANIM") ~= nil, "Import vazio avisa")

print("\n== AN15-C7: mobile ==")
plat = "Mobile"
AN.close()
AN.open()
check(find("M_AN").Visible == true, "Mobile: strip M_AN visivel")
click("M_AN_New")
check(AN.state().seqName == "Animacao" and #AN.state().keys == 1, "M_AN_New cria+captura K0")
for i = 1, 5 do click("AN5_F_P") end
click("M_AN_Key")
check(#AN.state().keys == 2, "M_AN_Key adiciona")
click("M_AN_Play")
check(AN.state().playing == true, "M_AN_Play toca")
click("M_AN_Play")
check(AN.state().playing == false, "M_AN_Play para")
AN.close()
check(find("M_AN").Visible == false, "close esconde M_AN")
plat = "PC"

print("\nANIM15: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
