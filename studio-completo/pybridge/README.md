# Arkher PyBridge — backend externo (Python/C++/C#)

Servidor de referência, **só stdlib** (sem `pip install`). O jogo chama ele via
`handlers.PyRun/PyStatus` (`server.lua` → `PY_URL`).

## Rodar local (para o Studio)

```bash
python3 pybridge.py            # porta 8773 (ou ARKHER_PY_PORT=xxxx)
```

No Studio: **Play Solo** → abra `Deck_py` → `STATUS` deve dizer online.
No Play Solo, `http://127.0.0.1:8773` alcança o SEU PC (o servidor de teste
roda na sua máquina). No jogo publicado, `127.0.0.1` não existe — hospede o
bridge e aponte o atributo do jogo:

```lua
-- command bar (1 vez, salva no place):
game:SetAttribute("ArkherPyUrl", "https://SEU-BRIDGE.exemplo.com")
```

## Hospedar grátis

Qualquer host Python serve (Render, Railway, Fly.io, VPS). Obrigatório:

```bash
export ARKHER_PY_TOKEN="um-segredo-longo"
python3 pybridge.py
```

e chame com `?token=um-segredo-longo` (o `server.lua` ainda não anexa o token —
fase 2; por enquanto o token protege execuções manuais/hosted).

Também ligue **Game Settings → Security → Enable Studio Access to API Services**
e **HTTP Requests** no jogo publicado.

## Privacidade (regra dura)

O bridge **NUNCA** recebe dados de player ou dev. Entram só `task/arg/code/lang`
anônimos. Campos `userId/playerName/accountName/...` são rejeitados com 400.

## Roadmap

- `lang=py` — funciona hoje (subprocesso com timeout).
- `lang=cpp` — real se `g++` instalado no host (`apt install build-essential`).
- `lang=csharp` — real se `dotnet` SDK instalado no host.
- Sem toolchain → erro honesto dizendo o que instalar.

## Cloud real (Open Cloud)

- `GET /cloud/places?universeId=...` → places reais do universo (conta real).
- `POST /cloud/export` `{name, tree}` → gera `.rbxlx` da cena e devolve o
  link de download (`/exports/arkher_<ts>.rbxlx`). Abra no Studio e publique
  de lá (caminho seguro, revisado por você).
- Publicação direta (opcional): crie a API key no Creator Dashboard com
  **universe-places + Write** no jogo e suba o bridge com:
  `ARKHER_ROBLOX_API_KEY=... ARKHER_AUTO_PUBLISH=1 ARKHER_UNIVERSE_ID=... ARKHER_PLACE_ID=...`
  → o export publica sozinho e devolve `{published, version}`.
- A key NUNCA passa pelo jogo: só existe no host do bridge.

## Catálogo (itens pagos)

- `GET /catalog/search?q=...&limit=8[&cat=...]` → busca na Creator Store
  (proxy p/ `catalog.roblox.com`, que o jogo não alcança direto).
- `GET /catalog/info?id=...` → nome/preço/criador (via `economy.roblox.com`).
- A compra em si é nativa no client (`MarketplaceService:PromptPurchase`).
