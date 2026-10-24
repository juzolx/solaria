"""Round 3 heroes: look B slim armour + look C dark head treatment, race heads readable from behind
(hair, ear tips, topknot + tusk, iron cap + beard, huge ears). Same window / cleanup as heroes2.
Layers: head (race, above the neck) + armour body (one shared sprite per build) + weapon arm."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P
import heroes2 as H2

PICK = {"human": "v3_human_s811", "elf": "v3_elf_s813", "orc": "v3_orc_s811", "dwarf": "v3b_dwarf_s822", "goblin": "v3_goblin_s812"}
ARMOUR = {"tall": "v3_human_s811", "short": "v3b_dwarf_s822"}
FRONT = {"human": "v3f_human_s811", "elf": "v2f_elf_s731", "orc": "v2f_orc_s731", "dwarf": "v2f_dwarf_s731", "goblin": "v2f_goblin_s731"}
BUILD = {"human": "tall", "elf": "tall", "orc": "tall", "dwarf": "short", "goblin": "short"}
NECK = {"tall": 18, "short": 19}
ARM_BOX = {"tall": (27, 11, 40, 22), "short": (28, 12, 40, 24)}
SHOULDER = {"tall": (27, 18), "short": (28, 19)}
FACE = {}


P.HUE_W = np.array([1.0, 2.2, 2.2])   # round 3: keep hues through the palette snap
P.SHADOW_CHROMA = 0.07


def clean(name):
    return H2.clean(name, max_colors=24, g=np.array([1.0, 1.0, 1.0]), sat=1.0)


def layers(race, layered=True):
    b = BUILD[race]
    head = clean(PICK[race])
    if layered and race not in ("human", "dwarf"):
        body = clean(ARMOUR[b])
        ha, ba = P.to_np(head).copy(), P.to_np(body).copy()
        ba[:NECK[b]] = 0          # armour below the neck
        ha[NECK[b]:] = 0          # race head above the neck
        img = P.to_im(ba); img.alpha_composite(P.to_im(ha))
    else:
        img = head
    a = P.to_np(img)
    x0, y0, x1, y1 = ARM_BOX[b]
    arm = np.zeros_like(a); arm[y0:y1, x0:x1] = a[y0:y1, x0:x1]
    base = a.copy(); base[y0:y1, x0:x1, 3] = 0
    return P.to_im(base), P.to_im(arm)


def fist_of(im, b):
    a = P.to_np(im); x0, y0, x1, y1 = ARM_BOX[b]
    ys, xs = np.where(a[y0 - 4:y1, :, 3] > 0)
    i = xs.argmax()
    return int(xs[i]) - 1, int(ys[i]) + y0 - 4


def portrait(race):
    f = clean(FRONT[race])
    return P.rim(P.outline(f))
