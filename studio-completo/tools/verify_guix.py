"""Verifica o GUIX: descomprime chunks e confere nos/codigo/scripts. Uso: verify_guix.py [rbxl]"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import patch_rbxl as P  # noqa: E402

RBXL = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(HERE), "..", "ArkherStudio_Completo_GUIX.rbxl")
RBXL = os.path.normpath(RBXL)

NODES = ["LangPy", "Suggest", "Sug0", "Sug7", "NewPlace", "SaveAcct", "Abrir", "Export", "Conta",
         "Publish", "V2_ArkherSaveOpen", "V2_ArkherScriptEditor", "V2_ArkherInsert", "IRow0", "IRow7",
         "ArkherShell2", "MenuBar2", "Ribbon2", "M2_Terrain", "R2_Play", "T2_Panel", "C2_Log", "TL2_Panel", "FR2_Panel", "F2_Publish",
         "DesktopRoot", "MobileRoot", "ConsoleRoot", "VRoot", "R2_Anchor", "R2_Group", "M_Numeric", "C_Numeric", "C_Radial", "V_Panel",
         "D_Settings", "D_S_B1", "D_S_Reset", "D_Marquee", "M_Marquee", "C_Marquee", "M_Cat_Assets", "M_B_Del", "V_Editors", "V_Spatial", "Shell2Scale",
         "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status", "M_TE",
         "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "M_VP",
         "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status", "M_MD",
         "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "M_AN"]
CODE = ["PARTE 6B", "ArkherSEBridge", "doPaidSearch", "buyPaid", "ToolboxPaidSearch", "TeleportTo", "PublishReal", "AccountPlaces", "REBUILD EN", "dsMirrorPut",
        "code grande demais", "handlers.SvcSet", "MENUS.Assets", "handlers.TerrainSmooth",
        "handlers.Group", "handlers.PivotReset", "actions.XPivotReset", "ArkherInput", "MOBILE_MENUS",
        "handlers.SelectMany", "handlers.DeleteMany", "handlers.DuplicateMany", "multiCommit", "snapDefaults", "pickBox", "pickLasso",
        "XPublishBridge", "XTerrGen", "Spatial.toggle", "numApplyMany", "editorsRadial", "setLang",
        "handlers.TerrainStroke", "handlers.TerrainGen", "handlers.TerrainHydro", "ArkherTerrain", "XTerrainEditor",
        "handlers.TransformMany", "handlers.ViewportFrame", "handlers.RemapSet", "ArkherViewport", "XViewport",
        "handlers.MeshNew", "handlers.MeshSmooth", "handlers.MeshExportOBJ", "handlers.MeshImportOBJ", "ArkherModeler", "XModeler",
        "handlers.AnimNew", "handlers.AnimPlay", "handlers.AnimScrub", "handlers.AnimExport", "handlers.AnimImport", "ArkherAnimator", "XAnimator"]
SCRIPTS = ["Arkher_01_Nucleo", "Arkher_02_Icones", "Arkher_03_Menus",
           "Arkher_04_Gizmos", "Arkher_05_StudioX", "Arkher_06_RigX",
           "Arkher_07_MeshX", "Arkher_08_RealityX", "Arkher_09_Topbar",
           "Arkher_10_Studio", "Arkher_11_Input", "Arkher_12_Terrain", "Arkher_13_Viewport", "Arkher_14_Modeler", "Arkher_15_Animator", "ArkherEditorServer", "ArkherEngineServer"]


def main():
    data = open(RBXL, "rb").read()
    ver, nt, ni, hdr = P.read_header(data)
    chunks = P.parse_chunks(data, hdr)
    blob = b"\n".join(p for _, p in chunks)
    print(f"{os.path.basename(RBXL)}: v={ver} tipos={nt} inst={ni} chunks={len(chunks)}")
    fails = []
    for grp, names in (("node", NODES), ("code", CODE), ("script", SCRIPTS)):
        for n in names:
            hit = blob.count(n.encode("utf-8"))
            print(f"  [{grp}] {n}: {hit}")
            if hit == 0:
                fails.append(n)
    srv = os.path.join(os.path.dirname(HERE), "scripts", "server.lua")
    print(f"  server.lua disco: {os.path.getsize(srv)} bytes")
    nologin = blob.count(b"V2_ArkherLogin")
    print(f"  [absent] V2_ArkherLogin: {nologin}")
    if nologin > 0:
        fails.append("V2_ArkherLogin ainda assada!")
    if fails:
        print("FALHOU:", fails)
        sys.exit(1)
    print("VERIFY OK")


if __name__ == "__main__":
    main()
