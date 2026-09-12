#!/usr/bin/env python3
"""Gera studio-completo/scripts/server.lua a partir do server original,
inserindo novos handlers (blocos multilinha) sem alterar a logica original."""

ORIG = open("studio-completo/scripts/server.orig.lua", encoding="utf-8").read()


def replace_once(src, old, new, tag):
    assert src.count(old) == 1, f"{tag}: achou {src.count(old)}x de {old[:60]!r}"
    return src.replace(old, new)


# ================= BLOCO A: historia + clipboard (declaracoes) =================
MARK_A = "local subscribed,selected,created,buckets,transactions,locks={},{},{},{},{},{}local dirty,removed={},{}"
BLOCK_A = """
local hist = {}
local clip = {}
local HIST_MAX = 50

local function histCleanup(e)
    if e and e.cleanup then pcall(e.cleanup) end
end

local function pushHist(player, entry)
    local h = hist[player] or { undo = {}, redo = {} }
    hist[player] = h
    table.insert(h.undo, entry)
    if #h.undo > HIST_MAX then histCleanup(table.remove(h.undo, 1)) end
    h.redo = {}
end

local function clearHist(player)
    local h = hist[player]
    if not h then return end
    for _, e in ipairs(h.undo) do histCleanup(e) end
    for _, e in ipairs(h.redo) do histCleanup(e) end
    h.undo = {}
    h.redo = {}
end
"""

# ================= BLOCO B: serialize / deserialize =================
SER_DESER = """
local function serializeTree(o, depth)
    depth = depth or 0
    if depth > 40 or not inspectable(o) then return nil end
    local t = { c = o.ClassName, n = o.Name }
    local p = {}
    if o:IsA("BasePart") and not o:IsA("Terrain") then
        local cf = o.CFrame
        local rx, ry, rz = cf:ToEulerAnglesYXZ()
        p.pos = cf.Position
        p.rot = Vector3.new(rx, ry, rz)
        p.size = o.Size
        p.color = o.Color
        p.trans = o.Transparency
        p.mat = o.Material.Name
        p.anchor = o.Anchored
        p.cc = o.CanCollide
        p.ct = o.CanTouch
        p.cq = o.CanQuery
        p.cs = o.CastShadow
        p.locked = o.Locked
        p.reflect = o.Reflectance
    end
    if o.ClassName == "Model" then
        p.pivot = o:GetPivot().Position
        p.scale = o:GetScale()
        if o.PrimaryPart then p.primary = o.PrimaryPart.Name end
    end
    if o:IsA("GuiObject") then
        p.pos2 = o.Position
        p.size2 = o.Size
        p.bg = o.BackgroundColor3
        p.bgt = o.BackgroundTransparency
        p.active = o.Active
    end
    if o:IsA("TextLabel") then
        p.text = o.Text
        p.tcolor = o.TextColor3
        p.tsize = o.TextSize
    end
    if o:IsA("BaseScript") then
        p.source = o.Source
        p.enabled = o.Enabled
    end
    if o:IsA("ValueBase") then p.value = o.Value end
    if o:IsA("Sound") then
        p.soundId = o.SoundId
        p.vol = o.Volume
        p.looped = o.Looped
        p.speed = o.PlaybackSpeed
    end
    for k, v in pairs(o:GetAttributes()) do p["@" .. k] = v end
    if next(p) then t.p = p end
    local kids = {}
    for _, c in ipairs(o:GetChildren()) do
        local s = serializeTree(c, depth + 1)
        if s then kids[#kids + 1] = s end
    end
    if #kids > 0 then t.k = kids end
    return t
end

local function countTree(t)
    local n = 1
    for _, c in ipairs(t.k or {}) do n = n + countTree(c) end
    return n
end

local function deserializeTree(parent, t)
    assert(type(t) == "table" and type(t.c) == "string", "Nó inválido.")
    assert(byClass[t.c], "Classe não permitida na importação: " .. tostring(t.c))
    local o = Instance.new(t.c)
    pcall(function() o.Name = (type(t.n) == "string" and #t.n > 0) and t.n or t.c end)
    local pr = t.p or {}
    if o:IsA("BasePart") then
        if pr.size then o.Size = pr.size end
        if pr.color then o.Color = pr.color end
        if pr.trans then o.Transparency = pr.trans end
        if pr.mat then pcall(function() o.Material = Enum.Material[pr.mat] end) end
        if pr.anchor ~= nil then o.Anchored = pr.anchor end
        if pr.cc ~= nil then o.CanCollide = pr.cc end
        if pr.ct ~= nil then o.CanTouch = pr.ct end
        if pr.cq ~= nil then o.CanQuery = pr.cq end
        if pr.cs ~= nil then o.CastShadow = pr.cs end
        if pr.locked ~= nil then o.Locked = pr.locked end
        if pr.pos then
            o.CFrame = CFrame.fromEulerAnglesYXZ((pr.rot and pr.rot.X) or 0, (pr.rot and pr.rot.Y) or 0, (pr.rot and pr.rot.Z) or 0) * CFrame.new(pr.pos)
        end
    end
    if o.ClassName == "Model" then
        if pr.scale then pcall(function() o:ScaleTo(pr.scale) end) end
    end
    if o:IsA("GuiObject") then
        if pr.pos2 then o.Position = pr.pos2 end
        if pr.size2 then o.Size = pr.size2 end
        if pr.bg then o.BackgroundColor3 = pr.bg end
        if pr.bgt then o.BackgroundTransparency = pr.bgt end
        if pr.active ~= nil then o.Active = pr.active end
    end
    if o:IsA("TextLabel") then
        if pr.text then o.Text = pr.text end
        if pr.tcolor then o.TextColor3 = pr.tcolor end
        if pr.tsize then o.TextSize = pr.tsize end
    end
    if o:IsA("BaseScript") then
        if pr.source then o.Source = pr.source end
        if pr.enabled ~= nil then o.Enabled = pr.enabled end
    end
    if o:IsA("Sound") then
        if pr.soundId then o.SoundId = pr.soundId end
        if pr.vol then o.Volume = pr.vol end
        if pr.looped ~= nil then o.Looped = pr.looped end
        if pr.speed then o.PlaybackSpeed = pr.speed end
    end
    if o:IsA("ValueBase") then
        if pr.value ~= nil then pcall(function() o.Value = pr.value end) end
    end
    for k, v in pairs(pr) do
        if type(k) == "string" and k:sub(1, 1) == "@" then pcall(function() o:SetAttribute(k:sub(2), v) end) end
    end
    o.Parent = parent
    for _, c in ipairs(t.k or {}) do deserializeTree(o, c) end
    return o
end
"""

# ================= BLOCO C: ops de historia + template =================
HIST_OPS = """
local function hCreate(player, o)
    local saved = o:Clone()
    local parent = o.Parent
    local name0 = o.Name
    local live = o
    pushHist(player, {
        label = "Criar " .. o.Name,
        cleanup = function() if saved and not saved.Parent then saved:Destroy() end end,
        undo = function() if live and live.Parent then live:Destroy() end end,
        redo = function() local n = saved:Clone(); n.Name = name0; n.Parent = parent; live = n end,
    })
end

local function hDelete(player, o)
    local saved = o:Clone()
    local parent = o.Parent
    local name0 = o.Name
    local live = o
    pushHist(player, {
        label = "Excluir " .. o.Name,
        cleanup = function() if saved and not saved.Parent then saved:Destroy() end end,
        undo = function() local n = saved:Clone(); n.Name = name0; n.Parent = parent; live = n end,
        redo = function() if live and live.Parent then live:Destroy() end end,
    })
end

local function hSet(player, o, key, oldVal, newVal)
    pushHist(player, {
        label = "Editar " .. key .. " de " .. o.Name,
        undo = function() pcall(function() o[key] = oldVal end) queueObject(o) end,
        redo = function() pcall(function() o[key] = newVal end) queueObject(o) end,
    })
end

local function hTransform(player, o, fCf, fSize, fScale, tCf, tSize, tScale)
    local function apply(cf, sz, sc)
        if not o.Parent then return end
        pcall(function()
            setPivot(o, cf)
            if sz and o:IsA("BasePart") then o.Size = sz elseif sc and o.ClassName == "Model" then o:ScaleTo(sc) end
        end)
        queueObject(o)
    end
    pushHist(player, {
        label = "Transformar " .. o.Name,
        undo = function() apply(fCf, fSize, fScale) end,
        redo = function() apply(tCf, tSize, tScale) end,
    })
end

local function wipeWorkspace()
    for _, c in ipairs(workspace:GetChildren()) do
        if not rootSet[c] and editable(c) and not containsProtected(c) then pcall(function() c:Destroy() end) end
    end
end

local function buildTemplate(kind)
    wipeWorkspace()
    if kind == "Baseplate" or kind == "Flat" then
        local bp = Instance.new("Part")
        bp.Name = "Baseplate"
        bp.Size = Vector3.new(512, 1, 512)
        bp.CFrame = CFrame.new(0, -0.5, 0)
        bp.Anchored = true
        bp.CanCollide = true
        bp.Color = Color3.fromRGB(94, 142, 190)
        bp.Material = kind == "Flat" and Enum.Material.SmoothPlastic or Enum.Material.Concrete
        bp.Parent = workspace
        return bp
    end
    if kind == "Terrain" then
        local ok, t = pcall(function()
            local ter = Instance.new("Terrain")
            ter.Parent = workspace
            return ter
        end)
        if ok and t then return t end
    end
    return nil
end
"""

# ================= BLOCO D: novos handlers =================
NEW_HANDLERS = """
function handlers.Undo(player)
    local h = hist[player]
    assert(h and #h.undo > 0, "Nada para desfazer.")
    local e = table.remove(h.undo)
    local ok, err = pcall(e.undo)
    table.insert(h.redo, e)
    if not ok then return { error = "Falha ao desfazer: " .. tostring(err) } end
    return { label = e.label }
end

function handlers.Redo(player)
    local h = hist[player]
    assert(h and #h.redo > 0, "Nada para refazer.")
    local e = table.remove(h.redo)
    local ok, err = pcall(e.redo)
    table.insert(h.undo, e)
    if not ok then return { error = "Falha ao refazer: " .. tostring(err) } end
    return { label = e.label }
end

function handlers.GetHistory(player)
    local h = hist[player] or { undo = {}, redo = {} }
    local u = {}
    for i = 1, #h.undo do u[#u + 1] = h.undo[i].label end
    local r = {}
    for i = 1, #h.redo do r[#r + 1] = h.redo[i].label end
    return { undo = u, redo = r, canUndo = #h.undo > 0, canRedo = #h.redo > 0 }
end

function handlers.Copy(player, payload)
    local o = getObject(payload.id)
    assert(inspectable(o), "Objeto indisponível.")
    local clone = o:Clone()
    if clip[player] then pcall(function() clip[player].inst:Destroy() end) end
    clip[player] = { inst = clone, label = o.Name }
    return { label = o.Name, count = #(o:GetDescendants()) + 1 }
end

function handlers.Delete_(player, payload)
    local o = getObject(payload.id)
    assert(editable(o) and not rootSet[o] and not containsProtected(o), "Este objeto não pode ser excluído.")
    assert(not conflictingLock(o, player), "Objeto ou descendente em edição por outro usuário.")
    release(player, true)
    local id = idOf[o]
    hDelete(player, o)
    o:Destroy()
    unregister(o)
    selected[player] = nil
    return { removed = id }
end

function handlers.Cut(player, payload)
    handlers.Copy(player, payload)
    return handlers.Delete_(player, payload)
end

function handlers.Paste(player, payload)
    local cb = clip[player]
    assert(cb, "Nada para colar. Use Copiar ou Duplicar antes.")
    local parent = workspace
    if payload.parentId and objects[payload.parentId] then parent = objects[payload.parentId] end
    if not (parent == workspace or parent:IsA("Folder") or parent.ClassName == "Model" or parent:IsA("BasePart") or parent:IsA("GuiObject") or parent:IsA("LayerCollector")) then
        parent = workspace
    end
    local inst = cb.inst:Clone()
    local base = inst.Name
    local unique, index = base, 1
    while parent:FindFirstChild(unique) do unique = base .. " " .. index; index = index + 1 end
    inst.Name = unique
    created[player] = (created[player] or 0) + 1
    inst.Parent = parent
    register(inst)
    selected[player] = inst
    hCreate(player, inst)
    return { node = record(inst), properties = properties(inst), parentId = idOf[parent] }
end

function handlers.Duplicate(player, payload)
    handlers.Copy(player, payload)
    return handlers.Paste(player, payload)
end

function handlers.Rename(player, payload)
    local o = getObject(payload.id)
    assert(editable(o) and not rootSet[o], "Objeto somente leitura.")
    assert(type(payload.name) == "string" and #payload.name > 0 and #payload.name <= 100 and not payload.name:match("^%s*$"), "Nome inválido.")
    local old = o.Name
    o.Name = payload.name
    queueObject(o)
    pushHist(player, {
        label = "Renomear " .. old .. " → " .. o.Name,
        undo = function() o.Name = old; queueObject(o) end,
        redo = function() o.Name = payload.name; queueObject(o) end,
    })
    return { node = record(o) }
end

function handlers.New(player)
    release(player, true)
    wipeWorkspace()
    clearHist(player)
    if clip[player] then pcall(function() clip[player].inst:Destroy() end) clip[player] = nil end
    local bp = buildTemplate("Baseplate")
    if bp then register(bp) end
    return { message = "Projeto novo criado." }
end

function handlers.Open(player, payload)
    release(player, true)
    local kind = payload.template or "Baseplate"
    assert(kind == "Empty" or kind == "Baseplate" or kind == "Flat" or kind == "Terrain", "Template inválido.")
    clearHist(player)
    local root = buildTemplate(kind)
    if root then register(root) end
    return { message = "Template aplicado: " .. kind }
end

function handlers.Export(player)
    local data = serializeTree(workspace)
    return { data = data, nodes = countTree(data) }
end

function handlers.Import(player, payload)
    assert(type(payload.data) == "table" and type(payload.data.c) == "string", "Dados de importação inválidos.")
    local n = countTree(payload.data)
    assert(n <= CONFIG.MAX_CREATED_PER_SESSION, "Importação excede o limite de objetos.")
    local root = deserializeTree(workspace, payload.data)
    register(root)
    selected[player] = root
    return { created = n, root = record(root) }
end

"""

# ================= BLOCO S: ARKHER SERVICES (custom cloud/publish/data/i18n/toolbox/collab) =================
MODULE_SRC = open("studio-completo/scripts/modules/arkher_services.lua", encoding="utf-8").read()
assert "]]" not in MODULE_SRC, "fonte do module tem ']]' (quebraria [[...]])"

BLOCK_S = '''
-- ============ ARKHER SERVICES (custom: cloud, publicar, dados, i18n, toolbox, colaboracao) ============
-- Camada "custom" que contorna a Cloud API / Open API reais: persiste no place (ServerStorage)
-- como vault, e "publica" o jogo no perfil do dev (cartao estilo pagina do jogo do Roblox).
local _SS = game:GetService("ServerStorage")
local services = nil
local servicesError = ""
do
	-- FIX (round 10): NADA de escrever Source em runtime (isso é level
	-- PluginOrOpenCloud e berrava "cannot write 'Source'" TODA HORA).
	-- O module agora é EMBUTIDO INLINE como função — roda direto, sem require.
	local vault = _SS:FindFirstChild("ArkherCloudVault")
	if not vault then vault = Instance.new("Folder") vault.Name = "ArkherCloudVault" vault.Parent = _SS end
	vault:SetAttribute("ArkherInternal", true)
	local okMod, mod = pcall(function()
		return (function()
__MODULE__
		end)()
	end)
	if okMod and type(mod) == "table" then services = mod else servicesError = tostring(mod) end
end
local function needSvc()
	assert(services, "Arkher Services indisponiveis: " .. servicesError)
	return services
end

local function buildToolboxTemplate(player, parent, tpl)
	local items = {}
	local function addNode(node, nodeParent)
		local o = create(player, nodeParent, node.class, node.name)
		if node.size and o:IsA("BasePart") then pcall(function() o.Size = Vector3.new(node.size[1], node.size[2], node.size[3]) end) end
		if node.color then pcall(function() o.Color = Color3.fromRGB(node.color[1], node.color[2], node.color[3]) end) end
		if node.mat then pcall(function() o.Material = Enum.Material[node.mat] end) end
		if node.pos and o:IsA("BasePart") then pcall(function() o.CFrame = CFrame.new(node.pos[1], node.pos[2], node.pos[3]) end) end
		items[#items + 1] = { o = o, parent = nodeParent, name = node.name }
		return o
	end
	local root = addNode(tpl.nodes[1], parent)
	for i = 2, #tpl.nodes do
		local np = (tpl.nodes[1].class == "Model") and root or parent
		addNode(tpl.nodes[i], np)
	end
	local saved = {}
	for _, it in ipairs(items) do saved[#saved + 1] = { it.o:Clone(), it.parent, it.name } end
	pushHist(player, {
		label = "Inserir " .. tpl.name .. " (Toolbox)",
		cleanup = function() for _, s in ipairs(saved) do if s[1] and not s[1].Parent then s[1]:Destroy() end end end,
		undo = function() for _, it in ipairs(items) do if it.o.Parent then it.o:Destroy() end unregister(it.o) end end,
		redo = function() for _, s in ipairs(saved) do if not s[1].Parent then local n = s[1]:Clone() n.Name = s[3] n.Parent = s[2] register(n) end end end,
	})
	selected[player] = root
	queueObject(parent)
	return { node = record(root), count = #items }
end

function handlers.CloudStatus(player) needSvc() return services.status() end
function handlers.CloudList(player) needSvc() return { projects = services.cloudList() } end
function handlers.CloudSave(player, payload)
	needSvc()
	local name = (type(payload.name) == "string" and payload.name ~= "") and payload.name or ("Projeto " .. os.date("%d/%m/%Y %H:%M"))
	local data = serializeTree(workspace)
	local n = countTree(data)
	local json = Http:JSONEncode(data)
	local rec = services.cloudPut(name, json, #json, n)
	return { project = rec }
end
function handlers.CloudOpen(player, payload)
	needSvc()
	local got = services.cloudGet(payload.id)
	assert(got, "Projeto nao encontrado na cloud.")
	release(player, true)
	wipeWorkspace()
	local data = Http:JSONDecode(got.data)
	assert(data and data.c, "Snapshot invalido.")
	-- se a raiz do snapshot eh o Workspace/DataModel, importa os filhos (nao recria a raiz)
	local rootsToImport = {}
	if data.c == "Workspace" or data.c == "DataModel" then
		for _, c in ipairs(data.k or {}) do rootsToImport[#rootsToImport + 1] = c end
	else
		rootsToImport[#rootsToImport + 1] = data
	end
	local n = 0
	for _, r in ipairs(rootsToImport) do n = n + countTree(r) end
	assert(n <= CONFIG.MAX_CREATED_PER_SESSION, "Snapshot excede o limite de objetos.")
	local last
	for _, r in ipairs(rootsToImport) do last = deserializeTree(workspace, r) end
	if last then register(last) selected[player] = last end
	return { opened = got.record.name, nodes = n }
end
function handlers.CloudDelete(player, payload)
	needSvc()
	local ok = services.cloudDelete(payload.id)
	assert(ok, "Projeto nao encontrado.")
	return { deleted = payload.id }
end
function handlers.Publish(player, payload)
	needSvc()
	local info = payload or {}
	local data = serializeTree(workspace)
	local rec = services.publish(info)
	rec.workspaceNodes = countTree(data)
	return { game = rec }
end
function handlers.ProfileList(player) needSvc() return { games = services.profileList() } end
function handlers.ProfileGet(player, payload) needSvc() local g = services.profileGet(payload.id) assert(g, "Jogo nao encontrado.") return { game = g } end
function handlers.ProfileDelete(player, payload) needSvc() assert(services.profileDelete(payload.id), "Jogo nao encontrado.") return { deleted = payload.id } end
function handlers.DataList(player) needSvc() return { entries = services.dataList() } end
function handlers.DataGet(player, payload) needSvc() local e = services.dataGet(payload.key) assert(e, "Chave nao encontrada.") return { entry = e } end
function handlers.DataSet(player, payload) needSvc() return { entry = services.dataSet(payload.key, payload.value, payload.type) } end
function handlers.DataDelete(player, payload) needSvc() assert(services.dataDelete(payload.key), "Chave nao encontrada.") return { deleted = payload.key } end
function handlers.ProjectInfo(player) needSvc() return { info = services.projectInfo() } end
function handlers.SetProjectInfo(player, payload) needSvc() return { info = services.setProjectInfo(payload or {}) } end
function handlers.TeamInfo(player) needSvc() return services.team() end
function handlers.TeamAdd(player, payload) needSvc() assert(type(payload.name) == "string" and #payload.name > 0, "Nome invalido.") return services.teamAdd(payload.name, payload.role or "Editor") end
function handlers.TeamRemove(player, payload) needSvc() return services.teamRemove(payload.name) end
function handlers.InviteList(player) needSvc() return { invites = services.inviteList() } end
function handlers.InviteCreate(player, payload) needSvc() assert(type(payload.email) == "string" and payload.email:match("@"), "E-mail invalido.") return { invite = services.inviteCreate(payload.email, payload.role or "Editor") } end
function handlers.InviteAccept(player, payload) needSvc() local r = services.inviteAccept(payload.code) assert(r.ok ~= false, r.error or "Convite invalido.") return r end
function handlers.InviteReject(player, payload) needSvc() local r = services.inviteReject(payload.code) assert(r.ok ~= false, r.error or "Convite invalido.") return r end
function handlers.Locales(player) needSvc() return services.locales() end
function handlers.SetLocale(player, payload) needSvc() return services.setLocale(payload.code) end
function handlers.LocStrings(player) needSvc() return services.strings() end
function handlers.SetLocString(player, payload) needSvc() return services.setString(payload.key, payload.value, payload.translations) end
function handlers.ToolboxList(player) needSvc() return services.toolboxList() end
function handlers.ToolboxInsert(player, payload)
	needSvc()
	local tpl = services.toolboxGet(payload.id)
	if tpl then
		local parent = workspace
		if payload.parentId and objects[payload.parentId] then parent = objects[payload.parentId] end
		assert(editable(parent), "Pai invalido para este template.")
		return buildToolboxTemplate(player, parent, tpl)
	end
	-- fallback REAL (ROUND 11): id numerico = asset da Creator Store -> InsertService:LoadAsset no SERVIDOR
	local aid = tonumber(payload.id)
	assert(aid, "Template nao encontrado.")
	local okA, asset = pcall(function()
		return game:GetService("InsertService"):LoadAsset(aid)
	end)
	if not okA then
		return { error = "Creator Store recusou o asset " .. tostring(aid) .. ": " .. tostring(asset) .. " (só funciona com o jogo publicado/online)." }
	end
	assert(asset, "Asset vazio.")
	if payload.x or payload.y or payload.z then
		pcall(function()
			if asset:IsA("Model") then asset:PivotTo(CFrame.new(payload.x or 0, payload.y or 4, payload.z or -14)) end
		end)
	end
	asset.Parent = workspace
	local n2 = 0
	pcall(function() register(asset) n2 = n2 + 1 end)
	for _, d2 in ipairs(asset:GetDescendants()) do
		if n2 > 400 then break end
		local okR = pcall(function() if inspectable(d2) then register(d2) n2 = n2 + 1 end end)
		if not okR then break end
	end
	selected[player] = asset
	pcall(function() hCreate(player, asset) end)
	return { msg = "Asset " .. tostring(aid) .. " INSERIDO no mundo (" .. tostring(asset.Name) .. ", " .. tostring(n2) .. " objeto(s)) — selecionado no editor." }
end
'''
BLOCK_S = BLOCK_S.replace("__MODULE__", MODULE_SRC)

BLOCK_X7 = r'''
-- ============ BLOCK_X7 (ROUND 7): propriedades EXAUSTIVAS + toolbox REAL + places ============
-- Mapa de propriedades por IsA-chain. kind: string,number,boolean,vector,color,brick,enum,cframe,source
local PROPSPEC = {
	{ isa = "SpawnLocation", props = {
		{"Transform",{"Neutral","boolean"},{"ForceField","number",0,600}},
		{"Appearance",{"TeamColor","brick"},{"AllowTeamChangeOnTouch","boolean"}},
	} },
	{ isa = "TrussPart", props = { {"Behavior",{"Style","enum:TrussStyle"}} } },
	{ isa = "CornerWedgePart", props = {} },
	{ isa = "WedgePart", props = {} },
	{ isa = "Terrain", props = {
		{"Water",{"WaterColor","color"},{"WaterTransparency","number",0,1},{"WaterReflectance","number",0,1},{"WaterWaveSize","number",0,1},{"WaterWaveSpeed","number",0,100}},
		{"Terrain",{"Decoration","boolean"}},
	} },
	{ isa = "Part", props = {
		{"Shape",{"Shape","enum:PartType"}},
		{"Surface",{"TopSurface","enum:SurfaceType"},{"BottomSurface","enum:SurfaceType"},{"LeftSurface","enum:SurfaceType"},{"RightSurface","enum:SurfaceType"},{"FrontSurface","enum:SurfaceType"},{"BackSurface","enum:SurfaceType"}},
	} },
	{ isa = "BasePart", props = {
		{"Transform",{"Position","vector",-1000000,1000000},{"Orientation","vector",-360,360},{"Size","vector",0.05,2048}},
		{"Appearance",{"Color","color"},{"Transparency","number",0,1},{"Reflectance","number",0,1},{"Material","enum:Material"},{"CastShadow","boolean"}},
		{"Data",{"Anchored","boolean"},{"Locked","boolean"},{"Massless","boolean"}},
		{"Collision",{"CanCollide","boolean"},{"CanTouch","boolean"},{"CanQuery","boolean"},{"CollisionGroupId","number",0,256},{"AssemblyMass","number",0,1000000}},
		{"Physics",{"CustomPhysicalPropertiesDensity","number",0.01,100},{"Friction","number",0,2},{"Elasticity","number",0,1},{"FrictionWeight","number",0,100},{"ElasticityWeight","number",0,100}},
	} },
	{ isa = "Model", props = {
		{"Data",{"PrimaryPart","string"}},
		{"Streaming",{"LevelOfDetail","enum:ModelLevelOfDetail"}},
	} },
	{ isa = "Humanoid", props = {
		{"State",{"Health","number",0,100000},{"MaxHealth","number",1,100000},{"WalkSpeed","number",0,1000},{"JumpPower","number",0,1000},{"JumpHeight","number",0,1000}},
		{"Behavior",{"HipHeight","number",-8,100},{"MaxSlopeAngle","number",0,89},{"AutoRotate","boolean"}},
	} },
	{ isa = "ScreenGui", props = {
		{"Data",{"Enabled","boolean"},{"DisplayOrder","number",0,1000},{"IgnoreGuiInset","boolean"},{"ResetOnSpawn","boolean"},{"ZIndexBehavior","enum:ZIndexBehavior"}},
	} },
	{ isa = "ScrollingFrame", props = {
		{"Scroll",{"CanvasSize","udim2"},{"ScrollBarThickness","number",0,32},{"ScrollingDirection","enum:ScrollingDirection"},{"AutomaticCanvasSize","enum:AutomaticSize"}},
	} },
	{ isa = "TextBox", props = {
		{"Behavior",{"ClearTextOnFocus","boolean"},{"MultiLine","boolean"},{"PlaceholderText","string"}},
	} },
	{ isa = "TextButton", props = { {"Behavior",{"AutoButtonColor","boolean"},{"Modal","boolean"},{"Selected","boolean"}} } },
	{ isa = "ImageButton", props = {} },
	{ isa = "ImageLabel", props = {
		{"Image",{"Image","string"},{"ImageColor3","color"},{"ImageTransparency","number",0,1},{"ScaleType","enum:ScaleType"},{"TileSize","udim2"}},
	} },
	{ isa = "TextLabel", props = {
		{"Text",{"Text","string"},{"TextColor3","color"},{"TextSize","number",4,96},{"Font","enum:Font"},{"TextScaled","boolean"},{"TextWrapped","boolean"},{"TextTransparency","number",0,1},{"TextStrokeTransparency","number",0,1},{"TextXAlignment","enum:TextXAlignment"},{"TextYAlignment","enum:TextYAlignment"},{"BackgroundColor3","color"},{"BackgroundTransparency","number",0,1}},
	} },
	{ isa = "GuiObject", props = {
		{"Layout",{"Position","udim2"},{"Size","udim2"},{"AnchorPoint","vector2"},{"Rotation","number",-360,360},{"ZIndex","number",-999,999},{"LayoutOrder","number",-99999,99999}},
		{"Appearance",{"BackgroundColor3","color"},{"BackgroundTransparency","number",0,1},{"BorderSizePixel","number",0,32},{"Visible","boolean"},{"ClipsDescendants","boolean"}},
		{"Input",{"Active","boolean"},{"Selectable","boolean"}},
	} },
	{ isa = "UICorner", props = { {"Corner",{"CornerRadius","udim"}} } },
	{ isa = "UIStroke", props = {
		{"Stroke",{"Color","color"},{"Thickness","number",0,64},{"Transparency","number",0,1},{"ApplyStrokeMode","enum:ApplyStrokeMode"},{"LineJoinMode","enum:LineJoinMode"}},
	} },
	{ isa = "UIGradient", props = { {"Gradient",{"Rotation","number",-360,360},{"Enabled","boolean"},{"Color","string"},{"Transparency","string"}} } },
	{ isa = "UIPadding", props = { {"Padding",{"PaddingTop","udim"},{"PaddingBottom","udim"},{"PaddingLeft","udim"},{"PaddingRight","udim"}} } },
	{ isa = "UIListLayout", props = {
		{"Layout",{"FillDirection","enum:FillDirection"},{"HorizontalAlignment","enum:HorizontalAlignment"},{"VerticalAlignment","enum:VerticalAlignment"},{"SortOrder","enum:SortOrder"},{"Padding","udim"}},
	} },
	{ isa = "UIGridLayout", props = { {"Layout",{"CellSize","udim2"},{"CellPadding","udim2"},{"FillDirection","enum:FillDirection"},{"SortOrder","enum:SortOrder"}} } },
	{ isa = "UIAspectRatioConstraint", props = { {"Constraint",{"AspectRatio","number",0.01,100},{"AspectType","enum:AspectType"},{"DominantAxis","enum:DominantAxis"}} } },
	{ isa = "Decal", props = { {"Texture",{"Texture","string"},{"Color3","color"},{"Transparency","number",0,1},{"Face","enum:NormalId"}} } },
	{ isa = "Texture", props = { {"Texture",{"StudsPerTileU","number",0.05,64},{"StudsPerTileV","number",0.05,64}} } },
	{ isa = "SurfaceLight", props = { {"Surface",{"Face","enum:NormalId"}} } },
	{ isa = "SpotLight", props = { {"Light",{"Angle","number",1,180},{"Face","enum:NormalId"}} } },
	{ isa = "PointLight", props = {
		{"Light",{"Brightness","number",0,40},{"Range","number",0,60},{"Color","color"},{"Enabled","boolean"},{"Shadows","boolean"}},
	} },
	{ isa = "ParticleEmitter", props = {
		{"Emission",{"Rate","number",0,50000},{"Lifetime","number",0.05,60},{"Speed","number",0,5000},{"SpreadAngle","vector2"}},
		{"Particle",{"Color","color"},{"Size","string"},{"Transparency","number",0,1},{"Rotation","number",-360,360},{"RotSpeed","vector2"}},
		{"Physics",{"Acceleration","vector"},{"Drag","number",0,10},{"VelocityInheritance","number",-1,1},{"LockedToPart","boolean"}},
		{"Data",{"Enabled","boolean"},{"LightEmission","number",0,1},{"LightInfluence","number",0,1}},
	} },
	{ isa = "Fire", props = { {"Fire",{"Color","color"},{"SecondaryColor","color"},{"Size","number",1,60},{"Heat","number",1,25},{"Enabled","boolean"}} } },
	{ isa = "Smoke", props = { {"Smoke",{"Color","color"},{"Size","number",0.1,100},{"Opacity","number",0,1},{"RiseVelocity","number",-25,25},{"Enabled","boolean"}} } },
	{ isa = "Sparkles", props = { {"Sparkles",{"SparkleColor","color"},{"Enabled","boolean"}} } },
	{ isa = "Sound", props = {
		{"Sound",{"SoundId","string"},{"Volume","number",0,10},{"PlaybackSpeed","number",0,20},{"Looped","boolean"},{"Playing","boolean"},{"RollOffMaxDistance","number",0,100000},{"RollOffMinDistance","number",0,100000}},
	} },
	{ isa = "ClickDetector", props = { {"Data",{"MaxActivationDistance","number",0,64},{"MaxActivationDistance","number"}} } },
	{ isa = "ProximityPrompt", props = {
		{"Prompt",{"ActionText","string"},{"ObjectText","string"},{"HoldDuration","number",0,30},{"MaxActivationDistance","number",0,50},{"Enabled","boolean"},{"RequiresLineOfSight","boolean"}},
	} },
	{ isa = "Tool", props = { {"Tool",{"RequiresHandle","boolean"},{"Enabled","boolean"}} } },
	{ isa = "Attachment", props = { {"Transform",{"Position","vector"},{"Orientation","vector"}} } },
	{ isa = "BoolValue", props = { {"Value",{"Value","boolean"}} } },
	{ isa = "IntValue", props = { {"Value",{"Value","number"}} } },
	{ isa = "NumberValue", props = { {"Value",{"Value","number"}} } },
	{ isa = "StringValue", props = { {"Value",{"Value","string"}} } },
	{ isa = "Vector3Value", props = { {"Value",{"Value","vector"}} } },
	{ isa = "Color3Value", props = { {"Value",{"Value","color"}} } },
	{ isa = "ObjectValue", props = { {"Value",{"Value","string"}} } },
	{ isa = "Script", props = { {"Script",{"Source","source"},{"Disabled","boolean"}} } },
	{ isa = "LocalScript", props = { {"Script",{"Source","source"},{"Disabled","boolean"}} } },
	{ isa = "ModuleScript", props = { {"Script",{"Source","source"}} } },
	{ isa = "Camera", props = { {"Camera",{"FieldOfView","number",1,120},{"CameraType","enum:CameraType"}} } },
	{ isa = "Lighting", props = {
		{"Atmosphere",{"Ambient","color"},{"OutdoorAmbient","color"},{"Brightness","number",0,10},{"ClockTime","number",0,24},{"GeographicLatitude","number",-90,90},{"TimeOfDay","string"}},
		{"Shadow",{"GlobalShadows","boolean"},{"FogColor","color"},{"FogStart","number",0,100000},{"FogEnd","number",0,100000}},
	} },
	{ isa = "Workspace", props = { {"World",{"Gravity","number",0,10000},{"GlobalWind","vector"},{"StreamingEnabled","boolean"}} } },
	{ isa = "Folder", props = {} },
}
local PROPSPEC_BASE = {
	{"Data",{"Name","string"},{"Archivable","boolean"}},
}

local function specFor(o)
	local out = {}
	for _, g in ipairs(PROPSPEC_BASE) do out[#out + 1] = g end
	for _, entry in ipairs(PROPSPEC) do
		if o:IsA(entry.isa) then
			for _, g in ipairs(entry.props) do out[#out + 1] = g end
		end
	end
	return out
end

local function readAny(o, key, kind)
	local ok, v = pcall(function() return o[key] end)
	if not ok or v == nil then return nil end
	if kind == "vector" and typeof(v) == "Vector3" then return { x = v.X, y = v.Y, z = v.Z } end
	if kind == "vector2" and typeof(v) == "Vector2" then return { x = v.X, y = v.Y } end
	if kind == "color" and typeof(v) == "Color3" then return { r = v.R, g = v.G, b = v.B } end
	if kind == "brick" and typeof(v) == "BrickColor" then return { brick = v.Name } end
	if kind == "cframe" and typeof(v) == "CFrame" then local c = v:GetComponents() return { x = c[1], y = c[2], z = c[3] } end
	if kind == "udim" and typeof(v) == "UDim" then return { scale = v.Scale, offset = v.Offset } end
	if kind == "udim2" and typeof(v) == "UDim2" then return { xs = v.X.Scale, xo = v.X.Offset, ys = v.Y.Scale, yo = v.Y.Offset } end
	if kind == "enum" and typeof(v) == "EnumItem" then return { enum = v.Name } end
	if kind == "source" and type(v) == "string" then return { s = v } end
	if type(v) == "string" then return { s = v:sub(1, 512) } end
	if type(v) == "number" or type(v) == "boolean" then return { v = v } end
	return nil
end

local function enumListFor(key)
	local map = {
		PartType = Enum.PartType, Material = Enum.Material, SurfaceType = Enum.SurfaceType,
		TrussStyle = Enum.TrussStyle, Font = Enum.Font, NormalId = Enum.NormalId,
		TextXAlignment = Enum.TextXAlignment, TextYAlignment = Enum.TextYAlignment,
		ScaleType = Enum.ScaleType, FillDirection = Enum.FillDirection,
		HorizontalAlignment = Enum.HorizontalAlignment, VerticalAlignment = Enum.VerticalAlignment,
		SortOrder = Enum.SortOrder, ZIndexBehavior = Enum.ZIndexBehavior,
		ScrollingDirection = Enum.ScrollingDirection, AutomaticSize = Enum.AutomaticSize,
		ApplyStrokeMode = Enum.ApplyStrokeMode, LineJoinMode = Enum.LineJoinMode,
		AspectType = Enum.AspectType, DominantAxis = Enum.DominantAxis,
		ModelLevelOfDetail = Enum.ModelLevelOfDetail, CameraType = Enum.CameraType,
	}
	local et = map[key]
	if not et then return nil end
	local out = {}
	for _, it in ipairs(et:GetEnumItems()) do out[#out + 1] = it.Name end
	table.sort(out)
	return out
end

function handlers.SelectedGet(player)
	local o = selected[player]
	if not o or not o.Parent then return { none = true, msg = "Nada selecionado — clique num objeto no EXPLORADOR." } end
	return { id = idOf[o], className = o.ClassName, name = o.Name, path = o:GetFullName() }
end

function handlers.PropsAll(player, payload)
	local o = getObject(payload.id)
	assert(o, "Objeto invalido.")
	local write = editable(o)
	local fields = {}
	for _, g in ipairs(specFor(o)) do
		local group = g[1]
		for i = 2, #g do
			local spec = g[i]
			local key, kind = spec[1], spec[2]
			local enumType = kind:match("^enum:(%w+)$")
			local k = enumType and "enum" or kind
			local val = readAny(o, key, k)
			if val then
				fields[#fields + 1] = {
					group = group, key = key, kind = k,
					enumType = enumType, enum = enumType and enumListFor(enumType) or nil,
					v = val, editable = write,
					min = spec[3], max = spec[4],
				}
			end
		end
	end
	table.sort(fields, function(a, b) return (a.group == b.group) and (a.key < b.key) or (a.group < b.group) end)
	return { fields = fields, className = o.ClassName, name = o.Name, writable = write }
end

function handlers.PropsSet(player, payload)
	local o = getObject(payload.id)
	assert(editable(o), "Objeto somente leitura.")
	assert(type(payload.key) == "string" and #payload.key < 80, "Propriedade invalida.")
	local kind = tostring(payload.kind or "string")
	local val
	if kind == "number" then
		assert(finite(payload.v), "Numero invalido.") val = payload.v
	elseif kind == "boolean" then
		val = payload.v == true
	elseif kind == "string" or kind == "source" then
		assert(type(payload.s) == "string" and #payload.s < 200000, "Texto invalido.") val = payload.s
	elseif kind == "vector" then
		val = Vector3.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0, tonumber(payload.z) or 0)
	elseif kind == "vector2" then
		val = Vector2.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0)
	elseif kind == "color" then
		val = Color3.new(math.clamp(tonumber(payload.r) or 0, 0, 1), math.clamp(tonumber(payload.g) or 0, 0, 1), math.clamp(tonumber(payload.b) or 0, 0, 1))
	elseif kind == "brick" then
		assert(type(payload.brick) == "string", "BrickColor invalido.")
		local bok, bv = pcall(function() return BrickColor.new(payload.brick) end)
		assert(bok and bv, "BrickColor desconhecido: " .. tostring(payload.brick)) val = bv
	elseif kind == "enum" then
		assert(type(payload.enum) == "string", "Enum invalido.")
		local cur = o[payload.key]
		assert(typeof(cur) == "EnumItem", "Sem enum atual para casar.")
		local found
		for _, it in ipairs(Enum[cur.EnumType]:GetEnumItems()) do
			if it.Name:lower() == payload.enum:lower() then found = it break end
		end
		assert(found, "EnumItem invalido: " .. payload.enum) val = found
	elseif kind == "udim" then
		val = UDim.new(tonumber(payload.scale) or 0, tonumber(payload.offset) or 0)
	elseif kind == "udim2" then
		val = UDim2.new(tonumber(payload.xs) or 0, tonumber(payload.xo) or 0, tonumber(payload.ys) or 0, tonumber(payload.yo) or 0)
	elseif kind == "cframe" then
		local cur = o[payload.key]
		val = CFrame.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0, tonumber(payload.z) or 0) * (cur and (cur - cur.Position) or CFrame.new())
	else
		error("Kind desconhecido: " .. kind)
	end
	local old = readAny(o, payload.key, kind)
	local ok, err = pcall(function() o[payload.key] = val end)
	assert(ok, "Roblox recusou: " .. tostring(err))
	local new = readAny(o, payload.key, kind)
	if old ~= new then hSet(player, o, payload.key, old, new) end
	return { node = record(o), ok = true, applied = payload.key }
end

function handlers.QuickPart(player, payload)
	local shapes = { Block = "Block", Ball = "Ball", Cylinder = "Cylinder", CylinderVertical = "CylinderVertical", Wedge = "WedgePart", CornerWedge = "CornerWedgePart", Truss = "TrussPart" }
	local shape = tostring(payload.shape or "Block")
	assert(shapes[shape], "Forma invalida: " .. shape)
	local cls = shapes[shape]
	local parent = workspace
	if payload.parentId and objects[payload.parentId] then
		local p = objects[payload.parentId]
		if editable(p) then parent = p end
	end
	local nm = tostring(payload.name or (shape .. "_ArkherStock"))
	if cls == "WedgePart" or cls == "CornerWedgePart" or cls == "TrussPart" then
		local inst = Instance.new(cls)
		inst.Size = Vector3.new(4, 2, 4)
		inst.CFrame = CFrame.new(payload.x or 0, payload.y or 3, payload.z or -16)
		inst.Anchored = true
		inst.Color = Color3.fromRGB(120, 160, 220)
		inst.Parent = parent
		inst.Name = nm
		register(inst) created[inst] = true
		selected[player] = inst
		hCreate(player, inst)
		return { id = idOf[inst], className = cls, msg = cls .. " '" .. nm .. "' criado (classe real, sempre com pivô garantido)" }
	end
	local p2 = Instance.new("Part")
	p2.Shape = Enum.PartType[cls]
	p2.Size = (cls == "Ball") and Vector3.new(4, 4, 4) or (cls:find("Cylinder") and Vector3.new(2, 4, 4) or Vector3.new(4, 2, 4))
	p2.CFrame = CFrame.new(payload.x or 0, payload.y or 3, payload.z or -16)
	p2.Anchored = true
	p2.Color = Color3.fromRGB(120, 160, 220)
	p2.Parent = parent
	p2.Name = nm
	register(p2) created[p2] = true
	selected[player] = p2
	hCreate(player, p2)
	return { id = idOf[p2], className = "Part", shape = cls, msg = "Part " .. cls .. " '" .. nm .. "' criado (Shape real + Register do histórico)" }
end

function handlers.ToolboxSearch(player, payload)
	local q = tostring(payload.query or ""):sub(1, 120)
	assert(#q > 0, "Digite o que buscar na TOOLBOX (creator store real).")
	local kindS = tostring(payload.kind or "models")
	local page = math.clamp(tonumber(payload.page) or 0, 0, 99)
	local ok, page2 = pcall(function()
		local pageObj
		if kindS == "decals" then
			pageObj = game:GetService("InsertService"):GetFreeDecalsAsync(q, page)
		else
			pageObj = game:GetService("InsertService"):GetFreeModelsAsync(q, page)
		end
		return pageObj
	end)
	if not ok then
		return { error = "Creator Store indisponível nesta sessão (Roblox recusou a busca): " .. tostring(page2) }
	end
	local items = {}
	local results = page2.Results or {}
	for i = 1, math.min(#results, 24) do
		local it = results[i]
		items[#items + 1] = { name = it.Name, id = it.AssetId, creator = it.Creator, icon = it.IconUrl, trusted = it.IsEndorsed }
	end
	return { items = items, total = page2.TotalCount or #items, page = page, kind = kindS, query = q }
end

function handlers.ToolboxAssetInsert(player, payload)
	local id = tonumber(payload.assetId)
	assert(id and id > 0, "AssetId invalido.")
	local parent = workspace
	if payload.parentId and objects[payload.parentId] then
		local p = objects[payload.parentId]
		if editable(p) then parent = p end
	end
	local ok, model = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	assert(ok, "LoadAsset falhou (asset privado/protegido?): " .. tostring(model))
	assert(model, "Asset vazio.")
	local NM = #model:GetChildren()
	model.Name = "Asset_" .. id
	model.Parent = parent
	register(model) created[model] = true
	selected[player] = model
	hCreate(player, model)
	-- marca no ouvinte para o cliente reposicionar
	return { id = idOf[model], nodes = NM, msg = ("Asset %d inserido (%d filhos) — Creator Store REAL"):format(id, NM) }
end

function handlers.PlaceCreate(player, payload)
	local name = tostring(payload.name or ""):sub(1, 80)
	assert(#name > 2, "Nome muito curto para a place.")
	local template = tonumber(payload.template) or 9544032260 -- baseplate do Roblox
	local desc = tostring(payload.description or "Criado com Arkher Studio") or ""
	local ok, ret = pcall(function()
		return game:GetService("AssetService"):CreatePlaceAsync(name, template, desc)
	end)
	if not ok then
		local msg = tostring(ret)
		return { error = "CreatePlaceAsync recusou (" .. msg .. "). Só funciona em jogo publicado online com permissão de criação de place ativa." }
	end
	return { placeId = ret, msg = "PLACE CRIADA no seu perfil: id " .. tostring(ret) .. "  — abra em roblox.com/games/" .. tostring(ret) }
end
'''


# ================= aplicar =================
src = ORIG
BLOCK_X8 = r'''
-- ============ BLOCK_X8: SCRIPTS (listar p/ o SCRIPT EDITOR X) ============
function handlers.ScriptList(player, payload)
	local out = {}
	local roots = {
		workspace,
		game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ReplicatedFirst"),
		game:GetService("StarterPlayer"),
		game:GetService("StarterPack"),
		game:GetService("StarterGui"),
	}
	local seen = {}
	local function walk(o, depth)
		if depth > 30 or hidden(o) then return end
		if o:IsA("LuaSourceContainer") and not seen[o] then
			seen[o] = true
			local len2 = 0
			pcall(function() len2 = #o.Source end)
			out[#out + 1] = {
				id = idOf[o] or 0, className = o.ClassName, name = o.Name,
				path = o:GetFullName(), len = len2,
			}
		end
		for _, c in ipairs(o:GetChildren()) do
			if not hidden(c) then walk(c, depth + 1) end
		end
	end
	for _, r in ipairs(roots) do walk(r, 0) end
	table.sort(out, function(a, b) return a.path < b.path end)
	return { scripts = out, count = #out }
end
'''

BLOCK_X9 = r'''
-- ============ BLOCK_X9: PYBRIDGE via SERVIDOR (HttpService so roda server-side) ============
local PY_URL = "http://127.0.0.1:8773"
local function pyGet(path2)
	local ok2, res = pcall(function()
		return Http:GetAsync(PY_URL .. path2, true)
	end)
	if not ok2 then
		return nil, ("python bridge/offline OU HttpService desligado: ligar em Game Settings > Security > HTTP Requests. Detalhe: %s"):format(tostring(res))
	end
	local ok3, data = pcall(function() return Http:JSONDecode(res) end)
	if not ok3 then return nil, "resposta nao-JSON do python bridge" end
	return data
end

function handlers.PyStatus(player)
	local data, err = pyGet("/status")
	if not data then return { online = false, error = err } end
	return { online = data.ok == true, py = data.py, cwd = data.cwd, tasks = data.tasks, version = data.version }
end

function handlers.PyRun(player, payload)
	local task = tostring(payload.task or "")
	local arg = tostring(payload.arg or "")
	local enc = (task == "shell") and ("?task=shell&arg=" .. Http:UrlEncode(arg)) or ("?task=" .. Http:UrlEncode(task))
	local data, err = pyGet("/run" .. enc)
	if not data then return { ok = false, error = err } end
	return { ok = data.ok == true, summary = data.summary, error = data.error, out = data.out }
end
'''

BLOCK_X10 = r'''
-- ============ BLOCK_X10 (ROUND 10): CSG real + SCULPT + CollisionGroups + Presence + Plugins ============
local TERRAIN = workspace:FindFirstChildOfClass("Terrain")
local function partSnap(o)
    return {
        class = o.ClassName, cf = o.CFrame, size = o.Size, color = o.Color,
        mat = o.Material.Name, trans = o.Transparency, shape = (o:IsA("Part") and o.Shape.Name or nil),
        name = o.Name, anchored = o.Anchored,
    }
end
local function partRestore(snap, parent)
    local cls = snap.class
    if cls == "WedgePart" or cls == "CornerWedgePart" or cls == "TrussPart" or cls == "Part" or cls == "MeshPart" then
        local o2 = Instance.new(cls == "MeshPart" and "Part" or cls)
        o2.Name = snap.name
        o2.CFrame = snap.cf
        o2.Size = snap.size
        pcall(function() o2.Color = snap.color end)
        pcall(function() o2.Material = snap.mat end)
        pcall(function() o2.Transparency = snap.trans end)
        if snap.shape then pcall(function() o2.Shape = Enum.PartType[snap.shape] end) end
        o2.Anchored = snap.anchored
        o2.Parent = parent
        register(o2) created[o2] = true
        return o2
    end
    return nil
end

function handlers.CsgDo(player, payload)
    local op = tostring(payload.op or "union")
    assert(op == "union" or op == "negate", "op deve ser 'union' ou 'negate'")
    local main
    if payload.mainId then main = getObject(payload.mainId) end
    if not main then main = selected[player] end
    assert(main and main:IsA("BasePart") and not main:IsA("Terrain"), "Selecione a PEÇA principal (BasePart) primeiro.")
    assert(editable(main), "Peça principal somente leitura.")
    -- outra: ids explicitos ou a peça valida mais proxima da main (escopo 80 studs)
    local others = {}
    if type(payload.otherIds) == "table" then
        for _, id2 in ipairs(payload.otherIds) do
            local o = getObject(id2)
            if o and o:IsA("BasePart") and not o:IsA("Terrain") and editable(o) and o ~= main then
                others[#others + 1] = o
            end
        end
    else
        local best, bd = nil, 80
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and not o:IsA("Terrain") and o ~= main and editable(o) and not o:IsDescendantOf(main) then
                local d2 = (o.Position - main.Position).Magnitude
                if d2 < bd then best, bd = o, d2 end
            end
        end
        if best then others[#others + 1] = best end
    end
    assert(#others > 0, "Sem segunda peça: selecione uma peça PERTO do alvo (até 80 studs) ou passe otherIds.")
    local other = others[1]
    local snapMain, snapOther = partSnap(main), partSnap(other)
    local parent = main.Parent
    local ok2, resultPart = pcall(function()
        if op == "union" then return main:UnionAsync({ other }) end
        return main:SubtractAsync({ other })
    end)
    assert(ok2 and resultPart, op .. "Async recusou: " .. tostring(resultPart))
    -- herda o visual da main
    pcall(function() resultPart.Color = main.Color end)
    pcall(function() resultPart.Material = main.Material end)
    pcall(function() resultPart.Transparency = main.Transparency end)
    resultPart.Name = main.Name .. "_" .. op:upper()
    resultPart.Anchored = main.Anchored
    resultPart.Parent = parent
    register(resultPart) created[resultPart] = true
    -- remove as duas originais
    local mId, oId = idOf[main], idOf[other]
    selected[player] = resultPart
    main:Destroy() other:Destroy()
    unregister(main) unregister(other)
    -- histórico real: undo recria as duas; redo refaz a operação
    pushHist(player, {
        label = "CSG " .. op .. " (" .. snapMain.name .. " × " .. snapOther.name .. ")",
        undo = function()
            if resultPart.Parent then resultPart:Destroy() end
            local m2 = partRestore(snapMain, parent)
            partRestore(snapOther, parent)
            selected[player] = m2
            if m2 then queueObject(m2) end
        end,
        redo = function()
            local okR, errR = pcall(function()
                handlers.CsgDo(player, { op = op })
            end)
            if not okR then error(errR) end
        end,
    })
    return { id = idOf[resultPart], msg = ("CSG %s: '%s' × '%s' -> sólido NOVO '%s' (real: PartOperation + histórico desfaz)"):format(op, snapMain.name, snapOther.name, resultPart.Name) }
end

-- --------- SCULPT X: pincéis de terreno com falloff real (fill/erode/smooth/flat) ---------
local function sculptInfo(v)
    return type(v) == "string" and Enum.Material[v] or nil
end
function handlers.SculptApply(player, payload)
    assert(TERRAIN, "Sem Terrain neste mundo.")
    local mode = tostring(payload.mode or "raise")
    local cx, cy, cz = tonumber(payload.x) or 0, tonumber(payload.y) or 2, tonumber(payload.z) or 0
    local r = math.clamp(tonumber(payload.r) or 12, 4, 64)
    local strength = math.clamp(tonumber(payload.strength) or 1, 0.05, 1)
    local center = Vector3.new(cx, cy, cz)
    local mat = sculptInfo(payload.material) or Enum.Material.Grass
    local cells = 0
    if mode == "raise" then
        TERRAIN:FillBall(center, r * strength, mat)
        cells = 1
    elseif mode == "lower" then
        TERRAIN:FillBall(center, r * strength, Enum.Material.Air)
        cells = 1
    elseif mode == "smooth" or mode == "flat" then
        local minP = center - Vector3.new(r, r, r)
        local maxP = center + Vector3.new(r, r, r)
        local region = Region3.new(minP, maxP):ExpandToGrid(4)
        local okR, mats, occs = pcall(function()
            local m2, o2 = TERRAIN:ReadVoxels(region, 4)
            return true, m2, o2
        end)
        assert(okR, "ReadVoxels falhou: " .. tostring(mats))
        local sizeY = #occs[1]
        local sizeZ = #occs[1][1]
        local function voxelPos(ix, iy, iz)
            local cell = region.CFrame * Vector3.new(
                (ix - 0.5 - #occs / 2) * 4,
                (iy - 0.5 - #occs[1] / 2) * 4,
                (iz - 0.5 - #occs[1][1] / 2) * 4)
            return cell
        end
        for ix = 1, #occs do
            for iy = 1, sizeY do
                for iz = 1, sizeZ do
                    local vp = voxelPos(ix, iy, iz)
                    local dist = (vp - center).Magnitude
                    if dist < r then
                        local t2 = dist / r
                        local fall = math.exp(-(t2 * t2) * 4) * strength -- gaussiano caindo p/ zero na borda
                        if mode == "smooth" then
                            -- média dos 6 vizinhos (Laplaciano real)
                            local sum, n2 = 0, 0
                            local function getO(dx, dy, dz)
                                local jx, jy, jz = ix + dx, iy + dy, iz + dz
                                if occs[jx] and occs[jx][jy] and occs[jx][jy][jz] ~= nil then
                                    sum = sum + occs[jx][jy][jz] n2 = n2 + 1
                                end
                            end
                            getO(-1, 0, 0) getO(1, 0, 0) getO(0, -1, 0) getO(0, 1, 0) getO(0, 0, -1) getO(0, 0, 1)
                            if n2 > 0 then
                                occs[ix][iy][iz] = math.clamp(occs[ix][iy][iz] + (sum / n2 - occs[ix][iy][iz]) * fall, 0, 1)
                            end
                        else -- flat
                            local target = (cy - vp.Y) / 4
                            target = math.clamp(target, 0, 1)
                            if vp.Y <= cy then target = 1 else target = math.clamp((cy + 4 - vp.Y) / 8, 0, 1) end
                            occs[ix][iy][iz] = math.clamp(occs[ix][iy][iz] + (target - occs[ix][iy][iz]) * fall, 0, 1)
                            if occs[ix][iy][iz] > 0.4 and (mats[ix] and mats[ix][iy] and mats[ix][iy][iz] == Enum.Material.Air) then
                                mats[ix][iy][iz] = mat
                            end
                        end
                    end
                end
            end
        end
        local okW, errW = pcall(function() TERRAIN:WriteVoxels(region, 4, mats, occs) end)
        assert(okW, "WriteVoxels falhou: " .. tostring(errW))
        cells = #occs * sizeY * sizeZ
    else
        error("mode deve ser raise|lower|smooth|flat")
    end
    return { msg = ("SCULPT %s em (%.0f, %.0f, %.0f) r=%d força=%.2f — terreno REAL alterado (%s)"):format(
        mode, cx, cy, cz, r, strength, tostring(cells)) }
end

-- --------- COLLISION GROUPS (grupos de colisão reais) ---------
local PS = game:GetService("PhysicsService")
local function colGroups()
    local ok, list = pcall(function() return PS:GetRegisteredCollisionGroups() end)
    if ok and type(list) == "table" then return list end
    return {}
end
function handlers.ColGroupList(player)
    local out = {}
    for _, g in ipairs(colGroups()) do
        out[#out + 1] = { id = g.id, name = g.name, mask = (g.mask ~= nil and g.mask or nil) }
    end
    return { groups = out }
end
function handlers.ColGroupCreate(player, payload)
    local nm = tostring(payload.name or ""):sub(1, 40)
    assert(#nm > 1, "Nome de grupo muito curto.")
    for _, g in ipairs(colGroups()) do
        if g.name == nm then return { id = g.id, msg = "Já existe: " .. nm .. " (id " .. g.id .. ")" } end
    end
    local ok, err = pcall(function() PS:CreateCollisionGroup(nm) end)
    assert(ok, "CreateCollisionGroup recusou: " .. tostring(err))
    return { msg = "Grupo de colisão '" .. nm .. "' criado (atribua CollisionGroupId nas peças — PROPS X)." }
end
function handlers.ColGroupSetCollidable(player, payload)
    local a2 = tostring(payload.a or "")
    local b2 = tostring(payload.b or "")
    assert(a2 ~= "" and b2 ~= "", "Passe a e b (nomes dos grupos).")
    local v = payload.collidable ~= false
    local ok, err = pcall(function() PS:CollisionGroupSetCollidable(a2, b2, v) end)
    assert(ok, "Recusou: " .. tostring(err))
    return { msg = ("Colisão %s × %s = %s (real, servidor)"):format(a2, b2, v and "COLIDE" or "ignora") }
end

-- --------- PRESENCE: quem está editando o quê, agora ----------
function handlers.PresenceGet(player)
    local out = {}
    for pl in pairs(subscribed) do
        if pl.Parent == Players then
            local sel2 = selected[pl]
            local editing = {}
            for obj, owner in pairs(locks) do
                if owner == pl and obj and obj.Parent then
                    editing[#editing + 1] = obj.Name
                    if #editing >= 3 then break end
                end
            end
            out[#out + 1] = {
                name = pl.Name,
                selected = sel2 and sel2.Parent and sel2.Name or nil,
                editing = (#editing > 0) and table.concat(editing, ", ") or nil,
            }
        end
    end
    return { players = out }
end

-- --------- PLUGINS (módulos X ligam/desligam de verdade no pump) ----------
local function enginesFolder()
    return game:GetService("ServerStorage"):FindFirstChild("ArkherEngines")
end
local PLUGIN_KEYS = { "Atmos", "Water", "Anim", "Audio", "Rig", "Reality", "Scene" }
function handlers.PluginList(player)
    local eng = enginesFolder()
    local out = {}
    if eng then
        for _, child in ipairs(eng:GetChildren()) do
            out[#out + 1] = { id = child.Name, kind = child.ClassName, enabled = eng:GetAttribute("Enabled_" .. child.Name) ~= false }
        end
    end
    for _, kj in ipairs(PLUGIN_KEYS) do
        if eng and eng:GetAttribute("Enabled_" .. kj) == nil then
            eng:SetAttribute("Enabled_" .. kj, true)
        end
        out[#out + 1] = { id = kj, kind = "pump", enabled = not eng or eng:GetAttribute("Enabled_" .. kj) ~= false }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return { plugins = out }
end
function handlers.PluginToggle(player, payload)
    local id = tostring(payload.id or "")
    assert(#id > 0, "id do plugin")
    local v = payload.enabled == true
    local eng = enginesFolder()
    assert(eng, "ArkherEngines ausente no ServerStorage.")
    eng:SetAttribute("Enabled_" .. id, v)
    return { msg = ("Plugin/pump '%s' agora = %s (efeito IMEDIATO no pump do servidor)"):format(id, v and "LIGADO" or "desligado") }
end
'''

src = replace_once(src, MARK_A, MARK_A + BLOCK_A, "A")
src = replace_once(src, "local function getObject(id)", SER_DESER + "local function getObject(id)", "B")
src = replace_once(src, "local handlers={}", HIST_OPS + "local handlers={}", "C")
BLOCK_X11 = r'''
-- ============ BLOCK_X11 (ROUND 11): BASEPLATE garantida (boot auto + botão BASEPLATE) ============
local function ensureBaseplate()
    local b = workspace:FindFirstChild("Baseplate")
    if b and b:IsA("BasePart") then return b end
    b = Instance.new("Part")
    b.Name = "Baseplate"
    b.Size = Vector3.new(2048, 2, 2048)
    b.CFrame = CFrame.new(0, -1, 0)
    b.Anchored = true
    b.Color = Color3.fromRGB(100, 104, 118)
    b.Material = Enum.Material.Concrete
    pcall(function() b.TopSurface = Enum.SurfaceType.Smooth b.BottomSurface = Enum.SurfaceType.Smooth end)
    b.Parent = workspace
    register(b) created[b] = true
    return b
end

function handlers.EnsureBase(player)
    local old = workspace:FindFirstChild("Baseplate")
    local wasMissing = not (old and old:IsA("BasePart"))
    local b = ensureBaseplate()
    selected[player] = b
    if wasMissing then pcall(function() hCreate(player, b) end) end
    return { id = idOf[b], msg = wasMissing and "BASEPLATE criada (2048×2048, topo em Y=0) e selecionada." or "Baseplate já existia — selecionada no editor." }
end
'''

src = replace_once(src, "request.OnServerInvoke=function(player,action,payload)", NEW_HANDLERS + BLOCK_S + BLOCK_X7 + BLOCK_X8 + BLOCK_X9 + BLOCK_X10 + BLOCK_X11 + "request.OnServerInvoke=function(player,action,payload)", "D")
src = replace_once(src, 'print("ArkherEditorServer pronto',
    '-- ROUND 11 boot: baseplate sempre presente\npcall(function()\n\tlocal b0 = workspace:FindFirstChild("Baseplate")\n\tif not (b0 and b0:IsA("BasePart")) then\n\t\tensureBaseplate()\n\t\tprint("[Arkher] Baseplate criada automaticamente no boot (2048x2048).")\n\tend\nend)\nprint("ArkherEditorServer pronto', "X11boot")
# Delete original -> delega para Delete_ (reusa hDelete)
src = replace_once(
    src,
    'function handlers.Delete(player,payload)local o=getObject(payload.id);assert(editable(o)and not rootSet[o]and not containsProtected(o),"Este objeto não pode ser excluído.")assert(not conflictingLock(o,player),"Objeto ou descendente em edição por outro usuário.")release(player,true)local id=idOf[o];o:Destroy();unregister(o)selected[player]=nil return{removed=id}end',
    "function handlers.Delete(player,payload) return handlers.Delete_(player,payload) end",
    "D2",
)
# Create -> hCreate
src = replace_once(
    src,
    "local o=create(player,getObject(payload.parentId),payload.class,payload.name)selected[player]=o return{node=record(o),properties=properties(o)}end",
    "local o=create(player,getObject(payload.parentId),payload.class,payload.name)selected[player]=o hCreate(player,o) return{node=record(o),properties=properties(o)}end",
    "E",
)
# Set -> hSet
src = replace_once(
    src,
    "setProperty(o,payload.key,payload.value)return{node=record(o),properties=properties(o)}end",
    "local arkOld=read(o,payload.key)setProperty(o,payload.key,payload.value)local arkNew=read(o,payload.key)if arkOld~=arkNew then hSet(player,o,payload.key,arkOld,arkNew)end return{node=record(o),properties=properties(o)}end",
    "F",
)
# End -> hTransform
src = replace_once(
    src,
    "applyTransform(t,payload);local o=t.object;release(player,false)return{properties=properties(o),node=record(o)}end",
    "applyTransform(t,payload);local o=t.object;hTransform(player,o,t.cf,t.size,t.scale,getPivot(o),o:IsA(\"BasePart\")and o.Size or nil,o.ClassName==\"Model\"and o:GetScale()or nil);release(player,false)return{properties=properties(o),node=record(o)}end",
    "G",
)

open("studio-completo/scripts/server.lua", "w", encoding="utf-8").write(src)
print("server.lua gerado:", len(src), "chars")
