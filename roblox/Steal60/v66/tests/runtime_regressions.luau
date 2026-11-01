-- Real API contracts behind the user's Output errors.
do
 local Security=require('SecurityService');local anchor=Instance.new('Part');anchor.Parent=workspace
 local prompt=Instance.new('ProximityPrompt');prompt.Parent=anchor;prompt.Enabled=true;local called=0
 local subscription=Security.prompt(prompt,function()called+=1 end)
 check(type(subscription.Disconnect)=='function','secure prompt exposes the Disconnect contract used by ThiefService')
 subscription:Disconnect();subscription:Disconnect()
 for _,connection in ipairs(subscription)do check(not connection.Connected,'composite disconnect releases every underlying connection')end
 anchor:Destroy();check(called==0,'destroying a disconnected prompt cannot invoke its handler')
 for _,motor in ipairs({false,true})do
  local rig=Instance.new('Model');local hand=Instance.new('Part');hand.Name='RightHand';hand.Parent=rig
  local joint=Instance.new(motor and'Motor6D'or'AnimationConstraint');joint.Name='RightShoulder';joint.C0=CF.new();joint.Parent=rig
  local before=joint.C0;local cleanup=makeStreetCoffee(rig)
  check(cleanup~=nil,'coffee prop still builds with either joint class')
  if motor then check(joint.C0~=before,'coffee pose uses an editable Motor6D')else check(joint.C0==before,'read-only animation joint is left untouched')end
  cleanup();check(joint.C0==before and not rig:FindFirstChild('Coffee'),'coffee cleanup restores the editable joint and removes the prop');rig:Destroy()
 end
end
-- Smoke test the actual new sound lifecycle; NOT an audio audition.
do
 local beforeClock=testClock;local previousChar=player.Character;testClock=40000
 local character=Instance.new('Model');character.Parent=workspace;player.Character=character
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(30,3,0);root.Parent=character
 local gui=Instance.new('ScreenGui');gui.Parent=playerGui
 local Police=require('PoliceAudio');Police.start(gui)
 local sound=services.SoundService:FindFirstChild('Steal60PoliceSiren')
 check(sound and not sound.IsPlaying,'standalone siren is silent outside police pursuit')
 player:SetAttribute('PolicePosition',V.new(30,0,0));player:SetAttribute('PoliceActive',true)
 for _=1,15 do services.RunService.Heartbeat:Fire(.1)end
 check(sound.IsPlaying and sound.Volume>.1 and sound.Volume<=.26,'police pursuit plays one moderate-volume siren')
 player:SetAttribute('PoliceActive',false)
 for _=1,15 do services.RunService.Heartbeat:Fire(.1)end
 check(not sound.IsPlaying and sound.Volume==0,'siren fades and stops after police return')
 check(require('EngineAudio').ASSET=='rbxassetid://13114759','engine identity is preserved')
 local first,last=require('EngineAudio').loopRange(10);check(first>0 and last<10 and last-first>=1,'engine sustains an interior loop away from intro/outro transients')
 gui:Destroy();character:Destroy();player.Character=previousChar;testClock=beforeClock
end
-- Actual server session, actual client minigame, actual ingress wrapper and actual music controller.
do
 local names={'HackService','DataService','Net','ParkingService','DriveService','OwnerService','PoliceService','DeliveryService','SalonService','MonetizationService','HeistService','TutorialService'}
 local saved={};for _,name in ipairs(names)do saved[name]=modules[name]end
 local oldSpawn,oldWait,oldDelay,oldClock=task.spawn,task.wait,task.delay,testClock
 local previousCharacter,previousTimer,previousPlayers=player.Character,workspace.GetServerTimeNow,Players.GetPlayers
 local now=50000;local pending={};testClock=now
 local function resume(co,...)local ok,delay=coroutine.resume(co,...);assert(ok,delay);if coroutine.status(co)~='dead'then pending[#pending+1]={co=co,at=now+(delay or 0)}end end
 task.spawn=function(fn,...)local co=coroutine.create(fn);resume(co,...);return co end
 task.wait=function(delay)return coroutine.yield(delay or .01)end
 task.delay=function(delay,fn,...)local args=table.pack(...);pending[#pending+1]={at=now+delay,fn=function()fn(table.unpack(args,1,args.n))end}end
 function workspace:GetServerTimeNow()return now end
 function Players:GetPlayers()return {player}end
 local function advance(seconds)
  local target=now+seconds
  for _=1,10000 do
   local pick;for i,v in ipairs(pending)do if v.at<=target and(not pick or v.at<pending[pick].at)then pick=i end end
   if not pick then now=target;testClock=now;services.RunService.Heartbeat:Fire(seconds);services.RunService.RenderStepped:Fire();return end
   local item=table.remove(pending,pick);now=item.at;testClock=now;if item.co then resume(item.co)else item.fn()end
  end
  error('hack scheduler did not settle')
 end
 local character=Instance.new('Model');character.Parent=workspace;player.Character=character
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(450,3,0);root.Parent=character
 local hum=Instance.new('Humanoid');hum.Health=100;hum.Parent=character
 player:SetAttribute('DataLoaded',true);player:SetAttribute('GameplayReady',true);player:SetAttribute('HackActive',false);player:SetAttribute('HeistCarrying',false)
 local profile={hackLevel=30,upgrades={},coinUpgrades={},till=1000};local carrying;local delivered=0;local helpers=0;local seats=0
 local stepSignal=signal();local tapEvent,cancelEvent=signal(),signal();local openClient,closeClient;local lastStart;local lastStep;local dropNextStep=false;local dropNextTap=false;local muteTap=false;local dropSteps=false
 local net={notify=function()end,HackTap={OnServerEvent=tapEvent},HackCancel={OnServerEvent=cancelEvent}}
 net.HackStart={FireClient=function(_,who,payload)lastStart=payload;openClient(payload)end}
 net.HackStep={FireClient=function(_,who,payload)lastStep=payload;if dropNextStep or dropSteps then dropNextStep=false;return end;stepSignal:Fire(payload)end}
 modules.Net=net;modules.DataService={get=function()return profile end,requestSave=function()end}
 local onPrompt
 modules.ParkingService={onPromptTriggered=function(fn)onPrompt=fn end,
  tryLock=function(car,who)if car:GetAttribute('State')~='available'then return false end;car:SetAttribute('State','busy');car:SetAttribute('LockedBy',who.UserId);return true end,
  unlock=function(car)car:SetAttribute('State','available');car:SetAttribute('LockedBy',nil)end,
  consume=function(car)if car:GetAttribute('State')~='busy'then return nil end;car:SetAttribute('State','stolen');return{classId='junk',carId='rusty_hatch',rarity='common',variantId='default'}end,recycle=function()end}
 modules.DriveService={enable=function()return true end,maxSpeedFor=function()return 42 end,seatPlayer=function()seats+=1 end}
 modules.OwnerService={spawn=function()end};modules.PoliceService={dispatch=function()error('unexpected police for an ordinary memory mistake')end}
 modules.DeliveryService={getCarrying=function()return carrying end,track=function(car)carrying=car;delivered+=1 end}
 modules.SalonService={onHackStarted=function()helpers+=1 end};modules.MonetizationService={hackAssist=function()return 0 end}
 modules.HeistService={onFailed=function()end};modules.TutorialService={isFirstHeist=function()return false end,event=function()end}
 local Security=require('SecurityService');local ui=Instance.new('ScreenGui');ui.Parent=playerGui
 local clientTap={FireServer=function(_,...)if dropNextTap or muteTap then dropNextTap=false;return end;Security.wrap('HackTap',function(who,...)tapEvent:Fire(who,...)end)(player,...)end}
 local clientCancel={FireServer=function(_,token)Security.wrap('HackCancel',function(who,t)cancelEvent:Fire(who,t)end)(player,token)end}
 openClient,closeClient=makeHackClient(ui,clientTap,{OnClientEvent=stepSignal},clientCancel)
 local audioRemote=remotes:FindFirstChild('SetAudio');local addedAudio=not audioRemote
 if not audioRemote then audioRemote=Instance.new('RemoteEvent');audioRemote.Name='SetAudio';audioRemote.Parent=remotes;function audioRemote:FireServer()end end
 local musicGui=Instance.new('ScreenGui');musicGui.Parent=playerGui;require('MusicDirector').start(musicGui)
 modules.HackService=nil;require('HackService').init()
 local cars={}
 local function car()
  local c=Instance.new('Model');c.Name='Memory regression target';c.WorldPivot=CF.new(450,0,0);c.Parent=workspace;c:SetAttribute('ClassId','junk');c:SetAttribute('RequiredHack',1);c:SetAttribute('State','available');cars[#cars+1]=c;return c
 end
 local first=car();onPrompt(player,first);check(lastStart.mode=='pins','actual rotation starts with pins')
 ui:FindFirstChild('Cancel',true).Activated:Fire();advance(.1)
 check(first:GetAttribute('State')=='available'and not player:GetAttribute('HackActive')and player:GetAttribute('Steal60AudioMode')=='ambient','cancel releases server lock and returns actual music to ambient')
 local memory=car();onPrompt(player,memory);check(lastStart.mode=='memory','actual next target is the memory puzzle')
 local token=lastStart.sessionId;local sequence=lastStart.zone.sequence
 advance(.85+require('HackModes').memoryDuration(lastStart.zone)+.1)
 ui:FindFirstChild('MemoryKey'..sequence[1],true).Activated:Fire();check(lastStep.state=='memory_progress'and lastStep.memoryIndex==2,'first actual client key advances memory on server')
 -- An old/fast client used to receive NO acknowledgement here and then wait forever.
 tapEvent:Fire(player,'memory_'..sequence[2],token)
 check(lastStep.state=='wait'and lastStep.memoryIndex==2,'too-fast key receives an authoritative wait acknowledgement')
 advance(.21);dropNextStep=true;ui:FindFirstChild('MemoryKey'..sequence[2],true).Activated:Fire()
 advance(1.1);check(lastStep.state=='sync'and lastStep.memoryIndex==3,'lost progress response recovers via actual client watchdog and server sync')
 advance(.21);dropNextStep=true;ui:FindFirstChild('MemoryKey'..sequence[3],true).Activated:Fire()
 check(lastStep.state=='success'and delivered==1 and seats==1 and memory:GetAttribute('DriverId')==player.UserId,'three-key memory completes exactly once and enables the verified car')
 advance(1.1);check(lastStep.state=='success'and delivered==1 and seats==1,'lost terminal success is restored without a second car or delivery');advance(1.1);carrying=nil;player:SetAttribute('HeistCarrying',false)
 local nextCar=car();onPrompt(player,nextCar);local current=lastStart.sessionId
 cancelEvent:Fire(player,token);check(nextCar:GetAttribute('State')=='busy'and player:GetAttribute('HackActive'),'stale cancel token cannot clear a newer session')
 root.Position=V.new(10000,3,0);ui:FindFirstChild('Cancel',true).Activated:Fire();advance(.1)
 check(nextCar:GetAttribute('State')=='available'and not player:GetAttribute('HackActive')and player:GetAttribute('Steal60AudioMode')=='ambient','cancel works even after movement validation would reject gameplay commands')
 root.Position=V.new(450,3,0);local removed=car();onPrompt(player,removed);removed:Destroy();advance(.1)
 check(not player:GetAttribute('HackActive')and not ui:FindFirstChild('HackVarietyV26'),'destroyed target also closes the client and clears its session')
 check(helpers>=4,'helper return hook still runs once for each genuine new target')
 -- Lost client command, duplicate request and all remaining production puzzle modes.
 local reliable=car();onPrompt(player,reliable);check(lastStart.mode=='pins','rotation returns to the real pins puzzle')
 local function hitBar(payload)
  advance(math.max(.01,payload.startAt+payload.zone.c*payload.period-now))
  ui:FindFirstChild('HackAction',true).Activated:Fire()
 end
 dropNextTap=true;hitBar(lastStart);advance(1.1)
 check(lastStep.ack==1,'sync discovers an unprocessed request and the actual client retransmits it with the same ID')
 local before=delivered;local cached=lastStep
 tapEvent:Fire(player,'tap',lastStart.sessionId,1,1)
 check(lastStep.ack==1 and delivered==before,'duplicate acknowledged command cannot advance the puzzle twice')
 if lastStep.state~='success'then hitBar(lastStep)end
 check(lastStep.state=='success'and delivered==(cached.state=='success'and before or before+1),'pins still completes through real server timing after request recovery')
 advance(1.1);carrying=nil;player:SetAttribute('HeistCarrying',false)
 local skipped=car();onPrompt(player,skipped);check(lastStart.mode=='memory','memory remains in the real rotation');ui:FindFirstChild('Cancel',true).Activated:Fire();advance(.1)
 local wires=car();onPrompt(player,wires);check(lastStart.mode=='wires','actual wire UI opens');advance(.9)
 before=delivered;ui:FindFirstChild('Wire'..lastStart.zone.target,true).Activated:Fire()
 check(lastStep.state=='success'and delivered==before+1,'actual wire selection completes a verified car handoff')
 tapEvent:Fire(player,'wire_'..lastStart.zone.target,lastStart.sessionId,1,1)
 check(delivered==before+1 and lastStep.state=='success','replayed terminal command returns the outcome without a second car')
 advance(1.1);carrying=nil;player:SetAttribute('HeistCarrying',false)
 local dial=car();onPrompt(player,dial);check(lastStart.mode=='dial','actual dial UI opens');before=delivered;hitBar(lastStart)
 check(lastStep.state=='success'and delivered==before+1,'actual dial completes with authoritative server timing')
 advance(1.1);carrying=nil;player:SetAttribute('HeistCarrying',false)
 -- A helper/native rig exception must not leave BUSY or pretend that a car was awarded.
 local oldEnable,oldHelper=modules.DriveService.enable,modules.SalonService.onHackStarted
 modules.SalonService.onHackStarted=function()error('injected helper failure')end
 local broken=car();onPrompt(player,broken);check(ui:FindFirstChild('HackAction',true)~=nil,'helper exception does not prevent the puzzle from opening')
 modules.SalonService.onHackStarted=oldHelper;modules.DriveService.enable=function()error('injected rig construction failure')end
 before=delivered;hitBar(lastStart)
 check(lastStep.state=='cancelled'and broken:GetAttribute('State')=='available'and not player:GetAttribute('HackActive')and delivered==before,'failed native rig preparation cancels cleanly before consuming the parking slot')
 modules.DriveService.enable=oldEnable
 local noReply=car();onPrompt(player,noReply);check(lastStart.mode=='memory','memory opens for the no-response scenario')
 advance(.85+require('HackModes').memoryDuration(lastStart.zone)+.1);dropSteps=true
 ui:FindFirstChild('MemoryKey'..lastStart.zone.sequence[1],true).Activated:Fire();advance(8.2);dropSteps=false
 check(noReply:GetAttribute('State')=='available'and not player:GetAttribute('HackActive')and not ui:FindFirstChild('HackVarietyV26'),'client timeout closes an unanswered puzzle and cancels its server lock')
 local disconnected=car();onPrompt(player,disconnected);muteTap=true;advance(13.1);muteTap=false
 check(disconnected:GetAttribute('State')=='available'and not player:GetAttribute('HackActive'),'server lease releases a client that stopped sending puzzle heartbeats')
 local hidden=car();onPrompt(player,hidden);ui:FindFirstChild('HackVarietyV26'):Destroy()
 check(hidden:GetAttribute('State')=='available'and not player:GetAttribute('HackActive'),'destroying the actual GUI cancels its server session without a hidden lock')

 closeClient();musicGui:Destroy();if addedAudio then audioRemote:Destroy()end;ui:Destroy();for _,c in ipairs(cars)do c:Destroy()end;character:Destroy()
 player.Character=previousCharacter;workspace.GetServerTimeNow=previousTimer;Players.GetPlayers=previousPlayers
 for _,name in ipairs(names)do modules[name]=saved[name]end
 task.spawn,task.wait,task.delay,testClock=oldSpawn,oldWait,oldDelay,oldClock
end
print('PASS: real client/server pins, memory, wires and dial; lost commands and terminal outcomes, deduplication, rig/helper failures, timeout/lease/GUI cleanup; NPC cleanup contracts and bounded siren')
