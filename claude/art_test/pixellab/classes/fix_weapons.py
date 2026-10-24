"""Weapons with ONE shape through the whole animation (Juzo: "weapons change mid swing").
Battle frames for him: Warrior base, Warrior level 75 (sword) and Cleric (mace / sword). 0 generations.
/c/ai/ComfyUI/python_embeded/python.exe -I fix_weapons.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import weapons as W
import recolour as R
import make_sheets as MS
import hero

def L(p): return Image.open(p).convert("RGBA")
A = os.path.join(PL, "anims")
BASE = {"idle0": "idle_as_north/00", "idle1": "idle_as_north/02", "atk0": "attack2_north/02", "atk1": "attack2_north/04",
        "atk2": "attack2_north/06", "atk3": "attack2_north/07", "hit": "hit_as_north/01"}
N = list(BASE)
def sfx(k): return "_as" if k in ("idle0", "idle1", "hit") else ""

# per frame: where PixelLab drew the sword (and the mace, from the mace edit of the same base frame)
SW, MC = {}, {}
for k in N:
    b = L(os.path.join(A, BASE[k] + ".png")); m = L(os.path.join(HERE, "raw", f"mace2_m_n_{k}{sfx(k)}.png"))
    d = W.changed(b, m); bp, mp = b.load(), m.load()
    s = W.biggest({p for p in d if bp[p][3] and R.kind(bp[p][:3]) in ("metal", "shirt", "outline")})
    SW[k] = (b, s, *W.axis(s, W.body_centre(b))[0::2])          # frame, pts, grip, angle
    MC[k] = (m, W.biggest({p for p in d if mp[p][3] and (not bp[p][3] or p in s)}))
SWORD = W.Weapon(SW["idle0"][0], SW["idle0"][1])
MACE = W.Weapon(MC["idle0"][0], MC["idle0"][1], hand=SW["idle0"][2])  # grip = the end in the hand

def clip(frame_path, weapon):
    out = []
    for k in N:
        fr = L(frame_path(k)); _, pts, grip, ang = SW[k]
        out.append(W.swap(fr, pts, weapon, grip, ang))
    return out

CW = 100
def centre(im):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2)); return c
def at_feet(fr):
    ref = max(f.getbbox()[3] for f in fr[:2])
    out = []
    for f in fr:
        c = Image.new("RGBA", (CW, CW)); c.alpha_composite(f, (0, ref - f.getbbox()[3])); out.append(c)
    return out

RAW = os.path.join(HERE, "raw"); TR = os.path.join(PL, "tiers", "raw")
PANELS = [
    ("Warrior - sword", lambda k: os.path.join(RAW, f"warrior_m_n_{k}{sfx(k)}.png"), SWORD),
    ("Warrior L75 - sword", lambda k: os.path.join(TR, f"warrior_t75_m_n_{k}.png"), SWORD),
    ("Cleric - mace", lambda k: os.path.join(RAW, f"cleric_m_n_{k}{sfx(k)}.png"), MACE),
    ("Cleric - sword", lambda k: os.path.join(RAW, f"cleric_m_n_{k}{sfx(k)}.png"), SWORD),
]
CL = [(t, at_feet([centre(f) for f in clip(fp, w)])) for t, fp, w in PANELS]
SEQ = [0, 1, 0, 1, 2, 3, 3, 4, 5, 0, 6, 6, 0, 1]
DUR = [260, 260, 260, 260, 110, 110, 160, 90, 140, 200, 220, 220, 260, 260]
Z = 3; PW = CW * Z
out = []
for i, ms in zip(SEQ, DUR):
    S = MS.Sheet(20 + 4 * (PW + 16), 110 + PW + 50, "Weapons keep one shape (3x)",
                 "One drawing per weapon, placed in the hand at each frame's angle. Same outfits as before.")
    for j, (t, cl) in enumerate(CL):
        x0 = 20 + j * (PW + 16)
        S.panel(x0, 110, PW, PW + 30); S.d.text((x0 + 10, 114), f"{j + 1}  {t}", font=MS.F_S, fill=MS.GOLD)
        S.im.alpha_composite(hero.zoom(cl[i], Z), (x0, 140))
    out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
out[0].save(os.path.join(HERE, "03_WEAPONS_fixed.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)
F = MS.Sheet(20 + 7 * 210, 110 + 4 * 230, "Weapons keep one shape - every battle frame (2x)", "idle 2 | attack 4 | hit")
for r, (t, cl) in enumerate(CL):
    y = 110 + r * 230
    F.d.text((24, y), f"{r + 1}  {t}", font=MS.F_S, fill=MS.GOLD)
    for i, f in enumerate(cl):
        F.im.alpha_composite(hero.zoom(f, 2), (20 + i * 210, y + 24))
F.im.convert("RGB").save(os.path.join(HERE, "04_WEAPONS_fixed_frames.png"))
