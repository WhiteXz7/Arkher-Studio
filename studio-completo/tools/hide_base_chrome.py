#!/usr/bin/env python3
"""Esconde as faixas mortas da base no .rbxl (R18/R19: topbar unica).

PoE em bake-time Visible=false em:
  R18: TitleBar, MenuBar, Ribbon (filhos de Canvas) — topbar antiga,
       substituida pela ArkherTop (18 menus + 9 abas + 42 botoes).
  R19: DocumentTabs, LeftTabs, ChatBar (filhos de Canvas) +
       CommandBar, Arkher (filhos de Footer) — faixas 100% decorativas:
       todos os botoes sao WIP ("Em desenvolvimento", 01_Nucleo cz) e os
       2 inputs (CommandBar/Chat) nao tem fiacao. As funcoes reais moram
       em: Places (aba SCENES), Team (TM2 + aba PLUGINS), Command Bar real
       (aba SCRIPTS > XOpenComando), Help (aba HELP).
Todo o resto (docks, viewport, footer, status) intacto.

Patch cirurgico: re-emite o arquivo com N bytes alterados nos chunks
PROP <Classe>/Visible (bool = 1 byte/ref na ordem do INST). Nada e
criado, removido ou reordenado; instancias e bytes antigos preservados.

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
# (nome-do-pai, nome-do-filho); pai None = Canvas.
HIDE = [(None, "TitleBar"), (None, "MenuBar"), (None, "Ribbon"),
        (None, "DocumentTabs"), (None, "LeftTabs"), (None, "ChatBar"),
        ("Footer", "CommandBar"), ("Footer", "Arkher")]


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
    by_parent = {}
    for s, p in parent.items():
        by_parent.setdefault(p, []).append(s)

    def only_child(pref, nm):
        found = [s for s in by_parent.get(pref, [])
                 if name_por_ref.get(s) == nm]
        assert len(found) == 1, "%s/%s: %d refs" % (
            name_por_ref.get(pref), nm, len(found))
        return found[0]

    targets = []
    for pname, nm in HIDE:
        pref = canvas if pname is None else only_child(canvas, pname)
        targets.append(only_child(pref, nm))
    tclass = {}
    for tid, refs in refs_por_type.items():
        for r in refs:
            tclass[r] = type_by_id[tid]
    print("escondendo:", sorted("%s#%d (%s)" % (name_por_ref[r], r, tclass[r])
                                for r in targets))

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
            if pname == "Visible" and t == 2:
                refs = refs_por_type.get(tid, [])
                mine = [r for r in targets if r in refs]
                if mine:
                    assert len(payload) - cr.i == len(refs), \
                        "%s/Visible: %dB != %d refs" % (
                            type_by_id[tid], len(payload) - cr.i, len(refs))
                    pos = {r: i for i, r in enumerate(refs)}
                    body = bytearray(payload[cr.i:])
                    for r in mine:
                        body[pos[r]] = 0
                    payload = payload[:cr.i] + bytes(body)
                    patched += 1
        out_chunks.append((cname, payload))
    assert patched >= 1, "nenhum chunk Visible patchado"

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
