-- ARKHER Services (ModuleScript) — camada CUSTOM de persistência + dados.
-- Roda no server (ServerStorage/ArkherCloudVault/ArkherServices). Não usa require externo;
-- só services globais. Todo dado aninhado vai em atributo STRING (JSON) p/ persistir no place.
local Http = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local VAULT = "ArkherCloudVault"

local M = {}
M.SCHEMA = 1

-- ============ util ============
local function enc(v)
	local ok, s = pcall(function() return Http:JSONEncode(v) end)
	if ok and type(s) == "string" then return s end
	return "null"
end
local function dec(s)
	if type(s) ~= "string" or s == "" then return nil end
	local ok, t = pcall(function() return Http:JSONDecode(s) end)
	if ok and type(t) == "table" then return t end
	return nil
end
local function now() return os.time() end
local function dstr(t) return os.date("!%Y-%m-%d %H:%M", t or now()) end
local _seed = (os.time() % 2147483646) + 1
local _ctr = 0
local function genNum()
	local n = (_seed + _ctr) % 2147483647
	_ctr = _ctr + 1
	local out = ""
	for _ = 1, 9 do n = (n * 16807) % 2147483647 out = out .. tostring(n % 10) end
	return out
end

local vault
local function getVault()
	if vault and vault.Parent then return vault end
	vault = SS:FindFirstChild(VAULT)
	if not vault then vault = Instance.new("Folder") vault.Name = VAULT vault.Parent = SS end
	vault:SetAttribute("ArkherInternal", true)
	vault:SetAttribute("ArkherSchema", M.SCHEMA)
	local subs = { "Account", "Cloud", "Profile", "Team", "ProjectInfo", "Data", "Locales" }
	for _, n in ipairs(subs) do
		local f = vault:FindFirstChild(n)
		if not f then f = Instance.new("Folder") f.Name = n f.Parent = vault end
		f:SetAttribute("ArkherInternal", true)
	end
	local team = vault:FindFirstChild("Team")
	if not team:FindFirstChild("Invites") then local iv = Instance.new("Folder") iv.Name = "Invites" iv.Parent = team end
	return vault
end

local function owner()
	local acc = getVault():FindFirstChild("Account")
	return acc:GetAttribute("OwnerName") or "Dev"
end

local function ensureAccount()
	local v = getVault()
	local acc = v:FindFirstChild("Account")
	if not acc:GetAttribute("OwnerName") then
		acc:SetAttribute("OwnerName", "WhiteXz73_Developer")
		acc:SetAttribute("OwnerId", 1)
		acc:SetAttribute("Plan", "Creator Plus")
		acc:SetAttribute("CreatedAt", now())
	end
	local team = v:FindFirstChild("Team")
	if not team:GetAttribute("Members") then
		team:SetAttribute("Members", enc({ { name = owner(), role = "Owner", joinedAt = now(), online = true } }))
	end
end
ensureAccount()

-- ============ CONTA / STATUS ============
function M.status()
	local acc = getVault():FindFirstChild("Account")
	return {
		ready = true,
		owner = owner(),
		ownerId = acc:GetAttribute("OwnerId") or 0,
		plan = acc:GetAttribute("Plan") or "Creator",
		region = "sa-east-1",
		createdAt = dstr(acc:GetAttribute("CreatedAt")),
		projects = #M.cloudList(),
		published = #M.profileList(),
		members = #M.team().members,
	}
end

-- ============ ARKHER CLOUD (projetos) ============
local function projRecord(p)
	return {
		id = p.Name:sub(6),
		name = p:GetAttribute("Name") or p.Name,
		size = p:GetAttribute("Size") or 0,
		nodes = p:GetAttribute("Nodes") or 0,
		savedAt = dstr(p:GetAttribute("SavedAt")),
		versions = p:GetAttribute("Versions") or 1,
	}
end
function M.cloudList()
	local cloud = getVault():FindFirstChild("Cloud")
	local out = {}
	for _, p in ipairs(cloud:GetChildren()) do
		if p:IsA("Folder") and p.Name:sub(1, 5) == "proj_" then out[#out + 1] = projRecord(p) end
	end
	table.sort(out, function(a, b) return (b.savedAt or "") > (a.savedAt or "") end)
	return out
end
function M.cloudPut(name, json, size, nodes)
	local cloud = getVault():FindFirstChild("Cloud")
	local id = "proj_" .. genNum()
	local p = Instance.new("Folder")
	p.Name = id
	p:SetAttribute("ArkherInternal", true)
	p:SetAttribute("Name", name)
	p:SetAttribute("Size", size)
	p:SetAttribute("Nodes", nodes)
	p:SetAttribute("SavedAt", now())
	p:SetAttribute("Versions", 1)
	local snap = Instance.new("StringValue")
	snap.Name = "Snapshot"
	snap.Value = json
	snap.Parent = p
	p.Parent = cloud
	return projRecord(p)
end
function M.cloudGet(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then return nil end
	local snap = p:FindFirstChild("Snapshot")
	return { data = snap and snap.Value or "", record = projRecord(p) }
end
function M.cloudDelete(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then return false end
	p:Destroy()
	return true
end

-- ============ PUBLICAR (perfil do dev) ============
local function gameRecord(g)
	return {
		id = g.Name:sub(6),
		title = g:GetAttribute("Title") or g.Name,
		slug = g:GetAttribute("Slug") or "",
		url = g:GetAttribute("Url") or "",
		visits = g:GetAttribute("Visits") or 0,
		favorites = g:GetAttribute("Favorites") or 0,
		version = g:GetAttribute("Version") or 1,
		createdAt = dstr(g:GetAttribute("CreatedAt")),
		updatedAt = dstr(g:GetAttribute("UpdatedAt")),
		visibility = g:GetAttribute("Visibility") or "Public",
		genre = g:GetAttribute("Genre") or "Obstrução",
		publishedBy = g:GetAttribute("PublishedBy") or owner(),
		rating = g:GetAttribute("Rating") or 100,
	}
end
function M.profileList()
	local prof = getVault():FindFirstChild("Profile")
	local out = {}
	for _, g in ipairs(prof:GetChildren()) do
		if g:IsA("Folder") and g.Name:sub(1, 5) == "game_" then out[#out + 1] = gameRecord(g) end
	end
	table.sort(out, function(a, b) return (b.updatedAt or "") > (a.updatedAt or "") end)
	return out
end
function M.profileGet(id)
	local g = getVault():FindFirstChild("Profile"):FindFirstChild("game_" .. id)
	if not g then return nil end
	local d = g:FindFirstChild("Description")
	local r = gameRecord(g)
	r.description = d and d.Value or ""
	return r
end
function M.publish(info)
	info = info or {}
	local prof = getVault():FindFirstChild("Profile")
	local title = type(info.title) == "string" and info.title or "Meu Jogo Arkher"
	if title:match("^%s*$") then title = "Meu Jogo Arkher" end
	local slug = title:lower():gsub("[^%w]", "-"):gsub("^-+", ""):gsub("-+$", "")
	if slug == "" then slug = "jogo" end
	-- acha um game existente com o mesmo slug (re-publicar = bump versão)
	local existing
	for _, g in ipairs(prof:GetChildren()) do
		if g:IsA("Folder") and g:GetAttribute("Slug") == slug then existing = g break end
	end
	local g = existing
	if not g then
		local gid = genNum()
		g = Instance.new("Folder")
		g.Name = "game_" .. gid
		g:SetAttribute("ArkherInternal", true)
		g:SetAttribute("Title", title)
		g:SetAttribute("Slug", slug)
		g:SetAttribute("GameId", gid)
		g:SetAttribute("Url", "https://www.roblox.com/games/" .. gid .. "/" .. slug)
		g:SetAttribute("CreatedAt", now())
		g:SetAttribute("Visits", 1)
		g:SetAttribute("Favorites", 0)
		g:SetAttribute("Version", 1)
		g:SetAttribute("Rating", 100)
		g:SetAttribute("Visibility", "Public")
		g:SetAttribute("Genre", "Obstrução")
		g.Parent = prof
	else
		local ver = (g:GetAttribute("Version") or 1) + 1
		g:SetAttribute("Version", ver)
		g:SetAttribute("Visits", (g:GetAttribute("Visits") or 0) + 1)
		g:SetAttribute("Title", title)
		local gid = g:GetAttribute("GameId")
		g:SetAttribute("Url", "https://www.roblox.com/games/" .. gid .. "/" .. slug)
	end
	g:SetAttribute("UpdatedAt", now())
	g:SetAttribute("PublishedBy", owner())
	if info.visibility == "Private" or info.visibility == "Unlisted" or info.visibility == "Public" then
		g:SetAttribute("Visibility", info.visibility)
	end
	if type(info.genre) == "string" and info.genre ~= "" then
		g:SetAttribute("Genre", info.genre)
	end
	if type(info.description) == "string" then
		local d = g:FindFirstChild("Description")
		if not d then d = Instance.new("StringValue") d.Name = "Description" d.Parent = g end
		d.Value = info.description
	end
	return gameRecord(g)
end
function M.profileDelete(id)
	local g = getVault():FindFirstChild("Profile"):FindFirstChild("game_" .. id)
	if not g then return false end
	g:Destroy()
	return true
end

-- ============ DADOS (custom DataStore) ============
local function dataEntry(key)
	local data = getVault():FindFirstChild("Data")
	local e = data:FindFirstChild(key)
	if not e then return nil end
	local vt = e:GetAttribute("Type") or "string"
	local val = e:GetAttribute("Value")
	return { key = key, type = vt, value = val, updatedAt = dstr(e:GetAttribute("UpdatedAt")) }
end
function M.dataList()
	local data = getVault():FindFirstChild("Data")
	local out = {}
	for _, e in ipairs(data:GetChildren()) do out[#out + 1] = dataEntry(e.Name) end
	return out
end
function M.dataSet(key, value, vt)
	assert(type(key) == "string" and #key > 0 and #key <= 60, "Chave inválida.")
	assert(not key:match("[/%?%*%:<>%|%\"\\]"), "Chave com caractere inválido.")
	vt = vt or (type(value) == "number" and "number" or (type(value) == "boolean" and "boolean" or "string"))
	assert(vt == "string" or vt == "number" or vt == "boolean", "Tipo inválido.")
	if vt == "number" then value = tonumber(value); assert(value, "Número inválido.") end
	if vt == "boolean" then value = value == true end
	if vt == "string" then value = tostring(value) assert(#value <= 4000, "Valor muito longo.") end
	local data = getVault():FindFirstChild("Data")
	local e = data:FindFirstChild(key)
	if not e then e = Instance.new("Folder") e.Name = key e:SetAttribute("ArkherInternal", true) e.Parent = data end
	e:SetAttribute("Type", vt)
	e:SetAttribute("Value", value)
	e:SetAttribute("UpdatedAt", now())
	return dataEntry(key)
end
function M.dataGet(key)
	return dataEntry(key)
end
function M.dataDelete(key)
	local e = getVault():FindFirstChild("Data"):FindFirstChild(key)
	if not e then return false end
	e:Destroy()
	return true
end

-- ============ PROJETO (metadados) ============
local INFO_FIELDS = { "GameName", "Description", "Genre", "Visibility", "MaxPlayers", "StreamingEnabled", "PhysicsEnabled" }
function M.projectInfo()
	local pi = getVault():FindFirstChild("ProjectInfo")
	local out = {}
	for _, f in ipairs(INFO_FIELDS) do
		local v = pi:GetAttribute(f)
		if v ~= nil then out[f] = v end
	end
	if not out.GameName then out.GameName = "" end
	out.Visibility = out.Visibility or "Public"
	out.Genre = out.Genre or "Obstrução"
	out.MaxPlayers = out.MaxPlayers or 50
	return out
end
function M.setProjectInfo(fields)
	fields = fields or {}
	local pi = getVault():FindFirstChild("ProjectInfo")
	local changed = {}
	for _, f in ipairs(INFO_FIELDS) do
		local v = fields[f]
		if v ~= nil then
			if f == "GameName" or f == "Description" or f == "Genre" then v = tostring(v) end
			if f == "MaxPlayers" then v = math.clamp(math.floor(tonumber(v) or 50), 1, 1000) end
			if f == "StreamingEnabled" or f == "PhysicsEnabled" then v = v == true end
			pi:SetAttribute(f, v)
			changed[f] = v
		end
	end
	return M.projectInfo()
end

-- ============ COLABORAÇÃO (equipe + convites) ============
local ROLES = { Owner = true, Editor = true, Viewer = true }
function M.team()
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	local me = owner()
	if #members == 0 then
		members = { { name = me, role = "Owner", joinedAt = now(), online = true } }
		team:SetAttribute("Members", enc(members))
	end
	return { members = members, owner = me, count = #members }
end
function M.teamAdd(name, role)
	if not ROLES[role] or role == "Owner" then role = "Editor" end
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	for _, m in ipairs(members) do if m.name == name then return M.team() end end
	members[#members + 1] = { name = tostring(name), role = role, joinedAt = now(), online = true }
	team:SetAttribute("Members", enc(members))
	return M.team()
end
function M.teamRemove(name)
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	local out = {}
	for _, m in ipairs(members) do
		if m.name == name then
			if m.role == "Owner" then return M.team() end
		else out[#out + 1] = m end
	end
	team:SetAttribute("Members", enc(out))
	return M.team()
end
function M.inviteList()
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	local out = {}
	for _, e in ipairs(iv:GetChildren()) do
		out[#out + 1] = {
			code = e:GetAttribute("Code") or "",
			email = e:GetAttribute("Email") or "",
			role = e:GetAttribute("Role") or "Editor",
			status = e:GetAttribute("Status") or "pending",
			by = e:GetAttribute("By") or owner(),
			createdAt = dstr(e:GetAttribute("CreatedAt")),
			link = "arkher.dev/j/" .. (e:GetAttribute("Code") or ""),
		}
	end
	return out
end
function M.inviteCreate(email, role)
	if not ROLES[role] or role == "Owner" then role = "Editor" end
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	local code = genNum():sub(1, 8):upper()
	local e = Instance.new("Folder")
	e.Name = "inv_" .. os.time() .. "_" .. code
	e:SetAttribute("ArkherInternal", true)
	e:SetAttribute("Code", code)
	e:SetAttribute("Email", tostring(email))
	e:SetAttribute("Role", role)
	e:SetAttribute("Status", "pending")
	e:SetAttribute("By", owner())
	e:SetAttribute("CreatedAt", now())
	e.Parent = iv
	return { code = code, role = role, email = email, link = "arkher.dev/j/" .. code }
end
local function findInvite(code)
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	for _, e in ipairs(iv:GetChildren()) do
		if (e:GetAttribute("Code") or "") == code then return e end
	end
	return nil
end
function M.inviteAccept(code)
	local e = findInvite(code)
	if not e then return { error = "Convite não encontrado." } end
	local email = e:GetAttribute("Email")
	local name = email and email:match("^(%S+)@") or "Convidado"
	local role = e:GetAttribute("Role") or "Editor"
	e:SetAttribute("Status", "accepted")
	local t = M.teamAdd(name, role)
	return { ok = true, member = name, team = t }
end
function M.inviteReject(code)
	local e = findInvite(code)
	if not e then return { error = "Convite não encontrado." } end
	e:SetAttribute("Status", "rejected")
	return { ok = true }
end

-- ============ LOCALIZAÇÃO (i18n) ============
local LOCALES = {
	{ code = "pt-BR", name = "Português (Brasil)" },
	{ code = "en", name = "English" },
	{ code = "es", name = "Español" },
	{ code = "fr", name = "Français" },
	{ code = "de", name = "Deutsch" },
	{ code = "ja", name = "日本語" },
}
function M.locales()
	local loc = getVault():FindFirstChild("Locales")
	local cur = loc:GetAttribute("Current") or "pt-BR"
	return { current = cur, available = LOCALES }
end
function M.setLocale(code)
	local ok = false
	for _, l in ipairs(LOCALES) do if l.code == code then ok = true break end end
	assert(ok, "Idioma inválido.")
	local loc = getVault():FindFirstChild("Locales")
	loc:SetAttribute("Current", code)
	return M.locales()
end
function M.strings()
	local loc = getVault():FindFirstChild("Locales")
	local list = dec(loc:GetAttribute("Strings")) or {}
	if #list == 0 then
		list = {
			{ key = "Greeting", value = "Bem-vindo ao jogo!", translations = { ["pt-BR"] = "Bem-vindo ao jogo!", en = "Welcome to the game!", es = "¡Bienvenido al juego!" } },
			{ key = "PlayButton", value = "Jogar", translations = { ["pt-BR"] = "Jogar", en = "Play", es = "Jugar" } },
			{ key = "GameOver", value = "Fim de jogo", translations = { ["pt-BR"] = "Fim de jogo", en = "Game over", es = "Fin del juego" } },
		}
		loc:SetAttribute("Strings", enc(list))
	end
	local cur = loc:GetAttribute("Current") or "pt-BR"
	for _, s in ipairs(list) do s.resolved = (s.translations and s.translations[cur]) or s.value end
	return { strings = list, current = cur }
end
function M.setString(key, value, translations)
	assert(type(key) == "string" and #key > 0 and #key <= 80, "Chave inválida.")
	local loc = getVault():FindFirstChild("Locales")
	local list = dec(loc:GetAttribute("Strings")) or {}
	local found = false
	for _, s in ipairs(list) do
		if s.key == key then
			s.value = tostring(value)
			if type(translations) == "table" then for k, v in pairs(translations) do s.translations[k] = tostring(v) end end
			found = true
		end
	end
	if not found then
		local tr = {}
		tr["pt-BR"] = tostring(value)
		if type(translations) == "table" then for k, v in pairs(translations) do tr[k] = tostring(v) end end
		list[#list + 1] = { key = key, value = tostring(value), translations = tr }
	end
	loc:SetAttribute("Strings", enc(list))
	return M.strings()
end

-- ============ TOOLBOX (biblioteca de templates) ============
local TOOLBOX = {
	category = "Geometria",
	items = {
		{ id = "tb_platform", name = "Plataforma", description = "Plataforma 8x0.5x8.", icon = "Part", nodes = { { class = "Part", name = "Plataforma", size = { 8, 0.5, 8 }, color = { 120, 160, 220 }, pos = { 0, 0, 0 } } } },
		{ id = "tb_wall", name = "Muralha", description = "Parede 12x6x0.5.", icon = "Part", nodes = { { class = "Part", name = "Muralha", size = { 12, 6, 0.5 }, color = { 90, 95, 110 }, pos = { 0, 3, 0 } } } },
		{ id = "tb_bridge", name = "Ponte", description = "Duas torres + tábua.", icon = "Model", nodes = { { class = "Model", name = "Ponte", pos = { 0, 0, 0 } }, { class = "Part", name = "TorreEsq", size = { 1, 4, 1 }, color = { 200, 180, 90 }, pos = { -4, 2, 0 } }, { class = "Part", name = "TorreDir", size = { 1, 4, 1 }, color = { 200, 180, 90 }, pos = { 4, 2, 0 } }, { class = "Part", name = "Tabua", size = { 9, 0.3, 2 }, color = { 150, 110, 70 }, pos = { 0, 4, 0 } } } },
	},
}
local TOOLBOX_LIST = {
	TOOLBOX,
	{
		category = "Iluminação",
		items = {
			{ id = "tb_spot", name = "Palco com luz", description = "Palco + SpotLight.", icon = "Stage", nodes = { { class = "Part", name = "Palco", size = { 10, 0.5, 10 }, color = { 40, 44, 60 }, pos = { 0, 0, 0 } }, { class = "SpotLight", name = "Luz", pos = { 0, 6, 0 } } } },
			{ id = "tb_point", name = "Luz pontual", description = "Ponto com luz laranja.", icon = "Stage", nodes = { { class = "Part", name = "Ponto", size = { 1, 1, 1 }, color = { 240, 150, 60 }, pos = { 0, 2, 0 } }, { class = "PointLight", name = "PointLight", pos = { 0, 0, 0 } } } },
		},
	},
	{
		category = "Jogo",
		items = {
			{ id = "tb_collectible", name = "Moeda", description = "Moeda giratória (Part).", icon = "Coin", nodes = { { class = "Part", name = "Moeda", size = { 1, 0.2, 1 }, color = { 245, 205, 66 }, mat = "Neon", pos = { 0, 2, 0 } } } },
			{ id = "tb_checkpoint", name = "Checkpoint", description = "Coluna de checkpoint.", icon = "Flag", nodes = { { class = "Part", name = "Checkpoint", size = { 2, 6, 2 }, color = { 90, 220, 130 }, pos = { 0, 3, 0 } } } },
			{ id = "tb_killbricks", name = "Ladrilhos", description = "Plataforma de eliminação.", icon = "Hazard", nodes = { { class = "Part", name = "Ladrilhos", size = { 10, 0.5, 10 }, color = { 180, 60, 60 }, mat = "Neon", pos = { 0, 0, 0 } } } },
		},
	},
	{
		category = "Scripts",
		items = {
			{ id = "tb_counter", name = "Contador", description = "Peça + Script que conta toques.", icon = "Script", nodes = { { class = "Part", name = "BotaoContador", size = { 2, 2, 2 }, color = { 120, 160, 220 }, pos = { 0, 2, 0 } } } },
		},
	},
}
function M.toolboxList()
	return { categories = TOOLBOX_LIST }
end
function M.toolboxGet(id)
	for _, cat in ipairs(TOOLBOX_LIST) do
		for _, it in ipairs(cat.items) do
			if it.id == id then return it end
		end
	end
	return nil
end

return M
