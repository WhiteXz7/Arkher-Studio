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
--[[ ARKHER V3 — UI: CONSOLE ]]
-- Layout unico: chips de filtro, log REAL (ARKHER.OUTPUT) colorido por
-- severidade, append ao vivo via Bus, exportacao para arquivo.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C8D6E5")

local KIND_COLORS = {
	INFO = T.neon, SUCCESS = T.ok, WARNING = C("#FFD93D"), ERROR = T.danger,
}

local function build()
	local g, root, head = K.window("ArkherConsole", "CONSOLE — log do ARKHER", 24, 440, 560, 380, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== TOPO: FILTROS =====
	local filters = { "TODAS", "INFO", "SUCCESS", "WARNING", "ERROR" }
	local curFilter = "TODAS"
	local fbtns = {}
	for i, fl in ipairs(filters) do
		local b = K.btn(root, "F" .. i, 8 + (i - 1) * 78, 34, 72, 22, i == 1 and T.bg2 or T.bg4, 4)
		K.txtS(b, fl, 9, i == 1 and T.txt or T.txt3)
		K.hover(b, T.bg4, T.hover)
		local fl2 = fl
		b.MouseButton1Click:Connect(function()
			curFilter = fl2
			for j, bb in ipairs(fbtns) do
				K.stroke(bb, j == i and ACCENT or T.line2, j == i and 1.5 or 1)
			end
			render()
		end)
		fbtns[i] = b
		K.stroke(b, i == 1 and ACCENT or T.line2, i == 1 and 1.5 or 1)
	end
	local cntLbl = K.txt(root, "# linhas", 410, 38, 140, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)

	-- ===== LOG =====
	local log = K.f(root, "Log", 8, 64, 544, 232, T.bg0)
	K.corner(log, 4)
	K.stroke(log, T.line, 1)
	local area = K.f(log, "Area", 0, 0, 544, 232)
	local function render()
		for _, ch in ipairs(area:GetChildren()) do ch:Destroy() end
		local lines = ARKHER.OUTPUT or {}
		local shown = 0
		local y = 6
		for i = #lines, 1, -1 do
			if shown >= 18 then break end
			local e = lines[i]
			if curFilter == "TODAS" or e.kind == curFilter then
				local col = KIND_COLORS[e.kind] or T.txt2
				if col == T.danger then K.f(area, "bg" .. shown, 6, y - 2, 532, 18, C("#2A1214")) end
				K.txt(area, string.format("[%s] %s", e.kind, e.msg), 10, y, 524, 14, 10, col, ARKHER.MONO or ARKHER.FONT)
				shown = shown + 1
				y = y + 16
			end
		end
		cntLbl.Text = tostring(#lines) .. " linhas | " .. shown .. " visiveis"
	end
	render()
	-- ao vivo
	Bus.on("output", function()
		render()
	end)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 304, 544, 68, T.bg0)
	K.corner(bar, 4)
	local clear = K.btn(bar, "Cl", 10, 10, 80, 24, T.bg2, 4)
	K.txtS(clear, "Limpar", 10, T.txt)
	K.hover(clear, T.bg2, T.hover)
	clear.MouseButton1Click:Connect(function()
		ARKHER.OUTPUT = {}
		render()
		ARKHER.out("INFO", "Console: limpo")
	end)
	local exp = K.btn(bar, "Ex", 100, 10, 110, 24, ACCENT, 4)
	K.txtS(exp, "Exportar .txt", 10, C("#101418"))
	K.hover(exp, ACCENT, C("#E4ECF5"))
	exp.MouseButton1Click:Connect(function()
		local lines = {}
		for _, e in ipairs(ARKHER.OUTPUT or {}) do
			table.insert(lines, "[" .. e.kind .. "] " .. e.msg)
		end
		local ok, path = pcall(function()
			if game.WriteFile then
				game:WriteFile("ArkherConsole/console_" .. tostring(math.floor(tick() and tick() or 0)) .. ".txt", table.concat(lines, "\n"))
				return true
			end
			return false
		end)
		if ok then
			ARKHER.out("SUCCESS", "Console: " .. #lines .. " linhas exportadas")
		else
			ARKHER.out("WARNING", "Console: WriteFile indisponivel fora do Studio")
		end
	end)
	local auto = K.checkRow(bar, "auto-scroll", true, 44)
	K.txt(bar, "severidades: INFO=azul SUCCESS=verde WARNING=amarelo ERROR=vermelho", 230, 16, 300, 14, 9, T.txt4)
end

ARKHER.reg("Console", "Console", "System", ICON.script, "Console: log real do ARKHER com filtros, ao vivo e exportacao", build)
end

ARKHER.open("Console")
