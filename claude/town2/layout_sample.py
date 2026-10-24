"""The isometric sample layout on the grid: streets first, buildings on lots with their doors
on a street, props anchored to the buildings' faces, trees only in free land."""
import random
from PIL import Image
from compose import load_sprite
from iso import Iso, COBBLE, FLAG, MUD, PUDDLE, GRASS, LEAVES, fog_outside


def base_of(im):
    """The bottom corner of a building's stone base: centre of its lowest opaque row."""
    a = im.getchannel("A").load()
    for y in range(im.height - 1, -1, -1):
        xs = [x for x in range(im.width) if a[x, y]]
        if xs:
            return (min(xs) + max(xs)) / 2, y


class Lot:
    """A building on the grid: its base's bottom corner sits on grid vertex (I, J); it covers
    wi cells along i (its left face looks toward +j) and wj cells along j (its right face
    looks toward +i)."""

    def __init__(self, t, im, I, J, wi, wj):
        self.t, self.im, self.I, self.J, self.wi, self.wj = t, im, I, J, wi, wj
        bx, by = base_of(im)
        x, y = t.at(I, J)
        t.sprites.append((y, round(x - bx), round(y - by), im, True))
        for i in range(int(I - wi), int(round(I))):
            for j in range(int(J - wj), int(round(J))):
                t.used.add((i, j))

    def left(self, f, out=0.55):
        """Just outside the left face (+j side); f = 0 at the bottom corner .. 1 at the far end."""
        return self.I - f * self.wi, self.J + out

    def right(self, f, out=0.55):
        """Just outside the right face (+i side)."""
        return self.I + out, self.J - f * self.wj


def sample():
    g = "gen"
    N = 26
    W, H = 880, 640
    t = Iso(N, W, H, W // 2, 130)
    t.used = set()

    def put(im, fi, fj, dx=0, dy=0, shadow=True):
        """Bottom-centre of a sprite on grid point (fi, fj); fractions allowed."""
        x, y = t.at(fi, fj)
        t.sprites.append((y + dy, round(x - im.width / 2 + dx), round(y + dy - im.height), im, shadow))
        t.used.add((int(fi), int(fj)))

    S = lambda n: load_sprite(None, f"{n}.png")

    def P(i, k=0.75):
        im = load_sprite(None, f"{g}/props/p{i}.png")
        return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)
    trees = [load_sprite(None, f"{g}/trees/t{i}.png") for i in range(16)]
    F = lambda who, d: load_sprite(None, f"gen3/folk/{who}_{d}.png")

    # streets first. Main street: from the dungeon stairs (they face +i) to the south-east.
    t.fill(FLAG, 8, 3, 11, 9)  # the dungeon forecourt
    t.fill(COBBLE, 11, 5, 25, 7)
    # the gate road: from the sealed gate (in the i = 0 wall, facing +i), unused, gone to mud
    t.fill(MUD, 2, 15, 25, 17)
    for (i, j) in ((4, 16), (9, 15), (13, 17), (19, 16), (23, 15)):
        t.fill(PUDDLE, i, j, i, j)
    t.fill(GRASS, 3, 17, 6, 17)  # weeds taking the old road back
    # the cross street joins them; a small square where it meets the main street
    t.fill(COBBLE, 14, 8, 15, 14)
    t.fill(COBBLE, 13, 4, 16, 8)
    t.fill(LEAVES, 1, 5, 4, 12)  # under the graveyard trees
    for i in range(N):
        for j in range(N):
            if t.ground[i][j] in (COBBLE, FLAG, MUD, PUDDLE):
                t.used.add((i, j))

    # walls, the watchtower in the north corner, the sealed gate in the west wall
    for k in range(N):
        t.walls.add((k, 0))
        if not 14 <= k <= 19:
            t.walls.add((0, k))
        t.used.update({(k, 0), (0, k)})
    Lot(t, S("gen3/tower"), 3, 25, 3, 3)  # watchtower in the west corner, over the gate road
    Lot(t, S("gen3/tower"), 25, 3, 3, 3)  # and one in the east corner
    Lot(t, S("gen3/gatehouse"), 2.25, 19.5, 2.25, 5)
    gx, gy = t.at(2.6, 17)
    t.lights.append((gx, gy, 26, "#ffb347"))

    # the dungeon entrance: the focal point at the head of the main street
    dun = Lot(t, S("gen/gate_iso"), 8, 8, 3.8, 3.9)
    x, y = t.at(*dun.right(0.35, 0.2))
    t.lights += [(x - 30, y - 16, 44, "#ff9a3c"), (x + 22, y - 30, 44, "#ff9a3c"), (x, y - 4, 64, "#7fb6ff")]
    put(P(43), 10.2, 3.6)  # the prophecy stone on the forecourt

    # buildings on lots, doors on a street
    inn = Lot(t, S("gen/inn_iso"), 13, 5, 3.5, 3.2)  # door on its left face -> main street
    smith = Lot(t, S("gen/smith_iso"), 20.5, 15, 3.5, 3.6)  # forge on its left face -> gate road
    # the cottage mirrored: its door moves to the left face -> gate road
    house = Lot(t, S("gen/house_iso").transpose(Image.FLIP_LEFT_RIGHT), 13.5, 15, 2.9, 4.1)
    inn2 = Lot(t, S("gen/inn_iso2"), 8, 15, 3.0, 3.6)  # door on its left face -> gate road
    for (lot, f, col, r) in ((inn, 0.3, "#ffb347", 50), (smith, 0.45, "#ff7a2a", 56),
                             (house, 0.3, "#ffb347", 40), (inn2, 0.5, "#ffb347", 40)):
        side = lot.left
        x, y = t.at(*side(f, 0.4))
        t.lights.append((x, y, r, col))

    # props hang off the buildings and the streets
    put(P(17), *inn.left(0.12, 0.7))  # lantern by the Inn door
    put(P(4), *inn.left(0.78, 0.55))
    put(P(0), *inn.left(0.92, 0.75))  # barrels at the corner
    put(P(51), *inn.right(0.3, 0.6))  # sacks on the side
    put(P(56), *smith.right(0.55, 0.55))
    put(P(57), *smith.right(0.25, 0.75))  # woodpile, chopping stump
    put(P(62), *smith.left(0.95, 0.5))
    put(P(36), *smith.left(0.75, 0.75))  # wheel, trough
    put(P(10), *house.left(0.8, 0.6))
    put(P(9), *house.right(0.3, 0.6))  # crates by the cottage
    put(P(53), *inn2.left(0.15, 0.75))
    put(P(58), *inn2.right(0.5, 0.55))  # cart, firewood
    for i in (12, 17, 22):  # lamps along the main street's edge
        put(P(19), i, 4.75)
        x, y = t.at(i, 4.75)
        t.lights.append((x, y + 4, 34, "#ffb347"))
    put(P(30), 16.6, 4.3)  # the notice board on the square
    put(P(33), 14.5, 6.5)  # the well in the square
    put(P(25), 15.8, 14.4)  # signpost where the cross street meets the gate road
    put(P(13 if False else 4), 11.2, 9.4)  # barrels by the square's corner
    # the vegetable plot behind the cottage, fenced, with its scarecrow
    t.fill(MUD, 17, 9, 22, 12)
    for i in range(17, 23):
        for j in range(9, 13):
            t.used.add((i, j))
    put(P(44), 19.5, 10.8)  # a scarecrow in the middle of the plot
    put(P(48), 22.6, 12.4)
    put(P(49), 21.6, 12.6)  # hay stacked at the far corner
    # the graveyard under the watchtower, in rows
    for k, (i, j) in enumerate([(i, j) for j in (5.5, 7, 8.5, 10, 11.5) for i in (1.6, 3.0)]):
        put(P((40, 41, 42, 27)[k % 4]), i, j)
    for i in range(1, 5):
        for j in range(5, 13):
            t.used.add((i, j))

    # trees: belts in free land, never on streets, lots or doorsteps
    rng = random.Random(9)
    near_used = {(i + di, j + dj) for (i, j) in t.used for di in (-1, 0, 1) for dj in (-1, 0, 1)}
    groups = {"oak": (0, 1, 2, 3), "dead": (4, 5, 6, 7), "pine": (8, 9, 10, 11), "willow": (12, 13)}
    for i in range(1, N - 1):
        for j in range(1, N - 1):
            edge = min(i, j, N - 1 - i, N - 1 - j)
            if (i, j) in near_used or rng.random() < (0.35 if edge <= 3 else 0.85):
                continue  # dense belts along the walls and edges, only scattered trees inside
            kind = "dead" if i + j < 14 else ("willow" if j > 18 and i < 12 else rng.choice(("oak", "pine", "oak", "willow")))
            tr = trees[rng.choice(groups[kind])]
            if rng.random() < 0.5:
                tr = tr.transpose(Image.FLIP_LEFT_RIGHT)
            put(tr, i + 0.5 + rng.uniform(-0.2, 0.2), j + 0.5 + rng.uniform(-0.2, 0.2))

    # townsfolk walk the streets, facing along them
    for (who, d, i, j) in (("hero", "north-west", 18.5, 6), ("hero", "south-east", 12, 6.5),
                           ("woman", "south-west", 14.5, 10), ("oldman", "north-east", 15, 12.8),
                           ("woman", "south-east", 21, 5.5), ("oldman", "south-west", 13.5, 4.8)):
        put(F(who, d), i, j, dy=2)

    img = t.render()
    return t, fog_outside(img, t)


if __name__ == "__main__":
    import sys
    from compose import dusk, day
    out = sys.argv[1]
    t, img = sample()
    big = lambda im, s: im.resize((im.width * s, im.height * s), Image.NEAREST)
    dk, dy = dusk(img, t.lights), day(img)
    big(dk, 2).save(f"{out}/iso2_dusk_2x.png")
    big(dy, 2).save(f"{out}/iso2_day_2x.png")
    for (name, im) in (("dusk", dk), ("day", dy)):
        for (s, cx, cy) in ((2, 440, 300), (3, 440, 280)):
            vw, vh = 430 // s, 932 // s
            x0, y0 = max(0, min(img.width - vw, cx - vw // 2)), max(0, min(img.height - vh, cy - vh // 2))
            big(im.crop((x0, y0, x0 + vw, y0 + vh)), s).save(f"{out}/iso2_phone_{s}x_{name}.png")
