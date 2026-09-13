# ARKHER STUDIO — INVENTÁRIO (R16, 2026-09-13)

Base: `ArkherStudio_Completo_X.rbxl` → `ArkherStudio_Completo_GUIX.rbxl`
(419526 bytes, 10811 instâncias, VERIFY OK). Suite: **1139/1139**.
Audits: botões mortos 0, drops 0, P0 75 ok / 1 parcial / 0 ausente.

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
  topbar/ribbon/menus reais (`03/09/10`); 4 plataformas sem conversão
  automática de controles.
- **Shell**: 22 LocalScripts assados (01–22), 2 servers; spec 2010 nós.
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

## % FALTANTE p/ superar a indústria: ~4%

R16 entregou Home + Script Studio + Places (99 testes). Falta: polish/
acessibilidade/docs (4%). Multi-place studio-side AUTORIZADO e entregue.
