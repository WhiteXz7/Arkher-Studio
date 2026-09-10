#!/usr/bin/env python3
"""Codec dos valores PROP do formato binario do Roblox (spec dom.rojo.space/binary.html).

Regras (confirmadas nos exemplos da spec):
  - Int32 (t=3):  u32 zigzag  (x<0 ? 2|x|-1 : 2x), bytes BIG-ENDIAN,
                  byte-interleaved quando em array.
  - Float32 (t=4): formato ROBLOX  (bits: eeeeeeee mmmmmmmm mmmmmmmm mmmmmms,
                  o bit de sinal vai para o LSB), BIG-ENDIAN, interleaved em array.
  - UDim (t=6):   array de Scale (Float32) + array de Offset (Int32).
  - UDim2 (t=7):  4 arrays: X.Scale, Y.Scale (Float32), X.Offset, Y.Offset (Int32).
  - Color3 (t=12): 3 arrays R, G, B (Float32).
  - Vector2 (t=13): 2 arrays X, Y (Float32).
  - Vector3 (t=14): 3 arrays X, Y, Z (Float32).
  - Rect (t=18? nao — t=0x18): 4 arrays Min.X Min.Y Max.X Max.Y (Float32).
  - Enum (t=18):   u32 sem transformacao, BIG-ENDIAN, interleaved em array.
  - String (t=1):  u32 len + bytes, sequencial.
  - Bool (t=2):    1 byte, sequencial.

Interleaving: n valores de w bytes (na ordem BE); stored[plane*n + i] = valor_be[i][plane].
"""
import struct


# ---------------------------------------------------------------- floats
def f32_bits(v: float) -> int:
    return struct.unpack("<I", struct.pack("<f", v))[0]


def bits_f32(b: int) -> float:
    return struct.unpack("<f", struct.pack("<I", b & 0xFFFFFFFF))[0]


def f32_to_rb(bits: int) -> int:
    """IEEE754 bits -> bits no formato Roblox (sinal no LSB)."""
    bits &= 0xFFFFFFFF
    return (((bits & 0x7FFFFFFF) << 1) | (bits >> 31)) & 0xFFFFFFFF


def rb_to_f32(bits: int) -> int:
    """Bits Roblox -> bits IEEE754.
    Roblox: [E:24-31][M:1-23][s:0];  IEEE: [s:31][E:23-30][M:0-22]."""
    bits &= 0xFFFFFFFF
    return ((bits >> 1) & 0x7FFFFFFF) | ((bits & 1) << 31)


def flt_to_rb(v: float) -> int:
    return f32_to_rb(f32_bits(v))


def rb_to_flt(bits: int) -> float:
    return bits_f32(rb_to_f32(bits))


# ---------------------------------------------------------------- ints
def zigzag(x: int) -> int:
    # converte para signed 32-bit p/ o shift aritmetico funcionar no Python
    x &= 0xFFFFFFFF
    if x & 0x80000000:
        x -= 0x100000000
    return ((x << 1) ^ (x >> 31)) & 0xFFFFFFFF


def unzigzag(y: int) -> int:
    y &= 0xFFFFFFFF
    z = (y >> 1) ^ -(y & 1)
    return z & 0xFFFFFFFF  # como u32; o caller interpreta como i32


def i32(u: int) -> int:
    u &= 0xFFFFFFFF
    return u - 0x100000000 if u & 0x80000000 else u


# ---------------------------------------------------------------- interleave
def interleave_u32(vals, w: int = 4) -> bytes:
    """vals: lista de u32 (ja transformados). Retorna bytes interleaved (BE por valor)."""
    n = len(vals)
    out = bytearray(n * w)
    for i, v in enumerate(vals):
        for p in range(w):
            out[p * n + i] = (v >> (8 * (w - 1 - p))) & 0xFF
    return bytes(out)


def deinterleave_u32(buf: bytes, n: int, w: int = 4):
    """inverso de interleave_u32."""
    out = []
    for i in range(n):
        v = 0
        for p in range(w):
            v = (v << 8) | buf[p * n + i]
        out.append(v)
    return out


# ---------------------------------------------------------------- tipos
def dec_array_u32(buf: bytes, n: int) -> list:
    return deinterleave_u32(buf, n, 4)


def enc_array_u32(vals: list) -> bytes:
    return interleave_u32(vals, 4)


def decode(t: int, buf: bytes, n: int):
    """retorna lista de n valores python."""
    if t == 1:
        raise SystemExit("String nao vai aqui (len-prefix sequencial)")
    if t == 2:
        return [b != 0 for b in buf]
    if t == 3:
        return [i32(unzigzag(v)) for v in dec_array_u32(buf, n)]
    if t == 4:
        return [rb_to_flt(v) for v in dec_array_u32(buf, n)]
    if t == 6:  # UDim: [scale f32][offset int32]
        s = dec_array_u32(buf[:4 * n], n)
        o = dec_array_u32(buf[4 * n:], n)
        return [(rb_to_flt(s[i]), i32(unzigzag(o[i]))) for i in range(n)]
    if t == 7:  # UDim2: XS YS XO YO
        c = 4 * n
        xs = dec_array_u32(buf[0:c], n)
        ys = dec_array_u32(buf[c:2 * c], n)
        xo = dec_array_u32(buf[2 * c:3 * c], n)
        yo = dec_array_u32(buf[3 * c:], n)
        return [(rb_to_flt(xs[i]), i32(unzigzag(xo[i])),
                 rb_to_flt(ys[i]), i32(unzigzag(yo[i]))) for i in range(n)]
    if t == 12:  # Color3: R G B
        c = 4 * n
        r = dec_array_u32(buf[0:c], n)
        g = dec_array_u32(buf[c:2 * c], n)
        b = dec_array_u32(buf[2 * c:], n)
        return [(rb_to_flt(r[i]), rb_to_flt(g[i]), rb_to_flt(b[i])) for i in range(n)]
    if t == 13:  # Vector2: X Y
        c = 4 * n
        x = dec_array_u32(buf[0:c], n)
        y = dec_array_u32(buf[c:], n)
        return [(rb_to_flt(x[i]), rb_to_flt(y[i])) for i in range(n)]
    if t == 14:  # Vector3: X Y Z
        c = 4 * n
        x = dec_array_u32(buf[0:c], n)
        y = dec_array_u32(buf[c:2 * c], n)
        z = dec_array_u32(buf[2 * c:], n)
        return [(rb_to_flt(x[i]), rb_to_flt(y[i]), rb_to_flt(z[i])) for i in range(n)]
    if t == 0x18:  # Rect: Min.X Min.Y Max.X Max.Y
        c = 4 * n
        a = [dec_array_u32(buf[k * c:(k + 1) * c], n) for k in range(4)]
        return [(rb_to_flt(a[0][i]), rb_to_flt(a[1][i]),
                 rb_to_flt(a[2][i]), rb_to_flt(a[3][i])) for i in range(n)]
    if t == 18:  # Enum: u32 puro
        return [v for v in dec_array_u32(buf, n)]
    raise SystemExit(f"tipo nao suportado: {t}")


def encode(t: int, vals: list) -> bytes:
    """vals: lista de valores python -> bytes do array."""
    n = len(vals)
    if t == 2:
        return bytes(1 if v else 0 for v in vals)
    if t == 3:
        return enc_array_u32([zigzag(v) for v in vals])
    if t == 4:
        return enc_array_u32([flt_to_rb(v) for v in vals])
    if t == 6:
        s = enc_array_u32([flt_to_rb(v[0]) for v in vals])
        o = enc_array_u32([zigzag(v[1]) for v in vals])
        return s + o
    if t == 7:
        xs = enc_array_u32([flt_to_rb(v[0]) for v in vals])
        xo = enc_array_u32([zigzag(v[1]) for v in vals])
        ys = enc_array_u32([flt_to_rb(v[2]) for v in vals])
        yo = enc_array_u32([zigzag(v[3]) for v in vals])
        return xs + ys + xo + yo
    if t == 12:
        r = enc_array_u32([flt_to_rb(v[0]) for v in vals])
        g = enc_array_u32([flt_to_rb(v[1]) for v in vals])
        b = enc_array_u32([flt_to_rb(v[2]) for v in vals])
        return r + g + b
    if t == 13:
        x = enc_array_u32([flt_to_rb(v[0]) for v in vals])
        y = enc_array_u32([flt_to_rb(v[1]) for v in vals])
        return x + y
    if t == 14:
        a = [enc_array_u32([flt_to_rb(v[k]) for v in vals]) for k in range(3)]
        return b"".join(a)
    if t == 0x18:
        a = [enc_array_u32([flt_to_rb(v[k]) for v in vals]) for k in range(4)]
        return b"".join(a)
    if t == 18:
        return enc_array_u32([v for v in vals])
    raise SystemExit(f"tipo nao suportado: {t}")


# ---------------------------------------------------------------- testes
if __name__ == "__main__":
    def hx(s):
        return bytes.fromhex(s.replace(" ", ""))

    fails = 0

    # 1) UDim {1,2} {3,4}
    got = decode(6, hx("7f 80 00 80 00 00 00 00 00 00 00 00 00 00 04 08"), 2)
    want = [(1.0, 2), (3.0, 4)]
    if got != want:
        print("FAIL UDim:", got); fails += 1
    if encode(6, want) != hx("7f 80 00 80 00 00 00 00 00 00 00 00 00 00 04 08"):
        print("FAIL UDim encode"); fails += 1

    # 2) UDim2 {0.75, -30, -1.5, 60}
    got = decode(7, hx("7e 80 00 00 7f 80 00 01 00 00 00 3b 00 00 00 78"), 1)
    want = [(0.75, -30, -1.5, 60)]
    if got != want:
        print("FAIL UDim2:", got); fails += 1
    if encode(7, want) != hx("7e 80 00 00 7f 80 00 01 00 00 00 3b 00 00 00 78"):
        print("FAIL UDim2 encode"); fails += 1

    # 3) Vector3 (1,2,3) (-1,-2,-3)
    got = decode(14, hx("7f 7f 00 00 00 00 00 01 80 80 00 00 00 00 00 01 80 80 80 80 00 00 00 01"), 2)
    want = [(1.0, 2.0, 3.0), (-1.0, -2.0, -3.0)]
    if got != want:
        print("FAIL Vector3:", got); fails += 1
    if encode(14, want) != hx("7f 7f 00 00 00 00 00 01 80 80 00 00 00 00 00 01 80 80 80 80 00 00 00 01"):
        print("FAIL Vector3 encode"); fails += 1

    # 4) Vector2 (-100.80, 200.55) (200.55, -100.80)
    got = decode(13, hx("85 86 93 91 33 19 35 9a 86 85 91 93 19 33 9a 35"), 2)
    want = [(bits_f32(f32_bits(-100.80)), bits_f32(f32_bits(200.55))),
            (bits_f32(f32_bits(200.55)), bits_f32(f32_bits(-100.80)))]
    if got != want:
        print("FAIL Vector2:", got, want); fails += 1
    if encode(13, want) != hx("85 86 93 91 33 19 35 9a 86 85 91 93 19 33 9a 35"):
        print("FAIL Vector2 encode"); fails += 1

    # 5) Rect (-1,-10,8,9) (0,1,5,6)
    got = decode(0x18, hx("7f 00 00 00 00 00 01 00 82 7f 40 00 00 00 01 00 82 81 00 40 00 00 00 00 82 81 20 80 00 00 00 00"), 2)
    want = [(-1.0, -10.0, 8.0, 9.0), (0.0, 1.0, 5.0, 6.0)]
    if got != want:
        print("FAIL Rect:", got); fails += 1
    if encode(0x18, want) != hx("7f 00 00 00 00 00 01 00 82 7f 40 00 00 00 01 00 82 81 00 40 00 00 00 00 82 81 20 80 00 00 00 00"):
        print("FAIL Rect encode"); fails += 1

    # 6) Float32 -0.15625 -> 7c 40 00 01
    got = decode(4, hx("7c 40 00 01"), 1)
    if abs(got[0] - -0.15625) > 1e-9:
        print("FAIL Float32:", got); fails += 1
    if encode(4, [-0.15625]) != hx("7c 40 00 01"):
        print("FAIL Float32 encode"); fails += 1

    # 7) Color3 doc: R=255/255=1.0, B=20/255 exatos
    got = decode(12, hx("7f 00 00 00 7e 69 69 6a 7b 41 41 42"), 1)[0]
    if abs(got[0] - 1.0) > 1e-9 or abs(got[2] - 20 / 255) > 1e-6:
        print("FAIL Color3 doc:", got); fails += 1

    # 8) Int32 zigzag/BE: [10, -30, 60] -> ?
    b = encode(3, [10, -30, 60])
    back = decode(3, b, 3)
    if back != [10, -30, 60]:
        print("FAIL Int32 roundtrip:", back); fails += 1
    # valor unico 10 -> BE de zigzag(10)=20=0x14
    if encode(3, [10]) != bytes.fromhex("00000014"):
        print("FAIL Int32 unico:", encode(3, [10]).hex()); fails += 1

    # 9) Enum u32 BE unico
    if encode(18, [1]) != bytes.fromhex("00000001"):
        print("FAIL Enum unico"); fails += 1
    if decode(18, bytes.fromhex("00000002"), 1) != [2]:
        print("FAIL Enum decode"); fails += 1

    # 10) Bool
    if decode(2, bytes([0, 1, 0, 1]), 4) != [False, True, False, True]:
        print("FAIL Bool"); fails += 1

    print("TESTES:", "TODOS OK" if fails == 0 else f"{fails} FALHAS")
