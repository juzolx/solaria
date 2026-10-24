"""Warrior (he) across the class tiers: base -> level 15 -> 35 -> 75, through the fixed frame set.
/c/ai/ComfyUI/python_embeded/python.exe -I tiers_sheet.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import make_sheets as MS
import hero

def L(p): return Image.open(p).convert("RGBA")
CW = 100
N = ["idle0", "idle1", "atk0", "atk1", "atk2", "atk3", "hit"]
def path(tier, k, view="n"):
    if tier == "base":
        sfx = "_as" if view == "n" and k in ("idle0", "idle1", "hit") else ""
        return os.path.join(PL, "classes", "raw", f"warrior_m_{view}_{k}{sfx}.png")
    return os.path.join(HERE, "raw", f"warrior_{tier}_m_{view}_{k}.png")
def centre(im):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2)); return c
def at_feet(fr):
    ref = max(f.getbbox()[3] for f in fr[:2])
    out = []
    for f in fr:
        c = Image.new("RGBA", (CW, CW)); c.alpha_composite(f, (0, ref - f.getbbox()[3])); out.append(c)
    return out
TIERS = [("base", "Base (level 1)"), ("t15", "Level 15: pauldrons + gold trim"), ("t35", "Level 35: + short cape"),
         ("t75", "Level 75: ornate armour, long cape, glowing runes")]
CL = {t: at_feet([centre(L(path(t, k))) for k in N]) for t, _ in TIERS}
PO = {t: [centre(L(path(t, f"idle{i}", "s"))) for i in (0, 1)] for t, _ in TIERS}
F = MS.Sheet(20 + 9 * 210, 110 + 4 * 230, "WARRIOR across class tiers (he, 2x)",
             "Same 9 frames per tier: battle idle 2 | attack 4 | hit | portrait idle 2. Each tier = PixelLab edit of the tier before.")
for r, (t, lab) in enumerate(TIERS):
    y = 110 + r * 230
    F.d.text((24, y), f"{r + 1}  {lab}", font=MS.F_S, fill=MS.GOLD)
    for i, f in enumerate(CL[t] + PO[t]):
        F.im.alpha_composite(hero.zoom(f, 2), (20 + i * 210, y + 24))
F.im.convert("RGB").save(os.path.join(HERE, "01_WARRIOR_tiers_frames.png"))
SEQ = [0, 1, 0, 1, 2, 3, 3, 4, 5, 0, 6, 6, 0, 1]
DUR = [260, 260, 260, 260, 110, 110, 160, 90, 140, 200, 220, 220, 260, 260]
Z = 3; PW = CW * Z
out = []
for n, (i, ms) in enumerate(zip(SEQ, DUR)):
    S = MS.Sheet(20 + 4 * (PW + 16), 110 + PW + 40 + 210, "WARRIOR tiers in battle (3x)", "Base -> 15 -> 35 -> 75. Below: portrait.")
    for j, (t, lab) in enumerate(TIERS):
        x0 = 20 + j * (PW + 16)
        S.panel(x0, 110, PW, PW + 30)
        S.d.text((x0 + 10, 114), f"{j + 1}  {lab.split(':')[0]}", font=MS.F_S, fill=MS.GOLD)
        S.im.alpha_composite(hero.zoom(CL[t][i], Z), (x0, 140))
        p = PO[t][(n // 2) % 2].crop((18, 16, 82, 68))
        S.im.alpha_composite(hero.zoom(p, 3), (x0 + (PW - 192) // 2, 110 + PW + 50))
    out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
out[0].save(os.path.join(HERE, "02_WARRIOR_tiers.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)
