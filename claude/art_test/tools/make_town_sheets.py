import sys; sys.path.insert(0, r"C:\ai\scripts")
import town_concept as T, pixlib as P
from PIL import Image, ImageDraw
OUT = sys.argv[1]; TXT = (232, 228, 240)
day, night, placed = T.compose()
D = day.resize((704, 1360), Image.NEAREST); N = night.resize((704, 1360), Image.NEAREST)
D.save(OUT + "/town_concept_day.png"); N.save(OUT + "/town_concept_dusk.png")
cur = Image.open(T.REPO + r"\art\town\town_summer.png").convert("RGBA")
c = Image.new("RGBA", (704 * 3 + 40, 1360 + 30), (30, 27, 40, 255)); d = ImageDraw.Draw(c)
c.alpha_composite(cur, (0, 30)); c.alpha_composite(D, (724, 30)); c.alpha_composite(N, (1448, 30))
d.text((6, 8), "today: LPC packs, 1x art, 704x1088", fill=TXT)
d.text((730, 8), "new concept: 2x art on the same layout (+ bottom strip: Church, trophy cabin, empty lots)", fill=TXT)
d.text((1454, 8), "dusk version (palette-snapped grade, lit windows, lamp glow)", fill=TXT)
c.save(OUT + "/town_compare.png")
# three cleaned buildings: raw -> native grid -> palette+outline (+ dusk windows)
picks = [("Tavern (wheel)", "bld_tavern_s23", 72), ("Blacksmith", "bld_smith_s22", 70), ("Church (new)", "bld_church_s22", 84)]
S = 3
sh = Image.new("RGBA", (1700, 3 * 380 + 30), (30, 27, 40, 255)); d = ImageDraw.Draw(sh)
d.text((6, 8), "raw AI 1024  ->  native grid (8 px cells)  ->  fitted to the map slot, 74-colour palette, 1 px outline  ->  dusk (lit windows)   [3x]", fill=TXT)
for j, (lab, f, w) in enumerate(picks):
    r = T.building(f, w); y = 30 + j * 380
    sh.paste(r["raw"].resize((360, 360)), (6, y))
    n = r["native"]; sh.alpha_composite(n.resize((n.width * S, n.height * S), Image.NEAREST), (380, y))
    fi = r["final"]; sh.alpha_composite(fi.resize((fi.width * S, fi.height * S), Image.NEAREST), (380 + n.width * S + 20, y))
    dk = T.dusk(T.light_windows(fi)); sh.alpha_composite(dk.resize((fi.width * S, fi.height * S), Image.NEAREST), (380 + n.width * S + fi.width * S + 40, y))
    d.text((1450, y + 150), f"{lab}\n{f}\nnative {n.size[0]}x{n.size[1]} -> {fi.size[0]}x{fi.size[1]} art px\ncolours {P.colours(fi)}", fill=TXT)
    full = T.building(f, None)["final"]  # the separate sprite keeps its native size (no shrink)
    full.resize((full.width * 2, full.height * 2), Image.NEAREST).save(OUT + f"/building_{f.split('_')[1]}.png")
sh.save(OUT + "/town_buildings.png")
print("ok")
