-- Wheel geometry on the actual 150-car catalog, plus real showroom refresh wiring.
do
 local Ground=require('CarGrounding');local Visual=require('CarVisualLibrary');local Classes=require('CarClasses')
 for _,def in ipairs(require('Cars'))do for _,side in ipairs({-1,1})do
  local car=Visual.build(def,Classes[def.class]);car:PivotTo(CF.new(30,.95,side*50)*CF.Angles(0,side*math.pi/2,0))
  Ground.place(car,.545,.012)
  check(math.abs(Ground.bottom(car)-.557)<.00001,'catalog tyres rest on the exhibit pad rather than the model pivot: '..def.id)
  local before=car:GetPivot().Position;Ground.place(car,.545,.012)
  check((car:GetPivot().Position-before).Magnitude<.0001,'unchanged showroom refresh never creeps upward');car:Destroy()
 end end
 local models={};local carId=require('Cars')[1].id
 local profile={catalog={[carId]={bestRarity='common'}},upgrades={},coinUpgrades={}}
 local factory={acquire=function(def,class)local c=Visual.build(def,Classes[class]);c:SetAttribute('CarId',def.id);c:SetAttribute('Rarity','common');c:SetAttribute('Variant','default');models[#models+1]=c;return c end,
  dress=function()end,setDisplay=function()end,updateSalonSecurity=function()end,release=function(car)car:Destroy()end}
 local refresh=makeShowcaseRefresh({get=function()return profile end},factory,{carId})
 local host=Instance.new('Model');host.Parent=workspace
 local rec={player=player,model=host,displays={},slotCFrames={[1]=CF.new(30,.95,50)},slotSurfaceY={[1]=.545}}
 refresh(rec);local first=rec.displays[1]
 check(first and math.abs(Ground.bottom(first)-.557)<.0001,'real showroom function invokes wheel-based placement on spawn')
 refresh(rec);check(rec.displays[1]==first and #models==1,'real showroom refresh keeps the same grounded instance');host:Destroy()
end
-- Actual input GUI, DriveService, DrivePresentation and DriveDynamics. Native physics integration/replication are not emulated.
do
 local names={'DriveService','DrivePresentation','DriveState','MonetizationService','Net'};local saved={};for _,n in ipairs(names)do saved[n]=modules[n]end
 local oldSpawn,oldWait,oldDelay,oldClock=task.spawn,task.wait,task.delay,testClock
 local previousChar=player.Character;local previousTouch=services.UserInputService.TouchEnabled;local previousType=services.UserInputService.GetLastInputType
 local previousWait=services.RunService.Heartbeat.Wait;local previousInvoke=Players.GetPlayers
 local allSignals={services.RunService.Heartbeat,services.RunService.PreSimulation,Players.PlayerRemoving,workspace.DescendantAdded,
  services.UserInputService.InputBegan,services.UserInputService.InputChanged,services.UserInputService.InputEnded,services.UserInputService.GamepadDisconnected}
 for _,tag in ipairs({'S60DriveObstacle','S60KnockdownCone','S60DrivableCar'})do
  allSignals[#allSignals+1]=services.CollectionService:GetInstanceAddedSignal(tag);allSignals[#allSignals+1]=services.CollectionService:GetInstanceRemovedSignal(tag)
 end
 local counts={};for _,s in ipairs(allSignals)do counts[s]=#s.listeners end
 local pending={};local now=60000;testClock=now
 local function resume(co,...)local ok,delay=coroutine.resume(co,...);assert(ok,delay);if coroutine.status(co)~='dead'then pending[#pending+1]={co=co,at=now+(delay or .01)}end end
 task.spawn=function(fn,...)local co=coroutine.create(fn);resume(co,...);return co end
 task.wait=function(delay)return coroutine.yield(delay or .01)end
 task.delay=function(delay,fn,...)local args=table.pack(...);pending[#pending+1]={at=now+delay,fn=function()fn(table.unpack(args,1,args.n))end}end
 function services.RunService.Heartbeat:Wait()return task.wait(.016)end
 local function advance(dt)
  local target=now+dt
  for _=1,10000 do
   local pick;for i,v in ipairs(pending)do if v.at<=target and(not pick or v.at<pending[pick].at)then pick=i end end
   if not pick then now=target;testClock=now;services.RunService.Heartbeat:Fire(dt);services.RunService.PreSimulation:Fire(dt);return end
   local item=table.remove(pending,pick);now=item.at;testClock=now;if item.co then resume(item.co)else item.fn()end
  end;error('driving test scheduler did not settle')
 end
 local char=Instance.new('Model');char.Parent=workspace;player.Character=char
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(450,3,0);root.Parent=char;char.WorldPivot=root.CFrame
 local hum=Instance.new('Humanoid');hum.Health=100;hum.Parent=char
 player:SetAttribute('DataLoaded',true);player:SetAttribute('GameplayReady',true);player:SetAttribute('HackActive',false);player:SetAttribute('Steal60MenuOpen',false);player:SetAttribute('TutorialComplete',true)
 services.UserInputService.TouchEnabled=true;function services.UserInputService:GetLastInputType()return Enum.UserInputType.Touch end
 local scripts=Instance.new('Folder');scripts.Name='PlayerScripts';scripts.Parent=player
 local native=moduleRef('PlayerModule',scripts);local joystick=V.new(.5,0,-.75)
 loaders.PlayerModule=function()return{GetControls=function()return{GetMoveVector=function()return joystick end}end}end
 modules.PlayerModule=nil;modules.DriveState=nil;modules.DrivePresentation=nil;modules.DriveService=nil
 modules.MonetizationService={speedMultiplier=function()return 1 end}
 local inputEvent,recoverEvent=signal(),signal();local correction=signal();local corrections=0
 modules.Net={DriveInput={OnServerEvent=inputEvent},RecoverCar={OnServerEvent=recoverEvent},DriveSnapshot={FireClient=function(_,_,car,cf,epoch)corrections+=1;correction:Fire(car,cf,epoch)end},notify=function()end,notifyKey=function()end}
 local createdRemotes={};local previousRemoteMethods={}
 local Security=require('SecurityService')
 for name,event in pairs({DriveInput=inputEvent,RecoverCar=recoverEvent})do
  local remote=remotes:FindFirstChild(name)
  if not remote then remote=Instance.new('RemoteEvent');remote.Name=name;remote.Parent=remotes;createdRemotes[#createdRemotes+1]=remote end
  previousRemoteMethods[remote]=remote.FireServer
  function remote:FireServer(...)Security.wrap(name,function(who,...)event:Fire(who,...)end)(player,...)end
 end
 local Drive=require('DriveService');Drive.init();require('DrivePresentation').start({OnClientEvent=correction})
 local screen=Instance.new('ScreenGui');screen.Parent=playerGui;local control=startDrivingUI(screen)
 check(#control:GetChildren()==1 and control:FindFirstChild('RecoverVehicle')~=nil,'touch UI keeps only recovery; native left joystick replaces all four direction buttons')
 local def=require('Cars')[1];local car=require('CarVisualLibrary').build(def,require('CarClasses')[def.class]);car:PivotTo(CF.new(450,0,0));car.Parent=workspace;car:SetAttribute('DriverId',player.UserId)
 local seat=Drive.enable(car,42);local sits=0
 function seat:Sit(who)sits+=1;self.Occupant=who;who.Sit=true;who.SeatPart=nil end -- delayed SeatPart/Occupant arrival at the client
 local confirmed=0;check(Drive.seatPlayer(player,car,function(ok)if ok then confirmed+=1 end end),'first seating request accepted')
 advance(.2)
 check(sits==1 and confirmed==1,'first Sit is confirmed without forcing the player to jump and re-enter')
 check(require('DriveState').current(player)==car and hum.SeatPart==nil,'server-verified reference resolves the car while client SeatPart is still late')
 local body=car:FindFirstChild('Body',true);local epoch=car:GetAttribute('DriveEpoch')
 check(car:GetAttribute('ClientDriveOwner')==player.UserId and body.NetworkOwner==player,'verified first-seat input grants one physics writer')
 for _=1,12 do advance(.08)end
 check(body.AssemblyLinearVelocity.Magnitude>20,'actual native joystick drives on the first seat even when VehicleSeat throttle is zero')
 local t,s=require('DriveState').input(car);check(t==.75 and s==.5,'actual PlayerModule move vector supplies analog throttle and steering')
 check(math.abs(body.AssemblyLinearVelocity:Dot(body.CFrame.LookVector))<.0001,'commanded velocity stays longitudinal to the real body heading, avoiding sideways ice motion')
 local front=car.DriveRig:FindFirstChild('SteeringMotor_FL');local rear=car.DriveRig:FindFirstChild('SteeringMotor_RL')
 check(front and rear and front.Transform and rear.Transform,'all wheel motors roll, including rear wheels')
 check((front.Transform.UpVector-rear.Transform.UpVector).Magnitude>.01,'front wheel steering is layered on top of wheel rolling')
 check(car.DriveRig.DriveHeading.RigidityEnabled and car.DriveRig.DriveHeading.Responsiveness==200,'upright heading constraint follows steering without a soft yaw lag')
 joystick=V.zero;for _=1,5 do advance(.08)end
 check(body.AssemblyLinearVelocity.Magnitude<.001,'releasing the standard stick stops ordinary-speed coasting promptly')
 local outsider=Instance.new('Player');outsider.UserId=999;outsider.Parent=Players
 inputEvent:Fire(outsider,car,1,1,60,epoch);inputEvent:Fire(player,car,1,1,60,epoch+100)
 advance(.16);check(body.AssemblyLinearVelocity.Magnitude<.001,'wrong owner and stale rig epoch cannot drive the car')
 local safe=body.CFrame;body.Position=V.new(90000,body.Position.Y,0)
 check(Drive.validatePosition(car,player)==false and(body.Position-safe.Position).Magnitude<.001 and corrections>0,'real server movement budget still rolls back an invalid vehicle position')
 seat.Occupant=nil;hum.Sit=false;hum.SeatPart=nil;advance(.16)
 check(car:GetAttribute('DriverSeatedId')==nil and not require('DriveState').current(player),'leaving clears the verified-seat marker and driving input')
 Drive.disable(car);car:Destroy();screen:Destroy();outsider:Destroy();char:Destroy();scripts:Destroy()
 for remote,fn in pairs(previousRemoteMethods)do remote.FireServer=fn end;for _,remote in ipairs(createdRemotes)do remote:Destroy()end
 for _,signal in ipairs(allSignals)do for i=counts[signal]+1,#signal.listeners do signal.listeners[i][2]:Disconnect()end end
 Security.setDriveValidator(nil);player.Character=previousChar;services.UserInputService.TouchEnabled=previousTouch;services.UserInputService.GetLastInputType=previousType
 services.RunService.Heartbeat.Wait=previousWait;Players.GetPlayers=previousInvoke
 for _,n in ipairs(names)do modules[n]=saved[n]end;modules.PlayerModule=nil;loaders.PlayerModule=nil;refs.PlayerModule=nil
 task.spawn,task.wait,task.delay,testClock=oldSpawn,oldWait,oldDelay,oldClock
end
print('PASS: 150-car exhibit grounding, actual showroom wiring, first-seat native joystick/server handoff, no duplicate direction UI, longitudinal drive commands, wheel rolling and server rollback (no native physics integration)')
