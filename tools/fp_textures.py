#!/usr/bin/env python3
"""First-person room textures (0.13): walls, floors and ceilings per zone, plus doors.

Source: Screaming Brain Studios "Tiny Texture Pack" 1, 2 and 3 (CC0, OpenGameArt),
unpacked at /home/claude/tex. Each texture is shrunk to 32x32, cut to a small
palette and graded dark so it reads as pixel art. Output: art/halls/.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageEnhance

SRC = "/home/claude/tex"
OUT = os.path.join(os.path.dirname(__file__), "..", "art", "halls")
P1 = "sbs_-_tiny_texture_pack_-_128x128/128x128/"
P2 = "sbs_-_tiny_texture_pack_2_-_128x128/128x128/"
P3 = "sbs_-_tiny_texture_pack_3_-_small/128x128/"

# zone: (wall, floor, ceiling, tint, brightness)
ZONES = [
    (P1 + "Bricks/Brick 5 - 128x128.png", P2 + "Dirt/Dirt_16-128x128.png", P1 + "Wood/Wood 6 - 128x128.png", (70, 110, 60), 0.75),     # 0 forest
    (P1 + "Bricks/Brick 25 - 128x128.png", P1 + "Tile/Tile 24 - 128x128.png", P1 + "Bricks/Brick 1 - 128x128.png", (120, 105, 85), 0.7),  # 1 barrows
    (P1 + "Bricks/Brick 3 - 128x128.png", P2 + "Tile/Tile_05-128x128.png", P1 + "Bricks/Brick 23 - 128x128.png", (70, 105, 125), 0.75),  # 2 coast
    (P2 + "Brick/Brick_12-128x128.png", P2 + "Tile/Tile_05-128x128.png", P2 + "Brick/Brick_10-128x128.png", (150, 70, 40), 0.8),       # 3 fire
    (P2 + "Brick/Brick_20-128x128.png", P2 + "Tile/Tile_01-128x128.png", P2 + "Brick/Brick_10-128x128.png", (95, 75, 125), 0.7),       # 4 myths
    (P1 + "Bricks/Brick 3 - 128x128.png", P1 + "Grass/Grass 11 - 128x128.png", P1 + "Wood/Wood 6 - 128x128.png", (80, 120, 95), 0.8),  # 5 elf
    (P1 + "Bricks/Brick 2 - 128x128.png", P1 + "Tile/Tile 25 - 128x128.png", P1 + "Bricks/Brick 2 - 128x128.png", (130, 90, 140), 0.85), # 6 fairy
    (P1 + "Bricks/Brick 24 - 128x128.png", P1 + "Tile/Tile 10 - 128x128.png", P2 + "Brick/Brick_08-128x128.png", (125, 100, 75), 0.8),  # 7 dwarf
    (P2 + "Brick/Brick_17-128x128.png", P1 + "Tile/Tile 2 - 128x128.png", P2 + "Brick/Brick_17-128x128.png", (150, 135, 100), 0.9),    # 8 angel
    (P2 + "Brick/Brick_15-128x128.png", P3 + "Terrain/Terrain_01-128x128.png", P2 + "Brick/Brick_10-128x128.png", (140, 50, 45), 0.7),  # 9 demon
]


def pixelize(path, size=32, colors=14, tint=(128, 128, 128), bright=0.8, sat=0.6):
    im = Image.open(os.path.join(SRC, path)).convert("RGB")
    im = im.resize((size, size), Image.BOX)
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Contrast(im).enhance(1.25)
    # Tint: multiply toward the zone color, then darken
    tr, tg, tb = tint
    px = im.load()
    for y in range(size):
        for x in range(size):
            r, g, b = px[x, y]
            lum = (r * 0.3 + g * 0.59 + b * 0.11) / 255.0
            nr = r * 0.45 + tr * lum * 1.1
            ng = g * 0.45 + tg * lum * 1.1
            nb = b * 0.45 + tb * lum * 1.1
            px[x, y] = (int(min(255, nr * bright)), int(min(255, ng * bright)), int(min(255, nb * bright)))
    im = im.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    return im


def door(wood_path, open_=False):
    W, H = 32, 48
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Arch mask
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle([2, 14, W - 3, H - 1], fill=255)
    md.ellipse([2, 2, W - 3, 26], fill=255)
    # Stone frame
    frame = Image.new("L", (W, H), 0)
    fd = ImageDraw.Draw(frame)
    fd.rectangle([0, 13, W - 1, H - 1], fill=255)
    fd.ellipse([0, 0, W - 1, 28], fill=255)
    im.paste((58, 54, 52, 255), (0, 0), frame)
    for y in range(H):
        for x in range(W):
            if frame.getpixel((x, y)) and not mask.getpixel((x, y)) and (x + y * 3) % 7 == 0:
                im.putpixel((x, y), (82, 76, 70, 255))
    if open_:
        inner = Image.new("RGBA", (W, H), (8, 6, 10, 255))
        idr = ImageDraw.Draw(inner)
        for i in range(10):
            c = 8 + i * 3
            idr.ellipse([W // 2 - 10 + i, H - 22 + i, W // 2 + 10 - i, H - 2 - i // 2], fill=(c, c - 2, c + 4, 255))
        im.paste(inner, (0, 0), mask)
        return im
    wood = pixelize(wood_path, 32, 8, (130, 88, 50), 1.1, 0.6).resize((W, H), Image.NEAREST)
    # Vertical planks: dark seams
    wd = ImageDraw.Draw(wood)
    for x in (8, 15, 23):
        wd.line([x, 0, x, H], fill=(28, 18, 12, 255))
    # Iron bands with rivets
    for y in (18, 36):
        wd.rectangle([0, y, W, y + 2], fill=(46, 46, 52, 255))
        wd.line([0, y, W, y], fill=(92, 92, 100, 255))
        for x in range(5, W - 3, 6):
            wd.point((x, y + 1), fill=(140, 140, 150, 255))
    # Ring handle
    wd.ellipse([21, 26, 26, 31], outline=(150, 135, 90, 255))
    im.paste(wood, (0, 0), mask)
    # Outline of the arch
    d2 = ImageDraw.Draw(im)
    d2.arc([2, 2, W - 3, 26], 180, 360, fill=(20, 18, 18, 255))
    d2.line([2, 14, 2, H - 1], fill=(20, 18, 18, 255))
    d2.line([W - 3, 14, W - 3, H - 1], fill=(20, 18, 18, 255))
    return im


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (wall, floor, ceil, tint, bright) in enumerate(ZONES):
        pixelize(wall, 32, 14, tint, bright).save(os.path.join(OUT, "z%d_wall.png" % i))
        pixelize(floor, 32, 12, tint, bright * 0.85).save(os.path.join(OUT, "z%d_floor.png" % i))
        pixelize(ceil, 32, 8, tint, bright * 0.45).save(os.path.join(OUT, "z%d_ceil.png" % i))
    door(P1 + "Wood/Wood 6 - 128x128.png").save(os.path.join(OUT, "door.png"))
    door(P1 + "Wood/Wood 6 - 128x128.png", True).save(os.path.join(OUT, "door_open.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    sys.exit(main())
