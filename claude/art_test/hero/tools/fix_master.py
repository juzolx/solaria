"""Hand pixel pass on the baked base hero (face, ear, eye, hair clusters, weapon hand)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint import Layer

body = Layer("b_body")
hair = Layer("b_hair_short")

# --- face sliver: hair layer gives way to skin ---
FACE = {  # y: (x0, mats, shades) for the BODY layer
    29: (22, "SS", "43"),
    30: (21, "SSSS", "3443"),
    31: (16, "SS..SSSSee", "33..344311"),
    32: (15, "SSSS.SSSSeS", "3213.344313"),
    33: (15, "SSSSSSSSSSS", "32133344332"),
    34: (15, "SSSSSSSSSS", "2332333332"),
    35: (16, "SSSSSSSS", "22333332"),
    36: (17, "SSSSSS", "233321"),
    37: (18, "SSSS", "1221"),
    38: (17, "SSS", "112"),
}
for y, (x0, m, s) in FACE.items():
    body.paint(y, x0, m, s)
    for i, c in enumerate(m):
        if c != ".":
            hair.paint(y, x0 + i, ".")
# sideburn between ear and cheek
hair.paint(31, 18, "HH", "21").paint(32, 19, "H", "1")
hair.paint(29, 24, "HHH", "322").paint(30, 25, "HH", "21").paint(29, 28, ".")
body.save(); hair.save()

# ---------------- full hand-drawn head (hair digits 1-4, skin letters a-d = shades 1-4, e = eye) ----------------
HEAD = {
    17: [(15, "33")],
    18: [(11, "33"), (15, "3443")],
    19: [(10, "23444433332")],
    20: [(9, "234443333433222")],
    21: [(8, "23443333344332222")],
    22: [(7, "2344333233443322222")],
    23: [(6, "2334332223343322232233")],
    24: [(6, "2233322233332222322122")],
    25: [(5, "2233222233332222222122")],
    26: [(4, "22232222333322222122112")],
    27: [(5, "1222222223332222221121")],
    28: [(5, "1122222222222222211111")],
    29: [(6, "1122222222221211dc321")],
    30: [(6, "112222222221111cddc21")],
    31: [(7, "11222211ccb21cdddce")],
    32: [(7, "11222111cbac1cddceb")],
    33: [(8, "1122211cbcccddddcb")],
    34: [(9, "112211bcccdddcbb")],
    35: [(10, "111211bbcccccb")],
    36: [(11, "111111bbccba")],
    37: [(12, "111111abba")],
    38: [(13, "1111aaab")],
}


def apply_head(body, hair, head=HEAD, y0=16, y1=39, x0=3, x1=29):
    # wipe head area in both layers (body keeps its skull under the hair), then paint
    for y in range(y0, y1):
        for x in range(x0, x1):
            if hair.m[y][x] != ".":
                hair.m[y][x] = "."; hair.s[y][x] = "."
    for y, segs in head.items():
        for xs, row in segs:
            for i, c in enumerate(row):
                x = xs + i
                if c.isdigit():
                    hair.m[y][x] = "H"; hair.s[y][x] = c
                elif c in "abcd":
                    body.m[y][x] = "S"; body.s[y][x] = str("abcd".index(c) + 1)
                elif c == "e":
                    body.m[y][x] = "e"; body.s[y][x] = "1"
    # visible face skin must not be covered by hair (already wiped); skull under hair stays


body = Layer("b_body"); hair = Layer("b_hair_short")
apply_head(body, hair)
body.save(); hair.save()

# ---------------- sword fist (drawn above the grip) ----------------
body = Layer("b_body")
FIST = {51: (39, "cddccb"), 52: (39, "bcbcba"), 53: (39, "abbbba"), 54: (40, "aaaa")}
for y, (xs, row) in FIST.items():
    for i, c in enumerate(row):
        body.m[y][xs + i] = "F"; body.s[y][xs + i] = str("abcd".index(c) + 1)
body.save()
