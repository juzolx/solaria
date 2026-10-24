"""Export the iso town for the game: one base picture per Church/Trophy Cabin state (no walkers,
no level props: town_view draws those), the level-prop sprites, and art/town/town.json with
spots (tap areas), walk grid, lights, pen, graveyard, ground/walls for the town map.
Usage: py export_town.py <repo_root>"""
import hashlib
import json
import os
import sys
from PIL import Image
import compose as C
import decor as D
from layout import N, GROUND, LOTS, HOUSES, MARKET, POINTS, PLATEAU, PLATEAU_Z, TOWERS, GATEHOUSE
from walk import grid, doors

STATES = [("lot", "lot"), ("holy", "lot"), ("lot", "built"), ("holy", "built"), ("ruin", "lot"), ("ruin", "built")]


def render(church, cabin):
    D.LEVEL, D.HARDCORE = 3, church == "ruin"
    C.HARDCORE.clear()
    if church == "ruin":
        C.HARDCORE.append(True)
    C.EMPTY.clear()
    if church == "lot":
        C.EMPTY.add("church")
    if cabin == "lot":
        C.EMPTY.add("cabin")
    C.NO_OVERLAYS[:] = [True]
    D.LIGHTS.clear()
    return C.compose().convert("RGB")


def occluder_list(art, sprites):
    """Everything tall enough to hide a walker (buildings, towers, wall runs, trees, stalls,
    lamps): [texture, x, y, sort_y, tag]. town_view redraws the ones in front of a walker
    over it, so nobody walks across a roof. Textures are shared by content hash."""
    os.makedirs(os.path.join(art, "iso", "occ"), exist_ok=True)
    out = []
    for key, x, y, im, tag in sprites:
        if tag in ("plateau", "bridge") or im.height < 28:
            continue
        b = im.getbbox()
        if b is None or b[3] - b[1] < 26:
            continue
        crop = im.crop(b)
        name = hashlib.md5(crop.tobytes()).hexdigest()[:10]
        path = os.path.join(art, "iso", "occ", name + ".png")
        if not os.path.exists(path):
            crop.save(path)
        out.append([name, x + b[0], y + b[1], round(key), tag])
    return out


def px_cell(i, j, z=0):
    return list(C.at(i, j, z))


def main(root):
    art = os.path.join(root, "art", "town")
    os.makedirs(os.path.join(art, "iso"), exist_ok=True)
    boxes = {}
    for church, cabin in STATES:
        C.BOXES.clear()
        img = render(church, cabin)
        assert img.width <= 2048 and img.height <= 2048
        img.save(os.path.join(art, "iso", f"town_{church}_{cabin}.png"), optimize=True)
        boxes.update({k: v for k, v in C.BOXES.items() if isinstance(k, str)})
        if church == "holy" and cabin == "built":
            lights = [[round(C.at(i, j, z)[0]), round(C.at(i, j, z)[1]), list(col), r] for i, j, z, col, r in D.LIGHTS]
            prop_boxes = {k: v for k, v in C.BOXES.items() if not isinstance(k, str)}
            occluders = occluder_list(art, C.LAST_SPRITES)
            deco = D.decor()
        if church == "ruin" and cabin == "built":     # both Church looks; town_view picks by mode
            ruin = [o + ["ruin"] for o in occluder_list(art, C.LAST_SPRITES) if o[4] == "church"]
            occluders = [o + ["holy"] if o[4] == "church" else o for o in occluders] + ruin
    spots = []
    pages = {"gate": None}
    for lid, label, x0, y0, x1, y1, door, _ in LOTS:
        label = label.replace(" (lot)", "")
        spots.append({"id": lid, "label": "Into the Dungeon" if lid == "gate" else label,
                      "kind": "lot" if lid in ("church", "cabin") else "building",
                      "cells": [x0, y0, x1, y1], "door": list(doors()[lid]), "rect": list(boxes[lid])})
    mid, mlabel, mx0, my0, mx1, my1 = MARKET
    xs = [C.at(mx0, my1 + 1)[0], C.at(mx1 + 1, my0)[0]]
    ys = [C.at(mx0, my0)[1], C.at(mx1 + 1, my1 + 1)[1]]
    spots.append({"id": "market", "label": mlabel, "kind": "market", "cells": [mx0, my0, mx1, my1],
                  "door": list(doors()["market"]), "rect": [min(xs), min(ys) - 20, max(xs) - min(xs), max(ys) - min(ys) + 20]})
    point_prop = {"bounty": ("props48", 6), "mail": ("props48", 8)}
    for pid, label, i, j in POINTS:
        if pid not in point_prop:
            continue
        b = prop_boxes[(*point_prop[pid], i, j)]
        spots.append({"id": pid, "label": label, "kind": "point", "cells": [i, j, i, j],
                      "door": list(doors()[pid]), "rect": [b[0] - 6, b[1] - 6, b[2] + 12, b[3] + 12]})
    # level props: [file, x, y, level_from, level_to] per building, drawn by town_view over the base
    os.makedirs(os.path.join(art, "iso", "up"), exist_ok=True)
    levels = {}
    for lvl in (1, 2, 3):
        D.LEVEL = lvl
        D.LIGHTS.clear()
        own = []
        for e, owner in zip(D.level_props(own), own):
            _, n, i, j = e
            im = Image.open(os.path.join(C.ROOT, "art", "props_up", f"p{n}.png")).convert("RGBA")
            im.save(os.path.join(art, "iso", "up", f"up{n}.png"))
            b = im.getbbox()
            x, y = C.at(i + .5, j + .5)
            pos = [round(x - (b[0] + b[2]) // 2), round(y + 3 - (b[3] - 1))]
            levels.setdefault(owner, []).append([f"up{n}", pos[0], pos[1], lvl])
    ok = grid()
    # props standing on the street are not walked through; their neighbours become stops
    big = {("props48", n) for n in range(16)} | {("props_up", n) for n in range(16)} | {("props32", 12)}
    stuff = {(e[2], e[3]) for e in deco if e[0] != "fence" and (e[0], e[1]) in big}
    ok -= stuff
    for lid, cell in doors().items():
        ok.add(cell)
    stop_props = {("props48", n) for n in (0, 1, 2, 3, 4, 5, 6, 8)}
    stops = set()
    for e in deco:
        if e[0] != "fence" and (e[0], e[1]) in stop_props:
            for di, dj in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                c = (e[2] + di, e[3] + dj)
                if c in ok:
                    stops.add(c)
    stops |= {c for c in ok if 19 <= c[0] <= 22 and 19 <= c[1] <= 22}      # round the well
    pen = C.at(30, 30), C.at(38, 35)
    data = {
        "iso": True, "size": [C.W, C.H], "cell": [32, 16], "origin": [C.OX, C.OY], "grid": N,
        "art": "res://art/town/iso/town_%s_%s.png",
        "spots": spots,
        "lights": lights,
        "walk": sorted([list(c) for c in ok]),
        "stops": sorted([list(c) for c in stops]),
        "raised": [[i, j] for i in range(18, 22) for j in range(5, 8)],   # plateau path: walkers stand 24 px higher
        "raised_z": PLATEAU_Z,
        "occluders": occluders,
        "levels": levels,
        "pen": [C.at(28, 35)[0], C.at(28, 29)[1], C.at(32, 29)[0] - C.at(28, 35)[0], C.at(32, 35)[1] - C.at(28, 29)[1]],
        "pen_cells": [28, 30, 31, 34],
        "graves": [px_cell(i + .5, j + .5) for i in range(2, 12) for j in range(2, 7) if (i, j) != (6, 4)],
        "smoke": [round(boxes["smith"][0] + boxes["smith"][2] * 0.62), round(boxes["smith"][1] + 8)],
        "ground": [[k, x0, y0, x1, y1] for k, x0, y0, x1, y1 in GROUND],
        "walls": {"towers": [[x, y, x + 2, y + 2] for x, y in TOWERS], "gatehouse": list(GATEHOUSE), "ring": [0, 0, N - 1, N - 1]},
        # map-only pins with no page to open (town_view doesn't make them tappable)
        "landmarks": [{"id": pid, "label": label, "cells": [i, j, i, j]} for pid, label, i, j in POINTS if pid not in point_prop],
        "houses": [list(h[:4]) for h in HOUSES], "plateau": list(PLATEAU), "plateau_z": PLATEAU_Z,
    }
    with open(os.path.join(art, "town.json"), "w", newline="\n") as f:
        json.dump(data, f, indent=1)
    print("spots", len(spots), "walk", len(ok), "lights", len(lights))


if __name__ == "__main__":
    main(sys.argv[1])
