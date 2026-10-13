"""The hero's layers, drawn natively at 64x64 (v0.11 "style A").

Every function returns a Canvas (art_native.py). make_art.py renders them in
key colors. The body records which pixels belong to which body part
(head, torso, arms, legs...) so armor can be built to fit it exactly.
"""
import numpy as np
from scipy.ndimage import binary_dilation
from art_native import Canvas

# ----------------------------------------------------------------------------
# Body landmarks (feet on row 63, facing right)
# ----------------------------------------------------------------------------
HEAD = {"masc": (32.0, 18.5, 8.0, 8.5), "fem": (32.0, 18.5, 7.8, 8.3)}
HAND = {"masc": (41, 47), "fem": (40, 47)}       # front (weapon) hand
OFF_HAND = {"masc": (24, 46), "fem": (25, 46)}   # back hand (shields, books)
SPHERE = (31.5, 17.5, 10.5)                       # the head-and-hair ball for lighting

BODY = {
    "masc": {
        "neck": [(29, 26), (35, 26), (36, 30), (28, 30)],
        "torso": [(25, 30), (39, 30), (38, 37), (36, 43), (28, 43), (26, 37)],
        "sh_b": (25.5, 31.5, 3.4, 2.6), "sh_f": (38.5, 31.5, 3.4, 2.6),
        "uarm_b": [(23, 32), (26, 32), (26, 39), (23, 39)],
        "farm_b": [(23, 39), (26, 39), (26, 45), (23, 45)],
        "hand_b": (24.5, 46.3, 1.8, 1.7),
        "uarm_f": [(38, 33), (41, 33), (41, 39), (38, 39)],
        "farm_f": [(38, 39), (41, 39), (42, 45), (39, 45)],
        "hand_f": (40.8, 46.8, 2.0, 1.8),
        "hips": [(27, 43), (37, 43), (38, 48), (26, 48)],
        "thigh_b": [(28, 47), (31, 47), (31, 53), (27, 53)],
        "calf_b": [(27, 53), (31, 53), (30, 59), (28, 59)],
        "foot_b": [(27, 59), (31, 59), (31, 63), (26, 63)],
        "thigh_f": [(33, 47), (36, 47), (37, 53), (33, 53)],
        "calf_f": [(33, 53), (37, 53), (36, 58), (34, 58)],
        "foot_f": [(33, 58), (37, 58), (39, 61), (39, 63), (33, 63)],
        "jaw": [(34, 24), (38, 22), (37, 25), (35, 26)],
    },
    "fem": {
        "neck": [(30, 26), (34, 26), (35, 30), (29, 30)],
        "torso": [(26, 30), (38, 30), (37, 36), (35, 41), (29, 41), (27, 36)],
        "sh_b": (26.5, 31.5, 2.8, 2.2), "sh_f": (37.5, 31.5, 2.8, 2.2),
        "uarm_b": [(24, 32), (26, 32), (26, 39), (24, 39)],
        "farm_b": [(24, 39), (26, 39), (26, 45), (24, 45)],
        "hand_b": (25.0, 46.2, 1.6, 1.6),
        "uarm_f": [(38, 33), (40, 33), (40, 39), (38, 39)],
        "farm_f": [(38, 39), (40, 39), (41, 45), (39, 45)],
        "hand_f": (40.0, 46.8, 1.8, 1.7),
        "hips": [(27, 41), (37, 41), (39, 48), (25, 48)],
        "thigh_b": [(27, 47), (31, 47), (31, 53), (27, 53)],
        "calf_b": [(27, 53), (31, 53), (30, 59), (28, 59)],
        "foot_b": [(27, 59), (31, 59), (31, 63), (26, 63)],
        "thigh_f": [(33, 47), (37, 47), (37, 53), (33, 53)],
        "calf_f": [(33, 53), (37, 53), (36, 58), (34, 58)],
        "foot_f": [(33, 58), (37, 58), (39, 61), (39, 63), (33, 63)],
        "chest": [(33, 33), (37, 33), (36, 36), (33, 36)],
    },
}

# Plain clothes everyone wears under their gear (final colors)
SHIRT = ['#e9d8b4', '#d8c096', '#b8996f', '#86684e', '#4a3a33']
PANTS = ['#8b9bb4', '#6a7a99', '#4f5d80', '#36405e', '#232944']
SHOES = ['#b86f50', '#9a5a40', '#733e39', '#4a2a2a', '#2a1d26']
BELT = ['#9c5a40', '#8a4e3c', '#733e39', '#4a2a2a', '#2a1d26']
LIPS = '#c4605a'
WHITE = '#fbfbff'
DARK = '#20203a'


def body(kind):
    """The bare hero in plain clothes. Skin = 's' (key), eyes = 'e' (key)."""
    b = BODY[kind]
    c = Canvas()
    c.form = {"c", "p", "l", "k"}
    c.nohi = {"c", "p"}
    # back arm and back leg first, so the torso and front leg cover them
    c.poly(b["uarm_b"], "c", reg="uarm_b")
    c.line([(b["uarm_b"][0][0], 34), (b["uarm_b"][0][0], 38)], "c", 3, reg="uarm_b")
    c.poly(b["farm_b"], "s", reg="farm_b")
    c.line([(b["farm_b"][0][0], 41), (b["farm_b"][0][0], 44)], "s", 3, reg="farm_b")
    c.ell(*b["hand_b"], "s", reg="hand_b")
    c.poly(b["thigh_b"], "p", reg="thigh_b")
    c.poly(b["calf_b"], "p", reg="calf_b")
    c.line([(28, 49), (28, 58)], "p", 3, reg="calf_b")
    c.poly(b["foot_b"], "l", reg="foot_b")
    c.line([(26, 61), (31, 61)], "l", 1, reg="foot_b")
    c.poly(b["thigh_f"], "p", reg="thigh_f")
    c.poly(b["calf_f"], "p", reg="calf_f")
    c.line([(36, 48), (36, 57)], "p", 3, reg="calf_f")
    c.poly(b["foot_f"], "l", reg="foot_f")
    c.line([(33, 60), (37, 60)], "l", 1, reg="foot_f")
    # hips, pants top, belt
    c.poly(b["hips"], "p", reg="hips")
    hy = b["hips"][0][1]
    c.line([(b["hips"][0][0], hy), (b["hips"][1][0], hy)], "k", reg="hips")
    c.line([(b["hips"][0][0], hy + 1), (b["hips"][1][0], hy + 1)], "k", 3, reg="hips")
    c.P(31, hy, "g", 1, reg="hips")
    c.P(32, hy, "g", 1, reg="hips")
    # torso: a simple tunic
    c.poly(b["torso"], "c", reg="torso")
    c.ell(*b["sh_b"], "c", reg="torso")
    c.ell(*b["sh_f"], "c", reg="torso")
    c.line([(32, 32), (32, hy - 2)], "c", 2, reg="torso")
    if kind == "fem":
        c.poly(b["chest"], "c", reg="torso")
        c.line([(34, 37), (36, 36)], "c", 3, reg="torso")
    else:
        c.line([(28, 36), (31, 37)], "c", 3, reg="torso")
        c.line([(33, 37), (37, 36)], "c", 3, reg="torso")
    # collar
    c.line([(30, 30), (32, 32), (34, 30)], "c", 3, reg="torso")
    # neck and head
    c.poly(b["neck"], "s", reg="neck")
    c.line([(b["neck"][0][0], 29), (b["neck"][1][0], 29)], "s", 3, reg="neck")
    hx, hy0, rx, ry = HEAD[kind]
    c.ell(hx, hy0, rx, ry, "s", reg="head")
    if kind == "masc":
        c.poly(b["jaw"], "s", reg="head")
    else:
        c.ell(35, 23, 3, 2.5, "s", reg="head")
    c.ell(25.5, 19.5, 1.5, 2.3, "s", reg="ear")
    c.P(25, 19, "s", 3, reg="ear")
    c.P(25, 20, "s", 3, reg="ear")
    # front arm
    c.poly(b["uarm_f"], "c", reg="uarm_f")
    c.line([(b["uarm_f"][1][0] - 1, 34), (b["uarm_f"][1][0] - 1, 38)], "c", 3, reg="uarm_f")
    c.poly(b["farm_f"], "s", reg="farm_f")
    c.line([(b["farm_f"][1][0], 40), (b["farm_f"][1][0], 44)], "s", 3, reg="farm_f")
    c.P(b["farm_f"][0][0] + 1, 40, "s", 1, reg="farm_f")
    c.ell(*b["hand_f"], "s", reg="hand_f")
    face(c, kind)
    return c


def face(c, kind):
    """Eyes 3 wide and 2 tall under a dark lid (a sclera, a 2-pixel iris in the
    eye key, a glint), the far eye narrower; brows in the hair key; a small nose
    and mouth. Eyes sit halfway down the head; the ear sits between the eye line
    and the nose tip."""
    # front eye
    for x in (35, 36, 37):
        c.P(x, 17, "x")
    c.P(35, 18, "w")
    c.P(36, 18, "e")
    c.P(37, 18, "x")
    c.P(35, 19, "w")
    c.P(36, 19, "e")
    c.P(37, 19, "e")
    c.P(36, 18, "y")  # glint, top-left of the iris
    # far eye (turned away): 2 wide
    c.P(30, 17, "x")
    c.P(31, 17, "x")
    c.P(30, 18, "e")
    c.P(31, 18, "x")
    c.P(30, 19, "e")
    c.P(31, 19, "e")
    # brows take the hair color; the front brow tilts a touch for life
    c.line([(34, 15), (36, 15), (38, 14)], "h", 3)
    c.line([(29, 15), (32, 15)], "h", 3)
    # nose and mouth
    c.P(35, 21, "s", 3)
    c.P(36, 22, "s", 3)
    c.P(34, 24, "q")
    c.P(35, 24, "q")
    if kind == "fem":
        c.P(38, 16, "x")
        c.P(38, 17, "x")
        c.P(29, 16, "x")
        c.P(37, 22, "q")
        c.P(31, 25, "s", 2)


def clean_head(c, tones):
    """Faces read better flat: a base tone, a soft shadow on the far edge and
    under the jaw, the neck in shadow under the chin."""
    for y in range(3, 31):
        for x in range(18, 46):
            if c.g[y][x] != "s" or (x, y) in c.tone:
                continue
            r = c.reg[y][x]
            if r == "neck":
                tones[y, x] = 3 if y <= 27 else 2
                continue
            if r not in ("head",):
                continue
            t = 1
            if x + 1 < 64 and c.g[y][x + 1] != "s":
                t = 2
            if y + 1 < 64 and c.g[y + 1][x] not in ("s", "e", "x", "w", "q"):
                t = 2
            if x <= 26:
                t = 1
            tones[y, x] = t
    return tones


# ----------------------------------------------------------------------------
# Hair: a hand-drawn silhouette per style, lit as part of the head ball, with
# strands following the style's flow. Drawn rows start at x=20, y=4.
# "back" parts hang behind the body (long hair, ponytails, braids).
# ----------------------------------------------------------------------------
HX, HY = 20, 4

def _rows(rows):
    m = np.zeros((64, 64), bool)
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch != ".":
                m[HY + j, HX + i] = True
    return m


HAIR = {}
HAIR["Spiky"] = (dict(rows=[
    "............................",
    "..............##............",
    ".........#....###...##......",
    ".......######.#######.......",
    "......##############..##....",
    ".....##################.....",
    "....###################.....",
    "....###################.....",
    "...###################......",
    "...######......#####.#......",
    "...#####........###..#......",
    "...####..........#..........",
    "....###.....................",
    "....###.....................",
    ".....##.....................",
    ".....#......................",
], flow=(-0.7, -0.7)), None)
HAIR["Short"] = (dict(rows=[
    "............................",
    "............................",
    "..........#######...........",
    "........###########.........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....##################.....",
    "....##################.#....",
    "....#####.....#########.....",
    "....####.......##.###.#.....",
    "....####........#..#........",
    ".....###....................",
    ".....###....................",
    "......#.....................",
], flow=(0.9, 0.45), period=3.6), None)
HAIR["Side Swept"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......#################.....",
    ".....###################....",
    ".....####################...",
    "....#####################...",
    "....#####......##########...",
    "....####.........#######....",
    "....####...........####.....",
    ".....###...........###......",
    ".....###............#.......",
    "......##....................",
], flow=(0.95, 0.3), period=4.6), None)
HAIR["Shaggy"] = (dict(rows=[
    "............................",
    "...........###..............",
    ".......#.#######.##.........",
    "......################......",
    ".....##################.....",
    "....####################....",
    "....#####################...",
    "...######################...",
    "...#######################..",
    "...#####.#####.##.#.##.###..",
    "...#####.........#..#..##...",
    "...######...............#...",
    "....#####...................",
    "....####....................",
    "....###.....................",
    ".....#......................",
], flow=(0.5, 0.86), period=3.2), None)
HAIR["Mohawk"] = (dict(rows=[
    "..........####..............",
    ".........######.............",
    "........########............",
    "........#########...........",
    ".......##########...........",
    ".......####.#####...........",
    "........##...####...........",
    "........#.....###...........",
], flow=(-0.3, -0.95), period=3.0), None)
HAIR["Buzz"] = (dict(rows=[
    "............................",
    "............................",
    "..........#######...........",
    "........###########.........",
    ".......#############........",
    "......###############.......",
    ".....#################......",
    ".....#################......",
    "....###...............#.....",
    "....##......................",
    "....##......................",
], flow=(0.7, 0.7), period=2.4, buzz=True), None)
HAIR["Bald"] = (None, None)
HAIR["Long"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....###################....",
    "....####################....",
    "....#####.....##########....",
    "....####.........#######....",
    "....####..........######....",
    "....###...........######....",
    "....###............#####....",
    "....###............#####....",
    "....###.............####....",
    "....##..............####....",
    "....................###.....",
    ".....................##.....",
], flow=(0.25, 0.97), period=3.4), dict(rows=["............................"] * 8 + [
    "..###.......................",
    "..####......................",
    ".#####......................",
    ".#####......................",
    ".######.....................",
    ".######.....................",
    ".######.....................",
    ".######.....................",
    "..#####.....................",
    "..#####.....................",
    "..#####.....................",
    "..####......................",
    "..####......................",
    "..####......................",
    "...###......................",
    "...###......................",
    "...##.......................",
    "....#.......................",
], flow=(0.15, 0.99), period=3.4))
HAIR["Ponytail"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....##################.....",
    "....##################.#....",
    "....#####......#######......",
    "....####.........####.......",
    "....###...........##........",
    ".....##.....................",
], flow=(-0.9, -0.4), period=3.8), dict(rows=[
    "............................",
    "............................",
    "............................",
    "...###......................",
    ".#####......................",
    "######......................",
    "#####.......................",
    "####........................",
    "####........................",
    "####........................",
    "####........................",
    ".####.......................",
    ".####.......................",
    ".####.......................",
    "..###.......................",
    "..###.......................",
    "..###.......................",
    "...##.......................",
    "...##.......................",
    "....#.......................",
], flow=(0.1, 1.0), period=3.0, tie=(3, 7)))
HAIR["Bob"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....###################....",
    "....####################....",
    "....#####.....###########...",
    "....####........#########...",
    "....####..........#######...",
    "....####...........######...",
    "....####............#####...",
    "....####............####....",
    "....#####...........####....",
    ".....####...........###.....",
    "......###...........##......",
], flow=(0.35, 0.94), period=3.6), None)
HAIR["Bun"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....##################.....",
    "....##################.#....",
    "....#####......########.....",
    "....####.........####.......",
    "....###...........#.........",
    ".....##.....................",
], flow=(-0.85, -0.5), period=3.6), dict(rows=[
    "....####....................",
    "...######...................",
    "..########..................",
    "..########..................",
    "..########..................",
    "...######...................",
    "....####....................",
], flow=(0.7, 0.7), period=2.6, ball=(6.0, 7.5, 4.2), tie=(5, 6)))
HAIR["Braid"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....##################.....",
    ".....##################.....",
    "....##################.#....",
    "....#####......#######......",
    "....####.........####.......",
    "....###...........##........",
    ".....##.....................",
], flow=(-0.9, -0.4), period=3.8), dict(braid=True))
HAIR["Pixie"] = (dict(rows=[
    "............................",
    "............................",
    "..........######............",
    "........##########..........",
    ".......##############.......",
    "......################......",
    ".....###################....",
    ".....####################...",
    "....######################..",
    "....####.......##.#####.##..",
    "....###..........#..##......",
    ".....##.....................",
    ".....#......................",
], flow=(0.98, 0.2), period=3.0), None)

HAIR_ORDER = ["Short", "Spiky", "Side Swept", "Shaggy", "Mohawk", "Buzz", "Bald", "Long", "Ponytail", "Bob", "Bun", "Braid", "Pixie"]


def hair_tones(m, flow, period=4.2, back=False, ball=None, buzz=False):
    """Tones for a hair mask: the head ball's light, strands across the flow,
    a shine band, and shadow along the bottom edge (it sits ON the head)."""
    import math
    cx, cy, r = SPHERE
    if ball:
        cx, cy, r = HX + ball[0], HY + ball[1], ball[2]
    L = np.array([-0.45, -0.7, 0.55])
    L = L / np.linalg.norm(L)
    fx, fy = flow
    nx, ny = -fy, fx
    t = np.full((64, 64), -1)
    ys, xs = np.nonzero(m)
    for y, x in zip(ys, xs):
        dx = (x + 0.5 - cx) / r
        dy = (y + 0.5 - cy) / r
        dz = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
        i = dx * L[0] + dy * L[1] + dz * L[2]
        if back:
            i -= 0.35
        tone = 0 if i > 0.86 else 1 if i > 0.6 else 2 if i > 0.3 else 3
        if not buzz:
            # Locks: crisp strips across the flow, each with a dark gap on one
            # side and its own small highlight cluster (not one band for all)
            sv = (x * nx + y * ny) / period + 0.25 * math.sin(x * 0.31 + y * 0.17)
            k = math.floor(sv)
            u = sv - k
            along = (x * fx + y * fy) / 6.0
            shift = ((k * 7919) % 5) / 5.0
            if u > 0.8:
                tone = min(4, tone + 1)
            elif 0.25 < u < 0.5 and tone <= 2 and math.sin(along + shift * 6.28) > 0.2:
                tone = max(0, tone - 1)
        else:
            if (x + y) % 3 == 0:
                tone = min(4, tone + 1)
        t[y, x] = tone
    for y, x in zip(ys, xs):
        if y + 1 < 64 and not m[y + 1, x]:
            t[y, x] = max(t[y, x], 3)
    return t


def braid_mask():
    m = np.zeros((64, 64), bool)
    seg = []
    for i in range(8):
        cx = 22 - i * 0.35
        cy = 21 + i * 2.6
        for y in range(int(cy - 2), int(cy + 3)):
            for x in range(int(cx - 3), int(cx + 3)):
                if ((x + 0.5 - cx) / 2.2) ** 2 + ((y + 0.5 - cy) / 1.6) ** 2 <= 1:
                    m[y, x] = True
        seg.append((cx, cy))
    return m, seg


def hair_layers(style):
    """Returns (front_canvas, back_canvas or None) for a style, in the hair key 'h'
    (and 'r' for hair ties, recolored by... nothing: they're a fixed color)."""
    front_d, back_d = HAIR[style]
    front = back = None
    if front_d:
        m = _rows(front_d["rows"])
        t = hair_tones(m, front_d["flow"], front_d.get("period", 4.2), buzz=front_d.get("buzz", False))
        front = Canvas()
        ys, xs = np.nonzero(m)
        for y, x in zip(ys, xs):
            front.P(int(x), int(y), "h", int(t[y, x]))
    if back_d:
        back = Canvas()
        if back_d.get("braid"):
            m, seg = braid_mask()
            t = hair_tones(m, (0.1, 1.0), 9.0, back=False, ball=(2.0, 30.0, 14.0))
            ys, xs = np.nonzero(m)
            for y, x in zip(ys, xs):
                back.P(int(x), int(y), "h", int(t[y, x]))
            for (cx, cy) in seg:
                back.line([(round(cx - 1), round(cy - 1)), (round(cx + 1), round(cy))], "h", 3)
            back.P(round(seg[-1][0]), round(seg[-1][1]) + 2, "t")
            back.P(round(seg[-1][0]) - 1, round(seg[-1][1]) + 2, "t")
        else:
            m = _rows(back_d["rows"])
            t = hair_tones(m, back_d["flow"], back_d.get("period", 4.2), back=True, ball=back_d.get("ball"))
            ys, xs = np.nonzero(m)
            for y, x in zip(ys, xs):
                back.P(int(x), int(y), "h", int(t[y, x]))
            if back_d.get("tie"):
                tx, ty = back_d["tie"]
                for dx in range(3):
                    back.P(HX + tx + dx, HY + ty, "t")
    return front, back


def hair_shadow(body_canvas, front):
    """The hair casts a soft shadow on the forehead/face just under it."""
    if front is None:
        return []
    out = []
    for y in range(63):
        for x in range(64):
            if front.g[y][x] == "h" and front.g[y + 1][x] is None and body_canvas.g[y + 1][x] == "s":
                out.append((x, y + 1))
    return out


# ----------------------------------------------------------------------------
# Armor, built from the body's own parts so it always fits
# ----------------------------------------------------------------------------

def _grow(m, n=1):
    return binary_dilation(m, iterations=n) if n > 0 else m


def armor(kind, piece):
    """A gear layer for one body build. Material 'm' = the item's material (key),
    'r' = rarity trim (key), 'k' = dark strap/leather (fixed)."""
    b = body(kind)
    c = Canvas()
    c.form = {"m", "k"}
    R = b.region
    torso = R("torso") | R("hips") & False
    arms_u = R("uarm_b", "uarm_f")
    arms_f = R("farm_b", "farm_f")
    hips = R("hips")
    thighs = R("thigh_b", "thigh_f")
    calves = R("calf_b", "calf_f")
    feet = R("foot_b", "foot_f")
    B = BODY[kind]
    hy = B["hips"][0][1]
    if piece == "tunic":
        m = _grow(R("torso"), 1) | arms_u | _grow(hips, 0)
        m &= ~_grow(R("neck"), 0)
        c.fill_mask(m, "m")
        c.fill_mask(hips & ~_grow(thighs, 0), "m")
        c.line([(B["hips"][0][0], hy), (B["hips"][1][0], hy)], "k")
        c.P(32, hy, "r", 1)
        c.line([(32, 32), (32, hy - 1)], "m", 3)
        c.line([(30, 30), (32, 33), (34, 30)], "r", 2)
        for y in (38, 39):
            c.P(B["uarm_b"][0][0], y, "m", 3)
    elif piece == "plate":
        m = _grow(R("torso"), 1) | arms_u
        m &= ~R("neck")
        c.fill_mask(m, "m")
        # pauldrons: round, a size bigger than the shoulder
        sx, sy, srx, sry = B["sh_b"]
        c.ell(sx, sy, srx + 1, sry + 1, "m")
        sx, sy, srx, sry = B["sh_f"]
        c.ell(sx, sy, srx + 1, sry + 1, "m")
        c.line([(B["sh_f"][0] - 3, 34), (B["sh_f"][0] + 4, 34)], "r", 2)
        c.line([(B["sh_b"][0] - 4, 34), (B["sh_b"][0] + 2, 34)], "m", 3)
        c.line([(32, 31), (32, hy - 2)], "m", 3)
        if kind == "masc":
            c.line([(28, 35), (31, 36)], "m", 3)
            c.line([(33, 36), (37, 35)], "m", 3)
        else:
            c.line([(33, 36), (36, 35)], "m", 3)
        c.line([(29, 39), (35, 39)], "m", 2)
        c.line([(B["hips"][0][0], hy), (B["hips"][1][0], hy)], "k")
        c.line([(B["hips"][0][0], hy + 1), (B["hips"][1][0], hy + 1)], "k", 3)
        c.P(31, hy, "r", 1)
        c.P(32, hy, "r", 1)
        c.P(int(B["sh_f"][0]) - 1, 30, "m", 0)
        c.P(int(B["sh_b"][0]) - 1, 30, "m", 0)
    elif piece == "robe":
        m = _grow(R("torso"), 1) | arms_u | arms_f & _grow(R("uarm_b", "uarm_f"), 2)
        m |= hips
        c.fill_mask(m & ~R("neck"), "m")
        # the skirt flares to the knees
        x0, x1 = B["hips"][3][0] - 1, B["hips"][2][0] + 1
        c.poly([(x0 + 1, hy), (x1 - 1, hy), (x1 + 2, 56), (x0 - 2, 56)], "m")
        c.line([(x0 - 2, 56), (x1 + 2, 56)], "r", 2)
        c.line([(32, 31), (32, 55)], "r", 2)
        c.line([(29, 47), (28, 55)], "m", 3)
        c.line([(35, 47), (36, 55)], "m", 3)
        c.line([(B["hips"][0][0], hy), (B["hips"][1][0], hy)], "k")
        # wide sleeves
        c.poly([(B["farm_f"][0][0] - 1, 40), (B["farm_f"][1][0] + 1, 40), (B["farm_f"][1][0] + 2, 44), (B["farm_f"][0][0] - 1, 44)], "m")
        c.line([(B["farm_f"][0][0] - 1, 44), (B["farm_f"][1][0] + 2, 44)], "r", 2)
        c.line([(30, 30), (32, 33), (34, 30)], "r", 1)
    elif piece == "pants":
        c.fill_mask(_grow(thighs | calves, 0) | hips, "m")
        c.line([(29, 50), (29, 57)], "m", 3)
        c.line([(35, 50), (35, 56)], "m", 3)
        c.line([(B["hips"][0][0], hy), (B["hips"][1][0], hy)], "k")
    elif piece == "greaves":
        c.fill_mask(thighs | calves, "m")
        for (x, y) in [(29, 52), (35, 52)]:
            c.P(x, y, "m", 0)
            c.P(x + 1, y, "m", 1)
            c.P(x, y + 1, "r", 1)
        c.line([(28, 55), (29, 58)], "m", 3)
        c.line([(36, 54), (36, 57)], "m", 3)
        c.line([(28, 48), (30, 48)], "m", 2)
        c.line([(34, 48), (36, 48)], "m", 2)
    elif piece == "leggings":
        c.fill_mask(thighs | calves | hips, "m")
        c.line([(30, 49), (29, 58)], "m", 3)
        c.line([(36, 49), (35, 57)], "m", 3)
        c.P(29, 52, "r", 1)
        c.P(35, 52, "r", 1)
    elif piece == "boots":
        boot = feet | (calves & (np.indices((64, 64))[0] >= 56))
        c.fill_mask(_grow(boot, 0), "m")
        c.line([(27, 56), (31, 56)], "r", 2)
        c.line([(33, 55), (37, 55)], "r", 2)
        c.line([(26, 63), (31, 63)], "k")
        c.line([(33, 63), (39, 63)], "k")
    elif piece == "sandals":
        c.fill_mask(feet & (np.indices((64, 64))[0] >= 61), "m")
        for (x0, x1, y) in [(27, 31, 60), (33, 38, 59)]:
            c.line([(x0, y), (x1, y)], "m", 2)
        c.line([(28, 58), (29, 60)], "m", 3)
        c.line([(35, 57), (36, 59)], "m", 3)
        c.P(29, 59, "r", 1)
        c.P(35, 58, "r", 1)
    elif piece == "sabatons":
        boot = feet | (calves & (np.indices((64, 64))[0] >= 56))
        c.fill_mask(boot, "m")
        c.line([(27, 58), (31, 58)], "m", 3)
        c.line([(33, 57), (37, 57)], "m", 3)
        c.line([(34, 60), (38, 60)], "m", 2)
        c.line([(26, 63), (31, 63)], "k")
        c.line([(33, 63), (39, 63)], "k")
        c.P(29, 56, "r", 1)
        c.P(35, 56, "r", 1)
    return c


# ----------------------------------------------------------------------------
# Helmets (one shape fits both builds)
# ----------------------------------------------------------------------------

def helmet(kind):
    c = Canvas()
    hx, hy, rx, ry = HEAD["masc"]
    if kind == "cap":
        c.ell(31.5, 12.5, 9.0, 5.5, "m")
        c.poly([(23, 13), (41, 13), (43, 15), (22, 15)], "m")
        c.line([(23, 14), (42, 14)], "r", 1)
        c.P(31, 7, "m", 0)
        c.P(32, 7, "m", 0)
        for y in range(16, 64):
            for x in range(64):
                c.g[y][x] = None
    elif kind == "helm":
        # a rounded steel helm: dome, back plate and cheek guard; the face stays open
        c.ell(31.5, 15.0, 9.4, 8.6, "m")
        c.poly([(22, 15), (30, 15), (31, 27), (24, 27), (22, 22)], "m")
        c.rect(33, 15, 42, 28, None)
        c.rect(31, 16, 33, 20, None)
        c.line([(23, 14), (41, 14)], "r", 1)
        c.line([(23, 13), (40, 13)], "m", 3)
        c.line([(31, 7), (31, 12)], "m", 0)
        c.line([(32, 6), (32, 12)], "m", 2)
        c.line([(27, 18), (28, 25)], "m", 3)
        c.P(29, 23, "r", 1)
    elif kind == "hood":
        # cloth over the head, falling to the shoulders behind the neck
        c.ell(31.5, 16.0, 9.8, 9.6, "m")
        c.poly([(22, 18), (30, 18), (31, 31), (24, 31), (21, 26)], "m")
        c.poly([(29, 26), (37, 27), (39, 31), (27, 31)], "m")
        c.ell(36.8, 20.5, 5.0, 7.2, None)
        c.rect(33, 16, 42, 25, None)
        c.line([(33, 13), (41, 16)], "m", 3)
        c.line([(34, 15), (41, 17)], "m", 3)
        c.line([(26, 11), (24, 23)], "m", 3)
        c.line([(29, 30), (37, 30)], "r", 2)
        for y in range(32, 64):
            for x in range(64):
                c.g[y][x] = None
    elif kind == "crown":
        c.poly([(24, 10), (40, 10), (40, 13), (24, 13)], "m")
        for x in (24, 28, 32, 36, 39):
            c.poly([(x, 10), (x + 1, 6), (x + 2, 10)], "m")
            c.P(x + 1, 6, "m", 0)
        c.P(31, 11, "r", 0)
        c.P(32, 11, "r", 0)
        c.P(26, 11, "r", 1)
        c.P(37, 11, "r", 1)
    return c


def cape():
    """A unique class's cape, behind the body: 'm' = class color, 'r' = rank trim."""
    c = Canvas()
    c.poly([(24, 28), (32, 28), (30, 44), (27, 60), (21, 62), (17, 60), (19, 48)], "m")
    c.line([(22, 37), (20, 51), (18, 59)], "m", 3)
    c.line([(26, 36), (24, 50), (23, 61)], "m", 3)
    c.line([(17, 60), (21, 62), (25, 61), (27, 60)], "r", 1)
    c.line([(24, 28), (32, 28)], "r", 1)
    return c


# ----------------------------------------------------------------------------
# Race features (v0.11, fitted to the native head). Each returns
# (canvas, ramps). 's' = skin key and 'h' = hair key are filled by make_art.
# ----------------------------------------------------------------------------
BONE = ['#fbf3dc', '#ead4aa', '#c8b08a', '#9a8064', '#5a4a3e']
DEMON = ['#ff8f80', '#e04a48', '#a22633', '#68203a', '#3e1225']
GOLD = ['#fff4a3', '#fee761', '#feae34', '#f77622', '#be4a2f']
WHITE_F = ['#ffffff', '#f4f4f8', '#d8dcec', '#a8b0c8', '#6a7090']
DARK_F = ['#8b9bb4', '#5a6988', '#3a4466', '#262b44', '#181425']
FAIRY = ['#fdf2ff', '#f5c9f0', '#e39ad8', '#b56bb0', '#6b3a7a']
DRAGON = ['#bff2c8', '#7fd6a0', '#3fa266', '#2a6e52', '#173f38']
DRAGON_M = ['#ffc6a8', '#f38a6a', '#c8504a', '#8a2e3c', '#4a1a2a']
RUNE = '#7fe9ff'
STITCH = '#2a1d26'
FUR_G = ['#e6e8ee', '#bfc4d0', '#8f97a8', '#5f6678', '#363a48']


def _wing(c, mat, root, tip, low, feathers=True, scale=1.0):
    rx, ry = root
    tx, ty = tip
    lx, ly = low
    c.poly([(rx, ry), (tx, ty), (tx - 1, ty + 4), (lx, ly), (rx + 1, ry + 8)], mat)
    if feathers:
        for i in range(4):
            f = 0.25 + i * 0.2
            x0 = rx + (lx - rx) * f
            y0 = ry + (ly - ry) * f + 2
            c.line([(round(x0 + 3), round(y0 - 2)), (round(x0 - 2), round(y0 + 2))], mat, 3)


def race_layer(key):
    c = Canvas()
    c.form = {"b", "d", "g", "w", "k", "f", "z", "m", "u", "o"}
    R = {"s": None, "h": None}
    if key == "ears":
        c.poly([(26, 17), (19, 11), (21, 16), (25, 22)], "s")
        c.line([(21, 13), (24, 18)], "s", 3)
        c.ell(25.5, 19.5, 1.5, 2.3, "s")
    elif key == "goblin_ears":
        c.poly([(26, 16), (14, 13), (17, 17), (25, 22)], "s")
        c.line([(17, 15), (24, 18)], "s", 3)
        c.ell(25.5, 19.5, 1.6, 2.4, "s")
    elif key == "horns":
        c.poly([(27, 11), (29, 10), (27, 5), (24, 3), (25, 7)], "d")
        c.poly([(34, 10), (36, 10), (37, 5), (35, 2), (34, 6)], "d")
        R["d"] = DEMON
    elif key == "horns_big":
        c.poly([(26, 11), (29, 10), (27, 4), (21, 1), (17, 3), (20, 4), (24, 6)], "d")
        c.poly([(34, 10), (37, 10), (39, 4), (37, 0), (35, 4)], "d")
        R["d"] = DEMON
    elif key == "halo":
        c.ell(31, 4.5, 6.5, 1.8, "g", 1)
        c.ell(31, 4.5, 4.5, 0.9, None)
        R["g"] = GOLD
    elif key == "broken_halo":
        c.ell(31, 4.5, 6.5, 1.8, "z", 2)
        c.ell(31, 4.5, 4.5, 0.9, None)
        c.rect(32, 2, 34, 7, None)
        R["z"] = DARK_F
    elif key == "tail":
        c.line([(27, 46), (22, 49), (18, 53), (16, 57)], "d")
        c.line([(27, 47), (22, 50), (18, 54)], "d", 2)
        c.poly([(14, 56), (18, 56), (16, 60)], "d")
        R["d"] = DEMON
    elif key == "wings_fairy":
        c.poly([(27, 31), (14, 17), (10, 22), (16, 31)], "f")
        c.poly([(27, 34), (15, 38), (13, 44), (21, 41)], "f")
        c.line([(26, 31), (15, 21)], "f", 3)
        c.line([(26, 35), (17, 41)], "f", 3)
        R["f"] = FAIRY
    elif key == "wings_big":
        c.poly([(27, 30), (11, 11), (5, 18), (12, 31)], "f")
        c.poly([(27, 34), (10, 38), (8, 48), (19, 44)], "f")
        c.line([(26, 30), (11, 16)], "f", 3)
        c.line([(26, 34), (12, 42)], "f", 3)
        c.P(9, 16, "f", 0)
        R["f"] = FAIRY
    elif key in ("wings_angel", "fallen_wings"):
        m = "w" if key == "wings_angel" else "k"
        _wing(c, m, (27, 30), (9, 19), (14, 44))
        R[m] = WHITE_F if m == "w" else DARK_F
    elif key == "wings2":
        _wing(c, "w", (27, 28), (13, 9), (20, 26), scale=0.7)
        R["w"] = WHITE_F
    elif key == "wings3":
        _wing(c, "w", (27, 38), (12, 44), (20, 52), scale=0.6)
        R["w"] = WHITE_F
    elif key == "beard":
        c.poly([(29, 22), (40, 21), (40, 26), (37, 31), (32, 32), (29, 27)], "h")
        c.rect(33, 23, 36, 24, None)
        c.line([(34, 26), (35, 30)], "h", 3)
        c.line([(31, 25), (31, 29)], "h", 3)
    elif key == "beast_ears":
        c.poly([(25, 11), (24, 3), (30, 9)], "h")
        c.poly([(33, 9), (37, 2), (38, 10)], "h")
        c.P(26, 7, "o")
        c.P(36, 6, "o")
        R["o"] = '#f2a8a0'
    elif key == "wolf_ears":
        c.poly([(24, 12), (22, 2), (30, 9)], "u")
        c.poly([(33, 9), (37, 1), (39, 11)], "u")
        R["u"] = FUR_G
    elif key == "beast_tail":
        c.poly([(27, 45), (20, 47), (13, 53), (12, 58), (16, 57), (21, 51), (27, 48)], "h")
        c.line([(24, 47), (15, 55)], "h", 3)
    elif key == "wolf_tail":
        c.poly([(27, 45), (19, 46), (11, 52), (10, 59), (15, 57), (20, 51), (27, 48)], "u")
        c.line([(24, 47), (13, 56)], "u", 3)
        R["u"] = FUR_G
    elif key == "dragon_horns":
        c.poly([(27, 12), (29, 10), (23, 5), (17, 4), (22, 8)], "b")
        c.poly([(33, 10), (35, 10), (31, 4), (27, 2), (30, 6)], "b")
        R["b"] = BONE
    elif key == "dragon_scales":
        for (x, y) in [(36, 20), (37, 21), (35, 23), (27, 22), (28, 23), (40, 41), (39, 42), (24, 41)]:
            c.P(x, y, "m", 1)
        R["m"] = DRAGON
    elif key == "dragon_tail":
        c.poly([(28, 44), (21, 47), (14, 53), (10, 59), (14, 59), (20, 53), (28, 49)], "m")
        c.line([(26, 46), (13, 56)], "m", 0)
        for x in (24, 20, 16):
            c.P(x, 47 + (24 - x) // 2, "m", 3)
        R["m"] = DRAGON
    elif key == "dragon_wings":
        c.poly([(27, 30), (10, 12), (8, 18), (4, 22), (10, 30), (6, 34), (14, 38), (24, 37)], "z")
        c.line([(27, 30), (10, 12)], "z", 4)
        c.line([(20, 25), (6, 34)], "z", 3)
        c.line([(16, 20), (4, 22)], "z", 3)
        R["z"] = DRAGON_M
    elif key == "tusks":
        c.P(36, 24, "b", 0)
        c.P(36, 23, "b", 0)
        c.P(33, 24, "b", 1)
        c.P(33, 23, "b", 1)
        R["b"] = BONE
    elif key == "fangs":
        c.P(34, 25, "b", 0)
        c.P(36, 25, "b", 0)
        R["b"] = BONE
    elif key == "golem_runes":
        for (x, y) in [(36, 13), (37, 13), (28, 18), (28, 19), (32, 34), (32, 35), (31, 36), (33, 36), (32, 37), (40, 42), (24, 36), (24, 37)]:
            c.P(x, y, "g", 0)
        R["g"] = RUNE
    elif key == "stitches":
        for (x, y) in [(29, 12), (30, 13), (29, 14), (30, 15), (38, 23), (39, 24), (40, 40), (39, 41), (40, 42)]:
            c.P(x, y, "k", 0)
        R["k"] = STITCH
    elif key == "lich_crown":
        c.poly([(24, 9), (39, 9), (39, 12), (24, 12)], "b")
        for x in (24, 28, 32, 36):
            c.poly([(x, 9), (x + 1, 4), (x + 2, 9)], "b")
        c.P(31, 10, "g", 0)
        c.P(37, 10, "g", 0)
        R["b"] = BONE
        R["g"] = RUNE
    elif key == "crown":
        c.poly([(25, 9), (38, 9), (38, 11), (25, 11)], "g")
        for x in (25, 31, 36):
            c.poly([(x, 9), (x + 1, 6), (x + 2, 9)], "g")
        c.P(32, 10, "o", 0)
        R["g"] = GOLD
        R["o"] = '#e43b44'
    return c, R


RACE_KEYS = ["ears", "horns", "halo", "tail", "wings_fairy", "wings_angel", "beard", "beast_ears", "beast_tail", "dragon_horns",
             "dragon_scales", "dragon_tail", "dragon_wings", "tusks", "goblin_ears", "golem_runes", "stitches", "fangs",
             "wolf_ears", "wolf_tail", "fallen_wings", "broken_halo", "lich_crown", "wings2", "wings3", "horns_big", "crown", "wings_big"]
