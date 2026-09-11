--[[ ARKHER AUDIO X (AUX) — motor de audio/mixer CUSTOM ]]
-- Vai alem do "tocar um Sound": arquitetura de MIXAGEM com SoundGroups REAIS
-- (master/sfx/music/ui/ambient/weather/voice), DSP do engine (Reverb, Echo,
-- Compressor, Distortion, Equalizer, Flange, Tremolo, PitchShift), presets
-- acusticos (caverna, estadio, campo aberto, subaquatico, radio), DUCKING
-- sidechain (voz abaixa a musica com envelope), crossfade de camadas
-- adaptativas (explore/combat/night), scheduler de ambiente com controle
-- de repeticao (never-repeats-recent), posicionamento 3D simulado com
-- rolloff real (inverso-quadratico) + doppler aproximado, e link com AWX
-- (ondas ressacam => vento/mono de mar alto sobe).
ArkherAudioX = ArkherAudioX or {}
local AUX = ArkherAudioX
local DM = ArkherDM
local floor, abs, sqrt, clamp = math.floor, math.abs, math.sqrt, DM.clamp
local soundService
do local ok, s = pcall(function() return game:GetService("SoundService") end) if ok then soundService = s end end
local RunService
do local ok, s = pcall(function() return game:GetService("RunService") end) if ok then RunService = s end end

-- ================= BUSES (SoundGroups REAIS) =================
AUX.BUSES = { "master", "music", "sfx", "ui", "ambient", "weather", "voice" }
AUX._groups = {}
function AUX._group(name)
	local g = AUX._groups[name]
	if g then return g end
	if soundService then
		local parent = name == "master" and soundService or AUX._group("master")
		g = Instance.new("SoundGroup")
		g.Name = "AUX_" .. name
		g.Volume = 1
		g.Parent = parent
	else
		g = { Name = "AUX_" .. name, Volume = 1, _shimBus = true }
	end
	AUX._groups[name] = g
	return g
end
function AUX.setup()
	for _, b in ipairs(AUX.BUSES) do AUX._group(b) end
	return AUX._groups
end
function AUX.busVolume(name) local g = AUX._group(name) return g and g.Volume end
function AUX.setBusVolume(name, v)
	local g = AUX._group(name)
	if g then pcall(function() g.Volume = clamp(v, 0, 10) end) end
	return v
end

-- ================= DSP / PRESETS ACUSTICOS =================
-- cada preset liga efeitos REAIS no SoundGroup da bus
AUX.ACOUSTICS = {
	flat = {},
	caverna = {
		{ "ReverbSoundEffect", { DecayTime = 4.5, Density = 1, Diffusion = 1, DryLevel = -6, WetLevel = -2 } },
		{ "EchoSoundEffect", { Delay = 0.18, Feedback = 0.35, WetLevel = -12 } },
	},
	estadio = {
		{ "ReverbSoundEffect", { DecayTime = 3.2, Density = 1, Diffusion = 0.85, DryLevel = -3, WetLevel = 0 } },
		{ "EchoSoundEffect", { Delay = 0.09, Feedback = 0.22, WetLevel = -16 } },
		{ "CompressorSoundEffect", { Threshold = -14, Ratio = 3, Attack = 0.02, Release = 0.15, GainMakeup = 4 } },
	},
	estudio = {
		{ "CompressorSoundEffect", { Threshold = -10, Ratio = 2.5, Attack = 0.005, Release = 0.1, GainMakeup = 2 } },
		{ "EqualizerSoundEffect", { LowGain = 1.5, MidGain = 0.8, HighGain = 0.4 } },
	},
	subaquatico = {
		{ "PitchShiftSoundEffect", { Octave = 0.5 } },
		{ "ReverbSoundEffect", { DecayTime = 2.8, Density = 0.9, Diffusion = 1, DryLevel = -8, WetLevel = -4 } },
		{ "EqualizerSoundEffect", { LowGain = 5, MidGain = -6, HighGain = -18 } },
	},
	radio = { -- telefone/radio AM
		{ "EqualizerSoundEffect", { LowGain = -18, MidGain = 4, HighGain = -14 } },
		{ "DistortionSoundEffect", { Level = 0.25 } },
	},
	floresta = {
		{ "ReverbSoundEffect", { DecayTime = 1.6, Density = 0.8, Diffusion = 0.7, DryLevel = -4, WetLevel = -10 } },
	},
	metal = { -- metal/catedral de metal
		{ "FlangeSoundEffect", { Depth = 0.4, Mix = 0.35, Rate = 0.8 } },
		{ "ReverbSoundEffect", { DecayTime = 2.2, Density = 1, Diffusion = 0.9, DryLevel = -5, WetLevel = -8 } },
	},
}
function AUX.patch(busName, presetId)
	if not soundService then return false, "SoundService indisponivel" end
	local g = AUX._group(busName)
	local preset = AUX.ACOUSTICS[presetId or "flat"] or AUX.ACOUSTICS.flat
	-- limpa efeitos anteriores AUX
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
	for _, spec in ipairs(preset) do
		local cls, params = spec[1], spec[2]
		local ok, fx = pcall(function()
			local e = Instance.new(cls)
			e.Name = "AUX_" .. cls
			e.Enabled = true
			e.Priority = 0
			for k, v in pairs(params or {}) do pcall(function() e[k] = v end) end
			e.Parent = g
			return e
		end)
		if not ok then return false, "efeito " .. cls .. " falhou" end
	end
	return true, #preset
end
function AUX.clearPatch(busName)
	local g = AUX._group(busName)
	for _, ch in ipairs(g:GetChildren()) do
		if ch.Name:sub(1, 4) == "AUX_" then ch:Destroy() end
	end
end

-- ================= REGISTRY DE SONS =================
AUX._sounds = {} -- id -> {inst, def}
function AUX.register(id, def)
	def = def or {}
	local s
	if soundService then
		s = Instance.new("Sound")
		s.Name = "AUX_S_" .. id
		s.SoundId = def.id or (def.asset and ("rbxassetid://" .. tostring(def.asset)) or "")
		s.Volume = def.volume or 0.5
		s.PlaybackSpeed = def.pitch or 1
		s.Looped = def.looped or false
		if def.bus then s.SoundGroup = AUX._group(def.bus) end
		s.Parent = soundService
	else
		s = { Name = id, Volume = def.volume or 0.5, Playing = false, Looped = def.looped or false }
	end
	AUX._sounds[id] = { inst = s, def = def, bus = def.bus or "sfx" }
	return s
end
function AUX.play(id, opts)
	opts = opts or {}
	local reg = AUX._sounds[id]
	if not reg then
		AUX.register(id, opts.def or { bus = opts.bus })
		reg = AUX._sounds[id]
	end
	local s = reg.inst
	pcall(function()
		if opts.volume then s.Volume = opts.volume end
		if opts.pitch then s.PlaybackSpeed = opts.pitch end
		s:Play()
	end)
	reg.playing = true
	if not soundService then s.Playing = true end
	return s
end
function AUX.stop(id)
	local reg = AUX._sounds[id]
	if reg then reg.playing = false pcall(function() reg.inst:Stop() end) reg.inst.Playing = false end
end

-- ================= DUCKING (sidechain real com envelope) =================
-- quando bus trigger toca, alvo abaixa p/ duckLevel com attack, volta com release
AUX._ducks = {}
function AUX.duck(targetBus, triggerBus, opts)
	opts = opts or {}
	AUX._ducks[#AUX._ducks + 1] = {
		target = targetBus, trigger = triggerBus,
		level = opts.level or 0.35, attack = opts.attack or 0.08, release = opts.release or 0.9,
		hold = opts.hold or 0.6, t = 0, env = 1, state = "idle",
	}
end
local function busIsPlaying(busName)
	for _, reg in pairs(AUX._sounds) do
		if reg.bus == busName and reg.playing then return true end
	end
	return false
end
function AUX._pumpDucks(dt)
	for _, d in ipairs(AUX._ducks) do
		local g = AUX._groups[d.target]
		if g then
			local active = busIsPlaying(d.trigger)
			if active then
				d.state = "ducking"
				d.env = math.max(d.level, d.env - dt / math.max(d.attack, 0.001))
				if d.env <= d.level then d.state = "hold" d.t = 0 end
			else
				if d.state == "hold" then
					d.t = d.t + dt
					if d.t >= d.hold then d.state = "release" end
				elseif d.state ~= "idle" then
					d.state = d.state == "ducking" and "release" or d.state
					d.env = math.min(1, d.env + dt / math.max(d.release, 0.001))
					if d.env >= 1 then d.state = "idle" d.env = 1 end
				end
			end
			pcall(function() g.Volume = d.env * (AUX._baseVol and AUX._baseVol[d.target] or 1) end)
		end
	end
end

-- ================= MUSIC LAYERS (adaptativo) =================
AUX._layers = nil -- {base=regId, tension=regId, combat=regId, intensity=0..1}
function AUX.musicLayers(defs)
	-- defs = { base = id, tension = id, combat = id } de sons registrados (loop)
	AUX._layers = { defs = defs, intensity = 0 }
	for role, id in pairs(defs) do
		local s = AUX._sounds[id] and AUX._sounds[id].inst
		if s then pcall(function() s.Looped = true s:Play() s.Volume = role == "base" and (AUX._sounds[id].def.volume or 0.5) or 0 end) end
	end
	return AUX._layers
end
function AUX.setIntensity(v) -- 0..2 (0 paz, 1 tensao, 2 combate)
	if not AUX._layers then return end
	AUX._layers.intensity = clamp(v, 0, 2)
end
function AUX._pumpLayers(dt)
	local L = AUX._layers
	if not L then return end
	local int = L.intensity or 0
	local targets = { base = clamp(1 - int, 0.25, 1), tension = clamp(1 - abs(int - 1), 0, 1), combat = clamp(int - 1, 0, 1) }
	for role, id in pairs(L.defs) do
		local reg = AUX._sounds[id]
		if reg then
			local base = reg.def.volume or 0.5
			local want = base * (targets[role] or 1)
			local cur = 0
			pcall(function() cur = reg.inst.Volume end)
			cur = cur or 0
			local nv = cur + (want - cur) * clamp(dt * 4, 0, 1)
			pcall(function() reg.inst.Volume = nv end)
		end
	end
end

-- ================= AMBIENT SCHEDULER (nunca repete os 2 ultimos) =================
AUX._ambients = {}
function AUX.ambient(name, spec)
	-- spec: { ids = {a,b,c}, interval = {min,max}, bus = "ambient", condition = fn,
	-- volume = {min,max}, pitched = {min,max} }
	local am = {
		name = name, ids = spec.ids or {}, bus = spec.bus or "ambient",
		interval = spec.interval or { 18, 42 }, volume = spec.volume or { 0.2, 0.5 },
		pitchRange = spec.pitch or { 0.9, 1.1 }, condition = spec.condition,
		timer = 0, running = false, last2 = {}, rng = 1234567,
	}
	function am:nextIn()
		return self.interval[1] + (self.interval[2] - self.interval[1]) * DM.hash2(self.rng, 77, 555)
	end
	function am:pick()
		if #self.ids == 0 then return nil end
		local tries = 0
		while tries < 8 do
			local i = 1 + floor(DM.hash2(self.rng, tries, 91) * #self.ids)
			local id = self.ids[i]
			if id ~= self.last2[1] and id ~= self.last2[2] then return id end
			tries = tries + 1
		end
		return self.ids[1]
	end
	function am:start()
		self.running = true
		self.timer = self:nextIn() * 0.3
	end
	function am:stop() self.running = false end
	function am:pump(dt)
		if not self.running then return false end
		if self.condition and not self.condition() then return false end
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = self:nextIn()
			self.rng = self.rng + 1
			local id = self:pick()
			if id then
				local vol = self.volume[1] + (self.volume[2] - self.volume[1]) * DM.hash2(self.rng, 3, 9)
				local pit = self.pitchRange[1] + (self.pitchRange[2] - self.pitchRange[1]) * DM.hash2(self.rng, 5, 7)
				AUX.play(id, { volume = vol, pitch = pit, bus = self.bus, def = { bus = self.bus, volume = vol } })
				self.last2[2] = self.last2[1]
				self.last2[1] = id
				return true
			end
		end
		return false
	end
	AUX._ambients[name] = am
	return am
end

-- ================= POSICIONAL 3D SIMULADO (rolloff^2 + doppler) =================
AUX._posTracked = {}
function AUX.positional(soundOrId, getPosFn, opts)
	opts = opts or {}
	local reg = AUX._sounds[soundOrId]
	local snd = reg and reg.inst or soundOrId
	local tr = {
		snd = snd, getPos = getPosFn, refDist = opts.refDist or 12, maxDist = opts.maxDist or 120,
		baseVol = opts.volume or (snd and snd.Volume) or 0.5, doppler = opts.doppler ~= false,
		lastPos = nil, lastVel = 0,
	}
	AUX._posTracked[#AUX._posTracked + 1] = tr
	return tr
end
local function camPos()
	local ws = workspace
	local cam = ws and ws.CurrentCamera
	if cam and cam.CFrame then return cam.CFrame.Position end
	return nil
end
function AUX._pumpPositional(dt)
	for _, tr in ipairs(AUX._posTracked) do
		local cp = camPos()
		local wp = tr.getPos and tr.getPos()
		if cp and wp and tr.snd then
			local dx, dy, dz = cp.X - wp.X, cp.Y - wp.Y, cp.Z - wp.Z
			local d = sqrt(dx * dx + dy * dy + dz * dz)
			-- rolloff inverso-quadratico (real) com clamp
			local g = clamp((tr.refDist / math.max(d, tr.refDist)) ^ 2, 0, 1)
			if d > tr.maxDist then g = 0 end
			-- doppler aproximado: velocidade radial do emissor
			local pitch = 1
			if tr.doppler and tr.lastPos and dt > 0 then
				local vx = (wp.X - tr.lastPos.X) / dt
				local vy = (wp.Y - tr.lastPos.Y) / dt
				local vz = (wp.Z - tr.lastPos.Z) / dt
				local speed = sqrt(vx * vx + vy * vy + vz * vz)
				local radial = speed * (dx / math.max(d, 1e-4))
				pitch = clamp(1 + radial / 343 * 6, 0.7, 1.4) -- exagero artistico
			end
			tr.lastPos = wp
			pcall(function()
				tr.snd.Volume = tr.baseVol * g
				tr.snd.PlaybackSpeed = pitch
			end)
		end
	end
end

-- ================= LINK AWX (mar alto => vento ondulante) =================
function AUX.linkSea(sea, ambientName, opts)
	opts = opts or {}
	local am = AUX._ambients[ambientName]
	if not am or not sea then return false end
	am.condition = function()
		local h = 0
		for w = 1, #sea.waves do h = h + (sea.waves[w].amp or 0) end
		return h >= (opts.minAmp or 0.4)
	end
	return true
end

-- ================= PUMP GLOBAL =================
AUX._fires = {}
function AUX.pump(dt)
	dt = dt or 0.016
	AUX._pumpDucks(dt)
	AUX._pumpLayers(dt)
	for name, am in pairs(AUX._ambients) do
		if am:pump(dt) then
			AUX._fires[#AUX._fires + 1] = { name = name, t = (tick and tick()) or os.clock() }
			if #AUX._fires > 8 then table.remove(AUX._fires, 1) end
		end
	end
	AUX._pumpPositional(dt)
end
function AUX.stats()
	local n, playing = 0, 0
	for _, reg in pairs(AUX._sounds) do
		n = n + 1
		local ok, p = pcall(function() return reg.inst.IsPlaying or reg.inst.Playing end)
		if ok and p then playing = playing + 1 end
	end
	return {
		sounds = n, playing = playing, buses = #AUX.BUSES,
		ducks = #AUX._ducks, ambients = (function() local c = 0 for _ in pairs(AUX._ambients) do c = c + 1 end return c end)(),
		positional = #AUX._posTracked, layers = AUX._layers and AUX._layers.intensity or nil,
	}
end

AUX._version = "1.0.0"
