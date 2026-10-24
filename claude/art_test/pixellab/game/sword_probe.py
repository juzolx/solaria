import os, sys
from PIL import Image
PL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "classes"))
import recolour as R, weapons as W
K = ["n_idle0", "n_idle1", "n_atk0", "n_atk1", "n_atk2", "n_atk3", "n_hit", "s_idle0", "s_idle1"]
def comps(pts):
    pts, seen, out = set(pts), set(), []
    for p in pts:
        if p in seen: continue
        c, todo = set(), [p]; seen.add(p)
        while todo:
            x, y = todo.pop(); c.add((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if q in pts and q not in seen: seen.add(q); todo.append(q)
        out.append(c)
    return out
def blade(pts):
    """the most blade-like group: long for its size"""
    best, bs = set(), 0
    for c in comps(pts):
        if len(c) < 10: continue
        l = max((a[0]-b[0])**2 + (a[1]-b[1])**2 for a in c for b in c) ** 0.5
        sc = l * l / len(c)
        if sc > bs: best, bs = c, sc
    return best
def sword(im):
    px = im.load()
    met = {(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] and R.kind(px[x, y][:3]) in ("metal", "shirt")}
    s = blade(met)
    # add the outline ring around the blade
    ring = set()
    for (x, y) in s:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                q = (x + dx, y + dy)
                if q not in s and 0 <= q[0] < im.width and 0 <= q[1] < im.height and px[q][3] and R.kind(px[q][:3]) == "outline":
                    ring.add(q)
    return s, ring
sheet = Image.new("RGBA", (9 * 100 * 3, 2 * 100 * 3), (30, 28, 36, 255))
for r, b in enumerate("mf"):
    for i, k in enumerate(K):
        im = Image.open(f"base/{b}_{k}.png").convert("RGBA")
        s, ring = sword(im)
        d = im.copy(); p = d.load()
        for q in s: p[q] = (255, 0, 0, 255)
        for q in ring: p[q] = (255, 200, 0, 255)
        sheet.alpha_composite(d.resize((d.width * 3, d.height * 3), Image.NEAREST), (i * 300, r * 300))
        print(b, k, len(s), len(ring))
sheet.save("sword_probe.png")
