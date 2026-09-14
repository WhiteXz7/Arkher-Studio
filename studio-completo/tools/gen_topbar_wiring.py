#!/usr/bin/env python3
"""Sincroniza o wiring da topbar unica a partir de build_shell.py (R20).

Fonte unica: TABS + TABMETA. Gera:
  09_Topbar.lua -> tabela BUTTONS (entre @@TOPBAR_BUTTONS@@)
  11_Input.lua  -> entradas PT de Tab_*/RibbonBtn_* (entre @@TOPBAR_LANG@@)
Uso: python3 tools/gen_topbar_wiring.py (rode apos qualquer mudanca no TABS).
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_shell as bs  # noqa: E402


def lua(s):
    # TABS usa \n real (Python) p/ 2 linhas; em Lua precisa ser escape \\n.
    return ('"' + s.replace("\\", "\\\\").replace('"', '\\"')
            .replace("\n", "\\n").replace("\r", "\\r") + '"')


def fill(path, marker, lines):
    p = os.path.join(HERE, "..", path)
    src = open(p, encoding="utf-8").read()
    pat = re.compile(r"([^\n]*@@%s@@\n)(.*?)(\n[^\n]*@@/%s@@)" % (marker, marker), re.S)
    m = pat.search(src)
    assert m, "marcador @@%s@@ ausente em %s" % (marker, path)
    body = "\n".join(lines)
    src = src[:m.start(2)] + body + src[m.end(2):]
    open(p, "w", encoding="utf-8").write(src)
    print("%s: %d linhas em @@%s@@" % (path, len(lines), marker))


def main():
    blines = []
    for t, btns in bs.TABS:
        blines.append("  -- %s" % t)
        for bid, _lb, _ic, act, _pt in btns:
            if len(act) == 1:
                blines.append("  RibbonBtn_%s_%s = { %s }," % (t, bid, lua(act[0])))
            else:
                blines.append("  RibbonBtn_%s_%s = { %s, %s }," % (t, bid, lua(act[0]), lua(act[1])))
    fill("scripts/09_Topbar.lua", "TOPBAR_BUTTONS", blines)

    llines = ["  -- abas (Tab_<T>/Lbl)"]
    for t, _btns in bs.TABS:
        llines.append('  { "Tab_%s", "Lbl", %s },' % (t, lua(bs.TABMETA[t][1])))
    for t, btns in bs.TABS:
        llines.append("  -- %s" % t)
        for bid, _lb, _ic, _act, pt in btns:
            llines.append('  { "RibbonBtn_%s_%s", "Lbl", %s },' % (t, bid, lua(pt)))
    fill("scripts/11_Input.lua", "TOPBAR_LANG", llines)


if __name__ == "__main__":
    main()
