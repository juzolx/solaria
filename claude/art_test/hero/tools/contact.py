"""Contact sheet: python -I contact.py OUT.png W in1.png in2.png ... (labels = file stems)"""
import sys, os
from PIL import Image, ImageDraw
out, w = sys.argv[1], int(sys.argv[2]); fs = sys.argv[3:]
cols = min(4, len(fs)); rows = (len(fs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * w, rows * (w + 14)), "white"); d = ImageDraw.Draw(sheet)
for i, f in enumerate(fs):
    im = Image.open(f).convert("RGB"); im.thumbnail((w, w))
    x, y = (i % cols) * w, (i // cols) * (w + 14)
    sheet.paste(im, (x, y + 14)); d.text((x + 2, y + 1), os.path.basename(f)[:-4], fill="black")
sheet.save(out)
