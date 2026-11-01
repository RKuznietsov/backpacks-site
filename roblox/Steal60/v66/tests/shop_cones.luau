-- Server vendor construction with delayed/failed catalog APIs and cloned native
-- instances. No live Roblox outfit download or client streaming is emulated.
do
 local oldOwner,oldVendor=modules.OwnerService,modules.VendorCharacters;local oldSpawn=task.spawn
 local pending={};local calls={};local parents={};local fallback={}
 task.spawn=function(fn)pending[#pending+1]=fn end;modules.VendorCharacters=nil
 modules.OwnerService={newRig=function(_,role)
  calls[role]=(calls[role]or 0)+1
  if role=='coins'then error('simulated catalog failure')end
  if role=='cosmetics'then return nil end
  local rig=fallback[1].diamonds:Clone();rig.NPC_ShopLabel:Destroy()
  local hum=Instance.new('Humanoid');hum.Parent=rig;return rig
 end}
 local Vendors=require('VendorCharacters')
 for i=1,3 do
  local parent=Instance.new('Model');parent.Parent=workspace;parents[i]=parent;fallback[i]={}
  for j,role in ipairs({'coins','diamonds','cosmetics'})do
   local at=CF.new(i*30,.73,j*8);local rig=Vendors.create(parent,at,role,Color3.fromRGB(130,220,180),role)
   fallback[i][role]=rig
   check(rig and rig.Parent==parent and rig.Head and rig:FindFirstChild('FriendlyFace',true)and rig:FindFirstChild('HairLock',true),'every salon immediately has a full dressed vendor with head/face/hair')
   check(rig:GetAttribute('VendorAppearance')=='NativeDressed'and rig.ModelStreamingMode==Enum.ModelStreamingMode.Atomic,'immediate vendor is atomic and independent of external outfit delivery')
   for _,part in ipairs(rig:GetDescendants())do if part:IsA('BasePart')then check(part.Anchored and not part.CanCollide and not part.CanTouch,'every vendor part is stationary on the server, without per-player physics ownership')end end
   local bounds,size=require('AvatarPreview').bounds(rig);check(math.abs(bounds.Position.Y-size.Y/2-.73)<.0001,'vendor feet rest on the existing stand')
  end
 end
 check(#pending==3,'three salons request only one template load for each of the three roles')
 parents[3]:Destroy()
 for _,fn in ipairs(pending)do fn()end
 check(calls.coins==1 and calls.diamonds==1 and calls.cosmetics==1,'outfit requests are shared per role even when another salon disappears during loading')
 for i=1,2 do
  for _,role in ipairs({'coins','diamonds','cosmetics'})do
   local rig=parents[i]:FindFirstChild('MarketplaceVendor_'..role)
   check(rig and rig.Head and rig:GetAttribute('VendorAppearance')==(role=='diamonds'and'CatalogDressed'or'NativeDressed'),'catalog failure never leaves an empty shop; successful template updates every surviving salon')
  end
 end
 local late=Instance.new('Model');late.Parent=workspace
 local copied=Vendors.create(late,CF.new(90,.73,8),'diamonds',Color3.fromRGB(130,220,180),'diamonds')
 check(copied:GetAttribute('VendorAppearance')=='CatalogDressed'and #pending==3,'later joiners clone the exact shared dressed template without another asset request')
 local original=parents[1]:FindFirstChild('MarketplaceVendor_diamonds')
 check(#original:GetDescendants()==#copied:GetDescendants()and original.Head.Color.R==copied.Head.Color.R,'all salons share the same role appearance and complete geometry')
 for _,parent in ipairs(parents)do if parent.Parent then parent:Destroy()end end;late:Destroy()
 task.spawn=oldSpawn;modules.OwnerService=oldOwner;modules.VendorCharacters=oldVendor
end
print('PASS: immediate server-created dressed vendors in three salons, one delayed template request per role, deterministic clones, API-failure fallback, atomic models, feet placement and removed-salon cleanup (API doubles)')

-- Execute real main-menu/economy/atelier repaint functions. Explicit native-layout
-- double below models AutomaticCanvasSize clamping when cards are destroyed.
do
 local oldDelay=task.delay;local timers={};task.delay=function(_,fn)timers[#timers+1]=fn end
 local function drain()local batch=timers;timers={};for _,fn in ipairs(batch)do fn()end;flush()end
 local created={};local saved={};local signals={services.UserInputService.InputBegan}
 for _,name in ipairs({'GetMenuData','GetSeasonTop','OpenEconomyNPC','BuyUpgrade','BuyCoinUpgrade','BuyUpgradeChoice','BuyVIP','ManageWorkshop','CosmeticAction','CosmeticUpdate','CurrencyUpdate'})do
  local r=remotes:FindFirstChild(name)
  if not r then r=Instance.new('RemoteEvent');r.Name=name;r.Parent=remotes;created[#created+1]=r end
  saved[r]={invoke=r.InvokeServer,fire=r.FireServer,event=r.OnClientEvent}
  r.OnClientEvent=signal();function r:FireServer()end;signals[#signals+1]=r.OnClientEvent
 end
 local counts={};for _,s in ipairs(signals)do counts[s]=#s.listeners end
 local Config=require('CosmeticConfig');local W=require('MenuWidgets');local oldPreview=W.preview
 W.preview=function(parent)local f=Instance.new('Frame');f.Parent=parent;return f end
 local data={money=100000000,diamonds=100000,hackLevel=16,till=100,income=500000/3600,tillHours=12,shelfCapacity=12,shelf={},catalog={},
  heroSkinBonusLevel=2,petBonusLevel=1,cosmeticsOwned={[Config.COIN_HERO_ID]=true},cosmeticsEquipped={},petUnlocked=true,upgrades={},coinUpgrades={},
  masteryEffects={hero={current='Доход +2%',next='Доход +3%'},pet={current='Доход +1%',next='Доход +2%'}},carCosmetics={}}
 local _,_,_,rows=previewFor(data,'income','coin',24);data.dualUpgrades=rows
 for _,def in ipairs(require('UpgradeConfig'))do if not require('CoinUpgradeConfig').ById[def.id]then
  data.upgrades[#data.upgrades+1]={id=def.id,name=def.name,description=def.description,level=0,max=def.max,cost=100,currentEffect='0%',nextEffect='+1%'}
 end end
 local requests=0;local unavailable=false
 function remotes.GetMenuData:InvokeServer()requests+=1;if unavailable then return nil end;return data end
 local oldMarket=services.MarketplaceService;services.MarketplaceService={PromptProductPurchase=function()end}
 local previews=services.ReplicatedStorage:FindFirstChild('Steal60CatalogPreviews');local addedPreviews=not previews
 if not previews then previews=Instance.new('Folder');previews.Name='Steal60CatalogPreviews';previews.Parent=services.ReplicatedStorage end
 for _,look in ipairs(Config.CatalogOrder)do previews:SetAttribute(look,true)end
 local screens={};local UIs={}
 local root=Instance.new('ScreenGui');root.Parent=playerGui;screens[#screens+1]=root
 local panel=Instance.new('Frame');panel.Visible=true;panel.Parent=root
 local content=Instance.new('ScrollingFrame');content.AbsoluteSize=Vector2.new(900,400);content.CanvasSize=UDim2.new();content.AutomaticCanvasSize=Enum.AutomaticSize.Y;content.Parent=panel
 local list=Instance.new('UIListLayout');list.Parent=content
 local main,refreshMain=makeMainShop(content,panel);main('upgrade')
 UIs[#UIs+1]={scroll=content,draw=function()main('upgrade')end,refresh=refreshMain}
 root=Instance.new('ScreenGui');root.Parent=playerGui;screens[#screens+1]=root
 local economy,economyScroll,economyDraw,economyOpen=makeEconomyShop(root);economyOpen('coins','coins')
 UIs[#UIs+1]={scroll=economyScroll,draw=economyDraw}
 root=Instance.new('ScreenGui');root.Parent=playerGui;screens[#screens+1]=root
 local oldSpawn=task.spawn;task.spawn=function()end
 local atelier,atelierScroll,atelierDraw=makeCosmeticUI(root);task.spawn=oldSpawn;atelierDraw('hero',1000)
 UIs[#UIs+1]={scroll=atelierScroll,draw=function()atelierDraw('hero',1000)end}
 local function settle(scroll,height)
  scroll.AbsoluteSize=Vector2.new(900,400);scroll.AbsoluteWindowSize=Vector2.new(900,400);scroll.AbsoluteCanvasSize=Vector2.new(900,height)
  scroll:FindFirstChildOfClass('UIListLayout').AbsoluteContentSize=Vector2.new(900,height)
  for _=1,3 do services.RunService.RenderStepped:Fire(1/60)end
 end
 for _,ui in ipairs(UIs)do
  settle(ui.scroll,4500);ui.scroll.CanvasPosition=Vector2.new(0,2200)
  for i=1,20 do
   -- Model the native shrink/clamp that caused the original bug. A canvas lease
   -- must be active BEFORE any production card is destroyed.
   for _,card in ipairs(ui.scroll:GetChildren())do if card:IsA('Frame')then
    card.Destroying:Connect(function()
     if ui.scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y then ui.scroll.CanvasPosition=Vector2.new(0,0)end
    end)
   end end
   data.money-=100;data.heroSkinBonusLevel=i%30;ui.draw();settle(ui.scroll,4500)
   check(ui.scroll.CanvasPosition.Y==2200,'twenty real purchase-data repaints keep the same visible scroll position in all three shops')
   check(ui.scroll.AutomaticCanvasSize==Enum.AutomaticSize.Y,'native automatic sizing resumes after the rebuilt layout settles')
  end
  unavailable=true;ui.draw();check(ui.scroll.CanvasPosition.Y==2200,'a throttled/failed data refresh retains populated content and scroll');unavailable=false
 end
 main('shop');settle(content,4500);check(content.CanvasPosition.Y==0,'deliberately switching a tab starts at its top')
 main('upgrade');settle(content,4500);content.CanvasPosition=Vector2.new(0,2200)
 local before=requests;for _=1,20 do refreshMain();remotes.CurrencyUpdate.OnClientEvent:Fire()end
 drain();settle(content,4500)
 check(requests-before<=3,'repeated currency/purchase notifications coalesce to one request per open shop rather than flooding GetMenuData')
 check(content.CanvasPosition.Y==2200,'coalesced currency refresh preserves the main upgrade position')
 local finish=require('ScrollKeeper').begin(content,'upgrade');list.AbsoluteContentSize=Vector2.new(900,600);finish();settle(content,600)
 check(content.CanvasPosition.Y==200,'when content actually shrinks, scrolling clamps to its new valid bottom')
 for _,screen in ipairs(screens)do screen:Destroy()end
 for _,s in ipairs(signals)do for i=counts[s]+1,#s.listeners do s.listeners[i][2]:Disconnect()end end
 for r,values in pairs(saved)do r.InvokeServer=values.invoke;r.FireServer=values.fire;r.OnClientEvent=values.event end
 for _,r in ipairs(created)do r:Destroy()end;if addedPreviews then previews:Destroy()end
 W.preview=oldPreview;services.MarketplaceService=oldMarket;task.delay=oldDelay
end
print('PASS: actual main/economy/atelier repaints retain scroll for 20 repeated upgrades, explicit automatic-canvas clamp reproduction, temporary data failure retention, tab reset, content shrink and coalesced refresh (layout API double)')

do
 local oldDelay=task.delay;local timers={};task.delay=function(_,fn)timers[#timers+1]=fn end
 local oldPreload=services.ContentProvider.PreloadAsync;local soundReady=true
 function services.ContentProvider:PreloadAsync(sounds,callback)for _,s in ipairs(sounds)do s.IsLoaded=soundReady;callback(s.SoundId,soundReady and Enum.AssetFetchStatus.Success or Enum.AssetFetchStatus.Failure)end end
 local screen=Instance.new('ScreenGui');screen.Parent=playerGui;local event=signal()
 require('ConeFeedback').start(screen,{OnClientEvent=event})
 local sound=services.SoundService:FindFirstChild('Steal60ConeCoin')
 event:Fire(V.new(450,2,3));local popup=playerGui:FindFirstChild('Steal60ConeReward')
 check(popup and popup.RewardAmount.Text=='+1 $'and popup.StudsOffsetWorldSpace.Y==6,'server-confirmed cone hit commands a rising dollar above its world position')
 check(sound.IsPlaying and sound.Volume==.10 and not sound.Looped,'coin feedback uses one quiet one-shot sound')
 check(not popup.Adornee.CanCollide and popup.Adornee.Transparency==1,'local popup anchor cannot affect driving or physics')
 local amount=0;for _,item in ipairs(playerGui:GetChildren())do if item.Name=='Steal60ConeReward'then amount+=1 end end
 event:Fire('forged');local after=0;for _,item in ipairs(playerGui:GetChildren())do if item.Name=='Steal60ConeReward'then after+=1 end end
 check(after==amount,'invalid popup payloads are ignored')
 for i=1,20 do event:Fire(V.new(450+i,2,3))end
 amount=0;for _,item in ipairs(playerGui:GetChildren())do if item.Name=='Steal60ConeReward'then amount+=1 end end
 check(amount==16,'a dense row of cones has a bounded popup count')
 for _,fn in ipairs(timers)do fn()end
 check(not playerGui:FindFirstChild('Steal60ConeReward')and not workspace:FindFirstChild('Steal60ConeRewardAnchor'),'expiry clears every local popup and anchor')
 screen:Destroy();check(not sound.Parent,'GUI destruction stops and removes the coin sound')
 soundReady=false;screen=Instance.new('ScreenGui');screen.Parent=playerGui;event=signal();require('ConeFeedback').start(screen,{OnClientEvent=event})
 event:Fire(V.new(450,2,3));sound=services.SoundService:FindFirstChild('Steal60ConeCoin')
 check(not sound.IsPlaying and playerGui:FindFirstChild('Steal60ConeReward'),'unavailable audio leaves the reward popup working without substitute sounds')
 screen:Destroy();services.ContentProvider.PreloadAsync=oldPreload;task.delay=oldDelay
 local accepted=0;require('SecurityService').wrap('ConeReward',function()accepted+=1 end)(player,V.new(450,2,3))
 check(accepted==0,'the server-only feedback remote has no accepted client minting command')
end
print('PASS: cone feedback world position/rise/fade commands, quiet sound gating, popup bounds/expiry/GUI cleanup and rejected client minting (no audio audition/rendering)')

do
 local Layout=require('HUDLayout');local Track=require('TrackLayout');local oldStarted=Layout.started;Layout.started=nil
 local oldChar,oldClock=player.Character,testClock;local oldCamera=workspace.CurrentCamera
 local char=Instance.new('Model');char.Parent=workspace;player.Character=char
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=char
 local camera=Instance.new('Camera');camera.ViewportSize=Vector2.new(1280,720);workspace.CurrentCamera=camera
 local screen=Instance.new('ScreenGui');screen.AbsoluteSize=Vector2.new(1280,720);screen.Parent=playerGui
 local hb=services.RunService.Heartbeat;local count=#hb.listeners
 player:SetAttribute('Steal60MenuOpen',false);player:SetAttribute('HackActive',false);player:SetAttribute('CosmeticPreviewToken',nil);player:SetAttribute('Steal60ToastActive',false);player:SetAttribute('Steal60ReadingLeaderboard',false);player:SetAttribute('Steal60AudioPanelOpen',false)
 local function step(at,district)testClock=at;root.Position=V.new(Track.districtStart(district)+10,3,0);hb:Fire(.11)end
 Layout.start(screen);local banner=screen.DevelopmentBanner
 step(5000,5);check(not banner.Visible,'districts one through five show no development overlay')
 step(5001,6);check(banner.Visible and banner.Size.X.Scale==.92 and banner.Size.Y.Offset>=150 and banner.TextScaled,'sixth district immediately shows a large central scalable development banner')
 step(5002.49,6);check(banner.Visible,'development notice remains for the full requested 1.5 seconds')
 step(5002.51,6);check(not banner.Visible,'development notice ends after 1.5 seconds')
 step(5006,7);check(not banner.Visible,'crossing another unfinished district does not spam an extra notice before ten seconds')
 step(5010.9,7);check(not banner.Visible,'the next notice waits until the ten-second cadence')
 step(5011,7);check(banner.Visible,'the notice repeats every ten seconds while in unfinished districts')
 step(5011.1,5);check(not banner.Visible and not player:GetAttribute('Steal60DevelopmentNotice'),'returning to completed districts hides the banner immediately')
 screen:Destroy();char:Destroy();camera:Destroy();for i=count+1,#hb.listeners do hb.listeners[i][2]:Disconnect()end
 player.Character=oldChar;workspace.CurrentCamera=oldCamera;testClock=oldClock;Layout.started=oldStarted
end
print('PASS: actual large development banner at district 6+, 1.5-second duration, ten-second repetition, cross-district cadence and exit suppression (GUI/time doubles)')
