"""Isometric town composer (Juzo's pick, Oct 24: the detailed isometric PixelLab buildings,
the 48x64 tree sheet and the 32 px prop sheet). Ground is 32x16 iso diamonds drawn back to
front; walls are procedural iso blocks; trees grow in belts and props sit in groups around
the buildings, each with a contact shadow.
Usage: py iso.py sample <out_dir>"""
import random
import sys
from PIL import Image, ImageDraw, ImageFilter
from compose import dusk, day, hexc, load_sprite

HW, HH = 16, 8  # half width / half height of a ground diamond

GRASS, COBBLE, MUD, PUDDLE, FLAG, LEAVES = "grass", "cobble", "mud", "puddle", "flag", "leaves"
TILES = {GRASS: (0, 1, 2, 3), COBBLE: (4, 5, 6, 7), MUD: (8, 9), PUDDLE: (10, 11), FLAG: (12, 13), LEAVES: (14, 15)}


class Iso:
    def __init__(self, n, w, h, ox, oy, seed=5):
        self.n, self.w, self.h, self.ox, self.oy = n, w, h, ox, oy
        self.rng = random.Random(seed)
        self.ground = [[GRASS] * n for _ in range(n)]
        self.walls = set()   # (i, j) cells with a wall block
        self.low_walls = set()  # front walls: one block high so they never hide the town
        self.sprites = []    # (foot_y, x, y, image, shadow)
        self.lights = []
        self.tiles = {k: [load_tile(f"gen3/iso/tile_{v}.png", k in (GRASS, LEAVES)) for v in vs] for k, vs in TILES.items()}

    def at(self, i, j):
        """Screen point of grid vertex (i, j): the top corner of cell (i, j)."""
        return self.ox + (i - j) * HW, self.oy + (i + j) * HH

    def centre(self, i, j):
        x, y = self.at(i, j)
        return x, y + HH

    def fill(self, kind, i0, j0, i1, j1):
        for i in range(max(0, i0), min(self.n, i1 + 1)):
            for j in range(max(0, j0), min(self.n, j1 + 1)):
                self.ground[i][j] = kind

    def place(self, im, i, j, dx=0, dy=0, shadow=True):
        """Puts a sprite's bottom-centre on the bottom corner of cell (i, j) (its feet)."""
        x, y = self.at(i + 1, j + 1)
        self.sprites.append((y + dy, x - im.width // 2 + dx, y + dy - im.height, im, shadow))

    def place_xy(self, im, x, y, shadow=True):
        self.sprites.append((y, x - im.width // 2, y - im.height, im, shadow))

    def render(self):
        img = Image.new("RGBA", (self.w, self.h), hexc("#16141c") + (255,))
        # ground, back to front
        for s in range(2 * self.n):
            for i in range(self.n):
                j = s - i
                if 0 <= j < self.n:
                    t = self.rng.choice(self.tiles[self.ground[i][j]])
                    x, y = self.centre(i, j)
                    img.alpha_composite(t, (x - 16, y - 15))
        # wall blocks join the y-sorted sprites
        for (i, j) in self.walls:
            blk = wall_block((i + j) % 2 == 0) if (i, j) not in self.low_walls else low_wall()
            x, y = self.at(i + 1, j + 1)
            self.sprites.append((y, x - 16, y - blk.height, blk, False))
        # contact shadows on their own layer, light from the top-left
        sh = Image.new("L", img.size, 0)
        d = ImageDraw.Draw(sh)
        for (foot, x, y, im, cast) in self.sprites:
            if cast:
                cx = x + im.width // 2
                rw = max(6, int(im.width * 0.42))
                d.ellipse([cx - rw + 4, foot - rw // 3 - 1, cx + rw + 6, foot + rw // 4], 120)
        sh = sh.filter(ImageFilter.MaxFilter(1))
        img.paste(Image.new("RGBA", img.size, (8, 6, 16, 255)), (0, 0), sh.point(lambda v: v // 2 if v else 0))
        for (foot, x, y, im, cast) in sorted(self.sprites, key=lambda s: s[0]):
            img.alpha_composite(im, (x, y))
        return img


def load_tile(path, calm_it=False):
    t = Image.open(path).convert("RGBA")
    a = t.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    t.putalpha(a)
    t = soften_rim(t)
    if not calm_it:
        return t
    calm = t.convert("RGB").filter(ImageFilter.MedianFilter(3)).convert("RGBA")
    calm.putalpha(a)
    return calm


def soften_rim(t):
    """The tiles come with a dark rim on the top face, which would draw a grid over the town:
    push each top-face rim pixel to its inner neighbour's colour."""
    px = t.load()
    out = t.copy()
    op = out.load()
    for y in range(7, 24):
        for x in range(32):
            r, g, b, a = px[x, y]
            if not a or r + g + b > 90:
                continue
            for (nx, ny) in ((x, y + 1), (x, y - 1), (x + 1, y), (x - 1, y), (x + 1, y + 1), (x - 1, y + 1)):
                if 0 <= nx < 32 and 7 <= ny < 23:
                    c = px[nx, ny]
                    if c[3] and sum(c[:3]) > 90:
                        op[x, y] = c
                        break
    return out


_blocks = {}


def low_wall():
    if "low" not in _blocks:
        tall = wall_block(False)
        im = Image.new("RGBA", (32, 32))
        im.alpha_composite(tall.crop((0, 26, 32, 58)), (0, 0))
        _blocks["low"] = im
    return _blocks["low"]


def wall_block(merlon):
    """A wall cell: PixelLab's iso stone block (gen3/wallblock.png) stacked two high, toned
    darker and greyer than the raw block, with a small merlon (the block's middle third) on
    every other cell."""
    if merlon in _blocks:
        return _blocks[merlon]
    blk = Image.open("gen3/wallblock.png").convert("RGBA")
    r, g, b, a = blk.split()
    lum = Image.merge("RGB", (r, g, b)).convert("L")
    blk = Image.merge("RGBA", (Image.blend(r, lum, 0.55).point(lambda v: int(v * 0.78)),
                               Image.blend(g, lum, 0.55).point(lambda v: int(v * 0.76)),
                               Image.blend(b, lum, 0.55).point(lambda v: int(v * 0.8)), a))
    im = Image.new("RGBA", (32, 48 + 10))
    im.alpha_composite(blk, (0, 26))
    im.alpha_composite(blk, (0, 10))
    if merlon:
        m = blk.crop((10, 0, 22, 32))
        mm = Image.new("RGBA", (12, 18))
        mm.alpha_composite(m.crop((0, 0, 12, 10)), (0, 0))
        mm.alpha_composite(m.crop((0, 24, 12, 32)), (0, 10))
        im.alpha_composite(mm, (10, 0))
    _blocks[merlon] = im
    return im


def sample(out):
    g = "gen"
    N = 26
    W, H = 880, 620
    t = Iso(N, W, H, W // 2, 120)

    # the walls: the town's north corner (i = 0 and j = 0 edges), a sealed gate on the right
    for k in range(N):
        t.walls.add((k, 0))
        t.walls.add((0, k))
    for k in (12, 13, 14):  # gap where the gatehouse sits
        t.walls.discard((k, 0))
    # outside the walls nothing: the composer's dark fog covers it later

    # roads: from the gate down-left, and from the dungeon down-right; a square where they cross
    t.fill(COBBLE, 12, 1, 14, 25)
    t.fill(COBBLE, 1, 11, 25, 13)
    t.fill(FLAG, 4, 3, 9, 8)  # the dungeon forecourt
    t.fill(MUD, 15, 1, 17, 3)
    t.fill(PUDDLE, 16, 2, 16, 2)
    t.fill(MUD, 3, 14, 7, 16)
    t.fill(PUDDLE, 5, 15, 5, 15)
    t.fill(LEAVES, 1, 1, 3, 9)
    t.fill(LEAVES, 18, 1, 25, 4)

    S = lambda n: load_sprite(None, f"{g}/{n}.png")
    gatehouse, tower = S("../gen3/gatehouse"), S("../gen3/tower")
    inn, smith, dungeon, house = S("inn_iso"), S("smith_iso"), S("gate_iso"), S("house_iso")
    trees = [load_sprite(None, f"{g}/trees/t{i}.png") for i in range(16)]
    def P(i, k=0.75):
        im = load_sprite(None, f"{g}/props/p{i}.png")
        return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)
    G = lambda i: load_sprite(None, f"gen2/graves/g{i}.png")

    t.place(gatehouse, 13, 0, dy=6)
    t.lights += [(t.centre(13, 1)[0] - 20, t.centre(13, 1)[1] + 4, 26, "#ffb347")]
    t.place(tower, 0, 0, dy=8)

    # the dungeon entrance: the focal point, on its flagstone forecourt
    t.place(dungeon, 7, 5)
    dx, dy = t.centre(7, 5)
    t.lights += [(dx - 40, dy - 10, 46, "#ff9a3c"), (dx + 40, dy - 10, 46, "#ff9a3c"), (dx, dy - 4, 60, "#7fb6ff")]
    t.place(P(43), 9, 8, dx=-6)  # the prophecy stone
    t.place(P(19), 4, 9)  # a lamp on the forecourt corner
    t.lights.append((t.centre(4, 9)[0], t.centre(4, 9)[1], 34, "#ffb347"))

    # inn: west of the square, its door on the road
    t.place(inn, 9, 13, dx=-4)
    ix, iy = t.centre(9, 13)
    t.lights.append((ix + 10, iy + 6, 52, "#ffb347"))
    for (p, i, j, ddx) in ((4, 10, 10, 0), (0, 11, 10, -6), (9, 7, 10, 0), (17, 11, 14, 0), (51, 10, 15, 4)):
        t.place(P(p), i, j, dx=ddx)
    t.lights.append((t.centre(11, 14)[0], t.centre(11, 14)[1], 34, "#ffb347"))

    # blacksmith: east of the square
    t.place(smith, 18, 9)
    sx, sy = t.centre(18, 9)
    t.lights.append((sx - 12, sy + 4, 56, "#ff7a2a"))
    for (p, i, j) in ((56, 19, 6), (57, 20, 7), (62, 15, 8), (10, 19, 10), (36, 15, 10)):
        t.place(P(p), i, j)

    # a cottage and its crop plot south of the square
    t.place(house, 18, 18)
    hx, hy = t.centre(18, 18)
    t.lights.append((hx, hy + 4, 40, "#ffb347"))
    for (p, i, j) in ((44, 21, 21), (48, 22, 19), (53, 15, 20), (33, 15, 16)):
        t.place(P(p), i, j)

    # a second house and its yard, west
    house2 = S("inn_iso2")
    t.place(house2, 6, 21)
    h2x, h2y = t.centre(6, 21)
    t.lights.append((h2x, h2y + 6, 40, "#ffb347"))
    for (p, i, j) in ((58, 3, 19), (7, 7, 22), (24, 9, 18), (63, 2, 21)):
        t.place(P(p), i, j)
    t.fill(MUD, 3, 18, 8, 19)

    # the graveyard under the watchtower
    for (gi, i, j) in ((40, 2, 3), (41, 3, 2), (42, 1, 4), (27, 3, 4), (40, 2, 5), (41, 4, 3), (42, 1, 6), (27, 4, 5)):
        t.place(P(gi), i, j)
    t.place(P(47), 1, 2)  # a ragged scarecrow-like effigy over the graves

    # trees: dense belts along the walls and edges, staggered, mixed species; dead ones by graves
    rng = random.Random(9)
    belts = [((20, 25), (1, 4), (0, 2, 8, 9, 10, 12, 13, 4, 6)),
             ((1, 3), (16, 25), (8, 9, 10, 11, 12, 13, 0, 2)),
             ((22, 25), (16, 25), (0, 3, 8, 11, 12, 13, 5)),
             ((1, 2), (8, 10), (4, 5, 6, 7, 14, 15))]
    for (ir, jr, kinds) in belts:
        for i in range(ir[0], ir[1] + 1):
            for j in range(jr[0], jr[1] + 1):
                if i >= N - 1 or j >= N - 1 or t.ground[i][j] in (COBBLE, FLAG) or rng.random() < 0.5:
                    continue
                tr = trees[rng.choice(kinds)]
                if rng.random() < 0.5:
                    tr = tr.transpose(Image.FLIP_LEFT_RIGHT)
                t.place(tr, i, j, dx=rng.randint(-10, 10), dy=rng.randint(-5, 5))
    for (i, j) in ((10, 3), (11, 7), (16, 15)):  # a few dead trees in the open
        t.place(trees[rng.choice((4, 5, 6, 7))], i, j)

    # townsfolk on the roads and at the doors (24 px PixelLab characters, 8 directions)
    F = lambda who, d: load_sprite(None, f"gen3/folk/{who}_{d}.png")
    for (who, d, i, j, ddx) in (("hero", "north-west", 13, 9, 0), ("hero", "north-east", 12, 12, 8),
                                 ("woman", "south-west", 10, 12, -4), ("oldman", "south-east", 16, 12, 0),
                                 ("woman", "north-east", 13, 18, 6), ("oldman", "south-west", 7, 7, 0),
                                 ("hero", "south-east", 8, 10, 4)):
        t.place(F(who, d), i, j, dx=ddx, dy=-4)

    img = t.render()
    img = fog_outside(img, t)
    return t, img


def fog_outside(img, t):
    """Everything outside the walls: dark violet fog that thins toward the town."""
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    n = t.n
    d.polygon([t.at(-5, -5), t.at(n, -5), t.at(n, n), t.at(-5, n)], 255)  # walls rise above the edge: keep them clear
    mask = mask.filter(ImageFilter.GaussianBlur(18)).point(lambda v: 255 - v)
    fog = Image.new("RGBA", img.size, (44, 40, 58, 255))
    # keep the wall tops and towers above the fog: only fog below the wall line
    out = img.copy()
    out.paste(Image.alpha_composite(img, Image.new("RGBA", img.size, (44, 40, 58, 230))), (0, 0),
              mask.point(lambda v: int(v * 0.95)))
    return out


if __name__ == "__main__":
    out = sys.argv[2]
    t, img = sample(out)
    big = lambda im, s: im.resize((im.width * s, im.height * s), Image.NEAREST)
    dk, dy = dusk(img, t.lights), day(img)
    big(dk, 2).save(f"{out}/iso_dusk_2x.png")
    big(dy, 2).save(f"{out}/iso_day_2x.png")
    for (name, im) in (("dusk", dk), ("day", dy)):
        for (s, cx, cy) in ((2, 440, 260), (3, 400, 250)):
            vw, vh = 430 // s, 932 // s
            x0, y0 = max(0, min(img.width - vw, cx - vw // 2)), max(0, min(img.height - vh, cy - vh // 2))
            big(im.crop((x0, y0, x0 + vw, y0 + vh)), s).save(f"{out}/iso_phone_{s}x_{name}.png")
