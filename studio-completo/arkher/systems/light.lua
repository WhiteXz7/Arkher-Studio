-- arkher/systems/light.lua — lighting presets + audits + bulk ops.
local L = {}
local function E() return _G.ARKHER end
local function LI() return game:GetService("Lighting") end
local PRESETS = {
  day = { ClockTime = 12, Brightness = 2, Ambient = Color3.fromRGB(120, 120, 120), OutdoorAmbient = Color3.fromRGB(150, 150, 150), GlobalShadows = true, FogEnd = 1000 },
  night = { ClockTime = 0, Brightness = 1, Ambient = Color3.fromRGB(40, 40, 60), OutdoorAmbient = Color3.fromRGB(50, 50, 80), GlobalShadows = true, FogEnd = 600 },
  sunset = { ClockTime = 18, Brightness = 1.5, Ambient = Color3.fromRGB(150, 100, 80), OutdoorAmbient = Color3.fromRGB(180, 120, 90), GlobalShadows = true, FogEnd = 800 },
  horror = { ClockTime = 0, Brightness = 0.3, Ambient = Color3.fromRGB(10, 10, 12), OutdoorAmbient = Color3.fromRGB(15, 15, 20), GlobalShadows = true, FogEnd = 150, FogColor = Color3.fromRGB(5, 5, 8) },
}
function L.preset(name)
  local p = PRESETS[name]
  if not p then E().toast("Unknown preset.") return end
  local l = LI()
  for k, v in pairs(p) do pcall(function() l[k] = v end) end
  E().toast("Lighting: " .. name)
end
function L.savePreset(name)
  name = name or ("preset" .. math.random(100, 999))
  local l = LI()
  local d = { ClockTime = l.ClockTime, Brightness = l.Brightness, FogEnd = l.FogEnd }
  E().out.log("LIGHTPRESET " .. name .. " " .. game:GetService("HttpService"):JSONEncode(d))
  E().toast("Preset saved -> Output.")
end
function L.toggleAll()
  local any = false
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then any = any or d.Enabled end end
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") then d.Enabled = not any end end
  E().toast("All lights " .. ((not any) and "on" or "off") .. ".")
end
function L.prioritize(list)
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("Light") then o.Brightness = math.max(o.Brightness, 2) end end
  E().toast("Selected lights boosted.")
end
function L.audit()
  local n, shadow = 0, 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") and d.Enabled then n = n + 1 if d.Shadows then shadow = shadow + 1 end end end
  E().out.log(string.format("Lights: %d enabled, %d casting shadows.", n, shadow))
  if n > 32 then E().out.warn("Over 32 enabled lights: mobile perf risk.") end
end
function L.cost()
  local n = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") and d.Enabled then n = n + 1 end end
  local tech = LI().Technology.Name
  E().out.log(string.format("Lighting cost: %d lights, tech=%s, shadows=%s", n, tech, tostring(LI().GlobalShadows)))
end
function L.reset() L.preset("day") end
E().systems.light = L
return L
