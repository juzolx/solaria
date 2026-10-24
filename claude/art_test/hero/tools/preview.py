"""Preview: python -I preview.py OUT.png layer1 layer2 ... [--ref native_ai.png] [--ai] [--z 8]
Shows the render zoomed, next to the AI reference (same zoom), plus 1x and 3x."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, r"C:\gamedev\solaria_wt_newart\claude\art_test\hero\tools")
import hero

args = sys.argv[1:]
out = args.pop(0)
ref = None; use_ai = False; z = 8; ramps = {}
names = []
i = 0
while i < len(args):
    a = args[i]
    if a == "--ref": ref = args[i + 1]; i += 2; continue
    if a == "--ai": use_ai = True; i += 1; continue
    if a == "--z": z = int(args[i + 1]); i += 2; continue
    if a == "--ramp": k, v = args[i + 1].split("="); ramps[k] = v; i += 2; continue
    names.append(a); i += 1
ai = None
if ref and use_ai:
    r = np.asarray(Image.open(ref).convert("RGB")).astype(float).mean(2)
    ai = np.zeros((hero.H, hero.W)); ai[:min(hero.H, r.shape[0]), :min(hero.W, r.shape[1])] = r[:hero.H, :hero.W]
im, mat, sh = hero.render(names, ramps=ramps, ai=ai)
bg = hero.on_bg(im)
panels = [hero.zoom(bg, z)]
if ref:
    panels.append(hero.zoom(hero.on_bg(Image.open(ref).convert("RGBA")), z))
small = Image.new("RGBA", (im.width * 3 + 10, im.height * 4 + 20), (52, 48, 60, 255))
small.alpha_composite(bg, (0, 0)); small.alpha_composite(hero.zoom(bg, 3), (0, im.height + 10))
panels.append(small)
Wt = sum(p.width + 16 for p in panels); Ht = max(p.height for p in panels)
s = Image.new("RGBA", (Wt, Ht), (30, 28, 36, 255)); x = 0
for p in panels:
    s.alpha_composite(p, (x, 0)); x += p.width + 16
s.save(out)
im.save(out[:-4] + "_1x.png")
