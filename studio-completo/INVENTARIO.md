# ARKHER STUDIO — INVENTÁRIO (R15, 2026-09-13)

Base: `ArkherStudio_Completo_X.rbxl` → `ArkherStudio_Completo_GUIX.rbxl`
(410994 bytes, 10572 instâncias, VERIFY OK). Suite: **1040/1040**.
Audits: botões mortos 0, drops 0, P0 75 ok / 1 parcial / 0 ausente.

## EXISTE (funcionando de verdade, com teste)

- **Terrain Editor** (`12_Terrain` + server Terrain*): voxel engine, pincel
  mouse/toque, smooth/noise/hidro, undo — 49+43 testes.
- **Viewport Editor** (`13_Viewport` + server Transform/ViewportFrame):
  gizmo traduz/rotaciona/escala, multi-select, snap — 41 testes.
- **Modeler PRO** (`14_Modeler` + server Mesh* + `07_MeshX`): EditableMesh
  real (verts/faces), smooth, OBJ export/import — 95 testes.
- **Animator PRO** (`15_Animator` + server Anim* + `06_RigX`): keyframes,
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
- **Infra**: server 173 handlers + undo/redo + rate limit;
  ARKHER Input System 4 plataformas (`11_Input` + layouts baked);
  topbar/ribbon/menus reais (`03/09/10`); 4 plataformas sem conversão
  automática de controles.
- **Shell**: 19 LocalScripts assados (01–19), 2 servers; spec 1774 nós.
- Correções R15: limite 200-locais/chunk (namespaces TERD/ANIMA/RRWS/DO15/WLD),
  strips mobile M_AN/M_UI/M_RW órfãs agora assadas, shell sob Canvas, forwards.

## EXISTE (herdado, SEM cobertura da suite R10–R14 — usar com cautela)

- `05_StudioX` (painéis/overlays/footer), `06_RigX`/`07_MeshX` (fiação
  Cascadeur++/Blender++), `08_RealityX` (4104 linhas, cita D-O15),
  `10_Studio`, `engine_server.lua`, `modules/arkher_services.lua`.
- Publish/Teleport/Toolbox aparecem no código assado mas não têm testes
  dedicados nesta suite.

## FALTA (não existe ou não é real)

1. **Home/Explorer**: só painéis genéricos; sem editor completo.
2. **Linguagens**: sem Python/C++/C# e sem visual script funcionais.
3. **Multi-place**: sem Teleport+cutscene/automação (pós-studio, ok).
4. **Polimento**: acessibilidade full (contraste/alto), docs in-app.

## HONESTO (limites declarados, não bugs)

- Sem path tracing; sem streaming (props não-scriptáveis).
- VFX só em BasePart (limite do motor).
- UiTree/UiExport/RrwStats são leitura; Grade/luzes sem props numéricas.
- Undo cobre CRUD UI + perfis RRW; LOD/VFX/FX individuais sem undo.

## % FALTANTE p/ superar a indústria: ~17%

R15 entregou D-O15 + World (139 testes). Falta: Home/Explorer (4%),
linguagens+visual script (8%), multi-place+polish (5%).
