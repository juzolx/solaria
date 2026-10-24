"""Partner review round 1 (one-off source patch). Usage: py fix_round1.py"""
import json


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


patch("layout.py", [
    # 2: Trophy Cabin off the gatehouse, Guild Hall off the NE tower
    ('("cabin", "Trophy Cabin (lot)", 13, 30, 17, 34, "i", 16)', '("cabin", "Trophy Cabin (lot)", 13, 29, 17, 33, "i", 16)'),
    ('("guild", "Guild Hall", 29, 3, 34, 7, "j", 24)', '("guild", "Guild Hall", 28, 3, 33, 7, "j", 24)'),
    # 3: the Vault no longer stands in front of the Tavern door: it takes the east-lane lot, its old lot is a garden
    ('("stash", "Vault", 28, 16, 31, 19, "j", 18)', '("stash", "Vault", 28, 21, 31, 24, "i", 18)'),
    ('    (3, 21, 6, 24, "i"), (28, 21, 31, 24, "i"),        # doors on the west / east lanes',
     '    (3, 21, 6, 24, "i"),                               # door on the west lane'),
    # 4: the Church gets a pale stone forecourt across the lane from its door; 3: the garden
    ('    ("road", 34, 14, 38, 14),     # alley off the east lane',
     '    ("road", 34, 14, 38, 14),     # alley off the east lane\n    ("square", 7, 11, 8, 15),     # Church forecourt (pale stone)\n    ("garden", 28, 16, 31, 19),   # small public garden with a well (the Vault moved)'),
])

s = json.load(open("sprites.json"))
s["stash"] = {"file": "stash_warm.png", "flip": True}
for k in ("house3", "house4"):
    s.pop(k, None)
s["house3"] = {"file": "house_a.png"}            # house list shifted: (9,31,12,35) is now house3, door j
json.dump(s, open("sprites.json", "w", newline="\n"), indent=1)

patch("compose.py", [
    ('"path": "cobble", "dirt": "dirt",', '"path": "cobble", "dirt": "dirt", "garden": "grass",'),
    # 5: graves only in Hardcore - the Regular town has a church garden there
    ('''            k = TILE_OF[g[i][j]]''', '''            k = TILE_OF[g[i][j]]
            if k == "grave" and not HARDCORE:
                k = "grass"'''),
    # 1: a real day look (the dusk look is the default mood; the game grades per zone)
    ('''def phone(img, cx, cy, scale=2, size=(430, 932)):''', '''def day(img):
    """Day: brighter ground, roofs and walls, windows unlit, a lighter sky behind the walls."""
    rgb = img.convert("RGB")
    px = rgb.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = px[x, y]
            if r > 215 and g > 140 and b < 110 and r - b > 130:      # lit glass -> daylight glass
                px[x, y] = (96, 104, 118)
            elif (r, g, b) == (20, 18, 30):
                px[x, y] = (58, 70, 92)
    rgb = ImageEnhance.Brightness(rgb).enhance(1.22)
    return ImageEnhance.Color(rgb).enhance(1.1)


def phone(img, cx, cy, scale=2, size=(430, 932)):'''),
    # 6: the dungeon - a shaft of cyan light rising from the portal (hard bands, additive)
    ('''    out = ImageChops.add(dark, glow)''', '''    beam = Image.new("RGB", rgb.size, (0, 0, 0))
    bd = ImageDraw.Draw(beam)
    bx, by = at(19.9, 4.0, PLATEAU_Z + 30)
    for w, f in ((26, .10), (16, .16), (8, .24)):
        bd.polygon([(bx - w, by), (bx + w, by), (bx + w * .6, by - 150), (bx - w * .6, by - 150)], fill=(int(90 * f * 2), int(210 * f * 2), int(255 * f * 2)))
    glow = ImageChops.add(glow, beam)
    out = ImageChops.add(dark, glow)'''),
])

patch("decor.py", [
    # 5: Regular - church garden (flowers, bushes, benches, the angel); Hardcore - the graves
    ('''    step = 1 if HARDCORE else 2
    for i in range(2, 12, step):
        for j in range(2, 7 if HARDCORE else 6, step):
            if (i, j) != (6, 4):
                d.append((P32, graves[rng.randrange(len(graves))], i, j))''', '''    if HARDCORE:
        for i in range(2, 12):
            for j in range(2, 7):
                if (i, j) != (6, 4):
                    d.append((P32, graves[rng.randrange(len(graves))], i, j))
    else:   # the Church's garden: flower beds, bushes, benches round the angel, two old stones
        d += [(P32, 14, 3, 3), (P32, 15, 4, 5), (P32, 14, 9, 5), (P32, 15, 10, 3), (P32, 3, 5, 3), (P32, 3, 8, 5),
              (TREE, 12, 3, 5), (TREE, 13, 9, 2), (UP, 8, 2, 2), (UP, 8, 11, 6), (P32, 10, 10, 5), (P32, 6, 2, 6)]'''),
    ('''    d += [(P32, 28, 3, 6), (P32, 28, 9, 2)]''', '''    if HARDCORE:
        d += [(P32, 28, 3, 6), (P32, 28, 9, 2)]'''),
    # 6: braziers lining the main street up to the dungeon stairs; rocks at the cliff foot
    ('''    # Bounty Board beside the dungeon stairs''', '''    for i, j in ((18, 10), (21, 10), (18, 13), (21, 13)):
        d.append((UP, 4, i, j))
        LIGHTS.append((i + .5, j + .5, 40, (255, 160, 80), 44))
    d += [(P32, 24, 14, 8), (P32, 23, 16, 8), (P32, 24, 24, 8), (P32, 23, 26, 8), (P32, 44, 13, 8)]
    # Bounty Board beside the dungeon stairs'''),
    # vault props follow it to the east lane; the old lot is a fenced garden with a well
    ('''    d += [(P32, 31, 32, 20)]''', '''    d += [(P32, 31, 32, 21)]
    d += fence("wood", 28, 16, 32, 20)
    d = [e for e in d if not (e[0] == "fence" and e[4] == "j" and e[2] == 28 and e[3] == 18)]   # gate on the square side
    d += [(P32, 36, 30, 18), (P32, 3, 29, 17), (P32, 14, 31, 16), (P32, 15, 28, 19), (TREE, 9, 31, 19)]'''),
    # 7/11: life by the gate: crates, a torch, a guard's post on the dark wall lane
    ('''    # gate courtyard: torches by the sealed gate, crates''', '''    d += [(P48, 11, 26, 36), (P32, 12, 29, 36), (P32, 0, 27, 36), (P32, 19, 31, 36), (P32, 1, 12, 36)]
    LIGHTS.append((29.5, 36.5, 30, (255, 170, 90), 34))
    # gate courtyard: torches by the sealed gate, crates'''),
])

# trees: the dead ones only in Hardcore; a few more for the empty NE lawn and the SE corner
patch("decor.py", [
    ('''    for i, j in ((2, 5), (11, 2)):               # dead trees inside the graveyard fence
        t.append((rng.choice((6, 7)), i, j, 0, 0))''', '''    if HARDCORE:
        for i, j in ((2, 5), (11, 2)):           # dead trees inside the graveyard fence
            t.append((rng.choice((6, 7)), i, j, 0, 0))
    for i, j in ((27, 2), (27, 5), (35, 2), (36, 7), (35, 35), (37, 34)):
        add(i, j, oaks + pines)'''),
])

# 6: the plateau's front: natural rock again (no block courses that read as a wall)
patch("prep_plateau.py", [
    ('''for zz in (0, 8):                       # two courses of blocks under the paving''', '''for zz in ():                           # (block courses removed: they read as a wall)'''),
])
print("round1 patched")
