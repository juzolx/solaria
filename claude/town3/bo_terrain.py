"""Block-outs for the plateau (raised 24 px, rock cliffs, stairs down to the main street) and
the stone bridge, at their exact layout footprints. Usage: py bo_terrain.py"""
from blockout import Canvas

def plateau():
    w, h, z = 14, 7, 24
    c = Canvas(w, h, z + 8)
    c.poly([(w, 0, 0), (w, h, 0), (w, h, z), (w, 0, z)], "#5d564e")           # +i cliff
    c.poly([(0, h, 0), (w, h, 0), (w, h, z), (0, h, z)], "#7a7066")           # +j cliff
    c.poly([(0, 0, z), (w, 0, z), (w, h, z), (0, h, z)], "#8c8678")           # top paving
    c.poly([(0, 0, z), (w, 0, z), (w, 2, z), (0, 2, z)], "#4c6040")           # grass strip at the back
    for k in range(6):                                                         # stairs on the +j face, i 5..9
        zz = z - k * 4
        c.poly([(5, h + k * .35, zz), (9, h + k * .35, zz), (9, h + (k + 1) * .35, zz), (5, h + (k + 1) * .35, zz)], "#a49c8c")
        c.poly([(5, h + (k + 1) * .35, zz), (9, h + (k + 1) * .35, zz), (9, h + (k + 1) * .35, zz - 4), (5, h + (k + 1) * .35, zz - 4)], "#6e665c")
    c.img.save("bo/bo_plateau.png"); print("plateau", c.size)

def bridge():
    w, h, z = 6, 4, 8          # spans the river along j
    c = Canvas(w, h, z + 14)
    c.poly([(w, 0, 0), (w, h, 0), (w, h, z), (w, 0, z)], "#6e6a66")
    c.poly([(0, h, 0), (w, h, 0), (w, h, z), (0, h, z)], "#8a8580")
    c.poly([(0, 0, z), (w, 0, z), (w, h, z), (0, h, z)], "#a39c90")
    c.poly([(0, 0, z), (.6, 0, z), (.6, h, z), (0, h, z)], "#77736e")          # parapets
    c.poly([(w - .6, 0, z), (w, 0, z), (w, h, z), (w - .6, h, z)], "#77736e")
    c.poly([(w - .6, 0, z + 10), (w, 0, z + 10), (w, h, z + 10), (w - .6, h, z + 10)], "#8f8a84")
    c.poly([(w, 0, z), (w, h, z), (w, h, z + 10), (w, 0, z + 10)], "#6e6a66")
    c.img.save("bo/bo_bridge.png"); print("bridge", c.size)

plateau(); bridge()
