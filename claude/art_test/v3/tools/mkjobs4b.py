import json
NEGB = "3d render, realistic, photo, blurry, text, watermark, signature, multiple characters, cropped, frame, border, scenery, gradient background, front view, looking at viewer, bright saturated colors"
NEGF = NEGB.replace("front view, looking at viewer, ", "back view, ")
O = {"cloth": "human mage with short dark brown hair in a long plain dark grey cloth robe with a rope belt",
     "leather": "human ranger with short dark brown hair in brown leather armor with straps, bracers and a short hooded cloak, hood down",
     "plate": "human knight with short dark brown hair in slim dark steel plate armor with pauldrons, no helmet"}
B = "tiny pixel art battle sprite, chibi {d}, seen from behind, three-quarter rear view turned up and to the right, right fist raised, full body, dark fantasy, muted desaturated colors, clean dark outline, simple shading, plain white background, 32x32 sprite"
F = "tiny pixel art character sprite, chibi {d}, facing the viewer, simple face, full body, dark fantasy, muted desaturated colors, clean dark outline, simple shading, plain white background, 32x32 sprite"
J = []
for o, d in O.items():
    for v, T, neg in (("back", B, NEGB), ("front", F, NEGF)):
        J.append({"name": f"v4g_{o}_{v}", "seeds": [861, 862], "init": f"C:/ai/art_work3/g4_human_{v}_32_1024.png", "denoise": 0.55,
                  "style": "C:/gamedev/solaria_wt_newart/art/enemies/draugr.png", "style_weight": 0.3, "neg": neg, "prompt": T.format(d=d)})
json.dump(J, open("jobs4b.json", "w"), indent=1)
