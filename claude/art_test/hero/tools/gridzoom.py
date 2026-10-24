"""python -I gridzoom.py in.png out.png [zoom] : zoomed image with a coordinate grid every 5 px"""
import sys
from PIL import Image, ImageDraw
im = Image.open(sys.argv[1]).convert("RGBA"); z = int(sys.argv[3]) if len(sys.argv) > 3 else 14
W, H = im.size; m = 24
out = Image.new("RGBA", (W * z + m, H * z + m), (60, 60, 70, 255))
chk = Image.new("RGBA", (W * z, H * z), (90, 90, 100, 255))
out.paste(chk, (m, m)); out.alpha_composite(im.resize((W * z, H * z), Image.NEAREST), (m, m))
d = ImageDraw.Draw(out)
for x in range(0, W + 1):
    c = (255, 255, 0, 150) if x % 5 == 0 else (0, 0, 0, 40)
    d.line([(m + x * z, m), (m + x * z, m + H * z)], fill=c)
    if x % 5 == 0 and x < W: d.text((m + x * z + 1, 4), str(x), fill="white")
for y in range(0, H + 1):
    c = (255, 255, 0, 150) if y % 5 == 0 else (0, 0, 0, 40)
    d.line([(m, m + y * z), (m + W * z, m + y * z)], fill=c)
    if y % 5 == 0 and y < H: d.text((2, m + y * z + 1), str(y), fill="white")
out.save(sys.argv[2])
