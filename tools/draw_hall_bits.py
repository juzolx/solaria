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
print("hall bits drawn")
