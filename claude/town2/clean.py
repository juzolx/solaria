"""Flood-fills the plain background PixelLab left around a sprite (from the border, by
colour distance to the border colour) to transparency. Usage: py clean.py <in> <out> [tol]"""
import sys
from collections import deque
from PIL import Image


def clean(im, tol=26):
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    border = [px[x, 0] for x in range(w)] + [px[x, h - 1] for x in range(w)]
    bg = max(set(border), key=border.count)
    near = lambda c: sum(abs(c[i] - bg[i]) for i in range(3)) <= tol
    seen = [[False] * w for _ in range(h)]
    q = deque((x, y) for x in range(w) for y in (0, h - 1))
    q.extend((x, y) for y in range(h) for x in (0, w - 1))
    while q:
        x, y = q.popleft()
        if seen[y][x]:
            continue
        seen[y][x] = True
        c = px[x, y]
        if c[3] == 0 or near(c):
            px[x, y] = (0, 0, 0, 0)
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                    q.append((nx, ny))
    return im


if __name__ == "__main__":
    clean(Image.open(sys.argv[1]), int(sys.argv[3]) if len(sys.argv) > 3 else 26).save(sys.argv[2])
