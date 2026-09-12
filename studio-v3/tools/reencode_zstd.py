#!/usr/bin/env python3
"""Re-encoding puro de um .rbxl: reduz o peso SEM alterar nenhum byte de conteúdo.

Lê cada chunk do arquivo original, descomprime o payload e o reescreve
escolhendo o MENOR resultado entre:
  - sem compressão  (clen=0, payload bruto)
  - LZ4 block       (sem frame, como o Studio grava)
  - ZSTD frame      (magic 28 b5 2f fd — o decoder do Roblox detecta pelo magic)

O chunk END é SEMPRE escrito sem compressão (exigência da spec:
"The END chunk must not be compressed").

Como só o codec muda e o payload descomprimido é cópia idêntica, o lugar
resultante é byte-a-byte equivalente em conteúdo (confirmar com
validate_completo.py antes/depois e diff dos payloads).

Uso:
  python3 reencode_zstd.py <entrada.rbxl> <saida.rbxl> [--level 15] [--no-zstd]
"""
import argparse
import struct
import time

import lz4.block

ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"
HEADER_LEN = 32
VALID_TAGS = {b"INST", b"PROP", b"PRNT", b"META", b"SSTR", b"END", b"END\x00"}


def decompress_body(clen: int, dlen: int, body: bytes) -> bytes:
    """body = bytes comprimidos (ou vazio se clen=0). Retorna payload bruto."""
    if clen == 0:
        assert dlen == 0 or body is not None
        return body  # o chamador passa os dlen bytes brutos
    if body[:4] == ZSTD_MAGIC:
        import zstandard
        return zstandard.ZstdDecompressor().decompress(body, max_output_size=dlen)
    return lz4.block.decompress(body, dlen)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("entrada")
    ap.add_argument("saida")
    ap.add_argument("--level", type=int, default=15, help="nível ZSTD (padrão 15)")
    ap.add_argument("--no-zstd", action="store_true", help="só LZ4/bruto, sem ZSTD")
    args = ap.parse_args()

    data = open(args.entrada, "rb").read()
    if data[:14] != b"<roblox!\x89\xff\r\n\x1a\n":
        raise SystemExit("magic inválida")
    header = data[:HEADER_LEN]
    n = len(data)

    zstd_comp = None
    if not args.no_zstd:
        import zstandard
        zstd_comp = zstandard.ZstdCompressor(level=args.level)

    out = bytearray(header)
    stats = []  # (tag, opt, dlen, nlen)
    t0 = time.time()
    i = HEADER_LEN
    while i + 16 <= n:
        tag = data[i:i + 4]
        if tag not in VALID_TAGS:
            raise SystemExit(f"tag inválida {tag!r} em offset {i}")
        clen = struct.unpack_from("<I", data, i + 4)[0]
        dlen = struct.unpack_from("<I", data, i + 8)[0]
        resv = struct.unpack_from("<I", data, i + 12)[0]
        if resv != 0:
            raise SystemExit(f"reservado != 0 no chunk {tag!r} @{i}")
        body = data[i + 16:i + 16 + (clen if clen else dlen)]
        if len(body) != (clen if clen else dlen):
            raise SystemExit(f"chunk {tag!r} truncado em @{i}")
        i += 16 + (clen if clen else dlen)

        payload = decompress_body(clen, dlen, body)

        if tag == b"END":
            # spec: END nunca comprimido
            out += tag + struct.pack("<III", 0, dlen, 0) + payload
            stats.append((tag, "raw", dlen, dlen))
            continue

        cands = []
        if clen == 0 or dlen <= 32:
            cands.append(("raw", payload))
        c_lz4 = lz4.block.compress(payload, store_size=False)
        cands.append(("lz4", c_lz4))
        if zstd_comp is not None:
            c_zstd = zstd_comp.compress(payload)
            cands.append(("zstd", c_zstd))
        cands.sort(key=lambda kv: len(kv[1]))
        opt, new_body = cands[0]

        if opt == "raw":
            out += tag + struct.pack("<III", 0, dlen, 0) + new_body
        else:
            out += tag + struct.pack("<III", len(new_body), dlen, 0) + new_body
        stats.append((tag, opt, dlen, len(new_body)))

    if i != n:
        raise SystemExit(f"resto de {n - i} bytes após o último chunk")

    with open(args.saida, "wb") as f:
        f.write(out)

    dt = time.time() - t0
    print(f"entrada : {args.entrada} ({len(data):,} B)")
    print(f"saída   : {args.saida} ({len(out):,} B)  delta={len(out) - len(data):+,} "
          f"({(len(out) - len(data)) / len(data) * 100:+.1f}%)")
    print(f"tempo   : {dt:.1f}s")
    by = {}
    for tag, opt, dlen, nlen in stats:
        e = by.setdefault(tag, [0, 0, 0, 0])
        e[0] += 1
        e[1] += dlen
        e[2] += nlen
        e[3] += 1 if opt != "raw" else 0
    print(f"{'chunk':6s} {'n':>5s} {'dlen':>13s} {'novo':>13s} {'compr.':>6s}")
    for tag, (cnt, dlen, nlen, nc) in sorted(by.items(), key=lambda kv: -kv[1][2]):
        print(f"{tag.decode('utf8', 'replace'):6s} {cnt:5d} {dlen:13,d} {nlen:13,d} {nc:6d}")
    opts = {}
    for tag, opt, dlen, nlen in stats:
        opts[opt] = opts.get(opt, 0) + 1
    print(f"codec por chunk: {opts}")


if __name__ == "__main__":
    main()
