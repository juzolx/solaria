"""Solaria town concept in the new style: procedural ground + AI building sprites cleaned to the
palette, placed on today's town.json layout (halved to art pixels), plus Church, trophy cabin and an
empty plot in a strip added at the bottom. Writes day and dusk versions at 2x (704x1280 files).
"""
import sys, json
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P
import town_ground as G

RAW = "C:/ai/art_raw/"
REPO = r"C:\gamedev\solaria_wt_newart"
# id: (raw file, width in art px, rect in 1x map px [x, y, w, h])  -- rects from art/town/town.json
spots = {s["id"]: s for s in json.load(open(REPO + r"\art\town\town.json"))["spots"]}
B = {
    "gate": ("bld_gate_s23", 56), "guild": ("bld_guild_s23", 100), "inn": ("bld_inn_s23", 100),
    "shop": ("bld_shop_s23", 78), "smith": ("bld_smith_s22", 70), "tavern": ("bld_tavern_s23", 72),
    "stash": ("bld_vault_s23", 74), "market": ("bld_market_s23", 62), "clinic": ("bld_clinic_s23", 80),
}
NEW = {  # new buildings in the added bottom strip (1x rects)
    "church": ("bld_church_s22", 84, [36, 1050, 200, 210]),
    "trophy": ("bld_trophy_s22", 70, [470, 1170, 170, 180]),
}
PLOTS = [[64, 556, 150, 104], [300, 1250, 110, 90]]  # empty lots (1x)

_cache = {}


def building(name, width):
    k = (name, width)
    if k not in _cache:
        _cache[k] = P.clean_building(RAW + name + ".png", width=width)
    return _cache[k]


def sub_figure(raw_name, box, width=None):
    raw, nobg, grid, nat = P.native_of(RAW + raw_name + ".png")
    f = P.crop(P.to_im(P.keep_largest(P.to_np(nat.crop(box)), 0.2)))
    if width and f.width > width:
        f = P.shrink_mode(f, width=width)
    return P.outline(P.quantize(f, 16))


def light_windows(im):
    """Lit windows for dusk: small enclosed dark pockets inside the building become warm light."""
    a = P.to_np(im).copy()
    h, w = a.shape[:2]
    L = P.oklab(a[..., :3].astype(float))[..., 0]
    out = np.all(a[..., :3] == P.OUTLINE, -1)
    dark = (a[..., 3] > 0) & (L < 0.30) & ~out
    tmp = np.zeros_like(a); tmp[dark] = 255
    for (x0, y0, x1, y1), m in P.components(tmp, 2):
        bw, bh = x1 - x0, y1 - y0
        if not (2 <= bw <= 8 and 3 <= bh <= 9) or m.sum() < 5 or m.sum() < 0.7 * bw * bh:
            continue
        ring = a[max(0, y0 - 1):y1 + 1, max(0, x0 - 1):x1 + 1, 3]
        if (ring == 0).any() or y0 < h * 0.12:
            continue
        a[m, :3] = (254, 174, 52)
        top = m & ~np.roll(m, 1, 0)
        a[top, :3] = (247, 118, 34)
        a[m & ~np.roll(m, -1, 0) & ~top, :3] = (254, 231, 97)
    return P.to_im(a)


def lamp():
    a = np.zeros((10, 3, 4), np.uint8)
    a[2:, 1] = (52, 50, 59, 255)
    a[0:2, 0:3] = (254, 231, 97, 255)
    a[9, 0:3] = (31, 29, 36, 255)
    return P.outline(P.to_im(a))


def plot_lot(img, r):
    x, y, w, h = [v // 2 for v in r]
    d = ImageDraw.Draw(img)
    d.rectangle((x, y, x + w, y + h), fill=(90, 63, 53, 255))
    for yy in range(y + 3, y + h, 5):
        d.line((x + 2, yy, x + w - 2, yy), fill=(62, 39, 49, 255))
    for xx in range(x, x + w + 1, 4):  # fence posts
        d.rectangle((xx, y - 2, xx + 1, y + 1), fill=(154, 112, 64, 255))
        d.rectangle((xx, y + h - 1, xx + 1, y + h + 2), fill=(106, 74, 40, 255))
    d.line((x, y - 1, x + w, y - 1), fill=(106, 74, 40, 255))
    d.line((x, y + h, x + w, y + h), fill=(106, 74, 40, 255))
    # sign post
    d.rectangle((x + w // 2 - 1, y + h // 2 - 6, x + w // 2, y + h // 2 + 2), fill=(106, 74, 40, 255))
    d.rectangle((x + w // 2 - 5, y + h // 2 - 9, x + w // 2 + 4, y + h // 2 - 5), fill=(200, 176, 138, 255))


def dusk(img):
    """Dusk grade that stays on the palette: darken + blue shift, then snap; warm lights untouched."""
    a = P.to_np(img).copy()
    warm = np.zeros(a.shape[:2], bool)
    for c in ((254, 174, 52), (247, 118, 34), (254, 231, 97), (255, 244, 163)):
        warm |= np.all(a[..., :3] == c, -1)
    rgb = a[..., :3].astype(float) * np.array([0.58, 0.60, 0.80]) + np.array([6, 6, 22])
    keys, inv = np.unique(rgb.reshape(-1, 3).round(), axis=0, return_inverse=True)
    snapped = P.PAL[P.nearest_idx(keys)][inv.reshape(-1)].reshape(rgb.shape)
    out = a.copy()
    out[..., :3] = np.where(warm[..., None], a[..., :3], snapped).astype(np.uint8)
    keep_ol = np.all(a[..., :3] == P.OUTLINE, -1)
    out[keep_ol, :3] = P.OUTLINE
    return P.to_im(out)


def glow(img, pts, r=10):
    """Lamp and window glow: 3 hard alpha rings (FX_ALPHA steps), warm colour."""
    g = Image.new("RGBA", img.size, (0, 0, 0, 0)); d = ImageDraw.Draw(g)
    for (x, y) in pts:
        for rr, al in ((r, 40), (r * 2 // 3, 64), (r // 3, 96)):
            d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(254, 174, 52, al))
    # composite in steps so the result stays a few flat bands
    out = img.copy(); out.alpha_composite(g)
    return out


def compose():
    img = G.to_rgba(G.ground())
    placed = []
    def put(sprite, rect, key):
        x, y, w, h = rect
        cx, by = (x + w // 2) // 2, (y + h) // 2
        at = (cx - sprite.width // 2, by - sprite.height)
        placed.append((at[1] + sprite.height, sprite, at, key))
    for k, (f, wd) in B.items():
        put(building(f, wd)["final"], spots[k]["rect"], k)
    for k, (f, wd, r) in NEW.items():
        put(building(f, wd)["final"], r, k)
    put(sub_figure("bld_bounty_s21", (51, 72, 73, 93)), spots["bounty"]["rect"], "bounty")
    put(building("bld_fountain_s24", 44)["final"], [310, 380, 90, 90], "fountain")
    trees = [building(f, w)["final"] for f, w in (("tree_pine_s61", 34), ("tree_oak_s61", 44), ("tree_pine_s63", 30), ("tree_oak_s62", 38))]
    tree_spots = [(0, 120), (300, 110), (690, 120), (660, 380), (10, 600), (690, 560), (250, 880), (690, 880),
                  (20, 1330), (690, 1340), (430, 1350), (250, 1100), (0, 380)]
    for i, (x, y) in enumerate(tree_spots):
        t = trees[i % len(trees)]
        put(t, [x - t.width, y - t.height * 2, t.width * 2, t.height * 2], "tree")
    for (x, y) in json.load(open(REPO + r"\art\town\town.json"))["lights"]:
        put(lamp(), [x - 3, y - 20, 6, 22], "lamp")
    for r in PLOTS:
        plot_lot(img, r)
    # ground shadows: light from the top-left, so each sprite drops a flat shadow down-right
    ga = P.to_np(img)
    for _, sp, at, k in placed:
        sa = P.to_np(sp)[..., 3] > 0
        hh, ww = sa.shape
        for (ox, oy) in ((3, 2), (2, 1)):
            ys, xs = np.where(sa)
            ys, xs = ys + at[1] + oy, xs + at[0] + ox
            ok = (ys >= 0) & (ys < ga.shape[0]) & (xs >= 0) & (xs < ga.shape[1])
            ys, xs = ys[ok], xs[ok]
            px = ga[ys, xs, :3]
            grass = px[:, 1] > px[:, 0]
            ga[ys[grass], xs[grass], :3] = (25, 60, 62)
            ga[ys[~grass], xs[~grass], :3] = (90, 63, 53)
    img = P.to_im(ga)
    day = img.copy()
    for _, s, at, k in sorted(placed, key=lambda p: p[0]):
        day.alpha_composite(s, at)
    night = img.copy()
    for _, s, at, k in sorted(placed, key=lambda p: p[0]):
        night.alpha_composite(light_windows(s) if k not in ("tree", "lamp", "bounty", "fountain") else s, at)
    night = dusk(night)
    lights = [(x // 2, y // 2 - 9) for (x, y) in json.load(open(REPO + r"\art\town\town.json"))["lights"]]
    night = glow(night, lights)
    return day, night, placed


if __name__ == "__main__":
    out = sys.argv[1]
    day, night, placed = compose()
    day.resize((day.width * 2, day.height * 2), Image.NEAREST).save(out + "/town_concept_day.png")
    night.resize((night.width * 2, night.height * 2), Image.NEAREST).save(out + "/town_concept_dusk.png")
    print(day.size)
