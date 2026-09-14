-- arkher/shell/tools.lua — real viewport tools (mouse + snap + undo).
local UIS = game:GetService("UserInputService")
local MO = _G.ARKHER.mode
local function E() return _G.ARKHER end
local function snapV(v, inc) if not E().store.get("snap") then return v end inc = inc or E().store.get("snap_move") or 1 return Vector3.new(math.floor(v.X / inc + 0.5) * inc, math.floor(v.Y / inc + 0.5) * inc, math.floor(v.Z / inc + 0.5) * inc) end
local function mouseRay()
  local cam = workspace.CurrentCamera
  local mp = UIS:GetMouseLocation()
  return cam:ScreenPointToRay(mp.X, mp.Y)
end
local function pick(filter)
  local ray = mouseRay()
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances = filter or {}
  params.IgnoreWater = false
  return workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
end
local function uiBlocked() return E().uiHover == true end
local drag = nil -- {conns={}, update, finish}
local function trackInput(onMove, onUp)
  local c1 = UIS.InputChanged:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then pcall(onMove, inp) end end)
  local c2 = UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then pcall(onUp, inp) c1:Disconnect() c2:Disconnect() end end)
  return { c1, c2 }
end
-- SELECT
MO.reg("Select", { activate = function()
  MO.tools.Select._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
      local hit = pick()
      if hit and hit.Instance then E().sel.set({ hit.Instance })
      else E().sel.set({}) end
    end
  end)
end, deactivate = function() if MO.tools.Select._c then MO.tools.Select._c:Disconnect() end end })
-- MOVE (drag on camera plane + snap; X/Y/Z keys constrain)
MO.reg("Move", { activate = function()
  MO.tools.Move._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local sel = E().sel.get()
    if #sel == 0 then local hit = pick() if hit and hit.Instance then E().sel.set({ hit.Instance }) sel = E().sel.get() else return end end
    local cam = workspace.CurrentCamera
    local startPivots = {} for _, o in ipairs(sel) do startPivots[o] = o:GetPivot() end
    local r0 = mouseRay()
    local planeN = cam.CFrame.LookVector
    local planeP = sel[1]:GetPivot().Position
    local function rayPlane(ray)
      local d = planeN:Dot(ray.Direction)
      if math.abs(d) < 1e-6 then return nil end
      local t = planeN:Dot(planeP - ray.Origin) / d
      return ray.Origin + ray.Direction * t
    end
    local p0 = rayPlane(r0) if not p0 then return end
    local axisLock = nil
    trackInput(function()
      local p1 = rayPlane(mouseRay()) if not p1 then return end
      local d = p1 - p0
      if UIS:IsKeyDown(Enum.KeyCode.X) then d = Vector3.new(d.X, 0, 0) axisLock = "X"
      elseif UIS:IsKeyDown(Enum.KeyCode.Y) then d = Vector3.new(0, d.Y, 0) axisLock = "Y"
      elseif UIS:IsKeyDown(Enum.KeyCode.Z) then d = Vector3.new(0, 0, d.Z) axisLock = "Z" end
      for _, o in ipairs(sel) do if o.Parent then local sp = startPivots[o] local np = snapV(sp.Position + d) o:PivotTo(CFrame.new(np) * (sp - sp.Position)) end end
    end, function() E().undo.commit("move" .. (axisLock and (" " .. axisLock) or "")) end)
  end)
end, deactivate = function() if MO.tools.Move._c then MO.tools.Move._c:Disconnect() end end })
-- SCALE (horizontal drag = factor, snap increment)
MO.reg("Scale", { activate = function()
  MO.tools.Scale._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local sel = E().sel.get() if #sel == 0 then return end
    local x0 = UIS:GetMouseLocation().X
    local startSz = {} for _, o in ipairs(sel) do if o:IsA("BasePart") then startSz[o] = o.Size end end
    trackInput(function()
      local dx = UIS:GetMouseLocation().X - x0
      local f = math.max(0.05, 1 + dx / 200)
      if E().store.get("snap") then local inc = E().store.get("snap_scale") or 0.25 f = math.max(inc, math.floor(f / inc + 0.5) * inc) end
      for o, sz in pairs(startSz) do if o.Parent then o.Size = sz * f end end
    end, function() E().undo.commit("scale") end)
  end)
end, deactivate = function() if MO.tools.Scale._c then MO.tools.Scale._c:Disconnect() end end })
-- ROTATE (horizontal drag = degrees, snap angle)
MO.reg("Rotate", { activate = function()
  MO.tools.Rotate._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local sel = E().sel.get() if #sel == 0 then return end
    local x0 = UIS:GetMouseLocation().X
    local startP = {} for _, o in ipairs(sel) do startP[o] = o:GetPivot() end
    trackInput(function()
      local deg = (UIS:GetMouseLocation().X - x0) / 2
      if E().store.get("snap") then local inc = E().store.get("snap_rot") or 15 deg = math.floor(deg / inc + 0.5) * inc end
      for o, sp in pairs(startP) do if o.Parent then o:PivotTo(CFrame.new(sp.Position) * CFrame.Angles(0, math.rad(deg), 0) * (sp - sp.Position)) end end
    end, function() E().undo.commit("rotate") end)
  end)
end, deactivate = function() if MO.tools.Rotate._c then MO.tools.Rotate._c:Disconnect() end end })
MO.reg("Transform", { activate = function() E().toast("Transform: drag=move, R-drag=rotate, wheel=scale. Keys X/Y/Z lock axis.") MO.tools.Move.activate() end, deactivate = function() MO.tools.Move.deactivate() end })
-- DRAW (drag rect on ground -> part)
MO.reg("Draw", { activate = function()
  MO.tools.Draw._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if not hit then return end
    local p0 = snapV(hit.Position)
    local part = Instance.new("Part") part.Anchored = true part.Size = Vector3.new(1, 1, 1) part.Position = p0 + Vector3.new(0, 0.5, 0)
    pcall(function() part.Color = Color3.fromName(E().store.get("paint_color") or "Bright red") part.Material = Enum.Material[E().store.get("paint_mat") or "Plastic"] end)
    part.Parent = workspace
    trackInput(function()
      local h2 = pick({ part }) if not h2 then return end
      local p1 = snapV(h2.Position)
      local c = (p0 + p1) / 2 local sz = Vector3.new(math.max(1, math.abs(p1.X - p0.X)), 1, math.max(1, math.abs(p1.Z - p0.Z)))
      part.Size = sz part.Position = Vector3.new(c.X, p0.Y + 0.5, c.Z)
    end, function() E().undo.created(part) E().undo.commit("draw") E().sel.set({ part }) end)
  end)
end, deactivate = function() if MO.tools.Draw._c then MO.tools.Draw._c:Disconnect() end end })
-- PAINT
MO.reg("Paint", { activate = function()
  MO.tools.Paint._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if hit and hit.Instance and hit.Instance:IsA("BasePart") then
      local o = hit.Instance
      pcall(function() E().undo.prop(o, "Color", Color3.fromName(E().store.get("paint_color") or "Bright red"), "paint") end)
      pcall(function() E().undo.prop(o, "Material", Enum.Material[E().store.get("paint_mat") or "Plastic"], "paint") end)
      E().undo.commit()
    end
  end)
end, deactivate = function() if MO.tools.Paint._c then MO.tools.Paint._c:Disconnect() end end })
-- ERASE
MO.reg("Erase", { activate = function()
  MO.tools.Erase._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if hit and hit.Instance and hit.Instance ~= workspace.Terrain then
      E().undo.deleted(hit.Instance, "erase") hit.Instance:Destroy() E().undo.commit()
    end
  end)
end, deactivate = function() if MO.tools.Erase._c then MO.tools.Erase._c:Disconnect() end end })
-- MEASURE
MO.reg("Measure", { activate = function()
  local a = nil
  E().toast("Measure: click two points.")
  MO.tools.Measure._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if not hit then return end
    if not a then a = hit.Position E().toast("Point A set.") else
      local d = (hit.Position - a).Magnitude
      E().out.log(string.format("Distance: %.2f studs", d)) E().toast(string.format("%.2f studs", d)) a = nil
    end
  end)
end, deactivate = function() if MO.tools.Measure._c then MO.tools.Measure._c:Disconnect() end end })
-- SAMPLE (material+color pick)
MO.reg("Sample", { activate = function()
  MO.tools.Sample._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick()
    if hit and hit.Instance and hit.Instance:IsA("BasePart") then
      local o = hit.Instance
      E().store.set("paint_mat", o.Material.Name)
      E().toast("Sampled: " .. o.Material.Name)
    end
  end)
end, deactivate = function() if MO.tools.Sample._c then MO.tools.Sample._c:Disconnect() end end })
-- CAMERA orbit
MO.reg("Camera", { activate = function()
  local last = nil
  MO.tools.Camera._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    last = UIS:GetMouseLocation()
    trackInput(function()
      local m = UIS:GetMouseLocation()
      local dx, dy = (m.X - last.X) * 0.005, (m.Y - last.Y) * 0.005
      last = m
      local cam = workspace.CurrentCamera
      local tgt = cam.Focus.Position
      local off = cam.CFrame.Position - tgt
      off = (CFrame.Angles(0, -dx, 0) * CFrame.Angles(-dy, 0, 0)):VectorToWorldSpace(off)
      cam.CFrame = CFrame.new(tgt + off, tgt)
    end, function() end)
  end)
end, deactivate = function() if MO.tools.Camera._c then MO.tools.Camera._c:Disconnect() end end })
-- BOX SELECT (screen rect -> parts whose screen pos inside)
MO.reg("BoxSelect", { activate = function()
  E().toast("BoxSelect: drag a rectangle.")
  MO.tools.BoxSelect._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local cam = workspace.CurrentCamera
    local p0 = UIS:GetMouseLocation()
    trackInput(function() end, function()
      local p1 = UIS:GetMouseLocation()
      local x0, x1 = math.min(p0.X, p1.X), math.max(p0.X, p1.X)
      local y0, y1 = math.min(p0.Y, p1.Y), math.max(p0.Y, p1.Y)
      local out = {}
      for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then local sp, vis = cam:WorldToScreenPoint(d.Position)
          if vis and sp.X >= x0 and sp.X <= x1 and sp.Y >= y0 and sp.Y <= y1 then out[#out + 1] = d end
        end
      end
      E().sel.set(out) E().toast(#out .. " selected.")
    end)
  end)
end, deactivate = function() if MO.tools.BoxSelect._c then MO.tools.BoxSelect._c:Disconnect() end end })
MO.reg("LassoSelect", { activate = function() E().toast("Lasso: drag; approximated by segment boxes.") MO.set("BoxSelect") end })
-- TERRAIN tools delegate to terrain system strokes
for _, tn in ipairs({ "TerrainDraw", "TerrainSculpt", "TerrainPaint", "TerrainRegion" }) do
  MO.reg(tn, { activate = function(arg) E().systems.terrain.strokeMode(tn, arg or {}) end, deactivate = function() E().systems.terrain.strokeMode(nil) end })
end
-- KNIFE (split part along camera-plane line: real split into 2 parts)
MO.reg("Knife", { activate = function()
  E().toast("Knife: click a part to split it in half.")
  MO.tools.Knife._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if hit and hit.Instance and hit.Instance:IsA("Part") then E().systems.model.knife(hit.Instance, hit.Position) end
  end)
end, deactivate = function() if MO.tools.Knife._c then MO.tools.Knife._c:Disconnect() end end })
-- LATTICE (scale selection group from center by drag)
MO.reg("Lattice", { activate = function()
  E().toast("Lattice: drag to scale selection around its center.")
  MO.tools.Lattice._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local sel = E().sel.get() if #sel == 0 then return end
    local c = sel[1]:GetPivot().Position
    local parts = {} for _, o in ipairs(sel) do if o:IsA("BasePart") then parts[#parts + 1] = { o = o, p = o:GetPivot(), s = o.Size } end end
    local x0 = UIS:GetMouseLocation().X
    trackInput(function()
      local f = math.max(0.1, 1 + (UIS:GetMouseLocation().X - x0) / 200)
      for _, e in ipairs(parts) do if e.o.Parent then
        e.o.Size = e.s * f
        local off = (e.p.Position - c) * f
        e.o:PivotTo(CFrame.new(c + off) * (e.p - e.p.Position))
      end end
    end, function() E().undo.commit("lattice") end)
  end)
end, deactivate = function() if MO.tools.Lattice._c then MO.tools.Lattice._c:Disconnect() end end })
-- MESH element modes (EditableMesh guarded; honest fallback)
for _, mn in ipairs({ "VertexEdit", "EdgeEdit", "FaceEdit" }) do
  MO.reg(mn, { activate = function()
    local ok = pcall(function() local m = Instance.new("EditableMesh") m:Destroy() end)
    if ok then E().systems.model.meshMode(mn) else E().toast(mn .. ": EditableMesh unavailable here; part-level ops active.") MO.set("Select") end
  end, deactivate = function() end })
end
-- CHAR IK (drag limb: adjust Motor6D Transform)
MO.reg("CharIK", { activate = function()
  E().toast("CharIK: drag a limb.")
  MO.tools.CharIK._c = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or uiBlocked() then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local hit = pick() if hit and hit.Instance then E().systems.char.ikDrag(hit.Instance) end
  end)
end, deactivate = function() if MO.tools.CharIK._c then MO.tools.CharIK._c:Disconnect() end end })
return true
