"""One contact sheet per dungeon zone from `tools/check.sh halls <tag>` shots.

  python3 tools/halls_sheets.py <tag>

Reads shots/halls/<tag>{,_se}, shots/room_events/<tag>{,_se} and shots/fights/<tag>{,_se} and writes
claude/art_test/halls/<tag>/z<zone>.png (rooms, events, then fights, at 430 and on the SE),
each picture cropped to the room view.
"""
import glob, os, sys
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
tag = sys.argv[1] if len(sys.argv) > 1 else "halls_all"
out = os.path.join(ROOT, "claude", "art_test", "halls", tag)
os.makedirs(out, exist_ok=True)

def crop(f, se):
    im = Image.open(f).convert("RGB")
    return im.crop((0, 50, im.width, 470 if se else 565))

def row(files, se, scale):
    ims = [crop(f, se) for f in files]
    ims = [i.resize((int(i.width * scale), int(i.height * scale)), Image.NEAREST) for i in ims]
    r = Image.new("RGB", (sum(i.width for i in ims) + 4 * (len(ims) - 1), max(i.height for i in ims)), (14, 8, 18))
    x = 0
    for i in ims:
        r.paste(i, (x, 0))
        x += i.width + 4
    return r

for z in range(10):
    rows = []
    for se in (False, True):
        suf = "_se" if se else ""
        rooms = sorted(glob.glob(os.path.join(ROOT, "shots", "halls", tag + suf, "z%d_*.png" % z)))
        events = sorted(glob.glob(os.path.join(ROOT, "shots", "room_events", tag + suf, "z%d_*.png" % z)))
        size = "375x667" if se else "430x932"
        if rooms:
            rows.append(("rooms at %s: %s" % (size, ", ".join(os.path.basename(f)[3:-4] for f in rooms)), row(rooms, se, 0.75)))
        for part in range(0, len(events), 9):
            chunk = events[part:part + 9]
            rows.append(("events at %s: %s" % (size, " ".join(os.path.basename(f)[6:-4] for f in chunk)), row(chunk, se, 0.5)))
        fights = sorted(glob.glob(os.path.join(ROOT, "shots", "fights", tag + suf, "z%d_*.png" % z)))
        if fights:
            rows.append(("fights at %s: %s" % (size, ", ".join(os.path.basename(f)[3:-4] for f in fights)), row(fights, se, 0.75)))
    if not rows:
        continue
    w = max(r.width for _, r in rows)
    s = Image.new("RGB", (w, sum(r.height + 20 for _, r in rows)), (14, 8, 18))
    d = ImageDraw.Draw(s)
    y = 0
    for label, r in rows:
        d.text((4, y + 4), label, fill=(254, 231, 97))
        s.paste(r, (0, y + 20))
        y += r.height + 20
    s.save(os.path.join(out, "z%d.png" % z))
print("sheets in", out)
