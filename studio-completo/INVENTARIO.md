# ARKHER STUDIO — INVENTÁRIO (R20, 2026-09-14)

Base: `ArkherStudio_Completo_X.rbxl` → `ArkherStudio_Completo_GUIX.rbxl`
(432379 bytes, 12647 instâncias, VERIFY OK). Suite: **1157/1157**.
Audits: botões mortos 0, drops 0, layout 0 violações,
P0 75 ok / 1 parcial / 0 ausente.

## EXISTE (funcionando de verdade, com teste)

- **Terrain Editor** (`12_Terrain` + server Terrain*): voxel engine, pincel
  mouse/toque, smooth/noise/hidro, undo — 49+43 testes.
- **Viewport Editor** (`13_Viewport` + server Transform/ViewportFrame):
  gizmo traduz/rotaciona/escala, multi-select, snap — 41 testes.
- **Modeler PRO** (`14_Modeler` + server Mesh* + `07_MeshX`): EditableMesh
  real (verts/faces), smooth, OBJ export/import — 95 testes.
- **Animator PRO** (`15_Animator` + server Anim* + `07_MeshX`): keyframes,
  preview, scrub, IK, JSON anim — 100 testes.
- **UI Editor R14** (`16_UI` + 10 server Ui*): cria/move/redimensiona/
  texto/duplica/deleta, tree, JSON UI v1, publish StarterGui, drag no
  canvas, escopo PlayerGui (nada fora dele) — 73 testes.
- **RRW R14** (`17_RRW` + 8 server Rrw*): 5 perfis (enums reais
  LightingStyle+Technology), 6 efeitos pós (clamps), céu static/cycle,
  atmosfera/nuvens, LOD tiers com histerese (troca real por distância),
  4 VFX fire/smoke/emitter/light, stats fps/parts — 90 testes.
- **D-O15 R15** (`18_Do15` + 7 server Do15*): stats reais (Stats svc,
  fps/mem/triângulos/rede/streaming), audit do mundo, optimize com undo
  (no-touch/no-shadow/anchor), preload de assets, relevance sets por
  distância (histerese, restaura estado inicial), GC, report JSON — 67 testes.
- **World R15** (`19_World` + 7 server World*): info/bounds, gravidade com
  undo, spawns CRUD (add na posição do player), saves/load em ServerStorage,
  quarantine/restore, clear com autosafe — 72 testes.
- **Home/Explorer R16** (`20_Home`, sem server novo): file ops via MenusBus
  real (File/Save/OpenPublish), tree via Snapshot com filtro, SELECT espelha
  seleção real, props rename/vis/dup/del + Undo histórico — 30 testes.
- **Script Studio R16** (`21_Script` + server ScriptGet): Lua real
  (load/edit/save + Enabled run/stop), Python-subset→Luau honesto
  (4sp, sem continue/step), blocos ev+act+if compilados p/ Luau, console
  LogService com filtro erro — 40 testes.
- **Places R16** (`22_Places` + server PlaceList + `place_automation.py`):
  lista universo paginada, teleport real, cria place (CreatePlaceAsync),
  cutscene TweenService com fade + restore de câmera, automação Open Cloud
  (CLI stdlib, dry-run honesto sem chave) — 29 testes.
- **Infra**: server 174 handlers + undo/redo + rate limit;
  ARKHER Input System 4 plataformas (`11_Input` + layouts baked);
  TOPBAR ÚNICA real (`09_Topbar` + `03_Menus`: header + 18 abas +
  162 botões, tudo fiado); 4 plataformas sem conversão automática
  de controles.
- **Shell**: 22 LocalScripts assados (01–22), 2 servers; specs
  shell 2289 + shell2 1931 nós; 64 ícones vetoriais (0 emoji).
- **Layout limpo R17** (`audit_layout.py`, 0 violações): 73 painéis dos
  editores saíram de baixo do ribbon (y100→128) e de cima do footer
  (status→y784); HUD O2 + FR2_Help agora escondem com os editores (DESK 19
  nomes nos 11 clients); HO10_File/Tree descolados; TE3_Water para o canto
  inferior (cobre só o quadrante, centro livre); mobile (strips/labels/
  drawer/props) sem sobreposição; modais com ZIndex 50 — 2 testes novos.
- **Topbar única R18** (`build_shell.py` + `hide_base_chrome.py` +
  `09_Topbar`): 3 topbars visíveis (TitleBar/MenuBar/Ribbon base +
  MenuBar2/Ribbon2 + ArkherTop morto) viraram 1 (ArkherTop 1568x120:
  18 menus File..Tools + search/bell/user, 9 abas, 42 botões com
  ícones vetoriais); base antiga escondida no bake (3 bytes Visible),
  MenuBar2/Ribbon2 removidos, clones X do 03 aposentados (ações
  re-homed: AnimKeyB/GoB→menu Animation, PlacesProfile já no Game);
  42/42 alvos resolvidos (audit 0 mortos). Bugs reais corrigidos:
  MenusBus sem fallback (cmds externos viravam no-op silencioso) e
  propOf `.key` vs PropsAll `.name` (Anchor/Snap travados) — 12 testes
  novos (incl. Anchor toggle full-stack true→false no server real).
- **Faixas mortas R19** (`hide_base_chrome.py` estendido): DocumentTabs
  (a 2ª "faixa de abas" sob a topbar), LeftTabs, ChatBar e, no footer,
  CommandBar + botão Arkher — TODOS os botões eram WIP ("Em
  desenvolvimento", sem função) e os 2 inputs sem fiação; escondidos no
  bake (8 refs Visible=false). Funções reais correspondentes: Places
  (aba SCENES), Team (TM2 + aba PLUGINS), Command Bar executável
  (aba SCRIPTS), Help (aba HELP). ResetLayout não restaura mais as
  faixas mortas.
- **Topbar quadro-1 R20** (`build_shell.py` + `gen_topbar_wiring.py` +
  `09_Topbar` + LANG `11_Input`): dropdowns desktop aposentados (M2_* x0
  no bake) — os 166 itens dos 18 menus + 17 funções ribbon-only do R18
  viraram 162 botões em 18 páginas (HOME..HELP, ≤20/aba, regra do
  quadro-1 da referência Renascido); header com logo/slogan/search/bell
  vetorial/user; abas com ícone+selo. Cobertura: 140 acts diretos + 5
  via equivalentes provados (RunToggle/Pause/Stop, api Undo/Redo);
  OpenPublish removido (idêntico ao Publish — mesmo diálogo).
  162/162 alvos resolvidos (audit 0 mortos, layout 0 violações);
  10 ícones novos (copy/cut/paste/expand/bell/home/drop/plug/note/fire,
  `record_icons_py.py` validou 25/25 bit-a-bit, 0 divergentes).
  Testes novos: Group full-stack (Model real), RecKeyA honesto,
  PlacesProfile (diálogo real), header bell/user, ≤20/aba.
- Correções R16: ScriptGet duplicado removido (1 definição), pyCompile
  (elif/else após dedent, range 1-arg com fold, indent 4sp validado,
  range-step recusado), exclusão mútua 12–22 completa.

## EXISTE (herdado, SEM cobertura da suite R10–R16 — usar com cautela)

- `05_StudioX` (painéis/overlays/footer), `06_RigX`/`07_MeshX` (fiação
  Cascadeur++/Blender++), `08_RealityX` (4104 linhas, cita D-O15),
  `10_Studio`, `engine_server.lua`, `modules/arkher_services.lua`.
- Publish/Toolbox aparecem no código assado mas não têm testes
  dedicados nesta suite. (Teleport AGORA tem: PL22.)

## FALTA (não existe ou não é real)

1. **Polimento**: acessibilidade full (contraste/alto), docs in-app.
2. **C++/C#**: EXCLUÍDOS — impossível no motor Roblox (só Luau executa);
   Python-subset e blocos compilam p/ Luau de verdade. Não é falta
   implementável; é limite da plataforma.

## HONESTO (limites declarados, não bugs)

- Sem path tracing; sem streaming (props não-scriptáveis).
- VFX só em BasePart (limite do motor).
- UiTree/UiExport/RrwStats são leitura; Grade/luzes sem props numéricas.
- Undo cobre CRUD UI + perfis RRW; LOD/VFX/FX individuais sem undo.
- PlaceList/Teleport/CreatePlace exigem jogo PUBLICADO + online
  (CreatePlace não funciona em Play Solo; template precisa ser seu).
- C++/C# nunca executarão no Roblox — sem promessa futura.
- Controles de janela da base (Minimize/Maximize/Close) aposentados com
  a TitleBar antiga: no Play, F8 mostra/esconde a UI (núcleo 01, real).

## % FALTANTE p/ superar a indústria: ~15%

R20 entregou o quadro-1 da referência Renascido (header + 18 abas +
162 botões, 0 mortos, M2_* zerado no bake, +4 testes). Novo programa:
cada quadro da referência é 1 UI — os ~60 quadros de editores (11+)
mapeiam sobre os 10 editores reais existentes (remake visual +
preencher lacunas, não do zero). Falta: remake dos editores pelos
quadros (~12%) + polish/acessibilidade/docs (3%).
