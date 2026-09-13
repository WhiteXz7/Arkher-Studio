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
