"""Her 10 portrait expressions, on her own hair and on library styles / colours (numbered phone sheet).
/c/ai/ComfyUI/python_embeded/python.exe -I faces_sheet_f.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); FEM = os.path.dirname(HERE); PL = os.path.dirname(FEM)
for p in (os.path.join(PL, "hair"), os.path.join(PL, "custom"), os.path.join(PL, "..", "hero", "tools")):
    sys.path.insert(0, p)
import headswap as HS, recolour as R
import make_sheets as MS

FACES = [("Neutral", None), ("Determined", "determined"), ("Smile", "smile"), ("Fierce", "fierce"),
         ("Battle cry", "battle_cry"), ("Wary", "wary"), ("Sleepy", "sleepy"), ("Laughing", "laughing"),
         ("Surprised", "surprised"), ("Grim", "grim")]
def L(p): return Image.open(p).convert("RGBA")
FS = L(os.path.join(FEM, "rotations", "south.png"))
BFS = L(os.path.join(FEM, "raw", "bald_south.png"))
MS_ = L(os.path.join(PL, "rotations", "south.png"))
RG = R.ref_ranges([FS, L(os.path.join(FEM, "rotations", "north.png"))])
STY = [("ponytail", None), ("bob", "pink"), ("long", "white")]
heads = {}
for s, _ in STY:
    heads[s] = HS.swap(BFS, MS_, L(os.path.join(PL, "hair", "raw", f"{s}_south.png")), keep_face=BFS, return_mask=True)
os.makedirs(os.path.join(HERE, "lib"), exist_ok=True)

def bust(im):
    return im.crop((6, 0, 50, 40))

COLS, CW, CH = 5, 330, 420
S = MS.Sheet(20 + COLS * CW, 110 + 2 * CH + 20, "FACES (female) - her 10 portrait expressions",
             "Same list as his: each face is a 1-generation PixelLab edit of her front view, laid onto any hair style in code.")
for i, (name, key) in enumerate(FACES):
    face = FS if key is None else L(os.path.join(HERE, "raw", key + ".png"))
    main = HS.put_face(FS, FS, face)
    main.save(os.path.join(HERE, "lib", f"{(key or 'neutral')}_south.png"))
    x0, y0 = 20 + (i % COLS) * CW, 110 + (i // COLS) * CH
    S.panel(x0, y0, CW - 20, CH - 20, f"{i + 1}  {name}")
    S.put(bust(main), x0 + 14, y0 + 44, 5)
    x = x0 + 14
    for s, col in STY:
        h, hm = heads[s]
        im = HS.put_face(h, FS, face)
        if col:
            im = R.recolour(im, hair=R.HAIR[col], ranges=RG, hair_px=hm)
        w, _ = S.put(bust(im), x, y0 + 262, 2); x += w + 10
    S.d.text((x0 + 14, y0 + 352), "ponytail | bob pink | long white", font=MS.F_S, fill=MS.DIM)
S.im.convert("RGB").save(os.path.join(HERE, "01_FACES_female_10.png"))
