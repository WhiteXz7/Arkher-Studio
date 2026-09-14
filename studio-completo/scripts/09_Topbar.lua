-- 09_Topbar (R18) — wires the SINGLE top bar (ArkherTop: menus + tabs + pages).
-- No GUI is created here: every button below is baked (build_shell.py).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = script:FindFirstAncestorOfClass("ScreenGui")
assert(gui, "09_Topbar: must live under ArkherStudioUI.")

local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "09_Topbar: runtime folder missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 30)
local menusReady = rt:WaitForChild("MenusReady", 30)
local selId = rt:WaitForChild("SelectedId", 30)
local canvas = gui:WaitForChild("Canvas")
local deck = canvas:WaitForChild("ArkherXDeck", 30)
assert(deck, "09_Topbar: ArkherXDeck missing from bake.")
local top = deck:WaitForChild("ArkherTop", 30)
assert(top, "09_Topbar: ArkherTop missing from bake.")

local TABS = { "FILE", "EDIT", "INSERT", "CREATE", "RUN", "TRANSFORM",
               "SETTINGS", "PLUGINS", "TEAM" }

local function say(text, bad)
  pcall(function() clientBus:Invoke("Message", { text = tostring(text), bad = bad }) end)
end

local function menu(name, button)
  if not menusReady.Value then say("Menus still starting…", true) return end
  local ok, err = pcall(function()
    menusBus:Invoke("Menu", { name = name, button = button })
  end)
  if not ok then say("Menu " .. name .. ": " .. tostring(err), true) end
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

-- ---- menu row: 18 dropdowns (classic 6 + X 12; entries live in 03_Menus MENUS.*) ----
for _, m in ipairs({ "File", "Edit", "View", "Insert", "Run", "Game",
                     "Assets", "Models", "Terrain", "Animation", "Audio", "Scripts",
                     "UI", "FX", "Lighting", "Gameplay", "Physics", "Tools" }) do
  on("M2_" .. m, function(o) menu(m, o) end)
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
      tb.TextColor3 = active and TXT_ON or TXT_OFF
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
  -- FILE
  RibbonBtn_FILE_Save = { "menus", "Save" },
  RibbonBtn_FILE_Open = { "menus", "Open" },
  RibbonBtn_FILE_SaveToArkher = { "menus", "SavePlaceAccount" },
  RibbonBtn_FILE_Publish = { "menus", "OpenPublish" },
  RibbonBtn_FILE_Help = { "menus", "HelpStudio" },
  -- EDIT
  RibbonBtn_EDIT_Undo = { "api", "Undo" },
  RibbonBtn_EDIT_Redo = { "api", "Redo" },
  RibbonBtn_EDIT_Anchor = { "menus", "XAnchor" },
  RibbonBtn_EDIT_Snap = { "menus", "XSnap" },
  RibbonBtn_EDIT_Group = { "menus", "XGroup" },
  RibbonBtn_EDIT_Ungroup = { "menus", "XUngroup" },
  -- INSERT
  RibbonBtn_INSERT_Model = { "menus", "InsertModel" },
  RibbonBtn_INSERT_Folder = { "menus", "InsertFolder" },
  RibbonBtn_INSERT_Script = { "menus", "InsertScript" },
  RibbonBtn_INSERT_Text = { "menus", "InsertTextLabel" },
  -- CREATE
  RibbonBtn_CREATE_Terrain = { "menu", "Terrain" },
  RibbonBtn_CREATE_Insert = { "menus", "Insert" },
  RibbonBtn_CREATE_Script = { "menu", "Scripts" },
  RibbonBtn_CREATE_UI = { "menu", "UI" },
  RibbonBtn_CREATE_Animate = { "menu", "Animation" },
  RibbonBtn_CREATE_FX = { "menu", "FX" },
  -- RUN
  RibbonBtn_RUN_Play = { "menus", "RunToggle" },
  RibbonBtn_RUN_Pause = { "menus", "RunPause" },
  RibbonBtn_RUN_Stop = { "menus", "RunStop" },
  -- TRANSFORM
  RibbonBtn_TRANSFORM_Select = { "core", "Select" },
  RibbonBtn_TRANSFORM_MoveScale = { "core", "MoveScale" },
  RibbonBtn_TRANSFORM_Rotate = { "core", "Rotate" },
  RibbonBtn_TRANSFORM_Scale = { "core", "Scale" },
  RibbonBtn_TRANSFORM_Transform = { "menus", "XTransform" },
  RibbonBtn_TRANSFORM_Lock = { "lock" },
  RibbonBtn_TRANSFORM_LocalGlobal = { "core", "LocalGlobal" },
  -- SETTINGS
  RibbonBtn_SETTINGS_Data = { "menus", "OpenData" },
  RibbonBtn_SETTINGS_Localization = { "menus", "OpenLocalization" },
  RibbonBtn_SETTINGS_Settings = { "menus", "XSettings" },
  -- PLUGINS
  RibbonBtn_PLUGINS_ArkherCloud = { "menus", "OpenCloud" },
  RibbonBtn_PLUGINS_PluginToolbar = { "menus", "OpenPlugins" },
  -- TEAM
  RibbonBtn_TEAM_Toolbox = { "menus", "OpenToolbox" },
  RibbonBtn_TEAM_CollaborationSettings = { "menus", "OpenCollaboration" },
  RibbonBtn_TEAM_Collaborate = { "menus", "Collaborate" },
  RibbonBtn_TEAM_Invites = { "menus", "Invites" },
  RibbonBtn_TEAM_Changes = { "menus", "Changes" },
  RibbonBtn_TEAM_Account = { "menus", "Account" },
}

for name, spec in pairs(BUTTONS) do
  local kind, target = spec[1], spec[2]
  if kind == "menus" then
    on(name, function() bus(target) end)
  elseif kind == "menu" then
    on(name, function(o) menu(target, o) end)
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

-- ---- menu row right: search / bell / user (all real) ----
local search = top:FindFirstChild("M2_Search", true)
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
on("M2_Bell", function()
  local n = _G.ArkherUnread or 0
  say(n == 0 and "No new notifications." or ("Notifications: " .. tostring(n) .. " unread (see Console)."))
end)
on("M2_User", function()
  say("Signed in as @" .. player.Name .. " (Pro).")
end)

say("Top bar ready: 18 menus + 9 tabs + 42 buttons online.")
