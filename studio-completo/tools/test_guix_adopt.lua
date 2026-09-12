-- Teste GUIX: adoção (scripts reusam a GUI estática, zero duplicata) + fiação 05/06/07/09.
dofile("studio-completo/tools/mock.lua")

local pass, fail = 0, 0
local function check(cond, msg)
  if cond then pass = pass + 1 print("  OK  " .. msg)
  else fail = fail + 1 print("  FALHOU  " .. msg) end
end

-- loops de monitor morrem em silêncio após o orçamento
local waits, stops = 0, 0
task.wait = function(t)
  waits = waits + 1
  if waits > 500 then error("__REC_STOP__", 0) end
  return nil
end
local _warn = warn
warn = function(m) if tostring(m):find("__REC_STOP__") then stops = stops + 1 else _warn(m) end end

-- ---------- ambiente ----------
local starterGui = game:GetService("StarterGui")
local gui = Instance.new("ScreenGui"); gui.Name = "ArkherStudioUI"; gui.Parent = starterGui
local canvas = Instance.new("Frame"); canvas.Name = "Canvas"; canvas.Parent = gui
local scale = Instance.new("UIScale"); scale.Name = "ResponsiveScale"; scale.Parent = canvas
local runtime = Instance.new("Folder"); runtime.Name = "ArkherServerClientRuntime"; runtime.Parent = gui
local NOSEL = { none = true, msg = "Nada selecionado — clique num objeto no EXPLORADOR." }
local messages, apiCalls = {}, {}
local clientBus = Instance.new("BindableFunction"); clientBus.Name = "ClientBus"; clientBus.Parent = runtime
clientBus.OnInvoke = function(action, payload)
  if action == "ClaimPart" then return true end
  if action == "Message" then messages[#messages + 1] = tostring(payload.text) return true end
  if action == "API" then
    apiCalls[#apiCalls + 1] = payload.action
    if payload.action == "SelectedGet" or payload.action == "PropsAll" then
      return { result = NOSEL }
    end
    return { result = { msg = "ok (" .. tostring(payload.action) .. ")" } }
  end
  return true
end
local ready = Instance.new("BoolValue"); ready.Name = "CoreReady"; ready.Value = true; ready.Parent = runtime
local directBus = Instance.new("BindableFunction"); directBus.Name = "ClientBus"; directBus.Parent = gui
directBus.OnInvoke = clientBus.OnInvoke
local rs = game:GetService("ReplicatedStorage")
local net = Instance.new("Folder"); net.Name = "ArkherNet"; net.Parent = rs
local netFn = Instance.new("RemoteFunction"); netFn.Name = "ArkherXQ"; netFn.Parent = net
local netCalls = {}
netFn.InvokeServer = function(self, arg)
  netCalls[#netCalls + 1] = arg.op
  if arg.op == "bench_stats" then return { verts = 0, faces = 0, ops = 0, msg = "banca vazia" } end
  if arg.op == "mesh_tools" or arg.op == "world_tools" then return { tools = {}, count = 0 } end
  return { msg = arg.op .. " ok (teste)" }
end
local ls = game:GetService("LogService")
ls.GetLogHistory = function(self) return {} end
ls.ClearOutput = function(self) end

local function loadClient(path, nm)
  local src = io.open(path):read("*a")
  local fn, err = loadstring(src, "[" .. nm .. "]")
  assert(fn, "sintaxe " .. nm .. ": " .. tostring(err))
  script = Instance.new("LocalScript"); script.Name = nm; script.Parent = gui
  -- LocalScripts somem do gui (só poluem o census)
  local ok, run = pcall(fn)
  check(ok, nm .. " executou" .. (ok and "" or (" err=" .. tostring(run))))
  script.Parent = nil
  return ok
end

local function census()
  local c = {}
  local function walk(o)
    for _, ch in ipairs(o:GetChildren()) do
      local cls = ch.ClassName
      c[cls] = (c[cls] or 0) + 1
      walk(ch)
    end
  end
  walk(canvas)
  return c
end
local function same(a, b)
  for k, v in pairs(a) do if b[k] ~= v then return false, k .. ":" .. v .. "!=" .. tostring(b[k]) end end
  for k, v in pairs(b) do if a[k] ~= v then return false, k .. ":" .. tostring(a[k]) .. "!=" .. v end end
  return true
end
local function total(c) local t = 0 for _, v in pairs(c) do t = t + v end return t end

print("\n== 08 create-path (canvas vazio) ==")
check(loadClient("studio-completo/scripts/08_RealityX.lua", "Arkher_08_RealityX"), "08 #1 ok")
local host = canvas:FindFirstChild("ArkherXDeck")
check(host ~= nil, "host ArkherXDeck criado (fallback)")
local wins = 0
if host then for _, ch in ipairs(host:GetChildren()) do if ch.Name:sub(1, 5) == "Deck_" then wins = wins + 1 end end end
check(wins == 23, "23 janelas Deck_* (" .. wins .. ")")
check(rawget(_G, "ArkherDeck") ~= nil, "_G.ArkherDeck exposto")
local S1 = census()
print("   census #1 total=" .. total(S1))

print("\n== 08 adopt-path (recarrega sobre a GUI pronta) ==")
check(loadClient("studio-completo/scripts/08_RealityX.lua", "Arkher_08_RealityX"), "08 #2 ok")
local S2 = census()
local ok2, diff2 = same(S1, S2)
check(ok2, "2o load NÃO duplica nada" .. (ok2 and (" (" .. total(S2) .. " inst)") or (" diff=" .. diff2)))

print("\n== estáticas launcher/rig/mesh + XBar/popups ==")
local GuixStatic = assert(loadstring(io.open("studio-completo/tools/guix_static.lua"):read("*a"), "[guix_static]"))()
GuixStatic.buildXBar(host)
GuixStatic.buildPopups(host)
GuixStatic.buildLauncher(host)
GuixStatic.buildRig(host)
GuixStatic.buildMesh(host)
local S3 = census()
print("   census #3 total=" .. total(S3))

print("\n== 05 fiação (zero novas) ==")
check(loadClient("studio-completo/scripts/05_StudioX.lua", "Arkher_05_StudioX"), "05 ok")
local S4 = census()
local ok4, diff4 = same(S3, S4)
check(ok4, "05 cria ZERO instâncias" .. (ok4 and "" or (" diff=" .. diff4)))
check(rawget(_G, "ArkherStudioX") ~= nil, "_G.ArkherStudioX exposto")
local launcher = host:FindFirstChild("Deck_launcher")
local lrow = launcher and launcher:FindFirstChild("Body"):FindFirstChild("List"):FindFirstChild("Launch_terrain")
if lrow then
  launcher.Visible = true
  lrow.MouseButton1Click:Fire()
  check(host:FindFirstChild("Deck_terrain").Visible == true, "Launch_terrain abre o Terrain")
  check(launcher.Visible == false, "launcher esconde (start-menu)")
end
local rrow = launcher and launcher:FindFirstChild("Body"):FindFirstChild("List"):FindFirstChild("Launch_rig")
if rrow then
  launcher.Visible = true
  rrow.MouseButton1Click:Fire()
  check(host:FindFirstChild("Deck_rig").Visible == true, "Launch_rig abre o Rig")
end

print("\n== 06/07 fiação (zero novas) ==")
check(loadClient("studio-completo/scripts/06_RigX.lua", "Arkher_06_RigX"), "06 ok")
check(loadClient("studio-completo/scripts/07_MeshX.lua", "Arkher_07_MeshX"), "07 ok")
local S5 = census()
local ok5, diff5 = same(S4, S5)
check(ok5, "06/07 criam ZERO instâncias" .. (ok5 and "" or (" diff=" .. diff5)))
local rigBody = host:FindFirstChild("Deck_rig"):FindFirstChild("Body")
local demo = rigBody:FindFirstChild("RigBtn_Demo")
if demo then
  demo.MouseButton1Click:Fire()
  check(netCalls[#netCalls] == "rig_demo", "RigBtn_Demo chama rig_demo")
  check(rigBody:FindFirstChild("RigStatus").Text:sub(1, 4) == "✓ ", "status ✓ (" .. rigBody:FindFirstChild("RigStatus").Text .. ")")
end
local meshBody = host:FindFirstChild("Deck_mesh"):FindFirstChild("Body")
local house = meshBody:FindFirstChild("MeshBtn_House")
if house then
  house.MouseButton1Click:Fire()
  check(netCalls[#netCalls] == "mesh_house", "MeshBtn_House chama mesh_house")
end

print("\n== 09 fiação (zero novas) ==")
check(loadClient("studio-completo/scripts/09_Topbar.lua", "Arkher_09_Topbar"), "09 ok")
local S6 = census()
local ok6, diff6 = same(S5, S6)
check(ok6, "09 cria ZERO instâncias" .. (ok6 and "" or (" diff=" .. diff6)))
local bar = host:FindFirstChild("ArkherXBar")
local nBtn = 0
if bar then for _, ch in ipairs(bar:GetChildren()) do if ch:IsA("TextButton") then nBtn = nBtn + 1 end end end
check(nBtn == 6, "XBar tem 6 botões (" .. nBtn .. ")")
local part = bar and bar:FindFirstChild("ArkherX_Part")
local shapes = host:FindFirstChild("ServerEditorPopups"):FindFirstChild("ArkherShapesPopup")
if part and shapes then
  part.Activated:Fire()
  check(shapes.Visible == true, "PART ▸ mostra o popup")
  local brow = shapes:FindFirstChild("ShapeRow_Block")
  if brow then
    local n0 = #apiCalls
    brow.Activated:Fire()
    check(apiCalls[n0 + 1] == "QuickPart", "ShapeRow_Block chama QuickPart")
    check(shapes.Visible == false, "popup esconde após spawn")
  end
end

print("\n================================")
print("ADOPT: " .. pass .. " passaram, " .. fail .. " falharam (loops mortos: " .. stops .. ")")
if fail > 0 then os.exit(1) end
