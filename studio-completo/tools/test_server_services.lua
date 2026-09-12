-- Testa os handlers de ARKHER SERVICES no server.lua (via bridge real).
dofile("studio-completo/tools/mock.lua")

local RS = game:GetService("ReplicatedStorage")
local src = io.open("studio-completo/scripts/server.lua"):read("*a")
local fn, serr = loadstring(src, "[server]")
assert(fn, "sintaxe do server: " .. tostring(serr))
local ok, rerr = pcall(fn)
assert(ok, "execucao do server falhou: " .. tostring(rerr))

local bridge = RS:FindFirstChild("ArkherStudioBridge")
local request = bridge:FindFirstChild("Request")
local testPlayer = game:GetService("Players"):FindFirstChild("WhiteXz73_Developer")
local function invoke(action, payload)
	return rawget(request, "__props").OnServerInvoke(testPlayer, action, payload or {})
end
local pass, fail = 0, 0
local function check(cond, msg)
	if cond then pass = pass + 1 print("  OK  " .. msg)
	else fail = fail + 1 print("  FALHOU  " .. msg) end
end
local function errOf(r) return r and r.error end

-- STATUS
local st = invoke("CloudStatus")
check(st and st.owner == "WhiteXz73_Developer", "CloudStatus: owner=" .. tostring(st and st.owner))
check(st and st.ready == true, "CloudStatus: ready")

-- CLOUD save/open/list
local cs = invoke("CloudSave", { name = "Checkpoint V1" })
check(cs and cs.project and cs.project.nodes > 0, "CloudSave: nodes=" .. tostring(cs and cs.project and cs.project.nodes))
local cid = cs and cs.project and cs.project.id
local cl = invoke("CloudList")
check(cl and #cl.projects == 1, "CloudList: 1 projeto")
-- cria uma part e salva de novo (diferencia o snapshot)
local cr = invoke("Create", { class = "Part", parentId = (invoke("Snapshot").roots or {})[1], name = "PartCloud" })
check(cr and cr.node, "Create PartCloud")
local cs2 = invoke("CloudSave", { name = "Checkpoint V2" })
check(cs2 and cs2.project and cs2.project.nodes > (cs.project.nodes), "CloudSave V2 tem mais nodes")
local cl2 = invoke("CloudList")
check(cl2 and #cl2.projects == 2, "CloudList: 2 projetos")
-- abre o V1 (volta ao estado anterior)
local co = invoke("CloudOpen", { id = cid })
check(co and co.opened == "Checkpoint V1", "CloudOpen: abriu " .. tostring(co and co.opened))

-- PUBLISH (perfil do dev)
local pub = invoke("Publish", { title = "Meu Jogo Insano", description = "Acao e aventura", genre = "Aventura", visibility = "Public" })
check(pub and pub.game and pub.game.url:find("roblox.com/games/") ~= nil, "Publish: url=" .. tostring(pub and pub.game and pub.game.url))
check(pub and pub.game and pub.game.publishedBy == "WhiteXz73_Developer", "Publish: publicado pelo dev")
local pub2 = invoke("Publish", { title = "Meu Jogo Insano" })
check(pub2 and pub2.game and pub2.game.version == 2, "Re-publish: version bump para 2")
local pl = invoke("ProfileList")
check(pl and #pl.games == 1, "ProfileList: 1 jogo no perfil")
local pg = invoke("ProfileGet", { id = pub.game.id })
check(pg and pg.game and pg.game.description == "Acao e aventura", "ProfileGet: descricao")

-- DATA
invoke("DataSet", { key = "Coins", value = 500, type = "number" })
invoke("DataSet", { key = "Skin", value = "Hero", type = "string" })
local dl = invoke("DataList")
check(dl and #dl.entries == 2, "DataList: 2 entradas")
local dg = invoke("DataGet", { key = "Coins" })
check(dg and dg.entry and dg.entry.value == 500 and dg.entry.type == "number", "DataGet: Coins=500")
invoke("DataDelete", { key = "Skin" })
check(invoke("DataList").entries and #invoke("DataList").entries == 1, "DataDelete: resta 1")

-- PROJETO
invoke("SetProjectInfo", { GameName = "Jogo Epico", MaxPlayers = 100, Visibility = "Unlisted" })
local pi = invoke("ProjectInfo")
check(pi and pi.info and pi.info.GameName == "Jogo Epico" and pi.info.MaxPlayers == 100, "ProjectInfo: GameName+Max")

-- EQUIPE + CONVITES
local ti = invoke("TeamInfo")
check(ti and ti.count == 1 and ti.members[1].role == "Owner", "TeamInfo: 1 owner")
local ta = invoke("TeamAdd", { name = "amigo@x.com", role = "Editor" })
check(ta and ta.count == 2, "TeamAdd: 2 membros")
local ic = invoke("InviteCreate", { email = "novo@y.com", role = "Viewer" })
check(ic and ic.invite and ic.invite.link:find("arkher.dev/j/") ~= nil, "InviteCreate: link=" .. tostring(ic and ic.invite and ic.invite.link))
local il = invoke("InviteList")
check(il and #il.invites == 1, "InviteList: 1 convite")
local ia = invoke("InviteAccept", { code = ic.invite.code })
check(ia and ia.ok == true, "InviteAccept: ok")

-- i18n
local loc = invoke("Locales")
check(loc and loc.current == "pt-BR" and #loc.available >= 5, "Locales: pt-BR + 5 idiomas")
invoke("SetLocale", { code = "en" })
check(invoke("Locales").current == "en", "SetLocale: en")
local ls = invoke("LocStrings")
check(ls and #ls.strings >= 3 and ls.strings[2].resolved == "Play", "LocStrings: PlayButton@en=Play")
invoke("SetLocString", { key = "Save", value = "Salvar", translations = { en = "Save", es = "Guardar" } })
check(#invoke("LocStrings").strings >= 4, "SetLocString: adiciona chave")

-- TOOLBOX
local tb = invoke("ToolboxList")
check(tb and #tb.categories >= 3, "ToolboxList: " .. tostring(tb and #tb.categories) .. " categorias")
local wsId = (invoke("Snapshot").roots or {})[1]
local ti2 = invoke("ToolboxInsert", { id = "tb_bridge", parentId = wsId })
check(ti2 and ti2.node and ti2.count == 4, "ToolboxInsert ponte: " .. tostring(ti2 and ti2.count) .. " nodes")
-- desfaz a insercao do toolbox
local un = invoke("Undo")
check(un and un.label and un.label:find("Toolbox") ~= nil, "Undo: desfaz toolbox (" .. tostring(un and un.label) .. ")")

print("SERVER SERVICES: " .. pass .. " passaram, " .. fail .. " falharam")
if fail > 0 then os.exit(1) end
