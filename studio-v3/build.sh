#!/bin/bash
# ARKHER V4 — gera os scripts para o Roblox (cada um < 95K chars, o limite do
# Studio e ~100K) + o build unico para testes em Lua puro.
#
# NOVO NA V4: Kit C (motores custom ATX/AWX — terreno e agua proprios, sem
# Terrain do Roblox) e Kit D (Script Studio X + UI Kit X).
#
# Instalação no Roblox Studio (9 pastes):
#   1. ArkherKit_Installer_A.lua  -> Script (cria ReplicatedStorage.ArkherV3.ArkherKit_A)
#   2. ArkherKit_Installer_B.lua  -> Script (cria ReplicatedStorage.ArkherV3.ArkherKit_B)
#   3. ArkherKit_Installer_C.lua  -> Script (cria ReplicatedStorage.ArkherV3.ArkherKit_C)
#   4. ArkherKit_Installer_D.lua  -> Script (cria ReplicatedStorage.ArkherV3.ArkherKit_D)
#   5. ArkherStudio_MainUI.lua    -> LocalScript (shell do editor)
#   6. UI_Bundle_Editors.lua      -> LocalScript (Animator/Modeler/Terrain/Water/Particles)
#   7. UI_Bundle_Code.lua         -> LocalScript (Script Studio IDE)
#   8. UI_Bundle_Scene.lua        -> LocalScript (Camera/Lighting/Audio/Physics/UIStudio/Map)
#   9. UI_Bundle_System.lua       -> LocalScript (City/NPCs/Performance/Console/Settings/Cloud/AI/
#                                     Publish/SaveOpen/Export/Open/About)
# (ou cole os UI_<Nome>.lua individuais em vez dos bundles — ex.: soh a WATER)
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

read -r -d '' KIT_C_HDR <<'EOF' || true
--[[ ARKHER V4 — KIT C (ModuleScript) — DMATH + TERRAIN X (custom) + WATER X (custom) ]]
-- Motores proprios RRW: nao usam Terrain nem agua do Roblox. Requer o Kit A.
-- Instala em: ReplicatedStorage.ArkherV3.ArkherKit_C
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro.")
	end
	require(a)
end
_arkherLoadKitA()
EOF

read -r -d '' KIT_D_HDR <<'EOF' || true
--[[ ARKHER V4 — KIT D (ModuleScript) — SCRIPT STUDIO X + UI KIT X ]]
-- IDE backend (tokenizer/lint/autocomplete) + 42 widgets de jogo. Requer o Kit A.
-- Instala em: ReplicatedStorage.ArkherV3.ArkherKit_D
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro.")
	end
	require(a)
end
_arkherLoadKitA()
EOF

read -r -d '' KIT_E_HDR <<'EOF' || true
--[[ ARKHER V4 — KIT E (ModuleScript) — ANIMATOR X + AUDIO X + SCENE/SCATTER X ]]
-- Motores de animacao (37 easings/springs/deformers), mixer/DSP e povoamento
-- procedural. Requer o Kit A. Instala em: ReplicatedStorage.ArkherV3.ArkherKit_E
local function _arkherLoadKitA()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	local a = folder and folder:FindFirstChild("ArkherKit_A")
	if not a then a = script:FindFirstChild("ArkherKit_A") end
	if not a then a = script.Parent:FindFirstChild("ArkherKit_A") end
	if not a then
		error("[ARKHER] ArkherKit_A nao encontrado: rode ArkherKit_Installer_A.lua primeiro.")
	end
	require(a)
end
_arkherLoadKitA()
EOF

read -r -d '' LAUNCH_HDR <<'EOF' || true
--[[ ARKHER V4 — LocalScript. Requer os kits (ReplicatedStorage.ArkherV3.ArkherKit_B/C/D/E). ]]
local function _arkherKit()
	local rs = game:GetService("ReplicatedStorage")
	local folder = rs:FindFirstChild("ArkherV3")
	for _, kn in ipairs({ "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E" }) do
		local m = folder and folder:FindFirstChild(kn)
		if not m then m = script:FindFirstChild(kn) end
		if not m then m = script.Parent and script.Parent:FindFirstChild(kn) end
		if not m then
			error("[ARKHER] " .. kn .. " nao encontrado: rode os installers A+B+C+D+E primeiro.")
		end
		require(m)
	end
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

# ---------- 2b) KIT C (ModuleScript) — motores custom: dmath + terrainx + waterx ----------
echo "== build: Kit_C (ModuleScript) =="
{
	echo "$KIT_C_HDR"
	echo ""
	for f in core/dmath.luau core/terrainx.luau core/waterx.luau; do
		catw "$f"; echo ""
	done
} > "$DIST/ArkherKit_C.lua"

# ---------- 2c) KIT D (ModuleScript) — scripterx + uikitx ----------
echo "== build: Kit_D (ModuleScript) =="
{
	echo "$KIT_D_HDR"
	echo ""
	for f in core/scripterx.luau core/uikitx.luau; do
		catw "$f"; echo ""
	done
} > "$DIST/ArkherKit_D.lua"

# ---------- 2d) KIT E (ModuleScript) — animx + audiomix + scenex ----------
echo "== build: Kit_E (ModuleScript) =="
{
	echo "$KIT_E_HDR"
	echo ""
	for f in core/animx.luau core/audiomix.luau core/scenex.luau core/atmosx.luau core/camerax.luau core/particlesx.luau; do
		catw "$f"; echo ""
	done
} > "$DIST/ArkherKit_E.lua"

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
BUNDLE_EDITOR="animator modeler terrain water particles scatter"
BUNDLE_MOTION="animator audio"
BUNDLE_CODE="scripter"
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
		echo "ARKHER.out(\"SUCCESS\", \"ARKHER V4 — bundle $label: \" .. opened .. \" UIs abertas\")"
	} > "$outfile"
}

echo "== build: bundles =="
emit_bundle "$DIST/UI_Bundle_Editors.lua" "Editors" $BUNDLE_EDITOR
emit_bundle "$DIST/UI_Bundle_Code.lua" "Code" $BUNDLE_CODE
echo "-- bundle extra: Terrain+Water juntos (opcional)"
emit_bundle "$DIST/UI_Bundle_Mundo.lua" "Mundo" "terrain" "water" "scatter"
emit_bundle "$DIST/UI_Bundle_Motion.lua" "Motion" $BUNDLE_MOTION
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
	for f in core/do15.luau core/undo.luau core/publish.luau core/nmn.luau core/places.luau core/actions.luau core/singularity.luau core/live.luau core/dmath.luau core/terrainx.luau core/waterx.luau core/scripterx.luau core/uikitx.luau core/animx.luau core/audiomix.luau core/scenex.luau core/atmosx.luau core/camerax.luau core/particlesx.luau "$BOOT"; do
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
install_kit "$DIST/ArkherKit_C.lua" "$DIST/ArkherKit_Installer_C.lua" "ArkherKit_C"
install_kit "$DIST/ArkherKit_D.lua" "$DIST/ArkherKit_Installer_D.lua" "ArkherKit_D"
install_kit "$DIST/ArkherKit_E.lua" "$DIST/ArkherKit_Installer_E.lua" "ArkherKit_E"

# ---------- 8) tamanho (limites) ----------
echo "== tamanhos (limite Roblox ~100000 chars) =="
for f in "$DIST"/*.lua; do
	sz=$(wc -c < "$f")
	mark="ok"
	[ "$sz" -gt 95000 ] && mark="!! GRANDO"
	printf "  %-40s %7d  %s\n" "$(basename "$f")" "$sz" "$mark"
done

echo "== done =="
