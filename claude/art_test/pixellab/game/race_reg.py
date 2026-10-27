"""Registration of the race layers (Fable hero R3 items 1-3): every battle frame is checked against the
idle's feature and repaired, so a tail keeps its hip, nothing sinks under the floor, and steel the
PixelLab edit left (a sword drawn into the layer) goes. Pure PIL: bake.py calls register() per layer."""
import colorsys
from PIL import Image

C = 96
BATTLE = range(7)  # frames 0-1 idle, 2-5 attack, 6 hit; 7-8 are the portrait (front view)
HIP = (55, 66)  # rows of the hip band: where a tail is rooted
TAIL_TOP = 48  # a tail race's layer under this row is its tail (ears and horns sit above)
LOW = 78  # the lowest row a feature may reach (the feet end on 79)
SLACK = 4  # px a frame's tail root may move from the idle's (the art test allows 6, measured on the outfit)
STEEL_OK = 20  # a layer whose idle has this much grey-white keeps it
PALE = ["Angel", "Fallen Angel", "Lich"]  # white feathers, a cracked halo, a bone crown: theirs to keep
NEAR = 3  # px a head part (ear, horn) may sit from the idle's and still be the same part
TAILS = ["Beastkin", "Dragonkin", "Demon"]


def lum(px):
    return (0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]) / 255


def steel(px):
    """Grey-white, the colour of a blade: low saturation and light."""
    return colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))[1] < 0.2 and lum(px) > 0.55


def pts_of(c):
    p = c.load()
    return {(x, y) for y in range(c.height) for x in range(c.width) if p[x, y][3]}


def comps(pts):
    pts = set(pts); out = []
    while pts:
        s = [pts.pop()]; g = set(s)
        while s:
            x, y = s.pop()
            for i in (-1, 0, 1):
                for j in (-1, 0, 1):
                    q = (x + i, y + j)
                    if q in pts:
                        pts.discard(q); g.add(q); s.append(q)
        out.append(g)
    return out


def steel_count(c):
    p = c.load()
    return sum(1 for q in pts_of(c) if steel(p[q]))


def hip_centre(pts):
    xs = [x for (x, y) in pts if HIP[0] <= y < HIP[1]]
    return sum(xs) / len(xs) if xs else None


def body_axis(body):
    """The body's centre column at the hips (a tail is mirrored about it)."""
    h = hip_centre(pts_of(body))
    return h if h is not None else C / 2


def part(c, pts, dx=0, mirror_at=None):
    """The pixels pts of c on a fresh cell, moved dx, or mirrored about the column mirror_at."""
    out = Image.new("RGBA", c.size); p, o = c.load(), out.load()
    for (x, y) in pts:
        nx = round(2 * mirror_at - x) if mirror_at is not None else x + dx
        if 0 <= nx < C:
            o[nx, y] = p[x, y]
    return out


def tail_pts(c):
    return {q for q in pts_of(c) if q[1] >= TAIL_TOP}


def tail_ok(t, ref_hip, ref_steel):
    pts = pts_of(t)
    h = hip_centre(pts)
    return (h is not None and abs(h - ref_hip) <= SLACK and steel_count(t) <= ref_steel
            and max(q[1] for q in pts) <= LOW)


def squash(c):
    """A feature reaching under LOW: its lower part (from the hips down) is squeezed row by row to end on
    LOW, so the root stays where it was drawn (a tail through the floor read as a mis-registered sprite)."""
    pts = pts_of(c)
    if not pts:
        return c
    low = max(q[1] for q in pts)
    if low <= LOW:
        return c
    top = HIP[0]
    out = c.copy(); p, o = c.load(), out.load()
    for (x, y) in pts:
        if y > top:
            o[x, y] = (0, 0, 0, 0)
    for ty in range(top + 1, LOW + 1):
        sy = top + round((ty - top) * (low - top) / (LOW - top))
        for x in range(C):
            if p[x, sy][3]:
                o[x, ty] = p[x, sy]
    return out


def no_steel(c):
    """Blades the edit drew into the layer: a part that is mostly steel goes whole, a steel pixel in a
    real feature goes alone (a white glint, the tip of a tail), and crumbs left behind go."""
    p = c.load(); out = c.copy(); o = out.load()
    for g in comps(pts_of(c)):
        st = {q for q in g if steel(p[q])}
        gone = g if len(st) > 0.25 * len(g) else st
        for q in gone:
            o[q] = (0, 0, 0, 0)
    for g in comps(pts_of(out)):
        if len(g) < 4:
            for q in g:
                o[q] = (0, 0, 0, 0)
    return out


def register(front, bodies, race, log=None):
    """front: the 9 front-layer cells of one race on one body; bodies: that body's 9 cells (for the hip
    axis). Returns the repaired cells; log gets one line per repair."""
    out = [c.copy() for c in front]
    note = (lambda s: log.append(f"{race}: {s}")) if log is not None else (lambda s: None)
    ref = out[0]
    ref_steel = steel_count(ref)
    if race in TAILS and tail_pts(ref):
        ref_tail = part(ref, tail_pts(ref))
        if not tail_ok(ref_tail, hip_centre(pts_of(ref_tail)), ref_steel):
            ref_tail = squash(ref_tail)
        ref_hip = hip_centre(pts_of(ref_tail))
        ax0 = body_axis(bodies[0])
        near = {(x + i, y + j) for (x, y) in pts_of(ref) - tail_pts(ref) for i in range(-NEAR, NEAR + 1)
                for j in range(-NEAR, NEAR + 1)}
        out[0] = Image.alpha_composite(part(ref, pts_of(ref) - tail_pts(ref)), ref_tail)
        for i in list(BATTLE)[1:]:
            c = out[i]; tp = tail_pts(c)
            heads = [g for g in comps(pts_of(c) - tp) if g & near]  # spines and dashes the edit drew between the horns go
            if len(heads) < len(comps(pts_of(c) - tp)):
                note(f"frame {i}: stray head parts dropped")
            head = part(c, set().union(*heads) if heads else set())
            ax = body_axis(bodies[i])
            own = part(c, tp)
            if tp and tail_ok(own, ref_hip + ax - ax0, ref_steel):
                out[i] = Image.alpha_composite(head, own)
                continue
            flip = part(c, tp, mirror_at=ax) if tp else None
            if flip is not None and tail_ok(flip, ref_hip + ax - ax0, ref_steel):
                note(f"frame {i} tail mirrored to the idle's side")
                t = flip
            else:
                note(f"frame {i} tail replaced by the idle's (moved {round(ax - ax0)} px with the hips)")
                t = part(ref_tail, pts_of(ref_tail), dx=round(ax - ax0))
            out[i] = Image.alpha_composite(head, t)
    h0 = (out[0].getbbox() or (0, 0, 0, 0))
    for i in list(BATTLE)[1:]:  # a frame drawn at another size (her bat wings grew to 22 rows from 13)
        bb = out[i].getbbox()
        if race not in TAILS and bb and h0[3] > h0[1] and abs((bb[3] - bb[1]) - (h0[3] - h0[1])) * 2 > h0[3] - h0[1]:
            note(f"frame {i} ({bb[3] - bb[1]} rows to the idle's {h0[3] - h0[1]}) replaced by the idle's")
            out[i] = part(out[0], pts_of(out[0]), dx=round(body_axis(bodies[i]) - body_axis(bodies[0])))
    for view, r in ((BATTLE, 0), (range(7, 9), 7)):
        if race not in PALE and steel_count(front[r]) < STEEL_OK:
            for i in view:
                n = steel_count(out[i])
                if n:
                    out[i] = no_steel(out[i])
                    note(f"frame {i}: {n} steel pixels dropped")
    for i in BATTLE:
        bb = out[i].getbbox()
        if bb and bb[3] - 1 > LOW:
            note(f"frame {i} squeezed from row {bb[3] - 1} to {LOW}")
            out[i] = squash(out[i])
    return out
