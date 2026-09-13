#!/usr/bin/env python3
"""Reskin V2 (rebuild UI PERFEITA): esconde o chrome antigo + remapa docks/viewport.

  reskin_v2.py <in.rbxl> <out.rbxl> --part=a   # placa-base X (chrome + remap)
  reskin_v2.py <in.rbxl> <out.rbxl> --part=b   # pos-inject (esconde ArkherTop)

Reutiliza a maquinaria provada de reskin_base (sobrescrita largura-fixa em PROP).
Falha RAPIDO se algum alvo nao existir (lista e exata para este rebuild).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
import reskin_base as R

C = lambda r, g, b: (r / 255.0, g / 255.0, b / 255.0)  # noqa: E731

# Design space 1568x882 (dg() do 01_Nucleo). Novo layout (EN, mockup UI_REFERENCE):
#  menu y0-34, ribbon y34-120, Explorer esq (0-300), viewport (300-1108),
#  props dir (1108-1388), coluna far-right (1388-1568), footer y819-882.
EDITS_A = [
    # --- esconde chrome antigo da placa ---
    ("Frame", "TitleBar", "Canvas", "Visible", False),
    ("Frame", "MenuBar", "Canvas", "Visible", False),
    ("Frame", "Ribbon", "Canvas", "Visible", False),
    ("Frame", "LeftTabs", "Canvas", "Visible", False),
    ("Frame", "DocumentTabs", "Canvas", "Visible", False),
    ("Frame", "DockBackgrounds", "Canvas", "Visible", False),
    ("Frame", "ChatBar", "Canvas", "Visible", False),
    ("TextButton", "Arkher", "Footer", "Visible", False),
    ("Frame", "CommandBar", "Footer", "Visible", False),
    ("Frame", "TopBorder", "Footer", "Visible", False),
    # --- remap funcional (nomes preservados: 01/03/10 continuam ligados) ---
    ("Frame", "HierarchyDock", "Canvas", "Position", (0.0, 0, 0.0, 120)),
    ("Frame", "HierarchyDock", "Canvas", "Size", (0.0, 300, 0.0, 225)),
    ("Frame", "PropertiesDock", "Canvas", "Position", (1.0, -460, 0.0, 120)),
    ("Frame", "PropertiesDock", "Canvas", "Size", (0.0, 280, 0.0, 425)),
    ("Frame", "Viewport", "Canvas", "Position", (0.0, 300, 0.0, 120)),
    ("Frame", "Viewport", "Canvas", "Size", (0.0, 808, 0.0, 455)),
    ("Frame", "Footer", "Canvas", "Position", (0.0, 0, 1.0, -63)),
    ("Frame", "Footer", "Canvas", "Size", (1.0, 0, 0.0, 63)),
    # --- recolor mockup ---
    ("Frame", "Canvas", "ArkherStudioUI", "BackgroundColor3", C(13, 17, 23)),
    ("Frame", "Footer", "Canvas", "BackgroundColor3", C(15, 23, 42)),
    ("Frame", "HierarchyDock", "Canvas", "BackgroundColor3", C(17, 26, 46)),
    ("Frame", "PropertiesDock", "Canvas", "BackgroundColor3", C(17, 26, 46)),
    ("Frame", "Viewport", "Canvas", "BackgroundColor3", C(7, 12, 24)),
]

EDITS_B = [
    # shell antiga (filha do host guix): some, a ArkherShell2 assume.
    ("Frame", "ArkherTop", "ArkherXDeck", "Visible", False),
]


def main():
    if len(sys.argv) != 4 or sys.argv[3] not in ("--part=a", "--part=b"):
        sys.exit("uso: reskin_v2.py <in.rbxl> <out.rbxl> --part=a|b")
    inp, outp, part = sys.argv[1], sys.argv[2], sys.argv[3][-1]
    R.EDITS = EDITS_A if part == "a" else EDITS_B
    R.SRC, R.OUT = inp, outp
    # reskin_base.main le R.EDITS/R.SRC/R.OUT e falha se alvo ambiguo/ausente.
    sys.argv = [sys.argv[0]]
    R.main()
    print(f"reskin_v2 part {part}: {inp} -> {outp}")


if __name__ == "__main__":
    main()
