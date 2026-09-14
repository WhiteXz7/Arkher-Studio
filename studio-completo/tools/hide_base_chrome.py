#!/usr/bin/env python3
"""Esconde a topbar antiga da base no .rbxl (R18: topbar unica = ArkherTop).

PoE em bake-time Visible=false nos 3 Frames filhos de Canvas:
TitleBar, MenuBar, Ribbon. Todo o resto (docks, viewport, footer) intacto.

Patch cirurgico: re-emite o arquivo com 3 bytes alterados no chunk
PROP Frame/Visible (bool = 1 byte/ref na ordem do INST). Nada e criado,
removido ou reordenado; instancias e bytes antigos sao preservados.

Uso: hide_base_chrome.py <in.rbxl> <out.rbxl>
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from patch_rbxl import read_header, parse_chunks, chunk_out, build_type_info
import pyrbxl2

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"
HIDE = {"TitleBar", "MenuBar", "Ribbon"}


def main():
    inp, outp = sys.argv[1], sys.argv[2]
    data = open(inp, "rb").read()
    version, num_types, num_instances, hdr_end = read_header(data)
    chunks = parse_chunks(data, hdr_end)
    type_by_id, refs_por_type, _type_ids, name_por_ref = build_type_info(chunks)

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

    canvas = [r for r, n in name_por_ref.items() if n == "Canvas"]
    assert len(canvas) == 1, "Canvas nao unico: %r" % canvas
    canvas = canvas[0]
    kids = [s for s, p in parent.items() if p == canvas]
    targets = [r for r in kids if name_por_ref.get(r) in HIDE]
    assert len(targets) == 3, "alvos base != 3: %r" % sorted(
        name_por_ref.get(r) for r in targets)
    print("escondendo:", sorted("%s#%d" % (name_por_ref[r], r) for r in targets))

    patched = 0
    out_chunks = []
    for cname, payload in chunks:
        if cname.startswith(b"END"):
            continue
        if cname == b"PROP":
            cr = pyrbxl2.R(payload)
            tid = cr.u32()
            pname = cr.string()
            t = cr.u8()
            if pname == "Visible" and t == 2 and type_by_id.get(tid) == "Frame":
                refs = refs_por_type.get(tid, [])
                assert len(payload) - cr.i == len(refs), \
                    "Frame/Visible: %dB != %d refs" % (len(payload) - cr.i, len(refs))
                body = bytearray(payload[cr.i:])
                for r in targets:
                    body[refs.index(r)] = 0
                payload = payload[:cr.i] + bytes(body)
                patched += 1
        out_chunks.append((cname, payload))
    assert patched == 1, "chunks Frame/Visible patchados: %d" % patched

    out = bytearray(MAGIC)
    out += struct.pack("<H", version)
    out += struct.pack("<I", num_types)
    out += struct.pack("<I", num_instances)
    out += b"\x00" * 8
    for cname, payload in out_chunks:
        out += chunk_out(cname, payload)
    end_payload = next((p for n, p in chunks if n.startswith(b"END")), b"\x00</roblox>")
    out += chunk_out(b"END\x00", end_payload)
    open(outp, "wb").write(bytes(out))
    print("ok: %s (%d bytes, %d instancias)" % (outp, len(out), num_instances))


if __name__ == "__main__":
    main()
