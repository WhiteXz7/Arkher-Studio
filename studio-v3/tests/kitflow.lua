-- ARKHER V3 — KITFLOW: simula o fluxo REAL de instalacao no Roblox
-- (2 ModuleScripts em ReplicatedStorage.ArkherV3 + LocalScripts que requerem).
-- Recebe via varargs: kitASrc, kitBSrc, mainUiSrc, bundleSrc
local function check(name, cond, extra)
	if cond then
		print("PASS " .. name)
	else
		print("FAIL " .. name .. (extra and (" — " .. tostring(extra)) or ""))
	end
end

local kitASrc = select(1, ...)
local kitBSrc = select(2, ...)
local mainUiSrc = select(3, ...)
local bundleSrc = select(4, ...)
local uiSrc = select(5, ...)

-- 1) installers: criam os ModuleScripts
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
check("kitflow: ModuleScripts criados", mA.Parent == folder and mB.Parent == folder)

-- 2) LocalScript: MainUI (shell)
local okM, errM = pcall(function() loadstring(mainUiSrc, "[MainUI]")() end)
check("kitflow: MainUI executou", okM, errM)
check("kitflow: ARKHER ativo via require", ARKHER ~= nil and ARKHER._booted == true)
check("kitflow: shell montado no CoreGui", (function()
	local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
	return fg ~= nil and fg:FindFirstChild("ArkherStudioMainUI") ~= nil
end)())

-- 3) LocalScript: Bundle Editors (5 UIs)
local okB, errB = pcall(function() loadstring(bundleSrc, "[BundleEditors]")() end)
check("kitflow: Bundle Editors executou", okB, errB)
check("kitflow: 5+ UIs registradas", #ARKHER.listUIs() >= 5, #ARKHER.listUIs())
local fg = game:GetService("CoreGui"):FindFirstChild("ArkherStudio")
local n = 0
if fg then
	for _, ch in ipairs(fg:GetChildren()) do
		if ch:FindFirstChild("Root") then n = n + 1 end
	end
end
check("kitflow: janelas no CoreGui (shell + 5 UIs)", n >= 6, n)

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
