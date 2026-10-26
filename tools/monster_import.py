"""Imports a finished monster picture (PixelLab, picked by Juzo) as game art.

    py tools/monster_import.py <key> <source.png> [<key> <source.png> ...]
    py tools/monster_import.py --all     (rebuild every pick listed in tools/monsters_native/picks.txt)

For each monster: crops to the drawing, makes alpha hard, keeps its own colours (no
palette snap: it greyed the accents), turns near-black pixels into the outline
colour, closes the outline on every edge, lifts the mid-tones of a dark monster so it
reads against the dark halls on a phone (Juzo: no dark-on-dark), pads 1 px, then writes art/enemies/<key>.png
and tools/monsters_native/<key>.png (the source make_art.py copies instead of drawing)
and updates the key's art_info.gd entry. Native art is 1 file pixel = 1 art pixel
("hd": 1), shown at the same integer scale as the hero.
"""
import json
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTLINE = (14, 8, 18)
DARK = 0.16  # OKLab lightness below this (near-black) becomes the outline colour
MIN_L = 0.42  # a monster's average OKLab lightness (outline excluded) is lifted to at least this
# Monsters that still blend into their own zone's hall at MIN_L get a stronger lift
LIFT = {"mare": 0.52, "wendigo": 0.5, "calamity_2": 0.5}
# ...and the whole picture (outline included) must average at least this luma (0-255): fable r1
# found 20 near-black monsters (47-54) vanishing into halls that average 38-94
MIN_Y = 60.0
MAX_COLORS = 24  # ArtStyle.NATIVE_COLORS
PICKS = os.path.join(ROOT, "tools", "monsters_native", "picks.txt")


def _lin(x):
    x /= 255.0
    return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4


def oklab(c):
    r, g, b = _lin(c[0]), _lin(c[1]), _lin(c[2])
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def convert(src, key=""):
    im = Image.open(src).convert("RGBA")
    im = im.crop(im.getbbox())
    out = Image.new("RGBA", (im.width + 2, im.height + 2))
    sp, op = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = sp[x, y]
            if a < 128:
                continue
            # Colours stay as Juzo approved them (snapping to the 74-colour palette turned
            # teal eyes grey and moss brown); only near-black becomes the outline colour
            c = OUTLINE if oklab((r, g, b))[0] < DARK else (r, g, b)
            op[x + 1, y + 1] = c + (255,)
    # Close the outline: a clear pixel next to a coloured (non-outline) pixel becomes outline
    w, h = out.size
    add = []
    for y in range(h):
        for x in range(w):
            if op[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and op[nx, ny][3] and op[nx, ny][:3] != OUTLINE:
                    add.append((x, y))
                    break
    for x, y in add:
        op[x, y] = OUTLINE + (255,)
    lift(out, LIFT.get(key, MIN_L))
    reduce(out)
    # Grown at the border? pad again so the outline never touches the canvas edge
    bb = out.getbbox()
    out = out.crop(bb)
    final = Image.new("RGBA", (out.width + 2, out.height + 2))
    final.paste(out, (1, 1))
    return final


def lift(im, target=MIN_L):
    """Brightens a dark monster (a gamma on its colours, darkest tones lifted most) until its
    average lightness reaches target (MIN_L unless LIFT says more) and its luma MIN_Y. Same number of colours;
    outline and glow stay put."""
    px = im.load()
    body = [px[x, y][:3] for y in range(im.height) for x in range(im.width)
            if px[x, y][3] and px[x, y][:3] != OUTLINE]
    if not body:
        return

    n_all = sum(1 for y in range(im.height) for x in range(im.width) if px[x, y][3])
    y_line = (n_all - len(body)) * (0.299 * OUTLINE[0] + 0.587 * OUTLINE[1] + 0.114 * OUTLINE[2])

    def ok(g):
        cs = [tuple(int(255 * (v / 255) ** g) for v in c) for c in body]
        luma = (y_line + sum(0.299 * r + 0.587 * gr + 0.114 * b for r, gr, b in cs)) / n_all
        return sum(oklab(c)[0] for c in cs) / len(cs) >= target and luma >= MIN_Y

    if ok(1.0):
        return
    good, bad = 0.4, 1.0  # gamma 0.4 is the strongest lift allowed; 1.0 is too dark
    for _ in range(14):
        mid = (good + bad) / 2
        if ok(mid):
            good = mid
        else:
            bad = mid
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) != OUTLINE:
                px[x, y] = tuple(int(255 * (v / 255) ** good) for v in (r, g, b)) + (255,)


def reduce(im, n=MAX_COLORS - 1):
    """Fewer colours for a busy picture (pixen edits come back with 30-70): the body is
    quantized to n colours (median cut, no dithering); the outline colour stays exact."""
    px = im.load()
    body = {px[x, y][:3] for y in range(im.height) for x in range(im.width)
            if px[x, y][3] and px[x, y][:3] != OUTLINE}
    if len(body) <= n:
        return
    flat = Image.new("RGB", im.size, OUTLINE)
    fp = flat.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3]:
                fp[x, y] = px[x, y][:3]
    q = flat.quantize(n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB").load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] and px[x, y][:3] != OUTLINE:
                c = q[x, y]
                px[x, y] = (c if c != OUTLINE else tuple(min(255, v + 6) for v in c)) + (255,)


def update_info(entries):
    path = os.path.join(ROOT, "art_info.gd")
    text = open(path, encoding="utf-8").read()
    m = re.search(r"const DATA := (.*)\n", text)
    data = json.loads(m.group(1))
    for key, im in entries:
        bb = im.getbbox()
        data["enemies"][key] = {"size": [im.width, im.height], "foot": bb[3] - 1, "hd": 1}
    text = text[:m.start(1)] + json.dumps(data) + text[m.end(1):]
    open(path, "w", encoding="utf-8", newline="\n").write(text)


def read_picks():
    picks = {}
    if os.path.exists(PICKS):
        for line in open(PICKS, encoding="utf-8"):
            if line.strip() and not line.startswith("#"):
                k, s = line.split(None, 1)
                picks[k] = s.strip()
    return picks


def main(args):
    done = []
    os.makedirs(os.path.join(ROOT, "tools", "monsters_native"), exist_ok=True)
    picks = read_picks()
    if args == ["--all"]:
        args = [v for k, s in picks.items() for v in (k, os.path.join(ROOT, s))]
    for key, src in zip(args[0::2], args[1::2]):
        rel = os.path.relpath(os.path.abspath(src), ROOT).replace(os.sep, "/")
        if rel.startswith(".."):
            raise SystemExit("%s: copy the source into claude/art_test/monsters/raw first" % src)
        picks[key] = rel
        im = convert(src, key)
        im.save(os.path.join(ROOT, "art", "enemies", key + ".png"))
        im.save(os.path.join(ROOT, "tools", "monsters_native", key + ".png"))
        done.append((key, im))
        print(key, im.size)
    update_info(done)
    with open(PICKS, "w", encoding="utf-8", newline="\n") as f:
        f.write("# art key -> the picked PixelLab picture (Juzo's ratings: claude/research/art-ratings.md)\n")
        for k in sorted(picks):
            f.write("%s %s\n" % (k, picks[k]))


if __name__ == "__main__":
    main(sys.argv[1:])
