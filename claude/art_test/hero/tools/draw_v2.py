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
    (33, 12, "c"), (34, 11, "cc"), (35, 11, "dc"), (36, 11, "cb"), (37, 12, "b"),
    (33, 39, "b"), (34, 39, "bb"), (35, 39, "ba"), (36, 39, "ba"), (37, 39, "a"),
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
    skull = {y: (x0, x0 + len(t) - 1) for y, x0, t in BODY if 27 <= y <= 43 and set(t) <= set("abcd") and len(t) > 6}
    for y in range(26, 42):
        if y not in skull and y > 27:
            continue
        a, b = skull.get(y, (21, 27) if y == 26 else (19, 32))
        if y >= 39:          # nape: skin shows below a soft hairline
            a, b = a + 2, b - 2
        n = b - a + 1
        row = ""
        for i in range(n):
            x = a + i
            t = (x - a) / max(1, n - 1)
            s = 3
            if y <= 31 and t < 0.55: s = 4
            if t > 0.7: s = 2
            if t > 0.9 or i == 0: s = max(1, s - 1)
            if y >= 37: s = min(s, 2)
            if y >= 40: s = 1
            row += str(s)
        rows.append((y, a, row))
    rows.append((25, 22, "33.3"))
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


if __name__ == "__main__":
    build()
