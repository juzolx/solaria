class_name UiSkin
extends RefCounted
## Next update (Juzo): the dark fantasy look for menus, tabs and town pages,
## following the Art Direction page: ink shadows (never grey), bone text, iron
## frames with rivets on stone, bevelled stone buttons, and one warm torch
## light. Everything is drawn here in code (no extra art packs) and cached.

const IRON := Color("#3a4466")       # frame line: slate (art/palette.gpl)
const IRON_HI := Color("#5a6988")    # the lit edge of a frame
const SOOT := Color("#0e0812")       # outlines: the same ink as the hero and monster outlines
const TORCH := Color("#f77622")      # the one warm light
const SLATE := Color("#262b44")      # raised parts: buttons, tabs
const STUD := Color("#c8a060")       # the small gold corner studs (dull gold)
const PX := 2                        # frame art is drawn at 2x, the same grid as the sprites (Sprites.HD)

static var _cache := {}

static func _key(parts: Array) -> String:
	return ",".join(parts.map(func(p): return str(p)))

## Interface pass (claude/research/ui-research.md): a quiet frame, so the art is
## the star. Ink outline, one slate line (or the accent colour for popups), a
## shadow under the top edge, and tiny gold studs in the corners.
static func frame(fill: Color, accent := IRON, margin := 12) -> StyleBoxTexture:
	var key := _key(["frame", fill.to_html(), accent.to_html(), margin])
	if _cache.has(key):
		return (_cache[key] as StyleBoxTexture).duplicate() as StyleBoxTexture  # a copy: callers may change its margins
	var n := 8   # art pixels per side
	var img := Image.create(n * PX, n * PX, false, Image.FORMAT_RGBA8)
	var line := accent
	for y in n:
		for x in n:
			var c := fill
			var ring := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var cx := x if x < n / 2 else n - 1 - x   # distance into the nearest corner
			var cy := y if y < n / 2 else n - 1 - y
			if ring == 0:
				c = SOOT
			elif ring == 1:
				c = line
			elif ring == 2 and y == 2:
				c = SOOT.lerp(fill, 0.5)   # a shadow just under the top line
			if cx <= 2 and cy <= 2:
				c = SOOT                    # the stud: a 3x3 ink block...
				if cx == 1 and cy == 1:
					c = STUD                # ...with one gold pixel
			_px(img, x, y, c)
	var st := StyleBoxTexture.new()
	st.texture = ImageTexture.create_from_image(img)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		st.set_texture_margin(side, 3 * PX)
		st.set_content_margin(side, margin)
	_cache[key] = st
	return st.duplicate() as StyleBoxTexture

## A slate block: ink outline with chipped corners, a 1 px edge in the button's
## role colour (slate, gold = selected / main action, red = danger), a lit lip
## under the top edge. Pressed: darker, no lip, text sits 1 px lower.
static func bevel(fill: Color, edge: Color, margin := 6, pressed := false) -> StyleBoxTexture:
	var key := _key(["bevel", fill.to_html(), edge.to_html(), margin, pressed])
	if _cache.has(key):
		return (_cache[key] as StyleBoxTexture).duplicate() as StyleBoxTexture  # a copy: callers may change its margins
	var n := 8
	var img := Image.create(n * PX, n * PX, false, Image.FORMAT_RGBA8)
	var face := fill if not pressed else fill.darkened(0.25)
	var lip := fill.lerp(edge, 0.35) if not pressed else face
	for y in n:
		for x in n:
			var c := face
			if x == 0 or y == 0 or x == n - 1 or y == n - 1:
				c = SOOT
				if (x == 0 or x == n - 1) and (y == 0 or y == n - 1):
					c = Color(0, 0, 0, 0)   # chipped corners
			elif x == 1 or y == 1 or x == n - 2 or y == n - 2:
				c = edge
			elif y == 2:
				c = lip
			_px(img, x, y, c)
	var st := StyleBoxTexture.new()
	st.texture = ImageTexture.create_from_image(img)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		st.set_texture_margin(side, 3 * PX)
		st.set_content_margin(side, margin + 2)
	st.set_content_margin(SIDE_TOP, margin + (2 if pressed else 0))
	_cache[key] = st
	return st.duplicate() as StyleBoxTexture

## The wall behind the menus and town pages: ink-dark stone blocks, a warm torch
## glow from above and a vignette. tint shifts it toward a region's mood.
static func backdrop(tint := Color("#181425")) -> ImageTexture:
	var key := _key(["bg", tint.to_html()])
	if _cache.has(key):
		return _cache[key]
	var w := 168
	var h := 300
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var shades := []
	for i in 400:
		shades.append(rng.randf_range(-0.035, 0.035))
	for y in h:
		var row := y / 10
		var off := 10 if row % 2 == 1 else 0
		for x in w:
			var t := float(y) / h
			var base := tint.lightened(0.07).lerp(tint.darkened(0.45), t)
			var bx := (x + off) / 20
			var mortar := y % 10 == 0 or (x + off) % 20 == 0
			var c := base
			if mortar:
				c = base.darkened(0.35)
			else:
				c = base.lightened(float(shades[(bx * 7 + row * 13) % shades.size()]) + 0.02)
				if (x + off) % 20 == 1 or y % 10 == 1:
					c = c.lightened(0.04)   # the lit top-left lip of each block
			# torchlight from the top, warm and soft
			var d := Vector2(x - w * 0.5, (y + 30) * 1.4).length() / (w * 0.9)
			c = c.lerp(TORCH, clampf(0.16 * (1.0 - d), 0.0, 0.16))
			# vignette
			var vx := absf(float(x) / w - 0.5) * 2.0
			var vy := absf(t - 0.45) * 2.0
			c = c.darkened(clampf((vx * vx + vy * vy) * 0.35, 0.0, 0.6))
			img.set_pixel(x, y, Color(c, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	for dy in PX:
		for dx in PX:
			img.set_pixel(x * PX + dx, y * PX + dy, c)
