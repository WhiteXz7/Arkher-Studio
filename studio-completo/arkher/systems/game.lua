-- arkher/systems/game.lua — game rules/spawns/economy/match preview.
local G = { cfg = { friendlyFire = false, matchOn = false, econ = {} } }
local function E() return _G.ARKHER end
function G.cfgFolder()
  local f = E().store.cfgFolder()
  local g = f:FindFirstChild("game") or Instance.new("Folder") g.Name = "game" g.Parent = f
  return g
end
function G.flag(key)
  G.cfg[key] = not G.cfg[key]
  local f = G.cfgFolder()
  local v = f:FindFirstChild(key) or Instance.new("BoolValue") v.Name = key v.Parent = f
  v.Value = G.cfg[key]
  E().toast(key .. " = " .. tostring(G.cfg[key]))
end
function G.checkpoint()
  local p = Instance.new("Part") p.Name = "Checkpoint" p.Anchored = true
  p.Size = Vector3.new(6, 1, 6) p.Color = Color3.fromRGB(0, 255, 0) p.Material = Enum.Material.Neon
  p.CFrame = E().systems.camera.focusCF() p.Parent = workspace
  local t = Instance.new("IntValue") t.Name = "ARKHER_checkpoint" t.Value = 1 t.Parent = p
  E().undo.created(p) E().undo.commit("checkpoint") E().sel.set({ p })
end
function G.dialog(into)
  local parent = (into and into.Parent) or workspace
  local d = Instance.new("Dialog") d.InitialPrompt = "Hello, traveler!" d.Parent = parent
  local c = Instance.new("DialogChoice") c.Name = "Choice1" c.UserDialog = "Tell me more." c.ResponseDialog = "Good luck out there." c.Parent = d
  E().undo.created(d) E().undo.commit("dialog") E().sel.set({ d })
end
function G.leaderstats()
  local f = Instance.new("Folder") f.Name = "leaderstats" f.Parent = game:GetService("ServerStorage")
  local c = Instance.new("IntValue") c.Name = "Coins" c.Value = 0 c.Parent = f
  local k = Instance.new("IntValue") k.Name = "KOs" k.Value = 0 k.Parent = f
  E().toast("leaderstats template in ServerStorage (copy recipe to your game).")
  E().sel.set({ f })
end
function G.zone(kind)
  kind = kind or "zone"
  local z = Instance.new("Part") z.Name = "Zone_" .. kind z.Anchored = true z.CanCollide = false z.Transparency = 0.6
  z.Size = Vector3.new(30, 10, 30) z.CFrame = E().systems.camera.focusCF() z.Parent = workspace
  local t = Instance.new("StringValue") t.Name = "ARKHER_zone" t.Value = kind t.Parent = z
  E().undo.created(z) E().undo.commit("zone") E().sel.set({ z })
end
function G.listSpawns()
  local out = {}
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("SpawnLocation") then out[#out + 1] = d end end
  E().sel.set(out)
  E().toast(#out .. " spawns selected.")
end
function G.mod(op)
  local pls = game:GetService("Players"):GetPlayers()
  if op == "healall" then for _, pl in ipairs(pls) do local ch = pl.Character local h = ch and ch:FindFirstChildWhichIsA("Humanoid") if h then h.Health = h.MaxHealth end end E().toast("All healed.")
  elseif op == "resetall" then for _, pl in ipairs(pls) do if pl.Character then pl.Character:BreakJoints() end end E().toast("Characters reset.")
  elseif op == "kick" then E().toast("Kick works in Play mode with server rights; select player in Multiplayer > Players.")
  elseif op == "spectate" or op == "follow" then
    local t = pls[1]
    if t and t.Character then local hrp = t.Character:FindFirstChild("HumanoidRootPart") if hrp then workspace.CurrentCamera.CameraSubject = hrp E().toast("Spectating " .. t.Name) end
    else E().toast("No players.") end
  end
end
function G.grant() E().toast("Grant: pick player + item in Game > Shop.") E().panel.open("game_shop", {}) end
function G.wipeEcon() G.cfg.econ = {} E().toast("Preview economy wiped.") end
function G.match(op)
  if op == "start" then G.cfg.matchOn = true E().out.log("Match started (preview).")
  else G.cfg.matchOn = false E().out.log("Match finished (preview).") end
end
function G.migrate() E().out.warn("Migrate needs published places + TeleportService (see Multiplayer > Limits).") end
function G.shutdown()
  E().out.warn("Shutdown: in Play mode this kicks all players. Not executed in Edit mode (safety).")
end
function G.tick(dt) end
E().systems.game = G
return G
