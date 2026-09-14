-- arkher/util.lua — helpers puros (sem Dependencias Roblox alem de tipos).
local U = {}
function U.clamp(v, a, b) if v < a then return a end if v > b then return b end return v end
function U.split(s, sep)
  local t = {}
  for part in tostring(s):gmatch("[^" .. sep .. "]+") do t[#t + 1] = part end
  return t
end
function U.trim(s) return tostring(s):match("^%s*(.-)%s*$") end
function U.deepCopy(o)
  if type(o) ~= "table" then return o end
  local c = {}
  for k, v in pairs(o) do c[U.deepCopy(k)] = U.deepCopy(v) end
  return c
end
function U.keys(t)
  local k = {}
  for key in pairs(t) do k[#k + 1] = key end
  table.sort(k, function(a, b) return tostring(a) < tostring(b) end)
  return k
end
function U.startsWith(s, p) return tostring(s):sub(1, #p) == p end
-- numero seguro p/ campos numericos (nil quando invalido).
function U.num(s)
  local n = tonumber(U.trim(s))
  return n
end
-- pcall que retorna (ok, valorOuErroString).
function U.guard(fn, ...)
  local r = { pcall(fn, ...) }
  if r[1] then return true, r[2] end
  return false, tostring(r[2])
end
return U
