"""Bridge sprite = generated parapets/sides, deck re-paved with the town's cobble tiles."""
from PIL import Image, ImageEnhance
im = Image.open("gen/bridge_c.png").convert("RGBA")
im = Image.merge("RGBA", (*ImageEnhance.Brightness(im.convert("RGB")).enhance(0.8).split(), im.getchannel("A")))
OX, OY, Z = 68, 28, 8
cob = [Image.open(f"art/tiles/cobble_{n}.png") for n in range(3)]
for s in range(10):
    for i in range(1, 5):
        j = s - i
        if 0 <= j < 4:
            t = cob[(i + j * 2) % 3]
            x, y = OX + (i - j) * 16, OY + (i + j) * 8 - Z
            im.alpha_composite(t, (x - 16, y))
im.save("art/bridge.png")
