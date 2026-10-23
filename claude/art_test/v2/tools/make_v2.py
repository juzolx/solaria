"""Style test v2 deliverables (dark chibi, back three-quarter heroes, portraits, anim, pets, town).
Usage: python -I make_v2.py OUT_DIR
Every image is one topic, big labels, numbered pieces, each shown at game size AND zoomed.
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, r"C:\ai\scripts")
import pixlib as P, heroes2 as H, heroes as H1, anim as A

OUT = sys.argv[1]
REPO = r"C:\gamedev\solaria_wt_newart"
BG = (24, 20, 37, 255); PANEL = (34, 30, 48, 255); TXT = (236, 232, 244); DIM = (160, 152, 180); ACC = (254, 174, 52)
F = {s: ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", s) for s in (18, 22, 28, 34)}
FR = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
SW = H1.weapon("sword")[1]; ST = H1.weapon("staff")[1]
WPN = {None: ("sword", SW), "warrior": ("sword", SW), "ranger": ("sword", SW), "mage": ("staff", ST)}
CAN = (60, 60); ORG = (8, 14)  # hero frame (art px) and where the 40x42 window sits in it
GAME = 2                      # game files are 2x art


def mon(name):
    return Image.open(fr"{REPO}\art\enemies\{name}.png").convert("RGBA")


# ------------------------------------------------------------------ hero frames
def parts(race, outfit, look=None):
    base, arm = H.layers(race, outfit, look)
    full = base.copy(); full.alpha_composite(arm)
    build = H.BUILD[race]
    fist = H.fist_of(full, build)
    if look == "B":  # slim mannequin: the arm box sits ~1 px further in
        pass
    return base, arm, fist, build


def arm_layer(arm, fist, wname, wimg, angle, rest=-35):
    """Arm + weapon as one layer in frame coords, rotated by (angle - rest) around the shoulder."""
    lay = Image.new("RGBA", CAN, (0, 0, 0, 0))
    g = H1.grip_of(wimg, wname)
    hand = (ORG[0] + fist[0], ORG[1] + fist[1])
    lay = A.paste_weapon(lay, wimg, g, rest if wname == "sword" else -10, hand)
    lay.alpha_composite(arm, ORG)
    return lay


def frame(race, outfit, look=None, dy=0, dx=0, swing=0.0, waist=26):
    base, arm, fist, build = parts(race, outfit, look)
    wname, wimg = WPN[outfit]
    sh = H.SHOULDER[build]
    body = A.shift_rows(base, waist, dy, dx)
    c = Image.new("RGBA", CAN, (0, 0, 0, 0))
    lay = arm_layer(arm, fist, wname, wimg, 0)
    if swing:
        piv = (ORG[0] + sh[0], ORG[1] + sh[1])
        lay = A.rotsprite(lay, swing, piv)
    lay2 = Image.new("RGBA", CAN, (0, 0, 0, 0)); lay2.paste(lay, (dx, dy), lay)
    c.alpha_composite(body, ORG)
    c.alpha_composite(lay2)
    return H.finish(c)  # (CAN + 2) px, outlined, rim lit


def crop_fig(im, pad=1):
    bb = im.getbbox()
    return im.crop((bb[0] - pad, bb[1] - pad, bb[2] + pad, bb[3] + pad))


def zoom(im, z):
    return im.resize((im.width * z, im.height * z), Image.NEAREST)


def portrait(race):
    f = H.clean(H.PICK["front"][race], max_colors=20)
    f = H.reskin(f, race, slice(0, 22))
    f = P.rim(P.outline(f))
    return crop_fig(f, 0)


def text(d, xy, s, size=22, fill=TXT, font=None):
    d.text(xy, s, font=font or F[size], fill=fill)


# ------------------------------------------------------------------ sheet helpers
def piece_sheet(title, sub, items, out, z=5, cols=3, cell_h=None):
    """items: [(code, label, image)] -> each shown at game size (2x) and zoomed (z x art)."""
    W = 1080
    cw = W // cols
    ims = [(c, l, crop_fig(im) if im.getbbox() else im) for c, l, im in items]
    ch = cell_h or max(max(im.height for _, _, im in ims) * z + 90, 200)
    rows = (len(ims) + cols - 1) // cols
    sh = Image.new("RGBA", (W, 120 + rows * ch), BG); d = ImageDraw.Draw(sh)
    text(d, (24, 18), title, 34); text(d, (24, 66), sub, 18, DIM, FR)
    for i, (code, label, im) in enumerate(ims):
        x, y = (i % cols) * cw, 120 + (i // cols) * ch
        d.rectangle((x + 8, y + 4, x + cw - 8, y + ch - 8), fill=PANEL)
        text(d, (x + 20, y + 12), code, 28, ACC); text(d, (x + 20 + 14 * len(code) + 24, y + 18), label, 18)
        g = zoom(im, GAME)
        zz = zoom(im, z)
        sh.alpha_composite(g, (x + 20, y + ch - 20 - g.height))
        sh.alpha_composite(zz, (x + 30 + g.width + 10, y + 52))
        text(d, (x + 20, y + ch - 44 - g.height), "game", 18, DIM, FR)
    sh.save(out)


def mockup(hero, out, label, monster="draugr"):
    """Phone-size battle screen (430x932): zone 1 background, Catacombs monster above, hero at the bottom."""
    W, Hh = 430, 932
    s = Image.new("RGBA", (W, Hh), (14, 8, 18, 255)); d = ImageDraw.Draw(s)
    bg = Image.open(fr"{REPO}\art\bg\zone_1.png").convert("RGBA")
    bg3 = zoom(bg, 3)  # 960x540
    s.alpha_composite(bg3.crop((265, 0, 265 + W, 540)), (0, 96))
    # top bar
    d.rectangle((0, 0, W, 96), fill=(28, 24, 40)); text(d, (16, 18), "Sunken Catacombs  -  Floor 7", 22)
    text(d, (16, 54), label, 18, ACC, FR)
    m = zoom(mon(monster), 2)  # 68x68 file shown at 2x (4 px per art px, same as the hero)
    s.alpha_composite(m, (W // 2 - m.width // 2 + 40, 96 + 405 - m.height + 20))
    d.rectangle((W // 2 - 20, 96 + 300, W // 2 + 100, 96 + 308), fill=(62, 39, 49)); d.rectangle((W // 2 - 20, 96 + 300, W // 2 + 70, 96 + 308), fill=(162, 38, 51))
    h = zoom(crop_fig(hero), 2 * GAME // 2 * 2)  # 4 px per art px
    s.alpha_composite(h, (70, 96 + 540 - h.height + 10))
    # UI panel
    d.rectangle((0, 646, W, Hh), fill=(28, 24, 40))
    for i, (nm, hp) in enumerate((("Hero", 0.8), ("Ally", 0.55), ("Pet", 0.9))):
        y = 668 + i * 46
        text(d, (18, y), nm, 18); d.rectangle((90, y + 4, 400, y + 20), fill=(62, 39, 49)); d.rectangle((90, y + 4, 90 + int(310 * hp), y + 20), fill=(62, 137, 72))
    for i in range(4):
        x = 22 + i * 100
        d.rectangle((x, 820, x + 84, 900), fill=(46, 40, 64), outline=(90, 105, 136), width=2)
    text(d, (130, 905), "mockup - not the real UI", 18, DIM, FR)
    s.save(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    races = ["human", "elf", "orc", "dwarf", "goblin"]
    names = {"human": "Human", "elf": "Elf", "orc": "Orc", "dwarf": "Dwarf", "goblin": "Goblin"}
    rest = {}
    # 01 look variants (same race/outfit)
    A_ = frame("human", "warrior"); B_ = frame("human", "warrior", "B"); C_ = frame("human", "warrior", "C")
    piece_sheet("01  Pick a base look: A / B / C", "Human warrior, back three-quarter. A = chunky chibi (big head). B = slimmer, taller. C = darker, draugr-tinted armour + cloak.",
                [("A", "chunky chibi", A_), ("B", "slimmer", B_), ("C", "darker armour", C_)], OUT + "/01_variants_ABC.png", z=6, cols=3)
    for k, im in (("A", A_), ("B", B_), ("C", C_)):
        mockup(im, OUT + f"/02_mockup_{k}.png", f"Variant {k} in the battle screen (430x932)")
    # 03 races (base clothes, sword)
    items = [(f"H{i + 1}", names[r], frame(r, None)) for i, r in enumerate(races)]
    piece_sheet("03  Races, back view (H1-H5)", "Same pose for every race so layers line up. Plain clothes + sword. Face sliver, ears, tusk, beard hand-placed (2-5 px).",
                items, OUT + "/03_heroes_races.png", z=5, cols=3)
    # 04 outfits on two builds
    items = []
    n = 6
    for r in ("human", "dwarf"):
        for o in ("warrior", "mage", "ranger"):
            items.append((f"H{n}", f"{names[r]} {o}", frame(r, o))); n += 1
    piece_sheet("04  Outfits as layers (H6-H11)", "One outfit sprite per build (tall: human/elf/orc, short: dwarf/goblin), laid over any race body.",
                items, OUT + "/04_heroes_outfits.png", z=5, cols=3)
    # 05 portraits
    items = [(f"P{i + 1}", names[r], portrait(r)) for i, r in enumerate(races)]
    piece_sheet("05  Front portraits for menus (P1-P5)", "Same method, front mannequin. Shown at game size (2x) and 5x.",
                items, OUT + "/05_portraits.png", z=5, cols=3)
    # 06 weapons + layer breakdown
    base, arm, fist, build = parts("human", "warrior")
    lay = arm_layer(arm, fist, "sword", SW, 0)
    bl = Image.new("RGBA", CAN, (0, 0, 0, 0)); bl.alpha_composite(base, ORG)
    body_only = Image.new("RGBA", CAN, (0, 0, 0, 0)); body_only.alpha_composite(H.clean(H.PICK["race"]["human"], 20), ORG)
    piece_sheet("06  Weapons and layers (W1-W2, L1-L4)", "L1 race body, L2 + outfit (arm removed), L3 weapon arm + weapon (rotates at the shoulder), L4 all together.",
                [("W1", "sword", P.outline(SW)), ("W2", "staff", P.outline(ST)),
                 ("L1", "race body", P.outline(body_only)), ("L2", "+ outfit", P.outline(bl)), ("L3", "arm + weapon", P.outline(lay)),
                 ("L4", "composed", A_)], OUT + "/06_weapons_layers.png", z=4, cols=3)
    # heroes_layers.png: overview grid races x outfits (numbered by row/col)
    S = 3; outs = [None, "warrior", "mage", "ranger"]
    cw, ch = 62 * S + 20, 62 * S + 20
    g = Image.new("RGBA", (180 + cw * 4, 110 + ch * 5), BG); d = ImageDraw.Draw(g)
    text(d, (20, 16), "Layer grid: race x outfit (3x)", 34)
    for i, o in enumerate(outs):
        text(d, (180 + i * cw + 10, 70), o or "base", 22, ACC)
    for j, r in enumerate(races):
        text(d, (20, 110 + j * ch + ch // 2 - 12), f"H{j + 1} {names[r]}", 22)
        for i, o in enumerate(outs):
            g.alpha_composite(zoom(frame(r, o), S), (180 + i * cw, 110 + j * ch))
    g.save(OUT + "/heroes_layers.png")
    # heroes_vs_monsters.png: back heroes + portraits beside the Catacombs monsters, game scale (2x files), 2x view
    mons = ["ghoul", "draugr", "barrow_wight", "banshee", "strigoi"]
    V = 2
    sh = Image.new("RGBA", (1080, 1200), BG); d = ImageDraw.Draw(sh)
    text(d, (24, 18), "Heroes vs Zone 1 Catacombs (game scale x2)", 34)
    text(d, (24, 66), "Row 1: back view (H1-H5).  Row 2: portraits (P1-P5).  Row 3: the house-style monsters.", 18, DIM, FR)
    for row, ims in enumerate(([frame(r, o) for r, o in zip(races, ["warrior", "mage", "ranger", "warrior", "ranger"])],
                               [portrait(r) for r in races])):
        x = 30
        for k, im in enumerate(ims):
            z = zoom(zoom(crop_fig(im), GAME), V)
            y0 = 130 + row * 340
            sh.alpha_composite(z, (x, y0 + 300 - z.height))
            text(d, (x, y0 + 304), ("H" if row == 0 else "P") + str(k + 1), 22, ACC)
            x += 205
    x = 20
    for mname in mons:
        m = zoom(mon(mname), V)
        sh.alpha_composite(m, (x, 820 + 280 - m.height))
        text(d, (x, 1110), mname, 18, TXT, FR)
        x += 210
    sh.save(OUT + "/heroes_vs_monsters.png")
    # animation: idle 4 + attack 4 with the arm swinging
    idle = [frame("human", "warrior", dy=v, swing=s) for v, s in ((0, 0), (1, -3), (1, -5), (0, -2))]
    attack = [frame("human", "warrior", dx=-1, swing=55),            # wind-up: arm back over the head
              frame("human", "warrior", dx=1, dy=-1, swing=-40),     # strike toward the monster (up-right)
              frame("human", "warrior", dx=2, dy=-1, swing=-75),     # follow-through
              frame("human", "warrior", dx=1, swing=-20)]            # recover
    # smear on the strike frame: an arc of light pixels outside the body
    st = attack[1].copy(); dd = ImageDraw.Draw(st)
    sh_ = H.SHOULDER["tall"]; cx, cy = ORG[0] + sh_[0] + 2, ORG[1] + sh_[1]
    for r, col in ((18, (192, 203, 220, 255)), (19, (255, 255, 255, 255)), (17, (139, 155, 180, 255))):
        for t in range(0, 101):
            a = math.radians(0 + 95 * t / 100)
            x, y = round(cx + r * math.sin(a)), round(cy - r * math.cos(a))
            if 0 <= x < st.width and 0 <= y < st.height and st.getpixel((x, y))[3] == 0:
                dd.point((x, y), fill=col)
    attack[1] = P.rim(P.outline(st, edge_ink=False)).crop((1, 1, st.width + 1, st.height + 1))
    seq = idle + idle + attack + [idle[0]]
    durs = [250] * 8 + [180, 70, 110, 200, 250]  # game speed: idle 4 fps, attack ~0.56 s

    def gif(frames, z, durs, path):
        out = []
        bg = zoom(Image.open(fr"{REPO}\art\bg\zone_1.png").convert("RGBA").crop((120, 100, 120 + 62, 100 + 62)), 1)
        for f in frames:
            c = bg.copy().resize(f.size, Image.NEAREST); c.alpha_composite(f)
            out.append(zoom(c, z).convert("RGB"))
        out[0].save(path, save_all=True, append_images=out[1:], duration=durs, loop=0, disposal=2)
    gif(seq, GAME, durs, OUT + "/hero_anim.gif")                          # game size (2x art) and speed
    gif(seq, GAME * 2, [d * 2 for d in durs], OUT + "/hero_anim_slow_zoom.gif")  # 2x zoom, half speed
    shp = Image.new("RGBA", (CAN[0] * 4 + 8, CAN[1] * 2 + 4), (0, 0, 0, 0))
    for i, f in enumerate(idle): shp.alpha_composite(f, (i * (CAN[0] + 2), 0))
    for i, f in enumerate(attack): shp.alpha_composite(f, (i * (CAN[0] + 2), CAN[1] + 2))
    zoom(shp, GAME).save(OUT + "/hero_anim_sheet.png")
    piece_sheet("07  Animation frames (I1-I4 idle, K1-K4 attack)", "Idle: upper body 1 px down, sword dips. Attack: the weapon arm is its own layer and rotates at the shoulder (RotSprite, no new colours).",
                [(f"I{i + 1}", "idle", f) for i, f in enumerate(idle)] + [(f"K{i + 1}", n, f) for i, (f, n) in enumerate(zip(attack, ["wind-up", "strike", "follow", "recover"]))],
                OUT + "/07_anim_frames.png", z=3, cols=4)
    print("heroes done")


if __name__ == "__main__":
    main()
