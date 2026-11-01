#!/usr/bin/env python3
"""Compile the FINAL XML, then execute selected real Luau sources with explicit Roblox test doubles."""
import argparse, hashlib, json, pathlib, subprocess, tempfile, xml.etree.ElementTree as ET
HERE=pathlib.Path(__file__).resolve().parent
p=argparse.ArgumentParser();p.add_argument('--luau',required=True,type=pathlib.Path);p.add_argument('--compiler',required=True,type=pathlib.Path);p.add_argument('--baseline',type=pathlib.Path);p.add_argument('--xml',type=pathlib.Path,default=HERE.parent/'Steal60_v66.rbxmx');a=p.parse_args()
def extract(path):
 tree=ET.parse(path);sources={};parents={};refs=[]
 def visit(item,parent=''):
  props=item.find('Properties');name=props.find("string[@name='Name']").text;src=props.find("ProtectedString[@name='Source']")
  refs.append(item.get('referent'))
  if src is not None:
   assert name not in sources, f'duplicate script name {name}'
   sources[name]=src.text or '';parents[name]=parent
  for child in item.findall('Item'):visit(child,name)
 for item in tree.getroot().findall('Item'):visit(item)
 assert len(refs)==len(set(refs)), 'duplicate XML referent'
 return tree,sources,parents
r,sources,parents=extract(a.xml)
print('Final XML SHA-256:',hashlib.sha256(a.xml.read_bytes()).hexdigest(),flush=True)
print('XML instances:',len(list(r.iter('Item'))),'script sources:',len(sources),flush=True)
if a.baseline:
 _,old,_=extract(a.baseline)
 for name in ['ProfileStore','MonetizationService','HackRequirements','Cars','CarClasses','MonetizationConfig','VIPConfig']:
  assert old[name]==sources[name],f'protected source changed: {name}'
 for name in ['UpgradeConfig','CoinUpgradeConfig']:
  # Runtime checks below compare every old/new price, ID, cap, growth in the same Luau VM.
  pass
 print('Baseline SHA-256:',hashlib.sha256(a.baseline.read_bytes()).hexdigest(),flush=True)
 print('PASS: v65 durable storage, payment processing, skill predicate and catalog sources byte-identical',flush=True)
# No undeclared remote bypass: new SetAudio uses the existing ingress wrapper.
assert 'SetAudio={2,3,2,function(volume,muted)return finite(volume)' in sources['SecurityService']
assert 'Net.SetAudio.OnServerEvent:Connect(audio)' in sources['LanguageService']
assert '"SetAudio"' in sources['Net']
assert 'processedReceipts' in sources['ProfileStore']
assert 'local worldEnd=T.SalonZoneLength' in sources['TrackBuilder']
assert 'PermanentMapEnd' not in sources['TrackBuilder'] and 'EndWall' not in sources['DistrictBuilder']
assert "for i in pairs(needed) do" in sources['DistrictManager']
assert 'local ENABLE_ONE_TIME_TEST_GRANT = false' in sources['DataService']
# All new sources are installed at their expected paths.
for name in ['DeliveryBonus','EndlessParking','PetMount','ShelfTypography']:
 assert parents[name]=='Shared'
assert parents['RoadsideArt']=='Services'
print('PASS: installer paths, infinite bounds, audio ingress and reset configuration',flush=True)
with tempfile.TemporaryDirectory(prefix='steal60-v66-')as temp:
 temp=pathlib.Path(temp)
 paths=[]
 for name,source in sources.items():
  path=temp/(name+'.luau');path.write_text(source);paths.append(str(path))
 subprocess.run([str(a.compiler),'--null',*paths],check=True)
 mock=(HERE/'roblox_mock.luau').read_text();parts=[mock]
 for name in sources:
  parent='config'if parents[name]=='Config'else 'serviceFolder'if parents[name]=='Services'else 'shared'
  parts.append(f'moduleRef({json.dumps(name)},{parent})\n')
 for name,source in sources.items():
  parts.append(f'loaders[{json.dumps(name)}]=function()\nlocal script=refs[{json.dumps(name)}]\n{source}\nend\n')
 if a.baseline:
  for name in ['UpgradeConfig','CoinUpgradeConfig']:
   parts.append(f'local old=(function()\n{old[name]}\nend)();local new=require({json.dumps(name)})\nfor _,u in ipairs(old)do local v=new.ById[u.id];check(v~=nil,"upgrade ID preserved");for _,k in ipairs({{"base","growth","max"}})do check(v[k]==u[k],"upgrade price/cap unchanged")end;for level=0,u.max-1 do check(old.cost(u.id,level)==new.cost(u.id,level),"exact upgrade price unchanged")end end\n')
 # Exercise the actual server bumper function without loading unrelated server services.
 drive=sources['DriveService'];start=drive.index('local function knockCones');end=drive.index('local function isRoadBlocked',start)
 parts.append('local function horizontal(v)local flat=Vector3.new(v.X,0,v.Z);return flat.Magnitude>.01 and flat.Unit or Vector3.xAxis end\nlocal coneCache={}\n'+drive[start:end])
 salon=sources['SalonService'];start=salon.index('local Balance=require');end=salon.index('-- Money remains in the till',start)
 parts.append('''local function previewFor(data,id,currency,maximum)
 local Shared=shared;local Settings=require('Settings');local Loot=require('Loot');local Rarity=require('Rarity');local VARIANT_MULT={}
 local CosmeticConfig=require('CosmeticConfig')
 local function displayList()return {}end
 local function partIncomeBoost()return 0 end
 local function fmt(n)local s=tostring(math.floor(n));local out=s:reverse():gsub('(%d%d%d)','%1 '):reverse();return(out:gsub('^ ',''))end
 local Monetization={has=function(_,key)return(data.upgrades[key]or 0)>0 end,tillHours=function()return(data.upgrades.till48h or 0)>0 and 48 or 12 end,incomeMultiplier=function()return(data.upgrades.doubleIncome or 0)>0 and 2 or 1 end}
 '''+salon[start:end]+'''
 local current,following=upgradePreview(data,player,id,currency,maximum)
 return current,following,computeIncome(data,player)*3600
 end
 ''')
 manager=sources['DistrictManager'];start=manager.index('local function neededSet()');end=manager.index('-- API',start)
 parts.append('''local function lifecycleFor()
 local Layout=require('TrackLayout');local LOAD={Behind=1,Ahead=1,UnloadDelay=0}
 local Builder={build=function(index)local model=Instance.new('Model');model.Name='Lifecycle'..index;return model end}
 local loaded,loading,unusedSince,loadedCbs,unloadedCbs={},{},{},{},{}
 local folder=Instance.new('Folder')
 '''+manager[start:end]+'''
 return step,loaded
 end
 ''')
 parts.append((HERE/'scenarios.luau').read_text())
 bundle=temp/'run.luau';bundle.write_text('\n'.join(parts))
 subprocess.run([str(a.luau),str(bundle)],check=True)
print('NOT RUN: Roblox Engine/Studio rendering, physics, live DataStore and Marketplace integration.',flush=True)
