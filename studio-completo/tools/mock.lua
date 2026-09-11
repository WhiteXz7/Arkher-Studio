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

-- ============ Enum ============
local function autoenum(name)
  local last = name:match("([^.]+)$") or name
  local items = {}
  local t = { __name = name, Name = last }
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
Vector3 = {}
local V3MT = { __index=Vector3,
  __mul=function(a,b)
    if type(b)=="number" then return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
    if type(a)=="number" then return Vector3.new(b.X*a,b.Y*a,b.Z*a) end
    return Vector3.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z)
  end,
  __add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end }
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__t="Vector3"},V3MT) end
CFrame = {}
local CFMT = { __index=CFrame, __mul=function(a,b) return CFrame.new(0,0,0) end }
function CFrame.new(x,y,z)
  if type(x)=="table" and x.X then return setmetatable({Position=x,__t="CFrame"},CFMT) end
  return setmetatable({Position=Vector3.new(x or 0,y or 0,z or 0),__t="CFrame"},CFMT)
end
function CFrame.fromEulerAnglesYXZ(x,y,z) return CFrame.new(0,0,0) end
function CFrame.lookAt(a,b) return CFrame.new(0,0,0) end
function CFrame:ToEulerAnglesYXZ() return 0,0,0 end
function CFrame:ToOrientation() return 0,0,0 end
function CFrame:GetComponents() return 0,0,0,0,0,0,0,0,0,0,0,0 end
UDim2 = {} function UDim2.new(a,b,c,d) return {X={Scale=a or 0,Offset=b or 0},Y={Scale=c or 0,Offset=d or 0},__t="UDim2"} end
UDim2.fromOffset = function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale = function(a,b) return UDim2.new(a,0,b,0) end
UDim = {} function UDim.new(a,b) return {Scale=a or 0,Offset=b or 0,__t="UDim"} end
Vector2 = {} function Vector2.new(x,y) return {X=x or 0,Y=y or 0,__t="Vector2"} end

-- ============ Event ============
local Event = {} Event.__index = Event
function Event.new(name) return setmetatable({handlers={},Name=name},Event) end
function Event:Connect(fn) table.insert(self.handlers,fn) return {Disconnect=function() end} end
function Event:Fire(...) for _,h in ipairs(self.handlers) do pcall(h,...) end end
function Event:Wait() return nil end

-- ============ Instance ============
local CLASS_SUPER = {
  Frame="GuiObject", TextLabel="GuiObject", TextButton="GuiObject", TextBox="GuiObject",
  ScrollingFrame="GuiObject", ScreenGui="LayerCollector", LayerCollector="Instance",
  UICorner="Instance", UIStroke="Instance", UIGradient="Instance", UIPadding="Instance",
  UIListLayout="Instance", UIGridLayout="Instance", UIAspectRatioConstraint="Instance", UISizeConstraint="Instance",
  Folder="Instance", Model="Instance",
  Part="BasePart", WedgePart="BasePart", CornerWedgePart="BasePart", TrussPart="BasePart",
  SpawnLocation="BasePart", MeshPart="BasePart", BasePart="Volume", Volume="Instance",
  Terrain="BasePart",
  Script="BaseScript", LocalScript="BaseScript", ModuleScript="BaseScript", BaseScript="Instance",
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
  "Activated","MouseEnter","MouseLeave","MouseButton1Click","MouseButton2Click","TouchTap","FocusLost" }
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
      for _,h in ipairs(rawget(self,"__events").AncestryChanged and rawget(self,"__events").AncestryChanged.handlers or {}) do pcall(h,self,old,nil) end
    end
    rawget(self,"__props").Parent = v
    if v then
      table.insert(rawget(v,"__children"), self)
      for _,h in ipairs(rawget(self,"__events").AncestryChanged and rawget(self,"__events").AncestryChanged.handlers or {}) do pcall(h,self,v,nil) end
      -- DescendantAdded no pai (recursivo)
      fireDescendantAdded(v, self)
    end
    return
  end
  if k=="CFrame" and type(v)=="table" and v.Position then
    rawget(self,"__props").CFrame = v
    rawget(self,"__props").Position = v.Position
    local p = rawget(self,"__props").Parent
    if p then
      for _,h in ipairs(rawget(p,"__events").DescendantAdded and rawget(p,"__events").DescendantAdded.handlers or {}) do end
    end
  else
    rawget(self,"__props")[k] = v
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
    BorderSizePixel=1, ZIndex=1 },
  TextLabel = { TextColor3=Color3.new(0,0,0), TextSize=14 },
  BaseScript = { Enabled=false, Source="" },
  Sound = { Volume=0, Looped=false, PlaybackSpeed=1, SoundId="rbxassetid://0" },
  ValueBase = { Value=nil },
}
local function mkInstance(class)
  local o = setmetatable({
    __props={ Name=class, ClassName=class, Visible=true, Text="", Position=Vector3.new(0,0,0),
      CFrame=CFrame.new(0,0,0), Size=Vector3.new(0,0,0) },
    __children={}, __events={}, __attrs={},
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
function METHODS:GetChildren()
  local out={}
  for _,ch in ipairs(rawget(self,"__children")) do out[#out+1]=ch end
  table.sort(out,function(a,b) return (rawget(a,"__props").Name or "")<(rawget(b,"__props").Name or "") end)
  return out
end
function METHODS:GetDescendants()
  local out={}
  local function rec(o) for _,ch in ipairs(rawget(o,"__children")) do out[#out+1]=ch; rec(ch) end end
  rec(self)
  return out
end
function METHODS:FindFirstChild(n) for _,ch in ipairs(rawget(self,"__children")) do if rawget(ch,"__props").Name==n then return ch end end return nil end
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
  for k,v in pairs(rawget(self,"__props")) do if k~="Parent" then rawget(c,"__props")[k]=v end end
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
function METHODS:ScaleTo(s) rawget(self,"__props").Scale = s end
-- RemoteFunction / RemoteEvent
function METHODS:InvokeServer(action,payload)
  local fn = rawget(self,"__props").OnServerInvoke
  if fn then return fn(rawget(self,"__invokePlayer"), action, payload) end
end
function METHODS:FireClient() end
Instance = {}
function Instance.new(class, parent)
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

-- ============ services ============
local services = {}
local gameObj = mkInstance("DataModel")
rawget(gameObj,"__props").Name = "Game"
function gameObj:GetService(name)
  if name == "Workspace" and workspace then return workspace end
  if services[name] then return services[name] end
  local s = mkInstance(name); rawget(s,"__props").ClassName=name; rawget(s,"__props").Name=name
  services[name]=s; table.insert(rawget(gameObj,"__children"), s)
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
