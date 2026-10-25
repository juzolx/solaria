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
    print("saved", out)


if __name__ == "__main__":
    main(sys.argv[1])
