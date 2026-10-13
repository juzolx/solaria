class_name Lpc
extends RefCounted
## Hero art built from the LPC (Liberated Pixel Cup) character parts in art/lpc/
## (made by tools/lpc_extract.py, credits in art/lpc/CREDITS.md).
##
## A hero is a list of parts (body, head, face, hair, clothes, armor, weapon...),
## each with a color ramp. Parts are stacked by their z order and recolored from
## the part's base palette to the game's own skin, hair and material ramps, then
## cut into animation frames. Only the right-facing row is kept: the hero
## always faces the monster.

const DIR := "res://art/lpc/"
const CORE := 64  # the character's own frame; bigger frames (weapon swings) are centered on it
const FPS := {"idle": 2.0, "combat_idle": 2.0, "walk": 10.0, "slash": 14.0, "thrust": 14.0, "spellcast": 12.0, "shoot": 18.0}
const BUILD := ["combat_idle", "slash", "thrust", "spellcast", "shoot"]
const OUTLINE := Color("#1c1526")

static var _manifest := {}
static var _palettes := {}
static var _imgs := {}     # file -> Image
static var _recolored := {}  # file|ramp -> Image
static var _built := {}    # spec key -> result

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		# Loaded as resources (not FileAccess) so exported games include them
		var m := load(DIR + "manifest.json") as JSON
		if m:
			_manifest = m.data
		var p := load(DIR + "palettes.json") as JSON
		if p:
			_palettes = p.data
	return _manifest

static func available() -> bool:
	return not manifest().is_empty()

static func has_item(id: String) -> bool:
	return manifest().get("items", {}).has(id)

## The colors a part was drawn in, darkest first: the palette the extractor found
## in that sheet ("src"), or the material's base palette.
static func base_ramp(material: String, src := "") -> Array:
	manifest()
	if not _palettes.has(material):
		return []
	var p: Dictionary = _palettes[material]
	var name: String = src if src != "" and p["palettes"].has(src) else p["base"]
	var out := []
	for h in p["palettes"].get(name, []):
		out.append(Color(h))
	return out

## Color swaps for one sheet: its material's colors to the part's ramp, plus eyes.
static func _maps(info: Dictionary, src: String) -> Array:
	var maps: Array = []
	var ramp: Array = info.get("ramp", [])
	if not ramp.is_empty() and String(info.get("mat", "")) != "":
		maps.append([base_ramp(info["mat"], src), ramp])
	var eyes: Array = info.get("eyes", [])
	if not eyes.is_empty():
		maps.append([base_ramp("eye"), eyes])
	return maps

## Turns one of the game's 5-color ramps (light to dark) into LPC's 6 (outline, dark to light).
static func ramp6(r5: Array) -> Array:
	var r: Array = []
	for c in r5:
		r.append(c if c is Color else Color(c))
	if r.size() < 5:
		return []
	var outline: Color = (r[4] as Color).darkened(0.45).lerp(OUTLINE, 0.5)
	return [outline, r[4], r[3], r[2], r[1], r[0]]

static func eye_ramp(c: Color) -> Array:
	return [c.darkened(0.55), c, c.lightened(0.45)]

static func _img(file: String) -> Image:
	if not _imgs.has(file):
		var tex := load(DIR + file) as Texture2D
		var im: Image = tex.get_image() if tex else null
		if im and im.get_format() != Image.FORMAT_RGBA8:
			im.convert(Image.FORMAT_RGBA8)
		_imgs[file] = im
	return _imgs[file]

## Recolors one strip from its base palette to the target ramp (nearest base color
## within a small distance; anything else, like a sword's wood grip, stays as drawn).
static func _recolor(file: String, maps: Array) -> Image:
	var key := file + str(maps)
	if _recolored.has(key):
		return _recolored[key]
	var src := _img(file)
	if src == null:
		return null
	if maps.is_empty():
		_recolored[key] = src
		return src
	var out := src.duplicate() as Image
	var data := out.get_data()
	var lookup := {}
	for i in range(0, data.size(), 4):
		if data[i + 3] == 0:
			continue
		var k := (data[i] << 16) | (data[i + 1] << 8) | data[i + 2]
		if not lookup.has(k):
			lookup[k] = _match(k, maps)
		var m: int = lookup[k]
		if m >= 0:
			data[i] = (m >> 16) & 255
			data[i + 1] = (m >> 8) & 255
			data[i + 2] = m & 255
	out.set_data(out.get_width(), out.get_height(), false, Image.FORMAT_RGBA8, data)
	_recolored[key] = out
	return out

static func _match(k: int, maps: Array) -> int:
	var r := (k >> 16) & 255
	var g := (k >> 8) & 255
	var b := k & 255
	var best := 40
	var hit := -1
	for mp in maps:
		var base: Array = mp[0]
		var target: Array = mp[1]
		for i in mini(base.size(), target.size()):
			var c: Color = base[i]
			var d := absi(r - c.r8) + absi(g - c.g8) + absi(b - c.b8)
			if d < best:
				best = d
				var t: Color = target[i]
				hit = (t.r8 << 16) | (t.g8 << 8) | t.b8
	return hit

## spec = {"body": "male"/"female"/"muscular", "parts": [{"id", "ramp": [6 colors] or [], "eyes": [3 colors]}]}
## Returns {"anims": {name: {"tex": [ImageTexture], "white": [ImageTexture], "size": px, "fps": n}}, "still": Image (64x64)}
static func build(spec: Dictionary) -> Dictionary:
	var key := str(spec)
	var flip: bool = spec.get("flip", false)
	if _built.has(key):
		return _built[key]
	var layers := _layers(spec)
	var out := {"anims": {}}
	for anim in BUILD:
		var a := _compose(layers, anim, flip)
		if not a.is_empty():
			out["anims"][anim] = a
	if not out["anims"].has("combat_idle"):
		out["anims"]["combat_idle"] = _compose(layers, "walk", flip)
	var idle: Dictionary = out["anims"]["combat_idle"]
	out["still"] = (idle["img"][0] as Image)
	_built[key] = out
	return out

## Walking and standing frames for a townsperson (right-facing): {"walk": {...}, "idle": {...}}.
static func build_walker(spec: Dictionary) -> Dictionary:
	var layers := _layers(spec)
	return {"walk": _compose(layers, "walk", false), "idle": _compose(layers, "idle", false)}

## The spec's parts as sorted layers: [z, order, files dict, info].
static func _layers(spec: Dictionary) -> Array:
	var items: Dictionary = manifest().get("items", {})
	var body: String = spec.get("body", "male")
	# LPC has few clothes cut for the muscular build: if any part lacks it, the whole
	# figure uses the regular male build so everything fits together.
	if body == "muscular":
		for part in spec.get("parts", []):
			var it: Dictionary = items.get(part["id"], {})
			for L in it.get("layers", []):
				var fl: Dictionary = L["files"]
				if fl.has("male") and not fl.has("muscular"):
					body = "male"
	var layers: Array = []
	var order := 0
	for part in spec.get("parts", []):
		var it: Dictionary = items.get(part["id"], {})
		if it.is_empty():
			continue
		var info := {"mat": it.get("material", ""), "ramp": part.get("ramp", []),
			"eyes": part.get("eyes", []) if it.get("eye", false) else [], "dy": int(part.get("dy", 0))}
		for L in it["layers"]:
			var files: Dictionary = L["files"]
			var f: Dictionary = files.get(body, files.get("male", files.get("female", {})))
			if f.is_empty():
				continue
			layers.append([int(L["z"]), order, f, info])
			order += 1
	layers.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	return layers

## One animation: every layer's strip for it (or its standing frame when a part
## has no such animation), stacked frame by frame.
static func _compose(layers: Array, anim: String, flip := false) -> Dictionary:
	var size := CORE
	var frames := 0
	var parts: Array = []  # [image, frame size, own frames, animated]
	for L in layers:
		var files: Dictionary = L[2]
		var f: Dictionary = files.get(anim, {})
		var animated := not f.is_empty()
		if not animated:
			f = files.get("combat_idle", files.get("idle", files.get("walk", {})))
		if f.is_empty():
			continue
		var im := _recolor(f["file"], _maps(L[3], f.get("src", "")))
		if im == null:
			continue
		var fs := int(f["size"])
		var n := maxi(1, im.get_width() / fs)
		parts.append([im, fs, n, animated, int(L[3].get("dy", 0))])
		size = maxi(size, fs)
		if animated and fs == CORE:
			frames = maxi(frames, n)
	if frames == 0:
		for p in parts:
			if p[3]:
				frames = maxi(frames, int(p[2]))
	if frames == 0 or parts.is_empty():
		return {}
	var imgs: Array = []
	var tex: Array = []
	var white: Array = []
	for i in frames:
		var canvas := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for p in parts:
			var im: Image = p[0]
			var fs: int = p[1]
			var fi: int = mini(i, int(p[2]) - 1) if p[3] else 0
			var at := Vector2i((size - fs) / 2, (size - fs) / 2 + int(p[4]))
			canvas.blend_rect(im, Rect2i(fi * fs, 0, fs, fs), at)
		if flip:
			canvas.flip_x()
		imgs.append(canvas)
		tex.append(ImageTexture.create_from_image(canvas))
		white.append(ImageTexture.create_from_image(_silhouette(canvas)))
	return {"img": imgs, "tex": tex, "white": white, "size": size, "fps": FPS.get(anim, 10.0)}

static func _silhouette(src: Image) -> Image:
	var out := src.duplicate() as Image
	var data := out.get_data()
	for i in range(0, data.size(), 4):
		if data[i + 3] > 0:
			data[i] = 255
			data[i + 1] = 255
			data[i + 2] = 255
			data[i + 3] = 255
	out.set_data(out.get_width(), out.get_height(), false, Image.FORMAT_RGBA8, data)
	return out

# =====================================================================
# The game's hero -> LPC parts
# =====================================================================

## The game's hair styles (old names first, so old saves keep their look).
const HAIR := {
	"Short": "plain", "Spiky": "spiked", "Side Swept": "swoop", "Shaggy": "messy1", "Mohawk": "longhawk",
	"Buzz": "buzzcut", "Bald": "", "Long": "long", "Ponytail": "ponytail", "Bob": "bob", "Bun": "bunches",
	"Braid": "braid", "Pixie": "pixie",
	"Afro": "afro", "Bangs": "bangs", "Long Bangs": "bangslong", "Bedhead": "bedhead", "Cornrows": "cornrows",
	"Curly": "curly_short", "Long Curls": "curly_long", "Dreadlocks": "dreadlocks_long", "Half Up": "half_up",
	"High Ponytail": "high_ponytail", "Wild": "long_messy", "Loose": "loose", "Mop": "mop", "Princess": "princess",
	"Short Mohawk": "shorthawk", "Porcupine": "spiked_porcupine", "Unkempt": "unkempt", "Very Long": "xlong",
	"Balding": "balding", "Wavy": "wavy", "Page": "page", "Parted": "parted", "Tied Back": "long_tied",
	"Pigtails": "pigtails",
}
const HAIR_ORDER := ["Short", "Spiky", "Side Swept", "Shaggy", "Mohawk", "Short Mohawk", "Buzz", "Bald", "Balding",
	"Bedhead", "Unkempt", "Porcupine", "Mop", "Parted", "Page", "Bangs", "Long Bangs", "Long", "Very Long", "Wild",
	"Loose", "Wavy", "Tied Back", "Ponytail", "High Ponytail", "Half Up", "Pigtails", "Bun", "Braid", "Bob", "Pixie",
	"Princess", "Curly", "Long Curls", "Afro", "Cornrows", "Dreadlocks"]

## Race -> head parts: [masc head, fem head, extra parts, has a human face].
const RACES := {
	"Human": ["human_m", "human_f", [], true],
	"Elf": ["human_m", "human_f", ["ears_elven"], true],
	"Fairy": ["human_m", "human_f", ["ears_long", "wings_monarch:hair"], true],
	"Angel": ["human_m", "human_f", ["wings_feather:angel"], true],
	"Demon": ["human_m", "human_f", ["horns_curled:horn", "tail_lizard"], true],
	"Dwarf": ["human_m", "human_f", ["beard_winter:hair"], true],
	"Beastkin": ["wolf_m", "wolf_f", ["tail_wolf:hair"], false],
	"Dragonkin": ["lizard_m", "lizard_f", ["tail_lizard"], false],
	"Undead": ["zombie", "zombie", [], false],
	"Orc": ["orc_m", "orc_f", [], false],
	"Goblin": ["goblin", "goblin", [], false],
	"Golem": ["troll", "troll", [], false],
}
## Transformations (forms) and awakening looks change the parts.
const FORMS := {
	"Vampire": {"head": "vampire", "add": []},
	"Werewolf": {"head_m": "wolf_m", "head_f": "wolf_f", "add": ["tail_wolf:hair"], "face": false},
	"Fallen Angel": {"remove": ["wings_feather:angel"], "add": ["wings_bat:dark"]},
	"Lich": {"head": "skeleton", "add": ["crown:gold"], "face": false},
}
const LOOKS := {
	"wings2": ["wings_feather:angel"], "wings3": ["wings_feather:angel"], "horns_big": ["horns_back:horn"],
	"crown": ["crown:gold"], "dragon_wings": ["wings_lizard"], "wings_big": ["wings_monarch:hair"],
}
## Game gear type -> LPC parts. ":mat" recolors with the item's material, ":dark"/":linen" with a fixed one.
const GEAR := {
	"sword": ["w_sword:mat"], "dagger": ["w_dagger"], "axe": ["w_axe"], "mace": ["w_mace"], "spear": ["w_spear:mat"],
	"bow": ["w_bow"], "staff": ["w_staff"],
	"buckler": ["sh_heater"], "shield": ["sh_heater", "sh_heater_trim:mat"], "tower": ["sh_scutum"], "orb": [], "tome": [],
	"cap": ["cap_leather:mat"], "helm": ["helm_bascinet:mat"], "hood": ["hood:mat"], "crown": ["crown:mat"],
	"tunic": ["shirt_long:linen", "armor_leather"], "plate": ["shirt_long:dark", "armor_plate:mat", "arms_plate:mat", "shoulders_legion:mat"],
	"robe": ["robe"],
	"pants": ["legs_pants:mat"], "leggings": ["legs_leggings:mat"], "greaves": ["legs_plate:mat"],
	"boots": ["feet_boots:mat"], "sandals": ["feet_sandals:mat"], "sabatons": ["feet_plate:mat"],
}
const HIDES_HAIR := ["helm", "hood"]
## Hair is drawn for the human skull; these heads sit lower, so their hair moves down to meet them.
const HAIR_DY := {"orc_m": 3, "troll": 2, "wolf_m": 3, "wolf_f": 3}
## Dragonkin grow crests and horns instead of hair (their "hair" choice picks one).
const CRESTS := {"Frills": ["ears_dragon:hair"], "Back Horns": ["horns_back:hair"], "Curled Horns": ["horns_curled:hair"],
	"Frills and Horns": ["ears_dragon:hair", "horns_back:hair"], "Smooth": []}
const CREST_ORDER := ["Frills", "Back Horns", "Curled Horns", "Frills and Horns", "Smooth"]
## Golems are living stone: only short, cropped or tied styles read well on the troll skull.
const GOLEM_HAIR := ["Bald", "Mohawk", "Short Mohawk", "Spiky", "Porcupine", "Back Horns", "Curled Horns"]

## The hair choices a race offers in the hero creator.
static func hair_styles(race: String) -> Array:
	match race:
		"Dragonkin":
			return CREST_ORDER
		"Golem":
			return GOLEM_HAIR
	return HAIR_ORDER

## A Dragonkin crest from a hair choice (older heroes picked human hair: map it onto a crest).
static func crest(name: String) -> Array:
	if CRESTS.has(name):
		return CRESTS[name]
	return CRESTS[CREST_ORDER[maxi(0, HAIR_ORDER.find(name)) % CREST_ORDER.size()]]
const FIXED := {
	"linen": ["#f4e6c4", "#ead4aa", "#d0b48a", "#a3825f", "#5a3f35"],
	"dark": ["#5a6988", "#3a4466", "#262b44", "#181425", "#0e0b16"],
	"angel": ["#ffffff", "#f4f4f8", "#e2e2ec", "#bdbdd2", "#8a8aa8"],
	"fairy": ["#ffe0f4", "#f8b8e4", "#e88ad0", "#b85aa8", "#6a2a6a"],
	"horn": ["#e8dccc", "#bba98e", "#8a7560", "#5a4a3e", "#2e2420"],
	"gold": ["#fff4a3", "#fee761", "#feae34", "#f77622", "#be4a2f"],
	"zombie": ["#c8d8b0", "#9cb48a", "#6e8a62", "#4a5e44", "#2a3428"],
	"bone": ["#fbf3dc", "#ead4aa", "#c8b08a", "#9a8064", "#5a4a3e"],
	"pale": ["#ffffff", "#eef0f4", "#d2d4de", "#a8a8ba", "#5e5a72"],
	"demon": ["#f8b09a", "#e4705a", "#c84a44", "#8e2e38", "#4e1a26"],
	"fur_brown": ["#c8a070", "#9a7048", "#6e4a30", "#4a2e20", "#2a1a14"],
	"fur_black": ["#6a6476", "#4a4456", "#302c3a", "#1e1a26", "#0e0b14"],
	"rust": ["#c88a5a", "#9a5a3a", "#6e3a2a", "#4a2420", "#2a1416"],
	"obsidian": ["#5a5468", "#3a3448", "#241f30", "#16121e", "#0b0910"],
	"scale": ["#b8e0a0", "#7cb868", "#4e8a48", "#2e5a34", "#183420"],
	"purple": ["#c8a0e8", "#9a6ad0", "#6a40a8", "#46287a", "#28164a"],
	"red": ["#f0a090", "#d05a50", "#a03040", "#6a1c30", "#3a0e1c"],
	"stone": ["#d8dce4", "#aab2c0", "#7d8798", "#545d70", "#2e3444"],
	"moss": ["#c8d090", "#98a860", "#6a7c40", "#46542c", "#262e1a"],
	"ash": ["#a8a4b0", "#7c7888", "#56525e", "#38343e", "#1c1a20"],
	"steel": ["#ffffff", "#c0cbdc", "#8b9bb4", "#5a6988", "#3a4466"],
	"iron": ["#c0cbdc", "#8b9bb4", "#5a6988", "#3a4466", "#262b44"],
	"leather": ["#e4a672", "#c28569", "#a8624a", "#733e39", "#3e2731"],
	"black": ["#4a4456", "#302c3a", "#1e1a26", "#120f18", "#08060c"],
	"blood": ["#e05050", "#b02a3a", "#7a1a2e", "#4a0e1e", "#260810"],
	"wine": ["#c86a8a", "#9a3e64", "#6e2448", "#46142e", "#24081a"],
	"teal": ["#a4dddb", "#4fb0c6", "#2e7896", "#1d4a66", "#0e2638"],
	"hag": ["#a8d0e0", "#78a0c0", "#4e7090", "#304868", "#1a283e"],
	"ember": ["#fee761", "#feae34", "#f77622", "#be4a2f", "#733e39"],
	"silver": ["#ffffff", "#e2e6ee", "#b4bccb", "#7d8798", "#4a5266"],
	"green_royal": ["#8fd17a", "#56a05a", "#357048", "#224a36", "#122a1e"],
	"fairy_skin": ["#fff0f6", "#fcd0e4", "#f0a8c8", "#c47a9e", "#7a4662"],
	"ghost": ["#e8f4ff", "#c0d8ee", "#8fb0d2", "#5f7ea8", "#34466e"],
}

## The parts for a hero. app = appearance, looks = slot -> Sprites.gear_look().
static func spec(app: Dictionary, looks: Dictionary) -> Dictionary:
	var race: String = app.get("race", "Human")
	var fem: bool = app.get("body", "masc") == "fem"
	var a: Dictionary = Sprites.race_look(app)["app"]
	var skins := Sprites.skins()
	var hairs := Sprites.hair_colors()
	var skin := ramp6(skins[clampi(int(a.get("skin", 1)), 0, skins.size() - 1)])
	var hair := ramp6(hairs[clampi(int(a.get("hair_color", 1)), 0, hairs.size() - 1)])
	var eye_c: Color = Color(a["eye_color"]) if a.has("eye_color") else Color(Sprites.eye_colors()[clampi(int(a.get("eyes", 0)), 0, Sprites.eye_colors().size() - 1)])
	var eyes := eye_ramp(eye_c)
	var r: Array = RACES.get(race, RACES["Human"])
	var head: String = r[1] if fem else r[0]
	var face: bool = r[3]
	var extras: Array = (r[2] as Array).duplicate()
	var form: String = app.get("form", "")
	if FORMS.has(form):
		var fd: Dictionary = FORMS[form]
		if fd.has("head"):
			head = fd["head"]
		if fd.has("head_m"):
			head = fd["head_f"] if fem else fd["head_m"]
		if fd.has("face"):
			face = fd["face"]
		for x in fd.get("remove", []):
			extras.erase(x)
		for x in fd.get("add", []):
			if not x in extras:
				extras.append(x)
	var look: String = app.get("look", "")
	for x in LOOKS.get(look, []):
		if not x in extras:
			extras.append(x)
	if fem:
		extras.erase("beard_winter:hair")
	var body := "female" if fem else ("muscular" if race in ["Orc", "Golem"] else "male")
	var parts: Array = []
	parts.append({"id": "body", "ramp": skin})
	parts.append({"id": "head_" + head, "ramp": skin, "eyes": eyes})
	if face:
		parts.append({"id": "face_neutral", "ramp": skin, "eyes": eyes})
		parts.append({"id": "brows_thin", "ramp": hair})
	var helmet: Dictionary = looks.get("Helmet", {})
	var hide_hair: bool = not helmet.is_empty() and helmet.get("type", "") in HIDES_HAIR
	var hair_name := str(app.get("hair", "Short"))
	if race == "Dragonkin":
		for x in crest(hair_name):
			if not (hide_hair and x.begins_with("horns")):
				parts.append(_part(x, {}, skin, hair))
	else:
		if race == "Golem" and not hair_name in GOLEM_HAIR:
			hair_name = GOLEM_HAIR[maxi(0, HAIR_ORDER.find(hair_name)) % GOLEM_HAIR.size()]
		if race == "Golem" and CRESTS.has(hair_name):
			if not hide_hair:
				for x in CRESTS[hair_name]:
					parts.append(_part(x.replace(":hair", ":stone"), {}, skin, hair))
			hair_name = "Bald"
		var style: String = HAIR.get(hair_name, "plain")
		if style != "" and not hide_hair:
			parts.append({"id": "hair_" + style, "ramp": hair, "dy": HAIR_DY.get(head, 0)})
	for x in extras:
		parts.append(_part(x, {}, skin, hair))
	# Clothes: an empty slot shows plain clothes
	var chest: Dictionary = looks.get("Chest", {})
	if chest.is_empty():
		parts.append({"id": "shirt_long", "ramp": ramp6(FIXED["linen"])})
	elif chest.get("type", "") == "robe":
		if fem:
			parts.append({"id": "robe_f", "ramp": _mat_ramp(chest)})
		else:
			parts.append({"id": "shirt_long", "ramp": _mat_ramp(chest)})
			if not looks.has("Legs"):
				parts.append({"id": "legs_skirt", "ramp": _mat_ramp(chest)})
	for slot in ["Chest", "Legs", "Feet", "Helmet", "Weapon", "Off Hand"]:
		if not looks.has(slot):
			continue
		var lk: Dictionary = looks[slot]
		if lk.get("type", "") == "robe":
			continue
		for x in GEAR.get(lk.get("type", ""), []):
			parts.append(_part(x, lk, skin, hair))
	if not looks.has("Legs") and not (chest.get("type", "") == "robe" and not fem):
		parts.append({"id": "legs_pants", "ramp": ramp6(FIXED["dark"])})
	if not looks.has("Feet"):
		parts.append({"id": "feet_shoes", "ramp": ramp6(ArtInfo.DATA["materials"]["leather"])})
	if looks.has("Cape"):
		parts.append({"id": "cape_solid", "ramp": _mat_ramp(looks["Cape"])})
	var out := []
	for p in parts:
		if has_item(p["id"]):
			out.append(p)
	return {"body": body, "parts": out}

static func _mat_ramp(lk: Dictionary) -> Array:
	if lk.has("ramp"):
		return ramp6(lk["ramp"])
	var mats: Dictionary = ArtInfo.DATA["materials"]
	return ramp6(mats.get(lk.get("mat", "steel"), mats["steel"]))

static func _part(x: String, lk: Dictionary, skin: Array, hair: Array) -> Dictionary:
	var bits := x.split(":")
	var id := bits[0]
	var how: String = bits[1] if bits.size() > 1 else ""
	var ramp: Array = []
	match how:
		"mat":
			ramp = _mat_ramp(lk)
		"hair":
			ramp = hair
		"":
			ramp = skin if id.begins_with("tail_") or id.begins_with("wings_lizard") or id.begins_with("ears_") else []
		_:
			ramp = ramp6(FIXED.get(how, FIXED["dark"]))
	return {"id": id, "ramp": ramp}

## Which attack animation a weapon uses.
static func attack_anim(weapon_type: String) -> String:
	match weapon_type:
		"bow":
			return "shoot"
		"spear", "staff":
			return "thrust"
		_:
			return "slash"


# =====================================================================
# Monsters built from the same parts (so heroes and monsters match)
# =====================================================================

## Monster art key -> {"body", "parts": [[part id, ramp name]], "attack": animation}.
## Ramps are names in FIXED. Monsters face left (the frames are mirrored).
const MONSTERS := {
	"ghoul": {"body": "male", "attack": "slash", "parts": [["body", "zombie"], ["head_zombie", "zombie"], ["shirt_sleeveless", "ash"], ["legs_pants", "black"]]},
	"revenant": {"body": "male", "attack": "slash", "parts": [["body_skeleton", "bone"], ["head_skeleton", "bone"], ["armor_legion", "rust"], ["legs_skirt_legion", "rust"], ["helm_barbuta", "rust"], ["w_sword", "rust"]]},
	"draugr": {"body": "male", "attack": "slash", "parts": [["body", "zombie"], ["head_zombie", "zombie"], ["armor_leather", ""], ["legs_pants", "black"], ["feet_boots", "leather"], ["helm_barbarian_viking", ""], ["beard_winter", "ash"], ["w_axe", ""]]},
	"strigoi": {"body": "male", "attack": "slash", "parts": [["cape_solid", "blood"], ["body", "pale"], ["head_vampire", "pale"], ["shirt_long", "black"], ["legs_pants", "black"], ["feet_boots", "black"], ["shoulders_mantal", "blood"], ["hair_parted", "black"]]},
	"redcap": {"body": "male", "attack": "thrust", "parts": [["body", "moss"], ["head_goblin", "moss"], ["shirt_short", "leather"], ["legs_pants", "rust"], ["cap_leather", "blood"], ["w_dagger", ""]]},
	"kobold": {"body": "male", "attack": "thrust", "parts": [["body", "rust"], ["head_lizard_m", "rust"], ["tail_lizard", "rust"], ["shirt_sleeveless", "leather"], ["legs_shorts", "leather"], ["w_spear", "iron"]]},
	"bogle": {"body": "male", "attack": "slash", "parts": [["body", "ash"], ["head_goblin", "ash"], ["shirt_sleeveless", "black"], ["legs_shorts", "black"], ["w_mace", ""]]},
	"imp": {"body": "male", "attack": "spellcast", "parts": [["wings_bat", "black"], ["body", "demon"], ["head_human_m", "demon"], ["face_angry", "demon"], ["horns_curled", "horn"], ["tail_lizard", "demon"], ["legs_shorts", "black"]]},
	"obsidian_knight": {"body": "male", "attack": "slash", "parts": [["cape_tattered", "blood"], ["body", "pale"], ["head_human_m", "pale"], ["shirt_long", "black"], ["armor_plate", "obsidian"], ["arms_plate", "obsidian"], ["shoulders_legion", "obsidian"], ["legs_plate", "obsidian"], ["feet_plate", "obsidian"], ["helm_greathelm", "obsidian"], ["w_sword", "obsidian"]]},
	"chain_warden": {"body": "muscular", "attack": "slash", "parts": [["body", "ash"], ["head_human_m", "ash"], ["armor_plate", "iron"], ["arms_plate", "iron"], ["legs_plate", "iron"], ["feet_plate", "iron"], ["helm_close", "iron"], ["w_flail", ""]]},
	"hollow_sentinel": {"body": "male", "attack": "thrust", "parts": [["body", "ash"], ["head_human_m", "ash"], ["armor_plate", "stone"], ["arms_plate", "stone"], ["legs_plate", "stone"], ["feet_plate", "stone"], ["helm_armet", "stone"], ["w_spear", "stone"], ["sh_kite", ""]]},
	"forge_sentry": {"body": "muscular", "attack": "slash", "parts": [["body", "ash"], ["head_human_m", "ash"], ["armor_plate", "rust"], ["arms_plate", "rust"], ["legs_plate", "rust"], ["feet_plate", "rust"], ["helm_sugarloaf", "rust"], ["w_mace", ""], ["sh_heater", ""]]},
	"stoneguard": {"body": "muscular", "attack": "slash", "parts": [["body", "stone"], ["head_troll", "stone"], ["armor_plate", "stone"], ["legs_plate", "stone"], ["feet_plate", "stone"], ["w_axe", ""]]},
	"executor": {"body": "muscular", "attack": "slash", "parts": [["body", "pale"], ["head_human_m", "pale"], ["armor_leather", ""], ["legs_pants", "black"], ["feet_boots", "black"], ["hood", "black"], ["w_axe", ""]]},
	"ash_raider": {"body": "muscular", "attack": "slash", "parts": [["body", "ash"], ["head_orc_m", "ash"], ["armor_leather", ""], ["shoulders_pauldrons", "rust"], ["legs_pants", "black"], ["feet_boots", "leather"], ["hair_longhawk", "black"], ["w_axe", ""]]},
	"cinder_miner": {"body": "muscular", "attack": "slash", "parts": [["body", "rust"], ["head_human_m", "rust"], ["face_angry", "rust"], ["beard_beard", "ash"], ["shirt_sleeveless", "ash"], ["legs_pants", "leather"], ["feet_boots", "leather"], ["helm_mail", "iron"], ["w_mace", ""]]},
	"briar_knight": {"body": "male", "attack": "slash", "parts": [["body", "moss"], ["head_human_m", "moss"], ["armor_plate", "moss"], ["arms_plate", "moss"], ["legs_plate", "moss"], ["feet_plate", "moss"], ["helm_bascinet", "moss"], ["w_sword", "moss"]]},
	"doppelganger": {"body": "male", "attack": "slash", "parts": [["body", "pale"], ["head_human_m", "pale"], ["shirt_long", "ash"], ["legs_pants", "ash"], ["feet_shoes", "ash"], ["w_dagger", ""]]},
	"throne_warden": {"body": "muscular", "attack": "thrust", "parts": [["cape_solid", "blood"], ["body", "pale"], ["head_human_m", "pale"], ["armor_plate", "gold"], ["arms_plate", "gold"], ["shoulders_legion", "gold"], ["legs_plate", "gold"], ["feet_plate", "gold"], ["helm_armet", "gold"], ["w_spear", "gold"]]},
	"choir_sentinel": {"body": "male", "attack": "thrust", "parts": [["wings_feather", "angel"], ["body", "pale"], ["head_human_m", "pale"], ["armor_plate", "gold"], ["legs_plate", "gold"], ["feet_plate", "gold"], ["helm_barbuta", "gold"], ["w_spear", "gold"]]},
	"soul_broker": {"body": "male", "attack": "spellcast", "parts": [["body", "pale"], ["head_human_m", "pale"], ["shirt_long", "purple"], ["legs_skirt", "purple"], ["hood", "purple"], ["w_staff", ""]]},
	"lantern_keeper": {"body": "male", "attack": "spellcast", "parts": [["body", "ash"], ["head_skeleton", "bone"], ["shirt_long", "black"], ["legs_skirt", "black"], ["hood", "black"], ["w_staff", ""]]},
	"changeling": {"body": "female", "attack": "slash", "parts": [["body", "moss"], ["head_goblin", "moss"], ["shirt_sleeveless", "moss"], ["legs_skirt", "moss"], ["w_dagger", ""]]},
	"kappa": {"body": "male", "attack": "slash", "parts": [["body", "scale"], ["head_lizard_m", "scale"], ["shirt_sleeveless", "teal"], ["legs_shorts", "teal"]]},
	"merrow": {"body": "female", "attack": "thrust", "parts": [["body", "teal"], ["head_lizard_f", "teal"], ["tail_lizard", "teal"], ["shirt_sleeveless", "teal"], ["w_spear", "iron"]]},
	"vodyanoy": {"body": "muscular", "attack": "slash", "parts": [["body", "scale"], ["head_lizard_m", "scale"], ["beard_winter", "moss"], ["legs_pants", "teal"], ["w_mace", ""]]},
	"rakshasa": {"body": "male", "attack": "spellcast", "parts": [["body", "fur_brown"], ["head_wolf_m", "fur_brown"], ["shirt_long", "wine"], ["legs_skirt", "wine"], ["crown", "gold"], ["w_staff", ""]]},
	"hellborn_duke": {"body": "muscular", "attack": "slash", "parts": [["cape_tattered", "black"], ["wings_bat", "black"], ["body", "demon"], ["head_human_m", "demon"], ["face_angry", "demon"], ["horns_back", "horn"], ["armor_plate", "obsidian"], ["legs_plate", "obsidian"], ["feet_plate", "obsidian"], ["crown", "gold"], ["w_sword", "obsidian"]]},
	"krampus": {"body": "muscular", "attack": "slash", "parts": [["body", "fur_black"], ["head_boar", "fur_black"], ["horns_curled", "horn"], ["tail_wolf", "black"], ["legs_pants", "black"], ["w_flail", ""]]},
	"wendigo": {"body": "muscular", "attack": "slash", "parts": [["body", "bone"], ["head_skeleton", "bone"], ["horns_back", "bone"], ["legs_shorts", "fur_brown"]]},
	"woodwose": {"body": "muscular", "attack": "slash", "parts": [["body", "fur_brown"], ["head_human_m", "fur_brown"], ["face_angry", "fur_brown"], ["hair_long_messy", "fur_brown"], ["beard_beard", "fur_brown"], ["legs_shorts", "leather"], ["w_mace", ""]]},
	"boggart": {"body": "muscular", "attack": "slash", "parts": [["body", "moss"], ["head_troll", "moss"], ["legs_shorts", "leather"], ["w_mace", ""]]},
	# Bosses (drawn twice the size)
	"boss_grendel": {"boss": true, "body": "muscular", "attack": "slash", "parts": [["body", "moss"], ["head_troll", "moss"], ["legs_shorts", "fur_brown"], ["w_mace", ""]]},
	"boss_black_annis": {"boss": true, "body": "female", "attack": "slash", "parts": [["body", "hag"], ["head_human_f", "hag"], ["face_angry", "hag"], ["hair_long_messy", "ash"], ["robe_f", "black"], ["arms_gloves", "iron"], ["w_dagger", ""]]},
	"boss_dullahan": {"boss": true, "body": "male", "attack": "slash", "parts": [["cape_tattered", "black"], ["body", "pale"], ["armor_plate", "obsidian"], ["arms_plate", "obsidian"], ["shoulders_legion", "obsidian"], ["legs_plate", "obsidian"], ["feet_plate", "obsidian"], ["w_scythe", ""]]},
	"boss_hel": {"boss": true, "body": "female", "attack": "spellcast", "parts": [["body", "pale"], ["head_human_f", "pale"], ["face_neutral", "pale"], ["hair_xlong", "black"], ["robe_f", "black"], ["tiara", "bone"], ["w_staff", ""]]},
	"boss_surtr": {"boss": true, "body": "muscular", "attack": "slash", "parts": [["body", "demon"], ["head_human_m", "demon"], ["face_angry", "demon"], ["beard_winter", "ember"], ["hair_long_messy", "ember"], ["armor_plate", "ember"], ["legs_plate", "ember"], ["feet_plate", "ember"], ["horns_back", "obsidian"], ["w_longsword", ""]]},
	"boss_weeping_warden": {"boss": true, "body": "male", "attack": "thrust", "parts": [["body_skeleton", "bone"], ["head_skeleton", "bone"], ["armor_plate", "rust"], ["legs_plate", "rust"], ["hood", "black"], ["w_halberd", ""]]},
	"boss_withered_queen": {"boss": true, "body": "female", "attack": "spellcast", "parts": [["body", "zombie"], ["head_human_f", "zombie"], ["face_neutral", "zombie"], ["hair_long", "pale"], ["robe_f", "wine"], ["crown", "gold"], ["w_wand", ""]]},
	"boss_jester_of_thorns": {"boss": true, "body": "male", "attack": "thrust", "parts": [["body", "pale"], ["head_human_m", "pale"], ["face_angry", "pale"], ["shirt_long", "purple"], ["legs_leggings", "moss"], ["feet_shoes", "purple"], ["cap_leather", "moss"], ["w_dagger", ""]]},
	"boss_fairy_queen": {"boss": true, "body": "female", "attack": "spellcast", "parts": [["wings_monarch", "fairy"], ["body", "fairy_skin"], ["head_human_f", "fairy_skin"], ["face_neutral", "fairy_skin"], ["ears_long", "fairy_skin"], ["hair_princess", "gold"], ["robe_f", "purple"], ["tiara", "gold"], ["w_wand", ""]]},
	"boss_forgemaster_brann": {"boss": true, "body": "muscular", "attack": "slash", "parts": [["body", "rust"], ["head_human_m", "rust"], ["face_angry", "rust"], ["beard_beard", "blood"], ["armor_plate", "iron"], ["arms_plate", "iron"], ["legs_plate", "iron"], ["feet_plate", "iron"], ["helm_barbarian", ""], ["w_mace", ""]]},
	"boss_high_king_thrandor": {"boss": true, "body": "male", "attack": "slash", "parts": [["cape_solid", "green_royal"], ["body", "pale"], ["head_human_m", "pale"], ["face_neutral", "pale"], ["ears_elven", "pale"], ["hair_long", "silver"], ["armor_plate", "silver"], ["arms_plate", "silver"], ["legs_plate", "silver"], ["feet_plate", "silver"], ["crown", "gold"], ["w_sword", "silver"]]},
	"boss_archon_valeth": {"boss": true, "body": "male", "attack": "thrust", "parts": [["wings_feather", "angel"], ["body", "pale"], ["head_human_m", "pale"], ["armor_plate", "gold"], ["arms_plate", "gold"], ["shoulders_legion", "gold"], ["legs_plate", "gold"], ["feet_plate", "gold"], ["helm_armet", "gold"], ["w_spear", "gold"]]},
	"boss_seraphiel": {"boss": true, "body": "female", "attack": "spellcast", "parts": [["wings_feather", "angel"], ["body", "pale"], ["head_human_f", "pale"], ["face_neutral", "pale"], ["hair_xlong", "gold"], ["robe_f", "angel"], ["tiara", "gold"], ["w_staff", ""]]},
	"boss_duke_malgrath": {"boss": true, "body": "male", "attack": "slash", "parts": [["cape_tattered", "blood"], ["wings_bat", "black"], ["body", "demon"], ["head_human_m", "demon"], ["face_angry", "demon"], ["horns_back", "horn"], ["hair_parted", "black"], ["armor_plate", "obsidian"], ["legs_plate", "obsidian"], ["feet_plate", "obsidian"], ["crown", "gold"], ["w_sword", "obsidian"]]},
	"boss_azgaroth": {"boss": true, "body": "muscular", "attack": "slash", "parts": [["wings_lizard", "obsidian"], ["body", "obsidian"], ["head_human_m", "obsidian"], ["face_angry", "obsidian"], ["horns_curled", "blood"], ["tail_lizard", "obsidian"], ["armor_plate", "blood"], ["legs_plate", "blood"], ["feet_plate", "blood"], ["w_axe", ""]]},
	"boss_sword_spirit": {"boss": true, "body": "male", "attack": "slash", "parts": [["body", "ghost"], ["head_human_m", "ghost"], ["face_neutral", "ghost"], ["hair_long", "silver"], ["shirt_long", "ghost"], ["legs_skirt", "ghost"], ["w_katana", ""]]},
	"boss_demon_ancestor": {"boss": true, "body": "muscular", "attack": "slash", "parts": [["wings_bat", "black"], ["body", "demon"], ["head_minotaur", "black"], ["legs_pants", "black"], ["arms_bracers", "gold"], ["w_flail", ""]]},
}

## The monster's parts as a build spec (mirrored to face left), or {} if it has no LPC look.
static func monster_spec(key: String) -> Dictionary:
	if not MONSTERS.has(key):
		return {}
	var m: Dictionary = MONSTERS[key]
	var parts: Array = []
	var dy := 0
	for p in m["parts"]:
		if String(p[0]).begins_with("head_"):
			dy = HAIR_DY.get(String(p[0]).substr(5), 0)
	for p in m["parts"]:
		var ramp: Array = []
		if String(p[1]) != "":
			ramp = ramp6(FIXED.get(p[1], FIXED["dark"]))
		var part := {"id": p[0], "ramp": ramp}
		if String(p[0]).begins_with("hair_") and dy != 0:
			part["dy"] = dy
		if String(p[0]).begins_with("head_") or String(p[0]).begins_with("face_"):
			part["eyes"] = eye_ramp(Color("#e43b44"))
		if has_item(p[0]):
			parts.append(part)
	return {"body": m["body"], "parts": parts, "flip": true}
