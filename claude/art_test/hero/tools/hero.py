"""Solaria base hero: layered material grids -> shaded, outlined pixel sprite with runtime-style recolour.

Each layer is a text grid (layers/<name>.txt): one char per pixel = material, '.' = empty.
Optional shade grid layers/<name>.shade.txt: digit 1-4 per pixel overrides the automatic shade
('0' forces the inner-line colour).
Render = stack layers (in order), shade each material region, draw inner lines where a material
sits behind another, add a 1 px near-black outer outline, then map (ramp, shade) -> colour.
The same (material, shade) index maps are what the game would recolour at runtime.
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
LAY = os.path.join(HERE, "layers")
OUTLINE = (18, 12, 20)
H, W = 84, 60
PADL = 8          # extra canvas on the left (shield side); every layer is shifted right by PADL

# ramps: index 0 = inner line, 1..4 = shadow -> highlight (cool/purple shadows, warm highlights)
RAMPS = {
    "skin_fair":  ["#3a1e2c", "#8c5058", "#c8806c", "#eeb48e", "#fbdcb8"],
    "skin_tan":   ["#341a26", "#7a4446", "#ac6a50", "#d29468", "#ecbc8a"],
    "skin_brown": ["#28141e", "#56303a", "#82503e", "#a87050", "#c8926a"],
    "skin_deep":  ["#1c0e18", "#40222e", "#623a38", "#8a5a42", "#ae7e5c"],
    "hair_brown": ["#24121c", "#4c2a2c", "#7a4834", "#a86c44", "#d29a62"],
    "hair_black": ["#0c0a14", "#1c1a2a", "#2e2e46", "#484a66", "#6c7090"],
    "hair_blond": ["#38221e", "#7c5434", "#b4843e", "#dcb25a", "#f4da8e"],
    "hair_red":   ["#280e16", "#5c1c20", "#923224", "#c0542c", "#e08444"],
    "hair_white": ["#2c2838", "#625e72", "#9a96a6", "#c8c4cc", "#eceae6"],
    "linen":      ["#3a2836", "#7a6470", "#b4a4a0", "#e0d6c8", "#faf4e8"],
    "leather":    ["#2a1018", "#5a2226", "#8a3c2c", "#b45e38", "#d8884c"],
    "leather_dk": ["#1a0e14", "#3a1c1e", "#5c3024", "#80482e", "#a0663c"],
    "trousers":   ["#24141c", "#4a2a2c", "#6e4436", "#926244", "#b08258"],
    "boots":      ["#1e0e16", "#46201e", "#6e3426", "#98502e", "#c0743c"],
    "steel":      ["#141a2a", "#34405e", "#62708e", "#a0aac0", "#e6eaee"],
    "iron_dk":    ["#0e0e1a", "#1e2034", "#30344e", "#4a5070", "#6e7898"],
    "wood":       ["#1e1216", "#422822", "#6a4230", "#8e603e", "#b08452"],
    "eye":        ["#120c14", "#120c14", "#2a1c2a", "#e8e0d8", "#ffffff"],
    "robe_plum":  ["#1a0e1c", "#38203c", "#563258", "#764a74", "#9a6a92"],
    "robe_moss":  ["#10140e", "#26301e", "#3c4a2c", "#566a3a", "#76885a"],
    "robe_ash":   ["#18161e", "#34303a", "#524c56", "#726a72", "#968c92"],
    "r_common":   ["#1e1c26", "#4a4a56", "#7a7a86", "#a8a8b0", "#d4d4d8"],
    "r_uncommon": ["#0e2018", "#1e4a30", "#2e7a48", "#46b066", "#8ee6a0"],
    "r_rare":     ["#101830", "#22386a", "#3a64a8", "#5c94e0", "#a4ccff"],
    "r_epic":     ["#1e1030", "#42246a", "#6c3ca8", "#9c62e0", "#d4a8ff"],
    "r_legendary":["#2a1208", "#6a2e10", "#a85020", "#e47c34", "#ffc078"],
    "r_mythic":   ["#2a0810", "#6a1420", "#a82630", "#e04048", "#ff9a9a"],
    "iris_brown": ["#120c14", "#1a0e16", "#5a3024", "#8c5634", "#fff8ec"],
    "iris_green": ["#120c14", "#0e1416", "#2a4a30", "#4e7a44", "#fff8ec"],
    "iris_blue":  ["#120c14", "#0e1220", "#2c4064", "#4c6c98", "#fff8ec"],
    "iris_grey":  ["#120c14", "#141420", "#4a4a5a", "#7a7a88", "#fff8ec"],
}
DEFAULT = {"S": "skin_fair", "F": "skin_fair", "e": "eye", "H": "hair_brown", "W": "linen", "V": "leather",
           "B": "leather_dk", "T": "trousers", "K": "boots", "M": "steel", "G": "leather_dk", "E": "iris_brown", "h": "hair_brown",
           "R": "steel", "U": "leather_dk", "Q": "leather_dk", "J": "steel", "D": "wood", "C": "robe_plum"}
# depth: where two materials touch, the lower one gets the inner line
DEPTH = {"S": 0, "e": 0, "T": 1, "K": 2, "W": 2.5, "V": 3, "C": 3, "M": 3, "R": 3, "U": 3, "Q": 3, "J": 3,
         "D": 3, "G": 3, "B": 4, "H": 5, "F": 7}
NOLINE = set(".eEh")


_rj = os.path.join(HERE, "ramps.json")
if os.path.exists(_rj):
    import json as _json
    RAMPS.update(_json.load(open(_rj)))


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def _grid(path):
    rows = [r.rstrip("\n") for r in open(path)]
    g = np.full((H, W), ".", dtype="<U1")
    for y, r in enumerate(rows[:H]):
        for x, c in enumerate(r[:W]):
            g[y, x] = c
    return g


def load(name):
    g = _grid(os.path.join(LAY, name + ".txt"))
    ps = os.path.join(LAY, name + ".shade.txt")
    sh = _grid(ps) if os.path.exists(ps) else None
    return g, sh


def stack(names):
    mat = np.full((H, W), ".", dtype="<U1")
    over = np.full((H, W), -1, int)
    global LAYER_IDX
    LAYER_IDX = np.full((H, W), -1, int)
    for li, n in enumerate(names):
        g, sh = load(n)
        on = g != "."
        mat[on] = g[on]
        LAYER_IDX[on] = li
        over[on] = -1
        if sh is not None:
            dig = np.char.isdigit(sh) & on
            over[dig] = sh[dig].astype(int)
    return mat, over


def _runs(reg, ys, xs, dy, dx):
    out = np.zeros(len(ys))
    for i, (y, x) in enumerate(zip(ys, xs)):
        k = 0
        while 0 <= y + dy * (k + 1) < H and 0 <= x + dx * (k + 1) < W and reg[y + dy * (k + 1), x + dx * (k + 1)]:
            k += 1
        out[i] = k
    return out


def auto_shade(mat, ai=None, ai_w=0.55):
    """Top-left light from region shape, blended with AI luminance rank; quantised per material to 1..4."""
    sh = np.zeros((H, W), int)
    for m in set(mat.flatten()) - {"."}:
        reg = mat == m
        ys, xs = np.where(reg)
        tl = _runs(reg, ys, xs, -1, 0) + 0.6 * _runs(reg, ys, xs, 0, -1)
        br = _runs(reg, ys, xs, 1, 0) + 0.6 * _runs(reg, ys, xs, 0, 1)
        v = (br + 0.5) / (tl + br + 1.0)
        if ai is not None and ai_w > 0:
            l = ai[ys, xs]
            r = l.argsort().argsort() / max(1, len(l) - 1)
            v = (1 - ai_w) * v + ai_w * r
        sh[ys, xs] = np.digitize(v, [0.22, 0.55, 0.85]) + 1
    return sh


def smooth(mat, sh, it=2):
    """Remove orphan shade pixels (no same-shade 4-neighbour inside the same material)."""
    for _ in range(it):
        new = sh.copy()
        for y in range(H):
            for x in range(W):
                if mat[y, x] == ".":
                    continue
                nb = [sh[y + dy, x + dx] for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))
                      if 0 <= y + dy < H and 0 <= x + dx < W and mat[y + dy, x + dx] == mat[y, x]]
                if nb and sh[y, x] not in nb:
                    new[y, x] = max(sorted(set(nb)), key=nb.count)
        sh = new
    return sh


def inner_lines(mat, lay=None):
    """A pixel gets the inner-line colour when a neighbour covers it: a later layer, or within one layer
    a material with a higher DEPTH. Skin next to skin and eye/brow pixels never make lines."""
    lay = LAYER_IDX if lay is None else lay
    line = np.zeros((H, W), bool)
    for y in range(H):
        for x in range(W):
            m = mat[y, x]
            if m in NOLINE:
                continue
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < H and 0 <= nx < W:
                    n = mat[ny, nx]
                    if n in NOLINE or n == m or (m in "SF" and n in "SF"):
                        continue
                    if lay[ny, nx] > lay[y, x] or (lay[ny, nx] == lay[y, x] and DEPTH.get(n, 0) > DEPTH.get(m, 0)):
                        line[y, x] = True
    return line


def _render_one(names, ramps, ai, ai_w, outline, lines):
    """names entries: layer name, or (name, {material: ramp}) for per-layer ramps (e.g. item rarity)."""
    per = [dict(ramps, **(n[1] if isinstance(n, tuple) else {})) for n in names]
    names = [n[0] if isinstance(n, tuple) else n for n in names]
    mat, over = stack(names)
    sh = smooth(mat, auto_shade(mat, ai, ai_w))
    sh = np.where(over >= 0, over, sh)
    ln = inner_lines(mat) if lines else np.zeros((H, W), bool)
    sh = np.where(ln, 0, sh)
    img = np.zeros((H + 2, W + 2, 4), np.uint8)
    for y in range(H):
        for x in range(W):
            m = mat[y, x]
            if m == ".":
                continue
            r = RAMPS[per[LAYER_IDX[y, x]][m]]
            c = hexrgb(r[1]) if m == "e" else hexrgb(r[sh[y, x]])
            img[y + 1, x + 1] = (*c, 255)
    if outline:
        a = img[..., 3] > 0
        ring = np.zeros_like(a)
        ring[1:] |= a[:-1]; ring[:-1] |= a[1:]; ring[:, 1:] |= a[:, :-1]; ring[:, :-1] |= a[:, 1:]
        ring &= ~a
        img[ring] = (*OUTLINE, 255)
    return Image.fromarray(img), mat, sh


def render(names, ramps=None, ai=None, ai_w=0.55, outline=True, lines=True, pad=True):
    """names: layer names bottom->top. A (name, dx) tuple is an under-layer (e.g. the shield on the far
    arm) rendered on its own and placed dx px to the side, under the hero. With pad=True the canvas has
    PADL extra px on the left so such pieces fit; size is (W+2+PADL) x (H+2)."""
    ramps = dict(DEFAULT, **(ramps or {}))
    under = [n for n in names if isinstance(n, tuple) and isinstance(n[1], int)]
    main = [n for n in names if not (isinstance(n, tuple) and isinstance(n[1], int))]
    im, mat, sh = _render_one(main, ramps, ai, ai_w, outline, lines)
    if not pad:
        return im, mat, sh
    out = Image.new("RGBA", (im.width + PADL, im.height), (0, 0, 0, 0))
    for item in under:
        n, dx = item[0], item[1]
        u = _render_one([(n, item[2] if len(item) > 2 else {})], ramps, None, 0, outline, lines)[0]
        out.alpha_composite(u, (PADL + dx, 0))
    out.alpha_composite(im, (PADL, 0))
    return out, mat, sh


def zoom(im, z):
    return im.resize((im.width * z, im.height * z), Image.NEAREST)


def on_bg(im, col=(52, 48, 60, 255)):
    bg = Image.new("RGBA", im.size, col)
    bg.alpha_composite(im)
    return bg
