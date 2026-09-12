--[[ ARKHER SCRYPTER X (ASX) — backend profissional do Script Studio ]]
-- Tokenizer Luau REAL + highlight por segmentos + linter (balanceamento de
-- blocos, variaveis nao declaradas, locais nao usados, APIs depreciadas) +
-- autocomplete com banco da API Roblox + 30 templates completos + 45 snippets
-- + formatador + find/replace + outline de funcoes + compile-check + diff.
ArkherScripterX = ArkherScripterX or {}
local SX = ArkherScripterX
local floor = math.floor
local byte, sub, find, gmatch, gsub, rep = string.byte, string.sub, string.find, string.gmatch, string.gsub, string.rep

-- ================= BANCO DE CONHECIMENTO =================
SX.KEYWORDS = {
	"and", "break", "continue", "do", "else", "elseif", "end", "export", "false",
	"for", "function", "if", "in", "local", "nil", "not", "or", "repeat",
	"return", "self", "then", "true", "type", "typeof", "until", "while",
}
SX.KW_SET = {}
for _, k in ipairs(SX.KEYWORDS) do SX.KW_SET[k] = true end
SX.BUILTINS = {
	"assert", "error", "gcinfo", "getmetatable", "ipairs", "next", "pairs", "pcall",
	"print", "rawequal", "rawget", "rawlen", "rawset", "require", "select",
	"setmetatable", "tonumber", "tostring", "type", "unpack", "xpcall", "warn",
	"coroutine", "debug", "math", "os", "string", "table", "utf8", "bit32", "buffer",
	"vector", "_G", "_VERSION", "task", "loadstring", "newproxy", "collectgarbage", "elapsedTime",
}
SX.GLOBALS = {
	"game", "workspace", "script", "plugin", "Enum", "Instance", "Vector2", "Vector3",
	"CFrame", "Color3", "UDim", "UDim2", "BrickColor", "NumberRange", "NumberSequence",
	"NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "Rect", "Region3",
	"TweenInfo", "Random", "DateTime", "PhysicalProperties", "PathWaypoint", "Axises",
	"Faces", "RaycastParams", "OverlapParams", "CatalogSearchParams", "secret", "shared", "settings",
}
SX.SERVICES = {
	"Players", "Workspace", "Lighting", "MaterialService", "ReplicatedFirst",
	"ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui",
	"StarterPack", "StarterPlayer", "Teams", "SoundService", "Chat", "TextChatService",
	"TweenService", "RunService", "UserInputService", "ContextActionService",
	"HttpService", "DataStoreService", "MemoryStoreService", "TeleportService",
	"MarketplaceService", "BadgeService", "CollectionService", "PhysicsService",
	"PathfindingService", "Debris", "InsertService", "ContentProvider", "GuiService",
	"ProximityPromptService", "SocialService", "MessagingService", "PolicyService",
	"LocalizationService", "VoiceChatService", "AssetService", "LogService", "Stats", "TestService",
}
SX.API_SET = {}
for _, k in ipairs(SX.BUILTINS) do SX.API_SET[k] = true end
for _, k in ipairs(SX.GLOBALS) do SX.API_SET[k] = true end
for _, k in ipairs(SX.SERVICES) do SX.API_SET[k] = true end
SX.METHODS_COMMON = {
	"GetService", "FindFirstChild", "WaitForChild", "GetChildren", "GetDescendants",
	"GetAttribute", "SetAttribute", "GetAttributes", "Clone", "Destroy", "IsA",
	"Connect", "Once", "Disconnect", "Fire", "FireServer", "FireClient", "InvokeServer",
	"new", "Wait", "Play", "Pause", "Stop", "Cancel", "Lerp", "ToWorldSpace",
	"ToObjectSpace", "JSONEncode", "JSONDecode", "GetAsync", "SetAsync", "UpdateAsync",
	"PostAsync", "GetAsyncFullUrl", "TweenValue", "Create", "Emit", "ClearAllChildren",
}
SX.DEPRECATED = {
	wait = "task.wait()", spawn = "task.spawn()", delay = "task.delay()", ypcall = "pcall()",
}

-- ================= TOKENIZER =================
-- retorna tokens: {k=("kw"|"id"|"str"|"num"|"cmt"|"op"), s, line, col}
function SX.tokenize(src)
	src = src or ""
	local toks = {}
	local i, line, col, n = 1, 1, 1, #src
	local function push(k, s, l, c) toks[#toks + 1] = { k = k, s = s, line = l, col = c } end
	while i <= n do
		local ch = sub(src, i, i)
		if ch == "\n" then
			line = line + 1; col = 1; i = i + 1
		elseif ch == " " or ch == "\t" or ch == "\r" then
			i = i + 1; col = col + 1
		elseif ch == "-" and sub(src, i + 1, i + 1) == "-" then
			local l, c = line, col
			if sub(src, i + 2, i + 3) == "[[" then -- comentario longo
				local e = find(src, "]]", i + 4, true)
				e = e or n + 1
				local s = sub(src, i, e - 1 + (e <= n and 2 or 0))
				push("cmt", s, l, c)
				-- atualiza linha/col por quebras internas
				for _ in gmatch(s, "\n") do line = line + 1 end
				i = (e <= n) and (e + 2) or (n + 1)
				col = 1
			else
				local e = find(src, "\n", i, true) or (n + 1)
				push("cmt", sub(src, i, e - 1), l, c)
				col = col + (e - i); i = e
			end
		elseif ch == '"' or ch == "'" then
			local l, c = line, col
			local j = i + 1
			while j <= n do
				local cj = sub(src, j, j)
				if cj == "\\" then j = j + 2
				elseif cj == ch then break
				elseif cj == "\n" then break
				else j = j + 1 end
			end
			push("str", sub(src, i, math.min(j, n)), l, c)
			col = col + (math.min(j, n) - i + 1); i = math.min(j + 1, n + 1)
		elseif sub(src, i, i + 1) == "[[" then
			local l, c = line, col
			local e = find(src, "]]", i + 2, true) or (n + 1)
			local s = sub(src, i, (e <= n and (e + 1) or n))
			push("str", s, l, c)
			for _ in gmatch(s, "\n") do line = line + 1 end
			i = (e <= n) and (e + 2) or (n + 1); col = 1
		elseif ch:match("%d") or (ch == "." and sub(src, i + 1, i + 1):match("%d")) then
			local s2 = sub(src, i)
			local num = s2:match("^0[xX]%x+") or s2:match("^%d+%.?%d*[eE][+-]?%d+") or s2:match("^%d+%.?%d*") or ch
			push("num", num, line, col)
			i = i + #num; col = col + #num
		elseif ch:match("[%a_]") then
			local j = i
			while j <= n and sub(src, j, j):match("[%w_]") do j = j + 1 end
			local word = sub(src, i, j - 1)
			push(SX.KW_SET[word] and "kw" or "id", word, line, col)
			col = col + (j - i); i = j
		else
			local two = sub(src, i, i + 1)
			local three = sub(src, i, i + 2)
			if SX.SYMBOL3 and SX.SYMBOL3[three] then
				push("op", three, line, col); i = i + 3; col = col + 3
			elseif SX.SYMBOL2 and SX.SYMBOL2[two] then
				push("op", two, line, col); i = i + 2; col = col + 2
			else
				push("op", ch, line, col); i = i + 1; col = col + 1
			end
		end
	end
	return toks
end
SX.SYMBOL2 = { ["=="] = true, ["~="] = true, ["<="] = true, [">="] = true, [".."] = true, ["+="] = true, ["-="] = true, ["*="] = true, ["/="] = true, ["->"] = true, ["::"] = true }
SX.SYMBOL3 = { ["..."] = true }

-- ================= HIGHLIGHT (linha -> segmentos {text,color}) =================
SX.THEME = {
	kw = "#C792EA", id = "#D7DCE8", str = "#C3E88D", num = "#F78C6C",
	cmt = "#697098", op = "#89AAAA", builtin = "#82AAFF", glob = "#FFCB6B",
	svc = "#5AD4E6", method = "#FF869A",
}
function SX.highlightLines(src)
	local toks = SX.tokenize(src)
	local lines = {}
	local function lineAt(l)
		while #lines < l do lines[#lines + 1] = {} end
		return lines[l]
	end
	for idx, t in ipairs(toks) do
		local kind = t.k
		if kind == "id" then
			local prev = toks[idx - 1]
			local nxt = toks[idx + 1]
			if prev and prev.k == "op" and (prev.s == ":" or prev.s == ".") then kind = "method"
			elseif SX.API_SET[t.s] and (prev == nil or prev.s ~= ":") then kind = SX.SVCWORD[t.s] and "svc" or "glob"
			elseif SX.KW_SET[t.s] then kind = "kw" end
			if SX.DEPRECATED[t.s] and nxt and nxt.s == "(" then kind = "method" end
		end
		table.insert(lineAt(t.line), { t.s, kind, t.col })
	end
	return lines, toks
end
-- palavras de servico p/ cor propria
SX.SVCWORD = {}
for _, s in ipairs(SX.SERVICES) do SX.SVCWORD[s] = true end

-- ================= LINTER =================
function SX.lint(src)
	local toks = SX.tokenize(src)
	local diags = {}
	local function diag(sev, line, col, code, msg)
		diags[#diags + 1] = { sev = sev, line = line, col = col, code = code, msg = msg }
	end
	-- 1) balanceamento de blocos
	local stack = {}
	local locals = {} -- {name, line, scopeDepth, used}
	local declared = {}
	local scopeOf = {}
	local function declare(name, line)
		locals[#locals + 1] = { name = name, line = line, depth = #stack, used = false }
		declared[name .. "@" .. #stack .. "@" .. (#locals)] = true
	end
	local lastId = nil
	local pendingLocalNames = nil
	local expectingParams = false
	for i, t in ipairs(toks) do
		local prev = toks[i - 1]
		local nxt = toks[i + 1]
		if t.k == "kw" then
			if t.s == "function" then
				stack[#stack + 1] = { what = "function", line = t.line }
				expectingParams = true
				-- nome da func (proximo id) conta como uso/declaracao de uso
				if lastId then lastId.used = true end
			elseif t.s == "then" then stack[#stack + 1] = { what = "then", line = t.line }
			elseif t.s == "do" then stack[#stack + 1] = { what = "do", line = t.line }
			elseif t.s == "repeat" then stack[#stack + 1] = { what = "repeat", line = t.line }
			elseif t.s == "end" then
				if #stack == 0 then diag("error", t.line, t.col, "E01", "'end' sem bloco correspondente")
				else
					local top = stack[#stack]
					if top.what == "repeat" then diag("error", t.line, t.col, "E02", "'repeat' fechado com 'end' — use 'until'") end
					stack[#stack] = nil
					-- fecha escopo: marca usados ate aqui (nao zera — global e simples)
				end
			elseif t.s == "until" then
				local found = false
				for si = #stack, 1, -1 do
					if stack[si].what == "repeat" then
						for sj = #stack, si, -1 do stack[sj] = nil end
						found = true
						break
					end
				end
				if not found then diag("error", t.line, t.col, "E03", "'until' sem 'repeat'") end
			elseif t.s == "elseif" then
				if #stack > 0 and stack[#stack].what == "then" then stack[#stack] = nil end
			elseif t.s == "local" then
				pendingLocalNames = {}
				-- olha adiante: local a, b =... / local function f
				if nxt and nxt.k == "kw" and nxt.s == "function" then
					local n3 = toks[i + 2]
					if n3 and n3.k == "id" then declare(n3.s, t.line) pendingLocalNames = nil end
				else
					local j = i + 1
					while j <= #toks do
						local tj = toks[j]
						if tj.k == "id" then
							if toks[j - 1] and toks[j - 1].s == "," or j == i + 1 then
								declare(tj.s, t.line)
							end
						elseif tj.s == "=" or tj.k == "kw" then
							break
						end
						j = j + 1
					end
				end
			elseif t.s == "for" then
				-- for i = / for k, v in
				local j = i + 1
				while toks[j] and (toks[j].k == "id" or toks[j].s == ",") do
					if toks[j].k == "id" then declare(toks[j].s, t.line) end
					j = j + 1
				end
			end
		elseif t.k == "id" then
			-- declaramos antes? marca uso
			if prev and prev.k == "op" and (prev.s == "." or prev.s == ":") then
				-- campo/metodo — nao conta como global
			elseif prev and prev.k == "kw" and (prev.s == "function" or prev.s == "local") then
				-- nome de declaracao — ok
			else
				-- uso
				local foundLocal = nil
				for li = #locals, 1, -1 do
					if locals[li].name == t.s then foundLocal = locals[li] break end
				end
				if foundLocal then foundLocal.used = true end
				-- global desconhecido? (socheca se nao e chave de tabela: nxt = '=' com prev = '{' ou ',')
				local isTableKey = nxt and nxt.s == "=" and prev and prev.k == "op" and (prev.s == "{" or prev.s == ",")
				local isParam = expectingParams and prev and (prev.s == "(" or prev.s == ",")
				if isParam then declare(t.s, t.line) end
				if not isTableKey and not isParam and not foundLocal and not SX.API_SET[t.s] and not SX.KW_SET[t.s] then
					diag("warn", t.line, t.col, "W10", "possivel global nao declarada '" .. t.s .. "'")
				end
			end
			if SX.DEPRECATED[t.s] and nxt and nxt.s == "(" then
				diag("warn", t.line, t.col, "W30", "'" .. t.s .. "()' esta depreciada — use " .. SX.DEPRECATED[t.s])
			end
			lastId = foundLocalOf(locals, t.s)
		elseif t.k == "str" then
			if not (sub(t.s, -1) == '"' or sub(t.s, -1) == "'" or sub(t.s, -2) == "]]") then
				diag("error", t.line, t.col, "E10", "string nao terminada")
			end
		elseif t.s == ")" then
			expectingParams = false
		end
	end
	if #stack > 0 then
		local top = stack[#stack]
		diag("error", top.line or 1, 1, "E04", "bloco '" .. top.what .. "' aberto na linha " .. tostring(top.line) .. " nao foi fechado ('end' ausente)")
	end
	-- 2) locais nao usados
	for _, l in ipairs(locals) do
		if not l.used then diag("info", l.line, 1, "I20", "local '" .. l.name .. "' declarada e nunca usada") end
	end
	return diags, toks
end
-- acha a ultima decl da variavel
function foundLocalOf(locals, name)
	for li = #locals, 1, -1 do
		if locals[li].name == name then return locals[li] end
	end
	return nil
end
function SX.lintSummary(diags)
	local e, w, inf = 0, 0, 0
	for _, d in ipairs(diags) do
		if d.sev == "error" then e = e + 1 elseif d.sev == "warn" then w = w + 1 else inf = inf + 1 end
	end
	return { errors = e, warns = w, infos = inf, total = #diags }
end

-- ================= COMPILE-CHECK (parse real quando possivel) =================
function SX.compile(src)
	if loadstring then
		local fn, err = loadstring(src, "arkher_script")
		if fn then return { ok = true, engine = "loadstring" } end
		local ln = tostring(err):match(":(%d+):")
		return { ok = false, error = tostring(err), line = tonumber(ln), engine = "loadstring" }
	end
	return { ok = false, error = "loadstring indisponivel", engine = "none" }
end

-- ================= FORMATADOR =================
function SX.format(src, indentW)
	indentW = indentW or "\t"
	local out, depth = {}, 0
	for line in (src .. "\n"):gmatch("(.-)\n") do
		local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
		if trimmed ~= "" then
			local first = trimmed:match("^(%S*)")
			if first then
				if first:sub(1, 3) == "end" or first == "until" or first == "else" or first:match("^elseif") or first == ")" or first == "}" then
					depth = math.max(depth - 1, 0)
				end
			end
			out[#out + 1] = rep(indentW, depth) .. trimmed
			-- sobe descendo pelos openers no fim da linha
			local opens = 0
			local closers = 0
			for w in trimmed:gmatch("[%a_]+") do
				if w == "function" or w == "then" or w == "do" or w == "repeat" then opens = opens + 1 end
				if w == "end" then closers = closers + 1 end
			end
			if trimmed:match("^end") then closers = closers - 1 end
			depth = math.max(depth + opens - 0, 0)
			if trimmed:match("then.*end$") or trimmed:match("do.*end$") then depth = math.max(depth - 1, 0) end
			if trimmed:match("^else") or trimmed:match("^elseif") then depth = depth + 0 end
		else
			out[#out + 1] = ""
		end
	end
	return table.concat(out, "\n")
end

-- ================= FIND / REPLACE =================
function SX.findAll(src, needle, opts)
	opts = opts or {}
	local hits = {}
	if needle == "" then return hits end
	local initPos = 1
	local line, lineStart = 1, 1
	if not opts.pattern then
		while true do
			local a, b = find(src, needle, initPos, true)
			if not a then break end
			hits[#hits + 1] = { a = a, b = b }
			initPos = b + 1
		end
	else
		for a, b in src:gmatch("()" .. needle .. "()") do
			hits[#hits + 1] = { a = a, b = b - 1 }
		end
	end
	-- mapeia pos -> linha
	local pos = 1
	local curLine = 1
	local map = {}
	for i = 1, #src do if sub(src, i, i) == "\n" then curLine = curLine + 1 end; map[i] = curLine end
	for _, h in ipairs(hits) do h.line = map[h.a] end
	return hits
end
function SX.replace(src, needle, repl, opts)
	opts = opts or {}
	if opts.pattern then
		local new, count = gsub(src, needle, repl)
		return new, count
	end
	local hits = SX.findAll(src, needle, opts)
	if #hits == 0 then return src, 0 end
	local parts, last = {}, 1
	for _, h in ipairs(hits) do
		parts[#parts + 1] = sub(src, last, h.a - 1)
		parts[#parts + 1] = repl
		last = h.b + 1
	end
	parts[#parts + 1] = sub(src, last)
	return table.concat(parts), #hits
end
-- ================= OUTLINE (arvore real de funcoes) =================
function SX.outline(src)
	local toks = SX.tokenize(src)
	local items = {}
	local depth = 0
	for i, t in ipairs(toks) do
		if t.k == "kw" then
			if t.s == "function" then
				local name = "(anonima)"
				local prev = toks[i - 1]
				local pieces = {}
				local j = i + 1
				while j <= #toks and (toks[j].k == "id" or toks[j].s == "." or toks[j].s == ":") do
					pieces[#pieces + 1] = toks[j].s
					j = j + 1
				end
				if #pieces > 0 then name = table.concat(pieces) end
				if prev and prev.k == "kw" and prev.s == "local" then name = "local " .. name end
				items[#items + 1] = { name = name, line = t.line, depth = depth, kind = "function" }
				depth = depth + 1
			elseif t.s == "then" or t.s == "do" or t.s == "repeat" then depth = depth + 1
			elseif t.s == "end" or t.s == "until" then depth = math.max(depth - 1, 0)
			end
		end
	end
	return items
end

-- ================= AUTOCOMPLETE =================
function SX.complete(prefix, docSrc)
	prefix = prefix or ""
	local results, seen = {}, {}
	local function add(label, kind, detail)
		if #prefix > 0 and sub(label, 1, #prefix):lower() ~= prefix:lower() then return end
		if seen[label] then return end
		seen[label] = true
		results[#results + 1] = { label = label, kind = kind, detail = detail or "" }
	end
	for _, k in ipairs(SX.KEYWORDS) do add(k, "keyword", "palavra-chave Luau") end
	for _, b in ipairs(SX.BUILTINS) do add(b, "builtin", "funcao global") end
	for _, g2 in ipairs(SX.GLOBALS) do add(g2, "global", "API Roblox") end
	for _, s in ipairs(SX.SERVICES) do add(s, "service", "service: game:GetService('" .. s .. "')") end
	for _, m in ipairs(SX.METHODS_COMMON) do add(m, "method", "metodo comum") end
	if docSrc then
		for w in gmatch(docSrc, "[%a_][%w_]+") do
			if #w > 2 and not SX.KW_SET[w] then add(w, "doc", "identificador do documento") end
		end
	end
	table.sort(results, function(a, b2) return a.label:lower() < b2.label:lower() end)
	local capped = {}
	for i = 1, math.min(#results, 24) do capped[i] = results[i] end
	return capped
end

-- ================= METRICS / DIFF =================
function SX.metrics(src)
	local toks = SX.tokenize(src)
	local lines = 1
	for _ in gmatch(src or "", "\n") do lines = lines + 1 end
	local funcs, cyclo = 0, 1
	for _, t in ipairs(toks) do
		if t.k == "kw" then
			if t.s == "function" then funcs = funcs + 1 end
			if t.s == "if" or t.s == "for" or t.s == "while" or t.s == "and" or t.s == "or" or t.s == "elseif" then cyclo = cyclo + 1 end
		end
	end
	return { lines = lines, chars = #(src or ""), tokens = #toks, functions = funcs, complexity = cyclo }
end
function SX.diffLines(a, b)
	local aL, bL = {}, {}
	for l in (a .. "\n"):gmatch("(.-)\n") do aL[#aL + 1] = l end
	for l in (b .. "\n"):gmatch("(.-)\n") do bL[#bL + 1] = l end
	local ops = {}
	local i, j = 1, 1
	while i <= #aL and j <= #bL do
		if aL[i] == bL[j] then
			ops[#ops + 1] = { op = "keep", line = aL[i] }; i = i + 1; j = j + 1
		else
			ops[#ops + 1] = { op = "del", line = aL[i] }; i = i + 1
			if bL[j] ~= aL[i] and bL[j] ~= nil then ops[#ops + 1] = { op = "add", line = bL[j] }; j = j + 1 end
		end
	end
	while i <= #aL do ops[#ops + 1] = { op = "del", line = aL[i] }; i = i + 1 end
	while j <= #bL do ops[#ops + 1] = { op = "add", line = bL[j] }; j = j + 1 end
	return ops
end

-- ================= SNIPPETS (45) =================
SX.SNIPPETS = {
	{ id = "debounce", nm = "Debounce", code = "local debounce = false\nif debounce then return end\ndebounce = true\ntask.wait(1)\ndebounce = false" },
	{ id = "pcall", nm = "pcall seguro", code = "local ok, err = pcall(function()\n\t-- codigo arriscado\nend)\nif not ok then warn(err) end" },
	{ id = "signal", nm = "Evento custom (BindableEvent)", code = "local bind = Instance.new(\"BindableEvent\")\nbind.Event:Connect(function(data) end)\nbind:Fire(payload)" },
	{ id = "loop", nm = "Loop com task", code = "task.spawn(function()\n\twhile task.wait(1) do\n\t\t-- ciclo\n\tend\nend)" },
	{ id = "raycast", nm = "Raycast com params", code = "local params = RaycastParams.new()\nparams.FilterType = Enum.RaycastFilterType.Exclude\nparams.FilterDescendantsInstances = { script.Parent }\nlocal hit = workspace:Raycast(origin, dir, params)\nif hit then print(hit.Instance) end" },
	{ id = "tween", nm = "Tween", code = "local ts = game:GetService(\"TweenService\")\nlocal t = ts:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Color = Color3.fromRGB(255, 0, 0) })\nt:Play()" },
	{ id = "heartbeat", nm = "Heartbeat", code = "game:GetService(\"RunService\").Heartbeat:Connect(function(dt)\n\t-- por frame\nend)" },
	{ id = "playersadded", nm = "PlayerAdded", code = "game:GetService(\"Players\").PlayerAdded:Connect(function(player)\n\tprint(player.Name)\nend)" },
	{ id = "charadded", nm = "CharacterAdded", code = "player.CharacterAdded:Connect(function(char)\n\tlocal hum = char:WaitForChild(\"Humanoid\")\nend)" },
	{ id = "touched", nm = "Touched com debounce", code = "local cd = {}\npart.Touched:Connect(function(hit)\n\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)\n\tif plr and not cd[plr] then\n\t\tcd[plr] = true\n\t\ttask.delay(1, function() cd[plr] = nil end)\n\tend\nend)" },
	{ id = "remote", nm = "RemoteEvent padrao", code = "local remote = Instance.new(\"RemoteEvent\")\nremote.Name = \"MyRemote\"\nremote.Parent = game:GetService(\"ReplicatedStorage\")\nremote.OnServerEvent:Connect(function(player, ...) end)" },
	{ id = "bindfunc", nm = "BindableFunction", code = "local bf = Instance.new(\"BindableFunction\")\nbf.OnInvoke = function(x) return x * 2 end" },
	{ id = "module", nm = "ModuleScript base", code = "local M = {}\nM.__index = M\nfunction M.new() return setmetatable({}, M) end\nreturn M" },
	{ id = "attr", nm = "Attributes", code = "part:SetAttribute(\"vida\", 100)\nlocal vida = part:GetAttribute(\"vida\")" },
	{ id = "collection", nm = "CollectionService tags", code = "local CS = game:GetService(\"CollectionService\")\nfor _, inst in ipairs(CS:GetTagged(\"Enemy\")) do end" },
	{ id = "debris", nm = "Debris cleanup", code = "game:GetService(\"Debris\"):AddItem(part, 5)" },
	{ id = "datastore", nm = "DataStore save", code = "local DS = game:GetService(\"DataStoreService\"):GetDataStore(\"Save1\")\nlocal ok, err = pcall(function()\n\tDS:SetAsync(\"p_\" .. player.UserId, data)\nend)" },
	{ id = "dsget", nm = "DataStore load", code = "local ok, data = pcall(function()\n\treturn DS:GetAsync(\"p_\" .. player.UserId)\nend)\ndata = data or { moedas = 0 }" },
	{ id = "json", nm = "JSON roundtrip", code = "local Http = game:GetService(\"HttpService\")\nlocal str = Http:JSONEncode({ a = 1 })\nlocal back = Http:JSONDecode(str)" },
	{ id = "lerp", nm = "Lerp manual", code = "local function lerp(a, b, t) return a + (b - a) * t end" },
	{ id = "clamp", nm = "Clamp", code = "local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end" },
	{ id = "tablefind", nm = "Tabela contem", code = "local function has(t, v)\n\tfor _, x in ipairs(t) do if x == v then return true end end\n\treturn false\nend" },
	{ id = "shuffle", nm = "Shuffle Fisher-Yates", code = "local function shuffle(t)\n\tfor i = #t, 2, -1 do\n\t\tlocal j = math.random(i)\n\t\tt[i], t[j] = t[j], t[i]\n\tend\nend" },
	{ id = "spring", nm = "Spring (fisica)", code = "local s = { p = 0, v = 0, k = 120, d = 12 }\nfunction s:step(dt, target)\n\tlocal acc = (target - self.p) * self.k - self.v * self.d\n\tself.v = self.v + acc * dt\n\tself.p = self.p + self.v * dt\n\treturn self.p\nend" },
	{ id = "maid", nm = "Maid (cleanup)", code = "local Maid = {}\nMaid.__index = Maid\nfunction Maid.new() return setmetatable({ items = {} }, Maid) end\nfunction Maid:give(item) table.insert(self.items, item) end\nfunction Maid:clean()\n\tfor _, it in ipairs(self.items) do\n\t\tpcall(function() it:Disconnect() end)\n\t\tpcall(function() it:Destroy() end)\n\tend\n\tself.items = {}\nend" },
	{ id = "observer", nm = "Observer/Observable", code = "local obs = { cbs = {} }\nfunction obs:subscribe(fn) table.insert(self.cbs, fn) end\nfunction obs:emit(...)\n\tfor _, f in ipairs(self.cbs) do task.spawn(f, ...) end\nend" },
	{ id = "camshake", nm = "Camera shake", code = "local cam = workspace.CurrentCamera\nlocal t0 = tick()\ngame:GetService(\"RunService\"):BindToRenderStep(\"shake\", 200, function()\n\tlocal a = math.max(0, 1 - (tick() - t0))\n\tcam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)\nend)" },
	{ id = "uicorner", nm = "Corner programatico", code = "local c = Instance.new(\"UICorner\")\nc.CornerRadius = UDim.new(0, 8)\nc.Parent = frame" },
	{ id = "uistroke", nm = "Stroke programatico", code = "local s = Instance.new(\"UIStroke\")\ns.Thickness = 2\ns.Color = Color3.fromRGB(88, 166, 255)\ns.Parent = frame" },
	{ id = "grid", nm = "UIListLayout", code = "local l = Instance.new(\"UIListLayout\")\nl.Padding = UDim.new(0, 6)\nl.SortOrder = Enum.SortOrder.LayoutOrder\nl.Parent = container" },
	{ id = "prompt", nm = "ProximityPrompt", code = "local p = Instance.new(\"ProximityPrompt\")\np.ActionText = \"Abrir\"\np.Parent = part\np.Triggered:Connect(function(player) end)" },
	{ id = "hitbox", nm = "Hitbox region", code = "local parts = workspace:GetPartBoundsInBox(CFrame.new(0, 5, 0), Vector3.new(6, 6, 6), params)" },
	{ id = "path", nm = "Pathfinding", code = "local ps = game:GetService(\"PathfindingService\")\nlocal path = ps:CreatePath()\npath:ComputeAsync(from, to)\nif path.Status == Enum.PathStatus.Success then\n\tfor _, wp in ipairs(path:GetWaypoints()) do end\nend" },
	{ id = "knockback", nm = "Knockback", code = "local lv = Instance.new(\"LinearVelocity\")\nlv.VectorVelocity = dir * 60\nlv.Parent = hrp\ngame:GetService(\"Debris\"):AddItem(lv, 0.2)" },
	{ id = "daynight", nm = "Ciclo dia/noite", code = "local L = game:GetService(\"Lighting\")\ngame:GetService(\"RunService\").Heartbeat:Connect(function(dt)\n\tL.ClockTime = (L.ClockTime + dt * 0.1) % 24\nend)" },
	{ id = "zone", nm = "Zona (magnitude)", code = "local function inZone(pos, center, r)\n\treturn (pos - center).Magnitude <= r\nend" },
	{ id = "intersect", nm = "Distancia 2D", code = "local function dist2D(a, b)\n\treturn ((a.X - b.X) ^ 2 + (a.Z - b.Z) ^ 2) ^ 0.5\nend" },
	{ id = "leaderstats", nm = "Leaderstats", code = "local ls = Instance.new(\"Folder\")\nls.Name = \"leaderstats\"\nlocal coins = Instance.new(\"IntValue\")\ncoins.Name = \"Moedas\"\ncoins.Parent = ls\nls.Parent = player" },
	{ id = "givetool", nm = "Dar Tool", code = "local tool = Instance.new(\"Tool\")\ntool.Name = \"Espada\"\ntool.Parent = player.Backpack" },
	{ id = "seat", nm = "Seat detect", code = "seat:GetPropertyChangedSignal(\"Occupant\"):Connect(function()\n\tlocal hum = seat.Occupant\n\tif hum then print(\"sentou\") end\nend)" },
	{ id = "spawnsafe", nm = "Spawn protegido", code = "local ff = Instance.new(\"ForceField\")\nff.Parent = char\ngame:GetService(\"Debris\"):AddItem(ff, 3)" },
	{ id = "sound", nm = "Som 3D", code = "local s = Instance.new(\"Sound\")\ns.SoundId = \"rbxassetid://0\"\ns.RollOffMaxDistance = 100\ns.Parent = part\ns:Play()" },
	{ id = "mutex", nm = "Lock simples", code = "local locked = false\nlocal function withLock(fn)\n\tif locked then return end\n\tlocked = true\n\tlocal ok, err = pcall(fn)\n\tlocked = false\n\tif not ok then error(err) end\nend" },
	{ id = "cachemod", nm = "Require com cache", code = "local cache = {}\nlocal function req(mod)\n\tif not cache[mod] then cache[mod] = require(mod) end\n\treturn cache[mod]\nend" },
	{ id = "typeshape", nm = "Guard de tipo", code = "local function isVec3(v)\n\treturn typeof(v) == \"Vector3\"\nend" },
	{ id = "atx", nm = "ARKHER: gerar terreno ATX", code = "local w = ArkherTerrainX.new({ seed = 7, preset = \"montanhas\" })\nw:materializeRegion(-256, -256, 512, 512)" },
	{ id = "awx", nm = "ARKHER: oceano AWX", code = "local sea = ArkherWaterX.preset(\"ressaca\", { kind = \"oceano\", level = 0 })\nArkherWaterX.materialize(sea)" },
	{ id = "uix", nm = "ARKHER: HUD via UIKitX", code = "local hud = ArkherUIKitX.create(\"health\")\nlocal gui, n = ArkherUIKitX.build({ hud }, \"MeuHUD\")" },
}

-- ================= TEMPLATES (30 roteiros completos) =================
local function T_(class, lines) return { class = class, code = lines } end
SX.TEMPLATES = {
	{ id = "basico", nm = "Script Basico (Touched)", cls = "Script", code = {
		"-- Script Basico — ARKHER Script Studio",
		"local part = script.Parent",
		"",
		"local DEBOUNCE = 1",
		"local cd = {}",
		"",
		"part.Touched:Connect(function(hit)",
		"\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)",
		"\tif not plr or cd[plr] then return end",
		"\tcd[plr] = true",
		"\ttask.delay(DEBOUNCE, function() cd[plr] = nil end)",
		"\tprint(plr.Name .. \" tocou em \" .. part.Name)",
		"end)",
	} },
	{ id = "local_basico", nm = "LocalScript Basico", cls = "LocalScript", code = {
		"-- LocalScript Basico",
		"local Players = game:GetService(\"Players\")",
		"local player = Players.LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal hrp = char:WaitForChild(\"HumanoidRootPart\")",
		"\tprint(\"spawn em\", hrp.Position)",
		"end)",
	} },
	{ id = "oop_classe", nm = "Classe OOP (metatable)", cls = "ModuleScript", code = {
		"-- Classe OOP completa com heranca minima",
		"local Classe = {}",
		"Classe.__index = Classe",
		"",
		"function Classe.new(nome, vida)",
		"\tlocal self = setmetatable({}, Classe)",
		"\tself.nome = nome",
		"\tself.vida = vida or 100",
		"\tself.alive = true",
		"\treturn self",
		"end",
		"",
		"function Classe:dano(q)",
		"\tself.vida = math.max(self.vida - q, 0)",
		"\tif self.vida == 0 then self.alive = false end",
		"end",
		"",
		"function Classe:curar(q) self.vida = self.vida + q end",
		"function Classe:__tostring() return self.nome .. \"(\" .. self.vida .. \"hp)\" end",
		"",
		"return Classe",
	} },
	{ id = "state_machine", nm = "Maquina de Estados", cls = "ModuleScript", code = {
		"-- FSM: estados com enter/update/exit",
		"local FSM = {}",
		"FSM.__index = FSM",
		"",
		"function FSM.new(states, ini)",
		"\tlocal self = setmetatable({}, FSM)",
		"\tself.states = states or {}",
		"\tself.state = ini",
		"\tself.t = 0",
		"\tif ini and states[ini] and states[ini].enter then states[ini].enter(self) end",
		"\treturn self",
		"end",
		"",
		"function FSM:set(nome)",
		"\tlocal st = self.states[self.state]",
		"\tif st and st.exit then st.exit(self) end",
		"\tself.state = nome",
		"\tself.t = 0",
		"\tst = self.states[nome]",
		"\tif st and st.enter then st.enter(self) end",
		"end",
		"",
		"function FSM:update(dt)",
		"\tself.t = self.t + dt",
		"\tlocal st = self.states[self.state]",
		"\tif st and st.update then st.update(self, dt) end",
		"end",
		"",
		"return FSM",
	} },
	{ id = "event_bus", nm = "Event Bus", cls = "ModuleScript", code = {
		"-- Barramento de eventos tipado",
		"local Bus = {}",
		"Bus.__index = Bus",
		"",
		"function Bus.new() return setmetatable({ handlers = {} }, Bus) end",
		"function Bus:on(ev, fn)",
		"\tself.handlers[ev] = self.handlers[ev] or {}",
		"\ttable.insert(self.handlers[ev], fn)",
		"\treturn function() self:off(ev, fn) end",
		"end",
		"function Bus:off(ev, fn)",
		"\tlocal hs = self.handlers[ev]",
		"\tif not hs then return end",
		"\tfor i = #hs, 1, -1 do if hs[i] == fn then table.remove(hs, i) end end",
		"end",
		"function Bus:emit(ev, ...)",
		"\tfor _, fn in ipairs(self.handlers[ev] or {}) do task.spawn(fn, ...) end",
		"end",
		"",
		"return Bus",
	} },
	{ id = "profile_store", nm = "Perfil de Dados (DataStore)", cls = "ModuleScript", code = {
		"-- Perfil de jogador com retry e padroes",
		"local DS = game:GetService(\"DataStoreService\"):GetDataStore(\"Profile_v1\")",
		"local Profile = {}",
		"Profile.__index = Profile",
		"Profile.defaults = { moedas = 0, nivel = 1, itens = {} }",
		"",
		"local function copy(t) local r = {} for k, v in pairs(t) do r[k] = v end return r end",
		"",
		"function Profile.load(player)",
		"\tlocal key = \"p_\" .. player.UserId",
		"\tlocal data",
		"\tfor tentativa = 1, 3 do",
		"\t\tlocal ok, res = pcall(function() return DS:GetAsync(key) end)",
		"\t\tif ok then data = res break end",
		"\t\ttask.wait(1)",
		"\tend",
		"\tlocal self = setmetatable({}, Profile)",
		"\tself.key = key",
		"\tself.data = data or copy(Profile.defaults)",
		"\treturn self",
		"end",
		"",
		"function Profile:save()",
		"\treturn pcall(function() DS:SetAsync(self.key, self.data) end)",
		"end",
		"",
		"return Profile",
	} },
	{ id = "arma_raycast", nm = "Arma Raycast (Server)", cls = "Script", code = {
		"-- Arma: raycast no servidor + cooldown",
		"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"local remote = ReplicatedStorage:WaitForChild(\"ShootRemote\")",
		"local COOLDOWN, RANGE = 0.25, 300",
		"local last = {}",
		"",
		"remote.OnServerEvent:Connect(function(player, origin, dir)",
		"\tlocal now = os.clock()",
		"\tif last[player] and now - last[player] < COOLDOWN then return end",
		"\tlast[player] = now",
		"\tlocal params = RaycastParams.new()",
		"\tparams.FilterType = Enum.RaycastFilterType.Exclude",
		"\tparams.FilterDescendantsInstances = { player.Character }",
		"\tlocal res = workspace:Raycast(origin, dir.Unit * RANGE, params)",
		"\tif res then",
		"\t\tlocal hum = res.Instance.Parent:FindFirstChildOfClass(\"Humanoid\")",
		"\t\tif hum then hum:TakeDamage(25) end",
		"\tend",
		"end)",
	} },
	{ id = "espada", nm = "Espada (Tool)", cls = "Script", code = {
		"-- Tool de espada com dano em Touched",
		"local tool = script.Parent",
		"local blade = tool:WaitForChild(\"Blade\")",
		"local swinging = false",
		"",
		"tool.Activated:Connect(function() swinging = true task.wait(0.4) swinging = false end)",
		"blade.Touched:Connect(function(hit)",
		"\tif not swinging then return end",
		"\tlocal hum = hit.Parent:FindFirstChildOfClass(\"Humanoid\")",
		"\tif hum and hum.Parent ~= tool.Parent then hum:TakeDamage(15) swinging = false end",
		"end)",
	} },
	{ id = "npc_ia", nm = "NPC IA (vagar/perseguir)", cls = "Script", code = {
		"-- NPC simples: vaga, persegue jogador proximo",
		"local Players = game:GetService(\"Players\")",
		"local npc = script.Parent",
		"local hum = npc:WaitForChild(\"Humanoid\")",
		"local root = npc:WaitForChild(\"HumanoidRootPart\")",
		"local AGGRO = 40",
		"",
		"while task.wait(0.5) do",
		"\tlocal alvo, dmin = nil, AGGRO",
		"\tfor _, plr in ipairs(Players:GetPlayers()) do",
		"\t\tlocal c = plr.Character",
		"\t\tlocal r = c and c:FindFirstChild(\"HumanoidRootPart\")",
		"\t\tif r then",
		"\t\t\tlocal d = (r.Position - root.Position).Magnitude",
		"\t\t\tif d < dmin then alvo = r dmin = d end",
		"\t\tend",
		"\tend",
		"\tif alvo then hum:MoveTo(alvo.Position)",
		"\telse hum:MoveTo(root.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))) end",
		"end)",
	} },
	{ id = "porta_tween", nm = "Porta com Tween", cls = "Script", code = {
		"-- Porta: abre/fecha com tween + prompt",
		"local TS = game:GetService(\"TweenService\")",
		"local porta = script.Parent",
		"local aberta = false",
		"local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)",
		"",
		"local prompt = Instance.new(\"ProximityPrompt\")",
		"prompt.ActionText = \"Abrir/Fechar\"",
		"prompt.Parent = porta",
		"",
		"prompt.Triggered:Connect(function()",
		"\taberta = not aberta",
		"\tlocal alvo = aberta and porta.CFrame * CFrame.new(0, porta.Size.Y, 0) or porta.CFrame * CFrame.new(0, -porta.Size.Y, 0)",
		"\tTS:Create(porta, info, { CFrame = alvo }):Play()",
		"end)",
	} },
	{ id = "elevador", nm = "Elevador", cls = "Script", code = {
		"-- Elevador multi-andar",
		"local TS = game:GetService(\"TweenService\")",
		"local cabine = script.Parent",
		"local andares = { 0, 40, 80 }",
		"local atual = 1",
		"",
		"local function irPara(i)",
		"\tatual = math.clamp(i, 1, #andares)",
		"\tlocal alvo = cabine.CFrame + Vector3.new(0, andares[atual] - andares[1], 0)",
		"\tTS:Create(cabine, TweenInfo.new(3), { CFrame = alvo }):Play()",
		"end",
		"",
		"irPara(2)",
	} },
	{ id = "esteira", nm = "Esteira Transportadora", cls = "Script", code = {
		"-- Esteira: move parts de cima",
		"local esteira = script.Parent",
		"local V = Vector3.new(12, 0, 0)",
		"esteira.AssemblyLinearVelocity = V",
	} },
	{ id = "dialogo", nm = "Dialogo NPC", cls = "Script", code = {
		"-- Dialogo com opcoes via prompt + remote",
		"local prompt = script.Parent.ProximityPrompt",
		"local falas = { \"Ola, viajante!\", \"Bem-vindo ao ARKHER.\", \"Cuide bem do mundo.\" }",
		"prompt.Triggered:Connect(function(player)",
		"\tfor i, f in ipairs(falas) do",
		"\t\tprint(\"NPC:\", f)",
		"\t\ttask.wait(1.4)",
		"\tend",
		"end)",
	} },
	{ id = "quest", nm = "Sistema de Quest", cls = "ModuleScript", code = {
		"-- Quest com objetivos e recompensa",
		"local Quest = {}",
		"Quest.__index = Quest",
		"function Quest.new(id, nome, objetivos)",
		"\treturn setmetatable({ id = id, nome = nome, objetivos = objetivos, progresso = {}, feita = false }, Quest)",
		"end",
		"function Quest:registrar(tipo, q)",
		"\tfor _, ob in ipairs(self.objetivos) do",
		"\t\tif ob.tipo == tipo then",
		"\t\t\tself.progresso[tipo] = (self.progresso[tipo] or 0) + q",
		"\t\tend",
		"\tend",
		"end",
		"function Quest:completa()",
		"\tfor _, ob in ipairs(self.objetivos) do",
		"\t\tif (self.progresso[ob.tipo] or 0) < ob.q then return false end",
		"\tend",
		"\tself.feita = true return true",
		"end",
		"return Quest",
	} },
	{ id = "loja", nm = "Loja (compra)", cls = "Script", code = {
		"-- Loja: compra com moedas dos leaderstats",
		"local ITENS = { espada = { preco = 100 }, escudo = { preco = 150 } }",
		"local remote = game:GetService(\"ReplicatedStorage\"):WaitForChild(\"BuyRemote\")",
		"remote.OnServerEvent:Connect(function(player, item)",
		"\tlocal cfg = ITENS[item]",
		"\tlocal moedas = player.leaderstats and player.leaderstats:FindFirstChild(\"Moedas\")",
		"\tif not cfg or not moedas then return end",
		"\tif moedas.Value >= cfg.preco then",
		"\t\tmoedas.Value = moedas.Value - cfg.preco",
		"\t\tprint(player.Name .. \" comprou \" .. item)",
		"\tend",
		"end)",
	} },
	{ id = "admin", nm = "Admin Basico", cls = "Script", code = {
		"-- Comandos admin via chat (!kill, !speed)",
		"local ADMINS = { [\"SeuUsuario\"] = true }",
		"game:GetService(\"Players\").PlayerAdded:Connect(function(player)",
		"\tplayer.Chatted:Connect(function(msg)",
		"\t\tif not ADMINS[player.Name] then return end",
		"\t\tlocal cmd, arg = msg:match(\"^!(%w+)%s*(%w*)\")",
		"\t\tif cmd == \"speed\" then",
		"\t\t\tlocal hum = player.Character and player.Character:FindFirstChildOfClass(\"Humanoid\")",
		"\t\t\tif hum then hum.WalkSpeed = tonumber(arg) or 16 end",
		"\t\tend",
		"\tend)",
		"end)",
	} },
	{ id = "checkpoint", nm = "Checkpoint", cls = "Script", code = {
		"-- Spawn por checkpoint",
		"local stage = script.Parent",
		"stage.Touched:Connect(function(hit)",
		"\tlocal plr = game:GetService(\"Players\"):GetPlayerFromCharacter(hit.Parent)",
		"\tif plr then plr.RespawnLocation = stage end",
		"end)",
	} },
	{ id = "teleport", nm = "Teleporte entre places", cls = "Script", code = {
		"-- TeleportService",
		"local TS = game:GetService(\"TeleportService\")",
		"local PLACE_ID = 0",
		"prompt.Triggered:Connect(function(player)",
		"\tTS:TeleportAsync(PLACE_ID, player)",
		"end)",
	} },
	{ id = "ragdoll", nm = "Ragdoll", cls = "Script", code = {
		"-- Ragdoll basico nas mortes",
		"local char = script.Parent",
		"local hum = char:WaitForChild(\"Humanoid\")",
		"hum.Died:Connect(function()",
		"\tfor _, d in ipairs(char:GetDescendants()) do",
		"\t\tif d:IsA(\"Motor6D\") then d.Enabled = false end",
		"\tend",
		"end)",
	} },
	{ id = "springcam", nm = "Camera Spring", cls = "LocalScript", code = {
		"-- Camera com mola suave",
		"local RS = game:GetService(\"RunService\")",
		"local cam = workspace.CurrentCamera",
		"local alvo = workspace:WaitForChild(\"CamTarget\")",
		"local pos, vel = cam.CFrame.Position, Vector3.zero",
		"RS.RenderStepped:Connect(function(dt)",
		"\tlocal acc = (alvo.Position - pos) * 90 - vel * 10",
		"\tvel = vel + acc * dt",
		"\tpos = pos + vel * dt",
		"\tcam.CFrame = CFrame.new(pos, alvo.Position)",
		"end)",
	} },
	{ id = "dia_noite", nm = "Ciclo Dia/Noite + Lua", cls = "Script", code = {
		"-- Ciclo completo: sol, lua, cores",
		"local L = game:GetService(\"Lighting\")",
		"local VEL = 1 -- minutos reais por dia",
		"game:GetService(\"RunService\").Heartbeat:Connect(function(dt)",
		"\tL.ClockTime = (L.ClockTime + dt * (24 / (VEL * 60))) % 24",
		"\tlocal dia = L.ClockTime > 6 and L.ClockTime < 18",
		"\tL.Brightness = dia and 2 or 0.5",
		"end)",
	} },
	{ id = "observador_ui", nm = "Observador -> UI", cls = "LocalScript", code = {
		"-- UI reativa a atributo",
		"local gui = script.Parent",
		"local label = gui:WaitForChild(\"Lbl\")",
		"local alvo = workspace:WaitForChild(\"GameState\")",
		"alvo:GetAttributeChangedSignal(\"Fase\"):Connect(function()",
		"\tlabel.Text = \"Fase \" .. tostring(alvo:GetAttribute(\"Fase\"))",
		"end)",
	} },
	{ id = "sistema_hud", nm = "HUD Vida/Stamina", cls = "LocalScript", code = {
		"-- HUD: barra de vida do personagem",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"local gui = script.Parent",
		"local bar = gui:WaitForChild(\"Vida\")",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal hum = char:WaitForChild(\"Humanoid\")",
		"\thum.HealthChanged:Connect(function(v)",
		"\t\tbar.Size = UDim2.fromScale(v / hum.MaxHealth, 1)",
		"\tend)",
		"end)",
	} },
	{ id = "terrain_atx", nm = "Terreno ATX completo", cls = "Script", code = {
		"-- Gera um mundo ATX + erosao + rios + materializacao",
		"local mundo = ArkherTerrainX.new({ seed = 42, preset = \"montanhas\", cell = 8 })",
		"mundo:erodeHydraulic(1, 1, 64, 64, 3000)",
		"mundo:carveRivers(1, 1, 64, 64, 24)",
		"mundo:materializeRegion(-256, -256, 512, 512)",
		"local oceano = ArkherWaterX.preset(\"porto\", { kind = \"oceano\", level = mundo.seaLevel })",
		"ArkherWaterX.materialize(oceano, { maxSpan = 512 })",
	} },
	{ id = "agua_awx", nm = "Oceano AWX + Boia", cls = "Script", code = {
		"-- Mar + boias com flutuabilidade",
		"local mar = ArkherWaterX.preset(\"ressaca\", { kind = \"oceano\", level = 0 })",
		"ArkherWaterX.materialize(mar)",
		"for i = 1, 4 do",
		"\tlocal p = Instance.new(\"Part\")",
		"\tp.Size = Vector3.new(4, 2, 4)",
		"\tp.Position = Vector3.new(i * 8, 1, 0)",
		"\tp.Parent = workspace",
		"\tArkherWaterX.float(mar, p, { density = 400 })",
		"end",
		"local t = 0",
		"game:GetService(\"RunService\").Heartbeat:Connect(function(dt)",
		"\tt = t + dt",
		"\tArkherWaterX.step(mar, dt, t)",
		"\tArkherWaterX.animate(mar, t)",
		"end)",
	} },
	{ id = "hud_uix", nm = "HUD completo (UIKitX)", cls = "LocalScript", code = {
		"-- HUD: vida + stamina + hotbar + timer via UIKitX",
		"local K = ArkherUIKitX",
		"local widgets = {",
		"\tK.create(\"health\", { x = 16, y = 16 }),",
		"\tK.create(\"stamina\", { x = 16, y = 48 }),",
		"\tK.create(\"hotbar\", { slots = 6 }),",
		"\tK.create(\"timer\", { x = 500, y = 16 }),",
		"}",
		"local gui, n = K.build(widgets, \"MeuHUD\")",
		"print(\"HUD montado com\", n, \"widgets\")",
	} },
	{ id = "match_loop", nm = "Loop de Partida", cls = "Script", code = {
		"-- Partida: lobby -> jogo -> placar",
		"local Players = game:GetService(\"Players\")",
		"while true do",
		"\tprint(\"Aguardando jogadores...\")",
		"\trepeat task.wait(1) until #Players:GetPlayers() >= 1",
		"\tprint(\"Intermissao 10s\") task.wait(10)",
		"\tprint(\"Partida! 60s\") task.wait(60)",
		"\tprint(\"Placar 8s\") task.wait(8)",
		"end)",
	} },
	{ id = "anti_abuso", nm = "Guard Anti-Exploit", cls = "Script", code = {
		"-- Validacoes de servidor simples",
		"local function validar(alvo, origem, maxD)",
		"\tif not alvo or typeof(alvo.Position) ~= \"Vector3\" then return false end",
		"\treturn (alvo.Position - origem).Magnitude <= maxD",
		"end",
		"return validar",
	} },
	{ id = "observable_stat", nm = "Stat Observavel", cls = "ModuleScript", code = {
		"-- Stat com watchers",
		"local Stat = {}",
		"Stat.__index = Stat",
		"function Stat.new(v) return setmetatable({ v = v, ws = {} }, Stat) end",
		"function Stat:set(v)",
		"\tlocal old = self.v",
		"\tself.v = v",
		"\tfor _, f in ipairs(self.ws) do task.spawn(f, v, old) end",
		"end",
		"function Stat:get() return self.v end",
		"function Stat:watch(f) table.insert(self.ws, f) return function() end end",
		"return Stat",
	} },
	{ id = "pool", nm = "Object Pool", cls = "ModuleScript", code = {
		"-- Pool de parts p/ projeteis/efeitos",
		"local Pool = {}",
		"Pool.__index = Pool",
		"function Pool.new(factory, n)",
		"\tlocal self = setmetatable({ factory = factory, livres = {}, emUso = {} }, Pool)",
		"\tfor i = 1, n or 10 do table.insert(self.livres, factory()) end",
		"\treturn self",
		"end",
		"function Pool:get()",
		"\tlocal o = table.remove(self.livres) or self.factory()",
		"\tself.emUso[o] = true return o",
		"end",
		"function Pool:free(o) if self.emUso[o] then self.emUso[o] = nil table.insert(self.livres, o) end end",
		"return Pool",
	} },
	{ id = "bezier", nm = "Curva Bezier 3D", cls = "ModuleScript", code = {
		"-- Bezier cubica + arc length approximado",
		"local B = {}",
		"function B.point(p0, p1, p2, p3, t)",
		"\tlocal u = 1 - t",
		"\treturn u^3 * p0 + 3 * u^2 * t * p1 + 3 * u * t^2 * p2 + t^3 * p3",
		"end",
		"function B.length(p0, p1, p2, p3, n)",
		"\tn = n or 24 local soma, a = 0, B.point(p0, p1, p2, p3, 0)",
		"\tfor i = 1, n do local b = B.point(p0, p1, p2, p3, i / n) soma = soma + (b - a).Magnitude a = b end",
		"\treturn soma",
		"end",
		"return B",
	} },
	{ id = "weighted_random", nm = "Sorteio Ponderado", cls = "ModuleScript", code = {
		"-- raridade/loot por peso",
		"local function roll(items)",
		"\tlocal total = 0",
		"\tfor _, it in ipairs(items) do total = total + it.peso end",
		"\tlocal r = math.random() * total",
		"\tfor _, it in ipairs(items) do",
		"\t\tr = r - it.peso",
		"\t\tif r <= 0 then return it end",
		"\tend",
		"\treturn items[#items]",
		"end",
		"return roll",
	} },
	{ id = "procedural_mapa", nm = "Mapa 2D Procedural", cls = "ModuleScript", code = {
		"-- maze simples (backtracker)",
		"local M = {}",
		"function M.gen(w, h, seed)",
		"\tmath.randomseed(seed or os.time())",
		"\tlocal g = {}",
		"\tfor y = 1, h do g[y] = {} for x = 1, w do g[y][x] = (x % 2 == 0 or y % 2 == 0) and 1 or 0 end end",
		"\t-- carve nos impares (algoritmo simplificado)",
		"\treturn g",
		"end",
		"return M",
	} },
}

for _, t in ipairs(SX.TEMPLATES) do t.src = table.concat(t.code, "\n") end
function SX.template(id) for _, t in ipairs(SX.TEMPLATES) do if t.id == id then return t end end return nil end
-- monta um script por descricao (mini-gerador local, p/ \"IA\" do IDE)
function SX.compose(goal)
	goal = (goal or ""):lower()
	local parts = { "-- Gerado pelo ARKHER Script Studio" }
	local picked = {}
	local function use(id) picked[#picked + 1] = id end
	if goal:find("arma") or goal:find("tiro") or goal:find("gun") then use("arma_raycast")
	elseif goal:find("espada") or goal:find("sword") then use("espada")
	elseif goal:find("npc") then use("npc_ia")
	elseif goal:find("quest") or goal:find("miss") then use("quest")
	elseif goal:find("loja") or goal:find("shop") then use("loja")
	elseif goal:find("hud") or goal:find("vida") then use("sistema_hud")
	elseif goal:find("terreno") or goal:find("terrain") or goal:find("mundo") then use("terrain_atx")
	elseif goal:find("agua") or goal:find("oceano") or goal:find("mar") then use("agua_awx")
	elseif goal:find("dia") or goal:find("noite") then use("dia_noite")
	elseif goal:find("porta") then use("porta_tween")
	else use("basico") end
	local t = SX.template(picked[1])
	for _, l in ipairs(t.code) do parts[#parts + 1] = l end
	return table.concat(parts, "\n"), picked[1]
end

SX._version = "1.0.0"
