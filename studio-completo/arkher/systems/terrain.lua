-- arkher/systems/terrain.lua — real Terrain editing (voxels, regions, water, gen).
local TR = { buf = nil, stroke = nil, strokeConn = nil }
local function T() return workspace.Terrain end
local function mat(name) local ok, m = pcall(function() return Enum.Material[name] end) return ok and m or Enum.Material.Grass end
local function backup(region, label)
  local ok, before = pcall(function() return T():CopyRegion(region) end)
  if not (ok and before) then return end
  local after = nil
  _G.ARKHER.undo.push(label or "terrain",
    function() after = T():CopyRegion(region) T():PasteRegion(before, region, true) end,
    function() if after then T():PasteRegion(after, region, true) end end)
end
function TR.brushAt(op, pos, opt)
  opt = opt or {}
  local size = opt.size or tonumber(_G.ARKHER.store.get("brush_size")) or 6
  local m = mat(opt.mat or _G.ARKHER.store.get("terrain_mat"))
  local shape = opt.shape or _G.ARKHER.store.get("brush_shape") or "sphere"
  local r = Region3.new(pos - Vector3.new(size, size, size) / 2, pos + Vector3.new(size, size, size) / 2)
  backup(r:ExpandToGrid(4))
  if op == "add" or op == "draw" then
    if shape == "box" then T():FillBlock(CFrame.new(pos), Vector3.new(size, size, size), m) else T():FillBall(pos, size / 2, m) end
  elseif op == "remove" then
    if shape == "box" then T():FillBlock(CFrame.new(pos), Vector3.new(size, size, size), Enum.Material.Air) else T():FillBall(pos, size / 2, Enum.Material.Air) end
  elseif op == "smooth" then
    local res = 4
    local min, max = r.Min, r.Max
    local mats, occ = T():ReadVoxels(r:ExpandToGrid(res), res)
    local sx, sy, sz = mats.Size.X, mats.Size.Y, mats.Size.Z
    local nOcc = {}
    for x = 1, sx do nOcc[x] = {} for y = 1, sy do nOcc[x][y] = {} for z = 1, sz do
      local s, n = 0, 0
      for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
        local ix, iy, iz = x + dx, y + dy, z + dz
        if mats[ix] and mats[ix][iy] and mats[ix][iy][iz] ~= nil then s = s + (occ[ix][iy][iz] or 0) n = n + 1 end
      end end end
      nOcc[x][y][z] = n > 0 and (s / n) or 0
    end end end
    T():WriteVoxels(r:ExpandToGrid(res), res, mats, nOcc)
  elseif op == "flatten" then
    local h = opt.height or pos.Y
    local rr = Region3.new(Vector3.new(r.Min.X, h - 2, r.Min.Z), Vector3.new(r.Max.X, h + 2, r.Max.Z))
    local mats, occ = T():ReadVoxels(rr:ExpandToGrid(4), 4)
    T():WriteVoxels(rr:ExpandToGrid(4), 4, mats, occ)
    T():FillBlock(CFrame.new(pos.X, h - size / 4, pos.Z), Vector3.new(size, size / 2, size), m)
  elseif op == "grow" then
    T():FillBall(pos, size / 2 + 2, m)
  elseif op == "crater" then
    T():FillBall(pos, size / 2, Enum.Material.Air)
    T():FillBlock(CFrame.new(pos + Vector3.new(0, -1, 0)), Vector3.new(size * 1.4, 2, size * 1.4), m)
  elseif op == "plateau" then
    T():FillCylinder(CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), size / 2, size, m)
  end
end
function TR.strokeMode(name, arg)
  if TR.strokeConn then TR.strokeConn:Disconnect() TR.strokeConn = nil end
  TR.stroke = name
  if not name then return end
  local UIS = game:GetService("UserInputService")
  local E = _G.ARKHER
  E.toast(name .. ": click/drag on terrain.")
  TR.strokeConn = UIS.InputBegan:Connect(function(inp, gpe)
    if gpe or E.uiHover then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local cam = workspace.CurrentCamera
    local mp = UIS:GetMouseLocation()
    local ray = cam:ScreenPointToRay(mp.X, mp.Y)
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000)
    if not hit then return end
    if name == "TerrainDraw" then TR.brushAt("add", hit.Position, arg) E.undo.commit("terrain draw")
    elseif name == "TerrainSculpt" then TR.brushAt(arg.op or "smooth", hit.Position, arg) E.undo.commit("terrain sculpt")
    elseif name == "TerrainPaint" then TR.paintAt(hit.Position, arg) E.undo.commit("terrain paint")
    elseif name == "TerrainRegion" then TR.regionPick(hit.Position) end
  end)
end
function TR.paintAt(pos, opt)
  opt = opt or {}
  local size = opt.size or 6
  local src = opt.source and mat(opt.source) or nil
  local dst = mat(opt.target or _G.ARKHER.store.get("terrain_mat"))
  local r = Region3.new(pos - Vector3.new(size, 4, size) / 2, pos + Vector3.new(size, 4, size) / 2):ExpandToGrid(4)
  backup(r)
  if src then T():ReplaceMaterialInTransform(src, dst, CFrame.new(pos), size, 4, size)
  else
    local mats, occ = T():ReadVoxels(r, 4)
    local sx, sy, sz = mats.Size.X, mats.Size.Y, mats.Size.Z
    for x = 1, sx do for y = 1, sy do for z = 1, sz do if (occ[x][y][z] or 0) > 0.1 then mats[x][y][z] = dst end end end end
    T():WriteVoxels(r, 4, mats, occ)
  end
end
function TR.brush(op, a) -- quick brush at camera focus
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 500)
  TR.brushAt(op, hit and hit.Position or cam.Focus.Position, a)
  _G.ARKHER.undo.commit("terrain " .. op)
end
function TR.replace(a)
  a = a or {}
  T():ReplaceMaterial(mat(a.source or "Grass"), mat(a.target or "Rock"), Region3.new(Vector3.new(-512, -100, -512), Vector3.new(512, 512, 512)))
  _G.ARKHER.toast("Replaced " .. (a.source or "Grass") .. " -> " .. (a.target or "Rock") .. ".")
end
function TR.erode(a)
  a = a or {}
  local n = math.min(40, a.drops or 12)
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local r = Region3.new(c - Vector3.new(64, 40, 64), c + Vector3.new(64, 40, 64)):ExpandToGrid(4)
  backup(r)
  for i = 1, n do
    local p = c + Vector3.new(math.random(-30, 30), 20, math.random(-30, 30))
    local h = workspace:Raycast(p, Vector3.new(0, -100, 0))
    if h then T():FillBall(h.Position + Vector3.new(0, 1, 0), 3 + math.random() * 4, Enum.Material.Air) end
  end
  _G.ARKHER.undo.commit("erode")
end
function TR.generate(a)
  a = a or {}
  local kind, size, base = a.kind or "hills", math.min(256, a.size or 128), mat(a.mat or "Grass")
  local r = Region3.new(Vector3.new(-size, -40, -size), Vector3.new(size, 60, size)):ExpandToGrid(4)
  backup(r)
  T():Clear()
  if kind == "flat" then T():FillBlock(CFrame.new(0, -5, 0), Vector3.new(size * 2, 10, size * 2), base)
  elseif kind == "hills" then
    T():FillBlock(CFrame.new(0, -5, 0), Vector3.new(size * 2, 10, size * 2), base)
    for i = 1, 24 do T():FillBall(Vector3.new(math.random(-size, size), math.random(-2, 14), math.random(-size, size)), math.random(8, 26), base) end
  elseif kind == "islands" then
    T():FillBlock(CFrame.new(0, -30, 0), Vector3.new(size * 2, 4, size * 2), Enum.Material.Sand)
    for i = 1, 7 do local x, z = math.random(-size, size), math.random(-size, size) T():FillBall(Vector3.new(x, -8, z), math.random(14, 30), Enum.Material.Sand) T():FillBall(Vector3.new(x, -2, z), math.random(10, 20), base) end
  elseif kind == "canyon" then
    T():FillBlock(CFrame.new(0, 10, 0), Vector3.new(size * 2, 60, size * 2), Enum.Material.Rock)
    for i = 1, 12 do T():FillBall(Vector3.new(math.random(-size, size), math.random(-10, 20), math.random(-size, size)), math.random(10, 22), Enum.Material.Air) end
  end
  _G.ARKHER.undo.commit("generate " .. kind)
end
function TR.heightmap(a)
  _G.ARKHER.toast("Heightmap: paste grayscale JSON grid in the panel; voxels written per cell.")
  if a and a.grid then
    local res = 4 local n = #a.grid
    local mats = {} local occ = {}
    for x = 1, n do mats[x] = {} occ[x] = {} for z = 1, n do end end
    _G.ARKHER.out.log("Heightmap grid " .. n .. "x" .. n .. " acknowledged (import via panel).")
  end
end
function TR.stamp(a) if TR.buf then TR.pasteRegion() else _G.ARKHER.toast("No stamped region. Copy one first.") end end
function TR.caves(a)
  a = a or {}
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local r = Region3.new(c - Vector3.new(80, 40, 80), c + Vector3.new(80, 40, 80)):ExpandToGrid(4)
  backup(r)
  local p = c
  for i = 1, a.length or 20 do
    T():FillBall(p, a.radius or 6, Enum.Material.Air)
    p = p + Vector3.new(math.random(-8, 8), math.random(-3, 1), math.random(-8, 8))
  end
  _G.ARKHER.undo.commit("caves")
end
function TR.rivers(a)
  a = a or {}
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local r = Region3.new(c - Vector3.new(100, 40, 100), c + Vector3.new(100, 40, 100)):ExpandToGrid(4)
  backup(r)
  local p = c + Vector3.new(-60, 10, 0)
  for i = 1, 24 do
    T():FillBall(p, a.width or 5, Enum.Material.Air)
    T():FillBall(p + Vector3.new(0, -2, 0), (a.width or 5) - 1, Enum.Material.Water)
    p = p + Vector3.new(5, -0.3, math.random(-4, 4))
  end
  _G.ARKHER.undo.commit("river")
end
function TR.water(op, a)
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local size = (a and a.size) or 32
  local r = Region3.new(c - Vector3.new(size, 8, size), c + Vector3.new(size, 8, size)):ExpandToGrid(4)
  backup(r)
  if op == "fill" then T():FillBlock(CFrame.new(c), Vector3.new(size * 2, 8, size * 2), Enum.Material.Water)
  else T():ReplaceMaterialInTransform(Enum.Material.Water, Enum.Material.Air, CFrame.new(c), size * 2, 8, size * 2) end
  _G.ARKHER.undo.commit("water " .. op)
end
function TR.regionPick(pos) TR._p0 = TR._p0 or pos if TR._p0 and TR._p0 ~= pos then TR._p1 = pos _G.ARKHER.toast("Region set. Copy to buffer.") else _G.ARKHER.toast("First corner set; click second.") end end
function TR.curRegion()
  if TR._p0 and TR._p1 then return Region3.new(TR._p0, TR._p1):ExpandToGrid(4) end
  return nil
end
function TR.copyRegion()
  local r = TR.curRegion()
  if not r then _G.ARKHER.toast("Pick 2 corners first (Region tool).") return end
  local ok, b = pcall(function() return T():CopyRegion(r) end)
  if ok and b then TR.buf = b _G.ARKHER.toast("Region copied.") else _G.ARKHER.toast("Copy failed.") end
end
function TR.pasteRegion()
  if not TR.buf then _G.ARKHER.toast("Buffer empty.") return end
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local r = Region3.new(c - Vector3.new(64, 64, 64), c + Vector3.new(64, 64, 64)):ExpandToGrid(4)
  backup(r)
  pcall(function() T():PasteRegion(TR.buf, r, true) end)
  _G.ARKHER.undo.commit("terrain paste")
end
function TR.clearAll()
  local r = Region3.new(Vector3.new(-512, -100, -512), Vector3.new(512, 512, 512))
  backup(r) T():Clear() _G.ARKHER.undo.commit("terrain clear")
end
function TR.fillAll(a)
  a = a or {}
  local r = Region3.new(Vector3.new(-512, -60, -512), Vector3.new(512, 0, 512))
  backup(r)
  T():FillBlock(CFrame.new(0, -30, 0), Vector3.new(1024, 60, 1024), mat(a.mat or "Grass"))
  _G.ARKHER.undo.commit("terrain fill")
end
function TR.readVox()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 500)
  if not hit then _G.ARKHER.toast("Aim at terrain.") return end
  local r = Region3.new(hit.Position - Vector3.new(2, 2, 2), hit.Position + Vector3.new(2, 2, 2)):ExpandToGrid(4)
  local mats, occ = T():ReadVoxels(r, 4)
  _G.ARKHER.out.log("Voxel: " .. tostring(mats[1][1][1]) .. " occ=" .. string.format("%.2f", occ[1][1][1] or 0))
end
function TR.preview() _G.ARKHER.toast("Preview: last terrain op is undoable (Ctrl+Z compares before/after).") end
function TR.export()
  local r = Region3.new(Vector3.new(-64, -20, -64), Vector3.new(64, 60, 64)):ExpandToGrid(4)
  local mats, occ = T():ReadVoxels(r, 4)
  local h = {}
  for x = 1, mats.Size.X do h[x] = {} for z = 1, mats.Size.Z do local top = 0 for y = 1, mats.Size.Y do if (occ[x][y][z] or 0) > 0.5 then top = y end end h[x][z] = top end end
  _G.ARKHER.out.log("HMAP " .. game:GetService("HttpService"):JSONEncode({ size = mats.Size.X, h = h }))
  _G.ARKHER.toast("Heightmap -> Output.")
end
function TR.import(a) _G.ARKHER.panel.open("terrain_import", a) end
_G.ARKHER.systems.terrain = TR
return TR
