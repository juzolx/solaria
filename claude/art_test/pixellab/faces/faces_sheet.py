"""10 portrait expressions on the PixelLab hero, on several hair styles and colours (numbered phone sheet).
/c/ai/ComfyUI/python_embeded/python.exe -I faces_sheet.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
for p in (os.path.join(PL, "hair"), os.path.join(PL, "custom"), os.path.join(PL, "..", "hero", "tools")):
    sys.path.insert(0, p)
import headswap as HS, recolour as R
import make_sheets as MS

FACES = [("Neutral", None), ("Determined", "determined"), ("Smile", "smile"), ("Fierce", "fierce"),
         ("Battle cry", "battle_cry"), ("Wary", "wary"), ("Sleepy", "sleepy"), ("Laughing", "laughing"),
         ("Surprised", "surprised"), ("Grim", "grim")]
def L(p): return Image.open(p).convert("RGBA")
BS = L(os.path.join(PL, "rotations", "south.png"))
RG = R.ref_ranges([BS, L(os.path.join(PL, "rotations", "north.png"))])
STY = [("short", None), ("long", "pink"), ("ponytail", "white")]
heads = {s: L(os.path.join(PL, "hair", "lib", f"{s}_south.png")) for s, _ in STY}
masks = {s: HS.load_mask(os.path.join(PL, "hair", "lib", f"{s}_south_hairmask.png")) for s, _ in STY}
os.makedirs(os.path.join(HERE, "lib"), exist_ok=True)

def bust(im):  # head + shoulders, the portrait crop
    return im.crop((6, 0, 50, 40))

COLS, CW, CH = 5, 330, 420
S = MS.Sheet(20 + COLS * CW, 110 + 2 * CH + 20, "FACES - 10 portrait expressions on the PixelLab hero",
             "Each face is a 1-generation PixelLab edit of the front view, laid onto any hair style in code. Small heads: same face, other styles + new pink / white hair.")
for i, (name, key) in enumerate(FACES):
    face = BS if key is None else L(os.path.join(HERE, "raw", key + ".png"))
    main = HS.put_face(BS, BS, face)
    main.save(os.path.join(HERE, "lib", f"{(key or 'neutral')}_south.png"))
    x0, y0 = 20 + (i % COLS) * CW, 110 + (i // COLS) * CH
    S.panel(x0, y0, CW - 20, CH - 20, f"{i + 1}  {name}")
    S.put(bust(main), x0 + 14, y0 + 44, 5)
    x = x0 + 14
    for s, col in STY:
        im = HS.put_face(heads[s], BS, face)
        if col:
            im = R.recolour(im, hair=R.HAIR[col], ranges=RG, hair_px=masks[s])
        w, _ = S.put(bust(im), x, y0 + 262, 2); x += w + 10
    S.d.text((x0 + 14, y0 + 352), "short | long pink | ponytail white", font=MS.F_S, fill=MS.DIM)
S.im.convert("RGB").save(os.path.join(HERE, "01_FACES_10.png"))
