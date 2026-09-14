#!/usr/bin/env python3
"""ARKHER R21: gera o LocalScript monolito colavel na Command Bar."""
import json, re, sys, hashlib, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
AK = ROOT / "arkher"
SPEC = ROOT / "tools" / "iconspec.json"
OUT = ROOT / "arkher_bootstrap.lua"

ORDER = [
    "util.lua", "icons.lua", "undo.lua", "registry.lua",
    "registry/tabs01.lua", "registry/tabs02.lua", "registry/tabs03.lua",
    "registry/tabs04.lua", "registry/tabs05.lua", "registry/tabs06.lua",
    "actions0.lua", "actions1.lua", "actions2.lua", "actions3.lua", "actions4.lua",
    "shell/store.lua", "shell/sel.lua", "shell/out.lua", "shell/cmd.lua",
    "shell/camera.lua", "shell/clip.lua", "shell/mode.lua", "shell/tools.lua",
    "shell/panelmgr.lua", "shell/panelkit.lua",
    "shell/panels_a.lua", "shell/panels_b.lua", "shell/panels_c.lua",
    "shell/shell.lua", "shell/explorer.lua", "shell/props.lua",
    "shell/bottom.lua", "shell/shortcuts.lua",
    "systems/terrain.lua", "systems/model.lua", "systems/char.lua",
    "systems/anim.lua", "systems/cut.lua", "systems/uitools.lua",
    "systems/mat.lua", "systems/light.lua", "systems/water.lua",
    "systems/phys.lua", "systems/audio.lua", "systems/fx.lua",
    "systems/npc.lua", "systems/ai.lua", "systems/scriptsys.lua",
    "systems/game.lua", "systems/project.lua", "systems/test.lua",
    "systems/multi.lua", "systems/perf.lua", "systems/env.lua",
    "systems/asset.lua", "systems/plugin.lua", "systems/worldext.lua",
    "init.lua",
]
errors, warns = [], []

def load_icons():
    d = json.loads(SPEC.read_text())
    icons = {}
    for ic in d["icons"]:
        nm = ic["name"]
        short = (nm[5:] if nm.startswith("Icon_") else nm).lower()
        px = []
        for k in ic.get("kids", []):
            if k.get("cls") != "Frame":
                continue
            p = k.get("props", {})
            if p.get("BackgroundTransparency", 0) == 1:
                continue
            pos = (p.get("Position") or {}).get("u2")
            siz = (p.get("Size") or {}).get("u2")
            col = (p.get("BackgroundColor3") or {}).get("c3")
            if not (pos and siz and col):
                continue
            rot = p.get("Rotation", 0) or 0
            px.append((pos[0], pos[2], siz[0], siz[2], col, rot))
        icons[short] = px
    return icons

def lua_icons(icons):
    parts = ["ICONS = {"]
    for name in sorted(icons):
        parts.append('  ["%s"] = {' % name)
        for (x, y, w, h, c, r) in icons[name]:
            parts.append("    {%.4f,%.4f,%.4f,%.4f,{%.4f,%.4f,%.4f},%s}," % (
                x, y, w, h, c[0], c[1], c[2], str(r)))
        parts.append("  },")
    parts.append("}")
    return "\n".join(parts)

def proc(rel, text):
    text = text.replace('require("arkher.util")', '_G.ARKHER.util')
    if "require(" in text:
        errors.append("%s: require() restante" % rel)
    lines = text.split("\n")
    while lines and lines[-1].strip() == "":
        lines.pop()
    if lines and re.match(r"^return\s+\S+", lines[-1].strip()):
        lines.pop()
        if rel == "util.lua":
            lines.append("_G.ARKHER.util = U")
        elif rel == "icons.lua":
            lines.append("_G.ARKHER.icons = Icons")
        elif rel == "undo.lua":
            lines.append("_G.ARKHER.undo = Undo")
        elif rel == "registry.lua":
            lines.append("_G.ARKHER.registry = Registry")
        elif rel.startswith("registry/tabs"):
            lines.append("_G.ARKHER.registry.addFile(T)")
    return "\n".join(lines)

def main():
    icons = load_icons()
    print("icons: %d" % len(icons))
    mods = {}
    for rel in ORDER:
        p = AK / rel
        if not p.exists():
            errors.append("ausente: " + rel)
            continue
        mods[rel] = proc(rel, p.read_text())
    tabs = "".join(mods.get("registry/tabs0%d.lua" % i, "") for i in range(1, 7))
    ncmd = len(re.findall(r'\bact\s*=\s*"', tabs))
    per = []
    chunks = re.split(r'\{\s*id\s*=\s*"[A-Z]+",\s*label\s*=', tabs)
    for ch in chunks[1:]:
        per.append(len(re.findall(r'\bact\s*=\s*"', ch.split("T\[#T")[0] if "T[#T" in ch else ch)))
    tabids = re.findall(r'\{\s*id\s*=\s*"([A-Z]+)",\s*label\s*=', tabs)
    print("tabs: %d cmds: %d" % (len(tabids), ncmd))
    if len(tabids) != 30:
        errors.append("tabs=%d esperava 30" % len(tabids))
    if ncmd != 1200:
        errors.append("cmds=%d esperava 1200" % ncmd)
    bad = [(tabids[i] if i < len(tabids) else ("?%d" % i), c) for i, c in enumerate(per) if c != 40]
    for tid, c in bad:
        errors.append("aba %s: %d cmds" % (tid, c))
    used_act = set(re.findall(r'act\s*=\s*"([a-z_0-9]+)"', tabs))
    defined = set()
    for rel in ("actions0.lua", "actions1.lua", "actions2.lua",
                "actions3.lua", "actions4.lua"):
        defined |= set(re.findall(r'A\.([a-z_0-9]+)\s*=', mods.get(rel, "")))
    missing = sorted(used_act - defined)
    for a in missing:
        errors.append("act sem impl: " + a)
    print("acts: %d usados, %d definidos, %d faltando" % (
        len(used_act), len(defined), len(missing)))
    used_ic = set(re.findall(r'icon\s*=\s*"([a-zA-Z0-9_]+)"', tabs))
    missing_ic = sorted(i for i in used_ic if i.lower() not in icons)
    for i in missing_ic:
        errors.append("icone ausente: " + i)
    print("icones usados: %d, faltando: %d" % (len(used_ic), len(missing_ic)))
    bespoke = set()
    for rel in ("shell/panels_a.lua", "shell/panels_b.lua",
                "shell/panels_c.lua"):
        bespoke |= set(re.findall(r'reg\("([a-z_0-9]+)"', mods.get(rel, "")))
    print("paineis bespoke: %d (+fallback generico funcional)" % len(bespoke))
    if errors:
        print("BUILD FALHOU:")
        for e in errors[:40]:
            print("  ERRO " + e)
        sys.exit(1)
    head = ("-- ARKHER ENGINE R21 bootstrap (gerado — nao editar)\n"
            "-- COLAR: Studio > View > Command Bar > colar tudo > Enter\n"
            "-- Requer: modo Edit (APIs de plugin via Command Bar)\n"
            "_G.ARKHER = { ACTIONS = {}, systems = {} }\n"
            + lua_icons(icons) + "\n")
    body = "\n".join("-- ===== %s =====\ndo\n%s\nend" % (r, mods[r])
                     for r in ORDER if r in mods)
    blob = head + body + "\n-- fim bootstrap R21\n"
    OUT.write_text(blob)
    h = hashlib.md5(blob.encode()).hexdigest()
    print("OK %s bytes=%d md5=%s" % (OUT.name, len(blob), h))

main()
