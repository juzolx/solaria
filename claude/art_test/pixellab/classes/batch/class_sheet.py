"""One class, both bodies, through the fixed frame set: frame sheet + battle GIF (3x) with portraits.
(Weapons here are PixelLab's own per frame; the one-drawing weapon layer is applied in the game build.)
/c/ai/ComfyUI/python_embeded/python.exe -I class_sheet.py <class> [<class> ...]"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import make_sheets as MS
import hero

def L(p): return Image.open(p).convert("RGBA")
CW = 100
N = ["idle0", "idle1", "atk0", "atk1", "atk2", "atk3", "hit"]
def centre(im):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2)); return c
def at_feet(fr):
    ref = max(f.getbbox()[3] for f in fr[:2])
    out = []
    for f in fr:
        c = Image.new("RGBA", (CW, CW)); c.alpha_composite(f, (0, ref - f.getbbox()[3])); out.append(c)
    return out

def build(cls):
    raw = os.path.join(HERE, "raw")
    CL = {b: at_feet([centre(L(os.path.join(raw, f"{cls}_{b}_n_{k}.png"))) for k in N]) for b in "mf"}
    PO = {b: [centre(L(os.path.join(raw, f"{cls}_{b}_s_idle{i}.png"))) for i in (0, 1)] for b in "mf"}
    name = cls.capitalize()
    F = MS.Sheet(20 + 9 * 210, 110 + 2 * 230, f"{name} - base class outfit (2x)",
                 "Battle idle 2 | attack 4 | hit | portrait idle 2, both bodies. Same wording on every frame.")
    for r, b in enumerate("mf"):
        y = 110 + r * 230
        F.d.text((24, y), f"{r + 1}  {'He' if b == 'm' else 'She'}", font=MS.F_S, fill=MS.GOLD)
        for i, f in enumerate(CL[b] + PO[b]):
            F.im.alpha_composite(hero.zoom(f, 2), (20 + i * 210, y + 24))
    F.im.convert("RGB").save(os.path.join(HERE, f"{cls}_frames.png"))
    SEQ = [0, 1, 0, 1, 2, 3, 3, 4, 5, 0, 6, 6, 0, 1]
    DUR = [260, 260, 260, 260, 110, 110, 160, 90, 140, 200, 220, 220, 260, 260]
    Z = 3; PW = CW * Z
    out = []
    for n, (i, ms) in enumerate(zip(SEQ, DUR)):
        S = MS.Sheet(20 + 2 * (PW + 16), 110 + PW + 40 + 210, f"{name} (3x)", "Battle loop, portrait below.")
        for j, b in enumerate("mf"):
            x0 = 20 + j * (PW + 16)
            S.panel(x0, 110, PW, PW + 30); S.d.text((x0 + 10, 114), "He" if b == "m" else "She", font=MS.F_S, fill=MS.GOLD)
            S.im.alpha_composite(hero.zoom(CL[b][i], Z), (x0, 140))
            p = PO[b][(n // 2) % 2].crop((18, 16, 82, 68))
            S.im.alpha_composite(hero.zoom(p, 3), (x0 + (PW - 192) // 2, 110 + PW + 50))
        out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
    out[0].save(os.path.join(HERE, f"{cls}_loop.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)

for c in sys.argv[1:]:
    build(c)
