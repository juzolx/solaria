"""Mix-and-match proof: any piece from any outfit, both bodies, battle view + portrait, any hair.
/c/ai/ComfyUI/python_embeded/python.exe -I mix_sheet.py"""
import os, sys
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "..", "hero", "tools"))
import layers as LY
import headswap as HS, recolour as R
import make_sheets as MS

L = LY.L
def tight(im): return im.crop(im.getbbox())
SRC = {  # (body, outfit, view) -> image
}
for body, rot in (("m", os.path.join(PL, "rotations")), ("f", os.path.join(PL, "female", "rotations"))):
    for v in ("north", "south"):
        SRC[(body, "base", v)] = L(os.path.join(rot, v + ".png"))
        for o in ("robe", "ranger"):
            SRC[(body, o, v)] = L(os.path.join(PL, "outfits", "raw", f"{body}_{o}_{v}.png"))
    for v in ("north", "south"):
        if body == "m":
            SRC[("m", "plate", v)] = L(os.path.join(PL, "custom", "plate", "rotations", v + ".png"))

BODY = {(b, v): LY.Body(SRC[(b, "base", v)]) for b in "mf" for v in ("north", "south")}
PIECES = {k: LY.cut(img, BODY[(k[0], k[2])], k[1], cape=(k[1] == "ranger")) for k, img in SRC.items()}

def helmet_piece(v):
    """Plate helmet = the helmet edit's head area (front: minus the face, which stays the hero's own)."""
    ed = L(os.path.join(HERE, "raw", f"m_helmet_plate_{v}.png"))
    body = BODY[("m", v)]
    out = Image.new("RGBA", ed.size); op = out.load(); ep = ed.load()
    face = HS.face_box(SRC[("m", "base", "south")]) if v == "south" else None
    for y in range(body.head + 3):
        for x in range(ed.width):
            if not ep[x, y][3]:
                continue
            if face and face[0] + 1 <= x <= face[2] - 1 and face[1] - 1 <= y <= body.head + 2:
                continue
            op[x, y] = ep[x, y]
    return out
HELM = {v: helmet_piece(v) for v in ("north", "south")}

def head(body, v, style=None, col=None):
    base = SRC[(body, "base", v)]
    if style is None:
        return base
    mbase = SRC[("m", "base", v)]
    tgt = base
    if body == "f":
        bald = L(os.path.join(PL, "female", "raw", f"bald_{v}.png"))
        tgt = bald
    im, hm = HS.swap(tgt, mbase, L(os.path.join(PL, "hair", "raw", f"{style}_{v}.png")),
                     keep_face=(tgt if v == "south" else None), return_mask=True)
    if col:
        im = R.recolour(im, hair=R.HAIR[col], ranges=R.ref_ranges([mbase]), hair_px=hm)
    return im

def build(body, v, kit, style=None, col=None):
    pcs = {}
    for slot, outfit in kit.items():
        if slot == "helmet":
            pcs["helmet"] = HELM[v] if (outfit == "plate" and body == "m") else None
        else:
            pcs[slot] = PIECES[(body, outfit, v)][slot]
    pcs.setdefault("weapon", PIECES[(body, "base", v)]["weapon"])
    return LY.compose(v, pcs, head(body, v, style, col))

def kit(chest, legs, feet, helmet=None):
    """The 6 visible slots. Arms/hands and any cape are parts of the chest item."""
    k = {"chest": chest, "legs": legs, "feet": feet, "gloves": chest}
    if chest == "ranger":
        k["back"] = "ranger"
    if helmet:
        k["helmet"] = helmet
    return k

MIXES = [  # chest / legs / feet / helmet; weapon is the base sword (step 4 swaps it)
    ("m", "plate helmet + robe + leather boots", kit("robe", "base", "base", helmet="plate"), None, None),
    ("m", "ranger chest + plate legs + plate feet", kit("ranger", "plate", "plate"), "short", None),
    ("m", "leather chest + ranger legs + ranger feet", kit("base", "ranger", "ranger"), "long", "white"),
    ("m", "plate chest + leather legs + ranger feet", kit("plate", "base", "ranger"), "mohawk", "red"),
    ("f", "robe + leather feet", kit("robe", "base", "base"), "bun", "pink"),
    ("f", "ranger chest + leather legs + robe feet", kit("ranger", "base", "robe"), "ponytail", None),
    ("f", "leather chest + ranger legs + leather feet", kit("base", "ranger", "base"), None, None),
    ("f", "ranger chest + ranger legs + leather feet", kit("ranger", "ranger", "base"), "long", "black"),
]
COLS, CW, CH = 4, 380, 330
S = MS.Sheet(20 + COLS * CW, 110 + 2 * CH + 300, "GEAR LAYERS - mix and match (code, 2 generations for the helmet)",
             "6 visible slots (weapon, off hand, helmet, chest, legs, feet) from any outfit; ring = no layer, necklace = portrait pendant. 3x.")
for i, (body, label, k, style, col) in enumerate(MIXES):
    x0, y0 = 20 + (i % COLS) * CW, 110 + (i // COLS) * CH
    S.panel(x0, y0, CW - 20, CH - 20, f"{i + 1}  {'He' if body == 'm' else 'She'}")
    x = x0 + 14
    for v in ("north", "south"):
        w, _ = S.put(tight(build(body, v, k, style, col)), x, y0 + 44, 3); x += w + 14
    S.d.text((x0 + 14, y0 + 262), label, font=MS.F_S, fill=MS.TXT)
y0 = 110 + 2 * CH
S.panel(20, y0, COLS * CW - 20, 280, "Ranger cut into pieces (battle view): chest body | chest arms | legs | feet | chest cape, + weapon, 3x")
x = 40
for s, src in (("chest", "ranger"), ("gloves", "ranger"), ("legs", "ranger"), ("feet", "ranger"), ("back", "ranger"), ("weapon", "base")):
    p = PIECES[("m", src, "north")][s]
    if not p.getbbox():
        continue
    t = tight(p)
    box = Image.new("RGBA", (t.width + 4, t.height + 4), (52, 48, 60, 255)); box.alpha_composite(t, (2, 2))
    w, _ = S.put(box, x, y0 + 50, 3, label={"chest": "chest body", "gloves": "chest arms", "back": "chest cape"}.get(s, s)); x += w + 26
S.im.convert("RGB").save(os.path.join(HERE, "01_LAYERS_mix.png"))
