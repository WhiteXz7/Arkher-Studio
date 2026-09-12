#!/usr/bin/env python3
"""Arkher PyBridge — backend externo de referência (Python/C++/C# + catálogo).

Fala com o jogo via handlers.PyRun/PyStatus/ToolboxPaidSearch
(server.lua -> PY_URL, default http://127.0.0.1:8773,
configurável pelo atributo de jogo "ArkherPyUrl").

Contrato (só stdlib, sem dependências):
  GET /status
  GET /run?task=shell&arg=<comando>
  GET /run?task=exec&lang=py|cpp|csharp&code=<codigo>
  GET /catalog/search?q=<busca>&limit=8[&cat=<Category>]
  GET /catalog/info?id=<assetId>

PRIVACIDADE (regra dura): o bridge NUNCA recebe dados de player/dev.
Só entram task/arg/code/lang/q anônimos. Qualquer campo userId/playerName/
accountName é rejeitado com 400. Logs guardam só nomes de task + tamanhos.

Uso local:  python3 pybridge.py   (depois: Play Solo no Studio + Deck_py)
Uso hosted: ver README.md (token obrigatório fora do localhost).
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs, urlencode

PORT = int(os.environ.get("ARKHER_PY_PORT", "8773"))
TOKEN = os.environ.get("ARKHER_PY_TOKEN", "")
VERSION = "1.1"
FORBIDDEN = ("userid", "playername", "accountname", "playerid", "email")

PY_BIN = sys.executable
CPP_BIN = shutil.which("g++") or shutil.which("c++") or shutil.which("clang++")
CS_BIN = shutil.which("dotnet")


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


def run_cpp(code):
    if not CPP_BIN:
        return {"ok": False, "error": "g++ ausente no host do bridge (instale build-essential)"}
    with tempfile.TemporaryDirectory(prefix="ark_cpp_") as td:
        src = os.path.join(td, "main.cpp")
        exe = os.path.join(td, "main")
        with open(src, "w", encoding="utf-8") as f:
            f.write(code)
        c = run_cmd([CPP_BIN, "-O2", "-std=c++17", "-o", exe, src], 25)
        if not c["ok"]:
            return {"ok": False, "out": c["out"], "error": "compilação: " + c["error"]}
        return run_cmd([exe], 10)


def run_csharp(code):
    if not CS_BIN:
        return {"ok": False, "error": "dotnet ausente no host do bridge (instale o .NET SDK)"}
    with tempfile.TemporaryDirectory(prefix="ark_cs_") as td:
        proj = os.path.join(td, "app")
        n = run_cmd([CS_BIN, "new", "console", "-o", proj, "--force"], 90)
        if not n["ok"]:
            return {"ok": False, "out": n["out"], "error": "dotnet new: " + n["error"]}
        with open(os.path.join(proj, "Program.cs"), "w", encoding="utf-8") as f:
            f.write(code)
        r = run_cmd([CS_BIN, "run", "--project", proj], 60)
        return r


def http_json(url, timeout=12):
    req = urllib.request.Request(url, headers={"User-Agent": "ArkherPyBridge/1.1"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def catalog_search(q, limit, cat):
    params = {"Keyword": q, "Limit": max(1, min(limit, 28))}
    if cat:
        params["Category"] = cat
    url = "https://catalog.roblox.com/v1/search/items/details?" + urlencode(params)
    try:
        data = http_json(url)
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "error": f"catalog API: {e}"[:300]}
    items = []
    for it in (data.get("data") or [])[:limit]:
        price = it.get("price")
        if price is None:
            pe = it.get("priceStatus") or it.get("lowestPrice") or 0
            price = pe if isinstance(pe, (int, float)) else 0
        items.append({
            "name": it.get("name") or "?",
            "id": it.get("id"),
            "creator": it.get("creatorName") or (it.get("creator") or {}).get("name") or "?",
            "price": price,
        })
    return {"ok": True, "items": items, "total": len(items)}


def catalog_info(aid):
    try:
        d = http_json(f"https://economy.roblox.com/v2/assets/{int(aid)}/details")
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "error": f"economy API: {e}"[:300]}
    return {"ok": True, "item": {
        "name": d.get("Name") or "?",
        "id": d.get("AssetId") or aid,
        "creator": d.get("Creator", {}).get("Name") if isinstance(d.get("Creator"), dict) else "?",
        "price": d.get("PriceInRobux") or 0,
    }}


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
                        "langs": ["py"] + (["cpp"] if CPP_BIN else []) + (["csharp"] if CS_BIN else []),
                        "auth": "token" if TOKEN else "localhost-only"})
            return
        if u.path == "/catalog/search":
            qq = q.get("q", [""])[0][:120]
            if not qq:
                self._send({"ok": False, "error": "q vazio"})
                return
            try:
                lim = max(1, min(int(q.get("limit", ["8"])[0]), 28))
            except ValueError:
                lim = 8
            self._send(catalog_search(qq, lim, q.get("cat", [""])[0][:8]))
            return
        if u.path == "/catalog/info":
            try:
                aid = int(q.get("id", ["0"])[0])
            except ValueError:
                aid = 0
            if aid <= 0:
                self._send({"ok": False, "error": "id inválido"})
                return
            self._send(catalog_info(aid))
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
                if lang in ("cpp", "c++"):
                    self._send(run_cpp(code))
                    return
                if lang in ("csharp", "c#", "cs"):
                    self._send(run_csharp(code))
                    return
                self._send({"ok": False, "error": f"lang '{lang}' desconhecida"})
                return
            self._send({"ok": False, "error": f"task desconhecida: {task}"})
            return
        self._send({"ok": False, "error": "404"}, 404)


if __name__ == "__main__":
    print(f"ArkherPyBridge {VERSION} na porta {PORT} "
          f"({'token ON' if TOKEN else 'localhost-only'}) "
          f"langs=py{'+cpp' if CPP_BIN else ''}{'+csharp' if CS_BIN else ''}", flush=True)
    HTTPServer(("0.0.0.0", PORT), H).serve_forever()
