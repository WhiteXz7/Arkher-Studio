#!/usr/bin/env python3
"""Aplica edicoes cirurgicas ao 01_Nucleo (a partir do .orig) e valida limite de
statement p/ Luau. Todas as insercoes usam ';' explicito entre statements."""
P = "studio-completo/scripts/01_Nucleo.lua"
ORIG = "studio-completo/scripts/01_Nucleo.orig.lua"
s = open(ORIG, encoding="utf-8").read()


def rep(old, new, tag):
    global s
    assert s.count(old) == 1, f"{tag}: {s.count(old)}x de {old[:60]!r}"
    s = s.replace(old, new)


# 1) File -> dispatch unificado de menus (File/Edit/View/Run/Game/topos)
rep('if X=="File"then ag(a7,ab,"File")O()return end',
    'if X=="File"or X=="Edit"or X=="View"or X=="Run"or X=="Game"or X=="Collaborate"or X=="Invites"or X=="Changes"or X=="Account"then ag(a7,ab,"Menu",{name=X,button=aV})O()return end',
    "1-File")

# 2) Insert -> Menu
rep('if X=="Insert"then cD()return end',
    'if X=="Insert"then ag(a7,ab,"Menu",{name="Insert",button=aV})return end',
    "2-Insert")

# 3) remover o antigo handler de View (com o ';' antecedente, p/ nao sobrar ';;')
rep(';if X=="View"then C.Visible=true;A.Visible=true;return end',
    '',
    "3-View")

# 4) Play/Pause -> RunToggle/RunPause (apos o bloco Text)
rep('if X=="Text"then Q(I.selectedId or I.workspaceId,"TextLabel")return end',
    'if X=="Text"then Q(I.selectedId or I.workspaceId,"TextLabel")return end;if X=="Play"then ag(a7,ab,"RunToggle")return end;if X=="Pause"then ag(a7,ab,"RunPause")return end',
    "4-Play")

# 5) lock de execucao: bloqueia edicao enquanto ArkherRunning (apenas a do cP)
rep('local X=(V(aV,"SelectionKey")or aV.Name):gsub("^Menu_","")if cK[X]then',
    'local X=(V(aV,"SelectionKey")or aV.Name):gsub("^Menu_","")if V(a0,"ArkherRunning")==true and(cK[X]or X=="Folder"or X=="Model"or X=="Script"or X=="Text")and X~="Select"then aQ("Em execução — use Run > Stop para voltar a editar.",true)return end;if cK[X]then',
    "5-RunLock")

# 6) Command Bar executa Luau (';' explicito em todo limite de statement)
CB = ('cV.PlaceholderText="Command Bar — escreva Luau e aperte Enter (executa no cliente)"'
      'cw(cV,"Executa Luau no cliente. Ex: game:GetService(\'Workspace\').Gravity=200")'
      'an(cV.FocusLost,function()local code=cV.Text;'
      'if not code:match("%S")then cV.Text="";return end;'
      'local ok,fn=loadstring(code,"==ArkherCommandBar==");'
      'if not ok then aQ(tostring(fn),true);cV.Text="";return end;'
      'local rok,rres=pcall(fn);'
      'if rok then local msg="Comando executado";'
      'if type(rres)~="nil"then msg=msg.." ("..tostring(rres)..")"end;'
      'aQ(msg);else aQ("Erro: "..tostring(rres),true);end;'
      'cV.Text=""end,I.propertyConnections)')
rep('cV.PlaceholderText="Command Bar — execução de código em desenvolvimento"cw(cV,"Este campo ainda não executa código.")',
    CB,
    "6-CommandBar")

# 7) cO: remove os implementados (Edit/View/Run/Game/Play/Pause/topos/Save)
old_co = 'local cO={Edit="Undo/Redo e operações avançadas de edição.",Run="Comandos de execução/simulação.",Game="Configurações de jogo.",Open="Abrir arquivos e projetos.",SaveToArkher="Salvar projetos na nuvem.",Transform="Ferramenta unificada de transformação.",Play="Executar uma simulação independente do servidor atual.",Pause="Pausar a simulação do projeto.",Data="Gerenciamento avançado de dados.",Localization="Ferramentas de localização/tradução.",Settings="Configurações completas do projeto.",Toolbox="Biblioteca e importação de assets.",CollaborationSettings="Configurações de colaboração.",ArkherCloud="Integração com a nuvem.",PluginToolbar="Sistema de plugins.",Collaborate="Colaboração e convites.",Invites="Gerenciamento de convites.",Changes="Histórico de alterações.",Account="Configurações da conta.",Save="A janela existe; publicar/salvar o place no Roblox ainda está em desenvolvimento."}'
new_co = 'local cO={Open="Abrir arquivos e projetos.",SaveToArkher="Salvar cópia do projeto na Arkher Cloud.",Transform="Ferramenta unificada de transformação.",Data="Gerenciador de dados (chave/valor).",Localization="Idiomas e traduções do jogo.",Settings="Configurações do projeto e do mundo.",Toolbox="Biblioteca de templates prontos.",CollaborationSettings="Equipe, papéis e convites.",ArkherCloud="Cópias de projeto na nuvem (custom).",PluginToolbar="Central de sistemas e plugins."}'
rep(old_co, new_co, "7-cO")

# 8) status final
rep('FILE/INSERT ativos', 'menus File/Edit/View/Insert/Run/Game ativos', "8-status")

# 9) F5 -> RunToggle
rep('if cV.KeyCode==Enum.KeyCode.F8 then x.Enabled=not x.Enabled;return end',
    'if cV.KeyCode==Enum.KeyCode.F8 then x.Enabled=not x.Enabled;return end;if cV.KeyCode==Enum.KeyCode.F5 then ag(a7,ab,"RunToggle")return end',
    "9-F5")

# 10) roteia botoes de sistemas p/ paineis custom (Data/Toolbox/Cloud/Collab/Locale/Settings/Plugins)
rep('if X=="Pause"then ag(a7,ab,"RunPause")return end;cu("Em desenvolvimento",cO[X]or"Este controle ainda não foi implementado.")',
    'if X=="Pause"then ag(a7,ab,"RunPause")return end;'
    'if X=="Data"then ag(a7,ab,"OpenData")return end;'
    'if X=="Toolbox"then ag(a7,ab,"OpenToolbox")return end;'
    'if X=="ArkherCloud"or X=="SaveToArkher"then ag(a7,ab,"OpenCloud")return end;'
    'if X=="CollaborationSettings"then ag(a7,ab,"OpenCollaboration")return end;'
    'if X=="Localization"then ag(a7,ab,"OpenLocalization")return end;'
    'if X=="Settings"then ag(a7,ab,"OpenProjectSettings")return end;'
    'if X=="PluginToolbar"then ag(a7,ab,"OpenPlugins")return end;'
    'cu("Em desenvolvimento",cO[X]or"Este controle ainda não foi implementado.")',
    "10-Systems")

# 11) tooltip dos sistemas agora mostra a funcao real (nao "Em desenvolvimento")
rep('cy[aV]=cA;cw(aV,"Em desenvolvimento: "..cA)',
    'cy[aV]=cA;cw(aV,cA)',
    "11-Tooltip")

# ---- valida: nenhum ';;' e parens balanceados ----
assert s.count(";;") == 0, f"sobrou ';;': {s.count(';;')}"
assert s.count("(") == s.count(")"), "parens desbalanceados"

open(P, "w", encoding="utf-8").write(s)
print(f"01_Nucleo.lua atualizado: {len(s)} chars (11 edicoes, sem ';;', parens ok)")
