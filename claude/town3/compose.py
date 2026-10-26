"""Compose the town from layout.py and the generated sprites (1x; a cell is a 32x16 diamond).
Usage: py compose.py <out_dir>   -> town_day.png, town_dusk.png, phone shots
Buildings anchor their bottom corner on their lot's front corner (both visible faces flush
with the lot's +i / +j edges, yard behind), so each sits inside its spot with the door on
its street."""
import json
import os
import random
import sys
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter
from decor import decor, trees, LIGHTS
from layout import N, PLATEAU, PLATEAU_Z, BRIDGE, GROUND, TOWERS, GATEHOUSE, LOTS, HOUSES, POINTS, TREE_BELTS

HW, HH = 16, 8
ROOT = os.path.dirname(os.path.abspath(__file__))
MX, MTOP, MBOT = 100, 280, 110
W, H = 2 * N * HW + 2 * MX, 2 * N * HH + MTOP + MBOT
OX, OY = MX + N * HW, MTOP
rng = random.Random(7)

# sprite per lot: file in art/, flip so the door lands on the lot's door face, nudge (dx, dy)
SPRITES = json.load(open(os.path.join(ROOT, "sprites.json")))


def at(i, j, z=0):
    return OX + (i - j) * HW, OY + (i + j) * HH - z


def load(name):
    im = Image.open(os.path.join(ROOT, "art", name)).convert("RGBA")
    return im


def base_corner(im):
    """Bottom corner of the sprite's footprint: centre of the lowest opaque row."""
    a = im.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    bb = a.getbbox()
    y = bb[3] - 1
    xs = [x for x in range(im.width) if a.getpixel((x, y))]
    return (xs[0] + xs[-1]) // 2, y


def ground_kind():
    g = [["grass"] * N for _ in range(N)]
    for k, x0, y0, x1, y1 in GROUND:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                g[i][j] = k
    return g


TILE_OF = {"grass": "grass", "yard": "grass", "plateau": "flag", "grave": "grave", "road": "cobble",
           "square": "flag", "water": "water", "bridge": "cobble", "path": "cobble", "dirt": "dirt", "garden": "grass", "planks": "planks", "field": "dirt", "pen": "grass"}


def load_tiles():
    t = {"planks": [load("tiles_extra_planks.png")]}
    for name in os.listdir(os.path.join(ROOT, "art", "tiles")):
        key = name.split("_")[0]
        t.setdefault(key, []).append(load("tiles/" + name))
    return t


def draw_ground(img, tiles):
    g = ground_kind()
    for s in range(2 * N):
        for i in range(N):
            j = s - i
            if not 0 <= j < N:
                continue
            k = TILE_OF[g[i][j]]
            if k == "grave" and not HARDCORE:
                k = "grass"
            var = tiles[k]
            t = var[(i * 7 + j * 13 + (i * j) % 5) % len(var)]
            x, y = at(i, j)
            img.alpha_composite(t, (x - t.width // 2, y))
    return g


SMALL = {0, 1, 2, 3, 14, 15, 16, 23, 25, 26, 27, 28, 29, 30, 31, 32, 33, 39, 44, 45, 50, 56, 57, 58, 59,
         6, 7, 8, 9, 10, 60, 63, 17, 18, 42, 19, 13, 11, 37, 43, 46, 35, 24}
FENCE_COL = {"wood": ((74, 50, 32), (107, 74, 46)), "iron": ((34, 34, 44), (58, 58, 72))}


def fence_piece(kind, axis):
    """One fence unit along a grid edge, drawn in iso: posts at both ends, two rails."""
    post, rail = FENCE_COL[kind]
    h = 12 if kind == "wood" else 14
    im = Image.new("RGBA", (36, 8 + h + 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ax, ay = (1, h + 2)
    bx, by = (ax + 32, ay + 16) if axis == "i" else (ax - 32 + 34, ay + 16)
    if axis == "j":
        ax, bx = 34, 2
    pts = [(ax, ay), (bx, by)] if axis == "i" else [(ax, ay), (bx, ay + 16)]
    (x0, y0), (x1, y1) = pts
    out = (14, 8, 18)
    for k in ((h - 3), (h - 8)) if kind == "wood" else ((h - 2), 3):
        d.line([(x0, y0 - k), (x1, y1 - k)], fill=out, width=3)
        d.line([(x0, y0 - k), (x1, y1 - k)], fill=rail, width=1)
    if kind == "iron":
        for t in range(0, 9):
            x, y = x0 + (x1 - x0) * t / 8, y0 + (y1 - y0) * t / 8
            d.line([(x, y), (x, y - h)], fill=out, width=1)
            d.point((x, y - h - 1), fill=rail)
    for x, y in ((x0, y0), (x1, y1)):
        d.rectangle([x - 2, y - h - 1, x + 1, y], fill=out)
        d.rectangle([x - 1, y - h, x, y - 1], fill=post)
    return im, (x0, y0)


def banks(img, g):
    d = ImageDraw.Draw(img)
    wet = lambda i, j: 0 <= i < N and 0 <= j < N and g[i][j] in ("water", "bridge") and g[i][j] == "water"
    for i in range(N):
        for j in range(N):
            if not wet(i, j):
                continue
            for (di, dj), edge in (((0, -1), ((i, j), (i + 1, j))), ((0, 1), ((i, j + 1), (i + 1, j + 1))),
                                   ((-1, 0), ((i, j), (i, j + 1))), ((1, 0), ((i + 1, j), (i + 1, j + 1)))):
                ni, nj = i + di, j + dj
                if 0 <= ni < N and 0 <= nj < N and g[ni][nj] not in ("water",):
                    a, b = at(*edge[0]), at(*edge[1])
                    d.line([a, b], fill=(30, 26, 22, 255), width=3)
                    d.line([(a[0], a[1] + 2), (b[0], b[1] + 2)], fill=(120, 150, 160, 255), width=1)


def water(img, g):
    """River with real banks: a grid vertex is water when any of its 4 cells is water (banks
    spill onto the neighbouring grass); cells touching a water vertex take that corner tile."""
    wat = lambda i, j: 0 <= i < N and 0 <= j < N and g[i][j] == "water"
    vw = lambda i, j: any(wat(a, b) for a in (i - 1, i) for b in (j - 1, j))
    tiles = {n: muted_water(load(f"water/w{n}.png")) for n in range(16)}
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
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
            layer.alpha_composite(tiles[mask], (x - 16, y))
    bank_line(img, layer)


def muted_water(t):
    """The river in the town's palette: 30% less saturated, 15% darker, the white dashes
    turned to a grey-blue (#6fa2b0)."""
    px = t.load()
    for y in range(t.height):
        for x in range(t.width):
            r, g, b, a = px[x, y]
            if not a or not (b > r + 10):        # only the water, not its bank pixels
                continue
            if min(r, g, b) > 180:
                px[x, y] = (111, 162, 176, a)
                continue
            l = (r * 299 + g * 587 + b * 114) / 1000
            r, g, b = (int((l + (c - l) * 0.7) * 0.85) for c in (r, g, b))
            px[x, y] = (r, g, b, a)
    return t


def is_water(p):
    return p[3] > 128 and p[2] > p[0] + 10


def bank_line(img, layer):
    """A 1 px dark line where the water meets its south bank."""
    lp, ip = layer.load(), img.load()
    for y in range(layer.height - 1):
        for x in range(layer.width):
            if is_water(lp[x, y]) and not is_water(lp[x, y + 1]) and lp[x, y + 1][3] > 0:
                r, g, b, a = ip[x, y + 1]
                ip[x, y + 1] = (int(r * .45), int(g * .45), int(b * .5), a)


GROUND_IMG = []   # the ground before any sprite: dusk light pools only land where it still shows


def outside(img, tiles):
    """Daylight country outside the walls over the whole picture (so a panned phone view never
    shows void): grass a little darker than the lawns inside, light fog only far out, and the road
    from the sealed gate running off as a rutted dirt track. Dusk comes from the look shader."""
    fog = Image.new("RGB", (32, 17), (150, 160, 170))
    memo = {}
    stream = muted_water(load("water/w0.png"))
    for s in range(-40, 2 * N + 60):
        for i in range(-50, N + 50):
            j = s - i
            if 0 <= i < N and 0 <= j < N:
                continue
            x, y = at(i, j)
            if x < -16 or x > W + 16 or y < -17 or y > H:
                continue
            ring = max(-i, -j, i - N + 1, j - N + 1)
            road = 18 <= i <= 21 and j >= N
            k = ("dirt" if road else "grass", (i * 5 + j * 3) % 2, min(ring, 14))
            if j in (27, 28) and ring <= 4:      # the river runs on past each culvert, fading into the wood
                g = tiles["grass"][(i * 5 + j * 3) % 2]
                w = Image.blend(stream, g, min(1.0, 0.22 * (ring - 1)))
                img.alpha_composite(w, (x - 16, y))
                continue
            if k not in memo:
                t = tiles[k[0]][k[1]]
                rgb = ImageEnhance.Color(t.convert("RGB")).enhance(0.9)
                rgb = ImageEnhance.Brightness(rgb).enhance(max(0.72, 0.85 - 0.01 * k[2]))
                if k[2] >= 10:
                    rgb = Image.blend(rgb, fog, min(0.22, 0.05 * (k[2] - 9)))
                memo[k] = Image.merge("RGBA", (*rgb.split(), t.getchannel("A")))
            img.alpha_composite(memo[k], (x - 16, y))
    d = ImageDraw.Draw(img)
    for ci in (19.25, 20.75):                 # two cart ruts down the road
        a, b = at(ci, N + 0.3), at(ci, N + 9)
        d.line([a, b], fill=(78, 58, 40, 255), width=1)
        d.line([(a[0] + 1, a[1]), (b[0] + 1, b[1])], fill=(150, 120, 86, 255), width=1)


def wall_shadow(img):
    """The outer wall faces away from the light (south-west and south-east) cast a 4 px band of
    shadow on the grass at their foot, 6 px under the towers."""
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    for a, b in ((at(0, N), at(N, N)), (at(N, 0), at(N, N))):
        d.polygon([a, b, (b[0], b[1] + 4), (a[0], a[1] + 4)], fill=(10, 8, 18, 64))
    for k in (0, N - 3):                          # the corner towers: a deeper 6 px
        for a, b in ((at(k, N), at(k + 3, N)), (at(N, k), at(N, k + 3))):
            d.polygon([a, b, (b[0], b[1] + 6), (a[0], a[1] + 6)], fill=(10, 8, 18, 64))
    img.alpha_composite(sh)


OUTSIDE_PROPS = [("props32", 25, -2, 11), ("props32", 16, -2, 12), ("props32", 16, -3, 12),   # a woodcutter's stump and logs (NW)
                 ("props48", 7, 12, -2),                                                     # a standing stone (NE)
                 ("props48", 19, 17, N + 3)]                                                 # a gibbet cage by the gate road


def outside_trees(sprites):
    """A daylight wood outside the walls: thick behind the north walls, sparse and far out in front
    of the south walls (never hiding them); the gate road runs ~120 px before the trees close in."""
    r = random.Random(31)
    pool = (2, 3, 10, 11, 0, 1, 4)
    for i in range(-14, N + 14):
        for j in range(-14, N + 14):
            if 0 <= i < N and 0 <= j < N:
                continue
            ring = max(-i, -j, i - N + 1, j - N + 1)
            front = i >= N or j >= N
            road = 16 <= i <= 23 and j >= N and (ring <= 7 or 18 <= i <= 21)
            near_prop = any(abs(i - pi) <= 1 and abs(j - pj) <= 1 for _, _, pi, pj in OUTSIDE_PROPS)
            stream = j in (26, 27, 28, 29) and ring <= 5
            if (front and ring < 5) or ring < 2 or road or near_prop or stream or r.random() > (0.16 if front else 0.3):
                continue
            x, y = at(i + .5, j + .5)
            if not (-40 < x < W + 40 and -20 < y < H + 60):
                continue
            n = r.choice(pool)
            im = load(f"trees/t{n}.png")
            rgb = ImageEnhance.Brightness(im.convert("RGB")).enhance(max(0.7, 0.88 - 0.012 * ring))
            if ring >= 9:
                rgb = Image.blend(rgb, Image.new("RGB", im.size, (150, 160, 170)), min(0.2, 0.04 * (ring - 8)))
            im = Image.merge("RGBA", (*rgb.split(), im.getchannel("A")))
            bb = im.getbbox()
            put(sprites, im, (x + r.randint(-6, 6), y + 4), ((bb[0] + bb[2]) // 2, bb[3] - 1))
    for name, n, i, j in OUTSIDE_PROPS:        # things you can see from inside, within 80 px of the walls
        im = load(f"{name}/p{n}.png")
        bb = im.getbbox()
        x, y = at(i + .5, j + .5)
        put(sprites, im, (x, y + 3), ((bb[0] + bb[2]) // 2, bb[3] - 1))


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


def put(sprites, im, foot_xy, anchor, key=None):
    """Queue a sprite so its anchor pixel lands on foot_xy; sorted by key (screen y of its front)."""
    x, y = int(round(foot_xy[0] - anchor[0])), int(round(foot_xy[1] - anchor[1]))
    sprites.append((key if key is not None else foot_xy[1], x, y, im, TAG[0]))


def place_lot(sprites, lid, x0, y0, x1, y1, z=0):
    """A sprite with "origin" (img2img from a block-out) puts that pixel on vertex (x0, y0);
    otherwise its bottom corner goes on the lot's front corner (x1+1, y1+1)."""
    spec = dict(SPRITES.get(lid) or {})
    if lid == "church" and HARDCORE and spec:
        spec["file"] = "church_ruin.png"
    if not spec or not os.path.exists(os.path.join(ROOT, "art", spec["file"])):
        return
    im = load(spec["file"])
    if not LIT[0] and lid != "smith":     # the forge burns by day too
        im = daylit(im)
    if spec.get("flip"):
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    import decor as _d
    if _d.LEVEL == 1 and lid in _d.LEVEL_ITEMS:
        im = level1_look(im)
    dx, dy = spec.get("nudge", (0, 0))
    front = at(x1 + 1, y1 + 1)[1] + spec.get("sort", 0)
    if "pin" in spec:                  # a known sprite pixel on a known grid point (the gate arch on the street)
        px_, py_, pi_, pj_ = spec["pin"]
        put(sprites, im, at(pi_, pj_, z), (px_, py_), front)
    elif "origin" in spec:
        fx, fy = at(x0, y0, z)
        put(sprites, im, (fx + dx, fy + dy), tuple(spec["origin"]), front)
    else:
        fx, fy = at(x1 + 1, y1 + 1, z)
        put(sprites, im, (fx + dx, fy + dy), base_corner(im), front)
    _, x, y, _, _ = sprites[-1]
    sprites[-1] = sprites[-1][:4] + (lid,)
    b = im.getbbox()
    BOXES[lid] = (x + b[0], y + b[1], b[2] - b[0], b[3] - b[1])


def level1_look(im):
    """A level 1 building: plainer and quieter - most windows dark, colours muted."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and r > 170 and g > 110 and b < 120 and r - b > 80 and (x // 6 + y // 9) % 3:
                px[x, y] = (40, 34, 40, a)
    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.6)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.75)
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


def place_walls(sprites):
    """Curtain wall from 4-cell runs (buttress at each join hides the repeat); runs along j are
    the mirrored run, shaded as the side away from the top-left light."""
    # three variants (moss at the foot / a cracked block / a drain hole and stain) by position,
    # and an arrow slit in the middle run of each side, so no run repeats its neighbour
    runs = [load(f) for f in ("wall_run.png", "wall_run_b.png", "wall_run_c.png", "wall_run_slit.png")]
    mirs = [Image.merge("RGBA", (*ImageEnhance.Brightness(r.transpose(Image.FLIP_LEFT_RIGHT).convert("RGB")).enhance(0.8).split(),
                                 r.transpose(Image.FLIP_LEFT_RIGHT).getchannel("A"))) for r in runs]
    OXR, OYR = 20, 60                      # pixel of the run's vertex (0, 0) on its canvas
    gx0, gy0, gx1, gy1 = GATEHOUSE
    pick = lambda s, side: 3 if s == 19 else (s * 7 + side) % 3
    for s in range(3, N - 3, 4):
        for j in (0, N - 1):               # along i
            if j == N - 1 and s + 3 >= gx0 + 1 and s <= gx1 - 1:
                continue
            put(sprites, runs[pick(s, j)], at(s, j), (OXR, OYR), at(s + 4, j + 1)[1] - 1)
        for i in (0, N - 1):               # along j
            m = mirs[pick(s, i + 1)]
            put(sprites, m, at(i + 1, s), (m.width - OXR, OYR), at(i + 1, s + 4)[1] - 1)
    for k, (tx, ty) in enumerate(TOWERS):
        place_lot(sprites, f"tower{k}", tx, ty, tx + 2, ty + 2)
    place_lot(sprites, "gatehouse", gx0, gy0, gx1, gy1)
    arch = culvert()
    for i, j in ((N - 1, 27.5), (0, 27.5)):      # the river goes under both side walls
        x, y = at(i + 1, j + .5)
        put(sprites, arch, (x - 6, y + 4), (15, 25), at(i + 1, j + 4)[1] + 2)


def shadow(img, sprites):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    for _, x, y, im, _ in sprites:
        a = im.getchannel("A").point(lambda v: 90 if v > 100 else 0)
        blk = Image.new("RGBA", im.size, (10, 6, 20, 255))
        blk.putalpha(a)
        sh.alpha_composite(blk.transform(im.size, Image.AFFINE, (1, 0.9, -im.height * 0.0, 0, 1.6, -im.height * 0.6)), (x, y))
    img.alpha_composite(sh)


TAG = [""]         # tag put() gives the next sprites (a lot id for buildings)
LAST_SPRITES = []  # the sorted sprites of the last compose (export_town builds walker occluders from them)
BOXES = {}      # sprite id -> opaque box on the town canvas (tap areas for town.json)
NO_OVERLAYS = []  # [True] -> leave out walkers and level props (the game draws those itself)
LIT = [True]      # False -> the day picture: windows are glass, torches and lamps unlit (the forge still burns)
FLAMES = {("props32", 12), ("props32", 11), ("props_up", 4), ("props_up", 5), ("props48", 10)}   # torches, candles, braziers, lanterns, lamps
_DAY = {}


def lit_px(r, g, b):
    """A lit pane or a flame (not wood, not pumpkins)."""
    return r > 215 and g > 140 and b < 110 and r - b > 130


def glow_core(r, g, b):
    """The bright heart of a lit window or lantern (the gatehouse lantern's pale yellow glass too)."""
    return (r > 200 and g > 130 and b < 120 and r - b > 115) or (r > 235 and g > 200 and b < 190 and r - b > 60)


def flame_lit(r, g, b):
    """A burning flame's bright pixel (yellow tongue or orange core), not wood, cloth or brass."""
    return (r > 220 and g > 150 and b < 110 and r - b > 110) or (r > 200 and g < 120 and b < 50 and r > g + 100)


def day_flames(img, lights):
    """The day check: lights (canvas x, y) with a burning pixel within 6 px. The forge (its light
    and the smithy's own box) and the blue portal and beam lights are left out (they burn by day)."""
    px, bad = img.load(), []
    sx, sy, sw, sh = BOXES.get("smith", (0, 0, 0, 0))
    forge = lambda i, j: sx <= i < sx + sw and sy <= j < sy + sh
    for (x, y), col in lights:
        if col[2] > col[0] or tuple(col) == FORGE:
            continue
        if any(flame_lit(*px[i, j][:3]) for j in range(y - 6, y + 7) for i in range(x - 6, x + 7)
               if 0 <= i < img.width and 0 <= j < img.height and not forge(i, j)):
            bad.append((x, y))
    return bad


FORGE = (255, 120, 50)   # the forge light's colour (decor.py): it burns by day


def flicker(over, lights):
    """The lit overlay's second flame frame: near each flame light (not the blue portal and beam),
    every flame tongue reaches one pixel higher and burns a little brighter. Windows stay."""
    out = over.copy()
    src, px = over.load(), out.load()
    for (x, y), col in lights:
        if col[2] > col[0]:
            continue
        for j in range(max(1, y - 10), min(over.height, y + 6)):
            for i in range(max(0, x - 6), min(over.width, x + 7)):
                r, g, b, a = src[i, j]
                if a and fire(r, g, b):
                    px[i, j] = (min(255, r + 12), min(255, g + 18), min(255, b + 10), a)
                    ar, ag, ab, aa = src[i, j - 1]
                    if not (aa and fire(ar, ag, ab)) and g > 150:   # the tip of a tongue: one pixel taller
                        px[i, j - 1] = (min(255, r + 12), min(255, g + 18), min(255, b + 10), a)
    return out


def fire(r, g, b):
    """A flame pixel: the yellow tongue, the orange body or the dark red rim."""
    return (r > 190 and g > 120 and r > b + 70) or (r > 120 and r > g + 40 and r > b + 60)


def daylit(im, flame=False):
    """The sprite by day: lit panes become glass (#3a4660, a #6b7a95 highlight on a pane's top
    row) - the warm rim round each pane too, within 2 px of its bright heart - and a flame
    becomes a dark iron bowl."""
    key = (id(im), flame)
    if key in _DAY:
        return _DAY[key][1]
    out = im.copy()
    src, px = im.load(), out.load()
    w, h = im.size
    if flame:
        warm = lambda r, g, b: fire(r, g, b)   # any part of the fire: yellow tongue, orange body, dark red rim
        near = lambda x, y: 0 <= x < w and 0 <= y < h and src[x, y][3] and warm(*src[x, y][:3])
        for y in range(h):
            for x in range(w):
                r, g, b, a = src[x, y]
                if a and warm(r, g, b):   # the flame's foot is the dark bowl, the tongue above it is gone
                    px[x, y] = (0, 0, 0, 0) if near(x, y + 1) else (34, 30, 36, a)
        _DAY[key] = (im, out)
        return out
    core = {(x, y) for y in range(h) for x in range(w) if src[x, y][3] and glow_core(*src[x, y][:3])}
    pane = set(core)
    for x, y in core:
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                q = (x + dx, y + dy)
                if 0 <= q[0] < w and 0 <= q[1] < h and q not in pane:
                    r, g, b, a = src[q]
                    if a and ((r > 195 and r - b > 110 and g > 50) or (r > 150 and r > g + 80 and b < 40)):   # the rim, a lantern's flame
                        pane.add(q)
    for x, y in pane:
        a = src[x, y][3]
        px[x, y] = (107, 122, 149, a) if (x, y - 1) not in pane else (58, 70, 96, a)
    _DAY[key] = (im, out)    # keep im alive so its id stays unique
    return out

EMPTY = set()   # lot ids drawn as empty building plots (Church / Trophy Cabin before they're built)
HARDCORE = []   # [True] -> ruined dark Church, no church glow, the graveyard full


def compose():
    img = Image.new("RGBA", (W, H), (20, 18, 30, 255))
    tiles = load_tiles()
    outside(img, tiles)
    wall_shadow(img)
    g = draw_ground(img, tiles)
    for lid, _, x0, y0, x1, y1, _, _ in LOTS:
        if lid in EMPTY:
            for i in range(x0, x1 + 1):
                for j in range(y0, y1 + 1):
                    t = tiles["dirt"][(i + j) % 2]
                    x, y = at(i, j)
                    img.alpha_composite(t, (x - 16, y))
    water(img, g)
    ripples(img, g)
    shadows(img)
    GROUND_IMG[:] = [img.copy()]
    sprites = []
    TAG[0] = "outside"
    outside_trees(sprites)
    TAG[0] = ""
    place_walls(sprites)
    place_lot(sprites, "plateau", *PLATEAU)
    place_lot(sprites, "bridge", *BRIDGE)
    for lid, _, x0, y0, x1, y1, door, _ in LOTS:
        if lid in EMPTY:
            continue
        place_lot(sprites, lid, x0, y0, x1, y1, PLATEAU_Z if lid == "gate" else 0)
    for n, (x0, y0, x1, y1, door) in enumerate(HOUSES):
        place_lot(sprites, f"house{n}", x0, y0, x1, y1)
    cache = {}
    def sheet(name, n):
        if (name, n) not in cache:
            if name == "trees" and n >= 100:     # 100+: the same tree mirrored
                im = sheet(name, n - 100).transpose(Image.FLIP_LEFT_RIGHT)
                cache[(name, n)] = im
                return im
            im = load("reeds.png" if name == "reeds" else f"folk/{n}.png" if name == "folk" else f"{name}/{'t' if name == 'trees' else 'p'}{n}.png")
            if name == "props32" and n in SMALL:   # clutter at half size: a barrel is half a walker
                im = im.resize((16, 16), Image.NEAREST)
            cache[(name, n)] = im
        return cache[(name, n)]
    def bottom(im):
        bb = im.getbbox()
        return ((bb[0] + bb[2]) // 2, bb[3] - 1)
    from decor import empty_lot
    extra = [e for lid, _, x0, y0, x1, y1, _, _ in LOTS if lid in EMPTY for e in empty_lot(x0, y0, x1, y1)]
    built_only = {"cabin": (13, 30, 18, 35), "church": (1, 10, 6, 17)}
    def inside(e, r):
        return e[0] != "fence" and r[0] <= e[2] < r[2] and r[1] <= e[3] < r[3]
    deco = [e for e in decor() if not any(inside(e, built_only[l]) for l in EMPTY)] + extra
    if NO_OVERLAYS:
        import decor as _dd
        deco = [e for e in deco if e[0] != "folk" and not (e[0] == "props_up" and (e[2], e[3]) not in _dd.BRAZIERS)]
    bed = load("tiles_extra_flowerbed.png")
    for e in [e for e in deco if e[0] == "bed"]:      # flowerbeds are ground: drawn before every sprite
        x, y = at(e[2], e[3])
        img.alpha_composite(bed, (int(x) - 16, int(y)))
    GROUND_IMG[:] = [img.copy()] if GROUND_IMG else []
    deco = [e for e in deco if e[0] != "bed"]
    for e in deco:
        if e[0] == "fence":
            _, kind, i, j, axis = e
            im, anchor = fence_piece(kind, axis)
            a = at(i, j)
            b = at(i + 1, j) if axis == "i" else at(i, j + 1)
            put(sprites, im, a, anchor, max(a[1], b[1]) + 1)
            continue
        name, n, i, j = e[:4]
        z = e[4] if len(e) > 4 else 0
        im = sheet(name, n)
        if not LIT[0] and (name, n) in FLAMES:   # torches and lamps out by day (props have no windows)
            im = daylit(im, True)
        x, y = at(i + .5, j + .5, z)
        put(sprites, im, (x, y + 3), bottom(im), at(i + .5, j + .5)[1] + 4)
        _, px, py, _, _ = sprites[-1]
        b = im.getbbox()
        BOXES[(name, n, i, j)] = (px + b[0], py + b[1], b[2] - b[0], b[3] - b[1])
    for n, i, j, dx, dy in trees():
        im = sheet("trees", n)
        x, y = at(i + .5, j + .5)
        put(sprites, im, (x + dx, y + dy + 4), bottom(im), y + dy + 6)
    sprites.sort(key=lambda s: s[0])
    LAST_SPRITES[:] = sprites
    for _, x, y, im, tag in sprites:
        img.alpha_composite(im, (x, y))
        if tag == "plateau" and GROUND_IMG:   # the plateau's paving and stairs take ground light like the streets
            GROUND_IMG[0].alpha_composite(im, (x, y))
    return img


def dusk(img):
    """Dusk grade: darken and cool, keep warm lights."""
    rgb = img.convert("RGB")
    dark = ImageEnhance.Brightness(rgb).enhance(0.7)
    blue = Image.new("RGB", rgb.size, (40, 44, 90))
    dark = ImageChops.multiply(dark, Image.new("RGB", rgb.size, (205, 205, 240)))
    dark = Image.blend(dark, blue, 0.10)
    # keep lit windows / fire bright
    px, dp = rgb.load(), dark.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            if r > 215 and g > 140 and b < 110 and r - b > 130:     # lit windows / flames, not wood or pumpkins
                dp[x, y] = (int(r * .9), int(g * .9), int(b * .9))     # 1: windows a touch below the dungeon
    glow = Image.new("RGB", rgb.size, (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i, j, z, col, r in LIGHTS:
        x, y = at(i, j, z)
        for k, f in ((3, .10), (2, .16), (1, .24)):     # three hard bands, pixel-art style
            rr = r * .75 * k / 3
            gd.ellipse([x - rr, y - rr * .5, x + rr, y + rr * .5], fill=tuple(int(c * f) for c in col))
    gd2 = ImageDraw.Draw(glow)
    for k, f in ((3, .10), (2, .16), (1, .22)):   # the portal's light spills down the stairs and onto the lane (ground only)
        sx, sy = at(20, 8.4)
        gd2.ellipse([sx - 30 * k, sy - 12 * k, sx + 30 * k, sy + 12 * k], fill=(int(70 * f), int(180 * f), int(230 * f)))   # soft: the stairs stay stone
    same = None
    if GROUND_IMG:                     # light pools land on the visible ground only
        ground = GROUND_IMG[0].convert("RGB")
        same = ImageChops.difference(ground, rgb).convert("L").point(lambda v: 255 if v < 3 else 0)
        glow = ImageChops.multiply(glow, Image.merge("RGB", (same, same, same)))
    beam = Image.new("RGB", rgb.size, (0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bx, by = at(19.9, 4.0, PLATEAU_Z + 30)
    for w, f in ((26, .10), (16, .16), (8, .24)):
        bd.polygon([(bx - w, by), (bx + w, by), (bx + w * .6, by - 95), (bx - w * .6, by - 95)], fill=(int(90 * f * 2), int(210 * f * 2), int(255 * f * 2)))

    glow = ImageChops.add(glow, beam)
    out = ImageChops.add(dark, glow)
    if HARDCORE:                       # the whole town colder and greyer...
        out = ImageEnhance.Color(out).enhance(0.85)
        out = ImageChops.multiply(ImageEnhance.Brightness(out).enhance(1.05), Image.new("RGB", out.size, (225, 232, 255)))
        fog = Image.new("RGB", out.size, (0, 0, 0))
        fd = ImageDraw.Draw(fog)
        for i, j, r in ((4, 3, 70), (8, 5, 60), (5, 6, 50), (10, 2, 44)):   # low hard-edged fog banks over the graves
            fx, fy = at(i, j)
            fd.ellipse([fx - r, fy - r * .28, fx + r, fy + r * .28], fill=(26, 30, 38))
        if same is not None:
            fog = ImageChops.multiply(fog, Image.merge("RGB", (same, same, same)))
        out = ImageChops.add(out, fog)
    if HARDCORE:                       # ...and a cold, dead corner around the ruined church and graveyard
        mask = Image.new("L", out.size, 0)
        ImageDraw.Draw(mask).polygon([at(0, 0), at(13, 0), at(13, 19), at(0, 19)], fill=128)
        blue = ImageChops.multiply(out, Image.new("RGB", out.size, (150, 165, 200)))
        out = Image.composite(blue, out, mask)
    return out


def plateau_mask(size):
    """Where the plateau sprite shows (its paving and stairs take ground light)."""
    m = Image.new("L", size, 0)
    for key, x, y, im, tag in LAST_SPRITES:
        if tag == "plateau":
            m.paste(im.getchannel("A").point(lambda v: 255 if v > 128 else 0), (x, y), im.getchannel("A"))
    return m


def day(img):
    """Day: brighter ground, roofs and walls, windows unlit, a lighter sky behind the walls."""
    rgb = img.convert("RGB")
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            if r > 215 and g > 140 and b < 110 and r - b > 130:      # lit glass -> daylight glass
                px[x, y] = (96, 104, 118)
            elif (r, g, b) == (20, 18, 30):
                px[x, y] = (58, 70, 92)
    rgb = ImageEnhance.Brightness(rgb).enhance(1.22)
    return ImageEnhance.Color(rgb).enhance(1.1)


def phone(img, cx, cy, scale=2, size=(430, 932)):
    w, h = size[0] // scale, size[1] // scale
    crop = img.crop((cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2))
    return crop.resize((w * scale, h * scale), Image.NEAREST)


if __name__ == "__main__":
    out = sys.argv[1]
    if len(sys.argv) > 2 and sys.argv[2] == "hardcore":
        HARDCORE.append(True)
        import decor as decor_mod
        decor_mod.HARDCORE = True
        h = dusk(compose())
        h.save(f"{out}/town_dusk_hardcore.png")
        x, y = at(6, 10)
        phone(h, x, y).save(f"{out}/phone_dusk_hardcore_church.png")
        sys.exit()
    if len(sys.argv) > 2 and sys.argv[2] == "empty":
        EMPTY.update({"church", "cabin"})
        e = dusk(compose())
        e.save(f"{out}/town_dusk_emptylots.png")
        for name, (i, j) in (("church", (6, 14)), ("cabin", (16, 32))):
            x, y = at(i, j)
            phone(e, x, y).save(f"{out}/phone_dusk_emptylot_{name}.png")
        sys.exit()
    day = compose()
    day.save(f"{out}/town_day.png")
    d = dusk(day)
    d.save(f"{out}/town_dusk.png")
    sx, sy = at(20, 20)
    phone(d, sx, sy).save(f"{out}/phone_dusk_square.png")
    phone(day.convert("RGB"), sx, sy).save(f"{out}/phone_day_square.png")
    for name, (i, j) in (("dungeon", (20, 9)), ("gate", (19, 32)), ("church", (7, 13)), ("guild", (31, 10))):
        x, y = at(i, j)
        phone(d, x, y).save(f"{out}/phone_dusk_{name}.png")
    x, y = at(20, 9)
    phone(day.convert("RGB"), x, y).save(f"{out}/phone_day_dungeon.png")
