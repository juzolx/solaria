import json
NEG = "3d render, realistic, photo, blurry, text, watermark, signature, multiple characters, cropped, frame, border, scenery, gradient background, front view, looking at viewer, bright saturated colors, bald"
T = "tiny pixel art battle sprite, chibi {d} in slim dark battered steel plate armor, seen from behind, three-quarter rear view turned up and to the right, side of the face visible, right fist raised, full body, dark fantasy, muted cold desaturated colors, thick dark outline, plain white background, 32x32 sprite, cute chunky silhouette"
R = {"human": "human with short dark brown hair", "elf": "elf with long ash-blond hair and a long pointed ear",
     "orc": "grey-green orc with a black topknot and a small tusk", "dwarf": "stocky dwarf with an iron cap and a big braided rust-red beard",
     "goblin": "small olive-green goblin with huge pointed ears sticking out sideways"}
J = [{"name": f"v3_{k}", "seeds": [811, 812, 813], "init": f"C:/ai/art_work3/g_{k}_1024.png", "denoise": 0.5,
      "style": "C:/gamedev/solaria_wt_newart/art/enemies/draugr.png", "style_weight": 0.35, "neg": NEG, "prompt": T.format(d=d)} for k, d in R.items()]
J.append({"name": "v3f_human", "seeds": [811, 812], "init": "C:/ai/art_work2/mq_front.png", "denoise": 0.6,
          "style": "C:/gamedev/solaria_wt_newart/art/enemies/draugr.png", "style_weight": 0.3,
          "neg": NEG.replace("front view, looking at viewer, ", "back view, "),
          "prompt": "tiny pixel art character portrait sprite, chibi human with short dark brown hair and pale skin, in slim dark steel plate armor, facing the viewer, big expressive eyes, full body, dark fantasy, muted cold desaturated colors, thick dark outline, plain white background, 32x32 sprite"})
json.dump(J, open("jobs_h3.json", "w"), indent=1)
