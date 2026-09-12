#!/usr/bin/env python3
"""Gera tools/baked_fixture.lua — arvores shell+v2+popups+rig/mesh como tabela
Lua + construtor generico, p/ os testes simularem a bake do .rbxl.
(Uso exclusivo em teste; nada disso vai para o .rbxl.)
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def emit(v, out):
    if v is None:
        out.append("nil")
    elif v is True:
        out.append("true")
    elif v is False:
        out.append("false")
    elif isinstance(v, (int, float)):
        out.append(repr(float(v)) if isinstance(v, float) else str(v))
    elif isinstance(v, str):
        out.append(lua_str(v))
    elif isinstance(v, list):
        out.append("{")
        for i in v:
            emit(i, out)
            out.append(",")
        out.append("}")
    elif isinstance(v, dict):
        out.append("{")
        for k, i in v.items():
            if isinstance(k, str) and k.isidentifier():
                out.append(k + "=")
            else:
                out.append("[")
                emit(k, out)
                out.append("]=")
            emit(i, out)
            out.append(",")
        out.append("}")
    else:
        raise ValueError(f"tipo inesperado: {type(v)}")


BUILDER = r'''
-- construtor generico da fixture (somente teste)
local function enumPath(path)
  local o = Enum
  for part in tostring(path):gmatch("[^.]+") do o = o[part] end
  return o
end
function buildFixtureTree(n, parent)
  local o = Instance.new(n.cls)
  o.Name = n.name
  for k, v in pairs(n.props) do
    if type(v) == "table" then
      if v.c3 then o[k] = Color3.new(v.c3[1], v.c3[2], v.c3[3])
      elseif v.u2 then o[k] = UDim2.new(v.u2[1], v.u2[2], v.u2[3], v.u2[4])
      elseif v.u1 then o[k] = UDim.new(v.u1[1], v.u1[2])
      elseif v.v2 then o[k] = Vector2.new(v.v2[1], v.v2[2])
      elseif v.en then o[k] = enumPath(v.en) end
    else o[k] = v end
  end
  o.Parent = parent
  for _, kd in ipairs(n.kids) do buildFixtureTree(kd, o) end
  return o
end
'''


def main():
    spec = json.load(open(os.path.join(HERE, "guix_spec.json"), encoding="utf-8"))
    trees = spec["shell"] + spec["v2"] + [spec["popups"]] + spec["extra"]
    out = ["-- baked_fixture.lua — GERADO por gen_fixture.py. Nao editar.\nFIXTURE_TREES = "]
    emit(trees, out)
    out.append("\n" + BUILDER)
    p = os.path.join(HERE, "baked_fixture.lua")
    with open(p, "w", encoding="utf-8") as f:
        f.write("".join(out))
    print(f"fixture: {len(trees)} raizes -> {p} ({os.path.getsize(p)} bytes)")


if __name__ == "__main__":
    main()
