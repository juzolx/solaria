"""PixelLab iso tiles (32x32 rhombus with an outline) -> seamless 32x16 ground diamonds:
drop every other row, sample slightly inward so the outline never shows, regrade darker.
Usage: py prep_tiles.py"""
from PIL import Image, ImageEnhance
NAMES = {"grass": [0, 1, 0, 1, 2], "cobble": [4, 5, 6], "flag": [8, 9], "dirt": [10, 11], "water": [12, 13], "grave": [14, 15]}
for key, idx in NAMES.items():
    for n, t in enumerate(idx):
        src = Image.open(f"gen/tiles/t{t}.png").convert("RGBA")
        sq = src.crop((0, 0, 32, 32)).resize((32, 16), Image.NEAREST)
        out = Image.new("RGBA", (32, 17), (0, 0, 0, 0))
        for y in range(17):
            for x in range(32):
                if abs(x - 15.5) / 16 + abs(y - 8) / 8.5 <= 1.0:
                    sx = int(round(15.5 + (x - 15.5) * 0.82))
                    sy = int(round(7.5 + (y - 8) * 0.78))
                    out.putpixel((x, y), sq.getpixel((max(0, min(31, sx)), max(0, min(15, sy)))))
        if key == "flag":
            out = Image.merge("RGBA", (*ImageEnhance.Brightness(out.convert("RGB")).enhance(0.72).split(), out.getchannel("A")))
        out.save(f"art/tiles/{key}_{n}.png")
