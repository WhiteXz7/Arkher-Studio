--[[ ARKHER V3 — BOOT: inicializa os sistemas core (idempotente) ]]
function ARKHER.boot()
	if ARKHER._booted then return end
	ARKHER._booted = true
	ArkherDO15.start()
	ArkherNMN.start()
	ArkherLive.start()
	ArkherActions.registerUICommands()
	ArkherActions.startShortcuts()
	pcall(function() ArkherPlaces.refreshList() end)
	ARKHER.out("INFO", "Core boot: do15 + nmn + live + actions + places")
end
