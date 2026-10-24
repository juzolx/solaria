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
rgb = ImageEnhance.Brightness(rgb).enhance(0.86)
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
im.save("art/church_ruin.png")
