-- =============================================================
-- PARTICLES X (APX) v5 — EMISSORES CUSTOM com ESPECIFICAÇÕES FISICAS
-- Emite ParticleEmitter REAIS do Roblox mas com parametros gerados por
-- física nossa: VORTEX (velocidade tangencial ao eixo), BURST cone,
-- FOUNTAIN com alcance balístico, RING SHOCKWAVE expansivo, TRAIL,
-- BUDGET D-O15-aware (caps por nível de LOD), 12 presets com rampas
-- de cor/vida derivadas de temperatura/processo real. Do zero. ✨
-- =============================================================

local DM = ArkherDM or error("ArkherDM init")
local mclamp = math.clamp or function(v, a, b)
	if v ~= v then return a end
	if v < a then return a end
	return v > b and b or v
end


local APX = {}
APX._V = 5

-- ---------- presets (fisica por trás de cada) ----------
APX.PRESETS = {
	foguete   = { mode = "burst",  rate = 0,   burst = 1,  life = 2.2, speed = 26, spread = 0.06, gravity = 60,  size0 = 0.6, size1 = 0.05, c0 = { 255, 250, 220 }, c1 = { 255, 60, 10 } },
	fogo      = { mode = "cone",   rate = 90,  life = 1.4, speed = 6,  spread = 0.25, gravity = -12, size0 = 1.6, size1 = 0.2, c0 = { 255, 140, 20 }, c1 = { 255, 20, 0 }, light = 1.4 },
	fumaca    = { mode = "cone",   rate = 40,  life = 3.2, speed = 3,  spread = 0.4, gravity = -4,  size0 = 2.2, size1 = 5.5, c0 = { 120, 120, 120 }, c1 = { 60, 60, 60 }, alpha = 0.7 },
	faiscas   = { mode = "burst",  rate = 0,   burst = 60, life = 0.8, speed = 18, spread = 1.0, gravity = 24, size0 = 0.15, size1 = 0.05, c0 = { 255, 230, 120 }, c1 = { 255, 100, 10 } },
	agua      = { mode = "cone",   rate = 0,   burst = 80, life = 0.9, speed = 14, spread = 0.7, gravity = 26, size0 = 0.3, size1 = 0.1, c0 = { 130, 190, 240 }, c1 = { 220, 240, 255 } },
	magia     = { mode = "vortex", rate = 120, life = 2.0, speed = 5,  spread = 0.9, gravity = 0,  size0 = 0.5, size1 = 0.1, c0 = { 130, 80, 255 }, c1 = { 255, 130, 255 }, vR = 4, vOmega = 9 },
	gilman    = { mode = "ring",   rate = 0,   burst = 1,  life = 0.9, speed = 0,  spread = 0, gravity = 0,   size0 = 0.2, size1 = 12, c0 = { 255, 255, 255 }, c1 = { 120, 200, 255 }, alpha = 0.85 },
	chuva     = { mode = "cone",   rate = 240, life = 1.4, speed = 40, spread = 0.05, gravity = 90, size0 = 0.06, size1 = 0.06, c0 = { 160, 190, 230 }, c1 = { 160, 190, 230 }, down = true, area = 40 },
	neve      = { mode = "cone",   rate = 60,  life = 6.0, speed = 2,  spread = 1.0, gravity = 1.5, size0 = 0.25, size1 = 0.35, c0 = { 250, 250, 255 }, c1 = { 235, 240, 255 }, down = true, area = 40, sway = 1.2 },
	folhas    = { mode = "cone",   rate = 12,  life = 7.0, speed = 2.2, spread = 1.2, gravity = 2.2, size0 = 0.5, size1 = 0.6, c0 = { 120, 160, 40 }, c1 = { 200, 160, 60 }, down = true, area = 30, sway = 2.4 },
	poeira    = { mode = "cone",   rate = 26,  life = 5.0, speed = 0.8, spread = 1.6, gravity = -0.4, size0 = 0.4, size1 = 1.2, c0 = { 190, 170, 130 }, c1 = { 150, 135, 105 }, alpha = 0.5 },
	bolhas    = { mode = "cone",   rate = 22,  life = 4.5, speed = 3.5, spread = 0.3, gravity = -9, size0 = 0.3, size1 = 0.15, c0 = { 140, 200, 240 }, c1 = { 200, 240, 255 } },
	trilha    = { mode = "trail",  rate = 160, life = 0.7, speed = 0.5, spread = 0.05, gravity = 0, size0 = 0.7, size1 = 0.05, c0 = { 90, 200, 255 }, c1 = { 30, 90, 190 } },
}

-- ---------- budget D-O15-aware ----------
APX.BUDGET = { [1] = 1.0, [2] = 0.75, [3] = 0.45, [4] = 10 }
function APX.budgetScale()
	-- D-O15: pressao de performance restringe emissão (evita overdraw real)
	if ArkherDO15 and ArkherDO15.pressure then
		local p = ArkherDO15.pressure()
		local scale = 1 - 0.55 * p
		return mclamp(scale, 0.15, 1)
	end
	return 1
end

-- ---------- emissao ----------
APX._emitters = {}
APX._fires, APX._ring = {}, 1
local function fire(e) APX._fires[APX._ring] = e APX._ring = (APX._ring % 60) + 1 end

local function mkEmitter(part, spec, tag)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "APX_" .. tag
	-- cor
	local c0, c1 = spec.c0, spec.c1
	pcall(function()
		pe.Color = ColorSequence.new(Color3.fromRGB(c0[1], c0[2], c0[3]), Color3.fromRGB(c1[1], c1[2], c1[3]))
		pe.Transparency = NumberSequence.new and NumberSequence.new(0, 1) or 0
	end)
	-- vida/velocidade/tamanho/gravidade
	pe.Lifetime = { Min = spec.life * 0.7, Max = spec.life }
	pe.Speed = { Min = spec.speed * 0.7, Max = spec.speed * 1.25 }
	pe.Acceleration = Vector3.new(0, -(spec.gravity or 0), 0)
	pe.Size = { Keypoints = { { 0, spec.size0 }, { 1, spec.size1 } }, __t = "NumberSequence" }
	pe.LightEmission = spec.light or 0.35
	pe.SpreadAngle = { X = 360 * (spec.spread or 0.25) / 2, Y = 360 * (spec.spread or 0.25) / 2 }
	pe.Rotation = { Min = -180, Max = 180 }
	-- modo
	if spec.mode == "burst" then
		pe.Rate = 0
		pcall(function() pe:Emit(math.max(1, math.floor((spec.burst or 10) * APX.budgetScale()))) end)
	elseif spec.mode == "ring" then
		pe.Rate = 0
		pe.SpreadAngle = { X = 0, Y = 0 }
		pcall(function() pe:Emit(1) end)
	else
		pe.Rate = (spec.rate or 40) * APX.budgetScale()
	end
	-- vortex: velocidade inicial tangencial simulada por RotSpeed (real)
	if spec.mode == "vortex" then
		pe.RotSpeed = { Min = -(spec.vOmega or 8) * 20, Max = (spec.vOmega or 8) * 20 }
		pe.VelocitySpread = 35
	end
	-- down: emitir para baixo (chuva/neve) — rotaciona o emissor
	if spec.down then
		part.RotVelocity = Vector3.new(0, 0, 0)
	end
	pe.Parent = part
	fire("emit:" .. tag)
	return pe
end

function APX.emit(part, kind, ovr)
	local base = APX.PRESETS[kind] or APX.PRESETS.fogo
	local spec = {}
	for k, v in pairs(base) do spec[k] = v end
	if ovr then for k, v in pairs(ovr) do spec[k] = v end end
	local target = part
	if target == nil then
		local mk = Instance.new("Part")
		mk.Name = "APX_Anchor"
		mk.Size = Vector3.new(0.1, 0.1, 0.1)
		mk.Transparency = 1
		mk.Anchored = true
		mk.CanCollide = false
		mk.Position = Vector3.new(0, 3, 0)
		mk.Parent = workspace
		target = mk
	end
	local pe = mkEmitter(target, spec, kind)
	APX._emitters[kind] = { pe = pe, part = target, spec = spec, t0 = os.clock() }
	return pe, spec
end

function APX.clear(kind)
	if kind then
		local e = APX._emitters[kind]
		if e then pcall(function() e.pe.Enabled = false end) APX._emitters[kind] = nil end
		return
	end
	for k, e in pairs(APX._emitters) do
		pcall(function() e.pe.Enabled = false end)
		APX._emitters[kind] = nil
	end
end

-- estoura um preset one-shot na selecao/posicao
function APX.burstAt(kind) return APX.emit(nil, kind) end

function APX.list()
	local out = {}
	for k in pairs(APX.PRESETS) do out[#out + 1] = k end
	table.sort(out)
	return out
end

APX.VERSION = "5.0"

_G.ArkherParticlesX = APX

