#!/usr/bin/env python3
"""Dump instancia/arvore de um .rbxl (nomes, classes, pais, Visible).

Uso: dump_rbxl_tree.py <rbxl> [substr-filtro] [max-profundidade]
  Filtra a subarvore de ArkherStudioUI/Canvas; mostra so ramos que casam
  com o filtro (ou tudo ate a profundidade se sem filtro).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import patch_rbxl as P  # noqa: E402
import pyrbxl2  # noqa: E402


def load(path):
    data = open(path, "rb").read()
    ver, nt, ni, hdr = P.read_header(data)
    chunks = P.parse_chunks(data, hdr)
    tids, refs_by_t, type_ids, names = P.build_type_info(chunks)
    # PRNT
    parent = {}
    for cname, payload in chunks:
        if cname != b"PRNT":
            continue
        pr = pyrbxl2.R(payload)
        pr.u8()
        cnt = pr.u32()
        subs = pr.referent_array(cnt)
        pars = pr.referent_array(cnt)
        for s, p in zip(subs, pars):
            parent[s] = p
    # class por ref
    cls = {}
    for tid, refs in refs_by_t.items():
        for r in refs:
            cls[r] = tids[tid]
    # Visible por ref (bool = 1 byte/ref na ordem do INST)
    vis = {}
    for cname, payload in chunks:
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32()
        pname = cr.string()
        t = cr.u8()
        if pname != "Visible":
            continue
        refs = refs_by_t.get(tid, [])
        if t == 2 and len(payload) - cr.i >= len(refs):
            for r in refs:
                vis[r] = bool(cr.u8())
    return names, parent, cls, vis, ni


def main():
    path = sys.argv[1]
    filt = sys.argv[2] if len(sys.argv) > 2 else ""
    maxd = int(sys.argv[3]) if len(sys.argv) > 3 else 4
    names, parent, cls, vis, ni = load(path)
    kids = {}
    for s, p in parent.items():
        kids.setdefault(p, []).append(s)
    roots = [r for r, n in names.items()
             if n == "ArkherStudioUI" and cls.get(r) == "ScreenGui"]
    print("%s: %d instancias, ScreenGui roots=%d" % (path, ni, len(roots)))

    def match_sub(r, depth=0):
        if depth > 12:
            return False
        if filt.lower() in (names.get(r) or "").lower():
            return True
        return any(match_sub(k, depth + 1) for k in kids.get(r, []))

    def show(r, d, force=False):
        if d > maxd and not filt:
            return
        n = names.get(r, "?")
        if filt and not force and filt.lower() not in n.lower() and not match_sub(r):
            return
        if filt and filt.lower() in n.lower():
            force = True
        v = vis.get(r, "?")
        print("  " * d + "%s [%s] vis=%s" % (n, cls.get(r, "?"), v))
        if d < 12:
            for k in kids.get(r, []):
                show(k, d + 1, force)

    for r in roots:
        show(r, 0)


if __name__ == "__main__":
    main()
