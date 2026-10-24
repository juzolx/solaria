"""Style test v2 (dark chibi): back three-quarter battle heroes + front portraits, layered.

Every sprite is img2img (denoise 0.5-0.55) from one code-drawn mannequin (C:/ai/art_work2/mannequin.py),
with IP-Adapter style transfer from art/enemies/draugr.png (weight 0.3). So every race, outfit and look
lands in the same 40x42 native window and the layers line up.

Layers, bottom to top:  body (race)  ->  outfit (below the neck)  ->  weapon arm (cut out, rotatable)
                        -> weapon (pinned to the fist, rotates with the arm).
"""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P

RAW = "C:/ai/art_raw/"
WIN = (46, 49, 86, 91)
PICK = {
    "race": {"human": "v2r_human_s732", "elf": "v2r_elf_s732", "orc": "v2r_orc_s731", "dwarf": "v2r_dwarf_s732", "goblin": "v2r_goblin_s731"},
    "outfit": {("warrior", "tall"): "v2o_warrior_tall_s732", ("warrior", "short"): "v2o_warrior_short_s731",
               ("mage", "tall"): "v2o_mage_tall_s731", ("mage", "short"): "v2o_mage_short_s732",
               ("ranger", "tall"): "v2o_ranger_tall_s732", ("ranger", "short"): "v2o_ranger_short_s731",
               "B": "v2var_B_s731", "C": "v2var_C_s731"},
    "front": {"human": "v2f_human_s731", "elf": "v2f_elf_s731", "orc": "v2f_orc_s731", "dwarf": "v2f_dwarf_s731", "goblin": "v2f_goblin_s731"},
}
BUILD = {"human": "tall", "elf": "tall", "orc": "tall", "dwarf": "short", "goblin": "short"}
NECK = {"tall": 17, "short": 21}
# the weapon arm (window coords): a box right of the torso, and its shoulder pivot and fist
ARM_BOX = {"tall": (26, 9, 40, 20), "short": (27, 15, 40, 25)}
SHOULDER = {"tall": (26, 15), "short": (27, 20)}
FIST = {"tall": (32, 11), "short": (33, 17)}
# dark-chibi grade: pull every colour a little darker/cooler before the palette snap
GRADE = np.array([0.94, 0.95, 1.0])

_cache = {}


def native(name):
    if name not in _cache:
        raw, nobg, grid, nat = P.native_of(RAW + name + ".png")
        win = nat.crop(WIN)
        _cache[name] = (raw, P.to_im(P.keep_largest(P.to_np(win), 0.05)))
    return _cache[name]


def strip_shadow_fixed(im):
    bb = im.getbbox()
    f = P.strip_shadow(im.crop(bb))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(f, (bb[0], bb[1]))
    return out


def despeckle(a):
    """Drop single opaque pixels with <= 1 opaque 4-neighbour (stray AI pixels)."""
    op = a[..., 3] > 0
    n = sum(np.roll(np.roll(op, dy, 0), dx, 1).astype(int) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    a = a.copy(); a[op & (n <= 1), 3] = 0
    return a


def grade(im, g=GRADE, sat=0.85):
    a = P.to_np(im).copy().astype(float)
    rgb = a[..., :3]
    lum = rgb.mean(-1, keepdims=True)
    rgb = (lum + (rgb - lum) * sat) * g
    a[..., :3] = np.clip(rgb, 0, 255)
    return P.to_im(a.astype(np.uint8))


def denoise(im, passes=2):
    """In-sprite noise: a pixel unlike all 4 neighbours, where >= 3 neighbours agree, takes their colour."""
    a = P.to_np(im).copy()
    h, w = a.shape[:2]
    for _ in range(passes):
        src = a.copy()
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if src[y, x, 3] == 0:
                    continue
                nb = [tuple(src[y + dy, x + dx]) for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                me = tuple(src[y, x])
                if me in nb:
                    continue
                best = max(set(nb), key=nb.count)
                if nb.count(best) >= 3 and best[3] > 0:
                    a[y, x] = best
    return P.to_im(a)


def clean(name, max_colors=16, g=GRADE, sat=1.0):
    im = strip_shadow_fixed(native(name)[1])
    im = P.to_im(despeckle(P.to_np(im)))
    return denoise(P.quantize(grade(im, g, sat), max_colors))


def outfit_layer(o, build, skin_src):
    a = P.to_np(o).copy()
    a[:NECK[build], :, 3] = 0
    # drop the mannequin's own skin (hands) so the race's skin shows
    face = P.to_np(skin_src)[NECK[build] - 12:NECK[build]]
    op = face[..., 3] > 0
    lab = P.oklab(face[..., :3][op].astype(float))
    ch = np.hypot(lab[:, 1], lab[:, 2])
    skin = lab[(lab[:, 0] > 0.55) & (ch > 0.025) & (lab[:, 1] > 0.0)]
    if len(skin):
        L = P.oklab(a[..., :3].astype(float))
        m = np.zeros(a.shape[:2], bool)
        for s in np.unique(np.round(skin, 3), axis=0):
            m |= ((L - s) ** 2).sum(-1) < 0.05 ** 2
        a[m & (a[..., 3] > 0), 3] = 0
    return P.to_im(a)


def layers(race, outfit_name=None, look=None):
    """-> (base without the weapon arm, arm layer), both window-sized RGBA, not yet outlined."""
    build = BUILD[race]
    if look in ("B", "C"):  # look variants are whole sprites (their own head), not layered
        img = clean(PICK["outfit"][look], max_colors=20, g=GRADE * (0.82 if look == "C" else 1.0))
        img = fix_face(reskin(img, race, slice(0, NECK[build])), race) if look == "C" else reskin(img, race, slice(0, NECK[build]))
        a = P.to_np(img)
        x0, y0, x1, y1 = ARM_BOX[build]
        arm = np.zeros_like(a); arm[y0:y1, x0:x1] = a[y0:y1, x0:x1]
        base = a.copy(); base[y0:y1, x0:x1, 3] = 0
        return P.to_im(base), P.to_im(arm)
    body = clean(PICK["race"][race], max_colors=20)
    body = fix_face(reskin(body, race, slice(0, NECK[build])), race)
    img = body.copy()
    if outfit_name:
        key = look or (outfit_name, build)
        o = clean(PICK["outfit"][key], max_colors=20, g=GRADE * (0.85 if look == "C" else 1.0))
        ba, oa = P.to_np(img).copy(), P.to_np(o)
        clip = oa[..., 3] == 0
        clip[:NECK[build]] = False
        ba[clip, 3] = 0
        img = P.to_im(ba)
        img.alpha_composite(outfit_layer(o, build, o))
    a = P.to_np(img)
    x0, y0, x1, y1 = ARM_BOX[build]
    arm = np.zeros_like(a); arm[y0:y1, x0:x1] = a[y0:y1, x0:x1]
    base = a.copy(); base[y0:y1, x0:x1, 3] = 0
    return P.to_im(base), P.to_im(arm)


def _c(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# race -> hand-placed pixels (x, y, colour) in window coords: the sliver of face seen over the shoulder
FACE = {
    "human": [(26, 11, _c("733e39")), (26, 12, _c("733e39")), (28, 11, _c("2a1a1e")), (28, 12, _c("c28569")), (28, 13, _c("a8624a"))],
    "elf": [(28, 10, _c("e8b796")), (29, 9, _c("e8b796")), (30, 8, _c("c28569")), (28, 12, _c("2a1a1e")), (28, 13, _c("e8b796"))],
    "orc": [(26, 12, _c("566a56")), (28, 12, _c("a22633")), (28, 15, _c("f4e6c4")), (28, 14, _c("7f9478"))],
    "dwarf": [(28, 15, _c("c28569")), (28, 16, _c("2a1a1e")), (29, 17, _c("8f563b")), (29, 18, _c("733e39")), (28, 19, _c("8f563b"))],
    "goblin": [(27, 16, _c("fee761")), (27, 17, _c("3e8948")), (28, 18, _c("f4e6c4"))],
}


def fix_face(im, race):
    a = P.to_np(im).copy()
    for x, y, c in FACE.get(race, []):
        a[y, x, :3] = c; a[y, x, 3] = 255
    return P.to_im(a)


def finish(im):
    """Outline + top-left rim on a composed frame (pads by 1 px)."""
    return P.rim(P.outline(im))


def fist_of(im, build):
    """The weapon fist: the right-most opaque pixel in the arm band (found, not hard-coded)."""
    a = P.to_np(im)
    x0, y0, x1, y1 = ARM_BOX[build]
    band = a[y0 - 4:y1, :, 3] > 0
    ys, xs = np.where(band)
    i = xs.argmax()
    return int(xs[i]) - 1, int(ys[i]) + y0 - 4

# muted skin ramps from the palette, dark -> light (runtime recolour target for bald heads and hands)
SKIN = {
    "human": ["2a1a1e", "5a3f35", "a8624a", "c28569", "e8b796"],
    "orc": ["193c3e", "566a56", "7f9478", "a8b89a", "d0dcc8"],
    "goblin": ["193c3e", "265c42", "3e8948", "75a743", "a8ca58"],
}


def reskin(im, race, rows):
    """Recolour the skin-like pixels in `rows` (head) by luminance rank onto the race's skin ramp."""
    if race not in SKIN:
        return im
    a = P.to_np(im).copy()
    ramp = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in SKIN[race]]
    sub = a[rows]
    op = (sub[..., 3] > 0) & ~np.all(sub[..., :3] == P.OUTLINE, -1)
    lab = P.oklab(sub[..., :3].astype(float))
    ch = np.hypot(lab[..., 1], lab[..., 2])
    m = op & (ch < 0.09) & (lab[..., 0] > 0.30)
    if m.sum() < 5:
        return im
    L = lab[..., 0][m]
    lo, hi = np.percentile(L, 3), np.percentile(L, 97)
    idx = np.clip(((L - lo) / max(1e-6, hi - lo) * 3.99).astype(int) + 1, 1, 4)
    vals = np.array(ramp)[idx]
    sub[m, :3] = vals
    a[rows] = sub
    return P.to_im(a)
