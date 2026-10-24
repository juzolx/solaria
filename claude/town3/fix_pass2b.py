"""Fable pass 2 fixes for compose.py (+ restores the banked river lost in the duplicate cleanup)
and the Trophy Cabin roof. Usage: py fix_pass2b.py"""
from PIL import Image


def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8").write(s)


NEW_FUNCS = '''def water(img, g):
    """River with real banks: a grid vertex is water when any of its 4 cells is water (banks
    spill onto the neighbouring grass); cells touching a water vertex take that corner tile."""
    wat = lambda i, j: 0 <= i < N and 0 <= j < N and g[i][j] == "water"
    vw = lambda i, j: any(wat(a, b) for a in (i - 1, i) for b in (j - 1, j))
    tiles = {n: load(f"water/w{n}.png") for n in range(16)}
    for s in range(2 * N):
        for i in range(N):
            j = s - i
            if not 0 <= j < N or g[i][j] not in ("water", "grass", "yard"):
                continue
            nw, ne, sw, se = vw(i, j), vw(i + 1, j), vw(i, j + 1), vw(i + 1, j + 1)
            if not (nw or ne or sw or se):
                continue
            mask = (not nw) << 3 | (not ne) << 2 | (not sw) << 1 | (not se)
            x, y = at(i, j)
            img.alpha_composite(tiles[mask], (x - 16, y))


GROUND_IMG = []   # the ground before any sprite: dusk light pools only land where it still shows


def outside(img, tiles):
    """Three cells of dusk ground outside the walls, darker each cell out (hard steps into the
    void), and the road from the sealed gate running off into the fog."""
    for s in range(-6, 2 * N + 6):
        for i in range(-3, N + 3):
            j = s - i
            if not -3 <= j < N + 3 or (0 <= i < N and 0 <= j < N):
                continue
            ring = max(-i, -j, i - N + 1, j - N + 1)
            road = 18 <= i <= 21 and j >= N
            t = (tiles["cobble"] if road else tiles["grass"])[(i * 5 + j * 3) % 2]
            rgb = ImageEnhance.Color(t.convert("RGB")).enhance(0.5)
            rgb = ImageEnhance.Brightness(rgb).enhance((0.75, 0.5, 0.3)[ring - 1])
            t = Image.merge("RGBA", (*rgb.split(), t.getchannel("A")))
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
                d.line([at(i, j - .5), at(i + 1, j - .5)], fill=(110, 130, 120, 255))


def shadows(img):
    """Ground shadows: each building's footprint shifted toward the bottom right (light from
    the top left), drawn before the sprites so only the part outside the building shows."""
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    rects = [l[2:6] for l in LOTS if l[0] not in EMPTY] + [h[:4] for h in HOUSES]
    rects += [(x, y, x + 2, y + 2) for x, y in TOWERS] + [GATEHOUSE]
    for x0, y0, x1, y1 in rects:
        a, b = x0 + .7, y0 + .25
        d.polygon([at(a, b), at(x1 + 1.7, b), at(x1 + 1.7, y1 + 1.25), at(a, y1 + 1.25)], fill=(14, 8, 18, 90))
    img.alpha_composite(sh)


def put(sprites'''

patch("compose.py", [
    ("MX, MTOP, MBOT = 40, 260, 60", "MX, MTOP, MBOT = 100, 280, 110"),
    ('''    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.7)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.88)''', '''    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.6)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.75)'''),
    ('''    tiles = load_tiles()
    g = draw_ground(img, tiles)''', '''    tiles = load_tiles()
    outside(img, tiles)
    g = draw_ground(img, tiles)'''),
    ('''    banks(img, g)
    sprites = []''', '''    water(img, g)
    ripples(img, g)
    shadows(img)
    GROUND_IMG[:] = [img.copy()]
    sprites = []'''),
    ('''def put(sprites''', NEW_FUNCS),
    ('''            if r > 190 and g > 120 and b < 110 and r - b > 90:
                dp[x, y] = (r, g, b)''', '''            if r > 205 and g > 140 and b < 120 and r - b > 90:      # lit windows / flames, not pumpkins
                dp[x, y] = (r, g, b)'''),
    ('''    return ImageChops.add(dark, glow)''', '''    if GROUND_IMG:                     # light pools land on the visible ground only
        ground = GROUND_IMG[0].convert("RGB")
        same = ImageChops.difference(ground, rgb).convert("L").point(lambda v: 255 if v < 3 else 0)
        glow = ImageChops.multiply(glow, Image.merge("RGB", (same, same, same)))
    out = ImageChops.add(dark, glow)
    if HARDCORE:                       # a cold, dead corner around the ruined church and graveyard
        mask = Image.new("L", out.size, 0)
        ImageDraw.Draw(mask).polygon([at(0, 0), at(13, 0), at(13, 19), at(0, 19)], fill=128)
        blue = ImageChops.multiply(out, Image.new("RGB", out.size, (150, 165, 200)))
        out = Image.composite(blue, out, mask)
    return out'''),
])

im = Image.open("art/cabin.png").convert("RGBA")
px = im.load()
for y in range(im.height):
    for x in range(im.width):
        r, g, b, a = px[x, y]
        if a and g > r + 12 and g > b + 8:                         # bright moss -> roof shadow ramp
            px[x, y] = (int(r * .55), int(g * .5), int(b * .55), a)
        elif a and r > 200 and g > 140 and b < 120 and y < im.height * .45:   # skylights out
            px[x, y] = (60, 46, 40, a)
im.save("art/cabin.png")
print("pass2b patched")
