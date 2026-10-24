"""Hand-pixelled front portrait (menus), 44 x 46, same char code as draw_master.py.
Extra code for the face layer: E-ramp eye chars 5 6 7 8 (1 lash/pupil .. 4 white glint).
Layers: port_body (face skin, ears, neck), port_face_<expr>, port_hair_<style>, port_outfit_leather.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_master as D

D.CODE.update({"5": ("E", "1"), "6": ("E", "2"), "7": ("E", "3"), "8": ("E", "4"), "y": ("h", "1")})


def rows_from(block, x0, y0):
    out = []
    for i, r in enumerate(block):
        out.append((y0 + i, x0, r))
    return out


# ---------------- skin: face, ears, neck ----------------
FACE_SKIN = [
    (6, 15, "cccccccccccccc"),
    (7, 13, "cccccccccccccccccc"),
    (8, 12, "cccccccccccccccccccc"),
    (9, 11, "cccccccccccccccccccccc"),
    (10, 10, "ccccccccccccccccccccccbb"),
    (11, 10, "bbbbbbbbbbbbbbbbbbbbbbbb"),
    (12, 10, "bbbbbbbbbbbbbbbbbbbbbbbb"),
    (13, 10, "cbbbbbbbbbbbbbbbbbbbbbbb"),
    (14, 10, "ccccccccccccccccccccccbb"),
    (15, 10, "dcccccccccccccccccccccbb"),
    (16, 10, "dccccccccccccccccccccccb"),
    (17, 10, "dcccccccccccccccccccccbb"),
    (18, 10, "ddcccccccccccccccccccccb"),
    (19, 11, "dcccccccccccccccccccbb"),          # temple steps in 1 px ...
    (20, 11, "dcccccccccccccccccccbb"),
    (21, 10, "ddddcccccccccccccccccdbb"),        # ... cheekbone steps back out, lit ridge
    (22, 10, "bcddccccccccccccccccccbb"),
    (23, 10, "bbcccccccccbccccccccccba"),
    (24, 10, "abbcccccccccccccccccbbaa"),        # shade run under each cheekbone toward the mouth
    (25, 11, "abbccccccccccccccbbaa"),
    (26, 12, "abbcccccccccccccbaa"),
    (27, 13, "abcccccccccccbbaa"),
    (28, 14, "abccccdddcccbbaa"),
    (29, 16, "abccccccbbaa"),
    (30, 18, "aabbbbaa"),
    # ears
    (18, 8, "cb"), (19, 8, "cab"), (20, 8, "cbb"), (21, 8, "bb"), (22, 9, "b"),
    (18, 34, "bb"), (19, 33, "bab"), (20, 33, "bbb"), (21, 34, "ba"), (22, 34, "a"),
    # neck + chest in the collar opening
    (31, 18, "aaaaaaaa"), (32, 18, "abbbbbba"), (33, 18, "bbbbbbba"), (34, 19, "bbbbba"),
    (35, 20, "bbba"), (36, 20, "abba"), (37, 21, "aa"),
]

# ---------------- expressions (brows use hair shades so they follow hair colour) ----------------
EYES_OPEN = [
    (17, 13, "55555"), (17, 26, "55555"),
    (18, 14, "8665"), (18, 26, "5866"),
    (19, 14, "6675"), (19, 26, "5667"),
    (20, 14, "6775"), (20, 26, "5677"),
    (21, 14, "b55b"), (21, 26, "b55b"),
]
FACES = {
    "determined": [(14, 13, "yy"), (15, 15, "yyy"), (14, 29, "yy"), (15, 26, "yyy")] + EYES_OPEN +
                  [(23, 22, "b"), (26, 20, "baab")],
    "fierce": [(14, 12, "yy"), (15, 14, "yyy"), (16, 16, "yy"),
               (14, 30, "yy"), (15, 27, "yyy"), (16, 26, "yy"),
               (18, 13, "55555"), (18, 26, "55555"), (17, 16, "55"), (17, 26, "55"),
               (19, 14, "8665"), (19, 26, "5866"), (20, 14, "6775"), (20, 26, "5677"), (21, 14, "b55b"), (21, 26, "b55b"),
               (23, 22, "b"), (25, 20, "5555"), (26, 20, "5665"), (27, 21, "55")],
    "smile": [(14, 13, "yyyy"), (14, 27, "yyyy"),
              (18, 14, "5555"), (18, 26, "5555"), (19, 13, "5"), (19, 18, "5"), (19, 25, "5"), (19, 30, "5"),
              (21, 12, "bb"), (21, 30, "bb"),
              (23, 22, "b"), (25, 19, "a"), (25, 24, "a"), (26, 20, "a55a"), (27, 21, "aa")],
}

# ---------------- hair styles (front) ----------------
HAIR_SHORT = rows_from([
    "......3....33...33.....2....",
    ".....334..3443.3332...22....",
    "....3344433444333333322.....",
    "..23344444433333333322221...",
    ".2334444433333333333222221..",
    "2233443332223344333322222211",
    "2233433322333343332222222211",
    "2234333223333433322232222211",
    "2233332233332333222322222111",
    "2223322333223322223222212211",
    "1222322232223222232222122211",
    "1222222.222221.22221.1222211",
    "12221....2221...221....12211",
    "1221......21............1211",
    "121......................211",
    "11........................11",
], 8, 2)
HAIR_LONG = rows_from([            # long, parted, falls past the shoulders (front part)
    "..........33333333..........",
    ".......3344444433333........",
    ".....33444444333433332......",
    "...2334444433333443333222...",
    "..233444433322333443332222..",
    ".22334433322223333433222221.",
    "2233443322222.2233343322221.",
    "223343322221...222333322221.",
    "22344322221.....2223332222 1",
    "2233432221.......222332222 1",
    "223342221.........22232221.1",
    "22333221...........2222221.1",
    "2233221.............222221.1",
    "223221...............22221..",
    "22321.................2221..",
    "2232..................2221..",
    "2232...................221..",
    "2232...................221..",
    "2232...................221..",
    "2232...................221..",
    "2221...................221..",
    "2221...................211..",
    "2221...................211..",
    "2221...................211..",
    "1221...................211..",
    "122.....................11..",
    "121.....................11..",
    "11......................1...",
], 8, 2)
HAIR_BUZZ = rows_from([            # close crop: follows the skull, high hairline, ears free
    "........................",
    ".......33333333333......",
    ".....334444443333332....",
    "...33444443333333332....",
    "..2344443333333333222...",
    ".233443333333333332222..",
    ".2334333333333333322221.",
    "22332222222222222222221.",
    "2221................2221",
    "221..................221",
    "21....................21",
    "1......................1",
], 10, 4)
HAIR_TAIL = rows_from([            # swept back, tied tail (tail shows at the side)
    "............................",
    "......3333444433333.........",
    "....334444444443333322......",
    "...33444444333333333222.....",
    "..2344444333333333332222....",
    ".233444333322223333322221...",
    ".23344332222222233332222213.",
    "2233432222222222223322222133",
    "2233322...........2222222133",
    "22332.............222222 1332",
    "2232...............22221.1332",
    "222.................2221.1322",
    "21...................221..322",
    "1.....................21..322",
    "..........................321",
    "..........................321",
    "..........................221",
    "...........................21",
    "..........................221",
    "..........................321",
    "..........................321",
    "..........................221",
    "..........................21.",
    ".........................221.",
    ".........................21..",
    ".........................1...",
], 8, 2)
HAIRS = {"short": HAIR_SHORT, "long": HAIR_LONG, "buzz": HAIR_BUZZ, "tail": HAIR_TAIL}

# ---------------- outfit (leather) ----------------
def vest_rows():
    rows = [(33, 15, "kll"), (33, 26, "llk"),
            (34, 9, "noooopjkll"), (34, 25, "llkjpoooon"),
            (35, 7, "nooooopjkkl"), (35, 24, "lkkjpooooon"),
            (36, 6, "noooooopijkk"), (36, 24, "kkjipooooonm"),
            (37, 5, "nooooooooopijk"), (37, 24, "kjipoooonnnnm"),
            (38, 5, "noooooooooopij"), (38, 20, "kllk"), (38, 24, "jipooooonnnnm")]
    for y in range(39, 46):
        l0 = 4 if y > 39 else 5
        left = "n" + "o" * (16 - l0 - 2) + "p"
        right = "p" + "o" * 6 + "n" * (38 - 26 - 7 - 1 + (y > 39)) + "m"
        rows += [(y, l0, left), (y, 17, "jk"), (y, 19, "kllkk"[: 5] + "k"), (y, 25, "kj"), (y, 27, right[: 39 - 27 + (y > 39)])]
    return rows


def vest_tone(rows):
    out = []
    for y, x, t in rows:
        t2 = "".join({"o": "n", "p": "o"}.get(c, c) for c in t)
        if y >= 42:                                      # sleeve corner under the vest edge
            if x <= 6:
                t2 = "kkj" + t2[3:]
            if x + len(t2) >= 37:
                t2 = t2[:-3] + "jkk"
        out.append((y, x, t2))
    return out


def build():
    body = D.blank(); D.draw(body, FACE_SKIN); D.save(body, "port_body")
    for k, rows in FACES.items():
        D.save(D.draw(D.blank(), rows), "port_face_" + k)
    for k, rows in HAIRS.items():
        D.save(D.denoise(D.draw(D.blank(), [(y, x, r.replace(" ", ".")) for y, x, r in rows])), "port_hair_" + k)
    D.save(D.draw(D.blank(), vest_tone(vest_rows())), "port_outfit_leather")


if __name__ == "__main__":
    build()
