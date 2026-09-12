"""Patch Fase 3 no 05_StudioX.lua: fia V2_ArkherSaveOpen assada. One-shot."""
import io

P05 = "studio-completo/scripts/05_StudioX.lua"
s = io.open(P05, encoding="utf-8").read()
assert "FASE 3 — SaveOpen" not in s, "patch ja aplicado!"
print("tail 05:", repr(s.rstrip("\n")[-120:]))

S1 = '''
-- ==== FASE 3 — V2_ArkherSaveOpen (janela ASSADA): cloud + place + publish REAIS ====
do
\tlocal sv = host and host:FindFirstChild("V2_ArkherSaveOpen")
\tif sv then
\t\tlocal HS = game:GetService("HttpService")
\t\tlocal input = sv:FindFirstChild("Input")
\t\tif input and not input:IsA("TextBox") then input = input:FindFirstChildOfClass("TextBox", true) end
\t\tlocal go = sv:FindFirstChild("Go")
\t\tlocal go2 = sv:FindFirstChild("Go2")
\t\tlocal newP = sv:FindFirstChild("NewPlace")
\t\tlocal saveA = sv:FindFirstChild("SaveAcct")
\t\tlocal pub = sv:FindFirstChild("Publish")
\t\tlocal tabS = sv:FindFirstChild("TabS")
\t\tlocal tabO = sv:FindFirstChild("TabO")
\t\tlocal rows = { sv:FindFirstChild("R_0"), sv:FindFirstChild("R_1"), sv:FindFirstChild("R_2") }
\t\tlocal projects, sel, mode = {}, 1, "save"
\t\tlocal SEL_BG = Color3.fromRGB(26, 42, 74)
\t\tlocal UNS_BG = Color3.fromRGB(7, 13, 25)
\t\tlocal function dump(res)
\t\t\tlocal ok, j = pcall(function() return HS:JSONEncode(res) end)
\t\t\tif ok and type(j) == "string" then return j:sub(1, 160) end
\t\t\treturn tostring(res)
\t\tend
\t\tlocal function rowText(row)
\t\t\tif not row then return nil end
\t\t\tif row:IsA("TextButton") or row:IsA("TextLabel") then return row end
\t\t\treturn row:FindFirstChildOfClass("TextLabel", true) or row:FindFirstChildOfClass("TextButton", true)
\t\tend
\t\tlocal function rowBtn(row)
\t\t\tif not row then return nil end
\t\t\tif row:IsA("GuiButton") then return row end
\t\t\treturn row:FindFirstChildOfClass("GuiButton", true)
\t\tend
\t\tlocal function paint()
\t\t\tfor i, row in ipairs(rows) do
\t\t\t\tlocal p = projects[i]
\t\t\t\tlocal t = rowText(row)
\t\t\t\tif t then pcall(function()
\t\t\t\t\tt.Text = p and (tostring(p.name):sub(1, 24) .. "  [" .. tostring(p.nodes or 0) .. " obj]  " .. tostring(p.savedAt or "")):sub(1, 44) or ("-- slot " .. i .. " --")
\t\t\t\tend) end
\t\t\t\tif row then pcall(function()
\t\t\t\t\trow.BackgroundColor3 = (i == sel) and SEL_BG or UNS_BG
\t\t\t\t\trow.BackgroundTransparency = (i == sel) and 0 or 0.55
\t\t\t\tend) end
\t\t\tend
\t\t\tfor _, tp in ipairs({ tabS, tabO }) do if tp then pcall(function()
\t\t\t\tlocal on = (tp == tabS and mode == "save") or (tp == tabO and mode == "open")
\t\t\t\ttp.BackgroundColor3 = on and SEL_BG or UNS_BG
\t\t\t\ttp.BackgroundTransparency = on and 0 or 0.55
\t\t\tend) end end
\t\tend
\t\tlocal function refresh()
\t\t\tif not sv.Visible then return end
\t\t\tlocal res, err = busApi("CloudList", {})
\t\t\tif err then say("Cloud: " .. tostring(err), true) return end
\t\t\tprojects = (res and res.projects) or {}
\t\t\tif sel > math.max(1, #projects) then sel = 1 end
\t\t\tpaint()
\t\tend
\t\tlocal function curName(def)
\t\t\tlocal t = input and input.Text or ""
\t\t\tt = t:match("^%s*(.-)%s*$")
\t\t\tif #t < 3 then return def end
\t\t\treturn t
\t\tend
\t\tfor i, row in ipairs(rows) do local b = rowBtn(row) if b then pcall(function()
\t\t\tb.MouseButton1Click:Connect(function() sel = i paint() end)
\t\t\tb.Activated:Connect(function() sel = i paint() end)
\t\tend) end end
\t\tlocal function tap(n, fn) if n and n:IsA("GuiButton") then pcall(function()
\t\t\tn.MouseButton1Click:Connect(fn) n.Activated:Connect(fn)
\t\tend) end end
\t\ttap(tabS, function() mode = "save" paint() refresh() say("Modo SALVAR (Go = salva na cloud).") end)
\t\ttap(tabO, function() mode = "open" paint() refresh() say("Modo ABRIR (Go2 = abre o slot selecionado).") end)
\t\ttap(go, function()
\t\t\tlocal res, err = busApi("CloudSave", { name = curName("") })
\t\t\tif err then say("Salvar: " .. tostring(err), true)
\t\t\telse local pr = res and res.project or {} say("Salvo na cloud: " .. tostring(pr.name or "?") .. " (" .. tostring(pr.nodes or 0) .. " obj).") refresh() end
\t\tend)
\t\ttap(go2, function()
\t\t\tlocal p = projects[sel]
\t\t\tif not p then say("Nada no slot " .. sel .. " (salve primeiro).", true) return end
\t\t\tsay("Abrindo " .. tostring(p.name) .. " (viewport atual sera substituida)...")
\t\t\tlocal _, err = busApi("CloudOpen", { id = p.id })
\t\t\tif err then say("Abrir: " .. tostring(err), true) else say("Projeto aberto: " .. tostring(p.name) .. ".") end
\t\tend)
\t\ttap(newP, function()
\t\t\tlocal nm = curName("Place " .. os.date("%d/%m %H:%M"))
\t\t\tsay("Criando place " .. nm .. "...")
\t\t\tlocal res, err = busApi("PlaceCreate", { name = nm })
\t\t\tif err then say("PlaceCreate: " .. tostring(err), true) else say("Place criada: " .. dump(res)) end
\t\tend)
\t\ttap(saveA, function()
\t\t\tlocal res, err = busApi("SavePlace", {})
\t\t\tif err then say("SavePlace: " .. tostring(err), true) else say("Place salva na conta: " .. dump(res)) end
\t\tend)
\t\ttap(pub, function()
\t\t\tlocal res, err = busApi("Publish", {})
\t\t\tif err then say("Publish: " .. tostring(err), true) else say("Publicado: " .. dump(res)) end
\t\tend)
\t\tif input and input:IsA("TextBox") then pcall(function()
\t\t\tinput.FocusLost:Connect(function(enter) if enter and go then pcall(function() go:Activate() end) end end)
\t\tend) end
\t\tpcall(function()
\t\t\tsv:GetPropertyChangedSignal("Visible"):Connect(function() if sv.Visible then refresh() end end)
\t\tend)
\t\tpaint()
\tend
end

'''
s = s.rstrip("\n") + "\n" + S1
io.open(P05, "w", encoding="utf-8").write(s)
print("05_StudioX: SaveOpen OK")
