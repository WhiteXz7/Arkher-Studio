#!/usr/bin/env python3
"""Gera o place .rbxlx do ARKHER V3.

Usa um .rbxl de baseplate real (salvo pelo Studio, v566) como template — o
XML texto legacy (workspace.rbxl) e aceito pelo Studio — e embute:

  ReplicatedStorage.ArkherV3.ArkherKit_A    (ModuleScript)
  ReplicatedStorage.ArkherV3.ArkherKit_B    (ModuleScript)
  StarterPlayerScripts.ArkherMainUI         (LocalScript)
  StarterPlayerScripts.ArkherBundle_Editors (LocalScript)
  StarterPlayerScripts.ArkherBundle_Scene   (LocalScript)
  StarterPlayerScripts.ArkherBundle_System  (LocalScript)

No Studio: abra o .rbxlx e aperte F5 (Play) — o editor ARKHER inteiro abre.
"""
import os
import re
import sys
import uuid
import zipfile
import xml.dom.minidom as minidom

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "commandbar")
TEMPLATE = sys.argv[1] if len(sys.argv) > 1 else None
OUT = os.path.join(DIST, "arkher-v3-studio.rbxlx")

SKELETON = """<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
\t<External>null</External>
\t<External>nil</External>
\t<Item class="Workspace" referent="RBXW1">
\t\t<Properties>
\t\t\t<string name="Constraints">false</string>
\t\t\t<string name="Name">Workspace</string>
\t\t</Properties>
\t</Item>
\t<Item class="ReplicatedStorage" referent="RBXRS1">
\t\t<Properties>
\t\t\t<string name="Name">ReplicatedStorage</string>
\t\t</Properties>
\t</Item>
\t<Item class="StarterPlayer" referent="RBXSP1">
\t\t<Properties>
\t\t\t<string name="Name">StarterPlayer</string>
\t\t</Properties>
\t\t<Item class="StarterPlayerScripts" referent="RBXSPS1">
\t\t\t<Properties>
\t\t\t\t<string name="Name">StarterPlayerScripts</string>
\t\t\t</Properties>
\t\t</Item>
\t</Item>
</roblox>"""
if not TEMPLATE or not os.path.exists(TEMPLATE):
    TEMPLATE = None  # gera do esqueleto minimo proprio


def xml_escape(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def new_referent() -> str:
    return "RBX" + uuid.uuid4().hex.upper()


def script_item(cls: str, name: str, source: str, indent: str) -> str:
    if len(source) > 100_000:
        sys.exit(f"ERRO: {name} tem {len(source)} chars (limite do Studio: 100.000)")
    return (
        f"{indent}<Item class=\"{cls}\" referent=\"{new_referent()}\">\n"
        f"{indent}\t<Properties>\n"
        f"{indent}\t\t<BinaryString name=\"AttributesSerialize\"></BinaryString>\n"
        f"{indent}\t\t<bool name=\"Disabled\">false</bool>\n"
        f"{indent}\t\t<Content name=\"LinkedSource\"><null></null></Content>\n"
        f"{indent}\t\t<string name=\"Name\">{xml_escape(name)}</string>\n"
        f"{indent}\t\t<string name=\"ScriptGuid\"></string>\n"
        f"{indent}\t\t<ProtectedString name=\"Source\">{xml_escape(source)}</ProtectedString>\n"
        f"{indent}\t\t<BinaryString name=\"Tags\"></BinaryString>\n"
        f"{indent}\t</Properties>\n"
        f"{indent}</Item>\n"
    )


def read(path):
    if path is None:
        return SKELETON
    with open(path, encoding="utf-8") as f:
        return f.read()


doc = read(TEMPLATE)

kit_a = read(os.path.join(DIST, "ArkherKit_A.lua"))
kit_b = read(os.path.join(DIST, "ArkherKit_B.lua"))
kit_c = read(os.path.join(DIST, "ArkherKit_C.lua"))
kit_d = read(os.path.join(DIST, "ArkherKit_D.lua"))
kit_e = read(os.path.join(DIST, "ArkherKit_E.lua"))
main_ui = read(os.path.join(DIST, "ArkherStudio_MainUI.lua"))
b_ed = read(os.path.join(DIST, "UI_Bundle_Editors.lua"))
b_cd = read(os.path.join(DIST, "UI_Bundle_Code.lua"))
b_sc = read(os.path.join(DIST, "UI_Bundle_Scene.lua"))
b_sy = read(os.path.join(DIST, "UI_Bundle_System.lua"))

# ---- 1) ArkherV3 em ReplicatedStorage ----
anchor = doc.find('class="ReplicatedStorage"')
assert anchor > 0, "template sem ReplicatedStorage"
end_item = doc.find("</Item>", anchor)
folder = (
    f"\t<Item class=\"Folder\" referent=\"{new_referent()}\">\n"
    f"\t\t<Properties>\n"
    f"\t\t\t<BinaryString name=\"AttributesSerialize\"></BinaryString>\n"
    f"\t\t<string name=\"Name\">ArkherV3</string>\n"
    f"\t\t<BinaryString name=\"Tags\"></BinaryString>\n"
    f"\t\t</Properties>\n"
    + script_item("ModuleScript", "ArkherKit_A", kit_a, "\t\t")
    + script_item("ModuleScript", "ArkherKit_B", kit_b, "\t\t")
    + script_item("ModuleScript", "ArkherKit_C", kit_c, "\t\t")
    + script_item("ModuleScript", "ArkherKit_D", kit_d, "\t\t")
    + script_item("ModuleScript", "ArkherKit_E", kit_e, "\t\t")
    + "\t</Item>\n"
)
doc = doc[:end_item] + folder + doc[end_item:]

# ---- 2) launchers em StarterPlayerScripts ----
anchor = doc.find('class="StarterPlayerScripts"')
assert anchor > 0, "template sem StarterPlayerScripts"
end_item = doc.find("</Item>", anchor)
launchers = (
    script_item("LocalScript", "ArkherMainUI", main_ui, "\t\t")
    + script_item("LocalScript", "ArkherBundle_Editors", b_ed, "\t\t")
    + script_item("LocalScript", "ArkherBundle_Code", b_cd, "\t\t")
    + script_item("LocalScript", "ArkherBundle_Scene", b_sc, "\t\t")
    + script_item("LocalScript", "ArkherBundle_System", b_sy, "\t\t")
)
doc = doc[:end_item] + launchers + doc[end_item:]

# ---- 3) valida XML (well-formed) ----
try:
    minidom.parseString(doc.encode("utf-8"))
except Exception as e:
    sys.exit(f"XML INVALIDO: {e}")

# ---- 4) zip -> .rbxlx ----
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("workspace.rbxl", doc.encode("utf-8"))

size = os.path.getsize(OUT)
print(f"ok: {OUT} ({size} bytes)")
print(f"    workspace.rbxl: {len(doc)} chars (xml texto legacy, aceito pelo Studio)")
print("    instancias:")
for n in ("ArkherV3", "ArkherKit_A", "ArkherKit_B", "ArkherKit_C", "ArkherKit_D", "ArkherKit_E", "ArkherMainUI",
          "ArkherBundle_Editors", "ArkherBundle_Code", "ArkherBundle_Scene", "ArkherBundle_System"):
    m = re.search(rf'<string name="Name">{n}</string>', doc)
    print(f"      {n}: {'ok' if m else 'FALTOU!'}")
