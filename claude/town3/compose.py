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


OUTSIDE_SPRITES = []   # (sprite, entry) of the OUTSIDE_PROPS, for the floating check
# (the woodcutter's stump and logs and the standing stone stood behind the walls: only a stone's
# top showed over the battlements, floating, Fable round 5 P11)
OUTSIDE_PROPS = [("props48", 19, 17, N + 3)]                                                 # a gibbet cage by the gate road


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
        OUTSIDE_SPRITES.append((sprites[-1], (name, n, i, j)))


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


def _bottoms(im):
    """Each column's lowest solid pixel (None where the column is empty)."""
    a = im.getchannel("A").load()
    out = []
    for x in range(im.width):
        ys = [y for y in range(im.height) if a[x, y] > 128]
        out.append(ys[-1] if ys else None)
    return out


def _foot(im, skip=()):
    """Ground a sprite where it meets the ground (Juzo: the dungeon entrance looked floating): a soft
    contact shadow under its lowest pixels and grass tufts and rubble on its foot line, none on
    the columns in `skip` (a stair's foot). The shadow stays under alpha 128, so base_corner and
    the anchors don't move."""
    import random
    rnd = random.Random(7)
    im = im.copy()
    px = im.load()
    bot = _bottoms(im)
    for x, b in enumerate(bot):
        if b is None:
            continue
        for k, al in ((1, 110), (2, 70), (3, 35)):
            if b + k < im.height and px[x, b + k][3] == 0:
                px[x, b + k] = (22, 20, 28, al)
    x = 2
    while x < im.width - 3:
        b = bot[x]
        if b is None or any(lo <= x <= hi for lo, hi in skip) or any(bot[x + d] is None or abs(bot[x + d] - b) > 1 for d in (-1, 1, 2)):
            x += 1
            continue
        if rnd.random() < 0.55:     # a grass tuft: two or three blades up the foot
            for dx, h in ((0, 2), (1, 3), (2, 1)):
                for k in range(h):
                    px[x + dx, bot[x + dx] - k] = (78, 118, 52, 255) if k else (54, 84, 40, 255)
        else:                       # a fallen stone: lit top, dark rim
            for dx in (0, 1, 2):
                px[x + dx, bot[x + dx]] = (44, 42, 48, 255)
                px[x + dx, bot[x + dx] - 1] = (128, 124, 120, 255) if dx < 2 else (92, 90, 96, 255)
            px[x + 1, bot[x + 1] - 2] = (150, 146, 140, 255)
        x += rnd.randint(5, 10)
    return im


def stone_base(im, stair_cols=(0, -1)):
    """The Dungeon sprite stood on a cut-soil slab, a brown band under its grass like a floating
    island's underside. The band becomes a stacked-stone retaining face like the plateau's walls,
    and under the stair (its columns) the steps carry on down to the plateau's path."""
    im = im.copy()
    px = im.load()
    bot = _bottoms(im)
    cx = base_corner(im)[0]
    soil = lambda c: c[3] > 128 and c[0] >= c[1] >= c[2] - 4 and c[0] - c[2] >= 14 and c[0] + c[1] + c[2] < 330
    for x, b in enumerate(bot):
        if b is None:
            continue
        band = [y for y in range(max(0, b - 13), b + 1) if soil(px[x, y])]
        if not band:
            continue
        top = band[0]
        stair = stair_cols[0] <= x <= stair_cols[1]
        shade = 0.74 if x > cx else 0.88     # as dark as the plateau walls; the south-east face in shadow
        for y in range(top, b + 1):
            d = b - y
            if d == 0:
                c = (36, 34, 40)
            elif stair:                       # treads and risers, two rows each
                c = (146, 142, 136) if (d // 2) % 2 else (84, 82, 88)
            else:
                course = d // 4
                joint = (x + (course % 2) * 5) % 10 == 0
                if d % 4 == 0 or joint:
                    c = (50, 48, 56)
                else:
                    c = ((98, 96, 102), (112, 110, 114), (124, 120, 122))[(x // 10 + course * 7) % 3]
                    if d % 4 == 3:            # each stone's lit top edge
                        c = tuple(min(255, v + 18) for v in c)
            px[x, y] = tuple(int(v * shade) for v in c) + (255,)
    return im


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
    if lid == "church" and spec["file"] == "church.png":
        im = no_statue(im)
    if lid == "clinic":
        im = wall_cross(im)
    if lid == "gate":                  # the dungeon entrance on stone, with its foot on the plateau
        im = _foot(stone_base(im, (20, 98)), skip=((18, 102),))
    if lid == "plateau":               # the plateau's walls meet the street (its stair's foot left clear)
        im = _foot(im, skip=((44, 146),))
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


def staked(im):
    """(Fable round 5, P3) A training dummy's single stake hovered on the flat dirt: a 9x2 ground
    shadow and a 5x2 mound of earth at its foot."""
    im = im.copy()
    px = im.load()
    bb = im.getbbox()
    cx, b = (bb[0] + bb[2]) // 2, min(bb[3], im.height - 1)
    for x in range(cx - 4, cx + 5):          # the shadow, under everything
        for y in (b - 1, b):
            if 0 <= x < im.width and px[x, y][3] == 0 and not (y == b and abs(x - cx) == 4):
                px[x, y] = (24, 18, 22, 110)
    for x in range(cx - 2, cx + 3):          # the mound over the stake's foot
        px[x, b - 1] = (118, 90, 60, 255) if abs(x - cx) < 2 else (92, 70, 48, 255)
        px[x, b - 2] = px[x, b - 2] if abs(x - cx) > 1 else (104, 80, 54, 255)
    return im


def no_statue(im):
    """(Fable round 5, P1) The Church's corner statue stood behind the Shop's roof, so it read as
    standing on that roof: it goes, and the facade's wall one stone course back fills its place."""
    im = im.copy()
    src, px = im.copy().load(), im.load()
    pale = {(x, y) for y in range(214, 264) for x in range(100, 124)
            if src[x, y][3] and min(src[x, y][:3]) > 120 and max(src[x, y][:3]) - min(src[x, y][:3]) < 45}
    for x, y in {(x + a, y + b) for x, y in pale for a in (-1, 0, 1) for b in (-1, 0, 1)}:   # with its outline
        px[x, y] = src[x - 12, y - 6]
    return im


def wall_cross(im):
    """(Fable round 5, P4) The Clinic's green cross stood on a post behind the ridge, floating over
    the roof: it hangs on the front gable's apex instead, a wall sign."""
    im = im.copy()
    src, px = im.copy().load(), im.load()
    green = {(x, y) for y in range(10, 35) for x in range(44, 68)
             if src[x, y][3] and src[x, y][1] > 90 and src[x, y][1] > src[x, y][0] + 25}
    cross, todo = set(green), list(green)                 # the cross and all that hangs on it, not the ridge
    while todo:
        x, y = todo.pop()
        for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if n not in cross and 40 <= n[0] < 72 and 4 <= n[1] <= 33 and src[n][3]:
                cross.add(n)
                todo.append(n)
    for x, y in cross:
        px[x, y] = (0, 0, 0, 0)
    for x, y in cross:
        px[x - 6, y + 26] = src[x, y]
    return im


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
    # the front wall meets the gatehouse flush (Juzo: "broken walls"): the last run west of it ends
    # on its west face; the first east of it starts one cell inside, drawn before the gatehouse so
    # the tower hides the join (the tower art stops short of its lot edge; starting on the face
    # left a gap, and drawn after the gatehouse the run stood in front of the tower). A run
    # overlapping its neighbour shows one more buttress, no seam.
    front = [s for s in range(3, N - 3, 4) if s + 3 < gx0 or s > gx1]
    if max(s for s in front if s < gx0) + 3 < gx0 - 1:
        front.append(gx0 - 4)
    front.append(gx1)
    gate_key = at(gx1 + 1, gy1 + 1)[1] + SPRITES.get("gatehouse", {}).get("sort", 0)
    WALL_RUNS.clear()
    for s in range(3, N - 3, 4):
        for j in (0,):                     # along i, the back wall
            put(sprites, runs[pick(s, j)], at(s, j), (OXR, OYR), at(s + 4, j + 1)[1] - 1)
            WALL_RUNS.append(("i", j, s))
    for s in sorted(front):                # along i, the front wall either side of the gatehouse
        j = N - 1
        put(sprites, runs[pick(s, j)], at(s, j), (OXR, OYR), gate_key - 1 if s == gx1 else at(s + 4, j + 1)[1] - 1)
        WALL_RUNS.append(("i", j, s))
    for s in range(3, N - 3, 4):
        for i in (0, N - 1):               # along j
            WALL_RUNS.append(("j", i, s))
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
WALL_RUNS = []     # (axis, the wall's row or column, first cell) of each 4-cell run of the last compose


def building_clash():
    """(Juzo: the Clinic's deck hung over the town wall) for the last compose: a building drawn over
    a building or a front wall run that stands in front of it, and a building whose base comes
    within 8 px of a front wall's top, so it seems to sit on the battlements. Returns [(lot, why)]."""
    import numpy as np
    order, solid, a_of = _cover_setup()
    lots = {l[0]: l[2:6] for l in LOTS if l[0] not in EMPTY}
    sp = LAST_SPRITES
    front_runs = []
    for k, s in enumerate(sp):
        _, x, y, im, tag = s
        if tag == "" and id(s) not in {id(p) for p, _ in PROPS}:
            front_runs.append(k)
    bad = []
    for k, s in enumerate(sp):
        _, x, y, im, tag = s
        if tag not in lots:
            continue
        a = a_of(im)
        x0, y0, x1, y1 = lots[tag]
        for k2, s2 in enumerate(sp[:k]):
            _, x2, y2, im2, tag2 = s2
            if tag2 in lots:
                bx0, by0, bx1, by1 = lots[tag2]
                if not (x1 < bx0 or y1 < by0):    # only one wholly in front of it counts
                    continue
            elif k2 not in front_runs:
                continue
            elif y2 + im2.height <= y + im.height:   # a wall run counts when its foot is in front
                continue
            X0, Y0 = max(x, x2), max(y, y2)
            X1, Y1 = min(x + im.width, x2 + im2.width), min(y + im.height, y2 + im2.height)
            if X1 > X0 and Y1 > Y0:
                n = int((a[Y0 - y:Y1 - y, X0 - x:X1 - x] & a_of(im2)[Y0 - y2:Y1 - y2, X0 - x2:X1 - x2]).sum())
                if n >= 4:
                    bad.append((tag, f"drawn over {tag2 or 'the wall'} in front of it ({n} px)"))
        # the base right on a front wall's top
        cols = a.any(axis=0)
        for cx in np.nonzero(cols)[0]:
            by = int(np.nonzero(a[:, cx])[0][-1]) + y
            gx = cx + x
            for k2 in front_runs:
                _, x2, y2, im2, _ = sp[k2]
                if not (x2 <= gx < x2 + im2.width):
                    continue
                col = a_of(im2)[:, gx - x2]
                top = np.nonzero(col)[0]
                if len(top) and 0 <= top[0] + y2 - by <= 8 and y2 + im2.height > y + im.height:
                    bad.append((tag, f"base sits on the wall top at x {gx}"))
                    break
            else:
                continue
            break
    return bad


def wall_gaps():
    """The wall circuit check (Juzo: "broken walls"): along each side every cell from corner tower
    to corner tower is wall, a tower or the gatehouse, and no run starts or ends inside the
    gatehouse. Returns [(side, cell, why)]."""
    gx0, gy0, gx1, gy1 = GATEHOUSE
    bad = []
    for axis, line in (("i", 0), ("i", N - 1), ("j", 0), ("j", N - 1)):
        cover = set()
        for a, l, s in WALL_RUNS:
            if (a, l) == (axis, line):
                cover |= set(range(s, s + 4))
                if axis == "i" and line == N - 1 and (gx0 <= s < gx1 or gx0 < s + 3 <= gx1):   # one cell tucked under a tower is the join
                    bad.append((f"{axis}{line}", s, "a run ends inside the gatehouse"))
        for tx, ty in TOWERS:
            k, t = (tx, ty) if axis == "i" else (ty, tx)
            if t <= line <= t + 2:
                cover |= set(range(k, k + 3))
        if axis == "i" and line == N - 1:
            cover |= set(range(gx0, gx1 + 1))
        bad += [(f"{axis}{line}", c, "gap") for c in range(N) if c not in cover]
    return bad
PROPS = []         # (sprite, decor entry) for every prop, fence and tree of the last compose (the floating check)
LAST_SPRITES = []  # the sorted sprites of the last compose (export_town builds walker occluders from them)
BOXES = {}      # sprite id -> opaque box on the town canvas (tap areas for town.json)
NO_OVERLAYS = []  # [True] -> leave out walkers and level props (the game draws those itself)
LIT = [True]      # False -> the day picture: windows are glass, torches and lamps unlit (the forge still burns)
FLAMES = {("props32", 12), ("props32", 11), ("props_up", 4), ("props_up", 5), ("props_up", 16), ("props48", 10)}   # torches, candles, braziers, lanterns, lamps
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


VIS = {}   # entry -> the share of its pixels still showing, for props the floating check flags


def _cover_setup():
    """For the last compose: sprite -> draw order, the sprites that hide what they cover (everything
    but the props, the bridge and the outside wood: buildings, towers, the wall runs), and a cached
    alpha mask getter."""
    import numpy as np
    order = {id(s): k for k, s in enumerate(LAST_SPRITES)}
    alpha = {}
    def a_of(im):
        if id(im) not in alpha:
            alpha[id(im)] = np.asarray(im.split()[3]) > 0
        return alpha[id(im)]
    mine = {id(s) for s, _ in PROPS + OUTSIDE_SPRITES}
    solid = [(k, s) for k, s in enumerate(LAST_SPRITES) if id(s) not in mine and s[4] not in ("bridge", "outside")]
    return order, solid, a_of


def _feet_cover(s, order, solid, a_of):
    """The share of a sprite's feet (the bottom 3 rows of its opaque pixels) drawn over by a later
    solid sprite, and the first one's tag."""
    import numpy as np
    _, x, y, im, _ = s
    a = a_of(im)
    rows = np.nonzero(a.any(axis=1))[0]
    if not len(rows):
        return 0.0, None
    feet = np.zeros_like(a)
    feet[rows[-1] - 2:rows[-1] + 1] = a[rows[-1] - 2:rows[-1] + 1]
    fy, fx = np.nonzero(feet)
    cover = np.zeros(len(fx), bool)
    by = None
    for k, s2 in solid:
        if k <= order[id(s)]:
            continue
        _, x2, y2, im2, tag = s2
        ox, oy = fx + x - x2, fy + y - y2
        ok = (ox >= 0) & (oy >= 0) & (ox < im2.width) & (oy < im2.height)
        if not ok.any():
            continue
        hit = np.zeros(len(fx), bool)
        hit[ok] = a_of(im2)[oy[ok], ox[ok]]
        if hit.any() and by is None:
            by = tag
        cover |= hit
    return float(cover.mean()), by


def cull_fences():
    """A fence is a long thing: the pieces whose foot runs behind a building or the wall are simply
    left out (a fence that meets a wall stops there), so no rail floats over a roof."""
    order, solid, a_of = _cover_setup()
    gone = {id(s) for s, e in PROPS if e[0] == "fence" and _feet_cover(s, order, solid, a_of)[0] >= 0.5}
    LAST_SPRITES[:] = [s for s in LAST_SPRITES if id(s) not in gone]
    PROPS[:] = [(s, e) for s, e in PROPS if id(s) not in gone]


def _visible(s, order, solid, a_of):
    import numpy as np
    _, x, y, im, _ = s
    a = a_of(im)
    py_, px_ = np.nonzero(a)
    cover = np.zeros(len(px_), bool)
    for k, s2 in solid:
        if k <= order[id(s)]:
            continue
        _, x2, y2, im2, _ = s2
        ox, oy = px_ + x - x2, py_ + y - y2
        ok = (ox >= 0) & (oy >= 0) & (ox < im2.width) & (oy < im2.height)
        if ok.any():
            cover[ok] |= a_of(im2)[oy[ok], ox[ok]]
    return round(1 - cover.mean(), 2) if len(px_) else 0


def floating():
    """The floating check (Juzo: props covered by buildings look like they float): every prop,
    fence and tree of the last compose whose feet (the bottom 3 rows of its opaque pixels) are
    mostly drawn over by a later building, wall or tower, or that stands off the ground (on a lot,
    in the water, on the wall ring or a plateau edge). A tree may stand behind a roof as long as
    most of its crown shows; the footbridge's rails stand over the water. Returns [(entry, why)]."""
    order, solid, a_of = _cover_setup()
    props = PROPS + OUTSIDE_SPRITES
    mine_ids = {id(s2) for s2, _ in props}
    g = {}
    for kind, x0, y0, x1, y1 in GROUND:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                g[(i, j)] = kind
    blocks = [l[2:6] for l in LOTS if l[0] not in EMPTY] + [h[:4] for h in HOUSES]
    towers = [(ti, tj, ti + 2, tj + 2) for ti, tj in TOWERS] + [GATEHOUSE]
    inside = lambda c, r: r[0] <= c[0] <= r[2] and r[1] <= c[1] <= r[3]
    bad = []
    import numpy as np
    sprites = LAST_SPRITES
    building = lambda tag: tag not in ("", "bridge", "outside", "plateau") and not tag.startswith("tower")
    def overlap(s, k_from, k_to, keep, rows=None):
        """Opaque pixels of sprite s shared with the sprites k_from..k_to that `keep` accepts:
        (count, first tag). rows=(a, b) limits s to that share of its height."""
        _, x, y, im, _ = s
        a = a_of(im)
        if rows:
            a = a.copy()
            h = a.shape[0]
            a[:int(h * rows[0])] = False
        fy, fx = np.nonzero(a)
        hit = np.zeros(len(fx), bool)
        by = None
        for k2 in range(max(0, k_from), min(len(sprites), k_to)):
            s2 = sprites[k2]
            if s2 is s or not keep(s2):
                continue
            _, x2, y2, im2, tag2 = s2
            ox, oy = fx + x - x2, fy + y - y2
            ok = (ox >= 0) & (oy >= 0) & (ox < im2.width) & (oy < im2.height)
            if not ok.any():
                continue
            h2 = np.zeros(len(fx), bool)
            h2[ok] = a_of(im2)[oy[ok], ox[ok]]
            if h2.any() and by is None:
                by = names.get(id(s2)) or tag2 or "the wall"
            hit |= h2
        return int(hit.sum()), by
    names = {id(s2): f"{e2[0]} {e2[1]} at {e2[2]},{e2[3]}" for s2, e2 in props}
    folk_ids = {id(s2) for s2, e2 in props if e2[0] == "folk"}   # the mockup's figures (the game has its own)
    up_ids = {id(s2) for s2, e2 in PROPS if e2[0] == "props_up"}
    stall_ids = {id(s2) for s2, e2 in PROPS if e2[0] == "props48" and e2[1] in STALLS}
    for s, e in props:
        if e[0] == "folk":               # the mockup's figures: the game has its own walkers
            continue
        k = order.get(id(s))
        if k is not None and e[0] == "props_up" and (e[2], e[3]) not in _braziers():   # (braziers are in the base)
            # town_view draws the level props over the flat base picture, so anything the composer
            # sorts in front of one (Juzo: the Shop's level props over the purple stall) would be
            # drawn over in the game
            # a building is behind a prop on its street side whatever the composer's sort key says
            # (a big sprite sorts by its front corner); only one it really stands in front of counts
            lot = {l[0]: l[2:6] for l in LOTS}
            ahead = lambda s2: (id(s2) not in up_ids and id(s2) not in folk_ids and not (s2[4] in lot and (e[2] > lot[s2[4]][2] or e[3] > lot[s2[4]][3])))
            n, by = overlap(s, k + 1, len(sprites), ahead)
            if n >= 8:
                bad.append((e, f"in the game drawn over {by} in front of it ({n} px)"))
        if k is not None and e[0] != "fence":
            # the foot half on a building's plinth, half off it (Juzo: the Shop's crates on its edge)
            _, x, y, im, _ = s
            a = a_of(im)
            rows_ = np.nonzero(a.any(axis=1))[0]
            if len(rows_):
                b = rows_[-1]
                foot = np.zeros_like(a)
                foot[b - 1:b + 1] = a[b - 1:b + 1]
                fy, fx = np.nonzero(foot)
                on = np.zeros(len(fx), bool)
                for k2 in range(k):
                    _, x2, y2, im2, tag2 = sprites[k2]
                    if not building(tag2) or id(sprites[k2]) in mine_ids:
                        continue
                    ox, oy = fx + x - x2, fy + y - y2
                    ok = (ox >= 0) & (oy >= 0) & (ox < im2.width) & (oy < im2.height)
                    if ok.any():
                        h2 = np.zeros(len(fx), bool)
                        h2[ok] = a_of(im2)[oy[ok], ox[ok]]
                        on |= h2
                share = on.mean() if len(on) else 0
                if 0.2 <= share <= 0.8:
                    bad.append((e, f"foot on a building's base edge ({share:.0%})"))
        if k is not None and id(s) in stall_ids:
            # a stall never overlaps a building, in front or behind (its lower half)
            n, by = overlap(s, 0, len(sprites), lambda s2: building(s2[4]) and id(s2) not in mine_ids, rows=(0.5, 1))
            if n >= 10:
                bad.append((e, f"stall overlaps {by} ({n} px)"))
            # nor straight behind another stall without a gap (the purple stall stood on the blue one's
            # roof like a second storey): a stall in front within 40 px across starts 10 px below its foot
            _, x, y, im, _ = s
            for s2, e2 in PROPS:
                if id(s2) in stall_ids and s2 is not s:
                    _, x2, y2, im2, _ = s2
                    dx, dy = (x2 + im2.width / 2) - (x + im.width / 2), (y2 + im2.height) - (y + im.height)
                    if abs(dx) < 40 and 0 < dy < im2.height + 10:
                        bad.append((e, f"stall stacked behind {e2[0]} {e2[1]} at {e2[2]},{e2[3]}"))
        cover, by = _feet_cover(s, order, solid, a_of)
        if cover >= 0.5:
            VIS[tuple(e[:4])] = v = _visible(s, order, solid, a_of)
            if e[0] != "trees" or v < 0.4:
                bad.append((e, f"feet under {by or 'the wall'}"))
        outside = not inside((e[2], e[3]), (0, 0, N - 1, N - 1))
        if outside or e[0] in ("fence", "trees") and not inside((e[2], e[3]), (1, 1, N - 2, N - 2)):
            continue                     # the forest and the things outside the walls stand on their own ground
        c = (e[2], e[3])
        z = e[4] if e[0] != "fence" and len(e) > 4 else 0
        on_plateau = inside(c, (PLATEAU[0], PLATEAU[1], PLATEAU[2], PLATEAU[3]))
        if e[0] != "fence" and any(inside(c, r) for r in blocks):
            bad.append((e, "on a building lot"))
        elif g.get(c) == "water" and not (e[0] == "fence" and g.get((c[0] - 1, c[1])) in ("planks", "bridge")):
            bad.append((e, "in the water"))
        elif not inside(c, (1, 1, N - 2, N - 2)) or any(inside(c, r) for r in towers):
            bad.append((e, "on the wall"))
        elif on_plateau != (z >= PLATEAU_Z) and e[0] != "fence":
            bad.append((e, "off the plateau's level"))
    return bad


STALLS = (0, 1, 2, 3, 4)   # props48: the market stalls


def _braziers():
    import decor
    return decor.BRAZIERS


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
    OUTSIDE_SPRITES.clear()
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
            if (name, n) == ("props32", 40):       # the dummy / scarecrow stake gets a foot
                im = staked(im)
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
    PROPS.clear()
    for e in deco:
        if e[0] == "fence":
            _, kind, i, j, axis = e
            im, anchor = fence_piece(kind, axis)
            a = at(i, j)
            b = at(i + 1, j) if axis == "i" else at(i, j + 1)
            put(sprites, im, a, anchor, max(a[1], b[1]) + 1)
            PROPS.append((sprites[-1], e))
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
        PROPS.append((sprites[-1], e))
    for n, i, j, dx, dy in trees():
        im = sheet("trees", n)
        x, y = at(i + .5, j + .5)
        put(sprites, im, (x + dx, y + dy + 4), bottom(im), y + dy + 6)
        PROPS.append((sprites[-1], ("trees", n, i, j)))
    sprites.sort(key=lambda s: s[0])
    LAST_SPRITES[:] = sprites
    cull_fences()
    sprites = LAST_SPRITES
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
