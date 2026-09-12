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
- `lang=cpp/csharp` — stub honesto; fase 2 instala a toolchain (g++/dotnet)
  no host do bridge e habilita de verdade.
