"""Candidate figures from many raws -> one indexed contact sheet (native size x4) + index json."""
import sys, glob, json, os
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P
from PIL import Image, ImageDraw
out = sys.argv[1]; pats = sys.argv[2:]
files = []
for g in pats: files += sorted(glob.glob(g))
cands = []
for f in files:
    raw, figs = P.figures(f)
    for i, fg in enumerate(figs):
        cands.append({"file": f, "i": i, "box": fg["box"], "img": fg["img"]})
S = 4; cell = 64 * S // 2 + 16
cols = 12; rows = (len(cands) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * 140, rows * 150), (44, 40, 54, 255)); d = ImageDraw.Draw(sheet)
idx = []
for k, c in enumerate(cands):
    im = c["img"]; s = max(1, min(130 // im.width, 130 // im.height, 4))
    x, y = (k % cols) * 140, (k // cols) * 150
    sheet.alpha_composite(im.resize((im.width * s, im.height * s), Image.NEAREST), (x + 4, y + 14))
    d.text((x + 2, y + 1), f"{k} {os.path.basename(c['file'])[:-4][-14:]}", fill=(230, 230, 230))
    idx.append({"k": k, "file": c["file"], "i": c["i"], "box": [int(v) for v in c["box"]], "size": list(im.size)})
sheet.save(out)
json.dump(idx, open(out[:-4] + ".json", "w"), indent=0)
print(len(cands))
