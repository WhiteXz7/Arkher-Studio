-- arkher/actions4.lua — game/run/test/multi/perf/env/asset/plugin.
local A = _G.ARKHER.ACTIONS
local H = _G.ARKHER.actionhelp
-- ===== game =====
local G = function() return H.E().systems.game end
A.game_checkpoint = function() G().checkpoint() end
A.game_dialog = function() G().dialog(H.first()) end
A.game_flag = function(c, a) G().flag(a.key) end
A.game_grant = function() G().grant() end
A.game_leaderstats = function() G().leaderstats() end
A.game_listspawns = function() G().listSpawns() end
A.game_match = function(c, a) G().match(a.op) end
A.game_migrate = function() G().migrate() end
A.game_mod = function(c, a) G().mod(a.op) end
A.game_shutdown = function() G().shutdown() end
A.game_wipeecon = function() G().wipeEcon() end
A.game_zone = function(c, a) G().zone(a and a.kind) end
-- ===== run/sim =====
local R = function() return H.E().sim end
A.run_play = function() R().play() end
A.run_pause = function() R().pause() end
A.run_stop = function() R().stop() end
A.run_restart = function() R().restart() end
A.run_step = function() R().step() end
A.run_resetsim = function() R().resetActors() end
A.run_record = function() R().record(true) end
A.run_replay = function() R().replay() end
A.run_freeze = function() H.E().store.toggle("net_frozen") H.E().toast("Net sim frozen=" .. tostring(H.E().store.get("net_frozen"))) end
-- ===== test =====
local TS = function() return H.E().systems.test end
A.test_local = function() TS().local_() end
A.test_bots = function(c, a) TS().bots(a) end
A.test_all = function() TS().all() end
A.test_selected = function() TS().selected(H.sel()) end
A.test_audit = function() TS().audit() end
-- ===== multi =====
local MU = function() return H.E().systems.multi end
A.multi_announce = function(c, a) MU().announce(a and a.text) end
A.multi_audit = function() MU().audit() end
A.multi_desync = function() MU().desync() end
A.multi_loadcfg = function(c, a) MU().loadcfg(a) end
A.multi_mute = function() MU().mute() end
A.multi_ping = function() MU().ping() end
A.multi_reset = function() MU().reset() end
A.multi_savecfg = function() MU().savecfg() end
A.multi_stress = function(c, a) MU().stress(a) end
-- ===== perf =====
local PF = function() return H.E().systems.perf end
A.perf_audit = function() PF().audit() end
A.perf_baseline = function() PF().baseline() end
A.perf_export = function() PF().export() end
A.perf_fps = function() PF().fps() end
A.perf_gc = function() PF().gc() end
A.perf_merge = function(c, a) PF().merge(a) end
A.perf_quick = function() PF().quick() end
A.perf_record = function() PF().record(true) end
A.perf_snapshot = function() PF().snapshot() end
A.perf_stoprec = function() PF().record(false) end
-- ===== env =====
local EV = function() return H.E().systems.env end
A.env_audit = function() EV().audit() end
A.env_preset = function(c, a) EV().preset(a.name) end
A.env_reset = function() EV().reset() end
A.env_savepreset = function(c, a) EV().savePreset(a and a.name) end
-- ===== asset =====
local AS = function() return H.E().systems.asset end
A.asset_archive = function() AS().archive() end
A.asset_audit = function() AS().audit() end
A.asset_dupfind = function() AS().dupfind() end
A.asset_export = function() AS().export() end
A.asset_import = function(c, a) AS().import(a) end
A.asset_insert = function(c, a) AS().insert(a) end
A.asset_missing = function() AS().missing() end
A.asset_preload = function() AS().preload() end
A.asset_restore = function(c, a) AS().restore(a) end
A.asset_verify = function() AS().verify() end
-- ===== plugin =====
local PL = function() return H.E().systems.plugin end
A.plugin_conflicts = function() PL().conflicts() end
A.plugin_export = function() PL().export() end
A.plugin_import = function(c, a) PL().import(a) end
A.plugin_install = function(c, a) PL().install(a) end
A.plugin_new = function(c, a) PL().new(a) end
A.plugin_package = function() PL().package() end
A.plugin_reload = function() PL().reload() end
A.plugin_reset = function() PL().reset() end
A.plugin_test = function() PL().test() end
A.plugin_toggle = function(c, a) PL().toggle(a.value) end
A.plugin_uninstall = function() PL().uninstall() end
A.plugin_updates = function() PL().updates() end
A.plugin_verify = function() PL().verify() end
return true
