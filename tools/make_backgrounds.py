"""Pixel-art battle backgrounds, one per zone (drawn at 160x90, saved Scale2x'd
to art/bg/zone_N.png at 320x180).
The ground line is row GROUND; the game lines it up with where fighters stand.

Run:  python3 tools/make_backgrounds.py
"""
import math
import os
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "art", "bg")
W, H = 160, 90
GROUND = 68
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gradient(im, y0, y1, colors):
    """Vertical dithered gradient through a list of colors."""
    px = im.load()
    cols = [hexc(c) for c in colors]
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1)) * (len(cols) - 1)
        i = min(int(t), len(cols) - 2)
        f = t - i
        for x in range(W):
            px[x, y] = cols[i + 1] if f * 16 > BAYER[y % 4][x % 4] else cols[i]


def rect(im, x0, y0, x1, y1, c):
    px = im.load()
    c = hexc(c) if isinstance(c, str) else c
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            px[x, y] = c


def dot(im, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        im.load()[x, y] = hexc(c) if isinstance(c, str) else c


def ground(im, top, base, dark, speck, rng):
    rect(im, 0, GROUND, W, H, base)
    for x in range(W):
        dot(im, x, GROUND, top)
        if rng.random() < 0.5:
            dot(im, x, GROUND + 1, top)
    for _ in range(140):
        dot(im, rng.randrange(W), rng.randrange(GROUND + 3, H), dark)
    for _ in range(50):
        dot(im, rng.randrange(W), rng.randrange(GROUND + 2, H), speck)


# ---------------------------------------------------------------- zones
def mossy(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0f2a2e", "#193c3e", "#265c42", "#3e6e48"])
    # far trees
    for i in range(14):
        x = i * 12 + rng.randrange(-3, 3)
        h = rng.randrange(28, 46)
        rect(im, x + 4, GROUND - h + 10, x + 7, GROUND, "#16302c")
        for k in range(10):
            r = 7 - k // 2
            cy = GROUND - h + k * 2
            rect(im, x + 5 - r, cy, x + 6 + r, cy + 2, "#173a32")
    # near trees
    for x in (6, 128):
        rect(im, x + 6, 10, x + 12, GROUND, "#2a2016")
        rect(im, x + 7, 10, x + 8, GROUND, "#3e2f1e")
        for k in range(16):
            r = 14 - abs(k - 6)
            rect(im, x + 9 - r, 4 + k * 2, x + 10 + r, 6 + k * 2, "#1f4a34" if k % 3 else "#2a5c3c")
    # light shafts
    for x0 in (40, 70, 95):
        for y in range(0, GROUND):
            x = x0 + y // 3
            if (x + y) % 3 == 0:
                c = im.getpixel((x, y))
                dot(im, x, y, tuple(min(255, v + 18) for v in c))
    # fireflies
    for _ in range(14):
        dot(im, rng.randrange(W), rng.randrange(20, GROUND - 4), "#fee761")
    ground(im, "#4f9a4a", "#2e5e3a", "#1f4430", "#63c74d", rng)
    # grass tufts
    for _ in range(40):
        x = rng.randrange(W)
        dot(im, x, GROUND - 1, "#4f9a4a")
    return im


def catacombs(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0d0e17", "#181425", "#262b44"])
    # brick wall
    for row in range(0, GROUND, 6):
        off = 0 if (row // 6) % 2 == 0 else 6
        for x in range(-12 + off, W, 12):
            rect(im, x, row, x + 11, row + 5, "#2a2e48" if (x // 12 + row) % 3 else "#30344f")
            rect(im, x, row + 5, x + 12, row + 6, "#1a1c2e")
    # arches (dark alcoves) with bones/skulls
    for ax in (18, 70, 122):
        for y in range(18, GROUND):
            half = 10 if y > 26 else int(math.sqrt(max(0, 100 - (26 - y) ** 2 * 1.4)))
            rect(im, ax - half, y, ax + half, y + 1, "#0d0e17")
        for sx in range(ax - 7, ax + 7, 4):
            rect(im, sx, 44, sx + 3, 47, "#c0cbdc")
            dot(im, sx, 45, "#0d0e17")
            dot(im, sx + 2, 45, "#0d0e17")
            dot(im, sx + 1, 47, "#8b9bb4")
    # candles
    for cx in (44, 96, 148):
        rect(im, cx, 50, cx + 2, 56, "#ead4aa")
        dot(im, cx, 48, "#feae34")
        dot(im, cx, 49, "#fee761")
        dot(im, cx + 1, 49, "#fee761")
        for r in range(1, 7):
            for a in range(0, 360, 30):
                x = cx + int(math.cos(math.radians(a)) * r)
                y = 49 + int(math.sin(math.radians(a)) * r)
                if 0 <= x < W and 0 <= y < H and r > 2 and (x + y) % 2 == 0:
                    c = im.getpixel((x, y))
                    dot(im, x, y, tuple(min(255, int(v + (40 - r * 5) * f)) for v, f in zip(c, (1.0, 0.8, 0.4))))
    ground(im, "#5a6988", "#3a4466", "#262b44", "#8b9bb4", rng)
    for x in range(0, W, 10):
        rect(im, x, GROUND + 2, x + 1, H, "#262b44")
    return im


def depths(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0b1a2e", "#124e89", "#1d6a96", "#2e7896"])
    # light rays from above
    for x0 in (20, 55, 100, 135):
        for y in range(0, GROUND):
            for w in range(3):
                x = x0 + w + y // 2
                if 0 <= x < W and (y + w) % 2 == 0:
                    c = im.getpixel((x, y))
                    dot(im, x, y, tuple(min(255, v + 14) for v in c))
    # kelp
    for i in range(10):
        x = rng.randrange(W)
        h = rng.randrange(18, 40)
        for y in range(GROUND - h, GROUND):
            sx = x + int(math.sin(y / 4.0 + i) * 2)
            rect(im, sx, y, sx + 2, y + 1, "#1d5a3a" if i % 2 else "#265c42")
    # rocks
    for x0, w0, h0 in ((0, 30, 14), (120, 40, 18), (60, 18, 8)):
        for y in range(GROUND - h0, GROUND):
            k = (y - (GROUND - h0)) / h0
            half = int(w0 / 2 * math.sqrt(max(0.0, k)))
            rect(im, x0 + w0 // 2 - half, y, x0 + w0 // 2 + half, y + 1, "#16304a")
    # bubbles
    for _ in range(18):
        x, y = rng.randrange(W), rng.randrange(4, GROUND - 4)
        dot(im, x, y, "#a4dddb")
        if rng.random() < 0.4:
            dot(im, x + 1, y - 2, "#73bed3")
    ground(im, "#a89070", "#6e5a46", "#4a3a2e", "#c8b08a", rng)
    for x in range(0, W, 2):  # water film over the sand
        dot(im, x, GROUND + 1, "#73bed3")
    return im


def ember(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#1a0f14", "#3e2731", "#68242c", "#a22633"])
    # basalt pillars
    for x0 in (8, 46, 104, 142):
        rect(im, x0, 0, x0 + 12, GROUND, "#2a1d26")
        rect(im, x0 + 1, 0, x0 + 3, GROUND, "#3e2731")
        for y in range(4, GROUND, 9):
            rect(im, x0, y, x0 + 12, y + 1, "#1a0f14")
    # far lava falls
    for x0 in (30, 84, 126):
        for y in range(10, GROUND):
            c = "#f77622" if (y // 2 + x0) % 3 else "#feae34"
            rect(im, x0, y, x0 + 3, y + 1, c)
    # embers
    for _ in range(26):
        dot(im, rng.randrange(W), rng.randrange(0, GROUND), rng.choice(["#feae34", "#f77622", "#fee761"]))
    ground(im, "#be4a2f", "#3e2731", "#2a1d26", "#733e39", rng)
    # lava cracks
    for _ in range(9):
        x, y = rng.randrange(W), rng.randrange(GROUND + 3, H - 2)
        for k in range(rng.randrange(4, 10)):
            dot(im, x + k, y + (k % 3 == 0), "#f77622")
            if k % 2:
                dot(im, x + k, y - 1, "#feae34")
    return im


def shadow(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0b0814", "#181425", "#2b1b45", "#3e2a5e"])
    # stars
    for _ in range(60):
        dot(im, rng.randrange(W), rng.randrange(0, GROUND - 10), rng.choice(["#c0cbdc", "#8b9bb4", "#e8b8f0"]))
    # big moon / eye
    for y in range(6, 26):
        for x in range(112, 140):
            if (x - 126) ** 2 + (y - 16) ** 2 < 90:
                dot(im, x, y, "#c27ad8" if (x - 122) ** 2 + (y - 13) ** 2 > 30 else "#e8b8f0")
    # floating rocks
    for x0, y0, w0 in ((14, 30, 22), (64, 20, 14), (90, 40, 18)):
        for k in range(6):
            half = w0 // 2 - k * w0 // 14
            rect(im, x0 + w0 // 2 - half, y0 + k, x0 + w0 // 2 + half, y0 + k + 1, "#262b44" if k else "#5a6988")
    ground(im, "#68386c", "#2b1b45", "#181425", "#9a4fc0", rng)
    for x in range(6, W, 22):  # glowing runes
        rect(im, x, GROUND + 6, x + 3, GROUND + 7, "#c27ad8")
        dot(im, x + 1, GROUND + 5, "#c27ad8")
    return im



# ---------------------------------------------------------------- helpers for areas
def ellipse(im, cx, cy, rx, ry, c):
    for y in range(int(cy - ry), int(cy + ry) + 1):
        for x in range(int(cx - rx), int(cx + rx) + 1):
            if ((x - cx) / max(rx, 0.5)) ** 2 + ((y - cy) / max(ry, 0.5)) ** 2 <= 1.0:
                dot(im, x, y, c)


def line(im, x0, y0, x1, y1, c, w=1):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        x = round(x0 + (x1 - x0) * i / n)
        y = round(y0 + (y1 - y0) * i / n)
        rect(im, x, y, x + w, y + w, c)


def tint(im, rgb, amount):
    """Blend the whole picture toward a color (for mood)."""
    px = im.load()
    t = hexc(rgb)
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            px[x, y] = tuple(int(c[i] + (t[i] - c[i]) * amount) for i in range(3))


def glow(im, cx, cy, r, rgb, strength=40):
    px = im.load()
    t = hexc(rgb)
    for y in range(max(0, cy - r), min(H, cy + r + 1)):
        for x in range(max(0, cx - r), min(W, cx + r + 1)):
            d = math.hypot(x - cx, y - cy)
            if d <= r and (x + y) % 2 == 0 or d <= r * 0.5:
                f = (1 - d / r) * strength / 100.0
                c = px[x, y]
                px[x, y] = tuple(min(255, int(c[i] + t[i] * f)) for i in range(3))


# ---------------------------------------------------------------- the 25 areas
def mossy_area(sub, rng):
    im = mossy(rng)
    if sub == 0:  # Fernlight Glade: bright, ferns
        tint(im, "#a8e070", 0.08)
        for x in range(0, W, 7):
            h = rng.randrange(5, 10)
            for k in range(h):
                dot(im, x + k // 2, GROUND - k, "#63c74d")
                dot(im, x - k // 2 + 3, GROUND - k, "#3e8948")
    elif sub == 1:  # Toadstool Ring: dusk, a ring of mushrooms
        tint(im, "#5a3a7a", 0.25)
        for i, x in enumerate(range(30, 135, 15)):
            hgt = 6 + (i % 3) * 2
            rect(im, x + 2, GROUND - hgt, x + 4, GROUND, "#ead4aa")
            ellipse(im, x + 3, GROUND - hgt, 4, 2, "#e43b44")
            dot(im, x + 1, GROUND - hgt - 1, "#ffffff")
            dot(im, x + 5, GROUND - hgt, "#ffffff")
        for _ in range(20):
            dot(im, rng.randrange(W), rng.randrange(10, GROUND), "#e8b8f0")
    elif sub == 2:  # Bramble Warren: thorny brambles and burrows
        for _ in range(9):
            x0 = rng.randrange(W)
            for k in range(30):
                x = x0 + int(math.sin(k / 3.0) * 6) + k // 3
                y = GROUND - k // 2
                dot(im, x, y, "#3e2731")
                if k % 4 == 0:
                    dot(im, x + 1, y - 1, "#733e39")
        for x in (40, 110):
            ellipse(im, x, GROUND + 2, 7, 4, "#1a1410")
    elif sub == 3:  # Hollow Oak: a giant hollow trunk
        rect(im, 62, 0, 98, GROUND, "#3a2a1e")
        rect(im, 64, 0, 68, GROUND, "#4e3a28")
        ellipse(im, 80, GROUND - 14, 9, 14, "#120c08")
        for y in range(0, GROUND, 6):
            dot(im, 70 + (y * 7) % 20, y, "#2a1d14")
        tint(im, "#2a3a1e", 0.12)
    else:  # Wychwood Heart: dark, dense, eyes in the trees
        tint(im, "#0b140f", 0.45)
        for _ in range(8):
            x, y = rng.randrange(8, W - 8), rng.randrange(14, GROUND - 14)
            dot(im, x, y, "#fee761")
            dot(im, x + 3, y, "#fee761")
    return im


def catacombs_area(sub, rng):
    im = catacombs(rng)
    if sub == 0:  # Bone Stair
        for i in range(8):
            rect(im, 100 + i * 7, GROUND - 4 - i * 4, W, GROUND - i * 4, "#3a4466" if i % 2 else "#30344f")
            rect(im, 100 + i * 7, GROUND - 4 - i * 4, W, GROUND - 3 - i * 4, "#5a6988")
    elif sub == 1:  # The Ossuary: walls of skulls
        for y in range(8, 40, 6):
            for x in range(4, W, 6):
                if (x // 6 + y // 6) % 3:
                    rect(im, x, y, x + 4, y + 4, "#c0cbdc")
                    dot(im, x + 1, y + 2, "#181425")
                    dot(im, x + 3, y + 2, "#181425")
        tint(im, "#181425", 0.25)
    elif sub == 2:  # Crypt of Candles: warm, lots of candles
        for x in range(8, W, 13):
            y = GROUND - 2 - (x * 3) % 6
            rect(im, x, y - 5, x + 2, y, "#ead4aa")
            dot(im, x, y - 7, "#feae34")
            dot(im, x, y - 6, "#fee761")
            glow(im, x, y - 7, 9, "#f77622", 30)
    elif sub == 3:  # Weeping Halls: cold, dripping, weeping statues
        tint(im, "#1d3a5a", 0.25)
        for x in (36, 124):
            rect(im, x, GROUND - 26, x + 10, GROUND, "#5a6988")
            ellipse(im, x + 5, GROUND - 30, 5, 5, "#8b9bb4")
            line(im, x + 3, GROUND - 29, x + 3, GROUND - 18, "#73bed3")
        for _ in range(30):
            x = rng.randrange(W)
            y = rng.randrange(0, GROUND)
            dot(im, x, y, "#73bed3")
    else:  # Hel's Gate: a great dark gate, blue mist
        rect(im, 52, 4, 108, GROUND, "#181425")
        rect(im, 56, 8, 104, GROUND, "#0b0814")
        for x in range(60, 104, 8):
            rect(im, x, 8, x + 2, GROUND, "#3a4466")
        rect(im, 50, 2, 110, 6, "#5a6988")
        for y in range(GROUND - 12, GROUND):
            for x in range(W):
                if (x + y * 3) % 5 == 0:
                    dot(im, x, y, "#8bb8d8")
        tint(im, "#3a5a8a", 0.15)
    return im


def depths_area(sub, rng):
    im = depths(rng)
    if sub == 0:  # Tidepools: shallow and bright
        tint(im, "#73bed3", 0.18)
        for x in (20, 70, 120):
            ellipse(im, x, GROUND + 6, 12, 3, "#4f8fba")
            ellipse(im, x - 3, GROUND + 5, 4, 1, "#a4dddb")
        for _ in range(6):
            x = rng.randrange(W)
            dot(im, x, GROUND - 1, "#e43b44")
            dot(im, x + 1, GROUND - 2, "#e43b44")
            dot(im, x - 1, GROUND - 2, "#e43b44")
    elif sub == 1:  # Drowned Village: sunken houses
        for x0, h in ((14, 26), (60, 34), (112, 22)):
            rect(im, x0, GROUND - h, x0 + 26, GROUND, "#2e4a5a")
            for k in range(10):
                rect(im, x0 - 2 + k, GROUND - h - k, x0 + 28 - k, GROUND - h - k + 1, "#3a2a2a")
            rect(im, x0 + 10, GROUND - 10, x0 + 16, GROUND, "#16304a")
            rect(im, x0 + 4, GROUND - h + 6, x0 + 9, GROUND - h + 11, "#73bed3")
    elif sub == 2:  # Coral Maze
        for _ in range(14):
            x = rng.randrange(W)
            c = rng.choice(["#e43b44", "#f77622", "#b55088", "#feae34"])
            for k in range(rng.randrange(8, 18)):
                dot(im, x + int(math.sin(k) * 2), GROUND - k, c)
                if k % 4 == 3:
                    dot(im, x + 2, GROUND - k, c)
                    dot(im, x - 2, GROUND - k - 1, c)
    elif sub == 3:  # Kelp Abyss: dark and thick with kelp
        tint(im, "#06101e", 0.45)
        for i in range(24):
            x = rng.randrange(W)
            h = rng.randrange(30, 66)
            for y in range(GROUND - h, GROUND):
                sx = x + int(math.sin(y / 5.0 + i) * 2)
                rect(im, sx, y, sx + 2, y + 1, "#1d4a2a" if i % 2 else "#265c42")
    else:  # Whirlpool's Edge: a swirl in the water
        for r in range(4, 40, 3):
            for a in range(0, 360, 6):
                ang = math.radians(a + r * 9)
                dot(im, 110 + int(math.cos(ang) * r), 30 + int(math.sin(ang) * r * 0.5), "#a4dddb" if r % 2 else "#4f8fba")
    return im


def ember_area(sub, rng):
    im = ember(rng)
    if sub == 0:  # Cinder Steps: ash falling, steps
        for i in range(6):
            rect(im, i * 9, GROUND - 3 - i * 3, i * 9 + 40, GROUND - i * 3, "#3e2731")
        for _ in range(60):
            dot(im, rng.randrange(W), rng.randrange(GROUND), "#8b9bb4")
        tint(im, "#5a5468", 0.15)
    elif sub == 1:  # Forge of Ash: anvils and a forge glow
        rect(im, 64, GROUND - 26, 96, GROUND, "#2a1d26")
        rect(im, 70, GROUND - 18, 90, GROUND - 4, "#f77622")
        rect(im, 74, GROUND - 14, 86, GROUND - 6, "#fee761")
        glow(im, 80, GROUND - 12, 30, "#f77622", 35)
        for x in (24, 128):
            rect(im, x, GROUND - 8, x + 14, GROUND - 5, "#5a6988")
            rect(im, x + 4, GROUND - 5, x + 10, GROUND, "#3a4466")
    elif sub == 2:  # Magma Galleries: a lava river
        for x in range(W):
            y = GROUND + 8 + int(math.sin(x / 9.0) * 2)
            rect(im, x, y, x + 1, y + 6, "#f77622" if (x // 3) % 3 else "#feae34")
        glow(im, 80, GROUND + 10, 60, "#f77622", 18)
    elif sub == 3:  # Brimstone Vault: yellow sulfur crystals
        for _ in range(12):
            x = rng.randrange(W)
            h = rng.randrange(6, 16)
            for k in range(h):
                w = max(1, (h - k) // 3)
                rect(im, x - w, GROUND - k, x + w, GROUND - k + 1, "#fee761" if k % 3 else "#feae34")
        tint(im, "#feae34", 0.08)
    else:  # Muspel Gate: a gate of fire
        for y in range(4, GROUND):
            for x in (50, 106):
                rect(im, x, y, x + 6, y + 1, "#3e2731")
        for x in range(56, 106):
            for y in range(10, GROUND):
                if rng.random() < 0.3:
                    dot(im, x, y, rng.choice(["#f77622", "#feae34", "#e43b44"]))
        glow(im, 80, 40, 50, "#e43b44", 25)
    return im


def shadow_area(sub, rng):
    im = shadow(rng)
    if sub == 0:  # Gloamwood Edge: dead trees in purple dusk
        for x in (10, 40, 120, 148):
            rect(im, x, 14, x + 3, GROUND, "#181425")
            line(im, x + 1, 24, x - 8, 14, "#181425")
            line(im, x + 2, 30, x + 10, 20, "#181425")
        tint(im, "#3e2a5e", 0.1)
    elif sub == 1:  # Weeping Stars: falling stars
        for _ in range(7):
            x, y = rng.randrange(20, W), rng.randrange(0, 40)
            line(im, x, y, x - 10, y + 6, "#e8b8f0")
            dot(im, x, y, "#ffffff")
    elif sub == 2:  # Mirror Hollow: floating mirror shards
        for _ in range(10):
            x, y = rng.randrange(W), rng.randrange(6, GROUND - 10)
            w, h = rng.randrange(3, 7), rng.randrange(5, 10)
            rect(im, x, y, x + w, y + h, "#8b9bb4")
            rect(im, x + 1, y + 1, x + w - 1, y + h - 1, "#c0cbdc")
            dot(im, x + 1, y + 1, "#ffffff")
    elif sub == 3:  # Void Spire: a black tower against the eye
        rect(im, 70, 6, 88, GROUND, "#0b0814")
        for k in range(10):
            rect(im, 70 + k, 6 - k // 2, 88 - k, 7 - k // 2, "#0b0814")
        for y in range(14, GROUND, 9):
            dot(im, 78, y, "#c27ad8")
            dot(im, 79, y, "#c27ad8")
    else:  # Abyssal Throne: a throne of bone and shadow
        rect(im, 64, 20, 96, GROUND, "#181425")
        rect(im, 68, 26, 92, GROUND - 14, "#2b1b45")
        rect(im, 60, 12, 66, GROUND, "#262b44")
        rect(im, 94, 12, 100, GROUND, "#262b44")
        for x in (61, 95):
            dot(im, x + 2, 10, "#c27ad8")
        glow(im, 80, 30, 30, "#9a4fc0", 20)
    return im


# ---------------------------------------------------------------- the 5 realms (floors 251-500)
def tree_silhouette(im, x, h, trunk, crown, rng, dead=False):
    rect(im, x - 1, GROUND - h, x + 2, GROUND, trunk)
    if dead:
        for k in range(4):
            y = GROUND - h + 4 + k * 5
            d = rng.choice((-1, 1))
            line(im, x, y, x + d * (6 + k), y - 5, trunk)
    else:
        for k in range(12):
            r = 8 - abs(k - 5)
            rect(im, x - r, GROUND - h + k * 2 - 6, x + r + 1, GROUND - h + k * 2 - 4, crown)


def hushwood(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0c1418", "#14262a", "#1e3a38", "#2a4a44"])
    for i in range(12):
        tree_silhouette(im, i * 14 + rng.randrange(-3, 4), rng.randrange(34, 56), "#142422", "#182c2a", rng, dead=True)
    for i in range(8):
        tree_silhouette(im, i * 22 + rng.randrange(-4, 4), rng.randrange(40, 62), "#22302c", "#22302c", rng, dead=True)
    # mist bands
    for y0 in (40, 52, 60):
        for y in range(y0, y0 + 3):
            for x in range(W):
                if (x + y * 3) % 4 != 0:
                    c = im.getpixel((x, y))
                    dot(im, x, y, tuple(min(255, v + 22) for v in c))
    # grief wisps
    for _ in range(10):
        x, y = rng.randrange(W), rng.randrange(14, GROUND - 6)
        dot(im, x, y, "#c8f2ee")
        glow(im, x, y, 3, "#9fd8c4", 30)
    ground(im, "#3e5a4a", "#22302c", "#16201e", "#5b8a72", rng)
    return im


def glimmer(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#1a0e2e", "#3a1e4e", "#68386c", "#8a4a7a"])
    # giant mushrooms
    for x, h, c in ((14, 40, "#e43b44"), (60, 26, "#c27ad8"), (118, 46, "#e43b44"), (150, 22, "#f6a6c8")):
        rect(im, x - 2, GROUND - h, x + 3, GROUND, "#ead4aa")
        for k in range(7):
            r = 4 + k * 2
            rect(im, x - r, GROUND - h - 7 + k, x + r + 1, GROUND - h - 6 + k, c)
        for s in range(4):
            dot(im, x - 6 + s * 4, GROUND - h - 4, "#fbf3dc")
    # sparkles
    for _ in range(40):
        dot(im, rng.randrange(W), rng.randrange(GROUND - 4), rng.choice(["#fee761", "#ffc6de", "#c8f2ee"]))
    # moon
    for y in range(6, 20):
        for x in range(72, 90):
            if math.hypot(x - 81, y - 13) < 7:
                dot(im, x, y, "#fbf3dc")
    glow(im, 81, 13, 16, "#fbf3dc", 18)
    ground(im, "#75a743", "#3e5a2e", "#2a3e22", "#f6a6c8", rng)
    for _ in range(30):
        dot(im, rng.randrange(W), GROUND - 1, rng.choice(["#f6a6c8", "#fee761", "#75a743"]))
    return im


def ironroot(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#120c0c", "#2a1a14", "#3e2618", "#5a3420"])
    # stone pillars with runes
    for x in (8, 46, 104, 142):
        rect(im, x, 4, x + 12, GROUND, "#3a3038")
        rect(im, x + 1, 4, x + 3, GROUND, "#4a3e46")
        for y in range(10, GROUND - 4, 12):
            dot(im, x + 6, y, "#7fe9ff")
            dot(im, x + 6, y + 1, "#7fe9ff")
            dot(im, x + 5, y + 2, "#7fe9ff")
    # forge glow and chains
    glow(im, 80, GROUND - 6, 40, "#f77622", 30)
    for x in (66, 94):
        for y in range(0, 30, 2):
            dot(im, x, y, "#8b9bb4")
    rect(im, 70, GROUND - 14, 90, GROUND - 10, "#5a6988")
    rect(im, 74, GROUND - 10, 86, GROUND, "#3a4466")
    # sparks
    for _ in range(30):
        dot(im, rng.randrange(40, 120), rng.randrange(20, GROUND), rng.choice(["#feae34", "#fee761"]))
    ground(im, "#8a6a50", "#4a3a2a", "#2e2016", "#feae34", rng)
    return im


def spire(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#4f8fba", "#7fb2e0", "#c8f2ee", "#fbf3dc"])
    # clouds
    for _ in range(9):
        x, y = rng.randrange(-10, W), rng.randrange(10, GROUND - 10)
        for k in range(5):
            rect(im, x + k * 3, y - k % 2, x + k * 3 + 10, y + 4, "#ffffff")
    # golden spire in the distance
    rect(im, 76, 2, 84, GROUND, "#e8b14a")
    rect(im, 77, 2, 79, GROUND, "#fee761")
    for k in range(8):
        rect(im, 76 + k // 2, 2 - k, 84 - k // 2, 3 - k, "#e8b14a")
    glow(im, 80, 10, 22, "#fee761", 25)
    # columns
    for x in (10, 34, 124, 148):
        rect(im, x, 18, x + 6, GROUND, "#eef2f8")
        rect(im, x - 1, 16, x + 7, 18, "#dfe6f0")
        rect(im, x + 4, 18, x + 6, GROUND, "#c0cbdc")
    ground(im, "#fff4a3", "#e8d4a0", "#c8b08a", "#ffffff", rng)
    return im


def abyss(rng):
    im = Image.new("RGB", (W, H))
    gradient(im, 0, GROUND, ["#0e0610", "#2a0e1a", "#5a1424", "#8e2e38"])
    # spires of obsidian
    for i in range(9):
        x = i * 19 + rng.randrange(-3, 3)
        h = rng.randrange(24, 54)
        for k in range(h):
            w = max(1, (h - k) // 6)
            rect(im, x - w, GROUND - k, x + w + 1, GROUND - k + 1, "#1e1418")
    # chains hanging
    for x in (30, 92, 136):
        for y in range(0, rng.randrange(20, 40), 2):
            dot(im, x, y, "#5a6988")
    # lava glow from below
    glow(im, 80, GROUND + 6, 70, "#e43b44", 22)
    for _ in range(40):
        dot(im, rng.randrange(W), rng.randrange(GROUND), rng.choice(["#f77622", "#be4a2f"]))
    ground(im, "#be4a2f", "#3e1a20", "#24101a", "#f77622", rng)
    return im


def hushwood_area(sub, rng):
    im = hushwood(rng)
    if sub == 0:  # Ashen Glade: grey ash falling
        for _ in range(80):
            dot(im, rng.randrange(W), rng.randrange(GROUND), "#8b9bb4")
        tint(im, "#5a6370", 0.15)
    elif sub == 1:  # Silent Boughs: big owl eyes in the dark
        for x, y in ((24, 20), (130, 26), (96, 14)):
            dot(im, x, y, "#fee761")
            dot(im, x + 3, y, "#fee761")
        tint(im, "#060a10", 0.3)
    elif sub == 2:  # Lantern Graves: grave stones with lanterns
        for x in range(12, W, 26):
            rect(im, x, GROUND - 9, x + 6, GROUND, "#5a6370")
            rect(im, x + 1, GROUND - 11, x + 5, GROUND - 9, "#5a6370")
            dot(im, x + 3, GROUND - 14, "#fee761")
            glow(im, x + 3, GROUND - 14, 7, "#feae34", 30)
    elif sub == 3:  # Rootless Hall: purple rot and mushrooms
        tint(im, "#3a1e4e", 0.2)
        for _ in range(14):
            x = rng.randrange(W)
            rect(im, x, GROUND - 3, x + 3, GROUND, "#8a5a9a")
            rect(im, x - 1, GROUND - 4, x + 4, GROUND - 3, "#c27ad8")
    else:  # The Withered Heart: a huge dead tree with a red heart
        rect(im, 70, 0, 92, GROUND, "#1a1410")
        rect(im, 74, 0, 78, GROUND, "#2a2016")
        rect(im, 78, 30, 84, 38, "#a22633")
        glow(im, 81, 34, 24, "#e43b44", 30)
    return im


def glimmer_area(sub, rng):
    im = glimmer(rng)
    if sub == 0:  # Moonpetal Fields: white flowers everywhere
        for _ in range(70):
            dot(im, rng.randrange(W), rng.randrange(GROUND - 6, GROUND), "#fbf3dc")
    elif sub == 1:  # The Mirror Pond: a still pond reflecting the moon
        rect(im, 30, GROUND + 4, 130, GROUND + 14, "#4fb0c6")
        rect(im, 34, GROUND + 6, 126, GROUND + 12, "#73bed3")
        for x in range(76, 86):
            dot(im, x, GROUND + 8, "#fbf3dc")
    elif sub == 2:  # Mushroom Hollow: a ring of tiny toadstools
        for k in range(16):
            a = k * math.pi / 8
            x, y = 80 + int(math.cos(a) * 40), GROUND + 6 + int(math.sin(a) * 6)
            rect(im, x, y - 2, x + 3, y, "#e43b44")
            dot(im, x + 1, y, "#ead4aa")
    elif sub == 3:  # Thorn Labyrinth: walls of thorny hedge
        for x in range(0, W, 30):
            rect(im, x, 24, x + 14, GROUND, "#2a4a22")
            for y in range(24, GROUND, 3):
                dot(im, x + rng.randrange(14), y, "#75a743")
                dot(im, x + rng.randrange(14), y, "#3e2a1e")
    else:  # The Queen's Bower: golden light and a throne of flowers
        tint(im, "#e8b14a", 0.12)
        rect(im, 68, 26, 92, GROUND, "#c27ad8")
        rect(im, 72, 30, 88, GROUND - 10, "#f6a6c8")
        glow(im, 80, 30, 34, "#fee761", 28)
    return im


def ironroot_area(sub, rng):
    im = ironroot(rng)
    if sub == 0:  # Slag Gate: heaps of slag
        for x in range(0, W, 22):
            for k in range(8):
                rect(im, x + k, GROUND - 8 + k, x + 16 - k, GROUND - 7 + k, "#2a2220")
    elif sub == 1:  # The Rune Halls: glowing runes everywhere
        for _ in range(26):
            x, y = rng.randrange(W), rng.randrange(6, GROUND - 6)
            dot(im, x, y, "#7fe9ff")
            dot(im, x + 1, y + 1, "#7fe9ff")
        tint(im, "#1d4a66", 0.12)
    elif sub == 2:  # The Great Anvil: a huge anvil and a forge
        rect(im, 54, GROUND - 22, 106, GROUND - 14, "#5a6988")
        rect(im, 66, GROUND - 14, 94, GROUND, "#3a4466")
        glow(im, 80, GROUND - 26, 30, "#fee761", 30)
    elif sub == 3:  # The Gem Vaults: gems in the walls
        for _ in range(40):
            dot(im, rng.randrange(W), rng.randrange(GROUND), rng.choice(["#c27ad8", "#73bed3", "#e43b44", "#fee761"]))
    else:  # Throne of Stone: a stone throne with gold
        rect(im, 64, 18, 96, GROUND, "#3a3038")
        rect(im, 70, 26, 90, GROUND - 12, "#5a4a3e")
        for x in range(64, 97, 4):
            dot(im, x, 17, "#e8b14a")
        glow(im, 80, 20, 26, "#e8b14a", 22)
    return im


def spire_area(sub, rng):
    im = spire(rng)
    if sub == 0:  # The Cloudstair: steps of cloud
        for i in range(7):
            rect(im, i * 12, GROUND - 4 - i * 4, i * 12 + 40, GROUND - i * 4, "#ffffff")
    elif sub == 1:  # Choir Gardens: white flowers and hedges
        for x in range(0, W, 20):
            rect(im, x, GROUND - 10, x + 14, GROUND, "#75a743")
            for _ in range(4):
                dot(im, x + rng.randrange(14), GROUND - rng.randrange(1, 10), "#ffffff")
    elif sub == 2:  # Halls of Judgement: a giant set of scales
        line(im, 50, 20, 110, 20, "#e8b14a", 2)
        rect(im, 79, 10, 81, GROUND, "#e8b14a")
        for x in (50, 110):
            line(im, x, 20, x - 6, 34, "#e8b14a")
            line(im, x, 20, x + 6, 34, "#e8b14a")
            rect(im, x - 8, 34, x + 9, 36, "#e8b14a")
    elif sub == 3:  # The Sunforge: blinding light
        glow(im, 80, 40, 70, "#fee761", 40)
        tint(im, "#fee761", 0.15)
    else:  # The Empyrean Gate: a great golden gate
        for x in (50, 104):
            rect(im, x, 6, x + 8, GROUND, "#e8b14a")
        for y in range(6, GROUND, 8):
            rect(im, 58, y, 104, y + 2, "#feae34")
        glow(im, 81, 30, 30, "#ffffff", 30)
    return im


def abyss_area(sub, rng):
    im = abyss(rng)
    if sub == 0:  # Brimstone Wastes: smoke
        for _ in range(60):
            x, y = rng.randrange(W), rng.randrange(GROUND)
            dot(im, x, y, "#5a4a3e")
        tint(im, "#3e2731", 0.2)
    elif sub == 1:  # The Chain Bridges: bridges of chain over the pit
        for y in (30, 46):
            for x in range(0, W, 2):
                dot(im, x, y + int(math.sin(x / 12.0) * 3), "#8b9bb4")
    elif sub == 2:  # The Soul Market: stalls with glowing souls
        for x in range(10, W, 36):
            rect(im, x, GROUND - 14, x + 20, GROUND - 12, "#68386c")
            rect(im, x + 1, GROUND - 12, x + 3, GROUND, "#3e2731")
            rect(im, x + 17, GROUND - 12, x + 19, GROUND, "#3e2731")
            dot(im, x + 10, GROUND - 6, "#7fe9ff")
            glow(im, x + 10, GROUND - 6, 6, "#7fe9ff", 30)
    elif sub == 3:  # Obsidian Citadel: black walls and red windows
        rect(im, 30, 10, 130, GROUND, "#120a10")
        for x in range(36, 128, 12):
            rect(im, x, 20, x + 4, 28, "#e43b44")
    else:  # The Throne Pit: a throne in fire
        rect(im, 64, 16, 96, GROUND, "#1e1418")
        rect(im, 70, 24, 90, GROUND - 12, "#5a1424")
        for x in (64, 94):
            line(im, x, 16, x - 4 if x == 64 else x + 6, 4, "#1e1418", 2)
        glow(im, 80, 30, 36, "#f77622", 30)
    return im


def hd(im):
    """Scale2x: twice the size with smoothed diagonals and no new colors, so the
    backgrounds match the HD sprites (320x180)."""
    w, h = im.size
    src = im.load()
    out = Image.new(im.mode, (w * 2, h * 2))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            p = src[x, y]
            a = src[x, max(y - 1, 0)]
            b = src[min(x + 1, w - 1), y]
            c = src[max(x - 1, 0), y]
            d = src[x, min(y + 1, h - 1)]
            e0 = e1 = e2 = e3 = p
            if a != d and c != b:
                if c == a:
                    e0 = a
                if a == b:
                    e1 = b
                if c == d:
                    e2 = c
                if d == b:
                    e3 = d
            dst[2 * x, 2 * y] = e0
            dst[2 * x + 1, 2 * y] = e1
            dst[2 * x, 2 * y + 1] = e2
            dst[2 * x + 1, 2 * y + 1] = e3
    return out


AREAS = [mossy_area, catacombs_area, depths_area, ember_area, shadow_area,
         hushwood_area, glimmer_area, ironroot_area, spire_area, abyss_area]


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for i, fn in enumerate((mossy, catacombs, depths, ember, shadow, hushwood, glimmer, ironroot, spire, abyss)):
        hd(fn(random.Random(i * 7 + 1))).save(os.path.join(OUT, "zone_%d.png" % i))
    for zi, fn in enumerate(AREAS):
        for sub in range(5):
            hd(fn(sub, random.Random(zi * 7 + 1))).save(os.path.join(OUT, "zone_%d_%d.png" % (zi, sub)))
    print("backgrounds done")
