--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER V3 — UI: PARTICLES ]]
-- Layout unico: arvore do emissor a esquerda, GRAPH DE NOS (K.node + K.wireLayer)
-- no centro — estilo Nuke/Blender, knobs a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#C56CF0")

local function build()
	local g, root, head = K.window("ArkherParticles", "PARTICLES — graph", 24, 340, 560, 400, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: ARVORE DO EMISSOR =====
	local left = K.f(root, "Tree", 8, 34, 148, 296, T.bg4)
	K.corner(left, 4)
	K.txt(left, "EMITTER", 10, 6, 90, 14, 10, T.txt3, ARKHER.FONTB)
	K.treeRow(left, 0, ICON.gem, "SparkEmitter", "open", 26)
	K.treeRow(left, 1, ICON.data, "RateOverTime", "sel", 50)
	K.treeRow(left, 1, ICON.data, "SpreadOverCone", nil, 74)
	K.treeRow(left, 1, ICON.data, "ColorOverLife", nil, 98)
	K.treeRow(left, 1, ICON.data, "Velocity", nil, 122)
	K.txt(left, "4 properties", 10, 150, 100, 14, 9, T.txt4)
	local addProp = K.btn(left, "AddP", 10, 172, 128, 22, T.bg2, 4)
	K.txtS(addProp, "+ property", 10, T.txt)
	K.hover(addProp, T.bg2, T.hover)
	local props = 4
	addProp.MouseButton1Click:Connect(function()
		props = props + 1
		ARKHER.out("INFO", "Particles: property #" .. props .. " adicionada")
	end)
	K.row(left, "Tipo", "Bullets", 210)
	K.row(left, "Lighting", "On", 234)
	K.row(left, "Sort", "Distance", 258)

	-- ===== CENTRO: GRAPH =====
	local cv = K.f(root, "Graph", 168, 34, 284, 296, T.dark)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	for i = 1, 8 do K.f(cv, "gx" .. i, i * 33, 0, 1, 296, T.bg3) end
	for i = 1, 9 do K.f(cv, "gy" .. i, 0, i * 31, 284, 1, T.bg3) end
	local wire = K.wireLayer(cv)
	-- nos
	local nEm = K.node(cv, 12, 108, 100, "Emitter", C("#3A2B45"), { "rate", "spread", "color" }, {}, { sel = true, dot = ACCENT })
	local nRate = K.node(cv, 160, 40, 104, "RateOverTime", T.bg1, {}, { "value" })
	local nSpread = K.node(cv, 160, 128, 104, "SpreadOverCone", T.bg1, {}, { "cone" })
	local nColor = K.node(cv, 160, 212, 104, "ColorOverLife", T.bg1, {}, { "grad" })
	-- liga os soquetes (coordenadas vindas dos _socket)
	local function socketsOf(n)
		local ins, outs = {}, {}
		for _, s in ipairs(n._sockets or {}) do
			if s._socket then
				if s._socket.kind == "in" then table.insert(ins, s._socket)
				else table.insert(outs, s._socket) end
			end
		end
		return ins, outs
	end
	local eIn, _ = socketsOf(nEm)
	local _, rOut = socketsOf(nRate)
	local _, sOut = socketsOf(nSpread)
	local _, cOut = socketsOf(nColor)
	if eIn[1] and rOut[1] then wire:link(rOut[1].x, rOut[1].y, eIn[1].x, eIn[1].y, ACCENT) end
	if eIn[2] and sOut[1] then wire:link(sOut[1].x, sOut[1].y, eIn[2].x, eIn[2].y, C("#4DFFDB")) end
	if eIn[3] and cOut[1] then wire:link(cOut[1].x, cOut[1].y, eIn[3].x, eIn[3].y, C("#FFD93D")) end
	K.txt(cv, "graph: 4 nos, 3 fios", 8, 278, 200, 14, 9, T.txt4)

	-- ===== DIREITA: KNOBS =====
	local right = K.f(root, "Knobs", 464, 34, 88, 296, T.bg4)
	K.corner(right, 4)
	K.txt(right, "RATE", 6, 6, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 24, 48, 0.72, "128/s")
	K.txt(right, "SPREAD", 6, 96, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 114, 48, 0.3, "38deg")
	K.txt(right, "LIFE", 6, 186, 76, 14, 10, T.txt3, ARKHER.FONTB)
	K.knob(right, 20, 204, 48, 0.5, "1.4s")

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 340, 544, 52, T.bg0)
	K.corner(bar, 4)
	-- preview de particulas (pontos)
	local pv = K.f(bar, "Prev", 10, 6, 120, 40, T.dark)
	K.corner(pv, 3)
	for i = 1, 14 do
		local s = (i * 16807) % 2147483647
		local s2 = (s * 16807) % 2147483647
		local d = K.f(pv, "P" .. i, s % 110 + 4, s2 % 30 + 4, 3, 3, ACCENT, 1)
	end
	local pvLbl = K.txt(bar, "preview: 128/s", 140, 12, 120, 16, 10, T.txt3)
	local sim = K.btn(bar, "Sim", 270, 12, 80, 26, ACCENT, 5)
	K.txtS(sim, "Simular", 11, C("#160B1E"))
	K.hover(sim, ACCENT, C("#D99BFF"))
	sim.MouseButton1Click:Connect(function()
		ARKHER.out("SUCCESS", "Particles: 128 particulas/s por 1.4s simuladas")
		K.notify("Simulacao", "SparkEmitter OK", "ok")
	end)
	K.txt(bar, "modo: graph", 370, 18, 90, 16, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
	K.txt(bar, "pronto", 480, 18, 50, 16, 9, T.ok, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Particles", "Particles", "Editor", ICON.gem, "Sistema de particulas em graph de nos com emissor e preview", build)
end

ARKHER.open("Particles")
