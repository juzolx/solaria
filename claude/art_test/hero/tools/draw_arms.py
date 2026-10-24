"""Arm variants for the pass-2 chibi base (Juzo: "arms are a little weird").

Each variant is one arm layer drawn AFTER the outfit (so the renderer puts a dark inner line where the
arm overlaps the torso: shoulder -> sleeve -> forearm -> hand reads as one shape), plus its own fist
(over the weapon) and a weapon offset. Codes as draw_master: linen i-l, dark leather q-t, skin a-d,
sword-hand skin W-Z.
  A  relaxed: tapered puffed sleeves, sword arm bent at the elbow holding the blade out from the hip,
     off arm hanging loose
  B  on guard: sword arm raised to the side with the elbow out, off arm braced with a clenched fist
  C  rolled sleeves: short puffed sleeves to the elbow, bare chunky forearms, relaxed
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import draw_master as D
import draw_custom as C
import draw_v2 as V

ARMS = {
    "A": {
        "rows": [
            # off arm (lit side): round shoulder cap, sleeve tapers, cuff, relaxed hand
            (45, 15, "lki"), (46, 14, "lkki"), (47, 13, "lkkki"), (48, 13, "kkji"), (49, 13, "kjji"),
            (50, 13, "jji"), (51, 12, "stsr"), (52, 12, "rqqq"),
            (53, 12, "cdc"), (54, 11, "cddc"), (55, 11, "bccb"), (56, 12, "ab"),
            # sword arm: cap, upper arm angled out, elbow, cuff, forearm bending forward to the fist
            (45, 35, "ikl"), (46, 35, "ikkj"), (47, 35, "ikkjj"), (48, 36, "ikjj"), (49, 37, "kjji"),
            (50, 37, "jjii"), (51, 38, "stsr"), (52, 38, "rqqq"),
            (53, 39, "cddc"),
        ],
        "fist": [(54, 40, "YZZYX"), (55, 40, "XYYXW"), (56, 40, "WXXXW"), (57, 41, "WWW")],
        "weapon": (0, 0),
    },
    "B": {
        "rows": [
            # off arm braced: sleeve angled out, clenched fist held away from the hip
            (45, 15, "lki"), (46, 14, "lkki"), (47, 13, "lkkki"), (48, 12, "lkkji"), (49, 11, "kkjji"),
            (50, 11, "kjji"), (51, 10, "stsr"), (52, 10, "rqqq"),
            (53, 9, "cddc"), (54, 9, "bccb"), (55, 9, "abba"),
            # sword arm raised: upper arm out to the side, elbow out, forearm up to a fist at chest height
            (45, 35, "ikl"), (46, 35, "ikkjj"), (47, 36, "ikkjj"), (48, 37, "ikjjj"), (49, 38, "jjjii"),
            (49, 41, "sst"), (48, 41, "tsr"), (47, 42, "rqq"), (46, 42, "cdc"),
        ],
        "fist": [(42, 41, "YZZYX"), (43, 41, "XYYXW"), (44, 41, "WXXXW"), (45, 42, "WW")],
        "weapon": (1, -12),
    },
    "C": {
        "rows": [
            # short puffed sleeves to the elbow, bare forearms (chunky, tapered), relaxed hands
            (45, 15, "lki"), (46, 14, "lkki"), (47, 13, "lkkki"), (48, 13, "kkjji"), (49, 13, "jjii"),
            (50, 13, "ccb"), (51, 13, "dcb"), (52, 12, "cdcb"), (53, 12, "cdcb"), (54, 11, "cddc"), (55, 11, "bccb"),
            (56, 12, "ab"),
            (45, 35, "ikl"), (46, 35, "ikkj"), (47, 35, "ikkjj"), (48, 36, "iijjj"), (49, 37, "iijj"),
            (50, 38, "bcc"), (51, 38, "bcdc"), (52, 39, "bcdc"), (53, 39, "bcdc"),
        ],
        "fist": [(54, 40, "YZZYX"), (55, 40, "XYYXW"), (56, 40, "WXXXW"), (57, 41, "WWW")],
        "weapon": (0, 0),
    },
}


def strip_arms(name_in, name_out, xs_left=(9, 17), xs_right=(35, 46), y0=45, y1=58, keep_mats="VBTKH"):
    """Copy a layer and remove its arm pixels (sleeves, cuffs, hands) so a variant arm layer can go on top."""
    import hero
    g, s = hero.load(name_in)
    m = [list(r) for r in g]; sh = [list(r) for r in (s if s is not None else g)]
    for y in range(y0, y1 + 1):
        for x in range(hero.W):
            inL = xs_left[0] <= x <= xs_left[1] - 1 and x < 17
            inR = x >= xs_right[0] + 1
            if (inL or inR) and m[y][x] in "WBSFe":
                if m[y][x] == "B" and 56 <= y <= 57 and 17 <= x <= 35:
                    continue
                m[y][x] = "."; sh[y][x] = "."
    D.save((m, sh), name_out)


def build():
    strip_arms("outfit_leather", "outfit_leather_noarms")
    strip_arms("base_body", "base_body_noarms")
    for k, v in ARMS.items():
        D.save(D.draw(D.blank(), v["rows"]), "arms_" + k)
        D.save(D.draw(D.blank(), v["fist"]), "fist_" + k)
        dx, dy = v["weapon"]
        D.save(D.draw(D.blank(), [(y + dy, x + dx, t) for y, x, t in V.sword_rows() if 0 <= y + dy < 84],
                      C.WCODE), "w_sword_" + k)


if __name__ == "__main__":
    build()
