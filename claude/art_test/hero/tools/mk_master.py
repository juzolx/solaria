"""Writes the hand-authored base layer grids (traced over AI candidate r6_d64_s53, 64 px body).
Canvas 52 x 84. Materials: H hair, S skin, F sword-hand skin (drawn over the weapon), e eye,
W linen, V leather, B dark leather, T trousers, K boots, M metal, G grip.
Edit the produced layers/*.txt by hand afterwards; this script is only the starting point."""
import os
W, H = 52, 84
HERE = os.path.dirname(os.path.abspath(__file__))


def grid():
    return [["."] * W for _ in range(H)]


def put(g, rows):
    for y, spans in rows:
        for x0, x1, c in spans:
            for x in range(x0, x1 + 1):
                g[y][x] = c


def save(g, name):
    open(os.path.join(HERE, "layers", name + ".txt"), "w").write("\n".join("".join(r) for r in g) + "\n")


# ---------------- hair: short messy ----------------
hair = grid()
put(hair, [
    (19, [(10, 20, "H")]), (20, [(9, 23, "H")]), (21, [(8, 24, "H")]), (22, [(8, 25, "H")]),
    (23, [(6, 27, "H")]), (24, [(6, 27, "H")]), (25, [(5, 26, "H")]), (26, [(4, 26, "H")]),
    (27, [(5, 26, "H")]), (28, [(6, 26, "H")]), (29, [(6, 21, "H"), (24, 26, "H")]),
    (30, [(6, 20, "H"), (24, 25, "H")]), (31, [(7, 15, "H"), (18, 19, "H")]), (32, [(7, 14, "H"), (19, 19, "H")]),
    (33, [(8, 14, "H")]), (34, [(9, 14, "H")]), (35, [(10, 15, "H")]), (36, [(11, 16, "H")]),
    (37, [(12, 17, "H")]), (38, [(12, 16, "H")]),
])
put(hair, [(18, [(11, 12, "H"), (15, 18, "H")]), (17, [(16, 17, "H")])])
save(hair, "hair_short")

# ---------------- body: bald head, ear, face sliver, neck, hands ----------------
body = grid()
put(body, [
    (20, [(11, 21, "S")]), (21, [(9, 23, "S")]), (22, [(8, 24, "S")]), (23, [(7, 25, "S")]),
    (24, [(7, 25, "S")]), (25, [(6, 25, "S")]), (26, [(6, 25, "S")]), (27, [(6, 25, "S")]),
    (28, [(7, 25, "S")]), (29, [(7, 23, "S")]), (30, [(7, 23, "S")]), (31, [(8, 24, "S")]),
    (32, [(8, 25, "S")]), (33, [(9, 25, "S")]), (34, [(10, 24, "S")]), (35, [(11, 24, "S")]),
    (36, [(12, 23, "S")]), (37, [(13, 22, "S")]), (38, [(15, 21, "S")]), (39, [(17, 20, "S")]),
])
body[31][24] = "e"; body[32][24] = "e"
put(body, [(y, [(3, 6, "S")]) for y in range(51, 54)] + [(54, [(4, 6, "S")]), (55, [(4, 6, "S")])])
put(body, [(y, [(27, 31, "S")]) for y in range(51, 54)])
put(body, [(y, [(39, 44, "F")]) for y in range(51, 54)] + [(54, [(40, 43, "F")])])
save(body, "body")
front = grid()
for y in range(H):
    for x in range(W):
        if body[y][x] == "F":
            front[y][x] = "F"
save(front, "body_front")

# ---------------- outfit: leather ----------------
o = grid()
put(o, [(39, [(13, 17, "W")])])
vest = {40: (9, 21), 41: (7, 22), 42: (6, 22), 43: (6, 21), 44: (5, 20), 45: (5, 20)}
for y in range(46, 56):
    vest[y] = (6 if y < 51 else 7, 20 if y < 53 else 21 + (y >= 55))
for y, (a, b) in vest.items():
    put(o, [(y, [(a, b, "V")])])
sleeve = {43: (22, 24), 44: (21, 25), 45: (21, 26), 46: (21, 26), 47: (21, 27), 48: (21, 27), 49: (22, 28),
          50: (22, 28), 51: (21, 26), 52: (22, 26), 53: (23, 26)}
for y, (a, b) in sleeve.items():
    put(o, [(y, [(a, b, "W")])])
put(o, [(y, [(4 if y == 46 else 3, 5, "W")]) for y in range(46, 51)])
put(o, [(y, [(32, 38, "B")]) for y in range(50, 54)])
put(o, [(y, [(6, 24, "B")]) for y in range(56, 59)])
put(o, [(y, [(7, 24, "T")]) for y in range(59, 65)])
put(o, [(y, [(8, 14, "T"), (17, 24, "T")]) for y in range(65, 71)])
put(o, [(y, [(8, 15, "K"), (17, 25, "K")]) for y in range(71, 73)])
put(o, [(y, [(8, 14, "K"), (18, 25, "K")]) for y in range(73, 79)])
put(o, [(y, [(8, 14, "K"), (18, 28, "K")]) for y in range(79, 81)])
put(o, [(81, [(9, 13, "K"), (19, 27, "K")])])
save(o, "outfit_leather")

# ---------------- sword ----------------
s = grid()
tip, base = (48.5, 1), (45.0, 45)
for y in range(1, 46):
    t = (y - tip[1]) / (base[1] - tip[1])
    cx = tip[0] + (base[0] - tip[0]) * t
    w = 1 if y < 3 else (2 if y < 5 else 3)
    x0 = int(round(cx - (w - 1) / 2))
    put(s, [(y, [(x0, x0 + w - 1, "M")])])
put(s, [(46, [(38, 48, "M")]), (47, [(37, 48, "M")]), (48, [(41, 44, "M")])])
put(s, [(y, [(41, 42, "G")]) for y in range(49, 64)])
put(s, [(64, [(40, 43, "M")]), (65, [(40, 43, "M")]), (66, [(41, 42, "M")])])
save(s, "weapon_sword")
