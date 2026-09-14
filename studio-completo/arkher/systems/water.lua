-- arkher/systems/water.lua — water kits + presets (Terrain water is real).
local W = {}
local function E() return _G.ARKHER end
local function T() return workspace.Terrain end
function W.ocean(a)
  a = a or {}
  local t = T()
  t:FillBlock(CFrame.new(0, -35, 0), Vector3.new(1024, 10, 1024), Enum.Material.Sand)
  t:FillBlock(CFrame.new(0, -25, 0), Vector3.new(1024, 10, 1024), Enum.Material.Water)
  E().undo.commit("ocean")
end
function W.lake(a)
  a = a or {}
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local r = a.r or 20
  T():FillBall(c, r + 6, Enum.Material.Air)
  T():FillBall(c + Vector3.new(0, -4, 0), r, Enum.Material.Water)
  E().undo.commit("lake")
end
function W.waterfall(a)
  a = a or {}
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local m = Instance.new("Model") m.Name = "Waterfall"
  local h = a.height or 30
  local sheet = Instance.new("Part") sheet.Name = "Sheet" sheet.Anchored = true sheet.CanCollide = false
  sheet.Size = Vector3.new(a.width or 8, h, 1) sheet.Material = Enum.Material.Glass sheet.Transparency = 0.3
  sheet.Color = Color3.fromRGB(100, 180, 255) sheet.CFrame = CFrame.new(c + Vector3.new(0, h / 2, 0)) sheet.Parent = m
  local em = Instance.new("ParticleEmitter") em.Rate = 60 em.Speed = NumberRange.new(10, 15) em.Lifetime = NumberRange.new(0.5, 1)
  em.Size = NumberSequence.new(2) em.Transparency = NumberSequence.new(0.5) em.Parent = sheet
  local snd = Instance.new("Sound") snd.SoundId = "" snd.Looped = true snd.Volume = 0.5 snd.Parent = sheet
  m.Parent = workspace E().undo.created(m) E().undo.commit("waterfall") E().sel.set({ m })
end
local WPRE = {
  tropical = { WaterColor3 = Color3.fromRGB(40, 170, 200), WaterTransparency = 0.4, WaterWaveSize = 0.4, WaterWaveSpeed = 12 },
  murky = { WaterColor3 = Color3.fromRGB(60, 70, 40), WaterTransparency = 0.1, WaterWaveSize = 0.1, WaterWaveSpeed = 5 },
  arctic = { WaterColor3 = Color3.fromRGB(150, 200, 230), WaterTransparency = 0.2, WaterWaveSize = 0.2, WaterWaveSpeed = 4 },
  storm = { WaterColor3 = Color3.fromRGB(30, 50, 70), WaterTransparency = 0.1, WaterWaveSize = 1.2, WaterWaveSpeed = 25 },
}
function W.preset(name)
  local p = WPRE[name] if not p then return end
  for k, v in pairs(p) do pcall(function() T()[k] = v end) end
  E().toast("Water: " .. name)
end
function W.freeze()
  pcall(function() T().WaterColor3 = Color3.fromRGB(200, 230, 245) T().WaterWaveSize = 0 T().WaterWaveSpeed = 0 T().WaterTransparency = 0 end)
  E().toast("Water frozen (still + icy).")
end
function W.ice()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  local c = hit and hit.Position or cam.Focus.Position
  local p = Instance.new("Part") p.Name = "IceSheet" p.Anchored = true
  p.Size = Vector3.new(30, 1, 30) p.Material = Enum.Material.Ice p.CFrame = CFrame.new(c.X, c.Y + 0.5, c.Z) p.Parent = workspace
  E().undo.created(p) E().undo.commit("ice") E().sel.set({ p })
end
function W.depth()
  local cam = workspace.CurrentCamera
  local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 800)
  if not hit then E().toast("Aim at water.") return end
  local surf = hit.Position.Y
  local deep = workspace:Raycast(hit.Position + Vector3.new(0, 1, 0), Vector3.new(0, -200, 0))
  if deep then E().out.log(string.format("Depth: %.1f studs", surf - deep.Position.Y)) else E().toast("No bottom found.") end
end
function W.audit()
  local r = Region3.new(Vector3.new(-256, -60, -256), Vector3.new(256, 60, 256)):ExpandToGrid(4)
  local mats, occ = T():ReadVoxels(r, 4)
  local n = 0
  for x = 1, mats.Size.X, 2 do for y = 1, mats.Size.Y, 2 do for z = 1, mats.Size.Z, 2 do if mats[x][y][z] == Enum.Material.Water and (occ[x][y][z] or 0) > 0.1 then n = n + 1 end end end end
  E().out.log("Water cells (sampled): ~" .. (n * 8))
end
function W.export() local t = T() E().out.log("WATER " .. game:GetService("HttpService"):JSONEncode({ c = { t.WaterColor3.R, t.WaterColor3.G, t.WaterColor3.B }, tr = t.WaterTransparency, ws = t.WaterWaveSize })) end
function W.reset() W.preset("tropical") end
E().systems.water = W
return W
