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
