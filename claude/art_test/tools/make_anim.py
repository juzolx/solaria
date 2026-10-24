import sys, math; sys.path.insert(0, r"C:\ai\scripts")
import heroes as H, pixlib as P, anim as A
from PIL import Image, ImageDraw
OUT = sys.argv[1]
body = H.compose("human", "warrior")
nat, w = H.weapon("sword"); g = H.grip_of(w, "sword")
hand = H.HAND["tall"]
CAN = (64, 52); ORG = (6, 6); WAIST = 28
def fr(**k):
    return A.finish(A.frame(body, w, g, hand, CAN, ORG, WAIST, **k))
idle = [fr(dy=0, angle=-20), fr(dy=1, angle=-20), fr(dy=1, angle=-24), fr(dy=0, angle=-22)]
def smear(im, a0, a1, dx, dy):
    im = im.copy(); d = ImageDraw.Draw(im)
    cx, cy = ORG[0] + hand[0] + dx, ORG[1] + hand[1] + dy
    for r, col in ((16, (192, 203, 220, 255)), (17, (255, 255, 255, 255)), (15, (139, 155, 180, 255))):
        for t in range(0, 101):
            a = math.radians(a0 + (a1 - a0) * t / 100)
            x, y = round(cx + r * math.sin(a)), round(cy - r * math.cos(a))
            if 0 <= x < im.width and 0 <= y < im.height and im.getpixel((x, y))[3] == 0:
                d.point((x, y), fill=col)
    return im
wind = fr(dx=-1, dy=0, angle=12, gdx=-2, gdy=-7)
strike = fr(dx=2, dy=1, angle=-105, gdx=1)
strike = A.finish(smear(strike, -40, 100, 3, 1))
recover = fr(dx=1, dy=0, angle=-55)
attack = [wind, strike, recover]
# sprite sheet: row 1 idle (4), row 2 attack (3), 2x scale (game files are 2x art)
S2 = 2
sheet = Image.new("RGBA", (CAN[0] * 4 * S2, CAN[1] * 2 * S2), (0, 0, 0, 0))
for i, f in enumerate(idle): sheet.alpha_composite(f.resize((CAN[0]*S2, CAN[1]*S2), Image.NEAREST), (i*CAN[0]*S2, 0))
for i, f in enumerate(attack): sheet.alpha_composite(f.resize((CAN[0]*S2, CAN[1]*S2), Image.NEAREST), (i*CAN[0]*S2, CAN[1]*S2))
sheet.save(OUT + "/hero_anim_sheet.png")
# preview GIF at 6x on the game dark backdrop: idle x2 loops then attack
S = 6; bg = (24, 20, 37)
def big(f):
    c = Image.new("RGBA", f.size, bg + (255,)); c.alpha_composite(f)
    return c.resize((f.width*S, f.height*S), Image.NEAREST).convert("RGB")
seq = idle + idle + attack + [idle[0]]
durs = [250]*8 + [160, 120, 220, 250]
fr0 = [big(f) for f in seq]
fr0[0].save(OUT + "/hero_anim.gif", save_all=True, append_images=fr0[1:], duration=durs, loop=0, disposal=2)
# labelled preview sheet
lab = Image.new("RGB", (CAN[0]*S*4 // 2 + 20, CAN[1]*S // 2 * 2 + 60), (30, 28, 40))
d = ImageDraw.Draw(lab)
for i, f in enumerate(idle): lab.paste(big(f).resize((CAN[0]*3, CAN[1]*3), Image.NEAREST), (i*CAN[0]*3 + 5, 20))
for i, f in enumerate(attack): lab.paste(big(f).resize((CAN[0]*3, CAN[1]*3), Image.NEAREST), (i*CAN[0]*3 + 5, CAN[1]*3 + 45))
d.text((5, 4), "idle (4 frames, 4 fps): upper body 1 px down, sword tip dips", fill=(230,230,230))
d.text((5, CAN[1]*3 + 28), "attack (3 frames): wind-up / strike + smear / recover", fill=(230,230,230))
lab.save(OUT + "/hero_anim_preview.png")
print("ok", g)
