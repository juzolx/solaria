"""Quick look at some monster drawings without rebuilding all the art.
Run:  python3 tools/preview_enemies.py out.png key1 key2 ...   (no keys = all)"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image  # noqa: E402
import art_enemies  # noqa: E402

out = sys.argv[1]
keys = sys.argv[2:] or list(art_enemies.ENEMIES)
S = 6
cells = []
for k in keys:
    im = art_enemies.render(k)
    cells.append(im.resize((im.width * S, im.height * S), Image.NEAREST))
cw = max(c.width for c in cells) + 16
ch = max(c.height for c in cells) + 16
cols = min(len(cells), 5)
rows = (len(cells) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * cw, rows * ch), (38, 43, 68, 255))
for i, c in enumerate(cells):
    x = (i % cols) * cw + (cw - c.width) // 2
    y = (i // cols) * ch + (ch - c.height) - 8
    sheet.alpha_composite(c, (x, y))
sheet.save(out)
