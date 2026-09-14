-- arkher/shell/store.lua — settings + state (persisted as config instances).
local U = _G.ARKHER.util
local DEF = {
  autosave = false, autosave_min = 5, grid = true, snap = true, snapvis = false,
  rulers = false, coords = false, tooltips = true, verbose = false, contrast = false,
  snap_move = 1, snap_rot = 15, snap_scale = 0.25, uiscale = 1, terrain_autosmooth = false,
  anim_onion = false, anim_keysnap = true, cut_letterbox = false, cut_duck = true,
  fx_vignette = false, ui_safearea = false, water_flowvis = false, water_rescue = true,
  audio_duck = true, phys_jointvis = false, phys_sleepvis = false, ai_debugvis = false,
  net_frozen = false, telemetry = false, perfmode = false, tips = true, reduce_motion = false,
  plugin_autoupd = false, language = "en", theme = "dark", brush_size = 6, brush_strength = 0.5,
  brush_shape = "sphere", terrain_mat = "Grass", paint_color = "Bright red", paint_mat = "Plastic",
  sim_speed = 1, net_latency = 0, ai_tick = 10, ai_budget = 4, world_frozen = false,
}
local S = { data = {}, listeners = {} }
for k, v in pairs(DEF) do S.data[k] = v end
function S.get(k) return S.data[k] end
function S.set(k, v) S.data[k] = v S.save() for _, f in ipairs(S.listeners[k] or {}) do pcall(f, v) end end
function S.toggle(k) S.set(k, not S.data[k]) end
function S.on(k, f) S.listeners[k] = S.listeners[k] or {} S.listeners[k][#S.listeners[k] + 1] = f end
function S.reset() for k, v in pairs(DEF) do S.data[k] = v end S.save() end
function S.cfgFolder()
  local ss = game:GetService("ServerStorage")
  local f = ss:FindFirstChild("ARKHER_cfg")
  if not f then f = Instance.new("Folder") f.Name = "ARKHER_cfg" f.Parent = ss end
  return f
end
function S.save()
  local f = S.cfgFolder()
  pcall(function()
    local ok, HS = pcall(game.GetService, game, "HttpService")
    local json = ok and HS:JSONEncode(S.data) or ""
    local v = f:FindFirstChild("settings") or Instance.new("StringValue")
    v.Name = "settings" v.Value = json v.Parent = f
  end)
end
function S.load()
  local f = game:GetService("ServerStorage"):FindFirstChild("ARKHER_cfg")
  local v = f and f:FindFirstChild("settings")
  if v and v.Value ~= "" then pcall(function()
    local d = game:GetService("HttpService"):JSONDecode(v.Value)
    for k, val in pairs(d) do S.data[k] = val end
  end) end
end
function S.export() local j = game:GetService("HttpService"):JSONEncode(S.data) _G.ARKHER.out.log("SETTINGS " .. j) _G.ARKHER.toast("Settings -> Output.") end
function S.import(json) if not json then _G.ARKHER.panel.open("settings_import") return end pcall(function() local d = game:GetService("HttpService"):JSONDecode(json) for k, v in pairs(d) do S.data[k] = v end S.save() end) end
function S.wipe() local f = game:GetService("ServerStorage"):FindFirstChild("ARKHER_cfg") if f then f:Destroy() end S.reset() end
_G.ARKHER.store = S
return S
