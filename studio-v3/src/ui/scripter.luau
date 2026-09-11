--[[ ARKHER V3 — UI: SCRIPT (code editor) ]]
-- Layout unico: barra de arquivo + tabs de classe, area de codigo com
-- numeros de linha, painel de lint, acoes reais (criar Script no place, exportar).
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#61DAFB")

local TEMPLATES = {
	Script = {
		"-- MeuScript (Script)",
		"local part = script.Parent",
		"",
		"part.Touched:Connect(function(hit)",
		"\tprint(\"tocado: \" .. hit.Name)",
		"\tpart.BrickColor = BrickColor.new(\"Bright red\")",
		"end)",
		"",
		"-- ARKHER: criado via Scripter",
	},
	LocalScript = {
		"-- MeuLocal (LocalScript)",
		"local player = game:GetService(\"Players\").LocalPlayer",
		"",
		"player.CharacterAdded:Connect(function(char)",
		"\tlocal cam = workspace.CurrentCamera",
		"\tcam.FieldOfView = 70",
		"end)",
	},
	ModuleScript = {
		"-- MeuModule (ModuleScript)",
		"local M = {}",
		"",
		"function M.hello(name)",
		"\treturn \"ola, \" .. name",
		"end",
		"",
		"return M",
	},
}

local function build()
	local g, root, head = K.window("ArkherScripter", "SCRIPT — editor de codigo", 24, 330, 520, 424, { pin = true })
	K.f(head, "Acc", 0, 24, 520, 2, ACCENT)

	local curCls = "Script"
	local curName = "MeuScript"
	local code = {}
	local CLASSES = { "Script", "LocalScript", "ModuleScript" }

	-- ===== TOPO: ARQUIVO + CLASSES =====
	local nameBox = K.input(root, 10, 34, 190, 24, "nome do arquivo")
	nameBox.Text = "MeuScript"
	K.tabs(root, 210, 34, 290, CLASSES, 1, function(idx)
		curCls = CLASSES[idx]
		curName = nameBox.Text
		code = TEMPLATES[curCls]
		renderCode()
	end)

	-- ===== AREA DE CODIGO =====
	local ed = K.f(root, "Editor", 10, 64, 356, 240, T.bg0)
	K.corner(ed, 4)
	K.stroke(ed, T.line, 1)
	local function renderCode()
		for i = 1, 12 do
			local old = ed:FindFirstChild("L" .. i)
			if old then old:Destroy() end
		end
		for i = 1, 12 do
			local ln = code[i] or ""
			K.txt(ed, string.format("%2d", i), 4, 6 + (i - 1) * 18, 24, 18, 9, T.txt4)
			K.f(ed, "ln" .. i, 28, 6 + (i - 1) * 18, 322, 1, (i == 5 or i == 7) and T.line or T.bg0)
			local col = T.txt2
			local txt = ln
			if ln:sub(1, 2) == "--" then col = T.txt4 end
			if ln:find("local ") == 1 then col = C("#C792EA") end
			if ln:find("function ") == 1 then col = ACCENT end
			if ln:find("print") == 1 then col = C("#82AAFF") end
			if txt ~= "" then
				local t = K.txt(ed, "L" .. i, 30, 6 + (i - 1) * 18, 320, 18, 10, col, ARKHER.MONO or ARKHER.FONT)
			end
		end
	end
	renderCode()

	-- ===== LINT =====
	local lint = K.f(root, "Lint", 10, 310, 356, 56, T.bg4)
	K.corner(lint, 4)
	K.txt(lint, "LINT", 8, 4, 50, 14, 10, T.txt3, ARKHER.FONTB)
	K.txt(lint, "0 erros", 8, 22, 80, 14, 10, T.ok)
	K.txt(lint, "1 aviso: pcall p/ Touched", 100, 22, 160, 14, 9, C("#FFD93D"))
	K.txt(lint, "linhas: 9", 280, 22, 70, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== DIREITA: ACOES =====
	local right = K.f(root, "Acts", 378, 64, 134, 302, T.bg4)
	K.corner(right, 4)
	K.txt(right, "AÇÕES", 10, 6, 80, 14, 10, T.txt3, ARKHER.FONTB)
	K.row(right, "Classe", curCls, 26)
	K.row(right, "Linhas", "9", 50)
	K.row(right, "Tamanho", "0.2 KB", 74)
	local create = K.btn(right, "Create", 10, 102, 114, 26, ACCENT, 5)
	K.txtS(create, "Criar no Place", 10, C("#08141A"))
	K.hover(create, ACCENT, C("#9BE8FF"))
	create.MouseButton1Click:Connect(function()
		local n = 1
		local ws = workspace
		local base = nameBox.Text
		while ws:FindFirstChild(base) do n = n + 1 base = nameBox.Text .. "_" .. n end
		local sc = Instance.new(curCls)
		sc.Name = base
		sc.Source = table.concat(code, "\n")
		sc.Parent = ws
		ARKHER.out("SUCCESS", "Script: " .. curCls .. " '" .. base .. "' criado no place (" .. #code .. " linhas)")
		K.notify("Script criado", base .. " no workspace", "ok")
	end)
	local exp = K.btn(right, "Export", 10, 136, 114, 26, T.bg2, 5)
	K.txtS(exp, "Exportar .lua", 10, T.txt)
	K.hover(exp, T.bg2, T.hover)
	exp.MouseButton1Click:Connect(function()
		local data = table.concat(code, "\n")
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherScripts/" .. nameBox.Text .. ".lua", data)
				return "ArkherScripts/" .. nameBox.Text .. ".lua"
			end
			return nil
		end)
		if ok and path then
			ARKHER.out("SUCCESS", "Script: exportado para " .. path)
		else
			ARKHER.out("WARNING", "Script: WriteFile indisponivel fora do Studio")
		end
	end)
	local ins = K.btn(right, "Insert", 10, 170, 114, 26, T.bg2, 5)
	K.txtS(ins, "+ snippet", 11, T.txt)
	K.hover(ins, T.bg2, T.hover)
	local snippets = { "\t-- snippet: debounce", "\tlocal debounce = false", "pcall(function() end)", "warn(\"debug\")" }
	local sn = 1
	ins.MouseButton1Click:Connect(function()
		sn = (sn % #snippets) + 1
		table.insert(code, snippets[sn])
		renderCode()
		ARKHER.out("INFO", "Script: snippet inserido")
	end)
	K.row(right, "Encoding", "utf-8", 214)
	K.row(right, "EOL", "LF", 238)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 10, 372, 502, 44, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "Ln 5, Col 12", 12, 6, 100, 14, 9, T.txt3)
	K.txt(bar, curCls, 130, 6, 120, 14, 9, ACCENT)
	K.txt(bar, "UTF-8 | LF | Luau", 268, 6, 130, 14, 9, T.txt4)
	K.txt(bar, "salvo", 470, 6, 30, 14, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Script", "Script", "Editor", ICON.script, "Editor de codigo Luau: classes, lint, criar no place e exportar", build)
