-- arkher/shell/panels_c.lua — bespoke panels: project/game/script/perf/shell + generic.
local function E() return _G.ARKHER end
local function K() return E().kit end
local function reg(n, f) E().panel.reg(n, f) end
-- PROJECT
reg("project_new", function(w)
  w.setTitle("New Project")
  local k, c = K(), w.content
  local nm, tp = "Untitled", "baseplate"
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.dropdown(c, "Template", { "baseplate", "empty" }, function() return tp end, function(v) tp = v end)
  k.button(c, "Create", function() E().systems.project.new({ name = nm, template = tp }) end)
end)
reg("project_open", function(w)
  w.setTitle("Open Project")
  local k, c = K(), w.content
  local f = E().systems.project.folder()
  local any = false
  for _, v in ipairs(f:GetChildren()) do
    if v:IsA("StringValue") and v.Name:sub(1, 5) == "save_" then any = true
      k.button(c, v.Name, function() E().systems.project.openSlot(v.Name) end)
    end
  end
  if not any then k.label(c, "No saves yet.") end
end)
reg("project_saveas", function(w)
  w.setTitle("Save As")
  local k, c = K(), w.content
  local nm = E().systems.project.name
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.button(c, "Save", function() E().systems.project.saveas(nm) end)
end)
reg("project_recent", function(w)
  w.setTitle("Recent")
  local k, c = K(), w.content
  k.button(c, E().systems.project.name .. " (current)", function() end)
  k.label(c, "More slots appear in Open Project.", true)
end)
reg("project_info", function(w)
  w.setTitle("Project Info")
  local k, c = K(), w.content
  local parts, scripts = 0, 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") then parts = parts + 1 elseif d:IsA("LuaSourceContainer") then scripts = scripts + 1 end end
  k.label(c, "Name: " .. E().systems.project.name)
  k.label(c, "Parts: " .. parts .. "  Scripts: " .. scripts)
end)
reg("project_validate", function(w, p)
  w.setTitle("Validate")
  local k, c = K(), w.content
  p = p or {}
  for _, e in ipairs(p.errs or {}) do k.label(c, "ERR: " .. e) end
  for _, e in ipairs(p.warns or {}) do k.label(c, "WARN: " .. e) end
  if #(p.errs or {}) + #(p.warns or {}) == 0 then k.label(c, "Clean.") end
  k.button(c, "Re-run", function() E().systems.project.validate() end)
end)
reg("project_restore", function(w)
  w.setTitle("Restore")
  local k, c = K(), w.content
  for _, v in ipairs(E().systems.project.folder():GetChildren()) do
    if v:IsA("StringValue") and (v.Name:sub(1, 7) == "backup_" or v.Name:sub(1, 5) == "snap_") then
      k.button(c, v.Name, function() E().systems.project.openSlot(v.Name) end)
    end
  end
end)
-- GAME
reg("game_rules", function(w)
  w.setTitle("Game Rules")
  local k, c = K(), w.content
  local g = E().systems.game
  k.button(c, "Toggle friendly fire", function() g.flag("friendlyFire") end)
  k.slider(c, "Max players", 1, 100, 1, function() return game:GetService("Players").MaxPlayers end, function(v) game:GetService("Players").MaxPlayers = v end)
  k.label(c, "Timers/rounds/quests live in their own panels under Game tab.", true)
end)
-- SCRIPT
reg("script_editor", function(w, p)
  w.setTitle("Script Editor")
  local k, c = K(), w.content
  p = p or {}
  local o = p.target or E().sel.get()[1]
  if not (o and o.Parent and o:IsA("LuaSourceContainer")) then k.label(c, "Select a Script.") return end
  k.label(c, o:GetFullName(), true)
  local tb = Instance.new("TextBox")
  tb.Size = UDim2.new(1, 0, 0, 260) tb.Font = Enum.Font.Code tb.TextSize = 13
  tb.Text = E().systems.script.getSource(o) or "--"
  tb.BackgroundColor3 = E().shell.theme().input tb.TextColor3 = E().shell.theme().text
  tb.TextXAlignment = Enum.TextXAlignment.Left tb.TextYAlignment = Enum.TextYAlignment.Top
  tb.MultiLine = true tb.ClearTextOnFocus = false tb.TextWrapped = false tb.Parent = c
  k.button(c, "Apply", function()
    local ok = E().systems.script.setSource(o, tb.Text)
    E().toast(ok and "Applied to Source." or "Stored (Source needs plugin context).")
  end)
  k.button(c, "Run once", function() E().systems.script.runCode(tb.Text) end)
  k.button(c, "Lint", function() local f, e = loadstring(tb.Text) E().toast(f and "Clean." or ("Error: " .. tostring(e))) end)
end)
reg("script_find", function(w)
  w.setTitle("Find in Scripts")
  local k, c = K(), w.content
  local q = ""
  k.text(c, "Query", function() return q end, function(v) q = v end)
  k.button(c, "Search", function()
    local n = 0
    for _, d in ipairs(game:GetDescendants()) do
      if d:IsA("LuaSourceContainer") then local s = E().systems.script.getSource(d)
        if s and s:find(q, 1, true) then n = n + 1 E().out.log("match: " .. d:GetFullName()) end
      end
    end
    E().toast(n .. " matches (see Output).")
  end)
end)
-- PERF
reg("perf_memory", function(w)
  w.setTitle("Memory")
  local k, c = K(), w.content
  local s = E().systems.perf.stats()
  k.label(c, "Total: " .. tostring(s.mem and (math.floor(s.mem) .. " MB") or "?"))
  k.label(c, "Instances: " .. tostring(s.instances or "?"))
  k.button(c, "GC collect", function() E().systems.perf.gc() end)
  k.button(c, "Refresh", function() E().panel.close("perf_memory") E().panel.open("perf_memory", {}) end)
end)
-- NET
reg("net_latency", function(w)
  w.setTitle("Latency Sim")
  local k, c = K(), w.content
  k.storeSlider(c, "Latency (ms)", "net_latency", 0, 2000, 10)
  k.label(c, "Applies to bridge calls (honest local simulation).", true)
end)
reg("net_stats", function(w)
  w.setTitle("Net Stats")
  local k, c = K(), w.content
  local s = E().systems.perf.stats()
  k.label(c, "Send: " .. tostring(s.send or "?") .. " kbps")
  k.label(c, "Recv: " .. tostring(s.recv or "?") .. " kbps")
end)
-- TEST
reg("test_bots", function(w)
  w.setTitle("Bot Clients")
  local k, c = K(), w.content
  local n = 4
  k.slider(c, "Count", 1, 20, 1, function() return n end, function(v) n = v end)
  k.button(c, "Spawn", function() E().systems.test.bots({ count = n }) end)
end)
-- HOME paint
reg("home_color", function(w)
  w.setTitle("Color")
  local k, c = K(), w.content
  local cols = { "Bright red", "Bright orange", "Bright yellow", "Bright green", "Bright blue", "Bright violet", "White", "Black", "Grey", "Brown" }
  k.dropdown(c, "Paint color", cols, function() return E().store.get("paint_color") end, function(v) E().store.set("paint_color", v) end)
  k.button(c, "Apply to selection", function()
    local ok, col = pcall(function() return Color3.fromName(E().store.get("paint_color")) end)
    if ok then for _, o in ipairs(E().sel.get()) do if o:IsA("BasePart") then o.Color = col end end E().undo.commit("color") end
  end)
end)
reg("home_material", function(w)
  w.setTitle("Material")
  local k, c = K(), w.content
  k.button(c, "Apply current to selection", function() E().systems.mat.apply(E().sel.get()) end)
  k.button(c, "Open library", function() E().panel.open("mat_browse", {}) end)
end)
reg("home_transp", function(w)
  w.setTitle("Transparency")
  local k, c = K(), w.content
  local v = 0
  k.slider(c, "Value", 0, 1, 0.05, function() return v end, function(x) v = x for _, o in ipairs(E().sel.get()) do if o:IsA("BasePart") then o.Transparency = x end end end)
  k.button(c, "Commit (undoable)", function() E().undo.commit("transparency") end)
end)
reg("home_reflect", function(w)
  w.setTitle("Reflectance")
  local k, c = K(), w.content
  local v = 0
  k.slider(c, "Value", 0, 1, 0.05, function() return v end, function(x) v = x for _, o in ipairs(E().sel.get()) do if o:IsA("BasePart") then o.Reflectance = x end end end)
  k.button(c, "Commit (undoable)", function() E().undo.commit("reflectance") end)
end)
-- CAMERA
reg("camera_fov", function(w)
  w.setTitle("Camera")
  local k, c = K(), w.content
  local cam = workspace.CurrentCamera
  k.slider(c, "FOV", 10, 120, 1, function() return cam.FieldOfView end, function(v) cam.FieldOfView = v end)
end)
-- SHELL
reg("theme", function(w)
  w.setTitle("Theme")
  local k, c = K(), w.content
  k.dropdown(c, "Theme", { "dark", "light", "contrast" }, function() return E().store.get("theme") end, function(v) E().store.set("theme", v) E().shell.applyTheme() end)
  k.storeToggle(c, "High contrast", "contrast")
end)
reg("welcome", function(w)
  w.setTitle("Welcome to ARKHER")
  local k, c = K(), w.content
  k.label(c, "A complete real engine inside Roblox: 30 tabs, 1200 commands.")
  k.button(c, "Take the tour", function() E().panel.open("tour", {}) end)
  k.button(c, "New project", function() E().cmd.run("file_new") end)
  k.button(c, "Command palette (Ctrl+K)", function() E().panel.open("cmdpalette", {}) end)
end)
reg("tour", function(w)
  w.setTitle("Tour")
  local k, c = K(), w.content
  k.label(c, "1) Topbar: 30 tabs, each with 40 real tools.")
  k.label(c, "2) Explorer + Properties on the sides.")
  k.label(c, "3) Bottom: Output, Console, Problems.")
  k.label(c, "4) Every tool runs for real; panels tune options.")
  k.button(c, "Open shortcuts", function() E().panel.open("shortcuts", {}) end)
end)
reg("about", function(w)
  w.setTitle("About")
  local k, c = K(), w.content
  k.label(c, "ARKHER Engine R21 — rebuilt as a real engine.")
  k.label(c, "30 tabs x 40 commands = 1200 real commands.", true)
  k.label(c, "Honest limits are declared per system.", true)
end)
reg("shortcuts", function(w)
  w.setTitle("Shortcuts")
  local k, c = K(), w.content
  local rows = { "Ctrl+N new", "Ctrl+S save", "Ctrl+Z/Y undo/redo", "Del delete", "F2 rename", "F focus", "F5 play", "Shift+F5 stop", "Ctrl+K palette", "1-9 quick tools" }
  for _, r in ipairs(rows) do k.label(c, r) end
end)
reg("cmdpalette", function(w)
  w.setTitle("Command Palette")
  local k, c = K(), w.content
  local q = ""
  local listF = Instance.new("Frame") listF.BackgroundTransparency = 1 listF.Size = UDim2.new(1, 0, 0, 300) listF.LayoutOrder = 99 listF.Parent = c
  local lay = Instance.new("UIListLayout") lay.Parent = listF
  local function render()
    for _, ch in ipairs(listF:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
    local n = 0
    for _, t in ipairs(E().registry.tabs) do
      for _, cmd in ipairs(t.commands) do
        if q == "" or cmd.label:lower():find(q:lower(), 1, true) or cmd.id:find(q:lower(), 1, true) then
          n = n + 1
          if n > 30 then return end
          local b = Instance.new("TextButton")
          b.Size = UDim2.new(1, 0, 0, 26) b.Font = Enum.Font.Gotham b.TextSize = 12
          b.Text = "  " .. t.label .. " > " .. cmd.label b.TextXAlignment = Enum.TextXAlignment.Left
          b.BackgroundColor3 = E().shell.theme().btn b.TextColor3 = E().shell.theme().text b.BorderSizePixel = 0 b.Parent = listF
          b.MouseButton1Click:Connect(function() E().panel.close("cmdpalette") E().cmd.run(cmd.id) end)
        end
      end
    end
  end
  k.text(c, "Search 1200 commands", function() return q end, function(v) q = v render() end)
  render()
end)
reg("edit_history", function(w)
  w.setTitle("History")
  local k, c = K(), w.content
  for i = #E().undo.stack, 1, -1 do local e = E().undo.stack[i] k.label(c, (i == #E().undo.stack and "> " or "") .. e.label, true) end
  k.button(c, "Undo", function() E().undo.undo() end)
  k.button(c, "Redo", function() E().undo.redo() end)
end)
-- GENERIC fallback: always functional (run + editable args + related).
reg("__generic", function(w, p)
  p = p or {}
  local k, c = K(), w.content
  local cmd = p.cmd and E().registry.byId[p.cmd] or nil
  w.setTitle(cmd and cmd.label or (p.name or "Panel"))
  if cmd then
    k.label(c, cmd.tip or "", true)
    local args = {}
    for kk, vv in pairs(cmd.arg or {}) do args[kk] = vv end
    for kk, vv in pairs(args) do
      if type(vv) == "boolean" then k.toggle(c, kk, function() return args[kk] end, function(v) args[kk] = v end)
      elseif type(vv) == "number" then k.text(c, kk, function() return args[kk] end, function(v) args[kk] = tonumber(v) or args[kk] end, true)
      else k.text(c, kk, function() return tostring(args[kk]) end, function(v) args[kk] = v end) end
    end
    k.button(c, "Run " .. cmd.label, function() E().cmd.run(cmd.id, args) end)
    k.sep(c)
    k.label(c, "Related:", true)
    local shown = 0
    for _, t in ipairs(E().registry.tabs) do
      for _, o in ipairs(t.commands) do
        if o.group == cmd.group and o.id ~= cmd.id and shown < 6 then k.cmd(c, o.id) shown = shown + 1 end
      end
      if shown >= 6 then break end
    end
  else
    k.label(c, "Panel: " .. tostring(p.name or "?"))
    k.label(c, "This panel is being expanded; the command already executed.", true)
  end
end)
return true
