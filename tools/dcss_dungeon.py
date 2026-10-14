"""Copies the Dungeon Crawl Stone Soup (CC0) floor, wall, door and prop tiles the
room view uses into art/dungeon/ (32x32, drawn scaled up by whole pixels).
One theme per zone index (GameData.zone_index): floors and walls, up to 4 variants each.
Run:  python3 tools/dcss_dungeon.py [/path/to/Dungeon Crawl Stone Soup Full]
"""
import glob, os, sys
from PIL import Image

SRC = "/home/claude/dcss/full/Dungeon Crawl Stone Soup Full/dungeon"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "dungeon")

# zone index -> (floor patterns, wall patterns)
THEMES = [
    (["floor/moss_*", "floor/grass_*"], ["wall/brick_brown-vines_*"]),           # Mossy Hollows (forest)
    (["floor/crypt_[0-9]*", "floor/tomb_*"], ["wall/catacombs_*"]),              # the barrows
    (["floor/swamp_*", "floor/bog_green_*"], ["wall/shoals_wall_*"]),            # the drowned coast
    (["floor/volcanic_floor_*"], ["wall/stone_dark_*"]),                       # the burning lands
    (["floor/limestone_*", "floor/mosaic_*"], ["wall/relief_[0-9]*"]),           # the wild myths
    (["floor/floor_vines_*", "floor/lair_[0-9]*"], ["wall/wall_vines_*"]),       # elf realm
    (["floor/crystal_floor_*"], ["wall/crystal_wall_magenta*", "wall/crystal_wall_lightmagenta*"]),  # fairy realm
    (["floor/floor_sand_stone_*", "floor/pebble_brown_*"], ["wall/stone_brick_*"]),  # dwarf realm
    (["floor/white_marble_*", "floor/marble_floor_*"], ["wall/marble_wall_*", "wall/church_*"]),  # angel realm
    (["floor/demonic_red_*", "floor/infernal_[0-9]*"], ["wall/hell_*"]),         # demon realm
]
PROPS = {"door_closed": "doors/closed_door", "door_open": "doors/open_door", "door_runed": "doors/runed_door",
         "chest": "chest_2_closed", "chest_open": "chest_2_open", "boulder": "boulder", "fountain": "blue_fountain",
         "blood_fountain": "blood_fountain", "sarcophagus": "sarcophagus_open", "box": "large_box",
         "pillar": "zot_pillar", "torch": "wall/torches/torch_1"}

def pick(patterns, n=4):
    files = []
    for p in patterns:
        files += sorted(f for f in glob.glob(os.path.join(SRC, p + ".png")) if "_old" not in f)
    out, seen = [], set()
    for f in files:
        if f not in seen:
            out.append(f); seen.add(f)
    return out[:n]

if __name__ == "__main__":
    if len(sys.argv) > 1:
        SRC = os.path.join(sys.argv[1], "dungeon")
    os.makedirs(OUT, exist_ok=True)
    for i, (floors, walls) in enumerate(THEMES):
        for kind, pats in (("floor", floors), ("wall", walls)):
            fs = pick(pats)
            assert fs, (i, kind, pats)
            for j, f in enumerate(fs):
                Image.open(f).convert("RGBA").save(os.path.join(OUT, "z%d_%s_%d.png" % (i, kind, j)), optimize=True)
    for k, p in PROPS.items():
        fs = pick([p], 1) or pick([p + "*"], 1)
        assert fs, k
        Image.open(fs[0]).convert("RGBA").save(os.path.join(OUT, k + ".png"), optimize=True)
    # statues (a few, for room decoration)
    for j, f in enumerate([os.path.join(SRC, "statues", n + ".png") for n in ["crumbled_column", "crumbled_column_3", "granite_statue", "crumbled_column_5"]]):
        Image.open(f).convert("RGBA").save(os.path.join(OUT, "statue_%d.png" % j), optimize=True)
    open(os.path.join(OUT, "CREDITS.md"), "w").write("# Dungeon tiles\n\nDungeon Crawl Stone Soup 32x32 tiles, CC0 (https://opengameart.org/content/dungeon-crawl-32x32-tiles), by the DCSS artists (https://github.com/crawl/tiles/blob/master/ARTISTS.md). Copied by tools/dcss_dungeon.py.\n")
    print("done", len(os.listdir(OUT)), "files")
