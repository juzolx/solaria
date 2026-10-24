"""Cleanup pipeline for AI pixel art -> Solaria game art (palette, 2x grid, outline).

Steps (each a function so contact sheets can show them):
  remove_bg   flood-fill the flat light background (and the soft drop shadow) to transparent
  find_grid   locate the AI's own pixel grid (cell size + phase) from edge energy
  grid_sample take the median colour of the centre of every cell -> "native" pixel image
  crop        trim to the opaque bounding box
  shrink      resize the native image to the game's art-pixel size (area average, hard alpha,
              keeps dark ink lines that would otherwise vanish)
  quantize    map to the 74-colour Solaria palette (OKLab nearest) and cap the colour count
  outline     1 art-pixel ring of #0e0812 around the silhouette (and edge ink -> outline)
  rim         top-left light: the first lit pixel on the top/left edge moves one ramp step lighter
  place       put the art on a fixed canvas (feet on the bottom row) and scale 2x nearest
"""
import numpy as np
from PIL import Image
from collections import deque

PALETTE = ["be4a2f", "d77643", "ead4aa", "e4a672", "b86f50", "733e39", "3e2731", "a22633",
	"e43b44", "f77622", "feae34", "fee761", "63c74d", "3e8948", "265c42", "193c3e", "124e89", "0099db",
	"2ce8f5", "ffffff", "c0cbdc", "8b9bb4", "5a6988", "3a4466", "262b44", "181425", "ff0044", "68386c",
	"b55088", "f6757a", "e8b796", "c28569", "a8624a", "7fb2e0", "4f8fba", "3c5e8b", "253a5e", "172038",
	"f4e6c4", "a3825f", "5a3f35", "8f563b", "fff4a3", "c8b08a", "a4dddb", "d0da91", "a8ca58", "75a743",
	"ffb0b0", "e8b8f0", "c27ad8", "9a4fc0", "c8f2ee", "4fb0c6", "2e7896", "2a1a1e", "5a72a8", "d4ecaa",
	"d0dcc8", "a8b89a", "7f9478", "566a56", "e4e0ec", "bdb6cc", "7d8798", "545d70", "c8a060", "9a7040",
	"6a4a28", "a8a8ba", "1f1d24", "34323b", "4a4852", "625f6a"]
OUTLINE = (14, 8, 18)
PAL = np.array([[int(h[i:i + 2], 16) for i in (0, 2, 4)] for h in PALETTE], dtype=np.float64)


def _lin(x):
    x = x / 255.0
    return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)


def oklab(rgb):
    rgb = np.asarray(rgb, dtype=np.float64)
    r, g, b = _lin(rgb[..., 0]), _lin(rgb[..., 1]), _lin(rgb[..., 2])
    l = np.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = np.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = np.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return np.stack([0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                     1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                     0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s], -1)


PAL_LAB = oklab(PAL)


def to_np(im):
    return np.array(im.convert("RGBA"))


def to_im(a):
    return Image.fromarray(a.astype(np.uint8), "RGBA")


# ------------------------------------------------------------------ background
def remove_bg(im, light=185, chroma=28, shadow_from=0.75):
    """Flood from the border through light, low-chroma pixels (white bg + grey drop shadow)."""
    a = to_np(im).copy()
    rgb = a[..., :3].astype(int)
    mx, mn = rgb.max(-1), rgb.min(-1)
    bgish = (mn >= light) & ((mx - mn) <= chroma)
    h, w = bgish.shape
    seen = np.zeros_like(bgish)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and bgish[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    a[seen, 3] = 0
    # the soft grey drop shadow under the feet: low-chroma mid greys reachable from the
    # background in the lowest 25% of the figure (the figure's own dark outline stops the flood)
    ys = np.where((a[..., 3] > 0).any(1))[0]
    if len(ys):
        y0 = int(ys[0] + (ys[-1] - ys[0]) * shadow_from)
        shad = (mn >= 105) & ((mx - mn) <= 22)
        shad[:y0] = False
        q = deque((y, x) for y, x in zip(*np.where(seen)) if y >= y0 - 1)
        while q:
            y, x = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and shad[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True; q.append((ny, nx))
        a[seen, 3] = 0
    return to_im(a)


def keep_largest(a, min_frac=0.02):
    """Drop small floating blobs (stray sparkles, extra mini figures)."""
    op = a[..., 3] > 0
    h, w = op.shape
    lab = np.zeros((h, w), int); n = 0; sizes = {}
    for y in range(h):
        for x in range(w):
            if op[y, x] and lab[y, x] == 0:
                n += 1; q = deque([(y, x)]); lab[y, x] = n; c = 0
                while q:
                    cy, cx = q.popleft(); c += 1
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and op[ny, nx] and lab[ny, nx] == 0:
                                lab[ny, nx] = n; q.append((ny, nx))
                sizes[n] = c
    if not sizes:
        return a
    big = max(sizes.values())
    keep = [k for k, v in sizes.items() if v >= big * min_frac]
    a = a.copy()
    a[~np.isin(lab, keep), 3] = 0
    return a


# ------------------------------------------------------------------ grid
def _period_score(g, p):
    best = (0, 0)
    n = len(g)
    for ph in np.arange(0, p, 0.5):
        idx = np.round(np.arange(ph, n - 1, p)).astype(int)
        s = g[idx].mean()
        if s > best[0]:
            best = (s, ph)
    return best


def find_grid(im):
    """Cell size and phase of the AI's pixel grid (it is close to 8 px but drifts per image)."""
    a = to_np(im).astype(float)
    lum = a[..., :3].mean(-1) * (a[..., 3] > 0)
    gx = np.abs(np.diff(lum, axis=1)).sum(0)
    gy = np.abs(np.diff(lum, axis=0)).sum(1)
    res = []
    for g in (gx, gy):
        m = g.mean() + 1e-9
        cands = []
        for p in np.arange(5.0, 14.01, 0.125):
            s, ph = _period_score(g, p)
            cands.append((s / m, p, ph))
        # prefer the largest period that scores within 3% of the best (avoid sub-harmonics)
        top = max(c[0] for c in cands)
        good = [c for c in cands if c[0] >= top * 0.97]
        sc, p, ph = max(good, key=lambda c: c[1])
        res.append((p, ph, sc))
    return res  # [(px, phase_x, score), (py, phase_y, score)]


def grid_sample(im, grid):
    a = to_np(im)
    (px, phx, _), (py, phy, _) = grid
    h, w = a.shape[:2]
    xs = np.arange(phx, w - 1, px); ys = np.arange(phy, h - 1, py)
    out = np.zeros((len(ys) - 1, len(xs) - 1, 4), np.uint8)
    for j in range(len(ys) - 1):
        for i in range(len(xs) - 1):
            x0, x1 = xs[i], xs[i + 1]; y0, y1 = ys[j], ys[j + 1]
            cx0, cx1 = int(x0 + (x1 - x0) * 0.25), int(np.ceil(x0 + (x1 - x0) * 0.75))
            cy0, cy1 = int(y0 + (y1 - y0) * 0.25), int(np.ceil(y0 + (y1 - y0) * 0.75))
            blk = a[cy0:cy1, cx0:cx1].reshape(-1, 4)
            if (blk[:, 3] > 0).mean() < 0.5:
                continue
            blk = blk[blk[:, 3] > 0]
            out[j, i, :3] = np.median(blk[:, :3], 0)
            out[j, i, 3] = 255
    return to_im(out)


def crop(im):
    bb = im.getbbox()
    return im.crop(bb) if bb else im


# ------------------------------------------------------------------ shrink
def shrink(im, height=None, width=None, ink=0.33, ink_lum=60):
    """Area-average resize to the target art size with hard alpha. A cell whose source pixels
    are at least `ink` dark line pixels stays dark, so internal outlines survive."""
    a = to_np(im).astype(float)
    h, w = a.shape[:2]
    if height:
        s = height / h
    else:
        s = width / w
    nh, nw = max(1, round(h * s)), max(1, round(w * s))
    out = np.zeros((nh, nw, 4))
    lum = a[..., :3].mean(-1)
    for j in range(nh):
        for i in range(nw):
            y0, y1 = int(j / s), max(int(j / s) + 1, int(np.ceil((j + 1) / s)))
            x0, x1 = int(i / s), max(int(i / s) + 1, int(np.ceil((i + 1) / s)))
            blk = a[y0:y1, x0:x1].reshape(-1, 4)
            op = blk[:, 3] > 0
            if op.mean() < 0.5:
                continue
            b = blk[op]
            l = lum[y0:y1, x0:x1].reshape(-1)[op]
            dark = l < ink_lum
            if dark.mean() >= ink:
                out[j, i, :3] = b[dark, :3].mean(0)
            else:
                # drop the darkest third of non-ink so mid tones stay clean
                out[j, i, :3] = b[~dark, :3].mean(0) if (~dark).any() else b[:, :3].mean(0)
            out[j, i, 3] = 255
    return to_im(out)


# ------------------------------------------------------------------ palette
def shrink_mode(im, height=None, width=None, ink_lum=0.30, ink=0.30, max_colors=20):
    """Palette first, then each output cell takes the most common palette colour of its source
    block (ink wins at >= `ink` share). Keeps crisp colours and small dark features (eyes, belts)."""
    q = quantize(im, max_colors)
    a = to_np(q)
    h, w = a.shape[:2]
    s = height / h if height else width / w
    nh, nw = max(1, round(h * s)), max(1, round(w * s))
    out = np.zeros((nh, nw, 4), np.uint8)
    L = oklab(a[..., :3].astype(float))[..., 0]
    for j in range(nh):
        for i in range(nw):
            y0, y1 = int(j / s), max(int(j / s) + 1, int(round((j + 1) / s)))
            x0, x1 = int(i / s), max(int(i / s) + 1, int(round((i + 1) / s)))
            blk = a[y0:y1, x0:x1].reshape(-1, 4)
            op = blk[:, 3] > 0
            if op.mean() < 0.5:
                continue
            b = blk[op]; l = L[y0:y1, x0:x1].reshape(-1)[op]
            dark = l < ink_lum
            pick = b[dark] if dark.mean() >= ink else (b[~dark] if (~dark).any() else b)
            keys, cnt = np.unique(pick[:, :3], axis=0, return_counts=True)
            out[j, i, :3] = keys[cnt.argmax()]
            out[j, i, 3] = 255
    return to_im(out)


def nearest_idx(rgb):
    lab = oklab(rgb)
    d = ((lab[..., None, :] - PAL_LAB) ** 2).sum(-1)
    return d.argmin(-1)


def quantize(im, max_colors=16, exclude=()):
    a = to_np(im).copy()
    op = a[..., 3] > 0
    rgb = a[..., :3][op]
    allowed = np.array([i for i in range(len(PAL)) if PALETTE[i] not in exclude])
    lab = oklab(rgb)
    d = ((lab[:, None, :] - PAL_LAB[allowed]) ** 2).sum(-1)
    idx = allowed[d.argmin(-1)]
    if max_colors:
        u, c = np.unique(idx, return_counts=True)
        if len(u) > max_colors:
            keep = u[np.argsort(-c)[:max_colors]]
            d2 = ((lab[:, None, :] - PAL_LAB[keep]) ** 2).sum(-1)
            idx = keep[d2.argmin(-1)]
    a[..., :3][op] = PAL[idx].astype(np.uint8)
    return to_im(a)


def is_ink(c):
    l = oklab(np.array(c[:3], float))[0]
    return l < 0.28


def outline(im, edge_ink=True):
    """Pad 1 px, turn dark edge pixels into the outline colour, ring the silhouette."""
    a = to_np(im)
    h, w = a.shape[:2]
    p = np.zeros((h + 2, w + 2, 4), np.uint8); p[1:-1, 1:-1] = a
    op = p[..., 3] > 0
    nb = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb |= np.roll(np.roll(~op, dy, 0), dx, 1)
    edge = op & nb
    if edge_ink:
        lab = oklab(p[..., :3].astype(float))[..., 0]
        p[edge & (lab < 0.30), :3] = OUTLINE
    body = op & ~np.all(p[..., :3] == OUTLINE, -1)
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(body, dy, 0), dx, 1)
    ring &= ~op
    p[ring, :3] = OUTLINE; p[ring, 3] = 255
    return to_im(p)


def lighter(rgb):
    """The palette colour one step lighter with a similar hue (for rim light)."""
    lab = oklab(np.array(rgb, float))
    best, bd = None, 1e9
    for i, pl in enumerate(PAL_LAB):
        dl = pl[0] - lab[0]
        if 0.04 < dl < 0.22:
            dc = ((pl[1:] - lab[1:]) ** 2).sum()
            score = dc * 4 + (dl - 0.09) ** 2
            if score < bd:
                bd, best = score, i
    return tuple(PAL[best].astype(int)) if best is not None and bd < 0.02 else tuple(rgb)


def rim(im):
    """Top-left light: a body pixel whose upper neighbour AND left neighbour are outline/clear
    (an upper-left corner of the silhouette), or whose upper neighbour is outline in the left
    half of the figure, moves one palette step lighter. Subtle on purpose."""
    a = to_np(im).copy()
    h, w = a.shape[:2]
    src = a.copy()
    cols = np.where((src[..., 3] > 0).any(0))[0]
    mid = (cols[0] + cols[-1]) / 2 if len(cols) else w / 2
    def edge(y, x):
        return y < 0 or x < 0 or src[y, x, 3] == 0 or tuple(src[y, x, :3]) == OUTLINE
    for y in range(h):
        for x in range(w):
            if src[y, x, 3] == 0 or tuple(src[y, x, :3]) == OUTLINE:
                continue
            up, left = edge(y - 1, x), edge(y, x - 1)
            if (up and left) or (up and x < mid - 1) or (left and y < h * 0.45):
                a[y, x, :3] = lighter(src[y, x, :3])
    return to_im(a)


def flip(im):
    return im.transpose(Image.FLIP_LEFT_RIGHT)


def place(im, canvas=(34, 34), anchor_x=None, bottom=0, scale=2):
    """Feet on the bottom row (minus `bottom`), centred (or anchor_x = column of the body centre)."""
    c = Image.new("RGBA", canvas, (0, 0, 0, 0))
    w, h = im.size
    x = (canvas[0] - w) // 2 if anchor_x is None else anchor_x - w // 2
    y = canvas[1] - h - bottom
    c.alpha_composite(im, (x, y))
    return c.resize((canvas[0] * scale, canvas[1] * scale), Image.NEAREST)


def colours(im):
    a = to_np(im)
    return len({tuple(p[:3]) for p in a.reshape(-1, 4) if p[3] > 0})


def pipeline(path, height, max_colors=16, mirror=False, edge_ink=True, light=185, do_rim=True, mode=True):
    raw = Image.open(path).convert("RGB")
    nobg = to_im(keep_largest(to_np(remove_bg(raw, light=light))))
    grid = find_grid(nobg)
    native = crop(to_im(keep_largest(to_np(grid_sample(nobg, grid)))))
    small = shrink_mode(native, height=height) if mode else shrink(native, height=height)
    q = quantize(small, max_colors)
    o = outline(q, edge_ink)
    if do_rim:
        o = rim(o)
    if mirror:
        o = flip(o)
        native = flip(native)
    return {"raw": raw, "nobg": nobg, "grid": grid, "native": native, "small": small, "final": o}


# ------------------------------------------------------------------ sheets -> figures
def components(a, min_px=30):
    """8-connected opaque blobs of a small (native) image -> list of (bbox, mask)."""
    op = a[..., 3] > 0
    h, w = op.shape
    lab = np.zeros((h, w), int); out = []; n = 0
    for y in range(h):
        for x in range(w):
            if op[y, x] and lab[y, x] == 0:
                n += 1; q = deque([(y, x)]); lab[y, x] = n; pts = []
                while q:
                    cy, cx = q.popleft(); pts.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and op[ny, nx] and lab[ny, nx] == 0:
                                lab[ny, nx] = n; q.append((ny, nx))
                if len(pts) >= min_px:
                    ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
                    out.append(((min(xs), min(ys), max(xs) + 1, max(ys) + 1), lab == n))
    return out


def native_of(path, light=185):
    raw = Image.open(path).convert("RGB")
    nobg = remove_bg(raw, light=light)
    grid = find_grid(nobg)
    return raw, nobg, grid, grid_sample(nobg, grid)


def figures(path, hmin=18, hmax=60, light=185):
    """Every separate figure on a sheet, at the AI's native pixel size."""
    raw, nobg, grid, nat = native_of(path, light)
    a = to_np(nat)
    res = []
    for (x0, y0, x1, y1), m in components(a):
        hgt = y1 - y0
        if hmin <= hgt <= hmax and (x1 - x0) <= hgt * 1.6:
            sub = a[y0:y1, x0:x1].copy()
            sub[~m[y0:y1, x0:x1], 3] = 0
            res.append({"img": to_im(sub), "box": (x0, y0, x1, y1), "grid": grid,
                        "src_box": tuple(int(v) for v in (x0 * grid[0][0] + grid[0][1], y0 * grid[1][0] + grid[1][1],
                                                          x1 * grid[0][0] + grid[0][1], y1 * grid[1][0] + grid[1][1]))})
    return raw, res


def strip_shadow(im, rows=4):
    """Native figure: peel grey, low-chroma pixels off the bottom rows where they touch clear
    (the AI's drop shadow), repeatedly."""
    a = to_np(im).copy()
    h, w = a.shape[:2]
    lab = oklab(a[..., :3].astype(float))
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    grey = (chroma < 0.035) & (lab[..., 0] > 0.45)
    changed = True
    while changed:
        changed = False
        for y in range(max(0, h - rows), h):
            for x in range(w):
                if a[y, x, 3] and grey[y, x]:
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = y + dy, x + dx
                        if not (0 <= ny < h and 0 <= nx < w) or a[ny, nx, 3] == 0:
                            a[y, x, 3] = 0; changed = True; break
    return crop(to_im(a))


def clean_figure(im, height=None, max_colors=18, mirror=False, do_rim=True, shadow=True):
    """Native figure -> game art: shadow off, shrink only if taller than `height`, palette, outline, rim."""
    f = strip_shadow(im) if shadow else im
    if height and f.height > height:
        f = shrink_mode(f, height=height, max_colors=max_colors + 4)
    q = quantize(f, max_colors)
    o = outline(q)
    if do_rim:
        o = rim(o)
    return flip(o) if mirror else o


def clean_building(path, width=None, max_colors=24, light=170, do_rim=False):
    """Raw building render -> native grid pixels -> fit width -> palette -> outline."""
    raw = Image.open(path).convert("RGB")
    nobg = to_im(keep_largest(to_np(remove_bg(raw, light=light, chroma=30, shadow_from=0.3)), min_frac=0.05))
    grid = find_grid(nobg)
    native = crop(to_im(keep_largest(to_np(grid_sample(nobg, grid)), min_frac=0.05)))
    f = native
    if width and f.width > width:
        f = shrink_mode(f, width=width, max_colors=max_colors + 6)
    q = quantize(f, max_colors)
    o = outline(q)
    if do_rim:
        o = rim(o)
    return {"raw": raw, "native": native, "final": o, "grid": grid}
