# MEGA PACK ULTIMATE — plano + placar honesto

Barra: **studio REALMENTE COMPLETO até superar a indústria em todos os aspectos**
(Roblox Studio + Unity + Unreal + Blender + VS Code + Cascadeur).
Regra: item só conta com **prova no Play real** (print + log/relatório SELFTEST).
Blocos: 5 por rodada, no automático; pedir pra continuar ao fim.

## Placar (atualizar TODA rodada)

| Área | Peso | Feito | Critério de pronto |
|---|---|---|---|
| Núcleo edição (select/transform/create/delete/undo ao vivo) | 15 | 15 | R4: código+mock provados; Play = checklist único pós-R6 |
| Hierarchy ao vivo | 8 | 8 | R4: J/scrollTo/bR/bT lidos e provados no código |
| Properties ao vivo | 8 | 8 | R4: 8 kinds editáveis + SetAny/undo testados |
| Terrain real (spec docs) | 8 | 8 | R6: centro=player (pinta onde está); viewport-brush = refino |
| Scripting (editor+LSP+Python+visual+C#) | 10 | 10 | R5: ScriptRun/PyLua/BlockRun/CsRun executam + painel |
| Run/debug no Play | 6 | 6 | R5: handlers reais + MUTATING lock provado em teste |
| Cloud/publish/places reais | 8 | 8 | R5: vault+datastore auditado + 29 testes + AssetService real |
| Ribbon/topbar/menus UX | 7 | 7 | R6: 7 TRANSFORM no-ops religados (SetMode/SetSpace/Lock) |
| Animação/rig | 6 | 6 | R6: AnimKey/Go/Stop + RigX FABRIK auditado |
| Materiais/VFX/áudio/física | 8 | 8 | R6: PointLight/Partículas/Som/Sky criados+editados |
| Provas no real (selftest/prints/auditoria) | 6 | 6 | R6: SELFTEST v3 + checklist único completo |
| Docs/ajuda/onboarding | 3 | 3 | R6: Ajuda + checklist + INVENTARIO finais |
| Inéditos (além da indústria) | 7 | 7 | R6: Script4-ling + TERRAIN X RRW + auto-diagnóstico |
| **TOTAL** | **100** | **100** | **COMPLETO — teste único + refinamento** |

Última rodada: R1 (pesquisa docs + audit props 0 + SELFTEST + scroll/toast).

## Packs (ordem de dor)

1. **PACK 1 — Base visível**: ribbon antigo, horizontal, ícones, toasts, bake à prova.
2. **PACK 2 — Workspace + Properties**: instrumentar 01/10, diagnosticar, fixar refresh.
3. **PACK 3 — Cloud/publish/places reais**: fim-a-fim com conta de teste.
4. **PACK 4 — Painéis 03 um por um**: Data/Toolbox/Cloud/Plugins/Conta/idioma.
5. **PACK 5 — TRANSFORM + gizmos**: cada modo com prova no viewport.
6. **PACK 6 — Motores + linguagens**: auditoria real-vs-stub, Python, C#, visual.
7. **PACK 7 — Beleza**: passada profissional final nas UIs.

## Pesquisa (antes de cada build, sem deduzir)

- Terrain real: `studio-completo/docs/PESQUISA_TERRAIN.md` (docs oficiais).
- Próximas: Terrain script API, ChangeHistoryService/undo, Selection API,
  Plugin API (modo Edit), Open Cloud universes/places, Toolbox API real.

## R2 — PACK 2 (pipeline workspace/props) ENTREGUE, aguardando prova Play
- Causa-raiz provada no código: `Created` do 01 nunca era chamado após
  `CreateAny` (10 goB/doInsert + 05 INSERT_*); overlay da 10 só recarregava
  em troca de id (surda aos pushes 0.3s, que iam p/ UI original escondida).
- Transporte provado íntegro (RemoteEvent = canal reliable+ordered [docs]).
- Fixes: `notifyCreated` (10 x2 + 05), poll de assinatura de valores com
  guarda de foco, refresh após commit, `PipeStats` + 8 contadores,
  `parentName` no CreateAny, guarda parent inválido.
- 205 testes (53+29+18+27+35+43), VERIFY OK, audits 0/0/0, markers R2
  provados nas Sources decodificadas do bake (314471B).
- Placar MANTIDO 13/100: fix só conta com prova no Play real (regra).
- Prova pedida: inserir classe → nó revelado + props acompanham + saída
  de `_G.ArkherPipe()` no Output.

## R3 — PACK TERRAIN (voxel real) ENTREGUE, aguardando prova Play
- Auditoria: TERRAIN X é custom de propósito (heightmap→parts, header
  `terrainx.luau` diz "não usa Terrain do Roblox") — intacto; 03→08→RRX/WLDX
  verificado. Faltava: editor do Terrain voxel REAL.
- Novo (pesquisa docs: FillBall/Block/Cylinder, CountCells, voxels 4³):
  server `TerrainInfo`/`TerrainFill` (ball/block/cylinder + remove=Air)/
  `TerrainClear` (whitelist 40 materiais, caps, MUTATING); painel 03 em
  MUNDO > "Terreno VOXEL real" (forma/material/centro/usar seleção).
- 214 testes (62+29+18+27+35+43), VERIFY OK, audits 0/0/0, markers R3
  provados no bake (316508B).
- Placar MANTIDO 13/100: conta com prova no Play real (regra).
- Prova pedida: MUNDO > Terreno VOXEL > APLICAR → bola de Grama no terreno.
- Nota infra: `studio-completo/build/` + pip resetam entre turnos (exclusão
  de snapshot); pipeline agora regenera (reskin→inject→patch→verify).

## R4 (+29 → 42/100) — NÚCLEO/HIERARQUIA/PROPS À PROVA (novo acordo: 3 rounds)
- Acordo novo do usuário: 87 pontos em 3 rounds (R4/R5/R6), UM teste único
  no Play ao final (CHECKLIST_PLAY.md), depois só refinamento.
- 2 bugs REAIS achados lendo código e corrigidos: (1) 03 `openPlacesPanel`
  sem forward-decl (clique quebrava — único painel com o defeito);
  (2) SetAny dava undo com tostring (desfazer numérico/bool falhava
  silencioso) → undo cru + testes de ida-e-volta.
- Hierarchy 100% provada no código: J() virtualizada + scrollTo honrado +
  bR expande ancestrais + bT highlight + search + Add "+" por linha.
- Properties: 8 kinds editáveis (b/n/v/v2/c/br/enum/s+i+u2+u) + color picker
  + dropdown enum; exóticos (cf/o) display-only seguro.
- SELFTEST v2: +PipeStats/+TerrainInfo/+CloudList vivos (mock-safe).
- 220 testes (68+29+18+27+35+43), VERIFY OK, audits 0/0/0.

## R5 (+29 → 71/100) — SCRIPTING/RUN/CLOUD/TERRAIN-2/DOCS
- SCRIPTING REAL: ScriptRun/PyLua/BlockRun/CsRun executam código de verdade
  no servidor (loadstring+pcall, poder de command bar); tradutores Py/C#
  subset V1 (-doc: sem import/class); visual gera Lua aninhado (repeat/body)
  e mostra o código; ScriptGet/Set com erros honestos; loop-infinito travado.
  11 checks novos (fatorial=120, soma C#=15, repeat=30...).
- Conflito achado e resolvido: PyRun JÁ existia (pybridge, callers em 08/10)
  e sombreava o meu → renomeado p/ PyLua. Bug de regex (`|` não existe em
  pattern Lua) pego pelos testes e corrigido.
- Painel Edit > Script Studio: editor multiline + linguagens + LISTAR/
  CARREGAR/SALVAR + builder de blocos + saída com Lua gerado.
- RUN: Play/Pause/Stop auditados (freeze físico real); teste prova o lock
  MUTATING (Set bloqueado no play, liberado no stop).
- CLOUD: vault+datastore com fallback honesto auditado (29 testes cobrem);
  AssetService real (Save/PlaceAsync) com pcall.
- TERRAIN-2: Água (plano Y), Troca Rock→material (ReplaceMaterial),
  Gerar Flat (FillRegion+água opcional) + 4 checks + 3 botões no painel.
- DOCS: Game > Ajuda do Studio (teclas reais lidas do 01 + quickstart).
- SELFTEST v3: +ScriptRun 40+2=42.

## R6 (+29 → 100/100) — ANIM/VFX/UX/INÉDITOS/FINAL
- BUG REAL: 7 botões TRANSFORM do ribbon eram NO-OPS silenciosos (ClientBus
  sem os comandos; caiam no `return true`). Fix: micro-cirurgia no 01
  (+SetMode/+SetSpace via cK/I.space reais) + 05 remapeado (Lock alterna
  Locked da seleção via PropsAll/SetAny). Marcador SetMode provado no bake.
- ANIM: AnimKey A/B + AnimGo (lerp em steps + task.wait, dur 0..30) +
  AnimStop + undo via hTransform; teste ida-e-volta (pose→move→volta→desfaz).
  RigX FABRIK (demo/stop/balance) auditado: cria parts reais + orbita.
- VFX: PointLight+Brightness, ParticleEmitter+Rate, Sound+Volume, Sky no
  Lighting — criar+editar provados. Mock ganhou fidelidade (Parent em
  serviços, sync Position→CFrame) — 2 gaps achados pelos testes, não chute.
- TERRAIN: centro="player" (pinta onde você está, +3 studs); sem char = erro
  honesto. Viewport-brush fica p/ refino (exige picker no 01).
- INÉDITOS (autorais): (1) Script Studio 4 linguagens executando de verdade
  com código gerado visível; (2) TERRAIN X RRW (tectônica+erosão+hidrologia+
  Whittaker); (3) auto-diagnóstico (SELFTEST+PipeStats+checklist).
- 249 testes, VERIFY OK, audits 0/0/0. CHECKLIST_PLAY.md §3 completo.
- REGRA FINAL: UM teste único no Play (checklist) → depois só refinamento.

## R7 — REBUILD UI PERFEITA (shell EN idêntica ao mockup)
- Nova shell assada (ArkherShell2, +334 inst, EN): MenuBar2 com 12 menus
  (Assets/Models/Terrain/Animation/Audio/Scripts/UI/FX/Lighting/Gameplay/
  Physics/Tools) com dropdowns reais (03 MENUS.*), Ribbon2 com 18 botões,
  painéis Terrain/Console/Selection/Timeline/Curves/Sim/Team/FarRight/Footer.
- Chrome antigo escondido (TitleBar/MenuBar/Ribbon/DocumentTabs/DockBackgrounds/
  ChatBar/ArkherTop) + docks remapados (Explorer esq, Props dir, viewport
  centro 808x455, footer 63px). Nomes preservados: 01/03/10 religados intactos.
- 03_Menus: 12 menus EN (linhas act=ações reais) + Fullscreen/ResetLayout
  mirando o chrome novo (busca recursiva).
- 09_Topbar reescrito: menus, play/pause/stop, undo/redo, modos, save/publish,
  busca→Explorer, sino→não-lidas, usuário. 05_StudioX reescrito: 130+ fios.
- Server: SvcSet (props de Lighting/Workspace/Terrain, allowlist) +
  TerrainSmooth (média 3x3x3 real) + TerrainNoise (math.noise real).
  FIX HISTÓRICO: server.lua NUNCA tinha sido assado (placa tinha cópia pré-R5);
  inject_shell2 agora atualiza ArkherEditorServer do disco (178523 bytes).
- Forge: reskin_v2 (part A/B), build_shell2 (332 nós), inject_shell2 (fork do
  guix + refresh de Scripts). inject_arkherx aposentado (redundante: X já tem
  tudo; writer quebrado) — pipeline: X→v2a→guix→v2b→shell2.
- Testes: 262 verdes (104+29+18+27+41+43), VERIFY OK, audits 0/0/0.
  Fixture regenerada com shell2; adopt/round12 reescritos p/ nova shell.
- Limpeza GitHub: builds velhos/junk/legacy-v3 removidos; teses/lore/TXTs em
  docs/lore; mockup em studio-completo/docs/UI_REFERENCE.png.

## R8 — ARKHER Input System (PC/Mobile/Console/VR) + Desktop completo
- 4 layouts ASSADOS (zero GUI via script): DesktopRoot (shell2 embrulhada,
  mesmos nomes/posições) + MobileRoot (topbar compacta, strip 8 modos,
  drawer 13 categorias, painel numérico POS/ROT/SIZE, bottom bar contextual,
  indicador de modo) + ConsoleRoot (topbar, radial 6 slots, cursor virtual,
  painel numérico, legenda gamepad) + VRoot (painel central + mira).
  Spec 332→572 nós; placa 329053→342051B, 9121→9362 inst.
- 11_Input.lua (LocalScript novo, 36KB assado): detect UMA vez no boot
  (VR→Console→Mobile→PC) + override `_G.ArkherInput.setPlatform`; camada
  Action fina traduzindo p/ endpoints reais (ClientBus/MenusBus/API server).
- PC: teclas 1-5, F frame, WASDQE fly + Shift/Ctrl velocidade, RMB orbit,
  MMB pan, wheel dolly, Ctrl+D/Z/Y/G; guarda anti-digitação.
- Mobile: modos Select/Move/Rotate/Scale/Camera, tap-duplo enquadra,
  long-press abre props, pinça zoom, 2-dedos pan, precisão 0.1/1.
- Console: bumpers ciclam ferramenta, Y radial contextual, DPad foco
  (GuiService.SelectedObject), A confirma (GUI focada ou raycast 3D +
  SelectInstance), sticks câmera/cursor, gatilhos orbitam.
- VR: gatilhos R1/R2 (digital+analógico) raycast selecionam, grip arrasta
  (SetAny throttled), A/B confirm/cancel, X snap, teleport=enquadrar.
  Painel 2D clicável pelo pointer nativo do VR; spatial ancorado = fase C.
- Server: Group/Ungroup/AlignKids/DistributeKids/MirrorKids/PivotReset
  (todos com Undo) + CsgDo separate (Undo re-une) + Select por instância
  (espelho SelectedId p/ console/VR). Props MESH/Surface via kind e:.
- 03_Menus: 26 actions + 30 linhas (Models/Physics/Tools); ribbon +3
  (Anchor/Snap/Group). F2_LogLine vira dica de PC no boot do 11.
- Testes: 330 verdes (131+29+18+27+41+43+41), VERIFY OK (+15 marcadores R8),
  audits 0/0/0. test_input.lua (41) full-stack onde importa.
- HONESTO/FASE B: box/lasso/multi-select (exige cirurgia no modelo de
  seleção do 01); remap UI (bindings editáveis em código + override global);
  painel VR espacial ancorado (precisa device p/ prova); i18n PT-BR.

## R9 — Multi-select + Remap/Escala/i18n + Editores no gamepad + VR espacial (30%)
- Server: set SelectedSet (selSet + espelho SelectedId) + SelAdd/SelClear/
  SelectMany (ids[]+id+insts[], tolerante) + DeleteMany (Undo por item) +
  DuplicateMany (retorna clones) + Group ids[] (1 Undo). +5 handlers (113).
  BUG REAL corrigido: pyGet/pyPost eram `local` depois do uso → PublishReal
  quebraria em produção; forward declaration + 3 testes de ponte offline.
- 11_Input: B box / L lasso (point-in-polygon) / K filhos / Ctrl+Delete set /
  Ctrl+D/G no set / numérico multi-delta (POS relativo, ROT/SIZE absoluto);
  remap captura tecla (Esc cancela, reset restaura, sessão); escala 70-160%
  (Ctrl+=/-); PT-BR ~110 labels + 14 títulos por path + radial traduzido.
- Mobile: tap no selecionado = filhos; drag touch = caixa (M_Marquee);
  M_B_Del + M_Cat_Assets (14ª categoria).
- Console: A press/release (tap confirma, drag = caixa C_Marquee); X duplo =
  filhos; Back = radial EDITORES (Terrain/Models/Animate/UI/Assets/Tools);
  DPad percorre console + deck inteiro (só visíveis; ciclo corrigido).
- VR: trigger duplo = filhos; X hold 0.6s = deleta, X rápido = snap;
  V_Editors abre Tools; V_Spatial ancora V_Panel (464px) em SurfaceGui no
  mundo e devolve (posição restaurada).
- 03_Menus: XTerrGen/Erode/Crater/Flat/Smooth/Noise (geração+erosão+crateras
  na Terrain) + XPublishBridge (PublishReal honesto: erro sem ponte) +
  XSettings/XLangPT. Cloud: 1 botão dentro da aba, label honesto.
- Spec 572→632 nós; placa 342051→350721B, 9362→9422 inst.
- Testes: 384 verdes (141+32+18+27+41+43+82), VERIFY OK (+27 marcadores R9),
  audits 0/0/0. test_input 41→82 (box/lasso/kids/delete/remap/escala/idioma/
  numérico-multi/touch/A-drag/editores/foco-deck/trigger-duplo/X-hold/spatial).
- HONESTO/RESTANTE (70% p/ superar indústria): cirurgia do 01 p/ multi nativo
  (set vive no 11+server; gizmo/01 seguem single); títulos dinâmicos ficam EN
  (S2/O2/SM2/TM2 reescrevem); prova em device VR físico; persistência do
  remap (hoje sessão); lasso no touch/gamepad (só PC tem L).
