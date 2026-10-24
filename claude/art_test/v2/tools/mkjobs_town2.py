import json
NEG = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, landscape, gradient background, close-up, cropped, people, characters, front elevation, side view"
T = "pixel art, top-down rpg town map sprite seen from above at a steep three-quarter angle, roof clearly visible from above, {d}, dark fantasy medieval village, single object isolated on a plain white background, whole object visible, crisp pixels, dark outline, cozy"
B = {
 "inn": "a large two-story timber-frame inn with a dark slate roof and a hanging sign",
 "smith": "a stone blacksmith forge with a brick chimney and an open workshop with an anvil",
 "tavern": "a timber tavern with a big wooden fortune wheel on its front wall and a red tiled roof",
 "vault": "a small squat fortified stone vault with an iron door and a copper dome roof",
 "guild": "a large stone guild hall with a dark red roof and hanging banners",
 "shop": "a small timber-frame shop with a striped awning over the door and crates outside",
 "clinic": "a small cottage animal clinic with a moss-green thatched roof and a fenced pen",
 "church": "a small gothic stone chapel with a bell tower",
 "trophy": "a log cabin trophy hall with antlers over the door",
 "house1": "a small timber-frame house with a brown thatched roof",
 "house2": "a timber-frame house with a dark blue slate roof and a chimney",
 "house3": "a narrow two-story timber-frame house with an orange tiled roof",
 "stall": "a market stall with a colored striped cloth awning and goods",
 "gate": "a heavy stone castle gatehouse with two round towers, the gate sealed shut with iron bars, chains and rubble",
 "tower": "a round stone castle wall watchtower with a pointed slate roof",
 "dungeon": "a dungeon entrance: stone stairs going down into a glowing archway, surrounded by candles, flowers and a small memorial shrine",
 "well": "a small stone well with a wooden roof",
 "bridge": "a small arched stone bridge",
}
jobs = [{"name": f"t2_{k}", "seeds": [741, 742], "neg": NEG, "prompt": T.format(d=d)} for k, d in B.items()]
PN = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, scenery, gradient background, multiple characters, cropped, human"
PT = "pixel art chibi pet creature sprite, cute {d}, big expressive eyes, chunky readable silhouette, clean dark outline, simple three-tone shading, few colors, dark fantasy, small in the center of a large empty plain white background, full body, 32x32 sprite"
for k, d in {"skullpup": "little puppy with a bone-white skull mask and dark fur", "lanternbat": "round little bat holding a tiny glowing lantern", "mossslime": "moss-green slime blob with a lit candle stuck on its head"}.items():
    jobs.append({"name": f"pet_{k}", "seeds": [751, 752, 753], "neg": PN, "prompt": PT.format(d=d)})
json.dump(jobs, open("jobs_town2.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in jobs))
