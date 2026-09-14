#!/usr/bin/env python3
"""Fallback puro-Python de record_icons.py (lupa indisponivel neste ambiente).

Replica EXATAMENTE a semantica de px()/K.corner()/C() de
studio-completo/v2src/UI_TerrainEditor.lua para corpos ICON.* puros
(sequencias de chamadas px). Uso:

  python3 record_icons_py.py            # anexa icones novos ao iconspec.json
  python3 record_icons_py.py --check    # so valida os ja gravados

Validacao: regenera cada icone do spec cujo corpo-fonte e px-puro e
compara com o registro existente (prova de fidelidade bit-a-bit).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "v2src", "UI_TerrainEditor.lua")
SPEC = os.path.join(HERE, "iconspec.json")


def hexrgb(h):
    h = h.lstrip("#")
    n = int(h, 16)
    return [(n // 65536) % 256 / 255.0, (n // 256) % 256 / 255.0, (n % 256) / 255.0]


def num(s):
    s = s.strip()
    return int(s) if re.fullmatch(r"-?\d+", s) else float(s)


def parse_source():
    src = open(SRC, encoding="utf-8").read()
    pal = dict(re.findall(r'(\w+) = C\("(#......)"\)', src))
    assert pal.get("txt") == "#E6EBF5", "paleta nao achada"
    bodies = dict(re.findall(r"ICON\.(\w+) = function\(c\)\n(.*?)end\n", src, re.S))
    return pal, bodies


def resolve_color(expr, pal):
    expr = expr.strip()
    m = re.fullmatch(r'T\.(\w+)', expr)
    if m:
        return hexrgb(pal[m.group(1)])
    m = re.fullmatch(r'C\("(#......)"\)', expr)
    if m:
        return hexrgb(m.group(1))
    raise ValueError("cor nao resolvida: %r" % expr)


def build_icon(name, body, pal):
    """Constroi o node Icon_<name> no formato conv_node. Retorna None se
    o corpo nao for px-puro (helpers/loops) — esses ficam com o lupa."""
    calls = re.findall(r"px\(c, (.*?)\)", body)
    rest = re.sub(r"px\(c, .*?\)", "", body)
    if not calls or re.sub(r"[\s;]", "", rest):
        return None  # helpers/loops/outros stmts: fica com o lupa
    kids = []
    for call in calls:
        args = [a.strip() for a in call.split(",")]
        assert len(args) in (5, 6, 7), (name, call)
        x, y, w, h = (num(a) for a in args[:4])
        try:
            col = resolve_color(args[4], pal)
        except ValueError:
            return None  # cor variavel/nil: fica com o lupa
        r = args[5] if len(args) >= 6 else "nil"
        rot = args[6] if len(args) >= 7 else None
        props = {
            "Position": {"u2": [x / 20.0, 0.0, y / 20.0, 0.0]},
            "BorderSizePixel": 0,
            "BackgroundColor3": {"c3": col},
            "Size": {"u2": [w / 20.0, 0.0, h / 20.0, 0.0]},
        }
        if rot is not None:
            props["Rotation"] = num(rot)
        kk = []
        # Em Lua, `if r then` — 0 e TRUTHY e cria UICorner(0,0)!
        if r != "nil":
            kk.append({"cls": "UICorner", "name": "UICorner",
                       "props": {"CornerRadius": {"u1": [0.0, float(num(r))]}},
                       "kids": []})
        kids.append({"cls": "Frame", "name": "Frame", "props": props, "kids": kk})
    return {"cls": "Frame", "name": "Icon_" + name,
            "props": {"Size": {"u2": [0.0, 26.0, 0.0, 26.0]},
                      "BorderSizePixel": 0, "Name": "Icon_" + name,
                      "BackgroundTransparency": 1},
            "kids": kids}


def main():
    check_only = "--check" in sys.argv
    pal, bodies = parse_source()
    spec = json.load(open(SPEC, encoding="utf-8"))
    have = {ic["name"]: ic for ic in spec["icons"]}
    ok, skip, bad = 0, 0, []
    for name, body in sorted(bodies.items()):
        node = build_icon(name, body, pal)
        if node is None:
            skip += 1
            continue
        old = have.get("Icon_" + name)
        if old is None:
            continue  # novo: tratado abaixo
        if json.dumps(old, sort_keys=True) == json.dumps(node, sort_keys=True):
            ok += 1
        else:
            bad.append(name)
    print("fonte: %d ICON fns | validados: %d | nao-px (lupa): %d | DIVERGENTES: %s"
          % (len(bodies), ok, skip, bad or "nenhum"))
    if bad:
        return 1
    if check_only:
        return 0
    added = []
    for name, body in sorted(bodies.items()):
        if ("Icon_" + name) in have:
            continue
        node = build_icon(name, body, pal)
        assert node is not None, "icone novo nao-px: " + name
        spec["icons"].append(node)
        added.append("Icon_" + name)
    spec["icons"].sort(key=lambda i: i["name"])
    json.dump(spec, open(SPEC, "w", encoding="utf-8"), ensure_ascii=False)
    print("anexados: %s (total %d)" % (", ".join(added) or "nenhum", len(spec["icons"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
