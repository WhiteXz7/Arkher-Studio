#!/usr/bin/env python3
"""Verifica o CB_UI_TODAS_UIS.lua: executa num stub limpo e compara a
árvore gerada (classe/nome/parent + props) com /tmp/v3uis.json + /tmp/v2ui.json.
Uso: python3 tools/verify_cb_uis.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CB = os.path.join(ROOT, "commandbar", "estrutura-completa", "CB_UI_TODAS_UIS.lua")
sys.path.insert(0, HERE)
import lupa  # noqa: E402

V3 = json.load(open("/tmp/v3uis.json"))
V2 = json.load(open("/tmp/v2ui.json"))
expected_guis = {**V3["guis"], **V2["guis"]}
v3_guis = set(V3["guis"].keys())

STUB = r"""
local function mk(cls)
  local o = setmetatable({
    __props = { ClassName = cls, Name = cls },
    __children = {},
  }, {
    __index = function(t, k)
      local p = rawget(t, "__props")
      if p[k] ~= nil then return p[k] end
      local m = _METHODS[k]
      if m then return m end
      return nil
    end,
    __newindex = function(t, k, v)
      if k == "Parent" then
        local old = rawget(t, "__props").Parent
        if old then
          local kids = rawget(old, "__children")
          for i = #kids, 1, -1 do if kids[i] == t then table.remove(kids, i) break end end
        end
        rawget(t, "__props").Parent = v
        if v then table.insert(rawget(v, "__children"), t) end
      else
        rawget(t, "__props")[k] = v
      end
    end,
  })
  return o
end
local SUPER = {
  Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiObject", TextBox = "GuiObject",
  ScrollingFrame = "GuiObject", SurfaceGui = "GuiObject", BillboardGui = "GuiObject",
  ScreenGui = "LayerCollector", LayerCollector = "Instance",
  UICorner = "Instance", UIStroke = "Instance", UIGradient = "Instance",
  UIGridLayout = "Instance", UIListLayout = "Instance", UIPadding = "Instance",
  Folder = "Instance", StringValue = "Instance",
}
local function isA(cls, c)
  local x = cls
  while x do
    if x == c then return true end
    x = SUPER[x]
  end
  return false
end
_METHODS = {
  GetChildren = function(self)
    local out = {}
    for i = 1, #rawget(self, "__children") do out[i] = rawget(self, "__children")[i] end
    return out
  end,
  GetDescendants = function(self)
    local out, st = {}, { self }
    while #st > 0 do
      local x = table.remove(st)
      for i = 1, #rawget(x, "__children") do
        out[#out + 1] = rawget(x, "__children")[i]
        table.insert(st, rawget(x, "__children")[i])
      end
    end
    return out
  end,
  FindFirstChild = function(self, n)
    for _, ch in ipairs(rawget(self, "__children")) do
      if rawget(ch, "__props").Name == n then return ch end
    end
  end,
  Destroy = function(self)
    local p = rawget(self, "__props").Parent
    if p then
      local kids = rawget(p, "__children")
      for i = #kids, 1, -1 do if kids[i] == self then table.remove(kids, i) break end end
    end
    rawset(self, "__children", {})
  end,
  IsA = function(self, c) return isA(rawget(self, "__props").ClassName, c) end,
}
Instance = { new = function(c) return mk(c) end }
Color3 = { new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0, __t = "Color3" } end }
UDim2 = { new = function(a, b, c, d) return { X = { Scale = a or 0, Offset = b or 0 }, Y = { Scale = c or 0, Offset = d or 0 }, __t = "UDim2" } end }
UDim = { new = function(a, b) return { Scale = a or 0, Offset = b or 0, __t = "UDim" } end }
Vector2 = { new = function(x, y) return { X = x or 0, Y = y or 0, __t = "Vector2" } end }
Vector3 = { new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0, __t = "Vector3" } end }
ColorSequenceKeypoint = { new = function(c, t) return { Value = c, Time = t or 0 } end }
ColorSequence = { new = function(a, b) return { Keypoints = { a, b }, __t = "ColorSequence" } end }
-- Enum com valores inteiros sequenciais (para EL[value] da UI do V2)
local function mkEnum(names)
  local e = {}
  local arr = {}
  for i, n in ipairs(names) do
    local entry = { Name = n, Value = i - 1, __enum = true }
    arr[i] = entry
    e[n] = entry
  end
  e.GetEnums = function(self)
    local out = {}
    for i = 1, #arr do out[i] = arr[i] end
    return out
  end
  return e
end
Enum = {}
local ENUM_NAMES = {
  Font = { "Gotham", "GothamMedium", "GothamBold", "Arial", "ArialBold", "Code", "Cartoon", "SciFi",
    "HighlandOBlique", "Fantasy", "Bangers", "Arcade", "Builder", "Slavic", "Modern", "Legacy",
    "GothamBlack", "SourceSans", "SourceSansBold", "Roboto", "RobotoMono", "CenturyGothic",
    "CenturyGothicBold", "Osaka", "OsakaBold", "Michroma", "Futura", "SofiaPro", "SofiaProBold",
    "SofiaProItalic", "AdventPro", "AdventProBold", "AdventProItalic", "AdventProBoldItalic",
    "BuilderSans", "BuilderSansBold", "BuilderSansBook", "CodePlatform", "RedDisplay", "Rajdhani",
    "NunitoSans", "NunitoSansBold", "NotoSans", "NotoSansBold", "QuartzRegular", "QuartzMedium",
    "QuartzBold", "QuartzBlack", "QuartzRegularItalic", "QuartzMediumItalic", "QuartzBoldItalic",
    "QuartzBlackItalic" },
  TextXAlignment = { "Left", "Center", "Right" },
  TextYAlignment = { "Top", "Center", "Bottom" },
  ZIndexBehavior = { "Sibling", "Global" },
  TextTruncate = { "None", "AtEnd", "AtCenter" },
  ApplyStrokeMode = { "Inset", "Border", "Outset" },
}
for _, k in ipairs({ "Font", "TextXAlignment", "TextYAlignment", "ZIndexBehavior", "TextTruncate", "ApplyStrokeMode" }) do
  Enum[k] = mkEnum(ENUM_NAMES[k])
end
local services = {}
game = {
  GetService = function(self, n)
    if not services[n] then
      services[n] = mk(n)
      rawget(services[n], "__props").Name = n
    end
    return services[n]
  end,
}
logs = {}
print = function(...) table.insert(logs, table.concat({...}, " ")) end
"""

DUMP = r"""
local function dumpInst(inst, out)
  local i = #out + 1
  out[i] = { cls = rawget(inst, "__props").ClassName, nm = rawget(inst, "__props").Name, p = 0, props = {} }
  for _, ch in ipairs(rawget(inst, "__children")) do
    local before = #out + 1
    dumpInst(ch, out)
    out[before].p = i
  end
  for k, v in pairs(rawget(inst, "__props")) do
    if k ~= "Name" and k ~= "ClassName" and k ~= "Parent" then
      local t = type(v)
      if t == "boolean" or t == "number" or t == "string" then
        out[i].props[k] = v
      elseif t == "table" then
        local tag = rawget(v, "__t")
        if tag == "Color3" then out[i].props[k] = { __t = "Color3", v = { v.R, v.G, v.B } }
        elseif tag == "Vector3" then out[i].props[k] = { __t = "Vector3", v = { v.X, v.Y, v.Z } }
        elseif tag == "UDim2" then out[i].props[k] = { __t = "UDim2", v = { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } }
        elseif tag == "UDim" then out[i].props[k] = { __t = "UDim", v = { v.Scale, v.Offset } }
        elseif tag == "Vector2" then out[i].props[k] = { __t = "Vector2", v = { v.X, v.Y } }
        elseif tag == "ColorSequence" then
          local kp = {}
          for _, p in ipairs(v.Keypoints or {}) do
            local c = p.Value
            table.insert(kp, { { c.R or 0, c.G or 0, c.B or 0 }, p.Time or 0 })
          end
          out[i].props[k] = { __t = "ColorSequence", v = kp }
        elseif rawget(v, "__enum") then
          out[i].props[k] = { __t = "Enum", v = v.Value }
        end
      end
    end
  end
end
local SG = game:GetService("StarterGui")
local result, order = {}, {}
for _, ch in ipairs(rawget(SG, "__children")) do
  local inst = {}
  dumpInst(ch, inst)
  result[rawget(ch, "__props").Name] = inst
  order[#order + 1] = rawget(ch, "__props").Name
end
_G.__dump = { guis = result, order = order }
"""


def main():
    L = lupa.LuaRuntime()
    L.execute(STUB)
    with open(CB, encoding="utf-8") as f:
        L.execute(f.read())
    L.execute(DUMP)
    d = L.globals()["__dump"]
    order = d["order"]
    n = len(order)
    got = {}
    for i in range(1, n + 1):
        k = order[i]
        arr = d["guis"][k]
        rows = []
        for j in range(1, len(arr) + 1):
            it = arr[j]
            props = {}
            pl = it["props"]
            for kk in pl:
                props[str(kk)] = pyv(pl[kk])
            rows.append({"c": it["cls"], "n": it["nm"], "p": it["p"], "props": props})
        got[k] = rows

    logs = list(L.globals()["logs"])
    for line in logs:
        print(line)

    errs = 0

    def err(msg):
        nonlocal errs
        errs += 1
        if errs <= 20:
            print("ERRO:", msg)

    exp_names = set(expected_guis)
    got_names = set(got)
    for g in sorted(exp_names - got_names):
        err(f"gui faltando: {g}")
    for g in sorted(got_names - exp_names):
        err(f"gui inesperado: {g}")

    for g in sorted(exp_names & got_names):
        v3 = g in v3_guis
        src = (V3 if v3 else V2)
        e_insts = src["guis"][g]
        e_cls = src["classes"]
        e_nm = src["names"]
        g_insts = got[g]
        if len(e_insts) != len(g_insts):
            err(f"{g}: {len(g_insts)} instancias != {len(e_insts)} esperadas")
            continue
        for i, (e, w) in enumerate(zip(e_insts, g_insts), 1):
            ec, en = e_cls[e["c"] - 1], e_nm[e["n"] - 1]
            if ec != w["c"]:
                err(f"{g}#{i}: classe {w['c']!r} != {ec!r}")
            if str(en) != str(w["n"]):
                err(f"{g}#{i}: nome {w['n']!r} != {str(en)!r}")
            if e["p"] != w["p"]:
                err(f"{g}#{i}: parent {w['p']} != {e['p']}")
            # props esperadas (com regras de skip + BSP post-pass)
            eprops = {}
            for k, v in e["props"]:
                if k == "_tool":
                    continue
                if v3 and k == "BorderSizePixel":
                    continue
                if _skipped(k, v):
                    continue
                v = unwrap(v)
                if isinstance(v, dict) and v.get("__t") == "Enum":
                    eprops[k] = _enum_int(k, v)
                else:
                    eprops[k] = v
            if v3 and _is_guiobject(ec):
                eprops["BorderSizePixel"] = 0
            wprops = {}
            for k, v in w["props"].items():
                if isinstance(v, dict) and v.get("__t") == "Enum":
                    wprops[k] = v["v"]
                else:
                    wprops[k] = v
            missing = set(eprops) - set(wprops)
            extra = set(wprops) - set(eprops)
            for k in missing:
                err(f"{g}#{i} {ec}.{en}: prop faltando {k} = {eprops[k]!r}")
            for k in extra:
                err(f"{g}#{i} {ec}.{en}: prop extra {k} = {wprops[k]!r}")
            for k in set(eprops) & set(wprops):
                ev, wv = eprops[k], wprops[k]
                if not _eq(ev, wv):
                    err(f"{g}#{i} {ec}.{en}: {k} = {wv!r} != {ev!r}")
    total_e = sum(len(v) for v in expected_guis.values())
    total_w = sum(len(v) for v in got.values())
    print(f"\nvalidacao: {len(exp_names & got_names)}/{len(exp_names)} guis, {total_w}/{total_e} instancias, {errs} erros")
    if errs:
        sys.exit(1)
    print("TUDO OK — CB_UI_TODAS_UIS.lua fiel aos builds das UIs")


SKIP_TRUE = ("Visible", "Active", "RichText", "TextWrapped", "TextScaled",
             "AutoButtonColor", "ClearTextOnFocus", "ResetOnSpawn", "Archivable", "ClipsDescendants")
SKIP_FALSE = ("Modal", "IgnoreGuiInset")
SKIP_ZERO = ("BackgroundTransparency", "ZIndex", "LayoutOrder", "Rotation", "Transparency")
SKIP_ENUMS = ("Enum.TextXAlignment.Left", "Enum.TextYAlignment.Top",
              "Enum.TextTruncate.None", "Enum.ApplyStrokeMode.Border",
              "Enum.ZIndexBehavior.Sibling")

# mesmo mapa de nomes do stub (para converter enum por nome -> valor int)
ENUM_NAMES = {
    "Font": ["Gotham", "GothamMedium", "GothamBold", "Arial", "ArialBold", "Code", "Cartoon", "SciFi",
             "HighlandOBlique", "Fantasy", "Bangers", "Arcade", "Builder", "Slavic", "Modern", "Legacy",
             "GothamBlack", "SourceSans", "SourceSansBold", "Roboto", "RobotoMono", "CenturyGothic",
             "CenturyGothicBold", "Osaka", "OsakaBold", "Michroma", "Futura", "SofiaPro", "SofiaProBold",
             "SofiaProItalic", "AdventPro", "AdventProBold", "AdventProItalic", "AdventProBoldItalic",
             "BuilderSans", "BuilderSansBold", "BuilderSansBook", "CodePlatform", "RedDisplay", "Rajdhani",
             "NunitoSans", "NunitoSansBold", "NotoSans", "NotoSansBold", "QuartzRegular", "QuartzMedium",
             "QuartzBold", "QuartzBlack", "QuartzRegularItalic", "QuartzMediumItalic", "QuartzBoldItalic",
             "QuartzBlackItalic"],
    "TextXAlignment": ["Left", "Center", "Right"],
    "TextYAlignment": ["Top", "Center", "Bottom"],
    "ZIndexBehavior": ["Sibling", "Global"],
    "TextTruncate": ["None", "AtEnd", "AtCenter"],
    "ApplyStrokeMode": ["Inset", "Border", "Outset"],
}


def _enum_int(prop, v):
    """enum esperado -> valor int (mesmo do stub)"""
    if not isinstance(v, dict) or v.get("__t") != "Enum":
        return v
    val = v["v"]
    if isinstance(val, int):
        return val
    s = str(val)
    if s.startswith("Enum."):
        tail = s[len("Enum."):]
        if tail.isdigit():
            return int(tail)
        # "Enum.Font.BuilderSans" -> prop "Font", nome "BuilderSans"
        parts = tail.split(".")
        base = parts[0]
        nm = parts[-1]
        arr = ENUM_NAMES.get(base) or ENUM_NAMES.get(prop) or []
        if nm in arr:
            return arr.index(nm)
        # TextTruncate etc: nao esta no stub; usar -1 como sentinel (presenca)
        return -1
    return -1


def pyv(v):
    tn = type(v).__name__
    if tn in ("_LuaTable", "LuaTable"):
        keys = []
        for k in v:
            keys.append(k)
        if not keys:
            return []
        isarr = all(type(k) is int for k in keys) and sorted(keys) == list(range(1, len(keys) + 1))
        if isarr:
            return [pyv(v[k]) for k in range(1, len(keys) + 1)]
        out = {}
        for k in keys:
            out[str(k)] = pyv(v[k])
        return out
    if isinstance(v, (list, tuple)):
        return [pyv(x) for x in v]
    if isinstance(v, dict):
        return {k: pyv(x) for k, x in v.items()}
    return v


def unwrap(v):
    if isinstance(v, dict) and v.get("__t") in ("Int32", "Float32", "Number", "Integer"):
        return v["v"]
    return v


GUIOBJECT_SUB = {"Frame", "TextLabel", "TextButton", "TextBox", "ScrollingFrame",
                 "SurfaceGui", "BillboardGui", "GuiObject"}


def _is_guiobject(cls):
    return cls in GUIOBJECT_SUB


def _skipped(k, v):
    v = unwrap(v)
    if isinstance(v, dict):
        if v.get("__t") == "UDim2" and v["v"] == [0, 0, 0, 0]:
            return True
        if v.get("__t") == "Enum" and v["v"] in SKIP_ENUMS:
            return True
        return False
    if k == "Text" and v == "":
        return True
    if isinstance(v, bool):
        return (v is True and k in SKIP_TRUE) or (v is False and k in SKIP_FALSE)
    if v == 0 and k in SKIP_ZERO:
        return True
    return False


def _eq(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        if a.get("__t") != b.get("__t"):
            return False
        return _eq(a.get("v"), b.get("v"))
    if isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)):
        if len(a) != len(b):
            return False
        return all(_eq(x, y) for x, y in zip(a, b))
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return float(a) == float(b)
    return a == b


if __name__ == "__main__":
    main()
