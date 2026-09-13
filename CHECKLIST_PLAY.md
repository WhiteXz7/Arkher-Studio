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

## 3b. Shell2 (rebuild EN — idêntico ao mockup)
- [ ] Menu: 12 menus abrem dropdowns EN; Terrain>Terrain Editor X abre V2
- [ ] Ribbon: Select/Move/Scale/Rotate trocam modo; Play/Pause/Stop rodam
- [ ] Ribbon: Undo/Redo desfazem; Save salva; Publish abre diálogo cloud
- [ ] Terrain: Generate/Erosion/Craters/Flatten/Smooth/Noise aplicam no mundo
- [ ] Console: erros do jogo aparecem; tabs All/Info/Warn/Error filtram
- [ ] Timeline: ● com seleção grava key + ◆ nas lanes; ▶ toca; ⏹ para
- [ ] Sim: Day/Physics/Water/Ambient alternam; Start avança o relógio
- [ ] Team: lista @nomes reais; Invite abre convite
- [ ] Assets: Tree/Crate/Lamp/Car/Coin/NPC nascem na frente da câmera
- [ ] Library/Resources: House/… constroem; Export/Import/Backup/Sync respondem
- [ ] Footer: FPS/Ping/Mem atualizam; Project abre cloud; Publish publica
- [ ] Overlays: compass gira; coords seguem câmera; layers escondem pastas
- [ ] Gizmo: Move/Rotate/Scale/Grid(3D)/Snap(grade) funcionam
- [ ] Curves: caption conta keys da sessão; Help (? no ribbon) abre Tools

## 3c. Input System R8 (4 plataformas)
- [ ] PC: toast "ARKHER Input: PC"; 1-5 trocam ferramenta; F enquadra seleção
- [ ] PC: WASD voa; RMB arrasta orbita; wheel aproxima; Ctrl+D duplica
- [ ] Ribbon: Anchor/Snap/Group novos funcionam na seleção
- [ ] Models: MeshPart/Decal/Texture/Color/Material/Surface aplicam
- [ ] Models: Join/Split/Group/Ungroup/Reset Pivot/Align/Distribute/Mirror
- [ ] `_G.ArkherInput.setPlatform("Mobile")` → layout mobile; M_T_Move abre numérico
- [ ] Mobile: steppers + APPLY movem a peça; M_Cat_Terrain abre menu Terrain
- [ ] `_G.ArkherInput.setPlatform("Console")` → layout console; Y abre radial
- [ ] `_G.ArkherInput.setPlatform("VR")` → painel VR; V_Snap/V_Teleport respondem
- [ ] `_G.ArkherInput.setPlatform("PC")` → desktop volta intacta

## 3d. Input System R9 (multi-select + prefs + gamepad/VR)
- [ ] PC: B arrasta caixa e seleciona vários (marquee azul some no fim)
- [ ] PC: L desenha laço; K no Model seleciona os filhos; Ctrl+Delete apaga set
- [ ] Settings: clicar slot + tecla remapeia; RESET volta; Ctrl+=/- escala UI
- [ ] `_G.ArkherInput.setLang("PT")` traduz labels; `setLang("EN")` restaura
- [ ] Mobile: arrastar na tela vazia = caixa; tap no selecionado = filhos
- [ ] Console: segurar A + stick = caixa; X 2x = filhos; Back = radial editores
- [ ] Console: DPad percorre radial + botões do deck sem travar em oculto
- [ ] VR: gatilho 2x = filhos; X segurado deleta; V_Spatial ancora/devolve painel
- [ ] Tools→Publish sem pybridge: erro honesto (sem falso sucesso)

## 4. Final
- [ ] Anotar cada FALHA com print + trecho do Output → vira lista de refino
