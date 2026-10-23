"""Town concept v2: a big walled town that feels like a beautiful prison (no road out).

New layout (forget town.json): 880x440 art px (1760x880 file, about 3.5 phone screens wide).
- High walls all around with outward-facing watchtowers; beyond them grey fog (the barrier).
- The west gate is sealed (portcullis down, planks, rubble); the old road outside is overgrown.
- One cobbled main street runs from the dead gate east, over a stone bridge, to the lit dungeon
  entrance with a memorial shrine: the hopeful focal point.
- Market square with stalls and a well in the middle; houses, yards and trees around.
Code draws ground, walls, river, bridge, roads, stalls, lots; AI sprites (cleaned) are the buildings.
"""
import sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P
import town_ground as G

W, H = 880, 440
RAW = "C:/ai/art_raw/"


def hx(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


C = {k: hx(v) for k, v in {
    "grass": "265c42", "grass_hi": "3e8948", "grass_lo": "193c3e", "fleck": "75a743",
    "cob": "625f6a", "cob_hi": "7d8798", "cob_lo": "4a4852", "cob_dk": "34323b",
    "wall": "7d8798", "wall_hi": "a8a8ba", "wall_lo": "545d70", "wall_dk": "34323b", "wall_top": "8b9bb4",
    "water": "2e7896", "water_hi": "4fb0c6", "water_fx": "a4dddb", "water_dk": "253a5e",
    "fog": "3a4466", "fog_hi": "5a6988", "fog_lo": "262b44",
    "dirt": "8f563b", "dirt_lo": "5a3f35", "wood": "6a4a28", "wood_hi": "9a7040",
    "iron": "34323b", "iron_hi": "625f6a", "candle": "fee761", "flame": "f77622", "glow": "feae34",
}.items()}

# AI building picks: (raw, target width in art px)
B = {
    1: ("Inn", "t2_inn_s742", 70), 2: ("Blacksmith", "t2_smith_s742", 66), 3: ("Tavern + Wheel", "t2_tavern_s742", 56),
    4: ("Vault", "t2_vault_s742", 52), 5: ("Guild Hall", "t2_guild_s742", 72), 6: ("Shop", "t2_shop_s742", 50),
    7: ("Clinic", "t2_clinic_s742", 60), 8: ("Dungeon + memorial", "t2_dungeon_s742", 76),
}
HOUSES = [("t2_house1_s742", 40), ("t2_house2_s742", 44), ("t2_house3_s742", 40)]
TOWER = ("t2_tower_s741", 40)
TREES = [("tree_pine_s61", 28), ("tree_oak_s61", 34), ("tree_pine_s63", 24), ("tree_oak_s62", 30)]
_c = {}


def spr(name, width):
    if (name, width) not in _c:
        _c[(name, width)] = P.clean_building(RAW + name + ".png", width=width)["final"]
    return _c[(name, width)]


def ground():
    g = np.zeros((H, W, 3), np.uint8); g[:] = C["grass"]
    big = G.smooth(H, W, 3, 14) * 0.7 + G.smooth(H, W, 4, 5) * 0.3
    g[big < 0.22] = C["grass_lo"]; g[big > 0.86] = C["grass_hi"]
    t = G.noise(H, W, 5, 1)
    g[(t > 0.985)] = C["grass_hi"]; g[np.roll(t > 0.985, 1, 0)] = C["grass_lo"]; g[t < 0.004] = C["fleck"]
    return g


def cobble(g, mask, seed=1):
    yy, xx = np.mgrid[0:H, 0:W]
    row = yy // 3
    brick = ((xx + (row % 2) * 2) % 5 == 0) | (yy % 3 == 0)
    n = G.noise(H, W, seed, 1)
    g[mask] = C["cob"]
    g[mask & brick] = C["cob_lo"]
    g[mask & ~brick & (n > 0.85)] = C["cob_hi"]
    edge = mask & ~(np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1))
    g[edge] = C["cob_dk"]


def blob_mask(cx, cy, rx, ry):
    yy, xx = np.mgrid[0:H, 0:W]
    return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1


def wobble(mask, seed, r=2.0):
    e = G.smooth(H, W, seed, 6)
    d = np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r)), float) / 255
    return d > (0.35 + (e - 0.5) * 0.5)


WX0, WY0, WX1, WY1, WT = 40, 30, 846, 426, 14  # wall rectangle (outer edge) and thickness


def layout_masks():
    road = np.zeros((H, W), bool)
    road[222:238, WX0:690] = True                     # main street: dead gate -> dungeon
    road[120:238, 210:224] = True                     # north lane to the inn
    road[230:360, 390:404] = True                     # south lane
    road[150:164, 560:760] = True                     # east lane
    road[150:238, 690:704] = True
    plaza = blob_mask(330, 230, 62, 40)
    shrine = blob_mask(730, 230, 34, 24)
    road = wobble(road, 11, 1.5) | plaza | shrine
    yy, xx = np.mgrid[0:H, 0:W]
    river_x = 520 + 18 * np.sin(yy / 46.0) + 8 * np.sin(yy / 13.0)
    river = (np.abs(xx - river_x) < 13) & (yy > WY0) & (yy < WY1)
    return road, plaza, shrine, river, river_x


def draw_walls(img):
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1, t = WX0, WY0, WX1, WY1, WT
    for (a, b, c, e) in ((x0, y0, x1, y0 + t), (x0, y1 - t, x1, y1), (x0, y0, x0 + t, y1), (x1 - t, y0, x1, y1)):
        d.rectangle((a, b, c, e), fill=C["wall"])
    # wall top walk (lit) + inner face shadow + bricks
    d.rectangle((x0, y0, x1, y0 + 3), fill=C["wall_top"])
    # the north wall's inner face is seen from the town: a tall brick face (the wall is HIGH)
    d.rectangle((x0 + t, y0 + t, x1 - t, y0 + t + 14), fill=C["wall"])
    d.rectangle((x0 + t, y0 + t + 13, x1 - t, y0 + t + 14), fill=C["wall_dk"])
    for xx in range(x0 + t + 30, x1 - t, 60):   # arrow slits
        d.rectangle((xx, y0 + t + 4, xx, y0 + t + 9), fill=C["wall_dk"])
    a = P.to_np(img)
    yy, xx = np.mgrid[0:H, 0:W]
    inwall = np.zeros((H, W), bool)
    inwall[y0:y1, x0:x1] = True; inwall[y0 + t + 15:y1 - t, x0 + t:x1 - t] = False
    brick = ((yy % 4) == 0) | (((xx + ((yy // 4) % 2) * 3) % 6) == 0)
    a[inwall & brick, :3] = C["wall_lo"]
    # crenellations on the outer edge of all sides
    for x in range(x0, x1, 6):
        a[y0 - 3:y0, x:x + 3, :3] = C["wall_hi"]; a[y0 - 3:y0, x:x + 3, 3] = 255
    a[y1 - 1:y1, x0:x1, :3] = C["wall_dk"]
    return P.to_im(a)


def sealed_gate(img):
    """The west gate: a stone arch in the wall, portcullis down, planks nailed across, rubble."""
    d = ImageDraw.Draw(img)
    gx, gy = WX0 - 6, 200
    d.rectangle((gx, gy, gx + WT + 12, gy + 52), fill=C["wall_lo"])
    d.rectangle((gx, gy, gx + WT + 12, gy + 2), fill=C["wall_hi"])
    d.rectangle((gx + 4, gy + 8, gx + WT + 4, gy + 38), fill=C["iron"])
    for y in range(gy + 10, gy + 38, 4):
        d.line((gx + 4, y, gx + WT + 4, y), fill=C["iron_hi"])
    for x in range(gx + 5, gx + WT + 4, 3):
        d.line((x, gy + 8, x, gy + 38), fill=C["iron_hi"])
    d.line((gx + 2, gy + 14, gx + WT + 6, gy + 30), fill=C["wood_hi"], width=2)
    d.line((gx + 2, gy + 30, gx + WT + 6, gy + 14), fill=C["wood"], width=2)
    for i, (rx, ry) in enumerate(((gx + WT + 9, gy + 34), (gx + WT + 13, gy + 37), (gx + WT + 8, gy + 39), (gx - 6, gy + 36))):
        d.ellipse((rx - 3, ry - 2, rx + 3, ry + 2), fill=C["wall_lo"]); d.point((rx - 1, ry - 1), fill=C["wall_hi"])
    return img


def fog(img):
    """Outside the walls: overgrown land fading into a grey-blue fog barrier."""
    a = P.to_np(img)
    yy, xx = np.mgrid[0:H, 0:W]
    dist = np.minimum.reduce([xx - (WX0 - 6), (WX1 + 6) - xx, yy - (WY0 - 6), (WY1 + 6) - yy])
    out = dist < 0
    n = G.smooth(H, W, 21, 10)
    f = (-dist) / 18.0 + (n - 0.5) * 0.8
    a[out & (f > 0.2), :3] = C["fog_lo"]
    a[out & (f > 0.6), :3] = C["fog"]
    a[out & (f > 1.1), :3] = C["fog_hi"]
    # stipple band between grass and fog (hard 2-tone dither, no soft alpha)
    band = out & (f > 0.0) & (f <= 0.2) & (((xx + yy) % 2) == 0)
    a[band, :3] = C["fog_lo"]
    return P.to_im(a)


def tower():
    """Round wall watchtower from above-front: stone drum, arrow slit facing out, crenels, slate cone."""
    t = Image.new("RGBA", (26, 36), (0, 0, 0, 0)); d = ImageDraw.Draw(t)
    d.rectangle((3, 14, 22, 34), fill=C["wall"]); d.rectangle((3, 14, 6, 34), fill=C["wall_hi"]); d.rectangle((18, 14, 22, 34), fill=C["wall_lo"])
    for y in range(17, 34, 4):
        d.line((3, y, 22, y), fill=C["wall_lo"])
    d.rectangle((12, 22, 13, 27), fill=C["wall_dk"])
    for x in range(2, 24, 4):
        d.rectangle((x, 11, x + 2, 14), fill=C["wall_hi"])
    d.polygon([(13, 0), (24, 12), (1, 12)], fill=(58, 68, 102)); d.polygon([(13, 0), (13, 12), (1, 12)], fill=(90, 105, 136))
    d.point((13, 0), fill=(162, 38, 51))
    return P.outline(t)


def stall(colour):
    """A small market stall seen from above: striped awning + counter."""
    s = Image.new("RGBA", (16, 14), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.rectangle((1, 7, 14, 12), fill=C["wood"]); d.line((1, 7, 14, 7), fill=C["wood_hi"])
    for i, x in enumerate(range(0, 16, 3)):
        d.rectangle((x, 1, x + 2, 6), fill=colour if i % 2 == 0 else (234, 212, 170))
    d.line((0, 6, 15, 6), fill=(62, 39, 49))
    d.point((4, 9), fill=(254, 174, 52)); d.point((9, 10), fill=(99, 199, 77)); d.point((12, 9), fill=(228, 59, 68))
    return P.outline(s)


def well():
    s = Image.new("RGBA", (12, 12), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.ellipse((1, 4, 10, 11), fill=C["wall"]); d.ellipse((3, 6, 8, 9), fill=C["water_dk"])
    d.line((1, 2, 10, 2), fill=C["wood_hi"]); d.line((2, 2, 2, 7), fill=C["wood"]); d.line((9, 2, 9, 7), fill=C["wood"])
    return P.outline(s)


def lot(img, x, y, w, h, n):
    d = ImageDraw.Draw(img)
    d.rectangle((x, y, x + w, y + h), fill=C["dirt_lo"])
    for yy in range(y + 3, y + h, 5):
        d.line((x + 2, yy, x + w - 2, yy), fill=(62, 39, 49))
    for xx in range(x, x + w + 1, 4):
        d.rectangle((xx, y - 2, xx + 1, y), fill=C["wood_hi"]); d.rectangle((xx, y + h, xx + 1, y + h + 2), fill=C["wood"])
    d.line((x, y - 1, x + w, y - 1), fill=C["wood"]); d.line((x, y + h + 1, x + w, y + h + 1), fill=C["wood"])
    d.rectangle((x + w // 2 - 1, y + h // 2 - 4, x + w // 2, y + h // 2 + 3), fill=C["wood"])
    d.rectangle((x + w // 2 - 5, y + h // 2 - 8, x + w // 2 + 4, y + h // 2 - 4), fill=(200, 176, 138))


def candles(img, cx, cy):
    a = P.to_np(img)
    for dx, dy in ((-22, 6), (-16, 12), (18, 8), (24, 13), (-8, 16), (10, 17)):
        x, y = cx + dx, cy + dy
        a[y:y + 3, x, :3] = (244, 230, 196); a[y:y + 3, x, 3] = 255
        a[y - 1, x, :3] = C["candle"]; a[y - 1, x, 3] = 255
    return P.to_im(a)


def compose():
    g = ground()
    road, plaza, shrine, river, river_x = layout_masks()
    cobble(g, road & ~river)
    # river with banks, ripples
    bank = river ^ (np.roll(river, 1, 1) & np.roll(river, -1, 1))
    g[river] = C["water"]
    rip = G.noise(H, W, 31, 1)
    g[river & (rip > 0.93)] = C["water_hi"]; g[river & (rip > 0.985)] = C["water_fx"]
    g[bank] = C["cob_dk"]
    g[np.roll(bank, 1, 0) & river] = C["water_dk"]
    img = P.to_im(np.dstack([g, np.full((H, W), 255, np.uint8)]))
    # bridge over the river on the main street
    d = ImageDraw.Draw(img)
    bx = int(river_x[230, 0]) if np.ndim(river_x) == 2 else 520
    d.rectangle((bx - 20, 219, bx + 20, 241), fill=C["wall"])
    d.rectangle((bx - 20, 219, bx + 20, 221), fill=C["wall_hi"]); d.rectangle((bx - 20, 239, bx + 20, 241), fill=C["wall_dk"])
    for x in range(bx - 18, bx + 19, 4):
        d.line((x, 222, x, 238), fill=C["wall_lo"])
    img = fog(img)
    img = draw_walls(img)
    img = sealed_gate(img)
    # overgrown old road outside the dead gate, swallowed by fog
    a = P.to_np(img)
    for x in range(0, WX0 - 4):
        for y in range(222, 238):
            if (x * 7 + y * 3) % 5 == 0 and a[y, x, 2] < 120:
                a[y, x, :3] = C["dirt_lo"] if (x + y) % 3 else C["grass_hi"]
    img = P.to_im(a)
    placed = []
    def put(s, cx, by, key, label=None, num=None):
        placed.append((by, s, (cx - s.width // 2, by - s.height), key, label, num))
    # numbered buildings: (num, centre x, bottom y)
    POS = {5: (120, 214), 1: (218, 118), 6: (282, 214), 3: (128, 330), 2: (230, 330), 4: (338, 330),
           7: (620, 214), 8: (742, 226)}
    for n, (cx, by) in POS.items():
        lab, f, w = B[n]
        put(spr(f, w), cx, by, "bld", lab, n)
    # empty lots (numbered): church, trophy cabin, two spare plots
    lots = [(9, "Church (lot)", 420, 66, 56, 44), (10, "Trophy cabin (lot)", 600, 300, 54, 40),
            (11, "spare lot", 470, 330, 40, 32), (12, "spare lot", 760, 300, 40, 32)]
    for n, lab, x, y, w, h in lots:
        lot(img, x, y, w, h, n)
        placed.append((0, None, (x + w // 2, y + h // 2), "lot", lab, n))
    # houses filling the districts
    hs = [(300, 120), (352, 122), (60, 330), (470, 214), (608, 118), (668, 120), (790, 140), (660, 400), (470, 404),
          (100, 410), (240, 410), (330, 410), (790, 400)]
    for i, (cx, by) in enumerate(hs):
        f, w = HOUSES[i % 3]
        put(spr(f, w), cx, by, "house")
    # market square: stalls + well (13 = Market, 14 = Bounty board stand-in: the well square notice)
    cols = [(162, 38, 51), (18, 78, 137), (62, 137, 72), (104, 56, 108), (190, 74, 47)]
    for i, (sx, sy) in enumerate(((300, 214), (318, 252), (350, 252), (366, 214), (330, 206))):
        put(stall(cols[i % 5]), sx, sy, "stall")
    put(well(), 333, 236, "well")
    placed.append((0, None, (333, 230), "tag", "Market square", 13))
    placed.append((0, None, (380, 196), "tag", "Bounty board", 14))
    # watchtowers on the wall, facing outward
    for (tx, ty) in ((WX0 + 6, WY0 + 26), (WX1 - 6, WY0 + 26), (WX0 + 6, WY1 + 2), (WX1 - 6, WY1 + 2),
                     (440, WY0 + 26), (440, WY1 + 2), (WX0 + 6, 204), (WX0 + 6, 262)):
        put(tower(), tx, ty, "tower")
    # trees
    tspots = [(70, 120), (160, 120), (260, 410), (400, 160), (560, 410), (720, 410), (820, 330), (820, 90),
              (580, 160), (150, 260), (430, 290), (700, 330), (560, 120)]
    for i, (x, y) in enumerate(tspots):
        put(spr(*TREES[i % 4]), x, y, "tree")
    # shadows (down-right, light from the top-left)
    ga = P.to_np(img)
    for by, s, at, k, lab, n in placed:
        if s is None:
            continue
        sa = P.to_np(s)[..., 3] > 0
        ys, xs = np.where(sa)
        for ox, oy in ((3, 2), (2, 1)):
            yy, xx = ys + at[1] + oy, xs + at[0] + ox
            ok = (yy >= 0) & (yy < H) & (xx >= 0) & (xx < W)
            yy, xx = yy[ok], xx[ok]
            px = ga[yy, xx, :3].astype(int)
            gr = px[:, 1] > px[:, 0] + 10
            ga[yy[gr], xx[gr], :3] = C["grass_lo"]
            ga[yy[~gr], xx[~gr], :3] = C["cob_dk"]
    img = P.to_im(ga)
    img = candles(img, 742, 230)
    for by, s, at, k, lab, n in sorted([p for p in placed if p[1] is not None], key=lambda p: p[0]):
        img.alpha_composite(s, at)
    return img, placed


def dusk_version(img, placed):
    import town_concept as TC
    d = img.copy()
    for by, s, at, k, lab, n in sorted([p for p in placed if p[1] is not None], key=lambda p: p[0]):
        if k in ("bld", "house"):
            d.alpha_composite(TC.light_windows(s), at)
    d = TC.dusk(d)
    # keep the fog beyond the walls a dull, dark grey-blue (the grade pushes it to bright blue)
    a = P.to_np(d); yy, xx = np.mgrid[0:H, 0:W]
    out = (xx < WX0 - 6) | (xx > WX1 + 6) | (yy < WY0 - 6) | (yy > WY1 + 6)
    L = P.oklab(a[..., :3].astype(float))[..., 0]
    a[out & (L >= 0.45), :3] = C["fog"]; a[out & (L < 0.45), :3] = C["fog_lo"]; a[out & (L < 0.3), :3] = (24, 20, 37)
    d = P.to_im(a)
    pts = [(742, 200), (720, 236), (764, 236)] + [(WX0 + 6, WY0 + 10), (WX1 - 6, WY0 + 10), (440, WY0 + 10)]
    return TC.glow(d, pts, r=14)


if __name__ == "__main__":
    img, placed = compose()
    img.save(r"C:\ai\art_work2\town2_art.png")
    img.resize((W * 2, H * 2), Image.NEAREST).save(r"C:\ai\art_work2\town2_2x.png")
    print("ok")
