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
const HAIR_STYLES := ["Short", "Spiky", "Long", "Ponytail", "Bun", "Mohawk", "Bald"]

const TYPE_MATERIAL := {
	"sword": "steel", "dagger": "steel", "axe": "steel", "mace": "iron", "spear": "steel", "bow": "wood", "staff": "wood",
	"buckler": "wood", "shield": "steel", "tower": "iron", "orb": "crystal", "tome": "leather",
	"cap": "leather", "helm": "steel", "hood": "cloth", "crown": "gold",
	"tunic": "leather", "plate": "steel", "robe": "cloth",
	"pants": "linen", "greaves": "steel", "leggings": "leather",
	"boots": "leather", "sandals": "leather", "sabatons": "steel",
}
## Uniques have their own colors (and a glow).
const UNIQUE_STYLES := {
	"u_hrunting": {"mat": "steel", "trim": "#f87171", "glow": true},
	"u_grendels_hide": {"mat": "hide", "trim": "#fbbf24", "glow": false},
	"u_helskor": {"mat": "dark", "trim": "#7dd3fc", "glow": true},
	"u_mask_of_half-death": {"mat": "pale", "trim": "#3a4466", "glow": false},
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
}
## Set pieces share a look per set.
const SET_STYLES := {
	"Grendel's Kin": "hide", "Hel's Shroud": "dark", "Tidecaller": "sea", "Muspel Forge": "ember", "Titanborn": "scale",
	"Last Light of the Elves": "pale", "Court of Glamour": "coral", "Undermountain Oath": "iron", "Choir of Dawn": "gold", "Pact of the Abyss": "dark",
}

static var _images := {}
static var _cache := {}

# =====================================================================
# Palettes (from art_info.gd)
# =====================================================================

static func skins() -> Array:
	return ArtInfo.DATA["skins"]

static func hair_colors() -> Array:
	return ArtInfo.DATA["hairs"]

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
	var key := str(app) + str(looks)
	if _cache.has(key):
		return _cache[key]
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
		var style: String = str(app.get("hair", "Short")).to_lower()
		_stack(canvas, _layer("hero/hair_%s.png" % style, cmap), o)
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
	var hand: Array = ArtInfo.DATA["hand"]
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

## A small picture of an item on its own (for item cards and the collection).
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
			var side := maxi(used.size.x, used.size.y) + 2
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(img, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
			out = ImageTexture.create_from_image(sq)
	_cache[key] = out
	return out

## The hero with the weapon held upright, as one picture (for menus).
static func portrait(app: Dictionary, looks := {}) -> ImageTexture:
	var key := "p" + str(app) + str(looks)
	if _cache.has(key):
		return _cache[key]
	var h := hero(app, looks)
	var img := (h["body_img"] as Image).duplicate() as Image
	if h.has("weapon_img"):
		var hand: Vector2 = h["hand"]
		var piv: Vector2 = h["pivot"]
		_stack(img, h["weapon_img"], Vector2i(int(hand.x - piv.x), int(hand.y - piv.y)))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

# =====================================================================
# Monsters (final colors, no recoloring)
# =====================================================================

static func enemy_key(enemy_name: String, boss: bool) -> String:
	var n := enemy_name
	for p in GameData.RANK_PREFIXES:
		if p != "" and n.begins_with(p):
			n = n.substr(p.length())
	if boss:
		return "boss_" + n.split(" ")[0].split(",")[0].to_lower()
	var out := ""
	for ch in n.to_lower():
		out += ch if (ch >= "a" and ch <= "z") else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	return out.trim_suffix("_")

## Returns {"tex", "white", "size": Vector2, "foot": float} or {} if there's no art.
static func enemy(enemy_name: String, boss: bool) -> Dictionary:
	return enemy_by_key(enemy_key(enemy_name, boss))

static func enemy_by_key(key: String) -> Dictionary:
	if _cache.has("e_" + key):
		return _cache["e_" + key]
	var img := _img("enemies/%s.png" % key)
	var out := {}
	if img:
		var info: Dictionary = ArtInfo.DATA["enemies"].get(key, {})
		out = {"tex": ImageTexture.create_from_image(img), "white": ImageTexture.create_from_image(_silhouette(img)),
			"size": Vector2(img.get_size()), "foot": float(info.get("foot", img.get_height() - 1))}
	_cache["e_" + key] = out
	return out

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
	"hit1": {"lean": -3, "squash": 0},
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
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var nx := x + dx
			if nx >= 0 and nx < w:
				out.set_pixel(nx, ny, c)
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
