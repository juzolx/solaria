"""Fable round 1, fix 8: the curtain walls and the plateau's retaining faces were flat slabs.
Paints stone courses (2-tone rows, 1 px dark mortar, staggered joints) along each iso face, a
shadow under the battlements, moss in low joints; stacked rock on the plateau faces.
Works from the untouched originals (art/orig_*.png). Usage: py fix_r1_stone.py"""
import os
import random
import shutil
from PIL import Image


def orig(name):
    o = f"art/orig_{name}"
    if not os.path.exists(o):
        shutil.copy(f"art/{name}", o)
    return Image.open(o).convert("RGBA")


def mul(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def courses(im, face, slope, h, widths, lit, top_shadow=0, moss=0.0, seed=1):
    """Repaint the pixels where face(x, y, rgba) is true: rows run along the face (dy/dx = slope)."""
    rng = random.Random(seed)
    px = im.load()
    pts = [(x, y) for y in range(im.height) for x in range(im.width) if face(x, y, px[x, y])]
    top = {}
    for x, y in pts:
        top[x] = min(top.get(x, 9999), y)
    base = {}
    for x, y in pts:
        base.setdefault(x, px[x, y])
    tone = {}
    for x, y in pts:
        v = y - slope * x
        row = int(v // h)
        within = v - row * h
        wid = widths[row % len(widths)]
        off = (row * 5) % wid
        stone = (x + off) // wid
        f = tone.setdefault((row, stone), rng.choice((0.92, 1.0, 1.06)) if lit else rng.choice((0.9, 0.96, 1.0)))
        c = mul(F[face], f)
        if within < 1 or (x + off) % wid == 0:
            c = mul(F[face], 0.6)
            if moss and rng.random() < moss * max(0.0, (y - top[x]) / 40.0):
                c = (52, 66, 40, 255)
        elif within < 2 and lit:
            c = mul(c, 1.08)                      # the lit top edge of each stone
        if top_shadow and y - top[x] < top_shadow:
            c = mul(c, 0.78)                      # shadow under the battlements / the lip
        px[x, y] = c


F = {}

# curtain wall run: long face (x < 70) slopes down-right, short end face slopes up-right
w = orig("wall_run.png")
A = {(94, 92, 100), (153, 153, 164), (65, 63, 70), (56, 54, 61), (73, 71, 78)}
fa = lambda x, y, c: x < 70 and c[3] and c[:3] in A and y > 30
fb = lambda x, y, c: x >= 70 and c[3] and c[:3] in {(56, 54, 61), (94, 92, 100), (73, 71, 78)} and y > 50
F[fa], F[fb] = (94, 92, 100), (56, 54, 61)
courses(w, fa, 0.5, 6, (11, 9, 12, 10), True, top_shadow=4, moss=0.35, seed=3)
courses(w, fb, -0.5, 6, (9, 11, 10), False, top_shadow=3, moss=0.25, seed=4)
w.save("art/wall_run.png")

# plateau retaining faces: stacked rock (taller, uneven stones)
p = orig("plateau.png")
pa = lambda x, y, c: x < 228 and c[3] and abs(c[0] - 83) < 6 and abs(c[1] - 77) < 6 and abs(c[2] - 82) < 6
pb = lambda x, y, c: x >= 140 and c[3] and abs(c[0] - 59) < 5 and abs(c[1] - 54) < 5 and abs(c[2] - 61) < 5 and y > 120
F[pa], F[pb] = (83, 77, 82), (59, 54, 61)
courses(p, pa, 0.5, 7, (14, 9, 12, 16, 10), True, top_shadow=3, moss=0.5, seed=5)
courses(p, pb, -0.5, 7, (12, 15, 9, 13), False, top_shadow=3, moss=0.4, seed=6)
p.save("art/plateau.png")
print("stone courses painted")
