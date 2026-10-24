"""Style test v2: pets (PET1-3) and the walled-town concept (numbered), phone views.
Usage: python -I make_v2b.py OUT_DIR"""
import sys
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P, town2 as T
from make_v2 import piece_sheet, F, FR, TXT, DIM, ACC, BG, text, zoom

OUT = sys.argv[1]
PETS = [("PET1", "Lantern bat", "pet2_1_s761"), ("PET2", "Moss slime", "pet2_2_s762"), ("PET3", "Skull pup", "pet2_3_s761")]


def pet(name):
    raw, figs = P.figures(f"C:/ai/art_raw/{name}.png", hmax=60)
    f = max(figs, key=lambda g: g["img"].width * g["img"].height)["img"]
    return P.clean_figure(f, height=32, max_colors=14)


def badge(d, x, y, n, label=None):
    r = 15
    d.ellipse((x - r, y - r, x + r, y + r), fill=(14, 8, 18), outline=ACC, width=3)
    s = str(n); text(d, (x - 6 * len(s), y - 12), s, 22, ACC)
    if label:
        w = d.textlength(label, font=F[18])
        d.rectangle((x + r + 2, y - 12, x + r + 10 + w, y + 12), fill=(14, 8, 18))
        text(d, (x + r + 6, y - 11), label, 18)


def main():
    piece_sheet("08  Sample pets (PET1-PET3)", "Chibi, chunky, 1 px dark outline, few colours, big eyes - in our palette. img2img re-drawn at true 32 px.",
                [(c, l, pet(n)) for c, l, n in PETS], OUT + "/08_pets.png", z=6, cols=3)
    day, placed = T.compose()
    dusk = T.dusk_version(day, placed)
    D2, N2 = zoom(day, 2), zoom(dusk, 2)
    D2.save(OUT + "/09_town_day.png"); N2.save(OUT + "/10_town_dusk.png")
    # numbered key (on the dusk-free day map, 2x)
    key = D2.copy(); d = ImageDraw.Draw(key)
    for by, s, at, k, lab, n in placed:
        if n is None:
            continue
        if s is not None:
            cx, cy = (at[0] + s.width // 2) * 2, (at[1] + 6) * 2
        else:
            cx, cy = at[0] * 2, at[1] * 2
        badge(d, cx, cy, n, lab)
    # story callouts
    for (x, y, lab) in ((T.WX0 * 2 + 40, 470, "sealed gate - no road out"), (60, 26, "fog beyond the walls"),
                        (1300, 230, "dungeon: the one way out"), (900, 64, "watchtowers face OUT")):
        w = d.textlength(lab, font=F[18]); d.rectangle((x - 4, y - 4, x + w + 6, y + 24), fill=(14, 8, 18)); text(d, (x, y - 2), lab, 18, (255, 176, 176))
    key.save(OUT + "/11_town_key.png")
    # phone views (430x932): the town at 2x is 880 px tall, so it fits; swipe sideways
    for name, x0, src in (("12_town_phone_gate_dusk", 0, N2), ("13_town_phone_market_dusk", 470, N2), ("14_town_phone_dungeon_dusk", 1300, N2)):
        ph = Image.new("RGBA", (430, 932), (14, 8, 18, 255)); dd = ImageDraw.Draw(ph)
        ph.alpha_composite(src.crop((x0, 0, x0 + 430, 880)), (0, 52))
        dd.rectangle((0, 0, 430, 52), fill=(28, 24, 40)); text(dd, (14, 12), "Town (swipe)  " + name.split("_")[3], 22)
        for i in range(5):
            dd.ellipse((165 + i * 22, 912, 177 + i * 22, 924), fill=ACC if i == {0: 0, 470: 2, 1300: 4}[x0] else (90, 84, 110))
        ph.save(OUT + f"/{name}.png")
    print("town done")


if __name__ == "__main__":
    main()
