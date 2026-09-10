#!/usr/bin/env python3
"""ARKHER V3 — gerador do CB_UI_TODAS_UIS.lua.

Gera o script da Command Bar que cria TODAS as UIs (24 UIs da V3 + shell +
UI original do V2 = 26 guis) no StarterGui, com a estrutura exata que o
build() de cada UI cria (capturado em /tmp/v3uis.json + /tmp/v2ui.json).

Uso: python3 tools/gen_cb_uis.py
Saída: commandbar/estrutura-completa/CB_UI_TODAS_UIS.lua
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "commandbar", "estrutura-completa", "CB_UI_TODAS_UIS.lua")

V3 = json.load(open("/tmp/v3uis.json"))
V2 = json.load(open("/tmp/v2ui.json"))

all_guis = {}
v3_guis = set(V3["guis"].keys())
for g, insts in V3["guis"].items():
    all_guis[g] = insts
for g, insts in V2["guis"].items():
    all_guis[g] = insts

# --------------------------- índices globais (classes / nomes / props)
gcls, gnm = [], []
for c in V3["classes"]:
    if c not in gcls:
        gcls.append(c)
for n in V3["names"]:
    if n not in gnm:
        gnm.append(n)
for c in V2["classes"]:
    if c not in gcls:
        gcls.append(c)
for n in V2["names"]:
    if n not in gnm:
        gnm.append(n)
CL2 = {c: i for i, c in enumerate(gcls, 1)}
NM2 = {n: i for i, n in enumerate(gnm, 1)}


def cls_of(v3gui, it):
    return (V3["classes"] if v3gui else V2["classes"])[it["c"] - 1]


def name_of(v3gui, it):
    return (V3["names"] if v3gui else V2["names"])[it["n"] - 1]


# --------------------------- dedup de valores
U2, C3, U1, ES, SS, V3t, V2t, CS = [], [], [], [], [], [], [], []
u2m, c3m, u1m, esm, ssm, v3m, v2m, csm = {}, {}, {}, {}, {}, {}, {}, {}


def add(arr, m, v):
    if v not in m:
        m[v] = len(arr) + 1
        arr.append(v)
    return m[v]


def enum_lua_name(full):
    return "E." + full[len("Enum."):]


def skipped(prop, val):
    """valor == default do Roblox (ou tratado por post-pass) -> nao gravar"""
    if isinstance(val, dict):
        t = val.get("__t")
        if t == "UDim2" and val["v"] == [0, 0, 0, 0]:
            return True
        if t == "Enum" and val["v"] in (
                "Enum.TextXAlignment.Left", "Enum.TextYAlignment.Top",
                "Enum.TextTruncate.None", "Enum.ApplyStrokeMode.Border",
                "Enum.ZIndexBehavior.Sibling"):
            return True
        return False
    if prop == "Text" and val == "":
        return True
    if prop in ("Visible", "Active", "RichText", "TextWrapped", "TextScaled",
                "AutoButtonColor", "ClearTextOnFocus", "ResetOnSpawn",
                "Archivable", "ClipsDescendants") and val is True:
        return True
    if prop in ("Modal", "IgnoreGuiInset") and val is False:
        return True
    if prop in ("BackgroundTransparency", "ZIndex", "LayoutOrder", "Rotation",
                "Transparency") and val == 0:
        return True
    return False


def unwrap(val):
    """numéricos podem vir embrulhados {'__t':'Int32'/'Float32','v':x} (V2)"""
    if isinstance(val, dict) and val.get("__t") in ("Int32", "Float32", "Number", "Integer"):
        return val["v"]
    return val


# valores estaveis dos Enums do Roblox (p/ converter int da UI do V2 -> nome)
ENUM_VAL2NAME = {
    "Font": {
        0: "Gotham", 1: "GothamMedium", 2: "GothamBold", 3: "Arial", 4: "ArialBold",
        5: "Code", 6: "Cartoon", 7: "SciFi", 8: "HighlandOBlique", 9: "Fantasy",
        10: "Bangers", 11: "Arcade", 12: "Builder", 13: "Slavic", 14: "Modern",
        15: "Legacy", 16: "GothamBlack", 17: "SourceSans", 18: "SourceSansBold",
        19: "Roboto", 20: "RobotoMono", 21: "CenturyGothic", 22: "CenturyGothicBold",
        23: "Osaka", 24: "OsakaBold", 25: "Michroma", 26: "Futura", 27: "SofiaPro",
        28: "SofiaProBold", 29: "SofiaProItalic", 30: "AdventPro", 31: "AdventProBold",
        32: "AdventProItalic", 33: "AdventProBoldItalic", 34: "BuilderSans",
        35: "BuilderSansBold", 36: "BuilderSansBook", 37: "CodePlatform",
        38: "RedDisplay", 39: "Rajdhani", 40: "NunitoSans", 41: "NunitoSansBold",
        42: "NotoSans", 43: "NotoSansBold", 44: "QuartzRegular", 45: "QuartzMedium",
        46: "QuartzBold", 47: "QuartzBlack", 48: "QuartzRegularItalic",
        49: "QuartzMediumItalic", 50: "QuartzBoldItalic", 51: "QuartzBlackItalic",
    },
    "TextXAlignment": {0: "Left", 1: "Center", 2: "Right"},
    "TextYAlignment": {0: "Top", 1: "Center", 2: "Bottom"},
    "ZIndexBehavior": {0: "Sibling", 1: "Global"},
    "TextTruncate": {0: "None", 1: "AtEnd", 2: "AtCenter"},
    "ApplyStrokeMode": {0: "Inset", 1: "Border", 2: "Outset"},
}


def val_type(val):
    val = unwrap(val)
    if isinstance(val, bool):
        return 2
    if isinstance(val, (int, float)):
        return 1
    if isinstance(val, str):
        return 7
    if isinstance(val, dict):
        return {
            "UDim2": 3, "Color3": 4, "UDim": 5, "Vector3": 8,
            "Vector2": 9, "ColorSequence": 10,
        }.get(val.get("__t"), 11)
    raise SystemExit(f"tipo nao suportado: {val!r}")


def encode_val(prop, val):
    t = val_type(val)
    if t == 1:
        return 1, val
    if t == 2:
        return 2, 1 if val else 0
    if t == 3:
        return 3, add(U2, u2m, tuple(val["v"]))
    if t == 4:
        return 4, add(C3, c3m, tuple(val["v"]))
    if t == 5:
        return 5, add(U1, u1m, tuple(val["v"]))
    if t == 7:
        return 7, add(SS, ssm, val)
    if t == 8:
        return 8, add(V3t, v3m, tuple(val["v"]))
    if t == 9:
        return 9, add(V2t, v2m, tuple(val["v"]))
    if t == 10:
        def dtup(x):
            return tuple(dtup(y) if isinstance(y, (list, tuple)) else y for y in x) if isinstance(x, (list, tuple)) else x
        return 10, add(CS, csm, dtup(val["v"]))
    if t == 11:
        v = val["v"]
        if isinstance(v, str):
            tail = v[len("Enum."):] if v.startswith("Enum.") else v
            if tail.isdigit():
                # enum por valor inteiro (UI do V2) -> converte p/ nome
                # (valores estaveis do Enum do Roblox)
                return 6, add(ES, esm, f"E.{prop}.{ENUM_VAL2NAME[prop][int(tail)]}")
            return 6, add(ES, esm, "E." + tail)
        return 11, v
    raise SystemExit(f"valor nao codificado: {val!r}")


# --------------------------- montar rows
props, prop_map, prop_type = [], {}, {}
gui_rows = {}
for g, insts in all_guis.items():
    v3 = g in v3_guis
    rows = []
    for it in insts:
        row = [CL2[cls_of(v3, it)], NM2[name_of(v3, it)], it["p"]]
        for k, v in it["props"]:
            v = unwrap(v)
            if k == "_tool":
                continue
            if v3 and k == "BorderSizePixel":
                continue  # post-pass (todos 0 nos guis V3)
            if skipped(k, v):
                continue
            t, ref = encode_val(k, v)
            pi = add(props, prop_map, k)
            pt = prop_type.setdefault(pi, t)
            if pt != t:
                raise SystemExit(f"prop '{k}' com tipos {pt} e {t}")
            row.append(pi)
            row.append(ref)
        rows.append(row)
    gui_rows[g] = rows


# --------------------------- emitir Lua
def fnum(x):
    return repr(x) if isinstance(x, float) else str(x)


def lstr(s):
    # string com aspas simples; escapa \, ' e quebras de linha
    s = s.replace("\\", "\\\\").replace("'", "\\'")
    s = s.replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
    return "'" + s + "'"


L = []
L.append("--[[ =====================================================================")
L.append("  ARKHER V3 — TODAS AS UIs NO STARTERGUI (Command Bar)")
L.append(f"  Cria as {len(all_guis)} janelas completas do ARKHER no StarterGui:")
L.append("  as 24 UIs unicas da V3 + o shell do editor + a UI original do V2")
L.append("  (ARKHER_Studio). Estrutura EXATA do que o build() de cada UI cria:")
L.append("  cada Frame/Texto/Cor/Tamanho/Posicao fiel ao script que a fez.")
L.append("  Uso: View > Command Bar > cole TODO este texto > Run")
L.append("  Idempotente: janelas ja existentes sao destruidas e recriadas.")
L.append("  API: ArkherUI.show(nome) / hide / toggle / list / destroy")
L.append("====================================================================== ]]")
L.append('local SG = game:GetService("StarterGui")')
L.append("local C3 = Color3.new")
L.append("local U2 = UDim2.new")
L.append("local U1 = UDim.new")
L.append("local V2n = Vector2.new")
L.append("local V3n = Vector3.new")
L.append("local E = Enum")
L.append("-- ============ TABELAS DE VALORES ============")
L.append("local T2 = { " + ", ".join(f"U2({fnum(a)},{fnum(b)},{fnum(c)},{fnum(d)})" for a, b, c, d in U2) + " }")
L.append("local TC = { " + ", ".join(f"C3({fnum(a)},{fnum(b)},{fnum(c)})" for a, b, c in C3) + " }")
L.append("local TU = { " + ", ".join(f"U1({fnum(a)},{fnum(b)})" for a, b in U1) + " }")
L.append("local TE = { " + ", ".join(ES) + " }")
L.append("local TV3 = { " + ", ".join(f"V3n({fnum(a)},{fnum(b)},{fnum(c)})" for a, b, c in V3t) + " }")
L.append("local TV2 = { " + ", ".join(f"V2n({fnum(a)},{fnum(b)})" for a, b in V2t) + " }")
L.append("local TCS = { " + ", ".join(
    "ColorSequence.new(" + ", ".join(
        f"ColorSequenceKeypoint.new(C3({fnum(kp[0][0])},{fnum(kp[0][1])},{fnum(kp[0][2])}), {fnum(kp[1])})"
        for kp in cs) + ")" for cs in CS) + " }")
L.append("local TS = { " + ", ".join(lstr(s) for s in SS) + " }")
L.append("-- ============ NOMES ============")
L.append("local CL = { " + ", ".join(lstr(c) for c in gcls) + " }")
L.append("local PN = { " + ", ".join(lstr(p) for p in props) + " }")
L.append("local PT = { " + ", ".join(str(prop_type[i]) for i in range(1, len(props) + 1)) + " }")
L.append("local NM = { " + ", ".join(lstr(n) for n in gnm) + " }")
L.append("-- ============ INSTANCIAS (classe, nome, parent, pares prop/valor) ============")

order = ["ArkherStudioMainUI"] + [g for g in all_guis if g != "ArkherStudioMainUI"]
L.append("local G = {")
for gi, g in enumerate(order, 1):
    rows = gui_rows[g]
    parts = ["{" + ",".join(fnum(x) for x in row) + "}" for row in rows]
    L.append(f"-- {g} ({len(rows)} insts)")
    L.append("  { " + ", ".join(parts) + " },")
L.append("}")
L.append("local NAMES = { " + ", ".join(lstr(g) for g in order) + " }")
L.append("-- ============ BUILDER ============")
L.append("-- instancia: {classe, nome, parent, pares prop/valor}; parent 0 = StarterGui")
L.append("local function setProps(o, row)")
L.append("  for j = 4, #row, 2 do")
L.append("    local k = PN[row[j]]")
L.append("    local v = row[j + 1]")
L.append("    local t = PT[row[j]]")
L.append("    if t == 3 then v = T2[v]")
L.append("    elseif t == 4 then v = TC[v]")
L.append("    elseif t == 5 then v = TU[v]")
L.append("    elseif t == 6 then v = TE[v]")
L.append("    elseif t == 7 then v = TS[v]")
L.append("    elseif t == 8 then v = TV3[v]")
L.append("    elseif t == 9 then v = TV2[v]")
L.append("    elseif t == 10 then v = TCS[v]")
L.append("    elseif t == 2 then v = (v == 1)")
L.append("    end")
L.append("    if v ~= nil then o[k] = v end")
L.append("  end")
L.append("end")
L.append("")
L.append("local created = {}")
L.append("for gi = 1, #NAMES do")
L.append("  local old = SG:FindFirstChild(NAMES[gi])")
L.append("  if old then old:Destroy() end")
L.append("  local rows = G[gi]")
L.append("  local inst = {}")
L.append("  for i = 1, #rows do")
L.append("    local row = rows[i]")
L.append("    local o = Instance.new(CL[row[1]])")
L.append("    o.Name = NM[row[2]]")
L.append("    inst[i] = o")
L.append("    setProps(o, row)")
L.append("  end")
L.append("  for i = 1, #rows do")
L.append("    local row = rows[i]")
L.append("    if row[3] > 0 then inst[i].Parent = inst[row[3]] else inst[i].Parent = SG end")
L.append("  end")
L.append("  created[gi] = inst[1]")
L.append("end")
v3_gis = [i for i, g in enumerate(order, 1) if g in v3_guis]
L.append("-- BorderSizePixel = 0 em todas as GuiObjects dos guis da V3")
L.append(f"local V3G = {{ {', '.join(str(i) for i in v3_gis)} }}")
L.append("for _, gi in ipairs(V3G) do")
L.append("  local g = created[gi]")
L.append("  if g:IsA('GuiObject') then g.BorderSizePixel = 0 end")
L.append("  for _, d in ipairs(g:GetDescendants()) do")
L.append("    if d:IsA('GuiObject') then d.BorderSizePixel = 0 end")
L.append("  end")
L.append("end")
L.append("")
L.append("ArkherUI = { _m = {} }")
L.append("for gi = 1, #NAMES do ArkherUI._m[NAMES[gi]] = gi end")
L.append("function ArkherUI.show(n) local g = created[ArkherUI._m[n]] if g then g.Visible = true end end")
L.append("function ArkherUI.hide(n) local g = created[ArkherUI._m[n]] if g then g.Visible = false end end")
L.append("function ArkherUI.toggle(n) local g = created[ArkherUI._m[n]] if g then g.Visible = not g.Visible end end")
L.append("function ArkherUI.list() local out = {} for n in pairs(ArkherUI._m) do out[#out + 1] = n end table.sort(out) return out end")
L.append("function ArkherUI.destroy() for _, g in pairs(created) do g:Destroy() end ArkherUI._m = {} end")
L.append("")
L.append("print('[ARKHER] TODAS AS UIs criadas no StarterGui: ' .. #NAMES .. ' janelas')")

src = "\n".join(L) + "\n"
os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    f.write(src)
n_inst = sum(len(v) for v in all_guis.values())
n_pairs = sum(len(r) - 3 for rows in gui_rows.values() for r in rows)
print(f"gerado: {OUT}")
print(f"  {len(all_guis)} guis, {n_inst} instancias, {n_pairs} pares prop/valor")
print(f"  {len(props)} props, {len(U2)} UDim2, {len(C3)} Color3, {len(U1)} UDim, "
      f"{len(ES)} enums, {len(SS)} strings, {len(V3t)} V3, {len(V2t)} V2, {len(CS)} CS")
print(f"  tamanho: {os.path.getsize(OUT):,} bytes, {src.count(chr(10))} linhas")
