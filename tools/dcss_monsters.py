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
    "Kobold": "big_kobold_new", "Redcap": "hobgoblin_new", "Boggart": "boggart_new",
    "Will-o'-Wisp": "nonliving/insubstantial_wisp", "Barghest": "animals/warg",
    "Spriggan": "spriggan/spriggan_defender", "Pooka": "glowing_shapeshifter", "Wolpertinger": "animals/quokka",
    "Leshy": "unique/leshy", "Woodwose": "troll", "Black Annis": "unique/agnes", "Grendel": "rock_troll",
    # The barrows (undead)
    "Ghoul": "undead/ghoul", "Draugr": "undead/wight", "Barrow-Wight": "undead/wight_king", "Banshee": "undead/silent_spectre",
    "Strigoi": "undead/vampire", "Revenant": "undead/revenant", "Gashadokuro": "undead/skeletal_warrior",
    "Vetala": "undead/jiangshi", "Moroi": "undead/vampire_mage", "Garmr": "animals/hell_hound",
    "The Dullahan": "death_knight", "Hel, Queen of the Dead": "unique/ereshkigal",
    # The drowned coast
    "Kappa": "animals/snapping_turtle", "Kelpie": "nonliving/water_elemental", "Nuckelavee": "centaur_warrior",
    "Bunyip": "animals/alligator", "Umibozu": "abyss/lurking_horror", "Selkie": "water_nymph", "Vodyanoy": "animals/giant_toad",
    "Merrow": "merfolk_fighter_water", "Grindylow": "aquatic/swamp_worm", "Ahuizotl": "animals/jackal",
    "Scylla": "unique/lernaean_hydra", "Charybdis": "abyss/apocalypse_crab",
    # The burning lands
    "Salamander": "salamander", "Ifrit": "demons/efreet", "Hellhound": "animals/hell_hound", "Chimera": "mutant_beast",
    "Manticore": "manticore", "Cherufe": "nonliving/fire_elemental", "Cyclops": "cyclops_new", "Firebird": "phoenix",
    "Tatzelwurm": "lindwurm", "Basilisk": "animals/basilisk", "Fafnir": "dragons/dragon", "Surtr the Fire Giant": "fire_giant_new",
    # The wild myths
    "Wendigo": "undead/hungry_ghost", "Jorogumo": "animals/tarantella", "Rakshasa": "demons/rakshasa", "Lamia": "unique/lamia",
    "Gorgon": "greater_naga", "Kitsune": "animals/jackal", "Tikbalang": "minotaur", "Doppelganger": "shapeshifter",
    "Krampus": "demons/hairy_devil", "Bakunawa": "dragons/storm_dragon", "Echidna": "naga_ritualist", "Typhon, Father of Monsters": "unique/tiamat",
    # Elf realm (Hushwood)
    "Hollow Sentinel": "nonliving/wood_golem", "Grief Wisp": "undead/lost_soul", "Barkhusk": "fungi_plants/treant",
    "Pale Stag": "animals/death_yak", "Rootstrangler": "fungi_plants/thorn_hunter", "Mourning Dryad": "dryad",
    "Owlwraith": "undead/phantom", "Lantern Keeper": "human_monk_ghost", "Blightcap": "fungi_plants/deathcap",
    "Heartrot Treant": "undead/rotting_hulk", "The Weeping Warden": "ironheart_preserver", "The Withered Queen": "enchantress_human",
    # Fairy realm (Glimmer Court)
    "Pixie Swarm": "animals/giant_firefly", "Thornling": "fungi_plants/briar_patch", "Mushroom Knight": "fungi_plants/wandering_mushroom",
    "Glimmermoth": "animals/ghost_moth", "Changeling": "faun", "Moonhare": "animals/quokka", "Mirror Nymph": "siren_new",
    "Bogle": "goblin_new", "Briar Knight": "spriggan_berserker", "Gilded Fae": "spriggan_enchanter",
    "The Jester of Thorns": "killer_klown_green", "The Fairy Queen": "unique/psyche",
    # Dwarf realm (Ironroot)
    "Forge Sentry": "nonliving/iron_golem", "Slag Golem": "nonliving/molten_gargoyle", "Rune Hound": "animals/war_dog",
    "Cinder Miner": "deep_dwarf", "Steamcrawler": "animals/boulder_beetle", "Ash Raider": "deep_dwarf_berserker",
    "Rune Wraith": "undead/freezing_wraith", "Anvil Brute": "ogre_new", "Gem Crawler": "nonliving/crystal_guardian",
    "Stoneguard": "nonliving/stone_golem", "Forgemaster Brann": "deep_dwarf_artificer", "High King Thrandor": "deep_dwarf_death_knight",
    # Angel realm
    "Choir Sentinel": "holy/angel", "Halo Wisp": "nonliving/battlesphere", "Gilded Lion": "holy/shedu", "Eye of Judgement": "eyes/golden_eye",
    "Sky Serpent": "holy/eastern_dragon", "Cherub": "holy/cherub", "Hymnbird": "kenku_winged", "Executor": "holy/paladin",
    "Sun Golem": "nonliving/guardian_golem", "Throne Warden": "holy/ophan", "Archon Valeth": "holy/daeva",
    "Seraphiel, the First Light": "holy/seraph_top+holy/seraph_bottom",
    # Demon realm (Cinder Abyss)
    "Imp": "demons/imp", "Hellmaw": "demons/cacodemon", "Chainwraith": "undead/shadow_wraith", "Brimstone Brute": "demons/beast",
    "Abyssal Worm": "aquatic/lava_snake", "Ash Fiend": "demons/fiend", "Chain Warden": "demons/hell_sentinel",
    "Soul Broker": "demons/soul_eater", "Obsidian Knight": "hell_knight_new", "Hellborn Duke": "demons/pit_fiend",
    "Duke Malgrath": "unique/dispater", "Azgaroth, Lord of the Abyss": "unique/asmodeus",
    # Others
    "Treasure Goblin": "goblin_new",
}
# Calamities get their own files: calamity_0 .. calamity_9
CALAMITIES = ["undead/ancient_lich", "demons/balrug", "unique/jormungandr", "abyss/tentacled_starspawn", "undead/bone_dragon",
              "eyes/great_orb_of_eyes", "demons/blizzard_demon", "unique/iron_giant", "abyss/worldbinder", "dragons/shadow_dragon"]
# Class companions: <class>_<stage> (4 stages each)
PETS = {
    "ranger": ["raven", "animals/caustic_shrike", "griffon", "holy/eastern_dragon"],
    "knight": ["hippogriff_new", "griffon", "holy/shedu", "dragons/golden_dragon"],
    "mage": ["nonliving/orb_of_fire", "nonliving/air_elemental", "nonliving/earth_elemental", "nonliving/fire_elemental"],
    "wanderer": ["animals/jackal", "animals/hound", "animals/warg", "animals/hell_hound"],
    "bard": ["animals/caustic_shrike", "raven", "fire_drake", "phoenix"],
}

def find(p):
    for cand in (p, p + "_new", p + "_1"):
        f = os.path.join(SRC, cand + ".png")
        if os.path.exists(f):
            return f
    raise FileNotFoundError(p)

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

def grade(im):
    # A touch darker and less saturated: one dark-fantasy look for every tile
    rgb = im.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(0.85)
    rgb = ImageEnhance.Brightness(rgb).enhance(0.92)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(im.getchannel("A"))
    return out

def make(name, key, outdir):
    im = grade(tile(name))
    im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    # square canvas (tall two-tile giants stay 64 wide x 128 tall)
    im.save(os.path.join(outdir, key + ".png"))

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
        make(t, art_key(m), outdir)
    for i, t in enumerate(CALAMITIES):
        make(t, "calamity_%d" % i, outdir)
    pets = os.path.join(os.path.dirname(outdir), "pets")
    for cls, stages in PETS.items():
        for i, t in enumerate(stages):
            make(t, "%s_%d" % (cls, i), pets)
    print("done", len(MAP), "monsters,", len(CALAMITIES), "calamities")
