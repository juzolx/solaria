import math
import os
import sys
from PIL import Image
# tools/draw_trap_circle.py <repo> : Solaria's own rune circles, in light palette greys (tinted in code).
# art/traps/circle.png is the base (2 px outer ring, eight runes in the band, 1 px inner ring);
# art/traps/<trap kind>.png adds that trap's sigil in the middle; art/traps/shrine.png is the
# shrine's own glyph (a different layout). 64x64, laid flat, no outline ring, no rotation in game.
W = 64
C = 31.5
WHITE = (255, 255, 255, 255)
LIGHT = (0xc0, 0xcb, 0xdc, 255)
MID = (0x8b, 0x9b, 0xb4, 255)
OUT = os.path.join(sys.argv[1] if len(sys.argv) > 1 else ".", "art", "traps")


def new():
    return Image.new("RGBA", (W, W))


def put(px, x, y, c):
    if 0 <= x < W and 0 <= y < W:
        px[x, y] = c


def band(px, r0, r1, c):
    # every pixel whose centre lies in r0 <= d < r1 (r1 - r0 = 1 gives a clean 1 px ring)
    for y in range(W):
        for x in range(W):
            d = math.hypot(x - C, y - C)
            if r0 <= d < r1:
                px[x, y] = c


def line(px, x0, y0, x1, y1, c, w=1):
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        for ox in range(w):
            for oy in range(w):
                put(px, x0 + ox, y0 + oy, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def rows(px, cx, cy, art, c):
    # a small sigil from text rows ('#' = pixel), centred on (cx, cy)
    h, w = len(art), len(art[0])
    for yy, row in enumerate(art):
        for xx, ch in enumerate(row):
            if ch == "#":
                put(px, cx - w // 2 + xx, cy - h // 2 + yy, c)


RUNES = [
    [".#.", "#.#", "#.#"],
    ["#.#", ".#.", ".#."],
    ["###", ".#.", "#.#"],
    ["#..", "###", "..#"],
]


def base(px):
    band(px, 29.0, 31.0, WHITE)       # the 2 px outer ring
    band(px, 18.5, 19.5, LIGHT)       # 1 px inner ring
    for i in range(8):
        a = math.radians(-90 + i * 45)
        rows(px, round(C + 24.0 * math.cos(a)), round(C + 24.0 * math.sin(a)), RUNES[i % 4], WHITE)
        a2 = math.radians(-90 + i * 45 + 22.5)
        for k in (20.5, 27.5):        # ticks on the rings between the runes
            put(px, round(C + k * math.cos(a2)), round(C + k * math.sin(a2)), MID)


SIGILS = {
    "spikes": [  # three blades
        "....#.......#.......#....",
        "....#.......#.......#....",
        "...###.....###.....###...",
        "...###.....###.....###...",
        "..#####...#####...#####..",
        "..#####...#####...#####..",
        ".#######.#######.#######.",
        "#########################",
    ],
    "darts": [  # a venom drop
        ".....#.....",
        ".....#.....",
        "....###....",
        "....###....",
        "...#####...",
        "..#######..",
        ".###...###.",
        ".##.....##.",
        "##.......##",
        "##.......##",
        ".##.....##.",
        "..###.###..",
        "...#####...",
    ],
    "flames": [  # a flame
        "....#......",
        "...##......",
        "...###..#..",
        "..####.##..",
        "..#######..",
        ".###.####..",
        ".##..#####.",
        "###...####.",
        "##....#####",
        "##.....####",
        ".##....###.",
        "..##..###..",
        "...#####...",
    ],
    "frost": [  # a snow crystal
        "......#......",
        "...#..#..#...",
        "....#.#.#....",
        "#....###....#",
        ".#...###...#.",
        "..##.###.##..",
        "#############",
        "..##.###.##..",
        ".#...###...#.",
        "#....###....#",
        "....#.#.#....",
        "...#..#..#...",
        "......#......",
    ],
    "smoke": [  # a waning moon
        "...######...",
        ".###....##..",
        "###.........",
        "##..........",
        "##..........",
        "##..........",
        "##..........",
        "###.........",
        ".###....##..",
        "...######...",
    ],
    "alarm": [  # a bell
        ".....##.....",
        "....####....",
        "...##..##...",
        "..##....##..",
        "..#......#..",
        "..#......#..",
        ".##......##.",
        ".#........#.",
        "############",
        ".....##.....",
    ],
}


def big(art):
    # every sigil pixel drawn as 2x2, so the strokes read as 2 px lines like the rings
    return [r for row in art for r in ("".join(ch * 2 for ch in row),) * 2]


os.makedirs(OUT, exist_ok=True)
img = new()
base(img.load())
img.save(os.path.join(OUT, "circle.png"))
for kind, art in SIGILS.items():
    img = new()
    px = img.load()
    base(px)
    rows(px, 32, 32, art if kind == "spikes" else big(art), WHITE)
    img.save(os.path.join(OUT, kind + ".png"))
# the shrine's glyph: a square set in two rings, four eyes on its sides, a small ring inside
img = new()
px = img.load()
band(px, 29.0, 31.0, WHITE)
band(px, 26.0, 27.0, MID)
for k in range(4):
    a = math.radians(45 + k * 90)
    b = math.radians(45 + (k + 1) * 90)
    line(px, C + 24 * math.cos(a), C + 24 * math.sin(a), C + 24 * math.cos(b), C + 24 * math.sin(b), LIGHT, 2)
    e = math.radians(k * 90)
    rows(px, round(C + 11 * math.cos(e)), round(C + 11 * math.sin(e)), [".##.", "#..#", ".##."], WHITE)
band(px, 4.0, 6.0, WHITE)
img.save(os.path.join(OUT, "shrine.png"))
print("trap circles drawn")
