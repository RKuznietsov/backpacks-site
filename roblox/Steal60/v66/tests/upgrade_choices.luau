-- Every distinct ordinary benefit supports both currencies, with one card per upgrade type.
local Policy=require('UpgradePolicy');local Coin=require('CoinUpgradeConfig');local Diamond=require('UpgradeConfig');local Cosmetics=require('CosmeticConfig')
for _,def in ipairs(Diamond)do for level=0,def.max-1 do check(Diamond.cost(def.id,level)%5==0,'diamond ladder prices use multiples of five')end end
for _,def in ipairs(Cosmetics.List)do if def.price then check(def.price%5==0,'diamond cosmetic prices use multiples of five')end end
for _,plan in ipairs(require('VIPConfig').Plans)do check(plan.diamonds%5==0,'VIP prices use multiples of five')end
for level=0,11 do check(Diamond.cost('speed',level)==20,'diamond speed is fixed at twenty')end
check(Diamond.cost('autoCollect',0)==300,'autocollect costs three hundred')
for g=0,12 do for c=0,12 do local d={upgrades={speed=g},coinUpgrades={speed=c}}
 check(actualMaxSpeed(d,1)==42+g+c,'real speed function adds one per level')
 check(actualMaxSpeed(d,1.25)==math.min(84,(42+g+c)*1.25),'sport multiplier and hard cap retained')
end end
local profile={cosmeticsOwned={[Cosmetics.COIN_HERO_ID]=true},cosmeticsEquipped={},heroSkinBonusLevel=12}
local total,hero=Cosmetics.coinBonusPct(profile);check(total==12 and hero==12,'hero mastery remains active with the own avatar')
profile.cosmeticsOwned={};check(Cosmetics.coinBonusPct(profile)==0,'unowned hero cannot grant mastery')
-- Exercise real server rows and the real shared UI; double only the 3D thumbnail renderer.
do
 local d={money=1e12,diamonds=1e9,upgrades={},coinUpgrades={},shelfCapacity=12,shelf={},catalog={}}
 local _,_,_,rows=previewFor(d,'income','coin',24);check(#rows==5,'five ordinary upgrade types, no currency duplicates')
 local W=require('MenuWidgets');local original=W.preview;W.preview=function(parent)local image=Instance.new('Frame');image.Parent=parent;return image end
 for _,width in ipairs({320,550,760})do
  local parent=Instance.new('Frame');parent.AbsoluteSize=Vector2.new(width,600);local clicks={}
  require('UpgradeView').render(parent,{dualUpgrades=rows,money=d.money,diamonds=d.diamonds},{choice=function(id,variant,payment)clicks[#clicks+1]={id,variant,payment}end})
  local seen={};local count=0
  for _,card in ipairs(parent:GetChildren())do if card:GetAttribute('UpgradeId')then
   local id=card:GetAttribute('UpgradeId');check(not seen[id],'one illustrated card per type');seen[id]=true;count+=1
   local options=Policy.choices(d,id);local buttons={};for _,child in ipairs(card:GetChildren())do if child:IsA('TextButton')then buttons[#buttons+1]=child end end
   check(#buttons==2*#options,'each distinct benefit has two payment buttons')
   for index,option in ipairs(options)do
    local left,right=buttons[index*2-1],buttons[index*2];local w=width-10
    check(left.Position.Y.Offset==right.Position.Y.Offset and left.Position.X.Offset+left.Size.X.Scale*w+left.Size.X.Offset<right.Position.X.Scale*w+right.Position.X.Offset,'currency buttons are side by side without overlap')
    left.Activated:Fire();right.Activated:Fire()
    check(clicks[#clicks-1][1]==id and clicks[#clicks-1][2]==option.id and clicks[#clicks-1][3]=='coin'and clicks[#clicks][3]=='diamond','buttons preserve benefit choice independently of payment')
   end
  end end
  check(count==5,'income, speed, helper, security and shelves each appear once');parent:Destroy()
 end
 W.preview=original
 d.upgrades={security=1,shelves=2};d.coinUpgrades={security=2,shelves=1};d.shelfCapacity=21
 local _,_,_,rows=previewFor(d,'shelves','coin',4)
 for _,row in ipairs(rows)do
  if row.id=='shelves'then local choice=row.choices[1];check(choice.level==3 and choice.coinCost==10000000 and choice.diamondCost==130,'old mixed shelf levels use the shared next price');check(choice.nextEffect:find('Мест на полках: 24',1,true),'shared shelf preview matches actual next capacity')end
 end
end
-- Real upgrade handler: every variant/currency, shared caps, durable snapshots and malformed choices.
do
 local names={'UpgradeService','DataService','Net','SalonService','TutorialService','DriveService'};local saved={};for _,name in ipairs(names)do saved[name]=modules[name]end
 local previousClock=testClock;testClock=20000;local profiles={};local saves={};local choices,gemEvent,coinEvent=signal(),signal(),signal();local actors={}
 modules.DataService={get=function(actor)return profiles[actor]end,canSave=function()return true end,requestSave=function()end,
  spendMoney=function(actor,cost)local d=profiles[actor];if d.money<cost then return false end;d.money-=cost;return true end,
  spendDiamonds=function(actor,cost)local d=profiles[actor];if d.diamonds<cost then return false end;d.diamonds-=cost;return true end,
  saveNow=function(actor)saves[#saves+1]=deepCopy(profiles[actor]);return true end}
 modules.Net={BuyUpgradeChoice={OnServerEvent=choices},BuyUpgrade={OnServerEvent=gemEvent},BuyCoinUpgrade={OnServerEvent=coinEvent},notify=function()end,CurrencyUpdate={FireClient=function()end}}
 modules.SalonService={refresh=function()end};modules.TutorialService={sync=function()end};modules.DriveService={maxSpeedFor=function(d)return actualMaxSpeed(d,(d.upgrades.fastRide or 0)>0 and 1.25 or 1)end}
 modules.UpgradeService=nil;require('UpgradeService').init()
 local function actor()local who=Instance.new('Player');who.Parent=Players;actors[#actors+1]=who;profiles[who]={money=1e12,diamonds=1e9,upgrades={},coinUpgrades={},shelfCapacity=12};return who,profiles[who]end
 for _,def in ipairs(Coin)do for _,initial in ipairs(Policy.choices({upgrades={},coinUpgrades={}},def.id))do for _,payment in ipairs({'coin','diamond'})do
  local who,d=actor();local option=Policy.find(d,def.id,initial.id);local amount=payment=='coin'and option.coinCost or option.diamondCost;local before=payment=='coin'and d.money or d.diamonds
  choices:Fire(who,def.id,option.id,payment)
  local remaining=payment=='coin'and d.money or d.diamonds
  check(Policy.total(d,def.id)==1 and remaining==before-amount,'each benefit accepts either currency: '..def.id..'/'..option.id..'/'..payment)
  check(Policy.total(saves[#saves],def.id)==1,'chosen benefit and debit persist immediately')
  if def.id=='income'then local expected=option.id=='coin'and 4 or 3;check(4*(d.coinUpgrades.income or 0)+3*(d.upgrades.income or 0)==expected,'income benefit is independent of currency')end
  if def.id=='botSpeed'then check(require('DeliveryBonus').points(d,'common')==(option.id=='coin'and 3 or 4),'delivery benefit is independent of currency')end
  choices:Fire(who,def.id,option.id,payment);check(Policy.total(d,def.id)==1,'repeated same-currency command is rate limited')
 end end end
 for _,id in ipairs({'security','shelves','speed'})do for _,payment in ipairs({'coin','diamond'})do
  local who,d=actor();local maximum=Policy.SharedMax[id]
  for _=1,maximum do testClock+=.3;choices:Fire(who,id,'combined',payment)end
  check(Policy.total(d,id)==maximum,'entire shared upgrade can use either single currency: '..id)
  if id=='shelves'then check(d.shelfCapacity==24,'four shelf expansions preserve twelve additional slots')end
  if id=='speed'then check((d.upgrades.speed or 0)==12 and(d.coinUpgrades.speed or 0)==12,'combined speed distributes within both historical counters')end
  local a,b=d.money,d.diamonds;testClock+=.3;choices:Fire(who,id,'combined','coin');choices:Fire(who,id,'combined','diamond')
  check(d.money==a and d.diamonds==b,'shared maximum rejects both payment routes')
 end end
 local who,d=actor();local a,b=d.money,d.diamonds
 choices:Fire(who,'autoCollect','diamond','coin');testClock+=.3;choices:Fire(who,'income','invalid','diamond')
 check(d.money==a and d.diamonds==b and not d.upgrades.autoCollect,'unavailable currency and invalid benefit cannot charge or grant')
 for _,who in ipairs(actors)do who:Destroy()end
 for _,name in ipairs(names)do modules[name]=saved[name]end;testClock=previousClock
end
print('PASS: +1 speed, five-diamond prices, own-avatar mastery, distinct benefits with both currencies, one-card UI and mixed/shared upgrade saves')
