"""Hand-pixelled base hero (back three-quarter, 64 px body), drawn over AI candidate r6_d64_s53.

One char = material + shade (1 dark .. 4 light):
  hair 1-4 | skin a-d | eye e | sword-hand skin W X Y Z | linen i j k l | leather m n o p
  dark leather q r s t | trousers u v w x | boots A B C D | metal M N O P | grip/wrap G H I J
Layers are written to layers/base_<layer>.txt (+ .shade.txt). Hidden parts (skull under the hair)
come from the trace in layers/body.txt.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hero

CODE = {}
for mat, chars in [("H", "1234"), ("S", "abcd"), ("F", "WXYZ"), ("W", "ijkl"), ("V", "mnop"),
                   ("B", "qrst"), ("T", "uvwx"), ("K", "ABCD"), ("M", "MNOP"), ("G", "GHIJ")]:
    for i, c in enumerate(chars):
        CODE[c] = (mat, str(i + 1))
CODE["e"] = ("e", "1")


def blank():
    return [["."] * hero.W for _ in range(hero.H)], [["."] * hero.W for _ in range(hero.H)]


def draw(layer, rows, codes=None):
    m, s = layer
    codes = codes or CODE
    for y, x0, txt in rows:
        for i, c in enumerate(txt):
            if c in " .":
                continue
            if c == "x" and codes is not CODE and "x" not in codes:
                m[y][x0 + i] = "."; s[y][x0 + i] = "."; continue
            mat, sh = codes[c]
            m[y][x0 + i] = mat; s[y][x0 + i] = sh
    return layer


def denoise(layer, mats="H"):
    """Pixel-artist cleanup: a pixel whose shade has no same-shade 4-neighbour in the same material
    takes the most common neighbour shade (removes speckle, keeps clusters)."""
    m, s = layer
    H_, W_ = len(m), len(m[0])
    new = [r[:] for r in s]
    for y in range(H_):
        for x in range(W_):
            if m[y][x] not in mats:
                continue
            nb = [s[y + dy][x + dx] for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1))
                  if 0 <= y + dy < H_ and 0 <= x + dx < W_ and m[y + dy][x + dx] == m[y][x]]
            if nb and s[y][x] not in nb:
                new[y][x] = max(set(nb), key=nb.count)
    layer[1][:] = new
    return layer


def save(layer, name):
    m, s = layer
    p = os.path.join(hero.LAY, name)
    open(p + ".txt", "w").write("\n".join("".join(r) for r in m) + "\n")
    open(p + ".shade.txt", "w").write("\n".join("".join(r) for r in s) + "\n")


def trace_skull():
    """Skull/face skin from the trace (hidden under hair) at mid shade."""
    g = hero.load("body")[0]
    lay = blank()
    for y in range(16, 40):
        for x in range(hero.W):
            if g[y, x] == "S":
                lay[0][y][x] = "S"; lay[1][y][x] = "3"
    return lay


# ---------------- head (hair + face) ----------------
HEAD = [
    (17, 15, "33"),
    (18, 11, "33"), (18, 15, "3443"),
    (19, 10, "23444433332"),
    (20, 9, "234443333433222"),
    (21, 8, "23443333344332222"),
    (22, 7, "2344333233443322222"),
    (23, 6, "2334332223343322232233"),
    (24, 6, "2233322233332222322122"),
    (25, 5, "2233222233332222222122"),
    (26, 4, "22232222333322222122112"),
    (27, 5, "1222222223332222221121"),
    (28, 5, "1122222222222222211111"),
    (29, 6, "1122222222221211dc321"),
    (30, 6, "112222222221111cddc21"),
    (31, 7, "11222211ccb21cdddce"),
    (32, 7, "11222111cbac1cddceb"),
    (33, 8, "1122211cbcccddddcb"),
    (34, 9, "112211bcccdddcbb"),
    (35, 10, "111211bbcccccb"),
    (36, 11, "111111bbccba"),
    (37, 12, "111111abba"),
    (38, 13, "1111aaab"),
]


def split_head(rows):
    """Digits go to the hair layer, everything else to the body layer."""
    hair, face = [], []
    for y, x0, txt in rows:
        hair.append((y, x0, "".join(c if c.isdigit() else "." for c in txt)))
        face.append((y, x0, "".join("." if c.isdigit() else c for c in txt)))
    return hair, face


# ---------------- body below the head ----------------
BODY_LOW = [
    (28, 22, "cddc"), (29, 24, "dc"), (31, 18, "cc"), (32, 19, "c"),
    (34, 9, "b"), (35, 10, "bbbbbb"), (36, 11, "abbbbb"), (37, 12, "aabbbb"), (38, 13, "aaaa"),
    (39, 17, "aab"),                      # neck under the collar
    (51, 27, "cdddc"), (52, 27, "bcccb"), (53, 27, "abbba"),           # forearm (under the sleeve)
    (52, 3, "ccb"), (53, 3, "bcb"), (54, 3, "aa"),                     # far hand below its cuff
]
FIST = [(51, 39, "YZZYYX"), (52, 39, "XYXYXW"), (53, 39, "WXXXXW"), (54, 40, "WWWW")]

# ---------------- outfit: leather (linen shirt, leather vest, belt, pouch, trousers, boots) ----------------
LEATHER = [
    (39, 13, "jkllk"),
    (40, 10, "oppppoooonn"),
    (41, 8, "opppppmooooonn"),
    (42, 7, "opppooomooonnnnm"),
    (43, 6, "ooppoooomoonnnnm"), (43, 22, "kllk"),
    (44, 6, "opoooooomonnnnm"), (44, 21, "jkllk"),
    (45, 5, "noooooooomonnnnm"), (45, 21, "jkklkk"),
    (46, 6, "nooooooomnnnnnm"), (46, 21, "jjkkkj"), (46, 4, "kj"),
    (47, 6, "nooopooomnnnnnm"), (47, 21, "jjkkkkj"), (47, 3, "kkj"),
    (48, 6, "noooooonmnnnnmm"), (48, 21, "ijjkkkj"), (48, 3, "kkj"),
    (49, 6, "nnooooonmnnnnnm"), (49, 22, "ijjkkkj"), (49, 3, "jkj"),
    (50, 6, "nnoooonnmnnnnnnm"), (50, 22, "iijjklllllllk"), (50, 3, "sts"), (50, 35, "stts"),
    (51, 7, "nnoooonmnnnnnnm"), (51, 22, "iijjjkkkkkkji"), (51, 3, "qrq"), (51, 35, "rqrr"),
    (52, 7, "nnnooonmnnnnnmm"), (52, 23, "iijjjjjjjjji"), (52, 35, "rqrr"),
    (53, 7, "nnnnnnnmnnnnnnmm"), (53, 25, "iiiiiiiiii"), (53, 35, "qqqq"),
    (54, 7, "mnnnnnnmnnnnnmmm"),
    (55, 7, "mmnnnnnmmnnnmmmm"),
    (56, 6, "sttssssssssssssssss"),
    (57, 6, "rrrrrrrrrrrrrrrrrrr"),
    (58, 6, "qqqqqqqqqqqqqqqqqqq"),
    (56, 19, "pooon"), (57, 19, "noPnm"), (58, 19, "nnnnm"), (59, 19, "nnnmm"), (60, 19, "mmmm"),
    (59, 7, "wxxxwwwwuwww"),
    (60, 6, "wxxxwwwwwuwww"),
    (61, 6, "vwxxwwwwwuwww"), (61, 23, "vu"),
    (62, 6, "vwwwwwwwwuvwwwvvvvu"),
    (63, 7, "vwwwwwwwuuvwwvvvvu"),
    (64, 7, "vwxwwwvu"), (64, 17, "vwwwvvvu"),
    (65, 7, "vwxwwwvu"), (65, 17, "vwwvvvvu"),
    (66, 7, "vwwwwvu"), (66, 18, "vwwvvvu"),
    (67, 6, "vwwwwwvu"), (67, 18, "vwwvvvvu"),
    (68, 6, "vwwwwvvu"), (68, 18, "vwvvvvvu"),
    (69, 6, "uvvvvvvu"), (69, 18, "uvvvvvuu"),
    (70, 6, "uuuuuuuu"), (70, 18, "uuuuuuuu"),
    (71, 5, "BCDDDCCCBA"), (71, 17, "BCDDDCCCBA"),
    (72, 5, "ABCCCBBBBA"), (72, 17, "ABCCCBBBBA"),
    (73, 6, "BCCBBBBA"), (73, 18, "BCCBBBBA"),
    (74, 6, "BCCBBBBA"), (74, 18, "BCCBBBBA"),
    (75, 6, "BCBBBBBA"), (75, 18, "BCBBBBBA"),
    (76, 6, "BCBBBBAA"), (76, 18, "BCBBBBBAA"),
    (77, 6, "BCBBBBAA"), (77, 18, "BCBBBBBBAA"),
    (78, 5, "BCCBBBBAA"), (78, 18, "BCCBBBCCBAA"),
    (79, 5, "ABBBBBBAA"), (79, 18, "ABBBBBBBBAA"),
    (80, 6, "AAAAAAA"), (80, 19, "AAAAAAAAA"),
]
# vest rows above overwrite pouch columns; redraw the pouch on top afterwards
POUCH = [(56, 19, "pooon"), (57, 19, "noPnm"), (58, 19, "nnnnm"), (59, 19, "nnnmm"), (60, 19, "mmmm")]


def sword_rows():
    rows = []
    tip, base = (48.5, 1), (45.0, 45)
    for y in range(1, 46):
        t = (y - tip[1]) / (base[1] - tip[1])
        cx = tip[0] + (base[0] - tip[0]) * t
        w = 1 if y < 3 else (2 if y < 12 else 3)
        x0 = int(round(cx - (w - 1) / 2))
        rows.append((y, x0, {1: "P", 2: "PN", 3: "PON"}[w]))
    rows += [(46, 38, "OPPPPPPPOON"), (47, 37, "MNNNNNNNNNM"), (48, 41, "NOOM")]
    for y in range(49, 64):
        rows.append((y, 41, "IH" if y % 2 else "HG"))
    rows += [(64, 40, "OPON"), (65, 40, "NONM"), (66, 41, "NM")]
    return rows


def build():
    hair_rows, face_rows = split_head(HEAD)
    body = trace_skull()
    draw(body, face_rows + BODY_LOW + FIST)
    save(body, "base_body")
    front = blank(); draw(front, FIST); save(front, "base_body_front")
    hair = denoise(draw(blank(), hair_rows)); save(hair, "base_hair_short")
    o = draw(blank(), LEATHER); draw(o, POUCH); save(o, "base_outfit_leather")
    s = draw(blank(), sword_rows()); save(s, "base_weapon_sword")


if __name__ == "__main__":
    build()
