"""Option B vs option D (battle view, 3x), robe chest item on both bodies.
  B  code only: pieces moved, sword rotated around the hand
  D  the same code frames, but the two moments where the body bends ('sword raised' and 'follow-through')
     are PixelLab key poses: the approved attack frames 4 and 6 with the robe edited on (1 gen each)
/c/ai/ComfyUI/python_embeded/python.exe -I anim_d.py"""
import os, sys, glob, math
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import layers as LY
import headswap as HS
import recolour as R
import make_sheets as MS
import hero

L = LY.L
CW = 96


class Rig:
    """Code animation for one body + kit (battle view)."""

    def __init__(self, base, robe_img, helmet_img=None):
        self.base = base
        self.body = b = LY.Body(base)
        robe, own = LY.cut(robe_img, b, "robe"), LY.cut(base, b, "base")
        self.off = (CW - base.width) // 2
        self.legs, self.feet, self.chest = own["legs"], own["feet"], robe["chest"]
        self.weapon = own["weapon"]
        self.arm_r, self.arms = self._split(robe["gloves"])
        self.head = Image.new("RGBA", base.size)
        for (x, y), k in R.masks(base).items():
            if y < b.head + 1 or k == "hair":
                self.head.putpixel((x, y), base.getpixel((x, y)))
        self.helm = None
        if helmet_img is not None:
            self.helm = Image.new("RGBA", base.size)
            for y in range(b.head + 3):
                for x in range(base.width):
                    if helmet_img.getpixel((x, y))[3]:
                        self.helm.putpixel((x, y), helmet_img.getpixel((x, y)))
        sw = sorted(b.sword, key=lambda p: (p[1], p[0]))
        self.pivot, self.shoulder = sw[0], (b.tx1 + 1, b.head + 5)

    def _split(self, p):
        right, rest = Image.new("RGBA", p.size), p.copy()
        for y in range(p.height):
            for x in range(self.body.tx1 + 1, p.width):
                c = p.getpixel((x, y))
                if c[3]:
                    right.putpixel((x, y), c); rest.putpixel((x, y), (0, 0, 0, 0))
        return right, rest

    def frame(self, body_dy=0, lean=0, deg=0.0, slash=False):
        o = self.off
        c = Image.new("RGBA", (CW, CW))
        for im, dx, dy in ((self.legs, 0, 0), (self.feet, 0, 0), (self.chest, lean, body_dy), (self.arms, lean, body_dy),
                           (self.head, lean, body_dy)):
            c.alpha_composite(im, (o + dx, o + dy))
        if self.helm:
            c.alpha_composite(self.helm, (o + lean, o + body_dy))
        a = math.radians(-deg * 0.55)
        vx, vy = self.pivot[0] - self.shoulder[0], self.pivot[1] - self.shoulder[1]
        hx = self.shoulder[0] + vx * math.cos(a) - vy * math.sin(a)
        hy = self.shoulder[1] + vx * math.sin(a) + vy * math.cos(a)
        mdx, mdy = round(hx - self.pivot[0]) + lean, round(hy - self.pivot[1]) + body_dy
        big = Image.new("RGBA", (CW, CW)); big.alpha_composite(self.weapon, (o, o))
        rot = big.rotate(deg, resample=Image.NEAREST, center=(self.pivot[0] + o, self.pivot[1] + o))
        if 60 < deg < 200:
            c.alpha_composite(rot, (mdx, mdy)); c.alpha_composite(self.arm_r, (o + mdx, o + mdy))
        else:
            c.alpha_composite(self.arm_r, (o + mdx, o + mdy)); c.alpha_composite(rot, (mdx, mdy))
        if slash:
            d = ImageDraw.Draw(c)
            cx, cy = o + self.shoulder[0] + lean, o + self.shoulder[1] - 4
            d.arc([cx - 30, cy - 26, cx + 14, cy + 22], 150, 250, fill=(235, 235, 245, 255), width=2)
        return c


def centre(im):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, ((CW - im.width) // 2, (CW - im.height) // 2))
    return c


def feet(im):
    return im.getbbox()[3]


def at_feet(im, ref):
    c = Image.new("RGBA", (CW, CW)); c.alpha_composite(im, (0, ref - feet(im)))
    return c


def clips(rig, key_raised, key_follow):
    idle = [rig.frame(body_dy=d) for d in (0, 0, 1, 1)]
    ref = feet(idle[0])
    B = [rig.frame(*a) for a in ((0, 0, 0), (0, 0, 40), (-1, 0, 100), (-1, 0, 150), (-1, 0, 168),
                                 (1, -1, 60, True), (1, -2, -25), (0, -1, -12), (0, 0, 0))]
    kr, kf = at_feet(centre(key_raised), ref), at_feet(centre(key_follow), ref)
    mid = rig.frame(1, -1, 60, True)
    D = [B[0], B[1], B[2], kr, kr, mid, kf, B[7], B[8]]
    return [at_feet(f, ref) for f in idle], [at_feet(f, ref) for f in B], D


MB = L(os.path.join(PL, "rotations", "north.png"))
FB = L(os.path.join(PL, "female", "rotations", "north.png"))
HELM = L(os.path.join(HERE, "raw", "m_helmet_plate_north.png"))
m_rig = Rig(MB, L(os.path.join(PL, "outfits", "raw", "m_robe_north.png")), HELM)
f_rig = Rig(FB, L(os.path.join(PL, "outfits", "raw", "f_robe_north.png")))
mk = [L(os.path.join(HERE, "raw", f"m_robe_key_{k}_north.png")) for k in ("raised", "follow")]
mk = [HS.swap(k, MB, HELM) for k in mk]  # the helmet goes on the key poses too
fk = [L(os.path.join(HERE, "raw", f"f_robe_key_{k}_north.png")) for k in ("raised", "follow")]
M = clips(m_rig, *mk)
F = clips(f_rig, *fk)

SEQ = [("i", i) for i in range(4)] * 2 + [("a", i) for i in range(9)] + [("i", i) for i in range(4)]
DUR = [220] * 8 + [90] * 9 + [220] * 4
PANELS = [("He  B: code only", M, 1), ("He  D: code + 2 key poses", M, 2),
          ("She  B: code only", F, 1), ("She  D: code + 2 key poses", F, 2)]
Z = 3
PW = CW * Z
W = 20 + 4 * (PW + 16)
out = []
for kind, i in SEQ:
    S = MS.Sheet(W, 110 + PW + 60, "Option B vs option D - robe, battle view, 3x",
                 "D swaps in two PixelLab-drawn poses (sword raised, follow-through); everything else is code. 4 generations.")
    for j, (t, clip, which) in enumerate(PANELS):
        x0 = 20 + j * (PW + 16)
        S.panel(x0, 110, PW, PW + 40)
        S.d.text((x0 + 10, 116), t, font=MS.F_S, fill=MS.GOLD)
        f = clip[0][i] if kind == "i" else clip[which][i]
        S.im.alpha_composite(hero.zoom(f, Z), (x0, 140))
    out.append(S.im.convert("RGB").convert("P", palette=Image.ADAPTIVE))
out[0].save(os.path.join(HERE, "04_ANIM_B_vs_D.gif"), save_all=True, append_images=out[1:], duration=DUR, loop=0)
strip = Image.new("RGBA", (9 * PW, 2 * PW), (52, 48, 60, 255))
for r, clip in enumerate((M, F)):
    for i, f in enumerate(clip[2]):
        strip.alpha_composite(hero.zoom(f, Z), (i * PW, r * PW))
strip.convert("RGB").save(os.path.join(HERE, "05_ANIM_D_attack_frames.png"))
