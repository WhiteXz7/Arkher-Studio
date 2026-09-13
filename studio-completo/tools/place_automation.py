#!/usr/bin/env python3
"""
place_automation.py — AUTOMACAO DE PLACES ARKHER (Open Cloud, stdlib pura)
===========================================================================
Cria/lista/configura places de um universo via Roblox Open Cloud, de verdade
(requer API key com escopo universe-places; NADA aqui e simulado — sem chave
o script apenas mostra o dry-run honesto).

USO:
    export ROBLOX_API_KEY="sua-chave"
    export ROBLOX_UNIVERSE_ID="123456"
    python3 place_automation.py list
    python3 place_automation.py create --name "Terra - Regiao Norte" --desc "..."
    python3 place_automation.py update --place 987654 --name "Novo nome" --players 50
    python3 place_automation.py create --name X --dry-run   # so mostra o request

ENDPOINTS (Open Cloud v2, documentados em create.roblox.com/docs/cloud):
    GET   /cloud/v2/universes/{uid}/places
    POST  /cloud/v2/universes/{uid}/places
    PATCH /cloud/v2/universes/{uid}/places/{pid}
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://apis.roblox.com/cloud/v2"


def req(method, path, key, body=None, dry_run=False):
    url = BASE + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    if dry_run:
        print("[dry-run] %s %s" % (method, url))
        if body is not None:
            print(json.dumps(body, indent=2, ensure_ascii=False))
        return {"dryRun": True, "method": method, "url": url}
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("x-api-key", key)
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=30) as fh:
            raw = fh.read().decode("utf-8", "replace")
            return json.loads(raw) if raw.strip() else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:500]
        print("ERRO HTTP %s em %s %s:\n%s" % (e.code, method, url, detail),
              file=sys.stderr)
        sys.exit(2)
    except urllib.error.URLError as e:
        print("ERRO rede: %s" % e, file=sys.stderr)
        sys.exit(3)


def cmd_list(key, uid, args):
    path = "/universes/%s/places?pageSize=%d" % (uid, args.page_size)
    if args.page_token:
        path += "&pageToken=" + urllib.parse.quote(args.page_token)
    out = req("GET", path, key, dry_run=args.dry_run)
    if args.dry_run:
        return 0
    places = out.get("places", out if isinstance(out, list) else [])
    print("universe %s: %d place(s)" % (uid, len(places)))
    for p in places:
        name = p.get("universeDisplayName") or p.get("displayName") or "?"
        print("  %s  %s" % (p.get("placeId", p.get("name", "?")), name))
    if out.get("nextPageToken"):
        print("nextPageToken: %s" % out["nextPageToken"])
    return 0


def cmd_create(key, uid, args):
    body = {"universeDisplayName": args.name}
    if args.desc:
        body["universeDescription"] = args.desc
    if args.players:
        body["maxPlayerCount"] = args.players
    out = req("POST", "/universes/%s/places" % uid, key, body,
              dry_run=args.dry_run)
    if args.dry_run:
        return 0
    print("place criada: %s" % json.dumps(out, ensure_ascii=False)[:300])
    return 0


def cmd_update(key, uid, args):
    if not args.place:
        print("--place obrigatorio para update.", file=sys.stderr)
        return 1
    body = {}
    if args.name:
        body["universeDisplayName"] = args.name
    if args.desc:
        body["universeDescription"] = args.desc
    if args.players:
        body["maxPlayerCount"] = args.players
    if not body and not args.dry_run:
        print("nada para atualizar (use --name/--desc/--players).",
              file=sys.stderr)
        return 1
    mask = ",".join({"universeDisplayName": "universeDisplayName",
                     "universeDescription": "universeDescription",
                     "maxPlayerCount": "maxPlayerCount"}[k] for k in body)
    path = "/universes/%s/places/%s" % (uid, args.place)
    if mask:
        path += "?updateMask=" + urllib.parse.quote(mask)
    out = req("PATCH", path, key, body or {"note": "dry-run"},
              dry_run=args.dry_run)
    if args.dry_run:
        return 0
    print("place atualizada: %s" % json.dumps(out, ensure_ascii=False)[:300])
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Automacao de places (Open Cloud)")
    ap.add_argument("cmd", choices=["list", "create", "update"])
    ap.add_argument("--universe", default=os.environ.get("ROBLOX_UNIVERSE_ID"),
                    help="universeId (ou env ROBLOX_UNIVERSE_ID)")
    ap.add_argument("--key", default=os.environ.get("ROBLOX_API_KEY"),
                    help="API key (ou env ROBLOX_API_KEY)")
    ap.add_argument("--name", default="", help="nome da place/universo")
    ap.add_argument("--desc", default="", help="descricao")
    ap.add_argument("--players", type=int, default=0, help="max players")
    ap.add_argument("--place", default="", help="placeId (update)")
    ap.add_argument("--page-size", type=int, default=50)
    ap.add_argument("--page-token", default="")
    ap.add_argument("--dry-run", action="store_true",
                    help="mostra o request sem chamar a API")
    args = ap.parse_args(argv)
    if not args.universe:
        print("informe --universe ou ROBLOX_UNIVERSE_ID.", file=sys.stderr)
        return 1
    if not args.key and not args.dry_run:
        print("informe --key ou ROBLOX_API_KEY (ou use --dry-run).",
              file=sys.stderr)
        return 1
    if args.cmd == "list":
        return cmd_list(args.key, args.universe, args)
    if args.cmd == "create":
        if not args.name:
            print("--name obrigatorio para create.", file=sys.stderr)
            return 1
        return cmd_create(args.key, args.universe, args)
    return cmd_update(args.key, args.universe, args)


if __name__ == "__main__":
    sys.exit(main())
