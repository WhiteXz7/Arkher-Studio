#!/usr/bin/env python3
"""Decoder do formato binario legacy .rbxl (spec: robloxapi/rbxfile).

Uso: pyrbxl decode <arquivo.rbxl>   -> dump da estrutura
     (modulo importavel: parse() retorna FormatModel)
"""
import struct
import sys

SIG_INST = 0x54534E49  # "TSNI"
SIG_END = 0x00444E45   # "\0DNE"
SIG_PRNT = 0x544E5250  # "TNRP"
SIG_PROP = 0x504F5250  # "PORP"
SIG_META = 0x4154454D  # "ATEM"
SIG_SSTR = 0x52545353  # "RTSS"


def zigzag32_enc(n: int) -> int:
    n &= 0xFFFFFFFF
    return (n << 1) ^ (n >> 31) & 0xFFFFFFFF


def zigzag32_dec(x: int) -> int:
    x &= 0xFFFFFFFF
    return (x >> 1) ^ -(x & 1)


def zigzag64_enc(n: int) -> int:
    n &= (1 << 64) - 1
    return (n << 1) ^ (n >> 63) & ((1 << 64) - 1)


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

    def u64(self):
        return struct.unpack("<Q", self.take(8))[0]

    def i32(self):
        return struct.unpack("<i", self.take(4))[0]

    def i64(self):
        return struct.unpack("<q", self.take(8))[0]

    def ref(self):
        # u32 BIG-endian zigzag32
        return zigzag32_dec(struct.unpack(">I", self.take(4))[0])

    def refarray(self, n):
        return [self.ref() for _ in range(n)]

    def string(self):
        n = self.u32()
        return self.take(n).decode("utf-8")


T_INVALID = 0
T_STRING = 1
T_BOOL = 2
T_INT = 3
T_FLOAT = 4
T_DOUBLE = 5
T_UDIM = 6
T_UDIM2 = 7
T_RAY = 8
T_FACES = 9
T_AXES = 0xA
T_BRICKCOLOR = 0xB
T_COLOR3 = 0xC
T_VECTOR2 = 0xD
T_VECTOR3 = 0xE
T_VECTOR2INT16 = 0xF
T_CFRAME = 0x10
T_CFRAME_QUAT = 0x11
T_TOKEN = 0x12
T_REFERENCE = 0x13
T_VECTOR3INT16 = 0x14
T_NUMBERSEQUENCE = 0x15
T_COLORSEQUENCE = 0x16
T_NUMBERRANGE = 0x17
T_RECT = 0x18
T_PHYSICALPROPERTIES = 0x19
T_COLOR3UINT8 = 0x1A
T_INT64 = 0x1B
T_SHAREDSTRING = 0x1C
T_SIGNEDSTRING = 0x1D
T_OPTIONAL = 0x1E
T_UNIQUEID = 0x1F
T_FONT = 0x20

TYPENAMES = {
    T_STRING: "string", T_BOOL: "bool", T_INT: "int", T_FLOAT: "float",
    T_DOUBLE: "double", T_UDIM: "UDim", T_UDIM2: "UDim2", T_RAY: "Ray",
    T_FACES: "Faces", T_AXES: "Axes", T_BRICKCOLOR: "BrickColor",
    T_COLOR3: "Color3", T_VECTOR2: "Vector2", T_VECTOR3: "Vector3",
    T_VECTOR2INT16: "Vector2int16", T_CFRAME: "CFrame", T_CFRAME_QUAT: "CFrameQuat",
    T_TOKEN: "token", T_REFERENCE: "Ref", T_VECTOR3INT16: "Vector3int16",
    T_NUMBERSEQUENCE: "NumberSequence", T_COLORSEQUENCE: "ColorSequence",
    T_NUMBERRANGE: "NumberRange", T_RECT: "Rect",
    T_PHYSICALPROPERTIES: "PhysicalProperties", T_COLOR3UINT8: "Color3uint8",
    T_INT64: "int64", T_SHAREDSTRING: "SharedString",
    T_SIGNEDSTRING: "SignedString", T_OPTIONAL: "optional",
    T_UNIQUEID: "UniqueId", T_FONT: "Font",
}


def decode_value(r: R, t: int, count: int):
    """Decodifica `count` valores do tipo `t`. Retorna lista de (t, bytes-raw)."""
    out = []
    for _ in range(count):
        if t == T_STRING:
            n = r.u32()
            raw = r.take(n)
        elif t == T_BOOL:
            raw = r.take(1)
        elif t in (T_INT, T_FONT):
            raw = r.take(4)
        elif t == T_FLOAT:
            raw = r.take(4)
        elif t in (T_DOUBLE,):
            raw = r.take(8)
        elif t == T_INT64:
            raw = r.take(8)
        elif t in (T_UDIM, T_VECTOR2):
            raw = r.take(8)
        elif t in (T_VECTOR3, T_NUMBERRANGE, T_UDIM2):
            raw = r.take(12)
        elif t == T_CFRAME:
            sp = r.u8()
            raw = struct.pack("<B", sp)
            if sp == 0:
                raw += r.take(36)  # 9x f32 rotacao
            raw += r.take(12)  # posicao 3x f32
        elif t == T_CFRAME_QUAT:
            sp = r.u8()
            raw = struct.pack("<B", sp)
            if sp == 0:
                raw += r.take(16)  # quat 4x f32
            raw += r.take(12)
        elif t == T_RAY:
            raw = r.take(24)  # 6x f32
        elif t == T_COLOR3:
            raw = r.take(12)
        elif t == T_COLOR3UINT8:
            raw = r.take(3)  # rgb u8x3
        elif t == T_BRICKCOLOR:
            raw = r.take(4)  # u32
        elif t in (T_FACES, T_AXES):
            raw = r.take(1)
        elif t == T_TOKEN:
            raw = r.take(4)  # u32 (indice)
        elif t == T_REFERENCE:
            raw = r.take(4)  # zigzag BE
        elif t in (T_VECTOR2INT16, T_VECTOR3INT16):
            sz = 4 if t == T_VECTOR2INT16 else 6
            raw = r.take(sz)
        elif t in (T_NUMBERSEQUENCE, T_COLORSEQUENCE):
            n = r.u32()
            ksize = 8 if t == T_NUMBERSEQUENCE else 16
            raw = struct.pack("<I", n) + r.take(n * ksize)
        elif t == T_PHYSICALPROPERTIES:
            cp = r.u8()
            raw = struct.pack("<B", cp)
            if cp != 0:
                raw += r.take(20)  # 5x f32
        elif t == T_RECT:
            raw = r.take(16)
        elif t == T_SHAREDSTRING:
            raw = r.take(4)  # u32 index
        elif t == T_UNIQUEID:
            raw = r.take(16)
        elif t == T_OPTIONAL:
            flag = r.u8()
            if flag == 0:
                raw = b"\x00"
            else:
                inner_t = r.u8()
                # decodifica 1 valor interno recursivamente
                inner_r_save = r.i
                val = decode_value(r, inner_t, 1)
                raw = b"\x01" + struct.pack("<B", inner_t) + r.d[inner_r_save:r.i]
        elif t == T_SIGNEDSTRING:
            n = r.u32()
            raw = r.take(n + 4)
        else:
            raise ValueError(f"tipo desconhecido {t:#x}")
        out.append(raw)
    return out


class Inst:
    def __init__(self, class_id, class_name, instance_id, is_service, service_flag):
        self.class_id = class_id
        self.class_name = class_name
        self.instance_id = instance_id
        self.is_service = is_service
        self.service_flag = service_flag
        self.props = {}  # name -> (type, raw)


class Model:
    def __init__(self):
        self.version = None
        self.class_count = None
        self.instance_count = None
        self.sstr_version = 0
        self.sstr = []          # (hash16, value)
        self.groups = []        # (class_id, class_name, [instance_ids], is_service, [flags])
        self.props = []         # (class_id, prop_name, type, [raw values])
        self.parents = []       # (child, parent)
        self.meta = []          # (k, v)
        self.end_content = b""
        self.unknown_chunks = []  # (sig, payload)


def parse(data: bytes) -> Model:
    m = Model()
    r = R(data)
    sig = r.take(7)
    assert sig == b"<roblox", f"assinatura invalida: {sig}"
    marker = r.take(1 + 6)
    assert marker == b"!\x89\xff\r\n\x1a\n", f"marker invalido: {marker!r}"
    m.version = r.u16()
    m.class_count = r.u32()
    m.instance_count = r.u32()
    r.u64()  # reserved

    class_lookup = {}
    while r.i < len(r.d):
        sig4 = r.u32()
        c_len = r.u32()
        d_len = r.u32()
        resv = r.u32()
        assert resv == 0, f"reserved != 0 no chunk {sig4:#x}"
        if c_len == 0:
            payload = r.take(d_len)
        else:
            import lz4.block
            payload = lz4.block.decompress(r.take(c_len), d_len)
        if sig4 == SIG_SSTR:
            cr = R(payload)
            m.sstr_version = cr.u32()
            n = cr.u32()
            m.sstr = []
            for _ in range(n):
                h = cr.take(16)
                v = cr.string()
                m.sstr.append((h, v))
        elif sig4 == SIG_INST:
            cr = R(payload)
            class_id = cr.i32()
            class_name = cr.string()
            is_service = cr.u8()
            n = cr.u32()
            ids = cr.refarray(n)
            flags = [cr.u8() for _ in range(n)] if is_service else []
            m.groups.append((class_id, class_name, ids, bool(is_service), flags))
            for iid in ids:
                class_lookup[iid] = (class_id, class_name)
        elif sig4 == SIG_PROP:
            cr = R(payload)
            class_id = cr.i32()
            prop_name = cr.string()
            if cr.i < len(cr.d):
                t = cr.u8()
                cid, cname, ids, _s, _f = next(g for g in m.groups if g[0] == class_id)
                values = decode_value(cr, t, len(ids))
                assert cr.i == len(cr.d), f"dados extras no PROP {prop_name}"
            else:
                t, values = None, []
            m.props.append((class_id, prop_name, t, values))
        elif sig4 == SIG_PRNT:
            cr = R(payload)
            ver = cr.u8()
            assert ver == 0, f"PRNT versao {ver}"
            n = cr.u32()
            children = cr.refarray(n)
            parents = cr.refarray(n)
            m.parents = list(zip(children, parents))
        elif sig4 == SIG_META:
            cr = R(payload)
            n = cr.u32()
            m.meta = [(cr.string(), cr.string()) for _ in range(n)]
        elif sig4 == SIG_END:
            m.end_content = payload
            break
        else:
            m.unknown_chunks.append((sig4, payload))
    return m


def dump(m: Model):
    print(f"version={m.version} classes={m.class_count} instances={m.instance_count}")
    print(f"sstr: {len(m.sstr)} strings (versao {m.sstr_version})")
    print("grupos:")
    for cid, cname, ids, is_s, flags in m.groups:
        print(f"  [{cid}] {cname}: {len(ids)} instancias" + (" SERVICE" if is_s else ""))
    print("props:")
    for cid, pname, t, values in m.props:
        print(f"  [{cid}] {pname} :: {TYPENAMES.get(t, t)} x{len(values)}")
    print(f"parents: {len(m.parents)} links")
    print(f"meta: {m.meta}")
    print(f"end: {m.end_content!r}")


if __name__ == "__main__":
    data = open(sys.argv[2] if len(sys.argv) > 2 else sys.argv[1], "rb").read()
    m = parse(data)
    dump(m)
