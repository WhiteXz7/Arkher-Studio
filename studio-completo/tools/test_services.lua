-- Testa o ArkherServices (module) no mock. Executa apos o mock.lua.
local f = io.open("studio-completo/scripts/modules/arkher_services.lua", "rb")
local src = f:read("*a")
f:close()
local ms = Instance.new("ModuleScript")
ms.Name = "ArkherServices"
ms.Source = src
local M = require(ms)
assert(type(M) == "table", "require nao retornou tabela")

local st = M.status()
print("STATUS owner=" .. st.owner .. " projects=" .. st.projects .. " published=" .. st.published .. " members=" .. st.members)

-- cloud
local rec = M.cloudPut("Projeto Teste", '{"c":"Workspace"}', 42, 5)
print("CLOUD put id=" .. rec.id .. " name=" .. rec.name .. " nodes=" .. rec.nodes)
local got = M.cloudGet(rec.id)
assert(got and got.data == '{"c":"Workspace"}', "cloudGet round-trip falhou")
assert(#M.cloudList() == 1, "cloudList deve ter 1")

-- publish
local g = M.publish({ title = "Meu Jogo Insano", description = "Acao", genre = "Aventura", visibility = "Public" })
print("PUBLISH url=" .. g.url .. " version=" .. g.version .. " publishedBy=" .. g.publishedBy)
assert(g.url:find("roblox.com/games/") ~= nil, "url de publicar invalida")
local g2 = M.publish({ title = "Meu Jogo Insano" })
assert(g2.version == 2 and g2.visits == 2, "re-publicar deve bump versao")
assert(#M.profileList() == 1, "profileList deve ter 1")
print("PROFILE title=" .. M.profileList()[1].title .. " rating=" .. M.profileList()[1].rating)

-- data
M.dataSet("Coins", 500, "number"); M.dataSet("Name", "Hero", "string"); M.dataSet("Win", true, "boolean")
assert(#M.dataList() == 3, "dataList deve ter 3")
assert(M.dataGet("Coins").value == 500 and M.dataGet("Coins").type == "number", "data number falhou")
M.dataDelete("Name")
assert(#M.dataList() == 2, "dataDelete falhou")

-- team
assert(#M.team().members == 1, "team inicial deve ter 1 (owner)")
M.teamAdd("amigo@x.com", "Editor")
assert(#M.team().members == 2, "teamAdd falhou")

-- invite
local inv = M.inviteCreate("novo@y.com", "Viewer")
assert(inv.code ~= "" and inv.link:find("arkher.dev/j/") ~= nil, "inviteCreate falhou")
local acc = M.inviteAccept(inv.code)
assert(acc.ok == true and acc.member ~= nil, "inviteAccept falhou")
print("INVITE code=" .. inv.code .. " accepted=" .. acc.member)

-- project info
M.setProjectInfo({ GameName = "Jogo Epico", MaxPlayers = 100, Visibility = "Unlisted" })
local pi = M.projectInfo()
assert(pi.GameName == "Jogo Epico" and pi.MaxPlayers == 100 and pi.Visibility == "Unlisted", "setProjectInfo falhou")

-- locales
assert(M.locales().current == "pt-BR", "locale padrao")
M.setLocale("en")
local ss = M.strings()
assert(#ss.strings >= 3, "strings padrao")
assert(ss.strings[2].resolved == "Play", "resolucao en do PlayButton")
M.setString("Save", "Salvar", { en = "Save", es = "Guardar" })
assert(#M.strings().strings >= 4, "setString falhou")

-- toolbox
local tb = M.toolboxList()
assert(#tb.categories >= 3, "toolbox categorias")
local t = M.toolboxGet("tb_bridge")
assert(t and #t.nodes == 4, "toolboxGet bridge")

print("SERVICES: 20 passaram, 0 falharam")
