-- =============================================================
-- ARKHER UI Editor (16_UI) — edita UI de verdade no PlayerGui ao vivo
-- UI 100% assada (UI6_*); este script LIGA os controles e traduz
-- gesto -> UiRoot/New/Delete/Dup/Move/Size/Text/Tree/Export/Import/
-- Publish (R14a). Escopo restrito a PlayerGui/StarterGui do autor.
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "16: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "16: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "16: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ============ helpers ============
local function find(name)
  return shell:FindFirstChild(name, true)
end
local function setText(name, text)
  local o = find(name)
  if o then pcall(function() o.Text = text end) end
end
local function setVisible(name, v)
  local o = find(name)
  if o then pcall(function() o.Visible = v end) end
end
local function on(name, fn)
  local o = find(name)
  if not o then return nil end
  local ev = o.Activated or o.MouseButton1Click
  if ev then pcall(function() ev:Connect(fn) end) return o end
  return nil
end
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  return (type(r) == "table" and r.result) or r, nil
end
local say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
end
local function typing()
  local ok, box = pcall(function() return UIS:GetFocusedTextBox() end)
  return ok and box ~= nil
end
local function platform()
  local inp = _G.ArkherInput
  if inp and inp.platform then
    local ok, p = pcall(inp.platform)
    if ok and p then return p end
  end
  return "PC"
end
local function overUI(x, y)
  local hit = false
  pcall(function()
    local pg = player:WaitForChild("PlayerGui")
    local list = pg:GetGuiObjectsAtPosition(x, y)
    local o = list and list[1] or nil
    local depth = 0
    while o and depth < 10 do
      if o.Name == "ArkherShell2" then hit = true break end
      o = o.Parent
      depth = depth + 1
    end
  end)
  return hit
end

-- ============ estado ============
local S = { open = false, tool = "Select",
  rootId = nil, selId = nil, selName = "-", selClass = "-",
  tree = {}, treeIdx = 0,
  drag = { active = false, id = nil, lx = 0, ly = 0 } }
local UI6_ALL = { "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status", "VP3_Rail", "VP3_Cam", "VP3_Trans",
  "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert",
  "MD4_Top", "MD4_IO", "MD4_Status", "AN5_Rail", "AN5_Rig", "AN5_Pose",
  "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status",
  "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status",
  "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status",
  "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel",
  "O2_Crumb", "O2_Compass", "O2_Coords", "O2_Play",
  "O2_Layers", "O2_Region", "O2_Map", "O2_Gizmo", "FR2_Help" }
local NEW_CLASS = { Frame = "Frame", Label = "TextLabel", Button = "TextButton",
  Box = "TextBox", Image = "ImageLabel", Scroll = "ScrollingFrame",
  Corner = "UICorner", Stroke = "UIStroke" }

local function refreshStatus()
  setText("UI6_StatL", string.format("%s · %d nodes · %s",
    S.selName, #S.tree, string.upper(S.tool)))
end
local function showSel()
  setText("UI6_Info", string.format("%s\n%s", S.selName, S.selClass))
  local it = nil
  for _, t in ipairs(S.tree) do if t.id == S.selId then it = t break end end
  setText("UI6_XV", tostring(it and it.x or 0))
  setText("UI6_YV", tostring(it and it.y or 0))
  setText("UI6_WV", tostring(it and it.w or 0))
  setText("UI6_HV", tostring(it and it.h or 0))
  local cur = nil
  for i, t in ipairs(S.tree) do if t.id == S.selId then cur = i break end end
  if cur then
    local pad = string.rep("> ", math.min(S.tree[cur].depth or 0, 4))
    setText("UI6_T_Name", (pad .. S.tree[cur].name):sub(1, 18))
  else
    setText("UI6_T_Name", "- -")
  end
  refreshStatus()
end
local function loadTree(silent)
  local r, err = api("UiTree", {})
  if err then
    if not silent then say("Tree: " .. tostring(err), true) end
    return false
  end
  S.tree = r.items or {}
  local still = false
  for _, t in ipairs(S.tree) do if t.id == S.selId then still = true break end end
  if not still then S.selId, S.selName, S.selClass = nil, "-", "-" end
  showSel()
  return true
end
local function setOpen(v)
  S.open = v
  for _, n in ipairs(UI6_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  for _, n in ipairs(OTHER_EDS) do setVisible(n, false) end
  setVisible("M_VP", false)
  setVisible("M_MD", false)
  setVisible("M_AN", false)
  setVisible("M_RW", false)
  setVisible("M_DO", false)
  setVisible("M_WO", false)
  setVisible("M_HO", false)
  setVisible("M_SC", false)
  setVisible("M_PL", false)
  if v then
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherHome", "ArkherScript", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    local r, err = api("UiRoot", {})
    if err then say("Root: " .. tostring(err), true)
    elseif r and r.node then S.rootId = r.node.id end
    loadTree(true)
    if platform() == "Mobile" then setVisible("M_UI", true) end
    say("UI Editor open (" .. platform() .. ").")
  else
    S.drag.active = false
    setVisible("M_UI", false)
    say("UI Editor closed.")
  end
end

-- ============ ferramentas ============
local BTN_BG, ACC_BG = nil, nil
pcall(function()
  local b = find("UI6_T_Select")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("UI6_N_Frame")
  if g then ACC_BG = g.BackgroundColor3 end
end)
local function setTool(t)
  S.tool = t
  for _, k in ipairs({ "Select", "Move" }) do
    local o = find("UI6_T_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == t and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  if t == "Select" then
    local ok, err = pcall(function() clientBus:Invoke("SetMode", { key = t }) end)
    if not ok then say("SetMode: " .. tostring(err), true) end
  else
    say("Move: drag any ArkherUI element.")
  end
  refreshStatus()
end
for _, k in ipairs({ "Select", "Move" }) do
  local key = k
  on("UI6_T_" .. key, function() setTool(key) end)
end
on("UI6_Close", function() setOpen(false) end)

-- ============ criar ============
for key, class in pairs(NEW_CLASS) do
  local kk, cc = key, class
  on("UI6_N_" .. kk, function()
    local arg = { class = cc, name = cc }
    if S.selId then arg.parentId = S.selId end
    local r, err = api("UiNew", arg)
    if err then say("New: " .. tostring(err), true) return end
    S.selId = r.node.id
    S.selName = r.node.name
    S.selClass = cc
    say(cc .. " created.")
    loadTree()
  end)
end

-- ============ props ============
local function nudge(key, dx, dy)
  if not S.selId then say("Move: select first.", true) return end
  local r, err = api("UiMove", { id = S.selId, dx = dx, dy = dy })
  if err then say("Move: " .. tostring(err), true) return end
  setText("UI6_XV", tostring(r.x))
  setText("UI6_YV", tostring(r.y))
  for _, t in ipairs(S.tree) do
    if t.id == S.selId then t.x, t.y = r.x, r.y break end
  end
end
on("UI6_X_M", function() nudge("X", -5, 0) end)
on("UI6_X_P", function() nudge("X", 5, 0) end)
on("UI6_Y_M", function() nudge("Y", 0, -5) end)
on("UI6_Y_P", function() nudge("Y", 0, 5) end)
local function resize(dw, dh)
  if not S.selId then say("Size: select first.", true) return end
  local r, err = api("UiSize", { id = S.selId, dw = dw, dh = dh })
  if err then say("Size: " .. tostring(err), true) return end
  setText("UI6_WV", tostring(r.w))
  setText("UI6_HV", tostring(r.h))
  for _, t in ipairs(S.tree) do
    if t.id == S.selId then t.w, t.h = r.w, r.h break end
  end
end
on("UI6_W_M", function() resize(-10, 0) end)
on("UI6_W_P", function() resize(10, 0) end)
on("UI6_H_M", function() resize(0, -10) end)
on("UI6_H_P", function() resize(0, 10) end)
on("UI6_T_Apply", function()
  if not S.selId then say("Text: select first.", true) return end
  local txt = ""
  pcall(function() txt = find("UI6_Text").Text or "" end)
  local r, err = api("UiText", { id = S.selId, text = txt })
  if err then say("Text: " .. tostring(err), true) return end
  say("Text set.")
end)
on("UI6_Dup", function()
  if not S.selId then say("Dup: select first.", true) return end
  local r, err = api("UiDup", { id = S.selId })
  if err then say("Dup: " .. tostring(err), true) return end
  S.selId = r.node.id
  S.selName = r.node.name
  say("Duplicated.")
  loadTree()
end)
on("UI6_Del", function()
  if not S.selId then say("Del: select first.", true) return end
  local r, err = api("UiDelete", { id = S.selId })
  if err then say("Del: " .. tostring(err), true) return end
  S.selId, S.selName, S.selClass = nil, "-", "-"
  say("Deleted.")
  loadTree()
end)

-- ============ tree + publish ============
on("UI6_T_Prev", function()
  if #S.tree == 0 then return end
  local cur = 1
  for i, t in ipairs(S.tree) do if t.id == S.selId then cur = i break end end
  cur = ((cur - 2) % #S.tree) + 1
  S.selId, S.selName, S.selClass = S.tree[cur].id, S.tree[cur].name, S.tree[cur].class
  showSel()
end)
on("UI6_T_Next", function()
  if #S.tree == 0 then return end
  local cur = #S.tree
  for i, t in ipairs(S.tree) do if t.id == S.selId then cur = i break end end
  cur = (cur % #S.tree) + 1
  S.selId, S.selName, S.selClass = S.tree[cur].id, S.tree[cur].name, S.tree[cur].class
  showSel()
end)
on("UI6_Pub", function()
  if not S.rootId then say("Publish: no root.", true) return end
  local r, err = api("UiPublish", { id = S.rootId })
  if err then say("Publish: " .. tostring(err), true) return end
  say(r.msg or "Published.")
end)

-- ============ IO ============
on("UI6_IO_Export", function()
  if not S.selId then say("Export: select first.", true) return end
  local r, err = api("UiExport", { id = S.selId })
  if err then say("Export: " .. tostring(err), true) return end
  local box = find("UI6_IO_Text")
  if box then pcall(function() box.Text = r.json end) end
  print("[ArkherUI] UI export:\n" .. r.json)
  setText("UI6_IO_Stat", string.format("ui %d nodes", r.nodes or 0))
  say("UI exported (textbox + Output).")
end)
on("UI6_IO_Import", function()
  local txt = ""
  pcall(function() txt = find("UI6_IO_Text").Text or "" end)
  if txt == "" then say("Import: paste UI first.", true) return end
  local arg = { json = txt }
  if S.selId then arg.parentId = S.selId end
  local r, err = api("UiImport", arg)
  if err then say("Import: " .. tostring(err), true) return end
  S.selId = r.node.id
  S.selName = r.node.name
  S.selClass = r.node.class or S.selClass
  setText("UI6_IO_Stat", string.format("ui %d nodes", r.nodes or 0))
  say(r.msg or "UI imported.")
  loadTree()
end)

-- ============ clique: select + drag ============
local function pickArkher(x, y)
  local found = nil
  pcall(function()
    local pg = player:WaitForChild("PlayerGui")
    local list = pg:GetGuiObjectsAtPosition(x, y) or {}
    for _, o in ipairs(list) do
      local p, depth, ok = o, 0, false
      while p and depth < 12 do
        if p.Name == "ArkherShell2" then ok = false break end
        if p.Name == "ArkherUI" then ok = true break end
        p = p.Parent
        depth = depth + 1
      end
      if ok then found = o break end
    end
  end)
  return found
end
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or typing() then return end
  if S.tool ~= "Select" and S.tool ~= "Move" then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseButton1 and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p or overUI(p.X, p.Y) then return end
  local hit = pickArkher(p.X, p.Y)
  if not hit then
    if S.tool == "Select" then say("Select: click an ArkherUI element.", true) end
    return
  end
  local r, err = api("Identify", { object = hit })
  if err or not (r and r.id) then say("Select: " .. tostring(err or "identify failed"), true) return end
  S.selId = r.id
  S.selName = hit.Name
  pcall(function() S.selClass = hit.ClassName end)
  showSel()
  if S.tool == "Move" then
    S.drag = { active = true, id = r.id, lx = p.X, ly = p.Y }
    say("Dragging " .. hit.Name .. ".")
  end
end)
UIS.InputChanged:Connect(function(input, gpe)
  if gpe or not S.open or not S.drag.active then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseMovement and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p then return end
  local dx, dy = p.X - S.drag.lx, p.Y - S.drag.ly
  S.drag.lx, S.drag.ly = p.X, p.Y
  if dx == 0 and dy == 0 then return end
  local r, err = api("UiMove", { id = S.drag.id, dx = dx, dy = dy })
  if err then S.drag.active = false return end
  setText("UI6_XV", tostring(r.x))
  setText("UI6_YV", tostring(r.y))
  for _, t in ipairs(S.tree) do
    if t.id == S.drag.id then t.x, t.y = r.x, r.y break end
  end
end)
UIS.InputEnded:Connect(function(input)
  if S.drag.active then
    S.drag.active = false
    say("Dropped.")
  end
end)

-- ============ mobile strip ============
on("M_UI_New", function()
  local r, err = api("UiNew", { class = "Frame", name = "Frame" })
  if err then say("New: " .. tostring(err), true) return end
  S.selId = r.node.id
  S.selName = r.node.name
  S.selClass = "Frame"
  say("Frame created.")
  loadTree()
end)
on("M_UI_Dup", function()
  if not S.selId then say("Dup: select first.", true) return end
  local r, err = api("UiDup", { id = S.selId })
  if err then say("Dup: " .. tostring(err), true) return end
  S.selId = r.node.id
  S.selName = r.node.name
  say("Duplicated.")
  loadTree()
end)
on("M_UI_Del", function()
  if not S.selId then say("Del: select first.", true) return end
  local r, err = api("UiDelete", { id = S.selId })
  if err then say("Del: " .. tostring(err), true) return end
  S.selId, S.selName, S.selClass = nil, "-", "-"
  say("Deleted.")
  loadTree()
end)

-- ============ boot ============
setTool("Select")
showSel()
rawset(_G, "ArkherUI", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})