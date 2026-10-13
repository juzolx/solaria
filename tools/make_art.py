"""Builds every sprite PNG in art/ from the drawings in tools/art_*.py and
writes art_info.gd (pivot points, color ramps) for the game.

Run:  python3 tools/make_art.py

How the art works
-----------------
* Drawings are text grids. Each letter is a material and a tone (see each
  art_*.py file); tools/pixelshade.py turns them into shaded pixels with
  colored "selective" outlines (light from the top-left, hue-shifted ramps).
* Things the game recolors (skin, hair, eyes, gear material, rarity trim) are
  saved in KEY colors: pure red tones = skin, green = hair, yellow = gear
  material, magenta = trim, blue = eyes. Everything else is final color.
* Outline pixels added around a layer are saved with alpha 201. When layers
  are stacked, those only draw on empty space; over another layer they just
  darken it slightly. Sprites.gd does the same thing in the game.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import art_body  # noqa: E402
import art_enemies  # noqa: E402
import art_gear  # noqa: E402
import art_hair  # noqa: E402
import art_races  # noqa: E402
import art_weapons  # noqa: E402
import pixelshade as ps  # noqa: E402

OUT = os.path.join(ROOT, "art")

# HD: every sprite is drawn from the same text grids, then scaled 2x with
# Scale2x and refined (crisp 1px highlights, 1px selective outlines, smoothed
# diagonals). Coordinates below are in 1x grid units and get multiplied.
HD = 2
ps.HD = HD


def keys(r, g, b):
    """5 key tones (highlight..line) for a key hue."""
    return [(int(r * v / 255), int(g * v / 255), int(b * v / 255)) for v in (255, 240, 225, 210, 195)]


SKIN_KEYS = keys(255, 0, 0)
HAIR_KEYS = keys(0, 255, 0)
MAT_KEYS = keys(255, 255, 0)
TRIM_KEYS = keys(255, 0, 255)
EYE_KEY = (0, 0, 255)

# ---------------- color ramps used by the game ----------------
SKINS = [
    ['#fff1e6', '#fbe0cc', '#f2c9ac', '#d9a283', '#8a5444'],
    ['#fbe6cf', '#f2cfae', '#e8b796', '#c28569', '#733e39'],
    ['#f2c49a', '#e4a672', '#c98a5c', '#9c6244', '#5a3434'],
    ['#d9996a', '#b86f50', '#9a5a40', '#733e39', '#3e2731'],
    ['#a8705a', '#8a5444', '#6b3e34', '#4e2a28', '#2a1a1e'],
    ['#d6e8ff', '#a9c6ee', '#7f9fd0', '#5a72a8', '#34416e'],
    ['#d4ecaa', '#a8ca58', '#75a743', '#468232', '#25562e'],
    ['#f8b09a', '#e4705a', '#c84a44', '#8e2e38', '#4e1a26'],
    ['#d0dcc8', '#a8b89a', '#7f9478', '#566a56', '#2e3a34'],   # 8 undead grey-green
    ['#e4e0ec', '#bdb6cc', '#948ca8', '#6a6284', '#3e3a52'],   # 9 undead ash
    ['#d8dce4', '#aab2c0', '#7d8798', '#545d70', '#2e3444'],   # 10 golem stone
    ['#e8c890', '#c8a060', '#9a7040', '#6a4a28', '#3a2818'],   # 11 golem bronze
    ['#ffffff', '#eef0f4', '#d2d4de', '#a8a8ba', '#5e5a72'],   # 12 vampire pale
    ['#e8f4ff', '#c0d8ee', '#8fb0d2', '#5f7ea8', '#34466e'],   # 13 lich
]
HAIR_BASES = ['#3a2f3a', '#6b3e2a', '#9a5530', '#e0b45a', '#ece4cf', '#a9b4c6', '#c23b2e', '#3c6fd0', '#d870ac', '#3fa266',
              '#1f1b26', '#4a2c22', '#c4703a', '#f0d58c', '#8a5ad0', '#2fa8a0', '#f2f2f6', '#e8732a']
HAIRS = [['#%02x%02x%02x' % c for c in ps.ramp_from(b, 0.05, 1.0)] for b in HAIR_BASES]
EYES = ['#2f5bb8', '#2f8a48', '#6b3e2a', '#181425', '#b8263a', '#8a4fc8', '#d9961a']
MATERIALS = {
    "steel": ['#ffffff', '#c0cbdc', '#8b9bb4', '#5a6988', '#3a4466'],
    "iron": ['#c0cbdc', '#8b9bb4', '#5a6988', '#3a4466', '#262b44'],
    "leather": ['#e4a672', '#c28569', '#a8624a', '#733e39', '#3e2731'],
    "cloth": ['#7fb2e0', '#4f8fba', '#3c5e8b', '#253a5e', '#172038'],
    "linen": ['#f4e6c4', '#ead4aa', '#d0b48a', '#a3825f', '#5a3f35'],
    "wood": ['#e4a672', '#b86f50', '#8f563b', '#5d3a2c', '#3e2731'],
    "gold": ['#fff4a3', '#fee761', '#feae34', '#f77622', '#be4a2f'],
    "bone": ['#fbf3dc', '#ead4aa', '#c8b08a', '#9a8064', '#5a4a3e'],
    "crystal": ['#ffffff', '#a4dddb', '#73bed3', '#4f8fba', '#3c5e8b'],
    "dark": ['#8b9bb4', '#5a6988', '#3a4466', '#262b44', '#181425'],
    "hide": ['#d0da91', '#a8ca58', '#75a743', '#468232', '#25562e'],
    "coral": ['#ffb0b0', '#f6757a', '#e43b44', '#a22633', '#68386c'],
    "ember": ['#fee761', '#feae34', '#f77622', '#be4a2f', '#733e39'],
    "scale": ['#e8b8f0', '#c27ad8', '#9a4fc0', '#68386c', '#3e2731'],
    "sea": ['#c8f2ee', '#a4dddb', '#4fb0c6', '#2e7896', '#1d4a66'],
    "pale": ['#ffffff', '#eef2f8', '#c0cbdc', '#8b9bb4', '#5a6988'],
}
FIXED_WOOD = ['#e4a672', '#c28569', '#8f563b', '#5d3a2c', '#3e2731']
FIXED_STRAP = ['#9c5a40', '#8a4e3c', '#733e39', '#4a2a2a', '#2a1d26']


def save(im, *path):
    p = os.path.join(OUT, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)


def shade(rows, mats, aliases, w=None, h=None, pad=0):
    if pad:
        width = max(len(r) for r in rows) + pad * 2
        rows = ["." * width] * pad + ["." * pad + r.ljust(width - pad * 2, ".") + "." * pad for r in rows] + ["." * width] * pad
    return ps.shade(rows, mats, w=w, h=h, outline_all=True, aliases=aliases, manual=True)


def find(rows, ch):
    for y, r in enumerate(rows):
        x = r.find(ch)
        if x >= 0:
            return [x, y]
    return [len(rows[0]) // 2, len(rows) // 2]


def clean_pivot(rows, fill):
    return [r.replace("P", fill) for r in rows]


def face_detail(im):
    """HD face pass: a brow above the eye (in the hair key, so it takes the hair
    color) and a glint in the eye. Only at HD, where there's room for it."""
    if HD < 2:
        return im
    px = im.load()
    eye = [(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][:3] == EYE_KEY and px[x, y][3] == 255]
    if not eye:
        return im
    x0 = min(x for x, _ in eye)
    x1 = max(x for x, _ in eye)
    y0 = min(y for _, y in eye)
    # glint: the top-left pixel of the eye catches the light
    px[x0, y0] = (244, 244, 244, 255)
    # brow: two rows above the eye, a little wider than it, slanting up toward the face
    for i, x in enumerate(range(x0 - 2, x1 + 2)):
        y = y0 - 3 - (1 if i >= 3 else 0)
        if 0 <= x < im.width and 0 <= y < im.height and px[x, y][3] == 255 and px[x, y][:3] in SKIN_KEYS:
            px[x, y] = HAIR_KEYS[3] + (255,)
    return im


def main():
    info = {"weapons": {}, "offhands": {}, "helmets": {}, "enemies": {}, "races": {},
            "hd": HD, "hand": [21 * HD, 19 * HD], "off_hand": [11 * HD, 19 * HD],
            "keys": {"skin": SKIN_KEYS, "hair": HAIR_KEYS, "mat": MAT_KEYS, "trim": TRIM_KEYS, "eye": [EYE_KEY]},
            "skins": SKINS, "hairs": HAIRS, "eyes": EYES, "materials": MATERIALS,
            "hair_styles": ["Short", "Spiky", "Long", "Ponytail", "Bun", "Mohawk", "Bald"]}

    # ---- v0.11: the hero is drawn natively at 64x64 (art_hero_native.py)
    import art_hero_native as hn
    import art_native as an
    info["hd"] = HD
    info["hand"] = list(hn.HAND["masc"])
    info["hand_fem"] = list(hn.HAND["fem"])
    info["off_hand"] = list(hn.OFF_HAND["masc"])
    info["hair_styles"] = hn.HAIR_ORDER
    info["hair_back"] = []
    eye = EYE_KEY
    body_r = {"s": SKIN_KEYS, "c": hn.SHIRT, "p": hn.PANTS, "l": hn.SHOES, "k": hn.BELT, "g": ['#fff4a3', '#fee761', '#feae34', '#f77622', '#be4a2f'],
              "e": eye, "x": hn.DARK, "w": hn.WHITE, "y": "#ffffff", "q": hn.LIPS, "h": HAIR_KEYS}
    for kind in ("masc", "fem"):
        save(hn.body(kind).render(body_r, tone_fn=hn.clean_head, shadow_under=("c", "p", "l")), "hero", "body_%s.png" % kind)
    for style in hn.HAIR_ORDER:
        f, bk = hn.hair_layers(style)
        rr = {"h": HAIR_KEYS, "t": "#c23b2e"}
        empty = an.Canvas().render(rr)
        save(f.render(rr, soft=1.2) if f else empty, "hero", "hair_%s.png" % style.lower().replace(" ", "_"))
        if bk:
            save(bk.render(rr, soft=1.2), "hero", "hair_%s_back.png" % style.lower().replace(" ", "_"))
            info["hair_back"].append(style)
    # ---- race features
    for key in hn.RACE_KEYS:
        cv, rr = hn.race_layer(key)
        rr = {k: v for k, v in rr.items() if v is not None}
        rr["s"] = SKIN_KEYS
        rr["h"] = HAIR_KEYS
        save(cv.render(rr), "hero", "race_%s.png" % key)
    info["races"] = {k: {"back": v[0], "front": v[1]} for k, v in art_races.RACES.items()}
    info["race_back"] = sorted(art_races.BACK)
    info["forms"] = art_races.FORMS
    info["race_looks"] = art_races.LOOKS
    info["race_eyes"] = art_races.EYES
    # ---- armor, fitted to each build
    gear_r = {"m": MAT_KEYS, "r": TRIM_KEYS, "k": FIXED_STRAP}
    for piece in ("tunic", "plate", "robe", "pants", "greaves", "leggings", "boots", "sandals", "sabatons"):
        for kind in ("masc", "fem"):
            save(hn.armor(kind, piece).render(gear_r), "gear", "%s_%s.png" % (piece, kind))
    save(hn.cape().render(gear_r), "gear", "cape.png")
    hides = {"cap": False, "helm": True, "hood": True, "crown": False}
    for kind in ("cap", "helm", "hood", "crown"):
        save(hn.helmet(kind).render(gear_r), "gear", "%s.png" % kind)
        info["helmets"][kind] = {"hides_hair": hides[kind]}

    # ---- weapons and off-hands (P in the drawing = where the hand holds it)
    w_mats = {"m": MAT_KEYS, "r": TRIM_KEYS, "w": FIXED_WOOD, "x": FIXED_STRAP, "n": "#f4f4f4"}
    for kind in ("sword", "dagger", "axe", "mace", "spear", "bow", "staff"):
        rows = getattr(art_weapons, kind.upper())
        piv = find(rows, "P")
        im = shade(clean_pivot(rows, "w"), w_mats, art_weapons.ALIASES, pad=1)
        save(im, "gear", "%s.png" % kind)
        info["weapons"][kind] = {"pivot": [(piv[0] + 1) * HD, (piv[1] + 1) * HD], "size": [im.width, im.height]}
    for kind in ("buckler", "shield", "tower", "orb", "tome"):
        rows = getattr(art_weapons, kind.upper())
        piv = find(rows, "P")
        line = rows[piv[1]]
        fill = line[piv[0] - 1] if piv[0] > 0 and line[piv[0] - 1] not in ".P" else "m"
        im = shade(clean_pivot(rows, fill), w_mats, art_weapons.ALIASES, pad=1)
        save(im, "gear", "%s.png" % kind)
        info["offhands"][kind] = {"pivot": [(piv[0] + 1) * HD, (piv[1] + 1) * HD], "size": [im.width, im.height]}

    # ---- enemies and bosses (final colors, drawn facing left)
    for key, d in art_enemies.ENEMIES.items():
        im = art_enemies.render(key)
        save(im, "enemies", "%s.png" % key)
        bbox = im.getbbox()
        info["enemies"][key] = {"size": [im.width, im.height], "foot": (bbox[3] - 1) if bbox else im.height - 1}

    with open(os.path.join(ROOT, "art_info.gd"), "w") as f:
        f.write("class_name ArtInfo\n## Made by tools/make_art.py - sprite pivots, sizes and color ramps. Don't edit by hand.\n\n")
        f.write("const DATA := " + json.dumps(info) + "\n")
    print("art done:", sum(len(fs) for _, _, fs in os.walk(OUT)), "files")


if __name__ == "__main__":
    main()
