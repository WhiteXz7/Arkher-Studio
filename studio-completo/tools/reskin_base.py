#!/usr/bin/env python3
"""Reskin cirurgico da placa-base X (SEM adicionar/remover instancias).

Aplica na copia de trabalho (default: studio-completo/build/X_reskinned.rbxl):
  * TitleBar/MenuBar/Footer -> fundo navy (11,18,32) [TitleBar continua visivel]
  * Ribbon (antigo, filho do Canvas) -> Visible=false (a shell nossa assume)
  * Remap +66px da workarea (DocumentTabs/DockBackgrounds/PropertiesDock/
    HierarchyDock/Viewport): abre espaco p/ shell em y=68..216, mantendo bottoms.

Somente SOBRESCRITA de valores em PROP existentes (Color3/bool/UDim2, todos de
largura fixa -> chunks mantem o mesmo tamanho). Contagens do header intactas.

Uso:
  reskin_base.py --report   # mostra valores atuais + cores dos filhos (nao escreve)
  reskin_base.py            # aplica e escreve build/X_reskinned.rbxl
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
import pyrbxl2
import rbxcodec
from patch_rbxl import read_header, parse_chunks, chunk_out, build_type_info

ROOT = os.path.dirname(HERE)
REPO = os.path.dirname(ROOT)
SRC = os.path.join(REPO, "ArkherStudio_Completo_X.rbxl")
OUT = os.path.join(ROOT, "build", "X_reskinned.rbxl")

NAVY = (11 / 255.0, 18 / 255.0, 32 / 255.0)

# (classe, nome, nome-do-pai, prop, novo-valor-python)
EDITS = [
    ("Frame", "TitleBar", "Canvas", "BackgroundColor3", NAVY),
    ("Frame", "MenuBar", "Canvas", "BackgroundColor3", NAVY),
    ("Frame", "Footer", "Canvas", "BackgroundColor3", NAVY),
    ("Frame", "Ribbon", "Canvas", "Visible", False),
    ("Frame", "LeftTabs", "Canvas", "Visible", False),
    ("Frame", "DocumentTabs", "Canvas", "Position", (0.0, 342, 0.0, 216)),
    ("Frame", "DockBackgrounds", "Canvas", "Position", (0.0, 0, 0.0, 216)),
    ("Frame", "DockBackgrounds", "Canvas", "Size", (1.0, 0, 1.0, -279)),
    ("Frame", "PropertiesDock", "Canvas", "Position", (0.0, 5, 0.0, 216)),
    ("Frame", "PropertiesDock", "Canvas", "Size", (0.0, 329, 1.0, -315)),
    ("Frame", "HierarchyDock", "Canvas", "Position", (1.0, -330, 0.0, 216)),
    ("Frame", "HierarchyDock", "Canvas", "Size", (0.0, 324, 1.0, -318)),
    ("Frame", "Viewport", "Canvas", "Position", (0.0, 342, 0.0, 253)),
    ("Frame", "Viewport", "Canvas", "Size", (1.0, -682, 1.0, -317)),
]
WANT_DTYPE = {"BackgroundColor3": 0xC, "Visible": 0x2, "Position": 0x7, "Size": 0x7}
# fills p/ props ausentes no arquivo (Studio omite colunas all-default)
FILLS = {"Visible": True}


def load(inp):
    data = open(inp, "rb").read()
    version, nt, ni, hdr_end = read_header(data)
    chunks = parse_chunks(data, hdr_end)
    type_by_id, refs_por_type, type_ids, name_por_ref = build_type_info(chunks)
    par = {}
    for cname, payload in chunks:
        if cname != b"PRNT":
            continue
        r = pyrbxl2.R(payload)
        r.u8()
        n = r.u32()
        for c, p in zip(r.referent_array(n), r.referent_array(n)):
            par[c] = p
    return (version, nt, ni), chunks, type_by_id, refs_por_type, type_ids, name_por_ref, par


def prop_body(chunks, tid, pname):
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        if cr.u32() == tid and cr.string() == pname:
            return idx, cr.u8(), payload[cr.i:]
    return None


def fmt_val(pname, v):
    if pname == "BackgroundColor3":
        return "(%d,%d,%d)" % (round(v[0] * 255), round(v[1] * 255), round(v[2] * 255))
    if pname in ("Position", "Size"):
        return "(sx=%.2f,ox=%d,sy=%.2f,oy=%d)" % v
    return repr(v)


def main():
    report_only = "--report" in sys.argv
    (version, nt, ni), chunks, type_by_id, refs_por_type, type_ids, name_por_ref, par = load(SRC)

    def find_ref(cls, name, parent_name):
        tid = type_ids[cls]
        out = []
        for r in refs_por_type[tid]:
            if name_por_ref.get(r) == name and name_por_ref.get(par.get(r)) == parent_name:
                out.append(r)
        return tid, out

    # ---- report: cores dos filhos do chrome (decisao TitleBar navy) ----
    if report_only:
        for holder in ("TitleBar", "MenuBar", "Footer"):
            href = find_ref("Frame", holder, "Canvas")[1]
            print(f"== {holder} ==")
            kids = sorted([c for c, p in par.items() if p in href],
                          key=lambda r: name_por_ref.get(r, ""))
            # props uteis por classe dos filhos
            tid_of = {}
            for t, rs in refs_por_type.items():
                for r in rs:
                    tid_of[r] = t
            for c in kids:
                t = tid_of[c]
                n = len(refs_por_type[t])
                pos = refs_por_type[t].index(c)
                info = []
                hit = prop_body(chunks, t, "BackgroundColor3")
                if hit:
                    _i, dt, body = hit
                    v = rbxcodec.decode(dt, body, n)[pos]
                    info.append("bg=(%d,%d,%d)" % (round(v[0] * 255), round(v[1] * 255), round(v[2] * 255)))
                hit = prop_body(chunks, t, "BackgroundTransparency")
                if hit:
                    _i, dt, body = hit
                    info.append("bgT=%.2f" % rbxcodec.decode(dt, body, n)[pos])
                hit = prop_body(chunks, t, "TextColor3")
                if hit:
                    _i, dt, body = hit
                    v = rbxcodec.decode(dt, body, n)[pos]
                    info.append("txt=(%d,%d,%d)" % (round(v[0] * 255), round(v[1] * 255), round(v[2] * 255)))
                hit = prop_body(chunks, t, "Text")
                if hit:
                    _i, _dt, body = hit
                    rr = pyrbxl2.R(body)
                    texts = []
                    for _ in range(n):
                        ln = rr.u32()
                        texts.append(rr.take(ln).decode("utf-8", "replace"))
                    info.append("text=%r" % texts[pos][:28])
                print(f"  - {name_por_ref.get(c)} [{type_by_id[t]}] " + " ".join(info))
        # valores atuais dos alvos
        for cls, name, pnam, pname, _new in EDITS:
            tid, refs = find_ref(cls, name, pnam)
            assert len(refs) == 1, f"alvo ambiguo/ausente: {cls}:{name} ({refs})"
            got = prop_body(chunks, tid, pname)
            if not got:
                print(f"ATUAL {cls}:{name}.{pname} = AUSENTE (fill padrao {FILLS[pname]!r})")
                continue
            _idx, dt, body = got
            vals = rbxcodec.decode(dt, body, len(refs_por_type[tid]))
            cur = vals[refs_por_type[tid].index(refs[0])]
            print(f"ATUAL {cls}:{name}.{pname} = {fmt_val(pname, cur)} (dtype {hex(dt)})")
        return 0

    # ---- apply ----
    changed = {}
    new_chunks = []
    for cls, name, pnam, pname, new in EDITS:
        tid, refs = find_ref(cls, name, pnam)
        assert len(refs) == 1, f"alvo ambiguo/ausente: {cls}:{name} ({refs})"
        n = len(refs_por_type[tid])
        pos = refs_por_type[tid].index(refs[0])
        hit = prop_body(chunks, tid, pname)
        if not hit:
            # coluna ausente (all-default): cria chunk novo com fill + valor
            assert pname in FILLS, f"sem fill p/ {cls}.{pname}"
            dt = WANT_DTYPE[pname]
            vals = [FILLS[pname]] * n
            old = FILLS[pname]
            vals[pos] = new
            head = struct.pack("<I", tid) + struct.pack("<I", len(pname)) + \
                pname.encode("utf-8") + struct.pack("<B", dt)
            # insere ANTES do PRNT na hora (o proximo edit do mesmo prop ja acha)
            for _pi, (_cn, _pl) in enumerate(chunks):
                if _cn == b"PRNT":
                    chunks.insert(_pi, [b"PROP", head + rbxcodec.encode(dt, vals)])
                    break
            else:
                new_chunks.append([b"PROP", head + rbxcodec.encode(dt, vals)])
            changed[f"{cls}:{name}.{pname}"] = (fmt_val(pname, old) + " (fill)", fmt_val(pname, new))
            continue
        idx, dt, body = hit
        assert dt == WANT_DTYPE[pname], f"dtype inesperado {cls}.{pname}: {hex(dt)}"
        n = len(refs_por_type[tid])
        vals = rbxcodec.decode(dt, body, n)
        pos = refs_por_type[tid].index(refs[0])
        old = vals[pos]
        # roundtrip check: re-encode sem mudar deve ser byte-identico
        rt = rbxcodec.encode(dt, vals)
        assert rt == body, f"roundtrip instavel: {cls}.{pname}"
        vals[pos] = new
        new_body = rbxcodec.encode(dt, vals)
        assert len(new_body) == len(body), f"tamanho mudou: {cls}.{pname}"
        cr = pyrbxl2.R(chunks[idx][1])
        cr.u32()
        cr.string()
        cr.u8()
        head = chunks[idx][1][:cr.i]
        chunks[idx] = [chunks[idx][0], head + new_body]
        changed[f"{cls}:{name}.{pname}"] = (fmt_val(pname, old), fmt_val(pname, new))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    out = bytearray(pyrbxl2.MAGIC if hasattr(pyrbxl2, "MAGIC") else b"<roblox!\x89\xff\r\n\x1a\n")
    out += struct.pack("<H", version)
    out += struct.pack("<I", nt)
    out += struct.pack("<I", ni)
    out += b"\x00" * 8
    for cname, payload in chunks:
        if cname == b"PRNT" and new_chunks:
            for nc, npay in new_chunks:
                out += chunk_out(nc, npay)
            new_chunks = []
        out += chunk_out(cname, payload)
    for nc, npay in new_chunks:
        out += chunk_out(nc, npay)
    open(OUT, "wb").write(bytes(out))
    print(f"reskin ok: {OUT} ({len(out)} bytes, {ni} inst, {nt} tipos)")
    for k, (a, b) in changed.items():
        print(f"  {k}: {a} -> {b}")

    # ---- re-le e confirma ----
    (_v, _nt, _ni), chunks2, t2, r2, ti2, np2, par2 = load(OUT)
    assert (_nt, _ni) == (nt, ni), "contagens mudaram!"
    for cls, name, pnam, pname, new in EDITS:
        tid = ti2[cls]
        refs = [r for r in r2[tid]
                if np2.get(r) == name and np2.get(par2.get(r)) == pnam]
        assert len(refs) == 1
        _idx, dt, body = prop_body(chunks2, tid, pname)
        vals = rbxcodec.decode(dt, body, len(r2[tid]))
        got = vals[r2[tid].index(refs[0])]

        def close(a, b):
            if isinstance(a, tuple):
                return len(a) == len(b) and all(close(x, y) for x, y in zip(a, b))
            if isinstance(a, float):
                return abs(a - b) < 1e-6
            return a == b

        assert close(got, new), f"nao persistiu: {cls}:{name}.{pname} = {got}"
    print(f"re-leitura: {len(EDITS)}/{len(EDITS)} valores persistidos, contagens intactas.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
t(main())
