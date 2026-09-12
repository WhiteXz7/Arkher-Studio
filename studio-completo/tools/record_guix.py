#!/usr/bin/env python3
"""Executa record_guix.lua (lupa+mock), converte _G.__SPEC e valida a GUI estática.

Gera tools/guix_spec.json — árvores prontas para o inject_guix.py:
  host:    filhos do DeckHost (23 janelas Deck_*) + Deck_launcher/rig/mesh
  xbar:    ArkherXBar (6 botões)
  popups:  ServerEditorPopups (container + ArkherShapesPopup)
"""
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/home/user/Arkher-Studio"


def conv_val(v):
    if v is None or isinstance(v, (str, bool, int, float)):
        return v
    tag = v[1]
    if tag == "C3":
        return {"c3": [float(v[2]), float(v[3]), float(v[4])]}
    if tag == "U2":
        return {"u2": [float(v[2]), float(v[3]), float(v[4]), float(v[5])]}
    if tag == "U1":
        return {"u1": [float(v[2]), float(v[3])]}
    if tag == "V2":
        return {"v2": [float(v[2]), float(v[3])]}
    if tag == "EN":
        return {"en": str(v[2])}
    raise ValueError(f"valor composto desconhecido: {tag}")


def conv_node(t):
    assert t[1] == "NODE", f"nó inválido: {t[1] if len(t) else 'vazio'}"
    cls, name = str(t[2]), str(t[3])
    props = {str(k): conv_val(v) for k, v in t[4].items()}
    kids = [conv_node(t[5][i]) for i in range(1, len(t[5]) + 1)]
    return {"cls": cls, "name": name, "props": props, "kids": kids}


def walk(n, fn, depth=0, path=""):
    p = f"{path}/{n['name']}"
    fn(n, depth, p)
    for k in n["kids"]:
        walk(k, fn, depth + 1, p)


def main():
    import lupa
    lua = lupa.LuaRuntime()
    src = open(os.path.join(HERE, "record_guix.lua"), encoding="utf-8").read()
    os.chdir(ROOT)
    try:
        lua.execute(src)
    except Exception as e:
        print("ERRO na gravação:", e)
        return 1
    spec = lua.eval("_G.__SPEC")
    deck = conv_node(spec["deck"])
    popups = conv_node(spec["popups"])
    extra = conv_node(spec["extra"])
    warns = [str(spec["warnings"][i]) for i in range(1, len(spec["warnings"]) + 1)]

    # ---- host ArkherXDeck: filhos = 23 janelas + UIScale ----
    assert deck["cls"] == "Frame" and deck["name"] == "ArkherXDeck", \
        f"host inesperado: {deck['cls']}/{deck['name']}"
    host_kids = deck["kids"]
    host_scale = None
    host_real = []
    for k in host_kids:
        if k["cls"] == "UIScale":
            host_scale = k["props"].get("Scale", 1)
        else:
            host_real.append(k)
    print(f"DeckHost: {len(host_real)} janelas + UIScale={host_scale}")
    win_names = sorted(k["name"] for k in host_real)
    print("janelas:", ", ".join(win_names))

    # OUT roots: pega os filhos (o OUT_* é só envelope)
    assert len(popups["kids"]) == 1, "OUT_Popups deve ter 1 filho"
    popups_node = popups["kids"][0]
    extra_kids = extra["kids"]
    print(f"Popups: {popups_node['name']} ({len(popups_node['kids'])} filhos)")
    print(f"Extra: {[k['name'] for k in extra_kids]}")

    # ---- estatísticas + validações ----
    counts = Counter()
    props_by_cls = {}
    nonpos = []  # estáticos sem Size/Position (risco p/ adoção)
    fonts = Counter()
    enums = Counter()
    sentinel = []

    def visit(n, depth, path):
        counts[n["cls"]] += 1
        props_by_cls.setdefault(n["cls"], Counter()).update(n["props"].keys())
        if "Font" in n["props"]:
            fonts[n["props"]["Font"]["en"]] += 1
        for k, v in n["props"].items():
            if isinstance(v, dict) and "en" in v and k != "Font":
                enums[f"{k}={v['en']}"] += 1
        for k in ("Text", "PlaceholderText"):
            if k in n["props"] and isinstance(n["props"][k], str):
                if "sem ponte" in n["props"][k] or "falha remota" in n["props"][k]:
                    sentinel.append(f"{path} [{k}]: {n['props'][k][:80]}")
        if n["cls"] == "TextBox" and "TextYAlignment" in n["props"]:
            print(f"  [TextBox+YAlign] {path}")
        if n["cls"] == "TextLabel" and "ClipsDescendants" in n["props"]:
            print(f"  [Label+Clips] {path}")
        if n["cls"] in ("Frame", "TextButton", "TextLabel", "TextBox", "ScrollingFrame"):
            if "Size" not in n["props"] or "Position" not in n["props"]:
                nonpos.append(f"{path} [{n['cls']}]")

    for n in host_real + [popups_node] + extra_kids:
        walk(n, visit)

    total = sum(counts.values())
    print(f"\nTOTAL: {total} instâncias")
    for cls, c in counts.most_common():
        print(f"  {cls}: {c}")
    print("\nprops por classe:")
    for cls in sorted(props_by_cls):
        print(f"  {cls}: {sorted(props_by_cls[cls].keys())}")
    print("\nFonts:", dict(fonts))
    print("Enums:", dict(enums))
    if warns:
        print(f"\nWARNINGS lua ({len(warns)}):")
        for w in warns[:30]:
            print("  " + w)
    if nonpos:
        print(f"\nSEM Size/Position ({len(nonpos)}):")
        for s in nonpos[:30]:
            print("  " + s)
    if sentinel:
        print(f"\nSENTINELA mock vazou ({len(sentinel)}):")
        for s in sentinel:
            print("  " + s)
        return 1

    out = {
        # escala 1.0 assada; o updateDeckScale recalcula no Play (0.2s)
        "host_scale": 1.0,
        "deck": host_real,
        "extra": extra_kids,
        "popups": popups_node,
    }
    with open(os.path.join(HERE, "deck_spec.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)
    print(f"\nspec salva: tools/deck_spec.json ({os.path.getsize(os.path.join(HERE, 'deck_spec.json'))} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
