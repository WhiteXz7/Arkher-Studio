#!/usr/bin/env python3
"""Validacao em 2 passes (memoria) do ARKHER V3 completo + gera o CB da UI.

Pass A: parse do meu .rbxl -> confere design (contagens, nomes, classes,
parents), sha1 de todas as fontes, props decodificadas (spec rbxcodec)
-> /tmp/v3check.json
Pass B: parse do ARKHER_V2.rbxl -> compara classes/nomes/parents/fontes/
props (valores decodificados) com o pass A. Gera CB_UI_StarterGui.lua.

Propriedades decodificadas segundo a spec do formato binario
(dom.rojo.space/binary.html): Int32 = u32 zigzag BE; Float32 = formato
Roblox (sinal no LSB) BE; arrays byte-interleaved; UDim/UDim2/Color3/
Vector2 = arrays de componentes.
"""
import collections
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pyrbxl2  # noqa: E402
import rbxcodec  # noqa: E402

DIST = os.path.dirname(HERE)
CB_DIR = os.path.join(DIST, "commandbar")
MY_RBXL = os.path.join(CB_DIR, "arkher-v3.rbxl")
V2 = os.environ.get("V2_RBXL", "/tmp/v2/ARKHER_V2.rbxl")
OUT_UI = os.path.join(CB_DIR, "estrutura-completa", "CB_UI_StarterGui.lua")
TMP = "/tmp/v3check.json"

from make_rbxl import (SERVICE_CLASSES, SERVICES)  # noqa: E402

SV = len(SERVICES)

PAINELS = ["UI_AI", "UI_About", "UI_Animator", "UI_Audio", "UI_Camera",
           "UI_City", "UI_Cloud", "UI_CommandPalette", "UI_Console",
           "UI_Lighting", "UI_Map", "UI_Modeler", "UI_NPCs", "UI_Open",
           "UI_Particles", "UI_Performance", "UI_Physics", "UI_Publish",
           "UI_SaveExport", "UI_SaveOpen", "UI_Script", "UI_Settings",
           "UI_Terrain", "UI_UIDesigner"]


def read_props(m, ib):
    """decodifica TODOS os chunks PROP de m -> (name, src, props).
    props[ref][pname] = (t, valor_python)."""
    name, src, props = {}, {}, collections.defaultdict(dict)
    for n, p, ps in m.chunks:
        if n != b"PROP":
            continue
        cr = pyrbxl2.R(p)
        tid = cr.u32()
        pname = cr.string()
        t = cr.u8()
        refs = ib[tid]
        if t == 1:
            # strings: u32 len + utf8, sequencial (sem transformacao)
            buf = cr.take(len(p) - cr.i)
            off = 0
            for r in refs:
                ln = int.from_bytes(buf[off:off + 4], "little")
                b = buf[off + 4:off + 4 + ln]
                off += 4 + ln
                if pname == "Name":
                    name[r] = b.decode("utf-8")
                elif pname == "Source":
                    src[r] = b.decode("utf-8")
                else:
                    props[r][pname] = (1, b.decode("utf-8"))
        elif t == 2:
            buf = cr.take(len(p) - cr.i)
            for r, b in zip(refs, buf):
                props[r][pname] = (2, b != 0)
        else:
            buf = cr.take(len(p) - cr.i)
            vals = rbxcodec.decode(t, buf, len(refs))
            for r, v in zip(refs, vals):
                props[r][pname] = (t, v)
    return name, src, props


def norm(v):
    """normaliza p/ comparacao JSON (tuples -> lists)."""
    if isinstance(v, tuple):
        return [norm(x) for x in v]
    return v


def h(s):
    return hashlib.sha1(s.encode("utf-8")).hexdigest()


# ------------------------------------------------------------------- pass A
if len(sys.argv) > 1 and sys.argv[1] == "A":
    m = pyrbxl2.parse(open(MY_RBXL, "rb").read())
    N = m.num_instances
    cls = {}
    ib = {}
    for n, p, ps in m.chunks:
        if n == b"INST" and ps:
            ib[ps[0]] = ps[3]
            for r in ps[3]:
                cls[r] = ps[1]
    name, src, props = read_props(m, ib)
    prnt = next(ps for n, p, ps in m.chunks if n == b"PRNT" and ps)
    parent = dict(zip(prnt[1], prnt[2]))

    out = {"N": N, "names": {}, "cls": {}, "parents": {},
           "src_hash": {}, "props": {}}
    for i in range(N):
        out["names"][str(i)] = name.get(i, "")
        out["cls"][str(i)] = cls.get(i, "")
        out["parents"][str(i)] = parent.get(i, -1)
    for i in range(SV, SV + 290461):
        if cls.get(i) in ("ModuleScript", "LocalScript", "Script") and i in src:
            out["src_hash"][str(i)] = h(src[i])
    for i, d in props.items():
        for k, (t, v) in d.items():
            out["props"][f"{i}:{k}"] = [t, norm(v)]
    json.dump(out, open(TMP, "w"))
    print(f"PASS A ok: {N} insts, {len(out['src_hash'])} hashes, "
          f"{len(out['props'])} props -> {TMP}")
    sys.exit(0)

# ------------------------------------------------------------------- pass B
mine = json.load(open(TMP))
m = pyrbxl2.parse(open(V2, "rb").read())
N2 = m.num_instances
cls = {}
svc = set()
ib = {}
for n, p, ps in m.chunks:
    if n == b"INST" and ps:
        ib[ps[0]] = ps[3]
        for r in ps[3]:
            cls[r] = ps[1]
            if ps[2]:
                svc.add(r)
name, src, props = read_props(m, ib)
prnt = next(ps for n, p, ps in m.chunks if n == b"PRNT" and ps)
parent = dict(zip(prnt[1], prnt[2]))

v2_ns = sorted(r for r in range(N2) if r not in svc)
assert len(v2_ns) == 290461, len(v2_ns)

bad_src = 0
checked = 0
bad_props = 0
for idx, v2r in enumerate(v2_ns):
    my = SV + idx
    # 1) estrutura esperada no meu arquivo
    if mine["cls"].get(str(my)) != cls[v2r]:
        bad_src += 1
        print("CLS", my, mine["cls"].get(str(my)), cls[v2r])
        if bad_src > 3:
            sys.exit(1)
    if mine["names"].get(str(my)) != name[v2r]:
        bad_src += 1
        print("NOME", my)
    par = parent.get(v2r, -1)
    # parent esperado: service V2 -> index em SERVICES; nao-service -> SV+rank
    if par == -1:
        exp_par = -1
    elif par in svc:
        exp_par = SERVICES.index(cls[par])
    else:
        exp_par = SV + v2_ns.index(par)
    if mine["parents"].get(str(my)) != exp_par:
        bad_src += 1
        print("PARENT", my, mine["parents"].get(str(my)), exp_par)
        if bad_src > 5:
            sys.exit(1)
    # 2) fonte
    if cls[v2r] in ("ModuleScript", "LocalScript", "Script") and v2r in src:
        if mine["src_hash"].get(str(my)) != h(src[v2r]):
            bad_src += 1
            print("SOURCE DIVERGE", v2r, name[v2r])
        checked += 1
    # 3) props (valores decodificados)
    for pname, (t, v) in props.get(v2r, {}).items():
        key = f"{my}:{pname}"
        mp = mine["props"].get(key)
        if mp is None or mp[0] != t or mp[1] != norm(v):
            bad_props += 1
            if bad_props <= 10:
                print("PROP", key, mp, "vs", t, norm(v))
print(f"PASS B: {checked} fontes comparadas, "
      f"{bad_src} divergencias estrutura/fonte, {bad_props} props divergentes")

# V3: conferir presenca/nomes
V3_N = 66
v3_names = {"ArkherV3", "ALL", "Remotes", "ArkherPublish", "ArkherData",
            "Arkher_S0_First", "Arkher_S1_Boot", "Arkher", "ArkherCloud",
            "Published", "Backups", "Panels", "StarterCharacterScripts",
            "Arkher_C0_Character", "ArkherTool", "Handle", "ToolUI",
            "Arkher_N0_Legacy", "ArkherSfx", "Click", "Success", "Error",
            "ArkherAtmos", "ArkherGrade", "ARKHER", "Spawn",
            "Arkher_T0_SelfTest"} | set(PAINELS) | \
    {"ArkherMainUI", "ArkherBundle_Editors", "ArkherBundle_Scene",
     "ArkherBundle_System", "ArkherALL_Assemble", "ALL_P1", "ALL_P2",
     "ALL_P3", "ArkherKit_A", "ArkherKit_B", "ArkherKit_Installer_A",
     "ArkherKit_Installer_B"}
found_v3 = 0
for i in range(SV + 290461, SV + 290461 + V3_N):
    nm = mine["names"].get(str(i), "")
    if nm in v3_names:
        found_v3 += 1
print(f"V3: {found_v3}/{V3_N} nomes esperados presentes")

# ------------------------------------------------- gerador do CB da UI
sg_ref = next(r for r in range(N2)
              if cls[r] == "ScreenGui" and name.get(r) == "ARKHER_Studio")
kidx = collections.defaultdict(list)
for r in range(N2):
    kidx[parent.get(r, -1)].append(r)
order = []


def walk(r):
    order.append(r)
    for c in kidx[r]:
        walk(c)
walk(sg_ref)

PROP_ENUM = {"Font": "FONT", "TextXAlignment": "XA",
             "ZIndexBehavior": "ZIB"}


def val_lua(pname, t, v):
    """v = valor python ja decodificado."""
    if t == 1:
        return json.dumps(v, ensure_ascii=False)
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
        return f"{PROP_ENUM[pname]}[{v}]" if pname in PROP_ENUM else str(v)
    raise SystemExit(f"tipo {pname} t={t}")


L = []
L.append("--[[ =====================================================================")
L.append("  ARKHER — UI COMPLETA NO STARTERGUI (Command Bar)")
L.append(f"  Cria: StarterGui.ArkherStudio — {len(order)} instancias (TopBar com")
L.append("  MenuRow/ToolRow, Explorer, Properties, StatusBar, Loading) — fiel")
L.append("  ao ARKHER_V2.rbxl (mesma arvore e mesmas propriedades).")
L.append("  Uso: View > Command Bar > cole TODO este texto > Run")
L.append("  Idempotente: se ja existir, destrói e recria.")
L.append("====================================================================== ]]")
L.append('local sg = game:GetService("StarterGui")')
L.append('local old = sg:FindFirstChild("ARKHER_Studio")')
L.append("if old then old:Destroy() end")
L.append("local FONT = {} for _, e in ipairs(Enum.Font:GetEnums()) do FONT[e.Value] = e end")
L.append("local XA = {} for _, e in ipairs(Enum.TextXAlignment:GetEnums()) do XA[e.Value] = e end")
L.append("local ZIB = {} for _, e in ipairs(Enum.ZIndexBehavior:GetEnums()) do ZIB[e.Value] = e end")
pos = {r: i for i, r in enumerate(order)}
for idx, r in enumerate(order):
    v = f"v{idx}"
    L.append(f'local {v} = Instance.new("{cls[r]}")')
    L.append(f'{v}.Name = {json.dumps(name[r], ensure_ascii=False)}')
    for pname, (t, val) in props.get(r, {}).items():
        L.append(f"{v}.{pname} = {val_lua(pname, t, val)}")
    par = parent.get(r, -1)
    if par == sg_ref:
        L.append(f"{v}.Parent = v0")
    elif par == -1 or par in svc:
        L.append(f"{v}.Parent = sg")
    else:
        L.append(f"{v}.Parent = v{pos[par]}")
L.append(f'print("[ARKHER] UI completa criada em StarterGui.ArkherStudio ({len(order)} instancias)")')
open(OUT_UI, "w", encoding="utf-8").write("\n".join(L) + "\n")
print(f"CB_UI gerado: {OUT_UI} ({os.path.getsize(OUT_UI):,} bytes, "
      f"{len(order)} instancias)")
sys.exit(1 if (bad_src or bad_props) else 0)
