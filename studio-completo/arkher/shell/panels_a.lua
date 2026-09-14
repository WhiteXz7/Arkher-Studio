-- arkher/shell/panels_a.lua — bespoke panels: terrain/model/anim/char/snap.
local function E() return _G.ARKHER end
local function K() return E().kit end
local function reg(n, f) E().panel.reg(n, f) end
local function mats() local o = {} for _, m in ipairs(Enum.Material:GetEnumItems()) do o[#o + 1] = m.Name end return o end
-- TERRAIN
reg("terrain_draw", function(w)
  w.setTitle("Terrain Draw")
  local k, c = K(), w.content
  k.storeSlider(c, "Brush size", "brush_size", 2, 64, 1)
  k.storeSlider(c, "Strength", "brush_strength", 0.1, 1, 0.05)
  k.dropdown(c, "Shape", { "sphere", "box" }, function() return E().store.get("brush_shape") end, function(v) E().store.set("brush_shape", v) end)
  k.dropdown(c, "Material", mats(), function() return E().store.get("terrain_mat") end, function(v) E().store.set("terrain_mat", v) end)
  k.button(c, "Apply at camera focus", function() E().cmd.run("terrain_add") end)
  k.label(c, "Or keep the tool active and click/drag on terrain.", true)
end)
reg("terrain_sculpt", function(w)
  w.setTitle("Sculpt")
  local k, c = K(), w.content
  k.storeSlider(c, "Brush size", "brush_size", 2, 64, 1)
  for _, op in ipairs({ "smooth", "flatten", "grow", "crater", "plateau" }) do
    k.button(c, op:sub(1, 1):upper() .. op:sub(2) .. " @focus", function() E().systems.terrain.brush(op, {}) end)
  end
  k.storeToggle(c, "Auto-smooth after stroke", "terrain_autosmooth")
end)
reg("terrain_erode", function(w)
  w.setTitle("Erode")
  local k, c = K(), w.content
  local n = 12
  k.slider(c, "Drops", 1, 40, 1, function() return n end, function(v) n = v end)
  k.button(c, "Erode @focus", function() E().systems.terrain.erode({ drops = n }) end)
end)
reg("terrain_generate", function(w)
  w.setTitle("Generate")
  local k, c = K(), w.content
  local kind, size = "hills", 128
  k.dropdown(c, "Kind", { "flat", "hills", "islands", "canyon" }, function() return kind end, function(v) kind = v end)
  k.slider(c, "Size", 32, 256, 16, function() return size end, function(v) size = v end)
  k.button(c, "Generate (clears terrain!)", function() E().systems.terrain.generate({ kind = kind, size = size }) end)
end)
reg("terrain_paint", function(w)
  w.setTitle("Terrain Paint")
  local k, c = K(), w.content
  k.dropdown(c, "Target", mats(), function() return E().store.get("terrain_mat") end, function(v) E().store.set("terrain_mat", v) end)
  k.storeSlider(c, "Brush size", "brush_size", 2, 64, 1)
  k.button(c, "Paint @focus", function() local cam = workspace.CurrentCamera local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800) if hit then E().systems.terrain.paintAt(hit.Position, {}) E().undo.commit("tpaint") end end)
end)
reg("terrain_replace", function(w)
  w.setTitle("Replace Material")
  local k, c = K(), w.content
  local s, t = "Grass", "Rock"
  k.dropdown(c, "Source", mats(), function() return s end, function(v) s = v end)
  k.dropdown(c, "Target", mats(), function() return t end, function(v) t = v end)
  k.button(c, "Replace in whole map", function() E().systems.terrain.replace({ source = s, target = t }) end)
end)
reg("terrain_materials", function(w)
  w.setTitle("Terrain Materials")
  local k, c = K(), w.content
  k.dropdown(c, "Active material", mats(), function() return E().store.get("terrain_mat") end, function(v) E().store.set("terrain_mat", v) end)
  k.button(c, "Open Terrain Colors", function() E().panel.open("terrain_colors", {}) end)
end)
reg("terrain_settings", function(w)
  w.setTitle("Terrain Settings")
  local k, c = K(), w.content
  local t = workspace.Terrain
  k.slider(c, "Grass length", 0, 2, 0.1, function() return t.Decoration and 1 or 0 end, function(v) end)
  k.toggle(c, "Decoration (grass)", function() return t.Decoration end, function(v) t.Decoration = v end)
  k.slider(c, "Water transparency", 0, 1, 0.05, function() return t.WaterTransparency end, function(v) t.WaterTransparency = v end)
  k.slider(c, "Wave size", 0, 2, 0.1, function() return t.WaterWaveSize end, function(v) t.WaterWaveSize = v end)
  k.slider(c, "Wave speed", 0, 50, 1, function() return t.WaterWaveSpeed end, function(v) t.WaterWaveSpeed = v end)
end)
-- MODEL
reg("model_extrude", function(w)
  w.setTitle("Extrude")
  local k, c = K(), w.content
  local d = 2
  k.slider(c, "Distance", -20, 20, 0.5, function() return d end, function(v) d = v end)
  k.button(c, "Extrude selection", function() E().systems.model.extrude({ dist = d }) end)
end)
reg("model_bevel", function(w)
  w.setTitle("Bevel")
  local k, c = K(), w.content
  k.label(c, "Parts are boxes: bevel edits EditableMesh (import mesh JSON first).")
  k.button(c, "Import mesh JSON", function() E().panel.open("model_import", {}) end)
end)
reg("model_deform", function(w, p)
  w.setTitle("Deform")
  local k, c = K(), w.content
  local amt = 0.3
  k.slider(c, "Amount", -2, 2, 0.05, function() return amt end, function(v) amt = v end)
  for _, kind in ipairs({ "bend", "twist", "taper" }) do k.button(c, kind, function() E().systems.model.deform(kind, { amount = amt }) end) end
end)
reg("model_array", function(w)
  w.setTitle("Array")
  local k, c = K(), w.content
  local n, dx = 5, 5
  k.slider(c, "Count", 1, 50, 1, function() return n end, function(v) n = v end)
  k.slider(c, "Offset X", -30, 30, 1, function() return dx end, function(v) dx = v end)
  k.button(c, "Apply array", function() E().systems.model.array({ count = n, dx = dx }) end)
end)
reg("model_mirror", function(w)
  w.setTitle("Mirror")
  local k, c = K(), w.content
  for _, ax in ipairs({ "X", "Y", "Z" }) do k.button(c, "Mirror " .. ax, function() E().systems.model.mirror({ axis = ax }) end) end
end)
-- ANIM
reg("anim_new", function(w)
  w.setTitle("New Clip")
  local k, c = K(), w.content
  local nm, dur = "Clip1", 2
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  k.slider(c, "Duration (s)", 0.5, 30, 0.5, function() return dur end, function(v) dur = v end)
  k.button(c, "Create on selected rig", function() E().systems.anim.new(E().sel.get()[1], { name = nm, dur = dur }) end)
end)
reg("anim_keyframe", function(w)
  w.setTitle("Keyframe")
  local k, c = K(), w.content
  local an = E().systems.anim
  k.label(c, "t = " .. string.format("%.2f", an.t) .. "s / f" .. math.floor(an.t * an.fps + 0.5))
  k.button(c, "Add key @playhead", function() an.addKey() end)
  k.button(c, "Key all joints", function() an.keyAll() end)
  k.button(c, "Delete key", function() an.delKey() end)
  k.button(c, "Prev key", function() an.navKey(-1) end)
  k.button(c, "Next key", function() an.navKey(1) end)
  k.slider(c, "Time", 0, (an.clip and an.clip.dur) or 2, 1 / an.fps, function() return an.t end, function(v) an.t = v an.apply(v) end)
end)
-- CHAR
reg("char_new", function(w)
  w.setTitle("New Character")
  local k, c = K(), w.content
  k.button(c, "Spawn R15", function() E().systems.char.new({ rig = "R15" }) end)
  k.button(c, "Spawn R6", function() E().systems.char.new({ rig = "R6" }) end)
end)
reg("char_stats", function(w)
  w.setTitle("Character Stats")
  local k, c = K(), w.content
  local m = E().sel.get()[1]
  local h = m and m:IsA("Model") and m:FindFirstChildWhichIsA("Humanoid")
  if not h then k.label(c, "Select a character.") return end
  k.slider(c, "MaxHealth", 1, 1000, 1, function() return h.MaxHealth end, function(v) h.MaxHealth = v end)
  k.slider(c, "WalkSpeed", 0, 100, 1, function() return h.WalkSpeed end, function(v) h.WalkSpeed = v end)
  k.slider(c, "JumpPower", 0, 200, 1, function() return h.JumpPower end, function(v) h.JumpPower = v end)
end)
-- SNAP
reg("snap_settings", function(w)
  w.setTitle("Snap Settings")
  local k, c = K(), w.content
  k.storeToggle(c, "Snapping enabled", "snap")
  k.storeSlider(c, "Move increment", "snap_move", 0.25, 16, 0.25)
  k.storeSlider(c, "Rotate degrees", "snap_rot", 1, 90, 1)
  k.storeSlider(c, "Scale increment", "snap_scale", 0.05, 2, 0.05)
  k.storeToggle(c, "Show snap overlay", "snapvis")
end)
return true
