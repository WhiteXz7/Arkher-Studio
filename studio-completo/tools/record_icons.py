#!/usr/bin/env python3
"""Executa record_icons.lua (lupa+mock) e salva tools/iconspec.json.

Cada icone: {"cls":"Frame","name":"Icon_<nome>","props":{...},"kids":[...]}
(pronto p/ copiar os kids p/ dentro do botao do ribbon).
"""
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = "/home/user/Arkher-Studio"
sys.path.insert(0, HERE)
from record_guix import conv_node, walk  # noqa: E402


def main():
    import lupa
    lua = lupa.LuaRuntime()
    src = open(os.path.join(HERE, "record_icons.lua"), encoding="utf-8").read()
    os.chdir(ROOT)
    try:
        lua.execute(src)
    except Exception as e:
        print("ERRO na gravacao de icones:", e)
        return 1
    spec = lua.eval("_G.__ICONS")
    icons = [conv_node(spec["icons"][i]) for i in range(1, len(spec["icons"]) + 1)]
    warns = [str(spec["warnings"][i]) for i in range(1, len(spec["warnings"]) + 1)]

    counts = Counter()
    for ic in icons:
        walk(ic, lambda n, d, p: counts.update([n["cls"]]))
    print(f"\nICONES: {len(icons)}")
    print("nomes:", ", ".join(sorted(ic["name"] for ic in icons)))
    total = sum(counts.values())
    print(f"TOTAL: {total} instancias ({dict(counts)})")
    if warns:
        print(f"\nWARNINGS ({len(warns)}):")
        for w in warns[:20]:
            print("  " + w)

    out = {"icons": icons}
    with open(os.path.join(HERE, "iconspec.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)
    print(f"\nspec salva: tools/iconspec.json ({os.path.getsize(os.path.join(HERE, 'iconspec.json'))} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
