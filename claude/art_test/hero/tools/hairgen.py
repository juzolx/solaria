"""Radial-clump shading for back-view hair: clumps fan out from the crown (whorl), lit from the top-left.
Used as a starting point; the result is then touched up by hand in draw_v2.py."""
import math


def shade_hair(sil, cx, cy, n_clumps=9, offset=0.0, light=(0.0, 0.0), seed_rows=()):
    """sil: dict y -> list of (x0, x1). Returns rows [(y, x0, digits)]."""
    ys = sorted(sil)
    allx = [x for y in ys for a, b in sil[y] for x in (a, b)]
    xmin, xmax = min(allx), max(allx)
    ymin, ymax = ys[0], ys[-1]
    inside = {(y, x) for y in ys for a, b in sil[y] for x in range(a, b + 1)}
    rows = []
    for y in ys:
        for a, b in sil[y]:
            t = ""
            for x in range(a, b + 1):
                dx, dy = x - cx, y - cy
                ang = math.atan2(dx, dy + 2.5)
                f = (ang / (2 * math.pi) * n_clumps * 2 + offset) % 1.0
                m = math.sin(f * math.pi)
                L = 0.55 - 0.45 * (x - (xmin + xmax) / 2) / (xmax - xmin) - 0.55 * (y - ymin) / (ymax - ymin)
                v = L + 0.30 * m + (0.10 if f < 0.45 else -0.08)
                # rim: pixels on the silhouette edge (except the lit top-left) go darker
                edge = any((y + ey, x + ex) not in inside for ey, ex in ((1, 0), (0, 1), (0, -1), (-1, 0)))
                if edge and (x > (xmin + xmax) / 2 or y > (ymin + ymax) / 2):
                    v -= 0.18
                s = 1 if v < 0.18 else 2 if v < 0.42 else 3 if v < 0.68 else 4
                t += str(s)
            rows.append((y, a, t))
    return rows
