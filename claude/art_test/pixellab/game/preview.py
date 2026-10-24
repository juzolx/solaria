"""Stacks the baked layers the way the game does (body, head, face, hair on top, weapon) for a few heroes.
/c/ai/ComfyUI/python_embeded/python.exe -I preview.py [out.png]"""
import os, sys, json
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "art", "heroes"))
INFO = json.load(open(os.path.join(ART, "heroes.json")))
C = INFO["cell"]; NF = len(INFO["frames"])

def L(n): return Image.open(os.path.join(ART, n + ".png"))

def ramp_at(ramp, t):
    t = max(0.0, min(1.0, t)) * (len(ramp) - 1); i = min(int(t), len(ramp) - 2); f = t - i
    return tuple(int(round(ramp[i][k] * (1 - f) + ramp[i + 1][k] * f)) for k in range(3))

def hexr(r): return [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in reversed(r)]

def tint(img, idx, skin, hair, only_hair=False):
    img = img.copy(); p, ip = img.load(), idx.load()
    for y in range(img.height):
        for x in range(img.width):
            s, h, _ = ip[x, y]
            if only_hair and not h:
                p[x, y] = (0, 0, 0, 0); continue
            if s and skin: p[x, y] = ramp_at(skin, (s - 1) / 254) + (p[x, y][3],)
            if h and hair: p[x, y] = ramp_at(hair, (h - 1) / 254) + (p[x, y][3],)
    return img

def hero(b, cls, style, face, weapon, skin=None, hair=None):
    out = Image.new("RGBA", (C * NF, C))
    body, head = f"{b}/outfit_{cls}", f"{b}/hair_{style}"
    out.alpha_composite(tint(L(body).convert("RGBA"), L(body + "_idx").convert("RGB"), skin, hair))
    h = L(head).convert("RGBA"); hi = L(head + "_idx").convert("RGB")
    out.alpha_composite(tint(h, hi, skin, hair))
    if face:
        f = f"{b}/face_{face}"
        fc = tint(L(f).convert("RGBA"), L(f + "_idx").convert("RGB"), skin, hair)
        out.alpha_composite(fc, (7 * C, 0))
        out.alpha_composite(tint(h, hi, skin, hair, only_hair=True))
    if weapon:
        out.alpha_composite(L(f"{b}/weapon_{weapon}").convert("RGBA"))
    return out

if __name__ == "__main__":
    SK = [["#fff1e6", "#fbe0cc", "#f2c9ac", "#d9a283", "#8a5444"], ["#a8705a", "#8a5444", "#6b3e34", "#4e2a28", "#2a1a1e"]]
    HR = [["#ede9c6", "#e6dd90", "#e0b45a", "#c65b1d", "#7d2814"], ["#edd5d4", "#e2a3b4", "#d86fab", "#c42cb2", "#7b1f80"]]
    rows = [("m", "warrior", "shaggy", "neutral", "sword", None, None),
            ("f", "warrior", "long", "smile", "sword", None, None),
            ("m", "mage", "ponytail", "determined", "staff", hexr(SK[1]), hexr(HR[0])),
            ("f", "ranger", "bob", "wary", "bow", hexr(SK[0]), hexr(HR[1])),
            ("f", "knight", "short", "fierce", "mace", None, None),
            ("m", "nightstalker", "long", "grim", "dagger", None, None),
            ("f", "ironbark", "braid", "sleepy", "axe", None, None),
            ("m", "sentinel", "bald", "battle_cry", "spear", None, None)]
    Z = 2
    sh = Image.new("RGBA", (C * NF * Z, C * Z * len(rows)), (30, 28, 36, 255))
    for r, a in enumerate(rows):
        im = hero(*a)
        sh.alpha_composite(im.resize((im.width * Z, im.height * Z), Image.NEAREST), (0, r * C * Z))
    sh.save(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "preview.png"))
