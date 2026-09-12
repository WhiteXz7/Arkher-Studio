"""Fase 7: openWindow centraliza V2 + log; DIAG mostra botoes/render. One-shot."""
import io

P05 = "studio-completo/scripts/05_StudioX.lua"
s = io.open(P05, encoding="utf-8").read()
assert "ArkherOPEN" not in s, "fase7 ja aplicada!"


def rep(old, new, tag):
    global s
    assert s.count(old) == 1, f"anchor {tag}: count={s.count(old)}"
    s = s.replace(old, new)


rep("""	w.Visible = true
	topZ = topZ + 1
	pcall(function() w.ZIndex = topZ end)
	wireWindow(w)
end""",
    """	w.Visible = true
	topZ = topZ + 1
	pcall(function() w.ZIndex = topZ end)
	if name:sub(1, 3) == "V2_" then
		pcall(function()
			w.AnchorPoint = Vector2.new(0.5, 0.5)
			w.Position = UDim2.new(0.5, 0, 0.46, 0)
		end)
	end
	wireWindow(w)
	print("[ArkherX] ArkherOPEN " .. name .. " vis=" .. tostring(w.Visible))
end""",
    "open-center")

rep(""""viewport=" .. fld(function() local z = uiRoot.AbsoluteSize return z.X .. "x" .. z.Y end),""",
    """"viewport=" .. fld(function() local z = uiRoot.AbsoluteSize return z.X .. "x" .. z.Y end),
		"canvasScale=" .. fld(function() local c = canvas and canvas:FindFirstChild("ResponsiveScale") return c and c.Scale end),
		"deckSize=" .. fld(function() local z = host.AbsoluteSize return z.X .. "x" .. z.Y end),
		"homeBtns=" .. fld(function()
			local pg = ribbon and ribbon:FindFirstChild("Page_HOME")
			local v, t = 0, 0
			if pg then for _, ch in ipairs(pg:GetChildren()) do
				if ch:IsA("GuiButton") and ch.Name:sub(1, 10) == "RibbonBtn_" then
					t = t + 1
					if ch.Visible then v = v + 1 end
				end
			end end
			return v .. "/" .. t
		end),
		"saveOpen=" .. fld(function()
			local w0 = host and host:FindFirstChild("V2_ArkherSaveOpen")
			if not w0 then return "nil" end
			local p = w0.AbsolutePosition
			return tostring(w0.Visible) .. "@" .. math.floor(p.X) .. "," .. math.floor(p.Y)
		end),""",
    "diag+")
io.open(P05, "w", encoding="utf-8").write(s)
print("05 fase7 OK")
