--[[ ARKHER V4 — LocalScript. Requer os kits (ReplicatedStorage.ArkherV3.ArkherKit_B/C/D/E). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	for _, kn in ipairs({ "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E" }) do
		local m = folder and folder:FindFirstChild(kn)
		if not m then m = script:FindFirstChild(kn) end
		if not m then m = script.Parent and script.Parent:FindFirstChild(kn) end
		if not m then
			error("[ARKHER] " .. kn .. " nao encontrado: rode os installers A+B+C+D+E primeiro.")
		end
		require(m)
	end
end
_arkherKit()
ARKHER.boot()

do
--[[ ARKHER — UI: WATER STUDIO (motor AWX custom, nao usa agua do Roblox) ]]
-- Estudio de agua completissimo: 8 tipos com fisica real (densidade/salinidade/
-- temperatura/viscosidade), 6 presets de mar, DESIGNER DE ONDAS DE GERSTNER
-- (amp/len/dir/speed/steep por onda), mare lunar, correntes (Stokes drift),
-- preview vivo do perfil de onda, espuma por energia de crista, causticas,
-- FLUTUABILIDADE arquimediana real na selecao, ambiente subaquatico, splash.
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C
local ACCENT = C("#58C6FF")
local WX, DM = ArkherWaterX, ArkherDM

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, ACCENT, ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, ACCENT)
	K.corner(fill, 3)
	local function renderSlider()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setFromInput(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		renderSlider()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then setFromInput(inp) end
	end)
	track.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement then setFromInput(inp) end
	end)
	renderSlider()
	return { get = function() return val end, set = function(v) val = v renderSlider() if onSet then onSet(v) end end }
end

local function build()
	local g, root, head = K.window("ArkherWater", "WATER STUDIO — motor AWX (custom)", 30, 320, 700, 470, { pin = true })
	K.f(head, "Acc", 0, 24, 700, 2, ACCENT)

	-- ================= CORPO D'AGUA VIVO =================
	local body = WX.preset("porto", { kind = "oceano", level = 0, size = { x = 480, z = 320 } })
	local simT = 0
	local playing = false
	local status = nil
	local statLbl = nil
	local profTiles = {}
	local foamTiles = {}
	local waveRows = {}
	local selWave = 1
	local repaintProfile = nil
	local repaintWaves = nil
	local refreshWaveSliders = nil
	local timeS = nil

	-- ================= ESQUERDA: TIPOS + PRESETS =================
	local left = K.f(root, "Left", 8, 34, 150, 252, T.bg4)
	K.corner(left, 4)
	K.txt(left, "TIPO DE AGUA", 10, 6, 120, 14, 10, T.txt3, ARKHER.FONTB)
	local kinds = { "oceano", "mar_calmo", "lago", "rio", "cachoeira", "pantano", "glacial", "terma" }
	for i, kd in ipairs(kinds) do
		local w = WX.WATERS[kd]
		local b = K.btn(left, "K" .. i, 8, 24 + (i - 1) * 27, 134, 23, T.bg2, 4)
		K.f(b, "c", 4, 5, 13, 13, Color3.fromRGB(w.cor[1], w.cor[2], w.cor[3]), 2)
		K.txt(b, w.nm, 22, 4, 102, 14, 10, T.txt)
		K.txt(b, "dens " .. w.dens, 22, 15, 102, 10, 7, T.txt4)
		K.hover(b, T.bg2, T.hover)
		local id = kd
		b.MouseButton1Click:Connect(function()
			local lvl = body.level
			body = WX.create(id, { level = lvl, size = body.size, waves = body.waves, tideAmp = body.tideAmp })
			repaintProfile()
			if status then status.Text = "agua: " .. w.nm .. " | sal " .. w.sal .. "g/L | temp " .. w.temp .. "C | visc " .. w.visc end
		end)
	end
	K.txt(left, "PRESETS DE MAR", 10, 242, 130, 14, 10, T.txt3, ARKHER.FONTB)
	local presets = { "calmaria", "porto", "ressaca", "tempestade", "corredeira", "espelho" }
	for i, pr in ipairs(presets) do
		local b = K.btn(left, "P" .. i, 8 + ((i - 1) % 2) * 68, 260 + math.floor((i - 1) / 2) * 24, 62, 20, T.bg2, 4)
		K.txtS(b, pr, 8, T.txt2)
		K.hover(b, T.bg2, T.hover)
		local id = pr
		b.MouseButton1Click:Connect(function()
			local kind = body.kind
			body = WX.preset(id, { kind = kind, level = body.level, size = body.size })
			repaintWaves()
			repaintProfile()
			if status then status.Text = "preset '" .. id .. "': " .. #body.waves .. " ondas de Gerstner" end
		end)
	end

	-- ================= CENTRO: PREVIEW VIVO (perfil de onda real) =================
	local prof = K.f(root, "Prof", 168, 34, 340, 252, T.bg0)
	K.corner(prof, 4)
	K.stroke(prof, T.line, 1)
	local COLS, PH = 34, 226
	local function colFor(h, crest)
		if crest > 0.45 then return Color3.fromRGB(190, 226, 246) end
		local f = math.min(1, math.max(0, (h + 6) / 12))
		local c = body.props.cor
		return Color3.fromRGB(
			math.floor(c[1] + f * 40), math.floor(c[2] + f * 44), math.floor(c[3] + f * 30))
	end
	for i = 1, COLS do
		local col = K.f(prof, "P" .. i, (i - 1) * 10 + 2, 10, 9, 10, C("#16456B"), 0)
		profTiles[i] = col
		local fo = K.f(prof, "F" .. i, (i - 1) * 10 + 2, 10, 9, 3, C("#E8F6FF"), 0)
		fo.Visible = false
		foamTiles[i] = fo
	end
	repaintProfile = function()
		local span = (body.size and body.size.x) or 480
		local maxA = 1
		for _, w in ipairs(body.waves) do maxA = math.max(maxA, w.amp) end
		for i = 1, COLS do
			local x = (i - 0.5) / COLS * span - span / 2
			local h = body:heightAt(x, 0, simT) - body.level
			local crest = body:crestAt(x, 0, simT)
			local px = math.floor(math.max(4, math.min(PH - 20, 60 + h * (22 / math.max(maxA, 0.5)))))
			local col = profTiles[i]
			col.Size = UDim2.new(0, 9, 0, px)
			col.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 10 + PH - px)
			col.BackgroundColor3 = colFor(h, crest)
			local fo = foamTiles[i]
			fo.Visible = crest * body.foaminess > 0.32
			fo.Position = UDim2.new(0, (i - 1) * 10 + 2, 0, 8 + PH - px)
		end
	end
	-- tempo + play
	timeS = mkSlider(prof, 10, PH + 8, 200, "Tempo (s)", 0, 120, 0, function(v) return string.format("%.1f", v) end, function(v)
		simT = v
		repaintProfile()
	end)
	local play = K.btn(prof, "Play", 250, PH + 18, 80, 22, ACCENT, 5)
	K.txtS(play, "ANIMAR", 9, C("#06222E"))
	K.hover(play, ACCENT, C("#9BE0FF"))
	local playConn = nil
	play.MouseButton1Click:Connect(function()
		playing = not playing
		local lbl2 = play:FindFirstChildOfClass("TextLabel")
		if lbl2 then lbl2.Text = playing and "PARAR" or "ANIMAR" end
		if playing and not playConn then
			local ok2, RS = pcall(function() return game:GetService("RunService") end)
			if ok2 and RS and RS.Heartbeat then
				local acc = 0
				playConn = RS.Heartbeat:Connect(function(dt)
					if not playing then return end
					acc = acc + dt
					local budget = ArkherDO15 and ArkherDO15.refreshBudget("animations") or 0
					if acc >= math.max(0.03, 0.05) then
						simT = simT + acc
						acc = 0
						timeS.set(simT % 120)
						repaintProfile()
						if body.tiles then WX.animate(body, simT) end
						WX.step(body, dt, simT)
					end
				end)
			end
		end
	end)

	-- ================= DIREITA: DESIGNER DE ONDAS + PROPRIEDADES =================
	local right = K.f(root, "Right", 518, 34, 174, 252, T.bg4)
	K.corner(right, 4)
	K.txt(right, "GERSTNER (ondas)", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	repaintWaves = function()
		for i = 1, 6 do
			local row = right:FindFirstChild("WR" .. i)
			if row then row:Destroy() end
		end
		waveRows = {}
		for i = 1, math.min(#body.waves, 6) do
			local w = body.waves[i]
			local row = K.btn(right, "WR" .. i, 8, 24 + (i - 1) * 26, 158, 22, T.bg2, 4)
			K.txt(row, "λ" .. string.format("%.0f", w.len) .. " a" .. string.format("%.2f", w.amp), 8, 3, 86, 14, 9, (i == selWave) and ACCENT or T.txt)
			K.txt(row, "→" .. string.format("%.0f", w.dir) .. "°", 100, 3, 50, 14, 9, T.txt4)
			K.stroke(row, i == selWave and ACCENT or T.line2, i == selWave and 1.5 or 1)
			local idx = i
			row.MouseButton1Click:Connect(function()
				selWave = idx
				repaintWaves()
				refreshWaveSliders()
			end)
			waveRows[i] = row
		end
	end
	repaintWaves()
	local swAmp, swLen, swDir
	local function curW() return body.waves[selWave] end
	refreshWaveSliders = function()
		local w = curW()
		if not w or not swAmp then return end
		swAmp.set(w.amp); swLen.set(w.len); swDir.set(w.dir)
	end
	swAmp = mkSlider(right, 10, 184, 154, "Amplitude", 0.03, 3, 0.4, nil, function(v) if curW() then curW().amp = v end repaintProfile() repaintWaves() end)
	swLen = mkSlider(right, 10, 216, 154, "Comprimento λ", 4, 120, 34, function(v) return string.format("%.0f", v) end, function(v) if curW() then curW().len = v end repaintProfile() repaintWaves() end)
	swDir = mkSlider(right, 10, 248, 154, "Direcao", 0, 360, 0, function(v) return string.format("%.0f", v) .. "°" end, function(v) if curW() then curW().dir = v end repaintProfile() repaintWaves() end)

	local props = K.f(root, "Props", 518, 292, 174, 130, T.bg4)
	K.corner(props, 4)
	K.txt(props, "MARE / NIVEL", 10, 6, 150, 14, 10, T.txt3, ARKHER.FONTB)
	mkSlider(props, 10, 24, 154, "Nivel", -20, 20, body.level, function(v) return string.format("%.1f", v) end, function(v) body.level = v repaintProfile() end)
	mkSlider(props, 10, 62, 154, "Mare amp", 0, 4, body.tideAmp, nil, function(v) body.tideAmp = v repaintProfile() end)
	mkSlider(props, 10, 100, 154, "Espuma", 0, 1, body.foaminess, nil, function(v) body.foaminess = v repaintProfile() end)

	-- ================= BASE: ACOES REAIS =================
	local bar = K.f(root, "Bar", 8, 296, 500, 130, T.bg0)
	K.corner(bar, 4)
	status = K.txt(bar, "pronto — escolha um preset e materialize o mar", 10, 6, 480, 16, 9, T.txt3)
	statLbl = K.txt(bar, "", 10, 24, 480, 14, 8, T.txt4)
	local function refreshStats()
		local s = body:stats()
		statLbl.Text = "ondas " .. s.waves .. " | dens " .. s.density .. " | tiles " .. s.tiles .. " | flutuadores " .. s.floaters .. " | splashes " .. s.splashes
	end
	refreshStats()

	local mk = K.btn(bar, "Mk", 10, 46, 110, 26, ACCENT, 5)
	K.txtS(mk, "Materializar mar", 9, C("#06222E"))
	K.hover(mk, ACCENT, C("#9BE0FF"))
	mk.MouseButton1Click:Connect(function()
		local model, n = WX.materialize(body, { maxSpan = 480 })
		status.Text = "mar materializado: " .. n .. " tiles animados (LOD D-O15 " .. (ArkherDO15 and ArkherDO15.levelName() or "?") .. ")"
		refreshStats()
	end)
	local cau = K.btn(bar, "Cau", 128, 46, 100, 26, T.bg2, 5)
	K.txtS(cau, "+ Causticas", 9, T.txt)
	K.hover(cau, T.bg2, T.hover)
	cau.MouseButton1Click:Connect(function()
		local n = WX.caustics(body, body.level - 10)
		status.Text = "causticas: " .. n .. " brilhos no fundo (shimmer neon)"
		refreshStats()
	end)
	local flt = K.btn(bar, "Flt", 236, 46, 120, 26, T.bg2, 5)
	K.txtS(flt, "Flutuar selecao", 9, T.txt)
	K.hover(flt, T.bg2, T.hover)
	flt.MouseButton1Click:Connect(function()
		local ok2, sel = pcall(function() return game:GetService("Selection"):Get() end)
		local n = 0
		if ok2 and sel then
			for _, inst in ipairs(sel) do
				if inst:IsA("BasePart") then WX.float(body, inst, {}) n = n + 1 end
			end
		end
		if n == 0 then
			-- cria uma boia demo de verdade
			local p = Instance.new("Part")
			p.Name = "AWX_Buoy"
			p.Size = Vector3.new(5, 2.4, 5)
			p.Position = Vector3.new(0, body.level + 1, 0)
			p.Color = Color3.fromRGB(240, 180, 60)
			p.Parent = workspace
			WX.float(body, p, { density = 420 })
			n = 1
			status.Text = "boia criada + flutuabilidade arquimediana ativa (de play)"
		else
			status.Text = "flutuabilidade em " .. n .. " parts da selecao (Arquimedes)"
		end
		refreshStats()
	end)
	local und = K.btn(bar, "Und", 364, 46, 126, 26, T.bg2, 5)
	K.txtS(und, "Submerso: ON/OFF", 9, T.txt)
	local undOn = false
	K.hover(und, T.bg2, T.hover)
	und.MouseButton1Click:Connect(function()
		undOn = not undOn
		WX.applyUnderwater(body, undOn)
		status.Text = undOn and "ambiente subaquatico: neblina croma + absorcao" or "ambiente restaurado"
	end)
	local spl = K.btn(bar, "Spl", 10, 78, 110, 26, T.bg2, 5)
	K.txtS(spl, "Splash teste", 9, T.txt)
	K.hover(spl, T.bg2, T.hover)
	spl.MouseButton1Click:Connect(function()
		if not body.tiles then WX.materialize(body, { maxSpan = 240 }) end
		WX.splash(body, 0, body:heightAt(0, 0, simT), 0, 2)
		status.Text = "splash emitido (particulas + gravidade real)"
		refreshStats()
	end)
	local ser = K.btn(bar, "Ser", 128, 78, 100, 26, T.bg2, 5)
	K.txtS(ser, "Roundtrip JSON", 9, T.txt)
	K.hover(ser, T.bg2, T.hover)
	ser.MouseButton1Click:Connect(function()
		local str = body:serialize()
		local b2, err = WX.deserialize(str)
		if b2 then status.Text = "roundtrip OK: " .. #str .. " chars, " .. #b2.waves .. " ondas restauradas"
		else status.Text = "roundtrip falhou: " .. tostring(err) end
	end)
	local ai2 = K.btn(bar, "AI", 236, 78, 120, 26, T.purple, 5)
	K.txtS(ai2, "Singularity: mar", 9, C("#FFF"))
	K.hover(ai2, T.purple, C("#A97AFF"))
	ai2.MouseButton1Click:Connect(function()
		local ok2, rep = pcall(function() return ARKHER_SINGULARITY.run("crie um oceano realista com ondas e espuma") end)
		if ok2 and rep then K.notify("Singularity", "oceano gerado (" .. #rep.lines .. " etapas)", "ok") end
	end)
	local terr = K.btn(bar, "Terr", 364, 78, 126, 26, C("#4E8FE0"), 5)
	K.txtS(terr, "< TERRAIN STUDIO", 9, C("#FFF"))
	K.hover(terr, C("#4E8FE0"), C("#6FA8F0"))
	terr.MouseButton1Click:Connect(function() ARKHER.open("Terrain") end)

	repaintProfile()
end

ARKHER.reg("Water", "Water Studio", "Editor", ICON.plate, "Agua custom (AWX): Gerstner, mare, correntes, flutuabilidade, causticas, submerso", build)
end

ARKHER.open("Water")
