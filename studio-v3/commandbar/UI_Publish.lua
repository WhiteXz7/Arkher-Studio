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
--[[ ARKHER V3 — UI: PUBLISH ]]
-- Layout unico: preview do manifest a esquerda, PIPELINE de publicacao no
-- centro (local / endpoint / nativo — botoes REAIS), historico a direita.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#2ED573")

local function build()
	local g, root, head = K.window("ArkherPublish", "PUBLISH — sem Open API", 24, 480, 560, 392, { pin = true })
	K.f(head, "Acc", 0, 24, 560, 2, ACCENT)

	-- ===== ESQUERDA: MANIFEST =====
	local left = K.f(root, "Man", 8, 34, 150, 250, T.bg4)
	K.corner(left, 4)
	K.txt(left, "MANIFEST", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local m = ArkherPublish.manifest()
	local curBytes = 0
	for _, p in ipairs(ArkherPlaces.list()) do
		if p.id == ARKHER.STATE.placeId then curBytes = p.bytes or 0 end
	end
	K.row(left, "Nome", m.name or "?", 28)
	K.row(left, "Desc", string.sub(m.description or "place", 1, 14), 52)
	K.row(left, "Genre", m.genre or "game", 76)
	K.row(left, "Tags", tostring(m.tags and #m.tags or 0), 100)
	K.row(left, "Bytes", string.format("%.1fK", curBytes / 1024), 124)
	K.row(left, "Criado", string.sub(tostring(m.created or "?"), 1, 10), 148)
	K.thumb(left, 10, 172, 130, 44, m.name or "place", T.sec, T.bg3)
	K.txt(left, "icone do place", 10, 222, 120, 14, 8, T.txt4)

	-- ===== CENTRO: PIPELINE =====
	local cv = K.f(root, "Pipe", 170, 34, 250, 250, T.bg0)
	K.corner(cv, 4)
	K.stroke(cv, T.line, 1)
	K.txt(cv, "PIPELINE", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	-- etapas
	local steps = {
		{ nm = "1. Bundle do place", d = "serializa workspace + luz + scripts" },
		{ nm = "2. Manifest", d = "nome, desc, genre, tags, bytes" },
		{ nm = "3. Destino", d = "local / endpoint / Studio nativo" },
	}
	for i, st in ipairs(steps) do
		local y = 28 + (i - 1) * 34
		local done = i < 3
		local dot = K.f(cv, "Sd" .. i, 10, y + 4, 10, 10, done and ACCENT or T.bg4, 5)
		K.stroke(dot, done and ACCENT or T.line2, 1.5)
		K.txt(cv, st.nm, 28, y, 200, 14, 10, T.txt)
		K.txt(cv, st.d, 28, y + 14, 210, 12, 8, T.txt4)
		if i < 3 then K.f(cv, "Sl" .. i, 14, y + 16, 2, 18, T.line) end
	end
	-- botoes de destino
	local bLocal = K.btn(cv, "Local", 10, 136, 110, 26, ACCENT, 5)
	K.txtS(bLocal, "Publicar local", 9, C("#04140A"))
	K.hover(bLocal, ACCENT, C("#6FE39A"))
	bLocal.MouseButton1Click:Connect(function()
		local ok = ArkherPublish.toLocal()
		ARKHER.out(ok and "SUCCESS" or "ERROR", "Publish: local -> " .. tostring(ok))
		refreshHist()
	end)
	local bEp = K.btn(cv, "Ep", 130, 136, 110, 26, T.bg2, 5)
	K.txtS(bEp, "Endpoint", 10, T.txt)
	K.hover(bEp, T.bg2, T.hover)
	bEp.MouseButton1Click:Connect(function()
		ArkherPublish.toEndpoint()
		refreshHist()
	end)
	local bNat = K.btn(cv, "Nat", 10, 170, 230, 26, T.bg2, 5)
	K.txtS(bNat, "Roblox nativo (delega ao Studio)", 9, T.txt)
	K.hover(bNat, T.bg2, T.hover)
	bNat.MouseButton1Click:Connect(function()
		ArkherPublish.toRobloxNative()
	end)
	K.txt(cv, "sem Open Cloud, sem JWT, sem API key do Roblox", 10, 206, 240, 28, 9, T.txt4)

	-- ===== DIREITA: HISTORICO =====
	local right = K.f(root, "Hist", 432, 34, 120, 250, T.bg4)
	K.corner(right, 4)
	K.txt(right, "HISTORICO", 10, 6, 100, 14, 10, T.txt3, ARKHER.FONTB)
	local histArea = K.f(right, "H", 0, 24, 120, 150)
	local function refreshHist()
		for _, ch in ipairs(histArea:GetChildren()) do ch:Destroy() end
		local h = ArkherPublish.history()
		if #h == 0 then
			K.txt(histArea, "(nada publicado)", 10, 6, 104, 20, 9, T.txt4)
			return
		end
		for i, e in ipairs(h) do
			if i > 5 then break end
			K.txt(histArea, e.name or "?", 10, 4 + (i - 1) * 26, 104, 14, 9, T.txt2)
			K.txt(histArea, e.dest or "?", 10, 18 + (i - 1) * 26, 104, 12, 8, T.txt4)
		end
	end
	refreshHist()
	K.row(right, "Endpoint", ARKHER.STATE.cloud.endpoint == "" and "off" or "on", 190)
	K.row(right, "SSL", "auto", 214)

	-- ===== BARRA INFERIOR =====
	local bar = K.f(root, "Bar", 8, 294, 544, 88, T.bg0)
	K.corner(bar, 4)
	K.txt(bar, "PUBLICAR FACIL", 12, 8, 160, 16, 11, ACCENT, ARKHER.FONTB)
	K.txt(bar, "1 clique -> bundle .arkher.lua -> local ou endpoint do ARKHER CLOUD", 12, 28, 420, 14, 9, T.txt3)
	K.progress(bar, 12, 54, 400, 1, ACCENT)
	K.txt(bar, "ultimo: " .. tostring((ArkherPublish.history()[1] or {}).when or "nunca"), 424, 58, 120, 14, 9, T.txt4, FONT, Enum.TextXAlignment.Right)
end

ARKHER.reg("Publish", "Publish", "System", ICON.share, "Publicacao: bundle + manifest + local/endpoint/nativo (sem Open API)", build)
end

ARKHER.open("Publish")
