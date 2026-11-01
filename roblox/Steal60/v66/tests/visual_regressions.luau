-- Geometry/readability and lifecycle checks; NOT a renderer or a listening test.
do
 local Typography=require('ShelfTypography')
 local panel=Instance.new('Part');panel.Name='IncomePlate';panel.Parent=workspace
 local sign=Typography.attach(panel,Enum.NormalId.Front,{'Ёлочка-ароматизатор ★0/5','+498 $/ч'})
 check(panel.Transparency==1 and not panel.CanCollide,'shelf no longer has a large solid black plate')
 local title=sign:FindFirstChild('ShelfLine1',true)
 check(title.TextSize==15 and not title.TextScaled,'item names use readable fixed pixel text')
 check(sign.Size.X.Offset<=236 and sign.Size.Y.Offset<=100,'background is measured to compact text size')
 local shortWidth=sign.Size.X.Offset
 title.Text='A';Typography.fit(sign)
 check(sign.Size.X.Offset<shortWidth,'card shrinks with short text instead of leaving empty black space')
 check(Typography.overlap({x=0,y=0,w=100,h=40},{x=90,y=0,w=100,h=40}),'overlapping screen labels detected')
 check(not Typography.overlap({x=0,y=0,w=100,h=40},{x=110,y=0,w=100,h=40}),'separate screen labels permitted')
 panel:Destroy()
 local View=require('LeaderboardView');local g=View.Geometry
 check(g.x-.12<31-.8,'scoreboard front is ahead of the occluding marble pillars')
 check(g.v-g.width/2>13+.8 and g.v+g.width/2<40-.8,'scoreboard fits between both pillars')
 local screen=Instance.new('Part');screen.Parent=workspace
 local view=View.attach(screen)
 check(view.heading.Position.X.Offset>=24 and view.heading.Position.X.Offset+view.heading.Size.X.Offset<View.WIDTH,'heading has real left/right canvas padding')
 check(#view.rows==10,'ten complete scoreboard rows')
 local unicode='Салон';View.setRow(view,1,{rank=1,name=unicode,score=123456789})
 check(view.rows[1].name.Text==unicode and view.rows[1].score.Text=='$ 123 456 789','separate name/score columns preserve full Unicode names')
 check(view.rows[1].name:GetAttribute('Steal60Literal')==true,'real player names opt out of translation')
 local langGui=Instance.new('ScreenGui');langGui.Parent=playerGui
 player:SetAttribute('Steal60Language','en');require('LanguageController').start(langGui);flush()
 check(view.rows[1].name.Text==unicode,'actual RU/EN binding leaves player display names unchanged')
 check(view.heading.Text=='SEASON TOP 10','new leaderboard heading translates')
 player:SetAttribute('Steal60Language','ru');flush();langGui:Destroy();screen:Destroy()
 check(View.looking(V.zero,V.xAxis,V.new(10,0,0))and not View.looking(V.zero,V.xAxis,V.new(-10,0,0)),'reading HUD suppression applies only while looking at a nearby board')
 print('PASS: compact measured shelf labels, overlap rules, unobscured leaderboard geometry, columns and literal Unicode names')
end
local Schedule=require('RoadEventSchedule')
check(Schedule.START_DELAY==3 and Schedule.START_DELAY<600/84,'events become visible before a fast car can cross the district')
local policeCount,repairCount=0,0
for district=1,100 do
 local initial=Schedule.kind(district,0)
 if initial=='police'then policeCount+=1 else repairCount+=1 end
 check(Schedule.kind(district,1)~=initial and Schedule.kind(district,2)==initial,'each district alternates police/repair without streaks')
end
check(policeCount==50 and repairCount==50,'neighboring districts split initial events evenly')
local Art=require('WorldArtDirector');local model=Instance.new('Model')
Art.decorateDistrict(model,6,3640,3680,4280)
local signs,posts=0,0
for _,object in ipairs(model:GetDescendants())do
 if object.Name=='CinematicSign'then signs+=1;check(object:GetAttribute('SignGrounded')==true,'road sign is grounded')end
 if object.Name=='SignSupport'then posts+=1;check(math.abs((object.Position.Y-object.Size.Y/2)-.15)<.001,'sign support reaches the ground')end
 if object:IsA('TextLabel')then check(not object.Text:find('60 / ',1,true),'no ambiguous floating 60/theme-number signs')end
end
check(signs>0 and posts==signs*2,'every district sign has two physical supports')
model:Destroy()
local Facing=require('RoadsideFacing')
for _,target in ipairs({V.new(10,10,0),V.new(-10,0,0),V.new(0,7,10),V.new(0,-4,-10)})do
 local origin=V.new(0,3,0);local cf=Facing.frame(origin,target);local wanted=(V.new(target.X,3,target.Z)-origin).Unit
 check(cf~=nil and cf.LookVector:Dot(wanted)>.999 and math.abs(cf.LookVector.Y)<.001,'NPC faces each player horizontally')
end
check(Facing.frame(V.zero,V.zero)==nil,'coincident viewer does not create an invalid facing matrix')
local Characters=require('RoadsideCharacters')
for _,police in ipairs({true,false})do
 local parent=Instance.new('Model');local npc=Characters.fallback(parent,V.zero,police)
 check(npc:GetAttribute('FullRoadsideUniform')and npc:FindFirstChild('FriendlyFace',true)~=nil,'rounded fallback has friendly face and complete role uniform')
 check(npc:FindFirstChild('Shoulder',true)and npc:FindFirstChild('Knee',true),'fallback limbs have rounded articulated silhouettes')
 parent:Destroy()
end
-- Force the asynchronous real-rig branch with an explicit R15 constructor double.
do
 local oldOwner=modules.OwnerService;local roles={}
 modules.OwnerService={newRig=function(_,role)
  roles[#roles+1]=role
  local rig=Instance.new('Model');rig.WorldPivot=CF.new(0,3,0)
  local hum=Instance.new('Humanoid');hum.HipHeight=2;hum.Parent=rig
  for _,entry in ipairs({{'HumanoidRootPart',0,3,0,2,2,1},{'UpperTorso',0,3.7,0,1.8,1.7,.9},{'LowerTorso',0,2.6,0,1.5,.6,.8},{'Head',0,5.1,0,1.1,1.1,1},{'RightHand',1.1,2.6,0,.5,.5,.5},{'LeftHand',-1.1,2.6,0,.5,.5,.5}})do
   local p=Instance.new('Part');p.Name=entry[1];p.Position=V.new(entry[2],entry[3],entry[4]);p.Size=V.new(entry[5],entry[6],entry[7]);p.Parent=rig
  end
  rig.PrimaryPart=rig.HumanoidRootPart
  return rig
 end}
 for _,police in ipairs({true,false})do
  local parent=Instance.new('Model');parent.Parent=workspace
  local fallback=Characters.create(parent,V.new(10,.25,10),police)
  local native=parent:FindFirstChild(police and'TrafficOfficer'or'RoadWorker')
  check(native and native:GetAttribute('RoadsideAppearance')=='R15Catalog'and fallback.Parent==nil,'loaded R15 outfit replaces the fallback once')
  check(native:GetAttribute('FullRoadsideUniform')and native.PrimaryPart.Anchored,'R15 prop rig retains role outfit and stationary root')
  parent:Destroy()
 end
 check(roles[1]=='trafficOfficer'and roles[2]=='roadWorker','police and construction use different catalog outfit profiles')
 modules.OwnerService=oldOwner
end
print('PASS: balanced early police/repair scheduling, grounded district signs, per-viewer facing and dressed rounded/R15 actor paths')
-- Sound identity/volume gating, not audio audition or proof of asset permission.
local Score=require('MusicScore');local Engine=require('EngineAudio')
check(#Score.Siren==0 and #Score.Alarm==0,'all old police scream/alarm clips removed')
for _,speed in ipairs({0,10,42,84,200})do local volume,pitch=Engine.parameters(speed,84,true);check(volume<=.025 and volume>=0 and pitch>=.72 and pitch<=1.22,'engine volume and pitch stay quiet/bounded')end
local volume=Engine.parameters(84,84,false);check(volume==0,'no engine volume outside the driver seat')
do
 local oldChar=player.Character;local oldClock=testClock;testClock=3000
 local character=Instance.new('Model');character.Parent=workspace;player.Character=character
 local hum=Instance.new('Humanoid');hum.Health=100;hum.Parent=character
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=character
 local death=Instance.new('Sound');death.Name='Died';death.Volume=.7;death.Parent=root;death:Play()
 local car=Instance.new('Model');car.Parent=workspace;car:SetAttribute('Drivable',true);car:SetAttribute('DriverId',player.UserId);car:SetAttribute('MaxSpeed',42)
 local seat=Instance.new('VehicleSeat');seat.Parent=car;seat.Occupant=hum;hum.SeatPart=seat
 local body=Instance.new('Part');body.Name='Body';body.AssemblyLinearVelocity=V.new(15,0,0);body.Parent=car;car.PrimaryPart=body
 local rootGui=Instance.new('ScreenGui');rootGui.Parent=playerGui;Engine.start(rootGui)
 services.RunService.Heartbeat:Fire(.1)
 local engine=services.SoundService:FindFirstChild('Steal60QuietEngine')
 check(engine and engine.IsPlaying and engine.Volume>0 and engine.Volume<=.025,'actual engine controller plays quietly for the driver')
 engine.TimeLength=5;engine.Loaded:Fire()
 check(engine.PlaybackRegionsEnabled and engine.LoopRegion.Min==1 and math.abs(engine.LoopRegion.Max-3.9)<.00001,'loaded engine uses the interior sustain region')
 local filter=engine:FindFirstChild('RemoveMetallicTick');local limiter=engine:FindFirstChild('SoftEnginePeaks')
 check(filter and filter.HighGain==-36 and limiter and limiter.Ratio==5,'actual engine installs treble attenuation and transient compression')
 local pitch=engine.PlaybackSpeed;body.AssemblyLinearVelocity=V.new(42,0,0);services.RunService.Heartbeat:Fire(.1)
 check(engine.PlaybackSpeed>pitch and engine.PlaybackSpeed<1.22,'engine pitch changes smoothly without a full instantaneous jump')
 player:SetAttribute('PoliceActive',true);services.RunService.Heartbeat:Fire(.1)
 check(death.Volume==0 and not death.IsPlaying,'police return also suppresses default character death scream')
 hum.SeatPart=nil;seat.Occupant=nil;services.RunService.Heartbeat:Fire(.1)
 check(not engine.IsPlaying and engine.Volume==0,'actual engine controller stops immediately on exit')
 player:SetAttribute('PoliceActive',false);testClock=3006;services.RunService.Heartbeat:Fire(.1)
 check(death.Volume==.7,'normal character sound volume restores after the quiet return window')
 rootGui:Destroy();car:Destroy();character:Destroy();player.Character=oldChar;testClock=oldClock
end
-- Run actual handbook construction without starting its infinite render loop.
do
 for _,name in ipairs({'TutorialAction','TutorialUpdate'})do if not remotes:FindFirstChild(name)then
  local remote=Instance.new('RemoteEvent');remote.Name=name;remote.OnClientEvent=signal();function remote:FireServer()end;remote.Parent=remotes
 end end
 local root=Instance.new('ScreenGui');root.Parent=playerGui
 local oldParent=refs.TutorialHUD.Parent;refs.TutorialHUD.Parent=root
 local oldSpawn=task.spawn;task.spawn=function()end;loaders.TutorialHUD();task.spawn=oldSpawn
 local button
 for _,object in ipairs(root:GetChildren())do if object:IsA('TextButton')and object.Text=='РУКОВОДСТВО'then button=object end end
 check(button and button.AnchorPoint.X==1 and button.Position.X.Scale==1 and button.Position.Y.Offset==8,'handbook button is in the upper-right header')
 check(button.Size.Y.Offset==28 and button.Size.X.Offset==96,'handbook leaves six pixels above the RU/music row')
 refs.TutorialHUD.Parent=oldParent;root:Destroy()
end
print('PASS: quiet driver-only engine lifecycle, police/death sound suppression and actual handbook-header construction; rendering/assets still require Studio')
-- Inspect actual native geometry, independently of the declared layout footprints.
for _,kind in ipairs({'police','repair'})do for _,side in ipairs({-1,1})do
 local root=Instance.new('Model');local Roadside=require('RoadsideArt');Roadside.decorate(root,kind,100,side)
 local boxes={}
 for _,child in ipairs(root:GetChildren())do if child:IsA('Model')then
  local low=V.new(math.huge,math.huge,math.huge);local high=V.new(-math.huge,-math.huge,-math.huge)
  for _,p in ipairs(child:GetDescendants())do if p:IsA('BasePart')and p.Transparency<1 then
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
    local point=p.CFrame:PointToWorldSpace(p.Size*.5*V.new(x,y,z))
    low=V.new(math.min(low.X,point.X),math.min(low.Y,point.Y),math.min(low.Z,point.Z));high=V.new(math.max(high.X,point.X),math.max(high.Y,point.Y),math.max(high.Z,point.Z))
   end end end
  end end
  check(side==1 and low.Z>2 or side==-1 and high.Z< -2,'patrol/backhoe and NPC leave the opposite driving lane open')
  boxes[#boxes+1]={low=low,high=high,name=child.Name}
 end end
 check(#boxes==2,'roadside event has one actor and one detailed vehicle')
 for i=1,#boxes do for j=i+1,#boxes do local a,b=boxes[i],boxes[j]
  check(a.high.X<b.low.X or b.high.X<a.low.X or a.high.Z<b.low.Z or b.high.Z<a.low.Z,'roadside actor does not intersect machinery: '..kind)
 end end
 root:Destroy()
end end
print('PASS: actual patrol/backhoe/NPC bounds on both road sides; actors separate from vehicles and opposite lane open')
-- Full ParkingService construction/update, with only the factory, profiles and loading IO doubled.
do
 local saved={};for _,name in ipairs({'ParkingService','CarFactory','DistrictManager','DataService'})do saved[name]=modules[name]end
 local oldSpawn,oldWait,oldPlayers,oldCharacter=task.spawn,task.wait,Players.GetPlayers,player.Character
 local pending={};local now=0
 local function resume(co,...)
  local ok,delay=coroutine.resume(co,...);assert(ok,delay)
  if coroutine.status(co)~='dead'then pending[#pending+1]={co=co,at=now+(delay or 0)}end
 end
 task.spawn=function(fn,...)local co=coroutine.create(fn);resume(co,...);return co end
 task.wait=function(delay)return coroutine.yield(delay or .01)end
 local function advance(seconds)
  local limit=now+seconds
  for _=1,10000 do
   local pick;for i,item in ipairs(pending)do if item.at<=limit and(not pick or item.at<pending[pick].at)then pick=i end end
   if not pick then now=limit;return end
   local item=table.remove(pending,pick);now=item.at;resume(item.co)
  end
  error('parking scheduler did not settle')
 end
 local Layout=require('TrackLayout');local character=Instance.new('Model');character.Parent=workspace;player.Character=character
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(Layout.districtStart(6)+100,3,0);root.Parent=character
 function Players:GetPlayers()return {player}end
 local data={hackLevel=16};modules.DataService={get=function()return data end}
 local loaded,unloaded
 modules.DistrictManager={onLoaded=function(fn)loaded=fn end,onUnloaded=function(fn)unloaded=fn end}
 modules.CarFactory={acquire=function()local car=Instance.new('Model');return car end,
  dress=function(car,def,class,rarity,variant)car:SetAttribute('CarId',def.id);car:SetAttribute('ClassId',class);car:SetAttribute('Rarity',rarity);car:SetAttribute('Variant',variant)end,
  release=function(car)car:Destroy()end,setBusy=function()end,setPromptHandler=function()end}
 modules.ParkingService=nil;local Parking=require('ParkingService');Parking.init()
 local district=Instance.new('Model');district.Parent=workspace;local slots=Instance.new('Folder');slots.Name='ParkSlots';slots.Parent=district
 for index=1,8 do local slot=Instance.new('Part');slot.Position=V.new(Layout.districtStart(6)+40+index*20,0,25);slot:SetAttribute('Index',index);slot:SetAttribute('Side',1);slot.Parent=slots end
 loaded(6,district);advance(.5)
 local firstIds={}
 for _,level in ipairs({16,25,30,45})do
  data.hackLevel=level;advance(1.1)
  local normal,hard,minimum,maximum=0,0,math.huge,0
  for _,car in ipairs(Parking.getAvailableCars(6))do local required=car:GetAttribute('RequiredHack')
   if car:GetAttribute('EndlessChallenge')then hard+=1;check(required==math.max(31,level+1),'real hard slot updates above the current player skill');check(not require('HackRequirements').canHack(data,required),'hard slot still rejects the real skill predicate')
   else
    normal+=1;minimum=math.min(minimum,required);maximum=math.max(maximum,required)
    check(car:GetAttribute('ClassId')=='super'and required>=25 and required<=30,'actual normal spawn stays super/25..30 at every player skill')
    if level==16 then check(not require('HackRequirements').canHack(data,required),'level 16 cannot bypass the 25..30 parked-car requirement');firstIds[car]=true
    else check(firstIds[car]==true,'normal cars are not replaced merely because the player leveled up')end
   end
  end
  check(normal==7 and hard==1 and minimum==25 and maximum==30,'actual district has seven ordinary targets spanning 25..30 and exactly one police target')
 end
 unloaded(6,district);check(#Parking.getAvailableCars(6)==0 and #district.Cars:GetChildren()==0,'unloaded endgame parking releases all cars')
 district:Destroy();character:Destroy();player.Character=oldCharacter
 local stolen=workspace:FindFirstChild('StolenCars');if stolen then stolen:Destroy()end
 for _,name in ipairs({'ParkingService','CarFactory','DistrictManager','DataService'})do modules[name]=saved[name]end
 task.spawn,task.wait,Players.GetPlayers=oldSpawn,oldWait,oldPlayers
end
print('PASS: actual ParkingService spawns 7 cars at 25..30 + one challenge, preserves normals across skill changes, enforces real skill predicate and unloads')
