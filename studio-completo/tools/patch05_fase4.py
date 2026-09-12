"""Patch Fase 4 no 05_StudioX.lua: reroute Save/Open/Cloud p/ baked + 1-clique + conta/export.
One-shot."""
import io

P05 = "studio-completo/scripts/05_StudioX.lua"
s = io.open(P05, encoding="utf-8").read()
assert "FASE 4" not in s, "fase4 ja aplicada!"


def rep(old, new, tag):
    global s
    assert s.count(old) == 1, f"anchor {tag}: count={s.count(old)}"
    s = s.replace(old, new)


# A: ribbon Save/Open/Cloud -> janela ASSADA (adeus modais runtime nesses 3)
rep('\tHOME_Save = { "menus", "Save" },',
    '\tHOME_Save = { "open", "V2_ArkherSaveOpen" },', "A-save")
rep('\tHOME_Open = { "menus", "File" },',
    '\tHOME_Open = { "open", "V2_ArkherSaveOpen" },', "A-open")
rep('\tHOME_Cloud = { "menus", "OpenCloud" },',
    '\tHOME_Cloud = { "open", "V2_ArkherSaveOpen" },', "A-cloud")

# B: row click respeita modo conta
rep("\t\tfor i, row in ipairs(rows) do local b = rowBtn(row) if b then pcall(function()\n"
    "\t\t\tb.MouseButton1Click:Connect(function() sel = i paint() end)\n"
    "\t\t\tb.Activated:Connect(function() sel = i paint() end)\n\t\tend) end end",
    "\t\tfor i, row in ipairs(rows) do local b = rowBtn(row) if b then pcall(function()\n"
    "\t\t\tlocal function pick() if _G.ArkherSvConta and _G.ArkherSvConta.on then _G.ArkherSvConta.sel = i "
    "if _G.ArkherSvContaPaint then _G.ArkherSvContaPaint() end else sel = i paint() end end\n"
    "\t\t\tb.MouseButton1Click:Connect(pick)\n"
    "\t\t\tb.Activated:Connect(pick)\n\t\tend) end end",
    "B-pick")

# C: Go2 = teleport na conta / abre com refresh na cloud
rep("\t\ttap(go2, function()\n\t\t\tlocal p = projects[sel]\n"
    '\t\t\tif not p then say("Nada no slot " .. sel .. " (salve primeiro).", true) return end',
    "\t\ttap(go2, function()\n"
    "\t\t\tif _G.ArkherSvConta and _G.ArkherSvConta.on then\n"
    "\t\t\t\tlocal c = _G.ArkherSvConta.places[_G.ArkherSvConta.sel]\n"
    '\t\t\t\tif not c then say("Nada selecionado na conta.", true) return end\n'
    '\t\t\t\tsay("Indo p/ " .. tostring(c.name) .. "...")\n'
    '\t\t\t\tlocal _, e = busApi("TeleportTo", { placeId = c.id })\n'
    '\t\t\t\tif e then say("Abrir: " .. tostring(e), true) end return\n'
    "\t\t\tend\n"
    "\t\t\trefresh()\n\t\t\tlocal p = projects[sel]\n"
    '\t\t\tif not p then say("Nada no slot " .. sel .. " (salve primeiro).", true) return end',
    "C-go2")

# D: Publish = 1-CLIQUE (cloud + save + link)
rep('\t\ttap(pub, function()\n\t\t\tlocal res, err = busApi("Publish", {})\n'
    '\t\t\tif err then say("Publish: " .. tostring(err), true) else say("Publicado: " .. dump(res)) end\n\t\tend)',
    '\t\ttap(pub, function()\n'
    '\t\t\tsay("1-CLIQUE: snapshot na cloud...")\n'
    '\t\t\tlocal snap, e1 = busApi("CloudSave", { name = "Auto " .. os.date("%d/%m %H:%M") })\n'
    '\t\t\tif e1 then say("1-CLIQUE: cloud falhou: " .. tostring(e1), true) return end\n'
    '\t\t\tlocal pr = snap and snap.project or {}\n'
    '\t\t\tsay("1-CLIQUE: cloud ok (" .. tostring(pr.nodes or 0) .. " obj). Salvando place...")\n'
    '\t\t\tlocal _, e2 = busApi("SavePlace", {})\n'
    '\t\t\tlocal pid = 0 pcall(function() pid = game.PlaceId or 0 end)\n'
    '\t\t\tif e2 then say("1-CLIQUE: cloud OK; SavePlace recusou (ative o API nas settings da place): " .. tostring(e2), true)\n'
    '\t\t\telse say("PUBLICADO 1-CLIQUE: cloud + place. roblox.com/games/" .. tostring(pid)) end\n'
    '\t\t\trefresh()\n\t\tend)',
    "D-1click")

# E: NewPlace guarda id p/ ABRIR
rep('\t\t\tif err then say("PlaceCreate: " .. tostring(err), true) else say("Place criada: " .. dump(res)) end',
    '\t\t\tif err then say("PlaceCreate: " .. tostring(err), true)\n'
    '\t\t\telse _G.ArkherLastPlace = res and res.placeId or nil\n'
    '\t\t\t\tsay("Place criada: " .. dump(res) .. " — ABRIR teleporta p/ la.") end',
    "E-lastplace")

S4 = '''
-- ==== FASE 4 — SaveOpen: ABRIR + EXPORT + CONTA (conta real) ====
do
\tlocal sv = host and host:FindFirstChild("V2_ArkherSaveOpen")
\tif sv then
\t\t_G.ArkherSvConta = _G.ArkherSvConta or { on = false, places = {}, sel = 1 }
\t\tlocal st = _G.ArkherSvConta
\t\tlocal input = sv:FindFirstChild("Input")
\t\tif input and not input:IsA("TextBox") then input = input:FindFirstChildOfClass("TextBox", true) end
\t\tlocal abrir = sv:FindFirstChild("Abrir")
\t\tlocal export = sv:FindFirstChild("Export")
\t\tlocal conta = sv:FindFirstChild("Conta")
\t\tlocal rows = { sv:FindFirstChild("R_0"), sv:FindFirstChild("R_1"), sv:FindFirstChild("R_2") }
\t\tlocal SEL_BG = Color3.fromRGB(26, 42, 74)
\t\tlocal UNS_BG = Color3.fromRGB(7, 13, 25)
\t\tlocal function rtext(row)
\t\t\tif not row then return nil end
\t\t\tif row:IsA("TextButton") or row:IsA("TextLabel") then return row end
\t\t\treturn row:FindFirstChildOfClass("TextLabel", true) or row:FindFirstChildOfClass("TextButton", true)
\t\tend
\t\t_G.ArkherSvContaPaint = function()
\t\t\tfor i, row in ipairs(rows) do
\t\t\t\tlocal c = st.places[i]
\t\t\t\tlocal t = rtext(row)
\t\t\t\tif t then pcall(function()
\t\t\t\t\tt.Text = c and ("@ " .. tostring(c.name):sub(1, 30) .. "  [id " .. tostring(c.id) .. "]"):sub(1, 44) or ("-- conta slot " .. i .. " --")
\t\t\t\tend) end
\t\t\t\tif row then pcall(function()
\t\t\t\t\trow.BackgroundColor3 = (i == st.sel) and SEL_BG or UNS_BG
\t\t\t\t\trow.BackgroundTransparency = (i == st.sel) and 0 or 0.55
\t\t\t\tend) end
\t\t\tend
\t\tend
\t\tlocal function paintCloudBack()
\t\t\tlocal res, err = busApi("CloudList", {})
\t\t\tlocal projects = (res and not err) and (res.projects or {}) or {}
\t\t\tfor i, row in ipairs(rows) do
\t\t\t\tlocal p = projects[i]
\t\t\t\tlocal t = rtext(row)
\t\t\t\tif t then pcall(function()
\t\t\t\t\tt.Text = p and (tostring(p.name):sub(1, 24) .. "  [" .. tostring(p.nodes or 0) .. " obj]"):sub(1, 44) or ("-- slot " .. i .. " --")
\t\t\t\tend) end
\t\t\tend
\t\tend
\t\tlocal function tap(n, fn) if n and n:IsA("GuiButton") then pcall(function()
\t\t\tn.MouseButton1Click:Connect(fn) n.Activated:Connect(fn)
\t\tend) end end
\t\ttap(conta, function()
\t\t\tst.on = not st.on
\t\t\tif not st.on then paintCloudBack() say("Modo CLOUD (snapshots).") return end
\t\t\tsay("Listando places reais da conta...")
\t\t\tlocal res, err = busApi("AccountPlaces", {})
\t\t\tif err then st.on = false say("Conta: " .. tostring(err), true) return end
\t\t\tst.places = (res and res.places) or {}
\t\t\tst.sel = 1
\t\t\t_G.ArkherSvContaPaint()
\t\t\tsay("CONTA: " .. #st.places .. " places reais. Go2/ABRIR teleporta.")
\t\tend)
\t\ttap(abrir, function()
\t\t\tlocal target, nm = nil, nil
\t\t\tif st.on then local c = st.places[st.sel] if c then target, nm = c.id, c.name end
\t\t\telse target = _G.ArkherLastPlace end
\t\t\tif not target then say(st.on and "Nada selecionado na conta." or "Crie uma place (NEW PLACE) ou entre na CONTA primeiro.", true) return end
\t\t\tsay("Abrindo " .. tostring(nm or ("place " .. tostring(target))) .. "...")
\t\t\tlocal _, err = busApi("TeleportTo", { placeId = target })
\t\t\tif err then say("ABRIR: " .. tostring(err), true) end
\t\tend)
\t\ttap(export, function()
\t\t\tlocal t = input and input.Text or ""
\t\t\tt = t:match("^%s*(.-)%s*$")
\t\t\tlocal nm = (#t >= 3) and t or ("Arkher " .. os.date("%d/%m %H:%M"))
\t\t\tsay("EXPORT: gerando .rbxlx de " .. nm .. "...")
\t\t\tlocal res, err = busApi("PublishReal", { name = nm })
\t\t\tif err then say("EXPORT: " .. tostring(err), true) return end
\t\t\tif res and res.published then say("PUBLICADO NA CONTA: versao " .. tostring(res.version) .. " (" .. tostring((res.stats or {}).parts or 0) .. " parts).")
\t\t\telseif res and res.url then say("RBXLX pronto: " .. tostring(res.url) .. " (" .. tostring((res.stats or {}).parts or 0) .. " parts, " .. tostring((res.stats or {}).bytes or 0) .. " bytes). Baixe e publique pelo Studio.")
\t\t\telse say("EXPORT: " .. tostring(res and res.file or "?")) end
\t\tend)
\tend
end

'''
s = s.rstrip("\n") + "\n" + S4
io.open(P05, "w", encoding="utf-8").write(s)
print("05 fase4 OK")
