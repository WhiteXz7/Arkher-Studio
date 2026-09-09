#!/bin/bash
# ARKHER V3 — gera os scripts para o Roblox (cada um < 90K chars, o limite do
# Studio e ~100K) + o build unico para testes em Lua puro.
#
# Instalação no Roblox Studio (6 pastes):
#   1. ArkherKit_Installer_A.lua  -> ModuleScript (cria ReplicatedStorage.ArkherV3.ArkherKit_A)
#   2. ArkherKit_Installer_B.lua  -> ModuleScript (cria ReplicatedStorage.ArkherV3.ArkherKit_B)
#   3. ArkherStudio_MainUI.lua    -> LocalScript (shell do editor)
#   4. UI_Bundle_Editors.lua      -> LocalScript (Animator/Modeler/Terrain/Script/Particles)
#   5. UI_Bundle_Scene.lua        -> LocalScript (Camera/Lighting/Audio/Physics/UIDesigner/Map)
#   6. UI_Bundle_System.lua       -> LocalScript (City/NPCs/Performance/Console/Settings/Cloud/AI/
#                                     Publish/SaveOpen/Export/Open/About)
# (ou cole os UI_<Nome>.lua individuais em vez dos bundles)
set -e
cd "$(dirname "$0")"

DIST=commandbar
rm -f "$DIST"/*.lua 2>/dev/null || true
mkdir -p "$DIST"

PRELUDE=src/prelude.luau
BOOT=src/boot.luau

# embrulha um arquivo em do...end (escopa os locals — evita o limite de 200
# locals por chunk quando varios arquivos viram 1 script)
catw() {
	echo "do"
	cat "$1"
	echo "end"
}

# ---------- headers ----------
read -r -d '' KIT_A_HDR <<'EOF' || true
--[[ ARKHER V3 — KIT A (ModuleScript) — prelude + do15 + undo + publish + nmn ]]
-- Instala em: ReplicatedStorage.ArkherV3.ArkherKit_A
EOF

read -r -d '' KIT_B_HDR <<'EOF' || true
--[[ ARKHER V3 — KIT B (ModuleScript) — places + actions + singularity + live + boot ]]
-- Requer o Kit A (na mesma pasta). Instala em: ReplicatedStorage.ArkherV3.ArkherKit_B
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro (cria ReplicatedStorage.ArkherV3.ArkherKit_A).")
	end
	require(a)
end
_arkherLoadKitA()
EOF

read -r -d '' LAUNCH_HDR <<'EOF' || true
--[[ ARKHER V3 — LocalScript. Requer o kit (ReplicatedStorage.ArkherV3.ArkherKit_B). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local b = folder and folder:FindFirstChild("ArkherKit_B")
	if not b then b = script:FindFirstChild("ArkherKit_B") end
	if not b then b = script.Parent:FindFirstChild("ArkherKit_B") end
	if not b then
		error("[ARKHER] ArkherKit_B nao encontrado: rode os 2 installers (ArkherKit_A e ArkherKit_B) primeiro.")
	end
	require(b)
end
_arkherKit()
ARKHER.boot()
EOF

# ---------- 1) KIT A (ModuleScript) ----------
echo "== build: Kit_A (ModuleScript) =="
{
	echo "$KIT_A_HDR"
	echo ""
	catw "$PRELUDE"; echo ""
	for f in core/do15.luau core/undo.luau core/publish.luau core/nmn.luau; do
		catw "$f"; echo ""
	done
} > "$DIST/ArkherKit_A.lua"

# ---------- 2) KIT B (ModuleScript) ----------
echo "== build: Kit_B (ModuleScript) =="
{
	echo "$KIT_B_HDR"
	echo ""
	for f in core/places.luau core/actions.luau core/singularity.luau core/live.luau "$BOOT"; do
		catw "$f"; echo ""
	done
} > "$DIST/ArkherKit_B.lua"

# ---------- 3) MAIN UI (LocalScript: shell) ----------
echo "== build: MainUI (LocalScript) =="
{
	echo "$LAUNCH_HDR"
	echo ""
	catw src/ui/main.luau; echo ""
	catw src/ui/palette.luau; echo ""
	echo "local ok, err = pcall(function() ARKHER_BUILD_MAIN() end)"
	echo "if not ok then ARKHER.out(\"ERROR\", \"MainUI falhou: \" .. tostring(err)) end"
} > "$DIST/ArkherStudio_MainUI.lua"

# ---------- 4) BUNDLES ----------
BUNDLE_EDITOR="animator modeler terrain scripter particles"
BUNDLE_SCENE="camera lighting audio physics uidesigner mapview"
BUNDLE_SYSTEM="city npcs performance console settings cloud ai publish saveopen saveexport open about"

emit_bundle() {
	local outfile="$1"; shift
	local label="$1"; shift
	{
		echo "$LAUNCH_HDR"
		echo ""
		for f in "$@"; do catw "src/ui/$f.luau"; echo ""; done
		echo "local opened = ARKHER.openAll()"
		echo "ARKHER.out(\"SUCCESS\", \"ARKHER V3 — bundle $label: \" .. opened .. \" UIs abertas\")"
	} > "$outfile"
}

echo "== build: bundles =="
emit_bundle "$DIST/UI_Bundle_Editors.lua" "Editors" $BUNDLE_EDITOR
emit_bundle "$DIST/UI_Bundle_Scene.lua" "Scene" $BUNDLE_SCENE
emit_bundle "$DIST/UI_Bundle_System.lua" "System" $BUNDLE_SYSTEM

# ---------- 5) UIs individuais ----------
echo "== build: UIs individuais =="
for f in src/ui/*.luau; do
	case "$f" in
		*main.luau) continue ;;
	esac
	NAME=$(grep -oE '^ARKHER\.reg\("[A-Za-z0-9_]+"' "$f" | head -1 | sed 's/^ARKHER\.reg("\(.*\)"/\1/')
		if [ -n "$NAME" ]; then
		{
			echo "$LAUNCH_HDR"
			echo ""
			catw "$f"; echo ""
			echo "ARKHER.open(\"$NAME\")"
		} > "$DIST/UI_$NAME.lua"
	fi
done

# ---------- 6) ALL (build unico p/ testes em Lua puro — NAO para o Roblox) ----------
echo "== build: ALL (teste) =="
{
	catw "$PRELUDE"; echo ""
	for f in core/do15.luau core/undo.luau core/publish.luau core/nmn.luau core/places.luau core/actions.luau core/singularity.luau core/live.luau "$BOOT"; do
		catw "$f"; echo ""
	done
	catw src/ui/main.luau; echo ""
	for f in src/ui/*.luau; do
		case "$f" in
			*main.luau) continue ;;
		esac
		catw "$f"; echo ""
	done
	cat src/driver_all.luau
} > "$DIST/ArkherStudio_ALL.lua"

# ---------- 7) INSTALLERS (colam os kits em ModuleScripts) ----------
echo "== build: installers =="
install_kit() {
	local kit_path="$1" out_path="$2" mod_name="$3"
	python3 - "$kit_path" "$out_path" "$mod_name" <<'PYEOF'
import sys
kit_path, out_path, mod_name = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(kit_path, encoding="utf-8").read()
assert "]====]" not in src, "fonte contem ]====] — use outro delimiter"
out = f"""--[[ ARKHER V3 — Installer {mod_name}: cria o ModuleScript em ReplicatedStorage.ArkherV3 ]]
local KIT = [====[
{src}
]====]
local rs = game:GetService("ReplicatedStorage")
local holder = rs:FindFirstChild("ArkherV3")
if not holder then
	holder = Instance.new("Folder")
	holder.Name = "ArkherV3"
	holder.Parent = rs
end
local mod = holder:FindFirstChild("{mod_name}")
if not mod then
	mod = Instance.new("ModuleScript")
	mod.Name = "{mod_name}"
	mod.Parent = holder
end
mod.Source = KIT
print("[ARKHER V3] {mod_name} instalado em ReplicatedStorage.ArkherV3")
"""
open(out_path, "w", encoding="utf-8").write(out)
PYEOF
}
install_kit "$DIST/ArkherKit_A.lua" "$DIST/ArkherKit_Installer_A.lua" "ArkherKit_A"
install_kit "$DIST/ArkherKit_B.lua" "$DIST/ArkherKit_Installer_B.lua" "ArkherKit_B"

# ---------- 8) tamanho (limites) ----------
echo "== tamanhos (limite Roblox ~100000 chars) =="
for f in "$DIST"/*.lua; do
	sz=$(wc -c < "$f")
	mark="ok"
	[ "$sz" -gt 95000 ] && mark="!! GRANDO"
	printf "  %-40s %7d  %s\n" "$(basename "$f")" "$sz" "$mark"
done

echo "== done =="
