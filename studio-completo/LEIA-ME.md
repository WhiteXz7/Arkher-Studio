# Arkher Studio — Sistemas integrados (completo)

Este diretório contém a **placa `ArkherStudio_Completo.rbxl` com todos os sistemas
implementados por trás da UI**. A UI é **idêntica** à placa original (1718 instâncias,
28 tipos, árvore e nomes byte-idênticos); o que mudou é **apenas a fonte de 3 scripts**:
o servidor, o núcleo (cliente) e os menus.

## Arquivos

| Arquivo | O que é |
|---|---|
| `ArkherStudio_Completo_Pro.rbxl` | **ENTREGA** — placa original + sistemas novos (55.964 B) |
| `ArkherStudio_Completo.rbxl` | placa original (referência, intacta) |
| `scripts/server.lua` | servidor estendido (Undo/Redo/Copy/Paste/Export/Import/New/Open) |
| `scripts/01_Nucleo.lua` | núcleo estendido (dispatch dos menus, Command Bar, F5, lock de execução) |
| `scripts/03_Menus.lua` | menus completos (File/Edit/View/Insert/Run/Game + topos) |
| `tools/patch_rbxl.py` | troca as fontes dos scripts no `.rbxl` (lossless, ZSTD lvl15) |
| `tools/build_server.py` | gera `server.lua` a partir do original (inserções) |
| `tools/build_nucleo.py` | gera `01_Nucleo.lua` (edições cirúrgicas) |
| `tools/mock.lua` | mock Roblox (Lua) p/ testar fora do Studio |
| `tools/test_server.lua` | 35 testes do servidor |
| `tools/test_client.lua` | 18 testes do cliente (menus + roteamento ao server) |
| `tools/run_tests.py` | roda todos os testes |

## O que foi AQUI (o que a placa NÃO tinha)

### Menus (dropdowns reais com itens funcionais)
A MenuBar tinha só **File** e **Insert** abertos. Agora **todos** abrem dropdowns:

- **File** — Novo, Abrir (Baseplate/vazio/Terrain), Salvar & Publicar, Salvar na Cloud,
  **Exportar (JSON)**, **Importar (JSON)**, Configurações do projeto, Sair.
- **Edit** — **Desfazer, Refazer, Cortar, Copiar, Colar, Duplicar, Renomear, Excluir** (server).
- **View** — Hierarchy, Properties, Tela cheia, Restaurar layout.
- **Insert** — Part, Folder, Model, Script, TextLabel, Seletor completo.
- **Run** — **Play / Pause / Stop** (modo de execução com lock de edição).
- **Game** — Configurações do jogo (dialog real: Gravity/Brilho/Hora), Propriedades,
  Reiniciar Workspace, Publicar.
- **Topos** — Collaborate, Invites, **Changes (histórico real)**, Account.

### Servidor (novo poder de edição)
Handlers novos no `ArkherEditorServer`, testados:
- **Undo/Redo** (histórico por jogador, 50 passos, undo de criar/excluir/editar/transformar).
- **Copy/Cut/Paste/Duplicate** (clipboard via `Instance:Clone()`).
- **Rename** (com histórico).
- **New / Open** (templates: Empty/Baseplate/Flat/Terrain).
- **Export / Import** (serializa/deserializa o Workspace p/ JSON, com validação de classe).
- **GetHistory** (lista de alterações p/ o menu Changes).

### Núcleo (cliente)
- **Command Bar executa Luau de verdade** (`loadstring`) — era "não executa código".
- **F5** = Play/Stop.
- **Lock de execução**: em modo Play, o editor bloqueia mover/criar/excluir.
- Os botões implementados saíram do estado "Em desenvolvimento".

## O que ainda está marcado "Em desenvolvimento" (honesto)
Publicação via Open API (Save no Roblox), Save na Arkher Cloud real, Data, Localization,
Settings (ribbon), Toolbox, CollaborationSettings, ArkherCloud, PluginToolbar. A
arquitetura já isola servidor/cliente para escalar.

## Testes (fora do Studio, via mock Lua)
```
python3 studio-completo/tools/run_tests.py
# Server: 35 passaram, 0 falharam
# Cliente: 18 passaram, 0 falharam
```
Cobrem: criar/desfazer/refazer, excluir/desfazer, copiar/colar/duplicar, renomear,
editar+desfazer, exportar/importar (JSON), new/open (templates), build dos 6 menus,
acões roteadas ao server, toggle de painéis, Play/Stop, dialog de settings.

## Como a placa é gerada
```
python3 studio-completo/tools/build_server.py     # server.lua
python3 studio-completo/tools/build_nucleo.py     # 01_Nucleo.lua
python3 studio-completo/tools/patch_rbxl.py ArkherStudio_Completo.rbxl ArkherStudio_Completo_Pro.rbxl \
  "Script:ArkherEditorServer=studio-completo/scripts/server.lua" \
  "LocalScript:Arkher_01_Nucleo=studio-completo/scripts/01_Nucleo.lua" \
  "LocalScript:Arkher_02_Icones=studio-completo/scripts/02_Icones.orig.lua" \
  "LocalScript:Arkher_03_Menus=studio-completo/scripts/03_Menus.lua" \
  "LocalScript:Arkher_04_Gizmos=studio-completo/scripts/04_Gizmos.orig.lua"
```
