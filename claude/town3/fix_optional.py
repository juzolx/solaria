"""Optional art pass after the merge: narrower wall lane, shorter towers, a wooden footbridge with
reeds, real flowerbeds in the church garden. Usage: py fix_optional.py"""
import json
import random
from PIL import Image, ImageDraw


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


# towers: cut 32 px out of the shaft so they sit lower next to the church and the houses
t = Image.open("art/tower.png").convert("RGBA")
cut0, cut1 = 100, 132
short = Image.new("RGBA", (t.width, t.height - (cut1 - cut0)), (0, 0, 0, 0))
short.paste(t.crop((0, 0, t.width, cut0)), (0, 0))
short.paste(t.crop((0, cut1, t.width, t.height)), (0, cut0))
short.save("art/tower_short.png")
s = json.load(open("sprites.json"))
for k in [k for k in s if k.startswith("tower")]:
    s[k] = {"file": "tower_short.png"}
json.dump(s, open("sprites.json", "w", newline="\n"), indent=1)

# flowerbed and plank tiles (32x17 ground diamonds, drawn in code on the town grid)
rng = random.Random(9)
inside = lambda x, y: abs(x - 15.5) / 16 + abs(y - 8) / 8.5 <= 1.0
bed = Image.new("RGBA", (32, 17), (0, 0, 0, 0))
bp = bed.load()
for y in range(17):
    for x in range(32):
        if inside(x, y):
            edge = abs(x - 15.5) / 16 + abs(y - 8) / 8.5 > 0.82
            bp[x, y] = (58, 44, 34, 255) if edge else (44, 58, 34, 255)
for _ in range(46):                                   # flowers: 2-pixel blooms on dark leaves
    x, y = rng.randint(4, 27), rng.randint(3, 13)
    if inside(x, y) and abs(x - 15.5) / 16 + abs(y - 8) / 8.5 < 0.75:
        c = rng.choice([(196, 70, 70), (214, 176, 70), (220, 214, 200), (150, 96, 170), (200, 120, 150)])
        bp[x, y] = c + (255,)
        if x + 1 < 32:
            bp[x + 1, y] = tuple(int(v * .75) for v in c) + (255,)
bed.save("art/tiles_extra_flowerbed.png")
plank = Image.new("RGBA", (32, 17), (0, 0, 0, 0))
pp = plank.load()
for y in range(17):
    for x in range(32):
        if inside(x, y):
            k = (x + 2 * y) // 4 % 2                  # planks run across the river (along j)
            pp[x, y] = (106, 76, 50, 255) if k else (88, 62, 40, 255)
            if (x + 2 * y) % 4 == 0:
                pp[x, y] = (52, 36, 26, 255)
plank.save("art/tiles_extra_planks.png")

# reeds: a small clump, outlined
reed = Image.new("RGBA", (14, 16), (0, 0, 0, 0))
rd = ImageDraw.Draw(reed)
for x, h in ((3, 11), (6, 14), (9, 10), (11, 12)):
    rd.line([(x, 15), (x, 15 - h)], fill=(14, 8, 18, 255), width=3)
for x, h in ((3, 11), (6, 14), (9, 10), (11, 12)):
    rd.line([(x, 15), (x, 16 - h)], fill=(84, 104, 58, 255))
    rd.point((x, 15 - h + 1), fill=(126, 96, 56, 255))
reed.save("art/reeds.png")

patch("layout.py", [
    ('    ("road", 1, 35, 38, 36),      # wall lane (one row clear of the wall so the wall never hides it)',
     '    ("road", 1, 35, 38, 35),      # wall lane: one row, clear of the wall so the wall never hides it'),
    ('    ("bridge", 6, 27, 9, 28),     # footbridge west', '    ("planks", 7, 27, 8, 28),     # wooden footbridge on the west lane'),
])
patch("compose.py", [
    ('"path": "cobble", "dirt": "dirt", "garden": "grass",', '"path": "cobble", "dirt": "dirt", "garden": "grass", "planks": "planks",'),
    ('''def load_tiles():
    t = {}''', '''def load_tiles():
    t = {"planks": [load("tiles_extra_planks.png")]}'''),
])
patch("walk.py", [('"plateau", "path", "dirt"}', '"plateau", "path", "dirt", "planks"}')])
patch("decor.py", [
    # church garden: four real 2x2 flowerbeds (Regular), benches between them; pots removed
    ('''        for i, j in ((3, 2), (4, 2), (3, 3), (8, 2), (9, 2), (9, 3), (3, 5), (4, 6), (9, 5), (8, 6), (10, 4), (2, 4)):
            d.append((P32, 14 if (i + j) % 2 else 15, i, j))''', '''        d += [("bed", 0, i, j) for i0, j0 in ((3, 2), (8, 2), (3, 5), (8, 5)) for i in (i0, i0 + 1) for j in (j0, j0 + 1)]'''),
    # rails on the footbridge and reeds along the river banks
    ('''    # river side:''', '''    d += [("fence", "wood", 7, 27, "j"), ("fence", "wood", 7, 28, "j"), ("fence", "wood", 9, 27, "j"), ("fence", "wood", 9, 28, "j")]
    for i, j in ((3, 26), (5, 29), (11, 26), (13, 29), (25, 26), (27, 29), (31, 26), (33, 29), (36, 26)):
        d.append(("reeds", 0, i, j))
    # river side:'''),
])
patch("compose.py", [
    ('''    for e in deco:
        if e[0] == "fence":''', '''    bed = load("tiles_extra_flowerbed.png")
    for e in [e for e in deco if e[0] == "bed"]:      # flowerbeds are ground: drawn before every sprite
        x, y = at(e[2], e[3])
        img.alpha_composite(bed, (int(x) - 16, int(y)))
    GROUND_IMG[:] = [img.copy()] if GROUND_IMG else []
    deco = [e for e in deco if e[0] != "bed"]
    for e in deco:
        if e[0] == "fence":'''),
    ('''            im = load(f"folk/{n}.png" if name == "folk" else f"{name}/{'t' if name == 'trees' else 'p'}{n}.png")''',
     '''            im = load("reeds.png" if name == "reeds" else f"folk/{n}.png" if name == "folk" else f"{name}/{'t' if name == 'trees' else 'p'}{n}.png")'''),
])
print("optional patched")
