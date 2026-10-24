"""Bake traced layers against an AI image into final material + shade grids.

python -I bake.py AI_native.png OUTPREFIX layer1 layer2 ... [--ramps]
 - silhouette comes from the AI image (shadow and its ragged outer dark ring removed),
 - every AI pixel gets the material/layer of the nearest traced pixel,
 - shade = AI luminance rank per material (blended with top-left light), 4 levels, orphans removed,
 - writes layers/<OUTPREFIX><layer>.txt and .shade.txt; with --ramps, writes AI-derived default ramps
   (ai_<material>) into ramps.json.
"""
import sys, os, json, colorsys
from collections import deque
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hero
H, W = hero.H, hero.W


def ai_sil(path, keep_ring=False):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(int)
    A = np.zeros((H, W, 4), int)
    h, w = min(H, a.shape[0]), min(W, a.shape[1])
    A[:h, :w] = a[:h, :w]
    rgb = A[..., :3]; al = A[..., 3] > 0
    mx = rgb.max(2); mn = rgb.min(2); lum = rgb.mean(2)
    shadow = al & (mx - mn < 22) & (lum > 70) & (lum < 140) & (np.arange(H)[:, None] > H - 14)
    al &= ~shadow
    if not keep_ring:
        edge = np.zeros_like(al)
        pad = np.pad(al, 1)
        edge = al & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
        al &= ~(edge & (lum < 70))
    return A, al, lum


def bake(ai_path, prefix, names, write_ramps=False, keep_ring=False, ai_w=0.75, fixed=()):
    A, sil, lum = ai_sil(ai_path, keep_ring)
    for f in fixed:   # pixels owned by hand-drawn layers (weapons) are not part of the AI body
        g = hero.load(f)[0] != "."
        pad = np.pad(g, 1)
        g = g | pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:]
        sil &= ~g
    lay = {n: hero.load(n)[0] for n in names}
    top_mat = np.full((H, W), ".", "<U1"); top_lay = np.full((H, W), -1, int)
    for i, n in enumerate(names):
        on = lay[n] != "."
        top_mat[on] = lay[n][on]; top_lay[on] = i
    # BFS: assign silhouette pixels with no trace to the nearest traced (visible) pixel
    src = (top_lay >= 0) & sil
    near_l = np.where(src, top_lay, -1); near_m = np.where(src, top_mat, ".")
    q = deque(zip(*np.where(src)))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and sil[ny, nx] and near_l[ny, nx] < 0:
                near_l[ny, nx] = near_l[y, x]; near_m[ny, nx] = near_m[y, x]; q.append((ny, nx))
    # new per-layer grids
    out = {n: lay[n].copy() for n in names}
    for i, n in enumerate(names):
        g = out[n]
        # visible pixels of this layer that fall outside the AI silhouette are removed
        g[(top_lay == i) & ~sil] = "."
        add = sil & (near_l == i) & (top_lay != i)
        g[add] = near_m[add]
    # composite again for shading
    comp = np.full((H, W), ".", "<U1"); comp_l = np.full((H, W), -1, int)
    for i, n in enumerate(names):
        on = out[n] != "."
        comp[on] = out[n][on]; comp_l[on] = i
    sh_vis = hero.smooth(comp, hero.auto_shade(comp, lum, ai_w), it=3)
    ramps = {}
    for i, n in enumerate(names):
        g = out[n]
        sh_all = hero.smooth(g, hero.auto_shade(g, None, 0), it=2)   # hidden parts: light only
        sh = np.where(comp_l == i, sh_vis, sh_all)
        shade_txt = np.where(g != ".", sh.astype(str), ".")
        open(os.path.join(hero.LAY, prefix + n + ".txt"), "w").write("\n".join("".join(r) for r in g) + "\n")
        open(os.path.join(hero.LAY, prefix + n + ".shade.txt"), "w").write("\n".join("".join(r) for r in shade_txt) + "\n")
    if write_ramps:
        rj = os.path.join(hero.HERE, "ramps.json")
        R = json.load(open(rj)) if os.path.exists(rj) else {}
        for m in set(comp.flatten()) - {".", "e"}:
            vis = (comp == m) & sil
            cols = []
            for s in (1, 2, 3, 4):
                px = A[vis & (sh_vis == s)][:, :3]
                cols.append(np.median(px, 0) if len(px) else None)
            # fill gaps by interpolation
            for k in range(4):
                if cols[k] is None:
                    cols[k] = next(c for c in cols if c is not None)
            c1 = np.array(cols[0], float)
            h, l, s_ = colorsys.rgb_to_hls(*(c1 / 255))
            line = np.array(colorsys.hls_to_rgb((h + 0.93) % 1.0 if h > 0.5 else max(0, h - 0.04) % 1.0, l * 0.55, min(1, s_ * 0.9))) * 255
            ramp = [line] + cols
            R["ai_" + m] = ["#%02x%02x%02x" % tuple(int(round(v)) for v in c) for c in ramp]
        json.dump(R, open(rj, "w"), indent=1)
    return out


if __name__ == "__main__":
    args = sys.argv[1:]
    wr = "--ramps" in args; args = [a for a in args if a != "--ramps"]
    kr = "--keep-ring" in args; args = [a for a in args if a != "--keep-ring"]
    fx = [a[8:] for a in args if a.startswith("--fixed=")]; args = [a for a in args if not a.startswith("--fixed=")]
    bake(args[0], args[1], args[2:], wr, kr, fixed=fx)
