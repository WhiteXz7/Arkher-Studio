-- arkher/actions1.lua — shell/sel/view/edit/project/logs/settings/create.
local A = _G.ARKHER.ACTIONS
local H = _G.ARKHER.actionhelp
local U = _G.ARKHER.util
-- ===== shell =====
A.shell_panel = function(c, a) H.E().panel.open(a.name, a.props) end
A.shell_toggle = function(c, a) H.E().panel.toggle(a.panel) end
A.shell_exit = function() H.E().shell.exit() end
A.shell_reload = function() H.E().shell.reload() end
A.shell_safemode = function() H.E().shell.safemode() end
A.settings_toggle = function(c, a) H.E().store.toggle(a.key) H.E().toast(a.key .. " = " .. tostring(H.E().store.get(a.key))) end
A.settings_resetall = function() H.E().store.reset() H.E().toast("All settings reset.") end
A.settings_export = function() H.E().store.export() end
A.settings_import = function(c, a) H.E().store.import(a and a.json) end
A.settings_wipe = function() H.E().store.wipe() end
A.tool_mode = function(c, a) H.E().mode.set(a.mode) end
A.prop_toggle = function(c, a)
  local s = H.need(1) if not s then return end
  for _, o in ipairs(s) do local ok, v = pcall(function() return o[a.key] end) if ok and type(v) == "boolean" then H.prop(o, a.key, not v) end end
  H.done("toggle " .. a.key)
end
-- ===== selection =====
A.sel_all = function() local t = {} for _, d in ipairs(H.ws():GetDescendants()) do if d:IsA("BasePart") or d:IsA("Model") then t[#t + 1] = d end end H.E().sel.set(t) end
A.sel_none = function() H.E().sel.set({}) end
A.sel_invert = function()
  local cur = {} for _, o in ipairs(H.sel()) do cur[o] = true end
  local t = {} for _, d in ipairs(H.ws():GetDescendants()) do if (d:IsA("BasePart") or d:IsA("Model")) and not cur[d] then t[#t + 1] = d end end
  H.E().sel.set(t)
end
A.sel_children = function() local t = {} H.each(function(o) for _, ch in ipairs(o:GetChildren()) do t[#t + 1] = ch end end) H.E().sel.set(t) end
A.sel_parent = function() local t, seen = {}, {} H.each(function(o) local p = o.Parent if p and p ~= game and not seen[p] then seen[p] = true t[#t + 1] = p end end) H.E().sel.set(t) end
A.sel_similar = function() local f = H.first() if not f then return H.need(1) end local t = {} for _, d in ipairs(H.ws():GetDescendants()) do if d.ClassName == f.ClassName then t[#t + 1] = d end end H.E().sel.set(t) end
-- ===== view =====
A.view_camera = function(c, a) H.E().systems.camera.preset(a.preset) end
A.view_focus = function() H.E().systems.camera.focus(H.sel()) end
A.view_frameall = function() H.E().systems.camera.frameAll() end
A.view_uiscale = function(c, a) H.E().shell.uiscale(a) end
A.view_focusmode = function() H.E().shell.focusmode() end
A.view_zen = function() H.E().shell.zen() end
A.view_layout = function(c, a) H.E().shell.layout(a.op) end
A.view_copycam = function() local cf = workspace.CurrentCamera.CFrame H.E().out.log("CAM " .. table.concat({ cf:GetComponents() }, ",")) H.E().toast("Camera CFrame -> Output.") end
-- ===== edit =====
A.edit_undo = function() H.E().undo.undo() end
A.edit_redo = function() H.E().undo.redo() end
A.edit_clearhistory = function() H.E().undo.clear() H.E().toast("History cleared.") end
A.edit_repeat = function() H.E().cmd.repeatLast() end
A.edit_cut = function() H.E().systems.clip.cut(H.sel()) end
A.edit_copy = function() H.E().systems.clip.copy(H.sel()) end
A.edit_paste = function() H.E().systems.clip.paste(H.ws()) end
A.edit_pasteinto = function() local f = H.first() H.E().systems.clip.paste(f or H.ws()) end
A.edit_duplicate = function() H.E().systems.clip.duplicate(H.sel()) end
A.edit_delete = function() local s = H.need(1) if not s then return end for _, o in ipairs(s) do H.E().undo.deleted(o, "delete") o:Destroy() end H.done("delete") H.E().sel.set({}) end
A.edit_rename = function(c, a)
  local s = H.need(1) if not s then return end
  local name = (a and a.name) or ("Renamed" .. math.random(100, 999))
  if #s == 1 then H.prop(s[1], "Name", name)
  else for i, o in ipairs(s) do H.prop(o, "Name", name .. "_" .. i) end end
  H.done("rename")
end
A.edit_copypath = function() local f = H.first() if f then H.E().store.set("copypath", f:GetFullName()) H.E().out.log("Path: " .. f:GetFullName()) H.E().toast("Path shown in Output.") else H.need(1) end end
A.edit_group = function() local s = H.need(1) if not s then return end local m = Instance.new("Model") m.Name = "Group" for _, o in ipairs(s) do o.Parent = m end m.Parent = H.ws() H.E().undo.created(m) H.done("group") H.E().sel.set({ m }) end
A.edit_ungroup = function() local s = H.need(1, "a Model") if not s then return end for _, o in ipairs(s) do if o:IsA("Model") then for _, ch in ipairs(o:GetChildren()) do ch.Parent = H.ws() end o:Destroy() end end H.done("ungroup") end
A.edit_lock = function() H.each(function(o) H.prop(o, "Locked", true) end) H.done("lock") end
A.edit_unlock = function() H.each(function(o) H.prop(o, "Locked", false) end) H.done("unlock") end
A.edit_hide = function() H.each(function(o) if o:IsA("BasePart") then H.prop(o, "Transparency", 1) end end) H.done("hide") end
A.edit_unhide = function() for _, d in ipairs(H.ws():GetDescendants()) do if d:IsA("BasePart") and d.Transparency >= 1 then d.Transparency = 0 end end H.done("unhide") end
A.edit_anchor = function() H.each(function(o) if o:IsA("BasePart") then H.prop(o, "Anchored", not o.Anchored) end end) H.done("anchor") end
A.edit_unanchor = function() H.each(function(o) if o:IsA("BasePart") then H.prop(o, "Anchored", false) end end) H.done("unanchor") end
A.edit_collide = function(c, a)
  H.each(function(o) if o:IsA("BasePart") then local v = a.toggle and (not o.CanCollide) or a.value H.prop(o, "CanCollide", v) end end) H.done("collide")
end
A.edit_pivotreset = function() H.each(function(o) if o:IsA("Model") then local cf, sz = o:GetBoundingBox() o:PivotTo(cf) end end) H.done("pivot") end
A.edit_align = function(c, a)
  local s = H.need(2, "2+ objects") if not s then return end
  local c0 = s[1]:GetPivot().Position
  for i = 2, #s do local p = s[i]:GetPivot() local np = p.Position
    if a.axis == "X" then np = Vector3.new(c0.X, np.Y, np.Z) elseif a.axis == "Y" then np = Vector3.new(np.X, c0.Y, np.Z) else np = Vector3.new(np.X, np.Y, c0.Z) end
    s[i]:PivotTo(CFrame.new(np) * (p - p.Position)) end
  H.done("align " .. a.axis)
end
A.edit_distribute = function(c, a)
  local s = H.need(3, "3+ objects") if not s then return end
  local ax = a.axis local vals = {}
  for _, o in ipairs(s) do vals[#vals + 1] = { o = o, v = o:GetPivot().Position[ax] } end
  table.sort(vals, function(x, y) return x.v < y.v end)
  local lo, hi = vals[1].v, vals[#vals].v
  for i = 2, #vals - 1 do local t = lo + (hi - lo) * ((i - 1) / (#vals - 1)) local p = vals[i].o:GetPivot() local np = p.Position
    if ax == "X" then np = Vector3.new(t, np.Y, np.Z) elseif ax == "Y" then np = Vector3.new(np.X, t, np.Y) else np = Vector3.new(np.X, np.Y, t) end
    vals[i].o:PivotTo(CFrame.new(np) * (p - p.Position)) end
  H.done("distribute " .. ax)
end
A.edit_mirror = function(c, a)
  local s = H.need(1) if not s then return end
  local cx = s[1]:GetPivot().Position[a.axis]
  for _, o in ipairs(s) do local cl = o:Clone() local p = cl:GetPivot() local np = p.Position
    local d = np[a.axis] - cx
    if a.axis == "X" then np = Vector3.new(cx - d, np.Y, np.Z) elseif a.axis == "Y" then np = Vector3.new(np.X, cx - d, np.Z) else np = Vector3.new(np.X, np.Y, cx - d) end
    cl:PivotTo(CFrame.new(np) * (p - p.Position)) cl.Parent = H.ws() H.E().undo.created(cl) end
  H.done("mirror " .. a.axis)
end
-- ===== create =====
A.create = function(c, a)
  local inst = Instance.new(a.class)
  if a.shape and inst:IsA("Part") then inst.Shape = Enum.PartType[a.shape] end
  local parent = H.ws()
  if a.parent then parent = game:GetService(a.parent) end
  if a.intoSelection then local f = H.first() if f then parent = f end end
  if inst:IsA("BasePart") then inst.Anchored = true inst.Size = Vector3.new(4, 1, 2) inst:PivotTo(H.E().systems.camera.focusCF() or CFrame.new(0, 5, 0)) end
  pcall(function() inst.Name = a.class end)
  inst.Parent = parent H.E().undo.created(inst) H.done("create " .. a.class) H.E().sel.set({ inst })
end
-- ===== project =====
local P = function() return H.E().systems.project end
A.project_new = function(c, a) P().new(a) end
A.project_open = function(c, a) P().open(a) end
A.project_save = function() P().save() end
A.project_saveas = function(c, a) P().saveas(a and a.name) end
A.project_revert = function() P().revert() end
A.project_close = function() P().close() end
A.project_newplace = function() P().newplace() end
A.project_dupplace = function() P().dupplace() end
A.project_archive = function() P().archive() end
A.project_import = function(c, a) P().import(a) end
A.project_exportsel = function() P().exportsel(H.sel()) end
A.project_exportplace = function() P().exportplace() end
A.project_importplace = function(c, a) P().importplace(a) end
A.project_publish = function(c, a) P().publish(a) end
A.project_cloudsave = function() P().cloudsave() end
A.project_cloudopen = function() P().cloudopen() end
A.project_backup = function() P().backup() end
A.project_restore = function(c, a) P().restore(a) end
A.project_snapshot = function(c, a) P().snapshot(a and a.name) end
A.project_cleanup = function() P().cleanup() end
A.project_validate = function() P().validate() end
-- ===== logs =====
A.logs_clear = function() H.E().out.clear() end
A.logs_filter = function(c, a) H.E().out.filter(a.level) end
A.logs_save = function() H.E().out.save() end
A.logs_export = function() H.E().out.export() end
return true
