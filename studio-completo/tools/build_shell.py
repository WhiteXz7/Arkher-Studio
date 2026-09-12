#!/usr/bin/env python3
"""Gera tools/shellspec.json — a nova shell: TabStrip + Ribbon paginado.

ArkherTop (Frame 148px, topo):
  TabStrip (ScrollingFrame horizontal, 11 abas Tab_<T>)
  Ribbon (Frame): Page_<T> (ScrollingFrame horizontal) por aba, cada uma com
    RibbonBtn_<T>_<id> (TextButton 66x100 + Icon 40x40 + Lbl 2 linhas)
ArkherMsg (toast inferior-direito, Visible=false)
Icones: kids copiados de tools/iconspec.json (posicoes em escala -> adaptam).

FONTE UNICA da tabela abas/botoes/acoes — 05_StudioX.lua espelha ACTIONS.
Acao: ("open", janela) ("toggle", janela) ("popup", nome) ("menus", cmd)
       ("bus", action, payload) .
"""
import copy
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# (tab, id, label, icon, acao...)
TABS = [
    ("FILE", [
        ("Save", "Save", "save", ("menus", "Save")),
        ("Open", "Open", "open", ("menus", "File")),
        ("SaveToArkher", "Cloud", "cloud", ("bus", "CloudQuick", {})),
    ]),
    ("INSERT", [
        ("Model", "Model", "model", ("bus", "CreateAny", {"class": "Model"})),
        ("Folder", "Folder", "folder", ("bus", "CreateAny", {"class": "Folder"})),
        ("Script", "Script", "script", ("bus", "CreateAny", {"class": "Script"})),
        ("Text", "Text", "textA", ("bus", "CreateAny", {"class": "TextLabel"})),
    ]),
    ("RUN", [
        ("Play", "Play", "play", ("menus", "RunToggle")),
        ("Pause", "Pause", "pause", ("menus", "RunPause")),
    ]),
    ("TRANSFORM", [
        ("Select", "Select", "select", ("core", "Select")),
        ("MoveScale", "Move", "move", ("core", "MoveScale")),
        ("Rotate", "Rotate", "rotate", ("core", "Rotate")),
        ("Scale", "Scale", "scaleI", ("core", "Scale")),
        ("Transform", "Transform", "transform", ("core", "Transform")),
        ("Lock", "Lock", "lock", ("core", "Lock")),
        ("LocalGlobal", "Local\nGlobal", "globe", ("core", "LocalGlobal")),
    ]),
    ("SETTINGS", [
        ("Data", "Data", "data", ("menus", "OpenData")),
        ("Localization", "Lang", "globe", ("menus", "OpenLocalization")),
        ("Settings", "Settings", "settings", ("menus", "OpenProjectSettings")),
    ]),
    ("PLUGINS", [
        ("ArkherCloud", "Cloud\nInfo", "info", ("menus", "OpenCloud")),
        ("PluginToolbar", "Plugins", "plugin", ("menus", "OpenPlugins")),
    ]),
    ("TEAM", [
        ("CollaborationSettings", "Collab", "people", ("menus", "OpenCollaboration")),
        ("Toolbox", "Toolbox", "toolbox", ("menus", "OpenToolbox")),
    ]),
]


def C3(r, g, b):
    return {"c3": [r / 255.0, g / 255.0, b / 255.0]}


def U2(sx, ox, sy, oy):
    return {"u2": [float(sx), float(ox), float(sy), float(oy)]}


def U1(s, o):
    return {"u1": [float(s), float(o)]}


TOP_BG = C3(11, 18, 32)
STRIP_BG = C3(7, 13, 25)
RIBBON_BG = C3(15, 27, 51)
BTN_BG = C3(20, 38, 74)
BTN_EDGE = C3(42, 59, 94)
DIVIDER = C3(34, 49, 79)
TXT = C3(230, 235, 245)
TXT2 = C3(199, 210, 232)
ACCENT = C3(88, 166, 255)
TAB_ACTIVE_BG = C3(26, 42, 74)


def N(cls, name, props=None, kids=None):
    return {"cls": cls, "name": name, "props": props or {}, "kids": kids or []}


def corner(r):
    return N("UICorner", "UICorner", {"CornerRadius": U1(0, r)})


def stroke(color, th=1):
    return N("UIStroke", "UIStroke", {
        "Color": color, "Thickness": float(th),
        "ApplyStrokeMode": {"en": "ApplyStrokeMode.Border"}})


def hlist(pad=6):
    return N("UIListLayout", "UIListLayout", {
        "FillDirection": {"en": "FillDirection.Horizontal"},
        "SortOrder": {"en": "SortOrder.LayoutOrder"},
        "Padding": U1(0, pad)})


def hpad(l, t, r):
    return N("UIPadding", "UIPadding", {
        "PaddingLeft": U1(0, l), "PaddingTop": U1(0, t), "PaddingRight": U1(0, r)})


def main():
    icons = {i["name"]: i for i in json.load(
        open(os.path.join(HERE, "iconspec.json"), encoding="utf-8"))["icons"]}

    def icon_kids(icon):
        src = icons["Icon_" + icon]["kids"]
        return copy.deepcopy(src)

    tab_names = [t for t, _ in TABS]
    # ---- TabStrip ----
    strip_w = len(tab_names) * (92 + 4) + 12
    tabs = []
    for i, t in enumerate(tab_names):
        active = (i == 0)
        tab = N("TextButton", f"Tab_{t}", {
            "Size": U2(0, 92, 0, 26), "Position": U2(0, 0, 0, 0),
            "LayoutOrder": float(i),
            "BackgroundColor3": TAB_ACTIVE_BG if active else STRIP_BG,
            "BackgroundTransparency": 0.0 if active else 1.0,
            "BorderSizePixel": 0, "ZIndex": 31, "Text": t,
            "Font": {"en": "Font.GothamBold"}, "TextSize": 11.0,
            "TextColor3": TXT if active else TXT2,
            "TextXAlignment": {"en": "TextXAlignment.Center"},
            "AutoButtonColor": False, "Active": True,
        }, [corner(6), N("Frame", "ActivePill", {
            "Size": U2(0, 76, 0, 3), "Position": U2(0, 8, 0, 22),
            "BackgroundColor3": ACCENT, "BorderSizePixel": 0,
            "Visible": active}, [])])
        tabs.append(tab)
    strip = N("ScrollingFrame", "TabStrip", {
        "Size": U2(1, 0, 0, 30), "Position": U2(0, 0, 0, 0),
        "BackgroundColor3": STRIP_BG, "BorderSizePixel": 0, "ZIndex": 30,
        "CanvasSize": U2(0, strip_w, 0, 0),
        "ScrollBarThickness": 3, "ScrollBarImageColor3": BTN_EDGE,
        "Active": True, "ClipsDescendants": True,
    }, [hlist(4), hpad(6, 2, 6)] + tabs)

    # ---- Ribbon pages ----
    pages = []
    n_btns = 0
    for i, (t, btns) in enumerate(TABS):
        items = []
        for j, (bid, label, icon, _act) in enumerate(btns):
            n_btns += 1
            btn = N("TextButton", f"RibbonBtn_{t}_{bid}", {
                "Size": U2(0, 66, 0, 100), "Position": U2(0, 0, 0, 0),
                "LayoutOrder": float(j),
                "BackgroundColor3": BTN_BG, "BorderSizePixel": 0,
                "ZIndex": 31, "Text": "",
                "AutoButtonColor": False, "Active": True,
            }, [corner(8), stroke(BTN_EDGE, 1),
                N("Frame", "Icon", {
                    "Size": U2(0, 40, 0, 40), "Position": U2(0, 13, 0, 8),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                }, icon_kids(icon)),
                N("TextLabel", "Lbl", {
                    "Size": U2(0, 60, 0, 42), "Position": U2(0, 3, 0, 52),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                    "Text": label, "Font": {"en": "Font.Gotham"},
                    "TextSize": 10.0, "TextColor3": TXT2,
                    "TextXAlignment": {"en": "TextXAlignment.Center"},
                    "TextYAlignment": {"en": "TextYAlignment.Top"},
                    "TextWrapped": True,
                }, [])])
            items.append(btn)
        page_w = len(btns) * (66 + 6) + 16
        page = N("ScrollingFrame", f"Page_{t}", {
            "Size": U2(1, 0, 1, 0), "Position": U2(0, 0, 0, 0),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "ZIndex": 31, "Visible": (i == 0),
            "CanvasSize": U2(0, page_w, 0, 0),
            "ScrollBarThickness": 3, "ScrollBarImageColor3": BTN_EDGE,
            "Active": True, "ClipsDescendants": True,
        }, [hlist(6), hpad(8, 8, 8)] + items)
        pages.append(page)
    ribbon = N("Frame", "Ribbon", {
        "Size": U2(1, 0, 0, 116), "Position": U2(0, 0, 0, 31),
        "BackgroundColor3": RIBBON_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, pages)
    top = N("Frame", "ArkherTop", {
        "Size": U2(1, 0, 0, 148), "Position": U2(0, 0, 0, 68),
        "BackgroundColor3": TOP_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, [strip,
        N("Frame", "TabDivider", {
            "Size": U2(1, 0, 0, 1), "Position": U2(0, 0, 0, 30),
            "BackgroundColor3": DIVIDER, "BorderSizePixel": 0}, []),
        ribbon,
        N("Frame", "RibbonEdge", {
            "Size": U2(1, 0, 0, 1), "Position": U2(0, 0, 0, 147),
            "BackgroundColor3": DIVIDER, "BorderSizePixel": 0}, [])])

    # ---- Toast inferior ----
    toast = N("Frame", "ArkherMsg", {
        "Size": U2(0, 320, 0, 30), "Position": U2(1, -328, 1, -56),
        "BackgroundColor3": TOP_BG, "BorderSizePixel": 0,
        "ZIndex": 60, "Visible": False, "Active": True,
    }, [corner(6), stroke(BTN_EDGE, 1),
        N("TextLabel", "MsgLbl", {
            "Size": U2(1, -16, 1, 0), "Position": U2(0, 8, 0, 0),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "", "Font": {"en": "Font.Gotham"}, "TextSize": 11.0,
            "TextColor3": TXT, "TextXAlignment": {"en": "TextXAlignment.Left"},
            "TextTruncate": {"en": "TextTruncate.AtEnd"},
        }, [])])

    out = {"shell": [top, toast]}
    with open(os.path.join(HERE, "shellspec.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)

    def count(n):
        return 1 + sum(count(k) for k in n["kids"])
    total = sum(count(n) for n in out["shell"])
    print(f"shell: {len(tab_names)} abas, {n_btns} botoes, {total} instancias")
    print(f"spec salva: tools/shellspec.json "
          f"({os.path.getsize(os.path.join(HERE, 'shellspec.json'))} bytes)")


if __name__ == "__main__":
    main()
