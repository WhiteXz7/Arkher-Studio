-- arkher/shell/panels_b.lua — bespoke panels: light/phys/audio/fx/world/water.
local function E() return _G.ARKHER end
local function K() return E().kit end
local function reg(n, f) E().panel.reg(n, f) end
local function LI() return game:GetService("Lighting") end
local function fxOf(cls)
  local l = LI()
  local f = l:FindFirstChildWhichIsA(cls)
  if not f then f = Instance.new(cls) f.Parent = l end
  return f
end
-- LIGHT
reg("light_atmosphere", function(w)
  w.setTitle("Atmosphere")
  local k, c = K(), w.content
  local a = fxOf("Atmosphere")
  k.slider(c, "Density", 0, 1, 0.01, function() return a.Density end, function(v) a.Density = v end)
  k.slider(c, "Offset", 0, 10, 0.1, function() return a.Offset end, function(v) a.Offset = v end)
  k.color(c, "Color", function() return a.Color end, function(v) a.Color = v end)
  k.color(c, "Decay", function() return a.Decay end, function(v) a.Decay = v end)
  k.slider(c, "Glare", 0, 10, 0.1, function() return a.Glare end, function(v) a.Glare = v end)
  k.slider(c, "Haze", 0, 10, 0.1, function() return a.Haze end, function(v) a.Haze = v end)
end)
reg("light_bloom", function(w)
  w.setTitle("Bloom")
  local k, c = K(), w.content
  local b = fxOf("BloomEffect")
  k.toggle(c, "Enabled", function() return b.Enabled end, function(v) b.Enabled = v end)
  k.slider(c, "Intensity", 0, 5, 0.1, function() return b.Intensity end, function(v) b.Intensity = v end)
  k.slider(c, "Size", 0, 100, 1, function() return b.Size end, function(v) b.Size = v end)
  k.slider(c, "Threshold", 0, 5, 0.05, function() return b.Threshold end, function(v) b.Threshold = v end)
end)
reg("light_blur", function(w)
  w.setTitle("Blur")
  local k, c = K(), w.content
  local b = fxOf("BlurEffect")
  k.toggle(c, "Enabled", function() return b.Enabled end, function(v) b.Enabled = v end)
  k.slider(c, "Size", 0, 100, 1, function() return b.Size end, function(v) b.Size = v end)
end)
reg("light_colorcorr", function(w)
  w.setTitle("Color Correction")
  local k, c = K(), w.content
  local b = fxOf("ColorCorrectionEffect")
  k.toggle(c, "Enabled", function() return b.Enabled end, function(v) b.Enabled = v end)
  k.slider(c, "Brightness", -1, 1, 0.01, function() return b.Brightness end, function(v) b.Brightness = v end)
  k.slider(c, "Contrast", -1, 2, 0.01, function() return b.Contrast end, function(v) b.Contrast = v end)
  k.slider(c, "Saturation", -1, 2, 0.01, function() return b.Saturation end, function(v) b.Saturation = v end)
  k.color(c, "Tint", function() return b.TintColor end, function(v) b.TintColor = v end)
end)
reg("light_dof", function(w)
  w.setTitle("Depth Of Field")
  local k, c = K(), w.content
  local b = fxOf("DepthOfFieldEffect")
  k.toggle(c, "Enabled", function() return b.Enabled end, function(v) b.Enabled = v end)
  k.slider(c, "FocusDistance", 0, 500, 1, function() return b.FocusDistance end, function(v) b.FocusDistance = v end)
  k.slider(c, "InFocusRadius", 0, 100, 1, function() return b.InFocusRadius end, function(v) b.InFocusRadius = v end)
  k.slider(c, "NearIntensity", 0, 1, 0.01, function() return b.NearIntensity end, function(v) b.NearIntensity = v end)
  k.slider(c, "FarIntensity", 0, 1, 0.01, function() return b.FarIntensity end, function(v) b.FarIntensity = v end)
end)
reg("light_sunrays", function(w)
  w.setTitle("Sun Rays")
  local k, c = K(), w.content
  local b = fxOf("SunRaysEffect")
  k.toggle(c, "Enabled", function() return b.Enabled end, function(v) b.Enabled = v end)
  k.slider(c, "Intensity", 0, 5, 0.05, function() return b.Intensity end, function(v) b.Intensity = v end)
  k.slider(c, "Spread", 0, 1, 0.01, function() return b.Spread end, function(v) b.Spread = v end)
end)
reg("light_exposure", function(w)
  w.setTitle("Exposure")
  local k, c = K(), w.content
  local l = LI()
  k.slider(c, "Compensation", -3, 3, 0.1, function() return l.ExposureCompensation end, function(v) l.ExposureCompensation = v end)
  k.slider(c, "Env diffuse", 0, 1, 0.01, function() return l.EnvironmentDiffuseScale end, function(v) l.EnvironmentDiffuseScale = v end)
  k.slider(c, "Env specular", 0, 1, 0.01, function() return l.EnvironmentSpecularScale end, function(v) l.EnvironmentSpecularScale = v end)
end)
reg("light_tech", function(w)
  w.setTitle("Technology")
  local k, c = K(), w.content
  local l = LI()
  k.dropdown(c, "Tech", { "Legacy", "Voxel", "ShadowMap", "Future", "Compatibility" }, function() return l.Technology.Name end, function(v) pcall(function() l.Technology = Enum.Technology[v] end) end)
  k.toggle(c, "Global shadows", function() return l.GlobalShadows end, function(v) l.GlobalShadows = v end)
end)
reg("light_sun", function(w)
  w.setTitle("Sun & Moon")
  local k, c = K(), w.content
  local l = LI()
  k.slider(c, "Sun size", 0, 100, 1, function() return l.SunAngularSize end, function(v) l.SunAngularSize = v end)
  k.slider(c, "Moon size", 0, 100, 1, function() return l.MoonAngularSize end, function(v) l.MoonAngularSize = v end)
  k.color(c, "Shift top", function() return l.ColorShift_Top end, function(v) l.ColorShift_Top = v end)
  k.color(c, "Shift bottom", function() return l.ColorShift_Bottom end, function(v) l.ColorShift_Bottom = v end)
end)
reg("light_colorshift", function(w)
  w.setTitle("ColorShift")
  local k, c = K(), w.content
  local l = LI()
  k.color(c, "Top", function() return l.ColorShift_Top end, function(v) l.ColorShift_Top = v end)
  k.color(c, "Bottom", function() return l.ColorShift_Bottom end, function(v) l.ColorShift_Bottom = v end)
end)
-- PHYS
reg("phys_constraint", function(w, p)
  w.setTitle("Constraint")
  local k, c = K(), w.content
  k.label(c, "Select 2 parts, then pick a constraint.")
  for _, kind in ipairs({ "Weld", "Hinge", "Rope", "Rod", "Spring", "Prismatic", "BallSocket" }) do
    k.button(c, kind, function() E().systems.phys.constraint(kind, E().sel.get(), {}) end)
  end
end)
reg("phys_mass", function(w)
  w.setTitle("Physical")
  local k, c = K(), w.content
  local o = E().sel.get()[1]
  if not (o and o:IsA("BasePart")) then k.label(c, "Select a part.") return end
  k.label(c, "Mass: " .. string.format("%.1f", o:GetMass()))
  k.toggle(c, "Custom properties", function() return o.CustomPhysicalProperties ~= nil end, function(v)
    o.CustomPhysicalProperties = v and PhysicalProperties.new(0.7, 0.3, 0.5) or nil
  end)
  k.toggle(c, "Massless", function() return o.Massless end, function(v) o.Massless = v end)
end)
-- AUDIO
reg("audio_mixer", function(w)
  w.setTitle("Mixer")
  local k, c = K(), w.content
  local au = E().systems.audio
  for bus, _ in pairs(au.buses) do
    k.slider(c, bus, 0, 2, 0.05, function() return au.buses[bus] end, function(v) au.buses[bus] = v E().out.log("bus " .. bus .. "=" .. v) end)
  end
  k.button(c, "Mute all", function() au.muteAll(true) end)
  k.button(c, "Unmute", function() au.muteAll(false) end)
end)
reg("audio_add", function(w)
  w.setTitle("Add Sound")
  local k, c = K(), w.content
  local id, vol, loop = "", 0.5, false
  k.text(c, "SoundId (rbxassetid://...)", function() return id end, function(v) id = v end)
  k.slider(c, "Volume", 0, 10, 0.1, function() return vol end, function(v) vol = v end)
  k.toggle(c, "Loop", function() return loop end, function(v) loop = v end)
  k.button(c, "Create", function() E().systems.audio.add({ id = id, vol = vol, loop = loop }) end)
end)
local function sfxPanel(name, cls, sliders)
  reg(name, function(w)
    w.setTitle(name)
    local k, c = K(), w.content
    local o = E().sel.get()[1]
    local s = o and o:IsA("Sound") and o or nil
    if not s then k.label(c, "Select a Sound.") return end
    local e = s:FindFirstChildWhichIsA(cls)
    if not e then k.button(c, "Add " .. cls, function() local n = Instance.new(cls) n.Parent = s E().undo.created(n) end) return end
    k.toggle(c, "Enabled", function() return e.Enabled end, function(v) e.Enabled = v end)
    for _, sl in ipairs(sliders) do k.slider(c, sl[1], sl[2], sl[3], sl[4], function() return e[sl[1]] end, function(v) e[sl[1]] = v end) end
  end)
end
sfxPanel("audio_eq", "EqualizerSoundEffect", { { "HighGain", -20, 20, 1 }, { "MidGain", -20, 20, 1 }, { "LowGain", -20, 20, 1 } })
sfxPanel("audio_reverb", "ReverbSoundEffect", { { "DecayTime", 0.1, 20, 0.1 }, { "Density", 0, 1, 0.01 }, { "WetLevel", -20, 20, 1 } })
sfxPanel("audio_echo", "EchoSoundEffect", { { "Delay", 0, 5, 0.05 }, { "Feedback", 0, 1, 0.01 }, { "WetLevel", -20, 20, 1 } })
sfxPanel("audio_distort", "DistortionSoundEffect", { { "Level", 0, 1, 0.01 } })
sfxPanel("audio_chorus", "ChorusSoundEffect", { { "Depth", 0, 1, 0.01 }, { "Rate", 0, 20, 0.5 }, { "WetLevel", -20, 20, 1 } })
sfxPanel("audio_pitch", "PitchSoundEffect", { { "Octave", 0.5, 2, 0.05 } })
-- FX
reg("fx_emitter", function(w)
  w.setTitle("Emitter")
  local k, c = K(), w.content
  local o = E().sel.get()[1]
  local e = o and o:IsA("ParticleEmitter") and o or nil
  if not e then k.label(c, "Select a ParticleEmitter.") k.button(c, "Create one", function() E().systems.fx.emit("particles", nil) end) return end
  k.toggle(c, "Enabled", function() return e.Enabled end, function(v) e.Enabled = v end)
  k.slider(c, "Rate", 0, 500, 1, function() return e.Rate end, function(v) e.Rate = v end)
  k.slider(c, "Speed min", 0, 100, 1, function() return e.Speed.Min end, function(v) e.Speed = NumberRange.new(v, e.Speed.Max) end)
  k.slider(c, "Speed max", 0, 100, 1, function() return e.Speed.Max end, function(v) e.Speed = NumberRange.new(e.Speed.Min, v) end)
  k.slider(c, "Life min", 0, 20, 0.1, function() return e.Lifetime.Min end, function(v) e.Lifetime = NumberRange.new(v, e.Lifetime.Max) end)
  k.slider(c, "Life max", 0, 20, 0.1, function() return e.Lifetime.Max end, function(v) e.Lifetime = NumberRange.new(e.Lifetime.Min, v) end)
  k.button(c, "Burst 50", function() e:Emit(50) end)
end)
-- NPC
reg("npc_new", function(w)
  w.setTitle("New NPC")
  local k, c = K(), w.content
  local nm = "NPC"
  k.text(c, "Name", function() return nm end, function(v) nm = v end)
  for _, pr in ipairs({ "civilian", "guard", "merchant", "enemy" }) do k.button(c, "Spawn " .. pr, function() E().systems.npc.preset(pr) end) end
  k.button(c, "Spawn custom (" .. nm .. ")", function() E().systems.npc.new({ name = nm }) end)
end)
-- WORLD
reg("world_clock", function(w)
  w.setTitle("Clock")
  local k, c = K(), w.content
  local l = LI()
  k.slider(c, "ClockTime", 0, 24, 0.1, function() return l.ClockTime end, function(v) l.ClockTime = v end)
  k.slider(c, "Latitude", -90, 90, 1, function() return l.GeographicLatitude end, function(v) l.GeographicLatitude = v end)
  for _, t in ipairs({ { "Sunrise", 6.5 }, { "Noon", 12 }, { "Sunset", 18.5 }, { "Midnight", 0 } }) do k.button(c, t[1], function() l.ClockTime = t[2] end) end
end)
reg("world_daycycle", function(w)
  w.setTitle("Day Cycle")
  local k, c = K(), w.content
  local speed, on = 0.5, false
  k.slider(c, "Hours/sec", 0.01, 4, 0.01, function() return speed end, function(v) speed = v end)
  k.button(c, "Start cycle", function()
    if on then return end on = true
    E().sim.addLoop(function(dt)
      if E().store.get("world_frozen") then return end
      local l = LI() l.ClockTime = (l.ClockTime + dt * speed) % 24
    end)
  end)
  k.button(c, "Freeze", function() E().store.set("world_frozen", true) end)
  k.button(c, "Unfreeze", function() E().store.set("world_frozen", false) end)
end)
reg("world_ambient", function(w)
  w.setTitle("Ambient")
  local k, c = K(), w.content
  local l = LI()
  k.color(c, "Ambient", function() return l.Ambient end, function(v) l.Ambient = v end)
  k.color(c, "Outdoor", function() return l.OutdoorAmbient end, function(v) l.OutdoorAmbient = v end)
  k.slider(c, "Brightness", 0, 10, 0.1, function() return l.Brightness end, function(v) l.Brightness = v end)
end)
reg("world_fog", function(w)
  w.setTitle("Fog")
  local k, c = K(), w.content
  local l = LI()
  k.slider(c, "FogStart", 0, 5000, 10, function() return l.FogStart end, function(v) l.FogStart = v end)
  k.slider(c, "FogEnd", 0, 10000, 10, function() return l.FogEnd end, function(v) l.FogEnd = v end)
  k.color(c, "FogColor", function() return l.FogColor end, function(v) l.FogColor = v end)
end)
reg("world_sky", function(w)
  w.setTitle("Sky")
  local k, c = K(), w.content
  k.button(c, "Default sky", function() local l = LI() local s = l:FindFirstChildWhichIsA("Sky") if s then s:Destroy() end end)
  k.toggle(c, "Stars", function() return LI():FindFirstChildWhichIsA("Stars") ~= nil end, function(v)
    local s = LI():FindFirstChildWhichIsA("Stars")
    if v and not s then local n = Instance.new("Stars") n.Parent = LI() elseif not v and s then s:Destroy() end
  end)
end)
reg("world_gravity", function(w)
  w.setTitle("Gravity")
  local k, c = K(), w.content
  k.slider(c, "Gravity", 0, 500, 1, function() return workspace.Gravity end, function(v) workspace.Gravity = v end)
  k.button(c, "Moon (50)", function() workspace.Gravity = 50 end)
  k.button(c, "Earth (196)", function() workspace.Gravity = 196.2 end)
end)
reg("world_wind", function(w)
  w.setTitle("Wind")
  local k, c = K(), w.content
  local function gw() local v = Vector3.new() pcall(function() v = workspace.GlobalWind end) return v end
  k.slider(c, "X", -100, 100, 1, function() return gw().X end, function(v) pcall(function() local g = gw() workspace.GlobalWind = Vector3.new(v, g.Y, g.Z) end) end)
  k.slider(c, "Z", -100, 100, 1, function() return gw().Z end, function(v) pcall(function() local g = gw() workspace.GlobalWind = Vector3.new(g.X, g.Y, v) end) end)
end)
reg("world_streaming", function(w)
  w.setTitle("Streaming")
  local k, c = K(), w.content
  k.toggle(c, "Enabled", function() return workspace.StreamingEnabled end, function(v) pcall(function() workspace.StreamingEnabled = v end) end)
  k.slider(c, "Target radius", 64, 2048, 16, function() return workspace.StreamingTargetRadius end, function(v) pcall(function() workspace.StreamingTargetRadius = v end) end)
  k.slider(c, "Min radius", 32, 1024, 16, function() return workspace.StreamingMinRadius end, function(v) pcall(function() workspace.StreamingMinRadius = v end) end)
end)
-- WATER
reg("water_level", function(w)
  w.setTitle("Sea Level")
  local k, c = K(), w.content
  k.label(c, "Terrain water fills lowlands automatically; adjust terrain or wave props:")
  k.button(c, "Water surface panel", function() E().panel.open("water_surface", {}) end)
  k.button(c, "Make ocean", function() E().systems.water.ocean({}) end)
end)
reg("water_surface", function(w)
  w.setTitle("Water Surface")
  local k, c = K(), w.content
  local t = workspace.Terrain
  k.color(c, "Color", function() return t.WaterColor3 end, function(v) t.WaterColor3 = v end)
  k.slider(c, "Transparency", 0, 1, 0.01, function() return t.WaterTransparency end, function(v) t.WaterTransparency = v end)
  k.slider(c, "Reflectance", 0, 1, 0.01, function() return t.WaterReflectance end, function(v) t.WaterReflectance = v end)
  k.slider(c, "Wave size", 0, 2, 0.05, function() return t.WaterWaveSize end, function(v) t.WaterWaveSize = v end)
  k.slider(c, "Wave speed", 0, 50, 1, function() return t.WaterWaveSpeed end, function(v) t.WaterWaveSpeed = v end)
end)
return true
