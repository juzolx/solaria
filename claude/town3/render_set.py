"""Numbered mockup set for Juzo's review. Usage: py render_set.py <out_dir>"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont
import compose as C
import decor as D
from layout import LOTS

FONT = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)


def town(level=3, hardcore=False, empty=()):
    D.LEVEL, D.HARDCORE = level, hardcore
    C.HARDCORE.clear()
    if hardcore:
        C.HARDCORE.append(True)
    C.EMPTY.clear()
    C.EMPTY.update(empty)
    D.LIGHTS.clear()
    day = C.compose()
    return day, C.dusk(day)


def view(img):
    return img.convert("RGB").crop((40, 140, C.W - 40, C.H - 60))


def tag(img, text):
    img = img.convert("RGB")
    d = ImageDraw.Draw(img)
    d.text((10, 8), text, font=FONT, fill="white", stroke_width=3, stroke_fill="black")
    return img


def strip(images, labels, gap=8):
    w = sum(i.width for i in images) + gap * (len(images) - 1)
    h = max(i.height for i in images)
    s = Image.new("RGB", (w, h), (10, 10, 14))
    x = 0
    for im, lb in zip(images, labels):
        s.paste(tag(im, lb), (x, 0))
        x += im.width + gap
    return s


def crop_lot(img, lid, pad=60, top=170):
    l = next(l for l in LOTS if l[0] == lid)
    _, _, x0, y0, x1, y1, _, _ = l
    xs = [C.at(x0, y1 + 1)[0], C.at(x1 + 1, y0)[0]]
    ys = [C.at(x0, y0)[1], C.at(x1 + 1, y1 + 1)[1]]
    box = (min(xs) - pad, min(ys) - top, max(xs) + pad, max(ys) + pad // 2)
    return img.convert("RGB").crop(box).resize(((box[2] - box[0]) * 2, (box[3] - box[1]) * 2), Image.NEAREST)


def main(out):
    os.makedirs(out, exist_ok=True)
    n = [0]

    def save(img, name):
        n[0] += 1
        img.save(f"{out}/{n[0]:02d}_{name}.png")

    day3, dusk3 = town(3)
    save(view(dusk3), "town_dusk_all_level3")
    save(view(day3), "town_day_all_level3")
    for scale in (2, 3):
        for name, (i, j) in (("square", (20, 19)), ("dungeon", (20, 9)), ("gate", (19, 32))):
            x, y = C.at(i, j)
            save(C.phone(dusk3, x, y, scale), f"phone_{scale}x_dusk_{name}")
    x, y = C.at(20, 19)
    save(C.phone(day3.convert("RGB"), x, y, 2), "phone_2x_day_square")
    day1, dusk1 = town(1, empty=("church", "cabin"))
    save(view(dusk1), "town_dusk_new_game_level1_empty_lots")
    hday, hdusk = town(3, hardcore=True)
    save(view(hdusk), "town_dusk_HARDCORE")
    x, y = C.at(6, 10)
    save(C.phone(hdusk, x, y, 2), "phone_2x_HARDCORE_church_graveyard")
    save(strip([crop_lot(dusk1, "church"), crop_lot(dusk3, "church"), crop_lot(hdusk, "church")],
               ["Church: empty lot", "built (Regular, holy)", "built (Hardcore, ruined)"]), "church_states")
    save(strip([crop_lot(dusk1, "cabin"), crop_lot(dusk3, "cabin")], ["Trophy Cabin: empty lot", "built"]), "trophy_cabin_states")
    day2, dusk2 = town(2)
    for lid in ("inn", "tavern", "smith", "shop", "guild", "stash", "clinic"):
        save(strip([crop_lot(day1, lid), crop_lot(day2, lid), crop_lot(day3, lid)],
                   [f"{lid} level 1", "level 2", "level 3"]), f"levels_{lid}")
    print("saved", n[0])


if __name__ == "__main__":
    main(sys.argv[1])
