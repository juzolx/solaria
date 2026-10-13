"""Native 64x64 hero art (v0.11, "style A").

The old hero art was drawn on a 32x32 grid and blown up 2x. This draws every
hero layer straight at 64x64 with shapes (ellipses, polygons, lines), then
shades it with a soft height field lit from the top-left, adds hue-shifted
ramps and selective outlines. Recolorable parts are saved in the KEY colors
make_art.py uses (skin red, hair green, gear yellow, trim magenta, eyes blue),
so skin tones, hair colors and gear materials still swap in the game, and
gear, weapons and armor still attach to the body.

Coordinates: the body stands in a 64x64 layer with its feet on row 63,
facing right. Sprites.gd places the layer at BODY_OFFSET inside its canvas.
"""
import math
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, binary_dilation

W = 64
DEEP = (24, 20, 37)
OUTLINE_ALPHA = 201
LIGHT = np.array([-0.62, -0.78])


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    """A 64x64 grid of materials. Draw with shapes; tones are worked out by render()."""

    def __init__(self, w=W, h=W):
        self.w, self.h = w, h
        self.g = [[None] * w for _ in range(h)]   # material letter
        self.tone = {}                             # (x, y) -> forced tone
        self.reg = [[None] * w for _ in range(h)]  # body region name (for gear)
        self.sphere = {}                           # material -> (cx, cy, r): lit like a ball (heads, hair)
        self.form = set()                          # materials shaded by their edges (clean, for cloth and metal)
        self.nohi = set()                          # materials that never get the highlight tone (cloth)

    # ---- drawing ----
    def P(self, x, y, c, t=None, reg=None):
        x, y = int(round(x)) if isinstance(x, float) else x, int(round(y)) if isinstance(y, float) else y
        if 0 <= x < self.w and 0 <= y < self.h:
            if c is None:
                self.g[y][x] = None
                self.tone.pop((x, y), None)
                return
            self.g[y][x] = c
            if t is None:
                self.tone.pop((x, y), None)
            else:
                self.tone[(x, y)] = t
            if reg:
                self.reg[y][x] = reg

    def ell(self, cx, cy, rx, ry, c, t=None, reg=None):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                    self.P(x, y, c, t, reg)

    def poly(self, pts, c, t=None, reg=None):
        ys = [p[1] for p in pts]
        xs = [p[0] for p in pts]
        for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
            for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
                inside = False
                j = len(pts) - 1
                for i in range(len(pts)):
                    xi, yi = pts[i]
                    xj, yj = pts[j]
                    if ((yi > y + 0.5) != (yj > y + 0.5)) and (x + 0.5 < (xj - xi) * (y + 0.5 - yi) / (yj - yi) + xi):
                        inside = not inside
                    j = i
                if inside:
                    self.P(x, y, c, t, reg)

    def line(self, pts, c, t=None, reg=None):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
            for i in range(n):
                tt = i / max(1, n - 1)
                self.P(round(x0 + (x1 - x0) * tt), round(y0 + (y1 - y0) * tt), c, t, reg)

    def rect(self, x0, y0, x1, y1, c, t=None, reg=None):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.P(x, y, c, t, reg)

    def fill_mask(self, m, c, t=None, reg=None):
        ys, xs = np.nonzero(m)
        for y, x in zip(ys, xs):
            self.P(int(x), int(y), c, t, reg)

    # ---- reading ----
    def mask(self, mats=None):
        m = np.zeros((self.h, self.w), bool)
        for y in range(self.h):
            for x in range(self.w):
                c = self.g[y][x]
                if c is not None and (mats is None or c in mats):
                    m[y, x] = True
        return m

    def region(self, *names):
        m = np.zeros((self.h, self.w), bool)
        for y in range(self.h):
            for x in range(self.w):
                if self.reg[y][x] in names:
                    m[y, x] = True
        return m

    # ---- shading ----
    def tones(self, soft=1.6, strength=6.0):
        """Each material is a soft pillow: blur its mask into a height field and
        light the slopes from the top-left. Materials set in self.sphere are lit
        as part of a ball instead (heads and hair read round)."""
        grid = np.array([[c if c is not None else "." for c in row] for row in self.g])
        out = np.full((self.h, self.w), -1)
        for m in set(grid.flatten()) - {"."}:
            mask = (grid == m)
            if m in self.form:
                ys, xs = np.nonzero(mask)
                for y, x in zip(ys, xs):
                    def run(dx, dy):
                        n = 0
                        X, Y = x + dx, y + dy
                        while 0 <= X < self.w and 0 <= Y < self.h and mask[Y, X] and n < 4:
                            n += 1
                            X += dx
                            Y += dy
                        return n
                    dr, db, dl, du = run(1, 0), run(0, 1), run(-1, 0), run(0, -1)
                    t = 1
                    if dr <= 1 or db <= 0:
                        t = 2
                    if dr == 0 and db <= 1:
                        t = 3
                    if (dl == 0 or du == 0) and dr >= 2 and db >= 1:
                        t = 0
                    out[y, x] = t
                continue
            if m in self.sphere:
                cx, cy, r = self.sphere[m]
                L = np.array([-0.45, -0.7, 0.55])
                L = L / np.linalg.norm(L)
                ys, xs = np.nonzero(mask)
                for y, x in zip(ys, xs):
                    dx = (x + 0.5 - cx) / r
                    dy = (y + 0.5 - cy) / r
                    dz = math.sqrt(max(0.0, 1 - dx * dx - dy * dy))
                    i = dx * L[0] + dy * L[1] + dz * L[2]
                    out[y, x] = 0 if i > 0.86 else 1 if i > 0.62 else 2 if i > 0.3 else 3
                continue
            hgt = gaussian_filter(mask.astype(float), soft)
            gy, gx = np.gradient(hgt)
            lit = -(gx * LIGHT[0] + gy * LIGHT[1]) * strength + (hgt - 0.5) * 0.6
            t = np.where(lit > 0.85, 0, np.where(lit > 0.3, 1, np.where(lit > -0.18, 2, 3)))
            out[mask] = t[mask]
        # Clean-up: no lone pixels of a different tone inside a material
        # (they read as noise), and cloth never gets a highlight tone.
        for y in range(self.h):
            for x in range(self.w):
                m = self.g[y][x]
                if m is None or (x, y) in self.tone:
                    continue
                nb = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
                same = [out[b, a] for a, b in nb if 0 <= a < self.w and 0 <= b < self.h and self.g[b][a] == m]
                if len(same) >= 3 and all(v == same[0] for v in same) and out[y, x] != same[0]:
                    out[y, x] = same[0]
                if m in self.nohi and out[y, x] == 0:
                    out[y, x] = 1
        for (x, y), t in self.tone.items():
            if self.g[y][x] is not None:
                out[y, x] = t
        return out

    def render(self, ramps, outline=True, keep_mask=None, cast=True, soft=1.6, out_alpha=OUTLINE_ALPHA, shadow_under=(), tone_fn=None):
        """ramps: material -> list of 5 colors (light..line) or one color (flat).
        keep_mask: only these pixels are kept (layers drawn over a body).
        shadow_under: materials that darken a step where another material sits right above them."""
        t = self.tones(soft)
        if tone_fn is not None:
            t = tone_fn(self, t)
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        px = img.load()
        for y in range(self.h):
            for x in range(self.w):
                m = self.g[y][x]
                if m is None or (keep_mask is not None and not keep_mask[y, x]):
                    continue
                r = ramps[m]
                tone = int(t[y, x])
                if cast and (x, y) not in self.tone and m in shadow_under and y > 0:
                    up = self.g[y - 1][x]
                    if up is not None and up != m and tone < 3:
                        tone += 1
                c = r[min(tone, len(r) - 1)] if isinstance(r, list) else r
                c = hexc(c) if isinstance(c, str) else tuple(c)
                px[x, y] = c + (255,)
        if outline:
            add_outline(img, self, ramps, out_alpha)
        return img


def add_outline(img, cv, ramps, alpha=OUTLINE_ALPHA):
    """Selective outline: on the lit side (above / left of a shape) the shape's own
    darkest tone; on the shadow side a near-black. Saved with alpha 201 so stacked
    layers only draw it on empty space."""
    px = img.load()
    w, h = img.size
    src = img.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3]:
                continue
            nb = [(x, y - 1), (x - 1, y), (x, y + 1), (x + 1, y)]
            if not any(0 <= a < w and 0 <= b < h and src[a, b][3] == 255 for a, b in nb):
                continue
            lit = None
            for a, b in [(x, y + 1), (x + 1, y)]:
                if 0 <= a < w and 0 <= b < h and src[a, b][3] == 255:
                    m = cv.g[b][a]
                    if m in ramps and isinstance(ramps[m], list):
                        lit = ramps[m]
            shadow_side = any(0 <= a < w and 0 <= b < h and src[a, b][3] == 255 for a, b in [(x, y - 1), (x - 1, y)])
            c = DEEP if (shadow_side or lit is None) else (hexc(lit[4]) if isinstance(lit[4], str) else tuple(lit[4]))
            px[x, y] = c + (alpha,)


def stack(dst, src, at=(0, 0)):
    """Like Sprites._stack: outline pixels (alpha 201) only draw on empty space."""
    dp = dst.load()
    sp = src.load()
    for y in range(src.height):
        for x in range(src.width):
            c = sp[x, y]
            if c[3] == 0:
                continue
            X, Y = x + at[0], y + at[1]
            if not (0 <= X < dst.width and 0 <= Y < dst.height):
                continue
            if c[3] == OUTLINE_ALPHA:
                d = dp[X, Y]
                if d[3] == 0:
                    dp[X, Y] = c[:3] + (255,)
                else:
                    dp[X, Y] = (int(d[0] * 0.85), int(d[1] * 0.85), int(d[2] * 0.85), d[3])
            else:
                dp[X, Y] = c
    return dst
