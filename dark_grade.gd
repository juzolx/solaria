class_name DarkGrade
extends RefCounted
## The dark fantasy look: grades monster, pet and background art as it loads.
## The PNGs stay untouched; the graded copy is made once and cached.
## Bright, saturated pixels (fire, magic, eyes) keep their color so they glow,
## and sprites get a faint cold rim light so dark monsters still read on a phone.
## Hero layers are never graded here: they are color-key masks (see sprites.gd).

const SPRITE := 1.0    # full strength for monsters, bosses and pets
const SCENE := 0.85    # a bit gentler for backgrounds (the UI sits on top of them)
const NATIVE := 0.0    # redrawn monsters: already dark and muted, so no grade (only the rim light)
const RIM := Color(0.11, 0.12, 0.16)  # moonlight on top/left edges
const SHADOW_TINT := Color(0.82, 0.88, 1.12)
const LIGHT_TINT := Color(1.0, 0.95, 0.86)

static var enabled := true
static var _textures := {}

## A graded copy of an image (or the image itself when the grade is off).
## rim_strength: how strong the rim light is (default: the grade's own strength).
static func image(src: Image, strength := SPRITE, rim := true, rim_strength := -1.0) -> Image:
	if not enabled or src == null:
		return src
	var img := src.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var out := data.duplicate()
	var rs := strength if rim_strength < 0.0 else rim_strength
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			if data[i + 3] == 0:
				continue
			var raw := Color8(data[i], data[i + 1], data[i + 2])
			if ArtStyle.is_outline(raw):
				continue  # the baked outline stays the same dark everywhere
			var c := _grade(raw, strength, rim)
			if rim:
				c = _rim(data, w, h, x, y, c, rs)
			out[i] = clampi(int(c.r * 255.0 + 0.5), 0, 255)
			out[i + 1] = clampi(int(c.g * 255.0 + 0.5), 0, 255)
			out[i + 2] = clampi(int(c.b * 255.0 + 0.5), 0, 255)
	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)

## Loads a texture by path and grades it (cached). Returns null if the file is missing.
static func texture(path: String, strength := SPRITE, rim := true) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	if not enabled:
		return load(path)
	var key := "%s|%.2f|%s" % [path, strength, rim]
	if not _textures.has(key):
		var tex: Texture2D = load(path)
		_textures[key] = ImageTexture.create_from_image(image(tex.get_image(), strength, rim)) if tex else null
	return _textures[key]

## Turns the grade on or off and forgets every graded picture so screens rebuild with the new look.
static func set_enabled(on: bool) -> void:
	if on == enabled:
		return
	enabled = on
	_textures.clear()
	Sprites.clear_monster_cache()
	Pets.clear_cache()

## sprite: small art where any bright color is a glow; on backgrounds only true highlights
## (candles, lava, sparkles) are, so big bright areas like the sea still darken.
static func _grade(c: Color, s: float, sprite: bool) -> Color:
	var l := c.get_luminance()
	# How much this pixel glows: bright and colorful pixels keep their punch
	var glow := smoothstep(0.75, 0.95, c.v) * smoothstep(0.45, 0.8, c.s) if sprite else smoothstep(0.9, 1.0, c.v) * smoothstep(0.55, 0.85, c.s) * smoothstep(0.62, 0.8, 1.0 - c.b + c.r * 0.5)
	var keep := 1.0 - glow
	var g := c.lerp(Color(l, l, l), (0.35 if sprite else 0.55) * s * keep)
	var gamma := 1.0 + 0.2 * s * keep
	g = Color(pow(g.r, gamma), pow(g.g, gamma), pow(g.b, gamma))
	g = g.lerp(g * SHADOW_TINT, (1.0 - l) * (0.45 if sprite else 0.3) * s)
	g = g.lerp(g * LIGHT_TINT, l * 0.3 * s * keep)
	if not sprite:
		g = g * (1.0 - 0.18 * s * keep)  # backgrounds sit a little further back
	return g

## Lifts pixels just inside the top and left edges (2-4 px in, past the dark outline).
static func _rim(data: PackedByteArray, w: int, h: int, x: int, y: int, c: Color, s: float) -> Color:
	if _clear(data, w, h, x, y - 1) or _clear(data, w, h, x - 1, y):
		return c  # the outline itself stays dark
	var hit := 0.0
	for d in range(2, 5):
		if _clear(data, w, h, x, y - d):
			hit = maxf(hit, 1.0 - (d - 2) * 0.3)
		if _clear(data, w, h, x - d, y):
			hit = maxf(hit, 0.7 - (d - 2) * 0.25)
	if hit <= 0.0:
		return c
	return Color(c.r + RIM.r * hit * s, c.g + RIM.g * hit * s, c.b + RIM.b * hit * s)

static func _clear(data: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return true
	return data[(y * w + x) * 4 + 3] < 8
