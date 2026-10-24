"""Class-outfit sample through the fixed frame set (battle: idle 2, attack 4, hit 1; portrait: idle 2).
Layers per frame: class outfit frame (PixelLab edit of the base frame) -> sword removed in code -> weapon layer.
Weapon layers: sword = the sword pixels of the base frame; mace = pixels a PixelLab 'replace the sword with a mace'
edit changed (where the sword was or outside the body). 0 generations here.
/c/ai/ComfyUI/python_embeded/python.exe -I compose.py"""
import os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import recolour as R
import make_sheets as MS
import hero

def L(p): return Image.open(p).convert("RGBA")
A = os.path.join(PL, "anims"); FA = os.path.join(PL, "female", "anims")
BASE = {  # (body, frame) -> base PixelLab frame with the sword
    # idle + hit come from v3 clips started on the attack's rest frame, so the hero keeps the attack's size
    ("m", "idle0"): os.path.join(A, "idle_as_north", "00.png"), ("m", "idle1"): os.path.join(A, "idle_as_north", "02.png"),
    ("m", "atk0"): os.path.join(A, "attack2_north", "02.png"), ("m", "atk1"): os.path.join(A, "attack2_north", "04.png"),
    ("m", "atk2"): os.path.join(A, "attack2_north", "06.png"), ("m", "atk3"): os.path.join(A, "attack2_north", "07.png"),
    ("m", "hit"): os.path.join(A, "hit_as_north", "01.png"),
    ("f", "idle0"): os.path.join(FA, "idle_as_north", "00.png"), ("f", "idle1"): os.path.join(FA, "idle_as_north", "02.png"),
    ("f", "atk0"): os.path.join(FA, "attack_north", "02.png"), ("f", "atk1"): os.path.join(FA, "attack_north", "04.png"),
    ("f", "atk2"): os.path.join(FA, "attack_north", "06.png"), ("f", "atk3"): os.path.join(FA, "attack_north", "07.png"),
    ("f", "hit"): os.path.join(FA, "hit_as_north", "01.png"),
}
NORTH = ["idle0", "idle1", "atk0", "atk1", "atk2", "atk3", "hit"]
CW = 96


def diff(a, b):
    return a[3] != b[3] or (a[3] and sum(abs(a[i] - b[i]) for i in range(3)) > 30)


def weapon_masks(base, mace):
    """S = sword pixels of the base frame, W = mace pixels: both from what the mace edit changed."""
    bp, mp = base.load(), mace.load()
    S, W = set(), set()
    for y in range(base.height):
        for x in range(base.width):
            b, m = bp[x, y], mp[x, y]
            if not diff(b, m):
                continue
            kind = R.kind(b[:3]) if b[3] else None
            if b[3] and kind in ("metal", "shirt", "outline"):
                S.add((x, y))
            if m[3] and (not b[3] or (x, y) in S):
                W.add((x, y))
    return S, W


def swap_weapon(frame, base, S, W_src=None, W=()):
    """Remove the sword pixels S from a class frame; put the weapon (pixels W of W_src) on top."""
    out = frame.copy(); op, bp = out.load(), base.load()
    for (x, y) in S:
        if W_src is None or not W_src.getpixel((x, y))[3]:
            op[x, y] = (0, 0, 0, 0)  # background behind the sword
        else:  # body behind the sword: fill from the nearest non-sword pixel on the row
            for d in (1, -1, 2, -2, 3, -3):
                if (x + d, y) not in S and 0 <= x + d < out.width and op[x + d, y][3]:
                    op[x, y] = op[x + d, y]; break
    if W_src is not None:
        for (x, y) in W:
            op[x, y] = W_src.getpixel((x, y))
    return out


def centre(im):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2)); return c


def at_feet(frames):
    ref = max(f.getbbox()[3] for f in frames[:2])  # feet of the idle frames
    out = []
    for f in frames:
        c = Image.new("RGBA", (CW, CW)); c.alpha_composite(f, (0, ref - f.getbbox()[3])); out.append(c)
    return out


def clip(cls, body, weapon):
    frames = []
    for k in NORTH:
        sfx = "_as" if k in ("idle0", "idle1", "hit") else ""
        fr = L(os.path.join(HERE, "raw", f"{cls}_{body}_n_{k}{sfx}.png"))
        if weapon == "mace":
            base = L(BASE[(body, k)]); mace = L(os.path.join(HERE, "raw", f"mace2_{body}_n_{k}{sfx}.png"))
            S, W = weapon_masks(base, mace)
            fr = swap_weapon(fr, base, S, mace, W) if W else fr
        frames.append(centre(fr))
    return at_feet(frames)


def portrait(cls, body):
    return [centre(L(os.path.join(HERE, "raw", f"{cls}_{body}_s_idle{i}.png"))) for i in (0, 1)]


PANELS = [("Warrior - he - sword", "warrior", "m", "sword"), ("Warrior - she - sword", "warrior", "f", "sword"),
          ("Cleric - he - mace", "cleric", "m", "mace"), ("Cleric - she - sword", "cleric", "f", "sword")]
CLIPS = [(t, clip(c, b, w), portrait(c, b)) for t, c, b, w in PANELS]
SEQ = [0, 1, 0, 1, 2, 3, 3, 4, 5, 0, 6, 6, 0, 1]
DUR = [260, 260, 260, 260, 110, 110, 160, 90, 140, 200, 220, 220, 260, 260]
Z = 3; PW = CW * Z
W_ = 20 + 4 * (PW + 16)
out = []
for n, (i, ms) in enumerate(zip(SEQ, DUR)):
    S = MS.Sheet(W_, 110 + PW + 40 + 200 + 20, "Class outfits through the fixed frame set (3x)",
                 "Battle view: idle 2, attack 4, hit 1. Below: portrait idle 2. Outfits and mace by PixelLab per frame; sword swap in code.")
    for j, (t, cl, po) in enumerate(CLIPS):
        x0 = 20 + j * (PW + 16)
        S.panel(x0, 110, PW, PW + 30)
        S.d.text((x0 + 10, 114), f"{j + 1}  {t}", font=MS.F_S, fill=MS.GOLD)
        S.im.alpha_composite(hero.zoom(cl[i], Z), (x0, 140))
        p = po[(n // 2) % 2].crop((16, 14, 80, 66))
        S.im.alpha_composite(hero.zoom(p, 3), (x0 + (PW - 192) // 2, 110 + PW + 50))
    out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
out[0].save(os.path.join(HERE, "01_CLASS_sample.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)
# still sheet of every frame
F = MS.Sheet(20 + 9 * 200, 110 + 4 * 220, "Class sample - every frame (2x)", "idle0 idle1 | attack 1-4 | hit | portrait idle0 idle1")
for r, (t, cl, po) in enumerate(CLIPS):
    y = 110 + r * 220
    F.d.text((24, y), f"{r + 1}  {t}", font=MS.F_S, fill=MS.GOLD)
    for i, f in enumerate(cl + po):
        F.im.alpha_composite(hero.zoom(f, 2), (20 + i * 200, y + 24))
F.im.convert("RGB").save(os.path.join(HERE, "02_CLASS_frames.png"))
