#!/usr/bin/env python3
"""Auditoria R17: layout sem sobreposicao e viewport legivel.

Checa em tools/shell2spec.json (design space 1568x882):
  1. Painel/chrome ids conhecidos: todo painel top-level pertence a um grupo.
  2. Dentro de cada grupo simultaneamente visivel, nenhum par de rects se
     sobrepoe (pares mutuamente exclusivos sao allowlist).
  3. Nenhum painel cobre o chrome reservado (menu/ribbon/footer; top/bottom
     no mobile; top/legend no console).
  4. Tudo dentro de 1568x882.
  5. (estatico) listas DESK/DESK_HIDE dos clients 12-22 contem os 19 nomes.

Uso: audit_layout.py  (exit 1 se houver violacao)
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = os.path.join(HERE, "shell2spec.json")
SCRIPTS = os.path.join(HERE, "..", "scripts")
W, H = 1568, 882

DESK19 = ["T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
          "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel",
          "O2_Crumb", "O2_Compass", "O2_Coords", "O2_Play",
          "O2_Layers", "O2_Region", "O2_Map", "O2_Gizmo", "FR2_Help"]
CHROME_DESK = ["MenuBar2", "Ribbon2", "F2_Out", "F2_Err", "F2_LogLine",
               "F2_Project", "F2_SaveState", "F2_FPS", "F2_Ping", "F2_Mem",
               "F2_Publish"]
MODALS_DESK = ["D_Settings", "D_Marquee"]
EDITORS = {
    "TE3": ["TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
            "TE3_Gen", "TE3_Water", "TE3_Status"],
    "VP3": ["VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap",
            "VP3_Status"],
    "MD4": ["MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO",
            "MD4_Status"],
    "AN5": ["AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys",
            "AN5_IO", "AN5_Status"],
    "UI6": ["UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO",
            "UI6_Status"],
    "RW7": ["RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World",
            "RW7_LOD", "RW7_Status"],
    "DO8": ["DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel",
            "DO8_Mem", "DO8_Status"],
    "WO9": ["WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save",
            "WO9_Clean", "WO9_Status"],
    "HO10": ["HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help",
             "HO10_Status"],
    "SC11": ["SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk",
             "SC11_Out", "SC11_Status"],
    "PL12": ["PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto",
             "PL12_Status"],
}
# pares que nunca aparecem juntos (mesmo slot / modos): pular.
EXCLUSIVE = [("SC11_Edit", "SC11_Py"), ("SC11_Edit", "SC11_Blk"),
             ("SC11_Py", "SC11_Blk")]
MSTRIPS = ["M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO",
           "M_HO", "M_SC", "M_PL"]
M_ALWAYS = ["M_Top", "M_Tools", "M_Bottom", "M_Sel", "M_Help"]
M_OVERLAY = ["M_Drawer", "M_PropsP"]  # cobrem so viewport quando abertos
M_MODAL = ["M_Numeric", "M_Marquee"]
C_ALWAYS = ["C_Top", "C_Cursor", "C_Legend"]
C_OVERLAY = ["C_Panel"]
C_MODAL = ["C_Radial", "C_Numeric", "C_Marquee"]


def rect(n):
    p = n.get("props", {})
    pos = p.get("Position", {}).get("u2", [0, 0, 0, 0])
    siz = p.get("Size", {}).get("u2", [0, 0, 0, 0])
    return (pos[1], pos[3], pos[1] + siz[1], pos[3] + siz[3])


def overlap(a, b):
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def main():
    spec = json.load(open(SPEC, encoding="utf-8"))
    roots = {r.get("name"): r for r in spec["roots"]}
    viol = []

    def kids(root):
        return {k.get("name"): rect(k) for k in roots[root]["kids"]}

    def check_group(label, R, names, skip=()):
        skipset = set()
        for a, b in skip:
            skipset.add((a, b))
            skipset.add((b, a))
        present = [n for n in names if n in R]
        missing = [n for n in names if n not in R]
        for n in missing:
            # O2_Panel/O2_WPanel sao no-ops historicos: aviso, nao erro.
            if n in ("O2_Panel", "O2_WPanel"):
                continue
            viol.append("%s: painel ausente no bake: %s" % (label, n))
        for i in range(len(present)):
            for j in range(i + 1, len(present)):
                a, b = present[i], present[j]
                if (a, b) in skipset:
                    continue
                if overlap(R[a], R[b]):
                    viol.append("%s: SOBREPOE %s %s x %s %s"
                                % (label, a, R[a], b, R[b]))

    def check_chrome(label, R, panels, chrome):
        for p in panels:
            if p not in R:
                continue
            for c in chrome:
                if c in R and overlap(R[p], R[c]):
                    viol.append("%s: %s %s invade chrome %s %s"
                                % (label, p, R[p], c, R[c]))

    def check_bounds(label, R):
        for n, r in sorted(R.items()):
            if r[0] < 0 or r[1] < 0 or r[2] > W or r[3] > H:
                viol.append("%s: %s %s fora de 1568x882" % (label, n, r))

    # ---- desktop ----
    D = kids("DesktopRoot")
    check_bounds("desk", D)
    check_group("desk/desk", D, DESK19)
    for ed, panels in EDITORS.items():
        check_group("desk/" + ed, D, panels, skip=EXCLUSIVE)
    check_chrome("desk", D,
                 [n for ps in EDITORS.values() for n in ps] + DESK19,
                 CHROME_DESK)
    known = (set(CHROME_DESK) | set(MODALS_DESK) | set(DESK19)
             | {n for ps in EDITORS.values() for n in ps})
    for n in D:
        if n not in known:
            viol.append("desk: painel top-level desconhecido: %s" % n)
    # modais precisam ZIndex alto (pintam por cima de tudo).
    for r in roots["DesktopRoot"]["kids"]:
        if r.get("name") == "D_Settings":
            z = r.get("props", {}).get("ZIndex", 1)
            if not isinstance(z, (int, float)) or z < 20:
                viol.append("desk: D_Settings sem ZIndex alto (z=%r)" % z)

    # ---- mobile ----
    M = kids("MobileRoot")
    check_bounds("mob", M)
    check_group("mob/always", M, M_ALWAYS)
    for s in MSTRIPS:
        check_group("mob/" + s, M, M_ALWAYS + [s])
    for o in M_OVERLAY:
        check_chrome("mob/" + o, M, [o], M_ALWAYS)
    for n in M:
        if n not in set(M_ALWAYS) | set(MSTRIPS) | set(M_OVERLAY) | set(M_MODAL):
            viol.append("mob: painel top-level desconhecido: %s" % n)
    for r in roots["MobileRoot"]["kids"]:
        if r.get("name") == "M_Numeric":
            z = r.get("props", {}).get("ZIndex", 1)
            if not isinstance(z, (int, float)) or z < 20:
                viol.append("mob: M_Numeric sem ZIndex alto (z=%r)" % z)

    # ---- console ----
    Cc = kids("ConsoleRoot")
    check_bounds("con", Cc)
    check_group("con/always", Cc, C_ALWAYS)
    for o in C_OVERLAY:
        check_chrome("con/" + o, Cc, [o], C_ALWAYS)
    for n in Cc:
        if n not in set(C_ALWAYS) | set(C_OVERLAY) | set(C_MODAL):
            viol.append("con: painel top-level desconhecido: %s" % n)
    for r in roots["ConsoleRoot"]["kids"]:
        if r.get("name") in ("C_Radial", "C_Numeric"):
            z = r.get("props", {}).get("ZIndex", 1)
            if not isinstance(z, (int, float)) or z < 20:
                viol.append("con: %s sem ZIndex alto (z=%r)"
                            % (r.get("name"), z))

    # ---- VR: so bounds (crosshair sobre painel e intencional) ----
    check_bounds("vr", kids("VRoot"))

    # ---- estatico: DESK lists dos clients 12-22 ----
    files = {"12_Terrain": "DESK_HIDE", "13_Viewport": "DESK_HIDE",
             "14_Modeler": "DESK_HIDE", "15_Animator": "DESK_HIDE",
             "16_UI": "DESK_HIDE", "17_RRW": "DESK_HIDE",
             "18_Do15": "DESK", "19_World": "DESK", "20_Home": "DESK",
             "21_Script": "DESK", "22_Places": "DESK"}
    for fn, var in files.items():
        src = open(os.path.join(SCRIPTS, fn + ".lua"), encoding="utf-8").read()
        m = re.search(re.escape(var) + r"\s*=\s*\{(.*?)\}", src, re.S)
        if not m:
            viol.append("static: %s sem %s" % (fn, var))
            continue
        have = set(re.findall(r'"([A-Za-z0-9_]+)"', m.group(1)))
        for n in DESK19:
            if n not in have:
                viol.append("static: %s.%s sem %s" % (fn, var, n))

    print("layout: %d violacoes" % len(viol))
    for v in viol[:60]:
        print("  -", v)
    return 1 if viol else 0


if __name__ == "__main__":
    sys.exit(main())
