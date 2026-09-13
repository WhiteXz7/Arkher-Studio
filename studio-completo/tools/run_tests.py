#!/usr/bin/env python3
"""Roda todos os testes do editor Arkher (server + cliente) via lupa."""
import subprocess
import sys

HERE = "/home/user/Arkher-Studio"
TESTS = {
    "Server (Undo/Redo/Copy/Paste/Export/Import/New/Open)": "studio-completo/tools/test_server.lua",
    "Arkher Services (cloud/publish/data/i18n/toolbox/collab)": "studio-completo/tools/test_server_services.lua",
    "Cliente (Menus + acoes roteadas ao server)": "studio-completo/tools/test_client.lua",
    "Cliente (Paineis dos sistemas custom)": "studio-completo/tools/test_client_panels.lua",
    "Cliente ROUND12 (Ribbon X + Properties/Insert/Toolbox + menus clicaveis)": "studio-completo/tools/test_client_round12.lua",
    "GUIX Adopt (08 adota bake sem duplicar + 05/06/07/09 wiring)": "studio-completo/tools/test_guix_adopt.lua",
    "Input System (11 detect/layouts/4 controllers)": "studio-completo/tools/test_input.lua",
    "Terrain R10 (pinceis voxel/undo/layers/gen/hidro)": "studio-completo/tools/test_terrain.lua",
    "Terrain R10 client (12_Terrain wiring/strokes/paineis)": "studio-completo/tools/test_terrain12.lua",
    "Viewport R11 (server remap/many/rig + 13_Viewport)": "studio-completo/tools/test_viewport13.lua",
    "Modeler R12 (server Mesh*/OBJ + 14_Modeler)": "studio-completo/tools/test_modeler14.lua",
    "Animator R13 (server Anim*/IK/JSON + 15_Animator)": "studio-completo/tools/test_animator15.lua",
    "UI Editor R14 (server Ui* + 16_UI)": "studio-completo/tools/test_ui16.lua",
    "RRW R14 (server Rrw* + 17_RRW)": "studio-completo/tools/test_rrw17.lua",
    "D-O15 R15 (server Do15* + 18_Do15)": "studio-completo/tools/test_do15_18.lua",
    "World R15 (server World* + 19_World)": "studio-completo/tools/test_world19.lua",
}
ok = True
for label, path in TESTS.items():
    print("=" * 60)
    print(f"RODANDO: {label}")
    print("=" * 60)
    r = subprocess.run(
        [sys.executable, "-c",
         "import lupa,sys;"
         "lua=lupa.LuaRuntime();"
         "lua.execute(open('%s',encoding='utf-8').read(),'t')" % path]
        if False else ["python3", "-c",
                       "import lupa,sys\n"
                       "lua=lupa.LuaRuntime()\n"
                       "try:\n"
                       "  lua.execute(open('%s',encoding='utf-8').read(),'t')\n" % path +
                       "except SystemExit as e: sys.exit(e.code or 0)\n"
                       "except Exception as e: print('ERRO:',e); sys.exit(1)"],
        cwd=HERE, capture_output=True, text=True)
    print(r.stdout)
    if r.returncode != 0:
        print("STDERR:", r.stderr)
        ok = False
    else:
        # extrai a linha de resultado
        for line in r.stdout.splitlines():
            if "RESULTADO" in line or "CLIENTE:" in line:
                print(">>", line.strip())
print("=" * 60)
print("TODOS OS TESTES PASSARAM" if ok else "HA FALHAS")
sys.exit(0 if ok else 1)
