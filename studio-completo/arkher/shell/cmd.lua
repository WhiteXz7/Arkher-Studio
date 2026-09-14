-- arkher/shell/cmd.lua — command dispatch + history + favorites + repeat.
local CMD = { history = {}, favs = {}, last = nil }
local REG
function CMD.init(reg) REG = reg
  local f = game:GetService("ServerStorage"):FindFirstChild("ARKHER_cfg")
  local v = f and f:FindFirstChild("cmdfav")
  if v and v.Value ~= "" then pcall(function() CMD.favs = game:GetService("HttpService"):JSONDecode(v.Value) end) end
end
function CMD.run(id, argOverride)
  local c = REG and REG.byId[id]
  if not c then _G.ARKHER.out.err("Unknown command: " .. tostring(id)) return false end
  local fn = _G.ARKHER.ACTIONS[c.act]
  if not fn then _G.ARKHER.out.err("Unimplemented act: " .. tostring(c.act)) return false end
  local arg = argOverride or c.arg or {}
  local t0 = os.clock()
  local ok, err = pcall(fn, c, arg)
  local dt = (os.clock() - t0) * 1000
  CMD.last = { id = id, arg = arg }
  CMD.history[#CMD.history + 1] = { id = id, ms = math.floor(dt), ok = ok }
  if #CMD.history > 100 then table.remove(CMD.history, 1) end
  -- behavior A: act always runs; panel (if any) opens too
  if c.panel then _G.ARKHER.panel.open(c.panel, { cmd = id }) end
  if not ok then _G.ARKHER.out.err("cmd " .. id .. ": " .. tostring(err)) return false end
  if _G.ARKHER.store.get("verbose") then _G.ARKHER.out.log(id .. " ok (" .. string.format("%.1f", dt) .. "ms)") end
  return true
end
function CMD.done(label)
  local ok, CHS = pcall(game.GetService, game, "ChangeHistoryService")
  if ok and CHS then pcall(function() CHS:SetWaypoint(label or "arkher") end) end
end
function CMD.repeatLast() if CMD.last then CMD.run(CMD.last.id, CMD.last.arg) else _G.ARKHER.toast("Nothing to repeat.") end end
function CMD.toggleFav(id)
  CMD.favs[id] = not CMD.favs[id] or nil
  if CMD.favs[id] == false then CMD.favs[id] = nil end
  local f = _G.ARKHER.store.cfgFolder()
  local v = f:FindFirstChild("cmdfav") or Instance.new("StringValue") v.Name = "cmdfav"
  v.Value = game:GetService("HttpService"):JSONEncode(CMD.favs) v.Parent = f
end
function CMD.isFav(id) return CMD.favs[id] == true end
_G.ARKHER.cmd = CMD
return CMD
