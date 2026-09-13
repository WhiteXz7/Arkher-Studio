# ARKHER STUDIO — INVENTÁRIO (R14, 2026-09-13)

Base: `ArkherStudio_Completo_X.rbxl` → `ArkherStudio_Completo_GUIX.rbxl`
(401279 bytes, 10363 instâncias, VERIFY OK). Suite: **901/901**.
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
- **Infra**: server 159 handlers + undo/redo + rate limit (283997 bytes);
  ARKHER Input System 4 plataformas (`11_Input` + layouts baked);
  topbar/ribbon/menus reais (`03/09/10`); 4 plataformas sem conversão
  automática de controles.
- **Shell**: 17 LocalScripts assados (01–17), 2 servers; spec 1567 nós.

## EXISTE (herdado, SEM cobertura da suite R10–R14 — usar com cautela)

- `05_StudioX` (painéis/overlays/footer), `06_RigX`/`07_MeshX` (fiação
  Cascadeur++/Blender++), `08_RealityX` (4104 linhas, cita D-O15),
  `10_Studio`, `engine_server.lua`, `modules/arkher_services.lua`.
- Publish/Teleport/Toolbox aparecem no código assado mas não têm testes
  dedicados nesta suite.

## FALTA (não existe ou não é real)

1. **D-O15 dedicado**: sem editor próprio + sem testes (só menções).
2. **World Editor**: sem editor dedicado.
3. **Home/Explorer**: só painéis genéricos; sem editor completo.
4. **Linguagens**: sem Python/C++/C# e sem visual script funcionais.
5. **Multi-place**: sem Teleport+cutscene/automação (pós-studio, ok).
6. **Polimento**: acessibilidade full (contraste/alto), docs in-app.

## HONESTO (limites declarados, não bugs)

- Sem path tracing; sem streaming (props não-scriptáveis).
- VFX só em BasePart (limite do motor).
- UiTree/UiExport/RrwStats são leitura; Grade/luzes sem props numéricas.
- Undo cobre CRUD UI + perfis RRW; LOD/VFX/FX individuais sem undo.

## % FALTANTE p/ superar a indústria: ~30%

R14 entregou 2 editores completos (UI+RRW, 163 testes). Falta: D-O15 (8%),
World (5%), Home/Explorer (4%), linguagens+visual script (8%),
multi-place+polish (5%).
