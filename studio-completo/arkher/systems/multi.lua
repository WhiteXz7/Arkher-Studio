-- arkher/systems/multi.lua — multiplayer helpers (honest Edit-mode limits).
local MU = { muted = {} }
local function E() return _G.ARKHER end
function MU.announce(text)
  text = text or "Announcement"
  for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
    pcall(function()
      local pg = pl:FindFirstChildWhichIsA("PlayerGui")
      if pg then local g = Instance.new("Message") g.Text = text g.Parent = pg game:GetService("Debris"):AddItem(g, 4) end
    end)
  end
  E().out.log("Announced: " .. text)
end
function MU.mute()
  local f = E().sel.get()[1]
  E().toast("Mute applies in Play mode via chat panel (see Multiplayer > Chat Setup).")
end
function MU.ping()
  local t0 = os.clock()
  E().bridge.call("ping", {}, function(ok) E().out.log(string.format("Ping: %.1fms (%s)", (os.clock() - t0) * 1000, ok and "local" or "fail")) end)
end
function MU.stress(a)
  a = a or {}
  E().systems.test.bots({ count = math.min(20, a.bots or 8) })
  E().store.set("net_latency", a.latency or 100)
  E().toast("Stress: bots + latency " .. tostring(E().store.get("net_latency")) .. "ms.")
end
function MU.desync()
  E().out.log("Desync check: preview sim is single-context; no desync possible in Edit mode. (Play-mode desync tools in Multiplayer > Test.)")
end
function MU.audit()
  local remotes = 0
  for _, d in ipairs(game:GetDescendants()) do if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then remotes = remotes + 1 end end
  E().out.log("Net audit: " .. remotes .. " remotes, " .. #game:GetService("Players"):GetPlayers() .. " players.")
end
function MU.savecfg()
  E().store.save()
  E().toast("Net config saved.")
end
function MU.loadcfg(a) E().panel.open("multi_loadcfg", a or {}) end
function MU.reset()
  E().store.set("net_latency", 0)
  E().store.set("net_frozen", false)
  E().toast("Net sim reset.")
end
E().systems.multi = MU
return MU
