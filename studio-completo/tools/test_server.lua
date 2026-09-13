-- Testa o ArkherEditorServer estendido via bridge real.
dofile("studio-completo/tools/mock.lua")

local RS = game:GetService("ReplicatedStorage")
local src = io.open("studio-completo/scripts/server.lua"):read("*a")
local fn, serr = loadstring(src, "[server]")
assert(fn, "sintaxe do server: " .. tostring(serr))
local ok, rerr = pcall(fn)
assert(ok, "execucao do server falhou: " .. tostring(rerr))

local bridge = RS:FindFirstChild("ArkherStudioBridge")
assert(bridge, "bridge nao criado")
local request = bridge:FindFirstChild("Request")
assert(request, "Request nao criado")
local testPlayer = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
assert(testPlayer, "player de teste")

local function invoke(action, payload)
  return rawget(request, "__props").OnServerInvoke(testPlayer, action, payload)
end

local pass, fail = 0, 0
local function check(cond, msg)
  if cond then pass = pass + 1 print("  OK  " .. msg)
  else fail = fail + 1 print("  FALHOU  " .. msg) end
end
local function snapshot() return invoke("Snapshot") end
local function findId(snap, name)
  for _, n in ipairs(snap.nodes) do if n.name == name then return n.id end end
  return nil
end
local function countNamed(snap, prefix)
  local c = 0
  for _, n in ipairs(snap.nodes) do if n.name:sub(1, #prefix) == prefix then c = c + 1 end end
  return c
end
local function exists(snap, name)
  for _, n in ipairs(snap.nodes) do if n.name == name then return true end end
  return false
end

local snap = snapshot()
check(snap and snap.ok == true, "Snapshot ok")
local wsId
for _, n in ipairs(snap.nodes) do if n.class == "Workspace" then wsId = n.id end end
check(wsId ~= nil, "Workspace encontrado (id=" .. tostring(wsId) .. ")")

print("\n== Criar / Undo / Redo ==")
local c1 = invoke("Create", { parentId = wsId, class = "Part", name = "PecaA" })
check(c1 and c1.ok == true and c1.node, "Create PecaA")
local h1 = invoke("GetHistory")
check(h1 and h1.canUndo == true, "apos Create: canUndo=true")
local u1 = invoke("Undo")
check(u1 and u1.ok ~= false, "Undo execute (" .. (u1 and u1.label or "?") .. ")")
check(not exists(snapshot(), "PecaA"), "apos Undo: PecaA removida")
local r1 = invoke("Redo")
check(r1 and r1.ok ~= false, "Redo execute")
check(exists(snapshot(), "PecaA"), "apos Redo: PecaA restaurada")

print("\n== Excluir / Undo / Redo ==")
local idA = findId(snapshot(), "PecaA")
local d1 = invoke("Delete", { id = idA })
check(d1 and d1.ok == true, "Delete PecaA")
check(not exists(snapshot(), "PecaA"), "apos Delete: PecaA removida")
local u2 = invoke("Undo")
check(u2 and u2.ok ~= false, "Undo do Delete")
check(exists(snapshot(), "PecaA"), "Undo do Delete: PecaA restaurada")

print("\n== Copiar / Colar / Duplicar ==")
local c2 = invoke("Create", { parentId = wsId, class = "Folder", name = "PastaX" })
local idF = c2.node.id
invoke("Create", { parentId = idF, class = "Part", name = "PecaDentro" })
local co = invoke("Copy", { id = idF })
check(co and co.ok ~= false, "Copy PastaX")
local pa = invoke("Paste", { parentId = wsId })
check(pa and pa.ok == true and pa.node, "Paste criou objeto")
check(countNamed(snapshot(), "PastaX") == 2, "apos Paste: 2x PastaX* (=" .. countNamed(snapshot(), "PastaX") .. ")")
local du = invoke("Duplicate", { id = idF })
check(du and du.ok == true and du.node, "Duplicate PastaX")
check(countNamed(snapshot(), "PastaX") == 3, "apos Duplicate: 3x PastaX* (=" .. countNamed(snapshot(), "PastaX") .. ")")

print("\n== Renomear ==")
local re = invoke("Rename", { id = idF, name = "PastaRenomeada" })
check(re and re.ok == true and re.node and re.node.name == "PastaRenomeada", "Rename -> PastaRenomeada")
check(exists(snapshot(), "PastaRenomeada"), "PastaRenomeada presente")

print("\n== Set (propriedade) + Undo ==")
local c4 = invoke("Create", { parentId = wsId, class = "Part", name = "PecaCor" })
local idC = c4.node.id
local se = invoke("Set", { id = idC, key = "Transparency", value = 0.5 })
check(se and se.ok == true, "Set Transparency=0.5" .. (se and se.error and (" err=" .. se.error) or ""))
local u3 = invoke("Undo")
check(u3 and u3.ok ~= false, "Undo do Set")

local hf2 = invoke("GetHistory")
check(hf2 and #hf2.undo >= 1, "historico tem entradas antes do New (" .. (hf2 and #hf2.undo or 0) .. ")")

print("\n== Export / Import ==")
local ex = invoke("Export")
check(ex and ex.ok == true and ex.data, "Export (nodes=" .. (ex and ex.nodes or "?") .. ")" .. (ex and ex.error and (" err=" .. ex.error) or ""))
local jsonStr = game:GetService("HttpService"):JSONEncode(ex and ex.data)
check(type(jsonStr) == "string" and #jsonStr > 50, "Export -> JSON (" .. #jsonStr .. " bytes)")
local impData = { c = "Folder", n = "Importada", k = { { c = "Part", n = "ParteImportada" } } }
local im = invoke("Import", { data = impData })
check(im and im.ok == true and im.created == 2 and im.root, "Import Folder+Part (created=" .. (im and im.created or "?") .. ")")
check(exists(snapshot(), "ParteImportada"), "ParteImportada presente apos Import")
local bad = invoke("Import", { data = { c = "Rocket", n = "X" } })
check(bad and bad.ok == false, "Import classe invalida rejeitada")

print("\n== New / Open (templates) ==")
local nw = invoke("New")
check(nw and nw.ok == true, "New (projeto novo)")
check(exists(snapshot(), "Baseplate"), "New: Baseplate presente")
local op = invoke("Open", { template = "Empty" })
check(op and op.ok == true, "Open template=Empty")
local op2 = invoke("Open", { template = "Baseplate" })
check(op2 and op2.ok == true, "Open template=Baseplate")
check(exists(snapshot(), "Baseplate"), "Open Baseplate: Baseplate presente")
local badT = invoke("Open", { template = "Rocket" })
check(badT and badT.ok == false, "Open template invalido rejeitado")

print("\n== GetHistory ==")
local hf = invoke("GetHistory")
check(hf and type(hf.undo) == "table" and type(hf.redo) == "table", "GetHistory estrutura")
check(hf and hf.canUndo == false, "apos New: historico limpo (canUndo=false)")


print("\n== Properties (PropsAll/SetAny roundtrip) ==")
local function invokeWait(action, payload)
  local t0 = os.clock()
  while os.clock() - t0 < 6 do
    local r = invoke(action, payload)
    if r and r.error ~= "Requisição inválida ou limite de frequência." then return r end
    local w0 = os.clock() while os.clock() - w0 < 0.15 do end
  end
  return invoke(action, payload)
end
check(wsId ~= nil, "Props: Workspace id (inicio do teste)")
local cp = invokeWait("Create", { parentId = wsId, class = "Part", name = "PropT" })
check(cp and cp.ok == true and cp.node and cp.node.id, "Props: Create PropT")
local pid = cp and cp.node and cp.node.id
local pa = pid and invokeWait("PropsAll", { id = pid })
check(pa and pa.fields and #pa.fields > 5, "PropsAll: " .. (pa and #pa.fields or 0) .. " fields")
local nameF = nil
if pa and pa.fields then for _, f in ipairs(pa.fields) do if f.name == "Name" then nameF = f end end end
check(nameF and nameF.value == "PropT" and nameF.kind == "s", "PropsAll: field Name=s valendo PropT")
local s1 = pid and invokeWait("SetAny", { id = pid, name = "Name", kind = "s", value = "PropT2" })
check(s1 and s1.ok == true and s1.now == "PropT2", "SetAny: Name -> PropT2")
local pa2 = pid and invokeWait("PropsAll", { id = pid })
local nameF2 = nil
if pa2 and pa2.fields then for _, f in ipairs(pa2.fields) do if f.name == "Name" then nameF2 = f end end end
check(nameF2 and nameF2.value == "PropT2", "PropsAll roundtrip: Name agora e PropT2")
local s2 = pid and invokeWait("SetAny", { id = pid, name = "Anchored", kind = "b", value = true })
check(s2 and s2.ok == true, "SetAny: Anchored=true ok")
local s3 = pid and invokeWait("SetAny", { id = pid, name = "Transparency", kind = "n", value = 0.5 })
local pa3 = pid and invokeWait("PropsAll", { id = pid })
local trF = nil
if pa3 and pa3.fields then for _, f in ipairs(pa3.fields) do if f.name == "Transparency" then trF = f end end end
check(s3 and s3.ok == true and trF and trF.value == 0.5, "SetAny: Transparency 0.5 roundtrip")


print("\n== CloudQuick (snapshot+publish+place) ==")
local cq = invokeWait("CloudQuick", {})
check(cq and cq.snapshot and cq.snapshot:sub(1, 5) == "Nuvem" and (cq.nodes or 0) > 0, "CloudQuick: snapshot Nuvem (" .. (cq and cq.nodes or 0) .. " obj)")
check(cq and cq.msg and (cq.saved or cq.placeId or cq.placeError), "CloudQuick: msg + resultado publish/place")

print("\n== R2 pipeline (PipeStats + CreateAny node + parentName) ==")
local ps = invokeWait("PipeStats", {})
check(ps and ps.deltaFlush ~= nil and ps.propsPush ~= nil and ps.selects ~= nil and ps.creates ~= nil, "PipeStats: contadores presentes")
check(ps and (ps.nodeCount or 0) > 0 and ps.maxNodes == 12000, "PipeStats: nodeCount>0 + maxNodes=12000")
check(ps and ps.subscribed == true, "PipeStats: subscribed=true apos Snapshot")
local snap0 = invokeWait("Snapshot", {})
local wsId = findId(snap0, "Workspace")
local ca = invokeWait("CreateAny", { class = "Folder", parentId = wsId })
check(ca and ca.id and ca.node and ca.node.id == ca.id and ca.node.parentId == wsId, "CreateAny: responde node{id,parentId}")
local ps2 = invokeWait("PipeStats", {})
check(ps2 and (ps2.creates or 0) > (ps.creates or 0), "PipeStats: creates incrementou")
local sel = (ca and ca.id) and invokeWait("Select", { id = ca.id })
local ps3 = invokeWait("PipeStats", {})
check(sel and sel.properties and ps3 and (ps3.selects or 0) > (ps.selects or 0) and ps3.selectedId == ca.id, "Select: props + selects incrementou + selectedId")
local caW = invokeWait("CreateAny", { class = "Model", parentName = "Workspace" })
check(caW and caW.id and caW.parent and caW.parent:find("Workspace"), "CreateAny parentName=Workspace: pai Workspace")
local caX = invokeWait("CreateAny", { class = "Folder", parentName = "ServicoInexistenteZZZ" })
check(caX and caX.id, "CreateAny parentName desconhecido: cai no default sem erro")

print("\n== R3 terreno voxel real ==")
local terCalls = {}
METHODS.FillBall = function(self, c, r, mt) terCalls[#terCalls+1] = { shape = "ball", r = r, mat = mt and mt.Name } end
METHODS.FillBlock = function(self, cf, sz, mt) terCalls[#terCalls+1] = { shape = "block", sz = sz, mat = mt and mt.Name } end
METHODS.FillCylinder = function(self, cf, h, r, mt) terCalls[#terCalls+1] = { shape = "cylinder", h = h, r = r, mat = mt and mt.Name } end
METHODS.Clear = function(self) terCalls[#terCalls+1] = { shape = "clear" } end
METHODS.CountCells = function(self) return 42 end
local ter0 = Instance.new("Terrain")
ter0.Parent = game:GetService("Workspace")
local ti = invokeWait("TerrainInfo", {})
check(ti and ti.cells == 42, "TerrainInfo: cells do Terrain real")
local f1 = invokeWait("TerrainFill", { shape = "ball", center = { x = 0, y = 10, z = 0 }, radius = 16, material = "Grass" })
check(f1 and f1.ok and #terCalls == 1 and terCalls[1].shape == "ball" and terCalls[1].r == 16 and terCalls[1].mat == "Grass", "TerrainFill ball: FillBall(centro, 16, Grass)")
local f2 = invokeWait("TerrainFill", { shape = "block", center = { x = 1, y = 2, z = 3 }, size = { x = 32, y = 8, z = 32 }, material = "Rock" })
check(f2 and f2.ok and terCalls[#terCalls].shape == "block" and terCalls[#terCalls].mat == "Rock", "TerrainFill block: FillBlock ok")
local f3 = invokeWait("TerrainFill", { shape = "cylinder", center = { x = 0, y = 0, z = 0 }, radius = 8, height = 24, material = "Sand" })
check(f3 and f3.ok and terCalls[#terCalls].shape == "cylinder", "TerrainFill cylinder: FillCylinder ok")
local fr = invokeWait("TerrainFill", { shape = "ball", center = { x = 0, y = 0, z = 0 }, radius = 8, material = "Grass", op = "remove" })
check(fr and fr.ok and terCalls[#terCalls].mat == "Air", "TerrainFill remove: vira Air")
local fb = invokeWait("TerrainFill", { shape = "x", center = { x = 0, y = 0, z = 0 }, material = "Grass" })
check(fb and fb.error, "TerrainFill shape invalido: rejeita")
local fbig = invokeWait("TerrainFill", { shape = "ball", center = { x = 0, y = 0, z = 0 }, radius = 9999, material = "Grass" })
check(fbig and fbig.error, "TerrainFill radius gigante: rejeita")
local fmat = invokeWait("TerrainFill", { shape = "ball", center = { x = 0, y = 0, z = 0 }, radius = 8, material = "Adamantium" })
check(fmat and fmat.error, "TerrainFill material falso: rejeita")
local cl = invokeWait("TerrainClear", {})
check(cl and cl.ok and terCalls[#terCalls].shape == "clear", "TerrainClear: Clear ok")

print("\n== R4 nucleo (undo cru + PropsAll) ==")
local wsSnap = invokeWait("Snapshot", {})
local wsId2 = findId(wsSnap, "Workspace")
local cp = invokeWait("CreateAny", { class = "Part", parentId = wsId2 })
local cpid = cp and cp.id
check(cpid ~= nil, "R4: Part criado p/ teste")
local t0 = cpid and invokeWait("SetAny", { id = cpid, name = "Transparency", kind = "n", value = 0.5 })
check(t0 and t0.ok == true, "R4: SetAny Transparency=0.5")
local paT = cpid and invokeWait("PropsAll", { id = cpid })
local tf = nil
if paT and paT.fields then for _, f in ipairs(paT.fields) do if f.name == "Transparency" then tf = f end end end
check(tf and tf.value == 0.5, "R4: PropsAll mostra 0.5")
local un1 = invokeWait("Undo", {})
local paT2 = cpid and invokeWait("PropsAll", { id = cpid })
local tf2 = nil
if paT2 and paT2.fields then for _, f in ipairs(paT2.fields) do if f.name == "Transparency" then tf2 = f end end end
check(un1 and tf2 and tf2.value == 0, "R4: Undo restaura Transparency=0 (undo cru)")
local b0 = cpid and invokeWait("SetAny", { id = cpid, name = "Anchored", kind = "b", value = false })
local un2 = invokeWait("Undo", {})
local paB = cpid and invokeWait("PropsAll", { id = cpid })
local bf = nil
if paB and paB.fields then for _, f in ipairs(paB.fields) do if f.name == "Anchored" then bf = f end end end
check(b0 and b0.ok and un2 and bf and bf.value == true, "R4: Undo restaura Anchored=true (bool cru)")
local names = {}
if paB and paB.fields then for _, f in ipairs(paB.fields) do names[f.name] = f.kind end end
check(names["Position"] and names["Size"] and names["Color"] and names["Name"], "R4: PropsAll Part tem Position/Size/Color/Name")

print("\n== R5 script studio (execucao real) ==")
local sr1 = invokeWait("ScriptRun", { code = "return 2+2" })
check(sr1 and sr1.ret == "4", "ScriptRun: return 2+2 -> 4")
local sr2 = invokeWait("ScriptRun", { code = "error('boom')" })
check(sr2 and sr2.error and sr2.error:find("boom"), "ScriptRun: erro capturado")
local sr3 = invokeWait("ScriptRun", { code = "local =" })
check(sr3 and sr3.error and sr3.error:find("Sintaxe"), "ScriptRun: sintaxe invalida")
local sr4 = invokeWait("ScriptRun", { code = "while true do end" })
check(sr4 and sr4.error and sr4.error:find("infinito"), "ScriptRun: trava loop infinito")
local py1 = invokeWait("PyLua", { code = [==[
def fat(n):
    r = 1
    for i in range(1, n + 1):
        r = r * i
    return r
return fat(5)
]==] })
check(py1 and py1.ret == "120", "PyRun: fatorial(5)=120 (ret=" .. tostring(py1 and py1.ret) .. ")")
local py2 = invokeWait("PyLua", { code = [==[
x = 7
if x > 10:
    r = "big"
elif x > 5:
    r = "mid"
else:
    r = "small"
return r
]==] })
check(py2 and py2.ret == "mid", "PyRun: if/elif/else -> mid")
local py3 = invokeWait("PyLua", { code = "import os\nreturn 1" })
check(py3 and py3.error and py3.error:find("import"), "PyRun: import rejeitado (honesto)")
local cs1 = invokeWait("CsRun", { code = [==[
int s = 0;
for (int i = 1; i < 6; i++) {
    s += i;
}
return s;
]==] })
check(cs1 and cs1.ret == "15", "CsRun: soma 1..5=15 (ret=" .. tostring(cs1 and cs1.ret) .. ")")
local bl1 = invokeWait("BlockRun", { nodes = {
  { op = "lua", code = "bx = 0" },
  { op = "repeat", n = 3, body = { { op = "lua", code = "bx = bx + 10" } } },
  { op = "lua", code = "return bx" },
} })
check(bl1 and bl1.ret == "30", "BlockRun: repeat 3x -> 30")
check(bl1 and bl1.lua and bl1.lua:find("for _bx"), "BlockRun: mostra Lua gerado")
local sssSnap = invokeWait("Snapshot", {})
local sssId = findId(sssSnap, "ServerScriptService")
local sc = invokeWait("CreateAny", { class = "Script", parentId = sssId })
local scid = sc and sc.id
local ss1 = scid and invokeWait("ScriptSet", { id = scid, source = "print('oi')" })
local sg1 = scid and invokeWait("ScriptGet", { id = scid })
check(ss1 and ss1.msg and sg1 and sg1.source == "print('oi')", "ScriptGet/Set: roundtrip Source")

print("\n== R5 run (play/pause/stop reais) ==")
local rp = invokeWait("CreateAny", { class = "Part" })
local rpid = rp and rp.id
local play = invokeWait("RunPlay", {})
check(play and play.msg, "RunPlay: msg")
local setBlocked = rpid and invokeWait("Set", { id = rpid, key = "Name", value = "Travado" })
check(setBlocked and setBlocked.error and setBlocked.error:find("execu"), "Run: Set bloqueado durante play")
local pause = invokeWait("RunPause", {})
check(pause and pause.msg, "RunPause: msg")
local stop = invokeWait("RunStop", {})
local setFree = rpid and invokeWait("Set", { id = rpid, key = "Name", value = "Livre" })
check(stop and stop.msg and setFree and setFree.node, "RunStop: edicao liberada")

print("\n== R5 terreno 2 (agua/troca/flat) ==")
Region3 = Region3 or { new = function(a, b) return { Min = a, Max = b, ExpandToGrid = function(self, _) return self end } end }
local terCalls2 = {}
METHODS.FillBlock = function(self, cf, sz, mt) terCalls2[#terCalls2+1] = { shape = "block", sz = sz, mat = mt and mt.Name } end
METHODS.FillRegion = function(self, r3, res, mt) terCalls2[#terCalls2+1] = { shape = "region", mat = mt and mt.Name } end
METHODS.ReplaceMaterial = function(self, r3, res, f, t2) terCalls2[#terCalls2+1] = { shape = "replace", from = f and f.Name, to = t2 and t2.Name } end
local w1 = invokeWait("TerrainWater", { y = 12, xz = 256 })
check(w1 and w1.msg and terCalls2[#terCalls2].mat == "Water", "TerrainWater: FillBlock Water")
local rp2 = invokeWait("TerrainReplace", { center = { x = 0, y = 0, z = 0 }, radius = 16, from = "Rock", to = "Grass" })
check(rp2 and rp2.msg and terCalls2[#terCalls2].shape == "replace" and terCalls2[#terCalls2].to == "Grass", "TerrainReplace: Rock->Grass")
local rp3 = invokeWait("TerrainReplace", { center = { x = 0, y = 0, z = 0 }, radius = 16, from = "Rock", to = "Adamantium" })
check(rp3 and rp3.error, "TerrainReplace: material falso rejeita")
local gf = invokeWait("TerrainGenFlat", { size = 128, material = "Sand", water = true })
check(gf and gf.msg and terCalls2[#terCalls2].shape == "block", "TerrainGenFlat: region + agua")

print("\n== R6 animacao (pose real) ==")
local aSnap = invokeWait("Snapshot", {})
local aWs = findId(aSnap, "Workspace")
local ap = invokeWait("CreateAny", { class = "Part", parentId = aWs })
local apid = ap and ap.id
local k1 = apid and invokeWait("AnimKey", { id = apid, slot = "A" })
check(k1 and k1.msg, "AnimKey A: pose gravada")
local mv = apid and invokeWait("Set", { id = apid, key = "Position", value = Vector3.new(10, 5, 0) })
check(mv and mv.node, "Anim: peca movida p/ (10,5,0)")
local go = apid and invokeWait("AnimGo", { id = apid, slot = "A", dur = 0 })
local paA = apid and invokeWait("PropsAll", { id = apid })
local posA = nil
if paA and paA.fields then for _, f in ipairs(paA.fields) do if f.name == "Position" then posA = f.value end end end
check(go and go.msg and posA and tonumber(posA.x) == 0, "AnimGo A: voltou p/ pose (x=" .. tostring(posA and posA.x) .. ")")
local unA = invokeWait("Undo", {})
local paA2 = apid and invokeWait("PropsAll", { id = apid })
local posA2 = nil
if paA2 and paA2.fields then for _, f in ipairs(paA2.fields) do if f.name == "Position" then posA2 = f.value end end end
check(unA and posA2 and tonumber(posA2.x) == 10, "AnimGo: desfazer volta p/ (10,5,0)")
local stp = invokeWait("AnimStop", {})
check(stp and stp.msg, "AnimStop: msg")

print("\n== R6 vfx (luz/particula/som/ceu) ==")
local vSnap = invokeWait("Snapshot", {})
local vWs = findId(vSnap, "Workspace")
local vLight = findId(vSnap, "Lighting")
local vp = invokeWait("CreateAny", { class = "Part", parentId = vWs })
local vpid = vp and vp.id
local li = vpid and invokeWait("CreateAny", { class = "PointLight", parentId = vpid })
local liSet = li and li.id and invokeWait("SetAny", { id = li.id, name = "Brightness", kind = "n", value = 5 })
check(li and li.id and liSet and liSet.ok, "VFX: PointLight + Brightness=5")
local pe = vpid and invokeWait("CreateAny", { class = "ParticleEmitter", parentId = vpid })
local peSet = pe and pe.id and invokeWait("SetAny", { id = pe.id, name = "Rate", kind = "n", value = 50 })
check(pe and pe.id and peSet and peSet.ok, "VFX: ParticleEmitter + Rate=50")
local snd = vpid and invokeWait("CreateAny", { class = "Sound", parentId = vpid })
local sndSet = snd and snd.id and invokeWait("SetAny", { id = snd.id, name = "Volume", kind = "n", value = 3 })
check(snd and snd.id and sndSet and sndSet.ok, "VFX: Sound + Volume=3")
local sky = vLight and invokeWait("CreateAny", { class = "Sky", parentId = vLight })
check(sky and sky.id, "VFX: Sky no Lighting")

print("\n== R6 terreno centro=player ==")
local pl = invokeWait("TerrainFill", { shape = "ball", center = "player", radius = 8, material = "Grass" })
check(pl and pl.error and pl.error:find("personagem"), "TerrainFill player sem char: erro honesto")

print("\n================================")

print("\n== R7 shell2 (svcset/smooth/noise) ==")
local sc1 = invokeWait("SvcSet", { service = "Lighting", name = "ClockTime", kind = "n", value = 18 })
local lk = game:GetService("Lighting")
check(sc1 and sc1.applied == "Lighting.ClockTime" and lk.ClockTime == 18, "SvcSet: ClockTime 18")
local sc2 = invokeWait("SvcSet", { service = "Lighting", name = "ClockTime", kind = "n", value = 6 })
check(sc2 and lk.ClockTime == 6, "SvcSet: ClockTime 6")
local sc3 = invokeWait("SvcSet", { service = "Players", name = "X", kind = "s", value = "y" })
check(sc3 and sc3.error, "SvcSet: servico fora da allowlist rejeita")
local rwLog = {}
local occIn = { { { 1, 0 }, { 0, 1 } }, { { 0, 1 }, { 1, 0 } } }
local matIn = { { { "Grass", "Grass" }, { "Grass", "Grass" } }, { { "Grass", "Grass" }, { "Grass", "Grass" } } }
METHODS.ReadVoxels = function(self, region, res) return matIn, occIn end
METHODS.WriteVoxels = function(self, r3, res, m, o) rwLog[#rwLog+1] = { m = m, o = o } end
local sm = invokeWait("TerrainSmooth", { center = { x = 0, y = 0, z = 0 }, radius = 8 })
check(sm and sm.msg and #rwLog == 1, "TerrainSmooth: write 1x")
local sv = rwLog[1] and rwLog[1].o[1][1][1]
check(sv and math.abs(sv - 0.5) < 0.001, "TerrainSmooth: media 3x3x3 = 0.5")
local nz = invokeWait("TerrainNoise", { center = { x = 0, y = 0, z = 0 }, radius = 8, force = 100 })
check(nz and nz.msg and #rwLog == 2, "TerrainNoise: write 1x")
local nv = rwLog[2] and rwLog[2].o[1][1][2]
check(nv and nv ~= 0, "TerrainNoise: perturba occupancy")

print(string.format("RESULTADO: %d passaram, %d falharam", pass, fail))
if fail > 0 then os.exit(1) else os.exit(0) end
