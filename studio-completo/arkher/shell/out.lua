-- arkher/shell/out.lua — output buffer + problems (feeds bottom panels).
local OUT = { lines = {}, filter = "all", max = 500, subs = {}, problems = {} }
local function push(kind, msg)
  local e = { t = os.time(), kind = kind, msg = tostring(msg) }
  OUT.lines[#OUT.lines + 1] = e
  if #OUT.lines > OUT.max then table.remove(OUT.lines, 1) end
  if kind == "error" or kind == "warn" then OUT.problems[#OUT.problems + 1] = e if #OUT.problems > 200 then table.remove(OUT.problems, 1) end end
  print("[ARKHER][" .. kind .. "] " .. tostring(msg))
  for _, f in ipairs(OUT.subs) do pcall(f, e) end
end
function OUT.log(m) push("log", m) end
function OUT.warn(m) push("warn", m) end
function OUT.err(m) push("error", m) end
function OUT.sub(f) OUT.subs[#OUT.subs + 1] = f end
function OUT.clear() OUT.lines = {} OUT.problems = {} for _, f in ipairs(OUT.subs) do pcall(f, { kind = "clear" }) end end
function OUT.filter(lv) OUT.filter = lv for _, f in ipairs(OUT.subs) do pcall(f, { kind = "filter" }) end end
function OUT.save()
  local arr = {} for _, e in ipairs(OUT.lines) do arr[#arr + 1] = { t = e.t, k = e.kind, m = e.msg } end
  local j = game:GetService("HttpService"):JSONEncode(arr)
  local f = _G.ARKHER.store.cfgFolder()
  local v = f:FindFirstChild("log") or Instance.new("StringValue") v.Name = "log" v.Value = j v.Parent = f
  _G.ARKHER.toast("Log saved to project.")
end
function OUT.export() local arr = {} for _, e in ipairs(OUT.lines) do arr[#arr + 1] = e.kind .. ": " .. e.msg end _G.ARKHER.toast("Log has " .. #arr .. " lines (see Output).") OUT.log("EXPORT " .. game:GetService("HttpService"):JSONEncode(arr)) end
_G.ARKHER.out = OUT
return OUT
