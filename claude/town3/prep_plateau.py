"""Plateau sprite = generated cliffs + stairs, top re-paved with the town's own iso tiles."""
from PIL import Image
from PIL import ImageEnhance
im = Image.open("gen/plateau_c.png").convert("RGBA")
im = Image.merge("RGBA", (*ImageEnhance.Brightness(im.convert("RGB")).enhance(0.7).split(), im.getchannel("A")))
OX, OY, Z = 116, 36, 24
def at(i, j): return OX + (i - j) * 16, OY + (i + j) * 8 - Z
flag = [Image.open(f"art/tiles/flag_{n}.png") for n in range(2)]
grass = [Image.open(f"art/tiles/grass_{n}.png") for n in range(5)]
cob = [Image.open(f"art/tiles/cobble_{n}.png") for n in range(3)]
blk = Image.open("art/wall_block.png").convert("RGBA")
blk = Image.merge("RGBA", (*ImageEnhance.Brightness(blk.convert("RGB")).enhance(0.75).split(), blk.getchannel("A")))
def cell(i, j, z=0): return OX + (i - j) * 16, OY + (i + j) * 8 - z
for zz in (0, 8):                       # two courses of blocks under the paving
    for i in range(14):                 # front (+j) face, leaving the stairs
        if not 5 <= i <= 8:
            x, y = cell(i, 6, zz)
            im.alpha_composite(blk, (x - 16, y - 16 + 16))
    for j in range(7):                  # side (+i) face
        x, y = cell(13, j, zz)
        im.alpha_composite(blk, (x - 16, y - 16 + 16))
for s in range(21):
    for i in range(14):
        j = s - i
        if 0 <= j < 7:
            t = cob if 5 <= i <= 8 and j >= 4 else (flag if 3 <= i <= 10 and j >= 2 else grass)
            t = t[(i * 7 + j * 3) % len(t)]
            x, y = at(i, j)
            im.alpha_composite(t, (x - 16, y))
im.save("art/plateau.png")
