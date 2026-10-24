"""Code-drawn 3/4 top-down building guides (roof seen from above + front wall below), one per unique
building, at art-pixel size; img2img + canny turns each into a detailed pixel sprite with the same shape.
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OL = (14, 8, 18)
ROOF = {"slate": ((58, 68, 102), (38, 43, 68), (90, 105, 136)), "red": ((162, 38, 51), (115, 30, 40), (190, 74, 47)),
        "thatch": ((163, 130, 95), (106, 74, 40), (200, 176, 138)), "brown": ((115, 62, 57), (62, 39, 49), (143, 86, 59)),
        "green": ((86, 106, 86), (52, 70, 56), (127, 148, 120)), "stone": ((98, 95, 106), (74, 72, 82), (125, 135, 152))}
WALL = {"timber": ((200, 176, 138), (106, 74, 40)), "stone": ((125, 135, 152), (84, 93, 112)),
        "brick": ((168, 98, 74), (115, 62, 57)), "wood": ((143, 86, 59), (90, 63, 53)), "dark": ((84, 93, 112), (52, 50, 59))}


def building(w, h, roof="slate", wall="timber", kind="gable", wall_frac=0.42, door=True, windows=2, chimney=True,
             extra=None):
    im = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    rc, rd, rl = ROOF[roof]; wc, wd = WALL[wall]
    wh = int(h * wall_frac); ry1 = h - wh
    # front wall
    d.rectangle((1, ry1, w, h), fill=wc)
    if wall == "timber":
        for x in range(1, w, 8):
            d.line((x, ry1, x, h), fill=wd)
        d.line((1, ry1 + wh // 2, w, ry1 + wh // 2), fill=wd)
    elif wall in ("stone", "brick", "dark"):
        for y in range(ry1 + 2, h, 3):
            d.line((1, y, w, y), fill=wd)
    else:
        for x in range(1, w, 3):
            d.line((x, ry1, x, h), fill=wd)
    d.rectangle((1, h - 1, w, h), fill=wd)
    # roof seen from above
    if kind == "gable":
        d.rectangle((0, 1, w + 1, ry1), fill=rc)
        d.rectangle((0, 1, w + 1, ry1 // 3), fill=rd)          # far slope (darker)
        d.line((0, ry1 // 3, w + 1, ry1 // 3), fill=rl)        # ridge
        for y in range(ry1 // 3 + 3, ry1, 3):
            d.line((0, y, w + 1, y), fill=rd)
        d.line((0, ry1, w + 1, ry1), fill=OL)
    elif kind == "hip":
        d.polygon([(0, ry1), (w // 4, 1), (w - w // 4, 1), (w + 1, ry1)], fill=rc)
        d.polygon([(0, ry1), (w // 4, 1), (w // 4, ry1)], fill=rl)
        d.line((w // 4, 1, w - w // 4, 1), fill=rl)
    elif kind == "flat":
        d.rectangle((0, 1, w + 1, ry1), fill=rc)
        for x in range(0, w + 1, 4):
            d.rectangle((x, 1, x + 1, 3), fill=rl)
        d.rectangle((3, 5, w - 2, ry1 - 3), fill=rd)
    elif kind == "cone":
        d.polygon([(w // 2, 0), (w + 1, ry1), (0, ry1)], fill=rc); d.polygon([(w // 2, 0), (w // 2, ry1), (0, ry1)], fill=rl)
    if chimney:
        d.rectangle((w - 10, 0, w - 6, 6), fill=(115, 62, 57)); d.rectangle((w - 10, 0, w - 6, 1), fill=OL)
    # door and windows
    if door:
        dx = w // 2 - 3
        d.rectangle((dx, h - min(10, wh - 2), dx + 6, h - 1), fill=(62, 39, 49)); d.rectangle((dx + 1, h - min(10, wh - 2) + 1, dx + 5, h - 1), fill=(90, 63, 53))
    for i in range(windows):
        cx = int((i + 0.5) * w / windows)
        if abs(cx - w // 2) < 7:
            continue
        d.rectangle((cx - 3, ry1 + 3, cx + 2, ry1 + 7), fill=(24, 20, 37)); d.rectangle((cx - 3, ry1 + 3, cx + 2, ry1 + 3), fill=(106, 74, 40))
    if extra:
        extra(d, w, h, ry1)
    return outline(im)


def outline(im):
    a = np.array(im); op = a[..., 3] > 0
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(op, dy, 0), dx, 1)
    a[ring & ~op] = OL + (255,)
    return Image.fromarray(a)


def wheel(d, w, h, ry1):
    cx, cy, r = w // 2 + 14, ry1 + (h - ry1) // 2, 8
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(143, 86, 59), outline=(62, 39, 49))
    for a in range(0, 180, 45):
        import math
        dx, dy = int(r * math.cos(math.radians(a))), int(r * math.sin(math.radians(a)))
        d.line((cx - dx, cy - dy, cx + dx, cy + dy), fill=(254, 174, 52))


def forge(d, w, h, ry1):
    d.rectangle((4, h - 9, 14, h - 1), fill=(24, 20, 37)); d.rectangle((6, h - 6, 12, h - 2), fill=(247, 118, 34))
    d.rectangle((w - 14, h - 5, w - 6, h - 3), fill=(74, 72, 82))


def awning(d, w, h, ry1):
    for i, x in enumerate(range(2, w - 1, 4)):
        d.rectangle((x, ry1, x + 3, ry1 + 4), fill=(162, 38, 51) if i % 2 == 0 else (234, 212, 170))


def banners(d, w, h, ry1):
    for x in (8, w - 10):
        d.rectangle((x, ry1 + 2, x + 3, ry1 + 12), fill=(162, 38, 51)); d.point((x + 1, ry1 + 6), fill=(254, 174, 52))


def iron_door(d, w, h, ry1):
    d.rectangle((w // 2 - 5, h - 11, w // 2 + 5, h - 1), fill=(52, 50, 59))
    for y in range(h - 10, h, 3):
        d.line((w // 2 - 5, y, w // 2 + 5, y), fill=(98, 95, 106))
    d.point((w // 2, h - 6), fill=(254, 174, 52))


def pen(d, w, h, ry1):
    d.line((w - 14, h - 6, w, h - 6), fill=(106, 74, 40))
    for x in range(w - 14, w + 1, 3):
        d.line((x, h - 9, x, h - 3), fill=(154, 112, 64))


def balcony(d, w, h, ry1):
    d.rectangle((6, ry1 + 9, w - 6, ry1 + 10), fill=(106, 74, 40))
    for x in range(6, w - 5, 3):
        d.point((x, ry1 + 8), fill=(154, 112, 64))


def shrine(d, w, h, ry1):
    # dungeon entrance: a dark arch with steps going down, candles either side
    d.rectangle((w // 2 - 12, ry1 - 4, w // 2 + 12, h), fill=(84, 93, 112))
    d.chord((w // 2 - 9, ry1 - 2, w // 2 + 9, ry1 + 16), 180, 360, fill=(14, 8, 18)); d.rectangle((w // 2 - 9, ry1 + 7, w // 2 + 9, h - 1), fill=(14, 8, 18))
    for i, y in enumerate(range(h - 8, h, 2)):
        d.line((w // 2 - 8 + i, y, w // 2 + 8 - i, y), fill=(74, 72, 82))
    for x in (w // 2 - 16, w // 2 - 14, w // 2 + 14, w // 2 + 16):
        d.rectangle((x, h - 6, x, h - 3), fill=(244, 230, 196)); d.point((x, h - 7), fill=(254, 231, 97))
    d.rectangle((w // 2 - 11, ry1 - 7, w // 2 + 11, ry1 - 5), fill=(254, 174, 52))


B = {
    "inn": dict(w=72, h=60, roof="slate", wall="timber", windows=4, extra=balcony),
    "smith": dict(w=56, h=50, roof="brown", wall="stone", windows=1, extra=forge),
    "tavern": dict(w=62, h=54, roof="red", wall="wood", windows=2, extra=wheel),
    "vault": dict(w=44, h=42, roof="stone", wall="dark", kind="flat", chimney=False, windows=0, door=False, extra=iron_door),
    "guild": dict(w=80, h=66, roof="red", wall="stone", kind="hip", windows=4, extra=banners),
    "shop": dict(w=46, h=42, roof="green", wall="timber", windows=2, extra=awning),
    "clinic": dict(w=54, h=44, roof="thatch", wall="wood", kind="hip", windows=2, extra=pen),
    "dungeon": dict(w=64, h=46, roof="stone", wall="dark", kind="flat", chimney=False, door=False, windows=0, wall_frac=0.6, extra=shrine),
    "house_a": dict(w=44, h=40, roof="slate", wall="stone", windows=2),
    "house_b": dict(w=38, h=36, roof="thatch", wall="timber", kind="hip", windows=1, chimney=False),
    "house_c": dict(w=34, h=44, roof="red", wall="brick", windows=1, wall_frac=0.5),
    "house_d": dict(w=50, h=42, roof="brown", wall="timber", windows=3, extra=balcony),
    "house_e": dict(w=42, h=38, roof="green", wall="wood", kind="hip", windows=2),
    "tower": dict(w=26, h=44, roof="slate", wall="stone", kind="cone", chimney=False, windows=1, door=False, wall_frac=0.55),
}
PROMPT = {
    "inn": "a wide two-story half-timbered inn with a dark slate roof, a wooden balcony and warm windows",
    "smith": "a stone blacksmith forge with a brown shingle roof, a glowing furnace opening and an anvil",
    "tavern": "a wooden tavern with a red tiled roof and a big carved fortune wheel on its front wall",
    "vault": "a squat fortified stone vault with a flat crenellated roof and a heavy iron door",
    "guild": "a large stone guild hall with a red hipped roof and red banners",
    "shop": "a small half-timbered shop with a green roof and a red striped awning",
    "clinic": "a thatched wooden cottage animal clinic with a little fenced pen",
    "dungeon": "a dark stone dungeon entrance shrine: an arch with stairs going down into darkness, candles and a memorial plaque",
    "house_a": "a stone cottage with a blue slate roof",
    "house_b": "a tiny thatched timber cottage",
    "house_c": "a narrow tall brick house with a red tiled roof",
    "house_d": "a half-timbered house with a brown roof and a balcony",
    "house_e": "a wooden house with a mossy green hipped roof",
    "tower": "a round stone castle wall watchtower with a pointed slate roof, facing outward",
}

if __name__ == "__main__":
    import json
    jobs = []
    NEG = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, landscape, gradient background, people, characters, isometric grid, side view, front elevation only"
    T = "pixel art top-down rpg town map building, three-quarter overhead view showing the roof from above and the front wall below, {d}, dark fantasy medieval town, plain white background, crisp pixels, dark outline"
    for k, kw in B.items():
        im = building(**kw); im.save(rf"C:\ai\art_work3\b_{k}.png")
        c = Image.new("RGB", (1024, 1024), (255, 255, 255))
        big = im.resize((im.width * 8, im.height * 8), Image.NEAREST)
        c.paste(big, ((1024 - big.width) // 2, (1024 - big.height) // 2), big); c.save(rf"C:\ai\art_work3\b_{k}_1024.png")
        c.convert("L").filter(ImageFilter.FIND_EDGES).point(lambda v: 255 if v > 30 else 0).save(rf"C:\ai\art_work3\b_{k}_canny.png")
        jobs.append({"name": f"t3_{k}", "seeds": [801, 802], "init": rf"C:/ai/art_work3/b_{k}_1024.png", "denoise": 0.6,
                     "pose": rf"C:/ai/art_work3/b_{k}_canny.png", "cn": "xinsir-canny-sdxl-1.0-v2.safetensors", "pose_strength": 0.45, "pose_end": 0.6,
                     "neg": NEG, "prompt": T.format(d=PROMPT[k])})
    json.dump(jobs, open(r"C:\ai\art_work3\jobs_t3.json", "w"), indent=1)
    sheet = Image.new("RGBA", (900, 220), (200, 200, 200, 255)); x = 0
    for k in B:
        im = Image.open(rf"C:\ai\art_work3\b_{k}.png")
        if x + im.width * 2 > 900: break
        sheet.alpha_composite(im.resize((im.width * 2, im.height * 2), Image.NEAREST), (x, 0)); x += im.width * 2 + 6
    sheet.save(r"C:\ai\art_work3\bguides.png")
    print(len(jobs))
