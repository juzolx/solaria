class_name UiIcons
extends RefCounted
## Interface pass (claude/research/ui-research.md): icons made from the game's
## own art, on the sprites' 2x grid. Stat icons are gear pictures (art/gear,
## recoloured by Sprites like any item); the few that no item shows (heart,
## coin) are small glyphs in palette colours with the #0e0812 outline.

const INK := {"o": "#0e0812", "r": "#e43b44", "R": "#a22633", "w": "#f4e6c4", "g": "#feae34", "G": "#c8a060", "y": "#9a7040"}
const GLYPHS := {
	"heart": [".oo...oo.", "orro.oRro", "orwrorrRo", "orrrrrrRo", ".orrrrRo.", "..orrRo..", "...oRo...", "....o...."],
	"coin": [".oooo.", "ogggGo", "ogwgGo", "oggGGo", "oGGGyo", ".oooo."],
}
## Stat -> [gear picture, material] or a glyph name.
const STAT_ICON := {"STR": ["mace", "iron"], "VIT": "heart", "AGI": ["boots_masc", "leather"], "DEX": ["dagger", "steel"],
	"INT": ["tome", "leather"], "WIS": ["orb", "crystal"], "LUK": "coin", "CHA": ["pendant", "gold"]}

static var _cache := {}

## A glyph at the 2x grid.
static func glyph(glyph_name: String) -> ImageTexture:
	var key := "g" + glyph_name
	if _cache.has(key):
		return _cache[key]
	var rows: Array = GLYPHS[glyph_name]
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if INK.has(row[x]):
				img.set_pixel(x, y, Color(INK[row[x]]))
	img.resize(w * UiSkin.PX, rows.size() * UiSkin.PX, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## A gear picture in one material, trimmed to its pixels (the files are already 2x).
static func gear(type: String, mat: String) -> ImageTexture:
	var key := "e" + type + mat
	if _cache.has(key):
		return _cache[key]
	var look := {"type": type, "mat": mat, "trim": Color("#5a6988")}
	var src: Image = Sprites._layer("gear/%s.png" % type, Sprites._gear_map(look, {}))
	var tex: ImageTexture = null
	if src != null:
		var used := src.get_used_rect()
		if used.size.x > 0:
			tex = ImageTexture.create_from_image(src.get_region(used))
	_cache[key] = tex
	return tex

static func stat(st: String) -> Texture2D:
	var spec = STAT_ICON.get(st, "coin")
	if spec is String:
		return glyph(spec)
	return gear(spec[0], spec[1])

## An empty slot's ghost: the slot's usual item as one dark slate shape (Moonlighter-style).
static func ghost(tex: Texture2D) -> ImageTexture:
	if tex == null:
		return null
	var key := "h" + str(tex.get_rid())
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.01:
				img.set_pixel(x, y, UiSkin.SLATE)
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out

## The stone plinth the hero stands on (ink outline, lit slate top), w art px wide.
static func plinth(w: int) -> ImageTexture:
	var key := "p%d" % w
	if _cache.has(key):
		return _cache[key]
	var h := w / 5
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2((w - 1) / 2.0, (h - 1) / 2.0)
	for y in h:
		for x in w:
			var d := pow((x - c.x) / (w / 2.0), 2) + pow((y - c.y) / (h / 2.0), 2)
			if d > 1.0:
				continue
			var col := Color("#262b44")
			if d > 0.78:
				col = UiSkin.SOOT
			elif y < c.y - h * 0.15:
				col = Color("#3a4466")   # the lit top-left rim
			if d < 0.3:
				col = Color("#181425")   # the hero's shadow
			img.set_pixel(x, y, col)
	img.resize(w * UiSkin.PX, h * UiSkin.PX, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

## Icons read best at twice the grid on a phone (each art pixel 4x4 design px,
## still whole pixels). Trims empty space first; falls back to 1x if 2x won't fit.
static func big(tex: Texture2D, max_side := 9999) -> Texture2D:
	if tex == null:
		return null
	var key := "b%s_%d" % [str(tex.get_rid()), max_side]
	if _cache.has(key):
		return _cache[key]
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	var used := img.get_used_rect()
	if used.size.x > 0:
		img = img.get_region(used)
	if img.get_width() * 2 <= max_side and img.get_height() * 2 <= max_side:
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var out := ImageTexture.create_from_image(img)
	_cache[key] = out
	return out
