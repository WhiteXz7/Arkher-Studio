--[[ ARKHER V3 — PUBLISH: publicar SEM Open Cloud API ]]
-- Pipeline: bundle do place → manifest (nome/desc/icone/genre/tags) → destino:
--   1) ARKHER CLOUD: endpoint HTTP proprio do usuario (Settings > Cloud). POST JSON.
--      Sem API key do Roblox, sem Open Cloud, sem JWT enterprise.
--   2) LOCAL: bundle em disco (game.WriteFile) quando no Studio.
--   3) CLIPBOARD: bundle copiado (qualquer ambiente).
--   4) ROBLOX NATIVO: prepara tudo e delega o publish ao proprio Studio (o unico
--      caminho oficial do lugar) — o ARKHER nao reinventa a conta do usuario.
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local PUB = {}
ArkherPublish = PUB

local function cloudRoot()
	local root = ServerStorage:FindFirstChild("ArkherCloud")
	if not root then
		root = Instance.new("Folder")
		root.Name = "ArkherCloud"
		root.Parent = ServerStorage
	end
	return root
end
local function pubFolder()
	local f = cloudRoot():FindFirstChild("Published")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Published"
		f.Parent = cloudRoot()
	end
	return f
end

function PUB.manifest(extra)
	extra = extra or {}
	local desc = extra.description or ("Place criado no ARKHER Studio — " .. (ARKHER.STATE.placeName or "sem nome"))
	return {
		schema = "arkher.place/v3",
		name = extra.name or ARKHER.STATE.placeName or "Untitled",
		description = desc,
		genre = extra.genre or "Roleplay",
		tags = extra.tags or { "arkher", "studio" },
		icon = extra.icon or nil,
		created = os.date and os.date("%Y-%m-%dT%H:%M:%S") or tostring(tick()),
		placeId = ARKHER.STATE.placeId,
		do15 = ARKHER.STATE.do15Level,
		by = extra.by or "ArkherStudio",
	}
end

function PUB.toLocal()
	local ok, bundle = pcall(function() return ArkherPlaces.exportBundle() end)
	if not ok or not bundle then
		ARKHER.out("ERROR", "Publish: nao foi possivel gerar o bundle")
		return false
	end
	local name = (ARKHER.STATE.placeName or "place"):gsub("[^%w%-_ ]", "")
	local f = pubFolder():FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = pubFolder()
	end
	local sv = f:FindFirstChild("bundle")
	if not sv then
		sv = Instance.new("StringValue")
		sv.Name = "bundle"
		sv.Parent = f
	end
	sv.Value = bundle
	local mf = f:FindFirstChild("manifest")
	if not mf then
		mf = Instance.new("StringValue")
		mf.Name = "manifest"
		mf.Parent = f
	end
	mf.Value = HttpService:JSONEncode(PUB.manifest())
	-- tenta tambem gravar em disco (no Studio)
	pcall(function()
		if game.WriteFile then
			game:WriteFile("ArkherPublished/" .. name .. ".arkher.lua", bundle)
		end
	end)
	ARKHER.out("SUCCESS", "Publicado no Arkher Cloud local: " .. name)
	Bus.emit("publish.local", { name = name, bytes = #bundle })
	return true
end

function PUB.toEndpoint()
	local ep = ARKHER.STATE.cloud.endpoint
	if not ep or #ep < 5 then
		ARKHER.out("WARNING", "Publish: configure o endpoint do Arkher Cloud em Settings > Cloud")
		return false
	end
	local ok, bundle = pcall(function() return ArkherPlaces.exportBundle() end)
	if not ok or not bundle then
		ARKHER.out("ERROR", "Publish: bundle falhou")
		return false
	end
	local payload = HttpService:JSONEncode({
		manifest = PUB.manifest(),
		bundle = bundle,
	})
	local ok2, res = pcall(function()
		return HttpService:PostAsync(ep, payload, Enum.HttpContentType.ApplicationJson, 20)
	end)
	if ok2 then
		ARKHER.out("SUCCESS", "Publicado no Arkher Cloud (" .. ep .. ") — resposta: " .. tostring(res))
		Bus.emit("publish.cloud", { endpoint = ep })
		return true
	end
	ARKHER.out("ERROR", "Publish cloud falhou: " .. tostring(res))
	return false
end

function PUB.toRobloxNative()
	-- prepara o native publish do Studio: nome/descricao ja estao no place;
	-- o usuario confirma no dialog oficial (a unica forma legita de publicar num lugar).
	local name = ARKHER.STATE.placeName or "Untitled"
	ARKHER.out("INFO", "Publicar no Roblox: abra FILE > Publish to Roblox no Studio — ARKHER ja preparou o name '" .. name .. "'.")
	Bus.emit("publish.native", { name = name })
	return true
end

function PUB.history()
	local out = {}
	for _, f in ipairs(pubFolder():GetChildren()) do
		local mf = f:FindFirstChild("manifest")
		local info = { name = f.Name }
		if mf then
			local ok, m = pcall(function() return HttpService:JSONDecode(mf.Value) end)
			if ok and type(m) == "table" then info = m end
		end
		out[#out + 1] = info
	end
	return out
end
