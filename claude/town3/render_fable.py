"""The picture set for one Fable review round: whole town day / dusk / Hardcore, phone 2x on the
square, the gate and the dungeon (plus 3x on the dungeon), the layout map. The in-game walker GIF
and strip come from walker_capture.gd. Usage: py render_fable.py out/fable_r1"""
import os
import subprocess
import sys
import compose as C
from render_set import town, view


def main(out):
    os.makedirs(out, exist_ok=True)
    day3, dusk3 = town(3)
    view(day3).save(f"{out}/01_town_day.png")
    view(dusk3).save(f"{out}/02_town_dusk.png")
    hday, hdusk = town(3, hardcore=True)
    ruin_box = C.BOXES["church"]
    view(hdusk).save(f"{out}/03_town_dusk_hardcore.png")
    k = 4
    for name, (i, j), scale in (("square", (20, 19), 2), ("gate", (19, 32), 2), ("dungeon", (20, 9), 2), ("dungeon", (20, 7), 3),
                                ("church", (6, 13), 2), ("guild_training", (33, 6), 2)):
        x, y = C.at(i, j)
        C.phone(dusk3, x, y, scale).save(f"{out}/{k:02d}_phone_{scale}x_{name}.png")
        k += 1
    x, y = C.at(20, 19)
    C.phone(day3.convert("RGB"), x, y, 2).save(f"{out}/{k:02d}_phone_2x_day_square.png")
    k += 1
    x, y = C.at(6, 10)
    C.phone(hdusk, x, y, 2).save(f"{out}/{k:02d}_phone_2x_hardcore_church.png")
    subprocess.run([sys.executable, "layout_map.py", f"{out}/{k + 1:02d}_layout_map.png"], check=True)
    from PIL import Image
    bx, by, bw, bh = ruin_box           # the ruined Church and its forecourt at dusk, 4x: rubble, the fallen cross, the crows
    hdusk.convert("RGB").crop((bx - 10, by - 10, bx + bw + 30, by + bh + 20)).resize(((bw + 40) * 4, (bh + 30) * 4), Image.NEAREST).save(f"{out}/{k + 2:02d}_ruin_forecourt_4x.png")
    lday, ldusk = town(3, empty=("church", "cabin"))   # both lots unbuilt: the "build here" sign and planks
    for n, (i, j) in enumerate(((4, 13), (15, 32))):
        x, y = C.at(i, j)
        C.phone(lday.convert("RGB"), x, y, 2).save(f"{out}/{k + 3 + n:02d}_phone_2x_day_{'church' if n == 0 else 'cabin'}_lot.png")
    print("saved", out)


if __name__ == "__main__":
    main(sys.argv[1])
