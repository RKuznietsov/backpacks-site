-- Actual CarFactory + VehicleLabels + LanguageController; Instances, streaming
-- order and the two client contexts below are API doubles, not Roblox networking.
do
 local savedFactory,savedCollision=modules.CarFactory,modules.CollisionService
 local savedStorage=services.ServerStorage;services.ServerStorage=Instance.new('Folder')
 modules.CollisionService={applyVehicle=function()end};modules.CarFactory=nil
 local Factory=require('CarFactory');local Collection=services.CollectionService
 local oldPlayer=Players.LocalPlayer;local oldChar=player.Character;local oldCamera=workspace.CurrentCamera
 local camera=Instance.new('Camera');camera.CFrame=CF.new(450,30,30);workspace.CurrentCamera=camera
 local signals={services.RunService.Heartbeat,workspace.DescendantAdded,Players.DescendantAdded,
  Collection:GetInstanceAddedSignal('S60VehicleLabel'),Collection:GetInstanceRemovedSignal('S60VehicleLabel')}
 local counts={};for _,s in ipairs(signals)do counts[s]=#s.listeners end
 local clients={}
 for i=1,2 do
  local p=i==1 and player or Instance.new('Player');if i==2 then p.UserId=789;p.Parent=Players end
  local pg=i==1 and playerGui or Instance.new('PlayerGui');if i==2 then pg.Name='PlayerGui';pg.Parent=p end
  local char=Instance.new('Model');char.Parent=workspace;p.Character=char
  local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Position=V.new(450,3,i*2);root.Parent=char
  local screen=Instance.new('ScreenGui');screen.Parent=pg
  p:SetAttribute('Steal60Language',i==1 and 'ru'or'en');Players.LocalPlayer=p
  require('LanguageController').start(screen);require('VehicleLabels').start(screen)
  clients[i]={player=p,pg=pg,char=char,root=root,screen=screen}
 end
 Players.LocalPlayer=oldPlayer
 local def=require('Cars')[1];local car=Factory.acquire(def,def.class)
 check(car.ModelStreamingMode==Enum.ModelStreamingMode.Atomic and Collection:HasTag(car,'S60VehicleLabel'),'actual factory tags the complete atomic car, including its nameplate')
 check(typeof(car:GetAttribute('CarLabelOffset'))=='Vector3','actual factory replicates a body-local roof offset without requiring an Attachment reference')
 car:PivotTo(CF.new(450,0,0));car.Parent=workspace;car:SetAttribute('State','available')
 services.RunService.Heartbeat:Fire(.25)
 local a=clients[1].pg:FindFirstChild('Steal60VehicleLabel');local b=clients[2].pg:FindFirstChild('Steal60VehicleLabel')
 check(a and b and a~=b and a.Enabled and b.Enabled,'two independent client contexts both reconstruct a late-arriving target label')
 check(a.Line3.Text=='Загрузка...'and b.Line3.Text=='Loading...','missing replicated requirement is explicitly pending, never an invented hack level')
 Factory.dress(car,def,def.class,'rare','neon',Random.new(8));car:SetAttribute('RequiredHack',23)
 services.RunService.Heartbeat:Fire(.25);flush()
 check(a.Line1.Text==def.name and b.Line1.Text==require('TextTranslator').translate(def.name,'en'),'both clients obtain the actual catalog name in their own language')
 check(a.Line3.Text=='Взлом 23+'and b.Line3.Text=='Hacking 23+','both clients obtain the actual server requirement once it arrives')
 check(a.Line2.Text=='Редкая · Неон'and b.Line2.Text=='Rare · Neon','rarity and variation are reconstructed and translated')
 local body=car:FindFirstChild('Body',true);local native=body.CarLabel
 local special=Instance.new('BillboardGui');special.Name='RoadVIPLabel';special.Enabled=true;special.Parent=body
 body.CarLabelRoofAnchor:Destroy();native.Adornee=nil;native.Enabled=true
 services.RunService.Heartbeat:Fire(.25)
 check(a.Adornee==body and b.Adornee==body and a.Enabled and b.Enabled,'a missing roof anchor/Adornee cannot erase the locally reconstructed information')
 check(native.Enabled==false and special.Enabled==true,'only the obsolete standard plate is suppressed; the special-target banner remains intact')
 camera.CFrame=CF.new(450,3000,3000);services.RunService.Heartbeat:Fire(.25)
 check(a.Enabled and b.Enabled and a.MaxDistance>=1000000,'zooming the camera far out does not hide nearby car information')
 for _=1,4 do
  clients[1].player:SetAttribute('Steal60Language','en');clients[2].player:SetAttribute('Steal60Language','ru');flush();services.RunService.Heartbeat:Fire(.25)
  check(a.Line3.Text=='Hacking 23+'and b.Line3.Text=='Взлом 23+','heartbeat never rewrites the selected client language')
  clients[1].player:SetAttribute('Steal60Language','ru');clients[2].player:SetAttribute('Steal60Language','en');flush()
 end
 car:SetAttribute('RequiredHack',nil);services.RunService.Heartbeat:Fire(.25)
 check(a.Line3.Text=='Загрузка...'and b.Line3.Text=='Loading...','late/missing required-level attribute never falls back to the catalog base level')
 car:SetAttribute('RequiredHack',23);car:SetAttribute('State','busy');services.RunService.Heartbeat:Fire(.25)
 check(a.Line3.Text=='ЗАНЯТО'and b.Line3.Text=='BUSY','busy state updates both client labels')
 car:SetAttribute('State','ride');services.RunService.Heartbeat:Fire(.25)
 check(a.Line3.Text=='ТВОЯ МАШИНА'and b.Line3.Text=='YOUR CAR','ride state preserves its existing label')
 car:SetAttribute('State','display');services.RunService.Heartbeat:Fire(.25)
 check(not a.Line3.Visible and not b.Line3.Visible and a.Size.X.Offset==135,'exhibits keep their smaller two-line nameplates')
 car:SetAttribute('State','cosmetic_preview');services.RunService.Heartbeat:Fire(.25)
 check(not a.Enabled and not b.Enabled,'inspection previews do not acquire duplicate nameplates')
 car:SetAttribute('State','available');body.Parent=nil;services.RunService.Heartbeat:Fire(.25)
 check(not a.Enabled and not b.Enabled,'a stale PrimaryPart reference cannot keep a streamed-out body visible')
 local replacement=Instance.new('Part');replacement.Name='Body';replacement.Size=body.Size;replacement.CFrame=body.CFrame;replacement.Parent=car
 services.RunService.Heartbeat:Fire(.25)
 check(a.Enabled and b.Enabled and a.Adornee==replacement and b.Adornee==replacement,'body stream-in rebinds both labels without a server-owned BillboardGui or roof attachment')
 clients[2].root.Position=V.new(900,3,0);services.RunService.Heartbeat:Fire(.25)
 check(a.Enabled and not b.Enabled,'visibility follows each player, while faraway targets are culled')
 clients[2].root.Position=V.new(450,3,4);replacement:Destroy();body.Parent=car
 Factory.release(car);services.RunService.Heartbeat:Fire(.25)
 check(not a.Parent and not b.Parent,'returning a vehicle to the pool removes its local UI')
 car.ModelStreamingMode=Enum.ModelStreamingMode.Default
 local reused,isNew=Factory.acquire(def,def.class)
 check(reused==car and not isNew and car.ModelStreamingMode==Enum.ModelStreamingMode.Atomic,'pool reuse also reasserts atomic streaming')
 Factory.dress(car,def,def.class,'common','default',Random.new(9));car:SetAttribute('RequiredHack',6);car:SetAttribute('State','available');car.Parent=workspace
 services.RunService.Heartbeat:Fire(.25)
 a=clients[1].pg:FindFirstChild('Steal60VehicleLabel');b=clients[2].pg:FindFirstChild('Steal60VehicleLabel')
 check(a and b and a.Line3.Text=='Взлом 6+'and b.Line3.Text=='Hacking 6+','existing tags re-register pooled cars with fresh text on both clients')
 Collection:RemoveTag(car,'S60VehicleLabel')
 check(not a.Parent and not b.Parent,'tag removal cleans up both local nameplates immediately')
 Collection:AddTag(car,'S60VehicleLabel');services.RunService.Heartbeat:Fire(.25)
 for _,client in ipairs(clients)do client.screen:Destroy();check(not client.pg:FindFirstChild('Steal60VehicleLabel'),'destroying the game GUI removes its local label collectors');client.char:Destroy();if client.player~=player then client.player:Destroy()end end
 for _,s in ipairs(signals)do for i=counts[s]+1,#s.listeners do s.listeners[i][2]:Disconnect()end end
 Collection:RemoveTag(car,'S60VehicleLabel');car:Destroy();camera:Destroy();services.ServerStorage:Destroy()
 services.ServerStorage=savedStorage;modules.CarFactory=savedFactory;modules.CollisionService=savedCollision
 player.Character=oldChar;Players.LocalPlayer=oldPlayer;workspace.CurrentCamera=oldCamera;player:SetAttribute('Steal60Language','ru')
end
print('PASS: actual factory atomic/tag setup and pool reuse, two client contexts, late label attributes/body/anchor repair, camera-independent range, special banner retention, RU/EN and label cleanup (API doubles; no native streaming/rendering)')
