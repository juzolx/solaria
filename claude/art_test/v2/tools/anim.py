"""Part-based pixel animation for a 1x art-pixel hero (all moves snap to whole art pixels).

idle(body, weapon, waist, grip)  -> 4 frames: breathe by moving everything above `waist` down 1 px
attack(body, weapon, waist, grip) -> 3 frames: wind-up (lean back, weapon raised), strike (lean in,
                                     weapon swung forward with a 2-colour smear), recover.
The weapon is a separate layer, rotated with a small RotSprite (8x nearest, rotate, mode-downsample)
around its grip point and pinned to the hand (`grip` = hand pixel on the body).
"""
import numpy as np
from PIL import Image
import pixlib as P


def shift_rows(im, waist, dy, dx=0):
    """Rows above `waist` move by (dx, dy); rows below stay. Overlap keeps the moved pixels."""
    a = P.to_np(im)
    out = np.zeros_like(a)
    out[waist:] = a[waist:]
    top = a[:waist]
    h, w = top.shape[:2]
    moved = np.zeros_like(a)
    ys, xs = slice(max(0, dy), min(a.shape[0], h + dy)), slice(max(0, dx), min(w, w + dx))
    src = top[max(0, -dy):h - max(0, dy) if dy > 0 else h, max(0, -dx):w - max(0, dx) if dx > 0 else w]
    moved[ys.start:ys.start + src.shape[0], xs.start:xs.start + src.shape[1]] = src
    m = moved[..., 3] > 0
    out[m] = moved[m]
    return P.to_im(out)


def rotsprite(im, angle, pivot):
    """Rotate pixel art by `angle` degrees (counter-clockwise) around `pivot` without new colours."""
    S = 8
    big = im.resize((im.width * S, im.height * S), Image.NEAREST)
    r = big.rotate(angle, resample=Image.NEAREST, center=(pivot[0] * S + S / 2, pivot[1] * S + S / 2), expand=False)
    a = P.to_np(r)
    h, w = im.height, im.width
    out = np.zeros((h, w, 4), np.uint8)
    for y in range(h):
        for x in range(w):
            blk = a[y * S:(y + 1) * S, x * S:(x + 1) * S].reshape(-1, 4)
            op = blk[blk[:, 3] > 0]
            if len(op) < S * S * 0.22:
                continue
            k, c = np.unique(op[:, :3], axis=0, return_counts=True)
            out[y, x, :3] = k[c.argmax()]; out[y, x, 3] = 255
    return P.to_im(out)


def paste_weapon(canvas, weapon, wgrip, angle, at):
    """Rotate the weapon around its grip and put the grip on canvas point `at`."""
    pad = max(weapon.size) * 2
    big = Image.new("RGBA", (pad, pad), (0, 0, 0, 0))
    off = (pad // 2 - wgrip[0], pad // 2 - wgrip[1])
    big.alpha_composite(weapon, off)
    rot = rotsprite(big, angle, (pad // 2, pad // 2)) if angle else big
    c = canvas.copy()
    tmp = Image.new("RGBA", c.size, (0, 0, 0, 0))
    tmp.paste(rot, (at[0] - pad // 2, at[1] - pad // 2), rot)
    c.alpha_composite(tmp)
    return c


def frame(body, weapon, wgrip, grip, canvas, origin, waist, dy=0, dx=0, angle=0, gdx=0, gdy=0, behind=False):
    b = shift_rows(body, waist, dy, dx)
    c = Image.new("RGBA", canvas, (0, 0, 0, 0))
    hand = (origin[0] + grip[0] + dx + gdx, origin[1] + grip[1] + dy + gdy)
    if weapon is not None and behind:
        c = paste_weapon(c, weapon, wgrip, angle, hand)
    c.alpha_composite(b, origin)
    if weapon is not None and not behind:
        c = paste_weapon(c, weapon, wgrip, angle, hand)
    return c


def finish(im):
    """Re-outline after moving parts (moved pixels can open gaps in the ring)."""
    return P.outline(im, edge_ink=False).crop((1, 1, im.width + 1, im.height + 1))
