-- arkher/shell/panels_d.lua — bespoke panels: File block.
local function E() return _G.ARKHER end
local function K() return E().kit end
local function reg(n, f) E().panel.reg(n, f) end
local function PR() return E().systems.project end
reg("project_import", function(w)
  w.setTitle("Import JSON")
  local k, c = K(), w.content
  k.label(c, "Paste place/selection JSON (from Export).", true)
  local tb = Instance.new("TextBox")
  tb.Size = UDim2.new(1, 0, 0, 180) tb.Font = Enum.Font.Code tb.TextSize = 11 tb.Text = ""
  tb.BackgroundColor3 = E().shell.theme().input tb.TextColor3 = E().shell.theme().text
  tb.TextXAlignment = Enum.TextXAlignment.Left tb.TextYAlignment = Enum.TextYAlignment.Top
  tb.MultiLine = true tb.ClearTextOnFocus = false tb.TextWrapped = true tb.Parent = c
  k.button(c, "Import parts", function() PR().importJSON(tb.Text) end)
end)
reg("project_export", function(w)
  w.setTitle("Export Selection")
  local k, c = K(), w.content
  local n = #E().sel.get()
  k.label(c, n .. " object(s) selected.")
  k.button(c, "Export to Output", function() PR().exportsel(E().sel.get()) end)
  k.button(c, "Export whole place", function() PR().exportplace() end)
end)
reg("project_publish", function(w)
  w.setTitle("Publish")
  local k, c = K(), w.content
  local ok, errs = PR().publishCheck()
  if ok then k.label(c, "Checks passed.") else for _, e in ipairs(errs or {}) do k.label(c, "ERR: " .. e) end end
  k.button(c, "Re-check", function() E().panel.close("project_publish") E().panel.open("project_publish", {}) end)
  k.sep(c)
  k.label(c, "Real publish happens in Studio: File > Publish to Roblox. This flow validates + snapshots first.", true)
  k.button(c, "Snapshot + open Studio publish", function()
    local ok2, e2 = PR().publishCheck()
    if not ok2 then E().toast("Fix errors first.") return end
    PR().snapshot("prepublish")
    E().out.log("Ready for Studio publish: save this place file, then File > Publish to Roblox.")
    E().toast("Snapshotted. Publish via Studio File menu.")
  end)
end)
reg("project_cloud", function(w)
  w.setTitle("Cloud Slots")
  local k, c = K(), w.content
  local q = PR().cloudQuota()
  k.label(c, q.slots .. " slots, " .. math.floor(q.bytes / 1024) .. " KB.")
  for _, v in ipairs(PR().listSlots("cloud_")) do
    k.button(c, v.Name, function() PR().openSlot(v.Name) end)
  end
  k.button(c, "Save current to cloud", function() PR().cloudsave() end)
end)
reg("cloud", function(w)
  w.setTitle("Cloud Info")
  local k, c = K(), w.content
  local q = PR().cloudQuota()
  k.label(c, "Slots used: " .. q.slots)
  k.label(c, "Bytes: " .. q.bytes)
  k.label(c, "Backend: project storage in this place (works offline, travels with the file).", true)
  k.button(c, "Open cloud slots", function() E().panel.open("project_cloud", {}) end)
end)
reg("project_settings", function(w)
  w.setTitle("Project Settings")
  local k, c = K(), w.content
  local s = PR().cfgGet("settings")
  local nm, genre = s.name or PR().name, s.genre or "All"
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.dropdown(c, "Genre", { "All", "Adventure", "Obby", "Roleplay", "Horror", "Simulator", "Other" }, function() return genre end, function(v) genre = v end)
  k.button(c, "Save", function() PR().name = nm PR().cfgSet("settings", { name = nm, genre = genre }) E().toast("Settings saved.") end)
end)
reg("project_snapshot", function(w)
  w.setTitle("Snapshot")
  local k, c = K(), w.content
  local nm = "snap1"
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.button(c, "Save snapshot", function() PR().snapshot(nm) end)
  k.sep(c)
  for _, v in ipairs(PR().listSlots("snap_")) do
    k.button(c, "Restore " .. v.Name, function() PR().openSlot(v.Name) end)
  end
end)
reg("files", function(w)
  w.setTitle("File Manager")
  local k, c = K(), w.content
  local f = PR().folder()
  for _, v in ipairs(f:GetChildren()) do
    local info = v.Name .. " (" .. math.floor(#(v:IsA("StringValue") and v.Value or "") / 1024) .. " KB)"
    k.button(c, info, function() end)
  end
  k.sep(c)
  local del = ""
  k.text(c, "Delete slot (exact name)", function() return del end, function(v) del = v end)
  k.button(c, "Delete", function() PR().deleteSlot(del) E().panel.close("files") E().panel.open("files", {}) end)
end)
reg("templates", function(w)
  w.setTitle("Templates")
  local k, c = K(), w.content
  k.button(c, "Baseplate + spawn", function() PR().new({ name = "Baseplate", template = "baseplate" }) end)
  k.button(c, "Empty", function() PR().new({ name = "Empty", template = "empty" }) end)
  k.button(c, "Obby starter", function() PR().new({ name = "Obby", template = "obby" }) end)
  k.label(c, "Terrain template: New Project > Empty, then Terrain > Generate.", true)
end)
reg("versions", function(w)
  w.setTitle("Versions")
  local k, c = K(), w.content
  for _, v in ipairs(PR().listSlots("save_")) do
    local info = PR().slotInfo(v.Name)
    k.button(c, v.Name .. " (" .. (info and info.parts or "?") .. " parts)", function() PR().openSlot(v.Name) end)
  end
  k.sep(c)
  k.button(c, "Compare two versions", function() E().panel.open("versions_diff", {}) end)
  k.button(c, "Backups", function() E().panel.open("backup", {}) end)
end)
reg("versions_diff", function(w)
  w.setTitle("Compare Versions")
  local k, c = K(), w.content
  local slots = {}
  for _, v in ipairs(PR().listSlots("save_")) do slots[#slots + 1] = v.Name end
  for _, v in ipairs(PR().listSlots("snap_")) do slots[#slots + 1] = v.Name end
  if #slots < 2 then k.label(c, "Need 2+ saves/snapshots.") return end
  local a, b = slots[1], slots[2]
  k.dropdown(c, "A", slots, function() return a end, function(v) a = v end)
  k.dropdown(c, "B", slots, function() return b end, function(v) b = v end)
  k.button(c, "Diff", function()
    local da, db = PR().readSlot(a), PR().readSlot(b)
    if not (da and db) then E().toast("Unreadable slot.") return end
    local na = {}
    for _, p in ipairs(da.parts or {}) do na[p.n or "?"] = (na[p.n or "?"] or 0) + 1 end
    local added, removed = 0, 0
    local nb = {}
    for _, p in ipairs(db.parts or {}) do nb[p.n or "?"] = (nb[p.n or "?"] or 0) + 1 end
    for n, x in pairs(nb) do if (na[n] or 0) < x then added = added + (x - (na[n] or 0)) end end
    for n, x in pairs(na) do if (nb[n] or 0) < x then removed = removed + (x - (nb[n] or 0)) end end
    E().out.log(string.format("Diff %s -> %s: +%d -%d parts (%d -> %d).", a, b, added, removed, #(da.parts or {}), #(db.parts or {})))
    E().toast(string.format("+%d -%d (see Output).", added, removed))
  end)
end)
reg("backup", function(w)
  w.setTitle("Backups")
  local k, c = K(), w.content
  k.button(c, "Backup now", function() PR().backup() end)
  k.storeSlider(c, "Keep slots", "backup_keep", 1, 20, 1)
  for _, v in ipairs(PR().listSlots("backup_")) do
    k.button(c, "Restore " .. v.Name, function() PR().openSlot(v.Name) end)
  end
  k.button(c, "Prune to keep-limit", function()
    local l = PR().listSlots("backup_")
    local keep = tonumber(E().store.get("backup_keep")) or 5
    while #l > keep do local v = table.remove(l, 1) v:Destroy() end
    E().toast("Pruned.")
  end)
end)
reg("permissions", function(w)
  w.setTitle("Permissions")
  local k, c = K(), w.content
  local p = PR().cfgGet("perms")
  local ce = p.canEdit ~= false
  local cp = p.canPublish ~= false
  k.toggle(c, "Editing allowed", function() return ce end, function(v) ce = v end)
  k.toggle(c, "Publishing allowed", function() return cp end, function(v) cp = v end)
  k.button(c, "Save", function() PR().cfgSet("perms", { canEdit = ce, canPublish = cp }) E().toast("Permissions saved.") end)
  k.label(c, "Publish flow blocks when publishing is off.", true)
end)
reg("localization", function(w)
  w.setTitle("Localization")
  local k, c = K(), w.content
  local t = PR().cfgGet("locale")
  local key, val = "", ""
  k.text(c, "Key", function() return key end, function(v) key = v end)
  k.text(c, "Text", function() return val end, function(v) val = v end)
  k.button(c, "Add/Update", function()
    if key == "" then return end
    t[key] = val PR().cfgSet("locale", t)
    E().panel.close("localization") E().panel.open("localization", {})
  end)
  k.sep(c)
  for kk, vv in pairs(t) do k.label(c, kk .. " = " .. tostring(vv):sub(1, 60), true) end
  k.label(c, "Lookup: project.tr(key) in console/plugins.", true)
end)
reg("team", function(w)
  w.setTitle("Team")
  local k, c = K(), w.content
  local t = PR().cfgGet("team")
  local nm = ""
  k.text(c, "Invite name", function() return nm end, function(v) nm = v end)
  k.button(c, "Create invite code", function()
    if nm == "" then return end
    local code = "ARK-" .. string.char(math.random(65, 90), math.random(65, 90)) .. "-" .. math.random(1000, 9999)
    t[nm] = code PR().cfgSet("team", t)
    E().out.log("Invite for " .. nm .. ": " .. code)
    E().panel.close("team") E().panel.open("team", {})
  end)
  k.sep(c)
  for kk, vv in pairs(t) do k.label(c, kk .. ": " .. vv, true) end
  k.label(c, "Online now:", true)
  for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do k.label(c, pl.Name, true) end
end)
return true
