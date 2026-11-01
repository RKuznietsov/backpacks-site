-- Run whole menu views with native TextColor3 type checks, not just individual upgrade cards.
do
 local W=require('MenuWidgets');local Views=require('MenuViews');local Coin=require('CoinUpgradeConfig');local Diamond=require('UpgradeConfig')
 local preview=W.preview;W.preview=function(parent)local image=Instance.new('Frame');image.Parent=parent;return image end
 local d={money=6000000,diamonds=1000,hackLevel=16,till=100,income=500000/3600,tillHours=12,shelfCapacity=12,shelf={},catalog={},
  heroSkinBonusLevel=2,petBonusLevel=0,cosmeticsOwned={[require('CosmeticConfig').COIN_HERO_ID]=true},cosmeticsEquipped={},petUnlocked=false,upgrades={},coinUpgrades={}}
 local _,_,_,rows=previewFor(d,'income','coin',24);d.dualUpgrades=rows
 for _,def in ipairs(Diamond)do if not Coin.ById[def.id]then
  local current,nextEffect=previewFor(d,def.id,'diamond',def.max)
  d.upgrades[#d.upgrades+1]={id=def.id,name=def.name,description=def.description,level=0,max=def.max,cost=Diamond.cost(def.id,0),currentEffect=current,nextEffect=nextEffect}
 end end
 for _,width in ipairs({320,550,920})do for _,tab in ipairs({'upgrade','shop','salon','parts','odds'})do
  local parent=Instance.new('ScrollingFrame');parent.AbsoluteSize=Vector2.new(width,500);local clicks={}
  local function action(name)return function(...)clicks[#clicks+1]={name,...}end end
  local actions={choice=action('choice'),diamond=action('diamond'),vip=action('vip'),mastery=action('mastery'),atelier=action('atelier'),handbook=action('handbook')}
  check(Views.render(tab,parent,d,actions)==true,'entire menu tab renders without native property type errors: '..tab)
  local cards,buttons,ordinary=0,0,0;local cardNames={}
  for _,child in ipairs(parent:GetChildren())do
   if child.Name=='IllustratedMenuCard'then cards+=1;cardNames[child.CardTitle.Text]=true end
   if child:GetAttribute('UpgradeId')then ordinary+=1 end
  end
  for _,object in ipairs(parent:GetDescendants())do
   if object:IsA('TextLabel')or object:IsA('TextButton')then check(typeof(object.TextColor3)=='Color3','each rendered menu text has a real Color3')end
   if object:IsA('TextButton')and object.Active then buttons+=1 end
  end
  if tab=='upgrade'then
   check(cards==13 and ordinary==5,'full upgrade tab includes five ordinary, six conveniences and two mastery cards')
   check(cardNames['Мастерство героя']and cardNames['Автокасса'],'render continues past the summary and through the last mastery card')
   for _,child in ipairs(parent:GetChildren())do if child:GetAttribute('UpgradeId')=='income'then
    for _,button in ipairs(child:GetChildren())do if button:IsA('TextButton')then button.Activated:Fire()end end
   end end
   check(#clicks==4 and clicks[1][1]=='choice','full upgrade tab buttons retain their actions')
  elseif tab=='shop'then
   check(cards==#require('MonetizationConfig').Products+#require('VIPConfig').Plans,'full shop displays all configured packs and VIP plans')
   check(buttons==#require('VIPConfig').Plans+1,'unconfigured packs remain disabled; VIP and atelier are usable')
  else check(#parent:GetChildren()>1,'read-only tabs retain their content after the currency formatter fix')end
  parent:Destroy()
 end end
 check(select('#',W.fmt(1234567))==1 and W.fmt(1234567)=='1 234 567','currency formatter exposes exactly one value in all call contexts')
 W.preview=preview
end
-- Real modal watcher + real reflow against a GUI canvas smaller than the camera/DPI viewport.
do
 local Access=require('InterfaceAccess');local previous=workspace.CurrentCamera
 local screen=Instance.new('ScreenGui');screen.AbsoluteSize=Vector2.new(1340,680);screen.Parent=playerGui
 local camera=Instance.new('Camera');camera.ViewportSize=Vector2.new(1675,900);workspace.CurrentCamera=camera
 local language=Instance.new('TextButton');language.Name='LanguageToggle';language.Position=UDim2.new(1,-66,0,44);language.Size=UDim2.fromOffset(44,44);language.Parent=screen
 local music=Instance.new('TextButton');music.Name='MusicToggle';music.Position=UDim2.new(1,-14,0,44);music.Size=UDim2.fromOffset(44,44);music.Parent=screen
 Access.start(screen)
 local fixtures={
  {name='MainMenu',width=.92,height=.86,minW=310,minH=290,maxW=920,maxH=760},
  {name='CosmeticShopV44',width=.9,height=.86,minW=300,minH=340,maxW=850,maxH=720},
  {name='Steal60NPCShopV35',width=.9,height=.8,minW=320,minH=340,maxW=760,maxH=650},
  {name='Steal60Handbook',width=.91,height=1,offset=-124,minW=0,minH=0,maxW=730,maxH=650},
  {name='HackVarietyV26',width=0,height=0,fixedW=550,fixedH=350,minW=0,minH=0,maxW=700,maxH=650},
 }
 local frames={}
 for _,f in ipairs(fixtures)do
  local frame=Instance.new('Frame');frame.Name=f.name;frame.Size=UDim2.new(f.width,f.fixedW or 0,f.height,f.fixedH or f.offset or 0);frame.Visible=false;frame.AbsoluteSize=Vector2.new(900,700)
  local limit=Instance.new('UISizeConstraint');limit.MinSize=Vector2.new(f.minW,f.minH);limit.MaxSize=Vector2.new(f.maxW,f.maxH);limit.Parent=frame
  frame.Parent=screen;frame.Visible=true;frames[#frames+1]=frame
 end
 for _,size in ipairs({{1340,680},{360,640},{640,360},{240,240},{1920,1080},{3840,2160}})do
  local width,height=size[1],size[2];screen.AbsoluteSize=Vector2.new(width,height);camera.ViewportSize=Vector2.new(width*1.25,height*1.25+36)
  for _=1,8 do services.RunService.Heartbeat:Fire(.3)end
  for index,frame in ipairs(frames)do local f=fixtures[index];local scale=frame:FindFirstChild('Steal60AdaptiveScale')
   check(frame.Position.X.Offset==0 and frame.Position.Y.Offset==0 and frame.Position.X.Scale==.5,'modal position uses the GUI canvas instead of scaled absolute pixels')
   local baseW=math.clamp(width*f.width+(f.fixedW or 0),f.minW,f.maxW);local baseH=math.clamp(height*f.height+(f.fixedH or f.offset or 0),f.minH,f.maxH)
   if Access.expanded(f.name)then baseW=width-24;baseH=height-Access.collectionTop(width,height)-12 end
   local cx=frame.Position.X.Scale*width;local cy=frame.Position.Y.Scale*height
   local top=Access.expanded(f.name)and Access.collectionTop(width,height)or(width<1160 and 100 or 10);local bottom=Access.expanded(f.name)and 12 or(f.name=='Steal60Handbook'and 124 or 24)
   if Access.expanded(f.name)then
    check(scale.Scale==1 and frame.Size.X.Scale==1 and frame.Size.X.Offset==-24,'selection windows fill the canvas without scaling up their text')
    if width>=700 then check(baseW>=width*.94 and baseH>=height*.94,'desktop selection window covers almost the whole usable screen')end
   end
   check(cx-baseW*scale.Scale/2>=11.9 and cx+baseW*scale.Scale/2<=width-11.9,'modal fits horizontally including minimum-size constraints')
   check(cy-baseH*scale.Scale/2>=top-.1 and cy+baseH*scale.Scale/2<=height-bottom+.1,'modal stays above the lower edge and outside reserved controls')
   local stable=scale.Scale;frame.AbsoluteSize=Vector2.new(9000,9000);services.RunService.Heartbeat:Fire(.3)
   check(math.abs(scale.Scale-stable)<.00001,'reflow does not feed rendered scale back into its own size calculation')
  end
  check(language.Position.Y.Offset+(language.Size.Y.Offset or 44)<=Access.collectionTop(width,height)or width>=700,'compact header controls stay above the expanded window')
 end
 for _,frame in ipairs(frames)do frame.Visible=false end
 check(language.Position.Y.Offset==44 and language.Position.X.Offset==-66 and music.Position.X.Offset==-14,'language and music restore their original positions after the menu closes')
 screen:Destroy();camera:Destroy();workspace.CurrentCamera=previous
end
print('PASS: full upgrade/shop and read-only tabs render under native color contracts; five modal types stay inside the actual GUI canvas under DPI/insets/resizing, without scale feedback')
