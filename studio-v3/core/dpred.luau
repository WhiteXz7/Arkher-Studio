-- DPRED (DPX) — D-O15 PREDICTIVE (tech ARKHER original, cat. Z/S):
-- o mundo nao reage: ele ANTECIPA. Este modulo estima por onde a percepcao
-- vai estar (velocidade+acentuacao EMA + horizonte adaptativo por tier),
-- alimenta o RRX/streaming com a POSICAO PREVISTA (pre-materializando antes
-- de chegar) e aprende um MAPA DE ATENCAO (dwell por celula) persistido na
-- memoria do projeto (THX.MEM) — o AWI e o mundo lembram onde voce vive.

local DM = rawget(_G, "ArkherDM")
local TX = rawget(_G, "ArkherTheoryX")
local RX = rawget(_G, "ArkherRealityX")

local V3 = Vector3.new
local DPX = {}
local S = {
	on = true,
	pos = nil, vel = V3(), acc = V3(),
	lastPos = nil, lastVel = nil, t = 0,
	heat = {}, -- heatmap celula(28 studs) -> dwell
	heatCell = 28,
	predPos = V3(), horizon = 1.6,
}

-- leitura da memoria do projeto (o AWI lembra entre mundos)
if TX and TX.memGet then
	S.heat = TX.memGet("dpred", "heatmap") or {}
end

function DPX.setOn(on) S.on = on and true or false return S.on end

function DPX.horizonByTier()
	local t = (TX and TX.activeTier) or { weatherHz = 2 }
	-- tier alto: horizon maior (olha mais longe, mais casca preditiva)
	return 0.9 + (t.weatherHz or 2) * 0.45
end

-- passo preditivo REAL: EMA de velocidade+acentuacao -> posicao prevista
function DPX.step(dt)
	if not S.on then RX.S.predPos = nil return end
	S.t = S.t + dt
	local cam = workspace.CurrentCamera
	if not cam then return end
	local p = cam.CFrame.Position
	-- EMA (estabilidade histeretica da tese: trepidação NAO vira previsão)
	local k = math.min(1, dt * 6)
	if S.lastPos then
		local v0 = (p - S.lastPos) / math.max(dt, 1e-3)
		S.vel = S.vel + (v0 - S.vel) * k
		if S.lastVel then
			local a0 = (v0 - S.lastVel) / math.max(dt, 1e-3)
			S.acc = S.acc + (a0 * 0.5 - S.acc) * k * 0.6 -- amortecido: acel. e ruidosa
		end
		S.lastVel = v0
	end
	S.lastPos = p
	-- previsao: p + v*t + 0.5*a*t^2 (horizonte por tier, saturado)
	local H = DPX.horizonByTier()
	local vMag = S.vel.Magnitude
	if vMag > 140 then S.vel = S.vel.Unit * 140 end -- anti-spike
	local pp = p + S.vel * H + S.acc * (0.5 * H * H)
	-- saturação de percepção: nao projetar além do raio de streaming
	local off = pp - p
	if off.Magnitude > 260 then pp = p + off.Unit * 260 end
	S.predPos = pp
	RX.S.predPos = pp
	-- MAPA DE ATENCAO: dwell por celula onde o jogador PASSA TEMPO
	local kc = math.floor(p.X / S.heatCell) .. ":" .. math.floor(p.Z / S.heatCell)
	S.heat[kc] = (S.heat[kc] or 0) + dt
end

-- hotspots de atenção (onde o jogador vive; o mundo pode CAPRICAR ali)
function DPX.topCells(n)
	local arr = {}
	for kc, d in pairs(S.heat) do arr[#arr + 1] = { k = kc, d = d } end
	table.sort(arr, function(a, b) return a.d > b.d end)
	local out = {}
	for i = 1, math.min(n or 3, #arr) do out[i] = arr[i] end
	return out
end

-- importante para AWI: quanta atenção uma posição tem (influencia importance)
function DPX.attendAt(x, z)
	local kc = math.floor(x / S.heatCell) .. ":" .. math.floor(z / S.heatCell)
	local d = S.heat[kc] or 0
	return math.clamp(d / 120, 0, 1) -- 2 min de dwell = atenção máxima
end

-- persiste o conhecimento (memoria de projeto — complemento 14 da tese)
function DPX.flush()
	if TX and TX.memPut then
		TX.memPut("dpred", "heatmap", S.heat)
	end
end

function DPX.stats()
	local hot = DPX.topCells(3)
	local hs = {}
	for _, h2 in ipairs(hot) do hs[#hs + 1] = ("%s:%.0fs"):format(h2.k, h2.d) end
	return {
		on = S.on, vel = S.vel.Magnitude, horizon = string.format("%.1fs", DPX.horizonByTier()),
		pred = string.format("%.0f,%.0f,%.0f", S.predPos.X, S.predPos.Y, S.predPos.Z),
		heatCells = (function() local n = 0 for _ in pairs(S.heat) do n = n + 1 end return n end)(),
		hotspots = table.concat(hs, " · "),
	}
end

_G.ArkherDPred = DPX
return DPX
