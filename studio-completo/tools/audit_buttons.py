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

# ribbon x ACTIONS (chave = TAB_Nome)
shell = load("tools/build_shell.py")
tabs = re.findall(r'\(\s*"([A-Z0-9]+)"\s*,\s*\[', shell)
rib_keys = set()
cur = None
for m in re.finditer(r'\(\s*"([A-Z0-9]+)"\s*,\s*\[|\(\s*"([A-Za-z0-9_ ]+)"\s*,\s*"', shell):
    if m.group(1):
        cur = m.group(1)
    elif cur and m.group(2) and " " not in m.group(2):
        rib_keys.add(f"{cur}_{m.group(2)}")
act_names = {a[0] for a in actions}
only_ribbon = sorted(k for k in rib_keys if k not in act_names)
only_actions = sorted(a for a in act_names if a not in rib_keys)
print(f"ribbon keys: {len(rib_keys)} | sem ACTIONS: {only_ribbon}")
print(f"ACTIONS sem ribbon: {only_actions}")

print(f"\nMORTOS/SUSPEITOS: {len(dead)}")
for d in dead:
    print("  ", d)
