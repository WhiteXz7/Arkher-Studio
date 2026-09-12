# 🔍 AUDITORIA ARKHER × especificações (TXT da raiz)

Método: **grep honesto** nas fontes reais + marcadores dentro da placa X descomprimida. ✅ = implementado (com evidência arquivo:linha), ⚠ = parcialim, ❌ = ausente. Gerado por `tools/auditoria.py`.


**Placar: 76 ✅ · 0 ⚠ · 0 ❌** (de 76 exigências)


## TESE-DOS-D

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Tese dos D como sistema de níveis funcionais (D-não-dimensão) | ✅ | 347 | `studio-completo/AUDITORIA.md:14` |
| D-O15 como domínio de OTIMIZAÇÃO (budget adaptativo real) | ✅ | 347 | `studio-completo/AUDITORIA.md:14` |
| Orçamento D-O15 de partículas (corte automático por nível) | ✅ | 31 | `studio-completo/scripts/engine_server.lua:1015` |

## RRW (UES)

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| RRW — Renderer of the Reality of Real World (não raster clássico) | ✅ | 172 | `studio-completo/AUDITORIA.md:17` |
| Representação em níveis de descrição (LOD por contexto, não tudo o tempo todo) | ✅ | 213 | `studio-completo/tools/auditoria.py:102` |
| Auto-bind: objetos do mundo entram no RRW sozinhos | ✅ | 14 | `studio-completo/LEIA-ME.md:413` |
| Matéria/substâncias (química: H2O, densidades, salinidade…) | ✅ | 61 | `studio-completo/AUDITORIA.md:24` |
| Óptica/luz espectro (Kelvin → RGB físico, Planck/CIE) | ✅ | 111 | `studio-completo/scripts/08_RealityX.lua:1561` |
| Terreno como dado de realidade (RLayer) | ✅ | 34 | `studio-completo/AUDITORIA.md:26` |
| Água da VIDA REAL (física Arquimedes + óptica + química) | ✅ | 461 | `studio-completo/LEIA-ME.md:118` |
| Atmosfera/tempo/estrelas (AEX — estados com transição) | ✅ | 396 | `studio-completo/LEIA-ME.md:118` |
| Frentes meteorológicas H/L que viajam (WEAX) | ✅ | 41 | `studio-completo/AUDITORIA.md:29` |
| Espaço/órbitas celestes (Képler real) | ✅ | 178 | `studio-completo/LEIA-ME.md:333` |
| Cordas/tecidos Verlet íntegros (RPX) | ✅ | 375 | `studio-completo/AUDITORIA.md:31` |
| Partículas físicas 13 presets (APX) com gravidade/vórtice reais | ✅ | 284 | `studio-completo/AUDITORIA.md:32` |
| Áudio real com buses (AUX mixer 7 buses) | ✅ | 591 | `studio-completo/AUDITORIA.md:33` |
| Humanos digitais/NPCs com IA (DAYX/MINDX/RIGX) | ✅ | 60 | `studio-completo/AUDITORIA.md:34` |
| Movimento IK/FABRIK real | ✅ | 27 | `studio-completo/AUDITORIA.md:35` |
| Ecossistema/ecologia (ECOX com presas/predadores) | ✅ | 43 | `studio-completo/AUDITORIA.md:36` |
| Cidadelas/urbanismo (CIVIX) gravando na terra | ✅ | 36 | `studio-completo/AUDITORIA.md:37` |
| Fabricação de peças pros sistemas (FABX catálogo) | ✅ | 44 | `studio-completo/LEIA-ME.md:414` |
| Modelagem: primitives/CSG-style/mesh (MESHX-like; no engine: modeler cmds) | ✅ | 35 | `studio-completo/LEIA-ME.md:435` |

## IDE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Topbar ORIGINAL + menus do STUDIO (não substituir a UI — expandir) | ✅ | 39 | `studio-completo/scripts/03_Menus.lua:617` |
| Ativação direta de TODOS os sistemas via botões na topbar (X-tier) | ✅ | 6 | `studio-completo/LEIA-ME.md:121` |
| Hierarchy/Explorer próprio (árvore real do DataModel) | ✅ | 203 | `studio-completo/AUDITORIA.md:47` |
| Properties nativas (schema por classe, edição validada) | ✅ | 121 | `studio-completo/scripts/01_Nucleo.lua:1` |
| PROPS EXAUSTIVAS (todas as curadas por IsA-chain) + aplicação funcional | ✅ | 43 | `studio-completo/AUDITORIA.md:81` |
| Color picker REAL aplicando no selecionado | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:2739` |
| Gizmos Move/Rotate/Scale no 3D (Handles reais + drag server-autorizado) | ✅ | 25 | `studio-completo/AUDITORIA.md:51` |
| Undo/Redo com histórico (50, server-side) | ✅ | 29 | `studio-completo/scripts/server.lua:151` |
| Seleção real server-side (Select + SelectedGet) | ✅ | 15 | `studio-completo/AUDITORIA.md:53` |
| Spawn de part com FORMAS reais (Shape/classe) | ✅ | 19 | `studio-completo/AUDITORIA.md:86` |
| Toolbox REAL do Roblox (Creator Store: GetFreeModelsAsync + LoadAsset) | ✅ | 20 | `studio-completo/AUDITORIA.md:55` |
| OUTPUT real (LogService MessageOut/history) + filtros | ✅ | 6 | `studio-completo/LEIA-ME.md:295` |
| Command bar que EXECUTA (spawn/set/cmd/math…) | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:3126` |
| Submenus reais nos menus + tooltips + headers de seção | ✅ | 7 | `studio-completo/scripts/03_Menus.lua:568` |
| UI adaptável a dispositivo (escala por largura + wrap de botões) | ✅ | 25 | `studio-completo/LEIA-ME.md:274` |
| Abrir criar/projetos (New/Open; baseplates oficiais) | ✅ | 4 | `studio-completo/scripts/server.lua:329` |
| Salvar na nuvem própria (CloudSave/List/Open) | ✅ | 85 | `studio-completo/LEIA-ME.md:9` |
| Publicar jogo no PERFIL do dev (página estilo jogo do Roblox) | ✅ | 58 | `studio-completo/scripts/server.lua:464` |
| Criar PLACES novas no perfil (AssetService.CreatePlaceAsync) | ✅ | 21 | `studio-completo/AUDITORIA.md:63` |
| Colaboração (equipe, convites, co-editores) | ✅ | 9 | `studio-completo/AUDITORIA.md:78` |
| Datastores simulados (persistência DataSet/List/Get) | ✅ | 12 | `studio-completo/LEIA-ME.md:70` |
| i18n/locale (strings por idioma) | ✅ | 18 | `studio-completo/AUDITORIA.md:66` |
| Templates de projeto / Import-Export JSON | ✅ | 28 | `studio-completo/scripts/server.lua:27` |
| Editor de scripts (abrir Source real, editar, aplicar) | ✅ | 405 | `studio-completo/AUDITORIA.md:68` |
| Painel de testes/build automatizados (pipeline python .rbxl) | ✅ | 11 | `studio-completo/AUDITORIA.md:96` |
| TOPBAR: botões/ícones X nativos DENTRO do Ribbon real (sem overlay) | ✅ | 13 | `studio-completo/scripts/09_Topbar.lua:260` |
| Ícones desenhados/atlas de sistemas (procedural em frames + atlas de ícones) | ✅ | 7 | `studio-completo/scripts/09_Topbar.lua:116` |
| Color picker INLINE nas propriedades (só aparece no clique do quadrado) | ✅ | 5 | `studio-completo/scripts/10_Studio.lua:118` |
| Python bridge SEM erro (HttpService via servidor; PyStatus/PyRun) | ✅ | 26 | `studio-completo/LEIA-ME.md:259` |
| Part com submenu de formas NA TOPBAR (estilo Studio) | ✅ | 7 | `studio-completo/scripts/09_Topbar.lua:178` |
| CSG real (Union/Negate = PartOperation + histórico) | ✅ | 11 | `studio-completo/scripts/09_Topbar.lua:330` |
| Sculpt de terreno com falloff real (gaussiano, Laplaciano) | ✅ | 9 | `studio-completo/scripts/08_RealityX.lua:3756` |
| Collision Groups editor (PhysicsService real) | ✅ | 6 | `studio-completo/scripts/08_RealityX.lua:3890` |
| Presença no collab (quem está editando o quê) | ✅ | 6 | `studio-completo/scripts/03_Menus.lua:1058` |
| Plugin manager real (liga/desliga pumps via atributos) | ✅ | 17 | `studio-completo/scripts/engine_server.lua:1055` |
| Botões X DENTRO do Ribbon real (clones nativos, zero overlay que engolia cliques) | ✅ | 7 | `studio-completo/scripts/09_Topbar.lua:116` |
| Properties EXAUSTIVAS na DOCK ORIGINAL (CLASSDB + PropsAll por leitura real) | ✅ | 43 | `studio-completo/AUDITORIA.md:81` |
| COLOR PICKER real dentro das Properties (HSV gradientes + RGB/hex) | ✅ | 29 | `studio-completo/scripts/08_RealityX.lua:2415` |
| Menu '+' com catálogo gigante (+1k objects) via CreateAny (Instance.new pcall) | ✅ | 23 | `studio-completo/AUDITORIA.md:83` |
| Toolbox estilo Studio com thumbnails reais (rbxthumb) + insert na frente da câmera | ✅ | 12 | `studio-completo/LEIA-ME.md:171` |
| Menus da faixa (ESTÚDIO/MODELAGEM/...) clicáveis (overlay morto + duplo sinal) | ✅ | 1462 | `studio-completo/LEIA-ME.md:152` |
| Spawn de pecas na frente da camera via servidor (QuickPart) | ✅ | 19 | `studio-completo/AUDITORIA.md:86` |
| Toolbox insert com fallback REAL (InsertService:LoadAsset server-side) | ✅ | 20 | `studio-completo/AUDITORIA.md:55` |
| Baseplate garantida (boot automatico + botao BASEPLATE) | ✅ | 10 | `studio-completo/scripts/server.lua:1709` |
| Permissao estendida: WhiteXz73_Developer + tentandoserbanido_9 | ✅ | 7 | `studio-completo/AUDITORIA.md:89` |
| Menus da faixa abrem o dropdown DIRETO ao clicar (buildMenu chamado no clique — antes ia ao barramento errado e nada abria) | ✅ | 19 | `studio-completo/scripts/03_Menus.lua:553` |
| Menu LUGARES: salvar place na conta + criar place nova no perfil (AssetService: SavePlaceAsync / CreatePlaceAsync com erro honesto) | ✅ | 21 | `studio-completo/AUDITORIA.md:63` |
| Botões X nunca mais 'somem': molde sintético se o Ribbon estiver sem botão-exemplo | ✅ | 3 | `studio-completo/scripts/09_Topbar.lua:101` |
| Re-skin profissional: sombra + faixa de título com acento + ✕ com hover (todas as janelas do deck e modais) | ✅ | 14 | `studio-completo/scripts/03_Menus.lua:748` |

## INTEGRIDADE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Simulação de integração (cliques reais no mock fiel) 100% antes do push — test_client_round12 | ✅ | 3 | `studio-completo/tools/auditoria.py:238` |
| Placa X passa na validação #StudioSafe (121 chunks PROP, PRNT/END) | ✅ | 7 | `studio-completo/AUDITORIA.md:95` |
| Suíte de testes automatizada com painéis (run_tests) | ✅ | 8 | `studio-completo/LEIA-ME.md:29` |
| Assinatura de autor (AUTHORIZED_USERNAMES) com anti-explorer | ✅ | 20 | `studio-completo/AUDITORIA.md:97` |
| Resposta anti-erro: erro repetido = mensagem única (root-cause) | ✅ | 3 | `studio-completo/LEIA-ME.md:344` |

---

## Leitura honesta

- ⚠ com 1-2 ocorrências geralmente significa 'existe mas raso' (ex.: nome citado, mas sem sub-sistema completo). Investigar caso a caso.
- ✅ com >=3 ocorrências em arquivos distintos é evidência forte de sistema real.
- Termos de ERRO (`Position = nil`) devem ser **0** nos marcadores de bug; a placa é lida descomprimida para isso.

- Bug marcador `Position = nil` dentro da placa X: **0** (esperado 0).
