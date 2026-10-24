"""Composes the new town from PixelLab pieces (claude/town2/gen) plus code depth layers
(art-pipeline 9): Wang ground tiles recoloured to the dark palette, a raised plateau with a
procedural cliff face, cast shadows on their own layer, y-sorted sprites, fog beyond the
wall, and a dusk grade with hard-edged light pools.
Usage: py compose.py sample <out_dir>"""
import json
import math
import random
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

GEN = "gen"
T = 16

RAMPS = {
    "grass": ["#1c261f", "#25331f", "#2f3f2a", "#3b4d33", "#4a5c3e", "#5b6c4a"],
    "stone": ["#211f27", "#2d2b35", "#3a3844", "#4a4855", "#5c5a68", "#706e7c"],
    "dirt": ["#241b17", "#30241d", "#3d2f25", "#4b3a2d", "#5a4636"],
    "flag": ["#26252c", "#33323b", "#42414b", "#53525d", "#66656f", "#7a7984"],
}


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def regrade(im, green_ramp, other_ramp):
    """Gradient-map a tile sheet: green pixels onto green_ramp, the rest onto other_ramp,
    each by its own luminance range so both keep their texture."""
    im = im.convert("RGBA")
    px = im.load()
    groups = {True: [], False: []}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                groups[g > r + 12 and g > b + 12].append(lum((r, g, b)))
    rng = {k: (min(v), max(v)) if v else (0, 255) for k, v in groups.items()}
    ramps = {True: [hexc(h) for h in green_ramp], False: [hexc(h) for h in other_ramp]}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if not a:
                continue
            k = g > r + 12 and g > b + 12
            lo, hi = rng[k]
            t = (lum((r, g, b)) - lo) / max(1.0, hi - lo)
            ramp = ramps[k]
            px[x, y] = ramp[min(len(ramp) - 1, int(t * len(ramp)))] + (255,)
    return im


class Wang:
    """A 16-tile corner set: (NW, NE, SW, SE) upper flags -> tile image."""

    def __init__(self, name, green_ramp, other_ramp, gen=None):
        gen = gen or GEN
        sheet = regrade(Image.open(f"{gen}/ts_{name}.png"), green_ramp, other_ramp)
        meta = json.load(open(f"{gen}/ts_{name}.json"))
        self.tiles = {}
        for t in meta["tileset_data"]["tiles"]:
            c, b = t["corners"], t["bounding_box"]
            key = tuple(c[k] == "upper" for k in ("NW", "NE", "SW", "SE"))
            self.tiles[key] = sheet.crop((b["x"], b["y"], b["x"] + b["width"], b["y"] + b["height"]))


def load_sprite(name, path=None):
    im = Image.open(path or f"{GEN}/{name}.png").convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    im.putalpha(a)
    return im.crop(im.getbbox())


class Town:
    def __init__(self, w, h, seed=7):
        self.w, self.h = w, h
        self.cw, self.ch = w // T, h // T
        self.rng = random.Random(seed)
        # vertex terrain: 0 grass, 1 cobble, 2 dirt
        self.v = [[0] * (self.cw + 1) for _ in range(self.ch + 1)]
        self.sprites = []   # (foot_y, x, y, image, shadow?)
        self.lights = []    # (x, y, radius, colour)
        self.plateaus = []  # (x0, y0, x1, y1, face_h) in px, tile aligned
        self.stairs = []    # (x, width) cut into the plateau face
        self.walls = []
        self.fog_trees = []  # (image, x, foot_y, alpha)
        self.fence_runs = []  # (x0, y0, x1, y1) rectangle outlines of fences
        self.plots = []  # (x0, y0, x1, y1) crop beds

    def paint(self, kind, x0, y0, x1, y1):
        """Vertices inside the tile rect [x0,x1]x[y0,y1] (inclusive, in tiles) become kind."""
        for y in range(max(0, y0), min(self.ch, y1) + 1):
            for x in range(max(0, x0), min(self.cw, x1) + 1):
                self.v[y][x] = kind

    def add(self, im, x, y, shadow=True, foot=None):
        """Places a sprite with its bottom-left at (x, y) (feet), y-sorted by foot."""
        self.sprites.append((foot if foot is not None else y, x, y - im.height, im, shadow))

    def ground(self, cob, dirt):
        g = Image.new("RGBA", (self.w, self.h))
        base = cob.tiles[(False,) * 4]
        for cy in range(self.ch):
            for cx in range(self.cw):
                c = (self.v[cy][cx], self.v[cy][cx + 1], self.v[cy + 1][cx], self.v[cy + 1][cx + 1])
                if 1 in c:
                    tile = cob.tiles[tuple(k == 1 for k in c)]
                elif 2 in c:
                    tile = dirt.tiles[tuple(k == 2 for k in c)]
                else:
                    tile = base
                    if self.rng.random() < 0.5:  # break the repeat
                        tile = tile.transpose(Image.FLIP_LEFT_RIGHT)
                g.paste(tile, (cx * T, cy * T))
        return g

    def tufts(self, g):
        """Calm ground detail: a few grass tufts and pebbles (2-3 values, no noise)."""
        d = ImageDraw.Draw(g)
        dark, lite = hexc("#22301f"), hexc("#55673f")
        for _ in range(self.w * self.h // 700):
            x, y = self.rng.randrange(self.w), self.rng.randrange(self.h)
            cx, cy = x // T, y // T
            if any(self.v[cy + j][cx + i] for i in (0, 1) for j in (0, 1)):
                continue
            k = 1  # 1 px detail at every scale: one pixel density
            for (px_, py_, c) in ((0, 0, dark), (2, 0, dark), (1, -1, dark), (1, -2, lite), (3, -1, dark), (2, -3, lite)):
                d.rectangle([x + px_ * k, y + py_ * k, x + px_ * k + k - 1, y + py_ * k + k - 1], c)

    def draw_plateau(self, img, flag_tile):
        d = ImageDraw.Draw(img)
        for (x0, y0, x1, y1, fh) in self.plateaus:
            # top surface: flagstones
            for y in range(y0, y1, T):
                for x in range(x0, x1, T):
                    t = flag_tile if (x // T + y // T) % 3 else flag_tile.transpose(Image.FLIP_LEFT_RIGHT)
                    img.paste(t, (x, y))
            # front face: strata bands, cracks, lip, base shadow (9.1b)
            bands = [hexc(c) for c in ("#4a4652", "#3d3a45", "#312e38", "#26242c")]
            for i in range(fh):
                d.line([x0, y1 + i, x1 - 1, y1 + i], bands[min(3, i * 4 // fh)])
            for y in (y1 + fh // 3, y1 + 2 * fh // 3):
                d.line([x0, y, x1 - 1, y], hexc("#211f27"))
            k = T // 16
            x = x0 + self.rng.randint(4, 8) * k
            while x < x1 - 2:
                top = y1 + self.rng.randint(1, fh // 2)
                d.line([x, top, x + self.rng.choice((-1, 0, 1)), top + self.rng.randint(4, fh - 2)], hexc("#1b1a20"))
                d.line([x + 1, top, x + 1, top + 3], hexc("#55525e"))
                x += self.rng.randint(5, 9) * k
            k = T // 16
            d.rectangle([x0, y1, x1 - 1, y1 + k - 1], hexc("#8a8896"))  # lit lip
            d.rectangle([x0, y1 + k, x1 - 1, y1 + 2 * k - 1], hexc("#5f5c6a"))
            for sx, sw in self.stairs:  # steps cut into the face
                st = 4 * (T // 16)
                for i in range(0, fh, st):
                    d.rectangle([sx, y1 + i, sx + sw - 1, y1 + i + st - 1], hexc("#5a5864"))
                    d.line([sx, y1 + i + st - 1, sx + sw - 1, y1 + i + st - 1], hexc("#2c2a33"))
                    d.line([sx, y1 + i, sx + sw - 1, y1 + i], hexc("#6e6c7a"))
                d.line([sx - 1, y1, sx - 1, y1 + fh], hexc("#1b1a20"))
                d.line([sx + sw, y1, sx + sw, y1 + fh], hexc("#1b1a20"))
            # side faces, and a darker strip on the ground under the face
            for sx in (x0, x1 - 2):
                d.rectangle([sx, y0, sx + 1, y1 + fh - 1], hexc("#2d2b35"))
            sh = Image.new("RGBA", img.size)
            ImageDraw.Draw(sh).rectangle([x0 + 2, y1 + fh, x1 + 3, y1 + fh + 4], (10, 8, 20, 110))
            img.alpha_composite(sh)

    def fences(self, img):
        d = ImageDraw.Draw(img)
        soil, furrow, leaf = hexc("#2f241d"), hexc("#21190f"), hexc("#3f5232")
        for (x0, y0, x1, y1) in self.plots:
            d.rectangle([x0, y0, x1, y1], soil)
            k = T // 16
            for y in range(y0 + 3 * k, y1, 8 * k):
                d.rectangle([x0 + 1, y + 3 * k, x1 - 1, y + 4 * k - 1], furrow)
                for x in range(x0 + 3 * k, x1 - 3 * k, 7 * k):
                    if self.rng.random() < 0.8:  # crops: cabbages, a few pumpkins
                        if self.rng.random() < 0.15:
                            d.ellipse([x - k, y - k, x + 3 * k, y + 2 * k], hexc("#8a4a1f"), outline=hexc("#3a1e10"))
                            d.rectangle([x, y - k, x + k - 1, y - 1], hexc("#c06a2a"))
                        else:
                            d.ellipse([x - k, y - k, x + 3 * k, y + 2 * k], leaf, outline=hexc("#1c2416"))
                            d.rectangle([x + k, y - k + 1, x + 2 * k - 1, y], hexc("#5d7044"))
        post, rail, rail_l = hexc("#3b2a1e"), hexc("#4e3826"), hexc("#6b5038")
        k = T // 16
        for (x0, y0, x1, y1) in self.fence_runs:
            for y in (y0, y1):
                d.rectangle([x0, y - 6 * k, x1, y - 5 * k], rail)
                d.line([x0, y - 6 * k, x1, y - 6 * k], rail_l)
                d.rectangle([x0, y - 3 * k, x1, y - 2 * k], rail)
                for x in range(x0, x1 + 1, 16 * k):
                    d.rectangle([x - k, y - 10 * k, x + k, y], post)
                    d.rectangle([x - k, y - 10 * k, x - k + k - 1, y - 10 * k + k - 1], rail_l)
            for x in (x0, x1):
                d.rectangle([x - k + 1, y0 - 5 * k, x + k - 1, y1 - 5 * k], rail)
                for y in range(y0, y1 + 1, 12 * k):
                    d.rectangle([x - k, y - 10 * k, x + k, y], post)

    def shadows(self, img):
        """One light from the top-left: every sprite casts a short shadow down-right (9.1)."""
        sh = Image.new("L", img.size, 0)
        for (foot, x, y, im, cast) in self.sprites:
            if not cast:
                continue
            a = im.getchannel("A")
            # only the lower part of the silhouette casts (keeps shadows short), skewed right
            h = im.height
            band = a.crop((0, int(h * 0.45), im.width, h))
            band = band.transform(band.size, Image.AFFINE, (1, 0.35, -band.height * 0.35, 0, 1, 0))
            sh.paste(255, (x + 5, y + int(h * 0.45) + 3), band)
        shade = Image.new("RGBA", img.size, (12, 10, 28, 120))
        img.paste(Image.alpha_composite(img, shade), (0, 0), sh)

    def render(self, cob, dirt, flag_tile, fog_top=0):
        img = self.ground(cob, dirt)
        self.tufts(img)
        self.draw_plateau(img, flag_tile)
        if fog_top:
            self.fog(img, fog_top)
        self.fences(img)
        self.shadows(img)
        for (foot, x, y, im, cast) in sorted(self.sprites, key=lambda s: s[0]):
            img.alpha_composite(im, (x, y))
        return img

    def fog(self, img, y1):
        """Beyond the wall: grey-violet fog with dead-tree silhouettes fading into it."""
        f = Image.new("RGBA", img.size)
        d = ImageDraw.Draw(f)
        for y in range(y1):
            a = int(70 + 140 * (1 - y / y1) ** 1.4)
            d.line([0, y, self.w, y], (52, 50, 66, a))
        img.alpha_composite(f)
        # dead trees out in the fog, fading with distance
        for (im, x, y, a) in self.fog_trees:
            ghost = Image.new("RGBA", im.size, (40, 38, 52, 255))
            ghost.putalpha(im.getchannel("A").point(lambda v: a if v else 0))
            img.alpha_composite(ghost, (x, y - im.height))
        f2 = Image.new("RGBA", img.size)
        d2 = ImageDraw.Draw(f2)
        for y in range(y1):
            d2.line([0, y, self.w, y], (60, 58, 76, int(90 * (1 - y / y1))))
        img.alpha_composite(f2)


def dusk(img, lights):
    """Dusk grade: cool and dark, then warm hard-edged light pools (2-3 steps) added on top."""
    r, g, b, a = img.split()
    graded = Image.merge("RGB", (r.point(lambda v: v * 0.55), g.point(lambda v: v * 0.55), b.point(lambda v: v * 0.78)))
    pool = Image.new("RGB", img.size, (0, 0, 0))
    d = ImageDraw.Draw(pool)
    for (x, y, rad, col) in lights:
        c = hexc(col)
        for k, f in ((1.0, 0.07), (0.72, 0.13), (0.45, 0.2)):
            rr = rad * k
            d.ellipse([x - rr, y - rr * 0.6, x + rr, y + rr * 0.6], tuple(int(v * f) for v in c))
    pool = Image.blend(pool, pool.filter(ImageFilter.BoxBlur(2)), 0.5)
    graded = ImageChops.add(graded, pool)
    # keep emissive pixels (windows, flames, runes) bright; pale glass next to lit panes glows warm
    src = img.convert("RGB")
    sp = src.load()
    lit = Image.new("L", img.size, 0)
    lp = lit.load()
    for y in range(img.height):
        for x in range(img.width):
            rr, gg, bb = sp[x, y]
            if rr > 150 and gg > 95 and rr > bb + 70:
                lp[x, y] = 255  # warm: windows, flames
            elif bb > 180 and bb > rr + 60:
                lp[x, y] = 128  # cold: runes
    near = lit.point(lambda v: 255 if v == 255 else 0).filter(ImageFilter.MaxFilter(9)).load()
    out = graded.load()
    for y in range(img.height):
        for x in range(img.width):
            rr, gg, bb = sp[x, y]
            if lp[x, y]:
                out[x, y] = (rr, gg, bb)
            elif near[x, y] and lum((rr, gg, bb)) > 120 and bb >= rr - 10:
                out[x, y] = (min(255, int(rr * 1.0)), int(gg * 0.8), int(bb * 0.4))
    return graded.convert("RGBA")


def day(img):
    """Grim overcast day: a touch desaturated and cool."""
    r, g, b, a = img.split()
    return Image.merge("RGBA", (r.point(lambda v: v * 0.96), g.point(lambda v: v * 0.97), b.point(lambda v: min(255, v * 1.04)), a))


def props(t, rng):
    """Clutter around the buildings (filled in once the prop sheet is picked)."""
    import os
    if not os.path.exists(f"{GEN}/props/pick.json"):
        return
    pick = json.load(open(f"{GEN}/props/pick.json"))
    P = {k: load_sprite(None, f"{GEN}/props/p{v}.png") for k, v in pick.items()}
    for (k, x, y) in SAMPLE_PROPS:
        if k in P:
            t.add(P[k], x, y)
            if k in ("lantern", "lamp2"):
                t.lights.append((x + P[k].width // 2, y - 2, 30, "#ffb347"))


SAMPLE_PROPS = [
    ("barrels", 146, 356), ("barrel", 4, 360), ("sacks", 150, 336), ("lantern", 104, 368), ("crate", 28, 410),
    ("logs", 238, 356), ("stump", 256, 362), ("wheel", 408, 354), ("crates", 410, 400), ("trough", 300, 428),
    ("sign", 190, 278), ("board", 248, 306), ("lamp2", 236, 366),
    ("grave", 60, 168), ("cross", 82, 176), ("grave2", 104, 166),
    ("scarecrow", 92, 492), ("hay", 152, 478), ("cart", 156, 446), ("well", 262, 476),
]


def sample(out):
    cob = Wang("cobble", RAMPS["grass"], RAMPS["stone"])
    dirt = Wang("dirt", RAMPS["grass"], RAMPS["dirt"])
    cliff = regrade(Image.open(f"{GEN}/ts_cliff.png"), RAMPS["grass"], RAMPS["flag"])
    flag = cliff.crop((0, 96, 16, 112))

    W, H = 448, 544
    t = Town(W, H)
    # roads: from the plateau stairs down, then across; short cobble paths to the doors
    t.paint(1, 13, 16, 14, 34)
    t.paint(1, 0, 23, 27, 24)
    t.paint(1, 5, 22, 5, 23)
    t.paint(1, 21, 22, 22, 23)
    t.paint(2, 24, 6, 26, 9)  # the weed-grown track to the sealed gate
    t.paint(2, 25, 9, 25, 16)
    t.paint(2, 22, 16, 25, 16)
    t.plots.append((2 * T + 4, 28 * T + 4, 9 * T - 4, 32 * T - 2))
    t.fence_runs.append((2 * T - 4, 28 * T - 2, 9 * T + 4, 32 * T + 6))

    # raised dungeon plateau (tiles 8..20 x 8..14), face 32 px, stairs in the middle
    t.plateaus.append((8 * T, 8 * T, 20 * T, 14 * T, 32))
    t.stairs.append((13 * T + 2, 2 * T - 4))

    wall = load_sprite("wall")
    tower = load_sprite("tower")
    gate = load_sprite("gatehouse")
    inn = load_sprite("inn")
    smith = load_sprite("smith")
    dungeon = load_sprite("gate")
    trees = [load_sprite(None, f"{GEN}/trees/t{i}.png") for i in range(16)]
    rng = random.Random(3)

    # the wall across the top; fog and dead woods beyond it
    wy = 112
    for i, x in enumerate(range(-30, W, 42)):
        tr = trees[rng.choice((4, 5, 6, 7, 14, 15))]
        t.fog_trees.append((tr, x + rng.randint(-8, 8), 30 + rng.randint(0, 22), 150 + rng.randint(0, 80)))
    x = -20
    while x < W:
        t.add(wall, x, wy, shadow=False, foot=0)
        x += wall.width - 2
    t.add(tower, 24, wy + 20)  # watchtowers face outward, over the fog
    t.add(gate, W - 4 - gate.width, wy + 24)  # the sealed gate: the way out nobody takes
    t.lights += [(36 + 24, wy + 22, 22, "#ffb347"), (W - 4 - gate.width + 18, wy + 26, 20, "#ffb347"),
                 (W - 22, wy + 26, 20, "#ffb347")]

    # the dungeon entrance at the back of the plateau: the lit focal point
    t.add(dungeon, 14 * T - dungeon.width // 2, 12 * T + 4)
    t.lights += [(14 * T - 52, 12 * T, 40, "#ff9a3c"), (14 * T + 52, 12 * T, 40, "#ff9a3c"),
                 (14 * T, 13 * T, 60, "#7fb6ff")]

    # inn (left) and blacksmith (right) facing the cross road
    t.add(inn, 1 * T, 22 * T + 4)
    t.lights += [(1 * T + 64, 22 * T + 14, 44, "#ffb347")]
    t.add(smith, 17 * T + 4, 22 * T + 4)
    t.lights += [(17 * T + 36, 22 * T + 14, 52, "#ff7a2a")]

    # trees: staggered overlapping clusters
    for (tx, ty, kinds) in [
        (-8, 198, (8, 9, 10, 11)), (20, 218, (0, 1, 2)), (-12, 253, (12, 13)), (48, 196, (8, 9)),
        (420, 300, (8, 9, 10)), (412, 336, (0, 3)), (392, 270, (12,)),
        (98, 182, (4, 5)), (336, 186, (6, 7)),
        (180, 500, (0, 1, 2, 3)), (210, 530, (12,)), (152, 528, (8, 9)),
        (340, 448, (0, 2)), (372, 468, (12, 13)), (400, 503, (1, 3)), (300, 530, (8, 10)),
        (-6, 540, (8, 9)), (-14, 430, (12,)), (430, 540, (8,)),
    ]:
        tr = trees[rng.choice(kinds)]
        if rng.random() < 0.5:
            tr = tr.transpose(Image.FLIP_LEFT_RIGHT)
        t.add(tr, tx, ty)
    props(t, rng)

    img = t.render(cob, dirt, flag, fog_top=wy - 60)
    big = lambda im: im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    d = dusk(img, t.lights)
    big(day(img)).save(f"{out}/sample_day.png")
    big(d).save(f"{out}/sample_dusk.png")
    # phone view: 430x932 window at game scale (2x art), centred on the plateau
    px0 = (W * 2 - 430) // 2
    big(d).crop((px0, 0, px0 + 430, 932)).save(f"{out}/sample_phone_dusk.png")
    big(day(img)).crop((px0, 0, px0 + 430, 932)).save(f"{out}/sample_phone_day.png")




def hero_standin():
    """The base hero's layers flattened to a muted ramp: a scale reference only."""
    L = "C:/gamedev/solaria_wt_newart/claude/art_test/hero/layers/"
    h = Image.new("RGBA", (60, 84))
    for n in ("base_body", "outfit_leather", "arms_A", "hair_short"):
        h.alpha_composite(Image.open(L + n + ".png").convert("RGBA"))
    ramp = [hexc(c) for c in ("#0e0812", "#2a2230", "#4a3a40", "#6e5a52", "#9a8070", "#c0a888")]
    px = h.load()
    for y in range(h.height):
        for x in range(h.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = ramp[min(5, int(lum((r, g, b)) / 256 * 6))] + (255,)
    return h.crop(h.getbbox())


SAMPLE2_PROPS = [
    ("barrel", 336, 900), ("barrel", 312, 904), ("sacks", 2, 904), ("lamp", 218, 960), ("crates", 40, 1010),
    ("logs", 580, 900), ("stump", 636, 904), ("barrel", 1000, 900), ("crates", 960, 1010), ("trough", 680, 1050),
    ("sign", 410, 590), ("board", 560, 620), ("lamp", 556, 960), ("bench", 400, 1010),
    ("scarecrow", 180, 1180), ("hay", 340, 1150), ("cart", 380, 1100), ("well", 600, 1180), ("laundry", 700, 1130),
]


def sample2(out):
    """Hero-scale sample: 32 px tiles, doors about hero height (style bible)."""
    global T
    T = 32
    g2 = "gen2"
    cob = Wang("cobble", RAMPS["grass"], RAMPS["stone"], g2)
    dirt = Wang("dirt", RAMPS["grass"], RAMPS["dirt"], g2)
    flag = Wang("flag", RAMPS["grass"], RAMPS["flag"], g2).tiles[(True,) * 4]

    W, H = 1024, 1280
    t = Town(W, H)
    t.paint(1, 15, 16, 16, 40)  # road from the plateau stairs
    t.paint(1, 0, 28, 32, 29)  # cross road
    t.paint(1, 5, 27, 6, 28)  # to the Inn door
    t.paint(1, 24, 27, 25, 28)  # to the forge
    t.paint(2, 26, 9, 27, 17)  # weed-grown track to the sealed gate
    t.paint(2, 18, 17, 27, 17)
    t.plots.append((2 * T + 8, 33 * T + 8, 11 * T - 8, 38 * T - 4))
    t.fence_runs.append((2 * T - 8, 33 * T - 4, 11 * T + 8, 38 * T + 12))
    t.plateaus.append((9 * T, 8 * T, 23 * T, 15 * T, 48))
    t.stairs.append((15 * T + 4, 2 * T - 8))

    ld = lambda n: load_sprite(None, f"{g2}/{n}.png")
    wall, tower, gate, inn, smith, dungeon = (ld(n) for n in ("wall", "tower", "gatehouse", "inn", "smith", "gate"))
    trees = {k: ld("tree_" + k) for k in ("oak", "pine", "dead", "willow")}
    rng = random.Random(3)

    wy = 8 * T
    for x in range(-60, W, 70):  # dead woods out in the fog
        t.fog_trees.append((trees["dead"], x + rng.randint(-14, 14), 100 + rng.randint(0, 16), 150 + rng.randint(0, 70)))
    x = -30
    while x < W:
        t.add(wall, x, wy, shadow=False, foot=0)
        x += wall.width - 4
    t.add(tower, 40, wy + 44)
    t.add(gate, W - 8 - gate.width, wy + 56)
    t.lights += [(40 + 70, wy + 40, 40, "#ffb347"), (W - 8 - gate.width + 60, wy + 50, 36, "#ffb347"),
                 (W - 70, wy + 50, 36, "#ffb347")]

    t.add(dungeon, 16 * T - dungeon.width // 2, 14 * T)
    t.lights += [(16 * T - 130, 14 * T, 80, "#ff9a3c"), (16 * T + 130, 14 * T, 80, "#ff9a3c"),
                 (16 * T, 14 * T + 20, 120, "#7fb6ff")]

    t.add(inn, 16, 28 * T)
    t.lights += [(16 + 175, 28 * T + 24, 100, "#ffb347")]
    t.add(smith, 21 * T, 28 * T)
    t.lights += [(21 * T + 120, 28 * T + 24, 110, "#ff7a2a")]

    for (tx, ty, k) in [
        (-30, 484, "pine"), (60, 514, "oak"), (-20, 604, "willow"), (110, 474, "pine"),
        (920, 624, "pine"), (880, 664, "oak"), (950, 714, "willow"),
        (230, 444, "dead"), (760, 464, "dead"),
        (420, 1214, "oak"), (520, 1274, "willow"), (330, 1280, "pine"),
        (760, 1084, "oak"), (850, 1124, "willow"), (930, 1194, "oak"), (700, 1274, "pine"),
        (-20, 1280, "pine"), (-40, 1064, "willow"), (990, 1280, "pine"),
    ]:
        tr = trees[k]
        if rng.random() < 0.5:
            tr = tr.transpose(Image.FLIP_LEFT_RIGHT)
        t.add(tr, tx, ty)
    pick = json.load(open(f"{g2}/props/pick.json"))
    P = {k: load_sprite(None, f"{g2}/props/p{v}.png") for k, v in pick.items()}
    for (k, x, y) in SAMPLE2_PROPS:
        t.add(P[k], x, y)
        if k == "lamp":
            t.lights.append((x + 10, y - 2, 70, "#ffb347"))
    G = lambda i: load_sprite(None, f"{g2}/graves/g{i}.png")
    # a small graveyard under the watchtower (Hardcore towns grow it: one grave per fallen hero)
    for (i, x, y) in ((0, 30, 400), (1, 84, 396), (13, 140, 404), (21, 196, 398), (22, 40, 452),
                      (12, 100, 456), (2, 160, 458), (17, 214, 462), (5, 8, 486), (15, 60, 488), (5, 120, 486), (15, 180, 488)):
        t.add(G(i), x, y)
    t.add(G(16), 15 * T - 40, 15 * T + 60)  # the prophecy obelisk beside the stairs
    hero = hero_standin()
    t.add(hero, 250, 30 * T + 4)  # a hero at the crossroads, for scale

    img = t.render(cob, dirt, flag, fog_top=wy - wall.height + 30)
    d = dusk(img, t.lights)
    dy = day(img)
    up = lambda im, s: im.resize((im.width * s, im.height * s), Image.NEAREST)
    dy.save(f"{out}/sample2_day_1x.png")
    d.save(f"{out}/sample2_dusk_1x.png")
    for (s, where, (cx, cy)) in ((2, "dungeon", (16 * T, 13 * T)), (2, "inn", (260, 820)), (3, "inn", (230, 860))):
        vw, vh = 430 // s, 932 // s  # phone views: 430x932 windows at 2x and 3x
        x0, y0 = max(0, min(W - vw, cx - vw // 2)), max(0, min(H - vh, cy - vh // 2))
        for name, im in (("dusk", d), ("day", dy)):
            up(im.crop((x0, y0, x0 + vw, y0 + vh)), s).save(f"{out}/sample2_phone_{s}x_{where}_{name}.png")


if __name__ == "__main__":
    if sys.argv[1] == "sample":
        sample(sys.argv[2])
    elif sys.argv[1] == "sample2":
        sample2(sys.argv[2])
