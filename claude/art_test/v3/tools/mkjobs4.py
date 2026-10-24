import json
NEGB = "3d render, realistic, photo, blurry, text, watermark, signature, multiple characters, cropped, frame, border, scenery, gradient background, front view, looking at viewer, bright saturated colors"
NEGF = NEGB.replace("front view, looking at viewer, ", "back view, ")
D = {"human": "human adventurer with short dark brown hair in a dark blue tunic",
     "elf": "slender elf with very long pointed ears and long ash-blond hair in a dark blue tunic",
     "orc": "tall bulky grey-green orc with a black topknot and tusks in a dark blue tunic",
     "dwarf": "short very wide dwarf with a heavy iron helmet and a huge braided red beard in a dark blue tunic",
     "goblin": "small hunched green goblin with huge pointed ears and a long nose in a ragged brown tunic"}
B = "tiny pixel art battle sprite, chibi {d}, seen from behind, three-quarter rear view turned up and to the right, right fist raised, full body, dark fantasy, muted desaturated colors, clean dark outline, simple shading, plain white background, {n}x{n} sprite"
F = "tiny pixel art character sprite, chibi {d}, facing the viewer, simple face, full body, dark fantasy, muted desaturated colors, clean dark outline, simple shading, plain white background, {n}x{n} sprite"
J = []
for r, d in D.items():
    for v, T, neg in (("back", B, NEGB), ("front", F, NEGF)):
        for n in (32, 48):
            J.append({"name": f"v4_{r}_{v}_{n}", "seeds": [851, 852], "init": f"C:/ai/art_work3/g4_{r}_{v}_{n}_1024.png", "denoise": 0.5,
                      "style": "C:/gamedev/solaria_wt_newart/art/enemies/draugr.png", "style_weight": 0.3, "neg": neg, "prompt": T.format(d=d, n=n)})
json.dump(J, open("jobs4.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in J))
