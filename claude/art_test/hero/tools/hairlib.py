"""Hair library (pass 2): the game's old LPC hair styles, redrawn in our own pixels for the chibi head.
Same style names and ideas as lpc.gd HAIR; no LPC pixels are used.

Each style = a silhouette (built from simple masks + hand-placed tufts) for the battle back view and for
the portrait, shaded by one routine: top-left light, strands that follow the hair flow (radial from the
crown on the head, vertical on hanging hair) with 1 px darker partings, darker rim on the shadow side,
then speckle removal. Output: layers hair_<id> (battle) and port_hair_<id> (portrait), material H.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_master as D

# ---------------------------------------------------------------- geometry helpers
def ellipse(cx, cy, rx, ry):
    return {(y, x) for y in range(int(cy - ry) - 1, int(cy + ry) + 2) for x in range(int(cx - rx) - 1, int(cx + rx) + 2)
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0}


def rect(x0, y0, x1, y1):
    return {(y, x) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)}


def tri(apex, base_l, base_r):
    (ay, ax), (ly, lx), (ry, rx) = apex, base_l, base_r
    pts = set()
    for y in range(min(ay, ly, ry), max(ay, ly, ry) + 1):
        for x in range(min(ax, lx, rx), max(ax, lx, rx) + 1):
            def s(p1, p2, p3):
                return (p1[1] - p3[1]) * (p2[0] - p3[0]) - (p2[1] - p3[1]) * (p1[0] - p3[0])
            p = (y, x)
            d1, d2, d3 = s(p, apex, base_l), s(p, base_l, base_r), s(p, base_r, apex)
            if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)):
                pts.add(p)
    return pts


def rows_from_grid(grid, x0, y0):
    out = set()
    for j, r in enumerate(grid):
        for i, c in enumerate(r):
            if c != ".":
                out.add((y0 + j, x0 + i))
    return out


# ---------------------------------------------------------------- shading
def shade(mask, crown, hang_from=99, period=4.6, light=0.0, curls=False, flat=False):
    """mask: set of (y, x). crown: (cy, cx) where strands start. Returns {(y,x): shade 1-4}."""
    if not mask:
        return {}
    ys = [p[0] for p in mask]; xs = [p[1] for p in mask]
    y0, y1, x0, x1 = min(ys), max(ys), min(xs), max(xs)
    cy, cx = crown
    out = {}
    for (y, x) in mask:
        L = 0.62 - 0.55 * (x - x0) / max(1, x1 - x0) - 0.45 * (y - y0) / max(1, y1 - y0) + light
        if curls:
            # round curl clusters: lit top-left of each 4x4 cell, dark lower-right corner
            u, v = (x + (y // 5) * 2) % 5, y % 5
            m = 0.20 if (u, v) in ((0, 0), (1, 0)) else (-0.22 if (u, v) in ((3, 3), (4, 3)) and L < 0.45 else 0)
        elif flat:
            m = 0
        else:
            if y >= hang_from:
                u = x + 0.35 * (y // 5)
            else:
                ang = math.atan2(x - cx, y - cy + 3)
                u = ang * 9.0
            f = (u / period) % 1.0
            m = -0.30 if f < 0.2 else (0.16 if f < 0.55 else 0.0)
        edge = any((y + dy, x + dx) not in mask for dy, dx in ((1, 0), (0, 1), (0, -1), (-1, 0)))
        rim = -0.2 if edge and (x > (x0 + x1) / 2 or y > (y0 + y1) / 2) else 0.0
        v = L + m + rim
        out[(y, x)] = 1 if v < 0.12 else 2 if v < 0.38 else 3 if v < 0.66 else 4
    # speckle removal
    for _ in range(2):
        new = dict(out)
        for (y, x), s in out.items():
            nb = [out[(y + dy, x + dx)] for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)) if (y + dy, x + dx) in out]
            if nb and s not in nb:
                new[(y, x)] = max(sorted(set(nb)), key=nb.count)
        out = new
    return out


def to_rows(sh, mats="H"):
    rows = {}
    for (y, x), s in sh.items():
        rows.setdefault(y, {})[x] = str(s)
    out = []
    for y in sorted(rows):
        xs = sorted(rows[y])
        seg_start = xs[0]; prev = xs[0]; seg = rows[y][xs[0]]
        for x in xs[1:]:
            if x == prev + 1:
                seg += rows[y][x]
            else:
                out.append((y, seg_start, seg)); seg_start, seg = x, rows[y][x]
            prev = x
        out.append((y, seg_start, seg))
    return out


# ---------------------------------------------------------------- battle (back view) silhouettes
SKULL = ellipse(25.5, 32.0, 12.2, 10.6)          # covers the body skull (x14-37, y22-42)
EARS = rect(11, 33, 13, 37) | rect(38, 33, 40, 37)
CROWN_B = (24, 25.5)


def nape(mask, y_cut):
    return {p for p in mask if p[0] <= y_cut}


def tufts_top(xs, y, h=2):
    out = set()
    for x in xs:
        out |= tri((y - h, x), (y + 1, x - 1), (y + 1, x + 1))
    return out


BACK = {}
BACK["short"] = (nape(SKULL | ellipse(25.5, 31, 13.2, 10.5), 41) - EARS | rect(18, 41, 33, 42) | tufts_top([20, 24, 28, 31], 22, 1), {})
BACK["spiky"] = (nape(SKULL | ellipse(25.5, 31, 13.0, 10.0), 40) - EARS
                 | tri((15, 22), (24, 14), (24, 21)) | tri((13, 30), (23, 21), (23, 28)) | tri((16, 37), (24, 29), (25, 35))
                 | tri((20, 14), (27, 13), (29, 18)) | tri((21, 42), (26, 36), (29, 38)), {})
BACK["mohawk"] = (rect(22, 22, 29, 42) | tri((13, 24), (22, 21), (22, 27)) | tri((15, 29), (22, 26), (22, 31))
                  | tri((17, 21), (23, 20), (23, 24)), {"crown": (20, 25.5)})
BACK["bangs"] = (SKULL | ellipse(25.5, 31, 14.0, 11.5) | rect(13, 32, 38, 44) - EARS - rect(11, 33, 12, 37) - rect(39, 33, 40, 37), {})
BACK["long"] = (SKULL | ellipse(25.5, 31, 13.8, 11.0) | rect(14, 34, 37, 44) | rect(16, 45, 35, 49) | rect(17, 50, 34, 50)
                | rect(17, 51, 20, 52) | rect(22, 51, 29, 53) | rect(31, 51, 33, 51), {"hang": 40})
BACK["ponytail"] = (nape(SKULL | ellipse(25.5, 31, 13.0, 10.0), 40) - EARS | rect(22, 38, 29, 41)
                    | tri((56, 25), (41, 21), (41, 30)) | rect(23, 41, 28, 50), {"hang": 41})
BACK["bun"] = (nape(SKULL | ellipse(25.5, 31, 13.0, 10.0), 40) - EARS | ellipse(10.5, 37, 3.6, 4.2) | ellipse(40.5, 37, 3.6, 4.2), {})
BACK["braid"] = (nape(SKULL | ellipse(25.5, 31, 13.0, 10.0), 40) - EARS | rect(23, 40, 28, 58) | tri((61, 25), (58, 23), (58, 28)), {"hang": 41, "braid": True})
BACK["afro"] = (ellipse(25.5, 29, 17.5, 15.5) - rect(0, 44, 60, 84), {"curls": True})

# ---------------------------------------------------------------- portrait (front) silhouettes
P_SKULL = ellipse(21.5, 15.0, 13.0, 12.0)        # top of the portrait head (face x10-33, y6-30)
FACE_CLEAR = ellipse(21.5, 20.5, 10.2, 8.8)       # keep the face visible


def fringe(y, xs_down):
    """Locks hanging over the forehead: list of (x, length)."""
    out = set()
    for x, n in xs_down:
        out |= rect(x, y, x + 1, y + n - 1)
    return out


def ragged(base, tips):
    out = set(base)
    for t in tips:
        out |= tri(*t)
    return out


BACK["shaggy"] = (ragged(nape(SKULL | ellipse(25.5, 31, 13.4, 10.6), 42) - EARS,
                         [((19, 18), (24, 15), (24, 21)), ((18, 25), (23, 22), (23, 28)), ((19, 32), (24, 29), (24, 35)),
                          ((25, 10), (28, 12), (31, 14)), ((25, 41), (28, 39), (31, 37)),
                          ((45, 17), (41, 15), (41, 20)), ((46, 23), (42, 21), (42, 26)), ((46, 29), (42, 27), (42, 31)),
                          ((45, 34), (41, 32), (41, 36))]), {"period": 3.6})
PORT = {}
PORT["shaggy"] = (ragged((P_SKULL - FACE_CLEAR) | rect(9, 8, 34, 12) | fringe(12, [(11, 3), (14, 4), (18, 2), (21, 4), (25, 3), (29, 4)])
                          | rect(8, 13, 10, 19) | rect(33, 13, 35, 19),
                          [((0, 12), (6, 9), (7, 15)), ((-1, 19), (5, 16), (5, 22)), ((0, 26), (5, 23), (6, 29)), ((2, 33), (7, 30), (9, 35)),
                           ((22, 7), (17, 7), (17, 10)), ((22, 36), (17, 34), (17, 37))]), {})
PORT["short"] = ((P_SKULL - FACE_CLEAR) | rect(9, 8, 34, 13) | fringe(13, [(11, 2), (15, 3), (19, 2), (24, 3), (29, 2)])
                 | rect(8, 14, 10, 17) | rect(33, 14, 35, 17), {})
PORT["spiky"] = ((P_SKULL - FACE_CLEAR) | rect(9, 8, 34, 13) | tri((-1, 17), (5, 10), (6, 17)) | tri((-3, 25), (4, 18), (4, 26))
                 | tri((-1, 33), (5, 26), (6, 33)) | tri((3, 9), (8, 7), (10, 12)) | tri((3, 38), (8, 33), (10, 35))
                 | fringe(13, [(14, 2), (21, 3), (27, 2)]) | rect(8, 14, 10, 16) | rect(33, 14, 35, 16), {"crown": (2, 21.5)})
PORT["mohawk"] = (rect(18, 3, 25, 11) | tri((-6, 20), (4, 17), (4, 24)) | tri((-3, 25), (5, 22), (5, 27)), {"crown": (-2, 21.5)})
PORT["bangs"] = ((P_SKULL - ellipse(21.5, 21.5, 10.0, 7.8)) | rect(9, 8, 34, 14) | rect(7, 14, 11, 27) | rect(32, 14, 36, 27), {})
PORT["long"] = ((P_SKULL - FACE_CLEAR) | rect(9, 8, 34, 12) | fringe(12, [(17, 2), (24, 2)]) | rect(7, 13, 11, 36) | rect(32, 13, 36, 36), {"hang": 18})
PORT["ponytail"] = ((P_SKULL - FACE_CLEAR) | rect(10, 7, 33, 11) | rect(8, 12, 10, 17) | rect(33, 12, 35, 17)
                    | rect(36, 13, 38, 30) | rect(35, 10, 37, 13), {"hang": 14})
PORT["bun"] = ((P_SKULL - FACE_CLEAR) | rect(10, 8, 33, 12) | fringe(12, [(13, 2), (20, 2), (27, 2)]) | ellipse(7.5, 9, 3.6, 3.8)
               | ellipse(35.5, 9, 3.6, 3.8) | rect(8, 13, 10, 17) | rect(33, 13, 35, 17), {})
PORT["braid"] = ((P_SKULL - FACE_CLEAR) | rect(9, 8, 34, 12) | fringe(12, [(12, 3), (16, 2)]) | rect(8, 13, 10, 18) | rect(33, 13, 36, 20)
                 | rect(34, 20, 37, 38), {"hang": 20, "braid": True})
PORT["afro"] = ((ellipse(21.5, 11.0, 18.0, 13.5) - ellipse(21.5, 22.0, 10.2, 9.5)) | rect(5, 12, 9, 26) | rect(34, 12, 38, 26), {"curls": True})


def braid_pattern(sh, x0, x1, y0, y1):
    """Overlapping braid sections: a light chevron every 3 rows, dark between."""
    for (y, x) in list(sh):
        if y0 <= y <= y1 and x0 <= x <= x1:
            k = (y - y0) % 3
            mid = (x0 + x1) / 2
            if k == 0:
                sh[(y, x)] = 1
            elif k == 1:
                sh[(y, x)] = 3 if x <= mid else 2
            else:
                sh[(y, x)] = 4 if x < mid else 3
    return sh


def build_style(key, view):
    mask, opt = (BACK if view == "back" else PORT)[key]
    mask = {p for p in mask if -6 <= p[0] < 84 and 0 <= p[1] < 60}
    crown = opt.get("crown", CROWN_B if view == "back" else (4, 21.5))
    if view != "back":                       # portrait canvas is drawn 6 px lower (draw_portrait.PDY)
        mask = {(y + PDY, x) for y, x in mask}
        crown = (crown[0] + PDY, crown[1])
        opt = dict(opt, hang=opt.get("hang", 99 - PDY) + PDY)
    sh = shade(mask, crown, hang_from=opt.get("hang", 99), curls=opt.get("curls", False), period=opt.get("period", 4.6))
    if opt.get("braid"):
        if view == "back":
            braid_pattern(sh, 23, 28, 41, 58)
        else:
            braid_pattern(sh, 34, 37, 21 + PDY, 38 + PDY)
    return to_rows(sh)


PDY = 9   # must match draw_portrait.PDY
STYLES = ["short", "shaggy", "spiky", "mohawk", "bangs", "long", "ponytail", "bun", "braid", "afro"]
OLD = {"mop": "mop", "short": "plain", "spiky": "spiked", "mohawk": "longhawk", "buzz": "buzzcut", "bangs": "bangs", "long": "long",
       "ponytail": "ponytail", "bun": "bunches", "braid": "braid", "afro": "afro", "shaggy": "messy1"}


def build():
    for k in STYLES:
        D.save(D.draw(D.blank(), build_style(k, "back")), "hair_" + k)
        D.save(D.draw(D.blank(), build_style(k, "port")), "port_hair_" + k)


if __name__ == "__main__":
    build()
