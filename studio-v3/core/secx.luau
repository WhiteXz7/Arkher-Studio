-- SEC X (SECX) — SEGURANCA da ponte (cat. X 12501-12900 dos TXT):
-- o unico caminho cliente->servidor (ArkherXQ) passa por aqui: rate limit
-- por jogador (janela deslizante), tamanho/payload higienizado e TRILHA DE
-- AUDITORIA. Modelo Roblox nativo: servidor nunca confia no cliente.

local SECX = {}
local S = {
	on = true,
	limit = 10,        -- invokes/seg/jogador
	win = 1.0,
	buckets = {},      -- player -> {t0, count}
	audit = {},        -- ring buffer (ultimos 200)
	viol = 0,
}

local function log(player, op, ok2)
	S.audit[#S.audit + 1] = { t = os.clock(), player = player and player.Name or "?", op = tostring(op), ok = ok2 }
	if #S.audit > 200 then table.remove(S.audit, 1) end
end

function SECX.allow(player, payload)
	local op = (type(payload) == "table" and payload.op) or "?"
	if not S.on then
		log(player, op, true)
		return true
	end
	-- higiene basica do payload
	if type(payload) ~= "table" then
		S.viol = S.viol + 1
		log(player, "payload-invalido", false)
		return false
	end
	-- rate limit por jogador (janela deslizante simples)
	local now = os.clock()
	local b = S.buckets[player]
	if not b or (now - b.t0) > S.win then
		b = { t0 = now, count = 0 }
		S.buckets[player] = b
	end
	b.count = b.count + 1
	local ok2 = b.count <= S.limit
	if not ok2 then S.viol = S.viol + 1 end
	log(player, op, ok2)
	return ok2
end

function SECX.arm(on) S.on = on and true or false return S.on end

function SECX.stats()
	local recent = {}
	for i = math.max(1, #S.audit - 6), #S.audit do
		local a = S.audit[i]
		recent[#recent + 1] = ("%s:%s%s"):format(a.player, a.op, a.ok and "" or "✗")
	end
	return { on = S.on, violations = S.viol, audited = #S.audit, recent = table.concat(recent, " · ") }
end

_G.ArkherSecX = SECX
return SECX
