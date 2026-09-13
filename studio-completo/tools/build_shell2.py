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

def B(name, x, y, w, h, text, bg=BTN, fg=TEXT, size=13, font=FG, align=CENTER, extra=None, kids=None):
    p = {"Position": P(x, y), "Size": S(w, h), "Text": text,
         "BackgroundColor3": bg, "BorderSizePixel": 0,
         "TextColor3": fg, "TextSize": float(size), "Font": font,
         "TextXAlignment": align, "AutoButtonColor": True}
    if extra:
        p.update(extra)
    return N("TextButton", name, p, [corner(4)] + list(kids or []))

def L(name, x, y, w, h, text, fg=TEXT, size=13, font=FG, align=LEFT, bg=None):
    p = {"Position": P(x, y), "Size": S(w, h), "Text": text,
         "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
         "TextColor3": fg, "TextSize": float(size), "Font": font,
         "TextXAlignment": align, "TextTruncate": {"en": "TextTruncate.AtEnd"}}
    if bg is not None:
        p["BackgroundColor3"] = bg
        p["BackgroundTransparency"] = 0.0
    return N("TextLabel", name, p)

def T(name, x, y, w, h, placeholder="", text="", size=13, extra=None):
    p = {"Position": P(x, y), "Size": S(w, h), "Text": text,
         "PlaceholderText": placeholder, "PlaceholderColor3": MUTED,
         "BackgroundColor3": INSET, "BorderSizePixel": 0,
         "TextColor3": TEXT, "TextSize": float(size), "Font": FG,
         "TextXAlignment": LEFT, "ClearTextOnFocus": False}
    if extra:
        p.update(extra)
    return N("TextBox", name, p, [corner(4)])

def SC(name, x, y, w, h, bg=INSET, kids=None):
    return N("ScrollingFrame", name,
             {"Position": P(x, y), "Size": S(w, h),
              "BackgroundColor3": bg, "BorderSizePixel": 0,
              "CanvasSize": {"u2": [0.0, 0, 0.0, 0]},
              "ScrollBarImageColor3": BORDER, "ScrollBarThickness": 6,
              "AutomaticCanvasSize": {"en": "AutomaticSize.Y"}}, [corner(4)] + list(kids or []))

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

# ---------------- 14. TERRAIN EDITOR R10 (engine UI, icones vetoriais, sem emoji) ----------------
def IC(nm, x, y, w, h, c, circ=False, rot=0):
    p = {"Position": P(x, y), "Size": S(w, h), "BackgroundColor3": c, "BorderSizePixel": 0}
    if rot:
        p["Rotation"] = float(rot)
    k = [N("UICorner", "Corner", {"CornerRadius": {"u1": [0.5, 0.0]}})] if circ else []
    return N("Frame", nm, p, k)

ICONS = {
    "draw": [IC("i", 20, 12, 16, 16, ACCENT, True)],
    "sculpt": [IC("o", 20, 12, 16, 16, TEXT, True), IC("i", 24, 16, 8, 8, BTN, True)],
    "raise": [IC("b", 26, 14, 4, 12, TEXT), IC("h", 24, 8, 8, 8, TEXT, False, 45)],
    "lower": [IC("b", 26, 14, 4, 12, TEXT), IC("h", 24, 24, 8, 8, TEXT, False, 45)],
    "flatten": [IC("b", 16, 18, 24, 4, ACCENT)],
    "smooth": [IC("d1", 18, 18, 5, 5, TEXT, True), IC("d2", 25, 14, 5, 5, TEXT, True), IC("d3", 32, 18, 5, 5, TEXT, True)],
    "erode": [IC("d1", 20, 12, 4, 4, MUTED), IC("d2", 28, 16, 3, 3, MUTED), IC("d3", 22, 22, 3, 3, MUTED), IC("d4", 30, 24, 4, 4, MUTED)],
    "crater": [IC("o", 18, 10, 20, 20, ACCENT, True), IC("i", 23, 15, 10, 10, BTN, True), IC("d", 26, 18, 4, 4, TEXT, True)],
    "paint": [IC("s", 20, 12, 16, 16, TEXT), IC("h", 20, 12, 16, 8, ACCENT)],
    "replace": [IC("a", 17, 14, 10, 12, TEXT), IC("b", 29, 14, 10, 12, ACCENT)],
    "water": [IC("w1", 17, 15, 22, 3, ACCENT), IC("w2", 19, 22, 20, 3, ACCENT)],
    "drain": [IC("b", 26, 10, 4, 10, TEXT), IC("h", 24, 16, 8, 8, TEXT, False, 45), IC("l", 18, 28, 20, 2, MUTED)],
    "undo": [IC("b", 22, 18, 12, 4, TEXT), IC("h", 18, 16, 8, 8, TEXT, False, 45)],
    "redo": [IC("b", 22, 18, 12, 4, TEXT), IC("h", 30, 16, 8, 8, TEXT, False, 45)],
}
ICON_X = [IC("x1", 20, 14, 16, 3, TEXT, False, 45), IC("x2", 20, 14, 16, 3, TEXT, False, -45)]

def SLIDER(prefix, x, y, w, name, val):
    trackw = w - 150
    return [L(prefix + "_Name", x, y, 80, 22, name, MUTED, 12, FB),
            B(prefix + "_Track", x + 82, y + 7, trackw, 8, "", INSET, TEXT, 11, FG, CENTER, {"AutoButtonColor": False}),
            B(prefix + "_Knob", x + 82, y + 1, 14, 20, "", ACCENT, TEXT, 11, FG, CENTER, {"AutoButtonColor": False}),
            L(prefix + "_Val", x + 86 + trackw, y, 60, 22, val, TEXT, 12, FC)]

HID = {"Visible": False}
rail_kids = [title("TERRAIN")]
for i, key in enumerate(["draw", "sculpt", "raise", "lower", "flatten", "smooth", "erode",
                         "crater", "paint", "replace", "water", "drain"]):
    rail_kids.append(B("TE3_T_" + key, 8, 30 + i * 44, 56, 40, "", BTN, TEXT, 11, FG, CENTER, None, ICONS[key]))
rail_kids.append(B("TE3_Close", 8, 30 + 12 * 44, 56, 32, "", BTN, TEXT, 11, FG, CENTER, None, ICON_X))
te3_rail = F("TE3_Rail", 8, 100, 72, 600, PANEL, rail_kids, HID)

brush_kids = [title("BRUSH")]
_by = 30
for prefix, nm, val in [("TE3_Size", "Size", "8"), ("TE3_Str", "Strength", "50"),
                        ("TE3_Fal", "Falloff", "50"), ("TE3_Har", "Hardness", "50"),
                        ("TE3_Noi", "Noise", "0")]:
    brush_kids += SLIDER(prefix, 8, _by, 256, nm, val)
    _by += 30
brush_kids.append(L("TE3_SymL", 8, 182, 70, 24, "Mirror", MUTED, 12, FB))
for i, s in enumerate(["None", "X", "Z", "XZ"]):
    brush_kids.append(B("TE3_Sym_" + s, 80 + i * 46, 182, 42, 24, s, BTN, TEXT, 11))
brush_kids.append(B("TE3_PlaneSet", 8, 212, 90, 26, "SET PLANE", BTN, TEXT, 11))
brush_kids.append(L("TE3_PlaneVal", 102, 212, 150, 26, "Y: --", TEXT, 12, FC))
brush_kids.append(L("TE3_SrcL", 8, 244, 70, 24, "Source", MUTED, 12, FB))
brush_kids.append(B("TE3_Src", 80, 244, 130, 24, "Grass", BTN, TEXT, 11))
te3_brush = F("TE3_Brush", 88, 100, 272, 280, PANEL, brush_kids, HID)

MATS21 = ["Grass", "LeafyGrass", "Ground", "Mud", "Sand", "Sandstone", "Rock", "Slate",
          "Basalt", "Limestone", "Pavement", "Concrete", "Brick", "Cobblestone", "Asphalt",
          "Salt", "Snow", "Ice", "Glacier", "CrackedLava", "WoodPlanks"]
mat_kids = [title("MATERIAL")]
for i, m in enumerate(MATS21):
    c, r = i % 6, i // 6
    mat_kids.append(B("TE3_M_" + m, 8 + c * 43, 30 + r * 43, 38, 38, "", BTN))
mat_kids.append(L("TE3_MatName", 8, 202, 256, 20, "Grass", GOLD, 12, FB))
te3_mat = F("TE3_Mat", 88, 388, 272, 232, PANEL, mat_kids, HID)

lay_rows = []
for i in range(8):
    lay_rows.append(F("TE3_LRow" + str(i), 0, i * 30, 330, 28, INSET, [
        B("TE3_LName" + str(i), 6, 4, 128, 20, "-", INSET, TEXT, 12, FB, LEFT),
        L("TE3_LOps" + str(i), 136, 4, 34, 20, "", MUTED, 11, FC),
        B("TE3_LShow" + str(i), 172, 3, 52, 22, "Hide", BTN, TEXT, 11),
        B("TE3_LClear" + str(i), 228, 3, 52, 22, "Clear", BTN, TEXT, 11),
        B("TE3_LDel" + str(i), 284, 3, 40, 22, "X", BTN, RED, 11)], HID))
lay_kids = [title("LAYERS"), SC("TE3_LScroll", 8, 28, 344, 150, INSET, lay_rows),
            T("TE3_LName", 8, 184, 120, 24, "layer name"),
            B("TE3_LSizeS", 132, 184, 34, 24, "S", BTN, TEXT, 11),
            B("TE3_LSizeM", 170, 184, 34, 24, "M", BTN, TEXT, 11),
            B("TE3_LSizeL", 208, 184, 34, 24, "L", BTN, TEXT, 11),
            B("TE3_LAdd", 250, 184, 102, 24, "ADD", ACCENT, TEXT, 11),
            L("TE3_LHint", 8, 212, 344, 20, "8 max - regions cannot overlap", MUTED, 11)]
te3_layers = F("TE3_Layers", 1200, 100, 360, 240, PANEL, lay_kids, HID)

his_kids = [title("HISTORY"),
            B("TE3_Undo", 8, 28, 120, 30, "UNDO", BTN, TEXT, 12, FB, CENTER, None, ICONS["undo"]),
            B("TE3_Redo", 136, 28, 120, 30, "REDO", BTN, TEXT, 12, FB, CENTER, None, ICONS["redo"]),
            L("TE3_Depth", 264, 28, 88, 30, "0/0", MUTED, 12, FC)]
for i in range(6):
    his_kids.append(L("TE3_H" + str(i), 8, 62 + i * 18, 344, 18, "", TEXT, 11, FC))
te3_history = F("TE3_History", 1200, 348, 360, 180, PANEL, his_kids, HID)

gen_kids = [title("GENERATE"),
            L("TE3_GSeedL", 8, 30, 60, 24, "Seed", MUTED, 12, FB),
            B("TE3_GSeedM", 70, 30, 30, 24, "-", BTN, TEXT, 14),
            L("TE3_GSeedV", 104, 30, 80, 24, "7", TEXT, 13, FC, CENTER),
            B("TE3_GSeedP", 188, 30, 30, 24, "+", BTN, TEXT, 14),
            L("TE3_GSizeL", 226, 30, 40, 24, "Size", MUTED, 12, FB),
            B("TE3_GSizeS", 268, 30, 28, 24, "S", BTN, TEXT, 11),
            B("TE3_GSizeM", 298, 30, 28, 24, "M", BTN, TEXT, 11),
            B("TE3_GSizeL", 328, 30, 28, 24, "L", BTN, TEXT, 11)]
gen_kids += SLIDER("TE3_GHei", 8, 58, 344, "Height", "48")
gen_kids += [L("TE3_GBioL", 8, 90, 60, 24, "Biome", MUTED, 12, FB),
             B("TE3_GBio", 70, 90, 130, 24, "meadow", BTN, TEXT, 12),
             L("TE3_GEroL", 208, 90, 60, 24, "Erosion", MUTED, 12, FB),
             B("TE3_GEroM", 268, 90, 28, 24, "-", BTN, TEXT, 14),
             L("TE3_GEroV", 298, 90, 28, 24, "1", TEXT, 13, FC, CENTER),
             B("TE3_GEroP", 328, 90, 28, 24, "+", BTN, TEXT, 14)]
gen_kids += SLIDER("TE3_GWat", 8, 122, 344, "Water", "OFF")
gen_kids += [B("TE3_Gen", 8, 154, 168, 30, "GENERATE", ACCENT, TEXT, 12, FB),
             B("TE3_Keep", 184, 154, 80, 30, "KEEP", BTN, GREEN, 12, FB),
             B("TE3_Discard", 268, 154, 84, 30, "UNDO", BTN, RED, 12, FB),
             L("TE3_GStat", 8, 188, 344, 36, "seed 7 - 128 - h48 - meadow", MUTED, 11, FC)]
te3_gen = F("TE3_Gen", 1200, 536, 360, 232, PANEL, gen_kids, HID)

wat_kids = [title("WATER & GROWTH")]
_wy = 30
for prefix, nm, val in [("TE3_WTra", "Clear", "0.30"), ("TE3_WRef", "Reflect", "1.00"),
                        ("TE3_WWav", "Waves", "0.00"), ("TE3_WSpd", "W.Speed", "10")]:
    wat_kids += SLIDER(prefix, 8, _wy, 250, nm, val)
    _wy += 30
wat_kids += [B("TE3_WC1", 8, 150, 60, 24, "TEAL", BTN, TEXT, 11),
             B("TE3_WC2", 72, 150, 60, 24, "BLUE", BTN, TEXT, 11),
             B("TE3_WC3", 136, 150, 60, 24, "GREEN", BTN, TEXT, 11),
             B("TE3_Decor", 200, 150, 100, 24, "GRASS: ON", BTN, TEXT, 11)]
wat_kids += SLIDER("TE3_Grass", 8, 180, 250, "G.Leng", "0.50")
wat_kids += [B("TE3_Rain", 280, 30, 150, 30, "RAIN: OFF", BTN, TEXT, 12, FB),
             L("TE3_FloodL", 280, 64, 60, 24, "Flood Y", MUTED, 12, FB),
             B("TE3_FloodM", 340, 64, 28, 24, "-", BTN, TEXT, 14),
             L("TE3_FloodV", 368, 64, 34, 24, "4", TEXT, 12, FC, CENTER),
             B("TE3_FloodP", 402, 64, 28, 24, "+", BTN, TEXT, 14),
             B("TE3_Flood", 280, 92, 150, 30, "FLOOD", ACCENT, TEXT, 12, FB),
             B("TE3_Hydro", 280, 126, 150, 30, "SCAN WATER", BTN, TEXT, 12, FB),
             L("TE3_HydroV", 280, 160, 150, 44, "no scan", MUTED, 11, FC)]
te3_water = F("TE3_Water", 376, 620, 440, 248, PANEL, wat_kids, HID)

te3_status = F("TE3_Status", 368, 100, 824, 30, PANEL,
               [L("TE3_StatL", 8, 5, 808, 20, "TERRAIN EDITOR", GOLD, 12, FB)], HID)

mte_kids = [B("M_TE_Prev", 8, 8, 64, 64, "<", BTN, TEXT, 24),
            L("M_TE_Tool", 80, 8, 200, 64, "DRAW", GOLD, 16, FB),
            B("M_TE_Next", 288, 8, 64, 64, ">", BTN, TEXT, 24),
            B("M_TE_SizeM", 360, 8, 64, 64, "-", BTN, TEXT, 24),
            L("M_TE_SizeV", 432, 8, 80, 64, "8", TEXT, 18, FC, CENTER),
            B("M_TE_SizeP", 520, 8, 64, 64, "+", BTN, TEXT, 24),
            B("M_TE_Mat", 592, 8, 150, 64, "Grass", BTN, TEXT, 14),
            L("M_TE_Hint", 750, 8, 500, 64, "drag on terrain to paint", MUTED, 13)]
mte = F("M_TE", 0, 690, 1568, 80, MENU_BG, mte_kids, HID)


# ---------------- 12b. viewport editor R11 (VP3) ----------------
vp3_rail_kids = [title("VIEW")]
for i, key in enumerate(["Select", "Move", "Rotate", "Scale", "Measure"]):
    vp3_rail_kids.append(B("VP3_T_" + key, 8, 30 + i * 44, 56, 40,
                           key[:3].upper(), BTN, TEXT, 12, FB))
vp3_rail_kids.append(B("VP3_Close", 8, 30 + 5 * 44, 56, 32, "X", BTN, RED, 14, FB))
vp3_rail = F("VP3_Rail", 8, 100, 72, 300, PANEL, vp3_rail_kids, HID)

vp3_cam_kids = [title("CAMERA"),
    B("VP3_CamFront", 8, 30, 62, 26, "FRONT", BTN, TEXT, 10, FB),
    B("VP3_CamTop", 74, 30, 62, 26, "TOP", BTN, TEXT, 10, FB),
    B("VP3_CamSide", 140, 30, 62, 26, "SIDE", BTN, TEXT, 10, FB),
    B("VP3_CamIso", 8, 60, 62, 26, "ISO", BTN, TEXT, 10, FB),
    B("VP3_CamOrbit", 74, 60, 128, 26, "ORBIT: OFF", BTN, TEXT, 10, FB),
    L("VP3_FovL", 8, 92, 60, 26, "FOV", MUTED, 11, FB),
    B("VP3_FovM", 70, 92, 40, 26, "-", BTN, TEXT, 14),
    L("VP3_FovV", 114, 92, 50, 26, "70", TEXT, 12, FC, CENTER, INSET),
    B("VP3_FovP", 168, 92, 40, 26, "+", BTN, TEXT, 14),
    B("VP3_Frame", 8, 124, 200, 30, "FRAME SELECTION", ACCENT, TEXT, 12, FB),
    B("VP3_RigSave", 8, 158, 98, 28, "SAVE RIG", BTN, TEXT, 11, FB),
    B("VP3_RigLoad", 110, 158, 98, 28, "LOAD RIG", BTN, TEXT, 11, FB),
    L("VP3_CamV", 8, 190, 200, 44, "cam -", MUTED, 11, FC)]
vp3_cam = F("VP3_Cam", 88, 100, 216, 244, PANEL, vp3_cam_kids, HID)

vp3_tm_kids = [title("MULTI"),
    B("VP3_TM_Move", 8, 30, 64, 26, "MOVE", ACCENT, TEXT, 10, FB),
    B("VP3_TM_Rot", 76, 30, 64, 26, "ROT", BTN, TEXT, 10, FB),
    B("VP3_TM_Scale", 144, 30, 64, 26, "SCALE", BTN, TEXT, 10, FB),
    L("VP3_TM_XL", 8, 62, 20, 26, "X", MUTED, 11, FB),
    B("VP3_TM_XM", 28, 62, 40, 26, "-", BTN, TEXT, 14),
    L("VP3_TM_XV", 72, 62, 72, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("VP3_TM_XP", 148, 62, 40, 26, "+", BTN, TEXT, 14),
    L("VP3_TM_YL", 8, 92, 20, 26, "Y", MUTED, 11, FB),
    B("VP3_TM_YM", 28, 92, 40, 26, "-", BTN, TEXT, 14),
    L("VP3_TM_YV", 72, 92, 72, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("VP3_TM_YP", 148, 92, 40, 26, "+", BTN, TEXT, 14),
    L("VP3_TM_ZL", 8, 122, 20, 26, "Z", MUTED, 11, FB),
    B("VP3_TM_ZM", 28, 122, 40, 26, "-", BTN, TEXT, 14),
    L("VP3_TM_ZV", 72, 122, 72, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("VP3_TM_ZP", 148, 122, 40, 26, "+", BTN, TEXT, 14),
    B("VP3_TM_Apply", 8, 154, 98, 30, "APPLY", ACCENT, TEXT, 12, FB),
    B("VP3_TM_Reset", 110, 154, 98, 30, "RESET", BTN, TEXT, 12, FB),
    L("VP3_TM_Count", 8, 190, 200, 22, "0 selected", MUTED, 11)]
vp3_tm = F("VP3_Trans", 88, 352, 216, 220, PANEL, vp3_tm_kids, HID)

vp3_meas_kids = [title("MEASURE"),
    B("VP3_M_D1", 8, 30, 104, 30, "SET A", BTN, TEXT, 12, FB),
    B("VP3_M_D2", 116, 30, 104, 30, "SET B", BTN, TEXT, 12, FB),
    L("VP3_M_Val", 8, 66, 214, 30, "dist -", GOLD, 14, FC, CENTER, INSET),
    B("VP3_M_Clear", 8, 102, 214, 28, "CLEAR", BTN, TEXT, 12, FB)]
vp3_meas = F("VP3_Meas", 1330, 100, 230, 140, PANEL, vp3_meas_kids, HID)

vp3_snap_kids = [title("SNAP"),
    B("VP3_G_Snap", 8, 30, 214, 30, "SNAP: ON", BTN, TEXT, 12, FB),
    L("VP3_G_StepL", 8, 66, 60, 26, "STEP", MUTED, 11, FB),
    B("VP3_G_StepM", 70, 66, 40, 26, "-", BTN, TEXT, 14),
    L("VP3_G_StepV", 114, 66, 64, 26, "1", TEXT, 12, FC, CENTER, INSET),
    B("VP3_G_StepP", 182, 66, 40, 26, "+", BTN, TEXT, 14)]
vp3_snap = F("VP3_Snap", 1330, 248, 230, 102, PANEL, vp3_snap_kids, HID)

vp3_status = F("VP3_Status", 88, 820, 700, 30, PANEL,
               [L("VP3_StatL", 8, 4, 684, 22, "viewport", TEXT, 12, FC)], HID)

mvp_kids = [B("M_VP_Frame", 8, 8, 200, 64, "FRAME", ACCENT, TEXT, 16, FB),
            B("M_VP_Meas", 216, 8, 200, 64, "MEASURE", BTN, TEXT, 16, FB),
            L("M_VP_Hint", 424, 8, 700, 64, "frame selection / tap 2 points", MUTED, 13)]
mvp = F("M_VP", 0, 690, 1568, 80, MENU_BG, mvp_kids, HID)


# ---------------- 12c. modeler R12 (MD4) ----------------
md4_rail_kids = [title("MESH")]
for i, key in enumerate(["Select", "Move", "Near"]):
    md4_rail_kids.append(B("MD4_T_" + key, 8, 30 + i * 44, 56, 40,
                           key[:3].upper(), BTN, TEXT, 12, FB))
md4_rail_kids.append(B("MD4_Close", 8, 30 + 3 * 44, 56, 32, "X", BTN, RED, 14, FB))
md4_rail = F("MD4_Rail", 8, 100, 72, 220, PANEL, md4_rail_kids, HID)

md4_mesh_kids = [title("MESH"),
    B("MD4_P_Box", 8, 30, 100, 26, "BOX", ACCENT, TEXT, 11, FB),
    B("MD4_P_Plane", 112, 30, 100, 26, "PLANE", BTN, TEXT, 11, FB),
    B("MD4_P_Wedge", 8, 60, 100, 26, "WEDGE", BTN, TEXT, 11, FB),
    B("MD4_P_Cyl8", 112, 60, 100, 26, "CYL8", BTN, TEXT, 11, FB),
    B("MD4_New", 8, 92, 100, 30, "CREATE", ACCENT, TEXT, 12, FB),
    B("MD4_Adopt", 112, 92, 100, 30, "ADOPT SEL", BTN, TEXT, 11, FB),
    L("MD4_Info", 8, 128, 204, 44, "no mesh", MUTED, 11, FC)]
md4_mesh = F("MD4_Mesh", 88, 100, 220, 180, PANEL, md4_mesh_kids, HID)

md4_vert_kids = [title("VERTEX"),
    B("MD4_V_Prev", 8, 30, 50, 26, "<", BTN, TEXT, 14),
    L("MD4_V_Id", 62, 30, 100, 26, "vid -", GOLD, 12, FC, CENTER, INSET),
    B("MD4_V_Next", 166, 30, 50, 26, ">", BTN, TEXT, 14),
    L("MD4_V_XL", 8, 62, 20, 26, "X", MUTED, 11, FB),
    B("MD4_V_XM", 28, 62, 40, 26, "-", BTN, TEXT, 14),
    L("MD4_V_XV", 72, 62, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("MD4_V_XP", 152, 62, 40, 26, "+", BTN, TEXT, 14),
    L("MD4_V_YL", 8, 92, 20, 26, "Y", MUTED, 11, FB),
    B("MD4_V_YM", 28, 92, 40, 26, "-", BTN, TEXT, 14),
    L("MD4_V_YV", 72, 92, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("MD4_V_YP", 152, 92, 40, 26, "+", BTN, TEXT, 14),
    L("MD4_V_ZL", 8, 122, 20, 26, "Z", MUTED, 11, FB),
    B("MD4_V_ZM", 28, 122, 40, 26, "-", BTN, TEXT, 14),
    L("MD4_V_ZV", 72, 122, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
    B("MD4_V_ZP", 152, 122, 40, 26, "+", BTN, TEXT, 14),
    B("MD4_V_Apply", 8, 154, 100, 30, "MOVE", ACCENT, TEXT, 12, FB),
    B("MD4_V_Del", 112, 154, 100, 30, "DELETE", BTN, RED, 12, FB),
    L("MD4_V_Hint", 8, 190, 204, 22, "Near: click mesh = nearest vert", MUTED, 10)]
md4_vert = F("MD4_Vert", 88, 288, 220, 220, PANEL, md4_vert_kids, HID)

md4_top_kids = [title("TOPOLOGY"),
    L("MD4_S_IL", 8, 30, 70, 26, "SMOOTH", MUTED, 11, FB),
    B("MD4_S_IM", 80, 30, 40, 26, "-", BTN, TEXT, 14),
    L("MD4_S_IV", 124, 30, 44, 26, "1", TEXT, 12, FC, CENTER, INSET),
    B("MD4_S_IP", 172, 30, 40, 26, "+", BTN, TEXT, 14),
    B("MD4_Smooth", 8, 62, 204, 30, "APPLY SMOOTH", ACCENT, TEXT, 12, FB),
    B("MD4_M_X", 8, 98, 64, 28, "MIR X", BTN, TEXT, 11, FB),
    B("MD4_M_Y", 76, 98, 64, 28, "MIR Y", BTN, TEXT, 11, FB),
    B("MD4_M_Z", 144, 98, 64, 28, "MIR Z", BTN, TEXT, 11, FB)]
md4_top = F("MD4_Top", 1330, 100, 220, 134, PANEL, md4_top_kids, HID)

md4_io_kids = [title("OBJ"),
    T("MD4_IO_Text", 8, 30, 204, 90, "paste OBJ here (v/f, tri+quad)", "", 11,
      {"MultiLine": True, "TextWrapped": True, "TextYAlignment": {"en": "TextYAlignment.Top"}}),
    B("MD4_IO_Import", 8, 126, 100, 30, "IMPORT", ACCENT, TEXT, 12, FB),
    B("MD4_IO_Export", 112, 126, 100, 30, "EXPORT", BTN, TEXT, 12, FB),
    L("MD4_IO_Stat", 8, 162, 204, 22, "obj -", MUTED, 11)]
md4_io = F("MD4_IO", 1330, 242, 220, 192, PANEL, md4_io_kids, HID)

md4_status = F("MD4_Status", 88, 820, 700, 30, PANEL,
               [L("MD4_StatL", 8, 4, 684, 22, "modeler", TEXT, 12, FC)], HID)

mmd_kids = [B("M_MD_New", 8, 8, 200, 64, "NEW BOX", ACCENT, TEXT, 16, FB),
            B("M_MD_Smooth", 216, 8, 200, 64, "SMOOTH", BTN, TEXT, 16, FB),
            L("M_MD_Hint", 424, 8, 700, 64, "create + smooth current mesh", MUTED, 13)]
mmd = F("M_MD", 0, 690, 1568, 80, MENU_BG, mmd_kids, HID)
# ---------------- 12d. animator R13 (AN5) ----------------
an5_rail_kids = [title("ANIM")]
for i, key in enumerate(["Select", "Pose"]):
    an5_rail_kids.append(B("AN5_T_" + key, 8, 30 + i * 44, 56, 40,
                            key[:3].upper(), BTN, TEXT, 11, FB))
an5_rail_kids.append(B("AN5_Close", 8, 30 + 2 * 44, 56, 32, "X", BTN, RED, 14, FB))
an5_rail = F("AN5_Rail", 8, 100, 72, 220, PANEL, an5_rail_kids, HID)

an5_rig_kids = [title("RIG + SEQ"),
    B("AN5_New", 8, 30, 100, 30, "NEW SEQ", ACCENT, TEXT, 12, FB),
    B("AN5_Adopt", 112, 30, 100, 30, "ADOPT", BTN, TEXT, 11, FB),
    B("AN5_J_Prev", 8, 66, 50, 26, "<", BTN, TEXT, 14),
    L("AN5_J_Name", 62, 66, 100, 26, "joint -", GOLD, 11, FC, CENTER, INSET),
    B("AN5_J_Next", 166, 66, 50, 26, ">", BTN, TEXT, 14),
    L("AN5_Info", 8, 98, 204, 66, "no rig", MUTED, 11, FC)]
an5_rig = F("AN5_Rig", 88, 100, 220, 172, PANEL, an5_rig_kids, HID)

an5_pose_kids = [title("POSE JOINT (live)")]
for i, ax in enumerate(["X", "Y", "Z"]):
    y = 30 + i * 30
    an5_pose_kids += [L("AN5_R_" + ax + "L", 8, y, 20, 26, ax, MUTED, 11, FB),
        B("AN5_R_" + ax + "M", 28, y, 40, 26, "-", BTN, TEXT, 14),
        L("AN5_R_" + ax + "V", 72, y, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
        B("AN5_R_" + ax + "P", 152, y, 40, 26, "+", BTN, TEXT, 14)]
an5_pose_kids += [B("AN5_R_Apply", 8, 122, 100, 30, "APPLY", ACCENT, TEXT, 12, FB),
    B("AN5_R_Reset", 112, 122, 100, 30, "RESET", BTN, TEXT, 12, FB),
    L("AN5_Pose_Hint", 8, 158, 204, 40, "rot deg step 15; apply = live Transform", MUTED, 10)]
an5_pose = F("AN5_Pose", 88, 280, 220, 206, PANEL, an5_pose_kids, HID)

an5_time_kids = [title("TIMELINE 30fps"),
    B("AN5_Play", 8, 30, 100, 30, "PLAY", ACCENT, TEXT, 12, FB),
    B("AN5_Stop", 112, 30, 100, 30, "STOP", BTN, TEXT, 12, FB),
    B("AN5_F_M", 8, 66, 50, 26, "-1F", BTN, TEXT, 11, FB),
    L("AN5_TLabel", 62, 66, 100, 26, "0:00", GOLD, 13, FC, CENTER, INSET),
    B("AN5_F_P", 166, 66, 50, 26, "+1F", BTN, TEXT, 11, FB),
    B("AN5_Loop", 8, 98, 100, 26, "LOOP OFF", BTN, TEXT, 11, FB),
    B("AN5_S_M", 112, 98, 30, 26, "-", BTN, TEXT, 14),
    L("AN5_SV", 146, 98, 36, 26, "1x", TEXT, 11, FC, CENTER, INSET),
    B("AN5_S_P", 186, 98, 26, 26, "+", BTN, TEXT, 14)]
an5_time = F("AN5_Time", 1330, 100, 220, 132, PANEL, an5_time_kids, HID)

an5_keys_kids = [title("KEYS"),
    B("AN5_K_Prev", 8, 30, 50, 26, "<", BTN, TEXT, 14),
    L("AN5_K_Name", 62, 66 - 36, 100, 26, "key -", GOLD, 11, FC, CENTER, INSET),
    B("AN5_K_Next", 166, 30, 50, 26, ">", BTN, TEXT, 14),
    B("AN5_K_Add", 8, 62, 100, 30, "ADD KEY", ACCENT, TEXT, 12, FB),
    B("AN5_K_Del", 112, 62, 100, 30, "DEL", BTN, RED, 12, FB),
    B("AN5_E_S", 8, 98, 100, 26, "LIN", BTN, TEXT, 11, FB),
    B("AN5_E_D", 112, 98, 100, 26, "INOUT", BTN, TEXT, 11, FB),
    L("AN5_W_L", 8, 130, 70, 26, "WEIGHT", MUTED, 11, FB),
    B("AN5_W_M", 80, 130, 40, 26, "-", BTN, TEXT, 14),
    L("AN5_WV", 124, 130, 44, 26, "1", TEXT, 12, FC, CENTER, INSET),
    B("AN5_W_P", 172, 130, 40, 26, "+", BTN, TEXT, 14)]
an5_keys = F("AN5_Keys", 1330, 240, 220, 164, PANEL, an5_keys_kids, HID)

an5_io_kids = [title("ANIM JSON"),
    T("AN5_IO_Text", 8, 30, 204, 90, "paste anim JSON here", "", 11,
      {"MultiLine": True, "TextWrapped": True, "TextYAlignment": {"en": "TextYAlignment.Top"}}),
    B("AN5_IO_Import", 8, 126, 100, 30, "IMPORT", ACCENT, TEXT, 12, FB),
    B("AN5_IO_Export", 112, 126, 100, 30, "EXPORT", BTN, TEXT, 12, FB),
    L("AN5_IO_Stat", 8, 162, 204, 22, "anim -", MUTED, 11)]
an5_io = F("AN5_IO", 1330, 412, 220, 192, PANEL, an5_io_kids, HID)

an5_status = F("AN5_Status", 88, 820, 700, 30, PANEL,
               [L("AN5_StatL", 8, 4, 684, 22, "animator", TEXT, 12, FC)], HID)

man_kids = [B("M_AN_New", 8, 8, 200, 64, "NEW SEQ", ACCENT, TEXT, 16, FB),
            B("M_AN_Play", 216, 8, 200, 64, "PLAY", BTN, TEXT, 16, FB),
            B("M_AN_Key", 424, 8, 200, 64, "ADD KEY", BTN, TEXT, 16, FB),
            L("M_AN_Hint", 632, 8, 700, 64, "new + play + key at cursor", MUTED, 13)]
man = F("M_AN", 0, 690, 1568, 80, MENU_BG, man_kids, HID)
# ---------------- 12e. ui editor R14 (UI6) ----------------
ui6_rail_kids = [title("UI")]
for i, key in enumerate(["Select", "Move"]):
    ui6_rail_kids.append(B("UI6_T_" + key, 8, 30 + i * 44, 56, 40,
                            key[:3].upper(), BTN, TEXT, 11, FB))
ui6_rail_kids.append(B("UI6_Close", 8, 30 + 2 * 44, 56, 32, "X", BTN, RED, 14, FB))
ui6_rail = F("UI6_Rail", 8, 100, 72, 220, PANEL, ui6_rail_kids, HID)

ui6_new_kids = [title("NEW")]
for i, (nm, tx) in enumerate([("Frame", "FRAME"), ("Label", "LABEL"), ("Button", "BUTTON"),
    ("Box", "TEXTBOX"), ("Image", "IMAGE"), ("Scroll", "SCROLL"),
    ("Corner", "CORNER"), ("Stroke", "STROKE")]):
    ui6_new_kids.append(B("UI6_N_" + nm, 8 + (i % 2) * 104, 30 + (i // 2) * 34, 100, 30,
                           tx, ACCENT if i < 6 else BTN, TEXT, 11, FB))
ui6_new_kids.append(L("UI6_Info", 8, 170, 204, 44, "no selection", MUTED, 11, FC))
ui6_new = F("UI6_New", 88, 100, 220, 222, PANEL, ui6_new_kids, HID)

ui6_props_kids = [title("POS + SIZE")]
for i, (ax, key) in enumerate([("X", "X"), ("Y", "Y")]):
    y = 30 + i * 30
    ui6_props_kids += [L("UI6_" + key + "L", 8, y, 20, 26, ax, MUTED, 11, FB),
        B("UI6_" + key + "_M", 28, y, 40, 26, "-", BTN, TEXT, 14),
        L("UI6_" + key + "V", 72, y, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
        B("UI6_" + key + "_P", 152, y, 40, 26, "+", BTN, TEXT, 14)]
for i, (ax, key) in enumerate([("W", "W"), ("H", "H")]):
    y = 92 + i * 30
    ui6_props_kids += [L("UI6_" + key + "L", 8, y, 20, 26, ax, MUTED, 11, FB),
        B("UI6_" + key + "_M", 28, y, 40, 26, "-", BTN, TEXT, 14),
        L("UI6_" + key + "V", 72, y, 76, 26, "0", TEXT, 12, FC, CENTER, INSET),
        B("UI6_" + key + "_P", 152, y, 40, 26, "+", BTN, TEXT, 14)]
ui6_props_kids += [T("UI6_Text", 8, 154, 140, 30, "text...", "", 12),
    B("UI6_T_Apply", 152, 154, 60, 30, "SET", ACCENT, TEXT, 12, FB),
    B("UI6_Dup", 8, 190, 100, 30, "DUPLI", BTN, TEXT, 12, FB),
    B("UI6_Del", 112, 190, 100, 30, "DEL", BTN, RED, 12, FB)]
ui6_props = F("UI6_Props", 88, 330, 220, 228, PANEL, ui6_props_kids, HID)

ui6_tree_kids = [title("TREE"),
    B("UI6_T_Prev", 8, 30, 50, 26, "<", BTN, TEXT, 14),
    L("UI6_T_Name", 62, 30, 100, 26, "- -", GOLD, 11, FC, CENTER, INSET),
    B("UI6_T_Next", 166, 30, 50, 26, ">", BTN, TEXT, 14),
    B("UI6_Pub", 8, 62, 204, 30, "PUBLISH UI", ACCENT, TEXT, 12, FB),
    L("UI6_T_Hint", 8, 98, 204, 40, "publish = StarterGui (respawn)", MUTED, 10)]
ui6_tree = F("UI6_Tree", 1330, 100, 220, 146, PANEL, ui6_tree_kids, HID)

ui6_io_kids = [title("UI JSON"),
    T("UI6_IO_Text", 8, 30, 204, 90, "paste UI JSON here", "", 11,
      {"MultiLine": True, "TextWrapped": True, "TextYAlignment": {"en": "TextYAlignment.Top"}}),
    B("UI6_IO_Import", 8, 126, 100, 30, "IMPORT", ACCENT, TEXT, 12, FB),
    B("UI6_IO_Export", 112, 126, 100, 30, "EXPORT", BTN, TEXT, 12, FB),
    L("UI6_IO_Stat", 8, 162, 204, 22, "ui -", MUTED, 11)]
ui6_io = F("UI6_IO", 1330, 254, 220, 192, PANEL, ui6_io_kids, HID)

ui6_status = F("UI6_Status", 88, 820, 700, 30, PANEL,
               [L("UI6_StatL", 8, 4, 684, 22, "ui editor", TEXT, 12, FC)], HID)

mui_kids = [B("M_UI_New", 8, 8, 200, 64, "NEW FRAME", ACCENT, TEXT, 16, FB),
            B("M_UI_Dup", 216, 8, 200, 64, "DUPLI", BTN, TEXT, 16, FB),
            B("M_UI_Del", 424, 8, 200, 64, "DEL", BTN, TEXT, 16, FB),
            L("M_UI_Hint", 632, 8, 700, 64, "frame + duplicate + delete", MUTED, 13)]
mui = F("M_UI", 0, 690, 1568, 80, MENU_BG, mui_kids, HID)

# ---------------- 12f. rrw R14 (RW7) ----------------
rw7_rail_kids = [title("RRW"),
    B("RW7_T_Place", 8, 30, 56, 40, "PLC", BTN, TEXT, 11, FB),
    B("RW7_Close", 8, 74, 56, 32, "X", BTN, RED, 14, FB)]
rw7_rail = F("RW7_Rail", 8, 100, 72, 220, PANEL, rw7_rail_kids, HID)

rw7_prof_kids = [title("PROFILE")]
for i, nm in enumerate(["Realista", "Showcase", "Horror", "Mobile", "Estudio"]):
    rw7_prof_kids.append(B("RW7_P_" + nm, 8 + (i % 2) * 104, 30 + (i // 2) * 34, 100, 30,
                            nm.upper(), ACCENT if i == 0 else BTN, TEXT, 11, FB))
rw7_prof_kids.append(L("RW7_P_Info", 8, 136, 204, 44, "style -", MUTED, 11, FC))
rw7_prof = F("RW7_Prof", 88, 100, 220, 188, PANEL, rw7_prof_kids, HID)

rw7_fx_kids = [title("POST FX")]
for i, (nm, tx) in enumerate([("Bloom", "BLOOM"), ("Blur", "BLUR"), ("Color", "COLOR"),
    ("DOF", "DOF"), ("Rays", "RAYS"), ("Grade", "GRADE")]):
    rw7_fx_kids.append(B("RW7_F_" + nm, 8 + (i % 2) * 104, 30 + (i // 2) * 34, 100, 30,
                           tx, BTN, TEXT, 11, FB))
rw7_fx_kids += [L("RW7_I_L", 8, 136, 70, 26, "INTEN", MUTED, 11, FB),
    B("RW7_I_M", 80, 136, 40, 26, "-", BTN, TEXT, 14),
    L("RW7_IV", 124, 136, 44, 26, "1", TEXT, 12, FC, CENTER, INSET),
    B("RW7_I_P", 172, 136, 40, 26, "+", BTN, TEXT, 14),
    L("RW7_F_Info", 8, 168, 204, 40, "click = toggle; inten = main prop", MUTED, 10)]
rw7_fx = F("RW7_FX", 88, 296, 220, 216, PANEL, rw7_fx_kids, HID)

rw7_sky_kids = [title("SKY"),
    B("RW7_S_TM", 8, 30, 50, 26, "-1H", BTN, TEXT, 11, FB),
    L("RW7_S_TV", 62, 30, 100, 26, "12:00", GOLD, 13, FC, CENTER, INSET),
    B("RW7_S_TP", 166, 30, 50, 26, "+1H", BTN, TEXT, 11, FB),
    B("RW7_S_Cycle", 8, 62, 100, 30, "CYCLE OFF", BTN, TEXT, 11, FB),
    B("RW7_S_SM", 112, 62, 30, 30, "-", BTN, TEXT, 14),
    L("RW7_S_SV", 146, 62, 36, 30, ".1", TEXT, 11, FC, CENTER, INSET),
    B("RW7_S_SP", 186, 62, 26, 30, "+", BTN, TEXT, 14)]
rw7_sky = F("RW7_Sky", 1330, 100, 220, 100, PANEL, rw7_sky_kids, HID)

rw7_world_kids = [title("ATMO + VFX"),
    L("RW7_A_L", 8, 30, 70, 26, "ATMO", MUTED, 11, FB),
    B("RW7_A_M", 80, 30, 40, 26, "-", BTN, TEXT, 14),
    L("RW7_AV", 124, 30, 44, 26, ".3", TEXT, 12, FC, CENTER, INSET),
    B("RW7_A_P", 172, 30, 40, 26, "+", BTN, TEXT, 14),
    L("RW7_C_L", 8, 62, 70, 26, "CLOUD", MUTED, 11, FB),
    B("RW7_C_M", 80, 62, 40, 26, "-", BTN, TEXT, 14),
    L("RW7_CV", 124, 62, 44, 26, ".5", TEXT, 12, FC, CENTER, INSET),
    B("RW7_C_P", 172, 62, 40, 26, "+", BTN, TEXT, 14),
    B("RW7_V_Torch", 8, 94, 100, 28, "TORCH", BTN, TEXT, 11, FB),
    B("RW7_V_Smoke", 112, 94, 100, 28, "SMOKE", BTN, TEXT, 11, FB),
    B("RW7_V_Magic", 8, 126, 100, 28, "MAGIC", BTN, TEXT, 11, FB),
    B("RW7_V_Glow", 112, 126, 100, 28, "GLOW", BTN, TEXT, 11, FB)]
rw7_world = F("RW7_World", 1330, 208, 220, 162, PANEL, rw7_world_kids, HID)

rw7_lod_kids = [title("LOD"),
    T("RW7_L_Name", 8, 30, 120, 26, "group", "", 11),
    B("RW7_L_Add", 132, 30, 80, 26, "+TIER", ACCENT, TEXT, 11, FB),
    L("RW7_L_Info", 8, 62, 204, 44, "tiers: select model, +tier xN", MUTED, 10),
    B("RW7_L_Reg", 8, 110, 100, 28, "REGISTER", ACCENT, TEXT, 11, FB),
    B("RW7_L_Del", 112, 110, 100, 28, "REMOVE", BTN, RED, 11, FB)]
rw7_lod = F("RW7_LOD", 1330, 378, 220, 146, PANEL, rw7_lod_kids, HID)

rw7_status = F("RW7_Status", 88, 820, 700, 30, PANEL,
               [L("RW7_StatL", 8, 4, 684, 22, "rrw", TEXT, 12, FC)], HID)

mrw_kids = [B("M_RW_Prof", 8, 8, 200, 64, "PROFILE", ACCENT, TEXT, 16, FB),
            B("M_RW_FX", 216, 8, 200, 64, "BLOOM", BTN, TEXT, 16, FB),
            B("M_RW_Sky", 424, 8, 200, 64, "CYCLE", BTN, TEXT, 16, FB),
            L("M_RW_Hint", 632, 8, 700, 64, "cycle profile + bloom + day cycle", MUTED, 13)]
mrw = F("M_RW", 0, 690, 1568, 80, MENU_BG, mrw_kids, HID)



desktop_kids = ([menu, ribbon, terrain, console, selection, crumb, compass, coords,
          play, layers, region, mapp, gizmo, timeline, curves, sim, team,
          farright, farhelp] + footer)
dmarquee = F("D_Marquee", 0, 0, 10, 10, INSET, [], {"Visible": False, "BackgroundTransparency": 0.45})
desktop_kids.append(dmarquee)
dset_kids = [title("SETTINGS"), B("D_S_Close", 392, 4, 60, 26, "\u2715", BTN, TEXT, 14),
             L("D_S_KeyTitle", 8, 32, 444, 20, "KEYBOARD (click a key, press new)", MUTED, 12, FB)]
dset_rows = [("D_S_B1", "Select tool"), ("D_S_B2", "Move tool"), ("D_S_B3", "Rotate tool"),
             ("D_S_B4", "Scale tool"), ("D_S_B5", "Frame"), ("D_S_B6", "Box select"),
             ("D_S_B7", "Lasso select"), ("D_S_B8", "Snap")]
for i, (nm, tx) in enumerate(dset_rows):
    dset_kids += [L(nm + "L", 8, 56 + i * 38, 220, 32, tx, TEXT, 13),
                  B(nm, 232, 56 + i * 38, 220, 32, "···", BTN, TEXT, 14, FB)]
dset_kids += [B("D_S_Reset", 8, 366, 444, 34, "RESET DEFAULTS", BTN, TEXT, 14, FB),
              L("D_S_LangTitle", 8, 408, 444, 20, "LANGUAGE", MUTED, 12, FB),
              B("D_S_Lang", 8, 430, 444, 34, "IDIOMA: EN", BTN, TEXT, 14, FB),
              L("D_S_ScaleTitle", 8, 472, 444, 20, "UI SCALE", MUTED, 12, FB),
              B("D_S_ScaleMinus", 8, 494, 60, 32, "\u2212", BTN, TEXT, 20),
              L("D_S_ScaleVal", 72, 494, 120, 32, "100%", TEXT, 14, FC, CENTER, INSET),
              B("D_S_ScalePlus", 196, 494, 60, 32, "+", BTN, TEXT, 20),
              L("D_S_Hint", 8, 534, 444, 56, "remap + language apply instantly (this session)", MUTED, 11)]
dsettings = F("D_Settings", 554, 140, 460, 600, PANEL, dset_kids, {"Visible": False})
desktop_kids.append(dsettings)

# ---------------- 12g. d-o15 R15 (DO8) ----------------
do8_rail = F("DO8_Rail", 8, 100, 72, 220, PANEL, [title("D-O15"),
    B("DO8_Scan", 8, 30, 56, 40, "SCAN", BTN, TEXT, 11, FB),
    B("DO8_Close", 8, 74, 56, 32, "X", BTN, RED, 14, FB)], HID)
do8_stats = F("DO8_Stats", 88, 100, 220, 190, PANEL, [title("STATS"),
    L("DO8_StatBig", 8, 30, 204, 118, "fps -", TEXT, 11, FC),
    B("DO8_S_Refresh", 8, 152, 100, 30, "REFRESH", BTN, TEXT, 11, FB),
    B("DO8_S_Report", 112, 152, 100, 30, "REPORT", ACCENT, TEXT, 11, FB)], HID)
do8_audit = F("DO8_Audit", 88, 298, 220, 190, PANEL, [title("AUDIT"),
    L("DO8_AuditBig", 8, 30, 204, 118, "run scan", MUTED, 11, FC),
    B("DO8_A_Scan", 8, 152, 204, 30, "SCAN WORLD", ACCENT, TEXT, 12, FB)], HID)
do8_opt = F("DO8_Opt", 88, 496, 220, 170, PANEL, [title("OPTIMIZE"),
    B("DO8_O_Touch", 8, 30, 100, 30, "NO-TOUCH", BTN, TEXT, 11, FB),
    B("DO8_O_Shadow", 112, 30, 100, 30, "NO-SHADOW", BTN, TEXT, 11, FB),
    B("DO8_O_Anchor", 8, 64, 100, 30, "ANCHOR", BTN, GOLD, 11, FB),
    B("DO8_O_Undo", 112, 64, 100, 30, "UNDO", BTN, TEXT, 11, FB),
    L("DO8_O_Info", 8, 98, 204, 60, "touch+shadow safe; anchor=confirm", MUTED, 10)], HID)
do8_rel = F("DO8_Rel", 1330, 100, 220, 206, PANEL, [title("RELEVANCE"),
    T("DO8_R_Name", 8, 30, 120, 26, "group", "", 11),
    B("DO8_R_Add", 132, 30, 80, 26, "+GRP", ACCENT, TEXT, 11, FB),
    L("DO8_R_RL", 8, 62, 60, 26, "RADIUS", MUTED, 11, FB),
    B("DO8_R_RM", 70, 62, 30, 26, "-", BTN, TEXT, 14),
    L("DO8_R_RV", 104, 62, 50, 26, "150", TEXT, 11, FC, CENTER, INSET),
    B("DO8_R_RP", 158, 62, 30, 26, "+", BTN, TEXT, 14),
    B("DO8_R_KLight", 8, 94, 48, 26, "LIT", ACCENT, TEXT, 11, FB),
    B("DO8_R_KEmit", 60, 94, 48, 26, "EMI", ACCENT, TEXT, 11, FB),
    B("DO8_R_KDecal", 112, 94, 48, 26, "DEC", BTN, TEXT, 11, FB),
    B("DO8_R_KSnd", 164, 94, 48, 26, "SND", BTN, TEXT, 11, FB),
    B("DO8_R_Reg", 8, 124, 100, 28, "REGISTER", ACCENT, TEXT, 11, FB),
    B("DO8_R_Del", 112, 124, 100, 28, "REMOVE", BTN, RED, 11, FB),
    L("DO8_R_Info", 8, 156, 204, 42, "select model/folder, +grp", MUTED, 10)], HID)
do8_mem = F("DO8_Mem", 1330, 314, 220, 150, PANEL, [title("MEMORY"),
    L("DO8_M_Info", 8, 30, 204, 44, "lua -", TEXT, 11, FC),
    T("DO8_M_Ids", 8, 78, 204, 26, "rbxassetid://..,..", "", 11),
    B("DO8_M_GC", 8, 110, 100, 30, "COLLECT", BTN, TEXT, 11, FB),
    B("DO8_M_Pre", 112, 110, 100, 30, "PRELOAD", BTN, TEXT, 11, FB)], HID)
do8_status = F("DO8_Status", 88, 820, 700, 30, PANEL,
               [L("DO8_StatL", 8, 4, 684, 22, "do15", TEXT, 12, FC)], HID)
mdo_kids = [B("M_DO_Scan", 8, 8, 200, 64, "SCAN", ACCENT, TEXT, 16, FB),
            B("M_DO_Opt", 216, 8, 200, 64, "SAFE OPT", BTN, TEXT, 16, FB),
            B("M_DO_GC", 424, 8, 200, 64, "GC", BTN, TEXT, 16, FB),
            L("M_DO_Hint", 632, 8, 700, 64, "scan + safe optimize + collect", MUTED, 13)]
mdo = F("M_DO", 0, 690, 1568, 80, MENU_BG, mdo_kids, HID)

# ---------------- 12h. world R15 (WO9) ----------------
wo9_rail = F("WO9_Rail", 8, 100, 72, 140, PANEL, [title("WORLD"),
    B("WO9_Close", 8, 30, 56, 32, "X", BTN, RED, 14, FB)], HID)
wo9_info = F("WO9_Info", 88, 100, 220, 200, PANEL, [title("WORLD"),
    L("WO9_InfoBig", 8, 30, 204, 128, "parts -", TEXT, 11, FC),
    B("WO9_I_Refresh", 8, 162, 204, 30, "REFRESH", ACCENT, TEXT, 12, FB)], HID)
wo9_grav = F("WO9_Grav", 88, 308, 220, 140, PANEL, [title("GRAVITY"),
    B("WO9_G_M", 8, 30, 50, 30, "-", BTN, TEXT, 14),
    L("WO9_GV", 62, 30, 100, 30, "196.2", GOLD, 13, FC, CENTER, INSET),
    B("WO9_G_P", 166, 30, 50, 30, "+", BTN, TEXT, 14),
    B("WO9_G_Set", 8, 66, 100, 30, "APPLY", ACCENT, TEXT, 11, FB),
    B("WO9_G_Reset", 112, 66, 100, 30, "EARTH", BTN, TEXT, 11, FB),
    L("WO9_G_Info", 8, 100, 204, 32, "killY -", MUTED, 10)], HID)
wo9_spawn = F("WO9_Spawn", 88, 456, 220, 152, PANEL, [title("SPAWN"),
    L("WO9_S_Info", 8, 30, 204, 44, "no spawns", MUTED, 11, FC),
    B("WO9_S_Prev", 8, 78, 64, 28, "<", BTN, TEXT, 14),
    B("WO9_S_Next", 76, 78, 64, 28, ">", BTN, TEXT, 14),
    B("WO9_S_Add", 144, 78, 68, 28, "+ADD", ACCENT, TEXT, 11, FB),
    B("WO9_S_Toggle", 8, 110, 100, 28, "ON/OFF", BTN, TEXT, 11, FB),
    B("WO9_S_Del", 112, 110, 100, 28, "DEL", BTN, RED, 11, FB)], HID)
wo9_save = F("WO9_Save", 1330, 100, 220, 178, PANEL, [title("SAVE/LOAD"),
    T("WO9_V_Name", 8, 30, 120, 26, "name", "", 11),
    B("WO9_V_Save", 132, 30, 80, 26, "SAVE", ACCENT, TEXT, 11, FB),
    L("WO9_V_Info", 8, 62, 204, 44, "no saves", MUTED, 11, FC),
    B("WO9_V_Prev", 8, 110, 64, 28, "<", BTN, TEXT, 14),
    B("WO9_V_Next", 76, 110, 64, 28, ">", BTN, TEXT, 14),
    B("WO9_V_Load", 144, 110, 68, 28, "LOAD", ACCENT, TEXT, 11, FB),
    B("WO9_V_Del", 8, 142, 204, 28, "DELETE SAVE", BTN, RED, 11, FB)], HID)
wo9_clean = F("WO9_Clean", 1330, 286, 220, 178, PANEL, [title("CLEANUP"),
    T("WO9_C_Y", 8, 30, 120, 26, "-400", "-400", 11),
    B("WO9_C_Fallen", 132, 30, 80, 26, "FALLEN", BTN, TEXT, 11, FB),
    B("WO9_C_Loose", 8, 62, 100, 28, "LOOSE", BTN, TEXT, 11, FB),
    B("WO9_C_Restore", 112, 62, 100, 28, "RESTORE", BTN, TEXT, 11, FB),
    B("WO9_C_Clear", 8, 94, 204, 28, "CLEAR WORLD", BTN, RED, 11, FB),
    L("WO9_C_Info", 8, 126, 204, 44, "trash 0 (+autosafe)", MUTED, 10)], HID)
wo9_status = F("WO9_Status", 88, 820, 700, 30, PANEL,
               [L("WO9_StatL", 8, 4, 684, 22, "world", TEXT, 12, FC)], HID)
mwo_kids = [B("M_WO_Save", 8, 8, 200, 64, "SAVE", ACCENT, TEXT, 16, FB),
            B("M_WO_Spawn", 216, 8, 200, 64, "SPAWN", BTN, TEXT, 16, FB),
            B("M_WO_Clean", 424, 8, 200, 64, "FALLEN", BTN, TEXT, 16, FB),
            L("M_WO_Hint", 632, 8, 700, 64, "quicksave + spawn here + fallen", MUTED, 13)]
mwo = F("M_WO", 0, 690, 1568, 80, MENU_BG, mwo_kids, HID)


# ---------------- 12i. home/explorer R16 (HO10) ----------------
ho10_rail = F("HO10_Rail", 8, 100, 72, 140, PANEL, [title("HOME"),
    B("HO10_Close", 8, 30, 56, 32, "X", BTN, RED, 14, FB)], HID)
ho10_file = F("HO10_File", 88, 100, 220, 172, PANEL, [title("PROJECT"),
    B("HO10_F_New", 8, 30, 100, 30, "NEW", BTN, TEXT, 11, FB),
    B("HO10_F_Open", 112, 30, 100, 30, "OPEN", BTN, TEXT, 11, FB),
    B("HO10_F_Save", 8, 66, 100, 30, "SAVE", ACCENT, TEXT, 11, FB),
    B("HO10_F_Pub", 112, 66, 100, 30, "PUBLISH", BTN, TEXT, 11, FB),
    B("HO10_F_Undo", 8, 102, 204, 26, "UNDO", BTN, TEXT, 11, FB),
    L("HO10_F_Info", 8, 132, 204, 30, "file ops via menus", MUTED, 10)], HID)
ho10_tree = F("HO10_Tree", 88, 258, 220, 196, PANEL, [title("EXPLORER"),
    T("HO10_T_Filter", 8, 30, 204, 26, "filter", "", 11),
    L("HO10_T_Info", 8, 62, 204, 60, "no selection", TEXT, 11, FC),
    B("HO10_T_Prev", 8, 126, 64, 28, "<", BTN, TEXT, 14),
    B("HO10_T_Next", 76, 126, 64, 28, ">", BTN, TEXT, 14),
    B("HO10_T_Sel", 144, 126, 68, 28, "SELECT", ACCENT, TEXT, 11, FB),
    B("HO10_T_Refresh", 8, 158, 204, 28, "REFRESH", BTN, TEXT, 11, FB)], HID)
ho10_props = F("HO10_Props", 1330, 100, 220, 182, PANEL, [title("PROPS"),
    L("HO10_P_Info", 8, 30, 204, 44, "-", MUTED, 11, FC),
    T("HO10_P_Name", 8, 78, 120, 26, "name", "", 11),
    B("HO10_P_Rename", 132, 78, 80, 26, "SET", ACCENT, TEXT, 11, FB),
    B("HO10_P_Vis", 8, 110, 100, 28, "SHOW/HIDE", BTN, TEXT, 11, FB),
    B("HO10_P_Dup", 112, 110, 100, 28, "DUPLI", BTN, TEXT, 11, FB),
    B("HO10_P_Del", 8, 142, 204, 28, "DELETE", BTN, RED, 11, FB)], HID)
ho10_help = F("HO10_Help", 1330, 290, 220, 180, PANEL, [title("HELP"),
    L("HO10_H_Text", 8, 30, 204, 142, "F5 play · F8 ui · Del delete · Ctrl+S save · Ctrl+Z undo", MUTED, 11)], HID)
ho10_status = F("HO10_Status", 88, 820, 700, 30, PANEL,
               [L("HO10_StatL", 8, 4, 684, 22, "home", TEXT, 12, FC)], HID)
mho_kids = [B("M_HO_Save", 8, 8, 200, 64, "SAVE", ACCENT, TEXT, 16, FB),
            B("M_HO_Refresh", 216, 8, 200, 64, "TREES", BTN, TEXT, 16, FB),
            B("M_HO_Del", 424, 8, 200, 64, "DEL", BTN, TEXT, 16, FB),
            L("M_HO_Hint", 632, 8, 700, 64, "save + refresh tree + delete", MUTED, 13)]
mho = F("M_HO", 0, 690, 1568, 80, MENU_BG, mho_kids, HID)

# ---------------- 12j. script studio R16 (SC11) ----------------
sc11_rail = F("SC11_Rail", 8, 100, 72, 200, PANEL, [title("SCRIPT"),
    B("SC11_M_Lua", 8, 30, 56, 36, "LUA", ACCENT, TEXT, 11, FB),
    B("SC11_M_Py", 8, 70, 56, 36, "PY", BTN, TEXT, 11, FB),
    B("SC11_M_Blk", 8, 110, 56, 36, "BLK", BTN, TEXT, 11, FB),
    B("SC11_Close", 8, 150, 56, 32, "X", BTN, RED, 14, FB)], HID)
sc11_list = F("SC11_List", 88, 100, 220, 200, PANEL, [title("SCRIPTS"),
    L("SC11_L_Info", 8, 30, 204, 60, "no scripts", MUTED, 11, FC),
    B("SC11_L_Prev", 8, 94, 64, 28, "<", BTN, TEXT, 14),
    B("SC11_L_Next", 76, 94, 64, 28, ">", BTN, TEXT, 14),
    B("SC11_L_Load", 144, 94, 68, 28, "LOAD", ACCENT, TEXT, 11, FB),
    B("SC11_L_NewS", 8, 126, 64, 28, "+SCR", BTN, TEXT, 11, FB),
    B("SC11_L_NewL", 76, 126, 64, 28, "+LOC", BTN, TEXT, 11, FB),
    B("SC11_L_NewM", 144, 126, 68, 28, "+MOD", BTN, TEXT, 11, FB),
    B("SC11_L_Del", 8, 158, 204, 28, "DELETE", BTN, RED, 11, FB)], HID)
sc11_edit = F("SC11_Edit", 316, 100, 500, 340, PANEL, [title("LUA EDITOR"),
    T("SC11_E_Code", 8, 30, 484, 262, "-- lua", "", 12, {"MultiLine": True, "Font": FC, "TextYAlignment": {"en": "TextYAlignment.Top"}}),
    B("SC11_E_Save", 8, 298, 120, 30, "SAVE", ACCENT, TEXT, 11, FB),
    B("SC11_E_Run", 132, 298, 120, 30, "RUN", BTN, TEXT, 11, FB),
    B("SC11_E_Stop", 256, 298, 120, 30, "STOP", BTN, TEXT, 11, FB),
    L("SC11_E_Info", 380, 298, 112, 30, "-", MUTED, 10)], HID)
sc11_py = F("SC11_Py", 316, 448, 500, 200, PANEL, [title("PYTHON->LUA"),
    T("SC11_P_Code", 8, 30, 484, 100, "print('hi')", "", 12, {"MultiLine": True, "Font": FC, "TextYAlignment": {"en": "TextYAlignment.Top"}}),
    B("SC11_P_Comp", 8, 136, 120, 30, "COMPILE", ACCENT, TEXT, 11, FB),
    B("SC11_P_Save", 132, 136, 120, 30, "SAVE LUA", BTN, TEXT, 11, FB),
    L("SC11_P_Info", 256, 136, 236, 30, "subset: print/if/while/for/def", MUTED, 10)], HID)
sc11_blk = F("SC11_Blk", 824, 100, 500, 300, PANEL, [title("BLOCKS"),
    L("SC11_B_Chain", 8, 30, 484, 130, "chain: (empty)", TEXT, 11, FC),
    B("SC11_B_Ev", 8, 164, 120, 30, "+EVENT", ACCENT, TEXT, 11, FB),
    B("SC11_B_Act", 132, 164, 120, 30, "+ACTION", BTN, TEXT, 11, FB),
    B("SC11_B_If", 256, 164, 120, 30, "+IF", BTN, TEXT, 11, FB),
    B("SC11_B_Undo", 380, 164, 104, 30, "UNDO", BTN, TEXT, 11, FB),
    T("SC11_B_Param", 8, 200, 300, 26, "param", "", 11),
    B("SC11_B_Comp", 312, 200, 88, 26, "COMP", ACCENT, TEXT, 11, FB),
    B("SC11_B_Save", 404, 200, 88, 26, "SAVE", BTN, TEXT, 11, FB),
    L("SC11_B_Info", 8, 232, 484, 30, "-", MUTED, 10)], HID)
sc11_out = F("SC11_Out", 824, 408, 500, 150, PANEL, [title("OUTPUT"),
    L("SC11_O_Log", 8, 30, 484, 80, "(log)", TEXT, 10, FC),
    B("SC11_O_Clear", 8, 114, 120, 28, "CLEAR", BTN, TEXT, 11, FB),
    B("SC11_O_Err", 132, 114, 120, 28, "ERRORS", BTN, TEXT, 11, FB)], HID)
sc11_status = F("SC11_Status", 88, 820, 700, 30, PANEL,
               [L("SC11_StatL", 8, 4, 684, 22, "script", TEXT, 12, FC)], HID)
msc_kids = [B("M_SC_Save", 8, 8, 200, 64, "SAVE", ACCENT, TEXT, 16, FB),
            B("M_SC_Run", 216, 8, 200, 64, "RUN", BTN, TEXT, 16, FB),
            B("M_SC_Stop", 424, 8, 200, 64, "STOP", BTN, TEXT, 16, FB),
            L("M_SC_Hint", 632, 8, 700, 64, "save + run + stop script", MUTED, 13)]
msc = F("M_SC", 0, 690, 1568, 80, MENU_BG, msc_kids, HID)

# ---------------- 12k. places R16 (PL12) ----------------
pl12_rail = F("PL12_Rail", 8, 100, 72, 140, PANEL, [title("PLACES"),
    B("PL12_Close", 8, 30, 56, 32, "X", BTN, RED, 14, FB)], HID)
pl12_list = F("PL12_List", 88, 100, 220, 210, PANEL, [title("PLACES"),
    L("PL12_L_Info", 8, 30, 204, 60, "no places", MUTED, 11, FC),
    B("PL12_L_Prev", 8, 94, 64, 28, "<", BTN, TEXT, 14),
    B("PL12_L_Next", 76, 94, 64, 28, ">", BTN, TEXT, 14),
    B("PL12_L_Go", 144, 94, 68, 28, "GO", ACCENT, TEXT, 11, FB),
    T("PL12_L_Id", 8, 126, 120, 26, "placeId", "", 11),
    B("PL12_L_GoId", 132, 126, 80, 26, "GO ID", BTN, TEXT, 11, FB),
    B("PL12_L_Refresh", 8, 158, 204, 28, "REFRESH", BTN, TEXT, 11, FB)], HID)
pl12_new = F("PL12_New", 88, 318, 220, 162, PANEL, [title("NEW PLACE"),
    T("PL12_N_Name", 8, 30, 204, 26, "name", "", 11),
    T("PL12_N_Tpl", 8, 62, 120, 26, "template?", "", 11),
    B("PL12_N_Create", 132, 62, 80, 26, "CREATE", ACCENT, TEXT, 11, FB),
    L("PL12_N_Info", 8, 94, 204, 60, "published game + online", MUTED, 10)], HID)
pl12_cut = F("PL12_Cut", 1330, 100, 220, 184, PANEL, [title("CUTSCENE"),
    B("PL12_C_A", 8, 30, 100, 30, "SET A", BTN, TEXT, 11, FB),
    B("PL12_C_B", 112, 30, 100, 30, "SET B", BTN, TEXT, 11, FB),
    T("PL12_C_T", 8, 66, 120, 26, "3", "3", 11),
    B("PL12_C_Play", 132, 66, 80, 26, "PLAY", ACCENT, TEXT, 11, FB),
    B("PL12_C_Stop", 8, 98, 204, 28, "STOP", BTN, TEXT, 11, FB),
    L("PL12_C_Info", 8, 130, 204, 46, "A/B = camera points", MUTED, 10)], HID)
pl12_auto = F("PL12_Auto", 1330, 292, 220, 150, PANEL, [title("AUTOMATION"),
    L("PL12_A_Text", 8, 30, 204, 112, "tools/place_automation.py (Open Cloud, needs API key)", MUTED, 11)], HID)
pl12_status = F("PL12_Status", 88, 820, 700, 30, PANEL,
               [L("PL12_StatL", 8, 4, 684, 22, "places", TEXT, 12, FC)], HID)
mpl_kids = [B("M_PL_Go", 8, 8, 200, 64, "GO", ACCENT, TEXT, 16, FB),
            B("M_PL_A", 216, 8, 200, 64, "SET A", BTN, TEXT, 16, FB),
            B("M_PL_Play", 424, 8, 200, 64, "PLAY", BTN, TEXT, 16, FB),
            L("M_PL_Hint", 632, 8, 700, 64, "teleport + cutscene A + play", MUTED, 13)]
mpl = F("M_PL", 0, 690, 1568, 80, MENU_BG, mpl_kids, HID)

for _p in [te3_rail, te3_brush, te3_mat, te3_layers, te3_history, te3_gen, te3_water, te3_status]:
    desktop_kids.append(_p)
for _p in [vp3_rail, vp3_cam, vp3_tm, vp3_meas, vp3_snap, vp3_status]:
    desktop_kids.append(_p)
for _p in [md4_rail, md4_mesh, md4_vert, md4_top, md4_io, md4_status]:
    desktop_kids.append(_p)
for _p in [an5_rail, an5_rig, an5_pose, an5_time, an5_keys, an5_io, an5_status]:
    desktop_kids.append(_p)
for _p in [ui6_rail, ui6_new, ui6_props, ui6_tree, ui6_io, ui6_status]:
    desktop_kids.append(_p)
for _p in [rw7_rail, rw7_prof, rw7_fx, rw7_sky, rw7_world, rw7_lod, rw7_status]:
    desktop_kids.append(_p)
for _p in [do8_rail, do8_stats, do8_audit, do8_opt, do8_rel, do8_mem, do8_status]:
    desktop_kids.append(_p)
for _p in [wo9_rail, wo9_info, wo9_grav, wo9_spawn, wo9_save, wo9_clean, wo9_status]:
    desktop_kids.append(_p)
for _p in [ho10_rail, ho10_file, ho10_tree, ho10_props, ho10_help, ho10_status]:
    desktop_kids.append(_p)
for _p in [sc11_rail, sc11_list, sc11_edit, sc11_py, sc11_blk, sc11_out, sc11_status]:
    desktop_kids.append(_p)
for _p in [pl12_rail, pl12_list, pl12_new, pl12_cut, pl12_auto, pl12_status]:
    desktop_kids.append(_p)
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
             "Sound", "UI", "Animate", "Physics", "Game", "Cloud", "Assets"]
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
             B("M_B_Del", 1170, 8, 150, 80, "\U0001F5D1 DEL", BTN, RED, 16, FB),
             L("M_B_Hint", 1324, 8, 236, 80, "contextual actions appear here", MUTED, 12, FG)]
mbot = F("M_Bottom", 0, 786, 1568, 96, MENU_BG, mbot_kids)
mmarquee = F("M_Marquee", 0, 0, 10, 10, INSET, [], {"Visible": False, "BackgroundTransparency": 0.45})


mobile = N("Frame", "MobileRoot",

           {"Position": P(0, 0), "Size": S(1568, 882),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "ClipsDescendants": False, "Visible": False},
           [mtop, mtools, mdrawer, mprops, mnum, msel, mhelp, mbot, mmarquee, mte, mvp, mmd, man, mui, mrw, mdo, mwo, mho, msc, mpl])

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
cmarquee = F("C_Marquee", 0, 0, 10, 10, INSET, [], {"Visible": False, "BackgroundTransparency": 0.45})
cons = N("Frame", "ConsoleRoot",
         {"Position": P(0, 0), "Size": S(1568, 882),
          "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
          "ClipsDescendants": False, "Visible": False},
         [ctop, cradial, ccursor, cpanel, clegend, cnumeric, cmarquee])

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
vpanel_kids += [B("V_Editors", 14, 404, 244, 52, "Editors", BTN, TEXT, 14, FB),
                B("V_Spatial", 262, 404, 244, 52, "Spatial: OFF", BTN, TEXT, 14, FB)]
vpanel = F("V_Panel", 524, 220, 520, 464, PANEL, vpanel_kids)
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
