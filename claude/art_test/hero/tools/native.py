"""Grid-sample AI images to true pixels, remove the flat background, crop.
python -I native.py OUTSHEET.png ZOOM in1.png ...   (also writes <in>_nat.png next to each input)"""
import sys, os
sys.path.insert(0, r"C:\gamedev\solaria_wt_newart\claude\art_test\tools")
import numpy as np
from PIL import Image
import pixlib as P

def native(path, tol=34):
    im = Image.open(path).convert("RGB")
    g = P.find_grid(im)
    nat = P.grid_sample(im, g)
    a = np.asarray(nat.convert("RGBA")).copy()
    rgb = a[..., :3].astype(int)
    # background = colour of the border; flood fill from edges
    from collections import deque
    H, W = rgb.shape[:2]
    bgc = np.median(np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]]), axis=0)
    near = np.abs(rgb - bgc).sum(2) < tol
    seen = np.zeros((H, W), bool); q = deque()
    for y in range(H):
        for x in (0, W - 1):
            if near[y, x]: q.append((y, x)); seen[y, x] = True
    for x in range(W):
        for y in (0, H - 1):
            if near[y, x] and not seen[y, x]: q.append((y, x)); seen[y, x] = True
    while q:
        y, x = q.popleft()
        for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny, nx = y+dy, x+dx
            if 0 <= ny < H and 0 <= nx < W and not seen[ny, nx] and near[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    # also kill shadow: low-chroma greys darker than bg that touch removed region at the bottom
    a[seen, 3] = 0
    ys, xs = np.where(a[..., 3] > 0)
    a = a[ys.min():ys.max()+1, xs.min():xs.max()+1]
    return Image.fromarray(a)

if __name__ == "__main__":
    out, z = sys.argv[1], int(sys.argv[2])
    ims = []
    for f in sys.argv[3:]:
        n = native(f); n.save(f[:-4] + "_nat.png"); ims.append(n)
        print(f, n.size)
    W = sum(i.width * z + 16 for i in ims); H = max(i.height for i in ims) * z + 16
    sh = Image.new("RGBA", (W, H), (40, 36, 48, 255)); x = 8
    for i in ims:
        sh.alpha_composite(i.resize((i.width * z, i.height * z), Image.NEAREST), (x, 8)); x += i.width * z + 16
    sh.save(out)
