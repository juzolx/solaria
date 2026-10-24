"""Put a hair style (a PixelLab edit of the base NORTH/SOUTH rotation) onto any frame of any outfit state.
The head is located in the target frame by matching the base rotation's head (silhouette + colour),
the old hair is erased, the new head is pasted at that offset, and the sword / sleeves that were in
front of the head are laid back on top. On the SOUTH view the base face is kept (faces are a separate option)."""
import os, sys
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "custom"))
import recolour as R


def head_bottom(im):
    bb = im.getbbox()
    return int(bb[1] + (bb[3] - bb[1]) * R.HEAD_FRAC)


def head_patch(src):
    """{(x, y): rgba} of the head: everything above the head line plus hair below it (long hair, ponytail)."""
    hb, px, m = head_bottom(src), src.load(), R.masks(src)
    return {p: px[p] for p, k in m.items() if p[1] < hb or k == "hair"}


def find_offset(base, frame, r=10):
    """Shift (dx, dy) that best lays the base rotation's head over the head in `frame`."""
    hb = head_bottom(base)
    bp = base.load(); fp = frame.load()
    pts = [(x, y) for y in range(hb) for x in range(base.width) if bp[x, y][3]]
    cx, cy = (frame.width - base.width) // 2, (frame.height - base.height) // 2
    best = None
    for dy in range(cy - r, cy + r + 1):
        for dx in range(cx - r, cx + r + 1):
            cost = 0
            for x, y in pts:
                X, Y = x + dx, y + dy
                if not (0 <= X < frame.width and 0 <= Y < frame.height) or not fp[X, Y][3]:
                    cost += 3000; continue
                a, b = bp[x, y], fp[X, Y]
                cost += min(3000, (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2)
            if best is None or cost < best[0]:
                best = (cost, dx, dy)
    return best[1], best[2]


def face_box(base_south):
    """Rows/cols of the base front face (brows to chin, between the cheeks) that are kept on SOUTH."""
    m = R.masks(base_south)
    pts = [p for p, k in m.items() if k in ("skin", "face") and p[1] < head_bottom(base_south)]
    xs = sorted(p[0] for p in pts); ys = sorted(p[1] for p in pts)
    # eyes to chin (the base forehead is covered by its own bangs), minus the outermost columns (ears)
    return xs[len(xs) // 20] + 1, ys[len(ys) // 4], xs[-len(xs) // 20 - 1] - 1, ys[-1]


def swap(frame, base, hair_img, keep_face=None):
    """frame: target RGBA frame. base: unedited base rotation for that direction. hair_img: base rotation
    with the new hair. keep_face: base SOUTH image -> keep its face pixels (front view only)."""
    dx, dy = find_offset(base, frame)
    out = frame.copy()
    op = out.load()
    fm = R.masks(frame)
    fhb = head_bottom(base) + dy
    bp = base.load()
    old_head = {(x + dx, y + dy) for y in range(head_bottom(base)) for x in range(base.width) if bp[x, y][3]}
    front = {}
    for (x, y), k in fm.items():
        if k == "metal" and y < fhb + 4:
            front[(x, y)] = op[x, y]  # sword stays on top of the new head
        elif k == "hair" or (x, y) in old_head:
            op[x, y] = (0, 0, 0, 0)
    patch = head_patch(hair_img)
    if keep_face is not None:  # base face, with the new style's hair (bangs) still on top of it
        x0, y0, x1, y1 = face_box(keep_face)
        kp = keep_face.load()
        hm = R.masks(hair_img)
        km = R.masks(keep_face)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                bangs = hm.get((x, y)) == "hair" and y < y0 + 3  # below the eyes 'hair' is stubble: not part of a style
                if kp[x, y][3] and km.get((x, y)) != "hair" and not bangs:
                    patch[(x, y)] = kp[x, y]
    for (x, y), c in patch.items():
        X, Y = x + dx, y + dy
        if 0 <= X < out.width and 0 <= Y < out.height and c[3]:
            op[X, Y] = c
    for p, c in front.items():
        op[p] = c
    # drop orphan pixels left from the old hair outline around the head
    for y in range(max(0, fhb - 40), min(out.height, fhb + 2)):
        for x in range(out.width):
            if op[x, y][3] and (x, y) not in front:
                n = sum(1 for ddx in (-1, 0, 1) for ddy in (-1, 0, 1) if (ddx or ddy)
                        and 0 <= x + ddx < out.width and 0 <= y + ddy < out.height and op[x + ddx, y + ddy][3])
                if n <= 1:
                    op[x, y] = (0, 0, 0, 0)
    return out
