-- arkher/systems/ai.lua — AI director state + pathfinding tests + squads.
local AI = { on = true, paused = {}, log = {} }
local function E() return _G.ARKHER end
function AI.enable(v) AI.on = v E().toast("AI " .. (v and "enabled" or "disabled") .. ".") end
function AI.findPath()
  local PFS = game:GetService("PathfindingService")
  local sel = E().sel.get()
  if #sel < 1 then E().toast("Select the agent.") return end
  local m = sel[1]
  local hrp = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart"))
  if not hrp then E().toast("Select a Model agent.") return end
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  if not hit then E().toast("Aim at destination.") return end
  local ok, path = pcall(function() return PFS:CreatePath() end)
  if not ok then E().toast("Pathfinding unavailable.") return end
  local ok2, err = pcall(function() path:ComputeAsync(hrp.Position, hit.Position) end)
  if ok2 and path.Status == Enum.PathStatus.Success then
    local pts = path:GetWaypoints()
    E().out.log("Path: " .. #pts .. " waypoints.")
    local h = m:FindFirstChildWhichIsA("Humanoid")
    if h then for _, w in ipairs(pts) do h:MoveTo(w.Position) h.MoveToFinished:Wait() end end
  else
    E().out.warn("No path: " .. tostring(err or path and path.Status))
  end
end
function AI.possess(m)
  if not (m and m:IsA("Model")) then E().toast("Select an agent.") return end
  AI.paused[m] = true
  E().toast("Possessed " .. m.Name .. " (brain paused; move it manually).")
end
function AI.killAll()
  local n = 0
  for m, _ in pairs(E().systems.npc.brains) do if m and m.Parent then m:Destroy() n = n + 1 end end
  E().systems.npc.brains = {}
  E().toast(n .. " agents removed.")
end
function AI.pauseOne(m, p)
  if not (m and m:IsA("Model")) then E().toast("Select an agent.") return end
  if p then AI.paused[m] = true else AI.paused[m] = nil end
  E().toast(m.Name .. (p and " paused." or " resumed."))
end
function AI.sendTo(m)
  if not (m and m:IsA("Model")) then E().toast("Select an agent.") return end
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  if not hit then E().toast("Aim at destination.") return end
  local h = m:FindFirstChildWhichIsA("Humanoid")
  if h then h:MoveTo(hit.Position) E().toast("Sent.") else E().toast("No humanoid.") end
end
function AI.stimulus(a)
  a = a or {}
  AI.log[#AI.log + 1] = { t = os.time(), kind = a.kind or "noise", pos = "cursor" }
  E().out.log("Stimulus: " .. (a.kind or "noise"))
end
function AI.tick(dt)
  if not AI.on then return end
  -- director heartbeat: respawn timers, wave logic hooks live in game system
end
function AI.resetActors() E().systems.npc.resetAll() end
function AI.reset() AI.log = {} AI.paused = {} E().toast("AI director reset.") end
function AI.audit()
  local stuck = 0
  for m, _ in pairs(E().systems.npc.brains) do if m and m.Parent then local h = m:FindFirstChildWhichIsA("Humanoid") if h and h.Health <= 0 then stuck = stuck + 1 end end end
  E().out.log("AI audit: " .. stuck .. " dead/stuck agents.")
end
function AI.export() E().out.log("AI " .. game:GetService("HttpService"):JSONEncode({ on = AI.on, log = #AI.log })) end
function AI.import(a) E().panel.open("ai_import", a) end
E().systems.ai = AI
return AI
