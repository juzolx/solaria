"""Round 3 town sheets: day, dusk, numbered key, phone crops. Usage: python -I make_v3_town.py OUT"""
import sys
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts")
import town3 as T
from make_v2 import text, zoom, F, ACC
from make_v2b import badge
OUT = sys.argv[1]
day, placed = T.compose()
dusk = T.dusk(day, placed)
D2, N2 = zoom(day, 2), zoom(dusk, 2)
D2.save(OUT + "/R3_6_town_day.png"); N2.save(OUT + "/R3_7_town_dusk.png")
key = D2.copy(); d = ImageDraw.Draw(key)
for by, s, at, k, lab, n, sl in placed:
    if n is None:
        continue
    cx, cy = ((at[0] + s.width // 2) * 2, (at[1] + 6) * 2) if s is not None else (at[0] * 2, at[1] * 2)
    badge(d, cx, cy, n, lab)
for (x, y, lab) in ((120, 470, "sealed gate - no road out"), (60, 22, "fog beyond the walls"), (1390, 150, "raised plateau + stairs: the way down"), (880, 70, "watchtowers face OUT")):
    w = d.textlength(lab, font=F[18]); d.rectangle((x - 4, y - 4, x + w + 6, y + 24), fill=(14, 8, 18)); text(d, (x, y - 2), lab, 18, (255, 176, 176))
key.save(OUT + "/R3_8_town_key.png")
for name, x0 in (("R3_9_town_phone_market_dusk", 430), ("R3_10_town_phone_dungeon_dusk", 1330)):
    ph = Image.new("RGBA", (430, 932), (14, 8, 18, 255)); dd = ImageDraw.Draw(ph)
    ph.alpha_composite(N2.crop((x0, 0, x0 + 430, 880)), (0, 52))
    dd.rectangle((0, 0, 430, 52), fill=(28, 24, 40)); text(dd, (14, 12), "Town (swipe)", 22)
    ph.save(OUT + f"/{name}.png")
print("town ok")
