-- ARKHER V3 test shim: Roblox API em Lua puro (estende o shim V2)
local WAIT_BUDGET = 8000
local waits = 0
function wait(n)
	waits = waits + 1
	if waits > WAIT_BUDGET then return nil end
	return n or (1 / 60)
end
loadstring = loadstring or load
tick = tick or os.clock
warn = warn or print

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
	return { R = r or 0, G = g or 0, B = b or 0, __t = "Color3" }
end

local function v3mag(x, y, z) return math.sqrt(x * x + y * y + z * z) end

Vector3 = {}
function Vector3.new(x, y, z)
	local vx, vy, vz = x or 0, y or 0, z or 0
	local m = v3mag(vx, vy, vz)
	return {
		X = vx, Y = vy, Z = vz, __t = "Vector3",
		Magnitude = m,
		Unit = m > 0 and { X = vx / m, Y = vy / m, Z = vz / m, Magnitude = 1, __t = "Vector3" } or { X = 0, Y = 0, Z = 0, Magnitude = 0, __t = "Vector3" },
	}
end
local V3MT = {
	__index = Vector3,
	__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end,
	__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end,
	__mul = function(a, b)
		if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
		if type(a) == "number" then return Vector3.new(b.X * a, b.Y * a, b.Z * a) end
		return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
	end,
}
-- re-wrap plain tables created by Vector3.new
function Vector3.new(x, y, z)
	if type(x) == "table" and type(x.X) == "number" and type(x.Y) == "number" and type(x.Z) == "number" then
		return setmetatable(x, V3MT)
	end
	local t = (function()
		local vx, vy, vz = x or 0, y or 0, z or 0
		local m = v3mag(vx, vy, vz)
		return { X = vx, Y = vy, Z = vz, __t = "Vector3", Magnitude = m,
			Unit = m > 0 and { X = vx / m, Y = vy / m, Z = vz / m, Magnitude = 1, __t = "Vector3" } or { X = 0, Y = 0, Z = 0, Magnitude = 0, __t = "Vector3" } }
	end)()
	return setmetatable(t, V3MT)
end

CFrame = {}
local cfm = {}
cfm.__mul = function(a, b)
	-- composicao aproximada p/ testes: posicao soma; guarda os angulos p/ debug
	local posA = a.Position or { X = 0, Y = 0, Z = 0 }
	local posB = b.Position or { X = 0, Y = 0, Z = 0 }
	local angA = a.Ang or { X = 0, Y = 0, Z = 0 }
	local angB = b.Ang or { X = 0, Y = 0, Z = 0 }
	return setmetatable({
		Position = Vector3.new(posA.X + posB.X, posA.Y + posB.Y, posA.Z + posB.Z),
		Ang = { X = angA.X + angB.X, Y = angA.Y + angB.Y, Z = angA.Z + angB.Z },
		__t = "CFrame",
	}, cfm)
end
local function isVec3(x)
	return type(x) == "table" and type(x.X) == "number" and type(x.Y) == "number" and type(x.Z) == "number"
end
function CFrame.new(x, y, z)
	if isVec3(x) then
		return setmetatable({ Position = x, __t = "CFrame" }, cfm)
	end
	return setmetatable({ Position = Vector3.new(x or 0, y or 0, z or 0), __t = "CFrame" }, cfm)
end
function CFrame.Angles(rx, ry, rz)
	return setmetatable({ Position = Vector3.new(0, 0, 0), Ang = { X = rx or 0, Y = ry or 0, Z = rz or 0 }, __t = "CFrame" }, cfm)
end
function CFrame.fromEulerAnglesXYZ(rx, ry, rz) return CFrame.Angles(rx, ry, rz) end
function CFrame.fromAxisAngle(axis, angle) return CFrame.Angles(0, angle, 0) end
function CFrame.lookAt(eye, target)
	return setmetatable({ Position = eye, LookVector = Vector3.new(target.X - eye.X, target.Y - eye.Y, target.Z - eye.Z).Unit, __t = "CFrame" }, cfm)
end

BrickColor = {}
function BrickColor.new(name) return { Name = name, Number = 1, __t = "BrickColor" } end

UDim2 = {}
UDim = {}
Vector2 = {}
ColorSequence = {}
TweenInfo = {}
function UDim2.new(a, b, c, d)
	return { X = { Scale = a or 0, Offset = b or 0 }, Y = { Scale = c or 0, Offset = d or 0 }, __t = "UDim2" }
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x or 0, 0, y or 0) end
function UDim2.fromScale(x, y) return UDim2.new(x or 0, 0, y or 0, 0) end
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

Random = {}
function Random.new(seed)
	local s = (seed or 1) % 2147483647
	if s <= 0 then s = s + 2147483646 end
	local function next()
		s = (s * 16807) % 2147483647
		return (s - 1) / 2147483646
	end
	return {
		NextInteger = function(_, a, b)
			a = a or 0
			b = b or 1
			return a + math.floor(next() * (b - a + 1))
		end,
		NextNumber = next,
	}
end

-- ---------- JSON (real encoder + decoder) ----------
local function jesc(s)
	s = s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
	return s
end
local JSON = {}
function JSON.encode(v, seen)
	seen = seen or {}
	local tv = type(v)
	if tv == "nil" then return "null" end
	if tv == "boolean" then return v and "true" or "false" end
	if tv == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return "null" end
		return string.format("%.10g", v)
	end
	if tv == "string" then return '"' .. jesc(v) .. '"' end
	if tv == "table" then
		if seen[v] then return "null" end
		seen[v] = true
		-- array ou object?
		local isArr, n = true, 0
		for k in pairs(v) do
			n = n + 1
			if type(k) ~= "number" then isArr = false break end
		end
		if n == 0 then
			if isArr then return "[]" else return "{}" end
		end
		if isArr then
			local parts = {}
			for i = 1, n do parts[i] = JSON.encode(v[i], seen) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		local keys = {}
		for k in pairs(v) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ipairs(keys) do
			parts[#parts + 1] = '"' .. jesc(tostring(k)) .. '":' .. JSON.encode(v[k], seen)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local function jskip(s, i)
	while i <= #s do
		local c = s:sub(i, i)
		if c == " " or c == "\t" or c == "\n" or c == "\r" then i = i + 1 else break end
	end
	return i
end
local J
J = {
	_value = function(s, i)
		i = jskip(s, i)
		local c = s:sub(i, i)
		if c == "{" then
			local obj = {}
			i = jskip(s, i + 1)
			if s:sub(i, i) == "}" then return obj, i + 1 end
			while true do
			i = jskip(s, i)
			if s:sub(i, i) ~= '"' then error("json: esperava chave em " .. i) end
				local k, ni = J.string(s, i + 1)
				obj[k] = nil
				i = jskip(s, ni)
				assert(s:sub(i, i) == ":", "json: esperava :")
				local v
				v, i = J._value(s, i + 1)
				obj[k] = v
				i = jskip(s, i)
				local d = s:sub(i, i)
				if d == "," then i = jskip(s, i + 1)
				elseif d == "}" then return obj, i + 1
				else error("json: esperava , ou } em " .. i) end
			end
		elseif c == "[" then
			local arr = {}
			i = jskip(s, i + 1)
			if s:sub(i, i) == "]" then return arr, i + 1 end
			while true do
				local v
				v, i = J._value(s, i)
				arr[#arr + 1] = v
				i = jskip(s, i)
				local d = s:sub(i, i)
				if d == "," then i = jskip(s, i + 1)
				elseif d == "]" then return arr, i + 1
				else error("json: esperava , ou ] em " .. i) end
			end
				elseif c == '"' then
					return J.string(s, i + 1)
		elseif c == "t" then
			if s:sub(i, i + 3) == "true" then return true, i + 4 end
			error("json: token invalido em " .. i)
		elseif c == "f" then
			if s:sub(i, i + 4) == "false" then return false, i + 5 end
			error("json: token invalido em " .. i)
		elseif c == "n" then
			if s:sub(i, i + 3) == "null" then return nil, i + 4 end
			error("json: token invalido em " .. i)
		else
			local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", i)
			if num then return tonumber(num), i + #num end
			error("json: numero invalido em " .. i .. " (" .. s:sub(i, i + 12) .. ")")
		end
	end,
	string = function(s, i)
		local out = {}
		local j = i
		while true do
			local c = s:sub(j, j)
			if c == '"' then return table.concat(out), j + 1 end
			if c == "\\" then
				local e = s:sub(j + 1, j + 1)
				local map = { n = "\n", t = "\t", r = "\r", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
				out[#out + 1] = map[e] or e
				j = j + 2
			else
				out[#out + 1] = c
				j = j + 1
			end
		end
	end,
}
function JSON.decode(s)
	if type(s) ~= "string" or s == "" then return nil end
	local ok, v = pcall(function()
		local val, i = J._value(s, 1)
		return val
	end)
	if not ok then
		_G.__lastJsonErr = v
		return nil
	end
	return v
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
		if not ok and h == nil then end
	end
end
function Event:Wait()
	return nil
end

-- ---------- Instance ----------
local CLASS_SUPER = {
	Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiObject", TextBox = "GuiObject",
	ScrollingFrame = "GuiObject", SurfaceGui = "GuiObject", BillboardGui = "GuiObject",
	ScreenGui = "LayerCollector", LayerCollector = "Instance",
	UICorner = "Instance", UIStroke = "Instance", UIGradient = "Instance",
	UIGridLayout = "Instance", UIListLayout = "Instance", UIPadding = "Instance",
	Folder = "Instance", StringValue = "Instance", NumberValue = "Instance", BoolValue = "Instance",
	Part = "BasePart", MeshPart = "BasePart", Terrain = "BasePart", SpawnLocation = "BasePart",
	BasePart = "Volume", Volume = "Model", Model = "Instance",
	Script = "Instance", LocalScript = "Instance", ModuleScript = "Instance",
	Camera = "Instance", Light = "Instance", PointLight = "Light", SpotLight = "Light", DirectionalLight = "Light",
	Sky = "Instance", Atmosphere = "Instance", ParticleEmitter = "Instance", Sound = "Instance",
	Humanoid = "Instance", WeldConstraint = "Instance", Motor6D = "Instance", Path = "Instance",
	Decal = "Instance", ForceField = "Instance",
}
local AUTO_EVENTS = {
	"MouseButton1Click", "MouseButton2Click", "MouseEnter", "MouseLeave",
	"InputBegan", "InputEnded", "InputChanged", "SelectionChanged", "Changed",
	"Heartbeat", "Stepped", "FocusLost", "AncestryChanged", "TouchTap", "Activated",
}
local InstanceMT = {}
InstanceMT.__index = function(self, k)
	local raw = rawget(self, "__props")[k]
	if raw ~= nil then return raw end
	local ev = rawget(self, "__events")[k]
	if ev == nil then
		for _, name in ipairs(AUTO_EVENTS) do
			if k == name then
				ev = Event.new(k)
				rawget(self, "__events")[k] = ev
				break
			end
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
	local function isVec3(v)
		return type(v) == "table" and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
	end
	if k == "Position" then
		local p = rawget(self, "__props").Position
		if p then return p end
		local cf = rawget(self, "__props").CFrame
		if type(cf) == "table" and cf.Position then return cf.Position end
		return nil
	end
	if k == "CFrame" then
		local cf = rawget(self, "__props").CFrame
		if cf then return cf end
		local p = rawget(self, "__props").Position
		if p then return CFrame.new(p.X, p.Y, p.Z) end
		return nil
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
	end
	local function isVec3n(v)
		return type(v) == "table" and type(v.X) == "number" and type(v.Y) == "number" and type(v.Z) == "number"
	end
	if k == "Position" and isVec3n(v) then
		rawget(self, "__props").Position = v
		rawget(self, "__props").CFrame = CFrame.new(v.X, v.Y, v.Z)
	elseif k == "CFrame" and type(v) == "table" and v.Position then
		rawget(self, "__props").CFrame = v
		rawget(self, "__props").Position = v.Position
	elseif k == "Size" and isVec3n(v) then
		rawget(self, "__props").Size = v
	else
		rawget(self, "__props")[k] = v
	end
	local ch = rawget(self, "__events").Changed
	if ch then ch:Fire(k) end
end

local function mkInstance(class)
	local self = setmetatable({
		__props = { Name = class, ClassName = class, BorderSizePixel = 0, Visible = true, Text = "" },
		__children = {},
		__events = {},
		__attrs = {},
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
	table.sort(out, function(a, b) return (rawget(a, "__props").Name or "") < (rawget(b, "__props").Name or "") end)
	return out
end
local function findFirst(self, name)
	for _, ch in ipairs(rawget(self, "__children")) do
		if rawget(ch, "__props").Name == name then return ch end
	end
	return nil
end
local function findFirstClass(self, cls)
	for _, ch in ipairs(rawget(self, "__children")) do
		if isA(ch, cls) then return ch end
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
	if cur then table.insert(parts, 1, rawget(cur, "__props").Name) end
	return table.concat(parts, ".")
end

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
function METHODS:FindFirstChildOfClass(c) return findFirstClass(self, c) end
function METHODS:IsA(c) return isA(self, c) end
function METHODS:GetFullName() return fullName(self) end
function METHODS:Clone()
	local c = mkInstance(rawget(self, "__props").ClassName)
	for k, v in pairs(rawget(self, "__props")) do
		rawget(c, "__props")[k] = v
	end
	for k, v in pairs(rawget(self, "__attrs")) do
		rawget(c, "__attrs")[k] = v
	end
	for _, ch in ipairs(rawget(self, "__children")) do
		local cc = ch:Clone()
		cc.Parent = c
	end
	return c
end
function METHODS:SetAttribute(k, v) rawget(self, "__attrs")[k] = v end
function METHODS:GetAttribute(k) return rawget(self, "__attrs")[k] end
function METHODS:GetAttributes()
	local out = {}
	for k in pairs(rawget(self, "__attrs")) do out[#out + 1] = k end
	return out
end
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
rawget(gameObj, "__props").Name = "Game"
function gameObj:GetService(name) return service(name) end
function gameObj:WaitForChild(name, t) return service(name) end
game = gameObj

-- services de top-level (como no Roblox real)
local TOP_SERVICES = {
	"Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage",
	"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
	"TextChatService", "SoundService", "RunService", "CoreGui", "DataStoreService",
}
for _, n in ipairs(TOP_SERVICES) do
	local s = service(n)
	s.Name = n
	game:GetChildren() -- no-op
	table.insert(rawget(gameObj, "__children"), s)
end
-- Remove duplicatas se ja estavam la
-- workspace
workspace = mkInstance("Workspace")
rawget(workspace, "__props").ClassName = "Workspace"
rawget(workspace, "__props").Name = "Workspace"
workspace.Parent = gameObj
local _cam = mkInstance("Camera")
rawget(_cam, "__props").ClassName = "Camera"
rawget(_cam, "__props").Name = "CurrentCamera"
_cam.Parent = workspace
rawset(workspace, "CurrentCamera", _cam)

local function seed(name, class, props)
	local o = mkInstance(class)
	rawget(o, "__props").Name = name
	for k, v in pairs(props or {}) do rawget(o, "__props")[k] = v end
	o.Parent = workspace
	return o
end
local baseplate = seed("Baseplate", "Part", { Size = Vector3.new(120, 1, 120), Position = Vector3.new(0, -0.5, 0), Anchored = true })
seed("SpawnLocation", "Part", { Size = Vector3.new(6, 1, 6), Position = Vector3.new(0, 0.5, 0), Anchored = true })
seed("Terrain", "Terrain")
local cam = seed("Camera", "Camera", { CFrame = CFrame.new(0, 8, 16) })

-- Players
local players = service("Players")
local lp = mkInstance("Player")
lp.Name = "TestUser"
local pg = mkInstance("PlayerGui")
pg.Name = "PlayerGui"
pg.Parent = lp
rawget(players, "__props").LocalPlayer = lp
rawget(lp, "__props").Name = "TestUser"
local char = mkInstance("Model")
char.Name = "TestUser"
char.Parent = workspace
local hrp = mkInstance("Part")
hrp.Name = "HumanoidRootPart"
hrp.Parent = char
rawset(rawget(hrp, "__props"), "Anchored", true)

-- StarterGui (top service ja existe; ensure children)
local starterGui = service("StarterGui")

-- RunService: Heartbeat fireavel
local runService = service("RunService")
runService.Heartbeat = Event.new("Heartbeat")
runService.Stepped = Event.new("Stepped")
function runService:IsRunning() return false end
-- helper p/ testes: dispara N heartbeats
runService._fireHB = function(n, dt)
	for i = 1, (n or 1) do
		runService.Heartbeat:Fire(dt or (1 / 60))
	end
end

-- TweenService
local tweenService = service("TweenService")
function tweenService:Create(obj, info, props)
	-- aplica props imediatamente (shim)
	pcall(function()
		for k, v in pairs(props or {}) do
			rawget(obj, "__props")[k] = v
		end
	end)
	return { Play = function() end, Cancel = function() end }
end

-- UserInputService
local uis = service("UserInputService")
UserInputService = uis

-- require (ModuleScript com Source) — mesmo comportamento do Roblox:
-- executa o Source uma vez (cache por instancia) e globals vazam p/ fora
require = function(mod)
	if type(mod) ~= "table" then error("require: esperado um ModuleScript") end
	local props = rawget(mod, "__props")
	if not props then error("require: nao e um Instance") end
	if rawget(mod, "__modran") then return rawget(mod, "__modresult") end
	local src = props.Source
	if type(src) ~= "string" or src == "" then
		error("require: ModuleScript sem Source (" .. tostring(props.Name) .. ")")
	end
	local fn, err = loadstring(src, "[ModuleScript " .. tostring(props.Name or "?") .. "]")
	if not fn then error(err) end
	local ok, res = pcall(fn)
	if not ok then error(res, 0) end
	rawset(mod, "__modran", true)
	rawset(mod, "__modresult", res)
	return res
end
uis.InputBegan = Event.new("InputBegan")
uis.InputChanged = Event.new("InputChanged")
uis.InputEnded = Event.new("InputEnded")
function uis:IsKeyDown() return false end

-- Selection (Set dispara SelectionChanged)
local selection = service("Selection")
local selStore = {}
function selection:Get() return selStore end
function selection:Set(t)
	selStore = t or {}
	selection.SelectionChanged:Fire(selStore)
end
selection.SelectionChanged = Event.new("SelectionChanged")

-- HttpService com JSON real
local http = service("HttpService")
function http:JSONEncode(t) return JSON.encode(t) end
function http:JSONDecode(s) return JSON.decode(s) end
function http:PostAsync(url, body, ct, timeout)
	http._lastPost = { url = url, body = body, ct = ct }
	return "200"
end

-- game file API (Studio)
local files = {}
function gameObj:WriteFile(path, data)
	files[path] = data
	gameObj._files = files
	return true
end
function gameObj:ReadFile(path)
	return files[path]
end
function gameObj:IsFile(path)
	return files[path] ~= nil
end

print("[shim v3] ready")
