class_name HeroArt
extends RefCounted
## The PixelLab hero (2.1): layers baked by claude/art_test/pixellab/game/bake.py into art/heroes/.
## Every layer is drawn on the same 9 frames, each a 96x96 cell (sheets: cells side by side):
##   0-1 idle, 2-5 attack, 6 hit  (battle, seen from behind)    7-8 portrait idle (front)
## A hero = body + class outfit (by class and tier) + head with the hair style + face (portrait)
## + the equipped weapon type in the hand. Skin and hair colours come from the creator's ramps:
## each layer's index sheet holds the original shade of every skin (R) and hair (G) pixel.
## Armour no longer changes the look. Built once per look and cached (never per frame).

const DIR := "res://art/heroes/"
const CELL := 96
const IDLE := [0, 1]
const ATTACK := [2, 3, 4, 5]
const HIT := [6]
const PORTRAIT := [7, 8]
const ATTACK_FPS := 9.0
## The 10 faces Juzo picked (the creator's "Face" row).
const FACES := ["neutral", "smile", "laughing", "determined", "fierce", "grim", "wary", "surprised", "sleepy", "battle_cry"]
const FACE_NAMES := ["Calm", "Smile", "Laugh", "Determined", "Fierce", "Grim", "Wary", "Surprised", "Sleepy", "Battle cry"]
## Weapon types without their own drawing are held as the closest one.
const WEAPON_AS := {"orb": "staff", "tome": "staff", "wand": "staff", "fist": ""}
## Races with no drawn body of their own yet: they use the human body with their skin tones.
const DRAWN_RACES := ["Human"]

static var _info := {}
static var _imgs := {}
static var _built := {}

static func info() -> Dictionary:
	if _info.is_empty() and FileAccess.file_exists(DIR + "heroes.json"):
		_info = JSON.parse_string(FileAccess.get_file_as_string(DIR + "heroes.json"))
	return _info

static func available() -> bool:
	return not info().is_empty()

static func _img(path: String) -> Image:
	if not _imgs.has(path):
		var img: Image = null
		if ResourceLoader.exists(DIR + path):
			var tex: Texture2D = load(DIR + path)
			if tex:
				img = tex.get_image()
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
		_imgs[path] = img
	return _imgs[path]

## "m" or "f" from the creator's build.
static func body_key(app: Dictionary) -> String:
	return "f" if str(app.get("body", "masc")) == "fem" else "m"

## The hair style file for a creator choice (styles PixelLab hasn't drawn, like horns, fall back to Short).
static func style_key(app: Dictionary) -> String:
	var st: Dictionary = info().get("styles", {})
	return str(st.get(str(app.get("hair", "Short")), "short"))

## The outfit for a class and how far its line has gone (tier 0, 15, 35, 75: the best drawn one at or below).
static func outfit_key(cls: String, tier: int, b: String) -> String:
	var c := cls.to_lower()
	var classes: Dictionary = info().get("classes", {})
	if not classes.has(c):
		c = "warrior"
	var best := 0
	for t in classes[c].get(b, [0]):
		if int(t) <= tier and int(t) > best:
			best = int(t)
	return "%s/outfit_%s%s" % [b, c, ("_t%d" % best) if best > 0 else ""]

## A dark-to-light ramp from the game's 5-tone colour rows (light first).
static func _ramp(row: Array) -> PackedColorArray:
	var out := PackedColorArray()
	for i in range(row.size() - 1, -1, -1):
		out.append(Color(row[i]))
	return out

static func _shade(ramp: PackedColorArray, i: int) -> Color:
	var t := float(i - 1) / 254.0 * float(ramp.size() - 1)
	var k := mini(int(t), ramp.size() - 2)
	return ramp[k].lerp(ramp[k + 1], t - k)

## Lays one layer sheet over `dst` (same size), recolouring indexed skin/hair pixels.
## only_hair: copy just the hair pixels (the hair goes over the face on the portrait).
## cells: [first, end) cell range to copy (only what's needed: battle or portrait).
static func _lay(dst: PackedByteArray, src_path: String, skin: PackedColorArray, hair: PackedColorArray, cells: Vector2i, only_hair := false, x0 := 0) -> void:
	var src := _img(src_path + ".png")
	if src == null:
		return
	var idx := _img(src_path + "_idx.png")
	var sd := src.get_data()
	var id := idx.get_data() if idx != null else PackedByteArray()
	var iw := 3 if idx != null and idx.get_format() == Image.FORMAT_RGB8 else 4
	var sw := src.get_width()
	var dw := CELL * 9
	var luts := [_lut(skin), _lut(hair)]
	var xa := maxi(0, cells.x * CELL - x0)
	var xb := mini(sw, cells.y * CELL - x0)
	for y in src.get_height():
		for x in range(xa, xb):
			var si := (y * sw + x) * 4
			if sd[si + 3] == 0:
				continue
			var s := 0
			var h := 0
			if not id.is_empty():
				s = id[(y * sw + x) * iw]
				h = id[(y * sw + x) * iw + 1]
			if only_hair and h == 0:
				continue
			var di := (y * dw + x + x0) * 4
			if h > 0 and not hair.is_empty():
				var c: PackedByteArray = luts[1]
				dst[di] = c[h * 3]; dst[di + 1] = c[h * 3 + 1]; dst[di + 2] = c[h * 3 + 2]
			elif s > 0 and not skin.is_empty():
				var c: PackedByteArray = luts[0]
				dst[di] = c[s * 3]; dst[di + 1] = c[s * 3 + 1]; dst[di + 2] = c[s * 3 + 2]
			else:
				dst[di] = sd[si]; dst[di + 1] = sd[si + 1]; dst[di + 2] = sd[si + 2]
			dst[di + 3] = 255

static var _luts := {}
## 256 shades of a ramp as bytes (built once per ramp).
static func _lut(ramp: PackedColorArray) -> PackedByteArray:
	if ramp.is_empty():
		return PackedByteArray()
	var k := str(ramp)
	if not _luts.has(k):
		var b := PackedByteArray()
		b.resize(256 * 3)
		for i in range(1, 256):
			var c := _shade(ramp, i)
			b[i * 3] = c.r8; b[i * 3 + 1] = c.g8; b[i * 3 + 2] = c.b8
		_luts[k] = b
	return _luts[k]

## Builds (once) the frames of a hero. Returns {"img": [9 Images], "tex": [...], "white": [...]}
## (null for the cells not asked for). back: the battle frames 0-6, else the portrait frames 7-8.
static func frames(app: Dictionary, cls: String, tier: int, weapon: String, back := true) -> Dictionary:
	var b := body_key(app)
	var key := "%s|%s|%d|%s|%s" % [str(app), cls, tier, weapon, back]
	var cells := Vector2i(0, 7) if back else Vector2i(7, 9)
	if _built.has(key):
		return _built[key]
	var sk: Array = Sprites.skins()
	var hc: Array = Sprites.hair_colors()
	var skin := _ramp(sk[clampi(int(app.get("skin", 1)), 0, sk.size() - 1)])
	var hair := _ramp(hc[clampi(int(app.get("hair_color", 1)), 0, hc.size() - 1)])
	var data := PackedByteArray()
	data.resize(CELL * 9 * CELL * 4)
	_lay(data, outfit_key(cls, tier, b), skin, hair, cells)
	var head := "%s/hair_%s" % [b, style_key(app)]
	_lay(data, head, skin, hair, cells)
	var face := str(app.get("face", "neutral"))
	if not face in FACES:
		face = "neutral"
	if not back:
		_lay(data, "%s/face_%s" % [b, face], skin, hair, cells, false, PORTRAIT[0] * CELL)
		_lay(data, head, skin, hair, cells, true)  # the hair (bangs) stays over the face
	var w := WEAPON_AS.get(weapon, weapon) as String
	if w != "" and w in info().get("weapons", []):
		_lay(data, "%s/weapon_%s" % [b, w], PackedColorArray(), PackedColorArray(), cells)
	var sheet := Image.create_from_data(CELL * 9, CELL, false, Image.FORMAT_RGBA8, data)
	var out := {"img": [], "tex": [], "white": []}
	for i in 9:
		if i < cells.x or i >= cells.y:
			out["img"].append(null); out["tex"].append(null); out["white"].append(null)
			continue
		var im := sheet.get_region(Rect2i(i * CELL, 0, CELL, CELL))
		out["img"].append(im)
		out["tex"].append(ImageTexture.create_from_image(im))
		out["white"].append(ImageTexture.create_from_image(Sprites._silhouette(im)))
	_built[key] = out
	return out

## The frames as the battle's animation table (same shape as Lpc.build()["anims"]): every attack name
## plays the one swing, "hurt" is the hit frame. "foot": the feet row inside a cell.
static func anims(fr: Dictionary, back: bool) -> Dictionary:
	var pick := func(ids: Array, fps: float) -> Dictionary:
		var a := {"img": [], "tex": [], "white": [], "size": CELL, "fps": fps}
		for i in ids:
			a["img"].append(fr["img"][i]); a["tex"].append(fr["tex"][i]); a["white"].append(fr["white"][i])
		return a
	if not back:
		return {"combat_idle": pick.call(PORTRAIT, 2.0)}
	var swing: Dictionary = pick.call(ATTACK, ATTACK_FPS)
	return {"combat_idle": pick.call(IDLE, 2.0), "slash": swing, "thrust": swing, "spellcast": swing, "shoot": swing,
		"hurt": pick.call(HIT, 3.0)}

## Class and tier a game state shows (tier 15/35/75 once the line picked that far).
static func class_of(looks: Dictionary) -> Array:
	var c: Dictionary = looks.get("Class", {})
	return [str(c.get("cls", "Warrior")), int(c.get("tier", 0))]

static func clear_cache() -> void:
	_built.clear()
