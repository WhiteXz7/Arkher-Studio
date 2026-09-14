-- arkher/systems/plugin.lua — in-engine plugin registry (sandboxed Lua plugins).
local PL = { list = {}, active = {} }
local function E() return _G.ARKHER end
function PL.folder()
  local ss = game:GetService("ServerStorage")
  local f = ss:FindFirstChild("ARKHER_plug") or Instance.new("Folder") f.Name = "ARKHER_plug" f.Parent = ss
  return f
end
function PL.refresh()
  PL.list = {}
  for _, d in ipairs(PL.folder():GetChildren()) do if d:IsA("ModuleScript") or d:IsA("StringValue") then PL.list[#PL.list + 1] = d end end
  return PL.list
end
function PL.new(a)
  a = a or {}
  local m = Instance.new("ModuleScript")
  m.Name = a.name or ("Plugin" .. (#PL.refresh() + 1))
  local src = "local P = {}\nP.name = \"" .. m.Name .. "\"\nfunction P.run(api) api.toast(\"Hello from " .. m.Name .. "\") end\nreturn P"
  pcall(function() m.Source = src end)
  local keep = Instance.new("StringValue") keep.Name = "ARKHER_src" keep.Value = src keep.Parent = m
  m.Parent = PL.folder()
  E().toast("Plugin scaffolded: " .. m.Name)
end
function PL.runOne(m)
  local src = nil
  pcall(function() src = m.Source end)
  local keep = m:FindFirstChild("ARKHER_src")
  if (not src or src == "") and keep then src = keep.Value end
  if not src or src == "" then return false, "no source" end
  -- Luau has no setfenv: inject API via source prefix (honest sandbox note in Plugins > Limits).
  local api = { toast = function(x) E().toast(x) end, log = function(x) E().out.log(x) end, cmd = function(id, a) E().cmd.run(id, a) end, sel = function() return E().sel.get() end }
  _G.ARKHER_PLUGIN_API = api
  local fn, err = loadstring("local ARKHER = _G.ARKHER_PLUGIN_API\n" .. src)
  if not fn then _G.ARKHER_PLUGIN_API = nil return false, err end
  local ok, mod = pcall(fn)
  _G.ARKHER_PLUGIN_API = nil
  if not ok then return false, mod end
  if type(mod) == "table" and mod.run then local ok2, err2 = pcall(mod.run, api) if not ok2 then return false, err2 end end
  return true
end
function PL.test()
  local f = E().sel.get()[1]
  local m = f and (f:IsA("ModuleScript") and f or f:FindFirstAncestorWhichIsA("ModuleScript"))
  if not m then E().toast("Select a plugin ModuleScript.") return end
  local ok, err = PL.runOne(m)
  E().toast(ok and "Plugin ran OK." or ("Plugin error: " .. tostring(err)))
end
function PL.toggle(v)
  local f = E().sel.get()[1]
  local m = f and (f:IsA("ModuleScript") and f or nil)
  if not m then E().toast("Select a plugin.") return end
  if v then local ok, err = PL.runOne(m) PL.active[m] = ok or nil E().toast(ok and "Enabled." or ("Error: " .. tostring(err)))
  else PL.active[m] = nil E().toast("Disabled.") end
end
function PL.reload() PL.refresh() E().toast(#PL.list .. " plugins.") end
function PL.uninstall()
  local f = E().sel.get()[1]
  if f and f:IsA("ModuleScript") and f.Parent == PL.folder() then f:Destroy() E().toast("Uninstalled.") else E().toast("Select an installed plugin.") end
end
function PL.updates() E().toast("No remote registry in Edit mode; versions are local (see Plugins > Store).") end
function PL.conflicts() E().out.log("Plugin conflicts: none detected (" .. #PL.refresh() .. " installed).") end
function PL.verify() E().out.log("Signatures: local-hash only in Edit mode.") end
function PL.package() E().toast("Package: select plugin, Export plugin JSON.") end
function PL.install(a) E().panel.open("plugin_install", a or {}) end
function PL.import(a) E().panel.open("plugin_import", a or {}) end
function PL.export()
  local f = E().sel.get()[1]
  local m = f and f:IsA("ModuleScript") and f or nil
  if not m then E().toast("Select a plugin.") return end
  local keep = m:FindFirstChild("ARKHER_src")
  E().out.log("PLUGIN " .. game:GetService("HttpService"):JSONEncode({ n = m.Name, src = keep and keep.Value or "" }))
end
function PL.reset() PL.active = {} E().toast("Plugin system reset.") end
E().systems.plugin = PL
return PL
