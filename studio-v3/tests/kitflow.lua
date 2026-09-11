-- ARKHER V4 — KITFLOW: simula o fluxo REAL de instalacao no Roblox
-- (4 ModuleScripts em ReplicatedStorage.ArkherV3 + LocalScripts que requerem).
-- Recebe via varargs: kitASrc, kitBSrc, kitCSrc, kitDSrc, mainUiSrc, bundleSrc, uiSrc
local function check(name, cond, extra)
	if cond then
		print("PASS " .. name)
	else
		print("FAIL " .. name .. (extra and (" — " .. tostring(extra)) or ""))
	end
end

local kitASrc = select(1, ...)
local kitBSrc = select(2, ...)
local kitCSrc = select(3, ...)
local kitDSrc = select(4, ...)
local kitESrc = select(5, ...)
local mainUiSrc = select(6, ...)
local bundleSrc = select(7, ...)
local uiSrc = select(8, ...)

-- 1) installers: criam os 5 ModuleScripts
local rs = game:GetService("ReplicatedStorage")
local folder = rs:FindFirstChild("ArkherV3")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "ArkherV3"
	folder.Parent = rs
end
local mA = Instance.new("ModuleScript")
mA.Name = "ArkherKit_A"
mA.Source = kitASrc
mA.Parent = folder
local mB = Instance.new("ModuleScript")
mB.Name = "ArkherKit_B"
mB.Source = kitBSrc
mB.Parent = folder
local mC = Instance.new("ModuleScript")
mC.Name = "ArkherKit_C"
mC.Source = kitCSrc
mC.Parent = folder
local mD = Instance.new("ModuleScript")
mD.Name = "ArkherKit_D"
mD.Source = kitDSrc
mD.Parent = folder
local mE = Instance.new("ModuleScript")
mE.Name = "ArkherKit_E"
mE.Source = kitESrc
mE.Parent = folder
check("kitflow: 5 ModuleScripts criados", mA.Parent == folder and mB.Parent == folder and mC.Parent == folder and mD.Parent == folder and mE.Parent == folder)

-- 1b) Kit C/D/E podem ser requeridos standalone (eles carregam o Kit A sozinhos)
require(mC)
check("kitflow: Kit C standalone (ATX+AWX ativos)", ArkherTerrainX ~= nil and ArkherWaterX ~= nil)
require(mD)
check("kitflow: Kit D standalone (SX+AXI ativos)", ArkherScripterX ~= nil and ArkherUIKitX ~= nil)
require(mE)
check("kitflow: Kit E standalone (AAX+AUX+ASXN+AEX+ACX+APX ativos)", ArkherAnimX ~= nil and ArkherAudioX ~= nil and ArkherSceneX ~= nil and ArkherAtmosX ~= nil and ArkherCameraX ~= nil and ArkherParticlesX ~= nil)

-- 2) LocalScript: MainUI (shell)
local okM, errM = pcall(function() loadstring(mainUiSrc, "[MainUI]")() end)
check("kitflow: MainUI executou", okM, errM)
check("kitflow: ARKHER ativo via require", ARKHER ~= nil and ARKHER._booted == true)
check("kitflow: shell montado no CoreGui", (function()
	local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
	return fg ~= nil and fg:FindFirstChild("ArkherStudioMainUI") ~= nil
end)())

-- 3) LocalScript: Bundle Editors (6 UIs: animator modeler terrain water particles scatter)
local okB, errB = pcall(function() loadstring(bundleSrc, "[BundleEditors]")() end)
check("kitflow: Bundle Editors executou", okB, errB)
check("kitflow: 6+ UIs registradas", #ARKHER.listUIs() >= 6, #ARKHER.listUIs())
check("kitflow: WATER registrada no bundle", (function()
	for _, nm in ipairs(ARKHER.listUIs()) do
		if nm == "Water" then return true end
	end
	return false
end)())
check("kitflow: SCATTER registrada no bundle", (function()
	for _, nm in ipairs(ARKHER.listUIs()) do
		if nm == "Scatter" then return true end
	end
	return false
end)())
local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
local n = 0
if fg then
	for _, ch in ipairs(fg:GetChildren()) do
		if ch:FindFirstChild("Root") then n = n + 1 end
	end
end
check("kitflow: janelas no CoreGui (shell + 6 UIs)", n >= 7, n)

-- 4) require com cache (2o require nao re-executa)
local before = #ARKHER.OUTPUT
require(mB)
check("kitflow: require com cache (sem re-execucao)", #ARKHER.OUTPUT == before)

-- 5) launcher de UI individual (so 1 UI)
local okI, errI = pcall(function()
	if uiSrc then loadstring(uiSrc, "[UIAnima]")() end
end)
check("kitflow: UI individual executou", okI, errI)

print("KITFLOW_DONE")
