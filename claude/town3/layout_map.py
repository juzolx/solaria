"""Labeled block-out of layout.py in the town's isometric view (no art). Usage: py layout_map.py <out.png>"""
import sys
from PIL import Image, ImageDraw, ImageFont
from layout import MARKET, N, GROUND, TOWERS, GATEHOUSE, LOTS, HOUSES, POINTS, TREE_BELTS, WALL_H, TOWER_H

HW, HH = 16, 8
W, H = N * 2 * HW + 80, N * 2 * HH + 160
OX, OY = W // 2, 70
COL = {"grass": "#3d5236", "plateau": "#6b6258", "grave": "#4a4a52", "yard": "#5a6a3c", "road": "#8a8172",
       "square": "#a39782", "water": "#3b6c9a", "bridge": "#b5a890", "field": "#7a6a3a", "pen": "#6f7d45", "dirt": "#6e5a40", "path": "#8a8172", "garden": "#4f6a3a", "planks": "#7a5a3a"}
FONT = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 15)


def at(i, j, h=0):
    return OX + (i - j) * HW, OY + (i + j) * HH - h


def flat(d, x0, y0, x1, y1, col):
    d.polygon([at(x0, y0), at(x1 + 1, y0), at(x1 + 1, y1 + 1), at(x0, y1 + 1)], fill=col)


def shade(col, k):
    c = tuple(int(col[n:n + 2], 16) for n in (1, 3, 5))
    return tuple(max(0, min(255, int(v * k))) for v in c)


def box(d, x0, y0, x1, y1, h, col, door=None):
    a, b, c, e = (x0, y0), (x1 + 1, y0), (x1 + 1, y1 + 1), (x0, y1 + 1)
    d.polygon([at(*b), at(*c), at(*c, h), at(*b, h)], fill=shade(col, .75), outline="#0e0812")  # +i face
    d.polygon([at(*e), at(*c), at(*c, h), at(*e, h)], fill=shade(col, .55), outline="#0e0812")  # +j face
    d.polygon([at(*a, h), at(*b, h), at(*c, h), at(*e, h)], fill=shade(col, 1), outline="#0e0812")
    if door == "i":
        m = (y0 + y1 + 1) / 2
        d.polygon([at(x1 + 1, m - .5), at(x1 + 1, m + .5), at(x1 + 1, m + .5, 11), at(x1 + 1, m - .5, 11)], fill="#ffcf5a")
    elif door == "j":
        m = (x0 + x1 + 1) / 2
        d.polygon([at(m - .5, y1 + 1), at(m + .5, y1 + 1), at(m + .5, y1 + 1, 11), at(m - .5, y1 + 1, 11)], fill="#ffcf5a")


def label(d, xy, text, fill="white"):
    d.text(xy, text, font=FONT, fill=fill, anchor="mm", stroke_width=3, stroke_fill="#0e0812")


def main(out):
    img = Image.new("RGB", (W, H), "#1a1726")
    d = ImageDraw.Draw(img)
    for k, x0, y0, x1, y1 in GROUND:
        flat(d, x0, y0, x1, y1, COL[k])
    for x0, y0, x1, y1 in TREE_BELTS:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                x, y = at(i + .5, j + .5)
                d.ellipse([x - 7, y - 12, x + 7, y + 2], fill="#24361f", outline="#0e0812")
    boxes = []
    for n in range(N):  # wall ring, one block per cell
        for c in {(n, 0), (0, n), (n, N - 1), (N - 1, n)}:
            boxes.append((c[0], c[1], c[0], c[1], WALL_H, "#7d8590", None, None))
    gx0, gy0, gx1, gy1 = GATEHOUSE
    boxes = [b for b in boxes if not (gx0 <= b[0] <= gx1 and gy0 <= b[1] <= gy1)]
    boxes.append((gx0, gy0, gx1, gy1, TOWER_H - 4, "#8f96a0", "j", "Sealed Gatehouse"))
    for tx, ty in TOWERS:
        boxes.append((tx, ty, tx + 2, ty + 2, TOWER_H, "#8f96a0", None, None))
    for lid, name, x0, y0, x1, y1, door, h in LOTS:
        col = "#d9a441" if lid == "gate" else ("#6e6e78" if "lot" in name else "#b0764a")
        boxes.append((x0, y0, x1, y1, h, col, door, name))
    for x0, y0, x1, y1, door in HOUSES:
        boxes.append((x0, y0, x1, y1, 14, "#7a5a44", door, "house" if door else "barn"))
    boxes.sort(key=lambda b: b[2] + b[3])
    for x0, y0, x1, y1, h, col, door, _ in boxes:
        box(d, x0, y0, x1, y1, h, col, door)
    for x0, y0, x1, y1, h, col, door, name in boxes:
        if name and name not in ("house", "barn"):
            x, y = at((x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2, h)
            label(d, (x, y - 4), name, "#ffe08a" if name == "Dungeon" else "white")
    for pid, name, i, j in POINTS:
        x, y = at(i + .5, j + .5)
        d.rectangle([x - 4, y - 10, x + 4, y], fill="#e0c070", outline="#0e0812")
        label(d, (x, y - 18), name, "#cfe6ff")
    _, mname, mx0, my0, mx1, my1 = MARKET
    pts = [at(mx0, my0), at(mx1 + 1, my0), at(mx1 + 1, my1 + 1), at(mx0, my1 + 1)]
    d.line(pts + [pts[0]], fill="#ffcf5a", width=3)
    label(d, at((mx0 + mx1 + 1) / 2, (my0 + my1 + 1) / 2), "MARKET (well + stalls + square)", "#ffe08a")
    x, y = at(19.5, 19.5)
    d.ellipse([x - 6, y - 4, x + 6, y + 4], fill="#7aa0c0", outline="#0e0812")
    for name, i, j in [("Main street", 19.5, 31), ("River", 34, 27.5),
                       ("Stone bridge", 23.5, 28.5), ("Garden / Graveyard (Hardcore)", 6, 3.5), ("Pet pen", 30, 31), ("Orchard", 36, 14), ("Plots", 13, 31),
                       ("Fields", 2.5, 32), ("Training yard", 36, 4)]:
        label(d, at(i, j), name, "#b8f0b0")
    label(d, (W // 2, 24), "Solaria town layout v3 - blocks only, no art. Yellow tick = door. Dungeon on the raised plateau (lit focal point).")
    label(d, (W // 2, H - 40), "Hardcore towns: Church dark/abandoned, graveyard grows. Regular: Church lit. Church + Trophy Cabin start as empty lots.")
    img.save(out)


if __name__ == "__main__":
    main(sys.argv[1])
