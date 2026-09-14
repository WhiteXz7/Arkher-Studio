-- arkher/systems/project.lua — project persistence (snapshots as JSON in ServerStorage).
local PR = { name = "Untitled", dirty = false, slots = {} }
local function E() return _G.ARKHER end
local function HS() return game:GetService("HttpService") end
function PR.folder()
  local ss = game:GetService("ServerStorage")
  local f = ss:FindFirstChild("ARKHER_proj") or Instance.new("Folder") f.Name = "ARKHER_proj" f.Parent = ss
  return f
end
function PR.snapshotData()
  local parts = {}
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and d ~= workspace.Terrain and not string.find(d:GetFullName(), "ARKHER_", 1, true) then
      parts[#parts + 1] = { c = d.ClassName, n = d.Name, cf = { d.CFrame:GetComponents() }, sz = { d.Size.X, d.Size.Y, d.Size.Z }, col = { d.Color.R, d.Color.G, d.Color.B }, mat = d.Material.Name, an = d.Anchored }
      if #parts >= 20000 then break end
    end
  end
  local l = game:GetService("Lighting")
  return { name = PR.name, parts = parts, lighting = { ct = l.ClockTime, br = l.Brightness }, t = os.time() }
end
function PR.writeSlot(slot, data)
  local f = PR.folder()
  local v = f:FindFirstChild(slot) or Instance.new("StringValue") v.Name = slot v.Parent = f
  v.Value = HS():JSONEncode(data)
end
function PR.readSlot(slot)
  local f = PR.folder()
  local v = f:FindFirstChild(slot)
  if not v or v.Value == "" then return nil end
  local ok, d = pcall(function() return HS():JSONDecode(v.Value) end)
  return ok and d or nil
end
function PR.new(a)
  a = a or {}
  for _, d in ipairs(workspace:GetChildren()) do
    if (d:IsA("BasePart") or d:IsA("Model") or d:IsA("Folder")) and d ~= workspace.Terrain and d.Name ~= "Camera" then d:Destroy() end
  end
  workspace.Terrain:Clear()
  if (a.template or "baseplate") ~= "empty" then
    local b = Instance.new("Part") b.Name = "Baseplate" b.Anchored = true b.Size = Vector3.new(512, 1, 512) b.Position = Vector3.new(0, -0.5, 0) b.Color = Color3.fromRGB(90, 160, 90) b.Parent = workspace
    local sp = Instance.new("SpawnLocation") sp.Anchored = true sp.Size = Vector3.new(6, 1, 6) sp.Position = Vector3.new(0, 0.5, 0) sp.Parent = workspace
  end
  PR.name = a.name or "Untitled"
  PR.dirty = false
  E().undo.commit("new project")
  E().toast("Project: " .. PR.name)
end
function PR.open(a) E().panel.open("project_open", a or {}) end
function PR.openSlot(slot)
  local d = PR.readSlot(slot)
  if not d then E().toast("Slot empty: " .. slot) return end
  PR.new({ name = d.name, template = "empty" })
  for _, p in ipairs(d.parts or {}) do
    local ok, inst = pcall(Instance.new, p.c)
    if ok and inst:IsA("BasePart") then
      inst.Name = p.n inst.CFrame = CFrame.new(unpack(p.cf)) inst.Size = Vector3.new(unpack(p.sz))
      inst.Color = Color3.new(unpack(p.col)) pcall(function() inst.Material = Enum.Material[p.mat] end) inst.Anchored = p.an
      inst.Parent = workspace
    end
  end
  if d.lighting then pcall(function() game:GetService("Lighting").ClockTime = d.lighting.ct game:GetService("Lighting").Brightness = d.lighting.br end) end
  PR.name = d.name or slot
  E().toast("Opened " .. PR.name .. " (" .. #(d.parts or {}) .. " parts).")
end
function PR.save() PR.writeSlot("save_" .. PR.name, PR.snapshotData()) PR.dirty = false E().toast("Saved " .. PR.name .. ".") end
function PR.saveas(name) if name and name ~= "" then PR.name = name end PR.save() end
function PR.revert() PR.openSlot("save_" .. PR.name) end
function PR.close() PR.new({ name = "Untitled", template = "empty" }) end
function PR.newplace() E().toast("Place slot registered in project cfg.") PR.snapshot() end
function PR.dupplace() PR.writeSlot("save_" .. PR.name .. "_copy", PR.snapshotData()) E().toast("Place duplicated.") end
function PR.archive() PR.writeSlot("archive_" .. os.time(), PR.snapshotData()) E().toast("Archived.") end
function PR.import(a) E().panel.open("project_import", a or {}) end
function PR.exportsel(list)
  local arr = {}
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") then arr[#arr + 1] = { c = o.ClassName, n = o.Name, cf = { o.CFrame:GetComponents() }, sz = { o.Size.X, o.Size.Y, o.Size.Z } } end end
  E().out.log("EXPORTSEL " .. HS():JSONEncode(arr))
  E().toast(#arr .. " objects -> Output.")
end
function PR.exportplace() E().out.log("PLACE " .. HS():JSONEncode(PR.snapshotData())) E().toast("Place -> Output.") end
function PR.importplace(a) E().panel.open("project_import", a or {}) end
function PR.publish(a) E().panel.open("project_publish", a or {}) end
function PR.cloudsave() PR.writeSlot("cloud_" .. PR.name, PR.snapshotData()) E().toast("Cloud slot saved (project storage).") end
function PR.cloudopen() E().panel.open("project_cloud", {}) end
function PR.backup() PR.writeSlot("backup_" .. os.time(), PR.snapshotData()) E().toast("Backup written.") end
function PR.restore(a) E().panel.open("project_restore", a or {}) end
function PR.snapshot(name) PR.writeSlot("snap_" .. (name or os.time()), PR.snapshotData()) E().toast("Snapshot saved.") end
function PR.cleanup()
  local n = 0
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and not d.Anchored and d.Position.Y < workspace.FallenPartsDestroyHeight + 50 then d:Destroy() n = n + 1 end
  end
  E().toast("Cleaned " .. n .. " fallen parts.")
end
function PR.validate()
  local errs, warns = {}, {}
  local spawns = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("SpawnLocation") then spawns = spawns + 1 end end
  if spawns == 0 then warns[#warns + 1] = "No SpawnLocation." end
  local lights = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Light") and d.Enabled then lights = lights + 1 end end
  if lights > 64 then warns[#warns + 1] = lights .. " enabled lights (perf risk)." end
  E().out.log("Validate: " .. #errs .. " errors, " .. #warns .. " warnings.")
  for _, w in ipairs(warns) do E().out.warn(w) end
  E().panel.open("project_validate", { errs = errs, warns = warns })
end
E().systems.project = PR
return PR
