from pathlib import Path
import re
# Scene-only, idempotent pass; run again after regenerating chamber scenes.
for i in range(6):
 p=Path(f'scenes/chambers/chamber_{i}.tscn'); text=p.read_text(encoding="utf-8")
 blocks=re.split(r'(?=\[node )',text)
 for j,b in enumerate(blocks):
  if not b.startswith('[node '): continue
  name=re.search(r'name="([^"]+)"',b)[1]
  disable=(name=='WarmHaze' or (i==4 and name=='Haze') or (i==3 and name in ['ChasmGlow','Fill1','Fill3','Fill5']) or (i==0 and name in ['ShaftSpill1','ShaftSpill3']))
  if disable and 'enabled = false' not in b:
   b=b.replace('\n','\nenabled = false\n',1)
  if i==1 and name.startswith('TubewormWall'): b=b.replace('stalk_count = 22','stalk_count = 14')
  if i==2 and name=='CeilingWorms': b=b.replace('stalk_count = 8','stalk_count = 4')
  if i==0 and name.startswith('Worms') and 's_worm' in b:
   n=int(name[5:]); rows=[(-3000,3),(-2300,4),(-1800,5),(-1400,6),(-1050,7),(-720,8)]
   if n>=len(rows): b=''
   else:
    y,count=rows[n]
    b=re.sub(r'position = Vector2\(([^,]+), [^)]+\)',rf'position = Vector2(\1, {y})',b)
    b=re.sub(r'stalk_count = \d+',f'stalk_count = {count}',b)
  if i==0 and name.startswith('Lunger') and 's_lunge' in b:
   n=int(name[6:]); y=[-2600,-2050,-1400,-820][n]
   b=re.sub(r'position = Vector2\(([^,]+), [^)]+\)',rf'position = Vector2(\1, {y})',b)
  blocks[j]=b
 p.write_text(''.join(blocks), encoding='utf-8')
