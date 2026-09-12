# ARKHER V4 — UES COMPLETA + MOTORES PRÓPRIOS (TERRAIN/WATER/SCRIPT/UI-KIT)

Reconstrução do ARKHER do zero. O V2 parou em 41 clones do mesmo template de UI;
o V3 trouxe 24 UIs desenhadas de verdade; **o V4 vai além do Roblox**: quatro
motores CUSTOM que substituem (e ultrapassam) o que o engine nativo oferece,
implementando RRW de ponta a ponta (Realidade → Representação → D-O15 → RRW →
Materialização) — **137 verificações em 2 fases, 0 falhas**.

## OS CUSTOMS (V4) — contornando os limites do Roblox

| Motor | O que faz de verdade |
|---|---|
| **D-MATH** (`core/dmath.luau`) | Campos determinísticos (mesma seed = mesmo universo): ruído gradiente/valor, fBm + turbulence + ridged + worley (F1/F2), Whittaker, integração numérica, splines, falloffs |
| **TERRAIN X / ATX** (`core/terrainx.luau`) | **Terreno próprio — NÃO usa o Terrain do Roblox**: mundo procedural com **10 presets geográficos** (continentes..pantanal/taiga), maré de preset honrada (`seaLevel` real), 21 materiais com densidade/dureza/parâmetros termais reais, **erosão hidráulica** (gotas com inércia/capacidade de sedimento), **erosão térmica** (talus), rios por acumulação de fluxo, lagos (flood fill de depressões), **classes Whittaker** (T/M → bioma → material → look), **CAVERNAS reais** (coluna se divide em base+tecto), 14 pincéis (raise/lower/smooth/flatten/mountain/plateau/mesa/paint/melt/wet/river/carve/erode/noise), **chunks com LOD adaptativo D-O15** (re-materializa conforme foco), serialize/export JSON |
| **WATER X / AWX** (`core/waterx.luau`) | **Água própria — NÃO usa a água do Roblox**: 8 tipos d'água com densidade/salinidade/temperatura/viscosidade, **ondas de Gerstner com dispersão gravitacional REAL** (ω=√(g·k)), marés lunares (diurna+semi-diurna), correntes de Stokes, crest foam, **flutuabilidade arquimediana estável** (empuxo, arrasto viscoso linear+quadrático, adesão à normal da crista), natação, ambiente subaquático (fog/color-correction), caustics Gerstner+Schlick, splash, ciclo hidrológico ↔ ATX (evaporação/umidade), 6 presets de mar, tiles LOD — **mais: CACHOEIRA física** (droplets com gravidade real + splash/foam ao pousar) e **BARCO com flutuabilidade de 4 pontos** (proa/popa/boreste/bombordo → empuxo, pitch/roll, motor, leme, arrasto hidrodinâmico) |
| **ANIMATOR X / AAX** (`core/animx.luau`) | **Animação própria — sem KeyframeSequence**: clips multi-track (Position/CFrame/Size/Color/Transparency/atributos) com **37 easings físicos reais** (quad..bounce/overshoot/spring), splines Catmull-Rom, **molas amortecidas REAL** (oscilador harmônico — mesma física do D-O15, usadas p/ secondary motion), loop/ping-pong, markers, time-warp, **blend de clips**, **DEFORMERS procedurais** (bend/twist/wave/taper/breathe) que dão vida a assemblies de parts sem rig manual, serialize/export JSON, apply REAL na seleção |
| **AUDIO X / AUX** (`core/audiomix.luau`) | **Mixer/DSP próprio**: 7 buses SoundGroup REAIS, presets acústicos (caverna/estádio/estúdio/subaquático/rádio/floresta/metal) ligando efeitos DSP do engine (Reverb/Echo/Compressor/EQ/Distortion/Flange/PitchShift), **ducking sidechain** (voz derruba música com envelope attack/hold/release), **camadas de música adaptativas** (base/tensão/combate com crossfade), **scheduler ambiente never-repeat**, **posicional 3D simulado** (rolloff inverso-quadrático + doppler aproximado), links AWX |
| **SCENE / SCATTER X / ASXN** (`core/scenex.luau`) | **Povoamento procedural**: spatial hash, query por classe/nome/atributo/raio, **PATINA** (variação determinística anti-CG por seed), **scatter Poisson** com regras por BIOMA (a árvore certa no bioma Whittaker certo), declive máximo, acima do mar, biblioteca de **vegetação procedural** (árvore com dossel orgânico / arbusto / pedra com juni / grama por lâminas), **LOD por distância** cooperando com D-O15 (ghost mid, cull far), MERGE/EXPLODE/ALIGN-ARRAY |
| **ATMOS X / AEX** (`core/atmosx.luau`) | **Céu + clima custom**: ciclo dia-noite com **temperatura de cor REAL em Kelvin → RGB** (aproximação CIE/Planckian), 6 presets de céu (kelvin/haze/fog físicos), **WEATHER MACHINE** com 7 estados (limpo/nuvem/chuva/tempestade/neblina/neve/aurora) e **transições suaves**, relâmpagos agendados (flash via ColorCorrection REAL + heat thunder), estrelas à noite (Sky real), e **LINKS FÍSICOS**: tempestade multiplica ondas AWX ×2.2 (amp+speed reais) e vento sobe volume weather AUX — tudo determinístico no pump |
| **CAMERA X / ACX** (`core/camerax.luau`) | **Cinematografia custom**: SHOTS reais na CurrentCamera (orbit/dolly/crane com lift/follow com lag exponencial/**flypath Catmull-Rom 3D** via AAX), **SHAKE com trauma²** (amplitude real de cinema), camera-collision por **raycast real**, **FADE IN/OUT via ColorCorrectionEffect no Lighting** (com callbacks), e **CINEMA** — sequência de cortes com avanço automático |
| **PARTICLES X / APX** (`core/particlesx.luau`) | **Emissores custom com física própria** sobre ParticleEmitters REAIS: **12 presets** (foguete balístico, fogo up-draft, fumaça, faíscas, splash d'água, **magia em vortex** (RotSpeed tangencial), ring shockwave, chuva/neve com área, folhas com sway, poeira, bolhas, trilha), spec editor dinâmico, e **BUDGET D-O15-aware** — a pressão de performance restringe emissão em tempo real (anti-overdraw real), com ancoragem automática no world |
| **ROPE X / RPX** (`core/ropex.luau`) | **O que o Roblox NÃO tem: cloth/rope real** — integração de **Verlet** própria: particulas x += (x-pp)·damp + a·dt², constraints de distancia com 5 passes de relaxamento, gravidade real, **vento vivo ligado ao ATMOS X** (tempestade → tecido enlouquece), colisão com esferas e plano, materialização em **Parts finas reais por segmento** (geometria física no workspace), cloth em grade pinada (bandeira de 1 chamada), bombeado no pulso do ANIM X |
| **SCRIPT STUDIO X / SX** (`core/scripterx.luau`) | **IDE backend completo**: tokenizer Lua real, **lint de escopo** (bloco não fechado, variáveis não usadas, shadowing, APIs depreciadas, `==` vs `=`, números longos, função longa), autocomplete contextual (API Roblox 60+), outline, find/replace, diff, métricas (Linhas/Funções/Complexidade McCabe), formatador com indentação, 30 templates de código real, 45 snippets, compile-check nativo, **compositor IA** (`compose("crie uma arma")` → monta o código) |
| **UI KIT X / AXI** (`core/uikitx.luau`) | 42 widgets de JOGO em 5 categorias (HUD/hotbar/minimap com coord AO VIVO/radial/menu/leaderboard/dialog/dialogue...), 6 temas proprios, anchors 9 presets, alinhamento/distribuição, **build REAL no StarterGui**, export que gera **código Roblox funcional pronto** (ModuleScript builders + Controller input bind) com import de GUI existente |

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

## As 26 UIs (cada uma ÚNICA)
| UI | Layout característico |
|---|---|
| **Animator Studio X** ⭐V4-W2 | over **AAX custom**: clips, tracks (Position/CFrame/Size/Color/Transparency/attr), **curva amostrada desenhada do motor**, keys clicáveis, easing grid (37 físicas), loop/ping-pong, speed, markers, play/stop, **DEFORMERS no assembly real** (bend/twist/wave/taper/breathe), export JSON |
| **Lighting Studio X** ⭐V4-W3 | over **ATMOS X custom**: 6 presets de céu com Kelvin físico, **swatch Kelvin→RGB real** (Planckian), arco do espectro do dia, slider de hora aplicando ClockTime REAL, **WEATHER MACHINE** (7 estados com transição suave), flash teste de raio, stats fog/haze/waveBoost AO VIVO no pump |
| **Camera Studio X** ⭐V4-W3 | over **CAMERA X custom**: 5 shots reais (orbit/dolly-in/dolly-out/crane/flypath), params (raio/altura/speed/duração), **editor de flypath com canvas top-view Catmull-Rom**, **TRAUMA meter** (shake trauma² real), **FADE real** ColorCorrection, **CINEMA** (3 cortes encadeados), stats ao vivo da CurrentCamera |
| **Particles Studio X** ⭐V4-W3 | over **PARTICLES X custom**: 12 presets físicos de 1 clique, **SPEC EDITOR** vivo (mode/life/speed/gravity/spread/rate/size/vΩ), budget **D-O15** com barra de pressure real, lista de emissores ativos, **links reais**: splash p/ primeiro corpo AWX, chuva+setWeather(tempestade), neve |
| Modeler | paleta vertical de ferramentas + **malha low-poly com vertices clicáveis** + UV grid |
| **Terrain Studio** ⭐V4 | over **ATX custom**: grid soil-view (cores = 21 materiais reais), 14 pincéis, 7 presets, erosão/mudança de relevo, rios/lagos, biomas/lista, seed export, **link cruzado para Water (lagos→água)** |
| **Water Studio** ⭐V4 | over **AWX custom**: tipos d'água + 6 mares (calmaria..tempestade), **gráfico AO VIVO do perfil Gerstner** (desenhado do campo real), designer de ondas (amp/len/dir/speed/steep), maré, tempo ANIMAR, fluição da selecção, submerso, caustics, splash, JSON, **link p/ Terrain**, (W2: cachoeira + barco) |
| **Scatter / Scene X** ⭐V4-W2 | over **ASXN custom**: região círculo/retângulo, count/minDist/declive/seed, **preview de pontos poisson ANTES de materializar**, makers automáticos por bioma Whittaker, **PATINA anti-CG**, LOD por distância, query por classe/nome/raio, MERGE/EXPLODE/ALIGN |
| **Script Studio** ⭐V4 | over **SX custom (IDE real)**: multi-doc tabs, números de linha + highlight real, lint panel (scopo real), outline/completar/45 snippets/30 templates, **find/replace**, undo, editor inline por linha + modo FullEdit, métricas/compile, compositor IA, **criar Script de verdade no Place + exportar arquivo** |
| Particles | **grafo de nós** (estilo Nuke/Blender) com fios + knobs |
| Camera | modos de vista + **cone de FOV que muda** com +/− + knobs |
| Lighting | **faixa de hora do dia clicável** (mexe o céu e o sol no preview) + knobs |
| **Audio Studio X** ⭐V4-W2 | over **AUX custom**: 7 buses SoundGroup REAIS com sliders funcionais, **DSP presets** (caverna/estádio/estúdio/subaquático/rádio/floresta/metal), **ducking sidechain** demonstrado AO VIVO (voz→música), scheduler ambiente (4 biomas), **layers adaptativas** (base/tensão/combate + intensidade), **posicional 3D** (rolloff + doppler demo circular) |
| Physics | **grid de colisão interativo** (clique liga/desliga) + joints |
| **UI Studio (Designer)** ⭐V4 | over **AXI custom**: paleta 42 widgets paginada, canvas device 960×540 com device cycler (iPhone/iPad!), **drag real multi-sel + resize handle + snap**, inspector X/Y/W/H é anchora 9 presets, align/distribute, temas 6, **export REAL p/ StarterGui + gera código** |
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
├── ArkherKit_A (ModuleScript)  prelude + do15 + undo + publish + nmn    (~65K)
├── ArkherKit_B (ModuleScript)  places + actions + singularity + live + boot (~79K)
├── ArkherKit_C (ModuleScript)  ⭐ D-MATH + TERRAIN X + WATER X         (~70K)
├── ArkherKit_D (ModuleScript)  ⭐ SCRIPT STUDIO X + UI KIT X           (~84K)
└── ArkherKit_E (ModuleScript)  ⭐ ANIM X + AUDIO X + SCENE X + ATMOS X + CAMERA X + PARTICLES X (~74K)

LocalScripts (launchers finos, ~4-52K):
├── ArkherStudio_MainUI         shell + command palette
├── UI_Bundle_Editors           Animator/Modeler/Terrain/Water/Particles/Scatter
├── UI_Bundle_Motion            Animator X + Audio X
├── UI_Bundle_Code              Script Studio IDE
├── UI_Bundle_Mundo             Terrain + Water + Scatter (opcional, p/ preload)
├── UI_Bundle_Scene             Camera/Lighting/Audio/Physics/UIStudio/Map
├── UI_Bundle_System            City/NPCs/Performance/Console/Settings/Cloud/AI/Publish/
│                               SaveOpen/Export/Open/About
└── UI_<Nome> (x26)             uma UI individual, autocontida
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

> **Peso do arquivo: 8,84 MB** (9.265.720 B). O place é gravado no formato
> binário v0 com **ZSTD (nível 15)** nos chunks grandes — o decoder do
> Studio detecta o codec pelo magic do chunk (`28 b5 2f fd`), como a própria
> spec do formato prevê (dom.rojo.space/binary.html). Nada de conteúdo foi
> removido: os 305 chunks descomprimem byte-a-byte idênticos à versão
> anterior (validação 2-passes: 290.361 fontes, 0 divergências). A re-
> compressão é reproduzível com `tools/reencode_zstd.py`.

**Caminho 2 — Command Bar num place existente:**
`commandbar/estrutura-completa/CB_UI_TODAS_UIS.lua` (View > Command Bar >
colar tudo > Run) cria **TODAS as UIs no StarterGui** — as 24 UIs únicas da
V3 + o shell do editor + a UI original do V2 (26 janelas, 4.807 instâncias,
estrutura exata do `build()` que fez cada uma). Depois use
`ArkherUI.show("ArkherMap")` / `hide` / `toggle` / `list`.
Só a UI original do V2: `CB_UI_StarterGui.lua` (88 instâncias, fiel).

**Caminho 3 — paste manual dos 10 scripts da engine** (sem o .rbxl):
Rode `./build.sh` e cole, na ordem:
1. `commandbar/ArkherKit_Installer_A.lua` → num **Script** (cria o ModuleScript Kit A)
2. `commandbar/ArkherKit_Installer_B.lua` → num **Script** (cria o ModuleScript Kit B)
3. `commandbar/ArkherKit_Installer_C.lua` → num **Script** (⭐ motores Terrain X + Water X)
4. `commandbar/ArkherKit_Installer_D.lua` → num **Script** (⭐ Script Studio X + UI Kit X)
5. `commandbar/ArkherKit_Installer_E.lua` → num **Script** (⭐ Animator X + Audio X + Scene X)
6. `commandbar/ArkherStudio_MainUI.lua` → num **LocalScript** (abre o shell)
7. `commandbar/UI_Bundle_Editors.lua` → **LocalScript** (Animator/Modeler/**Terrain**/**Water**/Particles/**Scatter**)
8. `commandbar/UI_Bundle_Code.lua` → **LocalScript** (Script Studio IDE)
9. `commandbar/UI_Bundle_Scene.lua` → **LocalScript**
10. `commandbar/UI_Bundle_System.lua` → **LocalScript**

Alternativa: cole `UI_<Nome>.lua` individuais em vez dos bundles
(ex.: só a `UI_Water.lua` + `UI_Terrain.lua` para o pacote de mundo).

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
│   ├── singularity.luau  # IA local: planner + 14 especialistas (V4: +terrain/water/ui)
│   ├── nmn.luau          # mentes (grid espacial, causalidade)
│   ├── publish.luau      # publish local + endpoint opcional (sem Open API)
│   ├── actions.luau      # registro central de comandos (ARKHER.cmd)
│   ├── dmath.luau        # ⭐ V4: campos determinísticos (fbm/worley/Whittaker)
│   ├── terrainx.luau     # ⭐ V4: TERRAIN X — motor de terreno próprio (21 materiais, erosões, cavernas)
│   ├── waterx.luau       # ⭐ V4: WATER X — água física própria (Gerstner, Arquimedes, marés, cachoeira, barcos)
│   ├── scripterx.luau    # ⭐ V4: SCRIPT STUDIO X — tokenizer/lint/autocomplete/30 templates
│   ├── uikitx.luau       # ⭐ V4: UI KIT X — 42 widgets de jogo + export de código
│   ├── animx.luau        # ⭐ V4-W2: ANIMATOR X — 37 easings, springs, deformers
│   ├── audiomix.luau     # ⭐ V4-W2: AUDIO X — SoundGroups, DSP presets, ducking, scheduler
│   └── scenex.luau       # ⭐ V4-W2: SCENE/SCATTER X — poisson por bioma, patina, LOD
├── build.sh              # gera commandbar/ (36 artefatos, todos < 95K)
└── tests/
    ├── shim.lua          # simulador de API Roblox (inclui require p/ ModuleScript)
    ├── verify.lua        # fase 1: 120+ checagens sobre o build unico
    ├── kitflow.lua       # fase 2: fluxo real de instalação (4 kits + launchers)
    └── run.py            # runner (lupa): build + 2 fases, sai 1 se algo falha
```

## Comandos (ARKHER.cmd)
Menus, atalhos, palette e a IA usam o **mesmo** registro — nenhum botão é
decorativo. Exemplos: `place.new`, `place.open`, `insert.part`, `tool Move`,
`edit.delete`, `file.save`, `file.export`, `publish.local`, `ui.open <Nome>`,
`undo.push`, `view.palette` — e na V4: `terrain.generate/erode/rivers/lakes/
materialize/lod/clear/export`, `water.ocean/caustics/float/underwater/splash`,
`script.new/newfromgoal/lintreport`, `uix.hud/theme` — e na V4-W2:
`anim.demo/pump/stopall/wave`, `audio.setup/duckdemo/patch`,
`scene.forest/patina/query/rehash/lod` — e na V4-W3: `atmos.setup/preset/
weather/cycle`, `cam.orbit/crane/fly/shake/fade/cinema/stop`,
`px.emit/demo/clear/storm`.

## Testes
```
cd studio-v3
python3 tests/run.py
```
- **Fase 1 (ALL)**: core + shell + 26 UIs num build único → **230 checagens**
  (places roundtrip, undo/redo, singularity, NMN, publish, D-O15, **D-MATH,
  TERRAIN X** (determinismo, erosões, rios, lagos, biomas, LOD, materialização,
  JSON, **cavernas**, 10 presets), **WATER X** (Gerstner, Arquimedes subindo
  objetos, caustics, JSON, swim, **cachoeira com splash real**, **barco 4 pts**
  avançando), **SCRIPT X** (tokenizer, lint real, autocomplete, format, diff,
  métricas), **UI KIT X** (criar/align/anchor/build/export-gera-código),
  **ANIM X** (35+ easings, catmull, spring converge, blend, pingpong, deformers,
  JSON), **AUDIO X** (7 buses Reais, patch DSP caverna 2 efx, **ducking envelope
  cai e recupera**, scheduler never-repeat, layers crossfade, posicional),
  **SCENE X** (prepare poisson minDist respeitado, bioma em cada ponto, scatter
  materializa, patina altera cor, query, near-hash, align/merge/explode, **LOD
  cull e retorno**), **ATMOS X** (Kelvin→RGB físico 2200/5600, presets,
  transição de clima, relâmpago dispara, **links AWX waveBoost>2**),
  **CAMERA X** (orbit mede raio REAL na CurrentCamera, dolly termina,
  Catmull-Rom 3D, trauma decai, fade -1/0 com callback, cinema),
  **PARTICLES X** (12 presets, emit REAL cria anchor, rate/burst/vortex,
  budget D-O15, clear), comandos V4-W2/W3, SINGULARITY (audio/anim/
  nature-scatter).
- **Fase 2 (kitflow)**: runtime limpo; cria os **5 ModuleScripts** e executa
  os launchers reais via `require` — 14 checagens (instalação, caches,
  Kit C/D/E standalone, bundles, WATER + SCATTER registradas, janelas no CoreGui).
- **Total: 244 PASS / 0 FAIL.**
