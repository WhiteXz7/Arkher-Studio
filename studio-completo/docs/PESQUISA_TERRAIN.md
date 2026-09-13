# PESQUISA — Terrain Editor REAL (docs oficiais Roblox)

Fontes:
- https://create.roblox.com/docs/studio/terrain-editor
- https://create.roblox.com/docs/parts/terrain (environmental terrain)
- GitHub Roblox/creator-docs (terrain-editor.md, parts/terrain.md)

## Base técnica (não deduzir)

- Terrain = grade de **voxels 4×4×4 studs**, cada um com um material.
- Script: `Terrain:FillBlock/ FillBall / FillCylinder / FillRegion`,
  `WriteVoxels / ReadVoxels` (Region3 + resolucao 4), `Clear`,
  `SetWaterCell`... (detalhar na rodada do terrain com a API ref).
- Água = voxels de material Water + nível do mar (SeaLevel).

## Create (aba)

1. **Import**: heightmap (imagem) + colormap opcional numa região selecionada;
   Y da região define altura (preto = -Y/2, branco = +Y/2 do centro).
2. **Generate**: procedural numa região; **Biomes**: Arctic, Dunes, Canyons,
   Lavascape, Water, Mountains, Hills, Plains, Marsh; botão Generate.
3. **Clear**: limpa a região.
- Região = move/resize no **viewport 3D** (+ Selection Settings X/Y/Z + snap).

## Edit (aba)

1. **Select**: região retangular universal; Ctrl+C/V/X/D, Delete.
2. **Transform**: move (draggers), rotate (anéis), scale (handles) + X/Y/Z;
   ativa sozinha após paste/duplicate.
3. **Fill**: Fill (material na região) / Replace (origem→destino) + Apply/Enter.
4. **Sea Level**: nível da água.
5. **Draw / Sculpt / Smooth / Flatten / Paint** (brush):
   - Brush: forma **esfera/caixa/cilindro**, base size **1–64 studs**.
   - **Sculpt**: add/subtract + slider **strength**; Ctrl = subtract;
     Shift = Smooth temporário.
   - **Smooth**: média altos/baixos. **Flatten**: nivela. **Draw**: add.
   - **Paint**: pinta material (não muda forma) ou replace de material.
   - Cursor azul no viewport; câmera orbitável (não só de cima).

## Implicação pro nosso rebuild (futura rodada)

- NADA de "UI de editor 2D": ferramenta = **pincel no viewport 3D** +
  região selecionável + painel lateral de settings (material/bioma/size/
  strength/forma). Mouse: clique/arraste esculpe; Ctrl inverte; Shift suaviza.
- Backend: Terrain API real no servidor (FillRegion/WriteVoxels), com
  undo via ChangeHistoryService ou pilha própria + toast/log de prova.
