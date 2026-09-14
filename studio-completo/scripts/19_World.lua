-- 19_World (R15b) — World: info/gravidade/spawns/saves/limpeza (mundo real).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
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
local PANELS = { "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status",
  "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status",
  "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local DESK = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel",
  "O2_Crumb", "O2_Compass", "O2_Coords", "O2_Play",
  "O2_Layers", "O2_Region", "O2_Map", "O2_Gizmo", "FR2_Help" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status",
  "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status" }
local OTHER_M = { "M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO", "M_HO", "M_SC", "M_PL" }
local S = { open = false, grav = 196.2, spawns = {}, spIdx = 0,
  saves = {}, svIdx = 0, clearArm = false, delArm = false, svDelArm = false }
local function platform()
  local ok, ai = pcall(function() return _G.ArkherInput end)
  if ok and ai and ai.platform then
    local ok2, p = pcall(ai.platform)
    if ok2 and p then return p end
  end
  return "PC"
end
local refreshInfo, refreshSpawns, refreshSaves
local function setOpen(v)
  S.open = v
  for _, n in ipairs(PANELS) do vis(n, v) end
  for _, n in ipairs(DESK) do vis(n, not v) end
  if v then
    for _, n in ipairs(OTHER_EDS) do vis(n, false) end
    for _, n in ipairs(OTHER_M) do vis(n, false) end
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherHome", "ArkherScript", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    vis("M_WO", platform() == "Mobile")
    refreshInfo()
    refreshSpawns()
    refreshSaves()
    say("World open.")
  else
    vis("M_WO", false)
    say("World closed.")
  end
end

-- ============ info ============
refreshInfo = function()
  local w, err = api("WorldInfo", {})
  if err then say("Info: " .. tostring(err), true) return end
  local bnd = "-"
  if w.bounds then
    bnd = string.format("(%.0f,%.0f,%.0f)-(%.0f,%.0f,%.0f)",
      w.bounds[1], w.bounds[2], w.bounds[3], w.bounds[4], w.bounds[5], w.bounds[6])
  end
  local stream = "n/a"
  if w.streaming ~= nil then stream = w.streaming and "on" or "off" end
  setText("WO9_InfoBig", string.format("parts %d · models %d\nscripts %d · spawns %d\nsaves %d · trash %d\ngrav %s · killY %s\nstream %s\n%s",
    w.parts or 0, w.models or 0, w.scripts or 0, w.spawns or 0,
    w.saves or 0, w.trash or 0, tostring(w.gravity or "-"),
    tostring(w.killY or "-"), stream, bnd))
  setText("WO9_StatL", string.format("parts %d · spawns %d · saves %d · trash %d",
    w.parts or 0, w.spawns or 0, w.saves or 0, w.trash or 0))
  setText("WO9_G_Info", string.format("killY %s · stream %s",
    tostring(w.killY or "-"), stream))
  setText("WO9_C_Info", string.format("trash %d (+autosafe)", w.trash or 0))
  if w.gravity then
    S.grav = w.gravity
    setText("WO9_GV", tostring(w.gravity))
  end
end
on("WO9_I_Refresh", refreshInfo)

-- ============ gravity ============
on("WO9_G_M", function()
  S.grav = math.clamp(S.grav - 10, 0, 500)
  setText("WO9_GV", tostring(S.grav))
end)
on("WO9_G_P", function()
  S.grav = math.clamp(S.grav + 10, 0, 500)
  setText("WO9_GV", tostring(S.grav))
end)
on("WO9_G_Set", function()
  local r, err = api("WorldGravity", { g = S.grav })
  if err then say("Gravity: " .. tostring(err), true) return end
  S.grav = r.g
  setText("WO9_GV", tostring(r.g))
  say("Gravity " .. tostring(r.g) .. ".")
end)
on("WO9_G_Reset", function()
  local r, err = api("WorldGravity", { g = 196.2 })
  if err then say("Gravity: " .. tostring(err), true) return end
  S.grav = r.g
  setText("WO9_GV", tostring(r.g))
  say("Gravity back to Earth.")
end)

-- ============ spawns ============
local function showSpawn()
  local sp = S.spawns[S.spIdx]
  if not sp then
    setText("WO9_S_Info", "no spawns")
    return
  end
  setText("WO9_S_Info", string.format("%s · %s · %s\n%.0f, %.0f, %.0f",
    sp.name, sp.enabled and "ON" or "OFF", sp.neutral and "neutral" or "team",
    sp.pos[1], sp.pos[2], sp.pos[3]))
end
refreshSpawns = function()
  local r, err = api("WorldSpawn", { op = "list" })
  if err then say("Spawns: " .. tostring(err), true) return end
  S.spawns = r.spawns or {}
  if S.spIdx > #S.spawns then S.spIdx = #S.spawns end
  if S.spIdx == 0 and #S.spawns > 0 then S.spIdx = 1 end
  showSpawn()
end
on("WO9_S_Prev", function()
  if #S.spawns == 0 then return end
  S.spIdx = ((S.spIdx - 2) % #S.spawns) + 1
  showSpawn()
end)
on("WO9_S_Next", function()
  if #S.spawns == 0 then return end
  S.spIdx = (S.spIdx % #S.spawns) + 1
  showSpawn()
end)
on("WO9_S_Add", function()
  local r, err = api("WorldSpawn", { op = "add" })
  if err then say("Spawn: " .. tostring(err), true) return end
  say("Spawn added (at you).")
  refreshSpawns()
  refreshInfo()
end)
on("WO9_S_Toggle", function()
  local sp = S.spawns[S.spIdx]
  if not sp then say("Toggle: no spawn.", true) return end
  local r, err = api("WorldSpawn", { op = "toggle", id = sp.id })
  if err then say("Toggle: " .. tostring(err), true) return end
  sp.enabled = r.enabled
  showSpawn()
end)
on("WO9_S_Del", function()
  local sp = S.spawns[S.spIdx]
  if not sp then say("Del: no spawn.", true) return end
  if not S.delArm then
    S.delArm = true
    say("Del spawn: click again.", true)
    return
  end
  S.delArm = false
  local r, err = api("WorldSpawn", { op = "remove", id = sp.id })
  if err then say("Del: " .. tostring(err), true) return end
  say("Spawn removed.")
  refreshSpawns()
  refreshInfo()
end)

-- ============ saves ============
local function showSave()
  local sv = S.saves[S.svIdx]
  if not sv then
    setText("WO9_V_Info", "no saves")
    return
  end
  setText("WO9_V_Info", string.format("%s · %d items", sv.name, sv.items or 0))
end
refreshSaves = function()
  local r, err = api("WorldSave", { op = "list" })
  if err then say("Saves: " .. tostring(err), true) return end
  S.saves = r.saves or {}
  if S.svIdx > #S.saves then S.svIdx = #S.saves end
  if S.svIdx == 0 and #S.saves > 0 then S.svIdx = 1 end
  showSave()
end
on("WO9_V_Prev", function()
  if #S.saves == 0 then return end
  S.svIdx = ((S.svIdx - 2) % #S.saves) + 1
  showSave()
end)
on("WO9_V_Next", function()
  if #S.saves == 0 then return end
  S.svIdx = (S.svIdx % #S.saves) + 1
  showSave()
end)
on("WO9_V_Save", function()
  local name = ""
  pcall(function() name = find("WO9_V_Name").Text or "" end)
  if name == "" then say("Save: name it.", true) return end
  local r, err = api("WorldSave", { op = "save", name = name })
  if err then say("Save: " .. tostring(err), true) return end
  say(string.format("Saved %s (%d items).", name, r.items or 0))
  refreshSaves()
  refreshInfo()
end)
on("WO9_V_Load", function()
  local sv = S.saves[S.svIdx]
  if not sv then say("Load: no save.", true) return end
  local r, err = api("WorldSave", { op = "load", name = sv.name })
  if err then say("Load: " .. tostring(err), true) return end
  say(string.format("Loaded %d (copy).", r.loaded or 0))
  refreshInfo()
end)
on("WO9_V_Del", function()
  local sv = S.saves[S.svIdx]
  if not sv then say("Del: no save.", true) return end
  if not S.svDelArm then
    S.svDelArm = true
    say("Del save: click again.", true)
    return
  end
  S.svDelArm = false
  local r, err = api("WorldSave", { op = "delete", name = sv.name })
  if err then say("Del: " .. tostring(err), true) return end
  say("Save deleted.")
  refreshSaves()
  refreshInfo()
end)

-- ============ cleanup ============
on("WO9_C_Fallen", function()
  local y = -400
  pcall(function() y = tonumber(find("WO9_C_Y").Text) or -400 end)
  local r, err = api("WorldClean", { op = "fallen", y = y })
  if err then say("Fallen: " .. tostring(err), true) return end
  setText("WO9_C_Info", string.format("trash +%d (restore ok)", r.moved or 0))
  say(string.format("Quarantined %d.", r.moved or 0))
  refreshInfo()
end)
on("WO9_C_Loose", function()
  local r, err = api("WorldClean", { op = "loose" })
  if err then say("Loose: " .. tostring(err), true) return end
  say(string.format("Quarantined %d loose.", r.moved or 0))
  refreshInfo()
end)
on("WO9_C_Restore", function()
  local r, err = api("WorldClean", { op = "restore" })
  if err then say("Restore: " .. tostring(err), true) return end
  say(string.format("Restored %d.", r.restored or 0))
  refreshInfo()
end)
on("WO9_C_Clear", function()
  if not S.clearArm then
    S.clearArm = true
    say("CLEAR WORLD: click again (autosafe kept).", true)
    return
  end
  S.clearArm = false
  local r, err = api("WorldClear", { confirm = true })
  if err then say("Clear: " .. tostring(err), true) return end
  say(string.format("Cleared %d (backup %s).", r.deleted or 0, r.backup or "?"))
  refreshInfo()
  refreshSaves()
end)

-- ============ mobile strip ============
on("M_WO_Save", function()
  pcall(function() api("WorldSave", { op = "delete", name = "quick" }) end)
  local r, err = api("WorldSave", { op = "save", name = "quick" })
  if err then say("Save: " .. tostring(err), true) return end
  say(string.format("Quicksaved (%d).", r.items or 0))
  refreshSaves()
  refreshInfo()
end)
on("M_WO_Spawn", function()
  local r, err = api("WorldSpawn", { op = "add" })
  if err then say("Spawn: " .. tostring(err), true) return end
  say("Spawn added (at you).")
  refreshSpawns()
  refreshInfo()
end)
on("M_WO_Clean", function()
  local r, err = api("WorldClean", { op = "fallen", y = -400 })
  if err then say("Clean: " .. tostring(err), true) return end
  say(string.format("Quarantined %d.", r.moved or 0))
  refreshInfo()
end)

-- ============ boot ============
on("WO9_Close", function() setOpen(false) end)
rawset(_G, "ArkherWorld", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
