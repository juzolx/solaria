#!/usr/bin/env python3
"""Builds the town map (art/town/town_<season>.png + town.json hotspots).

Usage: python3 tools/town_compose.py [LPC Revised repo] [LPC city outside dir]
Art: LPC Revised (github.com/ElizaWy/LPC; CC-BY-SA 3.0 / GPL 3.0 / OGA-BY 3.0, see its Credits.txt)
and "[LPC] City outside" by Reemax and others (CC-BY-SA 3.0 / GPL). Every sprite is placed by
hand below; the script lays them out, recolors a few buildings, and sorts everything by its
base line so things overlap the right way.
"""
import colorsys, json, os, random, sys
from PIL import Image, ImageDraw

REV = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/lpc_revised"
CITY = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/dl_oga/city/LPC_city_outside"
GRAVES = sys.argv[4] if len(sys.argv) > 4 else "/home/claude/dl_oga/terrain_atlas.png"  # LPC Tile Atlas (CC-BY-SA 3.0 / GPL 3.0)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art", "town")
T = 32
COLS, ROWS = 22, 34
CAVE_X = 304
W, H = COLS * T, ROWS * T


def load(*p):
    return Image.open(os.path.join(*p)).convert("RGBA")


def tile(sheet, cx, cy, w=1, h=1):
    return sheet.crop((cx * T, cy * T, (cx + w) * T, (cy + h) * T))


def quarter(t, qx, qy):
    return t.crop((qx * 16, qy * 16, qx * 16 + 16, qy * 16 + 16))


def trim(im):
    bb = im.getbbox()
    return im.crop(bb) if bb else im


# --------------------------------------------------------------------------- recolor
def recolor(im, groups):
    """groups: list of (test(h_deg, s, v) -> bool, hue shift in turns (or 1 + absolute hue), sat mult, val mult). First match wins."""
    im = im.copy()
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            for test, dh, sm, vm in groups:
                if test(h * 360, s, v):
                    h = (dh - 1.0) if dh >= 1.0 else (h + dh) % 1.0
                    s = max(0.0, min(1.0, s * sm))
                    v = max(0.0, min(1.0, v * vm))
                    break
            r2, g2, b2 = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return im


def warm(h, s, v):
    return (h < 45 or h > 330) and s > 0.22


def cool(h, s, v):
    return 170 < h < 290


# --------------------------------------------------------------------------- season art
class Art:
    def __init__(self, season):
        self.terrain = load(REV, "Terrain", "terrain_%s.png" % season)
        self.cliff = load(REV, "Terrain", "cliff_%s.png" % season)
        self.trees = load(REV, "Terrain", "trees_%s.png" % season)
        self.plants = load(REV, "Terrain", "plants_%s.png" % season)
        self.flowers = load(REV, "Terrain", "wildflowers_%s.png" % season)
        s = "Structure"
        self.house_a = load(REV, s, "Structures", "Brick House A.png")
        self.house_b = load(REV, s, "Structures", "Brick House B.png")
        self.house_p = load(REV, s, "Structures", "Paneled House A.png")
        self.door64 = load(REV, s, "Doors", "32x64px Doors", "15 Panel Door A.png").crop((224, 32, 256, 96))
        self.door48 = load(REV, s, "Doors", "32x48px Doors", "12 Panel Door A.png").crop((224, 16, 256, 64))
        self.fountain = load(REV, s, "Misc", "Fountain A.png")
        self.signs = load(REV, s, "Signs", "Sign Icons A.png")
        self.sign_bg = load(REV, s, "Signs", "Sign Backgrounds A.png")
        f = os.path.join(REV, "Objects", "Furniture")
        self.lamp = load(f, "Lighting, Outdoors.png")
        self.barrel = load(f, "Barrel.png")
        self.crate = load(f, "Crate.png")
        self.anvil = load(f, "Smithing", "Anvils.png")
        self.forge = load(f, "Smithing", "Forge A.png")
        self.coal = load(f, "Smithing", "Coal Piles.png")
        self.chest = load(f, "Chest.png")
        self.hay = load(REV, "Objects", "Small Items", "Hay & Straw.png")
        self.city = load(CITY, "city_outside.png")
        self.fence = load(REV, s, "Fences", "Plain Fence A.png")
        self.tilled = load(REV, "Terrain", "tilled_soil.png")
        self.graves = load(GRAVES)


# --------------------------------------------------------------------------- terrain
def is_grass(grid, x, y):
    if x < 0 or y < 0 or x >= COLS or y >= ROWS:
        return True
    return grid[y][x] == "g"


def paint_terrain(canvas, art, grid, rng):
    """Dirt everywhere, then grass painted over it with LPC quarter-tile edges."""
    t = art.terrain
    dirt = [tile(t, 3 + i, 3 + j) for i in range(3) for j in range(2)]
    grass = [tile(t, 3 + i, 1 + j) for i in range(3) for j in range(2)]
    for y in range(ROWS):
        for x in range(COLS):
            canvas.alpha_composite(rng.choice(dirt), (x * T, y * T))
    for y in range(ROWS):
        for x in range(COLS):
            if not is_grass(grid, x, y):
                continue
            fill = rng.choice(grass)
            for qy in (0, 1):
                for qx in (0, 1):
                    dx = -1 if qx == 0 else 1
                    dy = -1 if qy == 0 else 1
                    hz = is_grass(grid, x + dx, y)
                    vt = is_grass(grid, x, y + dy)
                    dg = is_grass(grid, x + dx, y + dy)
                    if hz and vt and dg:
                        src = fill
                    elif not hz and not vt:
                        src = tile(t, 6 + (0 if qx == 0 else 2), 0 + (0 if qy == 0 else 2))
                    elif hz and not vt:
                        src = tile(t, 7, 0 if qy == 0 else 2)
                    elif vt and not hz:
                        src = tile(t, 6 if qx == 0 else 8, 1)
                    else:  # inner corner
                        src = tile(t, 6 + (1 if qx == 0 else 0), 3 + (1 if qy == 0 else 0))
                    canvas.alpha_composite(quarter(src, qx, qy), (x * T + qx * 16, y * T + qy * 16))


CLIFF_TOP = (4, 11)


def cliff_band(canvas, art, rng):
    c = art.cliff
    for x in range(COLS):
        canvas.alpha_composite(tile(art.terrain, 3 + x % 3, 1), (x * T, 0))
        canvas.alpha_composite(tile(c, CLIFF_TOP[0], CLIFF_TOP[1]), (x * T, T))
        canvas.alpha_composite(tile(c, rng.choice([0, 2]), 9), (x * T, 2 * T))
        canvas.alpha_composite(tile(c, rng.choice([0, 2]), 10), (x * T, 3 * T))
        canvas.alpha_composite(tile(c, 5 + x % 2, 8), (x * T, 4 * T))
    for x in (2, 3, 17, 18):  # ivy
        canvas.alpha_composite(tile(c, 1, 9), (x * T, 2 * T))
        canvas.alpha_composite(tile(c, 1, 10), (x * T, 3 * T))
    canvas.alpha_composite(tile(c, 7, 9, 3, 3), (CAVE_X, 2 * T))


# --------------------------------------------------------------------------- sprites
class Scene:
    def __init__(self):
        self.items = []  # (base_y, order, image, x, y)
        self.spots = []
        self.lights = []  # lamp heads, for the night glow

    def put(self, im, x, y, base=None):
        self.items.append(((y + im.height) if base is None else base, len(self.items), im, x, y))

    def draw(self, canvas):
        for base, _, im, x, y in sorted(self.items, key=lambda i: (i[0], i[1])):
            canvas.alpha_composite(im, (x, y))


def contact(scene, im, x, y, cast=6, alpha=70):
    """A grounded shadow from the sprite's own outline: a soft band along its base and a
    short cast to the right (the light comes from the upper left). Nothing hovers."""
    a = im.getchannel("A")
    w, h = im.size
    bb = im.getbbox()
    if not bb:
        return
    sh = Image.new("RGBA", (w + cast + 2, h + 6))
    sp = sh.load()
    ap = a.load()
    top = bb[1] + int((bb[3] - bb[1]) * 0.45)
    for xx in range(w):
        low = -1
        for yy in range(h - 1, -1, -1):
            if ap[xx, yy] > 0:
                low = yy
                break
        if low < 0:
            continue
        for k in range(0, 5):  # contact band just under the base
            yy = low + 1 + k - 2
            if 0 <= yy < h + 6 and (yy >= h or ap[xx, yy] == 0):
                sp[xx, yy] = (10, 8, 20, int(alpha * 1.6 * (1.0 - k / 5.0)))
    for yy in range(top, h):
        right = -1
        for xx in range(w - 1, -1, -1):
            if ap[xx, yy] > 0:
                right = xx
                break
        if right < 0:
            continue
        for k in range(1, cast + 1):
            if right + k < w + cast + 2:
                sp[right + k, yy] = (10, 8, 20, int(alpha * 1.1 * (1.0 - 0.6 * k / (cast + 1.0))))
    scene.put(sh, x, y, base=-1)


def prop(scene, im, x, y):
    contact(scene, im, x, y, 3, 60)
    scene.put(im, x, y)


def shadow(scene, x, y, w, h, alpha=70):
    sh = Image.new("RGBA", (w, h))
    ImageDraw.Draw(sh).ellipse((0, 0, w - 1, h - 1), fill=(10, 8, 20, alpha))
    scene.put(sh, x, y, base=-1)


TREE_CELLS = {"oak": (128, 0), "oak2": (224, 0), "tall": (320, 0), "round": (416, 0),
              "dark": (128, 256), "dark2": (224, 256), "pine": (128, 384), "pine2": (224, 384), "pine3": (320, 384)}


def tree(scene, art, x, y, kind):
    cx, cy = TREE_CELLS[kind]
    im = trim(art.trees.crop((cx, cy, cx + 96, cy + 128)))
    shadow(scene, x + im.width // 2 - 28, y + im.height - 14, 56, 18)
    scene.put(im, x, y)


def sign(art, icon):
    """Hanging shop sign: plate plus icon (0 sword, 1 shield, 2 potion, 3 INN, 4 PUB)."""
    out = art.sign_bg.crop((0, 0, 32, 32)).copy()
    out.alpha_composite(art.signs.crop((icon * 32, 0, icon * 32 + 32, 32)))
    return out


def house(scene, art, im, x, y, door, door_at, sign_icon=None, sign_at=None, sid="", label=""):
    im = im.copy()
    im.alpha_composite(door, door_at)
    if sign_icon is not None:
        im.alpha_composite(sign(art, sign_icon), sign_at)
    bb = im.getbbox()
    contact(scene, im, x, y, 12, 85)
    scene.put(im, x, y)
    scene.spots.append({"id": sid, "label": label, "rect": [x + bb[0], y + bb[1], bb[2] - bb[0], bb[3] - bb[1]],
                        "door": [x + door_at[0] + 16, y + door_at[1] + door.height]})


def board(scene, x, y):
    """The bounty board: a timber notice board with pinned bills (drawn in the LPC palette)."""
    im = Image.new("RGBA", (72, 70))
    d = ImageDraw.Draw(im)
    out, dark, mid, light = (34, 22, 26, 255), (74, 46, 34, 255), (112, 72, 46, 255), (146, 100, 62, 255)
    for px in (8, 58):
        d.rectangle((px, 30, px + 5, 68), fill=out)
        d.rectangle((px + 1, 30, px + 4, 67), fill=dark)
        d.line((px + 2, 30, px + 2, 66), fill=mid)
    d.rectangle((2, 6, 69, 44), fill=out)
    d.rectangle((4, 8, 67, 42), fill=mid)
    for yy in range(10, 42, 6):
        d.line((4, yy, 67, yy), fill=dark)
    d.rectangle((0, 2, 71, 8), fill=out)
    d.rectangle((1, 3, 70, 6), fill=light)
    d.line((1, 7, 70, 7), fill=dark)
    paper, ink, pin = (236, 226, 196, 255), (120, 98, 88, 255), (196, 44, 52, 255)
    for px, py, w, h in [(8, 12, 15, 18), (27, 10, 13, 15), (44, 13, 17, 20), (11, 31, 14, 9), (29, 27, 13, 13), (48, 35, 12, 6)]:
        d.rectangle((px, py, px + w, py + h), fill=(40, 30, 30, 120))
        d.rectangle((px - 1, py - 1, px + w - 1, py + h - 1), fill=paper)
        for ly in range(py + 3, py + h - 2, 3):
            d.line((px + 1, ly, px + w - 4, ly), fill=ink)
        d.rectangle((px + w // 2 - 1, py - 1, px + w // 2, py), fill=pin)
    d.rectangle((44, 14, 58, 18), fill=(176, 40, 44, 255))  # a WANTED header
    contact(scene, im, x, y, 4, 70)
    scene.put(im, x, y)
    scene.spots.append({"id": "bounty", "label": "Bounty Board", "rect": [x - 4, y - 4, 80, 78], "door": [x + 36, y + 70]})


def build(season, seed=11):
    rng = random.Random(seed)
    art = Art(season)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    grid = [["g"] * COLS for _ in range(ROWS)]

    def dirt(x0, y0, x1, y1):
        for yy in range(y0, y1 + 1):
            for xx in range(x0, x1 + 1):
                if 0 <= xx < COLS and 0 <= yy < ROWS:
                    grid[yy][xx] = "d"
    dirt(9, 5, 12, 10)       # from the cave mouth
    dirt(3, 11, 18, 20)      # the square
    dirt(2, 12, 2, 18)
    dirt(19, 12, 19, 18)
    dirt(9, 21, 12, ROWS - 1)  # the road out of town

    def grass(x0, y0, x1, y1):
        for yy in range(y0, y1 + 1):
            for xx in range(x0, x1 + 1):
                grid[yy][xx] = "g"
    grass(2, 12, 6, 16)       # the shop stands on its own lawn
    grass(15, 11, 19, 16)     # and so does the smithy
    dirt(6, 21, 8, 22)
    dirt(13, 21, 15, 23)
    paint_terrain(canvas, art, grid, rng)
    cliff_band(canvas, art, rng)

    sc = Scene()
    lamp = trim(art.lamp.crop((0, 0, 32, 96)))

    def lamp_at(x, y):
        prop(sc, lamp, x, y)
        sc.lights.append([x + lamp.width // 2, y + 8])
    lamp_at(CAVE_X - 22, 3 * T + 8)
    lamp_at(CAVE_X + 3 * T + 6, 3 * T + 8)
    sc.spots.append({"id": "gate", "label": "Into the Dungeon", "rect": [CAVE_X, 2 * T, 3 * T, 3 * T], "door": [CAVE_X + 48, 5 * T]})
    banner = trim(art.city.crop((20 * T, 3 * T, 21 * T, 5 * T)))
    prop(sc, banner, CAVE_X - 44, 2 * T + 30)
    prop(sc, banner.transpose(Image.FLIP_LEFT_RIGHT), CAVE_X + 3 * T + 30, 2 * T + 30)

    # ---- the buildings (2 tiles of scenery on each side: phones crop the edges)
    guild = recolor(art.house_a, [(cool, 1.0 + 352 / 360, 2.6, 0.9), (warm, 0.0, 0.10, 1.25)])   # grey stone, deep red roof
    house(sc, art, guild, 40, 5 * T, art.door48, (64, 128), None, None, "guild", "Guild Hall")
    house(sc, art, art.house_a, 408, 5 * T, art.door48, (64, 128), 3, (28, 120), "inn", "Inn")
    house(sc, art, art.house_p, 64, 12 * T, art.door48, (112, 80), 2, (78, 84), "shop", "Shop")
    house(sc, art, art.house_b, 473, 11 * T, art.door64, (96, 128), 0, (132, 104), "smith", "Blacksmith")
    tavern = recolor(art.house_b, [(warm, -0.05, 0.55, 0.62)])
    house(sc, art, tavern, 41, 21 * T, art.door64, (96, 128), 4, (132, 104), "tavern", "Tavern")
    vault = recolor(art.house_p, [(warm, 0.55, 0.55, 0.85), (cool, 0.0, 0.6, 1.15)])
    house(sc, art, vault, 480, 22 * T, art.door48, (112, 80), 1, (78, 84), "stash", "Vault")

    # ---- the square
    fx, fy = 320, 13 * T
    prop(sc, art.fountain, fx, fy)
    board(sc, 410, 12 * T + 10)
    # the market stall stands out in the square, just below the fountain
    prop(sc, trim(art.city.crop((128, 480, 256, 576))), 9 * T, 17 * T + 18)
    prop(sc, trim(art.city.crop((0, 384, 128, 448))), 9 * T, 17 * T - 16)
    sc.spots.append({"id": "market", "label": "Market", "rect": [9 * T, 17 * T - 16, 128, 130], "door": [9 * T + 64, 20 * T]})
    prop(sc, trim(art.anvil.crop((64, 0, 128, 32))), 14 * T + 16, 17 * T + 20)
    prop(sc, trim(art.anvil.crop((0, 0, 32, 32))), 16 * T + 4, 18 * T + 6)
    prop(sc, trim(art.coal.crop((0, 0, 32, 32))), 18 * T + 12, 17 * T + 22)
    well = trim(art.city.crop((21 * T, 7 * T, 23 * T, 10 * T)))
    prop(sc, well, 15 * T, 18 * T + 12)
    barrel = trim(art.barrel.crop((0, 0, 32, 64)))
    for bx, by in [(12 * T + 14, 10 * T + 4), (7 * T, 24 * T), (7 * T + 20, 24 * T + 10), (5 * T + 8, 11 * T + 12)]:
        prop(sc, barrel, bx, by)
    crate = trim(art.crate.crop((0, 0, 32, 32)))
    for cx2, cy2 in [(14 * T + 4, 25 * T + 10), (14 * T + 8, 24 * T + 14), (5 * T + 20, 17 * T + 14)]:
        prop(sc, crate, cx2, cy2)
    prop(sc, trim(art.chest.crop((0, 0, 32, 32))), 19 * T + 12, 26 * T + 14)
    for lx, ly in [(3 * T, 10 * T + 4), (18 * T + 6, 10 * T + 4), (7 * T + 8, 19 * T + 18), (13 * T + 16, 19 * T + 18)]:
        lamp_at(lx, ly)
    planter = trim(art.city.crop((14 * T, 12 * T, 15 * T, 13 * T)))
    planter2 = trim(art.city.crop((15 * T, 12 * T, 16 * T, 13 * T)))
    for px2, py2, pl in [(2 * T + 30, 10 * T + 20, planter2), (13 * T + 10, 10 * T + 14, planter2), (5 * T + 10, 16 * T + 12, planter),
                         (19 * T + 6, 16 * T + 4, planter2), (15 * T + 10, 26 * T + 10, planter)]:
        prop(sc, pl, px2, py2)

    # ---- below the town: a small fenced graveyard and the gardens
    fence = trim(art.fence.crop((0, 64, 96, 96)))
    for fxx in range(2 * T, 8 * T, fence.width - 6):
        prop(sc, fence, fxx, 28 * T)
    for fxx in range(2 * T, 8 * T, fence.width - 6):
        prop(sc, fence, fxx, 33 * T + 4)
    graves = [trim(art.graves.crop(b)) for b in [(448, 676, 480, 724), (480, 676, 512, 724), (512, 676, 544, 724)]]
    for i, (gx, gy) in enumerate([(2 * T + 14, 29 * T + 8), (4 * T + 2, 29 * T + 2), (5 * T + 22, 29 * T + 10),
                                   (3 * T + 6, 31 * T + 4), (5 * T + 2, 31 * T + 8), (6 * T + 26, 31 * T)]):
        g = graves[(i + seed) % 3]
        prop(sc, g, gx, gy)
    bare = trim(art.trees.crop((0, 256, 96, 400)))
    prop(sc, bare, 6 * T + 10, 28 * T + 4)
    soil = art.tilled.crop((0, 0, 96, 96))
    for sx2, sy2 in [(14 * T, 28 * T + 8), (17 * T - 8, 28 * T + 8), (14 * T, 31 * T), (17 * T - 8, 31 * T)]:
        canvas.alpha_composite(soil, (sx2, sy2))
    hay = trim(art.hay.crop((0, 0, 64, 96)))
    prop(sc, hay, 19 * T + 22, 29 * T)

    # ---- greenery: cliff-top pines, trees down the edges (cropped on phones), bushes, flowers
    for x, k in [(-30, "pine"), (60, "pine2"), (150, "pine3"), (470, "pine"), (560, "pine2"), (640, "pine3")]:
        tree(sc, art, x, -52, k)
    for (x, y, k) in [(-40, 9 * T, "pine"), (-46, 15 * T, "oak"), (-40, 19 * T + 10, "pine2"), (-44, 25 * T, "oak2"),
                      (630, 9 * T + 10, "pine3"), (628, 17 * T, "oak"), (632, 20 * T + 20, "pine"), (626, 26 * T, "round"),
                      (8 * T - 30, 24 * T + 16, "round"), (-30, 30 * T, "pine"), (634, 30 * T, "pine2")]:
        tree(sc, art, x, y, k)
    bushes = [trim(art.plants.crop((i * 32, 0, i * 32 + 32, 32))) for i in range(3)]
    for bx, by in [(8 * T, 5 * T + 8), (12 * T + 30, 5 * T + 12), (3 * T, 20 * T + 6), (17 * T + 4, 21 * T + 4),
                   (8 * T + 6, 27 * T + 20), (13 * T + 4, 27 * T + 10), (2 * T, 26 * T + 30), (18 * T, 27 * T + 20)]:
        prop(sc, rng.choice(bushes), bx, by)
    fl = art.flowers
    for _ in range(60):
        fx2, fy2 = rng.randrange(0, W - 16), rng.randrange(5 * T, H - 16)
        if not is_grass(grid, fx2 // T, fy2 // T) or not is_grass(grid, (fx2 + 15) // T, (fy2 + 15) // T):
            continue
        sx, sy = rng.randrange(0, fl.width // 16) * 16, rng.randrange(0, fl.height // 16) * 16
        piece = fl.crop((sx, sy, sx + 16, sy + 16))
        if piece.getbbox():
            canvas.alpha_composite(piece, (fx2, fy2))
    sc.draw(canvas)
    return canvas, sc.spots, sc.lights


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    spots, lights = [], []
    seasons = sys.argv[3].split(",") if len(sys.argv) > 3 else ["summer", "spring", "autumn", "winter"]
    for season in seasons:
        im, spots, lights = build(season)
        im.save(os.path.join(OUT, "town_%s.png" % season))
    json.dump({"size": [W, H], "spots": spots, "lights": lights}, open(os.path.join(OUT, "town.json"), "w"), indent=1)
    print("town", W, H, len(spots))
