-- Entire production atelier UI up to its event bindings; only 3D asset previews and async background loops are doubled.
do
 local Config=require('CosmeticConfig');local Access=require('InterfaceAccess')
 local data={money=10000000,diamonds=1000,cosmeticsOwned={[Config.COIN_HERO_ID]=true},cosmeticsEquipped={hero=Config.COIN_HERO_ID},petUnlocked=true,heroSkinBonusLevel=2,petBonusLevel=1,catalog={},carCosmetics={},
  masteryEffects={hero={current='Доход +2%',next='Доход +3%'},pet={current='Доход +1%',next='Доход +2%'}}}
 local created={};local request
 for _,name in ipairs({'GetMenuData','OpenEconomyNPC','CosmeticAction','CosmeticUpdate','CurrencyUpdate'})do
  local remote=remotes:FindFirstChild(name)
  if not remote then remote=Instance.new('RemoteEvent');remote.Name=name;remote.Parent=remotes;created[#created+1]=remote end
  if name=='GetMenuData'then request=remote end
 end
 local oldInvoke=request.InvokeServer;function request:InvokeServer()return data end
 local previews=services.ReplicatedStorage:FindFirstChild('Steal60CatalogPreviews');local addedPreviews=not previews
 if not previews then previews=Instance.new('Folder');previews.Name='Steal60CatalogPreviews';previews.Parent=services.ReplicatedStorage end
 for _,look in ipairs(Config.CatalogOrder)do previews:SetAttribute(look,true)end
 local oldSpawn=task.spawn;task.spawn=function()end
 local screen=Instance.new('ScreenGui');screen.Parent=playerGui
 local panel,scroll,draw=makeCosmeticUI(screen)
 task.spawn=oldSpawn
 for _,width in ipairs({360,950,1316,1896,3800})do for _,category in ipairs({'hero','pet','paint','tuning','aura'})do
  draw(category,width)
  local contentWidth=width-32;local columns=Access.catalogColumns(contentWidth);local cards,rows,first=0,0;local lastOrder=0
  for _,row in ipairs(scroll:GetChildren())do if row.Name=='CosmeticGridRow'then
   rows+=1;check(row.LayoutOrder>lastOrder,'item grid rows keep stable order');lastOrder=row.LayoutOrder
   local count=0;local lastRight=-1
   for _,cell in ipairs(row:GetChildren())do if cell.Name=='CosmeticGridCell'then
    count+=1;local cellWidth=cell.Size.X.Scale*(contentWidth-14)+cell.Size.X.Offset
    local left=cell.Position.X.Scale*(contentWidth-14)+cell.Position.X.Offset
    check(left>lastRight and left+cellWidth<=contentWidth-14+.01,'card cells fit side by side without overlap');lastRight=left+cellWidth
    local card=cell:FindFirstChild('CosmeticCard');check(card~=nil,'every grid cell contains the actual item card')
    cards+=1;first=first or card:GetAttribute('CosmeticId');local height=card.Size.Y.Offset;local rectangles={}
    for _,child in ipairs(card:GetChildren())do if child:IsA('TextLabel')or child:IsA('TextButton')then
     local x=child.Position.X.Scale*cellWidth+child.Position.X.Offset;local y=child.Position.Y.Scale*height+child.Position.Y.Offset
     local w=child.Size.X.Scale*cellWidth+child.Size.X.Offset;local h=child.Size.Y.Scale*height+child.Size.Y.Offset
     check(x>=0 and x+w<=cellWidth+.01 and y>=0 and y+h<=height+.01,'actual card text and buy/equip buttons fit inside their tile')
     for _,r in ipairs(rectangles)do check(x+w<=r.x+.01 or r.x+r.w<=x+.01 or y+h<=r.y+.01 or r.y+r.h<=y+.01,'card title, description, status and purchase text do not overlap')end
     rectangles[#rectangles+1]={x=x,y=y,w=w,h=h}
    end end
   end end
   check(count>=1 and count<=columns,'row respects responsive column count')
  end end
  check(cards>0 and rows==math.ceil(cards/columns),'every category has populated, tightly packed item rows')
  if category=='hero'then
   check(first==Config.COIN_HERO_ID,'coin worker remains the very first hero choice')
   check(scroll:FindFirstChild('CosmeticMastery')~=nil and scroll:FindFirstChild('MasteryShortcut',true)~=nil,'mastery remains present and has a shortcut')
  end
  if width==1316 then check(columns==2,'screenshot desktop size shows two cards per row')end
  if width==3800 then check(columns==4,'ultrawide layouts show four cards without giant empty tiles')end
 end end
 draw('hero',1316)
 local target=scroll:FindFirstChild('CosmeticMastery');scroll.CanvasPosition=Vector2.new(0,0);scroll.AbsolutePosition=Vector2.new(0,100);target.AbsolutePosition=Vector2.new(0,1200)
 scroll:FindFirstChild('MasteryShortcut',true).Activated:Fire()
 check(scroll.CanvasPosition.Y==1100,'mastery shortcut scrolls to the real upgrade panel')
 screen:Destroy();request.InvokeServer=oldInvoke;if addedPreviews then previews:Destroy()end;for _,remote in ipairs(created)do remote:Destroy()end
end
print('PASS: actual atelier categories, first coin worker, responsive one-to-four-column grid, card/button bounds and mastery shortcut; 3D previews/async loops explicitly doubled')
