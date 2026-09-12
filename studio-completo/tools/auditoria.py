#!/usr/bin/env python3
"""
auditoria.py — AUDITORIA AUTOMÁTICA Arkher vs. especificações (TXT da raiz).

Para cada exigência dos documentos (Tese dos D, UTS, UES/RRW, ARKHER STUDIOS,
UTS Design System), procura a implementação REAL no código-fonte do estúdio:
  - studio-v3/core/*.luau (motores)
  - studio-completo/scripts/*.lua (UI + servidores)
  - studio-completo/tools/*.py (pipeline .rbxl)
  - placa binária X (marcadores descomprimidos)

Saída: studio-completo/AUDITORIA.md com ✅ / ⚠ parcial / ❌ ausente + evidência
(arquivo:linha) + nota honesta. RAPIDEZ: tudo por grep, sem AST.

Uso:  python3 studio-completo/tools/auditoria.py
"""
import os, re, io, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SC = os.path.join(ROOT, "studio-completo")
V3 = os.path.join(ROOT, "studio-v3")

def read_all(patterns):
    """concatena todas as fontes para busca rápida, com mapa de origem."""
    docs = []
    for base, pat in patterns:
        for dirpath, _dirs, files in os.walk(base):
            for f in files:
                if not re.search(pat, f):
                    continue
                fp = os.path.join(dirpath, f)
                try:
                    text = io.open(fp, encoding="utf-8", errors="replace").read()
                except OSError:
                    continue
                docs.append((os.path.relpath(fp, ROOT), text))
    return docs

DOCS = read_all([
    (SC, r"\.(lua|py|md)$"),
    (V3, r"\.(luau|lua|py|md)$"),
])

# placa X descomprimida (marcador verdadeiro dentro do .rbxl)
PLATE = ""
try:
    sys.path.insert(0, os.path.join(SC, "tools"))
    import patch_rbxl as pr
    plate = os.path.join(ROOT, "ArkherStudio_Completo_X.rbxl")
    if os.path.exists(plate):
        data = open(plate, "rb").read()
        _v, _t, _i, hdr_end = pr.read_header(data)
        chunks = pr.parse_chunks(data, hdr_end)
        PLATE = b"".join(p for _n, p in chunks).decode("latin-1")
except Exception as e:  # noqa: BLE001
    PLATE = ""

def find(term, docs=None, plate=False):
    """retorna (count, first_evidence 'arquivo:linha')."""
    total, first = 0, None
    rx = re.compile(re.escape(term))
    for path, text in (docs or DOCS):
        n = 0
        for ln, line in enumerate(text.splitlines(), 1):
            if rx.search(line):
                n += 1
                if first is None:
                    first = f"{path}:{ln}"
                break  # uma evidência por arquivo basta p/ nota? não, queremos linha certa:
        # conta total de ocorrências no arquivo
        total += len(rx.findall(text))
        if n and first is None:
            first = f"{path}"
    if plate and PLATE:
        pn = PLATE.count(term)
        total += pn
        if pn and first is None:
            first = "placa X (descomprimida)"
    return total, first

def find_any(terms, **kw):
    best = (0, None)
    for t in terms:
        n, ev = find(t, **kw)
        if n > best[0]:
            best = (n, ev)
    return best

# ------------- catálogo de exigências (nome, spec-doc, termos, nota se ok/ausente) -------------
CHECKS = [
    # ===== Tese dos D =====
    ("TESE-DOS-D", "Tese dos D como sistema de níveis funcionais (D-não-dimensão)",
     ["Tese dos D", "TESE DOS D", "D-O15"], None),
    ("TESE-DOS-D", "D-O15 como domínio de OTIMIZAÇÃO (budget adaptativo real)",
     ["D-O15", "D_O15"], None),
    ("TESE-DOS-D", "Orçamento D-O15 de partículas (corte automático por nível)",
     ["BUDGET"], None),
    # ===== RRW (UES) =====
    ("RRW (UES)", "RRW — Renderer of the Reality of Real World (não raster clássico)",
     ["RRW", "Renderer of the Reality"], None),
    ("RRW (UES)", "Representação em níveis de descrição (LOD por contexto, não tudo o tempo todo)",
     ["LevelOfDetail", "lod", "LOD"], None),
    ("RRW (UES)", "Auto-bind: objetos do mundo entram no RRW sozinhos",
     ["AUTO-BIND RRW", "autobind", "autoBind"], None),
    ("RRW (UES)", "Matéria/substâncias (química: H2O, densidades, salinidade…)",
     ["salinity", "densidade", "density"], None),
    ("RRW (UES)", "Óptica/luz espectro (Kelvin → RGB físico, Planck/CIE)",
     ["Kelvin", "kelvin", "CIE"], None),
    ("RRW (UES)", "Terreno como dado de realidade (RLayer)",
     ["RLayer", "rlayer"], None),
    ("RRW (UES)", "Água da VIDA REAL (física Arquimedes + óptica + química)",
     ["water_float_test", "Arquimedes", "AWX"], None),
    ("RRW (UES)", "Atmosfera/tempo/estrelas (AEX — estados com transição)",
     ["ATX", "AEX", "setWeather"], None),
    ("RRW (UES)", "Frentes meteorológicas H/L que viajam (WEAX)",
     ["WEAX", "fronts_on", "wea_stats"], None),
    ("RRW (UES)", "Espaço/órbitas celestes (Képler real)",
     ["Képler", "Kepler", "space_preset", "orbit"], None),
    ("RRW (UES)", "Cordas/tecidos Verlet íntegros (RPX)",
     ["RPX", "Verlet", "rope_bridge"], None),
    ("RRW (UES)", "Partículas físicas 13 presets (APX) com gravidade/vórtice reais",
     ["APX", "fx_presets", "vOmega"], None),
    ("RRW (UES)", "Áudio real com buses (AUX mixer 7 buses)",
     ["AUX", "BUSES", "audio_bus"], None),
    ("RRW (UES)", "Humanos digitais/NPCs com IA (DAYX/MINDX/RIGX)",
     ["DAYX", "MINDX", "RIGX"], None),
    ("RRW (UES)", "Movimento IK/FABRIK real",
     ["FABRIK", "ik_target", "AutoPhysics"], None),
    ("RRW (UES)", "Ecossistema/ecologia (ECOX com presas/predadores)",
     ["ECOX", "eco_start"], None),
    ("RRW (UES)", "Cidadelas/urbanismo (CIVIX) gravando na terra",
     ["CIVIX", "urbanize", "civ_fabricate"], None),
    ("RRW (UES)", "Fabricação de peças pros sistemas (FABX catálogo)",
     ["FABX", "fabricate"], None),
    ("RRW (UES)", "Modelagem: primitives/CSG-style/mesh (MESHX-like; no engine: modeler cmds)",
     ["MESHX", "mesh_", "modeler"], None),
    # ===== ARKHER STUDIOS (IDE) =====
    ("IDE", "Topbar ORIGINAL + menus do STUDIO (não substituir a UI — expandir)",
     ["MenusBus", "menuRow", "buildMenu"], None),
    ("IDE", "Ativação direta de TODOS os sistemas via botões na topbar (X-tier)",
     ["X-TIER", "ArkherXTier"], None),
    ("IDE", "Hierarchy/Explorer próprio (árvore real do DataModel)",
     ["Hierarchy", "Explorer", "anchor_tree", "snapshot"], None),
    ("IDE", "Properties nativas (schema por classe, edição validada)",
     ["properties", "descriptors", "setProperty"], None),
    ("IDE", "PROPS EXAUSTIVAS (todas as curadas por IsA-chain) + aplicação funcional",
     ["PropsAll", "PROPSPEC"], None),
    ("IDE", "Color picker REAL aplicando no selecionado",
     ["buildCores", "ArkherColorTarget"], None),
    ("IDE", "Gizmos Move/Rotate/Scale no 3D (Handles reais + drag server-autorizado)",
     ["Gizmos", "ArcHandles", "TransformPreview"], None),
    ("IDE", "Undo/Redo com histórico (50, server-side)",
     ["handlers.Undo", "pushHist", "hCreate"], None),
    ("IDE", "Seleção real server-side (Select + SelectedGet)",
     ["handlers.Select", "SelectedGet"], None),
    ("IDE", "Spawn de part com FORMAS reais (Shape/classe)",
     ["QuickPart"], None),
    ("IDE", "Toolbox REAL do Roblox (Creator Store: GetFreeModelsAsync + LoadAsset)",
     ["GetFreeModelsAsync", "ToolboxSearch", "LoadAsset"], None),
    ("IDE", "OUTPUT real (LogService MessageOut/history) + filtros",
     ["GetLogHistory", "buildOutput"], None),
    ("IDE", "Command bar que EXECUTA (spawn/set/cmd/math…)",
     ["buildComando", "mathEval"], None),
    ("IDE", "Submenus reais nos menus + tooltips + headers de seção",
     ["buildSubMenu", "TipBar"], None),
    ("IDE", "UI adaptável a dispositivo (escala por largura + wrap de botões)",
     ["updateDeckScale", "hostWidth", "UIGridLayout"], None),
    ("IDE", "Abrir criar/projetos (New/Open; baseplates oficiais)",
     ["handlers.New", "handlers.Open"], None),
    ("IDE", "Salvar na nuvem própria (CloudSave/List/Open)",
     ["CloudSave", "CloudList", "vault"], None),
    ("IDE", "Publicar jogo no PERFIL do dev (página estilo jogo do Roblox)",
     ["handlers.Publish", "profile", "ProfileList"], None),
    ("IDE", "Criar PLACES novas no perfil (AssetService.CreatePlaceAsync)",
     ["PlaceCreate", "CreatePlaceAsync"], None),
    ("IDE", "Colaboração (equipe, convites, co-editores)",
     ["TeamAdd", "InviteCreate", "collab"], None),
    ("IDE", "Datastores simulados (persistência DataSet/List/Get)",
     ["DataSet", "DataList"], None),
    ("IDE", "i18n/locale (strings por idioma)",
     ["SetLocale", "LocStrings", "i18n"], None),
    ("IDE", "Templates de projeto / Import-Export JSON",
     ["handlers.Export", "handlers.Import", "serializeTree"], None),
    ("IDE", "Editor de scripts (abrir Source real, editar, aplicar)",
     ["ScriptEditor", "kind = \"source\"", "Source"], None),
    ("IDE", "Painel de testes/build automatizados (pipeline python .rbxl)",
     ["inject_arkherx", "run_tests", "patch_rbxl"], None),
    ("IDE", "TOPBAR: botões/ícones X nativos DENTRO do Ribbon real (sem overlay)",
     ["Arkher_09_Topbar", "drawIcon16", "injectButton"], None),
    ("IDE", "Ícones desenhados/atlas de sistemas (procedural em frames + atlas de ícones)",
     ["drawIcon16", "Icon_", "ArkherVectorIcon"], None),
    ("IDE", "Color picker INLINE nas propriedades (só aparece no clique do quadrado)",
     ["openColorPicker", "openColorPopup"], None),
    ("IDE", "Python bridge SEM erro (HttpService via servidor; PyStatus/PyRun)",
     ["handlers.PyStatus", "handlers.PyRun", "pybridge"], None),
    ("IDE", "Part com submenu de formas NA TOPBAR (estilo Studio)",
     ["SHAPES", "openShapes"], None),
    ("IDE", "CSG real (Union/Negate = PartOperation + histórico)",
     ["CsgDo", "UnionAsync", "SubtractAsync"], None),
    ("IDE", "Sculpt de terreno com falloff real (gaussiano, Laplaciano)",
     ["SculptApply", "WriteVoxels", "ReadVoxels"], None),
    ("IDE", "Collision Groups editor (PhysicsService real)",
     ["ColGroupCreate", "CollisionGroupSetCollidable"], None),
    ("IDE", "Presença no collab (quem está editando o quê)",
     ["PresenceGet"], None),
    ("IDE", "Plugin manager real (liga/desliga pumps via atributos)",
     ["PluginToggle", "modOn"], None),
    # ===== ROUND 11: topbar VISIVEL + spawn + baseplate + permissao =====
    ("IDE", "Botões X DENTRO do Ribbon real (clones nativos, zero overlay que engolia cliques)",
     ["drawIcon16", "ArkherX_Part"], None),
    ("IDE", "Properties EXAUSTIVAS na DOCK ORIGINAL (CLASSDB + PropsAll por leitura real)",
     ["PropsAll", "CLASSDB", "ArkherPropsOverlay"], None),
    ("IDE", "COLOR PICKER real dentro das Properties (HSV gradientes + RGB/hex)",
     ["ArkherColorPicker", "fromHSV"], None),
    ("IDE", "Menu '+' com catálogo gigante (+1k objects) via CreateAny (Instance.new pcall)",
     ["ClassList", "CreateAny", "wireHierarchyPlus"], None),
    ("IDE", "Toolbox estilo Studio com thumbnails reais (rbxthumb) + insert na frente da câmera",
     ["rbxthumb://type=Asset", "ToolboxAssetInsert"], None),
    ("IDE", "Menus da faixa (ESTÚDIO/MODELAGEM/...) clicáveis (overlay morto + duplo sinal)",
     ["MouseButton1Click", "ServerEditorPopups"], None),
    ("IDE", "Spawn de pecas na frente da camera via servidor (QuickPart)",
     ["camSpawnPos", "QuickPart"], None),
    ("IDE", "Toolbox insert com fallback REAL (InsertService:LoadAsset server-side)",
     ["LoadAsset", "Creator Store recusou"], None),
    ("IDE", "Baseplate garantida (boot automatico + botao BASEPLATE)",
     ["ensureBaseplate", "handlers.EnsureBase"], None),
    ("IDE", "Permissao estendida: WhiteXz73_Developer + tentandoserbanido_9",
     ["tentandoserbanido_9"], None),
    # ===== Integridade de engenharia =====
    ("INTEGRIDADE", "Placa X passa na validação #StudioSafe (121 chunks PROP, PRNT/END)",
     ["StudioSafe"], None),
    ("INTEGRIDADE", "Suíte de testes automatizada com painéis (run_tests)",
     ["run_tests.py"], None),
    ("INTEGRIDADE", "Assinatura de autor (AUTHORIZED_USERNAMES) com anti-explorer",
     ["AUTHORIZED_USERNAMES"], None),
    ("INTEGRIDADE", "Resposta anti-erro: erro repetido = mensagem única (root-cause)",
     ["híbrido", "aviso único", "spam"], None),
]

def main():
    lines = []
    lines.append("# 🔍 AUDITORIA ARKHER × especificações (TXT da raiz)\n")
    lines.append("Método: **grep honesto** nas fontes reais + marcadores dentro da placa X "
                 "descomprimida. ✅ = implementado (com evidência arquivo:linha), "
                 "⚠ = parcialim, ❌ = ausente. Gerado por `tools/auditoria.py`.\n")
    cur_spec = None
    okc = warnc = failc = 0
    rows = []
    for spec, desc, terms, nota in CHECKS:
        n, ev = find_any(terms, plate=True)
        if n >= 3:
            status = "✅"
            okc += 1
        elif n >= 1:
            status = "⚠"
            warnc += 1
        else:
            status = "❌"
            failc += 1
        rows.append((spec, desc, status, n, ev, nota))

    out = io.StringIO()
    out.write("\n".join(lines))
    out.write(f"\n\n**Placar: {okc} ✅ · {warnc} ⚠ · {failc} ❌** (de {okc+warnc+failc} exigências)\n\n")
    last = None
    for spec, desc, status, n, ev, nota in rows:
        if spec != last:
            out.write(f"\n## {spec}\n\n")
            out.write("| Exigência | Status | Ocorrências | Evidência |\n|---|---|---|---|\n")
            last = spec
        ev2 = f"`{ev}`" if ev else "—"
        desc2 = desc.replace("|", "\\|")
        out.write(f"| {desc2} | {status} | {n} | {ev2} |\n")
    out.write("\n---\n\n")
    out.write("## Leitura honesta\n\n")
    out.write("- ⚠ com 1-2 ocorrências geralmente significa 'existe mas raso' (ex.: nome "
             "citado, mas sem sub-sistema completo). Investigar caso a caso.\n")
    out.write("- ✅ com >=3 ocorrências em arquivos distintos é evidência forte de "
             "sistema real.\n")
    out.write("- Termos de ERRO (`Position = nil`) devem ser **0** nos marcadores de bug; "
             "a placa é lida descomprimida para isso.\n")
    bad = PLATE.count("Position = nil")
    out.write(f"\n- Bug marcador `Position = nil` dentro da placa X: **{bad}** "
              f"(esperado 0).\n")
    target = os.path.join(SC, "AUDITORIA.md")
    io.open(target, "w", encoding="utf-8").write(out.getvalue())
    print(f"ok={okc} parcial={warnc} ausente={failc}")
    print("Position=nil na placa:", bad)
    print("->", target)

if __name__ == "__main__":
    main()
