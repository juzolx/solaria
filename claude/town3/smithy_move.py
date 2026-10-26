"""Before/after pictures for moving the Blacksmith to the west farm corner (Juzo, Oct 25):
day and dusk whole town, 2x phone views of the new corner, the old smithy spot and the training yard.
Usage: py smithy_move.py out/smithy_move before|after"""
import os
import sys
import compose as C
from render_set import town, view


def main(out, tag):
    os.makedirs(out, exist_ok=True)
    day, dusk = town(3)
    view(day).save(f"{out}/{tag}_1_town_day.png")
    view(dusk).save(f"{out}/{tag}_2_town_dusk.png")
    for k, (name, (i, j)) in enumerate((("west_corner", (5, 31)), ("old_smithy_spot", (11, 18))), 3):
        x, y = C.at(i, j)
        C.phone(dusk, x, y, 2).save(f"{out}/{tag}_{k}_phone_2x_dusk_{name}.png")
        C.phone(day.convert("RGB"), x, y, 2).save(f"{out}/{tag}_{k + 2}_phone_2x_day_{name}.png")
    x, y = C.at(35, 5)                                        # the Guild's training yard (Juzo: the Guild sat on the dummies)
    C.phone(dusk, x, y, 2).save(f"{out}/{tag}_7_phone_2x_dusk_training_yard.png")
    C.phone(day.convert("RGB"), x, y, 2).save(f"{out}/{tag}_8_phone_2x_day_training_yard.png")
    print("saved", out, tag)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
