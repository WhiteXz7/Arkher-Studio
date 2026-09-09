--[[ ARKHER V2 — GESTÃO: Projects, Build, Packages, Plugins, VC, Collab, Localization, Data, Toolbox, Undo, Layouts, Notifs ]]
ARKHER_REG = ARKHER_REG or {}
local T, K, ICON, C = ARKHER.T, ARKHER.K, ARKHER.ICON, ARKHER.C

-- ============ PROJECT SETTINGS ============
ARKHER_REG.ProjectSettings = function()
	local g, root = K.window("ArkherProjectSettings", "Project Settings", 240, 80, 560, 400)
	K.txt(root, "Name", 12, 40, 80, 20, 11, T.txt3)
	K.input(root, 100, 38, 200, 24, "SunEmblemBlock")
	K.txt(root, "Place ID", 12, 70, 80, 20, 11, T.txt3)
	K.input(root, 100, 68, 200, 24, "0x4F2A-ARKHER")
	K.txt(root, "Genre", 12, 100, 80, 20, 11, T.txt3)
	local gn = K.btn(root, "G", 100, 98, 200, 24, T.bg4, 4)
	K.txtS(gn, "Simulation / MMO", 11, T.txt2)
	local y = 136
	for _, tg in ipairs({ "Allow Copying", "Server Storage API", "Third-party APIs", "Studio Access to APIs", "Permissions: Arkher Cloud" }) do
		K.toggle(root, 12, y, true, tg)
		y = y + 24
	end
	local icon = K.f(root, "IC", 340, 40, 96, 96, T.bg4)
	K.corner(icon, 8)
	K.stroke(icon, T.line2, 1)
	ICON.emblem(K.f(icon, "E", 24, 24, 48, 48), 48)
	K.txt(root, "Icon / Thumbnail", 340, 142, 120, 16, 10, T.txt4)
	return g
end

-- ============ BUILD SETTINGS / PUBLISH ============
ARKHER_REG.BuildSettings = function()
	local g, root = K.window("ArkherBuildSettings", "Build Settings / Publish", 260, 90, 600, 400)
	local plats = { "Web", "Android", "Desktop", "Standalone", "Package" }
	local x = 8
	for i, p in ipairs(plats) do
		local card = K.btn(root, "PL_" .. p, x, 36, 104, 64, i == 1 and T.sel or T.bg4, 6)
		K.txtS(card, p, 12, i == 1 and T.txt or T.txt2, ARKHER.FONTB)
		K.hover(card, card.BackgroundColor3, T.hover)
		x = x + 110
	end
	local y = 116
	for _, s in ipairs({ { "Compression", 0.7 }, { "Strip unused", 0.9 }, { "Texture budget", 0.5 } }) do
		K.sliderRow(root, s[1], s[2], y)
		y = y + 22
	end
	local bar = K.f(root, "Bar", 8, y + 8, 584, 8, T.bg4)
	K.corner(bar, 4)
	local fill = K.f(bar, "F", 0, 0, 0, 8, T.green)
	K.corner(fill, 4)
	local st = K.txt(root, "idle", 8, y + 20, 584, 16, 10, T.txt3, ARKHER.MONO)
	local build = K.btn(root, "BD", 8, y + 42, 140, 28, T.sel, 5)
	K.txtS(build, "BUILD + SIGN", 12, T.txt, ARKHER.FONTB)
	build.MouseButton1Click:Connect(function()
		coroutine.wrap(function()
			for w = 0, 584, 8 do
				fill.Size = UDim2.new(0, w, 0, 8)
				st.Text = "building... " .. math.floor(w / 584 * 100) .. "% (integrity: sha256)"
				wait(0.03)
			end
			st.Text = "build ok | size 42.7MB | signature ARKHER-ED25519 verified"
			K.notify("PUBLISH", "Build assinado com integridade verificada", "SUCCESS")
		end)()
	end)
	K.row(root, "Dependencies", "UES-Core, D-O15, Singularity", y + 44)
	return g
end

-- ============ PACKAGE MANAGER ============
ARKHER_REG.PackageManager = function()
	local g, root = K.window("ArkherPackageManager", "Package Manager", 280, 100, 560, 380)
	K.search(root, 8, 32, 544, 24, "Search packages...")
	local pkgs = {
		{ "ues-core", "12.4.0", "installed" }, { "d-o15", "3.1.2", "installed" },
		{ "singularity-bridge", "1.9.0", "update" }, { "arkher-terrain", "2.0.1", "installed" },
		{ "arkher-audio-hrtf", "0.8.3", "install" }, { "nmn-behavior", "4.2.0", "update" },
		{ "collab-rt", "1.2.7", "installed" }, { "vfx-hdr", "2.2.0", "install" },
	}
	local y = 64
	for _, p in ipairs(pkgs) do
		local row = K.f(root, "PK_" .. p[1], 8, y, 544, 24, T.bg4)
		K.corner(row, 4)
		ICON.toolbox(K.f(row, "I", 6, 4, 16, 16), 16)
		K.txt(row, p[1], 28, 0, 200, 24, 11, T.txt, ARKHER.MONO)
		K.txt(row, "v" .. p[2], 240, 0, 80, 24, 10, T.txt3, ARKHER.MONO)
		local act = p[3]
		local b = K.btn(row, "A", 460, 2, 78, 20, act == "installed" and T.bg2 or T.sel, 4)
		K.txtS(b, string.upper(act), 9, act == "installed" and T.txt3 or T.txt, ARKHER.FONTB)
		if act ~= "installed" then
			b.MouseButton1Click:Connect(function()
				K.txt(row, "", 0, 0, 0, 0, 1)
				K.notify("PACKAGES", p[1] .. " -> " .. (act == "update" and "atualizado" or "instalado"), "SUCCESS")
				b.BackgroundColor3 = T.bg2
			end)
		end
		y = y + 27
	end
	return g
end

-- ============ PLUGIN MANAGER / TOOLBAR ============
ARKHER_REG.PluginManager = function()
	local g, root = K.window("ArkherPluginManager", "Plugin Toolbar / Manager", 300, 80, 520, 380)
	local plugs = {
		{ "Arkher Terrain Brush", true }, { "RoStrap Compat", false }, { "Animation Capture", true },
		{ "Lightmap Baker", false }, { "Mesh Optimizer", true }, { "Git Sync", true },
	}
	local y = 38
	for _, p in ipairs(plugs) do
		local row = K.f(root, "PL", 8, y, 504, 26, T.bg4)
		K.corner(row, 4)
		ICON.plugin(K.f(row, "I", 6, 5, 16, 16), 16)
		K.txt(row, p[1], 30, 0, 260, 26, 11, T.txt2)
		K.toggle(row, 380, 4, p[2], nil)
		local gear = K.btn(row, "G", 470, 5, 16, 16, T.bg4, 3)
		ICON.settings(gear, 14, 1, 1)
		K.hover(gear, T.bg4, T.hover)
		y = y + 29
	end
	local hot = K.btn(root, "HR", 8, y + 6, 120, 24, T.hover, 4)
	K.txtS(hot, "HOT RELOAD", 10, T.txt2, ARKHER.FONTB)
	hot.MouseButton1Click:Connect(function() K.notify("PLUGINS", "Hot reload executado sem perda de estado", "SUCCESS") end)
	return g
end

-- ============ VERSION CONTROL ============
ARKHER_REG.VersionControl = function()
	local g, root = K.window("ArkherVersionControl", "Version Control", 240, 70, 620, 420)
	local br = K.btn(root, "BR", 8, 32, 160, 24, T.bg4, 4)
	ICON.share(K.f(br, "I", 6, 4, 16, 16), 16)
	K.txt(br, "arena/v2-uis", 28, 0, 110, 24, 11, T.txt)
	ICON.chevD(K.f(br, "C", 140, 8, 8, 8), 8)
	local commits = {
		{ "09b5140", "Add Arkher package via Git LFS", "main" },
		{ "a41f2c9", "V2 ribbon replica (frame icons)", "arena" },
		{ "b77e01d", "Hierarchy + Properties dock", "arena" },
		{ "c03aa55", "D-O15 pressure wiring", "arena" },
	}
	local y = 66
	for _, c in ipairs(commits) do
		local row = K.f(root, "CM", 8, y, 380, 24, T.bg4)
		K.corner(row, 4)
		K.txt(row, c[1], 8, 0, 64, 24, 10, T.orange, ARKHER.MONO)
		K.txt(row, c[2], 78, 0, 240, 24, 10, T.txt2)
		K.txt(row, c[3], 330, 0, 50, 24, 9, T.accent2, ARKHER.MONO)
		y = y + 27
	end
	local changes = { "M studio-v2/src/prelude.luau", "M studio-v2/src/body_main.luau", "A studio-v2/src/ed_c.luau", "A studio-v2/src/ed_d.luau" }
	local ch = K.f(root, "CH", 400, 32, 212, 240, T.bg4)
	K.corner(ch, 4)
	K.txt(ch, "CHANGES", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	local cy = 22
	for _, c in ipairs(changes) do
		K.txt(ch, c, 8, cy, 200, 16, 10, c:sub(1, 1) == "A" and T.green or T.yellow, ARKHER.MONO)
		cy = cy + 17
	end
	local bx = 400
	for _, bn in ipairs({ "COMMIT", "PUSH", "PULL" }) do
		local b = K.btn(root, "VC_" .. bn, bx, 284, 64, 24, bn == "COMMIT" and T.sel or T.hover, 4)
		K.txtS(b, bn, 9, T.txt, ARKHER.FONTB)
		b.MouseButton1Click:Connect(function() K.notify("VC", bn .. " concluído (branch arena)", "SUCCESS") end)
		bx = bx + 70
	end
	return g
end

-- ============ COLLABORATION ============
ARKHER_REG.Collaboration = function()
	local g, root = K.window("ArkherCollaboration", "Collaboration Settings", 260, 90, 560, 400)
	local users = { { "WhiteXz7", T.purple, "owner" }, { "Arkher-Agent", T.accent2, "edit" }, { "Guest_42", T.yellow, "view" } }
	local y = 40
	for _, u in ipairs(users) do
		local av = K.f(root, "AV", 10, y, 20, 20, u[2])
		K.corner(av, 10)
		K.txt(root, u[1], 38, y + 2, 140, 18, 11, T.txt)
		local cur = K.f(root, "CUR", 190, y + 4, 8, 12, u[2])
		cur.Rotation = -15
		local perm = K.btn(root, "PM", 240, y, 90, 20, T.bg4, 4)
		K.txtS(perm, u[3], 10, T.txt2)
		K.hover(perm, T.bg4, T.hover)
		y = y + 28
	end
	local inv = K.input(root, 10, y + 8, 240, 24, "invite by email...")
	local sb = K.btn(root, "INV", 256, y + 8, 74, 24, T.sel, 4)
	K.txtS(sb, "INVITE", 10, T.txt, ARKHER.FONTB)
	sb.MouseButton1Click:Connect(function() K.notify("COLLAB", "Convite capability-scoped enviado", "SUCCESS") end)
	local feed = K.f(root, "FD", 340, 36, 212, 320, T.bg4)
	K.corner(feed, 4)
	K.txt(feed, "CHANGES FEED", 8, 4, 140, 14, 9, T.txt4, ARKHER.FONTB)
	local fl = { "WhiteXz7 moved Baseplate", "Arkher-Agent edited Ribbon", "Guest_42 viewing Viewport", "WhiteXz7 saved snapshot", "Arkher-Agent added icons" }
	local fy = 22
	for _, f in ipairs(fl) do
		K.txt(feed, f, 8, fy, 196, 14, 9, T.txt3)
		fy = fy + 16
	end
	return g
end

-- ============ LOCALIZATION ============
ARKHER_REG.Localization = function()
	local g, root = K.window("ArkherLocalization", "Localization", 280, 100, 560, 380)
	local langs = { { "pt-BR", 1.0 }, { "en-US", 0.92 }, { "es-419", 0.74 }, { "ja-JP", 0.41 }, { "de-DE", 0.38 } }
	local y = 40
	for _, l in ipairs(langs) do
		K.txt(root, l[1], 12, y, 60, 18, 11, T.txt, ARKHER.MONO)
		local track = K.f(root, "TR", 80, y + 5, 300, 8, T.bg4)
		K.corner(track, 4)
		local f = K.f(track, "F", 0, 0, math.floor(300 * l[2]), 8, l[2] == 1 and T.green or T.accent2)
		K.corner(f, 4)
		K.txt(root, math.floor(l[2] * 100) .. "%", 390, y, 50, 18, 10, T.txt3)
		y = y + 24
	end
	local tr = K.btn(root, "TRB", 12, y + 10, 180, 26, T.sel, 5)
	K.txtS(tr, "TRANSLATE MISSING", 10, T.txt, ARKHER.FONTB)
	tr.MouseButton1Click:Connect(function() K.notify("LOCALIZATION", "Singularity traduziu 214 strings pendentes", "SUCCESS") end)
	local prev = K.f(root, "PV", 12, y + 46, 536, 90, T.bg4)
	K.corner(prev, 4)
	K.txt(prev, "Preview: \"Como posso ajudar você a criar?\"", 12, 10, 500, 18, 12, T.txt)
	K.txt(prev, "Locale ativo: pt-BR (fallback en-US)", 12, 34, 500, 16, 10, T.txt4)
	return g
end

-- ============ DATA MANAGER ============
ARKHER_REG.DataManager = function()
	local g, root = K.window("ArkherDataManager", "Data / Storage Manager", 240, 80, 640, 420)
	local stores = { "player_progress", "world_state", "economy_ledger", "npc_memory" }
	local x = 8
	for i, s in ipairs(stores) do
		local b = K.btn(root, "ST_" .. s, x, 32, 30 + #s * 6, 22, i == 1 and T.sel or T.bg4, 4)
		K.txtS(b, s, 10, i == 1 and T.txt or T.txt2, ARKHER.MONO)
		K.hover(b, b.BackgroundColor3, T.hover)
		x = x + 36 + #s * 6
	end
	local entries = K.f(root, "EN", 8, 62, 400, 240, T.bg4)
	K.corner(entries, 4)
	K.txt(entries, "KEY", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	K.txt(entries, "SIZE", 240, 4, 60, 14, 9, T.txt4, ARKHER.FONTB)
	K.txt(entries, "INTEGRITY", 300, 4, 90, 14, 9, T.txt4, ARKHER.FONTB)
	local rows = { { "uid_0x4F2A", "2.1KB", "sha ok" }, { "checkpoint_118", "48KB", "sha ok" }, { "snapshot_sun", "12KB", "sha ok" }, { "ledger_q3", "96KB", "rebuild" } }
	local ey = 22
	for _, r in ipairs(rows) do
		K.txt(entries, r[1], 8, ey, 200, 16, 10, T.txt2, ARKHER.MONO)
		K.txt(entries, r[2], 240, ey, 50, 16, 10, T.txt3, ARKHER.MONO)
		K.txt(entries, r[3], 300, ey, 90, 16, 10, r[3] == "sha ok" and T.green or T.orange, ARKHER.MONO)
		ey = ey + 18
	end
	local snaps = K.f(root, "SN", 416, 62, 216, 240, T.bg4)
	K.corner(snaps, 4)
	K.txt(snaps, "CHECKPOINTS", 8, 4, 120, 14, 9, T.txt4, ARKHER.FONTB)
	local sy = 22
	for i = 1, 6 do
		local row = K.btn(snaps, "S" .. i, 2, sy, 212, 20, T.bg4, 3)
		K.txt(row, "ckpt #" .. (120 - i), 8, 0, 100, 20, 10, T.txt2, ARKHER.MONO)
		local rs = K.btn(row, "R", 150, 2, 60, 16, T.hover, 3)
		K.txtS(rs, "RESTORE", 8, T.txt2)
		rs.MouseButton1Click:Connect(function() K.notify("DATA", "Checkpoint restaurado (validação ok)", "SUCCESS") end)
		sy = sy + 22
	end
	local bb = K.btn(root, "BK", 8, 310, 140, 26, T.sel, 5)
	K.txtS(bb, "BACKUP NOW", 10, T.txt, ARKHER.FONTB)
	bb.MouseButton1Click:Connect(function() K.notify("DATA", "Backup com checksum criado", "SUCCESS") end)
	return g
end

-- ============ TOOLBOX ============
ARKHER_REG.Toolbox = function()
	local g, root = K.window("ArkherToolbox", "Toolbox — Arkher Assets", 220, 70, 660, 440)
	local cats = { "3D", "Materials", "Textures", "Audio", "Animation", "Particles", "Shaders", "Images", "Video", "Data" }
	local cx = 8
	for i, c in ipairs(cats) do
		local b = K.btn(root, "TC_" .. c, cx, 32, 16 + #c * 6, 20, i == 1 and T.sel or T.bg4, 10)
		K.txtS(b, c, 9, i == 1 and T.txt or T.txt2)
		K.hover(b, b.BackgroundColor3, T.hover)
		cx = cx + 22 + #c * 6
	end
	K.search(root, 8, 58, 644, 24, "Semantic search: ex. \"medieval castle gate\"")
	local assets = {
		{ "Castle Gate", ICON.toolbox, C("#8F5F2C") }, { "River Spline", ICON.chat, C("#2A6BC0") },
		{ "Pine Forest", ICON.terrain, C("#3ECF7A") }, { "Torch VFX", ICON.gem, C("#F07E2E") },
		{ "Lute Loop", ICON.bulb, C("#F6C65B") }, { "Knight NPC", ICON.playersI, C("#8A6BFF") },
		{ "Stone Wall", ICON.boxG, C("#9AA7C0") }, { "Market Stall", ICON.folder, C("#E8B33C") },
	}
	local ax, ay = 8, 92
	for _, a in ipairs(assets) do
		local card = K.f(root, "AS", ax, ay, 150, 120, T.bg4)
		K.corner(card, 6)
		K.stroke(card, T.line2, 1)
		local pv = K.f(card, "PV", 6, 6, 138, 76, T.bg0)
		K.corner(pv, 4)
		a[2](K.f(pv, "I", 57, 26, 24, 24), 24)
		pv.BackgroundColor3 = Color3.new(a[3].R * 0.2, a[3].G * 0.2, a[3].B * 0.2)
		K.txt(card, a[1], 8, 88, 100, 14, 10, T.txt)
		local ins = K.btn(card, "INS", 108, 86, 36, 18, T.sel, 3)
		K.txtS(ins, "INS", 9, T.txt, ARKHER.FONTB)
		ins.MouseButton1Click:Connect(function()
			pcall(function()
				local p = Instance.new("Part")
				p.Name = a[1]
				p.Parent = workspace
			end)
			K.notify("TOOLBOX", a[1] .. " inserido no workspace", "SUCCESS")
		end)
		ax = ax + 158
		if ax > 490 then ax = 8 ay = ay + 128 end
	end
	return g
end

-- ============ UNDO / REDO ============
ARKHER_REG.UndoRedo = function()
	local g, root = K.window("ArkherUndoRedo", "Undo / Redo History", 300, 100, 420, 360)
	local hist = { "Insert Part", "Move Baseplate", "Rename SpamPoint", "Edit Ribbon icon", "Change Transparency", "Insert Script", "Terrain paint" }
	local y = 36
	for i, h in ipairs(hist) do
		local row = K.btn(root, "H" .. i, 8, y, 404, 20, i == 4 and T.sel or T.bg4, 3)
		K.txt(row, (i <= 4 and "  " or "↺ ") .. h, 10, 0, 300, 20, 10, i <= 4 and T.txt or T.txt4)
		K.hover(row, row.BackgroundColor3, T.hover)
		row.MouseButton1Click:Connect(function() K.notify("UNDO", "Saltou para: " .. h, "INFO") end)
		y = y + 22
	end
	local ub = K.btn(root, "U", 8, y + 8, 90, 24, T.hover, 4)
	K.txtS(ub, "UNDO", 11, T.txt, ARKHER.FONTB)
	local rb = K.btn(root, "R", 104, y + 8, 90, 24, T.hover, 4)
	K.txtS(rb, "REDO", 11, T.txt, ARKHER.FONTB)
	ub.MouseButton1Click:Connect(function() K.notify("UNDO", "Desfeito: Edit Ribbon icon", "INFO") end)
	rb.MouseButton1Click:Connect(function() K.notify("UNDO", "Refeito", "INFO") end)
	return g
end

-- ============ LAYOUTS / PROFILES / DOCKING ============
ARKHER_REG.Layouts = function()
	local g, root = K.window("ArkherLayouts", "Workspace Profiles / Layout / Docking", 280, 90, 520, 360)
	local lays = { "Default Dual-Panel", "Animation Focus", "Debug Wide", "Coding Minimal", "Full Screen Viewport" }
	local y = 36
	for i, l in ipairs(lays) do
		local row = K.btn(root, "L" .. i, 8, y, 300, 22, i == 1 and T.sel or T.bg4, 4)
		K.txt(row, l, 10, 0, 240, 22, 11, i == 1 and T.txt or T.txt2)
		K.hover(row, row.BackgroundColor3, T.hover)
		local ap = K.btn(row, "AP", 240, 2, 56, 18, T.hover, 3)
		K.txtS(ap, "APPLY", 9, T.txt2)
		ap.MouseButton1Click:Connect(function() K.notify("LAYOUT", "Layout \"" .. l .. "\" aplicado", "SUCCESS") end)
		y = y + 25
	end
	local sv = K.btn(root, "SV", 8, y + 6, 120, 24, T.sel, 4)
	K.txtS(sv, "SAVE CURRENT", 10, T.txt, ARKHER.FONTB)
	K.toggle(root, 330, 40, true, "Docking")
	K.toggle(root, 330, 64, true, "Multi-window")
	K.toggle(root, 330, 88, false, "Auto-hide panels")
	K.toggle(root, 330, 112, true, "Snap to edges")
	return g
end

-- ============ NOTIFICATIONS CENTER ============
ARKHER_REG.NotificationsCenter = function()
	local g, root = K.window("ArkherNotifications", "Notifications", 320, 110, 460, 340)
	local kinds = { "INFO", "PROCESSING", "SUCCESS", "WARNING", "ERROR" }
	local kx = 8
	for i, kk in ipairs(kinds) do
		local b = K.btn(root, "K_" .. kk, kx, 32, 16 + #kk * 6, 18, T.bg4, 9)
		K.txtS(b, kk, 8, T.txt2, ARKHER.FONTB)
		K.hover(b, T.bg4, T.hover)
		kx = kx + 22 + #kk * 6
	end
	local feed = {
		{ "SUCCESS", "Snapshot salvo (checksum ok)" }, { "INFO", "Collab: Arkher-Agent entrou" },
		{ "WARNING", "D-O15: pressão alta no RENDER" }, { "PROCESSING", "Build em andamento..." },
		{ "ERROR", "Plugin Lightmap: timeout (isolado pelo sandbox)" }, { "INFO", "Localization pt-BR 100%" },
	}
	local cols = { SUCCESS = T.green, INFO = T.accent, WARNING = T.orange, PROCESSING = T.accent2, ERROR = C("#E05252") }
	local y = 58
	for _, f in ipairs(feed) do
		local row = K.f(root, "N", 8, y, 444, 24, T.bg4)
		K.corner(row, 4)
		K.f(row, "B", 0, 0, 3, 24, cols[f[1]])
		K.txt(row, f[1], 10, 0, 90, 24, 9, cols[f[1]], ARKHER.FONTB)
		K.txt(row, f[2], 104, 0, 330, 24, 10, T.txt2)
		y = y + 27
	end
	return g
end
