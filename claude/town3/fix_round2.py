"""Round 2 fixes (Fable doors/zones report). Usage: py fix_round2.py"""


def patch(path, pairs):
    s = open(path, encoding="utf-8", newline="").read()
    for a, b in pairs:
        assert a in s, (path, a[:70])
        s = s.replace(a, b, 1)
    open(path, "w", encoding="utf-8", newline="").write(s)


patch("layout.py", [
    # the wall lane comes one row in so the front wall doesn't hide it; Clinic, pen and house lift a row
    ('    ("road", 1, 36, 38, 37),      # wall lane (inside the wall)', '    ("road", 1, 35, 38, 36),      # wall lane (one row clear of the wall so the wall never hides it)'),
    ('("clinic", "Clinic", 24, 31, 28, 35, "j", 20)', '("clinic", "Clinic", 24, 30, 28, 34, "j", 20)'),
    ('    ("pen", 30, 31, 36, 34),      # pet pen (fenced), beside the Clinic', '    ("pen", 30, 30, 36, 33),      # pet pen (fenced), beside the Clinic'),
    ('    (9, 31, 12, 35, "j"),        # door on the wall lane', '    (9, 30, 12, 34, "j"),        # door on the wall lane'),
    # the Blacksmith one row away from the Church steps; the west cross street is one row
    ('("smith", "Blacksmith", 9, 15, 12, 18, "i", 20)', '("smith", "Blacksmith", 9, 16, 12, 19, "i", 20)'),
    ('    ("road", 1, 19, 12, 20),      # cross street west', '    ("road", 1, 20, 12, 20),      # cross street west'),
    ('    ("dirt", 13, 15, 13, 18),     # forge apron: crafts ground in front of the Blacksmith', '    ("dirt", 13, 16, 13, 19),     # forge apron: crafts ground in front of the Blacksmith'),
    # the Tavern's door is at the east end of its front: pave the square out to meet it
    ('    ("square", 7, 11, 8, 15),     # Church forecourt (pale stone)', '    ("square", 7, 11, 8, 15),     # Church forecourt (pale stone)\n    ("square", 27, 15, 28, 15),   # the square reaches the Tavern door'),
])

patch("decor.py", [
    # stalls off the Shop and Blacksmith doorsteps; the well off the Inn's step
    ('    d += [(P48, 5, 19, 19),', '    d += [(P48, 5, 20, 20),'),
    ('          (P48, 0, 14, 17), (P48, 1, 17, 17),', '          (P48, 0, 24, 21), (P48, 1, 17, 17),'),
    ('          (P48, 4, 25, 23), (P48, 0, 22, 24), (P48, 2, 17, 24), (P48, 1, 15, 23),', '          (P48, 4, 25, 23), (P48, 0, 22, 24), (P48, 2, 17, 24), (P48, 1, 16, 22),'),
    ('    LIGHTS.extend([(19.5, 19.5, 20, (255, 190, 110), 50)])', '    LIGHTS.extend([(20.5, 20.5, 20, (255, 190, 110), 50)])'),
    # blacksmith yard follows it
    ('''    d += [(P32, 17, 13, 16), (P32, 18, 13, 18), (P32, 42, 13, 15), (P32, 16, 9, 19), (P32, 33, 11, 19)]''',
     '''    d += [(P32, 17, 13, 17), (P32, 18, 13, 19), (P32, 42, 14, 16)]'''),
    ('(12.5, 16.5, 14, (255, 120, 50), 44)', '(12.5, 17.5, 14, (255, 120, 50), 44)'),
    # clinic + pen one row up
    ('''    d += [(P32, 37, 29, 34), (P32, 43, 29, 32)]
    d += fence("wood", 30, 31, 37, 35)''', '''    d += [(P32, 37, 29, 33), (P32, 43, 29, 31)]
    d += fence("wood", 30, 30, 37, 34)'''),
    ('''    d += [(P48, 14, 34, 32), (P48, 15, 35, 33), (P32, 58, 32, 33), (P32, 59, 35, 31), (UP, 5, 31, 32)]
    LIGHTS.append((31.5, 32.5, 34, (255, 190, 110), 36))''', '''    d += [(P48, 14, 34, 31), (P48, 15, 35, 32), (P32, 58, 32, 32), (P32, 59, 35, 30), (UP, 5, 31, 31)]
    LIGHTS.append((31.5, 31.5, 34, (255, 190, 110), 36))'''),
    # gate courtyard on the new lane row
    ('''    d += [(P32, 12, 17, 36), (P32, 12, 22, 36), (P32, 11, 16, 35), (P32, 1, 23, 35)]
    LIGHTS.extend([(17.5, 36.5, 30, (255, 170, 90), 36), (22.5, 36.5, 30, (255, 170, 90), 36)])''',
     '''    d += [(P32, 12, 17, 37), (P32, 12, 22, 37), (P32, 11, 16, 37), (P32, 1, 23, 37)]
    LIGHTS.extend([(17.5, 37.5, 30, (255, 170, 90), 36), (22.5, 37.5, 30, (255, 170, 90), 36)])'''),
    ('''    d += [(P48, 11, 26, 36), (P32, 12, 29, 36), (P32, 0, 27, 36), (P32, 19, 31, 36), (P32, 1, 12, 36)]
    LIGHTS.append((29.5, 36.5, 30, (255, 170, 90), 34))''', '''    d += [(P48, 11, 26, 37), (P32, 12, 29, 37), (P32, 0, 27, 37), (P32, 19, 31, 37), (P32, 1, 12, 37)]
    LIGHTS.append((29.5, 37.5, 30, (255, 170, 90), 34))'''),
    ('lamp(22, 35)', 'lamp(22, 33)'),
])
patch("export_town.py", [
    ('''        "pen": [C.at(30, 35)[0], C.at(30, 31)[1], C.at(37, 31)[0] - C.at(30, 35)[0], C.at(37, 35)[1] - C.at(30, 31)[1]],
        "pen_cells": [31, 32, 36, 34],''', '''        "pen": [C.at(30, 34)[0], C.at(30, 30)[1], C.at(37, 30)[0] - C.at(30, 34)[0], C.at(37, 34)[1] - C.at(30, 30)[1]],
        "pen_cells": [31, 31, 36, 33],'''),
])
patch("walk.py", [('    ok -= {(19, 19), (20, 19), (19, 20), (20, 20)}      # the well', '    ok -= {(20, 20), (21, 20), (20, 21), (21, 21)}      # the well')])
patch("export_town.py", [('    stops |= {c for c in ok if 18 <= c[0] <= 21 and 18 <= c[1] <= 21}      # round the well',
                          '    stops |= {c for c in ok if 19 <= c[0] <= 22 and 19 <= c[1] <= 22}      # round the well')])
print("round2 patched")
