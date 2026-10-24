"""Round 3b guides: one code-drawn figure per race with its OWN silhouette, back three-quarter
(turned up-right) and front, drawn at the 48 px size; the 32 px guides are the same drawing shrunk.
Faces are NOT drawn for the AI to copy: the face area is flat skin; code stamps faces later.

Silhouettes (playbook / Juzo): Human baseline; Elf slender, long ears, long hair; Orc tall and bulky,
topknot, tusks; Dwarf short and WIDE, big beard visible from behind, heavy helmet, stocky legs;
Goblin small and hunched, huge sideways ears, long nose, scrappy gear, no beard.
"""
import numpy as np
from PIL import Image, ImageDraw

OL = (14, 8, 18)
BOX = 64
CLOTH = ((58, 68, 102), (38, 43, 68), (90, 105, 136))
BOOT = (90, 63, 53)
R = {
    #          height head_w head_h shoulder leg  skin                                   hair
    "human":  dict(h=44, hw=15, hh=15, sw=17, leg=12, skin=((194, 133, 105), (168, 98, 74), (232, 183, 150)), hair=((62, 39, 49), (90, 63, 53))),
    "elf":    dict(h=47, hw=13, hh=15, sw=13, leg=15, skin=((232, 200, 170), (194, 150, 120), (244, 230, 196)), hair=((200, 176, 138), (163, 130, 95))),
    "orc":    dict(h=48, hw=16, hh=14, sw=25, leg=12, skin=((127, 148, 120), (86, 106, 86), (168, 184, 154)), hair=((24, 20, 37), (52, 50, 59))),
    "dwarf":  dict(h=36, hw=16, hh=13, sw=23, leg=7, skin=((194, 133, 105), (168, 98, 74), (232, 183, 150)), hair=((143, 86, 59), (115, 62, 57))),
    "goblin": dict(h=33, hw=15, hh=13, sw=13, leg=8, skin=((117, 167, 67), (62, 137, 72), (168, 202, 88)), hair=None),
}
FEET = 60
CX = 30


def _body(d, p, race, back):
    sk, skd, skl = p["skin"]
    top = FEET - p["h"]
    hy0, hy1 = top, top + p["hh"]
    hunch = 3 if race == "goblin" else 0
    ty0 = hy1 - 1 - hunch                 # shoulders (goblin: head sinks between them)
    ty1 = FEET - p["leg"]
    sw = p["sw"]
    x0, x1 = CX - sw // 2, CX + sw - sw // 2
    # legs
    lw = 5 if race in ("orc", "dwarf") else (3 if race in ("elf", "goblin") else 4)
    d.rectangle((CX - 1 - lw - 1, ty1, CX - 2, FEET - 2), fill=(52, 50, 59))
    d.rectangle((CX + 2, ty1, CX + 2 + lw, FEET - 2), fill=(31, 29, 36))
    d.rectangle((CX - 2 - lw - 2, FEET - 2, CX - 1, FEET), fill=BOOT); d.rectangle((CX + 1, FEET - 2, CX + 4 + lw, FEET), fill=BOOT)
    # torso (tunic; goblin ragged hem)
    c, cd, cl = CLOTH if race != "goblin" else ((106, 74, 40), (62, 39, 49), (154, 112, 64))
    d.polygon([(x0, ty0), (x1, ty0), (x1 - 1, ty1 + 2), (x0 + 1, ty1 + 2)], fill=c)
    d.polygon([(CX + 2, ty0), (x1, ty0), (x1 - 1, ty1 + 2), (CX + 2, ty1 + 2)], fill=cd)
    d.line((x0 + 1, ty0 + 1, CX, ty0 + 1), fill=cl)
    d.rectangle((x0 + 1, ty1 - 1, x1 - 1, ty1), fill=(62, 39, 49))  # belt
    if race == "goblin":
        for x in range(x0 + 1, x1, 3):
            d.point((x, ty1 + 3), fill=c)
    # arms
    aw = 5 if race == "orc" else (4 if race in ("human", "dwarf") else 3)
    d.rectangle((x0 - aw, ty0 + 1, x0, ty1 - 2), fill=c)
    d.rectangle((x0 - aw, ty1 - 2, x0, ty1 + 1), fill=sk)        # left hand
    if back:   # weapon arm raised forward-right
        d.polygon([(x1, ty0 + 1), (x1 + aw + 2, ty0 + 2), (x1 + aw + 3, ty0 + 6), (x1, ty0 + 7)], fill=cd)
        d.rectangle((x1 + aw + 1, ty0 - 3, x1 + aw + 5, ty0 + 1), fill=sk)
    else:
        d.rectangle((x1, ty0 + 1, x1 + aw, ty1 - 2), fill=cd)
        d.rectangle((x1, ty1 - 2, x1 + aw, ty1 + 1), fill=sk)
    return hy0, hy1, x0, x1


def _head(d, p, race, back, hy0, hy1):
    sk, skd, skl = p["skin"]
    hw = p["hw"]
    fwd = 2 if race == "goblin" else 0      # goblin head pokes forward/right
    hx0, hx1 = CX - hw // 2 + fwd, CX + hw - hw // 2 + fwd
    d.ellipse((hx0, hy0, hx1, hy1), fill=skd); d.ellipse((hx0 + 1, hy0, hx1 - 1, hy1 - 1), fill=sk)
    hr = p["hair"]
    if back:
        # face sliver on the right (turned up-right) - flat skin, details are stamped later
        d.polygon([(hx1 - 3, hy0 + 4), (hx1 + 1, hy0 + 6), (hx1 + 1, hy1 - 3), (hx1 - 3, hy1 - 1)], fill=skl)
    if race == "human":
        if back:
            d.ellipse((hx0, hy0 - 1, hx1 - 2, hy1 - 4), fill=hr[0]); d.ellipse((hx0 + 2, hy0, hx0 + 7, hy0 + 4), fill=hr[1])
        else:
            d.chord((hx0, hy0 - 1, hx1, hy1 - 4), 180, 360, fill=hr[0]); d.rectangle((hx0, hy0 + 4, hx0 + 1, hy0 + 8), fill=hr[0]); d.rectangle((hx1 - 1, hy0 + 4, hx1, hy0 + 8), fill=hr[0])
    if race == "elf":
        ear = [(hx1 - 1, hy0 + 7), (hx1 + 7, hy0 + 1), (hx1 + 1, hy0 + 9)]
        d.polygon(ear, fill=skl)
        if not back:
            d.polygon([(hx0 + 1, hy0 + 7), (hx0 - 7, hy0 + 1), (hx0 - 1, hy0 + 9)], fill=sk)
            d.chord((hx0, hy0 - 1, hx1, hy1 - 3), 180, 360, fill=hr[0])
            d.rectangle((hx0 - 1, hy0 + 5, hx0 + 1, hy1 + 8), fill=hr[0]); d.rectangle((hx1 - 1, hy0 + 5, hx1 + 1, hy1 + 8), fill=hr[0])
        else:
            d.ellipse((hx0 - 1, hy0 - 1, hx1 - 2, hy1 - 2), fill=hr[0]); d.rectangle((hx0, hy0 + 6, hx1 - 4, hy1 + 10), fill=hr[0])
            for x in range(hx0 + 2, hx1 - 4, 3):
                d.line((x, hy0 + 8, x, hy1 + 10), fill=hr[1])
            d.polygon(ear, fill=skl)
    if race == "orc":
        d.ellipse((CX - 3, hy0 - 5, CX + 2, hy0), fill=hr[0]); d.rectangle((CX - 2, hy0 - 1, CX + 1, hy0 + 2), fill=hr[0])
        d.polygon([(hx0 + 1, hy1 - 6), (hx1 - 1, hy1 - 6), (hx1 - 2, hy1 + 1), (hx0 + 2, hy1 + 1)], fill=sk)  # heavy jaw
        if back:
            d.rectangle((hx1 - 5, hy0 + 5, hx1 - 4, hy0 + 8), fill=skd)
            d.rectangle((hx1, hy1 - 3, hx1, hy1 - 1), fill=(244, 230, 196))
        else:
            d.rectangle((hx0 + 3, hy1 - 3, hx0 + 3, hy1 - 1), fill=(244, 230, 196)); d.rectangle((hx1 - 3, hy1 - 3, hx1 - 3, hy1 - 1), fill=(244, 230, 196))
    if race == "dwarf":
        d.chord((hx0 - 1, hy0 - 2, hx1 + 1, hy0 + 9), 180, 360, fill=(84, 93, 112)); d.rectangle((hx0 - 2, hy0 + 3, hx1 + 2, hy0 + 4), fill=(125, 135, 152))
        d.point((CX, hy0 - 2), fill=(168, 168, 186))
        if back:  # beard spills out on both sides of the head and over the shoulders
            d.polygon([(hx0 - 1, hy0 + 7), (hx0 - 4, hy1 + 5), (hx0 + 1, hy1 + 7)], fill=hr[0])
            d.polygon([(hx1 + 1, hy0 + 7), (hx1 + 5, hy1 + 6), (hx1 - 1, hy1 + 8)], fill=hr[0])
            d.line((hx1 + 2, hy0 + 9, hx1 + 3, hy1 + 5), fill=hr[1])
        else:
            d.polygon([(hx0 + 1, hy0 + 8), (hx1 - 1, hy0 + 8), (hx1 + 1, hy1 + 10), (CX, hy1 + 13), (hx0 - 1, hy1 + 10)], fill=hr[0])
            for x in range(hx0 + 2, hx1, 3):
                d.line((x, hy1 + 1, x, hy1 + 9), fill=hr[1])
    if race == "goblin":
        d.polygon([(hx0 + 1, hy0 + 5), (hx0 - 9, hy0 + 1), (hx0 - 6, hy0 + 6), (hx0 + 1, hy0 + 8)], fill=sk)
        d.polygon([(hx1 - 1, hy0 + 5), (hx1 + 9, hy0 + 1), (hx1 + 6, hy0 + 6), (hx1 - 1, hy0 + 8)], fill=skl)
        if back:
            d.polygon([(hx1, hy0 + 8), (hx1 + 4, hy0 + 10), (hx1, hy0 + 11)], fill=skl)   # long nose tip
        else:
            d.polygon([(CX + 1, hy0 + 7), (CX + 4, hy0 + 12), (CX, hy0 + 11)], fill=skd)


def figure(race, back=True):
    p = R[race]
    im = Image.new("RGBA", (BOX, BOX), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    hy0, hy1, x0, x1 = _body(d, p, race, back)
    _head(d, p, race, back, hy0, hy1)
    return outline(im)


def outline(im):
    a = np.array(im); op = a[..., 3] > 0
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(op, dy, 0), dx, 1)
    a[ring & ~op] = OL + (255,)
    return Image.fromarray(a)


def small(im):
    """The 32 px guide: the 48 px drawing shrunk 2/3 (it is only a guide; the AI redraws it)."""
    return im.resize((BOX * 2 // 3, BOX * 2 // 3), Image.NEAREST)


def canvas(im):
    c = Image.new("RGB", (1024, 1024), (255, 255, 255))
    big = im.resize((im.width * 8, im.height * 8), Image.NEAREST)
    c.paste(big, ((1024 - big.width) // 2, 560 - big.height // 2), big)
    return c


if __name__ == "__main__":
    races = list(R)
    sheet = Image.new("RGBA", (BOX * 5, BOX * 2), (200, 200, 200, 255))
    for i, r in enumerate(races):
        for j, back in enumerate((True, False)):
            f = figure(r, back); v = "back" if back else "front"
            sheet.alpha_composite(f, (i * BOX, j * BOX))
            f.save(rf"C:\ai\art_work3\g4_{r}_{v}_48.png"); small(f).save(rf"C:\ai\art_work3\g4_{r}_{v}_32.png")
            canvas(f).save(rf"C:\ai\art_work3\g4_{r}_{v}_48_1024.png"); canvas(small(f)).save(rf"C:\ai\art_work3\g4_{r}_{v}_32_1024.png")
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(r"C:\ai\art_work3\g4_sheet.png")
    print("ok")
