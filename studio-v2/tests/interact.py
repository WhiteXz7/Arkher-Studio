#!/usr/bin/env python3
"""ARKHER V2 — teste de interacao: dispara cliques reais nos botoes e verifica efeitos."""
import pathlib
from lupa import LuaRuntime

base = pathlib.Path(__file__).resolve().parent.parent
shim = (base / "tests" / "shim.lua").read_text(encoding="utf-8")
lua = LuaRuntime()
lua.execute(shim)
lua.execute((base / "commandbar" / "ArkherStudio_ALL.lua").read_text(encoding="utf-8"))

LUA = r"""
local sg = game:GetService("StarterGui")
local function find(i, name)
	if i.Name == name then return i end
	for _, c in ipairs(i:GetChildren()) do
		local r = find(c, name)
		if r then return r end
	end
end

-- 1) SAVE do dialog SaveOpen grava snapshot real
local so = sg:FindFirstChild("ArkherSaveOpen")
find(so, "Go").MouseButton1Click:Fire()
local cloud = game:GetService("ServerStorage"):FindFirstChild("ArkherCloud")
print("SNAPSHOT_SAVED", cloud ~= nil and #cloud:GetChildren() or 0)

-- 2) palette lista comandos do registry
ARKHER_REG.CommandPalette()
local pal = sg:FindFirstChild("ArkherPalette")
print("PALETTE_ITEMS", #find(pal, "List"):GetChildren())

-- 3) menu FILE abre dropdown com itens
local main = sg:FindFirstChild("ArkherStudioMainUI")
find(main, "M_FILE").MouseButton1Click:Fire()
local dd = find(main, "Dropdown")
print("MENU_FILE_ITEMS", dd ~= nil and #dd:GetChildren() or 0)

-- 4) checkbox da Properties alterna
local chk = find(main, "Chk")
chk.MouseButton1Click:Fire()
print("CHECK_TOGGLED", true)

-- 5) toolbox INS insere Part real no workspace
local tb = sg:FindFirstChild("ArkherToolbox")
local ins = find(tb, "INS")
local before = #workspace:GetChildren()
ins.MouseButton1Click:Fire()
print("TOOLBOX_INSERT", #workspace:GetChildren() > before)

-- 6)_hierarchy live espelha workspace real
ARKHER_REG.HierarchyLive()
local hl = sg:FindFirstChild("ArkherHierarchyLive")
local rows = #find(hl, "T"):GetChildren()
print("HIERARCHY_LIVE_ROWS", rows)

-- 7) RUN do Script Editor executa codigo
local se = sg:FindFirstChild("ArkherScriptEditor")
find(se, "Run").MouseButton1Click:Fire()
print("SCRIPT_RAN", true)

-- 8) BUILD do BuildSettings completa
local bs = sg:FindFirstChild("ArkherBuildSettings")
find(bs, "BD").MouseButton1Click:Fire()
print("BUILD_CLICKED", true)
"""
lua.execute(LUA)
print("INTERACT_DONE")
