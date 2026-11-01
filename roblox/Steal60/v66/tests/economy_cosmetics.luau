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
-- Transparent ribbon wakes and two rising vortices: native geometry/lifecycle, not a rendered image.
for _,shape in ipairs({{name='UpperTorso',size=V.new(2,1.6,1)},{name='Torso',size=V.new(2,2,1)},{name='HumanoidRootPart',size=V.new(2,2,1)}})do
 local character=Instance.new('Model');local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Size=V.new(2,2,1);root.Parent=character
 local host=root
 if shape.name~='HumanoidRootPart'then host=Instance.new('Part');host.Name=shape.name;host.Size=shape.size;host.Parent=character end
 local Visuals=require('AuraVisualLibrary');local aura=Visuals.create(root,Config.ById.aura_breeze_coin_v66)
 local count=#character:GetDescendants();local first=aura:FindFirstChild('WindCurl_-1_1').Attachment0.CFrame.Position
 local shoulder=aura:FindFirstChild('ShoulderWindWake');check(shoulder and math.abs(shoulder.Attachment1.Position.X-shoulder.Attachment0.Position.X)>=2,'wind has the broad shoulder wake silhouette used by the other auras')
 check(shoulder.Transparency.Keypoints[1].Value<=.5 and shoulder.Transparency.Keypoints[2].Value<=.65,'main wake retains at least half initial opacity instead of becoming nearly invisible')
 check(aura:FindFirstChild('WindCurl_-1_1').Width0>=.5 and aura:FindFirstChild('WindCurl_-1_1').Transparency.Keypoints[2].Value<=.55,'wind curls are wider and clearly less faded than the previous effect')
 for _,t in ipairs({0,.5,1,5,10})do
  Visuals.step(root,t)
  local beams,trails=0,0
  for _,o in ipairs(aura:GetChildren())do
   check(not o:IsA('ParticleEmitter'),'wind has no concentrated waist smoke emitter')
   if o:IsA('Beam')then
    beams+=1;check(o.Enabled and o.Segments>=12 and o.LightEmission>=.25 and o.LightEmission<.5 and o.Texture:find('smoke_main',1,true),'wind curls use a visible soft texture at rest')
    for _,key in ipairs(o.Transparency.Keypoints)do check(key.Value>=.44,'wind curls keep a translucent surface')end
    local p0=o.Attachment0.CFrame.Position;local p1=p0+o.Attachment0.CFrame.RightVector*o.CurveSize0
    local p3=o.Attachment1.CFrame.Position;local p2=p3-o.Attachment1.CFrame.RightVector*o.CurveSize1
    for j=0,10 do local f=j/10;local point=p0*(1-f)^3+p1*3*(1-f)^2*f+p2*3*(1-f)*f^2+p3*f^3
     check(point.Y>0 and math.abs(point.X)>host.Size.X*.5+.12,'rising wind curls stay outside the torso, above the waist')
    end
   elseif o:IsA('Trail')then
    trails+=1;check(not o.Enabled and o.Lifetime<=1.2 and o.MaxLength<=22,'wind wake matches other ribbon auras and is disabled at rest')
    check(o.Attachment0.Position.Y>0 and o.Attachment1.Position.Y>0,'wake anchors are at the upper back, not the waist')
    for _,key in ipairs(o.Transparency.Keypoints)do check(key.Value>=.42,'wind wakes remain translucent')end
   end
  end
  check(beams==8 and trails==3 and #character:GetDescendants()==count,'animation keeps a bounded eight-segment/three-ribbon construction')
 end
 check((aura:FindFirstChild('WindCurl_-1_1').Attachment0.CFrame.Position-first).Magnitude>.1,'wind curls animate even without character movement')
 root.Position=V.new(3,0,0);Visuals.step(root,10.1)
 for _,o in ipairs(aura:GetChildren())do if o:IsA('Trail')then check(o.Enabled,'walking leaves a soft wind wake')end end
 root.Position=V.new(300,0,0);Visuals.step(root,10.2)
 for _,o in ipairs(aura:GetChildren())do if o:IsA('Trail')then check(not o.Enabled and o.ClearCount==1,'teleport clears the old ribbon instead of stretching it across the map')end end
 Visuals.create(root,Config.ById.aura_breeze_coin_v66)
 check(aura.Parent==nil,'changing the same aura destroys the old wind effect')
 local replacement=root:FindFirstChild('Steal60CosmeticAura');replacement:Destroy()
 check(#host:GetChildren()==0 and #root:GetChildren()==0,'unequip removes every external wind attachment');character:Destroy()
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
 act('unequip','hero');local total,hero=Config.coinBonusPct(d);check(d.cosmeticsEquipped.hero==nil and total==1 and hero==1,'return to the own Roblox avatar keeps purchased hero mastery active')
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
