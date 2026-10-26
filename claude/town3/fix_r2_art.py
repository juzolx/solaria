"""Fable town round 2 art: the Tavern's chimney moves to the far gable (nothing in front of the
Bounty Board), a bigger Bounty Board (two posts, planked frame, a little roof, readable papers),
and the hope-path stair gets riser shadows, lit tread edges, moss and a darker stone.
Originals are kept as art/orig_r2_*.png and every run starts from them. Usage: py fix_r2_art.py"""
import os
import shutil
from PIL import Image, ImageDraw

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "art")


def orig(name, src=None):
    o = os.path.join(A, "orig_r2_" + os.path.basename(name))
    if not os.path.exists(o):
        shutil.copy(os.path.join(A, src or name), o)
    return Image.open(o).convert("RGBA")


def tavern():
    im = orig("tavern.png")
    px = im.load()
    # the chimney: grey stone (and its outline) above the roof's orange ridge trim, x 112-133
    chim = Image.new("RGBA", (22, 42), (0, 0, 0, 0))
    cp = chim.load()
    for x in range(112, 134):
        trim = next((y for y in range(4, 60) if (lambda p: p[3] and p[0] - p[2] > 40 and p[0] > p[1] > p[2])(px[x, y])), 46)
        stop = trim if x < 126 else 41
        for y in range(4, stop):
            r, g, b, a = px[x, y]
            if a and max(r, g, b) - min(r, g, b) < 30:
                cp[x - 112, y - 4] = (r, g, b, a)
                px[x, y] = (0, 0, 0, 0)
    for _ in range(2):                                       # crumbs of its outline left in the air
        for x in range(110, 136):
            for y in range(2, 48):
                if px[x, y][3] and sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if px[x + dx, y + dy][3]) < 2:
                    px[x, y] = (0, 0, 0, 0)
    # onto the far (west) gable: a canvas 34 px taller so it fits, bottom corner unchanged
    out = Image.new("RGBA", (im.width, im.height + 34), (0, 0, 0, 0))
    out.alpha_composite(im, (0, 34))
    bb = chim.getbbox()
    chim = chim.crop((bb[0], bb[1], bb[2], bb[3] - 6))     # its foot hides behind the ridge
    out.alpha_composite(chim, (52, 34 + 13 - chim.height))
    o = out.load()
    for x in range(52, 52 + chim.width):                     # the ridge trim passes in front again
        for y in range(34 + 6, 34 + 16):
            p = im.getpixel((x, y - 34))
            if p[3] and p[0] - p[2] > 40 and p[0] > p[1] > p[2]:
                o[x, y] = p
    out.save(os.path.join(A, "tavern.png"))


def board():
    orig("props48/p6.png")
    im = Image.new("RGBA", (56, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink, dark, wood, lite = (24, 16, 12, 255), (62, 40, 24, 255), (104, 70, 42, 255), (146, 104, 64, 255)
    for x0 in (6, 46):                                        # posts
        d.rectangle([x0 - 1, 8, x0 + 4, 63], fill=ink)
        d.rectangle([x0, 9, x0 + 3, 62], fill=wood)
        d.line([x0, 9, x0, 62], fill=lite)
        d.line([x0 + 3, 9, x0 + 3, 62], fill=dark)
        d.rectangle([x0 - 1, 60, x0 + 4, 63], fill=(52, 50, 56, 255))
    d.rectangle([8, 12, 47, 45], fill=ink)                    # the planked board
    for k, y in enumerate(range(13, 45, 4)):
        d.rectangle([9, y, 46, y + 3], fill=wood if k % 2 else (92, 62, 38, 255))
        d.line([9, y, 46, y], fill=lite if k % 2 else wood)
    d.rectangle([8, 12, 47, 45], outline=ink)
    d.line([9, 44, 46, 44], fill=dark)
    d.polygon([(2, 10), (10, 2), (45, 2), (53, 10)], fill=ink)    # a little shingled roof
    d.polygon([(4, 9), (11, 3), (44, 3), (51, 9)], fill=(70, 74, 88, 255))
    for x in range(8, 50, 4):
        d.line([x, 4, x - 2, 8], fill=(46, 48, 60, 255))
    d.line([3, 10, 52, 10], fill=(118, 84, 52, 255))
    cream, shade, line, seal = (232, 220, 180, 255), (196, 180, 140, 255), (110, 92, 66, 255), (176, 32, 32, 255)
    for k, (x, y) in enumerate(((12, 17), (24, 15), (36, 18))):   # three papers, 8x10, pinned with a red seal
        d.rectangle([x - 1, y - 1, x + 8, y + 10], fill=ink)
        d.rectangle([x, y, x + 7, y + 9], fill=cream)
        d.line([x + 7, y + 1, x + 7, y + 9], fill=shade)
        d.line([x, y + 9, x + 7, y + 9], fill=shade)
        d.point((x + 3, y), fill=seal)
        d.point((x + 4, y), fill=seal)
        if k == 1:                                           # WANTED: a black silhouette
            d.rectangle([x + 3, y + 2, x + 4, y + 3], fill=ink)
            d.rectangle([x + 2, y + 4, x + 5, y + 6], fill=ink)
            d.line([x + 1, y + 8, x + 6, y + 8], fill=seal)
        else:
            for yy in (y + 3, y + 5, y + 7):
                d.line([x + 1, yy, x + 5 + (yy % 2), yy], fill=line)
    im.save(os.path.join(A, "props48", "p6.png"))


def stair():
    im = orig("plateau.png")
    px = im.load()
    x0, y0, x1, y1 = 48, 108, 146, 178                      # the wide stair down to the lane
    lum = lambda p: (p[0] * 299 + p[1] * 587 + p[2] * 114) // 1000
    tread = lambda p: p[3] and lum(p) > 120
    src = im.copy().load()
    for x in range(x0, x1):
        for y in range(y0, y1):
            p = src[x, y]
            if not tread(p):
                continue
            up, dn = src[x, y - 1], src[x, y + 1]
            if not tread(up) and up[3]:                      # under the riser above: a dark shadow row
                q = (int(p[0] * .45), int(p[1] * .45), int(p[2] * .5), 255)
            elif not tread(dn) and dn[3]:                    # the tread's lit front edge
                q = (min(255, int(p[0] * .98)), min(255, int(p[1] * .98)), min(255, int(p[2] * .95)), 255)
            else:                                            # 15% darker overall
                q = (int(p[0] * .8), int(p[1] * .8), int(p[2] * .82), 255)
            px[x, y] = q
    moss = [(52, 70, 40, 255), (66, 88, 48, 255)]
    for k, (mx, my) in enumerate(((70, 150), (104, 131), (88, 160), (118, 140))):   # moss in two joints
        for dx in range(-2, 3):
            for dy in (0, 1):
                x, y = mx + dx, my + dy
                if px[x, y][3] and (dx + dy + k) % 3:
                    px[x, y] = moss[(dx + k) % 2]
    im.save(os.path.join(A, "plateau.png"))


if __name__ == "__main__":
    tavern()
    board()
    stair()
    print("ok")
