# mockup.py out.png zone_idx title monster.png [old_monster.png]
# 430x932 phone frame: tiled zone wall/floor at 3x, monster above, hero below, both 3x nearest.
import sys, os
from PIL import Image, ImageDraw, ImageFont
out, z, title, mon = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
S = 3
def tile(name):
    for root in ['C:/gamedev/solaria_wt_halls/art/halls/', 'C:/gamedev/solaria_dev/art/halls/']:
        p = root + 'z%s_%s.png' % (z, name)
        if os.path.exists(p): return Image.open(p).convert('RGBA')
W, H = 430, 932
img = Image.new('RGBA', (W, H), (18, 14, 22, 255))
wall, floor = tile('wall'), tile('floor')
wy1 = 470  # wall band y 70..470, floor 470..610
dark = Image.new('RGBA', (1, 1), (0, 0, 0, 90))
for y in range(70, wy1, 96):
    for x in range(-20, W, 96):
        img.alpha_composite(wall.resize((96, 96), 0), (x, y))
for y in range(wy1, 610, 96):
    for x in range(-20, W, 96):
        img.alpha_composite(floor.resize((96, 96), 0), (x, y))
img.alpha_composite(Image.new('RGBA', (W, wy1 - 70), (8, 6, 12, 110)), (0, 70))
img.alpha_composite(Image.new('RGBA', (W, 322), (18, 14, 22, 255)), (0, 610))
d = ImageDraw.Draw(img)
def shadow(cx, cy, w):
    sh = Image.new('RGBA', (w, w // 4))
    ImageDraw.Draw(sh).ellipse((0, 0, w - 1, w // 4 - 1), fill=(0, 0, 0, 120))
    img.alpha_composite(sh, (cx - w // 2, cy - w // 8))
m = Image.open(mon).convert('RGBA'); m = m.crop(m.getbbox())
mx, my = W // 2, 455  # monster feet line
shadow(mx, my, m.width * S)
img.alpha_composite(m.resize((m.width * S, m.height * S), 0), (mx - m.width * S // 2, my - m.height * S))
h = Image.open('ref/hero.png').convert('RGBA')
hx, hy = W // 2 - 10, 605
shadow(hx + 10, hy, 120)
img.alpha_composite(h.resize((h.width * S, h.height * S), 0), (hx - 34 * S // 2, hy - h.height * S))
try:
    f1 = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 22); f2 = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 17)
except Exception:
    f1 = f2 = ImageFont.load_default()
d.text((16, 10), title, font=f1, fill=(232, 228, 236))
d.text((16, 40), 'monster %dx%d px, hero 54 px, both at 3x' % (m.width, m.height), font=f2, fill=(244, 190, 90))
for i, (lab, frac) in enumerate([('Hero', .8), ('Ally', .55), ('Pet', .9)]):
    y = 640 + i * 48
    d.text((18, y), lab, font=f1, fill=(232, 228, 236))
    d.rectangle((90, y + 6, 400, y + 26), fill=(62, 34, 42)); d.rectangle((90, y + 6, 90 + int(310 * frac), y + 26), fill=(62, 140, 80))
img.convert('RGB').save(out)
