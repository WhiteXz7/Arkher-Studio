-- arkher/undo.lua — historico real com agrupamento (client-side, DataModel direto).
-- Cada entrada: {label=..., undo=fn, redo=fn}. Grupos: begin(id)/commit(id).
-- Backups: propriedades (valor antigo), instancias (clone), terreno (CopyRegion).
local Undo = {}
Undo.stack, Undo.redoStack = {}, {}
Undo.group, Undo.groupLabel = nil, nil
Undo.limit = 200

function Undo.push(label, undoFn, redoFn)
  local e = { label = label, undo = undoFn, redo = redoFn, t = os.clock() }
  if Undo.group then
    Undo.group[#Undo.group + 1] = e
  else
    Undo.stack[#Undo.stack + 1] = e
    if #Undo.stack > Undo.limit then table.remove(Undo.stack, 1) end
    Undo.redoStack = {}
  end
  return e
end

function Undo.begin(label)
  Undo.group, Undo.groupLabel = {}, label or "group"
end

function Undo.commit()
  if not Undo.group then pcall(function() if _G.ARKHER and _G.ARKHER.cmd then _G.ARKHER.cmd.done() end end) return end
  local g, label = Undo.group, Undo.groupLabel
  Undo.group, Undo.groupLabel = nil, nil
  if #g == 0 then return end
  Undo.push(label, function()
    for i = #g, 1, -1 do pcall(g[i].undo) end
  end, function()
    for i = 1, #g do pcall(g[i].redo) end
  end)
end

function Undo.cancel()
  if not Undo.group then return end
  local g = Undo.group
  Undo.group, Undo.groupLabel = nil, nil
  for i = #g, 1, -1 do pcall(g[i].undo) end
end

function Undo.undo()
  local e = table.remove(Undo.stack)
  if not e then return false, "Nothing to undo." end
  local ok, err = pcall(e.undo)
  if ok then Undo.redoStack[#Undo.redoStack + 1] = e end
  return ok, ok and ("Undone: " .. e.label) or tostring(err)
end

function Undo.redo()
  local e = table.remove(Undo.redoStack)
  if not e then return false, "Nothing to redo." end
  local ok, err = pcall(e.redo)
  if ok then Undo.stack[#Undo.stack + 1] = e end
  return ok, ok and ("Redone: " .. e.label) or tostring(err)
end

function Undo.history()
  local h = {}
  for i, e in ipairs(Undo.stack) do h[#h + 1] = { i = i, label = e.label } end
  return h
end

function Undo.clear()
  Undo.stack, Undo.redoStack, Undo.group = {}, {}, nil
end

-- ajuda: registra troca de propriedade com undo real.
function Undo.prop(inst, key, newValue, label)
  local ok, old = pcall(function() return inst[key] end)
  if not ok then return false, "Unreadable property " .. tostring(key) end
  local ok2, err2 = pcall(function() inst[key] = newValue end)
  if not ok2 then return false, tostring(err2) end
  Undo.push(label or (key .. " change"),
    function() inst[key] = old end,
    function() inst[key] = newValue end)
  return true
end

-- ajuda: registra criacao (undo=destroi, redo=recria clone guardado).
function Undo.created(inst, label)
  local parent, clone = inst.Parent, nil
  Undo.push(label or ("create " .. inst.ClassName),
    function() inst:Destroy() end,
    function()
      if not clone then return end
      clone.Parent = parent
    end)
  -- guarda o clone DEPOIS (o original segue vivo ate o undo).
  local ok, c = pcall(function() return inst:Clone() end)
  if ok then clone = c end
  return true
end

-- ajuda: registra delecao (undo=restaura clone, redo=destroi de novo).
function Undo.deleted(inst, label)
  local parent = inst.Parent
  local ok, c = pcall(function() return inst:Clone() end)
  if not ok then return false, "Uncloneable instance." end
  local cur = inst
  Undo.push(label or ("delete " .. inst.Name),
    function() cur = c:Clone() cur.Parent = parent end,
    function() if cur then pcall(function() cur:Destroy() end) end end)
  return true
end

-- ajuda: backup de regiao do terreno (CopyRegion/PasteRegion reais).
function Undo.terrainBackup(region, label)
  local ok, terr = pcall(function() return game:GetService("Workspace").Terrain end)
  if not ok or not terr then return nil end
  local ok2, snap = pcall(function() return terr:CopyRegion(region) end)
  if not ok2 then return nil end
  local entry = { region = region, snap = snap }
  function entry.restore()
    pcall(function() terr:PasteRegion(snap, region.CFrame.Position, true) end)
  end
  entry.label = label or "terrain op"
  return entry
end

return Undo
