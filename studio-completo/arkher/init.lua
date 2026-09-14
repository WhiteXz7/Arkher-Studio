-- arkher/init.lua — engine boot (runs last in bootstrap).
local E = _G.ARKHER
-- toast (status bar + floating)
function E.toast(msg)
  msg = tostring(msg)
  pcall(function() E.shell.status(msg) end)
  print("[ARKHER] " .. msg)
  pcall(function()
    local g = E.shell.root()
    if not g then return end
    local th = E.shell.theme()
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(0, 320, 0, 30) f.Position = UDim2.new(0.5, -160, 0, 200)
    f.BackgroundColor3 = th.bg f.TextColor3 = th.text f.Font = Enum.Font.GothamBold f.TextSize = 13
    f.Text = msg f.BorderSizePixel = 1 f.BorderColor3 = th.accent f.ZIndex = 150
    f.Parent = g
    game:GetService("Debris"):AddItem(f, 2.5)
  end)
end
-- boot sequence
E.store.load()
E.cmd.init(E.registry)
-- registry is filled by build order (tabs loaded before init)
local ok, errs, n = E.registry.validate(E.ACTIONS, E.icons)
if not ok then
  E.out.err("registry: " .. #errs .. " errors")
  for i = 1, math.min(10, #errs) do E.out.err("  " .. errs[i]) end
else
  E.out.log("registry OK: 30 tabs x 40 = " .. n .. " commands.")
end
local built = E.shell.build()
if not built then
  warn("[ARKHER] No PlayerGui/CoreGui; engine loaded headless.")
else
  E.shortcuts.build()
  E.mode.set("Select")
  E.panel.open("welcome", {})
  -- autosave loop
  coroutine.wrap(function()
    while true do
      wait(60)
      if E.store.get("autosave") then pcall(function() E.systems.project.save() end) end
    end
  end)()
  E.toast("ARKHER ready — " .. n .. " commands.")
end
return true
