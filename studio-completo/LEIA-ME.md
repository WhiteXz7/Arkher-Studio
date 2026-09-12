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
| `StarterGui/ArkherStudioUI/Arkher_01/03/08` | LocalScripts X — `03_Menus` (menus X na **topbar ORIGINAL** do Mezzanine, clonando seus botões **+ X-TIER: barra de ATIVAÇÃO com 13 botões, clique esquerdo abre o editor, direito abre o dropdown**) + `08_RealityX` (o DECK: **13 editores únicos**: TERRAIN/WATER/MODELER/ANIMATOR/ESPAÇO/FABRICAR/**ATMOS/CLIMA/VIDA/CIDADE/ÁUDIO/FX/CORDAS**) |

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
- **RIG X + MESH X no DECK** (os docks 05/06/07 foram removidos: eram
  "enfeite" de retângulos e a diretriz é ZERO painel sem efeito real).

**ROUND 7 (2026-09-11) — o pedido COMPLETO da pesquisa UI:** pesquisa feita
(Roblox Studio toolbar/menus, InsertService Creator Store, LogService, AssetService).
Entrega neste round:

- **X-TIER v2**: 19 ativadores na topbar (13 editores + **PART/TOOLBOX/PROPS/CORES/
  OUTPUT/COMANDO**). Clique esquerdo ATIVA; direito = dropdown. **UIGridLayout com
  wrap**: em telas estreitas (mobile/tablet) os botões caem pra 2-3 linhas e a escala
  muda — a UI se ADAPTA ao dispositivo (`hostWidth` + `updateDeckScale` 0.72–1.3).
- **PART com submenu de formas**: clique esquerdo spawna Block; direito abre
  submenu real (Block/Ball/Cylinder/CylinderVertical/Wedge/CornerWedge/Truss) — via
  `handlers.QuickPart` (Shape/classe REAIS do engine + Register/histórico nativos).
- **Submenus de verdade nos menus**: itens com `sub = {...}` abrem painel-filho ao
  lado (hover/click), fecham junto com o menu; **tooltips por item** (barra ⓘ diz o
  que cada coisa faz — resposta ao "não dá pra saber o que colocar") e **headers de
  seção**. 
- **TOOLBOX X** (deck): busca na **Creator Store REAL do Roblox** via
  `InsertService:GetFreeModelsAsync/GetFreeDecalsAsync` + insert com
  `LoadAsset` em **um clique** (com fallback honesto se o Roblox recusar). Aba 2:
  templates Arkher (toolbox nativa).
- **PROPS X — TODAS**: `handlers.PropsAll` devolve um **mapa exaustivo por IsA-chain**
  (~35 tipos, ~200 propriedades: BasePart physics completa, GuiObject, Text/Image,
  ParticleEmitter física, Lights, Values, Humanoid, Scripts…) e `handlers.PropsSet`
  aplica com coerção por kind (number/string/bool/Vector2/3/Color3/BrickColor/Enum/
  UDim/UDim2/CFrame) — **funcionais, afetam o selecionado de verdade**.
- **CORES X**: color picker REAL (R/G/B + H/S/V + hex + paleta BrickColor oficial)
  que varre as **chaves de cor do objeto selecionado** e aplica via PropsSet.
- **OUTPUT X**: `LogService:GetLogHistory` + `MessageOut` ao vivo, filtros
  Info/Warning/Error, LIMPAR real (`ClearOutput`).
- **COMANDO X**: barra que **executa de verdade**: `spawn <forma>`, `sel`,
  `set <prop> <valor>` (resolve o kind via PropsAll), `cmd <op motor X>`,
  `math <expr>` (parser Pratt seguro), `time`, `weather`, `help`.
- **Places no perfil**: `handlers.PlaceCreate` (AssetService:CreatePlaceAsync) —
  cria place NO PERFIL quando a sessão online permite (resposta honesta caso não).
- Backend: **7 handlers novos** no bridge nativo (bloco BLOCK_X7 do build_server):
  SelectedGet/PropsAll/PropsSet/QuickPart/ToolboxSearch/ToolboxAssetInsert/PlaceCreate.

**ROUND 6 (2026-09-11) — ativação total na topbar:** o **X-TIER** (faixa colada na
topbar original) ativa cada editor com **um clique esquerdo** (clique direito = dropdown
de cada um). 7 editores NOVOS com backend real: **ATMOS X** (relógio solar cruza os
Kelvin no pump — cor do sol é física, não tint manual; 7 estados de tempo com blend;
ceu presets de 1900K a 5600K), **CLIMA X** (mapa meteorológico vivo: frentes H/L nascem,
viajam e mudam o tempo sozinhas — WEAX já é hooked no RX), **VIDA X** (DAYX humana;
NPCs FABRIK; ECOX start/**stop** novo; MINDX mentes/objetivos no status),
**CIDADE X** (vila/cidade/metrópole por seed, grava na terra via RLayer.urbanize),
**ÁUDIO X** (mixer dos 7 buses reais AUX com leitura do motor + intensidade musical
paz/tensão/combate), **FX X** (13 presets APX com gravidade/vórtice REAL, budget D-O15,
emitir em (x,y,z) + limpar) e **CORDAS X** (Verlet íntegro: demo, bandeira ao vento AEX,
ponte pênsil + bola oscilante). Backend: **20 comandos novos** no `engine_server.lua`
(95 no total) — `atmos_list/clock/stats`, `wea_stats/off`, `day_stats`, `mind_stats`,
`eco_stop`, `civ_stats`, `audio_setup/bus/intensity/stats`, `fx_presets/emit/clear/stats`,
`rope_flag/bridge/stats`. `ecox.luau` ganhou `ECOX.stop()`. Todos pump no Heartbeat via
`RX.hook` (nada de fake: o Deck só chama comandos, o mundo muda no servidor).

Regerar: `python3 tools/inject_arkherx.py ../ArkherStudio_Completo_Pro.rbxl ../ArkherStudio_Completo_X.rbxl` → valida **1.751 inst, 32 tipos (185.317 B)**, PRNT/END corretos.

**UI SOBERANA (round 4 — super-diretriz do estúdio):** a topbar é a ORIGINAL
da UI (botões do Mezzanine dentro dela, criados por clone). Cada menu novo
abre **um editor único com ferramentas reais** (`_G.ArkherDeck.open(id)`):

| Menu topbar | Editor único (08_Deck) | Não é cópia de... |
|---|---|---|
| MUNDO | **TERRAIN X** — categorias>>52 tools reais do WORLDX, r/amp/X/Z, sonda viva, geração planetária | ferramenta territorial própria ARKHER |
| MODELAGEM | **MODELER X estilo Blender** — modos GERAR/EDITAR/TOPOLOGIA/FINALIZAR/PIPELINE, toolbox N-panel, outliner com verts/faces/operações reais da banca (99 mesh tools) | Blender genuíno |
| ANIMAÇÃO | **ANIMATOR X estilo Cascadeur** — régua 48f@24fps com playhead do tempo real do rig, transporte PLAY/STOP, AutoPhysics (Secundária+Auto-Balanço+Balística somados no backend), palco/rigs | Cascadeur genuíno |
| ESPAÇO | **ESPAÇO X** — criador orbital próprio: escada superfície→galáxia (escala real+LOG), Képler real (T∝r^1.5 no pump), mapa orbital 2D lendo estado VIVO do servidor, 2 presets prontos | único ARKHER (feito do zero) |
| ÁGUA | **WATER X** — oceanografia REAL: 8 composições físicas (densidade kg/m³, salinidade g/kg, °C, viscos.), ondas Gerstner com dispersão ω=√(g·k), maré lunar, Arquimedes (empuxo ρ·V·g) com 6 densidades reais, cachoeira de matéria real | único ARKHER — física de oceano de verdade, não skin |
| FABRICAR | **FABRICAR X** — gramática procedural (6 famílias, 50 classes), seed determinística/auto-seed, tingir real, "entra sozinho no mundo" (RRW) | único ARKHER |

**FIX (2026-09, boot limpo):** os motores clássicos usavam globals bare
(`ArkherDM = ...`), que NO ROBLOX ficam no environment privado de cada
ModuleScript — por isso DM "sumia" e a cadeia `DM.clamp` quebrava em
terrainx/waterx/scenex/animx/audiomix/atmosx/particlesx/ropex. Tudo agora
exporta em `_G` (padrão dos novos) e **todos os 25 módulos têm `return`**;
o EngineServer espelha os 25 símbolos após o boot. Services do editor
antigo rodavam escrevendo `Source` (capability ausente em servidor comum)
e spammavam erro — agora são **função inline** (mesmo código) com aviso
único. Heartbeat ganhou o pump da água (ondas/caustics/falls/barcos).

Nada é enfeite: todo clique muda o mundo de verdade (e todo efeito mostra a
resposta do servidor no rodapé). RRW/Tese-D/D-O15 = backend invisível,
automático. Sem automação falsa na UI — é tudo o DEV operando; a Singularity
AI (bloco futuro) é quem automatiza.

**TECH Z + K (2026-09, round 4 — 3 blocos em qualidade máxima):**
- `rlayer.luau` (RLX, tech Z OBRIGATÓRIA — **Reality Layer**): a realidade em
  **5 camadas vivas** — GEO/HYDRO/ATMO/BIO/URB — cada uma evoluindo sozinha
  (advecção do vento WEAX, evaporação/condensação, logística da BIO, deposição
  urbana do CIVIX) e **compondo juntas** a matéria de cada célula; o RRX aplica
  o tint das camadas nas entidades (wet escurece, BIO esverdeia, URB acinzenta,
  nuvem densa sombreia).
- `dpred.luau` (DPX, tech Z/S — **D-O15 Predictive**): EMA de velocidade+acentuação
  da câmera com horizonte adaptativo por tier (0.9+0.45·weatherHz), anti-spike
  (clamp 140 st/s) e saturação 260; o **anel de streaming anda com a previsão**
  (bias até 60% do Rin) → materializa ANTES da percepção chegar; **mapa de
  atenção por célula** (dwell) persistido em THX.MEM e consumido por AWI.
- `mindx.luau` (MINDX, cat. K — NMN recodificado no padrão RRW): **mentes reais**
  acopladas automaticamente a todo humano DAYX — necessidades (hunger/energy/
  social), objetivos com causalidade, **memória auditável com PORQUÊ** (`mind_why`),
  percepção por grade espacial O(células), pontos de comida (assentamentos CIVIX
  viram spots automáticos); o wander aleatório cede lugar à decisão da mente.
- Integrações: `RX.register` guarda baseColor; `materialize` aplica tint RL em
  D médio/alto; pump do RRX chama `DPred.step` ANTES do stream; DAYX obedece à mente.
- Servidor **61 comandos** (`rl_build`, `rl_stats`, `pred_on`, `pred_stats`,
  `mind_stats`, `mind_why`, `mind_food`); CIVIX agora **urbaniza a Reality Layer**
  e alimenta as mentes; injetor: **24 ModuleScripts**.

**MUNDO VIVO (2026-09, round 3 — famílias J/H/L/M/X):**
- `dayx.luau` (DAYX, cat. J) — **humano digital procedural**: respiração 0.25 Hz,
  piscar fisiológico, olhar-atento para a câmera, marcha com balanço pendular,
  importância 0.95 no RRW (D-O15 nunca o rebaixa).
- `ecox.luau` (ECOX, cat. L) — **ecossistemas** com dinâmica logística real
  (dN=rN(1−N/K)), fauna nascida pelo FABX no nicho do bioma (peixe só na água!).
- `weax.luau` (WEAX, cat. L/M) — **frentes meteorológicas**: sistemas de pressão
  ALTA/BAIXA que nascem/viajam/morrem, mudam o weather AEX ao passar por você e
  regam o ciclo d'água no WLDX.
- `civix.luau` (CIVIX, cat. M) — **assentamentos procedurais** vila/cidade/metrópole:
  malha viária + lotes + FABX + praças, determinístico por seed.
- `physx.luau` (PHYSX, cat. H) — **vento global** com rajadas (ruído 1D) aplicado a
  corpos soltos + **shockwave** com decaimento esférico; budget D-O15 fatiado.
- `secx.luau` (SECX, cat. X) — **anti-exploit da ponte**: rate-limit por jogador
  (janela deslizante), higiene de payload, trilha de auditoria, fail-closed.
- **RX.HOOKS**: qualquer motor assina o pulso universal do RRW (`RX.hook`) — a
  adaptação da realidade acontece para TODOS juntos, no mesmo Heartbeat.
- Servidor **54 comandos**; abas novas **VIDA · ECO** e **CIDADES** (12 abas; strip
  rolável; status no rodapé da board); injetor: **21 ModuleScripts**. Testes: `python3 tools/run_tests.py` (109+ asserts, 27 painéis).

**CAMADA AUTOMÁTICA + FABRICATOR (2026-09, round 2):**
- **`fabx.luau` (FABX)** — o FABRICATOR universal: gramática procedural com ~48 classes
  (árvore/pinheiro/palmeira/cacto/flor/pedra/cristal/ilha/vulcão/montanha · casa/prédio/
  torre/ponte/muro/cerca/porta/janela/coluna/fonte/escada/arco/telhado · mesa/cadeira/
  sofá/cama/estante/lâmpada/vaso · carro/barco/avião/nave/roda · espada/escudo/caixa/
  barril/baú/placa/estátua · personagem/criatura/ave/peixe · antena) determinísticas por
  seed, aceitando **PT ou EN** ("árvore"/"tree"), com matéria real (TX.MATTER) e
  **registro automático no RRW** na hora da criação. Aba **FABRICAR · TUDO** na topbar.
- **RRX camada de aplicação automática**: `autoBind` captura tudo do workspace (e todo
  spawn futuro via DescendantAdded); **Semantic World Graph** (nós por entidade +
  consultas); **AWI — Adaptive World Intelligence** (importância dinâmica pela atenção
  do jogador + D preditivo); `createEarth` (Terra em equiretangular, 12 placas,
  escala paisagem 4m/planetária 640m, gravidade calibrada) e **`earthStream`**
  (streaming celular com histerese D-O15 — entra cedo, abstrai tarde, nunca destrói).
- **Hidrologia viva no WORLDX**: `rivers` (steepest-descent real que **entalha o leito**
  via escovas-delta), `materializeRivers` (fitas d'água), `riverMoist` (umidade→vegetação)
  e `hydroStep` (ciclo d'água: evapora→nuvens→chuva→erosão que aprende) bombeado no
  Heartbeat do RRX. `statsReport` agora reporta stream/AWI/chuvas/terra.
- Servidor **44 comandos** (`rrx_autobind`, `awi_on`, `earth_generate`, `earth_stream`,
  `world_rivers`, `hydro_on`, `fabricate`, `fabricate_list`, `graph_stats`, `npc_spawn`…).

**REMAKE RRW (2026-09):** três motores núcleo novos + topbar de abas (barra lateral removida):
- `studio-v3/core/theoryx.luau` (THX) — teoria codificada: Tese dos D (D⃗, histerese,
  D\* = argmax(Q−C)), tiers D12/D9/D6/D3 com orçamentos, **10 matérias-com-matéria**,
  **32 biomas Köppen/ESA + Whittaker**, escalas studio/paisagem/planeta, memória de projeto.
- `studio-v3/core/worldx.luau` (WLDX) — motor planetário REAL: tectônica de placas +
  deriva, altura/clima (latitude, lapse rate, **sombra de chuva orográfica**, vento),
  regras mangue/alagado/playa, render **16K** por matéria (mole→escurece, exposição),
  **parallax TRUE** (N cascas clonadas — não bump), luz ambiente **Kelvin→RGB real**,
  erosão com **aprendizado** (memória THX), e **~50 tools de terreno** em 8 categorias
  (sculpt/landform/glacial/eólico/fluvial/cárste/vulcão+costa/erosão).
- `studio-v3/core/realityx.luau` (RRX) — **daemon RRW automático**: registra entidades,
  materializa/desmaterializa por distância+importância+tier (histerese/preditivo D-O15),
  relógio do mundo e luz ambiental sozinhos — **zero operação manual**.
- `Arkher_08_RealityX` (LocalScript) — **TOPBAR DE ABAS** logo abaixo da topbar original
  (**só adiciona UI**; a dock lateral direita foi RETIRADA por diretriz do estúdio):
  RRW·PLANETA / TERRAIN·50 (grade dinâmica das tools reais) / ÁGUA / CLIMA·LUZ
  (6 céus Kelvin + 7 weathers) / VEGET / MODELER·100 (banca MeshX viva) /
  ANIMATOR (AutoRig 4 esqueletos + **AutoPhysics 0→1** estilo Cascadeur) / CENA·FX / STATS.
- `engine_server.lua` agora expõe **34 comandos** (tier_set, world_generate/materialize/
  tool/tools/vegetate/erode, rrx_start/stats, world_tools dinâmico, mesh_tool/tools com
  banca, anim_autorig/autophysics…) e o pump Heartbeat roda o RRX junto dos demais.


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
