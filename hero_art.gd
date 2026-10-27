class_name HeroArt
extends RefCounted
## The PixelLab hero (2.1): layers baked by claude/art_test/pixellab/game/bake.py into art/heroes/.
## Every layer is drawn on the same 9 frames, each a 96x96 cell (sheets: cells side by side):
##   0-1 idle, 2-5 attack, 6 hit  (battle, seen from behind)    7-8 portrait idle (front)
## A hero = body + class outfit (by class and tier) + head with the hair style + face (portrait)
## + the equipped weapon type in the hand. Skin and hair colours come from the creator's ramps:
## each layer's index sheet holds the original shade of every skin (R) and hair (G) pixel.
## The weapon sheets have bigger cells (FRAME: the body cell PAD in from each side), so a staff or spear
## in the swing is never cut by the body cell; a built frame is FRAME x FRAME with the body cell centred.
## Armour no longer changes the look. Built once per look and cached (never per frame).

const DIR := "res://art/heroes/"
const CELL := 96
const PAD := 16
const FRAME := CELL + 2 * PAD
const FOOT := 80  # the feet row inside a body cell
const CORE := 64   # the character's own frame inside the cell (portraits and the hero canvas centre on it)
const IDLE := [0, 1]
const ATTACK := [2, 3, 4, 5]
const HIT := [6]
const PORTRAIT := [7, 8]
const WEAPON_BEHIND := [4]  # the mid-swing crosses the hero's back: drawn under the head (Fable hero R2 item 1)
const ATTACK_FPS := 9.0
const BUILT_MAX := 24  # looks kept built (the class cards build 13 at once)
const SHEETS_MAX := 24  # decoded layer sheets kept between builds (~10 MB at most)
## The 10 faces Juzo picked (the creator's "Face" row).
const FACES := ["neutral", "smile", "laughing", "determined", "fierce", "grim", "wary", "surprised", "sleepy", "battle_cry"]
const FACE_NAMES := ["Calm", "Smile", "Laugh", "Determined", "Fierce", "Grim", "Wary", "Surprised", "Sleepy", "Battle cry"]
## Weapon types without their own drawing are held as the closest one.
const WEAPON_AS := {"orb": "staff", "tome": "staff", "wand": "staff", "fist": ""}
## Races on the standard body get a signature layer (heroes.json "races"); the other builds
## (Goblin, Dwarf, Orc, Werewolf, Fairy) use the human body with their skin tones until drawn.

static var _info := {}
static var _imgs := {}
static var _sheet_order: Array[String] = []  # decoded layers, oldest first
static var _misses := {}  # layers that are missing or empty
static var _built := {}
static var _order: Array = []  # built looks, oldest first

static func info() -> Dictionary:
	if _info.is_empty() and FileAccess.file_exists(DIR + "heroes.json"):
		_info = JSON.parse_string(FileAccess.get_file_as_string(DIR + "heroes.json"))
	return _info

static func available() -> bool:
	return not info().is_empty()

## A layer sheet as RGBA8 (null if missing). Not cached: see _sheet.
static func _img(path: String) -> Image:
	if not ResourceLoader.exists(DIR + path):
		return null
	var tex: Texture2D = load(DIR + path)
	if tex == null:
		return null
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

## A decoded layer (its sheet and index sheet as one entry), kept between builds: the bytes, width, cell
## size and each cell's used rect (only those pixels are walked). {} if missing or every cell is empty
## (remembered as a miss). The oldest entry goes first when full.
static func _sheet(path: String) -> Dictionary:
	if _imgs.has(path):
		return _imgs[path]
	var out := {}
	var img := _img(path + ".png")
	if img != null:
		var n := img.get_height()
		var used := []
		var any := false
		for c in img.get_width() / n:
			var r := img.get_region(Rect2i(c * n, 0, n, n)).get_used_rect()
			used.append(r)
			any = any or r.has_area()
		if any:
			var ix := _img(path + "_idx.png")
			out = {"data": img.get_data(), "idx": ix.get_data() if ix != null else PackedByteArray(),
				"w": img.get_width(), "n": n, "rects": used}
	if out.is_empty():
		_misses[path] = true
		return out
	_imgs[path] = out
	_sheet_order.append(path)
	if _sheet_order.size() > SHEETS_MAX:
		_imgs.erase(_sheet_order.pop_front())
	return out

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

## Lays one layer sheet over `dst` (9 frames of FRAME x FRAME), recolouring indexed skin/hair pixels.
## A body sheet's 96 cells land PAD in; a weapon sheet's cells are already FRAME wide.
## only_hair: copy just the hair pixels (the hair goes over the face on the portrait).
## cells: [first, end) frames to fill (only what's needed: battle or portrait).
## first: the frame the sheet's first cell is (the face sheets hold only the portrait frames).
## dye: the class colour for a body build's family outfit (index blue channel).
## lift: rows to draw the layer higher (negative: lower).
static func _lay(dst: PackedByteArray, src_path: String, skin: PackedColorArray, hair: PackedColorArray, cells: Vector2i, only_hair := false, first := 0, dye := PackedColorArray(), lift := 0, lift_s := 0) -> void:
	if _misses.has(src_path):
		return
	var src := _sheet(src_path)
	if src.is_empty():
		return
	var sd: PackedByteArray = src["data"]
	var id: PackedByteArray = src["idx"]
	var sw: int = src["w"]
	var n: int = src["n"]
	var rects: Array = src["rects"]
	var off := (FRAME - n) / 2
	var dw := FRAME * 9
	var luts := [_lut(skin), _lut(hair), _lut(dye)]
	for f in range(maxi(cells.x, first), cells.y):
		var ci := f - first
		if ci >= rects.size():
			break
		var r: Rect2i = rects[ci]
		var lf := lift_s if f >= 7 else lift  # the portrait frames (7, 8) have their own
		for y in range(maxi(r.position.y, lf - off), mini(r.end.y, FRAME - off + lf)):
			var row := y * sw + ci * n
			var drow := (y + off - lf) * dw + f * FRAME + off
			for x in range(r.position.x, r.end.x):
				var si := (row + x) * 4
				if sd[si + 3] == 0:
					continue
				var s := 0
				var h := 0
				var dy := 0
				if not id.is_empty():
					s = id[si]
					h = id[si + 1]
					dy = id[si + 2]
				if only_hair and h == 0:
					continue
				var di := (drow + x) * 4
				if h > 0 and not hair.is_empty():
					var c: PackedByteArray = luts[1]
					dst[di] = c[h * 3]; dst[di + 1] = c[h * 3 + 1]; dst[di + 2] = c[h * 3 + 2]
				elif s > 0 and not skin.is_empty():
					var c: PackedByteArray = luts[0]
					dst[di] = c[s * 3]; dst[di + 1] = c[s * 3 + 1]; dst[di + 2] = c[s * 3 + 2]
				elif dy > 0 and not dye.is_empty():
					var c: PackedByteArray = luts[2]
					dst[di] = c[dy * 3]; dst[di + 1] = c[dy * 3 + 1]; dst[di + 2] = c[dy * 3 + 2]
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

## Builds (once) the frames of a hero. Returns {"img": [9 Images], "tex": [...], "white": [...]}, each
## FRAME x FRAME (null for the frames not asked for). back: the battle frames 0-6, else the portrait 7-8.
static func frames(app: Dictionary, cls: String, tier: int, weapon: String, back := true) -> Dictionary:
	var b := body_key(app)
	var key := "%s|%s|%d|%s|%s" % [str(look_key(app, back)), cls, tier, weapon, back]
	var cells := Vector2i(0, 7) if back else Vector2i(7, 9)
	if _built.has(key):
		return _built[key]
	var sk: Array = Sprites.skins()
	var hc: Array = Sprites.hair_colors()
	var skin := _ramp(sk[clampi(int(app.get("skin", 1)), 0, sk.size() - 1)])
	var hair := _ramp(hc[clampi(int(app.get("hair_color", 1)), 0, hc.size() - 1)])
	var data := PackedByteArray()
	data.resize(FRAME * 9 * FRAME * 4)
	var build := build_dir(app)
	_lay_weapon(data, build if build != "" else b, weapon, cells, true)
	if build != "":
		var br := build_race(app)
		# another body build (goblin, dwarf...): its own drawn head, the class's outfit family dyed in the class colour
		var fams: Array = info()["builds"][br]["bodies"][b]
		var fam := str(info().get("family_of", {}).get(cls, "plate"))
		if not fam in fams:
			fam = str(fams[0])
		# the class colour, darkened and muted to sit in the dark palette like the drawn outfits
		var cc := Color(Classes.info(cls).get("color", "#8b9bb4"))
		var dye := _dye_ramp(cc)
		var drawn: Array = info().get("dye", {}).get(cls.to_lower(), [])
		if not drawn.is_empty():  # the class's own drawn outfit colour (bake.py), so a goblin mage matches a human one
			dye = PackedColorArray()
			for h in drawn:
				dye.append(Color(h))
		# goblins keep their drawn yellow-green skin (their own hue family); dwarves take the skin choice
		var bd: Dictionary = info()["builds"][br]
		var bskin := skin if bool(bd.get("skin", true)) else PackedColorArray()
		if bd.has("skin_ramp"):
			bskin = _ramp(bd["skin_ramp"])  # the werewolf's grey, matching its fur
		# a race drawn over another build (the werewolf's wolf head, fur and tail on the orc)
		var feat := str(bd.get("feature", ""))
		if feat != "":
			feat = _looked("%s/%s" % [build, feat], app).get_file()  # the fairy's bigger wings once awakened
			_lay(data, "%s/%s_back" % [build, feat], PackedColorArray(), PackedColorArray(), cells)
		_lay(data, "%s/outfit_%s" % [build, fam], bskin, hair, cells, false, 0, dye)
		if not _armed(weapon):
			_open_hand(data, build, cells)
		if feat != "":  # over the body's back in battle (the fairy's wings grow from it)
			_lay(data, "%s/%s" % [build, feat], PackedColorArray(), PackedColorArray(), cells)
		if bool(bd.get("hair", false)):  # the creator's hair style, fitted to the build's head (bake.py)
			_lay(data, "%s/hair_%s" % [build, style_key(app)], bskin, hair, cells)
		_lay_look(data, build, app, cells)
		var btop := _head_top(data, cells)
		_lay_weapon(data, build, weapon, cells, false)
		var breath: bool = not back or b == "f" or build in info().get("breath", [])  # one drawn idle or portrait pose
		var glow := _glow(app)
		if glow.a == 0.0 and br != art_race(app):  # a Lich dwarf: the dwarf, outlined in the form's colour
			glow = Color(Races.FORMS.get(art_race(app), {}).get("color", "#7fd0f0"), 0.75)
		return _sourced(_finish(key, data, cells, glow, breath, btop), build, weapon)
	var race := race_key(app, b)
	if race != "":
		race = _looked(race, app)  # an awakening's variant of the race layer (a second pair of wings...)
		_lay(data, race + "_back", skin, hair, cells)  # wings / tail behind the body on the portrait
	_lay(data, outfit_key(cls, tier, b), skin, hair, cells)
	if not _armed(weapon):
		_open_hand(data, b, cells)
	var head := "%s/hair_%s" % [b, style_key(app)]
	_lay(data, head, skin, hair, cells)
	var face := str(app.get("face", "neutral"))
	if not face in FACES:
		face = "neutral"
	if not back:
		_lay(data, "%s/face_%s" % [b, face], skin, hair, cells, false, PORTRAIT[0])
		_lay(data, head, skin, hair, cells, true)  # the hair (bangs) stays over the face
	if race != "":
		_lay(data, race, skin, hair, cells)  # ears, horns, halo, wings from behind...
	_lay_look(data, b, app, cells)
	var top := _head_top(data, cells)
	_lay_weapon(data, b, weapon, cells, false)
	# her second idle and second portrait are drawn 2 px over: both made from the first (no hop; R3 neck check)
	return _sourced(_finish(key, data, cells, _glow(app), b == "f", top), b, weapon)

## The highest drawn row of the idle (or portrait) pair before the weapon goes on: the head's top, where the
## companion bar sits (a fairy's raised mace put it 10 rows over her hair: Fable hero R4 item 9).
static func _head_top(data: PackedByteArray, cells: Vector2i) -> int:
	var pair: Array = IDLE if cells.x == 0 else PORTRAIT
	var dw := FRAME * 9
	for y in FRAME:
		for f in pair:
			var row := (y * dw + int(f) * FRAME) * 4
			for x in FRAME:
				if data[row + x * 4 + 3] > 0:
					return y
	return FRAME

## The frames whose weapon hand opens when nothing is held (idle, hit, portrait); a swing stays a fist (a punch).
const OPEN_HAND := [0, 1, 6, 7, 8]

static func _armed(weapon: String) -> bool:
	var w := WEAPON_AS.get(weapon, weapon) as String
	return w != "" and w in info().get("weapons", [])

## Unarmed, the weapon hand (drawn clenched round a grip) becomes the free hand mirrored about the body's
## centre column (heroes.json "axis"): Juzo saw a fist holding nothing at the hip on the Gear page.
static func _open_hand(data: PackedByteArray, dir: String, cells: Vector2i) -> void:
	var ax: Array = info().get("axis", {}).get(dir, [])
	var hs: Array = info().get("hand", {}).get(dir, [])
	if ax.size() < 9 or hs.size() < 9:
		return
	var dw := FRAME * 9
	for f in range(cells.x, cells.y):
		if not f in OPEN_HAND:
			continue
		var a := float(ax[f]) + PAD
		var hx := int(hs[f][0]) + PAD
		var hy := int(hs[f][1]) + PAD
		for y in range(maxi(0, hy - 7), mini(FRAME, hy + 6)):
			for x in range(maxi(0, hx - 7), mini(FRAME, hx + 8)):
				var mx := roundi(2.0 * a - x)
				if absf(x - a) < 4.0 or mx < 0 or mx >= FRAME:
					continue  # the body's middle stays as drawn
				var i := (y * dw + f * FRAME + x) * 4
				var j := (y * dw + f * FRAME + mx) * 4
				for k in 4:
					data[i + k] = data[j + k]

## Where a look's weapon comes from, for its glow (weapon_white).
static func _sourced(fr: Dictionary, dir: String, weapon: String) -> Dictionary:
	fr["wsrc"] = {"dir": dir, "weapon": weapon}
	return fr

## The weapon alone as white silhouettes, one per frame of an animation (anims): a legendary weapon's glow
## outlines the weapon, not the whole hero (Fable hero R3 item 11). Built the first time a glow asks.
static func weapon_white(an: Dictionary) -> Array:
	if an.has("wwhite"):
		return an["wwhite"]
	var src: Dictionary = an.get("wsrc", {})
	var ids: Array = an.get("ids", [])
	var out := []
	if src.is_empty() or ids.is_empty():
		an["wwhite"] = out
		return out
	var data := PackedByteArray()
	data.resize(FRAME * 9 * FRAME * 4)
	var span := Vector2i(int(ids.min()), int(ids.max()) + 1)
	_lay_weapon(data, src["dir"], src["weapon"], span, true)
	_lay_weapon(data, src["dir"], src["weapon"], span, false)
	var sheet := Image.create_from_data(FRAME * 9, FRAME, false, Image.FORMAT_RGBA8, data)
	for i in ids:
		var white := Sprites._silhouette(sheet.get_region(Rect2i(int(i) * FRAME, 0, FRAME, FRAME)))
		white.convert(Image.FORMAT_LA8)
		out.append(ImageTexture.create_from_image(white))
	an["wwhite"] = out
	return out

## The creator fields a hero picture shows (the back view has no face), so stepping through faces or any
## other field never rebuilds the battle frames.
const LOOK_FIELDS := ["body", "race", "form", "look", "skin", "hair", "hair_color"]
static func look_key(app: Dictionary, back: bool) -> Dictionary:
	var k := {}
	for f in LOOK_FIELDS:
		k[f] = app.get(f)
	if not back:
		k["face"] = app.get("face")
	return k

## A race layer as an awakening wears it: "m/race_angel" -> "m/race_angel__wings2" when that variant is baked.
static func _looked(layer: String, app: Dictionary) -> String:
	var look := str(app.get("look", ""))
	if look != "" and ResourceLoader.exists(DIR + layer + "__" + look + ".png"):
		return layer + "__" + look
	return layer

## The rows a crown may move from where it sits (down, up): bake.py LIFT (a bald dwarf's -21 put it on his beard).
const LIFT := Vector2i(-3, 8)

## A look drawn over any head (the crown).
static func _lay_look(data: PackedByteArray, dir: String, app: Dictionary, cells: Vector2i) -> void:
	var look := str(app.get("look", ""))
	if look != "" and ResourceLoader.exists(DIR + "%s/look_%s.png" % [dir, look]):
		var lift := 0
		var lift_s := 0
		if look == "crown":  # it sits on short hair: taller or flatter styles move it (bake.py crown_lifts)
			var bd: Dictionary = info().get("builds", {}).get(build_race(app), {})
			if dir in ["m", "f"] or bool(bd.get("hair", false)):
				lift = crown_lift(dir, style_key(app))
				lift_s = crown_lift(dir, style_key(app), true)
		_lay(data, "%s/look_%s" % [dir, look], PackedColorArray(), PackedColorArray(), cells, false, 0, PackedColorArray(), lift, lift_s)

## Rows the crown moves on a style, in battle or (portrait) on the portrait frames (heroes.json crown_lift(_s)).
static func crown_lift(dir: String, style: String, portrait := false) -> int:
	var key := "crown_lift_s" if portrait and info().has("crown_lift_s") else "crown_lift"
	return clampi(int(info().get(key, {}).get(dir, {}).get(style, 0)), LIFT.x, LIFT.y)

## The "glow" awakening: a soft outline in the race colour (clear when the hero has none).
static func _glow(app: Dictionary) -> Color:
	if str(app.get("look", "")) != "glow":
		return Color(0, 0, 0, 0)
	return Color(Races.info(str(app.get("race", "Human"))).get("color", "#e8b14a"), 0.75)

## behind: the frames whose weapon passes in front of the hero seen from behind (WEAPON_BEHIND), laid first so
## the head and body cover it; else every other frame, laid last.
static func _lay_weapon(data: PackedByteArray, dir: String, weapon: String, cells: Vector2i, behind: bool) -> void:
	var w := WEAPON_AS.get(weapon, weapon) as String
	if w == "" or not w in info().get("weapons", []):
		return
	var path := "%s/weapon_%s" % [dir, w]
	var start := cells.x
	for f in WEAPON_BEHIND:
		if f < cells.x or f >= cells.y:
			continue
		if behind:
			_lay(data, path, PackedColorArray(), PackedColorArray(), Vector2i(f, f + 1))
		else:
			_lay(data, path, PackedColorArray(), PackedColorArray(), Vector2i(start, f))
			start = f + 1
	if not behind:
		_lay(data, path, PackedColorArray(), PackedColorArray(), Vector2i(start, cells.y))

## Her second battle idle, made from the first: the drawn one stood 2 px taller and 2 px over, so the whole
## torso jumped every half second. This one only lets the upper body sink 1 px (a breath).
static func _breath(im: Image) -> Image:
	var bb := im.get_used_rect()
	var out := im.duplicate() as Image
	var waist := bb.position.y + int(bb.size.y * 0.55)
	for y in range(waist, bb.position.y - 1, -1):
		for x in range(bb.position.x, bb.end.x):
			out.set_pixel(x, y, im.get_pixel(x, y - 1) if y > 0 else Color(0, 0, 0, 0))
	return out

static func _finish(key: String, data: PackedByteArray, cells: Vector2i, glow := Color(0, 0, 0, 0), breath := false, top := -1) -> Dictionary:
	if glow.a > 0.0:
		_outline(data, cells, glow)
	var sheet := Image.create_from_data(FRAME * 9, FRAME, false, Image.FORMAT_RGBA8, data)
	var out := {"img": [], "tex": [], "white": [], "top": FRAME}
	var pair: Array = IDLE if cells.x == 0 else PORTRAIT
	var first: Image = null
	for i in 9:
		if i < cells.x or i >= cells.y:
			out["img"].append(null); out["tex"].append(null); out["white"].append(null)
			continue
		var im := sheet.get_region(Rect2i(i * FRAME, 0, FRAME, FRAME))
		if breath and i == pair[1]:  # the second pose made from the first: one drawing, no jump cut
			im = _breath(first)
		if i in pair:  # the head's top row (companion bars sit on it: a fairy's is 17 rows under a human's)
			first = im if first == null else first
			var r := im.get_used_rect()
			if r.size.y > 0 and top < 0:
				out["top"] = mini(int(out["top"]), r.position.y)
			elif top >= 0:
				out["top"] = top
		# Images are kept only where something reads them: the first battle idle (Sprites.hero's still) and
		# the portrait pair (portrait_frames, the town walkers); the rest live as textures (Fable hero R3 item 15)
		out["img"].append(im if i in PORTRAIT or i == IDLE[0] else null)
		out["tex"].append(ImageTexture.create_from_image(im))
		var white := Sprites._silhouette(im)
		white.convert(Image.FORMAT_LA8)  # white + alpha: a quarter of the RGBA texture (drawn with a modulate)
		out["white"].append(ImageTexture.create_from_image(white))
	_built[key] = out
	_order.append(key)
	if _order.size() > BUILT_MAX:
		_built.erase(_order.pop_front())
	return out

## A 1-px outline of colour c around everything drawn in the frames (the glow awakening).
static func _outline(data: PackedByteArray, cells: Vector2i, c: Color) -> void:
	var dw := FRAME * 9
	var src := data.duplicate()
	for f in range(cells.x, cells.y):
		for y in range(1, FRAME - 1):
			for x in range(f * FRAME + 1, (f + 1) * FRAME - 1):
				var i := (y * dw + x) * 4
				if src[i + 3] != 0:
					continue
				if src[i + 7] != 0 or src[i - 1] != 0 or src[i + dw * 4 + 3] != 0 or src[i - dw * 4 + 3] != 0:
					data[i] = c.r8; data[i + 1] = c.g8; data[i + 2] = c.b8; data[i + 3] = c.a8

## The frames as the battle's animation table (Sprites.hero()["anims"]): every attack name
## plays the one swing, "hurt" is the hit frame. "foot": the feet row inside a frame.
static func anims(fr: Dictionary, back: bool) -> Dictionary:
	var pick := func(ids: Array, fps: float) -> Dictionary:
		var a := {"img": [], "tex": [], "white": [], "size": FRAME, "foot": FOOT + PAD, "fps": fps, "ids": ids,
			"top": int(fr.get("top", 37)), "wsrc": fr.get("wsrc", {})}
		for i in ids:
			a["img"].append(fr["img"][i]); a["tex"].append(fr["tex"][i]); a["white"].append(fr["white"][i])
		return a
	if not back:
		return {"combat_idle": pick.call(PORTRAIT, 2.0)}
	var swing: Dictionary = pick.call(ATTACK, ATTACK_FPS)
	return {"combat_idle": pick.call(IDLE, 2.0), "slash": swing, "thrust": swing, "spellcast": swing, "shoot": swing,
		"hurt": pick.call(HIT, 3.0)}

## Two walk steps made from a finished frame (the town walkers): the leg band (bottom 22% of the body)
## is split at its middle and one side lifted and swung 2 px forward (the frame faces right), left
## then right; the body above the legs rises 2 px on a step (1 map px once the town halves it), so
## the walker bobs instead of shortening a leg. No drawn walk cycle needed.
static func steps(im: Image) -> Array:
	var bb := im.get_used_rect()
	if bb.size.y < 8:
		return [im, im]
	var top := bb.end.y - int(bb.size.y * 0.22)
	var sx := 0
	var n := 0
	for y in range(top, bb.end.y):
		for x in range(bb.position.x, bb.end.x):
			if im.get_pixel(x, y).a > 0.0:
				sx += x; n += 1
	var cx := sx / maxi(n, 1)
	var lift := maxi(2, roundi(bb.size.y * 0.06))
	const BOB := 2
	const FWD := 2
	var clear := Color(0, 0, 0, 0)
	var out := []
	for side in [0, 1]:
		var st := Image.create(im.get_width(), im.get_height(), false, im.get_format())
		# the body rises; the hips stretch down over the gap so nothing opens up
		for y in range(maxi(0, bb.position.y - BOB), top):
			for x in range(bb.position.x, bb.end.x):
				st.set_pixel(x, y, im.get_pixel(x, mini(y + BOB, bb.end.y - 1)))
		var xa := bb.position.x if side == 0 else cx
		var xb := cx if side == 0 else bb.end.x
		for y in range(top, bb.end.y):
			for x in range(bb.position.x, bb.end.x):
				if x >= xa and x < xb:
					continue
				st.set_pixel(x, y, im.get_pixel(x, y))   # the planted leg as it is
		for y in range(top, bb.end.y):                  # the lifted leg, swung forward
			for x in range(xa, mini(xb + FWD, im.get_width())):
				var s := Vector2i(x - FWD, y + lift)
				var c := im.get_pixel(s.x, s.y) if s.x >= xa and s.x < xb and s.y < bb.end.y else clear
				if c.a > 0.0 or (x < xb and st.get_pixel(x, y).a == 0.0):
					st.set_pixel(x, y, c)
		out.append(st)
	return out

## A dark-to-light ramp of one class colour, kept in its own hue (the hue-shifted creator ramps turn
## light reds khaki) and pulled down into the game's dark palette.
static func _dye_ramp(c: Color) -> PackedColorArray:
	var out := PackedColorArray()
	for v in [0.16, 0.26, 0.38, 0.52, 0.66]:
		out.append(Color.from_hsv(c.h, clampf(c.s * 0.85, 0.0, 1.0), minf(c.v, 1.0) * v))
	return out

## The race whose art a hero wears: a transformation (Vampire, Werewolf, Lich) once it has its own art,
## else the race picked in the creator.
static func art_race(app: Dictionary) -> String:
	var f := str(app.get("form", ""))
	if f != "" and (info().get("builds", {}).has(f) or info().get("races", {}).has(f)):
		return f
	return Races.current(str(app.get("race", "Human")))  # an old slot summary may still say Golem

## The race whose body build a hero wears: its form when the form has one (the werewolf's orc build), else the
## race's own (a Lich dwarf stays a dwarf: Fable hero R3 item 7), else "" (the standard body).
static func build_race(app: Dictionary) -> String:
	var builds: Dictionary = info().get("builds", {})
	var ar := art_race(app)
	if builds.has(ar):
		return ar
	var r := Races.current(str(app.get("race", "Human")))
	return r if builds.has(r) else ""

## How many outfits a class has on a hero's body (the build families have one per class).
static func outfit_tiers(cls: String, app: Dictionary) -> int:
	if build_dir(app) != "":
		return 1
	return (info().get("classes", {}).get(cls.to_lower(), {}).get(body_key(app), [0]) as Array).size()

## The folder of a race's own body build ("goblin_m"), or "" when the race uses the standard body.
static func build_dir(app: Dictionary) -> String:
	var bd: Dictionary = info().get("builds", {}).get(build_race(app), {})
	var b := body_key(app)
	if bd.is_empty() or not (bd["bodies"] as Dictionary).has(b):
		return ""
	return "%s_%s" % [bd["key"], b]

## The hand points of a hero's frames (heroes.json "hand", per body or body build).
static func hands(app: Dictionary) -> Array:
	var d := build_dir(app)
	var out := []
	for h in info()["hand"][d if d != "" else body_key(app)]:
		out.append([int(h[0]) + PAD, int(h[1]) + PAD])  # in frame coordinates (the body cell sits PAD in)
	return out

## The race's signature layer ("m/race_elf"), or "" for races without one (Human, or not drawn yet).
static func race_key(app: Dictionary, b: String) -> String:
	var r := art_race(app)
	if b in (info().get("races", {}).get(r, []) as Array):
		return "%s/race_%s" % [b, r.to_lower().replace(" ", "_")]
	return ""

## Class and tier a game state shows (tier 15/35/75 once the line picked that far).
static func class_of(looks: Dictionary) -> Array:
	var c: Dictionary = looks.get("Class", {})
	return [str(c.get("cls", "Warrior")), int(c.get("tier", 0))]

static func clear_cache() -> void:
	_built.clear()
	_order.clear()
	_imgs.clear()
	_sheet_order.clear()
	_misses.clear()

## The looks of a saved hero's slot summary (GameState.meta()): 2.0 saves have no "Class" yet,
## so the class comes from the summary itself (else every old slot would show a Warrior).
static func meta_looks(meta: Dictionary) -> Dictionary:
	var looks: Dictionary = (meta.get("looks", {}) as Dictionary).duplicate()
	if not looks.has("Class") and str(meta.get("class", "")) != "":
		looks["Class"] = {"cls": str(meta["class"]), "tier": 0}
	return looks

## Which attack animation a weapon uses.
static func attack_anim(weapon_type: String) -> String:
	match weapon_type:
		"bow":
			return "shoot"
		"spear", "staff":
			return "thrust"
		_:
			return "slash"
