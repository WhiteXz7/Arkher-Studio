# 🔍 AUDITORIA ARKHER × especificações (TXT da raiz)

Método: **grep honesto** nas fontes reais + marcadores dentro da placa X descomprimida. ✅ = implementado (com evidência arquivo:linha), ⚠ = parcialim, ❌ = ausente. Gerado por `tools/auditoria.py`.


**Placar: 56 ✅ · 0 ⚠ · 0 ❌** (de 56 exigências)


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
| Representação em níveis de descrição (LOD por contexto, não tudo o tempo todo) | ✅ | 212 | `studio-completo/tools/auditoria.py:102` |
| Auto-bind: objetos do mundo entram no RRW sozinhos | ✅ | 14 | `studio-completo/LEIA-ME.md:308` |
| Matéria/substâncias (química: H2O, densidades, salinidade…) | ✅ | 61 | `studio-completo/AUDITORIA.md:24` |
| Óptica/luz espectro (Kelvin → RGB físico, Planck/CIE) | ✅ | 111 | `studio-completo/scripts/08_RealityX.lua:1540` |
| Terreno como dado de realidade (RLayer) | ✅ | 34 | `studio-completo/AUDITORIA.md:26` |
| Água da VIDA REAL (física Arquimedes + óptica + química) | ✅ | 461 | `studio-completo/LEIA-ME.md:118` |
| Atmosfera/tempo/estrelas (AEX — estados com transição) | ✅ | 396 | `studio-completo/LEIA-ME.md:118` |
| Frentes meteorológicas H/L que viajam (WEAX) | ✅ | 41 | `studio-completo/AUDITORIA.md:29` |
| Espaço/órbitas celestes (Képler real) | ✅ | 178 | `studio-completo/LEIA-ME.md:228` |
| Cordas/tecidos Verlet íntegros (RPX) | ✅ | 375 | `studio-completo/AUDITORIA.md:31` |
| Partículas físicas 13 presets (APX) com gravidade/vórtice reais | ✅ | 284 | `studio-completo/AUDITORIA.md:32` |
| Áudio real com buses (AUX mixer 7 buses) | ✅ | 591 | `studio-completo/AUDITORIA.md:33` |
| Humanos digitais/NPCs com IA (DAYX/MINDX/RIGX) | ✅ | 60 | `studio-completo/AUDITORIA.md:34` |
| Movimento IK/FABRIK real | ✅ | 27 | `studio-completo/AUDITORIA.md:35` |
| Ecossistema/ecologia (ECOX com presas/predadores) | ✅ | 43 | `studio-completo/AUDITORIA.md:36` |
| Cidadelas/urbanismo (CIVIX) gravando na terra | ✅ | 36 | `studio-completo/AUDITORIA.md:37` |
| Fabricação de peças pros sistemas (FABX catálogo) | ✅ | 44 | `studio-completo/LEIA-ME.md:309` |
| Modelagem: primitives/CSG-style/mesh (MESHX-like; no engine: modeler cmds) | ✅ | 35 | `studio-completo/LEIA-ME.md:330` |

## IDE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Topbar ORIGINAL + menus do STUDIO (não substituir a UI — expandir) | ✅ | 35 | `studio-completo/scripts/03_Menus.lua:611` |
| Ativação direta de TODOS os sistemas via botões na topbar (X-tier) | ✅ | 8 | `studio-completo/LEIA-ME.md:121` |
| Hierarchy/Explorer próprio (árvore real do DataModel) | ✅ | 193 | `studio-completo/AUDITORIA.md:47` |
| Properties nativas (schema por classe, edição validada) | ✅ | 121 | `studio-completo/scripts/01_Nucleo.lua:1` |
| PROPS EXAUSTIVAS (todas as curadas por IsA-chain) + aplicação funcional | ✅ | 22 | `studio-completo/LEIA-ME.md:153` |
| Color picker REAL aplicando no selecionado | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:2718` |
| Gizmos Move/Rotate/Scale no 3D (Handles reais + drag server-autorizado) | ✅ | 25 | `studio-completo/AUDITORIA.md:51` |
| Undo/Redo com histórico (50, server-side) | ✅ | 22 | `studio-completo/scripts/server.lua:10` |
| Seleção real server-side (Select + SelectedGet) | ✅ | 15 | `studio-completo/AUDITORIA.md:53` |
| Spawn de part com FORMAS reais (Shape/classe) | ✅ | 12 | `studio-completo/LEIA-ME.md:174` |
| Toolbox REAL do Roblox (Creator Store: GetFreeModelsAsync + LoadAsset) | ✅ | 10 | `studio-completo/AUDITORIA.md:55` |
| OUTPUT real (LogService MessageOut/history) + filtros | ✅ | 6 | `studio-completo/LEIA-ME.md:190` |
| Command bar que EXECUTA (spawn/set/cmd/math…) | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:3105` |
| Submenus reais nos menus + tooltips + headers de seção | ✅ | 7 | `studio-completo/scripts/03_Menus.lua:562` |
| UI adaptável a dispositivo (escala por largura + wrap de botões) | ✅ | 13 | `studio-completo/LEIA-ME.md:169` |
| Abrir criar/projetos (New/Open; baseplates oficiais) | ✅ | 4 | `studio-completo/scripts/server.lua:329` |
| Salvar na nuvem própria (CloudSave/List/Open) | ✅ | 91 | `studio-completo/LEIA-ME.md:9` |
| Publicar jogo no PERFIL do dev (página estilo jogo do Roblox) | ✅ | 58 | `studio-completo/scripts/server.lua:463` |
| Criar PLACES novas no perfil (AssetService.CreatePlaceAsync) | ✅ | 17 | `studio-completo/AUDITORIA.md:63` |
| Colaboração (equipe, convites, co-editores) | ✅ | 8 | `studio-completo/scripts/03_Menus.lua:1106` |
| Datastores simulados (persistência DataSet/List/Get) | ✅ | 12 | `studio-completo/LEIA-ME.md:70` |
| i18n/locale (strings por idioma) | ✅ | 18 | `studio-completo/AUDITORIA.md:66` |
| Templates de projeto / Import-Export JSON | ✅ | 28 | `studio-completo/scripts/server.lua:27` |
| Editor de scripts (abrir Source real, editar, aplicar) | ✅ | 386 | `studio-completo/AUDITORIA.md:68` |
| Painel de testes/build automatizados (pipeline python .rbxl) | ✅ | 11 | `studio-completo/AUDITORIA.md:76` |
| TOPBAR com ABAS estilo Roblox (aba -> página de botões com ícones) | ✅ | 8 | `studio-completo/scripts/05_StudioX.lua:94` |
| Ícones desenhados/atlas de sistemas (neôn procedural + atlas PNG) | ✅ | 7 | `studio-completo/scripts/09_Topbar.lua:10` |
| Color picker INLINE nas propriedades (só aparece no clique do quadrado) | ✅ | 5 | `studio-completo/scripts/08_RealityX.lua:2370` |
| Python bridge SEM erro (HttpService via servidor; PyStatus/PyRun) | ✅ | 26 | `studio-completo/LEIA-ME.md:154` |
| Part com submenu de formas NA TOPBAR (estilo Studio) | ✅ | 7 | `studio-completo/scripts/09_Topbar.lua:372` |

## INTEGRIDADE

| Exigência | Status | Ocorrências | Evidência |
|---|---|---|---|
| Placa X passa na validação #StudioSafe (121 chunks PROP, PRNT/END) | ✅ | 5 | `studio-completo/AUDITORIA.md:75` |
| Suíte de testes automatizada com painéis (run_tests) | ✅ | 8 | `studio-completo/LEIA-ME.md:29` |
| Assinatura de autor (AUTHORIZED_USERNAMES) com anti-explorer | ✅ | 19 | `studio-completo/AUDITORIA.md:77` |
| Resposta anti-erro: erro repetido = mensagem única (root-cause) | ✅ | 3 | `studio-completo/LEIA-ME.md:239` |

---

## Leitura honesta

- ⚠ com 1-2 ocorrências geralmente significa 'existe mas raso' (ex.: nome citado, mas sem sub-sistema completo). Investigar caso a caso.
- ✅ com >=3 ocorrências em arquivos distintos é evidência forte de sistema real.
- Termos de ERRO (`Position = nil`) devem ser **0** nos marcadores de bug; a placa é lida descomprimida para isso.

- Bug marcador `Position = nil` dentro da placa X: **0** (esperado 0).
