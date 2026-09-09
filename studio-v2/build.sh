#!/bin/bash
# ARKHER V2 — gera os scripts coláveis no Command Bar a partir de src/
set -e
cd "$(dirname "$0")"
SRC=src
DIST=commandbar
mkdir -p "$DIST"

echo "== build: main (a print) =="
cat $SRC/prelude.luau $SRC/body_main.luau > $DIST/ArkherStudio_MainUI.lua

echo "== build: ALL (todas as UIs + sistemas) =="
{
  cat $SRC/prelude.luau $SRC/body_systems.luau $SRC/ed_a.luau $SRC/ed_b.luau $SRC/ed_c.luau $SRC/ed_d.luau $SRC/body_main.luau
  echo ""
  echo "-- ===== DRIVER: monta todas as UIs ====="
  echo "pcall(function() ARKHER_REG.StatusBar() end)"
  echo "ARKHER.openAll()"
} > $DIST/ArkherStudio_ALL.lua

echo "== build: systems =="
{
  cat $SRC/prelude.luau $SRC/body_systems.luau
  echo "ARKHER_REG.InspectorLive()"
  echo "ARKHER_REG.HierarchyLive()"
} > $DIST/ArkherSystems.lua

echo "== build: UIs individuais =="
for f in ed_a ed_b ed_c ed_d; do
  for b in $(grep -oE "^ARKHER_REG\.[A-Za-z]+" $SRC/$f.luau | sed 's/ARKHER_REG\.//'); do
    {
      cat $SRC/prelude.luau $SRC/$f.luau
      echo "ARKHER_REG.$b()"
    } > $DIST/UI_$b.lua
  done
done

echo "== build: core installer (ModuleScript reutilizavel) =="
python3 - "$SRC/prelude.luau" "$DIST/ArkherCore_Installer.lua" <<'PYEOF'
import sys
src_path, out_path = sys.argv[1], sys.argv[2]
src = open(src_path, encoding="utf-8").read()
assert "]====]" not in src
out = f"""--[[ ARKHER V2 — Core Installer: instala ModuleScript ArkherKit no ReplicatedStorage ]]
local PRELUDE = [====[
{src}
]====]
local rs = game:GetService("ReplicatedStorage")
local holder = rs:FindFirstChild("ArkherV2")
if not holder then
	holder = Instance.new("Folder")
	holder.Name = "ArkherV2"
	holder.Parent = rs
end
local mod = holder:FindFirstChild("ArkherKit")
if not mod then
	mod = Instance.new("ModuleScript")
	mod.Name = "ArkherKit"
	mod.Parent = holder
end
mod.Source = PRELUDE
print("[ARKHER] ArkherKit instalado em ReplicatedStorage.ArkherV2")
"""
open(out_path, "w", encoding="utf-8").write(out)
PYEOF

echo "== done =="
ls -la $DIST | awk '{print $9, $5}'
