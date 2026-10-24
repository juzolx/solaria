"""Fable critique pass 3 polish (one-off source patch). Usage: py fix_pass3.py"""


def patch(path, pairs):
    s = open(path, encoding="utf-8").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8").write(s)


patch("compose.py", [
    # 2: only real light survives dusk (windows, flames, the portal) - not lit-looking wood slats
    ('''            if r > 205 and g > 140 and b < 120 and r - b > 90:      # lit windows / flames, not pumpkins
                dp[x, y] = (r, g, b)''', '''            if r > 215 and g > 140 and b < 110 and r - b > 130:     # lit windows / flames, not wood or pumpkins
                dp[x, y] = (int(r * .9), int(g * .9), int(b * .9))     # 1: windows a touch below the dungeon'''),
    # 7: pools are iso ellipses (2:1)
    ('''            gd.ellipse([x - rr, y - rr * .55, x + rr, y + rr * .55], fill=tuple(int(c * f) for c in col))''',
     '''            gd.ellipse([x - rr, y - rr * .5, x + rr, y + rr * .5], fill=tuple(int(c * f) for c in col))'''),
    # 5: Hardcore town reads colder everywhere, not just at the church
    ('''    if HARDCORE:                       # a cold, dead corner around the ruined church and graveyard''',
     '''    if HARDCORE:                       # the whole town colder and greyer...
        out = ImageEnhance.Color(out).enhance(0.85)
        out = ImageChops.multiply(ImageEnhance.Brightness(out).enhance(0.95), Image.new("RGB", out.size, (225, 232, 255)))
    if HARDCORE:                       # ...and a cold, dead corner around the ruined church and graveyard'''),
])

patch("decor.py", [
    # 1: the dungeon's own pool, bigger and falling down the stairs
    ('(19.8, 4.2, Z + 26, (120, 230, 255), 80)', '(19.8, 4.2, Z + 26, (120, 230, 255), 110), (19.5, 8.0, 6, (90, 200, 255), 70)'),
    # 3: level 3 also gets the gilded sign and a second lantern post
    ('''            d += [(UP, l3[0], *f[1]), (UP, l3[0], *f[2]), (UP, l3[1], *side), (P32, 12, *f[3])]''',
     '''            d += [(UP, l3[0], *f[1]), (UP, l3[0], *f[2]), (UP, l3[1], *side), (P32, 12, *f[3]),
                  (UP, 6, side[0] + (door == "i"), side[1] + (door == "j"))]'''),
    # 7: empty-lot lantern is a small light
    ('''    LIGHTS.append((x1 + .5, y0 + 1.5, 34, (255, 190, 110), 40))
    return e''', '''    LIGHTS.append((x1 + .5, y0 + 1.5, 34, (255, 190, 110), 26))
    return e'''),
])

# 6: Hardcore church statue weathered (bright stone -> dark mossy grey)
patch("prep_ruin.py", [('''rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.45)''', '''for y in range(h):                                                     # the white saint goes grey and mossy
    for x in range(w):
        r, g, b, a = px[x, y]
        if a and min(r, g, b) > 150 and max(r, g, b) - min(r, g, b) < 40:
            px[x, y] = (70, 78, 66, a) if (x + y) % 4 == 0 else (88, 90, 92, a)
rgb = ImageEnhance.Color(im.convert("RGB")).enhance(0.45)''')])
print("pass3 patched")
