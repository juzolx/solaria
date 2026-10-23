"""Quick grid of raw candidates: python -I artjob_contact.py out.png thumb glob..."""
import sys, glob, os
from PIL import Image, ImageDraw
out, th = sys.argv[1], int(sys.argv[2])
files = []
for g in sys.argv[3:]:
    files += sorted(glob.glob(g))
cols = min(6, len(files)); rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols * th, rows * (th + 14)), (30, 30, 36))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB"); im.thumbnail((th, th))
    x, y = (i % cols) * th, (i // cols) * (th + 14)
    sheet.paste(im, (x, y + 14)); d.text((x + 2, y + 1), os.path.basename(f)[:-4], fill=(220, 220, 220))
sheet.save(out)
