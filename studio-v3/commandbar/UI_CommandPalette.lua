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
--[[ ARKHER V3 — UI: COMMAND PALETTE (Ctrl+K) ]]
-- Layout unico: barra flutuante centralizada de BUSCA, lista viva que filtra
-- UIs + TODOS os comandos do ARKHER conforme digita. Sem janela comum.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#FFD400")

local function build()
	local g, root, head = K.window("ArkherCommandPalette", "COMMAND PALETTE", 40, 140, 480, 318, {})
	K.f(head, "Acc", 0, 24, 480, 2, ACCENT)

	local box = K.input(root, 10, 34, 460, 28, "digite: publish, animator, save, insert.part...")
	local area = K.f(root, "Results", 10, 70, 460, 212, T.bg0)
	K.corner(area, 4)
	K.stroke(area, T.line, 1)
	local rows = K.f(area, "Rows", 0, 4, 460, 204)

	local firstRun = nil
	local function render(filter)
		for _, ch in ipairs(rows:GetChildren()) do ch:Destroy() end
		firstRun = nil
		local f = (filter or ""):lower()
		local y = 0
		local n = 0
		for _, name in ipairs(ARKHER.listUIs()) do
			local cat = ARKHER.CATALOG[name]
			local title = (cat and cat.title) or name
			if f == "" or title:lower():find(f, 1, true) or name:lower():find(f, 1, true) then
				local row = K.btn(rows, "R" .. n, 4, y, 452, 24, T.bg2, 3)
				K.txt(row, title, 10, 0, 320, 24, 11, T.txt)
				K.txt(row, (cat and cat.cat) or "ui", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local nm = name
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd("ui.open", nm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd("ui.open", nm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n > 0 then
			K.f(rows, "Sep", 8, y + 6, 444, 1, T.line)
			y = y + 12
		end
		for cmd in pairs(ARKHER.ACTIONS or {}) do
			if n >= 26 then break end
			if f == "" or cmd:find(f, 1, true) then
				local row = K.btn(rows, "C" .. n, 4, y, 452, 24, T.bg4, 3)
				K.txt(row, cmd, 10, 0, 320, 24, 10, T.neon, ARKHER.MONO or ARKHER.FONT)
				K.txt(row, "comando", 384, 0, 62, 24, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
				local cm = cmd
				row.MouseButton1Click:Connect(function()
					ARKHER.cmd(cm)
					root.Visible = false
				end)
				if not firstRun then firstRun = function() ARKHER.cmd(cm) end end
				if y < 180 then y = y + 25 end
				n = n + 1
			end
		end
		if n == 0 then
			K.txt(rows, "(nada encontrado para \"" .. tostring(filter) .. "\")", 10, 10, 300, 20, 10, T.txt4)
		end
	end
	render("")

	local function refresh()
		render(box.Text or "")
	end
	local okc, sig = pcall(function() return box:GetPropertyChangedSignal("Text") end)
	if okc and sig then sig:Connect(refresh) end
	local okf, fl = pcall(function() return box.FocusLost end)
	if okf and fl then
		fl:Connect(function(commit)
			if commit and firstRun then
				local ok, err = pcall(firstRun)
				if not ok then ARKHER.out("ERROR", "Palette: " .. tostring(err)) end
			end
			root.Visible = false
		end)
	end
	K.txt(root, "# UIs: " .. tostring(#ARKHER.listUIs()) .. "  |  # comandos: " .. (function()
		local c = 0
		for _ in pairs(ARKHER.ACTIONS or {}) do c = c + 1 end
		return c
	end)(), 10, 290, 300, 16, 9, T.txt4)
	K.txt(root, "Enter = 1o resultado | Esc = fecha", 300, 290, 170, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	-- paleta nasce oculta: abre com Ctrl+K / VIEW > Command Palette
	root.Visible = false
end

ARKHER.reg("CommandPalette", "Command Palette", "System", ICON.search, "Ctrl+K: busca viva de UIs e todos os comandos do ARKHER", build)
end

ARKHER.open("CommandPalette")
