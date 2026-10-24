"""Round 3 guides: slim armoured body (look B) + per-race heads drawn so every race reads from behind
(hair, ears, beard, tusks), face turned up-right (cheek, nose, eye sliver on the right).
Tall build ~29 art px, short ~24 (smaller than before: the hero was too big next to monsters).
Drawn at art-pixel size in a 40x40 box; put on white 1024 at 8x for img2img.
"""
import numpy as np
from PIL import Image, ImageDraw

OL = (14, 8, 18)
STEEL, STEEL_D, STEEL_L = (90, 105, 136), (52, 50, 59), (139, 155, 180)
LEATHER = (90, 63, 53)
SK = {"human": ((168, 98, 74), (115, 62, 57), (194, 133, 105)),
      "elf": ((200, 160, 130), (150, 110, 90), (232, 200, 170)),
      "orc": ((86, 106, 86), (52, 70, 56), (127, 148, 120)),
      "dwarf": ((168, 98, 74), (115, 62, 57), (194, 133, 105)),
      "goblin": ((90, 120, 60), (55, 80, 45), (130, 160, 80))}
HAIR = {"human": ((62, 39, 49), (42, 26, 30)), "elf": ((200, 176, 138), (163, 130, 95)),
        "orc": ((24, 20, 37), (14, 8, 18)), "dwarf": ((143, 86, 59), (115, 62, 57)), "goblin": None}


def body(d, short):
    s = (lambda y: 16 + int((y - 16) * 0.8)) if short else (lambda y: y)  # squash rows below the neck
    w = 2 if short else 0
    # legs
    d.polygon([(14 - w, s(29)), (17, s(29)), (16, s(36)), (13 - w, s(36))], fill=STEEL_D)
    d.polygon([(19, s(29)), (22 + w, s(29)), (23 + w, s(34)), (20, s(35))], fill=STEEL_D)
    d.rectangle((12 - w, s(36), 16, s(37)), fill=LEATHER); d.rectangle((20, s(34), 24 + w, s(35)), fill=LEATHER)
    # slim plate torso (back), light top-left
    d.polygon([(13 - w, 17), (24 + w, 17), (23 + w, s(29)), (14 - w, s(29))], fill=STEEL)
    d.polygon([(19, 17), (24 + w, 17), (23 + w, s(29)), (19, s(29))], fill=STEEL_D)
    d.line([(14 - w, 18), (18, 18)], fill=STEEL_L)
    d.rectangle((14 - w, s(27), 23 + w, s(28)), fill=LEATHER)
    # pauldrons
    d.ellipse((10 - w, 15, 16 - w, 20), fill=STEEL_L); d.ellipse((21 + w, 15, 26 + w, 19), fill=STEEL)
    # left arm down
    d.polygon([(10 - w, 19), (13 - w, 19), (13 - w, s(26)), (10 - w, s(27))], fill=STEEL)
    # weapon arm raised forward-right, fist
    d.polygon([(23 + w, 17), (27 + w, 18), (29 + w, 21), (26 + w, 22), (23 + w, 21)], fill=STEEL_D)
    d.rectangle((27 + w, 15, 30 + w, 18), fill=STEEL_L)


def head(d, race):
    sk, skd, skl = SK[race]
    y0 = 5
    d.ellipse((12, y0, 25, y0 + 12), fill=skd); d.ellipse((13, y0, 24, y0 + 11), fill=sk)
    # face sliver on the right (turned up-right)
    d.polygon([(22, y0 + 3), (26, y0 + 5), (27, y0 + 8), (25, y0 + 11), (22, y0 + 11)], fill=skl)
    d.point((27, y0 + 7), fill=skl); d.point((25, y0 + 6), fill=OL)
    hr = HAIR[race]
    if race == "human":   # short dark hair over the back and top
        d.ellipse((12, y0 - 1, 24, y0 + 9), fill=hr[0]); d.ellipse((13, y0 - 1, 18, y0 + 3), fill=(90, 63, 53))
        d.rectangle((20, y0 + 5, 21, y0 + 8), fill=skd)              # ear
    if race == "elf":     # long pale hair to the shoulders, long ear tip out to the right
        d.ellipse((11, y0 - 1, 24, y0 + 10), fill=hr[0]); d.rectangle((12, y0 + 6, 21, y0 + 14), fill=hr[0])
        d.line([(14, y0 + 7), (14, y0 + 14)], fill=hr[1]); d.line([(18, y0 + 7), (18, y0 + 14)], fill=hr[1])
        d.polygon([(21, y0 + 6), (27, y0 + 1), (23, y0 + 8)], fill=skl)
    if race == "orc":     # black topknot, small ear, white tusk at the jaw
        d.ellipse((16, y0 - 4, 21, y0 + 1), fill=hr[0]); d.rectangle((17, y0, 20, y0 + 2), fill=hr[0])
        d.rectangle((20, y0 + 5, 21, y0 + 8), fill=skd)
        d.rectangle((25, y0 + 9, 25, y0 + 11), fill=(244, 230, 196))
    if race == "dwarf":   # iron cap + a big braided beard spilling out on both sides
        d.chord((12, y0 - 1, 25, y0 + 10), 180, 360, fill=STEEL_D); d.line([(12, y0 + 4), (25, y0 + 4)], fill=STEEL_L)
        d.polygon([(11, y0 + 7), (13, y0 + 13), (16, y0 + 15), (13, y0 + 16), (10, y0 + 12)], fill=hr[0])
        d.polygon([(24, y0 + 8), (28, y0 + 11), (27, y0 + 16), (24, y0 + 15)], fill=hr[0])
        d.line([(26, y0 + 12), (26, y0 + 15)], fill=hr[1])
    if race == "goblin":  # bald olive head, huge ears sticking out sideways
        d.polygon([(13, y0 + 4), (6, y0 + 1), (8, y0 + 5), (13, y0 + 7)], fill=sk)
        d.polygon([(23, y0 + 4), (30, y0 + 0), (28, y0 + 5), (23, y0 + 7)], fill=skl)
        d.point((26, y0 + 7), fill=(254, 231, 97))


def outline(im):
    a = np.array(im); op = a[..., 3] > 0
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(op, dy, 0), dx, 1)
    a[ring & ~op] = OL + (255,)
    return Image.fromarray(a)


def make(race, short=None):
    short = race in ("dwarf", "goblin") if short is None else short
    im = Image.new("RGBA", (40, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    body(d, short)
    if short:  # short builds: head sits lower
        h = Image.new("RGBA", (40, 40), (0, 0, 0, 0)); head(ImageDraw.Draw(h), race)
        im.alpha_composite(h.transform(h.size, Image.AFFINE, (1, 0, 0, 0, 1, -1)))
    else:
        head(d, race)
    return outline(im)


def canvas(im, S=8):
    c = Image.new("RGB", (1024, 1024), (255, 255, 255))
    big = im.resize((im.width * S, im.height * S), Image.NEAREST)
    c.paste(big, (512 - 20 * S, 430 - 2 * S), big)
    return c


if __name__ == "__main__":
    row = Image.new("RGBA", (40 * 5, 40), (200, 200, 200, 255))
    for i, r in enumerate(["human", "elf", "orc", "dwarf", "goblin"]):
        im = make(r); im.save(rf"C:\ai\art_work3\g_{r}.png"); canvas(im).save(rf"C:\ai\art_work3\g_{r}_1024.png")
        row.alpha_composite(im, (i * 40, 0))
    row.resize((row.width * 6, row.height * 6), Image.NEAREST).save(r"C:\ai\art_work3\guides.png")
    print("ok")
