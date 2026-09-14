-- arkher/registry.lua — registro unico de comandos (fonte unica) + validador.
-- Esquema por aba: {id, label, icon, groups={{id,label}}, commands={...40}}
-- Esquema por comando: {id, label, icon, tip, key, group, act, arg, panel}
--   act = chave em ACTIONS (sempre real); panel = nome do painel contextual
--   (opcional; quando ausente, o act executa direto com defaults honestos).
-- Validador: 30 abas x 40 cmds, ids unicos, icones existem, acts resolvem.
local Registry = {}
Registry.TABS = {}
Registry.BY_ID = {}
Registry.EXPECT_TABS, Registry.EXPECT_CMDS = 30, 40

function Registry.addFile(tabs)
  for _, t in ipairs(tabs) do
    Registry.TABS[#Registry.TABS + 1] = t
    for _, c in ipairs(t.commands) do
      c.tab = t.id
      Registry.BY_ID[c.id] = c
    end
  end
end

function Registry.validate(actions, icons)
  local errs = {}
  local function err(m) errs[#errs + 1] = m end
  if #Registry.TABS ~= Registry.EXPECT_TABS then
    err(("tabs: %d (esperado %d)"):format(#Registry.TABS, Registry.EXPECT_TABS))
  end
  local seen, n = {}, 0
  for _, t in ipairs(Registry.TABS) do
    if type(t.id) ~= "string" or t.id == "" then err("aba sem id") end
    if not icons.exists(t.icon) then err(("aba %s: icone '%s' ausente"):format(t.id, tostring(t.icon))) end
    if #t.commands ~= Registry.EXPECT_CMDS then
      err(("aba %s: %d cmds (esperado %d)"):format(t.id, #t.commands, Registry.EXPECT_CMDS))
    end
    local groups = {}
    for _, g in ipairs(t.groups or {}) do groups[g.id] = true end
    for _, c in ipairs(t.commands) do
      n = n + 1
      if seen[c.id] then err("cmd duplicado: " .. c.id) end
      seen[c.id] = true
      if not icons.exists(c.icon) then err(("%s: icone '%s' ausente"):format(c.id, tostring(c.icon))) end
      if type(c.tip) ~= "string" or #c.tip < 8 then err(c.id .. ": tooltip vazio/curto") end
      if c.group and not groups[c.group] then err(("%s: grupo '%s' nao existe"):format(c.id, tostring(c.group))) end
      if type(c.act) ~= "string" or actions[c.act] == nil then
        err(("%s: act '%s' sem implementacao"):format(c.id, tostring(c.act)))
      end
    end
  end
  return #errs == 0, errs, n
end

function Registry.find(id) return Registry.BY_ID[id] end

Registry.tabs = Registry.TABS
Registry.byId = Registry.BY_ID

return Registry
