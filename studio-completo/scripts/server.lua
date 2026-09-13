local CONFIG={AUTHORIZED_USERNAMES={"WhiteXz73_Developer","tentandoserbanido_9"},MAX_NODES=12000,MAX_CREATED_PER_SESSION=2000,MAX_POSITION=1000000,MAX_SIZE=2048,TRANSFORM_TIMEOUT=20,}local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")local Http=game:GetService("HttpService")assert(not RS:FindFirstChild("ArkherStudioBridge"),"Já existe um ArkherEditorServer. Use apenas um Script de servidor.")local bridge=Instance.new("Folder");bridge.Name="ArkherStudioBridge";bridge:SetAttribute("Protocol",3);bridge.Parent=RS local request=Instance.new("RemoteFunction");request.Name="Request";request.Parent=bridge local updates=Instance.new("RemoteEvent");updates.Name="Updates";updates.Parent=bridge local preview=Instance.new("RemoteEvent");preview.Name="TransformPreview";preview.Parent=bridge local catalog={}local byClass={}local function add(class,category,group,description,aliases)local entry={class=class,category=category,group=group,description=description,aliases=aliases or""}catalog[#catalog+1]=entry;byClass[class]=entry end add("Folder","Containers","container","Pasta para organizar objetos.","pasta")add("Model","Containers","container","Agrupa peças e outros objetos em um modelo.","modelo")add("Part","3D","geometry","Peça básica do cenário. Pode receber scripts, efeitos e outros filhos.","bloco peça parte")add("WedgePart","3D","geometry","Peça em formato de rampa.","rampa")add("CornerWedgePart","3D","geometry","Rampa de canto.","canto")add("TrussPart","3D","geometry","Estrutura escalável.","escada")add("SpawnLocation","3D","geometry","Ponto de nascimento dos jogadores.","spawn nascimento")add("Script","Scripts","script","Script de servidor vazio e desativado. Edite o código no Roblox Studio.","código servidor")add("LocalScript","Scripts","script","LocalScript vazio e desativado. Só executa nos contextos de cliente aceitos pelo Roblox.","local script código cliente")add("ModuleScript","Scripts","script","ModuleScript vazio. Criá-lo não executa código; Source é editado no Studio.","module script módulo")add("ScreenGui","UI","screen","Tela de interface; use StarterGui como pai.","ScreenGUI Screen GUI UI Screen tela")for _,class in ipairs({"Frame","TextLabel","TextButton","TextBox","ImageLabel","ImageButton","ScrollingFrame"})do add(class,"UI","gui","Elemento de interface. Adicione dentro de ScreenGui ou outro GuiObject.","interface botão texto imagem")end for _,class in ipairs({"UICorner","UIStroke","UIGradient","UIPadding","UIListLayout","UIGridLayout","UIAspectRatioConstraint","UISizeConstraint"})do add(class,"UI","component","Componente visual ou de layout de uma interface.","interface componente layout")end add("Tool","Gameplay","tool","Ferramenta vazia, sem Handle obrigatório.","ferramenta")add("Attachment","3D","attachment","Ponto de referência dentro de uma peça.","anexo")add("Decal","Appearance","surface","Imagem aplicada a uma face de uma peça.","adesivo decalque")add("Texture","Appearance","surface","Textura aplicada a uma peça.","textura")for _,class in ipairs({"PointLight","SpotLight","SurfaceLight"})do add(class,"Effects","effect","Fonte de luz em uma peça ou Attachment.","luz iluminação")end for _,class in ipairs({"ParticleEmitter","Fire","Smoke","Sparkles"})do add(class,"Effects","effect","Efeito visual em uma peça ou Attachment.","partícula fogo fumaça efeito")end add("Sound","Audio","sound","Objeto de áudio; configure SoundId nas propriedades.","som áudio")add("ClickDetector","Gameplay","detector","Detector de cliques em uma peça.","clique")add("ProximityPrompt","Gameplay","prompt","Interação de proximidade em uma peça, Attachment ou Model.","interagir proximidade")add("MaterialVariant","Appearance","material","Variação de material dentro de MaterialService.","material")for _,class in ipairs({"BoolValue","IntValue","NumberValue","StringValue","Vector3Value","Color3Value","ObjectValue"})do add(class,"Values","value","Armazena um valor como filho de outro objeto.","valor dados")end local roots,rootSet,rootIds={},{},{}for _,name in ipairs({"Workspace","Players","Lighting","MaterialService","ReplicatedFirst","ReplicatedStorage","ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer","TextChatService"})do local ok,o=pcall(function()return game:GetService(name)end)if ok then roots[#roots+1]=o;rootSet[o]=true end end local idOf,objects,watchers={},{},{}local subscribed,selected,created,buckets,transactions,locks={},{},{},{},{},{}local dirty,removed={},{}
local hist = {}
local pipeStats={deltaFlush=0,deltaNodes=0,propsPush=0,selRemoved=0,selects=0,creates=0,skippedCap=0,skippedParent=0} -- R2: contadores do pipeline workspace/props
local clip = {}
local HIST_MAX = 50

local function histCleanup(e)
    if e and e.cleanup then pcall(e.cleanup) end
end

local function pushHist(player, entry)
    local h = hist[player] or { undo = {}, redo = {} }
    hist[player] = h
    table.insert(h.undo, entry)
    if #h.undo > HIST_MAX then histCleanup(table.remove(h.undo, 1)) end
    h.redo = {}
end

local function clearHist(player)
    local h = hist[player]
    if not h then return end
    for _, e in ipairs(h.undo) do histCleanup(e) end
    for _, e in ipairs(h.redo) do histCleanup(e) end
    h.undo = {}
    h.redo = {}
end
local nextId,revision,nodeCount=0,0,0 local register,unregister,queueObject local function normalizeUsername(value)if type(value)~="string"then return nil end local name=value:match("^%s*(.-)%s*$"):gsub("^@",""):lower()if name==""or name=="seu_usuario_aqui"then return nil end return name end local allowedUsernames={}for _,name in ipairs(CONFIG.AUTHORIZED_USERNAMES)do local normalized=normalizeUsername(name)if normalized then allowedUsernames[normalized]=true end end if not next(allowedUsernames)then warn("Arkher: substitua SEU_USUARIO_AQUI pelo seu nome principal em AUTHORIZED_USERNAMES. Acesso fechado até configurar.")end local function authorized(player)if not player or player.Parent~=Players then return false end return allowedUsernames[normalizeUsername(player.Name)]==true end local function consume(player,cost)local now=os.clock();local b=buckets[player]or{tokens=80,time=now};buckets[player]=b b.tokens=math.min(80,b.tokens+(now-b.time)*35);b.time=now if b.tokens<cost then return false end b.tokens=b.tokens-cost;return true end local function hidden(o)if o==script or o:IsDescendantOf(script)or o==bridge or o:IsDescendantOf(bridge)then return true end local p=o while p and p~=game do if p.Name=="ArkherStudioUI"and p:IsA("ScreenGui")then return true end if p:GetAttribute("ArkherInternal")then return true end p=p.Parent end return false end local function rootFor(o)local p=o while p and p~=game do if rootSet[p]then return p end;p=p.Parent end end local function inspectable(o)return o and o.Parent and rootFor(o)~=nil and not hidden(o)end local function characterPart(o)for _,p in ipairs(Players:GetPlayers())do if p.Character and(o==p.Character or o:IsDescendantOf(p.Character))then return true end end return false end local function editable(o)local r=rootFor(o)return inspectable(o)and r~=Players and r~=game:GetService("TextChatService")and not characterPart(o)end local function containsProtected(o)if script:IsDescendantOf(o)or bridge:IsDescendantOf(o)then return true end for _,p in ipairs(Players:GetPlayers())do if p.Character and p.Character:IsDescendantOf(o)then return true end end for _,child in ipairs(o:GetDescendants())do if child:IsA("ScreenGui")and child.Name=="ArkherStudioUI"then return true end end return false end local function conflictingLock(o,exceptPlayer)for locked,owner in pairs(locks)do if owner~=exceptPlayer and(locked==o or locked:IsDescendantOf(o)or o:IsDescendantOf(locked))then return true end end return false end local function category(o)if byClass[o.ClassName]then return byClass[o.ClassName].category end if o:IsA("BasePart")then return"3D"end if o:IsA("LuaSourceContainer")then return"Scripts"end if o:IsA("GuiObject")or o:IsA("LayerCollector")then return"UI"end if rootSet[o]then return"Services"end return"Objects"end local function remoteObject(o)local r=rootFor(o)if r==game:GetService("ServerStorage")or r==game:GetService("ServerScriptService")then return nil end return o end local function canCreate(parent,entry)if not editable(parent)then return false,"Pai protegido ou somente leitura."end local group=entry.group local isFolder=parent:IsA("Folder")local isModel=parent.ClassName=="Model"local isPart=parent:IsA("BasePart")and not parent:IsA("Terrain")local dataRoot=parent==workspace or parent==RS or parent==game:GetService("ServerStorage")or parent==game:GetService("ReplicatedFirst")local container=dataRoot or isFolder or isModel if group=="screen"then return parent==game:GetService("StarterGui")or(isFolder and parent:IsDescendantOf(game:GetService("StarterGui"))),"ScreenGui usa StarterGui como pai."elseif group=="gui"then return parent:IsA("GuiObject")or parent:IsA("LayerCollector"),"Escolha um ScreenGui ou GuiObject."elseif group=="component"then return parent:IsA("GuiObject"),"Escolha um GuiObject."elseif group=="geometry"then return container or parent:IsA("Tool"),"Escolha Workspace, Model, Folder ou um armazenamento."elseif group=="attachment"or group=="surface"or group=="detector"then return isPart,"Escolha uma peça como pai."elseif group=="effect"then return isPart or parent:IsA("Attachment"),"Escolha uma peça ou Attachment."elseif group=="prompt"then return isPart or isModel or parent:IsA("Attachment"),"Escolha Part, Model ou Attachment."elseif group=="material"then return parent==game:GetService("MaterialService"),"Escolha MaterialService."elseif group=="tool"then return container or parent==game:GetService("StarterPack"),"Escolha StarterPack, Workspace ou um contêiner."elseif group=="script"then return parent:IsA("Tool")or parent:IsA("LuaSourceContainer")or container or isPart or parent:IsA("GuiObject")or parent:IsA("LayerCollector")or parent==game:GetService("ServerScriptService")or parent==game:GetService("StarterGui")or parent:IsA("StarterPlayerScripts")or parent:IsA("StarterCharacterScripts"),"Escolha uma peça, contêiner, interface ou pasta de scripts."elseif group=="container"or group=="value"or group=="sound"then return container or isPart or parent:IsA("GuiObject")or parent:IsA("LayerCollector")or parent==game:GetService("ServerScriptService")or parent==game:GetService("StarterGui")or parent==game:GetService("StarterPack")or parent:IsA("LuaSourceContainer"),"Este tipo não é compatível com o pai selecionado."end return false,"Tipo não permitido."end local function canInsert(o)for _,entry in ipairs(catalog)do if canCreate(o,entry)then return true end end return false end local function record(o)local has=false for _,c in ipairs(o:GetChildren())do if inspectable(c)then has=true;break end end return{id=idOf[o],parentId=idOf[o.Parent],name=o.Name,class=o.ClassName,category=category(o),hasChildren=has,canInsert=canInsert(o),canDelete=editable(o)and not rootSet[o]and not containsProtected(o),readOnly=not editable(o),object=remoteObject(o)}end queueObject=function(o)if not inspectable(o)then return end if not idOf[o]then register(o)end if idOf[o]then dirty[idOf[o] ]=true;removed[idOf[o] ]=nil end end register=function(o)if idOf[o]or not inspectable(o)then return end if nodeCount>=CONFIG.MAX_NODES and not rootSet[o]then pipeStats.skippedCap=pipeStats.skippedCap+1;if pipeStats.skippedCap<=3 then warn("[ArkherPipe] register pulado por MAX_NODES: "..tostring(o and o:GetFullName())) end;return end if not rootSet[o]and inspectable(o.Parent)and not idOf[o.Parent]then register(o.Parent);if not idOf[o.Parent]then pipeStats.skippedParent=pipeStats.skippedParent+1;return end end nextId=nextId+1;nodeCount=nodeCount+1;local id="n"..nextId;idOf[o]=id;objects[id]=o watchers[o]={o:GetPropertyChangedSignal("Name"):Connect(function()queueObject(o)end),o.AncestryChanged:Connect(function()task.defer(function()if inspectable(o)then queueObject(o);queueObject(o.Parent)else unregister(o)end end)end),}dirty[id]=true end unregister=function(o)local id=idOf[o];if not id then return end for _,c in ipairs(o:GetDescendants())do if idOf[c]then unregister(c)end end idOf[o]=nil;objects[id]=nil;dirty[id]=nil;removed[id]=true;nodeCount=math.max(0,nodeCount-1)for _,c in ipairs(watchers[o]or{})do c:Disconnect()end;watchers[o]=nil end for _,r in ipairs(roots)do register(r);rootIds[#rootIds+1]=idOf[r]end for _,r in ipairs(roots)do r.DescendantAdded:Connect(function(o)if inspectable(o)then register(o);queueObject(o.Parent)end end)r.DescendantRemoving:Connect(function(o)local oldParent=o.Parent task.defer(function()if inspectable(o)then queueObject(o)else unregister(o)end if oldParent and inspectable(oldParent)then queueObject(oldParent)end end)end)for _,o in ipairs(r:GetDescendants())do if nodeCount>=CONFIG.MAX_NODES then break end if inspectable(o)then register(o)end end end 
local function serializeTree(o, depth)
    depth = depth or 0
    if depth > 40 or not inspectable(o) then return nil end
    local t = { c = o.ClassName, n = o.Name }
    local p = {}
    if o:IsA("BasePart") and not o:IsA("Terrain") then
        local cf = o.CFrame
        local rx, ry, rz = cf:ToEulerAnglesYXZ()
        p.pos = cf.Position
        p.rot = Vector3.new(rx, ry, rz)
        p.size = o.Size
        p.color = o.Color
        p.trans = o.Transparency
        p.mat = o.Material.Name
        p.anchor = o.Anchored
        p.cc = o.CanCollide
        p.ct = o.CanTouch
        p.cq = o.CanQuery
        p.cs = o.CastShadow
        p.locked = o.Locked
        p.reflect = o.Reflectance
    end
    if o.ClassName == "Model" then
        p.pivot = o:GetPivot().Position
        p.scale = o:GetScale()
        if o.PrimaryPart then p.primary = o.PrimaryPart.Name end
    end
    if o:IsA("GuiObject") then
        p.pos2 = o.Position
        p.size2 = o.Size
        p.bg = o.BackgroundColor3
        p.bgt = o.BackgroundTransparency
        p.active = o.Active
    end
    if o:IsA("TextLabel") then
        p.text = o.Text
        p.tcolor = o.TextColor3
        p.tsize = o.TextSize
    end
    if o:IsA("BaseScript") then
        p.source = o.Source
        p.enabled = o.Enabled
    end
    if o:IsA("ValueBase") then p.value = o.Value end
    if o:IsA("Sound") then
        p.soundId = o.SoundId
        p.vol = o.Volume
        p.looped = o.Looped
        p.speed = o.PlaybackSpeed
    end
    for k, v in pairs(o:GetAttributes()) do p["@" .. k] = v end
    if next(p) then t.p = p end
    local kids = {}
    for _, c in ipairs(o:GetChildren()) do
        local s = serializeTree(c, depth + 1)
        if s then kids[#kids + 1] = s end
    end
    if #kids > 0 then t.k = kids end
    return t
end

local function countTree(t)
    local n = 1
    for _, c in ipairs(t.k or {}) do n = n + countTree(c) end
    return n
end

local function deserializeTree(parent, t)
    assert(type(t) == "table" and type(t.c) == "string", "Nó inválido.")
    assert(byClass[t.c], "Classe não permitida na importação: " .. tostring(t.c))
    local o = Instance.new(t.c)
    pcall(function() o.Name = (type(t.n) == "string" and #t.n > 0) and t.n or t.c end)
    local pr = t.p or {}
    if o:IsA("BasePart") then
        if pr.size then o.Size = pr.size end
        if pr.color then o.Color = pr.color end
        if pr.trans then o.Transparency = pr.trans end
        if pr.mat then pcall(function() o.Material = Enum.Material[pr.mat] end) end
        if pr.anchor ~= nil then o.Anchored = pr.anchor end
        if pr.cc ~= nil then o.CanCollide = pr.cc end
        if pr.ct ~= nil then o.CanTouch = pr.ct end
        if pr.cq ~= nil then o.CanQuery = pr.cq end
        if pr.cs ~= nil then o.CastShadow = pr.cs end
        if pr.locked ~= nil then o.Locked = pr.locked end
        if pr.pos then
            o.CFrame = CFrame.fromEulerAnglesYXZ((pr.rot and pr.rot.X) or 0, (pr.rot and pr.rot.Y) or 0, (pr.rot and pr.rot.Z) or 0) * CFrame.new(pr.pos)
        end
    end
    if o.ClassName == "Model" then
        if pr.scale then pcall(function() o:ScaleTo(pr.scale) end) end
    end
    if o:IsA("GuiObject") then
        if pr.pos2 then o.Position = pr.pos2 end
        if pr.size2 then o.Size = pr.size2 end
        if pr.bg then o.BackgroundColor3 = pr.bg end
        if pr.bgt then o.BackgroundTransparency = pr.bgt end
        if pr.active ~= nil then o.Active = pr.active end
    end
    if o:IsA("TextLabel") then
        if pr.text then o.Text = pr.text end
        if pr.tcolor then o.TextColor3 = pr.tcolor end
        if pr.tsize then o.TextSize = pr.tsize end
    end
    if o:IsA("BaseScript") then
        if pr.source then o.Source = pr.source end
        if pr.enabled ~= nil then o.Enabled = pr.enabled end
    end
    if o:IsA("Sound") then
        if pr.soundId then o.SoundId = pr.soundId end
        if pr.vol then o.Volume = pr.vol end
        if pr.looped ~= nil then o.Looped = pr.looped end
        if pr.speed then o.PlaybackSpeed = pr.speed end
    end
    if o:IsA("ValueBase") then
        if pr.value ~= nil then pcall(function() o.Value = pr.value end) end
    end
    for k, v in pairs(pr) do
        if type(k) == "string" and k:sub(1, 1) == "@" then pcall(function() o:SetAttribute(k:sub(2), v) end) end
    end
    o.Parent = parent
    for _, c in ipairs(t.k or {}) do deserializeTree(o, c) end
    return o
end
local function getObject(id)assert(type(id)=="string"and#id<48,"Identificador inválido.")local o=objects[id];assert(inspectable(o),"Objeto removido ou indisponível.")return o end local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end local function vec(v,min,max)assert(typeof(v)=="Vector3"and finite(v.X)and finite(v.Y)and finite(v.Z),"Vetor inválido.")assert(v.X>=min and v.Y>=min and v.Z>=min and v.X<=max and v.Y<=max and v.Z<=max,"Vetor fora do limite.")return v end local function cframe(v)assert(typeof(v)=="CFrame","CFrame inválido.")for _,n in ipairs({v:GetComponents()})do assert(finite(n)and math.abs(n)<=CONFIG.MAX_POSITION,"CFrame fora do limite.")end return v end local function read(o,key)local ok,v=pcall(function()return o[key]end);if ok then return v end end local function descriptors(o)local fields={}local write=editable(o)local function field(group,key,kind,allowed,lo,hi,enum)local value=read(o,key);if value==nil then return end local expected=({string="string",number="number",boolean="boolean",vector="Vector3",color="Color3",enum="EnumItem"})[kind]if expected and typeof(value)~=expected then return end fields[#fields+1]={group=group,key=key,kind=kind,value=value,editable=write and allowed==true,min=lo,max=hi,enum=enum,set=allowed and function(v)o[key]=v end or nil}end local function custom(group,key,kind,value,set,lo,hi)fields[#fields+1]={group=group,key=key,kind=kind,value=value,editable=write and set~=nil,set=set,min=lo,max=hi}end field("Data","Name","string",not rootSet[o]);field("Data","ClassName","string",false)custom("Data","Parent","string",o.Parent and o.Parent.Name or"None")custom("Data","Category","string",category(o))field("Data","Archivable","boolean",true)custom("Data","Children","number",#o:GetChildren())if o==workspace then field("World","Gravity","number",true,0,10000);field("World","GlobalWind","vector",true,-10000,10000)field("World","StreamingEnabled","boolean",false)elseif o:IsA("Terrain")then field("Water","WaterColor","color",true);field("Water","WaterTransparency","number",true,0,1)field("Water","WaterReflectance","number",true,0,1);field("Water","WaterWaveSize","number",true,0,1)field("Water","WaterWaveSpeed","number",true,0,100)elseif o:IsA("BasePart")then field("Transform","Position","vector",true,-CONFIG.MAX_POSITION,CONFIG.MAX_POSITION)field("Transform","Orientation","vector",true,-36000,36000);field("Transform","Size","vector",true,0.05,CONFIG.MAX_SIZE)field("Appearance","Color","color",true);field("Appearance","Transparency","number",true,0,1)field("Appearance","Material","enum",true,nil,nil,Enum.Material);field("Appearance","Reflectance","number",true,0,1)for _,key in ipairs({"Anchored","CanCollide","CanTouch","CanQuery","CastShadow","Locked"})do field("Physics",key,"boolean",true)end elseif o.ClassName=="Model"then local cf=o:GetPivot();local x,y,z=cf:ToOrientation()custom("Transform","Position","vector",cf.Position,function(v)local p=o:GetPivot();o:PivotTo(CFrame.new(v)*(p-p.Position))end,-CONFIG.MAX_POSITION,CONFIG.MAX_POSITION)custom("Transform","Orientation","vector",Vector3 .new(math.deg(x),math.deg(y),math.deg(z)),function(v)o:PivotTo(CFrame.new(o:GetPivot().Position)*CFrame.fromOrientation(math.rad(v.X),math.rad(v.Y),math.rad(v.Z)))end,-36000,36000)custom("Transform","Scale","number",o:GetScale(),function(v)o:ScaleTo(v)end,0.01,100)custom("Data","PrimaryPart","string",o.PrimaryPart and o.PrimaryPart.Name or"None")elseif o:IsA("Lighting")then field("Lighting","Brightness","number",true,0,100);field("Lighting","ClockTime","number",true,0,24)field("Lighting","Ambient","color",true);field("Lighting","OutdoorAmbient","color",true);field("Lighting","GlobalShadows","boolean",true)elseif o:IsA("LuaSourceContainer")then custom("Scripting","Source","string","Código editado no Roblox Studio")field("Scripting","Enabled","boolean",true)elseif o:IsA("Attachment")then field("Transform","Position","vector",true,-100000,100000);field("Transform","Orientation","vector",true,-36000,36000)elseif o:IsA("Decal")then field("Appearance","Texture","string",true);field("Appearance","Color3","color",true)field("Appearance","Transparency","number",true,0,1);field("Appearance","Face","enum",true,nil,nil,Enum.NormalId)elseif o:IsA("Sound")then field("Audio","SoundId","string",true);field("Audio","Volume","number",true,0,10)field("Audio","PlaybackSpeed","number",true,0.1,4);field("Audio","Looped","boolean",true)elseif o:IsA("GuiObject")then field("UI","Visible","boolean",true);field("UI","BackgroundColor3","color",true);field("UI","BackgroundTransparency","number",true,0,1)field("UI","Text","string",true);field("UI","TextColor3","color",true);field("UI","Rotation","number",true,-36000,36000)elseif o:IsA("LayerCollector")then field("UI","Enabled","boolean",true)elseif o:IsA("ValueBase")then local v=read(o,"Value");local kind=({string="string",number="number",boolean="boolean",Vector3="vector",Color3="color"})[typeof(v)]if kind then field("Value","Value",kind,true,-1000000,1000000)else custom("Value","Value","string",tostring(v))end end return fields end local function properties(o)local result={id=idOf[o],name=o.Name,class=o.ClassName,category=category(o),fields={}}for _,f in ipairs(descriptors(o))do local row={group=f.group,key=f.key,kind=f.kind,value=f.value,editable=f.editable,min=f.min,max=f.max}if f.kind=="enum"then row.value=f.value.Name;row.options={}for _,item in ipairs(f.enum:GetEnumItems())do row.options[#row.options+1]=item.Name end end result.fields[#result.fields+1]=row end return result end local function setProperty(o,key,value)assert(editable(o),"Objeto somente leitura.")if key=="Position"or key=="Orientation"or key=="Size"or key=="Scale"then assert(not containsProtected(o),"O contêiner contém objetos protegidos.")if o:IsA("BasePart")then assert(not o.Locked,"Desbloqueie a peça antes de transformá-la.")end if o.ClassName=="Model"then for _,p in ipairs(o:GetDescendants())do if p:IsA("BasePart")then assert(not p.Locked,"O modelo contém uma peça bloqueada.")end end end end local field for _,f in ipairs(descriptors(o))do if f.key==key and f.editable then field=f;break end end assert(field and field.set,"Propriedade não permitida.")local kind=field.kind if kind=="string"then assert(type(value)=="string"and#value<2048,"Texto inválido.")if key=="Name"then assert(#value>0 and#value<=100 and not value:match("^%s*$"),"Nome inválido.")end elseif kind=="number"then assert(finite(value)and value>=(field.min or-1000000)and value<=(field.max or 1000000),"Número fora do limite.")elseif kind=="boolean"then assert(type(value)=="boolean","Booleano inválido.")elseif kind=="vector"then vec(value,field.min or-1000000,field.max or 1000000)elseif kind=="color"then assert(typeof(value)=="Color3","Cor inválida.")for _,n in ipairs({value.R,value.G,value.B})do assert(finite(n)and n>=0 and n<=1,"Cor fora do limite.")end elseif kind=="enum"then assert(type(value)=="string"and#value<100,"Enum inválido.")local found for _,item in ipairs(field.enum:GetEnumItems())do if string.lower(item.Name)==string.lower(value)then found=item end end assert(found,"Enum não permitido.");value=found end field.set(value);queueObject(o)end local function allParts(o)if o:IsA("BasePart")and not o:IsA("Terrain")then return{o}end local result={}if o.ClassName=="Model"then for _,p in ipairs(o:GetDescendants())do if p:IsA("BasePart")and not p:IsA("Terrain")then result[#result+1]=p end end end return result end local function getPivot(o)return o:IsA("BasePart")and o.CFrame or o:GetPivot()end local function setPivot(o,cf)if o:IsA("BasePart")then o.CFrame=cf else o:PivotTo(cf)end end local function release(player,rollback)local t=transactions[player];if not t then return end transactions[player]=nil;locks[t.object]=nil if rollback and t.object.Parent then pcall(function()if t.object:IsA("BasePart")then t.object.Size=t.size else t.object:ScaleTo(t.scale)end setPivot(t.object,t.cf)end)end for part,anchored in pairs(t.anchors)do if part.Parent then pcall(function()part.Anchored=anchored end)end end if t.object.Parent then queueObject(t.object)end end local function applyTransform(t,payload)assert(inspectable(t.object)and editable(t.object),"Objeto indisponível.")local o=t.object if payload.pivot then setPivot(o,cframe(payload.pivot))end if payload.size then assert(o:IsA("BasePart"),"Size exige BasePart.");o.Size=vec(payload.size,0.05,CONFIG.MAX_SIZE)end if payload.scale then assert(o.ClassName=="Model"and finite(payload.scale)and payload.scale>=0.01 and payload.scale<=100,"Escala inválida.");o:ScaleTo(payload.scale)end t.time=os.clock()end local function create(player,parent,class,name)local entry=byClass[class];assert(entry,"Classe não permitida.")assert(nodeCount<CONFIG.MAX_NODES,"Limite de objetos da Hierarchy atingido. Ajuste MAX_NODES no servidor.")local allowed,reason=canCreate(parent,entry);assert(allowed,reason)created[player]=created[player]or 0;assert(created[player]<CONFIG.MAX_CREATED_PER_SESSION,"Limite de criações da sessão atingido.")local o=Instance.new(class)local ok,err=pcall(function()local base=type(name)=="string"and#name>0 and name or class assert(#base<=100 and not base:match("^%s*$"),"Nome inválido.")local unique,index=base,1 while parent:FindFirstChild(unique)do unique=base..index;index=index+1 end o.Name=unique if o:IsA("BasePart")then o.Anchored=true;o.Size=Vector3 .new(4,1,2);o.Color=Color3 .fromRGB(129,184,242)if parent:IsA("BasePart")then o.CFrame=parent.CFrame*CFrame.new(0,parent.Size.Y/2+1,0)elseif parent.ClassName=="Model"then o.CFrame=parent:GetPivot()*CFrame.new(0,3,0)else o.CFrame=CFrame.new(0,5,0)end elseif o:IsA("BaseScript")then o.Enabled=false elseif o:IsA("ScreenGui")then o.ResetOnSpawn=false elseif o:IsA("GuiObject")then o.Size=UDim2 .fromOffset(200,60);o.Position=UDim2 .fromOffset(24,24);o.BackgroundColor3=Color3 .fromRGB(20,45,80)if o:IsA("TextLabel")or o:IsA("TextButton")or o:IsA("TextBox")then o.Text=class;o.TextColor3=Color3 .new(1,1,1);o.TextSize=20 end elseif o:IsA("Tool")then o.RequiresHandle=false end o.Parent=parent end)if not ok then o:Destroy();error(err)end created[player]=created[player]+1;register(o);queueObject(parent)return o end local function snapshot()local nodes={}for _,root in ipairs(roots)do nodes[#nodes+1]=record(root)end for _,root in ipairs(roots)do for _,o in ipairs(root:GetDescendants())do if inspectable(o)then register(o)if idOf[o]then nodes[#nodes+1]=record(o)end end end end return{nodes=nodes,roots=rootIds,revision=revision,catalog=catalog,limit=CONFIG.MAX_NODES,atCapacity=nodeCount>=CONFIG.MAX_NODES}end 
local function hCreate(player, o)
    local saved = o:Clone()
    local parent = o.Parent
    local name0 = o.Name
    local live = o
    pushHist(player, {
        label = "Criar " .. o.Name,
        cleanup = function() if saved and not saved.Parent then saved:Destroy() end end,
        undo = function() if live and live.Parent then live:Destroy() end end,
        redo = function() local n = saved:Clone(); n.Name = name0; n.Parent = parent; live = n end,
    })
end

local function hDelete(player, o)
    local saved = o:Clone()
    local parent = o.Parent
    local name0 = o.Name
    local live = o
    pushHist(player, {
        label = "Excluir " .. o.Name,
        cleanup = function() if saved and not saved.Parent then saved:Destroy() end end,
        undo = function() local n = saved:Clone(); n.Name = name0; n.Parent = parent; live = n end,
        redo = function() if live and live.Parent then live:Destroy() end end,
    })
end

local function hSet(player, o, key, oldVal, newVal)
    pushHist(player, {
        label = "Editar " .. key .. " de " .. o.Name,
        undo = function() pcall(function() o[key] = oldVal end) queueObject(o) end,
        redo = function() pcall(function() o[key] = newVal end) queueObject(o) end,
    })
end

local function hTransform(player, o, fCf, fSize, fScale, tCf, tSize, tScale)
    local function apply(cf, sz, sc)
        if not o.Parent then return end
        pcall(function()
            setPivot(o, cf)
            if sz and o:IsA("BasePart") then o.Size = sz elseif sc and o.ClassName == "Model" then o:ScaleTo(sc) end
        end)
        queueObject(o)
    end
    pushHist(player, {
        label = "Transformar " .. o.Name,
        undo = function() apply(fCf, fSize, fScale) end,
        redo = function() apply(tCf, tSize, tScale) end,
    })
end

local function wipeWorkspace()
    for _, c in ipairs(workspace:GetChildren()) do
        if not rootSet[c] and editable(c) and not containsProtected(c) then pcall(function() c:Destroy() end) end
    end
end

local function buildTemplate(kind)
    wipeWorkspace()
    if kind == "Baseplate" or kind == "Flat" then
        local bp = Instance.new("Part")
        bp.Name = "Baseplate"
        bp.Size = Vector3.new(512, 1, 512)
        bp.CFrame = CFrame.new(0, -0.5, 0)
        bp.Anchored = true
        bp.CanCollide = true
        bp.Color = Color3.fromRGB(94, 142, 190)
        bp.Material = kind == "Flat" and Enum.Material.SmoothPlastic or Enum.Material.Concrete
        bp.Parent = workspace
        return bp
    end
    if kind == "Terrain" then
        local ok, t = pcall(function()
            local ter = Instance.new("Terrain")
            ter.Parent = workspace
            return ter
        end)
        if ok and t then return t end
    end
    return nil
end
local handlers={}function handlers.Hello(player)subscribed[player]=true return snapshot()end function handlers.Snapshot(player)subscribed[player]=true;return snapshot()end function handlers.Identify(_,payload)assert(typeof(payload.object)=="Instance"and inspectable(payload.object),"Objeto não disponível ao editor.")local o=payload.object;register(o);assert(idOf[o],"Limite de objetos da Hierarchy atingido.");local chain={};local p=o while p and inspectable(p)do register(p);chain[#chain+1]=record(p);p=p.Parent end return{id=idOf[o],nodes=chain}end function handlers.Select(player,payload)if not payload.id and payload.inst==nil then selected[player]=nil;return{}end pipeStats.selects=pipeStats.selects+1;local o if payload.inst~=nil then o=payload.inst assert(typeof(o)=="Instance"and idOf[o] and inspectable(o),"Instancia invalida ou nao registrada.")else o=getObject(payload.id)end;selected[player]=o return{properties=properties(o),node=record(o)}end function handlers.Catalog(_,payload)local parent=getObject(payload.parentId);local result={}for _,entry in ipairs(catalog)do local allowed,reason=canCreate(parent,entry)result[#result+1]={class=entry.class,category=entry.category,description=entry.description,aliases=entry.aliases,allowed=allowed,reason=allowed and""or reason}end return{items=result,parent=record(parent)}end function handlers.Create(player,payload)pipeStats.creates=pipeStats.creates+1;assert(type(payload.class)=="string"and#payload.class<60,"Classe inválida.")local o=create(player,getObject(payload.parentId),payload.class,payload.name)selected[player]=o hCreate(player,o) return{node=record(o),properties=properties(o)}end function handlers.Delete(player,payload) return handlers.Delete_(player,payload) end function handlers.Set(player,payload)assert(type(payload.key)=="string"and#payload.key<80,"Propriedade inválida.")local o=getObject(payload.id);assert(not conflictingLock(o),"Termine o arraste antes de editar este objeto/contêiner.")local arkOld=read(o,payload.key)setProperty(o,payload.key,payload.value)local arkNew=read(o,payload.key)if arkOld~=arkNew then hSet(player,o,payload.key,arkOld,arkNew)end return{node=record(o),properties=properties(o)}end function handlers.Begin(player,payload)release(player,true)local o=getObject(payload.id)assert(editable(o)and o:IsDescendantOf(workspace)and not containsProtected(o),"Selecione uma peça/Model no Workspace.")assert(payload.mode=="Move"or payload.mode=="Scale"or payload.mode=="Rotate","Ferramenta inválida.")assert(not conflictingLock(o),"Objeto ou descendente em edição por outro usuário.")local parts=allParts(o);assert(#parts>0,"Objeto sem peças manipuláveis.")for _,p in ipairs(parts)do assert(not p.Locked and not characterPart(p),"Peça bloqueada ou pertencente a um personagem.")end local token=Http:GenerateGUID(false)local t={object=o,token=token,mode=payload.mode,time=os.clock(),anchors={},cf=getPivot(o),size=o:IsA("BasePart")and o.Size or nil,scale=o.ClassName=="Model"and o:GetScale()or nil}transactions[player]=t;locks[o]=player for _,p in ipairs(parts)do t.anchors[p]=p.Anchored;p.Anchored=true end return{token=token}end function handlers.End(player,payload)local t=transactions[player];assert(t and t.token==payload.token,"Arraste expirado.")if payload.cancel then release(player,true);return{}end applyTransform(t,payload);local o=t.object;hTransform(player,o,t.cf,t.size,t.scale,getPivot(o),o:IsA("BasePart")and o.Size or nil,o.ClassName=="Model"and o:GetScale()or nil);release(player,false)return{properties=properties(o),node=record(o)}end function handlers.Close(player)subscribed[player]=nil;selected[player]=nil;release(player,true);return{}end 
function handlers.Undo(player)
    local h = hist[player]
    assert(h and #h.undo > 0, "Nada para desfazer.")
    local e = table.remove(h.undo)
    local ok, err = pcall(e.undo)
    table.insert(h.redo, e)
    if not ok then return { error = "Falha ao desfazer: " .. tostring(err) } end
    return { label = e.label }
end

function handlers.Redo(player)
    local h = hist[player]
    assert(h and #h.redo > 0, "Nada para refazer.")
    local e = table.remove(h.redo)
    local ok, err = pcall(e.redo)
    table.insert(h.undo, e)
    if not ok then return { error = "Falha ao refazer: " .. tostring(err) } end
    return { label = e.label }
end

-- ============ R3: TERRENO VOXEL REAL (workspace.Terrain de verdade) ============
local TERRAIN_MATS = { Air=true, Asphalt=true, Basalt=true, Brick=true, Cardboard=true, Carpet=true, CeramicTiles=true, Clay=true, Cobblestone=true, Concrete=true, CorrodedMetal=true, CrackedLava=true, DiamondPlate=true, Dirt=true, Fabric=true, Foil=true, Glacier=true, Glass=true, Granite=true, Grass=true, Ground=true, Ice=true, LeafyGrass=true, Limestone=true, Marble=true, Metal=true, Mud=true, Obsidian=true, PackedIce=true, Pavement=true, Pebble=true, Plastic=true, Plank=true, Rock=true, Rubber=true, Salt=true, Sand=true, Sandstone=true, Slate=true, SmoothPlastic=true, Snow=true, Wood=true, WoodPlanks=true, Water=true }
local function terrainOrFail()
	local ter = workspace:FindFirstChildOfClass("Terrain")
	assert(ter, "Sem Terrain no Workspace (File > Novo > Terrain).")
	return ter
end
local function terrainMat(name)
	assert(type(name) == "string" and TERRAIN_MATS[name], "Material de terreno invalido: " .. tostring(name))
	return Enum.Material[name]
end
local function terrainCenter(c, player)
	if c == "player" then
		local ch = player and player.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		assert(hrp, "Sem personagem (entre no Play com spawn).")
		local pp = hrp.Position
		return Vector3.new(pp.X, pp.Y + 3, pp.Z)
	end
	assert(type(c) == "table", "Centro invalido.")
	local x, y, z = tonumber(c.x), tonumber(c.y), tonumber(c.z)
	assert(x and y and z and finite(x) and finite(y) and finite(z), "Centro invalido.")
	assert(math.abs(x) <= 100000 and math.abs(y) <= 100000 and math.abs(z) <= 100000, "Centro fora do limite.")
	return Vector3.new(x, y, z)
end
function handlers.TerrainInfo(player)
	local ter = terrainOrFail()
	local cells = 0
	pcall(function() cells = ter:CountCells() end)
	local w = {}
	pcall(function()
		w.transparency = ter.WaterTransparency
		w.reflectance = ter.WaterReflectance
		w.waveSize = ter.WaterWaveSize
		w.waveSpeed = ter.WaterWaveSpeed
		local wc = ter.WaterColor
		w.color = { math.floor(wc.R * 255), math.floor(wc.G * 255), math.floor(wc.B * 255) }
	end)
	return { cells = cells, water = w, id = idOf[ter] }
end
function handlers.TerrainFill(player, payload)
	local shape = tostring(payload.shape or "ball")
	assert(shape == "ball" or shape == "block" or shape == "cylinder", "shape: ball, block ou cylinder.")
	local matName = (payload.op == "remove") and "Air" or payload.material
	local mat = terrainMat(matName)
	local ctr = terrainCenter(payload.center, player)
	local ter = terrainOrFail()
	if shape == "ball" then
		local r = tonumber(payload.radius) or 0
		assert(r >= 1 and r <= 128, "radius 1..128.")
		ter:FillBall(ctr, r, mat)
	elseif shape == "block" then
		local sz = payload.size or {}
		local x, y, z = tonumber(sz.x) or 0, tonumber(sz.y) or 0, tonumber(sz.z) or 0
		assert(x >= 1 and x <= 256 and y >= 1 and y <= 256 and z >= 1 and z <= 256, "size 1..256 por eixo.")
		ter:FillBlock(CFrame.new(ctr), Vector3.new(x, y, z), mat)
	else
		local h = tonumber(payload.height) or 0
		local r = tonumber(payload.radius) or 0
		assert(h >= 1 and h <= 256 and r >= 1 and r <= 128, "height 1..256, radius 1..128.")
		ter:FillCylinder(CFrame.new(ctr), h, r, mat)
	end
	return { msg = ("Terreno: %s %s aplicado."):format(shape, tostring(matName)) }
end
function handlers.TerrainClear(player)
	local ter = terrainOrFail()
	ter:Clear()
	return { msg = "Terreno limpo (voxels removidos)." }
end

-- ============ R5: SCRIPT STUDIO (Lua/Python/blocos/C# executam DE VERDADE) ============
-- Poder = command bar do Studio: roda como servidor, so p/ usuario autorizado.
local function execCode(code)
	if code:match("while%s+true%s+do") and not (code:find("task%.wait", 1, true) or code:find("wait%s*%(", 1)) then
		return { error = "Loop infinito sem espera (adicione task.wait)." }
	end
	local fn, err = loadstring(code, "[ArkherRun]")
	if not fn then return { error = "Sintaxe: " .. tostring(err) } end
	local ok2, res = pcall(fn)
	if not ok2 then return { error = "Execucao: " .. tostring(res) } end
	return { ret = (res == nil) and "nil" or tostring(res), msg = "Executado (saida no Output)." }
end
function handlers.ScriptRun(player, payload)
	local code = tostring(payload.code or "")
	assert(#code > 0 and #code < 20000, "Codigo vazio ou grande demais (20k).")
	return execCode(code)
end
local function pyToLua(src)
	local out, stack = {}, {}
	local function dedentTo(ind)
		while #stack > 0 and stack[#stack] >= ind do
			out[#out + 1] = string.rep("  ", #stack - 1) .. "end"
			table.remove(stack)
		end
	end
	for line in (src .. "\n"):gmatch("([^\n]*)\n") do
		local indent = #(line:match("^ *") or "")
		local t = line:match("^%s*(.-)%s*$")
		if t == "" then
			-- vazia: ignora
		elseif t:sub(1, 1) == "#" then
			out[#out + 1] = "--" .. t:sub(2)
		elseif t:match("^import%s") or t:match("^from%s") or t:match("^class%s") then
			return nil, "import/class nao suportado no V1 (use Lua)."
		elseif t:match("^elif%s") or t == "else:" then
			if #stack == 0 then return nil, "elif/else sem if." end
			table.remove(stack)
			local pre = string.rep("  ", #stack)
			if t == "else:" then out[#out + 1] = pre .. "else"
			else out[#out + 1] = pre .. "elseif " .. t:match("^elif%s+(.-):%s*$") .. " then" end
			stack[#stack + 1] = indent
		else
			dedentTo(indent)
			local pre = string.rep("  ", #stack)
			t = t:gsub("True", "true"):gsub("False", "false"):gsub("None", "nil")
			t = t:gsub("len%s*%(", "#("):gsub("str%s*%(", "tostring("):gsub("int%s*%(", "tonumber("):gsub("float%s*%(", "tonumber(")
			local fn, args = t:match("^def%s+([%a_][%w_]*)%s*%(([^)]*)%):%s*$")
			if fn then
				out[#out + 1] = pre .. "local function " .. fn .. "(" .. args .. ")"
				stack[#stack + 1] = indent
			else
				local v, r1, r2, r3 = t:match("^for%s+([%a_][%w_]*)%s+in%s+range%(([^,)]+),?([^,)]*),?([^)]*)%):%s*$")
				if v and r1 then
					r1 = r1:match("^%s*(.-)%s*$") r2 = (r2 or ""):match("^%s*(.-)%s*$") r3 = (r3 or ""):match("^%s*(.-)%s*$")
					local loop
					if r2 == "" then loop = ("for %s = 0, (%s) - 1 do"):format(v, r1)
					elseif r3 == "" then loop = ("for %s = %s, (%s) - 1 do"):format(v, r1, r2)
					else loop = ("for %s = %s, (%s) - 1, %s do"):format(v, r1, r2, r3) end
					out[#out + 1] = pre .. loop
					stack[#stack + 1] = indent
				else
					local w = t:match("^while%s+(.-):%s*$")
					local i = t:match("^if%s+(.-):%s*$")
					if w then out[#out + 1] = pre .. "while " .. w .. " do" stack[#stack + 1] = indent
					elseif i then out[#out + 1] = pre .. "if " .. i .. " then" stack[#stack + 1] = indent
					else
						local av, aop, ar = t:match("^([%a_][%w_.]*)%s*([%+%-%*/])=%s*(.+)$")
						if av then out[#out + 1] = pre .. av .. " = " .. av .. " " .. aop .. " (" .. ar .. ")"
						else out[#out + 1] = pre .. t end
					end
				end
			end
		end
	end
	dedentTo(-1)
	return table.concat(out, "\n")
end
function handlers.PyLua(player, payload)
	local code = tostring(payload.code or "")
	assert(#code > 0 and #code < 20000, "Codigo vazio ou grande demais (20k).")
	local lua, err = pyToLua(code)
	if not lua then return { error = tostring(err) } end
	local r = execCode(lua)
	r.lua = lua
	return r
end
local function csToLua(src)
	local out, stack = {}, {}
	for line in (src .. "\n"):gmatch("([^\n]*)\n") do
		local t = line:match("^%s*(.-)%s*$")
		if t == "" or t:match("^using%s") or t:match("^namespace%s") or t:match("^class%s") or t:match("static%s+void%s+Main") or t:match("^//") then
			-- pula estrutura
		elseif t == "{" then
			stack[#stack + 1] = false
		elseif t == "}" or t:match("^}%s*;?%s*$") then
			local was = table.remove(stack)
			if was then out[#out + 1] = string.rep("  ", #stack) .. "end" end
		elseif t:match("^}%s*else") then
			table.remove(stack)
			local pre = string.rep("  ", #stack)
			if t:find("{", 1, true) then stack[#stack + 1] = true end
			local ec = t:match("^}%s*else%s+if%s*%((.-)%)%s*{?%s*$")
			if ec then out[#out + 1] = pre .. "elseif " .. ec .. " then"
			else out[#out + 1] = pre .. "else" end
		else
			local pre = string.rep("  ", #stack)
			local w = t:match("Console%.WriteLine%s*%((.-)%)%s*;?%s*$")
			if w then out[#out + 1] = pre .. "print(" .. w .. ")"
			else
				local vt, vn, vv = t:match("^(%a+)%s+([%a_][%w_]*)%s*=%s*(.-);%s*$")
				local csTypes = { int = true, string = true, float = true, double = true, bool = true, var = true, long = true, char = true }
				if vt and vn and csTypes[vt] then
					vv = vv:gsub("true", "true"):gsub("false", "false"):gsub("null", "nil")
					out[#out + 1] = pre .. "local " .. vn .. " = " .. vv
				else
					local fv, fa, fop, fb = t:match("^for%s*%(%s*int%s+([%a_][%w_]*)%s*=%s*([^;]+);%s*%1%s*([<>=!]+)%s*([^;]+);%s*%1%+%+%s*%)%s*{?%s*$")
					if fv then
						local lim = "(" .. fb:match("^%s*(.-)%s*$") .. ")"
						if fop == "<" then lim = lim .. " - 1" end
						out[#out + 1] = pre .. ("for %s = %s, %s do"):format(fv, fa:match("^%s*(.-)%s*$"), lim)
						stack[#stack + 1] = true
					else
						local ic = t:match("^if%s*%((.-)%)%s*{?%s*$")
						local wc = t:match("^while%s*%((.-)%)%s*{?%s*$")
						if ic then out[#out + 1] = pre .. "if " .. ic .. " then" stack[#stack + 1] = true
						elseif wc then out[#out + 1] = pre .. "while " .. wc .. " do" stack[#stack + 1] = true
						else
							local r = t:match("^return%s+(.-);%s*$")
							if r then out[#out + 1] = pre .. "return " .. r
							else
								local av, aop, ar = t:match("^([%a_][%w_]*)%s*([%+%-%*/])=%s*(.-);%s*$")
								if av then out[#out + 1] = pre .. av .. " = " .. av .. " " .. aop .. " (" .. ar .. ")"
								else out[#out + 1] = pre .. t:gsub(";%s*$", "") end
							end
						end
					end
				end
			end
		end
	end
	while #stack > 0 do if table.remove(stack) then out[#out + 1] = "end" end end
	return table.concat(out, "\n")
end
function handlers.CsRun(player, payload)
	local code = tostring(payload.code or "")
	assert(#code > 0 and #code < 20000, "Codigo vazio ou grande demais (20k).")
	local r = execCode(csToLua(code))
	r.lua = csToLua(code)
	return r
end
local function blockGen(nodes, depth)
	depth = depth or 0
	local pre = string.rep("  ", depth)
	local out = {}
	for _, n in ipairs(nodes or {}) do
		if n.op == "print" then
			local tx = tostring(n.text or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
			out[#out + 1] = pre .. 'print("' .. tx .. '")'
		elseif n.op == "wait" then
			out[#out + 1] = pre .. "task.wait(" .. (tonumber(n.n) or 1) .. ")"
		elseif n.op == "lua" then
			out[#out + 1] = pre .. tostring(n.code or "")
		elseif n.op == "repeat" then
			out[#out + 1] = pre .. "for _bx = 1, " .. (tonumber(n.n) or 1) .. " do"
				for _, l in ipairs(blockGen(n.body or {}, depth + 1)) do out[#out + 1] = l end
				out[#out + 1] = pre .. "end"
		end
	end
	return out
end
function handlers.BlockRun(player, payload)
	assert(type(payload.nodes) == "table" and #payload.nodes <= 200, "Blocos invalidos (max 200).")
	local lua = table.concat(blockGen(payload.nodes, 0), "\n")
	local r = execCode(lua)
	r.lua = lua
	return r
end
function handlers.ScriptGet(player, payload)
	local o = getObject(payload.id)
	assert(o:IsA("LuaSourceContainer"), "Nao e Script.")
	local ok, src = pcall(function() return o.Source end)
	if not ok then return { error = "Source ilegivel aqui (leia no Studio)." } end
	return { source = src or "", className = o.ClassName, name = o.Name }
end
function handlers.ScriptSet(player, payload)
	local o = getObject(payload.id)
	assert(o:IsA("LuaSourceContainer"), "Nao e Script.")
	assert(editable(o), "Protegido.")
	local src = tostring(payload.source or "")
	assert(#src < 200000, "Grande demais.")
	local ok, err = pcall(function() o.Source = src end)
	if not ok then return { error = "Roblox recusou gravar Source aqui (edite no Studio). Rode ou salve na nuvem." } end
	queueObject(o)
	return { msg = "Source gravado.", len = #src }
end

-- ============ R5: TERRENO 2 (agua/troca/flat) ============
function handlers.TerrainWater(player, payload)
	local y = tonumber(payload.y) or 10
	local xz = tonumber(payload.xz) or 512
	assert(y >= -100 and y <= 1000, "y -100..1000.")
	assert(xz >= 16 and xz <= 2048, "xz 16..2048.")
	local ter = terrainOrFail()
	ter:FillBlock(CFrame.new(0, y, 0), Vector3.new(xz, 8, xz), Enum.Material.Water)
	return { msg = ("Agua em y=%s (%sx%s)."):format(tostring(y), tostring(xz), tostring(xz)) }
end
function handlers.TerrainReplace(player, payload)
	local ctr = terrainCenter(payload.center, player)
	local r = tonumber(payload.radius) or 32
	assert(r >= 4 and r <= 256, "radius 4..256.")
	local fromM = terrainMat(payload.from)
	local toM = terrainMat(payload.to)
	local ter = terrainOrFail()
	local r3 = Region3.new(Vector3.new(ctr.X - r, ctr.Y - r, ctr.Z - r), Vector3.new(ctr.X + r, ctr.Y + r, ctr.Z + r)):ExpandToGrid(4)
	ter:ReplaceMaterial(r3, 4, fromM, toM)
	return { msg = ("Troca %s->%s num cubo r=%s."):format(tostring(payload.from), tostring(payload.to), tostring(r)) }
end
function handlers.TerrainGenFlat(player, payload)
	local sz = tonumber(payload.size) or 512
	assert(sz >= 32 and sz <= 1024, "size 32..1024.")
	local mat = terrainMat(payload.material or "Grass")
	local ter = terrainOrFail()
	local r3 = Region3.new(Vector3.new(-sz / 2, 0, -sz / 2), Vector3.new(sz / 2, 8, sz / 2)):ExpandToGrid(4)
	ter:FillRegion(r3, 4, mat)
	if payload.water then ter:FillBlock(CFrame.new(0, 10, 0), Vector3.new(sz, 4, sz), Enum.Material.Water) end
	return { msg = "Flat gerado (" .. tostring(sz) .. "x" .. tostring(sz) .. ")." }
end

-- ============ R6: ANIMACAO (pose real em qualquer peca) ============
local ANIM = {}
function handlers.AnimKey(player, payload)
	local o = getObject(payload.id)
	assert(o:IsA("BasePart") or o.ClassName == "Model", "Pose exige Part/Model.")
	local slot = tostring(payload.slot or "A")
	assert(slot == "A" or slot == "B", "slot A ou B.")
	ANIM[player] = ANIM[player] or {}
	ANIM[player][slot] = { cf = getPivot(o), size = o:IsA("BasePart") and o.Size or nil, id = payload.id }
	return { msg = ("Pose %s gravada (%s)."):format(slot, o.Name) }
end
function handlers.AnimGo(player, payload)
	local o = getObject(payload.id)
	local slot = tostring(payload.slot or "A")
	local key = ANIM[player] and ANIM[player][slot]
	assert(key, "Grave a pose " .. slot .. " antes (AnimKey).")
	local dur = tonumber(payload.dur) or 0
	assert(dur >= 0 and dur <= 30, "dur 0..30s.")
	local fromCf = getPivot(o)
	local fromSize = o:IsA("BasePart") and o.Size or nil
	ANIM[player].stop = false
	if dur <= 0 then
		pcall(function() setPivot(o, key.cf) end)
		if key.size and o:IsA("BasePart") then pcall(function() o.Size = key.size end) end
		pcall(function() hTransform(player, o, fromCf, fromSize, nil, key.cf, key.size, nil) end)
		pcall(function() queueObject(o) end)
		return { msg = "Pose aplicada (instantâneo)." }
	end
	local steps = math.max(1, math.min(100, math.floor(dur * 20)))
	local me = player
	task.spawn(function()
		for i = 1, steps do
			if not (ANIM[me]) or ANIM[me].stop then return end
			if not o.Parent then return end
			local a = i / steps
			pcall(function() setPivot(o, fromCf:Lerp(key.cf, a)) end)
			task.wait(dur / steps)
		end
		if o.Parent and ANIM[me] and not ANIM[me].stop then
			pcall(function() setPivot(o, key.cf) end)
			pcall(function() hTransform(player, o, fromCf, fromSize, nil, key.cf, key.size, nil) end)
			pcall(function() queueObject(o) end)
		end
	end)
	return { msg = ("Tocando pose %s em %ss."):format(slot, tostring(dur)) }
end
function handlers.AnimStop(player, payload)
	if ANIM[player] then ANIM[player].stop = true end
	return { msg = "Animação parada." }
end

function handlers.PipeStats(player)
	local sel2 = selected[player]
	return { deltaFlush = pipeStats.deltaFlush, deltaNodes = pipeStats.deltaNodes, propsPush = pipeStats.propsPush, selRemoved = pipeStats.selRemoved, selects = pipeStats.selects, creates = pipeStats.creates, skippedCap = pipeStats.skippedCap, skippedParent = pipeStats.skippedParent, nodeCount = nodeCount, maxNodes = CONFIG.MAX_NODES, subscribed = subscribed[player] == true, selectedId = (sel2 ~= nil) and idOf[sel2] or nil }
end

function handlers.GetHistory(player)
    local h = hist[player] or { undo = {}, redo = {} }
    local u = {}
    for i = 1, #h.undo do u[#u + 1] = h.undo[i].label end
    local r = {}
    for i = 1, #h.redo do r[#r + 1] = h.redo[i].label end
    return { undo = u, redo = r, canUndo = #h.undo > 0, canRedo = #h.redo > 0 }
end

function handlers.Copy(player, payload)
    local o = getObject(payload.id)
    assert(inspectable(o), "Objeto indisponível.")
    local clone = o:Clone()
    if clip[player] then pcall(function() clip[player].inst:Destroy() end) end
    clip[player] = { inst = clone, label = o.Name }
    return { label = o.Name, count = #(o:GetDescendants()) + 1 }
end

function handlers.Delete_(player, payload)
    local o = getObject(payload.id)
    assert(editable(o) and not rootSet[o] and not containsProtected(o), "Este objeto não pode ser excluído.")
    assert(not conflictingLock(o, player), "Objeto ou descendente em edição por outro usuário.")
    release(player, true)
    local id = idOf[o]
    hDelete(player, o)
    o:Destroy()
    unregister(o)
    selected[player] = nil
    return { removed = id }
end

function handlers.Cut(player, payload)
    handlers.Copy(player, payload)
    return handlers.Delete_(player, payload)
end

function handlers.Paste(player, payload)
    local cb = clip[player]
    assert(cb, "Nada para colar. Use Copiar ou Duplicar antes.")
    local parent = workspace
    if payload.parentId and objects[payload.parentId] then parent = objects[payload.parentId] end
    if not (parent == workspace or parent:IsA("Folder") or parent.ClassName == "Model" or parent:IsA("BasePart") or parent:IsA("GuiObject") or parent:IsA("LayerCollector")) then
        parent = workspace
    end
    local inst = cb.inst:Clone()
    local base = inst.Name
    local unique, index = base, 1
    while parent:FindFirstChild(unique) do unique = base .. " " .. index; index = index + 1 end
    inst.Name = unique
    created[player] = (created[player] or 0) + 1
    inst.Parent = parent
    register(inst)
    selected[player] = inst
    hCreate(player, inst)
    return { node = record(inst), properties = properties(inst), parentId = idOf[parent] }
end

function handlers.Duplicate(player, payload)
    handlers.Copy(player, payload)
    return handlers.Paste(player, payload)
end

function handlers.Rename(player, payload)
    local o = getObject(payload.id)
    assert(editable(o) and not rootSet[o], "Objeto somente leitura.")
    assert(type(payload.name) == "string" and #payload.name > 0 and #payload.name <= 100 and not payload.name:match("^%s*$"), "Nome inválido.")
    local old = o.Name
    o.Name = payload.name
    queueObject(o)
    pushHist(player, {
        label = "Renomear " .. old .. " → " .. o.Name,
        undo = function() o.Name = old; queueObject(o) end,
        redo = function() o.Name = payload.name; queueObject(o) end,
    })
    return { node = record(o) }
end

function handlers.New(player)
    release(player, true)
    wipeWorkspace()
    clearHist(player)
    if clip[player] then pcall(function() clip[player].inst:Destroy() end) clip[player] = nil end
    local bp = buildTemplate("Baseplate")
    if bp then register(bp) end
    return { message = "Projeto novo criado." }
end

function handlers.Open(player, payload)
    release(player, true)
    local kind = payload.template or "Baseplate"
    assert(kind == "Empty" or kind == "Baseplate" or kind == "Flat" or kind == "Terrain", "Template inválido.")
    clearHist(player)
    local root = buildTemplate(kind)
    if root then register(root) end
    return { message = "Template aplicado: " .. kind }
end

function handlers.Export(player)
    local data = serializeTree(workspace)
    return { data = data, nodes = countTree(data) }
end

function handlers.Import(player, payload)
    assert(type(payload.data) == "table" and type(payload.data.c) == "string", "Dados de importação inválidos.")
    local n = countTree(payload.data)
    assert(n <= CONFIG.MAX_CREATED_PER_SESSION, "Importação excede o limite de objetos.")
    local root = deserializeTree(workspace, payload.data)
    register(root)
    selected[player] = root
    return { created = n, root = record(root) }
end


-- ============ ARKHER SERVICES (custom: cloud, publicar, dados, i18n, toolbox, colaboracao) ============
-- Camada "custom" que contorna a Cloud API / Open API reais: persiste no place (ServerStorage)
-- como vault, e "publica" o jogo no perfil do dev (cartao estilo pagina do jogo do Roblox).
local _SS = game:GetService("ServerStorage")
local services = nil
local servicesError = ""
do
	-- FIX (round 10): NADA de escrever Source em runtime (isso é level
	-- PluginOrOpenCloud e berrava "cannot write 'Source'" TODA HORA).
	-- O module agora é EMBUTIDO INLINE como função — roda direto, sem require.
	local vault = _SS:FindFirstChild("ArkherCloudVault")
	if not vault then vault = Instance.new("Folder") vault.Name = "ArkherCloudVault" vault.Parent = _SS end
	vault:SetAttribute("ArkherInternal", true)
	local okMod, mod = pcall(function()
		return (function()
-- ARKHER Services (ModuleScript) — camada CUSTOM de persistência + dados.
-- Roda no server (ServerStorage/ArkherCloudVault/ArkherServices). Não usa require externo;
-- só services globais. Todo dado aninhado vai em atributo STRING (JSON) p/ persistir no place.
local Http = game:GetService("HttpService")
local pyGet, pyPost -- forward: PublishReal/AccountPlaces/Py* usam antes do BLOCK_X9
local SS = game:GetService("ServerStorage")
local VAULT = "ArkherCloudVault"

local M = {}
M.SCHEMA = 1

-- ============ util ============
local function enc(v)
	local ok, s = pcall(function() return Http:JSONEncode(v) end)
	if ok and type(s) == "string" then return s end
	return "null"
end
local function dec(s)
	if type(s) ~= "string" or s == "" then return nil end
	local ok, t = pcall(function() return Http:JSONDecode(s) end)
	if ok and type(t) == "table" then return t end
	return nil
end
local function now() return os.time() end
local function dstr(t) return os.date("!%Y-%m-%d %H:%M", t or now()) end
local _seed = (os.time() % 2147483646) + 1
local _ctr = 0
local function genNum()
	local n = (_seed + _ctr) % 2147483647
	_ctr = _ctr + 1
	local out = ""
	for _ = 1, 9 do n = (n * 16807) % 2147483647 out = out .. tostring(n % 10) end
	return out
end

local vault
local function getVault()
	if vault and vault.Parent then return vault end
	vault = SS:FindFirstChild(VAULT)
	if not vault then vault = Instance.new("Folder") vault.Name = VAULT vault.Parent = SS end
	vault:SetAttribute("ArkherInternal", true)
	vault:SetAttribute("ArkherSchema", M.SCHEMA)
	local subs = { "Account", "Cloud", "Profile", "Team", "ProjectInfo", "Data", "Locales" }
	for _, n in ipairs(subs) do
		local f = vault:FindFirstChild(n)
		if not f then f = Instance.new("Folder") f.Name = n f.Parent = vault end
		f:SetAttribute("ArkherInternal", true)
	end
	local team = vault:FindFirstChild("Team")
	if not team:FindFirstChild("Invites") then local iv = Instance.new("Folder") iv.Name = "Invites" iv.Parent = team end
	return vault
end

local function owner()
	local acc = getVault():FindFirstChild("Account")
	return acc:GetAttribute("OwnerName") or "Dev"
end

local function ensureAccount()
	local v = getVault()
	local acc = v:FindFirstChild("Account")
	if not acc:GetAttribute("OwnerName") then
		acc:SetAttribute("OwnerName", "WhiteXz73_Developer")
		acc:SetAttribute("OwnerId", 1)
		acc:SetAttribute("Plan", "Creator Plus")
		acc:SetAttribute("CreatedAt", now())
	end
	local team = v:FindFirstChild("Team")
	if not team:GetAttribute("Members") then
		team:SetAttribute("Members", enc({ { name = owner(), role = "Owner", joinedAt = now(), online = true } }))
	end
end
ensureAccount()

-- ============ CONTA / STATUS ============
local DS_IDX = "arkher_cloud_idx_v1"
local dsState = { ok = false, msg = "" }
-- ============ ARKHER CLOUD DURAVEL (DataStore mirror; estado acima) ============
local function dsStore()
	local ok, svc = pcall(function() return game:GetService("DataStoreService") end)
	if not ok or not svc then return nil end
	local ok2, st = pcall(function() return svc:GetDataStore("arkher_cloud_v1") end)
	if not ok2 then dsState.msg = tostring(st):sub(1, 120) return nil end
	dsState.ok = true
	return st
end
local function dsIdxRead(st)
	local ok, v = pcall(function() return st:GetAsync(DS_IDX) end)
	if ok and type(v) == "table" then return v end
	return {}
end
local function dsMirrorPut(st, rec, json)
	pcall(function() st:SetAsync("arkher_proj_" .. tostring(rec.id), { rec = rec, snapshot = json }) end)
	local idx = dsIdxRead(st)
	local out, seen = {}, {}
	out[#out + 1] = rec seen[rec.id] = true
	for _, r in ipairs(idx) do
		if type(r) == "table" and r.id and not seen[r.id] then seen[r.id] = true out[#out + 1] = r end
		if #out >= 50 then break end
	end
	pcall(function() st:SetAsync(DS_IDX, out) end)
end
local function dsListMissing(vault)
	local have = {}
	for _, r in ipairs(vault) do if type(r) == "table" and r.id then have[r.id] = true end end
	local st = dsStore()
	if not st then return {} end
	local out = {}
	for _, r in ipairs(dsIdxRead(st)) do
		if type(r) == "table" and r.id and not have[r.id] then
			r.src = "ds" out[#out + 1] = r
		end
	end
	return out
end
local function dsSnapGet(id)
	local st = dsStore()
	if not st then return nil end
	local ok, v = pcall(function() return st:GetAsync("arkher_proj_" .. tostring(id)) end)
	if ok and type(v) == "table" and type(v.snapshot) == "string" then
		return { data = v.snapshot, record = v.rec or { id = id } }
	end
	return nil
end
local function dsDel(id)
	local st = dsStore()
	if not st then return false end
	pcall(function() st:RemoveAsync("arkher_proj_" .. tostring(id)) end)
	local idx = dsIdxRead(st)
	local out = {}
	for _, r in ipairs(idx) do if not (type(r) == "table" and tostring(r.id) == tostring(id)) then out[#out + 1] = r end end
	pcall(function() st:SetAsync(DS_IDX, out) end)
	return true
end
function M.status()
	local acc = getVault():FindFirstChild("Account")
	return {
		ready = true,
		owner = owner(),
		ownerId = acc:GetAttribute("OwnerId") or 0,
		plan = acc:GetAttribute("Plan") or "Creator",
		region = "sa-east-1",
		createdAt = dstr(acc:GetAttribute("CreatedAt")),
		projects = #M.cloudList(),
		published = #M.profileList(),
		members = #M.team().members,
		ds = dsState.ok,
		backend = dsState.ok and "vault+datastore" or "vault",
	}
end

-- ============ ARKHER CLOUD (projetos) ============
local function projRecord(p)
	return {
		id = p.Name:sub(6),
		name = p:GetAttribute("Name") or p.Name,
		size = p:GetAttribute("Size") or 0,
		nodes = p:GetAttribute("Nodes") or 0,
		savedAt = dstr(p:GetAttribute("SavedAt")),
		versions = p:GetAttribute("Versions") or 1,
	}
end
function M.cloudList()
	local cloud = getVault():FindFirstChild("Cloud")
	local out = {}
	for _, p in ipairs(cloud:GetChildren()) do
		if p:IsA("Folder") and p.Name:sub(1, 5) == "proj_" then out[#out + 1] = projRecord(p) end
	end
	for _, r in ipairs(dsListMissing(out)) do out[#out + 1] = r end
	table.sort(out, function(a, b) return (b.savedAt or "") > (a.savedAt or "") end)
	return out
end
function M.cloudPut(name, json, size, nodes)
	local cloud = getVault():FindFirstChild("Cloud")
	local id = "proj_" .. genNum()
	local p = Instance.new("Folder")
	p.Name = id
	p:SetAttribute("ArkherInternal", true)
	p:SetAttribute("Name", name)
	p:SetAttribute("Size", size)
	p:SetAttribute("Nodes", nodes)
	p:SetAttribute("SavedAt", now())
	p:SetAttribute("Versions", 1)
	local snap = Instance.new("StringValue")
	snap.Name = "Snapshot"
	snap.Value = json
	snap.Parent = p
	p.Parent = cloud
	local rec = projRecord(p)
	pcall(function() local st = dsStore() if st then dsMirrorPut(st, rec, json) end end)
	return rec
end
function M.cloudGet(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then local got = dsSnapGet(id) if got then return got end return nil end
	local snap = p:FindFirstChild("Snapshot")
	return { data = snap and snap.Value or "", record = projRecord(p) }
end
function M.cloudDelete(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then return dsDel(id) end
	p:Destroy()
	pcall(function() dsDel(id) end)
	return true
end

-- ============ PUBLICAR (perfil do dev) ============
local function gameRecord(g)
	return {
		id = g.Name:sub(6),
		title = g:GetAttribute("Title") or g.Name,
		slug = g:GetAttribute("Slug") or "",
		url = g:GetAttribute("Url") or "",
		visits = g:GetAttribute("Visits") or 0,
		favorites = g:GetAttribute("Favorites") or 0,
		version = g:GetAttribute("Version") or 1,
		createdAt = dstr(g:GetAttribute("CreatedAt")),
		updatedAt = dstr(g:GetAttribute("UpdatedAt")),
		visibility = g:GetAttribute("Visibility") or "Public",
		genre = g:GetAttribute("Genre") or "Obstrução",
		publishedBy = g:GetAttribute("PublishedBy") or owner(),
		rating = g:GetAttribute("Rating") or 100,
	}
end
function M.profileList()
	local prof = getVault():FindFirstChild("Profile")
	local out = {}
	for _, g in ipairs(prof:GetChildren()) do
		if g:IsA("Folder") and g.Name:sub(1, 5) == "game_" then out[#out + 1] = gameRecord(g) end
	end
	table.sort(out, function(a, b) return (b.updatedAt or "") > (a.updatedAt or "") end)
	return out
end
function M.profileGet(id)
	local g = getVault():FindFirstChild("Profile"):FindFirstChild("game_" .. id)
	if not g then return nil end
	local d = g:FindFirstChild("Description")
	local r = gameRecord(g)
	r.description = d and d.Value or ""
	return r
end
function M.publish(info)
	info = info or {}
	local prof = getVault():FindFirstChild("Profile")
	local title = type(info.title) == "string" and info.title or "Meu Jogo Arkher"
	if title:match("^%s*$") then title = "Meu Jogo Arkher" end
	local slug = title:lower():gsub("[^%w]", "-"):gsub("^-+", ""):gsub("-+$", "")
	if slug == "" then slug = "jogo" end
	-- acha um game existente com o mesmo slug (re-publicar = bump versão)
	local existing
	for _, g in ipairs(prof:GetChildren()) do
		if g:IsA("Folder") and g:GetAttribute("Slug") == slug then existing = g break end
	end
	local g = existing
	if not g then
		local gid = genNum()
		g = Instance.new("Folder")
		g.Name = "game_" .. gid
		g:SetAttribute("ArkherInternal", true)
		g:SetAttribute("Title", title)
		g:SetAttribute("Slug", slug)
		g:SetAttribute("GameId", gid)
		g:SetAttribute("Url", "https://www.roblox.com/games/" .. gid .. "/" .. slug)
		g:SetAttribute("CreatedAt", now())
		g:SetAttribute("Visits", 1)
		g:SetAttribute("Favorites", 0)
		g:SetAttribute("Version", 1)
		g:SetAttribute("Rating", 100)
		g:SetAttribute("Visibility", "Public")
		g:SetAttribute("Genre", "Obstrução")
		g.Parent = prof
	else
		local ver = (g:GetAttribute("Version") or 1) + 1
		g:SetAttribute("Version", ver)
		g:SetAttribute("Visits", (g:GetAttribute("Visits") or 0) + 1)
		g:SetAttribute("Title", title)
		local gid = g:GetAttribute("GameId")
		g:SetAttribute("Url", "https://www.roblox.com/games/" .. gid .. "/" .. slug)
	end
	g:SetAttribute("UpdatedAt", now())
	g:SetAttribute("PublishedBy", owner())
	if info.visibility == "Private" or info.visibility == "Unlisted" or info.visibility == "Public" then
		g:SetAttribute("Visibility", info.visibility)
	end
	if type(info.genre) == "string" and info.genre ~= "" then
		g:SetAttribute("Genre", info.genre)
	end
	if type(info.description) == "string" then
		local d = g:FindFirstChild("Description")
		if not d then d = Instance.new("StringValue") d.Name = "Description" d.Parent = g end
		d.Value = info.description
	end
	return gameRecord(g)
end
function M.profileDelete(id)
	local g = getVault():FindFirstChild("Profile"):FindFirstChild("game_" .. id)
	if not g then return false end
	g:Destroy()
	return true
end

-- ============ DADOS (custom DataStore) ============
local function dataEntry(key)
	local data = getVault():FindFirstChild("Data")
	local e = data:FindFirstChild(key)
	if not e then return nil end
	local vt = e:GetAttribute("Type") or "string"
	local val = e:GetAttribute("Value")
	return { key = key, type = vt, value = val, updatedAt = dstr(e:GetAttribute("UpdatedAt")) }
end
function M.dataList()
	local data = getVault():FindFirstChild("Data")
	local out = {}
	for _, e in ipairs(data:GetChildren()) do out[#out + 1] = dataEntry(e.Name) end
	return out
end
function M.dataSet(key, value, vt)
	assert(type(key) == "string" and #key > 0 and #key <= 60, "Chave inválida.")
	assert(not key:match("[/%?%*%:<>%|%\"\\]"), "Chave com caractere inválido.")
	vt = vt or (type(value) == "number" and "number" or (type(value) == "boolean" and "boolean" or "string"))
	assert(vt == "string" or vt == "number" or vt == "boolean", "Tipo inválido.")
	if vt == "number" then value = tonumber(value); assert(value, "Número inválido.") end
	if vt == "boolean" then value = value == true end
	if vt == "string" then value = tostring(value) assert(#value <= 4000, "Valor muito longo.") end
	local data = getVault():FindFirstChild("Data")
	local e = data:FindFirstChild(key)
	if not e then e = Instance.new("Folder") e.Name = key e:SetAttribute("ArkherInternal", true) e.Parent = data end
	e:SetAttribute("Type", vt)
	e:SetAttribute("Value", value)
	e:SetAttribute("UpdatedAt", now())
	return dataEntry(key)
end
function M.dataGet(key)
	return dataEntry(key)
end
function M.dataDelete(key)
	local e = getVault():FindFirstChild("Data"):FindFirstChild(key)
	if not e then return false end
	e:Destroy()
	return true
end

-- ============ PROJETO (metadados) ============
local INFO_FIELDS = { "GameName", "Description", "Genre", "Visibility", "MaxPlayers", "StreamingEnabled", "PhysicsEnabled" }
function M.projectInfo()
	local pi = getVault():FindFirstChild("ProjectInfo")
	local out = {}
	for _, f in ipairs(INFO_FIELDS) do
		local v = pi:GetAttribute(f)
		if v ~= nil then out[f] = v end
	end
	if not out.GameName then out.GameName = "" end
	out.Visibility = out.Visibility or "Public"
	out.Genre = out.Genre or "Obstrução"
	out.MaxPlayers = out.MaxPlayers or 50
	return out
end
function M.setProjectInfo(fields)
	fields = fields or {}
	local pi = getVault():FindFirstChild("ProjectInfo")
	local changed = {}
	for _, f in ipairs(INFO_FIELDS) do
		local v = fields[f]
		if v ~= nil then
			if f == "GameName" or f == "Description" or f == "Genre" then v = tostring(v) end
			if f == "MaxPlayers" then v = math.clamp(math.floor(tonumber(v) or 50), 1, 1000) end
			if f == "StreamingEnabled" or f == "PhysicsEnabled" then v = v == true end
			pi:SetAttribute(f, v)
			changed[f] = v
		end
	end
	return M.projectInfo()
end

-- ============ COLABORAÇÃO (equipe + convites) ============
local ROLES = { Owner = true, Editor = true, Viewer = true }
function M.team()
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	local me = owner()
	if #members == 0 then
		members = { { name = me, role = "Owner", joinedAt = now(), online = true } }
		team:SetAttribute("Members", enc(members))
	end
	return { members = members, owner = me, count = #members }
end
function M.teamAdd(name, role)
	if not ROLES[role] or role == "Owner" then role = "Editor" end
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	for _, m in ipairs(members) do if m.name == name then return M.team() end end
	members[#members + 1] = { name = tostring(name), role = role, joinedAt = now(), online = true }
	team:SetAttribute("Members", enc(members))
	return M.team()
end
function M.teamRemove(name)
	local team = getVault():FindFirstChild("Team")
	local members = dec(team:GetAttribute("Members")) or {}
	local out = {}
	for _, m in ipairs(members) do
		if m.name == name then
			if m.role == "Owner" then return M.team() end
		else out[#out + 1] = m end
	end
	team:SetAttribute("Members", enc(out))
	return M.team()
end
function M.inviteList()
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	local out = {}
	for _, e in ipairs(iv:GetChildren()) do
		out[#out + 1] = {
			code = e:GetAttribute("Code") or "",
			email = e:GetAttribute("Email") or "",
			role = e:GetAttribute("Role") or "Editor",
			status = e:GetAttribute("Status") or "pending",
			by = e:GetAttribute("By") or owner(),
			createdAt = dstr(e:GetAttribute("CreatedAt")),
			link = "arkher.dev/j/" .. (e:GetAttribute("Code") or ""),
		}
	end
	return out
end
function M.inviteCreate(email, role)
	if not ROLES[role] or role == "Owner" then role = "Editor" end
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	local code = genNum():sub(1, 8):upper()
	local e = Instance.new("Folder")
	e.Name = "inv_" .. os.time() .. "_" .. code
	e:SetAttribute("ArkherInternal", true)
	e:SetAttribute("Code", code)
	e:SetAttribute("Email", tostring(email))
	e:SetAttribute("Role", role)
	e:SetAttribute("Status", "pending")
	e:SetAttribute("By", owner())
	e:SetAttribute("CreatedAt", now())
	e.Parent = iv
	return { code = code, role = role, email = email, link = "arkher.dev/j/" .. code }
end
local function findInvite(code)
	local iv = getVault():FindFirstChild("Team"):FindFirstChild("Invites")
	for _, e in ipairs(iv:GetChildren()) do
		if (e:GetAttribute("Code") or "") == code then return e end
	end
	return nil
end
function M.inviteAccept(code)
	local e = findInvite(code)
	if not e then return { error = "Convite não encontrado." } end
	local email = e:GetAttribute("Email")
	local name = email and email:match("^(%S+)@") or "Convidado"
	local role = e:GetAttribute("Role") or "Editor"
	e:SetAttribute("Status", "accepted")
	local t = M.teamAdd(name, role)
	return { ok = true, member = name, team = t }
end
function M.inviteReject(code)
	local e = findInvite(code)
	if not e then return { error = "Convite não encontrado." } end
	e:SetAttribute("Status", "rejected")
	return { ok = true }
end

-- ============ LOCALIZAÇÃO (i18n) ============
local LOCALES = {
	{ code = "pt-BR", name = "Português (Brasil)" },
	{ code = "en", name = "English" },
	{ code = "es", name = "Español" },
	{ code = "fr", name = "Français" },
	{ code = "de", name = "Deutsch" },
	{ code = "ja", name = "日本語" },
}
function M.locales()
	local loc = getVault():FindFirstChild("Locales")
	local cur = loc:GetAttribute("Current") or "pt-BR"
	return { current = cur, available = LOCALES }
end
function M.setLocale(code)
	local ok = false
	for _, l in ipairs(LOCALES) do if l.code == code then ok = true break end end
	assert(ok, "Idioma inválido.")
	local loc = getVault():FindFirstChild("Locales")
	loc:SetAttribute("Current", code)
	return M.locales()
end
function M.strings()
	local loc = getVault():FindFirstChild("Locales")
	local list = dec(loc:GetAttribute("Strings")) or {}
	if #list == 0 then
		list = {
			{ key = "Greeting", value = "Bem-vindo ao jogo!", translations = { ["pt-BR"] = "Bem-vindo ao jogo!", en = "Welcome to the game!", es = "¡Bienvenido al juego!" } },
			{ key = "PlayButton", value = "Jogar", translations = { ["pt-BR"] = "Jogar", en = "Play", es = "Jugar" } },
			{ key = "GameOver", value = "Fim de jogo", translations = { ["pt-BR"] = "Fim de jogo", en = "Game over", es = "Fin del juego" } },
		}
		loc:SetAttribute("Strings", enc(list))
	end
	local cur = loc:GetAttribute("Current") or "pt-BR"
	for _, s in ipairs(list) do s.resolved = (s.translations and s.translations[cur]) or s.value end
	return { strings = list, current = cur }
end
function M.setString(key, value, translations)
	assert(type(key) == "string" and #key > 0 and #key <= 80, "Chave inválida.")
	local loc = getVault():FindFirstChild("Locales")
	local list = dec(loc:GetAttribute("Strings")) or {}
	local found = false
	for _, s in ipairs(list) do
		if s.key == key then
			s.value = tostring(value)
			if type(translations) == "table" then for k, v in pairs(translations) do s.translations[k] = tostring(v) end end
			found = true
		end
	end
	if not found then
		local tr = {}
		tr["pt-BR"] = tostring(value)
		if type(translations) == "table" then for k, v in pairs(translations) do tr[k] = tostring(v) end end
		list[#list + 1] = { key = key, value = tostring(value), translations = tr }
	end
	loc:SetAttribute("Strings", enc(list))
	return M.strings()
end

-- ============ TOOLBOX (biblioteca de templates) ============
local TOOLBOX = {
	category = "Geometria",
	items = {
		{ id = "tb_platform", name = "Plataforma", description = "Plataforma 8x0.5x8.", icon = "Part", nodes = { { class = "Part", name = "Plataforma", size = { 8, 0.5, 8 }, color = { 120, 160, 220 }, pos = { 0, 0, 0 } } } },
		{ id = "tb_wall", name = "Muralha", description = "Parede 12x6x0.5.", icon = "Part", nodes = { { class = "Part", name = "Muralha", size = { 12, 6, 0.5 }, color = { 90, 95, 110 }, pos = { 0, 3, 0 } } } },
		{ id = "tb_bridge", name = "Ponte", description = "Duas torres + tábua.", icon = "Model", nodes = { { class = "Model", name = "Ponte", pos = { 0, 0, 0 } }, { class = "Part", name = "TorreEsq", size = { 1, 4, 1 }, color = { 200, 180, 90 }, pos = { -4, 2, 0 } }, { class = "Part", name = "TorreDir", size = { 1, 4, 1 }, color = { 200, 180, 90 }, pos = { 4, 2, 0 } }, { class = "Part", name = "Tabua", size = { 9, 0.3, 2 }, color = { 150, 110, 70 }, pos = { 0, 4, 0 } } } },
	},
}
local TOOLBOX_LIST = {
	TOOLBOX,
	{
		category = "Iluminação",
		items = {
			{ id = "tb_spot", name = "Palco com luz", description = "Palco + SpotLight.", icon = "Stage", nodes = { { class = "Part", name = "Palco", size = { 10, 0.5, 10 }, color = { 40, 44, 60 }, pos = { 0, 0, 0 } }, { class = "SpotLight", name = "Luz", pos = { 0, 6, 0 } } } },
			{ id = "tb_point", name = "Luz pontual", description = "Ponto com luz laranja.", icon = "Stage", nodes = { { class = "Part", name = "Ponto", size = { 1, 1, 1 }, color = { 240, 150, 60 }, pos = { 0, 2, 0 } }, { class = "PointLight", name = "PointLight", pos = { 0, 0, 0 } } } },
		},
	},
	{
		category = "Jogo",
		items = {
			{ id = "tb_collectible", name = "Moeda", description = "Moeda giratória (Part).", icon = "Coin", nodes = { { class = "Part", name = "Moeda", size = { 1, 0.2, 1 }, color = { 245, 205, 66 }, mat = "Neon", pos = { 0, 2, 0 } } } },
			{ id = "tb_checkpoint", name = "Checkpoint", description = "Coluna de checkpoint.", icon = "Flag", nodes = { { class = "Part", name = "Checkpoint", size = { 2, 6, 2 }, color = { 90, 220, 130 }, pos = { 0, 3, 0 } } } },
			{ id = "tb_killbricks", name = "Ladrilhos", description = "Plataforma de eliminação.", icon = "Hazard", nodes = { { class = "Part", name = "Ladrilhos", size = { 10, 0.5, 10 }, color = { 180, 60, 60 }, mat = "Neon", pos = { 0, 0, 0 } } } },
		},
	},
	{
		category = "Scripts",
		items = {
			{ id = "tb_counter", name = "Contador", description = "Peça + Script que conta toques.", icon = "Script", nodes = { { class = "Part", name = "BotaoContador", size = { 2, 2, 2 }, color = { 120, 160, 220 }, pos = { 0, 2, 0 } } } },
		},
	},
}
function M.toolboxList()
	return { categories = TOOLBOX_LIST }
end
function M.toolboxGet(id)
	for _, cat in ipairs(TOOLBOX_LIST) do
		for _, it in ipairs(cat.items) do
			if it.id == id then return it end
		end
	end
	return nil
end

return M

		end)()
	end)
	if okMod and type(mod) == "table" then services = mod else servicesError = tostring(mod) end
end
local function needSvc()
	assert(services, "Arkher Services indisponiveis: " .. servicesError)
	return services
end

local function buildToolboxTemplate(player, parent, tpl)
	local items = {}
	local function addNode(node, nodeParent)
		local o = create(player, nodeParent, node.class, node.name)
		if node.size and o:IsA("BasePart") then pcall(function() o.Size = Vector3.new(node.size[1], node.size[2], node.size[3]) end) end
		if node.color then pcall(function() o.Color = Color3.fromRGB(node.color[1], node.color[2], node.color[3]) end) end
		if node.mat then pcall(function() o.Material = Enum.Material[node.mat] end) end
		if node.pos and o:IsA("BasePart") then pcall(function() o.CFrame = CFrame.new(node.pos[1], node.pos[2], node.pos[3]) end) end
		items[#items + 1] = { o = o, parent = nodeParent, name = node.name }
		return o
	end
	local root = addNode(tpl.nodes[1], parent)
	for i = 2, #tpl.nodes do
		local np = (tpl.nodes[1].class == "Model") and root or parent
		addNode(tpl.nodes[i], np)
	end
	local saved = {}
	for _, it in ipairs(items) do saved[#saved + 1] = { it.o:Clone(), it.parent, it.name } end
	pushHist(player, {
		label = "Inserir " .. tpl.name .. " (Toolbox)",
		cleanup = function() for _, s in ipairs(saved) do if s[1] and not s[1].Parent then s[1]:Destroy() end end end,
		undo = function() for _, it in ipairs(items) do if it.o.Parent then it.o:Destroy() end unregister(it.o) end end,
		redo = function() for _, s in ipairs(saved) do if not s[1].Parent then local n = s[1]:Clone() n.Name = s[3] n.Parent = s[2] register(n) end end end,
	})
	selected[player] = root
	queueObject(parent)
	return { node = record(root), count = #items }
end

function handlers.CloudStatus(player) needSvc() return services.status() end
function handlers.CloudList(player) needSvc() return { projects = services.cloudList() } end
function handlers.CloudSave(player, payload)
	needSvc()
	local name = (type(payload.name) == "string" and payload.name ~= "") and payload.name or ("Projeto " .. os.date("%d/%m/%Y %H:%M"))
	local data = serializeTree(workspace)
	local n = countTree(data)
	local json = Http:JSONEncode(data)
	local rec = services.cloudPut(name, json, #json, n)
	return { project = rec }
end
function handlers.CloudOpen(player, payload)
	needSvc()
	local got = services.cloudGet(payload.id)
	assert(got, "Projeto nao encontrado na cloud.")
	release(player, true)
	wipeWorkspace()
	local data = Http:JSONDecode(got.data)
	assert(data and data.c, "Snapshot invalido.")
	-- se a raiz do snapshot eh o Workspace/DataModel, importa os filhos (nao recria a raiz)
	local rootsToImport = {}
	if data.c == "Workspace" or data.c == "DataModel" then
		for _, c in ipairs(data.k or {}) do rootsToImport[#rootsToImport + 1] = c end
	else
		rootsToImport[#rootsToImport + 1] = data
	end
	local n = 0
	for _, r in ipairs(rootsToImport) do n = n + countTree(r) end
	assert(n <= CONFIG.MAX_CREATED_PER_SESSION, "Snapshot excede o limite de objetos.")
	local last
	for _, r in ipairs(rootsToImport) do last = deserializeTree(workspace, r) end
	if last then register(last) selected[player] = last end
	return { opened = got.record.name, nodes = n }
end
function handlers.CloudDelete(player, payload)
	needSvc()
	local ok = services.cloudDelete(payload.id)
	assert(ok, "Projeto nao encontrado.")
	return { deleted = payload.id }
end
function handlers.ToolboxPaidSearch(player, payload)
	local q = tostring(payload.query or ""):sub(1, 120)
	assert(#q > 0, "Digite o que buscar (itens pagos).")
	local data, err = pyGet("/catalog/search?q=" .. Http:UrlEncode(q) .. "&limit=8")
	if not data then return { ok = false, error = err } end
	if data.error then return { ok = false, error = tostring(data.error) } end
	return { items = data.items or {}, total = data.total or 0, query = q, paid = true }
end

local function sanitizeTree(t)
	if type(t) ~= "table" then
		local ty = typeof(t)
		if ty == "Vector3" or ty == "Vector2" then return { x = t.X, y = t.Y, z = t.Z } end
		if ty == "Color3" then return { x = t.R, y = t.G, z = t.B } end
		if ty == "UDim" or ty == "UDim2" or ty == "Rect" or ty == "CFrame" or ty == "BrickColor" then return tostring(t) end
		if ty == "string" or ty == "number" or ty == "boolean" then return t end
		return nil
	end
	local o = {}
	for k, v in pairs(t) do
		if k ~= "_r" then local c = sanitizeTree(v) if c ~= nil then o[k] = c end end
	end
	return o
end
function handlers.TeleportTo(player, payload)
	local pid = tonumber(payload.placeId or 0) or 0
	assert(pid > 0, "placeId invalido.")
	local ok, err = pcall(function()
		game:GetService("TeleportService"):TeleportAsync(pid, { player })
	end)
	if not ok then return { error = "Teleport recusou: " .. tostring(err):sub(1, 200) } end
	return { ok = true, placeId = pid }
end
function handlers.PublishReal(player, payload)
	local data = sanitizeTree(serializeTree(workspace))
	local body = Http:JSONEncode({ name = tostring(payload.name or "Arkher Place"), tree = data })
	assert(#body < 3000000, "Cena grande demais p/ exportar (3MB).")
	local res, err = pyPost("/cloud/export", body)
	if not res then return { error = err } end
	if res.error then return { error = tostring(res.error) } end
	return res
end
function handlers.AccountPlaces(player, payload)
	local uid = 0
	pcall(function() uid = game.GameId or 0 end)
	assert(uid > 0, "Universo desconhecido (jogo nao publicado?).")
	local data, err = pyGet("/cloud/places?universeId=" .. tostring(uid))
	if not data then return { ok = false, error = err } end
	if data.error then return { ok = false, error = tostring(data.error) } end
	return { places = data.places or {}, universeId = uid }
end

function handlers.CloudQuick(player, payload)
	needSvc()
	local data = serializeTree(workspace)
	local n = countTree(data)
	local json = Http:JSONEncode(data)
	local rec = services.cloudPut("Nuvem " .. os.date("%d/%m %H:%M"), json, #json, n)
	local okS, retS = pcall(function() return game:GetService("AssetService"):SavePlaceAsync() end)
	local pc = handlers.PlaceCreate(player, { name = "Place " .. os.date("%d/%m %H:%M") })
	local parts = { "Nuvem ok (" .. tostring(n) .. " obj)" }
	if okS then parts[#parts + 1] = "Publish ok"
	else parts[#parts + 1] = "Publish recusou" end
	if pc and pc.placeId then parts[#parts + 1] = "Place " .. tostring(pc.placeId)
	else parts[#parts + 1] = "Place: " .. tostring(pc and pc.error or "?"):sub(1, 60) end
	return {
		snapshot = rec and rec.name or "?",
		nodes = n,
		saved = okS == true,
		placeId = pc and pc.placeId or nil,
		placeError = (pc and pc.error) or nil,
		msg = table.concat(parts, " | "),
	}
end

function handlers.Publish(player, payload)
	needSvc()
	local info = payload or {}
	local data = serializeTree(workspace)
	local rec = services.publish(info)
	rec.workspaceNodes = countTree(data)
	return { game = rec }
end
function handlers.ProfileList(player) needSvc() return { games = services.profileList() } end
function handlers.ProfileGet(player, payload) needSvc() local g = services.profileGet(payload.id) assert(g, "Jogo nao encontrado.") return { game = g } end
function handlers.ProfileDelete(player, payload) needSvc() assert(services.profileDelete(payload.id), "Jogo nao encontrado.") return { deleted = payload.id } end
function handlers.DataList(player) needSvc() return { entries = services.dataList() } end
function handlers.DataGet(player, payload) needSvc() local e = services.dataGet(payload.key) assert(e, "Chave nao encontrada.") return { entry = e } end
function handlers.DataSet(player, payload) needSvc() return { entry = services.dataSet(payload.key, payload.value, payload.type) } end
function handlers.DataDelete(player, payload) needSvc() assert(services.dataDelete(payload.key), "Chave nao encontrada.") return { deleted = payload.key } end
function handlers.ProjectInfo(player) needSvc() return { info = services.projectInfo() } end
function handlers.SetProjectInfo(player, payload) needSvc() return { info = services.setProjectInfo(payload or {}) } end
function handlers.TeamInfo(player) needSvc() return services.team() end
function handlers.TeamAdd(player, payload) needSvc() assert(type(payload.name) == "string" and #payload.name > 0, "Nome invalido.") return services.teamAdd(payload.name, payload.role or "Editor") end
function handlers.TeamRemove(player, payload) needSvc() return services.teamRemove(payload.name) end
function handlers.InviteList(player) needSvc() return { invites = services.inviteList() } end
function handlers.InviteCreate(player, payload) needSvc() assert(type(payload.email) == "string" and payload.email:match("@"), "E-mail invalido.") return { invite = services.inviteCreate(payload.email, payload.role or "Editor") } end
function handlers.InviteAccept(player, payload) needSvc() local r = services.inviteAccept(payload.code) assert(r.ok ~= false, r.error or "Convite invalido.") return r end
function handlers.InviteReject(player, payload) needSvc() local r = services.inviteReject(payload.code) assert(r.ok ~= false, r.error or "Convite invalido.") return r end
function handlers.Locales(player) needSvc() return services.locales() end
function handlers.SetLocale(player, payload) needSvc() return services.setLocale(payload.code) end
function handlers.LocStrings(player) needSvc() return services.strings() end
function handlers.SetLocString(player, payload) needSvc() return services.setString(payload.key, payload.value, payload.translations) end
function handlers.ToolboxList(player) needSvc() return services.toolboxList() end
function handlers.ToolboxInsert(player, payload)
	needSvc()
	local tpl = services.toolboxGet(payload.id)
	if tpl then
		local parent = workspace
		if payload.parentId and objects[payload.parentId] then parent = objects[payload.parentId] end
		assert(editable(parent), "Pai invalido para este template.")
		return buildToolboxTemplate(player, parent, tpl)
	end
	-- fallback REAL (ROUND 11): id numerico = asset da Creator Store -> InsertService:LoadAsset no SERVIDOR
	local aid = tonumber(payload.id)
	assert(aid, "Template nao encontrado.")
	local okA, asset = pcall(function()
		return game:GetService("InsertService"):LoadAsset(aid)
	end)
	if not okA then
		return { error = "Creator Store recusou o asset " .. tostring(aid) .. ": " .. tostring(asset) .. " (só funciona com o jogo publicado/online)." }
	end
	assert(asset, "Asset vazio.")
	if payload.x or payload.y or payload.z then
		pcall(function()
			if asset:IsA("Model") then asset:PivotTo(CFrame.new(payload.x or 0, payload.y or 4, payload.z or -14)) end
		end)
	end
	asset.Parent = workspace
	local n2 = 0
	pcall(function() register(asset) n2 = n2 + 1 end)
	for _, d2 in ipairs(asset:GetDescendants()) do
		if n2 > 400 then break end
		local okR = pcall(function() if inspectable(d2) then register(d2) n2 = n2 + 1 end end)
		if not okR then break end
	end
	selected[player] = asset
	pcall(function() hCreate(player, asset) end)
	return { msg = "Asset " .. tostring(aid) .. " INSERIDO no mundo (" .. tostring(asset.Name) .. ", " .. tostring(n2) .. " objeto(s)) — selecionado no editor." }
end

-- ============ BLOCK_X7 (ROUND 7): propriedades EXAUSTIVAS + toolbox REAL + places ============
-- Mapa de propriedades por IsA-chain. kind: string,number,boolean,vector,color,brick,enum,cframe,source
local PROPSPEC = {
	{ isa = "SpawnLocation", props = {
		{"Transform",{"Neutral","boolean"},{"ForceField","number",0,600}},
		{"Appearance",{"TeamColor","brick"},{"AllowTeamChangeOnTouch","boolean"}},
	} },
	{ isa = "TrussPart", props = { {"Behavior",{"Style","enum:TrussStyle"}} } },
	{ isa = "CornerWedgePart", props = {} },
	{ isa = "WedgePart", props = {} },
	{ isa = "Terrain", props = {
		{"Water",{"WaterColor","color"},{"WaterTransparency","number",0,1},{"WaterReflectance","number",0,1},{"WaterWaveSize","number",0,1},{"WaterWaveSpeed","number",0,100}},
		{"Terrain",{"Decoration","boolean"}},
	} },
	{ isa = "Part", props = {
		{"Shape",{"Shape","enum:PartType"}},
		{"Surface",{"TopSurface","enum:SurfaceType"},{"BottomSurface","enum:SurfaceType"},{"LeftSurface","enum:SurfaceType"},{"RightSurface","enum:SurfaceType"},{"FrontSurface","enum:SurfaceType"},{"BackSurface","enum:SurfaceType"}},
	} },
	{ isa = "BasePart", props = {
		{"Transform",{"Position","vector",-1000000,1000000},{"Orientation","vector",-360,360},{"Size","vector",0.05,2048}},
		{"Appearance",{"Color","color"},{"Transparency","number",0,1},{"Reflectance","number",0,1},{"Material","enum:Material"},{"CastShadow","boolean"}},
		{"Data",{"Anchored","boolean"},{"Locked","boolean"},{"Massless","boolean"}},
		{"Collision",{"CanCollide","boolean"},{"CanTouch","boolean"},{"CanQuery","boolean"},{"CollisionGroupId","number",0,256},{"AssemblyMass","number",0,1000000}},
		{"Physics",{"CustomPhysicalPropertiesDensity","number",0.01,100},{"Friction","number",0,2},{"Elasticity","number",0,1},{"FrictionWeight","number",0,100},{"ElasticityWeight","number",0,100}},
	} },
	{ isa = "Model", props = {
		{"Data",{"PrimaryPart","string"}},
		{"Streaming",{"LevelOfDetail","enum:ModelLevelOfDetail"}},
	} },
	{ isa = "Humanoid", props = {
		{"State",{"Health","number",0,100000},{"MaxHealth","number",1,100000},{"WalkSpeed","number",0,1000},{"JumpPower","number",0,1000},{"JumpHeight","number",0,1000}},
		{"Behavior",{"HipHeight","number",-8,100},{"MaxSlopeAngle","number",0,89},{"AutoRotate","boolean"}},
	} },
	{ isa = "ScreenGui", props = {
		{"Data",{"Enabled","boolean"},{"DisplayOrder","number",0,1000},{"IgnoreGuiInset","boolean"},{"ResetOnSpawn","boolean"},{"ZIndexBehavior","enum:ZIndexBehavior"}},
	} },
	{ isa = "ScrollingFrame", props = {
		{"Scroll",{"CanvasSize","udim2"},{"ScrollBarThickness","number",0,32},{"ScrollingDirection","enum:ScrollingDirection"},{"AutomaticCanvasSize","enum:AutomaticSize"}},
	} },
	{ isa = "TextBox", props = {
		{"Behavior",{"ClearTextOnFocus","boolean"},{"MultiLine","boolean"},{"PlaceholderText","string"}},
	} },
	{ isa = "TextButton", props = { {"Behavior",{"AutoButtonColor","boolean"},{"Modal","boolean"},{"Selected","boolean"}} } },
	{ isa = "ImageButton", props = {} },
	{ isa = "ImageLabel", props = {
		{"Image",{"Image","string"},{"ImageColor3","color"},{"ImageTransparency","number",0,1},{"ScaleType","enum:ScaleType"},{"TileSize","udim2"}},
	} },
	{ isa = "TextLabel", props = {
		{"Text",{"Text","string"},{"TextColor3","color"},{"TextSize","number",4,96},{"Font","enum:Font"},{"TextScaled","boolean"},{"TextWrapped","boolean"},{"TextTransparency","number",0,1},{"TextStrokeTransparency","number",0,1},{"TextXAlignment","enum:TextXAlignment"},{"TextYAlignment","enum:TextYAlignment"},{"BackgroundColor3","color"},{"BackgroundTransparency","number",0,1}},
	} },
	{ isa = "GuiObject", props = {
		{"Layout",{"Position","udim2"},{"Size","udim2"},{"AnchorPoint","vector2"},{"Rotation","number",-360,360},{"ZIndex","number",-999,999},{"LayoutOrder","number",-99999,99999}},
		{"Appearance",{"BackgroundColor3","color"},{"BackgroundTransparency","number",0,1},{"BorderSizePixel","number",0,32},{"Visible","boolean"},{"ClipsDescendants","boolean"}},
		{"Input",{"Active","boolean"},{"Selectable","boolean"}},
	} },
	{ isa = "UICorner", props = { {"Corner",{"CornerRadius","udim"}} } },
	{ isa = "UIStroke", props = {
		{"Stroke",{"Color","color"},{"Thickness","number",0,64},{"Transparency","number",0,1},{"ApplyStrokeMode","enum:ApplyStrokeMode"},{"LineJoinMode","enum:LineJoinMode"}},
	} },
	{ isa = "UIGradient", props = { {"Gradient",{"Rotation","number",-360,360},{"Enabled","boolean"},{"Color","string"},{"Transparency","string"}} } },
	{ isa = "UIPadding", props = { {"Padding",{"PaddingTop","udim"},{"PaddingBottom","udim"},{"PaddingLeft","udim"},{"PaddingRight","udim"}} } },
	{ isa = "UIListLayout", props = {
		{"Layout",{"FillDirection","enum:FillDirection"},{"HorizontalAlignment","enum:HorizontalAlignment"},{"VerticalAlignment","enum:VerticalAlignment"},{"SortOrder","enum:SortOrder"},{"Padding","udim"}},
	} },
	{ isa = "UIGridLayout", props = { {"Layout",{"CellSize","udim2"},{"CellPadding","udim2"},{"FillDirection","enum:FillDirection"},{"SortOrder","enum:SortOrder"}} } },
	{ isa = "UIAspectRatioConstraint", props = { {"Constraint",{"AspectRatio","number",0.01,100},{"AspectType","enum:AspectType"},{"DominantAxis","enum:DominantAxis"}} } },
	{ isa = "Decal", props = { {"Texture",{"Texture","string"},{"Color3","color"},{"Transparency","number",0,1},{"Face","enum:NormalId"}} } },
	{ isa = "Texture", props = { {"Texture",{"StudsPerTileU","number",0.05,64},{"StudsPerTileV","number",0.05,64}} } },
	{ isa = "SurfaceLight", props = { {"Surface",{"Face","enum:NormalId"}} } },
	{ isa = "SpotLight", props = { {"Light",{"Angle","number",1,180},{"Face","enum:NormalId"}} } },
	{ isa = "PointLight", props = {
		{"Light",{"Brightness","number",0,40},{"Range","number",0,60},{"Color","color"},{"Enabled","boolean"},{"Shadows","boolean"}},
	} },
	{ isa = "ParticleEmitter", props = {
		{"Emission",{"Rate","number",0,50000},{"Lifetime","number",0.05,60},{"Speed","number",0,5000},{"SpreadAngle","vector2"}},
		{"Particle",{"Color","color"},{"Size","string"},{"Transparency","number",0,1},{"Rotation","number",-360,360},{"RotSpeed","vector2"}},
		{"Physics",{"Acceleration","vector"},{"Drag","number",0,10},{"VelocityInheritance","number",-1,1},{"LockedToPart","boolean"}},
		{"Data",{"Enabled","boolean"},{"LightEmission","number",0,1},{"LightInfluence","number",0,1}},
	} },
	{ isa = "Fire", props = { {"Fire",{"Color","color"},{"SecondaryColor","color"},{"Size","number",1,60},{"Heat","number",1,25},{"Enabled","boolean"}} } },
	{ isa = "Smoke", props = { {"Smoke",{"Color","color"},{"Size","number",0.1,100},{"Opacity","number",0,1},{"RiseVelocity","number",-25,25},{"Enabled","boolean"}} } },
	{ isa = "Sparkles", props = { {"Sparkles",{"SparkleColor","color"},{"Enabled","boolean"}} } },
	{ isa = "Sound", props = {
		{"Sound",{"SoundId","string"},{"Volume","number",0,10},{"PlaybackSpeed","number",0,20},{"Looped","boolean"},{"Playing","boolean"},{"RollOffMaxDistance","number",0,100000},{"RollOffMinDistance","number",0,100000}},
	} },
	{ isa = "ClickDetector", props = { {"Data",{"MaxActivationDistance","number",0,64},{"MaxActivationDistance","number"}} } },
	{ isa = "ProximityPrompt", props = {
		{"Prompt",{"ActionText","string"},{"ObjectText","string"},{"HoldDuration","number",0,30},{"MaxActivationDistance","number",0,50},{"Enabled","boolean"},{"RequiresLineOfSight","boolean"}},
	} },
	{ isa = "Tool", props = { {"Tool",{"RequiresHandle","boolean"},{"Enabled","boolean"}} } },
	{ isa = "Attachment", props = { {"Transform",{"Position","vector"},{"Orientation","vector"}} } },
	{ isa = "BoolValue", props = { {"Value",{"Value","boolean"}} } },
	{ isa = "IntValue", props = { {"Value",{"Value","number"}} } },
	{ isa = "NumberValue", props = { {"Value",{"Value","number"}} } },
	{ isa = "StringValue", props = { {"Value",{"Value","string"}} } },
	{ isa = "Vector3Value", props = { {"Value",{"Value","vector"}} } },
	{ isa = "Color3Value", props = { {"Value",{"Value","color"}} } },
	{ isa = "ObjectValue", props = { {"Value",{"Value","string"}} } },
	{ isa = "Script", props = { {"Script",{"Source","source"},{"Disabled","boolean"}} } },
	{ isa = "LocalScript", props = { {"Script",{"Source","source"},{"Disabled","boolean"}} } },
	{ isa = "ModuleScript", props = { {"Script",{"Source","source"}} } },
	{ isa = "Camera", props = { {"Camera",{"FieldOfView","number",1,120},{"CameraType","enum:CameraType"}} } },
	{ isa = "Lighting", props = {
		{"Atmosphere",{"Ambient","color"},{"OutdoorAmbient","color"},{"Brightness","number",0,10},{"ClockTime","number",0,24},{"GeographicLatitude","number",-90,90},{"TimeOfDay","string"}},
		{"Shadow",{"GlobalShadows","boolean"},{"FogColor","color"},{"FogStart","number",0,100000},{"FogEnd","number",0,100000}},
	} },
	{ isa = "Workspace", props = { {"World",{"Gravity","number",0,10000},{"GlobalWind","vector"},{"StreamingEnabled","boolean"}} } },
	{ isa = "Folder", props = {} },
}
local PROPSPEC_BASE = {
	{"Data",{"Name","string"},{"Archivable","boolean"}},
}

local function specFor(o)
	local out = {}
	for _, g in ipairs(PROPSPEC_BASE) do out[#out + 1] = g end
	for _, entry in ipairs(PROPSPEC) do
		if o:IsA(entry.isa) then
			for _, g in ipairs(entry.props) do out[#out + 1] = g end
		end
	end
	return out
end

local function readAny(o, key, kind)
	local ok, v = pcall(function() return o[key] end)
	if not ok or v == nil then return nil end
	if kind == "vector" and typeof(v) == "Vector3" then return { x = v.X, y = v.Y, z = v.Z } end
	if kind == "vector2" and typeof(v) == "Vector2" then return { x = v.X, y = v.Y } end
	if kind == "color" and typeof(v) == "Color3" then return { r = v.R, g = v.G, b = v.B } end
	if kind == "brick" and typeof(v) == "BrickColor" then return { brick = v.Name } end
	if kind == "cframe" and typeof(v) == "CFrame" then local c = v:GetComponents() return { x = c[1], y = c[2], z = c[3] } end
	if kind == "udim" and typeof(v) == "UDim" then return { scale = v.Scale, offset = v.Offset } end
	if kind == "udim2" and typeof(v) == "UDim2" then return { xs = v.X.Scale, xo = v.X.Offset, ys = v.Y.Scale, yo = v.Y.Offset } end
	if kind == "enum" and typeof(v) == "EnumItem" then return { enum = v.Name } end
	if kind == "source" and type(v) == "string" then return { s = v } end
	if type(v) == "string" then return { s = v:sub(1, 512) } end
	if type(v) == "number" or type(v) == "boolean" then return { v = v } end
	return nil
end

local function enumListFor(key)
	local map = {
		PartType = Enum.PartType, Material = Enum.Material, SurfaceType = Enum.SurfaceType,
		TrussStyle = Enum.TrussStyle, Font = Enum.Font, NormalId = Enum.NormalId,
		TextXAlignment = Enum.TextXAlignment, TextYAlignment = Enum.TextYAlignment,
		ScaleType = Enum.ScaleType, FillDirection = Enum.FillDirection,
		HorizontalAlignment = Enum.HorizontalAlignment, VerticalAlignment = Enum.VerticalAlignment,
		SortOrder = Enum.SortOrder, ZIndexBehavior = Enum.ZIndexBehavior,
		ScrollingDirection = Enum.ScrollingDirection, AutomaticSize = Enum.AutomaticSize,
		ApplyStrokeMode = Enum.ApplyStrokeMode, LineJoinMode = Enum.LineJoinMode,
		AspectType = Enum.AspectType, DominantAxis = Enum.DominantAxis,
		ModelLevelOfDetail = Enum.ModelLevelOfDetail, CameraType = Enum.CameraType,
	}
	local et = map[key]
	if not et then return nil end
	local out = {}
	for _, it in ipairs(et:GetEnumItems()) do out[#out + 1] = it.Name end
	table.sort(out)
	return out
end

function handlers.SelectedGet(player)
	local o = selected[player]
	if not o or not o.Parent then return { none = true, msg = "Nada selecionado — clique num objeto no EXPLORADOR." } end
	return { id = idOf[o], className = o.ClassName, name = o.Name, path = o:GetFullName() }
end


function handlers.PropsSet(player, payload)
	local o = getObject(payload.id)
	assert(editable(o), "Objeto somente leitura.")
	assert(type(payload.key) == "string" and #payload.key < 80, "Propriedade invalida.")
	local kind = tostring(payload.kind or "string")
	local val
	if kind == "number" then
		assert(finite(payload.v), "Numero invalido.") val = payload.v
	elseif kind == "boolean" then
		val = payload.v == true
	elseif kind == "string" or kind == "source" then
		assert(type(payload.s) == "string" and #payload.s < 200000, "Texto invalido.") val = payload.s
	elseif kind == "vector" then
		val = Vector3.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0, tonumber(payload.z) or 0)
	elseif kind == "vector2" then
		val = Vector2.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0)
	elseif kind == "color" then
		val = Color3.new(math.clamp(tonumber(payload.r) or 0, 0, 1), math.clamp(tonumber(payload.g) or 0, 0, 1), math.clamp(tonumber(payload.b) or 0, 0, 1))
	elseif kind == "brick" then
		assert(type(payload.brick) == "string", "BrickColor invalido.")
		local bok, bv = pcall(function() return BrickColor.new(payload.brick) end)
		assert(bok and bv, "BrickColor desconhecido: " .. tostring(payload.brick)) val = bv
	elseif kind == "enum" then
		assert(type(payload.enum) == "string", "Enum invalido.")
		local cur = o[payload.key]
		assert(typeof(cur) == "EnumItem", "Sem enum atual para casar.")
		local found
		for _, it in ipairs(Enum[cur.EnumType]:GetEnumItems()) do
			if it.Name:lower() == payload.enum:lower() then found = it break end
		end
		assert(found, "EnumItem invalido: " .. payload.enum) val = found
	elseif kind == "udim" then
		val = UDim.new(tonumber(payload.scale) or 0, tonumber(payload.offset) or 0)
	elseif kind == "udim2" then
		val = UDim2.new(tonumber(payload.xs) or 0, tonumber(payload.xo) or 0, tonumber(payload.ys) or 0, tonumber(payload.yo) or 0)
	elseif kind == "cframe" then
		local cur = o[payload.key]
		val = CFrame.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0, tonumber(payload.z) or 0) * (cur and (cur - cur.Position) or CFrame.new())
	else
		error("Kind desconhecido: " .. kind)
	end
	local old = readAny(o, payload.key, kind)
	local ok, err = pcall(function() o[payload.key] = val end)
	assert(ok, "Roblox recusou: " .. tostring(err))
	local new = readAny(o, payload.key, kind)
	if old ~= new then hSet(player, o, payload.key, old, new) end
	return { node = record(o), ok = true, applied = payload.key }
end

function handlers.QuickPart(player, payload)
	local shapes = { Block = "Block", Ball = "Ball", Cylinder = "Cylinder", CylinderVertical = "CylinderVertical", Wedge = "WedgePart", CornerWedge = "CornerWedgePart", Truss = "TrussPart" }
	local shape = tostring(payload.shape or "Block")
	assert(shapes[shape], "Forma invalida: " .. shape)
	local cls = shapes[shape]
	local parent = workspace
	if payload.parentId and objects[payload.parentId] then
		local p = objects[payload.parentId]
		if editable(p) then parent = p end
	end
	local nm = tostring(payload.name or (shape .. "_ArkherStock"))
	if cls == "WedgePart" or cls == "CornerWedgePart" or cls == "TrussPart" then
		local inst = Instance.new(cls)
		inst.Size = Vector3.new(4, 2, 4)
		inst.CFrame = CFrame.new(payload.x or 0, payload.y or 3, payload.z or -16)
		inst.Anchored = true
		inst.Color = Color3.fromRGB(120, 160, 220)
		inst.Parent = parent
		inst.Name = nm
		register(inst) created[inst] = true
		selected[player] = inst
		hCreate(player, inst)
		return { id = idOf[inst], className = cls, msg = cls .. " '" .. nm .. "' criado (classe real, sempre com pivô garantido)" }
	end
	local p2 = Instance.new("Part")
	p2.Shape = Enum.PartType[cls]
	p2.Size = (cls == "Ball") and Vector3.new(4, 4, 4) or (cls:find("Cylinder") and Vector3.new(2, 4, 4) or Vector3.new(4, 2, 4))
	p2.CFrame = CFrame.new(payload.x or 0, payload.y or 3, payload.z or -16)
	p2.Anchored = true
	p2.Color = Color3.fromRGB(120, 160, 220)
	p2.Parent = parent
	p2.Name = nm
	register(p2) created[p2] = true
	selected[player] = p2
	hCreate(player, p2)
	return { id = idOf[p2], className = "Part", shape = cls, msg = "Part " .. cls .. " '" .. nm .. "' criado (Shape real + Register do histórico)" }
end

function handlers.ToolboxSearch(player, payload)
	local q = tostring(payload.query or ""):sub(1, 120)
	assert(#q > 0, "Digite o que buscar na TOOLBOX (creator store real).")
	local kindS = tostring(payload.kind or "models")
	local page = math.clamp(tonumber(payload.page) or 0, 0, 99)
	local ok, page2 = pcall(function()
		local pageObj
		if kindS == "decals" then
			pageObj = game:GetService("InsertService"):GetFreeDecalsAsync(q, page)
		else
			pageObj = game:GetService("InsertService"):GetFreeModelsAsync(q, page)
		end
		return pageObj
	end)
	if not ok then
		return { error = "Creator Store indisponível nesta sessão (Roblox recusou a busca): " .. tostring(page2) }
	end
	local items = {}
	local results = page2.Results or {}
	for i = 1, math.min(#results, 24) do
		local it = results[i]
		items[#items + 1] = { name = it.Name, id = it.AssetId, creator = it.Creator, icon = it.IconUrl, trusted = it.IsEndorsed }
	end
	return { items = items, total = page2.TotalCount or #items, page = page, kind = kindS, query = q }
end

function handlers.ToolboxAssetInsert(player, payload)
	local id = tonumber(payload.assetId)
	assert(id and id > 0, "AssetId invalido.")
	local parent = workspace
	if payload.parentId and objects[payload.parentId] then
		local p = objects[payload.parentId]
		if editable(p) then parent = p end
	end
	local ok, model = pcall(function()
		return game:GetService("InsertService"):LoadAsset(id)
	end)
	assert(ok, "LoadAsset falhou (asset privado/protegido?): " .. tostring(model))
	assert(model, "Asset vazio.")
	local NM = #model:GetChildren()
	model.Name = "Asset_" .. id
	model.Parent = parent
	if payload.x or payload.y or payload.z then
		pcall(function()
			if model:IsA("Model") then model:PivotTo(CFrame.new(payload.x or 0, payload.y or 4, payload.z or -14)) end
		end)
	end
	register(model) created[model] = true
	selected[player] = model
	hCreate(player, model)
	-- marca no ouvinte para o cliente reposicionar
	return { id = idOf[model], nodes = NM, msg = ("Asset %d inserido (%d filhos) — Creator Store REAL"):format(id, NM) }
end

function handlers.PlaceCreate(player, payload)
	local name = tostring(payload.name or ""):sub(1, 80)
	assert(#name > 2, "Nome muito curto para a place.")
	-- templateChain: pedido > place atual (sua) > baseplate publica. Só online+publicado.
	local wanted = tonumber(payload.template) or 0
	local selfPlace = 0
	pcall(function() selfPlace = game.PlaceId or 0 end)
	local chain = {}
	if wanted > 0 then chain[#chain + 1] = wanted end
	if selfPlace > 0 and selfPlace ~= wanted then chain[#chain + 1] = selfPlace end
	chain[#chain + 1] = 9544032260
	local desc = tostring(payload.description or "Criado com Arkher Studio") or ""
	local ret, used, errs = nil, 0, {}
	for _, tpl in ipairs(chain) do
		local ok, r = pcall(function() return game:GetService("AssetService"):CreatePlaceAsync(name, tpl, desc) end)
		if ok and tonumber(r) then ret, used = r, tpl break
		else errs[#errs + 1] = tpl .. ": " .. tostring(r):sub(1, 100) end
	end
	if not ret then
		return { error = "CreatePlace recusou (" .. table.concat(errs, " | ") .. "). Regras: jogo PUBLICADO + jogando online (nao funciona em Play Solo); o template precisa ser seu, publicado e com copia-permitida." }
	end
	return { placeId = ret, templateUsed = used,
		url = "https://www.roblox.com/games/" .. tostring(ret),
		msg = "PLACE CRIADA na sua conta: id " .. tostring(ret) .. " (template " .. tostring(used) .. ")" }
end

-- ============ BLOCK_X8: SCRIPTS (listar p/ o SCRIPT EDITOR X) ============
function handlers.ScriptList(player, payload)
	local out = {}
	local roots = {
		workspace,
		game:GetService("ServerScriptService"),
		game:GetService("ServerStorage"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ReplicatedFirst"),
		game:GetService("StarterPlayer"),
		game:GetService("StarterPack"),
		game:GetService("StarterGui"),
	}
	local seen = {}
	local function walk(o, depth)
		if depth > 30 or hidden(o) then return end
		if o:IsA("LuaSourceContainer") and not seen[o] then
			seen[o] = true
			local len2 = 0
			pcall(function() len2 = #o.Source end)
			out[#out + 1] = {
				id = idOf[o] or 0, className = o.ClassName, name = o.Name,
				path = o:GetFullName(), len = len2,
			}
		end
		for _, c in ipairs(o:GetChildren()) do
			if not hidden(c) then walk(c, depth + 1) end
		end
	end
	for _, r in ipairs(roots) do walk(r, 0) end
	table.sort(out, function(a, b) return a.path < b.path end)
	return { scripts = out, count = #out }
end

-- ============ BLOCK_X9: PYBRIDGE via SERVIDOR (HttpService so roda server-side) ============
local PY_URL = "http://127.0.0.1:8773"
pcall(function() local u = game:GetAttribute("ArkherPyUrl") if type(u) == "string" and #u > 8 then PY_URL = u end end)
pyGet = function(path2)
	local ok2, res = pcall(function()
		return Http:GetAsync(PY_URL .. path2, true)
	end)
	if not ok2 then
		return nil, ("python bridge/offline OU HttpService desligado: ligar em Game Settings > Security > HTTP Requests. Detalhe: %s"):format(tostring(res))
	end
	local ok3, data = pcall(function() return Http:JSONDecode(res) end)
	if not ok3 then return nil, "resposta nao-JSON do python bridge" end
	return data
end
pyPost = function(path2, body)
	local ok2, res = pcall(function()
		return Http:PostAsync(PY_URL .. path2, body, Enum.HttpContentType.ApplicationJson, false)
	end)
	if not ok2 then
		return nil, ("python bridge/offline OU HttpService desligado: ligar em Game Settings > Security > HTTP Requests. Detalhe: %s"):format(tostring(res))
	end
	local ok3, data = pcall(function() return Http:JSONDecode(res) end)
	if not ok3 then return nil, "resposta nao-JSON do python bridge (POST " .. path2 .. ")" end
	return data
end

function handlers.PyStatus(player)
	local data, err = pyGet("/status")
	if not data then return { online = false, error = err } end
	return { online = data.ok == true, py = data.py, cwd = data.cwd, tasks = data.tasks, version = data.version }
end

function handlers.PyRun(player, payload)
	local task = tostring(payload.task or "")
	local arg = tostring(payload.arg or "")
	local lang = tostring(payload.lang or "py")
	local code = tostring(payload.code or "")
	local enc
	if task == "shell" then
		enc = "?task=shell&arg=" .. Http:UrlEncode(arg)
	elseif task == "exec" then
		assert(#code < 60000, "code grande demais (60KB).")
		enc = "?task=exec&lang=" .. Http:UrlEncode(lang) .. "&code=" .. Http:UrlEncode(code)
	else
		enc = "?task=" .. Http:UrlEncode(task)
	end
	local data, err = pyGet("/run" .. enc)
	if not data then return { ok = false, error = err } end
	return { ok = data.ok == true, summary = data.summary, error = data.error, out = data.out }
end

-- ============ BLOCK_X10 (ROUND 10): CSG real + SCULPT + CollisionGroups + Presence + Plugins ============
local TERRAIN = workspace:FindFirstChildOfClass("Terrain")
local function partSnap(o)
    return {
        class = o.ClassName, cf = o.CFrame, size = o.Size, color = o.Color,
        mat = o.Material.Name, trans = o.Transparency, shape = (o:IsA("Part") and o.Shape.Name or nil),
        name = o.Name, anchored = o.Anchored,
    }
end
local function partRestore(snap, parent)
    local cls = snap.class
    if cls == "WedgePart" or cls == "CornerWedgePart" or cls == "TrussPart" or cls == "Part" or cls == "MeshPart" then
        local o2 = Instance.new(cls == "MeshPart" and "Part" or cls)
        o2.Name = snap.name
        o2.CFrame = snap.cf
        o2.Size = snap.size
        pcall(function() o2.Color = snap.color end)
        pcall(function() o2.Material = snap.mat end)
        pcall(function() o2.Transparency = snap.trans end)
        if snap.shape then pcall(function() o2.Shape = Enum.PartType[snap.shape] end) end
        o2.Anchored = snap.anchored
        o2.Parent = parent
        register(o2) created[o2] = true
        return o2
    end
    return nil
end

function handlers.CsgDo(player, payload)
    local op = tostring(payload.op or "union")
    assert(op == "union" or op == "negate" or op == "separate", "op deve ser 'union', 'negate' ou 'separate'")
    local main
    if payload.mainId then main = getObject(payload.mainId) end
    if not main then main = selected[player] end
    assert(main and main:IsA("BasePart") and not main:IsA("Terrain"), "Selecione a PEÇA principal (BasePart) primeiro.")
    assert(editable(main), "Peça principal somente leitura.")
    if op == "separate" then
        assert(main:IsA("UnionOperation"), "Separate precisa de um UnionOperation selecionado.")
        local parent = main.Parent
        local okS, pieces = pcall(function() return main:Separate() end)
        assert(okS and type(pieces) == "table" and #pieces > 0, "Separate recusou.")
        local mId = idOf[main]
        for _, pc in ipairs(pieces) do pc.Parent = parent register(pc) created[pc] = true queueObject(pc) end
        main.Parent = nil unregister(main)
        selected[player] = pieces[1]
        pushHist(player, {
            label = "Separate " .. #pieces .. " parts",
            undo = function()
                local uOk, u = pcall(function() return pieces[1]:UnionAsync({ unpack(pieces, 2) }) end)
                assert(uOk and u, "Undo separate recusou.")
                u.Name = "Union_RESTORED" u.Parent = parent register(u) created[u] = true
                for _, pc in ipairs(pieces) do pc.Parent = nil unregister(pc) end
                selected[player] = u queueObject(u)
            end,
            redo = function()
                local u = selected[player]
                if u and u:IsA("UnionOperation") then
                    local _, p2 = pcall(function() return u:Separate() end)
                    if type(p2) == "table" then for _, pc in ipairs(p2) do pc.Parent = parent register(pc) created[pc] = true queueObject(pc) end end
                    u.Parent = nil unregister(u)
                    if type(p2) == "table" and #p2 > 0 then selected[player] = p2[1] end
                end
            end,
        })
        return { separated = #pieces, removed = mId }
    end
    -- outra: ids explicitos ou a peça valida mais proxima da main (escopo 80 studs)
    local others = {}
    if type(payload.otherIds) == "table" then
        for _, id2 in ipairs(payload.otherIds) do
            local o = getObject(id2)
            if o and o:IsA("BasePart") and not o:IsA("Terrain") and editable(o) and o ~= main then
                others[#others + 1] = o
            end
        end
    else
        local best, bd = nil, 80
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and not o:IsA("Terrain") and o ~= main and editable(o) and not o:IsDescendantOf(main) then
                local d2 = (o.Position - main.Position).Magnitude
                if d2 < bd then best, bd = o, d2 end
            end
        end
        if best then others[#others + 1] = best end
    end
    assert(#others > 0, "Sem segunda peça: selecione uma peça PERTO do alvo (até 80 studs) ou passe otherIds.")
    local other = others[1]
    local snapMain, snapOther = partSnap(main), partSnap(other)
    local parent = main.Parent
    local ok2, resultPart = pcall(function()
        if op == "union" then return main:UnionAsync({ other }) end
        return main:SubtractAsync({ other })
    end)
    assert(ok2 and resultPart, op .. "Async recusou: " .. tostring(resultPart))
    -- herda o visual da main
    pcall(function() resultPart.Color = main.Color end)
    pcall(function() resultPart.Material = main.Material end)
    pcall(function() resultPart.Transparency = main.Transparency end)
    resultPart.Name = main.Name .. "_" .. op:upper()
    resultPart.Anchored = main.Anchored
    resultPart.Parent = parent
    register(resultPart) created[resultPart] = true
    -- remove as duas originais
    local mId, oId = idOf[main], idOf[other]
    selected[player] = resultPart
    main:Destroy() other:Destroy()
    unregister(main) unregister(other)
    -- histórico real: undo recria as duas; redo refaz a operação
    pushHist(player, {
        label = "CSG " .. op .. " (" .. snapMain.name .. " × " .. snapOther.name .. ")",
        undo = function()
            if resultPart.Parent then resultPart:Destroy() end
            local m2 = partRestore(snapMain, parent)
            partRestore(snapOther, parent)
            selected[player] = m2
            if m2 then queueObject(m2) end
        end,
        redo = function()
            local okR, errR = pcall(function()
                handlers.CsgDo(player, { op = op })
            end)
            if not okR then error(errR) end
        end,
    })
    return { id = idOf[resultPart], msg = ("CSG %s: '%s' × '%s' -> sólido NOVO '%s' (real: PartOperation + histórico desfaz)"):format(op, snapMain.name, snapOther.name, resultPart.Name) }
end

-- --------- SCULPT X: pincéis de terreno com falloff real (fill/erode/smooth/flat) ---------
local function sculptInfo(v)
    return type(v) == "string" and Enum.Material[v] or nil
end
function handlers.SculptApply(player, payload)
    assert(TERRAIN, "Sem Terrain neste mundo.")
    local mode = tostring(payload.mode or "raise")
    local cx, cy, cz = tonumber(payload.x) or 0, tonumber(payload.y) or 2, tonumber(payload.z) or 0
    local r = math.clamp(tonumber(payload.r) or 12, 4, 64)
    local strength = math.clamp(tonumber(payload.strength) or 1, 0.05, 1)
    local center = Vector3.new(cx, cy, cz)
    local mat = sculptInfo(payload.material) or Enum.Material.Grass
    local cells = 0
    if mode == "raise" then
        TERRAIN:FillBall(center, r * strength, mat)
        cells = 1
    elseif mode == "lower" then
        TERRAIN:FillBall(center, r * strength, Enum.Material.Air)
        cells = 1
    elseif mode == "smooth" or mode == "flat" then
        local minP = center - Vector3.new(r, r, r)
        local maxP = center + Vector3.new(r, r, r)
        local region = Region3.new(minP, maxP):ExpandToGrid(4)
        local okR, mats, occs = pcall(function()
            local m2, o2 = TERRAIN:ReadVoxels(region, 4)
            return true, m2, o2
        end)
        assert(okR, "ReadVoxels falhou: " .. tostring(mats))
        local sizeY = #occs[1]
        local sizeZ = #occs[1][1]
        local function voxelPos(ix, iy, iz)
            local cell = region.CFrame * Vector3.new(
                (ix - 0.5 - #occs / 2) * 4,
                (iy - 0.5 - #occs[1] / 2) * 4,
                (iz - 0.5 - #occs[1][1] / 2) * 4)
            return cell
        end
        for ix = 1, #occs do
            for iy = 1, sizeY do
                for iz = 1, sizeZ do
                    local vp = voxelPos(ix, iy, iz)
                    local dist = (vp - center).Magnitude
                    if dist < r then
                        local t2 = dist / r
                        local fall = math.exp(-(t2 * t2) * 4) * strength -- gaussiano caindo p/ zero na borda
                        if mode == "smooth" then
                            -- média dos 6 vizinhos (Laplaciano real)
                            local sum, n2 = 0, 0
                            local function getO(dx, dy, dz)
                                local jx, jy, jz = ix + dx, iy + dy, iz + dz
                                if occs[jx] and occs[jx][jy] and occs[jx][jy][jz] ~= nil then
                                    sum = sum + occs[jx][jy][jz] n2 = n2 + 1
                                end
                            end
                            getO(-1, 0, 0) getO(1, 0, 0) getO(0, -1, 0) getO(0, 1, 0) getO(0, 0, -1) getO(0, 0, 1)
                            if n2 > 0 then
                                occs[ix][iy][iz] = math.clamp(occs[ix][iy][iz] + (sum / n2 - occs[ix][iy][iz]) * fall, 0, 1)
                            end
                        else -- flat
                            local target = (cy - vp.Y) / 4
                            target = math.clamp(target, 0, 1)
                            if vp.Y <= cy then target = 1 else target = math.clamp((cy + 4 - vp.Y) / 8, 0, 1) end
                            occs[ix][iy][iz] = math.clamp(occs[ix][iy][iz] + (target - occs[ix][iy][iz]) * fall, 0, 1)
                            if occs[ix][iy][iz] > 0.4 and (mats[ix] and mats[ix][iy] and mats[ix][iy][iz] == Enum.Material.Air) then
                                mats[ix][iy][iz] = mat
                            end
                        end
                    end
                end
            end
        end
        local okW, errW = pcall(function() TERRAIN:WriteVoxels(region, 4, mats, occs) end)
        assert(okW, "WriteVoxels falhou: " .. tostring(errW))
        cells = #occs * sizeY * sizeZ
    else
        error("mode deve ser raise|lower|smooth|flat")
    end
    return { msg = ("SCULPT %s em (%.0f, %.0f, %.0f) r=%d força=%.2f — terreno REAL alterado (%s)"):format(
        mode, cx, cy, cz, r, strength, tostring(cells)) }
end

-- --------- COLLISION GROUPS (grupos de colisão reais) ---------
local PS = game:GetService("PhysicsService")
local function colGroups()
    local ok, list = pcall(function() return PS:GetRegisteredCollisionGroups() end)
    if ok and type(list) == "table" then return list end
    return {}
end
function handlers.ColGroupList(player)
    local out = {}
    for _, g in ipairs(colGroups()) do
        out[#out + 1] = { id = g.id, name = g.name, mask = (g.mask ~= nil and g.mask or nil) }
    end
    return { groups = out }
end
function handlers.ColGroupCreate(player, payload)
    local nm = tostring(payload.name or ""):sub(1, 40)
    assert(#nm > 1, "Nome de grupo muito curto.")
    for _, g in ipairs(colGroups()) do
        if g.name == nm then return { id = g.id, msg = "Já existe: " .. nm .. " (id " .. g.id .. ")" } end
    end
    local ok, err = pcall(function() PS:CreateCollisionGroup(nm) end)
    assert(ok, "CreateCollisionGroup recusou: " .. tostring(err))
    return { msg = "Grupo de colisão '" .. nm .. "' criado (atribua CollisionGroupId nas peças — PROPS X)." }
end
function handlers.ColGroupSetCollidable(player, payload)
    local a2 = tostring(payload.a or "")
    local b2 = tostring(payload.b or "")
    assert(a2 ~= "" and b2 ~= "", "Passe a e b (nomes dos grupos).")
    local v = payload.collidable ~= false
    local ok, err = pcall(function() PS:CollisionGroupSetCollidable(a2, b2, v) end)
    assert(ok, "Recusou: " .. tostring(err))
    return { msg = ("Colisão %s × %s = %s (real, servidor)"):format(a2, b2, v and "COLIDE" or "ignora") }
end

-- --------- PRESENCE: quem está editando o quê, agora ----------
function handlers.PresenceGet(player)
    local out = {}
    for pl in pairs(subscribed) do
        if pl.Parent == Players then
            local sel2 = selected[pl]
            local editing = {}
            for obj, owner in pairs(locks) do
                if owner == pl and obj and obj.Parent then
                    editing[#editing + 1] = obj.Name
                    if #editing >= 3 then break end
                end
            end
            out[#out + 1] = {
                name = pl.Name,
                selected = sel2 and sel2.Parent and sel2.Name or nil,
                editing = (#editing > 0) and table.concat(editing, ", ") or nil,
            }
        end
    end
    return { players = out }
end

-- --------- PLUGINS (módulos X ligam/desligam de verdade no pump) ----------
local function enginesFolder()
    return game:GetService("ServerStorage"):FindFirstChild("ArkherEngines")
end
local PLUGIN_KEYS = { "Atmos", "Water", "Anim", "Audio", "Rig", "Reality", "Scene" }
function handlers.PluginList(player)
    local eng = enginesFolder()
    local out = {}
    if eng then
        for _, child in ipairs(eng:GetChildren()) do
            out[#out + 1] = { id = child.Name, kind = child.ClassName, enabled = eng:GetAttribute("Enabled_" .. child.Name) ~= false }
        end
    end
    for _, kj in ipairs(PLUGIN_KEYS) do
        if eng and eng:GetAttribute("Enabled_" .. kj) == nil then
            eng:SetAttribute("Enabled_" .. kj, true)
        end
        out[#out + 1] = { id = kj, kind = "pump", enabled = not eng or eng:GetAttribute("Enabled_" .. kj) ~= false }
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return { plugins = out }
end
function handlers.PluginToggle(player, payload)
    local id = tostring(payload.id or "")
    assert(#id > 0, "id do plugin")
    local v = payload.enabled == true
    local eng = enginesFolder()
    assert(eng, "ArkherEngines ausente no ServerStorage.")
    eng:SetAttribute("Enabled_" .. id, v)
    return { msg = ("Plugin/pump '%s' agora = %s (efeito IMEDIATO no pump do servidor)"):format(id, v and "LIGADO" or "desligado") }
end

-- ============ BLOCK_X11 (ROUND 11): BASEPLATE garantida (boot auto + botão BASEPLATE) ============
local function ensureBaseplate()
    local b = workspace:FindFirstChild("Baseplate")
    if b and b:IsA("BasePart") then return b end
    b = Instance.new("Part")
    b.Name = "Baseplate"
    b.Size = Vector3.new(2048, 2, 2048)
    b.CFrame = CFrame.new(0, -1, 0)
    b.Anchored = true
    b.Color = Color3.fromRGB(100, 104, 118)
    b.Material = Enum.Material.Concrete
    pcall(function() b.TopSurface = Enum.SurfaceType.Smooth b.BottomSurface = Enum.SurfaceType.Smooth end)
    b.Parent = workspace
    register(b) created[b] = true
    return b
end

function handlers.EnsureBase(player)
    local old = workspace:FindFirstChild("Baseplate")
    local wasMissing = not (old and old:IsA("BasePart"))
    local b = ensureBaseplate()
    selected[player] = b
    if wasMissing then pcall(function() hCreate(player, b) end) end
    return { id = idOf[b], msg = wasMissing and "BASEPLATE criada (2048×2048, topo em Y=0) e selecionada." or "Baseplate já existia — selecionada no editor." }
end

-- ============ BLOCK_X12 (ROUND 12): CLASSDB exaustiva + PropsAll + SetAny + ClassList + CreateAny ============
-- Formato: "Grupo|Nome|kind[:ro]" kinds: s,n,b,v,v2,c,br,e:Enum,cf,o,u2,u,r,seq,i
local CLASSDB = {
	Instance = "Data|Name|s:ro|Data|ClassName|s:ro|Data|Archivable|b",
	BasePart = "Transform|Position|v|Transform|Orientation|v|Transform|Rotation|v|Transform|Size|v|Transform|CFrame|cf|Transform|PivotOffset|cf|Appearance|Color|c|Appearance|Material|e:Material|Appearance|Transparency|n|Appearance|Reflectance|n|Physics|Anchored|b|Physics|Locked|b|Physics|CanCollide|b|Physics|CanTouch|b|Physics|CanQuery|b|Physics|CastShadow|b|Physics|Massless|b|Physics|CollisionGroupId|n|Physics|CustomPhysicalPropertiesDensity|n|Physics|Friction|n|Physics|Elasticity|n|Physics|FrictionWeight|n|Physics|ElasticityWeight|n|Physics|RootPriority|n|Physics|EnableFluidForces|b|Surface|TopSurface|e:SurfaceType|Surface|BottomSurface|e:SurfaceType|Surface|LeftSurface|e:SurfaceType|Surface|RightSurface|e:SurfaceType|Surface|FrontSurface|e:SurfaceType|Surface|BackSurface|e:SurfaceType|Assembly|AssemblyMass|n:ro|Assembly|AssemblyLinearVelocity|v:ro|Assembly|AssemblyAngularVelocity|v:ro",
	Part = "Part|Shape|e:PartType",
	Model = "Data|PrimaryPart|o|Streaming|LevelOfDetail|e:ModelLevelOfDetail",
	MeshPart = "Mesh|MeshId|s|Mesh|TextureID|i|Mesh|RenderFidelity|e:RenderFidelity|Mesh|DoubleSided|b|Mesh|CollisionFidelity|e:CollisionFidelity|Mesh|FluidFidelity|e:FluidFidelity",
	UnionOperation = "Mesh|UsePartColor|b|Mesh|RenderFidelity|e:RenderFidelity|Mesh|CollisionFidelity|e:CollisionFidelity|Mesh|FluidFidelity|e:FluidFidelity",
	SpawnLocation = "Spawn|Neutral|b|Spawn|TeamColor|br|Spawn|AllowTeamChangeOnTouch|b|Spawn|Duration|n|Spawn|Enabled|b",
	Seat = "Seat|Disabled|b",
	VehicleSeat = "Seat|Disabled|b|Seat|MaxSpeed|n|Seat|Torque|n|Seat|TurnSpeed|n|Seat|Throttle|n|Seat|Steer|n|Seat|AreHingesDetected|n:ro|Seat|Occupant|o:ro",
	TrussPart = "Truss|Style|e:TrussStyle",
	Attachment = "Attachment|Axis|v|Attachment|SecondaryAxis|v|Attachment|Position|v|Attachment|Orientation|v|Attachment|Rotation|v|Attachment|WorldPosition|v:ro|Attachment|WorldOrientation|v:ro|Attachment|Visible|b",
	JointInstance = "Joints|Part0|o|Joints|Part1|o|Joints|C0|cf|Joints|C1|cf|Joints|Enabled|bb",
	WeldConstraint = "Joints|Part0|o|Joints|Part1|o|Joints|Enabled|b",
	Motor6D = "Joints|Part0|o|Joints|Part1|o|Joints|C0|cf|Joints|C1|cf|Joints|Enabled|b|Motor|Transform|cf|Motor|MaxVelocity|n",
	Script = "Script|Enabled|b|Script|RunContext|e:RunContext|Script|Source|s:ro",
	LocalScript = "Script|Enabled|b|Script|Source|s:ro",
	ModuleScript = "Script|Source|s:ro",
	Humanoid = "State|Health|n|State|MaxHealth|n|Locomotion|WalkSpeed|n|Locomotion|JumpPower|n|Locomotion|JumpHeight|n|Locomotion|HipHeight|n|Locomotion|AutoRotate|b|Locomotion|MaxSlopeAngle|n|Locomotion|WalkToPoint|v|Locomotion|WalkToPart|o|Data|RigType|n:ro|Display|DisplayDistanceType|e:HumanoidDisplayDistanceType|Display|HealthDisplayType|e:HumanoidHealthDisplayType|Display|NameDisplayDistance|n|Display|HealthDisplayDistance|n|Display|NameOcclusion|e:NameOcclusion",
	Sound = "Audio|SoundId|i|Audio|Volume|n|Audio|PlaybackSpeed|n|Audio|Looped|b|Audio|Playing|b|Audio|IsPlaying|b:ro|Audio|IsPaused|b:ro|Audio|TimePosition|n|Audio|RollOffMaxDistance|n|Audio|RollOffMinDistance|n|Audio|RollOffMode|e:RollOffMode|Audio|EmitterSize|n|Audio|PlayOnRemove|b|Audio|SoundGroup|o",
	ParticleEmitter = "Emitter|Enabled|b|Emitter|Texture|i|Emitter|Rate|n|Emitter|Lifetime|s|Emitter|Speed|s|Emitter|SpreadAngle|v|Emitter|Rotation|s|Emitter|RotSpeed|s|Appearance|Color|seq|Appearance|Transparency|seq|Appearance|Size|seq|Appearance|LightEmission|n|Appearance|LightInfluence|n|Emission|EmissionDirection|e:NormalId|Emission|Squash|s|Emission|Shape|e:ParticleEmitterShape|Emission|ShapeStyle|e:ParticleEmitterShapeStyle|Emission|ShapeInOut|e:ParticleEmitterShapeInOut|Emission|ShapePartial|n|Physics|Acceleration|v|Physics|Drag|n|Physics|VelocityInheritance|n|Physics|LockedToPart|b|Particles|Orientation|e:ParticleOrientation|Particles|MaxDistance|n|Particles|TimeScale|n|Particles|ZOffset|n|Particles|WindAffectsDrag|b|Particles|FlipbookLayout|e:ParticleFlipbookLayout|Particles|FlipbookMode|e:ParticleFlipbookMode|Particles|FlipbookFramerate|s|Particles|FlipbookStartRandom|s",
	PointLight = "Light|Brightness|n|Light|Color|c|Light|Enabled|b|Light|Range|n|Light|Shadows|b",
	SpotLight = "Light|Brightness|n|Light|Color|c|Light|Enabled|b|Light|Range|n|Light|Shadows|b|Spot|Angle|n|Spot|Face|e:NormalId",
	SurfaceLight = "Light|Brightness|n|Light|Color|c|Light|Enabled|b|Light|Range|n|Light|Shadows|b|Surface|Angle|n|Surface|Face|e:NormalId",
	Decal = "Appearance|Texture|i|Appearance|Color3|c|Appearance|Transparency|n|Appearance|LocalTransparencyModifier|n:ro|Surface|Face|e:NormalId|Surface|ZIndex|n",
	Texture = "Appearance|Texture|i|Appearance|Color3|c|Appearance|Transparency|n|Surface|Face|e:NormalId|Surface|StudsPerTileU|n|Surface|StudsPerTileV|n|Surface|OffsetStudsU|n|Surface|OffsetStudsV|n|Surface|ZIndex|n",
	SpecialMesh = "Mesh|MeshId|i|Mesh|TextureId|i|Mesh|MeshType|e:MeshType|Mesh|Offset|v|Mesh|Scale|v|Mesh|VertexColor|v",
	BlockMesh = "Mesh|Offset|v|Mesh|Scale|v|Mesh|VertexColor|v",
	CylinderMesh = "Mesh|Offset|v|Mesh|Scale|v|Mesh|VertexColor|v",
	Fire = "Fire|Color|c|Fire|SecondaryColor|c|Fire|Heat|n|Fire|Size|n|Fire|Enabled|b|Fire|TimeScale|n",
	Smoke = "Smoke|Color|c|Smoke|Opacity|n|Smoke|RiseVelocity|n|Smoke|Size|n|Smoke|Enabled|b|Smoke|TimeScale|n",
	Sparkles = "Sparkles|SparkleColor|c|Sparkles|Enabled|b|Sparkles|TimeScale|n",
	ForceField = "ForceField|Visible|b",
	Explosion = "Explosion|BlastPressure|n|Explosion|BlastRadius|n|Explosion|DestroyJointRadiusPercent|n|Explosion|ExplosionType|e:ExplosionType|Explosion|Position|v|Explosion|TimeScale|n|Explosion|Visible|b",
	Highlight = "Highlight|Adornee|o|Highlight|FillColor|c|Highlight|FillTransparency|n|Highlight|OutlineColor|c|Highlight|OutlineTransparency|n|Highlight|DepthMode|e:HighlightDepthMode|Highlight|Enabled|b",
	SelectionBox = "Selection|Adornee|o|Selection|Color3|c|Selection|LineThickness|n|Selection|SurfaceColor3|c|Selection|SurfaceTransparency|n|Selection|Transparency|n|Selection|Visible|b",
	Sky = "Sky|CelestialBodiesShown|b|Sky|MoonAngularSize|n|Sky|MoonTextureId|i|Sky|SkyboxBk|i|Sky|SkyboxDn|i|Sky|SkyboxFt|i|Sky|SkyboxLf|i|Sky|SkyboxRt|i|Sky|SkyboxUp|i|Sky|StarCount|n|Sky|SunAngularSize|n|Sky|SunTextureId|i",
	Atmosphere = "Atmosphere|Color|c|Atmosphere|Decay|c|Atmosphere|Density|n|Atmosphere|Glare|n|Atmosphere|Haze|n|Atmosphere|Offset|n",
	Clouds = "Clouds|Color|c|Clouds|Cover|n|Clouds|Density|n|Clouds|Enabled|b",
	Trail = "Trail|Attachment0|o|Trail|Attachment1|o|Trail|Color|seq|Trail|Transparency|seq|Trail|Texture|i|Trail|TextureLength|n|Trail|TextureMode|e:TextureMode|Trail|Lifetime|n|Trail|MinLength|n|Trail|MaxLength|n|Trail|WidthScale|s|Trail|LightEmission|n|Trail|LightInfluence|n|Trail|Enabled|b|Trail|FaceCamera|b",
	Beam = "Beam|Attachment0|o|Beam|Attachment1|o|Beam|Color|seq|Beam|Transparency|seq|Beam|Texture|i|Beam|TextureLength|n|Beam|TextureMode|e:TextureMode|Beam|TextureSpeed|n|Beam|Width0|n|Beam|Width1|n|Beam|CurveSize0|n|Beam|CurveSize1|n|Beam|Segments|n|Beam|ZOffset|n|Beam|LightEmission|n|Beam|LightInfluence|n|Beam|Brightness|n|Beam|FaceCamera|b|Beam|Enabled|b",
	Camera = "Camera|CFrame|cf|Camera|FieldOfView|n|Camera|CameraType|e:CameraType|Camera|CameraSubject|o|Camera|Focus|cf|Camera|ViewportSize|v2:ro|Camera|HeadScale|n",
	Tool = "Tool|RequiresHandle|b|Tool|Enabled|b|Tool|ToolTip|s|Tool|TextureId|i|Tool|CanBeDropped|b|Tool|ManualActivationOnly|b",
	Folder = "",
	Configuration = "",
	BoolValue = "Value|Value|b",
	IntValue = "Value|Value|n",
	NumberValue = "Value|Value|n",
	StringValue = "Value|Value|s",
	ObjectValue = "Value|Value|o",
	BrickColorValue = "Value|Value|br",
	Color3Value = "Value|Value|c",
	CFrameValue = "Value|Value|cf",
	Vector3Value = "Value|Value|v",
	Lighting = "Environment|Ambient|c|Environment|OutdoorAmbient|c|Environment|Brightness|n|Environment|ClockTime|n|Environment|GeographicLatitude|n|Environment|GlobalShadows|b|Environment|EnvironmentDiffuseScale|n|Environment|EnvironmentSpecularScale|n|Environment|ExposureCompensation|n|Environment|ShadowSoftness|n|Environment|Technology|e:Technology",
	Terrain = "Water|WaterColor|c|Water|WaterTransparency|n|Water|WaterReflectance|n|Water|WaterWaveSize|n|Water|WaterWaveSpeed|n|Terrain|Decoration|b",
	ScreenGui = "Screen|Enabled|b|Screen|DisplayOrder|n|Screen|IgnoreGuiInset|b|Screen|ResetOnSpawn|b|Screen|ZIndexBehavior|e:ZIndexBehavior|Screen|ClipToDeviceSafeArea|b|Screen|SafeAreaCompatibility|e:SafeAreaCompatibility|Screen|ScreenInsets|e:ScreenInsets",
	BillboardGui = "Adornment|Adornee|o|Adornment|Size|u2|Adornment|ExtentsOffset|v|Adornment|ExtentsOffsetWorldSpace|v|Adornment|StudsOffset|v|Adornment|StudsOffsetWorldSpace|v|Adornment|LightInfluence|n|Adornment|MaxDistance|n|Adornment|AlwaysOnTop|b|Adornment|Brightness|n|Adornment|Enabled|b",
	SurfaceGui = "Adornment|Adornee|o|Adornment|Face|e:NormalId|Adornment|CanvasSize|u2|Adornment|PixelsPerStud|n|Adornment|MaxDistance|n|Adornment|AlwaysOnTop|b|Adornment|LightInfluence|n|Adornment|Brightness|n|Adornment|Enabled|b",
	GuiObject = "Data|Visible|b|Data|ZIndex|n|Data|LayoutOrder|n|Appearance|BackgroundColor3|c|Appearance|BackgroundTransparency|n|Appearance|BorderColor3|c|Appearance|BorderMode|e:BorderMode|Appearance|BorderSizePixel|n|Layout|Position|u2|Layout|Size|u2|Layout|AnchorPoint|v2|Layout|Rotation|n|Layout|ClipsDescendants|b|Layout|AutomaticSize|e:AutomaticSize|Behavior|Active|b|Behavior|Selectable|b|Behavior|SelectionOrder|n",
	TextLabel = "Text|Text|s|Text|TextColor3|c|Text|TextSize|n|Text|Font|e:Font|Text|FontFace|s|Text|TextTransparency|n|Text|TextStrokeTransparency|n|Text|TextStrokeColor3|c|Text|TextXAlignment|e:TextXAlignment|Text|TextYAlignment|e:TextYAlignment|Text|TextWrapped|b|Text|TextScaled|b|Text|RichText|b|Text|MaxVisibleGraphemes|n|Text|LineHeight|n|Text|TextTruncate|e:TextTruncate|Text|TextDirection|e:TextDirection",
	TextButton = "Text|Text|s|Text|TextColor3|c|Text|TextSize|n|Text|Font|e:Font|Text|FontFace|s|Text|TextTransparency|n|Text|TextStrokeTransparency|n|Text|TextStrokeColor3|c|Text|TextXAlignment|e:TextXAlignment|Text|TextYAlignment|e:TextYAlignment|Text|TextWrapped|b|Text|TextScaled|b|Text|RichText|b|Button|AutoButtonColor|b|Button|Modal|b|Button|Selected|b|Button|Style|e:ButtonStyle|Button|Interactable|b",
	TextBox = "Text|Text|s|Text|TextColor3|c|Text|TextSize|n|Text|Font|e:Font|Text|FontFace|s|Text|TextTransparency|n|Text|TextXAlignment|e:TextXAlignment|Text|TextYAlignment|e:TextYAlignment|Text|TextWrapped|b|Text|TextScaled|b|Text|RichText|b|Box|PlaceholderText|s|Box|PlaceholderColor3|c|Box|ClearTextOnFocus|b|Box|MultiLine|b|Box|TextEditable|b",
	ImageLabel = "Image|Image|i|Image|ImageColor3|c|Image|ImageTransparency|n|Image|ScaleType|e:ScaleType|Image|SliceCenter|r|Image|SliceScale|n|Image|TileSize|u2|Image|ResampleMode|e:ResamplerMode",
	ImageButton = "Image|Image|i|Image|ImageColor3|c|Image|ImageTransparency|n|Image|ScaleType|e:ScaleType|Image|SliceCenter|r|Image|SliceScale|n|Image|TileSize|u2|Image|ResampleMode|e:ResamplerMode|Image|HoverImage|i|Image|PressedImage|i|Button|AutoButtonColor|b|Button|Modal|b|Button|Selected|b|Button|Style|e:ButtonStyle",
	ScrollingFrame = "Scroll|CanvasSize|u2|Scroll|CanvasPosition|v2|Scroll|AutomaticCanvasSize|e:AutomaticSize|Scroll|ScrollBarThickness|n|Scroll|ScrollBarImageColor3|c|Scroll|ScrollBarImageTransparency|n|Scroll|ScrollingDirection|e:ScrollingDirection|Scroll|ScrollingEnabled|b|Scroll|ElasticBehavior|e:ElasticBehavior|Scroll|VerticalScrollBarInset|e:ScrollBarInset|Scroll|HorizontalScrollBarInset|e:ScrollBarInset|Scroll|VerticalScrollBarPosition|e:VerticalScrollBarPosition|Scroll|TopImage|i|Scroll|MidImage|i|Scroll|BottomImage|i",
	ViewportFrame = "Viewport|CurrentCamera|o|Viewport|ImageColor3|c|Viewport|ImageTransparency|n|Viewport|Ambient|c|Viewport|LightColor|c|Viewport|LightDirection|v",
	VideoFrame = "Video|Video|i|Video|Playing|b|Video|Looped|b|Video|Volume|n|Video|TimePosition|n",
	UIStroke = "Stroke|Color|c|Stroke|Thickness|n|Stroke|Transparency|n|Stroke|ApplyStrokeMode|e:ApplyStrokeMode|Stroke|LineJoinMode|e:LineJoinMode|Stroke|Enabled|b",
	UICorner = "Corner|CornerRadius|u",
	UIGradient = "Gradient|Color|seq|Gradient|Transparency|seq|Gradient|Rotation|n|Gradient|Offset|v2|Gradient|Enabled|b",
	UIPadding = "Padding|PaddingBottom|u|Padding|PaddingLeft|u|Padding|PaddingRight|u|Padding|PaddingTop|u",
	UIListLayout = "Layout|FillDirection|e:FillDirection|Layout|HorizontalAlignment|e:HorizontalAlignment|Layout|VerticalAlignment|e:VerticalAlignment|Layout|SortOrder|e:SortOrder|Layout|Padding|u|Layout|Wraps|b|Layout|HorizontalFlex|e:UIFlexAlignment|Layout|VerticalFlex|e:UIFlexAlignment|Layout|ItemLineAlignment|e:ItemLineAlignment",
	UIGridLayout = "Layout|FillDirection|e:FillDirection|Layout|HorizontalAlignment|e:HorizontalAlignment|Layout|VerticalAlignment|e:VerticalAlignment|Layout|SortOrder|e:SortOrder|Layout|CellPadding|u2|Layout|CellSize|u2|Layout|FillDirectionMaxCells|n|Layout|StartCorner|e:StartCorner",
	UIPageLayout = "Layout|Animated|b|Layout|Circular|b|Layout|EasingDirection|e:EasingDirection|Layout|EasingStyle|e:EasingStyle|Layout|GamepadInputEnabled|b|Layout|Padding|u|Layout|ScrollWheelInputEnabled|b|Layout|TouchInputEnabled|b|Layout|TweenTime|n",
	UISizeConstraint = "Constraint|MinSize|v2|Constraint|MaxSize|v2",
	UITextSizeConstraint = "Constraint|MinTextSize|n|Constraint|MaxTextSize|n",
	UIAspectRatioConstraint = "Constraint|AspectRatio|n|Constraint|AspectType|e:AspectType|Constraint|DominantAxis|e:DominantAxis",
	UIScale = "Scale|Scale|n",
	ProximityPrompt = "Prompt|ActionText|s|Prompt|ObjectText|s|Prompt|HoldDuration|n|Prompt|MaxActivationDistance|n|Prompt|RequiresLineOfSight|b|Prompt|ClickablePrompt|b|Prompt|Enabled|b|Prompt|KeyboardKeyCode|e:KeyCode|Prompt|GamepadKeyCode|e:KeyCode|Prompt|UIOffset|v2|Prompt|Style|e:ProximityPromptStyle|Prompt|Exclusivity|e:ProximityPromptExclusivity",
	ClickDetector = "Detector|MaxActivationDistance|n|Detector|CursorImage|i",
	AlignPosition = "Constraint|MaxForce|n|Constraint|MaxVelocity|n|Constraint|Responsiveness|n|Constraint|ApplyAtCenterOfMass|b|Constraint|MaxAxesForce|v|Constraint|Mode|e:PositionAlignmentMode|Constraint|Position|v|Constraint|RigidityEnabled|b|Constraint|ReactionForceEnabled|b|Constraint|Enabled|b|Constraint|Attachment0|o|Constraint|Attachment1|o",
	AlignOrientation = "Constraint|MaxTorque|n|Constraint|MaxAngularVelocity|n|Constraint|Responsiveness|n|Constraint|Mode|e:OrientationAlignmentMode|Constraint|PrimaryAxisOnly|b|Constraint|RigidityEnabled|b|Constraint|ReactionTorqueEnabled|b|Constraint|Enabled|b|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|CFrame|cf",
	VectorForce = "Constraint|Force|v|Constraint|RelativeTo|e:ActuatorRelativeTo|Constraint|ApplyAtCenterOfMass|b|Constraint|Attachment0|o|Constraint|Enabled|b",
	LineForce = "Constraint|InverseSquareLaw|b|Constraint|LineForce|n|Constraint|MaxForce|n|Constraint|ReactionTorqueEnabled|b|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	Torque = "Constraint|Torque|v|Constraint|RelativeTo|e:ActuatorRelativeTo|Constraint|Attachment0|o|Constraint|Enabled|b",
	RopeConstraint = "Constraint|Length|n|Constraint|Restitution|n|Constraint|Visible|b|Constraint|Thickness|n|Constraint|Color|br|Constraint|CurrentDistance|n:ro|Constraint|WinchEnabled|b|Constraint|WinchForce|n|Constraint|WinchResponsiveness|n|Constraint|WinchSpeed|n|Constraint|WinchTarget|n|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	SpringConstraint = "Constraint|Damping|n|Constraint|Stiffness|n|Constraint|FreeLength|n|Constraint|LimitsEnabled|b|Constraint|MaxLength|n|Constraint|MinLength|n|Constraint|Radius|n|Constraint|Thickness|n|Constraint|Visible|b|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	HingeConstraint = "Constraint|ActuatorType|e:ActuatorType|Constraint|AngularSpeed|n|Constraint|AngularResponsiveness|n|Constraint|AngularVelocity|n|Constraint|CurrentAngle|n:ro|Constraint|LimitsEnabled|b|Constraint|LowerAngle|n|Constraint|UpperAngle|n|Constraint|MotorMaxAcceleration|n|Constraint|MotorMaxTorque|n|Constraint|Radius|n|Constraint|Restitution|n|Constraint|ServoMaxTorque|n|Constraint|TargetAngle|n|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	BallSocketConstraint = "Constraint|LimitsEnabled|b|Constraint|MaxFrictionTorque|n|Constraint|Radius|n|Constraint|Restitution|n|Constraint|TwistLimitsEnabled|b|Constraint|TwistLowerAngle|n|Constraint|TwistUpperAngle|n|Constraint|UpperAngle|n|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	PrismaticConstraint = "Constraint|ActuatorType|e:ActuatorType|Constraint|LimitsEnabled|b|Constraint|LowerLimit|n|Constraint|UpperLimit|n|Constraint|MotorMaxForce|n|Constraint|ServoMaxForce|n|Constraint|Speed|n|Constraint|TargetPosition|n|Constraint|CurrentPosition|n:ro|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	UniversalConstraint = "Constraint|LimitsEnabled|b|Constraint|MaxAngle|n|Constraint|Radius|n|Constraint|Restitution|n|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	NoCollisionConstraint = "Constraint|Part0|o|Constraint|Part1|o|Constraint|Enabled|b",
	AngularVelocity = "Constraint|AngularVelocity|v|Constraint|MaxTorque|n|Constraint|ReactionTorqueEnabled|b|Constraint|RelativeTo|e:ActuatorRelativeTo|Constraint|Attachment0|o|Constraint|Enabled|b",
	RigidConstraint = "Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	CylindricalConstraint = "Constraint|ActuatorType|e:ActuatorType|Constraint|AngularActuatorType|e:ActuatorType|Constraint|CurrentAngle|n:ro|Constraint|CurrentPosition|n:ro|Constraint|InclinationAngle|n|Constraint|LimitsEnabled|b|Constraint|LowerLimit|n|Constraint|UpperLimit|n|Constraint|MotorMaxForce|n|Constraint|MotorMaxTorque|n|Constraint|ServoMaxForce|n|Constraint|ServoMaxTorque|n|Constraint|Speed|n|Constraint|TargetPosition|n|Constraint|AngularSpeed|n|Constraint|AngularResponsiveness|n|Constraint|AngularVelocity|n|Constraint|Attachment0|o|Constraint|Attachment1|o|Constraint|Enabled|b",
	BodyColors = "Colors|HeadColor|br|Colors|LeftArmColor|br|Colors|LeftLegColor|br|Colors|RightArmColor|br|Colors|RightLegColor|br|Colors|TorsoColor|br",
	Shirt = "Clothes|ShirtTemplate|i",
	Pants = "Clothes|PantsTemplate|i",
	ShirtGraphic = "Clothes|Graphic|i",
	Animation = "Animation|AnimationId|i",
	Bone = "Bone|Transform|cf",
	PathfindingModifier = "Modifier|Label|s|Modifier|PassThrough|b",
	SoundGroup = "Audio|Volume|n",
	EchoSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Echo|Delay|n|Echo|Feedback|n|Echo|DryLevel|n|Echo|WetLevel|n",
	ReverbSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Reverb|DecayTime|n|Reverb|Density|n|Reverb|Diffusion|n|Reverb|DryLevel|n|Reverb|WetLevel|n",
	DistortionSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Distortion|Level|n",
	ChorusSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Chorus|Depth|n|Chorus|Mix|n|Chorus|Rate|n",
	CompressorSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Compressor|Attack|n|Compressor|GainMakeup|n|Compressor|Ratio|n|Compressor|Release|n|Compressor|Threshold|n",
	EqualizerSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Equalizer|HighGain|n|Equalizer|LowGain|n|Equalizer|MidGain|n",
	FlangeSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Flange|Depth|n|Flange|Mix|n|Flange|Rate|n",
	PitchShiftSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Pitch|Octave|n",
	TremoloSoundEffect = "Effect|Enabled|b|Effect|Priority|n|Tremolo|Depth|n|Tremolo|Duty|n|Tremolo|Frequency|n",
	Message = "Text|Text|s",
	Hint = "Text|Text|s",
	Dialog = "Dialog|ConversationDistance|n|Dialog|GoodbyeChoiceActive|b|Dialog|GoodbyeDialog|s|Dialog|InUse|b|Dialog|InitialPrompt|s|Dialog|Purpose|e:DialogPurpose|Dialog|Tone|e:DialogTone|Dialog|TriggerOffset|n",
	RemoteEvent = "",
	RemoteFunction = "",
	BindableEvent = "",
	BindableFunction = "",
	UnreliableRemoteEvent = "",
	WorldModel = "",
	Actor = "",
}
-- herança: filho -> pai (cadeia consultada em PropsAll)
local CLASS_PARENT = {
	Part = "BasePart", WedgePart = "BasePart", CornerWedgePart = "BasePart", TrussPart = "BasePart",
	MeshPart = "BasePart", UnionOperation = "BasePart", SpawnLocation = "BasePart", Seat = "BasePart",
	VehicleSeat = "BasePart", Model = "PVStub", WorldModel = "Model",
	PointLight = "Stub", SpotLight = "Stub", SurfaceLight = "Stub",
	Decal = "Stub", Texture = "Stub", SpecialMesh = "Stub", BlockMesh = "Stub", CylinderMesh = "Stub",
	Fire = "Stub", Smoke = "Stub", Sparkles = "Stub", ForceField = "Stub", Explosion = "Stub",
	Highlight = "Stub", SelectionBox = "Stub", Sky = "Stub", Atmosphere = "Stub", Clouds = "Stub",
	Trail = "Stub", Beam = "Stub", Attachment = "Stub",
	WeldConstraint = "Stub", Motor6D = "Stub", Script = "Stub", LocalScript = "Stub", ModuleScript = "Stub",
	Humanoid = "Stub", Sound = "Stub", ParticleEmitter = "Stub", Camera = "Stub", Tool = "Stub",
	Folder = "Stub", Configuration = "Stub", Lighting = "Stub", Terrain = "Stub",
	BoolValue = "Stub", IntValue = "Stub", NumberValue = "Stub", StringValue = "Stub",
	ObjectValue = "Stub", BrickColorValue = "Stub", Color3Value = "Stub", CFrameValue = "Stub",
	Vector3Value = "Stub", Animation = "Stub", Bone = "Stub", PathfindingModifier = "Stub",
	SoundGroup = "Stub", EchoSoundEffect = "Stub", ReverbSoundEffect = "Stub", DistortionSoundEffect = "Stub",
	ChorusSoundEffect = "Stub", CompressorSoundEffect = "Stub", EqualizerSoundEffect = "Stub",
	FlangeSoundEffect = "Stub", PitchShiftSoundEffect = "Stub", TremoloSoundEffect = "Stub",
	Message = "Stub", Hint = "Stub", Dialog = "Stub",
	RemoteEvent = "Stub", RemoteFunction = "Stub", BindableEvent = "Stub",
	BindableFunction = "Stub", UnreliableRemoteEvent = "Stub", Actor = "Stub",
	BodyColors = "Stub", Shirt = "Stub", Pants = "Stub", ShirtGraphic = "Stub",
	ScreenGui = "Stub", BillboardGui = "Stub", SurfaceGui = "Stub",
	Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiObject", TextBox = "GuiObject",
	ImageLabel = "GuiObject", ImageButton = "GuiObject", ScrollingFrame = "GuiObject",
	ViewportFrame = "GuiObject", VideoFrame = "GuiObject", CanvasGroup = "GuiObject",
	UIStroke = "Stub", UICorner = "Stub", UIGradient = "Stub", UIPadding = "Stub",
	UIListLayout = "Stub", UIGridLayout = "Stub", UIPageLayout = "Stub", UISizeConstraint = "Stub",
	UITextSizeConstraint = "Stub", UIAspectRatioConstraint = "Stub", UIScale = "Stub",
	ProximityPrompt = "Stub", ClickDetector = "Stub",
	AlignPosition = "Stub", AlignOrientation = "Stub", VectorForce = "Stub", LineForce = "Stub",
	Torque = "Stub", RopeConstraint = "Stub", SpringConstraint = "Stub", HingeConstraint = "Stub",
	BallSocketConstraint = "Stub", PrismaticConstraint = "Stub", UniversalConstraint = "Stub",
	NoCollisionConstraint = "Stub", AngularVelocity = "Stub", RigidConstraint = "Stub",
	CylindricalConstraint = "Stub",
	Script_ = "Stub",
}
CLASS_PARENT.Form = nil

local function parseSpec(specStr, into)
	if not specStr or specStr == "" then return end
	local group, name, kind = nil, nil, nil
	local parts = {}
	for p2 in string.gmatch(specStr, "([^|]+)") do parts[#parts + 1] = p2 end
	local q2 = 1
	while q2 <= #parts do
		group = parts[q2]; name = parts[q2 + 1]; kind = parts[q2 + 2]; q2 = q2 + 3
		if name and kind then
			local ro = kind:sub(-3) == ":ro"
			if ro then kind = kind:sub(1, -4) end
			if kind == "bb" then kind = "b" end
			if kind == "o:ro" then ro = true kind = "o" end
			into[#into + 1] = { group = group, name = name, kind = kind, ro = ro }
		end
	end
end

-- resolve cadeia IsA real primeiro; CLASSDB cobre os detalhes finos
local function dbClassChain(o)
	local chain, seen = {}, {}
	local cn = o.ClassName
	while cn and not seen[cn] do
		seen[cn] = true
		chain[#chain + 1] = cn
		cn = CLASS_PARENT[cn]
	end
	return chain
end

function handlers.PropsAll(player, payload)
	local o = getObject(payload.id)
	assert(o, "Objeto sumiu.")
	local fields, seen = {}, {}
	local function addRow(group, name, kind, ro)
		local key = group .. "/" .. name
		if seen[key] then return end
		seen[key] = true
		local okRead, val = pcall(function() return o[name] end)
		if not okRead then return end
		local out = { group = group, name = name, kind = kind, ro = ro }
		local kt = kind
		if kt == "b" then out.value = val == true
		elseif kt == "n" then out.value = tonumber(tostring(val)) or 0
		elseif kt == "v" then local x, y2, z = pcall(function() return val.X, val.Y, val.Z end); if x then out.value = { x = val.X, y = val.Y, z = val.Z } else return end
		elseif kt == "v2" then local x, y2 = pcall(function() return val.X, val.Y end); if x then out.value = { x = val.X, y = val.Y } else return end
		elseif kt == "c" then local x = pcall(function() return val.R end); if x then out.value = { r = val.R, g = val.G, b = val.B } else return end
		elseif kt == "br" then local x, bv = pcall(function() return tostring(val) end); out.value = x and bv or "White"
		elseif kt:sub(1, 2) == "e:" then local x, ev = pcall(function() return val.Name end); if not x then return end; out.value = ev; out.enum = kt:sub(3)
		elseif kt == "i" or kt == "s" then out.value = tostring(val or "")
		elseif kt == "o" then out.value = val and val:GetFullName() or "None"; out.ro = true
		elseif kt == "cf" or kt == "u2" or kt == "u" or kt == "r" or kt == "seq" then out.value = tostring(val)
		else out.value = tostring(val) out.ro = true
		end
		fields[#fields + 1] = out
	end
	-- 1) CLASSDB (cadeia)
	for _, cn in ipairs(dbClassChain(o)) do
		local spec = CLASSDB[cn]
		if spec then
			local rows = {}
			parseSpec(spec, rows)
			for _, rp in ipairs(rows) do addRow(rp.group, rp.name, rp.kind, rp.ro) end
		end
	end
	addRow("Data", "Name", "s", false)
	-- 2) extra tipos comuns por IsA (segurança caso a cadeia falhe)
	if o:IsA("BasePart") and not o:IsA("Terrain") and not o:IsA("FormFactorPart") then
		-- já coberto por chain quando CLASSNAME conhecido; classes custom (UnionOperation etc) caem aqui
		local spec = CLASSDB.BasePart
		local rows = {}
		parseSpec(spec, rows)
		for _, rp in ipairs(rows) do addRow(rp.group, rp.name, rp.kind, rp.ro) end
	end
	if o:IsA("GuiObject") then
		local rows = {}
		parseSpec(CLASSDB.GuiObject, rows)
		for _, rp in ipairs(rows) do addRow(rp.group, rp.name, rp.kind, rp.ro) end
	end
	table.sort(fields, function(a, b) if a.group == b.group then return a.name < b.name end return a.group < b.group end)
	return { id = payload.id, name = o.Name, className = o.ClassName, fields = fields, count = #fields }
end

local function coerceProp(o, name, kind, v)
	if kind == "b" then return v == true or v == "true"
	elseif kind == "n" then
		local n2 = tonumber(v)
		assert(n2 and n2 == n2 and math.abs(n2) ~= math.huge, "Número inválido.")
		return n2
	elseif kind == "v" then
		assert(type(v) == "table", "Vector esperado.")
		return Vector3.new(tonumber(v.x) or 0, tonumber(v.y) or 0, tonumber(v.z) or 0)
	elseif kind == "v2" then
		assert(type(v) == "table", "Vector2 esperado.")
		return Vector2.new(tonumber(v.x) or 0, tonumber(v.y) or 0)
	elseif kind == "c" then
		assert(type(v) == "table", "Color esperado.")
		return Color3.new(math.clamp(tonumber(v.r) or 0, 0, 1), math.clamp(tonumber(v.g) or 0, 0, 1), math.clamp(tonumber(v.b) or 0, 0, 1))
	elseif kind == "br" then
		return BrickColor.new(tostring(v))
	elseif kind:sub(1, 2) == "e:" then
		local et = kind:sub(3)
		local ev = Enum[et]
		assert(ev, "Enum desconhecido: " .. et)
		local item = ev[tostring(v)]
		assert(item, "Valor de enum inválido: " .. tostring(v))
		return item
	elseif kind == "u2" then
		assert(type(v) == "table", "UDim2 esperado.")
		return UDim2.new(tonumber(v.sx) or 0, tonumber(v.ox) or 0, tonumber(v.sy) or 0, tonumber(v.oy) or 0)
	elseif kind == "u" then
		assert(type(v) == "table", "UDim esperado.")
		return UDim.new(tonumber(v.s) or 0, tonumber(v.o) or 0)
	elseif kind == "s" or kind == "i" then
		local t2 = tostring(v)
		assert(#t2 < 4096, "Texto longo demais.")
		return t2
	end
	error("Tipo não editável: " .. tostring(kind))
end

function handlers.SetAny(player, payload)
	local o = getObject(payload.id)
	assert(o, "Objeto sumiu.")
	assert(editable(o), "Objeto protegido.")
	local name = tostring(payload.name or "")
	assert(#name > 0 and #name < 60, "Prop inválida.")
	local kind = tostring(payload.kind or "s")
	local val = coerceProp(o, name, kind, payload.value)
	local okOld, old = pcall(function() return o[name] end)
	if not okOld then return { error = "Propriedade não existe: " .. name } end
	local okSet, errSet = pcall(function() o[name] = val end)
	if not okSet then return { error = "Roblox recusou " .. name .. ": " .. tostring(errSet) } end
	local okNew, new0 = pcall(function() return o[name] end)
	if okOld and okNew and tostring(old) ~= tostring(new0) then
		pcall(function() hSet(player, o, name, old, new0) end) -- R4: undo cru (tostring quebrava desfazer numerico/bool)
	end
	pcall(function() queueObject(o) end)
	return { ok = true, applied = name, now = tostring(new0) }
end

-- catálogo GIGANTE de classes (+ grupos) pro menu "+" (+1k objetos feel)
local CLASS_CATALOG = {
	{ "Part", "3D", "geometry", "Bloco básico (4x1x2).", "bloco" }, { "WedgePart", "3D", "geometry", "Rampa.", "rampa" },
	{ "CornerWedgePart", "3D", "geometry", "Canto de rampa.", "canto" }, { "TrussPart", "3D", "geometry", "Treliça escalável.", "" },
	{ "SpawnLocation", "3D", "geometry", "Ponto de spawn.", "spawn" }, { "Seat", "3D", "geometry", "Assento.", "assento" },
	{ "VehicleSeat", "3D", "geometry", "Assento de veículo (dirigível).", "" }, { "SkateboardPlatform", "3D", "geometry", "Plataforma de skate.", "" },
	{ "MeshPart", "3D", "geometry", "Peça de malha (sem mesh até atribuir MeshId no Studio).", "" },
	{ "UnionOperation", "3D", "geometry", "Peça union (via CSG).", "uniao" },
	{ "Model", "Containers", "container", "Agrupa objetos.", "grupo" }, { "WorldModel", "Containers", "container", "Model físico pra ViewportFrame.", "" },
	{ "Folder", "Containers", "container", "Pasta.", "pasta" }, { "Configuration", "Containers", "container", "Pasta de configuração.", "" },
	{ "Actor", "Containers", "container", "Contêiner paralelo (actors).", "" },
	{ "Attachment", "3D", "attachment", "Ponto de referência.", "anexo" }, { "Bone", "3D", "attachment", "Osso de skinned mesh.", "" },
	{ "Script", "Scripts", "script", "Script de servidor (vazio, desativado).", "codigo" }, { "LocalScript", "Scripts", "script", "LocalScript (vazio, desativado).", "" },
	{ "ModuleScript", "Scripts", "script", "ModuleScript (Source editável no Studio).", "modulo" },
	{ "ScreenGui", "UI", "screen", "Tela de UI (pai: StarterGui).", "tela" },
	{ "Frame", "UI", "gui", "Painel retangular.", "" }, { "CanvasGroup", "UI", "gui", "Grupo de canvas com transparência de grupo.", "" },
	{ "TextLabel", "UI", "gui", "Texto estático.", "texto" }, { "TextButton", "UI", "gui", "Botão de texto.", "botao" },
	{ "TextBox", "UI", "gui", "Caixa de texto editável.", "" }, { "ImageLabel", "UI", "gui", "Imagem estática.", "imagem" },
	{ "ImageButton", "UI", "gui", "Botão de imagem.", "" }, { "ScrollingFrame", "UI", "gui", "Área rolável.", "lista" },
	{ "ViewportFrame", "UI", "gui", "Render 3D dentro da UI.", "" }, { "VideoFrame", "UI", "gui", "Player de vídeo.", "video" },
	{ "UICorner", "UI", "component", "Cantos arredondados.", "" }, { "UIStroke", "UI", "component", "Contorno.", "borda" },
	{ "UIGradient", "UI", "component", "Gradiente de cor.", "" }, { "UIPadding", "UI", "component", "Espaçamento interno.", "" },
	{ "UIListLayout", "UI", "component", "Layout em lista.", "" }, { "UIGridLayout", "UI", "component", "Layout em grade.", "" },
	{ "UIPageLayout", "UI", "component", "Layout em páginas.", "" }, { "UISizeConstraint", "UI", "component", "Limita tamanho.", "" },
	{ "UITextSizeConstraint", "UI", "component", "Limita tamanho do texto.", "" }, { "UIAspectRatioConstraint", "UI", "component", "Trava proporção.", "" },
	{ "UIScale", "UI", "component", "Escala a UI.", "" },
	{ "BillboardGui", "Adorners", "surface", "UI flutuante no mundo (acima da peça).", "" }, { "SurfaceGui", "Adorners", "surface", "UI na face da peça.", "" },
	{ "SunRaysEffect", "PostFX", "postfx", "Raios de sol (Lighting).", "" }, { "BloomEffect", "PostFX", "postfx", "Brilho exagerado das luzes.", "" },
	{ "BlurEffect", "PostFX", "postfx", "Desfoque de tela.", "" }, { "ColorCorrectionEffect", "PostFX", "postfx", "Correção de cor/brilho/contraste.", "" },
	{ "DepthOfFieldEffect", "PostFX", "postfx", "Desfoque por distância.", "" },
	{ "Sky", "Ambiente", "sky", "Céu/sol/lua/estrelas (Lighting).", "ceu" }, { "Atmosphere", "Ambiente", "sky", "Atmosfera real (neblina física).", "" },
	{ "Clouds", "Ambiente", "sky", "Nuvens volumétricas.", "nuvens" },
	{ "PointLight", "Efeitos", "effect", "Luz pontual.", "luz" }, { "SpotLight", "Efeitos", "effect", "Holofote.", "" }, { "SurfaceLight", "Efeitos", "effect", "Luz de superfície.", "" },
	{ "ParticleEmitter", "Efeitos", "effect", "Partículas customizáveis.", "particula" }, { "Trail", "Efeitos", "effect", "Rastro entre attachments.", "" },
	{ "Beam", "Efeitos", "effect", "Feixe entre attachments.", "" }, { "Fire", "Efeitos", "effect", "Fogo clássico.", "fogo" },
	{ "Smoke", "Efeitos", "effect", "Fumaça clássica.", "fumaca" }, { "Sparkles", "Efeitos", "effect", "Faíscas clássicas.", "" },
	{ "Explosion", "Efeitos", "effect", "Explosão física.", "explosao" }, { "ForceField", "Efeitos", "effect", "Campo de força.", "" },
	{ "Highlight", "Efeitos", "effectmodel", "Contorno/preenchimento de destaque (pai: Model/peça).", "" }, { "SelectionBox", "Efeitos", "effectmodel", "Caixa de seleção visual.", "" },
	{ "FireEffect", "Efeitos", "effectmodel", "Fogo entre attachments (MaterialVariant era).", "" },
	{ "Decal", "Aparência", "surface", "Imagem numa face.", "adesivo" }, { "Texture", "Aparência", "surface", "Textura repetida.", "" },
	{ "SpecialMesh", "Aparência", "mesh", "Malha especial na peça.", "" }, { "BlockMesh", "Aparência", "mesh", "Malha bloco (escala não-uniforme).", "" },
	{ "CylinderMesh", "Aparência", "mesh", "Malha cilindro.", "" }, { "MaterialVariant", "Aparência", "material", "Variação de material (MaterialService).", "" },
	{ "Sound", "Áudio", "sound", "Áudio.", "som" }, { "SoundGroup", "Áudio", "sound", "Grupo de volume.", "" },
	{ "EchoSoundEffect", "Áudio", "soundfx", "Eco.", "" }, { "ReverbSoundEffect", "Áudio", "soundfx", "Reverberação.", "" },
	{ "DistortionSoundEffect", "Áudio", "soundfx", "Distorção.", "" }, { "ChorusSoundEffect", "Áudio", "soundfx", "Coro.", "" },
	{ "CompressorSoundEffect", "Áudio", "soundfx", "Compressor.", "" }, { "EqualizerSoundEffect", "Áudio", "soundfx", "Equalizador.", "" },
	{ "FlangeSoundEffect", "Áudio", "soundfx", "Flanger.", "" }, { "PitchShiftSoundEffect", "Áudio", "soundfx", "Pitch.", "" },
	{ "TremoloSoundEffect", "Áudio", "soundfx", "Tremolo.", "" },
	{ "Humanoid", "Personagem", "characterobj", "Humanoide (vida, andar, pular).", "" }, { "Animator", "Personagem", "characterobj", "Toca animações.", "" },
	{ "AnimationController", "Personagem", "characterobj", "Controlador sem humanoid.", "" }, { "Animation", "Personagem", "characterobj", "Clip de animação (id).", "" },
	{ "BodyColors", "Personagem", "characterobj", "Cores do corpo R6.", "" }, { "Shirt", "Personagem", "characterobj", "Camisa.", "roupa" },
	{ "Pants", "Personagem", "characterobj", "Calça.", "" }, { "ShirtGraphic", "Personagem", "characterobj", "Camiseta (graphic).", "" },
	{ "Accessory", "Personagem", "characterobj", "Acessório (hat etc).", "chapeu" }, { "Hat", "Personagem", "characterobj", "Chapéu clássico.", "" },
	{ "CharacterMesh", "Personagem", "characterobj", "Malha de personagem.", "" },
	{ "WeldConstraint", "Física", "constraint", "Solda duas peças.", "solda" }, { "Weld", "Física", "constraint", "Junta clássica.", "" },
	{ "Snap", "Física", "constraint", "Snap clássico.", "" }, { "Glue", "Física", "constraint", "Cola clássica.", "" },
	{ "Motor6D", "Física", "constraint", "Junta animável (Transform).", "" }, { "Motor", "Física", "constraint", "Motor clássico.", "" },
	{ "NoCollisionConstraint", "Física", "constraint", "Anula colisão entre duas peças.", "" }, { "RigidConstraint", "Física", "constraint", "Ligação rígida por attachments.", "" },
	{ "HingeConstraint", "Física", "constraint", "Dobradiça/motor.", "motor" }, { "BallSocketConstraint", "Física", "constraint", "Junta esférica.", "" },
	{ "PrismaticConstraint", "Física", "constraint", "Deslizante linear.", "" }, { "CylindricalConstraint", "Física", "constraint", "Cilíndrica (desliza+gira).", "" },
	{ "UniversalConstraint", "Física", "constraint", "Universal.", "" }, { "SpringConstraint", "Física", "constraint", "Mola.", "mola" },
	{ "RopeConstraint", "Física", "constraint", "Corda.", "corda" }, { "AlignPosition", "Física", "constraint", "Alinha posição.", "" },
	{ "AlignOrientation", "Física", "constraint", "Alinha rotação.", "" }, { "VectorForce", "Física", "constraint", "Força vetorial.", "" },
	{ "LineForce", "Física", "constraint", "Força em linha (ímã).", "" }, { "Torque", "Física", "constraint", "Torque.", "" },
	{ "AngularVelocity", "Física", "constraint", "Velocidade angular.", "" }, { "LinearVelocity", "Física", "constraint", "Velocidade linear.", "" },
	{ "BodyVelocity", "Física", "legacyphys", "Velocidade (legacy).", "" }, { "BodyGyro", "Física", "legacyphys", "Giroscópio (legacy).", "" },
	{ "BodyPosition", "Física", "legacyphys", "Posição (legacy).", "" }, { "BodyForce", "Física", "legacyphys", "Força (legacy).", "" },
	{ "BodyThrust", "Física", "legacyphys", "Empuxo (legacy).", "" }, { "BodyAngularVelocity", "Física", "legacyphys", "Vel. angular (legacy).", "" },
	{ "RocketPropulsion", "Física", "legacyphys", "Propulsão foguete (legacy).", "" },
	{ "ProximityPrompt", "Gameplay", "prompt", "Interação de proximidade.", "interagir" }, { "ClickDetector", "Gameplay", "detector", "Detector de clique.", "clique" },
	{ "Tool", "Gameplay", "tool", "Ferramenta de mão.", "ferramenta" }, { "HopperBin", "Gameplay", "tool", "HopperBin clássico.", "" },
	{ "Dialog", "Gameplay", "detector", "Diálogo NPC.", "" }, { "DialogChoice", "Gameplay", "prompt", "Opção de diálogo.", "" },
	{ "ForceField", "Gameplay", "effectmodel", "Campo de força no personagem.", "" },
	{ "RemoteEvent", "Rede", "net", "Evento cliente-servidor.", "" }, { "RemoteFunction", "Rede", "net", "Requisição c/s com retorno.", "" },
	{ "BindableEvent", "Rede", "net", "Evento interno.", "" }, { "BindableFunction", "Rede", "net", "Função interna.", "" },
	{ "UnreliableRemoteEvent", "Rede", "net", "Evento rede não-confiável (rápido).", "" },
	{ "BoolValue", "Valores", "value", "Armazena bool.", "" }, { "IntValue", "Valores", "value", "Armazena int.", "" },
	{ "NumberValue", "Valores", "value", "Armazena número.", "" }, { "StringValue", "Valores", "value", "Armazena texto.", "" },
	{ "ObjectValue", "Valores", "value", "Referencia objeto.", "" }, { "BrickColorValue", "Valores", "value", "Armazena BrickColor.", "" },
	{ "Color3Value", "Valores", "value", "Armazena Color3.", "cor" }, { "CFrameValue", "Valores", "value", "Armazena CFrame.", "" },
	{ "Vector3Value", "Valores", "value", "Armazena Vector3.", "" },
	{ "Camera", "Render", "cameraobj", "Câmera.", "" }, { "PathfindingModifier", "Nav", "geometry2", "Modifica navmesh.", "" },
	{ "Message", "Legado", "legacy", "Mensagem na tela (antiga).", "" }, { "Hint", "Legado", "legacy", "Dica na tela (antiga).", "" },
	{ "StarterGear", "Legado", "legacy", "Item inicial.", "" },
	{ "Sky", "Ambiente", "sky2", "Céu ( Lighting ).", "" }, { "Decal", "Aparência", "surface", "Decal em face.", "" },
	{ "StyleSheet", "UI", "component2", "Folha de estilo (UI).", "" },
}
-- dedupe + registro por classe
local CATALOG_BYCLASS, CATALOG_SEEN = {}, {}
local CATALOG_ITEMS = {}
for _, row in ipairs(CLASS_CATALOG) do
	if not CATALOG_SEEN[row[1]] then
		CATALOG_SEEN[row[1]] = true
		CATALOG_ITEMS[#CATALOG_ITEMS + 1] = { class = row[1], cat = row[2], group = row[3], desc = row[4], alias = row[5] }
		CATALOG_BYCLASS[row[1]] = row[3]
	end
end

function handlers.ClassList(player, payload)
	return { items = CATALOG_ITEMS, count = #CATALOG_ITEMS }
end

local function defaultParentFor(class, player)
	-- ScreenGui -> StarterGui, Lighting children -> Lighting, valores/remote -> ReplicatedStorage
	local Lighting = game:GetService("Lighting")
	if class == "ScreenGui" then return game:GetService("StarterGui") end
	if CATALOG_BYCLASS[class] == "sky" or CATALOG_BYCLASS[class] == "postfx" or CATALOG_BYCLASS[class] == "sky2" then return Lighting end
	if class == "MaterialVariant" then return game:GetService("MaterialService") end
	if class == "SoundEffect" then return game:GetService("SoundService") end
	return nil
end

function handlers.CreateAny(player, payload)
	pipeStats.creates=pipeStats.creates+1
	local class = tostring(payload.class or "")
	assert(#class > 0 and class:match("^%a[%w]*$"), "Classe inválida.")
	local parent = nil
	if payload.parentId and objects[payload.parentId] then
		parent = objects[payload.parentId]
	elseif CATALOG_BYCLASS[class] then
		parent = defaultParentFor(class, player)
	end
	if not parent then
		if not parent and type(payload.parentName) == "string" then
		local okSvc, svc = pcall(function() return game:GetService(payload.parentName) end)
		if okSvc and svc ~= nil then parent = svc end
		if parent == nil and payload.parentName == "Workspace" then parent = workspace end
		if parent ~= nil and parent ~= workspace then local okEd = false; pcall(function() okEd = editable(parent) end); if not okEd then parent = nil end end
	end
	local sel2 = selected[player]
	if sel2 and sel2.Parent and editable(sel2) then parent = sel2 else parent = workspace end
	end
	assert(editable(parent) or parent == workspace, "Pai protegido.")
	-- pcall REAL: deixa o motor decidir se a classe existe/é instanciável
	local okNew, o = pcall(function() return Instance.new(class) end)
	if not okNew then
		return { error = "Classe '" .. class .. "' não é instanciável nesta versão do Roblox: " .. tostring(o) }
	end
	-- defaults seguros antes do parent (ordem do ORIG)
	local okDef = pcall(function()
		local base = type(payload.name) == "string" and #payload.name > 0 and payload.name or class
		local unique, ix = base, 1
		while parent:FindFirstChild(unique) do unique = base .. ix; ix = ix + 1 end
		o.Name = unique
		if o:IsA("BasePart") then
			o.Anchored = true
			o.Size = Vector3.new(4, 1, 2)
			o.Color = Color3.fromRGB(129, 184, 242)
			if parent:IsA("BasePart") then o.CFrame = parent.CFrame * CFrame.new(0, parent.Size.Y / 2 + 1, 0)
			elseif parent.ClassName == "Model" then o.CFrame = parent:GetPivot() * CFrame.new(0, 3, 0)
			else o.CFrame = CFrame.new(0, 5, 0) end
		elseif o:IsA("BaseScript") then o.Enabled = false
		elseif o:IsA("ScreenGui") then o.ResetOnSpawn = false
		elseif o:IsA("GuiObject") then
			o.Size = UDim2.fromOffset(200, 60)
			o.Position = UDim2.fromOffset(24, 24)
			o.BackgroundColor3 = Color3.fromRGB(20, 45, 80)
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				o.Text = class; o.TextColor3 = Color3.new(1, 1, 1); o.TextSize = 20
			end
		elseif o:IsA("Tool") then o.RequiresHandle = false end
		o.Parent = parent
	end)
	if not okDef then
		local errP = o:GetFullName()
		o:Destroy()
		return { error = "Roblox recusou '" .. class .. "' em " .. parent:GetFullName() .. " (parent inválido p/ essa classe)." }
	end
	if not o.Parent then
		o:Destroy()
		return { error = "Roblox recusou '" .. class .. "' em " .. parent:GetFullName() .. " (parent inválido p/ essa classe)." }
	end
	register(o)
	created[o] = true
	selected[player] = o
	pcall(function() queueObject(parent) end)
	pcall(function() hCreate(player, o) end)
	return { id = idOf[o], className = class, parent = parent:GetFullName(), node = record(o), msg = class .. " criado em " .. parent.Name .. " (selecionado)." }
end

-- ============ RUN REAL (Play/Pause/Stop de verdade) ============
local RUN = { running = false, frozen = false, parts = {}, vels = {}, sounds = {} }

-- R7 SHELL2: service props (sim) + voxel smooth/noise (terrain panel).
local SVC_ALLOW = { Lighting = true, Workspace = true, Terrain = true }
function handlers.SvcSet(player, payload)
	local svc = tostring(payload.service or "")
	assert(SVC_ALLOW[svc], "Servico invalido.")
	local o = game:GetService(svc)
	local name = tostring(payload.name or "")
	assert(#name > 0 and #name < 60, "Prop invalida.")
	local kind = tostring(payload.kind or "s")
	local val = coerceProp(o, name, kind, payload.value)
	local okOld, old = pcall(function() return o[name] end)
	if not okOld then return { error = "Propriedade nao existe: " .. name } end
	local okSet, errSet = pcall(function() o[name] = val end)
	if not okSet then return { error = "Roblox recusou " .. name .. ": " .. tostring(errSet) } end
	local okNew, new0 = pcall(function() return o[name] end)
	if okOld and okNew and tostring(old) ~= tostring(new0) then
		pcall(function() hSet(player, o, name, old, new0) end)
	end
	pcall(function() queueObject(o) end)
	return { ok = true, applied = svc .. "." .. name, now = tostring(new0) }
end
local function smoothRegion(center, r)
	local ter = terrainOrFail()
	local minP = center - Vector3.new(r, r, r)
	local maxP = center + Vector3.new(r, r, r)
	local region = Region3.new(minP, maxP):ExpandToGrid(4)
	local mats, occs = ter:ReadVoxels(region, 4)
	return ter, region, mats, occs
end
function handlers.TerrainSmooth(player, payload)
	local ctr = terrainCenter(payload.center, player)
	local r = math.clamp(tonumber(payload.radius) or 16, 4, 32)
	local ter, region, mats, occs = smoothRegion(ctr, r)
	local sx, sy, sz = #occs, #occs[1], #occs[1][1]
	local out = {}
	for x = 1, sx do
		out[x] = {}
		for y = 1, sy do
			out[x][y] = {}
			for z = 1, sz do
				local sum, n = 0, 0
				for dx = -1, 1 do
					for dy = -1, 1 do
						for dz = -1, 1 do
							local xx, yy, zz = x + dx, y + dy, z + dz
							if occs[xx] and occs[xx][yy] and occs[xx][yy][zz] then
								sum, n = sum + occs[xx][yy][zz], n + 1
							end
						end
					end
				end
				out[x][y][z] = (n > 0) and (sum / n) or occs[x][y][z]
			end
		end
	end
	ter:WriteVoxels(region, 4, mats, out)
	return { msg = ("Smooth r=%s aplicado."):format(tostring(r)) }
end
function handlers.TerrainNoise(player, payload)
	local ctr = terrainCenter(payload.center, player)
	local r = math.clamp(tonumber(payload.radius) or 16, 4, 32)
	local force = math.clamp(tonumber(payload.force) or 50, 0, 100)
	local ter, region, mats, occs = smoothRegion(ctr, r)
	local sx, sy, sz = #occs, #occs[1], #occs[1][1]
	local lo = region.Min
	for x = 1, sx do
		for y = 1, sy do
			for z = 1, sz do
				local wx = lo.X + (x - 1) * 4
				local wy = lo.Y + (y - 1) * 4
				local wz = lo.Z + (z - 1) * 4
				local nz = math.noise or function() return 0.25 end
				local n2 = nz(wx * 0.05, wy * 0.05, wz * 0.05)
				local v = occs[x][y][z] + n2 * (force / 100)
				occs[x][y][z] = math.clamp(v, 0, 1)
			end
		end
	end
	ter:WriteVoxels(region, 4, mats, occs)
	return { msg = ("Noise r=%s f=%s aplicado."):format(tostring(r), tostring(force)) }
end
-- ============ R10: Terrain Editor engine (pincel real sobre voxels) ============
-- Mesma API no jogo e no mock (Fill/Read/Write/Replace/Copy/Paste). Grid 4,
-- res 4, regions alinhadas (ExpandToGrid), limite 4M voxels (docs Terrain).
local TER_TOOLS = { draw = true, sculpt = true, raise = true, lower = true,
  flatten = true, smooth = true, erode = true, crater = true, paint = true,
  replace = true, water = true, drain = true }
local function terHash(x, y, z, seed)
  local h = (x * 374761393 + y * 668265263 + z * 2147483647 + seed * 1442695041) % 4294967296
  h = (h * 668265263 + 1274126177) % 4294967296
  return (math.floor(h / 65536) % 32768) / 32767
end
local function terVNoise(x, y, z, seed)
  local xi, yi, zi = math.floor(x), math.floor(y), math.floor(z)
  local xf, yf, zf = x - xi, y - yi, z - zi
  local s = function(t) return t * t * (3 - 2 * t) end
  local u, v, w = s(xf), s(yf), s(zf)
  local c000 = terHash(xi, yi, zi, seed) local c100 = terHash(xi + 1, yi, zi, seed)
  local c010 = terHash(xi, yi + 1, zi, seed) local c110 = terHash(xi + 1, yi + 1, zi, seed)
  local c001 = terHash(xi, yi, zi + 1, seed) local c101 = terHash(xi + 1, yi, zi + 1, seed)
  local c011 = terHash(xi, yi + 1, zi + 1, seed) local c111 = terHash(xi + 1, yi + 1, zi + 1, seed)
  local x00 = c000 + (c100 - c000) * u local x10 = c010 + (c110 - c010) * u
  local x01 = c001 + (c101 - c001) * u local x11 = c011 + (c111 - c011) * u
  local y0 = x00 + (x10 - x00) * v local y1 = x01 + (x11 - x01) * v
  return y0 + (y1 - y0) * w
end
local function terFbm(x, z, seed, oct)
  local amp, f, sum, norm = 0.5, 1 / 48, 0, 0
  for i = 1, (oct or 4) do
    sum = sum + amp * terVNoise(x * f, seed * 0.731 + i * 17.3, z * f, seed + i * 101)
    norm = norm + amp amp = amp * 0.5 f = f * 2
  end
  return sum / math.max(norm, 1e-6)
end
local function terWeight(d, falloff, hardness)
  if d >= 1 then return 0 end
  if d <= hardness then return 1 end
  local t = (d - hardness) / math.max(1 - hardness, 1e-6)
  local s = t * t * (3 - 2 * t)
  return (1 - s) ^ (0.5 + falloff * 2)
end
local function terCenters(ctr, sym)
  sym = tostring(sym or "none")
  local list = { { x = ctr.x, y = ctr.y, z = ctr.z } }
  if sym == "x" or sym == "xz" then list[#list + 1] = { x = -ctr.x, y = ctr.y, z = ctr.z } end
  if sym == "z" or sym == "xz" then list[#list+1] = { x = ctr.x, y = ctr.y, z = -ctr.z } end
  if sym == "xz" then list[#list + 1] = { x = -ctr.x, y = ctr.y, z = -ctr.z } end
  return list
end
local TERD = { UNDO = {}, REDO = {}, STROKES = {} }
local function terSnap(ter, r3)
  local mn = r3.Min
  local bx, by, bz = mn.X / 4, mn.Y / 4, mn.Z / 4
  local ri = Region3int16.new(Vector3int16.new(bx, by, bz), Vector3int16.new(
    bx + (r3.Max.X - mn.X) / 4 - 1, by + (r3.Max.Y - mn.Y) / 4 - 1, bz + (r3.Max.Z - mn.Z) / 4 - 1))
  local ok, treg = pcall(function() return ter:CopyRegion(ri) end)
  if not ok then return nil end
  return { corner = { bx, by, bz }, treg = treg,
    sizeX = (r3.Max.X - mn.X) / 4, sizeY = (r3.Max.Y - mn.Y) / 4, sizeZ = (r3.Max.Z - mn.Z) / 4 }
end
local function terRestore(ter, snap)
  ter:PasteRegion(snap.treg, Vector3int16.new(snap.corner[1], snap.corner[2], snap.corner[3]), true)
end
local function terPushUndo(label, snaps)
  TERD.UNDO[#TERD.UNDO + 1] = { label = label, snaps = snaps }
  if #TERD.UNDO > 50 then table.remove(TERD.UNDO, 1) end
  TERD.REDO = {}
end
-- aplica 1 dab (read -> modifica -> write). p: tool,cx,cy,cz,radius,strength,
-- material,falloff,hardness,noise,seed,planeY,source
local function terApplyDab(ter, p)
  local r = math.clamp(tonumber(p.radius) or 8, 1, 64)
  local s = math.clamp(tonumber(p.strength) or 0.5, 0, 1)
  local fall = math.clamp(tonumber(p.falloff) or 0.5, 0, 1)
  local hard = math.clamp(tonumber(p.hardness) or 0.5, 0, 1)
  local nz = math.clamp(tonumber(p.noise) or 0, 0, 1)
  local seed = math.floor(tonumber(p.seed) or 1)
  local mat = terrainMat(p.material or "Grass")
  local r3 = Region3.new(
    Vector3.new(p.cx - r - 4, p.cy - r - 4, p.cz - r - 4),
    Vector3.new(p.cx + r + 4, p.cy + r + 4, p.cz + r + 4)):ExpandToGrid(4)
  local snap = terSnap(ter, r3)
  local ch = ter:ReadVoxelChannels(r3, 4, { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" })
  local size = ch.Size
  local sx, sy, sz = size.X, size.Y, size.Z
  local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
  local OC = nil
  if p.tool == "smooth" then
    OC = {}
    for x = 1, sx do OC[x] = {} for y = 1, sy do OC[x][y] = {}
      for z = 1, sz do OC[x][y][z] = SO[x][y][z] end end end
  end
  local touched = 0
  local lo = r3.Min
  local planeY = tonumber(p.planeY) or p.cy
  local srcN = p.source and terrainMat(p.source).Name or nil
  local AIR = Enum.Material.Air
  for x = 1, sx do
    local wx = lo.X + (x - 1) * 4 + 2
    for y = 1, sy do
      local wy = lo.Y + (y - 1) * 4 + 2
      for z = 1, sz do
        local wz = lo.Z + (z - 1) * 4 + 2
        local dx, dy, dz = wx - p.cx, wy - p.cy, wz - p.cz
        local d = math.sqrt(dx * dx + dy * dy + dz * dz) / r
        if d <= 1 then
          local w = terWeight(d, fall, hard)
          if nz > 0 then
            w = w * (1 - nz * 0.5 + nz * terVNoise(wx * 0.11, wy * 0.11, wz * 0.11, seed))
          end
          if w > 0.001 then
            local m = SM[x][y][z]
            local mN = (type(m) == "table" and m.Name) or "Air"
            local o = SO[x][y][z]
            local tool = p.tool
            if tool == "draw" then
              local no = math.min(1, o + s * w)
              if no > 0 and o <= 0 then SM[x][y][z] = mat end
              SO[x][y][z] = no
            elseif tool == "sculpt" then
              local no = math.max(0, o - s * w * 2)
              SO[x][y][z] = no
              if no <= 0 then SM[x][y][z] = AIR end
            elseif tool == "raise" then
              local no = math.min(1, o + s * w * 0.5)
              if no > 0 and o <= 0 then SM[x][y][z] = mat end
              SO[x][y][z] = no
            elseif tool == "lower" then
              local no = math.max(0, o - s * w * 0.5)
              SO[x][y][z] = no
              if no <= 0 then SM[x][y][z] = AIR end
            elseif tool == "flatten" then
              local target = math.clamp((planeY - wy) / 4 + 0.5, 0, 1)
              local no = o + (target - o) * s * w
              if no > 0.001 and o <= 0.001 then SM[x][y][z] = mat end
              if no <= 0.001 then SM[x][y][z] = AIR no = 0 end
              SO[x][y][z] = math.clamp(no, 0, 1)
            elseif tool == "smooth" then
              local sum, n = 0, 0
              for ax = -1, 1 do for ay = -1, 1 do for az = -1, 1 do
                local rx = OC[x + ax]
                if rx and rx[y + ay] and rx[y + ay][z + az] then
                  sum = sum + rx[y + ay][z + az] n = n + 1
                end
              end end end
              if n > 0 then SO[x][y][z] = o + (sum / n - o) * s * w end
            elseif tool == "erode" then
              local n2 = terVNoise(wx * 0.23, wy * 0.23, wz * 0.23, seed + 7)
              local no = math.max(0, o - s * w * (0.3 + 0.7 * n2))
              SO[x][y][z] = no
              if no <= 0 then SM[x][y][z] = AIR end
            elseif tool == "crater" then
              local cw = (d < 0.7) and (1 - d / 0.7) or 0
              local rim = math.exp(-(((d - 0.75) / 0.18) ^ 2))
              local no = math.clamp(o - s * cw * 1.5 + s * rim * 0.9, 0, 1)
              if no > 0 and o <= 0 then SM[x][y][z] = mat end
              if no <= 0 then SM[x][y][z] = AIR end
              SO[x][y][z] = no
            elseif tool == "paint" then
              if o > 0 and mN ~= "Air" then SM[x][y][z] = mat end
            elseif tool == "replace" then
              if o > 0 and (not srcN or mN == srcN) then SM[x][y][z] = mat end
            elseif tool == "water" then
              if o < 1 then LO[x][y][z] = math.min(1, LO[x][y][z] + s * w) end
            elseif tool == "drain" then
              LO[x][y][z] = math.max(0, LO[x][y][z] - s * w * 2)
            end
            touched = touched + 1
          end
        end
      end
    end
  end
  ter:WriteVoxelChannels(r3, 4, { SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO })
  return { snap = snap, touched = touched }
end
-- camadas nao-destrutivas: regiao fixa + snapshot base + ops (re-execucao).
-- Regioes nao podem sobrepor (garante correcao do hide/show).
TERD.LAYERS = {}
local function terLayerFind(name)
  for _, L in ipairs(TERD.LAYERS) do if L.name == name then return L end end
  return nil
end
local function terBoxOverlap(a, b)
  return a.x0 < b.x1 and a.x1 > b.x0 and a.z0 < b.z1 and a.z1 > b.z0
end
function handlers.TerrainStroke(player, payload)
  local tool = tostring(payload.tool or "")
  assert(TER_TOOLS[tool], "tool invalida (draw/sculpt/raise/lower/flatten/smooth/erode/crater/paint/replace/water/drain).")
  local ctr = terrainCenter(payload.center, player)
  local ter = terrainOrFail()
  if payload.apply == false then
    local ST = TERD.STROKES[player]
    if ST and #ST.snaps > 0 then
      terPushUndo(tool .. " (stroke)", ST.snaps)
      TERD.STROKES[player] = nil
      return { msg = "Stroke fechado.", dabs = #ST.snaps }
    end
    return { msg = "Stroke vazio.", dabs = 0 }
  end
  local p = { tool = tool, radius = payload.radius, strength = payload.strength,
    material = payload.material, falloff = payload.falloff, hardness = payload.hardness,
    noise = payload.noise, seed = payload.seed, planeY = payload.planeY, source = payload.source }
  local snaps, touched, dabs = {}, 0, 0
  for _, c in ipairs(terCenters({ x = ctr.X, y = ctr.Y, z = ctr.Z }, payload.symmetry)) do
    p.cx, p.cy, p.cz = c.x, c.y, c.z
    local r1 = terApplyDab(ter, p)
    if r1.snap then snaps[#snaps + 1] = r1.snap end
    touched = touched + r1.touched dabs = dabs + 1
  end
  local mode = tostring(payload.stroke or "")
  if mode == "" or mode == "single" then
    terPushUndo(tool, snaps)
  else
    local ST = TERD.STROKES[player] or { snaps = {} }
    TERD.STROKES[player] = ST
    if mode == "begin" then ST.snaps = snaps
    else for _, s in ipairs(snaps) do ST.snaps[#ST.snaps + 1] = s end end
    if mode == "end" then
      terPushUndo(tool .. " (stroke)", ST.snaps)
      TERD.STROKES[player] = nil
    end
  end
  local recorded = terLayerRecord(ter, payload, p, ctr)
  return { msg = ("%s: %d voxels (%d dab)."):format(tool, touched, dabs),
    touched = touched, dabs = dabs, recorded = recorded }
end
function handlers.TerrainUndo(player)
  local e = table.remove(TERD.UNDO)
  assert(e, "Nada p/ desfazer no terreno.")
  local ter = terrainOrFail()
  local redo = { label = e.label, snaps = {} }
  for _, s in ipairs(e.snaps) do
    local r3 = Region3.new(
      Vector3.new(s.corner[1] * 4, s.corner[2] * 4, s.corner[3] * 4),
      Vector3.new((s.corner[1] + (s.sizeX or 8)) * 4, (s.corner[2] + (s.sizeY or 8)) * 4, (s.corner[3] + (s.sizeZ or 8)) * 4))
    local cur = terSnap(ter, r3)
    if cur then cur.sizeX, cur.sizeY, cur.sizeZ = s.sizeX, s.sizeY, s.sizeZ redo.snaps[#redo.snaps + 1] = cur end
  end
  for i = #e.snaps, 1, -1 do terRestore(ter, e.snaps[i]) end
  TERD.REDO[#TERD.REDO + 1] = redo
  return { msg = "Desfeito: " .. tostring(e.label) .. "." }
end
function handlers.TerrainRedo(player)
  local e = table.remove(TERD.REDO)
  assert(e, "Nada p/ refazer no terreno.")
  local ter = terrainOrFail()
  local undo = { label = e.label, snaps = {} }
  for _, s in ipairs(e.snaps) do
    local r3 = Region3.new(
      Vector3.new(s.corner[1] * 4, s.corner[2] * 4, s.corner[3] * 4),
      Vector3.new((s.corner[1] + (s.sizeX or 8)) * 4, (s.corner[2] + (s.sizeY or 8)) * 4, (s.corner[3] + (s.sizeZ or 8)) * 4))
    local cur = terSnap(ter, r3)
    if cur then cur.sizeX, cur.sizeY, cur.sizeZ = s.sizeX, s.sizeY, s.sizeZ undo.snaps[#undo.snaps + 1] = cur end
  end
  for i = #e.snaps, 1, -1 do terRestore(ter, e.snaps[i]) end
  TERD.UNDO[#TERD.UNDO + 1] = undo
  return { msg = "Refeito: " .. tostring(e.label) .. "." }
end
function terLayerRecord(ter, payload, p, ctr)
  local lname = tostring(payload.layer or (TERD.LAYERS[1] and TERD.LAYERS[1].name) or "")
  if lname == "" then return false end
  local L = terLayerFind(lname)
  if not L or not L.visible then return false end
  if ctr.X < L.box.x0 or ctr.X > L.box.x1 or ctr.Z < L.box.z0 or ctr.Z > L.box.z1 then return false end
  if #L.ops >= 100 then return false end
  L.ops[#L.ops + 1] = { tool = p.tool, cx = ctr.X, cy = ctr.Y, cz = ctr.Z, radius = p.radius,
    strength = p.strength, material = p.material, falloff = p.falloff, hardness = p.hardness,
    noise = p.noise, seed = p.seed, planeY = p.planeY, source = p.source, symmetry = payload.symmetry }
  return true
end
function handlers.TerrainLayer(player, payload)
  local op = tostring(payload.op or "list")
  local ter = terrainOrFail()
  if op == "list" then
    local out = {}
    for _, L in ipairs(TERD.LAYERS) do
      out[#out + 1] = { name = L.name, visible = L.visible, ops = #L.ops, box = L.box }
    end
    return { layers = out }
  elseif op == "add" then
    assert(#TERD.LAYERS < 8, "Maximo 8 camadas.")
    local nm = tostring(payload.name or ("Layer" .. (#TERD.LAYERS + 1)))
    assert(nm ~= "" and not terLayerFind(nm), "Nome de camada invalido/duplicado.")
    local cx, cz = tonumber(payload.cx) or 0, tonumber(payload.cz) or 0
    local sx, sz = math.clamp(tonumber(payload.sx) or 256, 32, 1024), math.clamp(tonumber(payload.sz) or 256, 32, 1024)
    local sy = math.clamp(tonumber(payload.sy) or 128, 32, 512)
    local box = { x0 = cx - sx / 2, x1 = cx + sx / 2, z0 = cz - sz / 2, z1 = cz + sz / 2 }
    for _, L in ipairs(TERD.LAYERS) do assert(not terBoxOverlap(box, L.box), "Regioes de camada nao podem sobrepor.") end
    local r3 = Region3.new(Vector3.new(box.x0, -64, box.z0), Vector3.new(box.x1, -64 + sy, box.z1)):ExpandToGrid(4)
    local base = terSnap(ter, r3)
    assert(base, "Falha no snapshot base da camada.")
    TERD.LAYERS[#TERD.LAYERS + 1] = { name = nm, visible = true, ops = {}, box = box, sy = sy, base = base, region = r3 }
    return { msg = "Camada " .. nm .. " criada.", layers = #TERD.LAYERS }
  elseif op == "toggle" or op == "show" or op == "hide" then
    local L = terLayerFind(tostring(payload.name or ""))
    assert(L, "Camada nao encontrada.")
    local want = (op == "show") and true or (op == "hide") and false or (not L.visible)
    if want == L.visible then return { msg = "Camada " .. L.name .. " ja estava " .. (want and "visivel." or "oculta.") } end
    local pre = terSnap(ter, L.region)
    terRestore(ter, L.base)
    L.visible = want
    if want then for _, o in ipairs(L.ops) do terApplyDab(ter, o) end end
    if pre then terPushUndo("layer:" .. L.name, { pre }) end
    return { msg = "Camada " .. L.name .. (want and " visivel." or " oculta."), visible = want }
  elseif op == "remove" then
    local L = terLayerFind(tostring(payload.name or ""))
    assert(L, "Camada nao encontrada.")
    for i, v in ipairs(TERD.LAYERS) do if v == L then table.remove(TERD.LAYERS, i) break end end
    return { msg = "Camada " .. L.name .. " removida (voxels mantidos)." }
  elseif op == "clear" then
    local L = terLayerFind(tostring(payload.name or ""))
    assert(L, "Camada nao encontrada.")
    local pre = terSnap(ter, L.region)
    terRestore(ter, L.base)
    L.ops = {}
    L.visible = true
    if pre then terPushUndo("layer-clear:" .. L.name, { pre }) end
    return { msg = "Camada " .. L.name .. " limpa (voltou ao base)." }
  end
  assert(false, "op: list/add/toggle/show/hide/remove/clear.")
end
TERD.BIOMES = {
  meadow = { top = "Grass", topHigh = "Snow", shore = "Sand", mid = "Ground", deep = "Rock" },
  desert = { top = "Sand", topHigh = "Sandstone", shore = "Sand", mid = "Sandstone", deep = "Rock" },
  arctic = { top = "Snow", topHigh = "Glacier", shore = "Ice", mid = "Rock", deep = "Slate" },
  volcanic = { top = "Basalt", topHigh = "Basalt", shore = "CrackedLava", mid = "Basalt", deep = "Rock" },
}
function handlers.TerrainGen(player, payload)
  local seed = math.floor(tonumber(payload.seed) or 1)
  local size = math.clamp(math.floor(tonumber(payload.size) or 256), 64, 512)
  local height = math.clamp(math.floor(tonumber(payload.height) or 48), 8, 128)
  local cx, cz = tonumber(payload.cx) or 0, tonumber(payload.cz) or 0
  local baseY = math.floor(tonumber(payload.baseY) or 0)
  local biome = TERD.BIOMES[tostring(payload.biome or "meadow")] or TERD.BIOMES.meadow
  local waterLevel = payload.waterLevel and math.floor(tonumber(payload.waterLevel)) or nil
  local passes = math.clamp(math.floor(tonumber(payload.erosion) or 1), 0, 3)
  local ter = terrainOrFail()
  local n = size / 4
  local H = {}
  for ix = 1, n do H[ix] = {} for iz = 1, n do
    H[ix][iz] = baseY + (terFbm(cx + (ix - 1) * 4, cz + (iz - 1) * 4, seed, 4) ^ 1.2) * height
  end end
  for _ = 1, passes do
    for ix = 1, n do for iz = 1, n do
      local lo, li, lz = H[ix][iz], ix, iz
      if ix > 1 and H[ix-1][iz] < lo then lo, li, lz = H[ix-1][iz], ix-1, iz end
      if ix < n and H[ix+1][iz] < lo then lo, li, lz = H[ix+1][iz], ix+1, iz end
      if iz > 1 and H[ix][iz-1] < lo then lo, li, lz = H[ix][iz-1], ix, iz-1 end
      if iz < n and H[ix][iz+1] < lo then lo, li, lz = H[ix][iz+1], ix, iz+1 end
      local slope = H[ix][iz] - lo
      if slope > 5 then
        local mv = (slope - 5) * 0.25
        H[ix][iz] = H[ix][iz] - mv H[li][lz] = H[li][lz] + mv
      end
    end end
  end
  local topY = baseY + height + 8
  local r3 = Region3.new(Vector3.new(cx - size / 2, -64, cz - size / 2),
    Vector3.new(cx + size / 2, topY, cz + size / 2)):ExpandToGrid(4)
  local snap = terSnap(ter, r3)
  local lo = r3.Min
  local sx = (r3.Max.X - lo.X) / 4
  local sy = (r3.Max.Y - lo.Y) / 4
  local sz = (r3.Max.Z - lo.Z) / 4
  local SM, SO, LO = {}, {}, {}
  local minH, maxH, waterCells, cells = 1e9, -1e9, 0, 0
  for x = 1, sx do SM[x], SO[x], LO[x] = {}, {}, {} end
  for ix = 1, n do for iz = 1, n do
    local h = H[ix][iz]
    if h < minH then minH = h end
    if h > maxH then maxH = h end
    local surf = biome.top
    if waterLevel and h < waterLevel + 4 then surf = biome.shore end
    if h > baseY + height * 0.78 then surf = biome.topHigh end
    for y = 1, sy do
      local wy0 = lo.Y + (y - 1) * 4
      local d = h - wy0
      local gm = Enum.Material.Air
      local go, gw = 0, 0
      if d >= 4 then
        go = 1
        gm = Enum.Material[(h - wy0 > 12 and ((h - wy0 > 24 and biome.deep) or biome.mid)) or surf]
      elseif d > 0 then
        go = math.max(d / 4, 0.15) gm = Enum.Material[surf]
      elseif waterLevel and wy0 < waterLevel then
        gw = 1
      end
      SM[ix][y], SO[ix][y], LO[ix][y] = SM[ix][y] or {}, SO[ix][y] or {}, LO[ix][y] or {}
      SM[ix][y][iz], SO[ix][y][iz], LO[ix][y][iz] = gm, go, gw
      if go > 0 then cells = cells + 1 end
      if gw > 0 then waterCells = waterCells + 1 end
    end
  end end
  -- preenche colunas fora do grid n (bordas do ExpandToGrid): ar
  for x = n + 1, sx do for y = 1, sy do SM[x][y], SO[x][y], LO[x][y] = {}, {}, {}
    for z = 1, sz do SM[x][y][z], SO[x][y][z], LO[x][y][z] = Enum.Material.Air, 0, 0 end end end
  for x = 1, n do for y = 1, sy do for z = n + 1, sz do
    SM[x][y][z], SO[x][y][z], LO[x][y][z] = Enum.Material.Air, 0, 0
  end end end
  ter:WriteVoxelChannels(r3, 4, { SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO })
  if snap then terPushUndo("gen", { snap }) end
  return { msg = ("Gerado seed=%d (%dx%d, %d voxels, %d agua)."):format(seed, size, size, cells, waterCells),
    cells = cells, waterCells = waterCells, minH = math.floor(minH), maxH = math.floor(maxH) }
end
function handlers.TerrainWaterProps(player, payload)
  local ter = terrainOrFail()
  local echo = {}
  if payload.transparency ~= nil then
    ter.WaterTransparency = math.clamp(tonumber(payload.transparency) or 0.3, 0, 1)
    echo.transparency = ter.WaterTransparency
  end
  if payload.reflectance ~= nil then
    ter.WaterReflectance = math.clamp(tonumber(payload.reflectance) or 1, 0, 1)
    echo.reflectance = ter.WaterReflectance
  end
  if payload.waveSize ~= nil then
    ter.WaterWaveSize = math.clamp(tonumber(payload.waveSize) or 0, 0, 1)
    echo.waveSize = ter.WaterWaveSize
  end
  if payload.waveSpeed ~= nil then
    ter.WaterWaveSpeed = math.clamp(tonumber(payload.waveSpeed) or 10, 0, 100)
    echo.waveSpeed = ter.WaterWaveSpeed
  end
  if payload.color then
    local c = payload.color
    ter.WaterColor = Color3.fromRGB(math.clamp(tonumber(c.r) or 13, 0, 255),
      math.clamp(tonumber(c.g) or 84, 0, 255), math.clamp(tonumber(c.b) or 92, 0, 255))
    local wc = ter.WaterColor
    echo.color = { math.floor(wc.R * 255), math.floor(wc.G * 255), math.floor(wc.B * 255) }
  end
  if payload.decoration ~= nil then ter.Decoration = not not payload.decoration echo.decoration = ter.Decoration end
  if payload.grass ~= nil then ter.GrassLength = math.clamp(tonumber(payload.grass) or 0.5, 0.1, 1) echo.grass = ter.GrassLength end
  return { msg = "Agua/vegetacao atualizadas.", props = echo }
end
function handlers.TerrainRain(player, payload)
  local on = not not payload.on
  local old = workspace:FindFirstChild("ArkherRainRig")
  if old then pcall(function() old:Destroy() end) end
  if not on then return { msg = "Chuva desligada.", on = false } end
  local cx, cz = tonumber(payload.cx) or 0, tonumber(payload.cz) or 0
  local r = math.clamp(tonumber(payload.radius) or 64, 16, 256)
  local rig = Instance.new("Part")
  rig.Name = "ArkherRainRig"
  rig.Size = Vector3.new(r * 2, 1, r * 2)
  rig.CFrame = CFrame.new(cx, 140, cz)
  rig.Anchored = true rig.CanCollide = false rig.Transparency = 1
  rig.Parent = workspace
  local em = Instance.new("ParticleEmitter")
  em.Rate = math.clamp(math.floor(r * r / 4), 100, 2000)
  em.Speed = 90
  em.Enabled = true
  em.Parent = rig
  return { msg = ("Chuva ligada (rate %d)."):format(em.Rate), on = true }
end
function handlers.TerrainFlood(player, payload)
  local y = math.floor(tonumber(payload.y) or 8)
  assert(y >= -64 and y <= 512, "y -64..512.")
  local cx, cz = tonumber(payload.cx) or 0, tonumber(payload.cz) or 0
  local sx = math.clamp(math.floor(tonumber(payload.sx) or 128), 16, 1024)
  local sz = math.clamp(math.floor(tonumber(payload.sz) or 128), 16, 1024)
  local ter = terrainOrFail()
  local r3 = Region3.new(Vector3.new(cx - sx / 2, y - 8, cz - sz / 2),
    Vector3.new(cx + sx / 2, y, cz + sz / 2)):ExpandToGrid(4)
  local snap = terSnap(ter, r3)
  ter:FillRegion(r3, 4, Enum.Material.Water)
  if snap then terPushUndo("flood", { snap }) end
  return { msg = ("Enchente ate y=%d (%dx%d)."):format(y, sx, sz) }
end
function handlers.TerrainHydro(player, payload)
  local cx, cz = tonumber(payload.cx) or 0, tonumber(payload.cz) or 0
  local sx = math.clamp(math.floor(tonumber(payload.sx) or 128), 16, 512)
  local sz = math.clamp(math.floor(tonumber(payload.sz) or 128), 16, 512)
  local sy = math.clamp(math.floor(tonumber(payload.sy) or 64), 16, 256)
  local y0 = math.floor(tonumber(payload.y0) or -32)
  local ter = terrainOrFail()
  local r3 = Region3.new(Vector3.new(cx - sx / 2, y0, cz - sz / 2),
    Vector3.new(cx + sx / 2, y0 + sy, cz + sz / 2)):ExpandToGrid(4)
  local cells = ((r3.Max.X - r3.Min.X) / 4) * ((r3.Max.Y - r3.Min.Y) / 4) * ((r3.Max.Z - r3.Min.Z) / 4)
  assert(cells <= 250000, "Setor grande demais p/ diagnostico (250k voxels).")
  local ch = ter:ReadVoxelChannels(r3, 4, { "LiquidOccupancy" })
  local size = ch.Size
  local waterCells, maxDepth = 0, 0
  for x = 1, size.X do for z = 1, size.Z do
    local depth = 0
    for y = 1, size.Y do
      if ch.LiquidOccupancy[x][y][z] > 0.05 then waterCells = waterCells + 1 depth = depth + 1 end
    end
    if depth > maxDepth then maxDepth = depth end
  end end
  return { waterCells = waterCells, volume = waterCells * 64, maxDepth = maxDepth * 4,
    msg = ("Agua: %d voxels, %d studs3, prof max %d."):format(waterCells, waterCells * 64, maxDepth * 4) }
end
function handlers.TerrainStats(player)
  local ter = terrainOrFail()
  local cells = 0
  pcall(function() cells = ter:CountCells() end)
  return { cells = cells, undo = #TERD.UNDO, redo = #TERD.REDO, layers = #TERD.LAYERS }
end

local MUTATING = { Begin=true, Create=true, CreateAny=true, CsgDo=true, Cut=true, DataDelete=true, DataSet=true, Delete=true, Duplicate=true, End=true, EnsureBase=true, Import=true, New=true, Open=true, Paste=true, PlaceCreate=true, PropsSet=true, Publish=true, QuickPart=true, Redo=true, Rename=true, SculptApply=true, Set=true, SetAny=true, SetLocString=true, SetLocale=true, SetProjectInfo=true, ToolboxAssetInsert=true, ToolboxInsert=true, TerrainClear=true, TerrainFill=true, TerrainGenFlat=true, TerrainReplace=true, TerrainWater=true, TerrainSmooth=true, TerrainNoise=true, TerrainStroke=true, TerrainUndo=true, TerrainRedo=true, TerrainLayer=true, TerrainGen=true, TerrainWaterProps=true, TerrainRain=true, TerrainFlood=true, TerrainHydro=true, ScriptSet=true, Undo=true, Group=true, Ungroup=true, AlignKids=true, DistributeKids=true, MirrorKids=true, PivotReset=true, SelAdd=true, SelClear=true, SelectMany=true, DeleteMany=true, DuplicateMany=true, RemapSet=true, TransformMany=true, ViewportRig=true, MeshNew=true, MeshMoveVert=true, MeshDeleteVert=true, MeshSmooth=true, MeshMirror=true, MeshImportOBJ=true, AnimRig=true, AnimNew=true, AnimKeyAdd=true, AnimKeyDel=true, AnimPoseSet=true, AnimPlay=true, AnimStop=true, AnimScrub=true, AnimIK=true, AnimImport=true, AnimJointSet=true, UiRoot=true, UiNew=true, UiDelete=true, UiDup=true, UiMove=true, UiSize=true, UiText=true, UiImport=true, UiPublish=true, RrwProfile=true, RrwFx=true, RrwSky=true, RrwAtmo=true, RrwClouds=true, RrwLod=true, RrwVfx=true, Do15Optimize=true, Do15Relevance=true, WorldGravity=true, WorldSpawn=true, WorldSave=true, WorldClean=true, WorldClear=true }
local function runRestore()
	for part, was in pairs(RUN.parts) do
		if part and part.Parent then
			pcall(function()
				part.Anchored = was
				local v = RUN.vels[part]
				if v and not was then
					part.AssemblyLinearVelocity = v[1]
					part.AssemblyAngularVelocity = v[2]
				end
			end)
		end
	end
	RUN.parts = {}
	RUN.vels = {}
	for _, snd in ipairs(RUN.sounds) do
		if snd and snd.Parent then pcall(function() snd:Resume() end) end
	end
	RUN.sounds = {}
	RUN.frozen = false
end
local function selOrId(player, id)
    local o = nil
    if type(id) == "string" and objects[id] then o = objects[id] end
    if (not o or not inspectable(o)) then o = selected[player] end
    if o and not inspectable(o) then o = nil end
    return o
end

function handlers.Group(player, payload)
    if type(payload.ids) == "table" and #payload.ids > 0 then
        local parts = {}
        for _, id2 in ipairs(payload.ids) do
            if type(id2) == "string" then
                local ok, o = pcall(getObject, id2)
                if ok and o and editable(o) and not rootSet[o] and not containsProtected(o) then parts[#parts + 1] = o end
            end
        end
        assert(#parts > 0, "Nada agrupável nos ids.")
        local gparent = parts[1].Parent or workspace
        local g = Instance.new("Model")
        g.Name = "Group_" .. #parts
        g.Parent = gparent
        register(g) created[g] = true
        local olds = {}
        for _, o in ipairs(parts) do olds[o] = o.Parent or workspace o.Parent = g queueObject(o) end
        selected[player] = g
        queueObject(g)
        pushHist(player, {
            label = "Group " .. #parts .. " objs",
            undo = function() for _, o in ipairs(parts) do o.Parent = olds[o] end g.Parent = nil selected[player] = parts[1] end,
            redo = function() g.Parent = gparent for _, o in ipairs(parts) do o.Parent = g end selected[player] = g end,
        })
        return { node = record(g), grouped = #parts }
    end
    local o = selOrId(player, payload.id)
    assert(o and editable(o) and not rootSet[o] and not containsProtected(o), "Selecione um objeto editável para agrupar.")
    assert(not conflictingLock(o, player), "Objeto em edição por outro usuário.")
    local parent = o.Parent or workspace
    local g = Instance.new("Model")
    g.Name = o.Name .. "_Group"
    g.Parent = parent
    register(g) created[g] = true
    o.Parent = g
    selected[player] = g
    queueObject(g) queueObject(o)
    pushHist(player, {
        label = "Group " .. g.Name,
        undo = function() o.Parent = parent g.Parent = nil selected[player] = o queueObject(o) end,
        redo = function() g.Parent = parent o.Parent = g selected[player] = g queueObject(g) end,
    })
    return { node = record(g) }
end

function handlers.Ungroup(player, payload)
    local g = selOrId(player, payload.id)
    assert(g and (g:IsA("Model") or g:IsA("Folder")) and editable(g) and not rootSet[g], "Selecione um Model ou Folder para desagrupar.")
    local parent = g.Parent or workspace
    local kids = g:GetChildren()
    assert(#kids > 0, "O grupo está vazio.")
    for _, k in ipairs(kids) do k.Parent = parent queueObject(k) end
    g.Parent = nil
    selected[player] = kids[1]
    queueObject(g)
    pushHist(player, {
        label = "Ungroup " .. g.Name,
        undo = function() g.Parent = parent for _, k in ipairs(kids) do k.Parent = g end selected[player] = g queueObject(g) end,
        redo = function() for _, k in ipairs(kids) do k.Parent = parent end g.Parent = nil selected[player] = kids[1] end,
    })
    return { ungrouped = #kids }
end

local function kidsParts(g)
    local parts = {}
    for _, k in ipairs(g:GetChildren()) do
        if k:IsA("BasePart") and not k:IsA("Terrain") and editable(k) then parts[#parts + 1] = k end
    end
    return parts
end

local AXES = { X = "X", Y = "Y", Z = "Z" }
local function axisOf(payload)
    local a = tostring(payload.axis or "X"):upper()
    assert(AXES[a], "axis deve ser X, Y ou Z.")
    return a
end

function handlers.AlignKids(player, payload)
    local g = selOrId(player, payload.id)
    assert(g and (g:IsA("Model") or g:IsA("Folder") or g == workspace), "Selecione um Model/Folder para alinhar os filhos.")
    local parts = kidsParts(g)
    assert(#parts >= 2, "Precisa de 2+ peças filhas para alinhar.")
    local a = axisOf(payload)
    local target = g:GetPivot().Position[a]
    local old = {}
    for _, p in ipairs(parts) do old[p] = p.Position p.Position = Vector3.new(a == "X" and target or p.Position.X, a == "Y" and target or p.Position.Y, a == "Z" and target or p.Position.Z) queueObject(p) end
    pushHist(player, {
        label = "Align " .. #parts .. " on " .. a,
        undo = function() for _, p in ipairs(parts) do if old[p] then p.Position = old[p] queueObject(p) end end end,
        redo = function() for _, p in ipairs(parts) do p.Position = Vector3.new(a == "X" and target or p.Position.X, a == "Y" and target or p.Position.Y, a == "Z" and target or p.Position.Z) end end,
    })
    return { aligned = #parts, axis = a }
end

function handlers.DistributeKids(player, payload)
    local g = selOrId(player, payload.id)
    assert(g and (g:IsA("Model") or g:IsA("Folder") or g == workspace), "Selecione um Model/Folder para distribuir os filhos.")
    local parts = kidsParts(g)
    assert(#parts >= 3, "Precisa de 3+ peças filhas para distribuir.")
    local a = axisOf(payload)
    table.sort(parts, function(p1, p2) return p1.Position[a] < p2.Position[a] end)
    local lo, hi = parts[1].Position[a], parts[#parts].Position[a]
    assert(hi > lo, "Peças já coincidem no eixo " .. a .. ".")
    local old = {}
    for i, p in ipairs(parts) do
        old[p] = p.Position
        local v = lo + (hi - lo) * (i - 1) / (#parts - 1)
        p.Position = Vector3.new(a == "X" and v or p.Position.X, a == "Y" and v or p.Position.Y, a == "Z" and v or p.Position.Z)
        queueObject(p)
    end
    pushHist(player, {
        label = "Distribute " .. #parts .. " on " .. a,
        undo = function() for _, p in ipairs(parts) do if old[p] then p.Position = old[p] queueObject(p) end end end,
        redo = function() end,
    })
    return { distributed = #parts, axis = a }
end

function handlers.MirrorKids(player, payload)
    local g = selOrId(player, payload.id)
    assert(g and (g:IsA("Model") or g:IsA("Folder") or g == workspace), "Selecione um Model/Folder para espelhar os filhos.")
    local parts = kidsParts(g)
    assert(#parts >= 1, "Sem peças filhas para espelhar.")
    local a = axisOf(payload)
    local plane = g:GetPivot().Position[a]
    local old = {}
    for _, p in ipairs(parts) do
        old[p] = p.Position
        local v = 2 * plane - p.Position[a]
        p.Position = Vector3.new(a == "X" and v or p.Position.X, a == "Y" and v or p.Position.Y, a == "Z" and v or p.Position.Z)
        queueObject(p)
    end
    pushHist(player, {
        label = "Mirror " .. #parts .. " on " .. a,
        undo = function() for _, p in ipairs(parts) do if old[p] then p.Position = old[p] queueObject(p) end end end,
        redo = function() for _, p in ipairs(parts) do local v = 2 * plane - p.Position[a] p.Position = Vector3.new(a == "X" and v or p.Position.X, a == "Y" and v or p.Position.Y, a == "Z" and v or p.Position.Z) end end,
    })
    return { mirrored = #parts, axis = a }
end

local selSet = {}
local function setGet(player)
    local s = selSet[player]
    if not s then s = {} selSet[player] = s end
    return s
end
local function setPrune(player)
    local out = {}
    for _, o in ipairs(setGet(player)) do
        if inspectable(o) and idOf[o] then out[#out + 1] = o end
    end
    selSet[player] = out
    return out
end
local function setAddIds(player, ids)
    local s = setGet(player)
    local have = {}
    for _, o in ipairs(s) do have[o] = true end
    local added = 0
    for _, id2 in ipairs(ids or {}) do
        if type(id2) == "string" then
            local ok, o = pcall(getObject, id2)
            if ok and o and inspectable(o) and not have[o] then
                have[o] = true s[#s + 1] = o added = added + 1
            end
        end
    end
    return added
end
local function setAddInsts(player, insts)
    local s = setGet(player)
    local have = {}
    for _, o in ipairs(s) do have[o] = true end
    local added = 0
    for _, o in ipairs(insts or {}) do
        if typeof(o) == "Instance" and idOf[o] and inspectable(o) and not have[o] then
            have[o] = true s[#s + 1] = o added = added + 1
        end
    end
    return added
end
local function setIds(player)
    local out = {}
    for _, o in ipairs(setPrune(player)) do out[#out + 1] = idOf[o] end
    return out
end

function handlers.SelAdd(player, payload)
    local ids = {}
    if type(payload.ids) == "table" then ids = payload.ids end
    if payload.id then ids[#ids + 1] = payload.id end
    local added = setAddIds(player, ids) + setAddInsts(player, payload.insts)
    return { added = added, count = #setGet(player), ids = setIds(player) }
end

function handlers.SelClear(player, payload)
    selSet[player] = {}
    return { cleared = true }
end

function handlers.SelectMany(player, payload)
    selSet[player] = {}
    local ids = {}
    if type(payload.ids) == "table" then ids = payload.ids end
    if payload.id then ids[#ids + 1] = payload.id end
    local added = setAddIds(player, ids) + setAddInsts(player, payload.insts)
    return { count = #setGet(player), added = added, ids = setIds(player) }
end

function handlers.DeleteMany(player, payload)
    local s = setPrune(player)
    local deleted, failed = 0, 0
    for _, o in ipairs(s) do
        local ok = pcall(handlers.Delete_, player, { id = idOf[o] })
        if ok then deleted = deleted + 1 else failed = failed + 1 end
    end
    selSet[player] = {}
    return { deleted = deleted, failed = failed }
end

function handlers.DuplicateMany(player, payload)
    local s = setPrune(player)
    local ids, failed = {}, 0
    for _, o in ipairs(s) do
        local ok = pcall(handlers.Copy, player, { id = idOf[o] })
        if ok then
            local ok2, r = pcall(handlers.Paste, player, {})
            if ok2 and r and r.node and r.node.id then ids[#ids + 1] = r.node.id
            else failed = failed + 1 end
        else failed = failed + 1 end
    end
    return { duplicated = #ids, failed = failed, ids = ids }
end

-- ============ R11: REMAP PERSISTENTE + TRANSFORM MANY + VIEWPORT RIG ============
local remapMem = {}
local function remapStore()
  local st = nil
  pcall(function()
    st = game:GetService("DataStoreService"):GetDataStore("arkher_remap_v1")
  end)
  return st
end
local REMAP_SLOTS11 = { Select = true, Move = true, Rotate = true, Scale = true,
  Frame = true, Box = true, Lasso = true, Snap = true }
local function remapKey(player)
  local id = 0
  pcall(function() id = player.UserId or 0 end)
  return "u_" .. tostring(id)
end
function handlers.RemapGet(player, payload)
  local k = remapKey(player)
  if remapMem[k] then return { bindings = remapMem[k], source = "memory" } end
  local st = remapStore()
  if st then
    local ok, rec = pcall(function() return st:GetAsync(k) end)
    if ok and type(rec) == "table" then
      remapMem[k] = rec
      return { bindings = rec, source = "datastore" }
    end
  end
  return { bindings = nil, source = "none" }
end
function handlers.RemapSet(player, payload)
  local b = payload.bindings
  assert(type(b) == "table", "bindings deve ser tabela slot->KeyCode.")
  local clean = {}
  local n = 0
  for slot, name in pairs(b) do
    assert(REMAP_SLOTS11[slot], "slot invalido: " .. tostring(slot))
    assert(type(name) == "string" and #name >= 1 and #name <= 32
      and name:match("^[A-Za-z0-9_]+$"), "KeyCode invalido p/ " .. tostring(slot))
    local ok = pcall(function() return Enum.KeyCode[name] end)
    assert(ok, "KeyCode desconhecido: " .. tostring(name))
    clean[slot] = name
    n = n + 1
    assert(n <= 8, "slots demais.")
  end
  local k = remapKey(player)
  remapMem[k] = clean
  local stored = false
  local st = remapStore()
  if st then
    local ok = pcall(function() st:SetAsync(k, clean) end)
    stored = ok == true
  end
  return { saved = true, slots = n, store = stored }
end
local rigMem = {}
function handlers.ViewportRig(player, payload)
  local k = remapKey(player)
  if payload.op == "set" then
    local r = rigMem[k] or {}
    if payload.pos then r.pos = { x = tonumber(payload.pos.x) or 0, y = tonumber(payload.pos.y) or 0, z = tonumber(payload.pos.z) or 0 } end
    if payload.target then r.target = { x = tonumber(payload.target.x) or 0, y = tonumber(payload.target.y) or 0, z = tonumber(payload.target.z) or 0 } end
    if payload.fov then r.fov = math.clamp(tonumber(payload.fov) or 70, 1, 120) end
    if payload.mode then r.mode = tostring(payload.mode):sub(1, 16) end
    rigMem[k] = r
    return { saved = true, rig = r }
  end
  return { rig = rigMem[k] }
end
function handlers.ViewportFrame(player, payload)
  local objs = {}
  if type(payload.ids) == "table" and #payload.ids > 0 then
    for _, id2 in ipairs(payload.ids) do
      if type(id2) == "string" then
        local ok, o = pcall(getObject, id2)
        if ok and o and inspectable(o) then objs[#objs + 1] = o end
      end
    end
  else
    objs = setPrune(player)
  end
  assert(#objs > 0, "Nada selecionado para enquadrar.")
  assert(#objs <= 500, "Selecao grande demais p/ frame (500).")
  local mn, mx = nil, nil
  for _, o in ipairs(objs) do
    local ok, cf, sz = pcall(function() return o:GetBoundingBox() end)
    if ok and cf and sz then
      local p, s = cf.Position, sz
      local lo = Vector3.new(p.X - s.X / 2, p.Y - s.Y / 2, p.Z - s.Z / 2)
      local hi = Vector3.new(p.X + s.X / 2, p.Y + s.Y / 2, p.Z + s.Z / 2)
      if not mn then mn, mx = lo, hi
      else
        mn = Vector3.new(math.min(mn.X, lo.X), math.min(mn.Y, lo.Y), math.min(mn.Z, lo.Z))
        mx = Vector3.new(math.max(mx.X, hi.X), math.max(mx.Y, hi.Y), math.max(mx.Z, hi.Z))
      end
    end
  end
  assert(mn, "Sem bounds legiveis na selecao.")
  local c = (mn + mx) / 2
  local ext = (mx - mn)
  local radius = math.max(ext.X, ext.Y, ext.Z, 2) / 2
  local dir = payload.dir or { x = 1, y = 0.6, z = 1 }
  local dv = Vector3.new(tonumber(dir.x) or 1, tonumber(dir.y) or 0.6, tonumber(dir.z) or 1)
  if dv.Magnitude < 1e-6 then dv = Vector3.new(1, 0.6, 1) end
  dv = dv.Unit
  local dist = math.clamp(radius * 3.2 + 4, 6, 2000)
  local pos = c + dv * dist
  return {
    center = { x = c.X, y = c.Y, z = c.Z },
    size = { x = ext.X, y = ext.Y, z = ext.Z },
    pos = { x = pos.X, y = pos.Y, z = pos.Z },
    dist = dist, count = #objs,
    msg = ("Frame: %d objeto(s), centro (%.0f, %.0f, %.0f), dist %.0f."):format(#objs, c.X, c.Y, c.Z, dist),
  }
end
function handlers.TransformMany(player, payload)
  local mode = tostring(payload.mode or "move")
  assert(mode == "move" or mode == "rot" or mode == "scale", "mode: move/rot/scale.")
  local d = payload.delta or {}
  local dx, dy, dz = tonumber(d.x) or 0, tonumber(d.y) or 0, tonumber(d.z) or 0
  assert(math.abs(dx) < 100000 and math.abs(dy) < 100000 and math.abs(dz) < 100000, "delta fora do limite.")
  local objs = {}
  if type(payload.ids) == "table" and #payload.ids > 0 then
    for _, id2 in ipairs(payload.ids) do
      if type(id2) == "string" then
        local ok, o = pcall(getObject, id2)
        if ok and o and editable(o) and not containsProtected(o) then objs[#objs + 1] = o end
      end
    end
  else
    for _, o in ipairs(setPrune(player)) do
      if editable(o) and not containsProtected(o) then objs[#objs + 1] = o end
    end
  end
  assert(#objs > 0, "Nada transformavel selecionado.")
  assert(#objs <= 500, "Selecao grande demais (500).")
  local items = {}
  for _, o in ipairs(objs) do
    local ok, cf = pcall(function() return getPivot(o) end)
    if ok and cf then
      local it = { o = o, fromCf = cf, fromSize = nil, fromScale = nil }
      if o:IsA("BasePart") then it.fromSize = o.Size end
      if o.ClassName == "Model" then pcall(function() it.fromScale = o:GetScale() end) end
      items[#items + 1] = it
    end
  end
  assert(#items > 0, "Sem pivo legivel na selecao.")
  local function applyOne(it, isRedo)
    local o = it.o
    if not o.Parent then return end
    if isRedo then
      pcall(function()
        setPivot(o, it.toCf)
        if it.toSize and o:IsA("BasePart") then o.Size = it.toSize end
        if it.toScale and o.ClassName == "Model" then o:ScaleTo(it.toScale) end
      end)
    else
      pcall(function()
        setPivot(o, it.fromCf)
        if it.fromSize and o:IsA("BasePart") then o.Size = it.fromSize end
        if it.fromScale and o.ClassName == "Model" then o:ScaleTo(it.fromScale) end
      end)
    end
    queueObject(o)
  end
  for _, it in ipairs(items) do
    if mode == "move" then
      it.toCf = it.fromCf * CFrame.new(dx, dy, dz)
    elseif mode == "rot" then
      it.toCf = it.fromCf * CFrame.fromOrientation(math.rad(dx), math.rad(dy), math.rad(dz))
    else
      it.toCf = it.fromCf
      local mx, my, mz = dx == 0 and 1 or dx, dy == 0 and 1 or dy, dz == 0 and 1 or dz
      if it.fromSize then
        it.toSize = Vector3.new(
          math.clamp(it.fromSize.X * mx, 0.05, CONFIG.MAX_SIZE),
          math.clamp(it.fromSize.Y * my, 0.05, CONFIG.MAX_SIZE),
          math.clamp(it.fromSize.Z * mz, 0.05, CONFIG.MAX_SIZE))
      end
      if it.fromScale then it.toScale = math.clamp(it.fromScale * mx, 0.01, 100) end
    end
    applyOne(it, true)
  end
  pushHist(player, {
    label = ("TransformMany %s x%d"):format(mode, #items),
    undo = function() for _, it in ipairs(items) do applyOne(it, false) end end,
    redo = function() for _, it in ipairs(items) do applyOne(it, true) end end,
  })
  return { transformed = #items, mode = mode,
    msg = ("%s aplicado em %d objeto(s) (1 undo)."):format(mode, #items) }
end

-- ============ R12: MODELER (EditableMesh real + OBJ) ============
local meshReg = {}
local function meshGet(id)
  local ok, o = pcall(getObject, id)
  assert(ok and o, "mesh id invalido.")
  local em = meshReg[id]
  assert(em, "MeshPart sem malha Arkher (use MeshSelect p/ adotar).")
  return o, em
end
local function meshRefresh(o, em)
  local ok = pcall(function()
    local AS = game:GetService("AssetService")
    local tmp = AS:CreateMeshPartAsync(Content.fromObject(em))
    o:ApplyMesh(tmp)
    pcall(function() tmp:Destroy() end)
  end)
  return ok == true
end
local function meshPrim(em, kind, s)
  s = math.clamp(tonumber(s) or 4, 0.5, 512)
  local h = s / 2
  local V = function(x, y, z) return em:AddVertex(Vector3.new(x, y, z)) end
  local TR = function(a, b, c) return em:AddTriangle(a, b, c) end
  if kind == "box" then
    local v = { V(-h, -h, -h), V(h, -h, -h), V(h, h, -h), V(-h, h, -h),
      V(-h, -h, h), V(h, -h, h), V(h, h, h), V(-h, h, h) }
    -- back/front/left/right/bottom/top, todas CCW p/ fora (normais verificadas)
    local F = { { 1, 4, 3 }, { 1, 3, 2 }, { 5, 6, 7 }, { 5, 7, 8 },
      { 1, 5, 8 }, { 1, 8, 4 }, { 2, 3, 7 }, { 2, 7, 6 },
      { 1, 6, 5 }, { 1, 2, 6 }, { 4, 7, 3 }, { 4, 8, 7 } }
    for _, f in ipairs(F) do TR(v[f[1]], v[f[2]], v[f[3]]) end
  elseif kind == "plane" then
    local v = { V(-h, 0, -h), V(h, 0, -h), V(h, 0, h), V(-h, 0, h) }
    TR(v[1], v[4], v[3]) TR(v[1], v[3], v[2])
  elseif kind == "wedge" then
    local v = { V(-h, -h, -h), V(h, -h, -h), V(h, -h, h), V(-h, -h, h),
      V(-h, h, -h), V(h, h, -h) }
    local F = { { 1, 2, 3 }, { 1, 3, 4 }, { 4, 3, 6 }, { 4, 6, 5 },
      { 1, 6, 2 }, { 1, 5, 6 }, { 1, 4, 5 }, { 2, 6, 3 } }
    for _, f in ipairs(F) do TR(v[f[1]], v[f[2]], v[f[3]]) end
  elseif kind == "cyl8" then
    local b, t = {}, {}
    for k = 0, 7 do
      local a = math.rad(k * 45)
      b[k + 1] = V(math.cos(a) * h, -h, math.sin(a) * h)
      t[k + 1] = V(math.cos(a) * h, h, math.sin(a) * h)
    end
    for k = 1, 8 do
      local n = (k % 8) + 1
      TR(b[k], t[n], b[n]) TR(b[k], t[k], t[n])
    end
    for k = 2, 7 do TR(b[1], b[k], b[k + 1]) end
    for k = 2, 7 do TR(t[1], t[k + 1], t[k]) end
  else
    error("primitiva: box/plane/wedge/cyl8.")
  end
end
function handlers.MeshNew(player, payload)
  local kind = tostring(payload.primitive or "box")
  local em = nil
  local okA, errA = pcall(function()
    em = game:GetService("AssetService"):CreateEditableMesh()
  end)
  assert(okA and em, "EditableMesh indisponivel: " .. tostring(errA) .. " (ative Mesh/Image APIs no dashboard).")
  local okB, errB = pcall(meshPrim, em, kind, payload.size)
  if not okB then error(errB) end
  local parent = workspace
  if payload.parentId then
    local ok, p = pcall(getObject, payload.parentId)
    if ok and p then parent = p end
  end
  local mp = nil
  local okC, errC = pcall(function()
    mp = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromObject(em))
  end)
  assert(okC and mp, "CreateMeshPartAsync falhou: " .. tostring(errC))
  mp.Name = tostring(payload.name or ("Mesh_" .. kind)):sub(1, 40)
  mp.Anchored = true
  pcall(function() mp.Size = Vector3.new(2, 2, 2) end)
  local entry = byClass["MeshPart"]
  if entry then
    local allowed, reason = canCreate(parent, entry)
    assert(allowed, reason)
  end
  mp.Parent = parent
  created[player] = (created[player] or 0) + 1
  register(mp)
  meshReg[idOf[mp]] = em
  queueObject(parent)
  hCreate(player, mp)
  local nv = #em:GetVertices()
  return { node = record(mp), verts = nv, faces = #em:GetFaces(),
    msg = ("Mesh %s criada (%d verts)."):format(kind, nv) }
end
function handlers.MeshSelect(player, payload)
  local o = getObject(payload.id)
  assert(o:IsA("MeshPart"), "Selecione uma MeshPart.")
  local content = nil
  pcall(function() content = o.MeshContent end)
  assert(content, "MeshPart sem MeshContent.")
  local em = nil
  local ok, err = pcall(function()
    em = game:GetService("AssetService"):CreateEditableMeshAsync(content, { FixedSize = false })
  end)
  assert(ok and em, "Adocao falhou: " .. tostring(err))
  meshReg[payload.id] = em
  return { verts = #em:GetVertices(), faces = #em:GetFaces(), msg = "Mesh adotada." }
end
function handlers.MeshInfo(player, payload)
  local o, em = meshGet(payload.id)
  local mn, mx = nil, nil
  for _, vid in ipairs(em:GetVertices()) do
    local p = em:GetVertexPosition(vid)
    if not mn then mn, mx = p, p
    else
      mn = Vector3.new(math.min(mn.X, p.X), math.min(mn.Y, p.Y), math.min(mn.Z, p.Z))
      mx = Vector3.new(math.max(mx.X, p.X), math.max(mx.Y, p.Y), math.max(mx.Z, p.Z))
    end
  end
  return { verts = #em:GetVertices(), faces = #em:GetFaces(),
    min = mn and { x = mn.X, y = mn.Y, z = mn.Z } or nil,
    max = mx and { x = mx.X, y = mx.Y, z = mx.Z } or nil }
end
function handlers.MeshVerts(player, payload)
  local o, em = meshGet(payload.id)
  local ids = em:GetVertices()
  assert(#ids <= 500, "Malha grande demais p/ listar (500 verts).")
  local out = {}
  for _, vid in ipairs(ids) do
    local p = em:GetVertexPosition(vid)
    out[#out + 1] = { vid = vid, x = p.X, y = p.Y, z = p.Z }
  end
  return { verts = out }
end
function handlers.MeshMoveVert(player, payload)
  local o, em = meshGet(payload.id)
  local vid = tonumber(payload.vid)
  assert(vid, "vid invalido.")
  local np = Vector3.new(tonumber(payload.x) or 0, tonumber(payload.y) or 0, tonumber(payload.z) or 0)
  assert(math.abs(np.X) < 100000 and math.abs(np.Y) < 100000 and math.abs(np.Z) < 100000, "posicao fora do limite.")
  local old = em:GetVertexPosition(vid)
  em:SetVertexPosition(vid, np)
  queueObject(o)
  pushHist(player, {
    label = "Mover vertice " .. tostring(vid),
    undo = function() pcall(function() em:SetVertexPosition(vid, old) end) queueObject(o) end,
    redo = function() pcall(function() em:SetVertexPosition(vid, np) end) queueObject(o) end,
  })
  local ref = meshRefresh(o, em)
  return { moved = true, refreshed = ref }
end
function handlers.MeshDeleteVert(player, payload)
  local o, em = meshGet(payload.id)
  local vid = tonumber(payload.vid)
  assert(vid, "vid invalido.")
  local oldPos = em:GetVertexPosition(vid)
  local deadFaces = {}
  for _, fid in ipairs(em:GetFaces()) do
    local fv = em:GetFaceVertices(fid)
    if fv[1] == vid or fv[2] == vid or fv[3] == vid then
      deadFaces[#deadFaces + 1] = { fid = fid, v = fv }
    end
  end
  for _, d in ipairs(deadFaces) do em:RemoveTriangle(d.fid) end
  em:RemoveVertex(vid)
  queueObject(o)
  local curVid = vid
  pushHist(player, {
    label = "Deletar vertice " .. tostring(vid),
    undo = function()
      pcall(function()
        local nv = em:AddVertex(oldPos)
        for _, d in ipairs(deadFaces) do
          local a, b, c = d.v[1], d.v[2], d.v[3]
          if a == vid then a = nv end
          if b == vid then b = nv end
          if c == vid then c = nv end
          em:AddTriangle(a, b, c)
        end
        curVid = nv
      end)
      queueObject(o)
    end,
    redo = function()
      pcall(function()
        for _, fid in ipairs(em:GetFaces()) do
          local fv = em:GetFaceVertices(fid)
          if fv[1] == curVid or fv[2] == curVid or fv[3] == curVid then em:RemoveTriangle(fid) end
        end
        em:RemoveVertex(curVid)
      end)
      queueObject(o)
    end,
  })
  local ref = meshRefresh(o, em)
  return { deleted = true, faces = #deadFaces, refreshed = ref,
    msg = "Vertice deletado (undo restaura geometria; vid pode mudar)." }
end
function handlers.MeshSmooth(player, payload)
  local o, em = meshGet(payload.id)
  local iters = math.clamp(math.floor(tonumber(payload.iters) or 1), 1, 10)
  local lambda = math.clamp(tonumber(payload.lambda) or 0.5, 0.01, 1)
  local vids = em:GetVertices()
  assert(#vids > 0 and #vids <= 5000, "Malha vazia ou grande demais (5000).")
  local adj = {}
  for _, v in ipairs(vids) do adj[v] = {} end
  for _, fid in ipairs(em:GetFaces()) do
    local fv = em:GetFaceVertices(fid)
    for i = 1, 3 do
      local a, b = fv[i], fv[(i % 3) + 1]
      adj[a][b] = true adj[b][a] = true
    end
  end
  local old = {}
  for _, v in ipairs(vids) do old[v] = em:GetVertexPosition(v) end
  for _ = 1, iters do
    local newP = {}
    for _, v in ipairs(vids) do
      local sx, sy, sz, n = 0, 0, 0, 0
      for nb in pairs(adj[v]) do
        local p = em:GetVertexPosition(nb)
        sx, sy, sz, n = sx + p.X, sy + p.Y, sz + p.Z, n + 1
      end
      if n > 0 then
        local p = em:GetVertexPosition(v)
        newP[v] = Vector3.new(
          p.X + (sx / n - p.X) * lambda,
          p.Y + (sy / n - p.Y) * lambda,
          p.Z + (sz / n - p.Z) * lambda)
      end
    end
    for v, p in pairs(newP) do em:SetVertexPosition(v, p) end
  end
  local newF = {}
  for _, v in ipairs(vids) do newF[v] = em:GetVertexPosition(v) end
  queueObject(o)
  pushHist(player, {
    label = "Smooth x" .. tostring(iters),
    undo = function() for v, p in pairs(old) do pcall(function() em:SetVertexPosition(v, p) end) end queueObject(o) end,
    redo = function() for v, p in pairs(newF) do pcall(function() em:SetVertexPosition(v, p) end) end queueObject(o) end,
  })
  local ref = meshRefresh(o, em)
  return { smoothed = true, iters = iters, refreshed = ref }
end
function handlers.MeshMirror(player, payload)
  local o, em = meshGet(payload.id)
  local ax = tostring(payload.axis or "X"):upper()
  assert(ax == "X" or ax == "Y" or ax == "Z", "axis: X/Y/Z.")
  local vids = em:GetVertices()
  assert(#vids > 0 and #vids <= 5000, "Malha vazia ou grande demais (5000).")
  local old = {}
  for _, v in ipairs(vids) do old[v] = em:GetVertexPosition(v) end
  for _, v in ipairs(vids) do
    local p = old[v]
    if ax == "X" then em:SetVertexPosition(v, Vector3.new(-p.X, p.Y, p.Z))
    elseif ax == "Y" then em:SetVertexPosition(v, Vector3.new(p.X, -p.Y, p.Z))
    else em:SetVertexPosition(v, Vector3.new(p.X, p.Y, -p.Z)) end
  end
  queueObject(o)
  pushHist(player, {
    label = "Mirror " .. ax,
    undo = function() for v, p in pairs(old) do pcall(function() em:SetVertexPosition(v, p) end) end queueObject(o) end,
    redo = function()
      for v, p in pairs(old) do
        pcall(function()
          if ax == "X" then em:SetVertexPosition(v, Vector3.new(-p.X, p.Y, p.Z))
          elseif ax == "Y" then em:SetVertexPosition(v, Vector3.new(p.X, -p.Y, p.Z))
          else em:SetVertexPosition(v, Vector3.new(p.X, p.Y, -p.Z)) end
        end)
      end
      queueObject(o)
    end,
  })
  local ref = meshRefresh(o, em)
  return { mirrored = true, axis = ax, refreshed = ref }
end
function handlers.MeshExportOBJ(player, payload)
  local o, em = meshGet(payload.id)
  local vids = em:GetVertices()
  assert(#vids > 0 and #vids <= 20000, "Malha vazia ou grande demais p/ OBJ (20k).")
  local map = {}
  for i, v in ipairs(vids) do map[v] = i end
  local lines = { "# Arkher Modeler OBJ export", "o " .. tostring(o.Name):gsub("%s+", "_") }
  for _, v in ipairs(vids) do
    local p = em:GetVertexPosition(v)
    lines[#lines + 1] = string.format("v %.4f %.4f %.4f", p.X, p.Y, p.Z)
  end
  for _, fid in ipairs(em:GetFaces()) do
    local fv = em:GetFaceVertices(fid)
    lines[#lines + 1] = string.format("f %d %d %d", map[fv[1]], map[fv[2]], map[fv[3]])
  end
  return { obj = table.concat(lines, "\n"), verts = #vids, faces = #em:GetFaces() }
end
function handlers.MeshImportOBJ(player, payload)
  local text = tostring(payload.obj or "")
  assert(#text > 0 and #text <= 2000000, "OBJ vazio ou grande demais (2MB).")
  local verts, faces = {}, {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local tag, rest = line:match("^%s*(%S+)%s*(.-)%s*$")
    if tag == "v" then
      local x, y, z = rest:match("^(%S+)%s+(%S+)%s+(%S+)")
      assert(x and y and z, "linha v invalida: " .. line:sub(1, 40))
      verts[#verts + 1] = { tonumber(x), tonumber(y), tonumber(z) }
      assert(#verts <= 5000, "OBJ com verts demais (5000).")
    elseif tag == "f" then
      local idx = {}
      for tok in rest:gmatch("%S+") do
        local n = tonumber(tok:match("^(-?%d+)"))
        assert(n, "face invalida: " .. line:sub(1, 40))
        if n < 0 then n = #verts + n + 1 end
        assert(n >= 1 and n <= #verts, "indice de face fora do range.")
        idx[#idx + 1] = n
      end
      assert(#idx == 3 or #idx == 4, "so triangulos e quads (triangule o resto).")
      faces[#faces + 1] = { idx[1], idx[2], idx[3] }
      if #idx == 4 then faces[#faces + 1] = { idx[1], idx[3], idx[4] } end
      assert(#faces <= 10000, "OBJ com faces demais (10k).")
    end
  end
  assert(#verts >= 3 and #faces >= 1, "OBJ sem geometria (v/f).")
  local em = nil
  local okA, errA = pcall(function()
    em = game:GetService("AssetService"):CreateEditableMesh()
  end)
  assert(okA and em, "EditableMesh indisponivel: " .. tostring(errA))
  local vids = {}
  for _, v in ipairs(verts) do
    vids[#vids + 1] = em:AddVertex(Vector3.new(v[1], v[2], v[3]))
  end
  for _, f in ipairs(faces) do em:AddTriangle(vids[f[1]], vids[f[2]], vids[f[3]]) end
  local mp = nil
  local okC, errC = pcall(function()
    mp = game:GetService("AssetService"):CreateMeshPartAsync(Content.fromObject(em))
  end)
  assert(okC and mp, "CreateMeshPartAsync falhou: " .. tostring(errC))
  mp.Name = tostring(payload.name or "Mesh_OBJ"):sub(1, 40)
  mp.Anchored = true
  mp.Parent = workspace
  created[player] = (created[player] or 0) + 1
  register(mp)
  meshReg[idOf[mp]] = em
  queueObject(workspace)
  hCreate(player, mp)
  return { node = record(mp), verts = #verts, faces = #faces,
    msg = ("OBJ importado (%d verts, %d tris)."):format(#verts, #faces) }
end

-- ============ R13: ANIMATOR (KeyframeSequence real + preview por Motor6D.Transform) ============
-- Playback SEM publish: o motor aplica Pose interpolada em Motor6D.Transform todo
-- Heartbeat (exatamente o canal que o runtime usa). Easing Linear/Constant exato no
-- preview; Elastic/Cubic/Bounce/CubicV2 usam preview linear (flag approx=true) e o
-- easing real vale apos publicar a sequencia pelo Studio.
local ANIMA = {
  EASE_STYLE = { Linear = true, Constant = true, Elastic = true, Cubic = true,
    Bounce = true, CubicV2 = true },
  EASE_DIR = { In = true, Out = true, InOut = true },
  PRI = { Idle = true, Movement = true, Action = true, Action2 = true,
    Action3 = true, Action4 = true, Core = true },
}
local animPrev = {}
local function animGetSeq(id)
  local o = getObject(id)
  assert(o:IsA("KeyframeSequence"), "id nao eh KeyframeSequence.")
  return o
end
local function animRigOf(id)
  local o = getObject(id)
  assert(o:IsA("Model"), "rig precisa ser um Model.")
  local hum = o:FindFirstChildWhichIsA("Humanoid", true)
    or o:FindFirstChildWhichIsA("AnimationController", true)
  assert(hum, "rig sem Humanoid/AnimationController.")
  local ator = hum:FindFirstChildOfClass("Animator")
  local created = false
  if not ator then
    ator = Instance.new("Animator")
    ator.Name = "Animator"
    ator.Parent = hum
    created = true
  end
  return o, hum, ator, created
end
local function animJoints(rig)
  local j, seen = {}, {}
  for _, d in ipairs(rig:GetDescendants()) do
    if d:IsA("Motor6D") and d.Part1 then
      local nm = d.Part1.Name
      assert(not seen[nm], "rig com parts de mesmo nome (" .. nm .. "); animacao exige nomes distintos.")
      seen[nm] = true
      j[nm] = d
    end
  end
  return j
end
local function animKeysSorted(seq)
  local ks = seq:GetKeyframes()
  table.sort(ks, function(a, b) return a.Time < b.Time end)
  return ks
end
local function animLength(seq)
  local m = 0
  for _, k in ipairs(seq:GetKeyframes()) do m = math.max(m, k.Time or 0) end
  return m
end
local function animPoseMap(kf)
  local m = {}
  local function rec(list)
    for _, p in ipairs(list) do m[p.Name] = p rec(p:GetSubPoses()) end
  end
  rec(kf:GetPoses())
  return m
end
local function animFindKey(seq, time)
  local best, bd = nil, 1e-4
  for _, k in ipairs(seq:GetKeyframes()) do
    local d = math.abs((k.Time or 0) - time)
    if d < bd then best, bd = k, d end
  end
  return best
end
local function animCapture(rig, kf)
  local joints = animJoints(rig)
  local parts = {}
  for _, d in ipairs(rig:GetDescendants()) do
    if d:IsA("BasePart") then parts[d.Name] = d end
  end
  local poses = {}
  local names = {}
  for n in pairs(parts) do names[#names + 1] = n end
  table.sort(names)
  for _, n in ipairs(names) do
    local p = Instance.new("Pose")
    p.Name = n
    local m = joints[n]
    if m and m.Transform then p.CFrame = m.Transform else p.CFrame = CFrame.new() end
    p.Weight = 1
    poses[n] = p
  end
  for n, m in pairs(joints) do
    local par = (m.Part0 and m.Part0.Name) or nil
    if par and poses[par] then poses[par]:AddSubPose(poses[n]) end
  end
  local top = 0
  for _, p in pairs(poses) do
    if p.Parent == nil then kf:AddPose(p) top = top + 1 end
  end
  return #names, top
end
local function animSerPose(p, path)
  local cf = { p.CFrame:GetComponents() }
  local es, ed = p.EasingStyle, p.EasingDirection
  return { path = path,
    cf = { cf[1], cf[2], cf[3], cf[4], cf[5], cf[6], cf[7], cf[8], cf[9], cf[10], cf[11], cf[12] },
    w = p.Weight or 1, mw = p.MaskWeight or 1,
    es = (type(es) == "table" and es.Name) or "Linear",
    ed = (type(ed) == "table" and ed.Name) or "InOut" }
end
local function animSerKey(kf)
  local out = { time = kf.Time or 0, name = kf.Name, poses = {} }
  local function rec(list, path)
    for _, p in ipairs(list) do
      local np = {}
      for _, s in ipairs(path) do np[#np + 1] = s end
      np[#np + 1] = p.Name
      out.poses[#out.poses + 1] = animSerPose(p, np)
      rec(p:GetSubPoses(), np)
    end
  end
  rec(kf:GetPoses(), {})
  return out
end
local function animBuildKey(seq, data)
  local kf = Instance.new("Keyframe")
  kf.Name = tostring(data.name or "Key"):sub(1, 40)
  kf.Time = tonumber(data.time) or 0
  seq:AddKeyframe(kf)
  local byPath = { [""] = kf }
  for _, pd in ipairs(data.poses or {}) do
    local p = Instance.new("Pose")
    p.Name = tostring((pd.path or {})[#(pd.path or {})] or "Pose"):sub(1, 60)
    local c = pd.cf or {}
    p.CFrame = CFrame.new(c[1] or 0, c[2] or 0, c[3] or 0, c[4] or 1, c[5] or 0, c[6] or 0,
      c[7] or 0, c[8] or 1, c[9] or 0, c[10] or 0, c[11] or 0, c[12] or 1)
    p.Weight = tonumber(pd.w) or 1
    pcall(function() p.MaskWeight = tonumber(pd.mw) or 1 end)
    local es = tostring(pd.es or "Linear")
    if ANIMA.EASE_STYLE[es] then pcall(function() p.EasingStyle = Enum.PoseEasingStyle[es] end) end
    local ed = tostring(pd.ed or "InOut")
    if ANIMA.EASE_DIR[ed] then pcall(function() p.EasingDirection = Enum.PoseEasingDirection[ed] end) end
    local parentPath = ""
    for i = 1, #(pd.path or {}) - 1 do parentPath = parentPath .. "/" .. pd.path[i] end
    local par = byPath[parentPath]
    if par and par.AddSubPose and parentPath ~= "" then par:AddSubPose(p) else kf:AddPose(p) end
    local full = parentPath .. "/" .. p.Name
    byPath[full] = p
  end
  return kf
end
local function animAlpha(a, style, dir)
  if style == "Constant" then
    if dir == "InOut" then return (a < 0.5) and 0 or 1 end
    return (a >= 1) and 1 or 0
  end
  if style ~= "Linear" then return a, true end
  return a, false
end
local function animApply(sess, T)
  local ks = sess.keys
  if #ks == 0 then return false end
  local i0, i1 = 1, 1
  if T <= ks[1].Time then i0, i1 = 1, 1
  elseif T >= ks[#ks].Time then i0, i1 = #ks, #ks
  else
    for i = 1, #ks - 1 do
      if T >= ks[i].Time and T <= ks[i + 1].Time then i0, i1 = i, i + 1 break end
    end
  end
  local k0, k1 = ks[i0], ks[i1]
  local span = (k1.Time or 0) - (k0.Time or 0)
  local raw = (span > 1e-9) and ((T - (k0.Time or 0)) / span) or 0
  raw = math.clamp(raw, 0, 1)
  local m0, m1 = animPoseMap(k0), animPoseMap(k1)
  local approx = false
  for name, motor in pairs(sess.joints) do
    local p0, p1 = m0[name], m1[name]
    if p0 and p1 then
      local es = p0.EasingStyle
      local style = (type(es) == "table" and es.Name) or "Linear"
      local ed = p0.EasingDirection
      local dir = (type(ed) == "table" and ed.Name) or "InOut"
      local a, ap = animAlpha(raw, style, dir)
      if ap then approx = true end
      motor.Transform = p0.CFrame:Lerp(p1.CFrame, a)
    elseif p0 then
      motor.Transform = p0.CFrame
    elseif p1 then
      motor.Transform = p1.CFrame
    end
  end
  return approx
end
local function animSession(player, seq, rig)
  local sess = { seq = seq, rig = rig, joints = animJoints(rig),
    keys = animKeysSorted(seq), playing = false, time = 0, speed = 1, loop = false, track = nil }
  animPrev[player] = sess
  return sess
end
Run.Heartbeat:Connect(function(dt)
  for player, sess in pairs(animPrev) do
    if sess.playing and sess.seq and sess.seq.Parent then
      local len = animLength(sess.seq)
      sess.time = sess.time + dt * (sess.speed or 1)
      if len <= 0 then sess.time = 0
      elseif sess.time >= len then
        if sess.loop then sess.time = sess.time % len
        else sess.time = len sess.playing = false end
      end
      pcall(animApply, sess, sess.time)
    end
  end
end)
function handlers.AnimRig(player, payload)
  local rig, hum, ator, created = animRigOf(payload.id)
  local joints = animJoints(rig)
  local names = {}
  for n in pairs(joints) do names[#names + 1] = n end
  table.sort(names)
  local parts = 0
  for _, d in ipairs(rig:GetDescendants()) do if d:IsA("BasePart") then parts = parts + 1 end end
  if created then queueObject(hum) end
  return { node = record(rig), joints = names, parts = parts,
    animatorCreated = created, msg = ("Rig %s: %d juntas."):format(rig.Name, #names) }
end
function handlers.AnimNew(player, payload)
  local seq = Instance.new("KeyframeSequence")
  seq.Name = tostring(payload.name or "Animacao"):sub(1, 40)
  seq.Loop = payload.loop == true
  local pri = tostring(payload.priority or "Action")
  if ANIMA.PRI[pri] then pcall(function() seq.Priority = Enum.AnimationPriority[pri] end) end
  local parent = game:GetService("ServerStorage")
  if payload.parentId then
    local ok, p = pcall(getObject, payload.parentId)
    if ok and p then parent = p end
  end
  seq.Parent = parent
  created[player] = (created[player] or 0) + 1
  register(seq)
  queueObject(parent)
  hCreate(player, seq)
  if payload.rigId then
    local ok, rig = pcall(getObject, payload.rigId)
    if ok and rig and rig:IsA("Model") then
      local kf = Instance.new("Keyframe")
      kf.Name = "K0"
      kf.Time = 0
      seq:AddKeyframe(kf)
      pcall(animCapture, rig, kf)
    end
  end
  return { node = record(seq), length = animLength(seq), msg = "Sequencia criada." }
end
function handlers.AnimKeys(player, payload)
  local seq = animGetSeq(payload.id)
  local out = {}
  for _, k in ipairs(animKeysSorted(seq)) do
    local n = 0
    local function cnt(list) for _, p in ipairs(list) do n = n + 1 cnt(p:GetSubPoses()) end end
    cnt(k:GetPoses())
    out[#out + 1] = { time = k.Time or 0, name = k.Name, poses = n }
  end
  return { keys = out, length = animLength(seq) }
end
function handlers.AnimKeyAdd(player, payload)
  local seq = animGetSeq(payload.id)
  local time = math.clamp(tonumber(payload.time) or 0, 0, 120)
  assert(#seq:GetKeyframes() < 200, "Sequencia cheia (200 keys).")
  assert(not animFindKey(seq, time), "Ja existe key nesse tempo.")
  local kf = Instance.new("Keyframe")
  kf.Name = tostring(payload.name or ("K" .. tostring(math.floor(time * 30)))):sub(1, 40)
  kf.Time = time
  seq:AddKeyframe(kf)
  local poses = 0
  if payload.rigId then
    local ok, rig = pcall(getObject, payload.rigId)
    assert(ok and rig and rig:IsA("Model"), "rigId invalido.")
    poses = animCapture(rig, kf)
  end
  queueObject(seq)
  pushHist(player, {
    label = "Add key " .. string.format("%.2f", time),
    undo = function() pcall(function() seq:RemoveKeyframe(kf) end) queueObject(seq) end,
    redo = function() pcall(function() seq:AddKeyframe(kf) end) queueObject(seq) end,
  })
  return { time = time, poses = poses, length = animLength(seq) }
end
function handlers.AnimKeyDel(player, payload)
  local seq = animGetSeq(payload.id)
  local kf = animFindKey(seq, tonumber(payload.time) or 0)
  assert(kf, "Key nao encontrada nesse tempo.")
  local snap = animSerKey(kf)
  seq:RemoveKeyframe(kf)
  queueObject(seq)
  pushHist(player, {
    label = "Del key " .. string.format("%.2f", snap.time),
    undo = function() pcall(animBuildKey, seq, snap) queueObject(seq) end,
    redo = function()
      pcall(function()
        local k2 = animFindKey(seq, snap.time)
        if k2 then seq:RemoveKeyframe(k2) end
      end)
      queueObject(seq)
    end,
  })
  return { deleted = true, time = snap.time, length = animLength(seq) }
end
function handlers.AnimPoseSet(player, payload)
  local seq = animGetSeq(payload.id)
  local kf = animFindKey(seq, tonumber(payload.time) or 0)
  assert(kf, "Key nao encontrada nesse tempo.")
  local part = tostring(payload.part or "")
  assert(#part > 0 and #part <= 60, "part invalida.")
  local pos = payload.pos or {}
  local rot = payload.rot or {}
  local cf = nil
  if payload.pos ~= nil or payload.rot ~= nil then
    cf = CFrame.new(tonumber(pos.x) or 0, tonumber(pos.y) or 0, tonumber(pos.z) or 0)
      * CFrame.fromOrientation(math.rad(tonumber(rot.x) or 0), math.rad(tonumber(rot.y) or 0), math.rad(tonumber(rot.z) or 0))
  end
  local map = animPoseMap(kf)
  local pose = map[part]
  local created = false
  local old = nil
  if pose then
    local oes, oed = pose.EasingStyle, pose.EasingDirection
    old = { cf = pose.CFrame, w = pose.Weight,
      es = (type(oes) == "table" and oes.Name) or "Linear",
      ed = (type(oed) == "table" and oed.Name) or "InOut" }
  else
    local n = 0
    local function cnt(list) for _, p in ipairs(list) do n = n + 1 cnt(p:GetSubPoses()) end end
    cnt(kf:GetPoses())
    assert(n < 500, "Key cheia (500 poses).")
    pose = Instance.new("Pose")
    pose.Name = part
    local par = nil
    if payload.rigId then
      local ok, rig = pcall(getObject, payload.rigId)
      if ok and rig then
        for _, d in ipairs(rig:GetDescendants()) do
          if d:IsA("Motor6D") and d.Part1 and d.Part1.Name == part and d.Part0 then
            par = map[d.Part0.Name]
            break
          end
        end
      end
    end
    if par then par:AddSubPose(pose) else kf:AddPose(pose) end
    created = true
  end
  if cf then pose.CFrame = cf elseif created then pose.CFrame = CFrame.new() end
  if payload.weight ~= nil then pose.Weight = math.clamp(tonumber(payload.weight) or 1, 0, 10) end
  local es = payload.easingStyle and tostring(payload.easingStyle) or nil
  if es then
    assert(ANIMA.EASE_STYLE[es], "easingStyle: Linear/Constant/Elastic/Cubic/Bounce/CubicV2.")
    pcall(function() pose.EasingStyle = Enum.PoseEasingStyle[es] end)
  end
  local ed = payload.easingDir and tostring(payload.easingDir) or nil
  if ed then
    assert(ANIMA.EASE_DIR[ed], "easingDir: In/Out/InOut.")
    pcall(function() pose.EasingDirection = Enum.PoseEasingDirection[ed] end)
  end
  queueObject(seq)
  pushHist(player, {
    label = "Pose " .. part,
    undo = function()
      pcall(function()
        if created then
          if pose.Parent then pose.Parent = nil end
        else
          pose.CFrame = old.cf pose.Weight = old.w
          pose.EasingStyle = Enum.PoseEasingStyle[old.es]
          pose.EasingDirection = Enum.PoseEasingDirection[old.ed]
        end
      end)
      queueObject(seq)
    end,
    redo = function()
      pcall(function()
        if created and pose.Parent == nil then kf:AddPose(pose) end
        if cf then pose.CFrame = cf end
      end)
      queueObject(seq)
    end,
  })
  return { ok2 = true, created = created }
end
function handlers.AnimJointSet(player, payload)
  local rig = getObject(payload.rigId)
  assert(rig and rig:IsA("Model"), "rigId invalido.")
  local part = tostring(payload.part or "")
  assert(#part > 0, "part invalida.")
  local motor = nil
  for _, d in ipairs(rig:GetDescendants()) do
    if d:IsA("Motor6D") and d.Part1 and d.Part1.Name == part then motor = d break end
  end
  assert(motor, "junta nao achada: " .. part)
  local pos = payload.pos or {}
  local rot = payload.rot or {}
  motor.Transform = CFrame.new(tonumber(pos.x) or 0, tonumber(pos.y) or 0, tonumber(pos.z) or 0)
    * CFrame.fromOrientation(math.rad(tonumber(rot.x) or 0), math.rad(tonumber(rot.y) or 0), math.rad(tonumber(rot.z) or 0))
  return { posed = true, part = part }
end
function handlers.AnimPlay(player, payload)
  local seq = animGetSeq(payload.id)
  local rig = getObject(payload.rigId)
  assert(rig and rig:IsA("Model"), "rigId invalido.")
  animRigOf(payload.rigId)
  local sess = animSession(player, seq, rig)
  sess.loop = payload.loop == true
  sess.speed = math.clamp(tonumber(payload.speed) or 1, 0.1, 4)
  sess.time = math.clamp(tonumber(payload.from) or 0, 0, math.max(animLength(seq), 0.001))
  sess.keys = animKeysSorted(seq)
  sess.playing = true
  local trackLoaded = false
  if payload.animationId and #tostring(payload.animationId) > 0 then
    pcall(function()
      local ator = rig:FindFirstChildWhichIsA("Humanoid", true):FindFirstChildOfClass("Animator")
        or rig:FindFirstChildWhichIsA("AnimationController", true):FindFirstChildOfClass("Animator")
      if ator then
        local anim = Instance.new("Animation")
        anim.AnimationId = tostring(payload.animationId)
        local tr = ator:LoadAnimation(anim)
        tr.Looped = sess.loop
        tr:Play(0.1, 1, sess.speed)
        sess.track = tr
        trackLoaded = true
      end
    end)
  end
  local approx = animApply(sess, sess.time)
  local nj = 0
  for _ in pairs(sess.joints) do nj = nj + 1 end
  return { playing = true, length = animLength(seq), joints = nj,
    trackLoaded = trackLoaded, approx = approx,
    msg = approx and "Tocando (preview linear; easing real apos publish)."
      or "Tocando (preview exato)." }
end
function handlers.AnimStop(player, payload)
  local sess = animPrev[player]
  if sess and sess.track then pcall(function() sess.track:Stop() end) end
  if sess then
    for _, m in pairs(sess.joints) do pcall(function() m.Transform = CFrame.new() end) end
    sess.playing = false
    sess.time = 0
  end
  animPrev[player] = nil
  return { stopped = true, msg = "Parado (rig em repouso)." }
end
function handlers.AnimScrub(player, payload)
  local rig = getObject(payload.rigId)
  assert(rig and rig:IsA("Model"), "rigId invalido.")
  local sess = animPrev[player]
  if not sess or (payload.id and sess.seq ~= animGetSeq(payload.id)) then
    assert(payload.id, "seq id necessaria p/ iniciar sessao.")
    sess = animSession(player, animGetSeq(payload.id), rig)
  end
  sess.keys = animKeysSorted(sess.seq)
  sess.playing = false
  local len = animLength(sess.seq)
  local cursor = math.clamp(tonumber(payload.time) or 0, 0, 120)
  sess.time = math.clamp(cursor, 0, math.max(len, 0.001))
  local approx = animApply(sess, sess.time)
  return { time = cursor, applied = sess.time, length = len, approx = approx }
end
function handlers.AnimIK(player, payload)
  local rig, hum = animRigOf(payload.rigId)
  local ee = nil
  for _, d in ipairs(rig:GetDescendants()) do
    if d.Name == tostring(payload.endName or "") and (d:IsA("BasePart") or d:IsA("Attachment") or d:IsA("Motor6D")) then
      ee = d break
    end
  end
  assert(ee, "endEffector nao achado no rig (part/attachment/motor).")
  local tgt = getObject(payload.targetId)
  assert(tgt and (tgt:IsA("BasePart") or tgt:IsA("Attachment")), "targetId precisa ser part/attachment.")
  local ik = hum:FindFirstChild("ArkherIK")
  if not (ik and ik:IsA("IKControl")) then
    ik = Instance.new("IKControl")
    ik.Name = "ArkherIK"
    ik.Parent = hum
    created[player] = (created[player] or 0) + 1
    register(ik)
    hCreate(player, ik)
  end
  ik.EndEffector = ee
  ik.Target = tgt
  if payload.rootName then
    local root = nil
    for _, d in ipairs(rig:GetDescendants()) do
      if d.Name == tostring(payload.rootName) and (d:IsA("BasePart") or d:IsA("Motor6D")) then
        root = d break
      end
    end
    assert(root, "chainRoot nao achado no rig.")
    ik.ChainRoot = root
  else
    ik.ChainRoot = rig:FindFirstChild("HumanoidRootPart") or rig:FindFirstChildWhichIsA("BasePart", true)
  end
  local tp = tostring(payload.type or "Transform")
  assert(tp == "Transform" or tp == "Position" or tp == "Rotation" or tp == "LookAt", "type: Transform/Position/Rotation/LookAt.")
  pcall(function() ik.Type = Enum.IKControlType[tp] end)
  ik.Weight = math.clamp(tonumber(payload.weight) or 1, 0, 1)
  if payload.enabled ~= nil then ik.Enabled = payload.enabled == true end
  queueObject(hum)
  return { node = record(ik), msg = "IK configurado (" .. tp .. ")." }
end
function handlers.AnimExport(player, payload)
  local seq = animGetSeq(payload.id)
  local pri = seq.Priority
  local data = { v = 1, name = seq.Name, loop = seq.Loop == true,
    priority = (type(pri) == "table" and pri.Name) or "Action", keys = {} }
  for _, k in ipairs(animKeysSorted(seq)) do data.keys[#data.keys + 1] = animSerKey(k) end
  local ok, json = pcall(function() return Http:JSONEncode(data) end)
  assert(ok and json, "Falha ao serializar.")
  assert(#json <= 2000000, "Animacao grande demais (2MB).")
  return { json = json, keys = #data.keys }
end
function handlers.AnimImport(player, payload)
  local raw = tostring(payload.json or "")
  assert(#raw > 0 and #raw <= 2000000, "JSON vazio ou grande demais (2MB).")
  local ok, data = pcall(function() return Http:JSONDecode(raw) end)
  assert(ok and type(data) == "table" and type(data.keys) == "table", "JSON de animacao invalido.")
  assert(#data.keys >= 1 and #data.keys <= 200, "keys fora do limite (1..200).")
  local seq = Instance.new("KeyframeSequence")
  seq.Name = tostring(payload.name or data.name or "Animacao"):sub(1, 40)
  seq.Loop = data.loop == true
  local pri = tostring(data.priority or "Action")
  if ANIMA.PRI[pri] then pcall(function() seq.Priority = Enum.AnimationPriority[pri] end) end
  seq.Parent = game:GetService("ServerStorage")
  for _, kd in ipairs(data.keys) do
    assert(type(kd.time) == "number" and kd.time >= 0 and kd.time <= 120, "key time invalido.")
    assert(type(kd.poses) == "table" and #kd.poses <= 500, "poses demais (500).")
    animBuildKey(seq, kd)
  end
  created[player] = (created[player] or 0) + 1
  register(seq)
  queueObject(seq)
  hCreate(player, seq)
  return { node = record(seq), keys = #data.keys, length = animLength(seq),
    msg = ("Animacao importada (%d keys)."):format(#data.keys) }
end

-- ============ R14a: UI EDITOR (PlayerGui ao vivo, escopo validado) ============
local UI_CLASS = { Frame = true, TextLabel = true, TextButton = true, TextBox = true,
  ImageLabel = true, ImageButton = true, ScrollingFrame = true, ScreenGui = true,
  UICorner = true, UIStroke = true, UIGradient = true, UIPadding = true,
  UIListLayout = true, UIGridLayout = true }
local function uiPlayerGui(player)
  local pg = player:FindFirstChild("PlayerGui")
  if not pg then
    pg = Instance.new("PlayerGui")
    pg.Name = "PlayerGui"
    pg.Parent = player
  end
  return pg
end
local function uiRootGui(player)
  local pg = uiPlayerGui(player)
  local g = pg:FindFirstChild("ArkherUI")
  if not (g and g:IsA("ScreenGui")) then
    g = Instance.new("ScreenGui")
    g.Name = "ArkherUI"
    g.Parent = pg
    register(g)
  end
  return g
end
local function uiScope(player, o)
  local pg = uiPlayerGui(player)
  local sg = game:GetService("StarterGui")
  local p = o
  while p do
    if p == pg or p == sg then return true end
    p = p.Parent
  end
  return false
end
local function uiGet(player, id)
  local o = getObject(id)
  assert(o and uiScope(player, o), "UI fora do escopo (PlayerGui/StarterGui).")
  return o
end
local function uiEnumName(v)
  if type(v) == "table" and v.Name then return tostring(v.Name) end
  return nil
end
local function uiSer(o, depth)
  depth = depth or 0
  assert(depth <= 12, "UI profunda demais (12).")
  assert(UI_CLASS[o.ClassName], "classe UI nao suportada: " .. tostring(o.ClassName))
  local d = { class = o.ClassName, name = o.Name }
  local okP, pos = pcall(function() return o.Position end)
  if okP and pos and type(pos.X) == "table" and pos.X.Scale then
    d.pos = { pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset }
  end
  local okS, sz = pcall(function() return o.Size end)
  if okS and sz and type(sz.X) == "table" and sz.X.Scale then
    d.size = { sz.X.Scale, sz.X.Offset, sz.Y.Scale, sz.Y.Offset }
  end
  local function num(k) pcall(function() d[k] = o[k] end) end
  local function col(k)
    pcall(function()
      local c = o[k]
      if c and c.R then d[k] = { c.R, c.G, c.B } end
    end)
  end
  local function str(k) pcall(function()
    if type(o[k]) == "string" then d[k] = o[k] end
  end) end
  local function en(k) pcall(function()
    local n = uiEnumName(o[k])
    if n then d[k] = n end
  end) end
  local function boo(k) pcall(function()
    if type(o[k]) == "boolean" then d[k] = o[k] end
  end) end
  num("BackgroundTransparency") num("Rotation") num("ZIndex") num("LayoutOrder")
  num("TextSize") num("BorderSizePixel") num("Thickness") num("ScrollBarThickness")
  num("CornerRadius") col("BackgroundColor3") col("TextColor3") col("BorderColor3")
  col("Color") str("Text") str("PlaceholderText") str("Image")
  en("Font") en("TextXAlignment") en("TextYAlignment") en("ScaleType")
  en("HorizontalAlignment") en("VerticalAlignment") en("FillDirection")
  en("SortOrder") en("AutomaticSize")
  boo("Visible") boo("Active") boo("ClipsDescendants") boo("AutoButtonColor")
  boo("TextWrapped") boo("TextScaled") boo("MultiLine") boo("ClearTextOnFocus")
  boo("ApplyStrokeMode")
  pcall(function()
    local ap = o.AnchorPoint
    if ap and ap.X then d.anchor = { ap.X, ap.Y } end
  end)
  pcall(function()
    local cr = o.CornerRadius
    if cr and cr.Scale ~= nil then d.corner = { cr.Scale, cr.Offset } d.CornerRadius = nil end
  end)
  d.kids = {}
  for _, c in ipairs(o:GetChildren()) do
    if UI_CLASS[c.ClassName] then d.kids[#d.kids + 1] = uiSer(c, depth + 1) end
  end
  return d
end
local function uiCount(d)
  local n = 1
  for _, k in ipairs(d.kids or {}) do n = n + uiCount(k) end
  return n
end
local function uiBuild(parent, d)
  assert(UI_CLASS[d.class], "classe UI nao suportada: " .. tostring(d.class))
  local o = Instance.new(d.class)
  o.Name = tostring(d.name or d.class):sub(1, 60)
  if d.pos then pcall(function()
    o.Position = UDim2.new(d.pos[1] or 0, d.pos[2] or 0, d.pos[3] or 0, d.pos[4] or 0)
  end) end
  if d.size then pcall(function()
    o.Size = UDim2.new(d.size[1] or 0, d.size[2] or 0, d.size[3] or 0, d.size[4] or 0)
  end) end
  if d.anchor then pcall(function() o.AnchorPoint = Vector2.new(d.anchor[1], d.anchor[2]) end) end
  if d.corner then pcall(function() o.CornerRadius = UDim.new(d.corner[1], d.corner[2]) end) end
  for _, k in ipairs({ "BackgroundTransparency", "Rotation", "ZIndex", "LayoutOrder",
    "TextSize", "BorderSizePixel", "Thickness", "ScrollBarThickness" }) do
    if d[k] ~= nil then pcall(function() o[k] = tonumber(d[k]) or o[k] end) end
  end
  for _, k in ipairs({ "BackgroundColor3", "TextColor3", "BorderColor3", "Color" }) do
    if d[k] then pcall(function() o[k] = Color3.new(d[k][1], d[k][2], d[k][3]) end) end
  end
  for _, k in ipairs({ "Text", "PlaceholderText", "Image" }) do
    if d[k] ~= nil then pcall(function() o[k] = tostring(d[k]):sub(1, 4000) end) end
  end
  local enumOf = { Font = "Font", TextXAlignment = "TextXAlignment", TextYAlignment = "TextYAlignment",
    ScaleType = "ScaleType", HorizontalAlignment = "HorizontalAlignment",
    VerticalAlignment = "VerticalAlignment", FillDirection = "FillDirection",
    SortOrder = "SortOrder", AutomaticSize = "AutomaticSize", ApplyStrokeMode = "ApplyStrokeMode" }
  for k, en in pairs(enumOf) do
    if d[k] then pcall(function() o[k] = Enum[en][tostring(d[k])] end) end
  end
  for _, k in ipairs({ "Visible", "Active", "ClipsDescendants", "AutoButtonColor",
    "TextWrapped", "TextScaled", "MultiLine", "ClearTextOnFocus" }) do
    if d[k] ~= nil then pcall(function() o[k] = (d[k] == true) end) end
  end
  o.Parent = parent
  for _, k in ipairs(d.kids or {}) do uiBuild(o, k) end
  return o
end
function handlers.UiRoot(player, payload)
  local g = uiRootGui(player)
  queueObject(g)
  return { node = record(g) }
end
function handlers.UiNew(player, payload)
  local class = tostring(payload.class or "Frame")
  assert(UI_CLASS[class] and class ~= "ScreenGui", "classe UI: Frame/Label/Button/Box/Image/Scroll/Corner/Stroke/...")
  local parent = uiRootGui(player)
  if payload.parentId then
    local p = uiGet(player, payload.parentId)
    assert(p:IsA("GuiObject") or p:IsA("LayerCollector"), "pai precisa ser GuiObject/ScreenGui.")
    parent = p
  end
  local o = Instance.new(class)
  o.Name = tostring(payload.name or class):sub(1, 60)
  pcall(function() o.Size = UDim2.fromOffset(200, 50) end)
  pcall(function() o.Position = UDim2.fromOffset(80, 80) end)
  o.Parent = parent
  created[player] = (created[player] or 0) + 1
  register(o)
  queueObject(parent)
  hCreate(player, o)
  return { node = record(o) }
end
function handlers.UiDelete(player, payload)
  local o = uiGet(player, payload.id)
  assert(not (o:IsA("ScreenGui") and o.Name == "ArkherUI"), "raiz ArkherUI protegida.")
  local snap = uiSer(o)
  local parent = o.Parent
  o:Destroy()
  queueObject(parent)
  pushHist(player, {
    label = "UI delete " .. snap.name,
    undo = function() pcall(uiBuild, parent, snap) queueObject(parent) end,
    redo = function()
      pcall(function()
        local again = nil
        for _, c in ipairs(parent:GetChildren()) do
          if c.Name == snap.name and c.ClassName == snap.class then again = c break end
        end
        if again then again:Destroy() end
      end)
      queueObject(parent)
    end,
  })
  return { deleted = true }
end
function handlers.UiDup(player, payload)
  local o = uiGet(player, payload.id)
  local snap = uiSer(o)
  snap.name = (snap.name .. "Copy"):sub(1, 60)
  local c = uiBuild(o.Parent, snap)
  created[player] = (created[player] or 0) + 1
  register(c)
  queueObject(o.Parent)
  hCreate(player, c)
  return { node = record(c) }
end
function handlers.UiMove(player, payload)
  local o = uiGet(player, payload.id)
  assert(o:IsA("GuiObject"), "UiMove so em GuiObject.")
  local pos = o.Position
  local dx = math.clamp(tonumber(payload.dx) or 0, -5000, 5000)
  local dy = math.clamp(tonumber(payload.dy) or 0, -5000, 5000)
  o.Position = UDim2.new(pos.X.Scale, pos.X.Offset + dx, pos.Y.Scale, pos.Y.Offset + dy)
  return { x = o.Position.X.Offset, y = o.Position.Y.Offset }
end
function handlers.UiText(player, payload)
  local o = uiGet(player, payload.id)
  assert(o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox"), "UiText so em texto.")
  o.Text = tostring(payload.text or ""):sub(1, 4000)
  return { text = o.Text }
end
function handlers.UiSize(player, payload)
  local o = uiGet(player, payload.id)
  assert(o:IsA("GuiObject"), "UiSize so em GuiObject.")
  local sz = o.Size
  local dw = math.clamp(tonumber(payload.dw) or 0, -5000, 5000)
  local dh = math.clamp(tonumber(payload.dh) or 0, -5000, 5000)
  local nx = math.max(sz.X.Offset + dw, 1)
  local ny = math.max(sz.Y.Offset + dh, 1)
  o.Size = UDim2.new(sz.X.Scale, nx, sz.Y.Scale, ny)
  return { w = nx, h = ny }
end
function handlers.UiTree(player, payload)
  local g = uiRootGui(player)
  local out = {}
  local n = 0
  local function rec(o, depth)
    if n >= 500 then return end
    n = n + 1
    local x, y, w, h = nil, nil, nil, nil
    pcall(function()
      local p2 = o.Position
      x, y = p2.X.Offset, p2.Y.Offset
    end)
    pcall(function()
      local s2 = o.Size
      w, h = s2.X.Offset, s2.Y.Offset
    end)
    out[#out + 1] = { id = idOf[o], name = o.Name, class = o.ClassName, depth = depth,
      x = x, y = y, w = w, h = h }
    for _, c in ipairs(o:GetChildren()) do
      if UI_CLASS[c.ClassName] then rec(c, depth + 1) end
    end
  end
  for _, c in ipairs(g:GetChildren()) do
    if UI_CLASS[c.ClassName] then rec(c, 0) end
  end
  return { items = out, total = n }
end
function handlers.UiExport(player, payload)
  local o = uiGet(player, payload.id)
  local data = { v = 1, ui = uiSer(o) }
  local ok, json = pcall(function() return Http:JSONEncode(data) end)
  assert(ok and json, "Falha ao serializar UI.")
  assert(#json <= 2000000, "UI grande demais (2MB).")
  return { json = json, nodes = uiCount(data.ui) }
end
function handlers.UiImport(player, payload)
  local raw = tostring(payload.json or "")
  assert(#raw > 0 and #raw <= 2000000, "JSON vazio ou grande demais (2MB).")
  local ok, data = pcall(function() return Http:JSONDecode(raw) end)
  assert(ok and type(data) == "table" and type(data.ui) == "table", "JSON de UI invalido.")
  assert(uiCount(data.ui) <= 2000, "UI com nos demais (2000).")
  local parent = uiRootGui(player)
  if payload.parentId then
    local p = uiGet(player, payload.parentId)
    assert(p:IsA("GuiObject") or p:IsA("LayerCollector"), "pai precisa ser GuiObject/ScreenGui.")
    parent = p
  end
  local o = uiBuild(parent, data.ui)
  created[player] = (created[player] or 0) + 1
  register(o)
  queueObject(parent)
  hCreate(player, o)
  return { node = record(o), nodes = uiCount(data.ui), msg = "UI importada." }
end
function handlers.UiPublish(player, payload)
  local o = uiGet(player, payload.id)
  assert(o:IsA("ScreenGui"), "UiPublish: selecione a ScreenGui raiz.")
  local sg = game:GetService("StarterGui")
  local old = sg:FindFirstChild(o.Name)
  if old then pcall(function() old:Destroy() end) end
  local snap = uiSer(o)
  local c = uiBuild(sg, snap)
  created[player] = (created[player] or 0) + 1
  register(c)
  queueObject(sg)
  return { node = record(c), msg = "UI publicada em StarterGui (vale no respawn)." }
end

-- ============ R14b: RRW (pipeline de render real: perfil/FX/ceu/clima/LOD/VFX) ============
local RRWS = {
  FX = { BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true,
  DepthOfFieldEffect = true, SunRaysEffect = true, ColorGradingEffect = true },
  NUM = {
  BloomEffect = { Intensity = { 0, 10 }, Size = { 0, 100 }, Threshold = { 0, 2 } },
  BlurEffect = { Size = { 0, 100 } },
  ColorCorrectionEffect = { Brightness = { -1, 1 }, Contrast = { -1, 1 }, Saturation = { -1, 1 } },
  DepthOfFieldEffect = { FocusDistance = { 0, 100000 }, InFocusRadius = { 0, 100 },
    NearIntensity = { 0, 1 }, FarIntensity = { 0, 1 } },
  SunRaysEffect = { Intensity = { 0, 10 }, Spread = { 0, 1 } },
  ColorGradingEffect = {},
  },
  sky = { mode = "off", speed = 0.1 },
  lod = {},
  fps = { ema = 60, n = 0 },
}
local function uiEnumName2(v)
  if type(v) == "table" and v.Name then return tostring(v.Name) end
  return nil
end
local function rrwLighting()
  return game:GetService("Lighting")
end
local function rrwSetStyle(L, style)
  local via = {}
  pcall(function() L.LightingStyle = Enum.LightingStyle[style] via.style = true end)
  if style == "Realistic" then
    pcall(function() L.Technology = Enum.Technology.Future via.tech = true end)
  elseif style == "Soft" then
    pcall(function() L.Technology = Enum.Technology.ShadowMap via.tech = true end)
  end
  return via
end
Run.Heartbeat:Connect(function(dt)
  if dt and dt > 0 then
    RRWS.fps.n = RRWS.fps.n + 1
    local f = 1 / dt
    RRWS.fps.ema = RRWS.fps.ema * 0.95 + math.min(f, 1000) * 0.05
  end
  if RRWS.sky.mode == "cycle" then
    pcall(function()
      local L = rrwLighting()
      L.ClockTime = ((L.ClockTime or 12) + dt * (RRWS.sky.speed or 0.1)) % 24
    end)
  end
  for name, g in pairs(RRWS.lod) do
    pcall(function()
      local cam = workspace.CurrentCamera
      if not cam then return end
      local cp = cam.CFrame.Position
      local fp = g.focus
      if not fp then
        local ok, cf = pcall(function() return g.tiers[1].o:GetBoundingBox() end)
        fp = (ok and cf) and cf.Position or Vector3.new(0, 0, 0)
      end
      local dist = (cp - fp).Magnitude
      g.dist = dist
      local want = #g.tiers
      for i, t in ipairs(g.tiers) do
        if dist <= t.dist then want = i break end
      end
      if want ~= g.active then
        local cur = g.tiers[g.active]
        local margin = (want > g.active) and 1.1 or 0.9
        local edge = (want > g.active) and cur.dist or g.tiers[want].dist
        if (want > g.active and dist > edge * margin) or (want < g.active and dist < edge * margin) then
          local stash = game:GetService("ServerStorage"):FindFirstChild("ArkherLOD")
          if not stash then
            stash = Instance.new("Folder")
            stash.Name = "ArkherLOD"
            stash.Parent = game:GetService("ServerStorage")
          end
          cur.o.Parent = stash
          local nw = g.tiers[want]
          nw.o.Parent = nw.orig
          g.active = want
        end
      end
    end)
  end
end)
function handlers.RrwProfile(player, payload)
  local L = rrwLighting()
  local snapL = nil
  pcall(function()
    snapL = { b = L.Brightness, ct = L.ClockTime, gl = L.GeographicLatitude,
      amb = L.Ambient, oamb = L.OutdoorAmbient, exp = L.ExposureCompensation,
      gs = L.GlobalShadows, fc = L.FogColor, fs = L.FogStart, fe = L.FogEnd }
  end)
  local p = tostring(payload.preset or "Realista")
  local function C(r, g, b) return Color3.fromRGB(r, g, b) end
  local style = "Realistic"
  if p == "Realista" then
    L.Brightness = 2 L.ClockTime = 14 L.GeographicLatitude = 40
    L.Ambient = C(70, 70, 80) L.OutdoorAmbient = C(120, 120, 130)
    L.ExposureCompensation = -0.2 L.GlobalShadows = true
    L.FogColor = C(190, 200, 210) L.FogStart = 500 L.FogEnd = 100000
  elseif p == "Showcase" then
    L.Brightness = 2 L.ClockTime = 17.5 L.GeographicLatitude = 25
    L.Ambient = C(80, 70, 75) L.OutdoorAmbient = C(150, 120, 110)
    L.ExposureCompensation = 0 L.GlobalShadows = true
    L.FogColor = C(200, 180, 170) L.FogStart = 200 L.FogEnd = 50000
  elseif p == "Horror" then
    L.Brightness = 1 L.ClockTime = 0 L.GeographicLatitude = 0
    L.Ambient = C(5, 5, 10) L.OutdoorAmbient = C(10, 12, 25)
    L.ExposureCompensation = -0.5 L.GlobalShadows = true
    L.FogColor = C(0, 0, 0) L.FogStart = 0 L.FogEnd = 80
  elseif p == "Mobile" then
    style = "Soft"
    L.Brightness = 2 L.ClockTime = 14 L.GeographicLatitude = 40
    L.Ambient = C(90, 90, 95) L.OutdoorAmbient = C(130, 130, 135)
    L.ExposureCompensation = 0 L.GlobalShadows = false
    L.FogColor = C(190, 200, 210) L.FogStart = 0 L.FogEnd = 0
  elseif p == "Estudio" then
    L.Brightness = 3 L.ClockTime = 12 L.GeographicLatitude = 0
    L.Ambient = C(150, 150, 150) L.OutdoorAmbient = C(180, 180, 180)
    L.ExposureCompensation = 0.2 L.GlobalShadows = false
    L.FogColor = C(255, 255, 255) L.FogStart = 0 L.FogEnd = 0
  else
    error("preset: Realista/Showcase/Horror/Mobile/Estudio.")
  end
  pcall(function() L.ShadowSoftness = 0.2 end)
  pcall(function() L.EnvironmentDiffuseScale = 1 end)
  pcall(function() L.EnvironmentSpecularScale = 1 end)
  local via = rrwSetStyle(L, style)
  queueObject(L)
  local oldL = snapL
  local newL = { b = L.Brightness, ct = L.ClockTime, gl = L.GeographicLatitude,
    amb = L.Ambient, oamb = L.OutdoorAmbient, exp = L.ExposureCompensation,
    gs = L.GlobalShadows, fc = L.FogColor, fs = L.FogStart, fe = L.FogEnd }
  local function applyL(s)
    L.Brightness = s.b L.ClockTime = s.ct L.GeographicLatitude = s.gl
    L.Ambient = s.amb L.OutdoorAmbient = s.oamb L.ExposureCompensation = s.exp
    L.GlobalShadows = s.gs L.FogColor = s.fc L.FogStart = s.fs L.FogEnd = s.fe
    queueObject(L)
  end
  pushHist(player, { label = "RRW perfil " .. p,
    undo = function() if oldL then pcall(applyL, oldL) end end,
    redo = function() pcall(applyL, newL) end })
  return { applied = true, preset = p, style = style, via = via,
    msg = ("Perfil %s (%s)."):format(p, style) }
end
function handlers.RrwFx(player, payload)
  local L = rrwLighting()
  local op = tostring(payload.op or "list")
  if op == "list" then
    local out = {}
    for _, c in ipairs(L:GetChildren()) do
      if RRWS.FX[c.ClassName] then
        out[#out + 1] = { class = c.ClassName, enabled = c.Enabled ~= false }
      end
    end
    return { items = out }
  end
  local class = tostring(payload.class or "")
  assert(RRWS.FX[class], "fx: Bloom/Blur/ColorCorrection/DepthOfField/SunRays/ColorGrading + Effect.")
  local fx = L:FindFirstChildOfClass(class)
  if op == "remove" then
    assert(fx, class .. " nao esta ativo.")
    fx:Destroy()
    queueObject(L)
    return { removed = true }
  end
  assert(op == "add" or op == "set", "op: add/set/remove/list.")
  local created = false
  if not fx then
    fx = Instance.new(class)
    fx.Name = class
    fx.Parent = L
    created = true
    register(fx)
  end
  local props = payload.props or {}
  local spec = RRWS.NUM[class] or {}
  for k, lim in pairs(spec) do
    if props[k] ~= nil then
      local v = tonumber(props[k])
      assert(v, k .. " precisa ser numero.")
      fx[k] = math.clamp(v, lim[1], lim[2])
    end
  end
  if props.TintColor and class == "ColorCorrectionEffect" then
    local t = props.TintColor
    fx.TintColor = Color3.new(math.clamp(tonumber(t[1]) or 1, 0, 1),
      math.clamp(tonumber(t[2]) or 1, 0, 1), math.clamp(tonumber(t[3]) or 1, 0, 1))
  end
  if payload.enabled ~= nil then fx.Enabled = payload.enabled == true end
  queueObject(L)
  return { ok2 = true, created = created, enabled = fx.Enabled ~= false }
end
function handlers.RrwSky(player, payload)
  local L0 = rrwLighting()
  if payload.mode == nil and payload.clockTime == nil and payload.speed == nil then
    return { mode = RRWS.sky.mode, speed = RRWS.sky.speed, clockTime = L0.ClockTime }
  end
  local mode = tostring(payload.mode or RRWS.sky.mode)
  assert(mode == "off" or mode == "static" or mode == "cycle", "mode: off/static/cycle.")
  RRWS.sky.mode = mode
  if payload.speed ~= nil then RRWS.sky.speed = math.clamp(tonumber(payload.speed) or 0.1, 0.001, 6) end
  local L = rrwLighting()
  if payload.clockTime ~= nil then
    L.ClockTime = math.clamp(tonumber(payload.clockTime) or 12, 0, 24) % 24
  end
  queueObject(L)
  return { mode = mode, speed = RRWS.sky.speed, clockTime = L.ClockTime }
end
function handlers.RrwAtmo(player, payload)
  local L = rrwLighting()
  local a = L:FindFirstChildOfClass("Atmosphere")
  if not a then
    a = Instance.new("Atmosphere")
    a.Name = "Atmosphere"
    a.Parent = L
    created[player] = (created[player] or 0) + 1
    register(a)
  end
  if payload.density ~= nil then a.Density = math.clamp(tonumber(payload.density) or 0.3, 0, 1) end
  if payload.offset ~= nil then a.Offset = math.clamp(tonumber(payload.offset) or 0.3, 0, 1) end
  if payload.decay ~= nil then a.Decay = Color3.new(math.clamp(tonumber(payload.decay[1]) or 1, 0, 1),
    math.clamp(tonumber(payload.decay[2]) or 1, 0, 1), math.clamp(tonumber(payload.decay[3]) or 1, 0, 1)) end
  if payload.color ~= nil then a.Color = Color3.new(math.clamp(tonumber(payload.color[1]) or 0.8, 0, 1),
    math.clamp(tonumber(payload.color[2]) or 0.8, 0, 1), math.clamp(tonumber(payload.color[3]) or 0.8, 0, 1)) end
  if payload.glare ~= nil then a.Glare = math.clamp(tonumber(payload.glare) or 0, 0, 1) end
  if payload.haze ~= nil then a.Haze = math.clamp(tonumber(payload.haze) or 0, 10) end
  queueObject(L)
  return { ok2 = true, density = a.Density, offset = a.Offset }
end
function handlers.RrwClouds(player, payload)
  local L = rrwLighting()
  local c = L:FindFirstChildOfClass("Clouds")
  if not c then
    c = Instance.new("Clouds")
    c.Name = "Clouds"
    c.Parent = L
    created[player] = (created[player] or 0) + 1
    register(c)
  end
  if payload.cover ~= nil then c.Cover = math.clamp(tonumber(payload.cover) or 0.5, 0, 1) end
  if payload.density ~= nil then c.Density = math.clamp(tonumber(payload.density) or 0.7, 0, 1) end
  if payload.color ~= nil then c.Color = Color3.new(math.clamp(tonumber(payload.color[1]) or 1, 0, 1),
    math.clamp(tonumber(payload.color[2]) or 1, 0, 1), math.clamp(tonumber(payload.color[3]) or 1, 0, 1)) end
  queueObject(L)
  return { ok2 = true, cover = c.Cover, density = c.Density }
end
function handlers.RrwLod(player, payload)
  local op = tostring(payload.op or "list")
  if op == "list" then
    local out = {}
    for name, g in pairs(RRWS.lod) do
      out[#out + 1] = { name = name, active = g.active, tiers = #g.tiers, dist = g.dist or -1 }
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return { groups = out }
  end
  if op == "remove" then
    local g = RRWS.lod[tostring(payload.name or "")]
    assert(g, "grupo LOD nao achado.")
    for _, t in ipairs(g.tiers) do pcall(function() t.o.Parent = t.orig end) end
    RRWS.lod[tostring(payload.name)] = nil
    return { removed = true }
  end
  assert(op == "register", "op: register/remove/list.")
  local name = tostring(payload.name or "")
  assert(#name > 0 and #name <= 40, "nome do grupo invalido.")
  assert(type(payload.tiers) == "table" and #payload.tiers >= 2 and #payload.tiers <= 5,
    "tiers: 2..5 (cada um {id, dist}).")
  local tiers = {}
  local lastD = -1
  for _, td in ipairs(payload.tiers) do
    local o = getObject(td.id)
    assert(o and o:IsA("Model"), "tier precisa ser Model.")
    local d = tonumber(td.dist)
    assert(d and d > 0 and d <= 20000, "dist invalida (0..20000).")
    assert(d > lastD, "tiers precisam de dist crescente.")
    lastD = d
    tiers[#tiers + 1] = { o = o, dist = d, orig = o.Parent }
  end
  local stash = game:GetService("ServerStorage"):FindFirstChild("ArkherLOD")
  if not stash then
    stash = Instance.new("Folder")
    stash.Name = "ArkherLOD"
    stash.Parent = game:GetService("ServerStorage")
  end
  for i = 2, #tiers do tiers[i].o.Parent = stash end
  RRWS.lod[name] = { tiers = tiers, active = 1, dist = -1, focus = nil }
  if payload.focusId then
    local ok, fo = pcall(getObject, payload.focusId)
    if ok and fo and fo:IsA("BasePart") then RRWS.lod[name].focus = fo.Position end
  end
  return { registered = true, name = name, tiers = #tiers }
end
function handlers.RrwVfx(player, payload)
  local preset = tostring(payload.preset or "")
  local parent = workspace
  if payload.parentId then
    local ok, p = pcall(getObject, payload.parentId)
    if ok and p then parent = p end
  end
  local made = {}
  local function emit(class, nm, props)
    local e = Instance.new(class)
    e.Name = nm
    for k, v in pairs(props or {}) do pcall(function() e[k] = v end) end
    e.Parent = parent
    made[#made + 1] = e
    return e
  end
  if preset == "Tocha" then
    emit("Fire", "ArkherFire", { Size = 5, Heat = 9 })
    emit("PointLight", "ArkherLight", { Brightness = 2, Range = 16,
      Color = Color3.fromRGB(255, 170, 60) })
  elseif preset == "Fumaca" then
    emit("Smoke", "ArkherSmoke", { Size = 8, Opacity = 0.6 })
  elseif preset == "Magia" then
    emit("ParticleEmitter", "ArkherMagic", { Rate = 50, Lifetime = NumberRange.new(0.5, 1.5),
      Speed = NumberRange.new(4, 10), Size = NumberSequence.new(1),
      Transparency = NumberSequence.new(0.2), LightEmission = 0.8 })
    emit("PointLight", "ArkherLight", { Brightness = 3, Range = 20,
      Color = Color3.fromRGB(120, 200, 255) })
  elseif preset == "Brilho" then
    emit("Sparkles", "ArkherSparkles", {})
    emit("PointLight", "ArkherLight", { Brightness = 1, Range = 12 })
  else
    error("preset: Tocha/Fumaca/Magia/Brilho.")
  end
  for _, e in ipairs(made) do
    created[player] = (created[player] or 0) + 1
    register(e)
  end
  queueObject(parent)
  return { spawned = #made, preset = preset, msg = ("VFX %s (%d objetos)."):format(preset, #made) }
end
-- ================= R15a D-O15 (otimizacao real) =================
do
local DO15 = { OPS = { notouch = true, noshadow = true, anchor = true }, KINDS = {}, rel = {} }
function DO15.ws() return game:GetService("Workspace") end
function DO15.user(o)
  if not o or not o.Parent then return false end
  local cn = o.ClassName
  if cn == "Terrain" or cn == "Camera" then return false end
  if hidden(o) then return false end
  if characterPart(o) then return false end
  return true
end
function DO15.stats()
  local out = { fps = math.floor(RRWS.fps.ema * 10) / 10 }
  pcall(function()
    local St = game:GetService("Stats")
    out.instances = St.InstanceCount
    out.primitives = St.PrimitivesCount
    out.moving = St.MovingPrimitivesCount
    out.contacts = St.ContactsCount
    out.recvKbps = St.DataReceiveKbps
    out.sendKbps = St.DataSendKbps
    out.physMs = St.PhysicsStepTime
    out.renderMs = St.RenderCPUFrameTime
    out.drawcalls = St.SceneDrawcallCount
    out.tris = St.SceneTriangleCount
    out.memMb = St:GetTotalMemoryUsageMb()
  end)
  pcall(function() out.luaKb = math.floor(collectgarbage("count")) end)
  pcall(function()
    local w = DO15.ws()
    out.streaming = w.StreamingEnabled
    out.targetRadius = w.StreamingTargetRadius
    out.gravity = w.Gravity
    out.killY = w.FallenPartsDestroyHeight
  end)
  local parts, lights, emit, sc, n = 0, 0, 0, 0, 0
  for _, d in ipairs(DO15.ws():GetDescendants()) do
    n = n + 1
    if n > 20000 then out.truncated = true break end
    if DO15.user(d) then
      local cn = d.ClassName
      if d:IsA("BasePart") and cn ~= "Terrain" then parts = parts + 1 end
      if cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then lights = lights + 1 end
      if cn == "ParticleEmitter" or cn == "Fire" or cn == "Smoke" or cn == "Sparkles" or cn == "Beam" or cn == "Trail" then emit = emit + 1 end
      if cn == "Script" or cn == "LocalScript" or cn == "ModuleScript" then sc = sc + 1 end
    end
  end
  out.parts, out.lights, out.emitters, out.scripts = parts, lights, emit, sc
  out.scanned = n
  return out
end
function handlers.Do15Stats(player, payload) return DO15.stats() end
function DO15.audit()
  local a = { unanchored = 0, cantouch = 0, castshadow = 0, transparent = 0,
    oversized = 0, parts = 0, scripts = 0, sounds = 0, decals = 0, mats = {} }
  local n = 0
  for _, d in ipairs(DO15.ws():GetDescendants()) do
    n = n + 1
    if n > 20000 then a.truncated = true break end
    if DO15.user(d) then
      local cn = d.ClassName
      if d:IsA("BasePart") and cn ~= "Terrain" then
        a.parts = a.parts + 1
        if not d.Anchored then a.unanchored = a.unanchored + 1 end
        if d.CanTouch ~= false then a.cantouch = a.cantouch + 1 end
        if d.CastShadow ~= false then a.castshadow = a.castshadow + 1 end
        if (d.Transparency or 0) > 0 then a.transparent = a.transparent + 1 end
        local sz = d.Size
        if sz and type(sz.X) == "number" and (sz.X > 2048 or sz.Y > 2048 or sz.Z > 2048) then a.oversized = a.oversized + 1 end
        local m = d.Material
        local key = (type(m) == "table" and m.Name) or tostring(m)
        a.mats[key] = (a.mats[key] or 0) + 1
      elseif cn == "Script" or cn == "LocalScript" or cn == "ModuleScript" then
        a.scripts = a.scripts + 1
      elseif cn == "Sound" then a.sounds = a.sounds + 1
      elseif cn == "Decal" or cn == "Texture" then a.decals = a.decals + 1
      end
    end
  end
  a.scanned = n
  local list = {}
  for k, v in pairs(a.mats) do list[#list + 1] = { mat = k, n = v } end
  table.sort(list, function(x, y) return x.n > y.n end)
  while #list > 8 do table.remove(list) end
  a.topMats = list
  a.mats = nil
  return a
end
function handlers.Do15Audit(player, payload) return DO15.audit() end
function handlers.Do15Optimize(player, payload)
  local ops = payload.ops or {}
  assert(type(ops) == "table" and #ops >= 1, "ops: lista nao-vazia.")
  local want = {}
  for _, op in ipairs(ops) do
    op = tostring(op)
    assert(DO15.OPS[op], "op invalida: " .. op)
    want[op] = true
  end
  if want.anchor then assert(payload.confirm == true, "anchor muda fisica: confirme.") end
  local snap = {}
  local changed = { notouch = 0, noshadow = 0, anchor = 0 }
  local skipped, n, trunc = 0, 0, false
  for _, d in ipairs(DO15.ws():GetDescendants()) do
    n = n + 1
    if n > 20000 then trunc = true break end
    if #snap >= 2000 then trunc = true break end
    if d:IsA("BasePart") and d.ClassName ~= "Terrain" and DO15.user(d) then
      if d:FindFirstChildOfClass("ClickDetector") or d:FindFirstChildOfClass("ProximityPrompt") then
        skipped = skipped + 1
      else
        local e = { o = d }
        local touched = false
        if want.notouch and d.CanTouch ~= false then e.ct = d.CanTouch e.hasCt = true d.CanTouch = false changed.notouch = changed.notouch + 1 touched = true end
        if want.noshadow and d.CastShadow ~= false then e.cs = d.CastShadow e.hasCs = true d.CastShadow = false changed.noshadow = changed.noshadow + 1 touched = true end
        if want.anchor and not d.Anchored then e.an = d.Anchored e.hasAn = true d.Anchored = true changed.anchor = changed.anchor + 1 touched = true end
        if touched then snap[#snap + 1] = e queueObject(d) end
      end
    end
  end
  pushHist(player, { label = "D-O15 otimiza " .. #snap,
    undo = function()
      for _, e in ipairs(snap) do
        if e.hasCt then pcall(function() e.o.CanTouch = e.ct end) end
        if e.hasCs then pcall(function() e.o.CastShadow = e.cs end) end
        if e.hasAn then pcall(function() e.o.Anchored = e.an end) end
      end
    end,
    redo = function()
      for _, e in ipairs(snap) do
        if e.hasCt then pcall(function() e.o.CanTouch = false end) end
        if e.hasCs then pcall(function() e.o.CastShadow = false end) end
        if e.hasAn then pcall(function() e.o.Anchored = true end) end
      end
    end })
  return { changed = changed, skipped = skipped, truncated = trunc }
end
function handlers.Do15Preload(player, payload)
  local ids = payload.ids or {}
  assert(type(ids) == "table" and #ids >= 1 and #ids <= 50, "ids: 1..50.")
  local temps = {}
  for _, id in ipairs(ids) do
    id = tostring(id)
    assert(id:match("^rbxassetid://%d+$"), "id invalido: " .. id)
    local s = Instance.new("Sound")
    s.Name = "ArkherPreload"
    s.SoundId = id
    temps[#temps + 1] = s
  end
  local loaded, failed = 0, 0
  local t0 = os.clock()
  local ok, err = pcall(function()
    game:GetService("ContentProvider"):PreloadAsync(temps, function(assetId, status)
      local nm = (type(status) == "table" and status.Name) or tostring(status)
      if nm == "Success" then loaded = loaded + 1 else failed = failed + 1 end
    end)
  end)
  for _, s in ipairs(temps) do pcall(function() s:Destroy() end) end
  assert(ok, "preload falhou: " .. tostring(err))
  return { loaded = loaded, failed = failed, ms = math.floor((os.clock() - t0) * 1000) }
end
DO15.KINDS = {
  Light = { PointLight = true, SpotLight = true, SurfaceLight = true },
  Emitter = { ParticleEmitter = true, Fire = true, Smoke = true, Sparkles = true, Beam = true, Trail = true },
  Decal = { Decal = true, Texture = true },
  Sound = { Sound = true },
}

function handlers.Do15Relevance(player, payload)
  local op = tostring(payload.op or "list")
  if op == "list" then
    local out = {}
    for name, g in pairs(DO15.rel) do
      out[#out + 1] = { name = name, radius = g.radius, on = g.on, items = g.count, dist = g.dist }
    end
    return { groups = out }
  end
  if op == "remove" then
    local g = DO15.rel[tostring(payload.name or "")]
    assert(g, "grupo inexistente.")
    for o, st in pairs(g.init) do pcall(function() o.Enabled = st end) end
    DO15.rel[tostring(payload.name or "")] = nil
    queueObject(g.root)
    return { removed = true }
  end
  assert(op == "register", "op: register/list/remove.")
  local name = tostring(payload.name or "")
  assert(name:match("^[%w_%-%. ]+$") and #name <= 32, "nome invalido.")
  assert(not DO15.rel[name], "grupo ja existe.")
  local n = 0
  for _ in pairs(DO15.rel) do n = n + 1 end
  assert(n < 16, "limite 16 grupos.")
  local o = objects[payload.id]
  assert(o and (o.ClassName == "Model" or o.ClassName == "Folder"), "id precisa ser Model/Folder.")
  assert(DO15.user(o) and o:IsDescendantOf(DO15.ws()), "grupo fora do escopo.")
  local radius = math.clamp(tonumber(payload.radius) or 150, 10, 5000)
  local kinds = payload.kinds or { "Light", "Emitter" }
  assert(type(kinds) == "table" and #kinds >= 1, "kinds: lista nao-vazia.")
  local ks = {}
  for _, k in ipairs(kinds) do
    k = tostring(k)
    assert(DO15.KINDS[k], "kind invalido: " .. k)
    ks[k] = true
  end
  local init, count = {}, 0
  for _, d in ipairs(o:GetDescendants()) do
    for k in pairs(ks) do
      if DO15.KINDS[k][d.ClassName] then init[d] = (d.Enabled ~= false) count = count + 1 break end
    end
    if count >= 2000 then break end
  end
  DO15.rel[name] = { root = o, radius = radius, kinds = ks, init = init, count = count, on = true, dist = 0 }
  queueObject(o)
  return { registered = true, items = count }
end
Run.Heartbeat:Connect(function(dt)
  local dead = nil
  for name, g in pairs(DO15.rel) do
    if not g.root or not g.root.Parent then
      dead = dead or {}
      dead[#dead + 1] = name
    else
      local ok, cf = pcall(function() return g.root:GetBoundingBox() end)
      local cam = DO15.ws().CurrentCamera
      if ok and cf and cam and cam.CFrame then
        local dist = (cf.Position - cam.CFrame.Position).Magnitude
        g.dist = math.floor(dist)
        local r = g.radius
        if g.on and dist > r * 1.1 then
          g.on = false
          for o in pairs(g.init) do pcall(function() o.Enabled = false end) end
        elseif not g.on and dist < r * 0.9 then
          g.on = true
          for o, st in pairs(g.init) do pcall(function() o.Enabled = st end) end
        end
      end
    end
  end
  if dead then for _, name in ipairs(dead) do DO15.rel[name] = nil end end
end)
function handlers.Do15Gc(player, payload)
  local b0 = collectgarbage("count")
  collectgarbage("collect")
  local b1 = collectgarbage("count")
  return { beforeKb = math.floor(b0), afterKb = math.floor(b1), freedKb = math.floor(b0 - b1) }
end
function handlers.Do15Report(player, payload)
  local Http = game:GetService("HttpService")
  local rep = { v = 1, stats = DO15.stats(), audit = DO15.audit() }
  local js = Http:JSONEncode(rep)
  assert(#js <= 2000000, "relatorio grande demais.")
  return { json = js, bytes = #js }
end
end
-- ================= R15b World (mundo real) =================
do
local WLD = {}
function WLD.ws() return game:GetService("Workspace") end
function WLD.ss() return game:GetService("ServerStorage") end
function WLD.user(o)
  if not o or not o.Parent then return false end
  local cn = o.ClassName
  if cn == "Terrain" or cn == "Camera" then return false end
  if hidden(o) then return false end
  if characterPart(o) then return false end
  return true
end
function WLD.folder(name)
  local ss = WLD.ss()
  local f = ss:FindFirstChild(name)
  if not f then
    f = Instance.new("Folder")
    f.Name = name
    f.Parent = ss
  end
  return f
end
function WLD.saveWs(name)
  local ws = WLD.ws()
  local kids = {}
  local total = 0
  for _, c in ipairs(ws:GetChildren()) do
    if WLD.user(c) then
      total = total + 1 + #c:GetDescendants()
      kids[#kids + 1] = c
    end
  end
  assert(total <= 3000, "mundo grande demais p/ save (3000).")
  local root = WLD.folder("ArkherWorlds")
  local f = Instance.new("Folder")
  f.Name = name
  f:SetAttribute("items", total)
  f:SetAttribute("created", os.time())
  f.Parent = root
  for _, c in ipairs(kids) do
    local ok, cl = pcall(function() return c:Clone() end)
    if ok and cl then cl.Parent = f end
  end
  return total
end
function handlers.WorldInfo(player, payload)
  local ws, out = WLD.ws(), {}
  local parts, models, scripts, sounds, decals, sp = 0, 0, 0, 0, 0, 0
  local n, trunc = 0, false
  local mnx, mny, mnz, mxx, mxy, mxz, hasB = 0, 0, 0, 0, 0, 0, false
  for _, d in ipairs(ws:GetDescendants()) do
    n = n + 1
    if n > 20000 then trunc = true break end
    if WLD.user(d) then
      local cn = d.ClassName
      if d:IsA("BasePart") and cn ~= "Terrain" then
        parts = parts + 1
        if cn == "SpawnLocation" then sp = sp + 1 end
        if n <= 5000 then
          local p = d.Position
          if p and type(p.X) == "number" then
            if not hasB then
              mnx, mny, mnz, mxx, mxy, mxz = p.X, p.Y, p.Z, p.X, p.Y, p.Z
              hasB = true
            else
              if p.X < mnx then mnx = p.X end
              if p.Y < mny then mny = p.Y end
              if p.Z < mnz then mnz = p.Z end
              if p.X > mxx then mxx = p.X end
              if p.Y > mxy then mxy = p.Y end
              if p.Z > mxz then mxz = p.Z end
            end
          end
        end
      elseif cn == "Model" then models = models + 1
      elseif cn == "Script" or cn == "LocalScript" or cn == "ModuleScript" then scripts = scripts + 1
      elseif cn == "Sound" then sounds = sounds + 1
      elseif cn == "Decal" or cn == "Texture" then decals = decals + 1
      end
    end
  end
  out.parts, out.models, out.scripts = parts, models, scripts
  out.sounds, out.decals, out.spawns = sounds, decals, sp
  out.scanned, out.truncated = n, trunc
  if hasB then out.bounds = { mnx, mny, mnz, mxx, mxy, mxz } end
  pcall(function()
    out.gravity = ws.Gravity
    out.killY = ws.FallenPartsDestroyHeight
    out.streaming = ws.StreamingEnabled
    out.targetRadius = ws.StreamingTargetRadius
  end)
  local wroot = WLD.ss():FindFirstChild("ArkherWorlds")
  out.saves = wroot and #wroot:GetChildren() or 0
  local trash = WLD.ss():FindFirstChild("ArkherTrash")
  out.trash = trash and #trash:GetChildren() or 0
  return out
end
function handlers.WorldGravity(player, payload)
  local ws = WLD.ws()
  local g = math.clamp(tonumber(payload.g) or 196.2, 0, 500)
  local old = ws.Gravity
  ws.Gravity = g
  queueObject(ws)
  pushHist(player, { label = "World gravidade " .. g,
    undo = function() pcall(function() ws.Gravity = old end) end,
    redo = function() pcall(function() ws.Gravity = g end) end })
  return { g = ws.Gravity }
end
function handlers.WorldSpawn(player, payload)
  local ws = WLD.ws()
  local op = tostring(payload.op or "list")
  if op == "list" then
    local out = {}
    for _, d in ipairs(ws:GetDescendants()) do
      if d.ClassName == "SpawnLocation" and WLD.user(d) then
        register(d)
        local p = d.Position or { X = 0, Y = 0, Z = 0 }
        out[#out + 1] = { id = idOf[d], name = d.Name,
          enabled = d.Enabled ~= false, neutral = d.Neutral ~= false,
          pos = { p.X, p.Y, p.Z } }
      end
    end
    return { spawns = out }
  end
  if op == "add" then
    local px, py, pz = 0, 30, 0
    pcall(function()
      local ch = player.Character
      local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
      local p = hrp and hrp.Position
      if p and type(p.X) == "number" then px, py, pz = p.X, p.Y + 5, p.Z end
    end)
    if payload.pos then
      px = math.clamp(tonumber(payload.pos[1]) or px, -10000, 10000)
      py = math.clamp(tonumber(payload.pos[2]) or py, -10000, 10000)
      pz = math.clamp(tonumber(payload.pos[3]) or pz, -10000, 10000)
    end
    local s = Instance.new("SpawnLocation")
    s.Name = tostring(payload.name or "SpawnLocation"):sub(1, 40)
    s.Size = Vector3.new(6, 1, 6)
    s.CFrame = CFrame.new(px, py, pz)
    s.Anchored = true
    s.Neutral = true
    s.Enabled = true
    s.Parent = ws
    register(s)
    queueObject(s)
    return { node = record(s) }
  end
  local o = objects[payload.id]
  assert(o and o.ClassName == "SpawnLocation", "id precisa ser SpawnLocation.")
  assert(WLD.user(o), "spawn fora do escopo.")
  if op == "toggle" then
    o.Enabled = not (o.Enabled ~= false)
    queueObject(o)
    return { enabled = o.Enabled }
  end
  assert(op == "remove", "op: list/add/toggle/remove.")
  local snap = { parent = o.Parent, cf = o.CFrame, sz = o.Size,
    en = o.Enabled, ne = o.Neutral, nm = o.Name }
  local back = nil
  o:Destroy()
  pushHist(player, { label = "World remove spawn",
    undo = function()
      local s = Instance.new("SpawnLocation")
      s.Name = snap.nm
      s.CFrame = snap.cf
      s.Size = snap.sz
      s.Enabled = snap.en
      s.Neutral = snap.ne
      s.Anchored = true
      s.Parent = (snap.parent and snap.parent.Parent and snap.parent) or WLD.ws()
      register(s)
      queueObject(s)
      back = s
    end,
    redo = function() if back then pcall(function() back:Destroy() end) end end })
  return { removed = true }
end
function handlers.WorldSave(player, payload)
  local op = tostring(payload.op or "list")
  local root = WLD.folder("ArkherWorlds")
  if op == "list" then
    local out = {}
    for _, f in ipairs(root:GetChildren()) do
      out[#out + 1] = { name = f.Name, items = f:GetAttribute("items") or #f:GetDescendants() }
    end
    return { saves = out }
  end
  if op == "delete" then
    local f = root:FindFirstChild(tostring(payload.name or ""))
    assert(f, "save inexistente.")
    f:Destroy()
    return { deleted = true }
  end
  if op == "load" then
    local f = root:FindFirstChild(tostring(payload.name or ""))
    assert(f, "save inexistente.")
    local ws = WLD.ws()
    local n = 0
    for _, c in ipairs(f:GetChildren()) do
      local ok, cl = pcall(function() return c:Clone() end)
      if ok and cl then
        local base, k = cl.Name, 1
        while ws:FindFirstChild(cl.Name) and k < 100 do
          k = k + 1
          cl.Name = base .. " (" .. k .. ")"
        end
        cl.Parent = ws
        n = n + 1
      end
    end
    return { loaded = n }
  end
  assert(op == "save", "op: save/load/list/delete.")
  local name = tostring(payload.name or "")
  assert(name:match("^[%w_%-%. ]+$") and #name <= 32, "nome invalido.")
  assert(not root:FindFirstChild(name), "save ja existe (delete primeiro).")
  assert(#root:GetChildren() < 10, "limite 10 saves.")
  local total = WLD.saveWs(name)
  queueObject(root)
  return { saved = true, items = total }
end
function handlers.WorldClean(player, payload)
  local op = tostring(payload.op or "restore")
  local trash = WLD.folder("ArkherTrash")
  if op == "restore" then
    local n = 0
    for _, c in ipairs(trash:GetChildren()) do
      c.Parent = WLD.ws()
      n = n + 1
    end
    return { restored = n }
  end
  local ws = WLD.ws()
  local moved = 0
  if op == "fallen" then
    local y = math.clamp(tonumber(payload.y) or -400, -50000, 50000)
    for _, d in ipairs(ws:GetDescendants()) do
      if d:IsA("BasePart") and d.ClassName ~= "Terrain" and WLD.user(d) then
        local p = d.Position
        if p and type(p.X) == "number" and p.Y < y and d.Parent then
          d.Parent = trash
          moved = moved + 1
        end
      end
    end
    return { moved = moved }
  end
  assert(op == "loose", "op: fallen/loose/restore.")
  for _, d in ipairs(ws:GetDescendants()) do
    if d:IsA("BasePart") and d.ClassName ~= "Terrain" and WLD.user(d)
        and not d.Anchored and d.Parent then
      d.Parent = trash
      moved = moved + 1
    end
  end
  return { moved = moved }
end
function handlers.WorldClear(player, payload)
  assert(payload.confirm == true, "WorldClear apaga o mundo: confirme.")
  local root = WLD.folder("ArkherWorlds")
  local old = root:FindFirstChild("autosafe")
  if old then old:Destroy() end
  local items = WLD.saveWs("autosafe")
  local ws = WLD.ws()
  local n = 0
  for _, c in ipairs(ws:GetChildren()) do
    if WLD.user(c) then
      c:Destroy()
      n = n + 1
    end
  end
  queueObject(ws)
  return { deleted = n, backup = "autosafe", items = items }
end
end
function handlers.RrwStats(player, payload)
  local n, trunc = 0, false
  for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") then n = n + 1 end
    if n >= 20000 then trunc = true break end
  end
  local L = rrwLighting()
  local fx = 0
  for _, c in ipairs(L:GetChildren()) do if RRWS.FX[c.ClassName] then fx = fx + 1 end end
  local lod = 0
  for _ in pairs(RRWS.lod) do lod = lod + 1 end
  local style = nil
  pcall(function() style = uiEnumName2(L.LightingStyle) end)
  return { fps = math.floor(RRWS.fps.ema * 10) / 10, parts = n, truncated = trunc,
    effects = fx, lodGroups = lod, clockTime = L.ClockTime, style = style }
end

function handlers.PivotReset(player, payload)
    local o = selOrId(player, payload.id)
    assert(o and (o:IsA("Model") or o:IsA("BasePart")) and editable(o) and not rootSet[o], "Selecione um Model ou peça para resetar o pivô.")
    local old = o.PivotOffset
    o.PivotOffset = CFrame.new()
    queueObject(o)
    pushHist(player, {
        label = "Pivot reset " .. o.Name,
        undo = function() o.PivotOffset = old queueObject(o) end,
        redo = function() o.PivotOffset = CFrame.new() end,
    })
    return { node = record(o) }
end

function handlers.RunPlay(player, payload)
	runRestore()
	RUN.running = true
	pcall(function() player:LoadCharacter() end)
	return { msg = "▶ Executando de verdade: edições bloqueadas, física ao vivo, personagem no spawn." }
end
function handlers.RunPause(player, payload)
	if not RUN.running then return { error = "Nada em execução (aperte Play antes)." } end
	if RUN.frozen then
		runRestore()
		return { msg = "▶ Execução retomada." }
	end
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and not d.Anchored then
			RUN.parts[d] = false
			pcall(function()
				RUN.vels[d] = { d.AssemblyLinearVelocity, d.AssemblyAngularVelocity }
				d.Anchored = true
			end)
		elseif d:IsA("Sound") and d.Playing then
			RUN.sounds[#RUN.sounds + 1] = d
			pcall(function() d:Pause() end)
		end
	end
	RUN.frozen = true
	return { msg = "⏸ Pausado de verdade: física congelada, sons pausados." }
end
function handlers.RunStop(player, payload)
	runRestore()
	RUN.running = false
	pcall(function() player:LoadCharacter() end)
	return { msg = "■ Stop: modo de edição de volta, edições liberadas." }
end

function handlers.SavePlace(player, payload)
	local okS, ret = pcall(function()
		return game:GetService("AssetService"):SavePlaceAsync()
	end)
	if not okS then
		return { error = "SavePlaceAsync recusou (jogo precisa estar PUBLICADO e ser seu): " .. tostring(ret) }
	end
	return { msg = "PLACE SALVA na sua conta de verdade (AssetService:SavePlaceAsync executado)." }
end

print("[ArkherProps] CLASSDB pronta: " .. tostring(#CATALOG_ITEMS) .. " classes no catálogo + PropsAll/SetAny/CreateAny ativos")
request.OnServerInvoke=function(player,action,payload)if not authorized(player)then return{ok=false,error="A conta @"..player.Name.." não está autorizada. Adicione esse nome principal em AUTHORIZED_USERNAMES no servidor; não use o nome de exibição."}end if type(action)~="string"or not handlers[action]or not consume(player,action=="Snapshot"and 4 or 1)then return{ok=false,error="Requisição inválida ou limite de frequência."}end if payload~=nil and type(payload)~="table"then return{ok=false,error="Formato inválido."}end if RUN.running and MUTATING[action]then return{ok=false,error="Em execução — pare (Run > Stop) para editar."}end local ok,result=pcall(handlers[action],player,payload or{})if not ok then local t=transactions[player]if action=="Begin"or(action=="End"and t and payload and t.token==payload.token)then release(player,true)end return{ok=false,error=tostring(result)}end result=result or{};result.ok=true;return result end preview.OnServerEvent:Connect(function(player,payload)if not authorized(player)or type(payload)~="table"or not consume(player,1)then return end local t=transactions[player]if not t or payload.token~=t.token then return end if t.lastPreview and os.clock()-t.lastPreview<0.045 then return end t.lastPreview=os.clock()local ok=pcall(applyTransform,t,payload)if not ok then release(player,true)end end)Players.PlayerRemoving:Connect(function(player)release(player,true);subscribed[player]=nil;selected[player]=nil;buckets[player]=nil;created[player]=nil end)local timer,propertyTimer=0,0 Run.Heartbeat:Connect(function(dt)timer=timer+dt;propertyTimer=propertyTimer+dt for player,t in pairs(transactions)do if os.clock()-t.time>CONFIG.TRANSFORM_TIMEOUT then release(player,true)end end if timer>=0.12 then timer=0 if next(dirty)or next(removed)then revision=revision+1 local packet={kind="Delta",revision=revision,nodes={},removed={}}for id in pairs(dirty)do local o=objects[id];if inspectable(o)then packet.nodes[#packet.nodes+1]=record(o)end end for id in pairs(removed)do packet.removed[#packet.removed+1]=id end dirty={};removed={}pipeStats.deltaFlush=pipeStats.deltaFlush+1;pipeStats.deltaNodes=pipeStats.deltaNodes+#packet.nodes;for player in pairs(subscribed)do if authorized(player)then updates:FireClient(player,packet)end end end end if propertyTimer>=0.3 then propertyTimer=0 for player,o in pairs(selected)do if subscribed[player]and authorized(player)and not transactions[player]then if inspectable(o)then pipeStats.propsPush=pipeStats.propsPush+1;updates:FireClient(player,{kind="Properties",properties=properties(o)})else selected[player]=nil;pipeStats.selRemoved=pipeStats.selRemoved+1;updates:FireClient(player,{kind="SelectionRemoved"})end end end end end)-- ROUND 11 boot: baseplate sempre presente
pcall(function()
	local b0 = workspace:FindFirstChild("Baseplate")
	if not (b0 and b0:IsA("BasePart")) then
		ensureBaseplate()
		print("[Arkher] Baseplate criada automaticamente no boot (2048x2048).")
	end
end)
print("ArkherEditorServer pronto. Edição restrita aos nomes principais em AUTHORIZED_USERNAMES; scripts novos ficam vazios e desativados.")
