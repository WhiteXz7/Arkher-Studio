-- Testa R12 Modeler: server Mesh* (primitivas/winding/undo/OBJ) + client 14_Modeler.
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
for _, n in ipairs({ "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status", "M_MD" }) do
	W(shell, "Frame", n, false)
end
for _, n in ipairs({ "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
	"TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "TE3_Rail", "VP3_Rail" }) do W(shell, "Frame", n, true) end
for _, n in ipairs({ "MD4_T_Select", "MD4_T_Move", "MD4_T_Near", "MD4_Close",
	"MD4_P_Box", "MD4_P_Plane", "MD4_P_Wedge", "MD4_P_Cyl8", "MD4_New", "MD4_Adopt",
	"MD4_V_Prev", "MD4_V_Next", "MD4_V_XM", "MD4_V_XP", "MD4_V_YM", "MD4_V_YP",
	"MD4_V_ZM", "MD4_V_ZP", "MD4_V_Apply", "MD4_V_Del", "MD4_S_IM", "MD4_S_IP",
	"MD4_Smooth", "MD4_M_X", "MD4_M_Y", "MD4_M_Z", "MD4_IO_Export", "MD4_IO_Import",
	"M_MD_New", "M_MD_Smooth" }) do W(shell, "TextButton", n) end
for _, n in ipairs({ "MD4_Info", "MD4_V_Id", "MD4_V_XV", "MD4_V_YV", "MD4_V_ZV",
	"MD4_V_Hint", "MD4_S_IV", "MD4_IO_Stat", "MD4_StatL", "M_MD_Hint" }) do W(shell, "TextLabel", n) end
W(shell, "TextBox", "MD4_IO_Text")

local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local menusBus = Instance.new("BindableFunction"); menusBus.Name = "MenusBus"; menusBus.Parent = runtime
script = Instance.new("LocalScript"); script.Name = "Arkher_14_Modeler"; script.Parent = gui

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

print("\n== MD14-S1: primitivas + info ==")
local rBox = serverInvoke("MeshNew", { primitive = "box", size = 4 })
check(rBox.ok and rBox.verts == 8 and rBox.faces == 12, "box: 8v/12f")
check(rBox.node and rBox.node.name == "Mesh_box", "box: nome default Mesh_box")
local boxId = rBox.node.id
local rPlane = serverInvoke("MeshNew", { primitive = "plane", size = 4 })
check(rPlane.verts == 4 and rPlane.faces == 2, "plane: 4v/2f")
local rWedge = serverInvoke("MeshNew", { primitive = "wedge", size = 4 })
check(rWedge.verts == 6 and rWedge.faces == 8, "wedge: 6v/8f")
local wedgeId = rWedge.node.id
local rCyl = serverInvoke("MeshNew", { primitive = "cyl8", size = 4 })
check(rCyl.verts == 16 and rCyl.faces == 28, "cyl8: 16v/28f (16 lat + 6 + 6 fans)")
local cylId = rCyl.node.id
local rBad = serverInvoke("MeshNew", { primitive = "torus" })
check(rBad.error and rBad.error:find("box/plane") ~= nil, "primitiva invalida rejeitada")
local rBig = serverInvoke("MeshNew", { primitive = "box", size = 100000 })
local iBig = serverInvoke("MeshInfo", { id = rBig.node.id })
check(iBig.max and iBig.max.x == 256, "size clampado em 512 (max.x=256)")
local rTiny = serverInvoke("MeshNew", { primitive = "box", size = 0.01 })
local iTiny = serverInvoke("MeshInfo", { id = rTiny.node.id })
check(iTiny.max and math.abs(iTiny.max.x - 0.25) < 1e-6, "size minimo 0.5 (max.x=0.25)")
local iBox = serverInvoke("MeshInfo", { id = boxId })
check(iBox.verts == 8 and iBox.min.x == -2 and iBox.max.x == 2
	and iBox.min.y == -2 and iBox.max.z == 2, "MeshInfo box: bbox +-2")
local rNamed = serverInvoke("MeshNew", { primitive = "box", name = "Nave" })
check(rNamed.node.name == "Nave", "nome custom respeitado")

print("\n== MD14-S2: winding (normais p/ fora, prova geometrica) ==")
local function parseOBJ(obj)
	local V, F = {}, {}
	for line in (obj .. "\n"):gmatch("([^\n]*)\n") do
		local tag, rest = line:match("^%s*(%S+)%s*(.-)%s*$")
		if tag == "v" then
			local x, y, z = rest:match("^(%S+)%s+(%S+)%s+(%S+)")
			V[#V + 1] = { tonumber(x), tonumber(y), tonumber(z) }
		elseif tag == "f" then
			local f = {}
			for tok in rest:gmatch("%S+") do f[#f + 1] = tonumber(tok:match("^(%d+)")) end
			F[#F + 1] = f
		end
	end
	return V, F
end
local function allOutward(obj)
	local V, F = parseOBJ(obj)
	local cx, cy, cz = 0, 0, 0
	for _, v in ipairs(V) do cx, cy, cz = cx + v[1], cy + v[2], cz + v[3] end
	cx, cy, cz = cx / #V, cy / #V, cz / #V
	for _, f in ipairs(F) do
		local a, b, c = V[f[1]], V[f[2]], V[f[3]]
		local ux, uy, uz = b[1] - a[1], b[2] - a[2], b[3] - a[3]
		local wx, wy, wz = c[1] - a[1], c[2] - a[2], c[3] - a[3]
		local nx, ny, nz = uy * wz - uz * wy, uz * wx - ux * wz, ux * wy - uy * wx
		local gx, gy, gz = (a[1] + b[1] + c[1]) / 3 - cx,
			(a[2] + b[2] + c[2]) / 3 - cy, (a[3] + b[3] + c[3]) / 3 - cz
		if nx * gx + ny * gy + nz * gz <= 1e-9 then return false, #F end
	end
	return true, #F
end
local exBox = serverInvoke("MeshExportOBJ", { id = boxId })
check(exBox.obj:find("# Arkher") == 1 and exBox.verts == 8 and exBox.faces == 12,
	"export box: header + contagens")
local okW, nW = allOutward(exBox.obj)
check(okW, "box: " .. nW .. "/12 faces com normal p/ fora")
local okG, nG = allOutward(serverInvoke("MeshExportOBJ", { id = wedgeId }).obj)
check(okG, "wedge: " .. nG .. "/8 faces com normal p/ fora")
local okC, nC = allOutward(serverInvoke("MeshExportOBJ", { id = cylId }).obj)
check(okC, "cyl8: " .. nC .. "/28 faces com normal p/ fora")
local pV, pF = parseOBJ(serverInvoke("MeshExportOBJ", { id = rPlane.node.id }).obj)
local pa, pb, pc = pV[pF[1][1]], pV[pF[1][2]], pV[pF[1][3]]
local pny = (pb[3] - pa[3]) * (pc[1] - pa[1]) - (pb[1] - pa[1]) * (pc[3] - pa[3])
check(pny > 0, "plane: normal +Y")

print("\n== MD14-S3: select/verts ==")
local sel = serverInvoke("MeshSelect", { id = boxId })
check(sel.verts == 8 and sel.faces == 12 and sel.msg == "Mesh adotada.", "MeshSelect adota box")
local wsId = serverInvoke("Hello", {}).roots and nil or nil
local selWs = serverInvoke("MeshSelect", { id = "n1" })
check(selWs.error ~= nil, "MeshSelect em nao-MeshPart falha")
local vv = serverInvoke("MeshVerts", { id = boxId })
check(#vv.verts == 8 and vv.verts[1].vid and vv.verts[1].x == -2, "MeshVerts: 8 + campos")
local vBad = serverInvoke("MeshVerts", { id = "n999999" })
check(vBad.error ~= nil, "MeshVerts id invalido falha")

print("\n== MD14-S4: move/delete + undo/redo ==")
local vid1 = vv.verts[1].vid
local mv = serverInvoke("MeshMoveVert", { id = boxId, vid = vid1, x = 10, y = 20, z = 30 })
check(mv.moved and mv.refreshed == true, "MeshMoveVert move + refresh de colisao")
local function vertPos(id, vid)
	for _, v in ipairs(serverInvoke("MeshVerts", { id = id }).verts) do
		if v.vid == vid then return v end
	end
end
local p1 = vertPos(boxId, vid1)
check(p1.x == 10 and p1.y == 20 and p1.z == 30, "posicao nova persistida")
local mvBad = serverInvoke("MeshMoveVert", { id = boxId, vid = vid1, x = 1e9, y = 0, z = 0 })
check(mvBad.error and mvBad.error:find("limite") ~= nil, "move fora do limite rejeitado")
serverInvoke("Undo", {})
local pU = vertPos(boxId, vid1)
check(pU.x == -2 and pU.y == -2 and pU.z == -2, "Undo restaura vertice")
serverInvoke("Redo", {})
local pR = vertPos(boxId, vid1)
check(pR.x == 10, "Redo reaplica vertice")
serverInvoke("Undo", {})
local rDel = serverInvoke("MeshNew", { primitive = "box", size = 4 })
local delId, delVid = rDel.node.id, serverInvoke("MeshVerts", { id = rDel.node.id }).verts[1].vid
local dl = serverInvoke("MeshDeleteVert", { id = delId, vid = delVid })
local iDel = serverInvoke("MeshInfo", { id = delId })
check(dl.deleted and dl.faces == 6 and iDel.verts == 7 and iDel.faces == 6,
	"delete canto do box: -1v -6f")
check(dl.msg and dl.msg:find("vid pode mudar") ~= nil, "delete avisa vid-honesto")
serverInvoke("Undo", {})
local iDelU = serverInvoke("MeshInfo", { id = delId })
check(iDelU.verts == 8 and iDelU.faces == 12, "Undo restaura geometria (8v/12f)")
serverInvoke("Redo", {})
local iDelR = serverInvoke("MeshInfo", { id = delId })
check(iDelR.verts == 7 and iDelR.faces == 6, "Redo refaz delete")
serverInvoke("Undo", {})
local iDelU2 = serverInvoke("MeshInfo", { id = delId })
check(iDelU2.verts == 8 and iDelU2.faces == 12, "ciclo Undo2 apos Redo restaura (vid rastreado)")
local dlBad = serverInvoke("MeshDeleteVert", { id = delId, vid = 424242 })
check(dlBad.error ~= nil, "delete vid inexistente falha")

print("\n== MD14-S5: smooth/mirror ==")
local rSm = serverInvoke("MeshNew", { primitive = "box", size = 4 })
local smId = rSm.node.id
local before = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = smId }).verts) do before[v.vid] = v end
local sm = serverInvoke("MeshSmooth", { id = smId, iters = 1, lambda = 0.5 })
local after = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = smId }).verts) do after[v.vid] = v end
local movedSm = false
for vid, v in pairs(after) do
	if math.abs(v.x - before[vid].x) > 1e-6 then movedSm = true break end
end
check(sm.smoothed and movedSm, "smooth laplaciano desloca verts")
check(serverInvoke("MeshInfo", { id = smId }).faces == 12, "smooth preserva faces")
local smBig = serverInvoke("MeshSmooth", { id = smId, iters = 99 })
check(smBig.iters == 10, "smooth clamp iters em 10")
local rMr = serverInvoke("MeshNew", { primitive = "box", size = 4 })
local mrId = rMr.node.id
local mBefore = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = mrId }).verts) do mBefore[v.vid] = v.x end
local mr = serverInvoke("MeshMirror", { id = mrId, axis = "X" })
local mAfter = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = mrId }).verts) do mAfter[v.vid] = v.x end
local flipOk = mr.mirrored and mr.axis == "X"
for vid, x in pairs(mAfter) do
	if math.abs(x + mBefore[vid]) > 1e-6 then flipOk = false break end
end
check(flipOk, "mirror X inverte sinais")
serverInvoke("MeshMirror", { id = mrId, axis = "X" })
local mBack = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = mrId }).verts) do mBack[v.vid] = v.x end
local backOk = true
for vid, x in pairs(mBack) do
	if math.abs(x - mBefore[vid]) > 1e-6 then backOk = false break end
end
check(backOk, "mirror 2x = identidade")
check(serverInvoke("MeshMirror", { id = mrId, axis = "W" }).error ~= nil, "mirror eixo invalido falha")
serverInvoke("Undo", {})
local mU = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = mrId }).verts) do mU[v.vid] = v.x end
local uOk = true
for vid, x in pairs(mU) do
	if math.abs(x + mBefore[vid]) > 1e-6 then uOk = false break end
end
check(uOk, "Undo desfaz 1 mirror")

print("\n== MD14-S6: OBJ round-trip + limites ==")
local nv, nf = 0, 0
for line in (exBox.obj .. "\n"):gmatch("([^\n]*)\n") do
	if line:match("^v ") then nv = nv + 1 end
	if line:match("^f ") then nf = nf + 1 end
end
check(nv == 8 and nf == 12, "OBJ texto: 8v/12f")
local rt = serverInvoke("MeshImportOBJ", { obj = exBox.obj, name = "RT" })
check(rt.verts == 8 and rt.faces == 12 and rt.node.id ~= boxId, "round-trip: mesma geo, novo id")
check(serverInvoke("MeshInfo", { id = rt.node.id }).faces == 12, "round-trip registrado")
local quad = "v 0 0 0\nv 4 0 0\nv 4 0 4\nv 0 0 4\nf 1 2 3 4\n"
local rq = serverInvoke("MeshImportOBJ", { obj = quad })
check(rq.verts == 4 and rq.faces == 2, "quad vira 2 tris")
local neg = "v 0 0 0\nv 1 0 0\nv 0 1 0\nf -3 -2 -1\n"
local rn = serverInvoke("MeshImportOBJ", { obj = neg })
check(rn.verts == 3 and rn.faces == 1, "indices negativos funcionam")
check(serverInvoke("MeshImportOBJ", { obj = "v 0 0 0\nf 1 2 3\n" }).error ~= nil,
	"face fora do range falha")
check(serverInvoke("MeshImportOBJ", { obj = "" }).error ~= nil, "OBJ vazio falha")
check(serverInvoke("MeshImportOBJ", { obj = "v 1 2\nf 1 1 1\n" }).error ~= nil, "linha v invalida falha")
check(serverInvoke("MeshImportOBJ", { obj = "v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nv 0 0 1\nf 1 2 3 4 5\n" }).error ~= nil,
	"pentagono rejeitado")
local big = {}
for i = 1, 5001 do big[#big + 1] = "v 0 0 0" end
big[#big + 1] = "f 1 2 3"
check(serverInvoke("MeshImportOBJ", { obj = table.concat(big, "\n") }).error ~= nil,
	"limite 5000 verts enforced")

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
local src14 = io.open("studio-completo/scripts/14_Modeler.lua"):read("*a")
assert(pcall(assert(loadstring(src14, "[14]"))), "14 nao carregou")
local MD = _G.ArkherModeler
local function find(n) return shell:FindFirstChild(n, true) end
local function click(n) find(n).Activated:Fire() end

print("\n== MD14-C1: boot/open/close ==")
check(MD ~= nil and MD.isOpen() == false, "14 expoe _G.ArkherModeler fechado")
check(find("MD4_Rail").Visible == false and find("M_MD").Visible == false, "MD4+M_MD ocultos no boot")
check(find("MD4_StatL").Text:find("no%-mesh") ~= nil, "status boot: no-mesh")
find("TE3_Rail").Visible = true; find("VP3_Rail").Visible = true
MD.open()
check(MD.isOpen() and find("MD4_Rail").Visible and find("MD4_IO").Visible, "open mostra MD4")
check(find("T2_Panel").Visible == false, "open esconde desktop")
check(find("TE3_Rail").Visible == false and find("VP3_Rail").Visible == false, "open exclui TE3/VP3")
check(lastMsg():find("Modeler open") ~= nil, "open loga mensagem")
MD.close()
check(find("MD4_Rail").Visible == false and find("T2_Panel").Visible, "close restaura desktop")
MD.open()

print("\n== MD14-C2: prims + new ==")
click("MD4_P_Wedge")
check(MD.state().prim == "wedge", "seletor Wedge")
click("MD4_P_Box")
check(MD.state().prim == "box", "seletor Box")
click("MD4_New")
local st = MD.state()
check(st.meshId ~= nil and #st.verts == 8, "New cria box (8 verts no estado)")
check(find("MD4_StatL").Text:find("loaded") ~= nil, "status: loaded")
check(find("MD4_V_Id").Text == "vid " .. tostring(st.verts[1].vid), "V_Id mostra vid 1")
check(find("MD4_Info").Text:find("8 verts 12 faces") ~= nil, "Info: 8 verts 12 faces")
check(lastMsg():find("criada") ~= nil, "New loga msg do server")
local mark = ws:FindFirstChild("ArkherVertMark")
check(mark ~= nil and mark.Anchored and mark.CanQuery == false, "marcador 3D ancorado sem query")
local uiBoxId = st.meshId

print("\n== MD14-C3: ciclo + steppers + apply/del ==")
click("MD4_V_Next")
check(MD.state().vertIdx == 2, "Next -> 2")
click("MD4_V_Prev")
check(MD.state().vertIdx == 1, "Prev -> 1")
click("MD4_V_Prev")
check(MD.state().vertIdx == 8, "Prev no 1 embrulha p/ 8")
click("MD4_V_Next")
local v0 = MD.state().verts[1]
click("MD4_V_XP"); click("MD4_V_XP")
check(find("MD4_V_XV").Text == string.format("%.2f", v0.x + 1), "stepper pend +1.0 no label")
click("MD4_V_Apply")
local vSrv = vertPos(uiBoxId, v0.vid)
check(math.abs(vSrv.x - (v0.x + 1)) < 1e-6, "Apply persiste no server")
check(find("MD4_V_XV").Text == string.format("%.2f", v0.x + 1), "Apply zera pend (label=base)")
check(lastMsg():find("Vertex moved") ~= nil, "Apply loga")
click("MD4_V_Del")
check(#MD.state().verts == 7, "Del remove vert (estado)")
check(serverInvoke("MeshInfo", { id = uiBoxId }).verts == 7, "Del remove vert (server)")
check(lastMsg():find("deletado") ~= nil, "Del loga msg")

print("\n== MD14-C4: tools + clique select/near ==")
click("MD4_T_Near")
check(MD.state().tool == "Near" and lastMsg():find("Nearest") ~= nil or MD.state().tool == "Near",
	"tool Near")
click("MD4_T_Move")
check(MD.state().tool == "Move" and setModes[#setModes] == "Move", "tool Move -> SetMode")
click("MD4_T_Select")
check(MD.state().tool == "Select" and setModes[#setModes] == "Select", "tool Select -> SetMode")
local mp = nil
for _, o in ipairs(ws:GetDescendants()) do
	if o:IsA("MeshPart") then mp = o break end
end
check(mp ~= nil, "MeshPart existe no workspace")
hitInst, hitPos = mp, Vector3.new(0, 0, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
check(MD.state().meshId ~= nil and lastMsg():find("adopted") ~= nil, "clique Select adota MeshPart")
click("MD4_T_Near")
hitPos = Vector3.new(2, -1.99, -2)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
local nv2 = MD.state().verts[MD.state().vertIdx]
check(nv2 and math.abs(nv2.x - 2) < 0.6 and lastMsg():find("Nearest") ~= nil, "Near pega vert proximo do hit")
local plain = Instance.new("Part"); plain.Name = "Plain"; plain.Parent = ws
click("MD4_T_Select")
hitInst, hitPos = plain, Vector3.new(0, 0, 0)
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, false)
check(lastMsg():find("not a MeshPart") ~= nil, "clique em Part avisa")
local beforeId = MD.state().meshId
UIS.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
	KeyCode = Enum.KeyCode.Unknown, Position = { X = 400, Y = 300 } }, true)
check(MD.state().meshId == beforeId, "clique com gpe ignorado")

print("\n== MD14-C5: smooth/mirror UI ==")
click("MD4_S_IP")
check(find("MD4_S_IV").Text == "2", "iters 1->2")
click("MD4_S_IM")
check(find("MD4_S_IV").Text == "1", "iters 2->1")
click("MD4_Smooth")
check(lastMsg():find("Smoothed x1") ~= nil, "Smooth loga")
local mx0 = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = MD.state().meshId }).verts) do mx0[v.vid] = v.x end
click("MD4_M_X")
local mx1 = {}
for _, v in ipairs(serverInvoke("MeshVerts", { id = MD.state().meshId }).verts) do mx1[v.vid] = v.x end
local mFlip = lastMsg():find("Mirrored X") ~= nil
for vid, x in pairs(mx1) do
	if math.abs(x + mx0[vid]) > 1e-6 then mFlip = false break end
end
check(mFlip, "Mirror X via UI inverte + loga")

print("\n== MD14-C6: OBJ via UI ==")
click("MD4_IO_Export")
check(find("MD4_IO_Text").Text:find("# Arkher") == 1, "Export preenche textbox")
check(find("MD4_IO_Stat").Text:find("obj %d+ v %d+ f") ~= nil, "Export atualiza stat")
local tri = "v 0 0 0\nv 2 0 0\nv 0 2 0\nf 1 2 3\n"
find("MD4_IO_Text").Text = tri
click("MD4_IO_Import")
check(#MD.state().verts == 3 and MD.state().meshName == "Mesh_OBJ", "Import adota tri (3 verts)")
check(lastMsg():find("importado") ~= nil, "Import loga msg do server")
find("MD4_IO_Text").Text = ""
click("MD4_IO_Import")
check(lastMsg():find("paste OBJ") ~= nil, "Import vazio avisa")

print("\n== MD14-C7: mobile + marcador ==")
plat = "Mobile"
MD.close()
check(ws:FindFirstChild("ArkherVertMark") == nil, "close destroi marcador")
MD.open()
check(find("M_MD").Visible == true, "Mobile: strip M_MD visivel")
click("M_MD_New")
check(#MD.state().verts == 8, "M_MD_New cria box")
click("M_MD_Smooth")
check(lastMsg():find("Smoothed") ~= nil, "M_MD_Smooth loga")
MD.close()
check(find("M_MD").Visible == false, "close esconde M_MD")
plat = "PC"

print("\nMODEL14: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end