"""Sheet: base hero vs PixelLab 'Plate armour' state (+ code hair recolour on the armour state).
/c/ai/ComfyUI/python_embeded/python.exe -I demo_outfit.py"""
import os, sys, glob
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import recolour as R
import make_sheets as MS

def rot(base, d): return Image.open(os.path.join(base, "rotations", d + ".png")).convert("RGBA")
def tight(im): return im.crop(im.getbbox())
B, P = PL, os.path.join(HERE, "plate")
RG = R.ref_ranges([Image.open(f).convert("RGBA") for f in glob.glob(os.path.join(P, "rotations", "*.png"))])
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
S = MS.Sheet(1500, 1200, "Outfit sample - PixelLab 'state' of the same hero (10 generations)",
             "create_character_state keeps face, hair, build and sword; only the outfit changes, in all 8 directions.")
S.panel(20, 110, 1460, 400, "1  Base outfit vs plate armour - battle view (north) and front (south), 4x")
x = 40
for base, lab in ((B, "base"), (P, "plate")):
    for d in ("north", "south"):
        w, _ = S.put(tight(rot(base, d)), x, 160, 4, label=f"{lab} {d}"); x += w + 40
S.panel(20, 530, 1460, 200, "2  Plate armour - all 8 directions, 2x")
for i, d in enumerate(DIRS):
    S.put(rot(P, d), 40 + i * 175, 570, 2)
S.panel(20, 750, 1460, 430, "3  Plate armour + code hair colours (no extra generations), 3x")
for i, h in enumerate(R.HAIR):
    x = 40 + i * 290
    S.put(tight(R.recolour(rot(P, "north"), hair=R.HAIR[h], ranges=RG)), x, 800, 3)
    S.put(tight(R.recolour(rot(P, "south"), hair=R.HAIR[h], ranges=RG)), x + 130, 800, 3, label=h)
S.im.convert("RGB").save(os.path.join(HERE, "02_outfit_plate_sample.png"))
