-- record_v2.lua — grava as 41 UIs do outro agente (studio-completo/v2src/*.lua)
-- executando os builders reais no mock. Produz _G.__V2 = {wins={NODE...}, warnings={}}.
-- Regras: pula ScreenGui (envelope), pula ArkherToast_*, pula UIGradient (sem
-- suporte no injector), força Visible=false nas raízes (menos StatusBar),
-- renomeia raiz p/ V2_<nome-da-gui>.
dofile("studio-completo/tools/mock.lua")

local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui

local GROUPS = {
  { file = "UI_CommandPalette", eds = { "Splash", "Login", "SaveOpen", "CommandPalette", "Settings", "StatusBar", "Search", "Documentation" } },
  { file = "UI_TerrainEditor", eds = { "ScriptEditor", "Console", "Debugger", "Profiler", "Timeline", "MaterialEditor", "TerrainEditor", "AnimationEditor", "ParticleEditor", "VFXEditor" } },
  { file = "UI_AudioEditor", eds = { "AudioEditor", "PhysicsEditor", "NavigationEditor", "AIEditor", "WorldEditor", "UIEditor", "ShaderEditor", "VisualScripting", "NodeEditor", "GraphEditor", "UTSAI" } },
  { file = "UI_Toolbox", eds = { "ProjectSettings", "BuildSettings", "PackageManager", "PluginManager", "VersionControl", "Collaboration", "Localization", "DataManager", "Toolbox", "UndoRedo", "Layouts", "NotificationsCenter" } },
}

for _, g in ipairs(GROUPS) do
  local src = io.open("studio-completo/v2src/" .. g.file .. ".lua"):read("*a")
  -- troca o driver final (ARKHER_REG.X()) por loop ordenado sobre todos os editores
  local tailcall = src:match("ARKHER_REG%.[A-Za-z0-9_]+%(%)%s*$")
  assert(tailcall, "driver final nao achado em " .. g.file)
  local names = {}
  for _, n in ipairs(g.eds) do names[#names + 1] = string.format("%q", n) end
  local driver = "do for _,_n in ipairs({" .. table.concat(names, ",") .. "}) do "
    .. "local _f = ARKHER_REG[_n] if _f then local _ok,_err = pcall(_f) "
    .. "print(((_ok and '[v2][ok] ') or '[v2][ERR] ').._n..(_ok and '' or (': '..tostring(_err)))) "
    .. "else print('[v2][AUSENTE] '.._n) end end end"
  src = src:gsub("ARKHER_REG%.[A-Za-z0-9_]+%(%)%s*$", driver)
  assert(loadstring(src, "[" .. g.file .. "]"))()
  print("[v2] grupo " .. g.file .. " ok")
end

-- ---------- serializador (mesmo formato do record_guix) ----------
local SKIP = { Parent = true, ClassName = true, AbsoluteSize = true, AbsolutePosition = true,
  AbsoluteRotation = true, CFrame = true }
local SKIPCLS = { UIGradient = true }
local WARNINGS = {}
local skippedGrad, skippedToast = 0, 0
local function encVal(v, path, key)
  local t = type(v)
  if t == "string" or t == "boolean" or t == "number" then return v end
  if t ~= "table" then WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=badtype:" .. t return nil end
  local tag = rawget(v, "__t")
  if tag == "Color3" then return { "C3", v.R, v.G, v.B } end
  if tag == "UDim2" then return { "U2", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } end
  if tag == "UDim" then return { "U1", v.Scale, v.Offset } end
  if tag == "Vector2" then return { "V2", v.X, v.Y } end
  if tag == "Vector3" then WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=Vector3-3D!" return nil end
  local nm = rawget(v, "__name")
  if type(nm) == "string" and nm:sub(1, 5) == "Enum." then return { "EN", nm:sub(6) } end
  WARNINGS[#WARNINGS + 1] = path .. " " .. key .. "=badtable:" .. tostring(tag or nm) return nil
end
local function dumpNode(o, path)
  local props = rawget(o, "__props")
  local expl = rawget(o, "__explicit")
  local cls = props.ClassName
  local p = path .. "/" .. tostring(props.Name)
  local pd = {}
  for k in pairs(expl) do
    if not SKIP[k] then
      local e = encVal(props[k], p, k)
      if e ~= nil then pd[k] = e end
    end
  end
  local kd = {}
  for _, ch in ipairs(rawget(o, "__children")) do
    if SKIPCLS[rawget(ch, "__props").ClassName] then
      skippedGrad = skippedGrad + 1
    else
      kd[#kd + 1] = dumpNode(ch, p)
    end
  end
  return { "NODE", cls, tostring(props.Name), pd, kd }
end

local wins = {}
for _, sg in ipairs(starterGui:GetChildren()) do
  local nm = rawget(sg, "__props").Name
  if rawget(sg, "__props").ClassName == "ScreenGui" and nm ~= "ArkherStudioUI" then
    if nm:sub(1, 12) == "ArkherToast_" then
      skippedToast = skippedToast + 1
    else
      local kids = sg:GetChildren()
      for i, ch in ipairs(kids) do
        local rootNm = "V2_" .. nm .. (#kids > 1 and ("_" .. i) or "")
        -- raiz começa fechada (menos StatusBar); rename estável
        if nm ~= "ArkherStatusBar" then ch.Visible = false end
        ch.Name = rootNm
        wins[#wins + 1] = dumpNode(ch, "")
        print("[v2] janela " .. rootNm .. " [" .. rawget(ch, "__props").ClassName .. "]")
      end
    end
  end
end
print("[v2] janelas=" .. #wins .. " gradients_pulados=" .. skippedGrad .. " toasts_pulados=" .. skippedToast)
_G.__V2 = { wins = wins, warnings = WARNINGS }
print("[v2] SPEC pronta: warnings=" .. #WARNINGS)
