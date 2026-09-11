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
-- =============================================================
-- CAMERA STUDIO X — UI sobre o CAMERA X (ACX custom)
-- Shots fisicos (orbit/dolly/crane/follow/flypath Catmull-Rom),
-- SHAKE por trauma^2 (amplitude real de cinematografia), FADE real
-- via ColorCorrectionEffect, CINEMA (cortes em cadeia), editor de
-- flypath com canvas 2D top-view. Mexer = camera real. 🎬
-- =============================================================
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

local function mkSlider(parent, x, y, w, label, min, max, val, fmt, onSet)
	K.txt(parent, label, x, y, 90, 14, 9, T.txt3)
	local valLbl = K.txt(parent, "", x + w - 56, y, 56, 14, 9, C("#D9A5FF"), ARKHER.FONT, Enum.TextXAlignment.Right)
	local track = K.btn(parent, "Trk_" .. label, x, y + 15, w, 10, T.bg4, 5)
	K.stroke(track, T.line, 1)
	local fill = K.f(track, "Fill", 0, 2, 10, 6, C("#D9A5FF"))
	K.corner(fill, 3)
	local function rs()
		local frac = (val - min) / (max - min)
		fill.Size = UDim2.new(0, math.max(4, math.floor(w * frac)), 0, 6)
		valLbl.Text = fmt and fmt(val) or string.format("%.2f", val)
	end
	local function setI(inp)
		local frac = (inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
		frac = math.min(1, math.max(0, frac))
		val = min + (max - min) * frac
		rs()
		if onSet then onSet(val) end
	end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then setI(i) end end)
	track.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then setI(i) end end)
	rs()
	return { get = function() return val end, set = function(v) val = v rs() if onSet then onSet(v) end end }
end

local function build()
	if not ArkherCameraX then ARKHER.note("Kit E nao carregado (CAMERA X ausente)") return end
	local ACX = ArkherCameraX

	local W, H = 700, 480
	local g, root = K.window("CameraStudio", "CAMERA STUDIO X — cinematografia custom (ACX custom)", 260, 150, W, H, { pin = true })

	local bodyH = H - 34 - 40

	-- ============ ESQUERDA: SHOTS ============
	local left = K.f(root, "L", 6, 34, 244, bodyH, T.bg3)
	K.stroke(left, T.line, 1)
	K.txt(left, "SHOTS (acao real na CurrentCamera)", 8, 4, 230, 14, 9, T.txt3)
	local shots = {
		{ nm = "ORBIT", d = "circula o alvo (raio/altura/velocidade)" },
		{ nm = "DOLLY IN", d = "dolly-in com easeInOut_sine" },
		{ nm = "DOLLY OUT", d = "dolly-out com easeOut_quad" },
		{ nm = "CRANE", d = "eleva no arco (dolly + lift)" },
		{ nm = "FLY PATH", d = "catmull-rom por 3 pontos" },
	}
	local function runShot(nm)
		local r = radiusS.get()
		local hgt = heightS.get()
		local dur = durS.get()
		if nm == "ORBIT" then
			ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = r, height = hgt, speed = spdS.get(), duration = 9999 })
		elseif nm == "DOLLY IN" then
			ACX.shot({ type = "dolly", from = Vector3.new(-r, hgt, -r), to = Vector3.new(-2, hgt, -2), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeInOut_sine" })
		elseif nm == "DOLLY OUT" then
			ACX.shot({ type = "dolly", from = Vector3.new(-2, hgt, -2), to = Vector3.new(-r, hgt, -r), lookAt = Vector3.new(0, 3, 0), duration = dur, ease = "easeOut_quad" })
		elseif nm == "CRANE" then
			ACX.shot({ type = "crane", from = Vector3.new(-r, 2, 0), to = Vector3.new(r, 2, 0), lookAt = Vector3.new(0, 3, 0), duration = dur, lift = hgt })
		elseif nm == "FLY PATH" then
			ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = dur })
		end
	end
	for i, sh in ipairs(shots) do
		local y = 20 + (i - 1) * 44
		local b = K.btn(left, sh.nm, 8, y, 228, 26, C("#4A2E6E"), 6)
		K.txt(b, sh.nm, 10, 6, 100, 14, 9.5, T.txt)
		K.txt(left, sh.d, 10, y + 26, 224, 12, 8, T.txt3)
		b.MouseButton1Click:Connect(function() runShot(sh.nm) end)
	end
	local stopB = K.btn(left, "STOP", 8, 20 + 5 * 44, 110, 22, C("#7A2E2E"), 5)
	stopB.MouseButton1Click:Connect(function() ACX.stop() end)
	local cinemaB = K.btn(left, "CINEMA (3 cortes)", 124, 20 + 5 * 44, 112, 22, C("#2E4E7A"), 5)
	cinemaB.MouseButton1Click:Connect(function()
		ACX.cinema({
			{ type = "crane", from = Vector3.new(-20, 2, 0), to = Vector3.new(0, 12, 0), lookAt = Vector3.new(0, 3, 0), duration = durS.get(), lift = 10 },
			{ type = "orbit", center = Vector3.new(0, 3, 0), radius = 12, height = 6, speed = 0.5, duration = 3.5 },
			{ type = "dolly", from = Vector3.new(0, 6, 14), to = Vector3.new(0, 3, 2), lookAt = Vector3.new(0, 3, 0), duration = 2.5 },
		})
	end)

	-- ============ CENTRO: PARAMS + FLY CANVAS + TRAUMA ============
	local center = K.f(root, "C", 258, 34, 250, bodyH, T.bg3)
	K.stroke(center, T.line, 1)
	K.txt(center, "PARAMETROS DO SHOT", 8, 4, 236, 14, 9, T.txt3)
	local radiusS = mkSlider(center, 8, 20, 226, "raio/dist", 4, 40, 14, function(v) return string.format("%.1f m", v) end)
	local heightS = mkSlider(center, 8, 62, 226, "altura", 1, 30, 7, function(v) return string.format("%.1f m", v) end)
	local spdS = mkSlider(center, 8, 104, 226, "vel. orbita (rad/s)", 0.05, 4.0, 0.5, function(v) return string.format("%.2f", v) end)
	local durS = mkSlider(center, 8, 146, 226, "duracao (s)", 0.5, 12.0, 4.0, function(v) return string.format("%.1f s", v) end)
	local faS = mkSlider(center, 8, 188, 226, "fly from (+/−)", -30, 30, -20, function(v) return string.format("%.0f", v) end)
	local fbS = mkSlider(center, 8, 230, 226, "fly to (+/−)", -30, 30, 20, function(v) return string.format("%.0f", v) end)
	K.txt(center, "FLY PATH (top view)", 8, 276, 236, 14, 9, T.txt3)
	local fcv = K.f(center, "FCV", 8, 294, 226, 130, C("#0A0F1A"))
	K.stroke(fcv, T.line, 1)
	-- desenha a curva catmull no canvas (pontos)
	local pathPts = {}
	for i = 0, 24 do
		local dot = K.f(fcv, "p" .. i, 4 + i * 9, 4, 3, 3, C("#D9A5FF"))
		pathPts[i] = dot
	end
	local function repaintPath()
		local a = { X = faS.get(), Y = 0, Z = faS.get() }
		local m = { X = 0, Y = 0, Z = 0 }
		local b = { X = fbS.get(), Y = 0, Z = fbS.get() }
		local n2 = { X = fbS.get() * 2, Y = 0, Z = fbS.get() * 2 }
		local cur = ACX.curve3(a, m, b, n2)
		for i = 0, 24 do
			local u = i / 24
			local px, py, pz = cur(u)
			pathPts[i].Position = UDim2.new(0, math.floor(((px + 30) / 60) * 226), 0, math.floor(((pz + 30) / 60) * 130))
		end
	end
	repaintPath()
	local playFlyB = K.btn(center, "PLAY FLY PATH", 8, 428, 106, 22, C("#4A2E6E"), 5)
	playFlyB.MouseButton1Click:Connect(function()
		ACX.shot({ type = "fly", from = Vector3.new(faS.get(), 8, faS.get()), mid = Vector3.new(0, 16, 0), to = Vector3.new(fbS.get(), 8, fbS.get()), lookAt = Vector3.new(0, 3, 0), duration = durS.get() })
	end)
	local updB = K.btn(center, "redesenhar curva", 122, 428, 108, 22, T.bg4, 5)
	updB.MouseButton1Click:Connect(function() repaintPath() end)

	-- ============ DIREITA: TRAUMA + FADE + STATS ============
	local right = K.f(root, "R", 516, 34, 238, bodyH, T.bg3)
	K.stroke(right, T.line, 1)
	K.txt(right, "TRAUMA (shake puro cinema)", 8, 4, 222, 14, 9, T.txt3)
	K.txt(right, "amplitude = trauma^2 * 0.35 rad", 8, 18, 222, 12, 8, T.txt3)
	local traumaS = mkSlider(right, 8, 34, 222, "trauma alvo", 0, 1, 0.5, function(v) return string.format("%.0f%%", v * 100) end)
	local bumpB = K.btn(right, "BUMP (+trauma)", 8, 78, 106, 22, C("#7A5A2E"), 5)
	bumpB.MouseButton1Click:Connect(function() ACX.addTrauma(traumaS.get()) end)
	local decBtn = K.btn(right, "4s tremendo", 122, 78, 108, 22, T.bg4, 5)
	decBtn.MouseButton1Click:Connect(function()
		ACX.addTrauma(1)
		ACX.shot({ type = "orbit", center = Vector3.new(0, 3, 0), radius = 16, height = 6, speed = 0.4, duration = 9999 })
	end)
	K.txt(right, "FADE REAL (ColorCorrection)", 8, 112, 222, 14, 9, T.txt3)
	local fadeOutB = K.btn(right, "FADE OUT", 8, 128, 106, 22, C("#3A3A42"), 5)
	local fadeInB = K.btn(right, "FADE IN", 122, 128, 108, 22, C("#5A4A6E"), 5)
	fadeOutB.MouseButton1Click:Connect(function() ACX.fade(-1, 0.8) end)
	fadeInB.MouseButton1Click:Connect(function() ACX.fade(0, 0.8) end)
	K.txt(right, "CAMERA AO VIVO (pump)", 8, 162, 222, 14, 9, T.txt3)
	local posTxt = K.txt(right, "pos: —", 8, 178, 222, 14, 9, T.txt2)
	local modeTxt = K.txt(right, "modo: —", 8, 192, 222, 14, 9, T.txt2)
	local traumaTxt = K.txt(right, "trauma: —", 8, 206, 222, 14, 9, T.txt2)
	local traumaBar = K.f(right, "TB", 8, 226, 222, 8, C("#101827"))
	K.corner(traumaBar, 4)
	local traumaFill = K.f(traumaBar, "F", 0, 2, 4, 4, C("#7A2E2E"))
	K.corner(traumaFill, 2)
	K.txt(right, "CINEMATOGRAFIA", 8, 246, 222, 14, 9, T.txt3)
	K.txt(right, "Regra de terços: lookAt deslocado ", 8, 262, 222, 12, 8, T.txt3)
	K.txt(right, "automaticamente p/ (1/3, 2/3) do frame", 8, 274, 222, 12, 8, T.txt3)
	K.txt(right, "Collision: raycast puxa a camera pra", 8, 290, 222, 12, 8, T.txt3)
	K.txt(right, "dentro se parede atrapalhar (REAL)", 8, 302, 222, 12, 8, T.txt3)

	-- ============ STATUS ============
	local status = K.f(root, "St", 0, H - 36, W, 36, T.bg3)
	local sTxt = K.txt(status, "", 10, 11, W - 20, 14, 9.5, T.txt3)
	ARKHER.out("INFO", "Camera Studio X atasao CAMERA X (shots reais, trauma, fades reais, cinema)")

	-- ============ HEARTBEAT pump ============
	if not ArkherCameraX.UI_CONN then
		local okRS, RS = pcall(function() return game:GetService("RunService") end)
		if okRS and RS and RS.Heartbeat then
			pcall(function()
				ArkherCameraX.UI_CONN = RS.Heartbeat:Connect(function(dt)
					local okin = pcall(function()
						ACX.pump(dt or 1 / 60)
						ACX.pumpCinema()
						local c = workspace.CurrentCamera
						if c and c.CFrame and c.CFrame.Position then
							local p = c.CFrame.Position
							posTxt.Text = string.format("pos: %.1f  %.1f  %.1f", p.X, p.Y, p.Z)
						end
						modeTxt.Text = "modo: " .. tostring(ACX.S.mode) .. (ACX.S.shot and (" (" .. ACX.S.shot.type .. ")") or "")
						traumaTxt.Text = string.format("trauma: %.2f → shake %.3f rad", ACX.S.trauma, ACX.S.trauma ^ 2 * 0.35)
						traumaFill.Size = UDim2.new(0, math.floor(ACX.S.trauma * 222), 0, 4)
					end)
					if not okin then ArkherCameraX.UI_CONN:Disconnect() ArkherCameraX.UI_CONN = nil end
				end)
			end)
		end
	end
end

ARKHER.reg("Camera", "Camera", "Scene", ICON.camera, "Camera custom: shots fisicos, trauma shake, fades reais, cinema (CAMERA X)", build)
end

ARKHER.open("Camera")
