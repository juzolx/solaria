extends SceneTree
## Solaria's app icon and startup splash, drawn in code (original, CC0):
## an eclipsed black sun with a gold-and-crimson corona, in chunky pixels.
## godot --headless --path . -s tools/make_brand.gd
const BG := Color("#0b0812")
const GOLD := Color("#fbbf24")
const EMBER := Color("#f97316")
const CRIMSON := Color("#b91c1c")
const DEEP := Color("#3b0a1a")

const GLYPHS := {
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
}

func _initialize() -> void:
	var icon := emblem(128, 1.0)
	icon.resize(1024, 1024, Image.INTERPOLATE_NEAREST)
	icon.save_png("res://icon.png")
	var small := emblem(128, 1.0)
	small.resize(192, 192, Image.INTERPOLATE_NEAREST)
	small.save_png("res://art/brand/icon_192.png") if DirAccess.dir_exists_absolute("res://art/brand") else null
	var splash := Image.create(252, 448, false, Image.FORMAT_RGBA8)
	splash.fill(BG)
	var em := emblem(96, 0.0)
	splash.blend_rect(em, Rect2i(0, 0, 96, 96), Vector2i(78, 150))
	word(splash, "SOLARIA", 126, 268, 3, GOLD)
	splash.resize(504, 896, Image.INTERPOLATE_NEAREST)
	splash.save_png("res://splash.png")
	print("BRAND DONE")
	quit()

## The emblem on a `size` square. `bg` 1 fills the background (icon), 0 leaves it clear.
func emblem(size: int, bg: float) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(BG, bg))
	var c := Vector2(size, size) / 2.0 - Vector2(0.5, 0.5)
	var r_sun := size * 0.24
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in size:
		for x in size:
			var p := Vector2(x, y) - c
			var d := p.length()
			var ang := p.angle()
			# corona rays: 12 long and 12 short, flickering lengths
			var ray := absf(sin(ang * 6.0))
			var ray2 := absf(sin(ang * 12.0 + 0.5))
			var reach := r_sun * (1.25 + 0.55 * pow(ray, 6.0) + 0.22 * pow(ray2, 8.0))
			var col := Color(0, 0, 0, 0)
			if d < reach and d >= r_sun:
				var f := (d - r_sun) / (reach - r_sun)
				col = GOLD.lerp(EMBER, clampf(f * 1.4, 0.0, 1.0)).lerp(CRIMSON, clampf(f * 2.0 - 1.0, 0.0, 1.0))
				# dither the outer edge into the dark
				if f > 0.7 and (x + y) % 2 == 0:
					col = DEEP
			# soft glow halo
			elif d >= reach and d < r_sun * 2.1:
				var g := 1.0 - (d - r_sun) / (r_sun * 1.1)
				if g > 0.0 and ((x + y * 3) % 4 == 0 or g > 0.55 and (x + y) % 2 == 0):
					col = DEEP.lerp(CRIMSON, g * 0.5)
			# the black sun, with a thin bright rim on its lower right (light from behind)
			if d < r_sun:
				col = Color("#050307")
				if d > r_sun - 1.6 and p.dot(Vector2(1, 1).normalized()) > r_sun * 0.3:
					col = GOLD.lightened(0.3)
			if col.a > 0.0:
				img.set_pixel(x, y, col)
	return img

## Big pixel letters centered at (cx, top), each glyph pixel `px` wide, with a dark shadow.
func word(img: Image, text: String, cx: int, top: int, px: int, col: Color) -> void:
	var w := text.length() * 6 * px - px
	var x0 := cx - w / 2
	for pass_i in 2:
		var off := px if pass_i == 0 else 0
		var c := CRIMSON.darkened(0.4) if pass_i == 0 else col
		for i in text.length():
			var g: Array = GLYPHS[text[i]]
			for gy in 7:
				for gx in 5:
					if String(g[gy])[gx] == "1":
						img.fill_rect(Rect2i(x0 + i * 6 * px + gx * px + off, top + gy * px + off, px, px), c)
