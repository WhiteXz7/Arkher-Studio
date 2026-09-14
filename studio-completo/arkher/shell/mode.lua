-- arkher/shell/mode.lua — tool mode dispatch.
local MO = { current = "Select", arg = nil, tools = {} }
function MO.reg(name, tool) MO.tools[name] = tool end
function MO.set(name, arg)
  local prev = MO.tools[MO.current]
  if prev and prev.deactivate then pcall(prev.deactivate) end
  MO.current, MO.arg = name, arg
  local t = MO.tools[name]
  if t and t.activate then pcall(t.activate, arg) end
  _G.ARKHER.out.log("Tool: " .. name)
  if _G.ARKHER.shell and _G.ARKHER.shell.setTool then _G.ARKHER.shell.setTool(name) end
end
function MO.get() return MO.current end
_G.ARKHER.mode = MO
return MO
