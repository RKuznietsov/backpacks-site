#!/usr/bin/env python3
"""Evaluate the actual final XML's pure Luau price functions; constant-rate time estimates are NOT gameplay telemetry."""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile, xml.etree.ElementTree as ET
ROOT=pathlib.Path(__file__).resolve().parent.parent
p=argparse.ArgumentParser();p.add_argument('--luau',required=True,type=pathlib.Path);a=p.parse_args()
xml=ROOT/'Steal60_v66.rbxmx';sources={}
for item in ET.parse(xml).iter('Item'):
 source=item.find("Properties/ProtectedString[@name='Source']")
 if source is not None:sources[item.find("Properties/string[@name='Name']").text]=source.text
code="local modules={}\nlocal Color3={fromRGB=function(...)return {...}end,new=function(...)return {...}end}\nlocal config=setmetatable({},{__index=function(_,key)return key end})\nlocal script={Parent={Config=config,EconomyBalance='EconomyBalance'}}\nlocal function require(key)return assert(modules[key],key)end\n"
for name in ['EconomyBalance','CoinUpgradeConfig','UpgradeConfig','Settings','UpgradePolicy','CosmeticConfig']:
 code+='modules.'+name+'=(function()\n'+sources[name]+'\nend)()\n'
code+='local Balance=modules.EconomyBalance;local Coin=modules.CoinUpgradeConfig;local Diamond=modules.UpgradeConfig;local Policy=modules.UpgradePolicy;local Cosmetic=modules.CosmeticConfig\n'
code+='for _,c in ipairs({{name="hero",max=30},{name="pet",max=60}})do for level=0,c.max-1 do print("mastery",c.name,level,Balance.masteryCost(c.name,level))end end\n'
code+='for _,def in ipairs(Coin)do for level=0,def.max-1 do print("coin",def.id,level,Coin.cost(def.id,level))end end\n'
code+='for _,def in ipairs(Diamond)do for level=0,def.max-1 do print("diamond",def.id,level,Diamond.cost(def.id,level))end end\n'
code+='for _,def in ipairs(Coin)do for _,seed in ipairs(Policy.choices({coinUpgrades={},upgrades={}},def.id))do for level=0,seed.max-1 do local d={coinUpgrades={},upgrades={}};d[seed.id=="diamond"and"upgrades"or"coinUpgrades"][def.id]=level;local option=Policy.find(d,def.id,seed.id);print("choice",def.id,seed.id,level,option.coinCost,option.diamondCost)end end end\n'
code+='for _,def in ipairs(Cosmetic.List)do if def.price then print("cosmetic",def.id,0,def.price)end end\n'
with tempfile.TemporaryDirectory(prefix='steal60-prices-')as tmp:
 path=pathlib.Path(tmp)/'prices.luau';path.write_text(code)
 output=subprocess.check_output([str(a.luau),str(path)],text=True)
report={'final_xml_sha256':hashlib.sha256(xml.read_bytes()).hexdigest(),
 'method':'Actual final XML EconomyBalance, CoinUpgradeConfig, UpgradeConfig, UpgradePolicy and CosmeticConfig evaluated in official Luau. unified_upgrade_choices is the current shop; *_reference_tracks are the compatible saved-counter definitions, not an additional shop. Time estimates divide by a constant 500000 coins/hour; no travel, active rewards, reinvestment, offline limits or growth simulated.',
 'reference_coins_per_hour':500000,'coin_cosmetics':{},'mastery':{},'coin_reference_tracks':{},'diamond_reference_tracks':{},'unified_upgrade_choices':{},'diamond_cosmetics':{}}
for line in output.splitlines():
 fields=line.split('\t');kind,key=fields[:2]
 if kind=='choice':
  _,_,choice,level,coin,diamond=fields
  item=report['unified_upgrade_choices'].setdefault(key,{}).setdefault(choice,{'coin_prices':[],'diamond_prices':[]})
  item['coin_prices'].append(int(coin));item['diamond_prices'].append(int(diamond));continue
 _,_,level,cost=fields
 if kind=='cosmetic':report['diamond_cosmetics'][key]=int(cost);continue
 group=report[{'mastery':'mastery','coin':'coin_reference_tracks','diamond':'diamond_reference_tracks'}[kind]];group.setdefault(key,{'prices':[]})['prices'].append(int(cost))
for group in [report['mastery'],report['coin_reference_tracks'],report['diamond_reference_tracks']]:
 for item in group.values():
  values=item['prices'];item.update(first=values[0],last=values[-1],total=sum(values),last_hours_at_reference_rate=values[-1]/500000)
  if group is report['mastery']:item.update(first_nine_total=sum(values[:9]),first_nine_hours_at_reference_rate=sum(values[:9])/500000)
for choices in report['unified_upgrade_choices'].values():
 for item in choices.values():
  item['levels']=len(item['coin_prices'])
  for currency in ['coin','diamond']:
   values=item[currency+'_prices'];item[currency+'_total']=sum(values)
for line in sources['CosmeticConfig'].splitlines():
 match=re.search(r"id=['\"]([^'\"]+)['\"].*?priceCoins=(\d+)",line)
 if match:report['coin_cosmetics'][match[1]]=int(match[2])
report['pet_license']={currency:int(re.search(r'PET_LICENSE_'+currency.upper()+r'=(\d+)',sources['CosmeticConfig'])[1])for currency in ['coins','diamonds']}
(ROOT/'economy-data.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('PASS: final XML price functions evaluated; economy-data.json written')
for key,item in report['mastery'].items():print(key,'first',item['first'],'nine',item['first_nine_total'],'last',item['last'],'total',item['total'])
for key,choices in report['unified_upgrade_choices'].items():
 for choice,item in choices.items():print(key,choice,'levels',item['levels'],'coins',item['coin_total'],'diamonds',item['diamond_total'])
