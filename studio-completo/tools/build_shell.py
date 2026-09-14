#!/usr/bin/env python3
"""Gera tools/shellspec.json — a TOPBAR UNICA do Arkher Studio (R18).

ArkherTop (Frame 1568x120, y0) — o unico ribbon/topbar do Studio:
  MenuRow (Frame 30px): logo + 18 menus (File/Edit/View/Insert/Run/Game +
      Assets/Models/Terrain/Animation/Audio/Scripts/UI/FX/Lighting/Gameplay/
      Physics/Tools) + M2_Search + M2_Bell + M2_User
  TabStrip (ScrollingFrame 26px): 9 abas Tab_<T>
  Ribbon (Frame 63px): Page_<T> (ScrollingFrame) por aba, cada uma com
    RibbonBtn_<T>_<id> (TextButton 64x58 + Icon 30x30 + Lbl 2 linhas)
ArkherMsg (toast inferior-direito, Visible=false)
Icones: kids copiados de tools/iconspec.json (posicoes em escala -> adaptam).

FONTE UNICA da tabela abas/botoes/acoes — 09_Topbar.lua consome ACTIONS.
Acao: ("menus", cmd)      -> MenusBus:Invoke(cmd)
       ("menu", name)       -> MenusBus:Invoke("Menu", {name=name, button=btn})
       ("core", key)        -> ClientBus SetMode/SetSpace
       ("api", action)      -> ClientBus API (Undo/Redo)
       ("lock",)            -> PropsAll + SetAny Locked (09_Topbar).
"""
import copy
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# (name, text, width) — menus clássicos (base File/Edit/... preservados)
MENUS_BASE = [
    ("M2_File", "File", 52), ("M2_Edit", "Edit", 52),
    ("M2_View", "View", 50), ("M2_Insert", "Insert", 56),
    ("M2_Run", "Run", 50), ("M2_Game", "Game", 58),
]
# (name, text, width) — menus X (geração shell2, preservados)
MENUS_X = [
    ("M2_Assets", "Assets", 64), ("M2_Models", "Models", 64),
    ("M2_Terrain", "Terrain", 64), ("M2_Animation", "Animation", 76),
    ("M2_Audio", "Audio", 56), ("M2_Scripts", "Scripts", 64),
    ("M2_UI", "UI", 40), ("M2_FX", "FX", 44),
    ("M2_Lighting", "Lighting", 66), ("M2_Gameplay", "Gameplay", 74),
    ("M2_Physics", "Physics", 66), ("M2_Tools", "Tools", 56),
]

# (tab, id, label, icon, acao...)
TABS = [
    ("FILE", [
        ("Save", "Save", "save", ("menus", "Save")),
        ("Open", "Open", "open", ("menus", "Open")),
        ("SaveToArkher", "Save to\nArkher", "cloud", ("menus", "SavePlaceAccount")),
        ("Publish", "Publish", "share", ("menus", "OpenPublish")),
        ("Help", "Help", "bulb", ("menus", "HelpStudio")),
    ]),
    ("EDIT", [
        ("Undo", "Undo", "undo", ("api", "Undo")),
        ("Redo", "Redo", "redo", ("api", "Redo")),
        ("Anchor", "Anchor", "anchor", ("menus", "XAnchor")),
        ("Snap", "Snap", "snap", ("menus", "XSnap")),
        ("Group", "Group", "group", ("menus", "XGroup")),
        ("Ungroup", "Ungroup", "ungroup", ("menus", "XUngroup")),
    ]),
    ("INSERT", [
        ("Model", "Model", "model", ("menus", "InsertModel")),
        ("Folder", "Folder", "folder", ("menus", "InsertFolder")),
        ("Script", "Script", "script", ("menus", "InsertScript")),
        ("Text", "Text", "textA", ("menus", "InsertTextLabel")),
    ]),
    ("CREATE", [
        ("Terrain", "Terrain", "terrain", ("menu", "Terrain")),
        ("Insert", "Insert", "plus", ("menus", "Insert")),
        ("Script", "Script", "script", ("menu", "Scripts")),
        ("UI", "UI", "ws", ("menu", "UI")),
        ("Animate", "Animate", "play", ("menu", "Animation")),
        ("FX", "FX", "gem", ("menu", "FX")),
    ]),
    ("RUN", [
        ("Play", "Play", "play", ("menus", "RunToggle")),
        ("Pause", "Pause", "pause", ("menus", "RunPause")),
        ("Stop", "Stop", "square", ("menus", "RunStop")),
    ]),
    ("TRANSFORM", [
        ("Select", "Select", "select", ("core", "Select")),
        ("MoveScale", "Move", "move", ("core", "MoveScale")),
        ("Rotate", "Rotate", "rotate", ("core", "Rotate")),
        ("Scale", "Scale", "scaleI", ("core", "Scale")),
        ("Transform", "Transform", "transform", ("menus", "XTransform")),
        ("Lock", "Lock", "lock", ("lock",)),
        ("LocalGlobal", "Local\nGlobal", "globe", ("core", "LocalGlobal")),
    ]),
    ("SETTINGS", [
        ("Data", "Data", "data", ("menus", "OpenData")),
        ("Localization", "Lang", "globe", ("menus", "OpenLocalization")),
        ("Settings", "Settings", "settings", ("menus", "XSettings")),
    ]),
    ("PLUGINS", [
        ("ArkherCloud", "Cloud\nInfo", "info", ("menus", "OpenCloud")),
        ("PluginToolbar", "Plugins", "plugin", ("menus", "OpenPlugins")),
    ]),
    ("TEAM", [
        ("Toolbox", "Toolbox", "toolbox", ("menus", "OpenToolbox")),
        ("CollaborationSettings", "Collab", "people", ("menus", "OpenCollaboration")),
        ("Collaborate", "Collaborate", "playersI", ("menus", "Collaborate")),
        ("Invites", "Invites", "chat", ("menus", "Invites")),
        ("Changes", "Changes", "repfirst", ("menus", "Changes")),
        ("Account", "Account", "playercard", ("menus", "Account")),
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
MUTED = C3(140, 160, 190)
ACCENT = C3(88, 166, 255)
GOLD = C3(240, 185, 70)
GREEN = C3(55, 200, 90)
TAB_ACTIVE_BG = C3(26, 42, 74)

TOP_H = 120
MENU_H = 30
STRIP_H = 26
RIBBON_H = TOP_H - MENU_H - STRIP_H - 2  # 62 (1px dividers x2)


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

    # ---- MenuRow: logo + 18 menus + search + bell + user ----
    row_kids = [N("TextLabel", "M2_Logo", {
        "Size": U2(0, 130, 0, 24), "Position": U2(0, 8, 0, 3),
        "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
        "Text": "⬢  ARKHER STUDIO",
        "Font": {"en": "Font.GothamBold"}, "TextSize": 12.0,
        "TextColor3": GOLD, "TextXAlignment": {"en": "TextXAlignment.Left"},
    }, [])]
    mx = 144
    for name, text, w in MENUS_BASE + MENUS_X:
        row_kids.append(N("TextButton", name, {
            "Size": U2(0, w, 0, 26), "Position": U2(0, mx, 0, 2),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": text, "Font": {"en": "Font.Gotham"}, "TextSize": 12.0,
            "TextColor3": TXT, "AutoButtonColor": False, "Active": True,
        }, []))
        mx += w + 4
    search_x = mx + 2
    row_kids += [
        N("TextBox", "M2_Search", {
            "Size": U2(0, 180, 0, 24), "Position": U2(0, search_x, 0, 3),
            "BackgroundColor3": BTN_BG, "BorderSizePixel": 0,
            "Text": "", "PlaceholderText": "Search tools, assets...",
            "PlaceholderColor3": MUTED,
            "Font": {"en": "Font.Gotham"}, "TextSize": 12.0,
            "TextColor3": TXT, "TextXAlignment": {"en": "TextXAlignment.Left"},
            "ClearTextOnFocus": False,
        }, [corner(6), stroke(BTN_EDGE, 1), hpad(8, 0, 8)]),
        N("TextButton", "M2_Bell", {
            "Size": U2(0, 28, 0, 26), "Position": U2(0, search_x + 184, 0, 2),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "🔔", "Font": {"en": "Font.Gotham"}, "TextSize": 14.0,
            "TextColor3": TXT, "AutoButtonColor": False, "Active": True,
        }, []),
        N("TextButton", "M2_User", {
            "Size": U2(0, 82, 0, 26), "Position": U2(0, search_x + 216, 0, 2),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "● dev", "Font": {"en": "Font.GothamBold"}, "TextSize": 12.0,
            "TextColor3": GREEN, "AutoButtonColor": False, "Active": True,
        }, []),
    ]
    right_edge = search_x + 216 + 82
    assert right_edge <= 1568, f"menu row overflow: {right_edge}"
    menu_row = N("Frame", "MenuRow", {
        "Size": U2(1, 0, 0, MENU_H), "Position": U2(0, 0, 0, 0),
        "BackgroundColor3": STRIP_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, row_kids)

    tab_names = [t for t, _ in TABS]
    # ---- TabStrip ----
    tabs = []
    for i, t in enumerate(tab_names):
        active = (i == 0)
        tab = N("TextButton", f"Tab_{t}", {
            "Size": U2(0, 88, 0, 22), "Position": U2(0, 0, 0, 0),
            "LayoutOrder": float(i),
            "BackgroundColor3": TAB_ACTIVE_BG if active else STRIP_BG,
            "BackgroundTransparency": 0.0 if active else 1.0,
            "BorderSizePixel": 0, "ZIndex": 31, "Text": t,
            "Font": {"en": "Font.GothamBold"}, "TextSize": 11.0,
            "TextColor3": TXT if active else TXT2,
            "TextXAlignment": {"en": "TextXAlignment.Center"},
            "AutoButtonColor": False, "Active": True,
        }, [corner(6), N("Frame", "ActivePill", {
            "Size": U2(0, 72, 0, 3), "Position": U2(0, 8, 0, 18),
            "BackgroundColor3": ACCENT, "BorderSizePixel": 0,
            "Visible": active}, [])])
        tabs.append(tab)
    strip = N("ScrollingFrame", "TabStrip", {
        "Size": U2(1, 0, 0, STRIP_H), "Position": U2(0, 0, 0, MENU_H),
        "BackgroundColor3": STRIP_BG, "BorderSizePixel": 0, "ZIndex": 30,
        "CanvasSize": U2(0, len(tab_names) * 92 + 12, 0, 0),
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
                "Size": U2(0, 64, 0, 58), "Position": U2(0, 0, 0, 0),
                "LayoutOrder": float(j),
                "BackgroundColor3": BTN_BG, "BorderSizePixel": 0,
                "ZIndex": 31, "Text": "",
                "AutoButtonColor": False, "Active": True,
            }, [corner(8), stroke(BTN_EDGE, 1),
                N("Frame", "Icon", {
                    "Size": U2(0, 30, 0, 30), "Position": U2(0, 17, 0, 2),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                }, icon_kids(icon)),
                N("TextLabel", "Lbl", {
                    "Size": U2(0, 58, 0, 24), "Position": U2(0, 3, 0, 33),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                    "Text": label, "Font": {"en": "Font.Gotham"},
                    "TextSize": 10.0, "TextColor3": TXT2,
                    "TextXAlignment": {"en": "TextXAlignment.Center"},
                    "TextYAlignment": {"en": "TextYAlignment.Top"},
                    "TextWrapped": True,
                }, [])])
            items.append(btn)
        page_w = len(btns) * (64 + 6) + 16
        page = N("ScrollingFrame", f"Page_{t}", {
            "Size": U2(1, 0, 1, 0), "Position": U2(0, 0, 0, 0),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "ZIndex": 31, "Visible": (i == 0),
            "CanvasSize": U2(0, page_w, 0, 0),
            "ScrollBarThickness": 3, "ScrollBarImageColor3": BTN_EDGE,
            "Active": True, "ClipsDescendants": True,
        }, [hlist(6), hpad(8, 2, 8)] + items)
        pages.append(page)
    ribbon = N("Frame", "Ribbon", {
        "Size": U2(1, 0, 0, RIBBON_H),
        "Position": U2(0, 0, 0, MENU_H + STRIP_H + 1),
        "BackgroundColor3": RIBBON_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, pages)
    top = N("Frame", "ArkherTop", {
        "Size": U2(1, 0, 0, TOP_H), "Position": U2(0, 0, 0, 0),
        "BackgroundColor3": TOP_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, [menu_row,
        N("Frame", "MenuDivider", {
            "Size": U2(1, 0, 0, 1), "Position": U2(0, 0, 0, MENU_H - 1),
            "BackgroundColor3": DIVIDER, "BorderSizePixel": 0}, []),
        strip,
        N("Frame", "TabDivider", {
            "Size": U2(1, 0, 0, 1),
            "Position": U2(0, 0, 0, MENU_H + STRIP_H),
            "BackgroundColor3": DIVIDER, "BorderSizePixel": 0}, []),
        ribbon,
        N("Frame", "RibbonEdge", {
            "Size": U2(1, 0, 0, 1), "Position": U2(0, 0, 0, TOP_H - 1),
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
    n_menus = len(MENUS_BASE) + len(MENUS_X)
    print(f"shell: {n_menus} menus, {len(tab_names)} abas, {n_btns} botoes, "
          f"{total} instancias (topbar unica {TOP_H}px)")
    print(f"spec salva: tools/shellspec.json "
          f"({os.path.getsize(os.path.join(HERE, 'shellspec.json'))} bytes)")


if __name__ == "__main__":
    main()
