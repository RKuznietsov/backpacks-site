-- Synthetic R6/R15 rigs exercise actual static posing and portrait frustum, not loaded Roblox assets/rendering.
do
 local Preview=require('AvatarPreview')
 local function rig(mode,yaw)
  local model=Instance.new('Model');local records={}
  local function part(name,size)
   local p=Instance.new('Part');p.Name=name;p.Size=size;p.Transparency=0;p.Color=Color3.fromRGB(235,193,158);p.Parent=model;return p
  end
  local root=part('HumanoidRootPart',V.new(2,2,1));root.Transparency=1;root.CFrame=CF.Angles(0,yaw,0);model.PrimaryPart=root
  local r6=mode=='r6';local lower=r6 and part('Torso',V.new(2,2,1))or part('LowerTorso',V.new(2,1.2,1))
  local upper=r6 and lower or part('UpperTorso',V.new(2,1.6,1))
  local head=mode~='missing'and part('Head',V.new(1.5,mode=='tiny'and .1 or 1,1))or nil
  if head and mode=='tiny'then head.Transparency=1 end
  local function link(a,b,c0,c1,name)
   if not b then return end
   local j
   if mode=='attachments'or mode=='rig_only'then
    local x=Instance.new('Attachment');x.Name=name..'RigAttachment';x.CFrame=c0;x.Parent=a
    local y=Instance.new('Attachment');y.Name=x.Name;y.CFrame=c1;y.Parent=b
    if mode=='attachments'then j=Instance.new('AnimationConstraint');j.Attachment0=x;j.Attachment1=y;j.Parent=b end
   else
    j=Instance.new(mode=='animation'and'AnimationConstraint'or'Motor6D');j.Part0=a;j.Part1=b;j.C0=c0;j.C1=c1;j.Transform=CF.identity;j.Parent=b
    records[#records+1]={joint=j,c0=c0,c1=c1}
   end
  end
  link(root,lower,CF.identity,CF.identity,'Root')
  if not r6 then link(lower,upper,CF.new(0,.6,0),CF.new(0,-.8,0),'Waist')end
  link(upper,head,mode=='embedded'and CF.identity or CF.new(0,upper.Size.Y/2,0),mode=='embedded'and CF.identity or CF.new(0,-.5,0),'Neck')
  for _,side in ipairs({-1,1})do local leg=part(side<0 and'LeftLeg'or'RightLeg',V.new(1,2.4,1));link(lower,leg,CF.new(side*.5,-lower.Size.Y/2,0),CF.new(0,1.2,0),side<0 and'LeftHip'or'RightHip')end
  if head then
   local hair=Instance.new('Accessory');hair.Name='Hair';hair.Parent=model
   local handle=part('Handle',V.new(1.6,.4,1.1));handle.Parent=hair
   local weld=Instance.new('Weld');weld.Part0=head;weld.Part1=handle;weld.C0=CF.new(0,.65,0);weld.C1=CF.identity;weld.Parent=handle
  end
  return model,records
 end
 for _,mode in ipairs({'r6','animation','attachments','rig_only','embedded','missing','tiny'})do for _,yaw in ipairs({0,math.pi/2})do
  local model,records=rig(mode,yaw);Preview.prepare(model)
  local head=model:FindFirstChild('Head');local torso=model:FindFirstChild('UpperTorso')or model:FindFirstChild('Torso')
  check(head and head.Transparency==0 and head.Size.Y>=.45,'preview always contains a visible complete head: '..mode)
  local relative=torso.CFrame:PointToObjectSpace(head.Position)
  check(relative.Y-head.Size.Y/2>=torso.Size.Y/2-.17,'head rests above shoulders instead of inside the neck: '..mode)
  for _,r in ipairs(records)do check(r.joint.C0==r.c0 and r.joint.C1==r.c1,'posing reads joint frames without assigning read-only C0/C1')end
  local hair=model:FindFirstChild('Hair');if hair then check((hair.Handle.Position-head.Position).Y>.6,'accessory follows the repaired head position')end
  local bounds,size=Preview.bounds(model)
  check(head.Position.Y+head.Size.Y/2<=bounds.Position.Y+size.Y/2+.001,'whole head belongs to the measured portrait bounds')
  local before=head.CFrame.Position;Preview.prepare(model);check((head.Position-before).Magnitude<.001,'preparing a server template and its client copy is idempotent')
  model:Destroy()
 end end
 local previews=Instance.new('Folder');local template=Instance.new('Model');template.Name='worker';template:SetAttribute('CatalogReady',true);template.Parent=previews
 function template:Clone()return rig('attachments',0)end
 local parent=Instance.new('Frame');local image=actualAvatarPortrait(parent,previews,{catalogLook='worker'})
 local view=image:FindFirstChild('AvatarPortrait');local camera=view.CurrentCamera;local model=view:FindFirstChildOfClass('WorldModel'):FindFirstChildOfClass('Model');local head=model.Head
 check(view.Size.Y.Scale==1 and view.Size.Y.Offset==0,'hero portrait uses full image height; try-on button no longer covers the avatar')
 local tangent=math.tan(math.rad(camera.FieldOfView)/2)
 for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
  local corner=head.CFrame*V.new(head.Size.X*x/2,head.Size.Y*y/2,head.Size.Z*z/2);local p=camera.CFrame:PointToObjectSpace(corner);local depth=-p.Z
  check(depth>0 and math.abs(p.Y)<depth*tangent and math.abs(p.X)<depth*tangent*1.03,'actual portrait camera includes every head corner')
 end end end
 parent:Destroy();previews:Destroy()
end
print('PASS: actual preview posing for R6, modern AnimationConstraint, attachment-only and streamed rigs; missing/embedded/tiny heads, accessory repositioning, idempotency and full-head portrait frustum (synthetic rigs)')
