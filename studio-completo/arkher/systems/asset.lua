-- arkher/systems/asset.lua — asset insert/verify (InsertService, honest limits).
local AS = { reg = {} }
local function E() return _G.ARKHER end
function AS.insert(a)
  a = a or {}
  local id = tonumber(a.id or 0)
  if not id or id <= 0 then E().panel.open("asset_insert", a) return end
  local ok, m = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
  if ok and m then
    m.Parent = workspace
    E().undo.created(m) E().undo.commit("insert asset")
    E().sel.set({ m })
  else
    E().out.err("Insert failed for " .. id .. " (moderation/permissions?).")
  end
end
function AS.verify()
  local ids = {}
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Sound") and d.SoundId ~= "" then ids[#ids + 1] = d.SoundId end
    if (d:IsA("Decal") or d:IsA("Texture")) and d.Texture ~= "" then ids[#ids + 1] = d.Texture end
    if d:IsA("MeshPart") and d.MeshId ~= "" then ids[#ids + 1] = d.MeshId end
  end
  E().out.log("Verify: " .. #ids .. " asset references found.")
  local CP = game:GetService("ContentProvider")
  coroutine.wrap(function()
    local bad = 0
    for _, id in ipairs(ids) do
      local st = nil
      pcall(function() st = CP:GetAssetFetchStatus(id) end)
      if st and tostring(st):find("Failure") then bad = bad + 1 E().out.warn("failed: " .. id) end
    end
    E().toast("Verify done: " .. bad .. " failures.")
  end)()
end
function AS.preload()
  local inst = {}
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Sound") or d:IsA("Decal") or d:IsA("MeshPart") then inst[#inst + 1] = d end end
  if #inst == 0 then E().toast("Nothing to preload.") return end
  coroutine.wrap(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync(inst) end) E().toast("Preloaded " .. #inst .. ".") end)()
end
function AS.missing()
  local n = 0
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Sound") and d.SoundId == "" then n = n + 1
    elseif (d:IsA("Decal") or d:IsA("Texture")) and d.Texture == "" then n = n + 1
    elseif d:IsA("MeshPart") and d.MeshId == "" then n = n + 1 end
  end
  E().out.log("Missing asset ids: " .. n)
end
function AS.audit() AS.verify() AS.missing() end
function AS.dupfind()
  local seen, dups = {}, 0
  for _, d in ipairs(workspace:GetDescendants()) do
    local id = d:IsA("Sound") and d.SoundId or ((d:IsA("Decal") or d:IsA("Texture")) and d.Texture or nil)
    if id and id ~= "" then if seen[id] then dups = dups + 1 else seen[id] = true end end
  end
  E().out.log("Duplicate asset refs: " .. dups)
end
function AS.export()
  local arr = {}
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Sound") and d.SoundId ~= "" then arr[#arr + 1] = { t = "sound", id = d.SoundId }
    elseif d:IsA("MeshPart") and d.MeshId ~= "" then arr[#arr + 1] = { t = "mesh", id = d.MeshId } end
  end
  E().out.log("ASSETS " .. game:GetService("HttpService"):JSONEncode(arr))
end
function AS.import(a) E().panel.open("asset_import", a) end
function AS.archive() E().toast("Archive: unused assets listed in Assets > Packs.") E().panel.open("asset_packs", {}) end
function AS.restore(a) E().panel.open("asset_restore", a or {}) end
E().systems.asset = AS
return AS
