"""Turns flat "region" drawings into shaded pixel art.

Rules (from common pixel-art practice, light from the top-left):
  * 3 main tones per material at 32x32 (light, base, shadow) plus a small
    highlight and a dark line tone, with hue-shifted ramps (shadows cooler,
    highlights warmer) instead of just darker/lighter.
  * Form shading: the top-left edge of each shape catches light, the right
    third of each row and the bottom edge fall into shadow.
  * Cast shadows: where one material sits right under another (under hair,
    a belt, a helmet), the top row gets the shadow tone.
  * Selective outlines ("selout"): outline pixels on the lit top/left side use
    the material's own dark line color; on the shadow side (bottom/right) a
    near-black. This keeps sprites readable without a heavy black border.

A drawing is a list of strings. Letters are materials; "o" is an outline
pixel; "." is empty. An UPPERCASE letter forces the shadow tone, and a
material can set "flat" to skip shading (eyes, small gems).
"""
from PIL import Image

DEEP = (24, 20, 37)  # Endesga 32 darkest, used for shadow-side outlines


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _mat(ch):
    return ch.lower()


OUTLINE_ALPHA = 201  # outline pixels are saved with this alpha so layers can be stacked nicely


def _prep(rows, materials, w, h, aliases):
    h = h or len(rows)
    w = w or max(len(r) for r in rows)
    grid = [[(rows[y][x] if y < len(rows) and x < len(rows[y]) else ".") for x in range(w)] for y in range(h)]
    aliases = aliases or {}
    forced = {}
    for y in range(h):
        for x in range(w):
            if grid[y][x] in aliases:
                m, t = aliases[grid[y][x]]
                forced[(x, y)] = t
                grid[y][x] = m
    ramps = {}
    for k, v in materials.items():
        if isinstance(v, (list, tuple)) and v and isinstance(v[0], (list, tuple, str)):
            ramp = [hexc(c) if isinstance(c, str) else tuple(c) for c in v]
            while len(ramp) < 5:
                ramp.append(ramp[-1])
            ramps[k] = ramp
        else:
            c = hexc(v) if isinstance(v, str) else tuple(v)
            ramps[k] = [c] * 5
    flat = {k for k, v in materials.items() if not (isinstance(v, (list, tuple)) and v and isinstance(v[0], (list, tuple, str)))}
    return grid, forced, ramps, flat, w, h


def tone_grid(rows, materials, w=None, h=None, aliases=None, manual=False):
    """Works out each pixel's material and tone. Returns (cells, ramps, flat, w, h):
    cells[y][x] is None (empty), "o" (a drawn outline pixel) or (material, tone)."""
    grid, forced, ramps, flat, w, h = _prep(rows, materials, w, h, aliases)

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return grid[y][x]
        return "."

    def is_mat(ch):
        return ch not in ".o" and _mat(ch) in ramps

    cells = [[None] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            ch = grid[y][x]
            if ch == ".":
                continue
            if ch == "o":
                cells[y][x] = "o"
                continue
            m = _mat(ch)
            if m not in ramps:
                continue
            if m in flat:
                cells[y][x] = (m, 0)
                continue
            same = lambda c: c != "." and c != "o" and _mat(c) == m
            up, left, down, right = at(x, y - 1), at(x - 1, y), at(x, y + 1), at(x + 1, y)
            x0 = x
            while x0 - 1 >= 0 and same(grid[y][x0 - 1]):
                x0 -= 1
            x1 = x
            while x1 + 1 < w and same(grid[y][x1 + 1]):
                x1 += 1
            run = x1 - x0 + 1
            frac = (x - x0) / max(1, run - 1) if run > 1 else 0.0
            tone = 2
            if manual:
                tone = 3 if ch.isupper() else 2
                if (x, y) in forced:
                    tone = forced[(x, y)]
                cells[y][x] = (m, tone)
                continue
            if not same(up) and not same(left):
                tone = 0
            elif not same(up) or not same(left):
                tone = 1
            if run >= 3 and frac > 0.66:
                tone = 3
            elif run == 2 and x == x1 and tone == 2:
                tone = 3
            if not same(down) and tone >= 2:
                tone = 3
            if is_mat(up) and not same(up) and m not in flat:
                tone = 3  # cast shadow under another material
            if ch.isupper():
                tone = 3
            if (x, y) in forced:
                tone = forced[(x, y)]
            cells[y][x] = (m, tone)
    return cells, ramps, flat, w, h


def paint(cells, ramps, w, h, outline_all=False, mark_outline=True):
    """Colors a tone grid and adds the selective outline."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return cells[y][x]
        return None

    def is_mat(c):
        return isinstance(c, tuple)

    for y in range(h):
        for x in range(w):
            c = cells[y][x]
            if is_mat(c):
                px[x, y] = ramps[c[0]][c[1]] + (255,)

    def outline_color(x, y):
        nb = [(x, y - 1, "s"), (x - 1, y, "s"), (x, y + 1, "l"), (x + 1, y, "l")]
        lit_mat = None
        for nx, ny, side in nb:
            c = at(nx, ny)
            if is_mat(c):
                if side == "s":
                    return DEEP
                lit_mat = lit_mat or c[0]
        if lit_mat:
            return ramps[lit_mat][4]
        for nx, ny in [(x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1), (x + 1, y + 1)]:
            c = at(nx, ny)
            if is_mat(c):
                return DEEP if ny < y else ramps[c[0]][4]
        return DEEP

    for y in range(h):
        for x in range(w):
            c = cells[y][x]
            if c == "o":
                px[x, y] = outline_color(x, y) + (255,)
            elif outline_all and c is None and any(is_mat(at(x + dx, y + dy)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = outline_color(x, y) + ((OUTLINE_ALPHA if mark_outline else 255),)
    return im


def shade(rows, materials, w=None, h=None, outline_all=False, aliases=None, manual=False, mark_outline=True):
    """materials: letter -> list of 5 colors [highlight, light, base, shadow, line]
    (strings or tuples) or a single color for flat pixels.
    Returns an RGBA Image (with HD on, twice the size: see shade_hd)."""
    if HD > 1:
        return shade_hd(rows, materials, w, h, outline_all, aliases, manual, mark_outline)
    cells, ramps, flat, w, h = tone_grid(rows, materials, w, h, aliases, manual)
    return paint(cells, ramps, w, h, outline_all, mark_outline)


# =====================================================================
# HD: the same drawings at twice the resolution
# =====================================================================
# 1. Work out every pixel's material and tone at 1x (as above).
# 2. Scale2x the tone grid: diagonals get smoothed, nothing new is invented,
#    so key colors survive and the game can still recolor them.
# 3. Refine at 2x: highlights shrink to crisp 1-pixel rims, shadow cores get a
#    1-pixel terminator line, shadow sides pick up a faint reflected light.
# 4. A 1-pixel selective outline (half as heavy as before, relative to size).
HD = 1


def scale2x(cells, w, h):
    def at(x, y):
        x = min(max(x, 0), w - 1)
        y = min(max(y, 0), h - 1)
        return cells[y][x]
    out = [[None] * (w * 2) for _ in range(h * 2)]
    for y in range(h):
        for x in range(w):
            p = cells[y][x]
            a, b, c, d = at(x, y - 1), at(x + 1, y), at(x - 1, y), at(x, y + 1)
            e0 = e1 = e2 = e3 = p
            if a != d and c != b:
                if c == a:
                    e0 = a
                if a == b:
                    e1 = b
                if c == d:
                    e2 = c
                if d == b:
                    e3 = d
            out[2 * y][2 * x] = e0
            out[2 * y][2 * x + 1] = e1
            out[2 * y + 1][2 * x] = e2
            out[2 * y + 1][2 * x + 1] = e3
    return out


def refine(cells, w, h, flat):
    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return cells[y][x]
        return None

    def mat(c):
        return c[0] if isinstance(c, tuple) else None

    out = [row[:] for row in cells]
    for y in range(h):
        for x in range(w):
            c = cells[y][x]
            if not isinstance(c, tuple) or c[0] in flat:
                continue
            m, t = c
            up, left, down, right = at(x, y - 1), at(x - 1, y), at(x, y + 1), at(x + 1, y)
            # Highlights: keep only the outer pixel (crisp 1px shine)
            if t == 0 and isinstance(up, tuple) and isinstance(left, tuple) and up == (m, 0) and left == (m, 0):
                out[y][x] = (m, 1)
            # Light tone: soften its inner edge into the base tone
            elif t == 1 and mat(up) == m and mat(left) == m and up[1] >= 1 and left[1] >= 1 and mat(down) == m and down[1] == 2 and mat(right) == m and right[1] == 2:
                out[y][x] = (m, 2)
            # Terminator: the base pixel right before a shadow gets the shadow tone,
            # but only where the shadow area is thick (gives forms a crisper turn)
            elif t == 2 and mat(right) == m and right[1] == 3 and mat(at(x + 2, y)) == m and at(x + 2, y)[1] == 3 and mat(at(x + 3, y)) == m:
                out[y][x] = (m, 2)
            # Reflected light: a shadow pixel on the bottom/right rim, with deep
            # shadow inside it, lifts back to base so the form doesn't go flat
            if t == 3 and right is None and mat(left) == m and left[1] == 3 and mat(at(x - 2, y)) == m and at(x - 2, y)[1] == 3 and mat(up) == m and mat(down) == m:
                out[y][x] = (m, 2) if (x + y) % 2 == 0 else (m, 3)
    return out


def shade_hd(rows, materials, w=None, h=None, outline_all=False, aliases=None, manual=False, mark_outline=True):
    cells, ramps, flat, w, h = tone_grid(rows, materials, w, h, aliases, manual)
    big = scale2x(cells, w, h)
    big = [[(None if c == "o" else c) for c in row] for row in big]  # outlines are redrawn 1px thin
    thin = []
    for y in range(h):
        for x in range(w):
            if cells[y][x] == "o":
                thin.append((x, y))
    big = refine(big, w * 2, h * 2, flat)
    for (x, y) in thin:
        # a drawn outline pixel (mouths, seams) becomes a 1px line in the middle of its 2x2
        big[2 * y][2 * x] = "o"
        big[2 * y + 1][2 * x + 1] = "o"
    return paint(big, ramps, w * 2, h * 2, outline_all, mark_outline)


def _toward(h, target, amt):
    d = ((target - h + 0.5) % 1.0) - 0.5
    step = max(-amt, min(amt, d))
    return (h + step) % 1.0


def ramp_from(base_hex, shift=0.05, contrast=1.0):
    """5-step ramp [highlight, light, base, shadow, line] from one base color.
    Shadows lean toward blue-purple, highlights toward yellow (hue shifting),
    shadows get a little more saturated, highlights a little less."""
    import colorsys
    base = hexc(base_hex) if isinstance(base_hex, str) else base_hex
    r, g, b = [c / 255 for c in base]
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    out = []
    steps = [(0.24, 0.15, -0.15, 2.0), (0.12, 0.15, -0.05, 1.0), (0, 0, 0, 0), (-0.17, 0.72, 0.06, 1.0), (-0.33, 0.72, 0.04, 1.6)]
    for dl, target, ds, k in steps:
        nh = _toward(hh, target, shift * k) if ss > 0.08 else hh
        nl = min(0.96, max(0.05, ll + dl * contrast))
        ns = min(1, max(0, ss + ds))
        rr, gg, bb = colorsys.hls_to_rgb(nh, nl, ns)
        out.append((int(rr * 255), int(gg * 255), int(bb * 255)))
    return out


def stack(canvas, layer, at=(0, 0)):
    """Pastes a layer onto the canvas. Marked outline pixels only draw on empty
    space; over existing pixels they just darken them a little (a soft cast line)."""
    cw, chh = canvas.size
    src = layer.load()
    dst = canvas.load()
    for y in range(layer.height):
        for x in range(layer.width):
            r, g, b, a = src[x, y]
            if a == 0:
                continue
            X, Y = x + at[0], y + at[1]
            if not (0 <= X < cw and 0 <= Y < chh):
                continue
            if a == OUTLINE_ALPHA:
                d = dst[X, Y]
                if d[3] == 0:
                    dst[X, Y] = (r, g, b, 255)
                else:
                    dst[X, Y] = (int(d[0] * 0.78), int(d[1] * 0.74), int(d[2] * 0.8), 255)
            else:
                dst[X, Y] = (r, g, b, 255)
    return canvas
