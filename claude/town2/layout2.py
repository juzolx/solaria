"""Tighter isometric town sample (Juzo, Oct 24: buildings looked pasted on, walls blocky, town
too empty). Buildings lose their baked ground slab and stand on the town's ground; every door
opens onto a street; yards, a square and a graveyard fill the gaps; trees only behind the
buildings and along the walls.
Usage: py layout2.py <out_dir>"""
import random
import sys
from PIL import Image
from compose import load_sprite, dusk, day
from deslab import deslab
from iso import Iso, COBBLE, FLAG, MUD, PUDDLE, GRASS, LEAVES, fog_outside

# sprite -> (path, slab band, slab kinds, slab side). Every building's door is on its LEFT
# face (looks +j) except the gatehouse and tower (right face, looks +i); flip to swap.
ART = {
    "inn": ("gen/inn_iso", 0, (), 0), "house2": ("gen/inn_iso2", 0, (), 0),
    "smith": ("gen/smith_iso", 16, ("dirt", "grass"), 2), "dungeon": ("gen/gate_iso", 12, ("grass",), 9),
    "tower": ("gen3/tower", 14, ("grass",), 0), "gatehouse": ("gen3/gatehouse", 14, ("grass", "sand", "dirt"), 0),
    "shop": ("gen4/shop", 0, (), 0), "tavern": ("gen4/tavern", 0, (), 0), "church": ("gen4/church", 0, (), 0),
    "guild": ("gen4/guild", 0, (), 0), "vault": ("gen4/vault", 0, (), 0),
    "clinic": ("gen4/clinic", 16, ("grass",), 2),
}


def footprint(im):
    """(base x, base y, cells along i, cells along j) of an isometric building sprite."""
    a = im.getchannel("A").point(lambda v: 255 if v >= 128 else 0).load()
    w, h = im.size
    rows = [(y, [x for x in range(w) if a[x, y]]) for y in range(h)]
    rows = [(y, xs) for y, xs in rows if xs]
    yb, xs = rows[-1]
    bx = (min(xs) + max(xs)) / 2
    lower = [r for r in rows if r[0] > h * 0.5]
    L = min(min(xs) for _, xs in lower)
    R = max(max(xs) for _, xs in lower)
    return bx, yb, (bx - L) / 16, (R - bx) / 16


class Lot:
    def __init__(self, t, key, I, J, flip=False):
        path, band, kinds, side = ART[key]
        raw = Image.open(path + ".png").convert("RGBA")
        raw.putalpha(raw.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
        bx, by, wi, wj = footprint(raw)
        im = deslab(raw, band, kinds, side)[0] if band else raw
        if flip:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
            bx, wi, wj = im.width - 1 - bx, wj, wi
        self.t, self.I, self.J, self.wi, self.wj, self.flip = t, I, J, wi, wj, flip
        x, y = t.at(I, J)
        t.sprites.append((y, round(x - bx), round(y - by), im, True))
        for i in range(int(I - wi), int(round(I))):
            for j in range(int(J - wj), int(round(J))):
                t.used.add((i, j))

    def left(self, f, out=0.55):
        return self.I - f * self.wi, self.J + out

    def right(self, f, out=0.55):
        return self.I + out, self.J - f * self.wj

    def door(self, f=0.3, out=0.5):
        return self.right(f, out) if self.flip else self.left(f, out)


def build():
    N = 28
    W, H = 960, 640
    t = Iso(N, W, H, W // 2, 120)
    t.used = set()

    def put(im, fi, fj, dy=0, shadow=True):
        x, y = t.at(fi, fj)
        t.sprites.append((y + dy, round(x - im.width / 2), round(y + dy - im.height), im, shadow))
        t.used.add((int(fi), int(fj)))

    def P(i, k=0.75):
        im = load_sprite(None, f"gen/props/p{i}.png")
        return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)
    trees = [load_sprite(None, f"gen/trees/t{i}.png") for i in range(16)]
    F = lambda who, d: load_sprite(None, f"gen3/folk/{who}_{d}.png")

    def light(p, r=40, col="#ffb347", lift=0):
        x, y = t.at(*p)
        t.lights.append((x, y - lift, r, col))

    # ---- streets (3 tiles wide, so roofs in front never hide them) ----
    t.fill(FLAG, 9, 1, 17, 9)       # the dungeon forecourt and the square
    t.fill(COBBLE, 15, 9, 17, 27)   # cross street, from the square to the south wall
    t.fill(COBBLE, 1, 10, 27, 12)   # main street, west to east
    t.fill(MUD, 2, 18, 27, 20)      # the old gate road, gone to mud
    for (i, j) in ((5, 19), (10, 18), (20, 20), (25, 19)):
        t.fill(PUDDLE, i, j, i, j)
    t.fill(MUD, 18, 26, 27, 27)     # a lane to the Vault and the Clinic
    t.fill(LEAVES, 3, 22, 9, 26)    # the graveyard
    for i in range(N):
        for j in range(N):
            if t.ground[i][j] != GRASS:
                t.used.add((i, j))

    # ---- walls, towers, the sealed gate ----
    for k in range(N):
        t.walls.add((k, 0))
        if not 16 <= k <= 21:
            t.walls.add((0, k))
        t.used.update({(k, 0), (0, k)})
    for k in range(1, N):  # the front walls, low
        for c in ((N - 1, k), (k, N - 1)):
            t.walls.add(c)
            t.low_walls.add(c)
            t.used.add(c)
    Lot(t, "tower", 3, 27.2)
    Lot(t, "tower", 27.2, 3)
    gate = Lot(t, "gatehouse", 2.25, 21.5)
    light(gate.right(0.5, 0.3), 26)

    # ---- the dungeon entrance faces the square ----
    dun = Lot(t, "dungeon", 9, 7)
    sx, sy = dun.right(0.4, 0.3)
    light((sx, sy), 46, "#ff9a3c")
    light((sx + 0.4, sy - 1.6), 40, "#ff9a3c")
    light((sx + 0.6, sy - 0.6), 64, "#7fb6ff")
    put(P(43), 11, 2.2)  # the prophecy stone

    # ---- buildings, at least a tile and a half apart, doors on streets ----
    lots = {
        "inn": Lot(t, "inn", 22, 9.4),        # north of the main street, door on it
        "guild": Lot(t, "guild", 27, 9.4),
        "shop": Lot(t, "shop", 7, 17.4),      # between main street and gate road, doors on the gate road
        "house2": Lot(t, "house2", 12.4, 17.4),
        "smith": Lot(t, "smith", 22, 17.4),
        "tavern": Lot(t, "tavern", 27, 17.4),
        "church": Lot(t, "church", 14.4, 25.6, flip=True),  # door turned onto the cross street
        "vault": Lot(t, "vault", 22, 25.4),                 # doors on the lane
        "clinic": Lot(t, "clinic", 27, 25.4),
    }
    for k, lot in lots.items():
        light(lot.door(0.3, 0.45), 44 if k != "smith" else 56, "#ff7a2a" if k == "smith" else "#ffb347")

    # ---- props against walls and doors ----
    L = lots
    put(P(17), *L["inn"].door(0.1, 0.65)); put(P(4), *L["inn"].left(0.85, 0.6))
    put(P(28), *L["guild"].left(0.1, 0.7))
    put(P(9), *L["shop"].left(0.85, 0.6)); put(P(51), *L["shop"].right(0.4, 0.6))
    put(P(53), *L["house2"].right(0.5, 0.6))
    put(P(56), *L["smith"].right(0.5, 0.6)); put(P(57), *L["smith"].right(0.15, 0.8)); put(P(62), *L["smith"].left(0.95, 0.55))
    put(P(0), *L["tavern"].left(0.05, 0.7)); put(P(5), *L["tavern"].right(0.3, 0.6))
    put(P(16), *L["vault"].door(0.1, 0.7))
    put(P(36), *L["clinic"].right(0.3, 0.6)); put(P(48), *L["clinic"].right(0.7, 0.6))
    for i in (5, 11, 19, 25):  # lamps along the main street
        put(P(19), i, 9.6)
        light((i, 9.6), 32, lift=6)
    put(P(33), 14, 5.5)  # the well in the square
    put(P(30), 17.4, 3.6)  # the notice board (the Bounty Board)
    put(P(25), 14.4, 17.8)  # signpost
    # the graveyard beside the church: rows of graves, a fresh one, crosses
    for k, (i, j) in enumerate([(i, j) for j in (22.6, 23.8, 25.0, 26.2) for i in (4.0, 5.6, 7.2, 8.8)]):
        put(P((40, 41, 42, 27, 43)[k % 5]), i, j)

    # ---- trees: behind the buildings, along the walls ----
    rng = random.Random(4)
    near = {(i + di, j + dj) for (i, j) in t.used for di in (-1, 0, 1) for dj in (-1, 0, 1)}
    groups = {"oak": (0, 1, 2, 3), "dead": (4, 5, 6, 7), "pine": (8, 9, 10, 11), "willow": (12, 13)}
    spots = [(i, j) for i in range(1, N - 1) for j in range(1, N - 1) if (i, j) not in t.used]
    for (i, j) in spots:
        if (i, j) in near and rng.random() < 0.6:
            continue
        if rng.random() < 0.35:
            continue
        kind = "dead" if j < 6 and i < 12 else ("willow" if j > 20 and i < 10 else rng.choice(("oak", "pine", "oak")))
        tr = trees[rng.choice(groups[kind])]
        if rng.random() < 0.5:
            tr = tr.transpose(Image.FLIP_LEFT_RIGHT)
        put(tr, i + 0.5 + rng.uniform(-0.15, 0.15), j + 0.5 + rng.uniform(-0.15, 0.15))

    # ---- people on the streets ----
    for (who, d, i, j) in (("hero", "north-east", 16, 14), ("hero", "south-west", 15.6, 6.5),
                           ("woman", "south-east", 8, 11), ("oldman", "north-west", 20, 11.4),
                           ("woman", "south-west", 16.4, 22), ("oldman", "south-east", 23, 19.4),
                           ("hero", "north-west", 24, 10.6), ("woman", "north-east", 12, 6)):
        put(F(who, d), i, j, dy=2)

    return t, fog_outside(t.render(), t)


if __name__ == "__main__":
    out = sys.argv[1]
    t, img = build()
    big = lambda im, s: im.resize((im.width * s, im.height * s), Image.NEAREST)
    dk, dy = dusk(img, t.lights), day(img)
    big(dk, 2).save(f"{out}/iso3_dusk_2x.png")
    big(dy, 2).save(f"{out}/iso3_day_2x.png")
    for (name, im) in (("dusk", dk), ("day", dy)):
        for (s, cx, cy) in ((2, 480, 300), (3, 480, 290)):
            vw, vh = 430 // s, 932 // s
            x0, y0 = max(0, min(img.width - vw, cx - vw // 2)), max(0, min(img.height - vh, cy - vh // 2))
            big(im.crop((x0, y0, x0 + vw, y0 + vh)), s).save(f"{out}/iso3_phone_{s}x_{name}.png")
