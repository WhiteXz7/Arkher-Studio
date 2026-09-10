"""Smoke test dos 6 scripts V3 em stub Lua (lupa).
Uso: python3 tools/smoke_test_v3.py
"""
import sys, re
sys.path.insert(0, "tools")
import lupa

src = open("tools/build_completo.py", encoding="utf-8").read()

def get(var):
    m = re.search(var + r" = '''\\\n(.*?)'''\n", src, re.S)
    assert m, var
    return m.group(1)

S0, S1, C0, TOOL, N0, T0 = (get(v) for v in
    ("S0_FIRST", "S1_BOOT", "C0_CHAR", "TOOL_UI", "N0_LEGACY", "T0_SELFTEST"))

STUB = r"""
mk = function(cls)
  local methods = {
    FindFirstChild = function(self, n)
      for i = 1, #self._kids do if self._kids[i].Name == n then return self._kids[i] end end
    end,
    WaitForChild = function(self, n, t) return self:FindFirstChild(n) end,
    GetChildren = function(self) return self._kids end,
    Destroy = function(self) end,
    Connect = function(self, f) end,
    GetState = function(self) return "Walking" end,
    GetPlayers = function(self) return {} end,
    IsA = function(self, k) return false end,
  }
  local o = setmetatable({ClassName=cls, Name="", Parent=nil, _kids={}}, {
    __index = function(t, k)
      local m = methods[k]
      if m then return m end
      if rawget(t, k) ~= nil then return rawget(t, k) end
      local f = mk("Field")
      rawset(t, k, f)
      return f
    end,
    __newindex = function(t, k, v)
      if k == "Parent" then
        if v then v._kids[#v._kids + 1] = t end
      end
      rawset(t, k, v)
    end,
  })
  return o
end
Instance = {new = function(c, p) local o = mk(c); if p then o.Parent = p end; return o end}
Color3 = {new = function(r, g, b) return {r, g, b} end}
services = {}
game = {
  GetService = function(self, n)
    if not services[n] then
      local s = mk(n); s.Name = n
      services[n] = s
    end
    return services[n]
  end,
}
local RS = game:GetService("ReplicatedStorage")
local ark = Instance.new("Folder", RS); ark.Name = "ArkherV3"
local kitA = Instance.new("ModuleScript", ark); kitA.Name = "ArkherKit_A"
local kitB = Instance.new("ModuleScript", ark); kitB.Name = "ArkherKit_B"
local allf = Instance.new("Folder", ark); allf.Name = "ALL"
Instance.new("ModuleScript", allf).Name = "ALL_P1"
Instance.new("ModuleScript", allf).Name = "ALL_P2"
Instance.new("ModuleScript", allf).Name = "ALL_P3"
local remotes = Instance.new("Folder", ark); remotes.Name = "Remotes"
local SSS = game:GetService("ServerScriptService")
Instance.new("Folder", SSS).Name = "Arkher"
local SS = game:GetService("ServerStorage")
Instance.new("Folder", SS).Name = "ArkherData"
local cloud = Instance.new("Folder", SS); cloud.Name = "ArkherCloud"
Instance.new("Folder", cloud).Name = "Published"
local SG = game:GetService("StarterGui")
Instance.new("ScreenGui", SG).Name = "ARKHER_Studio"
local SP = game:GetService("StarterPlayer")
local sps = Instance.new("Folder", SP); sps.Name = "StarterPlayerScripts"
Instance.new("LocalScript", sps).Name = "ARKHER_HUD"
local scs = Instance.new("Folder", SP); scs.Name = "StarterCharacterScripts"
Instance.new("LocalScript", scs).Name = "Arkher_C0_Character"
logs = {}
print = function(...) table.insert(logs, table.concat({...}, " ")) end
"""

HARNESS = r"""
script = {Parent = nil}
__S0__
script = {Parent = nil}
__S1__
do
  local char = mk("Model")
  local hum = mk("Humanoid"); hum.Name = "Humanoid"; char._kids[#char._kids+1] = hum
  local root = mk("Part"); root.Name = "HumanoidRootPart"; char._kids[#char._kids+1] = root
  script = {Parent = char}
  __C0__
end
do
  local t = mk("Tool"); t.Activated = mk("BB")
  script = {Parent = t}
  __TOOL__
end
script = {Parent = nil}
__N0__
script = {Parent = nil}
__T0__
"""

harness = (HARNESS.replace("__S0__", S0).replace("__S1__", S1)
           .replace("__C0__", C0).replace("__TOOL__", TOOL)
           .replace("__N0__", N0).replace("__T0__", T0))

L = lupa.LuaRuntime()
L.execute(STUB)
L.execute(harness)
t = L.globals()["logs"]
logs = [t[i] for i in range(1, len(t) + 1)]
for line in logs:
    print(line)
checks = {
    "S0": any("S0 First (ReplicatedFirst)" in x for x in logs),
    "S1": any("S1 Boot (ServerScriptService)" in x for x in logs),
    "C0": any("C0 Character" in x for x in logs),
    "N0": any("N0 Legacy" in x for x in logs),
    "T0": any("ESTRUTURA COMPLETA" in x for x in logs),
}
print("\nsmoke test:", checks)
assert all(checks.values()), "HÁ FALHAS"
print("TUDO OK")
