"""Fable town round 3 art: three curtain-wall variants plus an arrow-slit segment (no more one
segment pasted 40 times), the Hardcore graveyard's big pieces (sarcophagus, obelisk, mausoleum),
and a hanging cage for the gate road. Usage: py fix_r3_art.py"""
import os
import random
from PIL import Image, ImageDraw

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "art")
INK = (18, 14, 22, 255)


def foot(x):
    """The wall run's front foot: y of its bottom edge at x (the face runs 10..75)."""
    return 70 + (x - 10) * 27 / 65


def is_moss(p):
    r, g, b, a = p
    return a and g >= r and b < r      # moss is warm green-grey; the stone is blue-grey


def walls():
    base = Image.open(os.path.join(A, "wall_run.png")).convert("RGBA")
    rng = random.Random(5)
    # B: moss only on the left third, a cracked block mid-course
    b = base.copy()
    px = b.load()
    for y in range(b.height):
        for x in range(28, b.width):
            if is_moss(px[x, y]) and y >= 6:
                px[x, y] = px[x, y - 6] if not is_moss(px[x, y - 6]) else px[x, y - 12]
    x, y = 46, int(foot(46)) - 30
    for k in range(16):                                      # a zigzag crack down three courses
        px[x, y] = INK
        px[x + 1, y] = (70, 70, 80, 255)
        x += rng.choice((-1, 0, 1))
        y += 1
    b.save(os.path.join(A, "wall_run_b.png"))
    # C: no moss, a drain hole at the foot and a dark stain running from it
    c = base.copy()
    px = c.load()
    for y in range(c.height):
        for x in range(c.width):
            if is_moss(px[x, y]) and y >= 6:
                px[x, y] = px[x, y - 6] if not is_moss(px[x, y - 6]) else px[x, y - 12]
    d = ImageDraw.Draw(c)
    hx = 56
    hy = int(foot(hx)) - 9
    d.rectangle([hx, hy, hx + 3, hy + 2], fill=INK)
    d.point((hx + 1, hy - 1), fill=INK)
    d.point((hx + 2, hy - 1), fill=INK)
    for yy in range(hy + 3, int(foot(hx)) + 1):              # the stain below it, darkening the stone
        for xx in (hx + 1, hx + 2):
            r, g, bb, a = px[xx, yy]
            if a:
                px[xx, yy] = (int(r * .55), int(g * .6), int(bb * .55), a)
    c.save(os.path.join(A, "wall_run_c.png"))
    # an arrow slit mid-wall (on variant A's moss)
    s = base.copy()
    d = ImageDraw.Draw(s)
    sx = 40
    sy = int(foot(sx)) - 34
    d.rectangle([sx - 1, sy - 1, sx + 2, sy + 9], fill=(120, 120, 130, 255))
    d.rectangle([sx, sy, sx + 1, sy + 8], fill=INK)
    d.line([sx - 2, sy + 4, sx + 3, sy + 4], fill=INK)
    s.save(os.path.join(A, "wall_run_slit.png"))


def graveyard():
    im = Image.new("RGBA", (24, 20), (0, 0, 0, 0))           # a stone sarcophagus with a lid line
    d = ImageDraw.Draw(im)
    st, sh, lt = (128, 128, 138, 255), (78, 78, 90, 255), (162, 162, 170, 255)
    d.polygon([(2, 9), (12, 4), (22, 9), (12, 14)], fill=INK)
    d.polygon([(3, 9), (12, 5), (21, 9), (12, 13)], fill=lt)
    d.polygon([(2, 9), (12, 14), (12, 19), (2, 14)], fill=INK)
    d.polygon([(3, 10), (12, 14), (12, 18), (3, 14)], fill=st)
    d.polygon([(12, 14), (22, 9), (22, 14), (12, 19)], fill=INK)
    d.polygon([(12, 14), (21, 10), (21, 14), (12, 18)], fill=sh)
    d.line([(3, 11), (12, 15)], fill=sh)
    d.line([(12, 15), (21, 11)], fill=(56, 56, 66, 255))
    os.makedirs(os.path.join(A, "props48"), exist_ok=True)
    im.save(os.path.join(A, "props48", "p16.png"))
    im = Image.new("RGBA", (16, 28), (0, 0, 0, 0))           # an obelisk
    d = ImageDraw.Draw(im)
    d.polygon([(7, 1), (10, 5), (10, 23), (4, 23), (4, 5)], fill=INK)
    d.polygon([(7, 2), (9, 5), (9, 22), (7, 22)], fill=sh)
    d.polygon([(7, 2), (5, 5), (5, 22), (7, 22)], fill=lt)
    d.rectangle([2, 22, 12, 26], fill=INK)
    d.rectangle([3, 23, 11, 25], fill=st)
    d.line([3, 23, 11, 23], fill=lt)
    im.save(os.path.join(A, "props48", "p17.png"))
    im = Image.new("RGBA", (28, 26), (0, 0, 0, 0))           # a mausoleum front against the wall
    d = ImageDraw.Draw(im)
    d.polygon([(1, 8), (14, 1), (27, 8)], fill=INK)
    d.polygon([(3, 8), (14, 2), (25, 8)], fill=(96, 96, 108, 255))
    d.rectangle([2, 8, 26, 25], fill=INK)
    d.rectangle([3, 9, 25, 24], fill=st)
    for x in (5, 21):                                        # two columns
        d.rectangle([x, 9, x + 2, 24], fill=lt)
        d.line([x + 2, 9, x + 2, 24], fill=sh)
    d.rectangle([10, 13, 18, 24], fill=INK)                  # the iron door
    d.rectangle([11, 14, 17, 24], fill=(40, 36, 44, 255))
    for x in (12, 14, 16):
        d.line([x, 14, x, 24], fill=(70, 66, 74, 255))
    d.line([3, 24, 25, 24], fill=sh)
    im.save(os.path.join(A, "props48", "p18.png"))


def cage():
    im = Image.new("RGBA", (22, 34), (0, 0, 0, 0))           # a gibbet: post, arm, a hanging iron cage
    d = ImageDraw.Draw(im)
    wood, dark = (92, 64, 40, 255), (52, 36, 24, 255)
    d.rectangle([2, 2, 5, 33], fill=INK)
    d.rectangle([3, 3, 4, 32], fill=wood)
    d.rectangle([2, 2, 19, 5], fill=INK)
    d.rectangle([3, 3, 18, 4], fill=wood)
    d.line([16, 5, 16, 9], fill=INK)
    d.rectangle([12, 9, 20, 23], outline=INK)
    for x in (14, 16, 18):
        d.line([x, 10, x, 22], fill=(62, 60, 68, 255))
    d.line([12, 16, 20, 16], fill=(62, 60, 68, 255))
    d.line([2, 33, 6, 33], fill=dark)
    im.save(os.path.join(A, "props48", "p19.png"))


if __name__ == "__main__":
    walls()
    graveyard()
    cage()
    print("ok")
