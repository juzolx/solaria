"""Hand-built 32-px mannequins (code-drawn guide figures) for img2img + the matching OpenPose skeletons.

back:  three-quarter from behind, turned up-right toward the monster; a sliver of cheek, ear and nose
       shows on the right of the head; weapon (right) hand raised forward-right at shoulder height.
front: facing the viewer (for portraits).
Each is drawn at art-pixel size, then put on a white 1024 canvas at 8x (figure ~256 px tall), which is
the size at which the pixel LoRA draws at true 32-px density.
"""
import sys
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\art_work2")
import poses

SKIN, SKIN_D, SKIN_L = (168, 98, 74), (115, 62, 57), (194, 133, 105)
CLOTH, CLOTH_D, CLOTH_L = (58, 68, 102), (38, 43, 68), (90, 105, 136)
PANT, PANT_D = (52, 50, 59), (31, 29, 36)
BOOT = (90, 63, 53)
OL = (14, 8, 18)
S, OFF = 8, (512 - 20 * 8, 430 - 2 * 8)  # 40x40 art box -> 320x320 on the 1024 canvas


def body_back(d):
    # legs (left leg back-left, right leg forward-right)
    d.polygon([(13, 24), (17, 24), (15, 31), (11, 31)], fill=PANT)
    d.polygon([(19, 24), (23, 24), (24, 29), (20, 30)], fill=PANT_D)
    d.rectangle((10, 31, 14, 32), fill=BOOT); d.rectangle((20, 29, 24, 30), fill=BOOT)
    # torso (back), lit from the top-left
    d.polygon([(10, 15), (25, 14), (24, 25), (12, 25)], fill=CLOTH)
    d.polygon([(19, 14), (25, 14), (24, 25), (19, 25)], fill=CLOTH_D)
    d.line([(11, 15), (18, 15)], fill=CLOTH_L)
    d.rectangle((12, 23, 24, 24), fill=PANT_D)  # belt
    # left arm hanging at the side (near arm, lower-left)
    d.polygon([(8, 16), (11, 15), (11, 22), (8, 23)], fill=CLOTH)
    d.rectangle((7, 23, 10, 25), fill=SKIN)


def head_back(d):
    # big chibi head turned up-right: back of the skull on the left, the face edge on the right
    d.ellipse((9, 1, 25, 15), fill=SKIN_D)
    d.ellipse((10, 1, 24, 14), fill=SKIN)
    d.ellipse((11, 2, 17, 7), fill=SKIN_L)
    d.polygon([(22, 4), (26, 6), (27, 9), (26, 12), (22, 13)], fill=SKIN_L)   # cheek and jaw, lit
    d.point((27, 8), fill=SKIN_L); d.point((28, 8), fill=SKIN)               # nose
    d.rectangle((24, 6, 25, 6), fill=SKIN_D)                                  # brow
    d.point((25, 7), fill=OL)                                                 # eye
    d.ellipse((18, 6, 21, 11), fill=SKIN_D)                                   # ear
    d.point((19, 8), fill=SKIN)


def arm_back(d):
    # weapon arm: shoulder -> elbow out right -> fist forward at shoulder height
    d.polygon([(23, 14), (27, 15), (29, 18), (26, 19), (23, 18)], fill=CLOTH_D)
    d.rectangle((27, 13, 30, 16), fill=SKIN)      # fist


def front(d):
    d.polygon([(12, 24), (16, 24), (15, 31), (12, 31)], fill=PANT)
    d.polygon([(18, 24), (22, 24), (22, 31), (19, 31)], fill=PANT_D)
    d.rectangle((11, 31, 15, 32), fill=BOOT); d.rectangle((19, 31, 23, 32), fill=BOOT)
    d.polygon([(10, 15), (24, 15), (23, 25), (11, 25)], fill=CLOTH)
    d.polygon([(18, 15), (24, 15), (23, 25), (18, 25)], fill=CLOTH_D)
    d.rectangle((11, 23, 23, 24), fill=PANT_D)
    d.polygon([(7, 16), (10, 15), (10, 22), (7, 23)], fill=CLOTH); d.rectangle((6, 23, 9, 25), fill=SKIN)
    d.polygon([(24, 15), (27, 16), (27, 23), (24, 22)], fill=CLOTH_D); d.rectangle((25, 23, 28, 25), fill=SKIN)
    d.ellipse((9, 1, 25, 15), fill=SKIN_D); d.ellipse((10, 1, 23, 13), fill=SKIN); d.ellipse((11, 2, 16, 6), fill=SKIN_L)
    d.rectangle((13, 8, 14, 9), fill=OL); d.rectangle((19, 8, 20, 9), fill=OL)
    d.line([(15, 12), (18, 12)], fill=SKIN_D)
    d.rectangle((8, 7, 9, 10), fill=SKIN_D); d.rectangle((24, 7, 25, 10), fill=SKIN_D)


def outline(im):
    import numpy as np
    a = np.array(im); op = a[..., 3] > 0
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(op, dy, 0), dx, 1)
    a[ring & ~op] = OL + (255,)
    return Image.fromarray(a)


def make(kind):
    im = Image.new("RGBA", (40, 40), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    if kind == "back":
        body_back(d); head_back(d); arm_back(d)
    else:
        front(d)
    im = outline(im.transform(im.size, Image.AFFINE, (1, 0, -4, 0, 1, -2)))  # centre in the 40 box
    return im


def to_canvas(im):
    c = Image.new("RGB", (1024, 1024), (255, 255, 255))
    big = im.resize((im.width * S, im.height * S), Image.NEAREST)
    c.paste(big, OFF, big)
    return c


if __name__ == "__main__":
    for k in ("back", "front"):
        im = make(k)
        im.save(rf"C:\ai\art_work2\mq_{k}_art.png")
        to_canvas(im).save(rf"C:\ai\art_work2\mq_{k}.png")
    # skeletons in the same frame (art px * 8 + offset); the 200x256 pose box maps to art (x/8+...)
    print("ok")
