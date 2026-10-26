class_name Sprites
extends RefCounted
## Builds the hero and monster pictures from the PNGs in art/ (made by
## tools/make_art.py). Hero layers use KEY colors that get swapped for real
## colors here: 5 tones of pure red = skin, green = hair, yellow = gear
## material, magenta = rarity trim, blue = eyes. Then the layers are stacked
## and cached.
##
## Style rules the art follows: light from the top-left, 3 main tones per
## material with hue-shifted ramps (cool shadows, warm highlights), and
## colored "selective" outlines instead of plain black.

const ART := "res://art/"
const HD := 2                  # the art is drawn at 2x (see tools/make_art.py): 64x64 bodies
const CANVAS := 48 * HD        # hero picture size; the body sits inside it
const BODY_OFFSET := Vector2i(8 * HD, 12 * HD)
const HERO_FOOT := 43 * HD + 1 # row of the hero's feet inside the canvas
const OUTLINE_ALPHA := 201     # layer outlines: drawn on empty space, only darken what's underneath

# ---------- Character creator choices ----------
const BODIES := ["masc", "fem"]
const BODY_NAMES := ["Build A", "Build B"]
const USE_LPC := true  # heroes from the LPC parts (lpc.gd); false = the older drawn heroes
## Hero pixel size (decision D4, open). 1 = LPC heroes keep their fine 1x pixels (today).
## 2 = heroes are snapped to the monsters' 2x art grid (every hero pixel a 2x2 block) and the
## battle draws them at the monsters' unit, so one screen has one pixel size.
const HERO_PIXEL := 1
# the part of the canvas menus show: the hero's frame rows 12-83 (the staff crystal and halo above the
# head, 4 rows under the feet), cols 12-83
const PORTRAIT_CROP := Rect2i(12, 20, 72, 72)
const PORTRAIT := 72  # its size: show portraits at 72, 144 or 216 to keep pixels crisp
const HAIR_STYLES := Lpc.HAIR_ORDER  # 37 styles; the 13 older names are kept so saves look the same

const TYPE_MATERIAL := {
	"sword": "steel", "dagger": "steel", "axe": "steel", "mace": "iron", "spear": "steel", "bow": "wood", "staff": "wood",
	"buckler": "wood", "shield": "steel", "tower": "iron", "orb": "crystal", "tome": "leather",
	"cap": "leather", "helm": "steel", "hood": "cloth", "crown": "gold",
	"tunic": "leather", "plate": "steel", "robe": "cloth",
	"pants": "linen", "greaves": "steel", "leggings": "leather",
	"boots": "leather", "sandals": "leather", "sabatons": "steel",
	"band": "gold", "signet": "steel", "pendant": "gold", "amulet": "bone",  # 2.1 jewelry
}
## Uniques have their own colors (and a glow).
const UNIQUE_STYLES := {
	"u_hrunting": {"mat": "steel", "trim": "#f87171", "glow": true},
	"u_grendels_hide": {"mat": "hide", "trim": "#fbbf24", "glow": false},
	"u_helskor": {"mat": "dark", "trim": "#7dd3fc", "glow": true},
	"u_mask_of_half_death": {"mat": "pale", "trim": "#3a4466", "glow": false},
	"u_scyllas_fang": {"mat": "bone", "trim": "#22d3ee", "glow": true},
	"u_drowned_captains_boots": {"mat": "sea", "trim": "#fbbf24", "glow": false},
	"u_flame_of_muspelheim": {"mat": "ember", "trim": "#fde047", "glow": true},
	"u_emberforged_greaves": {"mat": "ember", "trim": "#fbbf24", "glow": true},
	"u_aegis_fragment": {"mat": "gold", "trim": "#4ade80", "glow": true},
	"u_crown_of_a_hundred_heads": {"mat": "scale", "trim": "#22c55e", "glow": true},
	"u_anniss_skinning_claw": {"mat": "iron", "trim": "#4a6fa5", "glow": true},
	"u_the_hollow_helm": {"mat": "dark", "trim": "#a8ca58", "glow": true},
	"u_sailors_bane": {"mat": "coral", "trim": "#2ce8f5", "glow": true},
	"u_dragonblood_plate": {"mat": "scale", "trim": "#e43b44", "glow": true},
	"u_book_of_every_monster": {"mat": "leather", "trim": "#c27ad8", "glow": true},
	"u_anniss_bone_charm": {"mat": "bone", "trim": "#4a6fa5", "glow": true},
	"u_draupnir": {"mat": "gold", "trim": "#fde047", "glow": true},
	"u_pearl_of_the_strait": {"mat": "pale", "trim": "#22d3ee", "glow": true},
	"u_andvaranaut": {"mat": "gold", "trim": "#e43b44", "glow": true},
	"u_brisingamen": {"mat": "ember", "trim": "#fbbf24", "glow": true},
	"u_ring_of_gyges": {"mat": "dark", "trim": "#a78bfa", "glow": true},
}
## Set pieces share a look per set.
const SET_STYLES := {
	"grendels_kin": "hide", "hels_shroud": "dark", "tidecaller": "sea", "muspel_forge": "ember", "titanborn": "scale",
	"last_light_of_the_elves": "pale", "court_of_glamour": "coral", "undermountain_oath": "iron", "choir_of_dawn": "gold", "pact_of_the_abyss": "dark",
}

static var _images := {}
static var _cache := {}

# =====================================================================
# Palettes (from art_info.gd)
# =====================================================================

static func skins() -> Array:
	return ArtInfo.DATA["skins"]

static var _hairs: Array = []
## The hair ramps (light to dark), the darkest two steps lifted to a floor: near-black hair on a hero
## seen from behind was a black shape on the dark floor (no dark-on-dark, as for the monsters).
static func hair_colors() -> Array:
	if _hairs.is_empty():
		var floors := [Color("#2e2433"), Color("#241a28")]
		for row in ArtInfo.DATA["hairs"]:
			var out: Array = (row as Array).duplicate()
			for j in 2:
				var i := out.size() - 2 + j
				var c := Color(out[i])
				var f: Color = floors[j]
				if c.get_luminance() < f.get_luminance():
					out[i] = "#" + (Color.from_hsv(c.h, minf(c.s, 0.5), f.v) if c.s > 0.12 else f).to_html(false)
			_hairs.append(out)
	return _hairs

static func eye_colors() -> Array:
	return ArtInfo.DATA["eyes"]

## The middle color of each choice, for the swatches in the character creator.
static func swatches(kind: String) -> Array:
	match kind:
		"skin":
			return skins().map(func(r): return Color(r[2]))
		"hair":
			return hair_colors().map(func(r): return Color(r[2]))
	return eye_colors().map(func(c): return Color(c))

static func _key(rgb: Array) -> int:
	return (int(rgb[0]) << 16) | (int(rgb[1]) << 8) | int(rgb[2])

static func _ckey(c: Color) -> int:
	return (c.r8 << 16) | (c.g8 << 8) | c.b8

static func _add_ramp(map: Dictionary, keys: Array, ramp: Array) -> void:
	for i in mini(keys.size(), ramp.size()):
		var col = ramp[i]
		map[_key(keys[i])] = col if col is Color else Color(col)

## A 5-tone ramp [highlight, light, base, shadow, line] made from one color,
## hue-shifted like the art tools do: shadows lean blue-purple, highlights yellow.
static func ramp_from(base: Color) -> Array:
	var out := []
	var steps := [[0.24, 0.15, -0.15, 2.0], [0.12, 0.15, -0.05, 1.0], [0.0, 0.0, 0.0, 0.0], [-0.17, 0.72, 0.06, 1.0], [-0.33, 0.72, 0.04, 1.6]]
	var h := base.h
	var s := base.s
	var l := (base.v + base.v * (1.0 - s)) / 2.0  # rough lightness
	for st in steps:
		var nh := h
		if s > 0.08:
			var d := fposmod(float(st[1]) - h + 0.5, 1.0) - 0.5
			nh = fposmod(h + clampf(d, -0.05 * float(st[3]), 0.05 * float(st[3])), 1.0)
		var nv := clampf(base.v + float(st[0]) * 0.9, 0.05, 1.0)
		var ns := clampf(s + float(st[2]), 0.0, 1.0)
		out.append(Color.from_hsv(nh, ns, nv))
	return out

# =====================================================================
# Loading, recoloring and stacking
# =====================================================================

static func _img(path: String) -> Image:
	if not _images.has(path):
		var full := ART + path
		var img: Image = null
		if ResourceLoader.exists(full):
			var tex: Texture2D = load(full)
			if tex:
				img = tex.get_image()
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
		_images[path] = img
	return _images[path]

## Swaps key colors using a map of key int -> Color. Keeps each pixel's alpha.
static func _recolor(src: Image, map: Dictionary) -> Image:
	var img := src.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var k := _ckey(c)
			if map.has(k):
				var n: Color = map[k]
				img.set_pixel(x, y, Color(n.r, n.g, n.b, c.a))
	return img

static func _layer(path: String, map: Dictionary) -> Image:
	var src := _img(path)
	if src == null:
		return null
	return _recolor(src, map)

## Stacks a layer: normal pixels replace; outline pixels (alpha 201) only fill
## empty space and otherwise just darken what's under them a little.
static func _stack(dst: Image, src: Image, at: Vector2i) -> void:
	if src == null:
		return
	var w := dst.get_width()
	var h := dst.get_height()
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a8 == 0:
				continue
			var X := x + at.x
			var Y := y + at.y
			if X < 0 or Y < 0 or X >= w or Y >= h:
				continue
			if c.a8 == OUTLINE_ALPHA:
				var d := dst.get_pixel(X, Y)
				if d.a8 == 0:
					dst.set_pixel(X, Y, Color(c.r, c.g, c.b, 1.0))
				else:
					dst.set_pixel(X, Y, Color(d.r * 0.78, d.g * 0.74, d.b * 0.8, 1.0))
			else:
				dst.set_pixel(X, Y, Color(c.r, c.g, c.b, 1.0))

static func _silhouette(src: Image) -> Image:
	var img := src.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.01:
				img.set_pixel(x, y, Color.WHITE)
	return img

# =====================================================================
# The hero
# =====================================================================

## What a piece of gear looks like: type, material and trim color.
static func gear_look(item: Dictionary) -> Dictionary:
	var t := GameData.item_type(item)
	var r := int(item.get("rarity", 0))
	var mat: String = TYPE_MATERIAL.get(t, "steel")
	var trim := Color(GameData.color_of(r))
	var glow := r >= GameData.LEGENDARY
	var art: String = item.get("art", "")
	if UNIQUE_STYLES.has(art):
		var st: Dictionary = UNIQUE_STYLES[art]
		mat = st["mat"]
		trim = Color(st["trim"])
		glow = st["glow"]
	elif art.begins_with("s_"):
		var sig := Monsters.sig_by_art(art)
		if not sig.is_empty():
			mat = sig["mat"]
			trim = Color(sig["trim"])
			glow = true
	elif art.begins_with("r_") or art.begins_with("c_"):
		var cd := Races.gear_by_art(art) if art.begins_with("r_") else Realms.cosmetic_by_art(art)
		if not cd.is_empty():
			mat = cd["mat"]
			trim = Color(cd["trim"])
			glow = true
	elif item.get("set", "") != "" and GameData.EVO_SETS.has(item["set"]):
		var es: Dictionary = GameData.EVO_SETS[item["set"]]
		mat = es["mat"]
		trim = Color(es["trim"])
		glow = true
	elif item.get("set", "") != "":
		mat = SET_STYLES.get(item["set"], mat)
	elif r == 0:
		trim = Color("#8b9bb4")
	return {"type": t, "mat": mat, "trim": trim, "glow": glow}

## The race layers to draw: the race's own, changed by a transformation
## ("form") and an awakening look ("look"). Also forces skin and eye colors.
## Returns {"back": [...], "front": [...], "app": app with forced colors}.
const UNDER_HELMET := ["ears", "goblin_ears", "beard", "tusks", "stitches", "fangs", "dragon_scales", "golem_runes"]

static func race_look(app: Dictionary) -> Dictionary:
	var race: String = app.get("race", "Human")
	var base: Dictionary = ArtInfo.DATA["races"].get(race, {"back": [], "front": []})
	var back: Array = (base["back"] as Array).duplicate()
	var front: Array = (base["front"] as Array).duplicate()
	var a := app.duplicate()
	var eyes: Dictionary = ArtInfo.DATA.get("race_eyes", {})
	if eyes.has(race):
		a["eye_color"] = eyes[race]
	var specs: Array = []
	var form: String = app.get("form", "")
	if form != "" and ArtInfo.DATA.get("forms", {}).has(form):
		specs.append(ArtInfo.DATA["forms"][form])
	var look: String = app.get("look", "")
	if look != "" and ArtInfo.DATA.get("race_looks", {}).has(look):
		specs.append(ArtInfo.DATA["race_looks"][look])
	var back_set: Array = ArtInfo.DATA.get("race_back", [])
	for spec in specs:
		for l in spec.get("remove", []):
			back.erase(l)
			front.erase(l)
		for l in spec.get("add", []):
			if l in back or l in front:
				continue
			if l in back_set:
				back.append(l)
			else:
				front.append(l)
		if spec.has("skin"):
			a["skin"] = int(spec["skin"])
		if spec.has("eyes"):
			a["eye_color"] = spec["eyes"]
	return {"back": back, "front": front, "app": a}

static func _char_map(app: Dictionary) -> Dictionary:
	var keys: Dictionary = ArtInfo.DATA["keys"]
	var map := {}
	var sk := skins()
	var hc := hair_colors()
	var ey := eye_colors()
	_add_ramp(map, keys["skin"], sk[clampi(int(app.get("skin", 1)), 0, sk.size() - 1)])
	_add_ramp(map, keys["hair"], hc[clampi(int(app.get("hair_color", 1)), 0, hc.size() - 1)])
	map[_key(keys["eye"][0])] = Color(app["eye_color"]) if app.has("eye_color") else Color(ey[clampi(int(app.get("eyes", 0)), 0, ey.size() - 1)])
	return map

static func _gear_map(look: Dictionary, char_map: Dictionary) -> Dictionary:
	var keys: Dictionary = ArtInfo.DATA["keys"]
	var map := char_map.duplicate()
	var mats: Dictionary = ArtInfo.DATA["materials"]
	if look.has("ramp"):
		_add_ramp(map, keys["mat"], look["ramp"])
	else:
		_add_ramp(map, keys["mat"], mats.get(look["mat"], mats["steel"]))
	_add_ramp(map, keys["trim"], ramp_from(look["trim"]))
	return map

## Builds the hero. looks = slot -> gear_look() (missing slots show plain clothes).
## Returns {"body", "body_white", "body_img", "weapon", "weapon_white", "weapon_img",
##          "weapon_type", "pivot" (weapon pixels), "hand" (canvas pixels), "glow"}
static func hero(app: Dictionary, looks: Dictionary) -> Dictionary:
	if HeroArt.available():
		return _hero_pl_cached(app, looks, false)
	var key := str(app) + str(looks)
	if _cache.has(key):
		return _cache[key]
	if USE_LPC and Lpc.available():
		var lp := _hero_lpc(app, looks)
		_cache[key] = lp
		return lp
	var body: String = app.get("body", "masc")
	if not body in BODIES:
		body = "masc"
	var race_layers := race_look(app)
	var cmap := _char_map(race_layers["app"])
	var canvas := Image.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
	var o := BODY_OFFSET
	for layer in race_layers["back"]:
		_stack(canvas, _layer("hero/race_%s.png" % layer, cmap), o)
	# The off-hand item sits behind the body, in the back hand
	if looks.has("Off Hand"):
		var lk: Dictionary = looks["Off Hand"]
		var oi := _layer("gear/%s.png" % lk["type"], _gear_map(lk, cmap))
		if oi:
			var piv: Array = ArtInfo.DATA["offhands"].get(lk["type"], {"pivot": [0, 0]})["pivot"]
			var hand: Array = ArtInfo.DATA["off_hand"]
			_stack(canvas, oi, o + Vector2i(int(hand[0]) - int(piv[0]), int(hand[1]) - int(piv[1])))
	# A unique class's cape hangs behind the body
	if looks.has("Cape"):
		var ck: Dictionary = looks["Cape"]
		_stack(canvas, _layer("gear/cape.png", _gear_map(ck, cmap)), o)
	# Long hair, ponytails, buns and braids hang behind the body too
	var hair_file: String = str(app.get("hair", "Short")).to_lower().replace(" ", "_")
	var helmet_now: Dictionary = looks.get("Helmet", {})
	var hood_hides: bool = not helmet_now.is_empty() and ArtInfo.DATA["helmets"].get(helmet_now["type"], {}).get("hides_hair", false)
	if not hood_hides and ResourceLoader.exists(ART + "hero/hair_%s_back.png" % hair_file):
		_stack(canvas, _layer("hero/hair_%s_back.png" % hair_file, cmap), o)
	_stack(canvas, _layer("hero/body_%s.png" % body, cmap), o)
	for slot in ["Legs", "Feet", "Chest"]:
		if looks.has(slot):
			var lk: Dictionary = looks[slot]
			_stack(canvas, _layer("gear/%s_%s.png" % [lk["type"], body], _gear_map(lk, cmap)), o)
	var helmet: Dictionary = looks.get("Helmet", {})
	var hides := false
	if not helmet.is_empty():
		hides = ArtInfo.DATA["helmets"].get(helmet["type"], {}).get("hides_hair", false)
	if not hides:
		_stack(canvas, _layer("hero/hair_%s.png" % hair_file, cmap), o)
	var front: Array = race_layers["front"]
	for layer in front:
		if layer in UNDER_HELMET:
			_stack(canvas, _layer("hero/race_%s.png" % layer, cmap), o)
	if not helmet.is_empty():
		_stack(canvas, _layer("gear/%s.png" % helmet["type"], _gear_map(helmet, cmap)), o)
	for layer in front:
		if not layer in UNDER_HELMET:
			_stack(canvas, _layer("hero/race_%s.png" % layer, cmap), o)

	var out := {"body_img": canvas, "body": ImageTexture.create_from_image(canvas), "body_white": ImageTexture.create_from_image(_silhouette(canvas)),
		"weapon": null, "weapon_white": null, "weapon_type": "", "pivot": Vector2.ZERO, "glow": Color(0, 0, 0, 0)}
	var hand: Array = ArtInfo.DATA.get("hand_fem", ArtInfo.DATA["hand"]) if body == "fem" else ArtInfo.DATA["hand"]
	out["hand"] = Vector2(o) + Vector2(float(hand[0]), float(hand[1])) + Vector2(0.5, 0.5) * HD
	if looks.has("Weapon"):
		var lk: Dictionary = looks["Weapon"]
		var wsrc := _layer("gear/%s.png" % lk["type"], _gear_map(lk, cmap))
		if wsrc:
			# Weapons are drawn on their own, so outline pixels become solid
			var wi := Image.create(wsrc.get_width(), wsrc.get_height(), false, Image.FORMAT_RGBA8)
			_stack(wi, wsrc, Vector2i.ZERO)
			var piv: Array = ArtInfo.DATA["weapons"].get(lk["type"], {"pivot": [0, 0]})["pivot"]
			out["weapon"] = ImageTexture.create_from_image(wi)
			out["weapon_img"] = wi
			out["weapon_white"] = ImageTexture.create_from_image(_silhouette(wi))
			out["weapon_type"] = lk["type"]
			out["pivot"] = Vector2(float(piv[0]), float(piv[1])) + Vector2(0.5, 0.5) * HD
			if lk["glow"]:
				out["glow"] = lk["trim"]
	_cache[key] = out
	return out

## The part of the looks a hero picture depends on: with the PixelLab hero only the class and the
## weapon (armour no longer changes the look, so swapping it reuses the cached picture).
static func _looks_key(looks: Dictionary) -> String:
	if not HeroArt.available():
		return str(looks)
	var w: Dictionary = looks.get("Weapon", {})
	return str([looks.get("Class", {}), w.get("type", ""), w.get("trim", "") if w.get("glow", false) else ""])

## PixelLab heroes kept at once (oldest dropped first): every new look, weapon type or class
## tier makes one, and a phone shouldn't keep every look tried in the creator for the session.
const MAX_HERO_PICS := 48
static var _pl_keys: Array[String] = []

## The PixelLab hero, cached by only what it draws: the look, the class outfit and the weapon
## (armour has no look in 2.1, so changing it doesn't make a new picture).
static func _hero_pl_cached(app: Dictionary, looks: Dictionary, back: bool) -> Dictionary:
	var w: Dictionary = looks.get("Weapon", {})
	var key := "pl%s|%s|%s|%s|%s|%s" % [back, str(app), str(looks.get("Class", {})), w.get("type", ""), w.get("glow", false), w.get("trim", "")]
	if _cache.has(key):
		return _cache[key]
	var pl := _hero_pl(app, looks, back)
	_cache[key] = pl
	_pl_keys.append(key)
	while _pl_keys.size() > MAX_HERO_PICS:
		_cache.erase(_pl_keys.pop_front())
	return pl

## The PixelLab hero (hero_art.gd): class outfit, hair, face and the weapon type, on the fixed frames.
## Laid out like the LPC hero (a 96x96 cell on the hero canvas), so battle and menus treat it the same.
## back: seen from behind (battle); else the front portrait.
static func _hero_pl(app: Dictionary, looks: Dictionary, back: bool) -> Dictionary:
	var ct := HeroArt.class_of(looks)
	var wt := ""
	var glow := Color(0, 0, 0, 0)
	if looks.has("Weapon"):
		wt = looks["Weapon"].get("type", "")
		if looks["Weapon"].get("glow", false):
			glow = looks["Weapon"]["trim"]
	var fr := HeroArt.frames(race_look(app)["app"], ct[0], ct[1], wt, back)  # forms and awakenings still force skin tones
	var anims := HeroArt.anims(fr, back)
	var still: Image = anims["combat_idle"]["img"][0]
	var canvas := Image.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
	var s := still.get_width()
	canvas.blend_rect(still, Rect2i(0, 0, s, s), BODY_OFFSET - Vector2i((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2))
	var hand: Array = HeroArt.hands(app)[0 if back else HeroArt.PORTRAIT[0]]
	return {"body_img": canvas, "body": ImageTexture.create_from_image(canvas), "body_white": ImageTexture.create_from_image(_silhouette(canvas)),
		"weapon": null, "weapon_white": null, "weapon_type": wt, "pivot": Vector2.ZERO, "glow": glow,
		"hand": Vector2(BODY_OFFSET) - Vector2((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2) + Vector2(float(hand[0]), float(hand[1])),
		"lpc": anims, "pl": true}

## The LPC hero: animation frames plus a still picture laid out like the old
## hero canvas (the 64x64 character at BODY_OFFSET), so menus and portraits work.
static func _hero_lpc(app: Dictionary, looks: Dictionary) -> Dictionary:
	var built := Lpc.build(_px_spec(Lpc.spec(app, looks)))
	var canvas := Image.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
	var still: Image = built["still"]
	var s := still.get_width()
	canvas.blend_rect(still, Rect2i(0, 0, s, s), BODY_OFFSET - Vector2i((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2))
	var glow := Color(0, 0, 0, 0)
	var wt := ""
	if looks.has("Weapon"):
		wt = looks["Weapon"].get("type", "")
		if looks["Weapon"].get("glow", false):
			glow = looks["Weapon"]["trim"]
	return {"body_img": canvas, "body": ImageTexture.create_from_image(canvas), "body_white": ImageTexture.create_from_image(_silhouette(canvas)),
		"weapon": null, "weapon_white": null, "weapon_type": wt, "pivot": Vector2.ZERO, "glow": glow,
		"hand": Vector2(BODY_OFFSET) + Vector2(44, 38), "lpc": built["anims"]}

static func _px_spec(sp: Dictionary) -> Dictionary:
	if HERO_PIXEL > 1:
		sp = sp.duplicate()  # never change the caller's spec (it may be a shared constant or cached)
		sp["px"] = HERO_PIXEL
	return sp

## The picture snapped to a px-sized pixel grid (same size, every px x px block one color:
## the most common solid color in it, or clear when most of it is clear). For HERO_PIXEL.
static func chunky(src: Image, px: int) -> Image:
	if px <= 1:
		return src
	var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for by in range(0, src.get_height(), px):
		for bx in range(0, src.get_width(), px):
			var counts := {}
			var solid := 0
			for y in range(by, mini(by + px, src.get_height())):
				for x in range(bx, mini(bx + px, src.get_width())):
					var c := src.get_pixel(x, y)
					if c.a8 >= 128:
						solid += 1
						var k := c.to_rgba32()
						counts[k] = int(counts.get(k, 0)) + 1
			if solid * 2 < px * px:
				continue
			var best := 0
			var bk := 0
			for k in counts:
				if int(counts[k]) > best:
					best = counts[k]
					bk = k
			out.fill_rect(Rect2i(bx, by, px, px), Color.hex(bk))
	return out

## A hero's back picture for views that draw every frame (team in the fight and the room):
## hero_looks() and the cache key are rebuilt at most every LOOK_REFRESH_MS per hero, not 60
## times a second. Also keeps "back_key" (the look as a string) and "back_looks" on the hero.
const LOOK_REFRESH_MS := 500
static func hero_back_of(g: GameState) -> Dictionary:
	var now := Time.get_ticks_msec()
	if g.has_meta("back_art") and now - int(g.get_meta("back_art_ms", 0)) < LOOK_REFRESH_MS:
		return g.get_meta("back_art")
	var looks := g.hero_looks()
	var art := hero_back(g.appearance, looks)
	g.set_meta("back_art", art)
	g.set_meta("back_art_ms", now)
	g.set_meta("back_key", str(g.appearance) + str(looks))
	g.set_meta("back_looks", looks)
	return art

## The hero seen from behind (0.13 back-to-front fights): same dictionary as hero().
static func hero_back(app: Dictionary, looks: Dictionary) -> Dictionary:
	if HeroArt.available():
		return _hero_pl_cached(app, looks, true)
	var key := "back" + str(app) + str(looks)
	if _cache.has(key):
		return _cache[key]
	if not (USE_LPC and Lpc.available()):
		return hero(app, looks)
	var sp := Lpc.spec(app, looks)
	sp["dir"] = "up"
	var built := Lpc.build(_px_spec(sp))
	var canvas := Image.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
	var still: Image = built["still"]
	var s := still.get_width()
	canvas.blend_rect(still, Rect2i(0, 0, s, s), BODY_OFFSET - Vector2i((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2))
	var front := hero(app, looks)
	var out := front.duplicate()
	out["body_img"] = canvas
	out["body"] = ImageTexture.create_from_image(canvas)
	out["body_white"] = ImageTexture.create_from_image(_silhouette(canvas))
	out["lpc"] = built["anims"]
	out["hand"] = Vector2(BODY_OFFSET) + Vector2(32, 34)
	_cache[key] = out
	return out

## A small picture of an item on its own (for item cards and the collection).
## Icons for things that aren't gear: potions, elixirs, scrolls, the mystery box,
## the backpack (art/consumables/<id>.png). Null if there's no picture.
static func consumable_icon(id: String) -> Texture2D:
	var key := "c_" + id
	if _cache.has(key):
		return _cache[key]
	var path := "res://art/consumables/%s.png" % id
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex

static func item_icon(item: Dictionary) -> ImageTexture:
	var lk := gear_look(item)
	var key := "i" + str(lk)
	if _cache.has(key):
		return _cache[key]
	var t: String = lk["type"]
	var cmap := _char_map({})
	var path := "gear/%s.png" % t
	if item.get("slot", "") in ["Chest", "Legs", "Feet"]:
		path = "gear/%s_masc.png" % t
	var src := _layer(path, _gear_map(lk, cmap))
	var out: ImageTexture = null
	if src:
		var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
		_stack(img, src, Vector2i.ZERO)
		var used := img.get_used_rect()
		if used.size.x > 0:
			# One frame for every icon (ArtStyle.ICON_FRAME), centered, at the art's own pixel
			# size: a dagger looks smaller than a spear, but every pixel is the same size
			var side := maxi(ArtStyle.ICON_FRAME, maxi(used.size.x, used.size.y) + 2)
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(img, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
			out = ImageTexture.create_from_image(sq)
	_cache[key] = out
	return out

## The menu portrait's idle frames: the PixelLab hero has two (it breathes), the others one.
static func portrait_frames(app: Dictionary, looks := {}) -> Array:
	var key := "pf" + str(app) + _looks_key(looks)
	if _cache.has(key):
		return _cache[key]
	var out := [portrait(app, looks)]
	var h := hero(app, looks)
	if h.get("pl", false):
		var imgs: Array = h["lpc"]["combat_idle"]["img"]
		if imgs.size() > 1:
			var img: Image = imgs[1]
			var canvas := Image.create(CANVAS, CANVAS, false, Image.FORMAT_RGBA8)
			var s := img.get_width()
			canvas.blend_rect(img, Rect2i(0, 0, s, s), BODY_OFFSET - Vector2i((s - Lpc.CORE) / 2, (s - Lpc.CORE) / 2))
			out.append(ImageTexture.create_from_image(canvas.get_region(Rect2i(PORTRAIT_CROP).intersection(Rect2i(Vector2i.ZERO, canvas.get_size())))))
	_cache[key] = out
	return out

## The hero with the weapon held upright, as one picture (for menus).
static func portrait(app: Dictionary, looks := {}) -> ImageTexture:
	var key := "p" + str(app) + _looks_key(looks)
	if _cache.has(key):
		return _cache[key]
	var h := hero(app, looks)
	var img := (h["body_img"] as Image).duplicate() as Image
	if h.has("weapon_img"):
		var hand: Vector2 = h["hand"]
		var piv: Vector2 = h["pivot"]
		_stack(img, h["weapon_img"], Vector2i(int(hand.x - piv.x), int(hand.y - piv.y)))
	# A fixed crop around the hero, so every portrait shows the hero at the same
	# size and menus can show it at whole-pixel scales (88, 176...).
	var r := Rect2i(PORTRAIT_CROP).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	img = img.get_region(r)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

# =====================================================================
# Monsters (final colors, no recoloring)
# =====================================================================

## Monster art goes by its art key (ids: "kobold", "boss_grendel"), never by the
## shown name. Returns {"tex", "white", "size": Vector2, "foot": float} or {} if there's no art.
static func enemy_by_key(key: String) -> Dictionary:
	if _cache.has("e_" + key):
		return _cache["e_" + key]
	var img := _img("enemies/%s.png" % key)
	var out := {}
	if img:
		# The feet are the lowest solid row of the picture itself (art_info.gd lists the same
		# numbers for tools; measuring here means new art can never get a stale value)
		var used := img.get_used_rect()
		# Redrawn monsters (art_info "hd": 1) are already in the dark palette: no second darkening
		# pass (fable r1), only the rim light, so they stay brighter than the hall behind them
		var native: bool = int(ArtInfo.DATA["enemies"].get(key, {}).get("hd", 2)) == 1
		var graded := DarkGrade.image(img, DarkGrade.NATIVE, true, DarkGrade.SPRITE) if native else DarkGrade.image(img)
		out = {"tex": ImageTexture.create_from_image(graded), "white": ImageTexture.create_from_image(_silhouette(img)),
			"size": Vector2(img.get_size()), "foot": float(used.end.y - 1 if used.size.y > 0 else img.get_height() - 1)}
	_cache["e_" + key] = out
	return out

## Forgets the monster pictures (the dark grade was switched on or off).
static func clear_monster_cache() -> void:
	for k in _cache.keys():
		if str(k).begins_with("e_"):
			_cache.erase(k)

# =====================================================================
# Animation poses (pixel-perfect, made from one picture)
# =====================================================================
# Every pose shifts whole pixel rows, so the art never gets blurry or uneven.
# lean: how far the top of the body leans (pixels, + = toward facing direction)
# squash: + = upper body sinks (breathing out, crouching), - = stretches up.
# The legs (rows below the waist) stay planted.
const POSES := {
	"idle0": {"lean": 0, "squash": 0},
	"idle1": {"lean": 0, "squash": 1},
	"windup": {"lean": -2, "squash": 1},
	"strike": {"lean": 3, "squash": -1},
	"follow": {"lean": 1, "squash": 0},
	"crouch": {"lean": -1, "squash": 2},
	"cast": {"lean": -1, "squash": -2},
	"hit1": {"lean": -3, "squash": 2},  # A6: squash on the hit frame
	"hit2": {"lean": -1, "squash": 0},
	"kneel1": {"lean": -1, "squash": 3},
	"kneel2": {"lean": -2, "squash": 6},
}

## Shifts the rows above the waist. facing: +1 = faces right (hero), -1 = left (monsters).
static func pose_image(src: Image, waist: int, top: int, lean: int, squash: int, facing: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Legs stay where they are
	out.blit_rect(src, Rect2i(0, waist, w, h - waist), Vector2i(0, waist))
	var span := maxf(1.0, float(waist - top))
	# Stretching up leaves a gap above the waist: repeat the waist row to fill it
	if squash < 0:
		for k in -squash:
			out.blit_rect(src, Rect2i(0, waist - 1, w, 1), Vector2i(0, waist - 1 - k))
	for y in range(top, waist):
		var t := float(waist - y) / span
		var dx := int(round(lean * t)) * facing
		var ny := y + squash
		if ny < 0 or ny >= h:
			continue
		# The whole row moves by the same dx: one blit (clear pixels leave what is under them)
		out.blend_rect(src, Rect2i(0, y, w, 1), Vector2i(dx, ny))
	return out

## All poses for a picture: name -> {"tex", "white", "dx" (how far the hand row moved), "dy"}.
## hand_row: the row the weapon hand is on (to move the weapon with the body).
static func poses_for(key: String, src: Image, facing: int, hand_row := -1) -> Dictionary:
	if _cache.has("pose_" + key):
		return _cache["pose_" + key]
	var used := src.get_used_rect()
	var top := used.position.y
	var bottom := used.end.y
	var waist := top + int((bottom - top) * 0.62)
	var out := {}
	for p in POSES:
		var d: Dictionary = POSES[p]
		var lean := int(d["lean"]) * HD
		var squash := int(d["squash"]) * HD
		var img := pose_image(src, waist, top, lean, squash, facing)
		var hdx := 0
		if hand_row >= top and hand_row < waist:
			hdx = int(round(lean * float(waist - hand_row) / maxf(1.0, waist - top))) * facing
		out[p] = {"tex": ImageTexture.create_from_image(img), "white": ImageTexture.create_from_image(_silhouette(img)),
			"dx": hdx, "dy": squash if hand_row < waist else 0}
	_cache["pose_" + key] = out
	return out
