extends SceneTree
## Pets 2: turns Juzo's phone screenshots of pet refs into clean 32x32 sprites
## (style references only). args: <src dir> <out dir>
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	for i in range(1, 11):
		var img := Image.load_from_file("%s/pet_ref_%d.png" % [a[0], i])
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		# the panel: light grey pixels in the middle band
		var x0 := w; var x1 := 0; var y0 := h; var y1 := 0
		for y in range(int(h * 0.2), int(h * 0.8)):
			for x in range(0, w, 2):
				var c := img.get_pixel(x, y)
				if absf(c.r - c.g) < 0.03 and absf(c.g - c.b) < 0.03 and c.r > 0.47 and c.r < 0.8:
					x0 = mini(x0, x); x1 = maxi(x1, x); y0 = mini(y0, y); y1 = maxi(y1, y)
		var out := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var cw := float(x1 - x0 + 1) / 32.0
		var ch := float(y1 - y0 + 1) / 32.0
		for cy in 32:
			for cx in 32:
				out.set_pixel(cx, cy, img.get_pixel(int(x0 + (cx + 0.5) * cw), int(y0 + (cy + 0.5) * ch)))
		# flood the grey background from the edges (the sprite has a dark outline)
		var stack: Array = []
		for k in 32:
			stack.append(Vector2i(k, 0)); stack.append(Vector2i(k, 31)); stack.append(Vector2i(0, k)); stack.append(Vector2i(31, k))
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			if p.x < 0 or p.y < 0 or p.x > 31 or p.y > 31:
				continue
			var c := out.get_pixelv(p)
			if c.a == 0.0 or not (c.get_luminance() > 0.35 and c.s < 0.12):
				continue
			out.set_pixelv(p, Color(0, 0, 0, 0))
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				stack.append(p + d)
		out.save_png("%s/ref_%d.png" % [a[1], i])
		print("ref %d panel %d,%d-%d,%d" % [i, x0, y0, x1, y1])
	quit()
