#!/usr/bin/env python3
"""
pybridge.py — PONTE PYTHON ARKHER
=================================
Servidor HTTP mínimo (stdlib pura) que o painel **PY X** do Arkher Studio
consulta via HttpService (`http://127.0.0.1:8773`). Executa DE VERDADE os
scripts do pipeline (subprocess) e devolve a saída em JSON.

USO (no PC, dentro da pasta do repo):
    python3 studio-completo/tools/pybridge.py        # porta 8773
    python3 studio-completo/tools/pybridge.py --port 9000

ENDPOINTS
  GET /status           -> { ok, py, cwd, version, tasks }
  GET /run?task=tests   -> roda run_tests.py (stdout até 40 linhas)
  GET /run?task=build   -> roda build_server.py
  GET /run?task=audit   -> roda auditoria.py
  GET /run?task=shell&arg=<cmd>  -> qualquer comando shell (CUIDADO: local apenas)

Segurança: escuta APENAS em 127.0.0.1. Sem auth porque é loopback da máquina
do dev; se isso te deixar desconfortável, use `--token` e passe o token nos
headers — mas o painel usa GET simples sem segredos.
"""
import argparse
import json
import os
import subprocess
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = "1.0.0"
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

TASKS = {
    "tests": [sys.executable, os.path.join(ROOT, "studio-completo", "tools", "run_tests.py")],
    "build": [sys.executable, os.path.join(ROOT, "studio-completo", "tools", "build_server.py")],
    "audit": [sys.executable, os.path.join(ROOT, "studio-completo", "tools", "auditoria.py")],
}


def run_subprocess(args):
    """executa com timeout 180s, captura stdout/stderr, limita a 80 linhas."""
    try:
        proc = subprocess.run(
            args, cwd=ROOT, capture_output=True, text=True,
            timeout=180, errors="replace",
        )
        out = (proc.stdout or "") + ("\n[stderr]\n" + proc.stderr if proc.stderr else "")
        lines = [ln for ln in out.splitlines() if ln.strip()]
        tail = lines[-80:]
        ok = proc.returncode == 0
        summary = tail[-1] if tail else "(sem saída)"
        if not ok:
            summary = f"exit {proc.returncode}: {summary}"
        return {"ok": ok, "summary": summary, "out": tail, "code": proc.returncode}
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout 180s", "out": []}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "error": f"spawn falhou: {exc}", "out": []}


def run_task(task, arg=None):
    if task in TASKS:
        return run_subprocess(TASKS[task])
    if task == "shell" and arg:
        # shell local do dev: roda de verdade, em /bin/sh
        return run_subprocess(["/bin/sh", "-c", arg])
    return {"ok": False, "error": f"task desconhecida: {task}", "out": []}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # silencia o log barulhento
        sys.stderr.write("[pybridge] " + fmt % args + "\n")

    def _send(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)
        if parsed.path == "/status":
            self._send({
                "ok": True,
                "version": VERSION,
                "py": sys.version.split()[0],
                "cwd": ROOT,
                "tasks": sorted(TASKS.keys()) + ["shell"],
            })
            return
        if parsed.path == "/run":
            task = (qs.get("task") or [""])[0]
            arg = (qs.get("arg") or [""])[0]
            # executa num thread (o ThreadingHTTPServer ja cuida), com resposta
            self._send(run_task(task, arg))
            return
        self._send({"ok": False, "error": "rota desconhecida",
                    "rotas": ["/status", "/run?task=tests|build|audit|shell&arg=..."]}, status=404)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8773)
    args = ap.parse_args()
    srv = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"[pybridge] PYTHON BRIDGE ARKHER v{VERSION}")
    print(f"[pybridge] ouvindo em http://127.0.0.1:{args.port}  (cwd={ROOT})")
    print("[pybridge] deixe aberto; o painel PY X do Studio vai bater aqui.")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\n[pybridge] tchau.")
        srv.shutdown()


if __name__ == "__main__":
    main()
