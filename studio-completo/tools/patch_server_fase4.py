"""Patch Fase 4 no server.lua (+ espelho em modules/arkher_services.lua):
DataStore mirror da cloud + PlaceCreate chain + pyPost + Teleport/PublishReal/AccountPlaces.
One-shot."""
import io

FILES = ["studio-completo/scripts/server.lua",
         "studio-completo/scripts/modules/arkher_services.lua"]


def rep(s, old, new, tag):
    assert s.count(old) == 1, f"anchor {tag}: count={s.count(old)}"
    return s.replace(old, new)


DS_HELPERS = '''-- ============ ARKHER CLOUD DURAVEL (DataStore mirror) ============
local DS_IDX = "arkher_cloud_idx_v1"
local dsState = { ok = false, msg = "" }
local function dsStore()
\tlocal ok, svc = pcall(function() return game:GetService("DataStoreService") end)
\tif not ok or not svc then return nil end
\tlocal ok2, st = pcall(function() return svc:GetDataStore("arkher_cloud_v1") end)
\tif not ok2 then dsState.msg = tostring(st):sub(1, 120) return nil end
\tdsState.ok = true
\treturn st
end
local function dsIdxRead(st)
\tlocal ok, v = pcall(function() return st:GetAsync(DS_IDX) end)
\tif ok and type(v) == "table" then return v end
\treturn {}
end
local function dsMirrorPut(st, rec, json)
\tpcall(function() st:SetAsync("arkher_proj_" .. tostring(rec.id), { rec = rec, snapshot = json }) end)
\tlocal idx = dsIdxRead(st)
\tlocal out, seen = {}, {}
\tout[#out + 1] = rec seen[rec.id] = true
\tfor _, r in ipairs(idx) do
\t\tif type(r) == "table" and r.id and not seen[r.id] then seen[r.id] = true out[#out + 1] = r end
\t\tif #out >= 50 then break end
\tend
\tpcall(function() st:SetAsync(DS_IDX, out) end)
end
local function dsListMissing(vault)
\tlocal have = {}
\tfor _, r in ipairs(vault) do if type(r) == "table" and r.id then have[r.id] = true end end
\tlocal st = dsStore()
\tif not st then return {} end
\tlocal out = {}
\tfor _, r in ipairs(dsIdxRead(st)) do
\t\tif type(r) == "table" and r.id and not have[r.id] then
\t\t\tr.src = "ds" out[#out + 1] = r
\t\tend
\tend
\treturn out
end
local function dsSnapGet(id)
\tlocal st = dsStore()
\tif not st then return nil end
\tlocal ok, v = pcall(function() return st:GetAsync("arkher_proj_" .. tostring(id)) end)
\tif ok and type(v) == "table" and type(v.snapshot) == "string" then
\t\treturn { data = v.snapshot, record = v.rec or { id = id } }
\tend
\treturn nil
end
local function dsDel(id)
\tlocal st = dsStore()
\tif not st then return false end
\tpcall(function() st:RemoveAsync("arkher_proj_" .. tostring(id)) end)
\tlocal idx = dsIdxRead(st)
\tlocal out = {}
\tfor _, r in ipairs(idx) do if not (type(r) == "table" and tostring(r.id) == tostring(id)) then out[#out + 1] = r end end
\tpcall(function() st:SetAsync(DS_IDX, out) end)
\treturn true
end
'''

for path in FILES:
    s = io.open(path, encoding="utf-8").read()
    if "DS_IDX" in s:
        print(path, "ja tem DS mirror (pulando)")
        continue
    s = rep(s, "function M.cloudPut(name, json, size, nodes)",
            DS_HELPERS + "function M.cloudPut(name, json, size, nodes)", "ds-helpers@" + path)
    s = rep(s, "\tp.Parent = cloud\n\treturn projRecord(p)\nend",
            "\tp.Parent = cloud\n\tlocal rec = projRecord(p)\n"
            "\tpcall(function() local st = dsStore() if st then dsMirrorPut(st, rec, json) end end)\n"
            "\treturn rec\nend", "ds-put@" + path)
    s = rep(s, '\ttable.sort(out, function(a, b) return (b.savedAt or "") > (a.savedAt or "") end)\n\treturn out',
            "\tfor _, r in ipairs(dsListMissing(out)) do out[#out + 1] = r end\n"
            '\ttable.sort(out, function(a, b) return (b.savedAt or "") > (a.savedAt or "") end)\n\treturn out',
            "ds-list@" + path)
    s = rep(s, '\tlocal p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)\n\tif not p then return nil end',
            '\tlocal p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)\n'
            '\tif not p then local got = dsSnapGet(id) if got then return got end return nil end',
            "ds-get@" + path)
    s = rep(s, '\tlocal p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)\n\tif not p then return false end\n\tp:Destroy()\n\treturn true\nend',
            '\tlocal p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)\n'
            '\tif not p then return dsDel(id) end\n\tp:Destroy()\n\tpcall(function() dsDel(id) end)\n\treturn true\nend',
            "ds-del@" + path)
    s = rep(s, "\t\tmembers = #M.team().members,\n\t}",
            "\t\tmembers = #M.team().members,\n\t\tds = dsState.ok,\n"
            '\t\tbackend = dsState.ok and "vault+datastore" or "vault",\n\t}',
            "ds-status@" + path)
    io.open(path, "w", encoding="utf-8").write(s)
    print(path, "DS mirror OK")

# ---- só server.lua: PlaceCreate chain + pyPost + handlers ----
P = FILES[0]
s = io.open(P, encoding="utf-8").read()
assert "templateChain" not in s, "fase4 ja aplicada no server!"
s = rep(s,
        '\tlocal template = tonumber(payload.template) or 9544032260 -- baseplate do Roblox\n'
        '\tlocal desc = tostring(payload.description or "Criado com Arkher Studio") or ""\n'
        '\tlocal ok, ret = pcall(function()\n'
        '\t\treturn game:GetService("AssetService"):CreatePlaceAsync(name, template, desc)\n'
        '\tend)\n'
        '\tif not ok then\n'
        '\t\tlocal msg = tostring(ret)\n'
        '\t\treturn { error = "CreatePlaceAsync recusou (" .. msg .. "). Só funciona em jogo publicado online com permissão de criação de place ativa." }\n'
        '\tend\n'
        '\treturn { placeId = ret, msg = "PLACE CRIADA no seu perfil: id " .. tostring(ret) .. "  — abra em roblox.com/games/" .. tostring(ret) }\nend',
        '\t-- templateChain: pedido > place atual (sua) > baseplate publica. Só online+publicado.\n'
        '\tlocal wanted = tonumber(payload.template) or 0\n'
        '\tlocal selfPlace = 0\n'
        '\tpcall(function() selfPlace = game.PlaceId or 0 end)\n'
        '\tlocal chain = {}\n'
        '\tif wanted > 0 then chain[#chain + 1] = wanted end\n'
        '\tif selfPlace > 0 and selfPlace ~= wanted then chain[#chain + 1] = selfPlace end\n'
        '\tchain[#chain + 1] = 9544032260\n'
        '\tlocal desc = tostring(payload.description or "Criado com Arkher Studio") or ""\n'
        '\tlocal ret, used, errs = nil, 0, {}\n'
        '\tfor _, tpl in ipairs(chain) do\n'
        '\t\tlocal ok, r = pcall(function() return game:GetService("AssetService"):CreatePlaceAsync(name, tpl, desc) end)\n'
        '\t\tif ok and tonumber(r) then ret, used = r, tpl break\n'
        '\t\telse errs[#errs + 1] = tpl .. ": " .. tostring(r):sub(1, 100) end\n'
        '\tend\n'
        '\tif not ret then\n'
        '\t\treturn { error = "CreatePlace recusou (" .. table.concat(errs, " | ") .. "). Regras: jogo PUBLICADO + jogando online (nao funciona em Play Solo); o template precisa ser seu, publicado e com copia-permitida." }\n'
        '\tend\n'
        '\treturn { placeId = ret, templateUsed = used,\n'
        '\t\turl = "https://www.roblox.com/games/" .. tostring(ret),\n'
        '\t\tmsg = "PLACE CRIADA na sua conta: id " .. tostring(ret) .. " (template " .. tostring(used) .. ")" }\nend',
        "place-chain")
s = rep(s,
        '\tlocal ok3, data = pcall(function() return Http:JSONDecode(res) end)\n'
        '\tif not ok3 then return nil, "resposta nao-JSON do python bridge" end\n\treturn data\nend',
        '\tlocal ok3, data = pcall(function() return Http:JSONDecode(res) end)\n'
        '\tif not ok3 then return nil, "resposta nao-JSON do python bridge" end\n\treturn data\nend\n'
        'local function pyPost(path2, body)\n'
        '\tlocal ok2, res = pcall(function()\n'
        '\t\treturn Http:PostAsync(PY_URL .. path2, body, Enum.HttpContentType.ApplicationJson, false)\n'
        '\tend)\n'
        '\tif not ok2 then\n'
        '\t\treturn nil, ("python bridge/offline OU HttpService desligado: ligar em Game Settings > Security > HTTP Requests. Detalhe: %s"):format(tostring(res))\n'
        '\tend\n'
        '\tlocal ok3, data = pcall(function() return Http:JSONDecode(res) end)\n'
        '\tif not ok3 then return nil, "resposta nao-JSON do python bridge (POST " .. path2 .. ")" end\n'
        '\treturn data\nend',
        "pyPost")
s = rep(s, "function handlers.Publish(player, payload)",
        'local function sanitizeTree(t)\n'
        '\tif type(t) ~= "table" then\n'
        '\t\tlocal ty = typeof(t)\n'
        '\t\tif ty == "Vector3" or ty == "Vector2" then return { x = t.X, y = t.Y, z = t.Z } end\n'
        '\t\tif ty == "Color3" then return { x = t.R, y = t.G, z = t.B } end\n'
        '\t\tif ty == "UDim" or ty == "UDim2" or ty == "Rect" or ty == "CFrame" or ty == "BrickColor" then return tostring(t) end\n'
        '\t\tif ty == "string" or ty == "number" or ty == "boolean" then return t end\n'
        '\t\treturn nil\n'
        '\tend\n'
        '\tlocal o = {}\n'
        '\tfor k, v in pairs(t) do\n'
        '\t\tif k ~= "_r" then local c = sanitizeTree(v) if c ~= nil then o[k] = c end end\n'
        '\tend\n'
        '\treturn o\n'
        'end\n'
        'function handlers.TeleportTo(player, payload)\n'
        '\tlocal pid = tonumber(payload.placeId or 0) or 0\n'
        '\tassert(pid > 0, "placeId invalido.")\n'
        '\tlocal ok, err = pcall(function()\n'
        '\t\tgame:GetService("TeleportService"):TeleportAsync(pid, { player })\n'
        '\tend)\n'
        '\tif not ok then return { error = "Teleport recusou: " .. tostring(err):sub(1, 200) } end\n'
        '\treturn { ok = true, placeId = pid }\n'
        'end\n'
        'function handlers.PublishReal(player, payload)\n'
        '\tlocal data = sanitizeTree(serializeTree(workspace))\n'
        '\tlocal body = Http:JSONEncode({ name = tostring(payload.name or "Arkher Place"), tree = data })\n'
        '\tassert(#body < 3000000, "Cena grande demais p/ exportar (3MB).")\n'
        '\tlocal res, err = pyPost("/cloud/export", body)\n'
        '\tif not res then return { error = err } end\n'
        '\tif res.error then return { error = tostring(res.error) } end\n'
        '\treturn res\n'
        'end\n'
        'function handlers.AccountPlaces(player, payload)\n'
        '\tlocal uid = 0\n'
        '\tpcall(function() uid = game.GameId or 0 end)\n'
        '\tassert(uid > 0, "Universo desconhecido (jogo nao publicado?).")\n'
        '\tlocal data, err = pyGet("/cloud/places?universeId=" .. tostring(uid))\n'
        '\tif not data then return { ok = false, error = err } end\n'
        '\tif data.error then return { ok = false, error = tostring(data.error) } end\n'
        '\treturn { places = data.places or {}, universeId = uid }\n'
        'end\n'
        '\nfunction handlers.Publish(player, payload)',
        "real-handlers")
io.open(P, "w", encoding="utf-8").write(s)
print("server.lua fase4 OK")
