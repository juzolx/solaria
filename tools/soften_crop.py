"""Shapes a box-cropped sprite's straight bottom and cut sides into a natural edge (fable r6:
The Pale Tide and Umibozu ended in a hard rectangle). Pixels only, no generation: the cut follows
two summed waves, the corners round off, the new edge takes the art's own outline colour and the
row inside it its lightest water colour as foam.
    py tools/soften_crop.py art/enemies/calamity_3.png [more.png ...]"""
import math, sys
from collections import Counter
from PIL import Image

def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]

def soften(path):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    x0, y0, x1, y1 = im.getbbox()
    bw, bh = x1 - x0, y1 - y0
    solid = lambda x, y: 0 <= x < w and 0 <= y < h and px[x, y][3] > 25
    # the outline: the commonest colour on the silhouette's top half border; foam: the lightest
    # common colour in the bottom rows
    edge = Counter(px[x, y][:3] for y in range(y0, y0 + bh // 2) for x in range(x0, x1)
                   if solid(x, y) and not all(solid(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))))
    outline = min((c for c, _ in edge.most_common(6)), key=lum)
    low = Counter(px[x, y][:3] for y in range(y1 - bh // 5, y1) for x in range(x0, x1) if solid(x, y))
    foam = max((c for c, _ in low.most_common(12)), key=lum)
    cut = set()
    # the bottom: two waves, 0-6 rows deep, corners rounded over the last 14 columns
    for x in range(x0, x1):
        d = 2.2 * (1 + math.sin(2 * math.pi * (x - x0) / 23.0 + 0.6)) + 1.2 * (1 + math.sin(2 * math.pi * (x - x0) / 9.0 + 2.0))
        t = min(x - x0, x1 - 1 - x)
        if t < 14:
            d += (14 - t) ** 2 / 14.0
        for k in range(int(round(d))):
            cut.add((x, y1 - 1 - k))
    # cut sides: ragged spray where a side runs straight down to the bottom
    for side, col, step in ((0, x0, 1), (1, x1 - 1, -1)):
        run = 0
        y = y1 - 1
        while y >= y0 and solid(col, y):
            run += 1
            y -= 1
        if run < bh * 0.15:
            continue
        for y in range(y1 - run, y1):
            c = 1.3 * (1 + math.sin(2 * math.pi * y / 7.0 + side)) + 0.8 * (1 + math.sin(2 * math.pi * y / 3.1 + 1.0))
            c += max(0.0, (y - (y1 - run)) / run) * 3.0   # wider toward the floor: the water spills
            for k in range(int(round(c))):
                cut.add((col + step * k, y))
    for x, y in cut:
        px[x, y] = (0, 0, 0, 0)
    # keep the feet on the floor: the deepest wave never lifts the middle off the bottom row
    # (the cut above always leaves the troughs at d < 0.5 there)
    # re-edge: outline on the new border, foam just inside it on the crests
    border = [(x, y) for x in range(x0, x1) for y in range(y0, y1) if solid(x, y)
              and any((x + dx, y + dy) in cut for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    inner = set()
    for x, y in border:
        px[x, y] = outline + (255,)
        for dx, dy in ((0, -1), (1, 0), (-1, 0)):
            if solid(x + dx, y + dy) and (x + dx, y + dy) not in border:
                inner.add((x + dx, y + dy))
    bset = set(border)
    for x, y in inner:
        if (x, y) not in bset and (x // 2 + y) % 3 != 0 and all(solid(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            px[x, y] = foam + (255,)
    # any other pixel the cut left bare (the art rule: every edge pixel is outline)
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 0 and px[x, y][:3] != outline and any(
                    0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] == 0
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))) and (x, y) in _near(cut):
                px[x, y] = outline + (255,)
    im.save(path)
    return outline, foam, len(cut)

def _near(cut):
    out = set()
    for x, y in cut:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                out.add((x + dx, y + dy))
    return out

if __name__ == "__main__":
    for p in sys.argv[1:]:
        print(p, soften(p))
