#!/usr/bin/env python3
"""Injeta a GUI X ESTÁTICA (tools/guix_spec.json) + LocalScripts 05/06/07 no .rbxl.

Aditivo e lossless p/ a UI original:
  * Canvas ganha 1 filho: Frame ArkherXDeck (host) com UIScale DeckScale=1.0.
  * Sob o host: 26 janelas Deck_* + ArkherXBar + ServerEditorPopups (2013 inst).
  * Chunks PROP existentes: decode + append (valores antigos preservados);
    chunks novos: old-fill = defaults do Studio / novos = spec.
  * LocalScripts Arkher_05/06/07 criados; Source dos 10 recarregada do disco.

Uso: inject_guix.py <in.rbxl> <out.rbxl>
"""
import json
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "studio-v3", "tools"))
import pyrbxl2
import rbxcodec
from patch_rbxl import read_header, parse_chunks, chunk_out, s, build_type_info
from make_rbxl import referent_array_enc

ROOT = os.path.dirname(HERE)
MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"

ENUMS = {
    "TextXAlignment": {"Left": 0, "Right": 1, "Center": 2},
    "TextYAlignment": {"Top": 0, "Center": 1, "Bottom": 2},
    "TextTruncate": {"None": 0, "AtEnd": 1},
    "AutomaticSize": {"None": 0, "X": 1, "Y": 2, "XY": 3},
    "ApplyStrokeMode": {"Contextual": 0, "Border": 1},
    "ScrollingDirection": {"X": 1, "Y": 2, "XY": 4},
}
FAM_GOTH = "rbxasset://fonts/families/GothamSSm.json"
FAM_SSP = "rbxasset://fonts/families/SourceSansPro.json"
FAM_ROBO = "rbxasset://fonts/families/RobotoMono.json"
FONTMAP = {"Font.GothamBold": (FAM_GOTH, 700), "Font.Gotham": (FAM_GOTH, 500),
           "Font.Code": (FAM_ROBO, 400)}


def enc_fontface(vals):
    out = b""
    for fam, w, tail in vals:
        raw = fam.encode("utf-8")
        out += struct.pack("<I", len(raw)) + raw + struct.pack("<H", w) + tail
    return out


def dec_fontface(buf, n):
    out = []
    o = 0
    for _ in range(n):
        (ln,) = struct.unpack("<I", buf[o:o + 4])
        o += 4
        fam = buf[o:o + ln].decode("utf-8")
        o += ln
        (w,) = struct.unpack("<H", buf[o:o + 2])
        o += 2
        tail = buf[o:o + 5]
        o += 5
        out.append((fam, w, tail))
    return out, o


def dec_strings(buf, n):
    out = []
    o = 0
    for _ in range(n):
        (ln,) = struct.unpack("<I", buf[o:o + 4])
        o += 4
        out.append(buf[o:o + ln])
        o += ln
    return out, o


def enc_strings(raws):
    out = b""
    for r in raws:
        out += struct.pack("<I", len(r)) + r
    return out


# ---------------- spec -> valores ----------------
def g(spec_props, key, default):
    return spec_props.get(key, default)


def as_u2(v):
    return (float(v[0]), int(round(v[1])), float(v[2]), int(round(v[3])))


def as_u1(v):
    return (float(v[0]), int(round(v[1])))


def as_c3(v):
    return (float(v[0]), float(v[1]), float(v[2]))


def as_v2(v):
    return (float(v[0]), float(v[1]))


def as_enum(v):
    typ, name = v.split(".")
    return ENUMS[typ][name]


def as_font(v):
    fam, w = FONTMAP[v]
    return (fam, w, b"\x00" * 5)


U2ZERO = (0.0, 0, 0.0, 0)
BLACK = (0.0, 0.0, 0.0)


def build_prop_values(cls, nodes):
    """Retorna {prop: (dtype, [novos valores python])} p/ a classe."""
    P = {}
    N = len(nodes)

    def col(key, conv, default):
        return [conv(n["props"][key]) if key in n["props"] else default for n in nodes]

    if cls == "Frame":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Position": (0x7, col("Position", lambda v: as_u2(v["u2"]), U2ZERO)),
            "Size": (0x7, [as_u2(n["props"]["Size"]["u2"]) for n in nodes]),
            "BackgroundColor3": (0xC, col("BackgroundColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "BackgroundTransparency": (0x4, col("BackgroundTransparency", float, 0.0)),
            "BorderSizePixel": (0x3, col("BorderSizePixel", int, 1)),
            "ZIndex": (0x3, col("ZIndex", int, 1)),
            "Rotation": (0x4, col("Rotation", float, 0.0)),
            "AnchorPoint": (0xD, col("AnchorPoint", lambda v: as_v2(v["v2"]), (0.0, 0.0))),
            "Active": (0x2, col("Active", bool, False)),
            "Selectable": (0x2, col("Selectable", bool, True)),
            "Visible": (0x2, col("Visible", bool, True)),
            "ClipsDescendants": (0x2, col("ClipsDescendants", bool, False)),
        }
    elif cls == "TextButton":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Position": (0x7, col("Position", lambda v: as_u2(v["u2"]), U2ZERO)),
            "Size": (0x7, [as_u2(n["props"]["Size"]["u2"]) for n in nodes]),
            "Text": (0x1, col("Text", str, "")),
            "BackgroundColor3": (0xC, col("BackgroundColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "BackgroundTransparency": (0x4, col("BackgroundTransparency", float, 0.0)),
            "BorderSizePixel": (0x3, col("BorderSizePixel", int, 1)),
            "ZIndex": (0x3, col("ZIndex", int, 1)),
            "Active": (0x2, col("Active", bool, False)),
            "AutoButtonColor": (0x2, col("AutoButtonColor", bool, True)),
            "Selectable": (0x2, col("Selectable", bool, True)),
            "AttributesSerialize": (0x1, [b""] * N),
            "LayoutOrder": (0x3, [0] * N),
            "FontFace": (0x20, col("Font", lambda v: as_font(v["en"]), (FAM_SSP, 400, b"\x00" * 5))),
            "TextSize": (0x4, col("TextSize", float, 14.0)),
            "TextColor3": (0xC, col("TextColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "TextXAlignment": (0x12, col("TextXAlignment", lambda v: as_enum(v["en"]), 2)),
        }
    elif cls == "TextLabel":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Position": (0x7, col("Position", lambda v: as_u2(v["u2"]), U2ZERO)),
            "Size": (0x7, [as_u2(n["props"]["Size"]["u2"]) for n in nodes]),
            "Text": (0x1, col("Text", str, "")),
            "BackgroundColor3": (0xC, col("BackgroundColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "BackgroundTransparency": (0x4, col("BackgroundTransparency", float, 0.0)),
            "BorderSizePixel": (0x3, col("BorderSizePixel", int, 1)),
            "ZIndex": (0x3, col("ZIndex", int, 1)),
            "FontFace": (0x20, col("Font", lambda v: as_font(v["en"]), (FAM_SSP, 400, b"\x00" * 5))),
            "TextSize": (0x4, col("TextSize", float, 14.0)),
            "TextColor3": (0xC, col("TextColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "TextWrapped": (0x2, col("TextWrapped", bool, False)),
            "TextXAlignment": (0x12, col("TextXAlignment", lambda v: as_enum(v["en"]), 2)),
            "TextYAlignment": (0x12, col("TextYAlignment", lambda v: as_enum(v["en"]), 1)),
            "Active": (0x2, col("Active", bool, False)),
            "Selectable": (0x2, col("Selectable", bool, True)),
            "TextTruncate": (0x12, col("TextTruncate", lambda v: as_enum(v["en"]), 0)),
            "ClipsDescendants": (0x2, col("ClipsDescendants", bool, False)),
        }
    elif cls == "TextBox":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Position": (0x7, col("Position", lambda v: as_u2(v["u2"]), U2ZERO)),
            "Size": (0x7, [as_u2(n["props"]["Size"]["u2"]) for n in nodes]),
            "Text": (0x1, col("Text", str, "")),
            "BackgroundColor3": (0xC, col("BackgroundColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "BackgroundTransparency": (0x4, col("BackgroundTransparency", float, 0.0)),
            "BorderSizePixel": (0x3, col("BorderSizePixel", int, 1)),
            "ZIndex": (0x3, col("ZIndex", int, 1)),
            "Active": (0x2, col("Active", bool, False)),
            "Selectable": (0x2, col("Selectable", bool, True)),
            "ClearTextOnFocus": (0x2, col("ClearTextOnFocus", bool, True)),
            "FontFace": (0x20, col("Font", lambda v: as_font(v["en"]), (FAM_SSP, 400, b"\x00" * 5))),
            "PlaceholderColor3": (0xC, col("PlaceholderColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "PlaceholderText": (0x1, col("PlaceholderText", str, "")),
            "TextColor3": (0xC, col("TextColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "TextSize": (0x4, col("TextSize", float, 14.0)),
            "TextXAlignment": (0x12, col("TextXAlignment", lambda v: as_enum(v["en"]), 0)),
            "MultiLine": (0x2, col("MultiLine", bool, False)),
            "TextYAlignment": (0x12, col("TextYAlignment", lambda v: as_enum(v["en"]), 1)),
        }
    elif cls == "ScrollingFrame":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Position": (0x7, col("Position", lambda v: as_u2(v["u2"]), U2ZERO)),
            "Size": (0x7, [as_u2(n["props"]["Size"]["u2"]) for n in nodes]),
            "Active": (0x2, [False] * N),
            "BackgroundColor3": (0xC, col("BackgroundColor3", lambda v: as_c3(v["c3"]), BLACK)),
            "BackgroundTransparency": (0x4, col("BackgroundTransparency", float, 0.0)),
            "BorderSizePixel": (0x3, col("BorderSizePixel", int, 1)),
            "CanvasSize": (0x7, [as_u2(n["props"]["CanvasSize"]["u2"]) for n in nodes]),
            "ClipsDescendants": (0x2, [True] * N),
            "ScrollBarImageColor3": (0xC, [as_c3(n["props"]["ScrollBarImageColor3"]["c3"]) for n in nodes]),
            "ScrollBarThickness": (0x3, [int(n["props"]["ScrollBarThickness"]) for n in nodes]),
            "ScrollingDirection": (0x12, [4] * N),
            "Selectable": (0x2, [True] * N),
            "ZIndex": (0x3, col("ZIndex", int, 1)),
            "AutomaticCanvasSize": (0x12, col("AutomaticCanvasSize", lambda v: as_enum(v["en"]), 0)),
        }
    elif cls == "UICorner":
        radii = [as_u1(n["props"]["CornerRadius"]["u1"]) for n in nodes]
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "TopLeftRadius": (0x6, list(radii)),
            "TopRightRadius": (0x6, list(radii)),
            "BottomLeftRadius": (0x6, list(radii)),
            "BottomRightRadius": (0x6, list(radii)),
        }
    elif cls == "UIStroke":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "ApplyStrokeMode": (0x12, [as_enum(n["props"]["ApplyStrokeMode"]["en"]) for n in nodes]),
            "Color": (0xC, [as_c3(n["props"]["Color"]["c3"]) for n in nodes]),
            "Thickness": (0x4, [float(n["props"]["Thickness"]) for n in nodes]),
            "Transparency": (0x4, [0.0] * N),
        }
    elif cls == "UIScale":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Scale": (0x4, [float(n["props"].get("Scale", 1.0)) for n in nodes]),
        }
    elif cls == "UIPadding":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "PaddingLeft": (0x6, col("PaddingLeft", lambda v: as_u1(v["u1"]), (0.0, 0))),
            "PaddingRight": (0x6, col("PaddingRight", lambda v: as_u1(v["u1"]), (0.0, 0))),
            "PaddingTop": (0x6, col("PaddingTop", lambda v: as_u1(v["u1"]), (0.0, 0))),
        }
    elif cls == "UIListLayout":
        P = {
            "Name": (0x1, [n["name"] for n in nodes]),
            "Padding": (0x6, [as_u1(n["props"]["Padding"]["u1"]) for n in nodes]),
        }
    else:
        sys.exit(f"classe nao planejada: {cls}")
    return P


# old-fill p/ chunks NOVOS em classes existentes: {cls: {prop: valor}}
OLDFILL = {
    "Frame": {"Visible": True, "ClipsDescendants": False},
    "TextButton": {"FontFace": (FAM_SSP, 400, b"\x00" * 5), "TextSize": 14.0,
                   "TextColor3": BLACK, "TextXAlignment": 2},
    "TextLabel": {"TextTruncate": 0, "ClipsDescendants": False},
    "TextBox": {"MultiLine": False, "TextYAlignment": 1},
    "ScrollingFrame": {"AutomaticCanvasSize": 0},
}


def main():
    inp, outp = sys.argv[1], sys.argv[2]
    spec = json.load(open(os.path.join(HERE, "guix_spec.json"), encoding="utf-8"))
    data = open(inp, "rb").read()
    version, num_types, num_instances, hdr_end = read_header(data)
    chunks = parse_chunks(data, hdr_end)
    type_by_id, refs_por_type, type_ids, name_por_ref = build_type_info(chunks)

    def ref_of(cls, name):
        for tid, refs in refs_por_type.items():
            if type_by_id[tid] != cls:
                continue
            for r in refs:
                if name_por_ref.get(r) == name:
                    return r
        sys.exit(f"nao achei {cls}:{name}")

    ref_canvas = ref_of("Frame", "Canvas")
    ref_screengui = ref_of("ScreenGui", "ArkherStudioUI")
    print(f"Canvas ref={ref_canvas} ScreenGui ref={ref_screengui}")

    # ---------- flatten da spec (ordem depth-first estável) ----------
    host = {"cls": "Frame", "name": "ArkherXDeck", "props": {
        "Size": {"u2": [1.0, 0, 1.0, 0]}, "BackgroundTransparency": 1.0,
        "BorderSizePixel": 0, "ZIndex": 50, "Active": False, "Selectable": False,
        "Visible": True, "ClipsDescendants": False}, "kids": []}
    host_scale = {"cls": "UIScale", "name": "DeckScale",
                  "props": {"Scale": float(spec.get("host_scale", 1.0))}, "kids": []}
    roots = [host]
    host["kids"] = spec["deck"] + spec["extra"] + spec["shell"] + [spec["popups"]] + spec["v2"]
    ordered = []  # (nó, ref-pai-ou-None, é-host?)

    def walk(n, parent):
        ordered.append((n, parent))
        for k in n["kids"]:
            walk(k, n)

    walk(host, "CANVAS")
    ordered.append((host_scale, host))
    # Container canvas-level p/ dropdowns/dialogs do 03_Menus + paineis do 10:
    # sem ele o 03 trava em WaitForChild("ServerEditorPopups"). ZIndex=500 p/
    # ficar ACIMA do host (50): menus/dialogs sempre clicaveis. (Nao confundir
    # com o ServerEditorPopups filho do host, que guarda o popup de formas.)
    canvas_popups = {"cls": "Frame", "name": "ServerEditorPopups", "props": {
        "Size": {"u2": [1.0, 0, 1.0, 0]}, "BackgroundTransparency": 1.0,
        "BorderSizePixel": 0, "ZIndex": 500, "Active": False, "Selectable": False,
        "Visible": True, "ClipsDescendants": False}, "kids": []}
    ordered.append((canvas_popups, "CANVAS"))
    new_by_class = {}
    for n, _ in ordered:
        new_by_class.setdefault(n["cls"], []).append(n)
    print("novos por classe:", {c: len(v) for c, v in sorted(new_by_class.items())})

    max_ref = max(name_por_ref.keys())
    max_tid = max(type_ids.values())
    ref_of_node = {}
    next_ref = max_ref + 1
    for n, _ in ordered:
        ref_of_node[id(n)] = next_ref
        next_ref += 1

    def parent_ref(n, parent):
        if parent == "CANVAS":
            return ref_canvas
        return ref_of_node[id(parent)]

    want_par = {}
    for n, parent in ordered:
        want_par[ref_of_node[id(n)]] = parent_ref(n, parent)

    new_chunks = []
    updated_chunks = {}

    def inst_payload(tid, cls, is_s, refs):
        return struct.pack("<I", tid) + s(cls) + struct.pack("<B", is_s) + struct.pack("<I", len(refs)) + referent_array_enc(refs)

    def prop_head(tid, pname, dtype):
        return struct.pack("<I", tid) + s(pname) + struct.pack("<B", dtype)

    # ---------- INST ----------
    for cls, nodes in new_by_class.items():
        refs = [ref_of_node[id(n)] for n in nodes]
        if cls in type_ids:
            tid = type_ids[cls]
            for idx, (cname, payload) in enumerate(chunks):
                if cname != b"INST":
                    continue
                cr = pyrbxl2.R(payload)
                otid = cr.u32()
                tname = cr.string()
                is_s = cr.u8()
                cnt = cr.u32()
                if otid == tid and tname == cls:
                    old_refs = cr.referent_array(cnt)
                    updated_chunks[idx] = inst_payload(tid, cls, is_s, old_refs + refs)
                    break
            else:
                sys.exit(f"INST inexistente: {cls}")
        else:
            max_tid += 1
            tid = max_tid
            type_ids[cls] = tid
            new_chunks.append((b"INST", inst_payload(tid, cls, 0, refs)))

    # ---------- PROP (decode velho + append tipado) ----------
    prop_index = {}  # (tid, pname) -> (idx, payload, dtype)
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        ptid = cr.u32()
        pname = cr.string()
        dt = cr.u8()
        prop_index[(ptid, pname)] = (idx, payload, dt)

    for cls, nodes in new_by_class.items():
        tid = type_ids[cls]
        plan = build_prop_values(cls, nodes)
        for pname, (dtype, new_vals) in plan.items():
            if (tid, pname) in prop_index:
                idx, payload, dt = prop_index[(tid, pname)]
                assert dt == dtype, f"dtype mudou: {cls}.{pname} {hex(dt)} != {hex(dtype)}"
                cr = pyrbxl2.R(payload)
                cr.u32()
                cr.string()
                cr.u8()
                body = payload[cr.i:]
                n_old = len(refs_por_type[tid])
                if dtype == 0x1:
                    if pname == "AttributesSerialize":
                        old_vals, _ = dec_strings(body, n_old)
                        new_raws = [v if isinstance(v, bytes) else v.encode("utf-8") for v in new_vals]
                        new_body = enc_strings(old_vals + new_raws)
                    else:
                        old_vals, _ = dec_strings(body, n_old)
                        new_raws = [v.encode("utf-8") if isinstance(v, str) else v for v in new_vals]
                        new_body = enc_strings(old_vals + new_raws)
                elif dtype == 0x20:
                    old_vals, _ = dec_fontface(body, n_old)
                    new_body = enc_fontface(old_vals + new_vals)
                else:
                    old_vals = rbxcodec.decode(dtype, body, n_old)
                    new_body = rbxcodec.encode(dtype, old_vals + new_vals)
                updated_chunks[idx] = prop_head(tid, pname, dtype) + new_body
            else:
                # chunk NOVO: old-fill + novos (tipos novos: n_old=0, sem fill)
                n_old = len(refs_por_type.get(tid, []))
                fill = OLDFILL.get(cls, {}).get(pname, None)
                if fill is None and n_old > 0:
                    sys.exit(f"sem old-fill: {cls}.{pname}")
                if dtype == 0x20:
                    body = enc_fontface([fill] * n_old + new_vals if n_old else new_vals)
                elif dtype == 0x1:
                    olds = [fill.encode("utf-8")] * n_old if n_old else []
                    body = enc_strings(olds + [v.encode("utf-8") for v in new_vals])
                else:
                    body = rbxcodec.encode(dtype, [fill] * n_old + new_vals if n_old else new_vals)
                new_chunks.append((b"PROP", prop_head(tid, pname, dtype) + body))

    print(f"INST estendidos/novos ok; PROP updated={len(updated_chunks)} novos={len(new_chunks)}")

    # ---------- LocalScripts 05/06/07 + refresh de Source ----------
    LS_FILES = {
        "Arkher_01_Nucleo": "01_Nucleo.lua", "Arkher_02_Icones": "02_Icones.orig.lua",
        "Arkher_03_Menus": "03_Menus.lua", "Arkher_04_Gizmos": "04_Gizmos.orig.lua",
        "Arkher_05_StudioX": "05_StudioX.lua", "Arkher_06_RigX": "06_RigX.lua",
        "Arkher_07_MeshX": "07_MeshX.lua", "Arkher_08_RealityX": "08_RealityX.lua",
        "Arkher_09_Topbar": "09_Topbar.lua", "Arkher_10_Studio": "10_Studio.lua",
    }
    ls_tid = type_ids["LocalScript"]
    # nomes atuais (ordem do INST)
    ls_names = []
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        if cr.u32() == ls_tid and cr.string() == "Name" and cr.u8() == 1:
            vals, _ = dec_strings(payload[cr.i:], len(refs_por_type[ls_tid]))
            ls_names = [v.decode("utf-8", "replace") for v in vals]
            ls_name_idx = idx
            break
    missing = [nm for nm in LS_FILES if nm not in ls_names]
    print("LocalScripts atuais:", ls_names)
    print("faltando:", missing)
    for nm in missing:
        r = next_ref
        next_ref += 1
        want_par[r] = ref_screengui
        refs_por_type[ls_tid].append(r)
        ls_names.append(nm)
    # re-emite INST LocalScript
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"INST":
            continue
        cr = pyrbxl2.R(payload)
        if cr.u32() == ls_tid and cr.string() == "LocalScript":
            is_s = cr.u8()
            cnt = cr.u32()
            old_refs = cr.referent_array(cnt)
            add = refs_por_type[ls_tid][len(old_refs):]
            if add:
                updated_chunks[idx] = inst_payload(ls_tid, "LocalScript", is_s, old_refs + add)
            break
    # Name
    updated_chunks[ls_name_idx] = prop_head(ls_tid, "Name", 1) + enc_strings(
        [v.encode("utf-8", "replace") for v in ls_names])
    # Source (do disco; sem arquivo -> preserva antiga)
    old_srcs = {}
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        if cr.u32() == ls_tid and cr.string() == "Source" and cr.u8() == 1:
            n_prev = len(refs_por_type[ls_tid]) - len(missing)
            vals, _ = dec_strings(payload[cr.i:], n_prev)
            prev_names = ls_names[:n_prev]
            old_srcs = dict(zip(prev_names, vals))
            ls_src_idx = idx
            break
    srcs = []
    for nm in ls_names:
        f = os.path.join(ROOT, "scripts", LS_FILES.get(nm, ""))
        if LS_FILES.get(nm) and os.path.exists(f):
            srcs.append(open(f, encoding="utf-8").read().encode("utf-8"))
        else:
            srcs.append(old_srcs.get(nm, b""))
    updated_chunks[ls_src_idx] = prop_head(ls_tid, "Source", 1) + enc_strings(srcs)
    # Disabled (preserva + false p/ novos)
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        if cr.u32() == ls_tid and cr.string() == "Disabled" and cr.u8() == 2:
            body = payload[cr.i:]
            n_prev = len(refs_por_type[ls_tid]) - len(missing)
            old = rbxcodec.decode(2, body, n_prev)
            updated_chunks[idx] = prop_head(ls_tid, "Disabled", 2) + rbxcodec.encode(2, old + [False] * len(missing))
            break

    # ---------- PRNT ----------
    for idx, (cname, payload) in enumerate(chunks):
        if cname != b"PRNT":
            continue
        pr = pyrbxl2.R(payload)
        ver = pr.u8()
        cnt = pr.u32()
        subs = pr.referent_array(cnt)
        pars = pr.referent_array(cnt)
        for sref, pref in want_par.items():
            subs.append(sref)
            pars.append(pref)
        updated_chunks[idx] = struct.pack("<B", ver) + struct.pack("<I", len(subs)) + referent_array_enc(subs) + referent_array_enc(pars)
        break

    # ---------- re-emite ----------
    out = bytearray(MAGIC)
    out += struct.pack("<H", version)
    n_new_types = sum(1 for c in new_by_class if c in ("UIPadding", "UIListLayout"))
    out += struct.pack("<I", num_types + n_new_types)
    total_new = len(ordered) + len(missing)
    out += struct.pack("<I", num_instances + total_new)
    out += b"\x00" * 8
    for idx, (cname, payload) in enumerate(chunks):
        if cname.startswith(b"END"):
            continue
        if cname == b"PRNT":
            for nc, npay in new_chunks:
                out += chunk_out(nc, npay)
            new_chunks = []
            out += chunk_out(cname, updated_chunks.get(idx, payload))
            continue
        if idx in updated_chunks:
            out += chunk_out(cname, updated_chunks[idx])
        else:
            out += chunk_out(cname, payload)
    for cname, payload in new_chunks:
        out += chunk_out(cname, payload)
    end_payload = next((p for n, p in chunks if n.startswith(b"END")), b"\x00</roblox>")
    out += chunk_out(b"END\x00", end_payload)
    open(outp, "wb").write(bytes(out))
    print(f"arquivo: {outp} ({len(out)} bytes, +{total_new} instancias)")

    # ---------- validacao StudioSafe ----------
    m2 = pyrbxl2.parse(bytes(out))
    assert m2.num_instances == num_instances + total_new
    assert m2.num_types == num_types + n_new_types
    pairs2 = [(c[0], c[1]) for c in m2.chunks]
    t2_b, r2_b, ti2, np2 = build_type_info(pairs2)
    # todas as novas existem por nome+classe
    for cls, nodes in new_by_class.items():
        tid = ti2[cls]
        have = Counter2([np2.get(r) for r in r2_b[tid]])
        for n in nodes:
            assert have.get(n["name"], 0) > 0, f"faltou {cls}:{n['name']}"
            have[n["name"]] -= 1
    # PRNT pares
    pl = next(c[1] for c in m2.chunks if c[0] == b"PRNT")
    pr = pyrbxl2.R(pl)
    pr.u8()
    cnt = pr.u32()
    subs = pr.referent_array(cnt)
    pars = pr.referent_array(cnt)
    rem = dict(want_par)
    for sref, pref in zip(subs, pars):
        if sref in rem:
            assert pref == rem[sref], f"PRNT pai errado p/ {sref}"
            del rem[sref]
    assert not rem, f"faltaram pares PRNT: {len(rem)}"
    # PROP sizes
    SZ = {0x02: 1, 0x03: 4, 0x04: 4, 0x06: 8, 0x07: 16, 0x0C: 12, 0x0D: 8,
          0x12: 4, 0x18: 16, 0x0B: 4}
    n_by_tid = {tid: len(refs) for tid, refs in r2_b.items()}
    for cname, payload in pairs2:
        if cname != b"PROP":
            continue
        cr = pyrbxl2.R(payload)
        tid = cr.u32()
        pname = cr.string()
        tc = cr.u8()
        wantn = n_by_tid[tid]
        if tc == 0x01:
            vals = 0
            while cr.i < len(payload):
                n = cr.u32()
                cr.take(n)
                vals += 1
            assert vals == wantn, f"PROP {t2_b[tid]}.{pname}: {vals}!={wantn}"
        elif tc == 0x20:
            vals, o = dec_fontface(payload[cr.i:], wantn)
            assert o == len(payload) - cr.i, f"FontFace {t2_b[tid]}.{pname} sobra bytes"
        elif tc in SZ:
            rest = len(payload) - cr.i
            assert rest == SZ[tc] * wantn, f"PROP {t2_b[tid]}.{pname}: {rest}B"
    # valores antigos byte-idênticos (prefixo de cada PROP estendido)
    for (tid, pname), (idx, payload, dt) in prop_index.items():
        if idx not in updated_chunks:
            continue
        if (type_by_id[tid], pname) == ("LocalScript", "Source"):
            continue  # refresh intencional
        if type_by_id[tid] == "LocalScript" and pname == "Name" and missing:
            continue  # nomes anexados
        old_cr = pyrbxl2.R(payload)
        old_cr.u32()
        old_cr.string()
        old_cr.u8()
        old_body = payload[old_cr.i:]
        new_pay = updated_chunks[idx]
        new_cr = pyrbxl2.R(new_pay)
        new_cr.u32()
        new_cr.string()
        new_cr.u8()
        new_body = new_pay[new_cr.i:]
        if dt in (0x2, 0x3, 0x4, 0x6, 0x7, 0xC, 0xD, 0x12):
            # refs_por_type só foi estendido p/ LocalScript; GUI classes têm só old refs
            n_old = len(refs_por_type[tid]) - (len(missing) if type_by_id[tid] == "LocalScript" else 0)
            # interleave: decodifica o array novo INTEIRO e compara o prefixo lógico
            n_new = n_old + len(new_by_class.get(type_by_id[tid], []))
            full = rbxcodec.decode(dt, new_body, n_new)
            assert full[:n_old] == rbxcodec.decode(dt, old_body, n_old), \
                f"valores antigos mudaram: {type_by_id[tid]}.{pname}"
        else:
            assert new_body[:len(old_body)] == old_body, f"prefixo mudou: {type_by_id[tid]}.{pname}"
    print(f"validacao OK: {m2.num_types} tipos, {m2.num_instances} instancias, "
          f"{total_new} novas + PRNT + StudioSafe")


class Counter2(dict):
    def __init__(self, it):
        for x in it:
            self[x] = self.get(x, 0) + 1


if __name__ == "__main__":
    sys.exit(main())
