--[[ ARKHER V4 — LocalScript. Requer os kits (ReplicatedStorage.ArkherV3.ArkherKit_B/C/D/E). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	for _, kn in ipairs({ "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E" }) do
		local m = folder and folder:FindFirstChild(kn)
		if not m then m = script:FindFirstChild(kn) end
		if not m then m = script.Parent and script.Parent:FindFirstChild(kn) end
		if not m then
			error("[ARKHER] " .. kn .. " nao encontrado: rode os installers A+B+C+D+E primeiro.")
		end
		require(m)
	end
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER — UI: SCRIPT STUDIO (IDE completa, backend ArkherScripterX) ]]
-- IDE profissional: multi-documento (tabs), highlight REAL por tokenizer,
-- lint REAL (balanceamento de blocos/variaveis/deprecais), autocomplete pelo
-- banco da API Roblox + doc, outline de funcoes, find/replace, snippets (45),
-- templates (30), compile-check, create-in-place real, export, metricas.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")
local SX = ArkherScripterX
local MONO = ARKHER.MONO or ARKHER.FONT

local THM = {}
for k2, v in pairs(SX.THEME) do THM[k2] = C(v) end

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT STUDIO — IDE Luau", 28, 318, 720, 520, { pin = true })
	K.f(head, "Acc", 0, 24, 720, 2, ACCENT)

	-- ================= DOCUMENTOS =================
	local docs = {}
	local active = 1
	local scrollTop = 0
	local curLine = 1
	local status = nil
	local lintBody = nil
	local outlineBody = nil
	local acPopup = nil
	local codeFrame = nil
	local VISIBLE = 18
	local LINE_H = 15
	-- funcoes da tela (pre-declaradas p/ closures cruzadas)
	local repaintTabs, repaintCode, relintBody, repaintPanel, repaintStatus, repaintAll
	local openLineEditor, pushUndo, refreshAC

	local function newDoc(name, class, src)
		docs[#docs + 1] = { name = name, class = class or "Script", src = src or ("-- " .. name .. " (Script)\n\n"), undo = {}, dirty = false }
		return docs[#docs]
	end
	newDoc("Main", "Script", SX.template("basico").src)
	newDoc("Cliente", "LocalScript", SX.template("local_basico").src)
	newDoc("Fisica", "ModuleScript", SX.template("oop_classe").src)
	local function doc() return docs[active] end

	-- ================= TOOLBAR =================
	local nameBox = K.input(root, 10, 34, 130, 22, "nome")
	nameBox.Text = doc().name
	nameBox.FocusLost:Connect(function(enter)
		if enter and #nameBox.Text > 0 then doc().name = nameBox.Text repaintTabs() end
	end)
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }
	K.tabs(root, 148, 34, 230, CLASSES, 1, function(idx)
		doc().class = CLASSES[idx]
		repaintStatus()
	end)
	local TARGETS = { "Workspace", "ServerScriptService", "StarterPlayerScripts", "StarterGui", "ReplicatedStorage" }
	local targetIdx = 1
	local tgtLbl = K.txt(root, TARGETS[1], 386, 38, 140, 16, 9, T.txt3)
	local tgt = K.btn(root, "Tgt", 524, 34, 28, 22, T.bg2, 4)
	K.txtS(tgt, "<>", 10, ACCENT)
	tgt.MouseButton1Click:Connect(function()
		targetIdx = (targetIdx % #TARGETS) + 1
		tgtLbl.Text = TARGETS[targetIdx]
	end)
	local compile = K.btn(root, "Comp", 560, 34, 70, 22, T.bg2, 4)
	K.txtS(compile, "Compilar", 9, T.txt)
	K.hover(compile, T.bg2, T.hover)
	local aiGen = K.btn(root, "AI", 638, 34, 74, 22, T.purple, 4)
	K.txtS(aiGen, "Gerar p/ IA", 9, C("#FFF"))
	K.hover(aiGen, T.purple, C("#A97AFF"))

	-- ================= TABS DE DOCUMENTOS =================
	local tabBar = K.f(root, "Tabs", 10, 62, 580, 24, T.bg4)
	K.corner(tabBar, 4)
	repaintTabs = function()
		for _, ch2 in ipairs(tabBar:GetChildren()) do if ch2:IsA("GuiObject") then ch2:Destroy() end end
		local x = 4
		for i, d in ipairs(docs) do
			local w = 26 + #d.name * 6
			local b = K.btn(tabBar, "D" .. i, x, 2, w, 20, i == active and T.bg2 or T.bg4, 4)
			K.txtS(b, d.name .. (d.dirty and " *" or ""), 9, i == active and T.txt or T.txt3)
			local idx = i
			b.MouseButton1Click:Connect(function()
				active = idx
				nameBox.Text = docs[active].name
				scrollTop = 0
				repaintAll()
			end)
			x = x + w + 4
		end
	end
	local plus = K.btn(root, "Plus", 596, 62, 56, 24, T.bg2, 4)
	K.txtS(plus, "+ novo", 9, T.txt)
	K.hover(plus, T.bg2, T.hover)
	plus.MouseButton1Click:Connect(function()
		newDoc("Doc" .. (#docs + 1), "Script", "-- novo documento\n\n")
		active = #docs
		repaintAll()
	end)
	local cls = K.btn(root, "Cls", 658, 62, 52, 24, T.bg2, 4)
	K.txtS(cls, "fechar", 9, T.txt3)
	K.hover(cls, T.bg2, T.hover)
	cls.MouseButton1Click:Connect(function()
		if #docs > 1 then
			table.remove(docs, active)
			active = math.min(active, #docs)
			repaintAll()
		end
	end)

	-- ================= AREA DE CODIGO (highlight real) =================
	codeFrame = K.f(root, "Code", 10, 92, 582, 276, T.bg0)
	K.corner(codeFrame, 4)
	K.stroke(codeFrame, T.line, 1)
	-- numeros de linha
	local gutter = K.f(codeFrame, "G", 0, 0, 34, 276, T.bg3)
	-- src do doc como tabela de linhas
	local function linesOf(src)
		local out = {}
		for l in (src .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
		return out
	end
	local function joinLines(t2) return table.concat(t2, "\n") end


	local function commitEdit()
		doc().dirty = true
		repaintCode()
		relintBody()
		repaintTabs()
		repaintStatus()
	end

	repaintCode = function()
		for _, ch2 in ipairs(codeFrame:GetChildren()) do
			if ch2.Name ~= "G" then ch2:Destroy() end
		end
		gutter:ClearAllChildren()
		local hl = SX.highlightLines(doc().src)
		local srcLines = linesOf(doc().src)
		for i = 1, VISIBLE do
			local li = scrollTop + i
			if li > #srcLines then break end
			local y = 4 + (i - 1) * LINE_H
			K.txt(gutter, string.format("%2d", li), 0, y, 30, LINE_H - 1, 8, li == curLine and ACCENT or T.txt4, MONO, Enum.TextXAlignment.Right)
			-- click editor da linha
			local row = K.btn(codeFrame, "R" .. i, 36, y, 540, LINE_H - 1, li == curLine and T.bg2 or T.bg0, 0)
			row.BackgroundTransparency = li == curLine and 0.5 or 1
			local idx = li
			row.MouseButton1Click:Connect(function()
				curLine = idx
				openLineEditor(idx)
				repaintCode()
				repaintStatus()
			end)
			-- segmentos coloridos
			if hl[li] then
				local x = 4
				for _, seg in ipairs(hl[li]) do
					local segW = math.max(2, #seg[1] * 6.05)
					local t3 = K.txt(row, seg[1], x, 0, segW + 8, LINE_H - 1, 10, THM[seg[2]] or T.txt2, MONO)
					x = x + seg[1]:gsub("\t", "    "):len() * 6.05
				end
			end
		end
	end
	-- scroll por botoes
	local up = K.btn(root, "Up", 596, 92, 56, 22, T.bg2, 4)
	K.txtS(up, "▲", 11, T.txt3)
	local dn = K.btn(root, "Dn", 596, 118, 56, 22, T.bg2, 4)
	K.txtS(dn, "▼", 11, T.txt3)
	local page = K.btn(root, "Pg", 596, 144, 56, 22, T.bg2, 4)
	K.txtS(pg, "▼▼", 11, T.txt3)
	up.MouseButton1Click:Connect(function() scrollTop = math.max(0, scrollTop - 1) repaintCode() end)
	dn.MouseButton1Click:Connect(function() scrollTop = scrollTop + 1 repaintCode() end)
	page.MouseButton1Click:Connect(function() scrollTop = scrollTop + VISIBLE repaintCode() end)
	local home = K.btn(root, "Hm", 596, 170, 56, 22, T.bg2, 4)
	K.txtS(home, "Topo", 9, T.txt3)
	home.MouseButton1Click:Connect(function() scrollTop = 0 repaintCode() end)

	-- editor inline da linha
	local editBox = nil
	openLineEditor = function(li)
		if editBox then editBox:Destroy() editBox = nil end
		local rel = li - scrollTop
		if rel < 1 or rel > VISIBLE then return end
		local srcLines = linesOf(doc().src)
		local y = 4 + (rel - 1) * LINE_H
		editBox = Instance.new("TextBox")
		editBox.Name = "LineEdit"
		editBox.Parent = codeFrame
		editBox.Position = UDim2.new(0, 36, 0, y)
		editBox.Size = UDim2.new(0, 540, 0, LINE_H + 2)
		editBox.BackgroundColor3 = T.bg2
		editBox.TextColor3 = T.txt
		editBox.TextSize = 10
		editBox.Font = MONO
		editBox.Text = srcLines[li] or ""
		editBox.ClearTextOnFocus = false
		editBox.BorderSizePixel = 0
		editBox.FocusLost:Connect(function(enter)
			if enter and editBox then
				local lns = linesOf(doc().src)
				lns[li] = editBox.Text
				doc().src = joinLines(lns)
				commitEdit()
				refreshAC()
			end
			if editBox then editBox:Destroy() editBox = nil end
		end)
	end

	-- editor FULL (documento inteiro)
	local fullBtn = K.btn(root, "Full", 596, 196, 56, 22, T.bg2, 4)
	K.txtS(fullBtn, "Full", 9, T.txt3)
	K.hover(fullBtn, T.bg2, T.hover)
	local fullOpen = false
	fullBtn.MouseButton1Click:Connect(function()
		fullOpen = not fullOpen
		if fullOpen then
			local box = Instance.new("TextBox")
			box.Name = "FullEdit"
			box.Parent = codeFrame
			box.Position = UDim2.new(0, 36, 0, 2)
			box.Size = UDim2.new(0, 540, 0, 272)
			box.BackgroundColor3 = T.bg4
			box.TextColor3 = T.txt
			box.TextSize = 10
			box.Font = MONO
			box.MultiLine = true
			box.TextXAlignment = Enum.TextXAlignment.Left
			box.TextYAlignment = Enum.TextYAlignment.Top
			box.Text = doc().src
			box.ClearTextOnFocus = false
			box.FocusLost:Connect(function(enter)
				if enter then doc().src = box.Text commitEdit() end
			end)
		else
			local fe = codeFrame:FindFirstChild("FullEdit")
			if fe then fe:Destroy() end
			repaintCode()
		end
	end)
	local undoB = K.btn(root, "Ud", 596, 222, 56, 22, T.bg2, 4)
	K.txtS(undoB, "Undo", 9, T.txt3)
	local redoHint = K.txt(root, "Ctrl+Z do Studio", 596, 248, 60, 12, 7, T.txt4)
	undoB.MouseButton1Click:Connect(function()
		local stack = doc().undo
		if #stack > 0 then
			doc().src = table.remove(stack)
			commitEdit()
			status.Text = "undo do documento (stack local)"
		else
			status.Text = "nada p/ desfazer neste documento"
		end
	end)
	local fmt2 = K.btn(root, "Fm", 596, 264, 56, 22, T.bg2, 4)
	K.txtS(fmt2, "Format", 9, T.txt3)
	fmt2.MouseButton1Click:Connect(function()
		pushUndo()
		doc().src = SX.format(doc().src)
		commitEdit()
		status.Text = "formatado (indentacao por profundidade de bloco)"
	end)
	pushUndo = function()
		local stack = doc().undo
		stack[#stack + 1] = doc().src
		if #stack > 30 then table.remove(stack, 1) end
	end

	-- ================= AUTOCOMPLETE =================
	acPopup = K.f(root, "AC", 660, 92, 52, 0)
	refreshAC = function()
		-- popup real aparece perto do rodape (nao usado inline; a lista completa esta na aba COMPLETE)
	end

	-- ================= PAINEL INFERIOR ESQ: LINT (REAL) =================
	local lintF = K.f(root, "Lint", 10, 374, 286, 102, T.bg4)
	K.corner(lintF, 4)
	local lintHead = K.txt(lintF, "LINT", 8, 4, 60, 14, 10, T.txt3, ARKHER.FONTB)
	lintBody = K.f(lintF, "LB", 8, 20, 270, 76)
	relintBody = function()
		lintHead.Text = "LINT"
		lintBody:ClearAllChildren()
		local diags = SX.lint(doc().src)
		local sum = SX.lintSummary(diags)
		lintHead.Text = "LINT — " .. sum.errors .. " erros, " .. sum.warns .. " avisos"
		lintHead.TextColor3 = sum.errors > 0 and C("#E05252") or (sum.warns > 0 and C("#FFD93D") or C("#37C85C"))
		local shown = 0
		for _, d in ipairs(diags) do
			if shown >= 4 then break end
			shown = shown + 1
			local col = d.sev == "error" and C("#E05252") or d.sev == "warn" and C("#FFD93D") or T.txt4
			local lbl2 = K.txt(lintBody, "[" .. d.line .. "] " .. d.msg, 2, (shown - 1) * 16, 262, 14, 8, col)
			lbl2.TextTruncate = Enum.TextTruncate.AtEnd
		end
		if shown == 0 then K.txt(lintBody, "codigo limpo — nenhuma inconsistencia", 2, 0, 240, 14, 9, C("#37C85C")) end
	end

	-- ================= PAINEL INF INF: FIND/REPLACE + STATS =================
	local fr = K.f(root, "FR", 306, 374, 286, 102, T.bg4)
	K.corner(fr, 4)
	K.txt(fr, "BUSCAR / SUBSTITUIR", 8, 4, 200, 14, 10, T.txt3, ARKHER.FONTB)
	local findBox = K.input(fr, 8, 22, 128, 20, "buscar")
	local repBox = K.input(fr, 142, 22, 128, 20, "substituir")
	local frOut = K.txt(fr, "", 8, 82, 260, 14, 9, T.txt4)
	local findB = K.btn(fr, "FB", 8, 48, 84, 20, T.bg2, 4)
	K.txtS(findB, "Buscar", 9, T.txt)
	local repB = K.btn(fr, "RB", 96, 48, 84, 20, T.bg2, 4)
	K.txtS(repB, "Substituir", 9, T.txt)
	local allB = K.btn(fr, "AB", 184, 48, 86, 20, T.bg2, 4)
	K.txtS(allB, "Substituir tudo", 8, T.txt)
	findB.MouseButton1Click:Connect(function()
		local hits = SX.findAll(doc().src, findBox.Text, {})
		frOut.Text = #hits .. " ocorrencias de '" .. findBox.Text .. "'"
	end)
	repB.MouseButton1Click:Connect(function()
		pushUndo()
		local hits = SX.findAll(doc().src, findBox.Text, {})
		if #hits > 0 then
			local before = hits[1]
			local s = doc().src
			doc().src = s:sub(1, before.a - 1) .. repBox.Text .. s:sub(before.b + 1)
			commitEdit()
			frOut.Text = "substituido 1 de " .. #hits
		end
	end)
	allB.MouseButton1Click:Connect(function()
		pushUndo()
		local new, n = SX.replace(doc().src, findBox.Text, repBox.Text, {})
		doc().src = new
		commitEdit()
		frOut.Text = n .. " substituicoes feitas"
	end)

	-- ================= PAINEL DIR: OUTLINE + COMPLETE + SNIPPETS + TEMPLATES =================
	-- painel direito: outline / completar / snippets / templates

	local panel = K.f(root, "P", 604, 92, 108, 384, T.bg4)
	K.corner(panel, 4)
	local PTABS = { "Outline", "Completar", "Snippets", "Templates" }
	local pTab = 2
	local pBody = K.f(panel, "PB", 4, 24, 100, 356)
	local pBtns = {}
	local function selectPTab(i)
		pTab = i
		for j, b in ipairs(pBtns) do b.BackgroundColor3 = j == i and T.bg2 or T.bg4 end
		repaintPanel()
	end
	for i, nm in ipairs(PTABS) do
		local b = K.btn(panel, "PT" .. i, 4 + (i - 1) * 26, 4, 24, 18, T.bg4, 3)
		K.txtS(b, nm:sub(1, 2), 8, i == pTab and ACCENT or T.txt3)
		local idx = i
		b.MouseButton1Click:Connect(function() selectPTab(idx) end)
		pBtns[i] = b
	end
	local panelPage = 0
	repaintPanel = function()
		pBody:ClearAllChildren()
		if pTab == 1 then
			local items = SX.outline(doc().src)
			if #items == 0 then K.txt(pBody, "sem funcoes", 4, 0, 90, 14, 9, T.txt4) end
			for i = 1, math.min(#items, 20) do
				local it = items[i]
				local b = K.btn(pBody, "O" .. i, 4, (i - 1) * 17, 92, 15, T.bg4, 2)
				K.txt(b, string.rep(" ", it.depth * 2) .. "f " .. it.name, 4, 1, 84, 13, 8, T.txt2)
				K.txt(b, tostring(it.line), 64, 1, 26, 13, 7, T.txt4, FONT, Enum.TextXAlignment.Right)
				local ln = it.line
				b.MouseButton1Click:Connect(function()
					curLine = ln
					scrollTop = math.max(0, ln - 4)
					repaintCode()
					repaintStatus()
				end)
			end
		elseif pTab == 2 then
			K.txt(pBody, "prefixo:", 4, 0, 90, 14, 9, T.txt4)
			local pf = K.input(pBody, 4, 15, 92, 18, "Get, Inst, task...")
			local list = K.f(pBody, "L", 4, 38, 92, 200)
			local function showAC()
				list:ClearAllChildren()
				local res = SX.complete(pf.Text, doc().src)
				for i = 1, math.min(#res, 11) do
					local r = res[i]
					K.txt(list, r.label, 2, (i - 1) * 17, 92, 15, 9, r.kind == "keyword" and C("#C792EA") or r.kind == "service" and C("#5AD4E6") or T.txt2)
					K.txt(list, r.kind, 2, (i - 1) * 17 + 0, 100, 15, 7, T.txt4, FONT, Enum.TextXAlignment.Right)
				end
			end
			pf:GetPropertyChangedSignal("Text"):Connect(showAC)
			showAC()
		elseif pTab == 3 then
			local base = panelPage * 11
			for i = 1, 11 do
				local sn = SX.SNIPPETS[base + i]
				if not sn then break end
				local b = K.btn(pBody, "S" .. i, 4, (i - 1) * 17, 92, 15, T.bg4, 2)
				K.txt(b, sn.nm, 4, 1, 84, 13, 8, T.txt2)
				local id = sn.id
				b.MouseButton1Click:Connect(function()
					pushUndo()
					local lns = linesOf(doc().src)
					-- insere snippet na linha atual
					local snip = nil
					for _, s2 in ipairs(SX.SNIPPETS) do if s2.id == id then snip = s2 end end
					if snip then
						local cur = lns[curLine] or ""
						lns[curLine] = cur .. "\n" .. snip.code
						doc().src = joinLines(lns)
						commitEdit()
						status.Text = "snippet '" .. snip.nm .. "' inserido na linha " .. curLine
					end
				end)
			end
			local pg = K.btn(pBody, "PgS", 4, 190, 92, 16, T.bg2, 3)
			K.txtS(pg, "prox >", 9, T.txt3)
			pg.MouseButton1Click:Connect(function()
				panelPage = (panelPage + 1) % math.ceil(#SX.SNIPPETS / 11)
				repaintPanel()
			end)
		elseif pTab == 4 then
			local base = panelPage * 9
			for i = 1, 9 do
				local tp = SX.TEMPLATES[base + i]
				if not tp then break end
				local b = K.btn(pBody, "T" .. i, 4, (i - 1) * 19, 92, 17, T.bg4, 2)
				K.txt(b, tp.nm, 4, 2, 84, 14, 8, T.txt2)
				local id = tp.id
				b.MouseButton1Click:Connect(function()
					pushUndo()
					local tp2 = SX.template(id)
					doc().src = tp2.src
					doc().class = tp2.cls
					commitEdit()
					status.Text = "template '" .. tp2.nm .. "' carregado (" .. tp2.cls .. ")"
				end)
			end
			local pg = K.btn(pBody, "PgT", 4, 172, 92, 16, T.bg2, 3)
			K.txtS(pg, "prox >", 9, T.txt3)
			pg.MouseButton1Click:Connect(function()
				panelPage = (panelPage + 1) % math.ceil(#SX.TEMPLATES / 9)
				repaintPanel()
			end)
		end
	end

	-- ================= BASE: ACOES DE ARQUIVO =================
	local bar = K.f(root, "Bar", 10, 482, 702, 30, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "Ln 1, Col 1", 10, 8, 240, 14, 9, T.txt3)
	repaintStatus = function()
		local m = SX.metrics(doc().src)
		local diags = SX.lint(doc().src)
		local sum = SX.lintSummary(diags)
		status.Text = "Ln " .. curLine .. " | " .. doc().class .. " | " .. m.lines .. " linhas | " .. m.chars .. " chars | " .. m.functions .. " fns | cx " .. m.complexity .. " | " .. sum.errors .. "err/" .. sum.warns .. "warn"
	end
	local create = K.btn(bar, "Create", 440, 4, 90, 22, ACCENT, 4)
	K.txtS(create, "Criar no Place", 9, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local target
		pcall(function() target = game:GetService(TARGETS[targetIdx]) end)
		if not target and TARGETS[targetIdx] == "StarterPlayerScripts" then
			local ok2, sp = pcall(function() return game:GetService("StarterPlayer") end)
			if ok2 and sp then
				target = sp:FindFirstChild("StarterPlayerScripts")
				if not target then
					target = Instance.new("Folder")
					target.Name = "StarterPlayerScripts"
					target.Parent = sp
				end
			end
		end
		target = target or workspace
		local base = doc().name
		local n = 1
		while target:FindFirstChild(base) do n = n + 1 base = doc().name .. "_" .. n end
		local sc = Instance.new(doc().class)
		sc.Name = base
		sc.Source = doc().src
		sc.Parent = target
		doc().dirty = false
		ARKHER.out("SUCCESS", "Script Studio: " .. doc().class .. " '" .. base .. "' criado em " .. TARGETS[targetIdx])
		K.notify("Script criado", base .. " → " .. TARGETS[targetIdx], "ok")
		repaintTabs()
	end)
	local exp = K.btn(bar, "Exp", 538, 4, 80, 22, T.bg2, 4)
	K.txtS(exp, "Exportar", 9, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local path = "ArkherScripts/" .. doc().name .. ".lua"
		local ok2 = pcall(function()
			if game.WriteFile then game:WriteFile(path, doc().src) end
		end)
		status.Text = ok2 and ("exportado p/ " .. path) or "WriteFile indisponivel fora do Studio"
	end)
	local und2 = K.btn(bar, "U2", 626, 4, 80, 22, T.bg2, 4)
	K.txtS(und2, "Hist.", 9, T.txt3)
	und2.MouseButton1Click:Connect(function()
		status.Text = #doc().undo .. " versoes no stack local | " .. #docs .. " docs abertos"
	end)

	-- compile + AI callbacks (precisam do status)
	compile.MouseButton1Click:Connect(function()
		local res = SX.compile(doc().src)
		if res.ok then
			status.Text = "compilacao OK (" .. res.engine .. ") — sintaxe valida"
		else
			status.Text = "ERRO de sintaxe" .. (res.line and (" linha " .. res.line) or "") .. ": " .. tostring(res.error):sub(1, 90)
		end
	end)
	aiGen.MouseButton1Click:Connect(function()
		pushUndo()
		local goal = nameBox.Text ~= "" and nameBox.Text or "sistema"
		-- pergunta o objetivo via texto do nome + keywords do doc atual
		local hint = goal .. " " .. doc().src:sub(1, 60)
		local src, id2 = SX.compose(hint)
		doc().src = src
		commitEdit()
		status.Text = "IA local compôs de '" .. hint:sub(1, 24) .. "...' → template '" .. id2 .. "'"
	end)

	repaintAll = function()
		nameBox.Text = doc().name
		repaintTabs()
		repaintCode()
		relintBody()
		repaintPanel()
		repaintStatus()
	end

	-- ================= BOOT DA UI =================
	repaintAll()
end

ARKHER.reg("Script", "Script Studio", "Editor", ICON.script, "IDE completa: multi-doc, highlight real, lint real, autocomplete API, outline, templates, create-in-place", build)
end

ARKHER.open("Script")
