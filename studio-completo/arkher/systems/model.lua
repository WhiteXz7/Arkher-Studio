-- arkher/systems/model.lua — part-level ops (real) + CSG/EditableMesh (guarded, honest).
local MD = {}
local function E() return _G.ARKHER end
local function selParts()
  local out = {}
  for _, o in ipairs(E().sel.get()) do if o and o.Parent and o:IsA("BasePart") then out[#out + 1] = o end end
  return out
end
local function editableMeshOf(part)
  local m = part:FindFirstChildWhichIsA("EditableMesh")
  return m
end
function MD.extrude(a)
  a = a or {}
  local d = a.dist or 2
  for _, o in ipairs(selParts()) do
    local em = editableMeshOf(o)
    if em then E().toast("EditableMesh extrude: use FaceEdit on the mesh.") else
      local p = o:GetPivot()
      o:PivotTo(p + p.LookVector * d)
    end
  end
  E().undo.commit("extrude")
end
function MD.bevel(a) E().toast("Bevel on parts: approximated by corner wedges is manual; EditableMesh bevel in FaceEdit.") end
function MD.inset(a) E().toast("Inset: select faces in FaceEdit (EditableMesh) or scale parts.") end
function MD.bridge(a) E().toast("Bridge: select 2 parts; creates connecting part.") MD._bridgeGo() end
function MD._bridgeGo()
  local p = selParts() if #p < 2 then E().toast("Select 2 parts.") return end
  local a, b = p[1].Position, p[2].Position
  local mid = (a + b) / 2
  local part = Instance.new("Part") part.Anchored = true
  part.Size = Vector3.new(1, 1, (a - b).Magnitude)
  part.CFrame = CFrame.new(mid, b)
  part.Parent = workspace E().undo.created(part) E().undo.commit("bridge")
end
function MD.merge(a)
  local p = selParts() if #p < 2 then E().toast("Select 2+ parts.") return end
  local cf, sz = p[1].GetBoundingBox and nil or nil, nil
  local m = Instance.new("Model") m.Name = "Merged"
  for _, o in ipairs(p) do o.Parent = m end
  m.Parent = workspace E().undo.created(m) E().undo.commit("merge") E().sel.set({ m })
end
function MD.split(a)
  local p = selParts() if #p == 0 then E().toast("Select parts.") return end
  for _, o in ipairs(p) do
    if o:IsA("Part") and o.Shape == Enum.PartType.Block then
      local cf, sz = o.CFrame, o.Size
      o.Size = Vector3.new(sz.X / 2, sz.Y, sz.Z)
      o.CFrame = cf * CFrame.new(-sz.X / 4, 0, 0)
      local c2 = o:Clone() c2.CFrame = cf * CFrame.new(sz.X / 4, 0, 0) c2.Parent = workspace E().undo.created(c2)
    end
  end
  E().undo.commit("split")
end
function MD.knife(part, pos)
  if not (part and part.Parent) then return end
  local cf, sz = part.CFrame, part.Size
  local localHit = cf:PointToObjectSpace(pos)
  local axis = math.abs(localHit.X) > math.abs(localHit.Z) and "X" or "Z"
  if axis == "X" then
    part.Size = Vector3.new(sz.X / 2, sz.Y, sz.Z) part.CFrame = cf * CFrame.new(-sz.X / 4, 0, 0)
    local c2 = part:Clone() c2.Size = Vector3.new(sz.X / 2, sz.Y, sz.Z) c2.CFrame = cf * CFrame.new(sz.X / 4, 0, 0) c2.Parent = workspace E().undo.created(c2)
  else
    part.Size = Vector3.new(sz.X, sz.Y, sz.Z / 2) part.CFrame = cf * CFrame.new(0, 0, -sz.Z / 4)
    local c2 = part:Clone() c2.Size = Vector3.new(sz.X, sz.Y, sz.Z / 2) c2.CFrame = cf * CFrame.new(0, 0, sz.Z / 4) c2.Parent = workspace E().undo.created(c2)
  end
  E().undo.commit("knife")
end
function MD.subdiv()
  local n = 0
  for _, o in ipairs(selParts()) do if o:IsA("Part") then n = n + 1 end end
  E().toast("Subdivide applies to EditableMesh (FaceEdit). " .. n .. " part(s) selected.")
end
function MD.weld()
  local p = selParts() if #p < 2 then E().toast("Select 2+ parts.") return end
  for i = 2, #p do local w = Instance.new("WeldConstraint") w.Part0 = p[1] w.Part1 = p[i] w.Parent = p[1] E().undo.created(w) end
  E().undo.commit("weld")
end
function MD.boolean(op)
  local p = selParts() if #p < 2 then E().toast("Select 2+ parts.") return end
  local ok, res = pcall(function()
    if op == "union" then return p[1]:UnionAsync(p) end
    if op == "subtract" then local n = p[2]:NegateAsync() return (n and p[1]:UnionAsync({ n })) or nil end
    if op == "intersect" then local f = workspace.IntersectAsync return (f and workspace:IntersectAsync(p)) or nil end
  end)
  if ok and res then
    if type(res) == "table" then for _, r in ipairs(res) do r.Parent = workspace E().undo.created(r) end else res.Parent = workspace E().undo.created(res) end
    for _, o in ipairs(p) do o:Destroy() end
    E().undo.commit("boolean " .. op)
  else
    E().toast("CSG needs plugin context; parts kept. (Limit noted in Modeler > Limits.)")
    E().out.warn("boolean failed: " .. tostring(res))
  end
end
function MD.separate()
  for _, o in ipairs(E().sel.get()) do
    if o and o.Parent and (o:IsA("UnionOperation") or o:IsA("IntersectOperation")) then
      E().toast("Separate: CSG cannot be losslessly separated (honest limit). Union kept.")
      return
    end
  end
  E().toast("Select a Union/Intersect.")
end
function MD.deform(kind, a)
  a = a or {}
  local amt = a.amount or 0.3
  local parts = selParts() if #parts == 0 then E().toast("Select parts.") return end
  local c = parts[1]:GetPivot().Position
  for _, o in ipairs(parts) do
    local p = o:GetPivot()
    if kind == "bend" then o:PivotTo(CFrame.new(p.Position) * CFrame.Angles(0, 0, amt * ((p.Position - c).Magnitude / 10)) * (p - p.Position))
    elseif kind == "twist" then o:PivotTo(CFrame.new(p.Position) * CFrame.Angles(0, amt * (p.Position.Y - c.Y) / 5, 0) * (p - p.Position))
    elseif kind == "taper" then local f = 1 - amt * ((p.Position.Y - c.Y) / 20) o.Size = o.Size * math.max(0.1, f) end
  end
  E().undo.commit("deform " .. kind)
end
function MD.array(a)
  a = a or {}
  local p = selParts() if #p == 0 then E().toast("Select parts.") return end
  local n = math.min(50, a.count or 5)
  local off = Vector3.new(a.dx or 5, a.dy or 0, a.dz or 0)
  for _, o in ipairs(p) do for i = 1, n do local c = o:Clone() c:PivotTo(o:GetPivot() + off * i) c.Parent = workspace E().undo.created(c) end end
  E().undo.commit("array")
end
function MD.mirror(a)
  a = a or {}
  local ax = a.axis or "X"
  local p = selParts() if #p == 0 then E().toast("Select parts.") return end
  local cx = p[1]:GetPivot().Position[ax]
  for _, o in ipairs(p) do local c = o:Clone() local pp = c:GetPivot() local np = pp.Position local d = np[ax] - cx
    if ax == "X" then np = Vector3.new(cx - d, np.Y, np.Z) elseif ax == "Y" then np = Vector3.new(np.X, cx - d, np.Z) else np = Vector3.new(np.X, np.Y, cx - d) end
    c:PivotTo(CFrame.new(np) * (pp - pp.Position)) c.Parent = workspace E().undo.created(c) end
  E().undo.commit("mirror mesh")
end
function MD.normals() E().toast("Normals: EditableMesh only (FaceEdit). Parts use box normals.") end
function MD.smoothshade() E().toast("SmoothShade is a mesh property; parts are faceted by design.") end
function MD.decimate(a) E().toast("Decimate needs EditableMesh source (import mesh JSON first).") end
function MD.remesh(a) E().toast("Remesh needs EditableMesh source (import mesh JSON first).") end
function MD.bake()
  E().out.warn("Bake to MeshPart asset requires Studio asset upload (no API). Export JSON instead.")
  MD.export()
end
function MD.freeze()
  for _, o in ipairs(selParts()) do o:PivotTo(o:GetPivot()) end
  E().toast("Transforms are already baked on parts (pivot = transform).")
end
function MD.resetxf()
  for _, o in ipairs(selParts()) do local p = o:GetPivot() o:PivotTo(CFrame.new(p.Position)) end
  E().undo.commit("reset xf")
end
function MD.cleanup()
  local n = 0
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and (d.Size.X < 0.05 or d.Size.Y < 0.05 or d.Size.Z < 0.05) then d:Destroy() n = n + 1 end
  end
  E().toast("Removed " .. n .. " degenerate parts.") E().undo.commit("cleanup")
end
function MD.meshMode(mn) E().toast(mn .. ": click an EditableMesh part (import mesh JSON first).") end
function MD.export()
  local p = selParts()
  local arr = {}
  for _, o in ipairs(p) do arr[#arr + 1] = { n = o.Name, c = o.ClassName, cf = { o.CFrame:GetComponents() }, sz = { o.Size.X, o.Size.Y, o.Size.Z }, col = { math.floor(o.Color.R * 255), math.floor(o.Color.G * 255), math.floor(o.Color.B * 255) }, mat = o.Material.Name } end
  E().out.log("MESH " .. game:GetService("HttpService"):JSONEncode(arr))
  E().toast("Mesh JSON -> Output (" .. #arr .. " parts).")
end
function MD.import(a)
  E().panel.open("model_import", a)
end
E().systems.model = MD
return MD
