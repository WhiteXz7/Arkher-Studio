--[[ ARKHER V3 — DRIVER: boot completo (sistemas + shell + todas as UIs) ]]
-- Ordem: prelude → core → actions → boot → main shell → UIs em cascata.
do
	ARKHER.boot()
	pcall(function() ARKHER_BUILD_MAIN() end)
	local opened = ARKHER.openAll()
	ARKHER.out("SUCCESS", string.format("ARKHER V3 pronto: %d UIs ativas + core (places/do15/nmn/singularity/undo/live/publish)", opened))
end
