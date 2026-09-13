-- 05_StudioX (REBUILD EN) — panels + overlays + footer of ArkherShell2.
-- Every container is baked (build_shell2.py). Runtime instances created here are
-- DATA ROWS ONLY (console lines, team rows, timeline markers) — the same pattern
-- 01_Nucleo uses for Explorer rows. All actions call real server handlers.
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LogService = game:GetService("LogService")
local Social = game:GetService("SocialService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local gui = script:FindFirstAncestorOfClass("ScreenGui")
assert(gui, "05: must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "05: ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "05: runtime missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 20)
local selInst = rt:WaitForChild("SelectedInstance", 20)

local ACC = Color3.fromRGB(43, 139, 230)
local TXT = Color3.fromRGB(231, 240, 255)
local MUT = Color3.fromRGB(147, 165, 196)
local GOLD = Color3.fromRGB(240, 185, 70)
local RED = Color3.fromRGB(248, 113, 113)
local GRN = Color3.fromRGB(52, 211, 153)

local function say(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = tostring(text), bad = bad }) end)
end

local function api(action, payload)
  local res = nil
  local ok = pcall(function()
    res = clientBus:Invoke("API", { action = action, payload = payload or {}, quiet = true })
  end)
  if not ok then return nil, "bridge failed" end
  if type(res) == "table" and res.error then return nil, tostring(res.error) end
  return (res == nil) and true or res, nil
end

local function state()
  local ok, st = pcall(function() return clientBus:Invoke("State") end)
  if ok and type(st) == "table" then return st end
  return {}
end

local function on(name, fn)
  local o = shell:FindFirstChild(name, true)
  if not o then say("05: baked control missing: " .. name, true) return end
  if not o:IsA("GuiButton") then return end
  local function fire() local ok, err = pcall(fn, o) if not ok then say(name .. ": " .. tostring(err), true) end end
  pcall(function() o.Activated:Connect(fire) end)
  pcall(function() o.MouseButton1Click:Connect(fire) end)
end

local function lbl(name)
  local o = shell:FindFirstChild(name, true)
  if o and o:IsA("TextLabel") then return o end
  return nil
end

local function setText(name, text)
  local o = lbl(name) if o then o.Text = tostring(text) end
end

local function menu(name, button)
  if not menusBus then say("Menus still starting…", true) return end
  local ok, err = pcall(function() menusBus:Invoke("Menu", { name = name, button = button }) end)
  if not ok then say("Menu " .. name .. ": " .. tostring(err), true) end
end

local function bus(cmd, arg)
  if not menusBus then say("Menus still starting…", true) return end
  local ok, err = pcall(function() menusBus:Invoke(cmd, arg or {}) end)
  if not ok then say(cmd .. ": " .. tostring(err), true) end
end

local function cam()
  return workspace.CurrentCamera
end

local function frontPos(dist, up)
  local c = cam()
  if not c then return { x = 0, y = 3, z = -16 } end
  local cf = c.CFrame * CFrame.new(0, up or 3, -(dist or 16))
  local p = cf.Position
  return { x = math.floor(p.X), y = math.floor(p.Y), z = math.floor(p.Z) }
end

local lastEdit = nil
local function markEdit() lastEdit = os.date("%H:%M:%S") end

-- ================= CONSOLE =================
local logBox = shell:FindFirstChild("C2_Log", true)
local logFilter = "All"
local logRows = {}
local logY = 0
local logLatest = "—"
_G.ArkherUnread = 0

local LVLCOL = { Info = TXT, Warn = GOLD, Error = RED }
local function logAdd(level, msg)
  msg = tostring(msg)
  logLatest = msg
  if level ~= "Info" then _G.ArkherUnread = (_G.ArkherUnread or 0) + 1 end
  if not logBox then setText("F2_LogLine", msg:sub(1, 110)) return end
  local row = Instance.new("TextLabel")
  row.Name = "Row"
  row.BackgroundTransparency = 1
  row.BorderSizePixel = 0
  row.Font = Enum.Font.Code
  row.TextSize = 11
  row.TextColor3 = LVLCOL[level] or TXT
  row.TextXAlignment = Enum.TextXAlignment.Left
  row.TextYAlignment = Enum.TextYAlignment.Top
  row.TextTruncate = Enum.TextTruncate.AtEnd
  row.Position = UDim2.fromOffset(4, logY)
  row.Size = UDim2.new(1, -8, 0, 14)
  row.Text = msg:sub(1, 160)
  row:SetAttribute("Lvl", level)
  row.Visible = (logFilter == "All") or (logFilter == level)
  row.Parent = logBox
  logY = logY + 14
  logRows[#logRows + 1] = row
  if #logRows > 150 then
    local old = table.remove(logRows, 1)
    if old then old:Destroy() end
    logY = 0
    for _, r in ipairs(logRows) do r.Position = UDim2.fromOffset(4, logY) logY = logY + 14 end
  end
  pcall(function() logBox.CanvasPosition = Vector2.new(0, math.max(0, logY - 100)) end)
  setText("F2_LogLine", msg:sub(1, 110))
end

local function setConsoleFilter(f)
  logFilter = f
  local n = 0
  for _, r in ipairs(logRows) do
    local show = (f == "All") or (r:GetAttribute("Lvl") == f)
    r.Visible = show
    if show and f == "Error" then n = n + 1 end
  end
  for _, b in ipairs({ "All", "Info", "Warn", "Error" }) do
    local o = shell:FindFirstChild("C2_" .. b, true)
    if o and o:IsA("GuiButton") then o.TextColor3 = (b == f) and GRN or TXT end
  end
end

pcall(function()
  LogService.MessageOut:Connect(function(msg, mtype)
    local lvl = "Info"
    if mtype == Enum.MessageType.MessageWarning then lvl = "Warn"
    elseif mtype == Enum.MessageType.MessageError then lvl = "Error" end
    logAdd(lvl, msg)
  end)
end)
on("C2_All", function() setConsoleFilter("All") end)
on("C2_Info", function() setConsoleFilter("Info") end)
on("C2_Warn", function() setConsoleFilter("Warn") end)
on("C2_Error", function() setConsoleFilter("Error") end)
on("C2_Clear", function()
  for _, r in ipairs(logRows) do pcall(function() r:Destroy() end) end
  logRows = {} logY = 0 _G.ArkherUnread = 0
  say("Console cleared.")
end)
on("F2_Out", function() setConsoleFilter("All") end)
on("F2_Err", function()
  setConsoleFilter("Error")
  local n = 0
  for _, r in ipairs(logRows) do if r:GetAttribute("Lvl") == "Error" then n = n + 1 end end
  say(n == 0 and "No errors logged." or (tostring(n) .. " error(s) — see Console."))
end)

-- ================= TERRAIN =================
local tSize, tForce, tAuto = 16, 50, false
local function terr(action, payload, what)
  local r, err = api(action, payload)
  if not r then say(what .. ": " .. tostring(err), true) logAdd("Error", what .. ": " .. tostring(err)) return end
  markEdit()
  say(r.msg and tostring(r.msg) or (what .. " done."))
end
on("T2_Generate", function()
  local c = frontPos(24, 0)
  terr("TerrainFill", { shape = "ball", material = "Grass", radius = tSize, center = c }, "Generate")
  if tAuto then
    terr("TerrainWater", { y = math.floor(c.y) - 8, xz = 256 }, "Auto water")
  end
end)
on("T2_Erosion", function()
  terr("TerrainFill", { op = "remove", shape = "ball", radius = math.max(2, math.floor(tSize / 2)), center = frontPos(24, 0) }, "Erosion")
end)
on("T2_Craters", function()
  terr("TerrainFill", { op = "remove", shape = "ball", radius = tSize, center = frontPos(24, 0) }, "Crater")
end)
on("T2_Flatten", function()
  local s = math.clamp(tSize * 4, 64, 256)
  terr("TerrainGenFlat", { size = s, material = "Grass" }, "Flatten " .. tostring(s) .. "x" .. tostring(s) .. " at origin")
end)
on("T2_Smooth", function()
  terr("TerrainSmooth", { center = frontPos(24, 0), radius = tSize }, "Smooth")
end)
on("T2_Noise", function()
  terr("TerrainNoise", { center = frontPos(24, 0), radius = tSize, force = tForce }, "Noise")
end)
on("T2_SizeMinus", function() tSize = math.clamp(tSize - 4, 4, 64) setText("T2_SizeVal", tSize) end)
on("T2_SizePlus", function() tSize = math.clamp(tSize + 4, 4, 64) setText("T2_SizeVal", tSize) end)
on("T2_StrMinus", function() tForce = math.clamp(tForce - 10, 0, 100) setText("T2_StrVal", tForce) end)
on("T2_StrPlus", function() tForce = math.clamp(tForce + 10, 0, 100) setText("T2_StrVal", tForce) end)
on("T2_Auto", function(o)
  tAuto = not tAuto
  o.Text = tAuto and "Auto: ON" or "Auto: OFF"
  o.TextColor3 = tAuto and GRN or MUT
  say(tAuto and "Auto water ON: Generate also lays a water plane." or "Auto water OFF.")
end)

-- ================= SELECTION / REGION / CRUMB =================
local function selectedObject()
  if selInst and selInst.Value then return selInst.Value end
  return nil
end
local function refreshSelection()
  local o = selectedObject()
  if not o then
    setText("S2_Name", "Name: —") setText("S2_Class", "Class: —")
    setText("S2_Pos", "Pos: —") setText("S2_Size", "Size: —")
    setText("O2_Crumb", "Workspace")
    setText("O2_RegionTitle", "◉ WORLD")
    setText("O2_RegionL1", "nothing selected")
    setText("O2_RegionL2", "click the Explorer") setText("O2_RegionL3", "")
    return
  end
  local okP, pos = pcall(function()
    if o:IsA("BasePart") then return o.Position end
    return o:GetPivot().Position
  end)
  local okS, sz = pcall(function()
    if o:IsA("BasePart") then return o.Size end
    return o:GetExtentsSize()
  end)
  setText("S2_Name", "Name: " .. o.Name)
  setText("S2_Class", "Class: " .. o.ClassName)
  if okP then setText("S2_Pos", string.format("Pos: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z)) end
  if okS then setText("S2_Size", string.format("Size: %.0f x %.0f x %.0f", sz.X, sz.Y, sz.Z)) end
  local full = o:GetFullName()
  local short = full:gsub("^game%.", "")
  if #short > 34 then short = "…" .. short:sub(-33) end
  setText("O2_Crumb", short)
  local kids = #o:GetChildren()
  setText("O2_RegionTitle", "◉ " .. o.Name:sub(1, 14))
  setText("O2_RegionL1", o.ClassName)
  setText("O2_RegionL2", "Children: " .. tostring(kids))
  local tail = full:match("([^%.]+%.[^%.]+)$") or full
  setText("O2_RegionL3", tail:sub(1, 20))
end

local function snapSelection()
  local st = state()
  local id = st.selectedId
  local o = selectedObject()
  if not id or not o or not o:IsA("BasePart") then
    say("Snap: select a Part first.", true) return
  end
  local p = o.Position
  local r, err = api("SetAny", { id = id, name = "Position", kind = "v",
    value = { x = math.floor(p.X + 0.5), y = math.floor(p.Y + 0.5), z = math.floor(p.Z + 0.5) } })
  if not r then say("Snap: " .. tostring(err), true) return end
  markEdit() say("Snapped to 1-stud grid.")
end

-- ================= FOOTER =================
local fpsFrames, fpsTime, fpsVal = 0, 0, 60
local function refreshFooter(dt)
  fpsFrames = fpsFrames + 1 fpsTime = fpsTime + dt
  if fpsTime >= 0.5 then
    fpsVal = math.floor(fpsFrames / fpsTime + 0.5)
    fpsFrames, fpsTime = 0, 0
    setText("F2_FPS", tostring(fpsVal))
    local pingOk, ping = pcall(function()
      return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    setText("F2_Ping", pingOk and tostring(ping) or "—")
    local memOk, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
    setText("F2_Mem", memOk and (tostring(math.floor(mem)) .. "MB") or "—")
    setText("F2_SaveState", lastEdit and ("Edited " .. lastEdit) or ("Place " .. tostring(game.PlaceId)))
  end
end

local function refreshOverlays()
  local c = cam()
  if c then
    local lv = c.CFrame.LookVector
    local yaw = math.deg(math.atan2(-lv.X, -lv.Z))
    if yaw < 0 then yaw = yaw + 360 end
    local cards = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    local card = cards[math.floor((yaw + 22.5) / 45) % 8 + 1]
    setText("O2_Compass", "▲ " .. card .. " · " .. string.format("%03d", math.floor(yaw + 0.5)) .. "°")
    local p = c.CFrame.Position
    setText("O2_Coords", string.format("X:%.0f Y:%.0f Z:%.0f", p.X, p.Y, p.Z))
  end
  local running = rt:GetAttribute("ArkherRunning") == true or gui:GetAttribute("ArkherRunning") == true
  local pb = shell:FindFirstChild("O2_Play", true)
  if pb and pb:IsA("GuiButton") then pb.Text = running and "⏹" or "▶" end
end

on("O2_Play", function() bus("RunToggle") end)
on("F2_Project", function() bus("OpenCloud") end)
on("F2_Publish", function() bus("OpenPublish") end)

-- ================= LAYERS =================
local layerState = {}
local function toggleServiceLayer(svc, prop, kind, a, b, label)
  local ok, svcObj = pcall(function() return game:GetService(svc) end)
  if not ok or not svcObj then say(label .. ": service missing.", true) return end
  local curOk, cur = pcall(function() return svcObj[prop] end)
  if not curOk then say(label .. ": unreadable.", true) return end
  local want = (cur == a) and b or a
  local r, err = api("SvcSet", { service = svc, name = prop, kind = kind, value = want })
  if not r then say(label .. ": " .. tostring(err), true) return end
  markEdit() say(label .. " → " .. tostring(want))
end
local function toggleFolderLayer(name)
  local found = workspace:FindFirstChild(name, true)
  if not found then say("No '" .. name .. "' in scene.", false) logAdd("Info", "Layer " .. name .. ": not in scene.") return end
  local parts = {}
  if found:IsA("BasePart") then parts = { found }
  else for _, d in ipairs(found:GetDescendants()) do if d:IsA("BasePart") then parts[#parts + 1] = d end end end
  if #parts == 0 then say("Layer " .. name .. ": no parts inside.", true) return end
  layerState[name] = not layerState[name]
  local hide = layerState[name]
  local n = 0
  for _, p in ipairs(parts) do
    local ok = pcall(function() p.LocalTransparencyModifier = hide and 1 or 0 end)
    if ok then n = n + 1 end
  end
  local b = shell:FindFirstChild("O2_Layer_" .. name, true)
  if b and b:IsA("GuiButton") then b.Text = (hide and "☐ " or "☑ ") .. name end
  say("Layer " .. name .. (hide and (" hidden (" .. n .. " parts).") or " shown."))
end
on("O2_Layer_Terrain", function() toggleServiceLayer("Terrain", "Decoration", "b", true, false, "Terrain grass") end)
on("O2_Layer_Water", function() toggleServiceLayer("Terrain", "WaterTransparency", "n", 0, 1, "Water") end)
on("O2_Layer_Vegetation", function() toggleFolderLayer("Vegetation") end)
on("O2_Layer_Roads", function() toggleFolderLayer("Roads") end)
on("O2_Layer_Buildings", function() toggleFolderLayer("Buildings") end)
on("O2_Layer_NPCs", function() toggleFolderLayer("NPCs") end)

-- ================= MINIMAP / GIZMO =================
on("O2_ZoomIn", function()
  local c = cam() if not c then return end
  c.FieldOfView = math.clamp(c.FieldOfView - 5, 30, 100)
  setText("O2_Fov", "FOV: " .. tostring(math.floor(c.FieldOfView)))
end)
on("O2_ZoomOut", function()
  local c = cam() if not c then return end
  c.FieldOfView = math.clamp(c.FieldOfView + 5, 30, 100)
  setText("O2_Fov", "FOV: " .. tostring(math.floor(c.FieldOfView)))
end)
on("O2_G_Move", function() clientBus:Invoke("SetMode", { key = "Move" }) end)
on("O2_G_Rotate", function() clientBus:Invoke("SetMode", { key = "Rotate" }) end)
on("O2_G_Scale", function() clientBus:Invoke("SetMode", { key = "Scale" }) end)

local gridIds, gridOn, gridBusy = {}, false, false
on("O2_G_Grid", function(o)
  if gridBusy then say("Grid: working…") return end
  if #gridIds == 0 then
    gridBusy = true say("Grid: building 3D reference…")
    for i = -5, 5 do
      for _, horiz in ipairs({ true, false }) do
        local r = api("CreateAny", { class = "Part", name = "ArkherGrid", parentName = "Workspace" })
        if r and r.id then
          gridIds[#gridIds + 1] = r.id
          local x = horiz and 0 or i * 8
          local z = horiz and i * 8 or 0
          api("SetAny", { id = r.id, name = "Position", kind = "v", value = { x = x, y = 0.5, z = z } })
          api("SetAny", { id = r.id, name = "Size", kind = "v",
            value = horiz and { x = 88, y = 0.2, z = 0.2 } or { x = 0.2, y = 0.2, z = 88 } })
          api("SetAny", { id = r.id, name = "Anchored", kind = "b", value = true })
          api("SetAny", { id = r.id, name = "CanCollide", kind = "b", value = false })
          api("SetAny", { id = r.id, name = "Color", kind = "c", value = { r = 0.2, g = 0.5, b = 1 } })
        end
      end
    end
    gridBusy = false markEdit()
    say("Grid: " .. tostring(#gridIds) .. " lines ready.")
  end
  gridOn = not gridOn
  for _, id in ipairs(gridIds) do
    api("SetAny", { id = id, name = "Transparency", kind = "n", value = gridOn and 0 or 1 })
  end
  o.TextColor3 = gridOn and GRN or TXT
  say("Grid " .. (gridOn and "ON." or "OFF."))
end)
on("O2_G_Snap", snapSelection)

-- ================= TIMELINE + CURVES =================
local tlSlot, tlKeys, tlT0, tlLoop, tlPlaying = "A", {}, nil, false, false
local function tlRedraw()
  setText("TL2_Time", "Slot " .. tlSlot .. " · keys " .. tostring(#tlKeys))
  setText("CV2_Caption", "keys: " .. tostring(#tlKeys) .. " (this session; A→lane1, B→lane2, lane3=all)")
  for i = 1, 3 do
    local lane = shell:FindFirstChild("TL2_Lane" .. i, true)
    if lane then for _, k in ipairs(lane:GetChildren()) do if k.Name == "Key" then k:Destroy() end end end
  end
  local cv = shell:FindFirstChild("CV2_Canvas", true)
  if cv then for _, k in ipairs(cv:GetChildren()) do if k.Name == "Key" then k:Destroy() end end end
  if not tlT0 then return end
  for idx, k in ipairs(tlKeys) do
    local x = math.min(680, math.floor((k.t - tlT0) * 30))
    local lanes = (k.slot == "A") and { 1, 3 } or { 2, 3 }
    for _, li in ipairs(lanes) do
      local lane = shell:FindFirstChild("TL2_Lane" .. li, true)
      if lane then
        local d = Instance.new("TextLabel")
        d.Name = "Key" d.BackgroundTransparency = 1 d.BorderSizePixel = 0
        d.Font = Enum.Font.GothamBold d.TextSize = 12
        d.TextColor3 = (k.slot == "A") and ACC or GOLD
        d.Text = "◆" d.Size = UDim2.fromOffset(14, 20)
        d.Position = UDim2.fromOffset(x, 0)
        d.Parent = lane
      end
    end
    if cv then
      local d = Instance.new("TextLabel")
      d.Name = "Key" d.BackgroundTransparency = 1 d.BorderSizePixel = 0
      d.Font = Enum.Font.GothamBold d.TextSize = 12
      d.TextColor3 = (k.slot == "A") and ACC or GOLD
      d.Text = "◆" d.Size = UDim2.fromOffset(14, 16)
      d.Position = UDim2.fromOffset(math.min(770, x), 8 + (idx % 3) * 12)
      d.Parent = cv
    end
  end
end
on("TL2_Rec", function()
  local st = state()
  local id = st.selectedId
  if not id then say("Record: select an object first.", true) return end
  local r, err = api("AnimKey", { id = id, slot = tlSlot })
  if not r then say("Record: " .. tostring(err), true) return end
  if not tlT0 then tlT0 = os.clock() end
  tlKeys[#tlKeys + 1] = { slot = tlSlot, t = os.clock(), id = id }
  markEdit() tlRedraw()
  say(r.msg and tostring(r.msg) or "Key recorded.")
end)
local function tlPlay()
  if #tlKeys == 0 then say("Timeline: record a key first (●).", true) return end
  local k = tlKeys[#tlKeys]
  local id = (state().selectedId) or k.id
  local r, err = api("AnimGo", { id = id, slot = tlSlot, dur = 2 })
  if not r then say("Play: " .. tostring(err), true) return end
  tlPlaying = true
  say(r.msg and tostring(r.msg) or "Playing.")
  if tlLoop then
    task.spawn(function()
      while tlLoop and tlPlaying do
        task.wait(2.2)
        if not (tlLoop and tlPlaying) then break end
        pcall(function() api("AnimGo", { id = id, slot = tlSlot, dur = 2 }) end)
      end
    end)
  end
end
on("TL2_Play", tlPlay)
on("TL2_Stop", function()
  tlPlaying, tlLoop = false, false
  local o = shell:FindFirstChild("TL2_Loop", true)
  if o and o:IsA("GuiButton") then o.TextColor3 = MUT end
  local r = api("AnimStop", {})
  say(r and "Stopped." or "Stop failed.", r == nil)
end)
on("TL2_Prev", function()
  tlSlot = (tlSlot == "A") and "B" or "A" tlRedraw() say("Slot " .. tlSlot .. ".")
end)
on("TL2_Next", function()
  tlSlot = (tlSlot == "A") and "B" or "A" tlRedraw() say("Slot " .. tlSlot .. ".")
end)
on("TL2_Loop", function(o)
  tlLoop = not tlLoop
  o.TextColor3 = tlLoop and GRN or MUT
  say("Loop " .. (tlLoop and "ON." or "OFF."))
  if tlLoop and not tlPlaying then tlPlay() end
end)
on("TL2_Snap", snapSelection)

-- ================= SIMULATION =================
local simRunning, simClock = false, 0
local function svcToggle(label, svc, prop, kind, a, b, btnName)
  local ok, svcObj = pcall(function() return game:GetService(svc) end)
  if not ok then say(label .. ": service missing.", true) return end
  local _, cur = pcall(function() return svcObj[prop] end)
  local want = (cur == a) and b or a
  local r, err = api("SvcSet", { service = svc, name = prop, kind = kind, value = want })
  if not r then say(label .. ": " .. tostring(err), true) return end
  markEdit()
  local onState = (want == a and a ~= cur) or (want ~= b)
  local b = shell:FindFirstChild(btnName, true)
  if b and b:IsA("GuiButton") then b.TextColor3 = onState and GRN or TXT end
  say(label .. " → " .. tostring(want))
  return want
end
on("SM2_Day", function()
  local v = svcToggle("Day cycle", "Lighting", "ClockTime", "n", 14, 0, "SM2_Day")
  if v ~= nil then setText("SM2_Day", v == 14 and "Day Cycle: DAY" or "Day Cycle: NIGHT") end
end)
on("SM2_Physics", function()
  local v = svcToggle("Physics", "Workspace", "Gravity", "n", 196.2, 0, "SM2_Physics")
  if v ~= nil then setText("SM2_Physics", v == 0 and "Physics: ZERO-G" or "Physics: ON") end
end)
on("SM2_Water", function()
  local v = svcToggle("Water FX", "Terrain", "WaterTransparency", "n", 0, 1, "SM2_Water")
  if v ~= nil then setText("SM2_Water", v == 0 and "Water FX: ON" or "Water FX: OFF") end
end)
on("SM2_Ambient", function()
  local ok, L = pcall(function() return game:GetService("Lighting") end)
  if not ok then return end
  local day = L.Ambient.R > 0.5
  local want = day and { r = 0.1, g = 0.1, b = 0.15 } or { r = 1, g = 1, b = 1 }
  local r, err = api("SvcSet", { service = "Lighting", name = "Ambient", kind = "c", value = want })
  if not r then say("Ambient: " .. tostring(err), true) return end
  markEdit()
  setText("SM2_Ambient", day and "Ambient: NIGHT" or "Ambient: DAY")
  say("Ambient → " .. (day and "NIGHT" or "DAY"))
end)
on("SM2_Start", function(o)
  simRunning = not simRunning
  o.Text = simRunning and "⏹ Stop" or "▶ Start"
  setText("SM2_Status", simRunning and "running" or "idle")
  say(simRunning and "Simulation running (day advances)." or "Simulation stopped.")
end)

-- ================= TEAM =================
local teamList = shell:FindFirstChild("TM2_List", true)
local function refreshTeam()
  local ps = Players:GetPlayers()
  local t = shell:FindFirstChild("TM2_Title", true)
  if t and t:IsA("TextLabel") then t.Text = "TEAM (" .. tostring(#ps) .. ")" end
  if not teamList then return end
  for _, k in ipairs(teamList:GetChildren()) do if k.Name == "Mate" then k:Destroy() end end
  for i, p in ipairs(ps) do
    if i > 3 then break end
    local row = Instance.new("TextLabel")
    row.Name = "Mate"
    row.BackgroundTransparency = 1 row.BorderSizePixel = 0
    row.Font = Enum.Font.Gotham row.TextSize = 12
    row.TextColor3 = (p == player) and GRN or TXT
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextTruncate = Enum.TextTruncate.AtEnd
    row.Position = UDim2.fromOffset(6, 4 + (i - 1) * 24)
    row.Size = UDim2.new(1, -12, 0, 22)
    row.Text = "● @" .. p.Name .. (p == player and " · you (Pro)" or " · guest")
    row.Parent = teamList
  end
end
on("TM2_Invite", function()
  local ok, err = pcall(function() Social:PromptGameInvite(player) end)
  say(ok and "Invite dialog opened." or ("Invite: " .. tostring(err)), not ok)
end)

-- ================= ASSETS / LIBRARY =================
local function qp(shape, name, dx, dy, dz, parentId)
  local base = frontPos(16, 3)
  local payload = { shape = shape, name = name,
    x = base.x + (dx or 0), y = base.y + (dy or 0), z = base.z + (dz or 0) }
  if parentId then payload.parentId = parentId end
  local r, err = api("QuickPart", payload)
  if not r then say(name .. ": " .. tostring(err), true) return nil end
  return r
end
local function paint(id, r, g, b)
  if id then api("SetAny", { id = id, name = "Color", kind = "c", value = { r = r, g = g, b = b } }) end
end
local function buildTree()
  local t = qp("Cylinder", "Trunk", 0, 0, 0)
  if t then paint(t.id, 0.4, 0.25, 0.1) end
  local l = qp("Ball", "Leaves", 0, 5, 0)
  if l then paint(l.id, 0.15, 0.5, 0.2) end
  markEdit() say("Tree planted in front of camera.")
end
local function buildCrate()
  local c = qp("Block", "Crate", 0, 0, 0)
  if c then paint(c.id, 0.7, 0.55, 0.3) end
  markEdit() say("Crate inserted.")
end
local function buildLamp()
  local pole = qp("Cylinder", "LampPole", 0, 0, 0)
  local bulb = qp("Ball", "LampBulb", 0, 5, 0)
  if bulb and bulb.id then
    paint(bulb.id, 1, 0.9, 0.6)
    local li = api("CreateAny", { class = "PointLight", name = "Bulb", parentId = bulb.id })
    if li and li.id then
      api("SetAny", { id = li.id, name = "Brightness", kind = "n", value = 2 })
      api("SetAny", { id = li.id, name = "Range", kind = "n", value = 16 })
    end
  end
  markEdit() say("Lamp inserted (real light).")
end
local function buildCar()
  local b = qp("Block", "CarBody", 0, 1, 0)
  if b then paint(b.id, 0.8, 0.1, 0.1) end
  for _, w in ipairs({ { -2, 0, -1 }, { 2, 0, -1 }, { -2, 0, 1 }, { 2, 0, 1 } }) do
    local wh = qp("Ball", "Wheel", w[1], w[2], w[3])
    if wh then paint(wh.id, 0.1, 0.1, 0.1) end
  end
  markEdit() say("Car inserted (5 parts).")
end
local function buildCoin()
  local c = qp("Cylinder", "Coin", 0, 1, 0)
  if c then paint(c.id, 1, 0.84, 0) end
  markEdit() say("Coin inserted.")
end
local function buildNPC()
  local m = api("CreateAny", { class = "Model", name = "NPC", parentName = "Workspace" })
  if not (m and m.id) then say("NPC failed.", true) return end
  local base = frontPos(16, 3)
  local body = api("QuickPart", { shape = "Block", name = "Body", parentId = m.id,
    x = base.x, y = base.y, z = base.z })
  if body then paint(body.id, 0.2, 0.4, 0.8) end
  api("QuickPart", { shape = "Ball", name = "Head", parentId = m.id,
    x = base.x, y = base.y + 4, z = base.z })
  markEdit() say("NPC model inserted (rig it in Animator).")
end
on("FR2_A_Tree", buildTree)
on("FR2_A_Crate", buildCrate)
on("FR2_A_Lamp", buildLamp)
on("FR2_A_Car", buildCar)
on("FR2_A_Coin", buildCoin)
on("FR2_A_NPC", buildNPC)

local function buildHouse()
  qp("Block", "Floor", 0, 0, 0)
  qp("Block", "WallN", 0, 3, -4) qp("Block", "WallS", 0, 3, 4)
  qp("Block", "WallE", 4, 3, 0) qp("Block", "WallW", -4, 3, 0)
  qp("Block", "Roof", 0, 7, 0)
  markEdit() say("House inserted (6 parts).")
end
local function buildBridge()
  qp("Block", "DeckL", -6, 1, 0) qp("Block", "DeckM", 0, 1, 0) qp("Block", "DeckR", 6, 1, 0)
  qp("Cylinder", "PostL", -6, -2, 0) qp("Cylinder", "PostR", 6, -2, 0)
  markEdit() say("Bridge inserted (5 parts).")
end
local function buildTower()
  for i = 0, 3 do qp("Block", "Level" .. i, 0, i * 4, 0) end
  markEdit() say("Tower inserted (4 levels).")
end
local function buildFountain()
  local b = qp("Cylinder", "Basin", 0, 0, 0)
  if b then paint(b.id, 0.6, 0.6, 0.65) end
  local w = qp("Ball", "Water", 0, 2, 0)
  if w then
    paint(w.id, 0.2, 0.5, 1)
    api("SetAny", { id = w.id, name = "Transparency", kind = "n", value = 0.5 })
    api("SetAny", { id = w.id, name = "CanCollide", kind = "b", value = false })
  end
  markEdit() say("Fountain inserted.")
end
local function buildPortal()
  qp("Block", "PostL", -3, 2, 0) qp("Block", "PostR", 3, 2, 0)
  local top = qp("Block", "Lintel", 0, 6, 0)
  if top then paint(top.id, 0.6, 0.2, 1) end
  markEdit() say("Portal inserted.")
end
on("FR2_L_House", buildHouse)
on("FR2_L_Bridge", buildBridge)
on("FR2_L_Tower", buildTower)
on("FR2_L_Fountain", buildFountain)
on("FR2_L_Portal", buildPortal)
local searchA = shell:FindFirstChild("FR2_AssetSearch", true)
if searchA and searchA:IsA("TextBox") then
  pcall(function()
    searchA.FocusLost:Connect(function(enter)
      if not enter then return end
      local q = searchA.Text:lower()
      for _, b in ipairs({ "Tree", "Crate", "Lamp", "Car", "Coin", "NPC" }) do
        local o = shell:FindFirstChild("FR2_A_" .. b, true)
        if o then o.Visible = (q == "") or (b:lower():find(q, 1, true) ~= nil) end
      end
      say(q == "" and "Asset filter cleared." or ("Assets matching '" .. searchA.Text .. "'."))
    end)
  end)
end

-- ================= RESOURCES =================
on("FR2_Export", function()
  local r, err = api("Export", {})
  if not r then say("Export: " .. tostring(err), true) return end
  _G.ArkherExportBuf = r.data
  markEdit()
  say("Exported " .. tostring(r.nodes or "?") .. " nodes (buffer ready for Import).")
  logAdd("Info", "Export: " .. tostring(r.nodes or "?") .. " nodes.")
end)
on("FR2_Import", function()
  if not _G.ArkherExportBuf then say("Import: press Export first (buffer empty).", true) return end
  local r, err = api("Import", { data = _G.ArkherExportBuf })
  if not r then say("Import: " .. tostring(err), true) return end
  markEdit() say("Imported " .. tostring(r.nodes or r.count or "?") .. " nodes.")
end)
on("FR2_Backup", function()
  local r, err = api("CloudSave", { name = "Backup " .. os.date("%H:%M") })
  if not r then say("Backup: " .. tostring(err), true) return end
  markEdit() say(r.msg and tostring(r.msg) or "Backup saved to Arkher Cloud.")
end)
on("FR2_Sync", function()
  local r, err = api("CloudList", {})
  if not r then say("Sync: " .. tostring(err), true) return end
  local n = (r.projects and #r.projects) or 0
  setText("FR2_StorageLabel", "Cloud: " .. tostring(n) .. " project(s)")
  local fill = shell:FindFirstChild("FR2_StorageFill", true)
  if fill then fill.Size = UDim2.fromOffset(math.clamp(n * 15, 8, 152), 10) end
  say("Cloud synced: " .. tostring(n) .. " project(s).")
end)
on("FR2_TabAssets", function() say("Assets tab: click an item to insert.") end)
on("FR2_TabLibrary", function() say("Library tab: 5 featured builds below.") end)
on("FR2_TabCloud", function() bus("OpenCloud") end)
on("FR2_TabTools", function(o) menu("Tools", o) end)

-- ================= QUICK TOOLS =================
on("FR2_Q1", buildCrate)
on("FR2_Q2", buildLamp)
on("FR2_Q3", function(o) menu("Audio", o) end)
on("FR2_Q4", function()
  local o = selectedObject()
  local c = cam()
  if not o or not c then say("Frame: select an object first.", true) return end
  local ok, p = pcall(function()
    if o:IsA("BasePart") then return o.Position end
    return o:GetPivot().Position
  end)
  if not ok then say("Frame failed.", true) return end
  c.CFrame = CFrame.new(p + Vector3.new(10, 8, 10), p)
  say("Camera framed on " .. o.Name .. ".")
end)
on("FR2_Q5", function(o) menu("FX", o) end)
on("FR2_Q6", function()
  local r, err = api("SvcSet", { service = "Terrain", name = "WaterTransparency", kind = "n", value = 0 })
  say(r and "Water FX on." or ("Water: " .. tostring(err)), r == nil)
end)
on("FR2_Q7", buildTree)
on("FR2_Q8", buildCar)
on("FR2_Q9", function() bus("OpenPublish") end)

-- ================= LOOPS =================
local selT, teamT, ovT = 0, 99, 99
Run.Heartbeat:Connect(function(dt)
  refreshFooter(dt)
  selT = selT + dt
  if selT >= 0.3 then selT = 0 pcall(refreshSelection) end
  ovT = ovT + dt
  if ovT >= 0.5 then ovT = 0 pcall(refreshOverlays) end
  teamT = teamT + dt
  if teamT >= 5 then teamT = 0 pcall(refreshTeam) end
  if simRunning then
    simClock = simClock + dt
    if simClock >= 1 then
      simClock = 0
      local ok, L = pcall(function() return game:GetService("Lighting") end)
      if ok then
        local nt = (L.ClockTime + 0.5) % 24
        local r = api("SvcSet", { service = "Lighting", name = "ClockTime", kind = "n", value = nt })
        if r then setText("SM2_Status", string.format("running %.1fh", nt)) end
      end
    end
  end
end)

-- ================= BOOT =================
task.spawn(function()
  pcall(refreshSelection)
  pcall(refreshTeam)
  pcall(refreshOverlays)
  local r = api("CloudList", {})
  if r and r.projects and #r.projects > 0 then
    local first = r.projects[1]
    local nm = (type(first) == "table" and (first.name or first.Name)) or tostring(first)
    local pb = shell:FindFirstChild("F2_Project", true)
    if pb and pb:IsA("GuiButton") then pb.Text = "▼ " .. tostring(nm):sub(1, 18) end
    setText("FR2_StorageLabel", "Cloud: " .. tostring(#r.projects) .. " project(s)")
  end
  logAdd("Info", "Arkher Studio shell ready (EN).")
  say("Shell ready: panels + timeline + sim online.")
end)
