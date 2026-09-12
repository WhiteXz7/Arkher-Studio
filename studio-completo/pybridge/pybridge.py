#!/usr/bin/env python3
"""Arkher PyBridge — backend externo de referência (Python/C++/C#).

Fala com o jogo via handlers.PyRun/PyStatus (server.lua -> PY_URL, default
http://127.0.0.1:8773, configurável pelo atributo de jogo "ArkherPyUrl").

Contrato (só stdlib, sem dependências):
  GET /status
    -> {"ok":true,"py":"3.x","version":"1.0","cwd":"...","tasks":["shell","exec"]}
  GET /run?task=shell&arg=<comando>
    -> executa no SHELL do host, timeout 15s -> {"ok":bool,"out":str,"error":str}
  GET /run?task=exec&lang=py&code=<codigo>
    -> roda `python -c`, timeout 10s -> {"ok":bool,"out":str,"error":str}
  GET /run?task=exec&lang=cpp|csharp&code=...
    -> stub honesto (fase 2: toolchain no host)

PRIVACIDADE (regra dura): o bridge NUNCA recebe dados de player/dev.
Só entram task/arg/code/lang anônimos. Qualquer campo userId/playerName/
accountName é rejeitado com 400. Logs guardam só nomes de task + tamanhos.

Uso local:  python3 pybridge.py   (depois: Play Solo no Studio + Deck_py)
Uso hosted: ver README.md (token obrigatório fora do localhost).
"""
import json
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

PORT = int(os.environ.get("ARKHER_PY_PORT", "8773"))
TOKEN = os.environ.get("ARKHER_PY_TOKEN", "")
VERSION = "1.0"
FORBIDDEN = ("userid", "playername", "accountname", "playerid", "email")

PY_BIN = sys.executable


def run_cmd(argv, timeout, shell=False):
    try:
        p = subprocess.run(argv, capture_output=True, text=True, timeout=timeout,
                           shell=shell)
        out = (p.stdout or "") + (p.stderr or "")
        return {"ok": p.returncode == 0, "out": out[:8000],
                "error": "" if p.returncode == 0 else f"exit={p.returncode}"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "out": "", "error": f"timeout ({timeout}s)"}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "out": "", "error": str(e)[:500]}


class H(BaseHTTPRequestHandler):
    server_version = "ArkherPyBridge/" + VERSION

    def log_message(self, *a):
        pass  # silencioso; sem dados sensíveis em log

    def _send(self, obj, code=200):
        raw = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def _allowed(self):
        try:
            if self.client_address[0] in ("127.0.0.1", "::1", "::ffff:127.0.0.1"):
                return True
        except Exception:  # noqa: BLE001
            pass
        if not TOKEN:
            return False
        q = parse_qs(urlparse(self.path).query)
        return q.get("token", [""])[0] == TOKEN

    def do_GET(self):  # noqa: N802
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if any(f in "".join(q.keys()).lower() for f in FORBIDDEN):
            self._send({"ok": False, "error": "forbidden field (privacy: world/anonymous data only)"}, 400)
            return
        if u.path == "/status":
            self._send({"ok": True, "py": sys.version.split()[0], "version": VERSION,
                        "cwd": os.getcwd()[-80:], "tasks": ["shell", "exec"],
                        "langs": ["py"], "auth": "token" if TOKEN else "localhost-only"})
            return
        if u.path == "/run":
            if not self._allowed():
                self._send({"ok": False, "error": "auth: defina ARKHER_PY_TOKEN e passe ?token= (localhost é livre)"}, 403)
                return
            task = q.get("task", [""])[0]
            if task == "shell":
                self._send(run_cmd(q.get("arg", [""])[0], 15, shell=True))
                return
            if task == "exec":
                lang = q.get("lang", ["py"])[0]
                code = q.get("code", [""])[0]
                if len(code) > 60000:
                    self._send({"ok": False, "error": "code > 60KB"})
                    return
                if lang == "py":
                    self._send(run_cmd([PY_BIN, "-c", code], 10))
                    return
                self._send({"ok": False, "error": f"lang '{lang}': fase 2 (instale a toolchain no host do bridge)"})
                return
            self._send({"ok": False, "error": f"task desconhecida: {task}"})
            return
        self._send({"ok": False, "error": "404"}, 404)


if __name__ == "__main__":
    print(f"ArkherPyBridge {VERSION} na porta {PORT} "
          f"({'token ON' if TOKEN else 'localhost-only'})", flush=True)
    HTTPServer(("0.0.0.0", PORT), H).serve_forever()
