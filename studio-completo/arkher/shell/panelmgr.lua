-- arkher/shell/panelmgr.lua — window manager for tool panels + shell panels.
local PM = { openWins = {}, builders = {}, dock = {} }
function PM.reg(name, fn) PM.builders[name] = fn end
function PM.open(name, props)
  if PM.openWins[name] then PM.focus(name) return PM.openWins[name] end
  local b = PM.builders[name]
  if not b then
    -- honest fallback: generic inspector bound to command metadata (never a dead button)
    b = PM.builders.__generic
  end
  local win = _G.ARKHER.shell.window(name, props)
  local ok, err = pcall(b, win, props or {})
  if not ok then _G.ARKHER.out.err("panel " .. name .. ": " .. tostring(err)) end
  PM.openWins[name] = win
  return win
end
function PM.close(name) local w = PM.openWins[name] if w then _G.ARKHER.shell.closeWindow(w) PM.openWins[name] = nil end end
function PM.toggle(name)
  if PM.openWins[name] then PM.close(name)
  elseif _G.ARKHER.shell.toggleDock then _G.ARKHER.shell.toggleDock(name)
  else PM.open(name) end
end
function PM.focus(name) local w = PM.openWins[name] if w then _G.ARKHER.shell.focusWindow(w) end end
function PM.closeAll() for n, _ in pairs(PM.openWins) do PM.close(n) end end
_G.ARKHER.panel = PM
return PM
