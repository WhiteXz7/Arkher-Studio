"""Fase 6: testes PropsAll/SetAny (roundtrip real) no test_server.lua. One-shot."""
import io

P = "studio-completo/tools/test_server.lua"
s = io.open(P, encoding="utf-8").read()
assert "PropsAll roundtrip" not in s, "ja aplicado"

anchor = 'print("\\n================================\")\nprint(string.format("RESULTADO: %d passaram, %d falharam", pass, fail))'
assert s.count(anchor) == 1, "anchor final"

block = '''
print("\\n== Properties (PropsAll/SetAny roundtrip) ==")
local snapP = snapshot()
local wsP = nil
for _, n in ipairs(snapP.nodes) do if n.class == "Workspace" then wsP = n.id end end
check(wsP ~= nil, "Props: Workspace id re-resolvido")
local cp = invoke("Create", { parentId = wsP, class = "Part", name = "PropT" })
check(cp and cp.ok == true and cp.node and cp.node.id, "Props: Create PropT")
local pid = cp and cp.node and cp.node.id
local pa = pid and invoke("PropsAll", { id = pid })
check(pa and pa.fields and #pa.fields > 5, "PropsAll: " .. (pa and #pa.fields or 0) .. " fields")
local nameF = nil
if pa and pa.fields then for _, f in ipairs(pa.fields) do if f.name == "Name" then nameF = f end end end
check(nameF and nameF.value == "PropT" and nameF.kind == "s", "PropsAll: field Name=s valendo PropT")
local s1 = pid and invoke("SetAny", { id = pid, name = "Name", kind = "s", value = "PropT2" })
check(s1 and s1.ok == true and s1.now == "PropT2", "SetAny: Name -> PropT2")
local pa2 = pid and invoke("PropsAll", { id = pid })
local nameF2 = nil
if pa2 and pa2.fields then for _, f in ipairs(pa2.fields) do if f.name == "Name" then nameF2 = f end end end
check(nameF2 and nameF2.value == "PropT2", "PropsAll roundtrip: Name agora e PropT2")
local s2 = pid and invoke("SetAny", { id = pid, name = "Anchored", kind = "b", value = true })
check(s2 and s2.ok == true, "SetAny: Anchored=true ok")
local s3 = pid and invoke("SetAny", { id = pid, name = "NaoExiste", kind = "s", value = "x" })
check(s3 and s3.error, "SetAny: prop inexistente devolve erro honesto")
'''
s = s.replace(anchor, block + "\n" + anchor)
io.open(P, "w", encoding="utf-8").write(s)
print("test_server: props tests OK")
