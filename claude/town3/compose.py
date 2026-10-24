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
           "square": "flag", "water": "water", "bridge": "cobble", "path": "cobble", "dirt": "dirt", "garden": "grass", "field": "dirt", "pen": "grass"}


def load_tiles():
    t = {}
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
    if spec.get("flip"):
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    import decor as _d
    if _d.LEVEL == 1 and lid in _d.LEVEL_ITEMS:
        im = level1_look(im)
    dx, dy = spec.get("nudge", (0, 0))
    front = at(x1 + 1, y1 + 1)[1] + spec.get("sort", 0)
    if "origin" in spec:
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
    run = load("wall_run.png")
    mir = run.transpose(Image.FLIP_LEFT_RIGHT)
    mir = Image.merge("RGBA", (*ImageEnhance.Brightness(mir.convert("RGB")).enhance(0.8).split(), mir.getchannel("A")))
    OXR, OYR = 20, 60                      # pixel of the run's vertex (0, 0) on its canvas
    gx0, gy0, gx1, gy1 = GATEHOUSE
    for s in range(3, N - 3, 4):
        for j in (0, N - 1):               # along i
            if j == N - 1 and s + 3 >= gx0 + 1 and s <= gx1 - 1:
                continue
            put(sprites, run, at(s, j), (OXR, OYR), at(s + 4, j + 1)[1] - 1)
        for i in (0, N - 1):               # along j
            put(sprites, mir, at(i + 1, s), (run.width - OXR, OYR), at(i + 1, s + 4)[1] - 1)
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
EMPTY = set()   # lot ids drawn as empty building plots (Church / Trophy Cabin before they're built)
HARDCORE = []   # [True] -> ruined dark Church, no church glow, the graveyard full


def compose():
    img = Image.new("RGBA", (W, H), (20, 18, 30, 255))
    tiles = load_tiles()
    outside(img, tiles)
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
            im = load(f"folk/{n}.png" if name == "folk" else f"{name}/{'t' if name == 'trees' else 'p'}{n}.png")
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
        deco = [e for e in deco if e[0] not in ("folk", "props_up")]
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
    for _, x, y, im, _ in sprites:
        img.alpha_composite(im, (x, y))
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
    if GROUND_IMG:                     # light pools land on the visible ground only
        ground = GROUND_IMG[0].convert("RGB")
        same = ImageChops.difference(ground, rgb).convert("L").point(lambda v: 255 if v < 3 else 0)
        glow = ImageChops.multiply(glow, Image.merge("RGB", (same, same, same)))
    beam = Image.new("RGB", rgb.size, (0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bx, by = at(19.9, 4.0, PLATEAU_Z + 30)
    for w, f in ((26, .10), (16, .16), (8, .24)):
        bd.polygon([(bx - w, by), (bx + w, by), (bx + w * .6, by - 150), (bx - w * .6, by - 150)], fill=(int(90 * f * 2), int(210 * f * 2), int(255 * f * 2)))
    glow = ImageChops.add(glow, beam)
    out = ImageChops.add(dark, glow)
    if HARDCORE:                       # the whole town colder and greyer...
        out = ImageEnhance.Color(out).enhance(0.85)
        out = ImageChops.multiply(ImageEnhance.Brightness(out).enhance(0.95), Image.new("RGB", out.size, (225, 232, 255)))
    if HARDCORE:                       # ...and a cold, dead corner around the ruined church and graveyard
        mask = Image.new("L", out.size, 0)
        ImageDraw.Draw(mask).polygon([at(0, 0), at(13, 0), at(13, 19), at(0, 19)], fill=128)
        blue = ImageChops.multiply(out, Image.new("RGB", out.size, (150, 165, 200)))
        out = Image.composite(blue, out, mask)
    return out


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
