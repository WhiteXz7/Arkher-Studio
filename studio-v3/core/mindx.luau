-- MIND X (MINDX) — MENTES REAIS para humanos digitais (cat. K 5301-6000):
-- inspirado na tese NMN (precisões/objetivos/memória com CAUSA/percepção por
-- grade espacial), mas recodificado no padrão ARKHER-RRW: sem runtime externo,
-- no pulso do RRX, dirigindo os corpos procedurais do DAYX. Cada decisão é
-- AUDITÁVEL (mind_why mostra o PORQUÊ com as causas).

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local RX = rawget(_G, "ArkherRealityX")
local DAYX = rawget(_G, "ArkherDayX")

local V3 = Vector3.new
local MINDX = {}
local S = {
	minds = {}, grid = {}, CELL = 14,
	foodSpots = { V3(0, 0, 0) },
	enabled = true, acc = 0, t = 0,
}

local function cellKey(x, z)
	return math.floor(x / S.CELL) .. ":" .. math.floor(z / S.CELL)
end

local function gridInsert(id, x, z)
	local k = cellKey(x, z)
	S.grid[k] = S.grid[k] or {}
	S.grid[k][id] = true
end
local function gridRemove(id, x, z)
	local k = cellKey(x, z)
	if S.grid[k] then S.grid[k][id] = nil end
end

-- ============ nasce uma mente ============
local function newMind(h, seed)
	local rng = DM and DM.rng(seed or 7)
	return {
		id = "mind_" .. tostring((S.t * 1000 + #S.minds * 17) % 100000),
		h = h,
		needs = { hunger = 0.25 + rng(0.3), energy = 0.7 + rng(0.3), social = 0.3 + rng(0.4) },
		goal = "wander", memory = {}, relations = {},
		pos = h.root, lastKey = cellKey(h.root.X, h.root.Z),
		speedMul = 1, decided = 0,
	}
end

local function remember(m, event, cause)
	m.memory[#m.memory + 1] = { t = S.t, event = event, cause = cause }
	if #m.memory > 40 then table.remove(m.memory, 1) end
end

-- percepção: vizinhos por grade (O(celulas), como manda o TXT)
function MINDX.perceive(m, range)
	local cx, cz = math.floor(m.pos.X / S.CELL), math.floor(m.pos.Z / S.CELL)
	local out = {}
	local rr = math.ceil(range / S.CELL)
	for dx = -rr, rr do
		for dz = -rr, rr do
			local cell = S.grid[(cx + dx) .. ":" .. (cz + dz)]
			if cell then
				for id in pairs(cell) do
					if id ~= m.id and S.minds[id] then out[#out + 1] = S.minds[id] end
				end
			end
		end
	end
	return out
end

-- ============ decisão com causalidade (o coração do TXT) ============
local function decide(m)
	local h = m.h
	local hunger, energy, social = m.needs.hunger, m.needs.energy, m.needs.social
	local neighbors = MINDX.perceive(m, 22)
	local nearPeople = #neighbors
	for _, o in ipairs(neighbors) do
		m.relations[o.id] = (m.relations[o.id] or 0) + 0.04
	end
	local cause = ("hunger=%.2f,energy=%.2f,social=%.2f,near=%d"):format(hunger, energy, social, nearPeople)
	local newGoal = m.goal
	if energy < 0.18 then
		newGoal = "rest"
	elseif hunger > 0.78 then
		newGoal = "seek_food"
	elseif nearPeople == 0 and social > 0.66 then
		newGoal = "seek_people"
	elseif nearPeople >= 2 and social < 0.9 then
		newGoal = "wander"
	end
	if newGoal ~= m.goal then
		m.goal = newGoal
		m.decided = m.decided + 1
		remember(m, "goal:" .. newGoal, cause)
	end
	-- o corpo (DAYX) executa o objetivo
	if m.goal == "rest" then
		h.target = h.m:GetPivot().Position -- fica parado recuperando
		h.resting = true
	elseif m.goal == "seek_food" then
		local best, bd = S.foodSpots[1], 1e9
		for _, f in ipairs(S.foodSpots) do
			local d = (V3(f.X, 0, f.Z) - V3(m.pos.X, 0, m.pos.Z)).Magnitude
			if d < bd then best, bd = f, d end
		end
		h.target = V3(best.X, h.root.Y, best.Z)
		h.resting = false
		if bd < 4 then m.needs.hunger = math.max(0, m.needs.hunger - 0.25) remember(m, "comeu", "dist<4") end
	elseif m.goal == "seek_people" then
		local tgt
		for _, o in ipairs(neighbors) do tgt = tgt or o end
		if not tgt then
			-- andar em espiral até achar gente
			local a = S.t * 0.8 + (m.decided * 1.7)
			h.target = m.pos + V3(math.cos(a) * 18, 0, math.sin(a) * 18)
		else
			h.target = tgt.pos
		end
		h.resting = false
	else
		h.resting = false
	end
	m.needs.energy = math.clamp(m.needs.energy + (m.goal == "rest" and 0.05 or -0.012), 0, 1)
	m.needs.hunger = math.clamp(m.needs.hunger + 0.008, 0, 1)
	m.needs.social = math.clamp(m.needs.social + (nearPeople > 0 and -0.02 or 0.01), 0, 1)
end

-- ============ tick (no pulso universal; resolução adapta com D-O15) ============
function MINDX.step(dt)
	if not S.enabled then return end
	S.t = S.t + dt
	S.acc = S.acc + dt
	if S.acc < 0.4 then return end
	local dtm = S.acc
	S.acc = 0
	-- acopla automaticamente a TODOS humanos DAYX (viva nasça = mente nasça)
	if DAYX and DAYX.S and DAYX.S.humans then
		for _, h in ipairs(DAYX.S.humans) do
			if not h._mindId and h.m and h.m.Parent then
				local id = "mind_" .. tostring(#S.minds + 1) .. "_" .. h.name
				local m = newMind(h, 7)
				m.id = id
				h._mindId = id
				h.mind = m
				S.minds[id] = m
				S.minds[#S.minds + 1] = id -- índice ordenado p/ iteração
				gridInsert(id, h.root.X, h.root.Z)
			end
		end
	end
	for i = 1, #S.minds do
		local id = S.minds[i]
		local m = S.minds[id]
		if m and m.h.m and m.h.m.Parent then
			local pv = m.h.m:GetPivot().Position
			m.pos = pv
			local k = cellKey(pv.X, pv.Z)
			if k ~= m.lastKey then
				gridRemove(id, m.h.__lastX or pv.X, m.h.__lastZ or pv.Z)
				gridInsert(id, pv.X, pv.Z)
				m.lastKey = k
			end
			m.h.__lastX, m.h.__lastZ = pv.X, pv.Z
			decide(m)
		end
	end
end

-- ponto de comida (cozinha/mercado/fogueira)
function MINDX.addFoodSpot(x, z)
	S.foodSpots[#S.foodSpots + 1] = V3(x or 0, 0, z or 0)
	return #S.foodSpots
end

-- o porquê das decisões (auditoria exigida pelos TXT)
function MINDX.why(name)
	for i = 1, #S.minds do
		local id = S.minds[i]
		local m = type(id) == "string" and S.minds[id] or nil
		if m and (not name or m.h.name == name) then
			local lines = {}
			for j = math.max(1, #m.memory - 5), #m.memory do
				local e = m.memory[j]
				lines[#lines + 1] = ("[%s] %s ← %s"):format(tostring(math.floor(e.t)), e.event, e.cause)
			end
			return ("%s | goal=%s | %s"):format(m.h.name, m.goal, table.concat(lines, "  |  "))
		end
	end
	return "nenhuma mente com esse nome"
end

function MINDX.stats()
	local goals = {}
	local n = 0
	for i = 1, #S.minds do
		local id = S.minds[i]
		local m = type(id) == "string" and S.minds[id] or nil
		if m then
			n = n + 1
			goals[m.goal] = (goals[m.goal] or 0) + 1
		end
	end
	local gs = {}
	for g, c in pairs(goals) do gs[#gs + 1] = g .. "=" .. c end
	return { minds = n, goals = table.concat(gs, " "), food = #S.foodSpots - 1 }
end

do
	if RX and RX.hook then RX.hook("mindx", function(dt) MINDX.step(dt) end) end
end

_G.ArkherMindX = MINDX
return MINDX
