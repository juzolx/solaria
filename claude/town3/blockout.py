"""Iso block-outs at a lot's exact footprint (1x: a cell is a 32x16 diamond), used as img2img
init images so every generated building fits its lot and its door faces the right street.
Usage: py blockout.py <lot_id|all> <out_dir>"""
import sys
from PIL import Image, ImageDraw
from layout import LOTS

HW, HH, PAD = 16, 8, 4
OUT = "#0e0812"


class Canvas:
    def __init__(self, w, h, top):
        top += -(top + (w + h) * HH + 2 * PAD) % 4     # PixelLab wants sides divisible by 4
        self.w, self.h, self.top = w, h, top          # cells along i / j, px above the footprint
        self.ox, self.oy = PAD + h * HW, PAD + top
        self.size = ((w + h) * HW + 2 * PAD, top + (w + h) * HH + 2 * PAD)
        self.img = Image.new("RGBA", self.size, (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def at(self, i, j, z=0):
        return self.ox + (i - j) * HW, self.oy + (i + j) * HH - z

    def poly(self, pts, col, outline=OUT):
        self.d.polygon([self.at(*p) for p in pts], fill=col, outline=outline)

    def face_rect(self, side, t0, t1, z0, z1, col):
        """Rectangle on the +i face (t along j) or the +j face (t along i)."""
        if side == "i":
            pts = [(self.w, t0, z0), (self.w, t1, z0), (self.w, t1, z1), (self.w, t0, z1)]
        else:
            pts = [(t0, self.h, z0), (t1, self.h, z0), (t1, self.h, z1), (t0, self.h, z1)]
        self.poly(pts, col)


def house(c, wall, roof_h, wall_col=("#c9b48f", "#9c8a6c"), base_col=("#7d7b80", "#5d5b62"),
          roof_col=("#45465a", "#33344a"), door="j", door_col="#5a3a22", windows=2, chimney=True, steeple=False):
    w, h = c.w, c.h
    base = min(14, wall // 3)
    along_i = w >= h                                  # ridge direction
    ridge = wall + roof_h
    # back roof plane first
    if along_i:
        c.poly([(0, h / 2, ridge), (w, h / 2, ridge), (w, -.3, wall - 2), (0, -.3, wall - 2)], roof_col[1])
    else:
        c.poly([(w / 2, 0, ridge), (w / 2, h, ridge), (-.3, h, wall - 2), (-.3, 0, wall - 2)], roof_col[1])
    # walls: +i face (shade) and +j face (lit, light from top-left)
    c.face_rect("i", 0, h, 0, wall, wall_col[1])
    c.face_rect("j", 0, w, 0, wall, wall_col[0])
    c.face_rect("i", 0, h, 0, base, base_col[1])
    c.face_rect("j", 0, w, 0, base, base_col[0])
    for side, n in (("i", h), ("j", w)):             # timber posts + windows
        for k in range(1, n):
            c.face_rect(side, k - .06, k + .06, base, wall, "#4a3020")
        for k in range(n):
            if side == door and k == n // 2:
                continue
            for z in ([base + 6] if wall < 40 else [base + 6, wall - 16])[:windows]:
                c.face_rect(side, k + .3, k + .7, z, z + 9, "#e8b44a")
    # gable on the end face
    if along_i:
        c.poly([(w, 0, wall), (w, h, wall), (w, h / 2, ridge)], wall_col[1])
    else:
        c.poly([(0, h, wall), (w, h, wall), (w / 2, h, ridge)], wall_col[0])
    # front roof plane
    if along_i:
        c.poly([(0, h / 2, ridge), (w, h / 2, ridge), (w + .15, h + .3, wall - 2), (0 - .15, h + .3, wall - 2)], roof_col[0])
    else:
        c.poly([(w / 2, 0, ridge), (w / 2, h, ridge), (w + .3, h + .15, wall - 2), (w + .3, -.15, wall - 2)], roof_col[0])
    if chimney:
        ci, cj = (w * .7, h * .35) if along_i else (w * .35, h * .3)
        c.poly([(ci, cj, ridge - 6), (ci + .5, cj, ridge - 6), (ci + .5, cj, ridge + 14), (ci, cj, ridge + 14)], "#6d6a70")
        c.poly([(ci + .5, cj, ridge - 6), (ci + .5, cj + .5, ridge - 6), (ci + .5, cj + .5, ridge + 14), (ci + .5, cj, ridge + 14)], "#55525a")
    if steeple:                                       # bell tower over the door end
        t0, t1, a0, a1, top = w - 1.6, w, h / 2 - .8, h / 2 + .8, ridge + 34
        c.poly([(t1, a0, 0), (t1, a1, 0), (t1, a1, top), (t1, a0, top)], wall_col[1])
        c.poly([(t0, a1, 0), (t1, a1, 0), (t1, a1, top), (t0, a1, top)], wall_col[0])
        c.poly([(t0, a0, top), (t1, a0, top), (t1, a1, top), (t0, a1, top)], roof_col[0])
        apex = ((t0 + t1) / 2, h / 2, top + 30)
        c.poly([(t1, a0, top), (t1, a1, top), apex], roof_col[1])
        c.poly([(t0, a1, top), (t1, a1, top), apex], roof_col[0])
        c.face_rect("i", h / 2 - .3, h / 2 + .3, top - 22, top - 8, "#e8b44a")
    n = h if door == "i" else w
    m = n / 2
    c.face_rect(door, m - .35, m + .35, 0, 20, door_col)
    c.face_rect(door, m - .45, m + .45, 20, 23, "#3a2a1c")


# per lot: wall height, roof height, extras
SPEC = {
    "inn": dict(wall=48, roof_h=40, windows=2),
    "tavern": dict(wall=44, roof_h=38, wall_col=("#b89a74", "#8c7356")),
    "guild": dict(wall=52, roof_h=40, roof_col=("#5a3a3a", "#422a2c")),
    "shop": dict(wall=36, roof_h=32, roof_col=("#3e5466", "#2e3e4e")),
    "smith": dict(wall=34, roof_h=30, wall_col=("#8e8a8c", "#6c686c"), roof_col=("#3a3a40", "#2a2a30")),
    "stash": dict(wall=40, roof_h=16, wall_col=("#9a989e", "#74727a"), roof_col=("#6a686e", "#55535a"), chimney=False, windows=1),
    "clinic": dict(wall=36, roof_h=30, wall_col=("#d6cdb8", "#a89f8a"), roof_col=("#3e5a46", "#2e4434")),
    "church": dict(wall=40, roof_h=44, wall_col=("#a8a6ae", "#807e88"), roof_col=("#3a3a4a", "#2a2a38"), chimney=False, windows=1, steeple=True),
    "cabin": dict(wall=30, roof_h=28, wall_col=("#8a6444", "#664830"), roof_col=("#4a3a2a", "#3a2c20")),
    "house": dict(wall=30, roof_h=28),
}


def lot_canvas(lid):
    for l in LOTS:
        if l[0] == lid:
            _, _, x0, y0, x1, y1, door, _ = l
            return x1 - x0 + 1, y1 - y0 + 1, door
    raise KeyError(lid)


def build(lid, out_dir):
    w, h, door = lot_canvas(lid)
    s = dict(SPEC[lid])
    s["roof_h"] = int(s["roof_h"] * 1.3)  # PixelLab redraws roofs steeper; meet it halfway
    c = Canvas(w, h, s["wall"] + s["roof_h"] + (70 if s.get("steeple") else 24))
    house(c, door=door, **s)
    c.img.save(f"{out_dir}/bo_{lid}.png")
    return c.size


if __name__ == "__main__":
    ids = [k for k in SPEC if k != "house"] if sys.argv[1] == "all" else [sys.argv[1]]
    for k in ids:
        print(k, build(k, sys.argv[2]))
