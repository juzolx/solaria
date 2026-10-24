"""Procedural town ground for the Solaria town concept, at art-pixel size (2x on export).

Layout follows art/town/town.json (704x1088 at 1x) halved to art pixels, extended by 96 art px
at the bottom for the Church, the trophy cabin and empty plots. Pure palette colours.
"""
import numpy as np
from PIL import Image

W, H = 352, 680  # art px (file 704x1360)


def hexc(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.uint8)


C = {k: hexc(v) for k, v in {
    "grass": "265c42", "grass_hi": "3e8948", "grass_lo": "193c3e", "grass_fleck": "75a743",
    "dirt": "8f563b", "dirt_hi": "a3825f", "dirt_lo": "5a3f35",
    "stone": "7d8798", "stone_hi": "a8a8ba", "stone_lo": "545d70", "stone_dk": "34323b",
    "cliff": "4a4852", "cliff_hi": "625f6a", "cliff_lo": "34323b", "cliff_dk": "1f1d24",
    "soil": "5a3f35", "soil_lo": "3e2731", "crop": "75a743",
    "fence": "6a4a28", "fence_hi": "9a7040",
}.items()}


def noise(h, w, seed, scale=1):
    r = np.random.default_rng(seed)
    n = r.random((h // scale + 2, w // scale + 2))
    return np.kron(n, np.ones((scale, scale)))[:h, :w]


def smooth(h, w, seed, cell=12):
    r = np.random.default_rng(seed)
    small = (r.random((h // cell + 2, w // cell + 2)) * 255).astype(np.uint8)
    im = Image.fromarray(small, "L").resize(((w // cell + 2) * cell, (h // cell + 2) * cell), Image.BICUBIC)
    return np.asarray(im, float)[:h, :w] / 255.0


def ground(seed=7):
    img = np.zeros((H, W, 3), np.uint8)
    img[:] = C["grass"]
    # clumpy grass: low-frequency patches plus sparse two-pixel tufts (light from top-left)
    big = smooth(H, W, seed, 14) * 0.7 + smooth(H, W, seed + 9, 5) * 0.3
    img[big < 0.27] = C["grass_lo"]
    img[big > 0.80] = C["grass_hi"]
    t = noise(H, W, seed + 1, 1)
    tuft = (t > 0.965)
    img[tuft & (big >= 0.36)] = C["grass_hi"]
    img[np.roll(tuft, 1, 0) & (big >= 0.36)] = C["grass_lo"]
    img[(t < 0.004)] = C["grass_fleck"]
    road = np.zeros((H, W), bool)
    # main north-south road from the gate down to the bottom
    road[60:H, 142:212] = True
    # wide plaza in front of the gate and the guild/inn doors
    road[80:180, 40:320] = True
    # east-west street past shop and smith
    road[250:290, 40:320] = True
    # street past tavern and vault
    road[420:450, 40:320] = True
    # lane to church and trophy cabin
    road[548:572, 40:320] = True
    # rough edges
    # wobbly edges: grow/shrink the road by smooth noise within 3 px of its border
    e = smooth(H, W, seed + 2, 6)
    from PIL import ImageFilter
    dist = np.asarray(Image.fromarray((road * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(2.5)), float) / 255
    road = dist > (0.35 + (e - 0.5) * 0.5)
    img[road] = C["dirt"]
    n3 = noise(H, W, seed + 3, 1)
    pebble = road & (n3 > 0.975)
    img[pebble] = C["dirt_hi"]
    img[np.roll(pebble, 1, 0) & road] = C["dirt_lo"]
    rut = smooth(H, W, seed + 5, 9)
    img[road & (rut < 0.12)] = C["dirt_lo"]
    img[road & (rut > 0.90)] = C["dirt_hi"]
    # dark lip where grass meets road (grass casts onto the road from the top-left light)
    lip = road & ~np.roll(road, 1, 0)
    img[np.roll(lip, 1, 0) & road] = C["dirt_lo"]
    # cobbled plaza around the fountain (centre of the map)
    yy, xx = np.mgrid[0:H, 0:W]
    plaza = ((xx - 177) ** 2 / 62 ** 2 + (yy - 218) ** 2 / 44 ** 2) <= 1
    img[plaza] = C["stone"]
    cob = ((xx // 4 + (yy // 3) % 2 * 2) % 2 == 0) & ((yy % 3) == 0)
    img[plaza & ((xx + (yy // 3) * 2) % 4 == 0)] = C["stone_lo"]
    img[plaza & ((yy % 3) == 0)] = C["stone_lo"]
    img[plaza & ((xx + yy) % 7 == 0)] = C["stone_hi"]
    # cliff wall across the top with the gate cut into it
    cliff_h = 46 + (noise(1, W, seed + 4, 6)[0] * 6).astype(int)
    for x in range(W):
        for y in range(cliff_h[x]):
            v = (x * 7 + y * 3) % 11
            img[y, x] = C["cliff_hi"] if (y % 9 == 0 or v == 0) else (C["cliff"] if v < 7 else C["cliff_lo"])
        img[cliff_h[x] - 2:cliff_h[x], x] = C["cliff_dk"]
    return img


def to_rgba(a):
    out = np.zeros((a.shape[0], a.shape[1], 4), np.uint8)
    out[..., :3] = a; out[..., 3] = 255
    return Image.fromarray(out, "RGBA")


if __name__ == "__main__":
    to_rgba(ground()).resize((W * 2, H * 2), Image.NEAREST).save(r"C:\ai\art_work\ground_test.png")
