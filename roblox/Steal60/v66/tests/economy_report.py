#!/usr/bin/env python3
"""Evaluate the actual final XML's pure Luau price functions; constant-rate time estimates are NOT gameplay telemetry."""
import argparse, hashlib, json, pathlib, re, subprocess, tempfile, xml.etree.ElementTree as ET
ROOT=pathlib.Path(__file__).resolve().parent.parent
p=argparse.ArgumentParser();p.add_argument('--luau',required=True,type=pathlib.Path);a=p.parse_args()
xml=ROOT/'Steal60_v66.rbxmx';sources={}
for item in ET.parse(xml).iter('Item'):
 source=item.find("Properties/ProtectedString[@name='Source']")
 if source is not None:sources[item.find("Properties/string[@name='Name']").text]=source.text
code='local Balance=(function()\n'+sources['EconomyBalance']+'\nend)()\nlocal Coin=(function()\n'+sources['CoinUpgradeConfig']+'\nend)()\n'
code+='for _,c in ipairs({{name="hero",max=30},{name="pet",max=60}})do for level=0,c.max-1 do print("mastery",c.name,level,Balance.masteryCost(c.name,level))end end\n'
code+='for _,def in ipairs(Coin)do for level=0,def.max-1 do print("coin",def.id,level,Coin.cost(def.id,level))end end\n'
with tempfile.TemporaryDirectory(prefix='steal60-prices-')as tmp:
 path=pathlib.Path(tmp)/'prices.luau';path.write_text(code)
 output=subprocess.check_output([str(a.luau),str(path)],text=True)
report={'final_xml_sha256':hashlib.sha256(xml.read_bytes()).hexdigest(),
 'method':'Actual EconomyBalance.masteryCost and CoinUpgradeConfig.cost from final XML evaluated in official Luau. Time estimates divide by a constant 500000 coins/hour; no travel, active rewards, reinvestment, offline limits or growth simulated.',
 'reference_coins_per_hour':500000,'coin_cosmetics':{},'mastery':{},'coin_upgrades':{}}
for kind,key,level,cost in [line.split('\t')for line in output.splitlines()]:
 group=report['mastery'if kind=='mastery'else'coin_upgrades'];group.setdefault(key,{'prices':[]})['prices'].append(int(cost))
for group in [report['mastery'],report['coin_upgrades']]:
 for item in group.values():
  values=item['prices'];item.update(first=values[0],last=values[-1],total=sum(values),last_hours_at_reference_rate=values[-1]/500000)
  if group is report['mastery']:item.update(first_nine_total=sum(values[:9]),first_nine_hours_at_reference_rate=sum(values[:9])/500000)
for line in sources['CosmeticConfig'].splitlines():
 match=re.search(r"id=['\"]([^'\"]+)['\"].*?priceCoins=(\d+)",line)
 if match:report['coin_cosmetics'][match[1]]=int(match[2])
report['pet_license']={currency:int(re.search(r'PET_LICENSE_'+currency.upper()+r'=(\d+)',sources['CosmeticConfig'])[1])for currency in ['coins','diamonds']}
(ROOT/'economy-data.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('PASS: final XML price functions evaluated; economy-data.json written')
for key,item in report['mastery'].items():print(key,'first',item['first'],'nine',item['first_nine_total'],'last',item['last'],'total',item['total'])
for key,item in report['coin_upgrades'].items():print(key,'first',item['first'],'last',item['last'],'total',item['total'])
