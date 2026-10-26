"""Fable town round 4 art: the empty lot's "build here" motif from the old top-down town (a yellow
sign on a post with a hammer-and-saw mark, and a stack of planks), so a lot reads as a plot to
build on, not ploughed dirt. Usage: py fix_r4_art.py"""
import os
from PIL import Image, ImageDraw

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "art")
INK = (18, 14, 22, 255)


def sign():
    im = Image.new("RGBA", (30, 34), (0, 0, 0, 0))           # a 28x17 yellow board on a post
    d = ImageDraw.Draw(im)
    wood, dark = (107, 68, 35, 255), (62, 40, 22, 255)
    d.rectangle([13, 16, 16, 33], fill=INK)
    d.rectangle([14, 17, 15, 32], fill=wood)
    d.rectangle([0, 0, 29, 18], fill=INK)
    d.rectangle([1, 1, 28, 17], fill=(232, 197, 71, 255))
    d.line([1, 17, 28, 17], fill=(176, 140, 40, 255))
    d.line([1, 1, 28, 1], fill=(250, 226, 128, 255))
    for k in range(3):                                       # the hazard strokes of the old lot sign
        x = 5 + k * 8
        d.line([x, 14, x + 5, 4], fill=(42, 36, 32, 255), width=2)
    d.line([13, 33, 17, 33], fill=dark)
    os.makedirs(os.path.join(A, "props48"), exist_ok=True)
    im.save(os.path.join(A, "props48", "p20.png"))


def planks():
    im = Image.new("RGBA", (28, 16), (0, 0, 0, 0))           # three planks stacked on the ground, running along the lot's edge
    d = ImageDraw.Draw(im)
    for k, col in enumerate(((140, 104, 58, 255), (158, 118, 66, 255), (176, 132, 76, 255))):
        y = 10 - k * 3                                       # bottom plank first
        top = [(2, y), (18, y - 8), (25, y - 5), (9, y + 3)]  # the plank's top face, iso (2:1)
        d.polygon([(1, y), (18, y - 9), (26, y - 5), (26, y - 3), (9, y + 5), (1, y + 1)], fill=INK)
        d.polygon(top, fill=col)
        d.line([(9, y + 4), (25, y - 4)], fill=(96, 70, 40, 255))   # its front edge in shade
        d.line([(4, y), (17, y - 6)], fill=(200, 160, 100, 255))    # the grain
    im.save(os.path.join(A, "props48", "p21.png"))


if __name__ == "__main__":
    sign()
    planks()
    print("ok")
