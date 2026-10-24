"""Sheet: PixelLab hero hair colours x skin tones (north + south), code recolour only.
/c/ai/ComfyUI/python_embeded/python.exe -I demo_recolour.py"""
import os, sys, glob
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import recolour as R
import hero, make_sheets as MS

frames = [Image.open(f).convert("RGBA") for f in glob.glob(os.path.join(PL, "rotations", "*.png"))]
RG = R.ref_ranges(frames)
print(RG)
n, s = [Image.open(os.path.join(PL, "rotations", d + ".png")).convert("RGBA") for d in ("north", "south")]

def tight(im): return im.crop(im.getbbox())

# debug: material mask of north + south
dbg_c = {"outline": (0, 0, 0), "shirt": (255, 255, 255), "metal": (80, 160, 255), "skin": (255, 180, 120), "hair": (255, 60, 200), "face": (255, 240, 0), "cloth": (120, 90, 60)}
def dbg(im):
    m = Image.new("RGBA", im.size)
    for (x, y), k in R.masks(im).items(): m.putpixel((x, y), dbg_c[k] + (255,))
    return m

hairs = list(R.HAIR); skins = list(R.SKIN)
S = MS.Sheet(40 + len(hairs) * 290, 1240, "PixelLab hero - code recolours (0 generations)",
             "Hair colour and skin tone done in code on the PixelLab frames: same art, ramp swap per material. Pink in panel 3 = what code treats as hair.")
S.panel(20, 110, len(hairs) * 290, 330, "1  Hair colours - battle view (north) + front (south), 3x")
for i, h in enumerate(hairs):
    x = 40 + i * 290
    S.put(tight(R.recolour(n, hair=R.HAIR[h], ranges=RG)), x, 160, 3)
    S.put(tight(R.recolour(s, hair=R.HAIR[h], ranges=RG)), x + 120, 160, 3, label=h)
S.panel(20, 460, len(hairs) * 290, 330, "2  Skin tones - front (south) + side, 3x")
e = Image.open(os.path.join(PL, "rotations", "south-east.png")).convert("RGBA")
for i, k in enumerate(skins):
    x = 40 + i * 290
    S.put(tight(R.recolour(s, skin=R.SKIN[k], ranges=RG)), x, 510, 3, label=k)
    S.put(tight(R.recolour(e, skin=R.SKIN[k], ranges=RG)), x + 120, 510, 3)
S.panel(20, 810, len(hairs) * 290, 410, "3  How code splits the materials (check): north, south, attack frame")
a = Image.open(os.path.join(PL, "anims", "attack2_north", "04.png")).convert("RGBA")
x = 40
for im in (n, s, a):
    w, _ = S.put(tight(dbg(im)), x, 860, 4); x += w + 30
S.d.text((x, 870), "pink = hair, peach = skin,\nyellow = face detail (kept),\nwhite = shirt, blue = metal,\nbrown = cloth/leather", font=MS.F_S, fill=MS.TXT)
S.im.convert("RGB").save(os.path.join(HERE, "01_recolour_demo.png"))
