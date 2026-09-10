# ARKHER V3 — UES COMPLETA MAS NO ROBLOX

Reconstrução do ARKHER do zero. O V2 parou em 41 clones do mesmo template de UI;
o V3 é outra arquitetura: **24 UIs desenhadas de verdade** (cada uma com layout,
acentos e widgets próprios) e **todo o core roda testado** — 55 verificações em 2
fases, incluindo o fluxo real de instalação (ModuleScripts + `require`).

## O que o ARKHER é
- **Criar places como no Roblox Studio**: 6 menus reais, ribbon de ferramentas,
  hierarquia ao vivo, inspector de propriedades ao vivo, status bar,
  **command palette (Ctrl+K)** com busca viva de UIs + todos os comandos,
  atalhos WASD/Q/E, undo/redo 50 níveis.
- **Publish sem Open API / Cloud API**: `ArkherPublish` serializa o place num
  bundle `.arkher.lua` e publica para o **Arkher Cloud local**
  (`ServerStorage.ArkherCloud`). Endpoint opcional em Settings > Cloud.
- **Singularity (IA local)**: `ARKHER_SINGULARITY.run("crie uma cidade com npc e otimize")`
  → planner de intent → 10 especialistas locais (place/cidade/natureza/espaço/
  material/luz/npc/clean/perf/diagnóstico) → execução REAL no Roblox + relatório.
- **NMN**: mentes com percepção/precisões/memória em grid espacial
  (`ArkherNMN.spawn/why/report` — causalidade: "por que este NPC fez X?").
- **D-O15**: diretiva de performance de 5 níveis que mede FPS real e degrada
  upgrades automaticamente (`Bus.emit("do15.nudge", n)`).
- **Place Cloud**: new/save/open/delete/export/restore com roundtrip JSON verificado.

## As 24 UIs (cada uma ÚNICA)
| UI | Layout característico |
|---|---|
| Animator | lista de poses + preview do personagem + **keytracks** de timeline + scrub |
| Modeler | paleta vertical de ferramentas + **malha low-poly com vertices clicáveis** + UV grid |
| Terrain | pincelais + **heightmap 8x8 interativo** (clique aplica o pincel) + biomas |
| Script | editor com números de linha, tabs de classe, lint, **cria Script de verdade no place** |
| Particles | **grafo de nós** (estilo Nuke/Blender) com fios + knobs |
| Camera | modos de vista + **cone de FOV que muda** com +/− + knobs |
| Lighting | **faixa de hora do dia clicável** (mexe o céu e o sol no preview) + knobs |
| Audio | faixas com **waveforms** + **mixer de verticais** + seek |
| Physics | **grid de colisão interativo** (clique liga/desliga) + joints |
| UI Designer | paleta de widgets + **canvas com grade** + inspector de estilo |
| Map | **minimapa com POIs clicáveis** + legenda + exportação real |
| City | grid de distritos + skyline + **geração com IA real** |
| NPCs | **árvore real das mentes NMN** + monitor de percepção + painel "POR QUÊ?" (causalidade real) |
| Performance | **gauge D-O15 de 5 níveis** (estado real) + FPS + nudges via Bus |
| Console | **log real do ARKHER** com filtros + append ao vivo + exportar |
| Settings | seções: qualidade, **cloud (endpoint real)**, aparência, atalhos |
| Cloud | **lista real de places** com abrir/apagar + storage |
| AI (Singularity) | objetivo + chips + **execução real** + relatorio + historico |
| Publish | **preview do manifest** + pipeline local/endpoint/nativo + historico real |
| Save & Open | salvamento rapido + recentes + autosave |
| Export | formatos + **print-map 2D desenhado a partir do workspace real** |
| Open | busca + **grid de thumbnails** + detalhes |
| About | emblem + **sistemas e contadores em tempo real** |
| Command Palette | (Ctrl+K) **busca viva** de UIs + todos os comandos, nascida oculta |

## Arquitetura (para caber no limite de 100K chars do Studio)
```
ReplicatedStorage.ArkherV3/
├── ArkherKit_A (ModuleScript)  prelude + do15 + undo + publish + nmn   (~65K)
└── ArkherKit_B (ModuleScript)  places + actions + singularity + live + boot (~62K)
                                 (requer o Kit A)

LocalScripts (launchers finos, ~4-52K):
├── ArkherStudio_MainUI         shell + command palette
├── UI_Bundle_Editors           Animator/Modeler/Terrain/Script/Particles
├── UI_Bundle_Scene             Camera/Lighting/Audio/Physics/UIDesigner/Map
├── UI_Bundle_System            City/NPCs/Performance/Console/Settings/Cloud/AI/Publish/
│                               SaveOpen/Export/Open/About
└── UI_<Nome> (x24)             uma UI individual, autocontida
```
Globals vazam entre modules (comportamento do Roblox): o Kit A define `ARKHER`,
`Bus` etc.; o Kit B e os launchers os usam. `require` com cache — cada module
executa uma vez; `ARKHER.boot()` é idempotente.

## Instalar no Roblox Studio

**Caminho 1 (recomendado) — abrir o place completo:**
`commandbar/arkher-v3.rbxl` já é o place inteiro: **90 services** com cada
script no seu devido serviço — ReplicatedFirst (S0), ServerScriptService
(S1 Boot + installers), ServerStorage (ArkherData + ArkherCloud),
StarterPlayerScripts (engine + 24 UIs), **StarterCharacterScripts** (C0),
StarterGui (UI original do V2), **StarterPack** (ArkherTool),
**NetworkClient** (N0 legado), **SoundService** (SFX), **Lighting**
(Atmosphere + ColorCorrection), **Teams** (ARKHER), **TestService**
(T0 self-test), **Workspace** (Spawn) — além de **todo o catálogo V2**
(`ReplicatedStorage.ARKHER`: 290.000 customs + 333 generated +
core/editors/maps/systems/ui — 290.361 fontes byte-idênticas ao V2).
290.617 instâncias no total. `File > Open` e pronto.
Detalhes em `commandbar/estrutura-completa/LEIA-ME.md`.

**Caminho 2 — Command Bar num place existente:**
`commandbar/estrutura-completa/CB_UI_StarterGui.lua` (View > Command Bar >
colar tudo > Run) recria a UI original do V2 no `StarterGui.ARKHER_Studio`
(88 instâncias, 570 propriedades — fiel). A engine V3 vai junto dentro do
`.rbxl` (ou, em place avulso, use os CBs de legado `estrutura-completa/CB01…CB13`).

**Caminho 3 — paste manual dos 6 scripts da engine** (sem o .rbxl):
Rode `./build.sh` e cole, na ordem:
1. `commandbar/ArkherKit_Installer_A.lua` → num **Script** (cria o ModuleScript Kit A)
2. `commandbar/ArkherKit_Installer_B.lua` → num **Script** (cria o ModuleScript Kit B)
3. `commandbar/ArkherStudio_MainUI.lua` → num **LocalScript** (abre o shell)
4. `commandbar/UI_Bundle_Editors.lua` → **LocalScript**
5. `commandbar/UI_Bundle_Scene.lua` → **LocalScript**
6. `commandbar/UI_Bundle_System.lua` → **LocalScript**

Alternativa: cole `UI_<Nome>.lua` individuais em vez dos bundles.

## Estrutura do código
```
studio-v3/
├── src/
│   ├── prelude.luau      # kit ARKHER: tema, widgets (K.*), ícones, Bus,
│   │                     #   ARKHER.cmd, registry de UIs
│   ├── ui/
│   │   ├── main.luau     # shell: 6 menus, ribbon, toolbar, inspector,
│   │   │                 #   hierarquia, status bar (CoreGui)
│   │   └── <23 uis>.luau # cada UI: ARKHER.reg(nome, titulo, cat, icone, desc, build)
│   └── driver_all.luau   # boot + shell + openAll (usado no build de teste)
├── core/
│   ├── places.luau       # criar/salvar/abrir/apagar/exportar/restore
│   ├── undo.luau         # pilha de snapshots (50 níveis, guard de reentrância)
│   ├── live.luau         # inspector + hierarquia ao vivo
│   ├── do15.luau         # D-O15 performance (5 níveis)
│   ├── singularity.luau  # IA local: planner + 10 especialistas
│   ├── nmn.luau          # mentes (grid espacial, causalidade)
│   ├── publish.luau      # publish local + endpoint opcional (sem Open API)
│   └── actions.luau      # registro central de comandos (ARKHER.cmd)
├── build.sh              # gera commandbar/ (32 artefatos, todos < 66K)
└── tests/
    ├── shim.lua          # simulador de API Roblox (inclui require p/ ModuleScript)
    ├── verify.lua        # fase 1: 46 checagens sobre o build unico
    ├── kitflow.lua       # fase 2: fluxo real de instalação (kits + launchers)
    └── run.py            # runner (lupa): build + 2 fases, sai 1 se algo falha
```

## Comandos (ARKHER.cmd)
Menus, atalhos, palette e a IA usam o **mesmo** registro — nenhum botão é
decorativo. Exemplos: `place.new`, `place.open`, `insert.part`, `tool Move`,
`edit.delete`, `file.save`, `file.export`, `publish.local`, `ui.open <Nome>`,
`undo.push`, `view.palette`.

## Testes
```
cd studio-v3
python3 tests/run.py
```
- **Fase 1 (ALL)**: core + shell + 24 UIs num build único → 46 checagens
  (places roundtrip, undo/redo, singularity, NMN, publish, inspector, ações,
  D-O15, contagem e montagem das UIs).
- **Fase 2 (kitflow)**: runtime limpo; cria os 2 ModuleScripts e executa os
  launchers reais via `require` — 9 checagens (instalação, cache, bundles,
  UI individual).
