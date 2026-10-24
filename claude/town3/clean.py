"""Make a generated sprite's flat background transparent (flood fill from the border by the
corner colour) and trim nothing else. Usage: py clean.py <in.png> <out.png> [tolerance]"""
import sys
from collections import deque
from PIL import Image


def clean(src, dst, tol=10):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    if px[0, 0][3] == 0:          # already transparent
        im.save(dst)
        return
    bg = px[0, 0][:3]
    near = lambda c: c[3] > 0 and all(abs(c[k] - bg[k]) <= tol for k in range(3))
    seen = set()
    q = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while q:
        x, y = q.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not near(px[x, y]):
            continue
        seen.add((x, y))
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    im.save(dst)


if __name__ == "__main__":
    clean(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 10)
