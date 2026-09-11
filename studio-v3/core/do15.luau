--[[ ARKHER V3 — D-O15: camada de otimizacao adaptativa ]]
-- Mede o custo real (FPS/heartbeat) e decide o nivel de materializacao (1..4).
-- Nao e "reduzir qualidade": escala trabalho (densidade de UI animada, frequencia
-- de refresh de paineis, tick da IA) mantendo a capacidade plena.
local RunService = game:GetService("RunService")

local D15 = {}
ArkherDO15 = D15

local state = {
	level = 2, -- 1 MAX | 2 HIGH | 3 BALANCED | 4 ECO
	fps = 60, frame = 0,
	cost = 0, -- media mobile de heartbeat (ms)
	samples = 0,
	lastTick = tick(),
	pressure = 0,
}
D15.state = state

local LEVEL_NAMES = { "MAX", "HIGH", "BALANCED", "ECO" }

function D15.levelName()
	return LEVEL_NAMES[state.level] or "?"
end

-- frequencia permitida por nivel (ex: quanto o AI/Inspector pode atualizar)
function D15.refreshBudget(key)
	local budgets = {
		inspector = { 0.1, 0.1, 0.25, 0.5 },
		hierarchy = { 0.2, 0.3, 0.5, 1.0 },
		ai = { 1.0, 1.0, 2.0, 4.0 },
		nmn = { 0.05, 0.1, 0.2, 0.5 },
		animations = { 1.0, 0.8, 0.5, 0.2 },
	}
	local b = budgets[key] or budgets.ai
	return b[state.level] or 1.0
end

function D15.pressure()
	return state.pressure
end

local function decide()
	local p = state.pressure
	if p > 0.7 then
		state.level = math.min(4, state.level + 1)
	elseif p < 0.35 and state.level > 1 then
		state.level = state.level - 1
	end
end

local acc = 0
local n = 0
function D15.nudge(target)
	state.level = target or 1
	ARKHER.STATE.do15Level = state.level
	Bus.emit("do15.level", state.level, state.fps, state.cost)
	ARKHER.out("INFO", "D-O15: nivel forcado para " .. D15.levelName())
end
function D15.start()
	Bus.on("do15.nudge", D15.nudge)
	local last = tick()
	pcall(function()
		RunService.Heartbeat:Connect(function(dt)
			local t = tick()
			local frameDt = t - last
			last = t
			acc = acc + frameDt
			n = n + 1
			state.frame = state.frame + 1
			if n >= 30 then
				state.fps = math.min(999, n / acc)
				state.cost = (acc / n) * 1000
				acc = 0
				n = 0
				-- pressao = custo do frame vs orcamento de 16.6ms
				state.pressure = math.min(1, state.cost / 16.6)
				decide()
				ARKHER.STATE.do15Level = state.level
				Bus.emit("do15.level", state.level, state.fps, state.cost)
			end
		end)
	end)
	ARKHER.out("INFO", "D-O15 ativo: nivel " .. state.level .. " (" .. D15.levelName() .. ")")
end

-- API usada pelos sistemas: "posso gastar?"
function D15.canAfford(fraction)
	-- fraction: quanto do orcamento de frame o trabalho consome (0..1)
	return state.pressure + fraction <= 1.0
end

-- relatorio (profiler / UI)
function D15.report()
	return {
		level = state.level, levelName = D15.levelName(),
		fps = state.fps, frameMs = state.cost, pressure = state.pressure,
		frames = state.frame,
	}
end
