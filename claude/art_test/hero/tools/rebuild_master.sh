#!/bin/sh
# Rebuild the base hero layers from the trace + AI candidate, then apply the hand pixel pass.
cd "$(dirname "$0")"
PY=/c/ai/ComfyUI/python_embeded/python.exe
$PY -I mk_master.py
$PY -I bake.py /c/ai/art_raw/hero/r6_d64_s53_nat.png b_ body outfit_leather hair_short --fixed=weapon_sword
$PY -I - <<'PYEOF'
import sys; sys.path.insert(0,'.')
import hero
g,_=hero.load('weapon_sword'); sh=hero.smooth(g,hero.auto_shade(g,None,0))
open('layers/b_weapon_sword.txt','w').write('\n'.join(''.join(r) for r in g)+'\n')
open('layers/b_weapon_sword.shade.txt','w').write('\n'.join(''.join(str(sh[y,x]) if g[y,x]!='.' else '.' for x in range(hero.W)) for y in range(hero.H))+'\n')
PYEOF
$PY -I fix_master.py
$PY -I - <<'PYEOF'
g=[r.rstrip('\n') for r in open('layers/b_body.txt')]; s=[r.rstrip('\n') for r in open('layers/b_body.shade.txt')]
open('layers/b_body_front.txt','w').write('\n'.join(''.join(c if c=='F' else '.' for c in r) for r in g)+'\n')
open('layers/b_body_front.shade.txt','w').write('\n'.join(''.join(s[y][x] if g[y][x]=='F' else '.' for x in range(len(g[y]))) for y in range(len(g)))+'\n')
PYEOF
