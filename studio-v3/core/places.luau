--[[ ARKHER V3 — PLACES: criar/salvar/abrir/exportar places como no Roblox Studio ]]
-- ArkherPlaces: o sistema de places do ARKHER.
-- - New(template): cria um place novo (limpa workspace e aplica template real)
-- - Save(): snapshot REAL (hierarquia + propriedades + scripts) no ArkherCloud (ServerStorage)
-- - Open(id): restaura um snapshot
-- - Export(): gera um bundle Lua portavel (grava em disco via game.WriteFile se o Studio permitir)
-- - List(): lista places salvos
-- Nao depende de filesystem obrigatorio nem de Open Cloud API.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local P = {}
ArkherPlaces = P

local CLOUD_NAME = "ArkherCloud"

function P.cloudRoot()
	local root = ServerStorage:FindFirstChild(CLOUD_NAME)
	if not root then
		root = Instance.new("Folder")
		root.Name = CLOUD_NAME
		root.Parent = ServerStorage
	end
	return root
end

function P.placesFolder()
	local f = P.cloudRoot():FindFirstChild("Places")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Places"
		f.Parent = P.cloudRoot()
	end
	return f
end

-- ---------- SERIALIZACAO REAL ----------
local SCRIPT_CLASSES = { ["Script"] = true, ["LocalScript"] = true, ["ModuleScript"] = true }
local IGNORE = {
	["Humanoid"] = true, ["HumanoidRootPart"] = true,
	["Motor6D"] = true, ["WeldConstraint"] = true, ["ManualWarehouse"] = true,
	["SelectionBox"] = true, ["PathFindingMap"] = true,
}

local PROP_SKIP = {
	Parent = true, Name = true, ClassName = true,
	Archivable = true, Redacted = true,
}

local function serializeInstance(inst, depth, out)
	if depth > 24 then return nil end
	local entry = { cls = inst.ClassName, name = inst.Name, props = {}, kids = {} }
	-- pega propriedades via pcall-safe loop
	local ok = pcall(function()
		-- usa os getters padrao que todo Instance expoe
		local props = {
			"Position", "CFrame", "Size", "Color", "Material", "Transparency",
			"CanCollide", "Anchored", "CastShadow", "BrickColor", "TopSurface",
			"Text", "TextColor3", "TextSize", "BackgroundTransparency", "BackgroundColor3",
			"RotSpeed", "LinearVelocity", "Source", "Face", "AudioVolume", "Loops",
			"Rate", "LightColor", "Brightness", "Range", "Fov", "FocusDistance",
			"Visible", "Size2D", "Enabled", "Speed", "Rate2",
		}
		for _, pn in ipairs(props) do
			if not PROP_SKIP[pn] then
				local okv, v = pcall(function() return inst[pn] end)
				if okv and v ~= nil then
				local tv = type(v)
				if tv == "number" or tv == "string" or tv == "boolean" then
					entry.props[pn] = v
				elseif tv == "table" and v.__t == "Vector3" then
					entry.props[pn] = { v.X, v.Y, v.Z }
				elseif tv == "table" and v.__t == "Color3" then
					entry.props[pn] = { math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255) }
				elseif tv == "table" and v.__t == "BrickColor" then
					entry.props[pn] = v.Name
					elseif tv == "table" and v.NumberValue ~= nil and v.EnumItem then
						entry.props[pn] = tostring(v)
					end
				end
			end
		end
		if SCRIPT_CLASSES[inst.ClassName] then
			entry.props.__src = inst.Source or ""
		end
	end)
	for _, ch in ipairs(inst:GetChildren()) do
		if not IGNORE[ch.ClassName] then
			local sub = serializeInstance(ch, depth + 1, out)
			if sub then table.insert(entry.kids, sub) end
		end
	end
	return entry
end

local function parseVector(v)
	if type(v) == "table" and #v == 3 then return Vector3.new(v[1], v[2], v[3]) end
	return nil
end
local function parseColor(v)
	if type(v) == "table" and #v == 3 then return Color3.fromRGB(v[1], v[2], v[3]) end
	return nil
end

local function restoreInstance(entry, parent)
	if not entry then return nil end
	local inst
	local ok = pcall(function() inst = Instance.new(entry.cls) end)
	if not ok or not inst then
		ARKHER.out("WARNING", "Place restore: classe indisponivel " .. tostring(entry.cls))
		return nil
	end
	inst.Name = entry.name or inst.Name
	for pn, v in pairs(entry.props or {}) do
		if pn == "__src" then
			pcall(function() inst.Source = v end)
		elseif pn == "CFrame" then
			local vec = parseVector(v)
			if vec then pcall(function() inst.CFrame = CFrame.new(vec) end) end
		elseif pn == "Position" then
			local vec = parseVector(v)
			if vec then pcall(function() inst.Position = vec end) end
		elseif pn == "Color" then
			local col = parseColor(v)
			if col then pcall(function() inst.Color = col end) end
		elseif pn == "BackgroundColor3" or pn == "TextColor3" or pn == "LightColor" or pn == "Color3" then
			local col = parseColor(v)
			if col then pcall(function() inst[pn] = col end) end
		elseif type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
			pcall(function() inst[pn] = v end)
		end
	end
	for _, kid in ipairs(entry.kids or {}) do
		restoreInstance(kid, inst)
	end
	pcall(function() inst.Parent = parent end)
	return inst
end

-- ---------- SNAPSHOT DO PLACE ----------
function P.snapshot()
	local ws = workspace
	local data = {
		meta = {
			v = 3, t = tick(), name = ARKHER.STATE.placeName,
			id = ARKHER.STATE.placeId, do15 = ARKHER.STATE.do15Level,
			engine = "ARKHER V3 / UES",
		},
		services = {},
	}
	-- workspace completo
	local wsEntry = serializeInstance(ws, 0, data.services)
	data.workspace = wsEntry
	-- Lighting (sky, atmosphere, lights)
	local lighting = game:FindFirstChild("Lighting")
	if lighting then
		data.lighting = serializeInstance(lighting, 0, data.services)
	end
	-- PlayerGui / StarterGui conteudo
	for _, svc in ipairs({ "StarterGui", "StarterPack", "StarterCharacterScripts" }) do
		local s = game:FindFirstChild(svc)
		if s then data[svc] = serializeInstance(s, 0, data.services) end
	end
	return data
end

function P.apply(data)
	if not data or not data.workspace then
		ARKHER.out("ERROR", "Place: snapshot invalido")
		return false
	end
	ARKHER.cmd("undo.push", "Abrir place")
	-- limpa workspace
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		pcall(function() ch:Destroy() end)
	end
	-- restaura os FILHOS do workspace (nao um Workspace aninhado)
	for _, kid in ipairs(data.workspace.kids or {}) do
		restoreInstance(kid, ws)
	end
	if data.lighting then
		local lighting = game:FindFirstChild("Lighting")
		if lighting then
			for _, ch in ipairs(lighting:GetChildren()) do pcall(function() ch:Destroy() end) end
			restoreInstance(data.lighting, lighting)
		end
	end
	ARKHER.out("SUCCESS", "Place restaurado: " .. tostring((data.meta or {}).name))
	return true
end

-- ---------- PERSISTENCIA (ServerStorage.ArkherCloud) ----------
local function store(id, json)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if not f then
		f = Instance.new("Folder")
		f.Name = tostring(id)
		f.Parent = P.placesFolder()
	end
	local sv = f:FindFirstChild("data")
	if not sv then
		sv = Instance.new("StringValue")
		sv.Name = "data"
		sv.Parent = f
	end
	sv.Value = json
	local meta = f:FindFirstChild("meta")
	if not meta then
		meta = Instance.new("StringValue")
		meta.Name = "meta"
		meta.Parent = f
	end
	return f
end

local function read(id)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if not f then return nil end
	local sv = f:FindFirstChild("data")
	if not sv then return nil end
	return HttpService:JSONDecode(sv.Value)
end

function P.save(name)
	local data = P.snapshot()
	data.meta.name = name or ARKHER.STATE.placeName
	ARKHER.STATE.placeName = data.meta.name
	local json = HttpService:JSONEncode(data)
	local id = ARKHER.STATE.placeId
	if id == 0 then
		id = math.floor(tick() * 1000) % 1000000000
		ARKHER.STATE.placeId = id
	end
	store(id, json)
	P.refreshList()
	ARKHER.out("SUCCESS", "Place salvo: " .. data.meta.name .. " (id " .. id .. ") — " .. #json .. " bytes")
	Bus.emit("place.saved", data.meta)
	return id
end

function P.new(template)
	template = template or "Baseplate"
	ARKHER.cmd("undo.push", "New place")
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then
			pcall(function() ch:Destroy() end)
		end
	end
	local t = P.TEMPLATES[template]
	if t then t() end
	ARKHER.STATE.placeName = "New " .. template .. " Place"
	ARKHER.STATE.placeId = 0
	ARKHER.out("SUCCESS", "Place novo criado: " .. template)
	Bus.emit("place.new", template)
	return ARKHER.STATE.placeName
end

function P.open(id)
	local data = read(id)
	if not data then
		ARKHER.out("ERROR", "Place nao encontrado: " .. tostring(id))
		return false
	end
	local ok = P.apply(data)
	if ok and data.meta then
		ARKHER.STATE.placeName = data.meta.name or "Place"
		ARKHER.STATE.placeId = tonumber(id) or 0
	end
	Bus.emit("place.opened", { id = id })
	return ok
end

function P.close()
	ARKHER.STATE.placeName = "Untitled"
	ARKHER.STATE.placeId = 0
	ARKHER.out("INFO", "Place fechado")
end

function P.refreshList()
	local list = {}
	for _, f in ipairs(P.placesFolder():GetChildren()) do
		local meta = f:FindFirstChild("meta")
		local sv = f:FindFirstChild("data")
		local info = { id = tonumber(f.Name) or 0, name = f.Name, bytes = sv and #sv.Value or 0 }
		if meta then
			local ok, m = pcall(function() return HttpService:JSONDecode(meta.Value) end)
			if ok and type(m) == "table" then info = m end
		end
		list[#list + 1] = info
	end
	table.sort(list, function(a, b) return (a.bytes or 0) > (b.bytes or 0) end)
	ARKHER.STATE.cloud.places = list
	return list
end

function P.list()
	return P.refreshList()
end

function P.delete(id)
	local f = P.placesFolder():FindFirstChild(tostring(id))
	if f then
		pcall(function() f:Destroy() end)
		P.refreshList()
		ARKHER.out("INFO", "Place removido: " .. tostring(id))
	end
end

-- ---------- EXPORT (bundle portavel, sem Open Cloud API) ----------
function P.exportBundle()
	local data = P.snapshot()
	local json = HttpService:JSONEncode(data)
	local generated = (os.date and os.date("%c")) or ""
	local header = "-- ARKHER PLACE BUNDLE v3\n-- nome: " .. data.meta.name .. "\n-- gerado: " .. generated .. "\n-- para restaurar: cole este arquivo no Command Bar do ARKHER (FILE > Import Bundle)\n"
	-- %q: string escapada (robusto, sem long strings que quebrariam o embed)
	local jsq = string.format("%q", json)
	local body = "local HttpService = game:GetService(\"HttpService\")\nlocal ServerStorage = game:GetService(\"ServerStorage\")\nlocal json = " .. jsq .. "\nlocal data = HttpService:JSONDecode(json)\nif ArkherPlaces then ArkherPlaces.apply(data)\nelse\n\tlocal root = ServerStorage:FindFirstChild(\"ArkherCloud\") or Instance.new(\"Folder\"); root.Parent = ServerStorage\n\tlocal f = Instance.new(\"Folder\"); f.Name = \"pending\"; f.Parent = root\n\tlocal sv = Instance.new(\"StringValue\"); sv.Name = \"bundle\"; sv.Value = json; sv.Parent = f\n\tprint(\"[ARKHER] bundle aguardando o editor: reabra o ARKHER e use FILE > Import Bundle\")\nend"
	return header .. body
end

function P.exportToFile()
	local bundle = P.exportBundle()
	local ok, err = pcall(function()
		if game.WriteFile then
			game:WriteFile("ArkherPlaces/" .. (ARKHER.STATE.placeName or "place") .. ".arkher.lua", bundle)
			ARKHER.out("SUCCESS", "Bundle exportado para o disco: ArkherPlaces/" .. (ARKHER.STATE.placeName or "place") .. ".arkher.lua")
			return true
		end
		return false
	end)
	if not ok or not err then
		ARKHER.out("WARNING", "game.WriteFile indisponivel (fora do Studio). Use FILE > Copy Bundle para copiar.")
		return false
	end
	return err
end

function P.copyBundle()
	local bundle = P.exportBundle()
	local ok = pcall(function()
		if setclipboard then setclipboard(bundle) end
		ARKHER.out("SUCCESS", "Bundle copiado para a area de transferencia (" .. #bundle .. " chars)")
		return true
	end)
	if not ok then
		ARKHER.out("WARNING", "Sem clipboard neste ambiente. Exporte para arquivo ou Cloud.")
	end
end

-- ---------- TEMPLATES REAIS ----------
P.TEMPLATES = {}
function P.TEMPLATES.Baseplate()
	local ws = workspace
	local plate = Instance.new("Part")
	plate.Name = "Baseplate"
	plate.Size = Vector3.new(120, 1, 120)
	plate.Position = Vector3.new(0, -0.5, 0)
	plate.Color = Color3.fromRGB(136, 136, 136)
	plate.Anchored = true
	plate.TopSurface = Enum.SurfaceType.Smooth
	plate.BottomSurface = Enum.SurfaceType.Smooth
	plate.Parent = ws
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.City()
	P.TEMPLATES.Baseplate()
	local ws = workspace
	local city = Instance.new("Model")
	city.Name = "City"
	city.Parent = ws
	local mat = {
		{ 120, 120, 130 }, { 100, 110, 130 }, { 140, 140, 150 }, { 90, 100, 120 },
	}
	local rng = Random.new(42)
	for i = 1, 24 do
		local b = Instance.new("Part")
		b.Name = "Building_" .. i
		local h = 6 + rng:NextInteger(0, 26)
		b.Size = Vector3.new(6 + rng:NextInteger(0, 8), h, 6 + rng:NextInteger(0, 8))
		b.Position = Vector3.new((rng:NextInteger(0, 14) - 7) * 10 + 5, h / 2 + 0.5, (rng:NextInteger(0, 14) - 7) * 10 + 5)
		b.Anchored = true
		local c = mat[(i % #mat) + 1]
		b.Color = Color3.fromRGB(c[1], c[2], c[3])
		b.Parent = city
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 220, 140)
		light.Brightness = 0.6
		light.Range = 8
		light.Parent = b
	end
	local road = Instance.new("Part")
	road.Name = "Road_X"
	road.Size = Vector3.new(90, 0.3, 6)
	road.Position = Vector3.new(0, 0.2, 0)
	road.Anchored = true
	road.Color = Color3.fromRGB(30, 30, 34)
	road.Parent = city
	local road2 = Instance.new("Part")
	road2.Name = "Road_Z"
	road2.Size = Vector3.new(6, 0.3, 90)
	road2.Position = Vector3.new(0, 0.2, 0)
	road2.Anchored = true
	road2.Color = Color3.fromRGB(30, 30, 34)
	road2.Parent = city
end

function P.TEMPLATES.Nature()
	local ws = workspace
	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Size = Vector3.new(160, 1, 160)
	ground.Position = Vector3.new(0, -0.5, 0)
	ground.Color = Color3.fromRGB(74, 110, 60)
	ground.Material = Enum.Material.Grass
	ground.Anchored = true
	ground.Parent = ws
	local hill = Instance.new("Part")
	hill.Name = "Hill"
	hill.Size = Vector3.new(40, 18, 40)
	hill.Position = Vector3.new(30, 9, -40)
	hill.Anchored = true
	hill.Color = Color3.fromRGB(88, 122, 70)
	hill.Material = Enum.Material.Grass
	hill.Parent = ws
	local water = Instance.new("Part")
	water.Name = "Lake"
	water.Size = Vector3.new(30, 0.4, 24)
	water.Position = Vector3.new(-30, 0.2, 25)
	water.Color = Color3.fromRGB(40, 110, 180)
	water.Material = Enum.Material.Water
	water.Anchored = true
	water.Transparency = 0.25
	water.Parent = ws
	local trees = Instance.new("Model")
	trees.Name = "Trees"
	trees.Parent = ws
	local rng = Random.new(7)
	for i = 1, 14 do
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk_" .. i
		trunk.Size = Vector3.new(1.2, 4, 1.2)
		trunk.Position = Vector3.new(rng:NextInteger(-60, 60), 2.5, rng:NextInteger(-60, 60))
		trunk.Anchored = true
		trunk.Color = Color3.fromRGB(92, 64, 40)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = trees
		local crown = Instance.new("Part")
		crown.Name = "Crown_" .. i
		crown.Size = Vector3.new(5, 5, 5)
		crown.Shape = Enum.PartType.Ball
		crown.Position = trunk.Position + Vector3.new(0, 4.5, 0)
		crown.Anchored = true
		crown.Color = Color3.fromRGB(40, 120, 45)
		crown.Material = Enum.Material.Grass
		crown.Parent = trees
	end
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.Space()
	local ws = workspace
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(20, 1, 20)
	platform.Position = Vector3.new(0, 0, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.Neon
	platform.Color = Color3.fromRGB(60, 80, 140)
	platform.Parent = ws
	local rock = Instance.new("Part")
	rock.Name = "Asteroid"
	rock.Size = Vector3.new(10, 10, 10)
	rock.Shape = Enum.PartType.Ball
	rock.Position = Vector3.new(20, 14, -18)
	rock.Anchored = false
	rock.Color = Color3.fromRGB(120, 110, 130)
	rock.Material = Enum.Material.Slate
	rock.Parent = ws
	local sun = Instance.new("Part")
	sun.Name = "Sun"
	sun.Size = Vector3.new(14, 14, 14)
	sun.Shape = Enum.PartType.Ball
	sun.Position = Vector3.new(-40, 24, -50)
	sun.Anchored = true
	sun.Material = Enum.Material.Neon
	sun.Color = Color3.fromRGB(255, 200, 90)
	sun.Parent = ws
	local light = Instance.new("PointLight")
	light.Parent = sun
	light.Brightness = 2
	light.Range = 120
	local spawn = Instance.new("Part")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.Position = Vector3.new(0, 1, 0)
	spawn.Anchored = true
	spawn.BrickColor = BrickColor.new("Bright blue")
	spawn.Parent = ws
end

function P.TEMPLATES.Empty()
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then
			pcall(function() ch:Destroy() end)
		end
	end
	local part = Instance.new("Part")
	part.Name = "Part"
	part.Anchored = true
	part.Parent = ws
end

P.TEMPLATES.Baseplate()
