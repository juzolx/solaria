import json
T = "tiny pixel art battle sprite, chibi {d}, fighting stance, three-quarter view facing right, full body, dark fantasy, thick dark outline, plain white background, 32x32 sprite"
races = {
 "human": ("tall", "bald human man in a plain linen shirt and brown trousers, bare hands"),
 "elf": ("tall", "elf man with long pointed ears and long blond hair, pale skin, plain linen shirt and brown trousers, bare hands"),
 "orc": ("tall", "muscular green-skinned orc with tusks and a black topknot, plain linen shirt and brown trousers, bare hands"),
 "dwarf": ("short", "stocky dwarf with a big braided red beard, plain linen shirt and brown trousers, bare hands"),
 "goblin": ("short", "small green goblin with huge pointed ears and yellow eyes, plain linen shirt and brown trousers, bare hands"),
}
outfits = {
 "warrior": "human knight wearing dark steel plate armor with pauldrons, gauntlets and greaves, no helmet, bald",
 "mage": "human mage wearing a long deep purple robe with gold trim and a hood down, bald",
 "ranger": "human ranger wearing brown leather armor, bracers, and a short green hooded cloak, hood down, bald",
}
jobs = []
for k, (b, d) in races.items():
    for dn in (0.6, 0.72):
        jobs.append({"name": f"r2_{k}_d{int(dn*100)}", "seeds": [51, 52, 53], "init": f"C:/ai/art_work/base_{b}.png", "denoise": dn, "prompt": T.format(d=d)})
for k, d in outfits.items():
    for dn in (0.55, 0.68):
        for b in ("tall", "short"):
            if b == "short" and dn == 0.55:
                continue
            jobs.append({"name": f"o2_{k}_{b}_d{int(dn*100)}", "seeds": [51, 52, 53], "init": f"C:/ai/art_work/base_{b}.png", "denoise": dn, "prompt": T.format(d=d)})
json.dump(jobs, open(r"C:\ai\art_work\jobs_r2.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in jobs))
