"""Hand-placed pixel details drawn in code (AI never draws faces at this size).

- faces: per race and size (32/48), front portrait and back three-quarter sliver; eyes with a
  highlight, brows, nose shadow, mouth, tusks, goblin nose; stamped on a flattened skin patch
- hands: small shaded fists at known guide positions
- weapons: 10 code-drawn weapon sprites in the palette (sword, axe, mace, spear, bow, staff, orb, tome,
  dagger, shield), each with a grip point
- rarity: material ramps + trims + glow for Common -> Mythic
- rule passes: orphan pixels, white blobs, outline consistency
"""
import numpy as np
from PIL import Image, ImageDraw
import pixlib as P

def c(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

INK = c("2a1a1e"); WHITE = c("f4e6c4"); TUSK = c("f4e6c4")
EYE = {"human": c("5a3f35"), "elf": c("3e8948"), "orc": c("a22633"), "dwarf": c("3c5e8b"), "goblin": c("fee761")}
BROW = {"human": c("3e2731"), "elf": c("a3825f"), "orc": c("181425"), "dwarf": c("733e39"), "goblin": c("265c42")}


def _skin_tones(a, box):
    x0, y0, x1, y1 = box
    sub = a[y0:y1, x0:x1].reshape(-1, 4)
    sub = sub[(sub[:, 3] > 0) & ~np.all(sub[:, :3] == P.OUTLINE, -1)]
    if not len(sub):
        return None
    L = P.oklab(sub[:, :3].astype(float))
    ch = np.hypot(L[:, 1], L[:, 2])
    sk = sub[(L[:, 0] > 0.5) & (ch > 0.02)]
    if not len(sk):
        sk = sub
    keys, cnt = np.unique(sk[:, :3], axis=0, return_counts=True)
    base = keys[cnt.argmax()]
    # darker shade for nose/mouth: one palette step down of the base
    t = np.array(base, float) * np.array([0.78, 0.72, 0.72])
    shade = P.PAL[P.nearest_idx(t[None])[0]]
    return tuple(int(v) for v in base), tuple(int(v) for v in shade)


def face_front(im, race, cx, ey, size=32):
    """Stamp a front face: cx = face centre x, ey = eye row. Flattens the face patch first."""
    a = P.to_np(im).copy()
    s = 1 if size == 32 else 2
    gap = 3 if size == 32 else 4             # half distance between the eyes ("room for a third eye")
    box = (cx - gap - 2 * s, ey - 2 * s, cx + gap + 2 * s + 1, ey + 4 * s)
    tones = _skin_tones(a, box)
    if tones is None:
        return im
    base, shade = tones
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        for x in range(x0, x1):
            px = a[y, x]
            if px[3] and not np.all(px[:3] == P.OUTLINE):
                L = P.oklab(px[:3].astype(float)[None])[0]
                if L[0] > 0.45 and np.hypot(L[1], L[2]) > 0.02:   # skin-like: flatten AI face noise
                    a[y, x, :3] = base
    def put(x, y, col):
        a[y, x, :3] = col; a[y, x, 3] = 255
    for side in (-1, 1):
        ex = cx + side * gap
        if size == 32:
            put(ex, ey, INK); put(ex, ey + 1, EYE[race]); put(ex + (1 if side < 0 else 0), ey, WHITE if race != "goblin" else EYE[race])
            put(ex - side * 0, ey - 2, BROW[race])
        else:
            for dy in range(3):
                put(ex, ey + dy, INK); put(ex + side, ey + dy, EYE[race] if dy else INK)
            put(ex, ey, WHITE)
            put(ex - 1, ey - 2, BROW[race]); put(ex, ey - 2, BROW[race]); put(ex + 1, ey - 2, BROW[race])
        if race == "goblin":
            put(ex, ey, EYE[race]); put(ex, ey + (1 if size == 32 else 2), INK)
    my = ey + (3 if size == 32 else 5)
    if race == "goblin":   # long nose instead of a mouth line
        for k in range(3 * s):
            put(cx + (k // 2), ey + 1 + k, shade)
        put(cx - 1, my + 1, INK); put(cx + 1, my + 1, INK); put(cx, my + 1, WHITE)
    elif race != "dwarf":  # dwarves: the beard covers the mouth
        put(cx, ey + (1 if size == 32 else 2), shade)                       # nose shadow
        for k in range(-s, s + 1):
            put(cx + k, my, shade)                                          # mouth
    if race == "orc":
        put(cx - 2 * s, my, TUSK); put(cx + 2 * s, my, TUSK); put(cx - 2 * s, my - 1, TUSK); put(cx + 2 * s, my - 1, TUSK)
    return P.to_im(a)


def face_back(im, race, ex, ey, size=32):
    """Back three-quarter: the sliver of face at the right edge of the head (eye, brow, nose tip, ear)."""
    a = P.to_np(im).copy()
    s = 1 if size == 32 else 2
    def put(x, y, col):
        if 0 <= x < a.shape[1] and 0 <= y < a.shape[0]:
            a[y, x, :3] = col; a[y, x, 3] = 255
    tones = _skin_tones(a, (ex - 3 * s, ey - 2 * s, ex + 3 * s, ey + 4 * s))
    if tones is None:
        return im
    base, shade = tones
    ap = a[ey, ex]
    Lp = P.oklab(ap[:3].astype(float)[None])[0]
    if ap[3] == 0 or Lp[0] < 0.45 or np.linalg.norm(np.array(ap[:3], int) - np.array(base)) > 60:
        return im   # the anchor is hair or helmet, not face: leave it (no brown patch on hair)
    for y in range(ey - 1, ey + 3 * s):
        for x in range(ex - s, ex + 2 * s + 1):
            if a[y, x, 3] and not np.all(a[y, x, :3] == P.OUTLINE):
                a[y, x, :3] = base
    put(ex, ey, INK)
    if s == 2:
        put(ex, ey + 1, INK); put(ex + 1, ey, EYE[race])
    put(ex, ey - 1 - (s - 1), BROW[race]); put(ex - 1, ey - 1 - (s - 1), BROW[race])
    put(ex + 2 * s, ey + s, base)                                   # nose tip past the cheek
    put(ex - 3 * s, ey + s, shade); put(ex - 3 * s, ey + s + 1, shade)  # ear shadow
    if race == "orc":
        put(ex + s, ey + 3 * s, TUSK); put(ex + s, ey + 3 * s - 1, TUSK)
    if race == "goblin":
        for k in range(2 * s + 1):
            put(ex + 1 + k, ey + 1 + k // 2, base)
        put(ex, ey, EYE[race])
    return P.to_im(a)


def hand(im, x, y, skin, size=32):
    a = P.to_np(im).copy()
    s = 2 if size == 32 else 3
    base = np.array(skin[0]); shade = np.array(skin[1]); lite = np.array(skin[2])
    for dy in range(s):
        for dx in range(s):
            col = lite if (dx == 0 and dy == 0) else (shade if dy == s - 1 else base)
            a[y + dy, x + dx, :3] = col; a[y + dy, x + dx, 3] = 255
    return P.to_im(a)


# ------------------------------------------------------------------ cleanup rules
def rule_passes(im):
    """orphans -> neighbour colour; isolated near-white blobs (<= 3 px, not highlights next to metal) -> neighbours;
    then re-outline so the ring is one pixel everywhere."""
    a = P.to_np(im).copy()
    h, w = a.shape[:2]
    op = a[..., 3] > 0
    # orphans: opaque pixels with no opaque 4-neighbour
    n = sum(np.roll(np.roll(op, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    a[op & (n == 0), 3] = 0
    rgb = a[..., :3].astype(int)
    white = (a[..., 3] > 0) & (rgb.min(-1) > 215)
    tmp = np.zeros_like(a); tmp[white] = 255
    for (x0, y0, x1, y1), m in P.components(tmp, 1):
        if m.sum() <= 3:
            continue
        # big white blob = leftover background trapped inside the silhouette (e.g. between the legs): clear it
        a[m, 3] = 0
    # outline consistency: strip the old ring, rebuild one clean 1 px ring
    ol = np.all(a[..., :3] == P.OUTLINE, -1) & (a[..., 3] > 0)
    clear = a[..., 3] == 0
    touch = np.zeros_like(clear)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        touch |= np.roll(np.roll(clear, dy, 0), dx, 1)
    a[ol & touch, 3] = 0
    return P.outline(P.to_im(a), edge_ink=True).crop((1, 1, w + 1, h + 1))


# ------------------------------------------------------------------ weapons (code-drawn, palette)
STEEL = [c("34323b"), c("625f6a"), c("a8a8ba"), c("e4e0ec")]
WOOD = [c("3e2731"), c("6a4a28"), c("9a7040"), c("c8a060")]
GOLD = [c("733e39"), c("c8a060"), c("feae34"), c("fee761")]


def _w(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))


def weapons():
    """name -> (sprite pointing UP, grip (x, y)). Drawn at 1x art px for the 32 px heroes."""
    out = {}
    im = _w((7, 22)); d = ImageDraw.Draw(im)   # sword
    d.rectangle((2, 0, 4, 14), fill=STEEL[2]); d.line((3, 0, 3, 13), fill=STEEL[3]); d.line((4, 1, 4, 14), fill=STEEL[1])
    d.rectangle((0, 15, 6, 16), fill=GOLD[1]); d.rectangle((2, 17, 4, 20), fill=WOOD[1]); d.rectangle((2, 21, 4, 21), fill=GOLD[1])
    out["sword"] = (im, (3, 18))
    im = _w((10, 22)); d = ImageDraw.Draw(im)  # axe
    d.rectangle((4, 2, 5, 21), fill=WOOD[1]); d.line((4, 2, 4, 21), fill=WOOD[2])
    d.polygon([(5, 1), (9, 0), (9, 9), (5, 7)], fill=STEEL[2]); d.line((9, 0, 9, 9), fill=STEEL[3]); d.line((5, 7, 9, 9), fill=STEEL[1])
    out["axe"] = (im, (4, 17))
    im = _w((9, 20)); d = ImageDraw.Draw(im)   # mace
    d.rectangle((3, 6, 5, 19), fill=WOOD[1]); d.ellipse((0, 0, 8, 7), fill=STEEL[1]); d.ellipse((1, 1, 5, 4), fill=STEEL[2])
    for x, y in ((4, 0), (0, 3), (8, 3), (4, 7)):
        d.point((x, y), fill=STEEL[3])
    out["mace"] = (im, (4, 16))
    im = _w((5, 30)); d = ImageDraw.Draw(im)   # spear
    d.rectangle((2, 6, 2, 29), fill=WOOD[1]); d.polygon([(2, 0), (4, 5), (2, 7), (0, 5)], fill=STEEL[2]); d.line((2, 0, 2, 6), fill=STEEL[3])
    out["spear"] = (im, (2, 20))
    im = _w((9, 24)); d = ImageDraw.Draw(im)   # bow
    d.arc((-6, 0, 8, 23), -80, 80, fill=WOOD[2], width=2); d.line((1, 1, 1, 22), fill=WOOD[3])
    out["bow"] = (im, (6, 12))
    im = _w((7, 30)); d = ImageDraw.Draw(im)   # staff
    d.rectangle((3, 5, 3, 29), fill=WOOD[1]); d.line((2, 6, 2, 29), fill=WOOD[2])
    d.polygon([(3, 0), (6, 3), (3, 6), (0, 3)], fill=c("4fb0c6")); d.point((2, 2), fill=c("c8f2ee"))
    out["staff"] = (im, (3, 20))
    im = _w((8, 8)); d = ImageDraw.Draw(im)    # orb
    d.ellipse((0, 0, 7, 7), fill=c("68386c")); d.ellipse((1, 1, 5, 5), fill=c("9a4fc0")); d.point((2, 2), fill=c("e8b8f0"))
    out["orb"] = (im, (4, 7))
    im = _w((9, 10)); d = ImageDraw.Draw(im)   # tome
    d.rectangle((0, 0, 8, 9), fill=c("7a2b2b") if False else c("a22633")); d.rectangle((1, 1, 7, 8), fill=c("733e39"))
    d.line((0, 0, 0, 9), fill=GOLD[1]); d.rectangle((3, 3, 5, 5), fill=GOLD[2]); d.line((8, 1, 8, 9), fill=WHITE)
    out["tome"] = (im, (4, 9))
    im = _w((5, 13)); d = ImageDraw.Draw(im)   # dagger
    d.rectangle((1, 0, 3, 7), fill=STEEL[2]); d.line((2, 0, 2, 6), fill=STEEL[3]); d.rectangle((0, 8, 4, 8), fill=GOLD[1]); d.rectangle((1, 9, 3, 12), fill=WOOD[1])
    out["dagger"] = (im, (2, 10))
    im = _w((11, 13)); d = ImageDraw.Draw(im)  # shield (heater)
    d.polygon([(0, 0), (10, 0), (10, 6), (5, 12), (0, 6)], fill=STEEL[1]); d.polygon([(1, 1), (9, 1), (9, 6), (5, 11), (1, 6)], fill=c("3c5e8b"))
    d.line((5, 1, 5, 10), fill=GOLD[1]); d.line((1, 4, 9, 4), fill=GOLD[1]); d.point((2, 2), fill=STEEL[3])
    out["shield"] = (im, (5, 6))
    return {k: (P.outline(v[0]), (v[1][0] + 1, v[1][1] + 1)) for k, v in out.items()}


# ------------------------------------------------------------------ rarity (sprite-design 8.2: 4 visual tiers)
# material ramp from the zone (Catacombs = bone/iron), trim colour from the rarity, placed where the back
# view sees it (pauldron tops, belt, a back band); each tier adds a NON-colour cue.
TIERS = [  # rarity, visual tier, metal ramp (dark->light, from the RARITY), trim, bands, gem, ornate shape, mythic
    ("Common", "Plain", ["34323b", "4a4852", "7d8798", "a8a8ba"], "625f6a", 1, False, False, False),
    ("Uncommon", "Plain", ["193c3e", "566a56", "7f9478", "a8b89a"], "3e8948", 1, False, False, False),
    ("Rare", "Fine", ["172038", "253a5e", "4f8fba", "a4dddb"], "c0cbdc", 1, False, False, False),
    ("Epic", "Fine", ["2a1a1e", "68386c", "9a4fc0", "e8b8f0"], "c0cbdc", 2, True, False, False),
    ("Legendary", "Ornate", ["3e2731", "9a7040", "c8a060", "fee761"], "a22633", 2, True, True, False),
    ("Mythic", "Mythic", ["181425", "253a5e", "2e7896", "c8f2ee"], "2ce8f5", 2, True, True, True),
]


def _ring(body):
    r = np.zeros_like(body)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        r |= np.roll(np.roll(body, dy, 0), dx, 1)
    return r & ~body


def rarity(im, tier, neck, belt=None):
    name, vt, ramp, trim, bands, gem, ornate, mythic = TIERS[tier]
    ramp = [c(h) for h in ramp]
    a = P.to_np(im).copy()
    h, w = a.shape[:2]
    op = (a[..., 3] > 0) & ~np.all(a[..., :3] == P.OUTLINE, -1)
    lab = P.oklab(a[..., :3].astype(float))
    ch = np.hypot(lab[..., 1], lab[..., 2])
    m = op & (ch < 0.06); m[:neck] = False
    if not m.sum():
        return im
    L = lab[..., 0][m]
    lo, hi = np.percentile(L, 5), np.percentile(L, 95)
    idx = np.clip(((L - lo) / max(1e-6, hi - lo) * 3.99).astype(int), 0, 3)
    a[..., :3][m] = np.array(ramp)[idx]
    ys, xs = np.where(m)
    top = ys.min(); bot = ys.max()
    tc = c(trim)
    # band 1: pauldron tops / shoulder line (seen from behind)
    for x in xs[ys == top]:
        a[top, x, :3] = tc
    if bands >= 2:   # band 2: belt line
        by = belt if belt is not None else int(top + (bot - top) * 0.62)
        for x in range(w):
            if m[by, x]:
                a[by, x, :3] = tc
    if vt in ("Fine", "Ornate", "Mythic"):  # detail overlay: rivets every 3 px on the shoulder line
        for x in xs[ys == top + 1][::3]:
            a[top + 1, x, :3] = ramp[3]
    if gem:          # 2x2 gem in the middle of the back, colour-blind safe cue (shape, not hue)
        gx = int(np.median(xs)); gy = int(top + (bot - top) * 0.35)
        a[gy:gy + 2, gx:gx + 2, :3] = tc; a[gy, gx, :3] = (255, 255, 255)
    if ornate:       # new silhouette: raised pauldron spikes above the shoulder line
        for x in (xs[ys == top].min(), xs[ys == top].max()):
            for k in range(1, 4):
                yy = top - k
                if yy >= 0 and a[yy, x, 3] == 0 or (yy >= 0 and not op[yy, x]):
                    a[yy, x, :3] = ramp[2] if k < 3 else tc; a[yy, x, 3] = 255
    if mythic:       # emissive rune pixels down the back
        gx = int(np.median(xs))
        for y in range(top + 3, bot - 2, 3):
            if m[y, gx - 2]:
                a[y, gx - 2, :3] = c("2ce8f5")
            if m[y + 1, gx + 2]:
                a[y + 1, gx + 2, :3] = c("c8f2ee")
    out = P.to_im(a)
    if mythic:       # glow + particles ONLY on real Mythic gear (Juzo)
        body = a[..., 3] > 0
        r1 = _ring(body); r2 = _ring(body | r1)
        yy, xx = np.mgrid[0:h, 0:w]
        g = np.zeros_like(a)
        g[r1] = tc + (255,)
        if mythic:
            g[r2 & ((xx + yy) % 2 == 0)] = tc + (255,)
            # a few particles (2x2 motes) rising above the shoulders
            for (px, py) in ((xs.min() - 3, top - 4), (xs.max() + 2, top - 7), (int(np.median(xs)), top - 10)):
                if 0 <= py < h - 1 and 0 <= px < w - 1:
                    g[py:py + 2, px:px + 2] = c("c8f2ee") + (255,)
        base = P.to_im(g); base.alpha_composite(out); out = base
    return out


def dither_band(im, ramp_pairs):
    """Checker dither one pixel deep on the boundary between two ramp colours (shade transitions only)."""
    a = P.to_np(im).copy()
    h, w = a.shape[:2]
    src = a.copy()
    for (c1, c2) in ramp_pairs:
        m1 = np.all(src[..., :3] == c1, -1); m2 = np.all(src[..., :3] == c2, -1)
        edge = m1 & (np.roll(m2, 1, 0) | np.roll(m2, -1, 0))
        yy, xx = np.mgrid[0:h, 0:w]
        a[edge & ((xx + yy) % 2 == 0), :3] = c2
    return P.to_im(a)
