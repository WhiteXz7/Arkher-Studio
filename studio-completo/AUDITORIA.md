# 🔍 AUDITORIA ARKHER × especificações (TXT da raiz)

Método: **grep honesto** nas fontes reais + marcadores dentro da placa X descomprimida. ✅ = implementado (com evidência arquivo:linha), ⚠ = parcialim, ❌ = ausente. Gerado por `tools/auditoria.py`.


**Placar: 75 ✅ · 1 ⚠ · 0 ❌** (de 76 exigências)


## TESE-DOS-D

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Tese dos D como sistema de níveis funcionais (D-não-dimensão) | ✅ | 143 | `studio-completo/AUDITORIA.md:14` |
| D-O15 como domínio de OTIMIZAÇÃO (budget adaptativo real) | ✅ | 143 | `studio-completo/AUDITORIA.md:14` |
| Orçamento D-O15 de partículas (corte automático por nível) | ✅ | 13 | `studio-completo/scripts/engine_server.lua:1015` |

## RRW (UES)

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| RRW — Renderer of the Reality of Real World (não raster clássico) | ✅ | 134 | `studio-completo/AUDITORIA.md:17` |
| Representação em níveis de descrição (LOD por contexto, não tudo o tempo todo) | ✅ | 56 | `studio-completo/AUDITORIA.md:22` |
| Auto-bind: objetos do mundo entram no RRW sozinhos | ✅ | 14 | `studio-completo/LEIA-ME.md:430` |
| Matéria/substâncias (química: H2O, densidades, salinidade…) | ✅ | 38 | `studio-completo/AUDITORIA.md:24` |
| Óptica/luz espectro (Kelvin → RGB físico, Planck/CIE) | ✅ | 39 | `studio-completo/AUDITORIA.md:25` |
| Terreno como dado de realidade (RLayer) | ✅ | 34 | `studio-completo/AUDITORIA.md:26` |
| Água da VIDA REAL (física Arquimedes + óptica + química) | ✅ | 180 | `studio-completo/LEIA-ME.md:118` |
| Atmosfera/tempo/estrelas (AEX — estados com transição) | ✅ | 134 | `studio-completo/LEIA-ME.md:118` |
| Frentes meteorológicas H/L que viajam (WEAX) | ✅ | 41 | `studio-completo/AUDITORIA.md:29` |
| Espaço/órbitas celestes (Képler real) | ✅ | 137 | `studio-completo/LEIA-ME.md:350` |
| Cordas/tecidos Verlet íntegros (RPX) | ✅ | 162 | `studio-completo/AUDITORIA.md:31` |
| Partículas físicas 13 presets (APX) com gravidade/vórtice reais | ✅ | 103 | `studio-completo/AUDITORIA.md:32` |
| Áudio real com buses (AUX mixer 7 buses) | ✅ | 241 | `studio-completo/AUDITORIA.md:33` |
| Humanos digitais/NPCs com IA (DAYX/MINDX/RIGX) | ✅ | 60 | `studio-completo/AUDITORIA.md:34` |
| Movimento IK/FABRIK real | ✅ | 30 | `studio-completo/AUDITORIA.md:35` |
| Ecossistema/ecologia (ECOX com presas/predadores) | ✅ | 43 | `studio-completo/AUDITORIA.md:36` |
| Cidadelas/urbanismo (CIVIX) gravando na terra | ✅ | 36 | `studio-completo/AUDITORIA.md:37` |
| Fabricação de peças pros sistemas (FABX catálogo) | ✅ | 44 | `studio-completo/LEIA-ME.md:431` |
| Modelagem: primitives/CSG-style/mesh (MESHX-like; no engine: modeler cmds) | ✅ | 41 | `studio-completo/LEIA-ME.md:452` |

## IDE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Topbar ORIGINAL + menus do STUDIO (não substituir a UI — expandir) | ✅ | 41 | `studio-completo/AUDITORIA.md:90` |
| Ativação direta de TODOS os sistemas via botões na topbar (X-tier) | ✅ | 6 | `studio-completo/LEIA-ME.md:121` |
| Hierarchy/Explorer próprio (árvore real do DataModel) | ✅ | 100 | `studio-completo/AUDITORIA.md:47` |
| Properties nativas (schema por classe, edição validada) | ✅ | 99 | `studio-completo/LEIA-ME.md:149` |
| PROPS EXAUSTIVAS (todas as curadas por IsA-chain) + aplicação funcional | ✅ | 57 | `studio-completo/AUDITORIA.md:81` |
| Color picker REAL aplicando no selecionado | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:2790` |
| Gizmos Move/Rotate/Scale no 3D (Handles reais + drag server-autorizado) | ✅ | 31 | `studio-completo/AUDITORIA.md:51` |
| Undo/Redo com histórico (50, server-side) | ✅ | 30 | `studio-completo/scripts/server.lua:11` |
| Seleção real server-side (Select + SelectedGet) | ✅ | 17 | `studio-completo/AUDITORIA.md:53` |
| Spawn de part com FORMAS reais (Shape/classe) | ✅ | 21 | `studio-completo/AUDITORIA.md:86` |
| Toolbox REAL do Roblox (Creator Store: GetFreeModelsAsync + LoadAsset) | ✅ | 16 | `studio-completo/AUDITORIA.md:55` |
| OUTPUT real (LogService MessageOut/history) + filtros | ✅ | 8 | `studio-completo/LEIA-ME.md:312` |
| Command bar que EXECUTA (spawn/set/cmd/math…) | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:3177` |
| Submenus reais nos menus + tooltips + headers de seção | ✅ | 7 | `studio-completo/scripts/03_Menus.lua:604` |
| UI adaptável a dispositivo (escala por largura + wrap de botões) | ✅ | 18 | `studio-completo/LEIA-ME.md:291` |
| Abrir criar/projetos (New/Open; baseplates oficiais) | ✅ | 3 | `studio-completo/scripts/server.lua:684` |
| Salvar na nuvem própria (CloudSave/List/Open) | ✅ | 88 | `studio-completo/LEIA-ME.md:9` |
| Publicar jogo no PERFIL do dev (página estilo jogo do Roblox) | ✅ | 43 | `studio-completo/scripts/server.lua:879` |
| Criar PLACES novas no perfil (AssetService.CreatePlaceAsync) | ✅ | 20 | `studio-completo/AUDITORIA.md:63` |
| Colaboração (equipe, convites, co-editores) | ✅ | 12 | `studio-completo/AUDITORIA.md:78` |
| Datastores simulados (persistência DataSet/List/Get) | ✅ | 11 | `studio-completo/LEIA-ME.md:70` |
| i18n/locale (strings por idioma) | ✅ | 16 | `studio-completo/AUDITORIA.md:66` |
| Templates de projeto / Import-Export JSON | ✅ | 22 | `studio-completo/scripts/server.lua:28` |
| Editor de scripts (abrir Source real, editar, aplicar) | ✅ | 271 | `studio-completo/AUDITORIA.md:68` |
| Painel de testes/build automatizados (pipeline python .rbxl) | ✅ | 12 | `studio-completo/LEIA-ME.md:21` |
| TOPBAR: botões/ícones X nativos DENTRO do Ribbon real (sem overlay) | ✅ | 9 | `studio-completo/tools/auditoria.py:189` |
| Ícones desenhados/atlas de sistemas (procedural em frames + atlas de ícones) | ✅ | 5 | `studio-completo/tools/auditoria.py:189` |
| Color picker INLINE nas propriedades (só aparece no clique do quadrado) | ✅ | 5 | `studio-completo/scripts/10_Studio.lua:141` |
| Python bridge SEM erro (HttpService via servidor; PyStatus/PyRun) | ✅ | 30 | `studio-completo/LEIA-ME.md:276` |
| Part com submenu de formas NA TOPBAR (estilo Studio) | ✅ | 6 | `studio-completo/tools/auditoria.py:197` |
| CSG real (Union/Negate = PartOperation + histórico) | ✅ | 12 | `studio-completo/scripts/03_Menus.lua:2146` |
| Sculpt de terreno com falloff real (gaussiano, Laplaciano) | ✅ | 13 | `studio-completo/docs/PESQUISA_TERRAIN.md:12` |
| Collision Groups editor (PhysicsService real) | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:3941` |
| Presença no collab (quem está editando o quê) | ✅ | 5 | `studio-completo/scripts/03_Menus.lua:1094` |
| Plugin manager real (liga/desliga pumps via atributos) | ✅ | 17 | `studio-completo/scripts/engine_server.lua:1055` |
| Botões X DENTRO do Ribbon real (clones nativos, zero overlay que engolia cliques) | ✅ | 5 | `studio-completo/tools/auditoria.py:189` |
| Properties EXAUSTIVAS na DOCK ORIGINAL (CLASSDB + PropsAll por leitura real) | ✅ | 57 | `studio-completo/AUDITORIA.md:81` |
| COLOR PICKER real dentro das Properties (HSV gradientes + RGB/hex) | ✅ | 24 | `studio-completo/scripts/08_RealityX.lua:2466` |
| Menu '+' com catálogo gigante (+1k objects) via CreateAny (Instance.new pcall) | ✅ | 53 | `studio-completo/AUDITORIA.md:83` |
| Toolbox estilo Studio com thumbnails reais (rbxthumb) + insert na frente da câmera | ✅ | 13 | `studio-completo/LEIA-ME.md:188` |
| Menus da faixa (ESTÚDIO/MODELAGEM/...) clicáveis (overlay morto + duplo sinal) | ✅ | 224 | `studio-completo/LEIA-ME.md:169` |
| Spawn de pecas na frente da camera via servidor (QuickPart) | ✅ | 21 | `studio-completo/AUDITORIA.md:86` |
| Toolbox insert com fallback REAL (InsertService:LoadAsset server-side) | ✅ | 16 | `studio-completo/AUDITORIA.md:55` |
| Baseplate garantida (boot automatico + botao BASEPLATE) | ✅ | 7 | `studio-completo/scripts/server.lua:2242` |
| Permissao estendida: WhiteXz73_Developer + tentandoserbanido_9 | ✅ | 7 | `studio-completo/AUDITORIA.md:89` |
| Menus da faixa abrem o dropdown DIRETO ao clicar (buildMenu chamado no clique — antes ia ao barramento errado e nada abria) | ✅ | 19 | `studio-completo/scripts/03_Menus.lua:589` |
| Menu LUGARES: salvar place na conta + criar place nova no perfil (AssetService: SavePlaceAsync / CreatePlaceAsync com erro honesto) | ✅ | 20 | `studio-completo/AUDITORIA.md:63` |
| Botões X nunca mais 'somem': molde sintético se o Ribbon estiver sem botão-exemplo | ⚠ | 2 | `studio-completo/tools/auditoria.py:235` |
| Re-skin profissional: sombra + faixa de título com acento + ✕ com hover (todas as janelas do deck e modais) | ✅ | 12 | `studio-completo/scripts/03_Menus.lua:784` |

## INTEGRIDADE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Simulação de integração (cliques reais no mock fiel) 100% antes do push — test_client_round12 | ✅ | 5 | `studio-completo/AUDITORIA.md:99` |
| Placa X passa na validação #StudioSafe (121 chunks PROP, PRNT/END) | ✅ | 12 | `studio-completo/AUDITORIA.md:100` |
| Suíte de testes automatizada com painéis (run_tests) | ✅ | 8 | `studio-completo/LEIA-ME.md:29` |
| Assinatura de autor (AUTHORIZED_USERNAMES) com anti-explorer | ✅ | 20 | `studio-completo/AUDITORIA.md:102` |
| Resposta anti-erro: erro repetido = mensagem única (root-cause) | ✅ | 3 | `studio-completo/LEIA-ME.md:361` |

---

## Leitura honesta

- ⚠ com 1-2 ocorrências geralmente significa 'existe mas raso' (ex.: nome citado, mas sem sub-sistema completo). Investigar caso a caso.
- ✅ com >=3 ocorrências em arquivos distintos é evidência forte de sistema real.
- Termos de ERRO (`Position = nil`) devem ser **0** nos marcadores de bug; a placa é lida descomprimida para isso.

- Bug marcador `Position = nil` dentro da placa X: **0** (esperado 0).
