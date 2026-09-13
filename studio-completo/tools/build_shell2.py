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

roots = ([menu, ribbon, terrain, console, selection, crumb, compass, coords,
          play, layers, region, mapp, gizmo, timeline, curves, sim, team,
          farright, farhelp] + footer)

spec = {"host_scale": 1.0, "roots": roots}
out = os.path.join(HERE, "shell2spec.json")
json.dump(spec, open(out, "w", encoding="utf-8"), ensure_ascii=False)


def count(ns):
    n = 0
    for x in ns:
        n += 1 + count(x["kids"])
    return n


print("shell2spec: %d nos em %d raizes -> %s" % (count(roots), len(roots), out))
