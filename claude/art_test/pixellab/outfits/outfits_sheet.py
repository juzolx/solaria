"""Outfit sample: base / plate / mage robe / ranger on both bodies, plus library hair + colours on the new outfits.
/c/ai/ComfyUI/python_embeded/python.exe -I outfits_sheet.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
for p in (os.path.join(PL, "hair"), os.path.join(PL, "custom"), os.path.join(PL, "..", "hero", "tools")):
    sys.path.insert(0, p)
import headswap as HS, recolour as R
import make_sheets as MS

def L(p): return Image.open(p).convert("RGBA")
def tight(im): return im.crop(im.getbbox())
ROT = {"m": os.path.join(PL, "rotations"), "f": os.path.join(PL, "female", "rotations")}
def look(body, outfit, d):
    if outfit == "base":
        return L(os.path.join(ROT[body], d + ".png"))
    if outfit == "plate":
        return L(os.path.join(PL, "custom", "plate", "rotations", d + ".png")) if body == "m" else None
    return L(os.path.join(HERE, "raw", f"{body}_{outfit}_{d}.png"))

OUTFITS = [("base", "Leather (base)"), ("plate", "Plate"), ("robe", "Mage robe"), ("ranger", "Ranger")]
S = MS.Sheet(1540, 1260, "OUTFITS - shape from PixelLab, everything else in code",
             "1 generation per view. Each outfit keeps the same head, so all 37 hair styles, colours and the 10 faces fit on it.")
for r, (body, bname) in enumerate((("m", "Male"), ("f", "Female"))):
    y0 = 110 + r * 330
    S.panel(20, y0, 1500, 310, f"{r + 1}  {bname}: battle view (back) + portrait (front), 3x")
    for c, (o, oname) in enumerate(OUTFITS):
        x = 40 + c * 370
        n, s = look(body, o, "north"), look(body, o, "south")
        if n is None:
            S.d.text((x, y0 + 140), "plate: female not made yet", font=MS.F_S, fill=MS.DIM); continue
        w, _ = S.put(tight(n), x, y0 + 50, 3)
        S.put(tight(s), x + w + 10, y0 + 50, 3)
        S.d.text((x, y0 + 270), f"{c + 1}. {oname}", font=MS.F_S, fill=MS.TXT)
y0 = 790
S.panel(20, y0, 1500, 450, "3  Library hair + colours on the new outfits (code, 0 generations), 3x")
MN, MSo = L(os.path.join(ROT["m"], "north.png")), L(os.path.join(ROT["m"], "south.png"))
BF = {d: L(os.path.join(PL, "female", "raw", f"bald_{d}.png")) for d in ("north", "south")}
RG = R.ref_ranges([MN, MSo])
DEMO = [("m", "robe", "long", "white"), ("m", "ranger", "mohawk", "red"), ("f", "robe", "bun", "pink"), ("f", "ranger", "ponytail", "black")]
x = 40
for body, o, style, col in DEMO:
    for d, base in (("north", MN), ("south", MSo)):
        target = look(body, o, d)
        if body == "f":  # her outfit edit still has her own hair: put her bald head on first
            target = HS.swap(target, look("f", "base", d), BF[d], keep_face=BF["south"] if d == "south" else None)
        hair = L(os.path.join(PL, "hair", "raw", f"{style}_{d}.png"))
        im, hm = HS.swap(target, base, hair, keep_face=(target if d == "south" else None), return_mask=True)
        im = R.recolour(im, hair=R.HAIR[col], ranges=RG, hair_px=hm)
        w, _ = S.put(tight(im), x, y0 + 50, 3); x += w + 8
    S.d.text((x - 2 * w - 8, y0 + 280), f"{o} + {style} {col}", font=MS.F_S, fill=MS.TXT)
    x += 30
S.im.convert("RGB").save(os.path.join(HERE, "01_OUTFITS_sample.png"))
