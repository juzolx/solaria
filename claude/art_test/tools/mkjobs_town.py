import json
NEG = "3d render, realistic, photo, blurry, text, watermark, signature, frame, border, landscape, gradient background, close-up, cropped, people, characters, isometric grid"
T = "pixel art, top-down three-quarter view rpg game building sprite, {d}, dark fantasy village at dusk, warm glowing windows, single building isolated on a plain white background, whole building visible, crisp pixels, dark outline"
B = {
 "gate": "a dungeon cave entrance with a heavy iron-bound wooden gate set into a rocky cliff wall, two torches",
 "guild": "a large stone guild hall with a dark red tiled roof and hanging banners",
 "inn": "a two-story half-timbered inn with a slate blue roof, chimney, hanging inn sign",
 "shop": "a small general store cottage with a red tiled roof and a striped awning over the door",
 "smith": "a blacksmith forge workshop with a brick chimney, an anvil and glowing furnace at the open front",
 "tavern": "a wooden tavern with a big carved fortune wheel mounted on its front wall",
 "vault": "a small fortified stone vault bank with an iron door and a gold coin sign",
 "clinic": "a small cottage animal clinic with a green roof and a fenced pen with hay",
 "church": "a small gothic stone chapel with a bell tower, pointed arch door and stained glass window",
 "trophy": "a log cabin trophy hall with antlers and a skull above the door",
 "market": "a market stall with a cream canvas awning and crates of goods",
 "bounty": "a wooden bounty notice board with parchment posters pinned to it",
 "fountain": "a round stone town fountain with water",
}
jobs = [{"name": f"bld_{k}", "seeds": [21, 22, 23, 24], "neg": NEG, "prompt": T.format(d=d)} for k, d in B.items()]
jobs.append({"name": "tree_sheet", "seeds": [21, 22], "neg": NEG,
  "prompt": "pixel art sprite sheet of top-down rpg trees and bushes, dark pine trees, round oak trees, shrubs, dusk lighting, isolated on plain white background, crisp pixels, dark outline"})
jobs.append({"name": "town_full", "seeds": [21, 22, 23], "neg": "3d render, realistic, photo, blurry, text, watermark, signature, frame, border", "w": 832, "h": 1216,
  "prompt": "pixel art, top-down three-quarter view map of a small dark fantasy village at dusk, dirt roads, cobblestone plaza with a fountain, inn, blacksmith, stone church with a graveyard, cave gate in a cliff at the top, pine forest edges, warm torchlight and lit windows, rpg game map"})
json.dump(jobs, open(r"C:\ai\art_work\jobs_town.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in jobs))
