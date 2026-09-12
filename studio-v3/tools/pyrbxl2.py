#!/usr/bin/env python3
"""Decoder do formato binario MODERNO do Roblox (v0 — o que o Studio atual grava).

Spec: rojo-rbx/rbx-dom (rbx_binary). Uso:
  pyrbxl2.py <arquivo>            -> dump da estrutura
  pyrbxl2.py decode <arquivo> -o json  -> estrutura em JSON (para o builder)

Preserva payloads brutos de PROP/SSTR/META p/ re-encoding lossless.
"""
import json
import struct
import sys

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"


def zigzag32_dec(x: int) -> int:
    x &= 0xFFFFFFFF
    return (x >> 1) ^ -(x & 1)


class R:
    def __init__(self, d: bytes):
        self.d = d
        self.i = 0

    def take(self, n):
        b = self.d[self.i:self.i + n]
        if len(b) < n:
            raise EOFError(f"EOF em {self.i} (queria {n})")
        self.i += n
        return b

    def u8(self):
        return self.take(1)[0]

    def u16(self):
        return struct.unpack("<H", self.take(2))[0]

    def u32(self):
        return struct.unpack("<I", self.take(4))[0]

    def i32(self):
        return struct.unpack("<i", self.take(4))[0]

    def string(self):
        n = self.u32()
        return self.take(n).decode("utf-8")

    def referent_array(self, n: int):
        """n u32s em layout planar (byte b do valor i em i+b*n; os 4 planos lidos
        como big-endian), zigzag32, delta-encoded. Confirmado em fixtures reais."""
        buf = self.take(4 * n)
        last = 0
        out = []
        for i in range(n):
            x = ((buf[i] << 24) | (buf[i + n] << 16) | (buf[i + 2 * n] << 8) | buf[i + 3 * n]) & 0xFFFFFFFF
            last += zigzag32_dec(x)
            out.append(last)
        return out


class Model:
    def __init__(self):
        self.version = 0
        self.num_types = 0
        self.num_instances = 0
        self.chunks = []  # lista de (name, raw_payload, parsed|None) na ordem original


def parse(data: bytes) -> Model:
    m = Model()
    if data[:14] != MAGIC:
        raise ValueError(f"magic invalida: {data[:14]!r}")
    r = R(data)
    r.take(14)
    m.version = r.u16()
    m.num_types = r.u32()
    m.num_instances = r.u32()
    reserved = r.take(8)
    if reserved != b"\x00" * 8:
        raise ValueError(f"reserved != 0: {reserved!r}")

    while r.i < len(r.d):
        name = r.take(4)
        clen = r.u32()
        dlen = r.u32()
        resv = r.u32()
        if resv != 0:
            raise ValueError(f"chunk {name!r}: reserved != 0")
        if clen == 0:
            payload = r.take(dlen)
        else:
            import lz4.block
            raw = r.take(clen)
            if raw[:4] == b"\x28\xb5\x2f\xfd":
                import zstandard
                payload = zstandard.ZstdDecompressor().decompress(raw, max_output_size=dlen)
            else:
                payload = lz4.block.decompress(raw, dlen)
        m.chunks.append([name, payload, None])

        if name == b"INST":
            cr = R(payload)
            type_id = cr.u32()
            type_name = cr.string()
            is_service = cr.u8()
            count = cr.u32()
            refs = cr.referent_array(count)
            svc_flags = [cr.u8() for _ in range(count)] if is_service else []
            cr.take(len(cr.d) - cr.i)
            m.chunks[-1][2] = (type_id, type_name, is_service, refs, svc_flags)
        elif name == b"PRNT":
            cr = R(payload)
            ver = cr.u8()
            count = cr.u32()
            subjects = cr.referent_array(count)
            parents = cr.referent_array(count)
            m.chunks[-1][2] = (ver, subjects, parents)
        elif name == b"SSTR":
            cr = R(payload)
            ver = cr.u32()
            count = cr.u32()
            entries = []
            for _ in range(count):
                h = cr.take(16)
                v = cr.take(cr.u32())
                entries.append((h, v))
            m.chunks[-1][2] = (ver, entries)
        elif name == b"META":
            cr = R(payload)
            count = cr.u32()
            pairs = [(cr.string(), cr.string()) for _ in range(count)]
            m.chunks[-1][2] = pairs
        elif name == b"END\x00":
            pass
    return m


def build_index(m: Model):
    """retorna: type_by_id, instance ref -> (type_name, index-in-file-order)"""
    type_by_id = {}
    instances = {}  # referent -> type_name
    order = []
    for name, payload, parsed in m.chunks:
        if name != b"INST" or parsed is None:
            continue
        type_id, type_name, is_s, refs, flags = parsed
        type_by_id[type_id] = (type_name, is_s)
        for ref in refs:
            instances[ref] = type_name
            order.append(ref)
    return type_by_id, instances, order


def name_of(m: Model, referent) -> str:
    type_by_id, instances, order = build_index(m)
    # varre PROP Name (String)
    for name, payload, parsed in m.chunks:
        if name != b"PROP":
            continue
        cr = R(payload)
        type_id = cr.u32()
        prop_name = cr.string()
        t = cr.u8()
        if prop_name != "Name" or t != 1:
            continue
        type_name, is_s = type_by_id.get(type_id, (None, 0))
        for name_chunk in m.chunks:
            if name_chunk[0] == b"INST" and name_chunk[2] is not None and name_chunk[2][0] == type_id:
                for ref in name_chunk[2][3]:
                    s = cr.take(cr.u32()).decode("utf-8", "replace")
                    if ref == referent:
                        return s
    return "?"


def dump(m: Model):
    print(f"version={m.version} types={m.num_types} instances={m.num_instances}")
    type_by_id, instances, order = build_index(m)
    # nomes
    names = {}
    for name, payload, parsed in m.chunks:
        if name != b"PROP":
            continue
        cr = R(payload)
        type_id = cr.u32()
        prop_name = cr.string()
        t = cr.u8()
        if prop_name != "Name" or t != 1:
            continue
        for nc in m.chunks:
            if nc[0] == b"INST" and nc[2] is not None and nc[2][0] == type_id:
                for ref in nc[2][3]:
                    names[ref] = cr.take(cr.u32()).decode("utf-8", "replace")
    prnt = None
    for name, payload, parsed in m.chunks:
        if name == b"PRNT" and parsed:
            prnt = parsed
    print("\n== chunks ==")
    for name, payload, parsed in m.chunks:
        print(f"  {name!r} payload={len(payload)}")
    print("\n== top-level (parent=-1) ==")
    if prnt:
        ver, subjects, parents = prnt
        for subj, par in zip(subjects, parents):
            if par == -1:
                print(f"  [{subj}] {instances.get(subj, '?')!r} name={names.get(subj, '?')!r}")
    print("\n== arvore (primeiros 40) ==")
    if prnt:
        ver, subjects, parents = prnt
        children = {}
        for subj, par in zip(subjects, parents):
            children.setdefault(par, []).append(subj)
        count = [0]

        def walk(ref, depth):
            if count[0] > 40:
                return
            count[0] += 1
            cls = instances.get(ref, "?")
            nm = names.get(ref, "?")
            print("  " * depth + f"{cls} '{nm}' (ref={ref})")
            for c in children.get(ref, []):
                walk(c, depth + 1)
        for subj, par in zip(subjects, parents):
            if par == -1:
                walk(subj, 0)


def to_json(m: Model) -> dict:
    type_by_id, instances, order = build_index(m)
    out = {
        "version": m.version,
        "chunks": [],
    }
    for name, payload, parsed in m.chunks:
        out["chunks"].append({"name": name.decode("latin1"), "len": len(payload)})
    return out


if __name__ == "__main__":
    path = sys.argv[1]
    data = open(path, "rb").read()
    m = parse(data)
    dump(m)
