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

## 3. (R6: anim/vfx/inéditos/beleza — checklist entra na R6)
