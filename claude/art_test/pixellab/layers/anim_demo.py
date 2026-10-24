"""Animation options side by side (battle view, 3x), 0 generations:
  A  PixelLab frame animation (the approved overhead slash) - only exists for the outfit it was drawn with
  B  code animation of a MIXED layered outfit: pieces moved / the sword rotated per frame (what the game would do)
  C  PixelLab body frames with gear frozen on top (plate chest pasted on each frame) - shows why that breaks
/c/ai/ComfyUI/python_embeded/python.exe -I anim_demo.py"""
import os, sys, glob, math
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import layers as LY
import headswap as HS
import make_sheets as MS
import hero

L = LY.L
V = "north"
BASE = L(os.path.join(PL, "rotations", "north.png"))
BODY = LY.Body(BASE)
ROBE = LY.cut(L(os.path.join(PL, "outfits", "raw", "m_robe_north.png")), BODY, "robe")
BASEP = LY.cut(BASE, BODY, "base")
PLATE = LY.cut(L(os.path.join(PL, "custom", "plate", "rotations", "north.png")), BODY, "plate")
HELM = L(os.path.join(HERE, "raw", "m_helmet_plate_north.png"))
hb = BODY.head
helm = Image.new("RGBA", HELM.size)
hp, mp = helm.load(), HELM.load()
for y in range(hb + 3):
    for x in range(HELM.width):
        if mp[x, y][3]:
            hp[x, y] = mp[x, y]

# the mixed kit: plate helmet + robe chest + leather legs/feet + the sword
KIT = {"chest": ROBE["chest"], "gloves": ROBE["gloves"], "legs": BASEP["legs"], "feet": BASEP["feet"],
       "weapon": BASEP["weapon"], "helmet": helm}
SW = sorted(BODY.sword, key=lambda p: (p[1], p[0]))
PIVOT = SW[0]                                   # hilt end of the sword (in the hand)
SHOULDER = (BODY.tx1 + 1, hb + 5)
CW = 96  # work canvas, the 64 px sprite sits in the middle so the raised sword has room
OFF = (CW - 64) // 2


def split_arm(p):
    """Right arm/hand (sword side) out of the arms piece, so it can follow the sword."""
    right, rest = Image.new("RGBA", p.size), p.copy()
    pp, rp, sp = p.load(), right.load(), rest.load()
    for y in range(p.height):
        for x in range(BODY.tx1 + 1, p.width):
            if pp[x, y][3]:
                rp[x, y] = pp[x, y]; sp[x, y] = (0, 0, 0, 0)
    return right, rest


ARM_R, ARMS = split_arm(KIT["gloves"])
HEAD = Image.new("RGBA", BASE.size)
for (x, y), k in __import__("recolour").masks(BASE).items():
    if y < hb + 1 or k == "hair":
        HEAD.putpixel((x, y), BASE.getpixel((x, y)))


def place(canvas, im, dx=0, dy=0):
    canvas.alpha_composite(im, (OFF + dx, OFF + dy))


def code_frame(body_dy=0, lean=0, sword_deg=0.0, slash=False):
    """One code-animated frame: legs/feet still, upper body bobs/leans, the sword turns around the hand,
    the sword arm follows the hand along a circle around the shoulder."""
    c = Image.new("RGBA", (CW, CW))
    place(c, KIT["legs"]); place(c, KIT["feet"])
    place(c, KIT["chest"], lean, body_dy); place(c, ARMS, lean, body_dy)
    place(c, HEAD, lean, body_dy); place(c, KIT["helmet"], lean, body_dy)
    # hand position: rotate the shoulder->hand vector by part of the sword angle
    a = math.radians(-sword_deg * 0.55)
    vx, vy = PIVOT[0] - SHOULDER[0], PIVOT[1] - SHOULDER[1]
    hx = SHOULDER[0] + vx * math.cos(a) - vy * math.sin(a)
    hy = SHOULDER[1] + vx * math.sin(a) + vy * math.cos(a)
    mdx, mdy = round(hx - PIVOT[0]) + lean, round(hy - PIVOT[1]) + body_dy
    # sword: rotate the weapon piece around the hilt (nearest neighbour keeps the pixels crisp)
    big = Image.new("RGBA", (CW, CW)); big.alpha_composite(KIT["weapon"], (OFF, OFF))
    rot = big.rotate(sword_deg, resample=Image.NEAREST, center=(PIVOT[0] + OFF, PIVOT[1] + OFF))
    if 60 < sword_deg < 200:      # raised behind the head: sword under the arm, over the head
        c.alpha_composite(rot, (mdx, mdy)); c.alpha_composite(ARM_R, (OFF + mdx, OFF + mdy))
    else:
        c.alpha_composite(ARM_R, (OFF + mdx, OFF + mdy)); c.alpha_composite(rot, (mdx, mdy))
    if slash:  # a 1-frame slash arc, drawn in code
        d = ImageDraw.Draw(c)
        cx, cy = OFF + SHOULDER[0] + lean, OFF + SHOULDER[1] - 4
        d.arc([cx - 30, cy - 26, cx + 14, cy + 22], 150, 250, fill=(235, 235, 245, 255), width=2)
    return c


IDLE_B = [code_frame(body_dy=d) for d in (0, 0, 1, 1)]
ATK_B = [code_frame(*args) for args in (
    (0, 0, 0), (0, 0, 40), (-1, 0, 100), (-1, 0, 150), (-1, 0, 168),
    (1, -1, 60, True), (1, -2, -25), (0, -1, -12), (0, 0, 0))]


def frames(name):
    return [L(f) for f in sorted(glob.glob(os.path.join(PL, "anims", name, "*.png")))]


def centre(im):  # PixelLab frames: 64 (idle) or 88 (attack) canvases, centred on the work canvas
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2))
    return c


IDLE_A, ATK_A = [centre(f) for f in frames("idle_north")], [centre(f) for f in frames("attack2_north")]
# C: plate chest (+ arms) frozen at the rest pose, pasted on every PixelLab frame
frozen = Image.new("RGBA", (CW, CW)); frozen.alpha_composite(PLATE["chest"], (OFF, OFF)); frozen.alpha_composite(PLATE["gloves"], (OFF, OFF))
IDLE_C = [Image.alpha_composite(f, frozen) for f in IDLE_A]
ATK_C = [Image.alpha_composite(f, frozen) for f in ATK_A]

# feet line up: shift the PixelLab attack (bigger canvas) so its feet sit where the idle feet sit
def feet(fs): return max(f.getbbox()[3] for f in fs)
def align(fs, ref):
    d = ref - feet(fs)
    out = []
    for f in fs:
        c = Image.new("RGBA", (CW, CW)); c.alpha_composite(f, (0, d)); out.append(c)
    return out
fi = feet(IDLE_A)
ATK_A, ATK_C = align(ATK_A, fi), align(ATK_C, fi)
IDLE_B, ATK_B = align(IDLE_B, fi), align(ATK_B, fi)

SEQ = [("idle", i) for i in range(4)] * 2 + [("atk", i) for i in range(9)] + [("idle", i) for i in range(4)]
DUR = [220] * 8 + [90] * 9 + [220] * 4
COLS = [("A  PixelLab frames", "only its own outfit", IDLE_A, ATK_A),
        ("B  Code from layers", "any gear mix (here: plate", IDLE_B, ATK_B),
        ("C  Gear frozen on top", "plate pasted on PixelLab", IDLE_C, ATK_C)]
SUB2 = ["", "helmet + robe + leather)", "frames: breaks in the swing"]
Z = 3
W = 20 + 3 * (CW * Z + 20)
out = []
for (kind, i), ms in zip(SEQ, DUR):
    S = MS.Sheet(W, 120 + CW * Z + 110, "Animation options (battle view, 3x)", "Same idle -> attack loop. 0 generations.")
    for j, (t, sub, idle, atk) in enumerate(COLS):
        x0 = 20 + j * (CW * Z + 20)
        S.panel(x0, 110, CW * Z, CW * Z + 100)
        S.d.text((x0 + 10, 116), t, font=MS.F_L, fill=MS.GOLD)
        f = (idle if kind == "idle" else atk)[i]
        S.im.alpha_composite(hero.zoom(f, Z), (x0, 150))
        S.d.text((x0 + 10, 150 + CW * Z + 4), sub, font=MS.F_S, fill=MS.TXT)
        S.d.text((x0 + 10, 150 + CW * Z + 28), SUB2[j], font=MS.F_S, fill=MS.TXT)
    out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
out[0].save(os.path.join(HERE, "02_ANIM_options.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)
# a still strip of B's attack for close inspection
strip = Image.new("RGBA", (9 * CW * Z, CW * Z), (52, 48, 60, 255))
for i, f in enumerate(ATK_B):
    strip.alpha_composite(hero.zoom(f, Z), (i * CW * Z, 0))
strip.convert("RGB").save(os.path.join(HERE, "03_ANIM_code_attack_frames.png"))
