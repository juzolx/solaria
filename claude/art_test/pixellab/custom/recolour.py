"""Code-side recolours for the PixelLab hero (no generations): hair colour + skin tone.
Materials are found per frame: outline = near-black, shirt = near-white, metal = low-saturation grey,
skin = light warm pixels, hair = remaining pixels in the head band (top HEAD_FRAC of the figure).
Recolour keeps each pixel's relative brightness and maps it onto a target ramp."""
import colorsys

HEAD_FRAC = 0.42

HAIR = {  # dark -> light ramps
    "brown": None,  # original
    "black": [(18, 16, 24), (34, 30, 40), (52, 48, 60), (74, 70, 84), (98, 94, 110)],
    "blond": [(92, 62, 30), (150, 108, 52), (196, 154, 82), (226, 194, 120), (246, 226, 168)],
    "red": [(70, 20, 14), (118, 38, 22), (164, 62, 34), (204, 96, 50), (232, 140, 86)],
    "ash": [(52, 50, 56), (88, 86, 92), (128, 126, 130), (170, 168, 170), (210, 208, 206)],
    "pink": [(92, 34, 64), (150, 64, 108), (204, 108, 152), (232, 154, 190), (248, 200, 222)],
    "white": [(96, 100, 116), (150, 154, 168), (196, 200, 210), (228, 230, 236), (250, 250, 252)],
}
SKIN = {
    "fair": None,
    "tan": [(120, 70, 44), (170, 108, 70), (204, 144, 100), (226, 178, 136)],
    "brown": [(70, 38, 26), (112, 66, 42), (148, 96, 64), (176, 126, 90)],
    "deep": [(40, 22, 18), (70, 40, 30), (100, 62, 44), (128, 86, 62)],
}


def lum(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def kind(c):
    r, g, b = c
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if lum(c) < 22:
        return "outline"
    if s < 0.12 and v > 0.85:
        return "shirt"
    if s < 0.22 and abs(r - b) < 30:
        return "metal"
    if v > 0.62 and 0.02 < h < 0.11 and s > 0.25:
        return "skin"
    return "other"


def ramp_at(ramp, t):
    t = max(0.0, min(1.0, t)) * (len(ramp) - 1)
    i = min(int(t), len(ramp) - 2)
    f = t - i
    return tuple(int(round(ramp[i][k] * (1 - f) + ramp[i + 1][k] * f)) for k in range(3))


def masks(im):
    """{(x, y): material} for one RGBA frame.
    Hair = head-band pixels that are not outline/shirt/metal, connected to the silhouette edge
    (so eyes and brows enclosed by skin stay 'face'). In the head band only bright skin counts as skin,
    so the warm hair highlights stay hair."""
    bb = im.getbbox()
    head_bottom = bb[1] + (bb[3] - bb[1]) * HEAD_FRAC
    out, cand = {}, set()
    px = im.load()
    for y in range(bb[1], bb[3]):
        for x in range(bb[0], bb[2]):
            p = px[x, y]
            if not p[3]:
                continue
            k = kind(p[:3])
            if y < head_bottom and k == "skin" and colorsys.rgb_to_hsv(*(c / 255 for c in p[:3]))[2] < 0.78:
                k = "other"
            if k == "other":
                if y < head_bottom:
                    cand.add((x, y)); k = "face"
                else:
                    k = "cloth"
            out[(x, y)] = k

    def edge(x, y):  # touches transparency or the outline ring
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in out or out[q] == "outline":
                return True
        return False

    todo = [c for c in cand if edge(*c)]
    seen = set(todo)
    while todo:
        x, y = todo.pop()
        out[(x, y)] = "hair"
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                q = (x + dx, y + dy)
                if q in cand and q not in seen:
                    seen.add(q); todo.append(q)
    return out


def recolour(im, hair=None, skin=None, ranges=None, hair_px=None):
    """ranges = {material: (lo, hi)} luminance range of the ORIGINAL art, shared by all frames (from ref_ranges).
    hair_px: exact hair pixels (from headswap.swap(return_mask=True)) so long hair below the head recolours too."""
    im = im.copy()
    px = im.load()
    m = masks(im)
    if hair_px is not None:
        m = {p: ("hair" if p in hair_px else ("face" if k == "hair" else k)) for p, k in m.items()}
    for (x, y), k in m.items():
        ramp = {"hair": hair, "skin": skin}.get(k)
        if not ramp:
            continue
        lo, hi = ranges[k]
        p = px[x, y]
        px[x, y] = ramp_at(ramp, (lum(p[:3]) - lo) / max(1, hi - lo)) + (p[3],)
    return im


def ref_ranges(frames):
    vals = {"hair": [], "skin": []}
    for im in frames:
        px = im.load()
        for (x, y), k in masks(im).items():
            if k in vals:
                vals[k].append(lum(px[x, y][:3]))
    out = {}
    for k, v in vals.items():
        v.sort()
        out[k] = (v[len(v) // 20], v[-len(v) // 20 - 1])  # 5th-95th percentile
    return out
