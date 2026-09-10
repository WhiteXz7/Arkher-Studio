# ARKHER V3 — ENTREGA COMPLETA

Dois artefatos, dois caminhos:

| Artefato | O que é | Como usar |
|---|---|---|
| **`commandbar/arkher-v3.rbxl`** | **O place completo** — abre e já é o ARKHER inteiro: **90 services** com cada script no seu devido serviço, **todo o catálogo V2 (290.000 customs + 333 generated + core/editors/maps/systems/ui)**, a engine V3 (kits + ALL + 24 UIs), a UI original do V2 no `StarterGui`, o Tool, o personagem, o sound, o lighting, o Team e o boot. | `File > Open` no Roblox Studio. Fim. |
| **`estrutura-completa/CB_UI_StarterGui.lua`** | **A única Command Bar**: um script que gera **toda a UI original do V2** no `StarterGui.ARKHER_Studio` (88 instâncias, 570 propriedades — fiel ao arquivo do V2, a mesma UI que o script original do V2 fez). | Num place que já tem a estrutura: `View > Command Bar` > cole **tudo** > `Run`. |

> Os 13 scripts `CB01.lua … CB13.lua` desta pasta são **legado** da entrega
> anterior (montar a engine V3 por paste). Eles ficaram para histórico — o
> `.rbxl` já contém tudo que eles criavam, no service certo de cada um.

## Estrutura do place (`arkher-v3.rbxl` — 290.617 instâncias)

**90 services** + 290.461 instâncias do V2 + 66 novas da V3. Cada script na
casa certa:

```
game
├─ ReplicatedFirst
│  └─ Arkher_S0_First              (Script — roda ANTES de tudo: cria os
│                                    contêineres em ServerStorage + Remotes)
├─ ReplicatedStorage
│  ├─ ARKHER ·················································  290.369 instâncias
│  │  ├─ customs/    290.000 × ARKHER_CUST_NNNN   (o catálogo — os "milhares de sistemas")
│  │  ├─ generated/          333 módulos
│  │  ├─ editors/               9
│  │  ├─ ui/                   12
│  │  ├─ systems/               4
│  │  ├─ core/                  2   (config + theme)
│  │  └─ maps/                  1   (world_map)
│  └─ ArkherV3 ·········································· engine V3 (33 fontes do repo)
│     ├─ ArkherKit_A / ArkherKit_B   (ModuleScripts)
│     ├─ ALL/ALL_P1 · ALL_P2 · ALL_P3   (ArkherStudio_ALL em 3 chunks — limite 100K)
│     └─ Remotes/ArkherPublish · ArkherData   (RemoteEvents — publish + data)
├─ ServerScriptService
│  ├─ ARKHER_Boot            (Script V2, ativo)
│  ├─ Arkher_S1_Boot         (Script V3 — server principal: Remotes,
│  │                             PUBLISH → ArkherCloud.Published, DATA,
│  │                             habilita os installers)
│  └─ Arkher/ArkherKit_Installer_A · _B   (Scripts desativados — backup)
├─ ServerStorage
│  ├─ ArkherData             (Folder — profile por jogador)
│  └─ ArkherCloud            (Folder — "nuvem" local do ARKHER, SEM Open API)
│     ├─ Published           (bundles publicados: ValueString + manifest)
│     └─ Backups
├─ StarterPlayer
│  ├─ StarterPlayerScripts
│  │  ├─ ARKHER_HUD          (LocalScript V2, ativo)
│  │  └─ Arkher
│  │     ├─ ArkherMainUI · ArkherBundle_Editors · _Scene · _System   (ativos)
│  │     ├─ ArkherALL_Assemble          (desativado — junta os 3 chunks e roda o ALL)
│  │     └─ Panels/  24 × UI_*          (desativados — enable um por vez)
│  └─ StarterCharacterScripts
│     └─ Arkher_C0_Character   (LocalScript — roda por personagem: expõe
│                                model/humanoid/root em _G.ARKHER_CHAR)
├─ StarterGui
│  └─ ARKHER_Studio          (ScreenGui — UI original do V2: 88 instâncias, tudo fiel)
├─ StarterPack
│  └─ ArkherTool             (Tool — Handle Part + ToolUI: apertar Use abre o
│                               command palette do ARKHER)
├─ NetworkClient
│  └─ Arkher_N0_Legacy       (LocalScript — canal legado de rede: latência
│                               suavizada + status em _G.ARKHER_NET)
├─ SoundService
│  └─ ArkherSfx              (Folder — Click · Success · Error: 3 Sounds)
├─ Lighting
│  ├─ ArkherAtmos            (Atmosphere — cor ARKHER)
│  └─ ArkherGrade            (ColorCorrectionEffect — o "look" do ARKHER)
├─ Teams
│  └─ ARKHER                 (Team — TeamColor)
├─ TestService
│  └─ Arkher_T0_SelfTest     (Script desativado — habilite para rodar o
│                               self-test da estrutura: imprime [ARKHER] T0: 9/9)
└─ Workspace
   ├─ Ground                 (Part do V2)
   └─ Arkher/Spawn           (SpawnLocation — ponto de spawn do ARKHER)
```

Os demais services (DataStoreService, HttpService, PathfindingService,
AvatarStoreService, MemoryStoreService, MessagingService, CoreGui, etc.)
estão presentes e vazios, prontos para uso — 90 no total.

### Os sistemas/features do V2

O catálogo `ReplicatedStorage.ARKHER` é a V2 inteira decodificada do
`ARKHER_V2.rbxl`: **290.361 fontes byte-idênticas** (validadas por sha1),
sendo 290.000 customs + 333 generated + core/editors/maps/systems/ui. O
manifest da V2 (`ARKHER_MANIFEST.json`) indexa **17.188 sistemas nomeados**
em 30 categorias e 290.271 features — todos dentro do `.rbxl`.

### Como o publish funciona (sem Open API)

1. O client (UI Publish) envia `{Name, Bundle}` via
   `ReplicatedStorage.ArkherV3.Remotes.ArkherPublish`.
2. `Arkher_S1_Boot` (ServerScriptService) grava o bundle em
   `ServerStorage.ArkherCloud.Published.<name>` + `<name>_manifest`
   (name/author/data/tamanho). É a **Arkher Cloud local** — o servidor é a
   nuvem; nada passa pela Open API do Roblox.
3. Profiles de jogador vão para `ServerStorage.ArkherData.<player>` via
   o RemoteEvent `ArkherData` (S0 também cria a pasta por UserId ao entrar).

### Como a UI original funciona

No V2, a UI `StarterGui.ARKHER_Studio` já vem criada no place (estática) e o
`ARKHER_HUD` (StarterPlayerScripts) a usa/move no runtime. O
`CB_UI_StarterGui.lua` recria **exatamente** essa árvore estática (mesma
classe, nome, parent, cor, tamanho, posição, fonte e alinhamento de cada
instância) — útil para injetar a UI num place que não tem o `.rbxl` completo.

## Validações (2026-09-10)

Feito com `tools/build_completo.py` (build) + `tools/validate_completo.py`
(validação em 2 passes para caber na RAM) + `tools/rbxcodec.py` (codec da
spec do binário — Int32 BE+zigzag, Float32 formato Roblox, arrays
byte-interleaved, BrickColor/UDim/UDim2/Color3/Vector3/Enum) +
`tools/smoke_test_v3.py` (execução dos 6 scripts novos em stub Lua):

- [x] **290.617/290.617 instâncias** no `.rbxl` (90 services + 290.461 V2 + 66 V3)
- [x] **290.361/290.361 fontes byte-idênticas** ao V2 (sha1)
- [x] **0 divergências de estrutura** (classe/nome/parent de cada instância V2)
- [x] **0 divergências de propriedades** (valores decodificados, 647 props)
- [x] V3: **66/66** instâncias no lugar e **cada uma no service devido**
  (ReplicatedFirst, SSS, ServerStorage, SPS, SCS, StarterPack, NetworkClient,
  SoundService, Lighting, Teams, TestService, Workspace, RS.ArkherV3)
- [x] `RunContext`/`Disabled` corretos (S0/S1/Boot/HUD ativos; 24 painéis +
  assemble + 2 installers + T0 desativados)
- [x] Props das novas instâncias conferidas (Handle Part, SpawnLocation,
  Atmosphere/ColorCorrection, Team.TeamColor=BrickColor, Sounds, RemoteEvents)
- [x] **Smoke test**: S0, S1, C0, N0 e T0 executados em stub Lua — 0 erros;
  T0 self-test **9/9 — ESTRUTURA COMPLETA**
- [x] `CB_UI_StarterGui.lua`: sintaxe OK; simulação em stub Roblox → **88/88
      instâncias e 570/570 propriedades idênticas** à UI do V2
- [x] `ALL_P1+ALL_P2+ALL_P3 == ArkherStudio_ALL.lua` (byte a byte)

## Ferramentas (tools/)

| Arquivo | Função |
|---|---|
| `pyrbxl2.py` | decoder do binário moderno do Roblox (header `<roblox!`, chunks LZ4/ZSTD) |
| `rbxcodec.py` | codec dos valores PROP segundo a spec (com testes unitários: `python3 rbxcodec.py`) |
| `make_rbxl.py` | encoder base (header, chunks, referent arrays, lista de 90 services) |
| `build_completo.py` | **build do place completo** (ler V2 → montar → escrever `.rbxl` + gerar `CB_UI`) |
| `validate_completo.py` | validação 2-passes (`A` meu arquivo → json; `B` V2 → comparar + gerar `CB_UI`) |
| `smoke_test_v3.py` | execução dos 6 scripts V3 novos em stub Lua (lupa) |
| `make_estrutura_completa.py` | gerador dos 13 CBs de legado |
| `simulate_commandbar.py` | simulador dos CBs em stub Lua |
