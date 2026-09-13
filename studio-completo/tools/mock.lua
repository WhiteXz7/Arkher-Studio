-- Mock Roblox focado para testar o ArkherEditorServer (server.lua).
-- Cobre o suficiente: Instance, Clone, CFrame, Model, RemoteFunction/Event,
-- servicos de raiz, HttpService, Players.
local WAIT_BUDGET = 20000
local waits = 0
function wait(n) waits = waits + 1 if waits > WAIT_BUDGET then return nil end return n or (1/60) end
loadstring = loadstring or load
tick = tick or os.clock

-- require global para ModuleScript (compila Source e retorna o resultado, com cache)
require = function(mod)
  if type(mod) ~= "table" then error("require: argumento inválido") end
  local props = rawget(mod, "__props")
  if not props or props.ClassName ~= "ModuleScript" then error("require: não é um ModuleScript") end
  local src = props.Source
  if type(src) ~= "string" or src == "" then error("require: ModuleScript sem Source") end
  if props._reqCache ~= nil then return props._reqCache end
  local fn = assert(load(src, "@ArkherModule"))
  local result = fn()
  props._reqCache = result
  return result
end
warn = warn or print
if not math.clamp then math.clamp = function(v, lo, hi) return math.max(lo, math.min(hi, v)) end end
if not math.atan2 then
  math.atan2 = function(y, x)
    if x > 0 then return math.atan(y / x) end
    if x < 0 then
      if y >= 0 then return math.atan(y / x) + math.pi else return math.atan(y / x) - math.pi end
    end
    if y > 0 then return math.pi / 2 elseif y < 0 then return -math.pi / 2 else return 0 end
  end
end

-- ============ Enum ============
local function autoenum(name)
  local last = name:match("([^.]+)$") or name
  local items = {}
  local _, dots = name:gsub("%.", ".")
  local t = { __name = name, Name = last, __t = (dots >= 2 and "EnumItem" or "Enum") }
  function t:GetEnumItems()
    local out = {}
    for _, v in ipairs(items) do out[#out + 1] = v end
    return out
  end
  setmetatable(t, { __index = function(self, k)
    local c = rawget(self, k)
    if c == nil then
      c = autoenum(name .. "." .. tostring(k))
      rawset(self, k, c)
      items[#items + 1] = c
    end
    return c
  end })
  return t
end
Enum = autoenum("Enum")

-- ============ math types ============
Color3 = {}
function Color3.fromRGB(r,g,b) return { R=r/255, G=g/255, B=b/255, __t="Color3" } end
function Color3.new(r,g,b) return { R=r or 0, G=g or 0, B=b or 0, __t="Color3" } end
function Color3.fromHSV(h,s,v)
  h = (h % 1 + 1) % 1
  local c = v * s
  local x = c * (1 - math.abs((h * 6) % 2 - 1))
  local m = v - c
  local r, g, b = 0, 0, 0
  local hh = h * 6
  if hh < 1 then r, g, b = c, x, 0
  elseif hh < 2 then r, g, b = x, c, 0
  elseif hh < 3 then r, g, b = 0, c, x
  elseif hh < 4 then r, g, b = 0, x, c
  elseif hh < 5 then r, g, b = x, 0, c
  else r, g, b = c, 0, x end
  return { R=r+m, G=g+m, B=b+m, __t="Color3" }
end
function Color3.toHSV(c)
  local r, g, b = c.R, c.G, c.B
  local mx = math.max(r, g, b)
  local mn = math.min(r, g, b)
  local d = mx - mn
  local h = 0
  if d ~= 0 then
    if mx == r then h = ((g - b) / d) % 6
    elseif mx == g then h = (b - r) / d + 2
    else h = (r - g) / d + 4 end
    h = h / 6
    if h < 0 then h = h + 1 end
  end
  local s = (mx == 0) and 0 or (d / mx)
  return h, s, mx
end
-- Paleta BrickColor oficial (só o que o CORES X usa + fallback real)
BrickColor = {}
local BRICK_PALETTE = {
  ["Bright red"] = {196,40,28}, ["Bright blue"] = {13,105,172}, ["Bright green"] = {75,151,75},
  ["Bright yellow"] = {245,205,48}, ["Bright orange"] = {218,133,65}, ["Bright violet"] = {107,50,124},
  ["White"] = {242,243,243}, ["Black"] = {27,42,53},
  ["Dark stone grey"] = {99,95,98}, ["Medium stone grey"] = {163,162,165}, ["Light stone grey"] = {229,228,223},
  ["Deep orange"] = {255,176,0}, ["Navy blue"] = {0,32,96}, ["Lime green"] = {0,255,0},
  ["Pink"] = {255,102,204}, ["Cyan"] = {4,175,236}, ["Gold"] = {239,184,56},
  ["Really red"] = {255,0,0}, ["Really blue"] = {0,0,255}, ["Earth green"] = {39,70,45},
  ["Brick yellow"] = {215,197,154}, ["New Yeller"] = {255,255,0}, ["Hot pink"] = {255,0,191},
}
function BrickColor.new(nm)
  local rgb = BRICK_PALETTE[nm]
  if not rgb then nm = "Medium stone grey" rgb = BRICK_PALETTE[nm] end
  return { Name = nm, Number = 0, Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3]), __t = "BrickColor" }
end
Vector3 = {}
local V3MT = { __index=function(self, k)
    if k == "Magnitude" then
      local x, y, z = rawget(self, "X") or 0, rawget(self, "Y") or 0, rawget(self, "Z") or 0
      return math.sqrt(x * x + y * y + z * z)
    end
    if k == "Unit" then
      local x, y, z = rawget(self, "X") or 0, rawget(self, "Y") or 0, rawget(self, "Z") or 0
      local m2 = math.sqrt(x * x + y * y + z * z)
      if m2 == 0 then return Vector3.new(0, 0, 0) end
      return Vector3.new(x / m2, y / m2, z / m2)
    end
    return Vector3[k]
  end,
  __mul=function(a,b)
    if type(b)=="number" then return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
    if type(a)=="number" then return Vector3.new(b.X*a,b.Y*a,b.Z*a) end
    return Vector3.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z)
  end,
  __add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end,
  __sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end,
  __div=function(a,b)
    if type(b)=="number" then return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
    return Vector3.new(a.X/b.X,a.Y/b.Y,a.Z/b.Z)
  end }
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__t="Vector3"},V3MT) end
CFrame = {}
local function cfBuild(px,py,pz,r00,r01,r02,r10,r11,r12,r20,r21,r22)
  return setmetatable({ Position=Vector3.new(px,py,pz),
    r00=r00,r01=r01,r02=r02,r10=r10,r11=r11,r12=r12,r20=r20,r21=r21,r22=r22,__t="CFrame"},CFMT)
end
CFMT = { __index=function(self,k)
    if k=="LookVector" then return Vector3.new(-rawget(self,"r02"),-rawget(self,"r12"),-rawget(self,"r22")) end
    if k=="RightVector" then return Vector3.new(rawget(self,"r00"),rawget(self,"r10"),rawget(self,"r20")) end
    if k=="UpVector" then return Vector3.new(rawget(self,"r01"),rawget(self,"r11"),rawget(self,"r21")) end
    return CFrame[k]
  end,
  __sub=function(a,b)
    if type(b)=="table" and b.Position and b.r00 then
      local p=a.Position-b.Position return CFrame.new(p.X,p.Y,p.Z) end
    return CFrame.new(a.Position-b.X,a.Position.Y-b.Y,a.Position.Z-b.Z)
  end,
  __mul=function(a,b)
    if type(b)=="table" and b.r00 then
      local A, B = a, b
      local r00=A.r00*B.r00+A.r01*B.r10+A.r02*B.r20
      local r01=A.r00*B.r01+A.r01*B.r11+A.r02*B.r21
      local r02=A.r00*B.r02+A.r01*B.r12+A.r02*B.r22
      local r10=A.r10*B.r00+A.r11*B.r10+A.r12*B.r20
      local r11=A.r10*B.r01+A.r11*B.r11+A.r12*B.r21
      local r12=A.r10*B.r02+A.r11*B.r12+A.r12*B.r22
      local r20=A.r20*B.r00+A.r21*B.r10+A.r22*B.r20
      local r21=A.r20*B.r01+A.r21*B.r11+A.r22*B.r21
      local r22=A.r20*B.r02+A.r21*B.r12+A.r22*B.r22
      local p=B.Position
      local px=A.r00*p.X+A.r01*p.Y+A.r02*p.Z+A.Position.X
      local py=A.r10*p.X+A.r11*p.Y+A.r12*p.Z+A.Position.Y
      local pz=A.r20*p.X+A.r21*p.Y+A.r22*p.Z+A.Position.Z
      return cfBuild(px,py,pz,r00,r01,r02,r10,r11,r12,r20,r21,r22)
    end
    local p = (type(b)=="table" and b.X and b) or Vector3.new(0,0,0)
    local px=a.r00*p.X+a.r01*p.Y+a.r02*p.Z+a.Position.X
    local py=a.r10*p.X+a.r11*p.Y+a.r12*p.Z+a.Position.Y
    local pz=a.r20*p.X+a.r21*p.Y+a.r22*p.Z+a.Position.Z
    return Vector3.new(px,py,pz)
  end }
function CFrame.new(x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22)
  if type(x)=="table" and x.X and type(y)=="table" and y.X and r00==nil then
    return CFrame.lookAt(x, y)
  end
  if type(x)=="table" and x.X and r00==nil then return cfBuild(x.X,x.Y,x.Z,1,0,0,0,1,0,0,0,1) end
  if type(x)=="table" and x.Position and r00==nil then
    return cfBuild(x.Position.X,x.Position.Y,x.Position.Z,1,0,0,0,1,0,0,0,1) end
  return cfBuild(x or 0,y or 0,z or 0,r00 or 1,r01 or 0,r02 or 0,r10 or 0,r11 or 1,r12 or 0,r20 or 0,r21 or 0,r22 or 1)
end
function CFrame.fromEulerAnglesYXZ(x,y,z)
  x,y,z = x or 0, y or 0, z or 0
  local cx,sx,cy,sy,cz,sz = math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
  local r00=cy*cz+sy*sx*sz r01=-cy*sz+sy*sx*cz r02=sy*cx
  local r10=cx*sz r11=cx*cz r12=-sx
  local r20=-sy*cz+cy*sx*sz r21=sy*sz+cy*sx*cz r22=cy*cx
  return cfBuild(0,0,0,r00,r01,r02,r10,r11,r12,r20,r21,r22)
end
function CFrame.Angles(x,y,z)
  x,y,z = x or 0, y or 0, z or 0
  local cx,sx,cy,sy,cz,sz = math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
  local r00=cy*cz r01=-cy*sz r02=sy
  local r10=cz*sx*sy+cx*sz r11=cx*cz-sx*sy*sz r12=-cy*sx
  local r20=sx*sz-cx*cz*sy r21=cz*sx+cx*sy*sz r22=cx*cy
  return cfBuild(0,0,0,r00,r01,r02,r10,r11,r12,r20,r21,r22)
end
function CFrame.fromOrientation(x,y,z) return CFrame.fromEulerAnglesYXZ(x,y,z) end
function CFrame.lookAt(a,b)
  a = (type(a)=="table" and a.Position) or a
  b = (type(b)=="table" and b.Position) or b
  local fwd = (Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z))
  local m = fwd.Magnitude
  if m < 1e-6 then return CFrame.new(a.X,a.Y,a.Z) end
  fwd = fwd / m
  local up = Vector3.new(0,1,0)
  local r = Vector3.new(up.Y*fwd.Z-up.Z*fwd.Y, up.Z*fwd.X-up.X*fwd.Z, up.X*fwd.Y-up.Y*fwd.X)
  local rm = r.Magnitude
  if rm < 1e-6 then r = Vector3.new(1,0,0) else r = r / rm end
  local u = Vector3.new(fwd.Y*r.Z-fwd.Z*r.Y, fwd.Z*r.X-fwd.X*r.Z, fwd.X*r.Y-fwd.Y*r.X)
  return cfBuild(a.X,a.Y,a.Z, r.X,u.X,fwd.X, r.Y,u.Y,fwd.Y, r.Z,u.Z,fwd.Z)
end
function CFrame:ToEulerAnglesYXZ()
  local r02,r12,r22 = rawget(self,"r02"),rawget(self,"r12"),rawget(self,"r22")
  local x = math.asin(math.max(-1, math.min(1, -r12)))
  local y = math.atan2(r02, r22)
  local z = math.atan2(rawget(self,"r10"), rawget(self,"r11"))
  return x, y, z
end
function CFrame:ToOrientation()
  local y = math.atan2(rawget(self,"r02"), rawget(self,"r22"))
  local x = math.atan2(-rawget(self,"r12"), math.sqrt(rawget(self,"r02")^2 + rawget(self,"r22")^2))
  local z = math.atan2(rawget(self,"r10"), rawget(self,"r11"))
  return x, y, z
end
function CFrame:GetComponents()
  local p = rawget(self,"Position")
  return p.X,p.Y,p.Z,rawget(self,"r00"),rawget(self,"r01"),rawget(self,"r02"),
    rawget(self,"r10"),rawget(self,"r11"),rawget(self,"r12"),rawget(self,"r20"),rawget(self,"r21"),rawget(self,"r22")
end
function CFrame:Inverse()
  local p = rawget(self,"Position")
  local t00,t01,t02 = rawget(self,"r00"),rawget(self,"r10"),rawget(self,"r20")
  local t10,t11,t12 = rawget(self,"r01"),rawget(self,"r11"),rawget(self,"r21")
  local t20,t21,t22 = rawget(self,"r02"),rawget(self,"r12"),rawget(self,"r22")
  local px = -(t00*p.X+t01*p.Y+t02*p.Z)
  local py = -(t10*p.X+t11*p.Y+t12*p.Z)
  local pz = -(t20*p.X+t21*p.Y+t22*p.Z)
  return cfBuild(px,py,pz,t00,t01,t02,t10,t11,t12,t20,t21,t22)
end
UDim2 = {} function UDim2.new(a,b,c,d) return {X={Scale=a or 0,Offset=b or 0},Y={Scale=c or 0,Offset=d or 0},__t="UDim2"} end
UDim2.fromOffset = function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale = function(a,b) return UDim2.new(a,0,b,0) end
UDim = {} function UDim.new(a,b) return {Scale=a or 0,Offset=b or 0,__t="UDim"} end
ColorSequence = {} function ColorSequence.new(...) return {__t="ColorSequence"} end
Vector2 = {} function Vector2.new(x,y) return {X=x or 0,Y=y or 0,__t="Vector2"} end
Vector3int16 = {} function Vector3int16.new(x,y,z) return {X=x or 0,Y=y or 0,Z=z or 0,__t="Vector3int16"} end
Region3 = {}
function Region3.new(a, b)
  local mn = Vector3.new(math.min(a.X,b.X), math.min(a.Y,b.Y), math.min(a.Z,b.Z))
  local mx = Vector3.new(math.max(a.X,b.X), math.max(a.Y,b.Y), math.max(a.Z,b.Z))
  local r = { Min = mn, Max = mx, Size = mx - mn, CFrame = CFrame.new((mn.X+mx.X)/2,(mn.Y+mx.Y)/2,(mn.Z+mx.Z)/2), __t="Region3" }
  function r:ExpandToGrid(res)
    res = res or 4
    local f = function(v) return math.floor(v/res)*res end
    local c = function(v) return math.ceil(v/res)*res end
    return Region3.new(Vector3.new(f(mn.X),f(mn.Y),f(mn.Z)), Vector3.new(c(mx.X),c(mx.Y),c(mx.Z)))
  end
  return r
end
Region3int16 = {}
function Region3int16.new(a, b)
  return { Min = a, Max = b, __t="Region3int16" }
end

-- ============ Event ============
local Event = {} Event.__index = Event
function Event.new(name) return setmetatable({handlers={},Name=name},Event) end
function Event:Connect(fn) table.insert(self.handlers,fn) return {Disconnect=function() end} end
function Event:Fire(...) for _,h in ipairs(self.handlers) do pcall(h,...) end end
function Event:Wait() return nil end

-- ============ task (schedulador simplificado) ============
task = {
  spawn = function(f, ...) if type(f) == "function" then local ok, e = pcall(f, ...) if not ok then warn("[task.spawn] " .. tostring(e)) end end end,
  defer = function(f, ...) if type(f) == "function" then pcall(f, ...) end end,
  delay = function(_t, f, ...) if type(f) == "function" then pcall(f, ...) end end,
  wait = function(_t) return nil end,
}
wait = function(_t) return nil end  -- v2: corrotinas de build completam na hora

-- ============ Instance ============
local CLASS_SUPER = {
  Frame="GuiObject", TextLabel="GuiObject", ScrollingFrame="GuiObject",
  TextButton="GuiButton", ImageButton="GuiButton", GuiButton="GuiObject", TextBox="GuiObject",
  ImageLabel="GuiObject", ViewportFrame="GuiObject", VideoFrame="GuiObject", CanvasGroup="GuiObject",
  ScreenGui="LayerCollector", LayerCollector="Instance",
  BindableFunction="Instance", BindableEvent="Instance", RemoteEvent="Instance", RemoteFunction="Instance",
  UnreliableRemoteEvent="Instance", UIScale="Instance", WeldConstraint="Instance", Motor6D="Instance",
  UICorner="Instance", UIStroke="Instance", UIGradient="Instance", UIPadding="Instance",
  UIListLayout="Instance", UIGridLayout="Instance", UIAspectRatioConstraint="Instance", UISizeConstraint="Instance",
  Folder="Instance", Model="Instance",
  Part="BasePart", WedgePart="BasePart", CornerWedgePart="BasePart", TrussPart="BasePart",
  UnionOperation="BasePart", MeshPart="BasePart",
  SpawnLocation="BasePart", MeshPart="BasePart", BasePart="Volume", Volume="Instance",
  Terrain="BasePart",
  Script="BaseScript", LocalScript="BaseScript", ModuleScript="BaseScript", BaseScript="LuaSourceContainer", LuaSourceContainer="Instance",
  Attachment="Instance", Decal="Instance", Texture="Instance",
  PointLight="Light", SpotLight="Light", SurfaceLight="Light", Light="Instance",
  ParticleEmitter="Instance", Fire="Instance", Smoke="Instance", Sparkles="Instance",
  Sound="Instance", ClickDetector="Instance", ProximityPrompt="Instance",
  MaterialVariant="Instance", Tool="Instance",
  BoolValue="ValueBase", IntValue="ValueBase", NumberValue="ValueBase", StringValue="ValueBase",
  Vector3Value="ValueBase", Color3Value="ValueBase", ObjectValue="ValueBase", ValueBase="Instance",
}
local AUTO_EVENTS = { "AncestryChanged","Changed","Destroying","DescendantAdded","DescendantRemoving",
  "PlayerRemoving","OnServerEvent","PlayerAdded","InputBegan","InputChanged","InputEnded","SelectionChanged",
  "Activated","MouseEnter","MouseLeave","MouseButton1Click","MouseButton2Click","TouchTap","TouchTapInWorld",
  "TouchLongPress","TouchPinch","TouchPan","FocusLost",
  "ChildAdded","ChildRemoved","MessageOut","Heartbeat","RenderStepped","Stepped" }
local fireDescendantAdded, fireDescendantRemoving  -- forward declarations
local MT = {}
MT.__index = function(self,k)
  local raw = rawget(self,"__props")[k]
  if raw ~= nil then return raw end
  local ev = rawget(self,"__events")[k]
  if ev == nil then
    for _,n in ipairs(AUTO_EVENTS) do if k==n then ev=Event.new(k); rawget(self,"__events")[k]=ev; break end end
  end
  if ev then return ev end
  if METHODS and METHODS[k] then return METHODS[k] end
  if k=="CFrame" then
    local cf = rawget(self,"__props").CFrame
    if cf then return cf end
    local p = rawget(self,"__props").Position
    if p then return CFrame.new(p.X,p.Y,p.Z) end
    return CFrame.new(0,0,0)
  end
  return nil
end
MT.__newindex = function(self,k,v)
  if k=="Parent" then
    local old = rawget(self,"__props").Parent
    if old then
      local kids = rawget(old,"__children")
      for i=#kids,1,-1 do if kids[i]==self then table.remove(kids,i) end end
      local cr = rawget(old, "__events").ChildRemoved
      if cr then for _, h in ipairs(cr.handlers) do pcall(h, self) end end
      for _,h in ipairs(rawget(self, "__events").AncestryChanged and rawget(self, "__events").AncestryChanged.handlers or {}) do pcall(h,self,old,nil) end
    end
    rawget(self,"__props").Parent = v
    if v then
      table.insert(rawget(v,"__children"), self)
      for _,h in ipairs(rawget(self,"__events").AncestryChanged and rawget(self,"__events").AncestryChanged.handlers or {}) do pcall(h,self,v,nil) end
      local ca = rawget(v, "__events").ChildAdded
      if ca then for _, h in ipairs(ca.handlers) do pcall(h, self) end end
      -- DescendantAdded no pai (recursivo)
      fireDescendantAdded(v, self)
    end
    return
  end
  if k=="Position" and type(v)=="table" and v.X then
    rawget(self,"__props").Position = v
    rawget(self,"__props").CFrame = CFrame.new(v.X, v.Y, v.Z)
    rawget(self,"__explicit").CFrame = true
    rawget(self,"__explicit").Position = true
  elseif k=="CFrame" and type(v)=="table" and v.Position then
    rawget(self,"__props").CFrame = v
    rawget(self,"__props").Position = v.Position
    rawget(self,"__explicit").CFrame = true
    rawget(self,"__explicit").Position = true
    local p = rawget(self,"__props").Parent
    if p then
      for _,h in ipairs(rawget(p,"__events").DescendantAdded and rawget(p,"__events").DescendantAdded.handlers or {}) do end
    end
  else
    rawget(self,"__props")[k] = v
    if k ~= "Parent" then rawget(self,"__explicit")[k] = true end
  end
  local ch = rawget(self,"__events").Changed
  if ch then ch:Fire(k) end
end

fireDescendantAdded = function(root, added)
  -- propaga DescendantAdded para o root e todos os ancestors ate o root
  local p = rawget(added,"__props").Parent
  while p do
    local ev = rawget(p,"__events").DescendantAdded
    if ev then for _,h in ipairs(ev.handlers) do pcall(h,added) end end
    p = rawget(p,"__props").Parent
  end
end
fireDescendantRemoving = function(root, removing)
  local p = rawget(removing,"__props").Parent
  while p do
    local ev = rawget(p,"__events").DescendantRemoving
    if ev then for _,h in ipairs(ev.handlers) do pcall(h,removing) end end
    p = rawget(p,"__props").Parent
  end
end

local function isA(self,cls)
  local c = rawget(self,"__props").ClassName
  while c do if c==cls then return true end c=CLASS_SUPER[c] end
  return false
end
local CLASS_DEFAULTS = {
  BasePart = { Transparency=0, Color=Color3.new(1,1,1), Material=Enum.Material.Plastic, Anchored=false,
    CanCollide=true, CanTouch=true, CanQuery=true, CastShadow=true, Locked=false, Reflectance=0 },
  GuiObject = { BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0, Active=false, Rotation=0,
    AbsoluteSize=Vector2.new(0,0), AbsolutePosition=Vector2.new(0,0), AbsoluteRotation=0, ZIndex=1, LayoutOrder=0,
    BorderSizePixel=1, ZIndex=1 },
  LayerCollector = { AbsoluteSize=Vector2.new(1568,882), AbsolutePosition=Vector2.new(0,0) },
  TextLabel = { TextColor3=Color3.new(0,0,0), TextSize=14 },
  TextButton = { TextColor3=Color3.new(1,1,1), TextSize=14, AutoButtonColor=true },
  TextBox = { TextColor3=Color3.new(1,1,1), TextSize=14, ClearTextOnFocus=true },
  ImageLabel = { BackgroundTransparency=1 },
  BaseScript = { Enabled=false, Source="" },
  Sound = { Volume=0, Looped=false, PlaybackSpeed=1, SoundId="rbxassetid://0" },
  ValueBase = { Value=nil },
}
local function mkInstance(class)
  local o = setmetatable({
    __props={ Name=class, ClassName=class, Visible=true, Text="", Position=Vector3.new(0,0,0),
      CFrame=CFrame.new(0,0,0), Size=Vector3.new(0,0,0) },
    __children={}, __events={}, __attrs={}, __explicit={},
  },MT)
  local c = class
  while c do
    local d = CLASS_DEFAULTS[c]
    if d then
      for k, v in pairs(d) do
        if v ~= nil and rawget(o, "__props")[k] == nil then rawget(o, "__props")[k] = v end
      end
    end
    c = CLASS_SUPER[c]
  end
  return o
end
METHODS = {}
function METHODS:Destroy()
  local p = rawget(self,"__props").Parent
  if p then
    fireDescendantRemoving(p, self)
    local kids = rawget(p,"__children")
    for i=#kids,1,-1 do if kids[i]==self then table.remove(kids,i) end end
  end
  rawget(self,"__props").Parent = nil
end
function METHODS:ClearAllChildren()
  for _,ch in ipairs({table.unpack(rawget(self,"__children"))}) do ch:Destroy() end
end
function METHODS:GetChildren()
  local out={}
  for _,ch in ipairs(rawget(self,"__children")) do out[#out+1]=ch end
  return out
end
function METHODS:GetDescendants()
  local out={}
  local function rec(o) for _,ch in ipairs(rawget(o,"__children")) do out[#out+1]=ch; rec(ch) end end
  rec(self)
  return out
end
function METHODS:FindFirstChild(n, recursive)
  for _,ch in ipairs(rawget(self,"__children")) do
    if rawget(ch,"__props").Name==n then return ch end
  end
  if recursive then
    for _,ch in ipairs(rawget(self,"__children")) do
      local r = ch:FindFirstChild(n, true)
      if r then return r end
    end
  end
  return nil
end
function METHODS:FindFirstChildWhichIsA(cls, recursive)
  for _,ch in ipairs(rawget(self,"__children")) do if ch:IsA(cls) then return ch end end
  if recursive then
    for _,ch in ipairs(rawget(self,"__children")) do
      local r = ch:FindFirstChildWhichIsA(cls, true)
      if r then return r end
    end
  end
  return nil
end
function METHODS:FindFirstAncestor(n)
  local p = rawget(self,"__parent")
  while p do if rawget(p,"__props").Name==n then return p end p = rawget(p,"__parent") end
  return nil
end
function METHODS:FindFirstAncestorWhichIsA(cls)
  local p = rawget(self,"__parent")
  while p do if p:IsA(cls) then return p end p = rawget(p,"__parent") end
  return nil
end
function METHODS:WaitForChild(n,t) return self:FindFirstChild(n) end
function METHODS:FindFirstChildOfClass(c) for _,ch in ipairs(rawget(self,"__children")) do if isA(ch,c) then return ch end end return nil end
function METHODS:FindFirstAncestorOfClass(c)
  local p = rawget(self,"__props").Parent
  while p do if isA(p,c) then return p end p = rawget(p,"__props").Parent end
  return nil
end
function METHODS:FindFirstAncestor(n)
  local p = rawget(self,"__props").Parent
  while p do if rawget(p,"__props").Name==n then return p end p = rawget(p,"__props").Parent end
  return nil
end
function METHODS:IsA(c) return isA(self,c) end

-- ============ R10 Terrain voxel (mesma API do real: Fill/Read/Write/Replace) ============
local MAT_COLORS = {
  Grass={106,171,64}, LeafyGrass={90,160,70}, Sand={214,199,148}, Snow={240,244,245},
  Mud={102,72,46}, Ground={106,88,72}, Asphalt={60,62,67}, Salt={235,235,235},
  Ice={180,220,235}, Glacier={150,200,220}, Rock={110,110,112}, Sandstone={196,177,136},
  Limestone={206,206,190}, Pavement={150,148,140}, Brick={156,84,68}, Cobblestone={130,128,124},
  Concrete={150,150,150}, Basalt={70,70,75}, Slate={90,95,105}, CrackedLava={200,80,30},
  WoodPlanks={139,109,70}, Water={30,120,140}, Air={0,0,0},
}
local function voxStore(self)
  local p = rawget(self, "__props")
  if not p._vox then p._vox = {} end
  return p._vox
end
local function matName(m)
  if type(m) == "string" then return m end
  if type(m) == "table" and m.Name then return m.Name end
  return "Air"
end
local function voxSet(st, x, y, z, m, o, w)
  local k = x .. "," .. y .. "," .. z
  if (o or 0) <= 0 and (w or 0) <= 0 then st[k] = nil
  else st[k] = { m = m, o = math.max(0, math.min(1, o or 0)), w = math.max(0, math.min(1, w or 0)) } end
end
local function voxGet(st, x, y, z)
  local c = st[x .. "," .. y .. "," .. z]
  if c then return c.m, c.o, c.w end
  return "Air", 0, 0
end
local function voxRegion(region, res)
  assert(res == 4, "resolution deve ser 4")
  local mn, mx = region.Min, region.Max
  for _, v in ipairs({ mn.X, mn.Y, mn.Z, mx.X, mx.Y, mn.Z, mx.X, mx.Y, mx.Z }) do end
  for _, v in ipairs({ mn.X, mn.Y, mn.Z, mx.X, mx.Y, mx.Z }) do
    assert(v % 4 == 0, "region fora do grid voxel (use ExpandToGrid)")
  end
  local sx, sy, sz = (mx.X-mn.X)/4, (mx.Y-mn.Y)/4, (mx.Z-mn.Z)/4
  assert(sx*sy*sz <= 4194304, "region grande demais (4M voxels)")
  return mn, sx, sy, sz
end
local function voxFillBall(self, c, r, m)
  local st = voxStore(self)
  local mn = matName(m)
  local x0, x1 = math.floor((c.X-r)/4), math.floor((c.X+r)/4)
  local y0, y1 = math.floor((c.Y-r)/4), math.floor((c.Y+r)/4)
  local z0, z1 = math.floor((c.Z-r)/4), math.floor((c.Z+r)/4)
  for x = x0, x1 do for y = y0, y1 do for z = z0, z1 do
    local dx, dy, dz = x*4+2-c.X, y*4+2-c.Y, z*4+2-c.Z
    if dx*dx+dy*dy+dz*dz <= r*r then
      if mn == "Air" then voxSet(st, x, y, z, "Air", 0, 0)
      elseif mn == "Water" then voxSet(st, x, y, z, "Air", 0, 1)
      else voxSet(st, x, y, z, mn, 1, 0) end
    end
  end end end
end
function METHODS:FillBall(c, r, m) return voxFillBall(self, c, r, m) end
function METHODS:FillRegion(region, res, m)
  local st = voxStore(self)
  local mn = matName(m)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  for x = 1, sx do for y = 1, sy do for z = 1, sz do
    if mn == "Air" then voxSet(st, bx+x-1, by+y-1, bz+z-1, "Air", 0, 0)
    elseif mn == "Water" then voxSet(st, bx+x-1, by+y-1, bz+z-1, "Air", 0, 1)
    else voxSet(st, bx+x-1, by+y-1, bz+z-1, mn, 1, 0) end
  end end end
end
function METHODS:FillBlock(cf, size, m)
  local p = cf.Position or cf
  local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
  local r = Region3.new(
    Vector3.new(math.floor((p.X-hx)/4)*4, math.floor((p.Y-hy)/4)*4, math.floor((p.Z-hz)/4)*4),
    Vector3.new(math.ceil((p.X+hx)/4)*4, math.ceil((p.Y+hy)/4)*4, math.ceil((p.Z+hz)/4)*4))
  return self:FillRegion(r, 4, m)
end
function METHODS:FillCylinder(cf, h, r, m)
  local st = voxStore(self)
  local mn = matName(m)
  local p = cf.Position or cf
  local x0, x1 = math.floor((p.X-r)/4), math.floor((p.X+r)/4)
  local y0, y1 = math.floor((p.Y-h/2)/4), math.floor((p.Y+h/2)/4)
  local z0, z1 = math.floor((p.Z-r)/4), math.floor((p.Z+r)/4)
  for x = x0, x1 do for y = y0, y1 do for z = z0, z1 do
    local dx, dz = x*4+2-p.X, z*4+2-p.Z
    if dx*dx+dz*dz <= r*r then
      if mn == "Air" then voxSet(st, x, y, z, "Air", 0, 0)
      elseif mn == "Water" then voxSet(st, x, y, z, "Air", 0, 1)
      else voxSet(st, x, y, z, mn, 1, 0) end
    end
  end end end
end
function METHODS:ReadVoxels(region, res)
  local st = voxStore(self)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  local mats, occs = { Size = Vector3.new(sx, sy, sz) }, { Size = Vector3.new(sx, sy, sz) }
  for x = 1, sx do mats[x], occs[x] = {}, {} for y = 1, sy do mats[x][y], occs[x][y] = {}, {} for z = 1, sz do
    local m, o, w = voxGet(st, bx+x-1, by+y-1, bz+z-1)
    if w > 0 and o <= 0 then mats[x][y][z], occs[x][y][z] = Enum.Material.Water, w
    else mats[x][y][z], occs[x][y][z] = Enum.Material[m], o end
  end end end
  return mats, occs
end
function METHODS:WriteVoxels(region, res, mats, occs)
  local st = voxStore(self)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  for x = 1, sx do for y = 1, sy do for z = 1, sz do
    local mn = matName(mats[x][y][z])
    local o = occs[x][y][z] or 0
    if mn == "Water" then voxSet(st, bx+x-1, by+y-1, bz+z-1, "Air", 0, o)
    else voxSet(st, bx+x-1, by+y-1, bz+z-1, mn, o, 0) end
  end end end
end
function METHODS:ReadVoxelChannels(region, res, ids)
  local st = voxStore(self)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  local out = { Size = Vector3.new(sx, sy, sz) }
  local want = {}
  for _, id in ipairs(ids or {}) do want[id] = true end
  if want.SolidMaterial then out.SolidMaterial = {} end
  if want.SolidOccupancy then out.SolidOccupancy = {} end
  if want.LiquidOccupancy then out.LiquidOccupancy = {} end
  for x = 1, sx do
    if out.SolidMaterial then out.SolidMaterial[x] = {} end
    if out.SolidOccupancy then out.SolidOccupancy[x] = {} end
    if out.LiquidOccupancy then out.LiquidOccupancy[x] = {} end
    for y = 1, sy do
      if out.SolidMaterial then out.SolidMaterial[x][y] = {} end
      if out.SolidOccupancy then out.SolidOccupancy[x][y] = {} end
      if out.LiquidOccupancy then out.LiquidOccupancy[x][y] = {} end
      for z = 1, sz do
        local m, o, w = voxGet(st, bx+x-1, by+y-1, bz+z-1)
        if out.SolidMaterial then out.SolidMaterial[x][y][z] = Enum.Material[m] end
        if out.SolidOccupancy then out.SolidOccupancy[x][y][z] = o end
        if out.LiquidOccupancy then out.LiquidOccupancy[x][y][z] = w end
      end
    end
  end
  return out
end
function METHODS:WriteVoxelChannels(region, res, ch)
  local st = voxStore(self)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  for x = 1, sx do for y = 1, sy do for z = 1, sz do
    local m, o, w = voxGet(st, bx+x-1, by+y-1, bz+z-1)
    if ch.SolidMaterial and ch.SolidMaterial[x] and ch.SolidMaterial[x][y] then
      m = matName(ch.SolidMaterial[x][y][z]) end
    if ch.SolidOccupancy and ch.SolidOccupancy[x] and ch.SolidOccupancy[x][y] then
      o = ch.SolidOccupancy[x][y][z] or o end
    if ch.LiquidOccupancy and ch.LiquidOccupancy[x] and ch.LiquidOccupancy[x][y] then
      w = ch.LiquidOccupancy[x][y][z] or w end
    if m == "Water" then m, o = "Air", 0 end
    voxSet(st, bx+x-1, by+y-1, bz+z-1, m, o, w)
  end end end
end
function METHODS:ReplaceMaterial(region, res, src, tgt)
  local st = voxStore(self)
  local s, t = matName(src), matName(tgt)
  local lo, sx, sy, sz = voxRegion(region, res)
  local bx, by, bz = lo.X/4, lo.Y/4, lo.Z/4
  local n = 0
  for x = 1, sx do for y = 1, sy do for z = 1, sz do
    local m, o, w = voxGet(st, bx+x-1, by+y-1, bz+z-1)
    if m == s and o > 0 then voxSet(st, bx+x-1, by+y-1, bz+z-1, t, o, w) n = n + 1 end
  end end end
  return n
end
function METHODS:Clear()
  local p = rawget(self, "__props")
  if not p._vox then error("Clear: not a Terrain") end
  p._vox = {}
end
function METHODS:CopyRegion(ri)
  local st = voxStore(self)
  local mn, mx = ri.Min, ri.Max
  local cells = {}
  for x = mn.X, mx.X do for y = mn.Y, mx.Y do for z = mn.Z, mx.Z do
    local m, o, w = voxGet(st, x, y, z)
    if o > 0 or w > 0 then cells[x..","..y..","..z] = { m, o, w } end
  end end end
  return { __t = "TerrainRegion", min = { mn.X, mn.Y, mn.Z },
    max = { mx.X, mx.Y, mx.Z }, cells = cells }
end
function METHODS:PasteRegion(treg, corner, pasteEmpty)
  local st = voxStore(self)
  local ox, oy, oz = corner.X - treg.min[1], corner.Y - treg.min[2], corner.Z - treg.min[3]
  for x = treg.min[1], treg.max[1] do for y = treg.min[2], treg.max[2] do for z = treg.min[3], treg.max[3] do
    local c = treg.cells[x..","..y..","..z]
    if c then voxSet(st, x+ox, y+oy, z+oz, c[1], c[2], c[3])
    elseif pasteEmpty then voxSet(st, x+ox, y+oy, z+oz, "Air", 0, 0) end
  end end end
end
function METHODS:CountCells()
  local n = 0
  for _, c in pairs(voxStore(self)) do if c.m ~= "Air" and c.o > 0 then n = n + 1 end end
  return n
end
function METHODS:WorldToCell(p)
  return Vector3.new(math.floor(p.X/4), math.floor(p.Y/4), math.floor(p.Z/4))
end
function METHODS:CellCenterToWorld(x, y, z)
  return Vector3.new(x*4+2, y*4+2, z*4+2)
end
function METHODS:CellCornerToWorld(x, y, z)
  return Vector3.new(x*4, y*4, z*4)
end
function METHODS:GetMaterialColor(m)
  local mn = matName(m)
  assert(mn ~= "Air" and mn ~= "Water", "Air/Water sem cor custom")
  local p = rawget(self, "__props")
  if p._matColors and p._matColors[mn] then return p._matColors[mn] end
  local d = MAT_COLORS[mn] or { 128, 128, 128 }
  return Color3.fromRGB(d[1], d[2], d[3])
end
function METHODS:SetMaterialColor(m, c)
  local mn = matName(m)
  assert(mn ~= "Air" and mn ~= "Water", "Air/Water sem cor custom")
  local p = rawget(self, "__props")
  if not p._matColors then p._matColors = {} end
  p._matColors[mn] = c
end

function METHODS:IsDescendantOf(other)
  local p = self
  while p do if p == other then return true end p = rawget(p,"__props").Parent end
  return false
end
function METHODS:GetFullName()
  local parts={} local cur=self
  while cur do table.insert(parts,1, rawget(cur,"__props").Name); cur=rawget(cur,"__props").Parent end
  return table.concat(parts,".")
end
function METHODS:Clone()
  local c = mkInstance(rawget(self,"__props").ClassName)
  for k,v in pairs(rawget(self,"__props")) do
    if k~="Parent" then rawget(c,"__props")[k]=v rawget(c,"__explicit")[k]=true end
  end
  for k,v in pairs(rawget(self,"__attrs")) do rawget(c,"__attrs")[k]=v end
  for _,ch in ipairs(rawget(self,"__children")) do local cc=ch:Clone(); cc.Parent=c end
  return c
end
function METHODS:SetAttribute(k,v) rawget(self,"__attrs")[k]=v end
function METHODS:GetAttribute(k) return rawget(self,"__attrs")[k] end
function METHODS:GetAttributes() local out={} for k in pairs(rawget(self,"__attrs")) do out[#out+1]=k end return out end
function METHODS:GetPropertyChangedSignal()
  local ev = rawget(self,"__events").Changed
  if not ev then ev=Event.new("Changed"); rawget(self,"__events").Changed=ev end
  return ev
end
-- Model methods
function METHODS:GetPivot()
  if rawget(self,"__props").ClassName=="Model" then return CFrame.new(0,5,0) end
  return CFrame.new(0,0,0)
end
function METHODS:PivotTo(cf) rawget(self,"__props").CFrame=cf end
function METHODS:GetScale() return rawget(self,"__props").Scale or 1 end
function METHODS:ApplyMesh(other)
  local oc = other and rawget(other, "__props") and rawget(other, "__props").MeshContent
  assert(oc, "ApplyMesh: MeshPart sem MeshContent.")
  rawset(rawget(self, "__props"), "MeshContent", oc)
end
function METHODS:ScaleTo(s) rawget(self,"__props").Scale = s end
function METHODS:GetScale() return rawget(self,"__props").Scale or 1 end
function METHODS:GetBoundingBox()
  local parts = {}
  local function grab(o)
    if o.ClassName == "Terrain" then return end
    if o:IsA("BasePart") then parts[#parts + 1] = o
    else for _, c in ipairs(o:GetChildren()) do grab(c) end end
  end
  grab(self)
  if #parts == 0 then
    local cf = rawget(self, "__props").CFrame or CFrame.new(0, 0, 0)
    return cf, Vector3.new(0, 0, 0)
  end
  local mn, mx = nil, nil
  for _, p in ipairs(parts) do
    local cf = rawget(p, "__props").CFrame or CFrame.new(0, 0, 0)
    local sz = rawget(p, "__props").Size or Vector3.new(4, 1, 2)
    for _, sx in ipairs({ -0.5, 0.5 }) do for _, sy in ipairs({ -0.5, 0.5 }) do for _, sz2 in ipairs({ -0.5, 0.5 }) do
      local w = cf * Vector3.new(sz.X * sx, sz.Y * sy, sz.Z * sz2)
      if not mn then mn, mx = Vector3.new(w.X, w.Y, w.Z), Vector3.new(w.X, w.Y, w.Z)
      else
        mn = Vector3.new(math.min(mn.X, w.X), math.min(mn.Y, w.Y), math.min(mn.Z, w.Z))
        mx = Vector3.new(math.max(mx.X, w.X), math.max(mx.Y, w.Y), math.max(mx.Z, w.Z))
      end
    end end end
  end
  local c = (mn + mx) / 2
  return CFrame.new(c.X, c.Y, c.Z), (mx - mn)
end
-- RemoteFunction / RemoteEvent
function METHODS:InvokeServer(action,payload)
  local fn = rawget(self,"__props").OnServerInvoke
  if fn then return fn(rawget(self,"__invokePlayer"), action, payload) end
end
function METHODS:FireClient() end
Instance = {}
local KNOWN_BAD = { ClasseFalsa123 = true, ClassDoesNotExist = true }
function Instance.new(class, parent)
  if KNOWN_BAD[class] then error("The current thread cannot create '" .. class .. "' (fake class p/ teste)") end
  local o = mkInstance(class)
  if class == "BindableFunction" then
    o.Invoke = function(self, action, payload)
      local fn = rawget(self, "__props").OnInvoke
      if fn then return fn(action, payload) end
    end
  elseif class == "BindableEvent" then
    local ev = Event.new("BindableEvent")
    rawget(o, "__events").Event = ev
    o.Fire = function(self, ...) ev:Fire(...) end
    o.Wait = function(self) return nil end
  elseif class == "RemoteEvent" then
    local ev = Event.new("OnServerEvent")
    rawget(o, "__events").OnServerEvent = ev
    o.FireClient = function(self, ...) end
  end
  if parent then o.Parent = parent end
  return o
end
typeof = function(v)
  if v == nil then return "nil" end
  local t = type(v)
  if t ~= "table" then return t end
  local tag = rawget(v, "__t")
  if tag then return tag end
  if getmetatable(v) == MT then return "Instance" end
  return "table"
end

-- ============ R12: EditableMesh/Content/AssetService (memoria real) ============
EditableMesh = {}
local EMMT = { __index = EditableMesh }
function EditableMesh.new()
  return setmetatable({ __t = "EditableMesh", _v = {}, _f = {}, _nv = 0, _nf = 0 }, EMMT)
end
function EditableMesh:AddVertex(pos)
  assert(pos and pos.X and pos.Y and pos.Z, "AddVertex: Vector3 invalido.")
  assert(not self._fixed, "AddVertex: malha fixed-size.")
  self._nv = self._nv + 1
  self._v[self._nv] = { x = pos.X, y = pos.Y, z = pos.Z }
  return self._nv
end
function EditableMesh:AddTriangle(a, b, c)
  assert(self._v[a] and self._v[b] and self._v[c], "AddTriangle: vertice inexistente.")
  assert(not self._fixed, "AddTriangle: malha fixed-size.")
  self._nf = self._nf + 1
  self._f[self._nf] = { a, b, c }
  return self._nf
end
local function emKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = k end
  table.sort(out)
  return out
end
function EditableMesh:GetVertices() return emKeys(self._v) end
function EditableMesh:GetFaces() return emKeys(self._f) end
function EditableMesh:GetVertexPosition(vid)
  local v = self._v[vid]
  assert(v, "vertice inexistente: " .. tostring(vid))
  return Vector3.new(v.x, v.y, v.z)
end
function EditableMesh:SetVertexPosition(vid, pos)
  local v = self._v[vid]
  assert(v, "vertice inexistente: " .. tostring(vid))
  assert(pos and pos.X, "posicao invalida.")
  v.x, v.y, v.z = pos.X, pos.Y, pos.Z
end
function EditableMesh:GetFaceVertices(fid)
  local f = self._f[fid]
  assert(f, "face inexistente: " .. tostring(fid))
  return { f[1], f[2], f[3] }
end
function EditableMesh:RemoveTriangle(fid)
  assert(self._f[fid], "face inexistente: " .. tostring(fid))
  assert(not self._fixed, "RemoveTriangle: malha fixed-size.")
  self._f[fid] = nil
end
function EditableMesh:RemoveVertex(vid)
  assert(self._v[vid], "vertice inexistente: " .. tostring(vid))
  assert(not self._fixed, "RemoveVertex: malha fixed-size.")
  for _, f in pairs(self._f) do
    assert(not (f[1] == vid or f[2] == vid or f[3] == vid),
      "RemoveVertex: remova as faces dependentes antes (server faz isso).")
  end
  self._v[vid] = nil
end
function EditableMesh:Clone()
  local c = EditableMesh.new()
  for k, v in pairs(self._v) do c._v[k] = { x = v.x, y = v.y, z = v.z } end
  for k, f in pairs(self._f) do c._f[k] = { f[1], f[2], f[3] } end
  c._nv, c._nf = self._nv, self._nf
  return c
end
Content = {}
function Content.fromObject(o) return { __t = "Content", _obj = o } end
function Content.fromAssetId(id) return { __t = "Content", _id = id } end
local function assetMethods(s)
  local pr = rawget(s, "__props")
  rawset(pr, "CreateEditableMesh", function(self) return EditableMesh.new() end)
  rawset(pr, "CreateEditableMeshAsync", function(self, content, params)
    assert(content and content.__t == "Content", "Content invalido.")
    if content._obj and content._obj.__t == "EditableMesh" then
      local c = content._obj:Clone()
      if not (params and params.FixedSize == false) then c._fixed = false end
      return c
    end
    error("CreateEditableMeshAsync: asset externo indisponivel no mock (id=" .. tostring(content._id) .. ").")
  end)
  rawset(pr, "CreateMeshPartAsync", function(self, content)
    assert(content and content.__t == "Content", "Content invalido.")
    local mp = mkInstance("MeshPart")
    rawget(mp, "__props").ClassName = "MeshPart"
    rawset(rawget(mp, "__props"), "MeshContent", content)
    rawset(rawget(mp, "__props"), "Size", Vector3.new(2, 2, 2))
    return mp
  end)
end

-- ============ services ============
local services = {}
local gameObj = mkInstance("DataModel")
rawget(gameObj,"__props").Name = "Game"
function gameObj:GetService(name)
  if name == "Workspace" and workspace then return workspace end
  if services[name] then return services[name] end
  local s = mkInstance(name); rawget(s,"__props").ClassName=name; rawget(s,"__props").Name=name
  if name == "AssetService" then assetMethods(s) end
  services[name]=s; s.Parent = gameObj
  return s
end
game = gameObj
-- script (global Roblox) — dummy fora das raiz (fica "hidden")
script = mkInstance("Script")
rawget(script,"__props").Name = "ArkherEditorServer"
script.Parent = gameObj
-- workspace
workspace = mkInstance("Workspace")
rawget(workspace,"__props").ClassName="Workspace"; rawget(workspace,"__props").Name="Workspace"
workspace.Parent = gameObj
-- seed um baseplate
local bp = mkInstance("Part"); rawget(bp,"__props").Name="Baseplate"
rawget(bp,"__props").Size=Vector3.new(120,1,120); rawget(bp,"__props").CFrame=CFrame.new(0,-0.5,0)
rawset(rawget(bp,"__props"),"Anchored",true); rawset(rawget(bp,"__props"),"Color",Color3.fromRGB(94,142,190))
bp.Parent = workspace

-- Players
local players = game:GetService("Players")
local function playersGetPlayers()
  local out={}
  for _,ch in ipairs(rawget(players,"__children")) do
    if rawget(ch,"__props").ClassName=="Player" then out[#out+1]=ch end
  end
  return out
end
function players:GetPlayers() return playersGetPlayers() end
local lp = mkInstance("Player"); lp.Name="WhiteXz73_Developer"
local pg = mkInstance("PlayerGui"); pg.Name="PlayerGui"; pg.Parent=lp
rawget(players,"__props").LocalPlayer = lp
-- player autorizado (mesmo nome de AUTHORIZED_USERNAMES)
local testPlayer = mkInstance("Player"); testPlayer.Name="WhiteXz73_Developer"
testPlayer.Parent = players

-- RunService
local run = game:GetService("RunService")
run.Heartbeat = Event.new("Heartbeat")
run.Stepped = Event.new("Stepped")

-- HttpService
local http = game:GetService("HttpService")
local function jesc(s) return s:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t') end
function http:JSONEncode(v)
  local tv = type(v)
  if tv == "nil" then return "null" end
  if tv == "boolean" then return v and "true" or "false" end
  if tv == "number" then return string.format("%.10g", v) end
  if tv == "string" then return '"' .. jesc(v) .. '"' end
  if tv ~= "table" then return '"' .. jesc(tostring(v)) .. '"' end
  local isArr = true
  local n = 0
  for k in pairs(v) do n = n + 1 if type(k) ~= "number" then isArr = false break end end
  if n == 0 then return "{}" end
  local parts = {}
  if isArr then
    for i = 1, n do parts[i] = http:JSONEncode(v[i]) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  for _, k in ipairs(keys) do parts[#parts + 1] = '"' .. jesc(tostring(k)) .. '":' .. http:JSONEncode(v[k]) end
  return "{" .. table.concat(parts, ",") .. "}"
end
function http:JSONDecode(s)
  if type(s) ~= "string" or s == "" then return nil end
  local pos = 1
  local function err(m) error("JSONDecode: " .. m .. " @" .. pos, 0) end
  local function skipws()
    while true do
      local c = s:sub(pos, pos)
      if c == " " or c == "\n" or c == "\t" or c == "\r" then pos = pos + 1 else break end
    end
  end
  local parse_value, parse_string, parse_number, parse_array, parse_object
  parse_value = function()
    skipws()
    local c = s:sub(pos, pos)
    if c == "{" then return parse_object() end
    if c == "[" then return parse_array() end
    if c == '"' then return parse_string() end
    if c == "t" then if s:sub(pos, pos + 3) == "true" then pos = pos + 4 return true end err("literal") end
    if c == "f" then if s:sub(pos, pos + 4) == "false" then pos = pos + 5 return false end err("literal") end
    if c == "n" then if s:sub(pos, pos + 3) == "null" then pos = pos + 4 return nil end err("literal") end
    return parse_number()
  end
  parse_string = function()
    assert(s:sub(pos, pos) == '"', "esperava string @" .. pos)
    pos = pos + 1
    local out = {}
    while true do
      local c = s:sub(pos, pos)
      if c == "" then err("string aberta") end
      if c == '"' then pos = pos + 1 return table.concat(out) end
      if c == "\\" then
        local e = s:sub(pos + 1, pos + 1)
        local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
        if map[e] then out[#out + 1] = map[e]; pos = pos + 2
        elseif e == "u" then
          local n = tonumber(s:sub(pos + 2, pos + 5), 16)
          out[#out + 1] = n and string.char(n) or "?"
          pos = pos + 6
        else out[#out + 1] = e; pos = pos + 2 end
      else out[#out + 1] = c; pos = pos + 1 end
    end
  end
  parse_number = function()
    local num = s:match("-?%d+%.?%d*[eE]?[+-]?%d*", pos)
    if not num then err("número") end
    pos = pos + #num
    return tonumber(num)
  end
  parse_array = function()
    pos = pos + 1
    local arr = {}
    skipws()
    if s:sub(pos, pos) == "]" then pos = pos + 1 return arr end
    while true do
      arr[#arr + 1] = parse_value()
      skipws()
      local c = s:sub(pos, pos)
      if c == "," then pos = pos + 1 elseif c == "]" then pos = pos + 1 return arr else err("array") end
    end
  end
  parse_object = function()
    pos = pos + 1
    local obj = {}
    skipws()
    if s:sub(pos, pos) == "}" then pos = pos + 1 return obj end
    while true do
      skipws()
      local k = parse_string()
      skipws()
      assert(s:sub(pos, pos) == ":", "esperava ':'")
      pos = pos + 1
      obj[k] = parse_value()
      skipws()
      local c = s:sub(pos, pos)
      if c == "," then pos = pos + 1 elseif c == "}" then pos = pos + 1 return obj else err("objeto") end
    end
  end
  local ok, v = pcall(parse_value)
  if not ok then return nil end
  return v
end
function http:GenerateGUID(_d) local n=0 local function r() n=(n*16807)%2147483647 return (n+1) end
  local hex="0123456789abcdef" local out={} for i=1,32 do out[i]=hex:sub((r()%16)+1,(r()%16)+1) end return table.concat(out) end
function http:GetUuid() return self:GenerateGUID(false) end

print("[mock] ready")
