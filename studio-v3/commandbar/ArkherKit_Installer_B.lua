--[[ ARKHER V3 — Installer ArkherKit_B: cria o ModuleScript em ReplicatedStorage.ArkherV3 ]]
local KIT = [====[
--[[ ARKHER V3 — KIT B (ModuleScript) — places + actions + singularity + live + boot ]]
-- Requer o Kit A (na mesma pasta). Instala em: ReplicatedStorage.ArkherV3.ArkherKit_B
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro (cria ReplicatedStorage.ArkherV3.ArkherKit_A).")
	end
	require(a)
end
_arkherLoadKitA()

do
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
end

do
--[[ ARKHER V3 — ACTIONS: registro central de comandos ]]
-- Menus, toolbar, atalhos, command palette e a IA usam o MESMO registro:
-- ARKHER.cmd("comando", arg). Nenhum botão da UI é decorativo.
local UserInputService = game:GetService("UserInputService")
local Selection = game:GetService("Selection")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")
local HttpService = game:GetService("HttpService")

local A = {}
ArkherActions = A
ARKHER.ACTIONS = A -- mesmo objeto: ARKHER.cmd() despacha p/ A

local function sel()
	local ok, s = pcall(function() return Selection:Get() end)
	if ok and s and #s > 0 then return s[1] end
	return nil
end

-- ================= PLACE / FILE =================
A["place.new"] = function(template)
	ArkherPlaces.new(template)
	ARKHER.out("SUCCESS", "Place novo: " .. ARKHER.STATE.placeName)
end
A["place.open"] = function(id)
	if id then
		ArkherPlaces.open(id)
	else
		ARKHER.open("SaveOpen")
	end
end
A["place.save"] = function()
	ArkherPlaces.save()
end
A["place.close"] = function()
	ArkherPlaces.close()
end
A["place.export"] = function()
	ArkherPlaces.exportToFile()
	ArkherPlaces.copyBundle()
end
A["file.save"] = A["place.save"]
A["file.savecloud"] = function()
	ArkherPublish.toLocal()
end
A["file.open"] = function()
	ARKHER.open("SaveOpen")
end
A["file.import"] = function()
	ARKHER.out("INFO", "Import: copie um bundle .arkher.lua e cole no editor (FILE > Copy Bundle usa a area de transferencia).")
	ARKHER.open("SaveOpen")
end
A["file.export"] = A["place.export"]

-- ================= PUBLISH (sem Open Cloud API) =================
A["publish.local"] = function()
	ArkherPublish.toLocal()
end
A["publish.cloud"] = function()
	if ArkherPublish.toEndpoint() then return end
	ARKHER.out("INFO", "Sem endpoint? O local cloud guardou o bundle. Configure em Settings > Cloud.")
	ArkherPublish.toLocal()
end
A["publish.native"] = function()
	ArkherPublish.toRobloxNative()
end
A["game.publish"] = A["publish.local"]
A["game.places"] = function()
	ARKHER.open("SaveOpen")
end
A["game.settings"] = function()
	ARKHER.open("Settings")
end
A["game.passes"] = function()
	ARKHER.open("PackageManager")
end
A["game.products"] = function()
	ARKHER.out("INFO", "Developer Products: use o Package Manager para registrar passes/produtos no manifest do place.")
	ARKHER.open("PackageManager")
end

-- ================= UNDO (todo editavel passa por aqui antes de mudar) =================
A["undo.push"] = function(label)
	pcall(function() ArkherUNDO.push(label) end)
end

-- ================= EDIT =================
A["edit.undo"] = function() ArkherUNDO.undo() end
A["edit.redo"] = function() ArkherUNDO.redo() end
A["edit.delete"] = function()
	local s = sel()
	if s then
		ARKHER.cmd("undo.push", "Delete " .. s.Name)
		local ok = pcall(function() s:Destroy() end)
		ARKHER.out(ok and "SUCCESS" or "WARNING", "Removido: " .. (ok and s.Name or "sem acesso (servico)"))
	end
end
A["edit.duplicate"] = function()
	local s = sel()
	if not s then return end
	ARKHER.cmd("undo.push", "Duplicate " .. s.Name)
	local clone
	local ok = pcall(function() clone = s:Clone() end)
	if ok and clone then
		clone.Name = s.Name .. " Copy"
		if s:IsA("BasePart") then
			clone.Position = s.Position + Vector3.new(2, 0, 2)
		end
		pcall(function() clone.Parent = s.Parent end)
		pcall(function() Selection:Set({ clone }) end)
		ARKHER.out("SUCCESS", "Duplicado: " .. clone.Name)
	end
end
A["edit.rename"] = function()
	local s = sel()
	if not s then return end
	ARKHER.open("SaveOpen")
	ARKHER.out("INFO", "Renomear: use o panel SaveOpen/Manager ou digite no Explorer do Studio: " .. s.Name)
end
A["edit.copy"] = function()
	local s = sel()
	if s then ARKHER.STATE.clipboard = s end
end
A["edit.paste"] = function()
	local c = ARKHER.STATE.clipboard
	if not c or not c.Parent then
		ARKHER.out("WARNING", "Clipboard vazio")
		return
	end
	ARKHER.cmd("undo.push", "Paste " .. c.Name)
	local clone
	local ok = pcall(function() clone = c:Clone() end)
	if ok and clone then
		clone.Name = c.Name .. " Copy"
		pcall(function() clone.Parent = workspace end)
		ARKHER.out("SUCCESS", "Colado: " .. clone.Name)
	end
end
A["edit.cut"] = function()
	ARKHER.cmd("edit.copy")
	ARKHER.cmd("edit.delete")
end

-- ================= INSERT (cria instancias REAIS) =================
local function insertAt(cls, name, opts)
	ARKHER.cmd("undo.push", "Insert " .. name)
	local inst
	local ok = pcall(function() inst = Instance.new(cls) end)
	if not ok or not inst then
		ARKHER.out("ERROR", "Insert: classe indisponivel " .. cls)
		return
	end
	inst.Name = name or cls
	local pos = workspace:FindFirstChild("Camera")
	local at = (opts and opts.pos) or Vector3.new(0, 3, 0)
	if opts and opts.apply then opts.apply(inst) end
	if inst:IsA("BasePart") then
		inst.Anchored = true
		inst.Position = at
	end
	pcall(function() inst.Parent = workspace end)
	pcall(function() Selection:Set({ inst }) end)
	ARKHER.out("SUCCESS", "Inserido: " .. inst.Name .. " (" .. cls .. ")")
	return inst
end
A["insert.part"] = function()
	insertAt("Part", "Part")
end
A["insert.sphere"] = function()
	insertAt("Part", "Sphere", { apply = function(p) p.Shape = Enum.PartType.Ball p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.cylinder"] = function()
	insertAt("Part", "Cylinder", { apply = function(p) p.Shape = Enum.PartType.Cylinder p.Size = Vector3.new(4, 8, 4) end })
end
A["insert.wedge"] = function()
	insertAt("Part", "Wedge", { apply = function(p) p.Shape = Enum.PartType.Wedge p.Size = Vector3.new(4, 4, 4) end })
end
A["insert.blockmesh"] = function()
	insertAt("Part", "BlockMesh", { apply = function(p) p.Shape = Enum.PartType.Block end })
end
A["insert.folder"] = function()
	local inst = insertAt("Folder", "Folder")
	return inst
end
A["insert.model"] = function()
	local m = insertAt("Model", "Model")
	local p = Instance.new("Part")
	p.Name = "Part"
	p.Anchored = true
	p.Size = Vector3.new(4, 4, 4)
	p.Parent = m
	return m
end
A["insert.script"] = function()
	insertAt("Script", "ServerScript", { apply = function(s) s.Source = "-- ServerScript\nprint(\"ARKHER: script criado\")\n" end })
end
A["insert.localscript"] = function()
	insertAt("LocalScript", "ClientScript", { apply = function(s) s.Source = "-- ClientScript\n" end })
end
A["insert.modulescript"] = function()
	insertAt("ModuleScript", "Module", { apply = function(s) s.Source = "return {}\n" end })
end
A["insert.text"] = function()
	local bb = insertAt("Part", "TextPart", { apply = function(p)
		p.Size = Vector3.new(8, 4, 1)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.Parent = p
		local lb = Instance.new("TextLabel")
		lb.Name = "Text"
		lb.Size = UDim2.new(1, 0, 1, 0)
		lb.BackgroundTransparency = 1
		lb.Text = "ARKHER"
		lb.TextScaled = true
		lb.TextColor3 = Color3.new(1, 1, 1)
		lb.Parent = sg
	end })
	return bb
end
A["insert.light"] = function()
	local m = insertAt("Model", "Light")
	local p = Instance.new("Part")
	p.Name = "LightPart"
	p.Anchored = true
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Parent = m
	local pl = Instance.new("PointLight")
	pl.Brightness = 2
	pl.Range = 20
	pl.Color = Color3.new(1, 1, 1)
	pl.Parent = p
	return m
end
A["insert.sound"] = function()
	local m = insertAt("Model", "Sound")
	local p = Instance.new("Part")
	p.Name = "SoundPart"
	p.Anchored = true
	p.Size = Vector3.new(1, 1, 1)
	p.Transparency = 1
	p.CanCollide = false
	p.Parent = m
	local s = Instance.new("Sound")
	s.Name = "Sound"
	s.Loops = false
	s.Parent = p
	return m
end

-- ================= TOOL / TRANSFORM =================
local TOOLS = { Select = "select", Move = "move", Rotate = "rotate", Scale = "scale" }
A["tool"] = function(t)
	ARKHER.STATE.tool = t
	ARKHER.out("INFO", "Ferramenta: " .. t)
	Bus.emit("tool.changed", t)
end
A["transform.lock"] = function()
	ARKHER.STATE.locked = not ARKHER.STATE.locked
	ARKHER.out("INFO", "Lock: " .. (ARKHER.STATE.locked and "ON" or "OFF"))
	Bus.emit("tool.locked", ARKHER.STATE.locked)
end
A["transform.mode"] = function()
	ARKHER.STATE.spaceMode = ARKHER.STATE.spaceMode == "Local" and "Global" or "Local"
	ARKHER.out("INFO", "Espaco de transform: " .. ARKHER.STATE.spaceMode)
end

-- move real do selecionado (arraste com as setas / WASD quando ferramenta Move)
local function nudge(dx, dy, dz)
	local s = sel()
	if not s or not s:IsA("BasePart") then return end
	if ARKHER.STATE.locked then
		ARKHER.out("WARNING", "Objeto travado (Lock ON)")
		return
	end
	local ok = pcall(function() s.Position = s.Position + Vector3.new(dx, dy, dz) end)
	if ok and ARKHER_STATE then end
end
A["move.x+" ] = function() nudge(1, 0, 0) end
A["move.x-"] = function() nudge(-1, 0, 0) end
A["move.y+"] = function() nudge(0, 1, 0) end
A["move.y-"] = function() nudge(0, -1, 0) end
A["move.z+"] = function() nudge(0, 0, 1) end
A["move.z-"] = function() nudge(0, 0, -1) end

-- ================= RUN =================
A["run.play"] = function()
	ARKHER.STATE.playing = true
	ARKHER.out("SUCCESS", "RUN: modo Play (simulacao ARKHER)")
	Bus.emit("run.play")
end
A["run.pause"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: pausado")
	Bus.emit("run.pause")
end
A["run.stop"] = function()
	ARKHER.STATE.playing = false
	ARKHER.out("INFO", "RUN: parado")
	Bus.emit("run.stop")
end
A["run.diagnostics"] = function()
	ARKHER_SINGULARITY.run("diagnostico completo do place")
end
A["run.perf"] = function()
	ARKHER.open("Profiler")
end
A["sandbox.toggle"] = function()
	ARKHER.STATE.sandbox = not ARKHER.STATE.sandbox
	ARKHER.out("INFO", "Sandbox: " .. (ARKHER.STATE.sandbox and "ON (plugins isolados)" or "OFF"))
	Bus.emit("sandbox.changed", ARKHER.STATE.sandbox)
end

-- ================= VIEW (abrir UIs) =================
A["view.properties"] = function() Bus.emit("view.toggle", "Properties") end
A["view.hierarchy"] = function() Bus.emit("view.toggle", "Hierarchy") end
A["view.console"] = function() ARKHER.open("Console") end
A["view.output"] = function() ARKHER.open("Console") end
A["view.palette"] = function()
	ARKHER.open("CommandPalette") -- registra/cria (na oculta)
	local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
	local g = fg and fg:FindFirstChild("ArkherStudioCommandPalette")
	if g then g.Visible = true end
end
A["ui.open"] = function(name)
	local ok = ARKHER.open(name)
	if ok then
		ARKHER.out("INFO", "UI aberta: " .. tostring(name))
	else
		ARKHER.out("WARNING", "UI nao abriu: " .. tostring(name))
	end
	return ok
end
A["view.reset"] = function()
	ARKHER.out("INFO", "Layout resetado")
	Bus.emit("view.reset")
end

-- ================= AI / SINGULARITY =================
A["ai.run"] = function(goal)
	ARKHER_SINGULARITY.run(goal)
end
A["ai.mode"] = function(mode)
	ARKHER.STATE.ai.mode = mode
	ARKHER.out("INFO", "IA modo: " .. mode)
	Bus.emit("ai.mode", mode)
end
A["ai.open"] = function()
	ARKHER.open("AIEditor")
end
A["utsai.open"] = function()
	ARKHER.open("UTSAI")
end

-- ================= CLOUD =================
A["cloud.status"] = function()
	local c = ARKHER.STATE.cloud
	ARKHER.out("INFO", "Cloud: " .. (c.endpoint and ("endpoint " .. c.endpoint) or "so local (ServerStorage)") .. " | " .. #c.places .. " places salvos")
	Bus.emit("cloud.status", c)
end
A["cloud.connect"] = function()
	ARKHER.open("Settings")
end
A["cloud.disconnect"] = function()
	ARKHER.STATE.cloud.endpoint = ""
	ARKHER.STATE.cloud.connected = false
	ARKHER.out("INFO", "Cloud: desconectado (modo local)")
	Bus.emit("cloud.status", ARKHER.STATE.cloud)
end

-- ================= TERRAIN X (custom, ArkherTerrainX) =================
local function txWorld(preset, seed)
	if not ArkherTerrainX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._world = ArkherTerrainX.new({ seed = seed or 1337, preset = preset or "continentes", cell = 8 })
	return ARKHER._world
end
A["terrain.generate"] = function(preset, seed)
	local w, err = txWorld(preset, seed)
	if not w then ARKHER.out("WARNING", "terrain.generate: " .. err) return end
	local res = w:materializeRegion(-96, -96, 192, 192, {})
	ARKHER.out("SUCCESS", "terrain.generate: preset '" .. w.preset .. "' seed " .. w.seed .. " → " .. res.parts .. " parts em " .. res.chunks .. " chunks")
end
A["terrain.erode"] = function(iters)
	if not ARKHER._world then txWorld() end
	local w = ARKHER._world
	if not w then ARKHER.out("WARNING", "terrain.erode: sem mundo ATX") return end
	local r = w:erodeHydraulic(1, 1, 48, 32, iters or 3000)
	ARKHER.out("SUCCESS", "terrain.erode: " .. (iters or 3000) .. " gotas | dMedio " .. string.format("%.3f", r.meanDelta))
end
A["terrain.rivers"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:carveRivers(1, 1, 48, 32, 20)
	ARKHER.out("SUCCESS", "terrain.rivers: " .. r.cells .. " celulas fluviais (acum. max " .. r.maxAcc .. ")")
end
A["terrain.lakes"] = function()
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	local r = ARKHER._world:fillLakes(1, 1, 48, 32)
	ARKHER.out("SUCCESS", "terrain.lakes: " .. r.cells .. " celulas de lago")
end
A["terrain.materialize"] = function(span)
	if not ARKHER._world then txWorld() end
	if not ARKHER._world then return end
	span = span or 192
	local res = ARKHER._world:materializeRegion(-span / 2, -span / 2, span, span, {})
	ARKHER.out("SUCCESS", "terrain.materialize: " .. span .. "x" .. span .. " → " .. res.parts .. " parts (LOD D-O15)")
end
A["terrain.lod"] = function(fx, fz)
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.lod: sem mundo ATX") return end
	local r = ARKHER._world:updateLOD(fx or 0, fz or 0)
	ARKHER.out("INFO", "terrain.lod: " .. r.updated .. " chunks re-materializados adaptativamente")
end
A["terrain.clear"] = function()
	if ARKHER._world then ArkherTerrainX.clearWorld(ARKHER._world) end
	ARKHER.out("SUCCESS", "terrain.clear: ATX_World removido")
end
A["terrain.export"] = function()
	if not ARKHER._world then ARKHER.out("WARNING", "terrain.export: sem mundo ATX") return end
	local str, path, ok = ARKHER._world:exportFile()
	ARKHER.out("SUCCESS", "terrain.export: " .. #str .. " chars → " .. path .. (ok and "" or " (string retornada)"))
end

-- ================= WATER X (custom, ArkherWaterX) =================
local function wxSea(preset)
	if not ArkherWaterX then return nil, "Kit C nao carregado (ArkherKit_Installer_C)" end
	ARKHER._sea = ArkherWaterX.preset(preset or "porto", { kind = "oceano", level = 0, size = { x = 420, z = 320 } })
	return ARKHER._sea
end
A["water.ocean"] = function(preset)
	local sea, err = wxSea(preset)
	if not sea then ARKHER.out("WARNING", "water.ocean: " .. err) return end
	local _, n = ArkherWaterX.materialize(sea, { maxSpan = 420 })
	ARKHER.out("SUCCESS", "water.ocean: preset '" .. (preset or "porto") .. "' → " .. n .. " tiles animadas de Gerstner")
end
A["water.caustics"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local n = ArkherWaterX.caustics(ARKHER._sea, ARKHER._sea.level - 9)
	ARKHER.out("SUCCESS", "water.caustics: " .. n .. " brilhos")
end
A["water.float"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then
		for _, inst in ipairs(sel) do
			if inst:IsA("BasePart") then ArkherWaterX.float(ARKHER._sea, inst, {}) n = n + 1 end
		end
	end
	ARKHER.out("SUCCESS", "water.float: flutuabilidade arquimediana em " .. n .. " parts")
end
A["water.underwater"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	ARKHER._underwater = not ARKHER._underwater
	ArkherWaterX.applyUnderwater(ARKHER._sea, ARKHER._underwater)
	ARKHER.out("INFO", "water.underwater: " .. (ARKHER._underwater and "ON" or "OFF"))
end
A["water.splash"] = function()
	if not ARKHER._sea then wxSea() end
	if not ARKHER._sea then return end
	if not ARKHER._sea.tiles then ArkherWaterX.materialize(ARKHER._sea, { maxSpan = 240 }) end
	ArkherWaterX.splash(ARKHER._sea, 0, ARKHER._sea:heightAt(0, 0, 0), 0, 2)
	ARKHER.out("SUCCESS", "water.splash emitido")
end

-- ================= SCRIPT X (IDE) =================
A["script.new"] = function(name, templateId)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.new: Kit D nao carregado") return end
	name = name or "NovoScript"
	local tp = templateId and ArkherScripterX.template(templateId) or ArkherScripterX.template("basico")
	local sc = Instance.new(tp.cls)
	sc.Name = name
	sc.Source = tp.src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.new: " .. tp.cls .. " '" .. name .. "' (template " .. tp.id .. ") criado no workspace")
end
A["script.newfromgoal"] = function(goal)
	if not ArkherScripterX then ARKHER.out("WARNING", "script.newfromgoal: Kit D nao carregado") return end
	local src, id2 = ArkherScripterX.compose(goal or "basico")
	local sc = Instance.new("Script")
	sc.Name = "IA_" .. id2
	sc.Source = src
	sc.Parent = workspace
	ARKHER.out("SUCCESS", "script.newfromgoal: template '" .. id2 .. "' composto p/ '" .. tostring(goal) .. "'")
end
A["script.lintreport"] = function()
	if not ArkherScripterX then return end
	local sel2 = sel()
	if not (sel2 and sel2:IsA("LuaSourceContainer")) then
		ARKHER.out("INFO", "script.lintreport: selecione um Script no explorer")
		return
	end
	local diags = ArkherScripterX.lint(sel2.Source or "")
	local sum = ArkherScripterX.lintSummary(diags)
	ARKHER.out("INFO", "lint " .. sel2.Name .. ": " .. sum.errors .. " err, " .. sum.warns .. " warn, " .. sum.infos .. " info")
end

-- ================= UI KIT X =================
A["uix.hud"] = function()
	if not ArkherUIKitX then ARKHER.out("WARNING", "uix.hud: Kit D nao carregado") return end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("timer", { x = 850, y = 16, text = "10:00" }),
		X.create("coins", { x = 16, y = 52, text = "1.0K" }),
	}
	local gui, n = X.build(widgets, "ArkherHUD")
	ARKHER.out("SUCCESS", "uix.hud: " .. n .. " widgets no StarterGui.ArkherHUD")
end
A["uix.theme"] = function(id)
	if ArkherUIKitX then ArkherUIKitX.setTheme(id or "arkher") ARKHER.out("INFO", "uix.theme: " .. (id or "arkher")) end
end

-- ================= ANIMATION X (AAX) =================
A["anim.demo"] = function()
	if not ArkherAnimX then ARKHER.out("WARNING", "anim.demo: Kit E nao carregado (ArkherKit_Installer_E)") return end
	local AX = ArkherAnimX
	local ws = workspace
	local p = Instance.new("Part")
	p.Name = "AAX_DemoCube"
	p.Size = Vector3.new(2, 2, 2)
	p.Anchored = true
	p.Color = Color3.fromRGB(255, 170, 60)
	p.CFrame = CFrame.new(0, 4, 0)
	p.Parent = ws
	local c = AX.clip("DemoCube", { loop = "pingpong" })
	c:addTrack("Position", { AX.key(0, { x = 0, y = 4, z = 0 }, "easeInOut_sine"), AX.key(1.2, { x = 0.4, y = 7.2, z = 0 }, "easeOut_spring"), AX.key(2.4, { x = 0, y = 4, z = 0 }, "easeInOut_sine") })
	c:addTrack("Transparency", { AX.key(0, 0.5, "linear"), AX.key(1.2, 0, "easeOut_sine"), AX.key(2.4, 0.5, "linear") })
	c:marker(1.2, "pico")
	c:bind(p, {})
	c:play({ from = 0 })
	ARKHER._animDemo = c
	ARKHER.out("SUCCESS", "anim.demo: cube no workspace tocando (easeOut_spring + pingpong)")
end
A["anim.pump"] = function(dt)
	if ArkherAnimX then
		local n = ArkherAnimX.pump(dt or 0.016)
		ArkherAnimX.pumpDeformers(dt or 0.016)
		ARKHER.out("INFO", "anim.pump: " .. n .. " clips vivos")
	end
end
A["anim.stopall"] = function()
	if ArkherAnimX then ArkherAnimX.stopAll() ARKHER.out("SUCCESS", "anim.stopall executado") end
end
A["anim.wave"] = function()
	if not ArkherAnimX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and sel and #sel >= 1 then
		local asm = ArkherAnimX.assemble(sel)
		ARKHER._deform = ArkherAnimX.deform(asm, ArkherAnimX.DEFORMERS.wave(1.2, 14, 2.2), {})
		ARKHER.out("SUCCESS", "anim.wave: deformer ondulando " .. #sel .. " parts (assembly)")
	else
		ARKHER.out("INFO", "anim.wave: selecione parts")
	end
end

-- ================= AUDIO X (AUX) =================
A["audio.setup"] = function()
	if not ArkherAudioX then ARKHER.out("WARNING", "audio.*: Kit E nao carregado") return end
	ArkherAudioX.setup()
	local st = ArkherAudioX.stats()
	ARKHER.out("SUCCESS", "audio.setup: " .. st.buses .. " buses SoundGroup criadas no SoundService")
end
A["audio.duckdemo"] = function()
	if not ArkherAudioX then return end
	ArkherAudioX.setup()
	ArkherAudioX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.register("voice_demo", { bus = "voice", volume = 0.6 })
	ArkherAudioX.duck("music", "voice", { level = 0.3 })
	ArkherAudioX.play("musica_demo")
	ArkherAudioX.play("voice_demo")
	ARKHER.out("SUCCESS", "audio.duckdemo: musica ducked p/ 30% quando a voz toca (sidechain)")
end
A["audio.patch"] = function(bus, preset)
	if not ArkherAudioX then return end
	local ok, n = ArkherAudioX.patch(bus or "music", preset or "caverna")
	ARKHER.out(ok and "SUCCESS" or "WARNING", "audio.patch: " .. (preset or "caverna") .. " → " .. tostring(n))
end

-- ================= SCENE / SCATTER X (ASXN) =================
A["scene.forest"] = function(radius)
	if not ArkherSceneX then ARKHER.out("WARNING", "scene.*: Kit E nao carregado") return end
	local w = ARKHER._world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
	ARKHER._world = w
	local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = radius or 90, count = 70, minDist = 6, maxSlope = 0.9, world = w, seed = 777, name = "ASXN_Forest" })
	ARKHER.out("SUCCESS", "scene.forest: " .. res.count .. " arvores/arbustos/grama no mundo (biomas Whittaker)")
end
A["scene.patina"] = function()
	if not ArkherSceneX then return end
	local ok, sel = pcall(function() return Selection:Get() end)
	local n = 0
	if ok and sel then n = ArkherSceneX.patina(sel, {}) end
	ARKHER.out("SUCCESS", "scene.patina: variacao anti-CG em " .. n .. " parts")
end
A["scene.query"] = function(cls)
	if not ArkherSceneX then return end
	local list = ArkherSceneX.query({ class = cls or "Part" })
	ARKHER.out("INFO", "scene.query '" .. (cls or "Part") .. "' → " .. #list .. " resultados")
end
A["scene.rehash"] = function()
	if ArkherSceneX then
		local n = ArkherSceneX.rehash()
		ARKHER.out("SUCCESS", "scene.rehash: " .. n .. " parts no spatial hash")
	end
end
A["scene.lod"] = function()
	if ArkherSceneX then
		local r = ArkherSceneX.applyLOD(0, 0)
		ARKHER.out("INFO", "scene.lod: " .. r.shown .. " visiveis, " .. r.ghosts .. " ghosts, " .. r.culled .. " culled")
	end
end

-- ================= ATMOS X (ceu + clima custom) =================
A["atmos.setup"] = function()
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.setup({})
	ARKHER.out("SUCCESS", "atmos.setup: Lighting real vinculado (Atmosphere + ColorCorrection)")
end
A["atmos.preset"] = function(name)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "meiodia"
	if ArkherAtmosX.setPreset(name) then
		ArkherAtmosX.apply({})
		ARKHER.out("SUCCESS", "atmos.preset: " .. name .. " (Kelvin real aplicado ao Lighting)")
	else
		ARKHER.out("ERROR", "atmos.preset desconhecido: " .. name)
	end
end
A["atmos.weather"] = function(name, speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	name = name or "limpo"
	if ArkherAtmosX.setWeather(name, speedo or 0.6) then
		for i = 1, 90 do ArkherAtmosX.pump(1 / 30) end
		ARKHER.out("SUCCESS", "atmos.weather: " .. name .. " (transicao completa, links AWX/AUX aplicados)")
	else
		ARKHER.out("ERROR", "atmos.weather desconhecido: " .. name)
	end
end
A["atmos.cycle"] = function(speedo)
	if not ArkherAtmosX then ARKHER.out("WARNING", "atmos.*: Kit E nao carregado") return end
	ArkherAtmosX.S.cycleSpeed = speedo or 0.2
	ARKHER.out("INFO", "atmos.cycle: velocidade do ciclo solar = " .. tostring(ArkherAtmosX.S.cycleSpeed) .. " h/s")
end

-- ================= CAMERA X (cinematografia custom) =================
A["cam.orbit"] = function(radius, height, seconds)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = radius or 14, height = height or 6, speed = 0.6, duration = 9999 })
	ARKHER.out("SUCCESS", "cam.orbit: camera orbitando (raio " .. (radius or 14) .. " m)")
end
A["cam.crane"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
	ARKHER.out("SUCCESS", "cam.crane: movimento crane 4s com lift")
end
A["cam.fly"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
	ARKHER.out("SUCCESS", "cam.fly: trajetoria Catmull-Rom 3D real (5s)")
end
A["cam.shake"] = function(t)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.addTrauma(t or 0.8)
	ARKHER.out("INFO", "cam.shake: trauma +" .. (t or 0.8) .. " (amplitude trauma^2 real)")
end
A["cam.fade"] = function(to)
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.fade(to or -1, 0.8)
	ARKHER.out("SUCCESS", "cam.fade: ColorCorrection real -> brightness " .. tostring(to or -1))
end
A["cam.cinema"] = function()
	if not ArkherCameraX then ARKHER.out("WARNING", "cam.*: Kit E nao carregado") return end
	ArkherCameraX.cinema({
		{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 },
		{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
		{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
	})
	ARKHER.out("SUCCESS", "cam.cinema: sequencia de 3 cortes reais iniciada")
end
A["cam.stop"] = function() if ArkherCameraX then ArkherCameraX.stop() ARKHER.out("INFO", "cam.stop") end end

-- ================= PARTICLES X (emissores custom) =================
A["px.emit"] = function(kind)
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	kind = kind or "fogo"
	local pe = ArkherParticlesX.emit(nil, kind)
	ARKHER.out("SUCCESS", "px.emit: " .. kind .. " (ParticleEmitter real, budget D-O15 aplicado)")
	return pe
end
A["px.demo"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	local kinds = { "fogo", "fumaca", "magia" }
	for _, k in ipairs(kinds) do ArkherParticlesX.emit(nil, k) end
	ARKHER.out("SUCCESS", "px.demo: fogo + fumaca + magia emitidos")
end
A["px.clear"] = function()
	if ArkherParticlesX then ArkherParticlesX.clear() ARKHER.out("INFO", "px.clear: todos desligados") end
end
A["px.storm"] = function()
	if not ArkherParticlesX then ARKHER.out("WARNING", "px.*: Kit E nao carregado") return end
	if ArkherAtmosX then ArkherAtmosX.setup({}) ArkherAtmosX.setWeather("tempestade", 1.2) end
	ArkherParticlesX.emit(nil, "chuva", { rate = 240, speed = 40 })
	ARKHER.out("SUCCESS", "px.storm: chuva fisica + ATX... AEX tempestade (onda awx no pump)")
end

-- ================= GENERIC: ui.<nome> =================
function A.registerUICommands()
	for name in pairs(ARKHER.CATALOG) do
		ARKHER.on("ui." .. name, function()
			ARKHER.open(name)
		end)
		ARKHER.on(name, function()
			ARKHER.open(name)
		end)
	end
	-- atalhos de menu comuns
	ARKHER.on("menu.file.save", A["file.save"])
end

-- ================= SHORTCUTS =================
function A.startShortcuts()
	local CTRL = {
		[Enum.KeyCode.K] = function() ARKHER.open("CommandPalette") end,
		[Enum.KeyCode.Z] = function() ArkherUNDO.undo() end,
		[Enum.KeyCode.Y] = function() ArkherUNDO.redo() end,
		[Enum.KeyCode.D] = function() ARKHER.cmd("edit.duplicate") end,
		[Enum.KeyCode.C] = function() ARKHER.cmd("edit.copy") end,
		[Enum.KeyCode.X] = function() ARKHER.cmd("edit.cut") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("edit.paste") end,
	}
	local PLAIN = {
		[Enum.KeyCode.Delete] = function() ARKHER.cmd("edit.delete") end,
		[Enum.KeyCode.L] = function() ARKHER.cmd("transform.lock") end,
		[Enum.KeyCode.V] = function() ARKHER.cmd("tool", "Select") end,
		[Enum.KeyCode.W] = function() ARKHER.cmd("tool", "Move") end,
		[Enum.KeyCode.E] = function() ARKHER.cmd("tool", "Rotate") end,
		[Enum.KeyCode.R] = function() ARKHER.cmd("tool", "Scale") end,
	}
	local NUDGE = {
		[Enum.KeyCode.W] = "move.z-", [Enum.KeyCode.S] = "move.z+",
		[Enum.KeyCode.A] = "move.x-", [Enum.KeyCode.D] = "move.x+",
		[Enum.KeyCode.Q] = "move.y-", [Enum.KeyCode.E] = "move.y+",
	}
	local function onKey(inp, gp)
		if gp then return end
		local isCtrl = pcall(function() return UserInputService:IsKeyDown(Enum.LeftControl) end)
			and UserInputService:IsKeyDown(Enum.LeftControl)
		local code = inp.KeyCode
		if isCtrl and CTRL[code] then
			pcall(CTRL[code])
			return
		end
		if not isCtrl and PLAIN[code] then
			pcall(PLAIN[code])
		end
		-- nudge com WASD quando ferramenta Move (W/E disputam com tool; nudge tem prioridade em Move)
		if ARKHER.STATE.tool == "Move" and not isCtrl and NUDGE[code] then
			ARKHER.cmd(NUDGE[code])
		end
	end
	pcall(function()
		UserInputService.InputBegan:Connect(onKey)
	end)
	ARKHER.out("INFO", "Atalhos: Ctrl+K palette | Ctrl+Z/Y undo/redo | Del apagar | Ctrl+C/X/V/D | V/W/E/R ferramentas | L lock | WASD/Q/E move (ferramenta Move)")
end
end

do
--[[ ARKHER V3 — SINGULARITY CORE: IA operadora do editor ]]
-- Arquitetura: USER → objetivo → PLANNER → tarefas → ESPECIALISTAS → VERIFIER → relatório
-- Especialistas LOCAIS executam de verdade no Roblox (procedural real, sem depender de web).
-- Ponte opcional: se o usuario configurar um endpoint (Settings > AI), o plano tambem
-- pode vir de um LLM externo (mesmo contrato JSON). Sem endpoint = modo local 100%.
local HttpService = game:GetService("HttpService")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local SG = {}
ARKHER_SINGULARITY = SG

SG.memory = { decisions = {}, context = {}, tasks = 0 }

local function log(kind, msg)
	ARKHER.out(kind, "[SINGULARITY] " .. tostring(msg))
end

local function report(title, lines)
	local out = { title = title, lines = lines, ok = true }
	Bus.emit("singularity.report", out)
	log("SUCCESS", title .. " — " .. #lines .. " etapas")
	return out
end

-- ---------- PLANNER LOCAL (intent → tarefas) ----------
local INTENTS = {
	city = { "cidade", "city", "prédios", "predios", "buildings", "rua", "road", "urbe" },
	nature = { "floresta", "forest", "natureza", "nature", "arvore", "árvore", "tree", "montanha", "mountain", "lago", "lake" },
	space = { "espaco", "espaço", "space", "asteroide", "asteroid", "planet", "planeta" },
	npc = { "npc", "personagem", "personagens", "habitantes", "population", "populacao", "população", "moradores" },
	light = { "luz", "light", "iluminacao", "iluminação", "noite", "night", "amanhecer", "sunset", "day", "dia" },
	clean = { "organizar", "organize", "arrumar", "naming", "rotular", "label" },
	perf = { "otimizar", "otimiza", "otimizado", "otimizada", "otimizacao", "otimização", "otimise", "otimize", "otimizar", "optimize", "optimized", "performance", "fps", "leve" },
	check = { "diagnostico", "diagnóstico", "diagnostics", "analisar", "analyze", "auditoria", "audit" },
	material = { "material", "pbr", "superficie", "superfície", "textura", "texture" },
	place = { "place", "mundo", "world", "mapa", "map" },
	terrain = { "terreno", "terrain", "relief", "relevo", "heightmap", "erosao", "erosão", "rio", "rios", "river", "geologia", "canyon", "vulcao", "vulcão", "ilha", "ilhas", "vale", "bioma", "biomas", "continente", "geography" },
	water = { "agua", "água", "water", "oceano", "ocean", "mar", "sea", "onda", "ondas", "wave", "waves", "cachoeira", "waterfall", "lagoa", "tsunami", "rio2", "piscina", "pool" },
	ui = { "hud", "ui", "interface", "gui", "menu", "barra de vida", "lifetime", "hotbar", "inventario", "inventário", "placar", "leaderboard" },
	audio = { "som", "audio", "musica", "music", "sound", "trilha", "soundtrack", "barulho", "mixer", "reverb", "acustica", "acústica" },
	anim = { "animacao", "animação", "anim", "animation", "mover", "movimento", "dancar", "dançar", "timeline", "keyframe" },
	clima = { "clima", "weather", "chuva", "rain", "tempestade", "storm", "neve", "snow", "neblina", "fog", "aurora", "trovao", "trovão", "raio", "lightning", "ensolarado", "ceu", "céu", "sky" },
	camera = { "camera", "câmera", "filme", "film", "cinematic", "cinematica", "cinematográfica", "orbita", "orbit", "crane", "dolly", "shake", "tremor", "fly", "corte", "shot" },
	particles = { "particulas", "partículas", "particles", "fogo", "fire", "faisca", "faísca", "sparks", "magia", "magic", "explosao", "explosão", "fumaca", "fumaça", "smoke", "splash", "poeira", "dust" },
}

local function detectIntents(text)
	local t = (text or ""):lower()
	local found = {}
	for name, kws in pairs(INTENTS) do
		for _, kw in ipairs(kws) do
			if t:find(kw, 1, true) then
				found[name] = true
				break
			end
		end
	end
	return found
end

function SG.plan(goal)
	local intents = detectIntents(goal)
	local plan = { goal = goal, tasks = {}, mode = ARKHER.STATE.ai.mode }
	local order = { "place", "terrain", "water", "city", "nature", "space", "material", "light", "npc", "ui", "audio", "anim", "clima", "particles", "camera", "clean", "perf", "check" }
	for _, name in ipairs(order) do
		if intents[name] then table.insert(plan.tasks, name) end
	end
	if #plan.tasks == 0 then
		table.insert(plan.tasks, "check")
	end
	return plan
end

-- ---------- ESPECIALISTAS LOCAIS (execucao REAL no Roblox) ----------
local E = {}
SG.experts = E

function E.place(ctx)
	ARKHER.cmd("undo.push", "Singularity: place")
	local ws = workspace
	for _, ch in ipairs(ws:GetChildren()) do
		if ch.Name ~= "Camera" and ch.Name ~= "Terrain" then pcall(function() ch:Destroy() end) end
	end
	ArkherPlaces.TEMPLATES.Baseplate()
	ctx.lines[#ctx.lines + 1] = "base: baseplate 120x120 + spawn criados"
end

function E.city(ctx)
	local model = Instance.new("Model")
	model.Name = "CityGen_" .. (SG.memory.tasks + 1)
	model.Parent = workspace
	local rng = Random.new(SG.memory.tasks * 17 + 3)
	local n = 10 + rng:NextInteger(0, 8)
	local built = 0
	for i = 1, n do
		local b = Instance.new("Part")
		b.Name = "Building_" .. i
		local h = 5 + rng:NextInteger(0, 22)
		b.Size = Vector3.new(5 + rng:NextInteger(0, 7), h, 5 + rng:NextInteger(0, 7))
		b.Position = Vector3.new((rng:NextInteger(-6, 6)) * 9 + 4.5, h / 2 + 0.5, (rng:NextInteger(-6, 6)) * 9 + 4.5)
		b.Anchored = true
		b.Color = Color3.fromRGB(90 + rng:NextInteger(0, 70), 95 + rng:NextInteger(0, 70), 110 + rng:NextInteger(0, 70))
		b.Parent = model
		built = built + 1
	end
	local roads = 0
	for i = -1, 1 do
		local r = Instance.new("Part")
		r.Name = "Road_" .. (i + 2)
		r.Size = Vector3.new(80, 0.2, 5)
		r.Position = Vector3.new(0, 0.15, i * 18)
		r.Anchored = true
		r.Color = Color3.fromRGB(28, 28, 32)
		r.Material = Enum.Material.Asphalt
		r.Parent = model
		roads = roads + 1
	end
	ctx.lines[#ctx.lines + 1] = "cidade: " .. built .. " edificios + " .. roads .. " ruas (procedural, seed " .. (SG.memory.tasks * 17 + 3) .. ")"
end

function E.nature(ctx)
	-- V4: se o Scene/Scatter X esta carregado, o "natureza" vira povoamento
	-- REAL por bioma/declive no ATX (arvores com dossel organico, arbustos, etc)
	if ArkherSceneX then
		local w = SG.world or (ArkherTerrainX and ArkherTerrainX.new({ seed = 1337, preset = "montanhas", cell = 8 }))
		SG.world = SG.world or w
		local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = 110, count = 60, minDist = 7, maxSlope = 0.9, world = w, seed = 99 + SG.memory.tasks, name = "ASXN_Nature" })
		local trees, bushes = 0, 0
		for _, m in ipairs(res.made or {}) do
			local tg = m:GetAttribute("arkher_tag")
			if tg == "tree" then trees = trees + 1 elseif tg == "bush" then bushes = bushes + 1 end
		end
		ctx.lines[#ctx.lines + 1] = "natureza SCATTER: " .. res.count .. " entidades (" .. trees .. " arvores dossel-organico, " .. bushes .. " arbustos — " .. res.tries .. " amostras poisson)"
		return
	end
	local rng = Random.new(99)
	local trees = 0
	for i = 1, 12 do
		local trunk = Instance.new("Part")
		trunk.Name = "Tree_" .. i
		trunk.Size = Vector3.new(1.2, 4, 1.2)
		trunk.Position = Vector3.new(rng:NextInteger(-50, 50), 2, rng:NextInteger(-50, 50))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(90, 62, 38)
		trunk.Parent = workspace
		local crown = Instance.new("Part")
		crown.Name = "Crown_" .. i
		crown.Shape = Enum.PartType.Ball
		crown.Size = Vector3.new(5, 5, 5)
		crown.Position = trunk.Position + Vector3.new(0, 4.5, 0)
		crown.Anchored = true
		crown.Material = Enum.Material.Grass
		crown.Color = Color3.fromRGB(35 + rng:NextInteger(0, 30), 110 + rng:NextInteger(0, 40), 40)
		crown.Parent = workspace
		trees = trees + 1
	end
	ctx.lines[#ctx.lines + 1] = "natureza: " .. trees .. " arvores plantadas"
end

function E.space(ctx)
	local sun = workspace:FindFirstChild("Sun")
	if not sun then
		local s = Instance.new("Part")
		s.Name = "Sun"
		s.Shape = Enum.PartType.Ball
		s.Size = Vector3.new(12, 12, 12)
		s.Position = Vector3.new(-40, 30, -50)
		s.Anchored = true
		s.Material = Enum.Material.Neon
		s.Color = Color3.fromRGB(255, 200, 90)
		s.Parent = workspace
		local pl = Instance.new("PointLight")
		pl.Parent = s
		pl.Brightness = 2
		pl.Range = 150
		ctx.lines[#ctx.lines + 1] = "espaco: sol neon + luz pontual adicionados"
	end
end

function E.material(ctx)
	local count = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, v = pcall(function() return ch.Material end)
			if ok and v then
				if v.Name == "SmoothPlastic" then
					local mats = { "Concrete", "Metal", "Wood", "Slate" }
					pcall(function() ch.Material = Enum.Material[mats[count % #mats + 1]] end)
					count = count + 1
				end
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "materiais: " .. count .. " superficies variadas (anti-padrao visual)"
end

function E.light(ctx)
	local lighting = game:FindFirstChild("Lighting")
	if lighting then
		local ok, v = pcall(function() return lighting.Ambient end)
		if ok and v then
			pcall(function() lighting.Ambient = Color3.fromRGB(90, 95, 120) end)
		end
		local ok2, v2 = pcall(function() return lighting.OutdoorAmbient end)
		if ok2 and v2 then
			pcall(function() lighting.OutdoorAmbient = Color3.fromRGB(70, 80, 110) end)
		end
		local sun = lighting:FindFirstChild("Sun")
		if not sun then
			local s = Instance.new("Part")
			s.Name = "Sun"
			s.Anchored = true
			s.CanCollide = false
			s.Size = Vector3.new(1, 1, 1)
			s.Transparency = 1
			s.Position = Vector3.new(50, 60, -40)
			local d = Instance.new("DirectionalLight")
			d.Parent = s
			d.Brightness = 2.2
			d.Color = Color3.fromRGB(255, 230, 190)
			s.Parent = lighting
			ctx.lines[#ctx.lines + 1] = "luz: DirectionalLight solar criada"
		end
	end
end

function E.npc(ctx)
	local spawned = 0
	for i = 1, 4 do
		local mind = ArkherNMN.spawn("Inhabitant_" .. i, Vector3.new(math.random(-30, 30), 3, math.random(-30, 30)))
		if mind then spawned = spawned + 1 end
	end
	ctx.lines[#ctx.lines + 1] = "npcs: " .. spawned .. " habitantes NMN com mente ativa (percepcao/precisoes/memoria)"
end

function E.clean(ctx)
	local counts = {}
	for _, ch in ipairs(workspace:GetDescendants()) do
		counts[ch.ClassName] = (counts[ch.ClassName] or 0) + 1
	end
	local moved = 0
	local byType = {}
	for _, ch in ipairs(workspace:GetChildren()) do
		if not ch:IsA("Model") then
			local bucket = ch.ClassName == "Part" and "Parts" or ch.ClassName
			if not byType[bucket] then
				local f = Instance.new("Folder")
				f.Name = bucket
				f.Parent = workspace
				byType[bucket] = f
			end
			if ch:IsA("BasePart") and not ch:IsA("Terrain") then
				pcall(function() ch.Parent = byType[bucket] end)
				moved = moved + 1
			end
		end
	end
	ctx.lines[#ctx.lines + 1] = "organizacao: " .. moved .. " itens agrupados por tipo"
end

function E.perf(ctx)
	local fixed = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		if ch:IsA("BasePart") then
			local ok, a = pcall(function() return ch.Anchored end)
			local ok2, c = pcall(function() return ch.CanCollide end)
			if ok and a == false and ch.Name:find("Spawn") == nil then
				pcall(function() ch.Anchored = true end)
				fixed = fixed + 1
			end
		end
	end
	Bus.emit("do15.nudge", 1)
	ctx.lines[#ctx.lines + 1] = "performance: " .. fixed .. " partes ancoradas + D-O15 forcado p/ MAX"
end

function E.check(ctx)
	local parts, scripts, models, unanchored = 0, 0, 0, 0
	local total = 0
	for _, ch in ipairs(workspace:GetDescendants()) do
		total = total + 1
		if ch:IsA("BasePart") then
			parts = parts + 1
			local ok, a = pcall(function() return ch.Anchored end)
			if ok and a == false then unanchored = unanchored + 1 end
		elseif ch:IsA("Script") or ch:IsA("LocalScript") or ch:IsA("ModuleScript") then
			scripts = scripts + 1
		elseif ch:IsA("Model") then
			models = models + 1
		end
	end
	local rep = ArkherDO15 and ArkherDO15.report() or {}
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. parts .. " parts | " .. models .. " models | " .. scripts .. " scripts | " .. total .. " instancias"
	ctx.lines[#ctx.lines + 1] = "diagnostico: " .. unanchored .. " partes sem anchor (verificar fisica)"
	ctx.lines[#ctx.lines + 1] = "diagnostico: FPS=" .. tostring(math.floor(rep.fps or 0)) .. " | D-O15=" .. tostring(rep.levelName or "?") .. " | frame=" .. string.format("%.1f", rep.frameMs or 0) .. "ms"
end

function E.terrain(ctx)
	if not ArkherTerrainX then
		ctx.lines[#ctx.lines + 1] = "terreno: Kit C (ATX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local TX = ArkherTerrainX
	local seed = 1000 + SG.memory.tasks * 137
	local w = TX.new({ seed = seed, preset = "continentes", cell = 8 })
	local hyd = w:erodeHydraulic(1, 1, 48, 32, 2200)
	local riv = w:carveRivers(1, 1, 48, 32, 20)
	w:fillLakes(1, 1, 48, 32)
	local built = w:materializeRegion(-96, -96, 192, 192, {})
	local biomes = w:biomeCounts()
	local nb = 0
	for _ in pairs(biomes) do nb = nb + 1 end
	SG.world = w
	ctx.lines[#ctx.lines + 1] = "terreno ATX: mundo procedural seed " .. seed .. " (erosao " .. string.format("%.3f", hyd.meanDelta) .. " dMedio/" .. string.format("%.1f", hyd.maxDelta) .. " dMax)"
	ctx.lines[#ctx.lines + 1] = "terreno ATX: rios " .. riv.cells .. " celulas | " .. nb .. " biomas Whittaker | " .. built.parts .. " parts em " .. built.chunks .. " chunks (materializacao real)"
end

function E.water(ctx)
	if not ArkherWaterX then
		ctx.lines[#ctx.lines + 1] = "agua: Kit C (AWX) nao carregado — rode ArkherKit_Installer_C"
		return
	end
	local WX = ArkherWaterX
	local sea = WX.preset("porto", { kind = "oceano", level = (SG.world and SG.world.seaLevel) or 0, size = { x = 420, z = 320 } })
	sea.foaminess = 0.55
	local model, tiles = WX.materialize(sea, { maxSpan = 420 })
	local cau = WX.caustics(sea, sea.level - 9)
	SG.sea = sea
	ctx.lines[#ctx.lines + 1] = "agua AWX: oceano preset 'porto' — " .. #sea.waves .. " ondas Gerstner (dispersao omega=sqrt(gk)), mare, correntes Stokes"
	ctx.lines[#ctx.lines + 1] = "agua AWX: " .. tiles .. " tiles animadas + " .. cau .. " causticas | dens " .. sea.props.dens .. " | salinidade " .. sea.props.sal .. " g/L"
end

function E.ui(ctx)
	if not ArkherUIKitX then
		ctx.lines[#ctx.lines + 1] = "hud: Kit D (AXI) nao carregado — rode ArkherKit_Installer_D"
		return
	end
	local X = ArkherUIKitX
	local widgets = {
		X.create("health", { x = 16, y = 16 }),
		X.create("stamina", { x = 16, y = 48, value = 0.7 }),
		X.create("xpbar", { x = 16, y = 70, value = 0.35 }),
		X.create("hotbar", { x = 16, y = 470, slots = 6 }),
		X.create("coins", { x = 16, y = 100, text = "8.2K" }),
		X.create("timer", { x = 850, y = 16, text = "09:41" }),
		X.create("minimap", { x = 790, y = 60 }),
		X.create("questtracker", { x = 690, y = 230 }),
	}
	local gui, n = X.build(widgets, "ArkherHUD_AI")
	ctx.lines[#ctx.lines + 1] = "hud AXI: " .. n .. " widgets montados no StarterGui.ArkherHUD_AI (health/stamina/xp/hotbar/coins/timer/minimap/quest)"
end

function E.audio(ctx)
	if not ArkherAudioX then
		ctx.lines[#ctx.lines + 1] = "audio: Kit E (AUX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AX = ArkherAudioX
	AX.setup()
	AX.register("musica_demo", { bus = "music", volume = 0.5, looped = true })
	AX.register("voice_demo", { bus = "voice", volume = 0.6 })
	AX.duck("music", "voice", { level = 0.3 })
	AX.play("musica_demo")
	AX.play("voice_demo")
	AX.patch("music", "estudio")
	AX.ambient("floresta", { ids = { "passaros", "folhas", "rio_longe" }, interval = { 10, 24 }, bus = "ambient" })
	AX._ambients.floresta:start()
	local st = AX.stats()
	ctx.lines[#ctx.lines + 1] = "audio AUX: " .. st.buses .. " buses + duck voz->musica + patch estudio + scheduler floresta ON (" .. st.sounds .. " sons)"
end

function E.anim(ctx)
	if not ArkherAnimX then
		ctx.lines[#ctx.lines + 1] = "animacao: Kit E (AAX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	ARKHER.cmd("anim.demo")
	ctx.lines[#ctx.lines + 1] = "animacao AAX: clip easeOut_spring/pingpong tocando REAL (AAX_DemoCube no workspace)"
end

function E.clima(ctx)
	if not ArkherAtmosX then
		ctx.lines[#ctx.lines + 1] = "clima: Kit E (AEX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local AEX = ArkherAtmosX
	AEX.setup({})
	local g = (ctx.goal or ""):lower()
	local w = "limpo"
	if g:find("tempest") or g:find("trov") or g:find("raio") then w = "tempestade"
	elseif g:find("chuva") or g:find("rain") then w = "chuva"
	elseif g:find("neve") or g:find("snow") then w = "neve"
	elseif g:find("neblina") or g:find("fog") then w = "neblina"
	elseif g:find("aurora") then w = "aurora"
	elseif g:find("nuvem") then w = "nuvem" end
	AEX.setWeather(w, 0.8)
	for i = 1, 60 do AEX.pump(1 / 30) end
	if g:find("noite") then AEX.setPreset("noite") elseif g:find("amanhecer") then AEX.setPreset("amanhecer") elseif g:find("entardecer") or g:find("sunset") then AEX.setPreset("entardecer") end
	local mix = AEX.weatherMix()
	ctx.lines[#ctx.lines + 1] = string.format("clima AEX: %s (fog %.0f, haze %.1f, waveBoost %.2fx) — Lighting/Atmosphere REAIS", AEX.S.state, mix.fogEnd, mix.haze, mix.waveBoost)
end

function E.camera(ctx)
	if not ArkherCameraX then
		ctx.lines[#ctx.lines + 1] = "camera: Kit E (ACX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local ACX = ArkherCameraX
	local g = (ctx.goal or ""):lower()
	if g:find("crane") then
		ACX.shot({ type = "crane", from = Vector3.new(-18, 2, 0), to = Vector3.new(18, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = 4, lift = 10 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: crane 4s (lift fisico)"
	elseif g:find("fly") or g:find("voo") then
		ACX.shot({ type = "fly", from = Vector3.new(-20, 8, -20), mid = Vector3.new(0, 16, 0), to = Vector3.new(20, 8, 20), lookAt = Vector3.new(0, 3, 0), duration = 5 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: fly path Catmull-Rom REAL (5s)"
	elseif g:find("shake") or g:find("tremor") then
		ACX.addTrauma(0.9)
		ctx.lines[#ctx.lines + 1] = "camera ACX: trauma +0.9 (shake trauma^2)"
	else
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 14, height = 6, speed = 0.6, duration = 9999 })
		ctx.lines[#ctx.lines + 1] = "camera ACX: orbit cinematografico real na CurrentCamera"
	end
end

function E.particles(ctx)
	if not ArkherParticlesX then
		ctx.lines[#ctx.lines + 1] = "particulas: Kit E (APX) nao carregado — rode ArkherKit_Installer_E"
		return
	end
	local APX = ArkherParticlesX
	local g = (ctx.goal or ""):lower()
	local k = "fogo"
	if g:find("faisca") or g:find("spark") then k = "faiscas"
	elseif g:find("magia") or g:find("magic") then k = "magia"
	elseif g:find("fumaca") or g:find("smoke") then k = "fumaca"
	elseif g:find("explosao") or g:find("explos") then k = "faiscas"
	elseif g:find("splash") or g:find("agua") then k = "agua"
	elseif g:find("neve") then k = "neve"
	elseif g:find("poeira") or g:find("dust") then k = "poeira" end
	APX.emit(nil, k)
	if g:find("explosao") or g:find("explos") then APX.emit(nil, "fumaca") end
	local bs = APX.budgetScale()
	ctx.lines[#ctx.lines + 1] = string.format("particulas APX: %s emitido (Emitter REAL, budget D-O15 %.0f%%)", k, bs * 100)
end

function E.default(ctx)
	ctx.lines[#ctx.lines + 1] = "info: objetivo nao mapeado — executei auditoria de contexto"
	E.check(ctx)
end

-- ---------- EXECUTOR ----------
function SG.run(goal, opts)
	opts = opts or {}
	ARKHER.memory = SG.memory
	SG.memory.tasks = SG.memory.tasks + 1
	local task = { id = SG.memory.tasks, goal = goal, t = tick(), status = "running" }
	SG.memory.decisions[#SG.memory.decisions + 1] = task
	local plan = SG.plan(goal)
	local lines = {}
	log("INFO", "objetivo: " .. goal)
	Bus.emit("singularity.start", { goal = goal, plan = plan })
	lines[#lines + 1] = "plano: " .. table.concat(plan.tasks, " → ")

	local t0 = tick()
	for _, name in ipairs(plan.tasks) do
		local expert = E[name] or E.default
		local ok, err = pcall(expert, { lines = lines })
		if not ok then
			lines[#lines + 1] = "ERRO em " .. name .. ": " .. tostring(err)
			task.status = "partial"
			log("ERROR", "especialista " .. name .. " falhou: " .. tostring(err))
		end
		Bus.emit("singularity.step", { task = task.id, step = name })
	end
	local dt = tick() - t0
	lines[#lines + 1] = "tempo: " .. string.format("%.2f", dt) .. "s"
	task.status = task.status or "done"
	task.dt = dt
	task.lines = lines
	Bus.emit("singularity.done", task)
	return report("Missao " .. task.id .. " concluida", lines)
end

-- ---------- PONTE EXTERNA OPCIONAL (mesmo contrato, sem obrigar servico) ----------
function SG.bridgeAvailable()
	local ep = ARKHER.STATE.ai.endpoint
	return type(ep) == "string" and #ep > 4
end

function SG.askExternal(goal)
	if not SG.bridgeAvailable() then return nil, "sem endpoint configurado" end
	local Http = game:GetService("HttpService")
	local ok, res = pcall(function()
		return Http:PostAsync(
			ARKHER.STATE.ai.endpoint,
			Http:JSONEncode({ goal = goal, context = { place = ARKHER.STATE.placeName, do15 = ARKHER.STATE.do15Level } }),
			Enum.HttpContentType.ApplicationJson,
			5
		)
	end)
	if not ok or not res then return nil, tostring(res) end
	local ok2, plan = pcall(function() return Http:JSONDecode(res) end)
	if ok2 and type(plan) == "table" then return plan end
	return nil, "resposta invalida"
end
end

do
--[[ ARKHER V3 — LIVE: Inspector (Properties) e Hierarchy ligados ao Estado REAL ]]
-- O Inspector lê a Selection real do Roblox e edita propriedades de verdade.
-- A Hierarchy espelha o DataModel real (workspace + services) com filtro.
local Players = game:GetService("Players")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

local LIVE = {}
ArkherLive = LIVE
ARKHER_LIVE = LIVE

-- ---------- widgets de inspector ----------
local function vec3box(parent, label, vec, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local vals = { vec.X, vec.Y, vec.Z }
	local boxes = {}
	for i = 1, 3 do
		local b = K.input(parent, 118 + (i - 1) * 42, y, 40, 18, "")
		b.Text = tostring(math.floor((vals[i] or 0) * 100) / 100)
		b.TextXAlignment = Enum.TextXAlignment.Center
		b.ClearTextOnFocus = true
		b.FocusLost:Connect(function()
			local n = tonumber(b.Text)
			if n then
				vals[i] = n
				if onChange then onChange(vals[1], vals[2], vals[3]) end
			else
				b.Text = tostring(vals[i])
			end
		end)
		boxes[i] = b
	end
	return boxes
end

local function numbox(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(math.floor(val * 1000) / 1000)
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		local n = tonumber(b.Text)
		if n then
			if min and n < min then n = min end
			if max and n > max then n = max end
			b.Text = tostring(n)
			if onChange then onChange(n) end
		else
			b.Text = tostring(val)
		end
	end)
	return b
end

local function slider(parent, label, val, y, onChange, min, max)
	local T, K = ARKHER.T, ARKHER.K
	min = min or 0
	max = max or 1
	K.txt(parent, label, 22, y, 84, 18, 11, T.txt3)
	local track = K.btn(parent, "Sl_" .. label, 110, y + 6, 96, 6, T.bg4, 3)
	local fill = K.f(track, "Fill", 0, 0, 0, 6, T.accent)
	K.corner(fill, 3)
	local knob = K.f(track, "Knob", 0, -3, 12, 12, T.accent2, 6)
	local label2 = K.txt(parent, "", 210, y, 40, 18, 11, T.txt, FONT, Enum.TextXAlignment.Left)
	local v = math.min(max, math.max(min, val or min))
	local function paint()
		local frac = (v - min) / (max - min)
		fill.Size = UDim2.new(0, math.floor(96 * frac), 0, 6)
		knob.Position = UDim2.new(0, math.floor(96 * frac) - 6, 0, -3)
		label2.Text = string.format("%.2f", v)
	end
	paint()
	local dragging = false
	local function setFromX(xabs)
		local rel = (xabs - track.AbsolutePosition.X) / track.AbsoluteSize.X
		v = math.min(max, math.max(min, min + rel * (max - min)))
		paint()
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(inp.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			if onChange then onChange(v) end
		end
	end)
	return track
end

local function colorbox(parent, label, col, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local sw = K.btn(parent, "Clr_" .. label, 128, y, 96, 18, col, 3)
	K.stroke(sw, T.line2, 1)
	local pal = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(227, 52, 47),
		Color3.fromRGB(255, 152, 0), Color3.fromRGB(255, 230, 0), Color3.fromRGB(102, 187, 106),
		Color3.fromRGB(41, 121, 255), Color3.fromRGB(104, 58, 183), Color3.fromRGB(255, 112, 179),
	}
	local open = false
	sw.MouseButton1Click:Connect(function()
		open = not open
		local dd = sw:FindFirstChild("Pal")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "Pal", 128, y + 20, 96, 58, T.bg2)
			p.Name = "Pal"
			K.stroke(p, T.line2, 1)
			for i, c in ipairs(pal) do
				local cb = K.btn(p, "c" .. i, 4 + ((i - 1) % 4) * 23, 4 + math.floor((i - 1) / 4) * 18, 18, 14, c, 2)
				cb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					sw.BackgroundColor3 = c
					if onChange then onChange(c) end
				end)
			end
			K.f(p, "x", 0, 0, 1, 1, T.bg2)
		end
	end)
	return sw
end

local MATERIALS = {
	"Neon", "SmoothPlastic", "Plastic", "Metal", "Wood", "WoodPlanks", "Concrete",
	"Glass", "Grass", "Slate", "Brick", "CorrodedMetal", "Foil", "Ice", "Marble",
	"MossyRock", "Sand", "Snow", "Fabric", "LeafyGrass",
}
local function materialRow(parent, label, matName, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.btn(parent, "Mat_" .. label, 128, y, 96, 18, T.bg4, 3)
	K.stroke(b, T.line2, 1)
	K.txtS(b, matName or "?", 10, T.txt)
	local open = false
	b.MouseButton1Click:Connect(function()
		open = not open
		local dd = b:FindFirstChild("MList")
		if dd then dd:Destroy() end
		if open then
			local p = K.f(parent, "MList", 128, y + 20, 100, 130, T.bg2)
			p.Name = "MList"
			K.stroke(p, T.line2, 1)
			for i, m in ipairs(MATERIALS) do
				local mb = K.btn(p, m, 3, 3 + (i - 1) * 18, 94, 16, T.bg2, 2)
				K.txtS(mb, m, 10, m == matName and T.neon or T.txt2)
				K.hover(mb, T.bg2, T.hover)
				mb.MouseButton1Click:Connect(function()
					open = false
					p:Destroy()
					b:ClearAllChildren()
					K.txtS(b, m, 10, T.txt)
					if onChange then onChange(m) end
				end)
			end
		end
	end)
	return b
end

local function check(parent, label, on, y, onChange)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 128, 18, 11, T.txt3)
	local box = K.btn(parent, "Chk_" .. label, 156, y + 2, 14, 14, T.bg4, 3)
	K.stroke(box, on and T.check or T.line2, 1)
	local inner = K.f(box, "On", 2, 2, 10, 10, T.check)
	K.corner(inner, 2)
	inner.Visible = on
	box.MouseButton1Click:Connect(function()
		on = not on
		inner.Visible = on
		K.stroke(box, on and T.check or T.line2, 1)
		if onChange then onChange(on) end
	end)
	return box
end

local function textRow(parent, label, val, y, onChange, mono)
	local T, K = ARKHER.T, ARKHER.K
	K.txt(parent, label, 22, y, 100, 18, 11, T.txt3)
	local b = K.input(parent, 128, y, 96, 18, "")
	b.Text = tostring(val or "")
	b.Font = mono and ARKHER.MONO or FONT
	b.ClearTextOnFocus = true
	b.FocusLost:Connect(function()
		if onChange then onChange(b.Text) end
	end)
	return b
end

-- ---------- INSPECTOR ----------
local BASEPART_PROPS = {
	"Position", "CFrame", "Size", "Color", "Material", "Transparency",
	"Anchored", "CanCollide", "CastShadow", "BrickColor",
}
local GUI_PROPS = { "BackgroundColor3", "BackgroundTransparency", "Size", "Position", "Text", "TextColor3", "TextSize" }

function LIVE.currentSelection()
	local ok, sel = pcall(function() return Selection:Get() end)
	if ok and type(sel) == "table" and #sel > 0 then return sel[1] end
	return nil
end

function LIVE.rebuildInspector(container)
	local T, K = ARKHER.T, ARKHER.K
	container:ClearAllChildren()
	local inst = LIVE.currentSelection()
	local head = K.f(container, "Head", 1, 0, 10, 26, T.bg3)
	head.Size = UDim2.new(1, -2, 0, 26)
	if not inst then
		K.txt(head, "Nada selecionado", 24, 0, 200, 26, 11, T.txt4)
		return
	end
	local ic = K.f(head, "Ic", 10, 4, 18, 18)
	local iconFn = LIVE.iconFor(inst)
	if iconFn then iconFn(ic, 18) end
	K.txt(head, inst.Name, 32, 0, 120, 26, 12, T.txt, ARKHER.FONTB)
	K.txt(head, inst.ClassName, 0, 0, 150, 26, 9, T.txt4)
	-- linha de classe à direita
	local clsLbl = K.txt(head, inst.ClassName, 0, 0, 110, 26, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	clsLbl.Position = UDim2.new(1, -110, 0, 0)

	local body = K.f(container, "Body", 1, 26, 10, 10, T.bg3)
	body.Size = UDim2.new(1, -2, 1, -26)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Parent = body
	scroll.Position = UDim2.new(0, 0, 0, 0)
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	local inner = K.f(scroll, "Inner", 0, 0, 10, 0, T.bg3)
	inner.Size = UDim2.new(1, -8, 0, 0)
	local y = 4

	local function push(dy)
		y = y + dy
		inner.Size = UDim2.new(1, -8, 0, y)
		scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		return y
	end

	if inst:IsA("BasePart") then
		local sec, sbody = K.section(inner, "Core Properties", true, 0)
		local sy = 0
		local function row(dy)
			sy = sy + dy
			return sy
		end
		local pos = inst.Position or Vector3.new(0, 0, 0)
		local p1 = vec3box(sbody, "Position", pos, 4, function(x, y2, z)
			pcall(function() inst.Position = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local size = inst.Size or Vector3.new(1, 1, 1)
		vec3box(sbody, "Size", size, sy + 2, function(x, y2, z)
			pcall(function() inst.Size = Vector3.new(x, y2, z) end)
		end)
		sy = row(26)
		local col = inst.Color or Color3.new(1, 1, 1)
		colorbox(sbody, "Color", col, sy + 2, function(c)
			pcall(function() inst.Color = c end)
		end)
		sy = row(24)
		local matName = "SmoothPlastic"
		pcall(function() matName = inst.Material.Name end)
		materialRow(sbody, "Material", matName, sy + 2, function(m)
			pcall(function()
				local okm, me = pcall(function() return Enum.Material[m] end)
				if okm and me then inst.Material = me end
			end)
		end)
		sy = row(24)
		local tr = inst.Transparency or 0
		slider(sbody, "Transparency", tr, sy + 2, function(v)
			pcall(function() inst.Transparency = v end)
		end)
		sy = row(26)
		check(sbody, "Anchored", inst.Anchored ~= false, sy + 2, function(v)
			pcall(function() inst.Anchored = v end)
		end)
		sy = row(22)
		check(sbody, "CanCollide", inst.CanCollide ~= false, sy + 2, function(v)
			pcall(function() inst.CanCollide = v end)
		end)
		sy = row(22)
		check(sbody, "CastShadow", inst.CastShadow ~= false, sy + 2, function(v)
			pcall(function() inst.CastShadow = v end)
		end)
		sy = row(24)
		local bh = sy + 6
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Body" then ch.Size = UDim2.new(1, 0, 0, bh) end
		end
		for _, ch in ipairs(sec:GetChildren()) do
			if ch.Name == "Head" then end
		end
		push(bh + 10)

		local sec2 = K.section(inner, "Physics", true, y + 2)
		local b2 = sec2:FindFirstChild("Body")
		local sy2 = 0
		check(b2, "CanTouch", true, 4, function() end)
		sy2 = sy2 + 22
		check(b2, "CustomPhysicalProperties", false, sy2 + 2, function() end)
		sy2 = sy2 + 22
		b2.Size = UDim2.new(1, 0, 0, sy2 + 10)
		for _, ch in ipairs(sec2:GetChildren()) do
			if ch.Name ~= "Head" and ch.Name ~= "Body" then ch.Position = UDim2.new(0, 0, 0, 0) end
		end
		push(sy2 + 34)

		local sec3, b3 = K.section(inner, "Scripting", false, y + 2)
		check(b3, "Archivable", true, 4, function() end)
		b3.Size = UDim2.new(1, 0, 0, 26)
		push(20 + 26)
	elseif inst:IsA("GuiObject") then
		local sec = K.section(inner, "Layout", true, 0)
		local b = sec:FindFirstChild("Body")
		local sy = 0
		if inst.Size then
			numbox(b, "Size.X", 0, 4, function() end)
			sy = sy + 24
		end
		local col = inst.BackgroundColor3 or Color3.new(0, 0, 0)
		colorbox(b, "BackgroundColor3", col, sy + 2, function(c)
			pcall(function() inst.BackgroundColor3 = c end)
		end)
		sy = sy + 24
		local tr = inst.BackgroundTransparency or 0
		slider(b, "BackgroundTransp.", tr, sy + 2, function(v)
			pcall(function() inst.BackgroundTransparency = v end)
		end)
		sy = sy + 26
		if inst.Text ~= nil then
			textRow(b, "Text", inst.Text, sy + 2, function(t)
				pcall(function() inst.Text = t end)
			end, true)
			sy = sy + 24
			local tc = inst.TextColor3 or Color3.new(1, 1, 1)
			colorbox(b, "TextColor3", tc, sy + 2, function(c)
				pcall(function() inst.TextColor3 = c end)
			end)
			sy = sy + 24
		end
		b.Size = UDim2.new(1, 0, 0, sy + 8)
		push(sy + 28)
	elseif inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript") then
		local sec = K.section(inner, "Code", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "Fonte do script (abrindo no Script Editor):", 22, 4, 200, 16, 10, T.txt3)
		local src = inst.Source or ""
		local preview = K.txt(b, string.sub(src, 1, 300), 22, 22, 190, 60, 9, T.txt2, ARKHER.MONO)
		preview.TextXAlignment = Enum.TextXAlignment.Left
		preview.TextYAlignment = Enum.TextYAlignment.Top
		preview.TextWrapped = true
		local ob = K.btn(b, "OpenInEditor", 22, 88, 120, 20, T.sec, 4)
		K.txtS(ob, "Abrir no Script Editor", 10, T.txt)
		K.hover(ob, T.sec, T.hover)
		ob.MouseButton1Click:Connect(function()
			ARKHER.STATE.scriptOpen = inst
			ARKHER.open("ScriptEditor")
			ARKHER.out("INFO", "Script aberto: " .. inst:GetFullName())
		end)
		b.Size = UDim2.new(1, 0, 0, 120)
		push(140)
	else
		local sec = K.section(inner, "Identity", true, 0)
		local b = sec:FindFirstChild("Body")
		K.txt(b, "FullName", 22, 4, 80, 16, 10, T.txt3)
		K.txt(b, inst:GetFullName(), 100, 4, 130, 16, 9, T.txt2, ARKHER.MONO)
		b.Size = UDim2.new(1, 0, 0, 26)
		push(40)
	end
end

-- ---------- ICONS POR CLASSE (hierarchy) ----------
local CLASS_ICON = {
	Baseplate = "plate", Part = "cubeW", Terrain = "terrain", Camera = "camera",
	Workspace = "ws", SpawnLocation = "plate", Model = "model",
	Script = "script", LocalScript = "script", ModuleScript = "script",
	Folder = "folder", Lighting = "bulb", Players = "playersI",
	MaterialService = "gem", ReplicatedFirst = "repfirst",
	ReplicatedStorage = "boxG", ServerScriptService = "cubeT", ServerStorage = "cubeT",
	StarterGui = "folderP", StarterPack = "folderP", StarterPlayer = "folderP",
	TextChatService = "chat", PointLight = "bulb", SpotLight = "bulb",
	ParticleEmitter = "particle", Sound = "music", MeshPart = "model",
}
function LIVE.iconFor(inst)
	local n = CLASS_ICON[inst.ClassName] or CLASS_ICON[inst.Name]
	if n and ICON[n] then return ICON[n] end
	if inst:IsA("BasePart") then return ICON.cubeW end
	if inst:IsA("GuiObject") then return ICON.imageI end
	if inst:IsA("Model") then return ICON.model end
	return ICON.folder
end

-- ---------- HIERARCHY ----------
local SERVICE_ROWS = {
	"Players", "Lighting", "MaterialService", "ReplicatedFirst", "ReplicatedStorage",
	"ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
	"TextChatService", "SoundService", "RunService", "Workspace",
}

function LIVE.matchFilter(inst, filter)
	if not filter or filter == "" then return true end
	local f = filter:lower()
	local nameOk = inst.Name:lower():find(f, 1, true) ~= nil
	local clsOk = inst.ClassName:lower():find(f, 1, true) ~= nil
	return nameOk or clsOk
end

local function hierarchyNode(parent, inst, depth, y, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	local kids = inst:GetChildren()
	local hasKids = #kids > 0
	local visible = LIVE.matchFilter(inst, filter) or (hasKids and false)
	-- mantém visivel se qualquer descendant casar
	if not visible and hasKids then
		local any = false
		for _, ch in ipairs(kids) do
			if LIVE.matchFilter(ch, filter) then any = true break end
		end
		visible = any
	end
	if not visible then return y end
	local row = K.treeRow(parent, depth, LIVE.iconFor(inst), inst.Name, hasKids and (state.open[inst.Name] and depth < 99 and "open" or "closed") or nil, y)
	if inst == LIVE.currentSelection() then
		row.BackgroundColor3 = T.sel
	end
	row.MouseButton1Click:Connect(function()
		local ok = pcall(function() Selection:Set({ inst }) end)
		if not ok then
			pcall(function() Selection:Set({ inst }) end)
		end
		Bus.emit("hierarchy.picked", inst)
		ARKHER.out("INFO", "Selecionado: " .. inst:GetFullName())
	end)
	y = y + 20
	if hasKids then
		local isOpen = state.open[inst.Name] ~= false and depth <= 2
		state.open[inst.Name] = isOpen
		-- chevron clicavel
		local chev = row:FindFirstChild("Chev")
		if chev then
			local cb = K.btn(row, "ChevBtn", 6 + depth * 16, 2, 14, 16, T.bg3, 2)
			cb.BackgroundColor3 = T.bg3
			if isOpen then ICON.chevD(chev, 8) else ICON.chevR(chev, 8) end
			cb.MouseButton1Click:Connect(function()
				state.open[inst.Name] = not state.open[inst.Name]
				ARKHER_LIVE.rebuildHierarchy(state.container, state.filter or "", state)
			end)
		end
		if isOpen then
			for _, ch in ipairs(kids) do
				y = hierarchyNode(parent, ch, depth + 1, y, filter, state)
			end
		end
	end
	return y
end

function LIVE.rebuildHierarchy(container, filter, state)
	local T, K = ARKHER.T, ARKHER.K
	state = state or { open = {}, filter = filter }
	state.filter = filter or ""
	if state.container ~= container then state.container = container end
	container:ClearAllChildren()
	local ws = workspace
	local y = 4
	-- raiz: Workspace
	local rootRow = K.treeRow(container, 0, ICON.ws, "Workspace", "open", y)
	rootRow.BackgroundColor3 = T.bg3
	K.stroke(rootRow, T.line, 1)
	y = y + 20
	for _, ch in ipairs(ws:GetChildren()) do
		y = hierarchyNode(container, ch, 1, y, state.filter, state)
	end
	-- services (niveis de primeira classe)
	y = y + 6
	local svcLbl = K.txt(container, "— services —", 8, y, 150, 14, 9, T.txt4)
	y = y + 16
	for _, svcName in ipairs(SERVICE_ROWS) do
		if svcName ~= "Workspace" then
			local svc = game:FindFirstChild(svcName)
			if svc and LIVE.matchFilter(svc, state.filter) then
				local r = K.treeRow(container, 0, LIVE.iconFor(svc) or ICON.server, svcName .. "+", "closed", y)
				r.BackgroundColor3 = T.bg3
				r.MouseButton1Click:Connect(function()
					pcall(function() Selection:Set({ svc }) end)
					ARKHER.out("INFO", "Serviço selecionado: " .. svcName)
				end)
				y = y + 20
			end
		end
	end
	-- auto-abre workspace
	if state.open["Workspace"] == nil then state.open["Workspace"] = true end
end

-- ---------- WIRING (SelectionChanged + Changed do seleto) ----------
function LIVE.start()
	ARKHER.out("INFO", "ArkherLive: ligando SelectionChanged/Changed")
	local function onSel()
		Bus.emit("inspector.refresh")
		Bus.emit("hierarchy.refresh")
	end
	pcall(function()
		Selection.SelectionChanged:Connect(onSel)
	end)
	-- Changed do objeto selecionado (throttled por frame)
	local dirty = false
	pcall(function()
		RunService.Heartbeat:Connect(function()
			if dirty then
				dirty = false
				Bus.emit("inspector.refresh")
			end
		end)
	end)
	local function watch(inst)
		if not inst then return end
		pcall(function()
			inst:GetPropertyChangedSignal("*"):Connect(function()
				dirty = true
			end)
		end)
	end
	pcall(function()
		Selection.SelectionChanged:Connect(function()
			local sel = LIVE.currentSelection()
			watch(sel)
		end)
	end)
end
end

do
--[[ ARKHER V3 — BOOT: inicializa os sistemas core (idempotente) ]]
function ARKHER.boot()
	if ARKHER._booted then return end
	ARKHER._booted = true
	ArkherDO15.start()
	ArkherNMN.start()
	ArkherLive.start()
	ArkherActions.registerUICommands()
	ArkherActions.startShortcuts()
	pcall(function() ArkherPlaces.refreshList() end)
	ARKHER.out("INFO", "Core boot: do15 + nmn + live + actions + places")
end
end


]====]
local rs = game:GetService("ReplicatedStorage")
local holder = rs:FindFirstChild("ArkherV3")
if not holder then
	holder = Instance.new("Folder")
	holder.Name = "ArkherV3"
	holder.Parent = rs
end
local mod = holder:FindFirstChild("ArkherKit_B")
if not mod then
	mod = Instance.new("ModuleScript")
	mod.Name = "ArkherKit_B"
	mod.Parent = holder
end
mod.Source = KIT
print("[ARKHER V3] ArkherKit_B instalado em ReplicatedStorage.ArkherV3")
