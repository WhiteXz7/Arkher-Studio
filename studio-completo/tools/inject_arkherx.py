#!/usr/bin/env python3
"""Injeta o stack ARKHER X num .rbxl EXISTENTE de forma ADDITIVA e lossless:

  * SEM alterar 1 byte das instancias ORIGINAIS (GUI idêntica byte-a-byte).
  * Novas instancias sao ANEXADAS (novos referent ids altos), seguindo o
    modelo nativo do Roblox:
      ServerStorage/ArkherEngines/*    (ModuleScripts dos motores — seguros)
      ServerScriptService/ArkherEngineServer  (Script ponte)
      ReplicatedStorage/ArkherNet/*    (RemoteEvent/RemoteFunction — so a ponte)
      StarterGui/ArkherStudioUI/Arkher_05_StudioX (LocalScript — UI Studio X)

Validacao (interna):
  * re-parse do arquivo gerado com pyrbxl2 (round-trip total)
  * AND assert de que TODO chunk de instancia/propriedade ORIGINAL permanece
    byte-identico (ponto a ponto) — apenas PRNT muda (filhos anexados) e
    os INST/PROP das classes que GANHAM instancias (Script/LocalScript)
    sao re-emitidos com os mesmos conteudos + anexos.

Uso: inject_arkherx.py <in.rbxl> <out.rbxl>
"""
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
import pyrbxl2

from patch_rbxl import read_header, parse_chunks, chunk_out, s, build_type_info
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
from make_rbxl import referent_array_enc, zigzag32_enc

ROOT = os.path.dirname(HERE)
V3_CORE = os.path.join(ROOT, "..", "studio-v3", "core")

MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"

ENGINE_MODULES = ["DM", "THX", "WLDX", "RRX", "FABX", "DAYX", "ECOX", "WEAX", "CIVIX", "SECX", "PHYSX", "RLX", "DPX", "MINDX", "SPX", "ATX", "AWX", "ASXN", "AAX", "AUX", "AEX", "APX", "RPX", "RIGX", "MSHX"]


def inst_chunk_payload(tid, class_name, is_s, refs):
    return struct.pack("<I", tid) + s(class_name) + struct.pack("<B", is_s) + struct.pack("<I", len(refs)) + referent_array_enc(refs)


def prop_string_payload(tid, pname, values):
    out = struct.pack("<I", tid) + s(pname) + b"\x01"
    for v in values:
        raw = v.encode("utf-8")
        out += struct.pack("<I", len(raw)) + raw
    return out


def main():
    inp, outp = sys.argv[1], sys.argv[2]
    data = open(inp, "rb").read()
    version, num_types, num_instances, hdr_end = read_header(data)
    chunks = parse_chunks(data, hdr_end)
    type_by_id, refs_por_type, type_ids, name_por_ref = build_type_info(chunks)

    # ---------- referentes alvos ----------
    def ref_of(cls, name):
        for tid, refs in refs_por_type.items():
            if type_by_id[tid] != cls:
                continue
            for r in refs:
                if name_por_ref.get(r) == name:
                    return r
        sys.exit(f"nao achei {cls}:{name}")

    ref_sss = ref_of("ServerScriptService", "ServerScriptService")
    ref_srvstorage = ref_of("ServerStorage", "ServerStorage")
    ref_replicated = ref_of("ReplicatedStorage", "ReplicatedStorage")
    ref_screengui = ref_of("ScreenGui", "ArkherStudioUI")

    max_ref = max(name_por_ref.keys())
    max_tid = max(type_ids.values())

    # ---------- novas instancias (ordem -> referentes) ----------
    NODES = [
        ("Folder", "ArkherEngines", ref_srvstorage, None),
        ("Folder", "ArkherCloudVault", ref_srvstorage, None),
        *[( "ModuleScript", "ArkherX_" + m, 0, m) for m in ENGINE_MODULES],  # parent patched depois
        ("ModuleScript", "ArkherServices", 0, "__services__"),
        ("Script", "ArkherEngineServer", ref_sss, os.path.join(ROOT, "scripts", "engine_server.lua")),
        ("Folder", "ArkherNet", ref_replicated, None),
        ("RemoteEvent", "ArkherXCmd", 0, None),      # parent patched depois
        ("RemoteFunction", "ArkherXQ", 0, None),     # parent patched depois
        ("LocalScript", "Arkher_08_RealityX", ref_screengui, os.path.join(ROOT, "scripts", "08_RealityX.lua")),
        ("LocalScript", "Arkher_09_Topbar", ref_screengui, os.path.join(ROOT, "scripts", "09_Topbar.lua")),
    ]
    # pais dos filhos de folder (Folder referencia ai nao conhecida ainda — resolvemos na 1a passada)
    ref_map = {}
    next_ref = max_ref + 1
    for cls, nm, parent, src in NODES:
        ref_map[nm] = next_ref
        next_ref += 1
    NODES = list(NODES)
    for i, (cls, nm, parent, src) in enumerate(NODES):
        if cls == "ModuleScript" and src == "__services__":
            NODES[i] = (cls, nm, ref_map["ArkherCloudVault"], src)
        elif cls in ("ModuleScript",):
            NODES[i] = (cls, nm, ref_map["ArkherEngines"], src)
        elif cls in ("RemoteEvent", "RemoteFunction"):
            NODES[i] = (cls, nm, ref_map["ArkherNet"], src)

    # ---------- agrupa novos por classe ----------
    new_by_class = {}
    for cls, nm, parent, src in NODES:
        new_by_class.setdefault(cls, []).append((nm, parent, src))

    new_chunks = []  # (name, payload)
    updated_chunks = {}  # indice -> payload novo

    # ---------- INST chunks ----------
    for cls, items in new_by_class.items():
        refs = [ref_map[nm] for nm, _, _ in items]
        if cls in type_ids:
            tid = type_ids[cls]
            # encontra o INST original e re-emite com refs anexados
            for idx, (cname, payload) in enumerate(chunks):
                if cname != b"INST":
                    continue
                cr = pyrbxl2.R(payload)
                otid = cr.u32(); tname = cr.string(); is_s = cr.u8(); cnt = cr.u32()
                if otid == tid and tname == cls:
                    old_refs = cr.referent_array(cnt)
                    updated_chunks[idx] = inst_chunk_payload(tid, cls, is_s, old_refs + refs)
                    break
            else:
                sys.exit(f"INST da classe existente nao achada: {cls}")
        else:
            tid = max_tid + 1
            max_tid += 1
            type_ids[cls] = tid
            new_chunks.append((b"INST", inst_chunk_payload(tid, cls, 0, refs)))

    # ---------- PROP Name ============
    # classes existentes: estende chunk PROP Name original; novas: novo chunk
    for cls, items in new_by_class.items():
        tid = type_ids[cls]
        names = [nm for nm, _, _ in items]
        if cls in ("Folder", "ModuleScript", "RemoteEvent", "RemoteFunction"):
            # tipos novos: Name completo so das novas
            new_chunks.append((b"PROP", prop_string_payload(tid, "Name", names)))
        else:
            for idx, (cname, payload) in enumerate(chunks):
                if cname != b"PROP":
                    continue
                cr = pyrbxl2.R(payload)
                ptid = cr.u32(); pname = cr.string(); t = cr.u8()
                if ptid == tid and pname == "Name" and t == 1:
                    orig = []
                    while cr.i < len(cr.d):
                        n = cr.u32(); orig.append(cr.take(n).decode("utf-8", "replace"))
                    updated_chunks[idx] = prop_string_payload(tid, "Name", orig + names)
                    break
            else:
                new_chunks.append((b"PROP", prop_string_payload(tid, "Name", names)))

    # ---------- PROP Source (scripts) ----------
    for cls, items in new_by_class.items():
        tid = type_ids[cls]
        srcs = []
        for nm, _, src in items:
            if src is None:
                continue
            if cls == "ModuleScript":
                if src == "__services__":
                    f = os.path.join(ROOT, "scripts", "modules", "arkher_services.lua")
                else:
                    f = os.path.join(V3_CORE, {
                        "DM": "dmath", "THX": "theoryx", "WLDX": "worldx", "RRX": "realityx",
                        "FABX": "fabx",
                        "DAYX": "dayx", "ECOX": "ecox", "WEAX": "weax", "CIVIX": "civix",
                        "SECX": "secx", "PHYSX": "physx",
                        "RLX": "rlayer", "DPX": "dpred", "MINDX": "mindx",
                        "SPX": "spacex",
                        "ATX": "terrainx", "AWX": "waterx", "ASXN": "scenex",
                        "AAX": "animx", "AUX": "audiomix", "AEX": "atmosx", "APX": "particlesx",
                        "RPX": "ropex", "RIGX": "rigx", "MSHX": "meshx",
                    }[src] + ".luau")
            else:
                f = src
            srcs.append(open(f, encoding="utf-8").read())
        if not srcs:
            continue
        # classes novas: chunk novo; existentes: estende
        if cls in ("Folder", "RemoteEvent", "RemoteFunction"):
            continue
        if cls == "ModuleScript":
            new_chunks.append((b"PROP", prop_string_payload(tid, "Source", srcs)))
        else:
            found = False
            for idx, (cname, payload) in enumerate(chunks):
                if cname != b"PROP":
                    continue
                cr = pyrbxl2.R(payload); ptid = cr.u32(); pname = cr.string(); ttt = cr.u8()
                if ptid == tid and pname == "Source":
                    orig = []
                    while cr.i < len(cr.d):
                        n = cr.u32(); orig.append(cr.take(n).decode("utf-8", "replace"))
                    updated_chunks[idx] = prop_string_payload(tid, "Source", orig + srcs)
                    found = True
                    break
            if not found:
                new_chunks.append((b"PROP", prop_string_payload(tid, "Source", srcs)))

    # ---------- PROP genericos de tipos ESTENDIDOS (Disabled etc.) ----------
    # REGRA CRITICA: qualquer chunk PROP cujo type_id teve instancias anexadas
    # precisa receber 1 valor default por instancia nova — senao o Studio le
    # valores alem do fim do chunk (erro "offset out of bounds" / bool 4/5).
    SCALAR_SIZE = {  # bytes por valor (zeros sao default seguro p/ interleave)
        0x01: 4,    # string vazia (u32 len=0)
        0x02: 1,    # bool false
        0x03: 4,    # int32 0
        0x04: 4,    # float 0.0
        0x05: 8,    # double 0.0
        0x06: 8,    # UDim 0,0
        0x07: 16,   # UDim2
        0x0C: 12,   # Color3 preto
        0x0E: 8,    # Vector2
        0x0F: 12,   # Vector3
        0x13: 4,    # enum/int categ.
        0x1E: 8,    # UDim (alt)
    }
    for cls, items in new_by_class.items():
        if cls not in ("Script", "LocalScript"):
            continue  # so essas classes PRE-existiam com outros PROPs
        tid = type_ids[cls]
        for idx, (cname, payload) in enumerate(chunks):
            if cname != b"PROP" or idx in updated_chunks:
                continue
            cr = pyrbxl2.R(payload)
            ptid = cr.u32(); pname = cr.string(); tc = cr.u8()
            if ptid != tid:
                continue
            if pname in ("Name", "Source"):
                continue  # ja estendidos acima com valores REAIS
            sz = SCALAR_SIZE.get(tc)
            if sz is None:
                sys.exit(f"tipo de PROP desconhecido p/ extensao: {cls}.{pname} tc=0x{tc:02x}")
            updated_chunks[idx] = payload + (b"\x00" * sz) * len(items)

    # ---------- PRNT: anexa pares (subject=novo, parent=dest) ----------
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PRNT":
            continue
        pr = pyrbxl2.R(payload)
        ver = pr.u8(); cnt = pr.u32()
        subs = pr.referent_array(cnt)
        pars = pr.referent_array(cnt)
        for cls, items in new_by_class.items():
            for nm, parent, _ in items:
                subs.append(ref_map[nm])
                pars.append(parent)
        newp = struct.pack("<B", ver) + struct.pack("<I", len(subs)) + referent_array_enc(subs) + referent_array_enc(pars)
        updated_chunks[idx] = newp
        break

    # ---------- re-emite arquivo ----------
    out = bytearray(MAGIC)
    out += struct.pack("<H", version)
    num_types = num_types + len([c for c in new_by_class if c not in ("Script", "LocalScript")])
    out += struct.pack("<I", num_types)
    out += struct.pack("<I", num_instances + len(NODES) + 0)
    out += b"\x00" * 8
    for idx, (cname, payload) in enumerate(chunks):
        if cname.startswith(b"END"):
            continue  # re-emite por ultimo (spec: END termina o arquivo)
        if cname == b"PRNT":
            # CRITICO: os INST/PROP novos TEM que vir ANTES do PRNT — o loader
            # do Studio so aplica parentesco de instancias JA declaradas.
            # Se PRNT chega antes, os filhos novos caem no limbo (sumiam!).
            for nc, npay in new_chunks:
                out += chunk_out(nc, npay)
            new_chunks = []
            out += chunk_out(cname, updated_chunks.get(idx, payload))
            continue
        if idx in updated_chunks:
            out += chunk_out(cname, updated_chunks[idx])
        else:
            out += chunk_out(cname, payload)
    for cname, payload in new_chunks:  # fallback (sem PRNT no arquivo)
        out += chunk_out(cname, payload)
    end_payload = next((p for n, p in chunks if n.startswith(b"END")), b"\x00</roblox>")
    out += chunk_out(b"END\x00", end_payload)

    open(outp, "wb").write(bytes(out))
    print(f"arquivo: {outp} ({len(out)} bytes, +{len(NODES)} instancias)")

    # ---------- validacao ----------
    m2 = pyrbxl2.parse(bytes(out))
    assert m2.num_instances == num_instances + len(NODES), (m2.num_instances, num_instances, len(NODES))
    pairs2 = [(c[0], c[1]) for c in m2.chunks]
    t2_b, r2_b, ti2, np2 = build_type_info(pairs2)
    want = {nm: cls for cls, nm, _, _ in NODES}
    for nm, cls in want.items():
        tid = ti2.get(cls)
        assert tid is not None, f"classe inexistente: {cls}"
        hits = [r for r in r2_b.get(tid, []) if np2.get(r) == nm]
        assert hits, f"faltou {cls}:{nm}"
    # PRNT: cada ref novo bate com o pai esperado
    pl = next(c[1] for c in m2.chunks if c[0] == b"PRNT")
    pr = pyrbxl2.R(pl)
    pr.u8(); cnt = pr.u32()
    subs = pr.referent_array(cnt)
    pars = pr.referent_array(cnt)
    want_par = {ref_map[nm]: parent for cls, nm, parent, _ in NODES}
    for sref, pref in zip(subs, pars):
        if sref in want_par:
            assert pref == want_par[sref], f"PRNT pai errado p/ ref {sref}: {pref} != {want_par[sref]}"
            del want_par[sref]
    assert not want_par, f"faltaram pares PRNT: {want_par}"

    # REGRA Studio: #valores por PROP == #instancias do tipo (senao OOB read)
    n_by_tid = {tid: len(refs) for tid, refs in r2_b.items()}
    SZ = {0x02: 1, 0x03: 4, 0x04: 4, 0x05: 8, 0x06: 8, 0x07: 16, 0x0C: 12,
          0x0E: 8, 0x0F: 12, 0x13: 4, 0x1E: 8, 0x09: 4, 0x1B: 4}
    # ORDEM: todo INST vem antes do PRNT (senao Studio descarta parentescos)
    seq = [c[0] for c in m2.chunks]
    prnt_pos = seq.index(b"PRNT")
    assert all(pos < prnt_pos for pos, cn in enumerate(seq) if cn != b"PRNT" and not cn.startswith(b"END") and cn == b"INST"), \
        "INST depois do PRNT — parentescos novos seriam descartados"
    assert seq[-1].startswith(b"END") and seq[-2] == b"PRNT", "layout final deve ser ...PRNT, END"

    nprops = 0
    for cname, payload in [(c[0], c[1]) for c in m2.chunks]:
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32(); pname = cr.string(); tc = cr.u8()
        wantn = n_by_tid.get(tid, 0)
        if tc == 0x01:  # strings: decodifica e conta
            vals = 0
            while cr.i < len(payload):
                n = cr.u32(); cr.take(n); vals += 1
            assert vals == wantn, f"PROP {t2_b.get(tid,'?')}.{pname}: {vals} valores p/ {wantn} inst"
        elif tc in SZ:
            rest = len(payload) - cr.i
            assert rest == SZ[tc] * wantn, (
                f"PROP {t2_b.get(tid,'?')}.{pname} tc=0x{tc:02x}: {rest}B p/ {wantn} inst "
                f"(esperado {SZ[tc]*wantn}B)")
        nprops += 1
    print(f"validacao OK: {m2.num_types} tipos, {m2.num_instances} instancias, "
          f"{len(NODES)} novas + PRNT + {nprops} PROP chunks checks #StudioSafe")
    return 0


if __name__ == "__main__":
    sys.exit(main())
