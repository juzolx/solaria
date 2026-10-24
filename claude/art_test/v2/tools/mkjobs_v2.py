import json
NEG = "3d render, realistic, photo, blurry, text, watermark, signature, multiple characters, cropped, frame, border, scenery, gradient background, front view, looking at viewer, bright saturated colors"
NEGF = NEG.replace("front view, looking at viewer, ", "back view, ")
BACK = "tiny pixel art battle sprite, chibi {d}, seen from behind, three-quarter rear view turned up and to the right, side of the face and ear visible, right fist raised, full body, dark fantasy, muted cold desaturated colors, thick dark outline, plain white background, 32x32 sprite, cute chunky silhouette"
FRONT = "tiny pixel art character portrait sprite, chibi {d}, facing the viewer, big expressive eyes, full body, dark fantasy, muted cold desaturated colors, thick dark outline, plain white background, 32x32 sprite, cute chunky silhouette"
REF = "C:/gamedev/solaria_wt_newart/art/enemies/draugr.png"
LIN = "in a dark worn linen shirt and trousers"
races = {"human": ("tall", "bald human fighter with pale skin " + LIN),
         "elf": ("tall", "elf with long pointed ears and long ash-blond hair, pale skin, " + LIN),
         "orc": ("tall", "grey-green skinned orc with small tusks and a black topknot, " + LIN),
         "dwarf": ("short", "stocky dwarf with a big braided rust-red beard, " + LIN),
         "goblin": ("short", "small olive-green goblin with huge pointed ears, bald, sly grin, " + LIN)}
outfits = {"warrior": "human knight in dark battered steel plate armor with pauldrons, no helmet, bald",
           "mage": "human mage in a long dark violet robe with tarnished gold trim, hood down, bald",
           "ranger": "human ranger in dark brown leather armor and a short moss-green hooded cloak, hood down, bald"}
mq = {"tall": "C:/ai/art_work2/mq_back.png", "short": "C:/ai/art_work2/mq_back_short.png"}
mqf = {"tall": "C:/ai/art_work2/mq_front.png", "short": "C:/ai/art_work2/mq_front_short.png"}
J = []
def job(name, init, d, prompt, seeds=(731, 732), dn=0.5, sw=0.3, neg=NEG):
    J.append({"name": name, "seeds": list(seeds), "init": init, "denoise": dn, "style": REF, "style_weight": sw, "neg": neg, "prompt": prompt.format(d=d)})
for r, (b, d) in races.items():
    job(f"v2r_{r}", mq[b], d, BACK, seeds=(731, 732, 733))
for o, d in outfits.items():
    for b in ("tall", "short"):
        job(f"v2o_{o}_{b}", mq[b], d, BACK, dn=0.55)
# look variants on human warrior: A = above; B = slimmer mannequin; C = darker armour, stronger style
job("v2var_B", "C:/ai/art_work2/mq_back_slim.png", outfits["warrior"], BACK, seeds=(731, 732, 733), dn=0.55)
job("v2var_C", mq["tall"], "human knight in blackened iron plate armor with a torn dark cloak, no helmet, bald, grim", BACK, seeds=(731, 732, 733), dn=0.55, sw=0.6)
for r, (b, d) in races.items():
    job(f"v2f_{r}", mqf[b], d, FRONT, dn=0.55, neg=NEGF)
json.dump(J, open("jobs_v2.json", "w"), indent=1)
print(sum(len(j["seeds"]) for j in J))
