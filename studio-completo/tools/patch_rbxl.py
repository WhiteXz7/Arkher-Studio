#!/usr/bin/env python3
"""Patch de fontes de script num .rbxl (formato binario moderno), lossless.

Re-encoda SO os chunks PROP 'Source' dos scripts nomeados; todos os demais
chunks sao re-emitidos com o payload bruto original (bit-exact).

Uso:
  patch_rbxl.py <in.rbxl> <out.rbxl> <class>:<name>=<srcfile> [class:name=srcfile ...]

Exemplo:
  patch_rbxl.py in.rbxl out.rbxl LocalScript:Arkher_03_Menus=scripts/03_Menus.lua
"""
import struct
import sys
import os

_here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_here, "..", "..", "studio-v3", "tools"))
sys.path.insert(0, _here)
import pyrbxl2

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"


def read_header(data):
    r = pyrbxl2.R(data)
    assert data[:14] == MAGIC, "magic invalida"
    r.take(14)
    version = r.u16()
    num_types = r.u32()
    num_instances = r.u32()
    reserved = r.take(8)
    assert reserved == b"\x00" * 8
    return version, num_types, num_instances, r.i


def parse_chunks(data, hdr_end):
    r = pyrbxl2.R(data)
    r.take(hdr_end)
    chunks = []
    while r.i < len(r.d):
        name = r.take(4)
        clen = r.u32()
        dlen = r.u32()
        resv = r.u32()
        assert resv == 0, f"chunk {name!r} reserved!=0"
        if clen == 0:
            payload = r.take(dlen)
        else:
            raw = r.take(clen)
            if raw[:4] == b"\x28\xb5\x2f\xfd":
                import zstandard
                payload = zstandard.ZstdDecompressor().decompress(raw, max_output_size=dlen)
            else:
                import lz4.block
                payload = lz4.block.decompress(raw, dlen)
        chunks.append([name, payload])
    return chunks


def s(b: str) -> bytes:
    raw = b.encode("utf-8")
    return struct.pack("<I", len(raw)) + raw


def chunk_out(name: bytes, payload: bytes) -> bytes:
    # END nunca comprimido (spec)
    if name == b"END\x00":
        return name + struct.pack("<III", 0, len(payload), 0) + payload
    # ZSTD (lvl15) quando reduz; senao crus (clen=0)
    try:
        import zstandard
        c = zstandard.ZstdCompressor(level=15).compress(payload)
        if len(c) < len(payload):
            return name + struct.pack("<III", len(c), len(payload), 0) + c
    except Exception:
        pass
    return name + struct.pack("<III", 0, len(payload), 0) + payload


def build_type_info(chunks):
    """type_by_id, refs_por_type (lista na ordem do INST), name_por_ref."""
    type_by_id = {}
    refs_por_type = {}
    type_ids = {}
    for name, payload in chunks:
        if name != b"INST":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32()
        tname = cr.string()
        is_s = cr.u8()
        count = cr.u32()
        refs = cr.referent_array(count)
        type_by_id[tid] = tname
        refs_por_type[tid] = refs
        type_ids[tname] = tid
    # nomes
    name_por_ref = {}
    for name, payload in chunks:
        if name != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32()
        pname = cr.string()
        t = cr.u8()
        if pname != "Name" or t != 1:
            continue
        for ref in refs_por_type.get(tid, []):
            n = cr.u32()
            name_por_ref[ref] = cr.take(n).decode("utf-8", "replace")
    return type_by_id, refs_por_type, type_ids, name_por_ref


def patch_source(chunk_payload: bytes, position: int, new_value: str) -> bytes:
    """Re-encoda um chunk PROP (String) substituindo o valor na posicao."""
    cr = pyrbxl2.R(chunk_payload)
    cr.u32()      # type_id
    cr.string()   # prop_name
    cr.u8()       # value_type
    head = chunk_payload[: cr.i]  # [tid][pname][type]
    vals = []
    while cr.i < len(cr.d):
        n = cr.u32()
        vals.append(cr.take(n))
    assert len(vals) > position, f"posicao {position} fora do alcance ({len(vals)} valores)"
    out = bytearray(head)
    for i, v in enumerate(vals):
        v = new_value.encode("utf-8") if i == position else v
        out += struct.pack("<I", len(v)) + v
    return bytes(out)


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    inp, outp = sys.argv[1], sys.argv[2]
    data = open(inp, "rb").read()
    version, nt, ni, hdr_end = read_header(data)
    chunks = parse_chunks(data, hdr_end)
    type_by_id, refs_por_type, type_ids, name_por_ref = build_type_info(chunks)

    patches = sys.argv[3:]
    applied = {}
    for spec in patches:
        key, srcfile = spec.split("=", 1)
        cls, sname = key.split(":", 1)
        new_src = open(srcfile, encoding="utf-8").read()
        if cls not in type_ids:
            sys.exit(f"classe nao encontrada: {cls}")
        tid = type_ids[cls]
        refs = refs_por_type[tid]
        target_ref = None
        for ref in refs:
            if name_por_ref.get(ref) == sname:
                target_ref = ref
                break
        if target_ref is None:
            sys.exit(f"script {cls}:{sname} nao encontrado (refs {refs})")
        position = refs.index(target_ref)
        # achar o chunk PROP (tid, Source, String)
        found = False
        for i, (name, payload) in enumerate(chunks):
            if name != b"PROP":
                continue
            cr = pyrbxl2.R(payload)
            ctid = cr.u32()
            cpname = cr.string()
            ctype = cr.u8()
            if ctid == tid and cpname == "Source" and ctype == 1:
                chunks[i] = [name, patch_source(payload, position, new_src)]
                applied[f"{cls}:{sname}"] = (target_ref, position, len(new_src))
                found = True
                break
        if not found:
            sys.exit(f"chunk PROP Source nao encontrado para {cls}:{sname}")

    # re-emit
    out = bytearray(MAGIC)
    out += struct.pack("<H", version)
    out += struct.pack("<I", nt)
    out += struct.pack("<I", ni)
    out += b"\x00" * 8
    for name, payload in chunks:
        out += chunk_out(name, payload)
    open(outp, "wb").write(out)
    print(f"patch aplicado: {outp} ({len(out)} bytes)")
    for k, v in applied.items():
        print(f"  {k}: ref={v[0]} pos={v[1]} source={v[2]} chars")


if __name__ == "__main__":
    main()
