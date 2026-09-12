#!/usr/bin/env python3
"""Une deck_spec + v2spec + shellspec -> guix_spec.json final.

guix_spec.json: {host_scale, deck[23], extra[rig,mesh], shell[ArkherTop,ArkherMsg],
                 v2[40], popups}
Ajustes: raizes v2 ganham ZIndex=40 (StatusBar=30); Visible=false ja vem do
record (menos StatusBar). Valida que todo alvo open/toggle/popup da shell existe.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from build_shell import TABS  # noqa: E402
from record_guix import walk  # noqa: E402


def main():
    deck = json.load(open(os.path.join(HERE, "deck_spec.json"), encoding="utf-8"))
    v2 = json.load(open(os.path.join(HERE, "v2spec.json"), encoding="utf-8"))
    shell = json.load(open(os.path.join(HERE, "shellspec.json"), encoding="utf-8"))

    wins = v2["v2"]
    for w in wins:
        w["props"]["ZIndex"] = 30 if w["name"] == "V2_ArkherStatusBar" else 40
        if w["name"] == "V2_ArkherStatusBar":
            # default ESCONDIDA: o rodape proprio do Studio ja ocupa a base;
            # o usuario mostra pelo botao HOME > Status
            w["props"]["Visible"] = False
        else:
            w["props"]["Visible"] = False

    names = {w["name"] for w in deck["deck"]} | {w["name"] for w in wins} | \
        {e["name"] for e in deck["extra"]}
    popup_names = set()
    walk(deck["popups"], lambda n, d, p: popup_names.add(n["name"]))

    # valida alvos da shell
    errs = []
    n_act = 0
    for tab, btns in TABS:
        for bid, _label, _icon, act in btns:
            n_act += 1
            kind = act[0]
            if kind in ("open", "toggle"):
                if act[1] not in names:
                    errs.append(f"RibbonBtn_{tab}_{bid}: janela inexistente {act[1]}")
            elif kind == "popup":
                if act[1] not in popup_names:
                    errs.append(f"RibbonBtn_{tab}_{bid}: popup inexistente {act[1]}")
    if errs:
        print("ALVOS INVALIDOS:")
        for e in errs:
            print("  " + e)
        return 1
    print(f"alvos ok: {n_act} acoes, {len(names)} janelas, {len(popup_names)} popups")

    out = {
        "host_scale": deck["host_scale"],
        "deck": deck["deck"],
        "extra": deck["extra"],
        "shell": shell["shell"],
        "v2": wins,
        "popups": deck["popups"],
    }
    with open(os.path.join(HERE, "guix_spec.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)
    total = 0
    for n in deck["deck"] + deck["extra"] + shell["shell"] + wins + [deck["popups"]]:
        walk(n, lambda nn, d, p: None)
    print(f"spec final: tools/guix_spec.json "
          f"({os.path.getsize(os.path.join(HERE, 'guix_spec.json'))} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
