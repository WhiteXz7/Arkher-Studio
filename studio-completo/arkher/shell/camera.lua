-- arkher/shell/camera.lua — camera presets/focus/frame (real CFrame ops).
local CAM = {}
function CAM.cam() return workspace.CurrentCamera end
function CAM.preset(p)
  local cam = CAM.cam() if not cam then return end
  local tgt = cam.Focus.Position
  local d = (cam.CFrame.Position - tgt).Magnitude
  if d < 1 then d = 30 end
  local dirs = { front = Vector3.new(0, 0, 1), back = Vector3.new(0, 0, -1), left = Vector3.new(-1, 0, 0), right = Vector3.new(1, 0, 0), top = Vector3.new(0, 1, 0.001), bottom = Vector3.new(0, -1, 0.001), persp = Vector3.new(1, 0.6, 1).Unit }
  local dir = dirs[p] or dirs.persp
  cam.CFrame = CFrame.new(tgt + dir * d, tgt)
  cam.Focus = CFrame.new(tgt)
end
function CAM.focus(list)
  local cam = CAM.cam() if not cam then return end
  list = list or {}
  if #list == 0 then _G.ARKHER.toast("Nothing selected.") return end
  local cf = list[1]:GetPivot()
  local dist = 20
  if list[1]:IsA("Model") then local _, sz = list[1]:GetBoundingBox() dist = math.max(sz.X, sz.Y, sz.Z) * 2 + 5 end
  local dir = (cam.CFrame.Position - cam.Focus.Position)
  if dir.Magnitude < 0.1 then dir = Vector3.new(1, 0.6, 1) end
  dir = dir.Unit
  cam.CFrame = CFrame.new(cf.Position + dir * dist, cf.Position)
  cam.Focus = CFrame.new(cf.Position)
end
function CAM.frameAll()
  local cam = CAM.cam() if not cam then return end
  local min, max = nil, nil
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") then local p = d.Position
      if not min then min, max = p, p else min = Vector3.new(math.min(min.X, p.X), math.min(min.Y, p.Y), math.min(min.Z, p.Z)) max = Vector3.new(math.max(max.X, p.X), math.max(max.Y, p.Y), math.max(max.Z, p.Z)) end
    end
  end
  if not min then return end
  local c = (min + max) / 2
  local dist = (max - min).Magnitude + 10
  cam.CFrame = CFrame.new(c + Vector3.new(1, 0.6, 1).Unit * dist, c)
  cam.Focus = CFrame.new(c)
end
function CAM.focusCF()
  local cam = CAM.cam()
  if not cam then return CFrame.new(0, 5, 0) end
  return CFrame.new(cam.Focus.Position + Vector3.new(0, 3, 0))
end
_G.ARKHER.systems = _G.ARKHER.systems or {}
_G.ARKHER.systems.camera = CAM
return CAM
