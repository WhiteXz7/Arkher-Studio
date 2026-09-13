-- Testa R16b Script Studio: server ScriptGet + 21_Script (lua/py/blocos/output).
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
for _, n in ipairs({ "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status", "M_SC" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "WO9_Rail", "HO10_Rail", "PL12_Rail" }) do
	W(shell, "Frame", n, true)
end
for _, n in ipairs({ "SC11_L_NewS", "SC11_L_NewL", "SC11_L_NewM", "SC11_L_Load", "SC11_L_Del",
	"SC11_L_Prev", "SC11_L_Next", "SC11_M_Lua", "SC11_M_Py", "SC11_M_Blk",
	"SC11_E_Save", "SC11_E_Run", "SC11_E_Stop",
	"SC11_P_Comp", "SC11_P_Save", "SC11_B_Ev", "SC11_B_Act", "SC11_B_If",
	"SC11_B_Undo", "SC11_B_Comp", "SC11_B_Save", "SC11_O_Clear", "SC11_O_Err",
	"SC11_Close", "M_SC_Save", "M_SC_Run", "M_SC_Stop" }) do
	W(shell, "TextButton", n)
end
for _, n in ipairs({ "SC11_L_Info", "SC11_E_Info", "SC11_P_Info", "SC11_B_Chain",
	"SC11_B_Info", "SC11_O_Log", "SC11_StatL", "M_SC_Hint" }) do
	W(shell, "TextLabel", n)
end
W(shell, "TextBox", "SC11_E_Code")
W(shell, "TextBox", "SC11_P_Code")
W(shell, "TextBox", "SC11_B_Param")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_21_Script"; script.Parent = gui

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

print("\n== SC21-S1: ScriptGet server ==")
local snap0 = serverInvoke("Snapshot", {})
local sssId, baseId = nil, nil
for _, nd in ipairs(snap0.nodes) do
	if nd.class == "ServerScriptService" then sssId = nd.id end
	if nd.name == "Baseplate" then baseId = nd.id end
end
check(sssId ~= nil, "Snapshot expoe SSS")
local cr = serverInvoke("Create", { class = "Script", parentId = sssId, name = "SC21_Srv" })
check(cr.node and cr.node.id ~= nil, "Create Script no SSS")
local setR = serverInvoke("ScriptSet", { id = cr.node.id, source = "print('srv-ok')" })
check(setR.len == 15, "ScriptSet grava (len 15)")
local getR = serverInvoke("ScriptGet", { id = cr.node.id })
check(getR.source == "print('srv-ok')" and getR.class == "Script" and getR.name == "SC21_Srv", "ScriptGet roundtrip")
local badGet = serverInvoke("ScriptGet", { id = baseId })
check(badGet.error ~= nil, "ScriptGet em Part recusa (" .. tostring(badGet.error):sub(1, 30) .. ")")
local lst = serverInvoke("ScriptList", {})
local foundSrv = false
for _, sc in ipairs(lst.scripts or {}) do
	if sc.name == "SC21_Srv" then foundSrv = true end
end
check(foundSrv, "ScriptList lista o script")

-- ============ CLIENT ============
local plat = "PC"
_G.ArkherInput = { platform = function() return plat end }
local src21 = io.open("studio-completo/scripts/21_Script.lua"):read("*a")
assert(pcall(assert(loadstring(src21, "[21]"))), "21 nao carregou")
local SC = _G.ArkherScript
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end
local function enabledOf(id)
	local r = serverInvoke("Select", { id = id })
	for _, f in ipairs(r.properties.fields or {}) do
		if f.key == "Enabled" then return f.value end
	end
	return nil
end

print("\n== SC21-C1: boot/open/close ==")
check(SC ~= nil and SC.isOpen() == false, "21 expoe _G.ArkherScript fechado")
find("TE3_Rail").Visible = true; find("HO10_Rail").Visible = true; find("PL12_Rail").Visible = true
SC.open()
check(SC.isOpen() and find("SC11_List").Visible, "open mostra SC11")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("HO10_Rail").Visible == false and find("PL12_Rail").Visible == false, "open exclui editores")
check(find("SC11_StatL").Text:find("scripts") ~= nil, "open carrega lista")
SC.close()
check(find("SC11_Rail").Visible == false and find("T2_Panel").Visible, "close restaura")
SC.open()

print("\n== SC21-C2: new/load/edit/run ==")
local n0 = #SC.state().scripts
click("SC11_L_NewS")
check(sawMsg("Created") and #SC.state().scripts == n0 + 1, "NewS cria Script")
click("SC11_L_NewM")
check(#SC.state().scripts == n0 + 2, "NewM cria ModuleScript")
-- carrega o ultimo (Module) e edita
SC.state().idx = #SC.state().scripts
click("SC11_L_Load")
check(sawMsg("Loaded"), "Load carrega fonte")
find("SC11_E_Code").Text = "print('edit-ok')"
click("SC11_E_Save")
check(sawMsg("Saved"), "Save grava")
local back = serverInvoke("ScriptGet", { id = SC.state().selId })
check(back.source == "print('edit-ok')", "fonte persistiu no server")
click("SC11_E_Run")
check(enabledOf(SC.state().selId) == true, "Run liga Enabled")
click("SC11_E_Stop")
check(enabledOf(SC.state().selId) == false, "Stop desliga Enabled")
click("SC11_L_Del")
check(sawMsg("Deleted"), "Del apaga")

print("\n== SC21-C3: modos ==")
click("SC11_M_Py")
check(SC.state().mode == "py" and find("SC11_Py").Visible and not find("SC11_Edit").Visible, "modo py")
click("SC11_M_Blk")
check(SC.state().mode == "blk" and find("SC11_Blk").Visible and not find("SC11_Py").Visible, "modo blk")
click("SC11_M_Lua")
check(SC.state().mode == "lua" and find("SC11_Edit").Visible, "modo lua")

print("\n== SC21-C4: pyCompile honesto ==")
local py = SC.pyCompile
local lua1 = py("print('oi')")
check(lua1 and lua1:find("print%('oi'%)") ~= nil, "print passa")
local lua2 = py("x = 1\nif x > 0:\n    print(x)\nelse:\n    print(0)")
check(lua2 and lua2:find("then") and lua2:find("else") and lua2:find("end"), "if/else vira then/else/end")
local lua3 = py("for i in range(3):\n    print(i)")
check(lua3 and lua3:find("for i = 0, 2 do") ~= nil, "for-range vira for numerico")
local lua4 = py("def f(a):\n    return a")
check(lua4 and lua4:find("local function f%(a%)") ~= nil, "def vira local function")
local bad1, e1 = py("while True:\n    continue")
check(bad1 == nil and e1:find("continue") ~= nil, "continue recusado (" .. tostring(e1):sub(1, 40) .. ")")
local bad2, e2 = py("if x:\n  print(x)")
check(bad2 == nil and e2:find("indent") ~= nil or bad2 == nil and e2 ~= nil, "indent 2sp recusado (" .. tostring(e2):sub(1, 40) .. ")")
find("SC11_P_Code").Text = "print('via-ui')"
click("SC11_P_Comp")
check(sawMsg("compiled"), "P_Comp compila via UI")

print("\n== SC21-C5: blocos compilam ==")
local blk = SC.blkCompile
local b0, be0 = blk({})
check(b0 == nil and be0:find("event") ~= nil, "bloco vazio exige evento")
local b1 = blk({ { t = "ev", kind = "Touched" }, { t = "act", kind = "print", param = "tocou" } })
check(b1 and b1:find("Touched") and b1:find("tocou"), "ev+act gera handler")
local b2 = blk({ { t = "ev", kind = "Click" }, { t = "if", cond = "ok" }, { t = "act", kind = "wait", param = "2" } })
check(b2 and b2:find("if ok then") and b2:find("task.wait%(2%)"), "if envolve proxima acao")
click("SC11_B_Ev")
click("SC11_B_Ev")
find("SC11_B_Param").Text = "ui--blk"
click("SC11_B_Act")
click("SC11_B_Comp")
check(sawMsg("compiled") and find("SC11_B_Chain").Text:find("chain:") ~= nil, "B_Comp compila via UI")
click("SC11_B_Undo")
click("SC11_B_Comp")

print("\n== SC21-C6: output LogService ==")
local LS = game:GetService("LogService")
LS.MessageOut:Fire("info-1", { Name = "MessageOutput" })
check(find("SC11_O_Log").Text:find("info%-1") ~= nil, "log mostra MessageOut")
LS.MessageOut:Fire("boom-2", { Name = "MessageError" })
click("SC11_O_Err")
check(find("SC11_O_Log").Text:find("boom%-2") ~= nil and find("SC11_O_Log").Text:find("info%-1") == nil, "errOnly filtra")
click("SC11_O_Err")
click("SC11_O_Clear")
check(find("SC11_O_Log").Text == "(log)", "Clear limpa")

print("\n== SC21-C7: mobile + honestidade ==")
plat = "Mobile"
SC.close(); SC.open()
check(find("M_SC").Visible, "M_SC visivel no mobile")
SC.state().selId = nil
click("M_SC_Save")
check(lastMsg():find("load first") ~= nil, "M save sem load avisa")
click("SC11_E_Run")
check(lastMsg():find("load first") ~= nil, "Run sem load avisa")
plat = "PC"
SC.close(); SC.open()

print(("\nSC21: %d ok, %d falhas"):format(pass, fail))
if fail > 0 then os.exit(1) end
