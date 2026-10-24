"""Fable critique pass 2 fixes (one-off source patch). Usage: py fix_pass2.py"""
from PIL import Image, ImageEnhance


def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8").write(s)


# 4: Tavern one more cell from the stairs; Vault one cell south so a street separates it from the Tavern
patch("layout.py", [
    ('("tavern", "Tavern", 23, 10, 27, 14, "j", 24)', '("tavern", "Tavern", 24, 10, 28, 14, "j", 24)'),
    ('("stash", "Vault", 28, 15, 31, 18, "j", 18)', '("stash", "Vault", 28, 16, 31, 19, "j", 18)'),
    # 11: the dead-end strip along the east wall becomes a tree belt
    ('TREE_BELTS = [', 'TREE_BELTS = [(35, 21, 38, 25), '),
])

patch("decor.py", [
    # vault props follow it
    ('    d += [(P32, 31, 30, 19), (P32, 32, 31, 19)]', '    d += [(P32, 31, 32, 20)]'),
    # 12: Hardcore - torches by the church are out, so the dungeon is the warm light in that corner
    ('''    for j in (6, 13, 26, 33):
        d.append((P32, 12, 1, j))
        LIGHTS.append((1.5, j + .5, 28, (255, 170, 90), 30))''', '''    for j in (6, 13, 26, 33):
        if HARDCORE and j < 20:
            continue
        d.append((P32, 12, 1, j))
        LIGHTS.append((1.5, j + .5, 28, (255, 170, 90), 30))'''),
    ('lamp(8, 12), lamp(8, 26)', '*([] if HARDCORE else [lamp(8, 12)]), lamp(8, 26)'),
    # 5: level 3 showpieces - no unlit stone pillars (they read as chimneys); statues/trees + lit braziers by the door
    ('LEVEL_ITEMS = {"inn": (6, (2, 8)), "tavern": (7, (2, 4)), "smith": (10, (3, 4)), "shop": (6, (3, 11)),\n               "guild": (10, (2, 9)), "stash": (6, (3, 15)), "clinic": (13, (3, 8))}',
     'LEVEL_ITEMS = {"inn": (6, (2, 8)), "tavern": (7, (2, 8)), "smith": (10, (3, 9)), "shop": (6, (3, 11)),\n               "guild": (10, (2, 9)), "stash": (6, (3, 15)), "clinic": (13, (3, 8))}'),
    ('''            d += [(UP, l3[0], *f[1]), (UP, l3[0], *f[2]), (UP, l3[1], *side)]
            if l3[1] == 4:
                LIGHTS.append((side[0] + .5, side[1] + .5, 40, (255, 150, 70), 44))''',
     '''            d += [(UP, l3[0], *f[1]), (UP, l3[0], *f[2]), (UP, l3[1], *side), (P32, 12, *f[3])]
            LIGHTS.append((f[3][0] + .5, f[3][1] + .5, 30, (255, 170, 90), 36))'''),
])

patch("compose.py", [
    # 7: room for ground outside the walls
    ("MX, MTOP, MBOT = 40, 260, 60", "MX, MTOP, MBOT = 100, 280, 110"),
    # 5: level 1 clearly quieter
    ('''    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.7)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.88)''', '''    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.6)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.75)'''),
    # 7 + 2 + 6: outside ground with a fog step, gate road stub, ground shadows, river ripples / bank line
    ('''    g = draw_ground(img, tiles)
    water(img, g)''', '''    outside(img, tiles)
    g = draw_ground(img, tiles)
    water(img, g)
    ripples(img, g)
    shadows(img)
    GROUND_IMG[:] = [img.copy()]'''),
    ('''def put(sprites''', '''GROUND_IMG = []   # the ground before any sprite: dusk light pools only land where it still shows


def outside(img, tiles):
    """Three cells of dusk ground outside the walls, fading into the void in two hard steps,
    and the road from the sealed gate running off into the fog."""
    void = Image.new("RGBA", (34, 18), (20, 18, 30, 255))
    for s in range(-6, 2 * N + 6):
        for i in range(-3, N + 3):
            j = s - i
            if not -3 <= j < N + 3 or (0 <= i < N and 0 <= j < N):
                continue
            ring = max(-i, -j, i - N + 1, j - N + 1)          # 1..3 cells out
            road = 18 <= i <= 21 and j >= N
            t = (tiles["cobble"] if road else tiles["grass"])[(i * 5 + j * 3) % 2]
            t = Image.merge("RGBA", (*ImageEnhance.Brightness(ImageEnhance.Color(t.convert("RGB")).enhance(0.5))
                                    .enhance((0.75, 0.5, 0.3)[ring - 1]).split(), t.getchannel("A")))
            x, y = at(i, j)
            img.alpha_composite(t, (x - 16, y))


def ripples(img, g):
    """A few light ripple pixels per water cell and a pale line on the far (north) bank."""
    import random as _r
    rr = _r.Random(4)
    d = ImageDraw.Draw(img)
    for i in range(N):
        for j in range(N):
            if g[i][j] != "water":
                continue
            for _ in range(3):
                x, y = at(i + rr.random() * .8 + .1, j + rr.random() * .8 + .1)
                d.line([(x - 2, y), (x + 1, y)], fill=(96, 140, 150, 255))
            if j > 0 and g[i][j - 1] != "water":
                a, b = at(i, j - .5), at(i + 1, j - .5)
                d.line([a, b], fill=(110, 130, 120, 255))


def shadows(img):
    """Soft-free ground shadows: each building's footprint shifted toward the bottom right
    (light from the top left), drawn before the sprites so only the part outside shows."""
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    rects = [l[2:6] for l in LOTS if l[0] not in EMPTY] + [h[:4] for h in HOUSES]
    rects += [(x, y, x + 2, y + 2) for x, y in TOWERS] + [GATEHOUSE]
    for x0, y0, x1, y1 in rects:
        a, b = x0 + .7, y0 + .25
        d.polygon([at(a, b), at(x1 + 1.7, b), at(x1 + 1.7, y1 + 1.25), at(a, y1 + 1.25)], fill=(14, 8, 18, 90))
    img.alpha_composite(sh)


def put(sprites'''),
    # 1 + 8: light pools only on visible ground, banded; dusk spares only real light (windows, flames, portal)
    ('''            if r > 190 and g > 120 and b < 110 and r - b > 90:
                dp[x, y] = (r, g, b)''', '''            if r > 205 and g > 140 and b < 120 and r - b > 90:      # lit windows / flames, not pumpkins
                dp[x, y] = (r, g, b)'''),
    ('''    return ImageChops.add(dark, glow)''', '''    if GROUND_IMG:
        ground = GROUND_IMG[0].convert("RGB").crop((0, 0, rgb.width, rgb.height))
        diff = ImageChops.difference(ground, rgb).convert("L").point(lambda v: 255 if v < 3 else 0)
        glow = ImageChops.multiply(glow, Image.merge("RGB", (diff, diff, diff)))
    out = ImageChops.add(dark, glow)
    if HARDCORE:                       # a cold, dead corner around the ruined church and the graveyard
        cold = Image.new("RGB", out.size, (0, 0, 0))
        cd = ImageDraw.Draw(cold)
        cd.polygon([at(0, 0), at(13, 0), at(13, 19), at(0, 19)], fill=(255, 255, 255))
        cold = cold.convert("L").point(lambda v: int(v * .5))
        blue = ImageChops.multiply(out, Image.new("RGB", out.size, (150, 165, 200)))
        out = Image.composite(blue, out, cold)
    return out'''),
])
patch("compose.py", [("from layout import N, PLATEAU,", "from layout import N, HOUSES, PLATEAU,")]) if "HOUSES," not in open("compose.py").read().split("\n")[11] else None

# 10: Trophy Cabin roof moss to the roof's shadow ramp, fewer lit panes
im = Image.open("art/cabin.png").convert("RGBA")
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a and g > r + 12 and g > b + 8:
            px[x, y] = (int(r * .55), int(g * .5), int(b * .55), a)
        elif a and r > 200 and g > 140 and b < 120 and y < im.height * .45:
            px[x, y] = (60, 46, 40, a)
im.save("art/cabin.png")
print("pass2 patched")
