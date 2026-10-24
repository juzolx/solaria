"""All 37 old hair styles on the PixelLab hero (HAIR_ORDER from lpc.gd), exported per style + 2 numbered phone sheets.
/c/ai/ComfyUI/python_embeded/python.exe -I library.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import headswap as HS, recolour as R
import make_sheets as MS

ORDER = ["Short", "Spiky", "Side Swept", "Shaggy", "Mohawk", "Short Mohawk", "Buzz", "Bald", "Balding",
         "Bedhead", "Unkempt", "Porcupine", "Mop", "Parted", "Page", "Bangs", "Long Bangs", "Long", "Very Long", "Wild",
         "Loose", "Wavy", "Tied Back", "Ponytail", "High Ponytail", "Half Up", "Pigtails", "Bun", "Braid", "Bob", "Pixie",
         "Princess", "Curly", "Long Curls", "Afro", "Cornrows", "Dreadlocks"]
def key(n): return n.lower().replace(" ", "_")
def L(p): return Image.open(p).convert("RGBA")
def tight(im): return im.crop(im.getbbox())
BN, BS = L(os.path.join(PL, "rotations", "north.png")), L(os.path.join(PL, "rotations", "south.png"))
RG = R.ref_ranges([BN, BS])
os.makedirs(os.path.join(HERE, "lib"), exist_ok=True)
CARDS = []
for i, n in enumerate(ORDER):
    k = key(n)
    if k == "shaggy":  # the base hero's own hair
        n_im, s_im = BN, BS
    else:
        n_im = HS.swap(BN, BN, L(os.path.join(HERE, "raw", f"{k}_north.png")))
        s_im = HS.swap(BS, BS, L(os.path.join(HERE, "raw", f"{k}_south.png")), keep_face=BS)
    n_im.save(os.path.join(HERE, "lib", f"{k}_north.png")); s_im.save(os.path.join(HERE, "lib", f"{k}_south.png"))
    CARDS.append((i + 1, n, n_im, s_im))
COLS, CW, CH = 4, 400, 300
for part, cards in ((1, CARDS[:20]), (2, CARDS[20:])):
    rows = (len(cards) + COLS - 1) // COLS
    S = MS.Sheet(20 + COLS * CW, 110 + rows * CH, f"HAIR {part}/2 - old styles on the PixelLab hero",
                 "Battle view (back) + portrait (front), 3x. Numbers follow the old in-game list. Every style takes every hair colour.")
    for j, (num, n, ni, si) in enumerate(cards):
        x0, y0 = 20 + (j % COLS) * CW, 110 + (j // COLS) * CH
        S.panel(x0, y0, CW - 20, CH - 20, f"{num}  {n}")
        w, _ = S.put(tight(ni), x0 + 14, y0 + 44, 3)
        S.put(tight(si), x0 + 14 + w + 14, y0 + 44, 3)
        if num % 3 == 0:  # a few cards show a code colour so the range is visible
            c = ["black", "blond", "red", "ash"][(num // 3) % 4]
            S.put(tight(R.recolour(si, hair=R.HAIR[c], ranges=RG)), x0 + CW - 92, y0 + 150, 2)
            S.d.text((x0 + CW - 92, y0 + 250), c, font=MS.F_S, fill=MS.DIM)
    S.im.convert("RGB").save(os.path.join(HERE, f"03_HAIR_library_{part}.png"))
