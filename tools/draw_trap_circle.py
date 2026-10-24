import sys, math
from PIL import Image
# tools/draw_trap_circle.py out.png : the trap magic circle, clean 1 px pixel lines in light palette greys
# (tinted per trap in code). 64x64: double outer ring, eight runes in the band, inner ring, hexagram.
W = 64
C = 31.5
img = Image.new('RGBA', (W, W))
px = img.load()
WHITE = (255, 255, 255, 255)
LIGHT = (0xc0, 0xcb, 0xdc, 255)
MID = (0x8b, 0x9b, 0xb4, 255)

def put(x, y, c):
    if 0 <= x < W and 0 <= y < W:
        px[x, y] = c

def ring(r, c):
    # every pixel whose centre lies within half a pixel of the radius, thinned to a clean 1 px line
    for y in range(W):
        for x in range(W):
            d = math.hypot(x - C, y - C)
            if abs(d - r) < 0.5:
                put(x, y, c)

def line(x0, y0, x1, y1, c):
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        put(x0, y0, c)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy

ring(30.5, WHITE)
ring(27.5, LIGHT)
ring(18.5, WHITE)
# hexagram inside the inner ring
for k in range(2):
    pts = [(C + 17.0 * math.cos(math.radians(-90 + k * 60 + i * 120)), C + 17.0 * math.sin(math.radians(-90 + k * 60 + i * 120))) for i in range(3)]
    for i in range(3):
        line(*pts[i], *pts[(i + 1) % 3], LIGHT)
# eight runes in the band between the rings (alternating shapes), plus small dots between them
RUNES = [
    ['.W.', 'W.W', 'W.W'],
    ['W.W', '.W.', '.W.'],
    ['WWW', '.W.', 'W.W'],
    ['W..', 'WWW', '..W'],
]
for i in range(8):
    a = math.radians(-90 + i * 45)
    cx, cy = round(C + 23.0 * math.cos(a)), round(C + 23.0 * math.sin(a))
    g = RUNES[i % 4]
    for yy, row in enumerate(g):
        for xx, ch in enumerate(row):
            if ch == 'W':
                put(cx - 1 + xx, cy - 1 + yy, WHITE)
    a2 = math.radians(-90 + i * 45 + 22.5)
    put(round(C + 23.0 * math.cos(a2)), round(C + 23.0 * math.sin(a2)), MID)
# a bright centre
for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
    put(31 + dx, 31 + dy, WHITE)
img.save(sys.argv[1])
