-- arkher/systems/worldext.lua — world audit/defaults.
local WX = {}
local function E() return _G.ARKHER end
function WX.audit()
  local l = game:GetService("Lighting")
  E().out.log(string.format("World: clock=%.1f gravity=%.0f streaming=%s", l.ClockTime, workspace.Gravity, tostring(workspace.StreamingEnabled)))
  local zones = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "ARKHER_zone" then zones = zones + 1 end end
  E().out.log("Zones: " .. zones)
end
function WX.defaults()
  local l = game:GetService("Lighting")
  l.ClockTime, l.Brightness, l.FogEnd, l.GlobalShadows = 12, 2, 1000, true
  workspace.Gravity = 196.2
  E().toast("World defaults restored.")
end
E().systems.worldext = WX
return WX
