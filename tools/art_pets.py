"""Companion pictures (art/pets/<class>_<stage>.png, 64x64) built from the
monster art: stage 0 is a small baby, later stages grow, shift color and glow.
Run: python3 tools/art_pets.py"""
import colorsys, os
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EN = os.path.join(ROOT, "art", "enemies")
OUT = os.path.join(ROOT, "art", "pets")
# class -> 4 stages of (monster art, hue shift (0-1), saturation mult, glow color or None)
PETS = {
    "warrior": [("rune_hound", 0, 1, None), ("garmr", 0, 1, None), ("barghest", 0, 1, "#a8a29e"), ("hellhound", 0, 1, "#f97316")],
    "knight": [("hymnbird", 0.42, 1.1, None), ("firebird", 0.1, 0.8, None), ("gilded_lion", 0, 1, "#e8b14a"), ("gilded_lion", 0, 1.2, "#fde047")],
    "wanderer": [("kitsune", 0, 1, None), ("kitsune", 0, 1, None), ("kitsune", 0.95, 1.1, "#fb923c"), ("kitsune", 0.9, 1.2, "#fde047")],
    "cleric": [("will_o_wisp", 0.6, 1, None), ("halo_wisp", 0, 1, None), ("cherub", 0, 1, "#fde68a"), ("cherub", 0, 1, "#fffbeb")],
    "acolyte": [("imp", 0.75, 1, None), ("grief_wisp", 0.25, 1, None), ("ash_fiend", 0.75, 1.3, "#a78bfa"), ("cherub", 0.72, 1, "#a78bfa")],
    "mage": [("pixie_swarm", 0.72, 1, None), ("glimmermoth", 0, 1, None), ("ifrit", 0.75, 1, "#8b5cf6"), ("ifrit", 0.6, 1.1, "#c4b5fd")],
    "trickster": [("moonhare", 0.25, 0.5, None), ("wolpertinger", 0, 1, None), ("kitsune", 0.7, 0.3, "#a8ca58"), ("kitsune", 0.75, 0.6, "#c4b5fd")],
    "ranger": [("hymnbird", 0, 1, None), ("owlwraith", 0.05, 1, None), ("firebird", 0.55, 1, "#38bdf8"), ("firebird", 0.6, 1.1, "#7dd3fc")],
    "bard": [("hymnbird", 0.85, 1, None), ("hymnbird", 0.9, 1.2, None), ("firebird", 0.95, 1, "#f472b6"), ("firebird", 0, 1.1, "#fbbf24")],
}


def shift(im, dh, sm):
    if dh == 0 and sm == 1:
        return im
    px = im.load()
    out = im.copy()
    po = out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
            h = (h + dh) % 1.0
            s = max(0.0, min(1.0, s * sm))
            r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
            po[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return out


def glow(im, color, big=False):
    c = tuple(int(color.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    a = im.split()[3].filter(ImageFilter.MaxFilter(7 if big else 5)).filter(ImageFilter.GaussianBlur(3 if big else 2))
    g = Image.new("RGBA", im.size, c + (0,))
    g.putalpha(a.point(lambda v: int(v * 0.55)))
    out = g
    out.alpha_composite(im)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    for cls, stages in PETS.items():
        for i, (src, dh, sm, gl) in enumerate(stages):
            im = Image.open(os.path.join(EN, src + ".png")).convert("RGBA")
            im = shift(im, dh, sm)
            bb = im.getbbox()
            im = im.crop(bb)
            canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
            if i == 0:  # the baby: half size
                im = im.resize((max(1, im.width // 2), max(1, im.height // 2)), Image.NEAREST)
            canvas.alpha_composite(im, ((64 - im.width) // 2, 62 - im.height))
            if gl:
                canvas = glow(canvas, gl, i == 3)
            if i == 3:  # the final form sparkles
                c = tuple(int(gl.lstrip("#")[k:k + 2], 16) for k in (0, 2, 4)) if gl else (255, 255, 255)
                px = canvas.load()
                for sx, sy in [(6, 10), (56, 8), (10, 40), (54, 34), (30, 4), (44, 52), (18, 22)]:
                    for dx, dy in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
                        v = (255, 255, 255, 255) if (dx, dy) == (0, 0) else c + (200,)
                        if px[sx + dx, sy + dy][3] < 100:
                            px[sx + dx, sy + dy] = v
            canvas.save(os.path.join(OUT, "%s_%d.png" % (cls, i)))
    print("pets", sum(len(v) for v in PETS.values()))


if __name__ == "__main__":
    main()
