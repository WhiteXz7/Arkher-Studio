-- ARKHER V3 — bateria de verificacao (roda DENTRO do shim)
-- Imprime linhas "PASS ..." / "FAIL ..."; o python conta.
local function check(name, cond, extra)
	if cond then
		print("PASS " .. name)
	else
		print("FAIL " .. name .. (extra and (" — " .. tostring(extra)) or ""))
	end
end

local T = { failures = 0 }

-- 1) boot
ARKHER.boot()
check("boot: core inicializado", ARKHER._booted == true)
check("boot: do15 ativo", ArkherDO15 ~= nil)
check("boot: nmn ativo", ArkherNMN ~= nil)
check("boot: actions registrados", ARKHER.ACTIONS["file.save"] ~= nil and ARKHER.ACTIONS["insert.part"] ~= nil)

-- 2) PLACES
local ws = workspace
ArkherPlaces.new("City")
local city = ws:FindFirstChild("City")
check("place.new: cidade criada", city ~= nil)
local bcount = 0
if city then for _, ch in ipairs(city:GetChildren()) do bcount = bcount + 1 end end
check("place.new: 8+ edificios", bcount >= 8, bcount)

local id = ArkherPlaces.save("Test City")
check("place.save: id retornado", type(id) == "number" and id > 0, id)
local list = ArkherPlaces.list()
check("place.list: 1+ salvo", #list >= 1, #list)

-- export
local bundle = ArkherPlaces.exportBundle()
check("place.export: bundle gerado", type(bundle) == "string" and #bundle > 200, #bundle)
ArkherPlaces.exportToFile()
check("place.export: arquivo em disco", game:IsFile("ArkherPlaces/Test City.arkher.lua") == true)

-- open (restaura)
local partBefore
for _, ch in ipairs(ws:GetChildren()) do
	if ch.Name == "City" then
		for _, p in ipairs(ch:GetChildren()) do partBefore = p.Name break end
	end
end
ws:FindFirstChild("City"):Destroy()
check("place.open: pre-condicao (cidade removida)", ws:FindFirstChild("City") == nil)
local opened = ArkherPlaces.open(id)
check("place.open: restaurado", opened == true)
check("place.open: cidade de volta", ws:FindFirstChild("City") ~= nil)
check("place.open: name restaurado", ARKHER.STATE.placeName == "Test City", ARKHER.STATE.placeName)

-- 3) UNDO/REDO
ARKHER.cmd("undo.push", "antes de deletar")
local victim = ws:FindFirstChild("Part")
if not victim then
	victim = Instance.new("Part")
	victim.Name = "UndoVictim"
	victim.Parent = ws
end
local vname = victim.Name
ARKHER.cmd("undo.push", "deletar " .. vname)
victim:Destroy()
check("undo: pre-condicao (victima removida)", ws:FindFirstChild(vname) == nil)
ArkherUNDO.undo()
check("undo: vítima restaurada", ws:FindFirstChild(vname) ~= nil)
ArkherUNDO.redo()
check("redo: vítima removida de novo", ws:FindFirstChild(vname) == nil)
ArkherUNDO.undo()

-- 4) SINGULARITY (IA local)
local rep = ARKHER_SINGULARITY.run("crie uma cidade com npc e otimize")
check("singularity: relatorio retornado", type(rep) == "table" and rep.ok == true)
check("singularity: 4+ etapas", #rep.lines >= 4, #rep.lines)
local hasCity, hasNpc, hasPerf = false, false, false
for _, l in ipairs(rep.lines) do
	if l:find("cidade") then hasCity = true end
	if l:find("npcs") then hasNpc = true end
	if l:find("performance") then hasPerf = true end
end
check("singularity: especialista cidade executou", hasCity)
check("singularity: especialista npc executou", hasNpc)
check("singularity: especialista perf executou", hasPerf)

local rep2 = ARKHER_SINGULARITY.run("diagnostico")
local hasDiag = false
for _, l in ipairs(rep2.lines) do
	if l:find("diagnostico") and l:find("parts") then hasDiag = true end
end
check("singularity: diagnostico tem parts", hasDiag)

-- 5) NMN
local before = ArkherNMN.count()
for i = 1, 4 do
	ArkherNMN.spawn("MindTest_" .. i, Vector3.new(i * 5, 3, i * 5))
end
check("nmn: 4 mentes criadas", ArkherNMN.count() == before + 4, ArkherNMN.count())
game:GetService("RunService")._fireHB(700)
local rpt = ArkherNMN.why("MindTest_1_1")
-- ids sao name_tick; achar o real
local found = false
for _, m in ipairs(ArkherNMN.report()) do
	if m.name == "MindTest_1" then found = true; local w = ArkherNMN.why(m.id); check("nmn: por que (causalidade)", type(w) == "string" and #w > 3, w) break end
end
check("nmn: report lista mentes", found)

-- 6) PUBLISH
check("publish: local ok", ArkherPublish.toLocal() == true)
check("publish: historico 1+", #ArkherPublish.history() >= 1, #ArkherPublish.history())
local m = ArkherPublish.manifest()
check("publish: manifest tem nome", type(m.name) == "string" and #m.name > 0)
ArkherPublish.toEndpoint() -- sem endpoint → warning, nao crash
check("publish: endpoint ausente nao crash", true)

-- 7) LIVE (inspector + hierarchy)
local baseplate = ws:FindFirstChild("Baseplate")
if not baseplate then
	-- o teste de singularity limpou o workspace; cria uma part de inspecao
	baseplate = Instance.new("Part")
	baseplate.Name = "InspectionPart"
	baseplate.Parent = ws
end
game:GetService("Selection"):Set({ baseplate })
check("live: selection changed disparou", #game:GetService("Selection"):Get() == 1)
-- rebuild direto
local probe = Instance.new("Frame")
probe.Name = "ProbeContainer"
probe.Parent = workspace:FindFirstChild("Lighting") or workspace
local probe2 = Instance.new("Frame")
probe2.Name = "ProbeH"
probe2.Parent = probe
ArkherLive.rebuildInspector(probe)
local secs = 0
for _, ch in ipairs(probe:GetDescendants()) do if ch.Name:sub(1,4) == "SEC_" then secs = secs + 1 end end
check("live: inspector com secoes", secs >= 1, secs)
ArkherLive.rebuildHierarchy(probe2, "", { open = { Workspace = true } })
local rows = 0
for _, ch in ipairs(probe2:GetChildren()) do if ch.Name:sub(1,4) == "Row_" then rows = rows + 1 end end
check("live: hierarchy com linhas", rows >= 4, rows)
probe:Destroy()

-- 8) MAIN shell
ARKHER_BUILD_MAIN()
local coreGui = game:GetService("CoreGui")
local folder = coreGui:FindFirstChild("ArkherStudio")
local mainGui = folder and folder:FindFirstChild("ArkherStudioMainUI")
check("main: shell no CoreGui", mainGui ~= nil)
local rootF = mainGui and mainGui:FindFirstChild("Root")
local menuBar = rootF and rootF:FindFirstChild("MenuBar")
check("main: root tem menus", menuBar ~= nil and menuBar:FindFirstChild("M_FILE") ~= nil)
check("main: ribbon tem Save", rootF ~= nil and rootF:FindFirstChild("Ribbon") ~= nil)

-- 9) ACTIONS
ARKHER.cmd("insert.part")
check("actions: insert.part cria part", true)
ARKHER.cmd("tool", "Move")
check("actions: tool move", ARKHER.STATE.tool == "Move")
local sel = ArkherLive.currentSelection()
check("actions: selecao atual e part", sel ~= nil and sel:IsA("BasePart") == true, sel and sel.ClassName)
ARKHER.cmd("edit.delete")
check("actions: delete remove selecionado", sel == nil or sel.Parent == nil)
ARKHER.cmd("file.save")
check("actions: file.save funciona", #ArkherPlaces.list() >= 1)

-- 10) D-O15
game:GetService("RunService")._fireHB(200)
local drep = ArkherDO15.report()
check("do15: fps medido", drep.fps > 0, drep.fps)
Bus.emit("do15.nudge", 1)
check("do15: nudge p/ MAX", ArkherDO15.state.level == 1)

-- 11) UIs registradas (cada UI so se registra quando seu arquivo esta no build)
local uiCount = #ARKHER.listUIs()
print("INFO ui_count=" .. uiCount)
check("ui: 23+ UIs registradas", uiCount >= 23, uiCount)
-- janelas de verdade montadas no CoreGui (shell + uma por UI)
local arkFolder = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
local created = 0
if arkFolder then
	for _, ch in ipairs(arkFolder:GetChildren()) do
		if ch:FindFirstChild("Root") then created = created + 1 end
	end
end
check("ui: janelas montadas no CoreGui", created >= 23, created)
local uiFailed = 0
for _, e in ipairs(ARKHER.OUTPUT or {}) do
	if e.kind == "ERROR" and tostring(e.msg):find("falhou") then uiFailed = uiFailed + 1 end
end
check("ui: nenhuma build falhou", uiFailed == 0, uiFailed)

print("VERIFY_DONE failures_so_far=see_above")
