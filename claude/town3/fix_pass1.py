"""Fable critique pass 1 fixes (one-off source patch). Usage: py fix_pass1.py"""
import json
import re


def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8").write(s)


# --- layout: Tavern one cell SE of the stairs; Shop and Blacksmith swap so the Shop isn't behind the chimney
patch("layout.py", [
    ('("tavern", "Tavern", 22, 10, 26, 14, "j", 24)', '("tavern", "Tavern", 23, 10, 27, 14, "j", 24)'),
    ('("shop", "Shop", 9, 15, 12, 18, "j", 20)', '("shop", "Shop", 9, 21, 12, 24, "i", 20)'),
    ('("smith", "Blacksmith", 9, 21, 12, 24, "i", 20)', '("smith", "Blacksmith", 9, 15, 12, 18, "i", 20)'),
])

# --- sprites: Shop door now on its +i face (flip), Vault warmer
s = json.load(open("sprites.json"))
s["shop"] = {"file": "shop.png", "flip": True}
s["stash"] = {"file": "stash_warm.png"}
json.dump(s, open("sprites.json", "w"), indent=1)

# --- decor
patch("decor.py", [
    # Vault L2: a gilded sign instead of chests blocking the door
    ('"stash": (15, (3, 4))', '"stash": (6, (3, 15))'),
    # fewer lamps: one side of the main street at a time, one per lane segment
    ('''    for j in (11, 15, 25, 31, 35):
        d += [lamp(17, j), lamp(22, j)]
    d += [lamp(8, 12), lamp(8, 26), lamp(31, 12), lamp(31, 22), lamp(13, 9), lamp(26, 9)]''',
     '''    d += [lamp(17, 11), lamp(22, 25), lamp(17, 31), lamp(22, 35), lamp(8, 12), lamp(8, 26), lamp(31, 22), lamp(13, 9)]'''),
    # market: no hay pile against the yellow stall
    ('(P48, 9, 14, 20), (P48, 15, 23, 21),', '(P48, 9, 14, 20),'),
    # blacksmith / shop yard props follow the swap
    ('''    d += [(P32, 17, 13, 22), (P32, 18, 13, 24), (P32, 42, 13, 21), (P32, 16, 9, 25), (P32, 33, 11, 25)]''',
     '''    d += [(P32, 17, 13, 16), (P32, 18, 13, 18), (P32, 42, 13, 15), (P32, 16, 9, 19), (P32, 33, 11, 19)]'''),
    ('''    d += [(P32, 1, 9, 19), (P32, 2, 10, 19), (P32, 39, 12, 19)]''', '''    d += [(P32, 1, 13, 24), (P32, 2, 13, 21)]'''),
    ('(12.5, 22.5, 14, (255, 120, 50), 44)', '(12.5, 16.5, 14, (255, 120, 50), 44)'),
    # pet pen: trough, lantern, hay
    ('''    d += [(P48, 14, 34, 32), (P48, 15, 36, 33), (P32, 58, 32, 32), (P32, 29, 31, 33)]''',
     '''    d += [(P48, 14, 34, 32), (P48, 15, 36, 33), (P32, 58, 32, 32), (P32, 59, 35, 31), (UP, 5, 31, 31)]
    LIGHTS.append((31.5, 31.5, 34, (255, 190, 110), 36))'''),
    # trees: drop the loose singles (dead trees on the road, small trees by the square)
    ('''    for i, j in ((12, 2), (12, 5), (2, 7)):      # dead trees by the graveyard
        t.append((rng.choice((6, 7)), i, j, 0, 0))
''', '''    for i, j in ((2, 5), (11, 2)):               # dead trees inside the graveyard fence
        t.append((rng.choice((6, 7)), i, j, 0, 0))
'''),
    ('''    for i, j in ((2, 24), (36, 21), (37, 23),
                 (12, 10), (11, 12), (24, 26), (14, 26), (38, 8), (30, 8)):
        add(i, j, oaks + small)''', '''    for i, j in ((2, 24), (3, 25), (36, 21), (37, 22), (37, 24), (36, 36), (37, 35), (35, 37)):
        add(i, j, oaks + small)'''),
    # Hardcore: dead tree and graves in front of the ruined church
    ('''    d += [(P48, 12, 6, 4), (P48, 13, 10, 3), (P32, 53, 1, 1), (P32, 54, 11, 1)]''',
     '''    d += [(P48, 12, 6, 4), (P48, 13, 10, 3), (P32, 53, 1, 1), (P32, 54, 11, 1)]
    if HARDCORE:
        d += [(P32, 6, 2, 17), (P32, 63, 3, 18), (P32, 60, 4, 17), (P32, 9, 1, 18), (TREE, 7, 5, 9)]'''),
    # empty lot: a lantern and a sign on the street side
    ('''    e += [(P32, 19, x1, y1), (P32, 33, x0 + 1, y0 + 1)''', '''    e += [(UP, 5, x1, y0 + 1), (P32, 19, x1, y1), (P32, 33, x0 + 1, y0 + 1)'''),
    ('''    return e
''', '''    LIGHTS.append((x1 + .5, y0 + 1.5, 34, (255, 190, 110), 40))
    return e
'''),
    # levels: L1 also has a 2-cell pile of planks + barrels
    ('''            d += [(UP, 0, *f[0]), (UP, 1, *f[1])]''', '''            d += [(UP, 0, *f[0]), (UP, 1, *f[1]), (UP, 11, *f[3])]'''),
])

# --- compose
patch("compose.py", [
    # brighter dusk floor, banded (not blurred) warm light pools
    ('''    dark = ImageEnhance.Brightness(rgb).enhance(0.55)
    blue = Image.new("RGB", rgb.size, (40, 44, 90))
    dark = ImageChops.multiply(dark, Image.new("RGB", rgb.size, (190, 190, 235)))
    dark = Image.blend(dark, blue, 0.12)''', '''    dark = ImageEnhance.Brightness(rgb).enhance(0.7)
    blue = Image.new("RGB", rgb.size, (40, 44, 90))
    dark = ImageChops.multiply(dark, Image.new("RGB", rgb.size, (205, 205, 240)))
    dark = Image.blend(dark, blue, 0.10)'''),
    ('''        for k in range(6, 0, -1):
            rr = r * k / 6
            f = (7 - k) / 6 * 0.35
            gd.ellipse([x - rr, y - rr * .6, x + rr, y + rr * .6], fill=tuple(int(c * f) for c in col))
    glow = glow.filter(ImageFilter.GaussianBlur(6))''', '''        for k, f in ((3, .10), (2, .16), (1, .24)):     # three hard bands, pixel-art style
            rr = r * .75 * k / 3
            gd.ellipse([x - rr, y - rr * .55, x + rr, y + rr * .55], fill=tuple(int(c * f) for c in col))'''),
    # level 1 look: building dimmed, window lights out (scaffolding + pile in front)
    ('''    dx, dy = spec.get("nudge", (0, 0))
    front = at(x1 + 1, y1 + 1)[1] + spec.get("sort", 0)''', '''    import decor as _d
    if _d.LEVEL == 1 and lid in _d.LEVEL_ITEMS:
        im = level1_look(im)
    dx, dy = spec.get("nudge", (0, 0))
    front = at(x1 + 1, y1 + 1)[1] + spec.get("sort", 0)'''),
    ('''def place_walls(sprites):''', '''def level1_look(im):
    """A level 1 building: plainer and quieter - most windows dark, colours muted."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r > 170 and g > 110 and b < 120 and r - b > 80 and (x // 6 + y // 9) % 3:
                px[x, y] = (40, 34, 40, a)
    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.7)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.88)
    return Image.merge("RGBA", (*rgb.split(), im.getchannel("A")))


def culvert():
    """Dark arch with iron bars where the river passes under a wall."""
    im = Image.new("RGBA", (30, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.pieslice([2, 2, 28, 34], 180, 360, fill=(14, 10, 18, 255))
    d.rectangle([2, 18, 28, 25], fill=(14, 10, 18, 255))
    for x in range(6, 27, 5):
        d.line([(x, 4), (x, 25)], fill=(70, 70, 82, 255))
    d.arc([1, 1, 29, 35], 180, 360, fill=(110, 108, 116, 255), width=2)
    return im


def place_walls(sprites):'''),
    ('''    place_lot(sprites, "gatehouse", gx0, gy0, gx1, gy1)''', '''    place_lot(sprites, "gatehouse", gx0, gy0, gx1, gy1)
    arch = culvert()
    for i, j in ((N - 1, 27.5), (0, 27.5)):      # the river goes under both side walls
        x, y = at(i + 1, j + .5)
        put(sprites, arch, (x - 6, y + 4), (15, 25), at(i + 1, j + 4)[1] + 2)'''),
])

# --- plateau: stone-block cliff faces (same stone as the walls) instead of a flat slab
patch("prep_plateau.py", [
    ('''for s in range(21):''', '''blk = Image.open("art/wall_block.png").convert("RGBA")
blk = Image.merge("RGBA", (*ImageEnhance.Brightness(blk.convert("RGB")).enhance(0.75).split(), blk.getchannel("A")))
def cell(i, j, z=0): return OX + (i - j) * 16, OY + (i + j) * 8 - z
for zz in (0, 8):                       # two courses of blocks under the paving
    for i in range(14):                 # front (+j) face, leaving the stairs
        if not 5 <= i <= 8:
            x, y = cell(i, 6, zz)
            im.alpha_composite(blk, (x - 16, y - 16 + 16))
    for j in range(7):                  # side (+i) face
        x, y = cell(13, j, zz)
        im.alpha_composite(blk, (x - 16, y - 16 + 16))
for s in range(21):'''),
])

# --- Vault: warmer stone so it reads as a shop, not part of the wall
from PIL import Image, ImageChops
v = Image.open("art/stash.png").convert("RGBA")
warm = ImageChops.multiply(v.convert("RGB"), Image.new("RGB", v.size, (255, 226, 190)))
Image.merge("RGBA", (*warm.split(), v.getchannel("A"))).save("art/stash_warm.png")

# --- Hardcore church: opaque and readable, just colder
patch("prep_ruin.py", [('rgb = ImageEnhance.Brightness(rgb).enhance(0.72)', 'rgb = ImageEnhance.Brightness(rgb).enhance(0.86)')])
print("pass1 patched")
