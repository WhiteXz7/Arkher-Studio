# CHECKLIST — O ÚNICO TESTE NO PLAY (rodar após a R6)

Abrir `ArkherStudio_Completo_GUIX.rbxl` no Roblox Studio, apertar **Play**,
seguir os itens e anotar OK/FALHA + print/log. Depois é só refinamento.

## 0. Boot (2 min)
- [ ] Output mostra `Arkher dividido: núcleo pronto` + `SELFTEST fim: 10+ pass, 0 fail` (V2/Decks podem falhar: órfãos conhecidos)
- [ ] Toast "SelfTest..." aparece na tela
- [ ] 7 abas no topo, página HOME com botões em linha horizontal

## 1. Núcleo edição — R4 (5 min)
- [ ] Clicar peça no viewport → seleciona (hierarquia acende + props mostram)
- [ ] INSERT > Model → nó aparece REVELADO na hierarquia + props acompanham
- [ ] Editar Transparency na properties → aplica na peça
- [ ] Edit > Desfazer → Transparency volta (undo cru)
- [ ] Excluir peça → some; Desfazer → volta
- [ ] MUNDO > Terreno VOXEL > APLICAR → bola de Grama no terreno
- [ ] Console: `_G.ArkherPipe()` → 1 linha com contadores

## 2. Scripting/run/cloud/terrain-2 — R5 (8 min)
- [ ] Edit > Script Studio > EXECUTAR (Lua `return 2+2`) → saida ret=4
- [ ] Linguagem Python > fatorial (painel hint) > EXECUTAR → ret=120 + mostra Lua
- [ ] BLOCOS > ADD print/lua/repeat > EXECUTAR → roda + mostra Lua gerado
- [ ] C# > soma 1..5 > EXECUTAR → ret=15
- [ ] LISTAR SCRIPTS → nomes; CARREGAR SELECAO (Script) → código; SALVAR
- [ ] Run > Play → peça cai (física); editar peça → erro "Em execução"; Stop → libera
- [ ] Game > Places do meu perfil → abre (com ou sem login: msg honesta)
- [ ] Terreno VOXEL > AGUA / ROCHA->MATERIAL / GERAR FLAT → aplicam
- [ ] Game > Ajuda do Studio → painel de ajuda

## 3. Anim/VFX/UX/inéditos — R6 (8 min)
- [ ] TRANSFORM > Move/Rotate/Scale → status mostra "Modo: X"; gizmo muda no viewport
- [ ] TRANSFORM > LocalGlobal → "Espaço: Global"; Lock → trava peça (arraste recusa)
- [ ] ANIMACAO > Pose A gravar > mover peça > tocar A (2s) → desliza de volta
- [ ] Animator X (abrir) → deck abre; RigX demo (06) → ossos Neon mexem
- [ ] INSERT: PointLight + ParticleEmitter + Sound numa peça → visíveis/audíveis
- [ ] Terreno VOXEL > APLICAR com centro=player → pinta onde o personagem está
- [ ] SELFTEST fim: 13+ pass, 0 fail (só V2/Decks podem falhar se órfãos)
- [ ] `_G.ArkherPipe()` → flush/nodes/creates contando

## 4. Final
- [ ] Anotar cada FALHA com print + trecho do Output → vira lista de refino
