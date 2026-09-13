-- 18_Do15 (R15a) — D-O15: otimizacao real (stats/audit/optimize/relevance/memoria).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime")
local clientBus = rt:WaitForChild("ClientBus")
local function find(n) return shell:FindFirstChild(n, true) end
local function vis(n, v) local o = find(n) if o then pcall(function() o.Visible = v end) end end
local function setText(n, t) local o = find(n) if o then pcall(function() o.Text = t end) end end
local function say(t, bad)
  pcall(function() clientBus:Invoke("Message", { text = tostring(t), bad = bad == true }) end)
end
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  if type(r) == "table" and r.result ~= nil then return r.result end
  return r
end
local function on(n, fn)
  local o = find(n)
  if o and o.Activated then o.Activated:Connect(function() pcall(fn) end) end
end
local PANELS = { "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status" }
local DESK = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status",
  "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status" }
local OTHER_M = { "M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO" }
local S = { open = false, kinds = { Light = true, Emitter = true, Decal = false, Sound = false },
  radius = 150, grpId = nil, grpName = "-", anchorArm = false }
local ACC = Color3.fromRGB(43, 139, 230)
local DIM = Color3.fromRGB(28, 42, 72)
local function platform()
  local ok, ai = pcall(function() return _G.ArkherInput end)
  if ok and ai and ai.platform then
    local ok2, p = pcall(ai.platform)
    if ok2 and p then return p end
  end
  return "PC"
end
local refreshStats, refreshRels
local function setOpen(v)
  S.open = v
  for _, n in ipairs(PANELS) do vis(n, v) end
  for _, n in ipairs(DESK) do vis(n, not v) end
  if v then
    for _, n in ipairs(OTHER_EDS) do vis(n, false) end
    for _, n in ipairs(OTHER_M) do vis(n, false) end
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherWorld" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    vis("M_DO", platform() == "Mobile")
    refreshStats()
    refreshRels()
    say("D-O15 open.")
  else
    vis("M_DO", false)
    say("D-O15 closed.")
  end
end

-- ============ stats ============
refreshStats = function()
  local st, err = api("Do15Stats", {})
  if err then say("Stats: " .. tostring(err), true) return end
  local stream = "n/a"
  if st.streaming ~= nil then
    stream = (st.streaming and "on" or "off") .. (st.targetRadius and ("/" .. st.targetRadius) or "")
  end
  setText("DO8_StatBig", string.format("fps %.1f · lua %s KB\nparts %s · inst %s · tris %s\ndraw %s · net %s/%s kbps\nstream %s · g %s",
    st.fps or 0, tostring(st.luaKb or "-"), tostring(st.parts or "-"),
    tostring(st.instances or "-"), tostring(st.tris or "-"),
    tostring(st.drawcalls or "-"), tostring(st.recvKbps or "-"), tostring(st.sendKbps or "-"),
    stream, tostring(st.gravity or "-")))
  setText("DO8_StatL", string.format("fps %.1f · mem %s MB · parts %s · tris %s",
    st.fps or 0, tostring(st.memMb or "-"), tostring(st.parts or "-"), tostring(st.tris or "-")))
  setText("DO8_M_Info", string.format("lua %s KB · total %s MB", tostring(st.luaKb or "-"), tostring(st.memMb or "-")))
end
local statT = 0
Run.Heartbeat:Connect(function(dt)
  if not S.open then return end
  statT = statT + (dt or 0)
  if statT >= 2 then statT = 0 pcall(refreshStats) end
end)
on("DO8_S_Refresh", refreshStats)
on("DO8_S_Report", function()
  local r, err = api("Do15Report", {})
  if err then say("Report: " .. tostring(err), true) return end
  print("[ArkherDO15] report:\n" .. (r.json or "{}"))
  say(string.format("Report in Output (%s bytes).", tostring(r.bytes or 0)))
end)

-- ============ audit ============
local function runAudit()
  local a, err = api("Do15Audit", {})
  if err then say("Audit: " .. tostring(err), true) return end
  local tops = {}
  for _, t in ipairs(a.topMats or {}) do tops[#tops + 1] = t.mat .. " " .. t.n end
  setText("DO8_AuditBig", string.format("parts %d · unanch %d\ntouch %d · shadow %d · transp %d\nscripts %d · snd %d · dec %d\n%s",
    a.parts or 0, a.unanchored or 0, a.cantouch or 0, a.castshadow or 0,
    a.transparent or 0, a.scripts or 0, a.sounds or 0, a.decals or 0,
    (#tops > 0 and ("top: " .. table.concat(tops, ", "):sub(1, 60))) or "top: -"))
  say(string.format("Audit: %d parts.", a.parts or 0))
end
on("DO8_A_Scan", runAudit)
on("DO8_Scan", runAudit)

-- ============ optimize ============
local function runOpt(ops, confirm)
  local r, err = api("Do15Optimize", { ops = ops, confirm = confirm })
  if err then say("Optimize: " .. tostring(err), true) return end
  local c = r.changed or {}
  setText("DO8_O_Info", string.format("touch %d · shadow %d · anchor %d\nskip %d%s",
    c.notouch or 0, c.noshadow or 0, c.anchor or 0, r.skipped or 0,
    r.truncated and " · TRUNC" or ""))
  say("Optimized. (Undo available.)")
  runAudit()
end
on("DO8_O_Touch", function() runOpt({ "notouch" }) end)
on("DO8_O_Shadow", function() runOpt({ "noshadow" }) end)
on("DO8_O_Anchor", function()
  if not S.anchorArm then
    S.anchorArm = true
    setText("DO8_O_Info", "ANCHOR changes physics.\nclick again to confirm.")
    say("Anchor: click again to confirm.", true)
    return
  end
  S.anchorArm = false
  runOpt({ "anchor" }, true)
end)
on("DO8_O_Undo", function()
  local r, err = api("Undo", {})
  if err then say("Undo: " .. tostring(err), true) return end
  say("Undid: " .. tostring(r.label or "?"))
  runAudit()
end)

-- ============ relevance ============
local function idOf(o)
  local r, err = api("Identify", { object = o })
  if err then return nil end
  return r and r.id
end
refreshRels = function()
  local r, err = api("Do15Relevance", { op = "list" })
  if err then return end
  local names = {}
  for _, g in ipairs(r.groups or {}) do
    names[#names + 1] = g.name .. (g.on and "*" or "o")
  end
  setText("DO8_R_Info", (#names > 0 and ("groups: " .. table.concat(names, ", "):sub(1, 60)))
    or "select model/folder, +grp")
end
on("DO8_R_Add", function()
  local sv = rt:FindFirstChild("SelectedInstance")
  local v = sv and sv.Value
  if not v or (v.ClassName ~= "Model" and v.ClassName ~= "Folder") then
    say("Group: select a Model/Folder first (Viewport).", true)
    return
  end
  local id = idOf(v)
  if not id then say("Group: identify failed.", true) return end
  S.grpId = id
  S.grpName = v.Name
  setText("DO8_R_Info", "staged: " .. v.Name)
  say("Staged " .. v.Name .. ".")
end)
on("DO8_R_RM", function()
  S.radius = math.clamp(S.radius - 50, 10, 5000)
  setText("DO8_R_RV", tostring(S.radius))
end)
on("DO8_R_RP", function()
  S.radius = math.clamp(S.radius + 50, 10, 5000)
  setText("DO8_R_RV", tostring(S.radius))
end)
local function paintKinds()
  local map = { Light = "DO8_R_KLight", Emitter = "DO8_R_KEmit",
    Decal = "DO8_R_KDecal", Sound = "DO8_R_KSnd" }
  for k, n in pairs(map) do
    local o = find(n)
    if o then pcall(function() o.BackgroundColor3 = S.kinds[k] and ACC or DIM end) end
  end
end
for _, k in ipairs({ "Light", "Emitter", "Decal", "Sound" }) do
  local kk = k
  local nm = "DO8_R_K" .. (kk == "Light" and "Light" or kk == "Emitter" and "Emit"
    or kk == "Decal" and "Decal" or "Snd")
  on(nm, function()
    S.kinds[kk] = not S.kinds[kk]
    paintKinds()
  end)
end
on("DO8_R_Reg", function()
  local name = ""
  pcall(function() name = find("DO8_R_Name").Text or "" end)
  if name == "" then say("Register: name the group.", true) return end
  if not S.grpId then say("Register: +grp first.", true) return end
  local kinds = {}
  for k, v in pairs(S.kinds) do if v then kinds[#kinds + 1] = k end end
  if #kinds == 0 then say("Register: pick a kind.", true) return end
  local r, err = api("Do15Relevance", { op = "register", name = name,
    id = S.grpId, radius = S.radius, kinds = kinds })
  if err then say("Register: " .. tostring(err), true) return end
  S.grpId, S.grpName = nil, "-"
  say(string.format("Relevance %s live (%d items).", name, r.items or 0))
  refreshRels()
end)
on("DO8_R_Del", function()
  local name = ""
  pcall(function() name = find("DO8_R_Name").Text or "" end)
  if name == "" then say("Remove: name the group.", true) return end
  local r, err = api("Do15Relevance", { op = "remove", name = name })
  if err then say("Remove: " .. tostring(err), true) return end
  say("Relevance " .. name .. " removed.")
  refreshRels()
end)

-- ============ memory ============
on("DO8_M_GC", function()
  local r, err = api("Do15Gc", {})
  if err then say("GC: " .. tostring(err), true) return end
  setText("DO8_M_Info", string.format("lua %d->%d KB\nfreed %d KB",
    r.beforeKb or 0, r.afterKb or 0, r.freedKb or 0))
  say("GC done.")
end)
on("DO8_M_Pre", function()
  local txt = ""
  pcall(function() txt = find("DO8_M_Ids").Text or "" end)
  local ids = {}
  for raw in txt:gmatch("([^,]+)") do
    local id = raw:match("^%s*(.-)%s*$")
    if id ~= "" then ids[#ids + 1] = id end
  end
  if #ids == 0 then say("Preload: paste ids.", true) return end
  local r, err = api("Do15Preload", { ids = ids })
  if err then say("Preload: " .. tostring(err), true) return end
  setText("DO8_M_Info", string.format("preload %d ok %d fail\n%d ms",
    r.loaded or 0, r.failed or 0, r.ms or 0))
  say("Preload done.")
end)

-- ============ mobile strip ============
on("M_DO_Scan", runAudit)
on("M_DO_Opt", function() runOpt({ "notouch", "noshadow" }) end)
on("M_DO_GC", function()
  local r, err = api("Do15Gc", {})
  if err then say("GC: " .. tostring(err), true) return end
  say(string.format("GC: freed %d KB.", r.freedKb or 0))
end)

-- ============ boot ============
paintKinds()
setText("DO8_R_RV", tostring(S.radius))
on("DO8_Close", function() setOpen(false) end)
rawset(_G, "ArkherDo15", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
