class_name SkillIcons
extends RefCounted
## Skill icons: one frame of the matching effect (art/fx) for each skill tag.

const TAG_FX := {"Blade": "slash", "Fist": "impact", "Fire": "fire", "Frost": "ice", "Storm": "lightning", "Arcane": "arcane",
	"Holy": "holy", "Shadow": "shadow", "Blood": "blood", "Nature": "nature", "Song": "heal", "Trick": "claw"}
static var _cache := {}

## UX pass: the effect frames are soft, see-through glows, so on their own they
## nearly vanish on dark panels. Every icon now sits on the same small stone
## plate with an iron edge; the glow is made solid (no half-transparent pixels)
## and gets the style bible 1 px near-black outline. 32x32, built once, cached.
static func _plate(fx: Image) -> Image:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fill := Color("#1c1a30")
	var edge := Color("#4b4e63")
	for y in n:
		for x in n:
			var c := fill
			if x == 0 or y == 0 or x == n - 1 or y == n - 1:
				c = UiSkin.SOOT
				if (x == 0 or x == n - 1) and (y == 0 or y == n - 1):
					c = Color(0, 0, 0, 0)
			elif x == 1 or y == 1:
				c = edge.lightened(0.25)   # lit top-left
			elif x == n - 2 or y == n - 2:
				c = edge.darkened(0.3)
			img.set_pixel(x, y, c)
	var o := (n - fx.get_width()) / 2
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < fx.get_width() and y < fx.get_height() and fx.get_pixel(x, y).a > 0.25
	for y in range(-1, fx.get_height() + 1):
		for x in range(-1, fx.get_width() + 1):
			if solid.call(x, y):
				var p := fx.get_pixel(x, y)
				img.set_pixel(x + o, y + o, Color(p.r, p.g, p.b, 1.0).lightened(0.15))
			elif solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1):
				img.set_pixel(x + o, y + o, UiSkin.SOOT)
	return img

## A 64x64 icon for a skill tag (the effect's fullest frame), or null.
static func for_tag(tag: String) -> Texture2D:
	if _cache.has(tag):
		return _cache[tag]
	var fx: String = TAG_FX.get(tag, "burst")
	var path := "res://art/fx/%s.png" % fx
	var out: Texture2D = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		var img := tex.get_image()
		if img.is_compressed():
			img.decompress()
		var n := img.get_width() / 64
		var best := 0
		var best_a := -1
		for i in n:
			var a := 0
			for y in range(0, 64, 4):
				for x in range(0, 64, 4):
					if img.get_pixel(i * 64 + x, y).a > 0.3:
						a += 1
			if a > best_a:
				best_a = a
				best = i
		var frame := img.get_region(Rect2i(best * 64, 0, 64, 64))
		var used := frame.get_used_rect()
		if used.size.x > 0:
			var side := maxi(used.size.x, used.size.y)
			var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
			sq.blit_rect(frame, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
			sq.resize(24, 24, Image.INTERPOLATE_NEAREST)
			out = ImageTexture.create_from_image(_plate(sq))
	_cache[tag] = out
	return out
