"""Partner review round 2 + Juzo "everyone lives at the Inn" (one-off source patch). Usage: py fix_round3.py"""
import json


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


patch("decor.py", [
    ("""        for i, j in ((n, 1), (1, n), (n, N - 2), (N - 2, n)):""", """        for i, j in ((n, 1), (1, n)):"""),
    ("""    for i in range(N):                 # river: trees only""", """    for i in range(34, 38):                    # the orchard: fruit trees in rows
        for j in range(10, 19, 2):
            if (i + j) % 2 == 0:
                t.append((rng.choice((0, 4, 14, 5)), i, j, 0, 0))
    for i in range(N):                 # river: trees only"""),
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
