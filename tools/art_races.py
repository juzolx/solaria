"""Race features for the hero, drawn in hero coordinates (32x32).
"front" layers go over the hair, "back" layers go behind the body."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

MANUAL = True
MATS = {
    's': ['#fbe6cf', '#f2cfae', '#e8b796', '#c28569', '#733e39'],      # skin (recolored)
    'n': ['#fbf3dc', '#ead4aa', '#c8b08a', '#8b6d4f', '#3e2731'],      # horn
    'v': ['#f6757a', '#e43b44', '#a22633', '#68386c', '#3e2731'],      # demon tail
    'y': ['#fff4a3', '#fee761', '#feae34', '#f77622', '#be4a2f'],      # halo
    'a': ['#ffffff', '#f4f4f4', '#dfe6f0', '#b4c0d4', '#7d8aa6'],      # angel feathers
    'f': ['#ffffff', '#d9f6fa', '#a4dddb', '#73bed3', '#4f8fba'],      # fairy wing
    'q': ['#ffe3f0', '#ffc6de', '#f6a6c8', '#d47aa8', '#9a4a78'],      # fairy wing tint
    'h': ['#00ff00', '#00f000', '#00e100', '#00d200', '#00c300'],      # hair (recolored; make_art swaps in the keys)
    'p': ['#ffd6e4', '#f6a6c8', '#e47aa0', '#b8506e', '#6b2a3e'],      # inner ear
    'd': ['#ffd2a0', '#f7a24a', '#d9661f', '#9a3a1c', '#4e1c14'],      # dragon scale
    'w': ['#ffd2a0', '#e4705a', '#a83a3a', '#6b1f2e', '#3a1020'],      # dragon wing membrane
    'g': ['#ffffff', '#c8f8ff', '#7fe9ff', '#3fb8e0', '#1d6a96'],      # golem rune glow
    'x': ['#5a4a5a', '#4a3a4a', '#3a2a3a', '#2a1d2a', '#181425'],      # stitches
    'm': ['#e4e8ee', '#b4bccc', '#8b95a8', '#5a6380', '#343a52'],      # wolf fur
    'k': ['#8b8fa8', '#5a5e78', '#3a3c52', '#262838', '#121220'],      # black feathers
    'c': ['#fff4a3', '#fee761', '#feae34', '#d9661f', '#8a3a1c'],      # crown gold
    'r': ['#ff9aa8', '#ff4d6a', '#d4203e', '#8a1028', '#4a0a18'],      # crown gem / blood
    'b': ['#e4e8ee', '#b4bccc', '#8b95a8', '#5a6380', '#343a52'],      # dark iron (lich crown, broken halo)
}
ALIASES = {'H': ('h', 3), 'P': ('p', 3), 'D': ('d', 3), 'W': ('w', 3), 'G': ('g', 3), 'M': ('m', 3), 'K': ('k', 3),
           'C': ('c', 3), 'R': ('r', 3), 'B': ('b', 3), '!': ('g', 0), '=': ('c', 0), 'X': ('x', 3),
           '1': ('s', 1), 'S': ('s', 3), 'N': ('n', 3), '*': ('n', 0), 'V': ('v', 3), '^': ('v', 1),
           'Y': ('y', 3), '+': ('y', 0), 'A': ('a', 3), '~': ('a', 0), 'F': ('f', 3), '-': ('f', 0), 'Q': ('q', 3)}

#            0         1         2         3
#            01234567890123456789012345678901
EARS = [
    "................................",  # 0
    "................................",  # 1
    "................................",  # 2
    "......1.........................",  # 3
    "......11........................",  # 4
    ".......1ss......................",  # 5
    ".......1sssS....................",  # 6
    "........sssSS...................",  # 7
    ".........ssSS...................",  # 8
    "..........SS....................",  # 9
]
HORNS = [
    "...........*......*.............",  # 0
    "...........n*....*nN............",  # 1
    "............nN...nNN............",  # 2
    "............NN...NN.............",  # 3
]
HALO = [
    "............+yyyyyY.............",  # 0
    ".............YYYYY..............",  # 1
]
TAIL = ["................................"] * 19 + [
    "..........vV....................",  # 19
    ".........vV.....................",  # 20
    "........vV......................",  # 21
    ".......vV.......................",  # 22
    "......vV........................",  # 23
    ".....vV.........................",  # 24
    "...^vvV.........................",  # 25
    "..^vvvvV........................",  # 26
    "...VVVV.........................",  # 27
]
FAIRY_WINGS = ["................................"] * 8 + [
    "......-ff.......................",  # 8
    "....-ffqqf......................",  # 9
    "...-fqqqqfF.....................",  # 10
    "...-fqqqffFF....................",  # 11
    "....ffffFFF.....................",  # 12
    "......FFF.......................",  # 13
    "......-fF.......................",  # 14
    ".....-fqqF......................",  # 15
    ".....fqqfF......................",  # 16
    "......fFF.......................",  # 17
]
ANGEL_WINGS = ["................................"] * 6 + [
    "........~~~.....................",  # 6
    "......~~aaa~....................",  # 7
    ".....~aaaaaaa...................",  # 8
    "....~aaAAaaaaa..................",  # 9
    "...~aaAaaAAaaa..................",  # 10
    "...~aAaaAaaAaa..................",  # 11
    "..~aAa~aAaaAaa..................",  # 12
    "..~Aa~aAa~aAaa..................",  # 13
    ".~aA~aAa~aAaaA..................",  # 14
    ".~A~aAa~aAaaA...................",  # 15
    ".~A~aA~aAaaA....................",  # 16
    "..A~aA~aAaA.....................",  # 17
    "..A.~A~aAA......................",  # 18
    "....A.~AA.......................",  # 19
    "......A.........................",  # 20
]



def layer(spec, top=0):
    """spec: list of (y, x, pattern) -> 32x32 rows. '.' in a pattern is skipped."""
    g = [['.'] * 32 for _ in range(32)]
    for y, x, pat in spec:
        for i, ch in enumerate(pat):
            if ch != '.' and 0 <= x + i < 32:
                g[y][x + i] = ch
    return [''.join(r) for r in g]


# Dwarf: a big braided beard (hair colored)
BEARD = layer([
    (9, 16, "h....h"),
    (10, 15, "hhh.hhh"),
    (11, 14, "hhhhhhhH"),
    (12, 14, "hhhhhhHH"),
    (13, 14, "hhhhhHHH"),
    (14, 15, "HhhhHH"),
    (15, 15, "HhhHH"),
    (16, 16, "HhH"),
    (17, 16, "H.H"),
])
# Beastkin: furry ears on top (hair colored) and a bushy tail
BEAST_EARS = layer([
    (0, 11, "h......h"),
    (1, 10, "hhH....hhH"),
    (2, 10, "hphH..hhpH"),
    (3, 10, "hppH..hppH"),
])
BEAST_TAIL = layer([
    (17, 9, "hh"),
    (18, 7, "hhhH"),
    (19, 5, "hhhhHH"),
    (20, 4, "hhhhhH"),
    (21, 3, "hhhhHH"),
    (22, 3, "hhhHH"),
    (23, 4, "HHH"),
])
# Dragonkin: swept-back horns, scales on the cheek, a heavy tail, and wings (awakened)
DRAGON_HORNS = layer([
    (1, 9, "dd"),
    (2, 8, "dDdd"),
    (3, 7, "dD.Ddd"),
    (4, 6, "D....Dd"),
    (0, 10, "d"),
])
DRAGON_SCALES = layer([
    (8, 12, "d.d"),
    (9, 13, "dD"),
])
DRAGON_TAIL = layer([
    (19, 9, "dD"),
    (20, 7, "ddD"),
    (21, 5, "dddD"),
    (22, 3, "ddddD"),
    (23, 2, "dDDD"),
    (24, 1, "DD"),
])
DRAGON_WINGS = layer([
    (5, 4, "d"),
    (6, 3, "dDd"),
    (7, 2, "dwwD"),
    (8, 1, "dwwwwD"),
    (9, 1, "DwwwwwD"),
    (10, 0, "dwwwwwwD"),
    (11, 0, "DwWwWwwD"),
    (12, 1, "D.WD.WD"),
    (13, 1, "D..D..D"),
])
# Orc: tusks
TUSKS = layer([
    (9, 21, "*"),
    (10, 21, "n"),
    (9, 17, "*"),
    (10, 17, "n"),
])
# Goblin: long, droopy ears
GOBLIN_EARS = layer([
    (3, 1, "1"),
    (4, 1, "11s"),
    (5, 2, "1sssS"),
    (6, 3, "sspsSS"),
    (7, 5, "ssppSS"),
    (8, 7, "SSSSS"),
])
# Golem: glowing rune cracks and a core
GOLEM_RUNES = layer([
    (3, 13, "g"),
    (4, 13, "!"),
    (5, 14, "g"),
    (6, 14, "G"),
    (9, 11, "g"),
    (10, 12, "G"),
    (15, 16, "!g"),
    (16, 16, "gG"),
])
# Undead: stitches and a patch of bone
STITCHES = layer([
    (9, 12, "X.X"),
    (10, 12, "XXX"),
    (11, 12, "X.X"),
])
# Vampire: fangs
FANGS = layer([
    (10, 18, "*.*"),
    (11, 18, "*"),
])
# Werewolf: grey fur ears, tail and cheek tufts
WOLF_EARS = layer([
    (0, 11, "m......m"),
    (1, 10, "mmM....mmM"),
    (2, 10, "mpmM..mmpM"),
    (3, 11, "mM...mmM"),
    (9, 9, "mm"),
    (10, 9, "mM"),
])
WOLF_TAIL = layer([
    (17, 9, "mm"),
    (18, 6, "mmmM"),
    (19, 4, "mmmmMM"),
    (20, 3, "mmmmmM"),
    (21, 2, "mmmmMM"),
    (22, 2, "MmMM"),
])
# Fallen Angel: black wings and a cracked, dark halo
FALLEN_WINGS = [r.replace('a', 'k').replace('A', 'K').replace('~', 'k') for r in ANGEL_WINGS]
BROKEN_HALO = layer([
    (0, 12, "rrr.rR"),
    (1, 13, "RR..R"),
])
# Lich: an iron crown with a glowing gem
LICH_CROWN = layer([
    (0, 12, "b.b.b.b"),
    (1, 12, "bbbgbbB"),
    (2, 12, "BBBBBBB"),
])
# Angel awakening: more pairs of wings
WINGS2 = layer([
    (11, 6, "~~a"),
    (12, 4, "~aaaa"),
    (13, 3, "~aAaaa"),
    (14, 2, "~aAaAa"),
    (15, 2, "~AaAa"),
    (16, 2, "A~Aa"),
    (17, 3, "A.A"),
])
WINGS3 = layer([
    (2, 8, "~~"),
    (3, 6, "~aaa"),
    (4, 5, "~aAaa"),
    (5, 4, "~aAa"),
    (6, 4, "~A"),
])
# Demon awakening: great horns and a crown
HORNS_BIG = layer([
    (0, 10, "*.......*"),
    (1, 10, "nn......*n"),
    (2, 11, "nN....nN"),
    (3, 12, "NN...NN"),
])
CROWN = layer([
    (0, 12, "c.c.c.c"),
    (1, 12, "cccrccC"),
    (2, 12, "CCCCCCC"),
])
# Fairy awakening: bigger wings
WINGS_BIG = layer([
    (5, 7, "-f"),
    (6, 5, "-ffq"),
    (7, 3, "-ffqqf"),
    (8, 2, "-fqqqqf"),
    (9, 1, "-fqqqqfF"),
    (10, 1, "-fqqqffF"),
    (11, 2, "ffffFFF"),
    (12, 4, "FFFF"),
    (13, 5, "-ff"),
    (14, 4, "-fqqF"),
    (15, 3, "-fqqqF"),
    (16, 3, "fqqfF"),
    (17, 4, "fFF"),
])

# Every layer: name -> rows (saved as art/hero/race_<name>.png)
LAYERS = {
    "ears": EARS, "horns": HORNS, "halo": HALO, "tail": TAIL, "wings_fairy": FAIRY_WINGS, "wings_angel": ANGEL_WINGS,
    "beard": BEARD, "beast_ears": BEAST_EARS, "beast_tail": BEAST_TAIL, "dragon_horns": DRAGON_HORNS,
    "dragon_scales": DRAGON_SCALES, "dragon_tail": DRAGON_TAIL, "dragon_wings": DRAGON_WINGS, "tusks": TUSKS,
    "goblin_ears": GOBLIN_EARS, "golem_runes": GOLEM_RUNES, "stitches": STITCHES, "fangs": FANGS,
    "wolf_ears": WOLF_EARS, "wolf_tail": WOLF_TAIL, "fallen_wings": FALLEN_WINGS, "broken_halo": BROKEN_HALO,
    "lich_crown": LICH_CROWN, "wings2": WINGS2, "wings3": WINGS3, "horns_big": HORNS_BIG, "crown": CROWN,
    "wings_big": WINGS_BIG,
}
BACK = {"tail", "wings_fairy", "wings_angel", "beast_tail", "dragon_tail", "dragon_wings", "wolf_tail",
        "fallen_wings", "wings2", "wings3", "wings_big"}

# race -> (back layers, front layers). "ears" is drawn under the helmet, the rest over it.
RACES = {
    "Human": ([], []),
    "Elf": ([], ["ears"]),
    "Fairy": (["wings_fairy"], ["ears"]),
    "Angel": (["wings_angel"], ["halo"]),
    "Demon": (["tail"], ["horns"]),
    "Dwarf": ([], ["beard"]),
    "Beastkin": (["beast_tail"], ["beast_ears"]),
    "Dragonkin": (["dragon_tail"], ["dragon_horns", "dragon_scales"]),
    "Undead": ([], ["stitches"]),
    "Orc": ([], ["ears", "tusks"]),
    "Goblin": ([], ["goblin_ears"]),
    "Golem": ([], ["golem_runes"]),
}
# Transformations: extra layers, layers they take away, and forced skin / eye colors.
FORMS = {
    "Vampire": {"add": ["fangs"], "remove": [], "skin": 12, "eyes": "#e43b44"},
    "Werewolf": {"add": ["wolf_tail", "wolf_ears"], "remove": ["beast_ears", "beast_tail"], "eyes": "#feae34"},
    "Fallen Angel": {"add": ["fallen_wings", "broken_halo"], "remove": ["wings_angel", "halo"], "eyes": "#b8263a"},
    "Lich": {"add": ["lich_crown"], "remove": ["halo"], "skin": 13, "eyes": "#7fe9ff"},
}
# Awakening looks: rank look key -> extra layers (and layers they replace)
LOOKS = {
    "wings2": {"add": ["wings2"], "remove": []},
    "wings3": {"add": ["wings2", "wings3"], "remove": []},
    "horns_big": {"add": ["horns_big"], "remove": ["horns"]},
    "crown": {"add": ["crown"], "remove": []},
    "dragon_wings": {"add": ["dragon_wings"], "remove": []},
    "wings_big": {"add": ["wings_big"], "remove": ["wings_fairy"]},
    "glow": {"add": [], "remove": []},
}
EYES = {"Golem": "#7fe9ff", "Undead": "#a8ca58"}
