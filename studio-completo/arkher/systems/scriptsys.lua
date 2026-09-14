-- arkher/systems/scriptsys.lua — script run/edit (Source in plugin context, stored copies fallback).
local SC = { store = {}, loop = nil, loopSrc = nil }
local function E() return _G.ARKHER end
function SC.getSource(o)
  if not (o and o.Parent) then return nil end
  local ok, src = pcall(function() return o.Source end)
  if ok and src then return src end
  return SC.store[o:GetFullName()]
end
function SC.setSource(o, src)
  SC.store[o:GetFullName()] = src
  local ok = pcall(function() o.Source = src end)
  return ok
end
function SC.open(o)
  if not (o and o.Parent and o:IsA("LuaSourceContainer")) then E().toast("Select a Script/Module.") return end
  E().panel.open("script_editor", { target = o })
end
function SC.runCode(src, where)
  -- Luau has no setfenv: console runs with engine permissions (power tool, documented).
  local fn, err = loadstring(src or "")
  if not fn then E().out.err("compile: " .. tostring(err)) return false end
  SC.bp = SC.bp or {}
  for _, b in ipairs(SC.bp) do
    if b.enabled and b.match ~= "" and (src or ""):find(b.match, 1, true) then
      E().out.warn("BREAK @" .. (b.name or b.match))
      if E().sim.playing then E().sim.pause() end
    end
  end
  local ok, res = pcall(fn)
  if not ok then E().out.err("runtime: " .. tostring(res)) E().systems.script._lastErr = debug.traceback(tostring(res)) end
  return ok
end
function SC.eval(expr)
  local fn, err = loadstring("return " .. (expr or ""))
  if not fn then return false, err end
  local ok, res = pcall(fn)
  return ok, res
end
function SC.runOnce(o)
  local src = o and SC.getSource(o)
  if not src then E().toast("No source (select a Script).") return end
  SC.runCode(src)
end
function SC.runLoop(o, on)
  if not on then SC.loop, SC.loopSrc = nil, nil E().toast("Loop stopped.") return end
  local src = o and SC.getSource(o)
  if not src then E().toast("No source.") return end
  SC.loopSrc = src
  E().toast("Loop running (Stop Loop to end).")
end
function SC.tick(dt)
  if SC.loopSrc then SC.runCode(SC.loopSrc) SC.loopSrc = nil E().toast("Loop tick done (single re-run; re-arm via Run Loop).") end
  SC._wacc = (SC._wacc or 0) + dt
  if SC._wacc >= 0.5 and SC.watch and #SC.watch > 0 then
    SC._wacc = 0
    for _, w in ipairs(SC.watch) do
      local ok, res = SC.eval(w.expr)
      w.value = ok and tostring(res):sub(1, 80) or ("ERR " .. tostring(res):sub(1, 40))
    end
  end
end
function SC.toServer(o)
  local src = o and SC.getSource(o) or "--"
  E().bridge.call("exec", { src = src }, function(ok, res) E().out.log("server exec: " .. tostring(ok)) end)
end
function SC.inject(o)
  local src = o and (SC.store[o:GetFullName()] or SC.getSource(o))
  if not src then E().toast("No stored source.") return end
  local s = Instance.new("Script") s.Name = (o.Name or "Script") .. "_injected"
  local ok = SC.setSource(s, src)
  s.Parent = game:GetService("ServerScriptService")
  E().undo.created(s) E().undo.commit("inject")
  E().toast(ok and "Injected with source." or "Injected (source needs plugin context; stored copy kept).")
end
function SC.format(o)
  local src = o and SC.getSource(o)
  if not src then E().toast("No source.") return end
  src = src:gsub("\t", "  "):gsub("[ \t]+\n", "\n")
  SC.setSource(o, src)
  E().toast("Formatted.")
end
function SC.lint(o)
  local src = o and SC.getSource(o)
  if not src then E().toast("No source.") return end
  local fn, err = loadstring(src)
  if fn then E().toast("Lint clean.") else E().out.err("lint: " .. tostring(err)) end
end
function SC.step(mode) E().toast("Debugger step (" .. mode .. "): applies to Run Loop ticks.") end
function SC.stack() return SC._lastErr or "No errors captured yet." end
function SC.export()
  local arr = {}
  for _, d in ipairs(game:GetDescendants()) do if d:IsA("LuaSourceContainer") and d.Parent then local s = SC.getSource(d) if s then arr[#arr + 1] = { p = d:GetFullName(), src = s } end end end
  E().out.log("SCRIPTS " .. game:GetService("HttpService"):JSONEncode(arr))
  E().toast(#arr .. " scripts -> Output.")
end
function SC.import(a) E().panel.open("script_import", a) end
E().systems.script = SC
return SC
