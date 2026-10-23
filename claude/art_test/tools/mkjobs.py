import json
NEG_SHEET = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, scenery, landscape, gradient background, close-up, big character, cropped"
NEG_ONE = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, scenery, landscape, gradient background, close-up, multiple characters, cropped"
races = {
 "human": "human",
 "elf": "elf with long pointed ears",
 "dwarf": "stocky bearded dwarf",
 "orc": "green-skinned orc with tusks",
 "goblin": "small green goblin with big pointed ears",
}
outfits = {
 "warrior": "knight in dark steel plate armor",
 "mage": "mage in a long hooded purple robe holding a staff",
 "ranger": "ranger in brown leather armor and a green hooded cloak",
}
jobs = []
seeds = [11, 12, 13, 14]
for k, d in races.items():
    jobs.append({"name": f"race_{k}_sheet", "seeds": seeds, "neg": NEG_SHEET,
      "prompt": f"pixel art sprite sheet, rows of tiny 32x32 rpg battle sprites of a {d} adventurer in plain linen shirt and trousers, unarmed, fighting stance, three-quarter view facing right, full body, dark fantasy, few colors, thick dark outline, plain white background"})
    jobs.append({"name": f"race_{k}_one", "seeds": seeds, "neg": NEG_ONE,
      "prompt": f"tiny low resolution pixel art battle sprite of a single chibi {d} in a plain linen shirt and trousers, unarmed fighting stance, three-quarter view facing right, small in the center of a large empty plain white background, full body, 32x32 sprite, dark fantasy, few colors, thick dark outline"})
for k, d in outfits.items():
    jobs.append({"name": f"outfit_{k}_sheet", "seeds": seeds, "neg": NEG_SHEET,
      "prompt": f"pixel art sprite sheet, rows of tiny 32x32 rpg battle sprites of a human {d}, fighting stance, three-quarter view facing right, full body, dark fantasy, few colors, thick dark outline, plain white background"})
    jobs.append({"name": f"outfit_{k}_one", "seeds": seeds, "neg": NEG_ONE,
      "prompt": f"tiny low resolution pixel art battle sprite of a single chibi human {d}, fighting stance, three-quarter view facing right, small in the center of a large empty plain white background, full body, 32x32 sprite, dark fantasy, few colors, thick dark outline"})
for k, d in {"sword": "steel longswords and broadswords", "staff": "wooden wizard staffs with glowing crystals"}.items():
    jobs.append({"name": f"weapon_{k}", "seeds": [11, 12, 13], "neg": NEG_SHEET,
      "prompt": f"pixel art game item icons sheet, {d}, each drawn diagonally, low resolution, few colors, thick dark outline, plain white background, dark fantasy rpg inventory"})
json.dump(jobs, open(r"C:\ai\art_work\jobs_heroes.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in jobs))
