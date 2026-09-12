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
         "Publish", "V2_ArkherSaveOpen", "V2_ArkherScriptEditor", "V2_ArkherInsert", "IRow0", "IRow7"]
CODE = ["PARTE 6B", "ArkherSEBridge", "doPaidSearch", "buyPaid", "ToolboxPaidSearch", "TeleportTo", "PublishReal", "AccountPlaces", "1-CLIQUE", "dsMirrorPut",
        "code grande demais", "FASE 3"]
SCRIPTS = ["Arkher_01_Nucleo", "Arkher_02_Icones", "Arkher_03_Menus",
           "Arkher_04_Gizmos", "Arkher_05_StudioX", "Arkher_06_RigX",
           "Arkher_07_MeshX", "Arkher_08_RealityX", "Arkher_09_Topbar",
           "Arkher_10_Studio", "ArkherEditorServer", "ArkherEngineServer"]


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
