#!/usr/bin/env python3
"""Gera tools/shellspec.json — a TOPBAR UNICA do Arkher Studio (R20).

ArkherTop (Frame 1568x120, y0) — o unico ribbon/topbar do Studio:
  HeaderRow (Frame 26px): H_Logo + H_Slogan + H_Search + H_Bell + H_User
  TabStrip (ScrollingFrame 34px): 18 abas Tab_<T> (icone + Lbl, 80x30)
  Ribbon (Frame 58px): Page_<T> (ScrollingFrame) por aba, cada uma com
    RibbonBtn_<T>_<id> (TextButton 62x54 + Icon 28x28 + Lbl 2 linhas)
  Maximo 20 botoes por aba (regra do quadro-1 da referencia Renascido).
ArkherMsg (toast inferior-direito, Visible=false)
Icones: kids copiados de tools/iconspec.json (posicoes em escala -> adaptam).

FONTE UNICA da tabela abas/botoes/acoes — 09_Topbar.lua consome BUTTONS.
Acao: ("menus", cmd)      -> MenusBus:Invoke(cmd)
       ("core", key)        -> ClientBus SetMode/SetSpace
       ("api", action)      -> ClientBus API (Undo/Redo)
       ("lock",)            -> PropsAll + SetAny Locked (09_Topbar).
Linha: (bid, label EN, icon, acao, label PT). Dropdowns desktop aposentados
no R20 (todos os 166 itens de menu viraram botoes de pagina); o caminho
"menu"/buildMenu segue vivo p/ mobile/console/VR (11_Input) e 05_StudioX.
"""
import copy
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

# (tab, [botoes]) — icone/PT da aba em TABMETA (abaixo)
# Regra: <= 20 botoes por aba. Cobertura: 166 itens dos 18 menus + funcoes
# ribbon-only do R18 (Select/Move/Rotate/Scale, Lock, LocalGlobal, Undo/Redo,
# SavePlaceAccount, OpenPublish, OpenData, OpenLocalization, OpenToolbox,
# OpenCloud, OpenPlugins, OpenCollaboration, Collaborate, Invites, Changes,
# Account) = 163 botoes. "Menu"-openers do CREATE eram navegacao (dropdowns),
# aposentados: os ITENS que eles abriam estao todos nas paginas.
TABMETA = {
    "HOME": ("home", "Início"),
    "TERRAIN": ("terrain", "Terreno"),
    "OBJECTS": ("boxG", "Objetos"),
    "LANDSCAPE": ("cubeT", "Paisagem"),
    "SCENES": ("ws", "Cenas"),
    "UI": ("dock", "Interface"),
    "SCRIPTS": ("script", "Scripts"),
    "PLUGINS": ("plug", "Plugins"),
    "WORLD": ("globe", "Mundo"),
    "MODELS": ("model", "Modelos"),
    "MATERIALS": ("gem", "Materiais"),
    "LIGHTING": ("bulb", "Iluminação"),
    "CLIMATE": ("cloud", "Clima"),
    "WATER": ("drop", "Água"),
    "CAMERA": ("camera", "Câmera"),
    "TOOLS": ("plugin", "Ferramentas"),
    "SETTINGS": ("settings", "Configurações"),
    "HELP": ("info", "Ajuda"),
}


TABS = [
    ("HOME", [
        ("New", "New", "plus", ("menus", "New"), "Novo"),
        ("Open", "Open", "open", ("menus", "Open"), "Abrir"),
        ("OpenEmpty", "Open\nEmpty", "minus", ("menus", "OpenEmpty"), "Abrir\nVazio"),
        ("OpenTerrain", "Terrain", "terrain", ("menus", "OpenTerrain"), "Terreno"),
        ("Save", "Save", "save", ("menus", "Save"), "Salvar"),
        ("SaveCloud", "Cloud", "cloud", ("menus", "SaveCloud"), "Nuvem"),
        ("Export", "Export", "share", ("menus", "Export"), "Exportar"),
        ("Import", "Import", "folder", ("menus", "Import"), "Importar"),
        ("Exit", "Exit", "close", ("menus", "Exit"), "Sair"),
        ("Undo", "Undo", "undo", ("api", "Undo"), "Desfazer"),
        ("Redo", "Redo", "redo", ("api", "Redo"), "Refazer"),
        ("Cut", "Cut", "cut", ("menus", "Cut"), "Cortar"),
        ("Copy", "Copy", "copy", ("menus", "Copy"), "Copiar"),
        ("Paste", "Paste", "paste", ("menus", "Paste"), "Colar"),
        ("Duplicate", "Duplicate", "plus", ("menus", "Duplicate"), "Duplicar"),
        ("Rename", "Rename", "textA", ("menus", "Rename"), "Renomear"),
        ("Delete", "Delete", "minus", ("menus", "Delete"), "Excluir"),
        ("Play", "Play", "play", ("menus", "RunToggle"), "Jogar"),
        ("Pause", "Pause", "pause", ("menus", "RunPause"), "Pausar"),
        ("Stop", "Stop", "close", ("menus", "RunStop"), "Parar"),
    ]),
    ("TERRAIN", [
        ("TerrainEditor", "Terrain\nEditor", "terrain", ("menus", "XTerrainEditor"), "Editor de\nTerreno"),
        ("TerrainX", "Terrain X", "open", ("menus", "XOpenTerrain"), "Terreno X"),
        ("TerrainGen", "Generator", "open", ("menus", "XOpenTerrainGen"), "Gerador"),
        ("VoxelProbe", "Voxel\nProbe", "data", ("menus", "XOpenTerrainVoxel"), "Sonda\nVoxel"),
        ("TerrainProbe", "Probe", "search", ("menus", "XOpenTerrainProbe"), "Sonda"),
        ("Generate", "Generate", "plus", ("menus", "XTerrGen"), "Gerar"),
        ("Erode", "Erosion", "minus", ("menus", "XTerrErode"), "Erosão"),
        ("Crater", "Crater", "plus", ("menus", "XTerrCrater"), "Cratera"),
        ("Flatten", "Flatten", "plate", ("menus", "XTerrFlat"), "Aplainar"),
        ("Smooth", "Smooth", "share", ("menus", "XTerrSmooth"), "Suavizar"),
        ("Noise", "Noise", "data", ("menus", "XTerrNoise"), "Ruído"),
    ]),
    ("OBJECTS", [
        ("Part", "Part", "cubeW", ("menus", "InsertPart"), "Peça"),
        ("Folder", "Folder", "folder", ("menus", "InsertFolder"), "Pasta"),
        ("Model", "Model", "model", ("menus", "InsertModel"), "Modelo"),
        ("Script", "Script", "script", ("menus", "InsertScript"), "Script"),
        ("Text", "Text", "textA", ("menus", "InsertTextLabel"), "Texto"),
        ("InsertFull", "Full\nInsert", "plus", ("menus", "InsertFull"), "Inserir\nTudo"),
        ("Group", "Group", "group", ("menus", "XGroup"), "Agrupar"),
        ("Ungroup", "Ungroup", "ungroup", ("menus", "XUngroup"), "Desagrupar"),
        ("PivotReset", "Reset\nPivot", "share", ("menus", "XPivotReset"), "Zerar\nPivô"),
        ("AlignX", "Align X", "share", ("menus", "XAlignX"), "Alinhar X"),
        ("AlignY", "Align Y", "share", ("menus", "XAlignY"), "Alinhar Y"),
        ("AlignZ", "Align Z", "share", ("menus", "XAlignZ"), "Alinhar Z"),
        ("DistX", "Dist X", "share", ("menus", "XDistX"), "Distrib X"),
        ("DistY", "Dist Y", "share", ("menus", "XDistY"), "Distrib Y"),
        ("DistZ", "Dist Z", "share", ("menus", "XDistZ"), "Distrib Z"),
        ("MirrX", "Mirror X", "share", ("menus", "XMirrX"), "Espelho X"),
        ("MirrY", "Mirror Y", "share", ("menus", "XMirrY"), "Espelho Y"),
        ("MirrZ", "Mirror Z", "share", ("menus", "XMirrZ"), "Espelho Z"),
        ("Lock", "Lock", "lock", ("lock",), "Travar"),
        ("LocalGlobal", "Local\nGlobal", "globe", ("core", "LocalGlobal"), "Local\nGlobal"),
    ]),
    ("LANDSCAPE", [
        ("Life", "Life", "open", ("menus", "XOpenVida"), "Vida"),
        ("EcoSim", "Eco Sim", "globe", ("menus", "XVidaEco"), "Eco Sim"),
        ("Human", "Human", "people", ("menus", "XVidaHumano"), "Humano"),
        ("NPC", "NPC", "playercard", ("menus", "XVidaNpc"), "NPC"),
        ("City", "City", "open", ("menus", "XOpenCidade"), "Cidade"),
        ("Village", "Village", "home", ("menus", "XCidadeVila"), "Vila"),
        ("Metro", "Metro", "model", ("menus", "XCidadeMetro"), "Metrô"),
    ]),
    ("SCENES", [
        ("Places", "Places", "open", ("menus", "XPlaces"), "Lugares"),
        ("PlacesProfile", "My\nPlaces", "folder", ("menus", "PlacesProfile"), "Meus\nLugares"),
        ("HomeEditor", "Home", "home", ("menus", "XHome"), "Início"),
        ("SaveToArkher", "Save to\nArkher", "data", ("menus", "SavePlaceAccount"), "Salvar na\nArkher"),
        ("Publish", "Publish", "save", ("menus", "Publish"), "Publicar"),
        ("PublishBridge", "Bridge", "cloud", ("menus", "XPublishBridge"), "Ponte"),
        ("ResetWorkspace", "Reset\nWorld", "rotate", ("menus", "ResetWorkspace"), "Zerar\nMundo"),
        ("RecKeyA", "Rec Key\nA", "pin", ("menus", "AnimKeyA"), "Gravar A"),
        ("RecKeyB", "Rec Key\nB", "pin", ("menus", "AnimKeyB"), "Gravar B"),
        ("PlayA", "Play A", "play", ("menus", "AnimGoA"), "Tocar A"),
        ("PlayB", "Play B", "play", ("menus", "AnimGoB"), "Tocar B"),
        ("AnimStop", "Stop", "close", ("menus", "AnimStop"), "Parar"),
    ]),
    ("UI", [
        ("UIEditor", "UI\nEditor", "open", ("menus", "XUI"), "Editor de\nUI"),
        ("Colors", "Colors", "open", ("menus", "XOpenCores"), "Cores"),
        ("PropsPlus", "Props+", "open", ("menus", "XOpenProps"), "Props+"),
        ("Output", "Output", "open", ("menus", "XOpenOutput"), "Saída"),
        ("ClearOutput", "Clear\nOutput", "minus", ("menus", "XOutputClear"), "Limpar\nSaída"),
        ("Hierarchy", "Hierarchy", "share", ("menus", "ToggleHierarchy"), "Hierarquia"),
        ("Properties", "Properties", "data", ("menus", "ToggleProperties"), "Props"),
    ]),
    ("SCRIPTS", [
        ("ScriptStudio", "Script\nStudio", "script", ("menus", "ScriptStudio"), "Script\nStudio"),
        ("AllScripts", "All\nScripts", "open", ("menus", "XOpenScripts"), "Todos\nScripts"),
        ("Python", "Python", "open", ("menus", "XOpenPy"), "Python"),
        ("CommandBar", "Command\nBar", "open", ("menus", "XOpenComando"), "Barra de\nComando"),
        ("ScriptEditor", "Script\nEditor", "open", ("menus", "XScript"), "Editor de\nScript"),
    ]),
    ("PLUGINS", [
        ("Plugins", "Plugins", "plug", ("menus", "OpenPlugins"), "Plugins"),
        ("CloudInfo", "Cloud\nInfo", "cloud", ("menus", "OpenCloud"), "Nuvem\nInfo"),
        ("Toolbox", "Toolbox", "toolbox", ("menus", "OpenToolbox"), "Toolbox"),
        ("CreatorStore", "Creator\nStore", "open", ("menus", "XOpenToolbox"), "Loja"),
        ("CollabSettings", "Collab", "people", ("menus", "OpenCollaboration"), "Colab"),
        ("Collaborate", "Collaborate", "playersI", ("menus", "Collaborate"), "Colaborar"),
        ("Invites", "Invites", "chat", ("menus", "Invites"), "Convites"),
        ("Changes", "Changes", "repfirst", ("menus", "Changes"), "Mudanças"),
        ("Account", "Account", "playercard", ("menus", "Account"), "Conta"),
    ]),
    ("WORLD", [
        ("WorldEditor", "World", "globe", ("menus", "XWorld"), "Mundo"),
        ("Space", "Space", "open", ("menus", "XOpenEspaco"), "Espaço"),
        ("SolarSystem", "Solar\nSystem", "data", ("menus", "XEspacoSolar"), "Sistema\nSolar"),
        ("EarthMoon", "Earth-\nMoon", "gem", ("menus", "XEspacoTerraLua"), "Terra-\nLua"),
        ("GameProps", "Game\nProps", "settings", ("menus", "GameProperties"), "Props do\nJogo"),
    ]),
    ("MODELS", [
        ("ModelerPRO", "Modeler\nPRO", "open", ("menus", "XModeler"), "Modeler\nPRO"),
        ("Block", "Block", "plus", ("menus", "XSpawnBlock"), "Bloco"),
        ("Wedge", "Wedge", "plus", ("menus", "XSpawnWedge"), "Cunha"),
        ("Cylinder", "Cylinder", "plus", ("menus", "XSpawnCyl"), "Cilindro"),
        ("Ball", "Ball", "plus", ("menus", "XSpawnBall"), "Esfera"),
        ("Corner", "Corner", "plus", ("menus", "XSpawnCorner"), "Canto"),
        ("Truss", "Truss", "plus", ("menus", "XSpawnTruss"), "Treliça"),
        ("MeshPart", "Mesh", "plus", ("menus", "XMeshPart"), "Malha"),
        ("Join", "Join", "group", ("menus", "XJoin"), "Unir"),
        ("Split", "Split", "ungroup", ("menus", "XSplit"), "Separar"),
        ("Modeler", "Modeler", "open", ("menus", "XOpenModeler"), "Modelador"),
        ("ModelerPrims", "Prims", "open", ("menus", "XOpenModelerPrim"), "Primitivos"),
        ("RopeDemo", "Rope\nDemo", "play", ("menus", "XCordaDemo"), "Demo\nCorda"),
        ("RopeBridge", "Rope\nBridge", "plate", ("menus", "XCordaPonte"), "Ponte de\nCorda"),
        ("Ropes", "Ropes", "open", ("menus", "XOpenCordas"), "Cordas"),
    ]),
    ("MATERIALS", [
        ("Color", "Color", "data", ("menus", "XColor"), "Cor"),
        ("Material", "Material", "gem", ("menus", "XMaterial"), "Material"),
        ("Surface", "Surface", "plate", ("menus", "XSurface"), "Superfície"),
        ("Decal", "Decal", "plus", ("menus", "XDecal"), "Decalque"),
        ("Texture", "Texture", "plus", ("menus", "XTexture"), "Textura"),
    ]),
    ("LIGHTING", [
        ("RRW", "RRW\nRender", "open", ("menus", "XRRW"), "RRW"),
        ("Sky", "Sky", "cloud", ("menus", "XAtmosCeu"), "Céu"),
        ("TimeOfDay", "Time", "rotate", ("menus", "XAtmosTempo"), "Hora"),
        ("FXPanel", "FX", "open", ("menus", "XOpenFx"), "FX"),
        ("Fire", "Fire", "fire", ("menus", "XFxFogo"), "Fogo"),
        ("Atmosphere", "Atmo-\nsphere", "open", ("menus", "XOpenAtmos"), "Atmosfera"),
        ("Light", "Light", "bulb", ("menus", "XLight"), "Luz"),
        ("Particles", "Particles", "data", ("menus", "XParticles"), "Partículas"),
    ]),
    ("CLIMATE", [
        ("Climate", "Climate", "open", ("menus", "XOpenClima"), "Clima"),
        ("ClimateOn", "Climate\nOn", "check", ("menus", "XClimaOn"), "Clima\nOn"),
        ("ClimateOff", "Climate\nOff", "close", ("menus", "XClimaOff"), "Clima\nOff"),
        ("Rain", "Rain", "drop", ("menus", "XFxChuva"), "Chuva"),
    ]),
    ("WATER", [
        ("Ocean", "Ocean", "drop", ("menus", "XAguaOceano"), "Oceano"),
        ("Buoyancy", "Buoyancy", "anchor", ("menus", "XAguaFlutua"), "Flutuar"),
        ("WaterTools", "Water\nTools", "open", ("menus", "XOpenWater"), "Ferram.\nÁgua"),
    ]),
    ("CAMERA", [
        ("Camera", "Camera", "camera", ("menus", "XCamera"), "Câmera"),
        ("Viewport", "Viewport", "open", ("menus", "XViewport"), "Viewport"),
        ("Fullscreen", "Full-\nscreen", "expand", ("menus", "Fullscreen"), "Tela\ncheia"),
        ("ResetLayout", "Reset\nLayout", "rotate", ("menus", "ResetLayout"), "Zerar\nLayout"),
    ]),
    ("TOOLS", [
        ("Fabricate", "Fabricate", "open", ("menus", "XOpenFabricar"), "Fabricar"),
        ("FabList", "Fab\nList", "textA", ("menus", "XFabricarList"), "Lista\nFab"),
        ("Snap", "Snap", "snap", ("menus", "XSnap"), "Encaixe"),
        ("Transform", "Transform", "transform", ("menus", "XTransform"), "Transformar"),
        ("Sound", "Sound", "note", ("menus", "XSound"), "Som"),
        ("DO15", "D-O15", "open", ("menus", "XDO15"), "D-O15"),
        ("AnimatorPRO", "Animator\nPRO", "open", ("menus", "XAnimator"), "Animator\nPRO"),
        ("Animator", "Animator", "open", ("menus", "XOpenAnimator"), "Animador"),
        ("RigEditor", "Rig", "open", ("menus", "XOpenAnimatorRig"), "Rig"),
        ("PhysAnim", "Phys\nAnim", "open", ("menus", "XOpenAnimatorPhys"), "Anim\nFísica"),
        ("AudioTools", "Audio", "open", ("menus", "XOpenAudio"), "Áudio"),
        ("AudioInt", "Audio\nInt", "play", ("menus", "XAudioInt"), "Áudio\nInter"),
        ("Mixer", "Mixer", "share", ("menus", "XAudioMixer"), "Mixer"),
        ("Anchor", "Anchor", "anchor", ("menus", "XAnchor"), "Ancorar"),
        ("Collision", "Collision", "share", ("menus", "XCollision"), "Colisão"),
        ("Select", "Select", "select", ("core", "Select"), "Selecionar"),
        ("Move", "Move", "move", ("core", "MoveScale"), "Mover"),
        ("Rotate", "Rotate", "rotate", ("core", "Rotate"), "Girar"),
        ("Scale", "Scale", "scaleI", ("core", "Scale"), "Escala"),
    ]),
    ("SETTINGS", [
        ("GameSettings", "Game\nSettings", "settings", ("menus", "OpenSettings"), "Config\nJogo"),
        ("Data", "Data", "data", ("menus", "OpenData"), "Dados"),
        ("Language", "Lang", "textA", ("menus", "OpenLocalization"), "Idioma"),
        ("Settings", "Settings", "dock", ("menus", "XSettings"), "Ajustes"),
        ("LangPT", "PT-BR", "globe", ("menus", "XLangPT"), "PT-BR"),
        ("ProjSettings", "Project\nSettings", "folder", ("menus", "ProjectSettings"), "Config\nProjeto"),
    ]),
    ("HELP", [
        ("StudioHelp", "Studio\nHelp", "bulb", ("menus", "HelpStudio"), "Ajuda do\nStudio"),
        ("CommandHelp", "Command\nHelp", "textA", ("menus", "XComandoHelp"), "Ajuda\nComando"),
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
HEADER_H = 26
STRIP_H = 34
TAB_W = 80
TAB_H = 30
BTN_W = 62
BTN_H = 54
RIBBON_H = TOP_H - HEADER_H - STRIP_H - 2  # 58 (1px dividers x2)


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

    # regra do quadro-1: <= 20 botoes por aba
    for t, btns in TABS:
        assert len(btns) <= 20, f"aba {t}: {len(btns)} botoes (>20)"

    # ---- HeaderRow: logo + slogan + search + bell + user ----
    search_x = 1568 - 8 - 82 - 4 - 28 - 4 - 180
    header_kids = [
        N("TextLabel", "H_Logo", {
            "Size": U2(0, 170, 0, 22), "Position": U2(0, 8, 0, 2),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "⬢  ARKHER STUDIOS",
            "Font": {"en": "Font.GothamBold"}, "TextSize": 13.0,
            "TextColor3": GOLD, "TextXAlignment": {"en": "TextXAlignment.Left"},
        }, []),
        N("TextLabel", "H_Slogan", {
            "Size": U2(0, 800, 0, 22), "Position": U2(0, 384, 0, 2),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "CREATE ANYTHING. AT ANY SCALE. ANYWHERE.",
            "Font": {"en": "Font.Gotham"}, "TextSize": 11.0,
            "TextColor3": MUTED, "TextXAlignment": {"en": "TextXAlignment.Center"},
        }, []),
        N("TextBox", "H_Search", {
            "Size": U2(0, 180, 0, 22), "Position": U2(0, search_x, 0, 2),
            "BackgroundColor3": BTN_BG, "BorderSizePixel": 0,
            "Text": "", "PlaceholderText": "Search tools, assets...",
            "PlaceholderColor3": MUTED,
            "Font": {"en": "Font.Gotham"}, "TextSize": 12.0,
            "TextColor3": TXT, "TextXAlignment": {"en": "TextXAlignment.Left"},
            "ClearTextOnFocus": False,
        }, [corner(6), stroke(BTN_EDGE, 1), hpad(8, 0, 8)]),
        N("TextButton", "H_Bell", {
            "Size": U2(0, 28, 0, 24), "Position": U2(0, search_x + 184, 0, 1),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "", "AutoButtonColor": False, "Active": True,
        }, [N("Frame", "Icon", {
            "Size": U2(0, 18, 0, 18), "Position": U2(0, 5, 0, 3),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
        }, icon_kids("bell"))]),
        N("TextButton", "H_User", {
            "Size": U2(0, 82, 0, 24), "Position": U2(0, search_x + 216, 0, 1),
            "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            "Text": "● dev", "Font": {"en": "Font.GothamBold"}, "TextSize": 12.0,
            "TextColor3": GREEN, "AutoButtonColor": False, "Active": True,
        }, []),
    ]
    right_edge = search_x + 216 + 82
    assert right_edge <= 1568, f"header overflow: {right_edge}"
    header = N("Frame", "HeaderRow", {
        "Size": U2(1, 0, 0, HEADER_H), "Position": U2(0, 0, 0, 0),
        "BackgroundColor3": STRIP_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, header_kids)

    tab_defs = [(t, TABMETA[t][0]) for t, _b in TABS]
    # ---- TabStrip: 18 abas icone + Lbl ----
    tabs = []
    for i, (t, ti) in enumerate(tab_defs):
        active = (i == 0)
        tab = N("TextButton", f"Tab_{t}", {
            "Size": U2(0, TAB_W, 0, TAB_H), "Position": U2(0, 0, 0, 0),
            "LayoutOrder": float(i),
            "BackgroundColor3": TAB_ACTIVE_BG if active else STRIP_BG,
            "BackgroundTransparency": 0.0 if active else 1.0,
            "BorderSizePixel": 0, "ZIndex": 31, "Text": "",
            "AutoButtonColor": False, "Active": True,
        }, [corner(6),
            N("Frame", "Icon", {
                "Size": U2(0, 16, 0, 16), "Position": U2(0, 32, 0, 1),
                "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
            }, icon_kids(ti)),
            N("TextLabel", "Lbl", {
                "Size": U2(0, TAB_W - 4, 0, 11), "Position": U2(0, 2, 0, 17),
                "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                "Text": t, "Font": {"en": "Font.GothamBold"},
                "TextSize": 10.0,
                "TextColor3": TXT if active else TXT2,
                "TextXAlignment": {"en": "TextXAlignment.Center"},
                "TextTruncate": {"en": "TextTruncate.AtEnd"},
            }, []),
            N("Frame", "ActivePill", {
                "Size": U2(0, TAB_W - 16, 0, 2), "Position": U2(0, 8, 0, 28),
                "BackgroundColor3": ACCENT, "BorderSizePixel": 0,
                "Visible": active}, [])])
        tabs.append(tab)
    strip = N("ScrollingFrame", "TabStrip", {
        "Size": U2(1, 0, 0, STRIP_H), "Position": U2(0, 0, 0, HEADER_H),
        "BackgroundColor3": STRIP_BG, "BorderSizePixel": 0, "ZIndex": 30,
        "CanvasSize": U2(0, len(tab_defs) * (TAB_W + 4) + 12, 0, 0),
        "ScrollBarThickness": 3, "ScrollBarImageColor3": BTN_EDGE,
        "Active": True, "ClipsDescendants": True,
    }, [hlist(4), hpad(6, 2, 6)] + tabs)

    # ---- Ribbon pages ----
    pages = []
    n_btns = 0
    for i, (t, btns) in enumerate(TABS):
        items = []
        for j, (bid, label, icon, _act, _pt) in enumerate(btns):
            n_btns += 1
            btn = N("TextButton", f"RibbonBtn_{t}_{bid}", {
                "Size": U2(0, BTN_W, 0, BTN_H), "Position": U2(0, 0, 0, 0),
                "LayoutOrder": float(j),
                "BackgroundColor3": BTN_BG, "BorderSizePixel": 0,
                "ZIndex": 31, "Text": "",
                "AutoButtonColor": False, "Active": True,
            }, [corner(8), stroke(BTN_EDGE, 1),
                N("Frame", "Icon", {
                    "Size": U2(0, 28, 0, 28), "Position": U2(0, 17, 0, 1),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                }, icon_kids(icon)),
                N("TextLabel", "Lbl", {
                    "Size": U2(0, BTN_W - 6, 0, 22), "Position": U2(0, 3, 0, 30),
                    "BackgroundTransparency": 1.0, "BorderSizePixel": 0,
                    "Text": label, "Font": {"en": "Font.Gotham"},
                    "TextSize": 10.0, "TextColor3": TXT2,
                    "TextXAlignment": {"en": "TextXAlignment.Center"},
                    "TextYAlignment": {"en": "TextYAlignment.Top"},
                    "TextWrapped": True,
                }, [])])
            items.append(btn)
        page_w = len(btns) * (BTN_W + 6) + 16
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
        "Position": U2(0, 0, 0, HEADER_H + STRIP_H + 1),
        "BackgroundColor3": RIBBON_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, pages)
    top = N("Frame", "ArkherTop", {
        "Size": U2(1, 0, 0, TOP_H), "Position": U2(0, 0, 0, 0),
        "BackgroundColor3": TOP_BG, "BorderSizePixel": 0,
        "ZIndex": 30, "Active": True, "ClipsDescendants": True,
    }, [header,
        N("Frame", "HeaderDivider", {
            "Size": U2(1, 0, 0, 1), "Position": U2(0, 0, 0, HEADER_H - 1),
            "BackgroundColor3": DIVIDER, "BorderSizePixel": 0}, []),
        strip,
        N("Frame", "TabDivider", {
            "Size": U2(1, 0, 0, 1),
            "Position": U2(0, 0, 0, HEADER_H + STRIP_H),
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
    print(f"shell: header + {len(tab_defs)} abas, {n_btns} botoes, "
          f"{total} instancias (topbar unica {TOP_H}px)")
    print(f"spec salva: tools/shellspec.json "
          f"({os.path.getsize(os.path.join(HERE, 'shellspec.json'))} bytes)")


if __name__ == "__main__":
    main()
