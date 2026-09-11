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

# ================= aplicar =================
src = ORIG
src = replace_once(src, MARK_A, MARK_A + BLOCK_A, "A")
src = replace_once(src, "local function getObject(id)", SER_DESER + "local function getObject(id)", "B")
src = replace_once(src, "local handlers={}", HIST_OPS + "local handlers={}", "C")
src = replace_once(src, "request.OnServerInvoke=function(player,action,payload)", NEW_HANDLERS + "request.OnServerInvoke=function(player,action,payload)", "D")
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
