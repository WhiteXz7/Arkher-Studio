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
    ("HOME", [
        ("Play", "Play", "play", ("menus", "RunToggle")),
        ("Pause", "Pause", "pause", ("menus", "RunPause")),
        ("Stop", "Stop", "square", ("menus", "RunStop")),
        ("Plugins", "Plugins", "plugin", ("open", "V2_ArkherPluginManager")),
        ("Save", "Save", "save", ("menus", "Save")),
        ("Open", "Open", "open", ("menus", "File")),
        ("Undo", "Undo", "rotate", ("bus", "Undo", {})),
        ("Redo", "Redo", "chevR", ("bus", "Redo", {})),
        ("Palette", "Command\nPalette", "chevD", ("open", "V2_ArkherPalette")),
        ("Search", "Search", "search", ("open", "V2_ArkherSearch")),
        ("Toolbox", "Toolbox", "toolbox", ("open", "V2_ArkherToolbox")),
        ("Settings", "Settings", "settings", ("open", "V2_ArkherSettings")),
        ("Status", "Status\nBar", "check", ("toggle", "V2_ArkherStatusBar")),
        ("Places", "Places", "folder", ("open", "V2_ArkherSaveOpen")),
        ("History", "Undo\nHistory", "square", ("open", "V2_ArkherUndoRedo")),
    ]),
    ("BUILD", [
        ("Select", "Select", "select", ("core", "Select")),
        ("Move", "Move", "move", ("core", "Move")),
        ("Rotate", "Rotate", "rotate", ("core", "Rotate")),
        ("Scale", "Scale", "scaleI", ("core", "Scale")),
        ("Part", "Part", "cubeW", ("popup", "ArkherShapesPopup")),
        ("Model", "Model", "model", ("bus", "CreateAny", {"class": "Model"})),
        ("Folder", "Folder", "folder", ("bus", "CreateAny", {"class": "Folder"})),
        ("Script", "Script", "script", ("bus", "CreateAny", {"class": "Script"})),
        ("Text", "Text", "textA", ("open", "V2_ArkherInsert")),
        ("Material", "Material", "plate", ("open", "V2_ArkherMaterialEditor")),
        ("Mesh", "Mesh", "cubeT", ("open", "Deck_mesh")),
        ("Modeler", "Modeler", "move", ("open", "Deck_modeler")),
        ("Fabricar", "Fabricar", "plus", ("open", "Deck_fabricar")),
        ("Insert", "Insert...", "chevD", ("open", "V2_ArkherInsert")),
        ("Base", "Baseplate", "square", ("bus", "EnsureBase", {})),
        ("Union", "Union", "scaleI", ("bus", "CsgDo", {"op": "union"})),
        ("Negate", "Negate", "minus", ("bus", "CsgDo", {"op": "negate"})),
    ]),
    ("TERRAIN", [
        ("Terrain", "Terrain", "terrain", ("open", "V2_ArkherTerrainEditor")),
        ("TerrainX", "Terrain\nX", "globe", ("open", "Deck_terrain")),
        ("Sculpt", "Sculpt", "scaleI", ("open", "Deck_sculpt")),
        ("Water", "Water", "gem", ("open", "Deck_water")),
        ("Atmos", "Atmos", "bulb", ("open", "Deck_atmos")),
        ("Clima", "Clima", "share", ("open", "Deck_clima")),
    ]),
    ("ANIMATE", [
        ("Animator", "Animator", "play", ("open", "V2_ArkherAnimationEditor")),
        ("AnimX", "Anim\nX", "pause", ("open", "Deck_animator")),
        ("Timeline", "Timeline", "minus", ("open", "V2_ArkherTimeline")),
        ("Rig", "Rig", "pin", ("open", "Deck_rig")),
    ]),
    ("FX", [
        ("Particles", "Particles", "plus", ("open", "V2_ArkherParticleEditor")),
        ("VFX", "VFX", "emblem", ("open", "V2_ArkherVFXEditor")),
        ("FXLab", "FX\nLab", "dock", ("open", "Deck_fx")),
        ("Cordas", "Cordas", "share", ("open", "Deck_cordas")),
    ]),
    ("AUDIO", [
        ("Audio", "Audio", "play", ("open", "V2_ArkherAudioEditor")),
        ("AudioX", "Audio\nX", "pause", ("open", "Deck_audio")),
    ]),
    ("WORLD", [
        ("World", "World", "ws", ("open", "V2_ArkherWorldEditor")),
        ("Space", "Space", "camera", ("open", "Deck_espaco")),
        ("Vida", "Vida", "people", ("open", "Deck_vida")),
        ("City", "City", "boxG", ("open", "Deck_cidade")),
        ("Physics", "Physics", "transform", ("open", "V2_ArkherPhysicsEditor")),
        ("Navigate", "Navigate", "globe", ("open", "V2_ArkherNavigationEditor")),
    ]),
    ("SCRIPT", [
        ("Scripts", "Script\nEditor", "script", ("open", "V2_ArkherScriptEditor")),
        ("Console", "Console", "textA", ("open", "V2_ArkherConsole")),
        ("Debug", "Debug", "bulb", ("open", "V2_ArkherDebugger")),
        ("Profiler", "Profiler", "data", ("open", "V2_ArkherProfiler")),
        ("Terminal", "Terminal", "minus", ("open", "Deck_comando")),
        ("ScriptsX", "Scripts\nX", "folderP", ("open", "Deck_scripts")),
        ("Output", "Output", "chat", ("open", "Deck_output")),
        ("Py", "Python", "info", ("open", "Deck_py")),
    ]),
    ("DATA", [
        ("Data", "Data", "data", ("open", "V2_ArkherDataManager")),
        ("Lang", "Language", "globe", ("open", "V2_ArkherLocalization")),
        ("Packages", "Packages", "boxG", ("open", "V2_ArkherPackageManager")),
        ("Versions", "Versions", "chevD", ("open", "V2_ArkherVersionControl")),
        ("Props", "Props", "check", ("open", "Deck_props")),
        ("Colors", "Colors", "gem", ("open", "Deck_cores")),
        ("Cloud", "Cloud", "cloud", ("bus", "CloudQuick", {})),
    ]),
    ("AI", [
        ("Singularity", "Singularity", "emblem", ("open", "V2_ArkherAIEditor")),
        ("UTS", "UTS AI", "share", ("open", "V2_ArkherUTSAI")),
        ("Graph", "Graph", "transform", ("open", "V2_ArkherGraphEditor")),
        ("Nodes", "Nodes", "pin", ("open", "V2_ArkherNodeEditor")),
        ("Visual", "Visual", "lock", ("open", "V2_ArkherVisualScripting")),
        ("Shader", "Shader", "camera", ("open", "V2_ArkherShaderEditor")),
        ("Docs", "Docs", "info", ("open", "V2_ArkherDocs")),
    ]),
    ("VIEW", [
        ("UIEdit", "UI\nEditor", "select", ("open", "V2_ArkherUIEditor")),
        ("Layouts", "Layouts", "dock", ("open", "V2_ArkherLayouts")),
        ("Alerts", "Alerts", "playersI", ("open", "V2_ArkherNotifications")),
        ("Collab", "Collab", "people", ("open", "V2_ArkherCollaboration")),
        ("Project", "Project", "folder", ("open", "V2_ArkherProjectSettings")),
        ("Build", "Build", "plus", ("open", "V2_ArkherBuildSettings")),
        ("Plugins", "Plugins", "plugin", ("open", "V2_ArkherPluginManager")),
        ("Groups", "Groups", "lock", ("open", "Deck_grupos")),
        ("PluginsX", "Plugins\nX", "boxG", ("open", "Deck_plugins")),
        ("ToolX", "Tool\nX", "toolbox", ("open", "Deck_toolbox")),
        ("Play", "Play", "play", ("menus", "RunToggle")),
        ("Pause", "Pause", "pause", ("menus", "RunPause")),
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
        for bid, label, icon, _act in btns:
            n_btns += 1
            btn = N("TextButton", f"RibbonBtn_{t}_{bid}", {
                "Size": U2(0, 66, 0, 100), "Position": U2(0, 0, 0, 0),
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
