"""Joint-quantize every PixelLab hero frame and dump a labelled swatch + per-cluster masks (for material assignment)."""
import os, glob
from PIL import Image, ImageDraw
H = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
files = sorted(glob.glob(os.path.join(H, "rotations", "*.png")) + glob.glob(os.path.join(H, "anims", "*", "*.png")))
ims = [Image.open(f).convert("RGBA") for f in files]
cols = {}
for im in ims:
    for c, a in zip(im.getdata(), im.getchannel("A").getdata()):
        if a > 0: cols[c[:3]] = cols.get(c[:3], 0) + 1
print("frames", len(ims), "unique colours", len(cols))
N = 28
strip = Image.new("RGB", (len(cols), 1)); strip.putdata(list(cols))
big = Image.new("RGB", (sum(cols.values()), 1)); big.putdata([c for c, n in cols.items() for _ in range(n)])
q = big.quantize(N, method=Image.Quantize.MEDIANCUT)
pal = q.getpalette()[:N * 3]
P = [tuple(pal[i*3:i*3+3]) for i in range(N)]
def near(c): return min(range(N), key=lambda i: sum((a-b)**2 for a, b in zip(c, P[i])))
# north + south rotation labelled by cluster
for d in ["north", "south"]:
    im = Image.open(os.path.join(H, "rotations", d + ".png")).convert("RGBA")
    sheet = Image.new("RGB", (N * 70, 140), (40, 34, 48)); dr = ImageDraw.Draw(sheet)
    for i in range(N):
        m = Image.new("RGB", (64, 64), (40, 34, 48))
        for y in range(64):
            for x in range(64):
                p = im.getpixel((x, y))
                if p[3] and near(p[:3]) == i: m.putpixel((x, y), (255, 60, 200))
                elif p[3]: m.putpixel((x, y), (90, 84, 98))
        sheet.paste(m, (i * 70, 0)); dr.rectangle([i*70, 70, i*70+63, 110], fill=P[i]); dr.text((i*70+2, 114), str(i), fill=(255,255,255))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(os.environ["TMPD"], f"probe_{d}.png"))
print([ (i, P[i]) for i in range(N)])
