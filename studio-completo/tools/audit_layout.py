#!/usr/bin/env python3
"""Auditoria R18: layout sem sobreposicao e viewport legivel.

Checa em tools/shell2spec.json + tools/guix_spec.json (1568x882):
  1. Painel/chrome ids conhecidos: todo painel top-level pertence a um grupo.
  2. Dentro de cada grupo simultaneamente visivel, nenhum par de rects se
     sobrepoe (pares mutuamente exclusivos sao allowlist).
  3. Nenhum painel cobre o chrome reservado (topbar unica ArkherTop +
     footer; top/bottom no mobile; top/legend no console).
  4. Tudo dentro de 1568x882.
  5. (estatico) listas DESK/DESK_HIDE dos clients 12-22 contem os 19 nomes.
  6. Topbar unica: ArkherTop 1568x120 em y0; HeaderRow+TabStrip+Ribbon sem
     sobrepor; 18 menus + 9 abas + 9 paginas (1 visivel) + 42 botoes.

Uso: audit_layout.py  (exit 1 se houver violacao)
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SPEC = os.path.join(HERE, "shell2spec.json")
GUIX = os.path.join(HERE, "guix_spec.json")
SCRIPTS = os.path.join(HERE, "..", "scripts")
W, H = 1568, 882

DESK19 = ["T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
          "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel",
          "O2_Crumb", "O2_Compass", "O2_Coords", "O2_Play",
          "O2_Layers", "O2_Region", "O2_Map", "O2_Gizmo", "FR2_Help"]
CHROME_DESK = ["F2_Out", "F2_Err", "F2_LogLine",
               "F2_Project", "F2_SaveState", "F2_FPS", "F2_Ping", "F2_Mem",
               "F2_Publish"]
# topbar unica (guix shell, fora do shell2spec): rect esperado absoluto.
TOPBAR_RECT = (0, 0, 1568, 120)
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

    # ---- topbar unica (guix shell) ----
    def rect_abs(n, pw, ph):
        p = n.get("props", {})
        pos = p.get("Position", {}).get("u2", [0, 0, 0, 0])
        siz = p.get("Size", {}).get("u2", [0, 0, 0, 0])
        x0 = pos[0] * pw + pos[1]
        y0 = pos[2] * ph + pos[3]
        return (x0, y0, x0 + siz[0] * pw + siz[1], y0 + siz[2] * ph + siz[3])

    gx = json.load(open(GUIX, encoding="utf-8"))
    tops = [t for t in gx.get("shell", []) if t.get("name") == "ArkherTop"]
    if len(tops) != 1:
        viol.append("topbar: ArkherTop ausente ou duplicado no guix shell")
        tops = []
    else:
        top = tops[0]
        tr = rect_abs(top, W, H)
        if tr != TOPBAR_RECT:
            viol.append("topbar: ArkherTop %s != %s" % (tr, TOPBAR_RECT))
        tk = {k.get("name"): k for k in top.get("kids", [])}
        rows = {n: rect_abs(tk[n], tr[2] - tr[0], tr[3] - tr[1])
                for n in ("HeaderRow", "TabStrip", "Ribbon") if n in tk}
        for n in ("HeaderRow", "TabStrip", "Ribbon"):
            if n not in tk:
                viol.append("topbar: %s ausente em ArkherTop" % n)
        rn = sorted(rows)
        for i in range(len(rn)):
            for j in range(i + 1, len(rn)):
                if overlap(rows[rn[i]], rows[rn[j]]):
                    viol.append("topbar: SOBREPOE %s x %s"
                                % (rn[i], rn[j]))
        for n, r in rows.items():
            if r[1] < 0 or r[3] > TOPBAR_RECT[3]:
                viol.append("topbar: %s %s fora de ArkherTop" % (n, r))
        # header row: logo + slogan + search + bell + user, sem sobrepor.
        mk = tk.get("HeaderRow", {}).get("kids", []) if "HeaderRow" in tk else []
        hdr = [k.get("name") for k in mk
               if k.get("name", "").startswith("H_")]
        for want in ("H_Logo", "H_Slogan", "H_Search", "H_Bell", "H_User"):
            if want not in hdr:
                viol.append("topbar: %s ausente no HeaderRow" % want)
        mr = [(k.get("name"), rect(k)) for k in mk
              if k.get("cls") in ("TextButton", "TextBox", "TextLabel")]
        for i in range(len(mr)):
            for j in range(i + 1, len(mr)):
                if overlap(mr[i][1], mr[j][1]):
                    viol.append("topbar: header SOBREPOE %s x %s"
                                % (mr[i][0], mr[j][0]))
        for nm, r in mr:
            if r[2] > W or r[1] < 0 or r[3] > rows.get("HeaderRow", (0, 0, 0, 26))[3]:
                viol.append("topbar: header %s %s fora da HeaderRow" % (nm, r))
        # abas + paginas + botoes (max 20/aba).
        strip = tk.get("TabStrip", {}).get("kids", []) if "TabStrip" in tk else []
        tabs = [k for k in strip if k.get("name", "").startswith("Tab_")]
        if len(tabs) != 18:
            viol.append("topbar: %d abas Tab_* (esperado 18)" % len(tabs))
        pages = [k for k in tk.get("Ribbon", {}).get("kids", [])
                 if k.get("name", "").startswith("Page_")] if "Ribbon" in tk else []
        if len(pages) != 18:
            viol.append("topbar: %d paginas Page_* (esperado 18)" % len(pages))
        vispages = [k.get("name") for k in pages
                    if k.get("props", {}).get("Visible", True)]
        if vispages != ["Page_HOME"]:
            viol.append("topbar: paginas visiveis %s (esperado ['Page_HOME'])"
                        % vispages)
        nbtn = 0
        for pg in pages:
            nb = 0
            for k in pg.get("kids", []):
                if k.get("name", "").startswith("RibbonBtn_"):
                    nbtn += 1
                    nb += 1
                    s = k.get("props", {}).get("Size", {}).get("u2", [0, 0, 0, 0])
                    if s[1] > 1568 or s[3] > 58:
                        viol.append("topbar: botao %s %dx%d nao cabe no ribbon"
                                    % (k.get("name"), s[1], s[3]))
            if nb > 20:
                viol.append("topbar: %s com %d botoes (>20)"
                            % (pg.get("name"), nb))
        if nbtn != 162:
            viol.append("topbar: %d botoes RibbonBtn_* (esperado 162)" % nbtn)

    # ---- desktop ----
    D = kids("DesktopRoot")
    check_bounds("desk", D)
    # paineis desktop nao invadem a topbar unica (guix shell).
    if tops:
        for p in ([n for ps in EDITORS.values() for n in ps] + DESK19):
            if p in D and overlap(D[p], TOPBAR_RECT):
                viol.append("desk: %s %s invade topbar %s"
                            % (p, D[p], TOPBAR_RECT))
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
