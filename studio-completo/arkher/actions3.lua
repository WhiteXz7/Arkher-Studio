-- arkher/actions3.lua — light/water/phys/audio/fx/npc/ai/script/debug.
local A = _G.ARKHER.ACTIONS
local H = _G.ARKHER.actionhelp
-- ===== light =====
local L = function() return H.E().systems.light end
A.light_shadows = function() local l = game:GetService("Lighting") l.GlobalShadows = not l.GlobalShadows H.E().toast("GlobalShadows=" .. tostring(l.GlobalShadows)) end
A.light_preset = function(c, a) L().preset(a.name) end
A.light_savepreset = function(c, a) L().savePreset(a and a.name) end
A.light_toggleall = function() L().toggleAll() end
A.light_prioritize = function() L().prioritize(H.sel()) end
A.light_audit = function() L().audit() end
A.light_cost = function() L().cost() end
A.light_reset = function() L().reset() end
-- ===== water =====
local W = function() return H.E().systems.water end
A.water_ocean = function(c, a) W().ocean(a) end
A.water_lake = function(c, a) W().lake(a) end
A.water_waterfall = function(c, a) W().waterfall(a) end
A.water_preset = function(c, a) W().preset(a.name) end
A.water_freeze = function() W().freeze() end
A.water_ice = function() W().ice() end
A.water_depth = function() W().depth() end
A.water_audit = function() W().audit() end
A.water_export = function() W().export() end
A.water_reset = function() W().reset() end
-- ===== physics =====
local P = function() return H.E().systems.phys end
A.phys_constraint = function(c, a) P().constraint(a.kind, H.sel(), a) end
A.phys_align = function() P().align(H.sel()) end
A.phys_attachment = function() P().attachment(H.first()) end
A.phys_breakjoints = function() H.each(function(o) if o:IsA("BasePart") then o:BreakJoints() end end) H.done("breakjoints") end
A.phys_explode = function() P().explode() end
A.phys_audit = function() P().audit() end
A.phys_freezeall = function() P().freezeAll(true) end
A.phys_unfreeze = function() P().freezeAll(false) end
-- ===== audio =====
local AU = function() return H.E().systems.audio end
A.audio_play = function() AU().play(H.first()) end
A.audio_stop = function() AU().stop(H.sel()) end
A.audio_pause = function() AU().pause(H.first()) end
A.audio_add = function(c, a) AU().add(a) end
A.audio_preload = function() AU().preload() end
A.audio_muteall = function() AU().muteAll(true) end
A.audio_unmute = function() AU().muteAll(false) end
A.audio_zoneadd = function() AU().zoneAdd() end
A.audio_audit = function() AU().audit() end
A.audio_export = function() AU().export() end
A.audio_reset = function() AU().reset() end
A.audio_testtone = function() AU().testTone() end
-- ===== fx =====
local F = function() return H.E().systems.fx end
A.fx_emit = function(c, a) F().emit(a.kind, H.first()) end
A.fx_burst = function() F().burst(H.sel()) end
A.fx_toggle = function() F().toggle(H.sel()) end
A.fx_forcefield = function() F().forcefield(H.first()) end
A.fx_beam = function(c, a) F().beam(H.sel(), a) end
A.fx_trail = function() F().trail(H.first()) end
A.fx_lightning = function(c, a) F().lightning(a) end
A.fx_shake = function() F().shake() end
A.fx_flash = function() F().flash() end
A.fx_slowmo = function() F().slowmo() end
A.fx_hitstop = function() F().hitstop() end
A.fx_alloff = function() F().all(false) end
A.fx_allon = function() F().all(true) end
A.fx_audit = function() F().audit() end
A.fx_savepreset = function(c, a) F().savePreset(H.first(), a and a.name) end
A.fx_clear = function() F().clear() end
A.fx_sparkleburst = function() F().sparkleburst() end
-- ===== npc =====
local NP = function() return H.E().systems.npc end
A.npc_new = function(c, a) NP().new(a) end
A.npc_preset = function(c, a) NP().preset(a.name) end
A.npc_mode = function(c, a) NP().mode(H.first(), a.mode) end
A.npc_testtalk = function() NP().testTalk(H.first()) end
A.npc_bringall = function() NP().bringAll() end
A.npc_freeze = function() NP().freeze(true) end
A.npc_unfreeze = function() NP().freeze(false) end
A.npc_export = function() NP().export(H.first()) end
A.npc_import = function(c, a) NP().import(a) end
A.npc_audit = function() NP().audit() end
A.npc_healthbar = function() NP().healthbar() end
-- ===== ai =====
local AI = function() return H.E().systems.ai end
A.ai_enable = function() AI().enable(true) end
A.ai_disable = function() AI().enable(false) end
A.ai_findpath = function() AI().findPath() end
A.ai_export = function() AI().export() end
A.ai_import = function(c, a) AI().import(a) end
A.ai_possess = function() AI().possess(H.first()) end
A.ai_killall = function() AI().killAll() end
A.ai_pauseone = function() AI().pauseOne(H.first(), true) end
A.ai_resumeone = function() AI().pauseOne(H.first(), false) end
A.ai_sendto = function() AI().sendTo(H.first()) end
A.ai_stimulus = function(c, a) AI().stimulus(a) end
A.ai_reset = function() AI().reset() end
A.ai_audit = function() AI().audit() end
-- ===== script =====
local S = function() return H.E().systems.script end
A.script_open = function() S().open(H.first()) end
A.script_runonce = function() S().runOnce(H.first()) end
A.script_runloop = function() S().runLoop(H.first(), true) end
A.script_stoploop = function() S().runLoop(nil, false) end
A.script_toserver = function() S().toServer(H.first()) end
A.script_inject = function() S().inject(H.first()) end
A.script_format = function() S().format(H.first()) end
A.script_lint = function() S().lint(H.first()) end
A.script_disable = function() H.each(function(o) if o:IsA("LuaSourceContainer") then H.prop(o, "Disabled", not o.Disabled) end end) H.done("disabled") end
A.script_export = function() S().export() end
A.script_import = function(c, a) S().import(a) end
-- ===== debug =====
A.debug_step = function(c, a) H.E().systems.script.step(a.mode) end
-- ===== world direct =====
A.world_freezetime = function() H.E().store.set("world_frozen", true) H.E().toast("Clock frozen.") end
A.world_preload = function()
  local cam = workspace.CurrentCamera
  if cam then pcall(function() game:GetService("Workspace"):RequestStreamAroundAsync(cam.CFrame.Position) end) H.E().toast("Stream requested.") end
end
A.world_safezone = function() H.E().systems.game.zone("safe") end
A.world_audit = function() H.E().systems.worldext.audit() end
A.world_defaults = function() H.E().systems.worldext.defaults() end
return true
