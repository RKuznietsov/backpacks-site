local Bonus=require('DeliveryBonus');local Policy=require('EndlessParking');local Req=require('HackRequirements')
for coins=0,12 do for gems=0,8 do
 local data={coinUpgrades={botSpeed=coins},upgrades={botSpeed=gems,secondBot=1}}
 check(Bonus.points(data,'common')==3*coins+4*gems,'additive common delivery')
 for _,rarity in ipairs({'rare','epic','legendary'})do check(Bonus.points(data,rarity)==3*coins+4*gems+15,'rare delivery secondBot')end
end end
local Cars=require('Cars');local Classes=require('CarClasses')
for level=1,150 do
 local class,index=Policy.classFor(level)
 check(Classes[class].requiredHack<=level,'class must be unlocked')
 if index<5 then check(Policy.Min[index+1]>level,'must use highest unlocked class')end
 check(Policy.challenge(level)==math.max(31,level+1),'hard car level')
 check(not Req.canHack({hackLevel=level},Policy.challenge(level)),'hard car cannot bypass skill')
 local choices=0
 for _,car in ipairs(Cars.ByClass[class])do if Req.get(index,car,'common')<=level then choices+=1 end end
 check(choices>0,'at least one eligible ordinary car')
end
check(not Req.canHack({hackLevel=0/0},1),'NaN skill rejected')
check(not Req.canHack({hackLevel=math.huge},1),'infinite skill rejected')
local Reset=require('StudioTestProfile')
local function resetFixture()
 return {diamonds=777,hackLevel=42,hackXP=19,processedReceipts={receipt=true},receiptDiamondTotal=900,money=999,till=444,upgrades={secondBot=1},coinUpgrades={income=3},catalog={foo={count=1}},shelf={{id='radio_old'}},shelfStorage={{id='radio_fm'}},cosmeticsOwned={hero=true},cosmeticsEquipped={pet='pet_dog'},carCosmetics={foo={}},petUnlocked=true,language='en',musicVolume=.65,musicMuted=true,settings={foo='kept'},tutorialV2={done={start=true}}}
end
local data=resetFixture()
check(not Reset.reset(data,player,false),'no published reset');check(data.money==999,'published state unchanged')
check(not Reset.reset(data,{Name='AnotherPlayer'},true),'other Studio accounts untouched')
check(Reset.reset(data,player,true),'personal Studio reset applied')
for _,key in ipairs({'upgrades','coinUpgrades','catalog','shelf','shelfStorage','cosmeticsOwned','cosmeticsEquipped','carCosmetics','tutorialV2'})do
 if key~='upgrades'then check(next(data[key])==nil,'reset '..key)end
end
check(data.money==0 and data.till==0 and not data.petUnlocked and not data.botUnlocked,'progress cleared')
check(data.diamonds==777 and data.hackLevel==42 and data.hackXP==19,'gems and hacking preserved')
check(data.processedReceipts.receipt and data.receiptDiamondTotal==900,'receipt ledger retained')
check(data.language=='en'and data.musicVolume==.65 and data.musicMuted and data.settings.foo=='kept','settings preserved')
data.money=23;check(not Reset.reset(data,player,true)and data.money==23,'one-time reset')
print('PASS: purchase compatibility, delivery effects, skill policy, personal reset')
local Layout=require('TrackLayout');local themes={}
for index=1,10000 do
 check(Layout.indexAt(Layout.districtStart(index)+10)==index,'infinite district numbering')
 check(Layout.indexAt(Layout.intersectionStart(index))==index,'intersection numbering')
 local theme=Layout.themeIndex(index);check(theme>=1 and theme<=5,'existing themes only');themes[theme]=true
end
for i=1,5 do check(themes[i],'all themes appear')end
check(Layout.trackEnd()==math.huge,'no terminal cap')
print('PASS: 10,000 district indices and five-theme selection')
local Text=require('TextTranslator')
local effect='Сейчас: Доставка +7 п.п.; редкая+ +22 п.п. · Доход в час: 300 $\nДалее: Доставка +10 п.п.; редкая+ +25 п.п. · Доход в час: 300 $'
local english=Text.translate(effect,'en')
check(not english:find('Доставка',1,true)and not english:find('Доход',1,true),'formatted effect sub-lines translated')
check(english:find('Current:',1,true)and english:find('Next:',1,true),'effect prefixes translated')
for _,deferred in ipairs({false,true})do
 deferSignals=deferred
 local menu=Instance.new('TextLabel');menu.Name='OpenMenu';menu.Text='МЕНЮ';menu.Parent=gui
 local prompt=Instance.new('ProximityPrompt');prompt.ActionText='Начать первый угон';prompt.ObjectText='Piko 90 · учебная машина';prompt.Parent=workspace
 require('LanguageController').start(gui);flush()
 for i=1,100 do
  player:SetAttribute('Steal60Language',i%2==1 and'en'or'ru');flush()
  check(menu.Text==(i%2==1 and Text.translate('МЕНЮ','en')or'МЕНЮ'),'repeat language toggle menu')
  check(prompt.ActionText==(i%2==1 and Text.translate('Начать первый угон','en')or'Начать первый угон'),'prompt language')
 end
 player:SetAttribute('Steal60Language','en');flush()
 menu.Text='Громкость музыки: 65%';flush()
 check(menu.Text=='Music volume: 65%','external dynamic menu update')
 local streamed=Instance.new('TextLabel');streamed.Text='В разработке';streamed.Parent=workspace;flush()
 check(streamed.Text=='In development','streamed district translation')
 -- Deferred self-write still pending when locale switches again.
 player:SetAttribute('Steal60Language','ru');player:SetAttribute('Steal60Language','en');flush()
 player:SetAttribute('Steal60Language','ru');flush()
 check(menu.Text=='Громкость музыки: 65%'and streamed.Text=='В разработке','canonical source survives deferred callbacks')
 streamed:Destroy();prompt:Destroy();menu:Destroy();gui:Destroy();flush()
 gui=Instance.new('ScreenGui');gui.Parent=playerGui
end
deferSignals=false
print('PASS: RU/EN immediate + deferred events, dynamic text, streamed prompts/signs')
-- Every actual car constructor and tuning set runs with matrix-aware native-Part test doubles.
local Visuals=require('CarVisualLibrary');local Tuning=require('CarTuning');local Mount=require('PetMount')
local carCount=0
for _,def in ipairs(Cars)do
 local car=Visuals.build(def,Classes[def.class]);local body=car:FindFirstChild('Body',true)
 check(body~=nil,'car physics root retained')
 for _,part in ipairs(car:GetDescendants())do if part:IsA('BasePart')then
  check(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0,'positive car geometry')
  check(part.Position.X==part.Position.X and part.Position.Y==part.Position.Y and part.Position.Z==part.Position.Z,'finite car position')
  for _,entry in ipairs(part.CFrame.r)do check(entry==entry and math.abs(entry)<=1.00001,'finite car rotation')end
 end end
 local base=Mount.frame(car,body,.92,false)
 local selection={tune_spoiler=true,tune_roofscoop=true,tune_exhaust=true,tune_wheels=true,tune_skirts=true,tune_mirrors=true,tune_hood=true,tune_bumper=true,tune_diffuser=true,tune_neon=true}
 Tuning.apply(car,selection)
 local tuned=Mount.frame(car,body,.92,false)
 check(tuned.Position.Y>=base.Position.Y-.001,'pet clears tuned roof')
 local x,y=Mount.support(car,body);local world=body.CFrame:PointToWorldSpace(V.new(x,y+.92+.18,0))
 check((world-tuned.Position).Magnitude<.00001,'pet support frame')
 car:PivotTo(CF.new(2400,0,0)*CF.Angles(0,1.3,0))
 local moved=Mount.frame(car,body,.92,false)
 check(moved.Position.X>2300,'mount follows car position and yaw')
 Tuning.clear(car);Mount.frame(car,body,.92,true)
 car:Destroy();carCount+=1
end
print('PASS: '..carCount..' catalog car models, tuning, roof pet mounting')
local Builder=require('DistrictBuilder');local signatures={};local built=0
for _,index in ipairs({1,2,3,4,5,6,7,8,9,10,25,100,1000,10000})do
 local district=Builder.build(index)
 check(district:GetAttribute('LayoutAuditPassed')==true,'district parcel audit')
 check(district:GetAttribute('LayoutAuditParcels')>0,'real parcels audited')
 check(not district:FindFirstChild('EndWall',true),'no final wall')
 check(#district:FindFirstChild('ParkSlots'):GetChildren()==8,'eight parking slots')
 -- Independent AABB check on actual geometry of different registered large models.
 local parcels={}
 for _,model in ipairs(district:GetDescendants())do if model:GetAttribute('FootprintSize')then
  local lo=V.new(math.huge,math.huge,math.huge);local hi=V.new(-math.huge,-math.huge,-math.huge)
  for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')then
   for _,sx in ipairs({-1,1})do for _,sy in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
    local point=p.CFrame:PointToWorldSpace(p.Size*V.new(sx,sy,sz)*.5)
    lo=V.new(math.min(lo.X,point.X),math.min(lo.Y,point.Y),math.min(lo.Z,point.Z));hi=V.new(math.max(hi.X,point.X),math.max(hi.Y,point.Y),math.max(hi.Z,point.Z))
   end end end
  end end
  parcels[#parcels+1]={lo=lo,hi=hi,name=model.Name}
 end end
 for a=1,#parcels do for b=a+1,#parcels do local p,q=parcels[a],parcels[b]
  check(p.hi.X<=q.lo.X or q.hi.X<=p.lo.X or p.hi.Z<=q.lo.Z or q.hi.Z<=p.lo.Z,'large geometry intersection: '..index..' '..p.name..' / '..q.name)
 end end
 if index<=5 then local names={};for _,p in ipairs(district:GetDescendants())do if p:IsA('BasePart')then names[p.Name]=true end end;local list={};for n in pairs(names)do list[#list+1]=n end;table.sort(list);signatures[index]=table.concat(list,'|')end
 district:Destroy();built+=1
end
for i=1,5 do for j=i+1,5 do check(signatures[i]~=signatures[j],'distinct theme model signatures')end end
print('PASS: '..built..' constructed districts; reserved parcels + independent large-object AABBs')
local Roadside=require('RoadsideArt')
for _,kind in ipairs({'police','repair'})do
 local root=Instance.new('Model');Roadside.decorate(root,kind,100,1)
 check(root:FindFirstChild(kind=='police'and'TrafficOfficer'or'RoadWorker',true)~=nil,'dressed roadside person')
 if kind=='police'then check(root:FindFirstChild('TrafficBatonStripe',true)~=nil,'traffic baton');check(root:FindFirstChild('RedLight',true)~=nil,'detailed patrol car')
 else check(root:FindFirstChild('SteelDrum',true)~=nil,'road roller');check(root:FindFirstChild('OpenAsphaltBed',true)~=nil,'repair surface')end
 root:Destroy()
end
print('PASS: separate police and roadworks native model constructors')
local Store=require('ProfileStore');local defaults={money=0,diamonds=0,hackLevel=1,hackXP=0,processedReceipts={},upgrades={},catalog={}}
local p=Instance.new('Player');p.UserId=700;p.Parent=Players
local store=Store.new('V66Test',defaults);local profile=store:load(p)
check(profile~=nil,'fresh profile load')
local function purchase()return store:commit(p,profile,{receipt='receipt-1',apply=function(after)after.diamonds+=300 end})end
check(purchase(),'receipt commit');check(profile.diamonds==300,'receipt granted once')
check(purchase(),'receipt replay commit');check(profile.diamonds==300,'duplicate receipt not granted twice')
profile.money=123;check(store:commit(p,profile),'save gameplay state')
failStores.V66Test=true
check(not store:commit(p,profile),'unavailable datastore fails closed');check(profile.money==123,'live progress not reset on failed save')
failStores.V66Test=nil
check(store:commit(p,profile,{release=true}),'release lease')
dataStores.V66Test.Player_700={data={money=-500},revision=100}
local recovered=Store.new('V66Test',defaults);local recoveredData=recovered:load(p)
check(recoveredData and recoveredData.money==123 and recoveredData.diamonds==300,'recovery restores valid backup and receipts')
dataStores.V66Test.Player_700.lock.token='someone-else'
check(not recovered:commit(p,recoveredData),'lost lease write rejected');check(recovered:blocked(p),'lost lease blocks gameplay')
check(not Store.valid({money=0/0})and not Store.valid({diamonds=-1}),'invalid profiles rejected')
print('PASS: profile recovery, payment replay idempotency, outage and lease-loss rejection (mock store)')

-- Real DriveService function, evaluated with controlled server positions and assembly properties.
for _,yaw in ipairs({0,math.pi/2,math.pi,-math.pi/2})do
 local forward=CF.Angles(0,yaw,0):VectorToWorldSpace(V.xAxis);local sideways=V.new(-forward.Z,0,forward.X)
 for _,sign in ipairs({-1,1})do
  local cone=Instance.new('Part');cone.Position=forward*6+sideways*sign;cone.Parent=workspace;cone.AssemblyMass=1
  coneCache={cone};knockCones(V.zero,forward*.1,forward,30,6,2.5)
  check(not cone.Anchored,'front bumper launches before body center arrives')
  check(cone.AssemblyLinearVelocity:Dot(forward)>50,'cone launches ahead of driver')
  check(cone.AssemblyLinearVelocity:Dot(sideways)*sign>20,'cone launches outward on either side')
  local sideCone=Instance.new('Part');sideCone.Position=sideways*8;sideCone.Parent=workspace
  coneCache={sideCone};knockCones(V.zero,forward*.1,forward,30,6,2.5)
  check(sideCone.Anchored,'distant side cone cannot be hit')
  cone:Destroy();sideCone:Destroy()
 end
end
local stopped=Instance.new('Part');stopped.Position=V.new(6,0,0);stopped.Parent=workspace
coneCache={stopped};knockCones(V.zero,V.zero,V.xAxis,0,6,2.5);check(stopped.Anchored,'parked cars do not launch cones');stopped:Destroy()
print('PASS: actual server bumper sweep at four headings, both sides, stopped/out-of-range rejection')
local Security=require('SecurityService')
for _,values in ipairs({{.45,false},{0,true},{1,false}})do
 local who=Instance.new('Player');who.Parent=Players
 local handler=Security.wrap('SetAudio',function(_,volume,muted)return volume==values[1]and muted==values[2]end)
 check(handler(who,values[1],values[2])==true,'valid audio preference')
end
for _,values in ipairs({{-1,false},{2,false},{0/0,false},{math.huge,false},{.5,'yes'},{'0.5',false}})do
 local who=Instance.new('Player');who.Parent=Players;local called=false
 Security.wrap('SetAudio',function()called=true end)(who,table.unpack(values))
 check(not called,'malformed audio preference rejected')
end
local who=Instance.new('Player');who.UserId=701;who.Parent=Players;local count=0
local handler=Security.wrap('SetAudio',function()count+=1 end)
for _=1,20 do handler(who,.5,false)end
check(count==3,'audio token bucket caps burst')
print('PASS: real security wrapper accepts bounded audio and rejects malformed/flooded requests')
local audioData={language='en',musicVolume=.65,musicMuted=true};local loaded
local previousData,previousNet=modules.DataService,modules.Net
modules.DataService={get=function()return audioData end,onLoaded=function(_,fn)loaded=fn end,canSave=function()return true end}
local audioEvent=signal();local localeEvent=signal()
modules.Net={SetAudio={OnServerEvent=audioEvent},SetLanguage={OnServerEvent=localeEvent}}
require('LanguageService').init();loaded(audioData)
check(player:GetAttribute('Steal60MusicVolume')==.65 and player:GetAttribute('Steal60MusicMuted')==true,'saved audio restored on load')
audioEvent:Fire(player,.3,false)
check(audioData.musicVolume==.3 and not audioData.musicMuted,'audio change written to persistent profile')
local audioStore=Store.new('V66Audio',defaults);local audioProfile=audioStore:load(who)
audioProfile.musicVolume=audioData.musicVolume;audioProfile.musicMuted=audioData.musicMuted
check(audioStore:commit(who,audioProfile,{release=true}),'audio preference saved')
local reload=Store.new('V66Audio',defaults):load(who)
check(reload.musicVolume==.3 and reload.musicMuted==false,'audio survives profile reload')
modules.DataService,modules.Net=previousData,previousNet
print('PASS: audio preference restore/change/reload through real language service + profile store (mocks)')
local Loot=require('Loot');local Balance=require('EconomyBalance')
local fixture={upgrades={income=2,botSpeed=2,security=2,speed=2,shelves=1},coinUpgrades={income=3,botSpeed=3,security=1,speed=3,shelves=1},shelf={},catalog={}}
for i=1,2500 do fixture.shelf[i]={id=Loot[1].id}end
local function fmt(n)local s=tostring(math.floor(n));return(s:reverse():gsub('(%d%d%d)','%1 '):reverse():gsub('^ ',''))end
local current,following,rate=previewFor(fixture,'income','coin',24)
local base=Loot[1].income*2500
local expected=Balance.income(base,0,2,4,0,0,1)*3600
check(current:find('Бонус базового дохода +18 п.п.',1,true)~=nil,'current coin+diamond total shown')
check(following:find('Бонус базового дохода +22 п.п.',1,true)~=nil,'next combined income bonus')
check(following:find('Доход в час: '..fmt(expected)..' $',1,true)~=nil,'next actual nonlinear income shown')
check(rate==Balance.income(base,0,2,3,0,0,1)*3600,'live and preview income use same formula')
current,following=previewFor(fixture,'doubleIncome','diamond',1)
check(following:find('Доход в час: '..fmt(rate*2)..' $',1,true)~=nil,'x2 purchase preview doubles actual hourly income')
current,following=previewFor(fixture,'botSpeed','coin',12)
check(current:find('Доставка +17 п.п.',1,true)and following:find('Доставка +20 п.п.',1,true),'helper current/next coin preview')
current,following=previewFor(fixture,'botSpeed','diamond',8)
check(following:find('Доставка +21 п.п.',1,true)~=nil,'helper diamond increment')
fixture.upgrades.security=4
current,following=previewFor(fixture,'security','coin',5)
check(current:find('Охрана 5/5',1,true)and following=='Максимум','combined security cap preview')
check(Bonus.points({upgrades={},coinUpgrades={}},'epic',true)==15,'legacy secondBot entitlement retained')
print('PASS: actual server upgrade preview functions, combined effects, nonlinear hourly income and x2')
local originalPlayers=Players.GetPlayers
local root=Instance.new('Part');root.Name='HumanoidRootPart';local character=Instance.new('Model');root.Parent=character;player.Character=character
local step,loaded=lifecycleFor()
for index=6,1005 do
 root.Position=V.new(Layout.districtStart(index)+10,4,0);step()
 local count=0;for i in pairs(loaded)do count+=1;check(math.abs(i-index)<=1,'only adjacent districts remain loaded')end
 check(count==3,'load/unload set remains bounded during 1,000 district crossings')
end
function Players:GetPlayers()return {}end
step();check(next(loaded)==nil,'unused districts unload with no players')
Players.GetPlayers=originalPlayers;player.Character=nil;character:Destroy()
print('PASS: actual district manager needed/load/unload lifecycle for 1,000 crossings (zero-delay test config)')

-- Audit regression: both already-protected expensive remotes remain bounded.
do
 local beforeMovement=Security.movement;Security.movement=function()return true end
 for _,entry in ipairs({{'PinCar',3,'rusty_hatch'},{'GetMenuData',4}})do
  local actor=Instance.new('Player');actor.Parent=Players;actor:SetAttribute('DataLoaded',true);actor:SetAttribute('GameplayReady',true)
  local calls=0;local wrapped=Security.wrap(entry[1],function()calls+=1 end)
  for i=1,30 do if entry[3]then wrapped(actor,entry[3])else wrapped(actor)end end
  check(calls==entry[2],entry[1]..' expensive work limited by token bucket')
 end
 Security.movement=beforeMovement
end
print('PASS: actual PinCar and GetMenuData rate limits')
-- Full marginal bonus value after the cap at low and very high raw income.
for _,raw in ipairs({0,80,9600,10000,100000,1000000,1e10})do
 for _,multiplier in ipairs({1,2,4})do
  local current=Balance.income(raw,.2,4,5,30,20,multiplier)
  local nextDiamond=Balance.income(raw,.2,5,5,30,20,multiplier)
  local nextCoin=Balance.income(raw,.2,4,6,30,20,multiplier)
  local base=Balance.passiveRate(raw)*multiplier
  check(math.abs(nextDiamond-current-base*.03)<1e-7,'diamond bonus not eaten by logarithm')
  check(math.abs(nextCoin-current-base*.04)<1e-7,'coin bonus not eaten by logarithm')
  check(math.abs(Balance.income(raw,.2,4,5,30,20,multiplier*2)-current*2)<1e-7,'honest x2 at all income levels')
 end
end
local Diamond=require('UpgradeConfig');local Coin=require('CoinUpgradeConfig')
local function ladder(config,id)local total=0;local last;for level=0,config.ById[id].max-1 do last=config.cost(id,level);total+=last end;return total,last end
local dTotal,dLast=ladder(Diamond,'income');local cTotal,cLast=ladder(Coin,'income')
check(dTotal==1080 and dLast==193,'rebalanced diamond income ladder')
check(cTotal==6050976 and cLast==2147195,'rebalanced coin income ladder')
check(Diamond.cost('doubleIncome',0)==300,'moderately repriced permanent x2')
local XP=require('ProgressionConfig')
check(XP.needXP(1)==48 and XP.needXP(5)==80 and XP.needXP(6)==98,'smooth early XP curve')
for level=2,150 do check(XP.needXP(level)>XP.needXP(level-1),'XP thresholds monotonic')end
print('PASS: late-income marginal value, exact new prices and early progression')
-- Execute the actual upgrade handlers with controlled persistence results.
do
 local backup={data=modules.DataService,net=modules.Net,salon=modules.SalonService,tutorial=modules.TutorialService,drive=modules.DriveService}
 local profiles={};local saves={};local notices={};local requests=0
 local diamondEvent,coinEvent=signal(),signal()
 modules.DataService={get=function(actor)return profiles[actor]end,canSave=function()return true end,
 spendDiamonds=function(actor,cost)local data=profiles[actor];if data.diamonds<cost then return false end;data.diamonds-=cost;return true end,
 spendMoney=function(actor,cost)local data=profiles[actor];if data.money<cost then return false end;data.money-=cost;return true end,
 saveNow=function(actor)saves[#saves+1]=deepCopy(profiles[actor]);return not actor:GetAttribute('SimulateSaveFailure')end,
 requestSave=function()requests+=1 end}
 modules.Net={BuyUpgrade={OnServerEvent=diamondEvent},BuyCoinUpgrade={OnServerEvent=coinEvent},CurrencyUpdate={FireClient=function()end},notify=function(_,text,kind)notices[#notices+1]={text=text,kind=kind}end}
 modules.SalonService={refresh=function()end};modules.TutorialService={sync=function()end}
 modules.DriveService={maxSpeedFor=function(data)return math.min(84,42+(data.upgrades.speed or 0)*2.5+(data.coinUpgrades.speed or 0))end}
 game.ReplicatedStorage=services.ReplicatedStorage
 require('UpgradeService').init()
 local function actor(failing)
  local value=Instance.new('Player');value.Parent=Players;value:SetAttribute('SimulateSaveFailure',failing)
  profiles[value]={money=100000,diamonds=10000,upgrades={speed=0,income=0,botSpeed=0,security=0,shelves=0},coinUpgrades={}}
  return value
 end
 local a=actor(false);diamondEvent:Fire(a,'speed');coinEvent:Fire(a,'income')
 check(#saves==2,'both currencies save immediately with separate cooldowns')
 check(saves[1].upgrades.speed==1 and saves[1].diamonds==9988,'diamond level and debit persisted together')
 check(saves[2].coinUpgrades.income==1 and saves[2].money==99955,'coin level and debit persisted together')
 for i=1,100 do diamondEvent:Fire(a,'speed');coinEvent:Fire(a,'income')end
 check(#saves==2 and profiles[a].upgrades.speed==1,'upgrade spam blocked')
 local failed=actor(true);diamondEvent:Fire(failed,'income')
 check(profiles[failed].diamonds==9985 and profiles[failed].upgrades.income==1,'uncertain persistence keeps paired debit/level, no unsafe rollback')
 check(requests==1 and notices[#notices].kind=='info','failed immediate save schedules retry without announcing confirmed success')
 local capped=actor(false);profiles[capped].upgrades.speed=12;profiles[capped].coinUpgrades.speed=12
 local before=profiles[capped].diamonds;local previousSaves=#saves
 diamondEvent:Fire(capped,'fastRide');coinEvent:Fire(capped,'speed')
 check(#saves==previousSaves and profiles[capped].diamonds==before,'speed cap prevents useless paid upgrades')
 modules.DataService,modules.Net,modules.SalonService,modules.TutorialService,modules.DriveService=backup.data,backup.net,backup.salon,backup.tutorial,backup.drive
end
print('PASS: real upgrade handlers save immediately, separate cooldowns and paired failure behavior')
local Grammar=require('Grammar')
for _,test in ipairs({{'1 монет','1 монета'},{'2 монет','2 монеты'},{'5 монет','5 монет'},{'11 алмазов','11 алмазов'},{'21 алмазов','21 алмаз'},{'22 алмазов','22 алмаза'},{'111 машин','111 машин'},{'121 машин','121 машина'},{'до 21 монет','до 21 монеты'},{'до 22 монет','до 22 монет'},{'1.5 алмазов','1.5 алмаза'},{'1 001 монет','1 001 монета'},{'Салон','Гараж'},{'ПРОКАЧКА САЛОНА','ПРОКАЧКА ГАРАЖА'}})do
 check(Grammar.russian(test[1])==test[2],'Russian inflection: '..test[1]..' -> '..Grammar.russian(test[1]))
end
for _,test in ipairs({{'1 days','1 day'},{'21 days','21 days'},{'1 cars','1 car'},{'1 items','1 item'},{'1,001 coins','1,001 coins'},{'1 diamonds','1 diamond'},{'1 car thefts','1 car theft'}})do
 check(Grammar.english(test[1])==test[2],'English number inflection: '..test[1]..' -> '..Grammar.english(test[1]))
end
check(Text.translate('ВИП активирован на 1 дн. · +30% монеты за угон · +25% ОПЫТ · касса 48 ч.','en'):find('1 day',1,true)~=nil,'translated VIP singular')
check(Text.translate('Касса','en')=='Register'and Text.translate('Салон','en')=='Garage','consistent register/garage glossary')
print('PASS: Russian inflection, English singulars, American English and unified glossary')
local Access=require('InterfaceAccess')
for _,size in ipairs({{240,240},{320,320},{360,640},{640,360},{1024,768},{1920,1080},{3840,2160}})do
 local width,height=size[1],size[2];local scale=Access.scaleFor(width,height,550,350,24)
 check(550*scale<=width-24+.01 and 350*scale<=height-24+.01,'modal scale fits available viewport')
end
local throttle,steer=Access.axes(.1,1,0);check(throttle==1 and steer==0,'gamepad dead zone')
throttle,steer=Access.axes(-.7,.2,.9);check(math.abs(throttle+.7)<1e-10 and steer==-.7,'analog gamepad throttle and steering')
check(require('Messages').source('recover_stop')~=nil and require('Messages').source('unknown')==nil,'bounded message keys')
print('PASS: adaptive-scale geometry, analog control mapping and notification keys (no hardware rendering)')
local Cosmetics=require('CosmeticConfig')
local license={petUnlocked=true,petBonusLevel=17,cosmeticsOwned={},cosmeticsEquipped={pet='pet_dog'}}
sanitized(license)
local petCount,heroCount,auraCount=0,0,0
for _,def in ipairs(Cosmetics.List)do
 if def.category=='pet'then petCount+=1;check(license.cosmeticsOwned[def.id]==true,'one pet license unlocks every look')
 elseif def.category=='hero'then heroCount+=1;check(not license.cosmeticsOwned[def.id],'hero looks remain separate purchases')
 elseif def.category=='aura'then auraCount+=1 end
end
check(petCount==10 and license.petBonusLevel==17,'all ten looks retain shared paid mastery')
local legacyPet={cosmeticsOwned={pet_dog=true},petBonusLevel=5};sanitized(legacyPet)
check(legacyPet.petUnlocked==true and legacyPet.petBonusLevel==5,'legacy pet purchase migrates to shared license')
print('PASS: actual pet-license sanitization; '..petCount..' pets, '..heroCount..' hero entries, '..auraCount..' auras; separate paid mastery')
print('AUDIT FINAL ASSERTIONS: '..checks)
