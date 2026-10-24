"""How people move in town: a walk grid built from the layout (streets, square, bridge, plateau
path, the cell in front of every door) and shortest paths along it. The same grid goes into
town.json for town_view.gd. Usage: py walk.py <out_dir>  -> walk_grid.png, walk_demo.gif"""
import sys
from collections import deque
from PIL import Image, ImageDraw
from layout import N, GROUND, LOTS, HOUSES, MARKET, PLATEAU, PLATEAU_Z, POINTS
from compose import at, dusk, compose, phone

WALK = {"road", "square", "bridge", "plateau", "path", "dirt"}


def grid():
    g = [["grass"] * N for _ in range(N)]
    for k, x0, y0, x1, y1 in GROUND:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                g[i][j] = k
    ok = {(i, j) for i in range(N) for j in range(N) if g[i][j] in WALK}
    px0, py0, px1, py1 = PLATEAU          # plateau: only the cobbled path from the stairs up to the door
    ok -= {(i, j) for i in range(px0, px1 + 1) for j in range(py0, py1 + 1)}
    ok |= {(i, j) for i in range(18, 22) for j in range(5, 8)}
    for lid, _, x0, y0, x1, y1, door, _ in LOTS:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                ok.discard((i, j))
    ok -= {(20, 20), (21, 20), (20, 21), (21, 21)}      # the well
    return ok


def doors():
    d = {}
    for lid, _, x0, y0, x1, y1, side, _ in LOTS:
        d[lid] = ((x1 + 1, (y0 + y1) // 2) if side == "i" else ((x0 + x1) // 2, y1 + 1))
    d["gate"] = (19, 7)
    d["market"] = (17, 20)
    d["bounty"] = (22, 9)
    d["mail"] = (12, 15)
    return d


def path(ok, a, b):
    prev, q = {a: None}, deque([a])
    while q:
        c = q.popleft()
        if c == b:
            break
        for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (c[0] + di, c[1] + dj)
            if (n in ok or n == b) and n not in prev:
                prev[n] = c
                q.append(n)
    if b not in prev:
        return []
    p, c = [], b
    while c:
        p.append(c)
        c = prev[c]
    return p[::-1]


def main(out):
    ok, d = grid(), doors()
    for lid, cell in d.items():
        ok.add(cell)
    town = dusk(compose())
    # grid overlay
    ov = town.copy()
    dr = ImageDraw.Draw(ov, "RGBA")
    for i, j in ok:
        z = PLATEAU_Z if (i, j) in {(a, b) for a in range(18, 22) for b in range(5, 8)} else 0
        pts = [at(i, j, z), at(i + 1, j, z), at(i + 1, j + 1, z), at(i, j + 1, z)]
        dr.polygon(pts, fill=(90, 200, 255, 60), outline=(90, 200, 255, 120))
    for lid, (i, j) in d.items():
        x, y = at(i + .5, j + .5)
        dr.ellipse([x - 4, y - 3, x + 4, y + 3], fill=(255, 210, 80, 255))
    ov.crop((40, 140, 1320, 900)).save(f"{out}/walk_grid.png")
    # demo: three walkers on door-to-door trips, shown in the phone view around the square
    folk = {n: Image.open(f"art/folk/{n}.png").convert("RGBA") for n in ("hero", "villager")}
    trips = [("hero", ["inn", "market", "smith", "gate"]), ("villager", ["shop", "market", "tavern"]),
             ("hero", ["guild", "bounty", "gate"]), ("villager", ["clinic", "market", "mail"])]
    routes = []
    for who, stops in trips:
        r = []
        for a, b in zip(stops, stops[1:]):
            seg = path(ok, d[a], d[b])
            r += seg if not r else seg[1:]
        routes.append((who, r))
    frames, cx, cy = [], *at(20, 17)
    steps = 4                      # sub-steps per cell
    total = max(len(r) for _, r in routes) * steps
    for f in range(0, total, 2):
        fr = town.copy()
        for who, r in routes:
            k = min(f / steps, len(r) - 1.001)
            a, b = r[int(k)], r[min(int(k) + 1, len(r) - 1)]
            t = k - int(k)
            i, j = a[0] + (b[0] - a[0]) * t + .5, a[1] + (b[1] - a[1]) * t + .5
            z = PLATEAU_Z if 5 <= j - .5 < 8 and 18 <= i - .5 < 22 else 0
            x, y = at(i, j, z)
            im = folk[who]
            if (b[0] - a[0]) + (a[1] - b[1]) < 0:   # heading left on screen
                im = im.transpose(Image.FLIP_LEFT_RIGHT)
            bob = (f // 2) % 2
            bb = im.getbbox()
            fr.paste(im, (int(x - (bb[0] + bb[2]) // 2), int(y - bb[3] + 2 - bob)), im)
        frames.append(phone(fr, cx, cy).convert("P", palette=Image.ADAPTIVE, colors=255))
    frames[0].save(f"{out}/walk_demo.gif", save_all=True, append_images=frames[1:], duration=90, loop=0)
    print("frames", len(frames), "walk cells", len(ok))


if __name__ == "__main__":
    main(sys.argv[1])
