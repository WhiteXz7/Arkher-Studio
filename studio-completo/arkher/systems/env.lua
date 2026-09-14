-- arkher/systems/env.lua — environment presets + weather tick.
local EV = { rain = nil, snow = nil }
local function E() return _G.ARKHER end
local function LI() return game:GetService("Lighting") end
function EV.clearWx()
  for _, n in ipairs({ "ARKHER_rain", "ARKHER_snow" }) do local o = workspace:FindFirstChild(n) if o then o:Destroy() end end
  EV.rain, EV.snow = nil, nil
end
function EV.makeRain()
  EV.clearWx()
  local p = Instance.new("Part") p.Name = "ARKHER_rain" p.Anchored = true p.CanCollide = false p.Transparency = 1 p.Size = Vector3.new(200, 1, 200) p.Position = Vector3.new(0, 100, 0) p.Parent = workspace
  local e = Instance.new("ParticleEmitter") e.Rate = 500 e.Speed = NumberRange.new(60, 80) e.Lifetime = NumberRange.new(1, 1.5) e.EmissionDirection = Enum.NormalId.Bottom e.Size = NumberSequence.new(0.2) e.Transparency = NumberSequence.new(0.3) e.Parent = p
  EV.rain = e
end
function EV.makeSnow()
  EV.clearWx()
  local p = Instance.new("Part") p.Name = "ARKHER_snow" p.Anchored = true p.CanCollide = false p.Transparency = 1 p.Size = Vector3.new(200, 1, 200) p.Position = Vector3.new(0, 100, 0) p.Parent = workspace
  local e = Instance.new("ParticleEmitter") e.Rate = 200 e.Speed = NumberRange.new(5, 10) e.Lifetime = NumberRange.new(8, 12) e.EmissionDirection = Enum.NormalId.Bottom e.Size = NumberSequence.new(0.5) e.Parent = p
  EV.snow = e
end
local PRE = {
  day = function() EV.clearWx() E().systems.light.preset("day") end,
  dusk = function() EV.clearWx() E().systems.light.preset("sunset") end,
  night = function() EV.clearWx() E().systems.light.preset("night") end,
  storm = function() EV.makeRain() E().systems.light.preset("horror") LI().FogEnd = 300 pcall(function() workspace.GlobalWind = Vector3.new(50, 0, 20) end) end,
  snow = function() EV.makeSnow() E().systems.light.preset("day") LI().ClockTime = 10 LI().FogEnd = 400 end,
  desert = function() EV.clearWx() LI().ClockTime = 13 LI().Brightness = 2.5 LI().FogColor = Color3.fromRGB(230, 200, 150) LI().FogEnd = 900 end,
  alien = function() EV.clearWx() LI().ClockTime = 20 LI().Ambient = Color3.fromRGB(80, 40, 120) LI().OutdoorAmbient = Color3.fromRGB(100, 60, 160) LI().FogColor = Color3.fromRGB(60, 20, 90) LI().FogEnd = 500 end,
  underwater = function() EV.clearWx() LI().Ambient = Color3.fromRGB(20, 60, 90) LI().OutdoorAmbient = Color3.fromRGB(30, 80, 120) LI().FogColor = Color3.fromRGB(20, 60, 90) LI().FogEnd = 120 LI().Brightness = 1 end,
}
function EV.preset(name)
  local f = PRE[name]
  if f then f() E().toast("Environment: " .. name) else E().toast("Unknown preset.") end
end
function EV.savePreset(name) E().systems.light.savePreset(name) end
function EV.reset() EV.preset("day") end
function EV.audit()
  local l = LI()
  E().out.log(string.format("Env: clock=%.1f tech=%s fog=%d rain=%s snow=%s", l.ClockTime, l.Technology.Name, l.FogEnd, tostring(EV.rain ~= nil), tostring(EV.snow ~= nil)))
end
function EV.tick(dt)
  -- follow camera with weather emitters
  local cam = workspace.CurrentCamera
  if not cam then return end
  for _, n in ipairs({ "ARKHER_rain", "ARKHER_snow" }) do local o = workspace:FindFirstChild(n) if o then o.Position = cam.Focus.Position + Vector3.new(0, 60, 0) end end
end
E().systems.env = EV
return EV
