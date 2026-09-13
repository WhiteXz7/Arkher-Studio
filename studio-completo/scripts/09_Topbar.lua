-- 09_Topbar (REBUILD EN) — wires MenuBar2 + Ribbon2 (ArkherShell2) to real buses.
-- No GUI is created here: every button below is baked (build_shell2.py).
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = script:FindFirstAncestorOfClass("ScreenGui")
assert(gui, "09_Topbar: must live under ArkherStudioUI.")

local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
assert(rt, "09_Topbar: runtime folder missing (01_Nucleo must boot first).")
local clientBus = rt:WaitForChild("ClientBus", 30)
local menusBus = rt:WaitForChild("MenusBus", 30)
local coreReady = rt:WaitForChild("CoreReady", 30)
local menusReady = rt:WaitForChild("MenusReady", 30)
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "09_Topbar: ArkherShell2 missing from bake.")

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
  local res, err = nil, nil
  local ok = pcall(function()
    res = clientBus:Invoke("API", { action = action, payload = payload or {}, quiet = true })
  end)
  if not ok then say(action .. ": bridge failed.", true) return nil end
  if type(res) == "table" and res.error then say(action .. ": " .. tostring(res.error), true) return nil end
  return res or true
end

local function on(name, fn)
  local o = shell:FindFirstChild(name, true)
  if not o then say("09: baked button missing: " .. name, true) return end
  if not o:IsA("GuiButton") then return end
  local function fire() local ok, err = pcall(fn, o) if not ok then say(name .. ": " .. tostring(err), true) end end
  pcall(function() o.Activated:Connect(fire) end)
  pcall(function() o.MouseButton1Click:Connect(fire) end)
end

-- ---- menu bar: 12 dropdowns (entries live in 03_Menus MENUS.*) ----
for _, m in ipairs({ "Assets", "Models", "Terrain", "Animation", "Audio", "Scripts",
                     "UI", "FX", "Lighting", "Gameplay", "Physics", "Tools" }) do
  on("M2_" .. m, function(o) menu(m, o) end)
end

-- ---- ribbon: transform modes (real, via 01_Nucleo) ----
on("R2_Select", function() clientBus:Invoke("SetMode", { key = "Select" }) end)
on("R2_Move", function() clientBus:Invoke("SetMode", { key = "Move" }) end)
on("R2_Scale", function() clientBus:Invoke("SetMode", { key = "Scale" }) end)
on("R2_Rotate", function() clientBus:Invoke("SetMode", { key = "Rotate" }) end)

-- ---- ribbon: play controls (real, via 03_Menus Run handlers) ----
on("R2_Play", function() bus("RunToggle") end)
on("R2_Pause", function() bus("RunPause") end)
on("R2_Stop", function() bus("RunStop") end)

-- ---- ribbon: undo/redo (real server history) ----
on("R2_Undo", function()
  local r = api("Undo", {})
  if r then say("Undo" .. (r.msg and (": " .. tostring(r.msg)) or " done.")) end
end)
on("R2_Redo", function()
  local r = api("Redo", {})
  if r then say("Redo" .. (r.msg and (": " .. tostring(r.msg)) or " done.")) end
end)

-- ---- ribbon: menu shortcuts ----
on("R2_Terrain", function(o) menu("Terrain", o) end)
on("R2_Insert", function() bus("Insert") end)
on("R2_Script", function(o) menu("Scripts", o) end)
on("R2_UI", function(o) menu("UI", o) end)
on("R2_Animate", function(o) menu("Animation", o) end)
on("R2_FX", function(o) menu("FX", o) end)

-- ---- ribbon: save / publish / help ----
on("R2_Save", function() bus("Save") end)
on("R2_Publish", function() bus("OpenPublish") end)
on("R2_Help", function(o) menu("Tools", o) say("Help lives in Tools > Studio Help.") end)

-- ---- menu bar right: search / bell / user (all real) ----
local search = shell:FindFirstChild("M2_Search", true)
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

say("Top bar ready: 12 menus + ribbon online.")
