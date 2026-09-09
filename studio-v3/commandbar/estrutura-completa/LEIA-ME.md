# ARKHER V3 — ESTRUTURA COMPLETA (Command Bar)

Estes **13 scripts de paste & run** constroem a estrutura COMPLETA do ARKHER V3
dentro do seu place — os **33 scripts do repositório** viram instâncias reais nos
services corretos, do jeito igual da print do Studio.

| Arquivo | O que cria |
|---|---|
| `CB01.lua` | `ReplicatedStorage.ArkherV3.ArkherKit_A` (ModuleScript) |
| `CB02.lua` | `ReplicatedStorage.ArkherV3.ArkherKit_B` (ModuleScript) |
| `CB03.lua` | `StarterPlayerScripts.Arkher.ArkherMainUI` + `ArkherBundle_Editors` (LocalScripts ativos) |
| `CB04.lua` | `StarterPlayerScripts.Arkher.ArkherBundle_Scene` (LocalScript ativo) |
| `CB05.lua` | `StarterPlayerScripts.Arkher.ArkherBundle_System` (LocalScript ativo) |
| `CB06.lua` | `StarterPlayerScripts.Arkher.Panels` — 12 painéis (UI_AI … UI_Modeler), LocalScripts **desativados** |
| `CB07.lua` | `StarterPlayerScripts.Arkher.Panels` — 12 painéis (UI_NPCs … UI_UIDesigner), LocalScripts **desativados** |
| `CB08.lua` | `ServerScriptService.Arkher.ArkherKit_Installer_A` (Script **desativado**) |
| `CB09.lua` | `ServerScriptService.Arkher.ArkherKit_Installer_B` (Script **desativado**) + `ServerStorage.ArkherData` (Folder) |
| `CB10.lua` | `ReplicatedStorage.ArkherV3.ALL.ALL_P1` (ModuleScript — chunk 1/3 do ArkherStudio_ALL, 251 KB) |
| `CB11.lua` | `ReplicatedStorage.ArkherV3.ALL.ALL_P2` (ModuleScript — chunk 2/3) |
| `CB12.lua` | `ReplicatedStorage.ArkherV3.ALL.ALL_P3` (ModuleScript — chunk 3/3) |
| `CB13.lua` | `StarterPlayerScripts.Arkher.ArkherALL_Assemble` (LocalScript **desativado** — junta os 3 chunks e roda o ALL completo) |

## Por que o ALL fica em 3 chunks?
`ArkherStudio_ALL.lua` tem **250.993 chars** — passa do limite de ~100 KB de
`Script.Source` do Roblox. Por isso ele é dividido em 3 ModuleScripts
(`ALL_P1/P2/P3`) e o `ArkherALL_Assemble` faz:

```lua
local src = require(ALL_P1) .. require(ALL_P2) .. require(ALL_P3)
loadstring(src)()
```

A concatenação reconstrói o arquivo **byte a byte** (validado).

## Como rodar (passo a passo)

1. Abra o **place destino** no Roblox Studio.
2. Menu **View → Command Bar** (no topo do Studio).
3. Cole o conteúdo **inteiro** de `CB01.lua` na Command Bar e aperte **Run**.
4. Repita **na ordem CB01 → CB13** (cada um imprime `[ARKHER V3] (x/13) ...`).
5. Pronto — Hierarchy mostra a estrutura completa:

```
game
├─ ReplicatedStorage
│  └─ ArkherV3
│     ├─ ArkherKit_A            (ModuleScript)
│     ├─ ArkherKit_B            (ModuleScript)
│     └─ ALL
│        ├─ ALL_P1 / ALL_P2 / ALL_P3   (ModuleScripts)
├─ StarterPlayer
│  └─ StarterPlayerScripts
│     └─ Arkher
│        ├─ ArkherMainUI         (LocalScript, ativo)
│        ├─ ArkherBundle_Editors (LocalScript, ativo)
│        ├─ ArkherBundle_Scene   (LocalScript, ativo)
│        ├─ ArkherBundle_System  (LocalScript, ativo)
│        ├─ ArkherALL_Assemble   (LocalScript, desativado)
│        └─ Panels
│           └─ 24 × UI_*         (LocalScripts, desativados)
├─ ServerScriptService
│  └─ Arkher
│     ├─ ArkherKit_Installer_A   (Script, desativado)
│     └─ ArkherKit_Installer_B   (Script, desativado)
└─ ServerStorage
   └─ ArkherData                 (Folder — namespace de dados server)
```

## Depois de rodar

- **Testar um painel**: `Panels > UI_X` → marque **Enable** (um por vez — cada UI é independente).
- **Rodar o ALL completo**: `Arkher > ArkherALL_Assemble` → **Enable** → aperte **F5**.
- **Reinstalar/atualizar**: rode de novo o CB desejado — é **idempotente** (atualiza o `Source` sem duplicar nada).
- Os installers em `ServerScriptService.Arkher` ficam **desativados** de propósito
  (servem como backup do código dos kits no lado server).

## Alternativa: abrir o .rbxl direto

`arkher-v3.rbxl` (aqui na pasta do repositório: `commandbar/arkher-v3.rbxl`)
já contém **exatamente** esta estrutura — 81 instâncias, mesmas 33 fontes
byte a byte, mesma tree acima. Dá pra `File > Open` em vez de colar os 13.
(Se preferir o caminho Command Bar, é o que você pediu — e o .rbxl serve
de espelho/backup.)

## Validações feitas (2026-09-09)

- [x] Simulação em stub do Roblox (lupa/LuaJIT): os 13 scripts executam sem erro
- [x] 37/37 verificações da árvore criada (classe, nome, parent, `Disabled`, source byte a byte)
- [x] `ALL_P1 + ALL_P2 + ALL_P3` == `ArkherStudio_ALL.lua` (250.993 chars, idêntico)
- [x] Sintaxe Lua dos 13 scripts (compilador Lua)
- [x] `.rbxl`: round-trip 100% (decode → 81 instâncias → todas as fontes idênticas)
- [x] Nenhum script passa de 85.000 chars (limite prático da Command Bar)
