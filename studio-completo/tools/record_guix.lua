-- record_guix.lua — grava a GUI X estática executando os builders reais no mock.
-- Uso: via record_guix.py (lupa). Produz _G.__SPEC (árvores posicionais).
dofile("studio-completo/tools/mock.lua")

-- ---------- quebra de loops de monitor (while win.root.Parent) ----------
local waits = 0
task.wait = function(t)
  waits = waits + 1
  if waits > 15 then error("__REC_STOP__", 0) end
  return nil
end

-- ---------- ambiente falso ----------
local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
local NOSEL = { none = true, msg = "Nada selecionado — clique num objeto no EXPLORADOR." }
clientBus.OnInvoke = function(action, payload)
  if action == "ClaimPart" then return true end
  if action == "API" then return { result = NOSEL } end
  return true
end
-- caminho direto (08 atual procura ClientBus direto; provê os dois)
local directBus = Instance.new("BindableFunction"); directBus.Name = "ClientBus"; directBus.Parent = gui
directBus.OnInvoke = function(action, payload)
  if action == "ClaimPart" then return true end
  if action == "API" then return { result = NOSEL } end
  return true
end
local ls = game:GetService("LogService")
ls.GetLogHistory = function(self) return {} end
ls.ClearOutput = function(self) end
-- ponte ArkherNet (vazia-honesta: mesmas chaves do servidor real, zero itens)
local rs = game:GetService("ReplicatedStorage")
local net = Instance.new("Folder"); net.Name = "ArkherNet"; net.Parent = rs
local netFn = Instance.new("RemoteFunction"); netFn.Name = "ArkherXQ"; netFn.Parent = net
local NET_EMPTY = {
  bench_stats = { verts = 0, faces = 0, ops = 0, msg = "banca vazia" },
  mesh_tools = { tools = {}, count = 0 },
  world_tools = { tools = {}, count = 0 },
}
netFn.InvokeServer = function(self, arg)
  local op = type(arg) == "table" and arg.op or nil
  return NET_EMPTY[op] or { msg = "—" }
end

script = Instance.new("LocalScript"); script.Name = "Arkher_08_RealityX"; script.Parent = gui

-- ---------- raízes OUT (alvos do mapeamento) ----------
local OUT = Instance.new("Folder"); OUT.Name = "OUT"
local OUT_XBar = Instance.new("Frame"); OUT_XBar.Name = "OUT_XBar"; OUT_XBar.Parent = OUT
local OUT_Popups = Instance.new("Frame"); OUT_Popups.Name = "OUT_Popups"; OUT_Popups.Parent = OUT
local OUT_Deck = Instance.new("Frame"); OUT_Deck.Name = "OUT_Deck"; OUT_Deck.Parent = OUT

-- ---------- carrega os builders REAIS ----------
local src08 = io.open("studio-completo/scripts/08_RealityX.lua"):read("*a")
assert(loadstring(src08, "[08]"))()
print("[record] 08 carregado")

local srcS = io.open("studio-completo/tools/guix_static.lua"):read("*a")
local GuixStatic = assert(loadstring(srcS, "[guix_static]"))()
GuixStatic.buildXBar(OUT_XBar)
GuixStatic.buildPopups(OUT_Popups)
GuixStatic.buildLauncher(OUT_Deck)
GuixStatic.buildRig(OUT_Deck)
GuixStatic.buildMesh(OUT_Deck)
print("[record] static ok")

-- ---------- serializador posicional ----------
local SKIP = { Parent = true, ClassName = true, AbsoluteSize = true, AbsolutePosition = true,
  AbsoluteRotation = true, CFrame = true }
local WARNINGS = {}
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
  for _, ch in ipairs(rawget(o, "__children")) do kd[#kd + 1] = dumpNode(ch, p) end
  return { "NODE", cls, tostring(props.Name), pd, kd }
end

local deck = canvas:FindFirstChild("ArkherXDeck")
assert(deck, "ArkherXDeck nao construído (host ausente no Canvas)")
_G.__SPEC = {
  deck = dumpNode(deck, ""),
  xbar = dumpNode(OUT_XBar, ""),
  popups = dumpNode(OUT_Popups, ""),
  extra = dumpNode(OUT_Deck, ""),
  warnings = WARNINGS,
}
print("[record] SPEC pronta: warnings=" .. #WARNINGS)
for _, w in ipairs(WARNINGS) do print("[record][warn] " .. w) end
