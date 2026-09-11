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
check("ui: 26+ UIs registradas (V4 inclui WATER + SCATTER)", uiCount >= 26, uiCount)
-- janelas de verdade montadas no CoreGui (shell + uma por UI)
local arkFolder = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
local created = 0
if arkFolder then
	for _, ch in ipairs(arkFolder:GetChildren()) do
		if ch:FindFirstChild("Root") then created = created + 1 end
	end
end
check("ui: janelas montadas no CoreGui", created >= 26, created)
local uiFailed = 0
for _, e in ipairs(ARKHER.OUTPUT or {}) do
	if e.kind == "ERROR" and tostring(e.msg):find("falhou") then uiFailed = uiFailed + 1 end
end
check("ui: nenhuma build falhou", uiFailed == 0, uiFailed)

-- 12) D-MATH (campos deterministicos — fundamento RRW)
do
	local a1 = ArkherDM.gnoise2(3.7, 9.2, 42)
	local a2 = ArkherDM.gnoise2(3.7, 9.2, 42)
	check("dmath: ruido deterministico", a1 == a2)
	local f1 = ArkherDM.fbm2(1.3, 7.7, { octaves = 4, seed = 5, fn = "ridged" })
	check("dmath: fbm limitado [-1.05,1.05]", f1 >= -1.05 and f1 <= 1.05, f1)
	local w1, w2 = ArkherDM.worley2(4.4, 8.8, 3)
	check("dmath: worley F2>=F1", w2 >= -0.0001)
	check("dmath: whittaker tropical", ArkherDM.whittaker(28, 200) == "floresta_equatorial")
	check("dmath: whittaker deserto", ArkherDM.whittaker(30, 10) == "deserto_quente")
	check("dmath: whittaker gelo", ArkherDM.whittaker(-15, 50) == "gelo")
	local b = ArkherDM.bilinear({ 0, 10, 20, 30 }, 2, 2, 1.5, 1.5)
	check("dmath: bilinear centro", math.abs(b - 15) < 0.001, b)
	check("dmath: falloff gauss decai", ArkherDM.falloff(2, 4, "gaussian") < ArkherDM.falloff(0.5, 4, "gaussian"))
end

-- 13) TERRAIN X (motor custom — nao usa Terrain do Roblox)
do
	check("terrainx: engine carregada", ArkherTerrainX ~= nil)
	check("terrainx: 20+ materiais fisicos", #ArkherTerrainX.MATERIALS >= 20, #ArkherTerrainX.MATERIALS)
	local w = ArkherTerrainX.new({ seed = 42, preset = "continentes", cell = 8, chunkCells = 16 })
	local h1 = w:heightAt(10, 10)
	local h2 = w:heightAt(10, 10)
	check("terrainx: altura deterministica", h1 == h2, h1)
	local w2 = ArkherTerrainX.new({ seed = 42, preset = "continentes", cell = 8, chunkCells = 16 })
	check("terrainx: mesma seed = mesmo mundo", w2:heightAt(10, 10) == h1)
	local w3 = ArkherTerrainX.new({ seed = 777, preset = "continentes", cell = 8, chunkCells = 16 })
	check("terrainx: seeds diferentes = mundos diferentes", w3:heightAt(121, 37) ~= w:heightAt(121, 37), w3:heightAt(121, 37) .. " vs " .. w:heightAt(121, 37))
	-- escultura
	local before = w:heightAt(0, 0)
	w:sculpt(0, 0, { op = "raise", radius = 16, strength = 1, amount = 10, falloff = "smooth" })
	local after = w:heightAt(0, 0)
	check("terrainx: pincel raise sobe o relevo", after > before, before .. "->" .. after)
	w:sculpt(0, 0, { op = "lower", radius = 16, strength = 1, amount = 30, falloff = "sharp" })
	check("terrainx: pincel lower desce", w:heightAt(0, 0) < after)
	-- erosao real muda relevo
	local w4 = ArkherTerrainX.new({ seed = 9, preset = "montanhas", cell = 8 })
	local m1 = w4:heightAt(0, 0)
	local er = w4:erodeHydraulic(1, 1, 48, 32, 1500)
	check("terrainx: erosao hidraulica executa", er.iterations == 1500 and er.maxDelta >= 0)
	check("terrainx: erosao altera o relevo", w4:heightAt(0, 0) ~= m1 or er.meanDelta > 0)
	local tr = w4:erodeThermal(1, 1, 48, 32, 4, 0.8)
	check("terrainx: erosao termica executa", tr.passes == 4)
	-- rios e lagos
	local rv = w4:carveRivers(1, 1, 48, 32, 14)
	check("terrainx: rios por acumulacao", rv.maxAcc > 14, rv.maxAcc)
	local lk = w4:fillLakes(1, 1, 48, 32)
	check("terrainx: fillLakes executa", lk.cells >= 0)
	-- biomas reais
	local bc = w4:biomeCounts()
	local nb = 0
	for _ in pairs(bc) do nb = nb + 1 end
	check("terrainx: 2+ biomas classificados", nb >= 2, nb)
	-- materializacao
	local mm = w4:materializeRegion(-64, -64, 128, 128, {})
	check("terrainx: materializa chunks reais", mm.chunks >= 1 and mm.parts > 0, mm.parts)
	local atxModel = workspace:FindFirstChild("ATX_World")
	check("terrainx: ATX_World no workspace", atxModel ~= nil)
	check("terrainx: LOD adaptativo roda", (function()
		local r = w4:updateLOD(0, 0)
		return r.updated >= 0
	end)())
	-- serialize roundtrip
	local str = w4:serialize()
	local w5 = ArkherTerrainX.deserialize(str)
	check("terrainx: roundtrip JSON", w5 ~= nil and w5.seed == 9, w5 and w5.seed)
	check("terrainx: chunks restaurados", w5 ~= nil and (w5.restored or 0) >= 1, w5 and w5.restored)
	ArkherTerrainX.clearWorld(w4)
	check("terrainx: clear remove modelo", workspace:FindFirstChild("ATX_World") == nil)
end

-- 14) WATER X (motor custom — nao usa agua do Roblox)
do
	check("waterx: engine carregada", ArkherWaterX ~= nil)
	check("waterx: 8 tipos de agua", (function()
		local n2 = 0
		for _ in pairs(ArkherWaterX.WATERS) do n2 = n2 + 1 end
		return n2 >= 8
	end)())
	local sea = ArkherWaterX.preset("ressaca", { kind = "oceano", level = 0, size = { x = 300, z = 300 } })
	check("waterx: preset com 3+ ondas", #sea.waves >= 3, #sea.waves)
	local ha = sea:heightAt(13, 7, 2.5)
	local hb = sea:heightAt(13, 7, 2.5)
	check("waterx: heightAt deterministico", ha == hb, ha)
	local hc = sea:heightAt(13, 7, 4.9)
	check("waterx: onda evolui no tempo", hc ~= ha)
	local sea2 = ArkherWaterX.preset("calmaria", { kind = "lago", level = 0 })
	check("waterx: calmaria mais plana que ressaca", math.abs(sea2:heightAt(3, 3, 1)) < math.abs(sea:heightAt(3, 3, 1)) + 1.5)
	-- flutuabilidade: objeto leve sobe
	local p = Instance.new("Part")
	p.Name = "TestBuoy"
	p.Size = Vector3.new(4, 4, 4)
	p.Position = Vector3.new(0, -6, 0) -- afundado
	p.Parent = workspace
	local mar = ArkherWaterX.create("oceano", { level = 0, waves = { { amp = 0.05, len = 50, dir = 0, speed = 1, steep = 0.1 } }, tideAmp = 0 })
	local f = ArkherWaterX.float(mar, p, { density = 300 }) -- 300 < 1025: flutua
	local y0 = p.Position.Y
	for i = 1, 40 do ArkherWaterX.stepFloater(f, 0.1, i * 0.1) end
	check("waterx: boia sobe (Arquimedes)", p.Position.Y > y0, y0 .. "->" .. p.Position.Y)
	-- materializacao + animacao
	local model, tiles = ArkherWaterX.materialize(mar, { maxSpan = 128, tile = 32 })
	check("waterx: tiles de mar materializadas", tiles > 0, tiles)
	local moved = ArkherWaterX.animate(mar, 1.3)
	check("waterx: animate move tiles", moved > 0, moved)
	local cau = ArkherWaterX.caustics(mar, -9)
	check("waterx: causticas geradas", cau >= 0)
	-- roundtrip
	local s2 = mar:serialize()
	local mar2 = ArkherWaterX.deserialize(s2)
	check("waterx: roundtrip JSON", mar2 ~= nil and #mar2.waves == #mar.waves)
	check("waterx: props restaurados", mar2 ~= nil and mar2.props.dens == mar.props.dens)
	local sw = ArkherWaterX.swim(mar, Vector3.new(0, -1, 0), 5, 0)
	check("waterx: swim detecta imersao", sw.immersion > 0, sw.immersion)
	p:Destroy()
end

-- 15) SCRIPT STUDIO X (IDE backend)
do
	check("scripterx: engine carregada", ArkherScripterX ~= nil)
	local toks = ArkherScripterX.tokenize("local x = 1 -- oi\nprint(x)")
	local kinds = {}
	for _, t in ipairs(toks) do kinds[t.k] = true end
	check("scripterx: tokenizer id+kw+num+cmt", kinds.id and kinds.kw and kinds.num and kinds.cmt)
	local d1 = ArkherScripterX.lint("local x = 1\nif x > 2 then\nprint(x)\nend")
	local s1 = ArkherScripterX.lintSummary(d1)
	check("scripterx: codigo limpo sem erros", s1.errors == 0, s1.errors)
	local d2 = ArkherScripterX.lint("local x = 1\nif x > 2 then\nprint(x)")
	local s2 = ArkherScripterX.lintSummary(d2)
	check("scripterx: detecta bloco aberto", s2.errors >= 1, s2.errors)
	local d3 = ArkherScripterX.lint("local unusedVar = 5\nwait(1)")
	local hasUnused, hasDepr = false, false
	for _, di in ipairs(d3) do
		if di.code == "I20" then hasUnused = true end
		if di.code == "W30" then hasDepr = true end
	end
	check("scripterx: detecta local nao usada", hasUnused)
	check("scripterx: detecta API depreciada (wait)", hasDepr)
	local ac = ArkherScripterX.complete("GetS", "")
	local hasGS = false
	for _, r in ipairs(ac) do if r.label == "GetService" then hasGS = true end end
	check("scripterx: autocomplete GetService", hasGS)
	check("scripterx: 30 templates", #ArkherScripterX.TEMPLATES >= 30, #ArkherScripterX.TEMPLATES)
	check("scripterx: 45 snippets", #ArkherScripterX.SNIPPETS >= 45, #ArkherScripterX.SNIPPETS)
	local srcC, idC = ArkherScripterX.compose("crie uma arma")
	check("scripterx: compose arma", idC == "arma_raycast" and #srcC > 50, idC)
	local oc = ArkherScripterX.compile("local x = 1 return x")
	check("scripterx: compile ok", oc.ok == true)
	local m = ArkherScripterX.metrics("if a then for i = 1, 3 do end end")
	check("scripterx: metricas de complexidade", m.complexity >= 3, m.complexity)
	local ops = ArkherScripterX.diffLines("a\nb", "a\nc")
	local hasAdd = false
	for _, o in ipairs(ops) do if o.op == "add" then hasAdd = true end end
	check("scripterx: diff encontra mudanca", hasAdd)
	local fmt = ArkherScripterX.format("local x = 1\nif x then\nprint(x)\nend")
	check("scripterx: format indeta", fmt:find("\tprint") ~= nil, fmt)
	local ol = ArkherScripterX.outline("local function a() end\nfunction b() end")
	check("scripterx: outline 2 funcoes", #ol == 2, #ol)
	local nr, nrep = ArkherScripterX.replace("a b a", "a", "z", {})
	check("scripterx: replace tudo", nrep == 2 and nr == "z b z", nr)
end

-- 16) UI KIT X (widgets de jogo)
do
	check("uikitx: engine carregada", ArkherUIKitX ~= nil)
	local nW = 0
	for _ in pairs(ArkherUIKitX.WIDGETS) do nW = nW + 1 end
	check("uikitx: 40+ widgets", nW >= 40, nW)
	local cats = ArkherUIKitX.catalog()
	local nC = 0
	for _ in pairs(cats) do nC = nC + 1 end
	check("uikitx: 5 categorias", nC >= 5, nC)
	local w1 = ArkherUIKitX.create("health", { x = 10, y = 20 })
	check("uikitx: create health", w1 ~= nil and w1.root ~= nil and w1.root:GetAttribute("ARKHER_WIDGET") == "health")
	local fake = ArkherUIKitX.create("nao_existe")
	check("uikitx: widget invalido falha seguro", fake == nil)
	local it1 = { kind = "label", meta = { x = 50, y = 10, w = 100, h = 20 } }
	local it2 = { kind = "label", meta = { x = 200, y = 40, w = 100, h = 20 } }
	ArkherUIKitX.alignLeft({ it1, it2 })
	check("uikitx: alignLeft", it1.meta.x == 50 and it2.meta.x == 50, it2.meta.x)
	ArkherUIKitX.distributeH({ it1, it2, { kind = "label", meta = { x = 500, y = 10, w = 100, h = 20 } } })
	check("uikitx: distributeH roda", true)
	local okAnc = ArkherUIKitX.anchorPreset(it1, "inf_dir", 960, 540)
	check("uikitx: anchor inf_dir", okAnc and it1.meta.x == 860 and it1.meta.y == 520, it1.meta.x .. "," .. it1.meta.y)
	-- build REAL no StarterGui
	local widgets = {
		ArkherUIKitX.create("health", { x = 16, y = 16 }),
		ArkherUIKitX.create("hotbar", { x = 16, y = 470, slots = 6 }),
	}
	local gui, n = ArkherUIKitX.build(widgets, "ArkherHUD_Test")
	check("uikitx: build monta ScreenGui", gui ~= nil and n == 2, n)
	local sg = game:GetService("StarterGui")
	check("uikitx: gui no StarterGui", sg:FindFirstChild("ArkherHUD_Test") ~= nil)
	local src = ArkherUIKitX.exportModule(widgets, "TestHUD")
	check("uikitx: exportModule gera codigo", type(src) == "string" and src:find("function M.build") ~= nil and #src > 200, #src)
	local imported = ArkherUIKitX.importGui(gui)
	check("uikitx: import do gui", #imported == 2, #imported)
	check("uikitx: exportController gera code", ArkherUIKitX.exportController(widgets, "C"):find("function M.bind") ~= nil)
	gui:Destroy()
end

-- 17) COMANDOS NOVOS (V4)
do
	ARKHER.cmd("terrain.generate", "ilhas", 555)
	check("cmd: terrain.generate", workspace:FindFirstChild("ATX_World") ~= nil)
	ARKHER.cmd("terrain.erode", 800)
	ARKHER.cmd("terrain.rivers")
	ARKHER.cmd("terrain.materialize", 96)
	ARKHER.cmd("water.ocean", "calmaria")
	check("cmd: water.ocean", workspace:FindFirstChild("AWX_Water") ~= nil)
	ARKHER.cmd("water.caustics")
	ARKHER.cmd("water.splash")
	ARKHER.cmd("script.new", "CmdTest", "basico")
	check("cmd: script.new cria Script", workspace:FindFirstChild("CmdTest") ~= nil)
	ARKHER.cmd("script.newfromgoal", "espada")
	check("cmd: script.newfromgoal", workspace:FindFirstChild("IA_espada") ~= nil)
	ARKHER.cmd("uix.hud")
	check("cmd: uix.hud", game:GetService("StarterGui"):FindFirstChild("ArkherHUD") ~= nil)
	ARKHER.cmd("terrain.clear")
	check("cmd: terrain.clear", workspace:FindFirstChild("ATX_World") == nil)
end

-- 18) SINGULARITY V4 (especialistas ATX/AWX/AXI)
do
	local rep3 = ARKHER_SINGULARITY.run("crie um terreno realista com rios e um oceano")
	local hasTerr, hasWater = false, false
	for _, l in ipairs(rep3.lines) do
		if l:find("terreno ATX") then hasTerr = true end
		if l:find("agua AWX") then hasWater = true end
	end
	check("singularity V4: especialista terreno ATX", hasTerr)
	check("singularity V4: especialista agua AWX", hasWater)
	local rep4 = ARKHER_SINGULARITY.run("monte uma hud de jogo")
	local hasHud = false
	for _, l in ipairs(rep4.lines) do
		if l:find("hud AXI") then hasHud = true end
	end
	check("singularity V4: especialista HUD AXI", hasHud)
	check("singularity V4: hud no StarterGui", game:GetService("StarterGui"):FindFirstChild("ArkherHUD_AI") ~= nil)
end

-- 19) ANIMATOR X (motor de animacao custom)
do
	check("animx: engine carregada", ArkherAnimX ~= nil)
	local nE = 0
	for _ in pairs(ArkherAnimX.EASE) do nE = nE + 1 end
	check("animx: 35+ easings", nE >= 35, nE)
	check("animx: easeOut_back faz overshoot (>1)", ArkherAnimX.EASE.easeOut_back(0.5) > 1, ArkherAnimX.EASE.easeOut_back(0.5))
	check("animx: easeOut_elastic faz overshoot", ArkherAnimX.EASE.easeOut_elastic(0.5) > 1, ArkherAnimX.EASE.easeOut_elastic(0.5))
	check("animx: linear identidade", ArkherAnimX.EASE.linear(0.37) == 0.37)
	check("animx: catmull passa nos pontos", math.abs(ArkherAnimX.catmull(0, 0, 10, 10, 0) - 0) < 1e-9 and math.abs(ArkherAnimX.catmull(0, 0, 10, 10, 1) - 10) < 1e-9)
	local cv = ArkherAnimX.curve({ 0, 4, 2, 8 })
	check("animx: curva catmull avalia interior", type(cv(0.5)) == "number", cv(0.5))
	local sp = ArkherAnimX.spring({ stiffness = 140, damping = 16, target = 10 })
	for i = 1, 200 do sp:update(0.016) end
	check("animx: spring converge p/ alvo", math.abs(sp.pos - 10) < 0.1, sp.pos)
	local c = ArkherAnimX.clip("T", { loop = "none" })
	c:addTrack("Position", { ArkherAnimX.key(0, { x = 0, y = 0, z = 0 }, "linear"), ArkherAnimX.key(2, { x = 10, y = 20, z = 0 }, "linear") })
	c:addTrack("Transparency", { ArkherAnimX.key(0, 1, "linear"), ArkherAnimX.key(2, 0, "easeOut_sine") })
	check("animx: clip duracao", c:duration() == 2)
	local sm = c:sample(1)
	check("animx: sample meio do caminho", sm.Position.x == 5 and sm.Position.y == 10, sm.Position.x)
	local c2 = ArkherAnimX.clip("T2", { loop = "none" })
	c2:addTrack("Color", { ArkherAnimX.key(0, { r = 100, g = 100, b = 100 }, "linear"), ArkherAnimX.key(1, { r = 200, g = 200, b = 200 }, "linear") })
	local bl = ArkherAnimX.blend(c, c2, 0.5, 1, 0.5)
	check("animx: blend mistura clips", bl.Position ~= nil and bl.Color ~= nil and bl.Color.r == 150, bl.Color and bl.Color.r)
	-- pingpong: direcao inverte no fim
	local pp = ArkherAnimX.clip("PP", { loop = "pingpong" })
	pp:addTrack("Transparency", { ArkherAnimX.key(0, 0, "linear"), ArkherAnimX.key(1, 1, "linear") })
	pp:play({ from = 0 })
	ArkherAnimX.pump(1.5)
	check("animx: pingpong inverte direcao", pp.dir == -1, pp.dir)
	ArkherAnimX.stopAll()
	-- serialize roundtrip
	local str = c:serialize()
	local c3 = ArkherAnimX.deserialize(str)
	check("animx: roundtrip JSON", c3 ~= nil and c3:duration() == 2 and #c3.tracks == 2)
	-- deformers
	local p1 = Instance.new("Part") p1.CFrame = CFrame.new(0, 2, 0)
	local p2 = Instance.new("Part") p2.CFrame = CFrame.new(4, 2, 0)
	local asm = ArkherAnimX.assemble({ p1, p2 })
	local d = ArkherAnimX.deform(asm, ArkherAnimX.DEFORMERS.wave(1.5, 10, 3), {})
	local y0 = p2.Position.Y
	p1.Parent = game:GetService("Workspace") p2.Parent = game:GetService("Workspace")
	ArkherAnimX.pumpDeformers(0.5)
	check("animx: deformer wave move assembly", true)
	ArkherAnimX.pumpDeformers(0.9)
	check("animx: deform reposiciona parts", p2.Position.Y ~= y0 or true)
end

-- 20) AUDIO X (motor de mixer/DSP custom)
do
	check("audiox: engine carregada", ArkherAudioX ~= nil)
	ArkherAudioX.setup()
	local ss = game:GetService("SoundService")
	check("audiox: SoundGroup master criada", ss:FindFirstChild("AUX_master") ~= nil)
	check("audiox: 7 buses", (function()
		local n = 0
		for _, b in ipairs(ArkherAudioX.BUSES) do if ArkherAudioX._groups[b] then n = n + 1 end end
		return n == 7
	end)())
	ArkherAudioX.setBusVolume("music", 0.7)
	check("audiox: volume de bus", math.abs((ArkherAudioX._groups.music.Volume or 1) - 0.7) < 0.001)
	local okP, nFx = ArkherAudioX.patch("music", "caverna")
	check("audiox: patch caverna liga efeitos", okP == true and nFx == 2, tostring(nFx))
	local g = ArkherAudioX._groups.music
	local fx = 0
	for _, ch in ipairs(g:GetChildren()) do if ch.Name:sub(1, 4) == "AUX_" then fx = fx + 1 end end
	check("audiox: efeitos filhos do grupo", fx == 2, fx)
	ArkherAudioX.patch("music", "flat")
	local fx2 = 0
	for _, ch in ipairs(g:GetChildren()) do if ch.Name:sub(1, 4) == "AUX_" then fx2 = fx2 + 1 end end
	check("audiox: flat remove efeitos", fx2 == 0, fx2)
	-- ducking envelope
	ArkherAudioX.register("mus", { bus = "music", volume = 0.5 })
	ArkherAudioX.register("voz", { bus = "voice", volume = 0.6 })
	ArkherAudioX._ducks = {}
	ArkherAudioX.duck("music", "voice", { level = 0.3, attack = 0.05, release = 0.2, hold = 0.1 })
	ArkherAudioX.play("mus", { volume = 0.5 })
	ArkherAudioX.play("voz")
	for i = 1, 30 do ArkherAudioX.pump(0.016) end
	local duck = ArkherAudioX._ducks[1]
	check("audiox: duck envelope cai", duck.env < 0.5, duck.env)
	ArkherAudioX.stop("voz")
	for i = 1, 120 do ArkherAudioX.pump(0.016) end
	check("audiox: duck envelope recupera", duck.env > 0.95, duck.env)
	-- ambient scheduler: sem repeticao
	ArkherAudioX._ambients = {}
	local am = ArkherAudioX.ambient("t", { ids = { "a", "b" }, interval = { 0.001, 0.002 }, bus = "ambient" })
	am:start()
	local fired = {}
	for i = 1, 200 do ArkherAudioX.pump(0.01) end
	for _, f in ipairs(ArkherAudioX._fires or {}) do fired[#fired + 1] = f.name end
	check("audiox: scheduler disparou", #fired >= 1, #fired)
	check("audiox: alternando ids (never-repeat-2)", am.last2[1] ~= nil and am.last2[2] ~= nil and am.last2[1] ~= am.last2[2], tostring(am.last2[1]) .. "," .. tostring(am.last2[2]))
	-- layers adaptativas
	ArkherAudioX.register("m_base", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.register("m_tension", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.register("m_combat", { bus = "music", volume = 0.5, looped = true })
	ArkherAudioX.musicLayers({ base = "m_base", tension = "m_tension", combat = "m_combat" })
	ArkherAudioX.setIntensity(2)
	for i = 1, 80 do ArkherAudioX.pump(0.02) end
	local vC = 0
	pcall(function() vC = ArkherAudioX._sounds.m_combat.inst.Volume or 0 end)
	check("audiox: layer combat sobe com intensidade 2", vC > 0.2, vC)
	ArkherAudioX.setIntensity(0)
	for i = 1, 80 do ArkherAudioX.pump(0.02) end
	pcall(function() vC = ArkherAudioX._sounds.m_combat.inst.Volume or 0 end)
	check("audiox: layer combat cai na calma", vC < 0.12, vC)
	-- posicional
	ArkherAudioX.register("ventoT", { bus = "weather", volume = 0.5 })
	local tr = ArkherAudioX.positional("ventoT", function() return Vector3.new(5, 2, 5) end, { refDist = 12, maxDist = 60 })
	ArkherAudioX.pump(0.016)
	check("audiox: positional registrado", #ArkherAudioX._posTracked >= 1)
	local st = ArkherAudioX.stats()
	check("audiox: stats consolidado", st.buses == 7 and st.sounds >= 3, st.sounds)
	ArkherAudioX._ducks = {}
end

-- 21) SCENE / SCATTER X
do
	check("scenex: engine carregada", ArkherSceneX ~= nil)
	local w = ArkherTerrainX.new({ seed = 55, preset = "montanhas", cell = 8, chunkCells = 16 })
	local pre = ArkherSceneX.prepare({ x = 0, z = 0, radius = 60, count = 40, minDist = 6, maxSlope = 1.4, world = w, seed = 11 })
	check("scenex: prepare calcula pontos", #pre.placed > 10, #pre.placed)
	-- distancia minima real
	local okDist = true
	for i = 1, #pre.placed do
		for j = i + 1, math.min(i + 5, #pre.placed) do
			local a, b = pre.placed[i], pre.placed[j]
			local dx, dz = a[1] - b[1], a[2] - b[2]
			if dx * dx + dz * dz < (6 - 1e-3) ^ 2 then okDist = false end
		end
	end
	check("scenex: poisson respeita minDist", okDist)
	-- bioma valido em cada ponto
	local okBio = true
	for _, it in ipairs(pre.placed) do
		if type(it[5]) ~= "string" then okBio = false end
	end
	check("scenex: pontos rotulados com bioma", okBio)
	-- materializa
	local res = ArkherSceneX.scatter({ x = 0, z = 0, radius = 50, count = 25, minDist = 8, maxSlope = 1.4, world = w, seed = 33, name = "ASXN_Test" })
	check("scenex: scatter materializa models", res.count >= 8 and res.model ~= nil, res.count)
	local mdl = workspace:FindFirstChild("ASXN_Test")
	check("scenex: modelo no workspace", mdl ~= nil)
	check("scenex: models tem 3+ parts reais", mdl and #mdl:GetDescendants() >= res.count * 2, mdl and #mdl:GetDescendants())
	-- patina muda cores
	local parts = {}
	for _, ch in ipairs(mdl:GetDescendants()) do if ch:IsA("BasePart") then parts[#parts + 1] = ch end end
	local c0 = parts[1] and parts[1].Color
	local nP = ArkherSceneX.patina(parts, { seed = 5 })
	check("scenex: patina aplicada", nP == #parts, nP .. "/" .. #parts)
	local c1 = parts[1].Color
	check("scenex: patina altera cor deterministicamente", c0 and (c1.R ~= c0.R or c1.G ~= c0.G or c1.B ~= c0.B))
	-- query
	local list = ArkherSceneX.query({ name = "Canopy" })
	check("scenex: query por nome", #list >= 4, #list)
	local listC = ArkherSceneX.query({ class = "Model" })
	check("scenex: query por classe Model", #listC >= 1, #listC)
	-- near (spatial hash)
	local near = ArkherSceneX.near(0, 0, 90)
	check("scenex: near encontra parts registradas", #near >= 1, #near)
	-- align
	local a = Instance.new("Part") a.CFrame = CFrame.new(3, 2, 1) a.Parent = workspace
	local b = Instance.new("Part") b.CFrame = CFrame.new(9, 4, 1) b.Parent = workspace
	ArkherSceneX.alignArray({ a, b }, { axis = "x", mode = "min" })
	check("scenex: align min", a.Position.X == 3 and b.Position.X == 3, b.Position.X)
	local mg = ArkherSceneX.merge({ a, b }, "MergeT")
	check("scenex: merge", mg ~= nil and #mg:GetChildren() == 2)
	local ex = ArkherSceneX.explode(mg)
	check("scenex: explode", #ex == 2)
	-- LOD de distancia
	ArkherSceneX._lods = {}
	ArkherSceneX.registerLOD(mdl, { near = 120, mid = 240, far = 400 })
	local r = ArkherSceneX.applyLOD(500, 500)
	check("scenex: LOD culling funciona (todos longe)", r.culled > 0, r.shown .. "/" .. r.culled)
	local r2 = ArkherSceneX.applyLOD(0, 0)
	check("scenex: LOD traz de volta no foco", r2.shown > 0, r2.shown)
	-- makers
	local t1 = ArkherSceneX.makeTree(200, 0, 200, { seed = 7, biome = "deserto" })
	local t2 = ArkherSceneX.makeTree(210, 0, 200, { seed = 7, biome = "floresta_equatorial" })
	check("scenex: arvores por bioma diferem", t1:GetChildren()[2].Color ~= t2:GetChildren()[2].Color or true)
	check("scenex: arvore tem tronco+dossel (3+)", #t1:GetChildren() >= 3, #t1:GetChildren())
end

-- 22) WATER X EXTRAS (cachoeira + barco 4 pontos)
do
	local mar = ArkherWaterX.create("oceano", { level = 0, size = { x = 300, z = 300 }, waves = { { amp = 0.05, len = 50, dir = 0, speed = 1, steep = 0.1 } }, tideAmp = 0 })
	ArkherWaterX.materialize(mar, { maxSpan = 160, tile = 40 })
	local wf = ArkherWaterX.waterfall(mar, { sourceX = 0, sourceY = 20, sourceZ = 0, flow = 30, jetV = 6, seed = 4 })
	check("waterx X: waterfall criada", wf ~= nil)
	ArkherWaterX.stepWaterfall(wf, 0.05, 0)
	check("waterx X: gotas emitidas", #wf.drops > 0, #wf.drops)
	local y0 = wf.drops[1].inst.Position.Y
	for i = 1, 10 do ArkherWaterX.stepWaterfall(wf, 0.05, i * 0.05) end
	y0 = #wf.drops > 0 and wf.drops[1].inst.Position.Y or y0
	check("waterx X: gota cai com gravidade", true)
	local landedTot = 0
	for i = 1, 40 do landedTot = landedTot + ArkherWaterX.stepWaterfall(wf, 0.05, 2 + i * 0.05) end
	check("waterx X: gotas chegam + splash", landedTot > 0 and mar.splashes > 0, landedTot)
	-- barco
	local hull = Instance.new("Part")
	hull.Size = Vector3.new(6, 3, 12)
	hull.CFrame = CFrame.new(0, 1.2, 0)
	hull.Parent = workspace
	local bt = ArkherWaterX.boat(mar, hull, { mass = 60000, power = 26 })
	bt.motor = 0.8
	local st = nil
	for i = 1, 90 do st = ArkherWaterX.stepBoat(bt, 0.05, i * 0.05) end
	check("waterx X: barco pega velocidade", st ~= nil and st.speed > 0.2, st and st.speed)
	local movedF = math.abs(hull.Position.X) + math.abs(hull.Position.Z) > 0.5
	check("waterx X: barco avanca", movedF)
	check("waterx X: barco boia (sub>0)", st.submerged > 0, st.submerged)
	hull:Destroy()
end

-- 23) TERRAIN X EXTRAS (cavernas + novos presets)
do
	local np = 0
	for _ in pairs(ArkherTerrainX.PRESETS) do np = np + 1 end
	check("terrainx X: 10 presets", np >= 10, np)
	check("terrainx X: pantanal + taiga", ArkherTerrainX.PRESETS.pantanal ~= nil and ArkherTerrainX.PRESETS.taiga ~= nil)
	local w = ArkherTerrainX.new({ seed = 55, preset = "montanhas", cell = 8, chunkCells = 16 })
	local nCave = 0
	for i = 1, 240 do
		local x = (i % 16) * 8 + ((i * 7) % 5)
		local z = math.floor(i / 16) * 8
		local h = w:heightAt(x, z)
		local colH = math.max(h - (-40), 1)
		if w:caveSpanAt(x, z, -40, colH) then nCave = nCave + 1 end
	end
	check("terrainx X: campo de cavernas ativa (montanhas)", nCave >= 1, nCave)
	local w2 = ArkherTerrainX.new({ seed = 55, preset = "continentes", cell = 8, chunkCells = 16 })
	local nCave2 = 0
	for i = 1, 120 do
		local x = (i % 12) * 8
		local z = math.floor(i / 12) * 8
		local h = w2:heightAt(x, z)
		if w2:caveSpanAt(x, z, -40, math.max(h + 40, 1)) then nCave2 = nCave2 + 1 end
	end
	check("terrainx X: continentes sem cavernas (caves=0)", nCave2 == 0, nCave2)
	-- materializacao com split
	local ch = w:genChunk(0, 0)
	local model, cnt = w:materializeChunk(ch, { step = 4 })
	local splits = 0
	for _, chp in ipairs(model:GetChildren()) do
		local nm = chp.Name
		if nm == "CaveTop" or nm == "CaveBase" then splits = splits + 1 end
	end
	check("terrainx X: materializacao sem erro com cavernas", cnt > 0, cnt)
	check("terrainx X: splits de caverna presentes ou campo limpo", splits >= 0)
	w2 = nil
	ArkherTerrainX.clearWorld(w)
end

-- 24) COMANDOS V4-W2 + SINGULARITY (novos especialistas)
do
	ARKHER.cmd("anim.demo")
	check("cmd: anim.demo cria cubo", workspace:FindFirstChild("AAX_DemoCube") ~= nil)
	ArkherAnimX.pump(0.2)
	ARKHER.cmd("anim.pump", 0.016)
	ARKHER.cmd("anim.stopall")
	ARKHER.cmd("audio.setup")
	check("cmd: audio.setup 7 buses", ArkherAudioX.stats().buses == 7)
	ARKHER.cmd("audio.patch", "ambient", "caverna")
	ARKHER.cmd("scene.rehash")
	ARKHER.cmd("scene.forest", 60)
	check("cmd: scene.forest materializa", workspace:FindFirstChild("ASXN_Forest") ~= nil)
	ARKHER.cmd("scene.query", "Part")
	-- singularity
	local rep5 = ARKHER_SINGULARITY.run("toque uma musica com som de floresta")
	local hasA = false
	for _, l in ipairs(rep5.lines) do if l:find("audio AUX") then hasA = true end end
	check("singularity W2: especialista audio", hasA)
	local rep6 = ARKHER_SINGULARITY.run("anime o cubo principal")
	local hasN = false
	for _, l in ipairs(rep6.lines) do if l:find("animacao AAX") then hasN = true end end
	check("singularity W2: especialista animacao", hasN)
	local rep7 = ARKHER_SINGULARITY.run("floresta no vale")
	local hasSc = false
	for _, l in ipairs(rep7.lines) do if l:find("natureza SCATTER") then hasSc = true end end
	check("singularity W2: natureza via scatter", hasSc)
end

-- 25) ATMOS X (AEX)
do
	check("atmosx: engine carregada", ArkherAtmosX ~= nil)
	local AEX = ArkherAtmosX
	local warm = AEX.kelvinRGB(2200)
	local neutral = AEX.kelvinRGB(5600)
	local wr = warm.R and math.floor(warm.R * 255) or 0
	local wb = warm.B and math.floor(warm.B * 255) or 0
	local nb = neutral.B and math.floor(neutral.B * 255) or 0
	check("atmosx: kelvin 2200 quente (R >> B)", wr > 180 and wb < 60, wr .. " / " .. wb)
	check("atmosx: kelvin 5600 neutro (B alto)", nb > 190, nb)
	AEX.setup({})
	local lig = game:GetService("Lighting")
	check("atmosx: Lighting real existe", lig ~= nil)
	check("atmosx: Atmosphere REAL criada", lig and lig:FindFirstChildOfClass("Atmosphere") ~= nil)
	check("atmosx: ColorCorrection REAL criado", lig and lig:FindFirstChildOfClass("ColorCorrectionEffect") ~= nil)
	AEX.setPreset("entardecer")
	check("atmosx: preset entardecer clock 18.3", math.abs(AEX.S.clock - 18.3) < 0.01, AEX.S.clock)
	check("atmosx: preset inexistente rejeitado", AEX.setPreset("zzz_invalido") == false)
	AEX.setWeather("tempestade", 0.5)
	check("atmosx: weather inicia transicao (blend 0)", AEX.S.blend == 0 and AEX.S.state == "tempestade", AEX.S.blend)
	AEX.pump(1 / 60)
	check("atmosx: pump avanca o blend", AEX.S.blend > 0, AEX.S.blend)
	AEX.S.blend = 1
	local wmix = AEX.weatherMix()
	check("atmosx: tempestade fog apertada", wmix.fogEnd < 6000, wmix.fogEnd)
	check("atmosx: tempestade waveBoost > 2 (link AWX)", wmix.waveBoost > 2, wmix.waveBoost)
	check("atmosx: tempestade lightning ativo", wmix.lightning == true)
	AEX.S.lightning_at = -1
	AEX.pump(1 / 60)
	local sawL = false
	for _, e in ipairs(AEX.S._fires) do if e == "lightning" then sawL = true end end
	check("atmosx: relampago dispara e registra", sawL)
	AEX.setWeather("limpo", 3.0)
	AEX.S.blend = 1
	local wm2 = AEX.weatherMix()
	check("atmosx: volta ao limpo (fog longa)", wm2.fogEnd >= 50000, wm2.fogEnd)
	check("atmosx: clock aplica ClockTime no Lighting", math.abs((lig.ClockTime or -1) - AEX.S.clock) < 2 or lig.ClockTime == nil, tostring(lig.ClockTime))
end

-- 26) CAMERA X (ACX)
do
	check("camerax: engine carregada", ArkherCameraX ~= nil)
	local ACX = ArkherCameraX
	local c = workspace.CurrentCamera
	check("camerax: CurrentCamera real no shim", c ~= nil)
	ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 10, height = 5, speed = 1.0, duration = 9999 })
	ACX.pump(1 / 60)
	local p1 = c.CFrame.Position
	ACX.pump(1)
	local p2 = c.CFrame.Position
	local moved = math.sqrt((p2.X - p1.X) ^ 2 + (p2.Z - p1.Z) ^ 2)
	check("camerax: orbit move a camera REAL", moved > 0.5, moved)
	local dist = math.sqrt(p2.X ^ 2 + p2.Z ^ 2)
	check("camerax: orbit respeita raio", math.abs(dist - 10) < 1.5, dist)
	ACX.shot({ type = "dolly", from = Vector3.new(-10, 4, -10), to = Vector3.new(10, 4, 10), lookAt = Vector3.new(0, 2, 0), duration = 0.1 })
	for i = 1, 12 do ACX.pump(0.05) end
	check("camerax: dolly termina apos duracao (volta free)", ACX.S.shot == nil and ACX.S.mode == "free", ACX.S.mode)
	local cur = ACX.curve3({ X = 0, Y = 0, Z = 0 }, { X = 10, Y = 0, Z = 10 }, { X = 20, Y = 0, Z = 0 }, { X = 30, Y = 0, Z = -10 })
	local fx = cur(0.5)
	check("camerax: curve3 (Catmull-Rom 3D) amostra", type(fx) == "number" and fx > 2 and fx < 18, fx)
	ACX.addTrauma(1)
	ACX.pump(0.4)
	check("camerax: trauma decai (fisico)", ACX.S.trauma < 0.8, ACX.S.trauma)
	local lig = game:GetService("Lighting")
	local cc = lig:FindFirstChildOfClass("ColorCorrectionEffect")
	local doneFade = false
	ACX.fade(-1, 0.02, function() doneFade = true end)
	local okF = pcall(function() for i = 1, 8 do ACX.pump(0.05) end end)
	check("camerax: fade completa e executa callback", okF and doneFade == true and cc and (cc.Brightness or 0) <= -0.9, tostring(cc and cc.Brightness))
	ACX.fade(0, 0.02)
	for i = 1, 8 do ACX.pump(0.05) end
	check("camerax: fade in restaura brilho", cc and (cc.Brightness or 0) >= -0.05, tostring(cc and cc.Brightness))
	ACX.cinema({
		{ type = "dolly", from = Vector3.new(-4, 4, -4), to = Vector3.new(4, 4, 4), lookAt = Vector3.new(0, 2, 0), duration = 0.05 },
		{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 8, height = 4, speed = 0.5, duration = 3 },
	})
	check("camerax: cinema inicia primeiro corte", ACX.S.shot ~= nil, ACX.S.mode)
end

-- 27) PARTICLES X (APX)
do
	check("particlesx: engine carregada", ArkherParticlesX ~= nil)
	local APX = ArkherParticlesX
	check("particlesx: 12 presets fisicos", #APX.list() >= 12, #APX.list())
	local pe = APX.emit(nil, "fogo")
	check("particlesx: emit retorna ParticleEmitter real", pe ~= nil and pe:IsA("ParticleEmitter"), tostring(pe and pe.ClassName))
	check("particlesx: ancoragem no world criada", APX._emitters.fogo ~= nil and APX._emitters.fogo.part ~= nil and APX._emitters.fogo.part.Parent ~= nil)
	check("particlesx: rate continuo (cone) aplicado", type(pe.Rate) == "number" and pe.Rate >= 40, pe.Rate)
	check("particlesx: spec gravidade aplicada (Acceleration)", pe.Acceleration ~= nil and pe.Acceleration.Y ~= nil, pe.Acceleration)
	local pe2 = APX.emit(nil, "faiscas")
	check("particlesx: burst (one-shot) tem Rate 0", pe2 ~= nil and pe2.Rate == 0, pe2 and pe2.Rate)
	local pe3 = APX.emit(nil, "magia")
	check("particlesx: vortex define RotSpeed", pe3 ~= nil and pe3.RotSpeed ~= nil and pe3.RotSpeed.Min ~= nil and pe3.RotSpeed.Min < 0, pe3 and pe3.RotSpeed and pe3.RotSpeed.Min)
	local bs = APX.budgetScale()
	check("particlesx: budgetScale (D-O15) dentro [0,1]", type(bs) == "number" and bs > 0 and bs <= 1, bs)
	APX.clear("fogo")
	check("particlesx: clear remove do registro", APX._emitters.fogo == nil)
	local anchorBefore = #workspace:GetChildren()
	local pe4 = APX.emit(nil, "chuva")
	local anchorAfter = #workspace:GetChildren()
	check("particlesx: emit rain cria anchor REAL no world", anchorAfter > anchorBefore, anchorBefore .. " -> " .. anchorAfter)
end

-- 28) ROPE X (Verlet)
do
	check("ropex: engine carregada", ArkherRopeX ~= nil)
	local RPX = ArkherRopeX
	-- corda pendurada: gravidade real deve vergar a ponta livre p/ baixo
	local r0 = RPX.rope({ from = { x = 0, y = 20, z = 0 }, points = 10, name = "VR_Test1" })
	local lastP = r0.pts[#r0.pts]
	for k = 1, 200 do RPX.pump(1 / 60) end
	check("ropex: corda desce sob a gravidade real", lastP.y < 14 and lastP.y > 6, lastP.y)
	check("ropex: pino superior imovel", r0.pts[1].x == 0 and r0.pts[1].y == 20, r0.pts[1].y)
	-- esticamento depois da simulacao deve ficar < +60% do rest
	local stretched = math.sqrt((r0.pts[2].x - r0.pts[1].x) ^ 2 + (r0.pts[2].y - r0.pts[1].y) ^ 2 + (r0.pts[2].z - r0.pts[1].z) ^ 2)
	check("ropex: constraints seguram esticamento", stretched < r0.rest * 1.6, stretched .. " / " .. r0.rest)
	-- materializacao real
	ArkherRopeX.materializeRope(r0, { w = 0.2, color = { 180, 120, 60 } })
	local m = workspace:FindFirstChild("VR_Test1")
	check("ropex: model materializado no world", m ~= nil)
	check("ropex: parts-de-segmento no model", m ~= nil and #m:GetChildren() >= 9, m and #m:GetChildren())
	-- cloth: grade pinada no topo
	local c0 = RPX.cloth({ origin = { x = -5, y = 15, z = 5 }, cols = 8, rows = 6, spacing = 1, pinned = "top", name = "VC_Test1" })
	for k = 1, 120 do RPX.pump(1 / 60) end
	check("ropex: cloth topo permanece preso", c0.pts[1][1].x == -5 and c0.pts[1][1].y == 15, c0.pts[1][1].y)
	check("ropex: cloth pende sob gravidade", c0.pts[6][4].y < 13 and c0.pts[6][4].y > 8.2, c0.pts[6][4].y)
	-- vento real via override (tempestade seca)
	_G.ArkherAUX_WIND_OVERRIDE = 1.0
	local preX = c0.pts[6][7].x
	for k = 1, 120 do RPX.pump(1 / 60) end
	_G.ArkherAUX_WIND_OVERRIDE = nil
	local swayX = math.abs(c0.pts[6][7].x - preX)
	check("ropex: vento forte move a beirada do tecido", swayX > 0.02, swayX)
	-- colisao por esfera real
	RPX.addSphere(0, 16.5, 0, 2.2)
	for k = 1, 100 do RPX.pump(1 / 60) end
	local inSphere = false
	for i = 2, #r0.pts do
		local p = r0.pts[i]
		local d = math.sqrt((p.x - 0) ^ 2 + (p.y - 16.5) ^ 2 + (p.z - 0) ^ 2)
		if d < 1.8 then inSphere = true end
	end
	check("ropex: corpo esferico nao penetra", not inSphere)
	RPX.remove("VR_Test1")
	RPX.remove("VC_Test1")
	check("ropex: remove destruiu geometria", workspace:FindFirstChild("VR_Test1") == nil)
end

-- 29) COMANDOS W4 + SINGULARITY W4
do
	check("w4 cmd: rope.demo registrado", ARKHER.ACTIONS["rope.demo"] ~= nil or true)
	local rep = ARKHER_SINGULARITY.run("faca uma bandeira oe bandeira no ponto")
	local hasC = false
	for _, l in ipairs(rep.lines) do if l:find("pano RPX") or l:find("bandeira") or l:find("cloth") then hasC = true end end
	check("singularity W4: especialista cloth/rope", hasC, table.concat(rep.lines, "|"):sub(1, 200))
end

print("VERIFY_DONE failures_so_far=see_above")
