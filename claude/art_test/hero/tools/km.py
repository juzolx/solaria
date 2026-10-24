"""k-means label preview: python -I km.py in_nat.png K out.png -> prints cluster colours, saves zoomed label image"""
import sys, numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\gamedev\solaria_wt_newart\claude\art_test\tools")
import pixlib as P

def kmeans(X, k, it=30, seed=0):
    rs = np.random.RandomState(seed)
    C = X[rs.choice(len(X), k, replace=False)]
    for _ in range(it):
        d = ((X[:, None] - C[None]) ** 2).sum(2); L = d.argmin(1)
        for j in range(k):
            if (L == j).any(): C[j] = X[L == j].mean(0)
    return L, C

if __name__ == "__main__":
    f, k, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    a = np.asarray(Image.open(f).convert("RGBA")).astype(float)
    m = a[..., 3] > 0
    X = np.array([P.oklab(c) for c in a[m][:, :3]])
    L, C = kmeans(X, k)
    lab = -np.ones(m.shape, int); lab[m] = L
    np.save(out[:-4] + ".npy", lab)
    z = 12; H, W = m.shape
    im = Image.new("RGB", (W * z * 2 + 20, max(H * z, k * 20)), (30, 30, 30)); d = ImageDraw.Draw(im)
    for y in range(H):
        for x in range(W):
            if m[y, x]:
                c = tuple(int(v) for v in a[y, x, :3])
                d.rectangle([x*z, y*z, x*z+z-1, y*z+z-1], fill=c)
                d.text((W*z+20 + x*z+2, y*z), "%x" % lab[y, x], fill=c)
    for j in range(k):
        mc = a[m][L == j][:, :3].mean(0)
        print(j, "n=%d" % (L == j).sum(), tuple(int(v) for v in mc))
    im.save(out)
