"""Front-facing 3/4 block-outs (art-pipeline 9.3) used as img2img guides for PixelLab.
Roof band on top (seen from above), front wall facing the viewer, foundation strip.
Usage: py blockout.py <out_dir>"""
import sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
SLATE, SLATE_D, RIDGE = (58, 65, 82), (44, 50, 66), (78, 86, 104)
WALL, BEAM, FOUND = (122, 104, 84), (46, 36, 32), (74, 74, 82)
LIT, DOOR, EAVE = (232, 177, 74), (42, 28, 20), (26, 22, 32)
STONE, STONE_D = (92, 92, 100), (64, 64, 74)


def roof(d, x0, y0, x1, y1, rows=5):
    d.rectangle([x0, y0, x1, y1], SLATE)
    for y in range(y0 + 4, y1, rows):
        d.line([x0, y, x1, y], SLATE_D)
    d.rectangle([x0, y0, x1, y0 + 3], RIDGE)
    d.rectangle([x0 + 2, y1 + 1, x1 - 2, y1 + 3], EAVE)


def window(d, x, y, w=8, h=9):
    d.rectangle([x - 1, y - 1, x + w, y + h], BEAM)
    d.rectangle([x, y, x + w - 1, y + h - 1], LIT)
    d.line([x + w // 2, y, x + w // 2, y + h - 1], BEAM)


def inn():
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([88, 6, 100, 34], STONE)  # chimney
    d.rectangle([88, 6, 100, 9], STONE_D)
    roof(d, 6, 22, 121, 80)
    d.polygon([(42, 82), (86, 82), (64, 44)], WALL)  # cross gable
    d.line([(42, 82), (64, 44), (86, 82)], SLATE_D, 3)
    d.rectangle([10, 84, 117, 116], WALL)
    for x in (10, 36, 64, 92, 117):
        d.line([x, 84, x, 116], BEAM, 2)
    d.line([10, 99, 117, 99], BEAM, 2)
    window(d, 59, 62)
    for x in (18, 44, 76, 102):
        window(d, x, 87)
    for x in (18, 44, 102):
        window(d, x, 103, 8, 8)
    d.rectangle([58, 100, 70, 116], DOOR)
    d.rectangle([6, 116, 121, 123], FOUND)
    d.rectangle([2, 94, 8, 96], BEAM)  # sign bracket
    d.rectangle([0, 97, 10, 105], (150, 110, 60))
    return im


def smith():
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([22, 4, 38, 46], STONE)
    d.rectangle([22, 4, 38, 8], (30, 26, 30))
    roof(d, 4, 40, 86, 86)
    d.rectangle([8, 90, 82, 118], STONE)
    for y in range(94, 118, 6):
        d.line([8, y, 82, y], STONE_D)
    d.rectangle([20, 96, 44, 118], (40, 18, 10))  # forge mouth
    d.rectangle([24, 104, 40, 118], (236, 120, 40))
    d.rectangle([28, 108, 36, 118], (255, 200, 90))
    window(d, 58, 98)
    d.rectangle([84, 64, 124, 84], (88, 66, 46))  # lean-to roof (planks)
    for x in range(86, 124, 5):
        d.line([x, 64, x, 84], (62, 46, 32))
    d.rectangle([86, 86, 124, 88], EAVE)
    for x in (86, 122):
        d.rectangle([x, 86, x + 2, 118], BEAM)
    d.rectangle([96, 106, 112, 112], (40, 40, 48))  # anvil
    d.rectangle([100, 112, 108, 118], (40, 40, 48))
    d.ellipse([112, 104, 122, 118], (70, 50, 34))  # quench barrel
    d.rectangle([4, 118, 84, 124], FOUND)
    return im


def gate():
    im = Image.new("RGBA", (160, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([4, 0, 156, 70], (62, 82, 58))  # mossy top of the rise
    d.rectangle([6, 34, 154, 120], (72, 70, 80))  # rock/stone front face
    for y in range(44, 120, 9):
        d.line([6, y, 154, y], (56, 54, 64))
    for x in range(14, 154, 13):
        d.line([x, 40, x + 3, 120], (56, 54, 64))
    d.rectangle([44, 30, 116, 120], (98, 98, 108))  # carved portal
    d.pieslice([52, 38, 108, 94], 180, 360, (14, 10, 20))
    d.rectangle([52, 66, 108, 120], (14, 10, 20))
    for i, y in enumerate(range(96, 120, 5)):  # steps down
        d.rectangle([56 + i * 2, y, 104 - i * 2, y + 2], (60, 58, 70))
    for x in (60, 70, 80, 90, 100):  # runes on the arch
        d.rectangle([x, 34, x + 2, 37], (140, 200, 230))
    for x in (26, 128):  # braziers
        d.rectangle([x, 92, x + 8, 120], (40, 36, 40))
        d.ellipse([x - 4, 78, x + 12, 94], (240, 130, 40))
        d.ellipse([x, 80, x + 8, 90], (255, 210, 110))
    return im


for name, fn in (("inn", inn), ("smith", smith), ("gate", gate)):
    fn().save(f"{OUT}/{name}.png")
    fn().resize((fn().width * 4, fn().height * 4), Image.NEAREST).save(f"{OUT}/{name}_x4.png")


def wall():
    """Town wall segment, tiles horizontally: walkway top, crenellated parapet, tall block face."""
    im = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 95, 14], (104, 104, 114))  # walkway
    for x in range(0, 96, 8):
        d.line([x, 0, x, 14], (88, 88, 98))
    for x in range(0, 96, 16):  # merlons
        d.rectangle([x, 12, x + 9, 22], (118, 118, 128))
    d.rectangle([0, 22, 95, 62], (70, 70, 80))
    for i, y in enumerate(range(22, 62, 8)):
        d.line([0, y, 95, y], (52, 52, 62))
        for x in range((i % 2) * 8, 96, 16):
            d.line([x, y, x, y + 8], (52, 52, 62))
    d.rectangle([0, 58, 95, 63], (40, 40, 50))
    return im


def tower():
    im = Image.new("RGBA", (64, 112), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(32, 0), (6, 40), (58, 40)], SLATE)  # conical roof
    d.line([(32, 0), (32, 40)], RIDGE)
    d.rectangle([4, 40, 59, 46], (118, 118, 128))  # battlement ring
    for x in range(4, 60, 10):
        d.rectangle([x, 36, x + 5, 40], (118, 118, 128))
    d.rectangle([8, 46, 55, 108], (70, 70, 80))
    for y in range(52, 108, 8):
        d.line([8, y, 55, y], (52, 52, 62))
    d.rectangle([28, 58, 34, 70], LIT)  # lit slit window
    d.rectangle([29, 82, 33, 92], (20, 16, 24))
    d.rectangle([6, 104, 57, 111], FOUND)
    return im


def gatehouse():
    """The sealed town gate: two squat towers, portcullis down, chained and boarded."""
    im = Image.new("RGBA", (128, 112), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for x0 in (0, 92):
        d.rectangle([x0, 14, x0 + 35, 26], (118, 118, 128))
        for x in range(x0, x0 + 36, 9):
            d.rectangle([x, 8, x + 5, 14], (118, 118, 128))
        d.rectangle([x0 + 2, 26, x0 + 33, 106], (70, 70, 80))
        d.rectangle([x0 + 15, 44, x0 + 20, 56], LIT)
    d.rectangle([34, 30, 93, 106], (84, 84, 94))
    d.rectangle([34, 24, 93, 32], (118, 118, 128))
    d.pieslice([44, 40, 84, 80], 180, 360, (20, 16, 24))
    d.rectangle([44, 60, 84, 106], (20, 16, 24))
    for x in range(46, 84, 6):  # portcullis
        d.line([x, 44, x, 106], (60, 60, 66), 2)
    for y in range(64, 106, 10):
        d.line([44, y, 84, y], (60, 60, 66), 2)
    for y in (74, 90):  # boards across
        d.rectangle([40, y, 88, y + 5], (110, 80, 50))
    d.line([(42, 62), (86, 100)], (150, 150, 160), 2)  # chains
    d.line([(86, 62), (42, 100)], (150, 150, 160), 2)
    d.rectangle([0, 104, 127, 111], FOUND)
    return im


for name, fn in (("wall", wall), ("tower", tower), ("gatehouse", gatehouse)):
    fn().save(f"{OUT}/{name}.png")
