"""HAIR sample sheet: 6 PixelLab hair styles put on the base + plate outfit, battle frames and portrait, plus code colours.
/c/ai/ComfyUI/python_embeded/python.exe -I demo_hair.py [--check]"""
import os, sys, glob
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import headswap as HS, recolour as R
import hero, make_sheets as MS

STYLES = ["short", "spiky", "mohawk", "buzz", "long", "ponytail"]
def L(p): return Image.open(p).convert("RGBA")
def tight(im): return im.crop(im.getbbox())
BN, BS = L(os.path.join(PL, "rotations", "north.png")), L(os.path.join(PL, "rotations", "south.png"))
PN, PS = L(os.path.join(PL, "custom", "plate", "rotations", "north.png")), L(os.path.join(PL, "custom", "plate", "rotations", "south.png"))
ATK = [L(f) for f in sorted(glob.glob(os.path.join(PL, "anims", "attack2_north", "*.png")))]
IDL = [L(f) for f in sorted(glob.glob(os.path.join(PL, "anims", "idle_north", "*.png")))]
RG = R.ref_ranges([BN, BS])
HAIRC = ["brown", "black", "blond", "red", "ash"]

def styled(s):
    hn, hs = L(os.path.join(HERE, "raw", f"{s}_north.png")), L(os.path.join(HERE, "raw", f"{s}_south.png"))
    return {"north": HS.swap(BN, BN, hn), "south": HS.swap(BS, BS, hs, keep_face=BS),
            "plate_n": HS.swap(PN, BN, hn), "plate_s": HS.swap(PS, BS, hs, keep_face=BS),
            "atk": [HS.swap(f, BN, hn) for f in ATK], "idle": [HS.swap(f, BN, hn) for f in IDL], "hn": hn, "hs": hs}

out = {s: styled(s) for s in STYLES}
os.makedirs(os.path.join(HERE, "out"), exist_ok=True)
for s, d in out.items():
    for k in ("north", "south", "plate_n", "plate_s"):
        d[k].save(os.path.join(HERE, "out", f"{s}_{k}.png"))

W = 40 + 3 * 640
S = MS.Sheet(W, 110 + 2 * 520 + 20, "HAIR - 6 styles on the PixelLab hero (12 generations)",
             "Shape from PixelLab (1 edit per view), put on any outfit and animation frame in code; colours in code. Portrait keeps the base face.")
for i, s in enumerate(STYLES):
    d = out[s]
    x0, y0 = 20 + (i % 3) * 640, 110 + (i // 3) * 520
    S.panel(x0, y0, 620, 500, f"{i + 1}  {s.capitalize()}")
    x = x0 + 16
    for im in (d["north"], d["south"], d["plate_n"], d["plate_s"]):
        w, _ = S.put(tight(im), x, y0 + 50, 3); x += w + 12
    S.d.text((x0 + 16, y0 + 250), "battle (north) | portrait (south) | plate north | plate south", font=MS.F_S, fill=MS.DIM)
    x = x0 + 16
    for f in (d["atk"][0], d["atk"][3], d["atk"][5], d["atk"][7]):
        w, _ = S.put(tight(f), x, y0 + 290, 2); x += w + 8
    x += 14
    for c in ("black", "blond", "red"):
        w, _ = S.put(tight(R.recolour(d["south"], hair=R.HAIR[c], ranges=RG)), x, y0 + 300, 2); x += w + 4
    S.d.text((x0 + 16, y0 + 466), "attack frames 0/3/5/7  |  code colours: black, blond, red", font=MS.F_S, fill=MS.DIM)
S.im.convert("RGB").save(os.path.join(HERE, "01_HAIR_6_styles.png"))
# phone loop with one style per cycle so Juzo sees them move
seq = []
for s in STYLES:
    seq += [(f, 220) for f in out[s]["idle"] * 2] + [(f, 90) for f in out[s]["atk"]]
fi, fa = max(f.getbbox()[3] for f in IDL), max(f.getbbox()[3] for f in ATK)
frames, durs = [], []
for f, ms in seq:
    m = MS.mockup(Image.new("RGBA", (80, 80)))
    dd = ImageDraw.Draw(m); dd.rectangle([0, 40, 430, 68], fill=(18, 14, 22, 255))
    z = hero.zoom(f, 3); feet = fi if f.width == 64 else fa
    m.alpha_composite(z, (203 - z.width // 2, 603 - feet * 3))
    frames.append(m.convert("RGB").convert("P", palette=Image.ADAPTIVE)); durs.append(ms)
frames[0].save(os.path.join(HERE, "02_HAIR_battle_loop_430x932.gif"), save_all=True, append_images=frames[1:], duration=durs, loop=0)
