-- Actual whole-footprint sweep at five headings. Only assembly/clock APIs are
-- doubled; the real server money/ownership chain is covered in mobile_driving.
do
 local previous=coneCache
 for _,yaw in ipairs({0,math.pi/4,math.pi/2,math.pi,-math.pi/2})do
  local forward=CF.Angles(0,yaw,0).RightVector;local side=V.new(-forward.Z,0,forward.X)
  local function hit(point,from,to,speed,velocity)
   local cone=Instance.new('Part');cone.Size=V.new(1.9,.22,1.9);cone.Position=point;cone.Parent=workspace;coneCache={cone}
   knockCones(from,to,forward,speed,6,2.5,nil,nil,velocity)
   return cone
  end
  local rear=hit(-forward*6.8,V.zero,-forward*.4,-12,-forward*12)
  check(not rear.Anchored and rear.AssemblyLinearVelocity:Dot(forward)<-20,'rear bumper contact in reverse throws the cone behind the car at every heading');rear:Destroy()
  for _,sign in ipairs({-1,1})do for _,longitudinal in ipairs({-4,0,4})do
   local flank=hit(side*sign*3.4+forward*longitudinal,V.zero,forward*.2,18,forward*18)
   check(not flank.Anchored and flank.AssemblyLinearVelocity:Dot(side)*sign>20,'front/middle/rear of either side panel launches a touched cone outwards')
   local serial=flank:GetAttribute('KnockdownSerial');knockCones(V.zero,forward*.2,forward,18,6,2.5)
   check(flank:GetAttribute('KnockdownSerial')==serial,'side contact cannot claim the same fallen cone twice');flank:Destroy()
  end end
  local lateral=hit(side*5,-side*8,side*8,30,side*30)
  check(not lateral.Anchored and lateral.AssemblyLinearVelocity:Dot(side)>30,'actual lateral motion is swept against the full car and determines cone flight');lateral:Destroy()
  local fast=hit(forward*15+side*2,V.zero,forward*30,84,forward*84)
  check(not fast.Anchored,'long high-speed steps cannot tunnel through a cone');fast:Destroy()
  local nearMiss=hit(side*3.55,V.zero,forward*.2,30,forward*30)
  check(nearMiss.Anchored,'nearby cone outside the expanded side footprint is left intact');nearMiss:Destroy()
  local tall=hit(forward*6+V.new(0,8,0),V.zero,forward*.2,30,forward*30)
  check(tall.Anchored,'cones on another vertical level cannot be knocked down');tall:Destroy()
  local slow=hit(-forward*6.8,V.zero,-forward*.1,.75,-forward*.75)
  check(not slow.Anchored,'a gentle reversing touch also topples a cone');slow:Destroy()
  local parked=hit(side*2.5,V.zero,V.zero,0,V.zero)
  check(parked.Anchored,'stationary overlap cannot repeatedly knock down a respawned cone');parked:Destroy()
 end
 coneCache=previous
end
print('PASS: actual full-car cone sweep at five headings, reverse bumper, both complete flanks, lateral motion, fast tunneling, gentle touch, duplicate claim and near/height/stationary rejection (assembly doubles)')
