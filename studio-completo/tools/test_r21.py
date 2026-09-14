#!/usr/bin/env python3
"""R21 smoke: Lua real carrega o bootstrap (sem init) com mocks e valida."""
import pathlib, sys
from lupa import LuaRuntime

ROOT = pathlib.Path(__file__).resolve().parents[1]
BOOT = ROOT / "arkher_bootstrap.lua"

PRELUDE = r"""
-- mocks minimos (provam separacao limpa: carga nao toca o DataModel)
local _nilfn = function() return {} end
Color3 = { fromRGB = _nilfn, new = _nilfn }
UDim2 = { new = _nilfn, fromOffset = _nilfn }
UDim = { new = _nilfn }
Vector3 = { new = _nilfn }
CFrame = { new = _nilfn, Angles = _nilfn }
BrickColor = { new = _nilfn }
Enum = setmetatable({}, { __index = function() return {} end })
Instance = { new = function() return setmetatable({}, { __index = function() return function() return {} end end }) end }
workspace = {}
game = { GetService = function(n)
  if n == "RunService" then return { Heartbeat = { Connect = function() end }, RenderStepped = { Connect = function() end, Wait = function() end } } end
  return {}
end }
"""

lua = LuaRuntime()
blob = BOOT.read_text()
# remove init.lua section (boot real precisa do Roblox)
head, sep, tail = blob.partition("-- ===== init.lua =====")
assert sep, "secao init nao encontrada"
body = head + "-- init.lua removido no teste\n"
try:
    lua.compile(body)
    print("compile: OK")
except Exception as e:
    print("compile: FAIL", str(e)[:200])
    sys.exit(1)
try:
    lua.execute(PRELUDE + body)
    print("load: OK")
except Exception as e:
    print("load: FAIL", str(e)[:500])
    sys.exit(1)
res = lua.eval("""
(function()
  local E = _G.ARKHER
  local ok, errs, n = E.registry.validate(E.ACTIONS, E.icons)
  local nacts = 0 for _, _ in pairs(E.ACTIONS) do nacts = nacts + 1 end
  local nicons = 0 for _, _ in pairs(ICONS) do nicons = nicons + 1 end
  return { ok = ok, errs = errs, n = n, tabs = #E.registry.tabs,
           acts = nacts, icons = nicons }
end)()""")
print("tabs=%s cmds=%s acts=%s icons=%s valid=%s" % (
    res["tabs"], res["n"], res["acts"], res["icons"], res["ok"]))
if not res["ok"]:
    errs = lua.eval("""
(function()
  local E = _G.ARKHER
  local ok, errs = E.registry.validate(E.ACTIONS, E.icons)
  local out = {}
  for i = 1, math.min(#errs, 15) do out[#out+1] = errs[i] end
  return table.concat(out, "\\n")
end)()""")
    print(errs)
    sys.exit(1)
assert res["tabs"] == 30 and res["n"] == 1200, "contagem errada"
print("R21 SMOKE: PASS")
