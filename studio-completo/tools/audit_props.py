"""Auditoria prop-por-prop: tudo que os specs pedem x o que inject codifica.
Uso: python3 studio-completo/tools/audit_props.py  (exit 1 se houver drop)"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from inject_guix import build_prop_values, ENUMS

spec = json.load(open(os.path.join(HERE, "guix_spec.json"), encoding="utf-8"))
used = {}  # cls -> {prop}
def walk(n):
    if isinstance(n, dict):
        if "cls" in n and "props" in n:
            for p in n["props"]:
                used.setdefault(n["cls"], set()).add(p)
        for k in ("kids", "children"):
            if isinstance(n.get(k), list):
                for c in n[k]: walk(c)
    elif isinstance(n, list):
        for c in n: walk(c)
for branch in ("deck", "extra", "shell", "v2", "popups"):
    walk(spec[branch])
# host/canvas_popups sao montados no inject: props fixas conhecidas
used.setdefault("Frame", set()).update(["Size", "BackgroundTransparency", "BorderSizePixel",
    "ZIndex", "Active", "Selectable", "Visible", "ClipsDescendants"])
used.setdefault("UIScale", set()).add("Scale")

SPECIAL = {"Font"}  # Font -> coluna FontFace (mapeado, nao drop)
SPECIAL_CLS = {("UICorner", "CornerRadius")}  # -> 4 raios
SKIP_ENUM = {"Font"}  # via FONTMAP, nao ENUMS
drops, enum_gaps = [], []
for cls in sorted(used):
    try:
        plan = build_prop_values(cls, [])
    except SystemExit as e:
        print(f"CLASSE NAO PLANEJADA: {cls}"); drops.append((cls, "*", str(e))); continue
    for p in sorted(used[cls]):
        if p in SPECIAL or (cls, p) in SPECIAL_CLS: continue
        if p not in plan:
            drops.append((cls, p, "ignorado pelo inject"))
# enums {"en": "Tipo.Valor"} usados?
def enums(n):
    if isinstance(n, dict):
        if set(n.keys()) == {"en"}:
            yield n["en"]
        for v in n.values(): yield from enums(v)
    elif isinstance(n, list):
        for c in n: yield from enums(c)
for branch in ("deck", "extra", "shell", "v2", "popups"):
    for e in enums(spec[branch]):
        t, _, v = e.partition(".")
        if t in SKIP_ENUM: continue
        if t not in ENUMS: enum_gaps.append(f"{e} (tipo?)")
        elif v not in ENUMS[t]: enum_gaps.append(f"{e} (valor?)")
print(f"classes: {len(used)} | drops: {len(drops)} | enum gaps: {len(enum_gaps)}")
for d in drops: print("  DROP:", d)
for g in sorted(set(enum_gaps)): print("  ENUM:", g)
failed = bool(drops or enum_gaps)

# ---- cobertura OLDFILL x colunas da base (evita "sem old-fill" no inject) ----
from inject_guix import OLDFILL
import pyrbxl2 as _px
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
from patch_rbxl import read_header as _rh, parse_chunks as _pc, build_type_info as _bt
_base = os.path.join(HERE, "..", "build", "X_reskinned.rbxl")
_miss = []
if os.path.exists(_base):
    _d = open(_base, "rb").read()
    _v, _nt, _ni, _h = _rh(_d)
    _ch = _pc(_d, _h)
    _tbi, _rpt, _ti, _npr = _bt(_ch)
    _cols = set()
    for _cn, _pl in _ch:
        if _cn != b"PROP":
            continue
        _cr = _px.R(_pl)
        _cols.add((_tbi[_cr.u32()], _cr.string()))
    _miss = []
    for _cls, _props in used.items():
        try:
            _plan = build_prop_values(_cls, [])
        except SystemExit:
            continue
        for _pn in _plan:
            if _cls in _ti and (_cls, _pn) not in _cols:
                if OLDFILL.get(_cls, {}).get(_pn) is None:
                    _miss.append((_cls, _pn))
    print(f"oldfill gaps: {len(_miss)}")
    for _m in _miss:
        print("  OLDFILL:", _m)
    if _miss:
        sys.exit(1)
    failed = failed or bool(_miss)
else:
    print("oldfill: base ausente (rode reskin_base.py)")
sys.exit(1 if failed else 0)
