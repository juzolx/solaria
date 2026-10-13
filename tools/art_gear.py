"""Gear pieces drawn to fit the hero body. Material letters:
   m base / M shadow / ^ light / * highlight   (the gear's material, recolored in game)
   r trim / R trim shadow / ! trim light       (rarity color)
   x dark strap, k rivet/black, s skin (sandals)"""
import sys
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import pixelshade as ps
import art_body as hero_base

MANUAL = True
MATS = {
    'm': ['#ffffff', '#c0cbdc', '#8b9bb4', '#5a6988', '#3a4466'],
    'r': ['#2ce8f5', '#2ce8f5', '#0099db', '#124e89', '#193c3e'],
    'x': ['#733e39', '#733e39', '#5a3438', '#3e2731', '#2a1d26'],
    'k': '#262b44',
    's': ['#fbe6cf', '#f2cfae', '#e8b796', '#c28569', '#733e39'],
}
ALIASES = {'M': ('m', 3), '^': ('m', 1), '*': ('m', 0), 'R': ('r', 3), '!': ('r', 1), 'X': ('x', 3), 'S': ('s', 3)}

TONE_MAP = {'2': '^', '6': '*', 't': 'm', 'T': 'M', '3': '^', 'p': 'm', 'P': 'M', '4': '^', '5': '*', 'b': 'm', 'B': 'M'}


def blank():
    return [['.'] * 32 for _ in range(32)]


def from_body(body, letters, rows=range(32)):
    g = blank()
    for y in rows:
        for x, c in enumerate(body[y]):
            if c in letters:
                g[y][x] = TONE_MAP.get(c, 'm')
    return g


def put(g, x, y, text):
    for i, ch in enumerate(text):
        if ch != ' ':
            g[y][x + i] = ch


def done(g):
    return [''.join(r) for r in g]


B = hero_base.MASC

# ---------------- chest ----------------
def tunic():
    g = from_body(B, 'tT26', range(13, 21))
    for y in range(13, 21):
        for x in range(32):
            if B[y][x] == 'l' or B[y][x] == 'g' or B[y][x] == 'L':
                g[y][x] = 'x'
    put(g, 14, 13, 'r!r')         # collar
    put(g, 15, 14, 'R')
    put(g, 16, 20, 'r')           # buckle
    for y in range(15, 20):        # lacing
        g[y][16] = 'X' if y % 2 else 'x'
    return done(g)


def plate():
    g = from_body(B, 'tT26', range(13, 21))
    for y in range(13, 21):
        for x in range(32):
            if B[y][x] in 'lLg':
                g[y][x] = 'M'
    # chest ridge highlight
    for y in range(15, 19):
        g[y][14] = '*' if y < 17 else '^'
    # pauldrons
    put(g, 10, 13, '.^mM')
    put(g, 10, 14, '^mmM')
    put(g, 10, 15, 'rrrR')
    put(g, 19, 12, '^*^m')
    put(g, 18, 13, '^**^mM')
    put(g, 18, 14, 'mmmmMM')
    put(g, 18, 15, 'rr!rRR')
    # belt / faulds
    put(g, 12, 20, 'MMMMrMMMM')
    put(g, 12, 21, 'mMmMmMm')
    return done(g)


def robe():
    g = from_body(B, 'tT26', range(13, 21))
    for y in range(13, 21):
        for x in range(32):
            if B[y][x] in 'lLg':
                g[y][x] = 'r'
    put(g, 14, 13, 'r!r')
    for y in range(14, 20):
        g[y][15] = 'R'
    # long skirt over the legs
    skirt = {
        21: (12, 21), 22: (12, 22), 23: (11, 22), 24: (11, 23), 25: (10, 23), 26: (10, 24),
    }
    for y, (a, b) in skirt.items():
        for x in range(a, b + 1):
            g[y][x] = 'M' if x <= a + 1 else ('^' if x == a + 2 else 'm')
        g[y][b] = 'M'
    put(g, 10, 27, 'rr!rrrrrrrrrrrR')
    for y in range(21, 27):
        g[y][17] = 'M'
    return done(g)


# ---------------- legs ----------------
def pants():
    g = from_body(B, 'pP3', range(21, 27))
    return done(g)


def greaves():
    g = from_body(B, 'pP3', range(21, 27))
    put(g, 12, 21, 'rrrrrrrrRR')
    # knee caps
    put(g, 11, 24, '*^')
    put(g, 21, 24, '*^m')
    put(g, 21, 25, '^mM')
    return done(g)


def leggings():
    g = from_body(B, 'pP3', range(21, 27))
    for y in range(21, 27):
        xs = [x for x, c in enumerate(B[y]) if c in 'pP3']
        if xs:
            g[y][xs[-1]] = 'R' if y > 22 else 'r'
    put(g, 12, 21, 'xxxx')
    return done(g)


# ---------------- feet ----------------
def boots():
    g = from_body(B, 'bB45', range(27, 31))
    # tall cuffs over the shins
    put(g, 10, 25, 'r!rR')
    put(g, 10, 26, '^mmM')
    put(g, 20, 25, 'r!rR')
    put(g, 20, 26, '^mmM')
    return done(g)


def sandals():
    g = from_body(B, 'bB45', range(27, 31))
    for y in range(27, 30):
        for x in range(32):
            if g[y][x] != '.' and (x + y) % 2 == 0:
                g[y][x] = 's' if y < 29 else 'S'
    for x in range(32):
        if g[29][x] != '.':
            g[29][x] = 'r'
    return done(g)


def sabatons():
    g = from_body(B, 'bB45', range(27, 31))
    for y in range(27, 31):
        for x in range(32):
            if g[y][x] == '^':
                g[y][x] = '*'
    put(g, 10, 27, 'rrRR')
    put(g, 20, 27, 'rrRR')
    g[30][26] = 'M'
    return done(g)


TUNIC, PLATE, ROBE = tunic(), plate(), robe()
PANTS, GREAVES, LEGGINGS = pants(), greaves(), leggings()
BOOTS, SANDALS, SABATONS = boots(), sandals(), sabatons()

# ---------------- helmets (drawn by hand) ----------------
#            0         1         2         3
#            01234567890123456789012345678901
CAP = [
    "................................",  # 0
    "................................",  # 1
    "...........*^^mmM...............",  # 2
    ".........*^^mmmmmmM.............",  # 3
    "........*^mmmmmmmmmMM...........",  # 4
    "........rrr!rrrrrrrRRRRRR.......",  # 5
]
HELM = [
    "................................",  # 0
    "............*^^mm...............",  # 1
    "..........*^^mmmmmM.............",  # 2
    ".........*^mmmmmmmmMM...........",  # 3
    "........*^mmmmmmmmmmMMM.........",  # 4
    "........^mmmmmmmmmmmmMMM........",  # 5
    "........rr!rrrrrrrrrRRRR........",  # 6
    "........^mmmM.......mM..........",  # 7
    "........^mmMM.......mM..........",  # 8
    "........^mmMM.......MM..........",  # 9
    ".........mmMM...................",  # 10
    ".........rRR....................",  # 11
]
HOOD = [
    "................................",  # 0
    "...........^^mmm................",  # 1
    ".........^^*mmmmmM..............",  # 2
    "........^**mmmmmmmMM............",  # 3
    ".......^^mmmmmmmmmmMMM..........",  # 4
    ".......^mmmmmmmmmmmmMMM.........",  # 5
    ".......^mmmmMMMMMMMMMMMM........",  # 6
    ".......^mmmM..........M.........",  # 7
    ".......^mmmM.........M..........",  # 8
    ".......^mmmM....................",  # 9
    ".......^mmmmM...................",  # 10
    ".......mmmmmMM..................",  # 11
    "........mmmmmMM.................",  # 12
    "........rRRRrrR.................",  # 13
]
CROWN = [
    "...........*..*..*..............",  # 0
    "...........^.^m.^m..............",  # 1
    "...........^mmm!mmM.............",  # 2
    "...........mrmmrmmM.............",  # 3
]

# A cape for unique classes: hangs from the shoulders behind the body and
# sweeps back (to the left, the hero faces right). m = cloth (class color),
# r = trim (rank color). Drawn behind the body, so only the back edge shows.
CAPE = [
    "................................",  # 0
    "................................",  # 1
    "................................",  # 2
    "................................",  # 3
    "................................",  # 4
    "................................",  # 5
    "................................",  # 6
    "................................",  # 7
    "................................",  # 8
    "................................",  # 9
    "................................",  # 10
    "................................",  # 11
    "............rrrrrrrr............",  # 12
    "..........^mmmmmmmmmm...........",  # 13
    ".........^mmmmmmmmmmM...........",  # 14
    "........^mmmmmmmmmmMM...........",  # 15
    "........^mmmmmmmmmmM............",  # 16
    ".......^mmmmmmmmmmMM............",  # 17
    ".......^mmmmmmmmmMM.............",  # 18
    "......^mmmmmmmmmmM..............",  # 19
    "......^mmmmmmmmmMM..............",  # 20
    ".....^mmmmMmmmmmM...............",  # 21
    ".....^mmmMmmmmmMM...............",  # 22
    "....^mmmMmmmmmMM................",  # 23
    "....^mmMmmmmMmM.................",  # 24
    "...^mmMmmmmMmmM.................",  # 25
    "...^mMmmmMmmmM..................",  # 26
    "...rRrrrRrrrR...................",  # 27
    "................................",  # 28
    "................................",  # 29
    "................................",  # 30
    "................................",  # 31
]
