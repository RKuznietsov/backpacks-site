-- Final request: meaningful coin access, paced mastery and ground pets clear of the driver's head.
local Config=require('CosmeticConfig');local Balance=require('EconomyBalance')
check(Config.List[1].id==Config.COIN_HERO_ID and Config.List[1].priceCoins==4000000,'worker is the first item and costs four million coins')
local counts={hero=0,paint=0,aura=0}
for _,def in ipairs(Config.List)do if def.priceCoins then
 check(def.price==nil and def.currency=='coins','new coin appearances have no accidental diamond purchase')
 if counts[def.category]then counts[def.category]+=1 end
end end
check(counts.hero==1 and counts.paint==1 and counts.aura==1,'exactly one new coin hero, car color and aura')
local worker=Config.ById[Config.COIN_HERO_ID]
check(not worker.hiddenFromShop and worker.catalogLook=='worker'and Config.CatalogOrder[1]=='worker','worker stays visible and is loaded first')
check(Config.PET_LICENSE_COINS==5000000 and Config.PET_LICENSE_DIAMONDS==240,'license no longer costs only eighteen thousand; diamond option retained')
local petNine=0
for _,category in ipairs({'hero','pet'})do
 local maximum=category=='hero'and Config.HERO_MAX or Config.PET_MAX;local previous=0
 for level=0,maximum-1 do local cost=Balance.masteryCost(category,level)
  check(cost>previous,'mastery prices rise at every level');previous=cost
  if category=='pet'and level<9 then petNine+=cost end
 end
 check(Balance.masteryCost(category,maximum)==nil and Balance.masteryCost(category,0/0)==nil and Balance.masteryCost(category,1.5)==nil,'mastery cap and malformed level rejected')
end
check(petNine==1999998 and petNine/500000>3.9,'nine pet points cost approximately four hours at constant 500k/hour')
check(Balance.masteryCost('pet',0)==75000 and Balance.masteryCost('pet',59)==8802083,'pet curve has deliberate early and attainable late price endpoints')
-- The coin worker uses the exact same shared mastery as purchased diamond appearances.
local profile={cosmeticsOwned={[worker.id]=true},cosmeticsEquipped={hero=worker.id},heroSkinBonusLevel=9}
local total,hero,pet=Config.coinBonusPct(profile)
check(total==9 and hero==9 and pet==0,'worker unlocks full shared hero mastery without diamonds')
-- Shoulder placement must also work on R6 and the root-only loading fallback.
for _,shape in ipairs({{name='UpperTorso',size=V.new(2,1.6,1)},{name='Torso',size=V.new(2,2,1)},{name='HumanoidRootPart',size=V.new(2,2,1)}})do
 local character=Instance.new('Model');local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Size=V.new(2,2,1);root.Parent=character
 local host=root
 if shape.name~='HumanoidRootPart'then host=Instance.new('Part');host.Name=shape.name;host.Size=shape.size;host.Parent=character end
 local Visuals=require('AuraVisualLibrary');local aura=Visuals.create(root,Config.ById.aura_breeze_coin_v66)
 check(aura:GetAttribute('EmitterCount')==0 and not aura:FindFirstChild('AuraSpecialGeometry'),'coin wind uses no particle cloud or special geometry')
 local trails={};local attachments=0
 for _,o in ipairs(character:GetDescendants())do
  if o:IsA('Attachment')then
   attachments+=1
   check(o.Parent==host and o.Position.Y>host.Size.Y*.25 and math.abs(o.Position.X)>host.Size.X*.5 and math.abs(o.Position.Z)<host.Size.Z*.5,'breeze originates beside upper shoulders, clear of waist and rear center')
  elseif o:IsA('Trail')then
   trails[#trails+1]=o
   check(o.LightEmission==0 and o.Lifetime<.3 and o.MaxLength<=3,'wind fades quickly as a narrow short stroke')
   o.Clear=function(self)self:SetAttribute('TestClears',(self:GetAttribute('TestClears')or 0)+1)end
  elseif o:IsA('ParticleEmitter')then error('coin wind unexpectedly creates a particle plume')end
 end
 check(#trails==2 and attachments==4,'left and right shoulder trails have complete attachment pairs')
 Visuals.step(root,0);root.Position=V.new(.4,0,0);Visuals.step(root,.1)
 for _,trail in ipairs(trails)do check(trail.Enabled,'wind appears while the character moves')end
 Visuals.step(root,.2)
 for _,trail in ipairs(trails)do check(not trail.Enabled,'wind stops when the character is still')end
 root.Position=V.new(100,0,0);Visuals.step(root,.3)
 for _,trail in ipairs(trails)do check(not trail.Enabled and trail:GetAttribute('TestClears')==1,'teleport clears long streaks')end
 local replacement=Visuals.create(root,Config.ById.aura_breeze_coin_v66)
 check(aura.Parent==nil and #host:GetChildren()==(host==root and 5 or 4),'re-equipping removes old shoulder attachments')
 replacement:Destroy();check(#host:GetChildren()==0 and #root:GetChildren()==0,'unequip removes the effect and all shoulder anchors');character:Destroy()
end
-- Native pet constructors establish geometry; no rendered head or actual seating is emulated.
do
 local pets={};local visuals=require('PetVisualLibrary');local Mount=require('PetMount')
 for _,def in ipairs(Config.List)do if def.category=='pet'and def.movement=='ground'then
  local model=visuals.create(def);local furthest= -math.huge
  for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')and p.Transparency<1 then
   for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
    local point=p.CFrame:PointToWorldSpace(p.Size*.5*V.new(x,y,z));furthest=math.max(furthest,-point.Z)
   end end end
  end end
  pets[#pets+1]={model=model,forward=furthest}
 end end
 check(#pets>=5,'test covers all registered walking pets')
 local classes=require('CarClasses');local tuning=require('CarTuning')
 for _,carDef in ipairs(require('Cars'))do
  local car=require('CarVisualLibrary').build(carDef,classes[carDef.class]);local body=car:FindFirstChild('Body',true)
  for _,fitted in ipairs({false,true})do
   if fitted then tuning.apply(car,{tune_spoiler=true,tune_roofscoop=true,tune_hood=true})end
   for _,pet in ipairs(pets)do
    local frame=Mount.frame(car,body,pet.model:GetAttribute('PetGroundOffset'),false)
    local at=body.CFrame:PointToObjectSpace(frame.Position)
    check(at.X+pet.forward< -body.Size.X*.06-.65,'walking pet geometry is behind the driver head footprint: '..carDef.id)
    local x,y=Mount.support(car,body,false)
    check(math.abs(at.Y-pet.model:GetAttribute('PetGroundOffset')-y-.18)<.001,'pet feet sit above actual rear support/tuning')
   end
  end
  car:Destroy()
 end
 for _,pet in ipairs(pets)do pet.model:Destroy()end
end
print('PASS: coin cosmetics, quadratic mastery pacing, modest aura and all walking pet bounds behind the driver on 150 cars with/without tuning')
-- Execute the WHOLE CosmeticService and real remote action handler; external visuals/IO are doubles.
do
 local names={'CosmeticService','DataService','Net','CarFactory','WardrobeService','CarPreviewService'};local saved={}
 for _,name in ipairs(names)do saved[name]=modules[name]end
 local oldSpawn,oldPlayers,oldClock=task.spawn,Players.GetPlayers,testClock
 task.spawn=function()end;function Players:GetPlayers()return {}end;testClock=10000
 local event=signal();local profiles={};local saves={};local notices={};local wardrobeReady=true
 local data={get=function(actor)return profiles[actor]end,canSave=function()return true end,requestSave=function()end,onLoaded=function()end,
  spendMoney=function(actor,cost)local d=profiles[actor];if d.money<cost then return false end;d.money-=cost;return true end,
  spendDiamonds=function(actor,cost)local d=profiles[actor];if d.diamonds<cost then return false end;d.diamonds-=cost;return true end,
  saveNow=function(actor)saves[#saves+1]=deepCopy(profiles[actor]);return true end}
 modules.DataService=data;modules.Net={CosmeticAction={OnServerEvent=event},notify=function(_,text)notices[#notices+1]=text end,CosmeticUpdate={FireClient=function()end},CurrencyUpdate={FireClient=function()end}}
 modules.CarFactory={getLiveCars=function()return {}end}
 modules.WardrobeService={init=function()end,isReady=function()return wardrobeReady end,request=function()end}
 modules.CarPreviewService={clear=function()end}
 modules.CosmeticService=nil;require('CosmeticService').init()
 local actor=Instance.new('Player');actor.UserId=6601;actor.Parent=Players
 profiles[actor]={money=20000000,diamonds=1000,cosmeticsOwned={},cosmeticsEquipped={},carCosmetics={},catalog={rusty_hatch={count=1}},heroSkinBonusLevel=0,petBonusLevel=0}
 local d=profiles[actor]
 local function act(action,category,id,carId)testClock+=.3;event:Fire(actor,action,category,id,carId)end
 wardrobeReady=false;act('buyCoins','hero',worker.id)
 check(d.money==20000000 and not d.cosmeticsOwned[worker.id],'unloaded worker cannot be bought even with sufficient coins');wardrobeReady=true
 act('buyDiamonds','hero',worker.id)
 check(d.diamonds==1000 and not d.cosmeticsOwned[worker.id],'coin-only worker rejects diamond action')
 act('buyCoins','hero',worker.id)
 check(d.money==16000000 and d.cosmeticsOwned[worker.id]and d.cosmeticsEquipped.hero==worker.id,'real handler charges exact worker price and equips once')
 check(saves[#saves].money==16000000 and saves[#saves].cosmeticsOwned[worker.id],'coin debit and worker ownership saved together immediately')
 act('buyCoins','hero',worker.id);check(d.money==16000000,'repeat worker purchase cannot charge twice')
 act('upgradeHeroCoins','hero');check(d.heroSkinBonusLevel==1 and d.money==15900000,'coin worker can upgrade hero skill without owning a diamond skin')
 act('buyCoins','paint','paint_workgray_coin_v66','rusty_hatch')
 check(d.money==15150000 and d.carCosmetics.rusty_hatch.paint=='paint_workgray_coin_v66','coin paint is charged and applied to the owned car')
 act('buyCoins','aura','aura_breeze_coin_v66')
 check(d.money==13650000 and d.cosmeticsEquipped.aura=='aura_breeze_coin_v66','coin aura purchase equips its separate item')
 act('unlockPetCoins','pet','pet_dog')
 check(d.money==8650000 and d.petUnlocked and d.cosmeticsOwned.pet_fox and d.cosmeticsOwned.pet_bot,'five million license still grants every free appearance')
 local before=d.money
 for _=1,9 do act('upgradePetCoins','pet')end
 check(d.petBonusLevel==9 and before-d.money==petNine,'actual nine pet upgrades use the new paced curve')
 local last=d.money;act('upgradePetCoins','pet');event:Fire(actor,'upgradePetCoins','pet')
 check(d.petBonusLevel==10 and last-d.money==Config.petUpgradeCoins(9),'immediate duplicate upgrade is rate-limited')
 local saveCount=#saves;d.money=0;act('upgradePetCoins','pet')
 check(#saves==saveCount and d.petBonusLevel==10,'insufficient balance cannot grant a free mastery level')
 check(d.diamonds==1000,'all coin purchases and mastery leave diamonds intact')
 actor:Destroy();local folder=workspace:FindFirstChild('Steal60CosmeticPets');if folder then folder:Destroy()end
 for _,name in ipairs(names)do modules[name]=saved[name]end
 task.spawn,Players.GetPlayers,testClock=oldSpawn,oldPlayers,oldClock
end
print('PASS: real CosmeticService purchases/save snapshots, coin-only rejection, worker skill, paint/aura equip, license, mastery costs and duplicate/insufficient-funds guards')
local Text=require('TextTranslator')
local effectText='Сейчас: Бонус монет +9 п.п. · Доход в час: 500 000 $\nДалее: Бонус монет +10 п.п. · Доход в час: 504 587 $'
local english=Text.translate(effectText,'en')
check(english:find('Current:',1,true)and english:find('Next:',1,true)and not english:find('[\208\209]'),'new composite mastery income row translates its nested metrics')
