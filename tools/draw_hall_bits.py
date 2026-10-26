import math
import os
import random
import sys
from PIL import Image
# tools/draw_hall_bits.py <repo> : small pixel pieces for the 3D rooms, drawn in palette colours
# (art/palette.gpl) with hard alpha and the #0e0812 outline:
#   art/halls/rift_0..2.png  48x64 rift (3-frame swirl, the "scale" violet ramp)
#   art/fx/glow.png          32x16 floor glow, 3 hard alpha steps (tinted per use in code)
#   art/fx/shadow.png        32x8 dithered drop shadow, 2 steps
#   art/halls/z0_root.png    16x48 hanging root (Mossy Hollows)
#   art/halls/z3_crack.png   32x8 glowing floor seam (Ember Halls)
#   art/halls/z4_eye.png     32x16 carved eye over the middle door (Shadow Deep)
#   art/halls/z5_wisp.png    16x16 pale ghost wisp, the Hushwood's "torch"
#   art/halls/z6_crystal.png 16x24 crystal shard (Glimmer Court)
#   art/halls/z9_spikes.png  32x16 row of iron spikes (Cinder Abyss)
#   art/halls/z5_floor.png   32x32 leaf-littered flagstones (Hushwood floor, tiles)
#   art/halls/z2_pool_0..1   64x32 dark pool with a rippling rim, two frames (Flooded Vaults)
#   art/halls/z7_pipe.png    16x16 brass pipe, tiles along its length (Clockwork Depths)
#   art/halls/z8_pillar.png  16x64 gilded pillar, tiles up (Gilded Spire)
# and gives z5_wall / z6_floor a top light and bottom shade on their main stone (>= 5 colours).
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
OUT = (0x0e, 0x08, 0x12, 255)


def hexc(h, a=255):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), a)


def outline(img):
    # every see-through pixel touching a solid one becomes the outline (keeps the art's own size)
    px = img.load()
    w, h = img.size
    edge = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] == 255 and px[x + dx, y + dy] != OUT
                                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                edge.append((x, y))
    for x, y in edge:
        px[x, y] = OUT
    return img


def save(img, *path):
    p = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)


# --- rift: an oval of swirling violet, three frames ---
RAMP = [hexc("#181425"), hexc("#68386c"), hexc("#9a4fc0"), hexc("#c27ad8"), hexc("#e8b8f0")]
for f in range(3):
    img = Image.new("RGBA", (48, 64))
    px = img.load()
    for y in range(64):
        for x in range(48):
            dx, dy = (x - 23.5) / 21.0, (y - 31.5) / 29.0
            r = math.hypot(dx, dy)
            if r >= 1.0:
                continue
            a = math.atan2(dy, dx)
            s = math.sin(3 * a + 7.0 * r - f * 2.0944)
            if r > 0.86:
                k = 4
            elif r < 0.16:
                k = 4
            elif r < 0.3:
                k = 3
            else:
                k = 1 + (s > -0.2) + (s > 0.55)
            px[x, y] = RAMP[k]
    save(outline(img), "art", "halls", "rift_%d.png" % f)

# --- glow and shadow (fx: palette colours, alpha steps 64/128/192) ---
img = Image.new("RGBA", (32, 16))
px = img.load()
for y in range(16):
    for x in range(32):
        d = math.hypot((x - 15.5) / 16.0, (y - 7.5) / 8.0)
        if d < 1.0:
            step = 192 if d < 0.4 else (128 if d < 0.7 else 64)
            if step == 64 and (x + y) % 2:
                continue  # dither the outer step
            px[x, y] = hexc("#ffffff", step)
save(img, "art", "fx", "glow.png")
img = Image.new("RGBA", (32, 8))
px = img.load()
for y in range(8):
    for x in range(32):
        d = math.hypot((x - 15.5) / 16.0, (y - 3.5) / 4.0)
        if d < 1.0:
            if d > 0.65 and (x + y) % 2:
                continue
            px[x, y] = hexc("#181425", 192 if d < 0.65 else 128)
save(img, "art", "fx", "shadow.png")

# --- a hanging root ---
rng = random.Random(3)
BROWN = [hexc("#3e2731"), hexc("#5a3f35"), hexc("#8f563b")]
img = Image.new("RGBA", (16, 48))
px = img.load()
x = 7.0
for y in range(46):
    w = max(1, round(3.2 - y / 18.0))
    x += math.sin(y / 5.0) * 0.45
    for k in range(w):
        px[int(x) + k - w // 2, y] = BROWN[2] if k == 0 else BROWN[1 if k < w - 1 else 0]
    if y in (10, 22, 31):  # rootlets
        side = 1 if y != 22 else -1
        for j in range(5 - (y > 25) * 2):
            px[max(0, min(15, int(x) + side * (2 + j))), y + j] = BROWN[1]
save(outline(img), "art", "halls", "z0_root.png")

# --- Ember Halls: a glowing seam ---
img = Image.new("RGBA", (32, 8))
px = img.load()
y = 4.0
for x in range(1, 31):
    y += rng.choice((-1, 0, 0, 1)) * 0.6
    yy = max(1, min(6, round(y)))
    px[x, yy] = hexc("#feae34")
    for d in (-1, 1):
        if px[x, yy + d][3] == 0:
            px[x, yy + d] = hexc("#e43b44")
save(img, "art", "halls", "z3_crack.png")

# --- Shadow Deep: a carved eye ---
img = Image.new("RGBA", (32, 16))
px = img.load()
for y in range(16):
    for x in range(32):
        dx, dy = (x - 15.5) / 15.0, (y - 7.5) / 7.0
        lid = abs(dy) <= (1.0 - dx * dx) * 1.0
        if lid and abs(dx) < 1.0:
            iris = math.hypot((x - 15.5) / 5.0, (y - 7.5) / 5.0)
            px[x, y] = hexc("#e8b8f0") if iris < 0.45 else hexc("#c27ad8") if iris < 1.0 else hexc("#3a4466")
save(outline(img), "art", "halls", "z4_eye.png")

# --- Hushwood: a pale wisp ---
img = Image.new("RGBA", (16, 16))
px = img.load()
for y in range(16):
    for x in range(16):
        d = math.hypot((x - 7.5) / 5.0, (y - 9.0) / 5.0)
        tail = abs(x - 7.5 - math.sin(y / 2.5) * 1.5) < (8 - y) / 4.0 and y < 8
        if d < 1.0 or tail:
            px[x, y] = hexc("#ffffff") if d < 0.45 else hexc("#d0dcc8") if d < 0.8 else hexc("#a8b89a")
save(outline(img), "art", "halls", "z5_wisp.png")

# --- Glimmer Court: a crystal shard cluster ---
img = Image.new("RGBA", (16, 24))
px = img.load()
for cx, top, half in ((8, 1, 3), (4, 9, 2), (12, 7, 2)):
    for y in range(top, 23):
        w = min(half, (y - top) // 2 + 1)
        for x in range(cx - w, cx + w + 1):
            px[x, y] = hexc("#e8b8f0") if x == cx - w else hexc("#c27ad8") if x <= cx else hexc("#68386c")
save(outline(img), "art", "halls", "z6_crystal.png")

# --- Cinder Abyss: a row of spikes ---
img = Image.new("RGBA", (32, 16))
px = img.load()
for cx in (4, 12, 20, 28):
    for y in range(2, 15):
        w = (y - 2) // 4
        for x in range(cx - w, cx + w + 1):
            px[x, y] = hexc("#a3825f") if x < cx else hexc("#733e39")
    px[cx, 2] = hexc("#e43b44")
save(outline(img), "art", "halls", "z9_spikes.png")

# --- Hushwood floor: flagstones with moss and pale leaves (tiles: stones wrap at the edges) ---
rng = random.Random(55)
img = Image.new("RGBA", (32, 32), hexc("#1f1d24"))
px = img.load()
stones = [(0, 0, 14, 9), (15, 0, 16, 12), (0, 10, 9, 12), (10, 10, 12, 9), (23, 13, 9, 10), (0, 23, 13, 9), (14, 20, 8, 12), (23, 24, 9, 8)]
for sx, sy, sw, sh in stones:
    base = hexc("#4a4852") if rng.random() < 0.5 else hexc("#34323b")
    for yy in range(sh - 1):
        for xx in range(sw - 1):
            x, y = (sx + xx) % 32, (sy + yy) % 32
            c = base
            if yy == 0 or xx == 0:
                c = hexc("#566a56") if base == hexc("#4a4852") else hexc("#4a4852")   # lit top/left edge
            elif yy == sh - 2 or xx == sw - 2:
                c = hexc("#34323b") if base == hexc("#4a4852") else hexc("#1f1d24")   # shaded bottom/right edge
            px[x, y] = c
for i in range(14):   # moss in the cracks
    x, y = rng.randrange(32), rng.randrange(32)
    if px[x, y] == hexc("#1f1d24"):
        px[x, y] = hexc("#193c3e")
for i in range(7):    # fallen pale leaves
    x, y = rng.randrange(32), rng.randrange(32)
    px[x, y] = hexc("#d0dcc8")
    px[(x + 1) % 32, y] = hexc("#566a56")
save(img, "art", "halls", "z5_floor.png")

# --- Flooded Vaults: a dark pool with a rim that ripples (two frames) ---
for f in range(2):
    img = Image.new("RGBA", (64, 32))
    px = img.load()
    for y in range(32):
        for x in range(64):
            d = math.hypot((x - 31.5) / 31.0, (y - 15.5) / 15.0)
            if d < 1.0:
                c = hexc("#172038") if d < 0.62 else hexc("#253a5e")
                # the rim ring moves 2 px in on frame 1 (and its dashes turn), so the ripple shows
                lo = 0.80 - f * 2.0 / 31.0
                if lo <= d < lo + 0.10 and (int(math.degrees(math.atan2((y - 15.5) * 2.0, x - 31.5))) // 20 + f) % 2 == 0:
                    c = hexc("#4fb0c6")   # the rippling rim
                if 0.30 <= d < 0.38 and (x + y + f) % 7 == 0:
                    c = hexc("#3a4466")
                if y == 11 + f * 3 and 22 + f * 4 <= x < 34 + f * 4:
                    c = hexc("#c0cbdc")   # a glint on the water, one row lower each frame
                px[x, y] = c
    save(img, "art", "halls", "z2_pool_%d.png" % f)

# --- Clockwork Depths: a brass pipe (runs left-right, tiles along its length) ---
img = Image.new("RGBA", (16, 16))
px = img.load()
band = ["#0e0812", "#5a3f35", "#8f563b", "#c8a060", "#fee761", "#c8a060", "#c8a060", "#8f563b", "#8f563b", "#5a3f35", "#0e0812"]
for i, c in enumerate(band):
    for x in range(16):
        px[x, 3 + i] = hexc(c)
for y in range(3, 14):   # a collar every tile
    for x in (6, 7):
        px[x, y] = hexc("#5a3f35") if y in (3, 13) else hexc("#feae34" if y < 8 else "#8f563b")
save(img, "art", "halls", "z7_pipe.png")

# --- Gilded Spire: a gilded pillar (tiles upward) ---
img = Image.new("RGBA", (16, 64))
px = img.load()
cols = ["#0e0812", "#6a4a28", "#c8a060", "#fee761", "#c8a060", "#c8a060", "#c8a060", "#a3825f", "#a3825f", "#a3825f", "#6a4a28", "#6a4a28", "#5a3f35", "#5a3f35", "#3e2731", "#0e0812"]
for y in range(64):
    for x in range(16):
        px[x, y] = hexc(cols[x])
    if y % 16 in (0, 1):   # gold rings
        for x in range(1, 15):
            px[x, y] = hexc("#fee761" if y % 16 == 0 else "#6a4a28")
save(img, "art", "halls", "z8_pillar.png")

# --- more shades on the flattest PixelLab tiles: top light, bottom shade on the main stone ---
PAL = []
for line in open(os.path.join(ROOT, "art", "palette.gpl"), encoding="utf8"):
    parts = line.split()
    if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
        PAL.append(tuple(int(p) for p in parts[:3]) + (255,))


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def step(c, up, used):
    # the nearest palette colour clearly lighter (or darker) than c that the tile doesn't use yet
    pick = [p for p in PAL if p not in used and (lum(p) > lum(c) + 12 if up else lum(p) < lum(c) - 12)]
    return min(pick, key=lambda p: sum((p[i] - c[i]) ** 2 for i in range(3))) if pick else c


for name in ("z5_wall", "z6_floor"):
    path = os.path.join(ROOT, "art", "halls", name + ".png")
    img = Image.open(path).convert("RGBA")
    if len(img.getcolors(4096)) >= 5:
        continue   # already shaded
    px = img.load()
    w, h = img.size
    counts = {}
    for y in range(h):
        for x in range(w):
            counts[px[x, y]] = counts.get(px[x, y], 0) + 1
    main = max(counts, key=counts.get)
    hi, lo = step(main, True, counts), step(main, False, counts)
    src = img.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y] != main:
                continue
            if src[x, (y - 1) % h] != main:
                px[x, y] = hi
            elif src[x, (y + 1) % h] != main:
                px[x, y] = lo
    img.save(path)

print("hall bits drawn")
