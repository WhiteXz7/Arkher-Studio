-- =============================================================
-- ARKHER Modeler (14_Modeler) — malha real via EditableMesh
-- UI 100% assada (MD4_*); este script LIGA os controles e traduz
-- gesto -> MeshNew/Select/MoveVert/DeleteVert/Smooth/Mirror/OBJ (R12).
-- Sem GUI via script: verts navegados por prev/next + pick nearest.
-- =============================================================

local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "14: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "14: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "14: runtime missing (01_Nucleo must boot first).")
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
  if type(r) == "table" and r.error then return nil, tostring(r) end
  return (type(r) == "table" and r.result) or r, nil
end
local say = function(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = text, bad = bad }) end)
end
local function cam()
  return workspace.CurrentCamera
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
local function rayView(x, y)
  local c = cam()
  if not c then return nil end
  local ok, ray = pcall(function() return c:ScreenPointToRay(x, y) end)
  if not ok or not ray then return nil end
  local ok2, hit = pcall(function() return workspace:Raycast(ray.Origin, ray.Direction * 5000) end)
  if not ok2 or not hit or not hit.Instance then return nil end
  return hit
end

-- ============ estado ============
local S = { open = false, tool = "Select", prim = "box", iters = 1,
  meshId = nil, meshName = "-", verts = {}, vertIdx = 0,
  pend = { x = 0, y = 0, z = 0 } }
local MD4_ALL = { "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History",
  "TE3_Gen", "TE3_Water", "TE3_Status", "VP3_Rail", "VP3_Cam", "VP3_Trans",
  "VP3_Meas", "VP3_Snap", "VP3_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO",
  "AN5_Status" }
local DESK_HIDE = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }

local function curVert()
  if S.vertIdx >= 1 and S.vertIdx <= #S.verts then return S.verts[S.vertIdx] end
  return nil
end
local function refreshStatus()
  setText("MD4_StatL", string.format("%s · %s · %d verts · tool %s",
    S.meshName, S.meshId and "loaded" or "no-mesh", #S.verts, string.upper(S.tool)))
end
local marker = nil
local function setOpen(v)
  S.open = v
  for _, n in ipairs(MD4_ALL) do setVisible(n, v) end
  for _, n in ipairs(DESK_HIDE) do setVisible(n, not v) end
  for _, n in ipairs(OTHER_EDS) do setVisible(n, false) end
  setVisible("M_VP", false)
  setVisible("M_AN", false)
  if v then
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherAnimator" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    if platform() == "Mobile" then setVisible("M_MD", true) end
    say("Modeler open (" .. platform() .. ").")
  else
    setVisible("M_MD", false)
    if marker then pcall(function() marker:Destroy() end) end
    marker = nil
    say("Modeler closed.")
  end
end

-- ============ marcador 3D do vert ============
local function meshPart()
  if not S.meshId then return nil end
  local inst = nil
  pcall(function()
    local sv = rt:FindFirstChild("SelectedInstance")
    if sv and sv.Value and sv.Value:IsA("MeshPart") then inst = sv.Value end
  end)
  if inst then return inst end
  pcall(function()
    for _, o in ipairs(workspace:GetDescendants()) do
      local isM = false
      pcall(function() isM = o:IsA("MeshPart") end)
      if isM and o.Name == S.meshName then inst = o break end
    end
  end)
  return inst
end
local function updateMarker()
  local v = curVert()
  if marker then pcall(function() marker:Destroy() end) end
  marker = nil
  if not (S.open and v) then return end
  local part = meshPart()
  local w = Vector3.new(v.x, v.y, v.z)
  if part then pcall(function() w = part.CFrame * Vector3.new(v.x, v.y, v.z) end) end
  local ok, p = pcall(Instance.new, "Part")
  if not ok or not p then return end
  pcall(function()
    p.Name = "ArkherVertMark"
    p.Shape = Enum.PartType.Ball
    p.Size = Vector3.new(1, 1, 1)
    p.Color = Color3.fromRGB(240, 185, 70)
    p.Transparency = 0.2
    p.Anchored = true p.CanCollide = false p.CanQuery = false
    p.CFrame = CFrame.new(w.X, w.Y, w.Z)
    p.Parent = workspace
  end)
  marker = p
end

-- ============ malha ============
local function showVert()
  local v = curVert()
  if not v then
    setText("MD4_V_Id", "vid -")
    setText("MD4_V_XV", "0") setText("MD4_V_YV", "0") setText("MD4_V_ZV", "0")
  else
    setText("MD4_V_Id", "vid " .. tostring(v.vid))
    setText("MD4_V_XV", string.format("%.2f", v.x + S.pend.x))
    setText("MD4_V_YV", string.format("%.2f", v.y + S.pend.y))
    setText("MD4_V_ZV", string.format("%.2f", v.z + S.pend.z))
  end
  updateMarker()
  refreshStatus()
end
local function loadVerts(silent)
  if not S.meshId then return false end
  local r, err = api("MeshVerts", { id = S.meshId })
  if err then
    if not silent then say("Verts: " .. tostring(err), true) end
    return false
  end
  S.verts = r.verts or {}
  S.pend = { x = 0, y = 0, z = 0 }
  if S.vertIdx < 1 or S.vertIdx > #S.verts then S.vertIdx = (#S.verts > 0) and 1 or 0 end
  local info = api("MeshInfo", { id = S.meshId })
  if info then
    setText("MD4_Info", string.format("%s\n%d verts %d faces", S.meshName, info.verts or 0, info.faces or 0))
  end
  showVert()
  return true
end
local function adoptId(id, name)
  local r, err = api("MeshSelect", { id = id })
  if err then say("Adopt: " .. tostring(err), true) return false end
  S.meshId = id
  S.meshName = name or id
  S.vertIdx = 1
  say("Mesh adopted (" .. tostring(r.verts) .. " verts).")
  loadVerts()
  return true
end

-- ============ ferramentas ============
local BTN_BG, ACC_BG = nil, nil
pcall(function()
  local b = find("MD4_T_Select")
  if b then BTN_BG = b.BackgroundColor3 end
  local g = find("MD4_New")
  if g then ACC_BG = g.BackgroundColor3 end
end)
local function setTool(t)
  S.tool = t
  for _, k in ipairs({ "Select", "Move", "Near" }) do
    local o = find("MD4_T_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == t and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
  if t == "Select" or t == "Move" then
    local ok, err = pcall(function() clientBus:Invoke("SetMode", { key = t }) end)
    if not ok then say("SetMode: " .. tostring(err), true) end
  else
    say("Near: click the mesh to grab the nearest vertex.")
  end
  refreshStatus()
end
for _, k in ipairs({ "Select", "Move", "Near" }) do
  local key = k
  on("MD4_T_" .. key, function() setTool(key) end)
end
on("MD4_Close", function() setOpen(false) end)

-- ============ primitivas ============
local PRIMS = { "Box", "Plane", "Wedge", "Cyl8" }
local function setPrim(p)
  S.prim = p:lower() == "cyl8" and "cyl8" or p:lower()
  for _, k in ipairs(PRIMS) do
    local o = find("MD4_P_" .. k)
    if o then pcall(function()
      o.BackgroundColor3 = (k == p and ACC_BG or BTN_BG) or o.BackgroundColor3
    end) end
  end
end
for _, k in ipairs(PRIMS) do
  local key = k
  on("MD4_P_" .. key, function() setPrim(key) end)
end
on("MD4_New", function()
  local r, err = api("MeshNew", { primitive = S.prim, size = 4 })
  if err then say("New: " .. tostring(err), true) return end
  S.meshId = r.node.id
  S.meshName = r.node.name or S.prim
  S.vertIdx = 1
  say(r.msg or "Mesh created.")
  loadVerts()
end)
on("MD4_Adopt", function()
  local inst = nil
  pcall(function()
    local sv = rt:FindFirstChild("SelectedInstance")
    if sv then inst = sv.Value end
  end)
  if not inst then say("Adopt: select a MeshPart first.", true) return end
  local r, err = api("Identify", { object = inst })
  if err or not (r and r.id) then say("Adopt: " .. tostring(err or "identify failed"), true) return end
  adoptId(r.id, inst.Name)
end)

-- ============ vert steppers ============
on("MD4_V_Prev", function()
  if #S.verts == 0 then return end
  S.vertIdx = ((S.vertIdx - 2) % #S.verts) + 1
  S.pend = { x = 0, y = 0, z = 0 }
  showVert()
end)
on("MD4_V_Next", function()
  if #S.verts == 0 then return end
  S.vertIdx = (S.vertIdx % #S.verts) + 1
  S.pend = { x = 0, y = 0, z = 0 }
  showVert()
end)
for _, ax in ipairs({ "X", "Y", "Z" }) do
  local a = ax
  on("MD4_V_" .. a .. "M", function()
    S.pend[a:lower()] = S.pend[a:lower()] - 0.5
    showVert()
  end)
  on("MD4_V_" .. a .. "P", function()
    S.pend[a:lower()] = S.pend[a:lower()] + 0.5
    showVert()
  end)
end
on("MD4_V_Apply", function()
  local v = curVert()
  if not v then say("Move: no vertex.", true) return end
  local r, err = api("MeshMoveVert", { id = S.meshId, vid = v.vid,
    x = v.x + S.pend.x, y = v.y + S.pend.y, z = v.z + S.pend.z })
  if err then say("Move: " .. tostring(err), true) return end
  S.pend = { x = 0, y = 0, z = 0 }
  say("Vertex moved" .. (r.refreshed and "." or " (collision refresh skipped)."))
  loadVerts()
end)
on("MD4_V_Del", function()
  local v = curVert()
  if not v then say("Delete: no vertex.", true) return end
  local r, err = api("MeshDeleteVert", { id = S.meshId, vid = v.vid })
  if err then say("Delete: " .. tostring(err), true) return end
  say(r.msg or "Vertex deleted.")
  loadVerts()
end)

-- ============ topologia ============
on("MD4_S_IM", function()
  S.iters = math.max(S.iters - 1, 1)
  setText("MD4_S_IV", tostring(S.iters))
end)
on("MD4_S_IP", function()
  S.iters = math.min(S.iters + 1, 10)
  setText("MD4_S_IV", tostring(S.iters))
end)
on("MD4_Smooth", function()
  if not S.meshId then say("Smooth: no mesh.", true) return end
  local r, err = api("MeshSmooth", { id = S.meshId, iters = S.iters, lambda = 0.5 })
  if err then say("Smooth: " .. tostring(err), true) return end
  say("Smoothed x" .. tostring(S.iters) .. ".")
  loadVerts()
end)
for _, ax in ipairs({ "X", "Y", "Z" }) do
  local a = ax
  on("MD4_M_" .. a, function()
    if not S.meshId then say("Mirror: no mesh.", true) return end
    local r, err = api("MeshMirror", { id = S.meshId, axis = a })
    if err then say("Mirror: " .. tostring(err), true) return end
    say("Mirrored " .. a .. ".")
    loadVerts()
  end)
end

-- ============ OBJ ============
on("MD4_IO_Export", function()
  if not S.meshId then say("Export: no mesh.", true) return end
  local r, err = api("MeshExportOBJ", { id = S.meshId })
  if err then say("Export: " .. tostring(err), true) return end
  local box = find("MD4_IO_Text")
  if box then pcall(function() box.Text = r.obj end) end
  print("[ArkherModeler] OBJ export:\n" .. r.obj)
  setText("MD4_IO_Stat", string.format("obj %d v %d f", r.verts, r.faces))
  say("OBJ exported (textbox + Output).")
end)
on("MD4_IO_Import", function()
  local txt = ""
  pcall(function() txt = find("MD4_IO_Text").Text or "" end)
  if txt == "" then say("Import: paste OBJ first.", true) return end
  local r, err = api("MeshImportOBJ", { obj = txt, name = "Mesh_OBJ" })
  if err then say("Import: " .. tostring(err), true) return end
  S.meshId = r.node.id
  S.meshName = r.node.name or "Mesh_OBJ"
  S.vertIdx = 1
  setText("MD4_IO_Stat", string.format("obj %d v %d f", r.verts, r.faces))
  say(r.msg or "OBJ imported.")
  loadVerts()
end)

-- ============ clique: select mesh / near vert ============
UIS.InputBegan:Connect(function(input, gpe)
  if gpe or not S.open or typing() then return end
  if S.tool ~= "Select" and S.tool ~= "Near" then return end
  local uit = input.UserInputType
  if uit ~= Enum.UserInputType.MouseButton1 and uit ~= Enum.UserInputType.Touch then return end
  local p = input.Position
  if not p or overUI(p.X, p.Y) then return end
  local hit = rayView(p.X, p.Y)
  if not hit then return end
  if S.tool == "Select" then
    local isM = false
    pcall(function() isM = hit.Instance:IsA("MeshPart") end)
    if not isM then say("Select: that's not a MeshPart.", true) return end
    local r, err = api("Identify", { object = hit.Instance })
    if err or not (r and r.id) then say("Select: " .. tostring(err or "identify failed"), true) return end
    adoptId(r.id, hit.Instance.Name)
  else
    if not S.meshId or #S.verts == 0 then say("Near: load a mesh first.", true) return end
    local part = meshPart()
    local best, bestD = 1, 1e18
    for i, v in ipairs(S.verts) do
      local w = Vector3.new(v.x, v.y, v.z)
      if part then pcall(function() w = part.CFrame * Vector3.new(v.x, v.y, v.z) end) end
      local d = 0
      pcall(function() d = (w - hit.Position).Magnitude end)
      if d < bestD then best, bestD = i, d end
    end
    S.vertIdx = best
    S.pend = { x = 0, y = 0, z = 0 }
    showVert()
    say("Nearest: vid " .. tostring(S.verts[best].vid) .. ".")
  end
end)

-- ============ mobile strip ============
on("M_MD_New", function()
  local r, err = api("MeshNew", { primitive = "box", size = 4 })
  if err then say("New: " .. tostring(err), true) return end
  S.meshId = r.node.id
  S.meshName = r.node.name or "box"
  S.vertIdx = 1
  say(r.msg or "Mesh created.")
  loadVerts()
end)
on("M_MD_Smooth", function()
  if not S.meshId then say("Smooth: no mesh.", true) return end
  local r, err = api("MeshSmooth", { id = S.meshId, iters = 1, lambda = 0.5 })
  if err then say("Smooth: " .. tostring(err), true) return end
  say("Smoothed.")
  loadVerts()
end)

-- ============ boot ============
setTool("Select")
setPrim("Box")
refreshStatus()
rawset(_G, "ArkherModeler", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
