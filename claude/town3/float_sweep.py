"""Juzo's floating-props sweep (Oct 26): the whole town by day for before/after pictures.
  py float_sweep.py render OUT TAG   -> OUT/TAG_<look>.png, the day base of every look
  py float_sweep.py sheets OUT       -> 2x crops of every lot and the square, and a contact
                                         sheet of each prop moved or removed, before | after"""
import os
import sys
from PIL import Image, ImageDraw

LOOKS = [("holy", "built"), ("ruin", "built"), ("lot", "lot")]
# every lot and the square: name, cell at the crop's centre
PLACES = [("dungeon", (19, 5)), ("guild_training_yard", (33, 5)), ("inn", (14, 11)), ("tavern", (28, 15)),
          ("church", (5, 12)), ("graveyard", (6, 4)), ("shop", (10, 21)), ("blacksmith", (5, 31)),
          ("vault", (29, 22)), ("trophy_cabin", (4, 22)), ("clinic_pen", (27, 31)), ("square", (20, 20)),
          ("old_smithy_plaza", (11, 18)), ("gate_fields", (15, 33))]
# each prop moved or removed: label, look, cell
CHANGES = [("prophecy stone moved to the plateau's front", "holy_built", (15, 5)),
           ("plateau shrine and torch removed", "holy_built", (15, 3)),
           ("brazier behind the Tavern removed", "holy_built", (22, 10)),
           ("lane props and lamp behind the Inn removed", "holy_built", (14, 9)),
           ("lamp behind the Inn removed", "holy_built", (17, 11)),
           ("public garden behind the Tavern removed", "holy_built", (26, 12)),
           ("Tavern-front props removed", "holy_built", (25, 15)),
           ("market stalls pulled in from the Tavern and Vault", "holy_built", (24, 19)),
           ("lamp off the Vault's lot", "holy_built", (31, 22)),
           ("lamp behind the Clinic removed", "holy_built", (22, 31)),
           ("pen fence behind the Clinic", "holy_built", (28, 31)),
           ("training ring clear of the Guild and tower", "holy_built", (36, 4)),
           ("church garden: angel moved, hidden benches removed", "holy_built", (6, 4)),
           ("lamp moved off the Inn wing", "holy_built", (8, 13)),
           ("Inn-yard lantern on the wing removed", "holy_built", (12, 13)),
           ("wall torch and reeds behind the Blacksmith", "holy_built", (2, 27)),
           ("crops and fence behind the gatehouse", "holy_built", (13, 34)),
           ("gate torch behind the gatehouse removed", "holy_built", (17, 36)),
           ("old smithy spot: paved plaza", "holy_built", (11, 18)),
           ("Hardcore graves behind the Inn removed", "ruin_built", (8, 4)),
           ("Hardcore graves behind the ruin removed", "ruin_built", (4, 18)),
           ("empty-lot rope behind the Inn wing", "lot_lot", (6, 10)),
           ("empty-lot rope behind the Shop", "lot_lot", (6, 20))]


def render(out, tag):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import export_town as E
    os.makedirs(out, exist_ok=True)
    for church, cabin in LOOKS:
        E.render(church, cabin, lit=False).save(f"{out}/{tag}_{church}_{cabin}.png")
    print("saved", out, tag)


def pair(a, b, label, scale):
    w, h = a.width * scale, a.height * scale
    S = Image.new("RGB", (w * 2 + 8, h + 22), (20, 18, 24))
    d = ImageDraw.Draw(S)
    d.text((4, 5), f"BEFORE   {label}", fill=(255, 255, 255))
    d.text((w + 12, 5), "AFTER", fill=(255, 255, 255))
    S.paste(a.resize((w, h), Image.NEAREST), (0, 22))
    S.paste(b.resize((w, h), Image.NEAREST), (w + 8, 22))
    return S


def sheets(out):
    import compose as C
    load = lambda tag, look: Image.open(f"{out}/{tag}_{look}.png").convert("RGB")
    before = {f"{c}_{b}": load("before", f"{c}_{b}") for c, b in LOOKS}
    after = {f"{c}_{b}": load("after", f"{c}_{b}") for c, b in LOOKS}
    crop = lambda im, i, j, w, h: im.crop((int(C.at(i, j)[0]) - w // 2, int(C.at(i, j)[1]) - h * 2 // 3,
                                           int(C.at(i, j)[0]) + w // 2, int(C.at(i, j)[1]) + h // 3))
    os.makedirs(f"{out}/places", exist_ok=True)
    tiles = []
    for name, (i, j) in PLACES:      # 2x, the width of a phone (215 map px)
        p = pair(crop(before["holy_built"], i, j, 215, 200), crop(after["holy_built"], i, j, 215, 200), name, 2)
        p.save(f"{out}/places/{name}.png")
        tiles.append(p)
    grid(tiles, 2).save(f"{out}/sweep_2x_every_lot.png")
    tiles = [pair(crop(before[look], i, j, 120, 110), crop(after[look], i, j, 120, 110), label, 2)
             for label, look, (i, j) in CHANGES]
    grid(tiles, 3).save(f"{out}/contact_sheet_moved_props.png")
    print("sheets", out)


def grid(tiles, cols):
    w, h = max(t.width for t in tiles), max(t.height for t in tiles)
    rows = (len(tiles) + cols - 1) // cols
    S = Image.new("RGB", (cols * (w + 10), rows * (h + 10)), (40, 36, 44))
    for k, t in enumerate(tiles):
        S.paste(t, ((k % cols) * (w + 10), (k // cols) * (h + 10)))
    return S


if __name__ == "__main__":
    {"render": lambda: render(sys.argv[2], sys.argv[3]), "sheets": lambda: sheets(sys.argv[2])}[sys.argv[1]]()
