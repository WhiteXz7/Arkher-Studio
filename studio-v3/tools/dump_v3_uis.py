#!/usr/bin/env python3
"""ARKHER V3 — dumper das UIs.

Roda o engine completo (shim + ArkherStudio_ALL) num stub Lua (lupa),
abre o shell + as 24 UIs, e captura a árvore REAL que cada build() cria
(classe, nome, parent e todas as propriedades) → /tmp/v3uis.json.
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
import lupa  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DIST = os.path.join(ROOT, "commandbar")

DUMP_LUA = r"""
local namesList, classesList, names, classes = {}, {}, {}, {}
local function dumpInst(inst, out)
	local i = #out + 1
	local cls = rawget(inst, "__props").ClassName
	local nm = rawget(inst, "__props").Name
	local ci, ni = classes[cls], names[nm]
	if not ci then ci = #classesList + 1; classes[cls] = ci; classesList[#classesList+1] = cls end
	if not ni then ni = #namesList + 1; names[nm] = ni; namesList[#namesList+1] = nm end
	out[i] = { c = ci, n = ni, p = 0, props = {} }
	for _, ch in ipairs(rawget(inst, "__children")) do
		local before = #out + 1
		dumpInst(ch, out)
		out[before].p = i
	end
	-- props
	for k, v in pairs(rawget(inst, "__props")) do
		if k ~= "Name" and k ~= "ClassName" and k ~= "Parent" then
			local t = type(v)
			if t == "boolean" or t == "number" or t == "string" then
				table.insert(out[i].props, { k, v })
			elseif t == "table" then
				local tag = rawget(v, "__t")
				if tag == "Color3" then
					table.insert(out[i].props, { k, { __t = "Color3", v = { v.R, v.G, v.B } } })
				elseif tag == "Vector3" then
					table.insert(out[i].props, { k, { __t = "Vector3", v = { v.X, v.Y, v.Z } } })
				elseif tag == "UDim2" then
					table.insert(out[i].props, { k, { __t = "UDim2", v = { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } } })
				elseif tag == "UDim" then
					table.insert(out[i].props, { k, { __t = "UDim", v = { v.Scale, v.Offset } } })
				elseif tag == "Vector2" then
					table.insert(out[i].props, { k, { __t = "Vector2", v = { v.X, v.Y } } })
				elseif tag == "CFrame" then
					if v.Position then
						table.insert(out[i].props, { k, { __t = "CFrame", v = { v.Position.X, v.Position.Y, v.Position.Z } } })
					end
				elseif tag == "BrickColor" then
					table.insert(out[i].props, { k, { __t = "BrickColor", v = { v.Name or "", v.Number } } })
				elseif tag == "ColorSequence" then
					-- shim: Keypoints = lista de Color3 (sem time) -> times espacados
					local kp = {}
					local raw = v.Keypoints or {}
					local n = #raw
					for pi, p in ipairs(raw) do
						local c1 = p.Value or p.Color or p
						local function col(c)
							if type(c) == "table" and (rawget(c, "__t") == "Color3" or c.R ~= nil) then
								return { c.R or 0, c.G or 0, c.B or 0 }
							end
							return { 0, 0, 0 }
						end
						local tm = p.Time or (n > 1 and (pi - 1) / (n - 1) or 0)
						table.insert(kp, { col(c1), tm })
					end
					table.insert(out[i].props, { k, { __t = "ColorSequence", v = kp } })
				elseif type(rawget(v, "__name")) == "string" then
					-- Enum (autoenum do shim)
					table.insert(out[i].props, { k, { __t = "Enum", v = rawget(v, "__name") } })
				else
					-- tabela opaca: ignora (ex: TweenInfo com metatable)
				end
			end
		end
	end
end

local coreGui = game:GetService("CoreGui")
local folder = coreGui:FindFirstChild("ArkherStudio")
local result = {}
local order = {}
if folder then
	for _, ch in ipairs(folder:GetChildren()) do
		if rawget(ch, "__props").ClassName == "ScreenGui" then
			local inst = {}
			dumpInst(ch, inst)
			result[rawget(ch, "__props").Name] = inst
			order[#order + 1] = rawget(ch, "__props").Name
		end
	end
end
_G.__order = order
_G.__dump = {
	guis = result,
	names = namesList,
	classes = classesList,
}
"""


def main():
    L = lupa.LuaRuntime()

    def exec(name, src):
        try:
            L.execute(src)
        except Exception as e:
            print(f"ERRO em {name}: {e}")
            sys.exit(1)

    with open(os.path.join(ROOT, "tests", "shim.lua"), encoding="utf-8") as f:
        exec("shim", f.read())
    with open(os.path.join(DIST, "ArkherStudio_ALL.lua"), encoding="utf-8") as f:
        exec("ALL", f.read())

    exec("boot", "ARKHER.boot()")
    exec("main", "ARKHER_BUILD_MAIN()")
    exec("openall", "_G.__opened = ARKHER.openAll()")
    n = L.globals()["__opened"]

    L.execute(DUMP_LUA)
    d = L.globals()["__dump"]

    def pyv(v):
        tn = type(v).__name__
        if tn in ("_LuaTable", "LuaTable"):
            keys = []
            for k in v:
                keys.append(k)
            if not keys:
                return []
            isarr = all(type(k) is int for k in keys) and sorted(keys) == list(range(1, len(keys) + 1))
            if isarr:
                return [pyv(v[k]) for k in range(1, len(keys) + 1)]
            out = {}
            for k in keys:
                out[str(k)] = pyv(v[k])
            return out
        if isinstance(v, (list, tuple)):
            return [pyv(x) for x in v]
        if isinstance(v, dict):
            return {k: pyv(x) for k, x in v.items()}
        return v

    py = {}
    guis = d["guis"]
    order = L.globals()["__order"]
    for i in range(1, len(order) + 1):
        k = order[i]
        arr = guis[k]
        insts = []
        for j in range(1, len(arr) + 1):
            it = arr[j]
            props = []
            pl = it["props"]
            for pi in range(1, len(pl) + 1):
                pr = pl[pi]
                key = str(pr[1])
                val = pyv(pr[2])
                props.append([key, val])
            insts.append({
                "c": it["c"],
                "n": it["n"],
                "p": it["p"],
                "props": props,
            })
        py[k] = insts

    out = {
        "guis": py,
        "names": [d["names"][i] for i in range(1, len(d["names"]) + 1)],
        "classes": [d["classes"][i] for i in range(1, len(d["classes"]) + 1)],
        "opened": n,
    }
    with open("/tmp/v3uis.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False)

    # resumo
    tot = 0
    totprops = 0
    for g, insts in py.items():
        c = sum(len(i["props"]) for i in insts)
        tot += len(insts)
        totprops += c
        print(f"  {g:24s} {len(insts):4d} insts  {c:4d} props")
    print(f"\nTOTAL: {len(py)} guis, {tot} instâncias, {totprops} props")
    print(f"classes unicas: {len(out['classes'])}, nomes unicos: {len(out['names'])}")
    print("opened:", n)


if __name__ == "__main__":
    main()
