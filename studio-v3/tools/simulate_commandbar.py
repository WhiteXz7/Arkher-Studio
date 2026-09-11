#!/usr/bin/env python3
"""Simula a execucao dos 13 scripts de Command Bar num stub do Roblox (lupa)
e valida a arvore resultante: classes, nomes, parents, Disabled e checksum
de Source (o mesmo algoritmo usado no stub, calculado aqui em Python)."""
import glob
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DIST = os.path.dirname(HERE)
CB_DIR = os.path.join(DIST, "commandbar", "estrutura-completa")

SVCS = ["Workspace", "Lighting", "Players", "ReplicatedStorage",
        "ReplicatedFirst", "SoundService", "CSGDictionaryService",
        "NonReplicatedCSGDictionaryService", "Chat", "TimerService",
        "TweenService", "StarterPlayer", "StarterPack", "StarterGui",
        "LocalizationService", "TeleportService", "CollectionService",
        "PhysicsService", "Geometry", "InsertService", "GamePassService",
        "Debris", "CookiesService", "VRService", "ContextActionService",
        "ScriptService", "AssetService", "TouchInputService",
        "ServerScriptService", "ServerStorage", "LuaWebService",
        "HttpService", "AnalyticsService", "VirtualInputManager",
        "TestService", "Teams", "StudioData"]

STUB = r"""
local function mk(cls)
  local o = setmetatable({ClassName = cls, Name = "", Parent = nil,
                          Source = "", Disabled = false}, {
    __index = {
      FindFirstChild = function(self, n)
        for _, c in ipairs(self._kids or {}) do
          if c.Name == n then return c end
        end
        return nil
      end,
      WaitForChild = function(self, n)
        local c = self:FindFirstChild(n)
        if not c then error("WaitForChild falhou: " .. n, 2) end
        return c
      end,
    },
    __newindex = function(t, k, v)
      if k == "Parent" then
        if v then table.insert(v._kids, t) end
      end
      rawset(t, k, v)
    end,
  })
  o._kids = {}
  return o
end
Instance = {new = function(c) return mk(c) end}
services = {}
local function svc(n)
  local s = mk(n)
  s.Name = n
  services[n] = s
  return s
end
for _, n in ipairs(__SVCS) do svc(n) end
local root = mk("DataModel")
for _, n in ipairs(__SVCS) do services[n].Parent = root end
_G.__root = root
local spps = mk("StarterPlayerScripts")
spps.Name = "StarterPlayerScripts"
spps.Parent = services["StarterPlayer"]
game = {
  GetService = function(self, n)
    local s = services[n]
    if not s then error("servico inexistente: " .. n, 2) end
    return s
  end,
  WaitForChild = function(self, n) return services[n] end,
}
print = function(...) end  -- silencia
warn = function(...) end
function h(s)
  local n = 0
  for i = 1, #s do n = (n * 31 + s:byte(i)) % 1000000007 end
  return n
end
function dump(root, prefix, out)
  for _, c in ipairs(root._kids or {}) do
    out[#out + 1] = (prefix or "") .. c.ClassName .. ":" .. c.Name
      .. (c.Disabled and " D" or "") .. " len=" .. #tostring(c.Source)
      .. " h=" .. h(tostring(c.Source))
    dump(c, (prefix or "") .. "  ", out)
  end
end
"""


def h_py(s: str) -> int:
    n = 0
    for b in s.encode("utf-8"):
        n = (n * 31 + b) % 1000000007
    return n


def main() -> int:
    import lupa
    L = lupa.LuaRuntime()
    svcs_lua = "{" + ",".join(f'"{n}"' for n in SVCS) + "}"
    L.execute(f"__SVCS = {svcs_lua}\n" + STUB)

    scripts = sorted(glob.glob(os.path.join(CB_DIR, "CB*.lua")))
    assert len(scripts) == 13, len(scripts)
    for p in scripts:
        src = open(p, encoding="utf-8").read()
        try:
            L.execute(f"__log_i = 0; (function() {src} end)()")
        except Exception as e:
            print(f"ERRO em {os.path.basename(p)}: {e}")
            return 1
        print(f"  {os.path.basename(p):10s} executou sem erro")

    # dump da arvore
    L.execute(r"local o = {} dump(__root, '', o) _G.__tree = table.concat(o, '\n')")
    tree = L.globals()["__tree"]
    lines = [l for l in tree.split("\n") if l.strip()]
    print(f"\n== arvore criada (instancias nao-service) ==")
    keep = ("Arkher", "ALL", "Panels", "ArkherV3", "ArkherData", "StarterPlayerScripts")
    for l in lines:
        if any(k in l for k in keep):
            print(" " + l)

    # navegar via Lua
    L.execute("""
_G.__get = function(path)
  local cur = __root
  for part in string.gmatch(path, "[^/]+") do
    local c = cur:FindFirstChild(part)
    if not c then return nil end
    cur = c
  end
  return cur
end
""")
    gget = L.globals()["__get"]

    S = {os.path.basename(f): open(f, encoding="utf-8").read()
         for f in glob.glob(os.path.join(DIST, "commandbar", "*.lua"))}
    ALL = S["ArkherStudio_ALL.lua"]
    # reconstruir parts (mesma logica do gerador)
    ln = ALL.split("\n")
    szs = [len(x) + 1 for x in ln]
    tot = sum(szs)
    t1, t2 = tot // 3, 2 * tot // 3
    acc = c1 = c2 = 0
    for i, sz in enumerate(szs):
        if c1 == 0 and acc + sz > t1:
            c1 = i
        if c2 == 0 and c1 and acc + sz > t2:
            c2 = i
        acc += sz
    P1 = ALL[:sum(szs[:c1])]
    P2 = ALL[sum(szs[:c1]):sum(szs[:c2])]
    P3 = ALL[sum(szs[:c2]):]
    M = [f"return[====[{p}]====]\n" for p in (P1, P2, P3)]

    ASM = open(os.path.join(HERE, "make_estrutura_completa.py"),
               encoding="utf-8").read()
    import re
    ns = {}
    exec(compile(re.search(r"ASSEMBLE_SRC = '''.*?'''", ASM, re.S).group(0),
                 "<asm>", "exec"), ns)
    ASM_SRC = ns["ASSEMBLE_SRC"]

    PANELS = ["UI_AI", "UI_About", "UI_Animator", "UI_Audio", "UI_Camera",
              "UI_City", "UI_Cloud", "UI_CommandPalette", "UI_Console",
              "UI_Lighting", "UI_Map", "UI_Modeler", "UI_NPCs", "UI_Open",
              "UI_Particles", "UI_Performance", "UI_Physics", "UI_Publish",
              "UI_SaveExport", "UI_SaveOpen", "UI_Script", "UI_Settings",
              "UI_Terrain", "UI_UIDesigner"]

    expected = {
        # caminho: (fonte, disabled)
        "ReplicatedStorage/ArkherV3/ArkherKit_A": (S["ArkherKit_A.lua"], False),
        "ReplicatedStorage/ArkherV3/ArkherKit_B": (S["ArkherKit_B.lua"], False),
        "ReplicatedStorage/ArkherV3/ALL/ALL_P1": (M[0], False),
        "ReplicatedStorage/ArkherV3/ALL/ALL_P2": (M[1], False),
        "ReplicatedStorage/ArkherV3/ALL/ALL_P3": (M[2], False),
        "StarterPlayer/StarterPlayerScripts/Arkher/ArkherMainUI":
            (S["ArkherStudio_MainUI.lua"], False),
        "StarterPlayer/StarterPlayerScripts/Arkher/ArkherBundle_Editors":
            (S["UI_Bundle_Editors.lua"], False),
        "StarterPlayer/StarterPlayerScripts/Arkher/ArkherBundle_Scene":
            (S["UI_Bundle_Scene.lua"], False),
        "StarterPlayer/StarterPlayerScripts/Arkher/ArkherBundle_System":
            (S["UI_Bundle_System.lua"], False),
        "StarterPlayer/StarterPlayerScripts/Arkher/ArkherALL_Assemble":
            (ASM_SRC, True),
        "ServerScriptService/Arkher/ArkherKit_Installer_A":
            (S["ArkherKit_Installer_A.lua"], True),
        "ServerScriptService/Arkher/ArkherKit_Installer_B":
            (S["ArkherKit_Installer_B.lua"], True),
    }
    for p in PANELS:
        expected[f"StarterPlayer/StarterPlayerScripts/Arkher/Panels/{p}"] = \
            (S[f"{p}.lua"], True)

    fails = 0
    for path, (exp_src, exp_dis) in expected.items():
        inst = gget(path)
        if inst is None:
            print(f"  FALHA: {path} nao existe")
            fails += 1
            continue
        got_src = inst.Source
        if got_src is None or got_src == "":
            got_src = ""
        if got_src != exp_src:
            k = next((n for n, (a, b) in enumerate(zip(got_src, exp_src))
                      if a != b), min(len(got_src), len(exp_src)))
            print(f"  FALHA source {path}: diverge em {k} "
                  f"(got {len(got_src)} vs exp {len(exp_src)})")
            fails += 1
        if bool(inst.Disabled) != exp_dis:
            print(f"  FALHA disabled {path}: {inst.Disabled} != {exp_dis}")
            fails += 1

    # ArkherData (pasta vazia)
    ad = gget("ServerStorage/ArkherData")
    if ad is None or ad.ClassName != "Folder":
        print("  FALHA: ServerStorage.ArkherData nao existe")
        fails += 1

    print(f"\nRESULTADO: {len(expected) + 1} verificacoes, {fails} falhas")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
