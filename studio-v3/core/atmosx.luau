-- =============================================================
-- ATMOS X (AEX) v5 — CÉU + CLIMA CUSTOM (nao depende da atmosfera padrao)
-- CICLO DIA-NOITE REAL: temperatura de COR do sol em Kelvin -> RGB
-- via aproximacao Planckian/CIE (mesma teoria RRW: dado fisico real
-- -> representacao adaptativa), nuvens orgânicas, weather machine com
-- 7 estados e TRANSIÇÕES suaves, relâmpagos agendados, links AWX/AUX.
-- Do zero, determinístico, deterministic-pump. ⚡🌤️
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local AEX = {}
AEX._V = 5

-- ---------- dados fisicos ----------
-- presets de horario: infos fisicas (elevacao solar, kelvin do disco)
AEX.SKY_PRESETS = {
	madrugada = { clock = 5.5,   fogEnd = 12000, kelvin = 2200, haze = 4.0 },
	amanhecer = { clock = 6.8,   fogEnd = 30000, kelvin = 3200, haze = 2.4 },
	meiodia   = { clock = 12.0,  fogEnd = 60000, kelvin = 5600, haze = 0.7 },
	tarde     = { clock = 15.5,  fogEnd = 50000, kelvin = 5200, haze = 1.2 },
	entardecer= { clock = 18.3,  fogEnd = 24000, kelvin = 3600, haze = 3.2 },
	noite     = { clock = 23.5,  fogEnd = 20000, kelvin = 1900, haze = 1.0, stars = true },
}

-- weather machine: cada estado com parcelas fisicas
AEX.WEATHER = {
	limpo     = { fogEnd = 60000, haze = 0.7,  rain = 0, wind = 0.05, cloud = 0.10, waveBoost = 1.00, volBoost = 0.00 },
	nuvem     = { fogEnd = 30000, haze = 2.5,  rain = 0, wind = 0.25, cloud = 0.65, waveBoost = 1.15, volBoost = 0.05 },
	chuva     = { fogEnd = 8000,  haze = 5.0,  rain = 1, wind = 0.55, cloud = 0.90, waveBoost = 1.60, volBoost = 0.18 },
	tempestade= { fogEnd = 4500,  haze = 7.5,  rain = 1, wind = 1.00, cloud = 1.00, waveBoost = 2.20, volBoost = 0.30, lightning = true },
	neblina   = { fogEnd = 1800,  haze = 9.0,  rain = 0, wind = 0.05, cloud = 0.40, waveBoost = 1.00, volBoost = 0.03 },
	neve      = { fogEnd = 12000, haze = 4.0,  rain = 0, wind = 0.35, cloud = 0.80, waveBoost = 1.10, volBoost = 0.10, snow = true },
	aurora    = { fogEnd = 50000, haze = 0.4,  rain = 0, wind = 0.10, cloud = 0.05, waveBoost = 1.00, volBoost = 0.05, stars = true },
}

-- ---------- Kelvin -> RGB (CIE 1931 aproximacao real) ----------
function AEX.kelvinRGB(k)
	local t = mclamp(k, 1000, 12000) / 100
	local r, g, b
	if t <= 66 then r = 255 else r = mclamp(329.7 * (t - 60) ^ -0.1332, 0, 255) end
	if t <= 66 then g = mclamp(99.47 * math.log(math.max(t, 1)) - 161.12, 0, 255)
	else g = mclamp(288.12 * (t - 60) ^ -0.0755, 0, 255) end
	if t >= 66 then b = 255 elseif t <= 19 then b = 0
	else b = mclamp(138.52 * math.log(t - 10) - 305.04, 0, 255) end
	return Color3.fromRGB(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

-- ---------- estado ----------
local function mk(max)
	return { t = 0, phase = DM.hash3(1, 3, 5, 77) * 100 }
end

local S = {
	state = "limpo",
	prev = "limpo",
	blend = 1,          -- 1 = estado alvo atual
	blendSpeed = 0.35,  -- por segundo
	preset = "meiodia",
	clock = 12,
	cycleSpeed = 0.0045, -- horas por segundo (1 hora solar amplificada)
	lightning_at = 0,
	_state = mk(),
	_fires = {}, ring = 1,
	links = { waves = true, audio = true },
}
AEX.S = S

local function fire(event)
	S._fires[S.ring] = event
	S.ring = (S.ring % 60) + 1
end

-- ---------- instancias reais ----------
local function ensureReal(obj)
	if obj and obj.lighting then S._lig = obj.lighting end
	if not S._lig and game then
		local ok, lig = pcall(function() return game:GetService("Lighting") end)
		if ok then S._lig = lig end
	end
	-- efeitos REAIS
	if S._lig then
		S._atmo = S._lig:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
		S._atmo.Parent = S._lig
		S._cc = S._lig:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
		S._cc.Parent = S._lig
	end
	return S._lig ~= nil
end

-- ---------- estado maxwell (calcula multiplicadores do clima) ----------
function AEX.weatherMix(k)
	local cur = AEX.WEATHER[S.state]
	local pre = AEX.WEATHER[S.prev]
	local a = S.blend
	local function lerp(f) return pre[f] * (1 - a) + cur[f] * a end
	return {
		fogEnd = lerp("fogEnd"),
		haze = lerp("haze"),
		rain = lerp("rain"),
		wind = lerp("wind"),
		cloud = lerp("cloud"),
		waveBoost = lerp("waveBoost"),
		volBoost = lerp("volBoost"),
		lightning = cur.lightning and a > 0.7,
		snow = cur.snow and a > 0.7,
		stars = cur.stars or (k and k.stars),
	}
end

-- ---------- aplicacao REAL ----------
function AEX.apply(obj)
	obj = obj or {}
	local lig = S._lig or (obj.lighting)
	if lig == nil then return false end
	local p = AEX.SKY_PRESETS[S.preset] or AEX.SKY_PRESETS.meiodia
	local w = AEX.weatherMix(p)
	-- hora real (ClockTime)
	pcall(function() lig.ClockTime = S.clock end)
	-- cor do disco solar em Kelvin -> ambient/outdoor
	local kRGB = AEX.kelvinRGB(p.kelvin)
	pcall(function()
		if lig.Ambient ~= nil then lig.Ambient = kRGB end
		if lig.OutdoorAmbient ~= nil then lig.OutdoorAmbient = kRGB end
		lig.FogEnd = w.fogEnd
		if lig.FogColor ~= nil then lig.FogColor = kRGB end
	end)
	if S._atmo then
		pcall(function()
			S._atmo.Density = mclamp(0.18 + w.haze / 40, 0, 0.6)
			S._atmo.Haze = mclamp(w.haze, 0, 10)
		end)
	end
	-- ceu fisico: estrelas à noite ou com auroras
	if lig then
		local sky = lig:FindFirstChildOfClass("Sky")
		if w.stars and not sky then
			local ok, ns = pcall(function() return Instance.new("Sky") end)
			if ok and ns then pcall(function() ns.Parent = lig end) end
		end
	end
	return true
end

-- ---------- vitimas do clima (links AWX/AUX) ----------
function AEX.pushLinks(w)
	if S.links.waves and ArkherWaterX then
		for _, b in ipairs(ArkherWaterX.bodies) do
			for _, wv in ipairs(b.waves) do
				wv._isWave = true
			end
			b._stormBoost = w.waveBoost
			b._baseAmp = b._baseAmp or {}
			b._baseSpd = b._baseSpd or {}
			for i = 1, #b.waves do
				if b._baseAmp[i] == nil then b._baseAmp[i] = b.waves[i].amp or 0.1 end
				if b._baseSpd[i] == nil then b._baseSpd[i] = b.waves[i].speed or 1 end
				b.waves[i].amp = b._baseAmp[i] * w.waveBoost
				b.waves[i].speed = b._baseSpd[i] * (0.85 + w.wind * 0.4)
			end
		end
	end
	if S.links.audio and ArkherAudioX then
		for _, ev in ipairs(ArkherAudioX._ambients) do
			if ev.dayNight == "rain" then ev.likelihood = math.min(0.3 + w.rain * 0.7, 1) end
		end
		local grp = ArkherAudioX._groups and ArkherAudioX._groups.weather
		if grp then grp.Volume = mclamp(0.06 + w.volBoost, 0, 1) end
	end
end

-- ---------- pump deterministico ----------
function AEX.pump(dt)
	dt = dt or 1 / 60
	S._state.t = S._state.t + dt
	-- ciclo solar (cycleSpeed horas por segundo)
	S.clock = (S.clock + dt * S.cycleSpeed) % 24
	-- transicao do clima
	if S.blend < 1 then
		S.blend = math.min(1, S.blend + dt * S.blendSpeed)
	end
	local w = AEX.weatherMix(nil)
	-- relâmpago agendado fisicamente (tempestade)
	if w.lightning and S._state.t >= S.lightning_at then
		S.lightning_at = S._state.t + 1.5 + DM.hash3(math.floor(S._state.t), 7, 11, 41) * 6
		fire("lightning")
		if S._cc then
			pcall(function() S._cc.Brightness = 0.18 end)
		end
		if ArkherAudioX then
			pcall(function() ArkherAudioX.playSfx("ARK_THUNDER", "weather", { pitch = 0.9, volume = 0.9 }) end)
		end
	end
	-- decaimento do flash
	if S._cc and S._cc.Brightness and S._cc.Brightness > 0.0001 then
		pcall(function() S._cc.Brightness = math.max(0, S._cc.Brightness - dt * 0.6) end)
	end
	AEX.apply()
	AEX.pushLinks(w)
	return S.clock, w
end

-- ---------- API PUBLICA ----------
function AEX.setPreset(name)
	if AEX.SKY_PRESETS[name] then S.preset = name S.clock = AEX.SKY_PRESETS[name].clock fire("preset:" .. name) return true end
	return false
end
function AEX.setWeather(name, speedo)
	if not AEX.WEATHER[name] then return false end
	S.prev = S.state
	S.state = name
	S.blend = 0
	S.blendSpeed = speedo or 0.35
	fire("weather:" .. name)
	return true
end
function AEX.setClock(h) S.clock = (h or 12) % 24 return true end
function AEX.setup(obj) return ensureReal(obj or {}) end
function AEX.skyDayNight() return S.clock, S.state, S.blend end

AEX._setup = ensureReal

AEX.VERSION = "5.0"

_G.ArkherAtmosX = AEX

