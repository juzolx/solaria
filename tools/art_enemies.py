"""Monster and boss sprites, facing left (toward the hero).
Normal monsters are 32x32, bosses 48x48.

Draw filled shapes only: the outline is added automatically (colored on the
lit top-left side, near-black on the shadow side). Shading is automatic too:
light from the top-left, shadow on the right and underneath.

Letters: each sprite's "pal" maps lowercase letters to a base color (a full
hue-shifted ramp is made from it). An UPPERCASE letter is that material in
shadow. "hi" maps extra characters to a material's highlight tone.
Shared flat colors: w white, k black, r red glow, y yellow glow, g green glow,
b blue glow, o dark line (for mouths and separations).
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixelshade as ps  # noqa: E402

FLATS = {"w": "#f4f4f4", "k": "#181425", "r": "#ff4a4a", "y": "#fee761", "g": "#7dff7a", "b": "#7fe9ff"}
RESERVED = set(FLATS) | {"o"}

ENEMIES = {}


def add(key, pal, rows, hi=None, manual=False):
    for k in pal:
        assert k not in RESERVED, (key, k)
    ENEMIES[key] = {"pal": pal, "rows": rows, "hi": hi or {}, "manual": manual}


def render(key):
    d = ENEMIES[key]
    mats = dict(FLATS)
    for k, v in d["pal"].items():
        mats[k] = ps.ramp_from(v)
    aliases = {ch: (m, 0) for ch, m in d["hi"].items()}
    return ps.shade(d["rows"], mats, outline_all=True, aliases=aliases, manual=d["manual"], mark_outline=False)


import art_monsters  # noqa: E402,F401  (the drawings)
