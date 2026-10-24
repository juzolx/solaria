"""Partner review round 2 + Juzo "everyone lives at the Inn" (one-off source patch). Usage: py fix_round3.py"""
import json


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


patch("decor.py", [
    # 1/4: Regular church garden: flowerbeds, benches, shrine; no headstones or crosses (graves are Hardcore only)
    ('''    else:   # the Church's garden: flower beds, bushes, benches round the angel, two old stones
        d += [(P32, 14, 3, 3), (P32, 15, 4, 5), (P32, 14, 9, 5), (P32, 15, 10, 3), (P32, 3, 5, 3), (P32, 3, 8, 5),
              (TREE, 12, 3, 5), (TREE, 13, 9, 2), (UP, 8, 2, 2), (UP, 8, 11, 6), (P32, 10, 10, 5), (P32, 6, 2, 6)]
    d += [(P48, 12, 6, 4), (P48, 13, 10, 3), (P32, 54, 11, 2)]''', '''    else:   # the Church's garden: flowerbeds either side of a gravel path, benches facing the angel, a shrine
        for i, j in ((3, 2), (4, 2), (3, 3), (8, 2), (9, 2), (9, 3), (3, 5), (4, 6), (9, 5), (8, 6), (10, 4), (2, 4)):
            d.append((P32, 14 if (i + j) % 2 else 15, i, j))
        d += [(P32, 3, 5, 4), (P32, 3, 7, 4), (P32, 3, 5, 6), (P32, 3, 7, 6), (TREE, 12, 2, 2), (TREE, 13, 11, 6),
              (UP, 8, 10, 2), (P32, 11, 7, 2)]
    d += [(P48, 12, 6, 4)] + ([(P48, 13, 10, 3), (P32, 54, 11, 2)] if HARDCORE else [])'''),
    # Inn yard: busy - benches, barrels, lanterns, a cart
    ('''    # inn / tavern fronts''', '''    # the Inn's yard (everyone lives at the Inn): benches, barrels, lantern, cart
    d += [(P32, 3, 10, 14), (P32, 0, 9, 14), (P32, 0, 12, 14), (UP, 5, 11, 14), (P48, 9, 8, 14)]
    LIGHTS.append((11.5, 14.5, 34, (255, 190, 110), 40))
    # inn / tavern fronts'''),
    # 6: living tree in the garden lot by the Vault's old spot
    ('''(P32, 15, 28, 19), (TREE, 9, 31, 19)]''', '''(P32, 15, 28, 19), (TREE, 0, 31, 19)]'''),
    # 8: no brown pile by the gate - a cart with crates
    ('''    d += [(P32, 12, 17, 37), (P32, 12, 22, 37), (P32, 11, 16, 37), (P32, 1, 23, 37)]''',
     '''    d += [(P32, 12, 17, 37), (P32, 12, 22, 37), (P48, 9, 24, 37), (P32, 1, 23, 37)]'''),
    # 9: life at the square's south edge: one more stall
    ('''          (P48, 4, 25, 23), (P48, 0, 22, 24), (P48, 2, 17, 24), (P48, 1, 16, 22),''',
     '''          (P48, 4, 25, 23), (P48, 0, 22, 24), (P48, 2, 17, 24), (P48, 1, 16, 22), (P48, 3, 14, 24),'''),
    # orchard where the east houses were: a grid of fruit trees, beehive-ish crates
    ('''    # houses: woodpiles''', '''    # orchard (east, where the houses were)
    d += [(P32, 30, 35, 12), (P32, 1, 36, 16)]
    # houses: woodpiles'''),
    ('''    d += [(P32, 16, 33, 13), (P32, 0, 33, 18),  (P32, 50, 27, 22),
          (P32, 56, 13, 33), (P32, 35, 12, 35)]''', '''    d += [(P32, 50, 27, 22)]'''),
    # vegetable plots also on the old south house lot
    ('''    for i in range(13, 18):
        for j in range(29, 34):''', '''    for i in list(range(9, 13)) + list(range(13, 18)):
        for j in range(29, 34):'''),
    ('''    d += fence("wood", 13, 29, 18, 34) + [(P32, 40, 15, 31)]''', '''    d += fence("wood", 9, 29, 18, 34) + [(P32, 40, 15, 31), (P32, 40, 10, 32)]'''),
])
# trees: orchard grid; no tree rows hugging the FRONT walls (they read as rubble behind the wall)
patch("decor.py", [
    ('''        for i, j in ((n, 1), (1, n), (n, N - 2), (N - 2, n)):''', '''        for i, j in ((n, 1), (1, n)):'''),
    ('''    belt = [(i, j) for i in range(35, 39) for j in range(21, 26) if (i + j) % 2 == 0]   # east wall strip''',
     '''    belt = [(i, j) for i in range(35, 38) for j in range(21, 26) if (i + j) % 2 == 0]   # east wall strip
    for i in range(34, 38):                    # the orchard: fruit trees in rows
        for j in range(10, 19, 2):
            if (i + j) % 2 == 0:
                t.append((rng.choice((0, 4, 14, 5)), i, j, 0, 0))'''),
])
patch("compose.py", [
    # 3: shorter light shaft (fits the phone frame) and cyan light on the stairs and lane below (not ground-masked)
    ('''    for w, f in ((26, .10), (16, .16), (8, .24)):
        bd.polygon([(bx - w, by), (bx + w, by), (bx + w * .6, by - 150), (bx - w * .6, by - 150)], fill=(int(90 * f * 2), int(210 * f * 2), int(255 * f * 2)))''',
     '''    for w, f in ((26, .10), (16, .16), (8, .24)):
        bd.polygon([(bx - w, by), (bx + w, by), (bx + w * .6, by - 95), (bx - w * .6, by - 95)], fill=(int(90 * f * 2), int(210 * f * 2), int(255 * f * 2)))
    for k, f in ((3, .10), (2, .16), (1, .22)):   # spill down the plateau stairs onto the lane
        sx, sy = at(20, 8.2, 8)
        bd.ellipse([sx - 34 * k, sy - 14 * k, sx + 34 * k, sy + 14 * k], fill=(int(70 * f * 2), int(180 * f * 2), int(230 * f * 2)))'''),
    # 5: Hardcore readable: moonlit (not black) and fog over the graves
    ('''        out = ImageEnhance.Color(out).enhance(0.85)
        out = ImageChops.multiply(ImageEnhance.Brightness(out).enhance(0.95), Image.new("RGB", out.size, (225, 232, 255)))''',
     '''        out = ImageEnhance.Color(out).enhance(0.85)
        out = ImageChops.multiply(ImageEnhance.Brightness(out).enhance(1.05), Image.new("RGB", out.size, (225, 232, 255)))
        fog = Image.new("RGB", out.size, (0, 0, 0))
        fd = ImageDraw.Draw(fog)
        for i, j, r in ((4, 3, 70), (8, 5, 60), (5, 6, 50), (10, 2, 44)):   # low hard-edged fog banks over the graves
            fx, fy = at(i, j)
            fd.ellipse([fx - r, fy - r * .28, fx + r, fy + r * .28], fill=(26, 30, 38))
        out = ImageChops.add(out, fog)'''),
])
patch("prep_ruin.py", [
    ('rgb = ImageEnhance.Brightness(rgb).enhance(0.86)', 'rgb = ImageEnhance.Brightness(rgb).enhance(1.0)'),
])
patch("layout_map.py", [('("Graveyard", 6, 3.5)', '("Garden / Graveyard (Hardcore)", 6, 3.5)'), ('("Pet pen", 34, 32)', '("Pet pen", 30, 31), ("Orchard", 36, 14), ("Plots", 13, 31)')])
print("round3 patched")
