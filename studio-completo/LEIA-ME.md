# Arkher Studio — Sistemas integrados (100% funcional)

Este diretório contém a **placa `ArkherStudio_Completo.rbxl` com TODOS os sistemas
implementados por trás da UI** — inclusive os que antes estavam "Em desenvolvimento",
agora com **alternativas custom** (sem depender de Cloud API / Open API reais).

A UI é **idêntica** à placa original (1718 instâncias, 28 tipos, árvore e nomes
byte-idênticos); o que mudou é **apenas a fonte de 3 scripts** + um **ModuleScript**
(`ArkherServices`, criado em runtime no vault).

## Arquivos

| Arquivo | O que é |
|---|---|
| `ArkherStudio_Completo_Pro.rbxl` | **ENTREGA** — placa original + todos os sistemas (67.371 B) |
| `ArkherStudio_Completo.rbxl` | placa original (referência, intacta) |
| `scripts/server.lua` | servidor estendido (edição + **ARKHER SERVICES**) |
| `scripts/01_Nucleo.lua` | núcleo (menus, Command Bar, F5, lock, **roteia os sistemas p/ painéis**) |
| `scripts/03_Menus.lua` | menus + **painéis** (Data/Toolbox/Cloud/Publicar/Collab/Locale/Settings/Plugins) |
| `scripts/modules/arkher_services.lua` | **ModuleScript** `ArkherServices` (core custom: persistência + dados) |
| `tools/patch_rbxl.py` | troca as fontes dos scripts no `.rbxl` (lossless, ZSTD lvl15) |
| `tools/build_server.py` | gera `server.lua` (inserções, embute o module) |
| `tools/build_nucleo.py` | gera `01_Nucleo.lua` (11 edições cirúrgicas) |
| `tools/mock.lua` | mock Roblox (Lua) — agora com `require` + `JSONDecode` reais |
| `tools/test_server.lua` | 35 testes do servidor |
| `tools/test_server_services.lua` | 29 testes dos serviços (cloud/publish/data/i18n/toolbox/collab) |
| `tools/test_client.lua` | 18 testes do cliente (menus + roteamento) |
| `tools/test_client_panels.lua` | 27 testes dos painéis (UI dos sistemas) |
| `tools/run_tests.py` | roda os 4 testes (109 assertions) |

## Alternativas custom (contornam o que é difícil/bloqueado)

O difícil (Cloud API, Open API de publicar) é contornado por um **vault em
`ServerStorage/ArkherCloudVault`** que **persiste no próprio place** (fica "quebrado"
no `.rbxl` quando você salva). Assim tudo funciona **offline**, sem chave de API:

| Sistema | Alternativa custom |
|---|---|
| **Arkher Cloud** | Cópias do projeto serializadas em `Cloud/proj_*` (abrir/salvar/excluir). |
| **Publicar no perfil do dev** | Cria uma **página de jogo** (`Profile/game_*`) com URL `roblox.com/games/<id>/<slug>`, versão, visitas, visibilidade — **"igual o jogo no perfil do Dev"**, sem Open API. |
| **Data** | DataStore custom: entradas chave/valor (string/number/boolean) em `Data/`. |
| **Localização** | Tabela de strings + 6 idiomas (pt-BR/en/es/fr/de/ja), idioma ativo persistido. |
| **Settings (completas)** | Metadados do projeto (nome/gênero/visibilidade/máx. jogadores) + Gravity do Workspace. |
| **Toolbox** | Biblioteca de templates (Geometria/Iluminação/Jogo/Scripts) inseridos no place, desfazível. |
| **Colaboração** | Equipe (papéis Owner/Editor/Viewer) + convites por e-mail (gerar/aceitar/rejeitar). |
| **Plugins** | Central que lista/abre todos os sistemas. |

## O que foi AQUI (o que a placa NÃO tinha)

### Menus (dropdowns reais com itens funcionais)
- **File** — Novo, Abrir (Baseplate/vazio/Terrain), **Salvar & Publicar (abre o diálogo
  de publish)**, **Salvar na Cloud (abre o painel Arkher Cloud)**, Exportar/Importar (JSON),
  Configurações, Sair.
- **Edit** — Desfazer, Refazer, Cortar, Copiar, Colar, Duplicar, Renomear, Excluir (server).
- **View** — Hierarchy, Properties, Tela cheia, Restaurar layout.
- **Insert** — Part, Folder, Model, Script, TextLabel, Seletor completo.
- **Run** — Play / Pause / Stop (lock de edição em execução).
- **Game** — Configurações do jogo, Propriedades, Reiniciar Workspace, **Publicar**.
- **Topos** — Collaborate, Invites, Changes (histórico real), Account.

### Botões de sistema → painéis (antes só "Em desenvolvimento")
Cada botão da barra agora abre um **painel real**:
`Data`, `Toolbox`, `ArkherCloud`/`SaveToArkher`, `CollaborationSettings`, `Localization`,
`Settings`, `PluginToolbar`.

### Servidor
- Edição: **Undo/Redo**, **Copy/Cut/Paste/Duplicate**, **Rename**, **New/Open** (templates),
  **Export/Import** (JSON), **GetHistory**.
- **ARKHER SERVICES** (handlers): `CloudStatus/Save/Open/List/Delete`, `Publish`,
  `ProfileList/Get/Delete`, `DataList/Get/Set/Delete`, `ProjectInfo/SetProjectInfo`,
  `TeamInfo/Add/Remove`, `InviteList/Create/Accept/Reject`, `Locales/SetLocale/
  LocStrings/SetLocString`, `ToolboxList/ToolboxInsert`.

### ModuleScript `ArkherServices`
O core dos serviços roda como **módulo** (require pelo server) que **gerencia o vault**:
conta, cloud, perfil, dados, projeto, equipe/convites, localização, catálogo do toolbox.
Todo dado aninhado vai em **atributo STRING (JSON)** → persiste no place.

### Núcleo (cliente)
- **Command Bar executa Luau de verdade** (`loadstring`).
- **F5** = Play/Stop. **Lock de execução**.
- **Roteia os 7 botões de sistema** para os painéis + tooltips agora mostram a função real.

## Testes (fora do Studio, via mock Lua)
```
python3 studio-completo/tools/run_tests.py
# Server:            35 passaram, 0 falharam
# Arkher Services:   29 passaram, 0 falharam
# Cliente (menus):   18 passaram, 0 falharam
# Cliente (painéis): 27 passaram, 0 falharam
# TODOS OS TESTES PASSARAM
```

## Como a placa é gerada
```
python3 studio-completo/tools/build_server.py     # server.lua (embute o module)
python3 studio-completo/tools/build_nucleo.py     # 01_Nucleo.lua
python3 studio-completo/tools/patch_rbxl.py ArkherStudio_Completo.rbxl ArkherStudio_Completo_Pro.rbxl \
  "Script:ArkherEditorServer=studio-completo/scripts/server.lua" \
  "LocalScript:Arkher_01_Nucleo=studio-completo/scripts/01_Nucleo.lua" \
  "LocalScript:Arkher_02_Icones=studio-completo/scripts/02_Icones.orig.lua" \
  "LocalScript:Arkher_03_Menus=studio-completo/scripts/03_Menus.lua" \
  "LocalScript:Arkher_04_Gizmos=studio-completo/scripts/04_Gizmos.orig.lua"
```

---

## 🆕 ARKHER X embutido (build `ArkherStudio_Completo_X.rbxl`)

Gerado por `tools/inject_arkherx.py` a partir da placa Pro, de forma **100% aditiva**:
a GUI original fica **byte-a-byte idêntica** (138/146 chunks preservados exatos;
os 8 restantes são os mesmos chunks com *appends* — prova automática no injetor).

Nós injetados (modelo nativo Roblox, anti-exploiter):

| Onde | O quê |
|---|---|
| `ServerStorage/ArkherEngines/` | `ArkherX_DM/ATX/AWX/ASXN/AAX/AUX/AEX/APX/RPX` (9 ModuleScripts — motores v3 inteiros) |
| `ServerScriptService/ArkherEngineServer` | Script ponte: comandos, pumps Heartbeat (AEX/AAX+AUX/LOD), remotes |
| `ReplicatedStorage/ArkherNet/` | **só a ponte**: `ArkherXCmd` (RemoteEvent) + `ArkherXQ` (RemoteFunction) |
| `StarterGui/ArkherStudioUI/Arkher_05_StudioX` | LocalScript NOVO — dock X com 8 editores (TERRAIN/WATER/SCENE/ATMOS/ROPE/PX/ANIM/STATS) no tema original, **ícones desenhados em Frames** (linhas/maisons, zero imagens) |

**FIX (2026-09):** placa X dava `PROP.LocalScript.Disabled bool 4/5 → read offset out of bounds`
no Studio — o injetor agora estende **todo** PROP de qualquer tipo que ganhou
instância (bool=0, string/int/float=0 …) e VALIDA que `#valores == #instâncias`
em cada um dos 121 chunks PROP (#StudioSafe). Baixe novamente a placa atual.

**RIG X + MESH X (novos, nível Cascadeur++/Blender++):**
- `studio-v3/core/rigx.luau` — FABRIK multi-iteração com pole target, CCD,
  física de equilíbrio por COM projetado em polígono de suporte (estilo
  Cascadeur), locomotion procedural por intenção, keyframes Catmull-Rom,
  ghost/onion ring e spring secundário por osso — **ao vivo no Heartbeat**.
- `studio-v3/core/meshx.luau` — soup vértice/face, geradores (box/plane/
  cilindro/prisma/icosaedro+subdiv), extrude/inset/bevel/subdivide(Catmull-Clark
  simplificado)/knife(Sutherland-Hodgman)/espelho/weld/ponte, **boolean convexo
  REAL por recorte de semi-espaços (sem CSG service)**, bake auto em
  EditableMesh→wedges→wireframe-neon. Demos: casa com janelas porta booleanas,
  engrenagem dentada, cristal, mesa com displacement.
- `Arkher_06_RigX` + `Arkher_07_MeshX`: painéis que se ACOPLAM ao dock do
  05 (sem alterá-lo), mesmo tema, ícones desenhados (palito-rig, cubo-wire).

Regerar: `python3 tools/inject_arkherx.py ../ArkherStudio_Completo_Pro.rbxl ../ArkherStudio_Completo_X.rbxl` → valida 1733 inst, 32 tipos, PRNT/END corretos. Testes: `python3 tools/run_tests.py` (109+ asserts, 27 painéis).


**FIX round 2 (2026-09, log de Play do usuário):**
- `03_Menus label()` aceitava só UDim2 mas ~26 chamadores passam números
  (x,y,w,h[,fs],color) → crash "UDim2 expected, got number". Helper agora é
  bi-modal (detecta typeof) — visual idêntico, modais/menus voltam a abrir.
- `ArkherEditorServer` escrevia `Source` em runtime (proibido fora de plugin)
  → serviços nunca subiam e o assert vazava pro console. Loader patchado:
  pula a escrita quando o módulo já tem Source (o injetor agora EMBARCA
  `ArkherServices` dentro de `ServerStorage/ArkherCloudVault` — capability
  free) e o write cai num pcall à prova de spam.
- `ArkherEngineServer` ganhou PROBE anti-drop: se `ArkherEngines` sumir de
  novo, loga o inventário real de ServerStorage/ReplicatedStorage. Placa X:
  1739 inst (+21) — inclui Folder ArkherCloudVault + ModuleScript ArkherServices.
