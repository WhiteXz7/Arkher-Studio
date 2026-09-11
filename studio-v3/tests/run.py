#!/usr/bin/env python3
"""ARKHER V3 — test runner.

Fase 1 (ALL): shim + build unico + bateria de 126 checagens.
Fase 2 (kitflow): fluxo REAL de instalacao — 2 ModuleScripts (kits) +
LocalScripts (launchers) que usam require, num runtime limpo.
"""
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "commandbar")

PRINT_CAPTURE = """
_G.__captured = {}
function print(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
  table.insert(_G.__captured, table.concat(parts, " "))
end
function __drain()
  local t = _G.__captured
  _G.__captured = {}
  return t
end
"""


def run_build():
    r = subprocess.run(["bash", os.path.join(ROOT, "build.sh")], cwd=ROOT, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout)
        print(r.stderr)
        sys.exit("BUILD FALHOU")
    print("[build] ok")


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def drain(lua):
    cap = lua.eval("__drain()")
    n = len(cap)
    return [cap[i] for i in range(1, n + 1)]


def exec(lua, name, src, *args):
    try:
        if args:
            lua.execute(src, *args)
        else:
            lua.execute(src)
    except Exception as e:
        print("== ERRO em " + name + " ==")
        for line in drain(lua):
            print(line)
        print(str(e)[:2000])
        sys.exit(1)


def main():
    run_build()
    try:
        import lupa
    except ImportError:
        print("[env] lupa nao encontrado — instalando (pip --user)...")
        r = subprocess.run(
            [sys.executable, "-m", "pip", "install", "--user", "--break-system-packages", "lupa"],
            capture_output=True, text=True)
        if r.returncode != 0:
            print(r.stdout)
            print(r.stderr)
            sys.exit("FALHA AO INSTALAR lupa (python3 -m pip install lupa)")
        import lupa

    total_pass, total_fail = 0, 0

    # ================= FASE 1: ALL =================
    print("== fase 1: ALL (core + shell + 25 UIs) ==")
    lua = lupa.LuaRuntime()
    lua.execute(PRINT_CAPTURE)
    exec(lua, "shim", read(os.path.join(HERE, "shim.lua")))
    exec(lua, "ALL", read(os.path.join(DIST, "ArkherStudio_ALL.lua")))
    exec(lua, "verify", read(os.path.join(HERE, "verify.lua")))
    lines = drain(lua)
    for line in lines:
        print(line)
    total_pass += sum(1 for l in lines if l.startswith("PASS"))
    total_fail += sum(1 for l in lines if l.startswith("FAIL"))

    # ================= FASE 2: KITFLOW =================
    print("== fase 2: kitflow (fluxo de instalacao real) ==")
    lua2 = lupa.LuaRuntime()
    lua2.execute(PRINT_CAPTURE)
    exec(lua2, "shim", read(os.path.join(HERE, "shim.lua")))
    exec(
        lua2,
        "kitflow",
        read(os.path.join(HERE, "kitflow.lua")),
        read(os.path.join(DIST, "ArkherKit_A.lua")),
        read(os.path.join(DIST, "ArkherKit_B.lua")),
        read(os.path.join(DIST, "ArkherKit_C.lua")),
        read(os.path.join(DIST, "ArkherKit_D.lua")),
        read(os.path.join(DIST, "ArkherKit_E.lua")),
        read(os.path.join(DIST, "ArkherStudio_MainUI.lua")),
        read(os.path.join(DIST, "UI_Bundle_Editors.lua")),
        read(os.path.join(DIST, "UI_Water.lua")),
    )
    lines2 = drain(lua2)
    for line in lines2:
        print(line)
    total_pass += sum(1 for l in lines2 if l.startswith("PASS"))
    total_fail += sum(1 for l in lines2 if l.startswith("FAIL"))

    # ================= RESULTADO =================
    all_lines = lines + lines2
    fails = [l for l in all_lines if l.startswith("FAIL")]
    print(f"\n== RESULT: {total_pass} PASS / {total_fail} FAIL ==")
    if fails:
        print("\n".join(fails))
        sys.exit(1)
    print("TODOS OS TESTES PASSARAM")


if __name__ == "__main__":
    main()
