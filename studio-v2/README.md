# ARKHER STUDIO V2 — UIs por Command Bar (Roblox)

Rebuild completo da interface do **ARKHER STUDIO** fiel à print (`Recording_20260908_174341.jpg` na raiz do repo) + **todas as outras UIs** da plataforma no mesmo tipo e estilo, com **todos os ícones desenhados por Frame** (zero assets externos, zero ImageLabel).

Arquitetura: `UES + ARKHER + D-O15 + SINGULARITY AI` — o Roblox é só a camada de adaptação; a UI é nossa, original.

---

## O que tem aqui

```
studio-v2/
├── src/                  # código-fonte modular (edite aqui, rode ./build.sh)
│   ├── prelude.luau      #   Theme + Kit + TODOS os ícones por Frame
│   ├── body_main.luau    #   A UI EXATA da print (titlebar, menus, ribbon, Properties, Hierarchy, viewport)
│   ├── body_systems.luau #   Sistemas: rotas de ações, atalhos, Inspector live, Hierarchy live, sandbox
│   ├── ed_a.luau         #   Splash, Login/Arkher Cloud, SaveOpen, Command Palette, Settings, StatusBar, Search, Docs
│   ├── ed_b.luau         #   Script Editor, Console, Debugger, Profiler, Timeline, Material, Terrain, Animation, Particle, VFX
│   ├── ed_c.luau         #   Audio, Physics, Navigation, AI(Singularity), World, UI Editor, Shader/Node/VisualScripting, Graph, UTS AI
│   └── ed_d.luau         #   Project/Build Settings, Packages, Plugins, Version Control, Collab, Localization, Data, Toolbox, Undo, Layouts, Notifs
├── commandbar/           # SCRIPTS FINAIS COLÁVEIS NO COMMAND BAR (gerados pelo build.sh)
│   ├── ArkherStudio_MainUI.lua   # SÓ a UI da print → cria tudo no StarterGui
│   ├── ArkherStudio_ALL.lua      # CRIA TODAS AS UIs + sistemas de uma vez
│   ├── ArkherSystems.lua         # só os sistemas (inspector/hierarchy live, rotas, atalhos)
│   ├── ArkherCore_Installer.lua  # instala ModuleScript ArkherKit p/ reuso
│   └── UI_<Nome>.lua (41)        # cada UI individual, standalone
└── tests/                # harness que EXECUTA os scripts fora do Roblox (shim da API)
```

## Como usar no Roblox Studio

1. Abra o Studio → **View → Command Bar**.
2. (Opcional, pra limpar UIs antigas do V2 anterior) cole primeiro:
   ```lua
   for _, g in ipairs(game:GetService("StarterGui"):GetChildren()) do
       if g.Name:find("Arkher") then g:Destroy() end
   end
   ```
3. Cole o conteúdo de **UM** destes scripts e aperte Enter:
   - `commandbar/ArkherStudio_MainUI.lua` → só a réplica da print.
   - `commandbar/ArkherStudio_ALL.lua` → **TUDO**: main + 40 UIs + sistemas.
   - `commandbar/UI_<Nome>.lua` → uma UI específica.
4. Aperte **Play (F5)**: as ScreenGuis montam no `StarterGui` e a interface aparece. Cada janela é arrastável/fechável; o ALL abre tudo em cascata.

Cada script **substitui a versão anterior dele sozinho** (destrói a ScreenGui de mesmo nome antes de recriar) — então colar por cima do V2 velho já troca.

## Ícones por Frame

Todos os ~50 ícones (Save, Open, Cloud, Select, Scale, Rotate, Transform/Lock, Model, Folder, Script, Text, Play, Pause, Data, Localization, Settings, Toolbox, Collab, Arkher Cloud, Plugin, e os da Hierarchy: Workspace, Baseplate, Terrain, Camera, Players, Lighting, MaterialService, ReplicatedFirst/Storage, ServerScript/Storage, StarterGui/Pack/Player, TextChat…) são compostos por `Frame` + `UICorner` + `UIStroke` + `UIGradient` numa grade 20×20 (`ARKHER.ICON.<nome>`). Nada de emoji, nada de assetId.

## Como consertar o sandbox

Depende de qual sandbox:

**1) Sandbox do Roblox / executor.** Os scripts usam só APIs permitidas no Command Bar oficial (`Instance.new`, `game:GetService`, `Selection`, `UserInputService`). Se você estiver num executor de terceiros com sandbox restrito, libere `Instance.new`, `game:GetService` e eventos de input — ou use o Command Bar oficial do Studio, que tem acesso total de edição. O botão **Save** grava um snapshot REAL (JSON da hierarquia) em `ServerStorage.ArkherCloud`; não toca filesystem.

**2) Sandbox da engine ARKHER (sistema #41 / política de execução).** Dentro da própria UI: menu **RUN → "Sandbox: ON"** alterna; **Settings → Security** mostra capability tokens; plugins rodam isolados com hot reload (**Plugin Toolbar**). Se uma sessão de sandbox quebrar: feche o place, re-cole o `ArkherStudio_ALL.lua`, e reative pelo RUN — o instalador é idempotente e reconstrói capability state.

**3) Sandbox desta Arena (onde eu trabalho).** Se a sessão/preview travar, basta reabrir a sessão — o trabalho fica salvo no branch. Evite `git lfs pull` do `Arkher.zip` (356 MB) em máquina/sandbox fraco; ele não é necessário pra nada do V2.

## Verificação (o que eu rodei de verdade)

`tests/` tem um shim da API Roblox em Lua puro + runner (`tests/run.py`, requer `pip install lupa`). Ele **executa** cada script final e dispara cliques reais:

- `ArkherStudio_MainUI.lua` → 1 ScreenGui, **1.144 instâncias** (a print inteira).
- `ArkherStudio_ALL.lua` → **42 ScreenGuis, 6.093 instâncias, 43 UIs registradas**.
- 41/41 scripts `UI_*.lua` executam sem erro.
- Interações verificadas: Save gravou snapshot real no `ServerStorage.ArkherCloud`; Command Palette listou 10 comandos; menu FILE abriu com 11 itens; checkbox da Properties alternou; Toolbox inseriu `Part` real no `workspace`; Hierarchy live espelhou o workspace (8 linhas); Script Editor executou código; Build rodou.

O que eu **não** consigo verificar aqui: o render visual dentro do Roblox. Abra no Studio e aperte F5 pra ver — o layout segue as coordenadas/cores amostradas da print.

## Regenerar depois de editar

```bash
cd studio-v2 && ./build.sh
```
