"""Round 3b heroes: per-race silhouettes (guides4), AI bodies, code faces/hands, rule passes, 32 and 48 px."""
import sys
import numpy as np
from PIL import Image
sys.path.insert(0, r"C:\ai\scripts"); sys.path.insert(0, r"C:\ai\art_work3")
import pixlib as P, heroes2 as H2, details as D
import guides4 as G

P.HUE_W = np.array([1.0, 2.2, 2.2]); P.SHADOW_CHROMA = 0.07
RAW = "C:/ai/art_raw/"
WIN = {48: (31, 37, 95, 101), 32: (42, 48, 84, 90)}
SEED = {("dwarf", "back", 32): 851, ("orc", "back", 32): 852, ("goblin", "front", 32): 852,
        ("goblin", "back", 48): 852, ("orc", "back", 48): 852, ("elf", "front", 48): 852}  # default 851
_cache = {}


def native(name, size):
    if (name, size) not in _cache:
        raw, nobg, grid, nat = P.native_of(RAW + name + ".png")
        _cache[(name, size)] = P.to_im(P.keep_largest(P.to_np(nat.crop(WIN[size])), 0.05))
    return _cache[(name, size)]


def guide(race, view, size):
    g = Image.open(rf"C:\ai\art_work3\g4_{race}_{view}_{size}.png").convert("RGBA")
    return g


def align(im, g):
    """Best (dx, dy) in [-3, 3] so the guide's silhouette matches the AI sprite."""
    a = P.to_np(im)[..., 3] > 0
    b = np.zeros_like(a); gb = P.to_np(g)[..., 3] > 0
    h = min(a.shape[0], gb.shape[0]); w = min(a.shape[1], gb.shape[1])
    b[:h, :w] = gb[:h, :w]
    best = (0, 0, -1)
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            s = (a & np.roll(np.roll(b, dy, 0), dx, 1)).sum()
            if s > best[2]:
                best = (dx, dy, s)
    return best[0], best[1]


def anchors(race, view, size):
    p = G.R[race]
    k = 1.0 if size == 48 else 2 / 3
    top = G.FEET - p["h"]; hy0, hy1 = top, top + p["hh"]
    fwd = 2 if race == "goblin" else 0
    hx0, hx1 = G.CX - p["hw"] // 2 + fwd, G.CX + p["hw"] - p["hw"] // 2 + fwd
    if view == "front":
        return int(((hx0 + hx1) / 2) * k), int((hy0 + p["hh"] * 0.55) * k)
    return int((hx1 - 1) * k), int((hy0 + p["hh"] * 0.5) * k)


def clean(name, size, colours=None):
    n = native(name, size)
    im = H2.strip_shadow_fixed(n)
    im = P.to_im(H2.despeckle(P.to_np(im)))
    return H2.denoise(P.quantize(im, colours or (16 if size == 32 else 22)))


NAMES = {("dwarf", "back", 32): "v4_dwarf_back_32b_s872"}


def clip_to_guide(im, g, dx, dy, grow=2):
    """Rule pass: drop AI extras (stray shields, quivers) outside the guide silhouette grown by 2 px."""
    a = P.to_np(im).copy()
    gb = np.zeros(a.shape[:2], bool)
    ga = P.to_np(g)[..., 3] > 0
    h = min(gb.shape[0], ga.shape[0]); w = min(gb.shape[1], ga.shape[1])
    gb[:h, :w] = ga[:h, :w]
    gb = np.roll(np.roll(gb, dy, 0), dx, 1)
    for _ in range(grow):
        gb = gb | np.roll(gb, 1, 0) | np.roll(gb, -1, 0) | np.roll(gb, 1, 1) | np.roll(gb, -1, 1)
    a[~gb, 3] = 0
    return P.to_im(a)


def hero(race, view="back", size=32, name=None, seed=851, faces=True):
    name = name or NAMES.get((race, view, size)) or f"v4_{race}_{view}_{size}_s{SEED.get((race, view, size), seed)}"
    im = clean(name, size)
    g = guide(race, view, size)
    dx, dy = align(im, g)
    im = clip_to_guide(im, g, dx, dy, grow=1)
    if race == "dwarf" and view == "back":   # from behind a dwarf shows hair under the helmet, never a face
        a = P.to_np(im).copy()
        top = G.FEET - G.R["dwarf"]["h"]; k = 1.0 if size == 48 else 2 / 3
        y1 = int((top + G.R["dwarf"]["hh"] + 2) * k) + dy
        lab = P.oklab(a[..., :3].astype(float))
        skin = (a[..., 3] > 0) & (lab[..., 1] > 0.02) & (lab[..., 0] > 0.55)
        skin[y1:] = False
        L = lab[..., 0][skin]
        if len(L):
            hair = np.array([(115, 62, 57), (143, 86, 59), (184, 111, 80)])
            idx = np.clip(((L - L.min()) / max(1e-6, L.max() - L.min()) * 2.99).astype(int), 0, 2)
            a[..., :3][skin] = hair[idx]
        im = P.to_im(a)
    if race == "goblin":   # the AI greys the big ears: put them back on the goblin's yellow-green skin ramp
        a = P.to_np(im).copy()
        top = G.FEET - G.R["goblin"]["h"]; k = 1.0 if size == 48 else 2 / 3
        y1 = int((top + G.R["goblin"]["hh"]) * k) + dy
        lab = P.oklab(a[..., :3].astype(float)); ch = np.hypot(lab[..., 1], lab[..., 2])
        grey = (a[..., 3] > 0) & (ch < 0.05) & (lab[..., 0] > 0.42) & ~np.all(a[..., :3] == P.OUTLINE, -1)
        grey[y1:] = False
        L = lab[..., 0][grey]
        if len(L):
            ramp = np.array([(62, 137, 72), (117, 167, 67), (168, 202, 88)])
            idx = np.clip(((L - L.min()) / max(1e-6, L.max() - L.min()) * 2.99).astype(int), 0, 2)
            a[..., :3][grey] = ramp[idx]
        im = P.to_im(a)
    if faces:
        x, y = anchors(race, view, size)
        if view == "front":
            im = D.face_front(im, race, x + dx, y + dy, size)
        else:
            im = D.face_back(im, race, x + dx, y + dy, size)
    return D.rule_passes(P.rim(P.outline(im)))
