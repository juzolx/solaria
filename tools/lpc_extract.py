"""Pulls the parts of the LPC character generator Solaria uses into art/lpc/.

Only the right-facing row of each animation is kept (the hero always faces
right), deduplicated by source file. Writes art/lpc/manifest.json (items,
layers, z order, recolor material, frame sizes), art/lpc/palettes.json and
art/lpc/CREDITS.md (every artist whose work is used, with licenses).

Run:  python3 tools/lpc_extract.py /path/to/Universal-LPC-Spritesheet-Character-Generator
"""
import hashlib, json, os, sys
from PIL import Image

SRC = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/lpc"
SHEETS = os.path.join(SRC, "spritesheets")
DEFS = os.path.join(SRC, "sheet_definitions")
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "lpc")
BODIES = ["male", "female", "muscular"]
# animation -> (frame size, frames). Oversize weapon swings use bigger frames.
ANIMS = ["idle", "walk", "slash", "thrust", "spellcast", "shoot", "combat_idle"]
CUSTOM = {"slash_128": ("slash", 128), "slash_oversize": ("slash", 192), "thrust_oversize": ("thrust", 192), "walk_128": ("walk", 128)}

# id -> definition file, plus options:
#   variant: which pre-colored file to use (pick the material's base color so it can be recolored)
#   material: recolor material for variant items (the definition's own is used otherwise)
C = {}
def add(i, path, **kw):
    C[i] = dict(def_path=path, **kw)

add("body", "body/body.json")
for k, p in {"human_m": "human/heads_human_male", "human_f": "human/heads_human_female", "orc_m": "fantasy/heads_orc_male",
             "orc_f": "fantasy/heads_orc_female", "goblin": "fantasy/heads_goblin", "troll": "fantasy/heads_troll",
             "lizard_m": "reptile/heads_lizard_male", "lizard_f": "reptile/heads_lizard_female", "wolf_m": "beast/heads_wolf_male",
             "wolf_f": "beast/heads_wolf_female", "skeleton": "undead/heads_skeleton", "vampire": "undead/heads_vampire",
             "zombie": "undead/heads_zombie", "minotaur": "beast/heads_minotaur", "boar": "beast/heads_boarman"}.items():
    add("head_" + k, "head/heads/%s.json" % p)
add("face_neutral", "head/faces/face_neutral.json")
add("face_angry", "head/faces/face_angry.json")
add("brows_thick", "head/eyebrows/eyebrows_thick.json")
add("brows_thin", "head/eyebrows/eyebrows_thin.json")
add("ears_elven", "head/ears/head_ears_elven.json")
add("ears_long", "head/ears/head_ears_long.json")
add("ears_dragon", "head/ears/head_ears_dragon.json")
add("horns_curled", "head/appendages/head_horns_curled.json")
add("horns_back", "head/appendages/head_horns_backwards.json")
add("wings_bat", "body/wings/wings_bat.json", variant="orange", material="hair")
add("wings_feather", "body/wings/wings_feathered.json", variant="white", material="hair")
add("wings_lizard", "body/lizard/wings_lizard_bat.json")
add("tail_lizard", "body/lizard/tail_lizard.json")
add("tail_wolf", "body/tails/tail_wolf.json", variant="orange", material="hair")
for b in ["beard", "winter", "trimmed", "medium", "5oclock_shadow"]:
    add("beard_" + b, "hair/beards/beards_%s.json" % b)
add("beard_mustache", "hair/mustaches/beards_mustache.json")
HAIR = ["afro", "bangs", "bangslong", "bedhead", "bob", "braid", "buzzcut", "cornrows", "curly_long", "curly_short",
        "dreadlocks_long", "half_up", "high_ponytail", "long", "long_messy", "longhawk", "loose", "messy1", "mop", "pixie",
        "plain", "ponytail", "princess", "shorthawk", "spiked", "spiked_porcupine", "unkempt", "xlong", "balding", "wavy",
        "page", "swoop", "parted", "long_tied", "pigtails", "bunches"]
for h in HAIR:
    hits = [os.path.join(r, f) for r, _, fs in os.walk(os.path.join(DEFS, "hair")) for f in fs if f == "hair_%s.json" % h]
    if hits:
        add("hair_" + h, os.path.relpath(hits[0], DEFS))
# clothes
add("shirt_long", "torso/shirts/longsleeve/torso_clothes_longsleeve.json")
add("shirt_long_v", "torso/shirts/longsleeve/torso_clothes_longsleeve2_vneck.json")
add("shirt_short", "torso/shirts/shortsleeve/torso_clothes_tshirt.json")
add("shirt_sleeveless", "torso/shirts/sleeveless/torso_clothes_sleeveless2.json")
add("tunic_f", "torso/shirts/torso_clothes_tunic.json", variant="white", material="cloth")
add("robe_f", "torso/shirts/torso_clothes_robe.json", variant="white", material="cloth")
add("vest_m", "torso/vest/torso_clothes_vest.json", variant="white", material="cloth")
add("armor_leather", "torso/armour/torso_armour_leather.json")
add("armor_legion", "torso/armour/torso_armour_legion.json")
add("armor_plate", "torso/armour/torso_armour_plate.json")
add("shoulders_pauldrons", "arms/shoulders/shoulders_pauldrons.json")
add("shoulders_legion", "arms/shoulders/shoulders_legion.json")
add("shoulders_mantal", "arms/shoulders/shoulders_mantal.json")
add("arms_plate", "arms/arms_armour.json")
add("arms_bracers", "arms/wrists/arms_bracers.json")
add("arms_gloves", "arms/arms_gloves.json")
add("legs_pants", "legs/pants/legs_pants.json")
add("legs_leggings", "legs/leggings/legs_leggings.json")
add("legs_plate", "legs/legs_armour.json")
add("legs_skirt", "legs/skirts/legs_skirts_plain.json")
add("legs_skirt_legion", "legs/skirts/legs_skirts_legion.json")
add("legs_shorts", "legs/shorts/legs_shorts.json")
add("feet_boots", "feet/boots/feet_boots_revised.json")
add("feet_boots_rim", "feet/boots/feet_boots_rim.json")
add("feet_shoes", "feet/shoes/feet_shoes_revised.json")
add("feet_sandals", "feet/feet_sandals.json")
add("feet_plate", "feet/feet_armour.json")
add("cape_solid", "torso/cape/cape_solid.json")
add("cape_tattered", "torso/cape/cape_tattered.json")
add("hood", "headwear/coverings/hoods/hat_hood_cloth.json")
add("cap_leather", "headwear/hats/caps/hat_cap_leather.json", variant="white", material="cloth")
add("wizard_hat", "headwear/hats/magic/hat_magic_wizard.json", variant="white", material="cloth")
add("crown", "headwear/hats/formal/hat_formal_crown.json", variant="steel", material="metal")
add("tiara", "headwear/hats/formal/hat_formal_tiara.json", variant="steel", material="metal")
for h in ["bascinet", "greathelm", "close", "armet", "barbuta", "flattop", "mail", "sugarloaf", "barbarian", "barbarian_viking"]:
    add("helm_" + h, "headwear/helmets/helmets/hat_helmet_%s.json" % h)
add("helm_horns", "headwear/helmets/accessories/hat_accessory_horns_upward.json")
# weapons: metal ones keep the steel file (metal's base color) and recolor
add("w_sword", "weapons/sword/weapon_sword_arming.json", variant="steel", material="metal")
add("w_longsword", "weapons/sword/weapon_sword_longsword.json", variant="longsword")
add("w_dagger", "weapons/sword/weapon_sword_dagger.json", variant="dagger")
add("w_katana", "weapons/sword/weapon_sword_katana.json", variant="katana")
add("w_axe", "weapons/blunt/weapon_blunt_waraxe.json", variant="waraxe")
add("w_mace", "weapons/blunt/weapon_blunt_mace.json", variant="mace")
add("w_flail", "weapons/blunt/weapon_blunt_flail.json", variant="flail")
add("w_spear", "weapons/polearm/weapon_polearm_spear.json", variant="steel", material="metal")
add("w_halberd", "weapons/polearm/weapon_polearm_halberd.json", variant="halberd")
add("w_scythe", "weapons/polearm/weapon_polearm_scythe.json", variant="scythe")
add("w_bow", "weapons/ranged/bow/weapon_ranged_bow_normal.json", variant="medium")
add("w_crossbow", "weapons/ranged/weapon_ranged_crossbow.json", variant="crossbow")
add("w_staff", "weapons/magic/weapon_magic_gnarled.json", variant="medium")
add("w_staff_simple", "weapons/magic/weapon_magic_simple.json", variant="simple")
add("w_crystal", "weapons/magic/weapon_magic_crystal.json", variant="purple")
add("w_wand", "weapons/magic/weapon_magic_wand.json", variant="wand")
add("sh_heater", "weapons/shields/heater/shield_heater_revised_wood.json")
add("sh_heater_trim", "weapons/shields/heater/shield_heater_revised_trim.json")
add("sh_kite", "weapons/shields/shield_kite.json", variant="kite gray")
add("sh_scutum", "weapons/shields/scutum/shield_scutum.json", variant="scutum")


def frame_info(anim):
    if anim in CUSTOM:
        return CUSTOM[anim][1]
    return 64


def find_file(d, anim, variant, custom):
    base = os.path.join(SHEETS, d)
    v = variant
    cands = []
    if custom:
        cands += [os.path.join(base, (v or "") + ".png")]
        if os.path.isdir(base):
            cands += sorted(os.path.join(base, f) for f in os.listdir(base) if f.endswith(".png"))
    else:
        cands += [os.path.join(base, anim + ".png")]
        sub = os.path.join(base, anim)
        if v:
            cands += [os.path.join(sub, v + ".png"), os.path.join(sub, v.replace(" ", "_") + ".png")]
        if os.path.isdir(sub):
            cands += sorted(os.path.join(sub, f) for f in os.listdir(sub) if f.endswith(".png"))
    for c in cands:
        if os.path.isfile(c):
            return c
    return None


def right_row(path, size):
    im = Image.open(path).convert("RGBA")
    rows = im.height // size
    r = 3 if rows >= 4 else 0
    strip = im.crop((0, r * size, im.width, r * size + size))
    if strip.getbbox() is None:
        return None
    return strip


def main():
    os.makedirs(os.path.join(OUT, "f"), exist_ok=True)
    manifest = {"items": {}, "anims": ANIMS}
    credits = {}
    written = {}
    total = 0
    for item, opt in C.items():
        dp = os.path.join(DEFS, opt["def_path"])
        if not os.path.isfile(dp):
            print("no definition", item, opt["def_path"]); continue
        d = json.load(open(dp))
        rec = d.get("recolors", {})
        mat = opt.get("material") or rec.get("material") or rec.get("color_1", {}).get("material", "")
        entry = {"name": d.get("name", item), "material": mat, "eye": "color_2" in rec, "layers": []}
        for li in range(1, 10):
            L = d.get("layer_%d" % li)
            if not L:
                break
            custom = L.get("custom_animation", "")
            if custom and custom not in CUSTOM:
                continue
            layer = {"z": int(L.get("zPos", 0)), "files": {}}
            for body in BODIES:
                rel = L.get(body)
                if not rel:
                    continue
                if "${head}" in rel:  # faces depend on the head
                    rel = rel.replace("${head}", "female" if body == "female" else "male")
                files = {}
                anims = [custom] if custom else ANIMS
                for a in anims:
                    src = find_file(rel, a, opt.get("variant"), bool(custom))
                    if not src:
                        continue
                    size = frame_info(a) if custom else 64
                    key = src + "|" + str(size)
                    if key not in written:
                        strip = right_row(src, size)
                        if strip is None:
                            written[key] = None
                            continue
                        h = hashlib.sha1(key.encode()).hexdigest()[:14]
                        strip.save(os.path.join(OUT, "f", h + ".png"), optimize=True)
                        written[key] = "f/%s.png" % h
                        total += 1
                    if written[key]:
                        name = CUSTOM[a][0] if custom else a
                        files[name] = {"file": written[key], "size": size}
                if files:
                    layer["files"][body] = files
            if layer["files"]:
                entry["layers"].append(layer)
        if not entry["layers"]:
            print("nothing usable", item); continue
        manifest["items"][item] = entry
        for c in d.get("credits", []):
            k = c.get("file", "")
            credits[k] = c
    json.dump(manifest, open(os.path.join(OUT, "manifest.json"), "w"), indent=0)
    pals = {}
    for mat in ["body", "cloth", "hair", "metal", "eye", "wood"]:
        meta = json.load(open(os.path.join(SRC, "palette_definitions", mat, "meta_%s.json" % mat)))
        p = {}
        for f in sorted(os.listdir(os.path.join(SRC, "palette_definitions", mat))):
            if f.startswith(mat + "_"):
                p.update(json.load(open(os.path.join(SRC, "palette_definitions", mat, f))))
        pals[mat] = {"base": meta["base"], "palettes": p}
    pals["all"] = {"base": "", "palettes": json.load(open(os.path.join(SRC, "palette_definitions", "all", "all_lpcr.json")))}
    json.dump(pals, open(os.path.join(OUT, "palettes.json"), "w"))
    lines = ["# Character art credits (LPC)", "",
             "Hero art is built from the Liberated Pixel Cup (LPC) Universal Spritesheet Character Generator.",
             "Licenses: CC-BY-SA 3.0/4.0, GPL 2.0/3.0, OGA-BY 3.0, CC-BY 3.0/4.0, CC0, as listed per part.",
             "Source: https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator", ""]
    for k in sorted(credits):
        c = credits[k]
        lines.append("- **%s**: %s (%s)" % (k, ", ".join(c.get("authors", [])), ", ".join(c.get("licenses", []))))
    open(os.path.join(OUT, "CREDITS.md"), "w").write("\n".join(lines) + "\n")
    print("items", len(manifest["items"]), "files", total)


if __name__ == "__main__":
    main()
