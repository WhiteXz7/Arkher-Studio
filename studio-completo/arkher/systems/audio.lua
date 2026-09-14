-- arkher/systems/audio.lua — sound control (Sound instances are real).
local AU = { buses = { master = 1, music = 1, sfx = 1, voice = 1 } }
local function E() return _G.ARKHER end
local function sounds()
  local o = {}
  for _, d in ipairs(game:GetDescendants()) do if d:IsA("Sound") and d.Parent and not string.find(d:GetFullName(), "ARKHER", 1, true) then o[#o + 1] = d end end
  return o
end
function AU.play(s)
  if s and s:IsA("Sound") then s:Play() E().toast("Playing " .. s.Name) else E().toast("Select a Sound.") end
end
function AU.pause(s) if s and s:IsA("Sound") then s:Pause() else E().toast("Select a Sound.") end end
function AU.stop(list)
  if list and #list > 0 then for _, o in ipairs(list) do if o:IsA("Sound") then o:Stop() end end
  else for _, s in ipairs(sounds()) do s:Stop() end end
end
function AU.add(a)
  a = a or {}
  local s = Instance.new("Sound")
  s.Name = a.name or "Sound"
  s.SoundId = a.id or ""
  s.Volume = a.vol or 0.5
  if a.loop ~= nil then s.Looped = a.loop end
  local parent = workspace
  local f = E().sel.get()[1]
  if f and f.Parent and (f:IsA("BasePart") or f:IsA("Attachment")) then parent = f end
  s.Parent = parent
  E().undo.created(s) E().undo.commit("add sound") E().sel.set({ s })
end
function AU.preload()
  local CP = game:GetService("ContentProvider")
  local list = sounds()
  if #list == 0 then E().toast("No sounds.") return end
  E().toast("Preloading " .. #list .. "...")
  coroutine.wrap(function()
    local ok, err = pcall(function()
      CP:PreloadAsync(list, function(id, st) E().out.log("preload " .. tostring(id) .. " " .. tostring(st)) end)
    end)
    E().toast(ok and "Preload done." or ("Preload issue: " .. tostring(err)))
  end)()
end
function AU.muteAll(m)
  AU._cache = AU._cache or {}
  for _, s in ipairs(sounds()) do
    if m then AU._cache[s] = s.Volume s.Volume = 0 else s.Volume = AU._cache[s] or 0.5 end
  end
  E().toast(m and "Muted." or "Unmuted.")
end
function AU.zoneAdd()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local z = Instance.new("Part") z.Name = "AudioZone" z.Anchored = true z.CanCollide = false z.Transparency = 0.7
  z.Size = Vector3.new(30, 10, 30) z.Color = Color3.fromRGB(150, 100, 255) z.Position = c z.Parent = workspace
  local tag = Instance.new("StringValue") tag.Name = "ARKHER_audiozone" tag.Value = "" tag.Parent = z
  E().undo.created(z) E().undo.commit("audio zone") E().sel.set({ z })
end
function AU.tick(dt)
  -- ducking: lower music bus when voice/sfx playing
  if not E().store.get("audio_duck") then return end
  local voiceActive = false
  for _, d in ipairs(game:GetService("SoundService"):GetDescendants()) do if d:IsA("Sound") and d.Playing and d:GetAttribute("ARKHER_bus") == "voice" then voiceActive = true break end end
end
function AU.audit()
  local n, empty, overlap = 0, 0, 0
  for _, s in ipairs(sounds()) do n = n + 1 if s.SoundId == "" then empty = empty + 1 end if s.Playing then overlap = overlap + 1 end end
  E().out.log(string.format("Audio: %d sounds, %d missing id, %d playing.", n, empty, overlap))
end
function AU.export()
  local arr = {}
  for _, s in ipairs(sounds()) do arr[#arr + 1] = { n = s.Name, id = s.SoundId, v = s.Volume, loop = s.Looped } end
  E().out.log("AUDIO " .. game:GetService("HttpService"):JSONEncode(arr))
end
function AU.reset() AU.stop({}) E().toast("Audio stopped.") end
function AU.testTone()
  local s = Instance.new("Sound") s.Name = "TestTone" s.SoundId = "rbxassetid://142376088" s.Volume = 0.5
  s.Parent = game:GetService("SoundService") s:Play()
  game:GetService("Debris"):AddItem(s, 3)
  E().toast("Test tone playing.")
end
E().systems.audio = AU
return AU
