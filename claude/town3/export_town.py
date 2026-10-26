"""Export the iso town for the game: one base picture per Church/Trophy Cabin state (no walkers,
no level props: town_view draws those), the level-prop sprites, and art/town/town.json with
spots (tap areas), walk grid, lights, pen, graveyard, ground/walls for the town map.
Usage: py export_town.py <repo_root>"""
import hashlib
import json
import os
import sys
from PIL import Image, ImageChops
import compose as C
import decor as D
from layout import N, GROUND, LOTS, HOUSES, MARKET, POINTS, PLATEAU, PLATEAU_Z, TOWERS, GATEHOUSE, RAISED
from walk import grid, doors

STATES = [("lot", "lot"), ("holy", "lot"), ("lot", "built"), ("holy", "built"), ("ruin", "lot"), ("ruin", "built")]


def render(church, cabin, lit=True):
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
    C.LIT[:] = [lit]
    D.LIGHTS.clear()
    return C.compose().convert("RGB")


def occluder_list(art, sprites, lit_sprites):
    """Everything tall enough to hide a walker (buildings, towers, wall runs, trees, stalls,
    lamps): [texture, x, y, sort_y, tag, look, lit texture]. town_view redraws the ones in front
    of a walker over it, so nobody walks across a roof. `sprites` are the day picture's, and a
    sprite whose windows or flame light up at dusk also gets its lit texture (else "").
    Textures are shared by content hash."""
    os.makedirs(os.path.join(art, "iso", "occ"), exist_ok=True)
    out = []
    def save(im):
        name = hashlib.md5(im.tobytes()).hexdigest()[:10]
        path = os.path.join(art, "iso", "occ", name + ".png")
        if not os.path.exists(path):
            im.save(path)
        return name
    for (key, x, y, im, tag), lit in zip(sprites, lit_sprites):
        if tag in ("plateau", "bridge", "outside") or im.height < 28:
            continue
        b = im.getbbox()
        if b is None or b[3] - b[1] < 26:
            continue
        crop = im.crop(b)
        name = save(crop)
        lcrop = lit[3].crop(b)
        out.append([name, x + b[0], y + b[1], round(key), tag, "", save(lcrop) if lcrop.tobytes() != crop.tobytes() else ""])
    return out


def cut(r, q):
    """Rect r ([x, y, w, h]) minus its cheapest edge so it no longer overlaps q."""
    cuts = []
    if q[1] > r[1]:
        cuts.append((r[2] * (r[1] + r[3] - q[1]), [r[0], r[1], r[2], q[1] - r[1]]))
    if q[0] > r[0]:
        cuts.append((r[3] * (r[0] + r[2] - q[0]), [r[0], r[1], q[0] - r[0], r[3]]))
    if q[0] + q[2] < r[0] + r[2]:
        cuts.append((r[3] * (q[0] + q[2] - r[0]), [q[0] + q[2], r[1], r[0] + r[2] - q[0] - q[2], r[3]]))
    if q[1] + q[3] < r[1] + r[3]:
        cuts.append((r[2] * (q[1] + q[3] - r[1]), [r[0], q[1] + q[3], r[2], r[1] + r[3] - q[1] - q[3]]))
    return min(cuts)[1] if cuts else r


def trim_taps(spots):
    """Buildings' tap areas never overlap: where two do, the one drawn in front keeps the overlap and
    the one behind gives up its cheapest edge. (The Market is the square under everything.)"""
    def front(sp):
        x0, y0, x1, y1 = sp["cells"]
        return C.at(x1 + 1, y1 + 1)[1]
    taps = sorted([sp for sp in spots if sp["kind"] in ("building", "lot")], key=front)
    for k, b in enumerate(taps):              # b behind every later (front) one
        for f in taps[k + 1:]:
            r, q = b["rect"], f["rect"]
            ox = min(r[0] + r[2], q[0] + q[2]) - max(r[0], q[0])
            oy = min(r[1] + r[3], q[1] + q[3]) - max(r[1], q[1])
            if ox <= 0 or oy <= 0:
                continue
            b["rect"] = cut(r, q)
    # a point (Bounty Board, Mailbox) stands in front of everything: buildings give up their
    # cheapest edge to it too, so a tap on the board or the box is never ambiguous
    for p in [sp for sp in spots if sp["kind"] == "point"]:
        for b in taps:
            r, q = b["rect"], p["rect"]
            if min(r[0] + r[2], q[0] + q[2]) <= max(r[0], q[0]) or min(r[1] + r[3], q[1] + q[3]) <= max(r[1], q[1]):
                continue
            b["rect"] = cut(r, q)


def px_cell(i, j, z=0):
    return list(C.at(i, j, z))


def main(root):
    art = os.path.join(root, "art", "town")
    os.makedirs(os.path.join(art, "iso"), exist_ok=True)
    boxes = {}
    lit_pos = {}
    for church, cabin in STATES:
        C.BOXES.clear()
        img = render(church, cabin, lit=False)          # the base picture is the day: glass, torches out
        day_sprites = list(C.LAST_SPRITES)
        C.BOXES.clear()
        lit = render(church, cabin, lit=True)           # dusk: what lights up goes in an overlay
        assert img.width <= 2048 and img.height <= 2048
        img.save(os.path.join(art, "iso", f"town_{church}_{cabin}.png"), optimize=True)
        on = ImageChops.difference(img, lit).convert("L").point(lambda v: 255 if v else 0)
        over = Image.composite(lit.convert("RGBA"), Image.new("RGBA", lit.size, (0, 0, 0, 0)), on)   # clear pixels stay empty (a small file)
        over.crop(on.getbbox()).save(os.path.join(art, "iso", f"town_{church}_{cabin}_lit.png"), optimize=True)
        lit_at = list(on.getbbox()[:2])
        boxes.update({k: v for k, v in C.BOXES.items() if isinstance(k, str)})
        if church == "holy" and cabin == "built":
            lights = [[round(C.at(i, j, z)[0]), round(C.at(i, j, z)[1]), list(col), r] for i, j, z, col, r in D.LIGHTS]
            prop_boxes = {k: v for k, v in C.BOXES.items() if not isinstance(k, str)}
            occluders = occluder_list(art, day_sprites, C.LAST_SPRITES)
            deco = D.decor()
        if church == "ruin" and cabin == "built":     # both Church looks; town_view picks by mode
            ruin = [o[:5] + ["ruin"] + o[6:] for o in occluder_list(art, day_sprites, C.LAST_SPRITES) if o[4] == "church"]
            occluders = [o[:5] + ["holy"] + o[6:] if o[4] == "church" else o for o in occluders] + ruin
        lit_pos[f"{church}_{cabin}"] = lit_at
    spots = []
    pages = {"gate": None}
    for lid, label, x0, y0, x1, y1, door, _ in LOTS:
        label = label.replace(" (lot)", "")
        spots.append({"id": lid, "label": "Into the Dungeon" if lid == "gate" else label,
                      "kind": "lot" if lid in ("church", "cabin") else "building",
                      "cells": [x0, y0, x1, y1], "door": list(doors()[lid]), "rect": list(boxes[lid])})
    # the Inn's lodging wing is part of the Inn (everyone lives there): one tap area over both
    inn = next(sp for sp in spots if sp["id"] == "inn")
    if "house0" in boxes:
        a, b = inn["rect"], boxes["house0"]
        x0, y0 = min(a[0], b[0]), min(a[1], b[1])
        inn["rect"] = [x0, y0, max(a[0] + a[2], b[0] + b[2]) - x0, max(a[1] + a[3], b[1] + b[3]) - y0]
    from layout import door_cell
    from layout import INN_WING_DOOR
    inn_doors = [inn["door"], list(INN_WING_DOOR)]
    mid, mlabel, mx0, my0, mx1, my1 = MARKET
    xs = [C.at(mx0, my1 + 1)[0], C.at(mx1 + 1, my0)[0]]
    ys = [C.at(mx0, my0)[1], C.at(mx1 + 1, my1 + 1)[1]]
    spots.append({"id": "market", "label": mlabel, "kind": "market", "cells": [mx0, my0, mx1, my1],
                  "door": list(doors()["market"]), "rect": [min(xs), min(ys) - 20, max(xs) - min(xs), max(ys) - min(ys) + 20]})
    # name plates that don't sit at the top of their tap area: the Market's by the well (not on the
    # Inn's doorstep), the Dungeon's above the portal, the Bounty Board's over the board; the
    # Mailbox gets none (its badge is on the Mail button)
    spots[-1]["plate"] = None   # no plate: the whole square is its tap, and a plate there sits on the stall-goers
    for sid, xy in (("stash", (851, 690)), ("clinic", (628, 652))):   # plates on the roofs, clear of the stall-goers' heads
        next(sp for sp in spots if sp["id"] == sid)["plate"] = list(xy)
    gate = next(sp for sp in spots if sp["id"] == "gate")
    gate["plate"] = [gate["rect"][0] + gate["rect"][2] // 2, gate["rect"][1] - 6]
    point_prop = {"bounty": ("props48", 6), "mail": ("props48", 8)}
    for pid, label, i, j in POINTS:
        if pid not in point_prop:
            continue
        b = prop_boxes[(*point_prop[pid], i, j)]
        spots.append({"id": pid, "label": label, "kind": "point", "cells": [i, j, i, j],
                      "door": list(doors()[pid]), "rect": [b[0] - 6, b[1] - 6, b[2] + 12, b[3] + 12]})
        spots[-1]["plate"] = [b[0] + b[2] // 2, b[1] - 14] if pid == "bounty" else None
    trim_taps(spots)
    for sp in spots:                          # an unbuilt lot's plate sits on its ground, not in the air
        if sp["kind"] == "lot":
            x0, y0, x1, y1 = sp["cells"]
            gx, gy = C.at((x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2)
            sp["lot_plate"] = [round(gx), round(gy - 10)]
    # level props: [file, x, y, level_from, level_to] per building, drawn by town_view over the base
    os.makedirs(os.path.join(art, "iso", "up"), exist_ok=True)
    levels = {}
    for lvl in (1, 2, 3):
        D.LEVEL = lvl
        D.LIGHTS.clear()
        own = []
        for e, owner in zip(D.level_props(own), own):
            _, n, i, j = e[:4]
            im = Image.open(os.path.join(C.ROOT, "art", "props_up", f"p{n}.png")).convert("RGBA")
            im.save(os.path.join(art, "iso", "up", f"up{n}.png"))
            b = im.getbbox()
            x, y = C.at(i + .5, j + .5)
            pos = [round(x - (b[0] + b[2]) // 2), round(y + 3 - (b[3] - 1))]
            levels.setdefault(owner, []).append([f"up{n}", pos[0], pos[1], lvl, i, j])   # + the street cell it stands on
    ok = grid()
    # props standing on the street are not walked through; their neighbours become stops
    big = {("props48", n) for n in range(16)} | {("props_up", n) for n in range(16)} | {("props32", 12)}
    stuff = {(e[2], e[3]) for e in deco if e[0] != "fence" and (e[0], e[1]) in big}
    ok -= stuff
    for lid, cell in doors().items():
        ok.add(cell)
    # keep one connected street network: any door cut off by props gets the shortest way back through them
    from collections import deque
    def component(start, cells):
        seen, q = {start}, deque([start])
        while q:
            c = q.popleft()
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (c[0] + di, c[1] + dj)
                if n in cells and n not in seen:
                    seen.add(n)
                    q.append(n)
        return seen
    hub = tuple(doors()["market"])
    for cell in doors().values():
        main = component(hub, ok)
        if cell in main:
            continue
        prev, q = {cell: None}, deque([cell])
        while q:
            c = q.popleft()
            if c in main:
                while c is not None:
                    ok.add(c)
                    c = prev[c]
                break
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (c[0] + di, c[1] + dj)
                if n not in prev and (n in ok or n in stuff):
                    prev[n] = c
                    q.append(n)
    ok = component(hub, ok)                   # drop islands (e.g. the church-garden path)
    stop_props = {("props48", n) for n in (0, 1, 2, 3, 4, 5, 6, 8)}
    stops = {}                                # stop cell -> x of what people face there
    for e in deco:
        if e[0] != "fence" and (e[0], e[1]) in stop_props:
            for di, dj in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                c = (e[2] + di, e[3] + dj)
                if c in ok:
                    stops.setdefault(c, round(C.at(e[2] + .5, e[3] + .5)[0]))
    well_x = round(C.at(20.5, 20.5)[0])
    for c in ok:                              # round the well
        if 19 <= c[0] <= 22 and 19 <= c[1] <= 22:
            stops.setdefault(c, well_x)
    from layout import EXTRA_STOPS
    face = {(35, 6): C.at(34.5, 5.5)[0], (36, 6): C.at(37.5, 5.5)[0]}   # the training ring: the dummy / rack beside each gate cell
    bi, bj = next((i, j) for pid, _, i, j in POINTS if pid == "bounty")
    for c in EXTRA_STOPS:
        if c in ok:
            stops[c] = round(face.get(c, C.at(bi + .5, bj + .5)[0]))
    pen = C.at(30, 30), C.at(38, 35)
    data = {
        "iso": True, "size": [C.W, C.H], "cell": [32, 16], "origin": [C.OX, C.OY], "grid": N,
        "art": "res://art/town/iso/town_%s_%s.png",
        "art_lit": "res://art/town/iso/town_%s_%s_lit.png",    # dusk: lit windows and flames, drawn at lit_pos
        "lit_pos": lit_pos,
        "spots": spots,
        "lights": lights,
        "walk": sorted([list(c) for c in ok]),
        "stops": sorted([[c[0], c[1], x] for c, x in stops.items()]),   # [i, j, x people turn to face]
        "inn_doors": inn_doors,     # walkers come and go here most (everyone lives at the Inn)
        "raised": [[i, j, z] for (i, j), z in sorted(RAISED.items())],   # the hope path: walkers climb the stairs (px above the ground)
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
        "houses": [],                 # no generic homes (everyone lives at the Inn)
        "inn_wing": [list(h[:4]) for h in HOUSES],   # the Inn's lodging wing: part of the Inn on the town map
        "plateau": list(PLATEAU), "plateau_z": PLATEAU_Z,
    }
    with open(os.path.join(art, "town.json"), "w", newline="\n") as f:
        json.dump(data, f, indent=1)
    print("spots", len(spots), "walk", len(ok), "lights", len(lights))


if __name__ == "__main__":
    main(sys.argv[1])
