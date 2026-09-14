-- arkher/systems/mat.lua — material library + apply + variants.
local MT = { buf = nil, lib = {} }
local function E() return _G.ARKHER end
local MATS = { "Plastic", "Wood", "WoodPlanks", "Marble", "Slate", "Concrete", "Granite", "Brick", "Sand", "Grass", "Metal", "DiamondPlate", "Foil", "Glass", "Ice", "Neon", "Fabric", "CorrodedMetal", "SmoothPlastic", "ForceField", "Sandstone", "Limestone", "Basalt", "Asphalt", "Cobblestone", "Pebble", "Salt", "Snow", "CrackedLava", "Glacier", "Ground", "Mud", "Rock", "LeafyGrass", "Cardboard", "Carpet", "CeramicTiles", "ClayRoofTiles", "RoofShingles", "Leather", "Rubber", "Tin", "Titanium", "Zinc", "Copper", "Iron" }
function MT.list() return MATS end
function MT.current() return E().store.get("paint_mat") or "Plastic" end
function MT.apply(list)
  local m = MT.current()
  local ok, e = pcall(function() return Enum.Material[m] end)
  if not ok then E().toast("Bad material: " .. m) return end
  local n = 0
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") then E().undo.prop(o, "Material", e, "apply material") n = n + 1 end end
  E().undo.commit("apply material")
  E().toast(n .. " part(s) -> " .. m)
end
function MT.fill(list)
  MT.apply(list)
  local ok, c = pcall(function() return Color3.fromName(E().store.get("paint_color") or "Bright red") end)
  if ok then for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") then E().undo.prop(o, "Color", c, "fill color") end end E().undo.commit() end
end
function MT.surfaceApp(list)
  local n = 0
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") and not o:FindFirstChildWhichIsA("SurfaceAppearance") then local s = Instance.new("SurfaceAppearance") s.Parent = o E().undo.created(s) n = n + 1 end end
  E().undo.commit("surfaceapp") E().toast(n .. " SurfaceAppearance created.")
end
function MT.deleteCustom() E().toast("Select a MaterialVariant in Explorer and delete (Del).") end
function MT.copyProp(o)
  if o and o:IsA("BasePart") then MT.buf = { mat = o.Material.Name, col = { o.Color.R, o.Color.G, o.Color.B }, tr = o.Transparency, re = o.Reflectance } E().toast("Look copied.") else E().toast("Select a part.") end
end
function MT.pasteProp(list)
  if not MT.buf then E().toast("Buffer empty.") return end
  for _, o in ipairs(list or {}) do if o and o.Parent and o:IsA("BasePart") then
    o.Material = Enum.Material[MT.buf.mat] o.Color = Color3.new(unpack(MT.buf.col)) o.Transparency = MT.buf.tr o.Reflectance = MT.buf.re
  end end
  E().undo.commit("paste look")
end
function MT.cleanUnused()
  local used = {}
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("BasePart") and d.MaterialVariant ~= "" then used[d.MaterialVariant] = true end end
  local n = 0
  for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do if d:IsA("MaterialVariant") and not used[d.Name] then d:Destroy() n = n + 1 end end
  E().toast("Removed " .. n .. " unused variants.")
end
function MT.audit()
  local missing = 0
  for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("SurfaceAppearance") and d.ColorMap == "" then missing = missing + 1 end end
  E().out.log("Material audit: " .. missing .. " SurfaceAppearance without ColorMap.")
end
function MT.export() E().out.log("MATLIB " .. game:GetService("HttpService"):JSONEncode(MT.lib)) E().toast("Material pack -> Output.") end
function MT.import(a) E().panel.open("mat_import", a) end
E().systems.mat = MT
return MT
