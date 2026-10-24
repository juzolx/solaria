"""Cuts the little ground tile PixelLab bakes under an isometric building (grass, dirt or a
raised block with dark sides), so the building stands on the town's own ground.
deslab(im, band, kinds) -> (image, base) where base is the bottom corner measured BEFORE the
cut, so the building keeps its place on the grid."""
from PIL import Image


def _kind(c):
    r, g, b = c[:3]
    if g > r + 6 and g >= b:
        return "grass"
    if r >= g > b and r - b > 25:
        return "dirt"
    if r + g + b > 330 and abs(r - g) < 30 and b > 120:
        return "sand"
    return "other"


def base_of(im):
    a = im.getchannel("A").load()
    for y in range(im.height - 1, -1, -1):
        xs = [x for x in range(im.width) if a[x, y]]
        if xs:
            return (min(xs) + max(xs)) / 2, y


def deslab(im, band, kinds=("grass", "dirt", "sand"), side=0):
    """Removes pixels of `kinds` lying within `band` px above each column's lowest pixel, and
    with side > 0 every pixel within `side` px of that edge (a raised slab's dark sides)."""
    im = im.convert("RGBA")
    base = base_of(im)
    px = im.load()
    w, h = im.size
    bottom = []
    for x in range(w):
        ys = [y for y in range(h) if px[x, y][3]]
        bottom.append(max(ys) if ys else -1)
    for x in range(w):
        yb = bottom[x]
        if yb < 0:
            continue
        for y in range(max(0, yb - band), yb + 1):
            c = px[x, y]
            if not c[3]:
                continue
            if yb - y < side or _kind(c) in kinds:
                px[x, y] = (0, 0, 0, 0)
    # drop specks the cut left behind
    for y in range(h):
        for x in range(w):
            if px[x, y][3]:
                n = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                        if 0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3])
                if n <= 1:
                    px[x, y] = (0, 0, 0, 0)
    return im, base


if __name__ == "__main__":
    import sys
    cfg = {"gen/house_iso": (16, ("grass",), 2), "gen/smith_iso": (16, ("dirt", "grass"), 2),
           "gen/gate_iso": (12, ("grass",), 9), "gen3/tower": (14, ("grass",), 0),
           "gen3/gatehouse": (14, ("grass", "sand"), 0)}
    s = Image.new("RGBA", (len(cfg) * 270, 140), (255, 0, 255, 255))
    for k, (n, (band, kinds, side)) in enumerate(cfg.items()):
        im, base = deslab(Image.open(n + ".png"), band, kinds, side)
        s.alpha_composite(im.resize((256, 256), Image.NEAREST).crop((0, 116, 256, 256)), (k * 270, 0))
    s.save(sys.argv[1])
