"""Gera .rbxlx (XML place/model) a partir do snapshot Arkher {c,n,p,k}.

Subset suportado (o que o serializeTree entrega de útil):
  Model, Folder, Part, WedgePart, SpawnLocation, Script, ModuleScript,
  StringValue, IntValue, BoolValue, NumberValue, Sound, PointLight.
Classes fora do subset viram Folder (estrutura preservada, sem quebrar).

Uso:
  import rbxlx
  xml_bytes, stats = rbxlx.place_file(tree, title="Minha Place")
  xml_bytes, stats = rbxlx.model_file(tree)   # fragmento p/ importar no Studio
"""
import math
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

PART_CLASSES = {"Part", "WedgePart", "SpawnLocation", "MeshPart"}
SCRIPT_CLASSES = {"Script", "ModuleScript"}
VALUE_CLASSES = {"StringValue": "string", "IntValue": "int", "BoolValue": "bool",
                 "NumberValue": "float", "ObjectValue": None}

SCHEMA = ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
          'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
          '<Meta name="ExplicitAutoJoints">true</Meta>\n'
          '<External>null</External><External>nil</External>\n')


def _rot_yxz(rx, ry, rz):
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    # R = Ry * Rx * Rz
    return [
        cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx,
        cx * sz, cx * cz, -sx,
        -sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx,
    ]


def _f(v):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return "0"
    if f == 0:
        return "0"
    s = f"{f:.5f}".rstrip("0").rstrip(".")
    return s if s else "0"


def _v3(v, dflt=(0, 0, 0)):
    if isinstance(v, dict):
        return (v.get("X", v.get("x", dflt[0])), v.get("Y", v.get("y", dflt[1])),
                v.get("Z", v.get("z", dflt[2])))
    if isinstance(v, (list, tuple)) and len(v) >= 3:
        return (v[0], v[1], v[2])
    return dflt


def _bool(b):
    return "true" if b else "false"


class Gen:
    def __init__(self):
        self.ref = 0
        self.parts = 0
        self.scripts = 0
        self.skipped = []

    def _id(self):
        self.ref += 1
        return f"R{self.ref}"

    def emit(self, node, out):
        if not isinstance(node, dict):
            return
        cls = str(node.get("c", "Folder"))
        name = str(node.get("n", cls))
        p = node.get("p") or {}
        kids = node.get("k") or []
        if cls in PART_CLASSES:
            self._part(out, cls if cls != "MeshPart" else "Part", name, p, kids)
        elif cls in SCRIPT_CLASSES:
            self._script(out, cls, name, p, kids)
        elif cls in ("Model", "Folder"):
            self._cont(out, cls, name, kids)
        elif cls in VALUE_CLASSES and VALUE_CLASSES[cls]:
            self._value(out, cls, name, p)
        elif cls == "Sound":
            self._sound(out, name, p)
        elif cls == "PointLight":
            self._light(out, name, p)
        else:
            if cls not in ("Workspace", "Camera", "Terrain"):
                self.skipped.append(cls)
            self._cont(out, "Folder", name, kids)

    def _head(self, out, cls, name):
        r = self._id()
        out.append(f'<Item class="{escape(cls)}" referent="{r}"><Properties>'
                   f'<string name="Name">{escape(name)}</string>')
        return r

    def _tail(self, out, kids):
        out.append('</Properties>')
        for k in kids:
            self.emit(k, out)
        out.append('</Item>')

    def _part(self, out, cls, name, p, kids):
        self.parts += 1
        self._head(out, cls, name)
        pos = _v3(p.get("pos"), (0, 5, 0))
        rot = _v3(p.get("rot"), (0, 0, 0))
        m = _rot_yxz(rot[0], rot[1], rot[2])
        cf = " ".join([_f(pos[0]), _f(pos[1]), _f(pos[2])] + [_f(x) for x in m])
        size = _v3(p.get("size"), (4, 1, 2))
        col = _v3(p.get("color"), (0.639, 0.635, 0.647))
        out.append(
            f'<bool name="Anchored">{_bool(p.get("anchor", True))}</bool>'
            f'<float name="Reflectance">{_f(p.get("reflect", 0))}</float>'
            f'<float name="Transparency">{_f(p.get("trans", 0))}</float>'
            f'<bool name="CanCollide">{_bool(p.get("cc", True))}</bool>'
            f'<bool name="CanTouch">{_bool(p.get("ct", True))}</bool>'
            f'<bool name="CanQuery">{_bool(p.get("cq", True))}</bool>'
            f'<bool name="CastShadow">{_bool(p.get("cs", True))}</bool>'
            f'<bool name="Locked">{_bool(p.get("locked", False))}</bool>'
            f'<CoordinateFrame name="CFrame"><X>{_f(pos[0])}</X><Y>{_f(pos[1])}</Y><Z>{_f(pos[2])}</Z>'
            f'<R00>{_f(m[0])}</R00><R01>{_f(m[1])}</R01><R02>{_f(m[2])}</R02>'
            f'<R10>{_f(m[3])}</R10><R11>{_f(m[4])}</R11><R12>{_f(m[5])}</R12>'
            f'<R20>{_f(m[6])}</R20><R21>{_f(m[7])}</R21><R22>{_f(m[8])}</R22></CoordinateFrame>'
            f'<Vector3 name="size"><X>{_f(size[0])}</X><Y>{_f(size[1])}</Y><Z>{_f(size[2])}</Z></Vector3>'
            f'<Color3 name="Color"><R>{_f(col[0])}</R><G>{_f(col[1])}</G><B>{_f(col[2])}</B></Color3>'
        )
        _ = cf
        self._tail(out, kids)

    def _script(self, out, cls, name, p, kids):
        self.scripts += 1
        self._head(out, cls, name)
        src = p.get("source", "-- Arkher")
        if not isinstance(src, str):
            src = "-- Arkher"
        out.append(f'<bool name="Disabled">{_bool(not p.get("enabled", True))}</bool>'
                   f'<ProtectedString name="Source">{escape(src)}</ProtectedString>')
        self._tail(out, kids)

    def _cont(self, out, cls, name, kids):
        self._head(out, cls, name)
        self._tail(out, kids)

    def _value(self, out, cls, name, p):
        self._head(out, cls, name)
        v = p.get("value", "")
        kind = VALUE_CLASSES[cls]
        if kind == "bool":
            body = _bool(v)
        elif kind in ("int", "float"):
            body = _f(v)
        else:
            body = escape("" if v is None else str(v))
        out.append(f'<{kind} name="Value">{body}</{kind}>')
        out.append('</Properties></Item>')

    def _sound(self, out, name, p):
        self._head(out, "Sound", name)
        out.append(f'<string name="SoundId">{escape(str(p.get("soundId", "")))}</string>'
                   f'<float name="Volume">{_f(p.get("vol", 0.5))}</float>'
                   f'<bool name="Looped">{_bool(p.get("looped", False))}</bool>'
                   f'<float name="PlaybackSpeed">{_f(p.get("speed", 1))}</float>')
        out.append('</Properties></Item>')

    def _light(self, out, name, p):
        self._head(out, "PointLight", name)
        out.append(f'<float name="Brightness">{_f(p.get("bright", 1))}</float>'
                   f'<float name="Range">{_f(p.get("range", 16))}</float>')
        out.append('</Properties></Item>')


def _wrap(place_title, body_out):
    out = [SCHEMA]
    out.append('<Item class="Workspace" referent="RSVC_W"><Properties>'
               '<string name="Name">Workspace</string></Properties>')
    out.extend(body_out)
    out.append('</Item>')
    for svc in ("Lighting", "Players", "ReplicatedStorage", "ServerScriptService",
                "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
                "SoundService", "Chat", "TextChatService"):
        out.append(f'<Item class="{svc}" referent="RSVC_{svc}"><Properties>'
                   f'<string name="Name">{svc}</string></Properties></Item>')
    out.append('</roblox>\n')
    return "".join(out).encode("utf-8")


def place_file(tree, title="Arkher Place"):
    """Gera .rbxlx COMPLETO (DataModel) a partir do snapshot do Workspace."""
    g = Gen()
    body = []
    kids = (tree.get("k") or []) if isinstance(tree, dict) else []
    if tree.get("c") not in (None, "Workspace", "DataModel"):
        g.emit(tree, body)
    else:
        for k in kids:
            g.emit(k, body)
    data = _wrap(title, body)
    ET.fromstring(data)  # valida XML bem-formado
    stats = {"parts": g.parts, "scripts": g.scripts, "bytes": len(data),
             "skipped": sorted(set(g.skipped))[:12]}
    return data, stats


def model_file(tree):
    """Gera fragmento .rbxmx (p/ importar no Studio)."""
    g = Gen()
    body = [SCHEMA]
    g.emit(tree if isinstance(tree, dict) else {"c": "Folder", "n": "Arkher"}, body)
    body.append('</roblox>\n')
    data = "".join(body).encode("utf-8")
    ET.fromstring(data)
    return data, {"parts": g.parts, "scripts": g.scripts, "bytes": len(data)}
