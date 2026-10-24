"""Customization layers for the battle (back three-quarter) hero, hand-pixelled on the base.

Every piece declares its own char -> (material, shade) map. Shared slot materials:
  R trim (rarity colour or plain metal), U grip band 1 (Rare+), Q grip band 2 (Epic+), J gem (Epic+),
  D wood, C robe cloth, M metal, B dark leather, H hair, S skin.
"""
import os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_master as D


def cm(**groups):
    """cm(M="MNOP", R="QRST") -> {'M': ('M','1'), 'N': ('M','2'), ...}"""
    out = {}
    for mat, chars in groups.items():
        for i, c in enumerate(chars):
            if c != "_":
                out[c] = (mat, str(i + 1))
    return out


# =====================================================================================
# WEAPONS
# =====================================================================================
WCODE = cm(M="MNOP", R="QRST", U="_uv_", Q="_yz_", J="fghk", D="EFKL", G="GHIJ", B="abcd")


def sword():
    """Blade leans up-right toward the monster (~17 deg); grip follows the same line through the fist."""
    rows = []
    tip, base = (56.5, 4), (45.0, 45)
    k = (tip[0] - base[0]) / (base[1] - tip[1])
    for y in range(int(tip[1]), 46):
        cx = base[0] + (45 - y) * k
        w = 1 if y < tip[1] + 2 else (2 if y < 14 else 3)
        x0 = int(round(cx - (w - 1) / 2))
        rows.append((y, x0, {1: "P", 2: "PN", 3: "PON"}[w]))
    rows += [(46, 39, "SSTTkhTTSR"), (47, 38, "QRRRhgRRRQ")]
    for y in range(48, 64):
        gx = int(round(base[0] - 1 - (y - 45) * k))
        if y == 48:
            rows.append((y, gx, "NOM")); continue
        c = "IH" if y % 2 else "HG"
        if y in (56, 57): c = "uu" if y == 56 else "vu"
        if y in (59, 60): c = "yy" if y == 59 else "zy"
        rows.append((y, gx, c))
    gx = int(round(base[0] - 1 - (64 - 45) * k))
    rows += [(64, gx - 1, "STSR"), (65, gx - 1, "RSRQ"), (66, gx, "RQ")]
    return rows


def staff():
    rows = []
    for y in range(14, 68):                        # shaft, slight lean like the sword
        x = 42 if y < 40 else 41
        rows.append((y, x, "KF" if (y // 3) % 2 else "LF"))
    rows += [(66, 40, "EFFE"[:0] + "RSR"), (67, 41, "RQ")]       # iron ferrule
    rows += [(40, 41, "SR"), (41, 41, "TR"), (24, 41, "uv"), (25, 41, "uv"), (28, 41, "yz"), (29, 41, "yz")]
    head = [                                       # forked head holding a crystal
        (3, 41, "LF"), (3, 47, "FE"),
        (4, 40, "LF"), (4, 47, "KE"),
        (5, 40, "KF"), (5, 44, "kh"), (5, 47, "FE"),
        (6, 40, "KE"), (6, 43, "khhg"), (6, 47, "FE"),
        (7, 40, "LF"), (7, 42, "khhgg"), (7, 47, "E"),
        (8, 41, "LkhggfF"),
        (9, 41, "KFhgfFE"),
        (10, 41, "LKFfFE"),
        (11, 41, "KLFFE"),
        (12, 41, "STSR"), (13, 41, "RSQ"),
    ]
    return rows + head


def bow():
    rows = []
    top, bot = 30, 74
    for y in range(top, bot + 1):
        t = (y - top) / (bot - top)
        x = 40 + int(round(6.5 * math.sin(math.pi * t)))
        if y in (top, bot):
            rows.append((y, x, "RS"))
        else:
            rows.append((y, x, "LF" if t < 0.5 else "KF"))
        if top + 1 < y < bot - 1:
            rows.append((y, 39, "P" if y < 52 else "O"))     # string
    rows += [(49, 44, "uv"), (50, 44, "uv"), (55, 44, "yz"), (56, 44, "yz"), (52, 45, "g")]
    rows += [(46, 44, "SR"), (58, 44, "RQ")]
    for i in range(14):                                   # arrow nocked on the string at the hand row
        rows.append((55 - i, 38 + i, "F" if i % 2 else "K"))
    rows += [(41, 52, "P"), (42, 51, "ON"), (40, 52, "N"), (56, 37, "TS")]   # head + fletching
    return rows


def shield():
    """Heater shield on the far (left) arm, seen from behind: vertical planks, two straps, rarity rim.
    Drawn at x 0-14 and placed 9 px to the left of the hero (render tuple ("w_shield", -9))."""
    half = {40: 5, 41: 6, 42: 7, 43: 7}
    rows = []
    for y in range(40, 66):
        if y < 44:
            w = half[y]
        elif y < 54:
            w = 7
        else:
            w = max(1, 7 - (y - 53) * 7 // 12)
        a, b = 7 - w, 7 + w
        row = ""
        for x in range(a, b + 1):
            if x in (a, b) or y == 40 or (y == 41 and (x < a + 2 or x > b - 2)):
                row += "T" if (x == a or y <= 41) and y < 58 else ("S" if x == a else "R")
                continue
            if x in (a + 1, b - 1) or y == 41:
                row += "Q" if x == b - 1 else "R"
                continue
            k = (x - 1) % 4
            sh = "L" if k == 0 else ("K" if k in (1, 2) else "E")
            if x > 9 and sh == "L":
                sh = "K"
            if y > 58 and sh != "E":
                sh = "F"
            row += sh
        rows.append((y, a, row))
    rows += [(46, 2, "bccccccccccb"), (47, 2, "abbbbbbbbbba"), (55, 3, "bcccccccccb"), (56, 3, "abbbbbbbbba")]
    rows += [(51, 6, "gh"), (52, 6, "fg")]
    return rows


# =====================================================================================
# HAIR (battle back view). Digits = hair shades.
# =====================================================================================
HCODE = cm(H="1234", S="abcd")
SHORT_TOP = [r for r in D.HEAD if r[0] <= 30]


def hair_rows_only(rows):
    return [(y, x, "".join(c if c.isdigit() else "." for c in t)) for y, x, t in rows]


def hair_long():
    rows = hair_rows_only(SHORT_TOP)
    # strands falling over the ear and down the back to the shoulder blades
    spans = {31: (6, 19), 32: (6, 19), 33: (6, 18), 34: (6, 18), 35: (6, 18), 36: (6, 19), 37: (6, 20), 38: (6, 21),
             39: (6, 21), 40: (5, 21), 41: (5, 21), 42: (5, 21), 43: (5, 21), 44: (5, 20), 45: (5, 20), 46: (5, 20),
             47: (5, 19), 48: (6, 18)}
    # three overlapping locks of different widths (5, 4, 6 px) with 1 px partings; only the lit
    # (left) lock gets a highlight; each lock ends in a 2 px step
    locks = [(5, 9, 47), (10, 13, 49), (14, 21, 46)]   # (x0, x1, last row)
    for y, (a, b) in spans.items():
        row = ""
        for x in range(a, b + 1):
            li = next((i for i, (l0, l1, e) in enumerate(locks) if l0 <= x <= l1), 2)
            l0, l1, end = locks[li]
            if y > end or (y >= end - 2 and x in (l0, l1)) or (y == end and x in (l0 + 1, l1 - 1)):
                row += "."; continue
            s_ = 3 if li < 2 else 2
            if x == l0 and li > 0: s_ = 1                       # parting line
            if x == l1: s_ = max(1, s_ - 1)
            if li == 0 and 36 <= y <= 41 and l0 < x < l1: s_ = 4  # sheen on the lit lock
            if y >= end - 2: s_ = max(1, s_ - 1)
            if l1 - l0 >= 4 and x == l0 + 2 + (y // 6) % 2 and y >= 34 and y % 5 != 0:
                s_ = max(1, s_ - 1)                              # broken inner strand line
            row += str(s_)
        rows.append((y, a, row))
    rows += [(48, 10, "1221"), (49, 11, "11"), (47, 15, "1221."), (48, 16, "11")]
    return rows


def hair_buzz():
    """Close crop that follows the skull: the ear, temple and nape show."""
    return [
        (20, 11, "23344443332"),
        (21, 9, "233444433333322"),
        (22, 8, "23344333333333222"),
        (23, 7, "2334333333333332222"),
        (24, 7, "2333333333333332221"),
        (25, 6, "22333333333333322221"),
        (26, 6, "22333333333333222211"),
        (27, 6, "22233333333332222211"),
        (28, 7, "222333333322221"),
        (29, 7, "222233333222211"),
        (30, 7, "22222333222211"),
        (31, 8, "1222221"),
        (32, 8, "1122211"),
        (33, 9, "112211"),
        (34, 10, "11211"),
    ]


def hair_tail():
    """Swept back and tied: a tail hangs down the back."""
    rows = [
        (18, 12, "33"),
        (19, 10, "2344443332"),
        (20, 9, "234444333322"),
        (21, 8, "23444433333322"),
        (22, 7, "2344433333333222"),
        (23, 6, "233443333333332222"),
        (24, 6, "2334333333333322221"),
        (25, 5, "2233333333333332222"),
        (26, 5, "22333333333333222211"),
        (27, 5, "2223333333332222211"),
        (28, 6, "222333333222221"),
        (29, 6, "222233322222211"),
        (30, 6, "11222222222211"),
        (31, 7, "1122222211"),
        (32, 8, "112BB21"),            # tie (B = leather band)
        (33, 9, "1BBB1"),
        (34, 9, "23332"), (35, 8, "233432"), (36, 8, "2334321"), (37, 8, "2333321"), (38, 8, "2343221"),
        (39, 8, "2333221"), (40, 8, "2232221"), (41, 8, "223221"), (42, 8, "22321"), (43, 8, "2221"),
        (44, 8, "221"), (45, 8, "21"), (46, 9, "1"),
    ]
    return rows


TCODE = cm(H="1234", B="_B__")
TCODE["B"] = ("B", "3")

# =====================================================================================
# OUTFITS
# =====================================================================================
# cloth: hooded travelling robe (hood down on the shoulders), rope belt, robe to the shins
CCODE = cm(C="mnop", W="ijkl", B="qrst", R="QRST", K="ABCD", T="uvwx")
CLOTH = [
    (38, 10, "nooopppooon"),                                   # hood rolled on the shoulders
    (39, 8, "noppppppppoon"), (40, 7, "nopppoooopponm"),
    (41, 6, "nooooommmmooonnm"), (42, 6, "noooomnnnmooonnm"),
    (43, 6, "noooooooooooonnm"), (43, 22, "nnn"),
    (44, 5, "noooooooooonnnnm"), (44, 21, "onnnm"),
    (45, 5, "nooooooooomnnnnm"), (45, 21, "ooonnm"),
    (46, 5, "nooooooooomnnnnm"), (46, 21, "oooonnm"),
    (47, 5, "nooooopooomnnnnm"), (47, 21, "ooooonnm"),
    (48, 4, "noooooooooomnnnnm"), (48, 21, "nooooonnm"),
    (49, 4, "nnoooooooommnnnnm"), (49, 22, "nnoooonnm"),
    (50, 4, "nnoooooooomnnnnnm"), (50, 23, "nnnooonm"), (50, 32, "sssttss"),
    (51, 4, "mnnooooooomnnnnnm"), (51, 25, "mnnnm"), (51, 32, "rrqrrqr"),
    (52, 4, "mnnnooooonmnnnnmm"), (52, 26, "mmm"), (52, 32, "rrqrrqr"),
    (53, 5, "nnnnoooonmnnnnnm"), (53, 32, "qqqqqqq"),
    (54, 5, "nnnnoooonmnnnnmm"),
    (55, 5, "sttsssssssssssssss"), (56, 5, "rrrrrrrrrrrrrrrrrr"),   # rope belt
    (57, 6, "nooooooonmnnnnnnm"), (57, 19, "rs"), (58, 19, "rq"), (59, 20, "q"),
    (58, 5, "noooooooonmnnnnnnm"), (59, 5, "nooooooooonmnnnnnm"),
    (60, 4, "noooooooooonmnnnnnm"), (61, 4, "noooopooooonmnnnnnm"),
    (62, 4, "nnooooooooonmnnnnnnm"), (63, 4, "nnoooooooonnmnnnnnnm"),
    (64, 3, "nnnooooooonnmnnnnnnnm"), (65, 3, "nnnoooooonnnmnnnnnnnm"),
    (66, 3, "mnnnooooonnnmnnnnnnmm"), (67, 3, "mnnnnoooonnnmnnnnnmmm"),
    (68, 3, "QRRRSSSSRRRRRRRRRRRRQ"), (69, 3, "QQRRRRRRRRRRRRRRRRRQQ"),  # hem trim band
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
    # sleeve hangs wide on the sword arm, far sleeve on the left
    (46, 3, "op"), (47, 2, "nop"), (48, 2, "noo"), (49, 2, "nno"), (50, 2, "mnn"),
]

# plate: back plate, round pauldrons, faulds, greaves; gauntlets (the sword hand turns steel)
PCODE = cm(M="MNOP", R="QRST", B="qrst", T="uvwx", K="ABCD", W="ijkl", J="fghk", Q="_yz_")
PCODE["z"] = ("Q", "3")
PLATE = [
    (39, 12, "MNNNNNM"),                                        # gorget
    (40, 9, "NOPPPOOONNNM"), (41, 8, "NOPPPPOOONNNNM"),
    (42, 7, "NOPPOOOOONNNNNM"), (43, 7, "NOOOOOOOONNNNNM"),
    (44, 7, "zzzzzzzzzzzzzzz"), (45, 7, "NOOOOOOOONNNNNM"),
    (46, 7, "QRRRRRRRRRRRRRQ"), (47, 7, "QRSSSSSRRRRRRRQ"),    # 2 px trim band across the back
    (48, 7, "NOOOOOOOONNNNNM"), (49, 7, "NOOOOOOONNNNNMM"),
    (50, 7, "MNOOOOOONNNNNMM"), (51, 7, "MNNOOOONNNNNMMM"),
    (52, 7, "MMNNNNNNNNNMMMM"),
    # pauldrons
    (40, 3, "NOPO"), (41, 2, "NOPPON"), (42, 2, "NOPPOON"), (43, 2, "NOOPOON"), (44, 2, "MNOOONM"),
    (44, 2, "QRSSRQ"), (45, 2, "QRSSRQ"), (46, 3, "MNNM"),
    (41, 20, "OPPO"), (42, 19, "NOPPPON"), (43, 19, "NOPPOOON"), (44, 20, "QRSSRRQ"), (45, 20, "QRSSRRQ"),
    (46, 21, "MNNM"),
    # arm: rerebrace + vambrace over the sleeve
    (47, 22, "NOON"), (48, 22, "NOPON"), (49, 23, "NOOONM"), (50, 24, "NOOONNM"), (51, 26, "MNNNM"),
    (51, 31, "NOPPPON"), (50, 31, "OPPPPO"), (52, 31, "MNNNNNM"), (53, 32, "QRRRRQ"),
    (51, 28, "NOM"), (52, 27, "MNNM"), (53, 27, "MMM"),
    (47, 2, "NOO"), (48, 2, "NOO"), (49, 2, "MNO"), (50, 2, "MNN"), (51, 2, "QRRR"),   # far vambrace
    (52, 2, "NOPPN"), (53, 2, "MNOON"), (54, 3, "MNNM"), (55, 4, "MM"),              # far gauntlet
    # belt + faulds
    (53, 6, "qrrrrrrrhkgrrrrrrq"), (54, 6, "qqqqqqqhggqqqqqqqq"), (55, 13, "gff"),
    (55, 6, "NOPPONNOPPONNOOONM"), (56, 6, "NOOONMNOOONMNOONNM"), (57, 6, "MNNNMMMNNNMMMNNMMM"),
    (58, 7, "QRRRQQRRRQQRRRRQ"),
    # mail skirt / cuisses
    (59, 7, "uvwvuvwvuvwvuvwvu"), (60, 7, "vwvuvwvuvwvuvwvuv"), (61, 7, "uvuvuvuvuvuvuvuvu"),
    (62, 7, "NOPPONMN"), (62, 17, "NOOONNM"),
    (63, 7, "NOPPONMN"), (63, 17, "NOOONNMM"),
    (64, 7, "MNOONNM"), (64, 17, "NOOONNM"),
    (65, 8, "QRSRQ"), (65, 17, "QRSRRQ"),                         # knee cops
    (66, 7, "NOPPONM"), (66, 17, "NOPPONM"),
    (67, 7, "NOPOONM"), (67, 18, "NOPOONM"),
    (68, 6, "NOPOONNM"), (68, 18, "NOOONNM"),
    (69, 6, "NOOOONNM"), (69, 18, "NOOONNMM"),
    (70, 6, "MNOONNMM"), (70, 18, "MNOONNMM"),
    (71, 5, "BCDDDCCCBA"), (71, 17, "BCDDDCCCBA"),                 # leather sabatons keep the legs readable
    (72, 5, "ABCCCBBBBA"), (72, 17, "ABCCCBBBBA"),
    (73, 6, "BCCBBBBA"), (73, 18, "BCCBBBBA"),
    (74, 6, "BCCBBBBA"), (74, 18, "BCCBBBBA"),
    (75, 6, "BCBBBBBA"), (75, 18, "BCBBBBBA"),
    (76, 6, "BCBBBBAA"), (76, 18, "BCBBBBBAA"),
    (77, 6, "BCBBBBAA"), (77, 18, "BCBBBBBBAA"),
    (78, 5, "BCCBBBBAA"), (78, 18, "BCCBBBCCBAA"),
    (79, 5, "ABBBBBBAA"), (79, 18, "ABBBBBBBBAA"),
    (80, 6, "AAAAAAA"), (80, 19, "AAAAAAAAA"),
    (53, 12, "fhkf"), (54, 12, "fhgf"), (55, 12, "ffff"),          # 3x3 belt gem (steel stud unless Epic+)
]


def step_back(layer, x0=17, y0=64, dy=2):
    """Contrapposto: the near (right) leg steps back - its pixels from y0 down move up by dy rows."""
    m, s = layer
    for y in range(y0, len(m)):
        for x in range(x0, len(m[0])):
            if y + dy < len(m):
                m[y][x], s[y][x] = m[y + dy][x], s[y + dy][x]
            else:
                m[y][x], s[y][x] = ".", "."
    return layer


def build():
    S = D.save
    S(D.draw(D.blank(), sword(), WCODE), "w_sword")
    S(D.draw(D.blank(), staff(), WCODE), "w_staff")
    S(D.draw(D.blank(), bow(), WCODE), "w_bow")
    S(D.draw(D.blank(), shield(), WCODE), "w_shield")
    S(D.denoise(D.draw(D.blank(), hair_rows_only(D.HEAD))), "hair_short")
    S(D.denoise(D.draw(D.blank(), hair_long(), HCODE)), "hair_long")
    S(D.draw(D.blank(), hair_buzz(), HCODE), "hair_buzz")
    S(D.draw(D.blank(), hair_tail(), TCODE), "hair_tail")
    S(step_back(D.draw(D.blank(), CLOTH, CCODE), y0=70), "outfit_cloth")
    S(step_back(D.draw(D.blank(), PLATE, PCODE)), "outfit_plate")
    lo = D.draw(D.blank(), D.LEATHER); D.draw(lo, D.POUCH); S(step_back(lo), "outfit_leather")


if __name__ == "__main__":
    D.build()
    build()
