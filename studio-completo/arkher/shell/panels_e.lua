-- arkher/shell/panels_e.lua — bespoke panels: Edit/View/Insert/Run blocks.
local function E() return _G.ARKHER end
local function K() return E().kit end
local function reg(n, f) E().panel.reg(n, f) end
reg("edit_rename", function(w)
  w.setTitle("Rename")
  local k, c = K(), w.content
  local s = E().sel.get()
  k.label(c, #s .. " object(s) selected.")
  local nm = (s[1] and s[1].Name) or ""
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.button(c, "Apply", function() E().cmd.run("edit_rename", { name = nm }) E().panel.close("edit_rename") end)
  if #s > 1 then k.label(c, "Multi-select gets Name_1, Name_2...", true) end
end)
reg("insert_full", function(w)
  w.setTitle("Insert Class")
  local k, c = K(), w.content
  local q = ""
  local classes = { "Part", "WedgePart", "CornerWedgePart", "TrussPart", "MeshPart", "SpawnLocation", "Seat", "VehicleSeat", "Folder", "Model", "Tool", "Attachment", "Script", "LocalScript", "ModuleScript", "BindableEvent", "BindableFunction", "RemoteEvent", "RemoteFunction", "Sound", "ParticleEmitter", "Fire", "Smoke", "Sparkles", "PointLight", "SpotLight", "SurfaceLight", "Decal", "Texture", "ScreenGui", "Frame", "TextButton", "TextLabel", "TextBox", "ImageLabel", "ImageButton", "ScrollingFrame", "ViewportFrame", "UIListLayout", "UIGridLayout", "UIPadding", "UICorner", "UIStroke", "UIGradient", "UIScale", "ProximityPrompt", "ClickDetector", "Dialog", "DialogChoice", "ForceField", "Explosion", "Beam", "Trail", "WeldConstraint", "HingeConstraint", "RopeConstraint", "RodConstraint", "SpringConstraint", "PrismaticConstraint", "BallSocketConstraint", "AlignPosition", "AlignOrientation", "VectorForce", "LinearVelocity", "AngularVelocity", "Torque", "BodyGyro", "BodyVelocity", "NumberValue", "StringValue", "BoolValue", "IntValue", "ObjectValue", "CFrameValue", "Color3Value" }
  local listF = Instance.new("Frame") listF.BackgroundTransparency = 1 listF.Size = UDim2.new(1, 0, 0, 300) listF.LayoutOrder = 99 listF.Parent = c
  local lay = Instance.new("UIListLayout") lay.Parent = listF
  local function render()
    for _, ch in ipairs(listF:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
    local n = 0
    for _, cls in ipairs(classes) do
      if q == "" or cls:lower():find(q:lower(), 1, true) then
        n = n + 1 if n > 40 then return end
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 24) b.Font = Enum.Font.Gotham b.TextSize = 12
        b.Text = "  + " .. cls b.TextXAlignment = Enum.TextXAlignment.Left
        b.BackgroundColor3 = E().shell.theme().btn b.TextColor3 = E().shell.theme().text b.BorderSizePixel = 0 b.Parent = listF
        b.MouseButton1Click:Connect(function() E().ACTIONS.create(nil, { class = cls }) end)
      end
    end
  end
  k.text(c, "Filter", function() return q end, function(v) q = v render() end)
  render()
end)
reg("run_speed", function(w)
  w.setTitle("Sim Speed")
  local k, c = K(), w.content
  k.storeSlider(c, "Multiplier", "sim_speed", 0, 4, 0.25)
  for _, v in ipairs({ 0.25, 0.5, 1, 2, 4 }) do
    k.button(c, v .. "x", function() E().store.set("sim_speed", v) end)
  end
end)
reg("run_help", function(w)
  w.setTitle("Preview Limits")
  local k, c = K(), w.content
  k.label(c, "Preview-play CAN: run NPC/AI brains, cutscenes, clips, day cycle, weather, script loops, sim timescale.")
  k.label(c, "Preview-play CANNOT: run real server Scripts (Edit mode has no server), replicate, or publish. Use Run Loop + bots for logic tests.", true)
end)
reg("breakpoints", function(w)
  w.setTitle("Breakpoints")
  local k, c = K(), w.content
  local SC = E().systems.script
  SC.bp = SC.bp or {}
  local m = ""
  k.text(c, "Match text in source", function() return m end, function(v) m = v end)
  k.button(c, "Add", function()
    if m == "" then return end
    SC.bp[#SC.bp + 1] = { match = m, name = "bp" .. (#SC.bp + 1), enabled = true }
    E().panel.close("breakpoints") E().panel.open("breakpoints", {})
  end)
  k.sep(c)
  for i, b in ipairs(SC.bp) do
    k.toggle(c, (b.name or ("bp" .. i)) .. ": " .. b.match, function() return b.enabled end, function(v) b.enabled = v end)
  end
  if #SC.bp > 0 then k.button(c, "Clear all", function() SC.bp = {} E().panel.close("breakpoints") E().panel.open("breakpoints", {}) end) end
  k.label(c, "Hit = log + pause preview when executed code contains the match.", true)
end)
reg("watch", function(w)
  w.setTitle("Watch")
  local k, c = K(), w.content
  local SC = E().systems.script
  SC.watch = SC.watch or {}
  local ex = ""
  k.text(c, "Expression", function() return ex end, function(v) ex = v end)
  k.button(c, "Add", function()
    if ex == "" then return end
    SC.watch[#SC.watch + 1] = { expr = ex, value = "?" }
    E().panel.close("watch") E().panel.open("watch", {})
  end)
  k.sep(c)
  for _, x in ipairs(SC.watch) do k.label(c, x.expr .. " = " .. tostring(x.value or "?"), true) end
  k.button(c, "Refresh", function() E().panel.close("watch") E().panel.open("watch", {}) end)
  if #SC.watch > 0 then k.button(c, "Clear", function() SC.watch = {} end) end
  k.label(c, "Evaluated 2x/sec while preview plays.", true)
end)
reg("callstack", function(w)
  w.setTitle("Call Stack")
  local k, c = K(), w.content
  k.label(c, E().systems.script.stack(), true)
  k.button(c, "Clear", function() E().systems.script._lastErr = nil E().panel.close("callstack") E().panel.open("callstack", {}) end)
end)
reg("debug_eval", function(w)
  w.setTitle("Evaluate")
  local k, c = K(), w.content
  local ex, out = "", ""
  k.text(c, "Expression", function() return ex end, function(v) ex = v end)
  k.button(c, "Run", function()
    local ok, res = E().systems.script.eval(ex)
    out = (ok and "= " or "ERR ") .. tostring(res):sub(1, 200)
    E().out.log("eval " .. ex .. " -> " .. out)
    E().panel.close("debug_eval") E().panel.open("debug_eval", {})
  end)
  k.label(c, "Runs with engine permissions (documented).", true)
end)
reg("test_asserts", function(w)
  w.setTitle("Assertions")
  local k, c = K(), w.content
  local TS = E().systems.test
  local nm, ex = "", ""
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.text(c, "Expr (true=PASS)", function() return ex end, function(v) ex = v end)
  k.button(c, "Add", function()
    if nm == "" or ex == "" then return end
    TS.asserts[#TS.asserts + 1] = { name = nm, expr = ex, enabled = true }
    E().panel.close("test_asserts") E().panel.open("test_asserts", {})
  end)
  k.sep(c)
  for _, a in ipairs(TS.asserts) do
    k.toggle(c, a.name .. " [" .. (a._last == nil and "?" or (a._last and "PASS" or "FAIL")) .. "]", function() return a.enabled ~= false end, function(v) a.enabled = v end)
  end
  k.label(c, "Checked 2x/sec while preview plays; transitions logged.", true)
end)
reg("test_coverage", function(w)
  w.setTitle("Coverage")
  local k, c = K(), w.content
  local cov = E().systems.test.coverage()
  k.label(c, cov.used .. " / " .. cov.total .. " commands used this session.")
  for _, b in ipairs(cov.byTab) do
    if b.used > 0 then k.label(c, b.tab .. ": " .. b.used .. "/" .. b.total, true) end
  end
  k.button(c, "Refresh", function() E().panel.close("test_coverage") E().panel.open("test_coverage", {}) end)
end)
reg("net_graph", function(w)
  w.setTitle("Net Graph")
  local k, c = K(), w.content
  local lbl = k.label(c, "sampling...", true)
  local alive = true
  local oldClose = w.frame.Destroy
  coroutine.wrap(function()
    for i = 1, 20 do
      if not alive or not lbl.Parent then return end
      local s = E().systems.perf.stats()
      local up = tonumber(s.send) or 0
      local dn = tonumber(s.recv) or 0
      pcall(function()
        lbl.Text = string.format("up %s kbps %s\ndown %s kbps %s", tostring(s.send or "?"), string.rep("#", math.clamp(math.floor(up / 50), 0, 30)), tostring(s.recv or "?"), string.rep("#", math.clamp(math.floor(dn / 50), 0, 30)))
      end)
      wait(0.5)
    end
  end)()
  k.button(c, "Resample", function() E().panel.close("net_graph") E().panel.open("net_graph", {}) end)
end)
reg("script_activity", function(w)
  w.setTitle("Script Activity")
  local k, c = K(), w.content
  local n = 0
  for _, d in ipairs(game:GetDescendants()) do
    if d:IsA("LuaSourceContainer") and d.Parent then
      n = n + 1
      if n <= 40 then
        local dis = ""
        pcall(function() dis = d.Disabled and " [OFF]" or "" end)
        k.button(c, d.ClassName .. ": " .. d.Name .. dis, function() E().sel.set({ d }) E().props.show(d) end)
      end
    end
  end
  k.label(c, n .. " script(s) in place.", true)
end)
reg("error_list", function(w)
  w.setTitle("Error List")
  local k, c = K(), w.content
  for i = math.max(1, #E().out.problems - 30), #E().out.problems do
    local e = E().out.problems[i]
    k.label(c, "[" .. e.kind .. "] " .. e.msg:sub(1, 120), true)
  end
  if #E().out.problems == 0 then k.label(c, "No errors collected.") end
  k.button(c, "Clear", function() E().out.clear() E().panel.close("error_list") end)
end)
return true
