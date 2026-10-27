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
import colorsys, json, math, os, sys
from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
REPO = os.path.abspath(os.path.join(PL, "..", "..", ".."))
OUT = os.path.join(REPO, "art", "heroes")
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "classes")); sys.path.insert(0, os.path.join(PL, "hair"))
import recolour as R, weapons as W, headswap as HS, race_reg as RR

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


def sword_pts(im, near=None, hint=None):
    """The blade (most blade-like group of metal/white pixels) plus its outline ring.
    near: a stone body (golem) is grey like steel, so take only bright neutral steel and the group
    nearest to where the human frame holds its blade (these points).
    hint: the human frame's blade; groups far from it score lower (a white shirt neckline is
    blade-shaped too), and pieces on the same line (a tip showing past the head) join the blade."""
    px = im.load()
    best, bs = set(), 0
    if near:
        hx, hy = sum(p[0] for p in near) / len(near), sum(p[1] for p in near) / len(near)
        met = {(x, y) for y in range(im.height) for x in range(im.width)
               if px[x, y][3] and R.lum(px[x, y][:3]) >= 170 and max(px[x, y][:3]) - min(px[x, y][:3]) < 40}
        cs = [c for c in comps(met) if len(c) >= 5] if met else []
        best = min(cs, key=lambda c: (sum(p[0] for p in c) / len(c) - hx) ** 2 + (sum(p[1] for p in c) / len(c) - hy) ** 2, default=set())
        # the blade's shaded side and hilt: neutral or brown pixels touching the bright edge, 2 steps out
        for _ in range(2):
            best = best | {(x + dx, y + dy) for (x, y) in best for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                           if 0 <= x + dx < im.width and 0 <= y + dy < im.height and px[x + dx, y + dy][3]
                           and R.kind(px[x + dx, y + dy][:3]) != "outline" and R.lum(px[x + dx, y + dy][:3]) >= 60
                           and abs(x + dx - hx) + abs(y + dy - hy) < 40}
        met = set()
    else:
        met = {(x, y) for y in range(im.height) for x in range(im.width) if px[x, y][3] and R.kind(px[x, y][:3]) in ("metal", "shirt")}
    groups = comps(met) if met else []
    if hint:
        hx, hy = sum(p[0] for p in hint) / len(hint), sum(p[1] for p in hint) / len(hint)
    for c in groups:
        if len(c) < 10:
            continue
        if sum(R.lum(px[q][:3]) for q in c) / len(c) < 115:
            continue  # blades are bright steel; a dull grey-green group is skin (orc backs), not a sword
        l2 = max((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 for a in c for b in c)
        sc = l2 / len(c)
        if hint:
            d = ((sum(p[0] for p in c) / len(c) - hx) ** 2 + (sum(p[1] for p in c) / len(c) - hy) ** 2) ** 0.5
            sc /= 1 + d / 12
        if sc > bs:
            best, bs = c, sc
    if hint and len(best) >= 2:
        a, b = max(((p, q) for p in best for q in best), key=lambda pq: (pq[0][0] - pq[1][0]) ** 2 + (pq[0][1] - pq[1][1]) ** 2)
        ln = max(1e-6, ((b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2) ** 0.5)
        off = lambda q: abs((b[0] - a[0]) * (a[1] - q[1]) - (a[0] - q[0]) * (b[1] - a[1])) / ln
        for c in groups:
            if c is best or len(c) < 2 or sum(R.lum(px[q][:3]) for q in c) / len(c) < 115:
                continue
            gap = min(min(abs(q[0] - e[0]) + abs(q[1] - e[1]) for e in (a, b)) for q in c)
            if gap <= 14 and all(off(q) <= 1.6 for q in c):
                best = best | c  # the rest of the same blade (its tip past the head)
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
    n = cells[0].width  # 96, or F for the weapon cells
    s = Image.new("RGBA" if cells[0].mode == "RGBA" else "RGB", (n * len(cells), n))
    for i, c in enumerate(cells):
        s.paste(c, (i * n, 0))
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


def despeck4(c, smallest):
    """Drops bits joined to the rest only at a corner (4-connected islands under `smallest` pixels, never the
    main shape): loose hair over the chest, a lump under a lock read as specks at phone size."""
    p = c.load()
    pts = {(x, y) for y in range(c.height) for x in range(c.width) if p[x, y][3]}
    seen, parts = set(), []
    for q in pts:
        if q in seen:
            continue
        g, todo = [], [q]; seen.add(q)
        while todo:
            x, y = todo.pop(); g.append((x, y))
            for r in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if r in pts and r not in seen:
                    seen.add(r); todo.append(r)
        parts.append(g)
    parts.sort(key=len)
    gone = 0
    for g in parts[:-1]:
        if len(g) < smallest:
            gone += len(g)
            for q in g:
                p[q] = (0, 0, 0, 0)
    SPECKS[0] += gone
    return c


SPECKS = [0]


def save(name, cells, idx=None):
    os.makedirs(os.path.dirname(os.path.join(OUT, name)), exist_ok=True)
    base = os.path.basename(name)
    whole = base.startswith("outfit_")
    cells = [despeck(c, 4, 20 if whole else 0) for c in cells]  # islands of 1-3 px (Juzo: specks by her hair, R3)
    if base.startswith("hair_") or base.startswith("race_"):
        cells = [despeck(despeck4(c, 8 if base.startswith("hair_") else 3), 4) for c in cells]  # its cuts leave crumbs
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
    only = os.environ.get("BUILDS_ONLY")
    if only:  # a look at some body builds (debug): the standard bodies as baked, heroes.json left alone
        with open(os.path.join(OUT, "heroes.json")) as f:
            info = json.load(f)
        for b in "mf":
            HEAD_FIX[b] = head_fixes(b, sheet_cells(f"{b}/outfit_warrior"))
        build_bodies(info, only.split(","))
        print("drawn hair taken off the build outfits:", BARED)
        return
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
                    if FAMILY_OF.get(cls.title()) == "plate":
                        sym_front(cells)
                    cells = [despeck(c, 4, 20) for c in cells]  # as save() will: a loose bit it drops misled the fist search
                    forearms(b, cells)
                    if cls == "warrior" and not tier:
                        HEAD_FIX[b] = head_fixes(b, cells)
                    idxs = [index_of(c) for c in cells]
                    save(f"{b}/outfit_{cls}" + (f"_t{tier}" if tier else ""), cells, idxs)
                    if b == "m" and not tier:
                        dy = class_dye(cells, idxs)
                        if dy:
                            info.setdefault("dye", {})[cls] = dy
                    info["classes"].setdefault(cls, {}).setdefault(b, []).append(int(tier or 0))
        if b == "f":
            borrowed_tiers(info)
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
            offs = fixed(b, offs)
            cn, hn = head_cells(b, src["n"], base["n"], offs)
            cs, hs = head_cells(b, src["s"], base["s"], offs)
            for i in (7, 8):
                neck(b, cs[i], i)
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
                dx, dy = fixed(b, OFF_OWN[b])[k]
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
        hands = {k: SW[b][k][1] for k in K}
        info["hand"][b] = [list(mid_hands(hands)[k]) for k in K]
        for wt, drawing in WEAPON_DRAWINGS.items():
            save(f"{b}/weapon_{wt}", weapon_cells(wt, drawing, hands, b))
            if wt not in info["weapons"]:
                info["weapons"].append(wt)
        print(b, "weapons done")
        # ---- race signature features (standard-body races) ----
        for race in RACES:
            paths = {k: os.path.join(FEATURES, f"{race.lower()}_{b}_{k}.png") for k in K}
            if not all(os.path.exists(p) for p in paths.values()):
                continue
            front, back = race_cells(b, paths, race)
            save(f"{b}/race_{race.lower()}", front, [index_of(c) for c in front])
            if any(c.getbbox() for c in back):
                save(f"{b}/race_{race.lower()}_back", back, [index_of(c) for c in back])
            info.setdefault("races", {}).setdefault(race, []).append(b)
        print(b, "races done")
        derived_looks(b, info)
        print(b, "looks done")
    build_bodies(info)
    print("specks dropped (corner-only bits):", SPECKS[0], "px")
    print("race layers registered:", *REG_LOG, sep=chr(10) + "  ")
    print("drawn hair taken off the build outfits:", BARED)
    body_axes(info)
    with open(os.path.join(OUT, "heroes.json"), "w", newline=chr(10)) as f:
        json.dump(info, f, indent=1)


NECK = 3  # skin rows between the chin and the collar on the portrait (Juzo: the chin sat on the chest plate)
HEAD_FIX = {}  # body -> frame -> (dx, dy, collar row, neck centre x, chin row) for the portrait frames


def head_fixes(b, cells):
    """Where the portrait head goes on the body (Juzo, Gear page: a pasted-on head, no neck, off-centre):
    centred over the shoulders and lifted to leave NECK rows above the collar (the first outfit row under
    the chin). cells: the warrior's base frames (every outfit shares the head). The chin is the bald head's
    last drawn row in the middle columns, as the hair sheets place it (head_bottom() of her own rotation was
    a row off: an empty row under her jaw, Fable hero R4 item 2)."""
    patch = HS.head_patch(L(os.path.join(PL, "hair", "lib", "bald_south.png")), ROT["m"]["s"])
    out = {}
    for i, k in enumerate(K):
        if not k.startswith("s"):
            continue
        dx, dy = OFF_M[b][k]
        pts = [(x + dx, y + dy) for (x, y), col in patch.items() if col[3]]
        low = max(y for _, y in pts)
        xs = [x for x, y in pts if y >= low - 2]
        ccx = sum(xs) / len(xs)
        chin = max(y for x, y in pts if abs(x - ccx) <= 3)
        p = cells[i].load(); bb = cells[i].getbbox()
        top = next(y for y in range(C) if any(p[x, y][3] for x in range(round(ccx) - 2, round(ccx) + 3)))
        row = min(bb[3] - 1, top + 4)
        rx = [x for x in range(C) if p[x, row][3]]
        fx = round((min(rx) + max(rx)) / 2 - ccx) if k == "s_idle0" else out["s_idle0"][0]  # one sideways place: no head hop
        fy = top - 1 - NECK - chin
        out[k] = (fx, fy, top, ccx + fx, chin + fy)
    print(b, "portrait head fix:", {k: v[:3] for k, v in out.items()})
    return out


def fixed(b, offs):
    """Head offsets with the portrait head fix added."""
    return {k: (o[0] + HEAD_FIX.get(b, {}).get(k, (0, 0))[0], o[1] + HEAD_FIX.get(b, {}).get(k, (0, 0))[1])
            for k, o in offs.items()}


def neck(b, c, i):
    """A neck under the portrait chin down to the collar: skin, a shadow row under the chin, the outline at
    both sides, laid only where the head cell is empty (long hair stays over it)."""
    k = K[i]; fix = HEAD_FIX.get(b, {}).get(k)
    if not fix:
        return
    _, _, top, cx, _ = fix
    rot = ROT[b]["s"]; rp = rot.load(); m = R.masks(rot)
    skin = sorted((R.lum(rp[q][:3]), rp[q]) for q, kd in m.items() if kd == "skin")
    line = min((R.lum(rp[x, y][:3]), rp[x, y]) for y in range(rot.height) for x in range(rot.width) if rp[x, y][3])[1]
    shadow, base = skin[len(skin) // 4][1], skin[len(skin) * 3 // 5][1]
    hb = HS.head_bottom(rot)
    w = max(5, round(0.3 * len({x for x in range(rot.width) if rp[x, hb - 2][3]})))
    x0 = round(cx - w / 2)
    p = c.load()
    jaw = [y for y in range(top) for x in range(round(cx) - 3, round(cx) + 4) if 0 <= x < C and p[x, y][3]]
    if not jaw:
        return
    chin = max(jaw)  # this style's own jaw row: the neck starts on the next row, no gap
    for y in range(chin + 1, top):
        for x in range(x0 - 1, x0 + w + 1):
            if 0 <= x < C and 0 <= y < C and not p[x, y][3]:
                p[x, y] = line if x in (x0 - 1, x0 + w) else (shadow if y == chin + 1 else base)


def lum255(px):
    return (299 * px[0] + 587 * px[1] + 114 * px[2]) // 1000


def forearms(b, cells):
    """A forearm from the pauldron down to each fist on the portrait (Fable hero R4 item 6: both fists floated
    beside the hips with nothing between them and the shoulder plates): per side, at the fist's two inner
    columns, the rows between the shoulder band and the fist's top take the sleeve colour (the commonest
    mid colour on the pauldron's bottom rows there), outlined on both sides. Twice: one side's new forearm
    moves the band the other side's fist is found under."""
    for i in (7, 8, 7, 8):
        c = cells[i]; p = c.load(); bb = c.getbbox()
        if not bb:
            continue
        width = {y: [x for x in range(C) if p[x, y][3]] for y in range(bb[1], bb[3])}
        band = [y for y in range(bb[1], bb[1] + int(0.4 * (bb[3] - bb[1]))) if width[y]]
        wmax = max(max(width[y]) - min(width[y]) + 1 for y in band)
        pb = max(y for y in band if max(width[y]) - min(width[y]) + 1 >= 0.8 * wmax)  # the pauldrons' last row
        if pb + 1 >= bb[3] or not width[pb + 1]:
            continue
        tl, tr = min(width[pb + 1]), max(width[pb + 1])  # the torso under them
        dark = min((p[x, y] for y in range(bb[1], bb[3]) for x in width[y]), key=lambda q: lum255(q))
        for side in (-1, 1):
            out = lambda y: [x for x in width.get(y, []) if (x < tl - 1 if side < 0 else x > tr + 1)]
            y1 = next((y for y in range(pb + 1, min(bb[3], pb + 16)) if out(y) and out(y + 1)), None)
            # a fist is 2 rows or more (a 1-row stub beside the hand is an edit's leftover hilt)
            fist = [(x, y) for y in range(y1, min(bb[3], pb + 16)) for x in out(y)] if y1 else []
            if not fist:
                continue
            ft = min(y for _, y in fist)
            tops = [x for x, y in fist if y <= ft + 2]
            xi = max(tops) if side < 0 else min(tops)
            cols = sorted((xi, xi + side))
            if ft - pb - 1 < 1:
                continue
            near = [p[x, y][:3] for y in (pb, pb - 1) for x in range(cols[0] - 1, cols[1] + 2)
                    if p[x, y][3] and lum255(p[x, y]) >= 40]
            sleeve = (max(set(near), key=near.count) + (255,)) if near else p[xi, ft]
            for y in range(pb + 1, ft):
                for x in cols:
                    if not p[x, y][3]:
                        p[x, y] = sleeve
                for x in (cols[0] - 1, cols[1] + 1):
                    if 0 <= x < C and not p[x, y][3]:
                        p[x, y] = dark


def sym_front(cells):
    """The plate outfits from the front read as one symmetric suit (Juzo, Gear page: a shoulder plate on one
    side only, dark plates and red cloth mixed): the shoulders and chest of the portrait frames (the top
    40% of the body, above the hands) mirrored from the fuller side about the hips' centre."""
    for i in range(7, 9):
        c = cells[i]; p = c.load(); bb = c.getbbox()
        ax = RR.body_axis(c)
        band = range(bb[1], bb[1] + int(0.4 * (bb[3] - bb[1])))
        left = sum(1 for y in band for x in range(C) if p[x, y][3] and x < ax)
        right = sum(1 for y in band for x in range(C) if p[x, y][3] and x > ax)
        src = c.copy(); sp = src.load()
        for y in band:
            for x in range(C):
                if (x > ax) if left >= right else (x < ax):
                    mx = round(2 * ax - x)
                    p[x, y] = sp[mx, y] if 0 <= mx < C else (0, 0, 0, 0)


def body_axes(info):
    """The body's centre column per frame (hips), per body folder: HeroArt mirrors the free hand onto the
    weapon hand about it when nothing is held."""
    ax = info.setdefault("axis", {})
    for d in sorted(os.listdir(OUT)):
        for fam in ("warrior", "plate"):
            path = os.path.join(OUT, d, f"outfit_{fam}.png")
            if os.path.exists(path):
                im = L(path)
                ax[d] = [round(RR.body_axis(im.crop((i * C, 0, i * C + C, C))), 1) for i in range(len(K))]
                break


def borrowed_tiers(info, cls="warrior"):
    """Her class tiers without a generation (Juzo: no PixelLab for rounds 3-5; Fable hero R3 item 9): what
    each of his tiers added to his base outfit (pauldrons and gold trim, the cape, the ornate plates and
    runes) carried onto her base frames (the outfit cells start at the shoulders: no head to leave out). Each of her pixels looks up the matching place
    on his frame (same rows from the top of the body to the feet, same columns from the hip centre,
    scaled by the shoulder width) and takes his tier's pixel there when his tier changed it."""
    def cells_of(path):
        if not os.path.exists(path + ".png"):
            return None
        im = L(path + ".png")
        return [im.crop((i * C, 0, i * C + C, C)) for i in range(len(K))]
    def frame(c):
        p = c.load(); bb = c.getbbox(); h = bb[3] - bb[1]
        def span(y):
            xs = [x for x in range(C) if p[x, y][3]]
            return (min(xs), max(xs)) if xs else (C // 2, C // 2)
        hip = [x for y in range(bb[1] + int(h * 0.6), bb[1] + int(h * 0.7)) for x in range(C) if p[x, y][3]]
        sh = span(bb[1] + int(h * 0.45))
        return bb[1], bb[3] - 1, sum(hip) / max(1, len(hip)), sh[1] - sh[0] + 1
    mb, fb = cells_of(os.path.join(OUT, "m", f"outfit_{cls}")), cells_of(os.path.join(OUT, "f", f"outfit_{cls}"))
    have = info["classes"].get(cls, {}).get("f", [0])
    for tier in info["classes"].get(cls, {}).get("m", []):
        mt = cells_of(os.path.join(OUT, "m", f"outfit_{cls}_t{tier}"))
        if not tier or tier in have or not mt or not mb or not fb:
            continue
        out = []
        for i in range(len(K)):
            m0, m1, f0 = mb[i].load(), mt[i].load(), fb[i].copy()
            mtop, mbot, mcx, mw = frame(mb[i]); ftop, fbot, fcx, fw = frame(fb[i])
            sx = max(0.8, min(1.25, fw / max(1, mw))); sy = (fbot - ftop) / max(1, mbot - mtop)
            fp = f0.load(); orig = fb[i].load(); took = set()
            for y in range(C):
                my = round(mtop + (y - ftop) / sy)
                if my < 0 or my >= C:
                    continue
                for x in range(C):
                    mx = round(mcx + (x - fcx) / sx)
                    if not 0 <= mx < C or not m1[mx, my][3]:
                        continue
                    a, b0 = m1[mx, my], m0[mx, my]
                    if RR.steel(a) and not b0[3]:
                        continue  # a sword his tier edit drew (t15 atk2), not armour
                    if not b0[3] or sum(abs(a[j] - b0[j]) for j in range(3)) > 60:
                        fp[x, y] = a; took.add((x, y))
            for (x, y) in took:  # a lone rune spark or hem ember reads as a speck at 1x (Fable hero R4 item 12)
                if sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy) and (x + dx, y + dy) in took) < 2:
                    fp[x, y] = orig[x, y]
            out.append(f0)
        out = [despeck(c, 4, 20) for c in out]
        forearms("f", out)  # his tier's edit over her base can cut the forearm her base had
        save(f"f/outfit_{cls}_t{tier}", out, [index_of(c) for c in out])
        info["classes"][cls].setdefault("f", []).append(tier)
        print("f", cls, "tier", tier, "borrowed from his")


RACES = ["Elf", "Angel", "Demon", "Beastkin", "Dragonkin", "Undead", "Vampire", "Lich"]
FEATURES = os.path.abspath(os.path.join(REPO, "..", "solaria_dev", "claude", "art_test", "races", "features", "raw"))


def race_cells(b, paths, race=""):
    """A race's signature feature (PixelLab edits of the base frames, 'add only ...'): the pixels the edit
    changed, minus edit noise on the hair (the hair is its own layer) and specks. Front view: what sticks
    out below the head (wings, tail) goes to a layer drawn BEHIND the body; the rest is drawn on top."""
    front, back, found = [], [], {}
    for k in K:
        base = CELL[b][k]
        ed = cell(L(paths[k]), b, k)
        bp, ep = base.load(), ed.load()
        bm = R.masks(base)
        hair_cols = {bp[p][:3] for p, kd in bm.items() if kd == "hair"}
        near_sword = {(x + i, y + j) for (x, y) in SW[b][k][0] for i in range(-2, 3) for j in range(-2, 3)}
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
                if R.lum(e[:3]) < 80 and (x, y) in near_sword:
                    continue  # nor the dark trace of the old sword the edit kept (lines across the angel wings)
                pts.add((x, y))
        hl = (OFF_OWN[b][k][1] + HS.head_bottom(ROT[b][d_of(k)]))
        # keep real features: specks go, and so do small changes entirely inside the body below the head
        # (the edit re-shading the clothes); eyes, fangs and the like sit in the head and stay
        keep = []
        for c in comps(pts) if pts else []:
            inside = all(bp[q][3] and q[1] > hl for q in c)
            if len(c) >= 6 and not (inside and len(c) < 25):
                keep.append(c)
        found[k] = (set().union(*keep) if keep else set(), ep, bp, hl)
    for k in K:
        pts, ep, bp, hl = found[k]
        if race in HEAD_ONLY:  # only what overlaps the reference feature, moved with the head (dilated 2 px):
            r0 = "s_idle0" if k.startswith("s") else HEAD_REF.get((race, b), "n_idle0")  # the mid-swing edits
            if k != r0:  # grew hair and face residue around the ears (Fable hero R2 item 8, R3 item 4)
                dx = OFF_OWN[b][k][0] - OFF_OWN[b][r0][0]; dy = OFF_OWN[b][k][1] - OFF_OWN[b][r0][1]
                near = {(x + dx + i, y + dy + j) for (x, y) in found[r0][0] for i in range(-2, 3) for j in range(-2, 3)}
                pts &= near  # pixel by pixel: the residue is joined to the ears, so whole parts would keep it
        if race in BONE_OFF:  # the bone drawn over the clothes below the head (a spine on the coat) goes
            pts = no_bone(pts, ep, hl)
        f = Image.new("RGBA", (C, C)); bk = Image.new("RGBA", (C, C))
        fx, fy = HEAD_FIX[b][k][:2] if k in HEAD_FIX.get(b, {}) else (0, 0)
        for (x, y) in pts:
            if k.startswith("s") and y > hl:
                if not bp[x, y][3]:
                    bk.putpixel((x, y), ep[x, y])  # wings / tail peeking out from behind
            elif y <= hl and 0 <= x + fx < C and 0 <= y + fy < C:
                f.putpixel((x + fx, y + fy), ep[x, y])  # ears, horns, a halo: with the head (HEAD_FIX)
            else:
                f.putpixel((x, y), ep[x, y])
        front.append(f); back.append(bk)
    bodies = []  # the bare frames without the sword (in atk2/atk3 it crosses the hips and pulled the axis 9 px)
    for k in K:
        bc = CELL[b][k].copy(); bcp = bc.load()
        for q in SW[b][k][0]:
            bcp[q] = (0, 0, 0, 0)
        bodies.append(bc)
    front = RR.register(front, bodies, race, REG_LOG)
    return front, back


HEAD_ONLY = ["Elf", "Demon"]  # ears and horns: every frame keeps only the idle's feature, moved with the head
HEAD_REF = {("Elf", "f"): "n_atk0"}  # her idle edits drew hair and skin under the ears (19 rows to atk0's 8)
REG_LOG = []  # what race_reg repaired, printed after the bake
BONE_OFF = ["Undead"]  # keep the soul fire and the eyes; a glowing spine over the outfit read as a caterpillar


def no_bone(pts, ep, hl):
    """The feature's pixels without pale bone below the head line, nor the outline left around it."""
    import colorsys
    def bone(px):
        h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
        return v > 0.5 and sat < 0.4 and (h < 0.2 or h > 0.9 or sat < 0.12)
    gone = {q for q in pts if q[1] > hl and bone(ep[q])}
    pts = pts - gone
    for _ in range(3):  # the dark outline that hugged the bone
        edge = {q for q in pts if q[1] > hl and R.lum(ep[q][:3]) < 90
                and any((q[0] + i, q[1] + j) in gone for i in (-1, 0, 1) for j in (-1, 0, 1))}
        if not edge:
            break
        pts -= edge; gone |= edge
    keep = [c for c in comps(pts) if len(c) >= 6] if pts else []
    return set().union(*keep) if keep else set()


def mirrored(w):
    """The same weapon drawing flipped left-right (held in the other hand as seen from the front)."""
    m = W.Weapon.__new__(W.Weapon)
    m.img = w.img.transpose(Image.FLIP_LEFT_RIGHT)
    m.x0, m.y0 = w.x0, w.y0
    fx = lambda p: (w.x0 + w.img.width - 1 - (p[0] - w.x0), p[1])
    m.grip, m.tip = fx(w.grip), fx(w.tip)
    m.ang = math.atan2(m.tip[1] - m.grip[1], m.tip[0] - m.grip[0])
    return m


# Weapon cells are bigger than the body cell (the body cell sits in the middle), so a staff or spear in the
# swing is never cut by the 96-px cell edge. HeroArt lays the 96 layers PAD in from each side.
PAD = 16
F = C + 2 * PAD
# where the hand holds the weapon, as a fraction from its grip end to its tip (a staff or spear a third up the
# shaft, so its foot rests near the ground and a swing reaches both ways; a bow by its middle)
HOLD = {"staff": 0.3, "spear": 0.3, "bow": 0.5}
# at rest (idle, hit; seen from behind) every weapon is held up beside the body, angle in degrees (0 = right,
# -90 = straight up), so it reads at phone size; the portrait holds the mirror image in the other hand
REST = {"sword": -60, "dagger": -58, "axe": -64, "mace": -68, "spear": -84, "bow": -88, "staff": -84}
HIT_TILT = 22  # the hit frame knocks the tip back (clockwise)
# the portrait holds the short weapons upright beside the hip, tip at shoulder height (the -60 sword was a thin
# dash leaving the hip on the Gear page: Fable hero R4 item 5); the long ones as REST
PORTRAIT_REST = {"sword": -82, "dagger": -80, "axe": -78, "mace": -78}
GRIP_IN = 2  # px the portrait grip moves into the fist, toward the body (the hilt sat on its outer edge)
WIND_UP = 20  # degrees atk0's blade turns back toward rest: atk0 and atk1 were one pose (Fable hero R4 item 14)


def held(w, f):
    """The same drawing gripped f of the way from its grip end to its tip."""
    if not f:
        return w
    m = W.Weapon.__new__(W.Weapon)
    m.img, m.x0, m.y0, m.tip, m.ang = w.img, w.x0, w.y0, w.tip, w.ang
    m.grip = (round(w.grip[0] + (w.tip[0] - w.grip[0]) * f), round(w.grip[1] + (w.tip[1] - w.grip[1]) * f))
    return m


def swing(b):
    """The swing's angle per attack frame (the standard body b's sword) and its hand points. The drawn bodies
    repeat the low-left pose on atk2 and atk3, so atk2 becomes the middle of the arc: the blade across the
    back, between the raised atk1 and the low follow-through atk3."""
    a = {k: SW[b][k][2] for k in K if k.startswith("n_atk")}
    d = (a["n_atk3"] - a["n_atk1"]) % (2 * math.pi) - 2 * math.pi  # the way over the head (decreasing angle)
    a["n_atk2"] = a["n_atk1"] + d / 2
    return a


def mid_hands(hands):
    """The hand points as the weapon is drawn: atk2's halfway between atk1's and atk3's (the swing's middle)."""
    out = dict(hands)
    out["n_atk2"] = ((hands["n_atk1"][0] + hands["n_atk3"][0]) // 2, (hands["n_atk1"][1] + hands["n_atk3"][1]) // 2)
    return out


def weapon_cells(wt, drawing, hands, b, bodies=None):
    """The weapon on every frame (F x F cells, the body cell PAD in): one drawing, turned and pinned to the hand.
    bodies: the frames of the body it is held by (the fist covers the grip on the portrait)."""
    sb = b
    sw_a = swing(sb)
    w = held(drawing, HOLD.get(wt, 0))
    mir = held(mirrored(drawing), HOLD.get(wt, 0))
    rest = math.radians(REST[wt])
    i0 = SW[sb]["n_idle0"][2]
    cells = []
    for k in K:
        g = mid_hands(hands)[k]  # the hand halfway along the arc too
        g = (g[0] + PAD, g[1] + PAD)
        if k.startswith("n_atk"):
            a = sw_a[k]
            if k == "n_atk0":
                d = (rest - a + math.pi) % (2 * math.pi) - math.pi
                a += math.copysign(min(abs(d), math.radians(WIND_UP)), d)
            if wt in HOLD:  # a long weapon never swings steeply down: its far end would go through the floor
                deg = math.degrees(a) % 360
                a = math.radians(150 if 90 < deg < 150 else 30 if 30 < deg <= 90 else deg)
            cells.append(w.placed((F, F), g, a))
        elif k.startswith("s"):
            body = (bodies or CELL[b])[k]
            ax = RR.body_axis(body) + PAD
            g = (g[0] + (GRIP_IN if g[0] < ax else -GRIP_IN), g[1])
            c = rested(mir, g, math.pi - math.radians(PORTRAIT_REST.get(wt, REST[wt])), PORTRAIT_LOW)
            cells.append(in_fist(c, g))
        else:  # idle sways a little with the drawn arm; the hit frame tilts back
            ang = rest + (SW[sb][k][2] - i0) * 0.4 + (math.radians(HIT_TILT) if k == "n_hit" else 0)
            cells.append(rested(w, g, ang, FOOT + PAD))
    return cells


def in_fist(c, g, need=8):
    """A portrait weapon whose grip came to rest beside the fist (the upright sword's ended 3 rows over it, the
    axe's handle 1 px off: Fable hero R4 item 5) slides so its lower end's middle sits in the hand, unless it
    already has `need` pixels within 3 px of it. Measured on what save() keeps (its despeck took the sword's
    loose 1-3 px pommel, leaving the blade over the fist)."""
    c = despeck(c, 4); p = c.load(); bb = c.getbbox()
    held = lambda: sum(1 for y in range(g[1] - 3, g[1] + 4) for x in range(g[0] - 3, g[0] + 4)
                       if 0 <= x < c.width and 0 <= y < c.height and p[x, y][3])
    if not bb or held() >= need:
        return c
    xs = [x for x in range(bb[0], bb[2]) if p[x, bb[3] - 1][3]]
    dx = round(g[0] - sum(xs) / len(xs)); dy = min(g[1] + 1, PORTRAIT_LOW) - (bb[3] - 1)
    out = Image.new("RGBA", c.size); out.paste(c, (dx, dy))
    return out


PORTRAIT_LOW = 95  # Sprites.PORTRAIT_CROP ends at frame row 99: a limb ending on it read as cut (Fable hero R3 item 13)


def rested(w, g, ang, low):
    """A weapon at rest, tilted the least it takes (5-degree steps either way) to keep its lower end at or
    above row `low`: a bow held by its middle hung 3-9 rows under the feet and out of the portrait."""
    for d in [0] + [s * t for t in range(5, 90, 5) for s in (1, -1)]:
        c = w.placed((F, F), g, ang + math.radians(d))
        bb = c.getbbox()
        if not bb or bb[3] - 1 <= low:
            return c
    return w.placed((F, F), g, ang)


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
# Golem is no longer playable (Juzo, Oct 24): its drawings stay in races/raw (a monster candidate), not baked into the app
BUILDS = {"Goblin": "goblin", "Dwarf": "dwarf", "Orc": "orc", "Fairy": "fairy"}
OWN_SKIN = ["Goblin", "Orc", "Werewolf"]  # races whose drawn skin hue is their signature: no skin recolour
# races drawn as a feature layer on another build's frames (PixelLab edits of that build's base frames)
FEATURE_BUILDS = {"Werewolf": "orc"}
# a fixed skin for a race drawn over a build (light to dark): the werewolf greys to match its fur
SKIN_RAMP = {"Werewolf": ["#c4c4c8", "#9a9aa0", "#76767c", "#525258", "#323238"]}
SHARED = {}  # builds drawn once for both bodies, {race: body} (the golem was the only one)
HAIRLESS = []  # races whose drawn head has no hair to recolour
STONE = []  # grey stone bodies: the sword is found as bright steel only
# wings cut from the build's own base frames (the outfit edits leave them out, so the class outfit
# shows): over the back in battle, behind the body on the portrait. Hue range 0-1.
WINGS = {"Fairy": (0.68, 0.92)}
# hovering builds: feet this many art pixels above the foot row, per frame (idle frames bob)
FLOAT = {}  # was the fairy 4-6 px up: it read as a mis-registered sprite over the shadow (Fable hero R2 item 10)
CROWNED = ["Dwarf", "Goblin", "Orc", "Fairy"]  # build races with a crown awakening (races.gd look "crown"; Fable hero R3 item 8)
HAIR_LOW = 76  # the lowest row a build's fitted hair reaches (the fairy's very long hair hung under her feet)
FAMILY_SRC = {"plate": "warrior", "robe": "mage", "leather": "leather", "cloth": "cloth"}
FAMILY_OF = {"Warrior": "plate", "Knight": "plate", "Sentinel": "plate",
             "Mage": "robe", "Cleric": "robe", "Acolyte": "robe", "Conjurer": "robe",
             "Ranger": "leather", "Nightstalker": "leather", "Trickster": "leather", "Bard": "leather",
             "Wanderer": "cloth", "Ironbark": "cloth"}
# the dyed fabric of each family, as hue ranges (0-1): plate's skirt, the robe, the tunic, the gambeson
DYE_HUES = {"plate": [(0.94, 1.0), (0.0, 0.04)], "robe": [(0.70, 0.86)], "leather": [(0.20, 0.45)], "cloth": [(0.52, 0.68)]}
# frames a build reuses (his goblin's second idle frame lost its shirt: both idle frames are the first)
ALIAS = {("goblin", "m", "n_idle1"): "n_idle0", ("fairy", "m", "n_idle1"): "n_idle0",  # his fairy's 2nd idle hides the sword
         # his orc idles were drawn 11 rows taller than his other frames (a lurch at every swing): the neutral
         # atk0 stance stands in for both and the game makes the breath (hero_art _breath, heroes.json "breath")
         ("orc", "m", "n_idle0"): "n_atk0", ("orc", "m", "n_idle1"): "n_atk0"}
# every build's second portrait was a separate drawing (a jump cut at 2 fps): the first stands in and the game
# makes the breath (Fable hero R2 item 4)
ALIAS.update({(r, b, "s_idle1"): "s_idle0" for r in ("goblin", "dwarf", "orc", "fairy") for b in "mf"})


def build_src(race, fam, b, k):
    k = ALIAS.get((race, b, k), k)
    stem = f"{race}_{FAMILY_SRC[fam]}_{b}_{k}" if fam else f"{race}_{b}_{k}"
    v2 = os.path.join(RACES_RAW, stem.replace(f"_{b}_{k}", f"_{b}_{k}") + "_v2.png")
    if not fam and os.path.exists(os.path.join(RACES_RAW, f"{race}_{b}_{k}_v2.png")):
        return os.path.join(RACES_RAW, f"{race}_{b}_{k}_v2.png")
    return os.path.join(RACES_RAW, stem + ".png")


DYE_SHARE = []  # (family, dyed share of the non-skin, non-hair pixels) per build frame, checked after the bake


def dye_index(c, fam, idx, green_skin=False):
    """Marks the family's dyed fabric in the index's blue channel (shade 1..255) for the class colour."""
    import colorsys
    cp, ip = c.load(), idx.load()
    pts = []
    for y in range(C):
        for x in range(C):
            px = cp[x, y]
            if not px[3] or ip[x, y][0] or ip[x, y][1] or (green_skin and greenish(px)):
                continue  # an orc's or goblin's drawn green skin is not cloth (it is indexed as skin after)
            h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
            if sat > 0.15 and v > 0.12:
                pts.append((x, y, R.lum(px[:3]), int(h * 18) % 18))
    # every fabric hue that covers at least 15% of the coloured cloth, not one fixed hue range per family:
    # the fixed ranges dyed 9% of the leather and plate builds (a 2-3 px belt: Fable hero R2 item 5)
    bins = {}
    for q in pts:
        bins[q[3]] = bins.get(q[3], 0) + 1
    pts = [q for q in pts if bins[q[3]] >= 0.15 * len(pts)]
    if not pts:
        return idx
    tot = sum(1 for y in range(C) for x in range(C) if cp[x, y][3] and not ip[x, y][0] and not ip[x, y][1]
              and not (green_skin and greenish(cp[x, y])))
    DYE_SHARE.append((fam, round(len(pts) / max(1, tot), 2)))
    ls = sorted(q[2] for q in pts); lo, hi = ls[len(ls) // 20], ls[-(len(ls) // 20) - 1]
    for x, y, l, _ in pts:
        ip[x, y] = (0, 0, 1 + max(0, min(254, round((l - lo) / max(1, hi - lo) * 254))))
    return idx


def head_hair(c, skip):
    """The hair of a back-view head: brown to blond pixels in the top 30% of the body (wings left out)."""
    import colorsys
    p = c.load()
    body = [(x, y) for y in range(C) for x in range(C) if p[x, y][3] and (x, y) not in skip]
    if not body:
        return set()
    top = min(y for _, y in body); bot = max(y for _, y in body)
    out = set()
    for (x, y) in body:
        if y < top + (bot - top) * 0.3 and R.kind(p[x, y][:3]) != "outline":
            h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in p[x, y][:3]))
            if h <= 0.13 and sat >= 0.3 and v < 0.9:
                out.add((x, y))
    return out


HAIR_EVEN = ["Fairy"]  # its frames were drawn with lighter and darker hair: stretch each to one range


def even_hair(idx, lo_to=40, hi_to=200):
    """Stretches a frame's hair shades (index green) to one fixed range, so hair drawn lighter in one
    frame and darker in another comes out the same colour."""
    ip = idx.load()
    pts = [(x, y) for y in range(C) for x in range(C) if ip[x, y][1]]
    if len(pts) < 10:
        return
    vs = sorted(ip[q][1] for q in pts); lo, hi = vs[len(vs) // 20], vs[-(len(vs) // 20) - 1]
    for q in pts:
        r, g, b = ip[q]
        ip[q] = (r, max(1, min(255, round(lo_to + (g - lo) / max(1, hi - lo) * (hi_to - lo_to)))), b)


def own_skin_index(c, idx, fam):
    """A build that keeps its drawn skin (orc green) still marks it in the index (red channel), so a
    race drawn over the build can recolour it (the werewolf's grey). The family's dyed fabric is not skin."""
    cp, ip = c.load(), idx.load()
    pts = [(x, y) for y in range(C) for x in range(C)
           if cp[x, y][3] and not any(ip[x, y]) and greenish(cp[x, y]) and not dyed(cp[x, y], fam)]
    if not pts:
        return
    ls = sorted(R.lum(cp[q][:3]) for q in pts); lo, hi = ls[len(ls) // 20], ls[-(len(ls) // 20) - 1]
    for q in pts:
        ip[q] = (1 + max(0, min(254, round((R.lum(cp[q][:3]) - lo) / max(1, hi - lo) * 254))), 0, 0)


def dyed(px, fam):
    """The family's dyed fabric (a robe's shoulders reach the head band): never hair."""
    import colorsys
    h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
    return sat > 0.3 and any(lo <= h <= hi for lo, hi in DYE_HUES[fam])


def greenish(px):
    """Yellow-green skin (goblin ears and faces): never hair, even inside the head band."""
    import colorsys
    h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in px[:3]))
    return 0.11 <= h <= 0.40 and sat > 0.25


HAIR_BUILDS = ["Goblin", "Dwarf", "Orc", "Fairy"]  # builds that take the creator's hair style (Fable hero R1 item 6)


HAIR_FIT = {("goblin", "m"): 0.9, ("goblin", "f"): 0.9, ("dwarf", "m"): 0.9, ("dwarf", "f"): 0.9,
            ("orc", "m"): 0.85, ("orc", "f"): 0.9, ("fairy", "m"): 0.7, ("fairy", "f"): 0.8}  # head size vs the human, by eye


def fit_build_hair(d, b, bcells, info, s):
    """Every drawn human hair style moved onto a build's head (0 generations): scaled by s (HAIR_FIT,
    the build's head against the human's, measured by eye: the drawings' necks hide under hair, beards
    and hoods) and pinned per frame by the top of the head and the middle of the skull's top rows."""
    def box(c):  # the skull, not the frame's top pixel (a raised arm in atk1 took the hair with it)
        p = c.load(); top = skull_top(c)
        xs = [x for y in range(top, top + 6) for x in range(C) if p[x, y][3]]
        return (min(xs) + max(xs)) / 2, top
    def boxes(cells):  # a frame's head stays within 4 px of its idle's sideways (the arm beside it pulls)
        out = {k: box(cells[k]) for k in K}
        for k in K:
            r = out["s_idle0" if k.startswith("s") else "n_idle0"]
            out[k] = (max(r[0] - 4, min(r[0] + 4, out[k][0])), out[k][1])
        return out
    hb = boxes(CELL[b]); bb = boxes(bcells)
    for k, (fx, fy) in ((k, v[:2]) for k, v in HEAD_FIX.get(b, {}).items()):
        hb[k] = (hb[k][0] + fx, hb[k][1] + fy)  # the human hair sheets carry the portrait head fix
    for st, k_ in info["styles"].items():
        src = os.path.join(OUT, b, f"hair_{k_}")
        if not os.path.exists(src + ".png"):
            continue
        sh, si = Image.open(src + ".png"), Image.open(src + "_idx.png")
        cells, idxs = [], []
        if k_ == "bald":  # the build's own bare head shows (the human bald head left 1-6 px markers: R4 item 10)
            save(f"{d}/hair_{k_}", [Image.new("RGBA", (C, C)) for _ in K], [Image.new("RGB", (C, C)) for _ in K])
            continue
        for i, k in enumerate(K):
            hcx, htop = hb[k]; bcx, btop = bb[k]
            at = (round(bcx - hcx * s), round(btop - htop * s))
            hc, ic = sh.crop((i * C, 0, i * C + C, C)).convert("RGBA"), si.crop((i * C, 0, i * C + C, C))
            hp, ip = hc.load(), ic.load()
            for y in range(C):  # the hair only: the human scalp and ears under it stay human
                for x in range(C):
                    if not ip[x, y][1]:
                        hp[x, y] = (0, 0, 0, 0)
            for im, out in ((hc, cells), (ic, idxs)):
                big = im.resize((round(C * s), round(C * s)), Image.NEAREST)
                c = Image.new(big.mode, (C, C))
                c.paste(big, at)
                out.append(c)
            if k.startswith("n"):  # seen from behind the hair is the whole head: no scalp through it
                back_hair(cells[-1], idxs[-1], bcells[k], NAPE.get(d, 0))
            squeeze_rows(cells[-1], idxs[-1], btop + 10, HAIR_LOW)
        save(f"{d}/hair_{k_}", cells, idxs)


def squeeze_rows(c, ix, top, low):
    """A layer reaching under row `low`: its rows under `top` squeezed (rows dropped evenly) to end on low,
    the colour cell and its index alike (the Tiny build's very long hair reached her ankles and under)."""
    bb = c.getbbox()
    if not bb or bb[3] - 1 <= low or top >= low:
        return
    bottom = bb[3] - 1
    for im in (c, ix):
        src = im.copy(); sp, p = src.load(), im.load()
        empty = (0, 0, 0, 0) if im.mode == "RGBA" else (0, 0, 0)
        for y in range(top + 1, bottom + 1):
            for x in range(C):
                p[x, y] = empty
        for ty in range(top + 1, low + 1):
            sy = top + round((ty - top) * (bottom - top) / (low - top))
            for x in range(C):
                p[x, ty] = sp[x, sy]


KEEP_DRAWN_HAIR = ["orc_m"]  # hair by its index only: his pauldrons reach the skull, its colours took the plate
HOODED = ["goblin_m"]  # his dyed hood is outfit, not hair
BACK_SILHOUETTE = ["orc_m", "orc_f"]  # their skulls from behind by the head's own outline (back_skull())
DARK_BRAID = ["orc_f"]  # her braid is drawn in the outline black (braid(dark=True))
TOPKNOT = ["orc_m"]  # his drawn topknot over the skull goes (it poked through every style: Fable hero R4 item 7)
BARED = []  # (folder, family, hair pixels taken off its outfit's frames)


SKULL_R = (8, 11.5)  # a build skull's radius, from the smallest (fairy) to the largest (dwarf, orc) by eye


def skull(c, skull_h=None):
    """(cx, cy, r) of a build frame's skull as a circle: its top row, the middle and half-width of the head
    a few rows down (under a topknot, above the ears), round. The braids, ears and shoulders made a head found
    by width run to the hips (Fable hero R4 item 3); skull_h: the orc's skull height, measured by eye."""
    p = c.load(); top = skull_top(c)
    spans = []
    for y in range(top + 2, min(C, top + 6)):
        xs = [x for x in range(C) if p[x, y][3]]
        if xs:
            spans.append((min(xs), max(xs)))
    if not spans:
        return C / 2, top + 8, 8
    cx = sum(a + b for a, b in spans[:2]) / (2 * len(spans[:2]))
    r = max(SKULL_R[0], min(SKULL_R[1], max(b - a for a, b in spans) / 2 + 1))  # a goblin's ears start at the top
    return cx, top + r, r


def back_skull(c, cx):
    """(cx, cy, r) of a head from behind by its own silhouette (the orc_m's: ears out from his skull's top,
    a mane that is all of it): from its top row down to the row the shoulders start (twice its width), the
    rows' middle; the dome is everything inside it but the outline, so no colour decides it."""
    p = c.load()
    def span(y, half=30):
        xs = [x for x in range(max(0, round(cx) - half), min(C, round(cx) + half + 1)) if p[x, y][3]]
        return (min(xs), max(xs)) if xs else None
    top = next(y for y in range(C) if span(y, 14))  # the body's skull sits off it when an arm is up (atk1)
    cx = sum(sum(span(y, 14)) / 2 for y in range(top, top + 3)) / 3
    w = span(top + 2, 14)[1] - span(top + 2, 14)[0] + 1
    wd = lambda y: span(y)[1] - span(y)[0] + 1 if span(y) else 0
    # the shoulders: the first row 5 px wider than the narrowest (the jaw) since the ears, or twice the crown
    sh = next((y for y in range(top + 6, min(C, top + 30))
               if wd(y) > min(wd(t) for t in range(top + 4, y)) + 4 or wd(y) > 2 * w), top + 14)
    r = max(6, (sh - top) / 2 + 1)
    return cx, top + r, r, sh


def no_topknot(c, ix, sk):
    """Everything above the skull's top in its middle columns (a tuft or a topknot), and the outline it leaves."""
    cx, cy, r = sk; top = round(cy - r)
    p, q = c.load(), ix.load()
    for y in range(0, top):
        for x in range(max(0, round(cx - r)), min(C, round(cx + r) + 1)):
            p[x, y] = (0, 0, 0, 0); q[x, y] = (0, 0, 0)


def hair_palette(out, idxs, skulls):
    """The drawn hair's colours on a build's outfit (the index often reads them as skin: the dwarf_f's copper,
    the goblin_f's dark olive): from behind the skull is all hair, so every colour shown 3 px or more inside it
    and at least as often there as on the whole body under the neck (the steel, cloth and arms' skin), not the
    outline, and shown far more there than in the middle of the face on the portrait (her darkest copper is also
    the face's shadow)."""
    head, body, core = {}, {}, {}
    for k in ("n_idle0", "n_idle1"):
        c = out[K.index(k)]; p = c.load(); bb = c.getbbox()
        cx, cy, r = skulls[k]
        for y in range(bb[1], bb[3]):
            for x in range(C):
                if not p[x, y][3] or lum255(p[x, y]) < 28:
                    continue
                col = p[x, y][:3]
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    head[col] = head.get(col, 0) + 1
                elif y > cy + r + 3:
                    body[col] = body.get(col, 0) + 1
    p7 = out[7].load(); cx7, cy7, r7 = skulls["s_idle0"]
    for y in range(round(cy7 - r7), round(cy7 - 0.2 * r7)):  # the portrait's hair above the brows
        for x in range(round(cx7 - r7), round(cx7 + r7) + 1):
            if p7[x, y][3] and lum255(p7[x, y]) >= 28 and (x - cx7) ** 2 + (y - cy7) ** 2 <= r7 * r7:
                head[p7[x, y][:3]] = head.get(p7[x, y][:3], 0) + 1
    for y in range(round(cy7), round(cy7 + 0.6 * r7)):
        for x in range(round(cx7) - 3, round(cx7) + 4):
            if p7[x, y][3]:
                core[p7[x, y][:3]] = core.get(p7[x, y][:3], 0) + 1
    return {col for col, n in head.items() if n >= 3 and n >= body.get(col, 0) and n >= 6 * core.get(col, 0)}


def bare_heads(out, idxs, cells, skulls, d, fam, by_index=False):
    """The drawn hair off a build's outfit frames (Fable hero R4 item 3: a Bald dwarf_f had all her hair and
    braids, a goblin_f her fringe, the orcs a braid, a mane and a topknot). Inside the skull (a circle, skull())
    the head becomes a bald dome, shaded light at the top left to dark at the bottom right in the outfit's own
    skin shades, with an outline; outside it every pixel of the hair's colours (hair_palette) joined to the head,
    down to the hips in the head's columns (braids), goes and takes the non-hair pixels beside it, or nothing.
    From the front the face (brows, a beard) stays as drawn. No hair index is left: what stays is outfit.
    by_index: the hair is what the index marks (his pauldrons reach the skull, so colours would take the plate).
    From behind a braid down the back goes too (braid())."""
    if d in BACK_SILHOUETTE:  # from behind the body's skull circle reached her robe's collar: its purples read as hair
        skulls = {k: back_skull(c, skulls[k][0])[:3] if k.startswith("n") else skulls[k] for c, k in zip(out, K)}
    hp = set() if by_index else hair_palette(out, idxs, skulls)
    # the dome's shades: the skin of the portrait's face (a tusk, a pale trim or an orange vest also read as skin)
    fp, fq = out[7].load(), idxs[7].load(); fx, fy, fr = skulls["s_idle0"]
    pal = sorted({(R.lum(fp[x, y][:3]), fp[x, y], fq[x, y][0])
                  for y in range(round(fy), min(C, round(fy + 0.8 * fr))) for x in range(round(fx - 0.6 * fr), round(fx + 0.6 * fr) + 1)
                  if fq[x, y][0] and fp[x, y][3] and fp[x, y][:3] not in hp and lum255(fp[x, y]) >= 40})
    if not pal:  # an own-skin build (the orcs' green is not recoloured, so not indexed): the bare face's shades
        cnt = {}; fp = cells["s_idle0"].load()
        for y in range(round(fy), min(C, round(fy + 0.8 * fr))):
            for x in range(round(fx - 0.6 * fr), round(fx + 0.6 * fr) + 1):
                if fp[x, y][3] and lum255(fp[x, y]) >= 40 and fp[x, y][:3] not in hp:
                    cnt[fp[x, y]] = cnt.get(fp[x, y], 0) + 1
        if cnt:
            hue = lambda col: colorsys.rgb_to_hsv(*(v / 255 for v in col[:3]))[0]
            mode = max(cnt, key=cnt.get)  # the skin; a tusk or an eye is another hue or rare
            pal = sorted((R.lum(col[:3]), col, 0) for col, m in cnt.items()
                         if m >= 3 and min(abs(hue(col) - hue(mode)), 1 - abs(hue(col) - hue(mode))) <= 0.06)
    near = lambda col: any(sum(abs(col[j] - h[j]) for j in range(3)) <= 18 for h in hp)
    n = 0
    for c, ix, k in zip(out, idxs, K):
        p, q = c.load(), ix.load()
        cx, cy, r = skulls[k]; top = cy - r; bb = cells[k].getbbox()
        front = k.startswith("s")
        inside = lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r
        face = lambda x, y: front and y > top + 0.9 * r and abs(x - cx) <= 0.75 * r  # brows down: the face, a beard
        low = min(bb[1] + int(0.62 * (bb[3] - bb[1])), round(cy + r) + 30)
        xa, xb = max(0, round(cx - r) - 6), min(C - 1, round(cx + r) + 6)
        own = set()
        if front:  # the portrait's own hair shades (lit from the front: the braids are lighter than from behind)
            cnt = {}
            for y in range(max(0, round(cy - r)), round(cy - 0.2 * r)):
                for x in range(max(0, round(cx - r)), min(C, round(cx + r) + 1)):
                    if p[x, y][3] and inside(x, y) and lum255(p[x, y]) >= 28:
                        cnt[p[x, y][:3]] = cnt.get(p[x, y][:3], 0) + 1
            skin = {p[x, y][:3] for y in range(round(cy), round(cy + 0.6 * r)) for x in range(round(cx) - 3, round(cx) + 4) if p[x, y][3]}
            own = {col for col, m in cnt.items() if m >= 2 and col not in skin}
        nearf = lambda col: near(col) or col in own
        # from behind, the dark strands inside the skull (not its rim) are hair too: near-black orc hair
        strand = lambda x, y: not front and lum255(p[x, y]) < 60 and (x - cx) ** 2 + (y - cy) ** 2 <= (r - 1.5) ** 2
        ishair = lambda x, y: (p[x, y][3] and ((q[x, y][1] if by_index else nearf(p[x, y][:3])) or strand(x, y))
                               and not face(x, y) and not (d in HOODED and q[x, y][2]))  # never the dyed hood
        todo = [(x, y) for y in range(0, low + 1) for x in range(xa, xb + 1) if ishair(x, y) and (inside(x, y) or by_index)]
        if d in DARK_BRAID and front:  # her dark cap above the brows (the palette never saw it): the head's own outline
            todo, (cx, cy, r, sh) = [], back_skull(c, cx); top = cy - r
            hair = {(x, y) for y in range(max(1, round(cy - r)), min(C - 1, round(cy - 0.2 * r) + 1, sh))
                    for x in range(max(1, round(cx - r)), min(C - 1, round(cx + r) + 1))
                    if p[x, y][3] and all(p[x + dx, y + dy][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        elif d in BACK_SILHOUETTE and not front:  # an orc's head from behind: all mane or braids, the collar indexed as hair
            todo, (cx, cy, r, sh) = [], back_skull(c, cx); top = cy - r
            hair = {(x, y) for y in range(max(1, round(cy - r)), min(C - 1, round(cy + r), sh))
                    for x in range(max(1, round(cx - r)), min(C - 1, round(cx + r) + 1))
                    if inside(x, y) and all(p[x + dx, y + dy][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        else:
            hair = set(todo)
        while todo:
            x, y = todo.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    t = (x + dx, y + dy)
                    if t not in hair and xa <= t[0] <= xb and 0 <= t[1] <= low and ishair(*t):
                        hair.add(t); todo.append(t)
        dome = set()
        if pal:
            for y in range(max(0, int(top)), min(C, round(cy + r) + 1)):
                for x in range(max(0, round(cx - r)), min(C, round(cx + r) + 1)):
                    if inside(x, y) and p[x, y][3] and (x, y) in hair and not (front and y > cy - 0.2 * r):
                        light = 0.6 - 0.25 * (x - cx) / r - 0.35 * (y - cy) / r
                        _, col, ri = pal[max(0, min(len(pal) - 1, round(light * (len(pal) - 1))))]
                        p[x, y] = col; q[x, y] = (ri, 0, 0); dome.add((x, y))
        gone = hair - dome
        src = c.copy(); sp = src.load(); sq = ix.copy().load()
        for (x, y) in sorted(gone):
            side = [(x + dd * sg, y) for dd in (1, 2, 3) for sg in (-1, 1)]
            nb = [t for t in side if 0 <= t[0] < C and t not in hair and sp[t][3] and not nearf(sp[t][:3])
                  and lum255(sp[t]) >= 40]  # not the braid's own outline (it drew dark pillars down a robe)
            l = [t for t in nb if t[0] < x]; rr = [t for t in nb if t[0] > x]
            if l and rr and not inside(x, y):
                p[x, y] = sp[l[0]]; q[x, y] = (sq[l[0]][0], 0, sq[l[0]][2])
            else:
                p[x, y] = (0, 0, 0, 0); q[x, y] = (0, 0, 0)
        line = min((p[t] for t in pts_of(c)), key=lum255, default=(0, 0, 0, 255))
        rim = {(x, y) for y in range(max(0, round(cy - r) - 1), min(C, round(cy + r) + 2))
               for x in range(max(0, round(cx - r) - 1), min(C, round(cx + r) + 2)) if p[x, y][3]}
        for (x, y) in sorted(rim):  # the dome's and face's edge against the emptied hair: one outline pixel
            if any((x + dx, y + dy) in gone and 0 <= x + dx < C and 0 <= y + dy < C and not p[x + dx, y + dy][3]
                   for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                p[x, y] = line; q[x, y] = (0, 0, 0)
        for _ in range(2):  # the outline the hair left behind (a topknot's ring above the skull)
            for y in range(C):
                for x in range(C):
                    if not p[x, y][3] or lum255(p[x, y]) >= 32 or (x, y) in dome:
                        continue
                    nb8 = [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy) and 0 <= x + dx < C and 0 <= y + dy < C]
                    if (any(t in gone and not p[t][3] for t in nb8)
                            and sum(1 for t in nb8 if p[t][3] and lum255(p[t]) >= 32) <= 1):
                        p[x, y] = (0, 0, 0, 0); q[x, y] = (0, 0, 0)
        if front and d in DARK_BRAID:
            n += side_braid(c, ix, src, sq, cx, cy, r, low)
        if not front and not by_index:
            n += braid(c, ix, src, sq, cx, cy, r, low, lambda col: nearf(col), hair, d not in BACK_SILHOUETTE,
                       d in DARK_BRAID)
        for y in range(C):
            for x in range(C):
                if q[x, y][1]:
                    q[x, y] = (q[x, y][0], 0, q[x, y][2])
        n += len(hair)
    BARED.append((d, fam, n))


def braid(c, ix, src, sq, cx, cy, r, low, ishaircol, taken, wide=False, dark=False):
    """Braids down the back from under the skull, by their own mask: from the rows just under the dome every
    pixel of the hair's colours, its index or the hair already taken, joined to them, down to the hips.
    The orc_f's one braid is drawn in the outline black: in the middle columns (cx +-5) the near-black joins too,
    4-connected. wide (the dwarf_f's two braids over the shoulder blades, outlined, with shades the palette
    lacks): the whole skull's width, joined across 1 px, the row gaps of up to 3 px between its strands and
    1 px round it (its outline) with it. dark (the orc_f's, some frames all outline black and greys): every
    dark grey (under 70, unsaturated) in cx +-4 joins, and a strand 8 rows or longer is her braid. With 4 or more real
    hair pixels it goes, each pixel taking the nearer
    armour beside it within 8 px (nothing at the edge). Returns its size."""
    p, q = c.load(), ix.load(); sp = src.load()
    top = round(cy + r) - 1
    half = round(r) if wide else 5
    band = range(max(0, round(cx) - half), min(C, round(cx) + half + 1))
    real_px = lambda x, y: sp[x, y][3] and (ishaircol(sp[x, y][:3]) or sq[x, y][1] or (x, y) in taken)
    if dark:
        band = range(max(0, round(cx) - 4), min(C, round(cx) + 5))
    grey = lambda col: lum255(col) < 70 and max(col[:3]) - min(col[:3]) <= 12  # her braid's greys, not a dark cloth
    mark = real_px if wide else lambda x, y: real_px(x, y) or (sp[x, y][3] and (lum255(sp[x, y]) < 28 or dark and grey(sp[x, y])))
    steps = [(dx, dy) for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2) if dx or dy] if wide         else [(1, 0), (-1, 0), (0, 1), (0, -1)]
    todo = [(x, y) for y in range(top, top + 3) for x in band if 0 <= y < C and mark(x, y)]
    seen = set(todo)
    while todo:
        x, y = todo.pop()
        for dx, dy in steps:
            t = (x + dx, y + dy)
            if t not in seen and t[0] in band and top <= t[1] <= low and mark(*t):
                seen.add(t); todo.append(t)
    real = sum(1 for t in seen if real_px(*t))
    if dark and len({y for _, y in seen}) >= 8:
        real = max(real, 4)
    if real < 4:
        return 0
    if wide:
        rows = {}
        for x, y in seen:
            rows.setdefault(y, []).append(x)
        for y, xs in rows.items():
            xs.sort()
            for a, b in zip(xs, xs[1:]):
                if b - a <= 4:
                    seen |= {(x, y) for x in range(a + 1, b)}
        seen |= {(x + dx, y + dy) for x, y in list(seen) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                 if x + dx in band and top <= y + dy <= low}
    for (x, y) in sorted(seen):
        if (x, y) in taken and not p[x, y][3] and not (wide and sp[x, y][3]):
            continue  # hair the head took off (the dwarf_f's braids on a leather vest of her hair's browns: refilled)
        ok = lambda t: t not in seen and sp[t][3] and lum255(sp[t]) >= 40  # not a seam or the braid's own line
        l = next((t for t in ((x - dd, y) for dd in range(1, 9)) if t[0] >= 0 and ok(t)), None)
        rr = next((t for t in ((x + dd, y) for dd in range(1, 9)) if t[0] < C and ok(t)), None)
        if (l or rr) if wide else (l and rr):
            # the commonest colour round it: the cloth or plate itself (copying the pixel beside it drew a
            # strap, a stud or a seam across in streaks)
            cnt = {}
            for v in range(max(0, y - 3), min(C, y + 4)):
                for u in range(max(0, x - 6), min(C, x + 7)):
                    if ok((u, v)):
                        cnt[(sp[u, v], sq[u, v][0], sq[u, v][2])] = cnt.get((sp[u, v], sq[u, v][0], sq[u, v][2]), 0) + 1
            col, ri, bi = max(cnt, key=cnt.get) if cnt else (sp[l or rr], sq[l or rr][0], sq[l or rr][2])
            p[x, y] = col; q[x, y] = (ri, 0, bi)
        else:
            p[x, y] = (0, 0, 0, 0); q[x, y] = (0, 0, 0)
    near = {(x + dx, y + dy) for x, y in seen for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2)} - seen
    for _ in range(2):  # the braid's outline left in specks and dashes beside it: the colour round them
        for (x, y) in sorted(near):
            if not (0 < x < C - 1 and 0 < y < C - 1) or not p[x, y][3] or lum255(p[x, y]) >= 40:
                continue
            nb = [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
            lit = [t for t in nb if p[t][3] and lum255(p[t]) >= 40]
            if len(lit) >= 6:
                cnt = {}
                for t in lit:
                    cnt[(p[t], q[t][0], q[t][2])] = cnt.get((p[t], q[t][0], q[t][2]), 0) + 1
                col, ri, bi = max(cnt, key=cnt.get)
                p[x, y] = col; q[x, y] = (ri, 0, bi)
    return len(seen)


def side_braid(c, ix, src, sq, cx, cy, r, low):
    """The orc_f's thin braid from the front, drawn in the outline black from beside her head down over one
    shoulder, by its own mask: the front portrait is symmetric, so her braid is the near-black whose mirror
    image across her middle is lit (a jaw, a vest's edge or a seam has its twin). Joined (4-connected) from
    beside the head down, 8 rows or longer, with its row gaps and 1 px round it, it takes its mirror image.
    Returns its size."""
    p, q = c.load(), ix.load(); sp = src.load()
    rows_ = range(round(cy), min(C, round(cy + 2 * r)))
    def match(m2):  # m2 = twice the axis: how well the silhouette mirrors
        return sum(1 for y in rows_ for x in range(C) if 0 <= m2 - x < C and bool(sp[x, y][3]) == bool(sp[m2 - x, y][3]))
    m2 = max(range(round(2 * cx) - 3, round(2 * cx) + 4), key=match)
    lit = lambda x, y: 0 <= x < C and sp[x, y][3] and lum255(sp[x, y]) >= 40
    dark = lambda x, y: 0 <= x < C and sp[x, y][3] and (lum255(sp[x, y]) < 28 or lum255(sp[x, y]) < 70
                                                         and max(sp[x, y][:3]) - min(sp[x, y][:3]) <= 12)  # her greys
    asym = lambda x, y: dark(x, y) and lit(m2 - x, y)
    y0 = round(cy - 0.6 * r)
    best = (0, set())
    for half in (range(max(0, round(cx - r - 8)), m2 // 2), range(m2 // 2 + 1, min(C, round(cx + r + 9)))):
        # her side of the middle only, through any near-black (her outline crosses the jaw's); a strand that is
        # asymmetric on 8 rows or more is her braid (a buckle or a fold is shorter); one side only, hers (her
        # vest is open on the other side, so its edge there would take her braid back across)
        keep, done = set(), set()
        for seed in [(x, y) for y in range(y0, round(cy + r)) for x in half if asym(x, y)]:
            if seed in done:
                continue
            comp, st = {seed}, [seed]
            while st:
                x, y = st.pop()
                for t in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if t not in comp and t[0] in half and y0 <= t[1] <= low and dark(*t):
                        comp.add(t); st.append(t)
            done |= comp
            if len({y for x, y in comp if asym(x, y)}) >= 8:
                keep |= comp
        score = len({y for x, y in keep if asym(x, y)})
        if score > best[0]:
            best = (score, keep)
    keep = best[1]
    if not keep:
        return 0
    rows = {}
    for x, y in keep:
        rows.setdefault(y, []).append(x)
    for y, xs in rows.items():
        keep |= {(x, y) for x in range(min(xs), max(xs) + 1)}
    mask = keep | {(x + dx, y + dy) for x, y in keep for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                   if 0 <= x + dx < C and 0 <= y + dy < C and sp[x + dx, y + dy][3]}
    for (x, y) in sorted(mask):
        u = m2 - x
        if 0 <= u < C and sp[u, y][3]:
            p[x, y] = sp[u, y]; q[x, y] = (sq[u, y][0], 0, sq[u, y][2])
        else:
            p[x, y] = (0, 0, 0, 0); q[x, y] = (0, 0, 0)
    return len(mask)


NAPE = {"orc_m": 4}  # rows of strands the back hair reaches down the neck (his sat on the skull like a cap)


def back_hair(c, ix, body, nape):
    """A back-view hair cell over a build head: every head pixel between the hair's left and right edge on a
    row (a gap in spiky or tied hair showed the dwarf's pale dome) takes the hair's darkest shade, and nape
    rows of strands (every other column one row shorter) hang below it, over the head and neck only."""
    p, q, bp = c.load(), ix.load(), body.load()
    hair = [(x, y) for y in range(C) for x in range(C) if p[x, y][3]]
    if len(hair) < 12:
        return  # bald, or next to nothing: the drawn head shows
    dark = min(hair, key=lambda t: R.lum(p[t][:3]))
    col, idx = p[dark], q[dark]
    rows = {}
    for x, y in hair:
        lo, hi = rows.get(y, (x, x)); rows[y] = (min(lo, x), max(hi, x))
    def width(y):
        xs = [x for x in range(C) if bp[x, y][3]]
        return max(xs) - min(xs) + 1 if xs else 0
    st = skull_top(body); head_w = max(width(y) for y in range(st, min(C, st + 8)))
    for y, (lo, hi) in rows.items():
        if width(y) > head_w * 1.2:
            continue  # the shoulders and back: pigtails hang over them, not a sheet of hair
        for x in range(lo, hi + 1):
            if not p[x, y][3] and bp[x, y][3]:
                p[x, y] = col; q[x, y] = idx
    if nape:
        bottom = max(rows)
        lo, hi = rows[bottom]
        for x in range(lo + 1, hi):
            for y in range(bottom + 1, bottom + 1 + nape - (x % 2)):
                if y < C and bp[x, y][3] and not p[x, y][3]:
                    p[x, y] = col; q[x, y] = idx


def build_bodies(info, only=None):
    info["builds"] = {}; info["family_of"] = FAMILY_OF
    a0 = SW["m"]["n_idle0"][2]
    for race, key in BUILDS.items():
        for b in "mf":
            if race in SHARED and b != SHARED[race]:
                continue
            if not all(os.path.exists(build_src(key, None, b, k)) for k in K) or (only and f"{key}_{b}" not in only):
                continue
            base = {k: L(build_src(key, None, b, k)) for k in K}
            lift = FLOAT.get(race, {})
            place = {k: ((C - im.width) // 2, FOOT - im.getbbox()[3] - lift.get(k, 4 if lift else 0)) for k, im in base.items()}
            def bcell(im, k):
                c = Image.new("RGBA", (C, C)); c.alpha_composite(im, place[k]); return c
            cells = {k: bcell(base[k], k) for k in K}
            sw = {}
            for k in K:
                blade, ring = sword_pts(cells[k], SW["m"][k][0] if race in STONE else None, SW[b][k][0])
                grip, tip, ang = W.axis(blade, W.body_centre(cells[k]))
                # erased from the outfits: the blade, and the other blade-like group if the hint chose
                # differently (a piece of the same sword showing on the other side)
                alt = set() if race in STONE else set().union(*sword_pts(cells[k]))
                sw[k] = [blade | ring | alt, grip, ang, tip, ((tip[0] - grip[0]) ** 2 + (tip[1] - grip[1]) ** 2) ** 0.5]
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
                    own, ring = sword_pts(c, SW["m"][k][0] if race in STONE else None, SW[b][k][0])
                    if own and len(own & near) * 2 >= len(own):
                        pts |= own | ring
                    for (x, y) in sorted(pts):
                        l = next((p[x - dd, y] for dd in (1, 2, 3) if x - dd >= 0 and (x - dd, y) not in pts and p[x - dd, y][3]), None)
                        r = next((p[x + dd, y] for dd in (1, 2, 3) if x + dd < C and (x + dd, y) not in pts and p[x + dd, y][3]), None)
                        p[x, y] = l if (l and r) else (0, 0, 0, 0)
                    bb = c.getbbox(); top = bb[1] + (bb[3] - bb[1]) * 0.28  # big builds' shoulders reach the head band
                    hair = set() if race in HAIRLESS else {q for q, kd in R.masks(c).items() if kd == "hair" and not greenish(p[q])
                                                           and q[1] < top and not dyed(p[q], fam)}
                    if race in WINGS:
                        wp = wing_pts(c, WINGS[race], 0.0)
                        hair -= wp  # violet wing edges in the head band are not hair
                        if not k.startswith("s"):  # from behind the head is hair: take every brown to blond pixel
                            hair |= head_hair(c, wp)
                    idx = index_of(c, hair)
                    if race in WINGS and k.startswith("s"):  # his front hair is tan and blond, which the masks
                        import colorsys  # read as skin: saturated brown-blond in the top of the head is hair
                        hb = bb[1] + (bb[3] - bb[1]) * 0.26  # down to the bangs, above the eyes (the face's pale skin is less saturated, its shadows redder)
                        hsv = lambda q: colorsys.rgb_to_hsv(*(v / 255 for v in p[q][:3]))
                        more = {(x, y) for y in range(bb[1], int(hb)) for x in range(C)
                                if p[x, y][3] and (x, y) not in wp and (dyed(p[x, y], fam)  # dark red strands, not cloth this high
                                or 0.065 <= hsv((x, y))[0] <= 0.13 and hsv((x, y))[1] >= 0.42 and hsv((x, y))[2] >= 0.5)}
                        if more:
                            idx = index_of(c, hair | more)
                    idx = dye_index(c, fam, idx, race in OWN_SKIN)
                    if race in OWN_SKIN:
                        own_skin_index(c, idx, fam)
                    if race in HAIR_EVEN:
                        even_hair(idx)
                    if race in WINGS:  # small wings an outfit edit kept go (the big wing layer is behind the body)
                        er = wing_pts(c, WINGS[race], 0.55 if fam == "robe" else 0.15)  # not the deep violet robe
                        for q in er:
                            p[q] = (0, 0, 0, 0)
                        drop_stray_lines(c, er)
                    out.append(c); idxs.append(idx)
                if os.environ.get("DUMP_BARE"):  # debug: the frames as bare_heads gets them
                    sheet(out).save(os.path.join(os.environ["DUMP_BARE"], f"{d}_{fam}.png"))
                    sheet(idxs).save(os.path.join(os.environ["DUMP_BARE"], f"{d}_{fam}_idx.png"))
                    sheet([cells[k] for k in K]).save(os.path.join(os.environ["DUMP_BARE"], f"{d}_body.png"))
                if d in TOPKNOT:
                    for c, ix, k in zip(out, idxs, K):
                        no_topknot(c, ix, skull(cells[k], SKULL_H.get((key, b))))
                if race in HAIR_BUILDS:
                    bare_heads(out, idxs, cells, {k: skull(cells[k], SKULL_H.get((key, b))) for k in K}, d, fam,
                               d in KEEP_DRAWN_HAIR)
                if (key, b) in BIG_HEAD:
                    heads = head_regions(cells, SKULL_H.get((key, b)))
                    out = [grow_head(c, heads[k], head_s(key, b, k)) for c, k in zip(out, K)]
                    idxs = [grow_head(c, heads[k], head_s(key, b, k)) for c, k in zip(idxs, K)]
                save(f"{d}/outfit_{fam}", out, idxs)
                fams.append(fam)
            for wt, drawing in WEAPON_DRAWINGS.items():
                # the build's own hands, the standard body's swing (its own detected angles drop the staff)
                save(f"{d}/weapon_{wt}", weapon_cells(wt, drawing, {k: sw[k][1] for k in K}, b, cells))
            info["hand"][d] = [list(mid_hands({k: sw[k][1] for k in K})[k]) for k in K]
            if fams and (key, b, "n_idle1") in ALIAS:  # one idle drawing: the game makes the breath
                info.setdefault("breath", []).append(d)
            if fams:  # a body is only offered once it has an outfit
                info["builds"].setdefault(race, {"key": key, "bodies": {}, "skin": race not in OWN_SKIN})["bodies"][b] = fams
            print(race, b, "build done:", fams)
            if race in WINGS and fams:
                front, back = wing_layer(cells, WINGS[race])
                save(f"{d}/race_{race.lower()}", front)
                save(f"{d}/race_{race.lower()}_back", back)
                info["builds"][race]["feature"] = f"race_{race.lower()}"
                big_f, big_b = wing_layer(cells, WINGS[race], race, 1.25)
                save(f"{d}/race_{race.lower()}__wings_big", big_f)
                save(f"{d}/race_{race.lower()}__wings_big_back", big_b)
                info.setdefault("looks", {}).setdefault("wings_big", []).append(f"{d}/race_{race.lower()}")
            hc = cells
            if (key, b) in BIG_HEAD:
                heads = head_regions(cells, SKULL_H.get((key, b)))
                hc = {k: grow_head(cells[k], heads[k], head_s(key, b, k)) for k in K}
            if race in CROWNED and fams:  # the crown on the build head (its top centre per frame)
                tops = []
                for k in K:  # the skull's top row and middle, x kept within 3 px of the idle's: the highest
                    cp = hc[k].load(); y = skull_top(hc[k])  # pixel of atk1 is the raised axe arm
                    xs = [x for x in range(C) if cp[x, y][3]]
                    x = (min(xs) + max(xs)) // 2
                    if tops and not k.startswith("s"):
                        x = max(tops[0][0] - 3, min(tops[0][0] + 3, x))
                    elif k == "s_idle1":
                        x = max(tops[7][0] - 3, min(tops[7][0] + 3, x))
                    tops.append((x, y))
                save(f"{d}/look_crown", [crown_on((C, C), t) for t in tops])
                info.setdefault("looks", {}).setdefault("crown", []).append(f"{d}/look_crown")
            if race in HAIR_BUILDS and fams:  # the creator's hair style on the build's own head
                fit_build_hair(d, b, hc, info, HAIR_FIT[(key, b)])
                if race in CROWNED:  # each style's top against the crown's bottom (Fable hero R4 item 8)
                    info.setdefault("crown_lift", {})[d] = crown_lifts(d, tops[0][1] + 2, info, True)
                    info.setdefault("crown_lift_s", {})[d] = crown_lifts(d, tops[7][1] + 2, info, True, 7)
                info["builds"][race]["hair"] = True
            if race in SHARED and fams:
                e = info["builds"][race]
                for ob in "mf":
                    e["bodies"][ob] = fams
                e["share"] = SHARED[race]
            for fr, fk in FEATURE_BUILDS.items():
                fp = {k: os.path.join(FEATURES, f"{fr.lower()}_{b}_{ALIAS.get((key, b, k), k)}.png") for k in K}
                if fk != key or not fams or not all(os.path.exists(q) for q in fp.values()):
                    continue
                front, back = build_feature(cells, {k: bcell(L(fp[k]), k) for k in K}, sw)
                front, back = [above_floor(c) for c in front], [above_floor(c) for c in back]
                if (key, b) in BIG_HEAD:  # the wolf head sits on the grown orc head
                    heads = head_regions(cells, SKULL_H.get((key, b)))
                    front = [grow_head(c, heads[k], head_s(key, b, k), 10) for c, k in zip(front, K)]
                save(f"{d}/race_{fr.lower()}", front)
                save(f"{d}/race_{fr.lower()}_back", back)
                e = info["builds"].setdefault(fr, {"key": key, "bodies": {}, "skin": fr not in OWN_SKIN, "feature": f"race_{fr.lower()}"})
                if fr in SKIN_RAMP:
                    e["skin_ramp"] = SKIN_RAMP[fr]
                e["bodies"][b] = fams
                print(fr, b, "feature done")


def wing_pts(c, hues, vmin=0.3):
    """Pixels of a cell in the wing hue (lilac to violet)."""
    import colorsys
    p = c.load(); pts = set()
    for y in range(C):
        for x in range(C):
            if p[x, y][3]:
                h, sat, v = colorsys.rgb_to_hsv(*(q / 255 for q in p[x, y][:3]))
                if hues[0] <= h <= hues[1] and sat > 0.12 and v > vmin:
                    pts.add((x, y))
    return set().union(*[g for g in comps(pts) if len(g) >= 6]) if pts else set()


WING_SRC = {"Fairy": ("fairy", "f")}  # big butterfly wings drawn once on her first idle and portrait frames
# Juzo picked the 2.0 fairy's slim petal wings (fairy_wing_refs/old_race_wings_fairy.png, style only),
# drawn in code; the PixelLab luna / monarch / yellow drawings stay as options
WING_STYLE = os.environ.get("WING_STYLE", "petal")


def wing_drawing(path, src_cell, hues, place):
    """One wing drawing (a PixelLab edit of a base frame with big butterfly wings) cut to the wings:
    every pixel of the edit outside the fairy's body (the base frame minus its own small wings), so
    any palette works. Returns the drawing and the centre of the base frame's small wings (its anchor)."""
    ed = Image.new("RGBA", (C, C))
    ed.alpha_composite(L(path), place)  # the same canvas as its base frame, placed the same way
    ep, bp = ed.load(), src_cell.load()
    small = wing_pts(src_cell, hues)
    body = {(x, y) for y in range(C) for x in range(C) if bp[x, y][3] and (x, y) not in small}
    near = {(x + dx, y + dy) for (x, y) in body for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
    pts = {(x, y) for y in range(C) for x in range(C) if ep[x, y][3] and (x, y) not in near}
    pts = set().union(*[g for g in comps(pts) if len(g) >= 12]) if pts else set()
    w = Image.new("RGBA", (C, C)); wp = w.load()
    for q in pts:
        wp[q] = ep[q]
    cx = sum(q[0] for q in small) / max(1, len(small)); cy = sum(q[1] for q in small) / max(1, len(small))
    return w, (cx, cy)


def drop_stray_lines(c, erased, passes=4):
    """The dark outline left floating where the small wings were erased: a dark pixel next to an
    erased one that is only a thin line (at most 2 opaque neighbours; the body's own edge has more)."""
    p = c.load()
    near = set(erased)
    for _ in range(passes):
        gone = []
        for (ex, ey) in near:
            for x, y in ((ex + i, ey + j) for i in (-1, 0, 1) for j in (-1, 0, 1)):
                if 0 < x < C - 1 and 0 < y < C - 1 and p[x, y][3] and sum(p[x, y][:3]) < 240:
                    if sum(1 for i in (-1, 0, 1) for j in (-1, 0, 1) if (i or j) and p[x + i, y + j][3]) <= 2:
                        gone.append((x, y))
        if not gone:
            break
        for q in gone:
            p[q] = (0, 0, 0, 0)
        near = set(gone)


PETAL = {"line": (96, 52, 112), "deep": (206, 132, 200), "fill": (232, 166, 222), "lite": (245, 204, 240),
         "rim": (252, 236, 252)}


def petal_drawing(src_cell, hues):
    """The 2.0 fairy's wings (Juzo's pick, style only), drawn here: two slim pointed petals a side,
    a long one swept up and out and a short one down and out, pink-lilac lit toward the upper rim,
    a faint light vein from the root, one clean dark outline (no dotted edge)."""
    import math
    small = wing_pts(src_cell, hues)
    ax = sum(q[0] for q in small) / max(1, len(small)); ay = sum(q[1] for q in small) / max(1, len(small))
    bb = src_cell.getbbox(); H = bb[3] - bb[1]
    # (angle from straight out, length, widest half-width) as fractions of the body height
    petals = [(42, 0.5, 0.11), (-48, 0.74, 0.15)]  # the lower one first: the upper overlaps it
    w = Image.new("RGBA", (C, C)); wp = w.load()
    for ang, ln, wd in petals:
        for side in (-1, 1):
            a = math.radians(ang)
            ux, uy = side * math.cos(a), math.sin(a)
            L_, W_ = ln * H, wd * H
            ox, oy = ax + side * 2, ay
            inside = {}
            for y in range(C):
                for x in range(C):
                    dx, dy = x + 0.5 - ox, y + 0.5 - oy
                    t = (dx * ux + dy * uy) / L_
                    if not 0 <= t <= 1:
                        continue
                    d = dy * abs(ux) - dx * uy * side  # across the petal: negative = the side facing up
                    half = W_ * math.sin(math.pi * t ** 1.4)  # thin at the root, widest two thirds out, pointed
                    if abs(d) <= half:
                        inside[(x, y)] = (t, d / max(half, 0.5))
            for (x, y), (t, u) in inside.items():
                if any((x + i, y + j) not in inside for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    c = PETAL["line"]
                elif u < -0.55:
                    c = PETAL["rim"]  # the lit upper rim
                elif abs(u) < 0.14 and t < 0.6:
                    c = PETAL["lite"]  # the faint vein glowing from the root
                elif u > 0.35:
                    c = PETAL["deep"]
                else:
                    c = PETAL["fill"]
                wp[x, y] = c + (255,)
    return w, (ax, ay)


def wing_layer(cells, hues, race="Fairy", scale=1.0):
    """Big butterfly wings on every frame: over the body's back in the battle frames (they grow from it, as
    the angel's do) and behind the body on the portrait (Fable hero R2 item 6): the one drawing per view, centred where the frame's own small wings were, so every frame
    has the same wings. The second idle frame draws them narrower: a gentle flap."""
    key, sb = WING_SRC[race]
    feat = os.path.join(FEATURES, f"{key}_wings_{WING_STYLE}_%s.png")
    src = {d: bcell_of(key, sb, k) for d, k in (("n", "n_idle0"), ("s", "s_idle0"))}
    if WING_STYLE == "petal":
        draw = {d: petal_drawing(src[d][0], hues) for d in "ns"}
    else:
        draw = {d: wing_drawing(feat % d, src[d][0], hues, src[d][1]) for d in "ns"}
    if scale != 1.0:  # an awakening's bigger wings, grown from their root
        draw = {d: (scaled_part(w, pts_of(w), scale, a, a), a) for d, (w, a) in draw.items()}
    front, back = [], []
    for k in K:
        w, (sx, sy) = draw[d_of(k)]
        small = wing_pts(cells[k], hues)
        if small:
            cx = sum(q[0] for q in small) / len(small); cy = sum(q[1] for q in small) / len(small)
        else:
            cx, cy = sx, sy
        if k.endswith("idle1"):  # flap: half closed, 60% as wide around the body's centre line
            bb = w.getbbox(); part = w.crop(bb)
            nw = max(2, round(part.width * 0.6))
            w2 = Image.new("RGBA", (C, C))
            w2.alpha_composite(part.resize((nw, part.height), Image.NEAREST), (round(sx - (sx - bb[0]) * 0.6), bb[1]))
            w = w2
        layer = Image.new("RGBA", (C, C))
        layer.alpha_composite(w, (0, 0))
        layer = ImageChops.offset(layer, round(cx - sx), round(cy - sy))
        empty = Image.new("RGBA", (C, C))
        (back if k.startswith("s") else front).append(layer)
        (front if k.startswith("s") else back).append(empty)
    return front, back


def bcell_of(key, b, k):
    """A build's base frame placed in its cell as build_bodies places it, and where it went."""
    race = next(r for r, kk in BUILDS.items() if kk == key)
    lift = FLOAT.get(race, {})
    im = L(build_src(key, None, b, k))
    at = ((C - im.width) // 2, FOOT - im.getbbox()[3] - lift.get(k, 4 if lift else 0))
    c = Image.new("RGBA", (C, C)); c.alpha_composite(im, at)
    return c, at


def above_floor(c, last=FOOT - 2):
    """A feature never goes through the floor: any piece reaching below `last` (the werewolf tail tip under
    the feet) is lifted to end on it."""
    pts = pts_of(c)
    if not pts:
        return c
    p = c.load(); out = c.copy(); op = out.load()
    for g in comps(pts):
        low = max(q[1] for q in g)
        if low > last:
            for q in g:
                op[q] = (0, 0, 0, 0)
            for (x, y) in g:
                op[x, y - (low - last)] = p[x, y]
    return out


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


# ---------- awakening looks and the Fallen Angel, made from the drawn layers (no new drawings) ----------
# A look that changes a race's own feature is a full variant of the race layer ("race_angel__wings2"),
# worn instead of it; the crown is drawn over any head (look_crown). "glow" is drawn by HeroArt.
FALLEN = [(18, 14, 24), (30, 24, 40), (44, 36, 56), (62, 52, 76), (84, 72, 100)]  # black wings, dark to light
DRAGON = [(14, 38, 40), (29, 84, 82), (45, 127, 122), (190, 82, 24), (247, 118, 34), (252, 168, 92)]  # teal bone, #f77622 membrane
CROWN = [".K...K...K.",
         "KYK.KYK.KYK",
         "KGYKGYGKYGK",
         "KGGGGRGGGGK",
         "KDGGGGGGGDK",
         "KDDDDDDDDDK",
         ".KKKKKKKKK."]
CROWN_COL = {"K": (58, 36, 24), "Y": (254, 231, 97), "G": (254, 174, 52), "D": (190, 74, 47), "R": (228, 59, 68)}


def sheet_cells(name):
    p = os.path.join(OUT, name + ".png")
    if not os.path.exists(p):
        return None
    im = L(p); n = im.height
    return [im.crop((i * n, 0, i * n + n, n)) for i in range(im.width // n)]


def pts_of(c):
    p = c.load()
    return {(x, y) for y in range(c.height) for x in range(c.width) if p[x, y][3]}


def halo_of(c):
    """The halo: the flat ring floating over the head."""
    out = set()
    pts = pts_of(c)
    for g in comps(pts) if pts else []:
        xs = [q[0] for q in g]; ys = [q[1] for q in g]
        if max(ys) - min(ys) <= 6 and max(xs) - min(xs) >= 6 and min(ys) < 40:
            out |= g
    return out


def recolour(c, pts, ramp):
    """pts mapped by brightness onto a dark-to-light ramp."""
    p = c.load()
    if not pts:
        return
    ls = sorted(R.lum(p[q][:3]) for q in pts); lo, hi = ls[len(ls) // 20], ls[-(len(ls) // 20) - 1]
    for q in pts:
        t = (R.lum(p[q][:3]) - lo) / max(1, hi - lo)
        r = ramp[max(0, min(len(ramp) - 1, int(t * len(ramp))))]
        p[q] = r + (p[q][3],)


def cracked(c, halo):
    """The halo broken in two (a 2-px gap, the right piece dropped a pixel) and its gold dulled."""
    p = c.load()
    if not halo:
        return
    xs = [q[0] for q in halo]; cut = (min(xs) + max(xs)) // 2 + (max(xs) - min(xs)) // 6
    old = {q: p[q] for q in halo}
    for q in halo:
        p[q] = (0, 0, 0, 0)
    for (x, y), px in old.items():
        if cut <= x <= cut + 1:
            continue
        g = (px[0] * 0.55 + 60, px[1] * 0.5 + 50, px[2] * 0.6 + 50)  # dull, greyed gold
        q = (x, y + 1) if x > cut + 1 else (x, y)
        if 0 <= q[1] < c.height:
            p[q] = tuple(int(v) for v in g) + (px[3],)


def scaled_part(c, pts, s, anchor, to):
    """The pixels pts of c scaled by s (clean pixel-art scaling) with `anchor` moved to `to`."""
    out = Image.new("RGBA", c.size)
    if not pts:
        return out
    xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
    box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
    part = Image.new("RGBA", (box[2] - box[0], box[3] - box[1])); pp, cp = part.load(), c.load()
    for (x, y) in pts:
        pp[x - box[0], y - box[1]] = cp[x, y]
    big = W.scale2x(W.scale2x(part))
    small = big.resize((max(1, round(part.width * s)), max(1, round(part.height * s))), Image.NEAREST)
    ax, ay = (anchor[0] - box[0]) * s, (anchor[1] - box[1]) * s
    layer = Image.new("RGBA", (c.width * 2, c.height * 2))
    layer.alpha_composite(small, (round(to[0] - ax) + c.width // 2, round(to[1] - ay) + c.height // 2))
    return layer.crop((c.width // 2, c.height // 2, c.width // 2 + c.width, c.height // 2 + c.height))


def extra_wings(c, s, drop):
    """A smaller pair of the wings in c (not the halo), hung `drop` px lower, a touch paler."""
    wings = pts_of(c) - halo_of(c)
    if not wings:
        return Image.new("RGBA", c.size)
    xs = [q[0] for q in wings]; ys = [q[1] for q in wings]
    root = ((min(xs) + max(xs)) / 2, min(ys))
    w = scaled_part(c, wings, s, root, (root[0], root[1] + drop))
    p = w.load()
    for y in range(w.height):
        for x in range(w.width):
            if p[x, y][3]:
                r, g, bb, a = p[x, y]
                p[x, y] = (min(255, r + 14), min(255, g + 14), min(255, bb + 18), a)
    return w


def under(top, bottom):
    """bottom drawn first, top over it."""
    out = Image.new("RGBA", top.size); out.alpha_composite(bottom); out.alpha_composite(top)
    return out


def head_tops(b):
    """Where a crown sits on each frame: the top centre of the short-hair head."""
    out = []
    for c in sheet_cells(f"{b}/hair_short"):
        bb = c.getbbox()
        p = c.load()
        top = [x for x in range(c.width) if any(p[x, y][3] for y in range(bb[1], bb[1] + 3))]
        out.append(((min(top) + max(top)) // 2 if top else (bb[0] + bb[2]) // 2, bb[1]))
    return out


def crown_on(size, at):
    """The crown drawn with its band's bottom centre at `at` (it sits 3 rows into the hair)."""
    c = Image.new("RGBA", size); p = c.load()
    h, w = len(CROWN), len(CROWN[0])
    x0, y0 = at[0] - w // 2, at[1] + 3 - h
    for j, row in enumerate(CROWN):
        for i, ch in enumerate(row):
            if ch != "." and 0 <= x0 + i < size[0] and 0 <= y0 + j < size[1]:
                p[x0 + i, y0 + j] = CROWN_COL[ch] + (255,)
    return c


def derived_looks(b, info):
    looks = info.setdefault("looks", {})
    ang, angb = sheet_cells(f"{b}/race_angel"), sheet_cells(f"{b}/race_angel_back")
    if ang and angb:
        # the Fallen Angel: black wings, a cracked dull halo
        fr, fb = [c.copy() for c in ang], [c.copy() for c in angb]
        for c in fr + fb:
            h = halo_of(c)
            recolour(c, pts_of(c) - h, FALLEN)
            cracked(c, h)
        save(f"{b}/race_fallen_angel", fr, [index_of(c) for c in fr])
        save(f"{b}/race_fallen_angel_back", fb, [index_of(c) for c in fb])
        info.setdefault("races", {}).setdefault("Fallen Angel", []).append(b)
        # Archangel: a second pair under the first; Seraph: a third
        for look, pairs in (("wings2", [(0.72, 9)]), ("wings3", [(0.72, 9), (0.5, 17)])):
            vf, vb = [], []
            for c, cb in zip(ang, angb):
                f2, b2 = c, cb
                for s, drop in pairs:
                    f2 = under(f2, extra_wings(c, s, drop))
                    b2 = under(b2, extra_wings(cb, s, drop))
                vf.append(f2); vb.append(b2)
            save(f"{b}/race_angel__{look}", vf, [index_of(c) for c in vf])
            save(f"{b}/race_angel__{look}_back", vb, [index_of(c) for c in vb])
            looks.setdefault(look, []).append(f"{b}/race_angel")
    drg, drgb = sheet_cells(f"{b}/race_dragonkin"), sheet_cells(f"{b}/race_dragonkin_back")
    vam, vamb = sheet_cells(f"{b}/race_vampire"), sheet_cells(f"{b}/race_vampire_back")
    if drg and vam and vamb:
        # Wyrmkin and up: the vampire's bat wings (membrane and finger ribs: a dragon's in miniature) 1.7x,
        # teal bones and an orange membrane, ONE drawing on every battle frame at the shoulders (the angel's
        # feathers were a phoenix and changed size every frame: Fable hero R4 item 4), under the horns and tail
        wing = dragon_wing(vam[0])
        outs = sheet_cells(f"{b}/outfit_warrior")
        s0 = shoulder(outs[0])
        wb = wing.getbbox()
        vf, vb = [], []
        for i in range(len(K)):
            sx, sy = shoulder(outs[i])
            w = Image.new("RGBA", (C, C)); w.paste(wing, (sx - s0[0], sy - s0[1]), wing)
            if i < 7:
                vf.append(under(drg[i], w))
                vb.append(drgb[i] if drgb else Image.new("RGBA", (C, C)))
            else:  # the same pair seen from the front, behind the body (the bat's portrait stubs read as a plank)
                vf.append(drg[i])
                vb.append(under(drgb[i], w) if drgb else w)
        save(f"{b}/race_dragonkin__dragon_wings", vf, [index_of(c) for c in vf])
        save(f"{b}/race_dragonkin__dragon_wings_back", vb, [index_of(c) for c in vb])
        looks.setdefault("dragon_wings", []).append(f"{b}/race_dragonkin")
        print(b, "dragon wings", wb, [c.getbbox() for c in vf[:7]])
    dem = sheet_cells(f"{b}/race_demon")
    if dem:
        # Demon Noble: great horns (each horn 1.4x from its base)
        big = []
        for c in dem:
            out = c.copy(); op = out.load()
            horns = [g for g in comps(pts_of(c)) if min(q[1] for q in g) < 45 and len(g) >= 6]
            for g in horns:
                for q in g:
                    op[q] = (0, 0, 0, 0)
            for g in horns:
                base = (sum(q[0] for q in g) / len(g), max(q[1] for q in g))
                out.alpha_composite(scaled_part(c, g, 1.4, base, base))
            big.append(out)
        save(f"{b}/race_demon__horns_big", big, [index_of(c) for c in big])
        looks.setdefault("horns_big", []).append(f"{b}/race_demon")
    crown = [crown_on((C, C), t) for t in head_tops(b)]
    save(f"{b}/look_crown", crown)
    looks.setdefault("crown", []).append(f"{b}/look_crown")
    ref = head_tops(b)[0][1]  # the crown sits on short hair: other styles raise or lower it by their own top
    info.setdefault("crown_lift", {})[b] = crown_lifts(b, ref, info)
    info.setdefault("crown_lift_s", {})[b] = crown_lifts(b, head_tops(b)[7][1], info, f=7)


def shoulder(c):
    """The outfit's top row and middle column (the wings are pinned there, like a weapon to the hand)."""
    p = c.load(); bb = c.getbbox(); y = bb[1] + 2
    xs = [x for x in range(C) if p[x, y][3]]
    return (min(xs) + max(xs)) // 2, bb[1]


WING_SPAN = 78  # px the pair may span: 1.7x his bat wings reached both cell edges


def dragon_wing(c, s=1.7):
    """The wing parts of a vampire layer cell (parts of 20 px or more: the eyes and crumbs stay out), each
    scaled s from its root (its corner nearest the body's middle, at its bottom), re-outlined, recoloured:
    the darkest third teal (ribs and outline, DRAGON[0..2]), the rest orange (membrane, DRAGON[3..5])."""
    out = Image.new("RGBA", (C, C))
    parts = [g for g in comps(pts_of(c)) if len(g) >= 20]
    if not parts:
        return out
    mid = sum(q[0] for g in parts for q in g) / sum(len(g) for g in parts)
    xs = [q[0] for g in parts for q in g]
    gap = sum(1 for x in range(min(xs), max(xs) + 1) if x not in set(xs))
    s = min(s, (WING_SPAN - gap) / max(1, len(set(xs))))
    for g in parts:
        gx = sum(q[0] for q in g) / len(g)
        root = (max(q[0] for q in g) if gx < mid else min(q[0] for q in g), max(q[1] for q in g))
        out.alpha_composite(scaled_part(c, g, s, root, root))
    p = out.load(); pts = pts_of(out)
    ls = sorted(lum255(p[q]) for q in pts)
    cut = ls[len(ls) // 3] if ls else 0
    for (x, y) in pts:
        t = lum255(p[x, y])
        if t <= cut:
            p[x, y] = DRAGON[min(2, int(3 * t / max(1, cut + 1)))] + (255,)
        else:
            p[x, y] = DRAGON[3 + min(2, int(3 * (t - cut) / max(1, 256 - cut)))] + (255,)
    for (x, y) in pts:  # one dark pixel round every edge (nearest-neighbour scaling left steps open)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            t = (x + dx, y + dy)
            if 0 <= t[0] < C and 0 <= t[1] < C and not p[t][3]:
                p[t] = DRAGON[0] + (255,)
    return out


LIFT = (-3, 8)  # the crown moves at most this far from where it sits (rows down, rows up)


def crown_lifts(d, ref, info, skull=False, f=0):
    """Rows to raise the crown per hair style of folder d (frame f's hair top against `ref`); 0s left out.
    f=7: the portrait's own (crown_lift_s: f long hair is 6 rows taller than short in battle, as tall on the
    portrait, where the one lift floated the crown 5 rows over it).
    skull: ref is the build's skull top and a style lower than it (bald, buzz) leaves the crown on the skull
    (they lowered it onto the beard: Fable hero R3 item 5)."""
    out = {}
    for k_ in info["styles"].values():
        path = os.path.join(OUT, d, f"hair_{k_}.png")
        if os.path.exists(path):
            hc = Image.open(path).convert("RGBA").crop((f * C, 0, f * C + C, C))
            bb = hc.getbbox()
            if not bb or (skull and len(pts_of(hc)) < 12):
                continue
            # skull: ref is the crown's bottom row, which sits 2 rows into the style (a gap under it on the f
            # builds' tall styles, R4 item 8); else ref is short hair's top and the style moves it by its own
            lift = max(LIFT[0], min(LIFT[1], (ref - bb[1] - 2) if skull else (ref - bb[1])))
            if lift:
                out[k_] = lift
    return out


def class_dye(cells, idxs):
    """A class's dye for the other builds, from its drawn human outfit: the main colourful cloth (the
    commonest saturated hue, not skin or hair) as the middle shade, with shadows shifted 15 degrees and
    more saturated and highlights warmer and softer, dark to light (hex)."""
    import colorsys
    bins, by = {}, {}
    for c, ix in zip(cells[:2], idxs[:2]):  # the idle frames
        p, q = c.load(), ix.load()
        for y in range(C):
            for x in range(C):
                if not p[x, y][3] or q[x, y][0] or q[x, y][1]:
                    continue
                h, sat, v = colorsys.rgb_to_hsv(*(t / 255 for t in p[x, y][:3]))
                if sat < 0.1 or v < 0.12:  # 0.1 keeps cream and pale robes (the Cleric came out trim-red)
                    continue
                k = int(h * 18) % 18
                bins[k] = bins.get(k, 0) + 1
                by.setdefault(k, []).append((v, h, sat))
    if not bins:
        return None
    px = sorted(by[max(bins, key=bins.get)])
    v, h, sat = px[len(px) // 2]
    out = []
    hsv = [((h + dh / 360) % 1, min(1, sat * ds), min(0.9, v * dv))
           for dv, dh, ds in ((0.45, -15, 1.15), (0.7, -8, 1.08), (1.0, 0, 1.0), (1.3, 5, 0.9), (1.6, 9, 0.8))]
    return [("#%02x%02x%02x" % tuple(round(t * 255) for t in colorsys.hsv_to_rgb(*q))) for q in even_ramp(hsv)]


DYE_FLOOR, DYE_TOP, DYE_STEP = 0.11, 0.25, 0.06  # the darkest step no darker than #241a28; the lightest at least 0.25


def even_ramp(hsv):
    """Five HSV steps with distinct shades: the darkest floored at DYE_FLOOR luminance, the lightest at least
    DYE_TOP, and when two neighbours differ by less than DYE_STEP all five are respaced evenly between the ends
    (the cream cleric's top three steps were one colour; the nightstalker's whole ramp was under the floor)."""
    import colorsys
    def lum(q):
        return R.lum([round(t * 255) for t in colorsys.hsv_to_rgb(*q)]) / 255
    def at(q, target):  # the same hue and saturation at a target luminance (value search)
        lo, hi = 0.0, 1.0
        for _ in range(20):
            mid = (lo + hi) / 2
            if lum((q[0], q[1], mid)) < target:
                lo = mid
            else:
                hi = mid
        return (q[0], q[1], (lo + hi) / 2)
    ls = [lum(q) for q in hsv]
    a, z = max(ls[0], DYE_FLOOR), max(ls[-1], DYE_TOP)
    if z - a < 4 * DYE_STEP:
        z = a + 4 * DYE_STEP
    if ls[0] >= DYE_FLOOR and ls[-1] >= DYE_TOP and all(ls[i + 1] - ls[i] >= DYE_STEP for i in range(4)):
        return hsv
    return [at(q, a + (z - a) * i / 4) for i, q in enumerate(hsv)]


BIG_HEAD = {("orc", "m"): 1.4}  # his orc head was a pea on a boulder (25% of the height; the chibi rule is ~40%)
PORTRAIT_HEAD = {("orc", "m"): 1.15}  # and on the portrait still half his pauldrons (Fable hero R4 item 7)


def head_s(key, b, k):
    return BIG_HEAD[(key, b)] * (PORTRAIT_HEAD.get((key, b), 1.0) if k.startswith("s") else 1.0)


SKULL_H = {("orc", "m"): 12}  # the skull's height under its top (back and front), measured by eye: his neck
# hides in the shoulders, so finding it per frame grew a different head on every frame (Fable hero R2 item 3)


def skull_top(c):
    """The first row of the skull: at least 10 px wide (a mohawk or topknot above it is narrower)."""
    p = c.load(); bb = c.getbbox()
    for y in range(bb[1], bb[3]):
        xs = [x for x in range(C) if p[x, y][3]]
        if xs and max(xs) - min(xs) + 1 >= 10:
            return y
    return bb[1]


def head_regions(cells, skull_h=None):
    """Per frame: (x0, x1, neck) of the head on the bare build body. With skull_h: the same head on every
    frame, skull_h rows under each frame's skull top, its columns from those rows. Without: the top part
    down to the first row much wider than the head itself (the shoulders)."""
    out = {}
    if skull_h:
        for k in K:
            c = cells[k]; p = c.load(); bb = c.getbbox(); neck = skull_top(c) + skull_h
            xs = [x for y in range(bb[1], neck + 1) for x in range(C) if p[x, y][3]]
            out[k] = (min(xs), max(xs), neck)
        return out
    for k in K:
        c = cells[k]; p = c.load(); bb = c.getbbox()
        widest, neck, x0, x1 = 0, bb[3], C, 0
        for y in range(bb[1], bb[3]):
            xs = [x for x in range(C) if p[x, y][3]]
            if not xs:
                continue
            w = max(xs) - min(xs) + 1
            if widest and w > widest * 1.6 and y - bb[1] > 6:
                neck = y - 1
                break
            widest = max(widest, w); x0 = min(x0, min(xs)); x1 = max(x1, max(xs))
        out[k] = (x0, x1, neck, bb)
    # where the shoulders were missed (wide ears, a raised arm) the "head" ran down the whole body and the
    # whole body grew: those frames take the head height the good frames found, and the head's columns
    # from its rows only
    good = [r[2] - r[3][1] for r in out.values() if r[2] - r[3][1] <= 0.45 * (r[3][3] - r[3][1])]
    head_h = sorted(good)[len(good) // 2] if good else 0
    for k, (x0, x1, neck, bb) in out.items():
        if head_h and neck - bb[1] > 0.45 * (bb[3] - bb[1]):
            p = cells[k].load(); neck = bb[1] + head_h
            xs = [x for y in range(bb[1], neck + 1) for x in range(C) if p[x, y][3]]
            x0, x1 = min(xs), max(xs)
        out[k] = (x0, x1, neck)
    return out


def grow_head(c, reg, s, margin=4):
    """The pixels above the neck within the head's columns (plus a margin for ears and tusks), scaled by s
    from the middle of the neck, so the head grows up and out and the shoulders stay put."""
    x0, x1, neck = reg
    x0, x1 = max(0, x0 - margin), min(C - 1, x1 + margin)
    p = c.load()
    part = Image.new(c.mode, (x1 - x0 + 1, neck + 1)); pp = part.load()
    for y in range(neck + 1):
        for x in range(x0, x1 + 1):
            pp[x - x0, y] = p[x, y]
    big = part.resize((round(part.width * s), round(part.height * s)), Image.NEAREST)
    out = c.copy(); op = out.load()
    empty = (0, 0, 0, 0) if c.mode == "RGBA" else (0, 0, 0)
    for y in range(neck + 1):
        for x in range(x0, x1 + 1):
            op[x, y] = empty
    ox = round((x0 + x1) / 2 - big.width / 2); oy = neck + 1 - big.height
    bp = big.load()
    for y in range(big.height):
        for x in range(big.width):
            px = bp[x, y]
            if (px[3] if c.mode == "RGBA" else any(px)) and 0 <= ox + x < C and 0 <= oy + y < C:
                op[ox + x, oy + y] = px
    return out

if __name__ == "__main__":
    main()
