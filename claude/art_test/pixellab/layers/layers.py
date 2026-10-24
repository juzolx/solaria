"""Paper-doll gear layers for the PixelLab hero.

Every outfit is a PixelLab edit of the SAME base pose, so pixels line up between outfits. This cuts each
outfit image into per-slot pieces by body region (measured on the base body of that view), and stacks any
pieces from any outfits in a fixed draw order. 8 slots: helmet, chest, gloves, legs, feet, back, weapon, offhand.

Regions (rows measured on the base figure, top..bottom = H):
  head   : above the head line (hair / face / helmet live here, not outfit pieces)
  chest  : head line .. belt (63% of H), all columns; plus the arms/hands below the belt (outside the torso)
  gloves : forearms + hands = arm columns from belt-6 .. belt+9
  legs   : belt .. boot tops (90% of H), torso columns
  feet   : boot tops .. bottom
  back   : the cape (green cloth of the ranger), wherever it is
  weapon : the sword, cut with the BASE sword mask (same pose for every outfit)
A long garment (robe) keeps its skirt in the chest piece and has no legs piece.
"""
import os, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__)); PL = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(PL, "custom")); sys.path.insert(0, os.path.join(PL, "hair"))
import recolour as R
import headswap as HS
import colorsys

SLOTS = ["helmet", "chest", "gloves", "legs", "feet", "back", "weapon", "offhand"]
# draw order per view: from behind (north) the cape covers the back; from the front it hangs behind the body
ORDER = {"north": ["legs", "feet", "chest", "gloves", "back", "head", "helmet", "weapon", "offhand"],
         "south": ["back", "legs", "feet", "chest", "gloves", "head", "helmet", "weapon", "offhand"]}
LONG = {"robe"}  # skirts that cover the legs band


def L(p):
    return Image.open(p).convert("RGBA")


class Body:
    """Landmarks of one base body in one view."""

    def __init__(self, base):
        self.base = base
        bb = base.getbbox()
        self.top, self.bot = bb[1], bb[3]
        H = self.bot - self.top
        self.head = HS.head_bottom(base)
        self.belt = int(self.top + 0.635 * H)
        self.boot = int(self.top + 0.90 * H)
        bp = base.load()
        self.sword = self._sword()
        row = [x for x in range(base.width) if bp[x, self.belt + 2][3] and (x, self.belt + 2) not in self.sword]
        # torso = the widest run of the belt row minus the outer arm strips
        xs = self._runs(row)
        best = max(xs, key=lambda r: r[1] - r[0])
        self.tx0, self.tx1 = best[0] + 3, best[1] - 3

    @staticmethod
    def _runs(cols):
        runs, s = [], None
        for i, x in enumerate(cols):
            if s is None:
                s = x
            if i + 1 == len(cols) or cols[i + 1] != x + 1:
                runs.append((s, x)); s = None
        return runs or [(0, 0)]

    def _sword(self):
        """Biggest connected group of steel pixels below the belt line = the sword (its bright edge
        reads as 'shirt' white, so both count; the sleeves sit above the belt)."""
        m = R.masks(self.base)
        metal = {p for p, k in m.items() if k in ("metal", "shirt") and p[1] > self.belt - 1}
        best, seen = set(), set()
        for p in metal:
            if p in seen:
                continue
            comp, todo = set(), [p]
            seen.add(p)
            while todo:
                x, y = todo.pop(); comp.add((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        q = (x + dx, y + dy)
                        if q in metal and q not in seen:
                            seen.add(q); todo.append(q)
            if len(comp) > len(best):
                best = comp
        # grow by one pixel to take the blade's dark outline with it
        out = set(best)
        bp = self.base.load()
        for x, y in best:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if 0 <= q[0] < self.base.width and 0 <= q[1] < self.base.height and bp[q][3] and R.lum(bp[q][:3]) < 40:
                        out.add(q)
        return out

    def region(self, x, y, long=False):
        if y < self.head:
            return "head"
        arm = x < self.tx0 or x > self.tx1
        if arm and self.belt - 6 <= y <= self.belt + 9:
            return "gloves"
        if y < self.belt or (arm and y <= self.belt + 9):
            return "chest"
        if y < self.boot:
            return "chest" if long else "legs"
        return "feet"


def is_cape(c):
    h, s, v = colorsys.rgb_to_hsv(*(k / 255 for k in c[:3]))
    return 0.22 < h < 0.5 and s > 0.18 and v > 0.08


def cut(outfit_img, body, name, cape=False):
    """{slot: RGBA piece} of one outfit image. The sword is removed and its hole filled from the row."""
    px = outfit_img.load()
    w, h = outfit_img.size
    pieces = {s: Image.new("RGBA", (w, h)) for s in SLOTS}
    pp = {s: pieces[s].load() for s in SLOTS}
    long = name in LONG
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if not c[3]:
                continue
            if (x, y) in body.sword:
                if name == "base":
                    pp["weapon"][x, y] = c
                continue
            if cape and is_cape(c) and y >= body.head - 2:
                pp["back"][x, y] = c
                continue
            r = body.region(x, y, long)
            if r in ("legs", "feet") and not (body.tx0 - 4 <= x <= body.tx1 + 4):
                continue  # outside the legs: leftover sword pixels, not clothing
            if r != "head":
                pp[r][x, y] = c
    # fill the sword hole inside each piece with the nearest pixel of the same row
    for s in ("chest", "gloves", "legs", "feet"):
        p = pp[s]
        for (x, y) in body.sword:
            if p[x, y][3]:
                continue
            l = next((p[x - d, y] for d in range(1, 4) if x - d >= 0 and p[x - d, y][3]), None)
            r = next((p[x + d, y] for d in range(1, 4) if x + d < w and p[x + d, y][3]), None)
            if l and r:
                p[x, y] = l
    return pieces


def compose(view, pieces, head):
    """pieces: {slot: RGBA}; head: the head image (base rotation with hair / face / hair swap applied)."""
    out = Image.new("RGBA", head.size)
    hb = HS.head_bottom(head)
    hp = head.load()
    head_layer = Image.new("RGBA", head.size)
    hl = head_layer.load()
    m = R.masks(head)
    for (x, y), k in m.items():
        if y < hb + 1 or k == "hair":  # head + any long hair falling over the back
            hl[x, y] = hp[x, y]
    for s in ORDER[view]:
        if s == "head":
            out.alpha_composite(head_layer)
        elif s in pieces and pieces[s] is not None:
            out.alpha_composite(pieces[s])
    return out
