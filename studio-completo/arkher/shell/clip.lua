-- arkher/shell/clip.lua — clipboard (in-memory clones, undoable paste).
local CLIP = { buf = {} }
function CLIP.copy(list)
  CLIP.buf = {}
  for _, o in ipairs(list or {}) do if o and o.Parent then local ok, cl = pcall(function() return o:Clone() end) if ok and cl then CLIP.buf[#CLIP.buf + 1] = cl end end end
  _G.ARKHER.toast(#CLIP.buf .. " copied.")
end
function CLIP.cut(list) CLIP.copy(list) _G.ARKHER.ACTIONS.edit_delete() end
function CLIP.paste(parent)
  parent = parent or workspace
  if #CLIP.buf == 0 then _G.ARKHER.toast("Clipboard empty.") return end
  local out = {}
  for _, o in ipairs(CLIP.buf) do local cl = o:Clone()
    if cl:IsA("BasePart") or cl:IsA("Model") then local p = cl:GetPivot() cl:PivotTo(p + Vector3.new(2, 0, 2)) end
    cl.Parent = parent _G.ARKHER.undo.created(cl) out[#out + 1] = cl
  end
  _G.ARKHER.undo.commit("paste") _G.ARKHER.sel.set(out)
end
function CLIP.duplicate(list) CLIP.copy(list) CLIP.paste(workspace) end
_G.ARKHER.systems = _G.ARKHER.systems or {}
_G.ARKHER.systems.clip = CLIP
return CLIP
