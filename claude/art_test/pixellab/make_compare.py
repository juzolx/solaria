"""Comparison sheet: PixelLab v3 hero vs our hand-made hero, plus a 430x932 battle mockup.
/c/ai/ComfyUI/python_embeded/python.exe -I make_compare.py"""
import os, sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "hero", "tools"))
import hero
import make_sheets as MS

ROT = os.path.join(HERE, "rotations")
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]


def pl(d):
    return Image.open(os.path.join(ROT, d + ".png")).convert("RGBA")


def tight(im):
    return im.crop(im.getbbox())


def mockup(pl_north):
    """Same scene as our 01b mockup, with the PixelLab hero standing where ours stands (feet y~603, centre x 203)."""
    m = MS.mockup(Image.new("RGBA", (80, 80)))  # empty hero slot, keeps the bg, ghoul and bars identical
    d = ImageDraw.Draw(m)
    d.rectangle([0, 40, 430, 68], fill=(18, 14, 22, 255))
    d.text((16, 44), "PixelLab hero + ghoul, same 3x pixel scale", font=MS.F_S, fill=MS.GOLD)
    h = tight(pl_north)
    z = hero.zoom(h, 3)
    sh = Image.new("RGBA", (138, 24), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([0, 0, 137, 23], fill=(40, 46, 70, 150))
    ImageDraw.Draw(sh).ellipse([6, 3, 131, 20], fill=(8, 8, 16, 150))
    m.alpha_composite(sh, (203 - 69, 603 - 14))
    m.alpha_composite(z, (203 - z.width // 2, 603 - z.height))
    return m


def main():
    ours_b = MS.battle()
    ours_p = MS.portrait()
    pn, ps = pl("north"), pl("south")
    for name, im in [("ours battle", ours_b), ("ours portrait", ours_p), ("PL north", pn), ("PL south", ps)]:
        bb = im.getbbox()
        print(name, "canvas", im.size, "figure", bb[2] - bb[0], "x", bb[3] - bb[1])

    S = MS.Sheet(2040, 1630, "PixelLab test  -  base hero vs our hand-made hero",
                 "PixelLab v3, 64 px canvas, 2 trial generations, text prompt only (no style image). Numbers = pick by number.")
    D, F = S.d, MS.F_L

    def row(y, label, items):
        S.panel(20, y, 1140, 460, label)
        x = 40
        for im, z, lab in items:
            w, _ = S.put(tight(im), x, y + 60, z, label=lab)
            x += w + 30

    # 1 + 2: battle view (from behind)
    row(110, "1  PixelLab - battle view (NORTH, from behind)",
        [(pn, 1, "1x"), (pn, 3, "3x (phone)"), (pn, 5, "5x")])
    row(590, "2  Ours (01_HERO_base) - battle view",
        [(ours_b, 1, "1x"), (ours_b, 3, "3x (phone)"), (ours_b, 5, "5x")])
    # 3 + 4: portrait / front
    S.panel(20, 1070, 560, 400, "3  PixelLab - SOUTH (front)")
    x = 40
    for z, lab in [(1, "1x"), (3, "3x"), (5, "5x")]:
        w, _ = S.put(tight(ps), x, 1130, z, label=lab); x += w + 24
    S.panel(600, 1070, 560, 400, "4  Ours - front portrait (bust)")
    x = 620
    for z, lab in [(1, "1x"), (3, "3x"), (5, "5x")]:
        w, _ = S.put(tight(ours_p), x, 1130, z, label=lab); x += w + 24
    # 5: all 8 PixelLab directions
    S.panel(20, 1490, 1140, 120, None)
    D.text((32, 1498), "5  all 8 PixelLab directions, 1.5x:", font=MS.F_S, fill=MS.TXT)
    x = 360
    for dname in DIRS:
        im = pl(dname)
        im = im.resize((96, 96), Image.NEAREST)
        S.im.alpha_composite(im, (x, 1506)); x += 98
    # 6 + 7: phone mockups
    mp = mockup(pn)
    mp.convert("RGB").save(os.path.join(HERE, "02_PL_mockup_430x932.png"))
    ours_m = Image.open(os.path.join(HERE, "..", "hero", "01b_HERO_base_mockup_430x932.png")).convert("RGBA")
    D.text((1180, 110), "6  Phone: PixelLab", font=F, fill=MS.GOLD)
    S.im.alpha_composite(mp, (1180, 145))
    D.text((1620, 110), "7  Phone: ours", font=F, fill=MS.GOLD)
    S.im.alpha_composite(ours_m, (1620, 145))
    D.text((1180, 1090), "Phone mockups shown at true 430x932 size.", font=MS.F_S, fill=MS.DIM)
    S.im.convert("RGB").save(os.path.join(HERE, "01_PL_vs_ours_compare.png"))


if __name__ == "__main__":
    main()
