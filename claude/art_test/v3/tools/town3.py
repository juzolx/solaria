"""Town concept round 3: depth. 3/4 top-down buildings (roof + front wall) from code guides + img2img,
long cast shadows (light from the top-left), a raised dungeon plateau with a cliff face and carved
stairs, layered trees and props sorted by depth, unique buildings, darker prison dusk.
Reuses town2's walls, fog, sealed gate, river, cobbles, stalls.
"""
import sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P
import town2 as T2
import town_ground as G
from town2 import C, W, H, WX0, WY0, WX1, WY1, WT

C.update({"cliff": (74, 72, 82), "cliff_hi": (98, 95, 106), "cliff_lo": (52, 50, 59), "cliff_dk": (31, 29, 36)})
RAW = "C:/ai/art_raw/"
PLAT = (690, 96, WX1 - WT, 300)  # raised plateau (x0, y0, x1, y1) inside the east wall
CLIFF = 16                       # cliff face height (art px)

BLD = {  # num: (label, raw, width, (centre x, bottom y))
    1: ("Inn", "t3_inn_s801", 72, (230, 150)), 2: ("Blacksmith", "t3_smith_s802", 56, (236, 322)),
    3: ("Tavern + Wheel", "t3_tavern_s802", 62, (134, 322)), 4: ("Vault", "t3_vault_s801", 44, (340, 322)),
    5: ("Guild Hall", "t3_guild_s802", 80, (118, 206)), 6: ("Shop", "t3_shop_s801", 46, (300, 206)),
    7: ("Clinic", "t3_clinic_s802", 54, (600, 206)), 8: ("Dungeon entrance + memorial", "t3_dungeon_s801", 64, (780, 220)),
}
HOUSES = [("t3_house_a_s801", 44, (360, 140)), ("t3_house_b_s802", 38, (610, 120)), ("t3_house_c_s801", 34, (470, 410)),
          ("t3_house_d_s801", 50, (120, 410)), ("t3_house_e_s801", 42, (600, 410))]
TREES = [("tree_pine_s61", 34), ("tree_oak_s61", 44), ("tree_pine_s63", 30), ("tree_oak_s62", 40)]
_c = {}


def spr(name, width):
    if (name, width) not in _c:
        _c[(name, width)] = P.clean_building(RAW + name + ".png", width=width)["final"]
    return _c[(name, width)]


DARK = {}


def darker(rgb):
    """One-to-two palette steps darker and cooler (shadow colour), cached."""
    k = tuple(int(v) for v in rgb)
    if k not in DARK:
        t = np.array(k, float) * np.array([0.55, 0.58, 0.72]) + np.array([4, 4, 12])
        DARK[k] = tuple(int(v) for v in P.PAL[P.nearest_idx(t[None, :])[0]])
    return DARK[k]


def cast_shadow(a, sprite, at, length=6):
    """Shear the sprite's silhouette down-right (light top-left) and darken the ground under it."""
    sa = P.to_np(sprite)[..., 3] > 0
    h, w = sa.shape
    ys, xs = np.where(sa)
    # only the lower 70% of the sprite casts (roof tops don't touch the ground)
    keep = ys > h * 0.3
    ys, xs = ys[keep], xs[keep]
    pts = set()
    for k in range(1, length + 1):
        for y, x in zip(ys, xs):
            pts.add((y + at[1] + k // 2, x + at[0] + k))
    for (y, x) in pts:
        if 0 <= y < H and 0 <= x < W:
            a[y, x, :3] = darker(a[y, x, :3])


def plateau(img):
    """Raised rock plateau with a cliff face on its south and west sides and stairs carved into the west face."""
    a = P.to_np(img)
    x0, y0, x1, y1 = PLAT
    yy, xx = np.mgrid[0:H, 0:W]
    top = (xx >= x0) & (xx < x1) & (yy >= y0) & (yy < y1)
    n = G.smooth(H, W, 41, 8)
    a[top, :3] = (86, 106, 86)
    a[top & (n > 0.75), :3] = (127, 148, 120)
    # flagstone court in front of the shrine
    court = top & (np.abs(xx - 780) < 34) & (yy > 200) & (yy < y1 - 2)
    a[court, :3] = C["cob"]; a[court & ((xx + (yy // 3) * 2) % 5 == 0), :3] = C["cob_lo"]; a[court & (yy % 3 == 0), :3] = C["cob_lo"]
    # cliff faces: south (rows y1..y1+CLIFF) and west (cols x0-CLIFF//2..x0, drawn as a sloped face)
    for y in range(y1, y1 + CLIFF):
        t = (y - y1) / CLIFF
        col = C["cliff_hi"] if t < 0.15 else (C["cliff"] if t < 0.6 else C["cliff_lo"])
        for x in range(x0 - 6, x1):
            if 0 <= y < H:
                v = (x * 5 + y * 3) % 9
                a[y, x, :3] = col if v else C["cliff_dk"]
    a[y1 + CLIFF - 1, x0 - 6:x1, :3] = C["cliff_dk"]
    for y in range(y0, y1 + CLIFF):
        for x in range(x0 - 6, x0):
            if y < y1 or True:
                v = (x * 3 + y * 7) % 8
                a[y, x, :3] = C["cliff_lo"] if v else C["cliff_dk"]
    a[y0:y1, x0, :3] = C["cliff_hi"]  # lit rim on the plateau edge
    a[y1, x0:x1, :3] = C["cliff_hi"]
    # carved stairs in the west face, from the main street up to the court
    sx0, sy0 = x0 - 8, 214
    for i in range(8):
        y = sy0 + i * 2
        a[y:y + 2, sx0 - i:x0 + 8, :3] = C["cob_hi"] if i % 2 == 0 else C["cob"]
        a[y + 1, sx0 - i:x0 + 8, :3] = C["cob_dk"]
    # shadow the plateau throws on the ground below its south face
    for y in range(y1 + CLIFF, y1 + CLIFF + 6):
        for x in range(x0 - 4, x1):
            if (x + y) % 1 == 0:
                a[y, x, :3] = darker(a[y, x, :3])
    return P.to_im(a)


def crate(c=(143, 86, 59)):
    s = Image.new("RGBA", (6, 6), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.rectangle((0, 0, 5, 5), fill=c); d.line((0, 0, 5, 5), fill=(90, 63, 53)); d.line((0, 0, 5, 0), fill=(200, 176, 138))
    return P.outline(s)


def barrel():
    s = Image.new("RGBA", (5, 7), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.rectangle((0, 1, 4, 6), fill=(143, 86, 59)); d.ellipse((0, 0, 4, 2), fill=(90, 63, 53))
    d.line((0, 3, 4, 3), fill=(52, 50, 59)); d.line((0, 5, 4, 5), fill=(52, 50, 59))
    return P.outline(s)


def lamp():
    s = Image.new("RGBA", (3, 12), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.line((1, 2, 1, 11), fill=(52, 50, 59)); d.rectangle((0, 0, 2, 2), fill=(254, 231, 97))
    return P.outline(s)


def fence(n):
    s = Image.new("RGBA", (n * 4 + 1, 5), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.line((0, 1, n * 4, 1), fill=(106, 74, 40)); d.line((0, 3, n * 4, 3), fill=(106, 74, 40))
    for x in range(0, n * 4 + 1, 4):
        d.line((x, 0, x, 4), fill=(154, 112, 64))
    return P.outline(s)


def calm_ground():
    """Calm, desaturated dark grass: 3 values in big soft patches, sparse tufts (playbook 9.1)."""
    g = np.zeros((H, W, 3), np.uint8); g[:] = (86, 106, 86)
    big = G.smooth(H, W, 3, 26)
    g[big > 0.72] = (127, 148, 120)  # one lighter value in big soft patches
    t = G.noise(H, W, 5, 1)
    tuft = (t > 0.992) & (big >= 0.33)
    g[tuft] = (127, 148, 120); g[np.roll(tuft, 1, 0)] = (52, 70, 56)
    return g


def villager(body, hair):
    s = Image.new("RGBA", (6, 10), (0, 0, 0, 0)); d = ImageDraw.Draw(s)
    d.rectangle((1, 0, 4, 3), fill=(194, 133, 105)); d.rectangle((1, 0, 4, 1), fill=hair)
    d.rectangle((0, 4, 5, 8), fill=body); d.rectangle((1, 9, 2, 9), fill=(52, 50, 59)); d.rectangle((3, 9, 4, 9), fill=(52, 50, 59))
    return P.outline(s)


def compose():
    g = calm_ground()
    road, plaza, shrine_m, river, river_x = T2.layout_masks()
    road &= ~((np.mgrid[0:H, 0:W][1] >= PLAT[0] - 8))  # the street ends at the stairs
    T2.cobble(g, road & ~river)
    bank = river ^ (np.roll(river, 1, 1) & np.roll(river, -1, 1))
    g[river] = C["water"]
    rip = G.noise(H, W, 31, 1)
    g[river & (rip > 0.93)] = C["water_hi"]; g[river & (rip > 0.985)] = C["water_fx"]
    g[bank] = C["cob_dk"]; g[np.roll(river, -2, 0) & ~river & np.roll(river, -1, 1)] = C["grass_lo"]
    g[np.roll(bank, 1, 0) & river] = C["water_dk"]; g[np.roll(bank, 2, 0) & river] = C["water_dk"]
    img = P.to_im(np.dstack([g, np.full((H, W), 255, np.uint8)]))
    d = ImageDraw.Draw(img)
    bx = int(river_x[230, 0])
    d.rectangle((bx - 20, 219, bx + 20, 243), fill=C["wall"]); d.rectangle((bx - 20, 219, bx + 20, 221), fill=C["wall_hi"])
    d.rectangle((bx - 20, 241, bx + 20, 245), fill=C["wall_dk"])  # bridge side face (depth)
    for x in range(bx - 18, bx + 19, 4):
        d.line((x, 222, x, 240), fill=C["wall_lo"])
    img = plateau(img)
    img = T2.fog(img)
    img = T2.draw_walls(img)
    img = T2.sealed_gate(img)
    placed = []

    def put(s, cx, by, key, label=None, num=None, shadow=6):
        placed.append((by, s, (cx - s.width // 2, by - s.height), key, label, num, shadow))
    for n, (lab, f, w, (cx, by)) in BLD.items():
        put(spr(f, w), cx, by, "bld", lab, n, 4)
    for f, w, (cx, by) in HOUSES:
        put(spr(f, w), cx, by, "house", None, None, 4)
    tw = spr("t3_tower_s801", 26)
    for (tx, ty) in ((WX0 + 6, WY0 + 30), (WX1 - 6, WY0 + 30), (WX0 + 6, WY1 + 4), (WX1 - 6, WY1 + 4),
                     (440, WY0 + 30), (440, WY1 + 4), (WX0 + 6, 200), (WX0 + 6, 268)):
        put(tw, tx, ty, "tower", None, None, 3)
    cols = [(162, 38, 51), (18, 78, 137), (62, 137, 72), (104, 56, 108), (190, 74, 47)]
    for i, (sx, sy) in enumerate(((300, 222), (318, 258), (350, 258), (366, 222), (334, 214))):
        put(T2.stall(cols[i % 5]), sx, sy, "stall", None, None, 3)
    put(T2.well(), 333, 240, "well", None, None, 3)
    for (x, y) in ((262, 160), (268, 162), (254, 334), (390, 330), (170, 330), (640, 214), (520, 160)):
        put(barrel() if (x + y) % 2 else crate(), x, y, "prop", None, None, 2)
    for (x, y) in ((260, 232), (410, 232), (560, 232), (660, 232), (746, 300), (814, 300)):
        put(lamp(), x, y, "lamp", None, None, 3)
    for i, (x, y) in enumerate(((310, 246), (352, 232), (420, 236), (600, 238), (700, 240), (760, 228), (250, 166), (140, 334))):
        put(villager([(104, 56, 108), (62, 137, 72), (115, 62, 57), (58, 68, 102)][i % 4], [(62, 39, 49), (200, 176, 138), (24, 20, 37)][i % 3]), x, y, "villager", None, None, 2)
    for (x, y, n) in ((560, 224, 6), (90, 420, 8), (420, 420, 6), (560, 420, 5)):
        put(fence(n), x, y, "fence", None, None, 1)
    tspots = [(70, 120), (150, 120), (300, 120), (420, 120), (520, 120), (560, 150), (680, 120), (720, 120),
              (60, 330), (200, 420), (300, 420), (380, 420), (520, 420), (680, 420), (820, 420), (760, 370),
              (840, 120), (735, 100), (830, 200), (420, 300), (470, 300), (650, 330)]
    for i, (x, y) in enumerate(tspots):
        put(spr(*TREES[i % 4]), x, y, "tree", None, None, 4)
    a = P.to_np(img)
    for by, s, at, k, lab, n, sl in placed:
        cast_shadow(a, s, at, sl)
        if k in ("bld", "house", "tower"):   # foundation: a 1 px dark contact line + plinth under the wall
            sa = P.to_np(s)[..., 3] > 0
            cols = np.where(sa.any(0))[0]
            yb = at[1] + s.height
            for x in cols:
                for dy in (0, 1):
                    xx, yy = at[0] + x, yb + dy
                    if 0 <= xx < W and 0 <= yy < H:
                        a[yy, xx, :3] = darker(darker(a[yy, xx, :3])) if dy == 0 else darker(a[yy, xx, :3])
    img = P.to_im(a)
    img = T2.candles(img, 780, 214)
    for by, s, at, k, lab, n, sl in sorted(placed, key=lambda p: p[0]):
        img.alpha_composite(s, at)
    lots = [(9, "Church (lot)", 410, 60, 56, 44), (10, "Trophy cabin (lot)", 470, 330, 54, 40), (11, "spare lot", 160, 360, 44, 30), (12, "spare lot", 700, 340, 44, 32)]
    for nn, lab, x, y, w, h in lots:
        T2.lot(img, x, y, w, h, nn)
        placed.append((0, None, (x + w // 2, y + h // 2), "lot", lab, nn, 0))
    placed.append((0, None, (333, 232), "tag", "Market square", 13, 0))
    placed.append((0, None, (382, 200), "tag", "Bounty board", 14, 0))
    return img, placed


def dusk(img, placed):
    import town_concept as TC
    d = img.copy()
    for by, s, at, k, lab, n, sl in sorted([p for p in placed if p[1] is not None], key=lambda p: p[0]):
        if k in ("bld", "house"):
            d.alpha_composite(TC.light_windows(s), at)
    a = P.to_np(d).astype(float)
    warm = np.zeros(a.shape[:2], bool)
    for c in ((254, 174, 52), (247, 118, 34), (254, 231, 97), (255, 244, 163)):
        warm |= np.all(a[..., :3] == c, -1)
    # dusk LUT on the palette: each colour -> a darker palette colour of similar hue, nudged blue
    lab_p = P.PAL_LAB
    lut = {}
    for i, c in enumerate(P.PAL.astype(int)):
        l, aa, bb = lab_p[i]
        tgt = np.array([l * 0.68, aa * 0.8 - 0.004, bb * 0.8 - 0.02])
        dd = ((lab_p - tgt) ** 2 * np.array([1.0, 3.0, 3.0])).sum(-1)
        lut[tuple(c)] = P.PAL[dd.argmin()]
    flat = a[..., :3].reshape(-1, 3).astype(int)
    keys, inv = np.unique(flat, axis=0, return_inverse=True)
    mapped = []
    for k in keys:
        kk = tuple(int(v) for v in k)
        if kk not in lut:
            kk = tuple(int(v) for v in P.PAL[P.nearest_idx(np.array(k, float)[None])[0]])
        mapped.append(lut.get(kk, np.array(kk)))
    snapped = np.array(mapped)[inv.reshape(-1)].reshape(a[..., :3].shape)
    out = np.where(warm[..., None], a[..., :3], snapped)
    ol = np.all(a[..., :3] == P.OUTLINE, -1)
    out[ol] = P.OUTLINE
    yy, xx = np.mgrid[0:H, 0:W]
    fogm = (xx < WX0 - 6) | (xx > WX1 + 6) | (yy < WY0 - 6) | (yy > WY1 + 6)
    L = P.oklab(a[..., :3])[..., 0]
    out[fogm & (L >= 0.45)] = C["fog"]; out[fogm & (L < 0.45)] = C["fog_lo"]; out[fogm & (L < 0.3)] = (24, 20, 37)
    res = P.to_im(np.dstack([out.astype(np.uint8), np.full((H, W), 255, np.uint8)]))
    pts = [(780, 196), (760, 222), (800, 222)] + [(x, y - 11) for (x, y) in ((260, 232), (410, 232), (560, 232), (660, 232), (746, 300), (814, 300))]
    return TC.glow(res, pts, r=14)


if __name__ == "__main__":
    img, placed = compose()
    img.save(r"C:\ai\art_work3\town3_day.png"); dusk(img, placed).save(r"C:\ai\art_work3\town3_dusk.png")
    print("ok")
