"""Patch Fase 2b/3 no 10_Studio.lua: Run-bridge + toolbox paga. One-shot."""
import io

P10 = "studio-completo/scripts/10_Studio.lua"
s = io.open(P10, encoding="utf-8").read()


def rep(old, new, tag):
    global s
    assert s.count(old) == 1, f"anchor {tag}: count={s.count(old)}"
    s = s.replace(old, new)


# R1: Run -> bridge branch (LU cai no loadstring de sempre)
rep('\t\t\tonTap(runB, function()\n\t\t\t\tif not codeBox then return end\n\t\t\t\tbuffers[cur].code = codeBox.Text\n',
    '\t\t\tonTap(runB, function()\n\t\t\t\tif not codeBox then return end\n\t\t\t\tbuffers[cur].code = codeBox.Text\n'
    '\t\t\t\tif _G.ArkherSEBridge and _G.ArkherSEBridge(codeBox.Text, buffers[cur].name, term) then return end\n',
    "R1")
# T1a: MPS locals
rep('\t\tlocal searchFrame = tbW:FindFirstChild("Search")\n',
    '\t\tlocal MPS = game:GetService("MarketplaceService")\n'
    '\t\tlocal plr = game:GetService("Players").LocalPlayer\n'
    '\t\tlocal searchFrame = tbW:FindFirstChild("Search")\n',
    "T1a")
# T1b: paid flag
rep('\t\tlocal tb = { kind = "models", items = {}, note = false }\n',
    '\t\tlocal tb = { kind = "models", items = {}, note = false, paid = false }\n',
    "T1b")
# T2: paint com preco
rep('\t\t\t\t\tif lbl then lbl.Text = it and tostring(it.name):sub(1, 26) or "--" end\n',
    '\t\t\t\t\tif lbl then local t = it and tostring(it.name):sub(1, 22) or "--" '
    'if it and tonumber(it.price or 0) and tonumber(it.price) > 0 then t = t .. " [R$" .. tostring(it.price) .. "]" end '
    'lbl.Text = t end\n',
    "T2")
# T3a: buyPaid
rep('\t\tlocal function insertAt(i)\n',
    '\t\tlocal buyHooked = false\n'
    '\t\tlocal function buyPaid(it)\n'
    '\t\t\tlocal aid = tonumber(it.id or 0) or 0\n'
    '\t\t\tif aid <= 0 then say("Item pago sem id valido.", true) return end\n'
    '\t\t\tif not buyHooked then buyHooked = true\n'
    '\t\t\t\tpcall(function() MPS.PromptPurchaseFinished:Connect(function(p, assetId, ok)\n'
    '\t\t\t\t\tif ok and p == plr then say("Compra finalizada (asset " .. tostring(assetId) .. ").") end\n'
    '\t\t\t\tend) end)\n'
    '\t\t\tend\n'
    '\t\t\tpcall(function() MPS:PromptPurchase(plr, aid) end)\n'
    '\t\t\tsay("Abrindo compra de " .. tostring(it.name):sub(1, 28) .. " [R$" .. tostring(it.price or "?") .. "]...")\n'
    '\t\tend\n'
    '\t\tlocal function insertAt(i)\n',
    "T3a")
# T3b: branch pago
rep('\t\t\tlocal _, err = apiResult("ToolboxAssetInsert", { assetId = it.id, x = px, y = py, z = pz })\n',
    '\t\t\tif tb.paid then buyPaid(it) return end\n'
    '\t\t\tlocal _, err = apiResult("ToolboxAssetInsert", { assetId = it.id, x = px, y = py, z = pz })\n',
    "T3b")
# T4a: doPaidSearch
rep('\t\tlocal function doSearch()\n',
    '\t\tlocal function doPaidSearch(q)\n'
    '\t\t\tlocal res, err = apiResult("ToolboxPaidSearch", { query = q })\n'
    '\t\t\tif err then say("Loja paga: " .. tostring(err), true) return end\n'
    '\t\t\ttb.items = (res and res.items) or {}\n'
    '\t\t\ttb.paid = true\n'
    '\t\t\tpaint()\n'
    '\t\t\tsay("$ " .. #tb.items .. " pagos p/ " .. q:sub(1, 24) .. ". INS = comprar.")\n'
    '\t\tend\n'
    '\t\tlocal function doSearch()\n',
    "T4a")
# T4b: ramo $
rep('\t\t\tif #q < 2 then say("Digite 2+ letras e ENTER.", true) return end\n',
    '\t\t\tif #q < 2 then say("Digite 2+ letras e ENTER ($ = loja paga).", true) return end\n'
    '\t\t\tif q:sub(1, 1) == "$" then local rest = q:sub(2):match("^%s*(.-)%s*$") '
    'if rest:match("^%d+$") then buyPaid({ id = rest, name = "item #" .. rest, price = "?" }) '
    'else doPaidSearch(rest) end return end\n',
    "T4b")
# T4c: reset paid no caminho gratis (contexto do doSearch original)
rep('\t\t\ttb.items = (res and res.items) or {}\n\t\t\tpaint()\n\t\t\tsay("BAG "',
    '\t\t\ttb.items = (res and res.items) or {}\n\t\t\ttb.paid = false\n\t\t\tpaint()\n\t\t\tsay("BAG "',
    "T4c")

P6A = '''
-- PARTE 6A — ScriptEditor: LANG (LU/PY/C+/C#) + exec via PyBridge + autocomplete CLASSDB
do
\tlocal seW = host and host:FindFirstChild("V2_ArkherScriptEditor")
\tif seW then
\t\tlocal codeBox = seW:FindFirstChild("Code")
\t\tlocal langB = seW:FindFirstChild("LangPy")
\t\tlocal sugBox = seW:FindFirstChild("Suggest")
\t\tlocal LANGS = { "LU", "PY", "C+", "C#" }
\t\tlocal TOBR = { LU = "lua", PY = "py", ["C+"] = "cpp", ["C#"] = "csharp" }
\t\tlocal li = 1
\t\tlocal function paintLang()
\t\t\tif langB then local l = langB:FindFirstChild("Lbl") if l then l.Text = LANGS[li] end end
\t\tend
\t\tif langB then onTap(langB, function()
\t\t\tli = li % #LANGS + 1
\t\t\tpaintLang()
\t\t\tsay("ScriptEditor: " .. LANGS[li] .. (LANGS[li] == "LU" and " (exec local)" or " (exec PyBridge)") .. ".")
\t\tend) end
\t\tpaintLang()
\t\t_G.ArkherSEBridge = function(code, name, termFn)
\t\t\tlocal lg = LANGS[li]
\t\t\tif lg == "LU" then return false end
\t\t\tif termFn then termFn("bridge " .. lg .. ": executando...", false) end
\t\t\tlocal res, err = apiResult("PyRun", { task = "exec", lang = TOBR[lg], code = code })
\t\t\tif err then if termFn then termFn("BRIDGE ERRO: " .. tostring(err), true) end return true end
\t\t\tlocal out = res and (res.out or res.summary) or ""
\t\t\tlocal e2 = res and res.error or ""
\t\t\tif termFn then
\t\t\t\tif e2 ~= "" then termFn("ERRO: " .. tostring(e2) .. (out ~= "" and (" | " .. tostring(out):sub(1, 120)) or ""), true)
\t\t\t\telse termFn((out ~= "" and tostring(out):sub(1, 220) or "OK (sem saida)") .. " -- " .. tostring(name)) end
\t\t\tend
\t\t\treturn true
\t\tend
\t\tlocal sugs = {}
\t\tif sugBox then for i = 0, 7 do sugs[i] = sugBox:FindFirstChild("Sug" .. i) end end
\t\tlocal classes, classT, shown, lock = {}, 0, {}, false
\t\tlocal function hideSug() if sugBox then sugBox.Visible = false end end
\t\tlocal function refreshSug()
\t\t\tif lock then return end
\t\t\tif not sugBox or not codeBox then return end
\t\t\tif #classes == 0 and (os.clock() - classT) > 5 then
\t\t\t\tclassT = os.clock()
\t\t\t\tlocal res = apiResult("ClassList", {})
\t\t\t\tif res and res.items then for _, it in ipairs(res.items) do classes[#classes + 1] = it.class end end
\t\t\tend
\t\t\tif #classes == 0 then hideSug() return end
\t\t\tlocal pos = codeBox.CursorPosition or 1
\t\t\tlocal pre = (codeBox.Text or ""):sub(1, math.max(0, pos - 1))
\t\t\tlocal word = pre:match("[%w_]+$") or ""
\t\t\tif #word < 2 then hideSug() return end
\t\t\tlocal lw = word:lower()
\t\t\ttable.clear(shown)
\t\t\tfor _, c in ipairs(classes) do
\t\t\t\tif type(c) == "string" and c:lower():find(lw, 1, true) == 1 then shown[#shown + 1] = c end
\t\t\t\tif #shown >= 8 then break end
\t\t\tend
\t\t\tif #shown == 0 then hideSug() return end
\t\t\tfor i = 0, 7 do local b = sugs[i] if b then b.Text = (i < #shown) and ("  " .. shown[i + 1]) or "" b.Visible = i < #shown end end
\t\t\tsugBox.Visible = true
\t\tend
\t\tfor i = 0, 7 do local b = sugs[i] if b then onTap(b, function()
\t\t\tlocal pick = shown[i + 1]
\t\t\tif not pick or not codeBox then hideSug() return end
\t\t\tlocal pos = codeBox.CursorPosition or 1
\t\t\tlocal txt = codeBox.Text or ""
\t\t\tlocal pre = txt:sub(1, math.max(0, pos - 1)):gsub("[%w_]+$", "")
\t\t\tlock = true
\t\t\tcodeBox.Text = pre .. pick .. txt:sub(pos)
\t\t\t\tcodeBox.CursorPosition = #pre + #pick + 1
\t\t\tlock = false
\t\t\thideSug()
\t\t\tpcall(function() codeBox:CaptureFocus() end)
\t\tend) end end
\t\tif codeBox then pcall(function()
\t\t\tcodeBox:GetPropertyChangedSignal("Text"):Connect(refreshSug)
\t\t\tcodeBox:GetPropertyChangedSignal("CursorPosition"):Connect(refreshSug)
\t\tend) end
\tend
end

'''
assert "[ArkherX] 10_Studio:" in s[-300:], "tail mudou!"
s = s.rstrip("\n") + "\n" + P6A
io.open(P10, "w", encoding="utf-8").write(s)
print("10_Studio: R1+T1-T4+6A OK")
