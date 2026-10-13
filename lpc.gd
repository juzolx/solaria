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
		var f := FileAccess.open(DIR + "manifest.json", FileAccess.READ)
		if f:
			_manifest = JSON.parse_string(f.get_as_text())
		f = FileAccess.open(DIR + "palettes.json", FileAccess.READ)
		if f:
			_palettes = JSON.parse_string(f.get_as_text())
	return _manifest

static func available() -> bool:
	return not manifest().is_empty()

static func has_item(id: String) -> bool:
	return manifest().get("items", {}).has(id)

## The base colors a part was drawn in (its material's base palette), darkest first.
static func base_ramp(material: String) -> Array:
	manifest()
	if not _palettes.has(material):
		return []
	var p: Dictionary = _palettes[material]
	var out := []
	for h in p["palettes"].get(p["base"], []):
		out.append(Color(h))
	return out

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
	if _built.has(key):
		return _built[key]
	var items: Dictionary = manifest().get("items", {})
	var body: String = spec.get("body", "male")
	var layers: Array = []  # [z, order, files dict, maps]
	var order := 0
	for part in spec.get("parts", []):
		var it: Dictionary = items.get(part["id"], {})
		if it.is_empty():
			continue
		var maps: Array = []
		var ramp: Array = part.get("ramp", [])
		if not ramp.is_empty() and it.get("material", "") != "":
			maps.append([base_ramp(it["material"]), ramp])
		if it.get("eye", false) and part.has("eyes"):
			maps.append([base_ramp("eye"), part["eyes"]])
		for L in it["layers"]:
			var files: Dictionary = L["files"]
			var f: Dictionary = files.get(body, files.get("male", files.get("female", {})))
			if f.is_empty():
				continue
			layers.append([int(L["z"]), order, f, maps])
			order += 1
	layers.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out := {"anims": {}}
	for anim in BUILD:
		var a := _compose(layers, anim)
		if not a.is_empty():
			out["anims"][anim] = a
	if not out["anims"].has("combat_idle"):
		out["anims"]["combat_idle"] = _compose(layers, "walk")
	var idle: Dictionary = out["anims"]["combat_idle"]
	out["still"] = (idle["img"][0] as Image)
	_built[key] = out
	return out

## One animation: every layer's strip for it (or its standing frame when a part
## has no such animation), stacked frame by frame.
static func _compose(layers: Array, anim: String) -> Dictionary:
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
		var im := _recolor(f["file"], L[3])
		if im == null:
			continue
		var fs := int(f["size"])
		var n := maxi(1, im.get_width() / fs)
		parts.append([im, fs, n, animated])
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
			var at := Vector2i((size - fs) / 2, (size - fs) / 2)
			canvas.blend_rect(im, Rect2i(fi * fs, 0, fs, fs), at)
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
	"Fairy": ["human_m", "human_f", ["ears_long", "wings_feather:fairy"], true],
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
	"crown": ["crown:gold"], "dragon_wings": ["wings_lizard"], "wings_big": ["wings_feather:fairy"],
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
const FIXED := {
	"linen": ["#f4e6c4", "#ead4aa", "#d0b48a", "#a3825f", "#5a3f35"],
	"dark": ["#5a6988", "#3a4466", "#262b44", "#181425", "#0e0b16"],
	"angel": ["#ffffff", "#f4f4f8", "#e2e2ec", "#bdbdd2", "#8a8aa8"],
	"fairy": ["#ffe0f4", "#f8b8e4", "#e88ad0", "#b85aa8", "#6a2a6a"],
	"horn": ["#e8dccc", "#bba98e", "#8a7560", "#5a4a3e", "#2e2420"],
	"gold": ["#fff4a3", "#fee761", "#feae34", "#f77622", "#be4a2f"],
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
	var style: String = HAIR.get(str(app.get("hair", "Short")), "plain")
	if style != "" and not hide_hair:
		parts.append({"id": "hair_" + style, "ramp": hair})
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
