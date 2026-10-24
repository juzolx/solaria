"""One drawing per weapon, placed in the hand on every frame (so the weapon keeps one shape all through a swing).

Per frame we know where PixelLab drew the sword (the pixels a 'replace the sword with a mace' edit changed on that
base frame). From those pixels: the grip end (nearest the body) and the angle. Then: remove the frame's own weapon,
rotate the ONE weapon drawing to that angle (nearest neighbour) and pin its grip to the frame's grip."""
import math
from PIL import Image


def diff(a, b):
    return a[3] != b[3] or (a[3] and sum(abs(a[i] - b[i]) for i in range(3)) > 30)


def changed(base, edit):
    bp, ep = base.load(), edit.load()
    return {(x, y) for y in range(base.height) for x in range(base.width) if diff(bp[x, y], ep[x, y])}


def biggest(pts):
    """Largest 8-connected group (drops stray edit noise)."""
    pts, best, seen = set(pts), set(), set()
    for p in pts:
        if p in seen:
            continue
        comp, todo = set(), [p]; seen.add(p)
        while todo:
            x, y = todo.pop(); comp.add((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if q in pts and q not in seen:
                        seen.add(q); todo.append(q)
        if len(comp) > len(best):
            best = comp
    return best


def axis(pts, body_centre):
    """(grip, tip, angle): the two far ends of the pixel group; the grip is the end nearer the body centre."""
    pts = list(pts)
    a = max(pts, key=lambda p: (p[0] - pts[0][0]) ** 2 + (p[1] - pts[0][1]) ** 2)
    b = max(pts, key=lambda p: (p[0] - a[0]) ** 2 + (p[1] - a[1]) ** 2)
    da = (a[0] - body_centre[0]) ** 2 + (a[1] - body_centre[1]) ** 2
    db = (b[0] - body_centre[0]) ** 2 + (b[1] - body_centre[1]) ** 2
    grip, tip = (a, b) if da < db else (b, a)
    return grip, tip, math.atan2(tip[1] - grip[1], tip[0] - grip[0])


def body_centre(im):
    bb = im.getbbox()
    return ((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2)


def scale2x(im):
    """EPX / Scale2x: doubles pixel art while keeping diagonal edges clean (RotSprite step)."""
    w, h = im.size
    src = im.load()
    out = Image.new("RGBA", (w * 2, h * 2)); op = out.load()
    for y in range(h):
        for x in range(w):
            P = src[x, y]
            A = src[x, y - 1] if y > 0 else P
            B = src[x + 1, y] if x < w - 1 else P
            C = src[x - 1, y] if x > 0 else P
            D = src[x, y + 1] if y < h - 1 else P
            e = [P, P, P, P]
            if C == A and C != D and A != B: e[0] = A
            if A == B and A != C and B != D: e[1] = B
            if D == C and D != B and C != A: e[2] = C
            if B == D and B != A and D != C: e[3] = D
            op[2 * x, 2 * y], op[2 * x + 1, 2 * y], op[2 * x, 2 * y + 1], op[2 * x + 1, 2 * y + 1] = e
    return out


def rotsprite(im, deg, centre):
    """Rotate pixel art cleanly: Scale2x three times (8x), rotate with nearest, sample back down to 1x."""
    big = scale2x(scale2x(scale2x(im)))
    r = big.rotate(deg, resample=Image.NEAREST, center=(centre[0] * 8 + 4, centre[1] * 8 + 4))
    out = Image.new("RGBA", im.size); rp, op = r.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            op[x, y] = rp[x * 8 + 4, y * 8 + 4]
    return out


class Weapon:
    """A weapon cut ONCE from one frame: its pixels, grip and angle. `hand`: where the hand is on that frame
    (the grip is the end nearest the hand; default: the end nearest the body centre)."""

    def __init__(self, frame, pts, hand=None):
        pts = biggest(pts)
        self.grip, self.tip, self.ang = axis(pts, hand or body_centre(frame))
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        self.x0, self.y0 = min(xs), min(ys)
        self.img = Image.new("RGBA", (max(xs) - self.x0 + 1, max(ys) - self.y0 + 1))
        fp = frame.load()
        for (x, y) in pts:
            self.img.putpixel((x - self.x0, y - self.y0), fp[x, y])

    def placed(self, size, grip, ang):
        """The weapon drawing on a canvas of `size`, turned to `ang` with its grip at `grip`."""
        pad = max(self.img.size) * 2 + 4
        big = Image.new("RGBA", (pad * 2, pad * 2))
        gx, gy = self.grip[0] - self.x0, self.grip[1] - self.y0
        big.alpha_composite(self.img, (pad - gx, pad - gy))  # grip sits at the canvas centre
        rot = rotsprite(big, -math.degrees(ang - self.ang), (pad, pad))
        out = Image.new("RGBA", size)
        out.paste(rot, (grip[0] - pad, grip[1] - pad), rot)
        return out


def swap(frame, sword_pts, weapon, grip, ang):
    """Remove the frame's own weapon pixels, fill holes over the body from the row, draw `weapon` in the hand."""
    out = frame.copy(); op = out.load()
    for (x, y) in sword_pts:
        l = next((op[x - d, y] for d in (1, 2, 3) if x - d >= 0 and (x - d, y) not in sword_pts and op[x - d, y][3]), None)
        r = next((op[x + d, y] for d in (1, 2, 3) if x + d < out.width and (x + d, y) not in sword_pts and op[x + d, y][3]), None)
        op[x, y] = l if (l and r) else (0, 0, 0, 0)
    out.alpha_composite(weapon.placed(out.size, grip, ang))
    return out
