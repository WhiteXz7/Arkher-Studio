#!/usr/bin/env python3
"""Gera tools/shell2spec.json — a nova shell EN (mockup docs/UI_REFERENCE).

Design space 1568x882 (todos offsets). Formato de no == guix_spec.json
(cls/name/props/kids), consumido por inject_shell2.py (fork do inject_guix).
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# ---------------- helpers ----------------
def C(r, g, b):
    return {"c3": [r / 255.0, g / 255.0, b / 255.0]}

def P(x, y):
    return {"u2": [0.0, int(x), 0.0, int(y)]}

def S(w, h):
    return {"u2": [0.0, int(w), 0.0, int(h)]}

def N(cls, name, props, kids=None):
    return {"cls": cls, "name": name, "props": props, "kids": kids or []}

# ---------------- tema (mockup) ----------------
MENU_BG = C(10, 15, 28)
PANEL = C(17, 26, 46)
INSET = C(10, 18, 36)
BORDER = C(42, 58, 92)
BTN = C(28, 42, 72)
ACCENT = C(43, 139, 230)
TEXT = C(231, 240, 255)
MUTED = C(147, 165, 196)
GREEN = C(52, 211, 153)
RED = C(248, 113, 113)
GOLD = C(240, 185, 70)
FB = {"en": "Font.GothamBold"}
FG = {"en": "Font.Gotham"}
FC = {"en": "Font.Code"}
LEFT = {"en": "TextXAlignment.Left"}
CENTER = {"en": "TextXAlignment.Center"}

def corner(r=6):
    return N("UICorner", "Corner", {"CornerRadius": {"u1": [0.0, r]}})

def stroke(color=BORDER, t=1.0):
    return N("UIStroke", "Border",
             {"ApplyStrokeMode": {"en": "ApplyStrokeMode.Border"}, "Color": color, "Thickness": t})

def F(name, x, y, w, h, bg=PANEL, kids=None, extra=None):
    p = {"Position": P(x, y), "Size": S(w, h), "BackgroundColor3": bg,
         "BorderSizePixel": 0, "ClipsDescendants": True}
    if extra:
        p.update(extra)
    k = [corner(), stroke()] + list(kids or [])
    return N("Frame", name, p, k)

def B(name, x, y, w, h, text, bg=BTN, fg=TEXT, size=13, font=FG, align=CENTER, extra=None):
    p = {"Position": P(x, y), "Size": S(w, h), "Text": text,
         "BackgroundColor3": bg, "BorderSizePixel": 0,
         "TextColor3": fg, "TextSize": float(size), "Font": font,
         "TextXAlignment": align, "AutoButtonColor": True}
    if extra:
        p.update(extra)
    return N("TextButton", name, p, [corner(4)])

def L(name, x, y, w, h, text, fg=TEXT, size=13, font=FG, align=LEFT, bg=None):
    p = {"Position": P(x, y), "Size": S(w, h), "Text": text,
         "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
         "TextColor3": fg, "TextSize": float(size), "Font": font,
         "TextXAlignment": align, "TextTruncate": {"en": "TextTruncate.AtEnd"}}
    if bg is not None:
        p["BackgroundColor3"] = bg
        p["BackgroundTransparency"] = 0.0
    return N("TextLabel", name, p)

def T(name, x, y, w, h, placeholder="", text="", size=13):
    return N("TextBox", name,
             {"Position": P(x, y), "Size": S(w, h), "Text": text,
              "PlaceholderText": placeholder, "PlaceholderColor3": MUTED,
              "BackgroundColor3": INSET, "BorderSizePixel": 0,
              "TextColor3": TEXT, "TextSize": float(size), "Font": FG,
              "TextXAlignment": LEFT, "ClearTextOnFocus": False}, [corner(4)])

def SC(name, x, y, w, h, bg=INSET):
    return N("ScrollingFrame", name,
             {"Position": P(x, y), "Size": S(w, h),
              "BackgroundColor3": bg, "BorderSizePixel": 0,
              "CanvasSize": {"u2": [0.0, 0, 0.0, 0]},
              "ScrollBarImageColor3": BORDER, "ScrollBarThickness": 6,
              "AutomaticCanvasSize": {"en": "AutomaticSize.Y"}}, [corner(4)])

def title(text):
    return L("Title", 10, 6, 200, 20, text, GOLD, 13, FB)

def sep(x, y, h):
    return N("Frame", "Sep", {"Position": P(x, y), "Size": S(2, h),
                              "BackgroundColor3": BORDER, "BorderSizePixel": 0})

# ---------------- 1. menu bar ----------------
MENUS = [("M2_Assets", "Assets", 64), ("M2_Models", "Models", 64),
         ("M2_Terrain", "Terrain", 64), ("M2_Animation", "Animation", 82),
         ("M2_Audio", "Audio", 56), ("M2_Scripts", "Scripts", 64),
         ("M2_UI", "UI", 40), ("M2_FX", "FX", 44),
         ("M2_Lighting", "Lighting", 70), ("M2_Gameplay", "Gameplay", 80),
         ("M2_Physics", "Physics", 66), ("M2_Tools", "Tools", 56)]
menu_kids = [L("M2_Logo", 8, 5, 150, 24, "⬢  ARKHER STUDIO", GOLD, 13, FB)]
mx = 170
for name, text, w in MENUS:
    menu_kids.append(B(name, mx, 4, w, 26, text, MENU_BG, TEXT, 13, FG))
    mx += w + 4
menu_kids += [T("M2_Search", 1238, 5, 200, 24, "Search tools, assets..."),
              B("M2_Bell", 1444, 4, 28, 26, "🔔", MENU_BG, TEXT, 14),
              B("M2_User", 1476, 4, 86, 26, "● dev", MENU_BG, GREEN, 12, FB)]
menu = N("Frame", "MenuBar2",
         {"Position": P(0, 0), "Size": S(1568, 34),
          "BackgroundColor3": MENU_BG, "BorderSizePixel": 0,
          "ClipsDescendants": True}, menu_kids)

# ---------------- 2. ribbon ----------------
RIBBON = [("R2_Select", "⌖\nSelect", 64), ("R2_Move", "✥\nMove", 64),
          ("R2_Scale", "⛶\nScale", 64), ("R2_Rotate", "⟳\nRotate", 64), None,
          ("R2_Play", "▶\nPlay", 64), ("R2_Pause", "⏸\nPause", 64),
          ("R2_Stop", "⏹\nStop", 64), None,
          ("R2_Undo", "↩\nUndo", 64), ("R2_Redo", "↪\nRedo", 64), None,
          ("R2_Terrain", "⛰\nTerrain", 70), ("R2_Insert", "＋\nInsert", 70),
          ("R2_Script", "📜\nScript", 70), ("R2_UI", "🖼\nUI", 60),
          ("R2_Animate", "🎬\nAnimate", 70), ("R2_FX", "✨\nFX", 60), None,
          ("R2_Save", "💾\nSave", 70), ("R2_Publish", "☁\nPublish", 80)]
ribbon_kids = []
rx = 8
for item in RIBBON:
    if item is None:
        ribbon_kids.append(sep(rx, 43, 70))
        rx += 8
        continue
    name, text, w = item
    ribbon_kids.append(B(name, rx, 38, w, 78, text, PANEL, TEXT, 12, FG))
    rx += w + 4
ribbon_kids.append(B("R2_Anchor", 1242, 38, 70, 78, "⚓\nAnchor", PANEL, TEXT, 12, FG))
ribbon_kids.append(B("R2_Snap", 1316, 38, 70, 78, "🧲\nSnap", PANEL, TEXT, 12, FG))
ribbon_kids.append(B("R2_Group", 1390, 38, 70, 78, "🗂\nGroup", PANEL, TEXT, 12, FG))
ribbon_kids.append(B("R2_Help", 1480, 38, 70, 78, "❓\nHelp", PANEL, TEXT, 12, FG))
ribbon = N("Frame", "Ribbon2",
           {"Position": P(0, 34), "Size": S(1568, 86),
            "BackgroundColor3": PANEL, "BorderSizePixel": 0,
            "ClipsDescendants": True}, ribbon_kids)

# ---------------- 3. terrain panel ----------------
# ---------------- 3. terrain panel ----------------
terrain_btns = [("T2_Generate", "Generate"), ("T2_Erosion", "Erosion"),
                ("T2_Craters", "Craters"), ("T2_Flatten", "Flatten"),
                ("T2_Smooth", "Smooth"), ("T2_Noise", "Noise")]
tkids = [title("⛰ TERRAIN")]
for i, (nm, tx) in enumerate(terrain_btns):
    tkids.append(B(nm, 8 + (i % 3) * 92, 28 + (i // 3) * 32, 88, 28, tx, BTN, TEXT, 12))
tkids += [L("T2_SizeL", 8, 94, 52, 22, "Size", MUTED, 12),
          B("T2_SizeMinus", 64, 94, 28, 22, "−"),
          L("T2_SizeVal", 94, 94, 52, 22, "16", TEXT, 12, FC, CENTER, INSET),
          B("T2_SizePlus", 148, 94, 28, 22, "+"),
          B("T2_Auto", 182, 94, 94, 22, "Auto: OFF", BTN, MUTED, 12),
          L("T2_StrL", 8, 120, 52, 22, "Force", MUTED, 12),
          B("T2_StrMinus", 64, 120, 28, 22, "−"),
          L("T2_StrVal", 94, 120, 52, 22, "50", TEXT, 12, FC, CENTER, INSET),
          B("T2_StrPlus", 148, 120, 28, 22, "+")]
terrain = F("T2_Panel", 8, 353, 284, 150, PANEL, tkids)

# ---------------- 4. console panel ----------------
ckids = [title("CONSOLE"), B("C2_Clear", 230, 4, 46, 20, "Clear", BTN, TEXT, 11)]
for i, (nm, tx) in enumerate([("C2_All", "All"), ("C2_Info", "Info"),
                              ("C2_Warn", "Warn"), ("C2_Error", "Error")]):
    ckids.append(B(nm, 8 + i * 56, 28, 52, 20, tx, BTN, TEXT, 11))
ckids.append(SC("C2_Log", 8, 54, 268, 102))
console = F("C2_Panel", 8, 511, 284, 164, PANEL, ckids)

# ---------------- 5. selection panel ----------------
skids = [title("SELECTION"),
         L("S2_Name", 8, 30, 268, 20, "Name: —", TEXT, 12, FC),
         L("S2_Class", 8, 52, 268, 20, "Class: —", MUTED, 12, FC),
         L("S2_Pos", 8, 74, 268, 20, "Pos: —", MUTED, 12, FC),
         L("S2_Size", 8, 96, 268, 20, "Size: —", MUTED, 12, FC)]
selection = F("S2_Panel", 8, 683, 284, 128, PANEL, skids)

# ---------------- 6. viewport overlays ----------------
crumb = L("O2_Crumb", 308, 128, 240, 26, "Workspace", TEXT, 12, FC, LEFT, INSET)
compass = L("O2_Compass", 650, 128, 130, 26, "▲ N · 000°", TEXT, 12, FC, CENTER, INSET)
coords = L("O2_Coords", 930, 128, 170, 26, "X:0 Y:0 Z:0", TEXT, 11, FC, CENTER, INSET)
play = B("O2_Play", 684, 158, 40, 40, "▶", ACCENT, TEXT, 18)
layer_names = ["Terrain", "Water", "Vegetation", "Roads", "Buildings", "NPCs"]
lkids = [L("Title", 8, 6, 138, 18, "LAYERS", GOLD, 12, FB)]
for i, nm in enumerate(layer_names):
    lkids.append(B("O2_Layer_" + nm, 8, 30 + i * 22, 138, 20,
                   "☑ " + nm, BTN, TEXT, 11, FG, LEFT))
layers = F("O2_Layers", 946, 200, 154, 172, PANEL, lkids)
region = F("O2_Region", 308, 300, 150, 104, PANEL,
           [L("O2_RegionTitle", 8, 6, 134, 20, "◉ WORLD", GOLD, 12, FB),
            L("O2_RegionL1", 8, 30, 134, 20, "—", TEXT, 11, FC),
            L("O2_RegionL2", 8, 52, 134, 20, "—", MUTED, 11, FC),
            L("O2_RegionL3", 8, 74, 134, 20, "—", MUTED, 11, FC)])
mapp = F("O2_Map", 946, 420, 154, 100, PANEL,
         [L("Title", 8, 6, 138, 18, "🌐 WORLD", GOLD, 12, FB),
          B("O2_ZoomIn", 8, 30, 70, 26, "＋", BTN, TEXT, 14),
          B("O2_ZoomOut", 82, 30, 64, 26, "－", BTN, TEXT, 14),
          L("O2_Fov", 8, 62, 138, 22, "FOV: 70", TEXT, 12, FC, CENTER)])
gkids = []
for i, (nm, tx) in enumerate([("O2_G_Move", "✥"), ("O2_G_Rotate", "⟳"),
                              ("O2_G_Scale", "⛶"), ("O2_G_Grid", "▦"),
                              ("O2_G_Snap", "🧲")]):
    gkids.append(B(nm, 8 + i * 44, 6, 40, 28, tx, BTN, TEXT, 15))
gizmo = F("O2_Gizmo", 308, 524, 236, 40, PANEL, gkids)

# ---------------- 7. timeline ----------------
tlkids = [title("🎬 TIMELINE"),
          L("TL2_Time", 150, 6, 220, 20, "00:00:00 / 00:01:00", TEXT, 12, FC),
          B("TL2_Snap", 380, 4, 60, 22, "Snap", BTN, TEXT, 11),
          B("TL2_Prev", 450, 4, 30, 22, "⏮", BTN, TEXT, 12),
          B("TL2_Play", 484, 4, 30, 22, "▶", ACCENT, TEXT, 12),
          B("TL2_Stop", 518, 4, 30, 22, "⏹", BTN, TEXT, 12),
          B("TL2_Next", 552, 4, 30, 22, "⏭", BTN, TEXT, 12),
          B("TL2_Loop", 586, 4, 44, 22, "Loop", BTN, MUTED, 11),
          B("TL2_Rec", 634, 4, 44, 22, "●", BTN, RED, 12),
          N("Frame", "TL2_Ruler",
            {"Position": P(8, 30), "Size": S(792, 16),
             "BackgroundColor3": INSET, "BorderSizePixel": 0,
             "ClipsDescendants": True})]
for i, nm in enumerate(["Camera 1", "Light", "Char"]):
    tlkids.append(L("TL2_Track%d" % (i + 1), 8, 50 + i * 24, 90, 20, nm, MUTED, 11))
    tlkids.append(F("TL2_Lane%d" % (i + 1), 102, 50 + i * 24, 698, 20, INSET))
timeline = F("TL2_Panel", 300, 575, 808, 125, PANEL, tlkids)

# ---------------- 8. curves ----------------
curves = F("CV2_Panel", 300, 700, 808, 111, PANEL,
           [title("CURVES"),
            L("CV2_Track", 150, 6, 220, 20, "Track: Camera 1", MUTED, 12),
            F("CV2_Canvas", 8, 30, 792, 56, INSET),
            L("CV2_Caption", 8, 90, 792, 16, "keys: 0", MUTED, 11, FC)])

# ---------------- 9. simulation ----------------
sim = F("SM2_Panel", 1116, 553, 264, 104, PANEL,
        [title("SIMULATION"),
         B("SM2_Day", 8, 30, 124, 22, "Day Cycle: OFF", BTN, TEXT, 11),
         B("SM2_Physics", 136, 30, 120, 22, "Physics: ON", BTN, TEXT, 11),
         B("SM2_Water", 8, 56, 124, 22, "Water FX: ON", BTN, TEXT, 11),
         B("SM2_Ambient", 136, 56, 120, 22, "Ambient: DAY", BTN, TEXT, 11),
         B("SM2_Start", 8, 80, 124, 20, "▶ Start", ACCENT, TEXT, 12, FB),
         L("SM2_Status", 136, 80, 120, 20, "idle", MUTED, 11)])

# ---------------- 10. team ----------------
team = F("TM2_Panel", 1116, 665, 264, 146, PANEL,
         [L("TM2_Title", 10, 6, 200, 20, "TEAM (1)", GOLD, 13, FB),
          F("TM2_List", 8, 30, 248, 78, INSET),
          B("TM2_Invite", 8, 112, 248, 26, "＋ Invite", BTN, TEXT, 13)])

# ---------------- 11. far-right ----------------
frkids = [B("FR2_TabAssets", 6, 6, 36, 26, "▦", ACCENT, TEXT, 14),
          B("FR2_TabLibrary", 46, 6, 36, 26, "📚", BTN, TEXT, 14),
          B("FR2_TabCloud", 86, 6, 36, 26, "☁", BTN, TEXT, 14),
          B("FR2_TabTools", 126, 6, 32, 26, "🛠", BTN, TEXT, 14),
          T("FR2_AssetSearch", 6, 38, 152, 22, "Search assets")]
for i, (nm, tx) in enumerate([("FR2_A_Tree", "🌳 Tree"), ("FR2_A_Crate", "📦 Crate"),
                              ("FR2_A_Lamp", "💡 Lamp"), ("FR2_A_Car", "🚗 Car"),
                              ("FR2_A_Coin", "🪙 Coin"), ("FR2_A_NPC", "🧍 NPC")]):
    frkids.append(B(nm, 6 + (i % 2) * 78, 64 + (i // 2) * 38, 74, 34, tx, BTN, TEXT, 12))
frkids.append(L("FR2_LibTitle", 6, 178, 152, 16, "LIBRARY", MUTED, 11, FB))
for i, nm in enumerate(["House", "Bridge", "Tower", "Fountain", "Portal"]):
    frkids.append(B("FR2_L_" + nm, 6, 196 + i * 22, 152, 20,
                    "★ " + nm, BTN, TEXT, 12, FG, LEFT))
frkids.append(L("FR2_ResTitle", 6, 310, 152, 16, "RESOURCES", MUTED, 11, FB))
frkids += [B("FR2_Export", 6, 330, 74, 26, "⇪ Export", BTN, TEXT, 12),
           B("FR2_Import", 84, 330, 74, 26, "⇩ Import", BTN, TEXT, 12),
           B("FR2_Backup", 6, 360, 74, 26, "💾 Backup", BTN, TEXT, 12),
           B("FR2_Sync", 84, 360, 74, 26, "🔄 Sync", BTN, TEXT, 12)]
frkids.append(F("FR2_Storage", 6, 392, 152, 10, INSET,
                [N("Frame", "FR2_StorageFill",
                   {"Position": P(0, 0), "Size": S(60, 10),
                    "BackgroundColor3": GREEN, "BorderSizePixel": 0})]))
frkids.append(L("FR2_StorageLabel", 6, 404, 152, 14, "Cloud: —", MUTED, 11))
frkids.append(L("FR2_QuickTitle", 6, 422, 152, 16, "QUICK TOOLS", MUTED, 11, FB))
for i, tx in enumerate(["🧱", "💡", "🔊", "🎥", "✨", "🌊", "🌳", "🚗", "⭐"]):
    frkids.append(B("FR2_Q%d" % (i + 1), 6 + (i % 3) * 52, 440 + (i // 3) * 40,
                    48, 36, tx, BTN, TEXT, 16))
farright = F("FR2_Panel", 1396, 128, 164, 560, PANEL, frkids)
farhelp = F("FR2_Help", 1396, 696, 164, 115, PANEL,
            [L("Title", 8, 6, 148, 18, "KEYS", GOLD, 12, FB),
             L("K1", 8, 30, 148, 18, "F5 Play · F8 UI", MUTED, 11),
             L("K2", 8, 50, 148, 18, "Del Delete · Esc", MUTED, 11),
             L("K3", 8, 70, 148, 18, "Ctrl+S Save", MUTED, 11),
             L("K4", 8, 90, 148, 18, "Ctrl+Z Undo", MUTED, 11)])

# ---------------- 12. footer ----------------
footer = [B("F2_Out", 8, 823, 70, 26, "☰ Output", BTN, TEXT, 12),
          B("F2_Err", 82, 823, 70, 26, "⚠ Errors", BTN, TEXT, 12),
          L("F2_LogLine", 160, 823, 700, 26, "—", MUTED, 12, FC),
          B("F2_Project", 870, 823, 160, 26, "▼ MyProject", BTN, TEXT, 12),
          L("F2_SaveState", 1040, 823, 200, 26, "Saved —", MUTED, 12),
          L("F2_FPS", 1250, 823, 60, 26, "60", GREEN, 12, FB, CENTER),
          L("F2_Ping", 1314, 823, 60, 26, "0ms", TEXT, 12, FB, CENTER),
          L("F2_Mem", 1378, 823, 60, 26, "0MB", TEXT, 12, FB, CENTER),
          B("F2_Publish", 1442, 823, 118, 26, "☁ Publish", ACCENT, TEXT, 13, FB)]

desktop_kids = ([menu, ribbon, terrain, console, selection, crumb, compass, coords,
          play, layers, region, mapp, gizmo, timeline, curves, sim, team,
          farright, farhelp] + footer)
desktop = N("Frame", "DesktopRoot",
            {"Position": P(0, 0), "Size": S(1568, 882),
             "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
             "ClipsDescendants": False, "Visible": True}, desktop_kids)

# ---------------- 13. mobile layout (touch-first, baked) ----------------
mtop_kids = [B("M_MenuBtn", 8, 8, 64, 48, "☰", BTN, TEXT, 22),
             L("M_Title", 80, 8, 300, 48, "⬢ ARKHER · MOBILE", GOLD, 16, FB),
             L("M_Mode", 400, 8, 340, 48, "MODE: SELECT", GREEN, 16, FB),
             B("M_Undo", 1150, 8, 64, 48, "↩", BTN, TEXT, 20),
             B("M_Redo", 1218, 8, 64, 48, "↪", BTN, TEXT, 20),
             B("M_Save", 1286, 8, 64, 48, "💾", BTN, TEXT, 20),
             B("M_Play", 1354, 8, 64, 48, "▶", ACCENT, TEXT, 20),
             B("M_Stop", 1422, 8, 64, 48, "⏹", BTN, TEXT, 20)]
mtop = F("M_Top", 0, 0, 1568, 64, MENU_BG, mtop_kids)
mtool_defs = [("M_T_Select", "⌖\nSELECT"), ("M_T_Move", "✥\nMOVE"),
              ("M_T_Rotate", "⟳\nROTATE"), ("M_T_Scale", "⛶\nSCALE"),
              ("M_T_Camera", "🎥\nCAMERA"), ("M_T_Insert", "＋\nINSERT"),
              ("M_T_Snap", "🧲\nSNAP"), ("M_T_Props", "⚙\nPROPS")]
mtool_kids = []
for i, (nm, tx) in enumerate(mtool_defs):
    mtool_kids.append(B(nm, 6, 6 + i * 78, 88, 72, tx, BTN, TEXT, 13, FB))
mtools = F("M_Tools", 0, 70, 100, 640, PANEL, mtool_kids)
mdrawer_kids = [title("TOOLS"), B("M_DrawerClose", 296, 4, 56, 26, "✕", BTN, TEXT, 14)]
mcat_defs = ["Select", "Build", "Terrain", "Model", "Paint", "Light", "FX",
             "Sound", "UI", "Animate", "Physics", "Game", "Cloud"]
for i, cnm in enumerate(mcat_defs):
    mdrawer_kids.append(B("M_Cat_" + cnm, 8 + (i % 2) * 172, 34 + (i // 2) * 56,
                          168, 50, cnm, BTN, TEXT, 14, FB))
mdrawer = F("M_Drawer", 104, 70, 360, 640, PANEL, mdrawer_kids,
            {"Visible": False})
mprops = F("M_PropsP", 1144, 70, 424, 640, PANEL,
           [title("PROPERTIES"), B("M_PropsClose", 356, 4, 60, 26, "✕", BTN, TEXT, 14),
            B("M_PropsOpen", 8, 34, 408, 64, "OPEN PROPERTIES +", ACCENT, TEXT, 16, FB),
            L("M_PropsHint", 8, 106, 408, 60, "opens the real Properties panel (same data as desktop)", MUTED, 12)], {"Visible": False})
mnum_kids = [title("TRANSFORM"), B("M_N_Close", 492, 4, 60, 26, "✕", BTN, TEXT, 14)]
for i, ax in enumerate(["X", "Y", "Z"]):
    mnum_kids += [L("M_N_%sL" % ax, 8, 34 + i * 40, 30, 32, ax, GOLD, 16, FB, CENTER),
                  B("M_N_%sMinus" % ax, 44, 34 + i * 40, 60, 32, "−", BTN, TEXT, 20),
                  L("M_N_%sVal" % ax, 108, 34 + i * 40, 120, 32, "0", TEXT, 16, FC, CENTER, INSET),
                  B("M_N_%sPlus" % ax, 232, 34 + i * 40, 60, 32, "+", BTN, TEXT, 20)]
mnum_kids += [B("M_N_Rot", 304, 34, 120, 32, "ROTATE", BTN, TEXT, 13, FB),
              B("M_N_Size", 428, 34, 120, 32, "SIZE", BTN, TEXT, 13, FB),
              B("M_N_Axis", 304, 74, 244, 32, "AXIS: X", BTN, TEXT, 14, FB),
              B("M_N_Apply", 304, 114, 120, 40, "✓ APPLY", ACCENT, TEXT, 15, FB),
              B("M_N_Cancel", 428, 114, 120, 40, "✕", BTN, TEXT, 18),
              B("M_N_Reset", 304, 158, 244, 32, "RESET", BTN, MUTED, 13)]
mnum = F("M_Numeric", 504, 566, 560, 210, PANEL, mnum_kids, {"Visible": False})
msel = L("M_Sel", 108, 716, 500, 34, "Selection: —", TEXT, 14, FC, LEFT, INSET)
mhelp = L("M_Help", 1050, 716, 510, 34, "tap=select · 2×tap=frame · pinch=zoom", MUTED, 12, FG)
mbot_kids = [B("M_B_Confirm", 8, 8, 200, 80, "✓ CONFIRM", ACCENT, TEXT, 18, FB),
             B("M_B_Cancel", 212, 8, 140, 80, "✕", BTN, RED, 24),
             B("M_B_Undo", 356, 8, 110, 80, "↩", BTN, TEXT, 22),
             B("M_B_Prec", 470, 8, 190, 80, "🎯 PRECISION", BTN, TEXT, 15, FB),
             B("M_B_Snap", 664, 8, 150, 80, "🧲 SNAP", BTN, TEXT, 15, FB),
             B("M_B_Axis", 818, 8, 170, 80, "AXIS: X", BTN, TEXT, 16, FB),
             B("M_B_Space", 992, 8, 170, 80, "SPACE: LOCAL", BTN, TEXT, 14, FB),
             L("M_B_Hint", 1170, 8, 390, 80, "contextual actions appear here", MUTED, 12, FG)]
mbot = F("M_Bottom", 0, 786, 1568, 96, MENU_BG, mbot_kids)
mobile = N("Frame", "MobileRoot",
           {"Position": P(0, 0), "Size": S(1568, 882),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "ClipsDescendants": False, "Visible": False},
           [mtop, mtools, mdrawer, mprops, mnum, msel, mhelp, mbot])

# ---------------- 14. console layout (gamepad-first, baked) ----------------
ctop = F("C_Top", 0, 0, 1568, 56, MENU_BG,
         [B("C_Menu", 8, 6, 130, 44, "☰ MENU", BTN, TEXT, 15, FB),
          L("C_Title", 146, 6, 320, 44, "⬢ ARKHER · CONSOLE", GOLD, 15, FB),
          L("C_Tool", 600, 6, 340, 44, "TOOL: SELECT", GREEN, 15, FB),
          L("C_Mode", 960, 6, 340, 44, "MODE: EDITOR", TEXT, 15, FB),
          B("C_Props", 1430, 6, 130, 44, "⚙ PROPS", BTN, TEXT, 15, FB)])
crad_kids = [L("C_R_Title", 80, 8, 200, 30, "RADIAL", GOLD, 14, FB, CENTER)]
crad_pos = [(130, 44), (220, 100), (220, 200), (130, 256), (40, 200), (40, 100)]
for i, (cx, cy) in enumerate(crad_pos):
    crad_kids.append(B("C_R_%d" % i, cx, cy, 100, 52, "···", BTN, TEXT, 13, FB))
cradial = F("C_Radial", 604, 200, 360, 330, PANEL, crad_kids, {"Visible": False})
ccursor = L("C_Cursor", 770, 425, 32, 32, "＋", GREEN, 24, FB, CENTER)
cpanel = F("C_Panel", 1180, 160, 388, 500, PANEL,
           [title("PROPERTIES"), B("C_PropsOpen", 8, 34, 372, 64, "OPEN PROPERTIES +", ACCENT, TEXT, 16, FB),
            L("C_P_Hint", 8, 106, 372, 60, "same Properties data as desktop · ▲▼ navigate · Ⓐ edit", MUTED, 12)],
           {"Visible": False})
clegend = F("C_Legend", 0, 826, 1568, 56, MENU_BG,
            [L("C_Leg1", 8, 6, 760, 44, "Ⓐ confirm · Ⓑ cancel · Ⓧ tool · Ⓨ menu", TEXT, 14),
             L("C_Leg2", 800, 6, 760, 44, "LB/RB cycle · LT/RT orbit · sticks move", MUTED, 14)])
cnum_kids = [title("TRANSFORM")]
for i, ax in enumerate(["X", "Y", "Z"]):
    cnum_kids += [L("C_N_%sL" % ax, 8, 34 + i * 40, 30, 32, ax, GOLD, 16, FB, CENTER),
                  B("C_N_%sMinus" % ax, 44, 34 + i * 40, 60, 32, "\u2212", BTN, TEXT, 20),
                  L("C_N_%sVal" % ax, 108, 34 + i * 40, 120, 32, "0", TEXT, 16, FC, CENTER, INSET),
                  B("C_N_%sPlus" % ax, 232, 34 + i * 40, 60, 32, "+", BTN, TEXT, 20)]
cnum_kids += [B("C_N_Mode", 304, 34, 244, 40, "MODE: POS", BTN, TEXT, 14, FB),
              B("C_N_Apply", 304, 82, 120, 40, "\u2713 APPLY", ACCENT, TEXT, 15, FB),
              B("C_N_Cancel", 428, 82, 120, 40, "\u2715", BTN, TEXT, 18)]
cnumeric = F("C_Numeric", 504, 566, 560, 210, PANEL, cnum_kids, {"Visible": False})
cons = N("Frame", "ConsoleRoot",
         {"Position": P(0, 0), "Size": S(1568, 882),
          "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
          "ClipsDescendants": False, "Visible": False},
         [ctop, cradial, ccursor, cpanel, clegend, cnumeric])

# ---------------- 15. vr layout (minimal spatial-ready, baked) ----------------
vtool_defs = [("V_T_Select", "⌖ SELECT"), ("V_T_Move", "✥ MOVE"),
              ("V_T_Rotate", "⟳ ROTATE"), ("V_T_Scale", "⛶ SCALE"),
              ("V_T_Camera", "🎥 CAMERA"), ("V_T_Insert", "＋ INSERT")]
vpanel_kids = [L("V_Title", 10, 6, 500, 28, "🥽 ARKHER VR", GOLD, 16, FB, CENTER),
               L("V_Status", 10, 36, 500, 24, "right hand: ray · left hand: panel", MUTED, 12, FG, CENTER)]
for i, (nm, tx) in enumerate(vtool_defs):
    vpanel_kids.append(B(nm, 14 + (i % 3) * 168, 66 + (i // 3) * 72, 160, 64, tx, BTN, TEXT, 14, FB))
vpanel_kids += [B("V_Confirm", 14, 216, 244, 56, "✓ CONFIRM", ACCENT, TEXT, 16, FB),
                B("V_Cancel", 262, 216, 244, 56, "✕ CANCEL", BTN, RED, 16, FB),
                B("V_Prec", 14, 280, 160, 52, "🎯 PRECISION", BTN, TEXT, 13, FB),
                B("V_Snap", 178, 280, 160, 52, "🧲 SNAP", BTN, TEXT, 13, FB),
                B("V_Teleport", 342, 280, 164, 52, "📍 TELEPORT", BTN, TEXT, 13, FB),
                L("V_Sel", 14, 340, 492, 28, "Selection: —", TEXT, 13, FC, CENTER),
                L("V_Hint", 14, 372, 492, 28, "trigger=select · grip=move · A=confirm", MUTED, 12, FG, CENTER)]
vpanel = F("V_Panel", 524, 220, 520, 408, PANEL, vpanel_kids)
vcross = L("V_Cross", 772, 431, 24, 24, "·", GREEN, 20, FB, CENTER)
vr = N("Frame", "VRoot",
       {"Position": P(0, 0), "Size": S(1568, 882),
        "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
        "ClipsDescendants": False, "Visible": False}, [vpanel, vcross])

roots = [desktop, mobile, cons, vr]


spec = {"host_scale": 1.0, "roots": roots}
out = os.path.join(HERE, "shell2spec.json")
json.dump(spec, open(out, "w", encoding="utf-8"), ensure_ascii=False)


def count(ns):
    n = 0
    for x in ns:
        n += 1 + count(x["kids"])
    return n


print("shell2spec: %d nos em %d raizes -> %s" % (count(roots), len(roots), out))
