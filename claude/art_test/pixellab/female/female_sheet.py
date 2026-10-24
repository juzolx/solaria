"""Female body type sheet: 8 directions, male vs female, and the hair library put on her in code.
/c/ai/ComfyUI/python_embeded/python.exe -I female_sheet.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
for p in (os.path.join(PL, "hair"), os.path.join(PL, "custom"), os.path.join(PL, "..", "hero", "tools")):
    sys.path.insert(0, p)
import headswap as HS, recolour as R
import make_sheets as MS

def L(p): return Image.open(p).convert("RGBA")
def tight(im): return im.crop(im.getbbox())
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
FN, FS = L(os.path.join(HERE, "rotations", "north.png")), L(os.path.join(HERE, "rotations", "south.png"))
MN, MSO = L(os.path.join(PL, "rotations", "north.png")), L(os.path.join(PL, "rotations", "south.png"))
RG = R.ref_ranges([FN, FS])
BFN, BFS = L(os.path.join(HERE, "raw", "bald_north.png")), L(os.path.join(HERE, "raw", "bald_south.png"))  # her bald base: new hair goes on this
S = MS.Sheet(1520, 1200, "FEMALE body type - PixelLab (4 generations)",
             "Front view redrawn as a woman (same outfit), then rotated to 8 directions by PixelLab. Hair: a bald version of her (2 gens) takes every library style in code.")
S.panel(20, 110, 1480, 330, "1  Male vs female - battle view (north) and portrait (south), 4x")
x = 40
for im, lab in ((MN, "male"), (MSO, "male"), (FN, "female"), (FS, "female")):
    w, _ = S.put(tight(im), x, 160, 4); x += w + 40
S.panel(20, 460, 1480, 200, "2  Female - all 8 directions, 2x")
for i, d in enumerate(DIRS):
    S.put(L(os.path.join(HERE, "rotations", d + ".png")), 40 + i * 180, 500, 2)
S.panel(20, 680, 1480, 500, "3  Hair library on her (code): own hair, short, ponytail, long pink, bun white, afro black, 3x")
x = 40
for s, col in (("own", None), ("short", None), ("ponytail", None), ("long", "pink"), ("bun", "white"), ("afro", "black")):
    if s == "own":
        n, so, nm, sm = FN, FS, None, None
    else:
        n, nm = HS.swap(BFN, MN, L(os.path.join(PL, "hair", "raw", f"{s}_north.png")), return_mask=True)
        so, sm = HS.swap(BFS, MSO, L(os.path.join(PL, "hair", "raw", f"{s}_south.png")), keep_face=BFS, return_mask=True)
    if col:
        n = R.recolour(n, hair=R.HAIR[col], ranges=RG, hair_px=nm)
        so = R.recolour(so, hair=R.HAIR[col], ranges=RG, hair_px=sm)
    S.put(tight(n), x, 730, 3)
    S.put(tight(so), x, 940, 3, label=f"{s} {col or ''}")
    x += 240
S.im.convert("RGB").save(os.path.join(HERE, "01_FEMALE_body.png"))
