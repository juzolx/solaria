"""Hardcore church = the Regular church abandoned: windows dark, stone colder and darker, the
spire snapped off with a jagged break, a few holes in the roof. Usage: py prep_ruin.py"""
import random
from PIL import Image, ImageEnhance, ImageDraw
rng = random.Random(3)
im = Image.open("art/church.png").convert("RGBA")
px = im.load()
w, h = im.size
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a and r > 150 and g > 100 and b < 120 and r - b > 70:      # lit glass / candles -> dead glass
            px[x, y] = (28, 30, 40, a) if (x + y) % 3 else (44, 48, 60, a)
for y in range(h):                                                     # the white saint goes grey and mossy
    for x in range(w):
        r, g, b, a = px[x, y]
        if a and min(r, g, b) > 150 and max(r, g, b) - min(r, g, b) < 40:
            px[x, y] = (70, 78, 66, a) if (x + y) % 4 == 0 else (88, 90, 92, a)
rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.45)
rgb = ImageEnhance.Brightness(rgb).enhance(1.0)
im = Image.merge("RGBA", (*rgb.split(), im.getchannel("A")))
px = im.load()
bb = im.getbbox()
cut = bb[1] + 88                                                       # snap the spire
for x in range(w):
    edge = cut + rng.randint(-4, 6)
    for y in range(0, min(edge, h)):
        px[x, y] = (0, 0, 0, 0)
d = ImageDraw.Draw(im)
for x in range(w):                                                     # dark outline along the break
    for y in range(cut - 6, cut + 10):
        if 0 <= y < h - 1 and px[x, y][3] == 0 and px[x, y + 1][3] > 0:
            px[x, y + 1] = (14, 8, 18, 255)
for _ in range(5):                                                     # roof holes
    x, y = rng.randint(120, 175), rng.randint(95, 150)
    if px[x, y][3]:
        d.polygon([(x, y), (x + 5, y + 2), (x + 3, y + 6), (x - 2, y + 4)], fill=(10, 8, 14, 255))
# boards nailed across every window and the rose window (the lit glass regions of the Regular church)
src = Image.open("art/church.png").convert("RGBA")
sp = src.load()
warm = {(x, y) for y in range(h) for x in range(w) if sp[x, y][3] and sp[x, y][0] > 150 and sp[x, y][1] > 100 and sp[x, y][2] < 120 and sp[x, y][0] - sp[x, y][2] > 70}
seen = set()
for start in sorted(warm):
    if start in seen:
        continue
    comp, stack = [], [start]
    seen.add(start)
    while stack:
        cx, cy = stack.pop()
        comp.append((cx, cy))
        for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
            if n in warm and n not in seen:
                seen.add(n)
                stack.append(n)
    if len(comp) < 12:
        continue
    xs, ys = [c[0] for c in comp], [c[1] for c in comp]
    x0, x1, y0, y1 = min(xs) - 1, max(xs) + 1, min(ys), max(ys)
    if y1 < cut:
        continue
    for k, yy in enumerate(range(y0 + 2, y1, 5)):                    # planks, slightly askew
        d.line([(x0, yy + (k % 2)), (x1, yy + 1 - (k % 2))], fill=(14, 8, 18, 255), width=3)
        d.line([(x0, yy + (k % 2)), (x1, yy + 1 - (k % 2))], fill=(92, 66, 44, 255), width=1)
for _ in range(9):                                                     # more roof holes
    x, y = rng.randint(110, 185), rng.randint(cut + 10, 165)
    if px[x, y][3]:
        d.polygon([(x, y), (x + 7, y + 3), (x + 4, y + 8), (x - 3, y + 5)], fill=(10, 8, 14, 255))
        d.line([(x - 1, y + 2), (x + 6, y + 5)], fill=(70, 52, 38, 255))   # a broken rafter
# Fable r2: a real ruin. (File coords; the game shows the church flipped, so the file's right
# tower face is the left face on screen.)
rng2 = random.Random(11)
# the near nave roof caved in: a ragged hole with the dark interior and three bare rafters
cx, cy = 146, 132
U, V = (17, -8), (5, 9)   # along the ridge / down the slope (file coords)
hole = [(cx + a * U[0] + b * V[0] + rng2.randint(-2, 2), cy + a * U[1] + b * V[1] + rng2.randint(-2, 2))
        for a, b in ((-1, -1), (0, -1.2), (1, -1), (1.15, 0), (1, 1), (0, 1.2), (-1, 1), (-1.15, 0))]
mask = Image.new("L", im.size, 0)
ImageDraw.Draw(mask).polygon(hole, fill=255)
mp = mask.load()
for y in range(h):
    for x in range(w):
        if mp[x, y] and px[x, y][3]:
            px[x, y] = (12, 10, 16, 255) if (x * 3 + y) % 7 else (24, 20, 28, 255)
for y in range(1, h - 1):            # broken slate round the edge
    for x in range(1, w - 1):
        if not mp[x, y] and px[x, y][3] and any(mp[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            px[x, y] = (96, 98, 104, 255) if rng2.random() < .5 else (58, 60, 68, 255)
for a in (-0.55, 0.0, 0.55):         # three rafters across the hole
    p0 = (cx + a * U[0] - 1.1 * V[0], cy + a * U[1] - 1.1 * V[1])
    p1 = (cx + a * U[0] + 1.1 * V[0], cy + a * U[1] + 1.1 * V[1])
    d.line([(p0[0] + 1, p0[1]), (p1[0] + 1, p1[1])], fill=(30, 20, 14, 255), width=1)
    d.line([p0, p1], fill=(110, 80, 52, 255), width=1)
# one side of the tower fell further: a slanting break, not a flat crenellated top
tx0, tx1 = 40, 114
for x in range(tx0, tx1):
    edge = cut + int((x - tx0) * 26 / (tx1 - tx0)) + rng2.randint(-2, 2)
    for y in range(0, min(edge, h)):
        px[x, y] = (0, 0, 0, 0)
    if edge < h and px[x, edge][3]:
        px[x, edge] = (14, 8, 18, 255)
        if edge + 1 < h and px[x, edge + 1][3]:
            px[x, edge + 1] = (118, 116, 122, 255) if rng2.random() < .4 else px[x, edge + 1]
# ivy up the tower's (on-screen) left face
for vx in (84, 90, 97, 103, 108):
    top = rng2.randint(118, 170)
    x = vx
    for y in range(232, top, -1):
        x += rng2.choice((-1, 0, 0, 1)) if rng2.random() < .3 else 0
        for dx in ((0,) if rng2.random() < .6 else (-1, 0, 1)):
            q = px[x + dx, y]
            if q[3] and not (q[0] > 150 and q[2] < 120):
                px[x + dx, y] = (40, 66, 38, 255) if (x + y) % 3 else (64, 96, 52, 255)
# a heap of fallen blocks at the tower's foot
for _ in range(22):
    bx, by = rng2.randint(96, 120), rng2.randint(238, 250)
    bw, bh = rng2.randint(3, 6), rng2.randint(2, 4)
    shade = rng2.choice(((92, 94, 100), (74, 76, 84), (110, 110, 116)))
    d.rectangle([bx - 1, by - 1, bx + bw, by + bh], fill=(16, 12, 20, 255))
    d.rectangle([bx, by, bx + bw - 1, by + bh - 1], fill=shade + (255,))
    d.line([bx, by, bx + bw - 1, by], fill=tuple(min(255, c + 30) for c in shade) + (255,))
# two crows on the broken tower top
for cxw in (58, 92):
    ty = next(y for y in range(h) if px[cxw, y][3])
    for dx, dy in ((1, -4), (2, -4), (0, -3), (1, -3), (2, -3), (3, -3), (1, -2), (2, -2), (3, -2), (4, -2), (1, -1), (3, -1)):
        px[cxw + dx, ty + dy] = (8, 8, 12, 255)
    px[cxw - 1, ty - 3] = (90, 84, 70, 255)
# the fallen cross in the forecourt, lying in the weeds
cross = [(20 + k, 248 + k // 2) for k in range(18)] + [(25 + j, 244 + 2 * j // 3 + i) for i in range(0, 1) for j in range(-3, 9)][:0] + [(26 - k // 2, 245 + k) for k in range(8)]
for x, y in cross:
    for dx, dy in ((0, 2), (1, 2), (-1, 0), (0, -1)):
        if not px[x + dx, y + dy][3]:
            px[x + dx, y + dy] = (16, 12, 20, 255)
for x, y in cross:
    px[x, y] = (150, 150, 158, 255)
    px[x, y + 1] = (104, 104, 112, 255)
im.save("art/church_ruin.png")
