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

print("\n================================")
print(string.format("RESULTADO: %d passaram, %d falharam", pass, fail))
if fail > 0 then os.exit(1) else os.exit(0) end
