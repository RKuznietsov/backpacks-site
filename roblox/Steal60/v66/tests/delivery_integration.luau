-- Executes actual Main startup + DeliveryService polling + HeistService XP/rewards,
-- TutorialService transitions and SalonService.openCar loot logic. World rendering,
-- native seating/physics, persistence IO and unrelated service initialization are explicit doubles.
do
 local previousPlayers=Players.GetPlayers
 local previousSpawn,previousWait=task.spawn,task.wait
 local pending={};local now=1000;testClock=now
 local function resume(co,...)
  local ok,delay=coroutine.resume(co,...);assert(ok,delay)
  if coroutine.status(co)~='dead'then pending[#pending+1]={co=co,at=now+(delay or 0)}end
 end
 task.spawn=function(fn,...)local co=coroutine.create(fn);resume(co,...);return co end
 task.wait=function(delay)return coroutine.yield(delay or .01)end
 local function advance(seconds)
  local untilTime=now+seconds
  for _=1,10000 do
   local pick;for index,item in ipairs(pending)do if item.at<=untilTime and(not pick or item.at<pending[pick].at)then pick=index end end
   if not pick then now=untilTime;testClock=now;return end
   local item=table.remove(pending,pick);now=item.at;testClock=now;resume(item.co)
  end
  error('integration scheduler did not settle')
 end
 function Players:GetPlayers()return {}end
 local net={init=function()end};local notices={};local lootEvents={};local tutorialEvents={}
 net.notify=function(actor,text,kind)notices[#notices+1]={actor=actor,text=text,kind=kind}end
 net.LootReveal={FireClient=function(_,actor,payload)lootEvents[#lootEvents+1]={actor=actor,payload=payload}end}
 net.TutorialUpdate={FireClient=function(_,actor,payload)tutorialEvents[#tutorialEvents+1]={actor=actor,payload=payload}end}
 local profiles={};local data={init=function()end}
 data.get=function(actor)return profiles[actor]end
 data.onLoaded=function(actor,fn)if profiles[actor]then fn(profiles[actor])end end
 data.canSave=function()return false end
 data.saveNow=function()return true end
 data.requestSave=function()end
 data.addMoney=function(actor,amount)profiles[actor].money+=amount;return true end
 attachActualCatalog(data)
 local drive={init=function()end,disable=function(car)car:SetAttribute('DriveDisabled',true)end,
  validatePosition=function(car,actor)return car:GetAttribute('DriverId')==actor.UserId and not car:GetAttribute('RejectDrive')end}
 local recycled=0
 local parking={init=function()end,recycle=function(car)
  recycled+=1
  for actor in pairs(profiles)do local hum=actor.Character and actor.Character:FindFirstChildOfClass('Humanoid');if hum and hum.SeatPart and hum.SeatPart:IsDescendantOf(car)then hum.SeatPart=nil end end
  car.Parent=nil
 end}
 local monetary={init=function()end,has=function()return false end,vipCoinBonus=function()return 0 end,vipXPMultiplier=function()return 1 end}
 local security={teleport=function(actor,cf)actor.Character:PivotTo(cf);return true end}
 local names={'Net','DriveService','CollisionService','DataService','LanguageService','TutorialService','MonetizationService','TrackBuilder','SeasonLeaderboardService','StreetLifeService','DistrictManager','ParkingService','OwnerService','PoliceService','DeliveryService','RoadEventService','RoadChallengeService','HeistService','SalonService','UpgradeService','CosmeticService','HackService','SecurityService'}
 local saved={};for _,name in ipairs(names)do saved[name]=modules[name];modules[name]={init=function()end}end
 modules.Net=net;modules.DataService=data;modules.DriveService=drive;modules.ParkingService=parking;modules.MonetizationService=monetary;modules.SecurityService=security
 modules.RoadChallengeService={init=function()end,onDelivered=function()return 0,''end}
 modules.HeistService=nil;modules.TutorialService=nil;modules.DeliveryService=nil
 local heists=require('HeistService');local tutorial=require('TutorialService');local delivery=require('DeliveryService')
 -- We call the real tutorial event/sync/loot methods without unrelated join listeners.
 tutorial.init=function()end
 modules.SalonService=makeActualSalon(data,tutorial,net)
 local storage=Instance.new('Folder');storage.Name='ServerStorage';services.ServerStorage=storage
 local templates=Instance.new('Folder');templates.Name='ClientTemplates';templates.Parent=storage
 local client=Instance.new('LocalScript');client.Name='ClientMain';client.Parent=templates
 local serverScripts=Instance.new('Folder');serverScripts.Name='ServerScriptService'
 serviceFolder.Parent=serverScripts
 refs.Main.Parent=serverScripts
 for _,name in ipairs(names)do if not refs[name]then moduleRef(name,serviceFolder)end end
 game.ReplicatedStorage=services.ReplicatedStorage
 loaders.Main() -- THE ACTUAL FINAL XML MAIN: must register its delivery callback.
 local function actor()
  local who=Instance.new('Player');who.Name='DeliveryRegression';who.UserId=9001;who.Parent=Players
  local char=Instance.new('Model');char.Parent=workspace;who.Character=char
  local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(100,4,25);root.Parent=char
  local hum=Instance.new('Humanoid');hum.Health=100;hum.Parent=char
  profiles[who]={money=0,diamonds=0,hackLevel=1,hackXP=0,botUnlocked=false,upgrades={},coinUpgrades={},catalog={},showcase={recent={},pinned={}},shelf={},shelfStorage={},shelfCapacity=12,lootCopies={},lootRanks={},dailyHeists={},theftParts={},accessoryOrder={},cosmeticsOwned={},cosmeticsEquipped={}}
  modules.SalonService.attach(who)
  tutorial.event(who,'hack_started');tutorial.event(who,'hack_success')
  check(who:GetAttribute('TutorialStep')=='delivery','fixture begins at the reported stuck delivery lesson')
  return who,hum
 end
 local who,hum=actor();local profile=profiles[who]
 local chosen=require('Cars').ById.rusty_hatch;local variant=require('Cars').Variants[1].id
 local function carFor(owner)
  local car=Instance.new('Model');car.WorldPivot=CF.new(450,1,25);car.Parent=workspace
  local body=Instance.new('Part');body.Name='Body';body.Size=V.new(8,2,4);body.Position=V.new(450,1,25);body.AssemblyLinearVelocity=V.zero;body.Parent=car;car.PrimaryPart=body
  local seat=Instance.new('VehicleSeat');seat.Parent=car
  car:SetAttribute('DriverId',owner.UserId);car:SetAttribute('ArcadeSpeed',0);car:SetAttribute('MaxSpeed',42)
  return car,seat
 end
 delivery.setDestination(who,V.new(100,0,25),1,1)
 for trip=1,4 do
  local car,seat=carFor(who)
  delivery.track(car,who,{carId=chosen.id,classId='junk',rarity='common',variantId=variant,lockQuality=1})
  who:SetAttribute('HeistCarrying',true)
  if trip%2==1 then seat.Occupant=hum;hum.SeatPart=seat else hum.SeatPart=nil end
  car:PivotTo(CF.new(100,1,25))
  local moneyBefore=profile.money;local catalogBefore=profile.catalog[chosen.id]and profile.catalog[chosen.id].count or 0
  advance(8)
  check(car.Parent==nil,'server removes the delivered car')
  check(profile.money>moneyBefore,'delivered car credits money after recycle')
  check(profile.catalog[chosen.id]and profile.catalog[chosen.id].count==catalogBefore+1,'delivery updates catalog exactly once')
  check(#lootEvents==trip and #lootEvents[trip].payload.items>=2,'actual loot function reveals shelf items')
  check(profile.botUnlocked and who:GetAttribute('HelperUnlocked'),'first delivery unlocks helper')
  check(profile.tutorialV2.done.delivery and who:GetAttribute('TutorialStep')~='delivery','actual tutorial leaves delivery step')
  check(delivery.getCarrying(who)==nil and who:GetAttribute('HeistCarrying')==false,'carrying state clears')
  check(profile.hackXP>0 or profile.hackLevel>1,'actual heist handler grants XP')
  local count=profile.catalog[chosen.id].count;local money=profile.money
  advance(1)
  check(profile.catalog[chosen.id].count==count and profile.money==money,'same recycled vehicle cannot grant twice')
 end
 check(profile.hackLevel==2,'four precise starter deliveries reach level 2 with current XP formula')
 check(require('TutorialProgress').owns(profile,'tree_fresh'),'actual tutorial loot override places its required item')
 -- Rejection paths stay intact: nobody receives rewards merely for deleting/parking any car.
 local catalogCount=profile.catalog[chosen.id].count;local money=profile.money;local lootCount=#lootEvents
 for _,reason in ipairs({'outside','too_fast','too_soon','unverified','foreign_bay','untracked'})do
  local car,seat=carFor(who);hum.SeatPart=nil
  if reason~='untracked'then delivery.track(car,who,{carId=chosen.id,classId='junk',rarity='common',variantId=variant,lockQuality=1})end
  local x=reason=='outside'and 130 or 100
  if reason=='foreign_bay'then x=200 end
  car:PivotTo(CF.new(x,1,25))
  if reason=='too_fast'then car:FindFirstChild('Body').AssemblyLinearVelocity=V.new(8,0,0)end
  if reason=='unverified'then car:SetAttribute('RejectDrive',true)end
  advance(reason=='too_soon'and 1 or 8)
  check(profile.money==money and profile.catalog[chosen.id].count==catalogCount and #lootEvents==lootCount,'invalid delivery rejected: '..reason)
  if reason=='untracked'then car.Parent=nil else car:SetAttribute('RejectDrive',true);car.Parent=nil;advance(.3)end
 end
 print('PASS: actual Main + DeliveryService + HeistService + TutorialService + loot/catalog logic: four deliveries (seated and exited), rewards, XP/level, shelves, helper, lesson, replay and invalid-delivery rejection')
 for _,name in ipairs(names)do modules[name]=saved[name]end
 task.spawn,task.wait=previousSpawn,previousWait;Players.GetPlayers=previousPlayers;testClock=nil
end
