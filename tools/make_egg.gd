extends SceneTree
## Solaria's egg icon (original, CC0): a speckled egg with a soft highlight and a crack.
## godot --headless --path . -s tools/make_egg.gd
func _initialize() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var base := Color("#e9dcc0")
	var shade := Color("#b8a27a")
	var dark := Color("#6b5636")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for y in 32:
		for x in 32:
			# an egg: narrower at the top
			var cy := 17.5
			var ry := 12.5
			var t := (y - cy) / ry
			var rx := 9.5 * (1.0 - 0.18 * minf(0.0, t) * -1.0) if t < 0.0 else 9.5
			var d := pow((x - 15.5) / rx, 2.0) + pow(t, 2.0)
			if d > 1.0:
				continue
			var c := base.lerp(shade, clampf((x - 10.0) / 14.0 + (y - 10.0) / 30.0, 0.0, 1.0))
			if d > 0.82:
				c = dark  # outline
			elif (x - 11) * (x - 11) + (y - 11) * (y - 11) < 6:
				c = Color("#fffaf0")  # highlight
			elif rng.randf() < 0.07:
				c = Color("#8a6a3e")  # speckles
			img.set_pixel(x, y, c)
	# a little crack: something inside is moving
	for p in [Vector2i(16, 9), Vector2i(17, 10), Vector2i(16, 11), Vector2i(17, 12), Vector2i(18, 12)]:
		img.set_pixel(p.x, p.y, dark)
	img.save_png("res://art/consumables/egg.png")
	print("EGG DONE")
	quit()
