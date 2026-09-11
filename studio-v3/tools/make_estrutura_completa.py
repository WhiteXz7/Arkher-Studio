#!/usr/bin/env python3
"""Gera a ESTRUTURA COMPLETA do ARKHER V3:

1) 13 scripts de Command Bar (commandbar/estrutura-completa/CBxx_*.lua) que,
   colados e executados no Studio, criam TODAS as instancias no lugar:
     ReplicatedStorage.ArkherV3          (2 kits + 3 chunks do ALL)
     StarterPlayerScripts.Arkher         (4 launchers + assemble + 24 paineis)
     ServerScriptService.Arkher          (2 installers desativados)
     ServerStorage.ArkherData            (namespace server)
2) arkher-v3.rbxl completo (mesma arvore, no binario v0 do Studio)

Validacao:
  * lupa compila os 13 scripts gerados (sintaxe Lua)
  * round-trip do .rbxl: as 33 fontes byte-identicas + flags Disabled + arvore
  * p1..p2..p3 (chunks do ALL) reconstruem ArkherStudio_ALL.lua byte a byte
"""
import glob
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "commandbar")
OUT_DIR = os.path.join(DIST, "estrutura-completa")
RBXL_OUT = os.path.join(DIST, "arkher-v3.rbxl")

sys.path.insert(0, HERE)
from make_rbxl import (MAGIC, referent_array_enc, s, chunk, SERVICE_CLASSES,
                       SERVICES)  # noqa: E402
import pyrbxl2  # noqa: E402

for f in sorted(glob.glob(os.path.join(DIST, "*.lua"))):
    txt = open(f, encoding="utf-8").read()
    if "]====]" in txt and not f.endswith(("ArkherKit_Installer_A.lua",
                                           "ArkherKit_Installer_B.lua")):
        sys.exit(f"colisao de delimitador em {f}")

S = {os.path.basename(f): open(f, encoding="utf-8").read()
     for f in glob.glob(os.path.join(DIST, "*.lua"))}

PAINELS_A = ["UI_AI", "UI_About", "UI_Animator", "UI_Audio", "UI_Camera",
             "UI_City", "UI_Cloud", "UI_CommandPalette", "UI_Console",
             "UI_Lighting", "UI_Map", "UI_Modeler"]
PAINELS_B = ["UI_NPCs", "UI_Open", "UI_Particles", "UI_Performance",
             "UI_Physics", "UI_Publish", "UI_SaveExport", "UI_SaveOpen",
             "UI_Script", "UI_Settings", "UI_Terrain", "UI_UIDesigner"]
assert len(PAINELS_A) + len(PAINELS_B) == 24

# ---------------- chunks do ArkherStudio_ALL (251KB > limite de 100KB) ------
ALL = S["ArkherStudio_ALL.lua"]
LIMIT = 84_000
# divide em 3 partes nos limites de linha mais proximos de 1/3 e 2/3
lines = ALL.split("\n")
sizes = [len(l) + 1 for l in lines]
total = sum(sizes)
t1, t2 = total // 3, 2 * total // 3
acc = 0
cut1 = cut2 = 0
for i, sz in enumerate(sizes):
    if cut1 == 0 and acc + sz > t1:
        cut1 = i
    if cut2 == 0 and cut1 and acc + sz > t2:
        cut2 = i
    acc += sz
part1 = ALL[:sum(sizes[:cut1])]
part2 = ALL[sum(sizes[:cut1]):sum(sizes[:cut2])]
part3 = ALL[sum(sizes[:cut2]):]
assert part1 + part2 + part3 == ALL
assert max(len(part1), len(part2), len(part3)) <= LIMIT
CHUNKS = [part1, part2, part3]
MODULE_ALL = [f"return[====[{p}]====]\n" for p in CHUNKS]

ASSEMBLE_SRC = '''--[[ ARKHER V3 — ArkherStudio_ALL (251KB) reconstituido dos 3 chunks.
     HABILITE este LocalScript e aperte F5 para rodar o ALL completo. ]]
local ok, err = pcall(function()
\tlocal all = game:WaitForChild("ReplicatedStorage"):WaitForChild("ArkherV3"):WaitForChild("ALL")
\tlocal src = require(all:WaitForChild("ALL_P1"))
\t\t.. require(all:WaitForChild("ALL_P2"))
\t\t.. require(all:WaitForChild("ALL_P3"))
\tlocal fn = loadstring(src)
\tif not fn then error("loadstring falhou no ALL") end
\tfn()
end)
if not ok then
\twarn("[ARKHER V3] ArkherStudio_ALL falhou:", err)
else
\tprint("[ARKHER V3] ArkherStudio_ALL (251KB) executado a partir dos 3 chunks")
end
'''

# ---------------- templating dos scripts de Command Bar --------------------

HDR = """--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA ({n}/13)
  {titulo}
  Cria: {cria}
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]"""


def emb(name: str, src: str, level: int = 4) -> str:
    """Embutimento byte-exato: o conteudo do long string == src (src termina com \n)."""
    d = "=" * level
    assert src.endswith("\n"), f"{name}: src sem newline final"
    assert f"]{d}]" not in src, f"{name}: src contem o close do nivel {level}"
    return f"local {name} = [{d}[{src}]{d}]\n"


def put(folder_expr, name, cls, var, disabled=False) -> str:
    dis = "\n\tt.Disabled = true" if disabled else ""
    return (f"local t = {folder_expr}:FindFirstChild(\"{name}\")\n"
            f"if not t then t = Instance.new(\"{cls}\") t.Name = \"{name}\" t.Parent = {folder_expr} end\n"
            f"t.Source = {var}{dis}\n")


def folder(parent_expr, name) -> str:
    return (f"local {name.lower().replace('-', '_')} = {parent_expr}:FindFirstChild(\"{name}\")\n"
            f"if not {name.lower().replace('-', '_')} then {name.lower().replace('-', '_')} = Instance.new(\"Folder\") "
            f"{name.lower().replace('-', '_')}.Name = \"{name}\" {name.lower().replace('-', '_')}.Parent = {parent_expr} end\n")


def build_cb(idx, titulo, cria, body, extra_top=""):
    out = HDR.format(n=idx, titulo=titulo, cria=cria) + "\n"
    out += extra_top
    out += body
    open(os.path.join(OUT_DIR, f"CB{idx:02d}.lua"), "w", encoding="utf-8").write(out)
    return len(out)


os.makedirs(OUT_DIR, exist_ok=True)
sizes = []

# CB01/CB02 = installers existentes (criam ReplicatedStorage.ArkherV3.ArkherKit_X)
for i, (f, n) in enumerate((("ArkherKit_Installer_A.lua", "A"),
                            ("ArkherKit_Installer_B.lua", "B")), 1):
    txt = S[f]
    open(os.path.join(OUT_DIR, f"CB{i:02d}.lua"), "w", encoding="utf-8").write(txt)
    sizes.append(len(txt))

# CB03: launchers 1 (MainUI + Bundle_Editors)
body = ('local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")\n'
        + folder("spps", "Arkher")
        + emb("S_MAIN", S["ArkherStudio_MainUI.lua"])
        + emb("S_ED", S["UI_Bundle_Editors.lua"])
        + put("arkher", "ArkherMainUI", "LocalScript", "S_MAIN")
        + put("arkher", "ArkherBundle_Editors", "LocalScript", "S_ED")
        + 'print("[ARKHER V3] (3/13) MainUI + Bundle_Editors instalados em StarterPlayerScripts.Arkher")\n')
sizes.append(build_cb(3, "Launchers 1/2 — MainUI + Bundle_Editors",
                      "StarterPlayerScripts.Arkher.{ArkherMainUI, ArkherBundle_Editors} (LocalScripts ativos)", body))

# CB04: Bundle_Scene ; CB05: Bundle_System
for idx, fname in ((4, "UI_Bundle_Scene"), (5, "UI_Bundle_System")):
    nm = fname.replace("UI_", "Arkher")
    body = ('local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")\n'
            + folder("spps", "Arkher")
            + emb("S_SC", S[fname + ".lua"])
            + put("arkher", nm, "LocalScript", "S_SC")
            + f'print("[ARKHER V3] ({idx}/13) {nm} instalado em StarterPlayerScripts.Arkher")\n')
    sizes.append(build_cb(idx, f"Launcher {2 if idx == 4 else 3}/2 — {nm}",
                          f"StarterPlayerScripts.Arkher.{nm} (LocalScript ativo)", body))

# CB06/CB07: 12+12 paineis (LocalScripts desativados)
for idx, lista in ((6, PAINELS_A), (7, PAINELS_B)):
    body = ('local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")\n'
            + folder("spps", "Arkher")
            + folder("arkher", "Panels"))
    for i, p in enumerate(lista):
        body += emb(f"S_{i}", S[f"{p}.lua"])
    for i, p in enumerate(lista):
        body += put("panels", p, "LocalScript", f"S_{i}", disabled=True)
    body += (f'print("[ARKHER V3] ({idx}/13) {len(lista)} paineis instalados em '
             f'StarterPlayerScripts.Arkher.Panels (DESATIVADOS — habilite um por um para testar)")\n')
    sizes.append(build_cb(idx, f"Paineis {lista[0]}…{lista[-1]}",
                          "StarterPlayerScripts.Arkher.Panels: " + ", ".join(lista), body))

# CB08/CB09: installers em ServerScriptService (desativados) + ServerStorage
for idx, f, extra in ((8, "ArkherKit_Installer_A.lua", None),
                      (9, "ArkherKit_Installer_B.lua", "ServerStorage.ArkherData")):
    nm = f.replace(".lua", "")
    top = ('local sss = game:GetService("ServerScriptService")\n'
           + folder("sss", "Arkher"))
    body = top + emb("S_INST", S[f], level=5) + put("arkher", nm, "Script", "S_INST", disabled=True)
    if extra:
        body += ('local ss = game:GetService("ServerStorage")\n'
                 + folder("ss", "ArkherData")
                 + 'print("[ARKHER V3] (9/13) ServerStorage.ArkherData criado (namespace de dados do servidor)")\n')
    body += f'print("[ARKHER V3] ({idx}/13) {nm} guardado em ServerScriptService.Arkher (desativado)")\n'
    sizes.append(build_cb(idx, f"Server — {nm}",
                          f"ServerScriptService.Arkher.{nm} (Script desativado)" +
                          (f" + {extra}" if extra else ""), body, extra_top=top if not top else ""))

# CB10-12: chunks do ALL (ModuleScripts em ReplicatedStorage.ArkherV3.ALL)
for idx, (cn, p) in enumerate(zip(("ALL_P1", "ALL_P2", "ALL_P3"), MODULE_ALL), 10):
    body = ('local rs = game:GetService("ReplicatedStorage")\n'
            + folder("rs", "ArkherV3")
            + folder("arkherv3", "ALL")
            + emb("S_CHUNK", p, level=5)
            + put("all", cn, "ModuleScript", "S_CHUNK")
            + f'print("[ARKHER V3] ({idx}/13) {cn} instalado em ReplicatedStorage.ArkherV3.ALL ({len(p):,} chars)")\n')
    sizes.append(build_cb(idx, f"ArkherStudio_ALL chunk {idx - 9}/3",
                          f"ReplicatedStorage.ArkherV3.ALL.{cn} (ModuleScript, {len(p):,} chars)", body))

# CB13: assembler
body = ('local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")\n'
        + folder("spps", "Arkher")
        + emb("S_ASM", ASSEMBLE_SRC)
        + put("arkher", "ArkherALL_Assemble", "LocalScript", "S_ASM", disabled=True)
        + 'print("[ARKHER V3] (13/13) ArkherALL_Assemble pronto (desativado). Estrutura COMPLETA criada!")\n')
sizes.append(build_cb(13, "Assembler do ALL",
                      "StarterPlayerScripts.Arkher.ArkherALL_Assemble (LocalScript desativado)", body))

print("== scripts de Command Bar gerados ==")
for i, sz in enumerate(sizes, 1):
    flag = "  MUITO GRANDE!" if sz > 95_000 else ""
    print(f"  CB{i:02d}.lua  {sz:>7,} chars{flag}")
assert all(sz <= 95_000 for sz in sizes), "algum script passa de 95K"

# ---------------- .rbxl completo (79 instancias) ----------------------------
TREE = [(c, c, None, False) for c in SERVICES]
TREE += [
    ("StarterPlayerScripts", "StarterPlayerScripts", "StarterPlayer", False),
    ("StarterCharacterScripts", "StarterCharacterScripts", "StarterPlayer", False),
    ("Folder", "ArkherV3", "ReplicatedStorage", False),
    ("ModuleScript", "ArkherKit_A", "ArkherV3", False),
    ("ModuleScript", "ArkherKit_B", "ArkherV3", False),
    ("Folder", "ALL", "ArkherV3", False),
    ("ModuleScript", "ALL_P1", "ALL", False),
    ("ModuleScript", "ALL_P2", "ALL", False),
    ("ModuleScript", "ALL_P3", "ALL", False),
    ("Folder", "Arkher", "StarterPlayerScripts", False),
    ("LocalScript", "ArkherMainUI", "Arkher", False),
    ("LocalScript", "ArkherBundle_Editors", "Arkher", False),
    ("LocalScript", "ArkherBundle_Scene", "Arkher", False),
    ("LocalScript", "ArkherBundle_System", "Arkher", False),
    ("LocalScript", "ArkherALL_Assemble", "Arkher", True),
    ("Folder", "Panels", "Arkher", False),
] + [(cls, p, "Panels", True) for cls, p in [("LocalScript", p) for p in PAINELS_A + PAINELS_B]]
TREE += [
    ("Folder", "Arkher", "ServerScriptService", False),
    ("Script", "ArkherKit_Installer_A", "Arkher", True),
    ("Script", "ArkherKit_Installer_B", "Arkher", True),
    ("Folder", "ArkherData", "ServerStorage", False),
]

SOURCES = {
    ("ModuleScript", "ArkherKit_A"): S["ArkherKit_A.lua"],
    ("ModuleScript", "ArkherKit_B"): S["ArkherKit_B.lua"],
    ("ModuleScript", "ALL_P1"): MODULE_ALL[0],
    ("ModuleScript", "ALL_P2"): MODULE_ALL[1],
    ("ModuleScript", "ALL_P3"): MODULE_ALL[2],
    ("LocalScript", "ArkherMainUI"): S["ArkherStudio_MainUI.lua"],
    ("LocalScript", "ArkherBundle_Editors"): S["UI_Bundle_Editors.lua"],
    ("LocalScript", "ArkherBundle_Scene"): S["UI_Bundle_Scene.lua"],
    ("LocalScript", "ArkherBundle_System"): S["UI_Bundle_System.lua"],
    ("LocalScript", "ArkherALL_Assemble"): ASSEMBLE_SRC,
    ("Script", "ArkherKit_Installer_A"): S["ArkherKit_Installer_A.lua"],
    ("Script", "ArkherKit_Installer_B"): S["ArkherKit_Installer_B.lua"],
}
for p in PAINELS_A + PAINELS_B:
    SOURCES[("LocalScript", p)] = S[f"{p}.lua"]


def resolve_parents(tree):
    """referent do pai de cada instancia (TREE em ordem pai-antes-filhos;
    quando ha dois 'Arkher', o ultimo definido e o da sub-arvore certa)."""
    defined = {}
    parent_of = [None] * len(tree)
    for i, (cls, name, parent, dis) in enumerate(tree):
        if parent:
            assert defined.get(parent), f"pai {parent!r} nao definido antes"
            parent_of[i] = defined[parent][-1]
        defined.setdefault(name, []).append(i)
    return parent_of


def build_rbxl() -> bytes:
    parent_of = resolve_parents(TREE)
    instances = [(cls, name, parent_of[i], dis)
                 for i, (cls, name, parent, dis) in enumerate(TREE)]

    type_order, type_refs = [], {}
    for i, (cls, *_r) in enumerate(instances):
        if cls not in type_refs:
            type_refs[cls] = []
            type_order.append(cls)
        type_refs[cls].append(i)

    out = bytearray(MAGIC)
    out += struct.pack("<H", 0)
    out += struct.pack("<I", len(type_order))
    out += struct.pack("<I", len(instances))
    out += b"\x00" * 8
    out += chunk(b"META", struct.pack("<I", 1) + s("ExplicitAutoJoints") + s("true"))

    for tid, cls in enumerate(type_order):
        refs = type_refs[cls]
        is_svc = 1 if cls in SERVICE_CLASSES else 0
        payload = struct.pack("<I", tid) + s(cls) + struct.pack("<B", is_svc)
        payload += struct.pack("<I", len(refs)) + referent_array_enc(refs)
        if is_svc:
            payload += b"\x01" * len(refs)
        out += chunk(b"INST", payload)

    for tid, cls in enumerate(type_order):
        refs = type_refs[cls]
        payload = struct.pack("<I", tid) + s("Name") + struct.pack("<B", 1)
        for i in refs:
            payload += s(instances[i][1])
        out += chunk(b"PROP", payload)
        if any(instances[i][3] for i in refs) and cls in ("LocalScript", "Script"):
            sp = struct.pack("<I", tid) + s("Disabled") + struct.pack("<B", 2)
            sp += bytes(1 if instances[i][3] else 0 for i in refs)
            out += chunk(b"PROP", sp)
        if all((instances[i][0], instances[i][1]) in SOURCES for i in refs) and \
           cls in ("ModuleScript", "LocalScript", "Script"):
            sp = struct.pack("<I", tid) + s("Source") + struct.pack("<B", 1)
            for i in refs:
                src = SOURCES[(instances[i][0], instances[i][1])]
                if len(src) > 100_000:
                    sys.exit(f"{instances[i][1]} excede 100.000 chars")
                sp += s(src)
            out += chunk(b"PROP", sp)

    prnt = struct.pack("<B", 0) + struct.pack("<I", len(instances))
    prnt += referent_array_enc(list(range(len(instances))))
    prnt += referent_array_enc([-1 if inst[2] is None else inst[2] for inst in instances])
    out += chunk(b"PRNT", prnt)
    out += chunk(b"END\x00", b"</roblox>")
    return bytes(out), type_order


data, type_order = build_rbxl()
open(RBXL_OUT, "wb").write(data)
print(f"\n.rbxl gerado: {RBXL_OUT} ({len(data):,} bytes, {len(TREE)} instancias)")

# ---------------- validacao -------------------------------------------------
m = pyrbxl2.parse(data)
assert m.num_types == len(type_order)
assert m.num_instances == len(TREE)
names, sources, disabled = {}, {}, {}
for name, payload, parsed in m.chunks:
    if name != b"PROP":
        continue
    cr = pyrbxl2.R(payload)
    tid = cr.u32()
    pname = cr.string()
    t = cr.u8()
    refs = next(nc[2][3] for nc in m.chunks
                if nc[0] == b"INST" and nc[2] and nc[2][0] == tid)
    if t == 1:
        vals = [cr.take(cr.u32()).decode("utf-8") for _ in refs]
        for r, v in zip(refs, vals):
            (names if pname == "Name" else sources)[r] = v
    elif t == 2:
        vals = [cr.take(1)[0] for _ in refs]
        for r, v in zip(refs, vals):
            disabled[r] = bool(v)

cls_of = {}
for nc in m.chunks:
    if nc[0] == b"INST" and nc[2]:
        for r in nc[2][3]:
            cls_of[r] = nc[2][1]
prnt = next(parsed for n, p, parsed in m.chunks if n == b"PRNT" and parsed)
got_parent = dict(zip(prnt[1], prnt[2]))
exp_parent = resolve_parents(TREE)
ref = {}
ok = True
for i, (cls, name, parent, dis) in enumerate(TREE):
    if cls_of.get(i) != cls or names.get(i) != name:
        print(f"  FALHA inst {i}: {cls_of.get(i)}/{names.get(i)!r} != {cls}/{name!r}")
        ok = False
    if got_parent.get(i) != (exp_parent[i] if exp_parent[i] is not None else -1):
        print(f"  FALHA parent {i} {name}: {got_parent.get(i)} != {exp_parent[i]}")
        ok = False
    if (cls, name) in SOURCES and sources.get(i) != SOURCES[(cls, name)]:
        print(f"  FALHA source {i} {name}")
        ok = False
    if disabled.get(i, False) != dis:
        print(f"  FALHA disabled {i} {name}: {disabled.get(i)} != {dis}")
        ok = False
print("round-trip .rbxl:", "100% OK" if ok else "FALHOU")

# chunks do ALL reconstruem o original
ref2 = {}
for i, (cls, name, parent, dis) in enumerate(TREE):
    ref2[(parent, name)] = i
# o valor retornado pelo require = o conteudo do long string (sem o wrapper)
def strip_wrapper(src):
    return src[len("return[====["):src.rindex("]====]")]
got = b"".join(strip_wrapper(sources[ref2[("ALL", n)]]).encode("utf-8")
              for n in ("ALL_P1", "ALL_P2", "ALL_P3"))
print("ALL p1..p3:", "IDENTICO ao original (250.993 chars)" if got.decode() == ALL else "DIVERGE")

# lupa: compila os 13 scripts
import lupa  # noqa: E402
L = lupa.LuaRuntime()
bad = []
for i in range(1, 14):
    p = os.path.join(OUT_DIR, f"CB{i:02d}.lua")
    try:
        L.compile(open(p, encoding="utf-8").read())
    except Exception as e:
        bad.append((p, str(e)[:120]))
print("lupa (sintaxe dos 13 CB):", "TODOS OK" if not bad else bad)

sys.exit(0 if ok and not bad and got.decode() == ALL else 1)
