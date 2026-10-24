import sys; sys.path.insert(0, r"C:\ai\scripts")
import heroes as H, pixlib as P, anim as A
from PIL import Image, ImageDraw
OUT = sys.argv[1]; REPO = r"C:\gamedev\solaria_wt_newart"
BG = (30, 27, 40, 255); TXT = (232, 228, 240)
RACES = ["human", "elf", "orc", "dwarf", "goblin"]; OUTF = [None, "warrior", "mage", "ranger"]
sword = H.weapon("sword")[1]; staff = H.weapon("staff")[1]
WPN = {None: None, "warrior": ("sword", sword), "mage": ("staff", staff), "ranger": ("sword", sword)}

def armed(race, o):
    body = H.compose(race, o)
    w = WPN[o]
    if not w:
        return body.crop((0, 0, 56, 50)) if False else A.frame(body, None, (0, 0), (0, 0), (56, 50), (2, 2), 99)
    g = H.grip_of(w[1], w[0])
    return A.finish(A.frame(body, w[1], g, H.HAND[H.BUILD[race]], (56, 50), (2, 2), 99, angle=-20 if w[0] == "sword" else 0))

# 1) layer grid: races x outfits, 4x, labelled
S = 4; cw, ch = 56 * S, 50 * S
g = Image.new("RGBA", (130 + cw * 4, 40 + ch * 5 + 40 + 60 * S), BG); d = ImageDraw.Draw(g)
d.text((10, 8), "New 2x heroes: one pose, layered = race body + outfit + weapon (shown 4x; 1 art px = 4 px)", fill=TXT)
for i, o in enumerate(OUTF):
    d.text((130 + i * cw + 10, 26), (o or "base body (no outfit)") + ("" if not o else " + " + WPN[o][0]), fill=TXT)
for j, r in enumerate(RACES):
    d.text((10, 40 + j * ch + ch // 2), r + ("  (short build)" if H.BUILD[r] == "short" else ""), fill=TXT)
    for i, o in enumerate(OUTF):
        im = armed(r, o)
        g.alpha_composite(im.resize((im.width * S, im.height * S), Image.NEAREST), (130 + i * cw, 40 + j * ch))
y = 40 + ch * 5 + 10
d.text((10, y), "weapon layers (separate sprites, pinned to the hand, rotated with RotSprite for attacks)", fill=TXT)
for k, w in enumerate([sword, staff]):
    g.alpha_composite(w.resize((w.width * S, w.height * S), Image.NEAREST), (130 + k * 80, y + 18))
g.save(OUT + "/heroes_layers.png")

# 2) pipeline: raw AI -> native grid -> cleaned, per pick
rows = [("race", r, H.PICKS["race"][r]) for r in RACES] + [("outfit", f"{k[0]} ({k[1]})", v) for k, v in H.PICKS["outfit"].items()]
rh = 200
p = Image.new("RGBA", (200 + 200 + 210 + 210 + 20, 30 + rh * len(rows)), BG); d = ImageDraw.Draw(p)
d.text((10, 8), "raw AI (1024 px, img2img from the shared mannequin)  ->  native pixel grid (8 px cells found)  ->  palette + outline + rim", fill=TXT)
for j, (kind, label, name) in enumerate(rows):
    raw, nat = H.native(name)
    y = 30 + j * rh
    bb = (330, 360, 700, 760)
    p.paste(raw.crop(bb).resize((185, 200)), (5, y))
    p.alpha_composite(nat.resize((nat.width * 4, nat.height * 4), Image.NEAREST), (200, y + 10))
    cl = P.outline(H.clean(nat)) if kind == "outfit" else H.compose(label)
    if kind == "outfit":
        cl = P.rim(cl)
    p.alpha_composite(cl.resize((cl.width * 4, cl.height * 4), Image.NEAREST), (400, y + 6))
    d.text((620, y + 80), f"{kind}: {label}\n{name}\ncolours: {P.colours(cl)}", fill=TXT)
p.save(OUT + "/heroes_pipeline.png")

# 3) game scale next to existing monsters (all 2x files shown at 3x = phone-ish size)
mons = ["ghoul", "draugr", "barrow_wight", "banshee", "strigoi"]
heroes = [armed("human", "warrior"), armed("elf", "mage"), armed("dwarf", "warrior"), armed("orc", "ranger"), armed("goblin", "ranger")]
Z = 3
row_h = 140 * Z // 2 + 40
s = Image.new("RGBA", (40 + 5 * 110 * Z // 1 // 1, 2 * (68 * Z + 50) + 70), (24, 20, 37, 255)); d = ImageDraw.Draw(s)
d.text((10, 8), "game scale: heroes (2x art) beside the Zone 1 Sunken Catacombs monsters (house style, art/enemies 68x68); everything shown at 3x", fill=TXT)
x = 20
for h in heroes:
    h2 = h.crop(h.getbbox()); h2 = h2.resize((h2.width * 2, h2.height * 2), Image.NEAREST)
    s.alpha_composite(h2.resize((h2.width * Z, h2.height * Z), Image.NEAREST), (x, 50 + 68 * Z - h2.height * Z))
    x += h2.width * Z + 30
x = 20
for m in mons:
    im = Image.open(fr"{REPO}\art\enemies\{m}.png").convert("RGBA")
    s.alpha_composite(im.resize((im.width * Z, im.height * Z), Image.NEAREST), (x, 100 + 68 * Z))
    d.text((x, 100 + 68 * Z * 2 + 4), m, fill=TXT)
    x += 68 * Z + 20
s = s.crop((0, 0, max(x, 1000), s.height))
s.save(OUT + "/heroes_vs_monsters.png")

# 4) battle mock: hero facing a monster on a zone background at game scale (2x files, 3x view)
bgp = None
import glob, os
bgs = sorted(glob.glob(REPO + r"\art\bg\*.png"))
if bgs:
    bgi = Image.open(bgs[0]).convert("RGBA")
    W, Hh = bgi.size
    sc = bgi.resize((W * 2, Hh * 2), Image.NEAREST)
    hero = armed("human", "warrior"); hero = hero.crop(hero.getbbox()); hero = hero.resize((hero.width * 2, hero.height * 2), Image.NEAREST)
    mon = Image.open(fr"{REPO}\art\enemies\ghoul.png").convert("RGBA").transpose(Image.FLIP_LEFT_RIGHT) if False else Image.open(fr"{REPO}\art\enemies\ghoul.png").convert("RGBA")
    foot = int(Hh * 2 * 0.82)
    sc.alpha_composite(hero, (W * 2 // 2 - 120, foot - hero.height))
    sc.alpha_composite(mon, (W * 2 // 2 + 60, foot - mon.height))
    sc.resize((sc.width * 2, sc.height * 2), Image.NEAREST).save(OUT + "/heroes_battle_mock.png")
    print("bg", os.path.basename(bgs[0]))
print("done")
