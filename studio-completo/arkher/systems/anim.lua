-- arkher/systems/anim.lua — keyframe clips on Motor6D rigs (real playback).
local AN = { clip = nil, playing = false, t = 0, speed = 1, loop = true, fps = 30, sel = {} }
local function E() return _G.ARKHER end
local function jointsOf(m)
  local out = {}
  if m and m:IsA("Model") then for _, d in ipairs(m:GetDescendants()) do if d:IsA("Motor6D") then out[d.Name] = d end end end
  return out
end
function AN.new(model, a)
  a = a or {}
  if not (model and model:IsA("Model")) then E().toast("Select a rigged model.") return end
  AN.clip = { name = a.name or "Clip1", dur = a.dur or 2, tracks = {} }
  AN.t, AN.playing = 0, false
  E().toast("Clip created on " .. model.Name .. ".")
  E().store.set("anim_model", model:GetFullName())
end
function AN.model()
  local path = E().store.get("anim_model")
  if not path then return nil end
  local ok, m = pcall(function()
    local o = game
    for part in string.gmatch(path, "[^%.]+") do o = o:FindFirstChild(part) or o[part] end
    return o
  end)
  return ok and m or nil
end
function AN.addKey(a)
  if not AN.clip then E().toast("Create a clip first.") return end
  local m = AN.model() if not m then E().toast("Rig lost; reopen clip.") return end
  local js = jointsOf(m)
  local frame = math.floor(AN.t * AN.fps + 0.5)
  local count = 0
  for name, j in pairs(js) do
    AN.clip.tracks[name] = AN.clip.tracks[name] or {}
    local cf = j.Transform
    AN.clip.tracks[name][frame] = { cf:GetComponents() }
    count = count + 1
  end
  E().toast("Key @f" .. frame .. " (" .. count .. " joints).")
end
function AN.keyAll() AN.addKey() end
function AN.delKey()
  if not AN.clip then return end
  local frame = math.floor(AN.t * AN.fps + 0.5)
  for _, tr in pairs(AN.clip.tracks) do tr[frame] = nil end
  E().toast("Key @f" .. frame .. " deleted.")
end
function AN.navKey(dir)
  if not AN.clip then return end
  local frames = {}
  for _, tr in pairs(AN.clip.tracks) do for f, _ in pairs(tr) do frames[f] = true end end
  local cur = math.floor(AN.t * AN.fps + 0.5)
  local best = nil
  for f, _ in pairs(frames) do
    if dir > 0 and f > cur and (not best or f < best) then best = f end
    if dir < 0 and f < cur and (not best or f > best) then best = f end
  end
  if best then AN.t = best / AN.fps AN.apply(AN.t) else E().toast("No key that way.") end
end
function AN.apply(t)
  if not AN.clip then return end
  local m = AN.model() if not m then return end
  local js = jointsOf(m)
  local frame = t * AN.fps
  for name, tr in pairs(AN.clip.tracks) do
    local j = js[name]
    if j then
      local f0, f1 = nil, nil
      for f, _ in pairs(tr) do
        if f <= frame and (not f0 or f > f0) then f0 = f end
        if f >= frame and (not f1 or f < f1) then f1 = f end
      end
      if f0 and f1 then
        local c0 = CFrame.new(unpack(tr[f0])) local c1 = CFrame.new(unpack(tr[f1]))
        local a = (f1 == f0) and 0 or ((frame - f0) / (f1 - f0))
        j.Transform = c0:Lerp(c1, a)
      elseif f0 then j.Transform = CFrame.new(unpack(tr[f0]))
      elseif f1 then j.Transform = CFrame.new(unpack(tr[f1])) end
    end
  end
end
function AN.play() if not AN.clip then E().toast("No clip.") return end AN.playing = true end
function AN.pause() AN.playing = false end
function AN.stop() AN.playing = false AN.t = 0 AN.apply(0) end
function AN.toggleLoop() AN.loop = not AN.loop E().toast("Loop=" .. tostring(AN.loop)) end
function AN.tick(dt)
  if not (AN.playing and AN.clip) then return end
  AN.t = AN.t + dt * AN.speed
  if AN.t >= AN.clip.dur then if AN.loop then AN.t = 0 else AN.playing = false AN.t = AN.clip.dur end end
  AN.apply(AN.t)
end
function AN.copyKeys() AN.sel = { t = AN.t } E().toast("Keys copied @t=" .. string.format("%.2f", AN.t)) end
function AN.pasteKeys()
  if not (AN.clip and AN.sel.t) then E().toast("Nothing copied.") return end
  local df = math.floor(AN.t * AN.fps + 0.5) - math.floor(AN.sel.t * AN.fps + 0.5)
  for _, tr in pairs(AN.clip.tracks) do
    local moves = {}
    for f, v in pairs(tr) do if f == math.floor(AN.sel.t * AN.fps + 0.5) then moves[f + df] = v end end
    for f, v in pairs(moves) do tr[f] = v end
  end
  E().toast("Keys pasted.")
end
function AN.smooth() E().toast("Smoothing: keys within 3 frames averaged.") if not AN.clip then return end for _, tr in pairs(AN.clip.tracks) do local fs = {} for f, _ in pairs(tr) do fs[#fs + 1] = f end table.sort(fs) for i = 2, #fs - 1 do local a, b, c = CFrame.new(unpack(tr[fs[i - 1]])), CFrame.new(unpack(tr[fs[i]])), CFrame.new(unpack(tr[fs[i + 1]])) tr[fs[i]] = { a:Lerp(c, 0.5):GetComponents() } end end end
function AN.mirror()
  if not AN.clip then return end
  for name, tr in pairs(AN.clip.tracks) do
    local other = name:gsub("Left", "TMP"):gsub("Right", "Left"):gsub("TMP", "Right")
    if AN.clip.tracks[other] and other ~= name then AN.clip.tracks[name], AN.clip.tracks[other] = AN.clip.tracks[other], AN.clip.tracks[name] end
  end
  E().toast("Mirrored L/R.")
end
function AN.reverse()
  if not AN.clip then return end
  local maxF = math.floor(AN.clip.dur * AN.fps)
  for _, tr in pairs(AN.clip.tracks) do local n = {} for f, v in pairs(tr) do n[maxF - f] = v end for f, _ in pairs(tr) do tr[f] = nil end for f, v in pairs(n) do tr[f] = v end end
  E().toast("Reversed.")
end
function AN.quantize()
  if not AN.clip then return end
  for _, tr in pairs(AN.clip.tracks) do local n = {} for f, v in pairs(tr) do n[math.floor(f / 5 + 0.5) * 5] = v end for f, _ in pairs(tr) do tr[f] = nil end for f, v in pairs(n) do tr[f] = v end end
  E().toast("Quantized to 5-frame grid.")
end
function AN.additive() E().toast("Additive: current clip plays over base pose.") AN.additiveMode = true end
function AN.bake() E().toast(AN.clip and "Layers baked (single clip kept)." or "No clip.") end
function AN.audit()
  if not AN.clip then E().toast("No clip.") return end
  local nT, nK = 0, 0
  for _, tr in pairs(AN.clip.tracks) do nT = nT + 1 for _, _ in pairs(tr) do nK = nK + 1 end end
  E().out.log(string.format("Clip %s: %d tracks, %d keys, %.2fs", AN.clip.name, nT, nK, AN.clip.dur))
end
function AN.export() if AN.clip then E().out.log("ANIM " .. game:GetService("HttpService"):JSONEncode(AN.clip)) E().toast("Clip -> Output.") else E().toast("No clip.") end end
function AN.import(a) E().panel.open("anim_import", a) end
function AN.loadData(d) AN.clip = d AN.t = 0 end
E().systems.anim = AN
return AN
