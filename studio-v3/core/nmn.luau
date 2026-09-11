--[[ ARKHER V3 — NMN: Natural Mindset of NPCs ]]
-- Cada NPC possui MENTE real: precisoes (fome/energia/social), objetivos, memoria,
-- percepcao indexada por Spatial Grid (O(celulas), nao O(n)), decisoes com causalidade.
-- D-O15 controla a resolucao do tick (under pressure → tick mais raro, nao apaga estado).
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local NMN = {}
ArkherNMN = NMN

local CELL = 12 -- studs
local minds = {}
local grid = {}
local tickCount = 0

-- ---------- SPATIAL GRID ----------
local function cellKey(x, z)
	return math.floor(x / CELL) .. "_" .. math.floor(z / CELL)
end

local function gridInsert(key, id)
	grid[key] = grid[key] or {}
	table.insert(grid[key], id)
end
local function gridRemove(key, id)
	local arr = grid[key]
	if not arr then return end
	for i = #arr, 1, -1 do
		if arr[i] == id then table.remove(arr, i) break end
	end
end
local function nearKeys(x, z)
	local kx, kz = math.floor(x / CELL), math.floor(z / CELL)
	local out = {}
	for dx = -1, 1 do
		for dz = -1, 1 do
			out[#out + 1] = (kx + dx) .. "_" .. (kz + dz)
		end
	end
	return out
end

-- ---------- PERCEPÇÃO (o NMN nao conhece o grid — pede e recebe) ----------
function NMN.perceive(pos, range)
	range = range or 24
	local seen = {}
	for _, key in ipairs(nearKeys(pos.X, pos.Z)) do
		local arr = grid[key]
		if arr then
			for _, id in ipairs(arr) do
				local m = minds[id]
				if m and m.pos then
					local d = (m.pos - pos).Magnitude
					if d <= range and d > 0.001 then
						seen[#seen + 1] = { id = id, name = m.name, dist = d, pos = m.pos, need = m.need }
					end
				end
			end
		end
	end
	return seen
end

-- ---------- MENTE ----------
local function newMind(id, name, pos)
	return {
		id = id, name = name, pos = pos,
		needs = { hunger = 0.2, energy = 0.8, social = 0.3 },
		goal = "wander",
		target = pos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)),
		memory = {}, -- eventos causais
		relations = {}, -- id -> score
		state = "idle",
		lastDecision = tick(),
		speed = 10,
	}
end

function NMN.spawn(name, pos)
	local id = name .. "_" .. tostring(tick())
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = false
	root.Color = Color3.fromRGB(70 + math.random(0, 120), 90 + math.random(0, 100), 120 + math.random(0, 80))
	root.Material = Enum.Material.SmoothPlastic
	root.CFrame = CFrame.new(pos)
	root.Parent = model
	local hum = Instance.new("Humanoid")
	hum.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = root.Position + Vector3.new(0, 1.8, 0)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(230, 200, 170)
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head
	local ok = pcall(function() model.Parent = workspace end)
	if not ok then return nil end
	local mind = newMind(id, name, root.Position)
	minds[id] = mind
	model:SetAttribute("arkher.nmn.id", id)
	gridInsert(cellKey(pos.X, pos.Z), id)
	ARKHER.out("INFO", "NMN: " .. name .. " nasce em (" .. string.format("%.0f", pos.X) .. "," .. string.format("%.0f", pos.Z) .. ")")
	return mind
end

function NMN.kill(id)
	local m = minds[id]
	if not m then return end
	for _, key in ipairs(nearKeys(m.pos.X, m.pos.Z)) do
		gridRemove(key, id)
	end
	minds[id] = nil
end

function NMN.count()
	return table.maxn and table.maxn(minds) or (function()
		local n = 0
		for _ in pairs(minds) do n = n + 1 end
		return n
	end)()
end

local function remember(m, event, cause)
	m.memory[#m.memory + 1] = { t = tick(), event = event, cause = cause }
	if #m.memory > 40 then table.remove(m.memory, 1) end
end

-- ---------- DECISÃO (causal: cada acao guarda a causa) ----------
local function decide(m)
	local hunger, energy, social = m.needs.hunger, m.needs.energy, m.needs.social
	local neighbors = NMN.perceive(m.pos, 20)
	local nearPeople = 0
	for _, s in ipairs(neighbors) do
		local other = minds[s.id]
		if other then
			nearPeople = nearPeople + 1
			m.relations[s.id] = (m.relations[s.id] or 0) + 0.05
		end
	end
	local cause = "state:hunger=" .. string.format("%.1f", hunger) .. ",energy=" .. string.format("%.1f", energy) .. ",social=" .. string.format("%.1f", social) .. ",near=" .. nearPeople
	local newGoal
	if energy < 0.2 then
		newGoal = "rest"
	elseif hunger > 0.8 then
		newGoal = "seek_food"
	elseif nearPeople == 0 and social > 0.7 then
		newGoal = "seek_people"
	elseif nearPeople >= 2 then
		newGoal = "wander"
	else
		newGoal = m.goal
	end
	if newGoal ~= m.goal then
		m.goal = newGoal
		remember(m, "goal." .. newGoal, cause)
		Bus.emit("nmn.decision", { id = m.id, name = m.name, goal = newGoal, cause = cause })
	end
	m.state = m.goal
end

-- ---------- TICK (escala com D-O15) ----------
function NMN.tick()
	tickCount = tickCount + 1
	local budget = ArkherDO15 and ArkherDO15.refreshBudget("nmn") or 0.1
	if tickCount % math.max(1, math.floor(budget * 60)) ~= 0 then return 0 end
	local processed = 0
	for id, m in pairs(minds) do
		-- decaimento/evolucao das precisoes
		m.needs.hunger = math.min(1, m.needs.hunger + 0.002)
		m.needs.energy = math.max(0, m.needs.energy - 0.001)
		if m.goal == "rest" then m.needs.energy = math.min(1, m.needs.energy + 0.01) end
		m.needs.social = math.min(1, m.needs.social + 0.001)
		-- percecao + decisao (apenas se ha mudeca de estado OU periodicamente)
		if tickCount % 120 == 0 or m.state == "idle" then
			decide(m)
		end
		-- movimento simples rumo ao alvo
		local root
		for _, ch in ipairs(workspace:GetChildren()) do
			if ch:GetAttribute("arkher.nmn.id") == id then
				for _, p in ipairs(ch:GetChildren()) do
					if p.Name == "HumanoidRootPart" then root = p break end
				end
				break
			end
		end
		if root then
			local dir = m.target - root.Position
			local dist = dir.Magnitude
			if dist < 1 then
				m.target = root.Position + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
			else
				dir = dir.Unit
				local step = math.min(dist, m.speed * 0.16)
				local key = cellKey(root.Position.X, root.Position.Z)
				pcall(function()
					root.Position = root.Position + dir * step
					gridRemove(key, id)
					gridInsert(cellKey(root.Position.X, root.Position.Z), id)
					m.pos = root.Position
				end)
			end
		end
		processed = processed + 1
	end
	return processed
end

function NMN.start()
	local RunService = game:GetService("RunService")
	pcall(function()
		RunService.Heartbeat:Connect(function()
			pcall(function() NMN.tick() end)
		end)
	end)
	ARKHER.out("INFO", "NMN ativo: " .. NMN.count() .. " mentes")
end

function NMN.report()
	local out = {}
	for id, m in pairs(minds) do
		out[#out + 1] = {
			id = id, name = m.name, goal = m.goal, state = m.state,
			needs = { hunger = m.needs.hunger, energy = m.needs.energy, social = m.needs.social },
			memorySize = #m.memory, relations = table.maxn and 0 or 0,
			pos = m.pos,
		}
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end

function NMN.why(id)
	local m = minds[id]
	if not m then return "sem registro" end
	local last = m.memory[#m.memory]
	return m.name .. " → " .. m.goal .. (last and (" | causa: " .. last.cause) or "")
end
