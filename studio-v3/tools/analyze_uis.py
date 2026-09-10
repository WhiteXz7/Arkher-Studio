import json
import collections

d = json.load(open("/tmp/v3uis.json"))
CLS = d["classes"]
NM = d["names"]
u2, c3, ud, strs, enums, outros = set(), set(), set(), set(), set(), collections.Counter()
vis_false, texts, nums = 0, 0, collections.Counter()
tot = 0
skip = 0
for g, insts in d["guis"].items():
    for it in insts:
        for k, v in it["props"]:
            tot += 1
            if isinstance(v, dict):
                t = v.get("__t")
                if t == "UDim2":
                    u2.add(tuple(v["v"]))
                elif t == "Color3":
                    c3.add(tuple(round(x, 5) for x in v["v"]))
                elif t == "UDim":
                    ud.add(tuple(v["v"]))
                elif t == "Enum":
                    enums.add(v["v"])
                else:
                    outros[str(t)] += 1
            elif isinstance(v, str):
                strs.add(v)
                if k == "Text" and v:
                    texts += 1
            elif isinstance(v, bool):
                if k == "Visible" and v is False:
                    vis_false += 1
                if v is True and k in ("Visible", "Active", "AutoLocalize", "RichText", "TextWrapped", "Modal", "ClearTextOnFocus", "AutoButtonColor", "ApplyStrokeMode"):
                    skip += 1
            else:
                if v == 0 and k in ("BackgroundTransparency", "ZIndex", "LayoutOrder", "Rotation"):
                    skip += 1
            if k == "Text" and v == "":
                skip += 1
            if isinstance(v, dict) and v.get("__t") == "UDim2" and v["v"] == [0, 0, 0, 0]:
                skip += 1
print("tot props:", tot)
print("UDim2 unicos:", len(u2))
print("Color3 unicos:", len(c3))
print("UDim unicos:", len(ud), sorted(ud))
print("strings unicas:", len(strs), "chars:", sum(len(s) for s in strs))
print("enums:", len(enums), sorted(enums))
print("outros:", dict(outros))
print("Visible=false:", vis_false, "| Text nao-vazio:", texts)
print("props pulaveis:", skip, "-> restantes:", tot - skip)
n_inst = sum(len(v) for v in d["guis"].values())
print("instancias:", n_inst)
# props restantes por nome
cnt = collections.Counter()
for g, insts in d["guis"].items():
    for it in insts:
        for k, v in it["props"]:
            pul = False
            if isinstance(v, dict):
                t = v.get("__t")
                if t == "UDim2" and v["v"] == [0, 0, 0, 0]:
                    pul = True
            elif isinstance(v, str):
                if k == "Text" and v == "":
                    pul = True
            elif isinstance(v, bool):
                if v is True and k in ("Visible", "Active", "AutoLocalize", "RichText", "TextWrapped", "Modal", "ClearTextOnFocus", "AutoButtonColor", "ApplyStrokeMode"):
                    pul = True
            else:
                if v == 0 and k in ("BackgroundTransparency", "ZIndex", "LayoutOrder", "Rotation"):
                    pul = True
            if not pul:
                cnt[k] += 1
print("\nprops RESTANTES por nome:")
for k, c in cnt.most_common(40):
    print(f"  {k:26s} {c}")
