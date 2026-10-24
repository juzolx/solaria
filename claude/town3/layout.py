"""Town layout v3 (town dev 2, Oct 24 2026): the single source for the map, the composed town
and town.json. Grid N x N cells, i = x (screen down-right), j = y (screen down-left); cell
(0, 0) is the top corner. Building faces the viewer sees: +i (right face) and +j (left face),
so every door faces +i or +j onto a street.
Follows the reference town's logic: wall ring + corner towers, gatehouse, cobbled main street,
central market square, river with a stone bridge, buildings in yards between lanes."""

N = 40

# zones: (kind, x0, y0, x1, y1) inclusive cells, painted in order (later wins)
GROUND = [
    ("grass", 0, 0, N - 1, N - 1),
    ("plateau", 13, 1, 26, 7),
    ("grave", 1, 1, 11, 6),
    ("yard", 28, 1, 38, 6),
    ("road", 1, 8, 38, 9),        # north lane under the plateau
    ("road", 18, 7, 21, 37),      # main street: dungeon stairs -> gate
    ("square", 13, 15, 26, 24),   # market square
    ("road", 1, 19, 12, 20),      # cross street west
    ("road", 27, 19, 38, 20),     # cross street east
    ("road", 6, 8, 7, 37),        # west lane
    ("road", 32, 8, 33, 26),      # east lane
    ("water", 1, 27, 38, 28),     # river
    ("road", 1, 36, 38, 37),      # wall lane (inside the wall)
    ("bridge", 17, 26, 22, 29),   # stone bridge on the main street
    ("bridge", 5, 27, 8, 28),     # footbridge west
    ("field", 1, 30, 4, 34),
    ("pen", 30, 30, 37, 34),      # pet pen (fenced)
    ("yard", 13, 25, 17, 25),
    ("yard", 22, 25, 26, 25),
]

PLATEAU, PLATEAU_Z = (13, 1, 26, 7), 24   # raised block (sprite), dungeon stands on it
BRIDGE = (17, 26, 22, 29)

# walls: ring + corner towers + gatehouse (sealed)
WALL_H, TOWER_H = 16, 30
TOWERS = [(0, 0), (N - 3, 0), (0, N - 3), (N - 3, N - 3),   # corners, 3x3 each (top-left cell)
          (30, 0), (0, 19), (N - 3, 19)]                    # mid-wall towers break the long runs
GATEHOUSE = (16, 38, 23, 39)

# lots: id, label, x0, y0, x1, y1, door side ("i" or "j"), height in map px
LOTS = [
    ("gate", "Dungeon", 17, 2, 22, 6, "j", 26),
    ("guild", "Guild Hall", 29, 2, 34, 6, "j", 24),
    ("inn", "Inn", 13, 10, 17, 14, "j", 24),
    ("tavern", "Tavern", 24, 10, 28, 14, "j", 24),
    ("church", "Church (lot)", 1, 10, 5, 16, "i", 22),
    ("shop", "Shop", 9, 21, 12, 24, "i", 20),
    ("smith", "Blacksmith", 9, 15, 12, 18, "i", 20),
    ("stash", "Vault", 28, 16, 31, 19, "j", 18),
    ("cabin", "Trophy Cabin (lot)", 13, 30, 17, 34, "i", 16),
    ("clinic", "Clinic", 24, 30, 28, 34, "j", 20),
]
HOUSES = [  # plain homes for density (x0, y0, x1, y1, door side)
    (35, 10, 38, 13, "j"), (35, 15, 38, 18, "j"),
    (1, 21, 4, 24, "i"), (28, 21, 31, 24, "i"),
    (9, 30, 12, 34, "j"), (1, 30, 4, 34, None),
]
# small things on the square / streets: id, label, cell
POINTS = [
    ("bounty", "Bounty Board", 23, 8),      # by the dungeon stairs
    ("mail", "Mailbox", 12, 14),            # beside the Inn
    ("obelisk", "Prophecy stone", 15, 4),
]
# the Market is the whole square (well + stalls + paving) as one tap area
MARKET = ("market", "Market", 13, 15, 26, 24)
TREE_BELTS = [(35, 21, 38, 25), (1, 11, 1, 17), (34, 1, 38, 1), (9, 10, 11, 13), (34, 21, 38, 25), (1, 25, 12, 26),
              (27, 25, 38, 26), (13, 35, 31, 35)]


def door_cell(x0, y0, x1, y1, side):
    """The street-side cell in front of a door on the +i or +j face."""
    return (x1 + 1, (y0 + y1) // 2) if side == "i" else ((x0 + x1) // 2, y1 + 1)


def door_paths():
    """Every door gets a dirt path over the grass to the nearest street (shortest, never
    through a building), like the yard paths in the reference town. Returns cells."""
    from collections import deque
    g = [["grass"] * N for _ in range(N)]
    for k, x0, y0, x1, y1 in GROUND:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                g[i][j] = k
    blocked = set()
    rects = [l[2:6] for l in LOTS] + [h[:4] for h in HOUSES] + [PLATEAU]
    for x0, y0, x1, y1 in rects:
        blocked |= {(i, j) for i in range(x0, x1 + 1) for j in range(y0, y1 + 1)}
    street = {"road", "square", "bridge"}
    out = set()
    doors = [door_cell(*l[2:7]) for l in LOTS] + [door_cell(*h) for h in HOUSES if h[4]]
    for d in doors:
        if g[d[0]][d[1]] in street:
            continue
        prev, q = {d: None}, deque([d])
        while q:
            c = q.popleft()
            if g[c[0]][c[1]] in street:
                while c:
                    if g[c[0]][c[1]] not in street:
                        out.add(c)
                    c = prev[c]
                break
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (c[0] + di, c[1] + dj)
                if 0 < n[0] < N - 1 and 0 < n[1] < N - 1 and n not in blocked and n not in prev and g[n[0]][n[1]] != "water":
                    prev[n] = c
                    q.append(n)
    return sorted(out)


GROUND += [("path", i, j, i, j) for i, j in door_paths()]
