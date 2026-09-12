-- WEA X (WEAX) — FRENTES METEOROLOGICAS (cat. L/M dos TXT):
-- sistemas de pressao ALTA/BAIXA que NASCEM, VIAJAM e MORREM sobre o mundo.
-- Uma frente que chega ate a camera MUDA o clima de verdade (AEX) e carrega
-- umidade pro ciclo d'agua (WLDX). E o oposto de "preset de ceu": e dinamica.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local WX = rawget(_G, "ArkherWorldX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local WEAX = {}
local S = {
	running = false, t = 0, acc = 0,
	wind = Vector2.new(7, 2.4),
	systems = {}, -- {x,z,r,kind("H"/"L"),int,life}
	lastWeatherSet = "",
}

WEAX.S = S

function WEAX.start()
	S.running = true
	local w = RX and (RX.S.earth or RX.S.world) or nil
	local half = w and w.size / 2 or 1200
	S.systems = {}
	local rng = DM and DM.rng(4242)
	for i = 1, 4 do
		S.systems[#S.systems + 1] = {
			x = rng(-half, half), z = rng(-half, half),
			r = rng(160, 420),
			kind = rng() < 0.45 and "L" or "H",
			int = rng(0.4, 1), life = rng(120, 400),
			dx = 0, dz = 0,
		}
	end
	return ("WEA rodando: %d sistemas de pressao viajando"):format(#S.systems)
end

-- vento global varia devagar (circulacao); frentes advectam com ele
function WEAX.step(dt)
	if not S.running then return end
	S.t = S.t + dt
	S.acc = S.acc + dt
	if S.acc < 1.0 then return end
	local dtm = S.acc
	S.acc = 0
	local w = RX and (RX.S.earth or RX.S.world) or nil
	local half = w and w.size / 2 or 1200
	local cam = workspace.CurrentCamera
	local cp = cam and cam.CFrame.Position or V3()
	-- circulacao global: rota devagar + rajada senoidal (fisica, nao dado)
	local rot = math.sin(S.t * 0.01) * 0.4
	local wx, wy = S.wind.X, S.wind.Y
	S.wind = Vector2.new(wx * math.cos(rot * dtm) - wy * math.sin(rot * dtm),
		wx * math.sin(rot * dtm) + wy * math.cos(rot * dtm))
	for i = #S.systems, 1, -1 do
		local sy = S.systems[i]
		sy.x, sy.z = sy.x + S.wind.X * dtm, sy.z + S.wind.Y * dtm
		sy.life = sy.life - dtm
		-- H enfraquece/devagar, L pode intensificar sobre umidade
		if sy.kind == "L" and w and w.hydro then
			if w.hydro.humidity > 0.8 then sy.int = math.min(1.4, sy.int + 0.02 * dtm) end
		end
		if sy.life <= 0 or math.abs(sy.x) > half or math.abs(sy.z) > half then
			table.remove(S.systems, i)
		end
	end
	-- nasce novo sistema de vez em quando (max 6)
	if #S.systems < 6 and (math.floor(S.t) % 17) == 0 then
		local rng = DM and DM.rng((S.t * 13) % 99989)
		S.systems[#S.systems + 1] = {
			x = rng(-half, half), z = rng(-half, half), r = rng(160, 420),
			kind = rng() < 0.5 and "L" or "H", int = rng(0.4, 1), life = rng(120, 400), dx = 0, dz = 0,
		}
	end
	-- EFEITO NA CAMERA: a frente que cobre o jogador define o tempo real
	local AEX = rawget(_G, "ArkherAtmosX")
	if AEX then
		local want, wind = "limpo", 0.2
		for _, sy in ipairs(S.systems) do
			local d = ((cp.X - sy.x) ^ 2 + (cp.Z - sy.z) ^ 2) ^ 0.5
			if d < sy.r then
				if sy.kind == "L" then
					want = (sy.int > 0.95 and "tempestade") or (sy.int > 0.6 and "chuva") or "nuvem"
					wind = math.min(1, sy.int)
				end
			elseif d < sy.r * 1.5 and want == "limpo" then
				if sy.kind == "L" then want = "nuvem" wind = math.max(wind, 0.35) end
			end
		end
		if want ~= S.lastWeatherSet then
			S.lastWeatherSet = want
			pcall(function() AEX.setWeather(want, wind) end)
		end
		-- frente L sobre o mundo rega o ciclo d'agua
		if w and w.hydro then
			for _, sy in ipairs(S.systems) do
				if sy.kind == "L" then
					if math.abs(sy.x) < half and math.abs(sy.z) < half then
						w.hydro.humidity = math.min(1.4, w.hydro.humidity + 0.02 * sy.int * dtm)
					end
				end
			end
		end
	end
end

function WEAX.stats()
	local lows, highs = 0, 0
	for _, sy in ipairs(S.systems) do
		if sy.kind == "L" then lows = lows + 1 else highs = highs + 1 end
	end
	return { running = S.running, systems = #S.systems, low = lows, high = highs,
		wind = string.format("%.1f,%.1f", S.wind.X, S.wind.Y), current = S.lastWeatherSet }
end

do
	if RX and RX.hook then RX.hook("weax", function(dt) WEAX.step(dt) end) end
end

_G.ArkherWeaX = WEAX
return WEAX
