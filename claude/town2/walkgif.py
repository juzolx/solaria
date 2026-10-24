"""A short phone clip: the town at dusk (2x) with the hero walker crossing the square."""
from PIL import Image
import iso
from compose import dusk

t, img = iso.sample("out")
dk = dusk(img, t.lights)
frames = [Image.open(f"gen3/folk/hero_walk_north-east_{i}.png").convert("RGBA") for i in range(4)]
tint = lambda im: Image.merge("RGBA", [c.point(lambda v, k=k: int(v * k)) for c, k in zip(im.split(), (0.62, 0.6, 0.8, 1.0))])
frames = [tint(f) for f in frames]
x0, y0 = t.centre(13, 21)
x1, y1 = t.centre(13, 14)
vw, vh = 215, 466
cx, cy = 380, 330
ox, oy = cx - vw // 2, cy - vh // 2
out = []
steps = 40
for k in range(steps):
    f = dk.copy()
    x = round(x0 + (x1 - x0) * k / steps)
    y = round(y0 + (y1 - y0) * k / steps)
    s = frames[(k // 2) % 4]
    f.alpha_composite(s, (x - s.width // 2, y - s.height + 4))
    out.append(f.crop((ox, oy, ox + vw, oy + vh)).resize((vw * 2, vh * 2), Image.NEAREST).convert("P", palette=Image.ADAPTIVE, colors=255))
out[0].save("out/iso_phone_2x_walk.gif", save_all=True, append_images=out[1:], duration=110, loop=0)
