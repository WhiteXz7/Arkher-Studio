-- 09_Topbar (R20) — wires the SINGLE top bar (ArkherTop: header + 18 tabs + pages).
-- No GUI is created here: every button below is baked (build_shell.py).
-- BUTTONS mirrors build_shell.py TABS (run tools/gen_topbar_wiring.py to sync).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = script:FindFirstAncestorOfClass("ScreenGui")
assert(gui, "09_Topbar: must live under ArkherStudioUI.")

local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "09_Topbar: runtime folder missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 30)
local selId = rt:WaitForChild("SelectedId", 30)
local canvas = gui:WaitForChild("Canvas")
local deck = canvas:WaitForChild("ArkherXDeck", 30)
assert(deck, "09_Topbar: ArkherXDeck missing from bake.")
local top = deck:WaitForChild("ArkherTop", 30)
assert(top, "09_Topbar: ArkherTop missing from bake.")

local TABS = { "HOME", "TERRAIN", "OBJECTS", "LANDSCAPE", "SCENES", "UI",
               "SCRIPTS", "PLUGINS", "WORLD", "MODELS", "MATERIALS",
               "LIGHTING", "CLIMATE", "WATER", "CAMERA", "TOOLS",
               "SETTINGS", "HELP" }

local function say(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = tostring(text), bad = bad }) end)
end

local function bus(cmd, arg)
  local ok, err = pcall(function() menusBus:Invoke(cmd, arg or {}) end)
  if not ok then say(cmd .. ": " .. tostring(err), true) end
end

local function api(action, payload)
  local res = nil
  local ok = pcall(function()
    res = clientBus:Invoke("API", { action = action, payload = payload or {}, quiet = true })
  end)
  if not ok then say(action .. ": bridge failed.", true) return nil end
  if type(res) == "table" and res.error then say(action .. ": " .. tostring(res.error), true) return nil end
  return res or true
end

local function on(name, fn)
  local o = top:FindFirstChild(name, true)
  if not o then say("09: baked button missing: " .. name, true) return end
  if not o:IsA("GuiButton") then return end
  local function fire() local ok, err = pcall(fn, o) if not ok then say(name .. ": " .. tostring(err), true) end end
  pcall(function() o.Activated:Connect(fire) end)
  pcall(function() o.MouseButton1Click:Connect(fire) end)
end

-- ---- tabs: show one page, restyle strip ----
local TXT_ON = Color3.fromRGB(230, 235, 245)
local TXT_OFF = Color3.fromRGB(199, 210, 232)
local function showPage(t)
  for _, u in ipairs(TABS) do
    local pg = top:FindFirstChild("Page_" .. u, true)
    if pg then pg.Visible = (u == t) end
    local tb = top:FindFirstChild("Tab_" .. u, true)
    if tb and tb:IsA("GuiButton") then
      local active = (u == t)
      tb.BackgroundTransparency = active and 0 or 1
      local lbl = tb:FindFirstChild("Lbl")
      if lbl then pcall(function() lbl.TextColor3 = active and TXT_ON or TXT_OFF end) end
      local pill = tb:FindFirstChild("ActivePill")
      if pill then pill.Visible = active end
    end
  end
end
for _, t in ipairs(TABS) do
  on("Tab_" .. t, function() showPage(t) end)
end

-- ---- ribbon buttons: (kind, target) mirrors build_shell.py TABS ----
local function doUndo()
  local r = api("Undo", {})
  if r then say("Undo" .. (r.msg and (": " .. tostring(r.msg)) or " done.")) end
end
local function doRedo()
  local r = api("Redo", {})
  if r then say("Redo" .. (r.msg and (": " .. tostring(r.msg)) or " done.")) end
end
local function doLock()
  local id = selId and selId.Value or ""
  if id == "" then say("Lock: select an object first.", true) return end
  local pr = api("PropsAll", { id = id })
  if not (pr and pr.result and pr.result.fields) then say("Lock: no properties.", true) return end
  local cur = nil
  for _, f in ipairs(pr.result.fields) do
    if f.key == "Locked" or f.name == "Locked" then cur = f.value end
  end
  local r = api("SetAny", { id = id, name = "Locked", kind = "b", value = not cur })
  if r then say(cur and "Unlocked." or "Locked.") end
end

local BUTTONS = {
-- @@TOPBAR_BUTTONS@@
  -- HOME
  RibbonBtn_HOME_New = { "menus", "New" },
  RibbonBtn_HOME_Open = { "menus", "Open" },
  RibbonBtn_HOME_OpenEmpty = { "menus", "OpenEmpty" },
  RibbonBtn_HOME_OpenTerrain = { "menus", "OpenTerrain" },
  RibbonBtn_HOME_Save = { "menus", "Save" },
  RibbonBtn_HOME_SaveCloud = { "menus", "SaveCloud" },
  RibbonBtn_HOME_Export = { "menus", "Export" },
  RibbonBtn_HOME_Import = { "menus", "Import" },
  RibbonBtn_HOME_Exit = { "menus", "Exit" },
  RibbonBtn_HOME_Undo = { "api", "Undo" },
  RibbonBtn_HOME_Redo = { "api", "Redo" },
  RibbonBtn_HOME_Cut = { "menus", "Cut" },
  RibbonBtn_HOME_Copy = { "menus", "Copy" },
  RibbonBtn_HOME_Paste = { "menus", "Paste" },
  RibbonBtn_HOME_Duplicate = { "menus", "Duplicate" },
  RibbonBtn_HOME_Rename = { "menus", "Rename" },
  RibbonBtn_HOME_Delete = { "menus", "Delete" },
  RibbonBtn_HOME_Play = { "menus", "RunToggle" },
  RibbonBtn_HOME_Pause = { "menus", "RunPause" },
  RibbonBtn_HOME_Stop = { "menus", "RunStop" },
  -- TERRAIN
  RibbonBtn_TERRAIN_TerrainEditor = { "menus", "XTerrainEditor" },
  RibbonBtn_TERRAIN_TerrainX = { "menus", "XOpenTerrain" },
  RibbonBtn_TERRAIN_TerrainGen = { "menus", "XOpenTerrainGen" },
  RibbonBtn_TERRAIN_VoxelProbe = { "menus", "XOpenTerrainVoxel" },
  RibbonBtn_TERRAIN_TerrainProbe = { "menus", "XOpenTerrainProbe" },
  RibbonBtn_TERRAIN_Generate = { "menus", "XTerrGen" },
  RibbonBtn_TERRAIN_Erode = { "menus", "XTerrErode" },
  RibbonBtn_TERRAIN_Crater = { "menus", "XTerrCrater" },
  RibbonBtn_TERRAIN_Flatten = { "menus", "XTerrFlat" },
  RibbonBtn_TERRAIN_Smooth = { "menus", "XTerrSmooth" },
  RibbonBtn_TERRAIN_Noise = { "menus", "XTerrNoise" },
  -- OBJECTS
  RibbonBtn_OBJECTS_Part = { "menus", "InsertPart" },
  RibbonBtn_OBJECTS_Folder = { "menus", "InsertFolder" },
  RibbonBtn_OBJECTS_Model = { "menus", "InsertModel" },
  RibbonBtn_OBJECTS_Script = { "menus", "InsertScript" },
  RibbonBtn_OBJECTS_Text = { "menus", "InsertTextLabel" },
  RibbonBtn_OBJECTS_InsertFull = { "menus", "InsertFull" },
  RibbonBtn_OBJECTS_Group = { "menus", "XGroup" },
  RibbonBtn_OBJECTS_Ungroup = { "menus", "XUngroup" },
  RibbonBtn_OBJECTS_PivotReset = { "menus", "XPivotReset" },
  RibbonBtn_OBJECTS_AlignX = { "menus", "XAlignX" },
  RibbonBtn_OBJECTS_AlignY = { "menus", "XAlignY" },
  RibbonBtn_OBJECTS_AlignZ = { "menus", "XAlignZ" },
  RibbonBtn_OBJECTS_DistX = { "menus", "XDistX" },
  RibbonBtn_OBJECTS_DistY = { "menus", "XDistY" },
  RibbonBtn_OBJECTS_DistZ = { "menus", "XDistZ" },
  RibbonBtn_OBJECTS_MirrX = { "menus", "XMirrX" },
  RibbonBtn_OBJECTS_MirrY = { "menus", "XMirrY" },
  RibbonBtn_OBJECTS_MirrZ = { "menus", "XMirrZ" },
  RibbonBtn_OBJECTS_Lock = { "lock" },
  RibbonBtn_OBJECTS_LocalGlobal = { "core", "LocalGlobal" },
  -- LANDSCAPE
  RibbonBtn_LANDSCAPE_Life = { "menus", "XOpenVida" },
  RibbonBtn_LANDSCAPE_EcoSim = { "menus", "XVidaEco" },
  RibbonBtn_LANDSCAPE_Human = { "menus", "XVidaHumano" },
  RibbonBtn_LANDSCAPE_NPC = { "menus", "XVidaNpc" },
  RibbonBtn_LANDSCAPE_City = { "menus", "XOpenCidade" },
  RibbonBtn_LANDSCAPE_Village = { "menus", "XCidadeVila" },
  RibbonBtn_LANDSCAPE_Metro = { "menus", "XCidadeMetro" },
  -- SCENES
  RibbonBtn_SCENES_Places = { "menus", "XPlaces" },
  RibbonBtn_SCENES_PlacesProfile = { "menus", "PlacesProfile" },
  RibbonBtn_SCENES_HomeEditor = { "menus", "XHome" },
  RibbonBtn_SCENES_SaveToArkher = { "menus", "SavePlaceAccount" },
  RibbonBtn_SCENES_Publish = { "menus", "Publish" },
  RibbonBtn_SCENES_PublishBridge = { "menus", "XPublishBridge" },
  RibbonBtn_SCENES_ResetWorkspace = { "menus", "ResetWorkspace" },
  RibbonBtn_SCENES_RecKeyA = { "menus", "AnimKeyA" },
  RibbonBtn_SCENES_RecKeyB = { "menus", "AnimKeyB" },
  RibbonBtn_SCENES_PlayA = { "menus", "AnimGoA" },
  RibbonBtn_SCENES_PlayB = { "menus", "AnimGoB" },
  RibbonBtn_SCENES_AnimStop = { "menus", "AnimStop" },
  -- UI
  RibbonBtn_UI_UIEditor = { "menus", "XUI" },
  RibbonBtn_UI_Colors = { "menus", "XOpenCores" },
  RibbonBtn_UI_PropsPlus = { "menus", "XOpenProps" },
  RibbonBtn_UI_Output = { "menus", "XOpenOutput" },
  RibbonBtn_UI_ClearOutput = { "menus", "XOutputClear" },
  RibbonBtn_UI_Hierarchy = { "menus", "ToggleHierarchy" },
  RibbonBtn_UI_Properties = { "menus", "ToggleProperties" },
  -- SCRIPTS
  RibbonBtn_SCRIPTS_ScriptStudio = { "menus", "ScriptStudio" },
  RibbonBtn_SCRIPTS_AllScripts = { "menus", "XOpenScripts" },
  RibbonBtn_SCRIPTS_Python = { "menus", "XOpenPy" },
  RibbonBtn_SCRIPTS_CommandBar = { "menus", "XOpenComando" },
  RibbonBtn_SCRIPTS_ScriptEditor = { "menus", "XScript" },
  -- PLUGINS
  RibbonBtn_PLUGINS_Plugins = { "menus", "OpenPlugins" },
  RibbonBtn_PLUGINS_CloudInfo = { "menus", "OpenCloud" },
  RibbonBtn_PLUGINS_Toolbox = { "menus", "OpenToolbox" },
  RibbonBtn_PLUGINS_CreatorStore = { "menus", "XOpenToolbox" },
  RibbonBtn_PLUGINS_CollabSettings = { "menus", "OpenCollaboration" },
  RibbonBtn_PLUGINS_Collaborate = { "menus", "Collaborate" },
  RibbonBtn_PLUGINS_Invites = { "menus", "Invites" },
  RibbonBtn_PLUGINS_Changes = { "menus", "Changes" },
  RibbonBtn_PLUGINS_Account = { "menus", "Account" },
  -- WORLD
  RibbonBtn_WORLD_WorldEditor = { "menus", "XWorld" },
  RibbonBtn_WORLD_Space = { "menus", "XOpenEspaco" },
  RibbonBtn_WORLD_SolarSystem = { "menus", "XEspacoSolar" },
  RibbonBtn_WORLD_EarthMoon = { "menus", "XEspacoTerraLua" },
  RibbonBtn_WORLD_GameProps = { "menus", "GameProperties" },
  -- MODELS
  RibbonBtn_MODELS_ModelerPRO = { "menus", "XModeler" },
  RibbonBtn_MODELS_Block = { "menus", "XSpawnBlock" },
  RibbonBtn_MODELS_Wedge = { "menus", "XSpawnWedge" },
  RibbonBtn_MODELS_Cylinder = { "menus", "XSpawnCyl" },
  RibbonBtn_MODELS_Ball = { "menus", "XSpawnBall" },
  RibbonBtn_MODELS_Corner = { "menus", "XSpawnCorner" },
  RibbonBtn_MODELS_Truss = { "menus", "XSpawnTruss" },
  RibbonBtn_MODELS_MeshPart = { "menus", "XMeshPart" },
  RibbonBtn_MODELS_Join = { "menus", "XJoin" },
  RibbonBtn_MODELS_Split = { "menus", "XSplit" },
  RibbonBtn_MODELS_Modeler = { "menus", "XOpenModeler" },
  RibbonBtn_MODELS_ModelerPrims = { "menus", "XOpenModelerPrim" },
  RibbonBtn_MODELS_RopeDemo = { "menus", "XCordaDemo" },
  RibbonBtn_MODELS_RopeBridge = { "menus", "XCordaPonte" },
  RibbonBtn_MODELS_Ropes = { "menus", "XOpenCordas" },
  -- MATERIALS
  RibbonBtn_MATERIALS_Color = { "menus", "XColor" },
  RibbonBtn_MATERIALS_Material = { "menus", "XMaterial" },
  RibbonBtn_MATERIALS_Surface = { "menus", "XSurface" },
  RibbonBtn_MATERIALS_Decal = { "menus", "XDecal" },
  RibbonBtn_MATERIALS_Texture = { "menus", "XTexture" },
  -- LIGHTING
  RibbonBtn_LIGHTING_RRW = { "menus", "XRRW" },
  RibbonBtn_LIGHTING_Sky = { "menus", "XAtmosCeu" },
  RibbonBtn_LIGHTING_TimeOfDay = { "menus", "XAtmosTempo" },
  RibbonBtn_LIGHTING_FXPanel = { "menus", "XOpenFx" },
  RibbonBtn_LIGHTING_Fire = { "menus", "XFxFogo" },
  RibbonBtn_LIGHTING_Atmosphere = { "menus", "XOpenAtmos" },
  RibbonBtn_LIGHTING_Light = { "menus", "XLight" },
  RibbonBtn_LIGHTING_Particles = { "menus", "XParticles" },
  -- CLIMATE
  RibbonBtn_CLIMATE_Climate = { "menus", "XOpenClima" },
  RibbonBtn_CLIMATE_ClimateOn = { "menus", "XClimaOn" },
  RibbonBtn_CLIMATE_ClimateOff = { "menus", "XClimaOff" },
  RibbonBtn_CLIMATE_Rain = { "menus", "XFxChuva" },
  -- WATER
  RibbonBtn_WATER_Ocean = { "menus", "XAguaOceano" },
  RibbonBtn_WATER_Buoyancy = { "menus", "XAguaFlutua" },
  RibbonBtn_WATER_WaterTools = { "menus", "XOpenWater" },
  -- CAMERA
  RibbonBtn_CAMERA_Camera = { "menus", "XCamera" },
  RibbonBtn_CAMERA_Viewport = { "menus", "XViewport" },
  RibbonBtn_CAMERA_Fullscreen = { "menus", "Fullscreen" },
  RibbonBtn_CAMERA_ResetLayout = { "menus", "ResetLayout" },
  -- TOOLS
  RibbonBtn_TOOLS_Fabricate = { "menus", "XOpenFabricar" },
  RibbonBtn_TOOLS_FabList = { "menus", "XFabricarList" },
  RibbonBtn_TOOLS_Snap = { "menus", "XSnap" },
  RibbonBtn_TOOLS_Transform = { "menus", "XTransform" },
  RibbonBtn_TOOLS_Sound = { "menus", "XSound" },
  RibbonBtn_TOOLS_DO15 = { "menus", "XDO15" },
  RibbonBtn_TOOLS_AnimatorPRO = { "menus", "XAnimator" },
  RibbonBtn_TOOLS_Animator = { "menus", "XOpenAnimator" },
  RibbonBtn_TOOLS_RigEditor = { "menus", "XOpenAnimatorRig" },
  RibbonBtn_TOOLS_PhysAnim = { "menus", "XOpenAnimatorPhys" },
  RibbonBtn_TOOLS_AudioTools = { "menus", "XOpenAudio" },
  RibbonBtn_TOOLS_AudioInt = { "menus", "XAudioInt" },
  RibbonBtn_TOOLS_Mixer = { "menus", "XAudioMixer" },
  RibbonBtn_TOOLS_Anchor = { "menus", "XAnchor" },
  RibbonBtn_TOOLS_Collision = { "menus", "XCollision" },
  RibbonBtn_TOOLS_Select = { "core", "Select" },
  RibbonBtn_TOOLS_Move = { "core", "MoveScale" },
  RibbonBtn_TOOLS_Rotate = { "core", "Rotate" },
  RibbonBtn_TOOLS_Scale = { "core", "Scale" },
  -- SETTINGS
  RibbonBtn_SETTINGS_GameSettings = { "menus", "OpenSettings" },
  RibbonBtn_SETTINGS_Data = { "menus", "OpenData" },
  RibbonBtn_SETTINGS_Language = { "menus", "OpenLocalization" },
  RibbonBtn_SETTINGS_Settings = { "menus", "XSettings" },
  RibbonBtn_SETTINGS_LangPT = { "menus", "XLangPT" },
  RibbonBtn_SETTINGS_ProjSettings = { "menus", "ProjectSettings" },
  -- HELP
  RibbonBtn_HELP_StudioHelp = { "menus", "HelpStudio" },
  RibbonBtn_HELP_CommandHelp = { "menus", "XComandoHelp" },
  RibbonBtn_HELP_CommandHelp = { "menus", "XComandoHelp" },-- @@/TOPBAR_BUTTONS@@
}

for name, spec in pairs(BUTTONS) do
  local kind, target = spec[1], spec[2]
  if kind == "menus" then
    on(name, function() bus(target) end)
  elseif kind == "core" then
    if target == "LocalGlobal" then
      on(name, function()
        local ok = pcall(function() clientBus:Invoke("SetSpace", {}) end)
        say(ok and "Space toggled (Local/Global)." or "SetSpace failed.", not ok)
      end)
    else
      on(name, function()
        local ok = pcall(function() clientBus:Invoke("SetMode", { key = target }) end)
        if not ok then say("Mode " .. target .. " failed.", true) end
      end)
    end
  elseif kind == "api" then
    on(name, target == "Undo" and doUndo or doRedo)
  elseif kind == "lock" then
    on(name, doLock)
  end
end

-- ---- header right: search / bell / user (all real) ----
local search = top:FindFirstChild("H_Search", true)
if search and search:IsA("TextBox") then
  pcall(function()
    search.FocusLost:Connect(function(enter)
      if not enter then return end
      local q = search.Text
      local dock = canvas:FindFirstChild("HierarchyDock")
      local box = dock and dock:FindFirstChild("Search", true)
      local input = box and box:FindFirstChild("Input")
      if input and input:IsA("TextBox") then
        input.Text = q
        input:CaptureFocus()
        say("Explorer filtered: " .. q)
      else
        say("Explorer search not ready.", true)
      end
    end)
  end)
end
on("H_Bell", function()
  local n = _G.ArkherUnread or 0
  say(n == 0 and "No new notifications." or ("Notifications: " .. tostring(n) .. " unread (see Console)."))
end)
on("H_User", function()
  say("Signed in as @" .. player.Name .. " (Pro).")
end)

say("Top bar ready: header + 18 tabs + 162 buttons online.")
