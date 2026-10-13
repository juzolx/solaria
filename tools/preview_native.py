"""Preview sheet of the native hero art in real colors (not key colors)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
import art_native as an
import art_hero_native as hn
import pixelshade as ps

SKIN = ['#fbe6cf', '#f2cfae', '#e8b796', '#c28569', '#733e39']
HAIRC = ['#ffe0a8', '#f5b363', '#d98a3f', '#a95d30', '#73372b']
EYE = '#3a6fd8'
STEEL = ['#ffffff', '#c0cbdc', '#8b9bb4', '#5a6988', '#3a4466']
LEATHER = ['#e4a672', '#c28569', '#a8624a', '#733e39', '#3e2731']
CLOTH = ['#7fb2e0', '#4f8fba', '#3c5e8b', '#253a5e', '#172038']
TRIM = ['#ffe9a8', '#fde36a', '#f5b03a', '#c26c22', '#7a3a14']
RED = ['#ff8f80', '#e04a48', '#b02e40', '#781f36', '#41102a']

def body_ramps():
    return {"s": SKIN, "c": hn.SHIRT, "p": hn.PANTS, "l": hn.SHOES, "k": hn.BELT, "g": TRIM, "e": EYE, "x": hn.DARK, "w": hn.WHITE,
            "q": hn.LIPS, "h": HAIRC, "y": "#ffffff"}

def render_body(kind):
    c = hn.body(kind)
    return c.render(body_ramps(), tone_fn=hn.clean_head, shadow_under=("c", "p", "l"))

def render_hair(style):
    f, b = hn.hair_layers(style)
    r = {"h": HAIRC, "t": '#c23b2e'}
    return (f.render(r, soft=1.2) if f else None), (b.render(r, soft=1.2) if b else None)

def compose(kind, style, gear=()):
    out = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    f, b = render_hair(style)
    if b:
        an.stack(out, b)
    for g, mat in gear:
        if g == "cape":
            an.stack(out, hn.cape().render({"m": RED, "r": TRIM}))
    an.stack(out, render_body(kind))
    for g, mat in gear:
        if g in ("tunic", "plate", "robe", "pants", "greaves", "leggings", "boots", "sandals", "sabatons"):
            an.stack(out, hn.armor(kind, g).render({"m": mat, "r": TRIM, "k": hn.BELT}))
    helm = [g for g, m in gear if g in ("cap", "helm", "hood", "crown")]
    if f and not (helm and helm[0] in ("helm", "hood")):
        an.stack(out, f)
    for g, mat in gear:
        if g in ("cap", "helm", "hood", "crown"):
            an.stack(out, hn.helmet(g).render({"m": mat, "r": TRIM}))
    return out

if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else "hair"
    S = 5
    items = []
    if which == "hair":
        for i, st in enumerate(hn.HAIR_ORDER):
            items.append((st, compose("masc" if i < 7 else "fem", st)))
    else:
        sets = [("Plain", []), ("Knight", [("plate", STEEL), ("greaves", STEEL), ("sabatons", STEEL), ("helm", STEEL)]),
                ("Ranger", [("tunic", LEATHER), ("leggings", LEATHER), ("boots", LEATHER), ("hood", CLOTH)]),
                ("Mage", [("robe", CLOTH), ("sandals", LEATHER), ("hood", CLOTH)]),
                ("Unique", [("cape", RED), ("plate", STEEL), ("pants", CLOTH), ("boots", LEATHER), ("crown", TRIM)]),
                ("Rogue", [("tunic", CLOTH), ("pants", LEATHER), ("boots", LEATHER), ("cap", LEATHER)])]
        for kind in ("masc", "fem"):
            for n, g in sets:
                items.append(("%s %s" % (kind, n), compose(kind, "Short" if kind == "masc" else "Long", g)))
    cols = 7 if which == "hair" else 6
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (64 * S + 12) + 12, rows * (64 * S + 30) + 12), (15, 23, 42, 255))
    d = ImageDraw.Draw(sheet)
    for i, (n, im) in enumerate(items):
        x = 12 + (i % cols) * (64 * S + 12)
        y = 24 + (i // cols) * (64 * S + 30)
        big = im.resize((64 * S, 64 * S), Image.NEAREST)
        sheet.paste(big, (x, y), big)
        d.text((x, y - 14), n, fill=(232, 177, 74, 255))
    sheet.save("/root/shots/native_%s.png" % which)
    print("ok")

def race_preview():
    import art_races
    S = 5
    races = list(art_races.RACES.items())
    skins = {"Human": SKIN, "Elf": SKIN, "Fairy": SKIN, "Angel": SKIN, "Demon": ['#f8b09a', '#e4705a', '#c84a44', '#8e2e38', '#4e1a26'],
             "Dwarf": SKIN, "Beastkin": ['#f2c49a', '#e4a672', '#c98a5c', '#9c6244', '#5a3434'], "Dragonkin": SKIN,
             "Undead": ['#d0dcc8', '#a8b89a', '#7f9478', '#566a56', '#2e3a34'], "Orc": ['#d4ecaa', '#a8ca58', '#75a743', '#468232', '#25562e'],
             "Goblin": ['#d4ecaa', '#a8ca58', '#75a743', '#468232', '#25562e'], "Golem": ['#d8dce4', '#aab2c0', '#7d8798', '#545d70', '#2e3444']}
    items = []
    for name, (back, front) in races:
        sk = skins[name]
        out = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        for k in back:
            cv, R = hn.race_layer(k)
            R.update({"s": sk, "h": HAIRC})
            an.stack(out, cv.render({k2: v for k2, v in R.items() if v is not None}))
        bc = hn.body("masc")
        r = body_ramps()
        r["s"] = sk
        an.stack(out, bc.render(r, tone_fn=hn.clean_head, shadow_under=("c", "p", "l")))
        f, _ = hn.hair_layers("Short")
        an.stack(out, f.render({"h": HAIRC, "t": "#c23b2e"}, soft=1.2))
        for k in front:
            cv, R = hn.race_layer(k)
            R.update({"s": sk, "h": HAIRC})
            an.stack(out, cv.render({k2: v for k2, v in R.items() if v is not None}))
        items.append((name, out))
    for extra in [["wings2", "wings3", "wings_angel"], ["fallen_wings", "broken_halo"], ["wolf_tail", "wolf_ears"], ["lich_crown"], ["horns_big", "tail"], ["wings_big", "ears"], ["dragon_wings", "dragon_tail", "dragon_horns"], ["crown", "fangs"]]:
        out = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        backs = [k for k in extra if k in art_races.BACK]
        fronts = [k for k in extra if k not in art_races.BACK]
        for k in backs:
            cv, R = hn.race_layer(k)
            an.stack(out, cv.render({k2: v for k2, v in R.items() if v is not None} | {"s": SKIN, "h": HAIRC}))
        an.stack(out, hn.body("masc").render(body_ramps(), tone_fn=hn.clean_head, shadow_under=("c", "p", "l")))
        f, _ = hn.hair_layers("Short")
        an.stack(out, f.render({"h": HAIRC, "t": "#c23b2e"}, soft=1.2))
        for k in fronts:
            cv, R = hn.race_layer(k)
            an.stack(out, cv.render({k2: v for k2, v in R.items() if v is not None} | {"s": SKIN, "h": HAIRC}))
        items.append(("+".join(extra), out))
    cols = 7
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (64 * S + 12) + 12, rows * (64 * S + 30) + 12), (15, 23, 42, 255))
    d = ImageDraw.Draw(sheet)
    for i, (n, im) in enumerate(items):
        x = 12 + (i % cols) * (64 * S + 12)
        y = 24 + (i // cols) * (64 * S + 30)
        big = im.resize((64 * S, 64 * S), Image.NEAREST)
        sheet.paste(big, (x, y), big)
        d.text((x, y - 14), n, fill=(232, 177, 74, 255))
    sheet.save("/root/shots/native_races.png")
    print("ok races")

if __name__ == "__main__" and len(sys.argv) > 1 and sys.argv[1] == "races":
    race_preview()
