#!/usr/bin/env python3
"""Build do ARKHER V3 COMPLETO:

1. Extrai a arvore INTEIRA do ARKHER_V2.rbxl (290.467 instancias:
   290.000 customs + 333 generated + core/editors/maps/systems/ui + UI no
   StarterGui + ARKHER_Boot + ARKHER_HUD + Ground).
2. Reescreve o .rbxl no formato v0 com compressao LZ4 (igual ao V2) contendo:
   - os 37 services (place completo)
   - ReplicatedStorage.ARKHER = catalogo V2 inteiro (fontes byte-identicas)
   - ReplicatedStorage.ArkherV3 = kits + chunks ALL (engine V3)
   - StarterPlayerScripts.ARKHER_HUD (V2) + Arkher (launchers/24 paineis/assemble)
   - ServerScriptService.ARKHER_Boot (V2) + Arkher (installers desativados)
   - StarterGui.ARKHER_Studio (UI completa com todas as propriedades)
   - Workspace.Ground + Lighting + ServerStorage.ArkherData
3. Gera o script de Command Bar que cria a UI em StarterGui (fiel ao V2).
4. Valida: re-parse do arquivo gerado, compara TODAS as fontes, nomes, parents
   e bytes crus das propriedades com o V2 de origem.
"""
import collections
import glob
import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lz4.block  # noqa: E402
import pyrbxl2  # noqa: E402
import rbxcodec  # noqa: E402
from make_rbxl import (MAGIC, referent_array_enc, s, SERVICE_CLASSES,  # noqa: E402
                       SERVICES)

DIST = os.path.dirname(HERE)
CB_DIR = os.path.join(DIST, "commandbar")
V2 = os.environ.get("V2_RBXL", "/tmp/v2/ARKHER_V2.rbxl")
OUT_RBXL = os.path.join(CB_DIR, "arkher-v3.rbxl")
OUT_UI = os.path.join(CB_DIR, "estrutura-completa", "CB_UI_StarterGui.lua")

# ---------------------------------------------------------------- leitura V2
print("lendo V2...", flush=True)
m2 = pyrbxl2.parse(open(V2, "rb").read())
N2 = m2.num_instances

v2_services = {}
v2_cls = {}
for n, p, ps in m2.chunks:
    if n == b"INST" and ps:
        _, cls, is_svc, refs, _flags = ps
        for r in refs:
            v2_cls[r] = cls
            if is_svc:
                v2_services[r] = cls
v2_name = {}
v2_src = {}
v2_props = collections.defaultdict(dict)
for n, p, ps in m2.chunks:
    if n != b"PROP":
        continue
    cr = pyrbxl2.R(p)
    tid = cr.u32()
    pname = cr.string()
    t = cr.u8()
    refs = next(nc[2][3] for nc in m2.chunks
                if nc[0] == b"INST" and nc[2] and nc[2][0] == tid)
    if t == 1:
        # strings: u32 len + utf8, sequencial (sem transformacao)
        buf = cr.take(len(p) - cr.i)
        off = 0
        for r in refs:
            ln = int.from_bytes(buf[off:off + 4], "little")
            b = buf[off + 4:off + 4 + ln]
            off += 4 + ln
            if pname == "Name":
                v2_name[r] = b.decode("utf-8")
            elif pname == "Source":
                v2_src[r] = b.decode("utf-8")
            else:
                v2_props[r][pname] = (1, b.decode("utf-8"))
    elif t == 2:
        buf = cr.take(len(p) - cr.i)
        for r, b in zip(refs, buf):
            v2_props[r][pname] = (2, b != 0)
    else:
        # spec dom.rojo.space: Int32=BE+zigzag, Float32=fmt Roblox+BE,
        # arrays byte-interleaved; UDim/UDim2/Color3/Vector2 = arrays de componentes
        buf = cr.take(len(p) - cr.i)
        vals = rbxcodec.decode(t, buf, len(refs))
        for r, v in zip(refs, vals):
            v2_props[r][pname] = (t, v)

prnt2 = next(ps for n, p, ps in m2.chunks if n == b"PRNT" and ps)
subj2, par2 = prnt2[1], prnt2[2]
v2_parent = dict(zip(subj2, par2))

v2_non_service = sorted(r for r in range(N2) if r not in v2_services)
print(f"V2: {N2} instancias, {len(v2_non_service)} nao-service, "
      f"{len(v2_src)} fontes", flush=True)

# ------------------------------------------------- engine V3 (fontes locais)
S = {os.path.basename(f): open(f, encoding="utf-8").read()
     for f in sorted(glob.glob(os.path.join(CB_DIR, "*.lua")))}
ALL = S["ArkherStudio_ALL.lua"]
ln = ALL.split("\n")
szs = [len(x) + 1 for x in ln]
tot = sum(szs)
t1, t2 = tot // 3, 2 * tot // 3
acc = c1 = c2 = 0
for i, sz in enumerate(szs):
    if c1 == 0 and acc + sz > t1:
        c1 = i
    if c2 == 0 and c1 and acc + sz > t2:
        c2 = i
    acc += sz
P1 = ALL[:sum(szs[:c1])]
P2 = ALL[sum(szs[:c1]):sum(szs[:c2])]
P3 = ALL[sum(szs[:c2]):]
MODULE_ALL = [f"return[====[{p}]====]\n" for p in (P1, P2, P3)]

ns = {}
_gen = open(os.path.join(HERE, "make_estrutura_completa.py"),
            encoding="utf-8").read()
exec(compile(re.search(r"ASSEMBLE_SRC = '''.*?'''", _gen, re.S).group(0),
             "<asm>", "exec"), ns)
ASM_SRC = ns["ASSEMBLE_SRC"]

PAINELS = ["UI_AI", "UI_About", "UI_Animator", "UI_Audio", "UI_Camera",
           "UI_City", "UI_Cloud", "UI_CommandPalette", "UI_Console",
           "UI_Lighting", "UI_Map", "UI_Modeler", "UI_NPCs", "UI_Open",
           "UI_Particles", "UI_Performance", "UI_Physics", "UI_Publish",
           "UI_SaveExport", "UI_SaveOpen", "UI_Script", "UI_Settings",
           "UI_Terrain", "UI_UIDesigner"]

A_SPS = "Arkher_SPS"
A_SSS = "Arkher_SSS"
V3 = [
    ("Folder", "ArkherV3", "ReplicatedStorage", None, False),
    ("ModuleScript", "ArkherKit_A", "ArkherV3", S["ArkherKit_A.lua"], False),
    ("ModuleScript", "ArkherKit_B", "ArkherV3", S["ArkherKit_B.lua"], False),
    ("Folder", "ALL", "ArkherV3", None, False),
    ("ModuleScript", "ALL_P1", "ALL", MODULE_ALL[0], False),
    ("ModuleScript", "ALL_P2", "ALL", MODULE_ALL[1], False),
    ("ModuleScript", "ALL_P3", "ALL", MODULE_ALL[2], False),
    ("Folder", "Arkher", "StarterPlayerScripts", None, False),
    ("LocalScript", "ArkherMainUI", A_SPS, S["ArkherStudio_MainUI.lua"], False),
    ("LocalScript", "ArkherBundle_Editors", A_SPS, S["UI_Bundle_Editors.lua"], False),
    ("LocalScript", "ArkherBundle_Scene", A_SPS, S["UI_Bundle_Scene.lua"], False),
    ("LocalScript", "ArkherBundle_System", A_SPS, S["UI_Bundle_System.lua"], False),
    ("LocalScript", "ArkherALL_Assemble", A_SPS, ASM_SRC, True),
    ("Folder", "Panels", A_SPS, None, False),
] + [("LocalScript", p, "Panels", S[f"{p}.lua"], True) for p in PAINELS] + [
    ("Folder", "Arkher", "ServerScriptService", None, False),
    ("Script", "ArkherKit_Installer_A", A_SSS, S["ArkherKit_Installer_A.lua"], True),
    ("Script", "ArkherKit_Installer_B", A_SSS, S["ArkherKit_Installer_B.lua"], True),
    ("Folder", "ArkherData", "ServerStorage", None, False),
]

# ------------------------------------------------------------- montagem tree
rank2 = {r: 37 + i for i, r in enumerate(v2_non_service)}
svc_name2my = {sv: i for i, sv in enumerate(SERVICES)}
MY = []
for sv in SERVICES:
    MY.append((sv, sv, None, None, False))
for r in v2_non_service:
    par = v2_parent.get(r, -1)
    if par == -1:
        par_ref = None
    elif par in v2_services:
        par_ref = svc_name2my[v2_services[par]]
    else:
        par_ref = rank2[par]
    MY.append((v2_cls[r], v2_name[r], par_ref, v2_src.get(r), False))

name2ref = {MY[i][1]: i for i in range(len(SERVICES))}
v3_start = len(MY)
for cls, nm, par, src, dis in V3:
    idx = len(MY)
    MY.append((cls, nm, None, src, dis))
    if (par, nm) in name2ref:
        raise SystemExit(f"nome duplicado: {(par, nm)}")
    name2ref[(par, nm)] = idx
    if nm not in name2ref:
        name2ref[nm] = idx
    if cls == "Folder" and nm == "Arkher":
        name2ref[A_SPS if name2ref.get(A_SPS) is None else A_SSS] = idx
    if par in name2ref:
        MY[idx] = (cls, nm, name2ref[par], src, dis)

N = len(MY)
print(f"tree final: {N} instancias (37 services + {len(v2_non_service)} V2 + "
      f"{len(V3)} V3)", flush=True)

type_order, type_refs = [], {}
for i, (cls, *_r) in enumerate(MY):
    if cls not in type_refs:
        type_refs[cls] = []
        type_order.append(cls)
    type_refs[cls].append(i)


def chunk(name: bytes, payload: bytes) -> bytes:
    if len(payload) > 512:
        c = lz4.block.compress(payload, store_size=False)
        if len(c) < len(payload):
            return name + struct.pack("<III", len(c), len(payload), 0) + c
    return name + struct.pack("<III", 0, len(payload), 0) + payload


out = bytearray(MAGIC)
out += struct.pack("<H", 0)
out += struct.pack("<I", len(type_order))
out += struct.pack("<I", N)
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

SCRIPT_CLASSES = ("ModuleScript", "LocalScript", "Script")
for tid, cls in enumerate(type_order):
    refs = type_refs[cls]
    parts = [struct.pack("<I", tid) + s("Name") + struct.pack("<B", 1)]
    for i in refs:
        parts.append(s(MY[i][1]))
    out += chunk(b"PROP", b"".join(parts))
    if cls in SCRIPT_CLASSES:
        parts = [struct.pack("<I", tid) + s("Source") + struct.pack("<B", 1)]
        for i in refs:
            src = MY[i][3] or ""
            if len(src) > 100_000:
                raise SystemExit(f"{MY[i][1]} > 100k chars")
            parts.append(s(src))
        out += chunk(b"PROP", b"".join(parts))
    extra = collections.defaultdict(list)
    for i in refs:
        if 37 <= i < v3_start:
            v2r = v2_non_service[i - 37]
            for pname, val in v2_props.get(v2r, {}).items():
                extra[pname].append((i, val))
    # valores default p/ props do V2 que a V3 nao tem (explicit default = legal)
    DEFAULTS = {("Script", "RunContext"): 1}
    for pname, vals in extra.items():
        t = vals[0][1][0]
        byref = dict(vals)
        values = []
        for i in refs:
            if i in byref:
                values.append(byref[i][1])
            elif (cls, pname) in DEFAULTS:
                values.append(DEFAULTS[(cls, pname)])
            else:
                raise SystemExit(f"sem valor p/ ({cls},{pname}) ref {i}")
        payload = struct.pack("<I", tid) + s(pname) + struct.pack("<B", t)
        if t == 1:
            payload += b"".join(s(v) for v in values)
        elif t == 2:
            payload += bytes(1 if v else 0 for v in values)
        else:
            payload += rbxcodec.encode(t, values)
        out += chunk(b"PROP", payload)
    if cls in ("LocalScript", "Script") and any(i >= v3_start for i in refs):
        parts = [struct.pack("<I", tid) + s("Disabled") + struct.pack("<B", 2)]
        parts.append(bytes(1 if (MY[i][4] and i >= v3_start) else 0
                           for i in refs))
        out += chunk(b"PROP", b"".join(parts))

prnt = struct.pack("<B", 0) + struct.pack("<I", N)
prnt += referent_array_enc(list(range(N)))
prnt += referent_array_enc([MY[i][2] if MY[i][2] is not None else -1
                            for i in range(N)])
out += chunk(b"PRNT", prnt)
out += chunk(b"END\x00", b"</roblox>")

data = bytes(out)
open(OUT_RBXL, "wb").write(data)
print(f".rbxl gerado: {OUT_RBXL} ({len(data):,} bytes)", flush=True)

# ---------------------------------------------------------------- validacao
# (validacao completa em 2 passes — tools/validate_completo.py A e B —
#  para nao estourar a RAM com dois parses de ~650MB no mesmo processo)
print("validacao 2-pass: rode  python3 tools/validate_completo.py A  e  "
      "python3 tools/validate_completo.py B", flush=True)

# UI command bar
print("gerando CB_UI_StarterGui.lua...", flush=True)
sg_ref = None
for r in v2_non_service:
    if v2_cls[r] == "ScreenGui" and v2_name.get(r) == "ARKHER_Studio":
        sg_ref = r
        break
assert sg_ref is not None
kidx2 = collections.defaultdict(list)
for subj, par in zip(subj2, par2):
    kidx2[par].append(subj)
ui_tree = []  # (nome, classe, parent_local_idx, props_semantic)
order = []

def walk(r):
    idx = len(order)
    order.append(r)
    for c in kidx2.get(r, []):
        walk(c)
walk(sg_ref)

PROP_ENUM = {
    "Font": "FONT",
    "TextXAlignment": "XA",
    "ZIndexBehavior": "ZIB",
}


def val_lua(pname, t, v):
    """v = valor python ja decodificado (rbxcodec)."""
    if t == 1:
        return repr(v)
    if t == 2:
        return "true" if v else "false"
    if t == 3:
        return str(v)
    if t == 4:
        return repr(v)
    if t == 6:
        return f"UDim.new({repr(v[0])}, {v[1]})"
    if t == 7:
        return f"UDim2.new({repr(v[0])}, {v[1]}, {repr(v[2])}, {v[3]})"
    if t == 12:
        return f"Color3.new({repr(v[0])}, {repr(v[1])}, {repr(v[2])})"
    if t == 13:
        return f"Vector2.new({repr(v[0])}, {repr(v[1])})"
    if t == 18:
        if pname in PROP_ENUM:
            return f"{PROP_ENUM[pname]}[{v}]"
        return str(v)
    raise SystemExit(f"tipo nao suportado {pname} t={t}")

lines = []
lines.append("--[[ =====================================================================")
lines.append("  ARKHER — UI COMPLETA NO STARTERGUI (Command Bar)")
lines.append(f"  Cria: StarterGui.ArkherStudio (ScreenGui com {len(order)} instancias —")
lines.append("  TopBar, Explorer, Properties, StatusBar, Loading — fiel ao ARKHER_V2)")
lines.append("  Uso: View > Command Bar > cole TODO > Run (idempotente: recria)")
lines.append("====================================================================== ]]")
lines.append("local sg = game:GetService(\"StarterGui\")")
lines.append("local old = sg:FindFirstChild(\"ARKHER_Studio\")")
lines.append("if old then old:Destroy() end")
lines.append("local FONT = {} for _, e in ipairs(Enum.Font:GetEnums()) do FONT[e.Value] = e end")
lines.append("local XA = {} for _, e in ipairs(Enum.TextXAlignment:GetEnums()) do XA[e.Value] = e end")
lines.append("local ZIB = {} for _, e in ipairs(Enum.ZIndexBehavior:GetEnums()) do ZIB[e.Value] = e end")
for idx, r in enumerate(order):
    cls = v2_cls[r]
    nm = v2_name[r]
    var = "v0" if idx == 0 else f"v{idx}"
    lines.append(f"local {var} = Instance.new(\"{cls}\")")
    if cls != "ScreenGui" or True:
        lines.append(f"{var}.Name = {repr(nm)}")
    for pname, (t, v) in v2_props.get(r, {}).items():
        lines.append(f"{var}.{pname} = {val_lua(pname, t, v)}")
    par = v2_parent[r]
    if par == sg_ref:
        # parent e o proprio ScreenGui ARKHER_Studio (v0)
        lines.append(f"{var}.Parent = v0")
    elif par in v2_services:
        # parent e um service do V2 (StarterGui) — so acontece p/ o ScreenGui
        lines.append(f"{var}.Parent = sg")
    else:
        pidx = order.index(par)
        lines.append(f"{var}.Parent = v{pidx}")
lines.append('print("[ARKHER] UI completa criada em StarterGui.ArkherStudio (' + str(len(order)) + ' instancias)")')
open(OUT_UI, "w", encoding="utf-8").write("\n".join(lines) + "\n")
print(f"UI script: {OUT_UI} ({os.path.getsize(OUT_UI):,} bytes, {len(order)} instancias)")
