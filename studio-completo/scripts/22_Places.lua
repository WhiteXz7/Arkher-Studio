-- 22_Places (R16) — Places: lista/teleport/cria/cutscene real (TweenService).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local player = Players.LocalPlayer
local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
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
local PANELS = { "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local DESK = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status",
  "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status",
  "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status" }
local OTHER_M = { "M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO", "M_HO", "M_SC" }
local S = { open = false, places = {}, idx = 0, cutA = nil, cutB = nil,
  tween = nil, fade = nil, oldType = nil, playing = false }
local function platform()
  local ok, ai = pcall(function() return _G.ArkherInput end)
  if ok and ai and ai.platform then
    local ok2, p = pcall(ai.platform)
    if ok2 and p then return p end
  end
  return "PC"
end
local refreshPlaces
local stopCut
local function setOpen(v)
  S.open = v
  for _, n in ipairs(PANELS) do vis(n, v) end
  for _, n in ipairs(DESK) do vis(n, not v) end
  if v then
    for _, n in ipairs(OTHER_EDS) do vis(n, false) end
    for _, n in ipairs(OTHER_M) do vis(n, false) end
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherHome", "ArkherScript" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    vis("M_PL", platform() == "Mobile")
    refreshPlaces()
    say("Places open.")
  else
    if S.playing then stopCut() end
    vis("M_PL", false)
    say("Places closed.")
  end
end

-- ============ list + teleport ============
local function showPlace()
  local pl = S.places[S.idx]
  if not pl then
    setText("PL12_L_Info", "no places")
    setText("PL12_StatL", "places · 0")
    return
  end
  setText("PL12_L_Info", string.format("%s\nid %s (%d/%d)",
    tostring(pl.name), tostring(pl.placeId), S.idx, #S.places))
  setText("PL12_StatL", string.format("places · %d", #S.places))
end
refreshPlaces = function()
  local r, err = api("PlaceList", {})
  if err then
    setText("PL12_L_Info", "offline? " .. tostring(err):sub(1, 50))
    say("Places: " .. tostring(err), true)
    return
  end
  S.places = r.places or {}
  if S.idx > #S.places then S.idx = #S.places end
  if S.idx == 0 and #S.places > 0 then S.idx = 1 end
  showPlace()
end
on("PL12_L_Refresh", refreshPlaces)
on("PL12_L_Prev", function()
  if #S.places == 0 then return end
  S.idx = ((S.idx - 2) % #S.places) + 1
  showPlace()
end)
on("PL12_L_Next", function()
  if #S.places == 0 then return end
  S.idx = (S.idx % #S.places) + 1
  showPlace()
end)
local function goTeleport(pid)
  pid = tonumber(pid or 0) or 0
  if pid <= 0 then say("GO: bad placeId.", true) return end
  local r, err = api("TeleportTo", { placeId = pid })
  if err then say("GO: " .. tostring(err), true) return end
  say("Teleporting to " .. pid .. "...")
end
on("PL12_L_Go", function()
  local pl = S.places[S.idx]
  if not pl then say("GO: none.", true) return end
  goTeleport(pl.placeId)
end)
on("PL12_L_GoId", function()
  local txt = ""
  pcall(function() txt = find("PL12_L_Id").Text or "" end)
  goTeleport(txt)
end)

-- ============ new place ============
on("PL12_N_Create", function()
  local name = ""
  pcall(function() name = find("PL12_N_Name").Text or "" end)
  if #name < 3 then say("Create: name 3+.", true) return end
  local tpl = ""
  pcall(function() tpl = find("PL12_N_Tpl").Text or "" end)
  local arg = { name = name, description = "Criado com Arkher Studio" }
  if tonumber(tpl) then arg.template = tonumber(tpl) end
  local r, err = api("PlaceCreate", arg)
  if err then
    setText("PL12_N_Info", tostring(err):sub(1, 80))
    say("Create: " .. tostring(err), true)
    return
  end
  setText("PL12_N_Info", "id " .. tostring(r.placeId))
  print("[ArkherPlaces] new place: " .. tostring(r.url or r.placeId))
  say("Place created: " .. tostring(r.placeId))
  refreshPlaces()
end)

-- ============ cutscene (real TweenService + fade frame + restore) ============
local function cutInfo()
  local a = S.cutA and "A ok" or "A--"
  local b = S.cutB and "B ok" or "B--"
  setText("PL12_C_Info", a .. " " .. b .. (S.playing and " PLAY" or ""))
end
on("PL12_C_A", function()
  local cam = workspace.CurrentCamera
  if not cam then say("A: no camera.", true) return end
  S.cutA = cam.CFrame
  cutInfo()
end)
on("PL12_C_B", function()
  local cam = workspace.CurrentCamera
  if not cam then say("B: no camera.", true) return end
  S.cutB = cam.CFrame
  cutInfo()
end)
stopCut = function()
  if S.tween then pcall(function() S.tween:Cancel() end) end
  S.tween = nil
  S.playing = false
  if S.fade then pcall(function() S.fade:Destroy() end) end
  S.fade = nil
  local cam = workspace.CurrentCamera
  if cam and S.oldType then
    pcall(function() cam.CameraType = S.oldType end)
  end
  S.oldType = nil
  cutInfo()
  say("Cutscene stopped.")
end
on("PL12_C_Stop", function() stopCut() end)
on("PL12_C_Play", function()
  if S.playing then say("Cutscene busy.", true) return end
  if not (S.cutA and S.cutB) then say("Play: set A+B.", true) return end
  local cam = workspace.CurrentCamera
  if not cam then say("Play: no camera.", true) return end
  local secs = 3
  pcall(function() secs = tonumber(find("PL12_C_T").Text) or 3 end)
  secs = math.max(0.5, math.min(30, secs))
  S.oldType = cam.CameraType
  local okCam, errCam = pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
  if not okCam then say("Play: " .. tostring(errCam), true) return end
  local fade = Instance.new("Frame")
  local okFade = pcall(function()
    fade.Name = "ArkherCutFade"
    fade.Size = UDim2.fromScale(1, 1)
    fade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    fade.BackgroundTransparency = 1
    fade.BorderSizePixel = 0
    fade.ZIndex = 500
    fade.Parent = gui
  end)
  if okFade then S.fade = fade end
  cam.CFrame = S.cutA
  local tw
  local okTw, errTw = pcall(function()
    tw = TS:Create(cam, TweenInfo.new(secs, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
      { CFrame = S.cutB })
  end)
  if not okTw or not tw then
    if S.fade then pcall(function() S.fade:Destroy() end) end
    S.fade = nil
    pcall(function() cam.CameraType = S.oldType end)
    S.oldType = nil
    say("Play: " .. tostring(errTw or "TweenService fail"), true)
    return
  end
  S.tween = tw
  S.playing = true
  cutInfo()
  if S.fade then
    pcall(function()
      TS:Create(S.fade, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
    end)
  end
  local done = false
  local function finish()
    if done then return end
    done = true
    S.tween = nil
    S.playing = false
    pcall(function() cam.CameraType = S.oldType end)
    S.oldType = nil
    local f = S.fade
    S.fade = nil
    if f then
      local ok2, tw2 = pcall(function()
        return TS:Create(f, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
      end)
      if ok2 and tw2 then
        pcall(function()
          tw2.Completed:Connect(function() pcall(function() f:Destroy() end) end)
          tw2:Play()
        end)
      else
        pcall(function() f:Destroy() end)
      end
    end
    cutInfo()
    say("Cutscene done.")
  end
  pcall(function()
    tw.Completed:Connect(function() finish() end)
    tw:Play()
  end)
end)

-- ============ mobile ============
on("M_PL_Go", function()
  local pl = S.places[S.idx]
  if not pl then say("GO: none.", true) return end
  goTeleport(pl.placeId)
end)
on("M_PL_A", function()
  local cam = workspace.CurrentCamera
  if not cam then say("A: no camera.", true) return end
  S.cutA = cam.CFrame
  cutInfo()
end)
on("M_PL_Play", function()
  -- same logic as PL12_C_Play, 3s default, no fade
  local cam = workspace.CurrentCamera
  if S.playing then say("Cutscene busy.", true) return end
  if not (S.cutA and S.cutB) then say("Play: set A+B.", true) return end
  if not cam then say("Play: no camera.", true) return end
  S.oldType = cam.CameraType
  local okCam = pcall(function() cam.CameraType = Enum.CameraType.Scriptable end)
  if not okCam then say("Play: cam fail.", true) return end
  cam.CFrame = S.cutA
  local tw
  local okTw = pcall(function()
    tw = TS:Create(cam, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
      { CFrame = S.cutB })
  end)
  if not okTw or not tw then
    pcall(function() cam.CameraType = S.oldType end)
    S.oldType = nil
    say("Play: Tween fail.", true)
    return
  end
  S.tween = tw
  S.playing = true
  cutInfo()
  local done = false
  pcall(function()
    tw.Completed:Connect(function()
      if done then return end
      done = true
      S.tween = nil
      S.playing = false
      pcall(function() cam.CameraType = S.oldType end)
      S.oldType = nil
      cutInfo()
      say("Cutscene done.")
    end)
    tw:Play()
  end)
end)

-- ============ boot ============
cutInfo()
on("PL12_Close", function() setOpen(false) end)
rawset(_G, "ArkherPlaces", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
})
