#!/usr/bin/env python3
"""Compile the FINAL XML, then execute selected real Luau sources with explicit Roblox test doubles."""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile, xml.etree.ElementTree as ET
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
 for name in ['ProfileStore','MonetizationService','HackRequirements','Cars','CarClasses','VIPConfig']:
  assert old[name]==sources[name],f'protected source changed: {name}'
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
assert 'TEST_GRANT_AMOUNT' not in sources['DataService'] and 'TestDiamonds' not in sources['LanguageCatalog']
assert 'HackResult' not in sources['Net'] and 'HackResult' not in sources['ClientMain']
assert 'setupDebug' not in sources['Main'] and 'ВРЕМЕННО' not in sources['Main']
assert 'local TARGET_PROTECTION = 2 * 60' in sources['SalonService']
assert 'local THEFT_COOLDOWN = 5 * 60' in sources['SalonService']
assert 'Net.notifyKey(player' in sources['DriveService']
# All new sources are installed at their expected paths.
for name in ['DeliveryBonus','EndlessParking','PetMount','ShelfTypography','Grammar','Messages','ProgressionConfig','InterfaceAccess']:
 assert parents[name]=='Shared'
assert parents['RoadsideArt']=='Services'
print('PASS: installer paths, infinite bounds, audio ingress and reset configuration',flush=True)

catalog={}
for key,value in re.findall(r'^\s*\[("(?:[^"\\]|\\.)*")\]\s*=\s*("(?:[^"\\]|\\.)*")',sources['LanguageCatalog'],re.M):
 key,value=json.loads(key),json.loads(value)
 assert key not in catalog,f'duplicate translation: {key}'
 catalog[key]=value
 assert not re.search('[А-Яа-яЁё]',value),f'Cyrillic in English: {key}'
 assert not re.search(r'\b(?:bonnet|boot|pavement|colours?|catalogue|centred|favourite|armour|till|showroom)\b',value,re.I),f'unreviewed terminology: {value}'
 def tokens(text):return re.findall(r'%(?:[0-9.]*[dfisq])',text.replace('%%',''))
 assert tokens(key)==tokens(value),f'format mismatch: {key}'
assert len(catalog)>1200
assert 'KatanaGrip' not in sources['AvatarStyleLibrary'] and 'Sword_guard' not in sources['AvatarStyleLibrary']
for name,source in sources.items():
 assert not re.search(r'\brequire\s*\(\s*\d',source),f'numeric require in {name}'
 assert not re.search(r'\bloadstring\s*\(',source),f'loadstring in {name}'
print(f'PASS: {len(catalog)} unique translations, format tokens, American English and no numeric require/loadstring',flush=True)

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
  allowed={'UpgradeConfig':{'income':{'growth':1.20},'doubleIncome':{'base':300}},'CoinUpgradeConfig':{'income':{'growth':1.55},'speed':{'growth':1.9},'botSpeed':{'growth':1.9}}}
  for name in ['UpgradeConfig','CoinUpgradeConfig']:
   changes=json.dumps(allowed[name],separators=(',',':')).replace('"growth":','growth=').replace('"base":','base=').replace('"income":','income=').replace('"doubleIncome":','doubleIncome=').replace('"speed":','speed=').replace('"botSpeed":','botSpeed=')
   parts.append(f'local previous=(function()\n{old[name]}\nend)();local current=require({json.dumps(name)});local changes={changes}\nfor _,u in ipairs(previous)do local v=current.ById[u.id];check(v~=nil,"upgrade ID retained");for _,k in ipairs({{"base","growth","max"}})do local expected=(changes[u.id]or{{}})[k]or u[k];check(v[k]==expected,"only authorized price/cap changes")end;if not changes[u.id]then for level=0,u.max-1 do check(previous.cost(u.id,level)==current.cost(u.id,level),"unaffected prices unchanged")end end end\n')
  parts.append(f'local oldProducts=(function()\n{old["MonetizationConfig"]}\nend)();local newProducts=require("MonetizationConfig")\nfor _,u in ipairs(oldProducts.Products)do local v=newProducts.ProductById[u.id];check(v.assetId==u.assetId and v.recommendedRobux==u.recommendedRobux,"product IDs and recommended Robux prices retained");check(v.diamonds==u.diamonds*.9,"diamond packs adjusted by exactly ten percent")end\n')
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
 cosmetic=sources['CosmeticService'];start=cosmetic.index('local function sanitized');end=cosmetic.index('local function shallow',start)
 parts.append('local Config=require("CosmeticConfig")\n'+cosmetic[start:end])
 parts.append((HERE/'scenarios.luau').read_text())
 bundle=temp/'run.luau';bundle.write_text('\n'.join(parts))
 subprocess.run([str(a.luau),str(bundle)],check=True)
print('NOT RUN: Roblox Engine/Studio rendering, physics, live DataStore and Marketplace integration.',flush=True)
