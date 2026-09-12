local CONFIG={AUTHORIZED_USERNAMES={"WhiteXz73_Developer"},MAX_NODES=12000,MAX_CREATED_PER_SESSION=2000,MAX_POSITION=1000000,MAX_SIZE=2048,TRANSFORM_TIMEOUT=20,}local Players=game:GetService("Players")local RS=game:GetService("ReplicatedStorage")local Run=game:GetService("RunService")local Http=game:GetService("HttpService")assert(not RS:FindFirstChild("ArkherStudioBridge"),"Já existe um ArkherEditorServer. Use apenas um Script de servidor.")local bridge=Instance.new("Folder");bridge.Name="ArkherStudioBridge";bridge:SetAttribute("Protocol",3);bridge.Parent=RS local request=Instance.new("RemoteFunction");request.Name="Request";request.Parent=bridge local updates=Instance.new("RemoteEvent");updates.Name="Updates";updates.Parent=bridge local preview=Instance.new("RemoteEvent");preview.Name="TransformPreview";preview.Parent=bridge local catalog={}local byClass={}local function add(class,category,group,description,aliases)local entry={class=class,category=category,group=group,description=description,aliases=aliases or""}catalog[#catalog+1]=entry;byClass[class]=entry end add("Folder","Containers","container","Pasta para organizar objetos.","pasta")add("Model","Containers","container","Agrupa peças e outros objetos em um modelo.","modelo")add("Part","3D","geometry","Peça básica do cenário. Pode receber scripts, efeitos e outros filhos.","bloco peça parte")add("WedgePart","3D","geometry","Peça em formato de rampa.","rampa")add("CornerWedgePart","3D","geometry","Rampa de canto.","canto")add("TrussPart","3D","geometry","Estrutura escalável.","escada")add("SpawnLocation","3D","geometry","Ponto de nascimento dos jogadores.","spawn nascimento")add("Script","Scripts","script","Script de servidor vazio e desativado. Edite o código no Roblox Studio.","código servidor")add("LocalScript","Scripts","script","LocalScript vazio e desativado. Só executa nos contextos de cliente aceitos pelo Roblox.","local script código cliente")add("ModuleScript","Scripts","script","ModuleScript vazio. Criá-lo não executa código; Source é editado no Studio.","module script módulo")add("ScreenGui","UI","screen","Tela de interface; use StarterGui como pai.","ScreenGUI Screen GUI UI Screen tela")for _,class in ipairs({"Frame","TextLabel","TextButton","TextBox","ImageLabel","ImageButton","ScrollingFrame"})do add(class,"UI","gui","Elemento de interface. Adicione dentro de ScreenGui ou outro GuiObject.","interface botão texto imagem")end for _,class in ipairs({"UICorner","UIStroke","UIGradient","UIPadding","UIListLayout","UIGridLayout","UIAspectRatioConstraint","UISizeConstraint"})do add(class,"UI","component","Componente visual ou de layout de uma interface.","interface componente layout")end add("Tool","Gameplay","tool","Ferramenta vazia, sem Handle obrigatório.","ferramenta")add("Attachment","3D","attachment","Ponto de referência dentro de uma peça.","anexo")add("Decal","Appearance","surface","Imagem aplicada a uma face de uma peça.","adesivo decalque")add("Texture","Appearance","surface","Textura aplicada a uma peça.","textura")for _,class in ipairs({"PointLight","SpotLight","SurfaceLight"})do add(class,"Effects","effect","Fonte de luz em uma peça ou Attachment.","luz iluminação")end for _,class in ipairs({"ParticleEmitter","Fire","Smoke","Sparkles"})do add(class,"Effects","effect","Efeito visual em uma peça ou Attachment.","partícula fogo fumaça efeito")end add("Sound","Audio","sound","Objeto de áudio; configure SoundId nas propriedades.","som áudio")add("ClickDetector","Gameplay","detector","Detector de cliques em uma peça.","clique")add("ProximityPrompt","Gameplay","prompt","Interação de proximidade em uma peça, Attachment ou Model.","interagir proximidade")add("MaterialVariant","Appearance","material","Variação de material dentro de MaterialService.","material")for _,class in ipairs({"BoolValue","IntValue","NumberValue","StringValue","Vector3Value","Color3Value","ObjectValue"})do add(class,"Values","value","Armazena um valor como filho de outro objeto.","valor dados")end local roots,rootSet,rootIds={},{},{}for _,name in ipairs({"Workspace","Players","Lighting","MaterialService","ReplicatedFirst","ReplicatedStorage","ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer","TextChatService"})do local ok,o=pcall(function()return game:GetService(name)end)if ok then roots[#roots+1]=o;rootSet[o]=true end end local idOf,objects,watchers={},{},{}local subscribed,selected,created,buckets,transactions,locks={},{},{},{},{},{}local dirty,removed={},{}
local hist = {}
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
local nextId,revision,nodeCount=0,0,0 local register,unregister,queueObject local function normalizeUsername(value)if type(value)~="string"then return nil end local name=value:match("^%s*(.-)%s*$"):gsub("^@",""):lower()if name==""or name=="seu_usuario_aqui"then return nil end return name end local allowedUsernames={}for _,name in ipairs(CONFIG.AUTHORIZED_USERNAMES)do local normalized=normalizeUsername(name)if normalized then allowedUsernames[normalized]=true end end if not next(allowedUsernames)then warn("Arkher: substitua SEU_USUARIO_AQUI pelo seu nome principal em AUTHORIZED_USERNAMES. Acesso fechado até configurar.")end local function authorized(player)if not player or player.Parent~=Players then return false end return allowedUsernames[normalizeUsername(player.Name)]==true end local function consume(player,cost)local now=os.clock();local b=buckets[player]or{tokens=80,time=now};buckets[player]=b b.tokens=math.min(80,b.tokens+(now-b.time)*35);b.time=now if b.tokens<cost then return false end b.tokens=b.tokens-cost;return true end local function hidden(o)if o==script or o:IsDescendantOf(script)or o==bridge or o:IsDescendantOf(bridge)then return true end local p=o while p and p~=game do if p.Name=="ArkherStudioUI"and p:IsA("ScreenGui")then return true end if p:GetAttribute("ArkherInternal")then return true end p=p.Parent end return false end local function rootFor(o)local p=o while p and p~=game do if rootSet[p]then return p end;p=p.Parent end end local function inspectable(o)return o and o.Parent and rootFor(o)~=nil and not hidden(o)end local function characterPart(o)for _,p in ipairs(Players:GetPlayers())do if p.Character and(o==p.Character or o:IsDescendantOf(p.Character))then return true end end return false end local function editable(o)local r=rootFor(o)return inspectable(o)and r~=Players and r~=game:GetService("TextChatService")and not characterPart(o)end local function containsProtected(o)if script:IsDescendantOf(o)or bridge:IsDescendantOf(o)then return true end for _,p in ipairs(Players:GetPlayers())do if p.Character and p.Character:IsDescendantOf(o)then return true end end for _,child in ipairs(o:GetDescendants())do if child:IsA("ScreenGui")and child.Name=="ArkherStudioUI"then return true end end return false end local function conflictingLock(o,exceptPlayer)for locked,owner in pairs(locks)do if owner~=exceptPlayer and(locked==o or locked:IsDescendantOf(o)or o:IsDescendantOf(locked))then return true end end return false end local function category(o)if byClass[o.ClassName]then return byClass[o.ClassName].category end if o:IsA("BasePart")then return"3D"end if o:IsA("LuaSourceContainer")then return"Scripts"end if o:IsA("GuiObject")or o:IsA("LayerCollector")then return"UI"end if rootSet[o]then return"Services"end return"Objects"end local function remoteObject(o)local r=rootFor(o)if r==game:GetService("ServerStorage")or r==game:GetService("ServerScriptService")then return nil end return o end local function canCreate(parent,entry)if not editable(parent)then return false,"Pai protegido ou somente leitura."end local group=entry.group local isFolder=parent:IsA("Folder")local isModel=parent.ClassName=="Model"local isPart=parent:IsA("BasePart")and not parent:IsA("Terrain")local dataRoot=parent==workspace or parent==RS or parent==game:GetService("ServerStorage")or parent==game:GetService("ReplicatedFirst")local container=dataRoot or isFolder or isModel if group=="screen"then return parent==game:GetService("StarterGui")or(isFolder and parent:IsDescendantOf(game:GetService("StarterGui"))),"ScreenGui usa StarterGui como pai."elseif group=="gui"then return parent:IsA("GuiObject")or parent:IsA("LayerCollector"),"Escolha um ScreenGui ou GuiObject."elseif group=="component"then return parent:IsA("GuiObject"),"Escolha um GuiObject."elseif group=="geometry"then return container or parent:IsA("Tool"),"Escolha Workspace, Model, Folder ou um armazenamento."elseif group=="attachment"or group=="surface"or group=="detector"then return isPart,"Escolha uma peça como pai."elseif group=="effect"then return isPart or parent:IsA("Attachment"),"Escolha uma peça ou Attachment."elseif group=="prompt"then return isPart or isModel or parent:IsA("Attachment"),"Escolha Part, Model ou Attachment."elseif group=="material"then return parent==game:GetService("MaterialService"),"Escolha MaterialService."elseif group=="tool"then return container or parent==game:GetService("StarterPack"),"Escolha StarterPack, Workspace ou um contêiner."elseif group=="script"then return parent:IsA("Tool")or parent:IsA("LuaSourceContainer")or container or isPart or parent:IsA("GuiObject")or parent:IsA("LayerCollector")or parent==game:GetService("ServerScriptService")or parent==game:GetService("StarterGui")or parent:IsA("StarterPlayerScripts")or parent:IsA("StarterCharacterScripts"),"Escolha uma peça, contêiner, interface ou pasta de scripts."elseif group=="container"or group=="value"or group=="sound"then return container or isPart or parent:IsA("GuiObject")or parent:IsA("LayerCollector")or parent==game:GetService("ServerScriptService")or parent==game:GetService("StarterGui")or parent==game:GetService("StarterPack")or parent:IsA("LuaSourceContainer"),"Este tipo não é compatível com o pai selecionado."end return false,"Tipo não permitido."end local function canInsert(o)for _,entry in ipairs(catalog)do if canCreate(o,entry)then return true end end return false end local function record(o)local has=false for _,c in ipairs(o:GetChildren())do if inspectable(c)then has=true;break end end return{id=idOf[o],parentId=idOf[o.Parent],name=o.Name,class=o.ClassName,category=category(o),hasChildren=has,canInsert=canInsert(o),canDelete=editable(o)and not rootSet[o]and not containsProtected(o),readOnly=not editable(o),object=remoteObject(o)}end queueObject=function(o)if not inspectable(o)then return end if not idOf[o]then register(o)end if idOf[o]then dirty[idOf[o] ]=true;removed[idOf[o] ]=nil end end register=function(o)if idOf[o]or not inspectable(o)then return end if nodeCount>=CONFIG.MAX_NODES and not rootSet[o]then return end if not rootSet[o]and inspectable(o.Parent)and not idOf[o.Parent]then register(o.Parent);if not idOf[o.Parent]then return end end nextId=nextId+1;nodeCount=nodeCount+1;local id="n"..nextId;idOf[o]=id;objects[id]=o watchers[o]={o:GetPropertyChangedSignal("Name"):Connect(function()queueObject(o)end),o.AncestryChanged:Connect(function()task.defer(function()if inspectable(o)then queueObject(o);queueObject(o.Parent)else unregister(o)end end)end),}dirty[id]=true end unregister=function(o)local id=idOf[o];if not id then return end for _,c in ipairs(o:GetDescendants())do if idOf[c]then unregister(c)end end idOf[o]=nil;objects[id]=nil;dirty[id]=nil;removed[id]=true;nodeCount=math.max(0,nodeCount-1)for _,c in ipairs(watchers[o]or{})do c:Disconnect()end;watchers[o]=nil end for _,r in ipairs(roots)do register(r);rootIds[#rootIds+1]=idOf[r]end for _,r in ipairs(roots)do r.DescendantAdded:Connect(function(o)if inspectable(o)then register(o);queueObject(o.Parent)end end)r.DescendantRemoving:Connect(function(o)local oldParent=o.Parent task.defer(function()if inspectable(o)then queueObject(o)else unregister(o)end if oldParent and inspectable(oldParent)then queueObject(oldParent)end end)end)for _,o in ipairs(r:GetDescendants())do if nodeCount>=CONFIG.MAX_NODES then break end if inspectable(o)then register(o)end end end 
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
local handlers={}function handlers.Hello(player)subscribed[player]=true return snapshot()end function handlers.Snapshot(player)subscribed[player]=true;return snapshot()end function handlers.Identify(_,payload)assert(typeof(payload.object)=="Instance"and inspectable(payload.object),"Objeto não disponível ao editor.")local o=payload.object;register(o);assert(idOf[o],"Limite de objetos da Hierarchy atingido.");local chain={};local p=o while p and inspectable(p)do register(p);chain[#chain+1]=record(p);p=p.Parent end return{id=idOf[o],nodes=chain}end function handlers.Select(player,payload)if not payload.id then selected[player]=nil;return{}end local o=getObject(payload.id);selected[player]=o return{properties=properties(o),node=record(o)}end function handlers.Catalog(_,payload)local parent=getObject(payload.parentId);local result={}for _,entry in ipairs(catalog)do local allowed,reason=canCreate(parent,entry)result[#result+1]={class=entry.class,category=entry.category,description=entry.description,aliases=entry.aliases,allowed=allowed,reason=allowed and""or reason}end return{items=result,parent=record(parent)}end function handlers.Create(player,payload)assert(type(payload.class)=="string"and#payload.class<60,"Classe inválida.")local o=create(player,getObject(payload.parentId),payload.class,payload.name)selected[player]=o hCreate(player,o) return{node=record(o),properties=properties(o)}end function handlers.Delete(player,payload) return handlers.Delete_(player,payload) end function handlers.Set(player,payload)assert(type(payload.key)=="string"and#payload.key<80,"Propriedade inválida.")local o=getObject(payload.id);assert(not conflictingLock(o),"Termine o arraste antes de editar este objeto/contêiner.")local arkOld=read(o,payload.key)setProperty(o,payload.key,payload.value)local arkNew=read(o,payload.key)if arkOld~=arkNew then hSet(player,o,payload.key,arkOld,arkNew)end return{node=record(o),properties=properties(o)}end function handlers.Begin(player,payload)release(player,true)local o=getObject(payload.id)assert(editable(o)and o:IsDescendantOf(workspace)and not containsProtected(o),"Selecione uma peça/Model no Workspace.")assert(payload.mode=="Move"or payload.mode=="Scale"or payload.mode=="Rotate","Ferramenta inválida.")assert(not conflictingLock(o),"Objeto ou descendente em edição por outro usuário.")local parts=allParts(o);assert(#parts>0,"Objeto sem peças manipuláveis.")for _,p in ipairs(parts)do assert(not p.Locked and not characterPart(p),"Peça bloqueada ou pertencente a um personagem.")end local token=Http:GenerateGUID(false)local t={object=o,token=token,mode=payload.mode,time=os.clock(),anchors={},cf=getPivot(o),size=o:IsA("BasePart")and o.Size or nil,scale=o.ClassName=="Model"and o:GetScale()or nil}transactions[player]=t;locks[o]=player for _,p in ipairs(parts)do t.anchors[p]=p.Anchored;p.Anchored=true end return{token=token}end function handlers.End(player,payload)local t=transactions[player];assert(t and t.token==payload.token,"Arraste expirado.")if payload.cancel then release(player,true);return{}end applyTransform(t,payload);local o=t.object;hTransform(player,o,t.cf,t.size,t.scale,getPivot(o),o:IsA("BasePart")and o.Size or nil,o.ClassName=="Model"and o:GetScale()or nil);release(player,false)return{properties=properties(o),node=record(o)}end function handlers.Close(player)subscribed[player]=nil;selected[player]=nil;release(player,true);return{}end 
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
	local okMod, mod = pcall(function()
		local vault = _SS:FindFirstChild("ArkherCloudVault")
		if not vault then vault = Instance.new("Folder") vault.Name = "ArkherCloudVault" vault.Parent = _SS end
		vault:SetAttribute("ArkherInternal", true)
		local ms = vault:FindFirstChild("ArkherServices") or Instance.new("ModuleScript")
		ms.Name = "ArkherServices"
		ms.Source = [[
-- ARKHER Services (ModuleScript) — camada CUSTOM de persistência + dados.
-- Roda no server (ServerStorage/ArkherCloudVault/ArkherServices). Não usa require externo;
-- só services globais. Todo dado aninhado vai em atributo STRING (JSON) p/ persistir no place.
local Http = game:GetService("HttpService")
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
	return projRecord(p)
end
function M.cloudGet(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then return nil end
	local snap = p:FindFirstChild("Snapshot")
	return { data = snap and snap.Value or "", record = projRecord(p) }
end
function M.cloudDelete(id)
	local p = getVault():FindFirstChild("Cloud"):FindFirstChild("proj_" .. id)
	if not p then return false end
	p:Destroy()
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

]]
		ms.Parent = vault
		return require(ms)
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
	assert(tpl, "Template nao encontrado.")
	local parent = workspace
	if payload.parentId and objects[payload.parentId] then parent = objects[payload.parentId] end
	assert(editable(parent), "Pai invalido para este template.")
	return buildToolboxTemplate(player, parent, tpl)
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

function handlers.PropsAll(player, payload)
	local o = getObject(payload.id)
	assert(o, "Objeto invalido.")
	local write = editable(o)
	local fields = {}
	for _, g in ipairs(specFor(o)) do
		local group = g[1]
		for i = 2, #g do
			local spec = g[i]
			local key, kind = spec[1], spec[2]
			local enumType = kind:match("^enum:(%w+)$")
			local k = enumType and "enum" or kind
			local val = readAny(o, key, k)
			if val then
				fields[#fields + 1] = {
					group = group, key = key, kind = k,
					enumType = enumType, enum = enumType and enumListFor(enumType) or nil,
					v = val, editable = write,
					min = spec[3], max = spec[4],
				}
			end
		end
	end
	table.sort(fields, function(a, b) return (a.group == b.group) and (a.key < b.key) or (a.group < b.group) end)
	return { fields = fields, className = o.ClassName, name = o.Name, writable = write }
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
	register(model) created[model] = true
	selected[player] = model
	hCreate(player, model)
	-- marca no ouvinte para o cliente reposicionar
	return { id = idOf[model], nodes = NM, msg = ("Asset %d inserido (%d filhos) — Creator Store REAL"):format(id, NM) }
end

function handlers.PlaceCreate(player, payload)
	local name = tostring(payload.name or ""):sub(1, 80)
	assert(#name > 2, "Nome muito curto para a place.")
	local template = tonumber(payload.template) or 9544032260 -- baseplate do Roblox
	local desc = tostring(payload.description or "Criado com Arkher Studio") or ""
	local ok, ret = pcall(function()
		return game:GetService("AssetService"):CreatePlaceAsync(name, template, desc)
	end)
	if not ok then
		local msg = tostring(ret)
		return { error = "CreatePlaceAsync recusou (" .. msg .. "). Só funciona em jogo publicado online com permissão de criação de place ativa." }
	end
	return { placeId = ret, msg = "PLACE CRIADA no seu perfil: id " .. tostring(ret) .. "  — abra em roblox.com/games/" .. tostring(ret) }
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
request.OnServerInvoke=function(player,action,payload)if not authorized(player)then return{ok=false,error="A conta @"..player.Name.." não está autorizada. Adicione esse nome principal em AUTHORIZED_USERNAMES no servidor; não use o nome de exibição."}end if type(action)~="string"or not handlers[action]or not consume(player,action=="Snapshot"and 4 or 1)then return{ok=false,error="Requisição inválida ou limite de frequência."}end if payload~=nil and type(payload)~="table"then return{ok=false,error="Formato inválido."}end local ok,result=pcall(handlers[action],player,payload or{})if not ok then local t=transactions[player]if action=="Begin"or(action=="End"and t and payload and t.token==payload.token)then release(player,true)end return{ok=false,error=tostring(result)}end result=result or{};result.ok=true;return result end preview.OnServerEvent:Connect(function(player,payload)if not authorized(player)or type(payload)~="table"or not consume(player,1)then return end local t=transactions[player]if not t or payload.token~=t.token then return end if t.lastPreview and os.clock()-t.lastPreview<0.045 then return end t.lastPreview=os.clock()local ok=pcall(applyTransform,t,payload)if not ok then release(player,true)end end)Players.PlayerRemoving:Connect(function(player)release(player,true);subscribed[player]=nil;selected[player]=nil;buckets[player]=nil;created[player]=nil end)local timer,propertyTimer=0,0 Run.Heartbeat:Connect(function(dt)timer=timer+dt;propertyTimer=propertyTimer+dt for player,t in pairs(transactions)do if os.clock()-t.time>CONFIG.TRANSFORM_TIMEOUT then release(player,true)end end if timer>=0.12 then timer=0 if next(dirty)or next(removed)then revision=revision+1 local packet={kind="Delta",revision=revision,nodes={},removed={}}for id in pairs(dirty)do local o=objects[id];if inspectable(o)then packet.nodes[#packet.nodes+1]=record(o)end end for id in pairs(removed)do packet.removed[#packet.removed+1]=id end dirty={};removed={}for player in pairs(subscribed)do if authorized(player)then updates:FireClient(player,packet)end end end end if propertyTimer>=0.3 then propertyTimer=0 for player,o in pairs(selected)do if subscribed[player]and authorized(player)and not transactions[player]then if inspectable(o)then updates:FireClient(player,{kind="Properties",properties=properties(o)})else selected[player]=nil;updates:FireClient(player,{kind="SelectionRemoved"})end end end end end)print("ArkherEditorServer pronto. Edição restrita aos nomes principais em AUTHORIZED_USERNAMES; scripts novos ficam vazios e desativados.")
