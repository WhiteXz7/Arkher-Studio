--[[ ARKHER V3 — UNDO/REDO: pilha real de snapshots do workspace ]]
-- Registro de comandos: cada acao editavel chama ARKHER.cmd("undo.push", label)
-- antes de modificar o mundo. Limite: 50 niveis (D-O15 escala com mem).
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local workspace = game:FindFirstChild("Workspace") or game:FindFirstChild("workspace")

local U = {}
ArkherUNDO = U

local MAX = 50
local stack = { _undo = {}, _redo = {} }
local reentrant = false -- P.apply chama undo.push; sem o guard isso limparia o redo

local function snapshotWorkspace()
	local Http = game:GetService("HttpService")
	local data = ArkherPlaces and ArkherPlaces.snapshot()
	if data then
		return Http:JSONEncode(data)
	end
	return nil
end

function U.push(label)
	if not workspace then return end
	if reentrant then return end
	local json = snapshotWorkspace()
	if not json then return end
	table.insert(stack._undo, { label = label or "Edit", json = json, t = tick() })
	if #stack._undo > MAX then table.remove(stack._undo, 1) end
	stack._redo = {}
	Bus.emit("undo.state", U.status())
end

function U.canUndo() return #stack._undo > 0 end
function U.canRedo() return #stack._redo > 0 end

function U.status()
	return { undo = #stack._undo, redo = #stack._redo, last = stack._undo[#stack._undo] and stack._undo[#stack._undo].label or "" }
end

function U.undo()
	local top = table.remove(stack._undo)
	if not top then
		ARKHER.out("INFO", "Undo: nada para desfazer")
		return false
	end
	local current = snapshotWorkspace()
	if current then
		table.insert(stack._redo, { label = top.label, json = current, t = tick() })
	end
	local Http = game:GetService("HttpService")
	local ok, data = pcall(function() return Http:JSONDecode(top.json) end)
	if ok and data and ArkherPlaces then
		reentrant = true
		ArkherPlaces.apply(data)
		reentrant = false
		ARKHER.out("INFO", "Undo: " .. tostring(top.label))
	else
		ARKHER.out("ERROR", "Undo: snapshot corrompido")
	end
	Bus.emit("undo.state", U.status())
	return true
end

function U.redo()
	local top = table.remove(stack._redo)
	if not top then
		ARKHER.out("INFO", "Redo: nada para refazer")
		return false
	end
	local current = snapshotWorkspace()
	if current then
		table.insert(stack._undo, { label = top.label, json = current, t = tick() })
	end
	local Http = game:GetService("HttpService")
	local ok, data = pcall(function() return Http:JSONDecode(top.json) end)
	if ok and data and ArkherPlaces then
		reentrant = true
		ArkherPlaces.apply(data)
		reentrant = false
		ARKHER.out("INFO", "Redo: " .. tostring(top.label))
	else
		ARKHER.out("ERROR", "Redo: snapshot corrompido")
	end
	Bus.emit("undo.state", U.status())
	return true
end

function U.clear()
	stack._undo = {}
	stack._redo = {}
	Bus.emit("undo.state", U.status())
end
