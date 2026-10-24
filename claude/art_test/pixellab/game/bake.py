"""Bakes the PixelLab hero into the game's layer files (art/heroes). 0 generations.
/c/ai/ComfyUI/python_embeded/python.exe -I bake.py

Every layer is drawn on the SAME 9 frames (battle from behind: idle 2, attack 4, hit 1; portrait: idle 2),
each frame a 96x96 cell with the feet on row FOOT, the cells side by side in one sheet:
  <b>/outfit_<class>[_t<tier>].png  body + class outfit, NO head and NO weapon (both are own layers)
  <b>/hair_<style>.png                 the head with that hair style, already placed on every frame
  <b>/face_<expr>.png                  the face (eyes to chin) on the 2 portrait frames
  <b>/weapon_<type>.png                one weapon drawing, turned and placed in the hand on every frame
Each picture with skin or hair has an index sheet (<name>_idx.png): R = skin shade, G = hair shade
(0 = none, 1..255 = dark..light), so the game recolours skin and hair with any ramp at build time.
heroes.json lists what exists."""
import json, math, os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
REPO = os.path.abspath(os.path.join(PL, "..", "..", ".."))
OUT = os.path.join(REPO, "art", "heroes")
sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "classes")); sys.path.insert(0, os.path.join(PL, "hair"))
import recolour as R, weapons as W, headswap as HS

C, FOOT = 96, 80  # the feet sit where the old LPC heroes stood (Sprites.HERO_FOOT on the 96 canvas)
K = ["n_idle0", "n_idle1", "n_atk0", "n_atk1", "n_atk2", "n_atk3", "n_hit", "s_idle0", "s_idle1"]
CLASSES = ["warrior", "knight", "wanderer", "cleric", "acolyte", "mage", "trickster", "ranger", "bard",
           "sentinel", "ironbark", "nightstalker", "conjurer"]
STYLES = ["Short", "Spiky", "Side Swept", "Shaggy", "Mohawk", "Short Mohawk", "Buzz", "Bald", "Balding",
          "Bedhead", "Unkempt", "Porcupine", "Mop", "Parted", "Page", "Bangs", "Long Bangs", "Long", "Very Long", "Wild",
          "Loose", "Wavy", "Tied Back", "Ponytail", "High Ponytail", "Half Up", "Pigtails", "Bun", "Braid", "Bob", "Pixie",
          "Princess", "Curly", "Long Curls", "Afro", "Cornrows", "Dreadlocks"]
FACES = ["neutral", "smile", "laughing", "determined", "fierce", "grim", "wary", "surprised", "sleepy", "battle_cry"]
WEAPONS = ["sword", "dagger", "axe", "mace", "spear", "bow", "staff"]


def L(p): return Image.open(p).convert("RGBA")
def key(n): return n.lower().replace(" ", "_")


def src_path(cls, b, k, tier=""):
    if tier:
        return os.path.join(PL, "tiers", "raw", f"{cls}_t{tier}_{b}_{k}.png")
    if cls in ("warrior", "cleric"):
        sfx = "_as" if k in ("n_idle0", "n_idle1", "n_hit") else ""
        return os.path.join(PL, "classes", "raw", f"{cls}_{b}_{k}{sfx}.png")
    return os.path.join(PL, "classes", "batch", "raw", f"{cls}_{b}_{k}.png")


# ---------- the base frames: where each frame sits in its cell ----------
BASE = {b: {k: L(os.path.join(HERE, "base", f"{b}_{k}.png")) for k in K} for b in "mf"}
PLACE = {b: {k: ((C - im.width) // 2, FOOT - im.getbbox()[3]) for k, im in BASE[b].items()} for b in "mf"}


def cell(im, b, k):
    c = Image.new("RGBA", (C, C)); c.alpha_composite(im, PLACE[b][k]); return c


CELL = {b: {k: cell(BASE[b][k], b, k) for k in K} for b in "mf"}
ROT = {"m": {"n": L(os.path.join(PL, "rotations", "north.png")), "s": L(os.path.join(PL, "rotations", "south.png"))},
       "f": {"n": L(os.path.join(PL, "female", "rotations", "north.png")), "s": L(os.path.join(PL, "female", "rotations", "south.png"))}}


def comps(pts):
    pts, seen, out = set(pts), set(), []
    for p in pts:
        if p in seen:
            continue
        c, todo = set(), [p]; seen.add(p)
        while todo:
            x, y = todo.pop(); c.add((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if q in pts and q not in seen:
                        seen.add(q); todo.append(q)
        out.append(c)
    return out


def sword_pts(im):
    """The blade (most blade-like group of metal/white pixels) plus its outline ring."""
    px = im.load()
    met = {(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] and R.kind(px[x, y][:3]) in ("metal", "shirt")}
    best, bs = set(), 0
    for c in comps(met):
        if len(c) < 10:
            continue
        if sum(R.lum(px[q][:3]) for q in c) / len(c) < 115:
            continue  # blades are bright steel; a dull grey-green group is skin (orc backs), not a sword
        l2 = max((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 for a in c for b in c)
        if l2 / len(c) > bs:
            best, bs = c, l2 / len(c)
    ring = {(x + dx, y + dy) for (x, y) in best for dx in (-1, 0, 1) for dy in (-1, 0, 1)
            if 0 <= x + dx < im.width and 0 <= y + dy < im.height and (x + dx, y + dy) not in best
            and px[x + dx, y + dy][3] and R.kind(px[x + dx, y + dy][:3]) == "outline"}
    return best, ring


SW = {}  # b -> k -> (blade+ring pts, grip, angle) in cell coords
for b in "mf":
    SW[b] = {}
    for k in K:
        blade, ring = sword_pts(CELL[b][k])
        grip, tip, ang = W.axis(blade, W.body_centre(CELL[b][k]))
        SW[b][k] = [blade | ring, grip, ang, tip, ((tip[0] - grip[0]) ** 2 + (tip[1] - grip[1]) ** 2) ** 0.5]
    # a blade mostly hidden (behind the head) gives the wrong grip: measure back from its tip instead
    full = sorted(v[4] for v in SW[b].values())[len(K) // 2]
    for k, v in SW[b].items():
        if v[4] < 0.75 * full:
            v[1] = (round(v[3][0] - math.cos(v[2]) * full), round(v[3][1] - math.sin(v[2]) * full))
            print("grip from tip:", b, k, v[1])


def head_offset(rot, frame):
    """(dx, dy) laying the rotation's head over the frame's head: a guess from the tops, then a search."""
    hb = HS.head_bottom(rot)
    rp, fp = rot.load(), frame.load()
    pts = [(x, y) for y in range(hb) for x in range(rot.width) if rp[x, y][3]]
    rb, fb = rot.getbbox(), frame.getbbox()
    top_f = [x for x in range(frame.width) for y in range(fb[1], fb[1] + 6) if fp[x, y][3]]
    top_r = [x for x in range(rot.width) for y in range(rb[1], rb[1] + 6) if rp[x, y][3]]
    gx = round(sum(top_f) / len(top_f) - sum(top_r) / len(top_r)); gy = fb[1] - rb[1]
    best = None
    for dy in range(gy - 6, gy + 7):
        for dx in range(gx - 8, gx + 9):
            cost = 0
            for x, y in pts:
                X, Y = x + dx, y + dy
                if not (0 <= X < frame.width and 0 <= Y < frame.height) or not fp[X, Y][3]:
                    cost += 3000; continue
                a, c = rp[x, y], fp[X, Y]
                cost += min(3000, (a[0] - c[0]) ** 2 + (a[1] - c[1]) ** 2 + (a[2] - c[2]) ** 2)
            if best is None or cost < best[0]:
                best = (cost, dx, dy)
    return best[1], best[2]


def d_of(k): return "s" if k.startswith("s") else "n"


OFF_OWN = {b: {k: head_offset(ROT[b][d_of(k)], CELL[b][k]) for k in K} for b in "mf"}
# his hair styles on her: her own head position plus where his head sits on hers (per view)
M2F = {d: head_offset(ROT["m"][d], ROT["f"][d].crop((0, 0, 64, 64))) for d in "ns"}
OFF_M = {"m": OFF_OWN["m"], "f": {k: (OFF_OWN["f"][k][0] + M2F[d_of(k)][0], OFF_OWN["f"][k][1] + M2F[d_of(k)][1]) for k in K}}

# shade ranges of the original art (so every frame recolours the same way)
RANGES = R.ref_ranges([CELL[b][k] for b in "mf" for k in K] + [ROT[b][d] for b in "mf" for d in "ns"])


def shade(c, kind):
    lo, hi = RANGES[kind]
    return 1 + max(0, min(254, round((R.lum(c[:3]) - lo) / max(1, hi - lo) * 254)))


def old_head(b, k):
    rot = ROT[b][d_of(k)]; dx, dy = OFF_OWN[b][k]; rp = rot.load()
    return {(x + dx, y + dy) for y in range(HS.head_bottom(rot)) for x in range(rot.width) if rp[x, y][3]}


def body_cell(im, b, k):
    """Outfit frame -> its cell without the old head/hair and without the sword."""
    c = cell(im, b, k); p = c.load()
    pts = set(SW[b][k][0])
    # the edit may have shifted the sword a little: take this frame's own blade too when it lies near the base one
    near = {(x + dx, y + dy) for (x, y) in pts for dx in range(-3, 4) for dy in range(-3, 4)}
    own, ring = sword_pts(c)
    if own and len(own & near) * 2 >= len(own):
        pts |= own | ring
    for (x, y) in sorted(pts):
        l = next((p[x - d, y] for d in (1, 2, 3) if x - d >= 0 and (x - d, y) not in pts and p[x - d, y][3]), None)
        r = next((p[x + d, y] for d in (1, 2, 3) if x + d < C and (x + d, y) not in pts and p[x + d, y][3]), None)
        p[x, y] = l if (l and r) else (0, 0, 0, 0)
    gone = old_head(b, k)
    for (x, y), kd in R.masks(c).items():
        if kd == "hair" or (x, y) in gone:
            p[x, y] = (0, 0, 0, 0)
    # stray outline pixels left around the cut neck
    hb = max(y for _, y in gone) if gone else 0
    for y in range(max(0, hb - 40), min(C, hb + 2)):
        for x in range(C):
            if p[x, y][3]:
                n = sum(1 for ddx in (-1, 0, 1) for ddy in (-1, 0, 1) if (ddx or ddy)
                        and 0 <= x + ddx < C and 0 <= y + ddy < C and p[x + ddx, y + ddy][3])
                if n <= 1:
                    p[x, y] = (0, 0, 0, 0)
    return c


def index_of(c, hair_pts=()):
    idx = Image.new("RGB", c.size); ip = idx.load(); cp = c.load()
    if c.getbbox() is None:
        return idx
    m = R.masks(c)
    for (x, y), kd in m.items():
        if (x, y) in hair_pts:
            ip[x, y] = (0, shade(cp[x, y], "hair"), 0)
        elif kd == "skin":
            ip[x, y] = (shade(cp[x, y], "skin"), 0, 0)
    for (x, y) in hair_pts:
        if cp[x, y][3] and ip[x, y] == (0, 0, 0):
            ip[x, y] = (0, shade(cp[x, y], "hair"), 0)
    return idx


def sheet(cells):
    s = Image.new("RGBA" if cells[0].mode == "RGBA" else "RGB", (C * len(cells), C))
    for i, c in enumerate(cells):
        s.paste(c, (i * C, 0))
    return s


def despeck(c, smallest=3, loose=0):
    """Drops loose specks (8-connected islands under `smallest` pixels): edit noise and fragments a
    rotated weapon leaves behind. loose: also drop any piece under this size apart from the main shape
    (the base frames' dotted sword trail, weapon fragments)."""
    p = c.load()
    pts = {(x, y) for y in range(c.height) for x in range(c.width) if p[x, y][3]}
    parts = sorted(comps(pts), key=len)
    for comp in parts[:-1] if parts else []:
        if len(comp) < max(smallest, loose):
            for q in comp:
                p[q] = (0, 0, 0, 0)
    return c


def save(name, cells, idx=None):
    os.makedirs(os.path.dirname(os.path.join(OUT, name)), exist_ok=True)
    whole = os.path.basename(name).startswith("outfit_")
    cells = [despeck(c, 3, 20 if whole else 0) for c in cells]
    sheet(cells).save(os.path.join(OUT, name + ".png"), optimize=True)
    if idx is not None:
        sheet(idx).save(os.path.join(OUT, name + "_idx.png"), optimize=True)


def head_cells(b, style_img, base_rot, offs):
    """The head with a hair style on every frame: cells + hair pixel sets."""
    patch = HS.head_patch(style_img, base_rot)
    hb, hm = HS.head_bottom(style_img), R.masks(style_img)
    hair = {p for p in patch if p[1] >= hb or hm.get(p) == "hair"}
    cells, hairs = [], []
    for k in K:
        dx, dy = offs[k]
        c = Image.new("RGBA", (C, C)); cp = c.load(); hp = set()
        for (x, y), col in patch.items():
            X, Y = x + dx, y + dy
            if 0 <= X < C and 0 <= Y < C and col[3]:
                cp[X, Y] = col
                if (x, y) in hair:
                    hp.add((X, Y))
        cells.append(c); hairs.append(hp)
    return cells, hairs


def main():
    info = {"cell": C, "foot": FOOT, "frames": K, "classes": {}, "styles": {}, "faces": [], "weapons": [], "hand": {}}
    for b in "mf":
        # ---- outfits (base + any tiers) ----
        for cls in CLASSES:
            for tier in ("", "15", "35", "75"):
                if not all(os.path.exists(src_path(cls, b, k, tier)) for k in K):
                    continue
                cells = []
                for k in K:
                    im = L(src_path(cls, b, k, tier))
                    if im.size != BASE[b][k].size:
                        print("size mismatch", cls, tier, b, k, im.size); break
                    cells.append(body_cell(im, b, k))
                else:
                    save(f"{b}/outfit_{cls}" + (f"_t{tier}" if tier else ""), cells, [index_of(c) for c in cells])
                    info["classes"].setdefault(cls, {}).setdefault(b, []).append(int(tier or 0))
        print(b, "outfits done")
        # ---- hair styles (heads) ----
        for st in STYLES:
            k_ = key(st)
            if b == "f" and k_ == "long":  # her own long hair
                src, base, offs = ROT["f"], ROT["f"], OFF_OWN["f"]
            elif k_ == "shaggy" and b == "m":  # his own hair
                src, base, offs = ROT["m"], ROT["m"], OFF_M["m"]
            else:
                src = {d: L(os.path.join(PL, "hair", "lib", f"{k_}_{'north' if d == 'n' else 'south'}.png")) for d in "ns"}
                base, offs = ROT["m"], OFF_M[b]
            cn, hn = head_cells(b, src["n"], base["n"], offs)
            cs, hs = head_cells(b, src["s"], base["s"], offs)
            cells = cn[:7] + cs[7:]; hairs = hn[:7] + hs[7:]
            save(f"{b}/hair_{k_}", cells, [index_of(c, h) for c, h in zip(cells, hairs)])
            info["styles"][st] = k_
        print(b, "hair done")
        # ---- faces (portrait frames only) ----
        lib = os.path.join(PL, "faces", "lib") if b == "m" else os.path.join(PL, "female", "faces", "lib")
        bs = ROT[b]["s"]
        x0, y0, x1, y1 = HS.face_box(bs); y1 = max(y1, HS.head_bottom(bs) + 3)
        for e in FACES:
            fi = L(os.path.join(lib, f"{e}_south.png")); fp = fi.load(); fm = R.masks(fi)
            cells = []
            for k in K[7:]:
                dx, dy = OFF_OWN[b][k]
                c = Image.new("RGBA", (C, C)); cp = c.load()
                for x in range(x0, x1 + 1):
                    for y in range(y0 - 3, y1 + 1):
                        if fp[x, y][3] and fm.get((x, y)) != "hair" and 0 <= x + dx < C and 0 <= y + dy < C:
                            cp[x + dx, y + dy] = fp[x, y]
                cells.append(c)
            save(f"{b}/face_{e}", cells, [index_of(c) for c in cells])
            if e not in info["faces"]:
                info["faces"].append(e)
        print(b, "faces done")
        # ---- weapons ----
        info["hand"][b] = [list(SW[b][k][1]) for k in K]
        for wt, drawing in WEAPON_DRAWINGS.items():
            # at rest (idle, hit) a weapon is held as drawn on his first idle frame, turned as much as the sword
            # turns; in the swing it points where the blade points. The portrait (front) holds the mirror image.
            a0 = SW["m"]["n_idle0"][2]
            mir = mirrored(drawing)
            cells = []
            for k in K:
                g, a = SW[b][k][1], SW[b][k][2]
                if k.startswith("n_atk"):
                    cells.append(drawing.placed((C, C), g, a))
                elif k.startswith("s"):
                    cells.append(mir.placed((C, C), g, mir.ang + a - (math.pi - a0)))
                else:
                    cells.append(drawing.placed((C, C), g, drawing.ang + a - a0))
            save(f"{b}/weapon_{wt}", cells)
            if wt not in info["weapons"]:
                info["weapons"].append(wt)
        print(b, "weapons done")
        # ---- race signature features (standard-body races) ----
        for race in RACES:
            paths = {k: os.path.join(FEATURES, f"{race.lower()}_{b}_{k}.png") for k in K}
            if not all(os.path.exists(p) for p in paths.values()):
                continue
            front, back = race_cells(b, paths)
            save(f"{b}/race_{race.lower()}", front, [index_of(c) for c in front])
            if any(c.getbbox() for c in back):
                save(f"{b}/race_{race.lower()}_back", back, [index_of(c) for c in back])
            info.setdefault("races", {}).setdefault(race, []).append(b)
        print(b, "races done")
    build_bodies(info)
    with open(os.path.join(OUT, "heroes.json"), "w", newline=chr(10)) as f:
        json.dump(info, f, indent=1)


RACES = ["Elf", "Angel", "Demon", "Beastkin", "Dragonkin", "Undead", "Vampire", "Lich"]
FEATURES = os.path.abspath(os.path.join(REPO, "..", "solaria_dev", "claude", "art_test", "races", "features", "raw"))


def race_cells(b, paths):
    """A race's signature feature (PixelLab edits of the base frames, 'add only ...'): the pixels the edit
    changed, minus edit noise on the hair (the hair is its own layer) and specks. Front view: what sticks
    out below the head (wings, tail) goes to a layer drawn BEHIND the body; the rest is drawn on top."""
    front, back = [], []
    for k in K:
        base = CELL[b][k]
        ed = cell(L(paths[k]), b, k)
        bp, ep = base.load(), ed.load()
        bm = R.masks(base)
        hair_cols = {bp[p][:3] for p, kd in bm.items() if kd == "hair"}
        def hairlike(c):
            return any(sum(abs(c[i] - h[i]) for i in range(3)) < 45 for h in hair_cols)
        pts = set()
        for y in range(C):
            for x in range(C):
                e, o = ep[x, y], bp[x, y]
                if not e[3] or (o[3] and sum(abs(e[i] - o[i]) for i in range(3)) <= 40):
                    continue
                if o[3] and bm.get((x, y)) == "hair" and hairlike(e):
                    continue  # the edit redrew some hair: not part of the feature
                if (x, y) in SW[b][k][0]:
                    continue  # nor the sword
                pts.add((x, y))
        hl = (OFF_OWN[b][k][1] + HS.head_bottom(ROT[b][d_of(k)]))
        # keep real features: specks go, and so do small changes entirely inside the body below the head
        # (the edit re-shading the clothes); eyes, fangs and the like sit in the head and stay
        keep = []
        for c in comps(pts) if pts else []:
            inside = all(bp[q][3] and q[1] > hl for q in c)
            if len(c) >= 6 and not (inside and len(c) < 25):
                keep.append(c)
        pts = set().union(*keep) if keep else set()
        f = Image.new("RGBA", (C, C)); bk = Image.new("RGBA", (C, C))
        for (x, y) in pts:
            if k.startswith("s") and y > hl:
                if not bp[x, y][3]:
                    bk.putpixel((x, y), ep[x, y])  # wings / tail peeking out from behind
            else:
                f.putpixel((x, y), ep[x, y])
        front.append(f); back.append(bk)
    return front, back


def mirrored(w):
    """The same weapon drawing flipped left-right (held in the other hand as seen from the front)."""
    m = W.Weapon.__new__(W.Weapon)
    m.img = w.img.transpose(Image.FLIP_LEFT_RIGHT)
    m.x0, m.y0 = w.x0, w.y0
    fx = lambda p: (w.x0 + w.img.width - 1 - (p[0] - w.x0), p[1])
    m.grip, m.tip = fx(w.grip), fx(w.tip)
    m.ang = math.atan2(m.tip[1] - m.grip[1], m.tip[0] - m.grip[0])
    return m


def weapon_drawings():
    """One drawing per weapon type, cut from PixelLab edits of his first idle frame (same grip and scale)."""
    base = CELL["m"]["n_idle0"]
    blade, grip = SW["m"]["n_idle0"][0], SW["m"]["n_idle0"][1]
    out = {"sword": W.Weapon(base, sword_pts(base)[0])}
    for wt in WEAPONS[1:]:
        p = os.path.join(HERE, "weapons", f"{wt}.png")
        if not os.path.exists(p):
            continue
        ed = cell(L(p), "m", "n_idle0")
        d = W.changed(base, ed); ep, bp = ed.load(), base.load()
        pts = {q for q in d if ep[q][3]} | {q for q in blade if ep[q][3] and q in d}
        out[wt] = W.Weapon(ed, pts, hand=grip)
    return out


WEAPON_DRAWINGS = weapon_drawings()

# ---------- other body builds (sprite-design.md): their own body frames, 4 outfit families ----------
# Made from PixelLab edits of the base frames ("turn him into a goblin ..."), then each family's outfit
# as an edit of those (claude/art_test/races, jobs.txt / ojobs.txt). The head stays drawn (no hair-style
# swap): hair recolours by its shade, the family's fabric takes the class colour (index B = dye shade).
RACES_RAW = os.path.abspath(os.path.join(REPO, "..", "solaria_dev", "claude", "art_test", "races", "raw"))
BUILDS = {"Goblin": "goblin", "Dwarf": "dwarf", "Orc": "orc", "Golem": "golem"}
OWN_SKIN = ["Goblin", "Orc", "Werewolf", "Golem"]  # races whose drawn skin hue is their signature: no skin recolour
# races drawn as a feature layer on another build's frames (PixelLab edits of that build's base frames)
FEATURE_BUILDS = {"Werewolf": "orc"}
# builds drawn once for both bodies (a golem is stone: no man or woman build)
SHARED = {"Golem": "m"}
FAMILY_SRC = {"plate": "warrior", "robe": "mage", "leather": "leather", "cloth": "cloth"}
FAMILY_OF = {"Warrior": "plate", "Knight": "plate", "Sentinel": "plate",
             "Mage": "robe", "Cleric": "robe", "Acolyte": "robe", "Conjurer": "robe",
             "Ranger": "leather", "Nightstalker": "leather", "Trickster": "leather", "Bard": "leather",
             "Wanderer": "cloth", "Ironbark": "cloth"}
# the dyed fabric of each family, as hue ranges (0-1): plate's skirt, the robe, the tunic, the gambeson
DYE_HUES = {"plate": [(0.94, 1.0), (0.0, 0.04)], "robe": [(0.70, 0.86)], "leather": [(0.20, 0.45)], "cloth": [(0.52, 0.68)]}
# frames a build reuses (his goblin's second idle frame lost its shirt: both idle frames are the first)
ALIAS = {("goblin", "m", "n_idle1"): "n_idle0"}


def build_src(race, fam, b, k):
    k = ALIAS.get((race, b, k), k)
    stem = f"{race}_{FAMILY_SRC[fam]}_{b}_{k}" if fam else f"{race}_{b}_{k}"
    v2 = os.path.join(RACES_RAW, stem.replace(f"_{b}_{k}", f"_{b}_{k}") + "_v2.png")
    if not fam and os.path.exists(os.path.join(RACES_RAW, f"{race}_{b}_{k}_v2.png")):
        return os.path.join(RACES_RAW, f"{race}_{b}_{k}_v2.png")
    return os.path.join(RACES_RAW, stem + ".png")


def dye_index(c, fam, idx):
    """Marks the family's dyed fabric in the index's blue channel (shade 1..255) for the class colour."""
    import colorsys
    cp, ip = c.load(), idx.load()
    pts = []
    for y in range(C):
        for x in range(C):
            px = cp[x, y]
            if not px[3] or ip[x, y][0] or ip[x, y][1]:
                continue
            h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
            if sat > (0.15 if fam == "cloth" else 0.3) and v > 0.12 and any(lo <= h <= hi for lo, hi in DYE_HUES[fam]):
                pts.append((x, y, R.lum(px[:3])))
    if not pts:
        return idx
    ls = sorted(q[2] for q in pts); lo, hi = ls[len(ls) // 20], ls[-len(ls) // 20 - 1]
    for x, y, l in pts:
        ip[x, y] = (0, 0, 1 + max(0, min(254, round((l - lo) / max(1, hi - lo) * 254))))
    return idx


def greenish(px):
    """Yellow-green skin (goblin ears and faces): never hair, even inside the head band."""
    import colorsys
    h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
    return 0.11 <= h <= 0.40 and sat > 0.25


def build_bodies(info):
    info["builds"] = {}; info["family_of"] = FAMILY_OF
    a0 = SW["m"]["n_idle0"][2]
    for race, key in BUILDS.items():
        for b in "mf":
            if race in SHARED and b != SHARED[race]:
                continue
            if not all(os.path.exists(build_src(key, None, b, k)) for k in K):
                continue
            base = {k: L(build_src(key, None, b, k)) for k in K}
            place = {k: ((C - im.width) // 2, FOOT - im.getbbox()[3]) for k, im in base.items()}
            def bcell(im, k):
                c = Image.new("RGBA", (C, C)); c.alpha_composite(im, place[k]); return c
            cells = {k: bcell(base[k], k) for k in K}
            sw = {}
            for k in K:
                blade, ring = sword_pts(cells[k])
                grip, tip, ang = W.axis(blade, W.body_centre(cells[k]))
                sw[k] = [blade | ring, grip, ang, tip, ((tip[0] - grip[0]) ** 2 + (tip[1] - grip[1]) ** 2) ** 0.5]
            full = sorted(v[4] for v in sw.values())[len(K) // 2]
            for k, v in sw.items():
                if v[4] < 0.75 * full:
                    v[1] = (round(v[3][0] - math.cos(v[2]) * full), round(v[3][1] - math.sin(v[2]) * full))
            d = f"{key}_{b}"
            fams = []
            for fam in FAMILY_SRC:
                if not all(os.path.exists(build_src(key, fam, b, k)) for k in K):
                    print("missing", race, b, fam); continue
                out, idxs = [], []
                for k in K:
                    c = bcell(L(build_src(key, fam, b, k)), k); p = c.load()
                    pts = set(sw[k][0])
                    near = {(x + dx, y + dy) for (x, y) in pts for dx in range(-3, 4) for dy in range(-3, 4)}
                    own, ring = sword_pts(c)
                    if own and len(own & near) * 2 >= len(own):
                        pts |= own | ring
                    for (x, y) in sorted(pts):
                        l = next((p[x - dd, y] for dd in (1, 2, 3) if x - dd >= 0 and (x - dd, y) not in pts and p[x - dd, y][3]), None)
                        r = next((p[x + dd, y] for dd in (1, 2, 3) if x + dd < C and (x + dd, y) not in pts and p[x + dd, y][3]), None)
                        p[x, y] = l if (l and r) else (0, 0, 0, 0)
                    bb = c.getbbox(); top = bb[1] + (bb[3] - bb[1]) * 0.28  # big builds' shoulders reach the head band
                    hair = {q for q, kd in R.masks(c).items() if kd == "hair" and not greenish(p[q]) and q[1] < top}
                    out.append(c); idxs.append(dye_index(c, fam, index_of(c, hair)))
                save(f"{d}/outfit_{fam}", out, idxs)
                fams.append(fam)
            for wt, drawing in WEAPON_DRAWINGS.items():
                mir = mirrored(drawing)
                wc = []
                for k in K:
                    g, a = sw[k][1], sw[k][2]
                    if k.startswith("n_atk"):
                        wc.append(drawing.placed((C, C), g, a))
                    elif k.startswith("s"):
                        wc.append(mir.placed((C, C), g, mir.ang + a - (math.pi - a0)))
                    else:
                        wc.append(drawing.placed((C, C), g, drawing.ang + a - a0))
                save(f"{d}/weapon_{wt}", wc)
            info["hand"][d] = [list(sw[k][1]) for k in K]
            if fams:  # a body is only offered once it has an outfit
                info["builds"].setdefault(race, {"key": key, "bodies": {}, "skin": race not in OWN_SKIN})["bodies"][b] = fams
            print(race, b, "build done:", fams)
            if race in SHARED and fams:
                e = info["builds"][race]
                for ob in "mf":
                    e["bodies"][ob] = fams
                e["share"] = SHARED[race]
            for fr, fk in FEATURE_BUILDS.items():
                fp = {k: os.path.join(FEATURES, f"{fr.lower()}_{b}_{k}.png") for k in K}
                if fk != key or not fams or not all(os.path.exists(q) for q in fp.values()):
                    continue
                front, back = build_feature(cells, {k: bcell(L(fp[k]), k) for k in K}, sw)
                save(f"{d}/race_{fr.lower()}", front)
                save(f"{d}/race_{fr.lower()}_back", back)
                e = info["builds"].setdefault(fr, {"key": key, "bodies": {}, "skin": fr not in OWN_SKIN, "feature": f"race_{fr.lower()}"})
                e["bodies"][b] = fams
                print(fr, b, "feature done")


def build_feature(cells, edits, sw):
    """A race drawn over another build (werewolf on the orc): the pixels the edit changed, minus the
    sword and specks and small re-shadings inside the body. Front view: what sticks out beside or below
    the body (the tail) goes to a layer drawn behind it."""
    front, back = [], []
    for k in K:
        bp, ep = cells[k].load(), edits[k].load()
        bb = cells[k].getbbox(); hl = bb[1] + (bb[3] - bb[1]) * 0.28
        blade, ring = sword_pts(edits[k])
        own = {(x + dx, y + dy) for (x, y) in blade | ring for dx in (-1, 0, 1) for dy in (-1, 0, 1)} if blade else set()
        pts = set()
        for y in range(C):
            for x in range(C):
                e, o = ep[x, y], bp[x, y]
                if not e[3] or (o[3] and sum(abs(e[i] - o[i]) for i in range(3)) <= 40):
                    continue
                if (x, y) in sw[k][0] or (x, y) in own:
                    continue  # the sword: the base's, or the edit's own (moved) copy
                pts.add((x, y))
        keep = [c for c in (comps(pts) if pts else [])
                if len(c) >= 6 and not (all(bp[q][3] and q[1] > hl for q in c) and len(c) < 40)]
        pts = set().union(*keep) if keep else set()
        f = Image.new("RGBA", (C, C)); bk = Image.new("RGBA", (C, C))
        for (x, y) in pts:
            if k.startswith("s") and y > hl and not bp[x, y][3]:
                bk.putpixel((x, y), ep[x, y])
            else:
                f.putpixel((x, y), ep[x, y])
        front.append(f); back.append(bk)
    return front, back

if __name__ == "__main__":
    main()
