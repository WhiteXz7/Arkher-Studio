#!/usr/bin/env python3
"""Executa record_v2.lua (lupa+mock), converte _G.__V2 e valida as 41 UIs do v2.

Gera tools/v2spec.json — janelas prontas para o inject_guix.py (secao "v2"):
  V2_<Gui> (Visible=false, menos V2_ArkherStatusBar)
Mapeia Font.BuilderSans* -> Gotham* (injector nao conhece BuilderSans).
"""
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/home/user/Arkher-Studio"
sys.path.insert(0, HERE)
from record_guix import conv_val, conv_node, walk  # noqa: E402


def map_font(en):
    if en == "Font.BuilderSansBold":
        return "Font.GothamBold"
    if en == "Font.BuilderSans":
        return "Font.Gotham"
    if en in ("Font.CodePlatform", "Font.RobotoMono", "Font.UbuntuMono"):
        return "Font.Code"
    if en.startswith("Font.Builder"):
        return "Font.GothamBold" if "Bold" in en else "Font.Gotham"
    return en


def main():
    import lupa
    lua = lupa.LuaRuntime()
    src = open(os.path.join(HERE, "record_v2.lua"), encoding="utf-8").read()
    os.chdir(ROOT)
    try:
        lua.execute(src)
    except Exception as e:
        print("ERRO na gravacao v2:", e)
        return 1
    v2 = lua.eval("_G.__V2")
    wins = [conv_node(v2["wins"][i]) for i in range(1, len(v2["wins"]) + 1)]
    warns = [str(v2["warnings"][i]) for i in range(1, len(v2["warnings"]) + 1)]

    # mapa de fontes + coleta de stats
    counts = Counter()
    fonts = Counter()
    enums = Counter()
    bad = []  # nos que quebrariam o injector (campos obrigatorios)

    def visit(n, depth, path):
        if "Font" in n["props"] and isinstance(n["props"]["Font"], dict):
            n["props"]["Font"] = {"en": map_font(n["props"]["Font"]["en"])}
        counts[n["cls"]] += 1
        if "Font" in n["props"]:
            fonts[n["props"]["Font"]["en"]] += 1
        for k, v in n["props"].items():
            if isinstance(v, dict) and "en" in v and k != "Font":
                enums[f"{k}={v['en']}"] += 1
        p = n["props"]
        if n["cls"] in ("Frame", "TextButton", "TextLabel", "TextBox"):
            if "Size" not in p:
                bad.append(f"{path} [{n['cls']}] SEM Size")
        if n["cls"] == "UICorner" and "CornerRadius" not in p:
            bad.append(f"{path} SEM CornerRadius")
        if n["cls"] == "UIStroke" and not all(k in p for k in ("ApplyStrokeMode", "Color", "Thickness")):
            bad.append(f"{path} stroke incompleto")

    for w in wins:
        walk(w, visit)
    total = sum(counts.values())
    print(f"\nJANELAS: {len(wins)}")
    print("nomes:", ", ".join(sorted(w["name"] for w in wins)))
    print(f"\nTOTAL: {total} instancias")
    for cls, c in counts.most_common():
        print(f"  {cls}: {c}")
    print("\nFonts:", dict(fonts))
    print("Enums:", dict(enums))
    if warns:
        print(f"\nWARNINGS lua ({len(warns)}):")
        for w in warns[:30]:
            print("  " + w)
    if bad:
        print(f"\nINCOMPATIVEIS injector ({len(bad)}):")
        for b in bad[:30]:
            print("  " + b)
        return 1

    out = {"v2": wins}
    with open(os.path.join(HERE, "v2spec.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)
    print(f"\nspec salva: tools/v2spec.json ({os.path.getsize(os.path.join(HERE, 'v2spec.json'))} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
