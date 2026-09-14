-- arkher/systems/cut.lua — cutscene sequences (shots, camera tracks, dialog, audio cues).
local CU = { seq = nil, playing = false, t = 0, shot = 1, recCam = nil }
local function E() return _G.ARKHER end
function CU.new(a)
  a = a or {}
  CU.seq = { name = a.name or "Scene1", shots = {}, dur = 0 }
  CU.t, CU.shot, CU.playing = 0, 1, false
  E().toast("Cutscene created.")
end
function CU.addShot()
  if not CU.seq then E().toast("Create a scene first.") return end
  local cam = workspace.CurrentCamera
  CU.seq.shots[#CU.seq.shots + 1] = { cf = { cam.CFrame:GetComponents() }, dur = 3, fov = cam.FieldOfView, dialog = "", music = "" }
  CU.seq.dur = CU.seq.dur + 3
  E().toast("Shot " .. #CU.seq.shots .. " added.")
end
function CU.dupShot()
  if not (CU.seq and CU.seq.shots[CU.shot]) then E().toast("No shot.") return end
  local s = CU.seq.shots[CU.shot]
  CU.seq.shots[#CU.seq.shots + 1] = { cf = s.cf, dur = s.dur, fov = s.fov, dialog = s.dialog, music = s.music }
  CU.seq.dur = CU.seq.dur + s.dur
end
function CU.camAdd()
  if not CU.seq then E().toast("No scene.") return end
  local s = CU.seq.shots[CU.shot]
  if not s then E().toast("No shot.") return end
  local cam = workspace.CurrentCamera
  s.cf2 = { cam.CFrame:GetComponents() }
  E().toast("Camera end-key set (dolly).")
end
function CU.camGoto()
  if not (CU.seq and CU.seq.shots[CU.shot]) then E().toast("No shot.") return end
  workspace.CurrentCamera.CFrame = CFrame.new(unpack(CU.seq.shots[CU.shot].cf))
end
function CU.play()
  if not (CU.seq and #CU.seq.shots > 0) then E().toast("Add shots first.") return end
  CU.playing = true
  if E().store.get("cut_letterbox") then E().shell.letterbox(true) end
end
function CU.pause() CU.playing = false end
function CU.stop() CU.playing = false CU.t, CU.shot = 0, 1 E().shell.letterbox(false) end
function CU.tick(dt)
  if not (CU.playing and CU.seq) then return end
  local s = CU.seq.shots[CU.shot]
  if not s then CU.stop() return end
  CU.t = CU.t + dt
  local cam = workspace.CurrentCamera
  local c0 = CFrame.new(unpack(s.cf))
  if s.cf2 then local c1 = CFrame.new(unpack(s.cf2)) cam.CFrame = c0:Lerp(c1, math.min(1, CU.t / s.dur)) else cam.CFrame = c0 end
  cam.FieldOfView = s.fov or 70
  if s.dialog ~= "" then E().shell.subtitle(s.dialog) end
  if CU.t >= s.dur then
    CU.t = 0 CU.shot = CU.shot + 1
    if CU.shot > #CU.seq.shots then CU.stop() E().toast("Cutscene finished.") end
  end
end
function CU.recordCam()
  if CU.recCam then
    local keys = CU.recCam CU.recCam = nil
    if CU.seq and CU.seq.shots[CU.shot] then CU.seq.shots[CU.shot].camkeys = keys E().toast("Recorded " .. #keys .. " cam keys.") end
    return
  end
  CU.recCam = {}
  E().toast("Recording camera... click again to stop.")
  E().sim.addLoop(function()
    if CU.recCam then local cam = workspace.CurrentCamera CU.recCam[#CU.recCam + 1] = { cam.CFrame:GetComponents() } end
  end)
end
function CU.preview()
  if not CU.seq then E().toast("No scene.") return end
  E().shell.focusmode()
  CU.t, CU.shot = 0, 1
  CU.play()
end
function CU.export() if CU.seq then E().out.log("CUT " .. game:GetService("HttpService"):JSONEncode(CU.seq)) E().toast("Sequence -> Output.") else E().toast("No scene.") end end
function CU.import(a) E().panel.open("cut_import", a) end
function CU.loadData(d) CU.seq = d CU.t, CU.shot = 0, 1 end
E().systems.cut = CU
return CU
