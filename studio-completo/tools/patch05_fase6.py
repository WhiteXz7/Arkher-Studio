"""Fase 6: remove HOME_Account; BUILD_Insert/Text -> V2_ArkherInsert assada. One-shot."""
import io

P05 = "studio-completo/scripts/05_StudioX.lua"
s = io.open(P05, encoding="utf-8").read()
assert "HOME_Account" in s, "Account ja removida?"


def rep(old, new, tag):
    global s
    assert s.count(old) == 1, f"anchor {tag}: count={s.count(old)}"
    s = s.replace(old, new)


rep('\tHOME_Account = { "open", "V2_ArkherLogin" },\n', "", "rm-account")
rep('\tBUILD_Text = { "menus", "Insert" },',
    '\tBUILD_Text = { "open", "V2_ArkherInsert" },', "ins-text")
rep('\tBUILD_Insert = { "menus", "Insert" },',
    '\tBUILD_Insert = { "open", "V2_ArkherInsert" },', "ins-build")
io.open(P05, "w", encoding="utf-8").write(s)

PB = "studio-completo/tools/build_shell.py"
b = io.open(PB, encoding="utf-8").read()
old_ac = '        ("Account", "Account", "playercard", ("open", "V2_ArkherLogin")),\n'
assert b.count(old_ac) == 1
b = b.replace(old_ac, "")
old_t = '        ("Text", "Text", "textA", ("menus", "Insert")),'
assert b.count(old_t) == 1
b = b.replace(old_t, '        ("Text", "Text", "textA", ("open", "V2_ArkherInsert")),')
old_i = '        ("Insert", "Insert...", "chevD", ("menus", "Insert")),'
assert b.count(old_i) == 1
b = b.replace(old_i, '        ("Insert", "Insert...", "chevD", ("open", "V2_ArkherInsert")),')
io.open(PB, "w", encoding="utf-8").write(b)
print("05+shell fase6 OK (Account fora, Insert assado)")
