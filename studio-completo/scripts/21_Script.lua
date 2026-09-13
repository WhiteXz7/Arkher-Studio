-- 21_Script (R16) — Script Studio: Lua + Python-subset + Blocos (compilam p/ Luau real).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local player = Players.LocalPlayer
local gui = script.Parent
assert(gui and gui.Name == "ArkherStudioUI", "must live under ArkherStudioUI.")
local canvas = gui:WaitForChild("Canvas")
local shell = canvas:WaitForChild("ArkherShell2", 30)
assert(shell, "ArkherShell2 missing from bake.")
local rt = gui:WaitForChild("ArkherServerClientRuntime", 30)
local clientBus = rt:WaitForChild("ClientBus")
local function find(n) return shell:FindFirstChild(n, true) end
local function vis(n, v) local o = find(n) if o then pcall(function() o.Visible = v end) end end
local function setText(n, t) local o = find(n) if o then pcall(function() o.Text = t end) end end
local function say(t, bad)
  pcall(function() clientBus:Invoke("Message", { text = tostring(t), bad = bad == true }) end)
end
local function api(action, payload)
  local ok, r = pcall(function()
    return clientBus:Invoke("API", { action = action, payload = payload or {} })
  end)
  if not ok then return nil, tostring(r) end
  if type(r) == "table" and r.error then return nil, tostring(r.error) end
  if type(r) == "table" and r.result ~= nil then return r.result end
  return r
end
local function on(n, fn)
  local o = find(n)
  if o and o.Activated then o.Activated:Connect(function() pcall(fn) end) end
end
local PANELS = { "SC11_Rail", "SC11_List", "SC11_Edit", "SC11_Py", "SC11_Blk", "SC11_Out", "SC11_Status" }
local DESK = { "T2_Panel", "C2_Panel", "S2_Panel", "O2_Panel", "O2_WPanel",
  "TL2_Panel", "CV2_Panel", "SM2_Panel", "TM2_Panel", "FR2_Panel" }
local OTHER_EDS = { "TE3_Rail", "TE3_Brush", "TE3_Mat", "TE3_Layers", "TE3_History", "TE3_Gen", "TE3_Water", "TE3_Status",
  "VP3_Rail", "VP3_Cam", "VP3_Trans", "VP3_Meas", "VP3_Snap", "VP3_Status", "MD4_Rail", "MD4_Mesh", "MD4_Vert", "MD4_Top", "MD4_IO", "MD4_Status",
  "AN5_Rail", "AN5_Rig", "AN5_Pose", "AN5_Time", "AN5_Keys", "AN5_IO", "AN5_Status", "UI6_Rail", "UI6_New", "UI6_Props", "UI6_Tree", "UI6_IO", "UI6_Status",
  "RW7_Rail", "RW7_Prof", "RW7_FX", "RW7_Sky", "RW7_World", "RW7_LOD", "RW7_Status", "DO8_Rail", "DO8_Stats", "DO8_Audit", "DO8_Opt", "DO8_Rel", "DO8_Mem", "DO8_Status",
  "WO9_Rail", "WO9_Info", "WO9_Grav", "WO9_Spawn", "WO9_Save", "WO9_Clean", "WO9_Status",
  "HO10_Rail", "HO10_File", "HO10_Tree", "HO10_Props", "HO10_Help", "HO10_Status",
  "PL12_Rail", "PL12_List", "PL12_New", "PL12_Cut", "PL12_Auto", "PL12_Status" }
local OTHER_M = { "M_TE", "M_VP", "M_MD", "M_AN", "M_UI", "M_RW", "M_DO", "M_WO", "M_HO", "M_PL" }
local S = { open = false, mode = "lua", scripts = {}, idx = 0,
  selId = nil, selName = "-", selClass = "-", chain = {},
  evCyc = 0, actCyc = 0, compiled = nil, logBuf = {}, errOnly = false }
local ACC = Color3.fromRGB(43, 139, 230)
local DIM = Color3.fromRGB(28, 42, 72)
local function platform()
  local ok, ai = pcall(function() return _G.ArkherInput end)
  if ok and ai and ai.platform then
    local ok2, p = pcall(ai.platform)
    if ok2 and p then return p end
  end
  return "PC"
end
local refreshList
local function showMode()
  vis("SC11_Edit", S.open and S.mode == "lua")
  vis("SC11_Py", S.open and S.mode == "py")
  vis("SC11_Blk", S.open and S.mode == "blk")
  local map = { lua = "SC11_M_Lua", py = "SC11_M_Py", blk = "SC11_M_Blk" }
  for m, n in pairs(map) do
    local o = find(n)
    if o then pcall(function() o.BackgroundColor3 = (S.mode == m) and ACC or DIM end) end
  end
end
local function setOpen(v)
  S.open = v
  for _, n in ipairs(PANELS) do vis(n, v) end
  for _, n in ipairs(DESK) do vis(n, not v) end
  if v then
    for _, n in ipairs(OTHER_EDS) do vis(n, false) end
    for _, n in ipairs(OTHER_M) do vis(n, false) end
    for _, ed in ipairs({ "ArkherTerrain", "ArkherViewport", "ArkherModeler", "ArkherAnimator", "ArkherUI", "ArkherRRW", "ArkherDo15", "ArkherWorld", "ArkherHome", "ArkherPlaces" }) do
      pcall(function()
        local e = _G[ed]
        if e and e.isOpen and e.isOpen() then e.close() end
      end)
    end
    vis("M_SC", platform() == "Mobile")
    showMode()
    refreshList()
    say("Script Studio open.")
  else
    vis("M_SC", false)
    say("Script Studio closed.")
  end
end
on("SC11_M_Lua", function() S.mode = "lua" showMode() end)
on("SC11_M_Py", function() S.mode = "py" showMode() end)
on("SC11_M_Blk", function() S.mode = "blk" showMode() end)

-- ============ list ============
local function showScript()
  local sc = S.scripts[S.idx]
  if not sc then
    setText("SC11_L_Info", "no scripts")
    return
  end
  setText("SC11_L_Info", string.format("%s · %s\n%d chars (%d/%d)",
    sc.name, sc.className, sc.len or 0, S.idx, #S.scripts))
end
refreshList = function()
  local r, err = api("ScriptList", {})
  if err then say("Scripts: " .. tostring(err), true) return end
  S.scripts = r.scripts or {}
  if S.idx > #S.scripts then S.idx = #S.scripts end
  if S.idx == 0 and #S.scripts > 0 then S.idx = 1 end
  showScript()
  setText("SC11_StatL", string.format("script · %d scripts", #S.scripts))
end
on("SC11_L_Prev", function()
  if #S.scripts == 0 then return end
  S.idx = ((S.idx - 2) % #S.scripts) + 1
  showScript()
end)
on("SC11_L_Next", function()
  if #S.scripts == 0 then return end
  S.idx = (S.idx % #S.scripts) + 1
  showScript()
end)
on("SC11_L_Load", function()
  local sc = S.scripts[S.idx]
  if not sc then say("Load: none.", true) return end
  local r, err = api("ScriptGet", { id = sc.id })
  if err then say("Load: " .. tostring(err), true) return end
  S.selId, S.selName, S.selClass = sc.id, sc.name, sc.className
  local box = find("SC11_E_Code")
  if box then pcall(function() box.Text = r.source or "" end) end
  setText("SC11_E_Info", string.format("%s · %d", sc.name, r.len or 0))
  S.mode = "lua"
  showMode()
  say("Loaded " .. sc.name .. ".")
end)
local function sssId()
  local snap, err = api("Snapshot", {})
  if err then return nil end
  for _, nd in ipairs(snap.nodes or {}) do
    if nd.class == "ServerScriptService" then return nd.id end
  end
  return nil
end
local function newScript(class)
  local pid = sssId()
  if not pid then say("New: ServerScriptService id missing.", true) return end
  local r, err = api("Create", { class = class, parentId = pid, name = class })
  if err then say("New: " .. tostring(err), true) return end
  S.selId = r.node.id
  S.selName, S.selClass = r.node.name, class
  say("Created " .. r.node.name .. " (disabled).")
  refreshList()
end
on("SC11_L_NewS", function() newScript("Script") end)
on("SC11_L_NewL", function() newScript("LocalScript") end)
on("SC11_L_NewM", function() newScript("ModuleScript") end)
on("SC11_L_Del", function()
  local sc = S.scripts[S.idx]
  if not sc then say("Del: none.", true) return end
  local r, err = api("Delete", { id = sc.id })
  if err then say("Del: " .. tostring(err), true) return end
  if S.selId == sc.id then S.selId, S.selName = nil, "-" end
  say("Deleted.")
  refreshList()
end)

-- ============ lua edit ============
on("SC11_E_Save", function()
  if not S.selId then say("Save: load first.", true) return end
  local src = ""
  pcall(function() src = find("SC11_E_Code").Text or "" end)
  local r, err = api("ScriptSet", { id = S.selId, source = src })
  if err then say("Save: " .. tostring(err), true) return end
  setText("SC11_E_Info", string.format("%s · %d saved", S.selName, r.len or 0))
  say("Saved.")
  refreshList()
end)
on("SC11_E_Run", function()
  if not S.selId then say("Run: load first.", true) return end
  local r, err = api("Set", { id = S.selId, key = "Enabled", value = true })
  if err then say("Run: " .. tostring(err), true) return end
  say(S.selName .. " running.")
end)
on("SC11_E_Stop", function()
  if not S.selId then say("Stop: load first.", true) return end
  local r, err = api("Set", { id = S.selId, key = "Enabled", value = false })
  if err then say("Stop: " .. tostring(err), true) return end
  say(S.selName .. " stopped.")
end)

-- ============ python subset -> luau (honesto: subset documentado) ============
local function pyCompile(src)
  local declared = {}
  local out = {}
  local stack = {}
  local ln = 0
  local function indentOf(s)
    local sp = s:match("^(%s*)") or ""
    sp = sp:gsub("\t", "    ")
    if #sp % 4 ~= 0 then return nil end
    return math.floor(#sp / 4)
  end
  local function expr(e)
    e = e:gsub("([^%w_])True([^%w_])", "%1true%2"):gsub("([^%w_])False([^%w_])", "%1false%2")
    e = e:gsub("([^%w_])None([^%w_])", "%1nil%2")
    e = e:gsub("^True([^%w_])", "true%1"):gsub("^False([^%w_])", "false%1"):gsub("^None([^%w_])", "nil%1")
    return e
  end
  for raw in (src .. "\n"):gmatch("([^\n]*)\n") do
    ln = ln + 1
    local line = raw:gsub("\r", "")
    if line:match("^%s*$") or line:match("^%s*#") then
      if line:match("^%s*#") then
        out[#out + 1] = string.rep("  ", #stack) .. "--" .. line:match("^%s*#(.*)")
      end
    else
      local ind = indentOf(line)
      if ind == nil then return nil, "linha " .. ln .. ": indent deve ser multiplo de 4." end
      local code = line:match("^%s*(.-)%s*$")
      if code:find("continue") then return nil, "linha " .. ln .. ": continue nao suportado." end
      local isElse = code:match("^elif%s") or code:match("^else%s*:%s*$")
      local target = isElse and (ind + 1) or ind
      while #stack > target do
        table.remove(stack)
        out[#out + 1] = string.rep("  ", #stack) .. "end"
      end
      if #stack < target then return nil, "linha " .. ln .. ": indent invalido." end
      local pad = string.rep("  ", #stack)
      local done = false
      local f, args = code:match("^def%s+([%w_]+)%s*%((.-)%)%s*:%s*$")
      if f then
        out[#out + 1] = pad .. "local function " .. f .. "(" .. (args or "") .. ")"
        stack[#stack + 1] = "def"
        done = true
      end
      if not done then
        local c = code:match("^if%s+(.-)%s*:%s*$")
        if c then out[#out + 1] = pad .. "if " .. expr(c) .. " then" stack[#stack + 1] = "if" done = true end
      end
      if not done then
        local c = code:match("^elif%s+(.-)%s*:%s*$")
        if c then
          if stack[#stack] ~= "if" then return nil, "linha " .. ln .. ": elif sem if." end
          out[#out + 1] = pad .. "elseif " .. expr(c) .. " then" done = true
        end
      end
      if not done and code:match("^else%s*:%s*$") then
        if stack[#stack] ~= "if" then return nil, "linha " .. ln .. ": else sem if." end
        out[#out + 1] = pad .. "else" done = true
      end
      if not done then
        local c = code:match("^while%s+(.-)%s*:%s*$")
        if c then out[#out + 1] = pad .. "while " .. expr(c) .. " do" stack[#stack + 1] = "while" done = true end
      end
      if not done then
        local v, a, b = code:match("^for%s+([%w_]+)%s+in%s+range%(%s*(.-)%s*,%s*(.-)%s*%)%s*:%s*$")
        if v then
          if a:find(",") or b:find(",") then return nil, "linha " .. ln .. ": range com step nao suportado." end
          out[#out + 1] = pad .. "for " .. v .. " = " .. a .. ", (" .. b .. ") - 1 do"
          stack[#stack + 1] = "for" done = true
        end
      end
      if not done then
        local v, n = code:match("^for%s+([%w_]+)%s+in%s+range%(%s*(.-)%s*%)%s*:%s*$")
        if v then
          if n:find(",") then return nil, "linha " .. ln .. ": range com step nao suportado." end
          local num = n:match("^%s*(%d+)%s*$")
          local stop = num and tostring(tonumber(num) - 1) or "(" .. n .. ") - 1"
          out[#out + 1] = pad .. "for " .. v .. " = 0, " .. stop .. " do"
          stack[#stack + 1] = "for" done = true
        end
      end
      if not done then
        local v, lst = code:match("^for%s+([%w_]+)%s+in%s+(.-)%s*:%s*$")
        if v then
          out[#out + 1] = pad .. "for _, " .. v .. " in ipairs(" .. expr(lst) .. ") do"
          stack[#stack + 1] = "for" done = true
        end
      end
      if not done then
        local r = code:match("^return%s*(.-)%s*$")
        if r ~= nil and code:match("^return") then
          out[#out + 1] = pad .. "return " .. expr(r) done = true
        end
      end
      if not done and code:match("^break%s*$") then out[#out + 1] = pad .. "break" done = true end
      if not done then
        local p = code:match("^print%s*%((.*)%)%s*$")
        if p ~= nil then out[#out + 1] = pad .. "print(" .. expr(p) .. ")" done = true end
      end
      if not done then
        local v, e = code:match("^([%w_]+)%s*=%s*(.+)$")
        if v and not code:match("==") then
          local pre = ""
          if not declared[v] then declared[v] = true pre = "local " end
          out[#out + 1] = pad .. pre .. v .. " = " .. expr(e) done = true
        end
      end
      if not done then return nil, "linha " .. ln .. ": nao suportado (" .. code:sub(1, 30) .. ")." end
    end
  end
  while #stack > 0 do
    table.remove(stack)
    out[#out + 1] = string.rep("  ", #stack) .. "end"
  end
  return table.concat(out, "\n")
end

-- ============ blocks -> luau ============
local BLK_EV = { "Touched", "Click", "PlayerAdded" }
local BLK_ACT = { "print", "color", "sound", "wait" }
local function blkActCode(kind, param)
  param = param or ""
  if kind == "print" then return 'print("' .. param:gsub('"', "'") .. '")' end
  if kind == "color" then
    local r, g, b = param:match("^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if not r then return nil, "color precisa r,g,b." end
    return "script.Parent.Color = Color3.fromRGB(" .. r .. ", " .. g .. ", " .. b .. ")"
  end
  if kind == "sound" then
    return 'local _s = script.Parent:FindFirstChildOfClass("Sound") if _s then _s:Play() end'
  end
  if kind == "wait" then
    local n = tonumber(param)
    if not n then return nil, "wait precisa numero." end
    return "task.wait(" .. n .. ")"
  end
  return nil, "acao desconhecida."
end
local function blkCompile(chain)
  if #chain == 0 then return nil, "chain vazia (adicione evento)." end
  if chain[1].t ~= "ev" then return nil, "bloco 1 precisa ser evento." end
  local ev = chain[1].kind
  local head, foot = "", "end)"
  if ev == "Touched" then head = "script.Parent.Touched:Connect(function(hit)"
  elseif ev == "Click" then head = 'script.Parent:WaitForChild("ClickDetector").MouseClick:Connect(function(plr)'
  elseif ev == "PlayerAdded" then head = 'game:GetService("Players").PlayerAdded:Connect(function(plr)'
  else return nil, "evento desconhecido." end
  local body = {}
  local i = 2
  while i <= #chain do
    local b = chain[i]
    if b.t == "if" then
      local cond = (b.cond or ""):match("^%s*(.-)%s*$")
      if cond == "" then return nil, "if sem condicao." end
      local nx = chain[i + 1]
      if not nx or nx.t ~= "act" then return nil, "if exige 1 acao depois." end
      local code, err = blkActCode(nx.kind, nx.param)
      if not code then return nil, err end
      body[#body + 1] = "  if " .. cond .. " then " .. code .. " end"
      i = i + 2
    elseif b.t == "act" then
      local code, err = blkActCode(b.kind, b.param)
      if not code then return nil, err end
      body[#body + 1] = "  " .. code
      i = i + 1
    else
      return nil, "evento so no bloco 1."
    end
  end
  if #body == 0 then return nil, "sem acoes." end
  return head .. "\n" .. table.concat(body, "\n") .. "\n" .. foot
end

-- ============ python UI ============
on("SC11_P_Comp", function()
  local src = ""
  pcall(function() src = find("SC11_P_Code").Text or "" end)
  if src == "" then say("Compile: empty.", true) return end
  local lua, err = pyCompile(src)
  if not lua then
    setText("SC11_P_Info", tostring(err):sub(1, 60))
    say("Py: " .. tostring(err), true)
    return
  end
  S.compiled = lua
  print("[ArkherPy]\n" .. lua)
  setText("SC11_P_Info", "ok (Output). SAVE writes it.")
  say("Py compiled (see Output).")
end)
local function saveCompiled(name)
  if not S.compiled then say("Save: compile first.", true) return end
  local target = S.selId
  if not target then
    local pid = sssId()
    if not pid then say("Save: SSS id missing.", true) return end
    local r, err = api("Create", { class = "Script", parentId = pid, name = name })
    if err then say("Save: " .. tostring(err), true) return end
    target = r.node.id
    S.selId, S.selName, S.selClass = target, r.node.name, "Script"
  end
  local r, err = api("ScriptSet", { id = target, source = S.compiled })
  if err then say("Save: " .. tostring(err), true) return end
  say("Saved compiled Lua.")
  refreshList()
end
on("SC11_P_Save", function() saveCompiled("PyOut") end)

-- ============ blocks UI ============
local function showChain()
  local parts = {}
  for _, b in ipairs(S.chain) do
    if b.t == "ev" then parts[#parts + 1] = "[" .. b.kind .. "]"
    elseif b.t == "act" then parts[#parts + 1] = b.kind .. "(" .. (b.param or "") .. ")"
    else parts[#parts + 1] = "if(" .. (b.cond or "?") .. ")" end
  end
  setText("SC11_B_Chain", "chain: " .. ((#parts > 0 and table.concat(parts, " > "):sub(1, 200)) or "(empty)"))
end
on("SC11_B_Ev", function()
  S.evCyc = (S.evCyc % #BLK_EV) + 1
  local kind = BLK_EV[S.evCyc]
  if #S.chain > 0 and S.chain[1].t == "ev" then S.chain[1] = { t = "ev", kind = kind }
  else table.insert(S.chain, 1, { t = "ev", kind = kind }) end
  showChain()
end)
on("SC11_B_Act", function()
  if #S.chain == 0 or S.chain[1].t ~= "ev" then say("Action: event first.", true) return end
  S.actCyc = (S.actCyc % #BLK_ACT) + 1
  local param = ""
  pcall(function() param = find("SC11_B_Param").Text or "" end)
  S.chain[#S.chain + 1] = { t = "act", kind = BLK_ACT[S.actCyc], param = param }
  showChain()
end)
on("SC11_B_If", function()
  if #S.chain == 0 or S.chain[1].t ~= "ev" then say("If: event first.", true) return end
  local cond = ""
  pcall(function() cond = find("SC11_B_Param").Text or "" end)
  S.chain[#S.chain + 1] = { t = "if", cond = cond }
  showChain()
  say("If wraps NEXT action.")
end)
on("SC11_B_Undo", function()
  table.remove(S.chain)
  showChain()
end)
on("SC11_B_Comp", function()
  local lua, err = blkCompile(S.chain)
  if not lua then
    setText("SC11_B_Info", tostring(err):sub(1, 60))
    say("Blocks: " .. tostring(err), true)
    return
  end
  S.compiled = lua
  print("[ArkherBlocks]\n" .. lua)
  setText("SC11_B_Info", "ok (Output). SAVE writes it.")
  say("Blocks compiled (see Output).")
end)
on("SC11_B_Save", function() saveCompiled("BlkOut") end)

-- ============ output console (LogService real) ============
local function renderLog()
  local lines = {}
  for i = math.max(1, #S.logBuf - 4), #S.logBuf do
    local e = S.logBuf[i]
    if not S.errOnly or e.err then lines[#lines + 1] = e.txt end
  end
  setText("SC11_O_Log", (#lines > 0 and table.concat(lines, "\n"):sub(1, 400)) or "(log)")
end
pcall(function()
  LogService.MessageOut:Connect(function(msg, mtype)
    local nm = "out"
    pcall(function() nm = mtype.Name or "out" end)
    local isErr = (nm == "MessageError" or nm == "MessageWarning")
    S.logBuf[#S.logBuf + 1] = { txt = "[" .. nm .. "] " .. tostring(msg):sub(1, 120), err = isErr }
    if #S.logBuf > 50 then table.remove(S.logBuf, 1) end
    if S.open then renderLog() end
  end)
end)
on("SC11_O_Clear", function()
  S.logBuf = {}
  pcall(function() LogService:ClearOutput() end)
  renderLog()
end)
on("SC11_O_Err", function()
  S.errOnly = not S.errOnly
  local o = find("SC11_O_Err")
  if o then pcall(function() o.BackgroundColor3 = S.errOnly and ACC or DIM end) end
  renderLog()
end)

-- ============ mobile ============
on("M_SC_Save", function()
  if not S.selId then say("Save: load first.", true) return end
  local src = ""
  if S.mode == "py" or S.mode == "blk" then
    if not S.compiled then say("Save: compile first.", true) return end
    src = S.compiled
  else
    pcall(function() src = find("SC11_E_Code").Text or "" end)
  end
  local r, err = api("ScriptSet", { id = S.selId, source = src })
  if err then say("Save: " .. tostring(err), true) return end
  say("Saved.")
end)
on("M_SC_Run", function()
  if not S.selId then say("Run: load first.", true) return end
  local r, err = api("Set", { id = S.selId, key = "Enabled", value = true })
  if err then say("Run: " .. tostring(err), true) return end
  say("Running.")
end)
on("M_SC_Stop", function()
  if not S.selId then say("Stop: load first.", true) return end
  local r, err = api("Set", { id = S.selId, key = "Enabled", value = false })
  if err then say("Stop: " .. tostring(err), true) return end
  say("Stopped.")
end)

-- ============ boot ============
showChain()
on("SC11_Close", function() setOpen(false) end)
rawset(_G, "ArkherScript", {
  open = function() setOpen(true) end,
  close = function() setOpen(false) end,
  isOpen = function() return S.open end,
  state = function() return S end,
  pyCompile = pyCompile,
  blkCompile = blkCompile,
})

