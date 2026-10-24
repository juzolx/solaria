"""Round 3 deliverables: heroes (H1-H5 back, P1-P5 portraits, mockup), monster sample M1, town day/dusk/phone.
Usage: python -I make_v3.py OUT_DIR"""
import sys, os
import numpy as np
from PIL import Image, ImageDraw
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P, heroes3 as H, heroes as H1, anim as A
from make_v2 import piece_sheet, text, zoom, crop_fig, F, FR, TXT, DIM, ACC, BG, REPO, mon

OUT = sys.argv[1]
SW = H1.weapon("sword")[1]
CAN, ORG = (56, 54), (8, 8)
RACES = ["human", "elf", "orc", "dwarf", "goblin"]
NAMES = {"human": "Human", "elf": "Elf", "orc": "Orc", "dwarf": "Dwarf", "goblin": "Goblin"}


def hero(race, swing=0, dy=0, dx=0):
    base, arm = H.layers(race)
    b = H.BUILD[race]
    full = base.copy(); full.alpha_composite(arm)
    fist = H.fist_of(full, b)
    lay = Image.new("RGBA", CAN, (0, 0, 0, 0))
    g = H1.grip_of(SW, "sword")
    lay = A.paste_weapon(lay, SW, g, -35, (ORG[0] + fist[0], ORG[1] + fist[1]))
    lay.alpha_composite(arm, ORG)
    if swing:
        sh = H.SHOULDER[b]
        lay = A.rotsprite(lay, swing, (ORG[0] + sh[0], ORG[1] + sh[1]))
    c = Image.new("RGBA", CAN, (0, 0, 0, 0))
    c.alpha_composite(A.shift_rows(base, 26, dy, dx), ORG)
    l2 = Image.new("RGBA", CAN, (0, 0, 0, 0)); l2.paste(lay, (dx, dy), lay); c.alpha_composite(l2)
    return P.rim(P.outline(c))


def m1():
    best = None
    for sd in (841, 842, 843):
        raw, figs = P.figures(f"C:/ai/art_raw/m1b_grendel_s{sd}.png", hmax=70)
        if figs:
            f = max(figs, key=lambda g: g["img"].width * g["img"].height)["img"]
            if best is None or f.width * f.height > best[1].width * best[1].height:
                best = (sd, f)
    sd, f = best
    a = P.to_np(f).copy()  # white background pockets trapped inside the silhouette
    rgb = a[..., :3].astype(int)
    a[(rgb.min(-1) > 200) & ((rgb.max(-1) - rgb.min(-1)) < 20), 3] = 0
    return sd, P.clean_figure(P.to_im(a), height=34, max_colors=12)


def mockup(h, out):
    W, Hh = 430, 932
    s = Image.new("RGBA", (W, Hh), (14, 8, 18, 255)); d = ImageDraw.Draw(s)
    bg = zoom(Image.open(fr"{REPO}\art\bg\zone_1.png").convert("RGBA"), 3)
    s.alpha_composite(bg.crop((265, 0, 265 + W, 540)), (0, 96))
    d.rectangle((0, 0, W, 96), fill=(28, 24, 40)); text(d, (16, 18), "Sunken Catacombs  -  Floor 7", 22)
    text(d, (16, 54), "Round 3 hero in the battle screen (430x932)", 18, ACC, FR)
    # one scale for everything: 3 screen px per art px (68 px monster file = 2x art -> x1.5)
    m = mon("draugr"); m = m.resize((m.width * 3 // 2, m.height * 3 // 2), Image.NEAREST)
    s.alpha_composite(m, (W // 2 - m.width // 2 + 50, 96 + 395 - m.height))
    d.rectangle((W // 2 + 10, 96 + 385 - m.height, W // 2 + 110, 96 + 391 - m.height), fill=(162, 38, 51))
    hh = zoom(crop_fig(h), 3)
    s.alpha_composite(hh, (80, 96 + 540 - hh.height - 6))
    d.rectangle((0, 646, W, Hh), fill=(28, 24, 40))
    for i, (nm, hp) in enumerate((("Hero", 0.8), ("Ally", 0.55), ("Pet", 0.9))):
        y = 668 + i * 46
        text(d, (18, y), nm, 18); d.rectangle((90, y + 4, 400, y + 20), fill=(62, 39, 49)); d.rectangle((90, y + 4, 90 + int(310 * hp), y + 20), fill=(62, 137, 72))
    for i in range(4):
        d.rectangle((22 + i * 100, 820, 106 + i * 100, 900), fill=(46, 40, 64), outline=(90, 105, 136), width=2)
    text(d, (40, 905), "mockup UI; hero and monster at the same pixel scale", 18, DIM, FR)
    s.save(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    hs = [hero(r) for r in RACES]
    piece_sheet("R3-1  Heroes from behind (H1-H5)", "Look B slim armour + look C dark head. Hair, ear tip, topknot + tusk, iron cap + beard, big ears: race and facing readable from behind.",
                [(f"H{i + 1}", NAMES[r], im) for i, (r, im) in enumerate(zip(RACES, hs))], OUT + "/R3_1_heroes_back.png", z=5, cols=3)
    ps = [H.portrait(r) for r in RACES]
    piece_sheet("R3-2  Portraits (P1-P5)", "Front portraits for menus (P1 new: human with hair + slim armour; P2-P5 from round 2).",
                [(f"P{i + 1}", NAMES[r], im) for i, (r, im) in enumerate(zip(RACES, ps))], OUT + "/R3_2_portraits.png", z=5, cols=3)
    mockup(hs[0], OUT + "/R3_3_mockup_battle.png")
    # side-by-side scale check with the Catacombs monsters (all at the same pixel scale, 3x)
    sh = Image.new("RGBA", (1080, 560), BG); d = ImageDraw.Draw(sh)
    text(d, (24, 18), "R3-4  Scale check: heroes vs Catacombs (3x)", 34)
    x = 20
    for i, im in enumerate(hs):
        z = zoom(crop_fig(im), 3); sh.alpha_composite(z, (x, 250 - z.height)); text(d, (x, 256), f"H{i + 1}", 22, ACC); x += z.width + 30
    x = 20
    for mname in ("ghoul", "draugr", "barrow_wight", "banshee", "strigoi"):
        m = mon(mname); m = m.resize((m.width * 3 // 2, m.height * 3 // 2), Image.NEAREST)
        sh.alpha_composite(m, (x, 520 - m.height)); text(d, (x, 524), mname, 18, TXT, FR); x += m.width + 20
    sh.save(OUT + "/R3_4_scale_check.png")
    s, mm = m1()
    piece_sheet("R3-5  Monster direction sample (M1)", f"Original 'Grendel' in a classic handheld creature-battle look: bold outline, few colours, dithering, dynamic pose (seed {s}). Direction test only.",
                [("M1", "Grendel", mm)], OUT + "/R3_5_monster_M1.png", z=8, cols=1)
    print("heroes done")


if __name__ == "__main__":
    main()
