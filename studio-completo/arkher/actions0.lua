-- arkher/actions0.lua — action helpers (lazy runtime handles).
local U = _G.ARKHER.util
local A = _G.ARKHER.ACTIONS
local H = {}
_G.ARKHER.actionhelp = H
function H.E() return _G.ARKHER end
function H.sel() return _G.ARKHER.sel.get() end
function H.each(fn) for _, o in ipairs(_G.ARKHER.sel.get()) do if o and o.Parent then fn(o) end end end
function H.first() local s = _G.ARKHER.sel.get() return s[1] end
function H.ws() return game:GetService("Workspace") end
function H.need(n, what)
  local s = _G.ARKHER.sel.get()
  if #s < (n or 1) then _G.ARKHER.toast("Select " .. (what or "an object") .. " first.") return nil end
  return s
end
function H.done(label, undo)
  if undo ~= false then _G.ARKHER.undo.commit() end
  H.E().cmd.done(label)
end
function H.prop(obj, key, val)
  _G.ARKHER.undo.prop(obj, key, val, tostring(key) .. " change")
end
-- mark a stub-free guarantee: every registered act must exist (checked by registry.validate)
return H
