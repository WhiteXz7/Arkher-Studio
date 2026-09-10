#!/usr/bin/env python3
"""Extrai a UI original do V2 (StarterGui.ARKHER_Studio) do .rbxl para
/tmp/v2ui.json — mesmo formato do dump_v3_uis.py (c/n/p + props)."""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pyrbxl2
import rbxcodec  # noqa: F401

RBXL = os.path.join(os.path.dirname(HERE), "commandbar", "arkher-v3.rbxl")


def _tag(t):
    return {3: "Int32", 4: "Float32", 6: "UDim", 7: "UDim2", 12: "Color3",
            13: "Vector2", 14: "Vector3", 18: "Enum", 11: "BrickColor"}.get(t, str(t))


def main():
    m = pyrbxl2.parse(open(RBXL, "rb").read())
    N = m.num_instances
    cls, name = {}, {}
    ib = {}
    for n, p, ps in m.chunks:
        if n == b"INST" and ps:
            ib[ps[0]] = ps[3]
            for r in ps[3]:
                cls[r] = ps[1]
    props_by_ref = {}
    for n, p, ps in m.chunks:
        if n != b"PROP":
            continue
        cr = pyrbxl2.R(p)
        tid = cr.u32()
        pname = cr.string()  # ja str
        t = cr.u8()
        refs = ib[tid]
        if t == 1:
            buf = cr.take(len(p) - cr.i)
            off = 0
            for r in refs:
                ln = int.from_bytes(buf[off:off + 4], "little")
                b = buf[off + 4:off + 4 + ln]
                off += 4 + ln
                if pname == "Name":
                    name[r] = b.decode()
                else:
                    props_by_ref.setdefault(r, []).append([pname, b.decode()])
        elif t == 2:
            buf = cr.take(len(p) - cr.i)
            for r, b in zip(refs, buf):
                props_by_ref.setdefault(r, []).append([pname, b != 0])
        else:
            buf = cr.take(len(p) - cr.i)
            vals = rbxcodec.decode(t, buf, len(refs))
            for r, v in zip(refs, vals):
                props_by_ref.setdefault(r, []).append([pname, {"__t": _tag(t), "v": _val(t, v)}])

    prnt = next(ps for n, p, ps in m.chunks if n == b"PRNT" and ps)
    parent = dict(zip(prnt[1], prnt[2]))
    kids = {}
    for r, p in parent.items():
        kids.setdefault(p, []).append(r)

    # achar StarterGui (service) -> ARKHER_Studio
    sv = None
    for r in range(N):
        if cls.get(r) == "StarterGui":
            sv = r
            break
    assert sv is not None, "StarterGui nao encontrado"
    root = None
    for c in kids.get(sv, []):
        if name.get(c) == "ARKHER_Studio":
            root = c
            break
    assert root is not None, "ARKHER_Studio nao encontrado"

    names, classes = [], []
    nmap, cmap = {}, {}
    out = []

    def idx(arr, m, v):
        if v not in m:
            m[v] = len(arr) + 1
            arr.append(v)
        return m[v]

    def dump(inst, pi):
        i = len(out) + 1
        c = idx(classes, cmap, cls[inst])
        nm = idx(names, nmap, name.get(inst, ""))
        out.append({"c": c, "n": nm, "p": pi, "props": []})
        for ch in sorted(kids.get(inst, []), key=lambda x: name.get(x, "")):
            dump(ch, i)
        for k, v in props_by_ref.get(inst, []):
            if k in ("Name", "ClassName", "Source"):
                continue
            out[i - 1]["props"].append([k, v])

    dump(root, 0)

    # normaliza valores para o formato do dump v3
    def norm(v):
        if isinstance(v, dict):
            t = v.get("__t")
            if t in ("UDim", "UDim2", "Color3", "Vector2", "Vector3"):
                return v
            if t == "Enum":
                return {"__t": "Enum", "v": f"Enum.{v['v']}"}
            return v
        return v

    for it in out:
        it["props"] = [[k, norm(v)] for k, v in it["props"]]

    out_j = {"guis": {"ARKHER_Studio": out}, "names": names, "classes": classes}
    with open("/tmp/v2ui.json", "w", encoding="utf-8") as f:
        json.dump(out_j, f, ensure_ascii=False)
    print(f"V2 UI: {len(out)} instancias, {sum(len(i['props']) for i in out)} props")
    print(f"classes: {classes}")


def _val(t, v):
    return list(v) if isinstance(v, tuple) else v


if __name__ == "__main__":
    main()
