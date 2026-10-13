"""Copies the hit and spell effects Solaria uses from BDragon1727's
"750 Effect and FX Pixel All" (free version) into art/fx/.

Each source sheet has 9 color rows of 64x64 frames; we keep one row per effect.
Run: python3 tools/fx_extract.py "<unzipped pack>/Free"
Free license: non-commercial games. A commercial release needs a contribution
(any amount) to the artist: https://bdragon1727.itch.io/750-effect-and-fx-pixel-all
"""
import glob, json, os, sys
from PIL import Image

SRC = sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "fx")
ROWS = {"fire": 0, "arcane": 1, "ice": 2, "nature": 3, "earth": 4, "holy": 5, "mauve": 6, "blood": 7, "void": 8}
# name: (sheet number, color row)
FX = {
    "slash": (509, "holy"), "slash_crit": (509, "fire"), "claw": (516, "blood"),
    "pierce": (398, "holy"), "impact": (336, "holy"), "impact_red": (336, "blood"),
    "crit": (293, "fire"), "burst": (474, "fire"),
    "fire": (527, "fire"), "ice": (336, "ice"), "lightning": (274, "holy"), "poison": (466, "nature"),
    "holy": (314, "holy"), "shadow": (664, "void"), "nature": (223, "nature"), "arcane": (286, "arcane"),
    "shatter": (286, "ice"), "heal": (487, "nature"), "levelup": (635, "holy"), "blood": (336, "blood"),
}


def main():
    files = {os.path.basename(p)[:-4]: p for p in glob.glob(os.path.join(SRC, "**", "*.png"), recursive=True)}
    os.makedirs(OUT, exist_ok=True)
    info = {}
    for name, (num, row) in FX.items():
        p = files.get(str(num)) or files.get("%02d" % num)
        if not p:
            print("missing", num); continue
        im = Image.open(p).convert("RGBA")
        r = ROWS[row]
        strip = im.crop((0, r * 64, im.width, r * 64 + 64))
        n = im.width // 64
        # drop empty trailing frames
        while n > 1 and strip.crop(((n - 1) * 64, 0, n * 64, 64)).getbbox() is None:
            n -= 1
        strip = strip.crop((0, 0, n * 64, 64))
        strip.save(os.path.join(OUT, name + ".png"), optimize=True)
        info[name] = n
    json.dump(info, open(os.path.join(OUT, "fx.json"), "w"))
    open(os.path.join(OUT, "CREDITS.md"), "w").write(
        "# Effects\n\nHit and spell effects: \"750 Effect and FX Pixel All\" (free version) by BDragon1727.\n"
        "https://bdragon1727.itch.io/750-effect-and-fx-pixel-all\n\n"
        "Free license: non-commercial games only. For a commercial release, contribute any amount to the artist first.\n")
    print(info)


if __name__ == "__main__":
    main()
