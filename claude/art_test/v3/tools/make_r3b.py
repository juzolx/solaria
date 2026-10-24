"""Round 3b sheets: faces F, race silhouettes R, heroes 32 vs 48 + portraits, mockups 32/48, gear G, M1 v2.
Usage: python -I make_r3b.py OUT"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts"); sys.path.insert(0, r"C:\ai\art_work3")
import pixlib as P, heroes4 as H, details as D, anim as A
from make_v2 import text, zoom, crop_fig, F, FR, TXT, DIM, ACC, BG, PANEL, REPO, mon, piece_sheet
import guides4 as G

OUT = sys.argv[1]
RACES = ["human", "elf", "orc", "dwarf", "goblin"]
NM = {"human": "Human", "elf": "Elf", "orc": "Orc", "dwarf": "Dwarf", "goblin": "Goblin"}
WPN = D.weapons()


def sheet(title, sub, rows, out, colw=200):
    """rows: [(row label, [(code, image, zoom)])] -> one image, big labels; game size (x2) + zoom side by side."""
    W = 1080
    hs = []
    for _, items in rows:
        hs.append(max(max(im.height * z for _, im, z in items), 90) + 70)
    sh = Image.new("RGBA", (W, 120 + sum(hs)), BG); d = ImageDraw.Draw(sh)
    text(d, (24, 18), title, 34); text(d, (24, 66), sub, 18, DIM, FR)
    y = 120
    for (lab, items), hh in zip(rows, hs):
        d.rectangle((8, y + 2, W - 8, y + hh - 6), fill=PANEL)
        text(d, (20, y + 8), lab, 22, TXT)
        x = 20
        for code, im, z in items:
            text(d, (x, y + 36), code, 22, ACC)
            zz = zoom(im, z); sh.alpha_composite(zz, (x, y + 62))
            x += max(zz.width, 60) + 16
        y += hh
    sh.save(out)


def heads(size):
    """front and back heroes for every race at this size (dict)."""
    return {(r, v): H.hero(r, v, size) for r in RACES for v in ("back", "front")}


def head_crop(im, race, view, size):
    k = 1.0 if size == 48 else 2 / 3
    p = G.R[race]
    top = int((G.FEET - p["h"] - 6) * k); bot = int((G.FEET - p["h"] + p["hh"] + 4) * k)
    return im.crop((0, max(0, top), im.width, bot))


def m1_v2():
    raw, figs = P.figures("C:/ai/art_raw/m1b_grendel_s843.png", hmax=70)
    base = max(figs, key=lambda g: g["img"].width * g["img"].height)["img"]
    a = P.to_np(base).copy()
    rgb = a[..., :3].astype(int)
    a[(rgb.min(-1) > 200), 3] = 0                                   # white holes between the arms -> clear
    step1 = P.to_im(a)
    q = P.quantize(P.strip_shadow(step1), 12)                       # 10-14 colours rule
    q = D.rule_passes(P.outline(q)).crop((1, 1, q.width + 1, q.height + 1))
    b = P.to_np(q).copy()
    ox, oy = 0, 0
    def put(x, y, col):
        if 0 <= y < b.shape[0] and 0 <= x < b.shape[1]:
            b[y, x, :3] = col; b[y, x, 3] = 255
    INK, EYE, EYE2, TOOTH, CLAW = D.c("181425"), D.c("fee761"), D.c("f77622"), D.c("f4e6c4"), D.c("c0cbdc")
    for ex in (11, 16):                                             # glowing eyes, 2 px with a hot core
        put(ex, 6, EYE); put(ex - 1 if ex < 14 else ex + 1, 6, EYE2); put(ex, 5, INK)
    for x in range(12, 17):                                         # open maw + teeth
        put(x, 9, INK); put(x, 10, INK)
    for x in (12, 14, 16):
        put(x, 9, TOOTH)
    put(13, 10, D.c("a22633")); put(15, 10, D.c("a22633"))
    for (x, y) in ((1, 24), (3, 25), (5, 24), (20, 24), (22, 25), (24, 24)):   # claws on both hands
        put(x, y, CLAW); put(x, y + 1, INK)
    hand = P.to_im(b)
    # dithering only on the main shade transition of the body
    keys, cnt = np.unique(b[..., :3][b[..., 3] > 0].reshape(-1, 3), axis=0, return_counts=True)
    order = [tuple(k) for k in keys[np.argsort(-cnt)] if tuple(k) != P.OUTLINE][:3]
    dith = D.dither_band(hand, [(order[0], order[1])]) if len(order) >= 2 else hand
    final = P.rim(P.outline(dith, edge_ink=False))
    return [("AI base", base), ("holes out, 12 colours", q), ("hand fixes", hand), ("dither + outline", final)], final


def mockup(hero, out, label):
    W, Hh = 430, 932
    s = Image.new("RGBA", (W, Hh), (14, 8, 18, 255)); d = ImageDraw.Draw(s)
    bg = zoom(Image.open(fr"{REPO}\art\bg\zone_1.png").convert("RGBA"), 3)
    s.alpha_composite(bg.crop((265, 0, 265 + W, 540)), (0, 96))
    d.rectangle((0, 0, W, 96), fill=(28, 24, 40)); text(d, (16, 18), "Sunken Catacombs  -  Floor 7", 22); text(d, (16, 54), label, 18, ACC, FR)
    m = mon("draugr"); m = m.resize((m.width * 3 // 2, m.height * 3 // 2), Image.NEAREST)   # 3 px per art px
    s.alpha_composite(m, (W // 2 - m.width // 2 + 50, 96 + 395 - m.height))
    hh = zoom(crop_fig(hero), 3)
    s.alpha_composite(hh, (70, 96 + 540 - hh.height - 6))
    d.rectangle((0, 646, W, Hh), fill=(28, 24, 40))
    for i, (nm, hp) in enumerate((("Hero", 0.8), ("Ally", 0.55), ("Pet", 0.9))):
        y = 668 + i * 46
        text(d, (18, y), nm, 18); d.rectangle((90, y + 4, 400, y + 20), fill=(62, 39, 49)); d.rectangle((90, y + 4, 90 + int(310 * hp), y + 20), fill=(62, 137, 72))
    text(d, (40, 905), "same pixel scale for hero and monster (3x)", 18, DIM, FR)
    s.save(out)


def fist(im):
    a = P.to_np(im)[..., 3] > 0
    h = a.shape[0]
    band = a[: int(h * 0.6)]
    ys, xs = np.where(band)
    i = xs.argmax()
    return int(xs[i]) - 1, int(ys[i]) + 1


def off_hand(im):
    a = P.to_np(im)[..., 3] > 0
    h = a.shape[0]
    band = a[int(h * 0.45): int(h * 0.8)]
    ys, xs = np.where(band)
    i = xs.argmin()
    return int(xs[i]) + 1, int(ys[i]) + int(h * 0.45)


def armed(body, wname, pad=12):
    c = Image.new("RGBA", (body.width + 2 * pad, body.height + 2 * pad), (0, 0, 0, 0))
    w, g = WPN[wname]
    if wname == "shield":
        x, y = off_hand(body)
        c.alpha_composite(body, (pad, pad)); c.alpha_composite(w, (pad + x - w.width // 2 - 1, pad + y - g[1]))
        return crop_fig(c)
    x, y = fist(body)
    ang = {"sword": -30, "axe": -15, "mace": -15, "spear": -40, "bow": 0, "staff": -10, "orb": 0, "tome": 0, "dagger": -30}[wname]
    c = A.paste_weapon(c, w, g, ang, (pad + x, pad + y))
    c.alpha_composite(body, (pad, pad))
    if wname in ("sword", "axe", "mace", "spear", "dagger", "staff"):   # the fist goes over the grip
        b = P.to_np(body)
        fx0, fy0 = max(0, x - 1), max(0, y - 2)
        c.alpha_composite(P.to_im(b[fy0:y + 2, fx0:x + 3]), (pad + fx0, pad + fy0))
    return crop_fig(c)


def main():
    os.makedirs(OUT, exist_ok=True)
    h32, h48 = heads(32), heads(48)
    # F: faces close-ups (code-stamped)
    rows = [("Front faces, 32 px (F1-F5)", [(f"F{i + 1}", head_crop(h32[(r, 'front')], r, "front", 32), 6) for i, r in enumerate(RACES)]),
            ("Front faces, 48 px (F6-F10)", [(f"F{i + 6}", head_crop(h48[(r, 'front')], r, "front", 48), 4) for i, r in enumerate(RACES)]),
            ("Back 3/4 face slivers, 48 px (F11-F15)", [(f"F{i + 11}", head_crop(h48[(r, 'back')], r, "back", 48), 4) for i, r in enumerate(RACES)])]
    sheet("R3b-1  Faces drawn in code (F1-F15)", "AI draws body and gear only. Eyes (with a highlight), brows, nose shadow, mouth, tusks, goblin nose are stamped from a code library.", rows, OUT + "/R3b_1_faces.png")
    # R: silhouettes
    def sil(im):
        a = P.to_np(im).copy(); a[a[..., 3] > 0, :3] = (14, 8, 18); return P.to_im(a)
    rows = [("Back, 32 px: black silhouette (R1-R5)", [(f"R{i + 1}", sil(h32[(r, 'back')]), 4) for i, r in enumerate(RACES)]),
            ("Back, 32 px: coloured", [(NM[r][:3], h32[(r, 'back')], 4) for r in RACES]),
            ("Front, 32 px: silhouette + colour (R6-R10)", [(f"R{i + 6}", sil(h32[(r, 'front')]), 3) for i, r in enumerate(RACES)] + [("", h32[(r, 'front')], 3) for r in RACES[:0]]),
            ("Front, 32 px: coloured", [(NM[r][:3], h32[(r, 'front')], 3) for r in RACES])]
    sheet("R3b-2  Races by silhouette (R1-R10)", "Human baseline / Elf slender + long ears + long hair / Orc tall + bulky + topknot / Dwarf short + WIDE + beard + helmet / Goblin small + hunched + huge ears + long nose.", rows, OUT + "/R3b_2_race_silhouettes.png")
    # H: 32 vs 48
    rows = [("Back view, 32 px tall (H1-H5)", [(f"H{i + 1}", h32[(r, 'back')], 4) for i, r in enumerate(RACES)]),
            ("Back view, 48 px tall (H6-H10)", [(f"H{i + 6}", h48[(r, 'back')], 3) for i, r in enumerate(RACES)])]
    sheet("R3b-3  Size test: 32 px vs 48 px heroes", "Same races and method. 48 px is closer to the farm-game characters; 32 px matches today's monster grid.", rows, OUT + "/R3b_3_heroes_32_vs_48.png")
    rows = [("Portraits, 32 px (P1-P5)", [(f"P{i + 1}", h32[(r, 'front')], 4) for i, r in enumerate(RACES)]),
            ("Portraits, 48 px (P6-P10)", [(f"P{i + 6}", h48[(r, 'front')], 3) for i, r in enumerate(RACES)])]
    sheet("R3b-4  Portraits 32 vs 48 (P1-P10)", "Front view with code faces. Female dwarves would get braids, no beard (not drawn yet).", rows, OUT + "/R3b_4_portraits.png")
    mockup(armed(h32[("human", "back")], "sword"), OUT + "/R3b_5_mockup_32px.png", "32 px hero (same scale as monsters)")
    mockup(armed(h48[("human", "back")], "sword"), OUT + "/R3b_6_mockup_48px.png", "48 px hero (bigger art, same pixel scale)")
    # G: gear
    base = H.hero("human", "back", 32)
    names = ["sword", "axe", "mace", "spear", "bow", "staff", "orb", "tome", "dagger", "shield"]
    rows = [("Weapons and off-hands on the same hero, from behind (G1-G5)", [(f"G{i + 1}", armed(base, n), 4) for i, n in enumerate(names[:5])]),
            ("(G6-G10)", [(f"G{i + 6}", armed(base, n), 4) for i, n in enumerate(names[5:])])]
    sheet("R3b-7  Gear: weapons (G1-G10)", "sword, axe, mace, spear, bow / staff, orb, tome, dagger, shield. Code-drawn in the palette, pinned to the hand; goblins carry full-size weapons.", rows, OUT + "/R3b_7_gear_weapons.png")
    sets = {"cloth": ("v4g_cloth_back_s862", "v4g_cloth_front_s862"), "leather": ("v4g_leather_back_s862", "v4g_leather_front_s861"),
            "plate": ("v4g_plate_back2_s883", "v4g_plate_front_s861")}
    ims = {}
    for k, (b, f) in sets.items():
        ims[k] = (H.hero("human", "back", 32, name=b), H.hero("human", "front", 32, name=f))
    rows = [("Armour sets from behind (G11-G13)", [(f"G{11 + i}", armed(ims[k][0], "sword"), 4) for i, k in enumerate(sets)]),
            ("Armour sets as portraits", [(k, ims[k][1], 4) for k in sets])]
    sheet("R3b-8  Gear: armour sets (G11-G13)", "Cloth, leather, plate change the body shape (chest/helmet change shape; legs and feet only recolour).", rows, OUT + "/R3b_8_gear_armour.png")
    neck_b, neck_f = 12, 13
    rows = [("Rarity on plate, from behind (G14-G19)", [(f"G{14 + i}", D.rarity(armed(ims['plate'][0], 'sword'), i, neck_b), 4) for i in range(6)][:3]),
            ("", [(f"G{17 + i}", D.rarity(armed(ims['plate'][0], 'sword'), i + 3, neck_b), 4) for i in range(3)]),
            ("Rarity as portraits (Common .. Mythic)", [(D.TIERS[i][0][:4], D.rarity(ims['plate'][1], i, neck_f), 3) for i in range(6)])]
    sheet("R3b-9  Gear: rarity tiers (G14-G19)", "Plain: Common grey / Uncommon green trim. Fine: Rare 1 band, Epic 2 bands + gem (same shape). Ornate: Legendary spikes. Mythic: runes, glow + motes (only Mythic glows). Colour from rarity only.", rows, OUT + "/R3b_9_gear_rarity.png")
    steps, final = m1_v2()
    rows = [("M1 v2: AI base -> cleanup -> hand fixes -> dither + outline", [(f"{i + 1}", im, 6) for i, (lab, im) in enumerate(steps)]),
            ("M1 at game scale next to the draugr (2x)", [("M1", final, 2), ("draugr", P.to_im(P.to_np(mon("draugr"))[::2, ::2]), 2)])]
    sheet("R3b-10  Monster sample M1 v2 (Grendel)", "Handheld battle-sprite look: bold outline, 12 colours, dithering only on the shade transition; eyes, maw, teeth and claws placed by hand in code.", rows, OUT + "/R3b_10_monster_M1.png")
    print("done")


if __name__ == "__main__":
    main()
