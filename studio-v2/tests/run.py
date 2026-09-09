#!/usr/bin/env python3
"""ARKHER V2 — executa os scripts finais (dist) num runtime Lua com shim Roblox.
Isso roda de verdade todos os builders de UI (caminho de codigo real), fora do Roblox."""
import sys, pathlib
from lupa import LuaRuntime

BASE = pathlib.Path(__file__).resolve().parent.parent
SHIM = (BASE / "tests" / "shim.lua").read_text(encoding="utf-8")

SUMMARY = r"""
local sg = game:GetService("StarterGui")
local n = 0
local guis = 0
local function rec(i)
	n = n + 1
	for _, c in ipairs(i:GetChildren()) do rec(c) end
end
for _, g in ipairs(sg:GetChildren()) do
	guis = guis + 1
	rec(g)
end
local regs = 0
if ARKHER_REG then
	for _ in pairs(ARKHER_REG) do regs = regs + 1 end
end
print(("RESULT guis=%d instances=%d registry=%d"):format(guis, n, regs))
"""

def run_file(path: pathlib.Path, extra: str = "") -> bool:
    lua = LuaRuntime(unpack_returned_tuples=False)
    lua.execute(SHIM)
    try:
        lua.execute(path.read_text(encoding="utf-8"))
        if extra:
            lua.execute(extra)
        lua.execute(SUMMARY)
        return True
    except Exception as e:
        print(f"  !! LUA ERROR in {path.name}: {e}")
        return False

def main():
    targets = sys.argv[1:] or ["ArkherStudio_MainUI.lua", "ArkherStudio_ALL.lua"]
    ok = True
    for t in targets:
        p = BASE / "commandbar" / t
        print(f"== run {t} ==")
        if not run_file(p):
            ok = False
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()
