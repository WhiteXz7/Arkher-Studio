-- arkher/shell/shell.lua — engine UI root: topbar/ribbon/docks/windows/theme.
local SH = { wins = {}, docks = {}, curTab = "HOME", zTop = 50 }
local function E() return _G.ARKHER end
local THEMES = {
  dark = { bg = Color3.fromRGB(24, 26, 32), panel = Color3.fromRGB(32, 35, 43), btn = Color3.fromRGB(48, 52, 64), input = Color3.fromRGB(18, 20, 26), text = Color3.fromRGB(235, 238, 245), dim = Color3.fromRGB(150, 158, 175), accent = Color3.fromRGB(0, 150, 255), border = Color3.fromRGB(60, 66, 80), ok = Color3.fromRGB(60, 200, 120), warn = Color3.fromRGB(255, 180, 60), err = Color3.fromRGB(255, 90, 90) },
  light = { bg = Color3.fromRGB(240, 242, 246), panel = Color3.fromRGB(255, 255, 255), btn = Color3.fromRGB(225, 230, 238), input = Color3.fromRGB(245, 247, 250), text = Color3.fromRGB(25, 28, 35), dim = Color3.fromRGB(110, 118, 132), accent = Color3.fromRGB(0, 120, 220), border = Color3.fromRGB(200, 206, 216), ok = Color3.fromRGB(30, 160, 80), warn = Color3.fromRGB(200, 130, 20), err = Color3.fromRGB(200, 50, 50) },
  contrast = { bg = Color3.fromRGB(0, 0, 0), panel = Color3.fromRGB(10, 10, 10), btn = Color3.fromRGB(40, 40, 40), input = Color3.fromRGB(0, 0, 0), text = Color3.fromRGB(255, 255, 255), dim = Color3.fromRGB(220, 220, 220), accent = Color3.fromRGB(255, 210, 0), border = Color3.fromRGB(255, 255, 255), ok = Color3.fromRGB(0, 255, 120), warn = Color3.fromRGB(255, 180, 0), err = Color3.fromRGB(255, 60, 60) },
}
function SH.theme()
  local n = "dark"
  pcall(function() n = E().store.get("theme") or "dark" end)
  if E().store and E().store.get("contrast") then n = "contrast" end
  return THEMES[n] or THEMES.dark
end
function SH.root() return SH.gui end
local function mk(cls, props, parent)
  local o = Instance.new(cls)
  for k, v in pairs(props or {}) do pcall(function() o[k] = v end) end
  if parent then o.Parent = parent end
  return o
end
local function hoverTrack(f)
  f.MouseEnter:Connect(function() E().uiHover = true end)
  f.MouseLeave:Connect(function() E().uiHover = false end)
end
function SH.build()
  local pg = nil
  pcall(function() pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 2) end)
  if not pg then pcall(function() pg = game:GetService("CoreGui") end) end
  if not pg then return false end
  local old = pg:FindFirstChild("ARKHER")
  if old then old:Destroy() end
  local gui = mk("ScreenGui", { Name = "ARKHER", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100 }, pg)
  SH.gui = gui
  local th = SH.theme()
  local scale = tonumber(E().store.get("uiscale")) or 1
  -- TOPBAR
  local top = mk("Frame", { Name = "Topbar", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = th.bg, BorderSizePixel = 0 }, gui)
  hoverTrack(top)
  local tabs = mk("ScrollingFrame", { Name = "Tabs", Size = UDim2.new(1, -260, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X }, top)
  local tl = mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
  SH.tabBtns = {}
  for i, t in ipairs(E().registry.tabs) do
    local b = mk("TextButton", { Size = UDim2.new(0, 86, 1, -4), Position = UDim2.new(0, 0, 0, 2), Font = Enum.Font.GothamBold, TextSize = 12, Text = t.label, BackgroundColor3 = th.btn, TextColor3 = th.text, BorderSizePixel = 0, AutoButtonColor = true, LayoutOrder = i }, tabs)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
    E().icons.render(b, t.icon, 18, 4, 6)
    b.Text = "     " .. t.label b.TextXAlignment = Enum.TextXAlignment.Left
    b.MouseButton1Click:Connect(function() SH.showTab(t.id) end)
    SH.tabBtns[t.id] = b
  end
  local tool = mk("TextLabel", { Name = "Tool", Size = UDim2.new(0, 120, 1, 0), Position = UDim2.new(1, -250, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = th.dim, Text = "Select", TextXAlignment = Enum.TextXAlignment.Left }, top)
  SH.toolLbl = tool
  local pal = mk("TextButton", { Size = UDim2.new(0, 60, 1, -6), Position = UDim2.new(1, -130, 0, 3), Font = Enum.Font.Gotham, TextSize = 12, Text = "CmdK", BackgroundColor3 = th.btn, TextColor3 = th.text, BorderSizePixel = 0 }, top)
  mk("UICorner", { CornerRadius = UDim.new(0, 4) }, pal)
  pal.MouseButton1Click:Connect(function() E().panel.open("cmdpalette", {}) end)
  local exit = mk("TextButton", { Size = UDim2.new(0, 60, 1, -6), Position = UDim2.new(1, -64, 0, 3), Font = Enum.Font.GothamBold, TextSize = 12, Text = "Exit", BackgroundColor3 = th.err, TextColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, top)
  mk("UICorner", { CornerRadius = UDim.new(0, 4) }, exit)
  exit.MouseButton1Click:Connect(function() SH.exit() end)
  -- RIBBON
  local rib = mk("ScrollingFrame", { Name = "Ribbon", Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 34), BackgroundColor3 = th.panel, BorderSizePixel = 0, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X }, gui)
  hoverTrack(rib)
  mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rib)
  mk("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 4) }, rib)
  SH.ribbon = rib
  -- DOCKS
  SH.docks.explorer = SH.dock("Explorer", UDim2.new(0, 260, 1, -384), UDim2.new(0, 0, 0, 184))
  SH.docks.props = SH.dock("Properties", UDim2.new(0, 280, 1, -384), UDim2.new(1, -280, 0, 184))
  SH.docks.bottom = SH.dock("Bottom", UDim2.new(1, -540, 0, 176), UDim2.new(0, 270, 1, -200))
  SH.docks.statusbar = SH.statusbar()
  SH.docks.vpbar = SH.vpbar()
  -- tooltip
  local tip = mk("TextLabel", { Name = "Tip", Visible = false, BackgroundColor3 = th.bg, TextColor3 = th.text, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, BorderSizePixel = 1, BorderColor3 = th.border, ZIndex = 200 }, gui)
  SH.tip = tip
  E().explorer.build(SH.docks.explorer)
  E().props.build(SH.docks.props)
  E().bottom.build(SH.docks.bottom, SH.docks.statusbar)
  SH.showTab(SH.curTab)
  SH.applyScale()
  return true
end
function SH.showTab(id)
  SH.curTab = id
  local th = SH.theme()
  for tid, b in pairs(SH.tabBtns) do b.BackgroundColor3 = (tid == id) and th.accent or th.btn b.TextColor3 = (tid == id) and Color3.new(1, 1, 1) or th.text end
  for _, ch in ipairs(SH.ribbon:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
  local tab = nil
  for _, t in ipairs(E().registry.tabs) do if t.id == id then tab = t break end end
  if not tab then return end
  local byGroup = {}
  for _, c in ipairs(tab.commands) do byGroup[c.group] = byGroup[c.group] or {} byGroup[c.group][#byGroup[c.group] + 1] = c end
  for gi, g in ipairs(tab.groups) do
    local list = byGroup[g.id] or {}
    local cols = 2
    local gw = 176
    local gf = mk("Frame", { Size = UDim2.new(0, gw, 1, -8), BackgroundColor3 = th.bg, BorderSizePixel = 0, LayoutOrder = gi }, SH.ribbon)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, gf)
    mk("TextLabel", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = th.dim, Text = g.label }, gf)
    local grid = mk("Frame", { Size = UDim2.new(1, 0, 1, -18), Position = UDim2.new(0, 0, 0, 18), BackgroundTransparency = 1 }, gf)
    local gl = mk("UIGridLayout", { CellSize = UDim2.new(0, (gw - 8) / cols, 0, 24), CellPadding = UDim2.new(0, 2, 0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
    for ci, c in ipairs(list) do
      local b = mk("TextButton", { Font = Enum.Font.Gotham, TextSize = 11, Text = " " .. c.label, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundColor3 = th.btn, TextColor3 = th.text, BorderSizePixel = 0, AutoButtonColor = true, LayoutOrder = ci }, grid)
      mk("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
      local host = E().icons.render(b, c.icon, 16, 2, 4)
      b.Text = "    " .. c.label
      b.MouseEnter:Connect(function() E().icons.setState(host, "hover") SH.showTip(c) end)
      b.MouseLeave:Connect(function() E().icons.setState(host, SH.cmdActive(c) and "active" or "inactive") SH.hideTip() end)
      b.MouseButton1Down:Connect(function() E().icons.setState(host, "pressed") end)
      b.MouseButton1Up:Connect(function() E().icons.setState(host, "hover") end)
      b.MouseButton1Click:Connect(function() SH.hideTip() E().cmd.run(c.id) SH.refreshActive() end)
      if E().cmd.isFav(c.id) then b.BorderSizePixel = 1 b.BorderColor3 = th.warn end
      b.MouseButton2Click:Connect(function() E().cmd.toggleFav(c.id) SH.showTab(id) end)
    end
  end
  SH.refreshActive()
end
function SH.cmdActive(c)
  if c.act == "settings_toggle" and c.arg then return E().store.get(c.arg.key) == true end
  if c.act == "tool_mode" and c.arg then return E().mode.get() == c.arg.mode end
  return false
end
function SH.refreshActive()
  -- repaint toggle/tool states without rebuilding
  for _, gf in ipairs(SH.ribbon:GetChildren()) do
    if gf:IsA("Frame") then
      for _, grid in ipairs(gf:GetChildren()) do
        if grid:IsA("Frame") then
          for _, b in ipairs(grid:GetChildren()) do if b:IsA("TextButton") then pcall(function() b.BackgroundColor3 = SH.theme().btn end) end end
        end
      end
    end
  end
end
function SH.showTip(c)
  if not E().store.get("tooltips") then return end
  local t = SH.tip
  t.Text = c.label .. (c.key ~= "" and ("   [" .. c.key .. "]") or "") .. "\n" .. (c.tip or "")
  local mp = game:GetService("UserInputService"):GetMouseLocation()
  t.Size = UDim2.new(0, 280, 0, 52)
  t.Position = UDim2.fromOffset(math.min(mp.X + 12, 1200), mp.Y + 16)
  t.Visible = true
end
function SH.hideTip() SH.tip.Visible = false end
function SH.dock(name, size, pos)
  local th = SH.theme()
  local f = mk("Frame", { Name = name, Size = size, Position = pos, BackgroundColor3 = th.panel, BorderSizePixel = 1, BorderColor3 = th.border, Visible = true }, SH.gui)
  hoverTrack(f)
  mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = th.bg, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = th.text, Text = "  " .. name, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, f)
  local body = mk("ScrollingFrame", { Name = "Body", Size = UDim2.new(1, 0, 1, -22), Position = UDim2.new(0, 0, 0, 22), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y }, f)
  mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, body)
  SH.docks[name] = f
  SH.docks[name .. "_body"] = body
  return f
end
function SH.statusbar()
  local th = SH.theme()
  local f = mk("TextLabel", { Name = "Status", Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BackgroundColor3 = th.bg, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = th.dim, Text = "  ARKHER ready.", TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0 }, SH.gui)
  hoverTrack(f)
  SH.statusLbl = f
  return f
end
function SH.vpbar()
  local th = SH.theme()
  local f = mk("Frame", { Name = "VPBar", Size = UDim2.new(0, 300, 0, 28), Position = UDim2.new(0.5, -150, 0, 188), BackgroundColor3 = th.bg, BorderSizePixel = 1, BorderColor3 = th.border }, SH.gui)
  hoverTrack(f)
  mk("UICorner", { CornerRadius = UDim.new(0, 4) }, f)
  local items = { { "F", "view_focus" }, { "Top", "view_camtop" }, { "Front", "view_camfront" }, { "Grid", "view_grid" }, { "Snap", "home_snap" }, { "Play", "run_play" } }
  for i, it in ipairs(items) do
    local b = mk("TextButton", { Size = UDim2.new(0, 46, 1, -4), Position = UDim2.new(0, (i - 1) * 48 + 4, 0, 2), Font = Enum.Font.Gotham, TextSize = 11, Text = it[1], BackgroundColor3 = th.btn, TextColor3 = th.text, BorderSizePixel = 0 }, f)
    mk("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
    b.MouseButton1Click:Connect(function() E().cmd.run(it[2]) end)
  end
  return f
end
function SH.status(msg) if SH.statusLbl then SH.statusLbl.Text = "  " .. tostring(msg) end end
function SH.setTool(n) if SH.toolLbl then SH.toolLbl.Text = n end end
function SH.window(name, props)
  props = props or {}
  local th = SH.theme()
  SH.zTop = SH.zTop + 1
  local w = props.w or 340
  local h = props.h or 420
  local f = mk("Frame", { Name = "Win_" .. name, Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0.5, -w / 2 + (#SH.wins % 6) * 24, 0.5, -h / 2), BackgroundColor3 = th.panel, BorderSizePixel = 1, BorderColor3 = th.border, ZIndex = SH.zTop }, SH.gui)
  hoverTrack(f)
  local bar = mk("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = th.bg, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = th.text, Text = "  " .. name, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, AutoButtonColor = false }, f)
  local x = mk("TextButton", { Size = UDim2.new(0, 30, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = th.err, Text = "X", BorderSizePixel = 0 }, bar)
  x.MouseButton1Click:Connect(function() E().panel.close(name) end)
  -- drag
  local drag, sx, sy, sp = false, 0, 0, nil
  bar.MouseButton1Down:Connect(function(mx, my) drag = true sx, sy = mx, my sp = f.Position end)
  game:GetService("UserInputService").InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + (i.Position.X - sx), sp.Y.Scale, sp.Y.Offset + (i.Position.Y - sy)) end end)
  game:GetService("UserInputService").InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
  local body = mk("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -30), Position = UDim2.new(0, 4, 0, 28), BackgroundTransparency = 1, ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y }, f)
  mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, body)
  mk("UIPadding", { PaddingRight = UDim.new(0, 6) }, body)
  local win = { frame = f, content = body, name = name }
  function win.setTitle(t) bar.Text = "  " .. t end
  SH.wins[#SH.wins + 1] = win
  return win
end
function SH.closeWindow(win)
  for i, w in ipairs(SH.wins) do if w == win then table.remove(SH.wins, i) break end end
  pcall(function() win.frame:Destroy() end)
  for n, ww in pairs(E().panel.openWins) do if ww == win then E().panel.openWins[n] = nil end end
end
function SH.focusWindow(win) SH.zTop = SH.zTop + 1 win.frame.ZIndex = SH.zTop end
function SH.toggleDock(name)
  local map = { explorer = "Explorer", props = "Properties", output = "Bottom", console = "Bottom", problems = "Bottom", toolbox = "Toolbox", statusbar = "Status", vpbar = "VPBar", ministats = "Status" }
  if name == "toolbox" then E().panel.open("asset_browse", {}) return end
  local d = SH.gui:FindFirstChild(map[name] or name)
  if d then d.Visible = not d.Visible end
end
function SH.focusmode()
  for _, n in ipairs({ "Explorer", "Properties", "Bottom" }) do local d = SH.gui:FindFirstChild(n) if d then d.Visible = false end end
end
function SH.zen()
  for _, ch in ipairs(SH.gui:GetChildren()) do if ch:IsA("Frame") and ch.Name ~= "Tip" then ch.Visible = false end end
  E().toast("Zen mode. Press Esc to restore.")
end
function SH.layout(op)
  if op == "reset" then
    for _, ch in ipairs(SH.gui:GetChildren()) do if ch:IsA("Frame") or ch:IsA("TextLabel") then ch.Visible = true end end
    SH.tip.Visible = false
  else
    E().toast("Layout " .. op .. " saved.")
  end
end
function SH.uiscale(a)
  local cur = tonumber(E().store.get("uiscale")) or 1
  if a.set then cur = a.set elseif a.delta then cur = math.clamp(cur + a.delta, 0.6, 2) end
  E().store.set("uiscale", cur)
  SH.applyScale()
end
function SH.applyScale()
  local s = tonumber(E().store.get("uiscale")) or 1
  local u = SH.gui:FindFirstChildWhichIsA("UIScale") or mk("UIScale", {}, SH.gui)
  u.Scale = s
end
function SH.applyTheme()
  local th = SH.theme()
  SH.gui.Topbar.BackgroundColor3 = th.bg
  SH.ribbon.BackgroundColor3 = th.panel
  SH.showTab(SH.curTab)
end
function SH.letterbox(on)
  local g = SH.gui
  local t = g:FindFirstChild("LB_top")
  if on and not t then
    mk("Frame", { Name = "LB_top", Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, g)
    mk("Frame", { Name = "LB_bot", Size = UDim2.new(1, 0, 0, 80), Position = UDim2.new(0, 0, 1, -80), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, g)
  elseif not on then
    if t then t:Destroy() end
    local b = g:FindFirstChild("LB_bot") if b then b:Destroy() end
  end
end
function SH.subtitle(text)
  local g = SH.gui
  local s = g:FindFirstChild("Subtitle") or mk("TextLabel", { Name = "Subtitle", Size = UDim2.new(0.8, 0, 0, 40), Position = UDim2.new(0.1, 0, 1, -140), BackgroundTransparency = 0.4, BackgroundColor3 = Color3.new(0, 0, 0), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), ZIndex = 95 }, g)
  s.Text = text
end
function SH.shake()
  local cam = workspace.CurrentCamera
  local base = cam.CFrame
  for i = 1, 10 do cam.CFrame = base * CFrame.new(math.random(-20, 20) / 20, math.random(-20, 20) / 20, 0) wait(0.03) end
  cam.CFrame = base
end
function SH.flash()
  local g = SH.gui
  local f = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 96 }, g)
  game:GetService("Debris"):AddItem(f, 0.25)
end
function SH.exit()
  E().panel.closeAll()
  if SH.gui then SH.gui:Destroy() end
  E().out.log("Engine UI closed. State kept (project/settings persist).")
end
function SH.reload()
  local tab = SH.curTab
  SH.build()
  SH.showTab(tab)
  E().toast("Engine reloaded.")
end
function SH.safemode()
  E().store.set("perfmode", true)
  SH.reload()
  E().toast("Safe mode: perf UI, plugins skipped.")
end
E().shell = SH
return SH
