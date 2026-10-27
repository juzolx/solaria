"""Town dressing on the layout grid: props grouped by purpose next to their buildings, trees in
belts, the graveyard, pen, fields, street lamps and the lights the dusk grade keeps lit.
Each entry: (sheet, index, i, j[, z]) -> drawn bottom-centre on the centre of cell (i, j)."""
import random
from layout import TREE_BELTS, PLATEAU_Z, N

rng = random.Random(11)
HARDCORE = False    # Hardcore town: the graveyard is full (one grave per fallen hero), no church light
P48, P32, TREE = "props48", "props32", "trees"

# lit sources: (i, j, z, colour, radius) - z in px above the ground
LIGHTS = []
# the four brazier pillars round the stair foot: town dressing, so they stay in the game's base
# picture (the other props_up are level props the game draws itself). (22,10), not (21,10): clear
# of the stair newel, so the flame no longer sits on its top.
# (22,10) is gone: the Tavern stood in front of its foot (Juzo: props behind buildings float)
BRAZIERS = ((18, 10), (18, 13), (21, 13))
LEVEL = 3           # building level shown in the mockup (1-3); props below grow with it
UP = "props_up"
# per building: (level-2 item, level-3 items) from the upgrade sheet
#  0 scaffolding, 1 stone+timber pile, 2 red banner, 3 blue banner, 4 brazier pillar, 5 lantern post,
#  6 gilded sign, 7 awning+barrels, 8 potted tree, 9 knight statue, 10 weapon stand, 11 wagon,
#  12 shed, 13 garden wall, 14 notice board, 15 treasure chests
LEVEL_ITEMS = {"inn": (6, (2, 8)), "tavern": (7, (2, 8)), "smith": (10, (3, 9)), "shop": (6, (3, 11)),
               "guild": (10, (2, 9)), "stash": (6, (3, 15)), "clinic": (13, (3, 8))}


def level_props(owners=None):
    """Level 1: scaffolding and a pile of stone/timber beside the building (still growing).
    Level 2: a lantern post plus the building's own upgrade. Level 3: banners and a showpiece."""
    from layout import LOTS
    d = []
    for lid, _, x0, y0, x1, y1, door, _ in LOTS:
        if lid not in LEVEL_ITEMS:
            continue
        l2, l3 = LEVEL_ITEMS[lid]
        if door == "j":     # the street row in front of the +j face, left to right
            f = [(x, y1 + 1) for x in (x0, x0 + 1, x1 - 1, x1)]
            side = (x1 + 1, y0 + 1)
        else:               # the street column in front of the +i face
            f = [(x1 + 1, y) for y in (y0, y0 + 1, y1 - 1, y1)]
            side = (x0 + 1, y1 + 1)
        from layout import door_cell
        dc = door_cell(x0, y0, x1, y1, door)
        if dc in f[1:3]:    # narrow building: never stand anything in the doorway
            f[1:3] = [f[0], f[3]] if dc == f[1] else [f[0], f[3]]
            f[1], f[2] = (side[0] + (door == "i"), side[1] + (door == "j")), (side[0] + 2 * (door == "i"), side[1] + 2 * (door == "j"))
        if lid == "clinic":  # its door is reached along the wall lane from the west: props stand east of it
            f = [(dc[0] + 1, dc[1]), (dc[0] + 2, dc[1]), (dc[0] + 3, dc[1]), (dc[0] + 4, dc[1])]
        if lid == "tavern":  # the Vault stands in front of the row's west end: everything east of the door
            f = [(dc[0] + 3, dc[1]), (dc[0] + 4, dc[1]), (dc[0] + 5, dc[1]), (dc[0] + 5, dc[1] + 1)]   # (clear of the Vault's merlons; row 20 stays open to the Vault door)
        n0 = len(d)
        if LEVEL == 1:      # still growing: scaffolding and a pile of stone and timber at the front
            d += [(UP, 0, *f[0]), (UP, 1, *f[1]), (UP, 11, *f[3])]
        if LEVEL >= 2:      # a lantern post and the building's own upgrade
            d += [(UP, 5, *f[0]), (UP, l2, *f[3])]
            LIGHTS.append((f[0][0] + .5, f[0][1] + .5, 34, (255, 190, 110), 40))
        if LEVEL >= 3:      # banners by the door and a showpiece at the side
            lift = (4,) if lid == "stash" else ()   # its side is the river bank: the chest and the sign stand
            d += [(UP, l3[0], *f[1]), (UP, l3[0], *f[2]), (UP, l3[1], *side, *lift), (UP, 16, *f[3]),   # 4 px up the grass, off the water line (Fable P6/P7)
                  (UP, 6, side[0] + (door == "i"), side[1] + (door == "j"), *lift)]
            LIGHTS.append((f[3][0] + .5, f[3][1] + .5, 30, (255, 170, 90), 36))
        if owners is not None:
            owners += [lid] * (len(d) - n0)
    return d


def lamp(i, j):
    LIGHTS.append((i + .5, j + .5, 34, (255, 190, 110), 46))
    return (P48, 10, i, j)


def fence(kind, i0, j0, i1, j1):
    """Fence around the vertex rectangle (i0, j0)-(i1, j1): unit segments ("fence", kind, i, j, axis)."""
    f = []
    for i in range(i0, i1):
        f += [("fence", kind, i, j0, "i"), ("fence", kind, i, j1, "i")]
    for j in range(j0, j1):
        f += [("fence", kind, i0, j, "j"), ("fence", kind, i1, j, "j")]
    return f


def decor():
    d = level_props()
    Z = PLATEAU_Z
    # plateau: prophecy stone + candle shrines at the dungeon, torches at the stairs
    # (the stone stands at the plateau's front: further back the Dungeon hid its foot)
    # (no lone candle block at (23, 5): a pale stone with no shadow, Fable round 5 P12)
    d += [(P48, 7, 14, 6, Z), (P32, 46, 24, 3, Z),
          (P32, 12, 17, 7, Z), (P32, 12, 22, 7, Z), (P32, 44, 25, 2, Z)]
    LIGHTS.extend([(17.5, 7.5, Z + 30, (255, 170, 90), 40), (22.5, 7.5, Z + 30, (255, 170, 90), 40),
                   (19.8, 4.2, Z + 26, (120, 230, 255), 110), (19.5, 8.0, 6, (90, 200, 255), 70)])
    # (no torch on the stair rail: from the street it stood on the Tavern chimney's top; the plateau
    # torches and the braziers light the stair)
    # MARKET = the whole square as one place (Juzo): the well in the middle of the square with
    # the main street flowing round it, a ring of stalls around it, crates/carts between
    d += [(P48, 5, 20, 20),
          (P48, 1, 17, 18), (P48, 2, 22, 17),     # (Juzo: no stall overlaps a building or stands
          (P48, 4, 25, 24), (P48, 0, 22, 24), (P48, 2, 16, 24), (P48, 3, 14, 19),   # stacked behind another; the purple one clear of the Shop)
          (P32, 0, 16, 20), (P32, 1, 16, 21), (P32, 39, 22, 19), (P32, 2, 18, 23), (P32, 0, 21, 16),
          (P32, 3, 21, 22), (P32, 29, 20, 22)]
    LIGHTS.extend([(20.5, 20.5, 20, (255, 190, 110), 50)])
    for i, j in BRAZIERS:
        d.append((UP, 4, i, j))
        LIGHTS.append((i + .5, j + .5, 40, (255, 160, 80), 44))
    d += [(P32, 23, 16, 8), (P32, 24, 24, 8), (P32, 23, 26, 8)]
    # Bounty Board beside the dungeon stairs (heroes read it before descending); Mailbox by the Inn
    d += [(P48, 6, 17, 8), (P48, 8, 12, 14)]   # the board west of the stair foot, clear of the Tavern
    # street lamps along the main street and lanes
    # (none behind a building: the Inn hid (17, 11) and (13, 9), the Clinic (22, 31))
    d += [lamp(22, 25), *([] if HARDCORE else [lamp(7, 15)]), lamp(8, 26)] # (no lamp by the Vault's front: the game drew the Vault's lantern over it)
    # the Inn's yard (everyone lives at the Inn): benches, barrels, lantern, cart
    d += [(P32, 3, 10, 14), (P32, 0, 9, 14), (P32, 0, 12, 14)]   # (no lantern: (12, 13) was on the wing's own cell)
    # inn / tavern fronts
    # (none on the Inn's front row: the game draws the level props there over them)
    d += [(P32, 0, 22, 15), (P32, 0, 23, 15)]   # (the Tavern hid 25 and 26)
    # blacksmith yard on the west lane, just inside the gate (faces the lane on +i)
    # (the yard clutter and the shop and vault fronts are gone: they stood on the level props'
    # cells, and the game draws a level prop over whatever stands in front of it)
    # (the public garden behind the Tavern is gone: the Tavern stands in front of all of it)
    # guild training yard: a fenced dirt ring with dummies, a shield target, racks, hay and a grindstone
    # (Juzo: the Guild sat on top of the dummies) the ring keeps clear of the Guild's wing (i 34), the
    # corner tower (row 3) and the east wall's battlements (i 37); its open front is the gate
    # (and its west side open: the Guild's L3 showpiece and sign stand right behind that rail)
    d += [e for e in fence("wood", 35, 4, 37, 6) if not (e[4] == "i" and e[3] == 6) and not (e[4] == "j" and e[2] == 35)]
    d += [(P32, 40, 36, 4), (P32, 40, 36, 5), (P32, 18, 35, 4), (P32, 3, 34, 7)]
    # clinic: herb pots, cauldron; pet pen with fence, kennel, hay
    d += [(P32, 43, 21, 34)]   # (Juzo: west of the door the planter hid its lower half: out on the lane's edge)
    # (the pen ends a row short of the lane: its south rail stood on the Clinic's level props' row,
    # Juzo saw a cart on the fence line) the Clinic's wall closes the west side
    d += [e for e in fence("wood", 28, 29, 32, 34) if not (e[4] == "j" and e[2] == 28)]
    d += [(P48, 14, 30, 30), (P32, 58, 29, 32), (P32, 59, 30, 33), (P32, 37, 29, 30)]
    # the paved plaza where the Blacksmith stood (Juzo: no crops): a shade tree, a lamp and
    # two benches facing the square
    d += [(TREE, 0, 10, 17), (P32, 3, 12, 17), (P32, 3, 12, 18), lamp(11, 16)]
    # vegetable plots behind the gatehouse, fenced: rows of wheat, a bare path row, pumpkins, cabbages
    for i in range(9, 18):
        # (Juzo: the field ran up to the wall line) four rows and a fence along its south side, so
        # it reads as a fenced plot inside the walls; the pieces the gatehouse hides are culled
        for j, c in {29: 22, 30: 22 if i < 13 else 21, 31: None, 32: 20 if i < 13 else 21}.items():
            if c is not None:
                d.append((P32, c, i, j))
    d += [e for e in fence("wood", 9, 29, 18, 33) if (e[2], e[3]) != (18, 32)] + [(P32, 40, 15, 31), (P32, 40, 10, 32), (P32, 50, 12, 31), (P32, 30, 13, 31)]
    # orchard (east, where the houses were)
    d += [(P32, 30, 35, 12), (P32, 50, 34, 17), (P32, 2, 36, 11)]   # (none by the east wall: it cut their feet)
    # trophy cabin: hide rack, skull pike, antler... (built state)
    d += [(P32, 46, 7, 25)]
    # graveyard: rows of graves, angel, cross, iron fence, gate to the lane
    graves = (6, 7, 8, 10, 60, 63, 9)
    if HARDCORE:
        for i in range(2, 12):
            for j in range(2, 7):    # (the Inn's roof stands in front of the east half: no graves whose foot it hides)
                if (i, j) != (3, 4) and (i, j) in GRAVE_CELLS:
                    d.append((P32, graves[rng.randrange(len(graves))], i, j))
    else:   # the Church's garden: flowerbeds either side of a gravel path, benches facing the angel, a shrine
        d += [("bed", 0, i, j) for i0, j0 in ((3, 2), (8, 2), (3, 5), (8, 5)) for i in (i0, i0 + 1) for j in (j0, j0 + 1)]
        # (the Inn's roof stands in front of the garden's east half: nothing there whose foot it hides)
        d += [(P32, 3, 5, 5), (TREE, 0, 10, 2)]
        # the east half: a gravel walk to a bell shrine, hedges, a bench under the oak, potted flowers
        # (the bell shrine stands at the back, (11, 2): at (11, 4) the Inn wing's roof ran under its post)
        d += [(P32, 54, 11, 2), (P32, 11, 11, 3), (TREE, 13, 10, 3), (P32, 14, 2, 4), (P32, 15, 2, 6)]
    d += [(P48, 12, 3, 4)] + ([(P48, 13, 10, 3), (P32, 54, 11, 2)] if HARDCORE else [])
    if HARDCORE:   # three big pieces among the headstones, for scale: a sarcophagus, an obelisk, a mausoleum on the wall
        d += [(P48, 17, 3, 1), (P48, 18, 8, 1)]       # (the sarcophagus at (1, 4) lay behind the west wall)
    if HARDCORE:     # (the graves that stood by the ruin were behind it and the Trophy Cabin)
        d += [(TREE, 7, 5, 9)]
    hid = {(1, 1), (1, 2), (2, 1), (5, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 4), (12, 5), (12, 6)}   # in the tower, behind the Inn
    d += [e for e in fence("iron" if HARDCORE else "wood", 1, 1, 12, 7)
          if not (e[4] == "i" and e[3] == 7 and e[2] in (6, 7)) and (e[2], e[3]) not in hid]
    if HARDCORE:
        d += [(P32, 28, 3, 6), (P32, 28, 9, 2)]
    # torches on the inner wall faces between towers
    for i in (5, 35):                   # (14 and 25 stood behind the Dungeon and the Guild)
        d.append((P32, 12, i, 1))
        LIGHTS.append((i + .5, 1.5, 28, (255, 170, 90), 30))
    for j in (6,):                      # (26 stood behind the Blacksmith)
        if HARDCORE and j < 20:
            continue
        d.append((P32, 12, 1, j))
        LIGHTS.append((1.5, j + .5, 28, (255, 170, 90), 30))
    d += [("fence", "wood", 7, 27, "j"), ("fence", "wood", 7, 28, "j"), ("fence", "wood", 9, 27, "j"), ("fence", "wood", 9, 28, "j")]
    for i, j in ((3, 26), (13, 29), (25, 26), (27, 29), (31, 26), (33, 29), (36, 26)):
        d.append(("reeds", 0, i, j))
    # river side: reeds-ish rocks, signpost at the bridge
    d += [(P32, 19, 23, 25), (P32, 24, 12, 29), (P32, 23, 30, 29), (P32, 25, 36, 30)]   # the stump on the bank, not in the water
    # (nothing between the wall lane and the front wall: the battlements cut the feet of all of it)
    # (the gate courtyard's torches and crates stood behind the front wall's battlements: gone)
    # forge glow, church glow
    LIGHTS.extend([(5.5, 31.5, 14, (255, 120, 50), 44)] + ([] if HARDCORE else [(5.5, 13.5, 30, (255, 220, 150), 60)]))
    d += [("folk", "villager", 18, 21), ("folk", "hero", 21, 20), ("folk", "villager", 15, 19), ("folk", "hero", 24, 9),
          ("folk", "hero", 19, 31), ("folk", "villager", 33, 19)]
    return d


def trees():
    """Placed like the reference town: a broken row just inside the walls, trees lining both
    river banks, small clusters in back yards; never on roads, lots, doors or the square.
    Returns (index, i, j, dx, dy)."""
    from layout import GROUND, LOTS, HOUSES, PLATEAU, TOWERS
    g = [["grass"] * N for _ in range(N)]
    for k, x0, y0, x1, y1 in GROUND:
        for i in range(x0, x1 + 1):
            for j in range(y0, y1 + 1):
                g[i][j] = k
    busy = set()
    rects = [l[2:6] for l in LOTS] + [h[:4] for h in HOUSES] + [PLATEAU]
    for x0, y0, x1, y1 in rects:      # the building plus one cell of breathing room
        busy |= {(i, j) for i in range(x0 - 1, x1 + 2) for j in range(y0 - 1, y1 + 2)}
    for tx, ty in TOWERS:
        busy |= {(tx + a, ty + b) for a in range(-1, 4) for b in range(-1, 4)}
    busy |= {(1, 18), (1, 19), (1, 7)}  # behind the Trophy Cabin's roof and the Inn wing: only a scrap of crown showed
    busy |= {(34, 10), (35, 17), (36, 21), (34, 18), (36, 10), (35, 12), (37, 22), (37, 24)}   # in front of the Guild's and the Tavern's level props (the game draws those over a crown)
    free = lambda i, j: 0 < i < N - 1 and 0 < j < N - 1 and g[i][j] == "grass" and (i, j) not in busy
    oaks, pines, small = (0, 1, 4, 15, 14), (2, 3, 10, 11), (5, 9, 12, 13)
    t, used = [], set()
    def add(i, j, pool, jit=4):
        if free(i, j) and (i, j) not in used:
            used.add((i, j))
            t.append((pool[rng.randrange(len(pool))], i, j, rng.randint(-jit, jit), rng.randint(-2, 2)))
    for n in range(1, N - 1):          # inner wall rows: mostly pines, with gaps
        for i, j in ((n, 1), (1, n)):
            if rng.random() < .55:
                add(i, j, pines + oaks)
    orch = random.Random(23)                   # the orchard: 3 fruit-tree kinds, some flipped, loosely spaced
    for i, j in ((34, 10), (36, 10), (35, 12), (37, 13), (34, 14), (36, 15), (35, 17), (37, 17), (34, 18)):
        tr = (orch.choice((0, 4, 14)) + (100 if orch.random() < .5 else 0), i, j, orch.randint(-6, 6), orch.randint(-3, 3))
        if (i, j) not in busy:   # (the draws still happen, so the other trees keep their look)
            t.append(tr)
    for i in range(N):                 # river: trees only on the far (north) bank, set back a
        for j in range(N):             # cell so they never hide the water
            if g[i][j] == "water" and (j == 0 or g[i][j - 1] != "water") and i % 3 == 0 and rng.random() < .8:
                add(i, j - 2, oaks + (8,))
    for i, j in ((2, 24), (3, 25), (36, 21), (37, 22), (37, 24), (36, 36), (37, 35)):
        add(i, j, oaks + small)
    if HARDCORE:
        for i, j in ((5, 6), (10, 4)):           # dead trees inside the graveyard fence, crowns clear of the walls
            rng.choice((6, 7))
            t.append((6, i, j, 0, 0))
    for i, j in ((27, 2), (27, 5), (35, 2), (36, 7), (34, 30), (35, 32), (33, 33), (36, 34), (34, 35)):
        add(i, j, oaks + pines)
    return t


GRAVE_CELLS = {(2, 3), (2, 4), (2, 5), (2, 6), (3, 2), (3, 3), (3, 5), (3, 6), (4, 2), (4, 3), (4, 4), (4, 5), (4, 6),
               (5, 2), (5, 5), (5, 6), (6, 2), (8, 2), (9, 2), (10, 2), (10, 3), (11, 2), (11, 3), (11, 4)}
LOT_HIDDEN = {(5, 10), (6, 10), (4, 17), (7, 16), (5, 21), (6, 21)}   # empty-lot rope behind the Inn wing and the Shop


def empty_lot(x0, y0, x1, y1):
    """An unbuilt plot: rope-and-stake fence, a sign, stacked logs and stones waiting."""
    e = [f for f in fence("wood", x0, y0, x1 + 1, y1 + 1) if (f[2], f[3]) not in LOT_HIDDEN]
    e += [(P48, 20, x1, y0 + 1), (P48, 21, x0 + 1, y1), (P32, 19, x1, y1), (P32, 33, x0 + 1, y0 + 1), (P32, 16, x0 + 2, y0 + 1), (P32, 23, x1 - 1, y0 + 2),
          (P32, 24, x0 + 1, y1 - 1), (P32, 50, x1 - 1, y1 - 2), (P32, 1, x0 + 2, y1 - 1)]
    return e   # the yellow "build here" sign and a plank stack (fix_r4_art.py), the old top-down lot's motif
