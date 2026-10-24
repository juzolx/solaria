"""Build the HERO_* sheets, the 430x932 battle mockup and the runtime layer exports.
python -I make_sheets.py   (after draw_master.py / draw_custom.py / draw_portrait.py)"""
import os, sys, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hero
import draw_portrait as DP
import draw_master as D

ROOT = r"C:\gamedev\solaria_wt_newart"
OUT = os.path.join(ROOT, "claude", "art_test", "hero")
BG = (22, 18, 28, 255)
PANEL = (40, 34, 48, 255)
F_T = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 40)
F_L = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 24)
F_S = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 20)
GOLD = (240, 196, 110)
TXT = (230, 224, 214)
DIM = (160, 150, 160)

SKINS = ["skin_fair", "skin_tan", "skin_brown", "skin_deep"]
HAIRC = ["hair_brown", "hair_black", "hair_blond", "hair_red"]
HAIRS = ["short", "long", "buzz", "tail"]
RARITY = [("Common", "r_common"), ("Uncommon", "r_uncommon"), ("Rare", "r_rare"), ("Epic", "r_epic"),
          ("Legendary", "r_legendary"), ("Mythic", "r_mythic")]


# ------------------------------------------------------------------ hero builders
def rarity_ramps(i):
    """Juzo's rule: colour from rarity only. Common: plain metal. Uncommon: trim. Rare: trim + 1 band.
    Epic and up: trim + 2 bands + gem. Glow only for Mythic (added by glow())."""
    name, rr = RARITY[i]
    r = {}
    if i >= 1: r["R"] = rr
    if i >= 2: r["U"] = rr
    if i >= 3: r["Q"] = rr; r["J"] = rr
    return r


ARM = "A"   # chosen arm variant for the leather base (see 01c)


def battle(outfit="leather", hair="short", weapon="sword", skin="skin_fair", hairc="hair_brown",
           rarity=0, robe=None, plate_ramp=None, outfit_rarity=0, arm=None):
    """rarity = weapon (and shield) rarity; outfit_rarity = armour rarity. Each item keeps its own trim."""
    wr = rarity_ramps(rarity)
    orr = rarity_ramps(outfit_rarity)
    names = []
    if weapon == "sword_shield":
        names.append(("w_shield", 1, wr))
    o = {}
    if outfit == "plate":
        o.update(Q="steel", J="steel")
        o["F"] = plate_ramp or "steel"
        if plate_ramp: o["M"] = plate_ramp
    if robe: o["C"] = robe
    o.update(orr)
    arm = arm or ARM
    wname = "w_" + ("sword" if weapon == "sword_shield" else weapon)
    if outfit == "leather":
        if wname == "w_sword":
            wname = "w_sword_" + arm
        names += ["base_body_noarms", ("outfit_leather_noarms", o), "arms_" + arm, "hair_" + hair, (wname, wr)]
        names.append("fist_" + arm if wname.startswith("w_sword") else ("base_body_front", {"F": skin}))
    else:
        names += ["base_body", ("outfit_" + outfit, o), "hair_" + hair, (wname, wr)]
        names.append(("base_body_front", {"F": o.get("F", skin)}))
    ramps = {"S": skin, "F": skin, "H": hairc}
    return hero.render(names, ramps=ramps)[0]


def port_outfits():
    g, s = hero.load("port_outfit_leather")
    for name, mp in [("cloth", {"V": "C"}), ("plate", {"V": "M", "W": "M"})]:
        m2 = g.copy()
        for a, b in mp.items():
            m2[g == a] = b
        if name == "plate":                      # steel breastplate like the battle view; leather gorget strap
            m2[:35][g[:35] == "W"] = "B"
        if name == "plate":
            m2[(g == "V") & (s == "4")] = "R"
        p = os.path.join(hero.LAY, "port_outfit_" + name)
        open(p + ".txt", "w").write("\n".join("".join(r) for r in m2) + "\n")
        open(p + ".shade.txt", "w").write("\n".join("".join(r) for r in s) + "\n")


def portrait(face="determined", hair="short", outfit="leather", skin="skin_fair", hairc="hair_brown",
             iris="iris_brown", rarity=0):
    names = ["port_body", "port_outfit_" + outfit, "port_hair_" + hair, "port_face_" + face]
    ramps = {"S": skin, "H": hairc, "h": hairc, "E": iris}
    ramps.update(rarity_ramps(rarity))
    im = hero.render(names, ramps=ramps, pad=False)[0]
    return im.crop((0, 0, 46, 48))


def glow(im, rr="r_mythic", weapon_names=("w_sword",)):
    """Mythic only: 2-step hard-alpha glow ring around the weapon + 4 sparkles (code effect in game)."""
    w = hero.render(list(weapon_names), ramps={}, outline=True)[0]
    a = np.asarray(w)[..., 3] > 0
    a[46:, :] = False                       # blade only: no glow on the guard, hand or grip
    def dil(m):
        o = m.copy(); o[1:] |= m[:-1]; o[:-1] |= m[1:]; o[:, 1:] |= m[:, :-1]; o[:, :-1] |= m[:, 1:]
        return o
    d1 = dil(a); d2 = dil(d1); d3 = dil(d2)
    col = hero.hexrgb(hero.RAMPS[rr][3]); hi = hero.hexrgb(hero.RAMPS[rr][4])
    g = np.zeros(a.shape + (4,), np.uint8)
    lo = hero.hexrgb(hero.RAMPS[rr][2])
    g[d1 & ~a] = (*col, 210)
    g[d2 & ~d1] = (*lo, 90)
    gl = Image.fromarray(g)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(gl); out.alpha_composite(im)
    px = out.load()
    for (x, y) in [(68, 10), (60, 22), (67, 32), (58, 40)]:
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= x + dx < out.width and 0 <= y + dy < out.height and px[x + dx, y + dy][3] == 0:
                px[x + dx, y + dy] = (*(hi if (dx, dy) == (0, 0) else col), 255 if (dx, dy) == (0, 0) else 140)
    return out


# ------------------------------------------------------------------ sheet helpers
class Sheet:
    def __init__(self, w, h, title, sub=""):
        self.im = Image.new("RGBA", (w, h), BG)
        self.d = ImageDraw.Draw(self.im)
        self.d.text((24, 18), title, font=F_T, fill=GOLD)
        if sub:
            self.d.text((24, 68), sub, font=F_S, fill=DIM)

    def panel(self, x, y, w, h, label=None):
        self.d.rounded_rectangle([x, y, x + w, y + h], 10, fill=PANEL)
        if label:
            self.d.text((x + 12, y + 8), label, font=F_L, fill=TXT)

    def put(self, img, x, y, z=1, bg=None, label=None, lab_font=None):
        im = hero.zoom(img, z) if z > 1 else img
        if bg:
            b = Image.new("RGBA", im.size, bg); b.alpha_composite(im); im = b
        self.im.alpha_composite(im, (int(x), int(y)))
        if label:
            self.d.text((x, y + im.height + 4), label, font=lab_font or F_S, fill=TXT)
        return im.size

    def save(self, name):
        self.im.convert("RGB").save(os.path.join(OUT, name))


def head_crop(im):
    return im.crop((hero.PADL + 10, 20, hero.PADL + 43, 60))


# ------------------------------------------------------------------ sheets
def sheet_base():
    base = battle()
    por = portrait()
    S = Sheet(1600, 1500, "01  HERO base (pass 2) - Human chibi, seen from behind, 54 px",
              "Battle view straight from behind like the old heroes + front portrait (chiselled cheekbones). Right: mockup 430x932.")
    S.panel(20, 110, 1110, 690, "Battle view")
    S.put(base, 40, 160, 1, label="1x"); S.put(base, 40, 300, 2, label="2x")
    S.put(base, 200, 160, 3, label="3x (phone)")
    S.put(base, 420, 150, 7, label="7x")
    S.panel(20, 820, 520, 420, "Portrait")
    S.put(por, 40, 870, 1, label="1x"); S.put(por, 40, 950, 3, label="3x"); S.put(por, 210, 870, 7, label="7x")
    # layers
    S.panel(560, 820, 570, 420, "Layers (each recolours at runtime)")
    parts = [("body", ["base_body_noarms"]), ("outfit", ["outfit_leather_noarms"]), ("arms", ["arms_A"]),
             ("hair", ["hair_short"]), ("weapon", ["w_sword_A"]), ("hand", ["fist_A"])]
    x = 575
    for lab, n in parts:
        im = hero.render(n, ramps={})[0]
        S.put(im, x, 860, 2, label=lab); x += 86
    S.d.text((575, 1130), "Stacked bottom to top. Each pixel stores (material, shade 1-4);", font=F_S, fill=DIM)
    S.d.text((575, 1156), "the game swaps the 4-step ramp per material (skin, hair, cloth,", font=F_S, fill=DIM)
    S.d.text((575, 1182), "leather, metal, trim, gem) - no redraws for colours.", font=F_S, fill=DIM)
    # old in-game hero (LPC, the proportion reference) next to the new one, same 3x scale
    S.panel(20, 1260, 1110, 220, "Proportion reference: the old in-game hero (left) vs the new hero (right), 3x")
    old = old_lpc_back()
    if old is not None:
        S.put(old, 40, 1300, 3)
    S.put(base, 260, 1300 - 3 * 18, 3) if False else S.put(base.crop((0, 18, base.width, base.height)), 250, 1296, 3)
    S.d.text((520, 1310), "Same chibi build as the old heroes: head about 43 % of the height,", font=F_S, fill=DIM)
    S.d.text((520, 1336), "compact limbs, seen straight from behind. New: our own pixels,", font=F_S, fill=DIM)
    S.d.text((520, 1362), "clumped hair, white shirt + leather vest, outline and 4-shade ramps.", font=F_S, fill=DIM)
    S.d.text((520, 1388), "(Old LPC art shown for comparison only; nothing is copied from it.)", font=F_S, fill=DIM)
    mock = mockup(base)
    S.put(mock, 1150, 110)
    S.save("01_HERO_base.png")
    mock.convert("RGB").save(os.path.join(OUT, "01b_HERO_base_mockup_430x932.png"))


def old_lpc_back():
    """The current game's hero from behind (LPC parts), only to compare proportions on the sheet."""
    lp = "C:/gamedev/solaria_dev/art/lpc"
    try:
        m = json.load(open(os.path.join(lp, "manifest.json")))["items"]
        im = None
        for k in ["body", "legs_pants", "feet_boots", "shirt_long", "vest_m", "head_human_m", "hair_messy1"]:
            f = m[k]["layers"][0]["files"]["male"].get("idle@up")
            if not f:
                continue
            l = Image.open(os.path.join(lp, f["file"])).convert("RGBA").crop((0, 0, 64, 64))
            im = l if im is None else Image.alpha_composite(im, l)
        return im
    except Exception as e:
        print("old lpc:", e)
        return None


def mockup(base):
    W, Hh = 430, 932
    m = Image.new("RGBA", (W, Hh), (18, 14, 22, 255))
    d = ImageDraw.Draw(m)
    bg = Image.open(os.path.join(ROOT, "art", "bg", "zone_1.png")).convert("RGBA").resize((960, 540), Image.NEAREST)
    m.alpha_composite(bg.crop((265, 0, 265 + W, 540)), (0, 70))
    d.text((16, 14), "Sunken Catacombs - Floor 7", font=F_L, fill=TXT)
    d.text((16, 44), "hero and monster at the same 3x pixel scale", font=F_S, fill=GOLD)
    ghoul = Image.open(os.path.join(ROOT, "art", "enemies", "ghoul.png")).convert("RGBA")
    ghoul = ghoul.resize((34, 34), Image.NEAREST)
    gx, gy = 164, 322
    sh = Image.new("RGBA", (90, 16), (0, 0, 0, 0)); ImageDraw.Draw(sh).ellipse([0, 0, 89, 15], fill=(0, 0, 0, 90))
    m.alpha_composite(sh, (gx + 6, gy + 34 * 3 - 14))
    m.alpha_composite(hero.zoom(ghoul, 3), (gx, gy))
    sh2 = Image.new("RGBA", (138, 24), (0, 0, 0, 0)); ImageDraw.Draw(sh2).ellipse([0, 0, 137, 23], fill=(40, 46, 70, 150)); ImageDraw.Draw(sh2).ellipse([6, 3, 131, 20], fill=(8, 8, 16, 150))
    hx, hy = 203 - 3 * (hero.PADL + 27), 606 - 74 * 3
    m.alpha_composite(sh2, (203 - 69, hy + 73 * 3 - 12))
    m.alpha_composite(hero.zoom(base, 3), (hx, hy))
    y = 640
    for lab, f, c in [("Hero", 0.8, (70, 140, 80)), ("Ally", 0.55, (70, 140, 80)), ("Pet", 0.9, (70, 140, 80))]:
        d.text((18, y), lab, font=F_L, fill=TXT)
        d.rectangle([90, y + 4, 400, y + 24], fill=(60, 36, 44))
        d.rectangle([90, y + 4, 90 + int(310 * f), y + 24], fill=c)
        y += 48
    return m


def sheet_skin_hair():
    S = Sheet(1400, 1640, "02  Skin tones x hair styles x hair colours",
              "Same base. Skin and hair colours are ramp swaps; styles are separate hair layers (battle + portrait).")
    S.panel(20, 110, 1360, 330, "Skin tones (4)")
    for i, sk in enumerate(SKINS):
        x = 40 + i * 335
        S.put(battle(skin=sk), x, 160, 3)
        S.put(portrait(skin=sk), x + 196, 200, 3)
    S.panel(20, 460, 1360, 330, "Hair styles (4): short, long, close crop, tied tail")
    for i, hs in enumerate(HAIRS):
        x = 40 + i * 335
        S.put(battle(hair=hs), x, 510, 3)
        S.put(portrait(hair=hs), x + 196, 550, 3)
    S.panel(20, 810, 1360, 810, "Every style in every colour (brown, black, blond, red)")
    for r, hc in enumerate(HAIRC):
        for c, hs in enumerate(HAIRS):
            x = 40 + c * 335; y = 856 + r * 190
            S.put(head_crop(battle(hair=hs, hairc=hc)), x, y, 3)
            S.put(portrait(hair=hs, hairc=hc), x + 110, y + 20, 3)
    S.save("02_HERO_custom_skin_hair.png")


def sheet_faces():
    S = Sheet(1240, 1120, "03  Faces / expressions (3)",
              "Face layer on the portrait: brows follow hair colour, eyes are their own ramp (iris colour).")
    faces = ["determined", "fierce", "smile"]
    S.panel(20, 110, 1200, 450, "Determined - Fierce - Smile (7x and 1x)")
    for i, f in enumerate(faces):
        x = 40 + i * 395
        S.put(portrait(face=f), x, 160, 7)
        S.put(portrait(face=f), x + 330, 160, 1)
        S.d.text((x, 500), f, font=F_L, fill=TXT)
    S.panel(20, 580, 1200, 520, "Same faces on other skins / hair / eyes (4x)")
    combos = [("skin_tan", "hair_black", "iris_grey", "long"), ("skin_brown", "hair_red", "iris_green", "tail"),
              ("skin_deep", "hair_white", "iris_blue", "buzz")]
    for r, (sk, hc, ir, hs) in enumerate(combos):
        for c, f in enumerate(faces):
            S.put(portrait(face=f, skin=sk, hairc=hc, iris=ir, hair=hs), 40 + c * 400 + r * 0, 630 + r * 0, 1) if False else None
    for c, f in enumerate(faces):
        for r, (sk, hc, ir, hs) in enumerate(combos):
            S.put(portrait(face=f, skin=sk, hairc=hc, iris=ir, hair=hs), 40 + c * 400 + r * 128, 640, 2)
    S.d.text((40, 760), "Rows of three per face: tan / black hair / grey eyes, brown / red / green, deep / white / blue.",
             font=F_S, fill=DIM)
    # back view: the face is only a sliver from behind (ear, cheek, lash) - shown for honesty
    S.d.text((40, 820), "From behind (battle) only the cheek, ear and eyelash show, so expressions live on the portrait.",
             font=F_S, fill=DIM)
    S.put(head_crop(battle()), 40, 860, 6)
    S.put(head_crop(battle(skin="skin_deep", hairc="hair_white")), 240, 860, 6)
    S.save("03_HERO_custom_faces.png")


def sheet_outfits():
    S = Sheet(1400, 1060, "04  Outfits: cloth / leather / plate",
              "Outfit = one layer over the same body. Colours by ramp; the trim band carries rarity colour (here: plain).")
    outs = [("cloth", "Cloth robe"), ("leather", "Leather"), ("plate", "Plate (gauntlets turn the hand steel)")]
    S.panel(20, 110, 1360, 470, "Battle view (4x) + portrait (3x)")
    for i, (o, lab) in enumerate(outs):
        x = 40 + i * 450
        S.put(battle(outfit=o), x, 160, 4)
        S.put(portrait(outfit=o), x + 260, 300, 3)
        S.put(battle(outfit=o), x + 260, 170, 1)
        S.d.text((x, 520), lab, font=F_L, fill=TXT)
    S.panel(20, 600, 1360, 440, "Recolours of the same drawings (3x)")
    variants = [battle(outfit="cloth", robe="robe_plum"), battle(outfit="cloth", robe="robe_moss"),
                battle(outfit="cloth", robe="robe_ash"), battle(outfit="plate"),
                battle(outfit="plate", plate_ramp="iron_dk"), battle(outfit="plate", outfit_rarity=2),
                battle(outfit="plate", outfit_rarity=3)]
    labs = ["robe plum", "robe moss", "robe ash", "plate steel", "plate blackened", "plate Rare", "plate Epic"]
    for i, (im, lab) in enumerate(zip(variants, labs)):
        x = 40 + (i % 7) * 192
        S.put(im, x, 650, 3, label=lab)
    S.d.text((40, 990), "Rare vs Epic share the shape: Rare = trim colour, Epic = trim + extra band + gem (belt).",
             font=F_S, fill=DIM)
    S.save("04_HERO_custom_outfits.png")


def sheet_weapons():
    S = Sheet(1400, 1500, "05  Weapons + rarity looks",
              "Weapon layer in the near hand; shield under the far arm. Rarity = colour only; Rare vs Epic by trim + gem; glow only Mythic.")
    loads = [("sword", "Sword"), ("staff", "Staff"), ("bow", "Bow"), ("sword_shield", "Sword + shield")]
    S.panel(20, 110, 1360, 400, "Weapons (3x)")
    for i, (w, lab) in enumerate(loads):
        x = 40 + i * 340
        S.put(battle(weapon=w, outfit="plate" if w == "sword_shield" else "leather"), x, 150, 3)
        S.d.text((x, 470), lab, font=F_L, fill=TXT)
    S.panel(20, 530, 1360, 520, "Sword in 6 rarities (4x)")
    for i, (nm, rr) in enumerate(RARITY):
        im = hero.render([("w_sword", rarity_ramps(i)), "base_body_front"], ramps={})[0]
        crop = im.crop((hero.PADL + 34, 0, hero.PADL + 60, 68))
        if nm == "Mythic":
            crop = glow(im).crop((hero.PADL + 34, 0, hero.PADL + 60, 68))
        x = 40 + i * 222
        S.put(crop, x - 20, 570, 5) if False else S.put(crop, x, 570, 4)
        S.d.text((x, 925), nm, font=F_L, fill=hero.hexrgb(hero.RAMPS[rr][4]))
        S.d.text((x, 955), ["plain", "trim", "trim+band", "trim+bands+gem", "trim+bands+gem", "+glow"][i],
                 font=F_S, fill=DIM)
    S.panel(20, 1070, 1360, 410, "Full hero: Rare staff, Epic sword + shield, Mythic sword (3x)")
    a = battle(weapon="staff", outfit="cloth", rarity=2, hair="long")
    b = battle(weapon="sword_shield", outfit="plate", rarity=3, outfit_rarity=3, hair="buzz")
    c = glow(battle(rarity=5, outfit="leather"))
    for i, im in enumerate([a, b, c]):
        S.put(im, 40 + i * 300, 1110, 3)
    S.save("05_HERO_custom_weapons_rarity.png")


def sheet_arms():
    S = Sheet(1600, 1000, "01c  Arm variants - pick one (A is used in 01 and the mockup)",
              "Shoulder -> sleeve -> forearm -> hand as one shape; short, chunky, tapered for the chibi build.")
    labs = {"A": "A  relaxed: elbow bent, blade held out from the hip",
            "B": "B  on guard: sword arm raised, off arm braced",
            "C": "C  rolled sleeves: bare chunky forearms"}
    for i, k in enumerate("ABC"):
        x = 20 + i * 525
        S.panel(x, 110, 505, 860, labs[k][:1])
        im = battle(arm=k)
        S.put(im, x + 20, 160, 1, label="1x")
        S.put(im, x + 110, 150, 3, label="3x (phone)")
        S.put(im.crop((14, 38, 76, 66)), x + 30, 520, 7)
        S.d.text((x + 30, 490), "arms at 7x", font=F_S, fill=DIM)
        S.d.text((x + 20, 920), labs[k][3:], font=F_S, fill=TXT)
    S.save("01c_HERO_arms_ABC.png")


def export_layers():
    """Runtime export: one PNG per layer, R = shade (0 line, 1-4), G = material id, B = 0, A = 255."""
    mats = sorted(set("SFeEhHWVBTKMGRUQJDC"))
    ex = os.path.join(OUT, "layers")
    os.makedirs(ex, exist_ok=True)
    names = ["base_body", "base_body_front", "base_body_noarms", "outfit_leather_noarms", "arms_A", "arms_B", "arms_C", "fist_A", "fist_B", "fist_C", "w_sword_A", "w_sword_B", "w_sword_C", "outfit_leather", "outfit_cloth", "outfit_plate",
             "hair_short", "hair_long", "hair_buzz", "hair_tail", "w_sword", "w_staff", "w_bow", "w_shield",
             "port_body", "port_outfit_leather", "port_outfit_cloth", "port_outfit_plate",
             "port_hair_short", "port_hair_long", "port_hair_buzz", "port_hair_tail",
             "port_face_determined", "port_face_fierce", "port_face_smile"]
    for n in names:
        g, s = hero.load(n)
        a = np.zeros((hero.H, hero.W, 4), np.uint8)
        on = g != "."
        a[on, 0] = np.where(np.char.isdigit(s[on]), s[on], "0").astype(int) * 60
        a[on, 1] = [(mats.index(c) + 1) * 10 for c in g[on]]
        a[on, 3] = 255
        Image.fromarray(a).save(os.path.join(ex, n + ".png"))
    json.dump({"materials": {m: (i + 1) * 10 for i, m in enumerate(mats)},
               "shade_scale": 60, "ramps": hero.RAMPS, "default": hero.DEFAULT,
               "outline": "#%02x%02x%02x" % hero.OUTLINE,
               "notes": "R channel = shade*60 (0 = inner line, 1-4 dark to light); G = material id. "
                        "Stack layers bottom to top, colour = ramps[assigned ramp][shade], then add a 1 px outline."},
              open(os.path.join(ex, "layers.json"), "w"), indent=1)


if __name__ == "__main__":
    port_outfits()
    sheet_base(); sheet_arms(); export_layers()
    # customisation sheets 02-05 come back once each piece is rebuilt on the pass-2 base
    if "--all" in sys.argv:
        sheet_skin_hair(); sheet_faces(); sheet_outfits(); sheet_weapons()
    print("ok")
