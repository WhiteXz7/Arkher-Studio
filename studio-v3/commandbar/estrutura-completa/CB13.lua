--[[ =====================================================================
  ARKHER V3 — ESTRUTURA COMPLETA (13/13)
  Assembler do ALL
  Cria: StarterPlayerScripts.Arkher.ArkherALL_Assemble (LocalScript desativado)
  Uso: View > Command Bar > cole TODO este texto > Run
  Idempotente: pode rodar de novo (apenas atualiza o Source)
====================================================================== ]]
local spps = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
local arkher = spps:FindFirstChild("Arkher")
if not arkher then arkher = Instance.new("Folder") arkher.Name = "Arkher" arkher.Parent = spps end
local S_ASM = [====[--[[ ARKHER V3 — ArkherStudio_ALL (251KB) reconstituido dos 3 chunks.
     HABILITE este LocalScript e aperte F5 para rodar o ALL completo. ]]
local ok, err = pcall(function()
	local all = game:WaitForChild("ReplicatedStorage"):WaitForChild("ArkherV3"):WaitForChild("ALL")
	local src = require(all:WaitForChild("ALL_P1"))
		.. require(all:WaitForChild("ALL_P2"))
		.. require(all:WaitForChild("ALL_P3"))
	local fn = loadstring(src)
	if not fn then error("loadstring falhou no ALL") end
	fn()
end)
if not ok then
	warn("[ARKHER V3] ArkherStudio_ALL falhou:", err)
else
	print("[ARKHER V3] ArkherStudio_ALL (251KB) executado a partir dos 3 chunks")
end
]====]
local t = arkher:FindFirstChild("ArkherALL_Assemble")
if not t then t = Instance.new("LocalScript") t.Name = "ArkherALL_Assemble" t.Parent = arkher end
t.Source = S_ASM
	t.Disabled = true
print("[ARKHER V3] (13/13) ArkherALL_Assemble pronto (desativado). Estrutura COMPLETA criada!")
