"""Pass 2 (Juzo's critique): chibi hero seen straight from behind, proportions taken from the old
in-game LPC heroes (head ~43 % of height, compact limbs, arms at the sides, feet apart), drawn fresh
by hand at a bit more resolution (54 px tall) with our ramps, outline and gear.

Same char code as draw_master.py:
  hair 1-4 | skin a-d | sword-hand skin W X Y Z | linen i j k l | leather m n o p
  dark leather q r s t | trousers u v w x | boots A B C D | metal M N O P
Writes the same layer names as pass 1 (base_body, base_body_front, outfit_*, hair_*, w_*), so the
sheet builder is unchanged. Weapons are the pass-1 drawings (Juzo: keep them), moved to the new hand.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_master as D
import draw_custom as C

CX = 26          # body centre column
HAND_SHIFT = (1, 3)        # pass-1 sword hand (39-44, 51-54) -> pass-2 hand (40-45, 56-59)


def mirror_rows(rows):
    """Left half rows (y, x0, txt) -> mirrored right half around CX (x -> 2*CX - x)."""
    out = []
    for y, x0, t in rows:
        x1 = x0 + len(t) - 1
        out.append((y, 2 * CX - x1, t[::-1]))
    return out


# =========================================================== BODY (skin)
BODY = [
    # skull under the hair (hidden by the mop; shaped for the close crop)
    (24, 19, "cccccccccccccc"), (25, 17, "cccccccccccccccccc"), (26, 16, "cccccccccccccccccccc"),
    (27, 15, "cccccccccccccccccccccc"), (28, 14, "cccccccccccccccccccccccc"),
] + [(y, 14, "ccccccccccccccccccccccbb") for y in range(29, 38)] + [
    (38, 15, "cccccccccccccccccccccb"), (39, 16, "bccccccccccccccccccb"), (40, 17, "bcccccccccccccccbb"),
    (41, 19, "bbccccccccccbb"), (42, 20, "abbbbbbbbbba"),
    # ears stick out at the sides of the mop
    (33, 12, "c"), (34, 11, "ccb"), (35, 11, "dcb"), (36, 11, "cbb"), (37, 12, "b"),
    (33, 39, "b"), (34, 38, "abb"), (35, 38, "aba"), (36, 38, "aba"), (37, 39, "a"),
    # neck between the nape tufts
    (43, 22, "abbbbbbba"), (44, 22, "abbbbbbba"), (45, 23, "aaaaaaa"),
    # left hand hanging at the side
    (54, 13, "cdc"), (55, 13, "bccb"), (56, 14, "ab"),
    # sword forearm: connects the right cuff to the fist
    (52, 38, "cddc"), (53, 38, "bccb"),
]
FIST = [(54, 40, "YZZYX"), (55, 40, "XYYXW"), (56, 40, "WXXXW"), (57, 41, "WWW")]

# =========================================================== HAIR (back view)
HAIR_SHORT = [(22, 22, '3'), (22, 27, '33'), (23, 18, '334443'), (23, 25, '34433'), (24, 17, '3344443234444333'), (25, 16, '334444442223444443332'), (26, 15, '23444444322223444433322'), (27, 14, '2344444432112233333332221'), (28, 13, '234444443211222333333222211'), (29, 12, '2344444321123443123333212211'), (30, 12, '2344443211234432123332212211'), (31, 12, '1234433211233321123322212111'), (32, 13, '233432112333321122322112211'), (33, 13, '233332112333221122222122211'), (34, 13, '22333211223221112222122111'), (35, 13, '22332112222211212221122111'), (36, 13, '12332112222221221221221111'), (37, 13, '12232112222211221211211111'), (38, 14, '133311333331133113113111'), (39, 14, '113323333311133111131111'), (40, 15, '1121122221112211111111'), (41, 16, '12112221111211111111'), (42, 18, '11122111121111111'), (43, 19, '1211'), (43, 24, '1211'), (43, 29, '1111'), (44, 20, '11'), (44, 25, '11'), (44, 30, '11')]

HAIR_LONG = HAIR_SHORT[:13] + [
    # falls over the shoulders and down the back to the shoulder blades, 3 locks with partings
    (34, 15, "223333332222233322221"),
    (35, 15, "2233332222222333222221"),
    (36, 15, "2333322222222233222221"),
]
LOCKS = [(15, 20, 56), (21, 30, 58), (31, 36, 55)]   # (x0, x1, last row): left lit, middle, right shade


def long_rows():
    rows = list(HAIR_LONG)
    for y in range(37, 59):
        row = ""
        x0 = 15 if y < 50 else 16
        x1 = 36 if y < 50 else 35
        for x in range(x0, x1 + 1):
            li = next(i for i, (a, b, e) in enumerate(LOCKS) if a <= x <= b) if 15 <= x <= 36 else 2
            a, b, end = LOCKS[li]
            if y > end or (y >= end - 1 and x in (a, b)) or (y == end and x in (a + 1, b - 1)):
                row += "."; continue
            s = (3 if li == 0 else 2 if li == 2 else 3) if x not in (a, b) else 1
            if li == 1 and x in (a + 1, b - 1): s = 2
            if li == 0 and 40 <= y <= 44 and a < x < b - 1: s = 4
            if li == 1 and 44 <= y <= 47 and a + 2 < x < b - 3: s = 4
            if y >= end - 2 and s > 1: s -= 1
            if (x - a) % 4 == 3 and y % 6 != 0 and s > 1: s -= 1      # broken strand lines
            row += str(s)
        rows.append((y, x0, row))
    return rows


HAIR_BUZZ = [
    (26, 21, "3344443"), (27, 19, "33444444333"), (28, 18, "3344443333332"),
    (29, 17, "234444333333322"), (30, 16, "23444333333333222"), (31, 16, "23443333333333222"),
    (32, 16, "23433333333332222"), (33, 16, "22333333333322221"), (34, 16, "22333333333222221"),
    (35, 16, "2233333332222221"), (36, 16, "222333322222221"), (37, 17, "1222222222221"),
    (38, 17, "112222222211"), (39, 18, "1112222111"), (40, 19, "11.11.11"),
]
# body skull is wider than the buzz rows: hair must cover it, so fill side rows to the skull edge
def buzz_rows():
    rows = []
    skull = {y: (x0, x0 + len(t) - 1) for y, x0, t in BODY if 24 <= y <= 43 and set(t) <= set("abcd") and len(t) > 6}
    for y in range(24, 42):
        if y not in skull:
            continue
        a, b = skull.get(y, (21, 27) if y == 26 else (19, 32))
        if y >= 39:          # nape: skin shows below a soft hairline
            a, b = a + 2, b - 2
        n = b - a + 1
        row = ""
        for i in range(n):
            x = a + i
            t = (x - a) / max(1, n - 1)
            s_ = 3 if t < 0.45 else 2
            if y <= 29 and 0.15 < t < 0.4: s_ = 4                      # one lit patch top-left
            if y % 3 == 0 and (x + y) % 6 in (0, 1) and t > 0.3 and 0 < i < n - 1: s_ = max(1, s_ - 1)   # sparse cropped-hair dashes, shadow side
            if i == 0 or i == n - 1 or t > 0.85: s_ = max(1, s_ - 1)
            if y >= 37: s_ = min(s_, 2)
            if y >= 39: s_ = 1
            row += str(s_)
        rows.append((y, a, row))
    rows.append((23, 22, "3.33"))
    return rows


def tail_rows():
    rows = list(HAIR_SHORT[:12])          # top of the head swept back
    rows += [
        (32, 15, "23333333332233333221"),
        (33, 15, "223333332222333322221"),
        (34, 16, "2223332211223332221"),
        (35, 16, "1222221111122222211"),
        (36, 17, "12222111111222221"),
        (37, 18, "112211111112211"),
        (38, 19, "1111qqrq11111"),
        (39, 22, "qsrq"), (40, 22, "2332"), (41, 21, "233432"), (42, 21, "234432"), (43, 21, "233332"),
        (44, 21, "234321"), (45, 21, "233321"), (46, 21, "232221"), (47, 22, "23221"), (48, 22, "2321"),
        (49, 22, "2221"), (50, 23, "221"), (51, 23, "21"), (52, 24, "1"),
    ]
    return rows


TCODE = C.cm(H="1234", B="qrst")

# =========================================================== OUTFITS
BOOTS = [
    (74, 16, "BCDDDCCCBA"), (75, 16, "ABCCCBBBBA"), (76, 17, "BCCBBBBA"), (77, 17, "BCCBBBBA"),
    (78, 17, "BCBBBBBA"), (79, 16, "ABBBBBBBAA"), (80, 17, "AAAAAAAA"),
    (73, 28, "BCDDDCCCBA"), (74, 28, "ABCCCBBBBA"), (75, 29, "BCCBBBBA"), (76, 29, "BCBBBBBA"),
    (77, 29, "BCBBBBAA"), (78, 28, "ABBBBBBBAA"), (79, 29, "AAAAAAAA"),
]
LEGS = [
    (62, 17, "wxxxwwwwwuwwwwvvvvu"), (63, 17, "vwxxwwwwwuwwwwvvvvu"), (64, 17, "vwwwwwwwwuvwwwvvvvu"),
    (65, 17, "vwxwwwvu"), (65, 28, "vwwwvvvu"),
    (66, 17, "vwxwwwvu"), (66, 28, "vwwvvvvu"),
    (67, 17, "vwwwwwvu"), (67, 28, "vwwvvvvu"),
    (68, 17, "vwwwwvvu"), (68, 29, "vwwvvvu"),
    (69, 17, "vwwwwvvu"), (69, 29, "vwvvvvu"),
    (70, 17, "vwwwvvvu"), (70, 29, "vwvvvvu"),
    (71, 17, "uvvvvvvu"), (71, 29, "uvvvvuu"),
    (72, 17, "uvvvvvvu"), (72, 29, "uuuuuuu"),
    (73, 17, "uuuuuuuu"),
]
SLEEVES = [
    (48, 14, "kl"), (49, 13, "jkl"), (50, 12, "jkkl"), (51, 12, "jkkk"), (52, 12, "ijkk"), (53, 12, "ijkk"),
    (54, 12, "ijkj"), (55, 12, "ijjj"), (56, 12, "iijj"), (57, 12, "iiji"),
    (58, 11, "rsst"), (59, 11, "qrrr"), (60, 11, "qqqq"),                       # left cuff
    (48, 37, "kj"), (49, 37, "kjj"), (50, 37, "kjji"), (51, 37, "kjji"), (52, 37, "jjji"), (53, 38, "jjji"),
    (54, 38, "jjii"), (55, 39, "jji"), (55, 38, "j"),
    (56, 39, "sst"), (57, 39, "rrrq"),                                          # right cuff
]
LEATHER = [
    (46, 21, "jkk"), (46, 29, "kkj"), (47, 20, "jkllllllllkj"),
    (48, 17, "oppppppppmooooonnnm"),
    (49, 16, "opppppppppmoooooonnnm"),
    (50, 16, "noppppoooomooooonnnnm"),
    (51, 16, "nooooooooomoooonnnnnm"),
    (52, 16, "nooppooooomoooonnnnnm"),
    (53, 16, "noopppooomooooonnnnnm"),
    (54, 16, "nooooooooomoooonnnnnm"),
    (55, 16, "nooooooooomoooonnnnnm"),
    (56, 16, "nnoooooooomooonnnnnnm"),
    (57, 16, "nnoooooooomooonnnnnmm"),
    (58, 17, "nnnoooooomoonnnnnmm"),
    (59, 17, "mnnnnnnnnmnnnnnnmmm"),
    (60, 16, "stttssssssssssssssssr"), (61, 16, "qrrrrrrrrrrrrrrrrrrrq"),
] + SLEEVES + LEGS + BOOTS
# ---- pass-2 chibi leather outfit, drawn directly in final coordinates ----
LEATHER2 = [
    (45, 19, "jklllllllllllkj"),
    (46, 17, "jklllllllllllllkkji"),
    (47, 16, "jkllllllkkkkkkkkkkjji"),
] + [(y, 17, "jk") for y in range(48, 54)] + [(y, 34, "ji") for y in range(48, 54)] + [
    (54, 17, "ijjjjjjjjjjjjjjjjii"), (55, 18, "iiiiiiiiiiiiiiiii"),
    (48, 20, "pppppomnnnnnn"),
    (49, 19, "ppppppomnnnnnnm"),
    (50, 19, "pppppoomnnnnnmm"),
    (51, 19, "oppppoomnnnnnmm"),
    (52, 19, "ooppooomnnnnmmm"),
    (53, 19, "noooooomnnnnmmm"),
    (54, 19, "nnooonnmmnnmmmm"),
    (55, 20, "mnnnnnmnnnmmm"),
    (45, 21, "st"), (46, 21, "st"), (47, 21, "rs"), (45, 30, "sr"), (46, 30, "rq"), (47, 30, "rq"),   # straps
    (56, 17, "sttsssssssssssssssr"), (57, 17, "qrrrrrrrrrrrrrrrrrq"),                              # belt
    # sleeves + cuffs
    (46, 14, "kl"), (47, 13, "jkll"), (48, 13, "jkkl"), (49, 13, "jkkk"), (50, 13, "ijkk"), (51, 13, "ijjk"),
    (52, 13, "rsss"), (53, 13, "qrrq"),
    (46, 37, "kj"), (47, 36, "kkji"), (48, 36, "kjji"), (49, 37, "kjji"), (50, 37, "jjji"), (51, 37, "sstr"),
    # trousers
    (58, 18, "wxxxxwwwuvvvvvvvu"), (59, 18, "vwxxwwwvuvvwvvvuu"), (60, 18, "vwwxwwwvuuvvvvuuu"),
    (61, 18, "vwxwwvu"), (61, 28, "vvwvvuu"), (62, 18, "vwwxwvu"), (62, 28, "vvvvvuu"),
    (63, 18, "vwwwvvu"), (63, 28, "uvwvvuu"), (64, 18, "uvwwvvu"), (64, 28, "uuvvuuu"),
    (65, 18, "uvvvvuu"),
    # boots (near/right leg one row higher: weight on the left leg)
    (66, 17, "BCDDDDCBA"), (67, 17, "ABCCDCBBA"), (68, 18, "BCCCBBA"), (69, 18, "BDCBBBA"), (70, 18, "BCCBBAA"),
    (71, 18, "BCBBBAA"), (72, 17, "ABCBBBBAA"), (73, 18, "AAAAAAA"),
    (65, 27, "BCCDCCBBA"), (66, 27, "ABBCCBBAA"), (67, 28, "BCBBBAA"), (68, 28, "BCBBBAA"), (69, 28, "BBBBAAA"),
    (70, 28, "BCBBAAA"), (71, 27, "ABBBBBAAA"), (72, 28, "AAAAAAA"),
]
POUCH2 = [(56, 30, "pooon"), (57, 30, "noPnm"), (58, 30, "nnnnm"), (59, 30, "nnnmm"), (60, 31, "mmm")]

POUCH = [(60, 31, "pooon"), (61, 31, "noPnm"), (62, 31, "nnnnm"), (63, 31, "nnnmm"), (64, 32, "mmm")]

CCODE = C.CCODE
CLOTH = [
    (45, 18, "nooopppppppooon"), (46, 17, "noppppppppppoonn"), (47, 17, "nooooommmmmooonm"),   # hood down
    (48, 16, "noooooomnnnmoooonnm"),
    (49, 16, "nooooooooomooonnnnnm"),
    (50, 15, "noooooooooomooonnnnnm"),
    (51, 15, "noooopooooomooonnnnnm"),
    (52, 15, "nooooooooooomoonnnnnm"),
    (53, 15, "nooooooooooomoonnnnnm"),
    (54, 15, "nooooooooooomonnnnnnm"),
    (55, 15, "nnoooooooooomonnnnnmm"),
    (56, 15, "nnoooooooooomonnnnnmm"),
    (57, 15, "nnnooooooooomnnnnnnmm"),
    (58, 16, "sttsssssssssssssssss"), (59, 16, "rrrrrrrrrrrrrrrrrrrr"),                   # rope belt
    (58, 30, "rs"), (59, 31, "rq"), (60, 31, "q"), (61, 32, "s"),
    (60, 15, "noooooooooomonnnnnnm"), (61, 15, "noooopoooooomnnnnnnm"),
    (62, 14, "nooooooooooomonnnnnnmm"), (63, 14, "nnooooooooooomnnnnnnmm"),
    (64, 14, "nnooooooooooomnnnnnnnm"), (65, 13, "nnnoooooooooomnnnnnnnmm"),
    (66, 13, "nnnoooooooooomnnnnnnnmm"), (67, 13, "mnnnoooooooonmnnnnnnmmm"),
    (68, 13, "mnnnnooooooonmnnnnnmmmm"), (69, 13, "mmnnnnnnnnnnmnnnnnmmmmm"),
    (70, 13, "QRRRSSSSRRRRRRRRRRRRRRQ"), (71, 13, "QQRRRRRRRRRRRRRRRRRRRQQ"),       # hem trim
    (72, 17, "uuuuuuuu"), (72, 29, "uuuuuuu"), (73, 17, "uuuuuuuu"),
    # wide sleeves
    (48, 13, "nop"), (49, 12, "nopp"), (50, 11, "noop"), (51, 11, "nooo"), (52, 11, "nooo"), (53, 10, "nnooo"),
    (54, 10, "nnnoo"), (55, 10, "mnnnn"), (56, 10, "mmnnm"), (57, 11, "mmm"),
    (58, 11, "rsst"), (59, 11, "qrrr"), (60, 11, "qqqq"),
    (48, 37, "pon"), (49, 37, "ponn"), (50, 38, "oonn"), (51, 38, "onnn"), (52, 38, "onnnm"), (53, 38, "nnnnm"),
    (54, 39, "nnnm"), (55, 39, "nnmm"), (56, 39, "sst"), (57, 39, "rrrq"),
] + BOOTS

PCODE = C.PCODE
PLATE = [
    (46, 20, "MNNNNNNNNNNM"), (47, 19, "NOPPPPOOONNNNM"),                                # gorget
    (48, 17, "NOPPPPPPPOONNNNNNM"), (49, 16, "NOPPPPPPOOONNNNNNNM"),
    (50, 16, "NOPPOOOOOOONNNNNNNM"), (51, 16, "NOOOOOOOOOONNNNNNNM"),
    (52, 16, "QRSSSSSRRRRRRRRRRRQ"), (53, 16, "QRRRRRRRRRRRRRRRRRQ"),                   # 2 px trim band
    (54, 16, "NOOOOOzzzzzzzzONNNM"), (55, 16, "NOOOOOOOOONNNNNNNNM"),                   # Epic chest band (Q)
    (56, 16, "MNOOOOOOONNNNNNNNMM"), (57, 17, "MNNOOOONNNNNNNMMM"), (58, 17, "MMNNNNNNNNNNMMMM"),
    # big round pauldrons
    (46, 11, "NOPO"), (47, 10, "NOPPON"), (48, 9, "NOPPPONM"), (49, 9, "NOPPOONM"), (50, 9, "MNOOONNM"),
    (51, 9, "QRSSRRQ"), (52, 9, "QRRRRRQ"), (53, 10, "MNNNM"),
    (46, 38, "OPON"), (47, 37, "NOPOON"), (48, 36, "NOPOONNM"), (49, 36, "NOOONNNM"), (50, 36, "MNOONNMM"),
    (51, 37, "QRSRRQQ"), (52, 37, "QRRRRRQ"), (53, 38, "MNNNM"),
    # arms
    (54, 11, "NOON"), (55, 11, "NOON"), (56, 11, "NOPN"), (57, 11, "MNNM"), (58, 11, "QRRQ"),
    (59, 11, "NOPN"), (60, 11, "MNON"), (61, 11, "MNNM"), (62, 11, "MNNM"), (63, 12, "MM"),           # left gauntlet
    (54, 38, "NOON"), (55, 38, "NOOM"), (56, 39, "NOOM"), (57, 39, "QRRQ"),
    # belt + faulds
    (59, 16, "qrrrrrrrhkgrrrrrrrq"), (60, 16, "qqqqqqqqhggqqqqqqqq"), (61, 16, "qqqqqqqqfffqqqqqqqq"),
    (62, 16, "NOPPONNOPPONNOOONNM"), (63, 16, "NOOONMNOOONMNOONNMM"), (64, 16, "MNNNMMMNNNMMMNNMMMM"),
    (65, 17, "QRRRQQRRRQQRRRRQQ"),
    (66, 17, "uvwvuvwvuvwvuvwvu"), (67, 17, "vwvuvwvuvwvuvwvuv"),
    (68, 17, "NOPPONMN"), (68, 29, "NOOONNM"),
    (69, 17, "NOPPONMN"), (69, 29, "NOOONNM"),
    (70, 18, "QRSRQ"), (70, 29, "QRSRRQ"),                                             # knee cops
    (71, 17, "NOPPONMN"), (71, 29, "NOPONNM"),
    (72, 17, "NOPOONNM"), (72, 29, "MNOONNM"),
    (73, 17, "MNOONNMM"),
] + BOOTS


def relayout(rows):
    """Chibi re-proportion of the outfit drafts: torso up 2 rows, trousers 2 rows shorter, boots up 4."""
    out = []
    legmap = {}
    ny = 60
    for y in range(62, 74):
        if y in (67, 69):
            continue
        legmap[y] = ny; ny += 1
    for y, x, t in rows:
        if y <= 61:
            out.append((y - 2, x, t))
        elif y <= 73 and not any(c in "ABCD" for c in t):
            if y in legmap:
                out.append((legmap[y], x, t))
        else:
            out.append((y - 4, x, t))
    return out


def sword_rows():
    dx, dy = HAND_SHIFT
    rows = []
    for y, x, t in C.sword():
        y2, x2 = y + dy, x + dx
        if y >= 64:                      # pommel: pulled up so the grip ends 3 px under the fist
            y2 -= 6
        elif 49 <= y <= 63 and y2 > 60:
            continue
        rows.append((y2, x2, t))
    return rows


def shift(rows, dx, dy):
    return [(y + dy, x + dx, t) for y, x, t in rows]


def build():
    S = D.save
    body = D.draw(D.blank(), BODY + FIST); S(body, "base_body")
    S(D.draw(D.blank(), FIST), "base_body_front")
    S(D.denoise(D.draw(D.blank(), HAIR_SHORT)), "hair_short")
    S(D.denoise(D.draw(D.blank(), long_rows())), "hair_long")
    S(D.draw(D.blank(), buzz_rows()), "hair_buzz")
    S(D.draw(D.blank(), tail_rows(), TCODE), "hair_tail")
    lo = D.draw(D.blank(), LEATHER2); D.draw(lo, POUCH2); S(lo, "outfit_leather")
    S(D.draw(D.blank(), relayout(CLOTH), CCODE), "outfit_cloth")
    S(D.draw(D.blank(), relayout(PLATE), PCODE), "outfit_plate")
    dx, dy = HAND_SHIFT
    S(D.draw(D.blank(), sword_rows(), C.WCODE), "w_sword")
    S(D.draw(D.blank(), [r for r in shift(C.staff(), dx, dy) if r[0] >= 0], C.WCODE), "w_staff")
    S(D.draw(D.blank(), [r for r in shift(C.bow(), dx, dy) if r[0] < 84], C.WCODE), "w_bow")
    S(D.draw(D.blank(), shift(C.shield(), 0, 8), C.WCODE), "w_shield")




# =========================================================== pass-2 customisation on the new base
def long2():
    """Mop on top, then three locks over the shirt/vest to the shoulder blades (lit left lock)."""
    rows = [r for r in HAIR_SHORT if r[0] <= 36]
    locks = [(13, 19, 52), (20, 31, 54), (32, 38, 51)]
    for y in range(37, 55):
        row, x0 = "", 13
        for x in range(13, 39):
            li = next(i for i, (a, b, e) in enumerate(locks) if a <= x <= b)
            a, b, end = locks[li]
            if y > end or (y >= end - 1 and x in (a, b)) or (y == end and x in (a + 1, b - 1)):
                row += "."; continue
            s = 1 if x in (a, b) else (3 if li < 2 else 2)
            if li == 0 and 39 <= y <= 44 and a < x < b - 1: s = 4
            if li == 1 and 42 <= y <= 46 and a + 2 < x < b - 3: s = 4
            if y >= end - 2 and s > 1: s -= 1
            if (x - a + (y // 4) % 2) % 4 == 3 and y % 5 != 0 and s > 1: s -= 1   # staggered strand breaks
            row += str(s)
        # split into segments
        i = 0
        while i < len(row):
            if row[i] == ".": i += 1; continue
            e = i
            while e < len(row) and row[e] != ".": e += 1
            rows.append((y, x0 + i, row[i:e])); i = e
    return rows


def tail2():
    """Mop swept back and tied at the nape; the tail hangs down the middle of the back."""
    rows = [r for r in HAIR_SHORT if r[0] <= 35]
    rows += [
        (36, 14, "1222221111111222221111"), (37, 15, "11222111111112221111"), (38, 17, "1111122222111111"),
        (39, 21, "qsstrq"), (40, 22, "qrrq"),
        (41, 22, "2343"), (42, 21, "234432"), (43, 21, "234432"), (44, 21, "233432"), (45, 21, "234332"),
        (46, 21, "233321"), (47, 21, "234321"), (48, 22, "23321"), (49, 22, "23221"), (50, 22, "2321"),
        (51, 23, "221"), (52, 23, "21"), (53, 24, "1"),
    ]
    return rows


BOOTS2 = [r for r in LEATHER2 if any(c in "ABCD" for c in r[2])]

CLOTH2 = [
    (44, 19, "nooppppppppoon"), (45, 17, "noppppppppppppoon"), (46, 16, "nooommmmmmmmmmoonm"),   # hood down
    (47, 16, "pppppoomnnnnnnnnnm"), (48, 16, "ppppooomnnnnnnnnmm"), (49, 16, "opppooomnnnnnnnnmm"),
    (50, 16, "oppoooomnnnnnnnmmm"), (51, 16, "ooooooomnnnnnnnmmm"), (52, 16, "ooooooomnnnnnnnmmm"),
    (53, 16, "noooooomnnnnnnmmmm"), (54, 16, "nnooooomnnnnnnmmmm"),
    (55, 16, "sttssssssssssssssss"), (56, 16, "qrrrrrrrrrrrrrrrrrq"), (55, 29, "st"), (56, 29, "rq"), (57, 30, "s"), (58, 30, "q"),
    (57, 16, "ooooooomnnnnnnnmm"), (58, 15, "pooooooomnnnnnnnmm"), (59, 15, "ooooooooomnnnnnnmm"),
    (60, 15, "ooooooooomnnnnnnmmm"), (61, 14, "nooooooooomnnnnnnmmm"), (62, 14, "noooooooommnnnnnmmmm"),
    (63, 14, "nnoooooommnnnnnnmmmm"), (64, 14, "QRRSSSSRRRRRRRRRRRRQ"), (65, 14, "QQRRRRRRRRRRRRRRRRQQ"),
    # wide sleeves + cuffs
    (46, 13, "op"), (47, 12, "nopp"), (48, 12, "noop"), (49, 12, "nooo"), (50, 11, "nnooo"), (51, 11, "nnnoo"),
    (52, 12, "rsst"), (53, 12, "qrrq"),
    (46, 37, "on"), (47, 36, "oonn"), (48, 36, "onnn"), (49, 36, "nnnm"), (50, 37, "nnnmm"), (51, 37, "sstr"),
] + [r for r in BOOTS2 if r[0] >= 66]

PLATE2 = [
    (44, 21, "MNNNNNNNNM"), (45, 19, "NOPPPPOOONNNNM"),                                            # gorget
    (46, 17, "NOPPPPPPOONNNNNNNM"), (47, 17, "NOPPPPPOOONNNNNNMM"), (48, 17, "NOPPOOOOONNNNNNNMM"),
    (49, 17, "QRSSSSRRRRRRRRRRRQ"), (50, 17, "QRRRRRRRRRRRRRRRRQ"),                                 # 2 px trim band
    (51, 17, "NOOOOzzzzzzzzONNNM"), (52, 17, "NOOOOOOOONNNNNNNMM"), (53, 17, "MNOOOOOONNNNNNNMMM"),
    (54, 17, "MNNOOOONNNNNNMMMMM"), (55, 18, "MMNNNNNNNNNMMMMM"),
    # round pauldrons
    (44, 13, "NOPO"), (45, 12, "NOPPON"), (46, 11, "NOPPPONM"), (47, 11, "NOPPOONM"), (48, 11, "MNOOONNM"),
    (49, 11, "QRSSRRQ"), (50, 12, "QRRRRQ"),
    (44, 36, "OPON"), (45, 35, "NOPOON"), (46, 34, "NOPOONNM"), (47, 34, "NOOONNNM"), (48, 34, "MNOONNMM"),
    (49, 35, "QRSRRQQ"), (50, 35, "QRRRRQ"),
    # vambraces + left gauntlet
    (51, 13, "NOON"), (52, 13, "QRRQ"), (53, 13, "NOPN"), (54, 13, "NOPN"), (55, 13, "MNNM"), (56, 14, "MM"),
    (51, 37, "NOOM"), (52, 38, "QRRQ"), (53, 38, "NOOM"),
    # belt, gem, faulds, mail, greaves
    (56, 17, "qrrrrrrhkgrrrrrrrq"), (57, 17, "qqqqqqqhggqqqqqqqq"),
    (58, 17, "NOPPONNOPPONNOONNM"), (59, 17, "MNNNMMMNNNMMMNNMMM"), (60, 18, "QRRRQQRRRQQRRRRQ"),
    (61, 18, "uvwvuvwvuvwvuvwvu"),
    (62, 18, "NOPPONM"), (62, 28, "NOONNMM"), (63, 18, "QRSRRQM"), (63, 28, "QRSRRQM"),
    (64, 18, "NOPONNM"), (64, 28, "MNONNMM"), (65, 18, "MNOONNM"),
] + BOOTS2


def build2():
    S = D.save
    S(D.denoise(D.draw(D.blank(), long2())), "hair_long")
    S(D.draw(D.blank(), tail2(), TCODE), "hair_tail")
    S(D.draw(D.blank(), CLOTH2, CCODE), "outfit_cloth")
    S(D.draw(D.blank(), PLATE2, PCODE), "outfit_plate")
    dx, dy = HAND_SHIFT
    S(D.draw(D.blank(), [r for r in shift(C.staff(), dx, dy) if 0 <= r[0] < 84], C.WCODE), "w_staff")
    S(D.draw(D.blank(), [r for r in shift(C.bow(), dx, dy - 2) if 0 <= r[0] < 84], C.WCODE), "w_bow")
    S(D.draw(D.blank(), shift(C.shield(), 0, 2), C.WCODE), "w_shield")


if __name__ == "__main__":
    build(); build2()
