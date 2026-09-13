# MEGA PACK ULTIMATE — plano + placar honesto

Barra: **studio REALMENTE COMPLETO até superar a indústria em todos os aspectos**
(Roblox Studio + Unity + Unreal + Blender + VS Code + Cascadeur).
Regra: item só conta com **prova no Play real** (print + log/relatório SELFTEST).
Blocos: 5 por rodada, no automático; pedir pra continuar ao fim.

## Placar (atualizar TODA rodada)

| Área | Peso | Feito | Critério de pronto |
|---|---|---|---|
| Núcleo edição (select/transform/create/delete/undo ao vivo) | 15 | 2 | Exercer cada op no Play com prova |
| Hierarchy ao vivo | 8 | 1 | Select/marca/atualiza sempre (print) |
| Properties ao vivo | 8 | 1 | Mostra+edita+aplica sempre (print) |
| Terrain real (spec docs) | 8 | 0.5 | Ferramentas Create/Edit + brush no viewport |
| Scripting (editor+LSP+Python+visual+C#) | 10 | 1 | Editar+rodar Lua+Python; visual funciona |
| Run/debug no Play | 6 | 0.5 | Play/Pause/Stop + erros visíveis |
| Cloud/publish/places reais | 8 | 1.5 | Fim-a-fim com conta/place/template reais |
| Ribbon/topbar/menus UX | 7 | 3 | 7×23 antigo + horizontal + ícones (print) |
| Animação/rig | 6 | 0.5 | Rig real mexendo peça |
| Materiais/VFX/áudio/física | 8 | 0.5 | Um de cada aplicado e visível |
| Provas no real (selftest/prints/auditoria) | 6 | 1.5 | SELFTEST verde + audit_props 0 |
| Docs/ajuda/onboarding | 3 | 0 | Ajuda dentro do studio |
| Inéditos (além da indústria) | 7 | 0 | 3+ sistemas que ninguém tem |
| **TOTAL** | **100** | **13** | **FALTAM 87** |

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
