"""Block-out of a 4-cell curtain wall run along i (visible face +j), 40 px tall, merlons on the
outer edge, a buttress at the run start so repeats join behind it. Usage: py bo_wall.py"""
from blockout import Canvas
L, Hh = 4, 40
c = Canvas(L, 1, Hh + 16)
def box(i0, j0, i1, j1, z0, z1, cols):
    c.poly([(i1, j0, z0), (i1, j1, z0), (i1, j1, z1), (i1, j0, z1)], cols[1])
    c.poly([(i0, j1, z0), (i1, j1, z0), (i1, j1, z1), (i0, j1, z1)], cols[0])
    c.poly([(i0, j0, z1), (i1, j0, z1), (i1, j1, z1), (i0, j1, z1)], cols[2])
stone = ("#77737a", "#57535c", "#8c8890")
box(0, 0, L, 1, 0, Hh, stone)
c.poly([(0, .25, Hh), (L, .25, Hh), (L, .7, Hh), (0, .7, Hh)], "#5e5a52")          # walkway
for k in range(L * 2):
    i0 = k * .5 + .08
    box(i0, .7, i0 + .3, 1, Hh, Hh + 9, stone)                                      # merlons
for k in range(L * 2):
    i0 = k * .5 + .14
    box(i0, 0, i0 + .22, .22, Hh, Hh + 6, stone)                                    # back parapet
box(0, 1, .55, 1.35, 0, Hh + 4, ("#6c6870", "#504c55", "#85818a"))                  # buttress
c.poly([(.6, 1, 0), (L, 1, 0), (L, 1, 8), (.6, 1, 8)], "#4c5a3c")                   # moss at the base
c.img.save("bo/bo_wall.png"); print(c.size)
