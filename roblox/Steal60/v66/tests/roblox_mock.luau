-- Deliberately small test double, NOT Roblox Engine. No rendering/physics/network emulation.
local queue={};local deferSignals=false
local function signal()
 local s={listeners={}}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;self.listeners[#self.listeners+1]={fn,c};return c end
 function s:Fire(...)
  local args=table.pack(...)
  for _,item in ipairs(self.listeners)do if item[2].Connected then
   local function fire()if item[2].Connected then item[1](table.unpack(args,1,args.n))end end
   if deferSignals then queue[#queue+1]=fire else fire()end
  end end
 end
 return s
end
local function flush()
 local rounds=0
 while #queue>0 do rounds+=1;assert(rounds<500,'signal feedback loop');local batch=queue;queue={};for _,fn in ipairs(batch)do fn()end end
end
local V={};local vm={}
function V.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,_kind='Vector3'},vm)end
vm.__index=function(v,key)
 if key=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
 if key=='Unit'then return v/v.Magnitude end
 return V[key]
end
vm.__add=function(a,b)return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__unm=function(a)return a*-1 end
vm.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;if type(b)=='number'then return V.new(a.X*b,a.Y*b,a.Z*b)end;return V.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z)end
vm.__div=function(a,b)return a*(1/b)end
function V:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function V:Cross(b)return V.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X)end
function V:Lerp(b,t)return self+(b-self)*t end
V.zero=V.new();V.xAxis=V.new(1,0,0);V.yAxis=V.new(0,1,0);V.zAxis=V.new(0,0,1)
local Vector3=V
local CF={};local cm={}
local function matrix(p,r)return setmetatable({Position=p,r=r or {1,0,0,0,1,0,0,0,1},_kind='CFrame'},cm)end
function CF.new(x,y,z)if type(x)=='table'then return matrix(x)end;return matrix(V.new(x,y,z))end
function CF.Angles(x,y,z)
 local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 return matrix(V.zero,{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
end
function CF:VectorToWorldSpace(v)local r=self.r;return V.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)end
function CF:PointToWorldSpace(v)return self.Position+self:VectorToWorldSpace(v)end
function CF:Inverse()local r=self.r;local inv=matrix(V.zero,{r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]});inv.Position=inv:VectorToWorldSpace(-self.Position);return inv end
function CF:PointToObjectSpace(v)return self:Inverse():PointToWorldSpace(v)end
function CF:ToObjectSpace(v)return self:Inverse()*v end
function CF.fromMatrix(p,x,y,z)z=z or x:Cross(y);return matrix(p,{x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z})end
function CF.lookAt(p,target,up)local z=(p-target).Unit;local x=(up or V.yAxis):Cross(z).Unit;return CF.fromMatrix(p,x,z:Cross(x),z)end
cm.__index=function(c,key)if key=='RightVector'then return c:VectorToWorldSpace(V.xAxis)elseif key=='UpVector'then return c:VectorToWorldSpace(V.yAxis)elseif key=='LookVector'then return c:VectorToWorldSpace(-V.zAxis)end;return CF[key]end
cm.__mul=function(a,b)if b._kind=='Vector3' then return a:PointToWorldSpace(b)end;local r={};for i=0,2 do for j=0,2 do local n=0;for k=0,2 do n+=a.r[i*3+k+1]*b.r[k*3+j+1]end;r[i*3+j+1]=n end end;return matrix(a:PointToWorldSpace(b.Position),r)end
cm.__add=function(a,b)return matrix(a.Position+b,table.clone(a.r))end
local CFrame=CF
local Color3={}
function Color3.new(r,g,b)return {R=r,G=g,B=b,_kind='Color3'}end
function Color3.fromRGB(r,g,b)return Color3.new(r/255,g/255,b/255)end
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={}
function UDim2.new(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local Enum=setmetatable({},{__index=function(t,k)local e=setmetatable({},{__index=function(et,ek)rawset(et,ek,k..'.'..ek);return et[ek]end});rawset(t,k,e);return e end})
local task={spawn=function(fn,...)fn(...)end,wait=function()return .01 end,defer=function(fn)queue[#queue+1]=fn end,delay=function()end}
local methods={};local instmt={};local Instance={}
function Instance.new(class)
 return setmetatable({_kind='Instance',props={ClassName=class,Name=class,Size=V.new(1,1,1),CFrame=CF.new(),Text='',ActionText='',ObjectText='',Anchored=true,Transparency=0},children={},attrs={},changed={},attrSignals={},events={DescendantAdded=signal(),Destroying=signal(),Activated=signal(),PlayerAdded=signal(),PlayerRemoving=signal(),Heartbeat=signal()}},instmt)
end
instmt.__index=function(o,k)
 if methods[k]then return methods[k]end
 if k=='Position'then return o.props.CFrame.Position end
 if o.events[k]then return o.events[k]end
 if o.props[k]~=nil then return o.props[k]end
 for _,c in ipairs(o.children)do if c.Name==k then return c end end
end
instmt.__newindex=function(o,k,v)
 local old=o.props[k]
 if k=='Parent'then
  if old then local i=table.find(old.children,o);if i then table.remove(old.children,i)end end
  o.props[k]=v
  if v then v.children[#v.children+1]=o;local at=v;while at do at.DescendantAdded:Fire(o);for _,c in ipairs(o:GetDescendants())do at.DescendantAdded:Fire(c)end;at=at.Parent end end
 else
  if k=='Position'then o.props.CFrame=CF.new(v)else o.props[k]=v end
  if old~=v and o.changed[k]then o.changed[k]:Fire()end
 end
end
function methods:IsA(c)return self.ClassName==c or(c=='BasePart'and(self.ClassName=='Part'or self.ClassName=='WedgePart'))end
function methods:GetChildren()return table.clone(self.children)end
function methods:GetDescendants()local out={};local function walk(o)for _,c in ipairs(o.children)do out[#out+1]=c;walk(c)end end;walk(self);return out end
function methods:FindFirstChild(n,recurse)for _,c in ipairs(recurse and self:GetDescendants()or self.children)do if c.Name==n then return c end end end
function methods:WaitForChild(n)return assert(self:FindFirstChild(n),'missing child '..n..' in '..self.Name)end
function methods:GetPropertyChangedSignal(k)self.changed[k]=self.changed[k]or signal();return self.changed[k]end
function methods:GetAttributeChangedSignal(k)self.attrSignals[k]=self.attrSignals[k]or signal();return self.attrSignals[k]end
function methods:SetAttribute(k,v)local old=self.attrs[k];self.attrs[k]=v;if old~=v and self.attrSignals[k]then self.attrSignals[k]:Fire()end end
function methods:GetAttribute(k)return self.attrs[k]end
function methods:Destroy()self.Destroying:Fire();for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
function methods:GetPivot()return self.props.WorldPivot or CF.new()end
function methods:PivotTo(cf)local delta=cf*self:GetPivot():Inverse();for _,p in ipairs(self:GetDescendants())do if p:IsA('BasePart')then p.CFrame=delta*p.CFrame end end;self.WorldPivot=cf end
function methods:FindFirstChildWhichIsA(c,recurse)for _,p in ipairs(recurse and self:GetDescendants()or self.children)do if p:IsA(c)then return p end end end
function methods:IsDescendantOf(parent)local at=self.Parent;while at do if at==parent then return true end;at=at.Parent end;return false end
local Random={}
function Random.new(seed)
 local state=(seed or 333)%2147483647
 local rng={}
 function rng:NextNumber(a,b)state=(state*48271)%2147483647;local f=state/2147483647;return a and a+f*((b or 1)-a)or f end
 function rng:NextInteger(a,b)return math.floor(self:NextNumber(a,b+1))end
 return rng
end
local typeof=function(v)return type(v)=='table'and v._kind or type(v)end
local services={};local game={JobId='mock-job'}
function game:GetService(n)return assert(services[n],'unmocked service '..n)end
local workspace=Instance.new('Workspace');services.Workspace=workspace
for _,n in ipairs({'ReplicatedStorage','Players','Lighting','CollectionService','RunService'})do services[n]=Instance.new(n)end
local Players=services.Players;local player=Instance.new('Player');player.Name='HarDvRaiN';player.UserId=123;player.Parent=Players;Players.LocalPlayer=player
function Players:GetPlayers()return {player}end
local playerGui=Instance.new('PlayerGui');playerGui.Name='PlayerGui';playerGui.Parent=player
local gui=Instance.new('ScreenGui');gui.Parent=playerGui
local remotes=Instance.new('Folder');remotes.Name='Remotes';remotes.Parent=services.ReplicatedStorage
local setLanguage=Instance.new('RemoteEvent');setLanguage.Name='SetLanguage';setLanguage.Parent=remotes;function setLanguage:FireServer()end
local tags={}
function services.CollectionService:AddTag(object,tag)tags[tag]=tags[tag]or{};table.insert(tags[tag],object)end
local dataStores={};local failStores={};local guid=0
local function deepCopy(v)if type(v)~='table'then return v end;local out={};for k,x in pairs(v)do out[k]=deepCopy(x)end;return out end
services.HttpService={GenerateGUID=function()guid+=1;return 'mock-guid-'..guid end}
services.DataStoreService={GetDataStore=function(_,name)
 dataStores[name]=dataStores[name]or{}
 return {GetAsync=function(_,key)if failStores[name]then error('simulated outage')end;return deepCopy(dataStores[name][key])end,
 UpdateAsync=function(_,key,fn)if failStores[name]then error('simulated outage')end;local result=fn(deepCopy(dataStores[name][key]));if result~=nil then dataStores[name][key]=deepCopy(result)end;return deepCopy(result)end}
end}
local refs={};local modules={};local loaders={}
local shared=Instance.new('Folder');shared.Name='Shared';shared.Parent=services.ReplicatedStorage
local config=Instance.new('Folder');config.Name='Config';config.Parent=shared
local serviceFolder=Instance.new('Folder');serviceFolder.Name='Services'
local function moduleRef(name,parent)local r=Instance.new('ModuleScript');r.Name=name;r.Parent=parent;refs[name]=r;return r end
local function require(ref)
 local name=type(ref)=='string'and ref or ref.Name
 if modules[name]~=nil then return modules[name]end
 local result=assert(loaders[name],'unmocked require '..name)();modules[name]=result;return result
end
local checks=0
local function check(condition,message)checks+=1;assert(condition,message)end
local ColorSequence={new=function(...)return {...}end};local NumberSequence={new=function(...)return {...}end};local NumberRange={new=function(...)return {...}end}
