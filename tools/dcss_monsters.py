"""Builds Solaria's monster and pet art from the Dungeon Crawl Stone Soup tiles (CC0).

Every monster, boss and Calamity gets a dark-fantasy tile, upscaled 2x (nearest)
to 64x64 and graded a little darker. Two-tile giants (top + bottom) are stacked.
Run:  python3 tools/dcss_monsters.py [/path/to/Dungeon Crawl Stone Soup Full] [--preview]
"""
import os, sys
from PIL import Image, ImageEnhance

SRC = "/home/claude/dcss/full/Dungeon Crawl Stone Soup Full/monster"
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "enemies")

# game monster name -> DCSS tile (path under monster/, no .png; "a+b" stacks a on top of b)
MAP = {
    # Mossy Hollows (forest folk)
    "Kobold": "big_kobold_new", "Redcap": "hobgoblin_new", "Boggart": "unique/ijyb",
    "Will-o'-Wisp": "nonliving/orb_of_ice|hue=-70|sat=0.8", "Barghest": "animals/warg",
    "Spriggan": "spriggan/spriggan_defender", "Pooka": "satyr|hue=0|sat=0.4|val=0.7", "Wolpertinger": "animals/quokka|hue=-10|sat=1.2|val=0.8",
    "Leshy": "unique/leshy", "Woodwose": "unique/chuck|hue=35|sat=0.7", "Black Annis": "unique/agnes", "Grendel": "deep_troll_berserker",
    # The barrows (undead)
    "Ghoul": "undead/ghoul", "Draugr": "undead/wight|hue=150|sat=0.5", "Barrow-Wight": "undead/wight_king", "Banshee": "undead/silent_spectre",
    "Strigoi": "undead/vampire", "Revenant": "undead/profane_servitor", "Gashadokuro": "undead/skeletal_warrior",
    "Vetala": "undead/jiangshi", "Moroi": "undead/vampire_mage", "Garmr": "animals/hell_hound",
    "The Dullahan": "death_knight", "Hel, Queen of the Dead": "unique/ereshkigal",
    # The drowned coast
    "Kappa": "animals/snapping_turtle", "Kelpie": "hippogriff|hue=170|sat=0.7|val=0.8", "Nuckelavee": "centaur_warrior",
    "Bunyip": "animals/alligator", "Umibozu": "undead/shadow", "Selkie": "water_nymph", "Vodyanoy": "animals/giant_toad",
    "Merrow": "merfolk_fighter_water", "Grindylow": "aquatic/swamp_worm", "Ahuizotl": "animals/jackal|hue=160|sat=0.6|val=0.7",
    "Scylla": "unique/lernaean_hydra", "Charybdis": "demons/unspeakable_top+demons/unspeakable_bottom",
    # The burning lands
    "Salamander": "salamander", "Ifrit": "demons/efreet", "Hellhound": "animals/hell_hound", "Chimera": "mutant_beast",
    "Manticore": "manticore", "Cherufe": "nonliving/fire_elemental", "Cyclops": "cyclops_new", "Firebird": "phoenix",
    "Tatzelwurm": "lindwurm", "Basilisk": "animals/basilisk", "Fafnir": "dragons/dragon", "Surtr the Fire Giant": "fire_giant_new",
    # The wild myths
    "Wendigo": "undead/manes|hue=190|sat=0.5|val=1.1", "Jorogumo": "animals/tarantella", "Rakshasa": "demons/rakshasa", "Lamia": "unique/lamia",
    "Gorgon": "greater_naga|hue=80|sat=0.8", "Kitsune": "animals/jackal|hue=5|sat=1.6|val=1.15", "Tikbalang": "minotaur", "Doppelganger": "demons/shadow_demon",
    "Krampus": "demons/orange_demon|hue=-15|sat=0.55|val=0.6", "Bakunawa": "dragons/storm_dragon", "Echidna": "naga_ritualist|hue=110|sat=0.9", "Typhon, Father of Monsters": "unique/serpent_of_hell-geh_top+unique/serpent_of_hell-geh_bottom",
    # Elf realm (Hushwood)
    "Hollow Sentinel": "nonliving/wood_golem", "Grief Wisp": "undead/lost_soul", "Barkhusk": "fungi_plants/treant",
    "Pale Stag": "animals/raiju|sat=0.15|val=1.25", "Rootstrangler": "fungi_plants/thorn_hunter", "Mourning Dryad": "dryad",
    "Owlwraith": "undead/ghost", "Lantern Keeper": "undead/lich", "Blightcap": "fungi_plants/deathcap",
    "Heartrot Treant": "fungi_plants/treant|hue=-40|sat=1.1|val=0.75", "The Weeping Warden": "ironheart_preserver", "The Withered Queen": "enchantress_human",
    # Fairy realm (Glimmer Court)
    "Pixie Swarm": "animals/giant_firefly", "Thornling": "fungi_plants/briar_patch", "Mushroom Knight": "fungi_plants/wandering_mushroom",
    "Glimmermoth": "animals/ghost_moth", "Changeling": "faun", "Moonhare": "animals/quokka|sat=0.2|val=1.3", "Mirror Nymph": "siren_new",
    "Bogle": "goblin_new|hue=60|sat=0.7|val=0.8", "Briar Knight": "spriggan_berserker", "Gilded Fae": "spriggan_enchanter",
    "The Jester of Thorns": "killer_klown_green", "The Fairy Queen": "unique/psyche",
    # Dwarf realm (Ironroot)
    "Forge Sentry": "nonliving/iron_golem", "Slag Golem": "nonliving/iron_elemental", "Rune Hound": "animals/war_dog",
    "Cinder Miner": "deep_dwarf", "Steamcrawler": "animals/boulder_beetle", "Ash Raider": "deep_dwarf_berserker",
    "Rune Wraith": "undead/freezing_wraith", "Anvil Brute": "ogre_new", "Gem Crawler": "nonliving/crystal_guardian",
    "Stoneguard": "nonliving/stone_golem", "Forgemaster Brann": "deep_dwarf_artificer", "High King Thrandor": "deep_dwarf_death_knight",
    # Angel realm
    "Choir Sentinel": "holy/angel", "Halo Wisp": "nonliving/battlesphere", "Gilded Lion": "holy/shedu", "Eye of Judgement": "demons/sun_demon",
    "Sky Serpent": "holy/eastern_dragon|hue=45|sat=0.8|val=1.1", "Cherub": "holy/cherub", "Hymnbird": "kenku_winged", "Executor": "holy/paladin",
    "Sun Golem": "nonliving/guardian_golem", "Throne Warden": "holy/ophan", "Archon Valeth": "holy/daeva",
    "Seraphiel, the First Light": "holy/seraph_top+holy/seraph_bottom",
    # Demon realm (Cinder Abyss)
    "Imp": "demons/imp", "Hellmaw": "demons/hellion", "Chainwraith": "undead/wraith", "Brimstone Brute": "demons/beast",
    "Abyssal Worm": "aquatic/lava_snake", "Ash Fiend": "demons/fiend", "Chain Warden": "demons/hell_sentinel",
    "Soul Broker": "demons/soul_eater", "Obsidian Knight": "hell_knight_new", "Hellborn Duke": "demons/tormentor",
    "Duke Malgrath": "unique/dispater_top+unique/dispater_bottom", "Azgaroth, Lord of the Abyss": "unique/asmodeus_top+unique/asmodeus_bottom",
    # Others
    "Treasure Goblin": "goblin_new",
}
# Bosses keep the art keys the game already uses
BOSS_KEYS = {"Black Annis": "boss_black_annis", "Grendel": "boss_grendel", "The Dullahan": "boss_dullahan",
    "Hel, Queen of the Dead": "boss_hel", "Scylla": "boss_scylla", "Charybdis": "boss_charybdis", "Fafnir": "boss_fafnir",
    "Surtr the Fire Giant": "boss_surtr", "Echidna": "boss_echidna", "Typhon, Father of Monsters": "boss_typhon",
    "The Weeping Warden": "boss_weeping_warden", "The Withered Queen": "boss_withered_queen",
    "The Jester of Thorns": "boss_jester_of_thorns", "The Fairy Queen": "boss_fairy_queen",
    "Forgemaster Brann": "boss_forgemaster_brann", "High King Thrandor": "boss_high_king_thrandor",
    "Archon Valeth": "boss_archon_valeth", "Seraphiel, the First Light": "boss_seraphiel",
    "Duke Malgrath": "boss_duke_malgrath", "Azgaroth, Lord of the Abyss": "boss_azgaroth"}
# Other special fights that have their own art key
EXTRA = {"boss_demon_ancestor": "demons/pit_fiend", "boss_sword_spirit": "nonliving/spectral_lbl|hue=30|sat=1.2|val=1.2"}
# Calamities get their own files: calamity_0 .. calamity_9
CALAMITIES = ["undead/ancient_lich", "demons/balrug", "unique/jormungandr", "abyss/tentacled_starspawn|hue=180|sat=0.35|val=1.2", "undead/bone_dragon",
              "eyes/great_orb_of_eyes|hue=-25|sat=0.7|val=0.7", "demons/blizzard_demon", "unique/iron_giant", "demons/tentacled_monstrosity|hue=-80|sat=0.9|val=0.8", "dragons/shadow_dragon"]
# Class companions: <class>_<stage> (4 stages each)
PETS = {
    "ranger": ["raven", "animals/caustic_shrike", "griffon", "holy/eastern_dragon"],
    "knight": ["hippogriff_new", "griffon", "holy/shedu", "dragons/golden_dragon"],
    "mage": ["nonliving/orb_of_fire", "nonliving/air_elemental", "nonliving/earth_elemental", "nonliving/fire_elemental"],
    "wanderer": ["animals/jackal", "animals/hound", "animals/warg", "animals/hell_hound"],
    "bard": ["animals/caustic_shrike|hue=120|sat=1.3", "raven|hue=200|sat=2.0|val=1.3", "fire_drake", "phoenix"],
}

def find(p):
    for cand in (p, p + "_new", p + "_1"):
        f = os.path.join(SRC, cand + ".png")
        if os.path.exists(f):
            return f
    raise FileNotFoundError(p)

import colorsys

def parse(spec):
    """'tile|hue=30|sat=0.8|val=1.1' -> (tile, opts)."""
    bits = spec.split("|")
    opts = {}
    for b in bits[1:]:
        k, v = b.split("=")
        opts[k] = float(v)
    return bits[0], opts

def tile(name):
    parts = name.split("+")
    ims = [Image.open(find(p)).convert("RGBA") for p in parts]
    if len(ims) == 1:
        return ims[0]
    w = max(i.width for i in ims)
    h = sum(i.height for i in ims)
    out = Image.new("RGBA", (w, h))
    y = 0
    for i in ims:
        out.paste(i, ((w - i.width) // 2, y), i)
        y += i.height
    return out

def strip_shadow(im):
    """DCSS bakes a dithered black shadow under each creature. Pure black pixels
    that don't touch any colored pixel are shadow, not outline: remove them."""
    px = im.load()
    w, h = im.size
    def colored(x, y):
        if not (0 <= x < w and 0 <= y < h):
            return False
        r, g, b, a = px[x, y]
        return a > 0 and (r, g, b) != (0, 0, 0)
    kill = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and (r, g, b) == (0, 0, 0):
                if not any(colored(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy):
                    kill.append((x, y))
    for p in kill:
        px[p] = (0, 0, 0, 0)
    return im

def recolor(im, opts):
    if not opts:
        return im
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0 or (r, g, b) == (0, 0, 0):
                continue
            hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            hh = (hh + opts.get("hue", 0) / 360.0) % 1.0
            s = min(1.0, s * opts.get("sat", 1.0))
            v = min(1.0, v * opts.get("val", 1.0))
            r2, g2, b2 = colorsys.hsv_to_rgb(hh, s, v)
            px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return im

def rim_light(im):
    """A thin cool light on the top edges, so creatures read on dark rooms."""
    px = im.load()
    w, h = im.size
    src = im.copy().load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = src[x, y]
            if a == 0 or (r, g, b) == (0, 0, 0):
                continue
            above = src[x, y - 1] if y > 0 else (0, 0, 0, 0)
            if above[3] == 0 or above[:3] == (0, 0, 0):
                px[x, y] = (min(255, int(r * 0.7 + 210 * 0.3)), min(255, int(g * 0.7 + 215 * 0.3)), min(255, int(b * 0.7 + 235 * 0.3)), a)
    return im

def outline(im, color=(14, 8, 18, 255)):
    """1 px dark outline around the (upscaled) sprite."""
    out = im.copy()
    px = out.load()
    src = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        px[x, y] = color
                        break
    return out

def process(spec):
    name, opts = parse(spec)
    im = strip_shadow(tile(name))
    im = recolor(im, opts)
    im = grade(rim_light(im))
    im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    bbox = im.getbbox()
    pad = Image.new("RGBA", (im.width + 2, im.height + 2))
    pad.paste(im, (1, 1), im)
    return outline(pad)

def grade(im):
    # A touch darker and less saturated: one dark-fantasy look for every tile
    rgb = im.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(0.85)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.92)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out

def make(spec, key, outdir):
    process(spec).save(os.path.join(outdir, key + ".png"), optimize=True)

def art_key(monster):
    out = "".join(ch if "a" <= ch <= "z" else "_" for ch in monster.lower())
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("_")

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if args:
        SRC = os.path.join(args[0], "monster")
    outdir = OUT
    os.makedirs(outdir, exist_ok=True)
    for m, t in MAP.items():
        make(t, BOSS_KEYS.get(m, art_key(m)), outdir)
    for k, t in EXTRA.items():
        make(t, k, outdir)
    for i, t in enumerate(CALAMITIES):
        make(t, "calamity_%d" % i, outdir)
    pets = os.path.join(os.path.dirname(outdir), "pets")
    for cls, stages in PETS.items():
        for i, t in enumerate(stages):
            make(t, "%s_%d" % (cls, i), pets)
    print("done", len(MAP), "monsters,", len(CALAMITIES), "calamities")
