"""Auditoria Fase 5: cada botao do ribbon resolve p/ algo real?
Checa: ACTIONS kinds (open/toggle/popup) x specs; bus x handlers;
menus x dispatch 03; ribbon x ACTIONS. Uso: audit_buttons.py"""
import json
import os
import re

ROOT = os.path.dirname(os.path.abspath(__file__))
R = os.path.join(ROOT, "..")


def load(p):
    with open(os.path.join(R, p), encoding="utf-8") as f:
        return f.read()


s05 = load("scripts/05_StudioX.lua")
server = load("scripts/server.lua")
m03 = load("scripts/03_Menus.lua")

actions = re.findall(r'\n\t([A-Za-z0-9_]+) = \{ "(\w+)", "([^"]+)"', s05)
print(f"ACTIONS: {len(actions)} entradas")
handlers = set(re.findall(r'function handlers\.(\w+)', server))
print(f"server handlers: {len(handlers)}")

names = set()
for spec in ("tools/v2spec.json", "tools/deck_spec.json", "tools/guix_spec.json",
             "tools/shellspec.json"):
    try:
        d = json.loads(load(spec))

        def walk(o):
            if isinstance(o, dict):
                if isinstance(o.get("name"), str):
                    names.add(o["name"])
                for v in o.values():
                    walk(v)
            elif isinstance(o, list):
                for v in o:
                    walk(v)
        walk(d)
    except FileNotFoundError:
        pass
print(f"nomes assados (specs): {len(names)}")

# dispatch 03: chaves do OnInvoke (cmd == "..." / cmds["..."])
inv = m03[m03.find("MenusBus OnInvoke"):]
menucmds = set(re.findall(r'action == "(\w+)"', inv))
# dispatch 03 tambem resolve via tabela actions.* (fallback do OnInvoke).
menucmds |= set(re.findall(r'actions\.([A-Za-z0-9_]+)\s*=', m03))
print(f"menus cmds: {len(menucmds)}")

dead = []
for name, kind, arg in actions:
    if kind in ("open", "toggle"):
        if arg not in names:
            dead.append((name, kind, arg, "janela nao assada"))
    elif kind == "popup":
        if arg not in names:
            dead.append((name, kind, arg, "popup nao assado"))
    elif kind == "bus":
        if arg not in handlers:
            dead.append((name, kind, arg, "handler nao existe"))
    elif kind == "menus":
        if arg not in menucmds:
            dead.append((name, kind, arg, "cmd menus? (verificar)"))
    elif kind == "core":
        pass  # modos do nucleo 01 (manual)
    else:
        dead.append((name, kind, arg, "kind desconhecido"))

# topbar unica R18: botoes do TABS (build_shell.py) x BUTTONS (09_Topbar.lua)
shell = load("tools/build_shell.py")
shell = shell[shell.index("TABS = ["):shell.index("def C3(r, g, b):")]
rib = {}  # "TAB_id" -> (kind, target)
cur = None
for m in re.finditer(
        r'(?m)^(\s*)\("([A-Za-z0-9_]+)",\s*(?:\[|"[^"]*",\s*"[^"]*",\s*\("(\w+)"(?:,\s*(?:"([^"]*)")?)?\))',
        shell):
    ind, name, kind, target = m.group(1), m.group(2), m.group(3), m.group(4)
    if len(ind) == 4 and kind is None:
        cur = name
    elif len(ind) == 8 and kind and cur:
        rib[f"{cur}_{name}"] = (kind, target or "")
s09 = load("scripts/09_Topbar.lua")
wired = set(re.findall(r'RibbonBtn_([A-Za-z0-9_]+_[A-Za-z0-9_]+)\s*=\s*\{', s09))
menukeys = set(re.findall(r'MENUS\.([A-Za-z_]+)\s*=\s*\{', m03))
menukeys |= set(re.findall(r'(?m)^  ([A-Za-z]+) = \{$', m03))
corekeys = {"Select", "MoveScale", "Rotate", "Scale", "LocalGlobal"}
rib_dead = []
for key, (kind, target) in sorted(rib.items()):
    if key not in wired:
        rib_dead.append((key, "sem BUTTONS no 09"))
    elif kind == "menus" and target not in menucmds:
        rib_dead.append((key, f"menus: cmd {target} sem dispatch"))
    elif kind == "menu" and target not in menukeys:
        rib_dead.append((key, f"menu: MENUS.{target} nao existe"))
    elif kind == "core" and target not in corekeys:
        rib_dead.append((key, f"core: modo {target} invalido"))
    elif kind == "api" and target not in handlers:
        rib_dead.append((key, f"api: handler {target} nao existe"))
    elif kind == "lock" and not ({"PropsAll", "SetAny"} <= handlers):
        rib_dead.append((key, "lock: PropsAll/SetAny ausentes"))
    elif kind not in ("menus", "menu", "core", "api", "lock"):
        rib_dead.append((key, f"kind desconhecido: {kind}"))
only_wired = sorted(w for w in wired if w not in rib)
print(f"ribbon keys: {len(rib)} | sem fio no 09: "
      f"{sorted(k for k, _ in rib_dead if _.startswith('sem BUTTONS'))}")
print(f"BUTTONS sem TABS: {only_wired}")
for key, why in rib_dead:
    if not why.startswith("sem BUTTONS"):
        dead.append((key, "ribbon", why, "alvo nao resolve"))

print(f"\nMORTOS/SUSPEITOS: {len(dead)}")
for d in dead:
    print("  ", d)
