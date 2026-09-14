-- arkher/shell/sim.lua — preview simulation: play/pause/stop/step, timescale, record/replay.
local SIM = { playing = false, paused = false, t = 0, speed = 1, rec = false, events = {}, conn = nil, loops = {} }
function SIM.play()
  if SIM.playing and SIM.paused then SIM.paused = false _G.ARKHER.toast("Resumed.") return end
  if SIM.playing then return end
  SIM.playing, SIM.paused, SIM.t = true, false, 0
  _G.ARKHER.out.log("Preview play started.")
  if not SIM.conn then
    SIM.conn = game:GetService("RunService").Heartbeat:Connect(function(dt) SIM.tick(dt) end)
  end
end
function SIM.pause() if SIM.playing then SIM.paused = not SIM.paused _G.ARKHER.toast(SIM.paused and "Paused." or "Resumed.") end end
function SIM.stop() SIM.playing, SIM.paused = false, false SIM.resetActors() _G.ARKHER.out.log("Preview stopped.") end
function SIM.restart() SIM.stop() SIM.play() end
function SIM.step() if SIM.playing and SIM.paused then SIM.tick(1 / 60) end end
function SIM.resetActors()
  local sys = _G.ARKHER.systems
  if sys.npc and sys.npc.resetAll then pcall(sys.npc.resetAll) end
  if sys.ai and sys.ai.resetActors then pcall(sys.ai.resetActors) end
  SIM.t = 0
end
function SIM.tick(dt)
  if not SIM.playing or SIM.paused then return end
  local sdt = dt * (tonumber(_G.ARKHER.store.get("sim_speed")) or 1)
  SIM.t = SIM.t + sdt
  local sys = _G.ARKHER.systems
  if sys.npc and sys.npc.tick then pcall(sys.npc.tick, sdt) end
  if sys.ai and sys.ai.tick then pcall(sys.ai.tick, sdt) end
  if sys.cut and sys.cut.tick then pcall(sys.cut.tick, sdt) end
  if sys.anim and sys.anim.tick then pcall(sys.anim.tick, sdt) end
  if sys.env and sys.env.tick then pcall(sys.env.tick, sdt) end
  if sys.audio and sys.audio.tick then pcall(sys.audio.tick, sdt) end
  if sys.game and sys.game.tick then pcall(sys.game.tick, sdt) end
  if sys.fx and sys.fx.tick then pcall(sys.fx.tick, sdt) end
  if sys.script and sys.script.tick then pcall(sys.script.tick, sdt) end
  if sys.test and sys.test.tick then pcall(sys.test.tick, sdt) end
  for _, l in ipairs(SIM.loops) do pcall(l, sdt) end
  if SIM.rec then SIM.events[#SIM.events + 1] = { t = SIM.t } end
end
function SIM.addLoop(f) SIM.loops[#SIM.loops + 1] = f end
function SIM.record(on) SIM.rec = on if on then SIM.events = {} end _G.ARKHER.toast(on and "Recording." or ("Recorded " .. #SIM.events .. " ticks.")) end
function SIM.replay()
  if #SIM.events == 0 then _G.ARKHER.toast("Nothing recorded.") return end
  SIM.play()
  _G.ARKHER.out.log("Replaying " .. #SIM.events .. " ticks of events.")
end
_G.ARKHER.sim = SIM
return SIM
