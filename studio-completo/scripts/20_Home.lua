-- 20_Home (R16) — Home/Explorer: projeto + tree (Snapshot) + props (handlers reais).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
local clientBus = rt:WaitForChild("ClientBus")
local menusBus = rt:WaitForChild("MenusBus")
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
local function menus(action)
  local ok, r = pcall(function() return menusBus:Invoke(action, {}) end)
  if not ok then return nil, tostring(r) end
  return r
end
local function on(n, fn)
  local o = find(n)
  if o and o.Activated then o.Activated:Connect(function() pcall(fn) end) end
end
local PANELS = { "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status" }
local DESK = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status",
  "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status",
  "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local OTHER_M = { "M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO", "M_SC", "M_PL" }
local S = { open = false, nodes = {}, idx = 0, selId = nil, selName = "-", selClass = "-" }
local function platform()
  local ok, ai = pcall(function() return _G.ArkherInput end)
  if ok and ai and ai.platform then
    local ok2, p = pcall(ai.platform)
    if ok2 and p then return p end
  end
  return "PC"
end
local refreshTree
local function setOpen(v)
  S.open = v
  for _, n in ipairs(PANELS) do vis(n, v) end
  for _, n in ipairs(DESK) do vis(n, not v) end
  if v then
    for _, n in ipairs(OTHER_EDS) do vis(n, false) end
    for _, n in ipairs(OTHER_M) do vis(n, false) end
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherScript", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    vis("M_HO", platform() == "Mobile")
    refreshTree()
    say("Home open.")
  else
    vis("M_HO", false)
    say("Home closed.")
  end
end

-- ============ file (menus reais) ============
on("HO10_F_New", function()
  menus("File")
  setText("HO10_F_Info", "new: file menu")
  say("File menu.")
end)
on("HO10_F_Open", function()
  menus("File")
  setText("HO10_F_Info", "open: file menu")
  say("File menu.")
end)
on("HO10_F_Save", function()
  local r, err = menus("Save")
  if err then say("Save: " .. tostring(err), true) return end
  setText("HO10_F_Info", "saved via menus")
  say("Saved.")
end)
on("HO10_F_Pub", function()
  menus("OpenPublish")
  setText("HO10_F_Info", "publish dialog")
  say("Publish dialog.")
end)
on("HO10_F_Undo", function()
  local r, err = api("Undo", {})
  if err then say("Undo: " .. tostring(err), true) return end
  setText("HO10_F_Info", "undid: " .. tostring(r.label or "?"):sub(1, 40))
  say("Undid " .. tostring(r.label or ""))
  refreshTree()
end)

-- ============ tree (Snapshot real) ============
local function showNode()
  local nd = S.nodes[S.idx]
  if not nd then
    setText("HO10_T_Info", "no match")
    setText("HO10_StatL", "home · 0 nodes")
    return
  end
  setText("HO10_T_Info", string.format("%s · %s\n(%d/%d)", nd.name, nd.class, S.idx, #S.nodes))
  setText("HO10_StatL", string.format("home · %d nodes", #S.nodes))
end
refreshTree = function()
  local filt = ""
  pcall(function() filt = find("HO10_T_Filter").Text or "" end)
  filt = filt:lower()
  local snap, err = api("Snapshot", {})
  if err then say("Tree: " .. tostring(err), true) return end
  local out = {}
  for _, nd in ipairs(snap.nodes or {}) do
    if filt == "" or (nd.name and nd.name:lower():find(filt, 1, true)) then
      out[#out + 1] = nd
    end
  end
  S.nodes = out
  S.idx = (#out > 0) and 1 or 0
  showNode()
end
on("HO10_T_Refresh", refreshTree)
on("HO10_T_Prev", function()
  if #S.nodes == 0 then return end
  S.idx = ((S.idx - 2) % #S.nodes) + 1
  showNode()
end)
on("HO10_T_Next", function()
  if #S.nodes == 0 then return end
  S.idx = (S.idx % #S.nodes) + 1
  showNode()
end)
on("HO10_T_Sel", function()
  local nd = S.nodes[S.idx]
  if not nd then say("Select: empty.", true) return end
  local r, err = api("Select", { id = nd.id })
  if err then say("Select: " .. tostring(err), true) return end
  S.selId, S.selName, S.selClass = nd.id, nd.name, nd.class
  if r and r.node and r.node.object then
    pcall(function()
      local sv = rt:FindFirstChild("SelectedInstance")
      if sv then sv.Value = r.node.object end
    end)
  end
  setText("HO10_P_Info", string.format("%s · %s", nd.name, nd.class))
  say("Selected " .. nd.name .. ".")
end)

-- ============ props (handlers reais) ============
on("HO10_P_Rename", function()
  if not S.selId then say("Rename: select first.", true) return end
  local nm = ""
  pcall(function() nm = find("HO10_P_Name").Text or "" end)
  if nm == "" then say("Rename: type a name.", true) return end
  local r, err = api("Rename", { id = S.selId, name = nm })
  if err then say("Rename: " .. tostring(err), true) return end
  S.selName = nm
  setText("HO10_P_Info", string.format("%s · %s", nm, S.selClass))
  say("Renamed.")
  refreshTree()
end)
on("HO10_P_Vis", function()
  if not S.selId then say("Show/Hide: select first.", true) return end
  local key = nil
  if S.selClass == "ScreenGui" then key = "Enabled"
  elseif S.selClass == "Folder" or S.selClass == "Model" then key = nil
  else
    local r = api("Select", { id = S.selId })
    if r and r.properties then
      for _, f in ipairs(r.properties.fields or {}) do
        if f.key == "Visible" then key = "Visible" break end
      end
    end
  end
  if not key then say("Show/Hide: no Visible prop.", true) return end
  local cur = nil
  local r = api("Select", { id = S.selId })
  if r and r.properties then
    for _, f in ipairs(r.properties.fields or {}) do
      if f.key == key then cur = f.value break end
    end
  end
  local rr, err = api("Set", { id = S.selId, key = key, value = not cur })
  if err then say("Show/Hide: " .. tostring(err), true) return end
  say(key .. " = " .. tostring(not cur) .. ".")
end)
on("HO10_P_Dup", function()
  if not S.selId then say("Dup: select first.", true) return end
  local r, err = api("Duplicate", { id = S.selId })
  if err then say("Dup: " .. tostring(err), true) return end
  say("Duplicated.")
  refreshTree()
end)
on("HO10_P_Del", function()
  if not S.selId then say("Del: select first.", true) return end
  local r, err = api("Delete", { id = S.selId })
  if err then say("Del: " .. tostring(err), true) return end
  S.selId, S.selName, S.selClass = nil, "-", "-"
  setText("HO10_P_Info", "-")
  say("Deleted.")
  refreshTree()
end)

-- ============ mobile ============
on("M_HO_Save", function()
  local r, err = menus("Save")
  if err then say("Save: " .. tostring(err), true) return end
  say("Saved.")
end)
on("M_HO_Refresh", refreshTree)
on("M_HO_Del", function()
  if not S.selId then say("Del: select first.", true) return end
  local r, err = api("Delete", { id = S.selId })
  if err then say("Del: " .. tostring(err), true) return end
  S.selId = nil
  say("Deleted.")
  refreshTree()
end)

-- ============ boot ============
setText("HO10_H_Text", "HOME: file ops reuse Studio menus. EXPLORER: filter, walk, SELECT syncs the real selection. Props edit name/visible, duplicate, delete.")
on("HO10_Close", function() setOpen(false) end)
rawset(_G, "ArkherHome", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
