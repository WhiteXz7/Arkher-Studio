-- ARKHER V2 test shim: minimal Roblox API em Lua puro (5.1+)
local WAIT_BUDGET = 4000
local waits = 0
function wait(n)
	waits = waits + 1
	if waits > WAIT_BUDGET then return nil end
	return n or (1 / 60)
end
loadstring = loadstring or load

-- ---------- Enum (loose) ----------
local function autoenum(name)
	local t = { __name = name }
	setmetatable(t, {
		__index = function(self, k)
			local child = rawget(self, k)
			if child == nil then
				child = autoenum(name .. "." .. tostring(k))
				rawset(self, k, child)
			end
			return child
		end,
	})
	return t
end
Enum = autoenum("Enum")

-- ---------- math types ----------
Color3 = {}
function Color3.fromRGB(r, g, b)
	return { R = r / 255, G = g / 255, B = b / 255, __t = "Color3" }
end
function Color3.new(r, g, b)
	return { R = r, G = g, B = b, __t = "Color3" }
end
UDim2 = {}
UDim = {}
Vector2 = {}
ColorSequence = {}
TweenInfo = {}
function UDim2.new(a, b, c, d)
	return { X = { Scale = a or 0, Offset = b or 0 }, Y = { Scale = c or 0, Offset = d or 0 }, __t = "UDim2" }
end
function UDim.new(a, b)
	return { Scale = a or 0, Offset = b or 0, __t = "UDim" }
end
function Vector2.new(x, y)
	return { X = x or 0, Y = y or 0, __t = "Vector2" }
end
function ColorSequence.new(a, b)
	return { Keypoints = { a, b }, __t = "ColorSequence" }
end
function TweenInfo.new(a)
	return { Time = a, __t = "TweenInfo" }
end

-- ---------- Event ----------
local Event = {}
Event.__index = Event
function Event.new(name)
	return setmetatable({ handlers = {}, __t = "Event", Name = name }, Event)
end
function Event:Connect(fn)
	table.insert(self.handlers, fn)
	return { Disconnect = function() end, __t = "RBXScriptConnection" }
end
function Event:Fire(...)
	for _, h in ipairs(self.handlers) do
		local ok = pcall(h, ...)
	end
end
function Event:Wait()
	return nil
end

-- ---------- Instance ----------
local CLASS_SUPER = {
	Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiObject", TextBox = "GuiObject",
	ScreenGui = "LayerCollector", GuiObject = "Instance", LayerCollector = "Instance",
	UICorner = "Instance", UIStroke = "Instance", UIGradient = "Instance",
	Folder = "Instance", StringValue = "Instance", Part = "BasePart", BasePart = "Instance",
}
local InstanceMT = {}
InstanceMT.__index = function(self, k)
	local raw = rawget(self, "__props")[k]
	if raw ~= nil then return raw end
	local ev = rawget(self, "__events")[k]
	if ev == nil then
		if k == "MouseButton1Click" or k == "MouseEnter" or k == "MouseLeave" or k == "InputBegan"
			or k == "InputEnded" or k == "InputChanged" or k == "SelectionChanged" or k == "Changed"
			or k == "Heartbeat" or k == "Stepped" then
			ev = Event.new(k)
			rawget(self, "__events")[k] = ev
		end
	end
	if ev then return ev end
	if METHODS and METHODS[k] then return METHODS[k] end
	if k == "AbsoluteSize" then
		local s = rawget(self, "__props").Size
		return { X = s and s.X.Offset or 0, Y = s and s.Y.Offset or 0 }
	end
	if k == "AbsolutePosition" then
		local p = rawget(self, "__props").Position
		return { X = p and p.X.Offset or 0, Y = p and p.Y.Offset or 0 }
	end
	return nil
end
InstanceMT.__newindex = function(self, k, v)
	if k == "Parent" then
		local old = rawget(self, "__props").Parent
		if old then
			local kids = rawget(old, "__children")
			for i = #kids, 1, -1 do
				if kids[i] == self then table.remove(kids, i) end
			end
		end
		rawget(self, "__props").Parent = v
		if v then table.insert(rawget(v, "__children"), self) end
	else
		rawget(self, "__props")[k] = v
	end
end

local function mkInstance(class)
	local self = setmetatable({
		__props = { Name = class, ClassName = class, BorderSizePixel = 0, Visible = true, Text = "" },
		__children = {},
		__events = {},
	}, InstanceMT)
	return self
end

local function isA(self, class)
	local c = rawget(self, "__props").ClassName
	while c do
		if c == class then return true end
		c = CLASS_SUPER[c]
	end
	return false
end
local function getChildren(self)
	local out = {}
	for _, ch in ipairs(rawget(self, "__children")) do out[#out + 1] = ch end
	return out
end
local function findFirst(self, name)
	for _, ch in ipairs(rawget(self, "__children")) do
		if rawget(ch, "__props").Name == name then return ch end
	end
	return nil
end
local function descendants(self, out)
	for _, ch in ipairs(rawget(self, "__children")) do
		out[#out + 1] = ch
		descendants(ch, out)
	end
	return out
end
local function fullName(self)
	local parts = {}
	local cur = self
	while cur and rawget(cur, "__props").Parent do
		table.insert(parts, 1, rawget(cur, "__props").Name)
		cur = rawget(cur, "__props").Parent
	end
	table.insert(parts, 1, rawget(cur, "__props").Name)
	return table.concat(parts, ".")
end

-- methods injected via wrapper table
METHODS = {}
function METHODS:Destroy()
	local p = rawget(self, "__props").Parent
	if p then
		local kids = rawget(p, "__children")
		for i = #kids, 1, -1 do
			if kids[i] == self then table.remove(kids, i) end
		end
	end
	rawget(self, "__props").Parent = nil
	rawset(self, "__children", {})
end
function METHODS:ClearAllChildren()
	rawset(self, "__children", {})
end
function METHODS:GetChildren() return getChildren(self) end
function METHODS:GetDescendants() return descendants(self, {}) end
function METHODS:FindFirstChild(n) return findFirst(self, n) end
function METHODS:WaitForChild(n) return findFirst(self, n) end
function METHODS:IsA(c) return isA(self, c) end
function METHODS:GetFullName() return fullName(self) end
function METHODS:GetPropertyChangedSignal()
	local ev = rawget(self, "__events").Changed
	if not ev then ev = Event.new("Changed") rawget(self, "__events").Changed = ev end
	return ev
end
Instance = {}
function Instance.new(class)
	return mkInstance(class)
end

-- ---------- services ----------
local services = {}
local function service(name)
	if services[name] then return services[name] end
	local s = mkInstance(name)
	rawget(s, "__props").ClassName = name
	services[name] = s
	return s
end
local gameObj = mkInstance("DataModel")
function gameObj:GetService(name) return service(name) end
game = gameObj

-- StarterGui
local starterGui = service("StarterGui")
-- Players
local players = service("Players")
local lp = mkInstance("Player")
local pg = mkInstance("PlayerGui")
pg.Parent = lp
rawget(players, "__props").LocalPlayer = lp
-- RunService
local runService = service("RunService")
rawget(runService, "__events").Heartbeat = Event.new("Heartbeat")
function runService:IsRunning() return false end
-- TweenService
local tweenService = service("TweenService")
function tweenService:Create(obj, info, props)
	return { Play = function() end, Cancel = function() end }
end
-- UserInputService
local uis = service("UserInputService")
rawget(uis, "__events").InputBegan = Event.new("InputBegan")
rawget(uis, "__events").InputChanged = Event.new("InputChanged")
function uis:IsKeyDown() return false end
-- Selection
local selection = service("Selection")
local selStore = {}
function selection:Get() return selStore end
function selection:Set(t) selStore = t end
rawget(selection, "__events").SelectionChanged = Event.new("SelectionChanged")
-- HttpService
local http = service("HttpService")
function http:JSONEncode(t) return "[]" end
function http:JSONDecode(s) return {} end
-- ServerStorage / ReplicatedStorage
local ss = service("ServerStorage")
local rs = service("ReplicatedStorage")
-- Stats
local stats = service("Stats")

-- workspace with seed objects
workspace = mkInstance("Workspace")
rawget(workspace, "__props").ClassName = "Workspace"
local function seed(name, class)
	local o = mkInstance(class)
	rawget(o, "__props").Name = name
	o.Parent = workspace
	return o
end
seed("Baseplate", "Part")
seed("SpamPoint", "Part")
seed("Terrain", "Terrain")
seed("Camera", "Camera")
local lighting = seed("Lighting", "Folder")
local sgFolder = seed("StarterGui", "Folder")

print("[shim] ready")
