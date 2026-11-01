-- Actual screen placement across zoom/insets/DPI canvas sizes. Projection and
-- GUI properties are doubles; there is no native renderer in this test runner.
do
 local Feedback=require('ConeFeedback')
 for _,canvas in ipairs({Vector2.new(240,240),Vector2.new(360,640),Vector2.new(1280,684),Vector2.new(1536,828),Vector2.new(3840,2160)})do
  for _,viewport in ipairs({canvas,Vector2.new(canvas.X*1.25,canvas.Y*1.25+36)})do
   for _,point in ipairs({V.new(viewport.X*.5,viewport.Y*.65,30),V.new(-20000,20000,10),V.new(20000,-20000,10),V.new(10,10,-1)})do
    for _,progress in ipairs({0,.5,1})do for _,lane in ipairs({-1,0,1})do
     local p=Feedback.position(point,viewport,canvas,progress,lane)
     check(p.X>=56 and p.X<=canvas.X-56 and p.Y>=28 and p.Y<=canvas.Y-28,'reward remains readable inside the real GUI canvas, including behind/off-screen car projection')
    end end
   end
  end
 end
end
print('PASS: car-relative reward placement stays within five canvas sizes, DPI/inset variants, off-screen/behind-camera points and every rise/lane phase (projection geometry only)')

do
 local oldCamera,oldClock=workspace.CurrentCamera,testClock
 local camera=Instance.new('Camera');camera.CFrame=CF.new(450,20,-30);camera.ViewportSize=Vector2.new(1280,720);workspace.CurrentCamera=camera;testClock=9000
 local screen=Instance.new('ScreenGui');screen.Parent=playerGui
 local Ocean=require('OceanBackdrop');local heartbeat=services.RunService.Heartbeat;local count=#heartbeat.listeners
 Ocean.start(screen);Ocean.start(screen)
 local folder=workspace:FindFirstChild('Steal60OceanBackdrop');check(folder~=nil,'local ocean starts with the game GUI')
 local water,ripples={},{}
 for _,part in ipairs(folder:GetChildren())do
  if part.Name=='OceanSurface'then water[#water+1]=part elseif part.Name=='OceanRipple'then ripples[#ripples+1]=part end
  check(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow,'ocean surfaces and crests never affect collisions, rays or shadows')
  check(part.Size.X<=2048 and part.Size.Y<=2048 and part.Size.Z<=2048,'all sea parts fit Roblox native size limits')
 end
 check(#water==25 and #ripples==56 and #folder:GetChildren()==81,'ocean has a fixed small tile/crest set, including duplicate-start protection')
 local startTransparency=ripples[1].Transparency;local startPos=ripples[1].CFrame.Position
 for i=1,1000 do
  local position=V.new(i*640+400,20,i%2==0 and -7000 or 7000)
  camera.CFrame=CF.new(position);testClock=9000+i*.11;heartbeat:Fire(.11)
  local minX,minZ,maxX,maxZ=math.huge,math.huge,-math.huge,-math.huge
  for _,part in ipairs(water)do
   minX=math.min(minX,part.Position.X-part.Size.X/2);maxX=math.max(maxX,part.Position.X+part.Size.X/2)
   minZ=math.min(minZ,part.Position.Z-part.Size.Z/2);maxZ=math.max(maxZ,part.Position.Z+part.Size.Z/2)
   check(math.abs(part.Position.Y+part.Size.Y/2-Ocean.LEVEL)<.000001,'sea level stays below every ground district while the view moves')
  end
  check(position.X-minX>=4096 and maxX-position.X>=4096 and position.Z-minZ>=4096 and maxZ-position.Z>=4096,'the view has at least 4096 studs of continuous water in each direction, beyond the 1080-stud map haze')
  check(#folder:GetChildren()==81,'one thousand district-sized moves never grow ocean instance count')
 end
 check((ripples[1].Position-startPos).Magnitude>1 and ripples[1].Transparency~=startTransparency,'crests move/fade with time and travel instead of staying a static flat backdrop')
 screen:Destroy();check(not folder.Parent,'destroying the game GUI removes the complete local sea')
 for i=count+1,#heartbeat.listeners do check(not heartbeat.listeners[i][2].Connected,'ocean callbacks disconnect during cleanup')end
 camera:Destroy();workspace.CurrentCamera=oldCamera;testClock=oldClock
end
print('PASS: bounded 25-tile ocean and 56 subtle crests, native part size/collision limits, one thousand district moves with 4096-stud horizon coverage, animated ripples and full cleanup (no water shader/rendering)')

-- Actual builders: invisible limits cover the garage shoreline above and below
-- water, close both corners and preserve the onward procedural road.
do
 local oldSpawn=task.spawn;task.spawn=function()end
 local previousLighting=table.clone(services.Lighting.props)
 require('TrackBuilder').init();task.spawn=oldSpawn
 local core=workspace:FindFirstChild('TrackCore');check(core~=nil,'actual permanent world builder completes')
 local ground=core:FindFirstChild('Ground');local front=core:FindFirstChild('StartMapBoundary',true)
 local groundStart=ground.Position.X-ground.Size.X/2
 check(front.Position.X+front.Size.X/2>groundStart+2,'garage front wall overlaps solid land before the exposed shoreline, closing the old offshore gap')
 local bounds=core:FindFirstChild('GarageMapBounds')
 check(bounds and bounds.ModelStreamingMode==Enum.ModelStreamingMode.Persistent,'the small garage safety perimeter remains loaded independently of decorative ground')
 check(front:IsDescendantOf(bounds)and front.Position.Y-front.Size.Y/2< -6.5,'front boundary reaches below both the sea and emergency floor, preventing an underpass')
 local side,start,permanent=0,0,0
 for _,part in ipairs(core:GetDescendants())do
  if part.Name=='SideMapBoundary'then
   side+=1;check(part.Transparency==1 and part.CanCollide and part.Anchored and part.Size.Y==48 and part.Size.Z==4 and math.abs(part.Position.Z)==196 and not part.CastShadow,'garage side walls remain tall solid boundaries and become completely invisible')
  elseif part.Name=='StartMapBoundary'then
   start+=1;check(part.Transparency==1 and part.CanCollide and part.Size.Y>=48 and not part.CastShadow and part.CollisionGroup=='Default','start enclosure remains invisible, high and solid in the same collision group as the road')
  elseif part.Name=='PermanentMapEdge'then
   permanent+=1;check(part.Transparency==1 and part.Size.Y>=90 and part.Anchored and part.CanCollide and part:IsDescendantOf(bounds)and part.Position.Y-part.Size.Y/2< -6.5,'persistent lateral boundaries keep their tall top and extend below the safety floor')
  elseif part.Name=='BorderNeonRail'then check(part.Transparency==1,'outer floating rail no longer crosses the sea horizon')end
 end
 check(side==2 and start==1 and permanent>=2,'both sides, start and permanent safety sections are present')
 local left,right
 for _,part in ipairs(bounds:GetChildren())do if part.Name=='PermanentMapEdge'then if part.Position.Z<0 then left=part else right=part end end end
 for _,wall in ipairs({left,right})do
  check(front.Position.X+front.Size.X/2>=wall.Position.X-wall.Size.X/2 and front.Position.X-front.Size.X/2<=wall.Position.X+wall.Size.X/2 and
   front.Size.Z/2>=math.abs(wall.Position.Z)+wall.Size.Z/2,'the front wall overlaps the side bounds at both corners without an exit around its end')
 end
 -- Cross-shore paths at the walking, water and emergency-floor levels must
 -- intersect the actual wall volume, rather than passing under a visual panel.
 for z=-200,200,20 do for _,y in ipairs({-6,-2.35,0,3,12,40})do
  local at=front.CFrame:PointToObjectSpace(V.new(front.Position.X,y,z))
  check(math.abs(at.Z)<=front.Size.Z/2 and math.abs(at.Y)<=front.Size.Y/2,'entire garage shoreline is blocked at floor, sea, walking and jumping heights')
 end end
 do
  local previousChar=player.Character;local char=Instance.new('Model');char.Parent=workspace;player.Character=char
  local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Parent=char
  local hum=Instance.new('Humanoid');hum.Health=100;hum.Parent=char
  local Builder=require('TrackBuilder')
  local function position(p)root.Position=p;char.WorldPivot=root.CFrame;root.AssemblyLinearVelocity=V.new(-7,-18,4);root.AssemblyAngularVelocity=V.new(2,3,4)end
  for _,p in ipairs({V.new(-60.1,3,0),V.new(-63,-3,0),V.new(-63,-7,-198),V.new(-63,-7,198),V.new(100,-2.5,0),V.new(200,-3,201)})do
   position(p);check(Builder.rescueOutside(player),'a pedestrian who got beyond the garage edge is recovered before remaining in the sea')
   check(root.Position.X>=front.Position.X+front.Size.X/2+4 and root.Position.Y==4 and math.abs(root.Position.Z)<=187,'recovery lands safely inside the wall, not inside its collider or beyond the shore')
   check(root.AssemblyLinearVelocity.Magnitude==0 and root.AssemblyAngularVelocity.Magnitude==0,'shore recovery clears falling velocity')
  end
  for _,p in ipairs({V.new(-54,3,0),V.new(15,3,0),V.new(60,4,64),V.new(60,4,-64),V.new(450,3,0),V.new(4000,3,0)})do
   position(p);check(not Builder.rescueOutside(player)and(root.Position-p).Magnitude<.001,'valid garage walks, plots and onward road travel are untouched')
  end
  position(V.new(-63,-3,0));hum.SeatPart=Instance.new('VehicleSeat')
  check(not Builder.rescueOutside(player),'the pedestrian shoreline guard never relocates a seated driver');hum.SeatPart:Destroy();hum.SeatPart=nil
  hum.Health=0;check(not Builder.rescueOutside(player),'shoreline recovery ignores a dead character')
  char:Destroy();player.Character=previousChar
 end
 for _,index in ipairs({1,5,6,20,1000})do
  local district=require('DistrictBuilder').build(index);local walls=0
  for _,part in ipairs(district:GetDescendants())do if part.Name=='SideMapBoundary'then
   walls+=1;check(part.Transparency==1 and part.CanCollide and part.Anchored and part.Size.Y==48 and math.abs(part.Position.Z)==196 and not part.CastShadow,'all district themes and late procedural districts retain invisible high side colliders')
  end end
  check(walls==2,'every generated district has both lateral bounds');district:Destroy()
 end
 local atmosphere=services.Lighting:FindFirstChild('S60_Atmosphere')
 check(services.Lighting.FogStart==300 and services.Lighting.FogEnd==1080 and atmosphere.Color.B>atmosphere.Color.R,'sea-blue haze retains the original district streaming distances')
 core:Destroy();services.Lighting.props=previousLighting
end
print('PASS: actual core closes the garage shoreline on land, below sea/floor and at both corners with persistent invisible colliders; real pedestrian recovery is safe; five district builds and maritime haze retained (geometry/API doubles)')
